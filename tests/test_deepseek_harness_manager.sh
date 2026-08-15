#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "${temporary_dir}"' EXIT

export DSH_HOME="${temporary_dir}/dsh-home"
export DSH_ENV_FILE="${DSH_HOME}/kejilion.env"
export MODEL_PATCH_FILE="${DSH_HOME}/kejilion-model.patch.yml"
export DEEPSEEK_HARNESS_SERVICE_FILE="${temporary_dir}/deepseek-harness.service"
export DEEPSEEK_HARNESS_PID_FILE="${temporary_dir}/deepseek-harness.pid"
export DEEPSEEK_HARNESS_LOG_FILE="${temporary_dir}/deepseek-harness.log"
export DEEPSEEK_HARNESS_APP_MARKER_FILE="${temporary_dir}/appno.txt"
export DEEPSEEK_HARNESS_WEBUI_DOMAINS_FILE="${DSH_HOME}/kejilion-webui-domains"
export DEEPSEEK_HARNESS_WEB_CONF_DIR="${temporary_dir}/web/conf.d"
export DEEPSEEK_HARNESS_WEB_CERT_DIR="${temporary_dir}/web/certs"
export DEEPSEEK_HARNESS_K_COMMAND="k"
export MOCK_NPM_ARGS_LOG="${temporary_dir}/npm-args.log"
export MOCK_K_ARGS_LOG="${temporary_dir}/k-args.log"
export MOCK_DOCKER_ARGS_LOG="${temporary_dir}/docker-args.log"
export PATH="${temporary_dir}/bin:${PATH}"
mkdir -p "${temporary_dir}/bin" "$DSH_HOME" "$DEEPSEEK_HARNESS_WEB_CONF_DIR" "$DEEPSEEK_HARNESS_WEB_CERT_DIR"

catalog_entry='115. ${color115}Hermes机器人管理工具${gl_huang}★${gl_bai}               ${gl_kjlan}116. ${color116}DeepSeek Harness管理工具${gl_huang}★${gl_bai}'
for catalog_file in "${project_root}/kejilion.sh" "${project_root}/cn/kejilion.sh"; do
	if ! grep -Fq "$catalog_entry" "$catalog_file"; then
		echo "FAIL: DeepSeek Harness catalog description or alignment is incorrect in ${catalog_file}" >&2
		exit 1
	fi
done

cat >"${temporary_dir}/bin/dsh" <<'MOCK'
#!/bin/bash
if [ "$*" = "--version" ]; then
	printf '%s\n' '0.1.0-rc.6'
fi
MOCK
cat >"${temporary_dir}/bin/node" <<'MOCK'
#!/bin/bash
printf '%s\n' '24.18.0'
MOCK
cat >"${temporary_dir}/bin/npm" <<'MOCK'
#!/bin/bash
if [ "${1:-}" = "--version" ]; then
	printf '%s\n' "${MOCK_NPM_VERSION:-11.16.0}"
	exit 0
fi
printf '%s\n' "$@" >"$MOCK_NPM_ARGS_LOG"
MOCK
cat >"${temporary_dir}/bin/systemctl" <<'MOCK'
#!/bin/bash
if [ "$*" = "daemon-reload" ]; then
	exit 0
fi
exit 1
MOCK
cat >"${temporary_dir}/bin/curl" <<'MOCK'
#!/bin/bash
exit 1
MOCK
cat >"${temporary_dir}/bin/openssl" <<'MOCK'
#!/bin/bash
if [ "$*" = "passwd -apr1 -stdin" ]; then
	read -r password
	[ -n "$password" ] || exit 1
	printf '%s\n' '$apr1$mock$hashed-password'
	exit 0
