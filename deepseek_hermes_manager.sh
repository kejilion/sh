#!/bin/bash
# DeepSeek Hermes 终端管理脚本（基础轻量版）
# 仅提供：安装、启动、停止、API 管理、切换模型、命令行聊天、更新、卸载。

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

HERMES_DATA_DIR="${HERMES_HOME:-$HOME/.hermes}"
HERMES_ENV_FILE="${HERMES_DATA_DIR}/.env"
HERMES_INSTALLER_URL="https://hermes-agent.nousresearch.com/install.sh"
DEEPSEEK_BASE_URL="https://api.deepseek.com"
DEFAULT_DEEPSEEK_MODEL="deepseek-v4-pro"
APP_ID="116"

refresh_hermes_path() {
	local candidate
	for candidate in \
		"/usr/local/bin" \
		"$HOME/.local/bin" \
		"$HERMES_DATA_DIR/hermes-agent/venv/bin"; do
		[ -d "$candidate" ] || continue
		case ":$PATH:" in
			*":$candidate:"*) ;;
			*) PATH="$candidate:$PATH" ;;
		esac
	done
	export PATH
	hash -r 2>/dev/null || true
}

hermes_installed() {
	refresh_hermes_path
	command -v hermes >/dev/null 2>&1
}

hermes_running() {
	if command -v systemctl >/dev/null 2>&1 \
		&& systemctl --user is-active --quiet hermes-gateway.service 2>/dev/null; then
		return 0
	fi
	# The bracketed first character prevents pgrep from matching its own argv.
	pgrep -u "$(id -u)" -f '[p]ython([^[:space:]]*)?[[:space:]]+-m[[:space:]]+hermes_cli\.main[[:space:]]+gateway[[:space:]]+run([[:space:]]|$)' >/dev/null 2>&1
}

read_deepseek_api_key() {
	[ -r "$HERMES_ENV_FILE" ] || return 1
	sed -n 's/^[[:space:]]*DEEPSEEK_API_KEY=//p' "$HERMES_ENV_FILE" \
		| tail -n 1 \
		| sed 's/^"//;s/"$//;s/^'"'"'//;s/'"'"'$//'
}

mask_api_key() {
	local api_key="$1"
	local key_length=${#api_key}
	if [ "$key_length" -le 8 ]; then
		printf '%s' '********'
	else
		printf '%s****%s' "${api_key:0:3}" "${api_key: -4}"
	fi
}

write_deepseek_api_key() {
	local api_key="$1"
	local temporary_file

	mkdir -p "$HERMES_DATA_DIR" || return 1
	umask 077
	temporary_file=$(mktemp "${HERMES_ENV_FILE}.tmp.XXXXXX") || return 1
	if [ -f "$HERMES_ENV_FILE" ]; then
		grep -v '^[[:space:]]*DEEPSEEK_API_KEY=' "$HERMES_ENV_FILE" > "$temporary_file" || true
	fi
	printf 'DEEPSEEK_API_KEY=%s\n' "$api_key" >> "$temporary_file"
	mv -f -- "$temporary_file" "$HERMES_ENV_FILE"
	chmod 600 "$HERMES_ENV_FILE"
}

delete_deepseek_api_key() {
	local temporary_file
	[ -f "$HERMES_ENV_FILE" ] || return 0
	umask 077
	temporary_file=$(mktemp "${HERMES_ENV_FILE}.tmp.XXXXXX") || return 1
	grep -v '^[[:space:]]*DEEPSEEK_API_KEY=' "$HERMES_ENV_FILE" > "$temporary_file" || true
	mv -f -- "$temporary_file" "$HERMES_ENV_FILE"
	chmod 600 "$HERMES_ENV_FILE"
}

current_model() {
	local model_name
	hermes_installed || return 0
	model_name=$(hermes config get model.default 2>/dev/null | tail -n 1 | tr -d '"' | xargs)
	if [ -z "$model_name" ] || [ "$model_name" = "null" ]; then
		model_name=$(hermes config get model.model 2>/dev/null | tail -n 1 | tr -d '"' | xargs)
	fi
	[ "$model_name" = "null" ] && model_name=""
	printf '%s' "$model_name"
}

current_provider() {
	local provider_name
	hermes_installed || return 0
	provider_name=$(hermes config get model.provider 2>/dev/null | tail -n 1 | tr -d '"' | xargs)
	[ "$provider_name" = "null" ] && provider_name=""
	printf '%s' "$provider_name"
}

apply_deepseek_model() {
	local model_name="$1"
	local restart_gateway="${2:-true}"
	if ! hermes_installed; then
		echo -e "${RED}请先安装 DeepSeek Hermes。${NC}"
		return 1
	fi
	if [ -z "$model_name" ]; then
		echo -e "${RED}模型 ID 不能为空。${NC}"
		return 1
	fi

	hermes config set model.provider deepseek || return 1
	hermes config set model.default "$model_name" || return 1
	hermes config set model.base_url "$DEEPSEEK_BASE_URL" || return 1
	echo -e "${GREEN}模型已切换为：${model_name}${NC}"

	if [ "$restart_gateway" = "true" ] && hermes_running; then
		echo -e "${YELLOW}正在重启 Gateway 以应用新模型...${NC}"
		hermes gateway restart
	fi
}

ensure_default_model() {
	local model_name provider_name restart_gateway
	restart_gateway="${1:-true}"
	model_name=$(current_model)
	provider_name=$(current_provider)
	if [ "$provider_name" = "deepseek" ] && [ -n "$model_name" ]; then
		return 0
	fi
	case "$model_name" in
		deepseek-*) ;;
		*) model_name="$DEFAULT_DEEPSEEK_MODEL" ;;
	esac
	apply_deepseek_model "$model_name" "$restart_gateway"
}

