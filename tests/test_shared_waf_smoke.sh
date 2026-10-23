#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
bash -n "$root/kejilion.sh"
for name in shared_waf_revision shared_waf_manifest shared_waf_verified shared_waf_prepare shared_waf_cached shared_waf shared_waf_refresh shared_waf_remove_rotation nginx_reload nginx_waf shared_waf_mode nginx_wait_ready nginx_upgrade ldnmp_upgrade_all nginx_install_all ldnmp_protection_action ldnmp_uninstall_action; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh" >> "$fixture/functions"
done
sed -e "s|/home/web|$fixture/web|g" -e "s|/root/.waf-cron-cleanup.|$fixture/.waf-cron-cleanup.|g" "$fixture/functions" > "$fixture/isolated"
source "$fixture/isolated"
[[ "$(shared_waf_revision)" =~ ^[0-9a-f]{40}$ ]]
[ "$(shared_waf_manifest | wc -l)" -eq 6 ]
[ "$(shared_waf_manifest | awk '{print $2}' | sort -u | wc -l)" -eq 6 ]
shared_waf_manifest | awk 'length($1)!=64 || $1~/[^0-9a-f]/ {exit 1}'
if grep -Eq 'systemctl (enable|start)|shared_waf retire-jails' "$fixture/functions"; then
  echo 'Unexpected automatic backend or legacy jail replacement' >&2; exit 1
fi

calls="$fixture/calls"
test_python="${WAF_TEST_PYTHON:-$(command -v python3)}"
python3() { "$test_python" "$@"; }
shared_waf_prepare() { WAF_PYTHON="$test_python"; }
docker() { printf 'docker %s\n' "$*" >> "$calls"; return "${module_failure:-0}"; }
logrotate() { :; }
crontab() { :; }
shared_waf() {
  printf '%s\n' "$*" >> "$calls"
  case "$1" in
    rotation) return "${rotation_failure:-0}" ;;
    configure)
      [ "${configure_failure:-0}" = 0 ] || return 1
      printf '{"applied":true,"backup":"/home/web/backups/waf-managed/test-policy"}\n' ;;
    existing-filters) return "${filter_failure:-0}" ;;
  esac
}
reset_calls() { : > "$calls"; module_failure=0; rotation_failure=0; configure_failure=0; filter_failure=0; }
reset_calls
if nginx_waf invalid 2>/dev/null; then exit 1; fi
[ ! -s "$calls" ]
module_failure=1
if nginx_waf on 2>/dev/null; then exit 1; fi
! grep -q configure "$calls"

reset_calls; rotation_failure=1
if nginx_waf on; then exit 1; fi
! grep -q configure "$calls"

reset_calls; configure_failure=1
if nginx_waf on; then exit 1; fi
! grep -q existing-filters "$calls"

reset_calls; filter_failure=1
if nginx_waf on >/dev/null; then exit 1; fi
grep -Fx 'rollback --backup /home/web/backups/waf-managed/test-policy' "$calls"

reset_calls
nginx_waf off >/dev/null
grep -Fx 'configure --mode off' "$calls"
! grep -q '^rotation$' "$calls"
grep -Fx existing-filters "$calls"

reset_calls
nginx_waf on >/dev/null
grep -Fx 'configure --mode on' "$calls"
grep -Fx rotation "$calls"

# The legacy partial snapshot must never wrap a complete shared transaction.
reset_calls
ldnmp_protection_action waf-on >/dev/null
grep -Fx 'configure --mode on' "$calls"
! grep -q 'docker exec nginx nginx -t' "$calls"
reset_calls; configure_failure=1
if ldnmp_protection_action waf-on >/dev/null; then exit 1; fi
! grep -q 'docker exec nginx nginx -t' "$calls"

reset_calls
shared_waf_refresh
[ ! -s "$calls" ]
mkdir -p "$fixture/web/config/waf"
printf '{}\n' > "$fixture/web/config/waf/policy.json"
shared_waf_refresh
grep -Fx apply "$calls"

# Image/config migration failure cases live in test_nginx_config_update.py.
# Keep this suite focused on native WAF behavior and entry-point delegation.
send_stats() { :; }
nginx_update_transaction() { printf 'transaction %s\n' "$1" >> "$calls"; return "${transaction_failure:-0}"; }
reset_calls
nginx_upgrade
grep -Fx 'transaction nginx' "$calls"
ldnmp_upgrade_all
grep -Fx 'transaction all' "$calls"
root_use() { :; }; clear() { :; }; install_dependency() { :; }
install_docker() { :; }; install_certbot() { :; }; install_ldnmp_conf() { :; }
gl_huang=""; gl_bai=""
transaction_failure=1
if nginx_install_all > "$fixture/install-failure" 2>&1; then exit 1; fi
! grep -Fq 'nginx已安装完成' "$fixture/install-failure"

