#!/usr/bin/env bash
set -eu
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d /tmp/kpanel-site-wordpress-reload.XXXXXXXX)"
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/web/conf.d" "$fixture/web/html" "$fixture/jobs"
for name in kpanel_web_confirm_created_access ldnmp_wp; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh" |
    sed -e "s|/home/web/|$fixture/web/|g" -e "s|/var/lib/kejilion-panel/wordpress-jobs/|$fixture/jobs/|g" >> "$fixture/functions.sh"
done
source "$fixture/functions.sh"
clear() { :; }
kpanel_web_progress() { :; }
send_stats() { :; }
repeat_add_yuming() { :; }
ldnmp_install_status() { :; }
install_ssltls() { :; }
certs_status() { :; }
add_db() { dbname=db dbuse=user dbusepasswd=placeholder; }
kpanel_web_prepare_config() { :; }
nginx_http_on() { :; }
kpanel_web_http_mode() { return 1; }
prepare_ldnmp_site_root() { mkdir -p "$fixture/web/html/$1"; }
normalize_ldnmp_site_permissions() { :; }
patch_wp_url() { :; }
restart_ldnmp() { return 1; }
nginx_web_on() { touch "$fixture/reported-success"; }
docker() { [ "$*" = 'exec nginx nginx -t' ]; }
kpanel_web_access_password() { docker exec nginx nginx -t && docker exec nginx nginx -s reload; }
wget() { [ "$1" = '-O' ] && : > "$2"; }
unzip() { mkdir -p wordpress; : > wordpress/wp-config-sample.php; }
export KJ_WEB_ACCESS_PASSWORD_FILE="$fixture/jobs/aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa.access-password.json"
: > "$KJ_WEB_ACCESS_PASSWORD_FILE"
chmod 600 "$KJ_WEB_ACCESS_PASSWORD_FILE"
gh_proxy=''
if ldnmp_wp example.com > "$fixture/output" 2>&1; then exit 1; fi
[ ! -e "$fixture/reported-success" ]
grep -Fq '访问密码的 Nginx 配置未能加载' "$fixture/output"
echo 'PASS: WordPress does not report success when access configuration reload fails'
