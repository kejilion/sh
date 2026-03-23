#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-memory-auto-setup-test-$$"
mkdir -p "$WORKDIR/bin"
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
chmod +x "$WORKDIR/harness.sh"

# stub: openclaw
cat > "$WORKDIR/bin/openclaw" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
cmd="$*"
config_dir="$HOME/.openclaw/config"
mkdir -p "$config_dir"
key_file() {
  local key="$1"
  echo "$config_dir/${key//./_}"
}
if [[ "$cmd" == "config get"* ]]; then
  key="$3"
  file=$(key_file "$key")
  if [ -f "$file" ]; then
    cat "$file"
  fi
  exit 0
fi
if [[ "$cmd" == "config set"* ]]; then
  key="$3"
  val="$4"
  file=$(key_file "$key")
  echo "$val" > "$file"
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
Indexed: 0/0 files
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
echo "mock openclaw $*"
EOF_INNER
chmod +x "$WORKDIR/bin/openclaw"

# stub: curl
cat > "$WORKDIR/bin/curl" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
args=("$@")

is_head=0
for arg in "${args[@]}"; do
  if [ "$arg" = "-I" ]; then
    is_head=1
  fi
done
url="${args[$((${#args[@]}-1))]}"

for arg in "${args[@]}"; do
  if [[ "$arg" == *"ipinfo.io/country"* ]]; then
    echo "${FAKE_COUNTRY:-US}"
    exit 0
  fi
  if [[ "$arg" == *"bun.sh/install"* ]]; then
    cat <<'SCRIPT'
mkdir -p "$HOME/.bun/bin"
cat > "$HOME/.bun/bin/bun" <<'BUN'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "install" && "$2" == "-g" ]]; then
  mkdir -p "$HOME/.bun/bin"
  cat > "$HOME/.bun/bin/qmd" <<'QMD'
#!/usr/bin/env bash
exit 0
QMD
  chmod +x "$HOME/.bun/bin/qmd"
fi
echo "$*" >> "$HOME/.openclaw/bun_calls"
exit 0
BUN
chmod +x "$HOME/.bun/bin/bun"
SCRIPT
    exit 0
  fi
done

if [ "$is_head" = "1" ]; then
  if [[ "$url" == *"huggingface.co"* ]]; then
    exit ${FAKE_HF_OK:-0}
  fi
  if [[ "$url" == *"hf-mirror.com"* ]]; then
    exit ${FAKE_MIRROR_OK:-0}
  fi
  exit 0
fi

dest=""
for ((i=0;i<${#args[@]};i++)); do
  if [ "${args[$i]}" = "-o" ] && [ $((i+1)) -lt ${#args[@]} ]; then
    dest="${args[$((i+1))]}"
  fi
done

if [ -n "$dest" ] && [[ "$url" == *"embeddinggemma"* ]]; then
  mkdir -p "$(dirname "$dest")"
  echo "model" > "$dest"
  echo "$url" >> "$HOME/.openclaw/download_calls"
  exit 0
fi
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/curl"

# stub: wget (fallback, not used in test)
cat > "$WORKDIR/bin/wget" <<'EOF_INNER'
#!/usr/bin/env bash
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/wget"

export PATH="$WORKDIR/bin:$PATH"
export TERM=xterm

source "$WORKDIR/harness.sh"

make_home() {
  local name="$1"
  local home="$WORKDIR/$name/home"
  mkdir -p "$home/.openclaw/workspace/memory" "$home/.openclaw"
  echo "$home"
}

run_auto() {
  local input="$1"
  local scheme="$2"
  local outfile="$3"
  printf "%b" "$input" | openclaw_memory_auto_setup_run "$scheme" >"$outfile"
}

# Case 1: qmd 不存在 -> 安装 -> 写入绝对路径 -> index
HOME_QMD=$(make_home "qmd")
export HOME="$HOME_QMD"
FAKE_COUNTRY=US FAKE_HF_OK=0 FAKE_MIRROR_OK=1 \
  run_auto "yes\n" "qmd" "$WORKDIR/out_qmd.txt"

# Case 2: local 模型不存在 -> 下载 -> 写入 modelPath -> index (CN)
HOME_LOCAL=$(make_home "local")
export HOME="$HOME_LOCAL"
FAKE_COUNTRY=CN FAKE_HF_OK=1 FAKE_MIRROR_OK=0 \
  run_auto "yes\n" "local" "$WORKDIR/out_local.txt"

# Case 3: 已存在 -> 跳过下载/安装
HOME_SKIP=$(make_home "skip")
export HOME="$HOME_SKIP"
mkdir -p "$HOME/.openclaw/models/embedding" "$HOME/.openclaw/config"
MODEL_EXIST="$HOME/.openclaw/models/embedding/embeddinggemma-300M-Q8_0.gguf"

echo "local" > "$HOME/.openclaw/config/memory_backend"
echo "local" > "$HOME/.openclaw/config/agents_defaults_memorySearch_provider"
echo "$MODEL_EXIST" > "$HOME/.openclaw/config/agents_defaults_memorySearch_local_modelPath"

touch "$MODEL_EXIST"

# 预置 qmd
mkdir -p "$HOME/.bun/bin"
cat > "$HOME/.bun/bin/qmd" <<'QMD'
#!/usr/bin/env bash
exit 0
QMD
chmod +x "$HOME/.bun/bin/qmd"
export PATH="$HOME/.bun/bin:$PATH"

FAKE_COUNTRY=US FAKE_HF_OK=0 FAKE_MIRROR_OK=0 \
  run_auto "yes\n" "local" "$WORKDIR/out_skip.txt"

export WORKDIR
python3 - <<'PY'
import os
from pathlib import Path

workdir = os.environ['WORKDIR']

# Case1: qmd command absolute + index called
home_qmd = Path(workdir) / 'qmd' / 'home'
qmd_cmd = (home_qmd / '.openclaw/config/memory_qmd_command').read_text().strip()
if not qmd_cmd.startswith('/'):
    raise SystemExit('qmd command not absolute')
index_calls = (home_qmd / '.openclaw/index_calls').read_text()
if 'memory index' not in index_calls or '--force' not in index_calls:
    raise SystemExit('qmd preheat index not called')

# Case2: local model downloaded + modelPath written
home_local = Path(workdir) / 'local' / 'home'
model_path = (home_local / '.openclaw/config/agents_defaults_memorySearch_local_modelPath').read_text().strip()
if not Path(model_path).exists():
    raise SystemExit('model file not downloaded')
if 'hf-mirror.com' not in (Path(workdir) / 'out_local.txt').read_text():
    raise SystemExit('mirror not used for CN')

# Case3: skip download
home_skip = Path(workdir) / 'skip' / 'home'
download_calls = home_skip / '.openclaw/download_calls'
if download_calls.exists():
    raise SystemExit('download should be skipped when model exists')
print('SMOKE_OK')
PY
