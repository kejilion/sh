# 定义证书存储目录
certs_directory="/home/web/certs/"

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

    # 检查证书是否过期
    if [ $current_timestamp -gt $expiration_timestamp ]; then
        # 若过期，则停止 Nginx
        echo "证书已过期，正在进行自动续签。"
        docker stop nginx

        # 打开 iptables
        iptables -P INPUT ACCEPT
        iptables -P FORWARD ACCEPT
        iptables -P OUTPUT ACCEPT
        iptables -F

        # 续签证书
        certbot certonly --standalone -d $domain --email your@email.com --agree-tos --no-eff-email --force-renewal

        # 复制续签后的证书和私钥
        cp /etc/letsencrypt/live/$domain/cert.pem ${certs_directory}${domain}_cert.pem
        cp /etc/letsencrypt/live/$domain/privkey.pem ${certs_directory}${domain}_key.pem

        # 启动 Nginx
        docker start nginx

        echo "证书已成功续签。"
    else
        # 若未过期，则输出证书仍然有效
        echo "证书仍然有效。"
    fi

    # 输出分隔线
    echo "--------------------------"
done
