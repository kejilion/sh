#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"
function_body="$(
	awk '
		/^docker_app_plus\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"

printf '%s\n' "${function_body}" | grep -F 'if docker_app_install; then' >/dev/null
printf '%s\n' "${function_body}" | grep -F 'if docker_app_update; then' >/dev/null
printf '%s\n' "${function_body}" | grep -F 'if docker_app_uninstall; then' >/dev/null

install_branch="$(printf '%s\n' "${function_body}" | sed -n '/if docker_app_install; then/,/^[[:space:]]*fi$/p')"
update_branch="$(printf '%s\n' "${function_body}" | sed -n '/if docker_app_update; then/,/^[[:space:]]*fi$/p')"
uninstall_branch="$(printf '%s\n' "${function_body}" | sed -n '/if docker_app_uninstall; then/,/^[[:space:]]*fi$/p')"

printf '%s\n' "${install_branch}" |
	grep -F 'echo "$docker_port" > "/home/docker/${docker_name}_port.conf"' >/dev/null
printf '%s\n' "${install_branch}" | grep -F 'add_app_id' >/dev/null
printf '%s\n' "${update_branch}" | grep -F 'add_app_id' >/dev/null
printf '%s\n' "${uninstall_branch}" | grep -F 'rm -f /home/docker/${docker_name}_port.conf' >/dev/null
printf '%s\n' "${uninstall_branch}" | grep -F 'appno.txt' >/dev/null

printf '%s\n' "docker_app_plus_lifecycle_status=pass"
