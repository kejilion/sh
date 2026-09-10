#!/usr/bin/env python3
"""Run the authoritative updater in an isolated filesystem with real processes.

Requires Linux/root for the installer UID/GID boundary. No host service or network
is touched: curl/systemctl are fixtures and all fixed paths point into TemporaryDirectory.
"""
import hashlib
import json
import os
from pathlib import Path
import shutil
import signal
import subprocess
import sys
import tempfile
import time
import unittest

SOURCE = Path(os.environ.get('SCRIPT_PATH', Path(__file__).resolve().parents[1] / 'kejilion.sh')).read_text()
LOCK_TEMPLATE = SOURCE.split("<<'KPANEL_NODE_LIFECYCLE'\n", 1)[1].split('\nKPANEL_NODE_LIFECYCLE\n', 1)[0]
UPDATER = '#!/bin/bash\n' + LOCK_TEMPLATE + '\n' + SOURCE.split("<<'KPANEL_NODE_UPDATE'\n", 1)[1].split('\nKPANEL_NODE_UPDATE\n', 1)[0]
FILE_UNIT = UPDATER.split("<<'KPANEL_NODE_FILE_SERVICE'\n", 1)[1].split('\nKPANEL_NODE_FILE_SERVICE\n', 1)[0] + '\n'
# Verbatim installer-owned unit from kejilion/sh@2ee9856c9916b7ede8bbc19edc97e22872e86203.
LEGACY_FILE_UNIT = (Path(__file__).resolve().parent / 'fixtures/kpanel-node-file-2ee9856.service').read_text()

CURL = r'''#!/usr/bin/python3
import json,os,pathlib,shutil,sys
root=pathlib.Path(os.environ['NODE_TEST_ROOT']); args=sys.argv[1:]
with (root/'downloads').open('a') as f: f.write(args[-1]+'\n')
assert '--retry' in args and '--retry-max-time' in args and '--max-filesize' in args
assert args[args.index('--proto-redir')+1]=='=https'
if (root/'network-down').exists(): sys.exit(7)
if (root/'pause-download').exists():
 import time
 (root/'download-waiting').touch()
 while (root/'pause-download').exists(): time.sleep(0.05)
out=pathlib.Path(args[args.index('-o')+1])
if args[-1].endswith('/SHA256SUMS'):
 assert args[-1]=='https://github.com/kejilion/KPanel/releases/latest/download/SHA256SUMS'
 shutil.copyfile(root/'SHA256SUMS',out)
 headers=(root/'response-headers').read_text() if (root/'response-headers').exists() else 'HTTP/2 302\r\nLocation: https://github.com/kejilion/KPanel/releases/download/v9.9.9/SHA256SUMS\r\n\r\nHTTP/2 302\r\nlocation: https://release-assets.githubusercontent.com/test\r\n\r\n'
 pathlib.Path(args[args.index('--dump-header')+1]).write_text(headers)
else:
 if (root/'binary-network-down').exists(): sys.exit(7)
 assert args[-1]=='https://github.com/kejilion/KPanel/releases/download/v9.9.9/kejilion-node-linux-amd64'
 shutil.copyfile(root/('bad' if (root/'bad-download').exists() else 'release'),out)
'''

