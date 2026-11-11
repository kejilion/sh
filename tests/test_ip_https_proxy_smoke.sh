#!/usr/bin/env bash
# Isolate certificate and config generation; never touch the host Nginx or firewall.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
export MSYS2_ARG_CONV_EXCL=/CN=

for relative in kejilion.sh cn/kejilion.sh; do
  (
    mkdir -p "$fixture/web/conf.d" "$fixture/web/certs" "$fixture/live"
    for name in check_ip_and_get_access_port update_nginx_listen_port install_ssltls kpanel_web_certificate_pair_valid nginx_http_on nginx_web_on; do
      sed -n "/^$name() {/,/^}/p" "$root/$relative"
    done | sed -e "s|/home/web|$fixture/web|g" -e "s|/etc/letsencrypt/live|$fixture/live|g" > "$fixture/functions"
    source "$fixture/functions"
    kpanel_web_http_mode() { [ "${http_mode:-0}" = 1 ]; }
    webname="IP HTTPS smoke test"
    shared_waf_refresh() { :; }; clear() { :; }; cd() { :; }
    docker() { printf '%s\n' "$*" >> "$fixture/docker.log"; }
    template() {
      cat <<'EOF'
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen 443 quic;
    server_name 203.0.113.1;
    ssl_certificate /etc/nginx/certs/203.0.113.1_cert.pem;
    ssl_certificate_key /etc/nginx/certs/203.0.113.1_key.pem;
    if ($scheme = http) {
        return 301 https://$host$request_uri;
    }
    location / {
        proxy_pass http://backend;
        add_header Alt-Svc 'h3=":443"; ma=86400';
    }
}
EOF
    }

    # The frontend TLS port is independent of the backend service's port.
    for yuming in 203.0.113.1 2001:db8:0:0:0:0:0:1 ::1; do
      check_ip_and_get_access_port "$yuming" <<< ''
      [ "$access_port" = 443 ]
      for access_port in 443 8443 65535; do
        conf="$fixture/web/conf.d/$yuming.conf"
        template > "$conf"
        update_nginx_listen_port "$yuming" "$access_port"
        nginx_http_on
        grep -Eq "^[[:space:]]*listen $access_port ssl;" "$conf"
        grep -Eq "^[[:space:]]*listen \[::\]:$access_port ssl;" "$conf"
        [ "$(grep -c '^[[:space:]]*listen ' "$conf")" = 2 ]
        ! grep -Eq '^[[:space:]]*(add_header Alt-Svc|return 301 https)' "$conf"
        grep -F 'proxy_pass http://backend;' "$conf"
        grep -F 'ssl_certificate_key ' "$conf"
        nginx_web_on > "$fixture/address"
        if [[ "$yuming" == *:* ]]; then expected="https://[$yuming]:$access_port"; else expected="https://$yuming:$access_port"; fi
        grep -Fx "$expected" "$fixture/address"
        grep -F '自签名证书' "$fixture/address"
        [ -f "$fixture/web/conf.d/${yuming}_${access_port}.conf" ]
      done
      check_ip_and_get_access_port "$yuming" <<< 8443
      [ "$access_port" = 8443 ]
    done

    yuming=203.0.113.1
    conf="$fixture/web/conf.d/$yuming.conf"
    template > "$conf"; cp "$conf" "$fixture/original"
    for bad in 0 65536 -1 abc 00080 '8443;id'; do
      if check_ip_and_get_access_port "$yuming" <<< "$bad"; then exit 1; fi
      if update_nginx_listen_port "$yuming" "$bad"; then exit 1; fi
      cmp "$conf" "$fixture/original"
    done
    if check_ip_and_get_access_port "$yuming" < /dev/null; then exit 1; fi

    # Staged configs must receive the same TLS settings without editing the live file.
    template > "$fixture/staged.conf"
    KJ_WEB_STAGED_CONFIG="$fixture/staged.conf" update_nginx_listen_port "$yuming" 9443
    grep -Eq '^[[:space:]]*listen 9443 ssl;' "$fixture/staged.conf"
    cmp "$conf" "$fixture/original"

    # An explicit HTTP recipe still bypasses certificate/port prompting and prints HTTP.
    http_mode=1
    check_ip_and_get_access_port "$yuming" < /dev/null
    [ -z "$access_port" ]
    KJ_WEB_HTTP_PORT=8080 nginx_web_on > "$fixture/address"
    grep -Fx 'http://203.0.113.1:8080' "$fixture/address"
    http_mode=0
    access_port=8443
    check_ip_and_get_access_port example.com < /dev/null
    [ -z "$access_port" ]
    update_nginx_listen_port "$yuming" "$access_port"
    cmp "$conf" "$fixture/original"

    # Exercise both platform branches with real OpenSSL, including IP identity and reuse.
    for algorithm in ec ed25519; do
      command() {
        if [ "$1" = -v ] && { [ "$2" = dnf ] || [ "$2" = yum ]; }; then
          [ "$algorithm" = ec ]; return
        fi
        builtin command "$@"
      }
      for yuming in 203.0.113.1 2001:db8:0:0:0:0:0:1; do
        rm -f "$fixture/web/certs/${yuming}_cert.pem" "$fixture/web/certs/${yuming}_key.pem"
        rm -f "$fixture/live/$yuming/fullchain.pem" "$fixture/live/$yuming/privkey.pem"
        install_ssltls
        cert="$fixture/web/certs/${yuming}_cert.pem"
        key="$fixture/web/certs/${yuming}_key.pem"
        openssl x509 -in "$cert" -noout -checkip "$yuming" | grep -F 'does match'
        openssl verify -CAfile "$cert" "$cert"
        kpanel_web_certificate_pair_valid "$cert" "$key" "$yuming"
        original_pair=$(sha256sum "$cert" "$key")
        install_ssltls
        [ "$(sha256sum "$cert" "$key")" = "$original_pair" ]
      done
      unset -f command
    done
    ! grep -F 'certbot/certbot' "$fixture/docker.log"
  )
  printf '%s: IP HTTPS ports, config, URL, SAN, certificate reuse and HTTP/domain compatibility PASS\n' "$relative"
done
