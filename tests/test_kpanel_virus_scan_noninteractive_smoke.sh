#!/usr/bin/env bash
set -uo pipefail

root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="$root/kejilion.sh"
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT

fail() {
	printf 'FAIL: %s\n' "$*" >&2
	exit 1
}

grep -Fqx 'KPANEL_VIRUS_SCAN_PROTOCOL_VERSION="1"' "$script_path" || fail "protocol marker is missing"
grep -F '[ "${KJ_VIRUS_SCAN_NONINTERACTIVE:-}" = "1" ] ||' "$script_path" >/dev/null || fail "startup guard is missing"
grep -F 'kpanel_virus_scan_dispatch "$@"' "$script_path" >/dev/null || fail "dispatcher is not wired"

sed -n '/^KPANEL_VIRUS_SCAN_PROTOCOL_VERSION=/,/^clamav_scan() {/p' "$script_path" | sed '$d' > "$temporary/functions.sh"
# shellcheck disable=SC1090
source "$temporary/functions.sh"

docker_rc=0
docker() {
	printf '<%s>\n' "$@" >> "$temporary/docker.args"
	if [[ " $* " == *" clamscan "* ]]; then
		return "$docker_rc"
	fi
	return 0
}
kpanel_virus_scan_prepare_log() { :; }

kpanel_virus_scan_update_db || fail "virus database update should succeed"
grep -Fx '<source=clam_db,target=/var/lib/clamav,volume-nocopy>' "$temporary/docker.args" >/dev/null || fail "freshclam volume copy-up is not disabled"
grep -Fx '<freshclam>' "$temporary/docker.args" >/dev/null || fail "freshclam entrypoint is missing"
grep -Fx '<--user>' "$temporary/docker.args" >/dev/null || fail "freshclam user option is missing"
grep -Fx '<root>' "$temporary/docker.args" >/dev/null || fail "freshclam root user is missing"
grep -Fx '<SETUID>' "$temporary/docker.args" >/dev/null || fail "freshclam SETUID capability is missing"
grep -Fx '<SETGID>' "$temporary/docker.args" >/dev/null || fail "freshclam SETGID capability is missing"
grep -Fx '</var/log/clamav:rw,noexec,nosuid,nodev,size=16m,mode=0750>' "$temporary/docker.args" >/dev/null || fail "freshclam log tmpfs is missing"
: > "$temporary/docker.args"

mkdir "$temporary/scan-one" "$temporary/scan-two"
output="$(kpanel_virus_scan_run custom "$temporary/scan-one" "$temporary/scan-two")" || fail "custom scan should succeed"
grep -Fx 'KPANEL_VIRUS_SCAN_PROTOCOL 1' <<< "$output" >/dev/null || fail "protocol header mismatch"
grep -Fx 'KPANEL_VIRUS_SCAN_STATUS=clean' <<< "$output" >/dev/null || fail "clean receipt is missing"
grep -F 'target=/mnt/scan/0,readonly' "$temporary/docker.args" >/dev/null || fail "first read-only mount is missing"
grep -F 'target=/mnt/scan/1,readonly' "$temporary/docker.args" >/dev/null || fail "second read-only mount is missing"
grep -Fx '<--network>' "$temporary/docker.args" >/dev/null || fail "scan network isolation is missing"
grep -Fx '<--read-only>' "$temporary/docker.args" >/dev/null || fail "read-only container is missing"
grep -Fx '<--entrypoint>' "$temporary/docker.args" >/dev/null || fail "explicit ClamAV entrypoint is missing"
grep -Fx '<clamscan>' "$temporary/docker.args" >/dev/null || fail "clamscan entrypoint is missing"

docker_rc=1
output="$(kpanel_virus_scan_run custom "$temporary")"
rc=$?
[ "$rc" -eq 0 ] || fail "virus findings must be a successful scan result"
grep -Fx 'KPANEL_VIRUS_SCAN_STATUS=infected' <<< "$output" >/dev/null || fail "infected receipt is missing"

if kpanel_virus_scan_run custom relative/path >/dev/null 2>&1; then
	fail "relative custom path was accepted"
fi
if kpanel_virus_scan_run custom "$temporary/scan-one/../scan-two" >/dev/null 2>&1; then
	fail "non-canonical custom path was accepted"
fi
if kpanel_virus_scan_run custom "$temporary/scan-one" "$temporary/scan-one" >/dev/null 2>&1; then
	fail "duplicate custom path was accepted"
fi
mkdir "$temporary/bad,path"
if kpanel_virus_scan_run custom "$temporary/bad,path" >/dev/null 2>&1; then
	fail "comma path was accepted"
fi
mkdir "$temporary/"$'bad\tpath'
if kpanel_virus_scan_run custom "$temporary/"$'bad\tpath' >/dev/null 2>&1; then
	fail "control character path was accepted"
fi
if kpanel_virus_scan_run custom >/dev/null 2>&1; then
	fail "empty custom path set was accepted"
fi

printf 'KPanel virus scan non-interactive smoke test passed.\n'
