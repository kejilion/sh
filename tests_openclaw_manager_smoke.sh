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
EOF
sed -n '10053,10162p' "$SCRIPT" >> "$WORKDIR/harness.sh"
printf '\n' >> "$WORKDIR/harness.sh"
sed -n '10562,10610p' "$SCRIPT" >> "$WORKDIR/harness.sh"
printf '\n' >> "$WORKDIR/harness.sh"
chmod +x "$WORKDIR/harness.sh"

cat > "$WORKDIR/bin/curl" <<'EOF'
#!/usr/bin/env bash
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
if [[ "${1:-}" == "dashboard" ]]; then
  echo "Dashboard: http://127.0.0.1:18789/#token=deadbeef"
else
  echo "mock openclaw $*"
fi
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

echo 'SMOKE_OK'