mark_app_installed() {
	mkdir -p /home/docker 2>/dev/null || return 0
	touch /home/docker/appno.txt 2>/dev/null || return 0
	grep -qxF "$APP_ID" /home/docker/appno.txt 2>/dev/null \
		|| echo "$APP_ID" >> /home/docker/appno.txt
}

unmark_app_installed() {
	[ -f /home/docker/appno.txt ] || return 0
	sed -i "/^${APP_ID}$/d" /home/docker/appno.txt
}

install_prerequisites() {
	if command -v git >/dev/null 2>&1 \
		&& command -v curl >/dev/null 2>&1 \
		&& command -v xz >/dev/null 2>&1; then
		return 0
	fi

	echo -e "${YELLOW}正在安装 Git、curl 和 xz...${NC}"
	if command -v apt-get >/dev/null 2>&1; then
		apt-get update && apt-get install -y git curl xz-utils ca-certificates
	elif command -v dnf >/dev/null 2>&1; then
		dnf install -y git curl xz ca-certificates
	elif command -v yum >/dev/null 2>&1; then
		yum install -y git curl xz ca-certificates
	elif command -v apk >/dev/null 2>&1; then
		apk add git curl xz ca-certificates
	elif command -v pacman >/dev/null 2>&1; then
		pacman -Sy --noconfirm git curl xz ca-certificates
	elif command -v zypper >/dev/null 2>&1; then
		zypper --non-interactive install git curl xz ca-certificates
	else
		echo -e "${RED}未识别到支持的软件包管理器，请手动安装 git、curl、xz。${NC}"
		return 1
	fi
}

install_deepseek_hermes() {
	local installer_file
	if hermes_installed; then
		echo -e "${YELLOW}Hermes 已安装，无需重复安装。${NC}"
		mark_app_installed
		return 0
	fi

	install_prerequisites || return 1
	installer_file=$(mktemp) || return 1
	echo -e "${YELLOW}正在下载并安装 Hermes 基础轻量版...${NC}"
	if ! curl -fsSL "$HERMES_INSTALLER_URL" -o "$installer_file"; then
		rm -f -- "$installer_file"
		echo -e "${RED}Hermes 安装脚本下载失败。${NC}"
		return 1
	fi

	if ! bash "$installer_file" \
		--skip-setup \
		--skip-browser \
		--skip-computer-use \
		--no-skills; then
		rm -f -- "$installer_file"
		echo -e "${RED}Hermes 安装失败，请检查上方输出。${NC}"
		return 1
	fi
	rm -f -- "$installer_file"
	refresh_hermes_path

	if ! hermes_installed; then
		echo -e "${RED}安装程序已结束，但未找到 hermes 命令。${NC}"
		return 1
	fi

	mark_app_installed
	echo -e "${GREEN}DeepSeek Hermes 基础轻量版安装完成。${NC}"
	echo "下一步请进入“API 管理”设置 DeepSeek API Key，再启动或聊天。"
}

