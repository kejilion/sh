"""Linux root fixture for native package integrity; never contacts the network."""
import hashlib
import json
import os
from pathlib import Path
import shlex
import shutil
import subprocess
import sys
import tempfile
import unittest


@unittest.skipUnless(sys.platform.startswith('linux') and os.geteuid() == 0, 'requires an isolated Linux root validation environment')
class BootstrapTests(unittest.TestCase):
    def setUp(self):
        self.temporary=tempfile.TemporaryDirectory(prefix='waf-bootstrap-',dir='/root')
        self.addCleanup(self.temporary.cleanup)
        self.root=Path(self.temporary.name)
        self.web=self.root/'web';self.web.mkdir(mode=0o700)
        self.payload=self.root/'payload';self.payload.mkdir(mode=0o700)
        self.revision='a'*40
        self.package=self.web/'config/waf/packages'/self.revision
        self.calls=self.root/'downloads'
        names=['configure.py','policy.py','nginx_edit.py','ban.py','example-policy.json','cloudflare-ips.json','legacy-jails.local']
        self.files={name:(b'print("fixture-executed")\n' if name=='configure.py' else b'# trusted fixture\n') for name in names}
        for name,data in self.files.items():(self.payload/name).write_bytes(data)
        manifest='\n'.join(hashlib.sha256(data).hexdigest()+'  '+name for name,data in self.files.items())
        source=(Path(__file__).resolve().parents[1]/'kejilion.sh').read_text(encoding='utf-8')
        names=['shared_waf_revision','shared_waf_manifest','shared_waf_verified','shared_waf_prepare','shared_waf_cached','shared_waf']
        functions=[]
        for name in names:
            start=source.index(name+'() {\n');end=source.index('\n}\n',start)+3
            functions.append(source[start:end])
        body='\n'.join(functions).replace('/home/web',str(self.web))
        body+='\nshared_waf_revision() { printf "%s\\n" '+shlex.quote(self.revision)+'; }\n'
        body+='shared_waf_manifest() { printf "%s\\n" '+shlex.quote(manifest)+'; }\n'
        # Intercept only the download invocation; all version/path checks use real Python.
        body+='''python3() {
  if [ "${1:-}" = -I ] && [ "${2:-}" = - ] && [[ "${3:-}" = https://* ]]; then
    cat >/dev/null
    printf '%s\\n' "${3##*/}" >> DOWNLOADS
    [ "${FAIL_DOWNLOAD:-0}" = 0 ] || return 1
    cp -- PAYLOAD/"${3##*/}" "$4"
  else
    command PYTHON "$@"
  fi
}
'''.replace('DOWNLOADS',shlex.quote(str(self.calls))).replace('PAYLOAD',shlex.quote(str(self.payload))).replace('PYTHON',shlex.quote(sys.executable))
        self.script=self.root/'functions.sh';self.script.write_text(body,encoding='utf-8')

    def run_fixture(self,command,**extra):
        env=dict(os.environ,**extra)
        return subprocess.run(['bash','-c','source "$1"; '+command,'fixture',str(self.script)],env=env,text=True,capture_output=True,timeout=20)

    def seed(self,directory=None):
        directory=directory or self.package
        directory.mkdir(parents=True,mode=0o700)
        for name,data in self.files.items():
            p=directory/name;p.write_bytes(data);p.chmod(0o600)

    def test_verified_download_can_execute_and_cache_is_reused(self):
        result=self.run_fixture('shared_waf apply')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('fixture-executed',result.stdout)
        self.assertEqual(len(self.calls.read_text().splitlines()),7)
        result=self.run_fixture('shared_waf status')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertEqual(len(self.calls.read_text().splitlines()),7)

    def test_uncached_status_never_downloads_or_creates_directories(self):
        result=self.run_fixture('shared_waf status')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('共享 WAF 包尚未导入',result.stderr)
        self.assertNotIn('Traceback',result.stderr)
        self.assertFalse(self.calls.exists())
        self.assertFalse((self.web/'config').exists())

    def test_prefixed_options_and_unknown_actions_are_rejected_before_preparation(self):
        for command in ['shared_waf --policy /root/policy.json status','shared_waf invalid','shared_waf --help']:
            result=self.run_fixture(command)
            self.assertEqual(result.returncode,2,result.stderr)
            self.assertFalse(self.calls.exists())
            self.assertFalse((self.web/'config').exists())

    def test_status_rejects_writable_and_symlink_ancestors(self):
        self.seed()
        self.web.chmod(0o777)
        result=self.run_fixture('shared_waf status')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('fixture-executed',result.stdout)
        self.web.chmod(0o700)
        moved=self.root/'moved-web'
        self.web.rename(moved);self.web.symlink_to(moved,target_is_directory=True)
        result=self.run_fixture('shared_waf status')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('fixture-executed',result.stdout)

    def test_tampered_cache_is_not_executed_or_silently_replaced(self):
        self.seed();(self.package/'configure.py').write_text('print("tampered")')
        result=self.run_fixture('shared_waf status')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('tampered',result.stdout)
        self.assertFalse(self.calls.exists())

    def test_seven_manifest_files_are_accepted_and_unknown_names_are_rejected(self):
        self.seed()
        older=self.package.parent/('b'*40)
        self.seed(older)
        result=self.run_fixture('shared_waf_prepare')
        self.assertEqual(result.returncode,0,result.stderr)
        (older/'README.txt').write_text('unexpected')
        result=self.run_fixture('shared_waf_prepare')
        self.assertNotEqual(result.returncode,0)
        self.assertIn('WAF 缓存含未知文件',result.stderr)

    def test_older_six_file_package_cache_does_not_block_new_pinned_package(self):
        older=self.package.parent/('b'*40)
        older.mkdir(parents=True,mode=0o700)
        for name,data in self.files.items():
            if name=='ban.py':
                continue
            path=older/name;path.write_bytes(data);path.chmod(0o600)
        result=self.run_fixture('shared_waf apply')
        self.assertEqual(result.returncode,0,result.stderr)
        self.assertIn('fixture-executed',result.stdout)
        self.assertEqual(len(self.calls.read_text().splitlines()),7)
        self.assertTrue(self.package.is_dir())

    def test_symlink_and_writable_cache_files_are_rejected(self):
        self.seed();p=self.package/'configure.py';p.unlink();p.symlink_to(self.payload/'configure.py')
        self.assertNotEqual(self.run_fixture('shared_waf status').returncode,0)
        p.unlink();p.write_bytes(self.files['configure.py']);p.chmod(0o666)
        self.assertNotEqual(self.run_fixture('shared_waf status').returncode,0)

    def test_unknown_module_cannot_shadow_the_python_standard_library(self):
        self.seed();(self.package/'argparse.py').write_text('raise RuntimeError("shadowed")')
        result=self.run_fixture('shared_waf status')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('fixture-executed',result.stdout)

    def test_failed_or_wrong_digest_download_leaves_no_executable_stage(self):
        result=self.run_fixture('shared_waf apply',FAIL_DOWNLOAD='1')
        self.assertNotEqual(result.returncode,0)
        self.assertFalse(list(self.package.parent.glob('.stage.*')))
        (self.payload/'configure.py').write_text('print("wrong-digest")')
        result=self.run_fixture('shared_waf apply')
        self.assertNotEqual(result.returncode,0)
        self.assertNotIn('wrong-digest',result.stdout)
        self.assertFalse(self.package.exists())
        self.assertFalse(list(self.package.parent.glob('.stage.*')))

    def test_version_budget_reserves_space_before_fetching(self):
        for index in range(16):self.seed(self.package.parent/f'{index:040x}')
        result=self.run_fixture('shared_waf apply')
        self.assertNotEqual(result.returncode,0)
        self.assertFalse(self.calls.exists())
        shutil.rmtree(self.package.parent/f'{0:040x}')
        self.seed()
        self.assertEqual(self.run_fixture('shared_waf status').returncode,0)


