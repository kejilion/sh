#!/bin/bash
# Loaded by kejilion.sh: share its application locks and installation markers.
# Official installers: https://claude.ai/install.sh https://chatgpt.com/codex/install.sh https://opencode.ai/install

ai_cli_select() {
	case "$1" in
		claude-code) AI_CLI_ID=119; AI_CLI_NAME='Claude Code'; AI_CLI_COMMAND=claude; AI_CLI_PACKAGE='@anthropic-ai/claude-code' ;;
		codex) AI_CLI_ID=120; AI_CLI_NAME='Codex'; AI_CLI_COMMAND=codex; AI_CLI_PACKAGE='@openai/codex' ;;
		opencode) AI_CLI_ID=121; AI_CLI_NAME='OpenCode'; AI_CLI_COMMAND=opencode; AI_CLI_PACKAGE='opencode-ai' ;;
		*) echo '未知的 AI 编程工具。' >&2; return 1 ;;
	esac
	AI_CLI_BIN_DIR="$HOME/.local/bin"
	[ "$AI_CLI_COMMAND" != codex ] || AI_CLI_BIN_DIR="${CODEX_INSTALL_DIR:-$AI_CLI_BIN_DIR}"
	[ "$AI_CLI_COMMAND" != opencode ] || AI_CLI_BIN_DIR="$HOME/.opencode/bin"
	export PATH="$PATH:$AI_CLI_BIN_DIR"
}

ai_cli_installed() {
	hash -r
	command -v "$AI_CLI_COMMAND" >/dev/null 2>&1
}

ai_cli_require_installed() {
	ai_cli_installed && return 0
	echo "请先安装 $AI_CLI_NAME。" >&2
	return 1
}

ai_cli_mark() {
	local app_id="$AI_CLI_ID"
	kpanel_app_with_lock markers kpanel_app_update_marker "$1"
}

# Download completely before execution; a failed/partial response is never run.
ai_cli_native_install() (
	local installer result
	installer=$(mktemp "${TMPDIR:-/tmp}/ai-cli-install.XXXXXX") || return 1
	trap 'rm -f -- "$installer"' EXIT
	if [ "$AI_CLI_COMMAND" = claude ]; then
		curl -fLsS --connect-timeout 15 --max-time 120 https://claude.ai/install.sh -o "$installer" || return 1
		[ -s "$installer" ] && bash -n "$installer" || return 1
		bash "$installer" stable
		result=$?
	elif [ "$AI_CLI_COMMAND" = opencode ]; then
		curl -fLsS --connect-timeout 15 --max-time 120 https://opencode.ai/install -o "$installer" || return 1
		[ -s "$installer" ] && bash -n "$installer" || return 1
		bash "$installer"
		result=$?
	else
		curl -fLsS --connect-timeout 15 --max-time 120 https://chatgpt.com/codex/install.sh -o "$installer" || return 1
		[ -s "$installer" ] && sh -n "$installer" || return 1
		sh "$installer"
		result=$?
	fi
	return "$result"
)

ai_cli_install_impl() {
	if ! ai_cli_installed; then
		ai_cli_native_install || return 1
	fi
	ai_cli_require_installed || return 1
	"$AI_CLI_COMMAND" --version || return 1
	ai_cli_mark add || return 1
	echo "$AI_CLI_NAME 已安装。选择登录，再进入项目目录开始使用。"
}

ai_cli_is_npm_install() {
	local npm_root binary
	command -v npm >/dev/null 2>&1 || return 1
	npm_root=$(npm root -g 2>/dev/null) || return 1
	binary=$(readlink -f "$(command -v "$AI_CLI_COMMAND")") || return 1
	case "$binary" in "$npm_root/$AI_CLI_PACKAGE/"*) return 0 ;; esac
	return 1
}

ai_cli_is_native_install() {
	local binary target native_root
	binary=$(command -v "$AI_CLI_COMMAND") || return 1
	if [ "$AI_CLI_COMMAND" = opencode ]; then
		# The official installer writes a regular executable, not a launch link.
		[ "$binary" = "$AI_CLI_BIN_DIR/opencode" ] && [ -f "$binary" ] && [ ! -L "$binary" ]
		return $?
	fi
	[ "$binary" = "$AI_CLI_BIN_DIR/$AI_CLI_COMMAND" ] && [ -L "$binary" ] || return 1
	target=$(readlink -f "$binary") || return 1
	if [ "$AI_CLI_COMMAND" = claude ]; then
		native_root="$HOME/.local/share/claude"
	else
		native_root="${CODEX_HOME:-$HOME/.codex}/packages/standalone"
	fi
	native_root=$(readlink -f "$native_root") || return 1
	case "$target" in "$native_root/"*) return 0 ;; esac
	return 1
}

ai_cli_update_impl() {
	ai_cli_require_installed || return 1
	if ai_cli_is_npm_install; then
		npm install -g "$AI_CLI_PACKAGE@latest" || return 1
	elif ai_cli_is_native_install; then
		if [ "$AI_CLI_COMMAND" = claude ]; then
			claude update || return 1
		elif [ "$AI_CLI_COMMAND" = opencode ]; then
			opencode upgrade --method curl || return 1
		else
			ai_cli_native_install || return 1
		fi
	else
		echo '当前程序由其他方式安装，请使用原包管理器更新。' >&2
		return 1
	fi
	"$AI_CLI_COMMAND" --version || return 1
	ai_cli_mark add
}

