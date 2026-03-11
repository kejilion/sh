#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "$0")" && pwd)"
SCRIPT="$REPO_DIR/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-api-sync-diff-test-$$"
mkdir -p "$WORKDIR/bin" "$WORKDIR/home/.openclaw"
KEEP_WORKDIR=${KEEP_WORKDIR:-false}
trap '[ "$KEEP_WORKDIR" = "true" ] || rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/harness.sh" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
break_end() { return 0; }
send_stats() { return 0; }
start_gateway() { return 0; }
install() { return 0; }
EOF_INNER

awk 'BEGIN{p=0}
 /sync_openclaw_api_models\(\) \{/{p=1}
 /install_moltbot\(\) \{/{p=0}
 p{print}
' "$SCRIPT" >> "$WORKDIR/harness.sh"
chmod +x "$WORKDIR/harness.sh"


cat > "$WORKDIR/bin/python3" <<'EOF_INNER'
#!/usr/bin/env bash
if [[ "$1" != "-" ]]; then
  exec /usr/bin/python3 "$@"
fi
SCRIPT=$(cat)
export SCRIPT
/usr/bin/python3 - "${@:2}" <<"PY_STDIN"
import io
import json
import os
import urllib.request
import urllib.error

class _Resp(io.BytesIO):
    def __init__(self, data, code=200):
        super().__init__(data)
        self._code = code
    def getcode(self):
        return self._code
    def __enter__(self):
        return self
    def __exit__(self, exc_type, exc, tb):
        return False

_real = urllib.request.urlopen

def urlopen(req, timeout=0):
    url = getattr(req, "full_url", "") or getattr(req, "get_full_url", lambda: "")()
    if url.endswith("/models"):
        data = json.dumps({"data": [{"id": "alpha"}, {"id": "beta"}]}).encode("utf-8")
        return _Resp(data, 200)
    if url.endswith("/responses") or url.endswith("/chat/completions"):
        raise urllib.error.HTTPError(url, 404, "Not Found", {}, None)
    return _real(req, timeout=timeout)

urllib.request.urlopen = urlopen
script = os.environ.get("SCRIPT", "")
exec(compile(script, "<stdin>", "exec"))
PY_STDIN
exit $?
EOF_INNER
chmod +x "$WORKDIR/bin/python3"

cat > "$WORKDIR/bin/curl" <<'EOF_INNER'
#!/usr/bin/env bash
# fake curl for /models, /responses, /chat/completions (for shell probes)
set -e
args="$*"
if [[ "$args" == *"/responses"* ]]; then
  printf "404"
  exit 0
fi
if [[ "$args" == *"/chat/completions"* ]]; then
  printf "404"
  exit 0
fi
printf "000"
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/curl"

export HOME="$WORKDIR/home"
export PATH="$WORKDIR/bin:$PATH"
export TERM=xterm
export ENABLE_STATS=false
export sh_v=testing

cat > "$HOME/.openclaw/openclaw.json" <<'JSON'
{
  "models": {
    "mode": "merge",
    "providers": {
      "demo": {
        "api": "openai-completions",
        "baseUrl": "https://api.example.com/v1",
        "apiKey": "sk-test",
        "models": [
          {"id": "alpha", "name": "demo / alpha"},
          {"id": "gamma", "name": "demo / gamma"}
        ]
      }
    }
  },
  "agents": {
    "defaults": {
      "models": {
        "demo/alpha": {},
        "demo/gamma": {}
      },
      "model": "demo/alpha"
    }
  }
}
JSON

source "$WORKDIR/harness.sh"

output=$(sync_openclaw_api_models 2>&1 || true)

printf '%s\n' "$output" | grep -q "➕ 新增模型(1):"
printf '%s\n' "$output" | grep -q "^  + beta$"
printf '%s\n' "$output" | grep -q "➖ 删除模型(1):"
printf '%s\n' "$output" | grep -q "^  - gamma$"

printf '%s\n' "SMOKE_OK"
