#!/bin/bash

# 定义颜色
green="\e[1;32m"
yellow="\e[1;33m"
re="\033[0m"

# 设置默认CPU阈值为99，单位%
threshold_cpu=99

# 获取当前 CPU 使用率
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F. '{print $1}')

echo -e "${green}当前CPU使用率: ${cpu_usage}%${re}"

# 检查 CPU 使用率是否超过阈值
if ((cpu_usage >= threshold_cpu)); then
    echo -e "${yellow}CPU使用率已达到${threshold_cpu}%, 执行关机操作...${re}"
    shutdown -h now
else
    echo -e "${green}CPU使用率未达到${threshold_cpu}%, 继续运行...${re}"
fi