#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"

protocol_body="$(
	awk '
		/^kpanel_protocol_active\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
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
interactive_body="$(
	awk '
		/^kpanel_app_interactive_choice\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${script_path}"
)"
interactive_manage_body="$(
	awk '
		/^kpanel_app_interactive_manage_choice\(\) \{/ { capture=1 }
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
action_body="$(
	awk '
		/^kpanel_run_docker_app_action\(\) \{/ { capture=1 }
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
printf '%s\n' "${action_body}" | grep -F 'kpanel_app_verified_service true' >/dev/null
printf '%s\n' "${action_body}" | grep -F 'KJ_APP_ACCESS_MODE' >/dev/null
printf '%s\n' "${action_body}" | grep -F 'KJ_APP_RECONCILE_MARKER' >/dev/null
printf '%s\n' "${action_body}" | grep -F 'add_app_id || return 1' >/dev/null
printf '%s\n' "${docker_app_body}" | grep -F 'kpanel_run_docker_app_action standard' >/dev/null
printf '%s\n' "${docker_app_plus_body}" | grep -F 'kpanel_run_docker_app_action plus' >/dev/null
printf '%s\n' "${protocol_body}" | grep -F '[ "${KJ_APP_INTERACTIVE:-}" = "1" ]' >/dev/null
grep -F 'if [ "${KJ_APP_NONINTERACTIVE:-}" = "1" ]; then' "${script_path}" >/dev/null
grep -F 'if [ "${KJ_APP_INTERACTIVE:-}" = "1" ]; then' "${script_path}" >/dev/null
printf '%s\n' "${interactive_manage_body}" | grep -F 'KPanel 应用管理终端只接受菜单编号' >/dev/null
printf '%s\n' "${interactive_manage_body}" | grep -F 'KJ_APP_MARKER_RECOVERY' >/dev/null

eval "${interactive_manage_body}"
eval "${interactive_body}"
unset KJ_APP_INTERACTIVE KJ_APP_ACTION
choice=""
if kpanel_app_interactive_choice choice >/dev/null 2>&1; then
	printf '%s\n' "interactive helper accepted a normal SSH session" >&2
	exit 1
fi
export KJ_APP_INTERACTIVE=1 KJ_APP_ACTION=install
kpanel_app_interactive_choice choice
test "${choice}" = "1"
kpanel_app_verified_service() { return 0; }
export KJ_APP_ACTION=update
kpanel_app_interactive_choice choice
test "${choice}" = "2"
export KJ_APP_ACTION=uninstall
kpanel_app_interactive_choice choice
test "${choice}" = "3"
export KJ_APP_ACTION=manage
choice=""
kpanel_app_interactive_choice choice <<<'6'
test "${choice}" = "6"
recovery_verifications=0
kpanel_app_verified_service() {
	recovery_verifications=$((recovery_verifications + 1))
	return 1
}
export KJ_APP_MARKER_RECOVERY=1
kpanel_app_interactive_choice choice <<<'1'
test "${choice}" = "1"
test "${recovery_verifications}" = "0"
unset KJ_APP_MARKER_RECOVERY
if kpanel_app_interactive_choice choice <<<'1' >/dev/null 2>&1; then
	printf '%s\n' "interactive management bypassed container verification without recovery mode" >&2
	exit 1
fi
kpanel_app_verified_service() { return 0; }
if kpanel_app_interactive_choice choice <<<'invalid' >/dev/null 2>&1; then
	printf '%s\n' "interactive management accepted a non-menu input" >&2
	exit 1
fi
export KJ_APP_ACTION=direct_access KJ_APP_ACCESS_MODE=direct
kpanel_app_interactive_choice choice
test "${choice}" = "7"
export KJ_APP_ACCESS_MODE=domain_only
kpanel_app_interactive_choice choice
test "${choice}" = "8"
export KJ_APP_ACTION=unsupported
if kpanel_app_interactive_choice choice >/dev/null 2>&1; then
	printf '%s\n' "interactive helper accepted an unsupported action" >&2
	exit 1
fi
unset KJ_APP_INTERACTIVE KJ_APP_ACTION KJ_APP_ACCESS_MODE KJ_APP_MARKER_RECOVERY

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
kpanel_app_write_access_mode() { printf '%s\n' "$1" >"${test_app_root}/${docker_name}_access.conf"; }
kpanel_app_apply_access_mode() { kpanel_app_write_access_mode "$1"; }
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

management_helpers="$(
	for helper in \
		kpanel_app_service_name \
		kpanel_app_verified_service \
		kpanel_app_access_path \
		kpanel_app_read_access_mode \
		kpanel_app_write_access_mode \
		kpanel_app_apply_access_mode \
		kpanel_app_restore_access_mode \
		kpanel_app_remove_compatibility_state \
		kpanel_run_docker_app_action
	do
		awk -v helper="${helper}" '
			$0 ~ "^" helper "\\(\\) \\{" { capture=1 }
			capture { print }
			capture && /^}$/ { print ""; capture=0; exit }
		' "${script_path}"
	done | sed "s|/home/docker|${test_app_root}|g"
)"
eval "${management_helpers}"