# Environment removal must remove only the owned WAF job, with exact recovery.
cron_state="$fixture/cron-state"
printf '%s\n' '* * * * * private-logrotate # user-job' '* * * * * other-command # kejilion-waf-logrotate' > "$fixture/cron-expected"
cp "$fixture/cron-expected" "$cron_state"
printf '%s\n' "* * * * * /usr/sbin/logrotate --state $fixture/web/config/waf/logrotate.status $fixture/web/config/waf/logrotate.conf >/dev/null 2>&1 # kejilion-waf-logrotate" >> "$cron_state"
cp "$cron_state" "$fixture/cron-original"
crontab() {
  if [ "${1:-}" = -l ]; then
    case "${cron_empty:-}" in
      vixie) echo 'no crontab for root' >&2; return 1 ;;
      busybox) echo "crontab: can't open 'root': No such file or directory" >&2; return 1 ;;
      busybox-cannot) echo "crontab: cannot open 'root': No such file or directory" >&2; return 1 ;;
    esac
    [ "${cron_query_failure:-0}" = 0 ] || { echo 'permission denied' >&2; return 1; }
    cat "$cron_state"
  elif [[ "$1" = */after ]] && [ "${cron_write_failure:-0}" = 1 ]; then
    printf 'partial-write\n' > "$cron_state"; return 1
  elif [[ "$1" = */before ]] && [ "${cron_restore_failure:-0}" = 1 ]; then
    return 1
  else cp "$1" "$cron_state"
  fi
}
shared_waf_remove_rotation
cmp "$cron_state" "$fixture/cron-expected"
shared_waf_remove_rotation
cmp "$cron_state" "$fixture/cron-expected"
cp "$fixture/cron-original" "$cron_state"; cron_write_failure=1
if shared_waf_remove_rotation; then exit 1; fi
cmp "$cron_state" "$fixture/cron-original"
cron_restore_failure=1
if shared_waf_remove_rotation; then exit 1; else [ "$?" = 86 ]; fi
cp "$fixture/cron-original" "$cron_state"
cron_write_failure=0; cron_restore_failure=0; cron_query_failure=1
if shared_waf_remove_rotation; then exit 1; fi
cmp "$cron_state" "$fixture/cron-original"
cron_query_failure=0
for cron_empty in vixie busybox busybox-cannot; do shared_waf_remove_rotation; done
cron_empty=
docker() { return "${compose_down_failure:-0}"; }
compose_down_failure=1
if ldnmp_uninstall_action false; then exit 1; fi
[ -d "$fixture/web" ]
cmp "$cron_state" "$fixture/cron-original"
compose_down_failure=0; cron_write_failure=1
if ldnmp_uninstall_action false; then exit 1; fi
[ -d "$fixture/web" ]
cmp "$cron_state" "$fixture/cron-original"
cron_write_failure=0
ldnmp_uninstall_action false
[ ! -e "$fixture/web" ]
cmp "$cron_state" "$fixture/cron-expected"

# Execute the real backup + uninstall functions against a tiny private archive.
(
  cd "$fixture"
  backup_home="$fixture/backup-home"
  mkdir -p "$backup_home/web"
  printf 'retained\n' > "$backup_home/web/data"
  for name in ldnmp_backup_action ldnmp_uninstall_action; do
    sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh"
  done | sed "s|/home|$backup_home|g" > "$fixture/backup-functions"
  source "$fixture/backup-functions"
  sh_v=test
  kpanel_ldnmp_event() { :; }
  shared_waf_remove_rotation() { :; }
  docker() {
    printf '%s\n' "$*" >> "$fixture/backup-docker"
    case "$*" in
      'compose ps --services --filter status=running') printf 'nginx\n' ;;
      'compose start nginx') [ "${backup_fault:-}" != restart ] ;;
      *) return 0 ;;
    esac
  }
  mv() {
    case "${backup_fault:-}:$*" in
      rename:*) return 1 ;;
      sidecar:*kpanel.json) return 1 ;;
    esac
    command mv "$@"
  }
  sha256sum() { [ "${backup_fault:-}" != hash ] || return 1; command sha256sum "$@"; }
  chmod() { [ "${backup_fault:-}" != chmod ] || return 1; command chmod "$@"; }
  printf() {
    if [ "${backup_fault:-}" = metadata ] && [[ "${1:-}" = '{"format":'* ]]; then return 1; fi
    builtin printf "$@"
  }
  for backup_fault in rename sidecar hash chmod metadata restart; do
    rm -f -- "$backup_home"/web_*.tar.gz "$backup_home"/web_*.kpanel.json
    : > "$fixture/backup-docker"
    if ldnmp_uninstall_action true > "$fixture/backup-output"; then exit 1; else rc=$?; fi
    if [ "$backup_fault" = restart ]; then [ "$rc" = 86 ]; else [ "$rc" = 1 ]; fi
    [ -f "$backup_home/web/data" ]
    ! grep -q 'compose down' "$fixture/backup-docker"
    grep -q 'compose start nginx' "$fixture/backup-docker"
    ! grep -q 'KPANEL_LDNMP_BACKUP' "$fixture/backup-output"
  done
  backup_fault=
  rm -f -- "$backup_home"/web_*.tar.gz "$backup_home"/web_*.kpanel.json
  ldnmp_backup_action > "$fixture/backup-output"
  grep -q 'KPANEL_LDNMP_BACKUP web_' "$fixture/backup-output"
  [ "$(find "$backup_home" -maxdepth 1 -name '*.tar.gz' | wc -l)" = 1 ]
  [ "$(find "$backup_home" -maxdepth 1 -name '*.kpanel.json' | wc -l)" = 1 ]
)

echo shared_waf_protocol_dependencies_rollback=pass
