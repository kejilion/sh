# 定义证书存储目录
certs_directory="/home/web/certs/"
days_before_expiry=15  # 设置在证书到期前几天触发续签

# 遍历所有证书文件
for cert_file in $certs_directory*_cert.pem; do
    # 获取域名
    yuming=$(basename "$cert_file" "_cert.pem")

    # 输出正在检查的证书信息
    echo "检查证书过期日期： ${yuming}"

    # 获取证书过期日期
    expiration_date=$(openssl x509 -enddate -noout -in "${certs_directory}${yuming}_cert.pem" | cut -d "=" -f 2-)

    # 输出证书过期日期
    echo "过期日期： ${expiration_date}"

    # 将日期转换为时间戳
    expiration_timestamp=$(date -d "${expiration_date}" +%s)
    current_timestamp=$(date +%s)

    # 计算距离过期还有几天
    days_until_expiry=$(( ($expiration_timestamp - $current_timestamp) / 86400 ))

    if [ $days_until_expiry -le $days_before_expiry ]; then

        echo "证书将在${days_before_expiry}天内过期，正在进行自动续签。"

        # 1. 检查目录是否存在
        docker exec nginx [ -d /var/www/letsencrypt ] && DIR_OK=true || DIR_OK=false

        # 2. 检查配置文件是否包含关键字
        # 假设你的配置文件在容器内的 /etc/nginx/conf.d/ 目录下（这是 Nginx 容器的默认路径）
        docker exec nginx grep -q "letsencrypt" /etc/nginx/conf.d/$yuming.conf && CONF_OK=true || CONF_OK=false

        # 输出结果
        echo "--- 自动化环境检测报告 ---"
        if [ "$DIR_OK" = true ]; then echo "✅ 目录检测：/var/www/letsencrypt 存在"; else echo "❌ 目录检测：/var/www/letsencrypt 不存在"; fi
        if [ "$CONF_OK" = true ]; then echo "✅ 配置检测：$yuming.conf 已包含续签规则"; else echo "❌ 配置检测：$yuming.conf 未发现 letsencrypt 字样"; fi

        if [ "$DIR_OK" = true ] && [ "$CONF_OK" = true ]; then
            docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n

            docker run --rm \
              -v "/etc/letsencrypt:/etc/letsencrypt" \
              -v "/home/web/letsencrypt:/var/www/letsencrypt" \
              certbot/certbot certonly \
              --webroot \
              -w /var/www/letsencrypt \
              -d "$yuming" \
              --email your@email.com \
              --agree-tos \
              --no-eff-email \
              --key-type ecdsa \
              --force-renewal

            mkdir -p /home/web/certs/
            cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
            cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

            openssl rand -out /home/web/certs/ticket12.key 48
            openssl rand -out /home/web/certs/ticket13.key 80

            docker exec nginx nginx -t && docker exec nginx nginx -s reload

        else
            docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n

            docker stop nginx > /dev/null 2>&1

            docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d $yuming --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa

            mkdir -p /home/web/certs/
            cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
            cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

            openssl rand -out /home/web/certs/ticket12.key 48
            openssl rand -out /home/web/certs/ticket13.key 80

            docker start nginx > /dev/null 2>&1

        fi

        echo "证书已成功续签。"
    else
        # 若未满足续签条件，则输出证书仍然有效
        echo "证书仍然有效，距离过期还有 ${days_until_expiry} 天。"
    fi

    # 输出分隔线
    echo "--------------------------"
done