start_deepseek_hermes() {
	local api_key
	if ! hermes_installed; then
		echo -e "${RED}请先安装 DeepSeek Hermes。${NC}"
		return 1
	fi
	api_key=$(read_deepseek_api_key)
	if [ -z "$api_key" ]; then
		echo -e "${RED}尚未配置 DeepSeek API Key，请先进入 API 管理。${NC}"
		return 1
	fi
	ensure_default_model false || return 1

	echo -e "${YELLOW}正在启动 Hermes Gateway...${NC}"
	hermes gateway install >/dev/null 2>&1 || true
	if hermes gateway start; then
		mark_app_installed
		echo -e "${GREEN}Hermes Gateway 已启动。${NC}"
	else
		echo -e "${RED}Gateway 启动失败，请查看上方输出。${NC}"
		return 1
	fi
}

stop_deepseek_hermes() {
	if ! hermes_installed; then
		echo -e "${RED}请先安装 DeepSeek Hermes。${NC}"
		return 1
	fi
	echo -e "${YELLOW}正在停止 Hermes Gateway...${NC}"
	hermes gateway stop
}

api_management_menu() {
	local choice api_key confirm
	if ! hermes_installed; then
		echo -e "${RED}请先安装 DeepSeek Hermes。${NC}"
		return 1
	fi

	while true; do
		clear
		api_key=$(read_deepseek_api_key)
		echo -e "${CYAN}=======================================${NC}"
		echo "            DeepSeek API 管理"
		echo -e "${CYAN}=======================================${NC}"
		if [ -n "$api_key" ]; then
			echo -e "API 状态：${GREEN}已配置 $(mask_api_key "$api_key")${NC}"
		else
			echo -e "API 状态：${RED}未配置${NC}"
		fi
		echo "Base URL：$DEEPSEEK_BASE_URL"
		echo "---------------------------------------"
		echo "1. 设置或更换 API Key"
		echo "2. 删除 API Key"
		echo "0. 返回"
		read -r -p "请输入选项: " choice

		case "$choice" in
			1)
				read -r -s -p "请输入 DeepSeek API Key: " api_key
				echo
				if [ -z "$api_key" ]; then
					echo -e "${RED}API Key 不能为空。${NC}"
				elif write_deepseek_api_key "$api_key"; then
					if ensure_default_model false; then
						if hermes_running; then
							hermes gateway restart
						fi
						echo -e "${GREEN}DeepSeek API Key 已安全保存。${NC}"
					else
						echo -e "${YELLOW}API Key 已保存，但 DeepSeek 模型配置失败。${NC}"
					fi
				else
					echo -e "${RED}API Key 保存失败。${NC}"
				fi
				read -r -p "按回车键继续..."
				;;
			2)
				read -r -p "确定删除 DeepSeek API Key？(y/N): " confirm
				case "$confirm" in
					[yY])
						if hermes_running; then
							hermes gateway stop >/dev/null 2>&1 || true
						fi
						delete_deepseek_api_key
						echo -e "${GREEN}DeepSeek API Key 已删除。${NC}"
						;;
					*) echo "已取消。" ;;
				esac
				read -r -p "按回车键继续..."
				;;
			0) return 0 ;;
			*) sleep 1 ;;
		esac
	done
}

change_deepseek_model() {
	local choice model_name
	if ! hermes_installed; then
		echo -e "${RED}请先安装 DeepSeek Hermes。${NC}"
		return 1
	fi

	echo "当前模型：$(current_model)"
	echo "1. deepseek-v4-pro"
	echo "2. deepseek-v4-flash"
	echo "3. 手动输入模型 ID"
	echo "0. 取消"
	read -r -p "请选择模型: " choice
	case "$choice" in
		1) model_name="deepseek-v4-pro" ;;
		2) model_name="deepseek-v4-flash" ;;
		3) read -r -p "请输入模型 ID: " model_name ;;
		0) return 0 ;;
		*) echo -e "${RED}无效选项。${NC}"; return 1 ;;
	esac
	apply_deepseek_model "$model_name"
}

