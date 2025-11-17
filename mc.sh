#!/bin/bash
ln -sf ~/mc.sh /usr/local/bin/mcs

ip_address() {
    # 检测 IPv4 地址
    ipv4_address=$(curl -s --connect-timeout 5 ipv4.ip.sb 2>/dev/null || echo "")
    # 检测 IPv6 地址
    ipv6_address=$(curl -s --connect-timeout 5 ipv6.ip.sb 2>/dev/null || echo "")

    # 设置显示变量
    if [ -n "$ipv4_address" ] && [ -n "$ipv6_address" ]; then
        ip_display="\033[93m IPv4: $ipv4_address:25565 IPv6: $ipv6_address:25565 \033[0m"
    elif [ -n "$ipv4_address" ]; then
        ip_display="\033[93m IPv4: $ipv4_address:25565 \033[0m"
    elif [ -n "$ipv6_address" ]; then
        ip_display="\033[93m IPv6: $ipv6_address:25565 \033[0m"
    else
        ip_display="\033[93m 无法获取IP地址 \033[0m"
    fi
}


install() {
    if [ $# -eq 0 ]; then
        echo "未提供软件包参数!"
        return 1
    fi

    for package in "$@"; do
        if ! command -v "$package" &>/dev/null; then
            if command -v apt &>/dev/null; then
                apt update -y && apt install -y "$package"
            elif command -v yum &>/dev/null; then
                yum -y update && yum -y install "$package"
            elif command -v apk &>/dev/null; then
                apk update && apk add "$package"
            else
                echo "未知的包管理器!"
                return 1
            fi
        fi
    done

    return 0
}


remove() {
    if [ $# -eq 0 ]; then
        echo "未提供软件包参数!"
        return 1
    fi

    for package in "$@"; do
        if command -v apt &>/dev/null; then
            apt purge -y "$package"
        elif command -v yum &>/dev/null; then
            yum remove -y "$package"
        elif command -v apk &>/dev/null; then
            apk del "$package"
        else
            echo "未知的包管理器!"
            return 1
        fi
    done

    return 0
}


break_end() {
      echo -e "\033[0;32m操作完成\033[0m"
      echo "按任意键继续..."
      read -n 1 -s -r -p ""
      echo ""
      clear
}

mc() {
            p
            exit
}


install_add_docker() {
    if [ -f "/etc/alpine-release" ]; then
        apk update
        apk add docker docker-compose
        rc-update add docker default
        service docker start
    else
        curl -fsSL https://get.docker.com | sh && ln -s /usr/libexec/docker/cli-plugins/docker-compose /usr/local/bin
        systemctl start docker
        systemctl enable docker
    fi
}

install_docker() {
    if ! command -v docker &>/dev/null; then
        install_add_docker
    else
        echo "Docker 已经安装"
    fi
}

mc_start() {
    ip_address
    docker start mcserver > /dev/null 2>&1
    echo -e "\033[0;32mMinecraft服务启动啦！\033[0m"
    echo -e "\033[0;32m游戏下载地址: https://www.xbox.com/zh-cn/games/store/minecraft-java-bedrock-edition-for-pc/9nxp44l49shj\033[0m"
    echo -e "\033[0;32m进入游戏连接:$ip_display\033[0;32m开始冒险吧！\033[0m"

}

mc_backup() {
  cd ~
  curl -sS -O https://kejilion.pro/mc_backup.sh && chmod +x mc_backup.sh
}

mc_install_status() {
  CONTAINER_NAME="mcserver"

  # 检查容器是否已安装
  if [ "$(docker ps -a -q -f name=$CONTAINER_NAME 2>/dev/null)" ]; then
      container_status="\e[32mMinecraft服务已安装\e[0m"  # 绿色
  else
      container_status="\e[90mMinecraft服务未安装\e[0m"  # 灰色
  fi

  ip_address
  # 检查 Docker 容器是否正在运行
  if docker ps --format "table {{.Names}}" | grep -q "^$CONTAINER_NAME$"; then
      tmux_status="\e[32m已开服:$ip_display\e[0m"  # 绿色
  else
      tmux_status="\e[90m未开服\e[0m"  # 灰色
  fi

}

while true; do
clear
mc_install_status
echo -e "\033[92m███╗   ███╗██╗███╗   ██╗███████╗ ██████╗██████╗  █████╗ ███████╗████████╗\033[0m"
echo -e "\033[92m████╗ ████║██║████╗  ██║██╔════╝██╔════╝██╔══██╗██╔══██╗██╔════╝╚══██╔══╝\033[0m"
echo -e "\033[92m██╔████╔██║██║██╔██╗ ██║█████╗  ██║     ██████╔╝███████║█████╗     ██║   \033[0m"
echo -e "\033[92m██║╚██╔╝██║██║██║╚██╗██║██╔══╝  ██║     ██╔══██╗██╔══██║██╔══╝     ██║   \033[0m"
echo -e "\033[92m██║ ╚═╝ ██║██║██║ ╚████║███████╗╚██████╗██║  ██║██║  ██║██║        ██║   \033[0m"
echo -e "\033[92m╚═╝     ╚═╝╚═╝╚═╝  ╚═══╝╚══════╝ ╚═════╝╚═╝  ╚═╝╚═╝  ╚═╝╚═╝        ╚═╝   \033[0m"
echo -e "\033[92mMinecraft开服一键脚本工具v1.0.1  by AkarinLiu\033[0m"
echo -e "\033[92m-输入\033[92mmcs\033[92m可快速启动此脚本-\033[0m"
echo -e "$container_status $tmux_status"
echo "------------------------"
echo "1. 安装Minecraft服务"
echo "2. 开启Minecraft服务"
echo "3. 关闭Minecraft服务"
echo "4. 重启Minecraft服务"
echo "------------------------"
echo "5. 查看服务器状态"
echo "6. 设置虚拟内存"
echo "------------------------"
echo "7. 导出游戏存档"
echo "8. 导入游戏存档"
echo "9. 定时备份游戏存档"
echo "------------------------"
echo "10. 修改游戏配置"
echo "o.  添加管理员权限"
echo "p.  删除管理员权限"
echo "------------------------"
echo "11. 更新Minecraft服务"
echo "12. 卸载Minecraft服务"
echo "------------------------"
echo "k. 科技lion脚本工具箱"
echo "------------------------"
echo "00. 脚本更新"
echo "------------------------"
echo "0. 退出脚本"
echo "------------------------"
read -p "请输入你的选择: " choice

case $choice in
  1)
    clear
    install_docker
    docker run -d --name mcserver -p 25565:25565/tcp --restart=always -e EULA=true -e CREATE_CONSOLE_IN_PIPE=true -v mcserver:/data:rw itzg/minecraft-server
    clear
    mc_start
    ;;

  2)
    clear
    docker start $CONTAINER_NAME > /dev/null 2>&1
    mc_start
    ;;

  3)
    clear
    docker stop $CONTAINER_NAME > /dev/null 2>&1
    echo -e "\033[0;32mMinecraft服务已关闭\033[0m"
    ;;

  4)
    clear
    docker restart $CONTAINER_NAME > /dev/null 2>&1
    mc_start
    ;;

  5)
    clear
    install btop
    clear
    btop
    ;;

  6)
            clear
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

                if [ -f /etc/alpine-release ]; then
                    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
                    echo "nohup swapon /swapfile" >> /etc/local.d/swap.start
                    chmod +x /etc/local.d/swap.start
                    rc-update add local
                else
                    echo "/swapfile swap swap defaults 0 0" >> /etc/fstab
                fi

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

  7)
    clear
    mkdir -p /home/game
    docker cp $CONTAINER_NAME:/data/world /home/game/mc/ > /dev/null 2>&1
    cd /home/game && tar czvf mcsave_$(date +"%Y%m%d%H%M%S").tar.gz mc > /dev/null 2>&1
    rm -rf /home/game/mc/
    echo -e "\033[0;32m游戏存档已导出存放在: /home/game/mc/\033[0m"
    ;;
  8)
    clear
    docker stop mcserver > /dev/null 2>&1
    docker exec -it mcserver bash -c "rm -rf /data/world/*"
    cd /home/game/ && ls -t /home/game/mc/*.tar.gz | head -1 | xargs -I {} tar -xzf {}
    docker cp /home/game/mc/world/* mcserver:/data/world
    rm -rf /home/game/mc/
    echo -e "\033[0;32m游戏存档已导入\033[0m"
    docker restart mcserver > /dev/null 2>&1
    mc_start
    ;;

  9)
    clear
    echo "Minecraft游戏存档定时备份"
    echo "------------------------"
    echo "1. 每周备份       2. 每天备份       3. 每小时备份"
    echo "------------------------"
    read -p "请输入你的选择: " dingshi
    case $dingshi in
        1)
            mc_backup
            (crontab -l ; echo "0 0 * * 1 ./mc_backup.sh") | crontab - > /dev/null 2>&1
            echo "每周一备份，已设置"

            ;;
        2)
            mc_backup
            (crontab -l ; echo "0 3 * * * ./mc_backup.sh") | crontab - > /dev/null 2>&1
            echo "每天凌晨3点备份，已设置"

            ;;
        3)
            mc_backup
            (crontab -l ; echo "0 * * * * ./mc_backup.sh") | crontab - > /dev/null 2>&1
            echo "每小时整点备份，已设置"

            ;;
        *)
            echo "已取消"
            ;;
    esac
    ;;

  10)
    clear
    echo "配置游戏参数"
    echo "------------------------"
    read -p "设置游戏难度: （0.和平  1. 简单    2. 普通    3. 困难）:" Difficulty
      case $Difficulty in
        0)
            docker exec --user 1000 mcserver mc-send-to-console difficulty peaceful
            ;;
        1)
            docker exec --user 1000 mcserver mc-send-to-console difficulty easy
            ;;

        2)
            docker exec --user 1000 mcserver mc-send-to-console difficulty normal
            ;;
        3)
            docker exec --user 1000 mcserver mc-send-to-console difficulty hard
            ;;
        *)
            echo "-默认设置为普通难度"
            docker exec --user 1000 mcserver mc-send-to-console difficulty normal
            ;;
      esac

    read -p "死亡后掉落设置: （1. 掉落    2. 不掉落）:" DeathPenalty
      case $DeathPenalty in
        1)
            docker exec --user 1000 mcserver mc-send-to-console gamerule KeepInventoy false
            ;;

        2)
            docker exec --user 1000 mcserver mc-send-to-console gamerule KeepInventoy true
            ;;
        *)
            docker exec --user 1000 mcserver mc-send-to-console gamerule KeepInventoy false
            echo "-默认设置为掉落"
            ;;
      esac

    read -p "设置pvp模式: （1. 开启    2. 关闭）:" mc_pvp

      case $mc_pvp in
        1)
            docker exec --user 1000 mcserver mc-send-to-console gamerule pvp true
            ;;
        2)
            docker exec --user 1000 mcserver mc-send-to-console gamerule pvp false
            ;;
        *)
            docker exec --user 1000 mcserver mc-send-to-console gamerule pvp false
            echo "-默认关闭pvp模式"
            ;;
      esac

    # 更新配置
    echo -e "\033[0;32m游戏配置已更改\033[0m"
    ;;


  11)
    clear
    docker stop mcserver > /dev/null 2>&1
    docker restart mcserver > /dev/null 2>&1
    docker exec -it mcserver bash -c "/home/steam/mcserver/mcserver.sh +login anonymous +app_update 2394010 validate +quit"
    clear
    echo -e "\033[0;32mMinecraft已更新\033[0m"
    mc_start
    ;;

  12)
    clear
    docker rm -f mcserver
    docker rmi -f itzg/minecraft-server
    ;;
  o)
      read -p "请输入 Minecraft Java 版档案名称:" mc_op
      docker exec --user 1000 mcserver mc-send-to-console op $mc_op
      ;;
  p)
      read -p "请输入 Minecraft Java 版档案名称:" mc_deop
      docker exec --user 1000 mcserver mc-send-to-console deop $mc_deop
      ;;
  k)
    cd ~
    curl -sS -O https://kejilion.pro/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh
    exit
    ;;

  00)
    cd ~
    curl -sS -O https://kejilion.pro/mc_log.sh && chmod +x mc_log.sh && ./mc_log.sh
    rm mc_log.sh
    echo ""
    curl -sS -O https://kejilion.pro/mc.sh && chmod +x mc.sh
    echo "脚本已更新到最新版本！"
    break_end
    mc
    ;;


  0)
    clear
    exit
    ;;

  *)
    echo "无效的输入!"
    ;;
esac
    break_end
done
