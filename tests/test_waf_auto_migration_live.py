"""Opt-in real native WAF entrypoint, isolated containers and private cron only.

KJ_WAF_MIGRATION_LIVE=1 KJ_WAF_BUNDLE=/verified/six-file/bundle python3 -B <file>
"""
import json
import os
from pathlib import Path
import shutil
import subprocess
import sys
import tempfile
import unittest
import urllib.error
import urllib.request
import uuid

from test_nginx_config_update import SCRIPT, updater, template


@unittest.skipUnless(os.environ.get('KJ_WAF_MIGRATION_LIVE') == '1', 'opt-in Docker fixture')
class WafMigrationTests(unittest.TestCase):
    def test_native_on_recovery_retry_and_modes_with_direct_and_cf_configs(self):
        bundle = Path(os.environ['KJ_WAF_BUNDLE']).resolve()
        ordinary = os.environ.get('KJ_WAF_ORDINARY_IMAGE', 'nginx:1.31.8-alpine')
        waf = os.environ['KJ_WAF_IMAGE']
        docker = shutil.which('docker')
        functions = []
        for name in ('nginx_config_update', 'nginx_update_transaction', 'nginx_waf', 'nginx_waf_configure',
                     'shared_waf', 'shared_waf_verified', 'shared_waf_manifest', 'shared_waf_remove_rotation'):
            start = SCRIPT.index(name + '() {\n')
            end = SCRIPT.index('\n}\n', SCRIPT.index('\nNGINX_CONFIG_UPDATE\n', start)) if name == 'nginx_config_update' else SCRIPT.index('\n}\n', start)
            functions.append(SCRIPT[start:end + 3])
        for cf in (False, True):
            with self.subTest(cf=cf), tempfile.TemporaryDirectory(prefix='kj-waf-native-', dir='/root') as temporary:
                root = Path(temporary)
                name = 'kj-waf-native-' + uuid.uuid4().hex[:10]
                container = name + '-nginx'
                compose = [docker, 'compose', '--project-directory', str(root)]
                for directory in ('conf.d', 'stream.d', 'certs', 'log/nginx', 'bin'):
                    (root / directory).mkdir(parents=True, mode=0o700)
                updater.command('openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1',
                                '-subj', '/CN=localhost', '-keyout', str(root / 'certs/default_server.key'),
                                '-out', str(root / 'certs/default_server.crt'))
                (root / 'nginx.conf').write_text(template(updater.LEGACY, 'nginx10.conf'))
                (root / 'conf.d/default.conf').write_text(template(updater.LEGACY, 'default11.conf' if cf else 'default10.conf'))
                (root / 'conf.d/map.conf').write_text(template(updater.LEGACY, 'map.conf'))
                site = b'server { listen 80; server_name live.example; location / { return 200 "migration-ok"; } }\n'
                (root / 'conf.d/live.example.conf').write_bytes(site)
                model = {'name': name, 'services': {'nginx': {'image': ordinary, 'container_name': container,
                    'environment': {'PRESERVE_LITERAL': 'hello$$world'}, 'ports': ['127.0.0.1::80'],
                    'volumes': [{'type': 'bind', 'source': str(root / relative), 'target': target}
                                for relative, target in [('nginx.conf', '/etc/nginx/nginx.conf'), ('conf.d', '/etc/nginx/conf.d'),
                                    ('stream.d', '/etc/nginx/stream.d'), ('certs', '/etc/nginx/certs'), ('log/nginx', '/var/log/nginx')]]}}}
                original_compose = (json.dumps(model) + '\n').encode()
                (root / 'docker-compose.yml').write_bytes(original_compose)
                # Real override semantics and literal dollars are checked against the
                # complete effective model. No image tags, host cron, jails or live
                # arena containers are changed by this fixture.
                override = b'# preserve CF/custom override\nservices:\n  nginx:\n    environment:\n      OVERRIDE_FLAG: retained\n'
                (root / 'docker-compose.override.yml').write_bytes(override)
                (root / 'bin/docker').write_text('''#!'''+sys.executable+'''
import json, os, pathlib, subprocess, sys
args=sys.argv[1:]
if args and args[0] in ('exec','top') and args[1]=='nginx': args[1]=os.environ['FIXTURE_CONTAINER']
if args and args[0]=='inspect' and args[-1]=='nginx': args[-1]=os.environ['FIXTURE_CONTAINER']
if args and args[0]=='exec' and '-T' in args and '-c' in args and os.environ.get('FIXTURE_FAULT')=='policy':
    pending=pathlib.Path(os.environ['FIXTURE_ROOT'])/'conf.d/waf/pending-nginx.conf'
    with pending.open('a') as stream: stream.write('\\nfixture_unknown_directive;\\n')
if args and args[0]=='compose':
    if 'pull' in args:
        if os.environ.get('FIXTURE_FAULT')=='pull': sys.exit(1)
        sys.exit(0) # Both real images are already downloaded and pinned locally.
    files=[pathlib.Path(args[i+1]) for i,x in enumerate(args) if x=='-f']
    if files and any(x in args for x in ('up','run')):
        model=json.loads(files[0].read_text())
        if len(files)==1 and model['services']['nginx']['image']==os.environ['FIXTURE_WAF_IMAGE']:
            override=pathlib.Path(os.environ['FIXTURE_ROOT'])/'image-fixture.json'
            override.write_text(json.dumps({'services':{'nginx':{'image':os.environ['FIXTURE_WAF']}}}))
            point=next(i for i,x in enumerate(args) if x in ('up','run'))
            args[point:point]=['-f',str(override)]
    result=subprocess.run([os.environ['FIXTURE_DOCKER'],*args])
    if result.returncode==0 and 'start' in args and os.environ.get('FIXTURE_FAULT')=='switch':
        marker=pathlib.Path(os.environ['FIXTURE_ROOT'])/'switch-fault-fired'
        if not marker.exists(): marker.touch(); sys.exit(1)
    sys.exit(result.returncode)
os.execv(os.environ['FIXTURE_DOCKER'],[os.environ['FIXTURE_DOCKER'],*args])
''')
                (root / 'bin/docker').chmod(0o700)
                (root / 'bin/crontab').write_text('''#!'''+sys.executable+'''
import os, pathlib, sys
p=pathlib.Path(os.environ['FIXTURE_ROOT'])/'private-cron'
if sys.argv[1:]==['-l']:
    if p.exists(): print(p.read_text(),end='')
    else: print('no crontab for root',file=sys.stderr); sys.exit(1)
else: p.write_text(sys.stdin.read() if sys.argv[1]=='-' else pathlib.Path(sys.argv[1]).read_text())
''')
                (root / 'bin/crontab').chmod(0o700)
                body = '\n'.join(functions).replace('/home/web', str(root)).replace('/run/lock', str(root / 'locks'))
                # All policy configuration is real. Existing-filter updates stay in
                # the separate native smoke test so this fixture cannot touch host jails.
                body += '''
shared_waf_prepare() { WAF_PYTHON="$FIXTURE_PYTHON"; WAF_DIRECTORY="$FIXTURE_BUNDLE"; shared_waf_verified "$WAF_DIRECTORY"; }
shared_waf_cached() { shared_waf_prepare; }
shared_waf_refresh() { :; }
send_stats() { :; }
eval "$(declare -f shared_waf | sed '1s/shared_waf/shared_waf_real/')"
shared_waf() {
  # Match the real tool's successful JSON output without touching host jails.
  if [ "$1" = existing-filters ]; then printf '{"changed":false}\\n'; return 0; fi
  shared_waf_real "$@"
}
nginx_waf "$1"
'''
                script = root / 'entrypoint.sh'
                script.write_text(body)
                environment = dict(os.environ, PATH=str(root / 'bin') + ':' + os.environ['PATH'],
                    FIXTURE_ROOT=str(root), FIXTURE_CONTAINER=container, FIXTURE_DOCKER=docker,
                    FIXTURE_WAF=waf, FIXTURE_WAF_IMAGE=updater.WAF_CANDIDATE_IMAGE,
                    FIXTURE_BUNDLE=str(bundle), FIXTURE_PYTHON=sys.executable)

                def run(mode, fault=''):
                    result = subprocess.run(['bash', str(script), mode], env=dict(environment, FIXTURE_FAULT=fault),
                                            capture_output=True, text=True, timeout=240)
                    if fault:
                        self.assertNotEqual(result.returncode, 0, (mode, fault, result.stdout, result.stderr))
                    else:
                        self.assertEqual(result.returncode, 0, (mode, result.stdout, result.stderr))
                    return result

                def image():
                    return json.loads(updater.command(docker, 'inspect', container))[0]['Image']

                def http():
                    address = updater.command(*compose, 'port', 'nginx', '80').strip()
                    request = urllib.request.Request('http://' + address + '/', headers={'Host': 'live.example'})
                    with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=10) as response:
                        self.assertEqual(response.read(), b'migration-ok')

                try:
                    updater.command(*compose, 'up', '-d')
                    before_model = json.loads(updater.command(*compose, 'config', '--format', 'json'))
                    original_image = image()
                    before_nginx = (root / 'nginx.conf').read_bytes()
                    run('off')  # No WAF, no package state, no needless image migration.
                    self.assertFalse((root / 'config/waf/policy.json').exists())
                    for fault in ('pull', 'switch', 'policy'):
                        run('on', fault)
                        self.assertEqual(image(), original_image)
                        self.assertEqual((root / 'docker-compose.yml').read_bytes(), original_compose)
                        self.assertEqual((root / 'docker-compose.override.yml').read_bytes(), override)
                        self.assertEqual((root / 'nginx.conf').read_bytes(), before_nginx)
                        http()
                    run('on')
                    expected_waf = json.loads(updater.command(docker, 'image', 'inspect', waf))[0]['Id']
                    self.assertEqual(image(), expected_waf)
                    self.assertEqual((root / 'docker-compose.override.yml').read_bytes(), override)
                    effective = json.loads(updater.command(*compose, 'config', '--format', 'json'))
                    before_model['services']['nginx']['image'] = updater.WAF_CANDIDATE_IMAGE
                    self.assertEqual(effective, before_model)
                    actual = json.loads(updater.command(docker, 'inspect', container))[0]
                    self.assertIn('PRESERVE_LITERAL=hello$world', actual['Config']['Env'])
                    self.assertIn('OVERRIDE_FLAG=retained', actual['Config']['Env'])
                    if cf:
                        self.assertIn('real_ip_header CF-Connecting-IP;', updater.command(docker, 'exec', container, 'nginx', '-T'))
                    for mode in ('on', 'detect', 'off', 'on'):
                        run(mode)
                        self.assertEqual(image(), expected_waf)
                        policy = json.loads((root / 'config/waf/policy.json').read_text())
                        self.assertEqual(policy['mode'], mode)
                        http()
                    cleanup = root / 'remove-cron.sh'
                    cleanup.write_text(body.split('\nnginx_waf "$1"')[0] + '\nshared_waf_remove_rotation\n')
                    result = subprocess.run(['bash', str(cleanup)], env=environment, capture_output=True, text=True, timeout=30)
                    self.assertEqual(result.returncode, 0, result.stderr)
                    self.assertNotIn('kejilion-waf-logrotate', (root / 'private-cron').read_text())
                finally:
                    updater.command(*compose, 'down', '--remove-orphans')


if __name__ == '__main__':
    unittest.main()
