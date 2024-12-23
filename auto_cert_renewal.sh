# 定义证书存储目录
certs_directory="/etc/letsencrypt/live/"

days_before_expiry=10  # 设置在证书到期前几天触发续签

# 遍历所有证书文件
for cert_dir in $certs_directory*; do
    # 获取域名
    yuming=$(basename "$cert_dir")

    # 忽略 README 目录
    if [ "$yuming" = "README" ]; then
        continue
    fi

    # 输出正在检查的证书信息
    echo "检查证书过期日期： ${yuming}"

    # 获取fullchain.pem文件路径
    cert_file="${cert_dir}/fullchain.pem"

    # 获取证书过期日期
    expiration_date=$(openssl x509 -enddate -noout -in "${cert_file}" | cut -d "=" -f 2-)

    # 输出证书过期日期
    echo "过期日期： ${expiration_date}"

    # 将日期转换为时间戳
    expiration_timestamp=$(date -d "${expiration_date}" +%s)
    current_timestamp=$(date +%s)

    # 计算距离过期还有几天
    days_until_expiry=$(( ($expiration_timestamp - $current_timestamp) / 86400 ))

    # 检查是否需要续签（在满足续签条件的情况下）
    if [ $days_until_expiry -le $days_before_expiry ]; then
        echo "证书将在${days_before_expiry}天内过期，正在进行自动续签。"
        
        docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n

        docker stop nginx > /dev/null 2>&1

        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -F

        ip6tables -P INPUT ACCEPT
        ip6tables -P FORWARD ACCEPT
        ip6tables -P OUTPUT ACCEPT
        ip6tables -F

        docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d $yuming --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa  

        cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
        cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

        openssl rand -out /home/web/certs/ticket12.key 48
        openssl rand -out /home/web/certs/ticket13.key 80
        
        docker start nginx > /dev/null 2>&1


        echo "证书已成功续签。"
    else
        # 若未满足续签条件，则输出证书仍然有效
        echo "证书仍然有效，距离过期还有 ${days_until_expiry} 天。"
    fi

    # 输出分隔线
    echo "--------------------------"
done