@unittest.skipUnless(sys.platform.startswith('linux') and os.geteuid() == 0, 'requires isolated Linux root fixtures')
class NativeStatusTests(unittest.TestCase):
    def test_legacy_boolean_never_claims_unverified_or_partial_blocking(self):
        with tempfile.TemporaryDirectory(prefix='waf-status-',dir='/root') as directory:
            root=Path(directory);web=root/'web';(web/'config/waf').mkdir(parents=True)
            (web/'nginx.conf').write_text('events {} http { modsecurity on; }\n',encoding='utf-8')
            # The historical bool scanner is line-based, as in old native configs.
            (web/'nginx.conf').write_text('events {}\nhttp {\nmodsecurity on;\n}\n',encoding='utf-8')
            policy_file=web/'config/waf/policy.json';policy_file.write_text('{}\n',encoding='utf-8')
            source=(Path(__file__).resolve().parents[1]/'kejilion.sh').read_text(encoding='utf-8')
            start=source.index('ldnmp_environment_status() {\n');end=source.index('\n}\n',start)+3
            helpers=[]
            for name in ['kpanel_ldnmp_site_jail_json','kpanel_ldnmp_migration_json','kpanel_ldnmp_fail2ban_logs_json','kpanel_ldnmp_ddos_rules_present','kpanel_ldnmp_cloudflare_status_json','kpanel_ldnmp_protection_json']:
                helper_start=source.index(name+'() {\n');helper_end=source.index('\n}\n',helper_start)+3
                helpers.append(source[helper_start:helper_end])
            body='\n'.join(helpers)+'\n'+source[start:end]
            body=body.replace('/home/web',str(web)).replace('find /home -maxdepth','find '+shlex.quote(str(root))+' -maxdepth').replace('/etc/fail2ban',str(root/'no-fail2ban')).replace('/var/log/fail2ban.log',str(root/'fail2ban.log')).replace('/root/CF-Under-Attack.sh',str(root/'CF-Under-Attack.sh'))
            script=root/'status.sh'
            script.write_text(body+'''
docker() { return 1; }
iptables() { return 1; }
ss() { :; }
fail2ban-client() { return 1; }
crontab() { echo 'no crontab for root'; return 1; }
ldnmp_site_count() { printf '0'; }
kpanel_ldnmp_escape() { printf '%s' "$1"; }
kpanel_ldnmp_component() { printf '{}'; }
shared_waf_mode() { printf '%s' "$FIXTURE_MODE"; [ "$FIXTURE_MODE" != unknown ]; }
sh_v=fixture
ldnmp_environment_status
''',encoding='utf-8')
            for mode in ['on','off','detect','mixed','unknown']:
                result=subprocess.run(['bash',str(script)],env=dict(os.environ,FIXTURE_MODE=mode),capture_output=True,text=True,timeout=10,check=True)
                protection=json.loads(result.stdout)['protection']
                self.assertEqual(protection['wafMode'],mode)
                self.assertEqual(protection['waf'],mode=='on')
            policy_file.unlink()
            result=subprocess.run(['bash',str(script)],capture_output=True,text=True,timeout=10,check=True)
            protection=json.loads(result.stdout)['protection']
            self.assertEqual(protection['wafMode'],'legacy')
            self.assertTrue(protection['waf'])


if __name__=='__main__':unittest.main()
