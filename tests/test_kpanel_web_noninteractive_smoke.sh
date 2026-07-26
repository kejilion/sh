#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"

bash -n "${script_path}"
grep -F 'if [ "${KJ_WEB_NONINTERACTIVE:-0}" = "1" ]; then' "${script_path}" >/dev/null
grep -F 'sub_choice="${KJ_WEB_RECIPE:-}"' "${script_path}" >/dev/null
grep -F 'yuming="${KJ_WEB_DOMAIN:-}"' "${script_path}" >/dev/null
grep -F '域名已存在，拒绝覆盖现有产物' "${script_path}" >/dev/null
grep -F 'docker exec nginx nginx -t' "${script_path}" >/dev/null
grep -F 'KPANEL_PROGRESS 100 kejilion.sh 原生建站产物已完成' "${script_path}" >/dev/null

# KPanel only exposes the fixed, audited one-click menu selectors.
recipe_case="$(
	awk '
		/sub_choice="\$\{KJ_WEB_RECIPE:-\}"/ { capture=1 }
		capture { print }
		capture && /不支持的 KJ_WEB_RECIPE/ { exit }
	' "${script_path}"
)"
for selector in 3 4 5 6 7 8 9 27; do
	printf '%s\n' "${recipe_case}" | grep -E "(^|[[:space:]|])${selector}([|)])" >/dev/null
done
if printf '%s\n' "${recipe_case}" | grep -E '(^|[[:space:]|])(20|22|23|24|29|30|34|38)([|)])' >/dev/null; then
	printf '%s\n' "unsafe or interactive recipe selector was exposed to KPanel" >&2
	exit 1
fi