SYSTEMCTL = r'''#!/usr/bin/python3
import hashlib,json,os,pathlib,signal,subprocess,sys
root=pathlib.Path(os.environ['NODE_TEST_ROOT']); args=sys.argv[1:]
service=next((a for a in args if a.endswith('.service')), '')
with (root/'calls').open('a') as f: f.write(' '.join(args)+'\n')
pidfile=root/(service+'.pid')
pid=int(pidfile.read_text()) if pidfile.exists() else 0
if args[0] in ('daemon-reload','enable'): sys.exit(0)
if args[0]=='cat': sys.exit(0 if service=='kejilion-node.service' or (root/'optional').exists() else 1)
if args[0]=='show': print(pid); sys.exit(0)
if args[0]=='is-active':
 try:
  os.kill(pid,0)
  alive=pid>0 and pathlib.Path('/proc/%d/exe'%pid).exists()
 except OSError: alive=False
 sys.exit(0 if alive else 3)
if args[0]=='restart':
 if pid:
  try: os.killpg(pid,signal.SIGKILL)
  except ProcessLookupError: pass
  pidfile.unlink(missing_ok=True)
 if service!='kejilion-node.service' and (root/'optional-fail').exists(): sys.exit(1)
 binary=root/'home/kejilion-node'
 if service=='kejilion-node.service' and (root/'core-fail').exists() and binary.read_bytes()==(root/'release').read_bytes(): sys.exit(1)
 if service=='kejilion-node.service':
  # Exercise the actual unprivileged read of the rewritten/repaired credential.
  check=subprocess.run(['/bin/cat',str(root/'config/node.json')],user=65534,group=65534,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL)
  if check.returncode: sys.exit(1)
 command=[str(binary),'-c','while :; do sleep 30; done']
 if (root/'delayed-exec').exists():
  import shlex
  command=['/bin/sh','-c','sleep 0.5; exec '+shlex.join(command)]
 p=subprocess.Popen(command,stdin=subprocess.DEVNULL,stdout=subprocess.DEVNULL,stderr=subprocess.DEVNULL,start_new_session=True,close_fds=True)
 pidfile.write_text(str(p.pid)); sys.exit(0)
sys.exit(1)
'''

