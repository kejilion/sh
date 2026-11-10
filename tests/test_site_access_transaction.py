import os
from pathlib import Path
import sys
import tempfile
import unittest

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import site_access_transaction as txn


@unittest.skipUnless(sys.platform == 'linux', 'requires Linux atomic exchange')
class SiteAccessTransactionTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='site-access-test-')
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        self.target = self.root / 'site.conf'
        self.target.write_bytes(b'old')
        os.chmod(self.target, 0o640)
        self.calls = []

    def run_change(self, validate=lambda: None, reload=lambda: None, **kwargs):
        return txn.replace_existing(str(self.root), 'site.conf', txn.digest(b'old'),
                                    lambda old: old + b'-new', validate, reload, **kwargs)

    def test_commit_preserves_mode(self):
        version = self.run_change(lambda: self.calls.append('validate'), lambda: self.calls.append('reload'))
        self.assertEqual(version, txn.digest(b'old-new'))
        self.assertEqual(self.target.read_bytes(), b'old-new')
        self.assertEqual(self.target.stat().st_mode & 0o777, 0o640)
        self.assertEqual(self.calls, ['validate', 'reload'])
        self.assertFalse(list(self.root.glob('.site-access-*')))

    def test_validation_failure_restores_original_without_reload(self):
        def fail():
            raise RuntimeError('invalid configuration')
        with self.assertRaises(RuntimeError):
            self.run_change(fail, lambda: self.calls.append('reload'))
        self.assertEqual(self.target.read_bytes(), b'old')
        self.assertEqual(self.calls, [])
        self.assertFalse(list(self.root.glob('.site-access-*')))

    def test_reload_failure_restores_and_reloads_old_configuration(self):
        def reload():
            self.calls.append('reload')
            if len(self.calls) == 1:
                raise RuntimeError('reload failed')
        with self.assertRaises(RuntimeError):
            self.run_change(reload=reload)
        self.assertEqual(self.target.read_bytes(), b'old')
        self.assertEqual(self.calls, ['reload', 'reload'])

    def test_external_replacement_wins_race(self):
        def other_writer():
            replacement = self.root / 'external'
            replacement.write_bytes(b'external')
            os.replace(replacement, self.target)
        with self.assertRaises(txn.Conflict):
            self.run_change(before_exchange=other_writer)
        self.assertEqual(self.target.read_bytes(), b'external')
        self.assertFalse(list(self.root.glob('.site-access-*')))

    def test_symlink_target_is_not_followed(self):
        self.target.unlink()
        other = self.root / 'other'
        other.write_bytes(b'old')
        self.target.symlink_to(other)
        with self.assertRaises(OSError):
            self.run_change()
        self.assertEqual(other.read_bytes(), b'old')

    def test_external_in_place_edit_is_not_overwritten(self):
        def edit_candidate():
            self.target.write_bytes(b'external edit')
        with self.assertRaises(txn.Conflict):
            self.run_change(validate=edit_candidate)
        self.assertEqual(self.target.read_bytes(), b'external edit')
        backups = list(self.root.glob('.site-access-*'))
        self.assertEqual(len(backups), 1)
        self.assertEqual(backups[0].read_bytes(), b'old')

    def test_caller_can_pin_a_checked_directory_handle(self):
        directory = os.open(self.root, os.O_RDONLY | os.O_DIRECTORY)
        try:
            txn.replace_existing(directory, 'site.conf', txn.digest(b'old'),
                                 lambda old: old + b'-new', lambda: None, lambda: None)
        finally:
            os.close(directory)
        self.assertEqual(self.target.read_bytes(), b'old-new')


if __name__ == '__main__':
    unittest.main()
