#!/usr/bin/env bash
set -eu
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d /tmp/kpanel-site-proxy-smoke.XXXXXXXX)"
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/web/conf.d" "$fixture/jobs"
cat > "$fixture/docker-bin" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  'exec nginx id -g nginx') id -g ;;
  'exec nginx head -c 1048577 /etc/nginx/nginx.conf') printf 'events {} http {}\n' ;;
  'exec -u nginx nginx sh -c '*|'exec nginx nginx -t'|'exec nginx nginx -s reload') exit 0 ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$fixture/docker-bin"
sed -n '/^# BEGIN GENERATED SITE ACCESS ADAPTER$/,/^# END GENERATED SITE ACCESS ADAPTER$/p' "$root/kejilion.sh" |
  sed -e "s|os.open('/home/web',|os.open('$fixture/web',|" -e "s|/usr/bin/docker|$fixture/docker-bin|g" > "$fixture/adapter.sh"
for name in kpanel_web_prepare_config kpanel_web_apply_created_access kpanel_web_confirm_created_access nginx_http_on update_nginx_listen_port kpanel_app_write_proxy; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh" |
    sed -e "s|/var/lib/kejilion-panel/wordpress-jobs/|$fixture/jobs/|g" -e "s|/home/web/|$fixture/web/|g" >> "$fixture/functions.sh"
done
source "$fixture/adapter.sh"
source "$fixture/functions.sh"
kpanel_web_http_mode() { return 1; }
kpanel_web_progress() { :; }
nginx_web_on() { :; }
docker() { [ "$*" = 'exec nginx nginx -s reload' ]; }
wget() {
  [ "$1" = '-O' ] || return 1
  if [ "$2" = "$fixture/web/conf.d/map.conf" ]; then : > "$2"; return 0; fi
  [ "$2" = "$fixture/web/conf.d/.site-create-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pending" ] || return 1
  [ ! -e "$fixture/web/conf.d/example.com.conf" ] || return 1
  cat > "$2" <<'EOF'
upstream backend_yuming_com {
    # 动态添加
}
server {
    server_name yuming.com;
    location / { proxy_pass http://backend_yuming_com; }
}
EOF
}
export KJ_WEB_NONINTERACTIVE=1
export KJ_WEB_ACCESS_PASSWORD_FILE="$fixture/jobs/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.access-password.json"
printf '%s' '{"operation":"create-stage","configName":"example.com.conf","scope":"server","path":"","username":"alice","password":"synthetic-secret"}' > "$KJ_WEB_ACCESS_PASSWORD_FILE"
chmod 600 "$KJ_WEB_ACCESS_PASSWORD_FILE"
yuming=example.com reverseproxy=127.0.0.1 port=3000 access_port= gh_proxy=''
kpanel_app_write_proxy
grep -Fq 'auth_basic "Restricted";' "$fixture/web/conf.d/example.com.conf"
grep -Fq 'proxy_pass http://backend_' "$fixture/web/conf.d/example.com.conf"
[ ! -e "$fixture/web/conf.d/.site-create-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.pending" ]
echo 'PASS: proxy creation stages configuration before publishing its password rule'
