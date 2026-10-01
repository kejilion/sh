#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home" TMPDIR="$scratch/tmp"
mkdir -p "$HOME/.local/bin" "$TMPDIR" "$scratch/project with spaces"
source "$root/ai_cli_manager.sh"

# Execute callbacks and marker writes without touching host application paths.
kpanel_app_with_lock() { local resource=$1; shift; printf '%s\n' "$resource" >> "$scratch/locks"; "$@"; }
kpanel_app_update_marker() { printf '%s:%s\n' "$app_id" "$1" >> "$scratch/markers"; }
id() { if [ "${1:-}" = -u ]; then echo 0; else echo root; fi; }
ai_cli_select codex

if ai_cli_select 'codex; touch bad' >/dev/null 2>&1; then exit 1; fi
ai_cli_select codex
# Host installations are intentionally excluded from these fixture-only tests.
export PATH="$HOME/.local/bin:/usr/bin:/bin"
npm() { return 1; }

curl() {
	local output
	printf '%s\n' "$*" >> "$scratch/downloads"
	while [ "$#" -gt 0 ]; do
		if [ "$1" = -o ]; then output=$2; shift; fi
		shift
	done
	cat > "$output" <<'INSTALLER'
#!/bin/sh
touch "$HOME/installer-ran"
[ "${INSTALLER_STATUS:-37}" != 0 ] || [ -z "${AGY_FIXTURE:-}" ] || { mkdir -p "$HOME/.local/bin"; cp "$AGY_FIXTURE" "$HOME/.local/bin/agy"; }
exit "${INSTALLER_STATUS:-37}"
INSTALLER
	return "${DOWNLOAD_STATUS:-0}"
}
DOWNLOAD_STATUS=22
if ai_cli_native_install; then echo 'accepted partial download' >&2; exit 1; fi
test ! -e "$HOME/installer-ran"
test -z "$(ls -A "$TMPDIR")"
DOWNLOAD_STATUS=0
status=0
ai_cli_native_install || status=$?
test "$status" = 37
test -e "$HOME/installer-ran"
test -z "$(ls -A "$TMPDIR")"
if ai_cli_install_impl; then echo 'accepted failed installer' >&2; exit 1; fi
test ! -e "$scratch/markers"
export INSTALLER_STATUS=0
if ai_cli_install_impl; then echo 'accepted installer without executable' >&2; exit 1; fi
test ! -e "$scratch/markers"
unset INSTALLER_STATUS

make_cli() {
	local bin=$1
	cat > "$bin" <<'CLI'
#!/bin/bash
printf '%s\n' "$PWD" "$@" >> "$HOME/cli-calls"
printf '%s\n' "$*" >> "$HOME/cli-actions"
if [ "${1:-}" = --version ]; then echo 'fixture-cli 1.0.0'; fi
if [ "${2:-}" = --with-api-key ]; then cat > "$HOME/key-input"; fi
if [ "${0##*/}" = opencode ] && [ "${1:-}" = uninstall ] && [ "${CLI_STATUS:-0}" = 0 ]; then
	[ "$*" = 'uninstall --keep-config --keep-data --force' ] || exit 42
	rm -- "$0"
fi
exit "${CLI_STATUS:-0}"
CLI
	chmod +x "$bin"
}
mkdir -p "$HOME/.codex/packages/standalone/releases/test/bin"
make_cli "$HOME/.codex/packages/standalone/releases/test/bin/codex"
ln -s releases/test "$HOME/.codex/packages/standalone/current"
ln -s "$HOME/.codex/packages/standalone/current/bin/codex" "$HOME/.local/bin/codex"
ai_cli_install_impl
grep -qx '120:add' "$scratch/markers"
ai_cli_is_native_install

ai_cli_project <<< "$scratch/project with spaces"
grep -qx "$scratch/project with spaces" "$HOME/cli-calls"
test "$PWD" != "$scratch/project with spaces"
ai_cli_project resume <<< "$scratch/project with spaces"
grep -qx resume "$HOME/cli-calls"
if ai_cli_project <<< "$scratch/not-here"; then exit 1; fi
ai_cli_login <<< 1
grep -qx -- --device-auth "$HOME/cli-calls"
ai_cli_login <<< $'2\nfixture-key' > "$scratch/login-output"
test "$(cat "$HOME/key-input")" = fixture-key
! grep -q fixture-key "$HOME/cli-calls" "$scratch/login-output"
ai_cli_auth status
ai_cli_auth logout

# Unknown package installation is never removed, and failed updates keep markers.
DOWNLOAD_STATUS=22
if ai_cli_update_impl; then exit 1; fi
test -x "$HOME/.local/bin/codex"
touch "$HOME/.codex/auth.json" "$HOME/.codex/config.toml"
ai_cli_uninstall <<< n
test -x "$HOME/.local/bin/codex"
ai_cli_uninstall <<< y
test ! -e "$HOME/.local/bin/codex"
test -f "$HOME/.codex/auth.json" && test -f "$HOME/.codex/config.toml"
grep -qx '120:remove' "$scratch/markers"

