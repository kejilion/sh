#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_paths=("${project_root}/kejilion.sh" "${project_root}/cn/kejilion.sh")
reference_adapter=""

for script_path in "${script_paths[@]}"; do
	bash -n "${script_path}"
	grep -F 'if ! kpanel_protocol_active; then' "${script_path}" >/dev/null
	grep -F 'kpanel_ssh_port_noninteractive() {' "${script_path}" >/dev/null
	grep -F '[ "${KJ_SSH_PORT_NONINTERACTIVE:-}" = "1" ] || return 2' "${script_path}" >/dev/null
	grep -F 'new_ssh_port "$new_port" || return 1' "${script_path}" >/dev/null
	grep -F 'ss -H -ltn' "${script_path}" >/dev/null
	grep -F '错误: SSH 新端口未进入监听状态' "${script_path}" >/dev/null
	grep -F 'KPANEL_SSH_RESULT applied' "${script_path}" >/dev/null
	grep -F 'KPANEL_SSH_RESULT unchanged' "${script_path}" >/dev/null
	grep -F 'KPANEL_SSH_PORT $new_port' "${script_path}" >/dev/null
	grep -F 'kpanel_ssh_port_noninteractive "$@"' "${script_path}" >/dev/null

	# KPanel 入口只能包装现有主业务，不能复制或改写 new_ssh_port。
	test "$(grep -c '^new_ssh_port() {' "${script_path}")" -eq 1
	adapter_body="$({
		awk '
			/^kpanel_ssh_port_noninteractive\(\) \{/ { capture=1 }
			capture { print }
			capture && /^}$/ { exit }
		' "${script_path}"
	})"
	grep -F 'new_ssh_port "$new_port"' <<<"${adapter_body}" >/dev/null
	if grep -Eq 'sed -i|rm -rf /etc/ssh|systemctl (reload|restart)' <<<"${adapter_body}"; then
		echo "SSH adapter duplicated the existing SSH mutation logic in ${script_path}" >&2
		exit 1
	fi
	if [ -z "${reference_adapter}" ]; then
		reference_adapter="${adapter_body}"
	elif [ "${adapter_body}" != "${reference_adapter}" ]; then
		echo "SSH adapters are not synchronized: ${script_path}" >&2
		exit 1
	fi

	protocol_guard_body="$({
		awk '
			/^kpanel_protocol_active\(\) \{/ { capture=1 }
			capture { print }
			capture && /^}$/ { exit }
		' "${script_path}"
	})"
	eval "${protocol_guard_body}"
	KJ_SSH_PORT_NONINTERACTIVE=1
	kpanel_protocol_active
	unset KJ_SSH_PORT_NONINTERACTIVE
done

printf '%s\n' "kpanel_ssh_port_noninteractive_smoke=pass"
