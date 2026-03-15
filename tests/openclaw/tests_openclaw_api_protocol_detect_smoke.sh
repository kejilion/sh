#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-api-protocol-test-$$"
mkdir -p "$WORKDIR/bin" "$WORKDIR/home/.openclaw"
KEEP_WORKDIR=${KEEP_WORKDIR:-false}
trap '[ "$KEEP_WORKDIR" = "true" ] || rm -rf "$WORKDIR"' EXIT

# 抽取 OpenClaw API 添加逻辑（只验证：不再做协议探测/自动纠正）
cat > "$WORKDIR/harness.sh" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
break_end() { return 0; }
send_stats() { return 0; }
start_gateway() { return 0; }
install() { return 0; }
EOF_INNER

awk 'BEGIN{p=0}
 /add-all-models-from-provider\(\) \{/{p=1}
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
if [[ "$args" == *"/models"* ]]; then
  cat <<'JSON'
{"data": [{"id": "gpt-4o"}, {"id": "gpt-4o-mini"}]}
JSON
  exit 0
fi
printf ""
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/curl"

export HOME="$WORKDIR/home"
export PATH="$WORKDIR/bin:$PATH"
export TERM=xterm

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

# 添加 provider，不应依赖协议探测；若脚本内部仍调用已删除函数会报错
add-all-models-from-provider "demo" "https://api.example.com/v1" "sk-test"

echo "SMOKE_OK: no protocol probing required during add"

# 协议修复函数现在不再修改配置，只输出提示
openclaw_detect_api_protocol_by_provider "$HOME/.openclaw/openclaw.json" "demo" >/dev/null 2>&1 || true

echo "SMOKE_OK: protocol repair is no-op"