ai_cli_select claude-code
mkdir -p "$HOME/.local/share/claude/versions" "$HOME/.claude"
make_cli "$HOME/.local/share/claude/versions/test"
ln -s "$HOME/.local/share/claude/versions/test" "$HOME/.local/bin/claude"
ai_cli_install_impl
grep -qx '119:add' "$scratch/markers"
ai_cli_login
ai_cli_auth status
ai_cli_auth logout
ai_cli_project resume <<< "$scratch/project with spaces"
grep -qx -- --resume "$HOME/cli-calls"
ai_cli_update_impl
touch "$HOME/.claude/settings.json" "$HOME/.claude.json"
ai_cli_uninstall <<< y
test -f "$HOME/.claude/settings.json" && test -f "$HOME/.claude.json"
grep -qx '119:remove' "$scratch/markers"

# npm installations are updated/uninstalled with their existing package manager.
mkdir -p "$HOME/npm/node_modules/@anthropic-ai/claude-code"
make_cli "$HOME/npm/node_modules/@anthropic-ai/claude-code/cli.js"
ln -s "$HOME/npm/node_modules/@anthropic-ai/claude-code/cli.js" "$HOME/.local/bin/claude"
npm() {
	printf '%s\n' "$*" >> "$scratch/npm-calls"
	case "$1" in
		root) printf '%s\n' "$HOME/npm/node_modules" ;;
		install) return "${NPM_STATUS:-0}" ;;
		uninstall) [ "${NPM_STATUS:-0}" = 0 ] || return "$NPM_STATUS"; rm "$HOME/.local/bin/claude" ;;
	esac
}
ai_cli_update_impl
grep -qx 'install -g @anthropic-ai/claude-code@latest' "$scratch/npm-calls"
NPM_STATUS=29
if ai_cli_uninstall_impl; then exit 1; fi
test -x "$HOME/.local/bin/claude"
NPM_STATUS=0
ai_cli_uninstall_impl
grep -qx 'uninstall -g @anthropic-ai/claude-code' "$scratch/npm-calls"
make_cli "$HOME/.local/bin/claude"
if ai_cli_uninstall_impl; then exit 1; fi
test -x "$HOME/.local/bin/claude"

# Recognize the original official OpenCode install without reinstalling it.
ai_cli_select opencode
test "$AI_CLI_ID" = 121 && test "$AI_CLI_BIN_DIR" = "$HOME/.opencode/bin"
mkdir -p "$HOME/.opencode/bin" "$HOME/.config/opencode" "$HOME/.local/share/opencode"
make_cli "$HOME/.opencode/bin/opencode"
touch "$HOME/.config/opencode/opencode.json" "$HOME/.local/share/opencode/auth.json" "$HOME/.local/share/opencode/opencode.db"
ai_cli_install_impl
grep -qx '121:add' "$scratch/markers"
ai_cli_is_native_install
: > "$HOME/cli-actions"
ai_cli_project <<< "$scratch/project with spaces"
grep -qx '' "$HOME/cli-actions"
ai_cli_project resume <<< "$scratch/project with spaces"
ai_cli_login
ai_cli_auth status
ai_cli_auth logout
ai_cli_update_impl
for expected in '--continue' 'auth login' 'auth list' 'auth logout' 'upgrade --method curl'; do
	grep -qx -- "$expected" "$HOME/cli-actions"
done
export CLI_STATUS=29
if ai_cli_update_impl; then exit 1; fi
if ai_cli_uninstall_impl; then exit 1; fi
! grep -qx '121:remove' "$scratch/markers"
test -x "$HOME/.opencode/bin/opencode"
CLI_STATUS=0
ai_cli_uninstall <<< n
test -x "$HOME/.opencode/bin/opencode"
ai_cli_uninstall <<< y
test ! -e "$HOME/.opencode/bin/opencode"
grep -qx '121:remove' "$scratch/markers"
test -f "$HOME/.config/opencode/opencode.json"
test -f "$HOME/.local/share/opencode/auth.json" && test -f "$HOME/.local/share/opencode/opencode.db"

# Installation download failures do not write a marker or execute partial data.
DOWNLOAD_STATUS=22
marker_count=$(wc -l < "$scratch/markers")
rm -f "$HOME/installer-ran"
if ai_cli_install_impl; then exit 1; fi
test "$(wc -l < "$scratch/markers")" = "$marker_count"
test ! -e "$HOME/installer-ran"
grep -q 'https://opencode.ai/install' "$scratch/downloads"
DOWNLOAD_STATUS=0

# npm installs retain the package-manager update/uninstall path.
mkdir -p "$HOME/npm/node_modules/opencode-ai/bin"
make_cli "$HOME/npm/node_modules/opencode-ai/bin/opencode"
ln -s "$HOME/npm/node_modules/opencode-ai/bin/opencode" "$HOME/.opencode/bin/opencode"
npm() {
	printf '%s\n' "$*" >> "$scratch/npm-calls"
	case "$1" in
		root) printf '%s\n' "$HOME/npm/node_modules" ;;
		install) return 0 ;;
		uninstall) rm "$HOME/.opencode/bin/opencode" ;;
	esac
}
ai_cli_update_impl
grep -qx 'install -g opencode-ai@latest' "$scratch/npm-calls"
ai_cli_uninstall_impl
grep -qx 'uninstall -g opencode-ai' "$scratch/npm-calls"

