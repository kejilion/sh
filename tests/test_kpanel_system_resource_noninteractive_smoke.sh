#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script_path="${project_root}/kejilion.sh"
test_root="$(mktemp -d)"
case "$(uname -s)" in
	Linux) test_recovery_state="/var/tmp/kejilion-panel-system-resource-test.$$" ;;
	*) test_recovery_state="${project_root}/.test-kpanel-system-resource-recovery.$$" ;;
esac
trap 'rm -rf -- "${test_root}" "${test_recovery_state}"' EXIT

fail() {
	printf 'FAIL: %s\n' "$1" >&2
	if [ -n "${test_stderr:-}" ] && [ -s "${test_stderr}" ]; then
		printf '%s\n' '--- adapter stderr ---' >&2
		command cat -- "${test_stderr}" >&2
	fi
	exit 1
}

grep -F '[ "${KJ_SYSTEM_RESOURCE_NONINTERACTIVE:-}" = "1" ] ||' "${script_path}" >/dev/null
grep -F 'kpanel_system_resource_dispatch "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_system_resource_file_within_bounds "$path" 262144 1024' "${script_path}" >/dev/null
grep -F 'kpanel_system_resource_file_within_bounds "$target" 262144 512' "${script_path}" >/dev/null
grep -F '[ "$bytes" -le 524288 ]' "${script_path}" >/dev/null
grep -F 'iptables -w 5 "$@"' "${script_path}" >/dev/null
grep -F 'iptables-restore -w 5' "${script_path}" >/dev/null
grep -F 'allow-ip|block-ip|remove-ip)' "${script_path}" >/dev/null
grep -F 'open-all|close-all|enable-ping|disable-ping|enable-ddos|disable-ddos)' "${script_path}" >/dev/null
grep -F 'printf '\''%s\n'\'' "/var/lib/kejilion-panel"' "${script_path}" >/dev/null
grep -F 'chown -R -- 0:0 "$destination"' "${script_path}" >/dev/null
grep -F 'find "$destination" -type d -exec chmod 700' "${script_path}" >/dev/null
grep -F 'find "$destination" -type f -exec chmod 600' "${script_path}" >/dev/null
grep -F 'flock -w 5 -x 9' "${script_path}" >/dev/null

adapter_body="$(
	sed -n '/^# KPanel system resource protocol start/,/^# KPanel system resource protocol end/p' "${script_path}" |
		sed 's/\r$//'
)"
[ -n "${adapter_body}" ] || fail "system-resource adapter block was not found"
grep -Fqx 'KPANEL_SYSTEM_RESOURCE_PROTOCOL_VERSION="2"' <<< "${adapter_body}" ||
	fail "system-resource protocol v2 marker is missing"
[ "$(grep -Fxc 'KPANEL_SYSTEM_RESOURCE_PROTOCOL_VERSION="2"' <<< "${adapter_body}")" -eq 1 ] ||
	fail "system-resource protocol v2 marker must be unique"
printf '%s\n' "${adapter_body}" | grep -F '[ "$command_source" = "--command-stdin" ]' >/dev/null ||
	fail "cron command stdin marker is missing"
if printf '%s\n' "${adapter_body}" | grep -E 'grep .*\$new_line' >/dev/null; then
	fail "cron command is passed to an external grep argv"
fi
eval "${adapter_body}"

test_hosts="${test_root}/hosts"
test_crontab="${test_root}/crontab"
test_lock="${test_root}/system-resource.lock"
test_interfaces="${test_root}/interfaces"
test_rules="${test_root}/rules.v4"
test_iptables="${test_root}/iptables.state"
test_stderr="${test_root}/stderr"
mkdir -p -- "${test_interfaces}"

kpanel_system_resource_hosts_file() { printf '%s\n' "${test_hosts}"; }
kpanel_system_resource_lock_file() { printf '%s\n' "${test_lock}"; }
kpanel_system_resource_interfaces_dir() { printf '%s\n' "${test_interfaces}"; }
kpanel_system_resource_iptables_rules_file() { printf '%s\n' "${test_rules}"; }
kpanel_system_resource_state_root() {
	printf '%s\n' "${KPANEL_FAKE_RECOVERY_STATE_ROOT:-${test_recovery_state}}"
}
kpanel_system_resource_tempdir() {
	local resource="$1"
	local directory
	directory="$(mktemp -d "${test_root}/kejilion-system-resource-${resource}.XXXXXX")" || return 1
	chmod 700 "${directory}" || return 1
	printf '%s\n' "${directory}"
}

flock() {
	[ "$#" -eq 4 ] && [ "$1" = -w ] && [ "$2" = 5 ] && [ "$3" = -x ] && [ "$4" = 9 ] || return 1
	[ "${KPANEL_FAKE_FLOCK_TIMEOUT:-0}" != 1 ] || return 1
	case "$(uname -s)" in
		MINGW*|MSYS*|CYGWIN*) return 0 ;;
		*) command flock "$@" ;;
	esac
}

