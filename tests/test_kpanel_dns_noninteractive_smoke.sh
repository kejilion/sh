#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_script="${KEJILION_SCRIPT_PATH:-${project_root}/kejilion.sh}"
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
script_path="$temporary/kejilion.sh"
sed 's/\r$//' "$source_script" > "$script_path"

bash -n "${script_path}"
grep -F 'kpanel_set_dns_noninteractive() {' "${script_path}" >/dev/null
grep -F 'kpanel_protocol_active() {' "${script_path}" >/dev/null
grep -F 'if ! kpanel_protocol_active; then' "${script_path}" >/dev/null
grep -F '[ "${KJ_DNS_NONINTERACTIVE:-}" = "1" ] || return 2' "${script_path}" >/dev/null
grep -F 'KPANEL_DNS_MANAGER systemd-resolved' "${script_path}" >/dev/null
grep -F 'KPANEL_DNS_MANAGER resolv.conf' "${script_path}" >/dev/null
grep -F 'KPANEL_DNS_RESULT applied' "${script_path}" >/dev/null
grep -F 'KPANEL_DNS_RESULT unchanged' "${script_path}" >/dev/null
grep -F 'kpanel_dns_restore_file "$target" "$backup" "$existed" "$old_immutable"' "${script_path}" >/dev/null
grep -F 'systemctl reload-or-restart systemd-resolved.service' "${script_path}" >/dev/null
grep -F 'kpanel_set_dns_noninteractive "$@"' "${script_path}" >/dev/null

validator_body="$(
	awk '
		/^kpanel_dns_is_ipv4\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { completed++ }
		capture && completed == 2 { exit }
	' "${script_path}"
)"
eval "${validator_body}"

kpanel_dns_is_ipv4 "1.1.1.1"
kpanel_dns_is_ipv4 "255.255.255.255"
if kpanel_dns_is_ipv4 "256.1.1.1" || kpanel_dns_is_ipv4 "1.1.1"; then
	echo "DNS IPv4 validator accepted an invalid address" >&2
	exit 1
fi
kpanel_dns_is_ipv6 "2606:4700:4700::1111"
if kpanel_dns_is_ipv6 "not-an-ip"; then
	echo "DNS IPv6 validator accepted an invalid address" >&2
	exit 1
fi

protocol_guard_body="$(
	awk '
		/^kpanel_protocol_active\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
eval "${protocol_guard_body}"
KJ_DNS_NONINTERACTIVE=1
kpanel_protocol_active
unset KJ_DNS_NONINTERACTIVE
if kpanel_protocol_active; then
	echo "KPanel protocol guard activated without a protocol environment variable" >&2
	exit 1
fi

dns_writer_body="$(
	awk '
		/^kpanel_dns_restore_file\(\) \{/ { capture=1 }
		/^kpanel_dns_write_systemd_resolved\(\) \{/ { exit }
		capture { print }
	' "${script_path}" | sed 's#local target="/etc/resolv.conf"#local target="$KPANEL_DNS_TEST_TARGET"#'
)"
eval "$dns_writer_body"
KPANEL_DNS_TEST_TARGET="$temporary/resolv.conf"
printf 'nameserver 9.9.9.9\n' > "$KPANEL_DNS_TEST_TARGET"
chattr() { return 1; }
lsattr() { return 1; }
mv() { return 1; }
dns_result="$(kpanel_dns_write_static 1.1.1.1 8.8.8.8)"
grep -F 'KPANEL_DNS_RESULT applied' <<< "$dns_result" >/dev/null
[ "$(cat "$KPANEL_DNS_TEST_TARGET")"$'\n' = $'nameserver 1.1.1.1\nnameserver 8.8.8.8\n' ]
dns_result="$(kpanel_dns_write_static 1.1.1.1 8.8.8.8)"
grep -F 'KPANEL_DNS_RESULT unchanged' <<< "$dns_result" >/dev/null

printf '%s\n' "kpanel_dns_noninteractive_smoke=pass"
