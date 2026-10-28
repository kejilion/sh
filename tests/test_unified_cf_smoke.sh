#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
for name in web_cf_enable web_ban_install web_ban_clear web_ban_remove check_cf_mode; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh"
done | sed "s|/home/web|$fixture/web|g; s|/etc/fail2ban|$fixture/fail2ban|g" > "$fixture/functions"
source "$fixture/functions"
mkdir -p "$fixture/web/config/waf" "$fixture/fail2ban/jail.d"
calls="$fixture/calls"; : > "$calls"
test_python="$(command -v python3)"
shared_waf_cached() { WAF_PYTHON="$test_python"; }
shared_waf_prepare() { shared_waf_cached; }
cf_mode=cloudflare; cf_healthy=true; cf_pending=false
shared_waf() {
  shared_waf_cached
  printf '%s\n' "$1" >> "$calls"
  case "$1" in
    cf-on) cat > "$fixture/credentials" ;;
    ban-status) printf '{"mode":"%s","healthy":%s,"pending":%s}\n' "$cf_mode" "$cf_healthy" "$cf_pending" ;;
  esac
}
# A configured integration must not be reinstalled or reset by the CF switch.
printf '# Managed shared WAF; unified event bans v1\n' > "$fixture/fail2ban/jail.d/zz-waf-managed.local"
web_ban_install() { echo unexpected-reinstall >&2; return 99; }
fail2ban-client() { return 0; }
web_cf_enable user@example.com 'abcdefghijklmnopqrstuv' > "$fixture/output"
"$test_python" - "$fixture/credentials" <<'PY'
import json,sys
assert json.load(open(sys.argv[1]))==dict(email='user@example.com',key='abcdefghijklmnopqrstuv')
PY
! grep -q 'abcdefghijklmnopqrstuv' "$fixture/output" "$calls"
# First-time status must initialize the interpreter in the parent shell.
touch "$fixture/web/config/waf/ban-cf.json"
unset WAF_PYTHON
check_cf_mode
[ "$CFmessage" = ' CF模式已开启' ]
cf_pending=true; check_cf_mode; [ "$CFmessage" = ' CF等待同步' ]
cf_healthy=false; check_cf_mode; [ "$CFmessage" = ' CF同步待核验' ]
cf_mode=local; check_cf_mode; [ "$CFmessage" = ' 源站封禁模式' ]
# Clear/remove only invoke the shared adapter when it owns persistent state.
fail2ban-client() { return "${f2b_failure:-0}"; }
: > "$calls"; web_ban_clear; [ ! -s "$calls" ]
touch "$fixture/web/config/waf/bans.json"
web_ban_clear; grep -Fx ban-clear "$calls"
: > "$calls"; f2b_failure=1
if web_ban_clear; then exit 1; fi
grep -Fx ban-clear "$calls"; f2b_failure=0
web_ban_remove; grep -Fx ban-remove "$calls"
# Both protocol status and the menu initialize the interpreter before parsing.
status_body="$(sed -n '/^ldnmp_environment_status() {/,/^}/p' "$root/kejilion.sh")"
[[ "$status_body" == *'&& shared_waf_cached; then'* ]]
eval "$(printf '%s\n' "$status_body" | sed "s|/home|$fixture|g")"
docker() { return 1; }; iptables() { return 1; }; ss() { :; }
ldnmp_site_count() { echo 0; }
kpanel_ldnmp_component() { printf '{"name":"%s"}' "$1"; }
kpanel_ldnmp_escape() { printf '%s' "$1"; }
sh_v=test; cf_mode=cloudflare; cf_healthy=true; cf_pending=false
unset WAF_PYTHON
if ldnmp_environment_status > "$fixture/status.json"; then :; else exit 1; fi
"$test_python" - "$fixture/status.json" <<'PY'
import json,sys
assert json.load(open(sys.argv[1]))['protection']['cloudflare'] is True
PY
# Restore/uninstall must clean remote ownership while Nginx is still running.
"$test_python" - "$root/kejilion.sh" <<'PY'
import sys
s=open(sys.argv[1]).read()
for name in ['ldnmp_uninstall_action','ldnmp_restore_action']:
    body=s.split(name+'() {\n',1)[1].split('\n}\n',1)[0]
    assert body.index('web_ban_remove')<body.index('docker compose down'),name
PY
echo unified_cf_switch_status_lifecycle=pass
