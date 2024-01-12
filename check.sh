# 使用此脚本前先执行 apt install -y net-tools bc 安装依赖
# */10 * * * * /bin/bash /root/check_trafic.sh >> /root/check.log 2>&1    cron任务，每10分钟运行检查一次
#!/bin/bash

# 定义颜色
green="\e[1;32m"
yellow="\e[1;33m"
re="\033[0m"

# 设置流量阈值，单位为 GB
threshold_traffic=5000

# 设置 CPU 使用率阈值，单位为百分比
threshold_cpu=99

# 设置内存使用率阈值，单位为百分比
threshold_memory=99

# 获取 lxdbr0和eth0分支流量
rx_bytes=$(/sbin/ifconfig enp1s0 | grep "RX packets" | awk '{print $5}')
tx_bytes=$(/sbin/ifconfig enp1s0 | grep "TX packets" | awk '{print $5}')

# 将字节转换为 GB
rx_gb=$(echo "scale=2; $rx_bytes / (1024^3)" | bc)
tx_gb=$(echo "scale=2; $tx_bytes / (1024^3)" | bc)

echo -e "${yellow}RX 流量: $(echo "$rx_gb" | bc)GB${re}"
echo -e "${yellow}TX 流量: $(echo "$tx_gb" | bc)GB${re}"

# 计算总流量
total_gb=$(echo "$rx_gb + $tx_gb" | bc)

echo -e "${yellow}总共使用流量: ${total_gb}GB${re}"

# 检查流量是否超过阈值
if (( $(echo "$total_gb >= $threshold_traffic" | bc -l) )); then
    echo -e "${yellow}流量已超过阈值，执行关机操作...${re}"
    shutdown -h now
else
    echo -e "${green}流量未超过阈值，继续运行...${re}"
fi

total_memory=$(free -m | awk '/^Mem:/{print $2}')
used_memory=$(free -m | awk '/^Mem:/{print $3}')
memory_usage=$(echo "scale=2; $used_memory / $total_memory * 100" | bc)

echo -e "${yellow}总内存: ${total_memory}MB${re}"
echo -e "${yellow}已使用内存: ${used_memory}MB${re}"
echo -e "${yellow}当前内存使用率: ${memory_usage}%${re}"

# 检查内存使用率是否超过阈值
if (( $(echo "$memory_usage >= $threshold_memory" | bc -l) )); then
    echo -e "${yellow}内存使用率已达到${threshold_memory}%, 执行重启操作...${re}"
    shutdown -h now
else
    echo -e "${green}内存使用率未达到${threshold_memory}%, 继续运行...${re}"
fi

# 获取当前 CPU 使用率
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F. '{print $1}')

echo -e "${yellow}当前CPU使用率: ${cpu_usage}%${re}"

# 检查 CPU 使用率是否超过阈值
if ((cpu_usage >= threshold_cpu)); then
    echo -e "${yellow}CPU使用率已达到${threshold_cpu}%, 执行关机操作...${re}"
    shutdown -h now
else
    echo -e "${green}CPU使用率未达到${threshold_cpu}%, 继续运行...${re}"
fi