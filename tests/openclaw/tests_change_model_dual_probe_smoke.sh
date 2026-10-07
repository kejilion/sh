#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-change-model-dual-probe-$$"
mkdir -p "$WORKDIR/home/.openclaw"
KEEP_WORKDIR=${KEEP_WORKDIR:-false}
trap '[ "$KEEP_WORKDIR" = "true" ] || rm -rf "$WORKDIR"' EXIT

python3 - "$SCRIPT" "$WORKDIR" <<'PY'
import json
import re
import sys
from pathlib import Path

script_path = Path(sys.argv[1])
workdir = Path(sys.argv[2])
text = script_path.read_text(encoding='utf-8')
match = re.search(r'\n\t\topenclaw_model_probe\(\) \{.*?\n\t\t\}', text, re.S)
if not match:
    raise SystemExit('openclaw_model_probe not found')
func = match.group(0).strip('\n')

config = {
    "models": {
        "providers": {
            "demo": {
                "baseUrl": "https://api.example.com/v1",
                "apiKey": "sk-test"
            }
        }
    }
}
(workdir / 'home' / '.openclaw').mkdir(parents=True, exist_ok=True)
(workdir / 'home' / '.openclaw' / 'openclaw.json').write_text(json.dumps(config, ensure_ascii=False, indent=2) + '\n', encoding='utf-8')

harness = f'''#!/usr/bin/env bash
set -euo pipefail
HOME="{workdir / 'home'}"
OPENCLAW_PROBE_STATUS=""
OPENCLAW_PROBE_MESSAGE=""
OPENCLAW_PROBE_LATENCY=""
OPENCLAW_PROBE_REPLY=""
{func}
'''
(workdir / 'harness.sh').write_text(harness, encoding='utf-8')
PY

run_case() {
  local case_name="$1"
  CASE_NAME="$case_name" WORKDIR="$WORKDIR" bash <<'EOF_CASE'
set -euo pipefail
source "$WORKDIR/harness.sh"

python3() {
  if [ "$1" != "-" ]; then
    command python3 "$@"
    return
  fi

  local script
  script=$(cat)
  shift

  CASE_NAME="$CASE_NAME" command python3 - "$script" "$@" <<'PYWRAP'
import io
import json
import os
import sys
import urllib.error
import urllib.request
from pathlib import Path

script = sys.argv[1]
args = sys.argv[2:]
case = os.environ['CASE_NAME']

class Resp(io.BytesIO):
    def __init__(self, data, code=200):
        super().__init__(data)
        self.status = code
    def __enter__(self):
        return self
    def __exit__(self, exc_type, exc, tb):
        return False

real_urlopen = urllib.request.urlopen

def fake_urlopen(req, timeout=0):
    url = getattr(req, 'full_url', '')
    if case == 'fallback-success':
        if url.endswith('/chat/completions'):
            raise urllib.error.HTTPError(url, 404, 'Not Found', {}, io.BytesIO(b'{"error":"chat disabled"}'))
        if url.endswith('/responses'):
            body = json.dumps({"output": [{"content": [{"text": "pong from responses"}]}]}).encode('utf-8')
            return Resp(body, 200)
    elif case == 'all-fail':
        if url.endswith('/chat/completions'):
            raise urllib.error.HTTPError(url, 404, 'Not Found', {}, io.BytesIO(b'{"error":"chat disabled"}'))
        if url.endswith('/responses'):
            raise urllib.error.HTTPError(url, 404, 'Not Found', {}, io.BytesIO(b'{"error":"responses disabled"}'))
    return real_urlopen(req, timeout=timeout)

urllib.request.urlopen = fake_urlopen
sys.argv = ['python3'] + args
ns = {'__name__': '__main__'}
exec(compile(script, '<stdin>', 'exec'), ns, ns)
PYWRAP
}

set +e
openclaw_model_probe "demo/test-model"
probe_rc=$?
set -e
printf 'RC=%s\nSTATUS=%s\nMESSAGE=%s\nLATENCY=%s\nREPLY=%s\n' "$probe_rc" "$OPENCLAW_PROBE_STATUS" "$OPENCLAW_PROBE_MESSAGE" "$OPENCLAW_PROBE_LATENCY" "$OPENCLAW_PROBE_REPLY"
EOF_CASE
}

out1=$(run_case fallback-success)
printf '%s\n' "$out1" | grep -q 'STATUS=OK'
printf '%s\n' "$out1" | grep -q 'MESSAGE=/responses -> HTTP 200'
printf '%s\n' "$out1" | grep -q 'REPLY=pong from responses'

out2=$(run_case all-fail || true)
printf '%s\n' "$out2" | grep -q 'RC=1'
printf '%s\n' "$out2" | grep -q 'STATUS=FAIL'
printf '%s\n' "$out2" | grep -q '/responses -> HTTP 404 / exit 22；/chat/completions -> HTTP 404 / exit 22'

printf '%s\n' 'SMOKE_OK'
