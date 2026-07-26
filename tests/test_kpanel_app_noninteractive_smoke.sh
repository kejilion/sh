#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"

helper_body="$(
	awk '
		/^kpanel_run_docker_app_install\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
progress_body="$(
	awk '
		/^kpanel_app_progress\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
port_body="$(
	awk '
		/^kpanel_app_install_port\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
docker_app_body="$(
	awk '
		/^docker_app\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
docker_app_plus_body="$(
	awk '
		/^docker_app_plus\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"

printf '%s\n' "${helper_body}" | grep -F '[ "${KJ_APP_ACTION:-}" != "install" ]' >/dev/null
printf '%s\n' "${helper_body}" | grep -F 'kpanel_app_install_port || return 1' >/dev/null
printf '%s\n' "${helper_body}" | grep -F 'if ! docker_app_install; then' >/dev/null
printf '%s\n' "${helper_body}" | grep -F 'if ! docker_rum; then' >/dev/null
printf '%s\n' "${helper_body}" | grep -F 'echo "$docker_port" > "/home/docker/${docker_name}_port.conf"' >/dev/null
printf '%s\n' "${helper_body}" | grep -F 'kpanel_app_progress 100 "应用安装完成"' >/dev/null
printf '%s\n' "${docker_app_body}" | grep -F 'kpanel_run_docker_app_install standard' >/dev/null
printf '%s\n' "${docker_app_plus_body}" | grep -F 'kpanel_run_docker_app_install plus' >/dev/null
grep -F 'if [ "${KJ_APP_NONINTERACTIVE:-}" = "1" ]; then' "${script_path}" >/dev/null

test_app_root="$(mktemp -d)"
trap 'rm -rf "${test_app_root}"' EXIT
mkdir -p "${test_app_root}"
runtime_helpers="$(
	printf '%s\n%s\n%s\n' "${progress_body}" "${port_body}" "${helper_body}" |
		sed "s|/home/docker|${test_app_root}|g"
)"
eval "${runtime_helpers}"

setup_docker_dir() { return 0; }
check_disk_space() { return 0; }
install() { return 0; }
install_docker() { return 0; }
ss() { return 0; }
add_app_id() { printf '%s\n' "${app_id}" >>"${test_app_root}/appno.txt"; }
docker_app_install() { return 0; }
docker_rum() { return 0; }
show_user() { printf '%s\n' "user=admin"; }
show_pass() { printf '%s\n' "password=protected"; }

export KJ_APP_NONINTERACTIVE=1 KJ_APP_ACTION=install KJ_APP_PORT=18081
docker_name="test-standard"
docker_port=8080
app_id=999
app_size=1
docker_use=show_user
docker_passwd=show_pass
runtime_output="$(kpanel_run_docker_app_install standard)"
test "$(cat "${test_app_root}/test-standard_port.conf")" = "18081"
grep -qxF "999" "${test_app_root}/appno.txt"
printf '%s\n' "${runtime_output}" | grep -F "KPANEL_PROGRESS 5" >/dev/null
printf '%s\n' "${runtime_output}" | grep -F "KPANEL_PROGRESS 100" >/dev/null
printf '%s\n' "${runtime_output}" | grep -F "user=admin" >/dev/null
printf '%s\n' "${runtime_output}" | grep -F "password=protected" >/dev/null

docker_rum() { return 1; }
docker_name="test-failed"
app_id=998
if kpanel_run_docker_app_install standard >/dev/null 2>&1; then
	printf '%s\n' "failed installer was reported as successful" >&2
	exit 1
fi
test ! -e "${test_app_root}/test-failed_port.conf"
! grep -qxF "998" "${test_app_root}/appno.txt"

KJ_APP_PORT=0
if kpanel_app_install_port >/dev/null 2>&1; then
	printf '%s\n' "zero port was accepted" >&2
	exit 1
fi

printf '%s\n' "kpanel_app_noninteractive=pass"
