#!/bin/bash
ln -sf ~/palworld.sh /usr/local/bin/p

ip_address() {
ipv4_address=$(curl -s ipv4.ip.sb)
ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
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

palworld() {
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

pal_start() {
    ip_address
    tmux new -d -s my1 "docker exec -it steamcmd bash -c '/home/steam/Steam/steamapps/common/PalServer/PalServer.sh'"
    echo -e "\033[0;32m幻兽帕鲁服务启动啦！\033[0m"
    echo -e "\033[0;32m游戏下载地址: https://store.steampowered.com/app/1623730\033[0m"
    echo -e "\033[0;32m进入游戏连接:\033[93m $ipv4_address:8255 \033[0;32m开始冒险吧！\033[0m"

}


while true; do
clear
echo -e "\033[93m      .            .  ."
echo "._  _.|.    , _ ._.| _|"
echo "[_)(_]| \/\/ (_)[  |(_]"
echo "|                      "
echo -e "\033[96m幻兽帕鲁私服一键脚本工具v1.0  by KEJILION\033[0m"
echo -e "\033[96m-输入\033[93mp\033[96m可快速启动此脚本-\033[0m"
echo "------------------------"
echo "1. 安装幻兽帕鲁服务"
echo "2. 启动幻兽帕鲁服务"
echo "3. 暂停幻兽帕鲁服务"
echo "4. 重启幻兽帕鲁服务"
echo "------------------------"
echo "5. 查看服务器状态"
echo "6. 设置虚拟内存"
echo "------------------------"
echo "7. 导出游戏存档"
echo "8. 导入游戏存档"
echo "------------------------"
echo "9. 更新幻兽帕鲁服务"
echo "10. 卸载幻兽帕鲁服务"
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
    install tmux
    docker run -dit --name steamcmd -p 8255:8211/udp --restart=always cm2network/steamcmd
    docker exec -it steamcmd bash -c "/home/steam/steamcmd/steamcmd.sh +login anonymous +app_update 2394010 validate +quit"
    clear
    pal_start
    ;;

  2)
    clear
    docker start steamcmd
    pal_start
    ;;

  3)
    clear
    docker stop steamcmd
    echo -e "\033[0;32m幻兽帕鲁服务已停止\033[0m"
    ;;

  4)
    clear
    docker restart steamcmd
    pal_start
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
    docker cp steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/Saved/ /home/game/palworld/
    echo -e "\033[0;32m游戏存档已导出存放在: /home/game/palworld/\033[0m"
    ;;
  8)
    clear
    docker cp -a /home/game/palworld/ steamcmd:/home/steam/Steam/steamapps/common/PalServer/Pal/
    echo -e "\033[0;32m游戏存档已导入\033[0m"
    docker restart steamcmd
    pal_start
    ;;
  9)
    clear
    docker restart steamcmd
    docker exec -it steamcmd bash -c "/home/steam/steamcmd/steamcmd.sh +login anonymous +app_update 2394010 validate +quit"
    clear
    echo -e "\033[0;32m幻兽帕鲁已更新\033[0m"
    pal_start
    ;;

  10)
    clear
    docker rm -f steamcmd
    docker rmi -f cm2network/steamcmd
    ;;

  00)
    cd ~
    curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/pal_log.sh && chmod +x pal_log.sh && ./pal_log.sh
    rm pal_log.sh
    echo ""
    curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/palworld.sh && chmod +x palworld.sh
    echo "脚本已更新到最新版本！"
    break_end
    palworld
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
