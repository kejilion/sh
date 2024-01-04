# 使用此脚本前先执行 apt install -y net-tools bc 安装依赖
# */10 * * * * /bin/bash /root/check_trafic.sh >> /root/check.log 2>&1    cron任务，每10分钟运行检查一次
#!/bin/bash

# 设置流量阈值，单位为 GB
threshold_traffic=5000

# 设置 CPU 使用率阈值，单位为百分比
threshold_cpu=99

# 设置内存使用率阈值，单位为百分比
threshold_memory=99

# 获取 lxdbr0和eth0分支流量
rx_bytes=$(/sbin/ifconfig enp1s0 | grep "RX packets" | awk '{print $5}')
tx_bytes=$(/sbin/ifconfig enp1s0 | grep "TX packets" | awk '{print $5}')
rx_bytes1=$(/sbin/ifconfig lxdbr0 | grep "RX packets" | awk '{print $5}')
tx_bytes1=$(/sbin/ifconfig lxdbr0 | grep "TX packets" | awk '{print $5}')

# 将字节转换为 GB
rx_gb=$(echo "scale=2; $rx_bytes / (1024^3)" | bc)
tx_gb=$(echo "scale=2; $tx_bytes / (1024^3)" | bc)
rx_gb1=$(echo "scale=2; $rx_bytes1 / (1024^3)" | bc)
tx_gb1=$(echo "scale=2; $tx_bytes1 / (1024^3)" | bc)

echo "RX 流量: $(echo "$rx_gb + $rx_gb1" | bc)GB"
echo "TX 流量: $(echo "$tx_gb + $tx_gb1" | bc)GB"

# 计算总流量
total_gb=$(echo "$rx_gb + $tx_gb + $rx_gb1 + $tx_gb1" | bc)

echo "总流量: ${total_gb}GB"

# 检查流量是否超过阈值
if (( $(echo "$total_gb >= $threshold_traffic" | bc -l) )); then
    echo "流量已超过阈值，执行关机操作..."
    shutdown -h now
else
    echo "流量未超过阈值，继续运行..."
fi

total_memory=$(free -m | awk '/^Mem:/{print $2}')
used_memory=$(free -m | awk '/^Mem:/{print $3}')
memory_usage=$(echo "scale=2; $used_memory / $total_memory * 100" | bc)

echo "总内存: ${total_memory}MB"
echo "已使用内存: ${used_memory}MB"
echo "当前内存使用率: ${memory_usage}%"

# 检查内存使用率是否超过阈值
if (( $(echo "$memory_usage >= $threshold_memory" | bc -l) )); then
    echo "内存使用率已达到 ${threshold_memory}%, 执行重启操作..."
    reboot
else
    echo "内存使用率未达到 ${threshold_memory}%, 继续运行..."
fi

# 获取当前 CPU 使用率
cpu_usage=$(top -bn1 | grep "Cpu(s)" | awk '{print $2}' | awk -F. '{print $1}')

echo "当前 CPU 使用率: ${cpu_usage}%"

# 检查 CPU 使用率是否超过阈值
if ((cpu_usage >= threshold_cpu)); then
    echo "CPU 使用率已达到 ${threshold_cpu}%, 执行关机操作..."
    shutdown -h now
else
    echo "CPU 使用率未达到 ${threshold_cpu}%, 继续运行..."
fi