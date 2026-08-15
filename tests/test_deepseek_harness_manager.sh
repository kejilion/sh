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
export PATH="${temporary_dir}/bin:${PATH}"
mkdir -p "${temporary_dir}/bin" "$DSH_HOME"

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
chmod +x "${temporary_dir}/bin/dsh" "${temporary_dir}/bin/node" "${temporary_dir}/bin/systemctl" "${temporary_dir}/bin/curl"

# shellcheck source=../deepseek_harness_manager.sh
source "${project_root}/deepseek_harness_manager.sh"

node_version_supported
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

mark_app_installed
grep -qxF '116' "$DEEPSEEK_HARNESS_APP_MARKER_FILE"
unmark_app_installed
if grep -qxF '116' "$DEEPSEEK_HARNESS_APP_MARKER_FILE"; then
	echo 'FAIL: app marker was not removed' >&2
	exit 1
fi

echo 'PASS: DeepSeek Harness manager smoke tests'
