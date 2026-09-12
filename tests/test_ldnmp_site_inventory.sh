#!/usr/bin/env bash
set -euo pipefail
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT
export TZ=UTC
mkdir -p "$fixture/web/conf.d" "$fixture/web/certs"
sed -n '/^ldnmp_site_config_files() {/,/^ldnmp_web_status() {/p' "$root/kejilion.sh" |
  sed '$d' | sed "s|/home/web|$fixture/web|g" > "$fixture/functions"
source "$fixture/functions"
[ "$(ldnmp_site_count)" = 0 ]
ldnmp_site_table > "$fixture/empty"
[ "$(wc -l < "$fixture/empty")" = 1 ]

cat > "$fixture/web/conf.d/domain.conf" <<'EOF'
# listen 443 ssl; server_name wrong.example;
server { listen 8443; listen [::]:8443; server_name example.com www.example.com; }
EOF
cat > "$fixture/web/conf.d/192.168.1.10_8080.conf" <<'EOF'
server { listen 192.168.1.10:8080; listen [::]:8080; server_name 192.168.1.10; }
EOF
cat > "$fixture/web/conf.d/external_bundle.conf" <<'EOF'
upstream backend { server 127.0.0.1:3000; }
server { listen 8081; server_name first.example; location / { proxy_pass http://backend; } }
server { listen 9443 ssl; listen 9443 quic; server_name second.example;
  ssl_certificate /etc/nginx/certs/custom.pem; }
server { listen 8082; server_name first.example; }
EOF
cat > "$fixture/web/conf.d/legacy.conf" <<'EOF'
server {
  listen 80;
  listen 443 ssl;
  server_name legacy.example;
  ssl_certificate /etc/nginx/certs/custom.pem;
  if ($scheme = http) { return 301 https://$host$request_uri; }
}
EOF
cat > "$fixture/web/conf.d/quoted.conf" <<'EOF'
server {
  set $other ${host};
  location / { return 200 "}"; }
  add_header X-Text 'listen 443 ssl; server_name false.example;';
  listen 9090;
  server_name "quoted.example";
}
EOF
cat > "$fixture/web/conf.d/ipv6.conf" <<'EOF'
server { listen [::]:8888; server_name 2001:db8::10; }
EOF
cat > "$fixture/web/conf.d/include.conf" <<'EOF'
server { server_name included.example; include /etc/nginx/listeners.inc; }
EOF
cat > "$fixture/web/conf.d/default-port.conf" <<'EOF'
server { server_name default-port.example; }
EOF
cat > "$fixture/web/conf.d/wildcard.conf" <<'EOF'
server { listen 8088; server_name _; }
EOF
cat > "$fixture/web/conf.d/socket.conf" <<'EOF'
server { listen unix:/run/nginx.sock; server_name socket.example; }
EOF
cat > "$fixture/web/conf.d/missing-cert.conf" <<'EOF'
server { listen 9444 ssl; server_name missing.example; ssl_certificate /missing.pem; }
EOF
cat > "$fixture/web/conf.d/unparsed.conf" <<'EOF'
include /etc/nginx/external-server.conf;
EOF
touch "$fixture/web/conf.d/default.conf" "$fixture/web/conf.d/map.conf"
mkdir "$fixture/web/conf.d/not-a-file.conf"
if ! MSYS2_ARG_CONV_EXCL='/CN=' openssl req -x509 -newkey rsa:2048 -nodes -subj /CN=legacy.example -days 2 \
  -keyout "$fixture/key.pem" -out "$fixture/web/certs/custom.pem" > "$fixture/openssl.log" 2>&1; then
  cat "$fixture/openssl.log" >&2; exit 1
fi
cp "$fixture/web/certs/custom.pem" "$fixture/web/certs/orphan_cert.pem"
before="$(sha256sum "$fixture/web/conf.d/"*.conf 2>/dev/null || true)"
count=$(ldnmp_site_count)
[ "$count" = 12 ] || { echo "wrong site count: $count"; exit 1; }
ldnmp_site_table > "$fixture/table"
cat "$fixture/table"
grep -F 'http://example.com:8443' "$fixture/table"
grep -F 'http://192.168.1.10:8080' "$fixture/table"
grep -F 'http://first.example:8081' "$fixture/table"
grep -F 'http://first.example:8082' "$fixture/table"
grep -F 'https://second.example:9443' "$fixture/table"
grep -F 'http://legacy.example:80' "$fixture/table"
grep -F 'https://legacy.example:443' "$fixture/table"
grep -F 'http://quoted.example:9090' "$fixture/table"
grep -F 'http://[2001:db8::10]:8888' "$fixture/table"
grep -F 'http://default-port.example:80' "$fixture/table"
grep -F '监听待确认（include）' "$fixture/table"
grep -F 'HTTP :8088（server_name 待确认）' "$fixture/table"
grep -F 'Unix socket（无 TCP 端口）' "$fixture/table"
grep -F 'https://missing.example:9444' "$fixture/table" | grep -F '证书未找到/待确认'
[ "$(grep -c 'http://example.com:8443' "$fixture/table")" = 1 ]
[ "$(grep -c 'https://second.example:9443' "$fixture/table")" = 1 ]
[ "$(grep -c 'http://192.168.1.10:8080' "$fixture/table")" = 1 ]
! grep -Eq 'wrong.example|false.example|orphan|not-a-file|http://included.example:80' "$fixture/table"
expected_date=$(date -d "$(openssl x509 -noout -enddate -in "$fixture/web/certs/custom.pem" | cut -d= -f2-)" '+%Y-%m-%d')
grep -F 'https://second.example:9443' "$fixture/table" | grep -F "$expected_date"
grep -F 'https://legacy.example:443' "$fixture/table" | grep -F "$expected_date"
after="$(sha256sum "$fixture/web/conf.d/"*.conf 2>/dev/null || true)"
[ "$before" = "$after" ]

cat > "$fixture/inherited.conf" <<'EOF'
http {
  ssl on;
  ssl_certificate /etc/nginx/certs/shared.pem;
  server { listen 9443; server_name inherited.example; }
  server { listen 8080; ssl off; server_name explicit-http.example; }
}
EOF
ldnmp_site_config_endpoints "$fixture/inherited.conf" > "$fixture/inherited"
grep -Fx $'https://inherited.example:9443\t/etc/nginx/certs/shared.pem' "$fixture/inherited"
grep -Fx $'http://explicit-http.example:8080\t-' "$fixture/inherited"

# Exercise both existing menu surfaces with read-only stubs and exit selection 0.
for name in ldnmp_web_status ldnmp_tato; do
  sed -n "/^$name() {/,/^}/p" "$root/kejilion.sh" |
    sed "s|/home/web|$fixture/web|g" >> "$fixture/menus"
done
source "$fixture/menus"
gl_lv='' gl_bai='' gl_huang='' gl_hui=''
root_use() { :; }; clear() { :; }; send_stats() { :; }; ldnmp_v() { :; }
docker() { case "$*" in ps*) echo nginx ;; *) printf 'Database\nmysql\napp_db\n' ;; esac; }
printf 'MYSQL_ROOT_PASSWORD: test-only\n' > "$fixture/web/docker-compose.yml"
ldnmp_web_status <<< 0 > "$fixture/menu"
grep -F '站点: 12（按配置文件计数）' "$fixture/menu"
grep -F 'http://example.com:8443' "$fixture/menu"
ldnmp_tato > "$fixture/overview"
grep -F '站点: 12' "$fixture/overview"
printf 'site_inventory_http_tls_imports_counts_expiry_read_only_and_menus=pass\n'
