"""Root-owned disposable Linux fixtures; real RSA verification, no external network."""
import base64,contextlib,hashlib,importlib.util,json,os,pathlib,subprocess,sys,tempfile,time,unittest
from unittest.mock import patch

path=pathlib.Path(__file__).resolve().parents[1]/'scripts/waf_runtime.py'
spec=importlib.util.spec_from_file_location('waf_runtime',path)
w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)

@unittest.skipUnless(sys.platform.startswith('linux') and os.geteuid()==0,'isolated Linux root fixture required')
class SignedRuntimeTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.keys=tempfile.TemporaryDirectory(prefix='waf-test-key-',dir='/root')
        cls.key=pathlib.Path(cls.keys.name)/'private'
        subprocess.run(['openssl','genpkey','-algorithm','RSA','-pkeyopt','rsa_keygen_bits:3072','-out',str(cls.key)],check=True,capture_output=True)
        cls.public=subprocess.check_output(['openssl','pkey','-in',str(cls.key),'-pubout']).decode()
    @classmethod
    def tearDownClass(cls):cls.keys.cleanup()
    def setUp(self):
        self.temp=tempfile.TemporaryDirectory(prefix='waf-signed-test-',dir='/root');self.addCleanup(self.temp.cleanup)
        self.root=pathlib.Path(self.temp.name)/'web';self.root.mkdir(mode=0o700)
        self.runtime=w.Runtime(self.root)
        self.files={name:b'# fixture\n' for name in w.FILES}
        self.baseline=dict(sequence=0,revision='a'*40,files={n:w.digest(b) for n,b in self.files.items()})
        self.addCleanup(patch.stopall)
        patch.object(w,'BASELINE',self.baseline).start();patch.object(w,'PUBLIC_KEY',self.public).start()
        self.envelope=self.sign()
        self.fetches=[]
        def fetch(url,limit):
            self.fetches.append(url)
            return json.dumps(self.envelope).encode() if url.endswith('.json') and 'channels/' in url else self.files[url.rsplit('/',1)[-1]]
        patch.object(w,'fetch',fetch).start()
    def sign(self,**changes):
        m=dict(schema=1,api=1,channel='stable',sequence=1,revision='b'*40,files={n:w.digest(b) for n,b in self.files.items()},issued=int(time.time())-2,expires=int(time.time())+3600)
        m.update(changes);raw=json.dumps(m).encode()
        signature=subprocess.check_output(['openssl','dgst','-sha256','-sign',str(self.key)],input=raw)
        return dict(payload=base64.b64encode(raw).decode(),signature=base64.b64encode(signature).decode())
    def existing(self):
        self.runtime.control.mkdir(parents=True,mode=0o700)
        (self.runtime.control/'policy.json').write_text('{}')
        self.runtime.package({'baseline':True},download=True)
    def test_fresh_install_uses_signed_latest(self):
        selected=self.runtime.run('prepare',[])
        self.assertEqual(pathlib.Path(selected).name,'b'*40)
        self.assertEqual(self.runtime.state()['maximum'],1)
        self.assertEqual(len(self.fetches),8)
    def test_existing_install_stays_on_bootstrap_without_channel_request(self):
        self.existing();self.fetches.clear()
        self.assertEqual(pathlib.Path(self.runtime.run('prepare',[])).name,'a'*40)
        self.assertEqual(self.fetches,[])
    def test_uncached_status_does_not_download_or_create(self):
        with self.assertRaises(ValueError):self.runtime.run('cached',[])
        self.assertEqual(self.fetches,[]);self.assertFalse(self.runtime.control.exists())
    def test_installed_expired_manifest_remains_offline(self):
        self.runtime.run('prepare',[])
        state=self.runtime.state();state['active']=self.sign(issued=1,expires=3601);self.runtime.save(state)
        self.fetches.clear()
        self.runtime.run('cached',[]);self.assertEqual(self.fetches,[])
    def test_tampered_payload_rejected(self):
        bad=dict(self.envelope,payload=base64.b64encode(b'{}').decode())
        with self.assertRaisesRegex(ValueError,'signature rejected'):w.verify(bad)
    def test_invalid_signature_rejected(self):
        with self.assertRaises(ValueError):w.verify(dict(self.envelope,signature=base64.b64encode(bytes(384)).decode()))
    def test_unknown_fields_types_and_compatibility_rejected(self):
        for changes in [dict(api=2),dict(channel='preview'),dict(sequence=True),dict(revision='../escape'),dict(files={}),dict(extra=1),dict(expires=0)]:
            with self.subTest(changes=changes),self.assertRaises(ValueError):w.verify(self.sign(**changes))
    def test_expired_and_future_channel_rejected(self):
        for envelope in [self.sign(issued=1,expires=3601),self.sign(issued=int(time.time())+3600,expires=int(time.time())+7200)]:
            with self.assertRaises(ValueError):w.verify(envelope,fresh=True)
    def test_duplicate_json_rejected(self):
        with self.assertRaises(ValueError):w.decode('{"a":1,"a":2}')
    def test_replay_and_reused_sequence_rejected(self):
        self.runtime.run('prepare',[]);state=self.runtime.state()
        self.envelope=self.sign(sequence=1,revision='c'*40)
        with self.assertRaisesRegex(ValueError,'reused'):self.runtime.remote(state)
        state['maximum']=2
        with self.assertRaisesRegex(ValueError,'replay'):self.runtime.remote(state)
    def test_network_cannot_select_baseline_sentinel(self):
        self.envelope={'baseline':True}
        with self.assertRaises(ValueError):self.runtime.run('prepare',[])
    def test_download_hash_failure_keeps_old_identity(self):
        self.existing();self.files['policy.py']=b'tampered'
        with self.assertRaises(ValueError):self.runtime.package(self.envelope,download=True)
        self.assertEqual(self.runtime.state()['active'],{'baseline':True})
        self.assertFalse((self.runtime.control/'packages'/('b'*40)).exists())
    def test_cache_tamper_symlink_and_unknown_file_rejected(self):
        self.existing();directory=self.runtime.package({'baseline':True})
        (directory/'policy.py').write_text('bad')
        with self.assertRaises(ValueError):self.runtime.package({'baseline':True})
        (directory/'policy.py').unlink();(directory/'policy.py').symlink_to(directory/'ban.py')
        with self.assertRaises(ValueError):self.runtime.package({'baseline':True})
        (directory/'policy.py').unlink();(directory/'policy.py').write_bytes(self.files['policy.py'])
        (directory/'extra').write_text('')
        with self.assertRaises(ValueError):self.runtime.package({'baseline':True})
    def test_writable_ancestor_rejected(self):
        self.root.chmod(0o777)
        with self.assertRaises(ValueError):self.runtime.run('prepare',[])
    def test_dangling_state_symlink_rejected(self):
        self.existing();self.runtime.state_path.symlink_to(self.root/'missing')
        with self.assertRaises(ValueError):self.runtime.run('prepare',[])
    def test_unknown_action_does_not_execute_package(self):
        self.existing()
        with self.assertRaises(ValueError):self.runtime.run('run',['unknown'])
    def test_pending_update_blocks_execution_but_status_works(self):
        self.existing();state=self.runtime.state();state['pending']=str(self.root/'backup');self.runtime.save(state)
        with self.assertRaisesRegex(ValueError,'Interrupted'):self.runtime.run('prepare',[])
        self.assertTrue(json.loads(self.runtime.run('package-status',[]))['recoveryRequired'])
    def transaction(self,fail=None,crash=False):
        self.existing();runtime=self.runtime;root=self.root
        (root/'live').write_text('old')
        class Module:
            policy=type('Policy',(),{'validate':staticmethod(lambda value:value)})
            def __init__(self,value):self.value=value
            def load_json(self,path):return json.loads(path.read_text())
            @contextlib.contextmanager
            def locked(self,*args,**kwargs):yield
            def reconcile_native_switch(self,root,config):return config
            def make_plan(self,root,config):return {root/'live':self.value.encode()},[]
            def snapshot(self,root,changes,label):
                backup=root/'backups/waf-managed/fixture';backup.mkdir(parents=True,exist_ok=True)
                records={str(p.relative_to(root)):{'before':base64.b64encode(p.read_bytes()).decode(),'afterSha256':w.digest(b)} for p,b in changes.items()}
                (backup/'manifest.json').write_text(json.dumps({'files':records}));return backup
            def apply(self,root,config,**kwargs):
                (root/'live').write_text(self.value)
                if crash:raise KeyboardInterrupt('simulated process interruption')
                if fail=='apply':raise ValueError('apply failure')
            def restore(self,root,backup,verify=False):
                if fail=='restore':raise ValueError('restore failure')
                for relative,item in self.load_json(backup/'manifest.json')['files'].items():(root/relative).write_bytes(base64.b64decode(item['before']))
            def execute(self,*args):pass
            def reload_nginx(self,*args):pass
        def module(envelope):
            runtime.package(envelope)
            return Module('old' if envelope=={'baseline':True} else 'new')
        def doctor(m):
            if fail in {'doctor','restore'} and m.value=='new':raise ValueError('doctor failure')
        patch.object(runtime,'module',module).start();patch.object(runtime,'doctor',doctor).start()
        (runtime.control/'policy.json').write_text('{"container":"fixture"}')
    def test_successful_update_and_explicit_rollback_keep_replay_floor(self):
        self.transaction();self.runtime.run('package-update',[])
        self.assertEqual((self.root/'live').read_text(),'new')
        self.runtime.run('package-rollback',[])
        self.assertEqual((self.root/'live').read_text(),'old');self.assertEqual(self.runtime.state()['maximum'],1)
        self.runtime.run('package-update',[])
        self.assertEqual((self.root/'live').read_text(),'new')
    def test_apply_failure_restores_exact_preimage(self):
        self.transaction(fail='apply')
        with self.assertRaises(ValueError):self.runtime.run('package-update',[])
        self.assertEqual((self.root/'live').read_text(),'old');self.assertIsNone(self.runtime.state()['pending'])
    def test_unidentified_legacy_install_refuses_before_state_or_mutation(self):
        self.transaction();(self.root/'live').write_text('older original')
        with self.assertRaisesRegex(ValueError,'Older/unidentified'):self.runtime.run('package-update',[])
        self.assertEqual((self.root/'live').read_text(),'older original')
        self.assertFalse(self.runtime.state_path.exists())
    def test_doctor_failure_restores_exact_preimage(self):
        self.transaction(fail='doctor')
        with self.assertRaises(ValueError):self.runtime.run('package-update',[])
        self.assertEqual((self.root/'live').read_text(),'old')
    def test_recovery_failure_keeps_pending_and_old_identity(self):
        self.transaction(fail='restore')
        with self.assertRaisesRegex(ValueError,'recovery incomplete'):self.runtime.run('package-update',[])
        self.assertTrue(self.runtime.state()['pending']);self.assertEqual(self.runtime.state()['active'],{'baseline':True})
    def test_interruption_requires_explicit_recovery(self):
        self.transaction(crash=True)
        with self.assertRaises(KeyboardInterrupt):self.runtime.run('package-update',[])
        self.assertTrue(self.runtime.state()['pending'])
        self.runtime.run('package-recover',[])
        self.assertEqual((self.root/'live').read_text(),'old');self.assertIsNone(self.runtime.state()['pending'])
    def test_recovery_refuses_concurrent_unrelated_edits(self):
        self.transaction(crash=True)
        with self.assertRaises(KeyboardInterrupt):self.runtime.run('package-update',[])
        (self.root/'live').write_text('administrator edit')
        with self.assertRaisesRegex(ValueError,'Recovery conflict'):self.runtime.run('package-recover',[])
        self.assertEqual((self.root/'live').read_text(),'administrator edit')
    def test_second_operation_waits_for_common_package_lock(self):
        self.existing()
        with self.runtime.locked(True):
            code='import fcntl,os,sys; f=os.open(sys.argv[1],os.O_RDWR); fcntl.flock(f,fcntl.LOCK_EX|fcntl.LOCK_NB)'
            r=subprocess.run([sys.executable,'-c',code,str(self.runtime.control/'package-update.lock')],capture_output=True)
            self.assertNotEqual(r.returncode,0)
    def test_sigkill_during_download_does_not_poison_cache(self):
        self.existing()
        child=os.fork()
        if child==0:
            def interrupted(url,limit):
                if url.endswith('/policy.py'):os.kill(os.getpid(),9)
                return self.files[url.rsplit('/',1)[-1]]
            w.fetch=interrupted
            self.runtime.package(self.envelope,download=True)
            os._exit(2)
        _,status=os.waitpid(child,0)
        self.assertTrue(os.WIFSIGNALED(status))
        self.assertTrue((self.runtime.control/'package-download-stage/configure.py').exists())
        selected=self.runtime.package(self.envelope,download=True)
        self.assertEqual(selected.name,'b'*40)
        self.assertFalse((self.runtime.control/'package-download-stage').exists())

if __name__=='__main__':unittest.main()
