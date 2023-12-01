#!/bin/bash

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
      echo "LDNMP环境安装完毕"
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
    if ! command -v certbot &>/dev/null; then
        if command -v apt &>/dev/null; then
            apt update -y && apt install -y certbot
        elif command -v yum &>/dev/null; then
            yum -y update && yum -y install certbot
        else
            echo "未知的包管理器!"
            exit 1
        fi
    fi

    # 切换到一个一致的目录（例如，家目录）
    cd ~ || exit

    # 下载并使脚本可执行
    curl -O https://raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
    chmod +x auto_cert_renewal.sh

    # 安排每日午夜运行脚本
    echo "0 0 * * * cd ~ && ./auto_cert_renewal.sh" | crontab -
}

install_ssltls() {
    #   docker stop nginx
    #   iptables_open
    #   cd ~
    #   curl https://get.acme.sh | sh
    #   ~/.acme.sh/acme.sh --register-account -m xxxx@gmail.com --issue -d $yuming --standalone --key-file /home/web/certs/${yuming}_key.pem --cert-file /home/web/certs/${yuming}_cert.pem --force
    #   docker start nginx

      docker stop nginx
      iptables_open
      cd ~
      certbot certonly --standalone -d $yuming --email your@email.com --agree-tos --no-eff-email --force-renewal
      cp /etc/letsencrypt/live/$yuming/cert.pem /home/web/certs/${yuming}_cert.pem
      cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem
      docker start nginx

}

while true; do
clear

echo -e "\033[96m_  _ ____  _ _ _    _ ____ _  _ "
echo "|_/  |___  | | |    | |  | |\ | "
echo "| \_ |___ _| | |___ | |__| | \| "
echo "                                "
echo -e "\033[96m科技lion一键脚本工具 v2.0.2 （支持Ubuntu，Debian，Centos系统）\033[0m"
echo "------------------------"
echo "1. 系统信息查询"
echo "2. 系统更新"
echo "3. 系统清理"
echo "4. 常用工具 ▶"
echo "5. BBR管理 ▶"
echo "6. Docker管理 ▶ "
echo "7. WARP管理 ▶ 解锁ChatGPT Netflix"
echo "8. 测试脚本合集 ▶ "
echo "9. 甲骨文云脚本合集 ▶ "
echo -e "\033[33m10. LDNMP建站 ▶ \033[0m"
echo "11. 常用面板工具 ▶ "
echo "12. 我的工作区 ▶ "
echo "13. 系统工具 ▶ "
echo "------------------------"
echo "00. 脚本更新日志"
echo "------------------------"
echo "0. 退出脚本"
echo "------------------------"
read -p "请输入你的选择: " choice

