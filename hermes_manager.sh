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

# --- 科技lion 增强版 API 管理核心 ---
CONFIG_FILE="$HOME/.hermes/config.yaml"

config_tool() {
    python3 - "$CONFIG_FILE" "$@" <<'EOF'
import sys, yaml, json, os

path = sys.argv[1]
action = sys.argv[2]

def load():
    if not os.path.exists(path):
        return {}
    try:
        with open(path, 'r', encoding='utf-8') as f:
            return yaml.safe_load(f) or {}
    except:
        return {}

def save(d):
    with open(path, 'w', encoding='utf-8') as f:
        yaml.dump(d, f, sort_keys=False, allow_unicode=True)

try:
    data = load()
    if action == "get_info":
        m = data.get('model', {})
        res = {"m": m.get('default', '-'), "p": m.get('provider', '-'), "u": m.get('base_url', '-')}
        print(json.dumps(res))
    
    elif action == "list_p":
        print(json.dumps(data.get('custom_providers', [])))
    
    elif action == "add_p":
        n, u, k, m = sys.argv[3:7]
        ps = data.get('custom_providers', [])
        if not isinstance(ps, list): ps = []
        ps = [p for p in ps if p.get('name') != n]
        ps.append({"name": n, "base_url": u, "api_key": k, "model": m})
        data['custom_providers'] = ps
        save(data)
    
    elif action == "bulk_add":
        n_base, u, k, models_json = sys.argv[3:7]
        new_m_ids = json.loads(models_json)
        ps = data.get('custom_providers', [])
        if not isinstance(ps, list): ps = []
        # 移除旧的同前缀条目
        ps = [p for p in ps if not (isinstance(p, dict) and p.get('name', '').startswith(n_base + "/"))]
        # 移除可能存在的同名根条目
        ps = [p for p in ps if p.get('name') != n_base]
        for m_id in new_m_ids:
            ps.append({"name": f"{n_base}/{m_id}", "base_url": u, "api_key": k, "model": m_id})
        data['custom_providers'] = ps
        save(data)
    
    elif action == "del_p":
        n = sys.argv[3]
        ps = data.get('custom_providers', [])
        if isinstance(ps, list):
            data['custom_providers'] = [p for p in ps if p.get('name') != n and not p.get('name', '').startswith(n + "/")]
            save(data)

    elif action == "list_groups":
        ps = data.get('custom_providers', [])
        groups = []
        seen = set()
        for p in (ps if isinstance(ps, list) else []):
            name = p.get('name', '')
            g = name.split('/')[0] if '/' in name else name
            if g and g not in seen:
                seen.add(g)
                cnt = sum(1 for x in ps if x.get('name', '') == g or x.get('name', '').startswith(g + '/'))
                groups.append({"name": g, "count": cnt})
        print(json.dumps(groups))
    
    elif action == "switch":
        n, u, k, m = sys.argv[3:7]
        data['model'] = {"default": m, "provider": "custom", "base_url": u, "api_key": k}
        save(data)

except Exception as e:
    # 确保出错时返回合法的 JSON 避免 Bash 报错
    print(json.dumps([]))
    sys.exit(1)
EOF
}

