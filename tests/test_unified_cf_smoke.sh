#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
for name in web_cf_enable web_ban_install web_ban_clear web_ban_remove check_cf_mode ddos_rule_add_once ddos_rule_remove_all enable_ddos_defense disable_ddos_defense web_security kpanel_ldnmp_escape kpanel_ldnmp_site_jail_json kpanel_ldnmp_migration_json kpanel_ldnmp_fail2ban_logs_json kpanel_ldnmp_ddos_rules_present kpanel_ldnmp_cloudflare_status_json kpanel_ldnmp_cloudflare_shield_off cf_shield_install_script nginx_template_install kpanel_ldnmp_protection_json; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh"
done | sed "s|/home/web|$fixture/web|g; s|/etc/fail2ban|$fixture/fail2ban|g; s|/var/log/fail2ban.log|$fixture/fail2ban.log|g; s|/root/CF-Under-Attack.sh|$fixture/root/CF-Under-Attack.sh|g" > "$fixture/functions"
source "$fixture/functions"
sed -n '/^web_ban_install() {/,/^}/p' "$root/kejilion.sh" | sed "s|/home/web|$fixture/web|g" > "$fixture/real-web-ban-install"
mkdir -p "$fixture/web/config/waf" "$fixture/fail2ban/jail.d"
calls="$fixture/calls"; : > "$calls"; waf_remove_failure=0; waf_clear_failure=0
test_python="${PYTHON:-$(command -v python3)}"
mkdir -p "$fixture/root"
CF_SHIELD_SOURCE="$root/CF-Under-Attack.sh"
cf_url_log="$fixture/cf-url"
nginx_url_log="$fixture/nginx-template-url"
curl() {
  local output="" url=""
  while (($#)); do
    case "$1" in
      --output) output="$2"; shift 2 ;;
      *) url="$1"; shift ;;
    esac
  done
  if [[ "$url" = */nginx10.conf ]]; then
    printf '%s\n' "$url" > "$nginx_url_log"
    printf '%s\n' 'tampered template' > "$output"
  else
    printf '%s\n' "$url" > "$cf_url_log"
    cp "$CF_SHIELD_SOURCE" "$output"
  fi
}
mkdir -p "$fixture/web"
if nginx_template_install 2> "$fixture/nginx-template.err"; then exit 1; fi
[ ! -e "$fixture/web/nginx.conf" ]
printf '%s\n' 'existing nginx config' > "$fixture/web/nginx.conf"
nginx_template_install
[ "$(cat "$fixture/web/nginx.conf")" = 'existing nginx config' ]
grep -Fq '/bdb8cc42fb123b09b02dc5940d2596354efebb87/nginx10.conf' "$nginx_url_log"
! grep -Fq 'nginx/main/nginx10.conf' "$nginx_url_log"
! find "$fixture/web" -mindepth 1 -maxdepth 1 -name '.nginx10.conf.*' | grep -q .
cf_shield_install_script user@example.com 'token-123' 'zone-456' "$fixture/root/CF-Under-Attack.sh"
grep -Fq 'f02b7b8d59fd090006304a998ea2b3410ae5f736/CF-Under-Attack.sh' "$cf_url_log"
grep -Fxq 'EMAIL=user@example.com' "$fixture/root/CF-Under-Attack.sh"
grep -Fxq 'API_KEY=token-123' "$fixture/root/CF-Under-Attack.sh"
grep -Fxq 'ZONE_ID=zone-456' "$fixture/root/CF-Under-Attack.sh"
[ "$(stat -c '%a' "$fixture/root/CF-Under-Attack.sh")" = 700 ]
payload="\$(touch $fixture/credential-command-executed)"
cf_shield_install_script "$payload" "$payload" "$payload" "$fixture/root/CF-malicious.sh"
sed -n '4,6p' "$fixture/root/CF-malicious.sh" > "$fixture/credential-assignments.sh"
bash -c 'source "$1"; printf "%s\n%s\n%s\n" "$EMAIL" "$API_KEY" "$ZONE_ID"' bash "$fixture/credential-assignments.sh" > "$fixture/credential-values"
printf '%s\n' "$payload" "$payload" "$payload" > "$fixture/credential-expected"
cmp "$fixture/credential-expected" "$fixture/credential-values"
[ ! -e "$fixture/credential-command-executed" ]
printf '%s\n' 'trusted-old-script' > "$fixture/root/CF-Under-Attack.sh"
printf '%s\n' 'tampered-source' > "$fixture/tampered"
CF_SHIELD_SOURCE="$fixture/tampered"
if cf_shield_install_script user@example.com 'token-123' 'zone-456' "$fixture/root/CF-Under-Attack.sh" 2> "$fixture/cf-download.err"; then exit 1; fi
[ "$(cat "$fixture/root/CF-Under-Attack.sh")" = 'trusted-old-script' ]
! find "$fixture/root" -mindepth 1 -maxdepth 1 -name '.CF-Under-Attack.*' | grep -q .
legacy_shield_call="$fixture/legacy-shield-call"
(
  cf_shield_install_script() { printf '%s\n' "$*" > "$legacy_shield_call"; }
  send_stats() { :; }; clear() { :; }; break_end() { :; }
  check_f2b_status() { check_f2b_status=' Fail2Ban已安装'; }
  check_waf_status() { waf_status=' WAF已开启'; }
  check_cf_mode() { CFmessage=' 源站封禁模式'; }
  check_crontab_installed() { :; }; install() { :; }
  crontab() {
    if [ "$1" = -l ]; then cat "$fixture/legacy-crontab" 2>/dev/null || :; return 0; fi
    if [ "$1" = - ]; then cat > "$fixture/legacy-crontab"; return 0; fi
    return 1
  }
  gl_lv= gl_bai= gl_huang=
  printf '22\nuser@example.com\ntoken-123\nzone-456\n0\n' | web_security > "$fixture/legacy-shield-menu.out"
)
grep -Fxq 'user@example.com token-123 zone-456' "$legacy_shield_call"
grep -Fxq "*/5 * * * * $fixture/root/CF-Under-Attack.sh" "$fixture/legacy-crontab"
! grep -Fq 'raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh' "$root/kejilion.sh"
for language in cn en tw jp kr ir ru; do
  localized_script="$root/$language/kejilion.sh"
  [ -f "$localized_script" ] || exit 1
  bash -n "$localized_script"
  [ "$(grep -Fc 'cf_shield_install_script() {' "$localized_script")" -eq 1 ]
  grep -Fq "revision='f02b7b8d59fd090006304a998ea2b3410ae5f736'" "$localized_script"
  grep -Fq "expected_sha='781265062ba74bdeccb443177a9580190942c379dbe1e19a78ba1c774400086c'" "$localized_script"
  ! grep -Fq 'raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh' "$localized_script"
  grep -Fq 'cf_shield_install_script "$cfuser" "$cftoken" "$cfzonID"' "$localized_script"
  case "$language" in
    en|tw|jp|kr) grep -Fq 'cf_shield_install_script "$cfuser" "$cftoken" "$cfzone" || return $?' "$localized_script" ;;
  esac
  case "$language" in
    cn|en|tw|jp|kr)
      grep -Fq 'nginx_template_install() {' "$localized_script"
      [ "$(grep -Fc 'nginx_template_install || return $?' "$localized_script")" -ge 2 ]
      ! sed -n '/^nginx_br() {/,/^}/p; /^nginx_zstd() {/,/^}/p' "$localized_script" | grep -Fq 'nginx/main/nginx10.conf'
      ;;
  esac
