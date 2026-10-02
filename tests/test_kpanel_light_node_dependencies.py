#!/usr/bin/env python3
"""Exercise join's dependency bootstrap in a private Linux chroot.

Only fixture package-manager executables exist in the chroot. No host package
manager, repository, service or network is touched, even on a failing test.
Requires Linux root, bash, ldd and chroot; skips elsewhere.
"""
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import unittest

SOURCE = Path(os.environ.get('SCRIPT_PATH', Path(__file__).resolve().parents[1] / 'kejilion.sh')).read_text()
DEPENDENCIES = 'kpanel_node_require_platform() {' + SOURCE.split('kpanel_node_require_platform() {', 1)[1].split('\nkpanel_node_ensure_account() {', 1)[0]
JOIN = 'kpanel_node_join() {' + SOURCE.split('kpanel_node_join() {', 1)[1].split('\nkpanel_node_status() {', 1)[0]
COMMANDS = 'bash curl sha256sum mktemp flock stat readlink awk grep sed cmp od tr install ubus jsonfilter logread logger useradd adduser addgroup systemd-sysusers'.split()

PACKAGE_MANAGER = r'''#!/bin/bash
printf '%s' "${0##*/}" >>/calls
printf '|%s' "$@" >>/calls
printf '\n' >>/calls
case " $* " in
    *' update '*|*' makecache '*)
        if [ -f /fail-index ]; then echo 'fixture repository index failed' >&2; exit 31; fi
        exit 0 ;;
esac
if [ -f /fail-install ]; then echo 'fixture package unavailable' >&2; exit 32; fi
[ ! -f /install-noop ] || exit 0
provide() { /fixture/cp "/supplied/$1" "/usr/bin/$1"; }
for package in "$@"; do
    case "$package" in
        coreutils) for name in install od stat sha256sum mktemp readlink tr; do provide "$name"; done ;;
        coreutils-*) provide "${package#coreutils-}" ;;
        bash) : ;; # Already running bash; its presence is an entry prerequisite.
        curl|grep|sed|flock|ubus|jsonfilter|logger) provide "$package" ;;
        gawk) provide awk ;;
        diffutils) provide cmp ;;
        util-linux) provide flock; provide logger ;;
        shadow-useradd|shadow|passwd|shadow-utils) provide useradd ;;
        logd) provide logread ;;
    esac
done
'''


