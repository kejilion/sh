#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture=$(mktemp -d)
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/web/html" "$fixture/web/conf.d"
sed -n '/^ldnmp_fastadmin() (/,/^)/p' "$root/kejilion.sh" |
  sed "s|/home/web|$fixture/web|g" > "$fixture/functions"
source "$fixture/functions"
gh_proxy=""
add_yuming() { yuming=admin.example.com; }
ldnmp_install_status() { :; }
install_ssltls() { :; }
certs_status() { :; }
add_db() { dbname=fastadmin_test; dbuse=test; dbusepasswd=test; }
normalize_ldnmp_site_permissions() { :; }
kpanel_web_http_mode() { [ "${http_mode:-0}" = 1 ]; }
nginx_http_on() { :; }
docker() {
  if [ "$1 $2 $3" = 'exec php74 php' ]; then [ "${missing_php:-0}" != 1 ]; return; fi
  if [ "$*" = 'exec nginx nginx -t' ]; then [ "${invalid_nginx:-0}" != 1 ]; return; fi
  return 0
}
curl() {
  [ "${fail_download:-0}" != 1 ] || return 22
  [ "${*: -2:1}" = -o ]
  printf archive > "${*: -1}"
}
sha256sum() {
  local input; input=$(cat)
  [ "${bad_checksum:-0}" != 1 ] || return 1
  if [[ "$input" = *site.conf* ]]; then [ "${bad_template_checksum:-0}" != 1 ]; fi
}
unzip() {
  [ "${fail_unpack:-0}" != 1 ] || return 1
  local target="${*: -1}" file
  mkdir -p "$target/public/assets/libs" "$target/thinkphp" "$target/vendor" "$target/application"
  for file in public/index.php public/install.php thinkphp/base.php vendor/autoload.php application/database.php; do
    touch "$target/$file"
  done
  mkdir -p "$target/thinkphp/library/think/config/driver"
  printf '%s\n' '<?php $env = parse_ini_file(ROOT_PATH . '\''.env'\'', true);' > "$target/thinkphp/base.php"
  printf '%s\n' '<?php return parse_ini_file($config, true);' > "$target/thinkphp/library/think/config/driver/Ini.php"
  [ "${incomplete_package:-0}" != 1 ] || rm "$target/vendor/autoload.php"
}
wget() {
  [ "$4" = "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/c830bf34ae6da8e183b4892860fbce30ea6dc651/fastadmin.com.conf" ] || return 9
  [ "${fail_template:-0}" != 1 ] || return 8
  cat > "$3" <<'EOF'
server {
    root /var/www/html/yuming.com/public;
    fastcgi_pass unix:/run/php74/php-fpm.sock;
}
EOF
}
conf="$fixture/web/conf.d/admin.example.com.conf"
site="$fixture/web/html/admin.example.com"
for flag in missing_php fail_download bad_checksum fail_unpack incomplete_package fail_template bad_template_checksum; do
  if (export "$flag=1"; ldnmp_fastadmin); then echo "accepted $flag" >&2; exit 1; fi
  [ ! -e "$conf" ] && [ ! -e "$site" ]
  [ -z "$(find "$fixture/web" -maxdepth 1 -name '.fastadmin.*' -print)" ]
done
ldnmp_fastadmin > "$fixture/success"
grep -F 'https://admin.example.com/install.php' "$fixture/success"
grep -F 'root /var/www/html/admin.example.com/public;' "$conf"
grep -F 'parse_ini_string(file_get_contents(' "$site/thinkphp/base.php"
cp "$conf" "$fixture/original.conf"
if ldnmp_fastadmin; then echo 'overwrote existing site' >&2; exit 1; fi
cmp "$conf" "$fixture/original.conf"
rm -rf -- "$site" "$conf"
if invalid_nginx=1 ldnmp_fastadmin; then echo 'accepted invalid Nginx' >&2; exit 1; fi
[ ! -e "$conf" ] && [ -f "$site/public/index.php" ]
rm -rf -- "$site"
http_mode=1 KJ_WEB_HTTP_PORT=8088 ldnmp_fastadmin > "$fixture/http"
grep -F 'http://admin.example.com:8088/install.php' "$fixture/http"
# Both native entry points and the KPanel HTTP/document-root paths must dispatch menu 10.
grep -F 'kpanel_run_web_recipe_cli 10 "$@"' "$root/kejilion.sh"
grep -F 'fastadmin) selector=10' "$root/kejilion.sh"
printf 'fastadmin_php74_download_failure_rollback_dispatch=pass\n'
