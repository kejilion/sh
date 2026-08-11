#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_script="${KEJILION_SCRIPT_PATH:-${project_root}/kejilion.sh}"
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
script_path="$temporary/kejilion.sh"
sed 's/\r$//' "$source_script" > "$script_path"

bash -n "$script_path"
grep -Fqx 'KPANEL_F2B_MANAGER_PROTOCOL_VERSION="1"' "$script_path"
[ "$(grep -Fxc 'KPANEL_F2B_MANAGER_PROTOCOL_VERSION="1"' "$script_path")" -eq 1 ]
grep -F 'kpanel_f2b_manager_dispatch "$@"' "$script_path" >/dev/null

functions="$({
	awk '
		/^kpanel_f2b_jail_name\(\) \{/ { capture=1 }
		/^f2b_sshd\(\) \{/ { exit }
		capture { print }
	' "$script_path"
})"
eval "$functions"

KPANEL_F2B_TEST_ROOT="$temporary/root"
mkdir -p "$KPANEL_F2B_TEST_ROOT/etc/fail2ban/jail.d" "$KPANEL_F2B_TEST_ROOT/var/log"
cat > "$KPANEL_F2B_TEST_ROOT/var/log/fail2ban.log" <<'EOF'
2026-08-11 01:02:03,000 fail2ban.filter [1]: INFO [sshd] Found 198.51.100.8 - 2026-08-11 01:02:03
2026-08-11 01:02:04,000 fail2ban.actions [1]: NOTICE [sshd] Ban 198.51.100.8
EOF

F2B_TEST_BANS="198.51.100.8 2001:db8::8"
F2B_TEST_DEFAULT_TRUSTED="127.0.0.1/8 ::1"
F2B_TEST_FAIL_VALIDATE=0
F2B_TEST_UNBAN_STICKY=0

kpanel_system_resource_zero_version() { printf '%064d\n' 0; }
kpanel_system_resource_valid_version() { [[ "$1" =~ ^[0-9a-f]{64}$ ]]; }
kpanel_system_resource_file_within_bounds() {
	[ "$(wc -c < "$1")" -le "$2" ] && [ "$(awk 'END { print NR + 0 }' "$1")" -le "$3" ]
}
kpanel_system_resource_tempdir() { mktemp -d "$temporary/$1.XXXXXX"; }
kpanel_system_resource_persist_recovery_snapshot() { printf '%s\n' "$1"; }
kpanel_f2b_autostart() { return 0; }
if [[ "${OSTYPE:-}" == msys* ]]; then
	python3() {
		local value="${*: -1}"
		case "$value" in 999.999.999.999|203.0.113.0/99|203.0.113.0/24) [[ "$*" == *ip_network* && "$value" = 203.0.113.0/24 ]] ;; *) return 0 ;; esac
	}
fi

managed_value() {
	local key="$1" fallback="$2" config="$KPANEL_F2B_TEST_ROOT/etc/fail2ban/jail.d/99-kejilion-sshd.local" value
	value="$(awk -F= -v key="$key" '$1 ~ "^[[:space:]]*" key "[[:space:]]*$" { gsub(/[[:space:]]/, "", $2); print $2; exit }' "$config" 2>/dev/null || true)"
	printf '%s\n' "${value:-$fallback}"
}

fail2ban-client() {
	case "${1:-}" in
		ping) return 0 ;;
		status)
			printf '%s\n' \
				"Status for the jail: sshd" \
				"|- Filter" \
				"|  |- Currently failed: 1" \
				"|  |- Total failed: 12" \
				"|- Actions" \
				"   |- Currently banned: $(wc -w <<< "$F2B_TEST_BANS")" \
				"   |- Total banned: 4" \
				"   \\- Banned IP list: $F2B_TEST_BANS"
			;;
		get)
			case "${3:-}" in
				bantime) managed_value bantime 3600 ;;
				findtime) managed_value findtime 600 ;;
				maxretry) managed_value maxretry 5 ;;
				ignoreip)
					local config="$KPANEL_F2B_TEST_ROOT/etc/fail2ban/jail.d/99-kejilion-sshd.local" value
					value="$(awk -F= '/^[[:space:]]*ignoreip[[:space:]]*=/{sub(/^[^=]*=[[:space:]]*/, ""); print; exit}' "$config" 2>/dev/null || true)"
					printf '%s\n' "${value:-$F2B_TEST_DEFAULT_TRUSTED}"
					;;
			esac
			;;
		set)
			local ip="${6:-${5:-}}"
			[ "$F2B_TEST_UNBAN_STICKY" -eq 1 ] || F2B_TEST_BANS="$(for value in $F2B_TEST_BANS; do [ "$value" = "$ip" ] || printf '%s ' "$value"; done)"
			;;
		-t)
			if [ "$F2B_TEST_FAIL_VALIDATE" -gt 0 ]; then
				F2B_TEST_FAIL_VALIDATE=$((F2B_TEST_FAIL_VALIDATE - 1))
				return 1
			fi
			return 0
			;;
		reload) return 0 ;;
	esac
}

