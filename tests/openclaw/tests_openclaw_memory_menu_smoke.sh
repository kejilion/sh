#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-memory-menu-test-$$"
mkdir -p "$WORKDIR/bin" "$WORKDIR/home/.openclaw/workspace/memory"
KEEP_WORKDIR=${KEEP_WORKDIR:-false}
trap '[ "$KEEP_WORKDIR" = "true" ] || rm -rf "$WORKDIR"' EXIT

# 抽取 OpenClaw 记忆菜单实现
cat > "$WORKDIR/harness.sh" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
break_end() { return 0; }
send_stats() { return 0; }
EOF_INNER

awk 'BEGIN{p=0} /openclaw_memory_config_file\(\) \{/{p=1} /openclaw_memory_menu\(\) \{/{p=0} p{print}' "$SCRIPT" >> "$WORKDIR/harness.sh"
awk 'BEGIN{p=0} /openclaw_memory_menu\(\) \{/{p=1} /openclaw_backup_restore_menu\(\) \{/{p=0} p{print}' "$SCRIPT" >> "$WORKDIR/harness.sh"
chmod +x "$WORKDIR/harness.sh"

# stub: openclaw
cat > "$WORKDIR/bin/openclaw" <<'EOF_INNER'
#!/usr/bin/env bash
cmd="$*"
if [[ "$cmd" == "config get"* ]]; then
  key="$3"
  case "$key" in
    memory.backend) echo "qmd" ;;
    memory.qmd.includeDefaultMemory)
      if [ -f "${HOME}/.openclaw/includeDefaultMemory" ]; then
        cat "${HOME}/.openclaw/includeDefaultMemory"
      else
        echo "true"
      fi
      ;;
    memory.qmd.command) echo "qmd" ;;
    agents.defaults.memorySearch.local.modelPath) echo "hf:ggml-org/embeddinggemma-300M-GGUF/embeddinggemma-300M-Q8_0.gguf" ;;
    agents.defaults.memorySearch.provider) echo "local" ;;
    *) echo "" ;;
  esac
  exit 0
fi
if [[ "$cmd" == "config set"* ]]; then
  key="$3"
  val="$4"
  if [[ "$key" == "memory.qmd.includeDefaultMemory" ]]; then
    echo "$val" > "${HOME}/.openclaw/includeDefaultMemory"
  fi
  if [[ "$key" == "memory.backend" ]]; then
    echo "$val" > "${HOME}/.openclaw/backend"
  fi
  if [[ "$key" == "memory.qmd.command" ]]; then
    echo "$val" > "${HOME}/.openclaw/qmd_command"
  fi
  if [[ "$key" == "agents.defaults.memorySearch.provider" ]]; then
    echo "$val" > "${HOME}/.openclaw/provider"
  fi
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
  cat <<TXT
Provider: qmd (requested: qmd)
Vector: ready
Indexed: 23/14 files
Workspace: ${HOME}/.openclaw/workspace
Store: ${OPENCLAW_STORE:-~/.openclaw/workspace/memory/index.sqlite}
TXT
  exit 0
fi
if [[ "$1" == "memory" && "$2" == "index" ]]; then
  echo "$cmd" >> "${HOME}/.openclaw/index_calls"
  echo "index ok"
  exit 0
fi
if [[ "$cmd" == "gateway restart" ]]; then
  echo "$cmd" >> "${HOME}/.openclaw/gateway_calls"
  echo "gateway restarted"
  exit 0
fi
if [[ "$cmd" == "gateway stop" ]]; then
  echo "gateway stopped"
  exit 0
fi
if [[ "$cmd" == "gateway start" ]]; then
  echo "gateway started"
  exit 0
fi
echo "mock openclaw $*"
EOF_INNER
chmod +x "$WORKDIR/bin/openclaw"

# stub: qmd
cat > "$WORKDIR/bin/qmd" <<'EOF_INNER'
#!/usr/bin/env bash
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/qmd"

# stub: curl (用于网络探测)
cat > "$WORKDIR/bin/curl" <<'EOF_INNER'
#!/usr/bin/env bash
if [[ "$*" == *"huggingface.co"* ]]; then
  exit 1
fi
if [[ "$*" == *"hf-mirror.com"* ]]; then
  exit 0
fi
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/curl"

