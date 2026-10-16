#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${1:-${project_root}/kejilion.sh}"
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/home/apps"

# Exercise the entire production dispatcher in a child shell without errexit:
# a failing app must survive the case and protocol checks as its process status.
awk '/^local_app_config_trusted\(\) \{/ { capture=1 } /^linux_work\(\) \{/ { exit } capture { print }' "$script_path" > "$test_root/dispatcher.sh"
test -s "$test_root/dispatcher.sh"
cat > "$test_root/home/apps/standard.conf" <<'EOF'
docker_app
EOF
cat > "$test_root/home/apps/plus.conf" <<'EOF'
docker_app_plus
EOF
cat > "$test_root/home/apps/custom.conf" <<'EOF'
return "${APP_STATUS}"
EOF
cat > "$test_root/run.sh" <<'EOF'
source "$1/dispatcher.sh"
export HOME="$1/home"
clear() { :; }
refresh_apps_catalog() { return "${REFRESH_STATUS:-0}"; }
docker_app() { return "$APP_STATUS"; }
docker_app_plus() { return "$APP_STATUS"; }
break_end() { exit 29; }
linux_panel "$2"
EOF

check() {
	local mode=$1 selector=$2 status=$3 expected=$4 refresh=${5:-0} actual=0
	env KJ_APP_NONINTERACTIVE="$([[ $mode == noninteractive ]] && echo 1 || echo 0)" \
		KJ_APP_INTERACTIVE="$([[ $mode == interactive ]] && echo 1 || echo 0)" \
		APP_STATUS="$status" REFRESH_STATUS="$refresh" \
		bash "$test_root/run.sh" "$test_root" "$selector" > "$test_root/output" 2>&1 || actual=$?
	if [[ $actual != "$expected" ]]; then
		cat "$test_root/output" >&2
		echo "$mode/$selector/app=$status/refresh=$refresh: expected $expected, got $actual" >&2
		exit 1
	fi
}
for mode in noninteractive interactive; do
	for selector in standard plus custom; do
		for status in 0 1 37; do
			check "$mode" "$selector" "$status" "$status"
		done
	done
	check "$mode" standard 0 1 1
done
# Ordinary SSH sessions still return to the existing menu pause after an action.
check ssh standard 0 29
check ssh standard 1 29
echo app_dispatch_exit_status_smoke=pass
