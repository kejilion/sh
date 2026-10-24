"""Run the public backup template against temporary data and a fake transfer."""
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest


@unittest.skipUnless(os.name == 'posix', 'requires Bash and GNU tar/find')
class WebBackupTemplateTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        for relative in ['web/html/site/index.html', 'web/mysql/database',
                         'web/certs/site.pem', 'web/log/nginx/error.log',
                         'web/backups/old-site/index.html']:
            path = self.root / relative
            path.parent.mkdir(parents=True, exist_ok=True)
            path.write_text(relative)
        self.old = []
        for day in range(20, 25):
            path = self.root / f'web_202610{day}070001.tar.gz'
            path.write_bytes(b'old restore point')
            self.old.append(path)
        self.unrelated = self.root / 'unrelated.tar.gz'
        self.unrelated.write_bytes(b'keep unrelated backup')
        (self.root / 'web_custom.tar.gz').write_bytes(b'keep custom backup')
        (self.root / 'web_20260101000000.tar.gz').symlink_to(self.unrelated)
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        self.stub('date', 'printf 20261025070001\n')
        self.stub('sshpass', 'printf "%s\\n" "$@" > "$TRANSFER_ARGS"; exit "${TRANSFER_EXIT:-0}"\n')
        source = (Path(__file__).resolve().parents[1] / 'beifen.sh').read_text()
        self.script = self.root / 'backup.sh'
        self.script.write_text(source.replace('backup_root=/home', f'backup_root={self.root}'))
        self.archive = self.root / 'web_20261025070001.tar.gz'

    def stub(self, name, body):
        path = self.bin / name
        path.write_text('#!/bin/sh\n' + body)
        path.chmod(0o700)

    def run_backup(self, **extra):
        env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                   TRANSFER_ARGS=str(self.root / 'transfer-args'), **extra)
        return subprocess.run(['bash', str(self.script)], env=env,
                              capture_output=True, text=True, timeout=20)

    def test_success_keeps_business_data_and_only_prunes_completed_web_backups(self):
        result = self.run_backup()
        self.assertEqual(result.returncode, 0, result.stderr)
        with tarfile.open(self.archive) as archive:
            names = archive.getnames()
            for name in ['web/html/site/index.html', 'web/mysql/database', 'web/certs/site.pem']:
                self.assertIn(name, names)
            self.assertFalse(any(name.startswith(('web/log', 'web/backups')) for name in names))
        self.assertEqual([path.exists() for path in self.old], [False, False, False, True, True])
        self.assertTrue(self.unrelated.exists())
        self.assertTrue((self.root / 'web_custom.tar.gz').exists())
        self.assertTrue((self.root / 'web_20260101000000.tar.gz').is_symlink())
        self.assertEqual(self.archive.stat().st_mode & 0o777, 0o600)
        self.assertIn(self.archive.name, (self.root / 'transfer-args').read_text())
        self.assertFalse(list(self.root.glob('.web-backup.*')))

    def test_transfer_failure_preserves_all_restore_points(self):
        result = self.run_backup(TRANSFER_EXIT='7')
        self.assertEqual(result.returncode, 7)
        self.assertTrue(all(path.exists() for path in self.old))
        self.assertTrue(self.archive.exists())
        self.assertFalse(list(self.root.glob('.web-backup.*')))

    def test_archive_failure_never_publishes_or_prunes(self):
        self.stub('tar', 'exit 2\n')
        result = self.run_backup()
        self.assertEqual(result.returncode, 2)
        self.assertFalse(self.archive.exists())
        self.assertFalse((self.root / 'transfer-args').exists())
        self.assertTrue(all(path.exists() for path in self.old))
        self.assertFalse(list(self.root.glob('.web-backup.*')))


if __name__ == '__main__':
    unittest.main()