export HOME="$WORKDIR/home"
export PATH="$WORKDIR/bin:$PATH"
export TERM=xterm

# minimal openclaw.json
cat > "$HOME/.openclaw/openclaw.json" <<'JSON'
{
  "memory": {
    "backend": "qmd",
    "qmd": {"command": "qmd", "includeDefaultMemory": true}
  },
  "agents": {
    "defaults": {
      "memorySearch": {
        "provider": "local",
        "local": {
          "modelPath": "hf:ggml-org/embeddinggemma-300M-GGUF/embeddinggemma-300M-Q8_0.gguf"
        }
      }
    }
  }
}
JSON

# mock index sqlite
mkdir -p "$HOME/.openclaw/workspace/memory"
touch "$HOME/.openclaw/workspace/memory/index.sqlite"

# mock memory files
cat > "$HOME/.openclaw/workspace/MEMORY.md" <<'TXT'
# MEMORY
line1
line2
line3
TXT
cat > "$HOME/.openclaw/workspace/memory/2026-03-11.md" <<'TXT'
# 2026-03-11
foo
bar
TXT

source "$WORKDIR/harness.sh"

run_menu() {
  local input="$1"
  local title="$2"
  local outfile="$3"
  echo "[TEST] $title"
  printf "%b" "$input" | openclaw_memory_menu >"$outfile"
}

# 1) 状态展示（直接返回）
run_menu "0\n" "status" "$WORKDIR/out_status.txt"
# 2) 更新索引（增量）
run_menu "1\nyes\n\n\n0\n" "index" "$WORKDIR/out_index.txt"
# 3) 查看记忆文件（列表+查看）
run_menu "2\n1\n\n\n\n\n0\n0\n" "files" "$WORKDIR/out_files.txt"
# 4) 索引修复（检测到 includeDefaultMemory=false → 恢复为 true 并重建）
echo "false" > "$HOME/.openclaw/includeDefaultMemory"
run_menu "3\ny\n\n\n0\n" "fix" "$WORKDIR/out_fix.txt"
# 5) 记忆方案（自动推荐并取消）
run_menu "4\n1\n\n0\n0\n" "scheme" "$WORKDIR/out_scheme.txt"

# 6) Store 缺失时仍执行 rebuild
: > "$HOME/.openclaw/index_calls"
OPENCLAW_STORE="~/.openclaw/workspace/memory/missing.sqlite" \
  openclaw_memory_rebuild_index_safe >"$WORKDIR/out_missing.txt"

export WORKDIR
python3 - <<'PY'
import glob
import os

flag_path = os.path.expanduser('~/.openclaw/includeDefaultMemory')
if not os.path.exists(flag_path):
    raise SystemExit('includeDefaultMemory not updated')
flag = open(flag_path, 'r', encoding='utf-8').read().strip()
if flag != 'true':
    raise SystemExit('includeDefaultMemory not restored to true')
# ensure backup created
baks = glob.glob(os.path.expanduser('~/.openclaw/workspace/memory/index.sqlite.bak.*'))
if not baks:
    raise SystemExit('index sqlite backup not created')
# ensure missing store still triggers force index
calls_path = os.path.expanduser('~/.openclaw/index_calls')
if not os.path.exists(calls_path):
    raise SystemExit('index calls not recorded')
with open(calls_path, 'r', encoding='utf-8') as fh:
    calls = fh.read()
if 'memory index' not in calls or '--force' not in calls:
    raise SystemExit('force index not called for missing store')
# ensure gateway restart called after rebuild
gw_calls_path = os.path.expanduser('~/.openclaw/gateway_calls')
if not os.path.exists(gw_calls_path):
    raise SystemExit('gateway restart not recorded')
with open(gw_calls_path, 'r', encoding='utf-8') as fh:
    gw_calls = fh.read()
if 'gateway restart' not in gw_calls:
    raise SystemExit('gateway restart not called after rebuild')
# ensure warning emitted
with open(os.path.join(os.environ['WORKDIR'], 'out_missing.txt'), 'r', encoding='utf-8') as fh:
    out = fh.read()
if 'Store 原始值' not in out:
    raise SystemExit('missing store warning not found')
if '索引已重建并自动重启网关' not in out:
    raise SystemExit('auto restart message not found')
print('SMOKE_OK')
PY
