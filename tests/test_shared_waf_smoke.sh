#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
bash -n "$root/kejilion.sh"
for name in shared_waf_revision shared_waf_manifest shared_waf_verified shared_waf_prepare shared_waf_cached shared_waf shared_waf_refresh nginx_reload nginx_waf shared_waf_mode nginx_wait_ready nginx_upgrade ldnmp_protection_action; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh" >> "$fixture/functions"
done
sed -e "s|/home/web|$fixture/web|g" -e "s|/root/.nginx-rollback.|$fixture/.nginx-rollback.|g" "$fixture/functions" > "$fixture/isolated"
source "$fixture/isolated"
[[ "$(shared_waf_revision)" =~ ^[0-9a-f]{40}$ ]]
[ "$(shared_waf_manifest | wc -l)" -eq 6 ]
[ "$(shared_waf_manifest | awk '{print $2}' | sort -u | wc -l)" -eq 6 ]
shared_waf_manifest | awk 'length($1)!=64 || $1~/[^0-9a-f]/ {exit 1}'
if grep -Eq 'systemctl (enable|start)|retire-jails' "$fixture/functions"; then
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
    "inspect -f {{.Image}} nginx") printf 'sha256:%064d\n' 1 ;;
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
echo shared_waf_protocol_dependencies_rollback=pass
