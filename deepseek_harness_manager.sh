#!/bin/bash
# DeepSeek Harness 管理脚本（基础版）
# 官方项目：https://github.com/deepseek-ai/deepseek-harness
# 仅提供：安装、启动、停止、API 管理、切换模型、命令行任务、更新、卸载。

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

DSH_HOME="${DSH_HOME:-$HOME/.dsh}"
DSH_ENV_FILE="${DSH_ENV_FILE:-$DSH_HOME/kejilion.env}"
MODEL_PATCH_FILE="${MODEL_PATCH_FILE:-$DSH_HOME/kejilion-model.patch.yml}"
SERVICE_FILE="${DEEPSEEK_HARNESS_SERVICE_FILE:-/etc/systemd/system/deepseek-harness.service}"
PID_FILE="${DEEPSEEK_HARNESS_PID_FILE:-$DSH_HOME/deepseek-harness.pid}"
LOG_FILE="${DEEPSEEK_HARNESS_LOG_FILE:-$DSH_HOME/deepseek-harness.log}"
APP_MARKER_FILE="${DEEPSEEK_HARNESS_APP_MARKER_FILE:-/home/docker/appno.txt}"
NPM_PACKAGE="@deepseek-ai/dsh"
NPM_INSTALL_SCRIPT_ALLOWLIST="@deepseek-ai/dsh-subprocess-local,koffi,node-pty,@google/genai,protobufjs"
DEEPSEEK_BASE_URL="https://api.deepseek.com"
DEFAULT_MODEL="deepseek-v4-flash"
LISTEN_HOST="127.0.0.1"
LISTEN_PORT="3080"
APP_ID="116"

require_root() {
	if [ "$(id -u)" -ne 0 ]; then
		echo -e "${RED}此操作需要 root 权限。${NC}"
		return 1
	fi
}

dsh_installed() {
	hash -r 2>/dev/null || true
	command -v dsh >/dev/null 2>&1
}

node_version_supported() {
	local version major minor
	command -v node >/dev/null 2>&1 || return 1
	version=$(node -p 'process.versions.node' 2>/dev/null) || return 1
	major=${version%%.*}
	minor=${version#*.}
	minor=${minor%%.*}
	case "$major:$minor" in
		22:*) [ "$minor" -ge 19 ] ;;
		*) [ "$major" -ge 24 ] ;;
	esac
}

npm_allow_scripts_supported() {
	local version major minor
	version="${1:-$(npm --version 2>/dev/null)}" || return 1
	version=${version#v}
	major=${version%%.*}
	minor=${version#*.}
	minor=${minor%%.*}
	case "$major:$minor" in
		*[!0-9:]*|:*) return 1 ;;
		11:*) [ "$minor" -ge 16 ] ;;
		*) [ "$major" -ge 12 ] ;;
	esac
}

install_dsh_npm_package() {
	local -a npm_args=(install -g)
	if npm_allow_scripts_supported; then
		npm_args+=("--allow-scripts=${NPM_INSTALL_SCRIPT_ALLOWLIST}")
	fi
	npm_args+=("${NPM_PACKAGE}@latest")
	npm "${npm_args[@]}"
}

systemd_available() {
	command -v systemctl >/dev/null 2>&1 \
		&& [ "$(ps -p 1 -o comm= 2>/dev/null | tr -d '[:space:]')" = "systemd" ]
}

harness_running() {
	if systemd_available \
		&& systemctl is-active --quiet deepseek-harness.service 2>/dev/null; then
		return 0
	fi
	if [ -r "$PID_FILE" ]; then
		local pid
		pid=$(cat "$PID_FILE" 2>/dev/null)
		case "$pid" in
			''|*[!0-9]*) ;;
			*) kill -0 "$pid" 2>/dev/null && return 0 ;;
		esac
	fi
	pgrep -u "$(id -u)" -f '[n]ode.*[/]dsh.*([[:space:]]web|--profile[[:space:]]+web)' >/dev/null 2>&1
}

web_ready() {
	command -v curl >/dev/null 2>&1 \
		&& curl -fsS --max-time 2 "http://${LISTEN_HOST}:${LISTEN_PORT}/" >/dev/null 2>&1
}

wait_for_web_ready() {
	local _
	for _ in {1..30}; do
		harness_running && web_ready && return 0
		sleep 1
	done
	return 1
}

