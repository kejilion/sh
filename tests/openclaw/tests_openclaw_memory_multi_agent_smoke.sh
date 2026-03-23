#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-memory-multi-agent-test-$$"
mkdir -p "$WORKDIR/bin" "$WORKDIR/home/.openclaw/workspace/memory"
KEEP_WORKDIR=${KEEP_WORKDIR:-false}
trap '[ "$KEEP_WORKDIR" = "true" ] || rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/harness.sh" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
break_end() { return 0; }
send_stats() { return 0; }
EOF_INNER

awk 'BEGIN{p=0} /openclaw_memory_config_file\(\) \{/{p=1} /openclaw_permission_config_file\(\) \{/{p=0} p{print}' "$SCRIPT" >> "$WORKDIR/harness.sh"
chmod +x "$WORKDIR/harness.sh"

cat > "$WORKDIR/bin/openclaw" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
cmd="$*"
if [[ "$cmd" == "agents list --json" ]]; then
  cat <<'JSON'
[
  {"id":"main","workspace":"~/.openclaw/workspace"},
  {"id":"work","workspace":"~/.openclaw/workspace-work"}
]
JSON
  exit 0
fi
if [[ "$cmd" == "config get"* ]]; then
  key="$3"
  case "$key" in
    memory.backend) echo "qmd" ;;
    memory.qmd.command) echo "qmd" ;;
    agents.defaults.memorySearch.provider) echo "local" ;;
    agents.defaults.memorySearch.local.modelPath) echo "$HOME/.openclaw/models/embedding/model.gguf" ;;
    *) echo "" ;;
  esac
  exit 0
fi
if [[ "$cmd" == "config set"* || "$cmd" == "config unset"* ]]; then
  exit 0
fi
if [[ "$1" == "memory" && "$2" == "status" ]]; then
  agent="main"
  while [ $# -gt 0 ]; do
    if [ "$1" = "--agent" ] && [ $# -ge 2 ]; then
      agent="$2"
      shift 2
      continue
    fi
    shift
  done
  if [ "$agent" = "work" ]; then
    cat <<TXT
Provider: qmd (requested: qmd)
Vector: ready
Indexed: 3/2 files
Workspace: $HOME/.openclaw/workspace-work
Store: $HOME/.openclaw/workspace-work/memory/index.sqlite
TXT
  else
    cat <<TXT
Provider: qmd (requested: qmd)
Vector: ready
Indexed: 5/4 files
Workspace: $HOME/.openclaw/workspace
Store: $HOME/.openclaw/workspace/memory/index.sqlite
TXT
  fi
  exit 0
fi
if [[ "$1" == "memory" && "$2" == "index" ]]; then
  echo "$cmd" >> "$HOME/.openclaw/index_calls"
  exit 0
fi
if [[ "$1" == "gateway" && "$2" == "restart" ]]; then
  echo "$cmd" >> "$HOME/.openclaw/gateway_calls"
  exit 0
fi
echo "mock openclaw $*"
EOF_INNER
chmod +x "$WORKDIR/bin/openclaw"

export HOME="$WORKDIR/home"
export PATH="$WORKDIR/bin:$PATH"
export TERM=xterm

mkdir -p "$HOME/.openclaw/workspace/memory" "$HOME/.openclaw/workspace-work/memory"
touch "$HOME/.openclaw/workspace/memory/index.sqlite" "$HOME/.openclaw/workspace-work/memory/index.sqlite"
cat > "$HOME/.openclaw/openclaw.json" <<'JSON'
{
  "agents": {
    "list": [
      {"id": "work", "workspace": "~/.openclaw/workspace-work"}
    ]
  }
}
JSON
cat > "$HOME/.openclaw/workspace/MEMORY.md" <<'TXT'
# main memory
TXT
cat > "$HOME/.openclaw/workspace-work/MEMORY.md" <<'TXT'
# work memory
TXT
cat > "$HOME/.openclaw/workspace-work/memory/2026-03-23.md" <<'TXT'
# work note
TXT

source "$WORKDIR/harness.sh"

openclaw_memory_render_status > "$WORKDIR/out_status.txt"
openclaw_memory_file_render_list > "$WORKDIR/out_files.txt"
openclaw_memory_prepare_workspace_all > "$WORKDIR/out_prepare.txt"
openclaw_memory_rebuild_index_all > "$WORKDIR/out_rebuild.txt"

export WORKDIR
python3 - <<'PY'
import os
from pathlib import Path

workdir = Path(os.environ['WORKDIR'])
home = workdir / 'home'
status_out = (workdir / 'out_status.txt').read_text(encoding='utf-8')
files_out = (workdir / 'out_files.txt').read_text(encoding='utf-8')
prepare_out = (workdir / 'out_prepare.txt').read_text(encoding='utf-8')
rebuild_out = (workdir / 'out_rebuild.txt').read_text(encoding='utf-8')
index_calls = (home / '.openclaw' / 'index_calls').read_text(encoding='utf-8')
gateway_calls = (home / '.openclaw' / 'gateway_calls').read_text(encoding='utf-8')

if 'Agent: main' not in status_out or 'Agent: work' not in status_out:
    raise SystemExit('multi-agent status missing agent sections')
if 'main/MEMORY.md' not in files_out or 'work/MEMORY.md' not in files_out:
    raise SystemExit('multi-agent file list missing memory files')
if 'work/memory/2026-03-23.md' not in files_out:
    raise SystemExit('work daily memory file missing')
if '检查并准备 2 个智能体工作区' not in prepare_out:
    raise SystemExit('prepare summary missing agent count')
if '--agent main --force' not in index_calls or '--agent work --force' not in index_calls:
    raise SystemExit('force index not called for all agents')
if 'gateway restart' not in gateway_calls:
    raise SystemExit('gateway restart not called after multi-agent rebuild')
if '已为 2 个智能体重建索引' not in rebuild_out:
    raise SystemExit('multi-agent rebuild summary missing')
print('SMOKE_OK')
PY