@unittest.skipUnless(sys.platform.startswith('linux') and os.geteuid() == 0, 'requires isolated Linux root')
class NodeUpdater(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kpanel-update-test-')
        self.root = Path(self.temp.name)
        self.root.chmod(0o755)
        for name in ('home', 'config', 'units', 'bin'):
            (self.root / name).mkdir()
        os.chown(self.root / 'config', 0, 65534)
        (self.root / 'config').chmod(0o750)
        config = self.root / 'config/node.json'
        config.write_text('{"schemaVersion":1}')
        config.chmod(0o640)
        os.chown(config, 0, 65534)
        self.binary = self.root / 'home/kejilion-node'
        shutil.copyfile('/bin/dash', self.binary)
        self.binary.chmod(0o755)
        shutil.copyfile('/bin/bash', self.root / 'release')
        (self.root / 'version').write_text('echo "9.9.9 light-v1"\n')
        (self.root / 'bad').write_text('corrupt')
        digest = hashlib.sha256((self.root / 'release').read_bytes()).hexdigest()
        (self.root / 'SHA256SUMS').write_text(digest + '  kejilion-node-linux-amd64\n')
        for name, content in [('curl', CURL), ('systemctl', SYSTEMCTL), ('id', '#!/bin/sh\ncase "$1" in -g) echo 65534;; -gn) echo kejilion-node;; *) /usr/bin/id "$@";; esac\n')]:
            (self.root / 'bin' / name).write_text(content)
            (self.root / 'bin' / name).chmod(0o755)
        script = self.isolate_paths(UPDATER)
        (self.root / 'update.sh').write_text(script)
        self.env = {**os.environ, 'NODE_TEST_ROOT': str(self.root), 'PATH': str(self.root / 'bin') + ':' + os.environ['PATH']}

    def isolate_paths(self, script):
        return script.replace('/usr/local/lib/kejilion-node', str(self.root / 'home')).replace('/etc/kejilion-node', str(self.root / 'config')).replace('/etc/systemd/system', str(self.root / 'units')).replace('/run/lock/kejilion-node-update.lock', str(self.root / 'legacy.lock')).replace('/run/kejilion-node-lifecycle.lock', str(self.root / 'lifecycle.lock'))

    def test_inherited_installer_lock_spans_child_update_and_home_removal(self):
        # The child must use the same lock, but may not release the parent's
        # legacy bridge. Removing/recreating HOME must not create a second lock.
        wrapper = self.root / 'installer.sh'
        wrapper.write_text(self.isolate_paths(LOCK_TEMPLATE) + r'''
set -euo pipefail
kpanel_node_acquire_lock
bash "$NODE_TEST_ROOT/update.sh" install
test -d "$NODE_TEST_ROOT/legacy.lock"
rm -r "$NODE_TEST_ROOT/home"
mkdir "$NODE_TEST_ROOT/home"
touch "$NODE_TEST_ROOT/installer-waiting"
while [ ! -f "$NODE_TEST_ROOT/finish-installer" ]; do sleep 0.02; done
''')
        process = subprocess.Popen(['/bin/bash', str(wrapper)], env=self.env, cwd=self.root,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True, start_new_session=True)
        try:
            for _ in range(200):
                if (self.root / 'installer-waiting').exists() or process.poll() is not None: break
                time.sleep(0.02)
            self.assertTrue((self.root / 'installer-waiting').exists())
            inode = (self.root / 'lifecycle.lock').stat().st_ino
            self.assertIn('lifecycle operation', self.run_update(False).stderr)
            self.assertEqual((self.root / 'lifecycle.lock').stat().st_ino, inode)
            self.assertTrue((self.root / 'legacy.lock').is_dir())
            (self.root / 'finish-installer').touch()
            _, errors = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0, errors)
            self.assertFalse((self.root / 'legacy.lock').exists())
            self.run_update(mode='install')
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate()

    def test_real_join_control_flow_excludes_join_update_and_uninstall_until_activation(self):
        # Execute the actual lifecycle functions, not a simulated lock caller.
        # Only account creation, service activation and release/network endpoints
        # are fixtures; every filesystem path belongs to this TemporaryDirectory.
        lifecycle = SOURCE.split('kpanel_node_paths() {', 1)[1].split('\nkpanel_node_dispatch() {', 1)[0]
        lifecycle = self.isolate_paths('kpanel_node_paths() {' + lifecycle).replace('/run/kejilion-node-ssh', str(self.root / 'ssh-runtime'))
        wrapper = self.root / 'lifecycle.sh'
        wrapper.write_text(lifecycle + r'''
kpanel_node_preflight() { KPANEL_NODE_INSTALL_BIN="$(type -P install)"; }
kpanel_node_ensure_account() { :; }
kpanel_node_validate_config_dir() { :; }
kpanel_node_write_units() { :; }
kpanel_node_activate() {
    touch "$NODE_TEST_ROOT/activation-waiting"
    while [ ! -f "$NODE_TEST_ROOT/finish-activation" ]; do sleep 0.02; done
}
chown() { command chown "${1/kejilion-node/65534}" "${@:2}"; }
"kpanel_node_$1" kpl1.test-token
''')
        # Installer uses install -g; numeric group retains the real permission test.
        install = self.root / 'bin/install'
        install.write_text('#!/bin/bash\nargs=("$@"); for i in "${!args[@]}"; do [ "${args[$i]}" != kejilion-node ] || args[$i]=65534; done\nexec /usr/bin/install "${args[@]}"\n')
        install.chmod(0o755)
        config = self.root / 'config/node.json'
        config.unlink()
        (self.root / 'enroll').write_text(r'''echo enrolled >>"$NODE_TEST_ROOT/enroll.log"
while [ "$#" -gt 0 ]; do
    if [ "$1" = --config ]; then
        shift
        printf '{"schemaVersion":1}\n' >"$1"
        break
    fi
    shift
done
''')
        process = subprocess.Popen(['/bin/bash', str(wrapper), 'join'], cwd=self.root, env=self.env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.PIPE, text=True, start_new_session=True)
        try:
            for _ in range(300):
                if (self.root / 'activation-waiting').exists() or process.poll() is not None: break
                time.sleep(0.02)
            self.assertTrue((self.root / 'activation-waiting').exists())
            identity = config.read_bytes()
            for action in ('join', 'update', 'uninstall'):
                result = subprocess.run(['/bin/bash', str(wrapper), action], cwd=self.root, env=self.env,
                                        capture_output=True, text=True, timeout=10)
                self.assertNotEqual(result.returncode, 0, result.stdout + result.stderr)
                self.assertIn('lifecycle operation', result.stderr)
                self.assertEqual(config.read_bytes(), identity)
            self.assertEqual((self.root / 'enroll.log').read_text().splitlines(), ['enrolled'])
            (self.root / 'finish-activation').touch()
            _, errors = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 0, errors)
            # An ordinary retry resumes the saved identity without re-enrollment.
            result = subprocess.run(['/bin/bash', str(wrapper), 'join'], cwd=self.root, env=self.env,
                                    capture_output=True, text=True, timeout=15)
            self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
            self.assertEqual((self.root / 'enroll.log').read_text().splitlines(), ['enrolled'])
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate()

    def tearDown(self):
        for path in self.root.glob('*.service.pid'):
            try: os.killpg(int(path.read_text()), signal.SIGKILL)
            except ProcessLookupError: pass
        self.temp.cleanup()

    def run_update(self, success=True, mode='update'):
        result = subprocess.run(['/bin/bash', str(self.root / 'update.sh'), mode], cwd=self.root, env=self.env, text=True, capture_output=True, timeout=20)
        self.assertEqual(result.returncode == 0, success, result.stdout + result.stderr)
        return result

    def test_upgrade_optional_failure_does_not_rollback_and_delayed_exec_is_accepted(self):
        (self.root / 'optional').touch()
        (self.root / 'optional-fail').touch()
        (self.root / 'delayed-exec').touch()
        result = self.run_update()
        self.assertIn('optional service unavailable', result.stderr)
        self.assertEqual(self.binary.read_bytes(), (self.root / 'release').read_bytes())
        self.assertFalse((self.root / 'home/kejilion-node.previous').exists())
        status = json.loads((self.root / 'config/update-status.json').read_text())
        self.assertEqual((status['state'], status['errorCode']), ('degraded', 'optional_service'))

    def test_failed_core_rolls_back_and_restart_failure_cannot_be_masked(self):
        before = self.binary.read_bytes()
        (self.root / 'core-fail').touch()
        result = self.run_update(False)
        self.assertIn('was rolled back', result.stderr)
        self.assertEqual(self.binary.read_bytes(), before)
        status = json.loads((self.root / 'config/update-status.json').read_text())
        self.assertEqual((status['state'], status['errorCode']), ('rolled_back', 'restart'))

    def test_update_status_is_private_bounded_and_tracks_checks(self):
        self.run_update()
        path = self.root / 'config/update-status.json'
        value = json.loads(path.read_text())
        self.assertEqual(value['state'], 'updated')
        self.assertEqual(value['errorCode'], '')
        self.assertLessEqual(value['checkedAt'], value['finishedAt'])
        self.assertLess(path.stat().st_size, 1024)
        self.assertEqual(path.stat().st_mode & 0o777, 0o640)
        self.assertEqual((path.stat().st_uid, path.stat().st_gid), (0, 65534))
        self.assertEqual(set(value), {'state', 'checkedAt', 'finishedAt', 'errorCode'})
        self.run_update()
        self.assertEqual(json.loads(path.read_text())['state'], 'current')
        (self.root / 'network-down').touch()
        self.run_update(False)
        value = json.loads(path.read_text())
        self.assertEqual((value['state'], value['errorCode']), ('failed', 'release_check'))
        self.assertFalse((self.root / 'config/.update-status.pending').exists())

    def test_update_status_rejects_symlink_without_overwriting_target(self):
        target = self.root / 'untouched'
        target.write_text('private sentinel')
        (self.root / 'config/update-status.json').symlink_to(target)
        result = self.run_update()
        self.assertIn('status could not be recorded', result.stderr)
        self.assertEqual(target.read_text(), 'private sentinel')

    def test_running_status_survives_kill_and_next_check_recovers(self):
        (self.root / 'pause-download').touch()
        process = subprocess.Popen(['/bin/bash', str(self.root / 'update.sh'), 'update'],
                                   cwd=self.root, env=self.env, stdout=subprocess.DEVNULL,
                                   stderr=subprocess.DEVNULL, start_new_session=True)
        path = self.root / 'config/update-status.json'
        try:
            for _ in range(200):
                if (self.root / 'download-waiting').exists(): break
                time.sleep(0.02)
            self.assertTrue((self.root / 'download-waiting').exists())
            self.assertEqual(json.loads(path.read_text())['state'], 'running')
            before = path.read_bytes()
            self.run_update(False)
            self.assertEqual(path.read_bytes(), before, 'lock loser overwrote owner status')
            os.killpg(process.pid, signal.SIGKILL)
            process.wait(timeout=5)
            self.assertEqual(json.loads(path.read_text())['state'], 'running')
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.wait(timeout=5)
        (self.root / 'pause-download').unlink()
        self.run_update()
        self.assertEqual(json.loads(path.read_text())['state'], 'updated')

    def test_current_file_with_old_process_recovers_without_binary_download(self):
        subprocess.run([str(self.root / 'bin/systemctl'), 'restart', 'kejilion-node.service'], env=self.env, check=True)
        # Atomic replacement leaves the service running the previous inode.
        shutil.copyfile(self.root / 'release', self.root / 'home/new')
        (self.root / 'home/new').chmod(0o755)
        os.replace(self.root / 'home/new', self.binary)
        self.run_update()
        pid = int((self.root / 'kejilion-node.service.pid').read_text())
        self.assertTrue(os.path.samefile('/proc/%d/exe' % pid, self.binary))
        self.assertEqual(len((self.root / 'downloads').read_text().splitlines()), 1)

    def test_legacy_config_permissions_recover_for_real_service_uid(self):
        config = self.root / 'config/node.json'
        os.chown(config, 0, 0)
        config.chmod(0o600)
        self.run_update()
        self.assertEqual(config.stat().st_gid, 65534)
        self.assertEqual(config.stat().st_mode & 0o777, 0o640)

    def test_known_legacy_file_unit_is_repaired_and_current_broker_restarts(self):
        (self.root / 'optional').touch()
        self.run_update()
        unit = self.root / 'units/kejilion-node-file.service'
        current = unit.read_text()
        legacy = current.replace('RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6', 'RestrictAddressFamilies=AF_UNIX')
        self.assertNotEqual(current, legacy)
        unit.write_text(legacy)
        old_pid = (self.root / 'kejilion-node-file.service.pid').read_text()
        self.run_update()
        self.assertEqual(unit.read_text(), current)
        self.assertNotEqual((self.root / 'kejilion-node-file.service.pid').read_text(), old_pid)

    def test_custom_and_symlink_file_units_are_preserved(self):
        unit = self.root / 'units/kejilion-node-file.service'
        custom = '[Service]\nExecStart=/custom/broker\nRestrictAddressFamilies=AF_UNIX\n'
        unit.write_text(custom)
        self.run_update()
        self.assertEqual(unit.read_text(), custom)
        unit.unlink()
        target = self.root / 'private-unit'
        target.write_text(custom)
        unit.symlink_to(target)
        self.run_update()
        self.assertTrue(unit.is_symlink())
        self.assertEqual(target.read_text(), custom)

    def test_original_historical_file_unit_migrates_but_custom_variant_is_preserved(self):
        self.assertEqual(hashlib.sha256(LEGACY_FILE_UNIT.encode()).hexdigest(), 'b92a708103771a8e1334b74acc44c1c7299b8339f8ca36884e1084e86642f92d')
        (self.root / 'optional').touch()
        self.run_update()
        unit = self.root / 'units/kejilion-node-file.service'
        current = unit.read_text()
        legacy = LEGACY_FILE_UNIT.replace('/usr/local/lib/kejilion-node', str(self.root / 'home')).replace('/etc/kejilion-node', str(self.root / 'config'))
        unit.write_text(legacy)
        old_pid = (self.root / 'kejilion-node-file.service.pid').read_text()
        self.run_update()
        self.assertEqual(unit.read_text(), current)
        self.assertNotEqual((self.root / 'kejilion-node-file.service.pid').read_text(), old_pid)
        custom = legacy.replace('RestartSec=15s', 'RestartSec=30s')
        unit.write_text(custom)
        self.run_update()
        self.assertEqual(unit.read_text(), custom)

    def test_bad_checksum_and_network_failure_preserve_binary_then_retry_recovers(self):
        before = self.binary.read_bytes()
        (self.root / 'bad-download').touch()
        self.run_update(False)
        self.assertEqual(self.binary.read_bytes(), before)
        (self.root / 'bad-download').unlink()
        (self.root / 'network-down').touch()
        self.run_update(False)
        self.assertEqual(self.binary.read_bytes(), before)
        (self.root / 'network-down').unlink()
        self.run_update()

    def test_sigkill_releases_lock_and_legacy_handoff_blocks_only_live_process(self):
        process = subprocess.Popen(['flock', str(self.root / 'home/update.lock'), '/bin/sleep', '60'], start_new_session=True)
        try:
            time.sleep(0.1)
            self.run_update(False)
        finally:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        stat = Path('/proc/%d/stat' % os.getpid()).read_text().rsplit(')', 1)[1].split()
        marker = self.root / 'home/legacy-update.pid'
        marker.write_text('%d %s\n' % (os.getpid(), stat[19]))
        self.assertIn('still finishing', self.run_update(False).stderr)
        # A reused PID with a different start time cannot block future checks.
        marker.write_text('%d 0\n' % os.getpid())
        self.run_update()
        self.assertFalse(marker.exists())

    def test_orphaned_empty_lock_recovers_on_install_and_network_failure_releases_it(self):
        lock = self.root / 'legacy.lock'
        lock.mkdir()
        (self.root / 'network-down').touch()
        result = self.run_update(False, mode='install')
        self.assertIn('Recovered an inactive', result.stdout)
        self.assertIn('release check failed', result.stderr)
        self.assertFalse(lock.exists())
        (self.root / 'network-down').unlink()
        self.run_update(mode='install')
        self.assertFalse(lock.exists())

    def test_live_legacy_script_without_marker_is_preserved_even_after_replacement(self):
        legacy = self.root / 'home/update.sh'
        legacy.write_text('#!/bin/bash\nmkdir "$NODE_TEST_ROOT/legacy.lock" || exit 1\ntouch "$NODE_TEST_ROOT/legacy-ready"\nwhile :; do sleep 30; done\n')
        process = subprocess.Popen(['/bin/bash', 'update.sh'], cwd=legacy.parent, env=self.env, start_new_session=True)
        try:
            for _ in range(100):
                if (self.root / 'legacy-ready').exists(): break
                time.sleep(0.02)
            self.assertTrue((self.root / 'legacy-ready').exists())
            replacement = self.root / 'home/new-updater'
            replacement.write_text('#!/bin/bash\nexit 0\n')
            replacement.replace(legacy)
            self.assertIn('legacy KPanel update lock is still in use', self.run_update(False).stderr)
            self.assertTrue((self.root / 'legacy.lock').is_dir())
            self.assertFalse((self.root / 'downloads').exists())
        finally:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        self.run_update()
        self.assertFalse((self.root / 'legacy.lock').exists())

    def test_unknown_lock_contents_and_symlinks_are_never_removed(self):
        lock = self.root / 'legacy.lock'
        lock.mkdir()
        (lock / 'unknown').write_text('preserve')
        self.run_update(False)
        self.assertEqual((lock / 'unknown').read_text(), 'preserve')
        (lock / 'unknown').unlink()
        lock.rmdir()
        target = self.root / 'external-lock'
        target.mkdir()
        lock.symlink_to(target, target_is_directory=True)
        self.run_update(False)
        self.assertTrue(lock.is_symlink())
        self.assertTrue(target.is_dir())

    def test_invalid_legacy_identity_has_an_explicit_error(self):
        marker = self.root / 'home/legacy-update.pid'
        marker.write_text('')
        self.assertIn('legacy updater identity is invalid', self.run_update(False).stderr)
        self.assertTrue(marker.exists())

    def test_update_bridges_legacy_lock_and_recovers_after_sigkill(self):
        (self.root / 'pause-download').touch()
        process = subprocess.Popen(['/bin/bash', str(self.root / 'update.sh'), 'install'], cwd=self.root, env=self.env,
                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, start_new_session=True)
        try:
            for _ in range(100):
                if (self.root / 'download-waiting').exists(): break
                time.sleep(0.02)
            self.assertTrue((self.root / 'download-waiting').exists())
            self.assertTrue((self.root / 'legacy.lock').is_dir())
            self.assertNotEqual(subprocess.run(['mkdir', str(self.root / 'legacy.lock')], capture_output=True).returncode, 0)
            self.assertIn('another KPanel', self.run_update(False).stderr)
        finally:
            os.killpg(process.pid, signal.SIGKILL)
            process.wait()
        (self.root / 'pause-download').unlink()
        self.run_update(mode='install')
        self.assertFalse((self.root / 'legacy.lock').exists())

    def test_missing_or_untrusted_release_redirect_fails_visibly_before_binary_download(self):
        before = self.binary.read_bytes()
        for headers in ('HTTP/2 200\n', 'Location: https://githubXcom/kejilion/KPanel/releases/download/v9.9.9/SHA256SUMS\n',
                        'Location: https://github.com/other/project/releases/download/v9.9.9/SHA256SUMS\n'):
            with self.subTest(headers=headers):
                (self.root / 'response-headers').write_text(headers)
                result = self.run_update(False)
                self.assertIn('release manifest redirect is invalid', result.stderr)
                self.assertEqual(self.binary.read_bytes(), before)
                self.assertFalse((self.root / 'legacy.lock').exists())
        self.assertTrue(all(url.endswith('/SHA256SUMS') for url in (self.root / 'downloads').read_text().splitlines()))

    def test_interrupt_reports_retry_and_releases_compatibility_lock(self):
        (self.root / 'pause-download').touch()
        process = subprocess.Popen(['/bin/bash', str(self.root / 'update.sh'), 'install'], cwd=self.root, env=self.env,
                                   stdout=subprocess.PIPE, stderr=subprocess.PIPE, text=True, start_new_session=True)
        try:
            for _ in range(100):
                if (self.root / 'download-waiting').exists(): break
                time.sleep(0.02)
            self.assertTrue((self.root / 'download-waiting').exists())
            os.killpg(process.pid, signal.SIGINT)
            stdout, stderr = process.communicate(timeout=5)
            self.assertEqual(process.returncode, 130, stdout + stderr)
            self.assertIn('interrupted; run the command again', stderr)
            self.assertFalse((self.root / 'legacy.lock').exists())
        finally:
            if process.poll() is None:
                os.killpg(process.pid, signal.SIGKILL)
                process.communicate()

    def test_delivery_proxy_rewriting_keeps_release_origin_and_download_errors_are_visible(self):
        updater = self.root / 'update.sh'
        updater.write_text(updater.read_text().replace('https://github.com/', 'https://gh.kejilion.pro/https://github.com/'))
        (self.root / 'binary-network-down').touch()
        result = self.run_update(False)
        self.assertIn('Checking KPanel', result.stdout)
        self.assertIn('Downloading KPanel', result.stdout)
        self.assertIn('node download failed', result.stderr)
        (self.root / 'binary-network-down').unlink()
        self.run_update()

    def test_unsafe_config_is_rejected_without_widening_permissions(self):
        config = self.root / 'config/node.json'
        config.chmod(0o666)
        self.run_update(False)
        self.assertEqual(config.stat().st_mode & 0o777, 0o666)


if __name__ == '__main__':
    unittest.main(verbosity=2)