read_api_key() {
	[ -r "$DSH_ENV_FILE" ] || return 1
	sed -n 's/^DEEPSEEK_API_KEY=//p' "$DSH_ENV_FILE" | tail -n 1
}

mask_api_key() {
	local api_key="$1"
	if [ "${#api_key}" -le 8 ]; then
		printf '%s' '********'
	else
		printf '%s****%s' "${api_key:0:3}" "${api_key: -4}"
	fi
}

valid_api_key() {
	[[ "$1" =~ ^sk-[A-Za-z0-9._-]+$ ]]
}

write_api_key() {
	local api_key="$1" temporary_file
	valid_api_key "$api_key" || return 1
	mkdir -p "$DSH_HOME" || return 1
	umask 077
	temporary_file=$(mktemp "${DSH_ENV_FILE}.tmp.XXXXXX") || return 1
	{
		printf 'DEEPSEEK_API_KEY=%s\n' "$api_key"
		printf 'DEEPSEEK_BASE_URL=%s\n' "$DEEPSEEK_BASE_URL"
	} >"$temporary_file"
	chmod 600 "$temporary_file"
	mv -f "$temporary_file" "$DSH_ENV_FILE"
}

delete_api_key() {
	[ -e "$DSH_ENV_FILE" ] || return 0
	: >"$DSH_ENV_FILE"
	chmod 600 "$DSH_ENV_FILE"
}

load_managed_environment() {
	export DSH_HOME DSH_TELEMETRY_DISABLED=1
	if [ -r "$DSH_ENV_FILE" ]; then
		set -a
		# shellcheck disable=SC1090
		. "$DSH_ENV_FILE"
		set +a
	fi
}

valid_model_id() {
	case "$1" in
		''|*[!A-Za-z0-9._:/-]*) return 1 ;;
		*) return 0 ;;
	esac
}

current_model() {
	local model
	if [ -r "$MODEL_PATCH_FILE" ]; then
		model=$(sed -n 's/^[[:space:]]*model:[[:space:]]*//p' "$MODEL_PATCH_FILE" | tail -n 1)
	fi
	printf '%s' "${model:-$DEFAULT_MODEL}"
}

write_model_patch() {
	local model="$1" temporary_file
	valid_model_id "$model" || return 1
	mkdir -p "$DSH_HOME" || return 1
	umask 077
	temporary_file=$(mktemp "${MODEL_PATCH_FILE}.tmp.XXXXXX") || return 1
	{
		printf '%s\n' '- id: agent-default-model'
		printf '%s\n' '  config:'
		printf '%s\n' '    provider: deepseek-official'
		printf '    model: %s\n' "$model"
	} >"$temporary_file"
	chmod 600 "$temporary_file"
	mv -f "$temporary_file" "$MODEL_PATCH_FILE"
}

mark_app_installed() {
	mkdir -p "$(dirname "$APP_MARKER_FILE")" 2>/dev/null || return 0
	touch "$APP_MARKER_FILE" 2>/dev/null || return 0
	grep -qxF "$APP_ID" "$APP_MARKER_FILE" 2>/dev/null || echo "$APP_ID" >>"$APP_MARKER_FILE"
}

unmark_app_installed() {
	[ -f "$APP_MARKER_FILE" ] || return 0
	sed -i "/^${APP_ID}$/d" "$APP_MARKER_FILE"
}

install_node24() {
	require_root || return 1
	command -v curl >/dev/null 2>&1 || {
		echo -e "${RED}缺少 curl，无法安装 Node.js。${NC}"
		return 1
	}
	echo -e "${YELLOW}正在安装 Node.js 24...${NC}"
	if command -v apt-get >/dev/null 2>&1; then
		curl -fsSL https://deb.nodesource.com/setup_24.x | bash - || return 1
		apt-get install -y nodejs || return 1
	elif command -v dnf >/dev/null 2>&1; then
		curl -fsSL https://rpm.nodesource.com/setup_24.x | bash - || return 1
		dnf install -y nodejs || return 1
	else
		echo -e "${RED}当前系统不支持自动安装 Node.js，请先安装 Node.js 22.19+ 或 24+。${NC}"
		return 1
	fi
	node_version_supported
}

