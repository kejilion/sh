#!/bin/bash

# 定义颜色
re='\e[0m'
red='\e[1;91m'
white='\e[1;97m'
green='\e[1;32m'
yellow='\e[1;33m'
purple='\e[1;35m'
skyblue='\e[1;96m'

# 检查是否为root下运行
[[ $EUID -ne 0 ]] && echo -e "${red}注意: 请在root用户下运行脚本${re}" && sleep 2 && exit 1

# 创建快捷指令
add_alias() {
    config_file=$1
    alias_names=("k" "K")
    [ ! -f "$config_file" ] || touch "$config_file"
    for alias_name in "${alias_names[@]}"; do
        if ! grep -q "alias $alias_name=" "$config_file"; then 
            echo "Adding alias $alias_name to $config_file"
            echo "alias $alias_name='cd ~ && ./ssh_tool.sh'" >> "$config_file"
        fi
    done
    . "$config_file"
}
config_files=("/root/.bashrc" "/root/.profile" "/root/.bash_profile")
for config_file in "${config_files[@]}"; do
    add_alias "$config_file"
done

# 获取当前服务器ipv4和ipv6
ip_address() {
    ipv4_address=$(curl -s ipv4.ip.sb)
    ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
}

# 安装依赖包
install() {
    if [ $# -eq 0 ]; then
        echo -e "${red}未提供软件包参数!${re}"
        return 1
    fi

    for package in "$@"; do
        if command -v "$package" &>/dev/null; then
            echo -e "${green}${package}已经安装了！${re}"
            continue
        fi
        echo -e "${yellow}正在安装 ${package}...${re}"
        if command -v apt &>/dev/null; then
            apt install -y "$package"
        elif command -v dnf &>/dev/null; then
            dnf install -y "$package"
        elif command -v yum &>/dev/null; then
            yum install -y "$package"
        elif command -v apk &>/dev/null; then
            apk add "$package"
        else
            echo -e"${red}暂不支持你的系统!${re}"
            return 1
        fi
    done

    return 0
}

# 安装nodejs
install_nodejs(){
    if command -v node &>/dev/null; then
        # 获取当前已安装nodejs版本
        installed_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')
        echo -e "${green}系统中已经安装Nodejs,版本:${red}${installed_version}${re}"
    else
        echo -e "${yellow}系统中未安装nodejs，正在为你安装...${re}"

        # 根据对应系统安装nodejs
        if command -v apt &>/dev/null; then
            curl -fsSL https://deb.nodesource.com/setup_lts.x | sudo -E bash - && install nodejs
        elif command -v dnf &>/dev/null; then
            dnf install -y nodejs npm
        elif command -v yum &>/dev/null; then
            curl -fsSL https://rpm.nodesource.com/setup_21.x | sudo bash - && install nodejs
        elif command -v apk &>/dev/null; then
            apk add nodejs npm
        else
            echo -e "${red}暂不支持你的系统!${re}"
            return 1
        fi
        
        if [ $? -eq 0 ]; then
            echo -e "${green}nodejs安装成功!${re}"
            sleep 2
            break_end
        else
            echo -e "${red}nodejs安装失败，尝试再次安装...${re}"
            install nodejs npm
            sleep 2
            break_end
        fi
    fi 
}

# 安装java
install_java() {
    if command -v java &>/dev/null; then
        # 检查安装版本
        installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
        echo -e "${green}系统已经安装Java${yellow}${installed_version}${re}"     

    else
        echo -e "${yellow}系统中未安装Java，正在为你安装...${re}"

        local install_status=0

        if command -v apt &>/dev/null; then
            apt install -y openjdk-17-jdk
        elif command -v yum &>/dev/null; then
            yum install -y java-17-openjdk
        elif command -v dnf &>/dev/null; then
            dnf install -y java-17-openjdk
        elif command -v apk &>/dev/null; then
            apk add openjdk17
        else
            echo -e "${red}暂不支持你的系统！${re}"
            exit 1
        fi

        if [ $install_status -eq 0 ]; then
            echo -e "${green}Java安装成功${re}"
            sleep 2
            break_end
        else                    
            echo -e "${red}Java安装失败，尝试为你再次安装...${re}"
            install java-17-openjdk
            sleep 2
            break_end
        fi
    fi   
}

# 卸载依赖包
remove() {
    if [ $# -eq 0 ]; then
        echo -e "${red}未提供软件包参数!${re}"
        return 1
    fi

    for package in "$@"; do
        if command -v apt &>/dev/null; then
            apt remove -y "$package" && apt autoremove -y
        elif command -v dnf &>/dev/null; then
            dnf remove -y "$package" && dnf autoremove -y
        elif command -v yum &>/dev/null; then
            yum remove -y "$package" && yum autoremove -y
        elif command -v apk &>/dev/null; then
            apk del "$package"
        else
            echo -e "${red}暂不支持你的系统!${re}"
            return 1
        fi
    done

    return 0
}

# 初始安装依赖包
install_dependency() {
      clear
      install wget socat unzip tar
}

# 等待用户返回
break_end() {
    echo -e "${green}执行完成${re}"
    echo -e "${yellow}按任意键返回...${re}"
    read -n 1 -s -r -p ""
    echo ""
    clear
}
# 返回主菜单
main_menu() {
    cd ~
    ./ssh_tool.sh
    exit
}

check_port() {
    # 定义要检测的端口
    PORT=443

    # 检查端口占用情况
    result=$(ss -tulpn | grep ":$PORT")

    # 判断结果并输出相应信息
    if [ -n "$result" ]; then
        is_nginx_container=$(docker ps --format '{{.Names}}' | grep 'nginx')

        # 判断是否是Nginx容器占用端口
        if [ -n "$is_nginx_container" ]; then
            echo ""
        else
            clear
            echo -e "\e[1;31m端口 $PORT 已被占用，无法安装环境，卸载以下程序后重试！\e[0m"
            echo "$result"
            break_end
            ssh_tool
        fi
    else
        echo ""
    fi
}


# 定义安装 Docker 的函数
install_docker() {
    if ! command -v docker &>/dev/null; then
        curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
        systemctl start docker
        systemctl enable docker
    else
        echo "Docker 已经安装"
    fi
}

iptables_open() {
    iptables -P INPUT ACCEPT
    iptables -P FORWARD ACCEPT
    iptables -P OUTPUT ACCEPT
    iptables -F
}

install_ldnmp() {
      cd /home/web && docker-compose up -d
      clear
      echo "正在配置LDNMP环境，请耐心稍等……"

      # 定义要执行的命令
      commands=(
          "docker exec php apt update > /dev/null 2>&1"
          "docker exec php apt install -y libmariadb-dev-compat libmariadb-dev libzip-dev libmagickwand-dev imagemagick > /dev/null 2>&1"
          "docker exec php docker-php-ext-install mysqli pdo_mysql zip exif gd intl bcmath opcache > /dev/null 2>&1"
          "docker exec php pecl install imagick > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"extension=imagick.so\" > /usr/local/etc/php/conf.d/imagick.ini' > /dev/null 2>&1"
          "docker exec php pecl install redis > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"extension=redis.so\" > /usr/local/etc/php/conf.d/docker-php-ext-redis.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"upload_max_filesize=50M \\n post_max_size=50M\" > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"memory_limit=256M\" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"max_execution_time=1200\" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1"
          "docker exec php sh -c 'echo \"max_input_time=600\" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1"

          "docker exec php74 apt update > /dev/null 2>&1"
          "docker exec php74 apt install -y libmariadb-dev-compat libmariadb-dev libzip-dev libmagickwand-dev imagemagick > /dev/null 2>&1"
          "docker exec php74 docker-php-ext-install mysqli pdo_mysql zip gd intl bcmath opcache > /dev/null 2>&1"
          "docker exec php74 pecl install imagick > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"extension=imagick.so\" > /usr/local/etc/php/conf.d/imagick.ini' > /dev/null 2>&1"
          "docker exec php74 pecl install redis > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"extension=redis.so\" > /usr/local/etc/php/conf.d/docker-php-ext-redis.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"upload_max_filesize=50M \\n post_max_size=50M\" > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"memory_limit=256M\" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"max_execution_time=1200\" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1"
          "docker exec php74 sh -c 'echo \"max_input_time=600\" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1"

          "docker exec nginx chmod -R 777 /var/www/html"
          "docker exec php chmod -R 777 /var/www/html"
          "docker exec php74 chmod -R 777 /var/www/html"

          "docker restart php > /dev/null 2>&1"
          "docker restart php74 > /dev/null 2>&1"
          "docker restart nginx > /dev/null 2>&1"

      )

      total_commands=${#commands[@]}  # 计算总命令数

      for ((i = 0; i < total_commands; i++)); do
          command="${commands[i]}"
          eval $command  # 执行命令

          # 打印百分比和进度条
          percentage=$(( (i + 1) * 100 / total_commands ))
          completed=$(( percentage / 2 ))
          remaining=$(( 50 - completed ))
          progressBar="["
          for ((j = 0; j < completed; j++)); do
              progressBar+="#"
          done
          for ((j = 0; j < remaining; j++)); do
              progressBar+="."
          done
          progressBar+="]"
          echo -ne "\r[$percentage%] $progressBar"
      done

      echo  # 打印换行，以便输出不被覆盖


      clear
      echo -e "${green}LDNMP环境安装完毕${re}"
      echo "------------------------"

      # 获取nginx版本
      nginx_version=$(docker exec nginx nginx -v 2>&1)
      nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
      echo -n "nginx : v$nginx_version"

      # 获取mysql版本
      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
      echo -n "            mysql : v$mysql_version"

      # 获取php版本
      php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
      echo -n "            php : v$php_version"

      # 获取redis版本
      redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
      echo "            redis : v$redis_version"

      echo "------------------------"
      echo ""


}

install_certbot() {
    install certbot

    # 切换到一个一致的目录（例如，家目录）
    cd ~ || exit

    # 下载并使脚本可执行
    curl -O https://raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
    chmod +x auto_cert_renewal.sh

    # 安排每日午夜运行脚本
    echo "0 0 * * * cd ~ && ./auto_cert_renewal.sh" | crontab -
}

install_ssltls() {
      docker stop nginx > /dev/null 2>&1
      iptables_open
      cd ~
      certbot certonly --standalone -d $yuming --email your@email.com --agree-tos --no-eff-email --force-renewal
      cp /etc/letsencrypt/live/$yuming/cert.pem /home/web/certs/${yuming}_cert.pem
      cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem
      docker start nginx > /dev/null 2>&1
}


default_server_ssl() {
install openssl
openssl req -x509 -nodes -newkey rsa:2048 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"

}


nginx_status() {

    nginx_container_name="nginx"

    # 获取容器的状态
    container_status=$(docker inspect -f '{{.State.Status}}' "$nginx_container_name" 2>/dev/null)

    # 获取容器的重启状态
    container_restart_count=$(docker inspect -f '{{.RestartCount}}' "$nginx_container_name" 2>/dev/null)

    # 检查容器是否在运行，并且没有处于"Restarting"状态
    if [ "$container_status" == "running" ]; then
        echo ""
    else
        rm -r /home/web/html/$yuming >/dev/null 2>&1
        rm /home/web/conf.d/$yuming.conf >/dev/null 2>&1
        rm /home/web/certs/${yuming}_key.pem >/dev/null 2>&1
        rm /home/web/certs/${yuming}_cert.pem >/dev/null 2>&1
        docker restart nginx >/dev/null 2>&1
        echo -e "\e[1;31m检测到域名证书申请失败，请检测域名是否正确解析或更换域名重新尝试！\e[0m"
    fi

}


add_yuming() {
      ip_address
      echo -e "先将域名解析到本机IP: \033[33m$ipv4_address  $ipv6_address\033[0m"
      read -p "请输入你解析的域名: " yuming
}


add_db() {
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}

reverse_proxy() {
      ip_address
      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0000/$duankou/g" /home/web/conf.d/$yuming.conf
      docker restart nginx
}

restart_ldnmp() {
      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      docker restart php
      docker restart php74
      docker restart nginx
}


docker_app() {
if docker inspect "$docker_name" &>/dev/null; then
    clear
    echo "$docker_name 已安装，访问地址: "
    ip_address
    echo "http:$ipv4_address:$docker_port"
    echo ""
    echo "应用操作"
    echo "------------------------"
    echo "1. 更新应用             2. 卸载应用"
    echo "------------------------"
    echo "0. 返回上一级选单"
    echo "------------------------"
    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

    case $sub_choice in
        1)
            clear
            docker rm -f "$docker_name"
            docker rmi -f "$docker_img"
            # 安装 Docker（请确保有 install_docker 函数）
            install_docker
            $docker_rum
            clear
            echo "$docker_name 已经安装完成"
            echo "------------------------"
            # 获取外部 IP 地址
            ip_address
            echo "您可以使用以下地址访问:"
            echo "http:$ipv4_address:$docker_port"
            $docker_use
            $docker_passwd
            ;;
        2)
            clear
            docker rm -f "$docker_name"
            docker rmi -f "$docker_img"
            rm -rf "/home/docker/$docker_name"
            echo "应用已卸载"
            ;;
        0)
            # 跳出循环，退出菜单
            ;;
        *)
            # 跳出循环，退出菜单
            ;;
    esac
else
    clear
    echo "安装提示"
    echo "$docker_describe"
    echo "$docker_url"
    echo ""

    # 提示用户确认安装
    read -p "确定安装吗？(Y/N): " choice
    case "$choice" in
        [Yy])
            clear
            # 安装 Docker（请确保有 install_docker 函数）
            install_docker
            $docker_rum
            clear
            echo "$docker_name 已经安装完成"
            echo "------------------------"
            # 获取外部 IP 地址
            ip_address
            echo "您可以使用以下地址访问:"
            echo "http:$ipv4_address:$docker_port"
            $docker_use
            $docker_passwd
            ;;
        [Nn])
            # 用户选择不安装
            ;;
        *)
            # 无效输入
            ;;
    esac
fi

}
# 运行统计
sum_run_times() {
  local COUNT=$(wget --no-check-certificate -qO- --tries=2 --timeout=2 "https://hits.seeyoufarm.com/api/count/incr/badge.svg?url=https%3A%2F%2Fraw.githubusercontent.com%2Feooce%2Fssh_tool%2Fmain%2Fssh_tool.sh" 2>&1 | grep -m1 -oE "[0-9]+[ ]+/[ ]+[0-9]+") &&
  TODAY=$(cut -d " " -f1 <<< "$COUNT") &&
  TOTAL=$(cut -d " " -f3 <<< "$COUNT")
}
sum_run_times

while true; do
clear
echo -e "    ${skyblue}当日运行：${yellow}${TODAY}次   ${skyblue}累计运行：${yellow}${TOTAL}次${re}"
echo -e "\033[0;97m-----------------By'eooce-----------------\033[0m"
echo -e "\033[0;97m脚本地址: https://github.com/eooce/ssh_tool\033[0m" 
echo ""
echo -e "${skyblue} ##  ## #####   ####       ######  ####   ####  ##      ${re}" 
echo -e "${skyblue} ##  ## ##  ## ##            ##   ##  ## ##  ## ##      ${re}" 
echo -e "${skyblue} ##  ## #####   ####.        ##   ##  ## ##  ## ##      ${re}" 
echo -e "${skyblue}  ####  ##         ##        ##   ##  ## ##  ## ##      ${re}" 
echo -e "${skyblue}   ##   ##     ####          ##    ####   ####  ######  ${re}"  
echo -e ""
echo -e "                 ${yellow}VPS一键脚本工具 v8.8.8${re}"
echo -e "${yellow}支持Ubuntu/Debian/CentOS/Alpine/Fedora/Rocky/Almalinux/Oracle-linux${re}"
echo -e ""
echo -e "${skyblue}快捷键已设置为${yellow}k,${skyblue}下次运行输入${yellow}k${skyblue}可快速启动此脚本${re}"
echo "-------------------------------------------------------------------"
echo -e "${green} 1. 本机信息                   5. BBR管理 ${re}"
echo -e "${green} 2. 系统更新                   6. Docker管理 ▶${re}"
echo -e "${green} 3. 系统清理                   7. WARP管理 ▶解锁ChatGPT/Netflix${re}"
echo -e "${green} 4. 组件管理 ▶${purple}                 8. LDNMP建站 ▶${re}"
echo "-------------------------------------------------------------------"
echo -e "${green} 9. 面板工具 ▶                13. 测试脚本合集 ▶${re}"
echo -e "${green}10. 系统工具 ▶                14. 甲骨文云合集 ▶${re}"
echo -e "${green}11. 我的工作区 ▶              15. 常用环境管理 ▶${re}"
echo -e "${purple}12. 节点搭建合集 ▶            16. 开设NAT小鸡 ▶${re}"
echo "-------------------------------------------------------------------"
echo -e "${green}00. 脚本更新${red}                  88. 退出脚本${re}"
echo -e "${yellow}-------------------------------------------------------------------${re}"
read -p $'\033[1;91m请输入你的选择: \033[0m' choice

