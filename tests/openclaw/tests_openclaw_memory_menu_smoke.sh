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
    memory.qmd.includeDefaultMemory) echo "true" ;;
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
if [[ "$cmd" == "memory status" ]]; then
  cat <<TXT
Provider: qmd (requested: qmd)
Vector: ready
Indexed: 23/14 files
Workspace: ${HOME}/.openclaw/workspace
Store: ${HOME}/.openclaw/workspace/memory/index.sqlite
TXT
  exit 0
fi
if [[ "$cmd" == "memory index"* ]]; then
  echo "index ok"
  exit 0
fi
if [[ "$cmd" == "gateway restart" ]]; then
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
  echo "[TEST] $title"
  printf "%b" "$input" | openclaw_memory_menu >/tmp/memory_menu.out
}

# 1) 状态展示（直接返回）
run_menu "0\n" "status"
# 2) 更新索引（增量）
run_menu "1\nyes\n\n\n0\n" "index"
# 3) 查看记忆文件（列表+查看）
run_menu "2\n1\n\n\n\n\n0\n0\n" "files"
# 4) 索引修复（执行修复 + 不立即重建）
run_menu "3\ny\n\n\n0\n" "fix"
# 5) 记忆方案（自动推荐并取消）
run_menu "4\n1\n\nN\n0\n0\n" "scheme"

python3 - <<'PY'
import json,os,sys
flag_path = os.path.expanduser('~/.openclaw/includeDefaultMemory')
if not os.path.exists(flag_path):
    raise SystemExit('includeDefaultMemory not updated')
flag = open(flag_path, 'r', encoding='utf-8').read().strip()
if flag != 'false':
    raise SystemExit('includeDefaultMemory not updated')
# ensure backup created
import glob
baks = glob.glob(os.path.expanduser('~/.openclaw/workspace/memory/index.sqlite.bak.*'))
if not baks:
    raise SystemExit('index sqlite backup not created')
print('SMOKE_OK')
PY
