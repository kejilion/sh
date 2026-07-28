#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${KEJILION_SCRIPT_PATH:-${project_root}/kejilion.sh}"

bash -n "${script_path}"

for function_name in \
	kpanel_f2b_jail_name \
	kpanel_f2b_enabled \
	kpanel_f2b_autostart \
	kpanel_f2b_status \
	kpanel_f2b_dispatch; do
	grep -F "${function_name}() {" "${script_path}" >/dev/null
done

grep -F '[ "${KJ_F2B_NONINTERACTIVE:-}" = "1" ] ||' "${script_path}" >/dev/null
grep -F 'KPANEL_F2B_PROTOCOL 1' "${script_path}" >/dev/null
grep -F 'KPANEL_F2B_STATUS {' "${script_path}" >/dev/null
grep -F 'KPANEL_F2B_RESULT %s' "${script_path}" >/dev/null
grep -F 'kpanel_f2b_dispatch "$@"' "${script_path}" >/dev/null
grep -F '/bin/systemctl disable --now fail2ban.service' "${script_path}" >/dev/null

# The original bare `k f2b` path must remain an interactive menu.
grep -F 'fail2ban_panel' "${script_path}" >/dev/null
grep -F '1. 安装防御程序' "${script_path}" >/dev/null
grep -F '9. 卸载防御程序' "${script_path}" >/dev/null

protocol_guard_body="$(
	awk '
		/^kpanel_protocol_active\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
eval "${protocol_guard_body}"
KJ_F2B_NONINTERACTIVE=1
kpanel_protocol_active

status_functions="$(
	awk '
		/^kpanel_f2b_jail_name\(\) \{/ { capture=1 }
		/^f2b_sshd\(\) \{/ { exit }
		capture { print }
	' "${script_path}"
)"
eval "${status_functions}"
fail2ban-client() {
	case "${1:-}" in
		ping) return 0 ;;
		status)
			printf '%s\n' \
				"Status for the jail: sshd" \
				"|  Currently banned: 2"
			;;
	esac
}
status_output="$(kpanel_f2b_status)"
grep -F '"installed":true' <<<"${status_output}" >/dev/null
grep -F '"running":true' <<<"${status_output}" >/dev/null
grep -F '"enabled":true' <<<"${status_output}" >/dev/null
grep -F '"jail":"sshd"' <<<"${status_output}" >/dev/null
grep -F '"banned":2' <<<"${status_output}" >/dev/null

printf '%s\n' "kpanel_f2b_noninteractive_smoke=pass"
