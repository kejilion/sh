# OpenClaw Windows 10/11 独立管理脚本（快捷使用）

## 文件
- `openclaw-win-manager.ps1`：主脚本
- `openclaw-win-manager.bat`：一键启动器（推荐）

## 一键使用（推荐）
1. 右键 `openclaw-win-manager.bat`，选择**以管理员身份运行**。
2. 进入交互菜单后，按数字操作：
   - `1` 安装 OpenClaw
   - `2/3/4` 启动/停止/重启
   - `5` 查看状态与日志
   - `6` 切换模型

## 首次安装建议顺序
1. `1` 安装 OpenClaw
2. `12` 配置向导（onboard）
3. `2` 启动 OpenClaw
4. `5` 检查状态日志

## 常见问题
### 1) 提示执行策略限制
已在 `.bat` 内自动使用：
`-ExecutionPolicy Bypass`

### 2) 提示找不到 Node.js
脚本会尝试自动用 `winget/choco/scoop` 安装 Node.js。
如果都没有，请先手动安装 Node.js 20+。

### 3) 修改配置后不生效
在菜单中执行 `4`（重启）或 `2` 启动前先 `3` 停止。

## 安全建议
- 仅在可信机器运行。
- API Key 建议最小权限。
- 定期用菜单 `13` 执行 `doctor --fix`。