crontab() {
	case "${1:-}" in
		-l)
			if [ -e "${test_root}/crontab-read-error" ]; then
				printf 'permission denied\n' >&2
				return 1
			fi
			if [ -f "${test_crontab}" ]; then
				command cat -- "${test_crontab}"
				return 0
			fi
			printf 'no crontab for root\n' >&2
			return 1
			;;
		-r)
			command rm -f -- "${test_crontab}"
			;;
		*)
			[ "$#" -eq 1 ] || return 1
			if [ -e "${test_root}/crontab-install-error" ]; then
				command rm -f -- "${test_root}/crontab-install-error"
				return 1
			fi
			command cp -- "$1" "${test_crontab}"
			;;
	esac
}

ip() {
	[ "$#" -eq 5 ] && [ "$1" = link ] && [ "$2" = set ] && [ "$3" = dev ] || return 1
	case "$5" in
		up) printf '0x1003\n' > "${test_interfaces}/$4/flags" ;;
		down) printf '0x1002\n' > "${test_interfaces}/$4/flags" ;;
		*) return 1 ;;
	esac
	if [ -e "${test_root}/ip-partial-error" ]; then
		command rm -f -- "${test_root}/ip-partial-error"
		return 1
	fi
}

iptables_rule_text() {
	local chain="$1"
	shift
	local argument rule="-A ${chain}"
	for argument in "$@"; do
		rule="${rule} ${argument}"
	done
	printf '%s\n' "${rule}"
}

iptables() {
	[ "${1:-}" = -w ] && [ "${2:-}" = 5 ] || return 1
	shift 2
	local operation="${1:-}" chain rule temporary prefix
	case "${operation}" in
		-C)
			chain="$2"
			shift 2
			rule="$(iptables_rule_text "${chain}" "$@")"
			grep -Fqx -- "${rule}" "${test_iptables}"
			;;
		-D)
			chain="$2"
			shift 2
			rule="$(iptables_rule_text "${chain}" "$@")"
			temporary="${test_iptables}.delete"
			awk -v target="${rule}" '
				BEGIN { removed=0 }
				!removed && $0 == target { removed=1; next }
				{ print }
				END { if (!removed) exit 1 }
			' "${test_iptables}" > "${temporary}" || {
				command rm -f -- "${temporary}"
				return 1
			}
			command mv -f -- "${temporary}" "${test_iptables}"
			;;
		-I)
			chain="$2"
			[ "${3:-}" = 1 ] || return 1
			shift 3
			rule="$(iptables_rule_text "${chain}" "$@")"
			prefix="-A ${chain} "
			temporary="${test_iptables}.insert"
			awk -v prefix="${prefix}" -v rule="${rule}" '
				BEGIN { inserted=0 }
				!inserted && index($0, prefix) == 1 { print rule; inserted=1 }
				{ print }
				END { if (!inserted) print rule }
			' "${test_iptables}" > "${temporary}" || return 1
			command mv -f -- "${temporary}" "${test_iptables}"
			;;
		-A)
			chain="$2"
			shift 2
			iptables_rule_text "${chain}" "$@" >> "${test_iptables}"
			;;
		-S)
			chain="$2"
			grep -Eq "^(-N|-P) ${chain}( |$)|^-A ${chain} " "${test_iptables}"
			;;
		-P)
			chain="$2"
			local policy="$3"
			temporary="${test_iptables}.policy"
			awk -v chain="${chain}" -v policy="${policy}" '
				$0 ~ "^-P " chain " " { if (!done) print "-P " chain " " policy; done=1; next }
				{ print }
				END { if (!done) print "-P " chain " " policy }
			' "${test_iptables}" > "${temporary}" || return 1
			command mv -f -- "${temporary}" "${test_iptables}"
			;;
		-F)
			temporary="${test_iptables}.flush"
			awk '$1 != "-A"' "${test_iptables}" > "${temporary}" || return 1
			command mv -f -- "${temporary}" "${test_iptables}"
			;;
		-X)
			temporary="${test_iptables}.chains"
			awk '$1 != "-N"' "${test_iptables}" > "${temporary}" || return 1
			command mv -f -- "${temporary}" "${test_iptables}"
			;;
		*) return 1 ;;
	esac
}

iptables-save() {
	local remaining
	if [ -f "${test_root}/iptables-save-countdown" ]; then
		remaining="$(command cat -- "${test_root}/iptables-save-countdown")"
		if [ "${remaining}" -le 1 ]; then
			command rm -f -- "${test_root}/iptables-save-countdown"
			return 1
		fi
		printf '%s\n' "$((remaining - 1))" > "${test_root}/iptables-save-countdown"
	fi
	command cat -- "${test_iptables}"
}

