#!/bin/bash

# 获取总的接收流量（只统计公网网卡）
rx_output=$(awk 'BEGIN { rx_total = 0 }
    $1 ~ /^(eth|ens|enp|eno)[0-9]+/ { rx_total += $2 }
    END {
        printf("%.0f Bytes", rx_total);
    }' /proc/net/dev)

# 获取总的发送流量（只统计公网网卡）
tx_output=$(awk 'BEGIN { tx_total = 0 }
    $1 ~ /^(eth|ens|enp|eno)[0-9]+/ { tx_total += $10 }
    END {
        printf("%.0f Bytes", tx_total);
    }' /proc/net/dev)

# 获取接收流量数据
rx=$(echo "$rx_output" | awk '{print $1}')

# 获取发送流量数据
tx=$(echo "$tx_output" | awk '{print $1}')

# 显示当前流量使用情况
echo "当前接收流量: $rx Bytes"
echo "当前发送流量: $tx Bytes"

rx_threshold_gb=110
tx_threshold_gb=120

# 将GB转换为字节
rx_threshold=$((rx_threshold_gb * 1024 * 1024 * 1024))
tx_threshold=$((tx_threshold_gb * 1024 * 1024 * 1024))

# 检查是否达到接收流量阈值
if (( rx > rx_threshold )); then
    echo "接收流量达到${rx_threshold_gb}GB (${rx_threshold} Bytes)，正在关闭服务器..."
    shutdown -h now
else
    echo "当前接收流量未达到${rx_threshold_gb}GB (${rx_threshold} Bytes)，继续监视..."
fi

# 检查是否达到发送流量阈值
if (( tx > tx_threshold )); then
    echo "发送流量达到${tx_threshold_gb}GB (${tx_threshold} Bytes)，正在关闭服务器..."
    shutdown -h now
else
    echo "当前发送流量未达到${tx_threshold_gb}GB (${tx_threshold} Bytes)，继续监视..."
fi
