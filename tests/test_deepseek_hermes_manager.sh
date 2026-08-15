#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "${temporary_dir}"' EXIT

export HOME="${temporary_dir}/home"
export HERMES_HOME="${HOME}/.hermes"
export PATH="${temporary_dir}/bin:${PATH}"
export MOCK_HERMES_LOG="${temporary_dir}/hermes.log"
mkdir -p "$HERMES_HOME" "${temporary_dir}/bin"

cat >"${temporary_dir}/bin/hermes" <<'MOCK'
#!/bin/bash
printf '%s\n' "$*" >>"$MOCK_HERMES_LOG"
if [ "$*" = "config get model.default" ]; then
	printf '%s\n' 'deepseek-v4-pro'
fi
MOCK
chmod +x "${temporary_dir}/bin/hermes"

# shellcheck source=../deepseek_hermes_manager.sh
source "${project_root}/deepseek_hermes_manager.sh"

printf '%s\n' 'OTHER_KEY=keep-me' >"$HERMES_ENV_FILE"
write_deepseek_api_key 'sk-test-secret-1234'
grep -qxF 'OTHER_KEY=keep-me' "$HERMES_ENV_FILE"
grep -qxF 'DEEPSEEK_API_KEY=sk-test-secret-1234' "$HERMES_ENV_FILE"
[ "$(stat -c '%a' "$HERMES_ENV_FILE")" = "600" ]
[ "$(mask_api_key 'sk-test-secret-1234')" = 'sk-****1234' ]

delete_deepseek_api_key
grep -qxF 'OTHER_KEY=keep-me' "$HERMES_ENV_FILE"
if grep -q '^DEEPSEEK_API_KEY=' "$HERMES_ENV_FILE"; then
	echo 'FAIL: DeepSeek API key was not deleted' >&2
	exit 1
fi

apply_deepseek_model 'deepseek-v4-flash'
grep -qxF 'config set model.provider deepseek' "$MOCK_HERMES_LOG"
grep -qxF 'config set model.default deepseek-v4-flash' "$MOCK_HERMES_LOG"
grep -qxF 'config set model.base_url https://api.deepseek.com' "$MOCK_HERMES_LOG"

if hermes_running; then
	echo 'FAIL: stopped gateway was reported as running by the pgrep fallback' >&2
	exit 1
fi

echo 'PASS: DeepSeek Hermes manager smoke tests'