iptables-restore() {
	[ "${1:-}" = -w ] && [ "${2:-}" = 5 ] || return 1
	command cat > "${test_root}/iptables-restore.last" || return 1
	command cp -- "${test_root}/iptables-restore.last" "${test_iptables}" || return 1
	if [ -f "${test_root}/iptables-restore-output" ]; then
		command cp -- "${test_root}/iptables-restore-output" "${test_iptables}" || return 1
	fi
}

mv() {
	local destination="${!#}"
	if [ "${KPANEL_FAKE_HOSTS_MV_FAIL:-0}" = 1 ] && [ "${destination}" = "${test_hosts}" ]; then
		command mv "$@" || return 1
		return 1
	fi
	command mv "$@"
}

cp() {
	local destination="${!#}"
	if [ "${KPANEL_FAKE_HOSTS_RESTORE_FAIL:-0}" = 1 ] && [ "${destination}" = "${test_hosts}" ]; then
		return 1
	fi
	command cp "$@"
}

chown() {
	local argument
	if [ "$(id -u)" -ne 0 ]; then
		for argument in "$@"; do
			[ "${argument}" != 0:0 ] || return 0
		done
	fi
	command chown "$@"
}

assert_receipt() {
	local expected_status="$1"
	local line_count
	printf '%s\n' "${RUN_OUTPUT}" | grep -Fqx "KPANEL_SYSTEM_RESOURCE_STATUS=${expected_status}" ||
		fail "receipt status was not ${expected_status}: ${RUN_OUTPUT}"
	printf '%s\n' "${RUN_OUTPUT}" |
		grep -Eq '^KPANEL_SYSTEM_RESOURCE_VERSION=[0-9a-f]{64}$' ||
		fail "receipt version is missing or invalid: ${RUN_OUTPUT}"
	if printf '%s\n' "${RUN_OUTPUT}" | grep -Ev '^KPANEL_SYSTEM_RESOURCE_(STATUS|VERSION|BACKUP)=' >/dev/null; then
		fail "stdout contains a non-protocol line: ${RUN_OUTPUT}"
	fi
	line_count="$(printf '%s\n' "${RUN_OUTPUT}" | awk 'NF { count++ } END { print count + 0 }')"
	[ "${line_count}" -ge 2 ] && [ "${line_count}" -le 3 ] ||
		fail "receipt has an invalid line count: ${RUN_OUTPUT}"
}

run_dispatch() {
	local expected_status="$1"
	shift
	set +e
	RUN_OUTPUT="$(kpanel_system_resource_dispatch "$@" 2> "${test_stderr}")"
	RUN_RC=$?
	set -e
	assert_receipt "${expected_status}"
}

run_dispatch_stdin() {
	local stdin_value="$1"
	local expected_status="$2"
	shift 2
	RUN_ARGS=("$@")
	set +e
	RUN_OUTPUT="$(printf '%s\n' "${stdin_value}" | kpanel_system_resource_dispatch "$@" 2> "${test_stderr}")"
	RUN_RC=$?
	set -e
	assert_receipt "${expected_status}"
}

run_dispatch_file() {
	local stdin_path="$1"
	local expected_status="$2"
	shift 2
	RUN_ARGS=("$@")
	set +e
	RUN_OUTPUT="$(kpanel_system_resource_dispatch "$@" < "${stdin_path}" 2> "${test_stderr}")"
	RUN_RC=$?
	set -e
	assert_receipt "${expected_status}"
}

assert_argv_omits() {
	local secret="$1"
	local argument
	for argument in "${RUN_ARGS[@]}"; do
		[[ "${argument}" != *"${secret}"* ]] || fail "cron secret appeared in adapter argv"
	done
}

zero_version="$(kpanel_system_resource_zero_version)"
unset KJ_SYSTEM_RESOURCE_NONINTERACTIVE
run_dispatch failed hosts add "${zero_version}" 127.0.0.1 guarded.local ""
[ "${RUN_RC}" -eq 2 ] || fail "protocol guard returned ${RUN_RC}, expected 2"

export KJ_SYSTEM_RESOURCE_NONINTERACTIVE=1
kpanel_system_resource_require_platform() {
	if [ "${KJ_SYSTEM_RESOURCE_NONINTERACTIVE:-}" != 1 ]; then
		kpanel_system_resource_emit failed "$(kpanel_system_resource_zero_version)"
		return 2
	fi
}

KPANEL_FAKE_FLOCK_TIMEOUT=1
run_dispatch conflict hosts add "${zero_version}" 127.0.0.1 locked.local ""
unset KPANEL_FAKE_FLOCK_TIMEOUT
[ "${RUN_RC}" -eq 2 ] || fail "system-resource lock timeout did not return conflict"

printf '%s\n' \
	'127.0.0.1 localhost' \
	'10.0.0.1 duplicate.local' \
	'10.0.0.1 duplicate.local' > "${test_hosts}"