chat_with_deepseek_hermes() {
	local api_key
	if ! hermes_installed; then
		echo -e "${RED}请先安装 DeepSeek Hermes。${NC}"
		return 1
	fi
	api_key=$(read_deepseek_api_key)
	if [ -z "$api_key" ]; then
		echo -e "${RED}尚未配置 DeepSeek API Key，请先进入 API 管理。${NC}"
		return 1
	fi
	ensure_default_model || return 1
	echo -e "${YELLOW}正在进入 Hermes 命令行聊天，退出后将返回本菜单。${NC}"
	hermes
}

update_deepseek_hermes() {
	if ! hermes_installed; then
		echo -e "${RED}请先安装 DeepSeek Hermes。${NC}"
		return 1
	fi
	echo -e "${YELLOW}正在更新 Hermes...${NC}"
	if hermes update; then
		mark_app_installed
		echo -e "${GREEN}Hermes 更新完成。${NC}"
	fi
}

uninstall_deepseek_hermes() {
	local confirm
	if ! hermes_installed; then
		echo -e "${YELLOW}Hermes 未安装。${NC}"
		unmark_app_installed
		return 0
	fi

	read -r -p "确定卸载 Hermes？官方卸载器会询问是否保留配置。(y/N): " confirm
	case "$confirm" in
		[yY]) ;;
		*) echo "已取消。"; return 0 ;;
	esac

	hermes gateway stop >/dev/null 2>&1 || true
	hermes uninstall
	refresh_hermes_path
	if hermes_installed; then
		echo -e "${YELLOW}仍检测到 hermes 命令，未移除应用市场安装标记。${NC}"
		return 1
	fi
	unmark_app_installed
	echo -e "${GREEN}Hermes 已卸载。${NC}"
}

show_menu() {
	local install_status running_status model_name api_key
	if hermes_installed; then
		install_status="${GREEN}已安装${NC}"
		model_name=$(current_model)
		[ -n "$model_name" ] || model_name="未配置"
		if hermes_running; then
			running_status="${GREEN}运行中${NC}"
		else
			running_status="${YELLOW}已停止${NC}"
		fi
	else
		install_status="${RED}未安装${NC}"
		running_status="${RED}未运行${NC}"
		model_name="未配置"
	fi
	api_key=$(read_deepseek_api_key)

	clear
	echo -e "${CYAN}=================================================${NC}"
	echo "       DeepSeek Hermes 基础轻量管理工具"
	echo -e "${CYAN}=================================================${NC}"
	echo -e "安装状态：${install_status}    运行状态：${running_status}"
	echo "当前模型：${model_name}"
	if [ -n "$api_key" ]; then
		echo -e "API 状态：${GREEN}已配置 $(mask_api_key "$api_key")${NC}"
	else
		echo -e "API 状态：${RED}未配置${NC}"
	fi
	echo -e "${CYAN}-------------------------------------------------${NC}"
	echo "1. 安装"
	echo "2. 启动"
	echo "3. 停止"
	echo "4. API 管理"
	echo "5. 换模型"
	echo "6. 命令行聊天"
	echo "7. 更新"
	echo "8. 卸载"
	echo "0. 返回应用市场"
	echo -e "${CYAN}=================================================${NC}"
}

deepseek_hermes_main() {
	local menu_choice
	refresh_hermes_path
	while true; do
		show_menu
		read -r -p "请输入选项 [0-8]: " menu_choice || return 0
		case "$menu_choice" in
			1) install_deepseek_hermes ;;
			2) start_deepseek_hermes ;;
			3) stop_deepseek_hermes ;;
			4) api_management_menu ;;
			5) change_deepseek_model ;;
			6) chat_with_deepseek_hermes ;;
			7) update_deepseek_hermes ;;
			8) uninstall_deepseek_hermes ;;
			0) return 0 ;;
			*) echo -e "${RED}无效选项。${NC}" ;;
		esac
		echo
		read -r -p "按回车键返回菜单..."
	done
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	deepseek_hermes_main
fi
