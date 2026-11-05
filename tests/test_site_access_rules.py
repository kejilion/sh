import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import site_access_nginx as nginx
import site_access_rules as rules
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