done
shared_waf_cached() { WAF_PYTHON="$test_python"; }
shared_waf_prepare() { shared_waf_cached; }
cf_mode=cloudflare; cf_healthy=true; cf_pending=false
shared_waf() {
  shared_waf_cached
  printf '%s\n' "$1" >> "$calls"
  case "$1" in
    cf-on) cat > "$fixture/credentials" ;;
    ban-clear) return "$waf_clear_failure" ;;
    ban-remove) return "$waf_remove_failure" ;;
    ban-status) printf '{"mode":"%s","healthy":%s,"pending":%s,"configured":true,"running":true,"activeBans":3,"migration":{"state":"current","importedRecords":0,"apiJailEnabled":false,"legacyCFDetected":false,"cfReentryRequired":false,"legacyReconcilerStopped":false},"email":"hidden@example.com","key":"secret-value"}\n' "$cf_mode" "$cf_healthy" "$cf_pending" ;;
    ban-preflight) printf '{"safe":true,"migration":{"state":"legacy-ready","importedRecords":12,"apiJailDetected":true,"apiJailEnabled":true,"legacyCFDetected":true,"cfReentryRequired":true,"legacyReconcilerDetected":true}}\n' ;;
  esac
}
# Missing site jails should be reported without sending UnknownJailException to fail2ban.log.
fail2ban_calls="$fixture/fail2ban-calls"; : > "$fail2ban_calls"
(
  fail2ban-client() {
    printf '%s\n' "$*" >> "$fail2ban_calls"
    case "$*" in
      ping) return 0 ;;
      status) printf 'Status\n|- Number of jail: 1\n`- Jail list: sshd\n' ;;
      *) printf 'ERROR UnknownJailException(%s)\n' "$*" >&2; return 1 ;;
    esac
  }
  send_stats() { :; }; clear() { :; }; break_end() { :; }
  check_f2b_status() { check_f2b_status=' Fail2Ban已安装'; }
  check_waf_status() { waf_status=' WAF已开启'; }
  check_cf_mode() { CFmessage=' 源站封禁模式'; }
  gl_lv= gl_bai= gl_huang=
  cf_mode=local; cf_healthy=false; cf_pending=true
  printf '6\n0\n' | web_security > "$fixture/jail-menu.out" 2> "$fixture/jail-menu.err"
)
grep -Fq '网站 Jail waf-attack 未安装或未加载' "$fixture/jail-menu.out"
grep -Fq '网站 Jail waf-rate 未安装或未加载' "$fixture/jail-menu.out"
! grep -q 'UnknownJailException' "$fixture/jail-menu.err"
[ "$(cat "$fail2ban_calls")" = "$(printf 'ping\nstatus')" ]