install_gum() {
    if command -v gum >/dev/null 2>&1; then
        return 0
    fi
    echo -e "${YELLOW}正在安装 gum (交互式选择器)...${NC}"
    if command -v apt >/dev/null 2>&1; then
        mkdir -p /etc/apt/keyrings
        curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg 2>/dev/null
        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list > /dev/null
        apt update -qq && apt install -y -qq gum
    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
        cat > /etc/yum.repos.d/charm.repo <<'REPO'
[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key
REPO
        rpm --import https://repo.charm.sh/yum/gpg.key
        if command -v dnf >/dev/null 2>&1; then dnf install -y gum; else yum install -y gum; fi
    elif command -v zypper >/dev/null 2>&1; then
        zypper --non-interactive install gum
    fi
}

hermes_model_probe() {
    local target_model="$1"
    local ps_json="$2"
    local probe_timeout=15
    local provider_name request_model base_url api_key

    # 从 custom_providers 中查找对应条目
    provider_name="$target_model"
    local entry=$(echo "$ps_json" | jq -c --arg n "$provider_name" '.[] | select(.name == $n)' 2>/dev/null)
    if [ -z "$entry" ]; then
        HERMES_PROBE_STATUS="ERROR"
        HERMES_PROBE_MESSAGE="未找到模型配置"
        HERMES_PROBE_LATENCY="-"
        HERMES_PROBE_REPLY="-"
        return 1
    fi

    base_url=$(echo "$entry" | jq -r .base_url)
    api_key=$(echo "$entry" | jq -r .api_key)
    request_model=$(echo "$entry" | jq -r .model)
    base_url="${base_url%/}"

    local tmp_response
    tmp_response=$(mktemp)

    # 使用 Python 探测，精确计时
    local probe_result
    probe_result=$(python3 - "$base_url" "$api_key" "$request_model" "$tmp_response" "$probe_timeout" <<'PYEOF'
import sys, time, json
try:
    import urllib.request, urllib.error
except ImportError:
    print("1|0|0")
    sys.exit(0)

base_url, api_key, model, resp_path, timeout = sys.argv[1:6]
timeout = int(timeout)
url = base_url + "/chat/completions"
payload = json.dumps({"model": model, "messages": [{"role": "user", "content": "hi"}], "temperature": 0, "max_tokens": 16}).encode()
req = urllib.request.Request(url, data=payload, headers={
    "Content-Type": "application/json",
    "Authorization": f"Bearer {api_key}",
}, method="POST")

start = time.time()
body = b""
status = 0
exit_code = 0
try:
    with urllib.request.urlopen(req, timeout=timeout) as resp:
        status = getattr(resp, "status", 200)
        body = resp.read()
except urllib.error.HTTPError as e:
    status = getattr(e, "code", 0) or 0
    body = e.read()
    exit_code = 22
except Exception as e:
    body = str(e).encode("utf-8", errors="replace")
    exit_code = 1

elapsed = int((time.time() - start) * 1000)
with open(resp_path, "wb") as f:
    f.write(body)
print(f"{exit_code}|{status}|{elapsed}")
PYEOF
)

    local p_exit p_http p_latency
    p_exit=${probe_result%%|*}
    p_http=${probe_result#*|}
    p_http=${p_http%%|*}
    p_latency=${probe_result##*|}

    # 提取回复摘要
    local reply_preview
    reply_preview=$(python3 - "$tmp_response" <<'PYEOF'
import json, sys
from pathlib import Path
raw = Path(sys.argv[1]).read_text(encoding="utf-8", errors="replace").strip()
reply = ""
if raw:
    try:
        data = json.loads(raw)
        if isinstance(data, dict):
            choices = data.get("choices") or []
            if choices and isinstance(choices[0], dict):
                msg = choices[0].get("message") or {}
                if isinstance(msg, dict):
                    reply = msg.get("content") or ""
            if not reply:
                for key in ("error", "message", "detail"):
                    v = data.get(key)
                    if isinstance(v, str) and v.strip():
                        reply = v.strip(); break
                    if isinstance(v, dict):
                        n = v.get("message")
                        if isinstance(n, str) and n.strip():
                            reply = n.strip(); break
    except:
        reply = raw
reply = " ".join(str(reply).split())[:120]
print(reply if reply else "(空返回)")
PYEOF
)
    rm -f "$tmp_response"

    if [ "$p_exit" = "0" ] && [ "$p_http" -ge 200 ] 2>/dev/null && [ "$p_http" -lt 300 ] 2>/dev/null; then
        HERMES_PROBE_STATUS="OK"
        HERMES_PROBE_MESSAGE="HTTP ${p_http}"
        HERMES_PROBE_LATENCY="${p_latency}ms"
        HERMES_PROBE_REPLY="$reply_preview"
        return 0
    else
        HERMES_PROBE_STATUS="FAIL"
        HERMES_PROBE_MESSAGE="HTTP ${p_http:-0} / exit ${p_exit:-1}"
        HERMES_PROBE_LATENCY="${p_latency:-?}ms"
        HERMES_PROBE_REPLY="$reply_preview"
        return 1
    fi
}

hermes_probe_status_line() {
    local status_text="$1"
    local color_ok='\033[32m' color_fail='\033[31m' reset='\033[0m'
    if [ "$status_text" = "可用" ]; then
        printf "%b最小检测结果：%s%b\n" "$color_ok" "$status_text" "$reset"
    else
        printf "%b最小检测结果：%s%b\n" "$color_fail" "$status_text" "$reset"
    fi
}

api_management_submenu() {
    while true; do
        clear
        info=$(config_tool get_info)
        echo -e "${BLUE}=======================================${NC}"
        echo -e "      ${PURPLE}API & 模型管理 (OpenClaw 风格)${NC}"
        echo -e "${BLUE}=======================================${NC}"
        echo -e "${CYAN}当前激活模型:${NC} ${GREEN}$(echo $info | jq -r .m)${NC}"
        echo -e "---------------------------------------"
        echo -e "${CYAN}已配置 API 列表:${NC}"
        ps_list=$(config_tool list_p)
        if [ "$(echo "$ps_list" | jq '. | length')" -eq 0 ]; then
            echo -e "  ${YELLOW}(暂无配置)${NC}"
        else
            echo "$ps_list" | jq -r '.[] | "  ● [\(.name)] \(.model) | \(.base_url)"'
        fi
        echo -e "---------------------------------------"
        echo -e "1. ${YELLOW}切换模型 (带测速)${NC}"
        echo -e "2. 添加 API 供应商 (自动同步)${NC}"
        echo -e "3. 删除 API 供应商"
        echo -e "0. 返回主菜单"
        echo -e "---------------------------------------"
        read -p "选择序号: " sub_choice
        case "$sub_choice" in
            1)
                local orange="#FF8C00"
                local ps_json models_list model_count default_model selected_model confirm_switch

                ps_json=$(config_tool list_p)
                model_count=$(echo "$ps_json" | jq '. | length')

                if [ "$model_count" -eq 0 ] 2>/dev/null || [ -z "$model_count" ]; then
                    echo -e "${RED}无 API 配置! 请先添加供应商。${NC}"
                    sleep 1
                    continue
                fi

                # 构建带编号的模型列表
                models_list=$(echo "$ps_json" | jq -r '.[].name' | awk '{print "(" NR ") " $0}')
                default_model=$(config_tool get_info | jq -r .m)

                while true; do
                    clear
                    install_gum

                    # 若 gum 不可用，降级为手动输入
                    if ! command -v gum >/dev/null 2>&1; then
                        echo "--- 模型管理 ---"
                        echo "当前可用模型："
                        echo "$models_list"
                        echo "当前默认：${default_model}"
                        echo "----------------"
                        read -e -p "请输入模型编号或名称 (输入 0 退出): " selected_model

                        if [ "$selected_model" = "0" ]; then
                            break
                        fi
                        if [ -z "$selected_model" ]; then
                            echo "错误：不能为空，请重试。"
                            sleep 1
                            continue
                        fi
                        # 如果输入的是纯数字，从列表中取名称
                        if [[ "$selected_model" =~ ^[0-9]+$ ]]; then
                            selected_model=$(echo "$ps_json" | jq -r --argjson i "$((selected_model-1))" '.[$i].name // empty')
                            if [ -z "$selected_model" ]; then
                                echo "序号无效，请重试。"
                                sleep 1
                                continue
                            fi
                        fi
                    else
                        # gum 模式 — 完全复刻 openclaw 风格
                        gum style --foreground "$orange" --bold "模型管理"
                        gum style --foreground "$orange" "可用模型：${model_count}"
                        gum style --foreground "$orange" "当前默认：${default_model}"
                        echo ""
                        gum style --faint "↑↓ 选择 / 输入搜索 / Enter 测试 / Esc 退出"
                        echo ""

                        selected_model=$(echo "$models_list" | gum filter \
                            --placeholder "搜索模型（如 cli-api/gpt-4o）" \
                            --prompt "选择模型 > " \
                            --indicator "➜ " \
                            --prompt.foreground "$orange" \
                            --indicator.foreground "$orange" \
                            --cursor-text.foreground "$orange" \
                            --match.foreground "$orange" \
                            --header "" \
                            --height 35)

                        if [ -z "$selected_model" ] || echo "$selected_model" | head -n 1 | grep -iqE '^(error|usage|gum:)'; then
                            echo "操作已取消，正在退出..."
                            break
                        fi
                    fi

                    # 去掉编号前缀 "(N) "
                    selected_model=$(echo "$selected_model" | sed -E 's/^\([0-9]+\)[[:space:]]+//')

                    echo ""
                    echo "正在检测模型: $selected_model"
                    if hermes_model_probe "$selected_model" "$ps_json"; then
                        hermes_probe_status_line "可用"
                    else
                        hermes_probe_status_line "不可用"
                    fi
                    echo "状态：$HERMES_PROBE_MESSAGE"
                    echo "延迟：$HERMES_PROBE_LATENCY"
                    echo "摘要：$HERMES_PROBE_REPLY"
                    echo ""

                    printf "是否切换到该模型？[y/N，Esc 返回列表]: "
                    IFS= read -rsn1 confirm_switch
                    echo ""
                    if [ "$confirm_switch" = $'\x1b' ]; then
                        confirm_switch="no"
                    else
                        case "$confirm_switch" in
                            [yY])
                                IFS= read -rsn1 -t 5 _enter_key
                                confirm_switch="yes"
                                ;;
                            *) confirm_switch="no" ;;
                        esac
                    fi

                    if [ "$confirm_switch" != "yes" ]; then
                        echo "已返回模型选择列表。"
                        sleep 1
                        continue
                    fi

                    # 执行切换
                    local entry_data
                    entry_data=$(echo "$ps_json" | jq -c --arg n "$selected_model" '.[] | select(.name == $n)')
                    local sw_u sw_k sw_m
                    sw_u=$(echo "$entry_data" | jq -r .base_url)
                    sw_k=$(echo "$entry_data" | jq -r .api_key)
                    sw_m=$(echo "$entry_data" | jq -r .model)

                    echo "正在切换模型为: $selected_model ..."
                    config_tool switch "$selected_model" "$sw_u" "$sw_k" "$sw_m"

                    # 重启 gateway
                    echo -e "${YELLOW}正在重启 Gateway...${NC}"
                    hermes gateway stop >/dev/null 2>&1
                    hermes gateway start >/dev/null 2>&1
                    echo -e "${GREEN}✅ 模型已切换为: $sw_m${NC}"
                    sleep 2
                    break
                done
                ;;
            2)
                echo -e "${CYAN}--- 添加新 API 供应商 ---${NC}"
                read -p "请输入供应商名称 (如: DeepSeek): " n
                [ -z "$n" ] && continue
                read -p "请输入 Base URL (如: https://api.deepseek.com/v1): " u
                [ -z "$u" ] && continue
                u="${u%/}"
                echo -ne "${YELLOW}请输入 API Key (输入隐藏): ${NC}"
                read -s k
                echo ""
                [ -z "$k" ] && continue
                
                echo -e "${YELLOW}🔍 正在获取完整模型列表...${NC}"
                m_json=$(curl -s -m 10 -H "Authorization: Bearer $k" "$u/models")
                # 提取所有 ID
                m_list_str=$(echo "$m_json" | jq -r '.data[].id' 2>/dev/null | sort)
                
                if [ -n "$m_list_str" ]; then
                    # 转换为数组
                    m_array=()
                    while read -r line; do m_array+=("$line"); done <<< "$m_list_str"
                    m_count=${#m_array[@]}
                    
                    echo -e "${GREEN}✅ 发现 $m_count 个模型。请选择一个作为当前默认：${NC}"
                    PS3="请输入序号: "
                    select m_default in "${m_array[@]}"; do
                        [ -n "$m_default" ] && break
                    done
                    
                    echo -e "---------------------------------------"
                    read -p "是否同时添加该供应商的所有 $m_count 个模型？(y/N): " bulk_confirm
                    if [[ "$bulk_confirm" =~ ^[Yy]$ ]]; then
                        # 转换数组为 JSON
                        m_json_list=$(echo "$m_list_str" | jq -R . | jq -s -c .)
                        config_tool bulk_add "$n" "$u" "$k" "$m_json_list"
                        config_tool switch "$n/$m_default" "$u" "$k" "$m_default"
                        echo -e "${GREEN}✅ 已全量导入 $m_count 个模型。${NC}"
                    else
                        config_tool add_p "$n" "$u" "$k" "$m_default"
                        echo -e "${GREEN}✅ 已添加单个模型: $m_default${NC}"
                    fi
                else
                    echo -e "${RED}❌ 无法获取列表。${NC}"
                    read -p "请手动输入模型 ID: " m_manual
                    [ -n "$m_manual" ] && config_tool add_p "$n" "$u" "$k" "$m_manual"
                fi
                sleep 2
                ;;
            3)
                echo -e "${CYAN}已配置的供应商分组:${NC}"
                groups_json=$(config_tool list_groups)
                g_count=$(echo "$groups_json" | jq '. | length')
                if [ "$g_count" -eq 0 ]; then
                    echo -e "  ${YELLOW}(暂无配置)${NC}"
                    sleep 1
                    continue
                fi
                # 列出供应商分组
                g_names=()
                while read -r row; do
                    g_name=$(echo "$row" | jq -r .name)
                    g_cnt=$(echo "$row" | jq -r .count)
                    g_names+=("$g_name")
                    echo -e "  ${GREEN}${#g_names[@]}.${NC} $g_name (${g_cnt} 个模型)"
                done < <(echo "$groups_json" | jq -c '.[]')
                echo -e "  ${GREEN}0.${NC} 取消"
                read -p "选择要删除的供应商序号: " d_idx
                if [ "$d_idx" == "0" ] || [ -z "$d_idx" ]; then continue; fi
                d_name="${g_names[$((d_idx-1))]}"
                if [ -n "$d_name" ]; then
                    read -p "确认删除 [$d_name] 及其所有模型? (y/N): " del_confirm
                    if [[ "$del_confirm" =~ ^[Yy]$ ]]; then
                        config_tool del_p "$d_name"
                        echo -e "${RED}🗑️ 已删除 $d_name${NC}"
                        sleep 1
                    fi
                fi
                ;;
            0) break ;;
        esac
    done
}
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


refresh_hermes_path() {
    if ! command -v hermes >/dev/null 2>&1; then
        if [ -d "$HOME/.hermes/hermes-agent/venv/bin" ]; then
            export PATH="$HOME/.hermes/hermes-agent/venv/bin:$PATH"
        fi
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
            refresh_hermes_path
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
                api_management_submenu
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