fi
exit 1
MOCK
cat >"${temporary_dir}/bin/docker" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >>"$MOCK_DOCKER_ARGS_LOG"
exit 0
MOCK
cat >"${temporary_dir}/bin/k" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >>"$MOCK_K_ARGS_LOG"
[ "${1:-}" = "fd" ] || exit 1
domain="${2:-}"
host="${3:-}"
port="${4:-}"
[ -n "$domain" ] && [ "$host" = "127.0.0.1" ] && [ "$port" = "3080" ] || exit 1
cat >"$DEEPSEEK_HARNESS_WEB_CONF_DIR/${domain}.conf" <<EOF
upstream backend_mock {
    server ${host}:${port};
}
server {
    listen 443 ssl;
    server_name ${domain};
    location / {
        proxy_pass http://backend_mock;
        proxy_http_version 1.1;
        # proxy_read_timeout 1d;
        # proxy_send_timeout 1d;
    }
    location ~* \\.js$ {
        proxy_pass http://backend_mock;
        proxy_cache backend_mock;
    }
}
proxy_cache_path /var/cache/nginx/proxy/backend_mock keys_zone=backend_mock:20m;
EOF
touch "$DEEPSEEK_HARNESS_WEB_CERT_DIR/${domain}_cert.pem"
touch "$DEEPSEEK_HARNESS_WEB_CERT_DIR/${domain}_key.pem"
MOCK
chmod +x \
	"${temporary_dir}/bin/dsh" \
	"${temporary_dir}/bin/node" \
	"${temporary_dir}/bin/npm" \
	"${temporary_dir}/bin/systemctl" \
	"${temporary_dir}/bin/curl" \
	"${temporary_dir}/bin/openssl" \
	"${temporary_dir}/bin/docker" \
	"${temporary_dir}/bin/k"

# shellcheck source=../deepseek_harness_manager.sh
source "${project_root}/deepseek_harness_manager.sh"

node_version_supported
npm_allow_scripts_supported '11.16.0'
npm_allow_scripts_supported '12.0.2'
if npm_allow_scripts_supported '11.15.9'; then
	echo 'FAIL: unsupported npm version accepted allow-scripts' >&2
	exit 1
fi

export MOCK_NPM_VERSION='11.16.0'
install_dsh_npm_package
mapfile -t npm_args <"$MOCK_NPM_ARGS_LOG"
[ "${#npm_args[@]}" -eq 4 ]
[ "${npm_args[0]}" = 'install' ]
[ "${npm_args[1]}" = '-g' ]
[ "${npm_args[2]}" = '--allow-scripts=@deepseek-ai/dsh-subprocess-local,koffi,node-pty,@google/genai,protobufjs' ]
[ "${npm_args[3]}" = '@deepseek-ai/dsh@latest' ]

export MOCK_NPM_VERSION='11.15.9'
install_dsh_npm_package
mapfile -t npm_args <"$MOCK_NPM_ARGS_LOG"
[ "${#npm_args[@]}" -eq 3 ]
[ "${npm_args[0]}" = 'install' ]
[ "${npm_args[1]}" = '-g' ]
[ "${npm_args[2]}" = '@deepseek-ai/dsh@latest' ]
write_api_key 'sk-test-secret-1234'
grep -qxF 'DEEPSEEK_API_KEY=sk-test-secret-1234' "$DSH_ENV_FILE"
grep -qxF 'DEEPSEEK_BASE_URL=https://api.deepseek.com' "$DSH_ENV_FILE"
[ "$(stat -c '%a' "$DSH_ENV_FILE")" = "600" ]
[ "$(mask_api_key 'sk-test-secret-1234')" = 'sk-****1234' ]
if valid_api_key 'sk-invalid key'; then
	echo 'FAIL: unsafe API key was accepted' >&2
	exit 1
fi

delete_api_key
if grep -q '^DEEPSEEK_API_KEY=' "$DSH_ENV_FILE"; then
	echo 'FAIL: DeepSeek API key was not deleted' >&2
	exit 1
fi

write_model_patch 'deepseek-v4-pro'
grep -qxF -- '- id: agent-default-model' "$MODEL_PATCH_FILE"
grep -qxF '    provider: deepseek-official' "$MODEL_PATCH_FILE"
grep -qxF '    model: deepseek-v4-pro' "$MODEL_PATCH_FILE"
[ "$(current_model)" = 'deepseek-v4-pro' ]
[ "$(stat -c '%a' "$MODEL_PATCH_FILE")" = "600" ]

if write_model_patch $'bad\nmodel'; then
	echo 'FAIL: unsafe model id was accepted' >&2
	exit 1
fi

if harness_running; then
	echo 'FAIL: stopped Harness was reported as running' >&2
	exit 1
fi
if web_ready; then
	echo 'FAIL: unavailable Web UI was reported as ready' >&2
	exit 1
fi

