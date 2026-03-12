#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$REPO_DIR/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-manager-test-$$"
mkdir -p "$WORKDIR/bin" "$WORKDIR/home/.openclaw"
trap 'rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/harness.sh" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
install() { return 0; }
break_end() { :; }
send_stats() { :; }
EOF
sed -n '10597,10766p' "$SCRIPT" >> "$WORKDIR/harness.sh"
printf '\n' >> "$WORKDIR/harness.sh"
sed -n '12815,13534p' "$SCRIPT" >> "$WORKDIR/harness.sh"
printf '\n' >> "$WORKDIR/harness.sh"
sed -n '13781,13825p' "$SCRIPT" >> "$WORKDIR/harness.sh"
printf '\n' >> "$WORKDIR/harness.sh"
chmod +x "$WORKDIR/harness.sh"

cat > "$WORKDIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
for arg in "$@"; do
  if [ "$arg" = "-I" ]; then
    exit 0
  fi
done
if [[ "$*" == *"/models"* ]]; then
  cat <<JSON
{"data":[{"id":"gpt-5.4"},{"id":"gpt-5.3-codex"},{"id":"claude-opus-4-6-thinking"}]}
JSON
else
  echo "US"
fi
EOF
chmod +x "$WORKDIR/bin/curl"

cat > "$WORKDIR/bin/openclaw" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cmd="${1:-}"
shift || true
log_file="$HOME/.openclaw/mock_openclaw.log"
echo "openclaw $cmd $*" >> "$log_file"
case "$cmd" in
  dashboard)
    echo "Dashboard: http://127.0.0.1:18789/#token=deadbeef"
    ;;
  config)
    sub="${1:-}"
    shift || true
    config_file="$HOME/.openclaw/mock_config.env"
    touch "$config_file"
    case "$sub" in
      set)
        key="$1"
        shift || true
        value="$*"
        grep -v "^${key}=" "$config_file" > "${config_file}.tmp" || true
        echo "${key}=${value}" >> "${config_file}.tmp"
        mv "${config_file}.tmp" "$config_file"
        ;;
      get)
        key="$1"
        if grep -q "^${key}=" "$config_file"; then
          awk -F'=' -v k="$key" '$1==k {print substr($0, index($0, "=")+1); exit}' "$config_file"
        fi
        ;;
      unset)
        key="$1"
        grep -v "^${key}=" "$config_file" > "${config_file}.tmp" || true
        mv "${config_file}.tmp" "$config_file"
        ;;
      *)
        echo "mock openclaw config $sub $*"
        ;;
    esac
    ;;
  memory)
    sub="${1:-}"
    shift || true
    case "$sub" in
      status)
        echo "Provider: builtin"
        echo "Vector: ok"
        echo "Indexed: 0/0"
        echo "Workspace: $HOME/.openclaw/workspace"
        ;;
      index)
        echo "mock memory index $*"
        ;;
      *)
        echo "mock openclaw memory $sub $*"
        ;;
    esac
    ;;
  gateway)
    sub="${1:-}"
    shift || true
    if [ "$sub" = "restart" ]; then
      echo "mock gateway restart"
    else
      echo "mock openclaw gateway $sub $*"
    fi
    ;;
  *)
    echo "mock openclaw $cmd $*"
    ;;
esac
EOF
chmod +x "$WORKDIR/bin/openclaw"

export HOME="$WORKDIR/home"
export PATH="$WORKDIR/bin:$PATH"
cat > "$HOME/.openclaw/openclaw.json" <<'JSON'
{"models":{"mode":"merge","providers":{}}}
JSON

mkdir -p /home/web/conf.d
cat > /home/web/conf.d/test-openclaw.conf <<'EOF'
server {
  listen 443 ssl;
  server_name claw.example.com;
  location / {
    proxy_pass http://127.0.0.1:18789;
  }
}
EOF

source "$WORKDIR/harness.sh"

echo '[TEST] add-all-models-from-provider'
add-all-models-from-provider "cli-api" "https://example.com/v1" "dummy-token" >/tmp/add-models.out
jq -e '.models.providers["cli-api"].models | length == 3' "$HOME/.openclaw/openclaw.json" >/dev/null
jq -r '.models.providers["cli-api"].models[].id' "$HOME/.openclaw/openclaw.json"

echo '[TEST] openclaw_find_webui_domain'
openclaw_find_webui_domain

echo '[TEST] openclaw_show_webui_addr'
openclaw_show_webui_addr

echo '[TEST] openclaw_memory_auto_setup_run local'
mkdir -p "$HOME/.openclaw/models/embedding"
touch "$HOME/.openclaw/models/embedding/embeddinggemma-300M-Q8_0.gguf"
echo "memory.local=legacy" > "$HOME/.openclaw/mock_config.env"
printf "yes\n" | openclaw_memory_auto_setup_run "local" >/tmp/memory-auto.out

grep -q '^memory.backend=builtin' "$HOME/.openclaw/mock_config.env"
grep -q '^agents.defaults.memorySearch.provider=local' "$HOME/.openclaw/mock_config.env"
if grep -q '^memory.local=' "$HOME/.openclaw/mock_config.env"; then
  echo "memory.local should be removed"
  exit 1
fi

grep -q 'openclaw memory index --force' "$HOME/.openclaw/mock_openclaw.log"
grep -q 'openclaw gateway restart' "$HOME/.openclaw/mock_openclaw.log"

echo 'SMOKE_OK'
