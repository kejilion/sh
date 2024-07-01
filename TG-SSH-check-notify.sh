#!/bin/bash




# 获取登录信息
country=$(curl -s ipinfo.io/$public_ip/country)
isp_info=$(curl -s ipinfo.io/org | sed -e 's/\"//g' | awk -F' ' '{print $2}')

ipv4_address=$(curl -s ipv4.ip.sb)
masked_ip=$(echo $ipv4_address | awk -F'.' '{print "*."$3"."$4}')


IP=$(echo $SSH_CONNECTION | awk '{print $1}')
TIME=$(date +"%Y年%m月%d日 %H:%M:%S")
# 查询IP地址对应的地区信息
#LOCATION=$(curl -s https://ipapi.co/$IP/json/ | jq -r '.city')
 LOCATION=$(curl -s "http://opendata.baidu.com/api.php?query=$IP&co=&resource_id=6006&oe=utf8&format=json" | jq -r '.data[0].location')
# 获取当前用户名
 USERNAME=$(whoami)
# 发送Telegram消息
MESSAGE="ℹ️ 登录信息：
登录机器：${isp_info}-${country}-${masked_ip}
登录名：$USERNAME
登录IP：$IP
登录时间：$TIME
登录地区：$LOCATION"

curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID&text=$MESSAGE" > /dev/null 2>&1