ensure_node_runtime() {
	if node_version_supported && command -v npm >/dev/null 2>&1; then
		return 0
	fi
	install_node24
}

configure_systemd_service() {
	local dsh_bin node_bin service_path
	dsh_bin=$(command -v dsh) || return 1
	node_bin=$(command -v node) || return 1
	service_path="$(dirname "$dsh_bin"):$(dirname "$node_bin"):/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin"
	mkdir -p "$DSH_HOME" || return 1
	cat >"$SERVICE_FILE" <<EOF
[Unit]
Description=DeepSeek Harness Web UI
After=network-online.target
Wants=network-online.target

[Service]
Type=simple
User=root
WorkingDirectory=$HOME
Environment=HOME=$HOME
Environment=DSH_HOME=$DSH_HOME
Environment=DSH_TELEMETRY_DISABLED=1
Environment=PATH=$service_path
EnvironmentFile=-$DSH_ENV_FILE
ExecStart=$dsh_bin web --patch $MODEL_PATCH_FILE --host $LISTEN_HOST --port $LISTEN_PORT
Restart=on-failure
RestartSec=3

[Install]
WantedBy=multi-user.target
EOF
	chmod 644 "$SERVICE_FILE"
	systemctl daemon-reload
}

initialize_profiles() {
	load_managed_environment
	dsh --profile headless --dump-default-config >/dev/null || return 1
	dsh web --dump-default-config >/dev/null || return 1
}

install_deepseek_harness() {
	require_root || return 1
	if dsh_installed; then
		echo -e "${YELLOW}DeepSeek Harness 已安装，可使用更新功能升级。${NC}"
		mark_app_installed
		return 0
	fi
	ensure_node_runtime || return 1
	echo -e "${YELLOW}正在安装官方 $NPM_PACKAGE，首次安装可能需要数分钟...${NC}"
	install_dsh_npm_package || return 1
	dsh_installed || {
		echo -e "${RED}安装完成后仍找不到 dsh 命令。${NC}"
		return 1
	}
	[ -f "$MODEL_PATCH_FILE" ] || write_model_patch "$DEFAULT_MODEL" || return 1
	initialize_profiles || return 1
	if systemd_available; then
		configure_systemd_service || return 1
	fi
	mark_app_installed
	echo -e "${GREEN}DeepSeek Harness 安装完成：$(dsh --version 2>/dev/null)${NC}"
	echo "默认模型：$(current_model)"
	echo "Web UI 默认仅监听：http://${LISTEN_HOST}:${LISTEN_PORT}"
	echo "安装后不会自动启动，请返回菜单选择启动。"
}

start_deepseek_harness() {
	require_root || return 1
	dsh_installed || {
		echo -e "${RED}请先安装 DeepSeek Harness。${NC}"
		return 1
	}
	[ -f "$MODEL_PATCH_FILE" ] || write_model_patch "$DEFAULT_MODEL" || return 1
	if systemd_available; then
		configure_systemd_service || return 1
		systemctl enable --now deepseek-harness.service || return 1
	else
		if harness_running; then
			echo -e "${YELLOW}DeepSeek Harness 已在运行。${NC}"
			return 0
		fi
		mkdir -p "$DSH_HOME"
		load_managed_environment
		nohup dsh web --patch "$MODEL_PATCH_FILE" --host "$LISTEN_HOST" --port "$LISTEN_PORT" >"$LOG_FILE" 2>&1 &
		echo "$!" >"$PID_FILE"
	fi
	if wait_for_web_ready; then
		mark_app_installed
		echo -e "${GREEN}DeepSeek Harness 已启动。${NC}"
		echo "本机访问：http://${LISTEN_HOST}:${LISTEN_PORT}"
		echo "远程访问建议：ssh -L ${LISTEN_PORT}:${LISTEN_HOST}:${LISTEN_PORT} <服务器>"
	else
		echo -e "${RED}启动失败，请检查 $LOG_FILE 或 systemctl status deepseek-harness。${NC}"
		return 1
	fi
}

