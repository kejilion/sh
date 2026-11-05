import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import site_access_nginx as nginx
import site_access_rules as rules
import site_access_config as config
import site_access_transaction as txn


@unittest.skipUnless(sys.platform == 'linux', 'requires Linux atomic exchange')
class SiteAccessRuleTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='site-access-rules-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.conf = self.root / 'example.com.conf'
        self.original = b'server { server_name example.com; location /admin/ { proxy_pass http://app; } }\n'
        self.conf.write_bytes(self.original)
        self.dirfd = os.open(self.root, os.O_RDONLY | os.O_DIRECTORY)
        self.addCleanup(os.close, self.dirfd)
        self.events = []

    def create(self, validate=None):
        return rules.add_rule(self.dirfd, self.conf.name, txn.digest(self.original), 0, 'location', '/admin/', '',
                              'alice', 'synthetic-secret', validate=validate or (lambda: self.events.append('test')),
                              reload_config=lambda: self.events.append('reload'), worker_group=os.getegid,
                              verify_read=lambda path: self.events.append('read'),
                              hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')

    def test_creates_readable_password_file_and_preserves_proxy(self):
        self.create()
        config = self.conf.read_text()
        root = nginx.parse(config)
        auth = nginx.effective_auth(root, nginx.select_context(root, 0, 'location', '/admin/'))
        self.assertEqual(auth[0], 'Restricted')
        password_file = self.root / auth[1].split('/')[-1]
        self.assertTrue(password_file.exists())
        self.assertEqual(password_file.stat().st_mode & 0o777, 0o640)
        self.assertIn('alice:$apr1$', password_file.read_text())
        self.assertNotIn('synthetic-secret', password_file.read_text())
        self.assertIn('proxy_pass http://app;', config)
        self.assertEqual(self.events, ['read', 'test', 'reload'])

    def test_failed_validation_restores_config_and_removes_unused_file(self):
        def fail():
            raise RuntimeError('nginx test failed')
        with self.assertRaises(RuntimeError):
            self.create(validate=fail)
        self.assertEqual(self.conf.read_bytes(), self.original)
        self.assertFalse(list(self.root.glob('.site-auth-*.passwd')))

    def test_rejects_existing_rule_or_changed_config(self):
        self.conf.write_bytes(self.original + b'# changed\n')
        with self.assertRaises(txn.Conflict):
            self.create()
        self.assertFalse(list(self.root.glob('.site-auth-*.passwd')))

    def test_adds_rule_to_multiple_server_blocks_atomically(self):
        source = b'server { listen 80; } server { listen 443 ssl; }\n'
        self.conf.write_bytes(source)
        rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0, 1], 'server', '', '',
                       'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                       worker_group=os.getegid, verify_read=lambda path: None,
                       hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')
        root = nginx.parse(self.conf.read_text())
        auth0 = nginx.effective_auth(root, nginx.select_context(root, 0, 'server'))
        auth1 = nginx.effective_auth(root, nginx.select_context(root, 1, 'server'))
        self.assertEqual(auth0, auth1)
        self.assertEqual(len(list(self.root.glob('.site-auth-*.passwd'))), 1)

    def test_rejects_rules_bypassed_by_return_or_satisfy_any(self):
        sources = (
            b'server { return 301 https://example.org; }',
            b'server { location / { return 301 https://example.org; } }',
            b'server { satisfy any; location /admin/ { proxy_pass http://app; } }',
        )
        for source in sources:
            with self.subTest(source=source):
                self.conf.write_bytes(source)
                with self.assertRaises(rules.ConfigError):
                    rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'server', '', '',
                                   'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                                   worker_group=os.getegid, verify_read=lambda path: None)
                self.assertEqual(self.conf.read_bytes(), source)
                self.assertFalse(list(self.root.glob('.site-auth-*.passwd')))

    def test_rejects_inherited_satisfy_any_for_nested_location(self):
        sources = (
            b'http { satisfy any; server { location /admin/ { proxy_pass http://app; } } }',
            b'server { location /private/ { satisfy any; allow all; '
            b'location /private/admin/ { proxy_pass http://app; } } }',
        )
        for source in sources:
            path = '/private/admin/' if b'/private/' in source else '/admin/'
            with self.subTest(source=source):
                self.conf.write_bytes(source)
                with self.assertRaises(rules.ConfigError):
                    rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'location', path, '',
                                   'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                                   worker_group=os.getegid, verify_read=lambda path: None)
                self.assertEqual(self.conf.read_bytes(), source)

    def test_keeps_http_https_redirect_and_protects_content_server(self):
        source = (b'server { listen 80; return 301 https://example.com$request_uri; } '
                  b'server { listen 443 ssl; location / { proxy_pass http://app; } }')
        self.conf.write_bytes(source)
        rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0, 1], 'server', '', '',
                       'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                       worker_group=os.getegid, verify_read=lambda path: None,
                       hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')
        tree = nginx.parse(self.conf.read_text())
        self.assertIsNone(nginx.effective_auth(tree, nginx.select_context(tree, 0, 'server')))
        self.assertIsNotNone(nginx.effective_auth(tree, nginx.select_context(tree, 1, 'server')))

    def test_inspects_actual_includes_and_rejects_bypass(self):
        include = self.root / 'policy.inc'
        include.write_text('satisfy any; allow all;')
        source = (b'server { include /etc/nginx/conf.d/policy.inc; '
                  b'location /admin/ { proxy_pass http://app; } }')
        self.conf.write_bytes(source)
        with self.assertRaises(rules.ConfigError):
            rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'location', '/admin/', '',
                           'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                           worker_group=os.getegid, verify_read=lambda path: None)
        self.assertEqual(self.conf.read_bytes(), source)
        self.assertFalse(list(self.root.glob('.site-auth-*.passwd')))

    def test_allows_safe_include_but_detects_changes_before_reload(self):
        include = self.root / 'policy.inc'
        include.write_text('if ($blocked) { return 403; }')
        source = (b'server { include /etc/nginx/conf.d/policy.inc; '
                  b'location /admin/ { proxy_pass http://app; } }')
        self.conf.write_bytes(source)
        def change_include():
            include.write_text('satisfy any; allow all;')
        with self.assertRaises((rules.ConfigError, txn.Conflict)):
            rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'location', '/admin/', '',
                           'alice', 'synthetic-secret', validate=change_include, reload_config=lambda: None,
                           worker_group=os.getegid, verify_read=lambda path: None,
                           hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')
        self.assertEqual(self.conf.read_bytes(), source)

    def test_safe_and_missing_optional_waf_includes_remain_usable(self):
        (self.root / 'waf').mkdir()
        (self.root / 'waf' / 'server-default.inc').write_text('if ($blocked) { return 403; }')
        source = (b'server { include /etc/nginx/conf.d/waf/server-default*.inc; '
                  b'include /etc/nginx/conf.d/waf/optional*.inc; location / { proxy_pass http://app; } }')
        self.conf.write_bytes(source)
        rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'server', '', '',
                       'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                       worker_group=os.getegid, verify_read=lambda path: None,
                       hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')
        self.assertIn('auth_basic', self.conf.read_text())

    def test_rejects_unresolved_include_in_redirect_server(self):
        source = (b'server { include /etc/nginx/conf.d/extra.inc; return 301 https://example.com; } '
                  b'server { location / { proxy_pass http://app; } }')
        self.conf.write_bytes(source)
        with self.assertRaises(rules.ConfigError):
            rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0, 1], 'server', '', '',
                           'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                           worker_group=os.getegid, verify_read=lambda path: None)
        self.assertEqual(self.conf.read_bytes(), source)

    def test_rejects_nested_auth_off_and_responses_before_auth(self):
        sources = (
            b'server { location /public/ { auth_basic off; proxy_pass http://app; } }',
            b'server { if ($arg_open) { return 200 exposed; } location / { proxy_pass http://app; } }',
            b'server { location /open/ { return 200 exposed; } location / { proxy_pass http://app; } }',
        )
        for source in sources:
            with self.subTest(source=source):
                self.conf.write_bytes(source)
                with self.assertRaises(rules.ConfigError):
                    rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'server', '', '',
                                   'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                                   worker_group=os.getegid, verify_read=lambda path: None)
                self.assertEqual(self.conf.read_bytes(), source)

    def test_rejects_location_rewrites_that_can_escape_scope(self):
        for directive in ('rewrite ^ /public last;', 'if ($arg_open) { rewrite ^ /public last; }'):
            source = ('server { location /private/ { ' + directive +
                      ' proxy_pass http://app; } location /public { proxy_pass http://app; } }').encode()
            self.conf.write_bytes(source)
            with self.subTest(directive=directive), self.assertRaises(rules.ConfigError):
                rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'location', '/private/', '',
                               'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                               worker_group=os.getegid, verify_read=lambda path: None)
            self.assertEqual(self.conf.read_bytes(), source)

    def test_reload_rollback_uses_current_includes(self):
        include = self.root / 'policy.inc'
        include.write_text('# safe\n')
        source = (b'server { include /etc/nginx/conf.d/policy.inc; '
                  b'location /admin/ { proxy_pass http://app; } }')
        self.conf.write_bytes(source)
        calls = []
        def reload():
            calls.append('reload')
            if len(calls) == 1:
                include.write_text('satisfy any; allow all;')
        with self.assertRaises(rules.ConfigError):
            rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'location', '/admin/', '',
                           'alice', 'synthetic-secret', validate=lambda: None, reload_config=reload,
                           worker_group=os.getegid, verify_read=lambda path: None,
                           hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')
        self.assertEqual(calls, ['reload', 'reload'])
        self.assertEqual(self.conf.read_bytes(), source)

    def test_failed_rollback_retains_password_for_saved_candidate(self):
        include = self.root / 'policy.inc'
        include.write_text('# safe\n')
        source = (b'server { include /etc/nginx/conf.d/policy.inc; '
                  b'location /admin/ { proxy_pass http://app; } }')
        self.conf.write_bytes(source)
        calls = []
        def reload():
            calls.append('reload')
            if len(calls) == 1:
                include.write_text('satisfy any; allow all;')
            else:
                raise RuntimeError('rollback reload failed')
        with self.assertRaises(txn.TransactionError):
            rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'location', '/admin/', '',
                           'alice', 'synthetic-secret', validate=lambda: None, reload_config=reload,
                           worker_group=os.getegid, verify_read=lambda path: None,
                           hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')
        self.assertEqual(calls, ['reload', 'reload'])
        self.assertEqual(self.conf.read_bytes(), source)
        self.assertEqual(len(list(self.root.glob('.site-auth-*.passwd'))), 1)
        self.assertTrue(list(self.root.glob('.site-access-*')))

    def test_existing_satisfy_all_is_preserved(self):
        source = b'server { satisfy all; location / { proxy_pass http://app; } }'
        self.conf.write_bytes(source)
        rules.add_rule(self.dirfd, self.conf.name, txn.digest(source), [0], 'server', '', '',
                       'alice', 'synthetic-secret', validate=lambda: None, reload_config=lambda: None,
                       worker_group=os.getegid, verify_read=lambda path: None,
                       hasher=lambda _: '$apr1$abcdefgh$abcdefghijklmnopqrstuv')
        self.assertEqual(self.conf.read_text().count('satisfy all;'), 1)
        self.assertNotIn('kpanel-access-password-satisfy', self.conf.read_text())
        config.edit_config(self.dirfd, self.conf.name, txn.digest(self.conf.read_bytes()), 0,
                           'server', '', '', 'delete', validate=lambda: None, reload_config=lambda: None)
        self.assertEqual(self.conf.read_text().count('satisfy all;'), 1)

    def test_quarantine_preserves_failed_config_and_reloads(self):
        saved = rules.quarantine_created_config(self.dirfd, self.conf.name, txn.digest(self.original),
                                                validate=lambda: self.events.append('test'),
                                                reload_config=lambda: self.events.append('reload'))
        self.assertFalse(self.conf.exists())
        self.assertEqual((self.root / saved).read_bytes(), self.original)
        self.assertEqual(self.events, ['test', 'reload'])

    def test_quarantine_refuses_changed_config(self):
        self.conf.write_bytes(b'changed by another process')
        with self.assertRaises(txn.Conflict):
            rules.quarantine_created_config(self.dirfd, self.conf.name, txn.digest(self.original),
                                            validate=lambda: None, reload_config=lambda: None)
        self.assertEqual(self.conf.read_bytes(), b'changed by another process')


if __name__ == '__main__':
    unittest.main()
