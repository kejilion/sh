#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${project_root}/kejilion.sh"

bash -n "${script_path}"
grep -F 'if [ "${KJ_WEB_NONINTERACTIVE:-0}" = "1" ]; then' "${script_path}" >/dev/null
grep -F 'kpanel_web_interactive()' "${script_path}" >/dev/null
grep -F '! kpanel_web_interactive; then' "${script_path}" >/dev/null
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
for selector in 2 3 4 5 6 7 8 9 20 22 23 24 25 26 27 28 30; do
	printf '%s\n' "${recipe_case}" | grep -E "(^|[[:space:]|])${selector}([|)])" >/dev/null
done
if printf '%s\n' "${recipe_case}" | grep -E '(^|[[:space:]|])(21|29|31|32|33|34|35|36|37|38)([|)])' >/dev/null; then
	printf '%s\n' "unsafe or interactive recipe selector was exposed to KPanel" >&2
	exit 1
fi

grep -F 'ldnmp_wp "${KJ_WEB_DOMAIN:-}"' "${script_path}" >/dev/null
grep -F 'ldnmp_Proxy "${KJ_WEB_DOMAIN:-}" "${KJ_WEB_PROXY_HOST:-}" "${KJ_WEB_PROXY_PORT:-}"' "${script_path}" >/dev/null
grep -F 'KJ_WEB_PROXY_HOST 不是有效的 IP 或主机名' "${script_path}" >/dev/null
grep -F 'KJ_WEB_PROXY_PORT 不是有效端口' "${script_path}" >/dev/null
grep -F 'kpanel_web_recipe_requires_document_root()' "${script_path}" >/dev/null
grep -F 'if kpanel_web_recipe_requires_document_root "$sub_choice" &&' "${script_path}" >/dev/null
grep -F 'web_del "$@"' "${script_path}" >/dev/null
grep -F 'KPANEL_DELETE_SITE deleted $yuming' "${script_path}" >/dev/null
grep -F 'KPANEL_DELETE_DATABASE dropped $yuming' "${script_path}" >/dev/null
grep -F 'rm -rf -- "/home/web/html/$yuming"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli()' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 3 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 27 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 20 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 22 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 24 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 25 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 26 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 28 "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_web_recipe_cli 30 "$@"' "${script_path}" >/dev/null
grep -F 'ldnmp_wp "$@"' "${script_path}" >/dev/null
grep -F 'ldnmp_Proxy "$@"' "${script_path}" >/dev/null