case $choice in
  1)
    clear
    # 函数: 获取IPv4和IPv6地址
    fetch_ip_addresses() {
      ipv4_address=$(curl -s ipv4.ip.sb)
      # ipv6_address=$(curl -s ipv6.ip.sb)
      ipv6_address=$(curl -s --max-time 2 ipv6.ip.sb)

    }

    # 获取IP地址
    fetch_ip_addresses

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
    echo "系统信息查询"
    echo "------------------------"
    echo "主机名: $hostname"
    echo "运营商: $isp_info"
    echo "------------------------"
    echo "系统版本: $os_info"
    echo "Linux版本: $kernel_version"
    echo "------------------------"
    echo "CPU架构: $cpu_arch"
    echo "CPU型号: $cpu_info"
    echo "CPU核心数: $cpu_cores"
    echo "------------------------"
    echo "CPU占用: $cpu_usage_percent"
    echo "物理内存: $mem_info"
    echo "虚拟内存: $swap_info"
    echo "硬盘占用: $disk_info"
    echo "------------------------"
    echo "$output"
    echo "------------------------"
    echo "网络拥堵算法: $congestion_algorithm $queue_algorithm"
    echo "------------------------"
    echo "公网IPv4地址: $ipv4_address"
    echo "公网IPv6地址: $ipv6_address"
    echo "------------------------"
    echo "地理位置: $country $city"
    echo "系统时间: $current_time"
    echo "------------------------"
    echo "系统运行时长: $runtime"
    echo

    ;;

  2)
    clear

    # Update system on Debian-based systems
    if [ -f "/etc/debian_version" ]; then
        apt update -y && apt full-upgrade -y
    fi

    # Update system on Red Hat-based systems
    if [ -f "/etc/redhat-release" ]; then
        yum -y update
    fi

    ;;

  3)
  clear

  if [ -f "/etc/debian_version" ]; then
      # Debian-based systems
      apt autoremove --purge -y
      apt clean -y
      apt autoclean -y
      apt remove --purge $(dpkg -l | awk '/^rc/ {print $2}') -y
      journalctl --rotate
      journalctl --vacuum-time=1s
      journalctl --vacuum-size=50M
      apt remove --purge $(dpkg -l | awk '/^ii linux-(image|headers)-[^ ]+/{print $2}' | grep -v $(uname -r | sed 's/-.*//') | xargs) -y
  elif [ -f "/etc/redhat-release" ]; then
      # Red Hat-based systems
      yum autoremove -y
      yum clean all
      journalctl --rotate
      journalctl --vacuum-time=1s
      journalctl --vacuum-size=50M
      yum remove $(rpm -q kernel | grep -v $(uname -r)) -y
  fi
    ;;

  4)
  while true; do
      echo " ▼ "
      echo "安装常用工具"
      echo "------------------------"
      echo "1. curl 下载工具"
      echo "2. wget 下载工具"
      echo "3. sudo 超级管理权限工具"
      echo "4. socat 通信连接工具 （申请域名证书必备）"
      echo "5. htop 系统监控工具"
      echo "6. iftop 网络流量监控工具"
      echo "7. unzip ZIP压缩解压工具z"
      echo "8. tar GZ压缩解压工具"
      echo "9. tmux 多路后台运行工具"
      echo "10. ffmpeg 视频编码直播推流工具"
      echo "------------------------"
      echo "31. 全部安装"
      echo "32. 全部卸载"
      echo "------------------------"
      echo "0. 返回主菜单"
      echo "------------------------"
      read -p "请输入你的选择: " sub_choice

      case $sub_choice in
          1)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y curl
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install curl
              else
                  echo "未知的包管理器!"
              fi

              ;;
          2)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y wget
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install wget
              else
                  echo "未知的包管理器!"
              fi
              ;;
            3)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y sudo
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install sudo
              else
                  echo "未知的包管理器!"
              fi
              ;;
            4)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y socat
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install socat
              else
                  echo "未知的包管理器!"
              fi
              ;;
            5)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y htop
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install htop
              else
                  echo "未知的包管理器!"
              fi
              ;;
            6)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y iftop
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install iftop
              else
                  echo "未知的包管理器!"
              fi
              ;;
            7)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y unzip
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install unzip
              else
                  echo "未知的包管理器!"
              fi
              ;;
            8)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y tar
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install tar
              else
                  echo "未知的包管理器!"
              fi
              ;;
            9)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y tmux
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install tmux
              else
                  echo "未知的包管理器!"
              fi
              ;;
            10)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y ffmpeg
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install ffmpeg
              else
                  echo "未知的包管理器!"
              fi
              ;;


          31)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y curl wget sudo socat htop iftop unzip tar tmux ffmpeg
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install curl wget sudo socat htop iftop unzip tar tmux ffmpeg
              else
                  echo "未知的包管理器!"
              fi
              ;;

          32)
              clear
              if command -v apt &>/dev/null; then
                  apt remove -y htop iftop unzip tmux ffmpeg
              elif command -v yum &>/dev/null; then
                  yum -y remove htop iftop unzip tmux ffmpeg
              else
                  echo "未知的包管理器!"
              fi
              ;;

          0)
              cd ~
              ./kejilion.sh
              exit
              ;;

          *)
              echo "无效的输入!"
              ;;
      esac
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
  done

    ;;

  5)
    clear
    # 检查并安装 wget（如果需要）
    if ! command -v wget &>/dev/null; then
        if command -v apt &>/dev/null; then
            apt update -y && apt install -y wget
        elif command -v yum &>/dev/null; then
            yum -y update && yum -y install wget
        else
            echo "未知的包管理器!"
            exit 1
        fi
    fi
    wget --no-check-certificate -O tcpx.sh https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
    chmod +x tcpx.sh
    ./tcpx.sh
    ;;

  6)
    while true; do
      echo " ▼ "
      echo "Docker管理器"
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
      echo "8. 卸载Dcoker环境"
      echo "------------------------"
      echo "0. 返回主菜单"
      echo "------------------------"
      read -p "请输入你的选择: " sub_choice

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
                  echo "1. 创建新的容器"
                  echo "------------------------"
                  echo "2. 启动指定容器             6. 启动所有容器"
                  echo "3. 停止指定容器             7. 暂停所有容器"
                  echo "4. 删除指定容器             8. 删除所有容器"
                  echo "5. 重启指定容器             9. 重启所有容器"
                  echo "------------------------"
                  echo "11. 进入指定容器           12. 查看容器日志           13. 查看容器网络"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p "请输入你的选择: " sub_choice

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
                          echo -e "\033[0;32m操作完成\033[0m"
                          echo "按任意键继续..."
                          read -n 1 -s -r -p ""
                          echo ""
                          clear
                          ;;
                      12)
                          read -p "请输入容器名: " dockername
                          docker logs $dockername
                          echo -e "\033[0;32m操作完成\033[0m"
                          echo "按任意键继续..."
                          read -n 1 -s -r -p ""
                          echo ""
                          clear
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

                          echo -e "\033[0;32m操作完成\033[0m"
                          echo "按任意键继续..."
                          read -n 1 -s -r -p ""
                          echo ""
                          clear
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
                  read -p "请输入你的选择: " sub_choice

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
                  read -p "请输入你的选择: " sub_choice

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
                  read -p "请输入你的选择: " sub_choice

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
                  apt-get remove docker -y
                  apt-get remove docker-ce -y
                  apt-get purge docker-ce -y
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
              cd ~
              ./kejilion.sh
              exit
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear

    done

    ;;


  7)
    clear
    # 检查并安装 wget（如果需要）
    if ! command -v wget &>/dev/null; then
        if command -v apt &>/dev/null; then
            apt update -y && apt install -y wget
        elif command -v yum &>/dev/null; then
            yum -y update && yum -y install wget
        else
            echo "未知的包管理器!"
            exit 1
        fi
    fi

    wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh && bash menu.sh [option] [lisence/url/token]
    ;;

  8)
    while true; do

      echo " ▼ "
      echo "测试脚本合集"
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
      echo "0. 返回主菜单"
      echo "------------------------"
      read -p "请输入你的选择: " sub_choice

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
              wget -qO- https://github.com/yeahwu/check/raw/main/check.sh | bash
              ;;
          4)
              clear
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
              echo "按任意键继续..."
              read -n 1 -s -r -p ""
              ;;
          9)
              clear
              curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
              ;;
          0)
              cd ~
              ./kejilion.sh
              exit
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
    done
    ;;

  9)
     while true; do
      echo " ▼ "
      echo "甲骨文云脚本合集"
      echo "------------------------"
      echo "1. 安装闲置机器活跃脚本"
      echo "2. 卸载闲置机器活跃脚本"
      echo "------------------------"
      echo "3. DD重装系统脚本"
      echo "4. R探长开机脚本"
      echo "------------------------"
      echo "5. 开启ROOT密码登录模式"
      echo "------------------------"
      echo "0. 返回主菜单"
      echo "------------------------"
      read -p "请输入你的选择: " sub_choice

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
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y wget
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install wget
              else
                  echo "未知的包管理器!"
              fi
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
              echo "该功能处于开发阶段，敬请期待！"
              ;;
          5)
              clear
              echo "设置你的ROOT密码"
              passwd
              sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
              sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
              service sshd restart
              echo "ROOT登录设置完毕！"
              read -p "需要重启服务器吗？(Y/N): " choice
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
          0)
              cd ~
              ./kejilion.sh
              exit
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
    done
    ;;


  10)

  while true; do
    echo -e "\033[33m ▼ \033[0m"
    echo -e "\033[33mLDNMP建站\033[0m"
    echo  "------------------------"
    echo  "1. 安装LDNMP环境"
    echo  "------------------------"
    echo  "2. 安装WordPress"
    echo  "3. 安装Discuz论坛"
    echo  "4. 安装可道云桌面"
    echo  "5. 安装苹果CMS网站"
    echo  "6. 安装独角数发卡网"
    echo  "7. 安装BingChatAI聊天网站"
    echo  "8. 安装flarum论坛网站"
    echo  "9. 安装Bitwarden密码管理平台"
    echo  "10. 安装Halo博客网站"
    echo  "11. 安装typecho轻量博客网站"
    echo  "------------------------"
    echo -e "21. 仅安装nginx  \033[33mNEW\033[0m"
    echo  "22. 站点重定向"
    echo  "23. 站点反向代理"
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
    echo  "38. 卸载LDNMP环境"
    echo  "------------------------"
    echo  "0. 返回主菜单"
    echo  "------------------------"
    read -p "请输入你的选择: " sub_choice


    case $sub_choice in
      1)
      clear
      # 更新并安装必要的软件包
      if command -v apt &>/dev/null; then
          apt update -y
          apt install -y curl wget sudo socat unzip tar htop
      elif command -v yum &>/dev/null; then
          yum -y update
          yum -y install curl
          yum -y install wget
          yum -y install sudo
          yum -y install socat
          yum -y install unzip
          yum -y install tar
          yum -y install htop
      else
          echo "未知的包管理器!"
      fi

      install_docker
      install_certbot

      # 创建必要的目录和文件
      cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml

      wget -O /home/web/nginx.conf https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
      wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/kejilion/nginx/main/default10.conf
      localhostIP=$(curl -s ipv4.ip.sb)
      sed -i "s/localhost/$localhostIP/g" /home/web/conf.d/default.conf

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
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"

      install_ssltls

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget -O latest.zip https://cn.wordpress.org/latest-zh_CN.zip
      unzip latest.zip
      rm latest.zip

      echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php

      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"

      docker restart php
      docker restart php74
      docker restart nginx

      clear
      echo "您的WordPress搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "WP安装信息如下: "
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "数据库主机: mysql"
      echo "表前缀: wp_"

        ;;
      3)
      clear
      # Discuz论坛
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"
      install_ssltls

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf

      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget https://github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20230520.zip
      unzip -o Discuz_X3.5_SC_UTF8_20230520.zip
      rm Discuz_X3.5_SC_UTF8_20230520.zip

      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"

      docker restart php
      docker restart php74
      docker restart nginx


      clear
      echo "您的Discuz论坛搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库主机: mysql"
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "表前缀: discuz_"


        ;;

      4)
      clear
      # 可道云桌面
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"

      install_ssltls
      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget https://github.com/kalcaddle/kodbox/archive/refs/tags/1.42.04.zip
      unzip -o 1.42.04.zip
      rm 1.42.04.zip

      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"

      docker restart php
      docker restart php74
      docker restart nginx


      clear
      echo "您的可道云桌面搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库主机: mysql"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "数据库名: $dbname"
      echo "redis主机: redis"
        ;;

      5)
      clear
      # 苹果CMS
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"

      install_ssltls

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

      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"

      docker restart php
      docker restart php74
      docker restart nginx


      clear
      echo "您的苹果CMS搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库主机: mysql"
      echo "数据库端口: 3306"
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "数据库前缀: mac_"
      echo "------------------------"
      echo "安装成功后登录后台地址"
      echo "https://$yuming/vip.php"
      echo ""
        ;;

      6)
      clear
      # 独脚数卡
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"

      install_ssltls

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf

      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget https://github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"

      docker restart php
      docker restart php74
      docker restart nginx


      clear
      echo "您的独角数卡网站搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库主机: mysql"
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
      echo ""
        ;;

      7)
      clear
      # BingChat
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming

      install_ssltls

      docker run -d -p 3099:8080 --name go-proxy-bingai --restart=unless-stopped adams549659584/go-proxy-bingai

      # Get external IP address
      external_ip=$(curl -s ipv4.ip.sb)

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0.0.0.0/$external_ip/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0000/3099/g" /home/web/conf.d/$yuming.conf

      docker restart nginx

      clear
      echo "您的BingChat网站搭建好了！"
      echo "https://$yuming"
      echo ""
        ;;

      8)
      clear
      # flarum论坛
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"

      install_ssltls

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

      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"

      docker restart php
      docker restart php74
      docker restart nginx


      clear
      echo "您的flarum论坛网站搭建好了！"
      echo "https://$yuming"
      echo "------------------------"
      echo "安装信息如下: "
      echo "数据库主机: mysql"
      echo "数据库名: $dbname"
      echo "用户名: $dbuse"
      echo "密码: $dbusepasswd"
      echo "表前缀: flarum_"
      echo "管理员信息自行设置"
      echo ""
        ;;

      9)
      clear
      # Bitwarden
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming

      install_ssltls

      docker run -d \
        --name bitwarden \
        --restart always \
        -p 3280:80 \
        -v /home/web/html/$yuming/bitwarden/data:/data \
        vaultwarden/server

      # Get external IP address
      external_ip=$(curl -s ipv4.ip.sb)

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0.0.0.0/$external_ip/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0000/3280/g" /home/web/conf.d/$yuming.conf

      docker restart nginx

      clear
      echo "您的Bitwarden网站搭建好了！"
      echo "https://$yuming"
      echo ""
        ;;

      10)
      clear
      # Bitwarden
      read -p "请输入你解析的域名: " yuming

      install_ssltls

      docker run -d --name halo --restart always --network web_default -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2.9

      # Get external IP address
      external_ip=$(curl -s ipv4.ip.sb)

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0.0.0.0/$external_ip/g" /home/web/conf.d/$yuming.conf
      sed -i "s/0000/8010/g" /home/web/conf.d/$yuming.conf

      docker restart nginx

      clear
      echo "您的Halo网站搭建好了！"
      echo "https://$yuming"
      echo ""
        ;;

      11)
      clear
      # typecho
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
      read -p "请输入你解析的域名: " yuming
      dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
      dbname="${dbname}"

      install_ssltls

      wget -O /home/web/conf.d/$yuming.conf https://raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
      sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

      cd /home/web/html
      mkdir $yuming
      cd $yuming
      wget -O latest.zip https://github.com/typecho/typecho/releases/latest/download/typecho.zip
      unzip latest.zip
      rm latest.zip

      docker exec nginx chmod -R 777 /var/www/html
      docker exec php chmod -R 777 /var/www/html
      docker exec php74 chmod -R 777 /var/www/html

      dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
      docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"

      docker restart php
      docker restart php74
      docker restart nginx


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

        ;;


      21)
      clear

      if command -v apt &>/dev/null; then
          apt update -y
          apt install -y curl wget sudo socat unzip tar htop
      elif command -v yum &>/dev/null; then
          yum -y update && yum -y install curl wget sudo socat unzip tar htop
      else
          echo "未知的包管理器!"
      fi

      install_docker
      install_certbot

      cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml

      wget -O /home/web/nginx.conf https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
      wget -O /home/web/conf.d/default.conf https://raw.githubusercontent.com/kejilion/nginx/main/default10.conf
      localhostIP=$(curl -s ipv4.ip.sb)
      sed -i "s/localhost/$localhostIP/g" /home/web/conf.d/default.conf

      docker run -d --name nginx --restart always -p 80:80 -p 443:443 -v /home/web/nginx.conf:/etc/nginx/nginx.conf -v /home/web/conf.d:/etc/nginx/conf.d -v /home/web/certs:/etc/nginx/certs -v /home/web/html:/var/www/html -v /home/web/log/nginx:/var/log/nginx nginx

        ;;

      22)
      clear
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
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

        ;;

      23)
      clear
      external_ip=$(curl -s ipv4.ip.sb)
      echo -e "先将域名解析到本机IP: \033[33m$external_ip\033[0m"
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
        echo "1. 申请/更新域名证书               2. 更换站点域名               3. 清理站点缓存"
        echo "------------------------"
        echo "7. 删除指定站点                    8. 删除指定数据库"
        echo "------------------------"
        echo "0. 返回上一级选单"
        echo "------------------------"
        read -p "请输入你的选择: " sub_choice
        case $sub_choice in
            1)
                read -p "请输入你的域名: " yuming

                install_ssltls

                ;;

            2)
                read -p "请输入旧域名: " oddyuming
                read -p "请输入新域名: " newyuming
                mv /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$newyuming.conf
                sed -i "s/$oddyuming/$newyuming/g" /home/web/conf.d/$newyuming.conf
                mv /home/web/html/$oddyuming /home/web/html/$newyuming

                rm /home/web/certs/${oddyuming}_key.pem
                rm /home/web/certs/${oddyuming}_cert.pem

                install_ssltls

                ;;


            3)
                docker exec -it nginx rm -rf /var/cache/nginx
                docker restart nginx
                ;;

            7)
                read -p "请输入你的域名: " yuming
                rm -r /home/web/html/$yuming
                rm /home/web/conf.d/$yuming.conf
                rm /home/web/certs/${yuming}_key.pem
                rm /home/web/certs/${yuming}_cert.pem
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
      read -p "请输入你的选择: " dingshi

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

      if ! command -v sshpass &>/dev/null; then
          if command -v apt &>/dev/null; then
              apt update -y && apt install -y sshpass
          elif command -v yum &>/dev/null; then
              yum -y update && yum -y install sshpass
          else
              echo "未知的包管理器!"
          fi
      else
          echo "sshpass 已经安装，跳过安装步骤。"
      fi

      ;;

    34)
      clear
      cd /home/ && ls -t /home/*.tar.gz | head -1 | xargs -I {} tar -xzf {}

      if command -v apt &>/dev/null; then
          apt update -y
          apt install -y curl wget sudo socat unzip tar htop
      elif command -v yum &>/dev/null; then
          yum -y update
          yum -y install curl
          yum -y install wget
          yum -y install sudo
          yum -y install socat
          yum -y install unzip
          yum -y install tar
          yum -y install htop
      else
          echo "未知的包管理器!"
      fi

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
              read -p "请输入你的选择: " sub_choice
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
                      systemctl disable fail2ban
                      systemctl stop fail2ban
                      apt remove -y --purge fail2ban
                      if [ $? -eq 0 ]; then
                          echo "Fail2ban已卸载"
                      else
                          echo "卸载失败"
                      fi
                      rm -rf /etc/fail2ban
                      break
                      ;;
                  0)
                      break
                      ;;
                  *)
                      echo "无效的选择，请重新输入。"
                      ;;
              esac
              echo -e "\033[0;32m操作完成\033[0m"
              echo "按任意键继续..."
              read -n 1 -s -r -p ""
              echo ""
          done
      else
          clear
          # 安装Fail2ban
          if [ -f /etc/debian_version ]; then
              # Debian/Ubuntu系统
              apt update -y
              apt install -y fail2ban
          elif [ -f /etc/redhat-release ]; then
              # CentOS系统
              yum update -y
              yum install -y epel-release
              yum install -y fail2ban
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
          localhostIP=$(curl -s ipv4.ip.sb)
          sed -i "s/localhost/$localhostIP/g" /home/web/conf.d/default.conf

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
              read -p "请输入你的选择: " sub_choice
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
              echo -e "\033[0;32m操作完成\033[0m"
              echo "按任意键继续..."
              read -n 1 -s -r -p ""
              echo ""
          done
        ;;


    37)
      clear
      docker rm -f nginx php php74 mysql redis
      docker rmi nginx php:fpm php:7.4.33-fpm mysql redis

      if command -v apt &>/dev/null; then
          apt update -y
          apt upgrade -y
      elif command -v yum &>/dev/null; then
          yum -y update
      else
          echo "未知的包管理器!"
      fi

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
        cd ~
        ./kejilion.sh
        exit
      ;;

    *)
        echo "无效的输入!"
    esac

    echo -e "\033[0;32m操作完成\033[0m"
    echo "按任意键继续..."
    read -n 1 -s -r -p ""
    echo ""
    clear
  done
      ;;

  11)
    while true; do

      echo " ▼ "
      echo "常用面板工具"
      echo "------------------------"
      echo "1. 宝塔面板官方版                       2. aaPanel宝塔国际版"
      echo "3. 1Panel新一代管理面板                 4. NginxProxyManager可视化面板"
      echo "5. AList多存储文件列表程序              6. Ubuntu远程桌面网页版"
      echo "7. 哪吒探针VPS监控面板                  8. QB离线BT磁力下载面板"
      echo "9. Poste.io邮件服务器程序               10. RocketChat多人在线聊天系统"
      echo "11. 禅道项目管理软件                    12. 青龙面板定时任务管理平台"
      echo "13. Cloudreve网盘系统                   14. 简单图床图片管理程序"
      echo "15. emby多媒体管理系统                  16. Speedtest测速服务面板"
      echo "17. AdGuardHome去广告软件               18. onlyoffice在线办公OFFICE"
      echo "19. 雷池WAF防火墙面板"
      echo "------------------------"
      echo "0. 返回主菜单"
      echo "------------------------"
      read -p "请输入你的选择: " sub_choice

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
                read -p "请输入你的选择: " sub_choice

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
                            if ! command -v wget &>/dev/null; then
                                if command -v apt &>/dev/null; then
                                    apt update -y && apt install -y wget
                                elif command -v yum &>/dev/null; then
                                    yum -y update && yum -y install wget
                                else
                                    echo "未知的包管理器!"
                                    exit 1
                                fi
                            fi
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
                read -p "请输入你的选择: " sub_choice

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
                            if ! command -v wget &>/dev/null; then
                                if command -v apt &>/dev/null; then
                                    apt update -y && apt install -y wget
                                elif command -v yum &>/dev/null; then
                                    yum -y update && yum -y install wget
                                else
                                    echo "未知的包管理器!"
                                    exit 1
                                fi
                            fi
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
              ;;
          4)
            if docker inspect npm &>/dev/null; then
                    clear
                    echo "npm已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:81"
                    echo ""
                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f npm
                            docker rmi -f jc21/nginx-proxy-manager:latest

                            install_docker

                            docker run -d \
                              --name=npm \
                              -p 80:80 \
                              -p 81:81 \
                              -p 443:443 \
                              -v /home/docker/npm/data:/data \
                              -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
                              --restart=always \
                              jc21/nginx-proxy-manager:latest
                            clear
                            echo "npm已经安装完成"
                            echo "------------------------"
                            # Get external IP address
                            external_ip=$(curl -s ipv4.ip.sb)

                            echo "您可以使用以下地址访问Nginx Proxy Manager:"
                            echo "http:$external_ip:81"
                            echo "初始用户名: admin@example.com"
                            echo "初始密码: changeme"
                            ;;
                        2)
                            clear
                            docker rm -f npm
                            docker rmi -f jc21/nginx-proxy-manager:latest
                            rm -rf /home/docker/npm
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
                  echo "如果您已经安装了其他面板工具或者LDNMP建站环境，建议先卸载，再安装npm！"
                  echo "官网介绍: https://nginxproxymanager.com/"
                  echo ""

                  # Prompt user for installation confirmation
                  read -p "确定安装npm吗？(Y/N): " choice
                  case "$choice" in
                    [Yy])
                      clear
                      install_docker

                      docker run -d \
                        --name=npm \
                        -p 80:80 \
                        -p 81:81 \
                        -p 443:443 \
                        -v /home/docker/npm/data:/data \
                        -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
                        --restart=always \
                        jc21/nginx-proxy-manager:latest
                      clear
                      echo "npm已经安装完成"
                      echo "------------------------"
                      # Get external IP address
                      external_ip=$(curl -s ipv4.ip.sb)

                      echo "您可以使用以下地址访问Nginx Proxy Manager:"
                      echo "http:$external_ip:81"
                      echo "初始用户名: admin@example.com"
                      echo "初始密码: changeme"
                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;
          5)

            if docker inspect alist &>/dev/null; then
                    clear
                    echo "alist已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:5244"
                    echo ""
                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f alist
                            docker rmi -f xhofe/alist:latest

                            # 检查并安装 Docker（如果需要）

                            install_docker
                            docker run -d \
                                --restart=always \
                                -v /home/docker/alist:/opt/alist/data \
                                -p 5244:5244 \
                                -e PUID=0 \
                                -e PGID=0 \
                                -e UMASK=022 \
                                --name="alist" \
                                xhofe/alist:latest

                            clear
                            echo "alist已经安装完成"
                            echo "------------------------"
                            # Get external IP address
                            external_ip=$(curl -s ipv4.ip.sb)

                            echo "您可以使用以下地址访问alist:"
                            echo "http:$external_ip:5244"
                            docker exec -it alist ./alist admin random
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f alist
                            docker rmi -f xhofe/alist:latest
                            rm -rf /home/docker/alist
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
                  echo "一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
                  echo "官网介绍: https://alist.nn.ci/zh/"
                  echo ""

                  # Prompt user for installation confirmation
                  read -p "确定安装Alist吗？(Y/N): " choice
                  case "$choice" in
                    [Yy])
                      clear
                      install_docker
                      docker run -d \
                          --restart=always \
                          -v /home/docker/alist:/opt/alist/data \
                          -p 5244:5244 \
                          -e PUID=0 \
                          -e PGID=0 \
                          -e UMASK=022 \
                          --name="alist" \
                          xhofe/alist:latest

                      clear
                      echo "alist已经安装完成"
                      echo "------------------------"
                      # Get external IP address
                      external_ip=$(curl -s ipv4.ip.sb)

                      echo "您可以使用以下地址访问alist:"
                      echo "http:$external_ip:5244"
                      docker exec -it alist ./alist admin random
                      echo ""
                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;

          6)
            if docker inspect ubuntu-novnc &>/dev/null; then
                    clear
                    echo "乌班图桌面已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:6080"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f ubuntu-novnc
                            docker rmi -f fredblgr/ubuntu-novnc:20.04
                            read -p "请设置一个登录密码: " rootpasswd
                            install_docker
                            docker run -d \
                                --name ubuntu-novnc \
                                -p 6080:80 \
                                -v /home/docker/ubuntu:/workspace:rw \
                                -e HTTP_PASSWORD=$rootpasswd \
                                -e RESOLUTION=1280x720 \
                                --restart=always \
                                fredblgr/ubuntu-novnc:20.04

                            clear
                            echo "Ubuntu远程桌面已经安装完成"
                            echo "------------------------"
                            # Get external IP address
                            external_ip=$(curl -s ipv4.ip.sb)

                            echo "您可以使用以下地址访问Ubuntu远程桌面:"
                            echo "http:$external_ip:6080"
                            echo "用户名: root"
                            echo "密码: $rootpasswd"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f ubuntu-novnc
                            docker rmi -f fredblgr/ubuntu-novnc:20.04
                            rm -rf /home/docker/ubuntu
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
                echo "一个网页版Ubuntu远程桌面，挺好用的！"
                echo "官网介绍: https://hub.docker.com/r/fredblgr/ubuntu-novnc"
                echo ""

                # 提示用户确认安装
                read -p "确定安装Ubuntu远程桌面吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                        clear
                        read -p "请设置一个登录密码: " rootpasswd
                        install_docker
                        docker run -d \
                            --name ubuntu-novnc \
                            -p 6080:80 \
                            -v /home/docker/ubuntu:/workspace:rw \
                            -e HTTP_PASSWORD=$rootpasswd \
                            -e RESOLUTION=1280x720 \
                            --restart=always \
                            fredblgr/ubuntu-novnc:20.04

                        clear
                        echo "Ubuntu远程桌面已经安装完成"
                        echo "------------------------"
                        # Get external IP address
                        external_ip=$(curl -s ipv4.ip.sb)

                        echo "您可以使用以下地址访问Ubuntu远程桌面:"
                        echo "http:$external_ip:6080"
                        echo "用户名: root"
                        echo "密码: $rootpasswd"
                        echo ""
                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;
          7)
            clear
            curl -L https://raw.githubusercontent.com/naiba/nezha/master/script/install.sh  -o nezha.sh && chmod +x nezha.sh
            ./nezha.sh
              ;;
          8)
            if docker inspect qbittorrent &>/dev/null; then
                    clear

                    echo "QB已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:8081"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f qbittorrent
                            docker rmi -f lscr.io/linuxserver/qbittorrent:latest
                            docker rmi -f lscr.io/linuxserver/qbittorrent:4.5.5
                            install_docker
                            docker run -d \
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
                                  lscr.io/linuxserver/qbittorrent:latest
                            clear
                            echo "QB已经安装完成"
                            echo "------------------------"
                            # Get external IP address
                            external_ip=$(curl -s ipv4.ip.sb)

                            echo "您可以使用以下地址访问QB:"
                            echo "http:$external_ip:8081"
                            echo "账号: admin"
                            echo "密码: adminadmin"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f qbittorrent
                            docker rmi -f lscr.io/linuxserver/qbittorrent:latest
                            docker rmi -f lscr.io/linuxserver/qbittorrent:4.5.5
                            rm -rf /home/docker/qbittorrent
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
                echo "qbittorrent离线BT磁力下载服务"
                echo "官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
                echo ""

                # 提示用户确认安装
                read -p "确定安装QB吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run -d \
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
                          lscr.io/linuxserver/qbittorrent:4.5.5
                    clear
                    echo "QB已经安装完成"
                    echo "------------------------"
                    # Get external IP address
                    external_ip=$(curl -s ipv4.ip.sb)

                    echo "您可以使用以下地址访问QB:"
                    echo "http:$external_ip:8081"
                    echo "账号: admin"
                    echo "密码: adminadmin"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

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
                    read -p "请输入你的选择: " sub_choice

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
                if ! command -v telnet &>/dev/null; then
                    if command -v apt &>/dev/null; then
                        apt update -y && apt install -y telnet
                    elif command -v yum &>/dev/null; then
                        yum -y update && yum -y install telnet
                    else
                        echo "未知的包管理器!"
                        exit 1
                    fi
                fi

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
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "先解析这些DNS记录"
                    echo "A           mail            $external_ip"
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
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:3897"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f rocketchat
                            docker rmi -f rocket.chat:6.3
                            install_docker

                            docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

                            clear
                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "rocket.chat已经安装完成"
                            echo "------------------------"
                            echo "多等一会，您可以使用以下地址访问rocket.chat:"
                            echo "http:$external_ip:3897"
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

                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "rocket.chat已经安装完成"
                    echo "------------------------"
                    echo "多等一会，您可以使用以下地址访问rocket.chat:"
                    echo "http:$external_ip:3897"
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
            if docker inspect zentao-server &>/dev/null; then

                    clear
                    echo "禅道已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:82"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f zentao-server
                            docker rmi -f idoop/zentao:latest
                            install_docker
                            docker run -d -p 82:80 -p 3308:3306 \
                                    -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
                                    -e BIND_ADDRESS="false" \
                                    -v /home/docker/zbox/:/opt/zbox/ \
                                    --add-host smtp.exmail.qq.com:163.177.90.125 \
                                    --name zentao-server \
                                    --restart=always \
                                    idoop/zentao:latest


                            clear
                            echo "禅道已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问禅道:"

                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:82"
                            echo "账号和密码没变"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f zentao-server
                            docker rmi -f idoop/zentao:latest
                            rm -rf /home/docker/zbox
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
                echo "禅道是通用的项目管理软件"
                echo "官网介绍: https://www.zentao.net/"
                echo ""

                # 提示用户确认安装
                read -p "确定安装禅道吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run -d -p 82:80 -p 3308:3306 \
                            -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
                            -e BIND_ADDRESS="false" \
                            -v /home/docker/zbox/:/opt/zbox/ \
                            --add-host smtp.exmail.qq.com:163.177.90.125 \
                            --name zentao-server \
                            --restart=always \
                            idoop/zentao:latest
                    clear
                    echo "禅道已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问禅道:"
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:82"
                    echo "账号: admin"
                    echo "密码: 123456"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;

          12)
            if docker inspect qinglong &>/dev/null; then
                    clear
                    echo "青龙面板已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:5700"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f qinglong
                            docker rmi -f whyour/qinglong:latest
                            install_docker
                            docker run -d \
                              -v /home/docker/ql/data:/ql/data \
                              -p 5700:5700 \
                              --name qinglong \
                              --hostname qinglong \
                              --restart unless-stopped \
                              whyour/qinglong:latest


                            clear
                            echo "青龙面板已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问青龙面板:"

                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:5700"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f qinglong
                            docker rmi -f whyour/qinglong:latest
                            rm -rf /home/docker/ql
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
                echo "青龙面板是一个定时任务管理平台"
                echo "官网介绍: https://github.com/whyour/qinglong"
                echo ""

                # 提示用户确认安装
                read -p "确定安装青龙面板吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run -d \
                      -v /home/docker/ql/data:/ql/data \
                      -p 5700:5700 \
                      --name qinglong \
                      --hostname qinglong \
                      --restart unless-stopped \
                      whyour/qinglong:latest

                    clear
                    echo "青龙面板已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问青龙面板:"
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:5700"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;
          13)
            if docker inspect cloudreve &>/dev/null; then

                    clear
                    echo "cloudreve已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:5212"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

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
                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:5212"
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
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:5212"
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
            if docker inspect easyimage &>/dev/null; then

                    clear
                    echo "简单图床已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:85"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f easyimage
                            docker rmi -f ddsderek/easyimage:latest
                            install_docker
                            docker run -d \
                              --name easyimage \
                              -p 85:80 \
                              -e TZ=Asia/Shanghai \
                              -e PUID=1000 \
                              -e PGID=1000 \
                              -v /home/docker/easyimage/config:/app/web/config \
                              -v /home/docker/easyimage/i:/app/web/i \
                              --restart unless-stopped \
                              ddsderek/easyimage:latest

                            clear
                            echo "简单图床已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问简单图床:"
                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:85"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f easyimage
                            docker rmi -f ddsderek/easyimage:latest
                            rm -rf /home/docker/easyimage
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
                echo "简单图床是一个简单的图床程序"
                echo "官网介绍: https://github.com/icret/EasyImages2.0"
                echo ""

                # 提示用户确认安装
                read -p "确定安装简单图床吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run -d \
                      --name easyimage \
                      -p 85:80 \
                      -e TZ=Asia/Shanghai \
                      -e PUID=1000 \
                      -e PGID=1000 \
                      -v /home/docker/easyimage/config:/app/web/config \
                      -v /home/docker/easyimage/i:/app/web/i \
                      --restart unless-stopped \
                      ddsderek/easyimage:latest


                    clear
                    echo "简单图床已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问简单图床:"
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:85"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi
              ;;

          15)
            if docker inspect emby &>/dev/null; then

                    clear
                    echo "emby已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:8096"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f emby
                            docker rmi -f linuxserver/emby:latest
                            install_docker
                            docker run -d --name=emby --restart=always \
                                -v /homeo/docker/emby/config:/config \
                                -v /homeo/docker/emby/share1:/mnt/share1 \
                                -v /homeo/docker/emby/share2:/mnt/share2 \
                                -v /mnt/notify:/mnt/notify \
                                -p 8096:8096 -p 8920:8920 \
                                -e UID=1000 -e GID=100 -e GIDLIST=100 \
                                linuxserver/emby:latest


                            clear
                            echo "emby已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问emby:"
                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:8096"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f emby
                            docker rmi -f linuxserver/emby:latest
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
                echo "emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
                echo "官网介绍: https://emby.media/"
                echo ""

                # 提示用户确认安装
                read -p "确定安装emby吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run -d --name=emby --restart=always \
                        -v /homeo/docker/emby/config:/config \
                        -v /homeo/docker/emby/share1:/mnt/share1 \
                        -v /homeo/docker/emby/share2:/mnt/share2 \
                        -v /mnt/notify:/mnt/notify \
                        -p 8096:8096 -p 8920:8920 \
                        -e UID=1000 -e GID=100 -e GIDLIST=100 \
                        linuxserver/emby:latest

                    clear
                    echo "emby已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问emby:"
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:8096"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;


          16)
            if docker inspect looking-glass &>/dev/null; then

                    clear
                    echo "Speedtest测速面板已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:89"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f looking-glass
                            docker rmi -f wikihostinc/looking-glass-server
                            install_docker
                            docker run -d --name looking-glass --restart always -p 89:80 wikihostinc/looking-glass-server


                            clear
                            echo "Speedtest测速面板已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问Speedtest测速面板:"
                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:89"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f looking-glass
                            docker rmi -f wikihostinc/looking-glass-server
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
                echo "Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
                echo "官网介绍: https://github.com/wikihost-opensource/als"
                echo ""

                # 提示用户确认安装
                read -p "确定安装Speedtest测速面板吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run -d --name looking-glass --restart always -p 89:80 wikihostinc/looking-glass-server

                    clear
                    echo "Speedtest测速面板已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问Speedtest测速面板:"
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:89"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;
          17)
            if docker inspect adguardhome &>/dev/null; then

                    clear
                    echo "AdGuardHome已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:3000"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f adguardhome
                            docker rmi -f adguard/adguardhome
                            install_docker
                            docker run -d \
                                --name adguardhome \
                                -v /home/docker/adguardhome/work:/opt/adguardhome/work \
                                -v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
                                -p 53:53/tcp \
                                -p 53:53/udp \
                                -p 3000:3000/tcp \
                                --restart always \
                                adguard/adguardhome

                            clear
                            echo "AdGuardHome已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问AdGuardHome面板:"
                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:3000"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f adguardhome
                            docker rmi -f adguard/adguardhome
                            rm -rf /home/docker/adguardhome
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
                echo "AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
                echo "官网介绍: https://hub.docker.com/r/adguard/adguardhome"
                echo ""

                # 提示用户确认安装
                read -p "确定安装AdGuardHome吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                        docker run -d \
                            --name adguardhome \
                            -v /home/docker/adguardhome/work:/opt/adguardhome/work \
                            -v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
                            -p 53:53/tcp \
                            -p 53:53/udp \
                            -p 3000:3000/tcp \
                            --restart always \
                            adguard/adguardhome

                    clear
                    echo "AdGuardHome已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问AdGuardHome:"
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:3000"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;


          18)
            if docker inspect onlyoffice &>/dev/null; then

                    clear
                    echo "onlyoffice 已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:8082"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

                    case $sub_choice in
                        1)
                            clear
                            docker rm -f onlyoffice
                            docker rmi -f onlyoffice/documentserver
                            install_docker
                            docker run -d -p 8082:80 \
                                --restart=always \
                                --name onlyoffice \
                                -v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
                                -v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
                                 onlyoffice/documentserver

                            clear
                            echo "onlyoffice已经安装完成"
                            echo "------------------------"
                            echo "您可以使用以下地址访问onlyoffice:"
                            external_ip=$(curl -s ipv4.ip.sb)
                            echo "http:$external_ip:8082"
                            echo ""
                            ;;
                        2)
                            clear
                            docker rm -f onlyoffice
                            docker rmi -f onlyoffice/documentserver
                            rm -rf /home/docker/onlyoffice
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
                echo "onlyoffice是一款开源的在线office工具，太强大了！"
                echo "官网介绍: https://www.onlyoffice.com/"
                echo ""

                # 提示用户确认安装
                read -p "确定安装onlyoffice吗？(Y/N): " choice
                case "$choice" in
                    [Yy])
                    clear
                    install_docker
                    docker run -d -p 8082:80 \
                        --restart=always \
                        --name onlyoffice \
                        -v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
                        -v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
                         onlyoffice/documentserver

                    clear
                    echo "onlyoffice已经安装完成"
                    echo "------------------------"
                    echo "您可以使用以下地址访问onlyoffice:"
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:8082"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;

          19)
            if docker inspect safeline-tengine &>/dev/null; then

                    clear
                    echo "雷池已安装，访问地址: "
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:9443"
                    echo ""

                    echo "应用操作"
                    echo "------------------------"
                    echo "1. 更新应用             2. 卸载应用"
                    echo "------------------------"
                    echo "0. 返回上一级选单"
                    echo "------------------------"
                    read -p "请输入你的选择: " sub_choice

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
                    external_ip=$(curl -s ipv4.ip.sb)
                    echo "http:$external_ip:9443"
                    echo ""

                        ;;
                    [Nn])
                        ;;
                    *)
                        ;;
                esac
            fi

              ;;


          0)
              cd ~
              ./kejilion.sh
              exit
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
    done
    ;;

  12)
    while true; do
      echo " ▼ "
      echo "我的工作区"
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
      echo "0. 返回主菜单"
      echo "------------------------"
      read -p "请输入你的选择: " sub_choice

      case $sub_choice in
          a)
              clear
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y tmux
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install tmux
              else
                  echo "未知的包管理器!"
              fi

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
              cd ~
              ./kejilion.sh
              exit
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
    done
    ;;

  13)
    while true; do

      echo " ▼ "
      echo "系统工具"
      echo "------------------------"
      echo "1. 设置脚本启动快捷键"
      echo "------------------------"
      echo "2. 修改ROOT密码"
      echo "3. 开启ROOT密码登录模式"
      echo "4. 安装Python最新版"
      echo "5. 开放所有端口"
      echo "6. 修改SSH连接端口"
      echo "7. 优化DNS地址"
      echo "8. 一键重装系统"
      echo "9. 禁用ROOT账户创建新账户"
      echo "10. 切换优先ipv4/ipv6"
      echo "11. 查看端口占用状态"
      echo "12. 修改虚拟内存大小"
      echo "13. 用户管理"
      echo "14. 用户/密码生成器"
      echo "15. 系统时区调整"
      echo "16. 开启BBR3加速"
      echo "17. 防火墙高级管理器"
      echo "18. 修改主机名"
      echo "------------------------"
      echo "21. 留言板"
      echo "------------------------"
      echo "99. 重启服务器"
      echo "------------------------"
      echo "0. 返回主菜单"
      echo "------------------------"
      read -p "请输入你的选择: " sub_choice

      case $sub_choice in
          1)
              clear
              read -p "请输入你的快捷按键: " kuaijiejian
              echo "alias $kuaijiejian='curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh'" >> ~/.bashrc
              echo "快捷键已添加。请重新启动终端，或运行 'source ~/.bashrc' 以使修改生效。"
              ;;

          2)
              clear
              echo "设置你的ROOT密码"
              passwd
              ;;
          3)
              clear
              echo "设置你的ROOT密码"
              passwd
              sed -i 's/^#\?PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
              sed -i 's/^#\?PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
              service sshd restart
              echo "ROOT登录设置完毕！"
              read -p "需要重启服务器吗？(Y/N): " choice
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

            RED="\033[31m"
            GREEN="\033[32m"
            YELLOW="\033[33m"
            NC="\033[0m"

            # 系统检测
            OS=$(cat /etc/os-release | grep -o -E "Debian|Ubuntu|CentOS" | head -n 1)

            if [[ $OS == "Debian" || $OS == "Ubuntu" || $OS == "CentOS" ]]; then
                echo -e "检测到你的系统是 ${YELLOW}${OS}${NC}"
            else
                echo -e "${RED}很抱歉，你的系统不受支持！${NC}"
                exit 1
            fi

            # 检测安装Python3的版本
            VERSION=$(python3 -V 2>&1 | awk '{print $2}')

            # 获取最新Python3版本
            PY_VERSION=$(curl -s https://www.python.org/ | grep "downloads/release" | grep -o 'Python [0-9.]*' | grep -o '[0-9.]*')

            # 卸载Python3旧版本
            if [[ $VERSION == "3"* ]]; then
                echo -e "${YELLOW}你的Python3版本是${NC}${RED}${VERSION}${NC}，${YELLOW}最新版本是${NC}${RED}${PY_VERSION}${NC}"
                read -p "是否确认升级最新版Python3？默认不升级 [y/N]: " CONFIRM
                if [[ $CONFIRM == "y" ]]; then
                    if [[ $OS == "CentOS" ]]; then
                        echo ""
                        rm-rf /usr/local/python3* >/dev/null 2>&1
                    else
                        apt --purge remove python3 python3-pip -y
                        rm-rf /usr/local/python3*
                    fi
                else
                    echo -e "${YELLOW}已取消升级Python3${NC}"
                    exit 1
                fi
            else
                echo -e "${RED}检测到没有安装Python3。${NC}"
                read -p "是否确认安装最新版Python3？默认安装 [Y/n]: " CONFIRM
                if [[ $CONFIRM != "n" ]]; then
                    echo -e "${GREEN}开始安装最新版Python3...${NC}"
                else
                    echo -e "${YELLOW}已取消安装Python3${NC}"
                    exit 1
                fi
            fi

            # 安装相关依赖
            if [[ $OS == "CentOS" ]]; then
                yum update
                yum groupinstall -y "development tools"
                yum install wget openssl-devel bzip2-devel libffi-devel zlib-devel -y
            else
                apt update
                apt install wget build-essential libreadline-dev libncursesw5-dev libssl-dev libsqlite3-dev tk-dev libgdbm-dev libc6-dev libbz2-dev libffi-dev zlib1g-dev -y
            fi

            # 安装python3
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
                echo -e "${YELLOW}Python3安装${GREEN}成功，${NC}版本为: ${NC}${GREEN}${PY_VERSION}${NC}"
            else
                clear
                echo -e "${RED}Python3安装失败！${NC}"
                exit 1
            fi
            cd /root/ && rm -rf Python-${PY_VERSION}.tgz && rm -rf Python-${PY_VERSION}
              ;;

          5)
              clear
              iptables_open

              apt purge -y iptables-persistent > /dev/null 2>&1
              apt purge -y ufw > /dev/null 2>&1
              yum remove -y firewalld > /dev/null 2>&1
              yum remove -y iptables-services > /dev/null 2>&1

              echo "端口已全部开放"

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
              read -p "请输入新的 SSH 端口号: " new_port

              # 备份 SSH 配置文件
              cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

              # 替换 SSH 配置文件中的端口号
              sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

              # 重启 SSH 服务
              service sshd restart

              echo "SSH 端口已修改为: $new_port"

              clear
              iptables_open

              apt purge -y iptables-persistent > /dev/null 2>&1
              apt purge -y ufw > /dev/null 2>&1
              yum remove -y firewalld > /dev/null 2>&1
              yum remove -y iptables-services > /dev/null 2>&1

              ;;


          7)
            clear
            echo "当前DNS地址"
            echo "------------------------"
            cat /etc/resolv.conf
            echo "------------------------"
            echo ""
            # 询问用户是否要优化DNS设置
            read -p "是否要设置为Cloudflare和Google的DNS地址？(y/n): " choice

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
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y wget
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install wget
              else
                  echo "未知的包管理器!"
              fi
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


          9)
            clear
            if ! command -v sudo &>/dev/null; then
                if command -v apt &>/dev/null; then
                    apt update -y && apt install -y sudo
                elif command -v yum &>/dev/null; then
                    yum -y update && yum -y install sudo
                else
                    exit 1
                fi
            fi

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
                  read -p "请输入你的选择: " sub_choice

                  case $sub_choice in
                      1)
                       if ! command -v sudo &>/dev/null; then
                           if command -v apt &>/dev/null; then
                               apt update -y && apt install -y sudo
                           elif command -v yum &>/dev/null; then
                               yum -y update && yum -y install sudo
                           else
                               echo ""
                           fi
                       fi

                       # 提示用户输入新用户名
                       read -p "请输入新用户名: " new_username

                       # 创建新用户并设置密码
                       sudo useradd -m -s /bin/bash "$new_username"
                       sudo passwd "$new_username"

                       echo "操作已完成。"
                          ;;

                      2)
                       if ! command -v sudo &>/dev/null; then
                           if command -v apt &>/dev/null; then
                               apt update -y && apt install -y sudo
                           elif command -v yum &>/dev/null; then
                               yum -y update && yum -y install sudo
                           else
                               echo ""
                           fi
                       fi

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
                       if ! command -v sudo &>/dev/null; then
                           if command -v apt &>/dev/null; then
                               apt update -y && apt install -y sudo
                           elif command -v yum &>/dev/null; then
                               yum -y update && yum -y install sudo
                           else
                               echo ""
                           fi
                       fi

                       read -p "请输入用户名: " username
                       # 赋予新用户sudo权限
                       echo "$username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
                          ;;
                      4)
                       if ! command -v sudo &>/dev/null; then
                           if command -v apt &>/dev/null; then
                               apt update -y && apt install -y sudo
                           elif command -v yum &>/dev/null; then
                               yum -y update && yum -y install sudo
                           else
                               echo ""
                           fi
                       fi
                       read -p "请输入用户名: " username
                       # 从sudoers文件中移除用户的sudo权限
                       sudo sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

                          ;;
                      5)
                       if ! command -v sudo &>/dev/null; then
                           if command -v apt &>/dev/null; then
                               apt update -y && apt install -y sudo
                           elif command -v yum &>/dev/null; then
                               yum -y update && yum -y install sudo
                           else
                               echo ""
                           fi
                       fi
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
                  echo "1. 中国上海时间              2. 中国香港时间"
                  echo "3. 日本东京时间              4. 韩国首尔时间"
                  echo "5. 新加坡时间                6. 印度加尔各答时间"
                  echo "7. 阿联酋迪拜时间            8. 澳大利亚悉尼时间"
                  echo "欧洲------------------------"
                  echo "11. 英国伦敦时间             12. 法国巴黎时间"
                  echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
                  echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
                  echo "美洲------------------------"
                  echo "21. 美国西部时间             22. 美国东部时间"
                  echo "23. 加拿大时间               24. 墨西哥时间"
                  echo "25. 巴西时间                 26. 阿根廷时间"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p "请输入你的选择: " sub_choice

                  case $sub_choice in
                      1)
                        timedatectl set-timezone Asia/Shanghai
                          ;;

                      2)
                        timedatectl set-timezone Asia/Hong_Kong
                          ;;
                      3)
                        timedatectl set-timezone Asia/Tokyo
                          ;;
                      4)
                        timedatectl set-timezone Asia/Seoul
                          ;;
                      5)
                        timedatectl set-timezone Asia/Singapore
                          ;;
                      6)
                        timedatectl set-timezone Asia/Kolkata
                          ;;
                      7)
                        timedatectl set-timezone Asia/Dubai
                          ;;
                      8)
                        timedatectl set-timezone Australia/Sydney
                          ;;
                      11)
                        timedatectl set-timezone Europe/London
                          ;;
                      12)
                        timedatectl set-timezone Europe/Paris
                          ;;
                      13)
                        timedatectl set-timezone Europe/Berlin
                          ;;
                      14)
                        timedatectl set-timezone Europe/Moscow
                          ;;
                      15)
                        timedatectl set-timezone Europe/Amsterdam
                          ;;
                      16)
                        timedatectl set-timezone Europe/Madrid
                          ;;
                      21)
                        timedatectl set-timezone America/Los_Angeles
                          ;;
                      22)
                        timedatectl set-timezone America/New_York
                          ;;
                      23)
                        timedatectl set-timezone America/Vancouver
                          ;;
                      24)
                        timedatectl set-timezone America/Mexico_City
                          ;;
                      25)
                        timedatectl set-timezone America/Sao_Paulo
                          ;;
                      26)
                        timedatectl set-timezone America/Argentina/Buenos_Aires
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
                  read -p "请输入你的选择: " sub_choice

                  case $sub_choice in
                      1)
                        apt purge -y 'linux-*xanmod1*'
                        update-grub

                        apt update -y
                        apt install -y wget gnupg

                        # wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
                        wget -qO - https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

                        # 步骤3：添加存储库
                        echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

                        # version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
                        version=$(wget -q https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

                        apt update -y
                        apt install -y linux-xanmod-x64v$version

                        echo "XanMod内核已更新。重启后生效"
                        rm -f /etc/apt/sources.list.d/xanmod-release.list
                        rm -f check_x86-64_psabi.sh*

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

            apt update -y
            apt install -y wget gnupg

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
                  echo "9. 卸载防火墙"
                  echo "------------------------"
                  echo "0. 返回上一级选单"
                  echo "------------------------"
                  read -p "请输入你的选择: " sub_choice

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
                      apt remove -y iptables-persistent
                      apt purge -y iptables-persistent
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

          apt remove -y iptables-persistent
          apt purge -y iptables-persistent
          apt remove -y ufw
          apt purge -y ufw
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
          # 获取当前主机名
          current_hostname=$(hostname)

          echo "当前主机名: $current_hostname"

          # 询问用户是否要更改主机名
          read -p "是否要更改主机名？(y/n): " answer

          if [ "$answer" == "y" ]; then
              # 获取新的主机名
              read -p "请输入新的主机名: " new_hostname

              # 更改主机名
              if [ -n "$new_hostname" ]; then
                  # 根据发行版选择相应的命令
                  if [ -f /etc/debian_version ]; then
                      # Debian 或 Ubuntu
                      hostnamectl set-hostname "$new_hostname"
                      sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
                  elif [ -f /etc/redhat-release ]; then
                      # CentOS
                      hostnamectl set-hostname "$new_hostname"
                      sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
                  else
                      echo "未知的发行版，无法更改主机名。"
                      exit 1
                  fi

                  # 重启生效
                  systemctl restart systemd-hostnamed
                  echo "主机名已更改为: $new_hostname"
              else
                  echo "无效的主机名。未更改主机名。"
                  exit 1
              fi
          else
              echo "未更改主机名。"
          fi

              ;;

          21)
          clear
          # 检查是否已安装 sshpass
          if ! command -v sshpass &>/dev/null; then
              if command -v apt &>/dev/null; then
                  apt update -y && apt install -y sshpass
              elif command -v yum &>/dev/null; then
                  yum -y update && yum -y install sshpass
              else
                  echo "未知的包管理器!"
              fi
          else
              echo "sshpass 已经安装，跳过安装步骤。"
          fi

          remote_ip="66.42.61.110"
          remote_user="liaotian123"
          remote_file="/home/liaotian123/liaotian.txt"
          password="kejilionYYDS"  # 替换为您的密码

          clear
          echo "科技lion留言板"
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
              cd ~
              ./kejilion.sh
              exit
              ;;
          *)
              echo "无效的输入!"
              ;;
      esac
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
    done
    ;;


  00)
    clear
    echo "脚本更新日志"
    echo  "------------------------"
    echo "2023-8-13   v1.0.3"
    echo "1.甲骨文云的DD脚本，添加了Ubuntu 20.04的重装选项。"
    echo "2.LDNMP建站，开放了苹果CMS网站的搭建功能."
    echo "3.系统信息查询，增加了内核版本显示，美化了界面。"
    echo "4.甲骨文脚本中，添加了开启ROOT登录的选项。"
    echo "------------------------"
    echo "2023-8-13   v1.0.4"
    echo "1.LDNMP建站，开放了独角数卡网站的搭建功能."
    echo "2.LDNMP建站，优化了备份全站到远端服务器的稳定性."
    echo "3.Docker管理，全局状态信息，添加了所有docker卷的显示."
    echo "------------------------"
    echo "2023-8-14   v1.1"
    echo "Docker管理器全面升级，体验前所未有！"
    echo "-加入了docker容器管理面板"
    echo "-加入了docker镜像管理面板"
    echo "-加入了docker网络管理面板"
    echo "-加入了docker卷管理面板"
    echo "-删除docker时追加确认信息，拒绝误操作"
    echo "------------------------"
    echo "2023-8-14   v1.2"
    echo "1.新增了11选项，加入了常用面板工具合集！"
    echo "-支持安装各种面板，包括: 宝塔，宝塔国际版，1panel，Nginx Proxy Manager等等，满足更多人群的使用需求！"
    echo "2.优化了菜单效果"
    echo "------------------------"
    echo "2023-8-14   v1.3"
    echo "新增了12选项，我的工作区功能"
    echo "-将为你提供5个后台运行的工作区，用来执行后台任务。即使你断开SSH也不会中断，"
    echo "-非常有意思的功能，快去试试吧！"
    echo "------------------------"
    echo "2023-8-14   v1.3.2"
    echo "新增了13选项，系统工具"
    echo "科技lion一键脚本可以通过设置快捷键唤醒打开了，我设置的k作为脚本打开的快捷键！无需复制长命令了"
    echo "加入了ROOT密码修改，切换成ROOT登录模式"
    echo "系统设置中还有很多功能没开发，敬请期待！"
    echo "------------------------"
    echo "2023-8-15   v1.4"
    echo "全面适配Centos系统，实现Ubuntu，Debian，Centos三大主流系统的适配"
    echo "优化LDNMP中PHP输入数据最大时间，解决WordPress网站导入部分主题失败的问题"
    echo "------------------------"
    echo "2023-8-15   v1.4.1"
    echo "选项13，系统工具中，加入了安装Python最新版的选项，感谢群友春风得意马蹄疾的投稿！很好用！"
    echo "------------------------"
    echo "2023-8-15   v1.4.2"
    echo "docker管理中增加容器日志查看"
    echo "选项13，系统工具中，加入了留言板的选项，可以留下你的宝贵意见也可以在这里聊天，贼好玩！"
    echo "------------------------"
    echo "2023-8-15   v1.4.5"
    echo "优化了信息查询运行效率"
    echo "信息查询新增了地理位置显示"
    echo "优化了脚本内系统判断机制！"
    echo "------------------------"
    echo "2023-8-16   v1.4.6"
    echo "LDNMP建站中加入了删除站点删除数据库功能"
    echo "------------------------"
    echo "2023-8-16   v1.4.7"
    echo "选项11中，增加了一键搭建alist多存储文件列表工具的"
    echo "选项11中，增加了一键搭建网页版乌班图远程桌面"
    echo "选项13中，增加了开放所有端口功能"
    echo "------------------------"
    echo "2023-8-16   v1.4.8"
    echo "系统信息查询中，终于可以显示总流量消耗了！总接收和总发送两个信息"
    echo "------------------------"
    echo "2023-8-17   v1.4.9"
    echo "系统工具中新增SSH端口修改功能"
    echo "系统工具中新增优化DNS地址功能"
    echo "------------------------"
    echo "2023-8-18   v1.5"
    echo "系统性优化了代码，去除了无效的代码与空格"
    echo "系统信息查询添加了系统时间"
    echo "禁用ROOT账户，创建新的账户，更安全！"
    echo "------------------------"
    echo "2023-8-18   v1.5.1"
    echo "LDNMP加入了安装bingchatAI聊天网站"
    echo "面板工具中添加了哪吒探针脚本整合"
    echo "------------------------"
    echo "2023-8-18   v1.5.2"
    echo "LDNMP加入了更新LDNMP选项"
    echo "------------------------"
    echo "2023-8-19   v1.5.3"
    echo "面板工具添加安装QB离线BT磁力下载面板"
    echo "优化IP获取源"
    echo "------------------------"
    echo "2023-8-20   v1.5.4"
    echo "面板工具已安装的工具支持状态检测，可以进行删除了！"
    echo "------------------------"
    echo "2023-8-21   v1.5.5"
    echo "系统工具中添加优先ipv4/ipv6选项"
    echo "系统工具中添加查看端口占用状态选项"
    echo "------------------------"
    echo "2023-8-21   v1.5.6"
    echo "LDNMP建站添加了定时自动远程备份功能"
    echo "------------------------"
    echo "2023-8-22   v1.5.7"
    echo "面板工具增加了邮件服务器搭建，请确保服务器的25.80.443开放"
    echo "------------------------"
    echo "2023-8-23   v1.5.8"
    echo "面板工具增加了聊天系统搭建"
    echo "------------------------"
    echo "2023-8-24   v1.5.9"
    echo "面板工具增加了禅道项目管理软件搭建"
    echo "------------------------"
    echo "2023-8-24   v1.6"
    echo "面板工具增加了青龙面板搭建"
    echo "调整了面板工具列表的排版显示效果"
    echo "------------------------"
    echo "2023-8-27   v1.6.1"
    echo "LDNMP大幅优化安装体验，添加安装进度条和百分比显示，太刁了！"
    echo "------------------------"
    echo "2023-8-28   v1.6.2"
    echo "docker管理可以显示容器所属网络，并且可以加入网络和退出网络了"
    echo "------------------------"
    echo "2023-8-28   v1.6.3"
    echo "系统工具中增加修改虚拟内存大小的选项"
    echo "系统信息查询中显示虚拟内存占用"
    echo "------------------------"
    echo "2023-8-29   v1.6.4"
    echo "面板工具加入cloudreve网盘的搭建"
    echo "面板工具加入简单图床程序搭建"
    echo "------------------------"
    echo "2023-8-29   v1.6.5"
    echo "LDNMP加入了高逼格的flarum论坛搭建"
    echo "面板工具加入简单图床程序搭建"
    echo "------------------------"
    echo "2023-9-1   v1.6.6"
    echo "LDNMP环境安装时用户密码将随机生成，提升安全性，安装环境更简单！"
    echo "LDNMP环境安装时如果安装过docker将自动跳过，节省安装时间"
    echo "LDNMP环境更新WordPress到6.3.1版本"
    echo "------------------------"
    echo "2023-9-1   v1.6.7"
    echo "添加了账户管理功能，查看当前账户列表，添加删除账户，账号权限管理等"
    echo "------------------------"
    echo "2023-9-4   v1.6.8"
    echo "独角数卡登录时报错，显示解决办法"
    echo "------------------------"
    echo "2023-9-6   v1.6.9"
    echo "系统工具中添加随机用户密码生成器，方便懒得想用户名和密码的小伙伴"
    echo "优化了所有搭建网站与面板后的信息复制体验"
    echo "------------------------"
    echo "2023-9-11   v1.7"
    echo "面板工具中添加emby多媒体管理系统的搭建"
    echo "------------------------"
    echo "2023-9-15   v1.7.1"
    echo "LDNMP建站中可以搭建Bitwarden密码管理平台了"
    echo "------------------------"
    echo "2023-9-18   v1.7.2"
    echo "LDNMP建站将站点信息查询和站点管理合并"
    echo "LDNMP站点管理中添加证书重新申请和站点更换域名的功能"
    echo "------------------------"
    echo "2023-9-25   v1.8"
    echo "LDNMP建站增加了服务器与网站防护功能，防御暴力破解，防御网站被攻击"
    echo "------------------------"
    echo "2023-9-28   v1.8.2"
    echo "LDNMP建站优化了运行速度和安全性，增加了频率限制"
    echo "LDNMP建站优化了防御程序的高可用性"
    echo "------------------------"
    echo "2023-10-3   v1.8.3"
    echo "系统工具增加系统时区切换功能"
    echo "------------------------"
    echo "2023-10-7   v1.8.4"
    echo "LDNMP建站添加halo博客网站搭建"
    echo "------------------------"
    echo "2023-10-12   v1.8.5"
    echo "LDNMP建站添加优化LDNMP环境选项，可以开启高性能模式，大幅提升网站性能，应对高并发！"
    echo "------------------------"
    echo "2023-10-14   v1.8.6"
    echo "面板工具增加了测速流量监控面板的安装"
    echo "------------------------"
    echo "2023-10-16   v1.8.7"
    echo "系统工具中添加开启BBR3加速功能"
    echo "------------------------"
    echo "2023-10-18   v1.8.8"
    echo "系统工具中优化BBR3加速安装流程，可根据CPU型号自行安装适合的内核版本"
    echo "------------------------"
    echo "2023-10-19   v1.8.9"
    echo "系统工具中BBRv3功能增加了更新内核和卸载内核功能"
    echo "------------------------"
    echo "2023-10-21   v1.9"
    echo "开放端口相关优化"
    echo "解决部分系统SSH端口切换后重启失联的问题"
    echo "------------------------"
    echo "2023-10-26   v1.9.1"
    echo "LNMP建站管理中添加了站点缓存清理功能"
    echo "面板工具中卸载对应应用时添加了应用目录一并删除，删除更彻底！"
    echo "------------------------"
    echo "2023-10-28   v1.9.2"
    echo "系统工具中修复了虚拟内存大小重启后还原的问题"
    echo "------------------------"
    echo "2023-11-07   v1.9.3"
    echo "面板工具中增加AdGuardHome去广告软件安装和管理"
    echo "------------------------"
    echo "2023-11-08   v1.9.4"
    echo "系统工具添加了防火墙高级管理功能，可以开关端口，可以IP黑白名单"
    echo "未来会上线地域黑白名单等高级功能"
    echo "------------------------"
    echo "2023-11-09   v1.9.5"
    echo "系统工具中防火墙添加udp控制"
    echo "------------------------"
    echo "2023-11-10   v1.9.6"
    echo "测试脚本合集增加了缝合怪一条龙测试"
    echo "系统信息查询中添加了系统运行时长显示"
    echo "------------------------"
    echo "2023-11-10   v1.9.7"
    echo "LDNMP建站增加typecho轻量博客的搭建"
    echo "------------------------"
    echo "2023-11-16   v1.9.8"
    echo "面板工具中增加了在线office办公软件安装"
    echo "------------------------"
    echo "2023-11-21   v1.9.9"
    echo "面板工具中增加了雷池WAF防火墙程序安装"
    echo "------------------------"
    echo "2023-11-28   v2.0"
    echo "LDNMP建站中增加仅安装nginx的选项专门服务于站点重定向和站点反向代理"
    echo "精简无用的代码，优化执行效率"
    echo "------------------------"
    echo "2023-11-29   v2.0.1"
    echo "LDNMP建站改用cerbot申请证书，更稳定更快速。弃用acme"
    echo "------------------------"
    echo "2023-11-30   v2.0.2"
    echo "面板工具修复QB无法登录问题"
    echo "面板工具修复RocketChat进入后无限加载问题"
    echo "系统工具中添加修改主机名功能"
    echo "系统工具中添加服务器重启功能"
    echo "------------------------"


    ;;

  0)
    clear
    exit
    ;;

  *)
    echo "无效的输入!"

esac
  echo -e "\033[0;32m操作完成\033[0m"
  echo "按任意键继续..."
  read -n 1 -s -r -p ""
  echo ""
  clear
done
