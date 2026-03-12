# OpenClaw tests

这里的脚本用于对 `kejilion.sh` 中的 OpenClaw 相关功能做最小回归与冒烟测试，主要覆盖：

- API 模型同步/协议探测
- 记忆菜单
- 插件/技能菜单
- API 列表颜色/对齐展示（最小验证）

## 运行方式

在仓库根目录执行（推荐）：

```bash
bash tests/openclaw/tests_openclaw_api_protocol_detect_smoke.sh
bash tests/openclaw/tests_openclaw_api_sync_diff_smoke.sh
bash tests/openclaw/tests_openclaw_memory_menu_smoke.sh
bash tests/openclaw/tests_openclaw_plugin_skill_menu_smoke.sh
bash tests/openclaw/tests_openclaw_api_color_align_min.sh
```

也可在任意工作目录执行：

```bash
/path/to/repo/tests/openclaw/tests_openclaw_memory_menu_smoke.sh
```

## 安全说明

- 脚本会创建临时工作目录与临时 `HOME`（位于 `/tmp`），并在结束后自动清理（除非设置 `KEEP_WORKDIR=true`）。
- 运行过程使用 stub/模拟命令，不会改动真实 OpenClaw 配置或系统状态。
- 如需保留临时目录用于排查，请执行：

```bash
KEEP_WORKDIR=true bash tests/openclaw/tests_openclaw_memory_menu_smoke.sh
```
