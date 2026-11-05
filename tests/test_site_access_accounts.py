import os
from pathlib import Path
import subprocess
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import site_access_accounts as accounts
import site_access_transaction as txn


@unittest.skipUnless(sys.platform == 'linux', 'requires Linux atomic exchange and openssl')
class SiteAccessAccountTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='site-access-accounts-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.file = self.root / '.users'
        self.file.write_bytes(b'# admins\nalice:oldhash\n')
        os.chmod(self.file, 0o640)

    def call(self, action, name, **kwargs):
        before = self.file.read_bytes()
        return accounts.edit_account(str(self.root), '.users', txn.digest(before), action, name, **kwargs)

    def test_add_modify_and_remove_account(self):
        self.call('add', 'bob', password='testpass')
        result = self.file.read_text()
        self.assertIn('alice:oldhash', result)
        self.assertNotIn('testpass', result)
        digest = [line.split(':', 1)[1] for line in result.splitlines() if line.startswith('bob:')][0]
        verified = subprocess.run(['/usr/bin/openssl', 'passwd', '-apr1', '-salt', digest.split('$')[2], '-stdin'],
                                  input=b'testpass\n', capture_output=True, check=True)
        self.assertEqual(verified.stdout.decode().strip(), digest)
        self.call('update', 'carol', previous_username='bob', password='newpass')
        self.assertNotIn('bob:', self.file.read_text())
        self.call('delete', 'carol')
        self.assertEqual(self.file.read_bytes(), b'# admins\nalice:oldhash\n')

    def test_conflicts_do_not_change_file(self):
        old = self.file.read_bytes()
        with self.assertRaises(accounts.ConfigError):
            self.call('add', 'alice', password='anything')
        self.assertEqual(self.file.read_bytes(), old)
        with self.assertRaises(txn.Conflict):
            accounts.edit_account(str(self.root), '.users', txn.digest(b'outdated'), 'delete', 'alice')
        self.assertEqual(self.file.read_bytes(), old)

    def test_password_cannot_include_line_break_or_nul(self):
        for value in ('', 'a\nb', 'a\rb', 'a\0b'):
            with self.subTest(value=value), self.assertRaises(accounts.ConfigError):
                accounts.hash_password(value)


if __name__ == '__main__':
    unittest.main()
