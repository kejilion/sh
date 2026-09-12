#!/usr/bin/env bash
# Run in a disposable network namespace, never against a host Nginx instance.
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
nginx_bin="${NGINX_BIN:?set NGINX_BIN to the isolated test binary}"
fixture="$(mktemp -d)"
cleanup() {
  if [ -n "${blocker_pid:-}" ]; then kill "$blocker_pid" 2>/dev/null || true; wait "$blocker_pid" 2>/dev/null || true; fi
  if [ -f "$fixture/nginx.pid" ]; then "$nginx_bin" -p "$fixture" -c nginx.conf -s quit || true; fi
  rm -rf -- "$fixture"
}
trap cleanup EXIT
mkdir -p "$fixture/web/conf.d" "$fixture/logs" "$fixture/locks"
sed -n '/^KPANEL_WEB_HTTP_PROTOCOL_VERSION=/,/^KPANEL_WEB_REDIRECT_PROTOCOL_VERSION=/p' "$root/kejilion.sh" |
  sed -e "s|/home/web|$fixture/web|g" -e "s|/run/lock|$fixture/locks|g" > "$fixture/functions"
source "$fixture/functions"
cat > "$fixture/nginx.conf" <<EOF
pid $fixture/nginx.pid;
error_log $fixture/error.log;
events {}
http {
  access_log off;
  client_body_temp_path $fixture/client_temp;
  proxy_temp_path $fixture/proxy_temp;
  fastcgi_temp_path $fixture/fastcgi_temp;
  uwsgi_temp_path $fixture/uwsgi_temp;
  scgi_temp_path $fixture/scgi_temp;
  include $fixture/web/conf.d/*.conf;
}
EOF
printf 'server { listen 18080; server_name legacy.example; location / { return 200 "legacy-ok"; } }\n' > "$fixture/web/conf.d/legacy.conf"
"$nginx_bin" -p "$fixture" -c nginx.conf
docker() {
  if [ "$*" = 'inspect --format {{.HostConfig.NetworkMode}} nginx' ]; then echo host; return $?; fi
  if [ "$*" = 'inspect --format {{.State.Running}} nginx' ]; then
    if [ -f "$fixture/nginx.pid" ] && kill -0 "$(cat "$fixture/nginx.pid")" 2>/dev/null; then echo true; else echo false; fi
    return 0
  fi
  if [ "$*" = 'top nginx -eo pid' ]; then
    printf 'PID\n'; cat "$fixture/nginx.pid"; pgrep -P "$(cat "$fixture/nginx.pid")" || true; return 0
  fi
  if [ "$*" = 'exec nginx cat /proc/net/tcp /proc/net/tcp6' ]; then cat /proc/net/tcp /proc/net/tcp6; return $?; fi
  if [ "$*" = 'start nginx' ]; then "$nginx_bin" -p "$fixture" -c nginx.conf; return $?; fi
  if [ "$1 $2 $3 $4" = 'exec nginx nginx -t' ]; then "$nginx_bin" -p "$fixture" -c nginx.conf -t; return $?; fi
  if [ "$1 $2 $3 $4 ${5:-}" = 'exec nginx nginx -s reload' ]; then "$nginx_bin" -p "$fixture" -c nginx.conf -s reload; return $?; fi
  return 1
}
open_port() { :; }
linux_ldnmp() {
  touch "$fixture/native-called"
  yuming="$KJ_WEB_DOMAIN"
  cat > "$fixture/web/conf.d/$yuming.conf" <<EOF
server {
    listen 80;
    listen 443 ssl;
    listen 443 quic;
    server_name $yuming;
    ssl_certificate /missing-cert.pem;
    ssl_certificate_key /missing-key.pem;
    if (\$scheme = http) {
        return 301 https://\$host\$request_uri;
    }
    location / { return 200 "http-port-ok"; }
}
EOF
  kpanel_web_http_config
  if [ "${simulate_failed_restart:-0}" = 1 ]; then
    "$nginx_bin" -p "$fixture" -c nginx.conf -s quit
    for attempt in {1..30}; do [ ! -f "$fixture/nginx.pid" ] && break; sleep 0.1; done
    return 1
  fi
}
wait_http() {
  local expected="$1" url="$2"
  for attempt in {1..30}; do
    if [ "$(curl --noproxy '*' -fsS --max-time 1 "$url" 2>/dev/null)" = "$expected" ]; then return 0; fi
    sleep 0.1
  done
  cat "$fixture/error.log" >&2
  return 1
}
kpanel_run_http_site 18443 static-site example.com
wait_http http-port-ok http://127.0.0.1:18443/
wait_http legacy-ok http://127.0.0.1:18080/
# Another virtual host can share Nginx's port.
kpanel_run_http_site 18443 static-site second.example.com
rm "$fixture/native-called"
# A foreign listener must fail before the native recipe can restart Nginx.
python3 -m http.server 18444 --bind 0.0.0.0 > "$fixture/blocker.log" 2>&1 &
blocker_pid=$!
for attempt in {1..30}; do
  ss -H -ltn 'sport = :18444' | grep -q . && break
  sleep 0.1
done
if kpanel_run_http_site 18444 static-site occupied.example.com; then exit 1; fi
[ ! -f "$fixture/native-called" ]
[ ! -f "$fixture/web/conf.d/occupied.example.com.conf" ]
wait_http legacy-ok http://127.0.0.1:18080/
# A failed native restart restores a previously running Nginx after cleanup.
if simulate_failed_restart=1 kpanel_run_http_site 18445 php-site failed.example.com; then exit 1; fi
[ ! -f "$fixture/web/conf.d/failed.example.com.conf" ]
wait_http legacy-ok http://127.0.0.1:18080/
wait_http http-port-ok http://127.0.0.1:18443/
rm "$fixture/web/conf.d/example.com.conf"
"$nginx_bin" -p "$fixture" -c nginx.conf -t
"$nginx_bin" -p "$fixture" -c nginx.conf -s reload
wait_http legacy-ok http://127.0.0.1:18080/
printf 'isolated_nginx_http_shared_port_conflict_restart_recovery_and_existing_site=pass\n'
