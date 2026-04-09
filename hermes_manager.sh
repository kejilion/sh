     1|<<<<<<< HEAD
     2|#!/bin/bash
     3|# Hermes Agent 终端管理脚本 (轻量版)
     4|# 设计哲学：极简、直观、调用原生功能
     5|
     6|# 颜色定义
     7|RED='\033[0;31m'
     8|GREEN='\033[0;32m'
     9|YELLOW='\033[1;33m'
    10|CYAN='\033[0;36m'
    11|NC='\033[0m'
    12|
    13|# 确保 hermes 命令可用 (处理环境变量未加载的情况)
    14|if ! command -v hermes >/dev/null 2>&1; then
    15|    if [ -d "$HOME/.hermes/hermes-agent/venv/bin" ]; then
    16|        export PATH="$HOME/.hermes/hermes-agent/venv/bin:$PATH"
    17|    fi
    18|fi
    19|
    20|# 检查是否安装
    21|check_installed() {
    22|    if command -v hermes >/dev/null 2>&1; then return 0; else return 1; fi
    23|}
    24|
    25|# 获取版本号
    26|get_version() {
    27|    if check_installed; then
    28|        hermes --version | head -n 1
    29|    fi
    30|}
    31|
    32|# 获取网关状态
    33|get_gateway_status() {
    34|    if check_installed; then
    35|        # 匹配后台 gateway 进程或 systemd 服务
    36|        if pgrep -f "hermes_cli.main gateway" > /dev/null || pgrep -f "hermes gateway run" > /dev/null || pgrep -f "hermes-gateway" > /dev/null; then
    37|            echo -e "${GREEN}运行中${NC}"
    38|        else
    39|            echo -e "${RED}已停止${NC}"
    40|        fi
    41|    else
    42|        echo -e "${RED}未安装${NC}"
    43|    fi
    44|}
    45|
    46|# 主菜单UI
    47|show_menu() {
    48|    clear
    49|    echo -e "${CYAN}=================================================${NC}"
    50|    echo -e "${YELLOW}           Hermes Agent 终端管理工具             ${NC}"
    51|    echo -e "${CYAN}=================================================${NC}"
    52|    echo -e " 运行状态 : $(get_gateway_status)"
    53|    echo -e " 当前版本 : $(get_version)"
    54|    echo -e "${CYAN}-------------------------------------------------${NC}"
    55|    echo -e "${GREEN}1.${NC} 安装 Hermes Agent"
    56|    echo -e "${GREEN}2.${NC} 启动 Gateway (消息网关/后台服务)"
    57|    echo -e "${GREEN}3.${NC} 停止 Gateway"
    58|    echo -e "${GREEN}4.${NC} API/模型管理 (提供商与模型切换)"
    59|    echo -e "${GREEN}5.${NC} 启动终端对话UI (Interactive Chat)"
    60|    echo -e "${GREEN}6.${NC} 运行初始化配置向导 (Setup Wizard)"
    61|    echo -e "${GREEN}7.${NC} 检查并更新 Hermes"
    62|    echo -e "${GREEN}8.${NC} 卸载 Hermes"
    63|    echo -e "${GREEN}0.${NC} 退出"
    64|    echo -e "${CYAN}=================================================${NC}"
    65|    if ! read -p " 请输入数字 [0-8]: " choice; then
    66|        echo -e "\n${GREEN}退出脚本。${NC}"
    67|        exit 0
    68|    fi
    69|    echo ""
    70|    
    71|    case $choice in
    72|        1)
    73|            echo -e "${YELLOW}开始安装 Hermes Agent...${NC}"
    74|            curl -fsSL https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.sh | bash
    75|            source ~/.bashrc
    76|            hermes gateway install
    77|            hermes gateway start
    78|            
    79|            ;;
    80|        2)
    81|            if check_installed; then
    82|                echo -e "${YELLOW}正在启动 Gateway...${NC}"
    83|                hermes gateway stop
    84|                hermes gateway start
    85|            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
    86|            ;;
    87|        3)
    88|            if check_installed; then
    89|                echo -e "${YELLOW}正在停止 Gateway...${NC}"
    90|                hermes gateway stop
    91|            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
    92|            ;;
    93|        4)
    94|            if check_installed; then
    95|                echo -e "${YELLOW}进入模型配置向导...${NC}"
    96|                hermes model
    97|            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
    98|            ;;
    99|        5)
   100|            if check_installed; then
   101|                echo -e "${YELLOW}即将进入交互式终端，输入 /exit 即可退出返回。${NC}"
   102|                sleep 1
   103|                hermes
   104|            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
   105|            ;;
   106|        6)
   107|            if check_installed; then
   108|                echo -e "${YELLOW}正在启动初始化配置向导...${NC}"
   109|                hermes setup
   110|            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
   111|            ;;
   112|        7)
   113|            if check_installed; then
   114|                echo -e "${YELLOW}正在检查更新...${NC}"
   115|                hermes update
   116|            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
   117|            ;;
   118|        8)
   119|            if check_installed; then
   120|                read -p "确定要卸载 Hermes 吗？所有数据将被清除。(y/N): " confirm
   121|                if [[ "$confirm" =~ ^[Yy]$ ]]; then
   122|                    hermes uninstall
   123|                else echo "已取消。"; fi
   124|            else echo -e "${RED}请先安装 Hermes。${NC}"; fi
   125|            ;;
   126|        0)
   127|            echo -e "${GREEN}感谢使用，再见！${NC}"
   128|            exit 0
   129|            ;;
   130|        *)
   131|            echo -e "${RED}输入错误，请重新选择。${NC}"
   132|            ;;
   133|    esac
   134|    echo ""
   135|    read -p "按回车键返回主菜单..."
   136|}
   137|
   138|# 主循环
   139|while true; do
   140|    show_menu
   141|done
   142|=======
   143|     1|#!/bin/bash
   144|     2|# Hermes Agent 终端管理脚本 v2.1
   145|     3|# 借鉴 OpenClaw 管理模块，适配 Hermes Agent 配置体系
   146|     4|# 设计哲学：极简、直观、Python yaml 安全读写（不依赖 yq）
   147|     5|
   148|     6|# 颜色定义
   149|     7|RED='\033[0;31m'
   150|     8|GREEN='\033[0;32m'
   151|     9|YELLOW='\033[1;33m'
   152|    10|CYAN='\033[0;36m'
   153|    11|PURPLE='\033[0;35m'
   154|    12|DIM='\033[2m'
   155|    13|NC='\033[0m'
   156|    14|
   157|    15|# 确保 hermes 命令可用 (处理环境变量未加载的情况)
   158|    16|if ! command -v hermes >/dev/null 2>&1; then
   159|    17|    if [ -d "$HOME/.hermes/hermes-agent/venv/bin" ]; then
   160|    18|        export PATH="$HOME/.hermes/hermes-agent/venv/bin:$PATH"
   161|    19|    fi
   162|    20|fi
   163|    21|
   164|    22|# 配置文件路径
   165|    23|HERMES_CONFIG="${HOME}/.hermes/config.yaml"
   166|    24|
   167|    25|# ============================================================
   168|    26|# 通用工具函数
   169|    27|# ============================================================
   170|    28|
   171|    29|check_installed() {
   172|    30|    if command -v hermes >/dev/null 2>&1; then return 0; else return 1; fi
   173|    31|}
   174|    32|
   175|    33|get_version() {
   176|    34|    if check_installed; then
   177|    35|        hermes --version 2>/dev/null | head -n 1
   178|    36|    fi
   179|    37|}
   180|    38|
   181|    39|get_gateway_status() {
   182|    40|    if check_installed; then
   183|    41|        if pgrep -f "hermes_cli.main gateway" > /dev/null || pgrep -f "hermes gateway run" > /dev/null || pgrep -f "hermes-gateway" > /dev/null; then
   184|    42|            echo -e "${GREEN}运行中${NC}"
   185|    43|        else
   186|    44|            echo -e "${RED}已停止${NC}"
   187|    45|        fi
   188|    46|    else
   189|    47|        echo -e "${RED}未安装${NC}"
   190|    48|    fi
   191|    49|}
   192|    50|
   193|    51|# 获取当前模型
   194|    52|get_current_model() {
   195|    53|    if [ ! -f "$HERMES_CONFIG" ]; then echo -e "${DIM}(未知)${NC}"; return; fi
   196|    54|    python3 - "$HERMES_CONFIG" <<'PY'
   197|    55|import sys, yaml
   198|    56|with open(sys.argv[1], 'r') as f:
   199|    57|    cfg = yaml.safe_load(f)
   200|    58|m = cfg.get('model', {})
   201|    59|default = m.get('default', '') if isinstance(m, dict) else ''
   202|    60|if default:
   203|    61|    print(f'\033[0;32m{default}\033[0m')
   204|    62|else:
   205|    63|    print('\033[2m(未设置)\033[0m')
   206|    64|PY
   207|    65|}
   208|    66|
   209|    67|# 检查 python3 + yaml 可用
   210|    68|ensure_python_yaml() {
   211|    69|    if ! python3 -c "import yaml" 2>/dev/null; then
   212|    70|        pip3 install pyyaml -q 2>/dev/null || pip install pyyaml -q 2>/dev/null
   213|    71|    fi
   214|    72|}
   215|    73|
   216|    74|# 安装 jq（若缺失）
   217|    75|ensure_jq() {
   218|    76|    if ! command -v jq >/dev/null 2>&1; then
   219|    77|        echo -e "${YELLOW}正在安装 jq...${NC}"
   220|    78|        if command -v apt >/dev/null 2>&1; then
   221|    79|            apt update -qq && apt install -y -qq jq
   222|    80|        elif command -v dnf >/dev/null 2>&1; then
   223|    81|            dnf install -y jq
   224|    82|        elif command -v yum >/dev/null 2>&1; then
   225|    83|            yum install -y jq
   226|    84|        fi
   227|    85|    fi
   228|    86|}
   229|    87|
   230|    88|# 用 Python 读取 custom_providers，输出 JSON 数组
   231|    89|read_providers_json() {
   232|    90|    ensure_python_yaml
   233|    91|    python3 - "$HERMES_CONFIG" <<'PY'
   234|    92|import sys, json, yaml
   235|    93|with open(sys.argv[1], 'r') as f:
   236|    94|    cfg = yaml.safe_load(f)
   237|    95|providers = cfg.get('custom_providers', [])
   238|    96|json.dump(providers, sys.stdout, ensure_ascii=False)
   239|    97|PY
   240|    98|}
   241|    99|
   242|   100|# 重启 Gateway
   243|   101|restart_gateway() {
   244|   102|    echo -e "${YELLOW}正在重启 Gateway...${NC}"
   245|   103|    hermes gateway stop 2>/dev/null
   246|   104|    sleep 1
   247|   105|    systemctl --user start hermes-gateway 2>/dev/null
   248|   106|    hermes gateway start 2>/dev/null
   249|   107|    echo -e "${GREEN}Gateway 已重启${NC}"
   250|   108|}
   251|   109|
   252|   110|# ============================================================
   253|   111|# API 管理子菜单
   254|   112|# ============================================================
   255|   113|
   256|   114|hermes_api_list() {
   257|   115|    echo ""
   258|   116|    echo -e "${CYAN}--- 已配置 API 列表 ---${NC}"
   259|   117|
   260|   118|    if [ ! -f "$HERMES_CONFIG" ]; then
   261|   119|        echo -e "${RED}未找到配置文件: $HERMES_CONFIG${NC}"
   262|   120|        return 1
   263|   121|    fi
   264|   122|
   265|   123|    python3 - "$HERMES_CONFIG" <<'PY'
   266|   124|import sys, yaml, json, time, urllib.request
   267|   125|
   268|   126|GREEN = '\033[0;32m'
   269|   127|YELLOW = '\033[1;33m'
   270|   128|RED = '\033[0;31m'
   271|   129|DIM = '\033[2m'
   272|   130|NC = '\033[0m'
   273|   131|
   274|   132|with open(sys.argv[1], 'r') as f:
   275|   133|    cfg = yaml.safe_load(f)
   276|   134|
   277|   135|providers = cfg.get('custom_providers', [])
   278|   136|if not providers:
   279|   137|    print(f'{DIM}当前未配置任何 API provider。{NC}')
   280|   138|    sys.exit(0)
   281|   139|
   282|   140|for idx, p in enumerate(providers, start=1):
   283|   141|    name = p.get('name', '-')
   284|   142|    base_url = p.get('base_url', '-')
   285|   143|    model = p.get('model', '-')
   286|   144|    api_key = p.get('api_key', '')
   287|   145|    masked_key = f"{api_key[:8]}****" if len(str(api_key)) > 8 else "****"
   288|   146|
   289|   147|    # Ping 延迟
   290|   148|    latency_raw = "未检测"
   291|   149|    latency_level = "unchecked"
   292|   150|    if base_url and base_url != '-' and api_key:
   293|   151|        try:
   294|   152|            url = base_url.rstrip('/') + '/models'
   295|   153|            req = urllib.request.Request(url, headers={
   296|   154|                'Authorization': f'Bearer {api_key}',
   297|   155|                'User-Agent': 'Hermes-Manager/1.0',
   298|   156|            })
   299|   157|            start = time.perf_counter()
   300|   158|            with urllib.request.urlopen(req, timeout=4) as resp:
   301|   159|                resp.read(2048)
   302|   160|            ms = int((time.perf_counter() - start) * 1000)
   303|   161|            latency_raw = f"{ms}ms"
   304|   162|            latency_level = 'low' if ms <= 800 else ('medium' if ms <= 2000 else 'high')
   305|   163|        except Exception:
   306|   164|            latency_raw = "不可用"
   307|   165|            latency_level = "unavailable"
   308|   166|
   309|   167|    if latency_level == 'low': latency_color = GREEN
   310|   168|    elif latency_level == 'medium': latency_color = YELLOW
   311|   169|    elif latency_level == 'unavailable': latency_color = RED
   312|   170|    else: latency_color = DIM
   313|   171|
   314|   172|    print(f"  [{idx}] {name}")
   315|   173|    print(f"      URL: {base_url}  Key: {masked_key}  模型: {YELLOW}{model}{NC}  延迟: {latency_color}{latency_raw}{NC}")
   316|   174|
   317|   175|PY
   318|   176|}
   319|   177|
   320|   178|# 添加 API Provider
   321|   179|hermes_api_add() {
   322|   180|    echo ""
   323|   181|    echo -e "${CYAN}=== 交互式添加 Hermes API Provider ===${NC}"
   324|   182|
   325|   183|    # Provider 名称
   326|   184|    read -erp "请输入 Provider 名称 (如: deepseek): " provider_name
   327|   185|    while [[ -z "$provider_name" ]]; do
   328|   186|        echo -e "${RED}Provider 名称不能为空${NC}"
   329|   187|        read -erp "请输入 Provider 名称: " provider_name
   330|   188|    done
   331|   189|
   332|   190|    # Base URL
   333|   191|    read -erp "请输入 Base URL (如: https://api.deepseek.com/v1): " base_url
   334|   192|    while [[ -z "$base_url" ]]; do
   335|   193|        echo -e "${RED}Base URL 不能为空${NC}"
   336|   194|        read -erp "请输入 Base URL: " base_url
   337|   195|    done
   338|   196|    base_url="${base_url%/}"
   339|   197|
   340|   198|    # API Key
   341|   199|    stty -echo
   342|   200|    read -r -p "请输入 API Key (输入不显示): " api_key
   343|   201|    stty echo
   344|   202|    echo
   345|   203|    while [[ -z "$api_key" ]]; do
   346|   204|        echo -e "${RED}API Key 不能为空${NC}"
   347|   205|    stty -echo
   348|   206|        read -r -p "请输入 API Key: " api_key
   349|   207|    stty echo
   350|   208|        echo
   351|   209|    done
   352|   210|
   353|   211|    # 获取模型列表
   354|   212|    echo -e "${YELLOW}正在获取可用模型列表...${NC}"
   355|   213|    models_json=$(curl -s -m 10 \
   356|   214|        -H "Authorization: Bearer *** \
   357|   215|        "${base_url}/models" 2>/dev/null)
   358|   216|
   359|   217|    available_models=""
   360|   218|    model_count=0
   361|   219|    model_list=()
   362|   220|    if [[ -n "$models_json" ]]; then
   363|   221|        ensure_jq
   364|   222|        available_models=$(echo "$models_json" | jq -r '.data[]?.id // empty' 2>/dev/null | sort)
   365|   223|        if [[ -n "$available_models" ]]; then
   366|   224|            model_count=$(echo "$available_models" | wc -l | tr -d ' ')
   367|   225|            echo -e "${GREEN}发现 ${model_count} 个可用模型：${NC}"
   368|   226|            echo "--------------------------------"
   369|   227|            i=1
   370|   228|            while read -r model; do
   371|   229|                echo "[$i] $model"
   372|   230|                model_list+=("$model")
   373|   231|                ((i++))
   374|   232|            done <<< "$available_models"
   375|   233|            echo "--------------------------------"
   376|   234|        fi
   377|   235|    fi
   378|   236|
   379|   237|    # 如果获取失败，手动输入
   380|   238|    if [[ $model_count -eq 0 ]]; then
   381|   239|        echo -e "${YELLOW}未能自动获取模型列表，请手动输入。${NC}"
   382|   240|        read -erp "请输入默认 Model ID: " default_model
   383|   241|        while [[ -z "$default_model" ]]; do
   384|   242|            echo -e "${RED}Model ID 不能为空${NC}"
   385|   243|            read -erp "请输入 Model ID: " default_model
   386|   244|        done
   387|   245|    else
   388|   246|        # 选择默认模型
   389|   247|        echo
   390|   248|        read -erp "请输入默认 Model ID (或序号，留空则使用第一个): " input_model
   391|   249|        if [[ -z "$input_model" ]]; then
   392|   250|            default_model=$(echo "$available_models" | head -1)
   393|   251|            echo -e "使用第一个模型: ${GREEN}${default_model}${NC}"
   394|   252|        elif [[ "$input_model" =~ ^[0-9]+$ ]] && [ "${#model_list[@]}" -gt 0 ] && [ "$input_model" -ge 1 ] && [ "$input_model" -le "${#model_list[@]}" ]; then
   395|   253|            default_model="${model_list[$((input_model-1))]}"
   396|   254|            echo -e "已选择模型: ${GREEN}${default_model}${NC}"
   397|   255|        else
   398|   256|            default_model="$input_model"
   399|   257|        fi
   400|   258|    fi
   401|   259|
   402|   260|    # 确认信息
   403|   261|    echo
   404|   262|    echo "====== 确认信息 ======"
   405|   263|    echo "Provider    : $provider_name"
   406|   264|    echo "Base URL    : $base_url"
   407|   265|    echo "API Key     : ${api_key:0:8}****"
   408|   266|    echo "默认模型    : $default_model"
   409|   267|    echo "======================"
   410|   268|
   411|   269|    # 写入配置
   412|   270|    echo -e "${YELLOW}正在写入配置...${NC}"
   413|   271|
   414|   272|    python3 - "$HERMES_CONFIG" "$provider_name" "$base_url" "$api_key" "$default_model" <<'PY'
   415|   273|import sys, yaml, shutil
   416|   274|
   417|   275|path = sys.argv[1]
   418|   276|name = sys.argv[2]
   419|   277|base_url = sys.argv[3]
   420|   278|api_key = sys.argv[4]
   421|   279|model = sys.argv[5]
   422|   280|
   423|   281|with open(path, 'r', encoding='utf-8') as f:
   424|   282|    cfg = yaml.safe_load(f)
   425|   283|
   426|   284|providers = cfg.get('custom_providers', [])
   427|   285|
   428|   286|# 检查是否已存在同名 provider
   429|   287|existing_idx = None
   430|   288|for i, p in enumerate(providers):
   431|   289|    if p.get('name') == name:
   432|   290|        existing_idx = i
   433|   291|        break
   434|   292|
   435|   293|new_provider = {
   436|   294|    'name': name,
   437|   295|    'base_url': base_url,
   438|   296|    'api_key': api_key,
   439|   297|    'model': model,
   440|   298|}
   441|   299|
   442|   300|if existing_idx is not None:
   443|   301|    providers[existing_idx] = new_provider
   444|   302|    print(f'已更新同名 provider: {name}')
   445|   303|else:
   446|   304|    providers.append(new_provider)
   447|   305|    print(f'已添加 provider: {name}')
   448|   306|
   449|   307|cfg['custom_providers'] = providers
   450|   308|
   451|   309|# 备份
   452|   310|shutil.copy2(path, path + '.bak')
   453|   311|
   454|   312|with open(path, 'w', encoding='utf-8') as f:
   455|   313|    yaml.dump(cfg, f, default_flow_style=False, allow_unicode=True, sort_keys=False)
   456|   314|
   457|   315|print('OK')
   458|   316|PY
   459|   317|
   460|   318|    if [ $? -eq 0 ]; then
   461|   319|        echo -e "${GREEN}已成功添加 provider: ${provider_name}${NC}"
   462|   320|
   463|   321|        # 询问是否切换为当前使用
   464|   322|        echo
   465|   323|        read -erp "是否立即切换到该 provider？(y/N): " switch_now
   466|   324|        if [[ "$switch_now" =~ ^[Yy]$ ]]; then
   467|   325|            hermes_switch_to_provider "$provider_name"
   468|   326|        fi
   469|   327|    else
   470|   328|        echo -e "${RED}配置写入失败${NC}"
   471|   329|    fi
   472|   330|}
   473|   331|
   474|   332|# 切换到指定 provider
   475|   333|hermes_switch_to_provider() {
   476|   334|    local target_name="$1"
   477|   335|
   478|   336|    if [ -z "$target_name" ]; then
   479|   337|        read -erp "请输入要切换的 Provider 名称: " target_name
   480|   338|    fi
   481|   339|
   482|   340|    python3 - "$HERMES_CONFIG" "$target_name" <<'PY'
   483|   341|import sys, yaml, shutil
   484|   342|
   485|   343|path = sys.argv[1]
   486|   344|target = sys.argv[2]
   487|   345|
   488|   346|with open(path, 'r', encoding='utf-8') as f:
   489|   347|    cfg = yaml.safe_load(f)
   490|   348|
   491|   349|providers = cfg.get('custom_providers', [])
   492|   350|target_p = None
   493|   351|for p in providers:
   494|   352|    if p.get('name') == target:
   495|   353|        target_p = p
   496|   354|        break
   497|   355|
   498|   356|if target_p is None:
   499|   357|    print(f'ERROR: 未找到 provider: {target}')
   500|   358|    sys.exit(1)
   501|