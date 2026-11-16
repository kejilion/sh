#!/bin/bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
eval "$(awk '/^kpanel_app_restore_access_mode\(\) \{/ {capture=1} capture {print} capture && /^}$/ {exit}' "$project_root/kejilion.sh")"
calls=""
kpanel_app_write_access_mode() {
    case "$1" in direct|domain_only) ;; *) return 1 ;; esac
    calls+="write:$1;"
}
kpanel_app_apply_access_mode() { calls+="apply:$1:$2;"; }
unset docker_app_update_mode
kpanel_app_restore_access_mode domain_only
test "$calls" = 'apply:domain_only:false;'
calls=""
kpanel_app_restore_access_mode direct
test "$calls" = 'write:direct;'
for mode in direct domain_only; do
    calls=""
    docker_app_update_mode=preserve_entry
    kpanel_app_restore_access_mode "$mode"
    test "$calls" = "write:$mode;"
done
calls=""
if kpanel_app_restore_access_mode invalid; then
    echo 'FAIL: invalid access mode accepted' >&2
    exit 1
fi
test -z "$calls"
kpanel_app_write_access_mode() { return 37; }
status=0
kpanel_app_restore_access_mode domain_only || status=$?
test "$status" = 37
echo 'PASS: preserve_entry keeps native entry; ordinary access recovery and failure status preserved'
