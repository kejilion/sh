#!/bin/bash

# 定义颜色
green="\e[1;32m"
yellow="\e[1;33m"
re="\033[0m"

# 设置内存使用率阈值，单位为百分比
threshold_memory=99

#获取总内存和已使用内存计算使用率
total_memory=$(free -m | awk '/^Mem:/{print $2}')
used_memory=$(free -m | awk '/^Mem:/{print $3}')
memory_usage=$(echo "scale=2; $used_memory / $total_memory * 100" | bc)

echo -e "${green}总内存: ${total_memory}MB${re}"
echo -e "${yellow}已使用内存: ${used_memory}MB${re}"
echo -e "${yellow}当前内存使用率: ${memory_usage}%${re}"

# 检查内存使用率是否超过阈值
if (( $(echo "$memory_usage >= $threshold_memory" | bc -l) )); then
    echo "内存使用率已达到 ${threshold_memory}%, 执行重启操作..."
    shutdown -h now
else
    echo -e "${green}内存使用率未达到 ${threshold_memory}%, 继续运行...${re}"
fi