@unittest.skipUnless(sys.platform.startswith('linux') and os.geteuid() == 0, 'requires isolated Linux root')
class NodeDependencies(unittest.TestCase):
    def setUp(self):
        self.temp = tempfile.TemporaryDirectory(prefix='kpanel-dependencies-test-')
        self.root = Path(self.temp.name)
        self.addCleanup(self.temp.cleanup)
        for directory in ('bin', 'usr/bin', 'usr/sbin', 'sbin', 'etc', 'proc/1', 'run/systemd/system', 'fixture', 'supplied', 'dev'):
            (self.root / directory).mkdir(parents=True, exist_ok=True)
        self.copy_binary(shutil.which('bash'), '/bin/bash')
        self.copy_binary(shutil.which('cp'), '/fixture/cp')
        self.write('/dev/null', '')
        self.write('/proc/1/comm', 'systemd\n')
        self.write('/etc/os-release', 'ID=debian\n')
        self.stub('/usr/bin/uname', 'case "$1" in -s) echo "${TEST_KERNEL:-Linux}" ;; -m) echo "${TEST_ARCH:-x86_64}" ;; esac\n')
        self.stub('/usr/bin/id', '[ "$1" = -u ] && { echo "${TEST_UID:-0}"; exit 0; }; exit 1\n')
        self.stub('/usr/bin/systemctl')
        for command in COMMANDS:
            if command != 'bash':
                self.stub('/supplied/' + command)
                self.stub('/usr/bin/' + command)
        self.remove('adduser', 'addgroup', 'systemd-sysusers')
        self.write('/dependencies.sh', DEPENDENCIES)
        self.write('/join.sh', JOIN)
        self.manager('apt-get')

    def write(self, path, content):
        target = self.root / path.lstrip('/')
        target.parent.mkdir(parents=True, exist_ok=True)
        target.write_text(content)
        return target

    def stub(self, path, body='exit 0\n'):
        target = self.write(path, '#!/bin/bash\n' + body)
        target.chmod(0o755)

    def copy_binary(self, source, destination):
        if not source:
            self.fail('required fixture executable is missing')
        target = self.root / destination.lstrip('/')
        target.parent.mkdir(parents=True, exist_ok=True)
        shutil.copy2(source, target)
        linked = subprocess.run(['ldd', source], text=True, capture_output=True, check=False)
        for library in set(re.findall(r'(/[^\s()]+)', linked.stdout + linked.stderr)):
            if Path(library).is_file():
                output = self.root / library.lstrip('/')
                output.parent.mkdir(parents=True, exist_ok=True)
                shutil.copy2(library, output)

    def remove(self, *commands):
        for command in commands:
            (self.root / 'usr/bin' / command).unlink(missing_ok=True)

    def manager(self, name, directory='/usr/bin'):
        target = self.write(directory + '/' + name, PACKAGE_MANAGER)
        target.chmod(0o755)

    def family(self, family, manager, init='systemd'):
        self.remove('apt-get', 'opkg', 'apk', 'dnf', 'yum')
        self.write('/etc/os-release', 'ID=' + family + '\n')
        self.manager(manager)
        self.write('/proc/1/comm', init + '\n')
        if init == 'procd':
            self.write('/etc/rc.common', '# fixture\n')
            self.write('/lib/functions/procd.sh', '# fixture\n')
            self.stub('/etc/init.d/cron')
        if init == 'openrc':
            (self.root / 'run/systemd/system').rmdir()
            (self.root / 'run/openrc').mkdir(parents=True)
            (self.root / 'etc/periodic/hourly').mkdir(parents=True)
            for name in ('rc-service', 'rc-update', 'supervise-daemon'):
                self.stub('/usr/bin/' + name)
            self.stub('/etc/init.d/crond')

    def run_bootstrap(self, body='kpanel_node_ensure_dependencies', **env):
        script = r'''set -u
export PATH=/usr/bin:/bin:/usr/sbin:/sbin
KPANEL_NODE_SYSTEMCTL=/usr/bin/systemctl
KPANEL_NODE_RC_SERVICE=/usr/bin/rc-service
KPANEL_NODE_RC_UPDATE=/usr/bin/rc-update
KPANEL_NODE_SUPERVISE_DAEMON=/usr/bin/supervise-daemon
source /dependencies.sh
''' + body + '\n'
        self.write('/test.sh', script)
        return subprocess.run([shutil.which('chroot'), str(self.root), '/bin/bash', '/test.sh'],
                              text=True, capture_output=True, timeout=15,
                              env={'PATH': os.environ.get('PATH', ''), 'LANG': 'C', **env})

    def calls(self):
        log = self.root / 'calls'
        return log.read_text().splitlines() if log.exists() else []

    def assert_success(self, result):
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)

    def test_complete_dependencies_do_not_identify_family_or_run_manager(self):
        self.write('/etc/os-release', 'ID=unknown\n')
        self.write('/fail-index', '')
        self.assert_success(self.run_bootstrap())
        self.assertEqual(self.calls(), [])

    def test_openwrt_opkg_batches_split_packages_once(self):
        self.family('openwrt', 'opkg', 'procd')
        self.remove('od', 'install', 'stat', 'flock', 'useradd', 'logread', 'jsonfilter')
        self.assert_success(self.run_bootstrap())
        self.assertEqual(self.calls(), ['opkg|update', 'opkg|install|flock|coreutils-stat|coreutils-od|coreutils-install|jsonfilter|logd|shadow-useradd'])

    def test_openwrt_apk_uses_openwrt_names(self):
        self.family('openwrt', 'apk', 'procd')
        self.remove('od', 'install')
        self.assert_success(self.run_bootstrap())
        self.assertEqual(self.calls(), ['apk|update', 'apk|add|coreutils-od|coreutils-install'])

    def test_procd_derivative_metadata_selects_openwrt(self):
        self.family('custom-router', 'opkg', 'procd')
        self.write('/etc/openwrt_release', 'DISTRIB_ID=CustomRouter\n')
        self.remove('install')
        self.assert_success(self.run_bootstrap())
        self.assertEqual(self.calls()[-1], 'opkg|install|coreutils-install')

    def test_alpine_uses_minimal_flock_package_and_keeps_busybox_account_tools(self):
        self.family('alpine', 'apk', 'openrc')
        self.remove('useradd', 'flock', 'od', 'install', 'logger')
        self.stub('/usr/bin/adduser')
        self.stub('/usr/bin/addgroup')
        self.assert_success(self.run_bootstrap())
        self.assertEqual(self.calls(), ['apk|update', 'apk|add|flock|coreutils|logger'])

    def test_alpine_missing_addgroup_installs_account_provider(self):
        self.family('alpine', 'apk', 'openrc')
        self.remove('useradd')
        self.stub('/usr/bin/adduser')
        self.assert_success(self.run_bootstrap())
        self.assertEqual(self.calls(), ['apk|update', 'apk|add|shadow'])

    def test_debian_deduplicates_coreutils_and_installs_account_provider(self):
        self.remove('stat', 'od', 'install', 'flock', 'awk', 'cmp', 'useradd')
        self.assert_success(self.run_bootstrap())
        self.assertEqual(self.calls(), ['apt-get|update', 'apt-get|install|-y|--no-install-recommends|util-linux|coreutils|gawk|diffutils|passwd'])

    def test_rpm_dnf_and_yum_mappings(self):
        for manager in ('dnf', 'yum'):
            with self.subTest(manager=manager):
                (self.root / 'calls').unlink(missing_ok=True)
                self.family('rocky', manager)
                self.remove('flock', 'install', 'useradd')
                self.assert_success(self.run_bootstrap())
                self.assertEqual(self.calls(), [manager + '|-y|makecache', manager + '|-y|install|util-linux|coreutils|shadow-utils'])

    def test_id_like_parsing_is_data_only(self):
        self.write('/etc/os-release', 'ID=custom\nID_LIKE="ubuntu debian"\nNAME="$(printf attacked >/attacked)"\n')
        self.remove('install')
        self.assert_success(self.run_bootstrap())
        self.assertFalse((self.root / 'attacked').exists())
        self.assertEqual(self.calls()[-1], 'apt-get|install|-y|--no-install-recommends|coreutils')

    def test_unknown_family_does_not_guess_from_available_manager(self):
        self.write('/etc/os-release', 'ID=unknown\nID_LIKE="$(printf attacked >/attacked)"\n')
        self.remove('od')
        result = self.run_bootstrap()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])
        self.assertFalse((self.root / 'attacked').exists())
        self.assertIn('od', result.stderr)

    def test_entware_manager_is_not_selected(self):
        self.family('openwrt', 'opkg', 'procd')
        self.remove('opkg', 'install')
        self.manager('opkg', '/opt/bin')
        result = self.run_bootstrap('export PATH=/opt/bin:$PATH\nkpanel_node_ensure_dependencies')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_ambiguous_openwrt_managers_are_not_guessed(self):
        self.family('openwrt', 'opkg', 'procd')
        self.manager('apk')
        self.remove('od')
        self.assertNotEqual(self.run_bootstrap().returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_index_failure_preserves_error_and_does_not_install(self):
        self.remove('od', 'install')
        self.write('/fail-index', '')
        result = self.run_bootstrap()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), ['apt-get|update'])
        self.assertIn('fixture repository index failed', result.stderr)
        self.assertIn('od install', result.stderr)

    def test_install_failure_preserves_error_and_missing_commands(self):
        self.remove('od', 'install')
        self.write('/fail-install', '')
        result = self.run_bootstrap()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 2)
        self.assertIn('fixture package unavailable', result.stderr)
        self.assertIn('od install', result.stderr)

    def test_success_exit_without_restored_tools_fails_recheck(self):
        self.remove('od', 'install')
        self.write('/install-noop', '')
        result = self.run_bootstrap()
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(len(self.calls()), 2)
        self.assertIn('od install', result.stderr)

    def test_install_shell_function_does_not_hide_missing_binary(self):
        self.remove('install')
        self.assert_success(self.run_bootstrap('install() { return 0; }\nkpanel_node_ensure_dependencies'))
        self.assertEqual(len(self.calls()), 2)

    def test_root_kernel_architecture_checks_happen_before_package_writes(self):
        self.remove('install')
        for env in ({'TEST_UID': '1000'}, {'TEST_KERNEL': 'Darwin'}, {'TEST_ARCH': 'mips'}):
            with self.subTest(env=env):
                self.assertNotEqual(self.run_bootstrap(**env).returncode, 0)
                self.assertEqual(self.calls(), [])

    def test_missing_init_service_does_not_install_an_init_system(self):
        self.family('openwrt', 'opkg', 'procd')
        self.remove('install')
        (self.root / 'etc/init.d/cron').unlink()
        self.assertNotEqual(self.run_bootstrap().returncode, 0)
        self.assertEqual(self.calls(), [])

    def test_join_rejects_bad_token_and_name_without_grep_or_package_writes(self):
        self.remove('grep', 'install')
        for arguments in ("'kpl1.bad token' --name valid", "'kpl1.valid' --name $'bad\\nname'", "'kpl1.' --name valid", "'kpl1.valid' --name ''"):
            with self.subTest(arguments=arguments):
                result = self.run_bootstrap('source /join.sh\nkpanel_node_paths() { :; }\nkpanel_node_join ' + arguments)
                self.assertEqual(result.returncode, 2, result.stdout + result.stderr)
                self.assertEqual(self.calls(), [])

    def test_preflight_retains_read_only_missing_dependency_failure(self):
        self.remove('od')
        result = self.run_bootstrap('kpanel_node_preflight')
        self.assertNotEqual(result.returncode, 0)
        self.assertEqual(self.calls(), [])
        self.assertIn('od', result.stderr)

    def test_only_join_calls_bootstrap(self):
        self.assertEqual(len(re.findall(r'^\s*kpanel_node_ensure_dependencies(?:\s|$)', SOURCE, re.M)), 1)
        self.assertIn('kpanel_node_ensure_dependencies || return 1', JOIN)
        self.assertLess(JOIN.index('[[ "$node_name"'), JOIN.index('kpanel_node_ensure_dependencies ||'))
        self.assertLess(JOIN.index('kpanel_node_ensure_dependencies ||'), JOIN.index('kpanel_node_preflight ||'))


if __name__ == '__main__':
    unittest.main(verbosity=2)
