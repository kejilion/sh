#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
bash -n "$root/kejilion.sh"
bash -n "$root/cn/kejilion.sh"
sed 's/^canshu="CN"$/canshu="default"/' "$root/cn/kejilion.sh" | cmp - "$root/kejilion.sh"
mkdir -p "$fixture/web/conf.d" "$fixture/web/html" "$fixture/locks"
sed -n '/^KPANEL_WEB_HTTP_PROTOCOL_VERSION=/,/^KPANEL_WEB_REDIRECT_PROTOCOL_VERSION=/p' "$root/kejilion.sh" > "$fixture/functions"
for name in nginx_http_on install_ssltls certs_status check_ip_and_get_access_port nginx_web_on; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh" >> "$fixture/functions"
done
sed -e "s|/home/web|$fixture/web|g" -e "s|/run/lock|$fixture/locks|g" "$fixture/functions" > "$fixture/isolated"
source "$fixture/isolated"
template() {
cat <<'EOF'
server {
    listen 80;
    listen [::]:80;
    listen 443 ssl;
    listen 443 quic;
    server_name example.com;
    ssl_certificate /etc/nginx/certs/example.com_cert.pem;
    ssl_certificate_key /etc/nginx/certs/example.com_key.pem;
    if ($scheme = http) {
        return 301 https://$host$request_uri;
    }
    root /var/www/html/example.com;
    location / {
        proxy_set_header Host $host;
        proxy_set_header X-Forwarded-Proto $scheme;
        add_header Alt-Svc 'h3=":443"; ma=86400';
    }
}
EOF
}
docker() {
  echo "$*" >> "$fixture/docker.log"
  case "$*" in
    'inspect --format {{.HostConfig.NetworkMode}} nginx') echo "${network_mode:-host}" ;;
    'inspect --format {{.State.Running}} nginx') [ -f "$fixture/stopped" ] && echo false || echo true ;;
    'top nginx -eo pid') printf 'PID\n123\n' ;;
    'start nginx') rm -f "$fixture/stopped" ;;
    'exec nginx cat /proc/net/tcp /proc/net/tcp6') [ "${missing_listener:-0}" != 1 ] && echo '0: 00000000:20FB 00000000:0000 0A' ;;
    'port nginx '*'/tcp') [ "${mapped:-0}" = 1 ] && echo '0.0.0.0:8443' ;;
    'exec nginx nginx -t') [ "${fail_test:-0}" != 1 ] ;;
    'exec nginx nginx -s reload') [ "${fail_reload:-0}" != 1 ] ;;
    *) echo 'unexpected Docker side effect' >&2; return 1 ;;
  esac
}
ss() {
  if [ "${occupied:-0}" = 1 ]; then echo 'LISTEN 0 100 0.0.0.0:8443 0.0.0.0:* users:(("other",pid=456,fd=1))'; fi
  if [ "${own_listener:-0}" = 1 ]; then echo 'LISTEN 0 100 0.0.0.0:8443 0.0.0.0:* users:(("nginx",pid=123,fd=1))'; fi
}
flock() { [ "${fail_lock:-0}" != 1 ]; }
open_port() { echo "$1" > "$fixture/open-port"; }
linux_ldnmp() {
  yuming="$KJ_WEB_DOMAIN"
  install_ssltls
  certs_status
  check_ip_and_get_access_port "$yuming"
  [ -z "$access_port" ]
  template > "$fixture/web/conf.d/$yuming.conf"
  nginx_http_on
  if [ "${stop_nginx:-0}" = 1 ]; then touch "$fixture/stopped"; return 1; fi
  nginx_web_on > "$fixture/address"
}
conf="$fixture/web/conf.d/example.com.conf"
kpanel_run_http_site 8443 static-site example.com
grep -Fx 'http://example.com:8443' "$fixture/address"
grep -Fx '    listen 8443;' "$conf"
grep -Fx '    listen [::]:8443;' "$conf"
grep -F 'proxy_set_header Host $http_host;' "$conf"
if grep -E '^[[:space:]]*(ssl_|listen (80|443)|add_header Alt-Svc|return 301 https)' "$conf"; then exit 1; fi
cp "$conf" "$fixture/valid.conf"
if kpanel_run_http_site 9443 static-site example.com; then exit 1; fi
cmp "$conf" "$fixture/valid.conf"
rm "$conf"
for bad in 0 65536 abc -1 '80;id' 000080; do
  if kpanel_run_http_site "$bad" static-site example.com; then exit 1; fi
done
if kpanel_run_http_site 8443 arbitrary example.com; then exit 1; fi
if KJ_WEB_CERTIFICATE_FILE=/tmp/key kpanel_run_http_site 8443 static-site example.com; then exit 1; fi
for flag in fail_test fail_reload fail_lock missing_listener occupied stop_nginx; do
  export "$flag=1"
  if kpanel_run_http_site 8443 static-site example.com; then exit 1; fi
  [ ! -e "$conf" ]
  [ ! -e "$fixture/stopped" ]
  unset "$flag"
done
own_listener=1 kpanel_run_http_site 8443 static-site example.com
rm "$conf"
if network_mode=bridge kpanel_run_http_site 8443 static-site example.com; then exit 1; fi
[ ! -e "$conf" ]
network_mode=bridge mapped=1 kpanel_run_http_site 8443 static-site example.com
rm "$conf"
# The ordinary path must leave the domain template byte-for-byte unchanged.
template > "$conf"
cp "$conf" "$fixture/legacy.conf"
yuming=example.com
nginx_http_on
cmp "$conf" "$fixture/legacy.conf"
if kpanel_web_http_mode; then exit 1; fi
printf 'http_site_validation_conversion_rollback_legacy=pass\n'