current_exists=true
current_id="$(printf 'a%.0s' {1..64})"
updated_id="$(printf 'b%.0s' {1..64})"
docker_calls=()
docker_call_log="${test_app_root}/docker-calls.log"
docker() {
	docker_calls+=("$*")
	printf '%s\n' "$*" >>"${docker_call_log}"
	case "$1" in
		inspect)
			"${current_exists}" || return 1
			printf '%s\n' "${current_id}"
			;;
		ps)
			"${current_exists}" && printf '%s\n' "${docker_app_service:-$docker_name}"
			;;
		rm)
			current_exists=false
			;;
		rmi)
			return 0
			;;
	esac
}
docker_rum() {
	current_exists=true
	current_id="${updated_id}"
}
docker_app_update() {
	current_exists=true
	current_id="${updated_id}"
}
docker_app_uninstall() { current_exists=false; }
ip_address() { ipv4_address="192.0.2.10"; }
clear_container_rules() { return 0; }
block_container_port() { return 0; }
iptables() { return 0; }

docker_name="managed-standard"
docker_app_service=""
docker_img="example/managed:latest"
app_id=997
printf '%s\n' "${app_id}" >>"${test_app_root}/appno.txt"
test "$(kpanel_app_read_access_mode)" = "domain_only"
printf '%s\n' "domain_only" >"${test_app_root}/${docker_name}_access.conf"
export KJ_APP_ACTION=update
export KJ_APP_EXPECTED_CONTAINER_ID="${current_id}"
kpanel_run_docker_app_action standard >/dev/null
test "${current_exists}" = "true"
test "${current_id}" = "${updated_id}"
test "$(cat "${test_app_root}/${docker_name}_access.conf")" = "domain_only"

docker_name="managed-plus"
docker_app_service="managed-plus-web"
app_id=996
current_exists=true
current_id="$(printf 'c%.0s' {1..64})"
printf '%s\n' "${app_id}" >>"${test_app_root}/appno.txt"
printf '%s\n' "direct" >"${test_app_root}/${docker_name}_access.conf"
export KJ_APP_ACTION=update
export KJ_APP_EXPECTED_CONTAINER_ID="${current_id}"
kpanel_run_docker_app_action plus >/dev/null
test "${current_id}" = "${updated_id}"

current_id="$(printf 'd%.0s' {1..64})"
current_exists=true
export KJ_APP_ACTION=direct_access
export KJ_APP_ACCESS_MODE=domain_only
export KJ_APP_EXPECTED_CONTAINER_ID="${current_id}"
kpanel_run_docker_app_action plus >/dev/null
test "$(cat "${test_app_root}/${docker_name}_access.conf")" = "domain_only"

export KJ_APP_EXPECTED_CONTAINER_ID="$(printf 'e%.0s' {1..64})"
before_calls="$(wc -l <"${docker_call_log}")"
if kpanel_run_docker_app_action plus >/dev/null 2>&1; then
	printf '%s\n' "container identity mismatch was accepted" >&2
	exit 1
fi
test "$(wc -l <"${docker_call_log}")" -eq "$((before_calls + 1))"

export KJ_APP_ACTION=uninstall
export KJ_APP_EXPECTED_CONTAINER_ID="${current_id}"
kpanel_run_docker_app_action plus >/dev/null
test "${current_exists}" = "false"
test ! -e "${test_app_root}/${docker_name}_port.conf"
test ! -e "${test_app_root}/${docker_name}_access.conf"
! grep -qxF "${app_id}" "${test_app_root}/appno.txt"

printf '%s\n' "kpanel_app_noninteractive=pass"
