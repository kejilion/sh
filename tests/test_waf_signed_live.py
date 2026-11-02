#!/usr/bin/env python3
"""Explicit networkless Docker fixture: signed package update, reload and rollback."""
import argparse,base64,hashlib,importlib.util,json,os,pathlib,subprocess,tempfile,time,uuid

def main():
    parser=argparse.ArgumentParser();parser.add_argument('--bundle',type=pathlib.Path,required=True);parser.add_argument('--image',required=True);args=parser.parse_args()
    path=pathlib.Path(__file__).resolve().parents[1]/'scripts/waf_runtime.py'
    spec=importlib.util.spec_from_file_location('runtime',path);w=importlib.util.module_from_spec(spec);spec.loader.exec_module(w)
    name='waf-signed-live-'+uuid.uuid4().hex[:10]
    with tempfile.TemporaryDirectory(prefix='waf-signed-live-',dir='/root') as temporary:
        root=pathlib.Path(temporary)
        for relative in ['conf.d','log/nginx','config/waf/packages','sockets']:(root/relative).mkdir(parents=True,mode=0o755)
        (root/'nginx.conf').write_text('pid /run/nginx.pid; error_log /var/log/nginx/error.log; events {worker_connections 128;} http {include /etc/nginx/conf.d/*.conf;}\n')
        (root/'conf.d/site.conf').write_text('server {listen unix:/fixture/front.sock; server_name fixture.example; location / {return 200 "fixture-ok";} }\n')
        files={n:(args.bundle/n).read_bytes() for n in w.FILES}
        w.BASELINE={'sequence':0,'revision':'a'*40,'files':{n:w.digest(v) for n,v in files.items()}}
        old=root/'config/waf/packages'/('a'*40);old.mkdir(mode=0o700)
        for n,b in files.items():(old/n).write_bytes(b)
        candidate=dict(files);candidate['policy.py']+=b'\n# signed-live-fixture revision\n'
        key=root/'key'
        subprocess.run(['openssl','genpkey','-algorithm','RSA','-pkeyopt','rsa_keygen_bits:3072','-out',str(key)],check=True,capture_output=True)
        w.PUBLIC_KEY=subprocess.check_output(['openssl','pkey','-in',str(key),'-pubout']).decode()
        now=int(time.time());payload=json.dumps(dict(schema=1,api=1,channel='stable',sequence=1,revision='b'*40,files={n:w.digest(b) for n,b in candidate.items()},issued=now,expires=now+3600)).encode()
        signature=subprocess.check_output(['openssl','dgst','-sha256','-sign',str(key)],input=payload)
        envelope=dict(payload=base64.b64encode(payload).decode(),signature=base64.b64encode(signature).decode())
        w.fetch=lambda url,limit:json.dumps(envelope).encode() if 'channels/' in url else candidate[url.rsplit('/',1)[-1]]
        runtime=w.Runtime(root)
        module=runtime.module({'baseline':True})
        config=json.loads(files['example-policy.json']);config.update(container=name,cdn='direct',mode='on',sites={'fixture.example':{'profile':'kpanel'}})
        mounts=[(root/'nginx.conf','/etc/nginx/nginx.conf'),(root/'conf.d','/etc/nginx/conf.d'),(root/'log/nginx','/var/log/nginx'),(root/'sockets','/fixture')]
        cmd=['docker','run','-d','--name',name,'--pull=never','--network=none','--read-only','--memory=768m','--cpus=1','--pids-limit=96','--tmpfs','/tmp:rw,size=64m','--tmpfs','/run:rw,size=8m','--tmpfs','/var/cache/nginx:rw,size=16m']
        for source,target in mounts:cmd+=['--mount','type=bind,src='+str(source)+',dst='+target]
        cmd+=['--entrypoint','nginx',args.image,'-g','daemon off;']
        checks=[]
        def check(label,condition):
            if not condition:raise AssertionError(label)
            checks.append(label)
        try:
            subprocess.run(cmd,check=True,capture_output=True)
            module.apply(root,config)
            runtime.doctor(module)
            pid=subprocess.check_output(['docker','inspect','--format','{{.State.Pid}}',name])
            before={p.relative_to(root):p.read_bytes() for p in (root/'conf.d/waf').iterdir() if p.is_file()}
            check('legacy-pinned-install-adopted',runtime.state()['active']=={'baseline':True})
            runtime.run('package-update',[])
            check('new-generator-applied',(root/'conf.d/waf/policy.py').read_bytes()==candidate['policy.py'])
            check('signed-active-committed',w.verify(runtime.state()['active'])['sequence']==1)
            check('hot-reload-without-container-restart',subprocess.check_output(['docker','inspect','--format','{{.State.Pid}}',name])==pid)
            (root/'conf.d/waf/policy.py').write_bytes(files['policy.py'])
            runtime.run('package-update',[])
            check('same-version-repairs-old-script-source-drift',(root/'conf.d/waf/policy.py').read_bytes()==candidate['policy.py'])
            check('repair-preserves-previous',runtime.state()['previous']=={'baseline':True})
            runtime.run('package-rollback',[])
            check('rollback-old-generator',(root/'conf.d/waf/policy.py').read_bytes()==files['policy.py'])
            check('rollback-keeps-watermark',runtime.state()['maximum']==1)
            check('rollback-generated-files-exact',all((root/p).read_bytes()==data for p,data in before.items()))
            runtime.run('package-update',[])
            check('upgrade-after-rollback',w.verify(runtime.state()['active'])['sequence']==1)
            stable={p.relative_to(root):p.read_bytes() for p in (root/'conf.d/waf').iterdir() if p.is_file()}
            candidate['policy.py']+=b'# recovery fixture revision\n'
            manifest=json.loads(payload);manifest.update(sequence=2,revision='c'*40,files={n:w.digest(b) for n,b in candidate.items()})
            raw=json.dumps(manifest).encode();sig=subprocess.check_output(['openssl','dgst','-sha256','-sign',str(key)],input=raw)
            envelope=dict(payload=base64.b64encode(raw).decode(),signature=base64.b64encode(sig).decode())
            normal_doctor=runtime.doctor
            def fail_candidate(m):
                if m.BUNDLE.name=='c'*40:raise ValueError('injected post-apply validation failure')
                return normal_doctor(m)
            runtime.doctor=fail_candidate
            try:runtime.run('package-update',[]);raise AssertionError('failure not propagated')
            except ValueError as error:check('real-failure-propagated','injected' in str(error))
            runtime.doctor=normal_doctor
            check('real-failure-restores-exact-files',all((root/p).read_bytes()==data for p,data in stable.items()))
            check('failed-update-retains-active-and-watermark',w.verify(runtime.state()['active'])['sequence']==1 and runtime.state()['maximum']==2 and not runtime.state()['pending'])
            child=os.fork()
            if child==0:
                module_loader=runtime.module
                def killed_after_apply(e):
                    m=module_loader(e)
                    if m.BUNDLE.name=='c'*40:
                        original=m.apply
                        def apply(*a,**k):original(*a,**k);os.kill(os.getpid(),9)
                        m.apply=apply
                    return m
                runtime.module=killed_after_apply
                runtime.run('package-update',[]);os._exit(2)
            _,status=os.waitpid(child,0)
            check('real-sigkill-after-apply',os.WIFSIGNALED(status) and bool(runtime.state()['pending']))
            runtime.run('package-recover',[])
            check('real-crash-recovery-exact',all((root/p).read_bytes()==data for p,data in stable.items()) and not runtime.state()['pending'])
            w.fetch=lambda *args:(_ for _ in ()).throw(OSError('offline'))
            check('offline-active-cache',pathlib.Path(runtime.run('cached',[])).name=='b'*40)
            # Exercise actual shell embedding and stdin preservation using a trusted
            # fixture state/key; never source the full interactive native script.
            shell=(path.parents[1]/'kejilion.sh').read_text()
            block=shell[shell.index('shared_waf_python() {'):shell.index('shared_waf_refresh() {')]
            block=block.replace('/home/web',str(root))
            original=w.PUBLIC_KEY
            production=path.read_text().split('PUBLIC_KEY = ',1)[1].split('\n',1)[0]
            block=block.replace('PUBLIC_KEY = '+production,'PUBLIC_KEY = '+repr(original))
            # Baseline is only used for previous identity validation in the fixture.
            baseline=path.read_text().split('BASELINE = ',1)[1].split('\n',1)[0]
            block=block.replace('BASELINE = '+baseline,'BASELINE = '+repr(w.BASELINE))
            script=root/'fixture.sh';script.write_text(block+'\nshared_waf "$@"\n')
            status=subprocess.run(['bash',str(script),'package-status'],capture_output=True,text=True)
            check('real-shell-uses-active-package',status.returncode==0 and json.loads(status.stdout)['active']=='b'*40)
            doctor=subprocess.run(['bash',str(script),'doctor'],capture_output=True,text=True)
            check('real-shell-doctor-offline',doctor.returncode==0)
            invalid=subprocess.run(['bash',str(script),'cf-on'],input='{',capture_output=True,text=True)
            check('shell-preserves-credential-stdin',invalid.returncode!=0 and 'property name' in invalid.stderr)
            print(json.dumps({'passed':len(checks),'checks':checks}))
        finally:
            subprocess.run(['docker','rm','-f',name],capture_output=True)

if __name__=='__main__':main()
