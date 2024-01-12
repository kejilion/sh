# 使用此脚本前先执行 apt install -y net-tools bc 安装依赖
# */10 * * * * /bin/bash /root/check_trafic1.sh >> /root/check.log 2>&1    cron任务，每10分钟运行检查一次
#!/bin/bash

# 定义颜色
green="\e[1;32m"
yellow="\e[1;33m"
re="\033[0m"

# 设置流量阈值，单位为 GB
threshold_traffic=1000


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