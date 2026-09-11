#!/usr/bin/env python3
"""Exercise production lock helpers in temporary paths, with no host mutations."""
import concurrent.futures
import os
from pathlib import Path
import re
import subprocess
import tempfile
import unittest

SOURCE = (Path(__file__).resolve().parent.parent / "kejilion.sh").read_text()


class ParallelAppTests(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix="kpanel-parallel-")
        self.addCleanup(self.temp.cleanup)
        self.root = Path(self.temp.name)
        names = ["kpanel_app_lock_held", "kpanel_app_with_lock",
                 "kpanel_app_update_marker", "add_app_id", "remove_app_id", "kpanel_app_source_config"]
        bodies = []
        for name in names:
            match = re.search(r"^" + name + r"\(\) [\{\(]\n.*?^[\}\)]$", SOURCE, re.M | re.S)
            self.assertIsNotNone(match, name)
            bodies.append(match.group())
        fixture = "\n".join(bodies).replace("/run/lock/kejilion-app", str(self.root / "locks"))
        fixture = fixture.replace("/home/docker", str(self.root / "data"))
        # Only the temporary fixture's ownership expectation follows the test uid.
        fixture = fixture.replace('"$(id -u)" = "0"', f'"$(id -u)" = "{os.getuid()}"')
        fixture = fixture.replace('= "0:700"', f'= "{os.getuid()}:700"')
        self.helper = self.root / "helpers.sh"
        self.helper.write_text(fixture)

    def run_shell(self, body, check=True, timeout=10):
        result = subprocess.run(["bash", "-c", 'source "$1"; KJ_APP_CONCURRENCY=1; ' + body,
                                 "test", str(self.helper)], capture_output=True, text=True, timeout=timeout)
        if check:
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        return result

    def test_atomic_marker_add_remove(self):
        def add(i):
            self.run_shell(f"app_id=app-{i}; add_app_id; add_app_id")
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(add, range(40)))
        marker = self.root / "data/appno.txt"
        self.assertEqual(set(marker.read_text().splitlines()), {f"app-{i}" for i in range(40)})
        self.assertEqual(len(marker.read_text().splitlines()), 40)
        with concurrent.futures.ThreadPoolExecutor(max_workers=8) as pool:
            list(pool.map(lambda i: self.run_shell(f"app_id=app-{i}; remove_app_id"), range(0, 40, 2)))
        self.assertEqual(set(marker.read_text().splitlines()), {f"app-{i}" for i in range(1, 40, 2)})

    def test_excludes_concurrent_system_writes(self):
        body = 'write() { mkdir "$(dirname "$1")/busy" || return 44; sleep .02; rmdir "$(dirname "$1")/busy"; }; kpanel_app_with_lock system write "$1"'
        with concurrent.futures.ThreadPoolExecutor(max_workers=4) as pool:
            list(pool.map(lambda _: self.run_shell(body), range(16)))

    def test_nested_lock_keeps_shell_state_and_does_not_export_guard(self):
        self.run_shell('inner() { value=changed; bash -c \'test -z "${KJ_APP_LOCKS_HELD:-}"\'; }; outer() { kpanel_app_with_lock system inner; }; '
                       'export KJ_APP_LOCKS_HELD=""; value=old; kpanel_app_with_lock system outer; '
                       'test "$value" = changed && test -z "$KJ_APP_LOCKS_HELD"')

    def test_inherited_background_fd_does_not_hold_lock(self):
        self.run_shell('work() { sleep 3 >/dev/null 2>&1 & }; kpanel_app_with_lock system work; '
                       'flock -w .2 "$(dirname "$1")/locks/system.lock" true', timeout=2)

    def test_lock_failure_stops_caller(self):
        result = self.run_shell('flock() { return 75; }; kpanel_app_with_lock system true; echo UNSAFE_CONTINUATION', check=False)
        self.assertNotEqual(result.returncode, 0)
        self.assertNotIn("UNSAFE_CONTINUATION", result.stdout)

    def test_callback_failure_releases_lock(self):
        result = self.run_shell('kpanel_app_with_lock system false', check=False)
        self.assertEqual(result.returncode, 1)
        self.run_shell('kpanel_app_with_lock system true')

    def test_config_snapshot_keeps_input_exit_code_and_releases_catalog_lock(self):
        config = self.root / "app.conf"
        config.write_text('IFS= read -r answer\n'
                          'flock -n "$(dirname "$1")/locks/catalog.lock" true || return 45\n'
                          'printf "original:%s\\n" "$answer"\nreturn 37\n')
        # Replace the original immediately after the locked copy, before source.
        result = self.run_shell(
            'cp() { command cp "$@"; printf \'echo REPLACED\\n\' > "$2"; }; '
            'TMPDIR="$(dirname "$1")"; '
            'kpanel_app_source_config "$(dirname "$1")/app.conf" <<< answer', check=False)
        self.assertEqual(result.returncode, 37, result.stdout + result.stderr)
        self.assertIn("original:answer", result.stdout)
        self.assertNotIn("REPLACED", result.stdout)
        self.assertEqual(list(self.root.glob("kpanel-app.*")), [])

    def test_unsafe_lock_and_marker_paths_are_rejected(self):
        (self.root / "locks").symlink_to(self.root, target_is_directory=True)
        self.assertNotEqual(self.run_shell('kpanel_app_with_lock system true', check=False).returncode, 0)
        (self.root / "locks").unlink()
        (self.root / "data").mkdir()
        (self.root / "data/appno.txt").symlink_to(self.helper)
        self.assertNotEqual(self.run_shell('app_id=safe; add_app_id', check=False).returncode, 0)


if __name__ == "__main__":
    unittest.main(verbosity=2)
