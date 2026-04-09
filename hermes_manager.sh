#!/bin/bash
# Hermes Agent 终端管理脚本 (轻量版)
# 设计哲学：极简、直观、调用原生功能

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
NC='\033[0m'

# 确保 hermes 命令可用 (处理环境变量未加载的情况)
if ! command -v hermes >/dev/null 2>&1; then
    if [ -d "$HOME/.hermes/hermes-agent/venv/bin" ]; then
        export PATH="$HOME/.hermes/hermes-agent/venv/bin:$PATH"
    fi
fi

# 检查是否安装
check_installed() {
    if command -v hermes >/dev/null 2>&1; then return 0; else return 1; fi
}

# 获取版本号
get_version() {
    if check_installed; then
        hermes --version | head -n 1
    fi
}

# 获取网关状态
get_gateway_status() {
    if check_installed; then
        # 匹配后台 gateway 进程或 systemd 服务
        if pgrep -f "hermes_cli.main gateway" > /dev/null || pgrep -f "hermes gateway run" > /dev/null || pgrep -f "hermes-gateway" > /dev/null; then
            echo -e "${GREEN}运行中${NC}"
        else
            echo -e "${RED}已停止${NC}"
        fi
    else
        echo -e "${RED}未安装${NC}"
    fi
}

# 主菜单UI
show_menu() {
    clear
    echo -e "${CYAN}=================================================${NC}"
    echo -e "${YELLOW}           Hermes Agent 终端管理工具             ${NC}"
    echo -e "${CYAN}=================================================${NC}"
    echo -e " 运行状态 : $(get_gateway_status)"
    echo -e " 当前版本 : $(get_version)"
    echo -e "${CYAN}-------------------------------------------------${NC}"
    echo -e "${GREEN}1.${NC} 安装 Hermes Agent"
    echo -e "${GREEN}2.${NC} 启动 Gateway (消息网关/后台服务)"
    echo -e "${GREEN}3.${NC} 停止 Gateway"
    echo -e "${GREEN}4.${NC} API/模型管理 (提供商与模型切换)"
    echo -e "${GREEN}5.${NC} 启动终端对话UI (Interactive Chat)"
    echo -e "${GREEN}6.${NC} 运行初始化配置向导 (Setup Wizard)"
    echo -e "${GREEN}7.${NC} 检查并更新 Hermes"
    echo -e "${GREEN}8.${NC} 卸载 Hermes"
    echo -e "${GREEN}0.${NC} 退出"
    echo -e "${CYAN}=================================================${NC}"
    if ! read -p " 请输入数字 [0-8]: " choice; then
        echo -e "\n${GREEN}退出脚本。${NC}"
        exit 0
    fi
    echo ""
    
    case $choice in
        1)
            echo -e "${YELLOW}开始安装 Hermes Agent...${NC}"
            curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
            source ~/.bashrc
            hermes gateway install
            hermes gateway start
            ;;
        2)
            if check_installed; then
                echo -e "${YELLOW}正在启动 Gateway...${NC}"
                systemctl --user start hermes-gateway
                hermes gateway stop
                hermes gateway start
            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
            ;;
        3)
            if check_installed; then
                echo -e "${YELLOW}正在停止 Gateway...${NC}"
                hermes gateway stop
            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
            ;;
        4)
            if check_installed; then
                echo -e "${YELLOW}进入模型配置向导...${NC}"
                hermes model
            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
            ;;
        5)
            if check_installed; then
                echo -e "${YELLOW}即将进入交互式终端，输入 /exit 即可退出返回。${NC}"
                sleep 1
                hermes
            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
            ;;
        6)
            if check_installed; then
                echo -e "${YELLOW}正在启动初始化配置向导...${NC}"
                hermes setup
            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
            ;;
        7)
            if check_installed; then
                echo -e "${YELLOW}正在检查更新...${NC}"
                hermes update
            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
            ;;
        8)
            if check_installed; then
                read -p "确定要卸载 Hermes 吗？所有数据将被清除。(y/N): " confirm
                if [[ "$confirm" =~ ^[Yy]$ ]]; then
                    hermes uninstall
                else echo "已取消。"; fi
            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
            ;;
        0)
            echo -e "${GREEN}感谢使用，再见！${NC}"
            exit 0
            ;;
        *)
            echo -e "${RED}输入错误，请重新选择。${NC}"
            ;;
    esac
    echo ""
    read -p "按回车键返回主菜单..."
}

# 主循环
while true; do
    show_menu
done
