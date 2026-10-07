#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
source "$root/ai_cli_manager.sh"
hosts="$scratch/hosts"
resolver_status=0
id() { echo "${fixture_uid:-0}"; }
getent() {
	[ "$*" = 'hosts localhost' ] || return 1
	[ "$resolver_status" = 0 ] || return 1
	awk '{sub(/#.*/, ""); for(i=2;i<=NF;i++) if(tolower($i) == "localhost") {print $1, "localhost"; found=1}} END {exit !found}' "$hosts"
}
kpanel_app_with_lock() {
	[ "$1" = system ] || return 1
	shift
	"$@" "$hosts"
}

# Reproduce the reported hosts file: ip6-localhost does not alias localhost.
printf '192.0.2.10 fixture-node\n::1 ip6-localhost ip6-loopback' > "$hosts"
cp "$hosts" "$scratch/original"
ai_cli_select antigravity-cli
ai_cli_prepare_environment > "$scratch/fixed-output"
grep -qx '127.0.0.1 localhost' "$hosts"
backups=("$hosts".kejilion-backup.*)
test "${#backups[@]}" = 1
cmp "$scratch/original" "${backups[0]}"
grep -q "${backups[0]}" "$scratch/fixed-output"
cp "$hosts" "$scratch/after-fix"
ai_cli_prepare_environment
cmp "$hosts" "$scratch/after-fix"
backups=("$hosts".kejilion-backup.*)
test "${#backups[@]}" = 1

# Preserve valid IPv6-only and multi-alias entries, including comments/case.
for mapping in '::1 localhost ip6-localhost' '127.0.0.1 fixture-node LOCALHOST # comment'; do
	printf '%s\n' "$mapping" > "$hosts"
	cp "$hosts" "$scratch/unchanged"
	ai_cli_prepare_environment
	cmp "$hosts" "$scratch/unchanged"
done

# An external address, even alongside a correct mapping, is never rewritten.
printf '127.0.0.1 localhost\n192.0.2.5 localhost\n' > "$hosts"
cp "$hosts" "$scratch/unchanged"
if ai_cli_prepare_environment; then echo 'accepted conflicting mapping' >&2; exit 1; fi
cmp "$hosts" "$scratch/unchanged"

# A resolver failure with an existing mapping must not append duplicates.
printf '127.0.0.1 localhost\n' > "$hosts"
cp "$hosts" "$scratch/unchanged"
resolver_status=1
if ai_cli_prepare_environment; then exit 1; fi
cmp "$hosts" "$scratch/unchanged"
resolver_status=0

# Non-root callers, symlinks, missing files and failed backups are not changed.
printf '# no localhost\n' > "$hosts"
cp "$hosts" "$scratch/unchanged"
fixture_uid=1000
if ai_cli_prepare_environment; then exit 1; fi
cmp "$hosts" "$scratch/unchanged"
unset fixture_uid
mv "$hosts" "$scratch/real-hosts"
ln -s "$scratch/real-hosts" "$hosts"
if ai_cli_prepare_environment; then exit 1; fi
cmp "$scratch/real-hosts" "$scratch/unchanged"
rm "$hosts"
if ai_cli_prepare_environment; then exit 1; fi
test ! -e "$hosts"
mv "$scratch/real-hosts" "$hosts"
mktemp() { return 1; }
if ai_cli_prepare_environment; then exit 1; fi
unset -f mktemp
cmp "$hosts" "$scratch/unchanged"
cp() { return 1; }
if ai_cli_prepare_environment; then exit 1; fi
unset -f cp
cmp "$hosts" "$scratch/unchanged"

# A write failure is reported with its completed original-file backup.
printf() {
	if [ "$1" = '\n127.0.0.1 localhost\n' ]; then return 1; fi
	builtin printf "$@"
}
if ai_cli_prepare_environment > "$scratch/write-error" 2>&1; then exit 1; fi
unset -f printf
cmp "$hosts" "$scratch/unchanged"
grep -q 'kejilion-backup' "$scratch/write-error"

# Missing resolver tooling fails before any host-file change.
command() {
	if [ "$*" = '-v getent' ]; then return 1; fi
	builtin command "$@"
}
if ai_cli_prepare_environment; then exit 1; fi
unset -f command
cmp "$hosts" "$scratch/unchanged"

# Repair that cannot restore resolver behavior fails with a recoverable backup.
resolver_status=1
if ai_cli_prepare_environment > "$scratch/resolver-error" 2>&1; then exit 1; fi
grep -qx '127.0.0.1 localhost' "$hosts"
grep -q 'nsswitch.conf' "$scratch/resolver-error"
grep -q 'kejilion-backup' "$scratch/resolver-error"
resolver_status=0

# Other managed CLIs do not require getent or modify hosts.
cp "$hosts" "$scratch/unchanged"
getent() { echo 'unexpected resolver call' >&2; return 1; }
for app in claude-code codex opencode; do
	ai_cli_select "$app"
	ai_cli_prepare_environment
done
cmp "$hosts" "$scratch/unchanged"

# Block every TUI entry and installation before running any native command.
ai_cli_select antigravity-cli
ai_cli_installed() { return 0; }
ai_cli_prepare_environment() { return 17; }
ai_cli_native_install() { echo installed >> "$scratch/native-calls"; }
agy() { echo launched >> "$scratch/native-calls"; }
ai_cli_mark() { echo marked >> "$scratch/native-calls"; }
if ai_cli_install_impl; then exit 1; fi
if ai_cli_project <<< "$scratch"; then exit 1; fi
if ai_cli_project resume <<< "$scratch"; then exit 1; fi
if ai_cli_login; then exit 1; fi
if ai_cli_auth logout; then exit 1; fi
test ! -e "$scratch/native-calls"
echo ai_cli_localhost=pass