hosts_v0="$(kpanel_system_resource_hosts_version)"
run_dispatch applied hosts add "${hosts_v0}" 192.0.2.10 new.local,alias.local managed
[ "${RUN_RC}" -eq 0 ] || fail "hosts add failed"
grep -Fqx $'192.0.2.10\tnew.local alias.local # managed' "${test_hosts}" || fail "hosts add did not write the exact line"
run_dispatch conflict hosts add "${hosts_v0}" 192.0.2.11 conflict.local ""
[ "${RUN_RC}" -eq 2 ] || fail "stale hosts write did not return 2"
hosts_v1="$(kpanel_system_resource_hosts_version)"
run_dispatch applied hosts delete "${hosts_v1}" 2
[ "${RUN_RC}" -eq 0 ] || fail "hosts line-number delete failed"
[ "$(grep -Fxc '10.0.0.1 duplicate.local' "${test_hosts}")" -eq 1 ] || fail "hosts delete did not target one exact duplicate row"
printf '%s\n%s' '127.0.0.1 localhost' '192.0.2.20 final.local' > "${test_hosts}"
hosts_no_newline_v="$(kpanel_system_resource_hosts_version)"
run_dispatch applied hosts delete "${hosts_no_newline_v}" 1
[ "${RUN_RC}" -eq 0 ] || fail "hosts delete on a non-newline-terminated file failed"
[ "$(command cat -- "${test_hosts}")" = '192.0.2.20 final.local' ] || fail "hosts delete changed the retained final row"
[ "$(tail -c 1 "${test_hosts}" | wc -l)" -eq 0 ] || fail "hosts delete changed final-newline semantics"
hosts_before="${test_root}/hosts.before-rollback"
command cp -- "${test_hosts}" "${hosts_before}"
hosts_v2="$(kpanel_system_resource_hosts_version)"
KPANEL_FAKE_HOSTS_MV_FAIL=1
run_dispatch failed hosts add "${hosts_v2}" 192.0.2.12 rollback.local ""
unset KPANEL_FAKE_HOSTS_MV_FAIL
[ "${RUN_RC}" -eq 1 ] || fail "hosts rollback path did not return 1"
cmp -s -- "${hosts_before}" "${test_hosts}" || fail "hosts rollback did not restore original bytes"

printf '%s\n' '127.0.0.1 localhost' '192.0.2.30 recovery.local' > "${test_hosts}"
hosts_recovery_before="${test_root}/hosts.before-needs-attention"
command cp -- "${test_hosts}" "${hosts_recovery_before}"
hosts_recovery_v="$(kpanel_system_resource_hosts_version)"
KPANEL_FAKE_HOSTS_MV_FAIL=1
KPANEL_FAKE_HOSTS_RESTORE_FAIL=1
run_dispatch rollback-failed hosts add "${hosts_recovery_v}" 192.0.2.31 broken-rollback.local ""
unset KPANEL_FAKE_HOSTS_MV_FAIL KPANEL_FAKE_HOSTS_RESTORE_FAIL
[ "${RUN_RC}" -eq 1 ] || fail "hosts rollback-failed path did not return 1"
recovery_path="$(printf '%s\n' "${RUN_OUTPUT}" | sed -n 's/^KPANEL_SYSTEM_RESOURCE_BACKUP=//p')"
[ -n "${recovery_path}" ] || fail "rollback-failed receipt did not include a persistent backup"
[[ "${recovery_path}" = "${test_recovery_state}/system/recovery/system-resource/"* ]] ||
	fail "rollback-failed backup was outside the recovery state directory: ${recovery_path}"
