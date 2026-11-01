#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT

for relative in kejilion.sh cn/kejilion.sh; do
  (
    for name in nginx_install_update_dependencies ldnmp_Proxy kpanel_app_write_proxy kpanel_proxy_cli; do
      sed -n "/^$name() {/,/^}/p" "$root/$relative"
    done > "$fixture/functions"
    source "$fixture/functions"
    calls=''
    clear() { :; }; send_stats() { :; }; kpanel_web_progress() { :; }
    check_ip_and_get_access_port() { access_port=443; }
    install_ssltls() { calls+=" certificate"; }
    certs_status() { :; }
    find_container_by_host_port() { docker_name=kejilion-panel; }
    ip_address() { ipv4_address=203.0.113.1; }
    close_port() { calls+=" close"; }
    block_container_port() { calls+=" block"; }
    write_proxy=$(declare -f kpanel_app_write_proxy)
    kpanel_app_write_proxy() { calls+=" write"; }
    nginx_install_status() { return 42; }
    rc=0
    # Deliberately suppress errexit as real callers may do; guards must work.
    kpanel_proxy_cli panel.example.com 127.0.0.1 8080 || rc=$?
    [ "$rc" = 42 ] && [ -z "$calls" ]
    nginx_install_status() { :; }
    install_ssltls() { return 43; }
    rc=0
    kpanel_proxy_cli panel.example.com 127.0.0.1 8080 || rc=$?
    [ "$rc" = 43 ] && [ -z "$calls" ]
    install_ssltls() { :; }
    kpanel_app_write_proxy() { return 44; }
    rc=0
    kpanel_proxy_cli panel.example.com 127.0.0.1 8080 || rc=$?
    [ "$rc" = 44 ] && [ -z "$calls" ]
    kpanel_app_write_proxy() { :; }
    KJ_WEB_PROXY_KEEP_DIRECT=1 kpanel_proxy_cli panel.example.com 127.0.0.1 8080
    [ -z "$calls" ]
    kpanel_proxy_cli panel.example.com 127.0.0.1 8080
    [ "$calls" = ' close block' ]

    # Exercise the real writer with inert host/network commands.
    eval "$write_proxy"
    calls=''; gh_proxy=https://; yuming=panel.example.com; reverseproxy=127.0.0.1; port=8080
    wget() { :; }; sed() { :; }; update_nginx_listen_port() { :; }; nginx_http_on() { :; }
    nginx_web_on() { calls+=" success"; }
    tr() { printf backend; }; head() { cat; }
    docker() { calls+=" $*"; return 45; }
    rc=0
    kpanel_app_write_proxy || rc=$?
    [ "$rc" = 45 ] && [ "$calls" = ' exec nginx nginx -t' ]
    calls=''
    docker() { calls+=" $*"; if [ "$*" = 'exec nginx nginx -s reload' ]; then return 46; fi; }
    rc=0
    kpanel_app_write_proxy || rc=$?
    [ "$rc" = 46 ] && [[ "$calls" != *success* ]]
    wget() { return 47; }; calls=''
    rc=0
    kpanel_app_write_proxy || rc=$?
    [ "$rc" = 47 ] && [ -z "$calls" ]

    calls=''
    flock() { :; }
    install() { calls+=" $*"; }
    python3() { return 48; }
    rc=0
    nginx_install_update_dependencies || rc=$?
    [ "$rc" != 0 ] && [[ "$calls" == *python3* ]]
    python3() { return 0; }
    nginx_install_update_dependencies
  )
  printf '%s: dependency/proxy/certificate/download/validation/reload/direct-access PASS\n' "$relative"
done
