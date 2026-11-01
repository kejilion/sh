#!/bin/bash
set -euo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
tmp="$(mktemp -d)"
trap 'rm -rf -- "$tmp"' EXIT

cat > "$tmp/upstream" <<'EOF'
#!/bin/bash
value="$1"
if [[ "$value" =~ ^[[:ascii:]]*$ ]]; then
	printf 'ascii:%s\n' "$value"
else
	status=$?
	[ "$status" = 1 ] || exit "$status"
	printf 'non-ascii:%s\n' "$value"
fi
read -r answer
printf 'input:%s arg:%s\n' "$answer" "$2"
exit "$3"
EOF

for script in "$root/kejilion.sh" "$root"/{cn,en,tw,jp,kr,ir,ru}/kejilion.sh; do
	bash -n "$script"
	awk '/^linuxmirrors_run_script\(\)/ { capture=1 } /^# Armbian can identify/ { capture=0 } capture { print }' "$script" > "$tmp/functions"
	. "$tmp/functions"
	printf 'hello\n' | linuxmirrors_run_script "$tmp/upstream" abc 'two words' 0 > "$tmp/out"
	grep -Fxq 'ascii:abc' "$tmp/out"
	grep -Fxq 'input:hello arg:two words' "$tmp/out"
	printf 'hello\n' | linuxmirrors_run_script "$tmp/upstream" '中文' x 0 > "$tmp/out"
	grep -Fxq 'non-ascii:中文' "$tmp/out"
	if printf 'hello\n' | linuxmirrors_run_script "$tmp/upstream" abc x 17 > /dev/null; then
		echo 'script failure was lost' >&2; exit 1
	else
		[ "$?" = 17 ]
	fi
	curl() { [ "$1" = -fsSL ] && [ "$3" = -o ] || return 1; cp "$tmp/upstream" "$4"; }
	printf 'hello\n' | linuxmirrors_run_url https://linuxmirrors.cn/main.sh abc 'two words' 0 > "$tmp/out"
	grep -Fxq 'input:hello arg:two words' "$tmp/out"
	curl() { return 22; }
	if linuxmirrors_run_url https://linuxmirrors.cn/docker.sh abc x 0; then
		echo 'download failure was lost' >&2; exit 1
	fi
	unset -f curl
	if grep -Eq 'bash <\(curl -sSL https://linuxmirrors.cn/(main|docker)\.sh\)' "$script"; then
		echo "unprotected LinuxMirrors entry in $script" >&2; exit 1
	fi
done

# KPanel verifies the original download before invoking the same compatibility
# wrapper. Exercise that call without changing a machine's package sources.
awk '/^kpanel_system_tuning_switch_mirror\(\)/ { capture=1 } capture { print } capture && /^}/ { exit }' "$root/kejilion.sh" > "$tmp/kpanel-function"
. "$tmp/kpanel-function"
cat > "$tmp/kpanel-upstream" <<'EOF'
#!/bin/bash
[[ abc =~ ^[[:ascii:]]*$ ]] || exit $?
printf '%s\n' "$@"
EOF
preserve_armbian_mirrors() { return 1; }
kpanel_system_tuning_download_verified() { cp "$tmp/kpanel-upstream" "$3"; }
kpanel_system_tuning_curl() { printf 'CN\n'; }
kpanel_system_tuning_run_command() { "$@"; }
gh_proxy='https://'
KPANEL_SYSTEM_TUNING_MIRROR_COMMIT=fixture
KPANEL_SYSTEM_TUNING_MIRROR_SHA256=fixture
kpanel_system_tuning_switch_mirror > "$tmp/out"
grep -Fxq 'mirrors.huaweicloud.com' "$tmp/out"
grep -Fxq -- '--pure-mode' "$tmp/out"
echo 'linuxmirrors_compat=pass'
