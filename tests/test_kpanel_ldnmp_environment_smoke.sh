#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"

bash -n "${script_path}"

for function_name in \
	ldnmp_environment_status \
	ldnmp_environment_catalog \
	ldnmp_environment_install \
	ldnmp_protection_action \
	ldnmp_optimization_mode \
	ldnmp_optimization_action \
	ldnmp_update_action \
	ldnmp_backup_action \
	ldnmp_backup_delete_action \
	ldnmp_restore_action \
	ldnmp_uninstall_action \
	ldnmp_environment_menu \
	kpanel_ldnmp_dispatch; do
	grep -F "${function_name}() {" "${script_path}" >/dev/null
done

grep -F '[ "${KJ_LDNMP_NONINTERACTIVE:-}" = "1" ] ||' "${script_path}" >/dev/null
grep -F 'KPANEL_LDNMP_PROTOCOL 1' "${script_path}" >/dev/null
grep -F 'KPANEL_LDNMP_EVENT {' "${script_path}" >/dev/null
grep -F 'KPANEL_LDNMP_RESULT %s' "${script_path}" >/dev/null
grep -F '/var/lib/kejilion-panel/environment-jobs/*.receipt)' "${script_path}" >/dev/null
grep -F "grep -Eq '^web_[0-9]{14}\\.tar\\.gz$'" "${script_path}" >/dev/null
grep -F 'docker compose -f "$stage/web/docker-compose.yml" config -q' "${script_path}" >/dev/null
grep -F 'kpanel_ldnmp_dispatch "$@"' "${script_path}" >/dev/null
grep -F '/run/lock/kejilion-web-environment.lock' "${script_path}" >/dev/null
grep -F 'kpanel_ldnmp_run backup.delete ldnmp_backup_delete_action "$@"' "${script_path}" >/dev/null
grep -F 'ldnmp_optimization_mode standard' "${script_path}" >/dev/null
grep -F 'ldnmp_optimization_mode high' "${script_path}" >/dev/null
grep -F 'ldnmp_backup_action || return 1' "${script_path}" >/dev/null
grep -F 'ldnmp_environment_menu' "${script_path}" >/dev/null
grep -F '/var/lib/kejilion-panel/environment-jobs/*.secret)' "${script_path}" >/dev/null
grep -F 'cloudflare-fail2ban|cloudflare-shield)' "${script_path}" >/dev/null
grep -F 'rm -f -- "$KJ_LDNMP_SECRET_FILE"' "${script_path}" >/dev/null

# The original k web menu remains present and keeps its established selectors.
for menu_line in \
	'1.   ${gl_bai}安装LDNMP环境' \
	'32.  ${gl_bai}备份全站数据' \
	'34.  ${gl_bai}还原全站数据' \
	'37.  ${gl_bai}更新LDNMP环境' \
	'38.  ${gl_bai}卸载LDNMP环境'; do
	grep -F "${menu_line}" "${script_path}" >/dev/null
done

protocol_guard_body="$(
	awk '
		/^kpanel_protocol_active\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
eval "${protocol_guard_body}"
KJ_LDNMP_NONINTERACTIVE=1
kpanel_protocol_active

printf '%s\n' "kpanel_ldnmp_environment_smoke=pass"
