#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
payload="$root/tests/fixtures/nginx-update/bdb8cc42fb123b09b02dc5940d2596354efebb87/nginx10.conf"

for relative in kejilion.sh cn/kejilion.sh en/kejilion.sh tw/kejilion.sh jp/kejilion.sh kr/kejilion.sh ir/kejilion.sh ru/kejilion.sh; do
  (
    web="$fixture/${relative%kejilion.sh}web"
    mkdir -p "$web"
    for name in install nginx_template_install install_ldnmp_conf nginx_install_all ldnmp_install_all; do
      sed -n "/^$name() {/,/^}/p" "$root/$relative"
    done | sed "s|/home/web|$web|g; s|cd /home |cd $web/.. |g" > "$fixture/functions"
    source "$fixture/functions"
    # Keep the real package helper in scope, but never permit package/network work.
    apt() { echo unexpected-package-install >&2; return 99; }
    dnf() { echo unexpected-package-install >&2; return 99; }
    yum() { echo unexpected-package-install >&2; return 99; }
    curl() {
      local output=''
      while (($#)); do
        if [ "$1" = --output ]; then output="$2"; shift 2; else shift; fi
      done
      cp -- "$payload" "$output"
    }
    nginx_template_install
    cmp "$payload" "$web/nginx.conf"
    # A managed WAF include supplies the status directives itself. Replacing this
    # main file with the stock template would introduce duplicate HTTP directives.
    printf 'events {} http { include /etc/nginx/conf.d/waf/http*.conf; }\n' > "$web/nginx.conf"
    cp "$web/nginx.conf" "$fixture/expected-main"
    printf 'services: {mysql: {environment: {MYSQL_ROOT_PASSWORD: keep-me}}}\n' > "$web/docker-compose.yml"
    cp "$web/docker-compose.yml" "$fixture/expected-compose"
    mkdir -p "$web/waf"
    printf 'limit_req_status 429;\nlimit_conn_status 429;\n' > "$web/waf/http.conf"
    wget() { echo unexpected-template-reset >&2; return 99; }
    for attempt in 1 2 3; do
      nginx_template_install
      install_ldnmp_conf
      cmp "$fixture/expected-main" "$web/nginx.conf"
      cmp "$fixture/expected-compose" "$web/docker-compose.yml"
      if [ "$relative" = kejilion.sh ] && [ -n "${KJ_NGINX_TEST_IMAGE:-}" ]; then
        docker run --rm --network none --entrypoint nginx \
          -v "$web/nginx.conf:/etc/nginx/nginx.conf:ro" \
          -v "$web/waf:/etc/nginx/conf.d/waf:ro" "$KJ_NGINX_TEST_IMAGE" -t
      fi
    done
    rm "$web/nginx.conf"
    if install_ldnmp_conf 2> "$fixture/error"; then exit 1; fi
    cmp "$fixture/expected-compose" "$web/docker-compose.yml"
    curl() {
      while (($#)); do
        if [ "$1" = --output ]; then printf tampered > "$2"; return; fi
        shift
      done
    }
    if nginx_template_install 2> "$fixture/error"; then exit 1; fi
    [ ! -e "$web/nginx.conf" ]
    ! find "$web" -name '.nginx10.conf.*' | grep -q .

    # A failed initializer must return before starting containers, without relying on errexit.
    for name in send_stats root_use clear check_disk_space check_port install_dependency install_docker install_certbot; do
      eval "$name() { :; }"
    done
    install_ldnmp_conf() { return 42; }
    install_ldnmp() { touch "$fixture/unexpected-start"; }
    nginx_upgrade() { touch "$fixture/unexpected-start"; return 43; }
    export gl_huang='' gl_bai=''
    for entry in nginx_install_all ldnmp_install_all; do
      rc=0
      "$entry" > /dev/null || rc=$?
      [ "$rc" -eq 42 ]
      [ ! -e "$fixture/unexpected-start" ]
    done
  )
  printf '%s: first-install/update/integrity/failure-stop PASS\n' "$relative"
done