case $choice in
  1)
    clear
    ip_address
    
    if [ "$(uname -m)" == "x86_64" ]; then
      cpu_info=$(cat /proc/cpuinfo | grep 'model name' | uniq | sed -e 's/model name[[:space:]]*: //')
    else
      cpu_info=$(lscpu | grep 'Model name' | sed -e 's/Model name[[:space:]]*: //')
    fi

    cpu_usage=$(top -bn1 | grep 'Cpu(s)' | awk '{print $2 + $4}')
    cpu_usage_percent=$(printf "%.2f" "$cpu_usage")%

    cpu_cores=$(nproc)

    mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

    disk_info=$(df -h | awk '$NF=="/"{printf "%d/%dGB (%s)", $3,$2,$5}')

    country=$(curl -s ipinfo.io/country)
    city=$(curl -s ipinfo.io/city)

    isp_info=$(curl -s ipinfo.io/org)

    cpu_arch=$(uname -m)

    hostname=$(hostname)

    kernel_version=$(uname -r)

    congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
    queue_algorithm=$(sysctl -n net.core.default_qdisc)

    # 尝试使用 lsb_release 获取系统信息
    os_info=$(lsb_release -ds 2>/dev/null)

    # 如果 lsb_release 命令失败，则尝试其他方法
    if [ -z "$os_info" ]; then
      # 检查常见的发行文件
      if [ -f "/etc/os-release" ]; then
        os_info=$(source /etc/os-release && echo "$PRETTY_NAME")
      elif [ -f "/etc/debian_version" ]; then
        os_info="Debian $(cat /etc/debian_version)"
      elif [ -f "/etc/redhat-release" ]; then
        os_info=$(cat /etc/redhat-release)
      else
        os_info="Unknown"
      fi
    fi

    clear
    output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
        NR > 2 { rx_total += $2; tx_total += $10 }
        END {
            rx_units = "Bytes";
            tx_units = "Bytes";
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "KB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "MB"; }
            if (rx_total > 1024) { rx_total /= 1024; rx_units = "GB"; }

            if (tx_total > 1024) { tx_total /= 1024; tx_units = "KB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "MB"; }
            if (tx_total > 1024) { tx_total /= 1024; tx_units = "GB"; }

            printf("总接收: %.2f %s\n总发送: %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
        }' /proc/net/dev)


    current_time=$(date "+%Y-%m-%d %I:%M %p")


    swap_used=$(free -m | awk 'NR==3{print $3}')
    swap_total=$(free -m | awk 'NR==3{print $2}')

    if [ "$swap_total" -eq 0 ]; then
        swap_percentage=0
    else
        swap_percentage=$((swap_used * 100 / swap_total))
    fi

    swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

    runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

    echo ""
    echo -e "${white}系统信息详情${re}"
    echo "------------------------"
    echo -e "${white}主机名: ${purple}${hostname}${re}"
    echo -e "${white}运营商: ${purple}${isp_info}${re}"
    echo "------------------------"
    echo -e "${white}系统版本: ${purple}${os_info}${re}"
    echo -e "${white}Linux版本: ${purple}${kernel_version}${re}"
    echo "------------------------"
    echo -e "${white}CPU架构: ${purple}${cpu_arch}${re}"
    echo -e "${white}CPU型号: ${purple}${cpu_info}${re}"
    echo -e "${white}CPU核心数: ${purple}${cpu_cores}${re}"
    echo "------------------------"
    echo -e "${white}CPU占用: ${purple}${cpu_usage_percent}${re}"
    echo -e "${white}物理内存: ${purple}${mem_info}${re}"
    echo -e "${white}虚拟内存: ${purple}${swap_info}${re}"
    echo -e "${white}硬盘占用: ${purple}${disk_info}${re}"
    echo "------------------------"
    echo -e "${purple}$output${re}"
    echo "------------------------"
    echo -e "${white}网络拥堵算法: ${purple}${congestion_algorithm} ${queue_algorithm}${re}"
    echo "------------------------"
    echo -e "${white}公网IPv4地址: ${purple}${ipv4_address}${re}"
    echo -e "${white}公网IPv6地址: ${purple}${ipv6_address}${re}"
    echo "------------------------"
    echo -e "${white}地理位置: ${purple}${country} $city${re}"
    echo -e "${white}系统时间: ${purple}${current_time}${re}"
    echo "------------------------"
    echo -e "${white}系统运行时长: ${purple}${runtime}${re}"
    echo

    ;;

  2)
    clear
    update_system() {
        if command -v apt &>/dev/null; then
            apt-get update && apt-get upgrade -y
        elif command -v dnf &>/dev/null; then
            dnf check-update && dnf upgrade -y
        elif command -v yum &>/dev/null; then
            yum check-update && yum upgrade -y
        elif command -v apk &>/dev/null; then
            apk update && apk upgrade
        else
            echo -e "${red}不支持的Linux发行版${re}"
            return 1
        fi
        return 0
    }

    update_system

    ;;
  3)
    clear
        clean_system() {

            if command -v apt &>/dev/null; then
                apt autoremove --purge -y && apt clean -y && apt autoclean -y
                apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
                # 清理包配置文件
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
                # 移除不再需要的内核
                apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
            elif command -v yum &>/dev/null; then
                yum autoremove -y && yum clean all
                # 清理日志
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
                # 移除不再需要的内核
                yum remove $(rpm -q kernel | grep -v $(uname -r)) -y
            elif command -v dnf &>/dev/null; then
                dnf autoremove -y && dnf clean all
                # 清理日志
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
                # 移除不再需要的内核
                dnf remove $(rpm -q kernel | grep -v $(uname -r)) -y
            elif command -v apk &>/dev/null; then
                apk autoremove -y
                apk clean
                # 清理包配置文件
                apk del $(apk info -e | grep '^r' | awk '{print $1}') -y
                # 清理日志文件
                journalctl --vacuum-time=1s
                journalctl --vacuum-size=50M
                # 移除不再需要的内核
                apk del $(apk info -vv | grep -E 'linux-[0-9]' | grep -v $(uname -r) | awk '{print $1}') -y
            else
                echo -e "${red}暂不支持你的系统！${re}"
                exit 1
            fi
        }
        clean_system
    ;;

  4)
  while true; do
      clear
      echo "▶ 组件管理"
      echo "------------------------"
      echo " 1. curl 下载工具"
      echo " 2. wget 下载工具"
      echo " 3. sudo 超级管理权限工具"
      echo " 4. socat 通信连接工具 （申请域名证书必备）"
      echo " 5. htop 系统监控工具"
      echo " 6. iftop 网络流量监控工具"
      echo " 7. unzip ZIP压缩解压工具"
      echo " 8. tar GZ压缩解压工具"
      echo " 9. tmux 多路后台运行工具"
      echo "10. ffmpeg 视频编码直播推流工具"
      echo "11. btop 现代化监控工具"
      echo "12. ranger 文件管理工具"
      echo "13. gdu 磁盘占用查看工具"
      echo "14. fzf 全局搜索工具"
      echo "15. screen后台会话工具"
      echo "16. masscan端口快速扫描工具"
      echo "------------------------"
      echo "21. cmatrix 黑客帝国屏保"
      echo "22. sl 跑火车屏保"
      echo "------------------------"
      echo "26. 俄罗斯方块小游戏"
      echo "27. 贪吃蛇小游戏 "
      echo "28. 太空入侵者小游戏"
      echo "------------------------"
      echo "31. 全部安装"
      echo -e "${red}32. 全部卸载${re}"
      echo "------------------------"
      echo -e "${yellow}41. 安装指定工具${re}"
      echo -e "${red}42. 卸载指定工具${re}"
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              install curl
              clear
              echo "工具已安装，使用方法如下："
              curl --help
              ;;
          2)
              clear
              install wget
              clear
              echo "工具已安装，使用方法如下："
              wget --help
              ;;
            3)
              clear
              install sudo
              clear
              echo "工具已安装，使用方法如下："
              sudo --help
              ;;
            4)
              clear
              install socat
              clear
              echo "工具已安装，使用方法如下："
              socat -h
              ;;
            5)
              clear
              install htop
              clear
              htop
              ;;
            6)
              clear
              install iftop
              clear
              iftop
              ;;
            7)
              clear
              install unzip
              clear
              echo "工具已安装，使用方法如下："
              unzip
              ;;
            8)
              clear
              install tar
              clear
              echo "工具已安装，使用方法如下："
              tar --help
              ;;
            9)
              clear
              install tmux
              clear
              echo "工具已安装，使用方法如下："
              tmux --help
              ;;
            10)
              clear
              install ffmpeg
              clear
              echo "工具已安装，使用方法如下："
              ffmpeg --help
              ;;

            11)
              clear
              install btop
              clear
              btop
              ;;
            12)
              clear
              install ranger
              cd /
              clear
              ranger
              cd ~
              ;;
            13)
              clear
              install gdu
              cd /
              clear
              gdu
              cd ~
              ;;
            14)
              clear
              install fzf
              cd /
              clear
              fzf
              cd ~
              ;;
            15)
              clear
                # 检测 CentOS 系统
                if [ -f /etc/os-release ]; then
                    os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
                elif command -v lsb_release > /dev/null 2>&1; then
                    # 如果 os-release 文件不存在，则使用 lsb_release
                    os_name=$(lsb_release -i | cut -f2)
                else
                    echo "无法确定操作系统类型。"
                    exit 1
                fi
                os_name=$(echo $os_name | tr -d '"')
                if [ "$os_name" = "centos" ] || [ "$os_name" = "rocky" ]; then
                    yum install epel-release -y
                    yum install screen -y
                elif [ "$os_name" = "amzn" ]; then
                    amazon-linux-extras install epel
                    yum install screen -y                    
                else
                    install screen
                fi
                cd ~
              ;;
            16)
              clear
                # 检测 CentOS 系统
                if [ -f /etc/os-release ]; then
                    os_name=$(grep '^ID=' /etc/os-release | cut -d= -f2)
                elif command -v lsb_release > /dev/null 2>&1; then
                    # 如果 os-release 文件不存在，则使用 lsb_release
                    os_name=$(lsb_release -i | cut -f2)
                else
                    echo "无法确定操作系统类型。"
                    exit 1
                fi
                os_name=$(echo $os_name | tr -d '"')
                if [ "$os_name" = "centos" ] || [ "$os_name" = "rocky" ]; then
                    yum install epel-release -y
                    yum install masscan -y
                elif [ "$os_name" = "amzn" ]; then
                    amazon-linux-extras install epel
                    yum install masscan -y                    
                else
                    install masscan
                fi
                cd ~
              ;;
            21)
              clear
              install cmatrix
              clear
              cmatrix
              ;;
            22)
              clear
              install sl
              clear
              /usr/games/sl
              ;;
            26)
              clear
              install bastet
              clear
              /usr/games/bastet
              ;;
            27)
              clear
              install nsnake
              clear
              /usr/games/nsnake
              ;;
            28)
              clear
              install ninvaders
              clear
              /usr/games/ninvaders

              ;;

          31)
              clear
              install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders
              ;;

          32)
              clear
              remove htop iftop unzip tmux ffmpeg btop ranger gdu fzf cmatrix sl bastet nsnake ninvaders
              ;;

          41)
              clear
              read -p "请输入安装的工具名（wget curl sudo htop）: " installname
              install $installname
              ;;
          42)
              clear
              read -p "请输入卸载的工具名（htop ufw tmux cmatrix）: " removename
              remove $removename
              ;;

          0)
              main_menu

              ;;

          *)
              echo "无效的输入!"
              ;;
      esac
      break_end
  done

    ;;

  5)
    clear
    install wget
    wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
    chmod +x tcpx.sh
    ./tcpx.sh
    ;;

  6)
    while true; do
      clear
      echo "▶ Docker管理器"
      echo "------------------------"
      echo "1. 安装更新Docker环境"
      echo "------------------------"
      echo "2. 查看Dcoker全局状态"
      echo "------------------------"
      echo "3. Dcoker容器管理 ▶"
      echo "4. Dcoker镜像管理 ▶"
      echo "5. Dcoker网络管理 ▶"
      echo "6. Dcoker卷管理 ▶"
      echo "------------------------"
      echo "7. 清理无用的docker容器和镜像网络数据卷"
      echo "------------------------"
      echo -e "${red}8. 卸载Dcoker环境${re}"
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
              systemctl start docker
              systemctl enable docker
              ;;
          2)
              clear
              echo "Dcoker版本"
              docker --version
              docker-compose --version
              echo ""
              echo "Dcoker镜像列表"
              docker image ls
              echo ""
              echo "Dcoker容器列表"
              docker ps -a
              echo ""
              echo "Dcoker卷列表"
              docker volume ls
              echo ""
              echo "Dcoker网络列表"
              docker network ls
              echo ""

              ;;
          3)
              while true; do
                  clear
                  echo "Docker容器列表"
                  docker ps -a
                  echo ""
                  echo "容器操作"
                  echo "------------------------"
                  echo " 1. 创建新的容器"
                  echo "------------------------"
                  echo " 2. 启动指定容器             6. 启动所有容器"
                  echo " 3. 停止指定容器             7. 暂停所有容器"
                  echo " 4. 删除指定容器             8. 删除所有容器"
                  echo " 5. 重启指定容器             9. 重启所有容器"
                  echo "------------------------"
                  echo "11. 进入指定容器           12. 查看容器日志           13. 查看容器网络"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "请输入创建命令: " dockername
                          $dockername
                          ;;

                      2)
                          read -p "请输入容器名: " dockername
                          docker start $dockername
                          ;;
                      3)
                          read -p "请输入容器名: " dockername
                          docker stop $dockername
                          ;;
                      4)
                          read -p "请输入容器名: " dockername
                          docker rm -f $dockername
                          ;;
                      5)
                          read -p "请输入容器名: " dockername
                          docker restart $dockername
                          ;;
                      6)
                          docker start $(docker ps -a -q)
                          ;;
                      7)
                          docker stop $(docker ps -q)
                          ;;
                      8)
                          read -p "确定删除所有容器吗？(Y/N): " choice
                          case "$choice" in
                            [Yy])
                              docker rm -f $(docker ps -a -q)
                              ;;
                            [Nn])
                              ;;
                            *)
                              echo "无效的选择，请输入 Y 或 N。"
                              ;;
                          esac
                          ;;
                      9)
                          docker restart $(docker ps -q)
                          ;;
                      11)
                          read -p "请输入容器名: " dockername
                          docker exec -it $dockername /bin/bash
                          break_end
                          ;;
                      12)
                          read -p "请输入容器名: " dockername
                          docker logs $dockername
                          break_end
                          ;;
                      13)
                          echo ""
                          container_ids=$(docker ps -q)

                          echo "------------------------------------------------------------"
                          printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

                          for container_id in $container_ids; do
                              container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

                              container_name=$(echo "$container_info" | awk '{print $1}')
                              network_info=$(echo "$container_info" | cut -d' ' -f2-)

                              while IFS= read -r line; do
                                  network_name=$(echo "$line" | awk '{print $1}')
                                  ip_address=$(echo "$line" | awk '{print $2}')

                                  printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
                              done <<< "$network_info"
                          done

                          break_end
                          ;;

                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;
          4)
              while true; do
                  clear
                  echo "Docker镜像列表"
                  docker image ls
                  echo ""
                  echo "镜像操作"
                  echo "------------------------"
                  echo "1. 获取指定镜像             3. 删除指定镜像"
                  echo "2. 更新指定镜像             4. 删除所有镜像"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "请输入镜像名: " dockername
                          docker pull $dockername
                          ;;
                      2)
                          read -p "请输入镜像名: " dockername
                          docker pull $dockername
                          ;;
                      3)
                          read -p "请输入镜像名: " dockername
                          docker rmi -f $dockername
                          ;;
                      4)
                          read -p "确定删除所有镜像吗？(Y/N): " choice
                          case "$choice" in
                            [Yy])
                              docker rmi -f $(docker images -q)
                              ;;
                            [Nn])

                              ;;
                            *)
                              echo "无效的选择，请输入 Y 或 N。"
                              ;;
                          esac
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;

          5)
              while true; do
                  clear
                  echo "Docker网络列表"
                  echo "------------------------------------------------------------"
                  docker network ls
                  echo ""

                  echo "------------------------------------------------------------"
                  container_ids=$(docker ps -q)
                  printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

                  for container_id in $container_ids; do
                      container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

                      container_name=$(echo "$container_info" | awk '{print $1}')
                      network_info=$(echo "$container_info" | cut -d' ' -f2-)

                      while IFS= read -r line; do
                          network_name=$(echo "$line" | awk '{print $1}')
                          ip_address=$(echo "$line" | awk '{print $2}')

                          printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
                      done <<< "$network_info"
                  done

                  echo ""
                  echo "网络操作"
                  echo "------------------------"
                  echo "1. 创建网络"
                  echo "2. 加入网络"
                  echo "3. 退出网络"
                  echo "4. 删除网络"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "设置新网络名: " dockernetwork
                          docker network create $dockernetwork
                          ;;
                      2)
                          read -p "加入网络名: " dockernetwork
                          read -p "那些容器加入该网络: " dockername
                          docker network connect $dockernetwork $dockername
                          echo ""
                          ;;
                      3)
                          read -p "退出网络名: " dockernetwork
                          read -p "那些容器退出该网络: " dockername
                          docker network disconnect $dockernetwork $dockername
                          echo ""
                          ;;

                      4)
                          read -p "请输入要删除的网络名: " dockernetwork
                          docker network rm $dockernetwork
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;

          6)
              while true; do
                  clear
                  echo "Docker卷列表"
                  docker volume ls
                  echo ""
                  echo "卷操作"
                  echo "------------------------"
                  echo "1. 创建新卷"
                  echo "2. 删除卷"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "设置新卷名: " dockerjuan
                          docker volume create $dockerjuan

                          ;;
                      2)
                          read -p "输入删除卷名: " dockerjuan
                          docker volume rm $dockerjuan

                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;
          7)
              clear
              read -p "确定清理无用的镜像容器网络吗？(Y/N): " choice
              case "$choice" in
                [Yy])
                  docker system prune -af --volumes
                  ;;
                [Nn])
                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac
              ;;
          8)
              clear
              read -p "确定卸载docker环境吗？(Y/N): " choice
              case "$choice" in
                [Yy])
                  docker rm $(docker ps -a -q) && docker rmi $(docker images -q) && docker network prune
                  remove docker docker-ce > /dev/null 2>&1
                  rm -rf /var/lib/docker
                  ;;
                [Nn])
                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac
              ;;
          0)
              main_menu

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end


    done

    ;;


  7)
    clear
    install wget
    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
    ;;

  8)
  clear
  while true; do
    clear
    echo -e "${purple}▶ LDNMP建站${re}"
    echo  "------------------------"
    echo  " 1. 安装LDNMP环境"
    echo  "------------------------"
    echo  " 2. 安装WordPress"
    echo  " 3. 安装Discuz论坛"
    echo  " 4. 安装可道云桌面"
    echo  " 5. 安装苹果CMS网站"
    echo  " 6. 安装独角数发卡网"
    echo  " 7. 安装BingChatAI聊天网站"
    echo  " 8. 安装flarum论坛网站"
    echo  " 9. 安装Bitwarden密码管理平台"
    echo  "10. 安装Halo博客网站"
    echo  "11. 安装typecho轻量博客网站"
    echo  "12. 安装Pbootcms企业站"
    echo  "13. 安装极致CMS企业站"
    echo  "14. 安装易优CMS企业站"
    echo  "------------------------"
    echo  "21. 仅安装nginx "
    echo  "22. 站点重定向"
    echo  "23. 站点反向代理"
    echo -e "24. 自定义静态站点"
    echo  "------------------------"
    echo  "31. 站点数据管理"
    echo  "32. 备份全站数据"
    echo  "33. 定时远程备份"
    echo  "34. 还原全站数据"
    echo  "------------------------"
    echo  "35. 站点防御程序"
    echo  "------------------------"
    echo  "36. 优化LDNMP环境"
    echo  "37. 更新LDNMP环境"
    echo  -e "${red}38. 卸载LDNMP环境${re}"
    echo  "------------------------"
    echo  -e "${yellow} 0. 返回主菜单${re}"
    echo  "------------------------"
    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice


    case $sub_choice in
      1)
      check_port
      install_dependency
      install_docker
      install_certbot

      # 创建必要的目录和文件
      cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml

      wget -O /home/web/nginx.conf https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
      wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/kejilion/nginx/main/default10.conf
      default_server_ssl

      # 下载 docker-compose.yml 文件并进行替换
      wget -O /home/web/docker-compose.yml https://raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml

      dbrootpasswd=$(openssl rand -base64 16) && dbuse=$(openssl rand -hex 4) && dbusepasswd=$(openssl rand -base64 8)

      # 在 docker-compose.yml 文件中进行替换
      sed -i "s/webroot/$dbrootpasswd/g" /home/web/docker-compose.yml
      sed -i "s/kejilionYYDS/$dbusepasswd/g" /home/web/docker-compose.yml
      sed -i "s/kejilion/$dbuse/g" /home/web/docker-compose.yml

      install_ldnmp

        ;;
      2)
      clear
      # wordpress
      add_yuming
      install_ssltls
      add_db

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget -O latest.zip https://cn.wordpress.org/latest-zh_CN.zip
      unzip latest.zip
      rm latest.zip

      echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php

      restart_ldnmp

      clear
      echo "您的WordPress搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "WP安装信息如下: "
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "数据库地址: mysql"
      echo "表前缀: wp_"
      nginx_status
        ;;

      3)
      clear
      # Discuz论坛
      add_yuming
      install_ssltls
      add_db

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf

      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget https://github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20230520.zip
      unzip -o Discuz_X3.5_SC_UTF8_20230520.zip
      rm Discuz_X3.5_SC_UTF8_20230520.zip

      restart_ldnmp


      clear
      echo "您的Discuz论坛搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库地址: mysql"
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "表前缀: discuz_"
      nginx_status

        ;;

      4)
      clear
      # 可道云桌面
      add_yuming
      install_ssltls
      add_db

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget https://github.com/kalcaddle/kodbox/archive/refs/tags/1.42.04.zip
      unzip -o 1.42.04.zip
      rm 1.42.04.zip

      restart_ldnmp


      clear
      echo "您的可道云桌面搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库地址: mysql"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "数据库名: $dbname"
      echo "redis主机: redis"
      nginx_status
        ;;

      5)
      clear
      # 苹果CMS
      add_yuming
      install_ssltls
      add_db

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf

      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget https://github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
      cd /home/web/html/$yuming/maccms10-master/template/ && wget https://github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/maccms10-master/template/DYXS2.zip
      cp /home/web/html/$yuming/maccms10-master/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/maccms10-master/application/admin/controller
      cp /home/web/html/$yuming/maccms10-master/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/maccms10-master/application/admin/view/system
      mv /home/web/html/$yuming/maccms10-master/admin.php /home/web/html/$yuming/maccms10-master/vip.php && wget -O /home/web/html/$yuming/maccms10-master/application/extra/maccms.php https://raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php

      restart_ldnmp


      clear
      echo "您的苹果CMS搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库地址: mysql"
      echo "数据库端口: 3306"
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "数据库前缀: mac_"
      echo "------------------------"
      echo "安装成功后登录后台地址"
      echo "https://$yuming/vip.php"
      nginx_status
        ;;

      6)
      clear
      # 独脚数卡
      add_yuming
      install_ssltls
      add_db

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf

      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget https://github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

      restart_ldnmp


      clear
      echo "您的独角数卡网站搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库地址: mysql"
      echo "数据库端口: 3306"
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo ""
      echo "redis地址: redis"
      echo "redis密码: 默认不填写"
      echo "redis端口: 6379"
      echo ""
      echo "网站url: https://$yuming"
      echo "后台登录路径: /admin"
      echo "------------------------"
      echo "用户名: admin"
      echo "密码: admin"
      echo "------------------------"
      echo "登录时右上角如果出现红色error0请使用如下命令: "
      echo "我也很气愤独角数卡为啥这么麻烦，会有这样的问题！"
      echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"
      nginx_status
        ;;

      7)
      clear
      # BingChat
      add_yuming
      install_ssltls

      docker run -d -p 3099:8080 --name go-proxy-bingai --restart=unless-stopped adams549659584/go-proxy-bingai
      duankou=3099
      reverse_proxy

      clear
      echo "您的BingChat网站搭建好了！"
      echo "https://$yuming"
      nginx_status
        ;;

      8)
      clear
      # flarum论坛
      add_yuming
      install_ssltls
      add_db

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming

      docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
      docker exec php sh -c "php composer-setup.php"
      docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
      docker exec php sh -c "mv composer.phar /usr/local/bin/composer"

      docker exec php composer create-project flarum/flarum /var/www/html/$yuming
      docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
      docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"

      restart_ldnmp


      clear
      echo "您的flarum论坛网站搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库地址: mysql"
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "表前缀: flarum_"
      echo "管理员信息自行设置"
      nginx_status
        ;;

      9)
      clear
      # Bitwarden
      add_yuming
      install_ssltls

      docker run -d \
        --name bitwarden \
        --restart always \
        -p 3280:80 \
        -v /home/web/html/$yuming/bitwarden/data:/data \
        vaultwarden/server
      duankou=3280
      reverse_proxy

      clear
      echo "您的Bitwarden网站搭建好了！"
      echo "https://$yuming"
      nginx_status
        ;;

      10)
      clear
      # halo
      add_yuming
      install_ssltls

      docker run -d --name halo --restart always --network web_default -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2.9
      duankou=8010
      reverse_proxy

      clear
      echo "您的Halo网站搭建好了！"
      echo "https://$yuming"
      nginx_status
        ;;

      11)
      clear
      # typecho
      add_yuming
      install_ssltls
      add_db

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget -O latest.zip https://github.com/typecho/typecho/releases/latest/download/typecho.zip
      unzip latest.zip
      rm latest.zip

      restart_ldnmp


      clear
      echo "您的typecho搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库前缀: typecho_"
      echo "数据库地址: mysql"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "数据库名: $dbname"
      nginx_status
        ;;



      12)
      clear
        echo -e "${red}很抱歉，该模块正在开发中${re}"
        sleep 2
        main_menu
      ;;


      13)
      clear
        echo -e "${red}很抱歉，该模块正在开发中${re}"
        sleep 2
        main_menu

      ;;

      13)
      clear
        echo -e "${red}很抱歉，该模块正在开发中${re}"
        sleep 2
        main_menu

      ;;

      14)
      clear
        echo -e "${red}很抱歉，该模块正在开发中${re}"
        sleep 2
        main_menu

      ;;

      15)
      clear
        echo -e "${red}很抱歉，该模块正在开发中${re}"
        sleep 2
        main_menu

      ;;



      21)
      check_port
      install_dependency
      install_docker
      install_certbot

      cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml

      wget -O /home/web/nginx.conf https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
      wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/kejilion/nginx/main/default10.conf
      default_server_ssl
      docker rm -f nginx >/dev/null 2>&1
      docker rmi nginx >/dev/null 2>&1
      docker run -d --name nginx --restart always -p 80:80 -p 443:443 -v /home/web/nginx.conf:/etc/nginx/nginx.conf -v /home/web/conf.d:/etc/nginx/conf.d -v /home/web/certs:/etc/nginx/certs -v /home/web/html:/var/www/html -v /home/web/log/nginx:/var/log/nginx nginx

      clear
      nginx_version=$(docker exec nginx nginx -v 2>&1)
      nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
      echo "nginx已安装完成"
      echo "当前版本: v$nginx_version"
      echo ""
        ;;

      22)
      clear
      ip_address
      echo -e "先将域名解析到本机IP: \033[33m$ipv4_address\033[0m"
      read -p "请输入你的域名: " yuming
      read -p "请输入跳转域名: " reverseproxy

      install_ssltls

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
      sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf

      docker restart nginx

      clear
      echo "您的重定向网站做好了！"
      echo "https://$yuming"
      nginx_status

        ;;

      23)
      clear
      ip_address
      echo -e "先将域名解析到本机IP: \033[33m$ipv4_address\033[0m"
      read -p "请输入你的域名: " yuming
      read -p "请输入你的反代IP: " reverseproxy
      read -p "请输入你的反代端口: " port

      install_ssltls

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0.0.0.0/$reverseproxy/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0000/$port/g" /home/web/conf.d/$yuming.conf

      docker restart nginx

      clear
      echo "您的反向代理网站做好了！"
      echo "https://$yuming"
      nginx_status
        ;;

      24)
      clear
      # 静态界面
      add_yuming
      install_ssltls

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/html.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming

      install lrzsz
      clear
      echo -e "目前只允许上传\033[33mindex.html\033[0m文件，请提前准备好，按任意键继续..."
      read -n 1 -s -r -p ""
      rz

      docker exec nginx chmod -R 777 /var/www/html
      docker restart nginx

      clear
      echo "您的静态网站搭建好了！"
      echo "https://$yuming"
      nginx_status
        ;;

    31)
    while true; do
        clear
        echo "LDNMP环境"
        echo "------------------------"
        # 获取nginx版本
        nginx_version=$(docker exec nginx nginx -v 2>&1)
        nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
        echo -n "nginx : v$nginx_version"
        # 获取mysql版本
        dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
        mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
        echo -n "            mysql : v$mysql_version"
        # 获取php版本
        php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
        echo -n "            php : v$php_version"
        # 获取redis版本
        redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
        echo "            redis : v$redis_version"
        echo "------------------------"
        echo ""


        # ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
        echo "站点信息                      证书到期时间"
        echo "------------------------"
        for cert_file in /home/web/certs/*_cert.pem; do
          domain=$(basename "$cert_file" | sed 's/_cert.pem//')
          if [ -n "$domain" ]; then
            expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
            formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
            printf "%-30s%s\n" "$domain" "$formatted_date"
          fi
        done

        echo "------------------------"
        echo ""
        echo "数据库信息"
        echo "------------------------"
        dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
        docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

        echo "------------------------"
        echo ""
        echo "操作"
        echo "------------------------"
        echo "1. 申请/更新域名证书               2. 更换站点域名"
        echo -e "3. 清理站点缓存                    4. 查看站点分析报告 \033[33mNEW\033[0m"
        echo "------------------------"
        echo "7. 删除指定站点                    8. 删除指定数据库"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
        case $sub_choice in
            1)
                read -p "请输入你的域名: " yuming
                install_ssltls

                ;;

            2)
                read -p "请输入旧域名: " oddyuming
                read -p "请输入新域名: " yuming
                mv /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
                sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf
                mv /home/web/html/$oddyuming /home/web/html/$yuming

                rm /home/web/certs/${oddyuming}_key.pem
                rm /home/web/certs/${oddyuming}_cert.pem
                install_ssltls

                ;;


            3)
                docker exec -it nginx rm -rf /var/cache/nginx
                docker restart nginx
                ;;
            4)
                install goaccess
                goaccess --log-format=COMBINED /home/web/log/nginx/access.log

                ;;

            7)
                read -p "请输入你的域名: " yuming
                rm -r /home/web/html/$yuming
                rm /home/web/conf.d/$yuming.conf
                rm /home/web/certs/${yuming}_key.pem
                rm /home/web/certs/${yuming}_cert.pem
                docker restart nginx
                ;;
            8)
                read -p "请输入数据库名: " shujuku
                dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
                docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $shujuku;" 2> /dev/null
                ;;
            0)
                break  # 跳出循环，退出菜单
                ;;
            *)
                break  # 跳出循环，退出菜单
                ;;
        esac
    done

      ;;


    32)
      clear
      cd /home/ && tar czvf web_$(date +"%Y%m%d%H%M%S").tar.gz web

      while true; do
        clear
        read -p "要传送文件到远程服务器吗？(Y/N): " choice
        case "$choice" in
          [Yy])
            read -p "请输入远端服务器IP:  " remote_ip
            if [ -z "$remote_ip" ]; then
              echo "错误: 请输入远端服务器IP。"
              continue
            fi
            latest_tar=$(ls -t /home/*.tar.gz | head -1)
            if [ -n "$latest_tar" ]; then
              ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
              sleep 2  # 添加等待时间
              scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
              echo "文件已传送至远程服务器home目录。"
            else
              echo "未找到要传送的文件。"
            fi
            break
            ;;
          [Nn])
            break
            ;;
          *)
            echo "无效的选择，请输入 Y 或 N。"
            ;;
        esac
      done
      ;;

    33)
      clear
      read -p "输入远程服务器IP: " useip
      read -p "输入远程服务器密码: " usepasswd

      wget -O ${useip}_beifen.sh https://raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
      chmod +x ${useip}_beifen.sh

      sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
      sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

      echo "------------------------"
      echo "1. 每周备份                 2. 每天备份"
      read -p $'\033[1;91m请输入你的选择: \033[0m' dingshi

      case $dingshi in
          1)
              read -p "选择每周备份的星期几 (0-6，0代表星期日): " weekday
              (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
              ;;
          2)
              read -p "选择每天备份的时间（小时，0-23）: " hour
              (crontab -l ; echo "0 $hour * * * ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
              ;;
          *)
              break  # 跳出
              ;;
      esac

      install sshpass

      ;;

    34)
      clear
      cd /home/ && ls -t /home/*.tar.gz | head -1 | xargs -I {} tar -xzf {}
      check_port
      install_dependency
      install_docker
      install_certbot
      install_ldnmp

      ;;

    35)
      if [ -x "$(command -v fail2ban-client)" ] && [ -d "/etc/fail2ban" ]; then
          while true; do
              clear
              echo "服务器防御程序已启动"
              echo "------------------------"
              echo "1. 开启SSH防暴力破解              2. 关闭SSH防暴力破解"
              echo "3. 开启网站保护                   4. 关闭网站保护"
              echo "------------------------"
              echo "5. 查看SSH拦截记录                6. 查看网站拦截记录"
              echo "7. 查看防御规则列表               8. 查看日志实时监控"
              echo "------------------------"
              echo "9. 卸载防御程序"
              echo "------------------------"
              echo "0. 退出"
              echo "------------------------"
              read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
              case $sub_choice in
                  1)
                      sed -i 's/false/true/g' /etc/fail2ban/jail.d/sshd.local
                      systemctl restart fail2ban
                      sleep 1
                      fail2ban-client status
                      ;;
                  2)
                      sed -i 's/true/false/g' /etc/fail2ban/jail.d/sshd.local
                      systemctl restart fail2ban
                      sleep 1
                      fail2ban-client status
                      ;;
                  3)
                      sed -i 's/false/true/g' /etc/fail2ban/jail.d/nginx.local
                      systemctl restart fail2ban
                      sleep 1
                      fail2ban-client status
                      ;;
                  4)
                      sed -i 's/true/false/g' /etc/fail2ban/jail.d/nginx.local
                      systemctl restart fail2ban
                      sleep 1
                      fail2ban-client status
                      ;;
                  5)
                      echo "------------------------"
                      fail2ban-client status sshd
                      echo "------------------------"
                      ;;
                  6)
                      echo "------------------------"
                      fail2ban-client status nginx-bad-request
                      echo "------------------------"
                      fail2ban-client status nginx-botsearch
                      echo "------------------------"
                      fail2ban-client status nginx-http-auth
                      echo "------------------------"
                      fail2ban-client status nginx-limit-req
                      echo "------------------------"
                      fail2ban-client status php-url-fopen
                      echo "------------------------"
                      ;;

                  7)
                      fail2ban-client status
                      ;;
                  8)
                      tail -f /var/log/fail2ban.log

                      ;;
                  9)
                      remove fail2ban
                      break
                      ;;
                  0)
                      break
                      ;;
                  *)
                      echo "无效的选择，请重新输入。"
                      ;;
              esac
              break_end

          done
      else
          clear
          # 安装Fail2ban
          if [ -f /etc/debian_version ]; then
              # Debian/Ubuntu系统
              install fail2ban
          elif [ -f /etc/redhat-release ]; then
              # CentOS系统
              install epel-release fail2ban
          else
              echo "不支持的操作系统类型"
              exit 1
          fi

          # 启动Fail2ban
          systemctl start fail2ban

          # 设置Fail2ban开机自启
          systemctl enable fail2ban

          # 配置Fail2ban
          rm -rf /etc/fail2ban/jail.d/*
          cd /etc/fail2ban/jail.d/
          curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/sshd.local
          systemctl restart fail2ban
          docker rm -f nginx

          wget -O /home/web/nginx.conf https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
          wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/kejilion/nginx/main/default10.conf
          default_server_ssl
          docker run -d --name nginx --restart always --network web_default -p 80:80 -p 443:443 -v /home/web/nginx.conf:/etc/nginx/nginx.conf -v /home/web/conf.d:/etc/nginx/conf.d -v /home/web/certs:/etc/nginx/certs -v /home/web/html:/var/www/html -v /home/web/log/nginx:/var/log/nginx nginx
          docker exec -it nginx chmod -R 777 /var/www/html

          # 获取宿主机当前时区
          HOST_TIMEZONE=$(timedatectl show --property=Timezone --value)

          # 调整多个容器的时区
          docker exec -it nginx ln -sf "/usr/share/zoneinfo/$HOST_TIMEZONE" /etc/localtime
          docker exec -it php ln -sf "/usr/share/zoneinfo/$HOST_TIMEZONE" /etc/localtime
          docker exec -it php74 ln -sf "/usr/share/zoneinfo/$HOST_TIMEZONE" /etc/localtime
          docker exec -it mysql ln -sf "/usr/share/zoneinfo/$HOST_TIMEZONE" /etc/localtime
          docker exec -it redis ln -sf "/usr/share/zoneinfo/$HOST_TIMEZONE" /etc/localtime
          rm -rf /home/web/log/nginx/*
          docker restart nginx

          curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/nginx.local
          systemctl restart fail2ban
          sleep 1
          fail2ban-client status
          echo "防御程序已开启"
      fi

        ;;

    36)
          while true; do
              clear
              echo "优化LDNMP环境"
              echo "------------------------"
              echo "1. 标准模式              2. 高性能模式 (推荐2H2G以上)"
              echo "------------------------"
              echo "0. 退出"
              echo "------------------------"
              read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
              case $sub_choice in
                  1)
                  # nginx调优
                  sed -i 's/worker_connections.*/worker_connections 1024;/' /home/web/nginx.conf

                  # php调优
                  wget -O /home/www.conf https://raw.githubusercontent.com/kejilion/sh/main/www-1.conf
                  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
                  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
                  rm -rf /home/www.conf

                  # mysql调优
                  wget -O /home/custom_mysql_config.cnf https://raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
                  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
                  rm -rf /home/custom_mysql_config.cnf

                  docker restart nginx
                  docker restart php
                  docker restart php74
                  docker restart mysql

                  echo "LDNMP环境已设置成 标准模式"

                      ;;
                  2)

                  # nginx调优
                  sed -i 's/worker_connections.*/worker_connections 131072;/' /home/web/nginx.conf

                  # php调优
                  wget -O /home/www.conf https://raw.githubusercontent.com/kejilion/sh/main/www.conf
                  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
                  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
                  rm -rf /home/www.conf

                  # mysql调优
                  wget -O /home/custom_mysql_config.cnf https://raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
                  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
                  rm -rf /home/custom_mysql_config.cnf

                  docker restart nginx
                  docker restart php
                  docker restart php74
                  docker restart mysql

                  echo "LDNMP环境已设置成 高性能模式"

                      ;;
                  0)
                      break
                      ;;
                  *)
                      echo "无效的选择，请重新输入。"
                      ;;
              esac
              break_end

          done
        ;;


    37)
      clear
      docker rm -f nginx php php74 mysql redis
      docker rmi nginx php:fpm php:7.4.33-fpm mysql redis

      check_port
      install_dependency
      install_docker
      install_certbot
      install_ldnmp
      ;;



    38)
        clear
        read -p "强烈建议先备份全部网站数据，再卸载LDNMP环境。确定删除所有网站数据吗？(Y/N): " choice
        case "$choice" in
          [Yy])
            docker rm -f nginx php php74 mysql redis
            docker rmi nginx php:fpm php:7.4.33-fpm mysql redis
            rm -r /home/web
            ;;
          [Nn])

            ;;
          *)
            echo "无效的选择，请输入 Y 或 N。"
            ;;
        esac
        ;;

    0)
        main_menu
      ;;

    *)
        echo "无效的输入!"
    esac
    break_end

    done
    ;;


  9)
    while true; do
      clear
      echo "▶ 面板工具"
      echo "------------------------"
      echo " 1. 宝塔面板官方版                        2. aaPanel宝塔国际版"
      echo " 3. 1Panel新一代管理面板                  4. NginxProxyManager可视化面板"
      echo " 5. AList多存储文件列表程序               6. Ubuntu远程桌面网页版"
      echo " 7. 哪吒探针VPS监控面板                   8. QB离线BT磁力下载面板"
      echo " 9. Poste.io邮件服务器程序               10. RocketChat多人在线聊天系统"
      echo "11. 禅道项目管理软件                     12. 青龙面板定时任务管理平台"
      echo "13. Cloudreve网盘系统                    14. 简单图床图片管理程序"
      echo "15. emby多媒体管理系统                   16. Speedtest测速服务面板"
      echo "17. AdGuardHome去广告软件                18. onlyoffice在线办公OFFICE"
      echo "19. 雷池WAF防火墙面板                    20. portainer容器管理面板"
      echo "21. VScode网页版                         22. UptimeKuma监控工具"
      echo "23. Memos网页备忘录                      24. pandoranext潘多拉GPT镜像站"
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
            if [ -f "/etc/init.d/bt" ] && [ -d "/www/server/panel" ]; then
                clear
                echo "宝塔面板已安装，应用操作"
                echo ""
                echo "------------------------"
                echo "1. 管理宝塔面板           2. 卸载宝塔面板"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        # 更新宝塔面板操作
                        bt
                        ;;
                    2)
                        clear
                        curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1
                        chmod +x bt-uninstall.sh
                        ./bt-uninstall.sh
                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                        ;;
                    *)
                        break  # 跳出循环，退出菜单
                        ;;
                esac
            else
                clear
                echo "安装提示"
                echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装宝塔面板！"
                echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
                echo "官网介绍: https://www.bt.cn/new/index.html"
                echo ""

                # 获取当前系统类型
                get_system_type() {
                    if [ -f /etc/os-release ]; then
                        . /etc/os-release
                        if [ "$ID" == "centos" ]; then
                            echo "centos"
                        elif [ "$ID" == "ubuntu" ]; then
                            echo "ubuntu"
                        elif [ "$ID" == "debian" ]; then
                            echo "debian"
                        else
                            echo "unknown"
                        fi
                    else
                        echo "unknown"
                    fi
                }

                system_type=$(get_system_type)

                if [ "$system_type" == "unknown" ]; then
                    echo "不支持的操作系统类型"
                else
                    read -p "确定安装宝塔吗？(Y/N): " choice
                    case "$choice" in
                        [Yy])
                            iptables_open
                            install wget
                            if [ "$system_type" == "centos" ]; then
                                yum install -y wget && wget -O install.sh https://download.bt.cn/install/install_6.0.sh && sh install.sh ed8484bec
                            elif [ "$system_type" == "ubuntu" ]; then
                                wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && bash install.sh ed8484bec
                            elif [ "$system_type" == "debian" ]; then
                                wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh && bash install.sh ed8484bec
                            fi
                            ;;
                        [Nn])
                            ;;
                        *)
                            ;;
                    esac
                fi
            fi

              ;;
          2)
            if [ -f "/etc/init.d/bt" ] && [ -d "/www/server/panel" ]; then
                clear
                echo "aaPanel已安装，应用操作"
                echo ""
                echo "------------------------"
                echo "1. 管理aaPanel           2. 卸载aaPanel"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        # 更新aaPanel操作
                        bt
                        ;;
                    2)
                        clear
                        curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1
                        chmod +x bt-uninstall.sh
                        ./bt-uninstall.sh
                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                        ;;
                    *)
                        break  # 跳出循环，退出菜单
                        ;;
                esac
            else
                clear
                echo "安装提示"
                echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装aaPanel！"
                echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
                echo "官网介绍: https://www.aapanel.com/new/index.html"
                echo ""

                # 获取当前系统类型
                get_system_type() {
                    if [ -f /etc/os-release ]; then
                        . /etc/os-release
                        if [ "$ID" == "centos" ]; then
                            echo "centos"
                        elif [ "$ID" == "ubuntu" ]; then
                            echo "ubuntu"
                        elif [ "$ID" == "debian" ]; then
                            echo "debian"
                        else
                            echo "unknown"
                        fi
                    else
                        echo "unknown"
                    fi
                }

                system_type=$(get_system_type)

                if [ "$system_type" == "unknown" ]; then
                    echo "不支持的操作系统类型"
                else
                    read -p "确定安装aaPanel吗？(Y/N): " choice
                    case "$choice" in
                        [Yy])
                            iptables_open
                            install wget
                            if [ "$system_type" == "centos" ]; then
                                yum install -y wget && wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh && bash install.sh aapanel
                            elif [ "$system_type" == "ubuntu" ]; then
                                wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
                            elif [ "$system_type" == "debian" ]; then
                                wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh && bash install.sh aapanel
                            fi
                            ;;
                        [Nn])
                            ;;
                        *)
                            ;;
                    esac
                fi
            fi
              ;;
          3)
            if command -v 1pctl &> /dev/null; then
                clear
                echo "1Panel已安装，应用操作"
                echo ""
                echo "------------------------"
                echo "1. 查看1Panel信息           2. 卸载1Panel"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        1pctl user-info
                        1pctl update password
                        ;;
                    2)
                        clear
                        1pctl uninstall

                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                        ;;
                    *)
                        break  # 跳出循环，退出菜单
                        ;;
                esac
            else

                clear
                echo "安装提示"
                echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装1Panel！"
                echo "会根据系统自动安装，支持Debian，Ubuntu，Centos"
                echo "官网介绍: https://1panel.cn/"
                echo ""
                # 获取当前系统类型
                get_system_type() {
                  if [ -f /etc/os-release ]; then
                    . /etc/os-release
                    if [ "$ID" == "centos" ]; then
                      echo "centos"
                    elif [ "$ID" == "ubuntu" ]; then
                      echo "ubuntu"
                    elif [ "$ID" == "debian" ]; then
                      echo "debian"
                    else
                      echo "unknown"
                    fi
                  else
                    echo "unknown"
                  fi
                }

                system_type=$(get_system_type)

                if [ "$system_type" == "unknown" ]; then
                  echo "不支持的操作系统类型"
                else
                  read -p "确定安装1Panel吗？(Y/N): " choice
                  case "$choice" in
                    [Yy])
                      iptables_open
                      install_docker
                      if [ "$system_type" == "centos" ]; then
                        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && sh quick_start.sh
                      elif [ "$system_type" == "ubuntu" ]; then
                        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
                      elif [ "$system_type" == "debian" ]; then
                        curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
                      fi
                      ;;
                    [Nn])
                      ;;
                    *)
                      ;;
                  esac
                fi
            fi


              ;;
          4)

            docker_name="npm"
            docker_img="jc21/nginx-proxy-manager:latest"
            docker_port=81
            docker_rum="docker run -d \
                          --name=$docker_name \
                          -p 80:80 \
                          -p 81:$docker_port \
                          -p 443:443 \
                          -v /home/docker/npm/data:/data \
                          -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
                          --restart=always \
                          $docker_img"
            docker_describe="如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装npm！"
            docker_url="官网介绍: https://nginxproxymanager.com/"
            docker_use="echo \"初始用户名: admin@example.com\""
            docker_passwd="echo \"初始密码: changeme\""

            docker_app

              ;;

          5)

            docker_name="alist"
            docker_img="xhofe/alist:latest"
            docker_port=5244
            docker_rum="docker run -d \
                                --restart=always \
                                -v /home/docker/alist:/opt/alist/data \
                                -p 5244:5244 \
                                -e PUID=0 \
                                -e PGID=0 \
                                -e UMASK=022 \
                                --name="alist" \
                                xhofe/alist:latest"
            docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
            docker_url="官网介绍: https://alist.nn.ci/zh/"
            docker_use="docker exec -it alist ./alist admin random"
            docker_passwd=""

            docker_app

              ;;

          6)
            docker_name="ubuntu-novnc"
            docker_img="fredblgr/ubuntu-novnc:20.04"
            docker_port=6080
            rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
            docker_rum="docker run -d \
                                --name ubuntu-novnc \
                                -p 6080:80 \
                                -v /home/docker/ubuntu-novnc:/workspace:rw \
                                -e HTTP_PASSWORD=$rootpasswd \
                                -e RESOLUTION=1280x720 \
                                --restart=always \
                                fredblgr/ubuntu-novnc:20.04"
            docker_describe="一个网页版Ubuntu远程桌面，挺好用的！"
            docker_url="官网介绍: https://hub.docker.com/r/fredblgr/ubuntu-novnc"
            docker_use="echo \"用户名: root\""
            docker_passwd="echo \"密码: $rootpasswd\""

            docker_app

              ;;
          7)
            clear
            curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh  -o nezha.sh && chmod +x nezha.sh
            ./nezha.sh
              ;;

          8)

            docker_name="qbittorrent"
            docker_img="lscr.io/linuxserver/qbittorrent:latest"
            docker_port=8081
            docker_rum="docker run -d \
                                  --name=qbittorrent \
                                  -e PUID=1000 \
                                  -e PGID=1000 \
                                  -e TZ=Etc/UTC \
                                  -e WEBUI_PORT=8081 \
                                  -p 8081:8081 \
                                  -p 6881:6881 \
                                  -p 6881:6881/udp \
                                  -v /home/docker/qbittorrent/config:/config \
                                  -v /home/docker/qbittorrent/downloads:/downloads \
                                  --restart unless-stopped \
                                  lscr.io/linuxserver/qbittorrent:latest"
            docker_describe="qbittorrent离线BT磁力下载服务"
            docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
            docker_use="sleep 3"
            docker_passwd="docker logs qbittorrent"

            docker_app

              ;;

          9)
            if docker inspect mailserver &>/dev/null; then

                    clear
                    echo "poste.io已安装，访问地址: "
                    yuming=$(cat /home/docker/mail.txt)
                    echo "https://$yuming"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f mailserver
                            docker rmi -f analogic/poste.io
                            install_docker
                            yuming=$(cat /home/docker/mail.txt)
                            docker run \
                                --net=host \
                                -e TZ=Europe/Prague \
                                -v /home/docker/mail:/data \
                                --name "mailserver" \
                                -h "$yuming" \
                                --restart=always \
                                -d analogic/poste.io

                            clear
                            echo "poste.io已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问poste.io:"
                            echo "https://$yuming"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f mailserver
                            docker rmi -f analogic/poste.io
                            rm /home/docker/mail.txt
                            rm -rf /home/docker/mail
                            echo "应用已卸载"
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                install telnet

                clear
                echo ""
                echo "端口检测"
                port=25
                timeout=3

                if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
                  echo -e "\e[32m端口$port当前可用\e[0m"
                else
                  echo -e "\e[31m端口$port当前不可用\e[0m"
                fi
                echo "------------------------"
                echo ""


                echo "安装提示"
                echo "poste.io一个邮件服务器，确保80和443端口没被占用，确保25端口开放"
                echo "官网介绍: https://hub.docker.com/r/analogic/poste.io"
                echo ""

                # 提示用户确认安装
                read -p "确定安装poste.io吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear

                    read -p "请设置邮箱域名 例如 mail.yuming.com : " yuming
                    mkdir -p /home/docker      # 递归创建目录
                    echo "$yuming" > /home/docker/mail.txt  # 写入文件
                    echo "------------------------"
                    ip_address
                    echo "先解析这些DNS记录"
                    echo "A           mail            $ipv4_address"
                    echo "CNAME       imap            $yuming"
                    echo "CNAME       pop             $yuming"
                    echo "CNAME       smtp            $yuming"
                    echo "MX          @               $yuming"
                    echo "TXT         @               v=spf1 mx ~all"
                    echo "TXT         ?               ?"
                    echo ""
                    echo "------------------------"
                    echo "按任意键继续..."
                    read -n 1 -s -r -p ""

                    install_docker

                    docker run \
                        --net=host \
                        -e TZ=Europe/Prague \
                        -v /home/docker/mail:/data \
                        --name "mailserver" \
                        -h "$yuming" \
                        --restart=always \
                        -d analogic/poste.io

                    clear
                    echo "poste.io已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问poste.io:"
                    echo "https://$yuming"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;

          10)
            if docker inspect rocketchat &>/dev/null; then


                    clear
                    echo "rocket.chat已安装，访问地址: "
                    ip_address
                    echo "http:$ipv4_address:3897"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f rocketchat
                            docker rmi -f rocket.chat:6.3
                            install_docker

                            docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

                            clear
                            ip_address
                            echo "rocket.chat已经安装完成"
                            echo "------------------------"
                            echo "多等一会，您可以使用以下地址访问rocket.chat:"
                            echo "http:$ipv4_address:3897"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f rocketchat
                            docker rmi -f rocket.chat
                            docker rmi -f rocket.chat:6.3
                            docker rm -f db
                            docker rmi -f mongo:latest
                            # docker rmi -f mongo:6
                            rm -rf /home/docker/mongo
                            echo "应用已卸载"
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                echo "安装提示"
                echo "rocket.chat国外知名开源多人聊天系统"
                echo "官网介绍: https://www.rocket.chat"
                echo ""

                # 提示用户确认安装
                read -p "确定安装rocket.chat吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run --name db -d --restart=always \
                        -v /home/docker/mongo/dump:/dump \
                        mongo:latest --replSet rs5 --oplogSize 256
                    sleep 1
                    docker exec -it db mongosh --eval "printjson(rs.initiate())"
                    sleep 5
                    docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat:6.3

                    clear

                    ip_address
                    echo "rocket.chat已经安装完成"
                    echo "------------------------"
                    echo "多等一会，您可以使用以下地址访问rocket.chat:"
                    echo "http:$ipv4_address:3897"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;



          11)
            docker_name="zentao-server"
            docker_img="idoop/zentao:latest"
            docker_port=82
            docker_rum="docker run -d -p 82:80 -p 3308:3306 \
                              -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
                              -e BIND_ADDRESS="false" \
                              -v /home/docker/zentao-server/:/opt/zbox/ \
                              --add-host smtp.exmail.qq.com:163.177.90.125 \
                              --name zentao-server \
                              --restart=always \
                              idoop/zentao:latest"
            docker_describe="禅道是通用的项目管理软件"
            docker_url="官网介绍: https://www.zentao.net/"
            docker_use="echo \"初始用户名: admin\""
            docker_passwd="echo \"初始密码: 123456\""
            docker_app

              ;;

          12)
            docker_name="qinglong"
            docker_img="whyour/qinglong:latest"
            docker_port=5700
            docker_rum="docker run -d \
                      -v /home/docker/qinglong/data:/ql/data \
                      -p 5700:5700 \
                      --name qinglong \
                      --hostname qinglong \
                      --restart unless-stopped \
                      whyour/qinglong:latest"
            docker_describe="青龙面板是一个定时任务管理平台"
            docker_url="官网介绍: https://github.com/whyour/qinglong"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;
          13)
            if docker inspect cloudreve &>/dev/null; then

                    clear
                    echo "cloudreve已安装，访问地址: "
                    ip_address
                    echo "http:$ipv4_address:5212"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f cloudreve
                            docker rmi -f cloudreve/cloudreve:latest
                            docker rm -f aria2
                            docker rmi -f p3terx/aria2-pro
                            install_docker
                            cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
                            curl -o /home/docker/cloud/docker-compose.yml https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
                            cd /home/docker/cloud/ && docker-compose up -d


                            clear
                            echo "cloudreve已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问cloudreve:"
                            ip_address
                            echo "http:$ipv4_address:5212"
                            sleep 3
                            docker logs cloudreve
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f cloudreve
                            docker rmi -f cloudreve/cloudreve:latest
                            docker rm -f aria2
                            docker rmi -f p3terx/aria2-pro
                            rm -rf /home/docker/cloud
                            echo "应用已卸载"
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                echo "安装提示"
                echo "cloudreve是一个支持多家云存储的网盘系统"
                echo "官网介绍: https://cloudreve.org/"
                echo ""

                # 提示用户确认安装
                read -p "确定安装cloudreve吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
                    curl -o /home/docker/cloud/docker-compose.yml https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
                    cd /home/docker/cloud/ && docker-compose up -d


                    clear
                    echo "cloudreve已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问cloudreve:"
                    ip_address
                    echo "http:$ipv4_address:5212"
                    sleep 3
                    docker logs cloudreve
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;

          14)
            docker_name="easyimage"
            docker_img="ddsderek/easyimage:latest"
            docker_port=85
            docker_rum="docker run -d \
                      --name easyimage \
                      -p 85:80 \
                      -e TZ=Asia/Shanghai \
                      -e PUID=1000 \
                      -e PGID=1000 \
                      -v /home/docker/easyimage/config:/app/web/config \
                      -v /home/docker/easyimage/i:/app/web/i \
                      --restart unless-stopped \
                      ddsderek/easyimage:latest"
            docker_describe="简单图床是一个简单的图床程序"
            docker_url="官网介绍: https://github.com/icret/EasyImages2.0"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          15)
            docker_name="emby"
            docker_img="linuxserver/emby:latest"
            docker_port=8096
            docker_rum="docker run -d --name=emby --restart=always \
                        -v /homeo/docker/emby/config:/config \
                        -v /homeo/docker/emby/share1:/mnt/share1 \
                        -v /homeo/docker/emby/share2:/mnt/share2 \
                        -v /mnt/notify:/mnt/notify \
                        -p 8096:8096 -p 8920:8920 \
                        -e UID=1000 -e GID=100 -e GIDLIST=100 \
                        linuxserver/emby:latest"
            docker_describe="emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
            docker_url="官网介绍: https://emby.media/"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          16)
            docker_name="looking-glass"
            docker_img="wikihostinc/looking-glass-server"
            docker_port=89
            docker_rum="docker run -d --name looking-glass --restart always -p 89:80 wikihostinc/looking-glass-server"
            docker_describe="Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
            docker_url="官网介绍: https://github.com/wikihost-opensource/als"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;
          17)

            docker_name="adguardhome"
            docker_img="adguard/adguardhome"
            docker_port=3000
            docker_rum="docker run -d \
                            --name adguardhome \
                            -v /home/docker/adguardhome/work:/opt/adguardhome/work \
                            -v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
                            -p 53:53/tcp \
                            -p 53:53/udp \
                            -p 3000:3000/tcp \
                            --restart always \
                            adguard/adguardhome"
            docker_describe="AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
            docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;


          18)

            docker_name="onlyoffice"
            docker_img="onlyoffice/documentserver"
            docker_port=8082
            docker_rum="docker run -d -p 8082:80 \
                        --restart=always \
                        --name onlyoffice \
                        -v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
                        -v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
                         onlyoffice/documentserver"
            docker_describe="onlyoffice是一款开源的在线office工具，太强大了！"
            docker_url="官网介绍: https://www.onlyoffice.com/"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;

          19)

            if docker inspect safeline-tengine &>/dev/null; then

                    clear
                    echo "雷池已安装，访问地址: "
                    ip_address
                    echo "http:$ipv4_address:9443"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                    case $sub_choice in
                        1)
                            clear
                            echo "暂不支持"
                            echo ""
                            ;;
                        2)

                            clear
                            echo "cd命令到安装目录下执行: docker compose down"
                            echo ""
                            ;;
                        0)
                            break  # 跳出循环，退出菜单
                            ;;
                        *)
                            break  # 跳出循环，退出菜单
                            ;;
                    esac
            else
                clear
                echo "安装提示"
                echo "雷池是长亭科技开发的WAF站点防火墙程序面板，可以反代站点进行自动化防御"
                echo "80和443端口不能被占用，无法与宝塔，1panel，npm，ldnmp建站共存"
                echo "官网介绍: https://github.com/chaitin/safeline"
                echo ""

                # 提示用户确认安装
                read -p "确定安装吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

                    clear
                    echo "雷池WAF面板已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问:"
                    ip_address
                    echo "http:$ipv4_address:9443"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;

          20)
            docker_name="portainer"
            docker_img="portainer/portainer"
            docker_port=9050
            docker_rum="docker run -d \
                    --name portainer \
                    -p 9050:9000 \
                    -v /var/run/docker.sock:/var/run/docker.sock \
                    -v /home/docker/portainer:/data \
                    --restart always \
                    portainer/portainer"
            docker_describe="portainer是一个轻量级的docker容器管理面板"
            docker_url="官网介绍: https://www.portainer.io/"
            docker_use=""
            docker_passwd=""
            docker_app

              ;;

          21)
            docker_name="vscode-web"
            docker_img="codercom/code-server"
            docker_port=8180
            docker_rum="docker run -d -p 8180:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart always codercom/code-server"
            docker_describe="VScode是一款强大的在线代码编写工具"
            docker_url="官网介绍: https://github.com/coder/code-server"
            docker_use="sleep 3"
            docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
            docker_app
              ;;
          22)
            docker_name="uptime-kuma"
            docker_img="louislam/uptime-kuma:latest"
            docker_port=3003
            docker_rum="docker run -d \
                            --name=uptime-kuma \
                            -p 3003:3001 \
                            -v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
                            --restart=always \
                            louislam/uptime-kuma:latest"
            docker_describe="Uptime Kuma 易于使用的自托管监控工具"
            docker_url="官网介绍: https://github.com/louislam/uptime-kuma"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          23)
            docker_name="memos"
            docker_img="ghcr.io/usememos/memos:latest"
            docker_port=5230
            docker_rum="docker run -d --name memos -p 5230:5230 -v /home/docker/memos:/var/opt/memos --restart always ghcr.io/usememos/memos:latest"
            docker_describe="Memos是一款轻量级、自托管的备忘录中心"
            docker_url="官网介绍: https://github.com/usememos/memos"
            docker_use=""
            docker_passwd=""
            docker_app
              ;;

          24)

            docker_name="PandoraNext"
            docker_img="pengzhile/pandora-next"
            docker_port=8181
            docker_rum="docker run -d --restart always --name PandoraNext \
                            -p 8181:8181 \
                            -v /home/docker/PandoraNext/data:/data \
                            -v /home/docker/PandoraNext/sessions:/root/.cache/PandoraNext \
                            pengzhile/pandora-next"
            docker_describe="pandora-next一个好用的GPT镜像站服务，国内也可以访问"
            docker_url="官网介绍: https://github.com/pandora-next/deploy"


            if docker inspect "$docker_name" &>/dev/null; then
                clear
                echo "$docker_name 已安装，访问地址: "
                ip_address
                echo "http:$ipv4_address:$docker_port"
                echo ""
                echo "应用操作"
                echo "------------------------"
                echo "1. 更新应用             2. 卸载应用"
                echo "3. 修改config           4. 修改tokens"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        docker rm -f "$docker_name"
                        docker rmi -f "$docker_img"
                        # 安装 Docker（请确保有 install_docker 函数）
                        install_docker
                        $docker_rum
                        clear
                        echo "$docker_name 已经安装完成"
                        echo "------------------------"
                        # 获取外部 IP 地址
                        ip_address
                        echo "您可以使用以下地址访问:"
                        echo "http:$ipv4_address:$docker_port"

                        ;;
                    2)
                        clear
                        docker rm -f "$docker_name"
                        docker rmi -f "$docker_img"
                        rm -rf "/home/docker/$docker_name"
                        echo "应用已卸载"
                        ;;
                    3)
                        clear
                        nano /home/docker/PandoraNext/data/config.json
                        echo "正在重启$docker_name"
                        docker restart "$docker_name"

                        ;;
                    4)
                        clear
                        nano /home/docker/PandoraNext/data/tokens.json
                        echo "正在重启$docker_name"
                        docker restart "$docker_name"

                        ;;
                    0)
                        # 跳出循环，退出菜单
                        ;;
                    *)
                        # 跳出循环，退出菜单
                        ;;
                esac
            else
                clear
                echo "安装提示"
                echo "$docker_describe"
                echo "$docker_url"
                echo ""

                # 提示用户确认安装
                read -p "确定安装吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                        clear
                        echo "获取license_id请访问: https://dash.pandoranext.com/"
                        read -p "请输入你的GitHub的license_id: " github1

                        install_docker

                        mkdir -p /home/docker/PandoraNext/{data,sessions}
                        cd /home/docker/PandoraNext/data
                        wget https://raw.githubusercontent.com/kejilion/sh/main/PandoraNext/config.json
                        wget https://raw.githubusercontent.com/kejilion/sh/main/PandoraNext/tokens.json
                        sed -i "s/github/$github1/g" /home/docker/PandoraNext/data/config.json
                        webgptpasswd1=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
                        sed -i "s/webgptpasswd/$webgptpasswd1/g" /home/docker/PandoraNext/data/config.json

                        $docker_rum
                        clear
                        echo "$docker_name 已经安装完成"
                        echo "------------------------"
                        # 获取外部 IP 地址
                        ip_address
                        echo "您可以使用以下地址访问:"
                        echo "http:$ipv4_address:$docker_port"

                        ;;
                    [Nn])
                        # 用户选择不安装
                        ;;
                    *)
                        # 无效输入
                        ;;
                esac
            fi






              ;;

          0)
              main_menu
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;

  10)
    while true; do
      clear
      echo "▶ 系统工具"
      echo "------------------------"
      echo " 1. 设置脚本启动快捷键"
      echo "------------------------"
      echo " 2. 修改ROOT密码"
      echo " 3. 开启ROOT密码登录模式"
      echo " 4. 禁用修改ROOT密码"
      echo " 5. 开放所有端口"
      echo " 6. 修改SSH连接端口"
      echo " 7. 优化DNS地址"
      echo -e "${skyblue} 8. 一键重装系统${re}"
      echo " 9. 禁用ROOT账户创建新账户"
      echo "10. 切换优先ipv4/ipv6"
      echo "11. 查看端口占用状态"
      echo "12. 修改虚拟内存大小"
      echo "13. 用户管理"
      echo "14. 用户/密码生成器"
      echo "15. 系统时区调整"
      echo "16. 开启BBR3加速"
      echo "17. 防火墙高级管理器"
      echo "18. 修改主机名"
      echo "19. 切换系统更新源"
      echo "20. 定时任务管理"
      echo "21. ip开放端口扫描"
      echo "22. 服务器资源限制"
      echo -e "23. ${skyblue}NAT小鸡一键重装系统${re}"
      echo "24. iptables一键转发"
      echo "25. NAT批量SSH连接测试"
      echo "------------------------"
      echo "80. 留言板"
      echo "------------------------"
      echo "99. 重启服务器"
      echo "------------------------"
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              read -p $'\033[1;91m请输入你的快捷按键: \033[0m' kuaijiejian
              echo "alias $kuaijiejian='./ssh_tool.sh'" >> ~/.bashrc
              source ~/.bashrc
              echo "快捷键已设置"
              ;;

          2)
              clear
               read -p $'\033[1;35m请输入新的ROOT密码: \033[0m' passwd
               echo "root:$passwd" | chpasswd && echo -e "\033[1;32mRoot密码修改成功. 正在重启服务器...\033[0m" && sleep 1 && reboot || echo -e "\033[1;91mRoot密码修改失败\033[0m"
              ;;
          3)
              clear
              read -p $'\033[1;35m请设置你的root密码: \033[0m' passwd
              echo "root:$passwd" | chpasswd && echo "Root密码设置成功" || echo "Root密码修改失败"
              sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
              sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
              service sshd restart
              echo -e "${green}ROOT登录设置完毕，重启服务器生效${re}"
              read -p $'\033[1;35m需要立即重启服务器吗？(y/n): \033[0m' choice
          case "$choice" in
            [Yy])
              reboot
              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
              ;;

          4)
            clear
                chattr +i /etc/passwd
                chattr +i /etc/shadow
                echo -e "${yellow}已禁用修改ROOT密码${re}"
              ;;

          5)
              clear
              iptables_open
              remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
              echo -e "${green}端口已全部开放${re}"

              ;;
          6)
              clear
              #!/bin/bash

              # 去掉 #Port 的注释
              sed -i 's/#Port/Port/' /etc/ssh/sshd_config

              # 读取当前的 SSH 端口号
              current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

              # 打印当前的 SSH 端口号
              echo "当前的 SSH 端口号是: $current_port"

              echo "------------------------"

              # 提示用户输入新的 SSH 端口号
              read -p $'\033[1;35m请输入新的 SSH 端口号: \033[0m' new_port

              # 备份 SSH 配置文件
              cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

              # 替换 SSH 配置文件中的端口号
              sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

              # 重启 SSH 服务
              service sshd restart

              echo "SSH 端口已修改为: $new_port"

              clear
              iptables_open
              remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

              ;;


          7)
            clear
            echo "当前DNS地址"
            echo "------------------------"
            cat /etc/resolv.conf
            echo "------------------------"
            echo ""
            # 询问用户是否要优化DNS设置
            read -p $'\033[1;35m是否要设置为Cloudflare和Google的DNS地址？(y/n): \033[0m' choice

            if [ "$choice" == "y" ]; then
                # 定义DNS地址
                cloudflare_ipv4="1.1.1.1"
                google_ipv4="8.8.8.8"
                cloudflare_ipv6="2606:4700:4700::1111"
                google_ipv6="2001:4860:4860::8888"

                # 检查机器是否有IPv6地址
                ipv6_available=0
                if [[ $(ip -6 addr | grep -c "inet6") -gt 0 ]]; then
                    ipv6_available=1
                fi

                # 设置DNS地址为Cloudflare和Google（IPv4和IPv6）
                echo "设置DNS为Cloudflare和Google"

                # 设置IPv4地址
                echo "nameserver $cloudflare_ipv4" > /etc/resolv.conf
                echo "nameserver $google_ipv4" >> /etc/resolv.conf

                # 如果有IPv6地址，则设置IPv6地址
                if [[ $ipv6_available -eq 1 ]]; then
                    echo "nameserver $cloudflare_ipv6" >> /etc/resolv.conf
                    echo "nameserver $google_ipv6" >> /etc/resolv.conf
                fi

                echo "DNS地址已更新"
                echo "------------------------"
                cat /etc/resolv.conf
                echo "------------------------"
            else
                echo "DNS设置未更改"
            fi

              ;;

          8)
            clear
            echo -e "${purple}重装系统将无法恢复数据，请提前做好备份${re}"
            echo ""
            read -p $'\033[1;35m确定要重装吗？(y/n): \033[0m' confirm

            if [[ $confirm =~ ^[Yy]$ ]]; then
                    sleep 1
                    echo -e "${yellow}初始化安装环境...${re}"
                    install wget
                    wget --no-check-certificate -qO InstallNET.sh 'https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh' && chmod a+x InstallNET.sh
                    sleep 1
                while true; do
                    echo ""
                    echo -e "${purple}请保存你的root密码，安装后使用该密码登录，登录成功后自行修改${re}"
                    echo -e "${yellow}Linux默认用户名：${purple}root${yellow} 默认密码：${purple}LeitboGi0ro${yellow} 默认ssh端口22${re}"
                    echo -e "${yellow}Windows默认用户名：${purple}Administrator${yellow} 默认密码：${purple}Teddysun.com${yellow} 默认远程连接端口${purple}3389${re}"
                    echo -e "${yellow}详细参数参考Github项目地址：https://github.com/leitbogioro/Tools${re}"
                    echo ""
                    echo -e "${green}1.安装Debian-12${re}"
                    echo -e "${green}2.安装Ubuntu-22.04${re}"
                    echo -e "${green}3.安装Alpine-Linux${re}"
                    echo -e "${green}4.安装CentOS-9${re}"
                    echo -e "${green}5.安装Fedora-39${re}"
                    echo -e "${green}6.安装RockyLinux-9${re}"
                    echo -e "${green}7.安装AlmaLinux-9${re}"
                    echo -e "${green}8.安装Kali-Rolling${re}"
                    echo -e "${green}9.安装Windows-11-Pro${re}"
                    echo "---------------------"
                    echo -e "${red}0.取消安装${re}"
                    echo "------------------------"
                    read -p $'\033[1;35m请输入你的选择: \033[0m' sub_choice
                   
                    case $sub_choice in
                        1) 
                            echo -e "${green}开始为你安装Debian-12${re}"
                            sleep 1
                            bash InstallNET.sh -debian
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        2) 
                            echo -e "${green}开始为你安装Ubuntu-22.04${re}"
                            sleep 1
                            bash InstallNET.sh -ubuntu
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        3) 
                            echo -e "${green}开始为你安装Alpine-Linux${re}"
                            sleep 1
                            bash InstallNET.sh -alpine
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        4) 
                            echo -e "${green}开始为你安装CentOS-9${re}"
                            sleep 1
                            bash InstallNET.sh -centos
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        5) 
                            echo -e "${green}开始为你安装Fedora-39${re}"
                            sleep 1
                            bash InstallNET.sh -fedora
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        6) 
                            echo -e "${green}开始为你安装RockyLinux-9${re}"
                            sleep 1
                            bash InstallNET.sh -rockylinux
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        7) 
                            echo -e "${green}开始为你安装AlmaLinux-9${re}"
                            sleep 1
                            bash InstallNET.sh -rockylinux
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        8) 
                            echo -e "${green}开始为你安装Kali-Rolling${re}"
                            sleep 1
                            bash InstallNET.sh -kali
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接SSH${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        9) 
                            echo -e "${green}开始为你安装Windows-11-Pro${re}"
                            sleep 1
                            bash InstallNET.sh -windows
                            sleep 2
                            clear
                            read -p $'\033[1;35m是否立即重启系统继续完成安装？(y/n): \033[0m' restart_choice
                            echo -e "${green}重启系统几分钟后即可连接远程桌面${re}"
                            if [[ $restart_choice =~ ^[Yy]$ ]]; then
                                reboot
                            else 
                                echo -e "${green}请手动重启系统继续完成安装${re}"
                                sleep 2
                                main_menu
                            fi
                            ;;
                        0) 
                            echo -e "${red}正在退出安装...${re}"
                            rm InstallNET.sh
                            sleep 2
                            main_menu
                            ;;
                        *)
                            echo -e "${red}输入错误，请重新输入${re}"
                            ;;
                    esac
                done
            else 
                main_menu
            fi
            ;;

          9)
            clear
            install sudo

            # 提示用户输入新用户名
            read -p "请输入新用户名: " new_username

            # 创建新用户并设置密码
            sudo useradd -m -s /bin/bash "$new_username"
            sudo passwd "$new_username"

            # 赋予新用户sudo权限
            echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

            # 禁用ROOT用户登录
            sudo passwd -l root

            echo "操作已完成。"
            ;;


          10)
            clear
            ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

            echo ""
            if [ "$ipv6_disabled" -eq 1 ]; then
                echo "当前网络优先级设置: IPv4 优先"
            else
                echo "当前网络优先级设置: IPv6 优先"
            fi
            echo "------------------------"

            echo ""
            echo "切换的网络优先级"
            echo "------------------------"
            echo "1. IPv4 优先          2. IPv6 优先"
            echo "------------------------"
            read -p "选择优先的网络: " choice

            case $choice in
                1)
                    sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
                    echo "已切换为 IPv4 优先"
                    ;;
                2)
                    sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
                    echo "已切换为 IPv6 优先"
                    ;;
                *)
                    echo "无效的选择"
                    ;;

            esac
            ;;

          11)
            clear
            ss -tulnape
            ;;

          12)

            if [ "$EUID" -ne 0 ]; then
              echo "请以 root 权限运行此脚本。"
              exit 1
            fi

            clear
            # 获取当前交换空间信息
            swap_used=$(free -m | awk 'NR==3{print $3}')
            swap_total=$(free -m | awk 'NR==3{print $2}')

            if [ "$swap_total" -eq 0 ]; then
              swap_percentage=0
            else
              swap_percentage=$((swap_used * 100 / swap_total))
            fi

            swap_info="${swap_used}MB/${swap_total}MB (${swap_percentage}%)"

            echo "当前虚拟内存: $swap_info"

            read -p "是否调整大小?(Y/N): " choice

            case "$choice" in
              [Yy])
                # 输入新的虚拟内存大小
                read -p "请输入虚拟内存大小MB: " new_swap

                # 获取当前系统中所有的 swap 分区
                swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

                # 遍历并删除所有的 swap 分区
                for partition in $swap_partitions; do
                  swapoff "$partition"
                  wipefs -a "$partition"  # 清除文件系统标识符
                  mkswap -f "$partition"
                  echo "已删除并重新创建 swap 分区: $partition"
                done

                # 确保 /swapfile 不再被使用
                swapoff /swapfile

                # 删除旧的 /swapfile
                rm -f /swapfile

                # 创建新的 swap 分区
                dd if=/dev/zero of=/swapfile bs=1M count=$new_swap
                chmod 600 /swapfile
                mkswap /swapfile
                swapon /swapfile
                echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

                echo "虚拟内存大小已调整为${new_swap}MB"
                ;;
              [Nn])
                echo "已取消"
                ;;
              *)
                echo "无效的选择，请输入 Y 或 N。"
                ;;
            esac
            ;;

          13)
              while true; do
                clear
                install sudo
                clear
                # 显示所有用户、用户权限、用户组和是否在sudoers中
                echo "用户列表"
                echo "----------------------------------------------------------------------------"
                printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
                while IFS=: read -r username _ userid groupid _ _ homedir shell; do
                    groups=$(groups "$username" | cut -d : -f 2)
                    sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
                    printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
                done < /etc/passwd


                  echo ""
                  echo "账户操作"
                  echo "------------------------"
                  echo "1. 创建普通账户             2. 创建高级账户"
                  echo "------------------------"
                  echo "3. 赋予最高权限             4. 取消最高权限"
                  echo "------------------------"
                  echo "5. 删除账号"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                       # 提示用户输入新用户名
                       read -p "请输入新用户名: " new_username

                       # 创建新用户并设置密码
                       sudo useradd -m -s /bin/bash "$new_username"
                       sudo passwd "$new_username"

                       echo "操作已完成。"
                          ;;

                      2)
                       # 提示用户输入新用户名
                       read -p "请输入新用户名: " new_username

                       # 创建新用户并设置密码
                       sudo useradd -m -s /bin/bash "$new_username"
                       sudo passwd "$new_username"

                       # 赋予新用户sudo权限
                       echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

                       echo "操作已完成。"

                          ;;
                      3)
                       read -p "请输入用户名: " username
                       # 赋予新用户sudo权限
                       echo "$username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
                          ;;
                      4)
                       read -p "请输入用户名: " username
                       # 从sudoers文件中移除用户的sudo权限
                       sudo sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

                          ;;
                      5)
                       read -p "请输入要删除的用户名: " username
                       # 删除用户及其主目录
                       sudo userdel -r "$username"
                          ;;

                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done
              ;;

          14)
            clear

            echo "随机用户名"
            echo "------------------------"
            for i in {1..5}; do
                username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
                echo "随机用户名 $i: $username"
            done

            echo ""
            echo "随机姓名"
            echo "------------------------"
            first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
            last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

            # 生成5个随机用户姓名
            for i in {1..5}; do
                first_name_index=$((RANDOM % ${#first_names[@]}))
                last_name_index=$((RANDOM % ${#last_names[@]}))
                user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
                echo "随机用户姓名 $i: $user_name"
            done

            echo ""
            echo "随机UUID"
            echo "------------------------"
            for i in {1..5}; do
                uuid=$(cat /proc/sys/kernel/random/uuid)
                echo "随机UUID $i: $uuid"
            done

            echo ""
            echo "16位随机密码"
            echo "------------------------"
            for i in {1..5}; do
                password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
                echo "随机密码 $i: $password"
            done

            echo ""
            echo "32位随机密码"
            echo "------------------------"
            for i in {1..5}; do
                password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
                echo "随机密码 $i: $password"
            done
            echo ""

              ;;

          15)
            while true; do
                clear
                echo "系统时间信息"

                # 获取当前系统时区
                current_timezone=$(timedatectl show --property=Timezone --value)

                # 获取当前系统时间
                current_time=$(date +"%Y-%m-%d %H:%M:%S")

                # 显示时区和时间
                echo "当前系统时区：$current_timezone"
                echo "当前系统时间：$current_time"

                echo ""
                echo "时区切换"
                echo "亚洲------------------------"
                echo " 1. 中国上海时间              2. 中国香港时间"
                echo " 3. 日本东京时间              4. 韩国首尔时间"
                echo " 5. 新加坡时间                6. 印度加尔各答时间"
                echo " 7. 阿联酋迪拜时间            8. 澳大利亚悉尼时间"
                echo "欧洲------------------------"
                echo "11. 英国伦敦时间             12. 法国巴黎时间"
                echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
                echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
                echo "美洲------------------------"
                echo "21. 美国西部时间             22. 美国东部时间"
                echo "23. 加拿大时间               24. 墨西哥时间"
                echo "25. 巴西时间                 26. 阿根廷时间"
                echo "------------------------"
                echo " 0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1) timedatectl set-timezone Asia/Shanghai ;;
                    2) timedatectl set-timezone Asia/Hong_Kong ;;
                    3) timedatectl set-timezone Asia/Tokyo ;;
                    4) timedatectl set-timezone Asia/Seoul ;;
                    5) timedatectl set-timezone Asia/Singapore ;;
                    6) timedatectl set-timezone Asia/Kolkata ;;
                    7) timedatectl set-timezone Asia/Dubai ;;
                    8) timedatectl set-timezone Australia/Sydney ;;
                    11) timedatectl set-timezone Europe/London ;;
                    12) timedatectl set-timezone Europe/Paris ;;
                    13) timedatectl set-timezone Europe/Berlin ;;
                    14) timedatectl set-timezone Europe/Moscow ;;
                    15) timedatectl set-timezone Europe/Amsterdam ;;
                    16) timedatectl set-timezone Europe/Madrid ;;
                    21) timedatectl set-timezone America/Los_Angeles ;;
                    22) timedatectl set-timezone America/New_York ;;
                    23) timedatectl set-timezone America/Vareouver ;;
                    24) timedatectl set-timezone America/Mexico_City ;;
                    25) timedatectl set-timezone America/Sao_Paulo ;;
                    26) timedatectl set-timezone America/Argentina/Buenos_Aires ;;
                    0) break ;; # 跳出循环，退出菜单
                    *) break ;; # 跳出循环，退出菜单
                esac
            done
              ;;

          16)
          if dpkg -l | grep -q 'linux-xanmod'; then
            while true; do
                  clear
                  kernel_version=$(uname -r)
                  echo "您已安装xanmod的BBRv3内核"
                  echo "当前内核版本: $kernel_version"

                  echo ""
                  echo "内核管理"
                  echo "------------------------"
                  echo "1. 更新BBRv3内核              2. 卸载BBRv3内核"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                        apt update -y
                        apt upgrade -y
                        echo "XanMod内核已更新。重启后生效"
                        reboot

                          ;;
                      2)
                        apt purge -y 'linux-*xanmod1*'
                        update-grub
                        echo "XanMod内核已卸载。重启后生效"
                        reboot
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;

                  esac
            done
        else

          clear
          echo "请备份数据，将为你升级Linux内核开启BBR3"
          echo "官网介绍: https://xanmod.org/"
          echo "------------------------------------------------"
          echo "仅支持Debian/Ubuntu 仅支持x86_64架构"
          echo "VPS是512M内存的，请提前添加1G虚拟内存，防止因内存不足失联！"
          echo "------------------------------------------------"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
            if [ -r /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
                    echo "当前环境不支持，仅支持Debian和Ubuntu系统"
                    break
                fi
            else
                echo "无法确定操作系统类型"
                break
            fi

            # 检查系统架构
            arch=$(dpkg --print-architecture)
            if [ "$arch" != "amd64" ]; then
              echo "当前环境不支持，仅支持x86_64架构"
              break
            fi

            install wget gnupg

            # wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
            wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

            # 步骤3：添加存储库
            echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

            # version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
            version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

            apt update -y
            apt install -y linux-xanmod-x64v$version

            # 步骤5：启用BBR3
            cat > /etc/sysctl.conf << EOF
net.core.default_qdisc=fq_pie
net.ipv4.tcp_congestion_control=bbr
EOF
            sysctl -p
            echo "XanMod内核安装并BBR3启用成功。重启后生效"
            rm -f /etc/apt/sources.list.d/xanmod-release.list
            rm -f check_x86-64_psabi.sh*
            reboot

              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
        fi
              ;;

          17)
          if dpkg -l | grep -q iptables-persistent; then
            while true; do
                  clear
                  echo "防火墙已安装"
                  echo "------------------------"
                  iptables -L INPUT

                  echo ""
                  echo "防火墙管理"
                  echo "------------------------"
                  echo "1. 开放指定端口              2. 关闭指定端口"
                  echo "3. 开放所有端口              4. 关闭所有端口"
                  echo "------------------------"
                  echo "5. IP白名单                  6. IP黑名单"
                  echo "7. 清除指定IP"
                  echo "------------------------"
                  echo "9. 关闭并卸载防火墙"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                      read -p "请输入开放的端口号: " o_port
                      sed -i "/COMMIT/i -A INPUT -p tcp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
                      sed -i "/COMMIT/i -A INPUT -p udp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4

                          ;;
                      2)
                      read -p "请输入关闭的端口号: " c_port
                      sed -i "/--dport $c_port/d" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4
                        ;;

                      3)
                      current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

                      cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT ACCEPT [0:0]
