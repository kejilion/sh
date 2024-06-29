#!/bin/bash

# 你需要配置Telegram Bot Token和Chat ID
TELEGRAM_BOT_TOKEN="输入TG的机器人API"
CHAT_ID="输入TG的接收通知的账号ID"


# 你可以修改监控阈值设置
CPU_THRESHOLD=70
MEMORY_THRESHOLD=70
DISK_THRESHOLD=70
NETWORK_THRESHOLD_GB=1000



# 获取设备信息的变量
country=$(curl -s ipinfo.io/$public_ip/country)
isp_info=$(curl -s ipinfo.io/org | sed -e 's/\"//g' | awk -F' ' '{print $2}')

ipv4_address=$(curl -s ipv4.ip.sb)
masked_ip=$(echo $ipv4_address | awk -F'.' '{print "*."$3"."$4}')

# 发送Telegram通知的函数
send_tg_notification() {
    local MESSAGE=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE"
}


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

# 获取总的接收流量（字节数）
get_rx_bytes() {
    awk 'BEGIN { rx_total = 0 }
        NR > 2 { rx_total += $2 }
        END {
            printf("%.2f", rx_total / (1024 * 1024 * 1024));
        }' /proc/net/dev
}

# 获取总的发送流量（字节数）
get_tx_bytes() {
    awk 'BEGIN { tx_total = 0 }
        NR > 2 { tx_total += $10 }
        END {
            printf("%.2f", tx_total / (1024 * 1024 * 1024));
        }' /proc/net/dev
}

# 检查并发送通知
check_and_notify() {
    local USAGE=$1
    local TYPE=$2
    local THRESHOLD=$3
    local CURRENT_VALUE=$4

    if (( $(echo "$USAGE > $THRESHOLD" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的 $TYPE 使用率已达到 $USAGE%，超过阈值 $THRESHOLD%。"
    fi
}

# 主循环
while true; do
    CPU_USAGE=$(get_cpu_usage)
    MEMORY_USAGE=$(get_memory_usage)
    DISK_USAGE=$(get_disk_usage)
    RX_GB=$(get_rx_bytes)
    TX_GB=$(get_tx_bytes)

    check_and_notify $CPU_USAGE "CPU" $CPU_THRESHOLD $CPU_USAGE
    check_and_notify $MEMORY_USAGE "内存" $MEMORY_THRESHOLD $MEMORY_USAGE
    check_and_notify $DISK_USAGE "硬盘" $DISK_THRESHOLD $DISK_USAGE

    # 检查入站流量是否超过阈值
    if (( $(echo "$RX_GB > $NETWORK_THRESHOLD_GB" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的入站流量已达到 ${RX_GB}GB，超过阈值 ${NETWORK_THRESHOLD_GB}GB。"
    fi

    # 检查出站流量是否超过阈值
    if (( $(echo "$TX_GB > $NETWORK_THRESHOLD_GB" | bc -l) )); then
        send_tg_notification "警告: ${isp_info}-${country}-${masked_ip} 的出站流量已达到 ${TX_GB}GB，超过阈值 ${NETWORK_THRESHOLD_GB}GB。"
    fi

    # 休眠5分钟
    sleep 300
done