ai_cli_uninstall_impl() {
	if ! ai_cli_installed; then
		ai_cli_mark remove
		return $?
	fi
	if ai_cli_is_npm_install; then
		npm uninstall -g "$AI_CLI_PACKAGE" || return 1
	elif ai_cli_is_native_install; then
		if [ "$AI_CLI_COMMAND" = opencode ]; then
			opencode uninstall --keep-config --keep-data --force || return 1
		else
			# Remove only the official launch link. Keep settings, logins, sessions and
			# downloaded versions; these may also be used by the desktop/IDE clients.
			rm -f -- "$AI_CLI_BIN_DIR/$AI_CLI_COMMAND" || return 1
		fi
	else
		echo '当前程序由其他方式安装，请使用原包管理器卸载。' >&2
		return 1
	fi
	if ai_cli_installed; then
		echo '仍检测到另一份安装，保留应用标记；请检查 PATH 中的重复安装。' >&2
		return 1
	fi
	ai_cli_mark remove || return 1
	echo "$AI_CLI_NAME 命令已卸载；配置、登录与会话已保留。"
}

ai_cli_uninstall() {
	local confirm
	read -r -p "卸载 $AI_CLI_NAME 命令？配置和会话将保留。(y/N): " confirm || return 1
	case "$confirm" in y|Y) kpanel_app_with_lock system ai_cli_uninstall_impl ;; *) echo '已取消。' ;; esac
}

ai_cli_project() (
	local directory
	ai_cli_require_installed || return 1
	read -r -p "项目目录（默认 $PWD）: " directory || return 1
	directory="${directory:-$PWD}"
	case "$directory" in '~') directory="$HOME" ;; '~/'*) directory="$HOME/${directory#\~/}" ;; esac
	[ -d "$directory" ] || { echo '项目目录不存在。' >&2; return 1; }
	cd -- "$directory" || return 1
	if [ "${1:-}" = resume ]; then
		case "$AI_CLI_COMMAND" in
			claude) claude --resume ;;
			codex) codex resume ;;
			opencode) opencode --continue ;;
		esac
	else
		"$AI_CLI_COMMAND"
	fi
)

ai_cli_login() {
	ai_cli_require_installed || return 1
	if [ "$AI_CLI_COMMAND" = claude ]; then
		claude auth login
	elif [ "$AI_CLI_COMMAND" = opencode ]; then
		opencode auth login
	else
		local choice key result
		echo '1. ChatGPT 设备码登录（适合远程服务器）'
		echo '2. OpenAI API Key 登录'
		read -r -p '请选择 [1]: ' choice || return 1
		case "${choice:-1}" in
			1) codex login --device-auth ;;
			2)
				read -r -s -p 'API Key: ' key || return 1
				echo
				[ -n "$key" ] || return 1
				printf '%s' "$key" | codex login --with-api-key
				result=$?
				unset key
				return "$result"
				;;
			*) return 1 ;;
		esac
	fi
}

ai_cli_auth() {
	ai_cli_require_installed || return 1
	if [ "$AI_CLI_COMMAND" = claude ]; then
		case "$1" in status) claude auth status ;; logout) claude auth logout ;; esac
	elif [ "$AI_CLI_COMMAND" = opencode ]; then
		case "$1" in status) opencode auth list ;; logout) opencode auth logout ;; esac
	else
		case "$1" in status) codex login status ;; logout) codex logout ;; esac
	fi
}

ai_cli_main() {
	ai_cli_select "$1" || return 1
	[ "$(id -u)" = 0 ] || { echo '请以 root 运行 k app，管理服务器上的安装。' >&2; return 1; }
	declare -F kpanel_app_with_lock >/dev/null && declare -F kpanel_app_update_marker >/dev/null || {
		echo '请通过最新版 kejilion.sh 的 k app 入口运行。' >&2; return 1;
	}
	local choice result=0
	while true; do
		if [ -t 1 ]; then
			clear 2>/dev/null || printf '\033[H\033[2J'
		fi
		echo
		echo "========== $AI_CLI_NAME 应用管理 =========="
		if ai_cli_installed; then
			echo "状态：已安装（$(command -v "$AI_CLI_COMMAND")）"
		else
			echo '状态：未安装'
		fi
		echo "当前用户：$(id -un) | HOME: $HOME"
		echo '终端工具：在此终端中运行，无需端口或常驻服务。'
		echo '1. 安装 / 识别已有安装'
		echo '2. 进入项目并启动'
		if [ "$AI_CLI_COMMAND" = opencode ]; then
			echo '3. 登录模型供应商'
			echo '4. 查看版本与已登录供应商'
			echo '5. 恢复项目最近会话'
		else
			echo '3. 登录账号'
			echo '4. 查看版本与登录状态'
			echo '5. 恢复项目会话'
		fi
		echo '6. 更新'
		echo '7. 查看原生命令帮助'
		echo '8. 卸载（保留配置和会话）'
		if [ "$AI_CLI_COMMAND" = opencode ]; then echo '9. 退出模型供应商'; else echo '9. 退出账号'; fi
		echo '0. 返回'
		read -r -p '请选择: ' choice || return "$result"
		case "$choice" in
			1) kpanel_app_with_lock system ai_cli_install_impl ;;
			2) ai_cli_project ;;
			3) ai_cli_login ;;
			4) ai_cli_require_installed && "$AI_CLI_COMMAND" --version && ai_cli_auth status ;;
			5) ai_cli_project resume ;;
			6) kpanel_app_with_lock system ai_cli_update_impl ;;
			7) ai_cli_require_installed && "$AI_CLI_COMMAND" --help ;;
			8) ai_cli_uninstall ;;
			9) ai_cli_auth logout ;;
			0) return "$result" ;;
			*) echo '无效选项。'; continue ;;
		esac
		result=$?
		[ "$result" -eq 0 ] || echo "操作未完成（退出码 $result），请检查上方输出。"
		read -r -p '按回车继续...' _ || return "$result"
	done
}
