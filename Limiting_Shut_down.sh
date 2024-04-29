#!/bin/bash

# 获取总的接收和发送流量
output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
    NR > 2 { rx_total += $2; tx_total += $10 }
    END {
        printf("%.0f Bytes %.0f Bytes", rx_total, tx_total);
    }' /proc/net/dev)

# 获取接收和发送的流量数据
rx=$(echo "$output" | awk '{print $1}')
tx=$(echo "$output" | awk '{print $3}')

# 显示当前流量使用情况
echo "当前接收流量: $rx"
echo "当前发送流量: $tx"

threshold_gb=110

# 将GB转换为字节
threshold=$((threshold_gb * 1024 * 1024 * 1024))

# 检查是否达到流量阈值
if (( $rx > $threshold || $tx > $threshold )); then
    echo "流量达到${threshold}，正在关闭服务器..."
    # 在此处执行关闭服务器的命令，例如：
    shutdown -h now
    # 或者
    # systemctl poweroff
else
    echo "当前流量未达到${threshold}，继续监视..."
fi