status_output="$(kpanel_f2b_dispatch manager status)"
grep -F 'KPANEL_F2B_PROTOCOL 1' <<< "$status_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_PROTOCOL 1' <<< "$status_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_STATUS=ok' <<< "$status_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_PROFILE=standard' <<< "$status_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_CURRENT_FAILED=1' <<< "$status_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_BAN=198.51.100.8' <<< "$status_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_TRUSTED=127.0.0.1/8' <<< "$status_output" >/dev/null
[ "$(grep -c '^KPANEL_F2B_MANAGER_EVENT_HEX=' <<< "$status_output")" -eq 2 ]
! kpanel_f2b_manager_valid_address '999.999.999.999'
! kpanel_f2b_manager_valid_address '203.0.113.0/99'
! kpanel_f2b_manager_valid_ip '203.0.113.0/24'

version="$(grep '^KPANEL_F2B_MANAGER_VERSION=' <<< "$status_output" | cut -d= -f2)"
profile_output="$(kpanel_f2b_manager_config_action set-profile "$version" strict)"
grep -F 'KPANEL_F2B_MANAGER_STATUS=applied' <<< "$profile_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_PROFILE=strict' <<< "$profile_output" >/dev/null
grep -F 'bantime = 43200' "$KPANEL_F2B_TEST_ROOT/etc/fail2ban/jail.d/99-kejilion-sshd.local" >/dev/null

version="$(grep '^KPANEL_F2B_MANAGER_VERSION=' <<< "$profile_output" | cut -d= -f2)"
trusted_output="$(kpanel_f2b_manager_config_action add-trusted "$version" 203.0.113.0/24)"
grep -F 'KPANEL_F2B_MANAGER_STATUS=applied' <<< "$trusted_output" >/dev/null
grep -F 'KPANEL_F2B_MANAGER_TRUSTED=203.0.113.0/24' <<< "$trusted_output" >/dev/null

version="$(grep '^KPANEL_F2B_MANAGER_VERSION=' <<< "$trusted_output" | cut -d= -f2)"
unban_output="$(kpanel_f2b_manager_unban_action "$version" 198.51.100.8)"
grep -F 'KPANEL_F2B_MANAGER_STATUS=applied' <<< "$unban_output" >/dev/null
! grep -F 'KPANEL_F2B_MANAGER_BAN=198.51.100.8' <<< "$unban_output" >/dev/null

F2B_TEST_UNBAN_STICKY=1
version="$(grep '^KPANEL_F2B_MANAGER_VERSION=' <<< "$unban_output" | cut -d= -f2)"
if kpanel_f2b_manager_unban_action "$version" 2001:db8::8 > "$temporary/unban-failure.out" 2>/dev/null; then
	echo "unban readback mismatch unexpectedly succeeded" >&2
	exit 1
fi
grep -F 'KPANEL_F2B_MANAGER_STATUS=needs-attention' "$temporary/unban-failure.out" >/dev/null
F2B_TEST_UNBAN_STICKY=0

config="$KPANEL_F2B_TEST_ROOT/etc/fail2ban/jail.d/99-kejilion-sshd.local"
before_hash="$(sha256sum "$config" | awk '{print $1}')"
version="$(grep '^KPANEL_F2B_MANAGER_VERSION=' <<< "$unban_output" | cut -d= -f2)"
F2B_TEST_FAIL_VALIDATE=1
if kpanel_f2b_manager_config_action set-profile "$version" mild > "$temporary/failure.out" 2>/dev/null; then
	echo "invalid configuration unexpectedly succeeded" >&2
	exit 1
fi
grep -F 'KPANEL_F2B_MANAGER_STATUS=failed' "$temporary/failure.out" >/dev/null
[ "$(sha256sum "$config" | awk '{print $1}')" = "$before_hash" ]

printf '%s\n' "kpanel_f2b_manager_noninteractive_smoke=pass"
