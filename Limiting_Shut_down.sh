#!/bin/bash

# 获取总的接收和发送流量
output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
    NR > 2 { rx_total += $2; tx_total += $10 }
    END {
        rx_units = "Bytes";
        tx_units = "Bytes";
        if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
        if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
        if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

        if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
        if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
        if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

        printf("%.2f %s %.2f %s", rx_total, rx_units, tx_total, tx_units);
    }' /proc/net/dev)

# 获取接收和发送的流量数据及其单位
rx=$(echo "$output" | awk '{print $1}')
rx_unit=$(echo "$output" | awk '{print $2}')
tx=$(echo "$output" | awk '{print $3}')
tx_unit=$(echo "$output" | awk '{print $4}')

# 显示当前流量使用情况
echo "当前接收流量: $rx $rx_unit"
echo "当前发送流量: $tx $tx_unit"

threshold_gb=110

# 将GB转换为字节
threshold=$((threshold_gb * 1024 * 1024 * 1024))

# 检查是否达到流量阈值
if (( $(echo "$rx * 1024 * 1024 * 1024 > $threshold" | bc -l) || $(echo "$tx * 1024 * 1024 * 1024 > $threshold" | bc -l) )); then
    echo "流量达到${threshold_gb}GB，正在关闭服务器..."
    # 在此处执行关闭服务器的命令，例如：
    shutdown -h now
    # 或者
    # systemctl poweroff
else
    echo "当前流量未达到${threshold_gb}GB，继续监视..."
fi
