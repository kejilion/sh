#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
bash -n "$root/kejilion.sh"
for name in shared_waf_revision shared_waf_manifest shared_waf_verified shared_waf_prepare shared_waf_cached shared_waf shared_waf_refresh shared_waf_remove_rotation nginx_reload nginx_waf shared_waf_mode nginx_wait_ready nginx_upgrade nginx_install_all ldnmp_protection_action ldnmp_uninstall_action; do
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

shared_waf_refresh() { :; }
send_stats() { :; }
sleep() { :; }
crontab() { if [ "${1:-}" = -l ]; then printf '* * * * * private-logrotate # user-job\n'; else cat > "$fixture/cron"; fi; }
docker() {
  printf 'docker %s\n' "$*" >> "$calls"
  case "$*" in
    "inspect -f {{.Image}} nginx")
      [ "${inspect_failure:-0}" = 0 ] || return 1
      printf 'sha256:%064d\n' 1 ;;
    'container ls -a --filter name=^/nginx$ --format {{.ID}}')
      [ "${list_failure:-0}" = 0 ] || return 1
      printf '%s' "${container_list_result:-}" ;;
    'top nginx -eo args') printf 'nginx: worker process\n' ;;
    'compose config --format json')
      [ "${config_failure:-0}" = 0 ] || return 1
      printf '%s\n' '{"name":"fixture","services":{"nginx":{"image":"fixture:latest","environment":{"LITERAL":"hello$world"},"ports":["127.0.0.1:18443:443"]}}}' ;;
    'exec nginx nginx -t') return "${ready_failure:-0}" ;;
    *' config --format json') cat -- "$5" ;;
    *' pull nginx') return "${pull_failure:-0}" ;;
    *' run --rm --no-deps --entrypoint nginx nginx -t') return "${preflight_failure:-0}" ;;
    *' up -d --force-recreate nginx')
      # Assert the frozen model keeps overrides and literal dollar values.
      "$test_python" -I -c 'import json,sys; s=json.load(open(sys.argv[1]))["services"]["nginx"]; assert s["environment"]["LITERAL"]=="hello$world"; assert s["ports"]==["127.0.0.1:18443:443"]' "$5" || return 1
      return "${up_failure:-0}" ;;
  esac
}
reset_calls; pull_failure=1
if nginx_upgrade >/dev/null 2>&1; then exit 1; fi
! grep -q ' up -d ' "$calls"
reset_calls; pull_failure=0; preflight_failure=1
if nginx_upgrade >/dev/null 2>&1; then exit 1; fi
! grep -q ' up -d ' "$calls"
reset_calls; preflight_failure=0; up_failure=1
if nginx_upgrade >/dev/null 2>&1; then exit 1; fi
grep -F -- '--pull never nginx' "$calls"
! grep -Eq 'docker rm |docker rmi ' "$calls"
reset_calls; up_failure=0; ready_failure=1
if nginx_upgrade > "$fixture/not-ready" 2>&1; then exit 1; fi
grep -F '旧镜像恢复未能通过核验' "$fixture/not-ready"
! grep -Fq '已恢复并核验旧镜像' "$fixture/not-ready"
reset_calls; ready_failure=0; config_failure=1
if nginx_upgrade >/dev/null 2>&1; then exit 1; fi
! grep -q ' up -d ' "$calls"
config_failure=0
reset_calls; up_failure=0
nginx_upgrade >/dev/null
grep -Fx '* * * * * private-logrotate # user-job' "$fixture/cron"
# Fresh installation must reach compose; an unavailable daemon must not.
reset_calls; inspect_failure=1
nginx_upgrade >/dev/null
grep -F ' up -d --force-recreate nginx' "$calls"
! grep -q -- '--pull never' "$calls"
reset_calls; list_failure=1
if nginx_upgrade >/dev/null 2>&1; then exit 1; fi
! grep -q ' pull nginx' "$calls"
reset_calls; list_failure=0; container_list_result=container-with-unreadable-image
if nginx_upgrade >/dev/null 2>&1; then exit 1; fi
! grep -q ' pull nginx' "$calls"
container_list_result=""
root_use() { :; }; clear() { :; }; install_dependency() { :; }
install_docker() { :; }; install_certbot() { :; }; install_ldnmp_conf() { :; }
gl_huang=""; gl_bai=""
up_failure=1
if nginx_install_all > "$fixture/install-failure" 2>&1; then exit 1; fi
! grep -Fq 'nginx已安装完成' "$fixture/install-failure"
! grep -q -- '--pull never' "$calls"

# Environment removal must remove only the owned WAF job, with exact recovery.
cron_state="$fixture/cron-state"
printf '%s\n' '* * * * * private-logrotate # user-job' '* * * * * other-command # kejilion-waf-logrotate' > "$fixture/cron-expected"
cp "$fixture/cron-expected" "$cron_state"
printf '%s\n' "* * * * * /usr/sbin/logrotate --state $fixture/web/config/waf/logrotate.status $fixture/web/config/waf/logrotate.conf >/dev/null 2>&1 # kejilion-waf-logrotate" >> "$cron_state"
cp "$cron_state" "$fixture/cron-original"
crontab() {
  if [ "${1:-}" = -l ]; then
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

echo shared_waf_protocol_dependencies_rollback=pass
