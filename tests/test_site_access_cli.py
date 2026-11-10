import os
from pathlib import Path
import sys
import tempfile
import unittest
from unittest import mock

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import site_access_cli as cli
import site_access_transaction as txn


@unittest.skipUnless(sys.platform == 'linux', 'requires Linux atomic exchange')
class SiteAccessCLITests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='site-access-cli-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        (self.root / 'conf.d').mkdir()
        self.config = self.root / 'conf.d' / 'example.com.conf'
        self.config.write_text('server { location /admin/ { proxy_pass http://app; auth_basic "Private"; auth_basic_user_file /etc/nginx/conf.d/.users; } }')
        self.users = self.root / 'conf.d' / '.users'
        self.users.write_text('alice:old\n')
        self.rootfd = os.open(self.root, os.O_RDONLY | os.O_DIRECTORY)
        self.addCleanup(os.close, self.rootfd)
        self.request = {
            'operation': 'update', 'configName': 'example.com.conf',
            'configVersion': txn.digest(self.config.read_bytes()), 'fileVersion': txn.digest(self.users.read_bytes()),
            'serverIndex': 0, 'scope': 'location', 'path': '/admin/', 'modifier': '',
            'username': 'bob', 'previousUsername': 'alice', 'password': 'test-secret',
        }

    def test_account_edit_follows_actual_rule_and_preserves_config(self):
        before = self.config.read_bytes()
        result = cli.apply_account(self.rootfd, self.request)
        self.assertEqual(result, txn.digest(self.users.read_bytes()))
        self.assertIn('bob:$apr1$', self.users.read_text())
        self.assertNotIn('test-secret', self.users.read_text())
        self.assertEqual(self.config.read_bytes(), before)

    def test_rejects_stale_configuration_or_file(self):
        self.config.write_text(self.config.read_text() + '\n# changed\n')
        before = self.users.read_bytes()
        with self.assertRaises(txn.Conflict):
            cli.apply_account(self.rootfd, self.request)
        self.assertEqual(self.users.read_bytes(), before)

    def test_rejects_target_escape_and_unknown_fields(self):
        for value in ('/etc/nginx/conf.d/../../outside', '/etc/shadow', '/var/www/html/$user'):
            with self.subTest(value=value), self.assertRaises(cli.ConfigError):
                fd, _ = cli.file_target(self.rootfd, value)
                os.close(fd)
        self.request['untrusted'] = True
        with self.assertRaises(cli.ConfigError):
            cli.apply_account(self.rootfd, self.request)

    def test_parent_symlink_is_not_followed(self):
        (self.root / 'html').mkdir()
        (self.root / 'html' / 'link').symlink_to(self.root / 'conf.d', target_is_directory=True)
        with self.assertRaises(OSError):
            cli.file_target(self.rootfd, '/var/www/html/link/.users')

    def test_account_file_can_use_relative_nginx_prefix(self):
        self.config.write_text(self.config.read_text().replace('/etc/nginx/conf.d/.users', 'conf.d/.users'))
        self.request['configVersion'] = txn.digest(self.config.read_bytes())
        cli.apply_account(self.rootfd, self.request)
        self.assertIn('bob:$apr1$', self.users.read_text())

    def test_explicit_rule_remains_editable_when_site_has_includes(self):
        self.config.write_text(self.config.read_text().replace('server {', 'server { include common.conf;')
                               .replace('location /admin/ {', 'location /admin/ { include proxy.conf;'))
        self.request['configVersion'] = txn.digest(self.config.read_bytes())
        cli.apply_account(self.rootfd, self.request)
        self.assertIn('bob:$apr1$', self.users.read_text())

    def test_add_and_delete_rule_through_structured_protocol(self):
        self.config.write_text('server { location /admin/ { proxy_pass http://app; } }')
        request = {'operation': 'rule-add', 'configName': self.config.name,
                   'configVersion': txn.digest(self.config.read_bytes()), 'serverIndices': [0],
                   'scope': 'location', 'path': '/admin/', 'modifier': '',
                   'username': 'bob', 'password': 'synthetic-secret'}
        cli.apply_rule(self.rootfd, request, validate=lambda: None, reload_config=lambda: None,
                       worker_group=os.getegid, verify_read=lambda path: None, global_policy=lambda: b'events {} http {}')
        self.assertIn('proxy_pass http://app;', self.config.read_text())
        created = list((self.root / 'conf.d').glob('.site-auth-*.passwd'))
        self.assertEqual(len(created), 1)
        self.assertNotIn('synthetic-secret', created[0].read_text())
        request = {'operation': 'rule-delete', 'configName': self.config.name,
                   'configVersion': txn.digest(self.config.read_bytes()), 'serverIndex': 0,
                   'scope': 'location', 'path': '/admin/', 'modifier': '',
                   'fileVersion': txn.digest(created[0].read_bytes())}
        cli.apply_rule(self.rootfd, request, validate=lambda: None, reload_config=lambda: None)
        self.assertNotIn('auth_basic', self.config.read_text())
        self.assertNotIn('kpanel-access-password-satisfy', self.config.read_text())
        self.assertNotIn('satisfy all', self.config.read_text())
        self.assertIn('proxy_pass http://app;', self.config.read_text())
        self.assertTrue(created[0].exists(), 'a password file can be shared by other rules')

    def test_creation_applies_to_each_matching_server_before_reload(self):
        staged_name = '.site-create-' + 'a' * 32 + '.pending'
        staged = self.root / 'conf.d' / staged_name
        self.config.unlink()
        staged.write_text('server { server_name example.com; listen 80; } server { server_name example.com; listen 443 ssl; }')
        request = {'operation': 'create-stage', 'configName': self.config.name, 'scope': 'server',
                   'path': '', 'username': 'alice', 'password': 'synthetic-secret'}
        cli.apply_creation(self.rootfd, request, expected_version=txn.digest(staged.read_bytes()), staged_name=staged_name,
                           expected_domain='example.com', worker_group=os.getegid, verify_read=lambda path: None,
                           global_policy=lambda: b'events {} http {}')
        self.assertFalse(staged.exists())
        source = self.config.read_text()
        tree = cli.parse(source)
        first = cli.effective_auth(tree, cli.select_context(tree, 0, 'server'))
        second = cli.effective_auth(tree, cli.select_context(tree, 1, 'server'))
        self.assertEqual(first, second)
        self.assertNotIn('synthetic-secret', source)

    def test_creation_does_not_replace_concurrent_site(self):
        staged_name = '.site-create-' + 'c' * 32 + '.pending'
        staged = self.root / 'conf.d' / staged_name
        staged.write_text('server { server_name example.com; listen 80; }')
        original = self.config.read_bytes()
        request = {'operation': 'create-stage', 'configName': self.config.name, 'scope': 'server',
                   'path': '', 'username': 'alice', 'password': 'synthetic-secret'}
        with self.assertRaises(FileExistsError):
            cli.apply_creation(self.rootfd, request, expected_version=txn.digest(staged.read_bytes()), staged_name=staged_name,
                               expected_domain='example.com', worker_group=os.getegid, verify_read=lambda path: None,
                               global_policy=lambda: b'events {} http {}')
        self.assertEqual(self.config.read_bytes(), original)
        self.assertTrue(staged.exists())

    def test_creation_failure_never_publishes_unprotected_config(self):
        staged_name = '.site-create-' + 'd' * 32 + '.pending'
        staged = self.root / 'conf.d' / staged_name
        self.config.unlink()
        staged.write_text('server { server_name example.com; listen 80; }')
        request = {'operation': 'create-stage', 'configName': self.config.name, 'scope': 'location',
                   'path': '/missing/', 'username': 'alice', 'password': 'synthetic-secret'}
        with self.assertRaises(cli.ConfigError):
            cli.apply_creation(self.rootfd, request, expected_version=txn.digest(staged.read_bytes()), staged_name=staged_name,
                               expected_domain='example.com', worker_group=os.getegid, verify_read=lambda path: None,
                               global_policy=lambda: b'events {} http {}')
        self.assertFalse(self.config.exists())
        self.assertTrue(staged.exists())

    def test_creation_preserves_config_changed_immediately_after_publication(self):
        staged_name = '.site-create-' + 'e' * 32 + '.pending'
        staged = self.root / 'conf.d' / staged_name
        self.config.unlink()
        staged.write_text('server { server_name example.com; listen 80; }')
        request = {'operation': 'create-stage', 'configName': self.config.name, 'scope': 'server',
                   'path': '', 'username': 'alice', 'password': 'synthetic-secret'}
        rename = cli.rename_noreplace

        def publish_then_edit(directory, source, destination):
            rename(directory, source, destination)
            self.config.write_text('server { # changed by another administrator\n }')

        with mock.patch.object(cli, 'rename_noreplace', side_effect=publish_then_edit):
            with self.assertRaises(txn.Conflict):
                cli.apply_creation(self.rootfd, request, expected_version=txn.digest(staged.read_bytes()),
                                   staged_name=staged_name, expected_domain='example.com',
                                   worker_group=os.getegid, verify_read=lambda path: None,
                                   global_policy=lambda: b'events {} http {}')
        self.assertIn('changed by another administrator', self.config.read_text())
        self.assertFalse(staged.exists())

    def test_creation_rechecks_global_policy_at_final_reload(self):
        staged_name = '.site-create-' + 'f' * 32 + '.pending'
        staged = self.root / 'conf.d' / staged_name
        self.config.unlink()
        staged.write_text('server { server_name example.com; listen 80; }')
        request = {'operation': 'create-stage', 'configName': self.config.name, 'scope': 'server',
                   'path': '', 'username': 'alice', 'password': 'synthetic-secret'}
        good = lambda: b'events {} http {}'
        cli.apply_creation(self.rootfd, request, expected_version=txn.digest(staged.read_bytes()),
                           staged_name=staged_name, expected_domain='example.com',
                           worker_group=os.getegid, verify_read=lambda path: None, global_policy=good)
        version = txn.digest(self.config.read_bytes())
        calls = []
        bad = lambda: b'events {} http { error_page 401 = /public; }'
        with self.assertRaises(cli.ConfigError):
            cli.apply_creation(self.rootfd, request, expected_version=version, expected_domain='example.com',
                               verify_only=True, verify_read=lambda path: None, global_policy=bad,
                               validate=lambda: calls.append('test'), reload_config=lambda: calls.append('reload'))
        self.assertEqual(calls, [])
        cli.apply_creation(self.rootfd, request, expected_version=version, expected_domain='example.com',
                           verify_only=True, verify_read=lambda path: None, global_policy=good,
                           validate=lambda: calls.append('test'), reload_config=lambda: calls.append('reload'))
        self.assertEqual(calls, ['test', 'reload'])

    def test_creation_detects_global_policy_change_during_final_reload(self):
        staged_name = '.site-create-' + '9' * 32 + '.pending'
        staged = self.root / 'conf.d' / staged_name
        self.config.unlink()
        staged.write_text('server { server_name example.com; listen 80; }')
        request = {'operation': 'create-stage', 'configName': self.config.name, 'scope': 'server',
                   'path': '', 'username': 'alice', 'password': 'synthetic-secret'}
        policy = [b'events {} http {}']
        cli.apply_creation(self.rootfd, request, expected_version=txn.digest(staged.read_bytes()),
                           staged_name=staged_name, expected_domain='example.com', worker_group=os.getegid,
                           verify_read=lambda path: None, global_policy=lambda: policy[0])
        def change_policy():
            policy[0] = b'events {} http { error_page 401 = /public; }'
        with self.assertRaises(cli.ConfigError):
            cli.apply_creation(self.rootfd, request, expected_version=txn.digest(self.config.read_bytes()),
                               expected_domain='example.com', verify_only=True, verify_read=lambda path: None,
                               global_policy=lambda: policy[0], validate=lambda: None, reload_config=change_policy)


if __name__ == '__main__':
    unittest.main()