# Fail2Ban prefixes its list line with tree glyphs; installed jails must still be found.
: > "$fail2ban_calls"
(
  fail2ban-client() {
    printf '%s\n' "$*" >> "$fail2ban_calls"
    case "$*" in
      ping) return 0 ;;
      status) printf 'Status\n|- Number of jail: 3\n`- Jail list: sshd, waf-attack, waf-rate\n' ;;
      'status waf-attack') printf 'Status for the jail: waf-attack\n|- Currently banned: 2\n`- Total banned: 9\n' ;;
      'status waf-rate') printf 'Status for the jail: waf-rate\n|- Currently banned: 1\n`- Total banned: 4\n' ;;
      *) return 1 ;;
    esac
  }
  site_jail_status="$(kpanel_ldnmp_site_jail_json waf-attack true)"
  [[ "$site_jail_status" == *'"available":true,"currentlyBanned":2,"totalBanned":9'* ]]
  send_stats() { :; }; clear() { :; }; break_end() { :; }
  check_f2b_status() { check_f2b_status=' Fail2Ban已安装'; }
  check_waf_status() { waf_status=' WAF已开启'; }
  check_cf_mode() { CFmessage=' 源站封禁模式'; }
  gl_lv= gl_bai= gl_huang=
  cf_mode=local; cf_healthy=true; cf_pending=false
  printf '6\n0\n' | web_security > "$fixture/jail-installed-menu.out" 2> "$fixture/jail-installed-menu.err"
)
grep -Fq 'Status for the jail: waf-attack' "$fixture/jail-installed-menu.out"
grep -Fq 'Status for the jail: waf-rate' "$fixture/jail-installed-menu.out"
! grep -q '未安装或未加载' "$fixture/jail-installed-menu.out"
! grep -q 'UnknownJailException' "$fixture/jail-installed-menu.err"

