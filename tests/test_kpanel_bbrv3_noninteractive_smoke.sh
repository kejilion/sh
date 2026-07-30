#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${KEJILION_SCRIPT_PATH:-${project_root}/kejilion.sh}"

bash -n "${script_path}"

for function_name in \
	kpanel_bbrv3_status \
	kpanel_bbrv3_dispatch \
	bbrv3; do
	grep -F "${function_name}() {" "${script_path}" >/dev/null
done

grep -F '[ "${KJ_BBRV3_NONINTERACTIVE:-}" = "1" ] ||' "${script_path}" >/dev/null
grep -F 'KPANEL_BBRV3_PROTOCOL 1' "${script_path}" >/dev/null
grep -F 'KPANEL_BBRV3_STATUS {' "${script_path}" >/dev/null
grep -F 'KPANEL_BBRV3_RESULT {' "${script_path}" >/dev/null
grep -F 'printf '\''%s'\'' "$status_line" | grep -q '\''"rebootRequired":true'\''' "${script_path}" >/dev/null
grep -F 'kpanel_bbrv3_dispatch "$@"' "${script_path}" >/dev/null
grep -F '[ "${KJ_BBRV3_NONINTERACTIVE:-}" = "1" ] || server_reboot' "${script_path}" >/dev/null

# The legacy command without the protocol environment must remain interactive.
grep -F 'send_stats "bbrv3管理"' "${script_path}" >/dev/null
grep -F '1. 更新BBRv3内核' "${script_path}" >/dev/null
grep -F '确定继续吗？(Y/N)' "${script_path}" >/dev/null
grep -F 'bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)' "${script_path}" >/dev/null

status_output="$(
	KJ_BBRV3_NONINTERACTIVE=1 \
		LC_ALL=C.UTF-8 \
		LANG=C.UTF-8 \
		bash "${script_path}" bbrv3 status
)"
grep -Fx 'KPANEL_BBRV3_PROTOCOL 1' <<<"${status_output}" >/dev/null
grep -F 'KPANEL_BBRV3_STATUS {"supported":' <<<"${status_output}" >/dev/null
grep -F '"installed":' <<<"${status_output}" >/dev/null
grep -F '"runningKernel":"' <<<"${status_output}" >/dev/null
grep -F '"installedKernel":"' <<<"${status_output}" >/dev/null
grep -F '"rebootRequired":' <<<"${status_output}" >/dev/null

if KJ_BBRV3_NONINTERACTIVE=1 bash "${script_path}" bbrv3 arbitrary >/dev/null 2>&1; then
	echo "unknown BBRv3 action was accepted" >&2
	exit 1
fi

printf '%s\n' "kpanel_bbrv3_noninteractive_smoke=pass"
