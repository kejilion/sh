"""Opt-in, isolated Docker validation: KJ_NGINX_UPDATE_LIVE=1 python3 <this file>."""
import json
import os
from pathlib import Path
import tempfile
import unittest
import urllib.request
import uuid
from unittest.mock import patch

from test_nginx_config_update import updater, template


@unittest.skipUnless(os.environ.get('KJ_NGINX_UPDATE_LIVE') == '1', 'opt-in Docker fixture')
class DockerUpdateTests(unittest.TestCase):
    def test_real_preflight_switch_and_old_image_recovery(self):
        image = os.environ.get('KJ_NGINX_UPDATE_IMAGE', 'nginx:1.29-alpine')
        real_command = updater.command
        original = json.loads(real_command('docker', 'image', 'inspect', image))[0]['Id']
        name = 'kj-nginx-update-' + uuid.uuid4().hex[:12]
        container = name + '-nginx'
        php_container = name + '-php'
        candidate_image = name + ':candidate'
        base = tempfile.TemporaryDirectory(prefix=name + '-', dir='/root')
        root = Path(base.name)
        compose = ['docker', 'compose', '--project-directory', str(root), '-f', str(root / 'docker-compose.yml')]
        created_image = False
        try:
            for directory in ('conf.d', 'stream.d', 'certs'):
                (root / directory).mkdir(mode=0o700)
            real_command('openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1',
                         '-subj', '/CN=localhost', '-keyout', str(root / 'certs/default_server.key'),
                         '-out', str(root / 'certs/default_server.crt'))
            (root / 'nginx.conf').write_bytes(template(updater.LEGACY, 'nginx10.conf').encode())
            (root / 'conf.d/default.conf').write_bytes(template(updater.LEGACY, 'default10.conf').encode())
            (root / 'conf.d/map.conf').write_bytes(template(updater.LEGACY, 'map.conf').encode())
            site = b'server { listen 80; server_name live.example; location / { return 200 "updater-live-ok"; } }\n'
            (root / 'conf.d/live.example.conf').write_bytes(site)
            model = {'name': name, 'services': {'nginx': {
                'image': image, 'container_name': container,
                'environment': {'LIVE_LITERAL': 'hello$$world'}, 'ports': ['127.0.0.1::80'],
                'volumes': [{'type': 'bind', 'source': str(root / relative), 'target': target}
                            for relative, target in [('nginx.conf', '/etc/nginx/nginx.conf'),
                                                     ('conf.d', '/etc/nginx/conf.d'),
                                                     ('stream.d', '/etc/nginx/stream.d'),
                                                     ('certs', '/etc/nginx/certs')]]},
                'php': {'image': image, 'container_name': php_container}}}
            (root / 'docker-compose.yml').write_text(json.dumps(model), encoding='utf-8')
            real_command(*compose, 'up', '-d')
            # A lightweight sidecar exercises real container-config snapshots without
            # downloading a PHP image or touching any host PHP installation.
            real_command('docker', 'exec', php_container, 'sh', '-c',
                         'mkdir -p /usr/local/etc/php-fpm.d; printf "custom-socket-config\\n" > /usr/local/etc/php-fpm.d/www.conf')
            # A metadata-only image supplies a distinct candidate ID without downloads/builds.
            real_command('docker', 'commit', '-c', 'LABEL kejilion.updater.fixture=true', container, candidate_image)
            created_image = True
            candidate_id = json.loads(real_command('docker', 'image', 'inspect', candidate_image))[0]['Id']
            self.assertNotEqual(original, candidate_id)
            model['services']['nginx']['image'] = candidate_image
            model['services']['php']['image'] = candidate_image
            (root / 'docker-compose.yml').write_text(json.dumps(model), encoding='utf-8')
            mode = {'value': 'preflight-failure'}

            def command(*args):
                if args[:3] in (('docker', 'exec', 'nginx'), ('docker', 'top', 'nginx')):
                    args = (*args[:2], container, *args[3:])
                if args[:2] == ('docker', 'compose') and 'pull' in args:
                    # All inputs are local and pinned for this fixture.
                    return ''
                if mode['value'] == 'preflight-failure' and args[:2] == ('docker', 'compose') and 'run' in args:
                    # Corrupt only the staged file. A real nginx -t must reject it.
                    staged = json.loads(Path(args[args.index('-f') + 1]).read_text())
                    main = next(volume['source'] for volume in staged['services']['nginx']['volumes']
                                if volume['target'] == '/etc/nginx/nginx.conf')
                    with Path(main).open('a') as stream:
                        stream.write('\nunknown_fixture_directive;\n')
                result = real_command(*args)
                if (mode['value'] == 'switch-failure' and args[:2] == ('docker', 'compose') and
                        'start' in args):
                    mode['value'] = 'recovering'
                    raise RuntimeError('fixture: connection lost after actual container recreation')
                return result

            def recovery_point(label):
                directory = root / 'backups/nginx-update' / label
                directory.mkdir(parents=True, mode=0o700)
                updater.snapshot(root, directory)
                return directory

            def current_image():
                return json.loads(real_command('docker', 'inspect', container))[0]['Image']

            def check_http():
                binding = real_command(*compose, 'port', 'nginx', '80').strip()
                request = urllib.request.Request('http://' + binding + '/', headers={'Host': 'live.example'})
                with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=5) as response:
                    self.assertEqual(response.read(), b'updater-live-ok')

            with patch.object(updater, 'command', side_effect=command), patch.object(updater, 'download', side_effect=template):
                first = recovery_point('preflight')
                before = (root / 'nginx.conf').read_bytes()
                with self.assertRaises(RuntimeError):
                    updater.execute_update(root, first, 'nginx', 'https://')
                updater.rollback(root, first)
                self.assertEqual(current_image(), original)
                self.assertEqual((root / 'nginx.conf').read_bytes(), before)
                check_http()
                mode['value'] = 'switch-failure'
                second = recovery_point('rollback')
                with self.assertRaisesRegex(RuntimeError, 'connection lost'):
                    updater.execute_update(root, second, 'nginx', 'https://')
                updater.rollback(root, second)
                self.assertEqual(current_image(), original)
                self.assertEqual((root / 'nginx.conf').read_bytes(), before)
                self.assertEqual(real_command('docker', 'exec', php_container, 'cat', '/usr/local/etc/php-fpm.d/www.conf'), 'custom-socket-config\n')
                check_http()
                mode['value'] = 'success'
                third = recovery_point('success')
                updater.execute_update(root, third, 'nginx', 'https://')
                self.assertEqual(current_image(), candidate_id)
                self.assertIn(b'waf/load-module', (root / 'nginx.conf').read_bytes())
                self.assertEqual((root / 'conf.d/live.example.conf').read_bytes(), site)
                self.assertEqual(real_command('docker', 'exec', php_container, 'cat', '/usr/local/etc/php-fpm.d/www.conf'), 'custom-socket-config\n')
                actual = json.loads(real_command('docker', 'inspect', container))[0]
                self.assertIn('LIVE_LITERAL=hello$world', actual['Config']['Env'])
                check_http()
        finally:
            real_command(*compose, 'down', '--remove-orphans')
            if created_image:
                real_command('docker', 'image', 'rm', candidate_image)
            base.cleanup()


if __name__ == '__main__':
    unittest.main()
