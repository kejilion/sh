# 定义证书存储目录
certs_directory="/home/web/certs/"
days_before_expiry=5  # 设置在证书到期前几天触发续签

# 遍历所有证书文件
for cert_file in $certs_directory*_cert.pem; do
    # 获取域名
    domain=$(basename "$cert_file" "_cert.pem")

    # 输出正在检查的证书信息
    echo "检查证书过期日期： ${domain}"

    # 获取证书过期日期
    expiration_date=$(openssl x509 -enddate -noout -in "${certs_directory}${domain}_cert.pem" | cut -d "=" -f 2-)

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

        # 停止 Nginx
        docker stop nginx

        # 打开 iptables
        iptables_open

        # 安装 Certbot
        install_certbot

        # 续签证书
        certbot certonly --standalone -d $domain --email your@email.com --agree-tos --no-eff-email --force-renewal

        # 复制续签后的证书和私钥
        cp /etc/letsencrypt/live/$domain/cert.pem ${certs_directory}${domain}_cert.pem
        cp /etc/letsencrypt/live/$domain/privkey.pem ${certs_directory}${domain}_key.pem

        # 启动 Nginx
        docker start nginx

        echo "证书已成功续签。"
    else
        # 若未满足续签条件，则输出证书仍然有效
        echo "证书仍然有效，距离过期还有 ${days_until_expiry} 天。"
    fi

    # 输出分隔线
    echo "--------------------------"
done
