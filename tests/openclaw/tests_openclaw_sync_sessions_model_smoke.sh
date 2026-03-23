#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/../.." && pwd)
script="$repo_root/kejilion.sh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
export HOME="$workdir/home"
mkdir -p "$HOME/.openclaw/agents/main/sessions"
mkdir -p "$HOME/.openclaw/agents/work/sessions"

funcs_file="$workdir/funcs.sh"
{
	awk '/^[[:space:]]*openclaw_get_agents_dir\(\)/,/^[[:space:]]*\}$/' "$script"
	echo
	awk '/^[[:space:]]*openclaw_sync_sessions_model\(\)/,/^[[:space:]]*\}$/' "$script"
} > "$funcs_file"

cat > "$HOME/.openclaw/agents/main/sessions/sessions.json" <<'JSON'
{
  "agent:main:telegram:direct:123": {
    "sessionId": "abc-123",
    "modelOverride": "gpt-4",
    "providerOverride": "openai"
  },
  "agent:main:main": {
    "sessionId": "def-456"
  }
}
JSON

cat > "$HOME/.openclaw/agents/work/sessions/sessions.json" <<'JSON'
{
  "agent:work:slack:channel:C789": {
    "sessionId": "ghi-789",
    "modelOverride": "claude-3",
    "providerOverride": "anthropic"
  }
}
JSON

source "$funcs_file"
openclaw_sync_sessions_model "cli-api/gpt-5-pro"

echo "=== VERIFICATION ==="

main_file="$HOME/.openclaw/agents/main/sessions/sessions.json"
work_file="$HOME/.openclaw/agents/work/sessions/sessions.json"

main_model=$(jq -r '."agent:main:telegram:direct:123".modelOverride' "$main_file")
main_provider=$(jq -r '."agent:main:telegram:direct:123".providerOverride' "$main_file")
main2_model=$(jq -r '."agent:main:main".modelOverride' "$main_file")
main2_provider=$(jq -r '."agent:main:main".providerOverride // "null"' "$main_file")

work_model=$(jq -r '."agent:work:slack:channel:C789".modelOverride' "$work_file")
work_provider=$(jq -r '."agent:work:slack:channel:C789".providerOverride' "$work_file")

[ "$main_model" = "gpt-5-pro" ] || { echo "FAIL: main model (got: $main_model)"; exit 1; }
[ "$main_provider" = "cli-api" ] || { echo "FAIL: main provider (got: $main_provider)"; exit 1; }
[ "$main2_model" = "gpt-5-pro" ] || { echo "FAIL: main2 model (got: $main2_model)"; exit 1; }
[ "$main2_provider" = "cli-api" ] || { echo "FAIL: main2 provider (got: $main2_provider)"; exit 1; }
[ "$work_model" = "gpt-5-pro" ] || { echo "FAIL: work model (got: $work_model)"; exit 1; }
[ "$work_provider" = "cli-api" ] || { echo "FAIL: work provider (got: $work_provider)"; exit 1; }

echo "PASS: openclaw_sync_sessions_model smoke"
