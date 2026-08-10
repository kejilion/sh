#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"
temporary="$(mktemp -d)"
trap 'rm -rf -- "${temporary}"' EXIT

fail() {
	echo "account-management smoke failed: $*" >&2
	exit 1
}

normalized="${temporary}/kejilion.sh"
adapter="${temporary}/adapter.sh"
tr -d '\r' < "${script_path}" > "${normalized}"
awk '
	/^# KPanel account management protocol start$/ { capture=1; next }
	/^# KPanel account management protocol end$/ { capture=0 }
	capture { print }
' "${normalized}" > "${adapter}"

[ -s "${adapter}" ] || fail "adapter block was not found"
grep -Fqx 'KPANEL_ACCOUNT_MANAGEMENT_PROTOCOL_VERSION="1"' "${adapter}" || fail "protocol v1 marker is missing"
[ "$(grep -Fxc 'KPANEL_ACCOUNT_MANAGEMENT_PROTOCOL_VERSION="1"' "${adapter}")" -eq 1 ] || fail "protocol marker is not unique"
grep -F '[ "${KJ_ACCOUNT_MANAGEMENT_NONINTERACTIVE:-}" = "1" ] ||' "${normalized}" >/dev/null || fail "startup guard is missing"
grep -F 'kpanel_account_dispatch "$@"' "${normalized}" >/dev/null || fail "CLI dispatch is missing"
grep -F -- '--secret-stdin' "${adapter}" >/dev/null || fail "bounded stdin marker is missing"
if grep -E 'chpasswd[^|]*\$KPANEL_ACCOUNT_SECRET|useradd[^|]*\$KPANEL_ACCOUNT_SECRET' "${adapter}" >/dev/null; then
	fail "secret is passed as an external command argument"
fi

# shellcheck disable=SC1090
source "${adapter}"

kpanel_account_valid_username operator || fail "valid username was rejected"
if kpanel_account_valid_username 'root;reboot'; then fail "injected username was accepted"; fi
if kpanel_account_valid_username 'user$'; then fail "machine account suffix was accepted"; fi

kpanel_account_read_secret 256 <<< 'correct horse battery staple' || fail "valid stdin secret frame was rejected"
[ "${KPANEL_ACCOUNT_SECRET}" = 'correct horse battery staple' ] || fail "stdin secret was changed"
if kpanel_account_read_secret 256 <<< $'first\nsecond'; then fail "multiline secret was accepted"; fi
if kpanel_account_read_secret 8 <<< '123456789'; then fail "oversized secret was accepted"; fi

ssh-keygen -q -t ed25519 -N '' -C laptop -f "${temporary}/id_ed25519" || fail "could not build key fixture"
valid_key="$(cat "${temporary}/id_ed25519.pub")"
kpanel_account_key_valid "${valid_key}" || fail "valid ed25519 key was rejected"
if kpanel_account_key_valid 'command="reboot" ssh-ed25519 AAAA'; then fail "authorized_keys options were accepted as a raw key"; fi

# Resource versions must hash key content, not the random mktemp filename used
# while capturing it. Two reads of unchanged account state must be identical.
version_fixture="${temporary}/version-fixture"
mkdir -p "${version_fixture}"
for name in passwd group shadow gshadow sudoers sshd_config; do
	printf '%s\n' "${name}-fixture" > "${version_fixture}/${name}"
done
printf 'root:x:0:0:root:/root:/bin/bash\noperator:x:1000:1000::/home/operator:/bin/bash\n' > "${version_fixture}/passwd"
kpanel_account_passwd_file() { printf '%s\n' "${version_fixture}/passwd"; }
kpanel_account_group_file() { printf '%s\n' "${version_fixture}/group"; }
kpanel_account_shadow_file() { printf '%s\n' "${version_fixture}/shadow"; }
kpanel_account_gshadow_file() { printf '%s\n' "${version_fixture}/gshadow"; }
kpanel_account_sudoers_file() { printf '%s\n' "${version_fixture}/sudoers"; }
kpanel_account_sshd_config() { printf '%s\n' "${version_fixture}/sshd_config"; }
kpanel_account_sshd_fragment() { printf '%s\n' "${version_fixture}/sshd_fragment"; }
kpanel_account_file_safe() { return 0; }
kpanel_account_sshd_effective() { printf '%s\n' 'yes yes enabled'; }
kpanel_account_capture_keys() { printf '%s\n' "${valid_key}" > "$2"; }
kpanel_account_sudo_file() { printf '%s/90-kejilion-%s\n' "${version_fixture}" "$1"; }
stable_version_a="$(kpanel_account_version)"
stable_version_b="$(kpanel_account_version)"
[ "${stable_version_a}" = "${stable_version_b}" ] || fail "unchanged account state produced unstable resource versions"

# A standard account does not need sudo/wheel to exist. Minimal servers may
# legitimately have neither group until an administrator role is requested.
kpanel_account_sudo_file() { printf '%s\n' "${temporary}/90-kejilion-operator"; }
kpanel_account_admin_group() { return 1; }
kpanel_account_role() { printf '%s\n' standard; }
gpasswd() { return 0; }
kpanel_account_set_role operator standard || fail "standard role incorrectly required an administrator group"