:FORWARD ACCEPT [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF
                      iptables-restore < /etc/iptables/rules.v4

                          ;;
                      4)
                      current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

                      cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF
                      iptables-restore < /etc/iptables/rules.v4

                          ;;

                      5)
                      read -p "请输入放行的IP: " o_ip
                      sed -i "/COMMIT/i -A INPUT -s $o_ip -j ACCEPT" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4

                          ;;

                      6)
                      read -p "请输入封锁的IP: " c_ip
                      sed -i "/COMMIT/i -A INPUT -s $c_ip -j DROP" /etc/iptables/rules.v4
                      iptables-restore < /etc/iptables/rules.v4
                          ;;

                      7)
                     read -p "请输入清除的IP: " d_ip
                     sed -i "/-A INPUT -s $d_ip/d" /etc/iptables/rules.v4
                     iptables-restore < /etc/iptables/rules.v4
                          ;;

                      9)
                      sudo systemctl stop ufw.service && sudo systemctl disable ufw.service && (sudo ufw status | grep -q 'Status: inactive' && echo "UFW closed successfully" || echo "Failed to close UFW")
                      remove iptables-persistent
                      rm /etc/iptables/rules.v4
                      break
                      # echo "防火墙已卸载，重启生效"
                      # reboot
                          ;;

                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;

                  esac
            done
        else

          clear
          echo "将为你安装防火墙，该防火墙仅支持Debian/Ubuntu"
          echo "------------------------------------------------"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
            if [ -r /etc/os-release ]; then
                . /etc/os-release
                if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
                    echo "当前环境不支持，仅支持Debian和Ubuntu系统"
                    break
                fi
            else
                echo "无法确定操作系统类型"
                break
            fi

          clear
          iptables_open
          remove iptables-persistent ufw
          rm /etc/iptables/rules.v4

          apt update -y && apt install -y iptables-persistent

          current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

          cat > /etc/iptables/rules.v4 << EOF
