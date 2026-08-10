#!/usr/bin/env bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"
test_root="$(mktemp -d)"
trap 'rm -rf -- "${test_root}"' EXIT

fail() {
	echo "network-operations smoke failed: $*" >&2
	exit 1
}

adapter_file="${test_root}/adapter.sh"
{
	sed 's/\r$//' "${script_path}" | sed -n '/^# KPanel system resource protocol start$/,/^# KPanel system resource protocol end$/p'
	sed 's/\r$//' "${script_path}" | sed -n '/^# KPanel network operations protocol start$/,/^# KPanel network operations protocol end$/p'
} > "${adapter_file}"

grep -Fqx 'KPANEL_NETWORK_OPERATIONS_PROTOCOL_VERSION="1"' "${adapter_file}" ||
	fail "protocol v1 marker is missing"
[ "$(grep -Fxc 'KPANEL_NETWORK_OPERATIONS_PROTOCOL_VERSION="1"' "${adapter_file}")" -eq 1 ] ||
	fail "protocol v1 marker must be unique"

# shellcheck disable=SC1090
source "${adapter_file}"

unset KJ_NETWORK_OPERATIONS_NONINTERACTIVE || true
set +e
guard_output="$(kpanel_network_operations_dispatch port-usage list 2>/dev/null)"
guard_rc=$?
set -e
[ "${guard_rc}" -eq 2 ] || fail "protocol guard did not reject an unguarded call"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_STATUS=failed' <<< "${guard_output}" || fail "protocol guard receipt missing"

mock_bin="${test_root}/bin"
mkdir -p "${mock_bin}"
mock_crontab="${test_root}/crontab"
mock_ss="${test_root}/ss.output"
traffic_script="${test_root}/Limiting_Shut_down.sh"
net_dev="${test_root}/net.dev"
recovery_root="${test_root}/state"
export MOCK_CRONTAB="${mock_crontab}" MOCK_SS="${mock_ss}"
export MOCK_CRONTAB_FAIL_ONCE="${test_root}/crontab.fail-once"

cat > "${mock_bin}/crontab" <<'MOCK'
#!/usr/bin/env bash
set -euo pipefail
case "${1:-}" in
	-l)
		if [ -f "${MOCK_CRONTAB}" ]; then cat "${MOCK_CRONTAB}"; else echo "no crontab for root" >&2; exit 1; fi
		;;
	-r) rm -f -- "${MOCK_CRONTAB}" ;;
	'') exit 2 ;;
	*)
		if [ -e "${MOCK_CRONTAB_FAIL_ONCE}" ]; then rm -f -- "${MOCK_CRONTAB_FAIL_ONCE}"; exit 1; fi
		cp -- "$1" "${MOCK_CRONTAB}"
		;;
esac
MOCK
cat > "${mock_bin}/ss" <<'MOCK'
#!/usr/bin/env bash
cat "${MOCK_SS}"
MOCK
chmod +x "${mock_bin}/crontab" "${mock_bin}/ss"
PATH="${mock_bin}:${PATH}"

kpanel_network_operations_script_file() { printf '%s\n' "${traffic_script}"; }
kpanel_network_operations_net_dev_file() { printf '%s\n' "${net_dev}"; }
kpanel_system_resource_state_root() { printf '%s\n' "${recovery_root}"; }
kpanel_system_resource_lock_owner_uid() { id -u; }
kpanel_system_resource_tempdir() {
	local resource="$1" directory
	directory="$(mktemp -d "${test_root}/${resource}.XXXXXX")"
	chmod 700 "${directory}"
	printf '%s\n' "${directory}"
}
chown() { return 0; }
kpanel_network_operations_require() { return 0; }

{
	for index in $(seq 1 514); do
		printf 'tcp LISTEN 0 4096 127.0.0.1:%s 0.0.0.0:* users:(("demo",pid=%s,fd=3))\n' "$((8000 + index))" "$index"
	done
} > "${mock_ss}"

port_output="$(kpanel_network_operations_port_usage)"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_STATUS=ok' <<< "${port_output}" || fail "port list status missing"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_TOTAL=514' <<< "${port_output}" || fail "port total is wrong"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_TRUNCATED=true' <<< "${port_output}" || fail "port truncation missing"
[ "$(grep -Fc 'KPANEL_NETWORK_OPERATIONS_PORT_HEX=' <<< "${port_output}")" -eq 512 ] || fail "port list was not bounded"
first_hex="$(sed -n '0,/^KPANEL_NETWORK_OPERATIONS_PORT_HEX=/{s/^KPANEL_NETWORK_OPERATIONS_PORT_HEX=//p}' <<< "${port_output}")"
[ "$(printf '%s' "${first_hex}" | xxd -r -p)" = 'tcp LISTEN 0 4096 127.0.0.1:8001 0.0.0.0:* users:(("demo",pid=1,fd=3))' ] ||
	fail "port line encoding changed content"

