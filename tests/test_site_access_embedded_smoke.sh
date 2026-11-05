#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d /tmp/kpanel-site-access-smoke.XXXXXXXX)"
trap 'rm -rf -- "$fixture"' EXIT
mkdir -p "$fixture/web/conf.d"
cat > "$fixture/web/conf.d/example.com.conf" <<'EOF'
server { location /admin/ { proxy_pass http://app; auth_basic "Private"; auth_basic_user_file /etc/nginx/conf.d/.users; } }
EOF
printf 'alice:oldhash\n' > "$fixture/web/conf.d/.users"
config_version="$(sha256sum "$fixture/web/conf.d/example.com.conf" | cut -d' ' -f1)"
file_version="$(sha256sum "$fixture/web/conf.d/.users" | cut -d' ' -f1)"
sed -n '/^# BEGIN GENERATED SITE ACCESS ADAPTER$/,/^# END GENERATED SITE ACCESS ADAPTER$/p' "$root/kejilion.sh" |
  sed "s|os.open('/home/web',|os.open('$fixture/web',|" > "$fixture/adapter.sh"
source "$fixture/adapter.sh"
printf '{"operation":"update","configName":"example.com.conf","configVersion":"%s","fileVersion":"%s","serverIndex":0,"scope":"location","path":"/admin/","modifier":"","username":"bob","previousUsername":"alice","password":"synthetic-secret"}' "$config_version" "$file_version" > "$fixture/request"
KJ_WEB_NONINTERACTIVE=1 kpanel_web_access_password < "$fixture/request" > "$fixture/receipt"
grep -Fq '"ok":true' "$fixture/receipt"
grep -Fq 'bob:$apr1$' "$fixture/web/conf.d/.users"
if grep -Fq 'synthetic-secret' "$fixture/receipt" "$fixture/web/conf.d/.users"; then exit 1; fi
if KJ_WEB_NONINTERACTIVE=1 kpanel_web_access_password < "$fixture/request" > "$fixture/stale"; then exit 1; fi
grep -Fq '"ok":false' "$fixture/stale"
echo 'PASS: embedded site-access adapter updates an account and rejects stale input'