fixture_expected="$(printf 'a%.0s' {1..64})"
fixture_final="$(printf 'b%.0s' {1..64})"
capture="${temporary}/create.capture"
version_calls="${temporary}/version.calls"
fixture_lock_file="${temporary}/system-resource.lock"
: > "${fixture_lock_file}"
chmod 600 "${fixture_lock_file}"

kpanel_account_require() { return 0; }
kpanel_system_resource_prepare_lock_file() { printf '%s\n' "${fixture_lock_file}"; }
kpanel_system_resource_lock_path_secure() { return 0; }
# Git for Windows cannot flock a Bash file descriptor. The production lock
# implementation is covered by the system-resource root smoke; this fixture
# only verifies the account dispatcher uses the fixed lock call.
flock() { [ "$*" = "-w 5 -x 9" ]; }
kpanel_system_resource_valid_version() { [[ "$1" =~ ^[0-9a-f]{64}$ ]]; }
kpanel_system_resource_tempdir() { mktemp -d "${temporary}/snapshot.XXXXXX"; }
kpanel_account_snapshot_core() { return 0; }
kpanel_account_create() {
	printf 'username=%s\nrole=%s\ncredential=%s\nsecret=%s\n' "$1" "$2" "$3" "$4" > "${capture}"
}
kpanel_account_version() {
	local count=0
	[ ! -f "${version_calls}" ] || count="$(cat "${version_calls}")"
	count=$((count + 1))
	printf '%s\n' "${count}" > "${version_calls}"
	if [ "${count}" -eq 1 ]; then printf '%s\n' "${fixture_expected}"; else printf '%s\n' "${fixture_final}"; fi
}

receipt="$(printf '%s\n' 'correct horse battery staple' | kpanel_account_dispatch create "${fixture_expected}" operator administrator password --secret-stdin)" || fail "create transaction failed"
grep -Fqx 'KPANEL_ACCOUNT_MANAGEMENT_STATUS=applied' <<< "${receipt}" || fail "create did not return applied"
grep -Fqx "KPANEL_ACCOUNT_MANAGEMENT_VERSION=${fixture_final}" <<< "${receipt}" || fail "create final version is missing"
grep -Fqx 'secret=correct horse battery staple' "${capture}" || fail "stdin secret did not reach the fixed action"
if grep -F 'correct horse battery staple' <<< "${receipt}" >/dev/null; then fail "secret leaked into receipt"; fi

# The guided Root migration must remove the newly created account and restore
# both account files and SSH policy if the second phase fails.
: > "${version_calls}"
printf '0\n' > "${version_calls}"
restore_capture="${temporary}/restore.capture"
cleanup_capture="${temporary}/cleanup.capture"
kpanel_account_version() { printf '%s\n' "${fixture_expected}"; }
kpanel_account_snapshot_ssh() { return 0; }
kpanel_account_restore_core() { printf 'core\n' >> "${restore_capture}"; }
kpanel_account_restore_ssh() { printf 'ssh\n' >> "${restore_capture}"; }
kpanel_account_create() { return 0; }
kpanel_account_apply_ssh_policy() { return 1; }
kpanel_account_sudo_file() { printf '%s\n' "${temporary}/90-kejilion-operator"; }
passwd() { return 0; }
userdel() { printf '%s\n' "$*" > "${cleanup_capture}"; }
set +e
failure_receipt="$(printf '%s\n' "${valid_key}" | kpanel_account_dispatch create-admin-disable-root "${fixture_expected}" operator key --secret-stdin)"
failure_rc=$?
set -e
[ "${failure_rc}" -ne 0 ] || fail "failed Root migration returned success"
grep -Fqx 'KPANEL_ACCOUNT_MANAGEMENT_STATUS=failed' <<< "${failure_receipt}" || fail "failed Root migration did not report rollback"
grep -Fqx core "${restore_capture}" && grep -Fqx ssh "${restore_capture}" || fail "Root migration did not restore both resources"
grep -Fqx -- '-r operator' "${cleanup_capture}" || fail "Root migration did not remove the replacement account"

# A failed userdel -r cannot promise that the home directory is intact. The
# adapter must preserve the account snapshot and report needs-attention.
kpanel_account_exists() { return 0; }
kpanel_account_snapshot_core() { return 0; }
kpanel_account_restore_core() { return 0; }
kpanel_account_version() { printf '%s\n' "${fixture_expected}"; }
kpanel_system_resource_persist_recovery_snapshot() { printf '%s\n' '/var/lib/kejilion-panel/system/recovery/system-resource/20260811T000000Z-account-management.ABC123'; }
userdel() { return 1; }
set +e
delete_receipt="$(kpanel_account_dispatch delete "${fixture_expected}" operator true)"
delete_rc=$?
set -e
[ "${delete_rc}" -ne 0 ] || fail "failed home removal returned success"
grep -Fqx 'KPANEL_ACCOUNT_MANAGEMENT_STATUS=needs-attention' <<< "${delete_receipt}" || fail "partial home removal was reported as rolled back"
grep -Fqx 'KPANEL_ACCOUNT_MANAGEMENT_BACKUP=/var/lib/kejilion-panel/system/recovery/system-resource/20260811T000000Z-account-management.ABC123' <<< "${delete_receipt}" || fail "partial home removal did not preserve its recovery snapshot"

echo "account-management smoke passed"