cat > "${net_dev}" <<'NET'
Inter-|   Receive                                                |  Transmit
 face |bytes    packets errs drop fifo frame compressed multicast|bytes    packets errs drop fifo colls carrier compressed
  lo: 999 0 0 0 0 0 0 0 888 0 0 0 0 0 0 0
eth0: 1073741824 0 0 0 0 0 0 0 2147483648 0 0 0 0 0 0 0
NET
printf '15 4 * * * reboot --reason unrelated\n0 2 1 * * reboot\n' > "${mock_crontab}"

status_output="$(kpanel_network_operations_traffic_status)"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_HEALTH=disabled' <<< "${status_output}" || fail "disabled status is wrong"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_RX_BYTES=1073741824' <<< "${status_output}" || fail "rx counter is wrong"
version0="$(sed -n 's/^KPANEL_NETWORK_OPERATIONS_VERSION=//p' <<< "${status_output}")"

enable_output="$(kpanel_network_operations_traffic_action enable "${version0}" 100 200 5)"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_STATUS=applied' <<< "${enable_output}" || fail "enable was not applied"
grep -Fqx 'rx_threshold_gb=100' "${traffic_script}" || fail "rx threshold was not written"
grep -Fqx 'tx_threshold_gb=200' "${traffic_script}" || fail "tx threshold was not written"
grep -Fqx '15 4 * * * reboot --reason unrelated' "${mock_crontab}" || fail "unrelated reboot cron was deleted"
grep -Fqx '0 2 1 * * reboot' "${mock_crontab}" || fail "ambiguous legacy reboot cron was deleted"
grep -Fqx '0 1 5 * * reboot' "${mock_crontab}" || fail "managed reset cron is missing"

status_output="$(kpanel_network_operations_traffic_status)"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_HEALTH=ready' <<< "${status_output}" || fail "enabled status is not ready"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_RESET_DAY=5' <<< "${status_output}" || fail "reset day is wrong"
version1="$(sed -n 's/^KPANEL_NETWORK_OPERATIONS_VERSION=//p' <<< "${status_output}")"

set +e
conflict_output="$(kpanel_network_operations_traffic_action disable "${version0}" 2>/dev/null)"
conflict_rc=$?
set -e
[ "${conflict_rc}" -eq 2 ] || fail "stale write did not return conflict"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_STATUS=conflict' <<< "${conflict_output}" || fail "conflict receipt missing"

unchanged_output="$(kpanel_network_operations_traffic_action enable "${version1}" 100 200 5)"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_STATUS=unchanged' <<< "${unchanged_output}" || fail "idempotent enable changed state"
version1="$(sed -n 's/^KPANEL_NETWORK_OPERATIONS_VERSION=//p' <<< "${unchanged_output}")"

disable_output="$(kpanel_network_operations_traffic_action disable "${version1}")"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_STATUS=applied' <<< "${disable_output}" || fail "disable was not applied"
[ ! -e "${traffic_script}" ] || fail "managed script remains after disable"
grep -Fqx '15 4 * * * reboot --reason unrelated' "${mock_crontab}" || fail "disable deleted unrelated reboot cron"
grep -Fqx '0 2 1 * * reboot' "${mock_crontab}" || fail "disable deleted ambiguous reboot cron"
if grep -Fq 'kejilion traffic shutdown' "${mock_crontab}"; then fail "managed cron block remains after disable"; fi

version2="$(kpanel_network_operations_traffic_version)"
touch "${MOCK_CRONTAB_FAIL_ONCE}"
set +e
rollback_output="$(kpanel_network_operations_traffic_action enable "${version2}" 300 400 9 2>/dev/null)"
rollback_rc=$?
set -e
[ "${rollback_rc}" -eq 1 ] || fail "failed crontab install did not report a rolled-back failure"
grep -Fqx 'KPANEL_NETWORK_OPERATIONS_STATUS=failed' <<< "${rollback_output}" || fail "rollback receipt missing"
[ ! -e "${traffic_script}" ] || fail "failed enable did not roll back the managed script"
[ "$(kpanel_network_operations_traffic_version)" = "${version2}" ] || fail "failed enable did not restore the resource version"
grep -Fqx '15 4 * * * reboot --reason unrelated' "${mock_crontab}" || fail "rollback did not restore unrelated cron"

printf '%s\n' 'kpanel_network_operations_noninteractive_smoke=pass'
