"""Offline behavioral tests of the updater embedded in the distributable script."""
import copy
import importlib.util
import json
import os
from pathlib import Path
import shutil
import subprocess
import tempfile
import unittest
from unittest.mock import patch

ROOT = Path(__file__).resolve().parents[1]
SCRIPT = (ROOT / 'kejilion.sh').read_text(encoding='utf-8')
BODY = SCRIPT.split("<<'NGINX_CONFIG_UPDATE'\n", 1)[1].split('\nNGINX_CONFIG_UPDATE\n', 1)[0]
updater = importlib.util.module_from_spec(importlib.util.spec_from_loader('nginx_config_update', loader=None))
exec(compile(BODY, 'kejilion.sh:nginx_config_update', 'exec'), updater.__dict__)
FIXTURES = ROOT / 'tests/fixtures/nginx-update'


def template(revision, name, prefix='https://'):
    return (FIXTURES / revision / name).read_bytes().decode('utf-8')


class MergeTests(unittest.TestCase):
    def test_nested_scopes_quotes_variables_and_customizations(self):
        old = 'events { worker_connections 1024; } http { set $x "a;#{}"; server { set $x one; } }'
        live = '# user\nevents { worker_connections 8192; } http { set $x "a;#{}"; server { set $x custom; } }'
        new = 'events { worker_connections 2048; } http { set $x "b;#{}"; server { set $x two; } map ${uri} $v { default ""; } }'
        result, kept = updater.merge_configuration(old, live, new)
        self.assertIn('worker_connections 8192;', result)
        self.assertIn('set $x "b;#{}";', result)
        self.assertIn('set $x custom;', result)
        self.assertIn('map ${uri} $v', result)
        self.assertTrue(result.startswith('# user'))
        self.assertIn('/http/server/set $x', kept)

    def test_added_root_include_precedes_events_and_disabled_values_stay_disabled(self):
        old = 'events {} http { gzip on; }'
        live = 'events {} http { # gzip on;\n }'
        new = 'include /etc/nginx/conf.d/waf/load-module*.conf; events {} http { gzip off; }'
        result, kept = updater.merge_configuration(old, live, new)
        self.assertLess(result.index('include'), result.index('events'))
        self.assertNotIn('gzip off;', result)
        self.assertIn('# gzip on;', result)

    def test_repeated_or_ambiguous_directives_are_preserved(self):
        old = 'http { add_header Vary A; add_header Vary B; }'
        new = 'http { add_header Vary C; }'
        result, kept = updater.merge_configuration(old, old, new)
        self.assertEqual(result, old)
        self.assertTrue(kept)

    def test_feature_switches_and_performance_mode_are_not_reset_by_new_defaults(self):
        old = 'worker_processes 2; events { worker_connections 1024; } http { gzip on; brotli off; modsecurity off; }'
        new = 'worker_processes auto; events { worker_connections 2048; } http { gzip off; brotli on; modsecurity on; }'
        result, _ = updater.merge_configuration(old, old, new)
        self.assertEqual(result, old)

    def test_malformed_configuration_is_rejected(self):
        for bad in ('http {', 'http { x "unclosed; }', 'x ${broken;'):
            with self.subTest(bad=bad), self.assertRaises(ValueError):
                updater.parse(bad)

    def test_real_upstream_templates_have_verified_hashes(self):
        for revision, files in updater.SOURCES.items():
            for name, expected in files.items():
                self.assertEqual(updater.digest(template(revision, name).encode()), expected)

    def test_previous_managed_buffers_migrate_and_custom_buffers_stay(self):
        old = template(updater.PREVIOUS, 'nginx10.conf')
        new = template(updater.REVISION, 'nginx10.conf')
        for live, expected_gzip in [(old, 'gzip_buffers 16 32k;'),
                                   (old.replace('gzip_buffers 8 256k;', 'gzip_buffers 32 16k;'), 'gzip_buffers 32 16k;')]:
            with self.subTest(custom=live != old):
                merged, _ = updater.merge_configuration(old, live, new)
                self.assertIn(expected_gzip, merged)
                self.assertIn('output_buffers 2 128k;', merged)
                self.assertIn('ssl_buffer_size 32k;', merged)


