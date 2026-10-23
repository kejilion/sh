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
        self.images = {name: {'Image': 'sha256:' + str(number) * 64, 'State': {'Running': True}}
                       for number, name in enumerate(self.model['services'], 1)}
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
                self.runtime[container.removeprefix('container-')][path] = Path(args[2]).read_bytes()
            return ''
        if args[:2] == ('docker', 'restart'):
            return ''
        if args[:2] == ('docker', 'exec') and args[2].startswith('container-'):
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
            self.assertIn('waf/load-module', Path(main_volume['source']).read_text(encoding='utf-8'))
            self.assertEqual((self.root / 'nginx.conf').read_bytes(), self.initial['nginx.conf'])
            if self.failure == 'preflight':
                raise RuntimeError('nginx -t failed')
            if self.failure == 'concurrent':
                self.seed('conf.d/custom.example.conf', self.site + '# concurrent administrator edit\n')
            return ''
        if 'up' in args:
            self.assertNotIn('down', args)
            if '--pull' in args:
                override = json.loads(files[-1].read_text(encoding='utf-8'))
                for name, value in override['services'].items():
                    self.images[name] = copy.deepcopy(self.old_images[name])
                    if name in updater.RUNTIME_PATHS:
                        self.runtime[name] = {path: b'image-default' for path in updater.RUNTIME_PATHS[name]}
                    self.assertEqual(self.images[name]['Image'], value['image'])
                self.switched = False
                if self.failure == 'rollback':
                    raise RuntimeError('old image recovery failed')
                return ''
            services = args[args.index('--no-deps') + 1:]
            for name in services:
                self.images[name] = {'Image': 'sha256:' + 'f' * 64, 'State': {'Running': True}}
                if name in updater.RUNTIME_PATHS:
                    self.runtime[name] = {path: b'image-default' for path in updater.RUNTIME_PATHS[name]}
            self.switched = True
            self.changed = True
            if self.failure in ('up', 'rollback'):
                raise RuntimeError('up failed')
            return ''
        if 'rm' in args:
            for name in args[args.index('-f') + 1:]:
                self.images.pop(name, None)
                self.runtime.pop(name, None)
            return ''
        if 'stop' in args:
            for name in args[args.index('stop') + 1:]:
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
        self.assertEqual(self.runtime, self.old_runtime)

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
        self.images['mysql']['State']['Running'] = False
        self.old_images = copy.deepcopy(self.images)
        self.failure = 'up'
        with self.assertRaises(RuntimeError):
            self.update('all')
        updater.rollback(self.root, self.directory)
        self.assert_restored()
        self.assertNotIn('redis', self.images)

    def test_full_update_covers_all_services_and_restores_php_configuration(self):
        self.update('all')
        self.assertTrue(any(call[:2] == ('docker', 'restart') for call in self.calls))
        self.assertEqual(self.runtime, self.old_runtime)
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
        self.assertFalse(any('--pull' in call and 'never' in call for call in self.calls))

    def test_php_hook_failure_rolls_back_full_update(self):
        self.images.pop('php')
        self.runtime.pop('php')
        self.old_images, self.old_runtime = copy.deepcopy(self.images), copy.deepcopy(self.runtime)
        self.failure = 'php-hook'
        with self.assertRaises(RuntimeError):
            self.update('all')
        updater.rollback(self.root, self.directory)
        self.assert_restored()

    def test_shared_waf_changes_are_included_in_recovery_point(self):
        self.seed('conf.d/custom.example.conf', self.site + '# WAF-managed change\n')
        self.seed('conf.d/waf/http.conf', 'modsecurity off;\n')
        updater.remember(self.root, self.directory)
        self.failure = 'pull'
        with self.assertRaises(RuntimeError):
            self.update()
        updater.rollback(self.root, self.directory)
        self.assert_restored()
        self.assertFalse((self.root / 'conf.d/waf/http.conf').exists())

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
        with self.assertRaisesRegex(ValueError, '摘要'):
            self.update()
        self.assertFalse(self.changed)

    def test_cf_mode_and_custom_trust_are_preserved(self):
        self.seed('conf.d/default.conf', template(updater.LEGACY, 'default11.conf') + '\nset_real_ip_from 192.0.2.0/24;\n')
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
        self.update()
        self.assertFalse((self.root / 'conf.d/default.conf').exists())


class EntryPointTests(unittest.TestCase):
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
                         ({'FAIL_STAGE': 'update'}, 1, True), ({'WAF_FAILURE': '3'}, 3, True),
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