[[ "${recovery_path}" != /tmp/* ]] || fail "rollback-failed backup remained in PrivateTmp"
[ -d "${recovery_path}" ] && [ ! -L "${recovery_path}" ] || fail "persistent recovery backup is not a real directory"
cmp -s -- "${hosts_recovery_before}" "${recovery_path}/hosts.backup" ||
	fail "persistent recovery backup did not preserve the original hosts bytes"
if [ "$(uname -s)" = Linux ]; then
	[ "$(stat -c '%a' "${recovery_path}")" = 700 ] || fail "persistent recovery directory mode is not 0700"
	[ "$(stat -c '%a' "${recovery_path}/hosts.backup")" = 600 ] || fail "persistent recovery file mode is not 0600"
	if [ "$(id -u)" -eq 0 ]; then
		[ "$(stat -c '%u:%g' "${recovery_path}")" = 0:0 ] || fail "persistent recovery directory is not root-owned"
		[ "$(stat -c '%u:%g' "${recovery_path}/hosts.backup")" = 0:0 ] || fail "persistent recovery file is not root-owned"
	fi
fi

printf '%s\n' '127.0.0.1 localhost' '192.0.2.40 recovery-fail.local' > "${test_hosts}"
hosts_recovery_fail_before="${test_root}/hosts.before-recovery-persist-fail"
command cp -- "${test_hosts}" "${hosts_recovery_fail_before}"
hosts_recovery_fail_v="$(kpanel_system_resource_hosts_version)"
KPANEL_FAKE_HOSTS_MV_FAIL=1
KPANEL_FAKE_HOSTS_RESTORE_FAIL=1
KPANEL_FAKE_RECOVERY_STATE_ROOT="${test_root}/missing-parent/state"
run_dispatch rollback-failed hosts add "${hosts_recovery_fail_v}" 192.0.2.41 no-backup.local ""
unset KPANEL_FAKE_HOSTS_MV_FAIL KPANEL_FAKE_HOSTS_RESTORE_FAIL KPANEL_FAKE_RECOVERY_STATE_ROOT
[ "${RUN_RC}" -eq 1 ] || fail "recovery persistence failure did not return rollback-failed"
if printf '%s\n' "${RUN_OUTPUT}" | grep -q '^KPANEL_SYSTEM_RESOURCE_BACKUP='; then
	fail "recovery persistence failure emitted a false backup path"
fi
grep -F '失败快照持久化失败' "${test_stderr}" >/dev/null ||
	fail "recovery persistence failure was not reported on stderr"
private_recovery_path="$(find "${test_root}" -maxdepth 1 -type d -name 'kejilion-system-resource-hosts.*' -print -quit)"
[ -n "${private_recovery_path}" ] || fail "failed recovery persistence discarded the PrivateTmp fallback snapshot"
cmp -s -- "${hosts_recovery_fail_before}" "${private_recovery_path}/hosts.backup" ||
	fail "PrivateTmp fallback snapshot did not preserve the original hosts bytes"

cron_line='0 * * * * echo duplicate'
printf '%s\n%s\n' "${cron_line}" "${cron_line}" > "${test_crontab}"
cron_v0="$(kpanel_system_resource_cron_version)"
cron_secret='  printf cron-secret-value  '
run_dispatch_stdin "${cron_secret}" applied cron add "${cron_v0}" '15 2 * JAN MON' --command-stdin
[ "${RUN_RC}" -eq 0 ] || fail "cron add with English names failed"
assert_argv_omits 'cron-secret-value'
printf '%s\n' "${RUN_OUTPUT}" | grep -F 'cron-secret-value' >/dev/null && fail "cron secret leaked to stdout"
grep -F 'cron-secret-value' "${test_stderr}" >/dev/null && fail "cron secret leaked to stderr"
grep -Fqx "15 2 * JAN MON ${cron_secret}" "${test_crontab}" || fail "cron command whitespace was not preserved"
cron_v1="$(kpanel_system_resource_cron_version)"
run_dispatch_stdin 'echo updated' applied cron update "${cron_v1}" 2 '*/5 * * * *' --command-stdin
[ "${RUN_RC}" -eq 0 ] || fail "cron line-number update failed"
[ "$(sed -n '2p' "${test_crontab}")" = '*/5 * * * * echo updated' ] || fail "cron update targeted the wrong row"
cron_v2="$(kpanel_system_resource_cron_version)"
run_dispatch applied cron delete "${cron_v2}" 1
[ "${RUN_RC}" -eq 0 ] || fail "cron line-number delete failed"
[ "$(sed -n '1p' "${test_crontab}")" = '*/5 * * * * echo updated' ] || fail "cron delete targeted the wrong row"
cron_before_invalid="${test_root}/cron.before-invalid"
command cp -- "${test_crontab}" "${cron_before_invalid}"
cron_v2="$(kpanel_system_resource_cron_version)"
run_dispatch_stdin 'echo quartz' failed cron add "${cron_v2}" '0 0 L * *' --command-stdin
[ "${RUN_RC}" -eq 2 ] || fail "Quartz cron token was not rejected"
cmp -s -- "${cron_before_invalid}" "${test_crontab}" || fail "invalid cron input changed the crontab"
legacy_secret='legacy-argv-secret'
run_dispatch failed cron add "${cron_v2}" '0 4 * * *' "${legacy_secret}"
[ "${RUN_RC}" -eq 2 ] || fail "legacy cron command argv was not rejected"
printf '%s\n' "${RUN_OUTPUT}" | grep -F "${legacy_secret}" >/dev/null && fail "rejected cron argv leaked to stdout"
grep -F "${legacy_secret}" "${test_stderr}" >/dev/null && fail "rejected cron argv leaked to stderr"
run_dispatch_stdin $'echo first\necho second' failed cron add "${cron_v2}" '0 4 * * *' --command-stdin
[ "${RUN_RC}" -eq 2 ] || fail "multiline cron stdin frame was not rejected"
printf -v overlong_command '%*s' 2049 ''
overlong_command="${overlong_command// /x}"
run_dispatch_stdin "${overlong_command}" failed cron add "${cron_v2}" '0 4 * * *' --command-stdin
[ "${RUN_RC}" -eq 2 ] || fail "overlong cron stdin frame was not rejected"
cron_bad_frame="${test_root}/cron-command.bad-frame"
printf 'echo safe\000echo hidden\n' > "${cron_bad_frame}"
run_dispatch_file "${cron_bad_frame}" failed cron add "${cron_v2}" '0 4 * * *' --command-stdin
[ "${RUN_RC}" -eq 2 ] || fail "NUL cron stdin frame was not rejected"
printf 'echo safe\recho hidden\n' > "${cron_bad_frame}"
run_dispatch_file "${cron_bad_frame}" failed cron add "${cron_v2}" '0 4 * * *' --command-stdin
[ "${RUN_RC}" -eq 2 ] || fail "CR cron stdin frame was not rejected"
printf 'echo unterminated' > "${cron_bad_frame}"
run_dispatch_file "${cron_bad_frame}" failed cron add "${cron_v2}" '0 4 * * *' --command-stdin
[ "${RUN_RC}" -eq 2 ] || fail "unterminated cron stdin frame was not rejected"
cmp -s -- "${cron_before_invalid}" "${test_crontab}" || fail "rejected cron stdin frame changed the crontab"
command cp -- "${test_crontab}" "${cron_before_invalid}"
touch "${test_root}/crontab-read-error"
run_dispatch failed cron delete "${cron_v2}" 1
command rm -f -- "${test_root}/crontab-read-error"
[ "${RUN_RC}" -eq 1 ] || fail "unexpected crontab -l failure was treated as an empty table"
cmp -s -- "${cron_before_invalid}" "${test_crontab}" || fail "crontab read error changed the crontab"
cron_v3="$(kpanel_system_resource_cron_version)"
touch "${test_root}/crontab-install-error"
run_dispatch_stdin 'echo rollback' failed cron add "${cron_v3}" '0 3 * * *' --command-stdin
[ "${RUN_RC}" -eq 1 ] || fail "cron install rollback path did not return 1"
cmp -s -- "${cron_before_invalid}" "${test_crontab}" || fail "cron rollback did not restore original bytes"

mkdir -p -- "${test_interfaces}/eth-test"
printf '0x1002\n' > "${test_interfaces}/eth-test/flags"
printf '02:00:00:00:00:01\n' > "${test_interfaces}/eth-test/address"
interface_v0="$(kpanel_system_resource_interface_version eth-test)"
run_dispatch applied network-interface state "${interface_v0}" eth-test up
[ "${RUN_RC}" -eq 0 ] || fail "network interface state change failed"
[ "$(kpanel_system_resource_interface_admin_state eth-test)" = up ] || fail "network interface admin state was not updated"
interface_v1="$(kpanel_system_resource_interface_version eth-test)"
run_dispatch unchanged network-interface state "${interface_v1}" eth-test up
[ "${RUN_RC}" -eq 0 ] || fail "network interface idempotence failed"
run_dispatch conflict network-interface state "${interface_v0}" eth-test down
[ "${RUN_RC}" -eq 2 ] || fail "stale network interface write did not return 2"
touch "${test_root}/ip-partial-error"
run_dispatch failed network-interface state "${interface_v1}" eth-test down
[ "${RUN_RC}" -eq 1 ] || fail "partial network interface failure did not return 1"
[ "$(kpanel_system_resource_interface_admin_state eth-test)" = up ] || fail "network interface rollback did not restore admin state"

firewall_dynamic_a="${test_root}/iptables.dynamic-a"
firewall_dynamic_b="${test_root}/iptables.dynamic-b"
firewall_rule_changed="${test_root}/iptables.rule-changed"
firewall_policy_changed="${test_root}/iptables.policy-changed"
printf '%s\r\n' \
	'# Generated by iptables-save v1.8.9 (nf_tables) on Mon Aug 10 00:00:00 2026' \
	'*filter' \
	':INPUT ACCEPT [123:456]' \
	':FORWARD DROP [7:8]' \
	'-A INPUT -p tcp --dport 22 -j ACCEPT' \
	'# Static audit [12:34]' \
	'COMMIT' \
	'# Completed on Mon Aug 10 00:00:01 2026' > "${firewall_dynamic_a}"
printf '%s\n' \
	'# Generated by iptables-save v9.9.9 on Tue Aug 11 11:11:11 2026' \
	'*filter' \
	':INPUT ACCEPT [999:888]' \
	':FORWARD DROP [0:999]' \
	'-A INPUT -p tcp --dport 22 -j ACCEPT' \
	'# Static audit [12:34]' \
	'COMMIT' \
	'# Completed on Tue Aug 11 11:11:12 2026' > "${firewall_dynamic_b}"
printf '%s\n' \
	'# Generated by iptables-save v9.9.9 on Tue Aug 11 11:11:11 2026' \
	'*filter' \
	':INPUT ACCEPT [999:888]' \
	':FORWARD DROP [0:999]' \
	'-A INPUT -p tcp --dport 23 -j ACCEPT' \
	'# Static audit [12:34]' \
	'COMMIT' \
	'# Completed on Tue Aug 11 11:11:12 2026' > "${firewall_rule_changed}"
printf '%s\n' \
	'# Generated by iptables-save v9.9.9 on Tue Aug 11 11:11:11 2026' \
	'*filter' \
	':INPUT DROP [999:888]' \
	':FORWARD DROP [0:999]' \
	'-A INPUT -p tcp --dport 22 -j ACCEPT' \
	'# Static audit [12:34]' \
	'COMMIT' \
	'# Completed on Tue Aug 11 11:11:12 2026' > "${firewall_policy_changed}"

firewall_canonical_actual="${test_root}/iptables.canonical-actual"
firewall_canonical_expected="${test_root}/iptables.canonical-expected"
printf '%s\n' \
	'*filter' \
	':INPUT ACCEPT [0:0]' \
	':FORWARD DROP [0:0]' \
	'-A INPUT -p tcp --dport 22 -j ACCEPT' \
	'# Static audit [12:34]' \
	'COMMIT' > "${firewall_canonical_expected}"
kpanel_system_resource_firewall_canonicalize "${firewall_dynamic_a}" "${firewall_canonical_actual}" ||
	fail "firewall canonicalization failed"
cmp -s -- "${firewall_canonical_expected}" "${firewall_canonical_actual}" ||
	fail "firewall canonical bytes do not match the protocol definition"

command cp -- "${firewall_dynamic_a}" "${test_iptables}"
firewall_dynamic_v1="$(kpanel_system_resource_firewall_version)"
command cp -- "${firewall_dynamic_b}" "${test_iptables}"
firewall_dynamic_v2="$(kpanel_system_resource_firewall_version)"
[ "${firewall_dynamic_v1}" = "${firewall_dynamic_v2}" ] ||
	fail "firewall version changed for timestamp, counter, or CRLF-only differences"
command cp -- "${firewall_rule_changed}" "${test_iptables}"
firewall_rule_v="$(kpanel_system_resource_firewall_version)"
[ "${firewall_dynamic_v1}" != "${firewall_rule_v}" ] || fail "firewall version ignored a rule change"
command cp -- "${firewall_policy_changed}" "${test_iptables}"
firewall_policy_v="$(kpanel_system_resource_firewall_version)"
[ "${firewall_dynamic_v1}" != "${firewall_policy_v}" ] || fail "firewall version ignored a policy change"

canonical_cron_before="${test_root}/cron.before-canonical-firewall"
canonical_rules_before="${test_root}/rules.before-canonical-firewall"
canonical_snapshot_dir="${test_root}/firewall-canonical-snapshot"
canonical_persist_dir="${test_root}/firewall-canonical-persist"
command cp -- "${test_crontab}" "${canonical_cron_before}"
command cp -- "${firewall_dynamic_a}" "${test_rules}"
command cp -- "${test_rules}" "${canonical_rules_before}"
command cp -- "${firewall_dynamic_b}" "${test_iptables}"
mkdir -p -- "${canonical_persist_dir}"
kpanel_system_resource_firewall_persist "${canonical_persist_dir}" ||
	fail "firewall persist rejected a semantically identical dynamic capture"
cmp -s -- "${canonical_rules_before}" "${test_rules}" ||
	fail "firewall persist rewrote the raw rules snapshot for dynamic-only differences"

mkdir -p -- "${canonical_snapshot_dir}"
kpanel_system_resource_firewall_snapshot "${canonical_snapshot_dir}" "${test_rules}" ||
	fail "firewall raw snapshot failed"
cmp -s -- "${firewall_dynamic_b}" "${canonical_snapshot_dir}/iptables.rules" ||
	fail "firewall runtime snapshot was canonicalized instead of kept raw"
cmp -s -- "${canonical_rules_before}" "${canonical_snapshot_dir}/rules.v4" ||
	fail "firewall persisted snapshot was canonicalized instead of kept raw"
canonical_cron_existed="${KPANEL_SYSTEM_RESOURCE_FIREWALL_CRON_EXISTED}"
command cp -- "${firewall_rule_changed}" "${test_iptables}"
command cp -- "${firewall_rule_changed}" "${test_rules}"
command cp -- "${firewall_dynamic_a}" "${test_root}/iptables-restore-output"
kpanel_system_resource_firewall_restore \
	"${canonical_snapshot_dir}" "${test_rules}" true "${canonical_cron_existed}" ||
	fail "firewall restore rejected a semantically identical dynamic capture"
cmp -s -- "${firewall_dynamic_b}" "${test_root}/iptables-restore.last" ||
	fail "firewall restore input was canonicalized instead of kept raw"
cmp -s -- "${firewall_dynamic_a}" "${test_iptables}" ||
	fail "firewall restore fixture did not expose dynamic-only output"
cmp -s -- "${canonical_rules_before}" "${test_rules}" ||
	fail "firewall restore did not preserve the raw persisted rules snapshot"
command rm -f -- "${test_root}/iptables-restore-output" "${test_rules}"
command cp -- "${canonical_cron_before}" "${test_crontab}"

printf '%s\n' \
	'-P INPUT ACCEPT' \
	'-P FORWARD ACCEPT' \
	'-P OUTPUT ACCEPT' \
	'-N DOCKER-USER' \
	'-A DOCKER-USER -j RETURN' > "${test_iptables}"
firewall_v0="$(kpanel_system_resource_firewall_version)"
run_dispatch applied firewall open-port "${firewall_v0}" 443
[ "${RUN_RC}" -eq 0 ] || fail "firewall open-port failed"
grep -Fqx -- '-A INPUT -p tcp --dport 443 -j ACCEPT' "${test_iptables}" || fail "firewall TCP rule is missing"
grep -Fqx -- '-A INPUT -p udp --dport 443 -j ACCEPT' "${test_iptables}" || fail "firewall UDP rule is missing"
cmp -s -- "${test_iptables}" "${test_rules}" || fail "firewall rules were not persisted exactly"
[ "$(grep -Fxc '@reboot iptables-restore < /etc/iptables/rules.v4' "${test_crontab}")" -eq 1 ] || fail "firewall restore cron entry is not unique"
firewall_v1="$(kpanel_system_resource_firewall_version)"
run_dispatch unchanged firewall open-port "${firewall_v1}" 443
[ "${RUN_RC}" -eq 0 ] || fail "firewall idempotence failed"
run_dispatch conflict firewall close-port "${firewall_v0}" 443
[ "${RUN_RC}" -eq 2 ] || fail "stale firewall write did not return 2"
run_dispatch failed firewall allow-ip "${firewall_v1}" '2001:db8::1'
[ "${RUN_RC}" -eq 2 ] || fail "firewall accepted IPv6 without an ip6tables transaction"
run_dispatch failed firewall allow-ip "${firewall_v1}" '010.0.0.1'
[ "${RUN_RC}" -eq 2 ] || fail "firewall accepted an ambiguous leading-zero IPv4 address"

iptables_before="${test_root}/iptables.before-rollback"
rules_before="${test_root}/rules.before-rollback"
cron_before_firewall="${test_root}/cron.before-firewall-rollback"
command cp -- "${test_iptables}" "${iptables_before}"
command cp -- "${test_rules}" "${rules_before}"
command cp -- "${test_crontab}" "${cron_before_firewall}"
printf '3\n' > "${test_root}/iptables-save-countdown"
run_dispatch failed firewall close-port "${firewall_v1}" 443
[ "${RUN_RC}" -eq 1 ] || fail "firewall persistence rollback path did not return 1"
cmp -s -- "${iptables_before}" "${test_iptables}" || fail "firewall rollback did not restore runtime rules"
cmp -s -- "${rules_before}" "${test_rules}" || fail "firewall rollback did not restore persisted rules"
cmp -s -- "${cron_before_firewall}" "${test_crontab}" || fail "firewall rollback did not restore crontab"

firewall_v2="$(kpanel_system_resource_firewall_version)"
run_dispatch applied firewall enable-ddos "${firewall_v2}"
[ "${RUN_RC}" -eq 0 ] || fail "firewall enable-ddos failed"
mapfile -t docker_user_rules < <(grep -F -- '-A DOCKER-USER ' "${test_iptables}")
[ "${docker_user_rules[0]}" = '-A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT' ] || fail "DDoS TCP limit rule is not first"
[ "${docker_user_rules[1]}" = '-A DOCKER-USER -p tcp --syn -j DROP' ] || fail "DDoS TCP drop rule is not second"
[ "${docker_user_rules[2]}" = '-A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT' ] || fail "DDoS UDP limit rule is not third"
[ "${docker_user_rules[3]}" = '-A DOCKER-USER -p udp -j DROP' ] || fail "DDoS UDP drop rule is not fourth"
[ "${docker_user_rules[4]}" = '-A DOCKER-USER -j RETURN' ] || fail "DDoS rules were placed after DOCKER-USER RETURN"
firewall_v3="$(kpanel_system_resource_firewall_version)"
run_dispatch unchanged firewall enable-ddos "${firewall_v3}"
[ "${RUN_RC}" -eq 0 ] || fail "DDoS rule reconciliation is not idempotent"
firewall_v4="$(kpanel_system_resource_firewall_version)"
run_dispatch applied firewall enable-ping "${firewall_v4}"
[ "${RUN_RC}" -eq 0 ] || fail "firewall enable-ping failed"
grep -Fqx -- '-A INPUT -p icmp --icmp-type echo-request -j ACCEPT' "${test_iptables}" || fail "ping ACCEPT rule is missing"
firewall_v5="$(kpanel_system_resource_firewall_version)"
run_dispatch applied firewall disable-ping "${firewall_v5}"
[ "${RUN_RC}" -eq 0 ] || fail "firewall disable-ping failed"
grep -Fqx -- '-A INPUT -p icmp --icmp-type echo-request -j DROP' "${test_iptables}" || fail "ping DROP rule is missing"

printf '%s\n' "kpanel_system_resource_noninteractive_smoke=pass"