configure_systemd_service
grep -Fq 'ExecStart=' "$DEEPSEEK_HARNESS_SERVICE_FILE"
grep -Fq ' web --patch ' "$DEEPSEEK_HARNESS_SERVICE_FILE"
grep -Fq ' --host 127.0.0.1 --port 3080' "$DEEPSEEK_HARNESS_SERVICE_FILE"
grep -Fq 'Environment=DSH_TELEMETRY_DISABLED=1' "$DEEPSEEK_HARNESS_SERVICE_FILE"
grep -Fq 'Environment=PATH=' "$DEEPSEEK_HARNESS_SERVICE_FILE"

valid_domain 'chat.example.com'
valid_domain 'deepseek-v4.example.com'
if valid_domain 'https://chat.example.com'; then
	echo 'FAIL: domain with scheme was accepted' >&2
	exit 1
fi
if valid_domain 'bad..example.com'; then
	echo 'FAIL: malformed domain was accepted' >&2
	exit 1
fi
if valid_domain '127.0.0.1'; then
	echo 'FAIL: IP address was accepted as a domain' >&2
	exit 1
fi

create_webui_domain 'Chat.Example.com' 'admin' 'test-password'
[ "$(cat "$MOCK_K_ARGS_LOG")" = 'fd chat.example.com 127.0.0.1 3080' ]
grep -qxF 'chat.example.com' "$DEEPSEEK_HARNESS_WEBUI_DOMAINS_FILE"
[ "$(stat -c '%a' "$DEEPSEEK_HARNESS_WEBUI_DOMAINS_FILE")" = '600' ]
webui_conf="$DEEPSEEK_HARNESS_WEB_CONF_DIR/chat.example.com.conf"
webui_auth="$DEEPSEEK_HARNESS_WEB_CONF_DIR/.deepseek-harness-chat.example.com.htpasswd"
grep -Fq '# kejilion-deepseek-harness-managed' "$webui_conf"
grep -Fq 'auth_basic "DeepSeek Harness";' "$webui_conf"
grep -Fq 'auth_basic_user_file /etc/nginx/conf.d/.deepseek-harness-chat.example.com.htpasswd;' "$webui_conf"
grep -Fq 'proxy_read_timeout 1d;' "$webui_conf"
grep -Fq 'proxy_send_timeout 1d;' "$webui_conf"
if grep -Eq '^[[:space:]]*proxy_cache[[:space:]]' "$webui_conf"; then
	echo 'FAIL: generated WebUI proxy still enables static asset cache' >&2
	exit 1
fi
grep -qxF 'admin:$apr1$mock$hashed-password' "$webui_auth"
[ "$(stat -c '%a' "$webui_auth")" = '644' ]

configure_systemd_service
grep -Fq ' --trusted-host chat.example.com' "$DEEPSEEK_HARNESS_SERVICE_FILE"

touch "$DEEPSEEK_HARNESS_WEB_CONF_DIR/existing.example.com.conf"
if create_webui_domain 'existing.example.com' 'admin' 'test-password'; then
	echo 'FAIL: existing website was overwritten' >&2
	exit 1
fi
[ "$(wc -l <"$MOCK_K_ARGS_LOG" | tr -d '[:space:]')" = '1' ]

delete_webui_domain 'chat.example.com'
[ ! -e "$webui_conf" ]
[ ! -e "$webui_auth" ]
[ ! -e "$DEEPSEEK_HARNESS_WEB_CERT_DIR/chat.example.com_cert.pem" ]
[ ! -e "$DEEPSEEK_HARNESS_WEB_CERT_DIR/chat.example.com_key.pem" ]
if grep -qxF 'chat.example.com' "$DEEPSEEK_HARNESS_WEBUI_DOMAINS_FILE"; then
	echo 'FAIL: deleted domain remains in trusted-host records' >&2
	exit 1
fi
if grep -Fq 'web del' "$MOCK_K_ARGS_LOG"; then
	echo 'FAIL: WebUI deletion called the generic site/database deletion path' >&2
	exit 1
fi
configure_systemd_service
if grep -Fq ' --trusted-host chat.example.com' "$DEEPSEEK_HARNESS_SERVICE_FILE"; then
	echo 'FAIL: deleted domain remains in the generated systemd service' >&2
	exit 1
fi

mark_app_installed
grep -qxF '116' "$DEEPSEEK_HARNESS_APP_MARKER_FILE"
unmark_app_installed
if grep -qxF '116' "$DEEPSEEK_HARNESS_APP_MARKER_FILE"; then
	echo 'FAIL: app marker was not removed' >&2
	exit 1
fi

echo 'PASS: DeepSeek Harness manager smoke tests'