class TransactionTests(unittest.TestCase):
    def setUp(self):
        # The production writer requires a root-owned, non-world-writable ancestor chain.
        base = '/root' if hasattr(os, 'geteuid') and os.geteuid() == 0 else None
        self.temp = tempfile.TemporaryDirectory(prefix='nginx-update-test-', dir=base)
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name) / 'web'
        self.root.mkdir(mode=0o700)
        for directory in ('conf.d', 'stream.d', 'config/waf'):
            (self.root / directory).mkdir(parents=True, mode=0o700)
        self.seed('nginx.conf', template(updater.LEGACY, 'nginx10.conf').replace('worker_processes  auto;', 'worker_processes  7;'))
        self.seed('conf.d/default.conf', template(updater.LEGACY, 'default10.conf'))
        self.seed('conf.d/map.conf', template(updater.LEGACY, 'map.conf'))
        self.site = 'server { listen 443 ssl; server_name custom.example; ssl_certificate /custom/cert; location / { proxy_pass http://10.0.0.7:9999; } }\n'
        self.seed('conf.d/custom.example.conf', self.site)
        self.seed('stream.d/database.conf', 'server { listen 3333; proxy_pass db:3306; }\n')
        self.seed('docker-compose.yml', 'services: {}\n')
        self.model = {'name': 'custom-project', 'services': {
            'nginx': {'image': 'custom/nginx:latest', 'environment': {'PASSWORD': 'literal$$secret'},
                      'ports': ['127.0.0.1:8443:443'], 'networks': ['private'],
                      'volumes': [{'type': 'bind', 'source': str(self.root / name), 'target': target}
                                  for name, target in [('nginx.conf', '/etc/nginx/nginx.conf'),
                                                       ('conf.d', '/etc/nginx/conf.d'), ('stream.d', '/etc/nginx/stream.d')]]},
            'php': {'image': 'custom/php:8.3'}, 'mysql': {'image': 'custom/mysql:8.4'}},
            'networks': {'private': {'external': True}}}
        data = self.root / 'mysql'
        data.mkdir()
        (data / 'original').write_text('original database')
        self.images = {name: {'Id': 'container-' + name, 'Mounts': [], 'Image': 'sha256:' + str(number) * 64, 'State': {'Running': True}}
                       for number, name in enumerate(self.model['services'], 1)}
        self.images['mysql']['Mounts'] = [{'Destination': '/var/lib/mysql', 'Source': str(data), 'Type': 'bind', 'RW': True}]
        self.old_images = copy.deepcopy(self.images)
        self.runtime = {service: {path: (b'custom php socket/config\n' if path.endswith('www.conf') else None)
                                  for path in paths} for service, paths in updater.RUNTIME_PATHS.items() if service in self.images}
        self.old_runtime = copy.deepcopy(self.runtime)
        self.calls, self.failure, self.changed, self.switched = [], None, False, False
        self.directory = self.root / 'backups/nginx-update/fixture'
        self.directory.mkdir(parents=True, mode=0o700)
        updater.snapshot(self.root, self.directory)
        self.initial = {name: (self.root / name).read_bytes() for name in updater.inventory(self.root)}
        self.addCleanup(patch.stopall)
        patch.object(updater, 'download', side_effect=template).start()
        patch.object(updater, 'command', side_effect=self.command).start()
        patch.object(updater.time, 'sleep', return_value=None).start()

    def seed(self, name, text):
        path = self.root / name
        path.parent.mkdir(parents=True, exist_ok=True)
        path.write_bytes(text.encode('utf-8'))
        path.chmod(0o600)

    def command(self, *args):
        self.calls.append(args)
        if args[0] in {'du', 'tar'}:
            result = subprocess.run(args, capture_output=True, text=True)
            if result.returncode:
                raise RuntimeError(result.stderr)
            return result.stdout
        if args[:3] == ('docker', 'ps', '-q'):
            return ' '.join('container-' + name for name, value in self.images.items() if value['State']['Running'])
        if args[:2] == ('docker', 'cp'):
            if args[2].startswith('container-'):
                container, path = args[2].split(':', 1)
                value = self.runtime[container.removeprefix('container-')][path]
                if value is None:
                    raise RuntimeError('Could not find the file ' + path)
                Path(args[3]).write_bytes(value)
                Path(args[3]).chmod(0o600)
            else:
                container, path = args[3].split(':', 1)
                self.assertFalse(self.images[container.removeprefix('container-')]['State']['Running'])
                self.runtime[container.removeprefix('container-')][path] = Path(args[2]).read_bytes()
            return ''
        if args[:2] == ('docker', 'restart'):
            return ''
        if args[:2] == ('docker', 'exec') and args[2].startswith('container-'):
            if args[3:5] == ('sh', '-c') and 'MYSQL_PWD' in args[5]:
                if args[-1] == 'SELECT @@datadir':
                    return '/var/lib/mysql/\n'
                if args[-1] == 'SELECT @@socket':
                    return '/run/mysqld/mysqld.sock\n'
                if args[-1] == 'SELECT 1':
                    if self.failure == 'mysql-auth' and self.switched:
                        raise RuntimeError('Access denied after image switch')
                    return '1\n'
                if args[-1].startswith('SHOW VARIABLES LIKE'):
                    return ''
                if args[-1].startswith('SHOW VARIABLES'):
                    return 'innodb_data_file_path\tibdata1:12M:autoextend\ninnodb_undo_directory\t./\n'
                return './mysql.ibd\n'
            if args[3:6] == ('redis-cli', '--raw', 'CONFIG'):
                return 'dir\n/data\n' if args[-1] == 'dir' else 'unixsocket\n\n'
            if args[3:6] == ('redis-cli', '--raw', 'PING'):
                return 'PONG\n'
            if args[3:5] == ('readlink', '-f'):
                return args[-1].replace('/var/run/', '/run/')
            if args[3:5] == ('rm', '-f'):
                self.runtime[args[2].removeprefix('container-')][args[5]] = None
            return ''
        if args[0] == 'bash':
            if self.failure == 'php-hook':
                raise RuntimeError('PHP configuration failed')
            return ''
        if args[:2] == ('docker', 'inspect'):
            service = args[2].removeprefix('container-')
            return json.dumps([self.images[service]])
        if args[:3] == ('docker', 'exec', 'nginx'):
            if self.failure == 'ready' and self.switched:
                raise RuntimeError('candidate not ready')
            return ''
        if args[:2] == ('docker', 'top'):
            return 'PID COMMAND\n123 nginx: worker process\n'
        if args[:2] != ('docker', 'compose'):
            raise AssertionError(args)
        files = [Path(args[index + 1]) for index, item in enumerate(args) if item == '-f']
        if args[-3:] == ('config', '--format', 'json'):
            if not files:
                if getattr(self, 'waf_fixture', False):
                    current = copy.deepcopy(self.model)
                    current['services']['nginx']['image'] = json.loads((self.root / 'docker-compose.yml').read_text())['services']['nginx']['image']
                    return json.dumps(current)
                return json.dumps(self.model)
            literal = json.loads(files[0].read_text(encoding='utf-8'))
            return json.dumps(literal)
        if 'ps' in args:
            name = args[-1]
            return 'container-' + name if name in self.images else ''
        if 'pull' in args:
            if self.failure == 'pull':
                raise RuntimeError('pull failed')
            return ''
        if 'run' in args:
            candidate = self.unescape(json.loads(files[0].read_text(encoding='utf-8')))
            self.assertEqual(candidate['services']['nginx']['environment'], self.unescape(self.model['services']['nginx']['environment']))
            self.assertEqual(candidate['services']['nginx']['ports'], ['127.0.0.1:8443:443'])
            main_volume = candidate['services']['nginx']['volumes'][0]
            if not getattr(self, 'waf_fixture', False):
                self.assertIn('waf/load-module', Path(main_volume['source']).read_text(encoding='utf-8'))
            self.assertEqual((self.root / 'nginx.conf').read_bytes(), self.initial['nginx.conf'])
            if self.failure == 'preflight':
                raise RuntimeError('nginx -t failed')
            if self.failure == 'concurrent':
                self.seed('conf.d/custom.example.conf', self.site + '# concurrent administrator edit\n')
            return ''
        if 'up' in args:
            self.assertNotIn('down', args)
            if len(files) == 2:
                override = json.loads(files[-1].read_text(encoding='utf-8'))
                for name, value in override['services'].items():
                    self.images[name] = copy.deepcopy(self.old_images[name])
                    if name in updater.RUNTIME_PATHS:
                        self.runtime[name] = {path: b'image-default' for path in updater.RUNTIME_PATHS[name]}
                    self.images[name]['State']['Running'] = False
                    self.assertEqual(self.images[name]['Image'], value['image'])
                self.switched = False
                if self.failure == 'rollback':
                    raise RuntimeError('old image recovery failed')
                return ''
            services = args[args.index('never') + 1:]
            for name in services:
                prior = self.images.get(name, {'Id': 'container-' + name, 'Mounts': []})
                self.images[name] = dict(prior, Image='sha256:' + 'f' * 64, State={'Running': False})
                if name in updater.RUNTIME_PATHS:
                    self.runtime[name] = {path: b'image-default' for path in updater.RUNTIME_PATHS[name]}
            self.switched = True
            self.changed = True
            if self.failure in ('up', 'rollback'):
                raise RuntimeError('up failed')
            return ''
        if 'start' in args:
            for name in args[args.index('start') + 1:]:
                self.images[name]['State']['Running'] = True
            return ''
        if 'rm' in args:
            for name in args[args.index('-f') + 1:]:
                self.images.pop(name, None)
                self.runtime.pop(name, None)
            return ''
        if 'stop' in args:
            offset = args.index('stop') + (3 if '-t' in args else 1)
            for name in args[offset:]:
                if name in self.images:
                    self.images[name]['State']['Running'] = False
            return ''
        raise AssertionError(args)

    @classmethod
    def unescape(cls, data):
        if isinstance(data, str):
            return data.replace('$$', '$')
        if isinstance(data, list):
            return [cls.unescape(item) for item in data]
        if isinstance(data, dict):
            return {key: cls.unescape(value) for key, value in data.items()}
        return data

    def update(self, component='nginx'):
        updater.execute_update(self.root, self.directory, component, 'https://')

    def assert_restored(self):
        for name, data in self.initial.items():
            self.assertEqual((self.root / name).read_bytes(), data, name)
        self.assertFalse((self.root / updater.STATE).exists())
        self.assertEqual(self.images, self.old_images)
        self.assertEqual(self.normalized_runtime(self.runtime), self.normalized_runtime(self.old_runtime))

    @staticmethod
    def normalized_runtime(runtime):
        return {service: {path: value or None for path, value in files.items()} for service, files in runtime.items()}

    def prepare_waf(self):
        self.waf_fixture = True
        self.model['services']['nginx']['image'] = 'nginx:alpine'
        self.seed('docker-compose.yml', json.dumps(self.model))
        self.images['nginx']['Config'] = {'Image': 'nginx:alpine', 'Labels': {
            'com.docker.compose.project.config_files': str(self.root / 'docker-compose.yml')}}
        self.old_images = copy.deepcopy(self.images)
        updater.snapshot(self.root, self.directory)
        self.initial = {name: (self.root / name).read_bytes() for name in updater.inventory(self.root)}

    def test_waf_image_switch_preserves_custom_config_and_does_not_commit_before_policy(self):
        self.prepare_waf()
        updater.execute_update(self.root, self.directory, 'waf', 'https://')
        self.assertEqual(json.loads((self.directory / 'journal.json').read_text())['phase'], 'switching')
        self.assertEqual((self.root / 'nginx.conf').read_bytes(), self.initial['nginx.conf'])
        self.assertEqual(json.loads((self.root / 'docker-compose.yml').read_text())['services']['nginx']['image'], updater.WAF_CANDIDATE_IMAGE)
        updater.rollback(self.root, self.directory)  # A later policy/configuration failure.
        self.assertEqual((self.root / 'docker-compose.yml').read_bytes(), self.initial['docker-compose.yml'])
        self.assertEqual(self.images, self.old_images)

    def test_waf_pull_and_preflight_and_switch_failures_restore_compose_and_image(self):
        self.prepare_waf()
        updater.rollback(self.root, self.directory)
        for failure in ('pull', 'preflight', 'up', 'ready'):
            with self.subTest(failure=failure):
                self.failure = failure
                self.directory = self.root / 'backups/nginx-update' / failure
                self.directory.mkdir(mode=0o700)
                updater.snapshot(self.root, self.directory)
                with self.assertRaises(RuntimeError):
                    updater.execute_update(self.root, self.directory, 'waf', 'https://')
                updater.rollback(self.root, self.directory)
                self.assertEqual((self.root / 'docker-compose.yml').read_bytes(), self.initial['docker-compose.yml'])
                self.assertEqual(self.images, self.old_images)

    def test_waf_yaml_override_image_only_edit_preserves_comments_and_other_services(self):
        self.prepare_waf()
        original = '# user\nservices:\n  nginx:\n    environment:\n      CF_MODE: "true"\n    image: ${NGINX_IMAGE:-nginx:alpine} # old\n  php:\n    image: custom/php:8.3\n'
        self.seed('docker-compose.override.yml', original)
        container = copy.deepcopy(self.images['nginx'])
        container['Config']['Labels']['com.docker.compose.project.config_files'] += ',' + str(self.root / 'docker-compose.override.yml')
        name, result = updater.waf_image_plan(self.root, self.model, container)
        self.assertEqual(name, 'docker-compose.override.yml')
        self.assertEqual(result.decode(), original.replace('image: ${NGINX_IMAGE:-nginx:alpine} # old', 'image: ' + updater.WAF_CANDIDATE_IMAGE))
        self.assertRegex(updater.WAF_CANDIDATE_IMAGE, r'^kjlion/nginx:alpine@sha256:[0-9a-f]{64}$')

    def test_waf_custom_image_or_build_cannot_be_automatically_replaced(self):
        self.prepare_waf()
        for changes in ({'image': 'custom/nginx:latest'}, {'build': './custom'}):
            model = copy.deepcopy(self.model)
            model['services']['nginx'].update(changes)
            with self.assertRaisesRegex(ValueError, '自定义镜像'):
                updater.waf_image_plan(self.root, model, self.images['nginx'])

    def test_waf_image_plan_accepts_owned_tag_alias_and_current_pin(self):
        self.prepare_waf()
        for image in ('kjlion/nginx:alpine', 'docker.io/kjlion/nginx:alpine', updater.WAF_CANDIDATE_IMAGE):
            with self.subTest(image=image):
                model = copy.deepcopy(self.model)
                model['services']['nginx']['image'] = image
                name, data = updater.waf_image_plan(self.root, model, self.images['nginx'])
                self.assertEqual(name, 'docker-compose.yml')
                self.assertEqual(json.loads(data)['services']['nginx']['image'], updater.WAF_CANDIDATE_IMAGE)

    def test_managed_waf_tag_is_pinned_during_regular_upgrade(self):
        self.prepare_waf()
        self.model['services']['nginx']['image'] = 'kjlion/nginx:alpine'
        self.images['nginx']['Config']['Image'] = 'kjlion/nginx:alpine'
        self.seed('docker-compose.yml', json.dumps(self.model))
        updater.snapshot(self.root, self.directory)
        updater.execute_update(self.root, self.directory, 'nginx', 'https://')
        compose = json.loads((self.root / 'docker-compose.yml').read_text(encoding='utf-8'))
        self.assertEqual(compose['services']['nginx']['image'], updater.WAF_CANDIDATE_IMAGE)
        pinned = json.loads((self.directory / 'pinned.json').read_text(encoding='utf-8'))
        self.assertEqual(pinned['services']['nginx']['image'], updater.WAF_CANDIDATE_IMAGE)
        self.assertTrue(any('pull' in call and str(self.directory / 'pinned.json') in call for call in self.calls))

    def test_first_managed_image_upgrade_pins_when_running_container_is_official(self):
        self.prepare_waf()
        self.model['services']['nginx']['image'] = 'kjlion/nginx:alpine'
        self.seed('docker-compose.yml', json.dumps(self.model))
        updater.snapshot(self.root, self.directory)
        updater.execute_update(self.root, self.directory, 'nginx', 'https://')
        compose = json.loads((self.root / 'docker-compose.yml').read_text(encoding='utf-8'))
        self.assertEqual(compose['services']['nginx']['image'], updater.WAF_CANDIDATE_IMAGE)
        pinned = json.loads((self.directory / 'pinned.json').read_text(encoding='utf-8'))
        self.assertEqual(pinned['services']['nginx']['image'], updater.WAF_CANDIDATE_IMAGE)
        self.assertTrue(any('pull' in call and str(self.directory / 'pinned.json') in call for call in self.calls))

    def test_success_migrates_common_files_preserves_sites_and_persists_verified_baselines(self):
        original_inode = (self.root / 'nginx.conf').stat().st_ino
        self.update()
        main = (self.root / 'nginx.conf').read_text(encoding='utf-8')
        self.assertIn('worker_processes  7;', main)
        self.assertIn('waf/load-module', main)
        self.assertNotIn('X-XSS-Protection "1; mode=block"', main)
        self.assertIn('add_header_inherit merge;', (self.root / 'conf.d/default.conf').read_text(encoding='utf-8'))
        self.assertEqual((self.root / 'conf.d/custom.example.conf').read_text(encoding='utf-8'), self.site)
        self.assertEqual((self.root / 'nginx.conf').stat().st_ino, original_inode)
        state = json.loads((self.root / updater.STATE).read_text(encoding='utf-8'))
        self.assertEqual(len(state['files']), 3)
        self.assertEqual(state['files']['nginx.conf']['revision'], updater.REVISION)
        self.assertEqual(self.images['mysql'], self.old_images['mysql'])
        current = self.unescape(json.loads((self.directory / 'current.json').read_text(encoding='utf-8')))
        self.assertEqual(current, self.unescape(self.model))
        updater.rollback(self.root, self.directory)  # Committed updates are not reverted by EXIT.
        self.assertTrue((self.root / updater.STATE).exists())

    def test_repeat_update_is_idempotent_and_uses_verified_cached_templates(self):
        self.update()
        first = {name: (self.root / name).read_bytes() for name in updater.inventory(self.root)}
        second = self.root / 'backups/nginx-update/second'
        second.mkdir(mode=0o700)
        updater.snapshot(self.root, second)
        self.directory = second
        self.initial = first
        self.old_images = copy.deepcopy(self.images)
        self.switched = False
        with patch.object(updater, 'download', side_effect=AssertionError('cached templates should be used')):
            self.update()
        for name, data in first.items():
            self.assertEqual((self.root / name).read_bytes(), data, name)

    def test_failure_before_switch_keeps_live_files_and_images(self):
        for stage in ('pull', 'preflight'):
            with self.subTest(stage=stage):
                self.failure = stage
                with self.assertRaises(RuntimeError):
                    self.update()
                updater.rollback(self.root, self.directory)
                self.assert_restored()
                self.assertFalse(self.changed)

    def test_failed_switch_and_failed_readiness_restore_files_and_images(self):
        self.failure = 'ready'
        with self.assertRaises(RuntimeError):
            self.update()
        updater.rollback(self.root, self.directory)
        self.assert_restored()
        self.assertTrue(any('--pull' in call and 'never' in call for call in self.calls))

    def test_up_failure_restores_original_stopped_service_state(self):
        self.model['services']['redis'] = {'image': 'redis:latest'}
        data = self.root / 'redis'
        data.mkdir()
        self.images['redis'] = {'Id': 'container-redis', 'Image': 'sha256:' + 'a' * 64, 'State': {'Running': True},
                                'Mounts': [{'Destination': '/data', 'Source': str(data), 'Type': 'volume', 'Name': 'redis-data', 'RW': True}]}
        self.images['php']['State']['Running'] = False
        self.old_images = copy.deepcopy(self.images)
        self.failure = 'up'
        with self.assertRaises(RuntimeError):
            self.update('all')
        updater.rollback(self.root, self.directory)
        self.assert_restored()
        self.assertIn('redis', self.images)

    def test_full_update_covers_all_services_and_restores_php_configuration(self):
        self.update('all')
        self.assertTrue(any('--no-start' in call for call in self.calls))
        self.assertEqual(self.normalized_runtime(self.runtime), self.normalized_runtime(self.old_runtime))
        self.assertTrue(all(value['Image'] == 'sha256:' + 'f' * 64 for value in self.images.values()))
        self.assertFalse(any('down' in call or 'rmi' in call for call in self.calls))

    def test_full_update_does_not_enable_inactive_compose_profiles(self):
        self.model['services']['debug'] = {'image': 'debug:latest', 'profiles': ['debug']}
        with patch.dict(os.environ, {'COMPOSE_PROFILES': ''}):
            self.update('all')
        self.assertNotIn('debug', self.images)

    def test_failed_first_install_removes_only_new_container_and_restores_configuration(self):
        self.images, self.old_images = {}, {}
        self.failure = 'up'
        with self.assertRaises(RuntimeError):
            self.update()
        updater.rollback(self.root, self.directory)
        self.assert_restored()
        self.assertFalse(any('rollback.json' in ' '.join(call) for call in self.calls))

    def test_php_hook_failure_rolls_back_full_update(self):
        self.images.pop('php')
        self.runtime.pop('php')
        self.old_images, self.old_runtime = copy.deepcopy(self.images), copy.deepcopy(self.runtime)
        self.failure = 'php-hook'
        with self.assertRaises(RuntimeError):
            self.update('all')
        with self.assertRaisesRegex(RuntimeError, '业务写入阶段'):
            updater.rollback(self.root, self.directory)
        self.assertTrue((self.directory / 'data/0.tar').exists())

    def test_preexisting_admin_change_is_not_claimed_by_update(self):
        self.seed('conf.d/custom.example.conf', self.site + '# SSH administrator edit\n')
        self.failure = 'pull'
        with self.assertRaisesRegex(ValueError, '保留管理员修改'):
            self.update()
        updater.rollback(self.root, self.directory)
        self.assertIn('SSH administrator edit', (self.root / 'conf.d/custom.example.conf').read_text())

    def test_concurrent_administrator_changes_are_not_overwritten(self):
        self.failure = 'concurrent'
        with self.assertRaisesRegex(ValueError, '配置发生变化'):
            self.update()
        updater.rollback(self.root, self.directory)
        self.assertIn('concurrent administrator edit', (self.root / 'conf.d/custom.example.conf').read_text())
        self.assertEqual((self.root / 'nginx.conf').read_bytes(), self.initial['nginx.conf'])

    def test_rollback_failure_is_reported_and_recovery_point_is_retained(self):
        self.failure = 'rollback'
        with self.assertRaises(RuntimeError):
            self.update()
        with self.assertRaisesRegex(RuntimeError, 'recovery failed'):
            updater.rollback(self.root, self.directory)
        self.assertTrue((self.directory / 'current.json').exists())
        self.assertTrue((self.directory / 'before/nginx.conf').exists())

    def test_unsupported_mount_prevents_switch(self):
        self.model['services']['nginx']['volumes'].pop(0)
        with self.assertRaisesRegex(ValueError, 'bind'):
            self.update()
        updater.rollback(self.root, self.directory)
        self.assert_restored()

    def test_tampered_baseline_prevents_switch(self):
        self.seed(updater.STATE, json.dumps({'files': {}, 'templates': {updater.LEGACY + '/nginx10.conf': 'tampered'}}))
        with self.assertRaisesRegex(ValueError, '摘要|配置发生变化'):
            self.update()
        self.assertFalse(self.changed)

    def test_cf_mode_and_custom_trust_are_preserved(self):
        self.seed('conf.d/default.conf', template(updater.LEGACY, 'default11.conf') + '\nset_real_ip_from 192.0.2.0/24;\n')
        updater.snapshot(self.root, self.directory)
        self.initial = {name: (self.root / name).read_bytes() for name in updater.inventory(self.root)}
        self.update()
        data = (self.root / 'conf.d/default.conf').read_text(encoding='utf-8')
        self.assertIn('real_ip_header CF-Connecting-IP;', data)
        self.assertIn('set_real_ip_from 192.0.2.0/24;', data)
        self.assertIn('add_header_inherit merge;', data)

    def test_native_cdn_mode_switch_does_not_block_subsequent_updates(self):
        self.update()
        self.seed('conf.d/default.conf', template(updater.LEGACY, 'default11.conf'))
        second = self.root / 'backups/nginx-update/cdn-mode'
        second.mkdir(mode=0o700)
        updater.snapshot(self.root, second)
        self.directory = second
        self.initial = {name: (self.root / name).read_bytes() for name in updater.inventory(self.root)}
        self.switched = False
        self.update()
        state = json.loads((self.root / updater.STATE).read_text(encoding='utf-8'))
        self.assertEqual(state['files']['conf.d/default.conf']['source'], 'default11.conf')

    def test_missing_common_file_is_not_reintroduced(self):
        (self.root / 'conf.d/default.conf').unlink()
        updater.snapshot(self.root, self.directory)
        self.update()
        self.assertFalse((self.root / 'conf.d/default.conf').exists())

    def test_keyboard_interrupt_during_inplace_write_can_restore_actual_postimage(self):
        original = updater.write
        def interrupted(path, data, mode=0o600, inplace=False):
            if path == self.root / 'nginx.conf' and inplace:
                path.write_bytes(b'')
                raise KeyboardInterrupt()
            return original(path, data, mode, inplace)
        with patch.object(updater, 'write', side_effect=interrupted), self.assertRaises(KeyboardInterrupt):
            self.update()
        updater.rollback(self.root, self.directory)
        self.assert_restored()

    def test_cold_data_rollback_removes_new_files_and_preserves_links_modes(self):
        data = self.root / 'mysql'
        (data / 'original').chmod(0o640)
        os.link(data / 'original', data / 'hardlink')
        (data / 'symlink').symlink_to('original')
        self.update('all')
        journal = json.loads((self.directory / 'journal.json').read_text())
        journal['phase'] = 'switching'  # Exercise recovery of a switched, uncommitted candidate.
        updater.json_write(self.directory / 'journal.json', journal)
        (data / 'original').write_text('new database dictionary')
        (data / 'new-table').write_text('candidate-only')
        updater.rollback(self.root, self.directory)
        self.assertEqual((data / 'original').read_text(), 'original database')
        self.assertEqual((data / 'original').stat().st_mode & 0o777, 0o640)
        self.assertEqual((data / 'original').stat().st_ino, (data / 'hardlink').stat().st_ino)
        self.assertTrue((data / 'symlink').is_symlink())
        self.assertFalse((data / 'new-table').exists())

    def test_tampered_data_backup_is_rejected_before_deleting_live_data(self):
        self.update('all')
        (self.directory / 'data/0.tar').write_bytes(b'corrupt')
        compose = updater.compose_file(self.directory, 'current.json.test', self.model)
        with self.assertRaisesRegex(ValueError, '摘要'):
            updater.restore_data(self.directory, compose, list(self.model['services']))
        self.assertEqual((self.root / 'mysql/original').read_text(), 'original database')

    def test_full_update_requires_real_persistent_database_mount(self):
        self.images['mysql']['Mounts'] = []
        with self.assertRaisesRegex(ValueError, 'bind/named volume'):
            self.update('all')
        self.assertFalse(self.switched)

    def test_database_space_budget_fails_before_stop_or_switch(self):
        with patch.object(updater.shutil, 'disk_usage', return_value=type('Usage', (), {'free': 1})()), self.assertRaisesRegex(ValueError, '冷备空间不足'):
            self.update('all')
        self.assertFalse(any('stop' in call for call in self.calls))
        self.assertFalse(self.switched)

    def test_runtime_configuration_is_copied_before_first_container_start(self):
        self.update('all')
        copied = [i for i, call in enumerate(self.calls) if call[:2] == ('docker', 'cp') and call[3].startswith('container-')]
        self.assertTrue(copied)
        # The command fixture also asserts every cp destination is stopped.
        for i in copied:
            service = self.calls[i][3].split(':')[0].removeprefix('container-')
            self.assertTrue(any(j > i and 'start' in call and service in call for j, call in enumerate(self.calls)))

    def test_isolated_database_model_removes_all_network_and_published_port_paths(self):
        self.model['services']['mysql'].update(ports=['3306:3306'], networks=['private'], depends_on=['php'])
        self.update('all')
        isolated = json.loads((self.directory / 'database-validation.json').read_text())
        service = isolated['services']['mysql']
        self.assertEqual(service['network_mode'], 'none')
        for field in ('ports', 'networks', 'depends_on', 'links'):
            self.assertNotIn(field, service)

    def test_new_mysql_authentication_failure_is_caught_before_business_exposure(self):
        self.failure = 'mysql-auth'
        with self.assertRaisesRegex(RuntimeError, '未通过就绪检查'):
            self.update('all')
        self.assertEqual(json.loads((self.directory / 'journal.json').read_text())['phase'], 'switching')
        updater.rollback(self.root, self.directory)
        self.assert_restored()

    def test_exposed_candidate_failure_keeps_acknowledged_database_writes(self):
        original = self.command
        def command(*args):
            result = original(*args)
            if 'start' in args and 'current.json' in ' '.join(args):
                (self.root / 'mysql/original').write_text('acknowledged business write')
                raise RuntimeError('post-exposure failure')
            return result
        with patch.object(updater, 'command', side_effect=command), self.assertRaisesRegex(RuntimeError, 'post-exposure'):
            self.update('all')
        with self.assertRaisesRegex(RuntimeError, '业务写入阶段'):
            updater.rollback(self.root, self.directory)
        self.assertEqual((self.root / 'mysql/original').read_text(), 'acknowledged business write')
        self.assertTrue(all(value['Image'] == 'sha256:' + 'f' * 64 for value in self.images.values()))

    def test_stopped_database_is_rejected_before_writes_or_container_switch(self):
        self.images['mysql']['State']['Running'] = False
        with self.assertRaisesRegex(ValueError, '数据库未运行'):
            self.update('all')
        self.assertEqual((self.root / 'nginx.conf').read_bytes(), self.initial['nginx.conf'])
        self.assertFalse(any('up' in call or 'stop' in call for call in self.calls))

    def test_external_database_volume_writer_prevents_switch(self):
        self.images['external'] = copy.deepcopy(self.images['mysql'])
        self.images['external']['Id'] = 'container-external'
        with self.assertRaisesRegex(ValueError, '其他运行容器共享'):
            self.update('all')
        self.assertFalse(self.switched)

    def test_container_nested_data_mount_is_rejected_even_when_host_root_is_plain_directory(self):
        outside = self.root / 'actual-mysql-data'
        outside.mkdir()
        self.images['mysql']['Mounts'].append({'Destination': '/var/lib/mysql/custom', 'Source': str(outside), 'Type': 'bind', 'RW': True})
        with self.assertRaisesRegex(ValueError, '嵌套数据挂载'):
            self.update('all')
        self.assertFalse(self.switched)

    def test_external_data_symlink_is_rejected_but_standard_socket_link_is_supported(self):
        data = self.root / 'mysql'
        (data / 'internal-link').symlink_to('/var/lib/mysql/original')
        (data / 'mysql.sock').symlink_to('/var/run/mysqld/mysqld.sock')
        updater.prepare_data(self.directory, updater.compose_file(self.directory, 'socket.json', self.model), list(self.model['services']))
        (data / 'external-table.ibd').symlink_to(self.root / 'outside-table.ibd')
        with self.assertRaisesRegex(ValueError, '外部符号链接'):
            self.update('all')
        self.assertFalse(self.switched)

    def test_external_mysql_log_or_tablespace_path_is_rejected_before_switch(self):
        original = self.command
        for query_kind in ('SHOW VARIABLES', 'SELECT PATH'):
            def command(*args):
                if args[0] == 'docker' and args[-1].startswith(query_kind):
                    return 'innodb_undo_directory\t/external/undo\n' if query_kind == 'SHOW VARIABLES' else '/external/table.ibd\n'
                return original(*args)
            with self.subTest(query=query_kind), patch.object(updater, 'command', side_effect=command), self.assertRaisesRegex(ValueError, '冷备|表空间'):
                updater.prepare_data(self.directory, ['docker', 'compose'], list(self.model['services']))
            self.assertFalse(self.switched)

    def test_shared_database_unix_socket_is_rejected_with_run_alias_normalization(self):
        original = self.command
        self.images['mysql']['Mounts'].append({'Destination': '/run/shared', 'Source': str(self.root / 'shared-socket'), 'Type': 'bind', 'RW': True})
        for socket in ('/var/run/shared/mysql.sock', './shared.sock'):
            def command(*args):
                if args[0] == 'docker' and args[-1] == 'SELECT @@socket':
                    return socket + '\n'
                return original(*args)
            with self.subTest(socket=socket), patch.object(updater, 'command', side_effect=command), self.assertRaisesRegex(ValueError, 'Unix socket.*共享挂载'):
                updater.prepare_data(self.directory, ['docker', 'compose'], list(self.model['services']))


