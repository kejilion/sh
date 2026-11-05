import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import site_access_config as config
import site_access_transaction as txn


@unittest.skipUnless(sys.platform == 'linux', 'requires Linux atomic exchange')
class SiteAccessConfigTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='site-access-config-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.file = self.root / 'site.conf'
        self.original = b'server { server_name a.example; location /admin/ { proxy_pass http://app; } }\n'
        self.file.write_bytes(self.original)
        self.calls = []

    def edit(self, action, **values):
        return config.edit_config(str(self.root), 'site.conf', txn.digest(self.file.read_bytes()),
                                  0, 'location', '/admin/', '', action,
                                  validate=lambda: self.calls.append('test'),
                                  reload_config=lambda: self.calls.append('reload'), **values)

    def test_set_and_delete_preserve_proxy_configuration(self):
        self.edit('set', realm='Private', user_file='/etc/nginx/conf.d/users')
        value = self.file.read_text()
        self.assertIn('auth_basic "Private";', value)
        self.assertIn('proxy_pass http://app;', value)
        self.edit('delete')
        self.assertNotIn('auth_basic', self.file.read_text())
        self.assertIn('proxy_pass http://app;', self.file.read_text())
        self.assertEqual(self.calls, ['test', 'reload', 'test', 'reload'])

    def test_rejects_nonexistent_or_mismatched_context(self):
        with self.assertRaises(config.ConfigError):
            self.edit('delete')
        self.assertEqual(self.file.read_bytes(), self.original)
        self.assertEqual(self.calls, [])

    def test_reload_failure_restores_exact_original(self):
        def broken():
            self.calls.append('reload')
            if len(self.calls) == 1:
                raise RuntimeError('reload failed')
        with self.assertRaises(RuntimeError):
            config.edit_config(str(self.root), 'site.conf', txn.digest(self.original),
                               0, 'location', '/admin/', '', 'set', realm='Private',
                               user_file='/etc/nginx/conf.d/users', validate=lambda: None,
                               reload_config=broken)
        self.assertEqual(self.file.read_bytes(), self.original)
        self.assertEqual(self.calls, ['reload', 'reload'])


if __name__ == '__main__':
    unittest.main()
