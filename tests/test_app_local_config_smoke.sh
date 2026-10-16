#!/bin/bash
set -euo pipefail

script_path=${1:-"$(cd "$(dirname "$0")/.." && pwd)/kejilion.sh"}
for helper in local_app_config_trusted resolve_app_config; do
	helper_body=$(
		awk -v name="$helper" '
			$0 ~ "^" name "\\(\\) \\{" { capture=1 }
			capture { print }
			capture && /^}/ { exit }
		' "$script_path"
	)
	[ -n "$helper_body" ]
	eval "$helper_body"
done

test_root=$(mktemp -d)
cleanup() {
	case "$test_root" in
		/tmp/*) rm -rf -- "$test_root" ;;
	esac
}
trap cleanup EXIT HUP INT TERM

export HOME="$test_root/home"
mkdir -p "$HOME/apps" "$HOME/apps-local"
gl_hong=
gl_bai=

printf 'local app_text="mine"\n' >"$HOME/apps-local/myapp.conf"
chmod 644 "$HOME/apps-local/myapp.conf"
[ "$(resolve_app_config myapp)" = "$HOME/apps-local/myapp.conf" ]

# 官方同名优先
printf 'local app_text="official"\n' >"$HOME/apps/myapp.conf"
[ "$(resolve_app_config myapp)" = "$HOME/apps/myapp.conf" ]
rm -f -- "$HOME/apps/myapp.conf"

# 组/他人可写拒绝并提示
chmod 666 "$HOME/apps-local/myapp.conf"
if resolve_app_config myapp >"$test_root/writable.out" 2>&1; then
	echo "accepted a group/world writable local config" >&2
	exit 1
fi
grep -F 'chmod 644' "$test_root/writable.out" >/dev/null
chmod 644 "$HOME/apps-local/myapp.conf"

# 软链接拒绝
ln -s "$HOME/apps-local/myapp.conf" "$HOME/apps-local/linked.conf"
if resolve_app_config linked >/dev/null 2>&1; then
	echo "accepted a symlinked local config" >&2
	exit 1
fi

# 非法名称拒绝
for name in "" "../myapp" ".hidden" "a/b"; do
	if local_app_config_trusted "$name"; then
		echo "accepted invalid local app name: $name" >&2
		exit 1
	fi
done

if resolve_app_config missing >/dev/null 2>&1; then
	echo "resolved a missing app" >&2
	exit 1
fi

# local: 前缀只解析 ~/apps-local，避开 b/r 等内置菜单别名
printf 'local app_text="restore-like"\n' >"$HOME/apps-local/r.conf"
chmod 644 "$HOME/apps-local/r.conf"
[ "$(resolve_app_config local:r)" = "$HOME/apps-local/r.conf" ]
printf 'local app_text="official"\n' >"$HOME/apps/shadow.conf"
cp "$HOME/apps-local/r.conf" "$HOME/apps-local/shadow.conf"
if resolve_app_config local:shadow >"$test_root/shadow.out" 2>&1; then
	echo "local: prefix bypassed an official config with the same name" >&2
	exit 1
fi
grep -F '与官方应用同名' "$test_root/shadow.out" >/dev/null
if resolve_app_config local:../apps/shadow >/dev/null 2>&1; then
	echo "local: prefix accepted a traversal name" >&2
	exit 1
fi

echo "app_local_config_smoke=pass"
