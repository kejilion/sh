#!/bin/bash
set -euo pipefail

script_path=${1:-"$(cd "$(dirname "$0")/.." && pwd)/kejilion.sh"}
helper_body=$(
	awk '
		/^refresh_apps_catalog\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}/ { exit }
	' "$script_path"
)
[ -n "$helper_body" ]
eval "$helper_body"

test_root=$(mktemp -d)
cleanup() {
	case "$test_root" in
		/tmp/*) rm -rf -- "$test_root" ;;
	esac
}
trap cleanup EXIT HUP INT TERM

export HOME="$test_root/home"
mkdir -p "$HOME"
git_log="$test_root/git.log"
: >"$git_log"
gh_proxy=
gl_hong=
gl_bai=

install() {
	[ "$1" = git ]
}

timeout() {
	[ "$1" = 30s ]
	shift
	"$@"
}

git() {
	printf '%s\n' "$*" >>"$git_log"
	case "$1" in
		clone)
			destination=${4:?missing clone destination}
			mkdir -p "$destination/.git"
			;;
		-C)
			[ "${GIT_PULL_FAIL:-0}" != 1 ]
			;;
		*)
			return 1
			;;
	esac
}

refresh_apps_catalog
test -d "$HOME/apps/.git"
grep -Fx 'clone --depth=1 github.com/kejilion/apps.git '"$HOME"'/apps' "$git_log" >/dev/null

: >"$git_log"
refresh_apps_catalog
grep -Fx -- '-C '"$HOME"'/apps pull --ff-only github.com/kejilion/apps.git main' "$git_log" >/dev/null

if GIT_PULL_FAIL=1 refresh_apps_catalog >"$test_root/pull-failure.out" 2>&1; then
	echo "catalog refresh accepted a failed fast-forward pull" >&2
	exit 1
fi
grep -F '拒绝继续使用可能过期的配置' "$test_root/pull-failure.out" >/dev/null

rm -rf -- "$HOME/apps"
mkdir -p "$HOME/apps"
if refresh_apps_catalog >"$test_root/non-git.out" 2>&1; then
	echo "catalog refresh accepted an existing non-Git directory" >&2
	exit 1
fi
grep -F '已存在但不是应用市场 Git 仓库' "$test_root/non-git.out" >/dev/null

echo "app_catalog_refresh_smoke=pass"