# CF mode always runs the idempotent migration path before changing the edge mode.
printf '# Managed shared WAF; unified event bans v1\n' > "$fixture/fail2ban/jail.d/zz-waf-managed.local"
web_ban_install() { shared_waf_cached; printf 'install\n' >> "$calls"; return 0; }
fail2ban-client() { return 0; }
web_cf_enable user@example.com 'abcdefghijklmnopqrstuv' > "$fixture/output"
grep -Fx install "$calls"
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
# Clear/remove uses the shared adapter whenever local or CF state exists.
rm -f "$fixture/web/config/waf/ban-cf.json"
fail2ban-client() { return "${f2b_failure:-0}"; }
: > "$calls"; web_ban_clear; [ ! -s "$calls" ]
touch "$fixture/web/config/waf/bans.json"
web_ban_clear; grep -Fx ban-clear "$calls"
: > "$calls"; f2b_failure=1
if web_ban_clear; then exit 1; fi
grep -Fx ban-clear "$calls"; f2b_failure=0
web_ban_remove; grep -Fx ban-remove "$calls"
# CF credentials without the owner-state file must still enter the fail-closed cleanup path.
rm -f "$fixture/web/config/waf/bans.json"
printf '{"mode":"cloudflare","auth":{"email":"test@example.invalid","key":"not-a-real-secret"}}\n' > "$fixture/web/config/waf/ban-cf.json"
: > "$calls"
waf_clear_failure=1
if web_ban_clear; then echo "missing owner state must stop CF unban" >&2; exit 1; fi
grep -Fx ban-clear "$calls"
waf_clear_failure=0
: > "$calls"
waf_remove_failure=1
if web_ban_remove; then echo "missing owner state must stop CF cleanup" >&2; exit 1; fi
grep -Fx ban-remove "$calls"
waf_remove_failure=0
# Both protocol status and the menu initialize the interpreter before parsing.
status_body="$(sed -n '/^ldnmp_environment_status() {/,/^}/p' "$root/kejilion.sh")"
[[ "$status_body" == *'protection_json=$(kpanel_ldnmp_protection_json "$waf" "$waf_mode")'* ]]
eval "$(printf '%s\n' "$status_body" | sed "s|/home|$fixture|g")"
docker() { return 1; }; iptables() { return 1; }; ss() { :; }
ldnmp_site_count() { echo 0; }
kpanel_ldnmp_component() { printf '{"name":"%s"}' "$1"; }
mkdir -p "$fixture/root"; touch "$fixture/root/CF-Under-Attack.sh"
crontab() { [ "$1" = -l ] && { printf '%s\n' '*/5 * * * * /root/CF-Under-Attack.sh'; return 0; }; return 1; }
sh_v=test; cf_mode=cloudflare; cf_healthy=true; cf_pending=false
unset WAF_PYTHON
if ldnmp_environment_status > "$fixture/status.json"; then :; else exit 1; fi
"$test_python" - "$fixture/status.json" <<'PY'
import json,sys
protection=json.load(open(sys.argv[1]))['protection']
assert protection['cloudflare'] is True
assert protection['fail2ban'] is True
assert [j['name'] for j in protection['siteJails']]==['waf-attack','waf-rate','waf-api-invalid']
assert protection['ddosRuleCount']==0 and protection['ddosRuleExpected']==8
assert protection['cloudflareStatus']['mode']=='cloudflare'
assert protection['cloudflareStatus']['configured'] and protection['cloudflareStatus']['running']
assert protection['cloudflareStatus']['activeBans']==3
assert 'hidden@example.com' not in json.dumps(protection) and 'secret-value' not in json.dumps(protection)
assert protection['cloudflareShield']=={'available':True,'scheduled':True,'scriptPresent':True}
assert protection['ddosRulesAvailable'] is True
assert protection['banMigration']['state']=='current'
PY
rm -f "$fixture/web/config/waf/ban-cf.json"
touch "$fixture/web/config/waf/state.json"
kpanel_ldnmp_protection_json false off > "$fixture/pending-protection.json"
"$test_python" - "$fixture/pending-protection.json" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))['banMigration']
assert m['state']=='legacy-pending' and m['importedRecords']==12
assert m['apiJailEnabled'] and m['cfReentryRequired'] and m['legacyReconcilerStopped'] is False
PY
printf '%s\n' '2026-10-28 01:00:00 [waf-attack] Ban 192.0.2.1' '2026-10-28 01:01:00 [waf-rate] Ban "192.0.2.2"' '2026-10-28 01:02:00 [waf-api-invalid] Ban 192.0.2.4' '2026-10-28 01:03:00 [sshd] Ban 192.0.2.3' > "$fixture/fail2ban.log"
kpanel_ldnmp_fail2ban_logs_json "$fixture/fail2ban.log" > "$fixture/fail2ban-logs.json"
"$test_python" - "$fixture/fail2ban-logs.json" <<'PY'
import json,sys
logs=json.load(open(sys.argv[1]))
assert logs['available'] is True and len(logs['entries'])==3
assert all('[sshd]' not in line for line in logs['entries'])
assert '"192.0.2.2"' in logs['entries'][1]
assert '[waf-api-invalid]' in logs['entries'][2]
PY
kpanel_ldnmp_migration_json '{"migration":{"state":"legacy-imported","importedRecords":12,"apiJailEnabled":true,"legacyCFDetected":true,"cfReentryRequired":true,"legacyReconcilerStopped":true},"key":"secret"}' > "$fixture/migration.json"
"$test_python" - "$fixture/migration.json" <<'PY'
import json,sys
m=json.load(open(sys.argv[1]))
assert m['state']=='legacy-imported' and m['importedRecords']==12
assert m['apiJailEnabled'] and m['cfReentryRequired'] and m['legacyReconcilerStopped']
assert 'secret' not in json.dumps(m)
PY

