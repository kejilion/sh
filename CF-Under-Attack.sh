#!/bin/bash

# 设置变量
EMAIL="AAAA"
API_KEY="BBBB"
ZONE_ID="CCCC"
LOAD_THRESHOLD=5.0  # 设置高负载阈值

TELEGRAM_BOT_TOKEN="输入TG机器人API"
CHAT_ID="输入TG用户ID"


# 获取当前系统负载
CURRENT_LOAD=$(uptime | awk -F'load average:' '{ print $2 }' | cut -d, -f1 | awk '{print $1}')

echo "当前系统负载: $CURRENT_LOAD"


send_tg_notification() {
    local MESSAGE=$1
    curl -s -X POST "https://api.telegram.org/bot$TELEGRAM_BOT_TOKEN/sendMessage" -d "chat_id=$CHAT_ID" -d "text=$MESSAGE"
}



# 获取当前的“Under Attack”模式状态
STATUS=$(curl -s -X GET "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/security_level" \
     -H "X-Auth-Email: $EMAIL" \
     -H "X-Auth-Key: $API_KEY" \
     -H "Content-Type: application/json" | jq -r '.result.value')

echo "当前的Under Attack模式状态: $STATUS"

# 检查系统负载是否高于阈值
if (( $(echo "$CURRENT_LOAD > $LOAD_THRESHOLD" | bc -l) )); then
    if [ "$STATUS" != "under_attack" ]; then
        echo "系统负载高于阈值，开启Under Attack模式"
        # send_tg_notification "系统负载高于阈值，开启Under Attack模式"
        NEW_STATUS="under_attack"
    else
        echo "系统负载高，但Under Attack模式已经开启"
        exit 0
    fi
else
    if [ "$STATUS" == "under_attack" ]; then
        echo "系统负载低于阈值，关闭Under Attack模式"
        # send_tg_notification "系统负载低于阈值，关闭Under Attack模式"
        NEW_STATUS="high"
    else
        echo "系统负载低，Under Attack模式已经关闭"
        exit 0
    fi
fi

# 更新“Under Attack”模式状态
RESPONSE=$(curl -s -X PATCH "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/settings/security_level" \
     -H "X-Auth-Email: $EMAIL" \
     -H "X-Auth-Key: $API_KEY" \
     -H "Content-Type: application/json" \
     --data "{\"value\":\"$NEW_STATUS\"}")

if [[ $(echo $RESPONSE | jq -r '.success') == "true" ]]; then
    echo "成功更新Under Attack模式状态为: $NEW_STATUS"
else
    echo "更新Under Attack模式状态失败"
    echo "响应: $RESPONSE"
fi
