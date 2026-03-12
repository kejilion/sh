#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-api-protocol-test-$$"
mkdir -p "$WORKDIR/bin" "$WORKDIR/home/.openclaw"
KEEP_WORKDIR=${KEEP_WORKDIR:-false}
trap '[ "$KEEP_WORKDIR" = "true" ] || rm -rf "$WORKDIR"' EXIT

# 抽取 OpenClaw API 添加逻辑
cat > "$WORKDIR/harness.sh" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
break_end() { return 0; }
send_stats() { return 0; }
start_gateway() { return 0; }
install() { return 0; }
EOF_INNER

awk 'BEGIN{p=0}
 /openclaw_probe_api_endpoint\(\) \{/{p=1}
 /openclaw_api_manage_list\(\) \{/{p=0}
 p{print}
' "$SCRIPT" >> "$WORKDIR/harness.sh"

awk 'BEGIN{p=0}
 /openclaw_detect_api_protocol_by_provider\(\) \{/{p=1}
 /fix-openclaw-provider-protocol-interactive\(\) \{/{p=0}
 p{print}
' "$SCRIPT" >> "$WORKDIR/harness.sh"

chmod +x "$WORKDIR/harness.sh"

# stub: curl
cat > "$WORKDIR/bin/curl" <<'EOF_INNER'
#!/usr/bin/env bash
set -e
args="$*"
# write body to stdout when /models
if [[ "$args" == *"/models"* ]]; then
  cat <<'JSON'
{"data": [{"id": "gpt-4o"}, {"id": "gpt-4o-mini"}]}
JSON
  exit 0
fi
# emulate POST /responses = 404, /chat/completions = 200
if [[ "$args" == *"/responses"* ]]; then
  printf "404"
  exit 0
fi
if [[ "$args" == *"/chat/completions"* ]]; then
  printf "200"
  exit 0
fi
printf "000"
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/curl"

# stub: jq (passthrough for system jq)
# rely on system jq if available

export HOME="$WORKDIR/home"
export PATH="$WORKDIR/bin:$PATH"
export TERM=xterm

# case 1: responses 不可用但 chat/completions 可用，仍应写 openai-completions
cat > "$HOME/.openclaw/openclaw.json" <<'JSON'
{
  "models": {
    "mode": "merge",
    "providers": {}
  },
  "agents": {
    "defaults": {
      "models": {}
    }
  }
}
JSON

source "$WORKDIR/harness.sh"

add-all-models-from-provider "demo" "https://api.example.com/v1" "sk-test"

python3 - <<'PY'
import json, os, sys
path = os.path.expanduser('~/.openclaw/openclaw.json')
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
prov = data.get('models', {}).get('providers', {}).get('demo', {})
api = prov.get('api')
if api != 'openai-completions':
    raise SystemExit(f'api mismatch: {api}')
print('SMOKE_OK: detect fallback to openai-completions')
PY

# case 2: 已写入 openai-chat-completions 的配置，修复后必须落回合法协议
cat > "$HOME/.openclaw/openclaw.json" <<'JSON'
{
  "models": {
    "mode": "merge",
    "providers": {
      "demo": {
        "api": "openai-chat-completions",
        "baseUrl": "http://127.0.0.1:1",
        "apiKey": "sk-test",
        "models": [
          {
            "id": "gpt-4o",
            "name": "demo / gpt-4o",
            "input": ["text"],
            "contextWindow": 1,
            "maxTokens": 1,
            "cost": {"input": 0, "output": 0, "cacheRead": 0, "cacheWrite": 0}
          }
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "models": {
        "demo/gpt-4o": {}
      }
    }
  }
}
JSON

openclaw_detect_api_protocol_by_provider "$HOME/.openclaw/openclaw.json" "demo"

python3 - <<'PY'
import json, os, sys
path = os.path.expanduser('~/.openclaw/openclaw.json')
with open(path, 'r', encoding='utf-8') as f:
    data = json.load(f)
api = data.get('models', {}).get('providers', {}).get('demo', {}).get('api')
if api not in ('openai-completions', 'openai-responses'):
    raise SystemExit(f'protocol fix mismatch: {api}')
print('SMOKE_OK: protocol repair corrected openai-chat-completions')
PY
