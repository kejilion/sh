#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for script_path in "${project_root}/kejilion.sh" "${project_root}/cn/kejilion.sh"; do
	menu_body="$(
		awk '
			/^kejilion_sh\(\) \{/ { capture=1 }
			capture { print }
			capture && /^}$/ { exit }
		' "${script_path}"
	)"

	grep -F 'grep -qxF "kpanel" /home/docker/appno.txt 2>/dev/null' <<<"${menu_body}" >/dev/null
	grep -F '17.  ${gl_bai}KPanel Web管理面板 ${kpanel_menu_status}' <<<"${menu_body}" >/dev/null
	grep -F 'kejilion.sh 的现代化网页管理界面' <<<"${menu_body}" >/dev/null
	grep -F '17) linux_panel kpanel ;;' <<<"${menu_body}" >/dev/null
	grep -F 'KPanel管理          k app kpanel' "${script_path}" >/dev/null
done

printf '%s\n' 'PASS: KPanel main-menu shortcut smoke tests'