*filter
:INPUT DROP [0:0]
:FORWARD DROP [0:0]
:OUTPUT ACCEPT [0:0]
-A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
-A INPUT -i lo -j ACCEPT
-A FORWARD -i lo -j ACCEPT
-A INPUT -p tcp --dport $current_port -j ACCEPT
COMMIT
EOF

          iptables-restore < /etc/iptables/rules.v4
          systemctl enable netfilter-persistent
          echo "防火墙安装完成"


              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
        fi
              ;;

          18)
            clear
            # 获取系统信息
            source /etc/os-release
            echo -e "${yellow}当前系统: ${red}${PRETTY_NAME}${re}"
            current_hostname=$(hostname)
            read -p $'\033[1;35m确定要更改主机名？ (y/n): \033[0m' choice

            if [[ "$choice" =~ ^[Yy]$ ]]; then

                read -p $'\033[1;35m请输入新的主机名: \033[0m' new_hostname

                case $ID in
                    "alpine")
                        echo "$new_hostname" > /etc/hostname
                        echo "127.0.0.1 localhost $new_hostname" > /etc/hosts
                        ;;
                    "debian" | "ubuntu")
                        hostnamectl set-hostname "$new_hostname"
                        sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
                        ;;
                    "centos" | "fedora" | "rocky" | "amzn" | "almalinux")
                        hostnamectl set-hostname "$new_hostname"
                        ;;
                    *)
                        echo -e "${red}不支持的系统类型: ${ID}${re}"
                        sleep 3
                        main_menu
                        ;;
                esac

                echo -e $'\033[1;35m主机名已更改，重新连接ssh生效\033[0m'
                    sleep 2
                    main_menu
            else
                echo -e "${green}取消更改主机名。${re}"
                sleep 2
                main_menu
            fi

            ;;
            
          19)

          # 获取系统信息
          source /etc/os-release

          # 定义 Ubuntu 更新源
          aliyun_ubuntu_source="http://mirrors.aliyun.com/ubuntu/"
          official_ubuntu_source="http://archive.ubuntu.com/ubuntu/"
          initial_ubuntu_source=""

          # 定义 Debian 更新源
          aliyun_debian_source="http://mirrors.aliyun.com/debian/"
          official_debian_source="http://deb.debian.org/debian/"
          initial_debian_source=""

          # 定义 CentOS 更新源
          aliyun_centos_source="http://mirrors.aliyun.com/centos/"
          official_centos_source="http://mirror.centos.org/centos/"
          initial_centos_source=""

          # 获取当前更新源并设置初始源
          case "$ID" in
              ubuntu)
                  initial_ubuntu_source=$(grep -E '^deb ' /etc/apt/sources.list | head -n 1 | awk '{print $2}')
                  ;;
              debian)
                  initial_debian_source=$(grep -E '^deb ' /etc/apt/sources.list | head -n 1 | awk '{print $2}')
                  ;;
              centos)
                  initial_centos_source=$(awk -F= '/^baseurl=/ {print $2}' /etc/yum.repos.d/CentOS-Base.repo | head -n 1 | tr -d ' ')
                  ;;
              *)
                  echo "未知系统，无法执行切换源脚本"
                  exit 1
                  ;;
          esac

          # 备份当前源
          backup_sources() {
              case "$ID" in
                  ubuntu)
                      cp /etc/apt/sources.list /etc/apt/sources.list.bak
                      ;;
                  debian)
                      cp /etc/apt/sources.list /etc/apt/sources.list.bak
                      ;;
                  centos)
                      if [ ! -f /etc/yum.repos.d/CentOS-Base.repo.bak ]; then
                          cp /etc/yum.repos.d/CentOS-Base.repo /etc/yum.repos.d/CentOS-Base.repo.bak
                      else
                          echo "备份已存在，无需重复备份"
                      fi
                      ;;
                  *)
                      echo "未知系统，无法执行备份操作"
                      exit 1
                      ;;
              esac
              echo "已备份当前更新源为 /etc/apt/sources.list.bak 或 /etc/yum.repos.d/CentOS-Base.repo.bak"
          }

          # 还原初始更新源
          restore_initial_source() {
              case "$ID" in
                  ubuntu)
                      cp /etc/apt/sources.list.bak /etc/apt/sources.list
                      ;;
                  debian)
                      cp /etc/apt/sources.list.bak /etc/apt/sources.list
                      ;;
                  centos)
                      cp /etc/yum.repos.d/CentOS-Base.repo.bak /etc/yum.repos.d/CentOS-Base.repo
                      ;;
                  *)
                      echo "未知系统，无法执行还原操作"
                      exit 1
                      ;;
              esac
              echo "已还原初始更新源"
          }

          # 函数：切换更新源
          switch_source() {
              case "$ID" in
                  ubuntu)
                      sed -i 's|'"$initial_ubuntu_source"'|'"$1"'|g' /etc/apt/sources.list
                      ;;
                  debian)
                      sed -i 's|'"$initial_debian_source"'|'"$1"'|g' /etc/apt/sources.list
                      ;;
                  centos)
                      sed -i "s|^baseurl=.*$|baseurl=$1|g" /etc/yum.repos.d/CentOS-Base.repo
                      ;;
                  *)
                      echo "未知系统，无法执行切换操作"
                      exit 1
                      ;;
              esac
          }

          # 主菜单
          while true; do
              clear
              case "$ID" in
                  ubuntu)
                      echo "Ubuntu 更新源切换脚本"
                      echo "------------------------"
                      ;;
                  debian)
                      echo "Debian 更新源切换脚本"
                      echo "------------------------"
                      ;;
                  centos)
                      echo "CentOS 更新源切换脚本"
                      echo "------------------------"
                      ;;
                  *)
                      echo "未知系统，无法执行脚本"
                      exit 1
                      ;;
              esac

              echo "1. 切换到阿里云源"
              echo "2. 切换到官方源"
              echo "------------------------"
              echo "3. 备份当前更新源"
              echo "4. 还原初始更新源"
              echo "------------------------"
              echo "0. 返回上一级"
              echo "------------------------"
              read -p "请选择操作: " choice

              case $choice in
                  1)
                      backup_sources
                      case "$ID" in
                          ubuntu)
                              switch_source $aliyun_ubuntu_source
                              ;;
                          debian)
                              switch_source $aliyun_debian_source
                              ;;
                          centos)
                              switch_source $aliyun_centos_source
                              ;;
                          *)
                              echo "未知系统，无法执行切换操作"
                              exit 1
                              ;;
                      esac
                      echo "已切换到阿里云源"
                      ;;
                  2)
                      backup_sources
                      case "$ID" in
                          ubuntu)
                              switch_source $official_ubuntu_source
                              ;;
                          debian)
                              switch_source $official_debian_source
                              ;;
                          centos)
                              switch_source $official_centos_source
                              ;;
                          *)
                              echo "未知系统，无法执行切换操作"
                              exit 1
                              ;;
                      esac
                      echo "已切换到官方源"
                      ;;
                  3)
                      backup_sources
                      case "$ID" in
                          ubuntu)
                              switch_source $initial_ubuntu_source
                              ;;
                          debian)
                              switch_source $initial_debian_source
                              ;;
                          centos)
                              switch_source $initial_centos_source
                              ;;
                          *)
                              echo "未知系统，无法执行切换操作"
                              exit 1
                              ;;
                      esac
                      echo "已切换到初始更新源"
                      ;;
                  4)
                      restore_initial_source
                      ;;
                  0)
                      break
                      ;;
                  *)
                      echo "无效的选择，请重新输入"
                      ;;
              esac
              break_end

          done

              ;;

          20)

              while true; do
                  clear
                  echo "定时任务列表"
                  crontab -l
                  echo ""
                  echo "操作"
                  echo "------------------------"
                  echo "1. 添加定时任务              2. 删除定时任务"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                  case $sub_choice in
                      1)
                          read -p "请输入新任务的执行命令: " newquest
                          echo "------------------------"
                          echo "1. 每周任务                 2. 每天任务"
                          read -p $'\033[1;91m请输入你的选择: \033[0m' dingshi

                          case $dingshi in
                              1)
                                  read -p "选择周几执行任务？ (0-6，0代表星期日): " weekday
                                  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
                                  ;;
                              2)
                                  read -p "选择每天几点执行任务？（小时，0-23）: " hour
                                  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
                                  ;;
                              *)
                                  break  # 跳出
                                  ;;
                          esac
                          ;;
                      2)
                          read -p "请输入需要删除任务的关键字: " kquest
                          crontab -l | grep -v "$kquest" | crontab -
                          ;;
                      0)
                          break  # 跳出循环，退出菜单
                          ;;

                      *)
                          break  # 跳出循环，退出菜单
                          ;;
                  esac
              done

              ;;

          21)

            while true; do
                clear
                echo "ip端口扫描"
                echo "------------------------"
                echo "1. ipv4"
                echo "2. ipv6"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice   

                case $sub_choice in
                    1)
                        clear
                        # 检查是否已安装 nmap
                        if command -v nmap &> /dev/null; then
                            # nmap 已安装
                            echo -e "${green}nmap已存在，无需安装${re}"
                            while true; do
                                read -p "请输入你想要扫描的ipv4: " ip4
                                if [[ $ip4 =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv4地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip4}开放的端口，请稍等...${re}"
                            nmap -sS -p 1-65535 $ip4
                            echo -e "${green}${ip4}端口已扫描完${re}"

                        else
                            # nmap 未安装，使用相应的包管理工具进行安装
                            echo -e "${yellow}nmap不存在. 开始安装nmap...${re}"
                            install "nmap"
                            sleep 1
                            clear
                            while true; do
                                read -p "请输入你想要扫描的ipv4: " ip4
                                if [[ $ip4 =~ ^[0-9]{1,3}(\.[0-9]{1,3}){3}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv4地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip4}开放的端口，请稍等...${re}"
                            nmap -sS -p 1-65535 $ip4
                            echo -e "${green}${ip4}端口已扫描完${re}"

                        fi
                            break_end

                        ;;
                    
                    2)
                        clear
                        # 检查是否已安装 nmap
                        if command -v nmap &> /dev/null; then
                            # nmap 已安装
                            echo -e "${green}nmap已存在，无需安装${re}"
                            while true; do
                                read -p "请输入你想要扫描的ipv6: " ip6
                                if [[ $ip6 =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::([0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,6}:$|^([0-9a-fA-F]{1,4}:){1,6}::([0-9a-fA-F]{1,4}:){0,4}[0-9a-fA-F]{1,4}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv6地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip6}开放的端口，请稍等...${re}"
                            nmap -6 -sS -p 1-65535 $ip6
                            echo -e "${green}${ip6}端口已扫描完${re}"

                        else
                            # nmap 未安装，使用相应的包管理工具进行安装
                            echo -e "${yellow}nmap不存在. 开始安装nmap...${re}"
                            install "nmap"
                            sleep 1
                            while true; do
                                read -p "请输入你想要扫描的ipv6: " ip6
                                if [[ $ip6 =~ ^([0-9a-fA-F]{1,4}:){7}[0-9a-fA-F]{1,4}$|^::([0-9a-fA-F]{1,4}:){0,5}[0-9a-fA-F]{1,4}$|^([0-9a-fA-F]{1,4}:){1,6}:$|^([0-9a-fA-F]{1,4}:){1,6}::([0-9a-fA-F]{1,4}:){0,4}[0-9a-fA-F]{1,4}$ ]]; then
                                    break
                                else
                                    echo -e "${red}无效的IPv6地址，请重新输入${re}"
                                fi
                            done
                            sleep 1
                            echo -e "${green}开始扫描${ip6}开放的端口，请稍等...${re}"
                            nmap -6 -sS -p 1-65535 $ip6
                            echo -e "${green}${ip6}端口已扫描完${re}"

                        fi
                            break_end
                        ;;
                    0)
                        break  # 跳出循环，退出菜单
                    ;;

                    *)
                        break  # 跳出循环，退出菜单
                    ;; 
                esac
            done
            ;;

          22)
            # 检查依赖包
            check_packages() {
                install net-tools bc sysstat
            }
            check_packages
            
            while true; do
                clear
                echo -e "${yellow}服务器资源控制${re}"
                echo "------------------------"
                echo -e "${yellow}当CPU或内存或流量达到设置的阈值将采取关机操作${re}"
                echo "------------------------"
                echo "1. 一键限制CPU，当CPU达到99%自动关机"
                echo "2. 一键限制内存，内存达到99%自动关机"
                echo "3. 一键限制流量1T，流量达到1T自动关机"
                echo "4. CPU99%、内存99%、流量5T统一限制"
                echo "------------------------"
                echo "0. 返回上一级选单"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice   

                case $sub_choice in
                    1)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check_cpu.sh -o check_cpu.sh && chmod +x check_cpu.sh && bash check_cpu.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check_cpu.sh >> /root/check_cpu.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end
                    ;;
                    2)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check_memory.sh -o check_memory.sh && chmod +x check_memory.sh && bash check_memory.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check_memory.sh >> /root/check_cpu.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end                         
                    ;;
                    3)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check_traffic.sh -o check_traffic.sh && chmod +x check_traffic.sh && bash check_traffic.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check_traffic.sh >> /root/check_traffic.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end                         
                    ;;
                    4)
                        curl https://raw.githubusercontent.com/eooce/ssh_tool/main/check.sh -o check.sh && chmod +x check.sh && bash check.sh

                        # 添加Cron任务
                        (crontab -l 2>/dev/null; echo "*/10 * * * * /bin/bash /root/check.sh >> /root/check.log 2>&1") | crontab -
                        echo -e "${green}Cron任务已添加${re}"
                        break_end                         
                    ;;

                    0)
                        break  # 跳出循环，退出菜单
                    ;;

                    *)
                        break  # 跳出循环，退出菜单
                    ;; 
                esac
            done
            ;;

          23)
            clear
            echo -e "${green}重装系统将无法恢复数据，请提前做好备份${re}"
            echo ""
            read -p $'\033[1;35m确定要重装吗？(y/n): \033[0m' confirm

                if [[ $confirm =~ ^[Yy]$ ]]; then
                    sleep 1
                    curl -so OsMutation.sh https://raw.githubusercontent.com/LloydAsp/OsMutation/main/OsMutation.sh && chmod u+x OsMutation.sh && ./OsMutation.sh
                    break_end
                else 
                    main_menu
                fi
            ;;

          24)
            clear
            wget --no-check-certificate -qO natcfg.sh https://raw.githubusercontent.com/arloor/iptablesUtils/master/natcfg.sh && bash natcfg.sh
            sleep 2
            break_end
            ;;
          25)
            clear
                echo -e "${yellow}初始化环境...${re}"
                install sshpass
                clear
                read -p $'\033[1;35m请输入要连接的ipv4/ipv6地址: \033[0m' common_ip
                
                echo -e "${green}即将进入nano编辑器，请添加nat小鸡配置信息${re}"
                sleep 1
                echo -e "# 示例配置: \n# ex1 20001 8a2a7f65c 30001 30025" > server.txt
                nano -w server.txt
                echo -e "${green}进入测试中,请稍等...${re}"

                if [ -f "server.txt" ]; then
                    mapfile -t lines < "server.txt"

                    # 遍历配置文件进行连接测试
                    for line in "${lines[@]}"; do
 
                        if [[ "$line" == \#* || -z "$line" ]]; then
                            continue
                        fi

                        name=$(echo "$line" | awk '{print $1}')
                        port=$(echo "$line" | awk '{print $2}')
                        password=$(echo "$line" | awk '{print $3}')

                        ssh_output=$(sshpass -p "$password" ssh -p "$port" -o ConnectTimeout=5 "root@$common_ip" "echo Connection successful!" 2>&1 || true)

                        if [[ "$ssh_output" == *successful* ]]; then
                            echo -e "${green}$name $port $password connect successful${re}"
                        else
                            echo -e "${red}$name $port $password connect failed${re}"
                        fi
                    done

                else
                    echo -e "${red}未找到server.txt配置文件${re}"
                    exit 1
                fi

                rm server.txt
                
              ;;
          80)
            clear
            install sshpass

            remote_ip="8.8.8.8"
            remote_user="liaotian123"
            remote_file="/home/liaotian123/liaotian.txt"
            password="wangYYDS"  # 替换为您的密码

            clear
            echo "留言板"
            echo "------------------------"
            # 显示已有的留言内容
            sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${remote_user}@${remote_ip}" "cat '${remote_file}'"
            echo ""
            echo "------------------------"

            # 判断是否要留言
            read -p "是否要留言？(y/n): " leave_message

            if [ "$leave_message" == "y" ] || [ "$leave_message" == "Y" ]; then
                # 输入新的留言内容
                read -p "输入你的昵称: " nicheng
                read -p "输入你的聊天内容: " neirong

                # 添加新留言到远程文件
                sshpass -p "${password}" ssh -o StrictHostKeyChecking=no "${remote_user}@${remote_ip}" "echo -e '${nicheng}: ${neirong}' >> '${remote_file}'"
                echo "已添加留言: "
                echo "${nicheng}: ${neirong}"
                echo ""
            else
                echo "您选择了不留言。"
            fi

            echo "留言板操作完成。"

              ;;

          99)
              clear
              echo "正在重启服务器，即将断开SSH连接"
              reboot
              ;;
          0)
              main_menu

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;


  11)
    while true; do
      clear
      echo "▶ 我的工作区"
      echo "系统将为你提供5个后台运行的工作区，你可以用来执行长时间的任务"
      echo "即使你断开SSH，工作区中的任务也不会中断，非常方便！来试试吧！"
      echo -e "\033[33m注意: 进入工作区后使用Ctrl+b再单独按d，退出工作区！\033[0m"
      echo "------------------------"
      echo "a. 安装工作区环境"
      echo "------------------------"
      echo "1. 1号工作区"
      echo "2. 2号工作区"
      echo "3. 3号工作区"
      echo "4. 4号工作区"
      echo "5. 5号工作区"
      echo "------------------------"
      echo "8. 工作区状态"
      echo "------------------------"
      echo "b. 卸载工作区"
      echo "------------------------"
      echo -e "${skyblue}0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          a)
              clear
              install tmux

              ;;
          b)
              clear
              remove tmux
              ;;
          1)
              clear
              SESSION_NAME="work1"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          2)
              clear
              SESSION_NAME="work2"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          3)
              clear
              SESSION_NAME="work3"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          4)
              clear
              SESSION_NAME="work4"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;
          5)
              clear
              SESSION_NAME="work5"

              # Check if the session already exists
              tmux has-session -t $SESSION_NAME 2>/dev/null

              # $? is a special variable that holds the exit status of the last executed command
              if [ $? != 0 ]; then
                # Session doesn't exist, create a new one
                tmux new -s $SESSION_NAME
              else
                # Session exists, attach to it
                tmux attach-session -t $SESSION_NAME
              fi
              ;;

          8)
              clear
              tmux list-sessions
              ;;
          0)
              main_menu
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;


  12)
    while true; do
      clear
      echo -e "${purple}▶ 节点搭建脚本合集${re}"
      echo -e "${green}---------------------------------------------------------${re}"
      echo -e "${green}       Sing-box多合一             Argo-tunnel${re}"
      echo -e "${green}---------------------------------------------------------${re}"
      echo -e "${white} 1. F佬Sing-box一键脚本        5. F佬ArgoX一键脚本${re}"
      echo -e "${white} 2. 小绵羊Sing-box三合一       6. Suoha一键Argo脚本${re}"
      echo -e "${white} 3. 勇哥Sing-box四合一         7. WL一键Argo哪吒脚本${re}"
      echo -e "${white} 4. V2ray-agent八合一          8. 一键老王Nodejs-Argo节点+哪吒+订阅"
      echo -e "${yellow}---------------------------------------------------------${re}"
      echo -e "${yellow}        单协议                    XRAY面板及其他${re}"
      echo -e "${yellow}---------------------------------------------------------${re}"
      echo -e "${white} 9. 老王Hysteria2一键脚本     13.新版Xray面板一键脚本${re}"
      echo -e "${white}10. M佬Juicity一键脚本        14.伊朗版Xray面板一键脚本${re}"
      echo -e "${white}11. M佬Tuic-v5一键脚本        15.OpenVPN一键安装脚本 ${re}"
      echo -e "${white}12. Brutal-Reality一键脚本    16.一键搭建TG代理 ${re}"
      echo -e "${white}17. 老王Reality一键脚本       18.sing-box面板(sui) ▶${re}"
      echo "---------------------------------------------------------" 
      echo -e "${skyblue} 0. 返回主菜单${re}"
      echo "---------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice   

      case $sub_choice in

        1)
        clear
            bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/sing-box/main/sing-box.sh)
            sleep 2
            break_end
        ;;
        2)
        clear
            bash <(curl -fsSL https://github.com/vveg26/sing-box-reality-hysteria2/raw/main/beta.sh)
            sleep 2
            break_end
        ;;
        3)
        clear
            bash <(curl -Ls https://gitlab.com/rwkgyg/sing-box-yg/raw/main/sb.sh)
            sleep 2
            break_end
        ;;
        4)
        clear
            install wget
            wget -N --no-check-certificate "https://raw.githubusercontent.com/mack-a/v2ray-agent/master/install.sh" && chmod 777 install.sh && bash install.sh
            sleep 2
            break_end
        ;;
        5)
        clear
            bash <(wget -qO- https://raw.githubusercontent.com/fscarmen/argox/main/argox.sh)
            sleep 2
            break_end
        ;;
        6)
        clear
            curl https://www.baipiao.eu.org/suoha.sh -o suoha.sh && bash suoha.sh
            sleep 2
            break_end            
        ;;            
        7)
        clear
            bash <(curl -sL https://raw.githubusercontent.com/dsadsadsss/vps-argo/main/install.sh)
            sleep 1
            break_end            
        ;; 
        8)
        clear
            # 检查系统中是否安装screen
            if command -v screen &>/dev/null; then
                echo -e "${green}Screen已经安装${re}"
            else
                # 如果系统中未安装screen，则根据对应系统安装
                install screen
            fi   

            # 检查系统中是否存在nodejs
            install_nodejs       
            # 提示输入订阅端口
            echo -e "${yellow}注意：NAT小鸡需输入指定端口范围内的端口，否则无法使用订阅功能${re}"
            while true; do
                read -p $'\033[1;35m请输入节点订阅端口: \033[0m' port

                if [[ $port =~ ^[0-9]+$ ]]; then
                    # 检查输入是否为正整数
                    if [ "$port" -gt 0 ] 2>/dev/null; then
                        # 输入有效，跳出循环
                        break
                    else
                        echo -e "${red}端口输入错误，端口应为数字且为正整数${re}"
                    fi
                else
                    echo -e "${red}端口输入错误，端口应为数字且为正整数${re}"
                fi
            done

            echo -e "${yellow}正在开放端口中...${re}"
                open_port() {
                    if command -v iptables &> /dev/null; then
                        iptables -A INPUT -p tcp --dport $port -j ACCEPT
                        echo -e "${green}${port}端口已开放${re}"
                    else
                        echo "iptables未安装，尝试安装..."
                        
                        install iptables

                        if [ $? -eq 0 ]; then
                            clear
                            echo -e "${green}iptables安装成功${re}"
                            iptables -A INPUT -p tcp --dport $port -j ACCEPT
                            echo -e "${green}${port}端口已开放${re}"
                        else
                            echo -e "${red}iptables安装失败，尝试关闭防火墙${re}"
                            sudo systemctl stop ufw.service && sudo systemctl disable ufw.service && (sudo ufw status | grep -q 'Status: inactive' && echo "防火墙已关闭成功" || echo "防火墙已关闭失败，请手动关闭")
                        fi
                    fi
                }
                open_port

            ipv4=$(curl -s ipv4.ip.sb)

            echo -e "${green}你的节点订阅链接为：http://$ipv4:$port/sub${re}" 

            # 判断是否要安装哪吒
            read -p $'\033[1;33m是否需要一起安装哪吒探针？(y/n): \033[0m' nezha

            if [ "$nezha" == "y" ] || [ "$nezha" == "Y" ]; then

                # 提示输入哪吒域名
                read -p $'\033[1;35m请输入哪吒客户端的域名: \033[0m' nezha_server

                # 提示输入哪吒端口
                read -p $'\033[1;35m请输入哪吒端口: \033[0m' nezha_port 

                # 提示输入哪吒密钥
                read -p $'\033[1;35m请输入哪吒客户端密钥: \033[0m' nezha_key
                [ -d "node" ] || mkdir -p "node" && cd "node"
                curl -O https://raw.githubusercontent.com/eooce/ssh_tool/main/index.js && curl -O https://raw.githubusercontent.com/eooce/nodejs-argo/main/package.json && npm install && chmod +x index.js && PORT=$port NEZHA_SERVER=$nezha_server NEZHA_PORT=$nezha_port NEZHA_KEY=$nezha_key CFIP=na.ma CFPORT=8443 screen node index.js
            
            else

                curl -O https://raw.githubusercontent.com/eooce/ssh_tool/main/index.js && curl -O https://raw.githubusercontent.com/eooce/nodejs-argo/main/package.json && npm install && chmod +x index.js && PORT=$port CFIP=na.ma CFPORT=8443 screen node index.js
            fi
        ;;
        9)
        clear
            read -p $'\033[1;35m请输入Hysteria2节点端口(nat小鸡请输入可用端口范围内的端口),回车跳过则使用随机端口：\033[0m' port
            [[ -z $port ]]
            until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
                if [[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
                    echo -e $'\033[1;91m${port}端口已经被其他程序占用，请更换端口重试！\033[0m'
                    read -p "设置 Hysteria2 端口[1-65535]（回车将使用随机端口）：" port
                    [[ -z $HY2_PORT ]] && port=8880
                fi
            done

            HY2_PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/xray-reality/master/Hysteria2.sh)"
            sleep 2
            break_end
        ;;     
        10)
        clear
            install wget && wget -N https://raw.githubusercontent.com/Misaka-blog/juicity-script/main/juicity.sh && bash juicity.sh
            sleep 2
            break_end
        ;;   
        11)
        clear
            install wget && wget -N --no-check-certificate https://gitlab.com/Misaka-blog/tuic-script/-/raw/main/tuic.sh && bash tuic.sh
            sleep 2
            break_end
        ;;      

        12)
        clear
            echo ""
            echo -e "${purple}安装Tcp-Brutal-Reality需要内核高于5.8，不符合请手动升级5.8内核以上再安装${re}" 

            current_kernel_version=$(uname -r | cut -d'-' -f1 | awk -F'.' '{print $1 * 100 + $2}')
            target_kernel_version=508

            # 比较内核版本
            if [ "$current_kernel_version" -lt "$target_kernel_version" ]; then
                echo -e "${red}当前系统内核版本小于 $target_kernel_version，请手动升级内核后重试，正在退出...${re}"
                sleep 2 
                main_menu
            else
                echo ""
                echo -e "${green}当前系统内核版本 $current_kernel_version，符合安装要求${re}"
                sleep 1
                bash <(curl -fsSL https://github.com/vveg26/sing-box-reality-hysteria2/raw/main/tcp-brutal-reality.sh)
                sleep 2
                break_end
            fi

        ;;

        13)
        clear
            bash <(curl -Ls https://raw.githubusercontent.com/slobys/x-ui/main/install.sh)
            sleep 2
            break_end
        ;; 
        14)
        clear
            bash <(curl -Ls https://raw.githubusercontent.com/mhsanaei/3x-ui/master/install.sh)
            sleep 2
            break_end
        ;;           
        15)
        clear
            install wget && wget https://git.io/vpn -O openvpn-install.sh && bash openvpn-install.sh
            sleep 2
            break_end
        ;;   

        16)
        clear
            
            echo "自動創建TG代理目錄：/home/mtproxy"
            mkdir /home/mtproxy && cd /home/mtproxy

            curl -s -o mtproxy.sh https://raw.githubusercontent.com/sunpma/mtp/master/mtproxy.sh && chmod +x mtproxy.sh && bash mtproxy.sh
            sleep 2
            break_end
        ;;

        17)
        clear
            read -p $'\033[1;35m请输入reality节点端口(nat小鸡请输入可用端口范围内的端口),回车跳过则使用随机端口：\033[0m' port
            [[ -z $port ]]
            until [[ -z $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; do
                if [[ -n $(ss -tunlp | grep -w udp | awk '{print $5}' | sed 's/.*://g' | grep -w "$port") ]]; then
                    echo -e $'\033[1;91m${port}端口已经被其他程序占用，请更换端口重试！\033[0m'
                    read -p "设置 reality 端口[1-65535]（回车将使用随机端口）：" port
                    [[ -z $PORT ]] && port=$(shuf -i 2000-65000 -n 1)
                fi
            done

            PORT=$port bash -c "$(curl -L https://raw.githubusercontent.com/eooce/xray-reality/master/reality.sh)"
            sleep 2
            break_end
        ;; 

        18)
        while true; do
        clear
          echo -e "${skyblue}▶ Sui面板${re}"
          echo "--------------"
          echo -e "${green}1.安装sui面板${re}"
          echo -e "${red}2.卸载sui面板${re}"
          echo "--------------"
          echo -e "${skyblue}0. 返回上一级菜单${re}"
          echo "--------------"
          read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
            case $sub_choice in
                1)
                    bash <(curl -Ls https://raw.githubusercontent.com/Misaka-blog/s-ui/master/install.sh)
                    sleep 2
                    echo ""
                    break_end

                    ;;
                2)
                    systemctl disable sing-box --now
                    systemctl disable s-ui --now

                    rm -f /etc/systemd/system/s-ui.service
                    rm -f /etc/systemd/system/sing-box.service
                    systemctl daemon-reload

                    rm -fr /usr/local/s-ui
                    clear
                    echo -e "${green}sui面板已卸载${re}"
                    break_end

                    ;;
                0)
                    break

                    ;;
                *)
                    echo -e "${red}无效的输入!${re}"
                    ;;
            esac  
        done
        ;;
        0)
            main_menu # 返回主菜单
        ;;

        *)
        break  # 跳出循环，退出菜单
        ;;
      esac
    done
    ;; 

  13)
    while true; do
      clear
      echo "▶ 测试脚本合集"
      echo "------------------------"
      echo "1. ChatGPT解锁状态检测"
      echo "2. Region流媒体解锁测试"
      echo "3. yeahwu流媒体解锁检测"
      echo "4. besttrace三网回程延迟路由测试"
      echo "5. mtr_trace三网回程线路测试"
      echo "6. Superspeed三网测速"
      echo "7. yabs性能带宽测试"
      echo "8. bench性能测试"
      echo "------------------------"
      echo -e "9. spiritysdx融合怪测评 \033[33mNEW\033[0m"
      echo "------------------------"
      echo -e "${skyblue}0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
              ;;
          2)
              clear
              bash <(curl -L -s check.unlock.media)
              ;;
          3)
              clear
              install wget
              wget -qO- https://github.com/yeahwu/check/raw/main/check.sh | bash
              ;;
          4)
              clear
              install wget
              wget -qO- git.io/besttrace | bash
              ;;
          5)
              clear
              curl https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
              ;;
          6)
              clear
              bash <(curl -Lso- https://git.io/superspeed_uxh)
              ;;
          7)
              clear
              curl -sL yabs.sh | bash -s -- -i -5
              ;;
          8)
              clear
              curl -Lso- bench.sh | bash
              ;;
          9)
              clear
              curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
              ;;
          0)
              main_menu

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;


  14)
     while true; do
      clear
      echo -e "${green}▶ 甲骨文云脚本合集${re}"
      echo "------------------------"
      echo -e "${green}1. 安装闲置机器活跃${yellow}[Docker版]${re}"
      echo -e "${green}2. 卸载闲置机器活跃${re}"
      echo "------------------------"
      echo -e "${purple}3. 一键DD重装系统${re}"
      echo "------------------------"
      echo -e "${green}4. 一键R探长刷机${re}"
      echo -e "${red}5. 卸载R探长刷机${re}"
      echo "------------------------"
      echo -e "${green}6. 开启ROOT密码登录模式${re}"
      echo -e "${green}7. 一键锻炼${re}"
      echo "------------------------"
      echo -e "${skyblue}0. 返回主菜单${re}"
      echo "------------------------"
      read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

      case $sub_choice in
          1)
              clear
              echo "活跃脚本: CPU占用10-20% 内存占用15% "
              read -p "确定安装吗？(Y/N): " choice
              case "$choice" in
                [Yy])

                  install_docker

                  docker run -itd --name=lookbusy --restart=always \
                          -e TZ=Asia/Shanghai \
                          -e CPU_UTIL=10-20 \
                          -e CPU_CORE=1 \
                          -e MEM_UTIL=15 \
                          -e SPEEDTEST_INTERVAL=120 \
                          fogforest/lookbusy
                  ;;
                [Nn])

                  ;;
                *)
                  echo "无效的选择，请输入 Y 或 N。"
                  ;;
              esac
              ;;
          2)
              clear
              docker rm -f lookbusy
              docker rmi fogforest/lookbusy
              ;;

          3)
          clear
          echo "请备份数据，将为你重装系统，预计花费15分钟。"
          read -p "确定继续吗？(Y/N): " choice

          case "$choice" in
            [Yy])
              while true; do
                read -p "请选择要重装的系统:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

                case "$sys_choice" in
                  1)
                    xitong="-d 12"
                    break  # 结束循环
                    ;;
                  2)
                    xitong="-u 20.04"
                    break  # 结束循环
                    ;;
                  *)
                    echo "无效的选择，请重新输入。"
                    ;;
                esac
              done

              read -p "请输入你重装后的密码: " vpspasswd
              install wget
              bash <(wget --no-check-certificate -qO- 'https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh') $xitong -v 64 -p $vpspasswd -port 22
              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
              ;;

          4)
              clear  
              echo -e "${purple}温馨提醒：自动抢机属于官方禁止行为，可能会造成封号现象，如因刷机造成封号，与本人无关！\n开始执行此任务前请确认以下3步是否操作完成。${re}"
              echo ""
              echo -e "${yellow}1：请确保你的服务器${purple}9527端口${yellow}可用，故此一键开机也不适合nat小鸡${re}"
              echo ""
              echo -e "${yellow}2：获取R探长机器人对应的${purple}username和password，${yellow}机器人获取链接https://t.me/radiance_helper_bot，使用/raninfo命令随机生成${re}"
              echo ""
              echo -e "${yellow}3：获取甲骨文云${purple}api密钥${yellow}下载文件并复制内容保存，获取方式在甲骨文云控制台右上角头像--我的概要信息里${re}"
              echo ""
              read -p $'\033[1;91m确定要继续吗？[y/n]: \033[0m' confirm
              echo ""

                if [[ $confirm =~ ^[Yy]$ ]]; then
                    echo -e "${yellow}开安装依赖...${re}"
                    install iptables wget nano
                    install_java
                    iptables -A INPUT -p tcp --dport 9527 -j ACCEPT
                    mkdir -p rtbot && cd rtbot
                    # 下载、解压、设置权限并后台运行 sh_client_bot.sh
                    wget -O gz_client_bot.tar.gz https://github.com/semicons/java_oci_manage/releases/latest/download/gz_client_bot.tar.gz
                    tar -zxvf gz_client_bot.tar.gz --exclude=client_config
                    tar -zxvf gz_client_bot.tar.gz --skip-old-files client_config
                    chmod +x sh_client_bot.sh client_config
                    bash sh_client_bot.sh &
                    clear 

                    while true; do
                        pid_tail=$(ps aux | grep '[t]ail' | awk '{print $2}')
                        pid_java=$(ps aux | grep '[j]ava' | grep -v 'grep' | awk '{print $2}')

                        tail_running=true
                        java_running=true

                        if [ ! -z "$pid_tail" ]; then
                            kill $pid_tail
                            echo -e "${green}已结束PID为${pid_tail}的tail进程。${re}"
                            tail_running=false
                        fi

                        if [ ! -z "$pid_java" ]; then
                            kill $pid_java
                            echo -e "${green}已结束PID为${pid_java}的java进程。${re}"
                            java_running=false
                        fi

                        if [ "$tail_running" = false ] && [ "$java_running" = false ]; then
                            break
                        fi

                        sleep 5
                    done
                    sleep 2
                    clear
                    echo ""
                    echo -e "${red}等待完成以下步骤,请完成后再确认${re}"
                    echo ""
                    echo -e "${yellow}1：获取R探长机器人对应的${purple}username和password，${yellow}机器人获取链接https://t.me/radiance_helper_bot${re}"
                    echo ""
                    echo -e "${yellow}2：获取甲骨文云${purple}api密钥下载文件并复制内容保存，${yellow}获取方式在甲骨文云控制台右上角头像--我的概要信息里${re}"
                    echo ""
                    echo -e "${yellow}3：将甲骨文云api密钥文件上传至root目录内，并复制文件路径保存，api密钥最后一行的路径改为此路径${re}"
                    echo ""                    
                    read -p $'\033[1;91m是否已完成以上步骤？[y/n]: \033[0m' confirm
                        sleep 1
                        if [[ $confirm =~ ^[Yy]$ ]]; then
                            # 使用 nano 编辑器打开文件
                            chmod +x /root/rtbot/client_config
                            echo ""
                            echo -e "${purple}即将打开/root/rtbot/client_config配置文件进行编辑。${re}"
                            echo ""
                            echo -e "${purple}键盘上下键定位，将api密钥(注意最后一行的路径)，username，password粘贴到指定位置${re}"
                            echo ""
                            echo -e "${purple}编辑完成后，请按顺序输入命令(Ctrl+O, Enter, Ctrl+X)保存退出${re}"
                            sleep 2
                            echo ""
                            read -p $'\033[1;91m是否清楚以上步骤？[y/n]: \033[0m' confirm

                            if [[ $confirm =~ ^[Yy]$ ]]; then
                                sleep 1
                                nano "/root/rtbot/client_config"
                                echo -e "${green}client_config配置更新成功。${re}"
                                sleep 1
                                echo -e "${green}开始执行抢机...${re}"
                                bash sh_client_bot.sh
                                sleep  3
                                echo -e "${green}正在后台执行抢机中，可关闭SSH，开机成功会在R探长bot上提醒...${re}"
                                sleep  3
                                main_menu
                            else 
                                echo -e "${yellow}请重新执行，正在退出...${re}"
                                sleep 1
                                rm -rf /root/rtbot
                                main_menu
                            fi
                        else 
                            echo -e "${yellow}已取消操作，正在退出...${re}"
                            rm -rf /root/rtbot
                            sleep 2
                            main_menu

                        fi
                else 
                    echo -e "${yellow}已取消操作，正在退出...${re}"
                    sleep 2
                    main_menu
                fi
              ;;

          5)
              clear
              ps -ef | grep r_client.jar | grep -v grep | awk '{print $2}' | xargs kill -9
              rm -rf /root/rtbot
              echo -e "${green}卸载完毕...${re}"
              break_end
              ;;

          6)
              clear
              read -p $'\033[1;33m请设置ROOT密码: \033[0m' pswd
              echo "root:$pswd" | chpasswd
              sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
              sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
              service sshd restart
              echo "ROOT登录设置完毕！"
              read -p $'\033[1;33m需要重启服务器吗？(y/n): \033[0m' choice
          case "$choice" in
            [Yy])
              reboot
              ;;
            [Nn])
              echo "已取消"
              ;;
            *)
              echo "无效的选择，请输入 Y 或 N。"
              ;;
          esac
              ;;

          7)
              clear
              curl -L https://gitlab.com/spiritysdx/Oracle-server-keep-alive-script/-/raw/main/oalive.sh -o oalive.sh && chmod +x oalive.sh && bash oalive.sh
              ;;              
          0)
              main_menu

              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      break_end

    done
    ;;


  15)
    while true; do
        clear
       echo -e "${skyblue}▶ 常用环境管理${re}"
        echo "------------------------"
        echo -e "${green}1. 一键安装Python最新版${re}"
        echo -e "${green}2. 一键安装Nodejs最新版${re}"
        echo -e "${green}3. 一键安装Golang最新版${re}"
        echo -e "${green}4. 一键安装Java最新版${re}"
        echo "------------------------"
        echo -e "${red}5. 一键卸载Python${re}"
        echo -e "${red}6. 一键卸载Nodejs${re}"
        echo -e "${red}7. 一键卸载Golang${re}"
        echo -e "${red}8. 一键卸载Java${re}"
        echo "------------------------"
        echo -e "${skyblue}0. 返回主菜单${re}"
        echo "------------------------"
        read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

        case $sub_choice in
            1)
             clear
                # 获取系统信息
                OS=$(grep -o -E "Debian|Ubuntu|CentOS|Alpine|Fedora|Rocky|AlmaLinux|Amazon" /etc/os-release 2>/dev/null | head -n 1)

                # 检查系统支持性
                if [[ -n $OS ]]; then
                    echo -e "${green}检测到你的系统是${yellow}${OS}${re}"
                else
                    echo -e "${red}很抱歉，暂不支持的系统！${re}"
                    sleep 2
                    main_menu
                fi

                # 检测安装Python3的版本
                VERSION=$(python3 -V 2>&1 | awk '{print $2}')

                # 获取最新Python3版本
                PY_VERSION=$(curl -s https://www.python.org/ | grep "downloads/release" | grep -o 'Python [0-9.]*' | grep -o '[0-9.]*')

                # 卸载Python3旧版本
                if [[ $VERSION == "3"* ]]; then
                    if [ "$VERSION" = "$PY_VERSION" ]; then
                        echo -e "${green}检测到你的Python3版本已经是最新版本:${red}${PY_VERSION}${green}，无需安装或升级${re}"
                        sleep 2
                        main_menu
                    else
                        echo -e "${yellow}检测到你的Python3版本:${red}${VERSION}${yellow},最新版本:${green}${PY_VERSION}${re}"
                        read -p $'\033[1;91m是否确认升级最新版Python3？[y/n]: \033[0m' confirm
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            if [[ $OS == "CentOS" ]]; then
                                yum remove python3 -y
                                package-cleanup --leaves
                                package-cleanup --orphans
                                yum autoremove -y
                                rm-rf /usr/local/python3* >/dev/null 2>&1
                                
                            elif [[ $OS == "Alpine" ]]; then
                                apk del python3
                                apk info --installed | xargs apk info --installed -R | cut -d: -f1 | sort | uniq -c | sort -n | grep -v ' 1 ' | awk '{print $2}' | xargs apk del
                                rm -rf /usr/lib/python3.*
                                rm -rf /etc/python3
                                rm -rf /var/cache/apk/*
                                    
                            elif [[ $OS == "Fedora" ]] || [[ $OS == "Rocky" ]] || [[ $OS == "AlmaLinux" ]] || [[ $OS == "Amazon" ]]; then
                                dnf remove python3 -y
                                dnf autoremove -y
                                rm -rf ~/.local/lib/python3.*                  
                            else
                                apt --purge remove python3 python3-pip -y
                                rm-rf /usr/local/python3*
                            fi
                        else
                            echo -e "${yellow}已取消升级Python3${re}"
                            sleep 1
                            main_menu
                        fi
                    fi   
                else
                    echo -e "${red}检测到没有安装Python3。${re}"
                    read -p $'\033[1;91m是否确认安装最新版Python3？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        echo -e "${green}开始安装最新版Python3...${re}"
                    else
                        echo -e "${yellow}已取消安装Python3${re}"
                        exit 1
                    fi
                fi

                # 安装相关依赖
                if [[ $OS == "CentOS" ]]; then
                    yum update -y
                    yum groupinstall -y "development tools"
                    yum install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y
                elif [[ $OS == "Fedora" ]] || [[ $OS == "Rocky" ]] || [[ $OS == "AlmaLinux" ]] || [[ $OS == "Amazon" ]]; then
                    dnf update -y
                    dnf groupinstall -y "development tools"
                    dnf install wget tar openssl-devel bzip2-devel libffi-devel zlib-devel -y
                elif [[ $OS == "Alpine" ]]; then
                    apk update
                    apk add python3
                    apk add py3-pip
                    apk add wget tar openssl-dev bzip2-dev libffi-dev zlib-dev
                    sleep 2
                    break_end
                    exit 1
                else
                    apt update -y
                    apt install wget tar build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev -y
                fi
                
                # 安装python3
                install wget tar
                cd /root/
                wget https://www.python.org/ftp/python/${PY_VERSION}/Python-"$PY_VERSION".tgz
                tar -zxf Python-${PY_VERSION}.tgz
                cd Python-${PY_VERSION}
                ./configure --prefix=/usr/local/python3
                make -j $(nproc)
                make install
                if [ $? -eq 0 ];then
                    rm -f /usr/local/bin/python3*
                    rm -f /usr/local/bin/pip3*
                    ln -sf /usr/local/python3/bin/python3 /usr/bin/python3
                    ln -sf /usr/local/python3/bin/pip3 /usr/bin/pip3
                    clear
                    echo -e "${yellow}Python3安装${green}成功，${re}版本为: ${re}${green}${PY_VERSION}${re}"
                    sleep 2
                else
                    clear
                    echo -e "${red}Python3安装失败！${re}"
                    exit 1
                fi
                cd /root/ && rm -rf Python-${PY_VERSION}.tgz && rm -rf Python-${PY_VERSION}
            ;;

            2)
             clear
                # 检查系统中是否存在nodejs
                if command -v node &>/dev/null; then
                    # 获取当前nodejs版本
                    current_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')

                    # 获取最新nodejs版本
                    install jq
                    json_data=$(curl -s https://nodejs.org/dist/index.json)
                    latest_version=$(echo "$json_data" | jq -r '.[] | select(.lts != null) | .version' | head -n 1 | sed 's/^v//')
                    # echo "$latest_version"
                    if [ "$current_version" = "$latest_version" ]; then
                        echo -e "${yellow}当前版本${green}$current_version${yellow}已经是最新版${green}${latest_version}${yellow}，无需更新！${re}"
                        sleep 2
                        main_menu
                    else
                        # 如果不是最新版本
                        echo -e "${yellow}你的nodejs版本是${re}${red}${current_version}${re}，${yellow}最新版本是${purple}${latest_version}${re}"                                 
                        read -p $'\033[1;91m是否卸载旧版nodejs并安装最新版？[y/n]: \033[0m' confirm
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                                                       
                            remove nodejs
                            sleep 1

                            # 安装新版nodejs
                            install_nodejs
                        else
                            main_menu 
                        fi
                    fi

                else
                    install_nodejs
                fi           
                
            ;;

            3)
            clear
                # 获取最新版Go的版本
                html=$(curl -s https://go.dev/dl/)
                latest_version=$(echo "$html" | grep -oP 'go[0-9]+\.[0-9]+(\.[0-9]+)?' | head -1)    

                # 根据系统架构选择不同的下载链接
                architecture=$(uname -m)
                case "$architecture" in
                    x86_64|amd64)
                        latest_version_url="https://golang.org/dl/${latest_version}.linux-amd64.tar.gz"
                        ;;
                    x86)
                        latest_version_url="https://golang.org/dl/${latest_version}.linux-386.tar.gz"
                        ;;
                    arm64|aarch64)
                        latest_version_url="https://golang.org/dl/${latest_version}.linux-arm64.tar.gz"
                        ;;
                    *)
                        echo -e "${red}暂不支持的系统架构：$architecture${re}"
                        sleep 2
                        main_menu
                        ;;
                esac

                # 检查是否已安装Go
                if command -v go &> /dev/null; then
                    # 获取当前已安装的Go版本
                    installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+')
                    echo -e "${yellow}当前已安装的Go版本：${red}$installed_version${re}"

                    # 比较已安装版本与最新版本
                    if [ "$installed_version" = "$latest_version" ]; then
                        echo -e "${green}当前Go已经是最新版本，无需更新。${re}"
                        sleep 2
                        main_menu

                    elif [ "$(printf "$installed_version\n$latest_version" | sort -V | head -n 1)" != "$installed_version" ]; then
                        echo -e "${yellow}发现新版本：$latest_version。${re}"
                        read -p $'\033[1;91m需要卸载当前版本 $installed_version 并安装新版本 $latest_version 吗 [y/n]: \033[0m' confirm
                        
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            echo "卸载旧版Go：$installed_version"
                            rm -rf /usr/local/go

                        else
                            echo -e "${yellow}退出更新。${re}"
                            sleep 2
                            break_end
                        fi
                    fi
                else
                    echo -e "${yellow}系统中未安装Go，正在为你安装最新版Go...${re}"
                fi
              # 下载并安装最新版Go
              install tar
              wget -O go_latest.tar.gz "$latest_version_url"
              tar -C /usr/local -xzf go_latest.tar.gz

              # 设置环境变量
              export GOPATH=$HOME/go
              export PATH=$PATH:$GOPATH/bin
              export PATH=$PATH:/usr/local/go/bin
              source ~/.bashrc
              source ~/.profile
              source ~/.bash_profile
              rm go_latest.tar.gz
              echo -e "${green}GO安装完成，当前Go版本：${red}$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' | cut -c 3-)${re}"
              sleep 1
              break_end
            ;;            

            4)
              clear
                latest_version="17.0.10"
                if command -v java &>/dev/null; then
                    installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
                    echo -e "${green}当前Java版本是${yellow}${installed_version},最新版本是${green}${latest_version}${re}"

                    if [ "$installed_version" == "$latest_version" ]; then
                        echo -e "${green}当前已安装Java最新版：${yellow}${latest_version},无需更新${re}"
                        sleep 2
                        main_menu
                    else
                        echo -e "${red}"
                        read -p "是否卸载旧版java并安装最新版？[y/n]: " confirm
                        if [[ $confirm =~ ^[Yy]$ ]]; then
                            # 卸载旧版java
                            remove java
                            sleep 2
                            install_java                           

                        else
                            main_menu 
                        fi   
                    fi

                else
                    install_java
                fi
            ;;

            5)
             clear
                if command -v python3 &>/dev/null; then
                    # 获取当前安装的python版本
                    current_version=$(python3 --version 2>&1 | awk '{print $2}')   

                    echo -e "${yellow}当前已安装python${red}${current_version}"

                    read -p $'\033[1;91m确定卸载python？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                    
                        # 卸载python3
                        remove python3

                        # 清理缓存配置文件
                        rm -rf /usr/bin/pip3
                        rm -rf /usr/bin/python3
                        rm -rf /usr/share/python3
                        rm -rf /usr/local/python3
                        rm -rf /usr/share/man/man1/python3.1.gz
                        rm -rf /usr/local/bin/python
                        rm -rf /usr/local/lib/python*
                        rm -rf /usr/local/bin/python*

                        echo -e "${green}python已卸载${re}"
                        break_end
                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装python，无需卸载${re}"
                    sleep 2
                    main_menu
                fi           
            ;;

            6)
             clear
                if command -v node &>/dev/null; then
                    # 获取当前安装的nodjs版本
                    current_version=$(node --version | grep -oE '[0-9]+\.[0-9]+\.[0-9]+')    

                    echo -e "${yellow}当前已安装nodejs${red}$current_version${re}"
                            
                    read -p $'\033[1;91m确定卸载nodejs？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        
                        # 卸载
                        remove nodejs npm 
         
                        # 清理缓存配置文件
                        rm -rf ~/.npm
                        rm -rf ~/.nvm
                        rm -rf /usr/local/bin/node
                        rm -rf /usr/local/lib/node_modules

                        echo -e "${green}nodejs已卸载${re}"
                        break_end
                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装nodejs，无需卸载${re}"
                    sleep 2
                    main_menu
                fi           
            ;;

            7)
             clear
                if command -v go &> /dev/null; then
                    # 获取当前安装的Go版本
                    installed_version=$(go version | grep -oE 'go[0-9]+\.[0-9]+\.[0-9]+' | cut -c 3-)   

                    echo -e "${yellow}当前已安装Go：${red}$installed_version${re}"
                            
                    read -p $'\033[1;91m确定卸载Go？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                        rm -rf /usr/local/go

                        # 清理环境变量
                        export PATH=$PATH:/usr/local/go/bin
                        export GOPATH=$HOME/go
                        export PATH=$PATH:$GOPATH/bin
                        source ~/.bashrc && source ~/.profile && source ~/.bash_profile

                        echo -e "${green}Go已卸载${re}"
                        sleep 1
                        break_end

                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装Go，无需卸载${re}"
                    sleep 2
                    main_menu
                fi           
            ;;

            8)
             clear
                if command -v java &> /dev/null; then
                    # 获取当前安装的Java版本
                    installed_version=$(java -version 2>&1 | awk -F '"' '/version/ {print $2}')
                    echo -e "${yellow}你的Java版本：${red}${installed_version}${re}"

                    read -p $'\033[1;91m确定卸载Java？[y/n]: \033[0m' confirm
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                        remove_java() {
                            local remove_status=0

                            if command -v apt &>/dev/null; then
                                apt remove -y openjdk-17-jdk && apt autoremove -y openjdk-17-jdk
                            elif command -v yum &>/dev/null; then
                                yum remove -y java && yum autoremove -y java
                            elif command -v dnf &>/dev/null; then
                                dnf remove -y java && dnf autoremove -y java
                            elif command -v apk &>/dev/null; then
                                apk del openjdk17
                            else
                                echo -e "${red}暂不支持你的系统！${re}"
                                exit 1
                            fi
                            # 检查是否安装成功，如果没有成功则重新
                            if [ $remove_status -eq 0 ]; then
                                echo -e "${green}Java卸载成功！${re}"
                            else                    
                                echo -e "${red}Java卸载失败，请重试!${re}"
                                break_end
                            fi
                        }
                        remove_java

                        rm -rf /usr/lib/jvm/java-*
                        rm -rf /usr/local/java
                        rm -rf /opt/java
                        echo -e "${red}"
                        read -p $'\033[1;91m重启服务器配置才可生效，需要立即重启吗 [y/n]: \033[0m' confirm

                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            sleep 1
                            reboot
                        else
                            main_menu
                        fi

                    else
                        main_menu
                    fi
                else
                    echo -e "${yellow}系统中未安装Java，无需卸载${re}"
                    sleep 2
                fi           
            ;;

            0)
                main_menu
            ;;

            *)
            echo -e "${yellow}无效的输入!${re}"
            ;;
        esac
    done
    ;; 

  16)
    while true; do
        clear
        echo -e "${purple}▶ 管理NAT小鸡${re}"
        echo "------------------------"
        echo -e "${yellow}开设kvm小鸡分两步，请依次执行。 \n如果第一步失败，请选择其他方式开设小鸡。\n建议选择4或9，大部分vps都兼容！${re}"
        echo "------------------------"
        echo -e "${skyblue} 1. 开设KVM小鸡(第1步)${re}" 
        echo -e "${skyblue} 2. 开设KVM小鸡(第2步)${re}"
        echo -e "${red} 3. 删除所有KVM小鸡${re}"
        echo "------------------------"
        echo -e "${green} 4. 开设LXC小鸡(官方版)${re}" 
        echo -e "${green} 5. 开设LXC小鸡(魔改版)${re}" 
        echo -e "${skyblue} 6. 管理LXC小鸡 ▶${re}"
        echo "------------------------"
        echo -e "${green} 7. 开设Docker小鸡${re}"
        echo -e "${red} 8. 删除所有Docker容器${re}"
        echo "------------------------"
        echo -e "${green} 9. 开设incus小鸡(官方版)${re}" 
        echo -e "${skyblue}10. 管理incus小鸡 ▶${re}"
        echo "------------------------"
        echo -e "${skyblue} 0. 返回主菜单${re}"
        echo "------------------------"
        while :; do
            echo
            read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice
            if ! [[ "$sub_choice" =~ ^[0-9]+$ ]]; then
                echo -e "${red}输入错误, 请输入0~10的数字!${re}"
                continue
            fi
            if [ $sub_choice -ge 0 -a $sub_choice -le 12 ]; then
                break
            else
                echo -e "${red}输入错误, 请输入0~10的数字!${re}"   
            fi
        done
        case $sub_choice in 
            1)
                clear
                echo -e "${yellow}开始进行环境检测...${re}"
                install wget
                output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/check_kernal.sh))
                echo "$output"
                if echo "$output" | grep -q "CPU不支持硬件虚拟化，无法嵌套虚拟化KVM服务器，但可以开LXC服务器(CT)"; then
                    echo ""
                    echo -e "${red}你的服务器不支持开设KVM小鸡，建议选择4或9开设其他类型，正在退出...${re}"
                    rm -rf /root/check_kernal.sh
                    sleep 2
                    break_end

                elif echo "$output" | grep -q "本机符合要求：可以使用PVE虚拟化KVM服务器，并可以在开出来的KVM服务器选项中开启KVM硬件虚拟化"; then
                    echo -e "${green}本机符合开设kvm小鸡的要求${re}"
                    read -p $'\033[1;35m确定要开设kvm小鸡吗？ [y/n]: \033[0m' confirm
                    sleep 1
                    if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                        echo ""
                        echo ""
                        echo ""
                        echo -e "${yellow}开设虚拟内存(Swap),请先输入2移除原来的配置，会自动重新执行一次，再输入1添加虚拟内存${re}"
                        curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                        sleep 1
                        curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                        echo -e "${yellow}开始进行PVE主体安装${re}"
                        curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
                        sleep 1
                        echo -e "${yellow}请等待20秒后重启后运行第2步${re}"
                        read -p $'\033[1;96m需要立即重启吗？ [y/n]: \033[0m' confirm
                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then
                            sleep 1
                            reboot
                        else 
                            break_end
                        fi
                    else
                        echo -e "${yellow}已取消操作...${re}"
                        sleep 2
                        main_menu
                    fi

                elif echo "$output" | grep -q "宿主机的环境无apt包管理器命令，请检查系统"; then
                    echo ""
                    echo -e "${red}你的vps系统暂不支持，请更换Debian12或Ubuntu22.04后重试${re}"
                    sleep 3
                    main_menu
                else 
                    echo -e "${red}暂不能判定你的服务器状态，无法开设kvm小鸡，可以考虑使用LXC模式开小鸡，正在退出...${re}"
                    rm -rf /root/check_kernal.sh
                    sleep 3
                    main_menu
                fi
            ;;

            2)
                clear

                read -p $'\033[1;96m确认你已执行完第1步，是否继续 [y/n]: \033[0m' confirm
                if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                    sleep 1
                    curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
                    sleep 1
                    echo -e "${yellow}开始配置环境...${re}"
                    bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/build_backend.sh)
                    sleep 1
                    echo -e "${yellow}开始自动配置宿主机的网关...${re}"
                    bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/build_nat_network.sh)
                    sleep 1
                    echo -e "${yellow}KVM虚拟化开设出的虚拟机，默认生成的用户名不是root，请确保你已在root下运行及修改root密码${re}"

                    while true; do
                        read -p $'\033[1;96m你需要手动开设kvm小鸡还是批量开设kvm小鸡？(1：手动开设  2：自动批量开设) \033[0m' choose

                        if [ "$choose" == "1" ]; then
                            sleep 1
                            curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/buildvm.sh -o buildvm.sh && chmod +x buildvm.sh
                            sleep 2
                            echo -e "${purple}手动开设请执行以下命令，参数对照如下可自行修改${re}"
                            echo ""
                            echo -e "${purple}./buildvm.sh VMID 用户名 密码 CPU核数 内存 硬盘 SSH端口 80端口 443端口 外网端口起 外网端口止 系统 存储盘 独立IPV6地址(留空默认N)${re}"
                            echo -e "${purple}./buildvm.sh 102 test1 oneclick123 1 512 10 40001 40002 40003 50000 50025 debian11 local N${re}"
                            sleep 3
                            break_end
                            break  # 跳出循环
                        elif [ "$choose" == "2" ]; then
                            sleep 1
                            echo -e "${red}注意: KVM开设出的NAT小鸡，默认生成的用户名不是root，默认的root密码部分类型是${green}password${red},需要sudo -i手动切换为root${re}"
                            sleep 2
                            curl -L https://raw.githubusercontent.com/spiritLHLS/pve/main/scripts/create_vm.sh -o create_vm.sh && chmod +x create_vm.sh && bash create_vm.sh
                            sleep 2
                            break_end
                            break  # 跳出循环
                        else
                            echo -e "${red}输入错误，请输入1或2${re}"
                        fi
                    done
                else 
                    break_end
                fi
            ;;

            3)
                clear
                for vmid in $(qm list | awk '{if(NR>1) print $1}'); do qm stop $vmid; qm destroy $vmid; rm -rf /var/lib/vz/images/$vmid*; done
                iptables -t nat -F
                iptables -t filter -F
                service networking restart
                systemctl restart networking.service
                systemctl restart ndpresponder.service
                iptables-save | awk '{if($1=="COMMIT"){delete x}}$1=="-A"?!x[$0]++:1' | iptables-restore
                iptables-save > /etc/iptables/rules.v4
                rm -rf vmlog
                rm -rf vm*
                sleep 2
                break_end
            ;;

            4)
                clear
                echo -e "${yellow}开始进行环境检测...${re}"
                install wget 

                output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/pre_check.sh))
                echo "$output"
                if echo "$output" | grep -q "本机符合作为LXC母鸡的要求，可以批量开设LXC容器"; then
                    echo ""
                    echo -e "${green}你的vps已通过检测，可以开设LXC小鸡${re}"

                    read -p $'\033[1;35m确定要开设LXC小鸡吗？ [y/n]: \033[0m' confirm

                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                            echo -e "${yellow}开始进行安装LXD主体...${re}"
                            sleep 1
                            curl -L https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/lxdinstall.sh -o lxdinstall.sh && chmod +x lxdinstall.sh && bash lxdinstall.sh
                            sleep 3
                            # 检查LXD是否安装成功
                            check_lxc(){
                                if command lxc -h &> /dev/null; then
                                    echo -e "${green}LXD主体已安装完成${re}"
                                    # lxc --version 2>/dev/null
                                    sleep 1
                                    return 0
                                else
                                    echo -e "${yellow}lxc没有软连接上，正在为你修复...${re}"
                                    apt update -y
                                    ! lxc -h >/dev/null 2>&1 && echo 'alias lxc="/snap/bin/lxc"' >> /root/.bashrc && source /root/.bashrc
                                    export PATH=$PATH:/snap/bin

                                    if command lxc -h &> /dev/null; then
                                        sleep 1
                                        return 0
                                    else
                                        echo -e "${yellow}lxc没有软连接上，请重启系统后重新运行${re}"
                                        sleep 2
                                        main_menu
                                    fi
                                fi
                            }
                            check_lxc
                            while true; do
                                clear
                                echo ""
                                echo -e "${yellow}温馨提醒:如果你开设的小鸡数量较多建议reboot重启一次系统使配置生效，再进入管理LXC小鸡菜单${purple}新增即可${re}"
                                echo ""
                                read -p $'\033[1;35m选择哪种方式开设LXC小鸡？\n1:普通批量生成(256RAM+1G+上下行限制300Mb)  \n2:自定义配置批量生成  \n3:取消开小鸡 \n4:重启系统 \n请选择： \033[0m' confirm

                                case $confirm in
                                    1)
                                        echo -e "${green}开始运行普通版本批量生成小鸡${yellow}(1核256MB内存1GB硬盘限速300Mbit)${re}"
                                        sleep 1
                                        curl -L https://raw.githubusercontent.com/oneclickvirt/lxd/main/scripts/init.sh -o init.sh && chmod +x init.sh && dos2unix init.sh
                                        
                                        read -p $'\033[1;35m请输入你要生成小鸡的数量：\033[0m' number
                                        sleep 1
                                        install screen
                                        echo -e "${green}正在后台自动为你开设小鸡中，可关闭SSH，完成后运行cat log查看信息${re}"
                                        sleep 3
                                        screen bash init.sh lxc $number 
                                        sleep 3
                                        cat log
                                        break
                                        ;;
                                    2)
                                        echo -e "${green}开始运行自定义批量生成小鸡(自定义配置)${re}"
                                        sleep 1
                                        install screen
                                        echo -e "${green}输入配置后，自动进入后台生成小鸡(可直接关闭SSH连接，完成后运行cat log查看小鸡信息)${re}"
                                        sleep 3
                                        curl -L https://github.com/oneclickvirt/lxd/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh
                                        cat log
                                        break
                                        ;;
                                    3)
                                        echo -e "${yellow}你已取消了开设小鸡的操作${re}"
                                        exit 0
                                        ;;
                                    4)
                                        reboot
                                        ;;
                                    *)
                                        echo -e "${red}输入错误，请输入1~4${re}"
                                        ;;
                                esac
                            done

                        else
                            echo -e "${yellow}取消开设LXC小鸡，正在退出...${re}"
                            sleep 2
                            main_menu
                            
                        fi                        
                else
                    echo -e "${red}你的vps不符合开设LXC母鸡要求，请选择incus或Docker方式开设小鸡${re}"
                    sleep 3
                    main_menu
                fi
            ;;


            5)
                clear
                install wget
                wget -N --no-check-certificate https://raw.githubusercontent.com/eooce/lxdpro/main/lxdpro.sh && chmod +x lxdpro.sh && bash lxdpro.sh

                break_end
            
            ;;                   

            6)
              while true; do
                clear
                echo -e "${purple}▶ 管理LXC小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}1. 查看所有LXC小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}2. 暂停所有LXC小鸡${re}"
                echo -e "${skyblue}3. 启动所有LXC小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}4. 暂停指定LXC小鸡${re}"
                echo -e "${skyblue}5. 启动指定LXC小鸡${re}"
                echo -e "${skyblue}6. 给指定小鸡重装系统${re}"
                echo "------------------------"
                echo -e "${skyblue}7. 新增开设LXC小鸡${re}"
                echo -e "${red}8. 删除指定LXC小鸡${re}" 
                echo -e "${red}9. 删除所有LXC小鸡和配置${re}" 
                echo "------------------------"
                echo -e "${white}0. 返回上一级菜单${re}"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        echo -e "${green}所有LXC小鸡运行状态：${re}"
                        lxc list
                        echo -e "${green}所有LXC小鸡密码端口信息${re}"
                        cat log
                        break_end
                    ;;

                    2)
                        clear
                        lxc stop --all
                        break_end
                    ;;

                    3)
                        clear
                        lxc start --all
                        break_end
                    ;;

                    4)
                        clear
                        read -p $'\033[1;35m请输入要暂停的小鸡的名字（如ex1，nat1等）：\033[0m' nat
                        lxc stop $nat
                        info_output=$(lxc info $nat)

                        # 检查指定暂停的小鸡状态
                        if echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${green}已暂停${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${yellow}${nat}仍在运行，请重试${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi
                    ;;

                    5)
                        clear
                        read -p $'\033[1;35m请输入要启动的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        lxc start $nat
                        info_output=$(lxc info ${nat})

                        # 检查指定启动的小鸡状态
                        if echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${green}启动成功${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${yellow}${nat}暂停状态，请重新启动${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi

                    ;;

                    6)
                        clear
                        read -p $'\033[1;35m请输入要重装系统的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        lxc stop $nat && lxc rebuild images:debian/11 $nat
                        sleep 2
                        lxc start $nat
                        echo -e "${green}${nat}小鸡已重装系统完成${re}"
                        sleep 2
                        break_end
                    ;;

                    7)
                        read -p $'\033[1;35m确定要新增LXC小鸡吗？ [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            echo -e "${green}输入配置后将进入后台为你新增，可关闭SSH，完成后cat log查看信息${re}"
                            curl -L https://github.com/oneclickvirt/lxd/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh

                        else 
                            echo -e "${green}已取消${re}"
                            break_end
                        fi
                    ;;

                    8)
                        clear
                        read -p $'\033[1;35m请输入要删除的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        lxc delete -f $nat
                        sleep 2
                        echo -e "${green}${nat}小鸡已删除${re}"
                        sleep 2
                        break_end
                    ;;

                    9)
                        clear
                        read -p $'\033[1;35m删除后无法恢复，确定要继续删除所有Lxc小鸡吗 [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            lxc list -c n --format csv | xargs -I {} lxc delete -f {}

                            sudo find /var/log -type f -delete
                            sudo find /var/tmp -type f -delete
                            sudo find /tmp -type f -delete
                            sudo find /var/cache/apt/archives -type f -delete

                            # 删除配置
                            rm -rf /usr/local/bin/ssh_sh.sh
                            rm -rf /usr/local/bin/config.sh
                            rm -rf /usr/local/bin/ssh_bash.sh
                            rm -rf /usr/local/bin/check-dns.sh
                            rm -rf /root/ssh_sh.sh
                            rm -rf /root/config.sh
                            rm -rf /root/ssh_bash.sh
                            rm -rf /root/buildone.sh
                            rm -rf /root/add_more.sh
                            rm -rf /root/build_ipv6_network.sh

                            echo -e "${green}已删除所有Lxc小鸡${re}"
                            break_end
                        else 
                            echo -e "${green}已取消删除${re}"
                            break_end
                        fi    
                    ;;                    
                    
                    0)
                        break
                    ;;
                    *)
                        echo -e "${red}无效选择，请重新输入。${re}"
                    ;;
                esac
              done
            ;;

            7)
                clear
                echo -e "${yellow}开设虚拟内存(Swap),请先输入2移除原来的，会重新执行一次，再输入1添加虚拟内存${re}"
                curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                sleep 1
                curl -L https://raw.githubusercontent.com/spiritLHLS/addswap/main/addswap.sh -o addswap.sh && chmod +x addswap.sh && bash addswap.sh
                sleep 1
                echo -e "${yellow}开始安装docker配置环境${re}"
                curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/dockerinstall.sh -o dockerinstall.sh && chmod +x dockerinstall.sh && bash dockerinstall.sh
                sleep 2

                while true; do
                    read -p $'\033[1;96m你需要单独开设Docker小鸡还是批量开设Docker小鸡？(1：单个开设  2：批量开设 3：重启系统) \033[0m' choose

                    if [ "$choose" == "1" ]; then
                        sleep 1
                        install screen
                        curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/onedocker.sh -o onedocker.sh && chmod +x onedocker.sh && screen bash onedocker.sh
                        sleep 2
                        break_end
                        break  # 跳出循环
                    elif [ "$choose" == "2" ]; then
                        sleep 1
                        curl -L https://raw.githubusercontent.com/spiritLHLS/docker/main/scripts/create_docker.sh -o create_docker.sh && chmod +x create_docker.sh && screen bash create_docker.sh
                        sleep 2
                        break_end
                        break  # 跳出循环
                    elif  [ "$choose" == "3" ]; then
                        reboot
                    else
                        echo -e "${red}输入错误，请输入1或2${re}"
                    fi
                done
            ;;

            8)
                clear
                docker ps -aq --format '{{.Names}}' | grep -E '^ndpresponder' | xargs -r docker rm -f
                docker images -aq --format '{{.Repository}}:{{.Tag}}' | grep -E '^ndpresponder' | xargs -r docker rmi
                rm -rf dclog
                ls

                sleep 2
                break_end
            ;;

            9)
                clear
                echo -e "${yellow}开始进行环境检测...${re}"
                install wget 

                output=$(bash <(wget -qO- --no-check-certificate https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/pre_check.sh))
                echo "$output"
                if echo "$output" | grep -q "本机符合作为incus母鸡的要求，可以批量开设incus容器"; then

                    echo -e "${green}你的vps符合开设incus要求，可以开设incus小鸡${re}"

                    read -p $'\033[1;35m确定要开设incus小鸡吗？ [y/n]: \033[0m' confirm

                        if [ "$confirm" == "y" ] || [ "$confirm" == "Y" ]; then

                            echo -e "${yellow}开始进行安装incus主体...${re}"
                            sleep 1
                            curl -L https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/incus_install.sh -o incus_install.sh && chmod +x incus_install.sh && bash incus_install.sh
                            sleep 2
                            # 检查incus是否安装成功
                            check_incus(){
                                if which incus >/dev/null; then
                                    echo -e "${green}Incus主体已安装完成${re}"
                                    # incus --version 2>/dev/null
                                    sleep 1
                                    return 0
                                
                                else
                                    echo "Incus主体已安装失败，请更新系统后重试，正在清理缓存..."
                                    rm -rf /root/incus_install.sh
                                    sleep 2
                                    main_menu

                                fi
                            }

                            while true; do
                                clear
                                echo ""
                                echo -e "${yellow}温馨提醒:如果你开设的小鸡数量较多建议reboot重启一次系统使配置生效，再进入管理incus小鸡菜单${purple}新增即可${re}"
                                echo ""
                                read -p $'\033[1;35m选择哪种方式开设incus小鸡？\n1:普通批量生成(256RAM+1G+上下行300Mb)  \n2:自定义配置批量生成  \n3:取消开小鸡 \n4:重启系统 \n请选择： \033[0m' confirm

                                case $confirm in
                                    1)
                                        echo -e "${green}开始运行普通版本批量生成小鸡${yellow}(1核256MB内存1GB硬盘限速300Mbit)${re}"
                                        sleep 1
                                        curl -L https://raw.githubusercontent.com/oneclickvirt/incus/main/scripts/init.sh -o init.sh && chmod +x init.sh && dos2unix init.sh
                                        
                                        read -p $'\033[1;35m请输入你要生成小鸡的数量：\033[0m' number
                                        sleep 1
                                        install screen
                                        echo -e "${green}正在后台自动为你开设小鸡中，可关闭SSH，完成后运行cat log查看小鸡信息${re}"
                                        sleep 3
                                        screen bash init.sh nat $number 
                                        sleep 3
                                        cat log
                                        break
                                        ;;
                                    2)
                                        echo -e "${green}开始运行自定义批量生成小鸡${re}"
                                        sleep 1
                                        install screen
                                        echo -e "${green}正在后台自动为你开设小鸡中，可关闭SSH，完成后运行cat log查看小鸡信息${re}"
                                        sleep 3
                                        curl -L https://github.com/oneclickvirt/incus/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh
                                        cat log
                                        break
                                        ;;
                                    3)
                                        echo -e "${green}你已取消了开设小鸡的操作${re}"
                                        exit 0
                                        ;;
                                    4)
                                        reboot
                                        ;;
                                    *)
                                        echo -e "${red}输入错误，请输入 1至4的数字${re}"
                                        ;;
                                esac
                            done

                        else
                            echo -e "${yellow}取消开设incus小鸡，正在退出...${re}"
                            sleep 2
                            main_menu
                            
                        fi
                else
                    echo ""
                    echo -e "${red}你的vps不符合开设incus要求，请选择LXD或Docker方式开设小鸡${re}"
                    sleep 2
                    break_end
                fi
            ;;

            10)
              while true; do
                clear
                echo -e "${purple}▶ 管理incus小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}1. 查看所有incus小鸡运行状态${re}"
                echo "------------------------"
                echo -e "${skyblue}2. 暂停所有incus小鸡${re}"
                echo -e "${skyblue}3. 启动所有incus小鸡${re}"
                echo "------------------------"
                echo -e "${skyblue}4. 暂停指定incus小鸡${re}"
                echo -e "${skyblue}5. 启动指定incus小鸡${re}"
                echo -e "${skyblue}6. 给指定小鸡重装系统${re}"
                echo "------------------------"
                echo -e "${skyblue}7. 新增开设incus小鸡${re}"
                echo -e "${red}8. 删除指定incus小鸡${re}"
                echo -e "${red}9. 删除所有incus小鸡和配置${re}" 
                echo "------------------------"
                echo -e "${white}0. 返回上一级菜单${re}"
                echo "------------------------"
                read -p $'\033[1;91m请输入你的选择: \033[0m' sub_choice

                case $sub_choice in
                    1)
                        clear
                        echo -e "${green}所有incus小鸡运行状态：${re}"
                        incus list
                        echo -e "${green}所有incus小鸡密码端口信息${re}"
                        cat log
                        break_end
                    ;;

                    2)
                        clear
                        incus stop --all
                        break_end
                    ;;

                    3)
                        clear
                        incus start --all
                        break_end
                    ;;

                    4)
                        clear
                        read -p $'\033[1;35m请输入要暂停的小鸡的名字（如ex1，nat1等）：\033[0m' nat
                        incus stop $nat
                        info_output=$(incus info $nat)

                        # 检查指定暂停的小鸡状态
                        if echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${green}已暂停${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${yellow}${nat}仍在运行，请重试${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi
                    ;;

                    5)
                        clear
                        read -p $'\033[1;35m请输入要启动的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        incus start $nat
                        info_output=$(incus info ${nat})

                        # 检查指定启动的小鸡状态
                        if echo "$info_output" | grep -q "Status: RUNNING"; then
                            echo -e "${green}启动成功${nat}小鸡${re}"
                            sleep 2
                            break_end
                        elif echo "$info_output" | grep -q "Status: STOPPED"; then
                            echo -e "${yellow}${nat}暂停状态，请重新启动${re}"
                            sleep 2
                        else
                            echo -e "${red}未知${nat}状态${re}"
                            sleep 2
                        fi

                    ;;

                    6)
                        clear
                        read -p $'\033[1;35m请输入要重装系统的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        incus stop $nat && incus rebuild images:debian/11 $nat
                        sleep 2
                        incus start $nat
                        echo -e "${green}${nat}小鸡已重装系统完成${re}"
                        sleep 2
                        break_end
                    ;;
                    7)
                        read -p $'\033[1;35m确定要新增incus小鸡吗？ [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            echo -e "${green}输入配置后将进入后台为你新增incus小鸡，可关闭SSH，完成后cat log查看信息${re}"
                            curl -L https://github.com/oneclickvirt/incus/raw/main/scripts/add_more.sh -o add_more.sh && chmod +x add_more.sh && screen bash add_more.sh
                            cat log
                        else 
                            echo -e "${green}已取消${re}"
                            break_end
                        fi
                    ;;
                    8)
                        clear
                        read -p $'\033[1;35m请输入要删除的小鸡的名字（如ex1，nat1等）: \033[0m' nat
                        incus delete -f $nat
                        sleep 2
                        echo -e "${green}${nat}小鸡已删除${re}"
                        sleep 2
                        break_end
                    ;;

                    9)
                        clear
                        read -p $'\033[1;35m删除后无法恢复，确定要继续删除所有incus小鸡吗 [y/n]: \033[0m' confirm

                        if [[ "$confirm" =~ ^[Yy]$ ]]; then   
                            incus list -c n --format csv | xargs -I {} incus delete -f {}

                            sudo find /var/log -type f -delete
                            sudo find /var/tmp -type f -delete
                            sudo find /tmp -type f -delete
                            sudo find /var/cache/apt/archives -type f -delete

                            # 删除配置
                            rm -rf /usr/local/bin/ssh_sh.sh
                            rm -rf /usr/local/bin/config.sh
                            rm -rf /usr/local/bin/ssh_bash.sh
                            rm -rf /usr/local/bin/check-dns.sh
                            rm -rf /root/ssh_sh.sh
                            rm -rf /root/config.sh
                            rm -rf /root/ssh_bash.sh
                            rm -rf /root/buildone.sh
                            rm -rf /root/add_more.sh
                            rm -rf /root/build_ipv6_network.sh

                            echo -e "${green}已删除所有incus小鸡${re}"
                            break_end
                        else 
                            echo -e "${green}已取消删除${re}"
                            break_end
                        fi 
                    ;;

                    0)
                        break
                    ;;
                    *)
                        echo -e "${red}无效选择，请重新输入。${re}"
                    ;;
                esac
              done
            ;;

            0)
                main_menu
            ;;
        esac
    done
    ;; 
# 脚本更新
  00)
    cd ~
    curl -sS -O https://raw.githubusercontent.com/eooce/ssh_tool/main/update_log.sh && chmod +x update_log.sh && ./update_log.sh
    rm update_log.sh
    echo ""
    curl -sS -O https://raw.githubusercontent.com/eooce/ssh_tool/main/ssh_tool.sh && chmod +x ssh_tool.sh
    echo -e "${green}脚本已更新到最新版本！${re}"
    break_end
    main_menu
    ;;

  88)
    clear
    exit
    ;;

  *)
    echo -e "${purple}无效的输入!${re}"
    ;;
esac
    break_end
done