# Unknown installation is left to its original package manager.
make_cli "$HOME/.local/bin/opencode"
if ai_cli_uninstall_impl; then exit 1; fi
test -x "$HOME/.local/bin/opencode"

# Antigravity uses its official flat binary and native TUI account commands.
ai_cli_select antigravity-cli
test "$AI_CLI_ID" = 122 && test "$AI_CLI_COMMAND" = agy
test -z "$AI_CLI_PACKAGE"
mkdir -p "$HOME/.gemini/antigravity-cli" "$HOME/.cache/antigravity"
touch "$HOME/.gemini/antigravity-cli/settings.json" "$HOME/.gemini/antigravity-cli/sessions.json" "$HOME/.cache/antigravity/fixture-cache"
make_cli "$scratch/agy-template"
export AGY_FIXTURE="$scratch/agy-template" INSTALLER_STATUS=0
ai_cli_install_impl
unset AGY_FIXTURE INSTALLER_STATUS
grep -qx '122:add' "$scratch/markers"
grep -q 'https://antigravity.google/cli/install.sh' "$scratch/downloads"
ai_cli_is_native_install
! ai_cli_is_npm_install
: > "$HOME/cli-actions"
ai_cli_project <<< "$scratch/project with spaces"
ai_cli_project resume <<< "$scratch/project with spaces"
ai_cli_login
ai_cli_auth status > "$scratch/agy-status"
grep -q '/usage' "$scratch/agy-status"
ai_cli_auth logout
ai_cli_update_impl
grep -qx '' "$HOME/cli-actions"
grep -qx -- '--continue' "$HOME/cli-actions"
grep -qx update "$HOME/cli-actions"
! grep -qE '^(auth|login|logout|/logout)' "$HOME/cli-actions"
export CLI_STATUS=29
marker_count=$(wc -l < "$scratch/markers")
if ai_cli_update_impl; then exit 1; fi
test "$(wc -l < "$scratch/markers")" = "$marker_count"
CLI_STATUS=0
ai_cli_uninstall <<< n
test -x "$HOME/.local/bin/agy"
ai_cli_uninstall <<< y
test ! -e "$HOME/.local/bin/agy"
grep -qx '122:remove' "$scratch/markers"
test -f "$HOME/.gemini/antigravity-cli/settings.json"
test -f "$HOME/.gemini/antigravity-cli/sessions.json" && test -f "$HOME/.cache/antigravity/fixture-cache"
DOWNLOAD_STATUS=22
marker_count=$(wc -l < "$scratch/markers")
rm -f "$HOME/installer-ran"
if ai_cli_install_impl; then exit 1; fi
test "$(wc -l < "$scratch/markers")" = "$marker_count"
test ! -e "$HOME/installer-ran"
DOWNLOAD_STATUS=0
# A package-manager or unknown symlink cannot be removed as a native install.
ln -s "$scratch/agy-template" "$HOME/.local/bin/agy"
if ai_cli_uninstall_impl; then exit 1; fi
test -L "$HOME/.local/bin/agy"
rm "$HOME/.local/bin/agy"

# EOF and return preserve failures, so KPanel never records a failed task as done.
ai_cli_main claude-code <<< $'6\n\n0' > "$scratch/menu" && exit 1
ai_cli_main claude-code <<< 0

# Exercise the actual dispatcher/bootstrap with local downloads and no host effects.
awk '/^run_ai_cli_manager\(\) \(/ { capture=1 } /^linux_work\(\) \{/ { exit } capture { print }' "$root/kejilion.sh" > "$scratch/dispatcher.sh"
source "$scratch/dispatcher.sh"
clear() { :; }
refresh_apps_catalog() { :; }
gh_proxy=''
gl_kjlan='' gl_bai=''
curl() {
	local output
	while [ "$#" -gt 0 ]; do
		if [ "$1" = -o ]; then output=$2; shift; fi
		shift
	done
	printf 'ai_cli_main() { printf "%%s\\n" "$1" > "%s/selected"; return 37; }\n' "$scratch" > "$output"
	return "${DOWNLOAD_STATUS:-0}"
}
DOWNLOAD_STATUS=0
export KJ_APP_INTERACTIVE=1 KJ_APP_NONINTERACTIVE=0
for selector in 119 claude claude-code 120 codex 121 opencode OpenCode 122 antigravity-cli agy; do
	status=0
	linux_panel "$selector" || status=$?
	test "$status" = 37
	case "$selector" in 119|claude|claude-code) expected=claude-code ;; 120|codex) expected=codex ;; 121|opencode|OpenCode) expected=opencode ;; *) expected=antigravity-cli ;; esac
	test "$(cat "$scratch/selected")" = "$expected"
done
rm "$scratch/selected"
DOWNLOAD_STATUS=22
if run_ai_cli_manager codex; then exit 1; fi
test ! -e "$scratch/selected"
test -z "$(ls -A "$TMPDIR")"
echo ai_cli_manager=pass