stop_deepseek_harness() {
	require_root || return 1
	if systemd_available && [ -f "$SERVICE_FILE" ]; then
		systemctl disable --now deepseek-harness.service >/dev/null 2>&1 || true
	fi
	if [ -r "$PID_FILE" ]; then
		local pid
		pid=$(cat "$PID_FILE" 2>/dev/null)
		case "$pid" in
			''|*[!0-9]*) ;;
			*) kill "$pid" 2>/dev/null || true ;;
		esac
		rm -f -- "$PID_FILE"
	fi
	sleep 1
	if harness_running; then
		echo -e "${RED}DeepSeek Harness 仍在运行，请检查残留进程。${NC}"
		return 1
	fi
	echo -e "${GREEN}DeepSeek Harness 已停止，并取消开机启动。${NC}"
}

restart_if_running() {
	local was_running=false
	harness_running && was_running=true
	[ "$was_running" = "true" ] || return 0
	if systemd_available && [ -f "$SERVICE_FILE" ]; then
		configure_systemd_service \
			&& systemctl restart deepseek-harness.service \
			&& wait_for_web_ready
	else
		stop_deepseek_harness && start_deepseek_harness
	fi
}

api_management_menu() {
	local choice api_key confirm was_running
	dsh_installed || {
		echo -e "${RED}请先安装 DeepSeek Harness。${NC}"
		return 1
	}
	while true; do
		clear 2>/dev/null || true
		api_key=$(read_api_key)
		echo -e "${CYAN}=======================================${NC}"
		echo "          DeepSeek Harness API 管理"
		echo -e "${CYAN}=======================================${NC}"
		if [ -n "$api_key" ]; then
			echo -e "脚本托管 API：${GREEN}已配置 $(mask_api_key "$api_key")${NC}"
		else
			echo -e "脚本托管 API：${RED}未配置${NC}"
		fi
		echo "Base URL：$DEEPSEEK_BASE_URL"
		echo "1. 设置或更换 API Key"
		echo "2. 删除脚本托管 API Key"
		echo "0. 返回"
		read -r -p "请输入选项: " choice
		case "$choice" in
			1)
				read -r -s -p "请输入 DeepSeek API Key: " api_key
				echo
				if ! valid_api_key "$api_key"; then
					echo -e "${RED}API Key 格式无效，应以 sk- 开头且不能包含空格。${NC}"
				else
					harness_running && was_running=true || was_running=false
					if write_api_key "$api_key"; then
						[ "$was_running" = "true" ] && restart_if_running
						echo -e "${GREEN}API Key 已保存，文件权限为 600。${NC}"
					fi
				fi
				read -r -p "按回车键继续..."
				;;
			2)
				read -r -p "确定删除脚本托管的 API Key？(y/N): " confirm
				case "$confirm" in
					[yY])
						harness_running && was_running=true || was_running=false
						delete_api_key
						[ "$was_running" = "true" ] && restart_if_running
						echo -e "${GREEN}脚本托管 API Key 已删除。${NC}"
						;;
					*) echo "已取消。" ;;
				esac
				read -r -p "按回车键继续..."
				;;
			0) return 0 ;;
		esac
	done
}

change_model() {
	local choice model
	dsh_installed || {
		echo -e "${RED}请先安装 DeepSeek Harness。${NC}"
		return 1
	}
	echo "当前默认模型：$(current_model)"
	echo "1. deepseek-v4-flash"
	echo "2. deepseek-v4-pro"
	echo "3. 手动输入模型 ID"
	echo "0. 取消"
	read -r -p "请选择模型: " choice
	case "$choice" in
		1) model="deepseek-v4-flash" ;;
		2) model="deepseek-v4-pro" ;;
		3) read -r -p "请输入模型 ID: " model ;;
		0) return 0 ;;
		*) echo -e "${RED}无效选项。${NC}"; return 1 ;;
	esac
	if ! write_model_patch "$model"; then
		echo -e "${RED}模型 ID 无效。${NC}"
		return 1
	fi
	restart_if_running
	echo -e "${GREEN}默认模型已切换为：$model${NC}"
}

run_headless_task() {
	local task api_key
	dsh_installed || {
		echo -e "${RED}请先安装 DeepSeek Harness。${NC}"
		return 1
	}
	api_key=$(read_api_key)
	if [ -z "$api_key" ]; then
		echo -e "${RED}尚未配置脚本托管的 DeepSeek API Key。${NC}"
		return 1
	fi
	read -r -p "请输入命令行任务: " task
	[ -n "$task" ] || {
		echo -e "${RED}任务不能为空。${NC}"
		return 1
	}
	load_managed_environment
	dsh --profile headless --patch "$MODEL_PATCH_FILE" "$task"
}