# The no-write preflight must run before Fail2Ban setup, and install must own WAF apply.
touch "$fixture/web/config/waf/policy.json"
(
  order="$fixture/install-order"; : > "$order"
  source "$fixture/real-web-ban-install"
  shared_waf() { printf 'waf:%s\n' "$1" >> "$order"; return 0; }
  f2b_install_sshd() { printf 'fail2ban\n' >> "$order"; }
  ip() { printf 'ip\n' >> "$order"; return 0; }
  check_crontab_installed() { printf 'crontab\n' >> "$order"; }
  web_ban_cron_ready() { printf 'cron-ready\n' >> "$order"; }
  web_ban_install
  expected=$(printf 'waf:ban-preflight\nfail2ban\nip\nip\ncrontab\ncron-ready\nwaf:ban-install')
  [ "$(cat "$order")" = "$expected" ]
)
ddos_call=0; ddos_present=8
iptables() { ddos_call=$((ddos_call+1)); [ "$ddos_call" -le "$ddos_present" ]; }
[ "$(kpanel_ldnmp_ddos_rules_present)" = 8 ]
ddos_call=0; ddos_present=3
[ "$(kpanel_ldnmp_ddos_rules_present)" = 3 ]
declare -A ddos_state=()
iptables() {
  local operation="$1" key count
  shift
  key="$*"; count="${ddos_state["$key"]:-0}"
  case "$operation" in
    -C) [ "$count" -gt 0 ] ;;
    -A) ddos_state["$key"]=$((count + 1)) ;;
    -D) [ "$count" -gt 0 ] || return 1; ddos_state["$key"]=$((count - 1)) ;;
    *) return 2 ;;
  esac
}
send_stats() { :; }
ddos_state['DOCKER-USER -p tcp --syn -j DROP']=2
enable_ddos_defense
ddos_rules=(
  'DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT'
  'DOCKER-USER -p tcp --syn -j DROP'
  'DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT'
  'DOCKER-USER -p udp -j DROP'
  'INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT'
  'INPUT -p tcp --syn -j DROP'
  'INPUT -p udp -m limit --limit 3000/s -j ACCEPT'
  'INPUT -p udp -j DROP'
)
for rule in "${ddos_rules[@]}"; do
  expected=1; [ "$rule" = 'DOCKER-USER -p tcp --syn -j DROP' ] && expected=2
  [ "${ddos_state["$rule"]:-0}" -eq "$expected" ]
done
disable_ddos_defense
for rule in "${ddos_rules[@]}"; do [ "${ddos_state["$rule"]:-0}" -eq 0 ]; done
mkdir -p "$fixture/root"; touch "$fixture/root/CF-Under-Attack.sh"
printf '%s\n' '*/5 * * * * /root/CF-Under-Attack.sh' '0 1 * * * /usr/local/bin/other-job' > "$fixture/crontab"
crontab() {
  if [ "$1" = -l ]; then cat "$fixture/crontab"; return 0; fi
  if [ "$1" = - ]; then cat > "$fixture/crontab"; return 0; fi
  return 1
}
kpanel_ldnmp_cloudflare_shield_off "$fixture/root/CF-Under-Attack.sh"
! grep -Fq 'CF-Under-Attack.sh' "$fixture/crontab"
grep -Fq '/usr/local/bin/other-job' "$fixture/crontab"
[ ! -e "$fixture/root/CF-Under-Attack.sh" ]
touch "$fixture/root/CF-Under-Attack.sh"
crontab() { printf 'permission denied\n' >&2; return 1; }
if kpanel_ldnmp_cloudflare_shield_off "$fixture/root/CF-Under-Attack.sh"; then exit 1; fi
[ -e "$fixture/root/CF-Under-Attack.sh" ]
crontab() { printf 'no crontab for root\n' >&2; return 1; }
kpanel_ldnmp_cloudflare_shield_off "$fixture/root/CF-Under-Attack.sh"
[ ! -e "$fixture/root/CF-Under-Attack.sh" ]
# Restore/uninstall must clean remote ownership while Nginx is still running.
"$test_python" - "$root/kejilion.sh" <<'PY'
import sys
s=open(sys.argv[1],encoding='utf-8').read()
for name in ['ldnmp_uninstall_action','ldnmp_restore_action']:
    body=s.split(name+'() {\n',1)[1].split('\n}\n',1)[0]
    assert body.index('web_ban_remove')<body.index('docker compose down'),name
PY
echo unified_cf_switch_status_lifecycle=pass