class EntryPointTests(unittest.TestCase):
    @unittest.skipUnless(os.name != 'nt', 'requires Linux Bash and /proc')
    def test_waf_commit_handoff_and_interrupted_policy_do_not_rollback_image(self):
        start = SCRIPT.index('nginx_update_transaction() {\n')
        body = SCRIPT[start:SCRIPT.index('\n}\n', start) + 3]
        with tempfile.TemporaryDirectory(prefix='nginx-waf-handoff-', dir='/root') as temporary:
            root = Path(temporary)
            body = body.replace('/home/web', str(root)).replace('/run/lock', str(root))
            shell = '''
WAF_PYTHON=python3
send_stats() { :; }
shared_waf() { echo unexpected-policy-rollback >> "$ACTIONS"; }
nginx_waf_configure() {
  if [ "$SCENARIO" = interrupted ]; then kill -TERM "$BASHPID"; fi
  printf '{"backup":"/test-policy"}\\n'
}
nginx_config_update() {
  printf '%s\\n' "$1" >> "$ACTIONS"
  case "$1" in
    commit-waf) touch "$COMMITTED"; return 1 ;;
    phase) if [ -f "$COMMITTED" ]; then echo committed; else echo switching; fi ;;
  esac
}
'''+body+'\nnginx_update_transaction waf on\n'
            for scenario, code in [('handoff', 1), ('interrupted', 86)]:
                log, committed = root / 'actions', root / 'committed'
                log.write_text('')
                committed.unlink(missing_ok=True)
                result = subprocess.run(['bash', '-c', shell], capture_output=True, text=True,
                                        env=dict(os.environ, ACTIONS=str(log), COMMITTED=str(committed), SCENARIO=scenario), timeout=20)
                self.assertEqual(result.returncode, code, result.stderr)
                self.assertNotIn('rollback', log.read_text())

    def test_cli_and_panel_full_update_use_same_transaction(self):
        body = SCRIPT.split('ldnmp_update_action() {\n', 1)[1].split('\n}\n', 1)[0]
        self.assertIn('ldnmp_upgrade_all', body)
        menu = SCRIPT.split('确定更新LDNMP环境吗？', 1)[1].split('\n\t38)', 1)[0]
        self.assertIn('ldnmp_upgrade_all', menu)
        self.assertNotIn('down --rmi all', menu)
        self.assertIn('nginx_update_transaction nginx', SCRIPT)
        self.assertIn('nginx_update_transaction all', SCRIPT)

    @unittest.skipUnless(os.name != 'nt' or os.environ.get('KJ_TEST_BASH'), 'requires Git Bash or Linux Bash')
    def test_shell_exit_trap_preserves_failures_and_reports_failed_recovery(self):
        interpreter = os.environ.get('KJ_TEST_BASH') or shutil.which('bash')
        start = SCRIPT.index('nginx_update_transaction() {\n')
        body = SCRIPT[start:SCRIPT.index('\n}\n', start) + 3]
        with tempfile.TemporaryDirectory(prefix='nginx-wrapper-') as temporary:
            root = Path(temporary)
            log = root / 'actions'
            isolated = body.replace('/home/web', root.as_posix()).replace('/run/lock', root.as_posix())
            shell = '''
flock() { [ "${BUSY:-0}" = 0 ]; }
python3() { :; }
shared_waf_refresh() { return "${WAF_FAILURE:-0}"; }
send_stats() { :; }
nginx_config_update() {
  printf '%s\\n' "$1" >> "$ACTIONS"
  if [ "$1" = rollback ]; then return "${RECOVERY_FAILURE:-0}"; fi
  [ "$1" != "${FAIL_STAGE:-}" ]
}
'''+isolated+'\nnginx_update_transaction nginx\n'
            scenarios = [({}, 0, True), ({'FAIL_STAGE': 'prepare'}, 1, False),
                         ({'FAIL_STAGE': 'update'}, 1, True), ({'WAF_FAILURE': '3'}, 3, False),
                         ({'FAIL_STAGE': 'update', 'RECOVERY_FAILURE': '1'}, 86, True),
                         ({'BUSY': '1'}, 75, False)]
            for settings, code, recovered in scenarios:
                log.write_text('')
                result = subprocess.run([interpreter, '-c', shell], capture_output=True, text=True, encoding='utf-8',
                                        env=dict(os.environ, ACTIONS=log.as_posix(), **settings), timeout=20)
                self.assertEqual(result.returncode, code, (settings, result.stderr))
                self.assertEqual('rollback' in log.read_text().splitlines(), recovered, settings)

    @unittest.skipUnless(os.name != 'nt', 'requires Linux /proc and flock')
    def test_nested_panel_update_reuses_environment_lock_without_unlocking_parent(self):
        start = SCRIPT.index('nginx_update_transaction() {\n')
        body = SCRIPT[start:SCRIPT.index('\n}\n', start) + 3]
        with tempfile.TemporaryDirectory(prefix='nginx-held-lock-') as temporary:
            root = Path(temporary)
            isolated = body.replace('/home/web', str(root)).replace('/run/lock', str(root))
            shell = '''
shared_waf_refresh() { :; }
send_stats() { :; }
nginx_config_update() { :; }
'''+isolated+'''
exec {lock_fd}>>"$LOCK_PATH"
flock -n "$lock_fd" || exit 90
nginx_update_transaction nginx || exit 91
if flock -n "$LOCK_PATH" true; then exit 92; fi
'''
            result = subprocess.run(['bash', '-c', shell], capture_output=True, text=True, encoding='utf-8',
                                    env=dict(os.environ, LOCK_PATH=str(root / 'kejilion-web-environment.lock')), timeout=20)
            self.assertEqual(result.returncode, 0, result.stderr)


if __name__ == '__main__':
    unittest.main()
