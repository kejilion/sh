#!/usr/bin/env bash
set -eu
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d /tmp/kpanel-site-restart-failure.XXXXXXXX)"
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/web"
sed -n '/^restart_ldnmp() {/,/^}/p' "$root/kejilion.sh" |
  sed "s|/home/web|$fixture/web|g" > "$fixture/restart.sh"
source "$fixture/restart.sh"
shared_waf_refresh() { :; }
kpanel_web_confirm_created_access() {
  echo check >> "$fixture/checks"
  if [ -e "$fixture/unsafe" ]; then touch "$fixture/quarantined"; return 1; fi
}
docker() {
  if [ "$*" = 'compose restart' ]; then
    touch "$fixture/unsafe"
    return 1
  fi
  return 0
}
export KJ_WEB_ACCESS_PASSWORD_FILE=synthetic KJ_WEB_ACCESS_PASSWORD_APPLIED=1
if restart_ldnmp; then exit 1; fi
[ -e "$fixture/quarantined" ]
[ "$(wc -l < "$fixture/checks")" -eq 3 ]
echo 'PASS: failed compose restart still rechecks and quarantines unsafe access policy'
