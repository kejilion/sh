#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d /tmp/kpanel-site-create-smoke.XXXXXXXX)"
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/web/conf.d" "$fixture/jobs"
cat > "$fixture/docker" <<'EOF'
#!/usr/bin/env bash
case "$*" in
  'exec nginx id -g nginx') id -g ;;
  'exec nginx head -c 1048577 /etc/nginx/nginx.conf') printf 'events {} http {}\n' ;;
  'exec nginx nginx -s reload') [ ! -f "$(dirname "$0")/fail-reload" ] ;;
  'exec -u nginx nginx sh -c '*|'exec nginx nginx -t'|'exec nginx nginx -s reload') exit 0 ;;
  *) exit 1 ;;
esac
EOF
chmod +x "$fixture/docker"
export PATH="$fixture:$PATH"
sed -n '/^# BEGIN GENERATED SITE ACCESS ADAPTER$/,/^# END GENERATED SITE ACCESS ADAPTER$/p' "$root/kejilion.sh" |
  sed -e "s|os.open('/home/web',|os.open('$fixture/web',|" -e "s|/usr/bin/docker|$fixture/docker|g" > "$fixture/adapter.sh"
sed -n '/^kpanel_web_apply_created_access() {/,/^}/p' "$root/kejilion.sh" |
  sed -e "s|/var/lib/kejilion-panel/wordpress-jobs/|$fixture/jobs/|g" -e "s|/home/web/conf.d/|$fixture/web/conf.d/|g" > "$fixture/hook.sh"
sed -n '/^kpanel_web_prepare_config() {/,/^}/p' "$root/kejilion.sh" |
  sed -e "s|/var/lib/kejilion-panel/wordpress-jobs/|$fixture/jobs/|g" -e "s|/home/web/conf.d/|$fixture/web/conf.d/|g" > "$fixture/prepare.sh"
sed -n '/^kpanel_web_confirm_created_access() {/,/^}/p' "$root/kejilion.sh" |
  sed -e "s|/var/lib/kejilion-panel/wordpress-jobs/|$fixture/jobs/|g" -e "s|/home/web/conf.d/|$fixture/web/conf.d/|g" > "$fixture/confirm.sh"
sed -n '/^nginx_http_on() {/,/^}/p' "$root/kejilion.sh" > "$fixture/http.sh"
source "$fixture/adapter.sh"
source "$fixture/hook.sh"
source "$fixture/prepare.sh"
source "$fixture/confirm.sh"
source "$fixture/http.sh"
kpanel_web_http_mode() { return 1; }
export KJ_WEB_NONINTERACTIVE=1
id=aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa
export KJ_WEB_ACCESS_PASSWORD_FILE="$fixture/jobs/$id.access-password.json"
cat > "$KJ_WEB_ACCESS_PASSWORD_FILE" <<'EOF'
{"operation":"create-stage","configName":"example.com.conf","scope":"server","path":"","username":"alice","password":"synthetic-secret"}
EOF
chmod 600 "$KJ_WEB_ACCESS_PASSWORD_FILE"
yuming=example.com
chmod 777 "$fixture/web/conf.d"
if kpanel_web_prepare_config; then exit 1; fi
chmod 755 "$fixture/web/conf.d"
kpanel_web_prepare_config
printf 'server { server_name example.com; location / { proxy_pass http://app; } }\n' > "$KJ_WEB_STAGED_CONFIG"
[ ! -e "$fixture/web/conf.d/example.com.conf" ]
nginx_http_on
grep -Fq 'auth_basic "Restricted";' "$fixture/web/conf.d/example.com.conf"
grep -Fq 'proxy_pass http://app;' "$fixture/web/conf.d/example.com.conf"
touch "$fixture/fail-reload"
if kpanel_web_confirm_created_access 2> "$fixture/reload-failure.log"; then exit 1; fi
grep -Fq '访问密码的 Nginx 配置未能加载' "$fixture/reload-failure.log"
rm "$fixture/fail-reload"
kpanel_web_confirm_created_access
if grep -RFq 'synthetic-secret' "$fixture/web/conf.d"; then exit 1; fi

id=bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
export KJ_WEB_ACCESS_PASSWORD_FILE="$fixture/jobs/$id.access-password.json"
cat > "$KJ_WEB_ACCESS_PASSWORD_FILE" <<'EOF'
{"operation":"create-stage","configName":"failure.example.com.conf","scope":"location","path":"/missing/","username":"alice","password":"synthetic-secret"}
EOF
chmod 600 "$KJ_WEB_ACCESS_PASSWORD_FILE"
yuming=failure.example.com
KJ_WEB_ACCESS_PASSWORD_APPLIED=0
kpanel_web_prepare_config
printf 'server { server_name failure.example.com; location / { proxy_pass http://app; } }\n' > "$KJ_WEB_STAGED_CONFIG"
if nginx_http_on 2> "$fixture/failure.log"; then exit 1; fi
[ ! -e "$fixture/web/conf.d/failure.example.com.conf" ]
grep -Fq '访问密码配置失败' "$fixture/failure.log"
grep -Fq 'server_name failure.example.com' "$KJ_WEB_STAGED_CONFIG"

id=cccccccccccccccccccccccccccccccc
export KJ_WEB_ACCESS_PASSWORD_FILE="$fixture/jobs/$id.access-password.json"
yuming=missing.example.com
KJ_WEB_ACCESS_PASSWORD_APPLIED=0
KJ_WEB_STAGED_CONFIG=''
kpanel_web_prepare_config
printf 'server { server_name missing.example.com; }\n' > "$KJ_WEB_STAGED_CONFIG"
if nginx_http_on 2> "$fixture/missing.log"; then exit 1; fi
[ ! -e "$fixture/web/conf.d/missing.example.com.conf" ]
grep -Fq '访问密码配置失败' "$fixture/missing.log"
echo 'PASS: creation publishes only a protected configuration and retains failed staging'