update_deepseek_harness() {
	local was_running=false
	require_root || return 1
	dsh_installed || {
		echo -e "${RED}请先安装 DeepSeek Harness。${NC}"
		return 1
	}
	harness_running && was_running=true
	echo -e "${YELLOW}正在更新官方 $NPM_PACKAGE...${NC}"
	install_dsh_npm_package || return 1
	initialize_profiles || return 1
	[ "$was_running" = "true" ] && restart_if_running
	mark_app_installed
	echo -e "${GREEN}DeepSeek Harness 更新完成：$(dsh --version 2>/dev/null)${NC}"
}

uninstall_deepseek_harness() {
	local confirm remove_data
	require_root || return 1
	read -r -p "确定卸载 DeepSeek Harness？(y/N): " confirm
	case "$confirm" in
		[yY]) ;;
		*) echo "已取消。"; return 0 ;;
	esac
	stop_deepseek_harness >/dev/null 2>&1 || true
	if systemd_available && [ -f "$SERVICE_FILE" ]; then
		rm -f -- "$SERVICE_FILE"
		systemctl daemon-reload
	fi
	if dsh_installed; then
		npm uninstall -g "$NPM_PACKAGE" || return 1
	fi
	read -r -p "是否同时删除 $DSH_HOME 中的配置、凭据引用和会话？(y/N): " remove_data
	case "$remove_data" in
		[yY])
			case "$DSH_HOME" in
				"$HOME/.dsh"|/root/.dsh) rm -rf -- "$DSH_HOME" ;;
				*) echo -e "${YELLOW}自定义 DSH_HOME 未自动删除：$DSH_HOME${NC}" ;;
			esac
			;;
	esac
	if dsh_installed; then
		echo -e "${RED}卸载后仍能找到 dsh 命令，请检查 npm 全局目录。${NC}"
		return 1
	fi
	unmark_app_installed
	echo -e "${GREEN}DeepSeek Harness 已卸载。Node.js 及 npm 缓存未自动删除。${NC}"
}

show_menu() {
	local install_status running_status api_status model version
	if dsh_installed; then
		version=$(dsh --version 2>/dev/null)
		install_status="${GREEN}已安装 ${version}${NC}"
	else
		install_status="${RED}未安装${NC}"
	fi
	if harness_running; then
		running_status="${GREEN}运行中${NC}"
	else
		running_status="${YELLOW}已停止${NC}"
	fi
	if [ -n "$(read_api_key)" ]; then
		api_status="${GREEN}已配置${NC}"
	else
		api_status="${RED}未配置${NC}"
	fi
	model=$(current_model)
	clear 2>/dev/null || true
	echo -e "${CYAN}=================================================${NC}"
	echo "          DeepSeek Harness 基础管理工具"
	echo -e "${CYAN}=================================================${NC}"
	echo -e "安装状态：$install_status    运行状态：$running_status"
	echo -e "API 状态：$api_status    默认模型：$model"
	echo "Web UI：http://${LISTEN_HOST}:${LISTEN_PORT}（仅本机）"
	echo -e "${CYAN}-------------------------------------------------${NC}"
	echo "1. 安装"
	echo "2. 启动"
	echo "3. 停止"
	echo "4. API 管理"
	echo "5. 换模型"
	echo "6. 命令行任务"
	echo "7. 更新"
	echo "8. 卸载"
	echo "0. 返回应用市场"
	echo -e "${CYAN}=================================================${NC}"
}

deepseek_harness_main() {
	local choice
	while true; do
		show_menu
		read -r -p "请输入选项 [0-8]: " choice || return 0
		case "$choice" in
			1) install_deepseek_harness ;;
			2) start_deepseek_harness ;;
			3) stop_deepseek_harness ;;
			4) api_management_menu ;;
			5) change_model ;;
			6) run_headless_task ;;
			7) update_deepseek_harness ;;
			8) uninstall_deepseek_harness ;;
			0) return 0 ;;
			*) echo -e "${RED}无效选项。${NC}" ;;
		esac
		echo
		read -r -p "按回车键返回菜单..."
	done
}

if [ "${BASH_SOURCE[0]}" = "$0" ]; then
	deepseek_harness_main
fi
