#!/usr/bin/env bash
set -euo pipefail

REPO_ROOT="$(cd "$(dirname "$0")/../.." && pwd)"
SCRIPT="$REPO_ROOT/kejilion.sh"
WORKDIR="${TMPDIR:-/tmp}/openclaw-plugin-skill-menu-test-$$"
mkdir -p "$WORKDIR/bin" "$WORKDIR/home/.openclaw/workspace/skills" "$WORKDIR/home/.openclaw"
KEEP_WORKDIR=${KEEP_WORKDIR:-false}
trap '[ "$KEEP_WORKDIR" = "true" ] || rm -rf "$WORKDIR"' EXIT

cat > "$WORKDIR/harness.sh" <<'EOF_INNER'
#!/usr/bin/env bash
set -euo pipefail
break_end() { return 0; }
send_stats() { return 0; }
start_gateway() { openclaw gateway stop; openclaw gateway start; }
EOF_INNER

# 抽取插件/技能管理实现
awk 'BEGIN{p=0} /resolve_openclaw_plugin_id\(\) \{/{p=1} /openclaw_json_get_bool\(\) \{/{p=0} p{print}' "$SCRIPT" >> "$WORKDIR/harness.sh"
chmod +x "$WORKDIR/harness.sh"

# stub: openclaw
cat > "$WORKDIR/bin/openclaw" <<'EOF_INNER'
#!/usr/bin/env bash
cmd="$*"
if [[ "$cmd" == "plugins list" ]]; then
  cat <<TXT
feishu disabled
telegram enabled
TXT
  exit 0
fi
if [[ "$cmd" == "plugins enable"* ]]; then
  echo "enabled $*" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
if [[ "$cmd" == "plugins install"* ]]; then
  echo "install $*" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
if [[ "$cmd" == "plugins disable"* ]]; then
  echo "disable $*" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
if [[ "$cmd" == "plugins uninstall"* ]]; then
  # 模拟预装卸载失败
  if [[ "$cmd" == *"feishu"* ]]; then
    exit 1
  fi
  echo "uninstall $*" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
if [[ "$cmd" == "skills list" ]]; then
  echo "skill1"
  exit 0
fi
if [[ "$cmd" == "gateway stop" ]]; then
  echo "gateway stop" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
if [[ "$cmd" == "gateway start" ]]; then
  echo "gateway start" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
echo "mock openclaw $*" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
EOF_INNER
chmod +x "$WORKDIR/bin/openclaw"

# stub: npx
cat > "$WORKDIR/bin/npx" <<'EOF_INNER'
#!/usr/bin/env bash
if [[ "$*" == *"clawhub uninstall"* ]]; then
  echo "uninstall $*" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
if [[ "$*" == *"clawhub install"* ]]; then
  echo "install $*" >> "${TEST_LOG:-/tmp/openclaw-plugin.log}"
  exit 0
fi
exit 0
EOF_INNER
chmod +x "$WORKDIR/bin/npx"

export HOME="$WORKDIR/home"
export PATH="$WORKDIR/bin:$PATH"
export TERM=xterm
export TEST_LOG="$WORKDIR/test.log"

cat > "$HOME/.openclaw/openclaw.json" <<'JSON'
{"plugins":{"allow":["telegram","feishu"]}}
JSON

# 模拟用户技能目录
mkdir -p "$HOME/.openclaw/workspace/skills/skillA"

source "$WORKDIR/harness.sh"

# 插件安装：多输入，确保只重启一次
printf "1\nfeishu telegram\n0\n" | install_plugin > "$WORKDIR/plugin_install.out"

# 插件删除：多输入，确保删除流程与 allowlist 移除
printf "2\nfeishu telegram\n0\n" | install_plugin > "$WORKDIR/plugin_delete.out"

# 技能删除：二次确认 + 多输入，删除目录
printf "2\nskillA skillB\ny\n0\n" | install_skill > "$WORKDIR/skill_delete.out"

# 断言：start_gateway 只调用一次/每次菜单
start_count=$(grep -c "gateway start" "$TEST_LOG" || true)
if [ "$start_count" -ne 3 ]; then
  echo "Expected 3 gateway starts (plugin install/delete + skill delete), got $start_count"
  exit 1
fi

# 断言：用户技能目录已删除
if [ -d "$HOME/.openclaw/workspace/skills/skillA" ]; then
  echo "Skill directory was not removed"
  exit 1
fi

# 断言：plugins.allow 移除
if grep -q '"feishu"' "$HOME/.openclaw/openclaw.json"; then
  echo "feishu still in plugins.allow"
  exit 1
fi

# 断言：输出汇总
grep -q "操作汇总" "$WORKDIR/plugin_install.out"
grep -q "操作汇总" "$WORKDIR/plugin_delete.out"
grep -q "操作汇总" "$WORKDIR/skill_delete.out"

echo "SMOKE_OK"
