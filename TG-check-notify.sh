#!/bin/bash

# 你需要配置Telegram Bot Token和Chat ID
TELEGRAM_BOT_TOKEN="输入TG的机器人API"
CHAT_ID="输入TG的接收通知的账号ID"



# 获取设备信息的变量
country=$(curl -s ipinfo.io/$public_ip/country)
isp_info=$(curl -s ipinfo.io/org | sed -e 's/\"//g' | awk -F' ' '{print $3}')

ipv4_address=$(curl -s ipv4.ip.sb)
masked_ip=$(echo $ipv4_address | awk -F'.' '{print $1"."$2".*.*"}')


# 发送Telegram通知的函数
send_tg_notification() {
    local MESSAGE=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE"
}

# 监控阈值设置
CPU_THRESHOLD=70
MEMORY_THRESHOLD=70
DISK_THRESHOLD=70

# 获取CPU使用率
get_cpu_usage() {
    awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
        <(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat)
}

# 获取内存使用率
get_memory_usage() {
    free | awk '/Mem/ {printf("%.0f"), $3/$2 * 100}'
}

# 获取硬盘使用率
get_disk_usage() {
    df / | awk 'NR==2 {print $5}' | sed 's/%//'
}

# 检查并发送通知
check_and_notify() {
    local USAGE=$1
    local TYPE=$2
    local THRESHOLD=$3

    if [ "$USAGE" -gt "$THRESHOLD" ]; then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的 $TYPE 使用率已达到 $USAGE%，超过阈值 $THRESHOLD%。"
    fi
}

# 主循环
while true; do
    CPU_USAGE=$(get_cpu_usage)
    MEMORY_USAGE=$(get_memory_usage)
    DISK_USAGE=$(get_disk_usage)

    check_and_notify $CPU_USAGE "CPU" $CPU_THRESHOLD
    check_and_notify $MEMORY_USAGE "内存" $MEMORY_THRESHOLD
    check_and_notify $DISK_USAGE "硬盘" $DISK_THRESHOLD

    # 休眠5分钟
    sleep 300
done
