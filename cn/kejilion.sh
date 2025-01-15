#!/bin/bash
sh_v="3.6.2"


gl_hui='\e[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'



canshu="CN"
permission_granted="false"
ENABLE_STATS="true"


quanju_canshu() {
if [ "$canshu" = "CN" ]; then
	zhushi=0
	gh_proxy="https://gh.kejilion.pro/"
elif [ "$canshu" = "V6" ]; then
	zhushi=1
	gh_proxy="https://gh.kejilion.pro/"
else
	zhushi=1  # 0 表示执行，1 表示不执行
	gh_proxy=""
fi

}
quanju_canshu



# 定义一个函数来执行命令
run_command() {
	if [ "$zhushi" -eq 0 ]; then
		"$@"
	fi
}


canshu_v6() {
	if grep -q '^canshu="V6"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/kejilion.sh
		sed -i 's/^canshu="default"/canshu="V6"/' /usr/local/bin/k
	fi
}


CheckFirstRun_true() {
	if grep -q '^permission_granted="true"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	fi
}



# 收集功能埋点信息的函数，记录当前脚本版本号，使用时间，系统版本，CPU架构，机器所在国家和用户使用的功能名称，绝对不涉及任何敏感信息，请放心！请相信我！
# 为什么要设计这个功能，目的更好的了解用户喜欢使用的功能，进一步优化功能推出更多符合用户需求的功能。
# 全文可搜搜 send_stats 函数调用位置，透明开源，如有顾虑可拒绝使用。



send_stats() {

	if [ "$ENABLE_STATS" == "false" ]; then
		return
	fi

	local country=$(curl -s ipinfo.io/country)
	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')
	local cpu_arch=$(uname -m)
	curl -s -X POST "https://api.kejilion.pro/api/log" \
		 -H "Content-Type: application/json" \
		 -d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\",\"version\":\"$sh_v\"}" &>/dev/null &
}


yinsiyuanquan2() {

if grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
	sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
	sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
fi

}



canshu_v6
CheckFirstRun_true
yinsiyuanquan2

cp -f ./kejilion.sh ~/kejilion.sh > /dev/null 2>&1
cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1



CheckFirstRun_false() {
	if grep -q '^permission_granted="false"' /usr/local/bin/k > /dev/null 2>&1; then
		UserLicenseAgreement
	fi
}

# 提示用户同意条款
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}欢迎使用科技lion脚本工具箱${gl_bai}"
	echo "首次使用脚本，请先阅读并同意用户许可协议。"
	echo "用户许可协议: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "是否同意以上条款？(y/n): " user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "许可同意"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "许可拒绝"
		clear
		exit
	fi
}

CheckFirstRun_false





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
			echo -e "${gl_huang}正在安装 $package...${gl_bai}"
			if command -v dnf &>/dev/null; then
				dnf -y update
				dnf install -y epel-release
				dnf install -y "$package"
			elif command -v yum &>/dev/null; then
				yum -y update
				yum install -y epel-release
				yum install -y "$package"
			elif command -v apt &>/dev/null; then
				apt update -y
				apt install -y "$package"
			elif command -v apk &>/dev/null; then
				apk update
				apk add "$package"
			elif command -v pacman &>/dev/null; then
				pacman -Syu --noconfirm
				pacman -S --noconfirm "$package"
			elif command -v zypper &>/dev/null; then
				zypper refresh
				zypper install -y "$package"
			elif command -v opkg &>/dev/null; then
				opkg update
				opkg install "$package"
			else
				echo "未知的包管理器!"
				return 1
			fi
		else
			echo -e "${gl_lv}$package 已经安装${gl_bai}"
		fi
	done
}

install_dependency() {
	install wget unzip tar jq
}

remove() {
	if [ $# -eq 0 ]; then
		echo "未提供软件包参数!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}正在卸载 $package...${gl_bai}"
		if command -v dnf &>/dev/null; then
			dnf remove -y "$package"
		elif command -v yum &>/dev/null; then
			yum remove -y "$package"
		elif command -v apt &>/dev/null; then
			apt purge -y "$package"
		elif command -v apk &>/dev/null; then
			apk del "$package"
		elif command -v pacman &>/dev/null; then
			pacman -Rns --noconfirm "$package"
		elif command -v zypper &>/dev/null; then
			zypper remove -y "$package"
		elif command -v opkg &>/dev/null; then
			opkg remove "$package"
		else
			echo "未知的包管理器!"
			return 1
		fi
	done
}


# 通用 systemctl 函数，适用于各种发行版
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# 重启服务
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务已重启。"
	else
		echo "错误：重启 $1 服务失败。"
	fi
}

# 启动服务
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务已启动。"
	else
		echo "错误：启动 $1 服务失败。"
	fi
}

# 停止服务
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务已停止。"
	else
		echo "错误：停止 $1 服务失败。"
	fi
}

# 查看服务状态
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1 服务状态已显示。"
	else
		echo "错误：无法显示 $1 服务状态。"
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME 已设置为开机自启。"
}



break_end() {
	  echo -e "${gl_lv}✔️  操作完成${gl_bai}"
	  echo "按任意键继续..."
	  read -n 1 -s -r -p ""
	  echo ""
	  clear
}

kejilion() {
			cd ~
			kejilion_sh
}




check_port() {
	install lsof

	stop_containers_or_kill_process() {
		local port=$1
		local containers=$(docker ps --filter "publish=$port" --format "{{.ID}}" 2>/dev/null)

		if [ -n "$containers" ]; then
			docker stop $containers
		else
			for pid in $(lsof -t -i:$port); do
				kill -9 $pid
			done
		fi
	}

	stop_containers_or_kill_process 80
	stop_containers_or_kill_process 443
}


install_add_docker_cn() {

local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	cat > /etc/docker/daemon.json << EOF
{
	"registry-mirrors": ["https://docker.kejilion.pro"]
}
EOF

fi


enable docker
start docker
restart docker

}


install_add_docker_guanfang() {
local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	cd ~
	curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/docker/main/install && chmod +x install
	sh install --mirror Aliyun
	rm -f install
else
	curl -fsSL https://get.docker.com | sh
fi
install_add_docker_cn


}



install_add_docker() {
	echo -e "${gl_huang}正在安装docker环境...${gl_bai}"
	if  [ -f /etc/os-release ] && grep -q "Fedora" /etc/os-release; then
		install_add_docker_guanfang
	elif command -v dnf &>/dev/null; then
		dnf update -y
		dnf install -y yum-utils device-mapper-persistent-data lvm2
		rm -f /etc/yum.repos.d/docker*.repo > /dev/null
		country=$(curl -s ipinfo.io/country)
		arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/centos/docker-ce.repo | tee /etc/yum.repos.d/docker-ce.repo > /dev/null
		else
			yum-config-manager --add-repo https://download.docker.com/linux/centos/docker-ce.repo > /dev/null
		fi
		dnf install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn

	elif [ -f /etc/os-release ] && grep -q "Kali" /etc/os-release; then
		apt update
		apt upgrade -y
		apt install -y apt-transport-https ca-certificates curl gnupg lsb-release
		rm -f /usr/share/keyrings/docker-archive-keyring.gpg
		local country=$(curl -s ipinfo.io/country)
		local arch=$(uname -m)
		if [ "$country" = "CN" ]; then
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/etc\/apt\/keyrings\/docker-archive-keyring.gpg\] https:\/\/mirrors.aliyun.com\/docker-ce\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://mirrors.aliyun.com/docker-ce/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://mirrors.aliyun.com/docker-ce/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			fi
		else
			if [ "$arch" = "x86_64" ]; then
				sed -i '/^deb \[arch=amd64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=amd64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			elif [ "$arch" = "aarch64" ]; then
				sed -i '/^deb \[arch=arm64 signed-by=\/usr\/share\/keyrings\/docker-archive-keyring.gpg\] https:\/\/download.docker.com\/linux\/debian bullseye stable/d' /etc/apt/sources.list.d/docker.list > /dev/null
				mkdir -p /etc/apt/keyrings
				curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor -o /etc/apt/keyrings/docker-archive-keyring.gpg > /dev/null
				echo "deb [arch=arm64 signed-by=/etc/apt/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian bullseye stable" | tee /etc/apt/sources.list.d/docker.list > /dev/null
			fi
		fi
		apt update
		apt install -y docker-ce docker-ce-cli containerd.io
		install_add_docker_cn


	elif command -v apt &>/dev/null || command -v yum &>/dev/null; then
		install_add_docker_guanfang
	else
		install docker docker-compose
		install_add_docker_cn

	fi
	sleep 2
}


install_docker() {
	if ! command -v docker &>/dev/null; then
		install_add_docker
	else
		echo -e "${gl_lv}Docker环境已经安装${gl_bai}"
	fi
}


docker_ps() {
while true; do
	clear
	send_stats "Docker容器管理"
	echo "Docker容器列表"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "容器操作"
	echo "------------------------"
	echo "1. 创建新的容器"
	echo "------------------------"
	echo "2. 启动指定容器             6. 启动所有容器"
	echo "3. 停止指定容器             7. 停止所有容器"
	echo "4. 删除指定容器             8. 删除所有容器"
	echo "5. 重启指定容器             9. 重启所有容器"
	echo "------------------------"
	echo "11. 进入指定容器           12. 查看容器日志"
	echo "13. 查看容器网络           14. 查看容器占用"
	echo "------------------------"
	echo "0. 返回上一级选单"
	echo "------------------------"
	read -e -p "请输入你的选择: " sub_choice
	case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "请输入创建命令: " dockername
			$dockername
			;;
		2)
			send_stats "启动指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker stop $dockername
			;;
		4)
			send_stats "删除指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重启指定容器"
			read -e -p "请输入容器名（多个容器名请用空格分隔）: " dockername
			docker restart $dockername
			;;
		6)
			send_stats "启动所有容器"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "停止所有容器"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "删除所有容器"
			read -e -p "$(echo -e "${gl_hong}🚨  注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
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
			send_stats "重启所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "进入容器"
			read -e -p "请输入容器名: " dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日志"
			read -e -p "请输入容器名: " dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "查看容器网络"
			echo ""
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"
			for container_id in $container_ids; do
				local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")
				local container_name=$(echo "$container_info" | awk '{print $1}')
				local network_info=$(echo "$container_info" | cut -d' ' -f2-)
				while IFS= read -r line; do
					local network_name=$(echo "$line" | awk '{print $1}')
					local ip_address=$(echo "$line" | awk '{print $2}')
					printf "%-20s %-20s %-15s\n" "$container_name" "$network_name" "$ip_address"
				done <<< "$network_info"
			done
			break_end
			;;
		14)
			send_stats "查看容器占用"
			docker stats --no-stream
			break_end
			;;
		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done
}


docker_image() {
while true; do
	clear
	send_stats "Docker镜像管理"
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
	read -e -p "请输入你的选择: " sub_choice
	case $sub_choice in
		1)
			send_stats "拉取镜像"
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在获取镜像: $name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新镜像"
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在更新镜像: $name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "删除镜像"
			read -e -p "请输入镜像名（多个镜像名请用空格分隔）: " imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "删除所有镜像"
			read -e -p "$(echo -e "${gl_hong}🚨  注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
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
		*)
			break  # 跳出循环，退出菜单
			;;
	esac
done


}





check_crontab_installed() {
	if command -v crontab >/dev/null 2>&1; then
		echo -e "${gl_lv}crontab 已经安装${gl_bai}"
		return
	else
		install_crontab
		return
	fi
}



install_crontab() {

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case "$ID" in
			ubuntu|debian|kali)
				apt update
				apt install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			centos|rhel|almalinux|rocky|fedora)
				yum install -y cronie
				systemctl enable crond
				systemctl start crond
				;;
			alpine)
				apk add --no-cache cronie
				rc-update add crond
				rc-service crond start
				;;
			arch|manjaro)
				pacman -S --noconfirm cronie
				systemctl enable cronie
				systemctl start cronie
				;;
			opensuse|suse|opensuse-tumbleweed)
				zypper install -y cron
				systemctl enable cron
				systemctl start cron
				;;
			openwrt|lede)
				opkg update
				opkg install cron
				/etc/init.d/cron enable
				/etc/init.d/cron start
				;;
			*)
				echo "不支持的发行版: $ID"
				return
				;;
		esac
	else
		echo "无法确定操作系统。"
		return
	fi

	echo -e "${gl_lv}crontab 已安装且 cron 服务正在运行。${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 检查配置文件是否存在，如果不存在则创建文件并写入默认设置
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# 使用jq处理配置文件的更新
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 检查当前配置是否已经有 ipv6 设置
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 更新配置，开启 IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 对比原始配置与新配置
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}当前已开启ipv6访问${gl_bai}"
		else
			echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
			restart docker
		fi
	fi
}


docker_ipv6_off() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"

	# 检查配置文件是否存在
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}配置文件不存在${gl_bai}"
		return
	fi

	# 读取当前配置
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# 使用jq处理配置文件的更新
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 检查当前的 ipv6 状态
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 对比原始配置与新配置
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}当前已关闭ipv6访问${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}已成功关闭ipv6访问${gl_bai}"
	fi
}




iptables_open() {
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	ip6tables -P INPUT ACCEPT
	ip6tables -P FORWARD ACCEPT
	ip6tables -P OUTPUT ACCEPT
	ip6tables -F

}



add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 获取当前系统中所有的 swap 分区
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 遍历并删除所有的 swap 分区
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# 确保 /swapfile 不再被使用
	swapoff /swapfile

	# 删除旧的 /swapfile
	rm -f /swapfile

	# 创建新的 swap 分区
	fallocate -l ${new_swap}M /swapfile
	chmod 600 /swapfile
	mkswap /swapfile
	swapon /swapfile

	sed -i '/\/swapfile/d' /etc/fstab
	echo "/swapfile swap swap defaults 0 0" >> /etc/fstab

	if [ -f /etc/alpine-release ]; then
		echo "nohup swapon /swapfile" > /etc/local.d/swap.start
		chmod +x /etc/local.d/swap.start
		rc-update add local
	fi

	echo -e "虚拟内存大小已调整为${gl_huang}${new_swap}${gl_bai}MB"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 判断是否需要创建虚拟内存
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # 获取nginx版本
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # 获取mysql版本
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # 获取php版本
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # 获取redis版本
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 创建必要的目录和文件
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/default10.conf

  default_server_ssl

  # 下载 docker-compose.yml 文件并进行替换
  wget -O /home/web/docker-compose.yml ${gh_proxy}https://raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # 在 docker-compose.yml 文件中进行替换
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}





install_ldnmp() {

	  check_swap

	  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

	  if ! grep -q "healthcheck" /home/web/docker-compose.yml; then
		wget -O /home/web/docker-compose.yml ${gh_proxy}https://raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
	  	dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
	  	dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')
	  	dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose1.yml | tr -d '[:space:]')

  		sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  		sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  		sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml
	  fi

	  if grep -q "kjlion/nginx:alpine" /home/web/docker-compose1.yml; then
	  	sed -i 's|kjlion/nginx:alpine|nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml  > /dev/null 2>&1
	  fi

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -
	  restart_ldnmp

	  clear
	  echo "LDNMP环境安装完毕"
	  echo "------------------------"
	  ldnmp_v

}


install_certbot() {

	cd ~
	curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
	chmod +x auto_cert_renewal.sh

	check_crontab_installed
	local cron_job="0 0 * * * ~/auto_cert_renewal.sh"

	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -z "$existing_cron" ]; then
		(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
		echo "续签任务已添加"
	fi
}


install_ssltls() {
	  docker stop nginx > /dev/null 2>&1
	  iptables_open > /dev/null 2>&1
	  check_port > /dev/null 2>&1
	  cd ~

	  local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	  if [ ! -f "$file_path" ]; then
		 	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	  		local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
			if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
				mkdir -p /etc/letsencrypt/live/$yuming/
				if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
					openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				else
					openssl genpkey -algorithm Ed25519 -out /etc/letsencrypt/live/$yuming/privkey.pem
					openssl req -x509 -key /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				fi
			else
				docker run -it --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
			fi
	  fi

	  cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
	  cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

	  docker start nginx > /dev/null 2>&1
}



install_ssltls_text() {
	echo -e "${gl_huang}$yuming 公钥信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming 私钥信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}证书存放路径${gl_bai}"
	echo "公钥: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "私钥: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {

yuming="${1:-}"
if [ -z "$yuming" ]; then
	add_yuming
fi
install_docker
install_certbot
docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
install_ssltls
certs_status
install_ssltls_text
ssl_ps
}


ssl_ps() {
	echo -e "${gl_huang}已申请的证书到期情况${gl_bai}"
	echo "站点信息                      证书到期时间"
	echo "------------------------"
	for cert_dir in /etc/letsencrypt/live/*; do
	  local cert_file="$cert_dir/fullchain.pem"
	  if [ -f "$cert_file" ]; then
		local domain=$(basename "$cert_dir")
		local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
		local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
		printf "%-30s%s\n" "$domain" "$formatted_date"
	  fi
	done
	echo ""
}




default_server_ssl() {
install openssl

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
else
	openssl genpkey -algorithm Ed25519 -out /home/web/certs/default_server.key
	openssl req -x509 -key /home/web/certs/default_server.key -out /home/web/certs/default_server.crt -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
fi

openssl rand -out /home/web/certs/ticket12.key 48
openssl rand -out /home/web/certs/ticket13.key 80

}


certs_status() {

	sleep 1

	local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	if [ -f "$file_path" ]; then
		send_stats "域名证书申请成功"
	else
		send_stats "域名证书申请失败"
		echo -e "${gl_hong}🚨  注意: ${gl_bai}检测到域名证书申请失败，请检测域名是否正确解析或更换域名重新尝试！"
		break_end
		clear
		echo "请再次尝试部署 $webname"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "域名重复使用"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "先将域名解析到本机IP: ${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "请输入你的IP或者解析过的域名: " yuming
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
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|0000|$duankou|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on
	  docker restart nginx
}


restart_redis() {
  docker exec redis redis-cli FLUSHALL > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET maxmemory 512mb > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET maxmemory-policy allkeys-lru > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET save "" > /dev/null 2>&1
  docker exec -it redis redis-cli CONFIG SET appendonly no > /dev/null 2>&1
}



restart_ldnmp() {
	  restart_redis
	  docker exec nginx chown -R nginx:nginx /var/www/html > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec php chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  docker exec php74 chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  cd /home/web && docker compose restart nginx php php74

}

nginx_upgrade() {

  local ldnmp_pods="nginx"
  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker images --filter=reference="${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
  docker compose up -d --force-recreate $ldnmp_pods
  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -
  docker exec nginx chown -R nginx:nginx /var/www/html
  docker exec nginx mkdir -p /var/cache/nginx/proxy
  docker exec nginx mkdir -p /var/cache/nginx/fastcgi
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy
  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi
  docker restart $ldnmp_pods > /dev/null 2>&1

  send_stats "更新$ldnmp_pods"
  echo "更新${ldnmp_pods}完成"

}

phpmyadmin_upgrade() {
  local ldnmp_pods="phpmyadmin"
  local local docker_port=8877
  local dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
  local dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

  cd /home/web/
  docker rm -f $ldnmp_pods > /dev/null 2>&1
  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  curl -sS -O https://raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
  docker compose -f docker-compose.phpmyadmin.yml up -d
  clear
  ip_address

  check_docker_app_ip
  echo "登录信息: "
  echo "用户名: $dbuse"
  echo "密码: $dbusepasswd"
  echo
  send_stats "启动$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 检查配置文件是否存在
  if [ -f "$CONFIG_FILE" ]; then
	# 从配置文件读取 API_TOKEN 和 zone_id
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# 将 ZONE_IDS 转换为数组
	ZONE_IDS=($ZONE_IDS)
  else
	# 提示用户是否清理缓存
	read -p "需要清理 Cloudflare 的缓存吗？（y/n）: " answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF信息保存在$CONFIG_FILE，可以后期修改CF信息"
	  read -p "请输入你的 API_TOKEN: " API_TOKEN
	  read -p "请输入你的CF用户名: " EMAIL
	  read -p "请输入 zone_id（多个用空格分隔）: " -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 循环遍历每个 zone_id 并执行清除缓存命令
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "正在清除缓存 for zone_id: $ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "缓存清除请求已发送完毕。"
}



web_cache() {
  send_stats "清理站点缓存"
  # docker exec -it nginx rm -rf /var/cache/nginx
  cf_purge_cache
  docker exec php php -r 'opcache_reset();'
  docker exec php74 php -r 'opcache_reset();'
  docker restart nginx php php74 redis
  restart_redis
}



web_del() {

	send_stats "删除站点数据"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "删除站点数据，请输入你的域名（多个域名用空格隔开）: " yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "正在删除域名: $yuming"
		rm -r /home/web/html/$yuming
		rm /home/web/conf.d/$yuming.conf
		rm /home/web/certs/${yuming}_key.pem
		rm /home/web/certs/${yuming}_cert.pem

		# 将域名转换为数据库名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 删除数据库前检查是否存在，避免报错
		echo "正在删除数据库: $dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker restart nginx
}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 根据 mode 参数来决定开启或关闭 WAF
	if [ "$mode" == "on" ]; then
		# 开启 WAF：去掉注释
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# 关闭 WAF：加上注释
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "无效的参数：使用 'on' 或 'off'"
		return 1
	fi

	# 检查 nginx 镜像并根据情况处理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker restart nginx
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

check_waf_status() {
	if grep -q "^\s*#\s*modsecurity on;" /home/web/nginx.conf; then
		waf_status=""
	elif grep -q "modsecurity on;" /home/web/nginx.conf; then
		waf_status="WAF已开启"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage="cf模式已开启"
	else
		CFmessage=""
	fi
}


nginx_http_on() {

local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
	sed -i '/if (\$scheme = http) {/,/}/s/^/#/' /home/web/conf.d/${yuming}.conf
fi

}




















check_docker_app() {

if docker inspect "$docker_name" &>/dev/null; then
	check_docker="${gl_lv}已安装${gl_bai}"
else
	check_docker="${gl_hui}未安装${gl_bai}"
fi

}


check_docker_app_ip() {
echo "------------------------"
echo "访问地址:"
ip_address
if [ -n "$ipv4_address" ]; then
	echo "http://$ipv4_address:$docker_port"
fi

if [ -n "$ipv6_address" ]; then
	echo "http://[$ipv6_address]:$docker_port"
fi

local search_pattern="$ipv4_address:$docker_port"

for file in /home/web/conf.d/*; do
	if [ -f "$file" ]; then
		if grep -q "$search_pattern" "$file" 2>/dev/null; then
			echo "https://$(basename "$file" | sed 's/\.conf$//')"
		fi
	fi
done

}


check_docker_image_update() {

	local container_name=$1

	local country=$(curl -s ipinfo.io/country)
	if [[ "$country" == "CN" ]]; then
		update_status=""
		return
	fi

	# 获取容器的创建时间和镜像名称
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# 提取镜像仓库和标签
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# 默认标签为 latest
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# 添加对官方镜像的支持
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# 从 Docker Hub API 获取镜像发布时间
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# 验证获取的时间
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# 比较时间戳
		if [[ $container_created_ts -lt $last_updated_ts ]]; then
			update_status="${gl_huang}发现新版本!${gl_bai}"
		else
			update_status=""
		fi
	else
		update_status=""
	fi

}


docker_app() {
send_stats "${docker_name}管理"

while true; do
	clear
	check_docker_app
	check_docker_image_update $docker_name
	echo -e "$docker_name $check_docker $update_status"
	echo "$docker_describe"
	echo "$docker_url"
	if docker inspect "$docker_name" &>/dev/null; then
		check_docker_app_ip
	fi
	echo ""
	echo "------------------------"
	echo "1. 安装            2. 更新            3. 卸载"
	echo "------------------------"
	echo "5. 域名访问"
	echo "------------------------"
	echo "0. 返回上一级"
	echo "------------------------"
	read -e -p "请输入你的选择: " choice
	 case $choice in
		1)
			install jq
			install_docker
			$docker_rum
			clear
			echo "$docker_name 已经安装完成"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "安装$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			$docker_rum
			clear
			echo "$docker_name 已经安装完成"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "更新$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			echo "应用已卸载"
			send_stats "卸载$docker_name"
			;;

		5)
			echo "${docker_name}域名访问设置"
			send_stats "${docker_name}域名访问设置"
			add_yuming
			ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
			;;
		*)
			break
			;;
	 esac
	 break_end
done

}



prometheus_install() {

local PROMETHEUS_DIR="/home/docker/monitoring/prometheus"
local GRAFANA_DIR="/home/docker/monitoring/grafana"
local NETWORK_NAME="monitoring"

# Create necessary directories
mkdir -p $PROMETHEUS_DIR
mkdir -p $GRAFANA_DIR

# Set correct ownership for Grafana directory
chown -R 472:472 $GRAFANA_DIR

if [ ! -f "$PROMETHEUS_DIR/prometheus.yml" ]; then
	curl -o "$PROMETHEUS_DIR/prometheus.yml" ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/refs/heads/main/prometheus/prometheus.yml
fi

# Create Docker network for monitoring
docker network create $NETWORK_NAME

# Run Node Exporter container
docker run -d \
  --name=node-exporter \
  --network $NETWORK_NAME \
  --restart unless-stopped \
  prom/node-exporter

# Run Prometheus container
docker run -d \
  --name prometheus \
  -v $PROMETHEUS_DIR/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $PROMETHEUS_DIR/data:/prometheus \
  --network $NETWORK_NAME \
  --restart unless-stopped \
  --user 0:0 \
  prom/prometheus:latest

# Run Grafana container
docker run -d \
  --name grafana \
  -p 8047:3000 \
  -v $GRAFANA_DIR:/var/lib/grafana \
  --network $NETWORK_NAME \
  --restart unless-stopped \
  grafana/grafana:latest

}




tmux_run() {
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
}


tmux_run_d() {

local base_name="tmuxd"
local tmuxd_ID=1

# 检查会话是否存在的函数
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 循环直到找到一个不存在的会话名称
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 创建新的 tmux 会话
tmux new -d -s "$base_name-$tmuxd_ID" "$tmuxd"


}



f2b_status() {
	 docker restart fail2ban
	 sleep 3
	 docker exec -it fail2ban fail2ban-client status
}

f2b_status_xxx() {
	docker exec -it fail2ban fail2ban-client status $xxx
}

f2b_install_sshd() {

	docker run -d \
		--name=fail2ban \
		--net=host \
		--cap-add=NET_ADMIN \
		--cap-add=NET_RAW \
		-e PUID=1000 \
		-e PGID=1000 \
		-e TZ=Etc/UTC \
		-e VERBOSITY=-vv \
		-v /path/to/fail2ban/config:/config \
		-v /var/log:/var/log:ro \
		-v /home/web/log/nginx/:/remotelogs/nginx:ro \
		--restart unless-stopped \
		lscr.io/linuxserver/fail2ban:latest

	sleep 3
	if grep -q 'Alpine' /etc/issue; then
		cd /path/to/fail2ban/config/fail2ban/filter.d
		curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd.conf
		curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd-ddos.conf
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-ssh.conf
	elif command -v dnf &>/dev/null; then
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf
	else
		install rsyslog
		systemctl start rsyslog
		systemctl enable rsyslog
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/linux-ssh.conf
	fi
}

f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	elif command -v dnf &>/dev/null; then
		xxx=centos-sshd
		f2b_status_xxx
	else
		xxx=linux-sshd
		f2b_status_xxx
	fi
}






server_reboot() {

	read -e -p "$(echo -e "${gl_huang}⚠️  提示: ${gl_bai}现在重启服务器吗？(Y/N): ")" rboot
	case "$rboot" in
	  [Yy])
		echo "已重启"
		reboot
		;;
	  *)
		echo "已取消"
		;;
	esac


}

output_status() {
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

			printf("总接收:       %.2f %s\n总发送:       %.2f %s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)

}


ldnmp_install_status_one() {

   if docker inspect "php" &>/dev/null; then
	clear
	send_stats "无法再次安装LDNMP环境"
	echo -e "${gl_huang}⚠️  提示: ${gl_bai}建站环境已安装。无需再次安装！"
	break_end
	linux_ldnmp
   else
	:
   fi

}


ldnmp_install_all() {
cd ~
send_stats "安装LDNMP环境"
root_use
clear
echo -e "${gl_huang}LDNMP环境未安装，开始安装LDNMP环境...${gl_bai}"
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "安装nginx环境"
root_use
clear
echo -e "${gl_huang}nginx未安装，开始安装nginx环境...${gl_bai}"
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "nginx已安装完成"
echo -e "当前版本: ${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "请先安装LDNMP环境"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "请先安装nginx环境"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "您的 $webname 搭建好了！"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webname 安装信息如下: "

}

nginx_web_on() {
	  clear
	  echo "您的 $webname 搭建好了！"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "安装$webname"
  echo "开始部署 $webname"
  if [ -z "$yuming" ]; then
	add_yuming
  fi
  repeat_add_yuming
  ldnmp_install_status
  install_ssltls
  certs_status
  add_db
  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
  nginx_http_on

  cd /home/web/html
  mkdir $yuming
  cd $yuming
  wget -O latest.zip ${gh_proxy}https://github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip
  # wget -O latest.zip https://cn.wordpress.org/latest-zh_CN.zip
  # wget -O latest.zip https://wordpress.org/latest.zip
  unzip latest.zip
  rm latest.zip
  echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|database_name_here|$dbname|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|username_here|$dbuse|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|password_here|$dbusepasswd|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|localhost|mysql|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  cp /home/web/html/$yuming/wordpress/wp-config-sample.php /home/web/html/$yuming/wordpress/wp-config.php

  restart_ldnmp
  nginx_web_on
#   echo "数据库名: $dbname"
#   echo "用户名: $dbuse"
#   echo "密码: $dbusepasswd"
#   echo "数据库地址: mysql"
#   echo "表前缀: wp_"

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安装$webname"
	echo "开始部署 $webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "请输入你的反代IP: " reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "请输入你的反代端口: " port
	fi
	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0.0.0.0/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	sed -i "s|0000|$port|g" /home/web/conf.d/$yuming.conf
	nginx_http_on
	docker restart nginx
	nginx_web_on
}



ldnmp_web_status() {
	root_use
	while true; do
		local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
		local output="站点: ${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="数据库: ${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站点管理"
		echo "LDNMP环境"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}                      证书到期时间"
		echo -e "------------------------"
		for cert_file in /home/web/certs/*_cert.pem; do
		  local domain=$(basename "$cert_file" | sed 's/_cert.pem//')
		  if [ -n "$domain" ]; then
			local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
			local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
			printf "%-30s%s\n" "$domain" "$formatted_date"
		  fi
		done

		echo "------------------------"
		echo ""
		echo -e "${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "站点目录"
		echo "------------------------"
		echo -e "数据 ${gl_hui}/home/web/html${gl_bai}     证书 ${gl_hui}/home/web/certs${gl_bai}     配置 ${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "操作"
		echo "------------------------"
		echo "1.  申请/更新域名证书               2.  更换站点域名"
		echo "3.  清理站点缓存                    4.  创建关联站点"
		echo "5.  查看访问日志                    6.  查看错误日志"
		echo "7.  编辑全局配置                    8.  编辑站点配置"
		echo "9.  管理站点数据库		    10. 查看站点分析报告"
		echo "------------------------"
		echo "20. 删除指定站点数据"
		echo "------------------------"
		echo "0. 返回上一级选单"
		echo "------------------------"
		read -e -p "请输入你的选择: " sub_choice
		case $sub_choice in
			1)
				send_stats "申请域名证书"
				read -e -p "请输入你的域名: " yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "更换站点域名"
				echo -e "${gl_hong}🚨  强烈建议: ${gl_bai}先备份好全站数据再更换站点域名！"
				read -e -p "请输入旧域名: " oddyuming
				read -e -p "请输入新域名: " yuming
				install_certbot
				install_ssltls
				certs_status

				# mysql替换
				add_db

				local odd_dbname=$(echo "$oddyuming" | sed -e 's/[^A-Za-z0-9]/_/g')
				local odd_dbname="${odd_dbname}"

				docker exec mysql mysqldump -u root -p"$dbrootpasswd" $odd_dbname | docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname
				docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE $odd_dbname;"


				local tables=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW TABLES;" | awk '{ if (NR>1) print $1 }')
				for table in $tables; do
					columns=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW COLUMNS FROM $table;" | awk '{ if (NR>1) print $1 }')
					for column in $columns; do
						docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "UPDATE $table SET $column = REPLACE($column, '$oddyuming', '$yuming') WHERE $column LIKE '%$oddyuming%';"
					done
				done

				# docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "
				# UPDATE wp_options SET option_value = replace(option_value, '$oddyuming', '$yuming') WHERE option_name = 'home' OR option_name = 'siteurl';
				# UPDATE wp_posts SET guid = replace(guid, '$oddyuming', '$yuming');
				# UPDATE wp_posts SET post_content = replace(post_content, '$oddyuming', '$yuming');
				# UPDATE wp_postmeta SET meta_value = replace(meta_value,'$oddyuming', '$yuming');
				# "


				# 网站目录替换
				mv /home/web/html/$oddyuming /home/web/html/$yuming
				# sed -i "s/$odd_dbname/$dbname/g" /home/web/html/$yuming/wordpress/wp-config.php
				# sed -i "s/$oddyuming/$yuming/g" /home/web/html/$yuming/wordpress/wp-config.php

				find /home/web/html/$yuming -type f -exec sed -i "s/$odd_dbname/$dbname/g" {} +
				find /home/web/html/$yuming -type f -exec sed -i "s/$oddyuming/$yuming/g" {} +

				mv /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf

				rm /home/web/certs/${oddyuming}_key.pem
				rm /home/web/certs/${oddyuming}_cert.pem

				docker restart nginx

				;;


			3)
				web_cache
				;;
			4)
				send_stats "创建关联站点"
				echo -e "为现有的站点再关联一个新域名用于访问"
				read -e -p "请输入现有的域名: " oddyuming
				read -e -p "请输入新域名: " yuming
				install_certbot
				install_ssltls
				certs_status

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s|server_name $oddyuming|server_name $yuming|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_cert.pem|/etc/nginx/certs/${yuming}_cert.pem|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_key.pem|/etc/nginx/certs/${yuming}_key.pem|g" /home/web/conf.d/$yuming.conf

				docker restart nginx

				;;
			5)
				send_stats "查看访问日志"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "查看错误日志"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "编辑全局配置"
				install nano
				nano /home/web/nginx.conf
				docker restart nginx
				;;

			8)
				send_stats "编辑站点配置"
				read -e -p "编辑站点配置，请输入你要编辑的域名: " yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker restart nginx
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "查看站点数据"
				install goaccess
				goaccess --log-format=COMBINED /home/web/log/nginx/access.log
				;;

			20)
				web_del

				;;
			*)
				break  # 跳出循环，退出菜单
				;;
		esac
	done


}




check_panel_app() {

if $lujing ; then
	check_panel="${gl_lv}已安装${gl_bai}"
else
	check_panel="${gl_hui}未安装${gl_bai}"
fi

}



install_panel() {
send_stats "${panelname}管理"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname}是一款时下流行且强大的运维管理面板。"
	echo "官网介绍: $panelurl "

	echo ""
	echo "------------------------"
	echo "1. 安装            2. 管理            3. 卸载"
	echo "------------------------"
	echo "0. 返回上一级"
	echo "------------------------"
	read -e -p "请输入你的选择: " choice
	 case $choice in
		1)
			iptables_open
			install wget
			if grep -q 'Alpine' /etc/issue; then
				$ubuntu_mingling
				$ubuntu_mingling2
			elif command -v dnf &>/dev/null; then
				$centos_mingling
				$centos_mingling2
			elif grep -qi 'Ubuntu' /etc/os-release; then
				$ubuntu_mingling
				$ubuntu_mingling2
			elif grep -qi 'Debian' /etc/os-release; then
				$ubuntu_mingling
				$ubuntu_mingling2
			else
				echo "不支持的系统"
			fi
			send_stats "${panelname}安装"
			;;
		2)
			$gongneng1
			$gongneng1_1
			send_stats "${panelname}控制"
			;;
		3)
			$gongneng2
			$gongneng2_1
			$gongneng2_2
			send_stats "${panelname}卸载"
			;;
		*)
			break
			;;
	 esac
	 break_end
done

}



check_frp_app() {

if [ -d "/home/frp/" ]; then
	check_frp="${gl_lv}已安装${gl_bai}"
else
	check_frp="${gl_hui}未安装${gl_bai}"
fi

}




donlond_frp() {
	mkdir -p /home/frp/ && cd /home/frp/
	curl -L ${gh_proxy}https://github.com/fatedier/frp/releases/download/v0.61.0/frp_0.61.0_linux_amd64.tar.gz -o frp_0.61.0_linux_amd64.tar.gz
	tar -zxvf frp_*.tar.gz
}

generate_frps_config() {
	# 生成随机端口和凭证
	local bind_port=8055
	local dashboard_port=8056
	local token=$(openssl rand -hex 16)
	local dashboard_user="user_$(openssl rand -hex 4)"
	local dashboard_pwd=$(openssl rand -hex 8)

	donlond_frp

	# 创建 frps.toml 文件
	cat <<EOF > /home/frp/frp_0.61.0_linux_amd64/frps.toml
[common]
bind_port = $bind_port
authentication_method = token
token = $token
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
EOF

	# 输出生成的信息
	ip_address
	echo "------------------------"
	echo "客户端部署时需要用的参数"
	echo "服务IP: $ipv4_address"
	echo "token: $token"
	echo
	echo "FRP面板信息"
	echo "FRP面板地址: http://$ipv4_address:$dashboard_port"
	echo "FRP面板用户名: $dashboard_user"
	echo "FRP面板密码: $dashboard_pwd"
	echo
	echo "------------------------"
	install tmux
	tmux kill-session -t frps >/dev/null 2>&1
	tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"
	check_crontab_installed
	crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"') | crontab - > /dev/null 2>&1

}



configure_frpc() {
	# 提示用户输入外网服务器信息
	read -e -p "请输入外网对接IP: " server_addr
	read -e -p "请输入外网对接token: " token
	echo

	donlond_frp

	cat <<EOF > /home/frp/frp_0.61.0_linux_amd64/frpc.toml
[common]
server_addr = ${server_addr}
server_port = 8055
token = ${token}

EOF

	install tmux
	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"
	check_crontab_installed
	crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"') | crontab - > /dev/null 2>&1

}

add_forwarding_service() {
	# 提示用户输入服务名称和转发信息
	read -e -p "请输入服务名称: " service_name
	read -e -p "请输入转发类型 (tcp/udp) [回车默认tcp]: " service_type
	service_type=${service_type:-tcp}
	read -e -p "请输入内网端口: " local_port
	read -e -p "请输入外网端口: " remote_port

	# 将用户输入写入配置文件
	cat <<EOF >> /home/frp/frp_0.61.0_linux_amd64/frpc.toml
[$service_name]
type = ${service_type}
local_ip = 127.0.0.1
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 输出生成的信息
	echo "服务 $service_name 已成功添加到 frpc.toml"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

}



delete_forwarding_service() {
	# 提示用户输入需要删除的服务名称
	read -e -p "请输入需要删除的服务名称: " service_name
	# 使用 sed 删除该服务及其相关配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frp_0.61.0_linux_amd64/frpc.toml
	echo "服务 $service_name 已成功从 frpc.toml 删除"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

}


list_forwarding_services() {
	local config_file="$1"

	# 打印表头
	printf "%-20s %-25s %-30s %-10s\n" "服务名称" "内网地址" "外网地址" "协议"

	awk '
	BEGIN {
		server_addr=""
		server_port=""
		current_service=""
	}

	/^server_addr = / {
		gsub(/"|'"'"'/, "", $3)
		server_addr=$3
	}

	/^server_port = / {
		gsub(/"|'"'"'/, "", $3)
		server_port=$3
	}

	/^\[.*\]/ {
		# 如果已有服务信息，在处理新服务之前打印当前服务
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 更新当前服务名称
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# 清除之前的值
			local_ip=""
			local_port=""
			remote_port=""
			type=""
		}
	}

	/^local_ip = / {
		gsub(/"|'"'"'/, "", $3)
		local_ip=$3
	}

	/^local_port = / {
		gsub(/"|'"'"'/, "", $3)
		local_port=$3
	}

	/^remote_port = / {
		gsub(/"|'"'"'/, "", $3)
		remote_port=$3
	}

	/^type = / {
		gsub(/"|'"'"'/, "", $3)
		type=$3
	}

	END {
		# 打印最后一个服务的信息
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



frps_panel() {
	send_stats "FRP服务端"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		echo -e "FRP服务端 $check_frp"
		echo "构建FRP内网穿透服务环境"
		echo "官网介绍: https://github.com/fatedier/frp/"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
		fi
		echo ""
		echo "------------------------"
		echo "1. 安装                  2. 更新                  3. 卸载"
		echo "------------------------"
		echo "5. 内网服务域名访问"
		echo "------------------------"
		echo "0. 返回上一级"
		echo "------------------------"
		read -e -p "输入你的选择: " choice
		case $choice in
			1)
				generate_frps_config
				echo "FRP服务端已经安装完成"
				;;
			2)
				cp -f /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp
				cp -f /home/frp/frps.toml /home/frp/frp_0.61.0_linux_amd64/frps.toml
				tmux kill-session -t frps >/dev/null 2>&1
				tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				(crontab -l ; echo '@reboot tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"') | crontab - > /dev/null 2>&1
				echo "FRP服务端已经更新完成"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				rm -rf /home/frp
				echo "应用已卸载"
				;;
			5)
				echo "将内网穿透服务反代成域名访问"
				send_stats "FRP对外域名访问"
				ldnmp_Proxy
				;;
			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRP客户端"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		echo -e "FRP客户端 $check_frp"
		echo "与服务端对接，对接后可创建内网穿透转发服务"
		echo "官网介绍: https://github.com/fatedier/frp/"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			list_forwarding_services "/home/frp/frp_0.61.0_linux_amd64/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. 安装               2. 更新               3. 卸载"
		echo "------------------------"
		echo "4. 添加对外服务       5. 删除对外服务       6. 手动配置服务"
		echo "------------------------"
		echo "0. 返回上一级"
		echo "------------------------"
		read -e -p "输入你的选择: " choice
		case $choice in
			1)
				configure_frpc
				echo "FRP客户端已经安装完成"
				;;
			2)
				cp -f /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp
				cp -f /home/frp/frpc.toml /home/frp/frp_0.61.0_linux_amd64/frpc.toml
				tmux kill-session -t frpc >/dev/null 2>&1
				tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				(crontab -l ; echo '@reboot tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"') | crontab - > /dev/null 2>&1
				echo "FRP客户端已经更新完成"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				rm -rf /home/frp
				echo "应用已卸载"
				;;

			4)
				add_forwarding_service
				;;

			5)
				delete_forwarding_service
				;;

			6)
				install nano
				nano /home/frp/frp_0.61.0_linux_amd64/frpc.toml
				tmux kill-session -t frpc >/dev/null 2>&1
				tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}




current_timezone() {
	if grep -q 'Alpine' /etc/issue; then
	   date +"%Z %z"
	else
	   timedatectl | grep "Time zone" | awk '{print $3}'
	fi

}


set_timedate() {
	local shiqu="$1"
	if grep -q 'Alpine' /etc/issue; then
		install tzdata
		cp /usr/share/zoneinfo/${shiqu} /etc/localtime
		hwclock --systohc
	else
		timedatectl set-timezone ${shiqu}
	fi
}



# 修复dpkg中断问题
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}🔄 正在系统更新...${gl_bai}"
	if command -v dnf &>/dev/null; then
		dnf -y update
	elif command -v yum &>/dev/null; then
		yum -y update
	elif command -v apt &>/dev/null; then
		fix_dpkg
		DEBIAN_FRONTEND=noninteractive apt update -y
		DEBIAN_FRONTEND=noninteractive apt full-upgrade -y
	elif command -v apk &>/dev/null; then
		apk update && apk upgrade
	elif command -v pacman &>/dev/null; then
		pacman -Syu --noconfirm
	elif command -v zypper &>/dev/null; then
		zypper refresh
		zypper update
	elif command -v opkg &>/dev/null; then
		opkg update
	else
		echo "未知的包管理器!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}🧹 正在系统清理...${gl_bai}"
	if command -v dnf &>/dev/null; then
		dnf autoremove -y
		dnf clean all
		dnf makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v yum &>/dev/null; then
		yum autoremove -y
		yum clean all
		yum makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apt &>/dev/null; then
		fix_dpkg
		apt autoremove --purge -y
		apt clean -y
		apt autoclean -y
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v apk &>/dev/null; then
		echo "清理包管理器缓存..."
		apk cache clean
		echo "删除系统日志..."
		rm -rf /var/log/*
		echo "删除APK缓存..."
		rm -rf /var/cache/apk/*
		echo "删除临时文件..."
		rm -rf /tmp/*

	elif command -v pacman &>/dev/null; then
		pacman -Rns $(pacman -Qdtq) --noconfirm
		pacman -Scc --noconfirm
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v zypper &>/dev/null; then
		zypper clean --all
		zypper refresh
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v opkg &>/dev/null; then
		echo "删除系统日志..."
		rm -rf /var/log/*
		echo "删除临时文件..."
		rm -rf /tmp/*

	else
		echo "未知的包管理器!"
		return
	fi
	return
}



bbr_on() {

cat > /etc/sysctl.conf << EOF
net.ipv4.tcp_congestion_control=bbr
EOF
sysctl -p

}


set_dns() {

ip_address

rm /etc/resolv.conf
touch /etc/resolv.conf

if [ -n "$ipv4_address" ]; then
	echo "nameserver $dns1_ipv4" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv4" >> /etc/resolv.conf
fi

if [ -n "$ipv6_address" ]; then
	echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
fi

}


set_dns_ui() {
root_use
send_stats "优化DNS"
while true; do
	clear
	echo "优化DNS地址"
	echo "------------------------"
	echo "当前DNS地址"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 国外DNS优化: "
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 国内DNS优化: "
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. 手动编辑DNS配置"
	echo "------------------------"
	echo "0. 返回上一级"
	echo "------------------------"
	read -e -p "请输入你的选择: " Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "国外DNS优化"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "国内DNS优化"
		;;
	  3)
		install nano
		nano /etc/resolv.conf
		send_stats "手动编辑DNS配置"
		;;
	  *)
		break
		;;
	esac
done

}



restart_ssh() {
	restart sshd ssh > /dev/null 2>&1

}


new_ssh_port() {


  # 备份 SSH 配置文件
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config

  # 替换 SSH 配置文件中的端口号
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  # 重启 SSH 服务
  restart_ssh

  iptables_open
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSH 端口已修改为: $new_port"

  sleep 1

}



add_sshkey() {

	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""

	cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys


	ip_address
	echo -e "私钥信息已生成，务必复制保存，可保存成 ${gl_huang}${ipv4_address}_ssh.key${gl_bai} 文件，用于以后的SSH登录"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	echo -e "${gl_lv}ROOT私钥登录已开启，已关闭ROOT密码登录，重连将会生效${gl_bai}"

}


import_sshkey() {

	read -e -p "请输入您的SSH公钥内容（通常以 'ssh-rsa' 或 'ssh-ed25519' 开头）: " public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}错误：未输入公钥内容。${gl_bai}"
		return 1
	fi

	echo "$public_key" >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	echo -e "${gl_lv}公钥已成功导入，ROOT私钥登录已开启，已关闭ROOT密码登录，重连将会生效${gl_bai}"

}




add_sshpasswd() {

echo "设置你的ROOT密码"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ROOT登录设置完毕！${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}⚠️  提示: ${gl_bai}该功能需要root用户才能运行！" && break_end && kejilion
}



dd_xitong() {
		send_stats "重装系统"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}https://raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}https://raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "重装后初始用户名: ${gl_huang}root${gl_bai}  初始密码: ${gl_huang}LeitboGi0ro${gl_bai}  初始端口: ${gl_huang}22${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "重装后初始用户名: ${gl_huang}Administrator${gl_bai}  初始密码: ${gl_huang}Teddysun.com${gl_bai}  初始端口: ${gl_huang}3389${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "重装后初始用户名: ${gl_huang}root${gl_bai}  初始密码: ${gl_huang}123@@@${gl_bai}  初始端口: ${gl_huang}22${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "重装后初始用户名: ${gl_huang}Administrator${gl_bai}  初始密码: ${gl_huang}123@@@${gl_bai}  初始端口: ${gl_huang}3389${gl_bai}"
		  echo -e "按任意键继续..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "重装系统"
			echo "--------------------------------"
			echo -e "${gl_hong}🚨  注意: ${gl_bai}重装有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
			echo -e "${gl_hui}感谢MollyLau大佬和bin456789大佬的脚本支持！${gl_bai} "
			echo "------------------------"
			echo "1. Debian 12                  2. Debian 11"
			echo "3. Debian 10                  4. Debian 9"
			echo "------------------------"
			echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
			echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
			echo "------------------------"
			echo "21. Rocky Linux 9             22. Rocky Linux 8"
			echo "23. Alma Linux 9              24. Alma Linux 8"
			echo "25. oracle Linux 9            26. oracle Linux 8"
			echo "27. Fedora Linux 41           28. Fedora Linux 40"
			echo "29. CentOS 7"
			echo "------------------------"
			echo "31. Alpine Linux              32. Arch Linux"
			echo "33. Kali Linux                34. openEuler"
			echo "35. openSUSE Tumbleweed"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2022"
			echo "45. Windows Server 2019       46. Windows Server 2016"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 返回上一级选单"
			echo "------------------------"
			read -e -p "请选择要重装的系统: " sys_choice
			case "$sys_choice" in
			  1)
				send_stats "重装debian 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  2)
				send_stats "重装debian 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  3)
				send_stats "重装debian 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  4)
				send_stats "重装debian 9"
				dd_xitong_1
				bash InstallNET.sh -debian 9
				reboot
				exit
				;;
			  11)
				send_stats "重装ubuntu 24.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "重装ubuntu 22.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "重装ubuntu 20.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "重装ubuntu 18.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "重装rockylinux9"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "重装rockylinux8"
				dd_xitong_3
				bash reinstall.sh rocky 8
				reboot
				exit
				;;

			  23)
				send_stats "重装alma9"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "重装alma8"
				dd_xitong_3
				bash reinstall.sh almalinux 8
				reboot
				exit
				;;

			  25)
				send_stats "重装oracle9"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "重装oracle8"
				dd_xitong_3
				bash reinstall.sh oracle 8
				reboot
				exit
				;;

			  27)
				send_stats "重装fedora41"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "重装fedora40"
				dd_xitong_3
				bash reinstall.sh fedora 40
				reboot
				exit
				;;

			  29)
				send_stats "重装centos 7"
				dd_xitong_1
				bash InstallNET.sh -centos 7
				reboot
				exit
				;;

			  31)
				send_stats "重装alpine"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "重装arch"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "重装kali"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "重装openeuler"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "重装opensuse"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  41)
				send_stats "重装windows11"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;
			  42)
				dd_xitong_2
				send_stats "重装windows10"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;
			  43)
				send_stats "重装windows7"
				dd_xitong_4
				local URL="https://massgrave.dev/windows_7_links"
				local web_content=$(wget -q -O - "$URL")
				local iso_link=$(echo "$web_content" | grep -oP '(?<=href=")[^"]*cn[^"]*windows_7[^"]*professional[^"]*x64[^"]*\.iso')
				# bash reinstall.sh windows --image-name 'Windows 7 Professional' --lang zh-cn
				# bash reinstall.sh windows --iso='$iso_link' --image-name='Windows 7 PROFESSIONAL'
				bash reinstall.sh windows --iso="$iso_link" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;
			  44)
				send_stats "重装windows server 22"
				dd_xitong_4
				local URL="https://massgrave.dev/windows_server_links"
				local web_content=$(wget -q -O - "$URL")
				local iso_link=$(echo "$web_content" | grep -oP '(?<=href=")[^"]*cn[^"]*windows_server[^"]*2022[^"]*x64[^"]*\.iso')
				bash reinstall.sh windows --iso="$iso_link" --image-name='Windows Server 2022 SERVERDATACENTER'
				reboot
				exit
				;;
			  45)
				send_stats "重装windows server 19"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;
			  46)
				send_stats "重装windows server 16"
				dd_xitong_2
				bash InstallNET.sh -windows 2016 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "重装windows11 ARM"
				dd_xitong_4
				bash reinstall.sh dd --img https://r2.hotdog.eu.org/win11-arm-with-pagefile-15g.xz
				reboot
				exit
				;;

			  *)
				break
				;;
			esac
		  done
}


bbrv3() {
		  root_use
		  send_stats "bbrv3管理"

		  local cpu_arch=$(uname -m)
		  if [ "$cpu_arch" = "aarch64" ]; then
			bash <(curl -sL jhb.ovh/jb/bbrv3arm.sh)
			break_end
			linux_Settings
		  fi

		  if dpkg -l | grep -q 'linux-xanmod'; then
			while true; do
				  clear
				  local kernel_version=$(uname -r)
				  echo "您已安装xanmod的BBRv3内核"
				  echo "当前内核版本: $kernel_version"

				  echo ""
				  echo "内核管理"
				  echo "------------------------"
				  echo "1. 更新BBRv3内核              2. 卸载BBRv3内核"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# 步骤3：添加存储库
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "XanMod内核已更新。重启后生效"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "XanMod内核已卸载。重启后生效"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "设置BBR3加速"
		  echo "视频介绍: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		  echo "------------------------------------------------"
		  echo "仅支持Debian/Ubuntu"
		  echo "请备份数据，将为你升级Linux内核开启BBR3"
		  echo "VPS是512M内存的，请提前添加1G虚拟内存，防止因内存不足失联！"
		  echo "------------------------------------------------"
		  read -e -p "确定继续吗？(Y/N): " choice

		  case "$choice" in
			[Yy])
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "当前环境不支持，仅支持Debian和Ubuntu系统"
					break_end
					linux_Settings
				fi
			else
				echo "无法确定操作系统类型"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# 步骤3：添加存储库
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "XanMod内核安装并BBR3启用成功。重启后生效"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "已取消"
			  ;;
			*)
			  echo "无效的选择，请输入 Y 或 N。"
			  ;;
		  esac
		fi

}


elrepo_install() {
	# 导入 ELRepo GPG 公钥
	echo "导入 ELRepo GPG 公钥..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 检测系统版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 确保我们在一个支持的操作系统上运行
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "不支持的操作系统：$os_name"
		break_end
		linux_Settings
	fi
	# 打印检测到的操作系统信息
	echo "检测到的操作系统: $os_name $os_version"
	# 根据系统版本安装对应的 ELRepo 仓库配置
	if [[ "$os_version" == 8 ]]; then
		echo "安装 ELRepo 仓库配置 (版本 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "安装 ELRepo 仓库配置 (版本 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	else
		echo "不支持的系统版本：$os_version"
		break_end
		linux_Settings
	fi
	# 启用 ELRepo 内核仓库并安装最新的主线内核
	echo "启用 ELRepo 内核仓库并安装最新的主线内核..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "已安装 ELRepo 仓库配置并更新到最新主线内核。"
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "红帽内核管理"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "您已安装elrepo内核"
				  echo "当前内核版本: $kernel_version"

				  echo ""
				  echo "内核管理"
				  echo "------------------------"
				  echo "1. 更新elrepo内核              2. 卸载elrepo内核"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "更新红帽内核"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "elrepo内核已卸载。重启后生效"
						send_stats "卸载红帽内核"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "请备份数据，将为你升级Linux内核"
		  echo "视频介绍: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		  echo "------------------------------------------------"
		  echo "仅支持红帽系列发行版 CentOS/RedHat/Alma/Rocky/oracle "
		  echo "升级Linux内核可提升系统性能和安全，建议有条件的尝试，生产环境谨慎升级！"
		  echo "------------------------------------------------"
		  read -e -p "确定继续吗？(Y/N): " choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "升级红帽内核"
			  server_reboot
			  ;;
			[Nn])
			  echo "已取消"
			  ;;
			*)
			  echo "无效的选择，请输入 Y 或 N。"
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}正在更新病毒库...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "请指定要扫描的目录。"
		return
	fi

	echo -e "${gl_huang}正在扫描目录$@... ${gl_bai}"

	# 构建 mount 参数
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# 构建 clamscan 命令参数
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# 执行 Docker 命令
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ 扫描完成，病毒报告存放在${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}如果有病毒请在${gl_huang}scan.log${gl_lv}文件中搜索FOUND关键字确认病毒位置 ${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "病毒扫描管理"
		  while true; do
				clear
				echo "clamav病毒扫描工具"
				echo "视频介绍: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
				echo "------------------------"
				echo "是一个开源的防病毒软件工具，主要用于检测和删除各种类型的恶意软件。"
				echo "包括病毒、特洛伊木马、间谍软件、恶意脚本和其他有害软件。"
				echo "------------------------"
				echo -e "${gl_lv}1. 全盘扫描 ${gl_bai}             ${gl_huang}2. 重要目录扫描 ${gl_bai}            ${gl_kjlan} 3. 自定义目录扫描 ${gl_bai}"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "请输入你的选择: " sub_choice
				case $sub_choice in
					1)
					  send_stats "全盘扫描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "重要目录扫描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "自定义目录扫描"
					  read -e -p "请输入要扫描的目录，用空格分隔（例如：/etc /var /usr /home /root）: " directories
					  install_docker
					  clamav_freshclam
					  clamav_scan $directories
					  break_end
						;;
					*)
					  break  # 跳出循环，退出菜单
						;;
				esac
		  done

}




# 高性能模式优化函数
optimize_high_performance() {
	echo -e "${gl_lv}切换到${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}优化文件描述符...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}优化虚拟内存...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}优化网络设置...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=250000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

	echo -e "${gl_lv}优化缓存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}优化CPU设置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}其他优化...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# 均衡模式优化函数
optimize_balanced() {
	echo -e "${gl_lv}切换到均衡模式...${gl_bai}"

	echo -e "${gl_lv}优化文件描述符...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}优化虚拟内存...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}优化网络设置...${gl_bai}"
	sysctl -w net.core.rmem_max=8388608 2>/dev/null
	sysctl -w net.core.wmem_max=8388608 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=125000 2>/dev/null
	sysctl -w net.core.somaxconn=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 32768 8388608' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 49151' 2>/dev/null

	echo -e "${gl_lv}优化缓存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}优化CPU设置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}其他优化...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# 还原默认设置函数
restore_defaults() {
	echo -e "${gl_lv}还原到默认设置...${gl_bai}"

	echo -e "${gl_lv}还原文件描述符...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}还原虚拟内存...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}还原网络设置...${gl_bai}"
	sysctl -w net.core.rmem_max=212992 2>/dev/null
	sysctl -w net.core.wmem_max=212992 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=1000 2>/dev/null
	sysctl -w net.core.somaxconn=128 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 6291456' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 16384 4194304' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=cubic 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=2048 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=0 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='32768 60999' 2>/dev/null

	echo -e "${gl_lv}还原缓存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}还原CPU设置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}还原其他优化...${gl_bai}"
	# 还原透明大页面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 还原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# 网站搭建优化函数
optimize_web_server() {
	echo -e "${gl_lv}切换到网站搭建优化模式...${gl_bai}"

	echo -e "${gl_lv}优化文件描述符...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}优化虚拟内存...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}优化网络设置...${gl_bai}"
	sysctl -w net.core.rmem_max=16777216 2>/dev/null
	sysctl -w net.core.wmem_max=16777216 2>/dev/null
	sysctl -w net.core.netdev_max_backlog=5000 2>/dev/null
	sysctl -w net.core.somaxconn=4096 2>/dev/null
	sysctl -w net.ipv4.tcp_rmem='4096 87380 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_wmem='4096 65536 16777216' 2>/dev/null
	sysctl -w net.ipv4.tcp_congestion_control=bbr 2>/dev/null
	sysctl -w net.ipv4.tcp_max_syn_backlog=8192 2>/dev/null
	sysctl -w net.ipv4.tcp_tw_reuse=1 2>/dev/null
	sysctl -w net.ipv4.ip_local_port_range='1024 65535' 2>/dev/null

	echo -e "${gl_lv}优化缓存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}优化CPU设置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}其他优化...${gl_bai}"
	# 禁用透明大页面，减少延迟
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux内核调优管理"
	  echo "Linux系统内核参数优化"
	  echo "视频介绍: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "提供多种系统参数调优模式，用户可以根据自身使用场景进行选择切换。"
	  echo -e "${gl_huang}⚠️  提示: ${gl_bai}生产环境请谨慎使用！"
	  echo "--------------------"
	  echo "1. 高性能优化模式：     最大化系统性能，优化文件描述符、虚拟内存、网络设置、缓存管理和CPU设置。"
	  echo "2. 均衡优化模式：       在性能与资源消耗之间取得平衡，适合日常使用。"
	  echo "3. 网站优化模式：       针对网站服务器进行优化，提高并发连接处理能力、响应速度和整体性能。"
	  echo "4. 直播优化模式：       针对直播推流的特殊需求进行优化，减少延迟，提高传输性能。"
	  echo "5. 游戏服优化模式：     针对游戏服务器进行优化，提高并发处理能力和响应速度。"
	  echo "6. 还原默认设置：       将系统设置还原为默认配置。"
	  echo "--------------------"
	  echo "0. 返回上一级"
	  echo "--------------------"
	  read -e -p "请输入你的选择: " sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "高性能模式优化"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "均衡模式优化"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "网站优化模式"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "直播推流优化"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "游戏服优化"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "还原默认设置"
			  ;;
		  *)
			  break
			  ;;
	  esac
	  break_end
	done
}





update_locale() {
	local lang=$1
	local locale_file=$2

	if [ -f /etc/os-release ]; then
		. /etc/os-release
		case $ID in
			debian|ubuntu|kali)
				install locales
				sed -i "s/^\s*#\?\s*${locale_file}/${locale_file}/" /etc/locale.gen
				locale-gen
				echo "LANG=${lang}" > /etc/default/locale
				export LANG=${lang}
				echo -e "${gl_lv}系统语言已经修改为: $lang 重新连接SSH生效。${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}系统语言已经修改为: $lang 重新连接SSH生效。${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "不支持的系统: $ID"
				break_end
				;;
		esac
	else
		echo "不支持的系统，无法识别系统类型。"
		break_end
	fi
}




linux_language() {
root_use
send_stats "切换系统语言"
while true; do
  clear
  echo "当前系统语言: $LANG"
  echo "------------------------"
  echo "1. 英文          2. 简体中文          3. 繁体中文"
  echo "------------------------"
  echo "0. 返回上一级"
  echo "------------------------"
  read -e -p "输入你的选择: " choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "切换到英文"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "切换到简体中文"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "切换到繁体中文"
		  ;;
	  *)
		  break
		  ;;
  esac
done
}



shell_bianse_profile() {

if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
	sed -i '/^PS1=/d' ~/.bashrc
	echo "${bianse}" >> ~/.bashrc
	# source ~/.bashrc
else
	sed -i '/^PS1=/d' ~/.profile
	echo "${bianse}" >> ~/.profile
	# source ~/.profile
fi
echo -e "${gl_lv}变更完成。重新连接SSH后可查看变化！${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "命令行美化工具"
  while true; do
	clear
	echo "命令行美化工具"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. 返回上一级"
	echo "------------------------"
	read -e -p "输入你的选择: " choice

	case $choice in
	  1)
		local bianse="PS1='\[\033[1;32m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;31m\]\w\[\033[0m\] # '"
		shell_bianse_profile

		;;
	  2)
		local bianse="PS1='\[\033[1;35m\]\u\[\033[0m\]@\[\033[1;36m\]\h\[\033[0m\] \[\033[1;33m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  3)
		local bianse="PS1='\[\033[1;31m\]\u\[\033[0m\]@\[\033[1;32m\]\h\[\033[0m\] \[\033[1;34m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  4)
		local bianse="PS1='\[\033[1;36m\]\u\[\033[0m\]@\[\033[1;33m\]\h\[\033[0m\] \[\033[1;37m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  5)
		local bianse="PS1='\[\033[1;37m\]\u\[\033[0m\]@\[\033[1;31m\]\h\[\033[0m\] \[\033[1;32m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  6)
		local bianse="PS1='\[\033[1;33m\]\u\[\033[0m\]@\[\033[1;34m\]\h\[\033[0m\] \[\033[1;35m\]\w\[\033[0m\] # '"
		shell_bianse_profile
		;;
	  7)
		local bianse=""
		shell_bianse_profile
		;;
	  *)
		break
		;;
	esac

  done
}




linux_trash() {
  root_use
  send_stats "系统回收站"

  local bashrc_profile="/root/.bashrc"
  local TRASH_DIR="$HOME/.local/share/Trash/files"

  while true; do

	local trash_status
	if ! grep -q "trash-put" "$bashrc_profile"; then
		trash_status="${gl_hui}未启用${gl_bai}"
	else
		trash_status="${gl_lv}已启用${gl_bai}"
	fi

	clear
	echo -e "当前回收站 ${trash_status}"
	echo -e "启用后rm删除的文件先进入回收站，防止误删重要文件！"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "回收站为空"
	echo "------------------------"
	echo "1. 启用回收站          2. 关闭回收站"
	echo "3. 还原内容            4. 清空回收站"
	echo "------------------------"
	echo "0. 返回上一级"
	echo "------------------------"
	read -e -p "输入你的选择: " choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "回收站已启用，删除的文件将移至回收站。"
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "回收站已关闭，文件将直接删除。"
		sleep 2
		;;
	  3)
		read -e -p "输入要还原的文件名: " file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restore 已还原到主目录。"
		else
		  echo "文件不存在。"
		fi
		;;
	  4)
		read -e -p "确认清空回收站？[y/n]: " confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "回收站已清空。"
		fi
		;;
	  *)
		break
		;;
	esac
  done
}




linux_ps() {

	clear
	send_stats "系统信息查询"

	ip_address

	local cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')

	local cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
		<(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))

	local cpu_cores=$(nproc)

	local cpu_freq=$(cat /proc/cpuinfo | grep "MHz" | head -n 1 | awk '{printf "%.1f GHz\n", $4/1000}')

	local mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2f MB (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

	local disk_info=$(df -h | awk '$NF=="/"{printf "%s/%s (%s)", $3, $2, $5}')

	local ipinfo=$(curl -s ipinfo.io)
	local country=$(echo "$ipinfo" | grep 'country' | awk -F': ' '{print $2}' | tr -d '",')
	local city=$(echo "$ipinfo" | grep 'city' | awk -F': ' '{print $2}' | tr -d '",')
	local isp_info=$(echo "$ipinfo" | grep 'org' | awk -F': ' '{print $2}' | tr -d '",')

	local load=$(uptime | awk '{print $(NF-2), $(NF-1), $NF}')
	local dns_addresses=$(awk '/^nameserver/{printf "%s ", $2} END {print ""}' /etc/resolv.conf)


	local cpu_arch=$(uname -m)

	local hostname=$(uname -n)

	local kernel_version=$(uname -r)

	local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
	local queue_algorithm=$(sysctl -n net.core.default_qdisc)

	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')

	output_status

	local current_time=$(date "+%Y-%m-%d %I:%M %p")


	local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dMB/%dMB (%d%%)", used, total, percentage}')

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

	local timezone=$(current_timezone)


	echo ""
	echo -e "💻 系统信息查询"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}主机名:       ${gl_bai}$hostname"
	echo -e "${gl_kjlan}系统版本:     ${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linux版本:    ${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU架构:      ${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPU型号:      ${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPU核心数:    ${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU频率:      ${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU占用:      ${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}系统负载:     ${gl_bai}$load"
	echo -e "${gl_kjlan}物理内存:     ${gl_bai}$mem_info"
	echo -e "${gl_kjlan}虚拟内存:     ${gl_bai}$swap_info"
	echo -e "${gl_kjlan}硬盘占用:     ${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}$output"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}网络算法:     ${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}运营商:       ${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4地址:     ${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6地址:     ${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS地址:      ${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}地理位置:     ${gl_bai}$country $city"
	echo -e "${gl_kjlan}系统时间:     ${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}运行时长:     ${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "基础工具"
	  echo -e "▶ 🛠️  基础工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}curl 下载工具 ${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget 下载工具 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo 超级管理权限工具             ${gl_kjlan}4.   ${gl_bai}socat 通信连接工具"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop 系统监控工具                 ${gl_kjlan}6.   ${gl_bai}iftop 网络流量监控工具"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP压缩解压工具             ${gl_kjlan}8.   ${gl_bai}tar GZ压缩解压工具"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux 多路后台运行工具             ${gl_kjlan}10.  ${gl_bai}ffmpeg 视频编码直播推流工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop 现代化监控工具 ${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}ranger 文件管理工具"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu 磁盘占用查看工具             ${gl_kjlan}14.  ${gl_bai}fzf 全局搜索工具"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim 文本编辑器                    ${gl_kjlan}16.  ${gl_bai}nano 文本编辑器 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}git 版本控制系统"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}黑客帝国屏保                      ${gl_kjlan}22.  ${gl_bai}跑火车屏保"
	  echo -e "${gl_kjlan}26.  ${gl_bai}俄罗斯方块小游戏                  ${gl_kjlan}27.  ${gl_bai}贪吃蛇小游戏"
	  echo -e "${gl_kjlan}28.  ${gl_bai}太空入侵者小游戏"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}全部安装                          ${gl_kjlan}32.  ${gl_bai}全部安装（不含屏保和游戏）${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}全部卸载"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}安装指定工具                      ${gl_kjlan}42.  ${gl_bai}卸载指定工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "工具已安装，使用方法如下："
			  curl --help
			  send_stats "安装curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "工具已安装，使用方法如下："
			  wget --help
			  send_stats "安装wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "工具已安装，使用方法如下："
			  sudo --help
			  send_stats "安装sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "工具已安装，使用方法如下："
			  socat -h
			  send_stats "安装socat"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "安装htop"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "安装iftop"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "工具已安装，使用方法如下："
			  unzip
			  send_stats "安装unzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "工具已安装，使用方法如下："
			  tar --help
			  send_stats "安装tar"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "工具已安装，使用方法如下："
			  tmux --help
			  send_stats "安装tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "工具已安装，使用方法如下："
			  ffmpeg --help
			  send_stats "安装ffmpeg"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "安装btop"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "安装ranger"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "安装ncdu"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "安装fzf"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "安装vim"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "安装nano"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "安装git"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "安装cmatrix"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "安装sl"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "安装bastet"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "安装nsnake"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "安装ninvaders"
			  ;;

		  31)
			  clear
			  send_stats "全部安装"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "全部安装（不含游戏和屏保）"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "全部卸载"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "请输入安装的工具名（wget curl sudo htop）: " installname
			  install $installname
			  send_stats "安装指定软件"
			  ;;
		  42)
			  clear
			  read -e -p "请输入卸载的工具名（htop ufw tmux cmatrix）: " removename
			  remove $removename
			  send_stats "卸载指定软件"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "bbr管理"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			  echo "当前TCP阻塞算法: $congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR管理"
			  echo "------------------------"
			  echo "1. 开启BBRv3              2. 关闭BBRv3（会重启）"
			  echo "------------------------"
			  echo "0. 返回上一级选单"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "alpine开启bbr3"
					  ;;
				  2)
					sed -i '/net.ipv4.tcp_congestion_control=bbr/d' /etc/sysctl.conf
					sysctl -p
					server_reboot
					  ;;
				  *)
					  break  # 跳出循环，退出菜单
					  ;;

			  esac
		done
	else
		install wget
		wget --no-check-certificate -O tcpx.sh ${gh_proxy}https://raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
		chmod +x tcpx.sh
		./tcpx.sh
	fi


}





linux_docker() {

	while true; do
	  clear
	  # send_stats "docker管理"
	  echo -e "▶ 🐳 Docker管理"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}安装更新Docker环境 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}查看Docker全局状态 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Docker容器管理 ▶ ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker镜像管理 ▶"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker网络管理 ▶"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker卷管理 ▶"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}清理无用的docker容器和镜像网络数据卷"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}更换Docker源"
	  echo -e "${gl_kjlan}9.   ${gl_bai}编辑daemon.json文件"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}开启Docker-ipv6访问"
	  echo -e "${gl_kjlan}12.  ${gl_bai}关闭Docker-ipv6访问"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}20.  ${gl_bai}卸载Docker环境"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "安装docker环境"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "docker全局状态"
			  echo "Docker版本"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker镜像: ${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "Docker容器: ${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Docker卷: ${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Docker网络: ${gl_lv}$network_count${gl_bai}"
			  docker network ls
			  echo ""

			  ;;
		  3)
			  docker_ps
			  ;;
		  4)
			  docker_image
			  ;;

		  5)
			  while true; do
				  clear
				  send_stats "Docker网络管理"
				  echo "Docker网络列表"
				  echo "------------------------------------------------------------"
				  docker network ls
				  echo ""

				  echo "------------------------------------------------------------"
				  container_ids=$(docker ps -q)
				  printf "%-25s %-25s %-25s\n" "容器名称" "网络名称" "IP地址"

				  for container_id in $container_ids; do
					  local container_info=$(docker inspect --format '{{ .Name }}{{ range $network, $config := .NetworkSettings.Networks }} {{ $network }} {{ $config.IPAddress }}{{ end }}' "$container_id")

					  local container_name=$(echo "$container_info" | awk '{print $1}')
					  local network_info=$(echo "$container_info" | cut -d' ' -f2-)

					  while IFS= read -r line; do
						  local network_name=$(echo "$line" | awk '{print $1}')
						  local ip_address=$(echo "$line" | awk '{print $2}')

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
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "创建网络"
						  read -e -p "设置新网络名: " dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "加入网络"
						  read -e -p "加入网络名: " dockernetwork
						  read -e -p "那些容器加入该网络（多个容器名请用空格分隔）: " dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "加入网络"
						  read -e -p "退出网络名: " dockernetwork
						  read -e -p "那些容器退出该网络（多个容器名请用空格分隔）: " dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "删除网络"
						  read -e -p "请输入要删除的网络名: " dockernetwork
						  docker network rm $dockernetwork
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
				  send_stats "Docker卷管理"
				  echo "Docker卷列表"
				  docker volume ls
				  echo ""
				  echo "卷操作"
				  echo "------------------------"
				  echo "1. 创建新卷"
				  echo "2. 删除指定卷"
				  echo "3. 删除所有卷"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  send_stats "新建卷"
						  read -e -p "设置新卷名: " dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "输入删除卷名（多个卷名请用空格分隔）: " dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "删除所有卷"
						  read -e -p "$(echo -e "${gl_hong}🚨  注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "无效的选择，请输入 Y 或 N。"
							  ;;
						  esac
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;
		  7)
			  clear
			  send_stats "Docker清理"
			  read -e -p "$(echo -e "${gl_huang}⚠️  提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
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
			  send_stats "Docker源"
			  bash <(curl -sSL https://linuxmirrors.cn/docker.sh)
			  ;;

		  9)
			  clear
			  install nano
			  mkdir -p /etc/docker && nano /etc/docker/daemon.json
			  restart docker
			  ;;

		  11)
			  clear
			  send_stats "Docker v6 开"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker v6 关"
			  docker_ipv6_off
			  ;;

		  20)
			  clear
			  send_stats "Docker卸载"
			  read -e -p "$(echo -e "${gl_hong}🚨  注意: ${gl_bai}确定卸载docker环境吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker ps -a -q | xargs -r docker rm -f && docker images -q | xargs -r docker rmi && docker network prune -f && docker volume prune -f
				  remove docker docker-compose docker-ce docker-ce-cli containerd.io
				  rm -f /etc/docker/daemon.json
				  hash -r
				  ;;
				[Nn])
				  ;;
				*)
				  echo "无效的选择，请输入 Y 或 N。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "测试脚本合集"
	  echo -e "▶ 🧪 测试脚本合集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IP及解锁状态检测"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT 解锁状态检测"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Region 流媒体解锁测试"
	  echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu 流媒体解锁检测"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP质量体检脚本 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}网络线路测速"
	  echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 三网回程延迟路由测试"
	  echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace 三网回程线路测试"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 三网测速"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 快速回程测试脚本"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace 指定IP回程测试脚本"
	  echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 三网线路测试"
	  echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 多功能测速脚本"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}硬件性能测试"
	  echo -e "${gl_kjlan}21.  ${gl_bai}yabs 性能测试"
	  echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU性能测试脚本"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}综合性测试"
	  echo -e "${gl_kjlan}31.  ${gl_bai}bench 性能测试"
	  echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx 融合怪测评 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "ChatGPT解锁状态检测"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "Region流媒体解锁测试"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "yeahwu流媒体解锁检测"
			  install wget
			  wget -qO- ${gh_proxy}https://github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_IP质量体检脚本"
			  bash <(curl -Ls IP.Check.Place)
			  ;;
		  11)
			  clear
			  send_stats "besttrace三网回程延迟路由测试"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "mtr_trace三网回程线路测试"
			  curl ${gh_proxy}https://raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "Superspeed三网测速"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace快速回程测试脚本"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace指定IP回程测试脚本"
			  echo "可参考的IP列表"
			  echo "------------------------"
			  echo "北京电信: 219.141.136.12"
			  echo "北京联通: 202.106.50.1"
			  echo "北京移动: 221.179.155.161"
			  echo "上海电信: 202.96.209.133"
			  echo "上海联通: 210.22.97.1"
			  echo "上海移动: 211.136.112.200"
			  echo "广州电信: 58.60.188.222"
			  echo "广州联通: 210.21.196.6"
			  echo "广州移动: 120.196.165.24"
			  echo "成都电信: 61.139.2.69"
			  echo "成都联通: 119.6.6.6"
			  echo "成都移动: 211.137.96.205"
			  echo "湖南电信: 36.111.200.100"
			  echo "湖南联通: 42.48.16.100"
			  echo "湖南移动: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "输入一个指定IP: " testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "ludashi2020三网线路测试"
			  curl ${gh_proxy}https://raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc多功能测速脚本"
			  bash <(curl -sL ${gh_proxy}https://raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;


		  21)
			  clear
			  send_stats "yabs性能测试"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "icu/gb5 CPU性能测试脚本"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "bench性能测试"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "spiritysdx融合怪测评"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "甲骨文云脚本合集"
	  echo -e "▶ 🏢 甲骨文云脚本合集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}安装闲置机器活跃脚本"
	  echo -e "${gl_kjlan}2.   ${gl_bai}卸载闲置机器活跃脚本"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD重装系统脚本"
	  echo -e "${gl_kjlan}4.   ${gl_bai}R探长开机脚本"
	  echo -e "${gl_kjlan}5.   ${gl_bai}开启ROOT密码登录模式"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPV6恢复工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "活跃脚本: CPU占用10-20% 内存占用20% "
			  read -e -p "确定安装吗？(Y/N): " choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # 设置默认值
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # 提示用户输入CPU核心数和占用百分比，如果回车则使用默认值
				  read -e -p "请输入CPU核心数 [默认: $DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "请输入CPU占用百分比范围（例如10-20） [默认: $DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "请输入内存占用百分比 [默认: $DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "请输入Speedtest间隔时间（秒） [默认: $DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # 运行Docker容器
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "甲骨文云安装活跃脚本"

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
			  send_stats "甲骨文云卸载活跃脚本"
			  ;;

		  3)
		  clear
		  echo "重装系统"
		  echo "--------------------------------"
		  echo -e "${gl_hong}🚨  注意: ${gl_bai}重装有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
		  read -e -p "确定继续吗？(Y/N): " choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "请选择要重装的系统:  1. Debian12 | 2. Ubuntu20.04 : " sys_choice

				case "$sys_choice" in
				  1)
					local xitong="-d 12"
					break  # 结束循环
					;;
				  2)
					local xitong="-u 20.04"
					break  # 结束循环
					;;
				  *)
					echo "无效的选择，请重新输入。"
					;;
				esac
			  done

			  read -e -p "请输入你重装后的密码: " vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}https://raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "甲骨文云重装系统脚本"
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
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "该功能由jhb大神提供，感谢他！"
			  send_stats "ipv6修复"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end

	done



}


docker_tato() {

	local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
	local image_count=$(docker images -q 2>/dev/null | wc -l)
	local network_count=$(docker network ls -q 2>/dev/null | wc -l)
	local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

	if command -v docker &> /dev/null; then
		echo -e "${gl_kjlan}------------------------"
		echo -e "${gl_lv}环境已经安装${gl_bai}  容器: ${gl_lv}$container_count${gl_bai}  镜像: ${gl_lv}$image_count${gl_bai}  网络: ${gl_lv}$network_count${gl_bai}  卷: ${gl_lv}$volume_count${gl_bai}"
	fi
}



ldnmp_tato() {
local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
local output="站点: ${gl_lv}${cert_count}${gl_bai}"

local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
if [ -n "$dbrootpasswd" ]; then
	local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
fi

local db_output="数据库: ${gl_lv}${db_count}${gl_bai}"


if command -v docker &>/dev/null; then
	if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_lv}环境已安装${gl_bai}  $output  $db_output"
	fi
fi

}


linux_ldnmp() {
  while true; do

	clear
	# send_stats "LDNMP建站"
	echo -e "${gl_huang}▶ 🌐 LDNMP建站"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}安装LDNMP环境 ${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}安装WordPress ${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}安装Discuz论坛                    ${gl_huang}4.   ${gl_bai}安装可道云桌面"
	echo -e "${gl_huang}5.   ${gl_bai}安装苹果CMS影视站                 ${gl_huang}6.   ${gl_bai}安装独角数发卡网"
	echo -e "${gl_huang}7.   ${gl_bai}安装flarum论坛网站                ${gl_huang}8.   ${gl_bai}安装typecho轻量博客网站"
	echo -e "${gl_huang}9.   ${gl_bai}安装LinkStack共享链接平台         ${gl_huang}20.  ${gl_bai}自定义动态站点"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}仅安装nginx ${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}站点重定向"
	echo -e "${gl_huang}23.  ${gl_bai}站点反向代理-IP+端口 ${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}站点反向代理-域名"
	echo -e "${gl_huang}25.  ${gl_bai}安装Bitwarden密码管理平台         ${gl_huang}26.  ${gl_bai}安装Halo博客网站"
	echo -e "${gl_huang}27.  ${gl_bai}安装AI绘画提示词生成器            ${gl_huang}30.  ${gl_bai}自定义静态站点"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}站点数据管理 ${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}备份全站数据"
	echo -e "${gl_huang}33.  ${gl_bai}定时远程备份                      ${gl_huang}34.  ${gl_bai}还原全站数据"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}保护LDNMP环境                     ${gl_huang}36.  ${gl_bai}优化LDNMP环境"
	echo -e "${gl_huang}37.  ${gl_bai}更新LDNMP环境                     ${gl_huang}38.  ${gl_bai}卸载LDNMP环境"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}返回主菜单"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "请输入你的选择: " sub_choice


	case $sub_choice in
	  1)
	  ldnmp_install_status_one
	  ldnmp_install_all
		;;
	  2)
	  ldnmp_wp
		;;

	  3)
	  clear
	  # Discuz论坛
	  webname="Discuz论坛"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}https://github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20240520.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "表前缀: discuz_"


		;;

	  4)
	  clear
	  # 可道云桌面
	  webname="可道云桌面"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}https://github.com/kalcaddle/kodbox/archive/refs/tags/1.50.02.zip
	  unzip -o latest.zip
	  rm latest.zip
	  mv /home/web/html/$yuming/kodbox* /home/web/html/$yuming/kodbox
	  restart_ldnmp

	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "数据库名: $dbname"
	  echo "redis主机: redis"

		;;

	  5)
	  clear
	  # 苹果CMS
	  webname="苹果CMS"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  # wget ${gh_proxy}https://github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
	  wget ${gh_proxy}https://github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && mv maccms10-*/* . && rm -r maccms10-* && rm maccms10.zip
	  cd /home/web/html/$yuming/template/ && wget ${gh_proxy}https://github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/template/DYXS2.zip
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/application/admin/controller
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/application/admin/view/system
	  mv /home/web/html/$yuming/admin.php /home/web/html/$yuming/vip.php && wget -O /home/web/html/$yuming/application/extra/maccms.php ${gh_proxy}https://raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php

	  restart_ldnmp


	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库端口: 3306"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "数据库前缀: mac_"
	  echo "------------------------"
	  echo "安装成功后登录后台地址"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 独脚数卡
	  webname="独脚数卡"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget ${gh_proxy}https://github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

	  restart_ldnmp


	  ldnmp_web_on
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

		;;

	  7)
	  clear
	  # flarum论坛
	  webname="flarum论坛"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

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
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/sitemap"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/oauth"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/best-answer:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"


	  restart_ldnmp


	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "表前缀: flarum_"
	  echo "管理员信息自行设置"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}https://github.com/typecho/typecho/releases/latest/download/typecho.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "数据库前缀: typecho_"
	  echo "数据库地址: mysql"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "数据库名: $dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf
	  sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" /home/web/conf.d/$yuming.conf
	  sed -i "s|yuming.com|$yuming|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}https://github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "数据库地址: mysql"
	  echo "数据库端口: 3306"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  clear
	  echo -e "[${gl_huang}1/6${gl_bai}] 上传PHP源码"
	  echo "-------------"
	  echo "目前只允许上传zip格式的源码包，请将源码包放到/home/web/html/${yuming}目录下"
	  read -e -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] index.php所在路径"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "请输入index.php的路径，类似（/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] 请选择PHP版本"
	  echo "-------------"
	  read -e -p "1. php最新版 | 2. php7.4 : " pho_v
	  case "$pho_v" in
		1)
		  sed -i "s#php:9000#php:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php"
		  ;;
		2)
		  sed -i "s#php:9000#php74:9000#g" /home/web/conf.d/$yuming.conf
		  local PHP_Version="php74"
		  ;;
		*)
		  echo "无效的选择，请重新输入。"
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] 安装指定扩展"
	  echo "-------------"
	  echo "已经安装的扩展"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] 编辑站点配置"
	  echo "-------------"
	  echo "按任意键继续，可以详细设置站点配置，如伪静态等内容"
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] 数据库管理"
	  echo "-------------"
	  read -e -p "1. 我搭建新站        2. 我搭建老站有数据库备份： " use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "数据库备份必须是.gz结尾的压缩包。请放到/home/目录下，支持宝塔/1panel备份数据导入。"
			  read -e -p "也可以输入下载链接，远程下载备份数据，直接回车将跳过远程下载： " url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "数据库导入的表数据"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "数据库导入完成"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "数据库地址: mysql"
	  echo "数据库名: $dbname"
	  echo "用户名: $dbuse"
	  echo "密码: $dbusepasswd"
	  echo "表前缀: $prefix"
	  echo "管理员登录信息自行设置"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  read -e -p "请输入跳转域名: " reverseproxy
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker restart nginx

	  nginx_web_on


		;;

	  23)
	  ldnmp_Proxy
		;;

	  24)
	  clear
	  webname="反向代理-域名"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  echo -e "域名格式: ${gl_huang}google.com${gl_bai}"
	  read -e -p "请输入你的反代域名: " fandai_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|fandaicom|$fandai_yuming|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker restart nginx

	  nginx_web_on

		;;


	  25)
	  clear
	  webname="Bitwarden"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  docker run -d \
		--name bitwarden \
		--restart always \
		-p 3280:80 \
		-v /home/web/html/$yuming/bitwarden/data:/data \
		vaultwarden/server
	  duankou=3280
	  reverse_proxy

	  nginx_web_on

		;;

	  26)
	  clear
	  webname="halo"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  docker run -d --name halo --restart always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2
	  duankou=8010
	  reverse_proxy

	  nginx_web_on

		;;

	  27)
	  clear
	  webname="AI绘画提示词生成器"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  wget ${gh_proxy}https://github.com/kejilion/Website_source_code/raw/refs/heads/main/ai_prompt_generator.zip
	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker restart nginx

	  nginx_web_on

		;;


	  30)
	  clear
	  webname="静态站点"
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  repeat_add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming


	  clear
	  echo -e "[${gl_huang}1/2${gl_bai}] 上传静态源码"
	  echo "-------------"
	  echo "目前只允许上传zip格式的源码包，请将源码包放到/home/web/html/${yuming}目录下"
	  read -e -p "也可以输入下载链接，远程下载源码包，直接回车将跳过远程下载： " url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] index.html所在路径"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "请输入index.html的路径，类似（/home/web/html/$yuming/index/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker restart nginx

	  nginx_web_on

		;;



	31)
	  ldnmp_web_status
	  ;;


	32)
	  clear
	  send_stats "LDNMP环境备份"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}正在备份 $backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "备份文件已创建: /home/$backup_filename"
		read -e -p "要传送备份数据到远程服务器吗？(Y/N): " choice
		case "$choice" in
		  [Yy])
			read -e -p "请输入远端服务器IP:  " remote_ip
			if [ -z "$remote_ip" ]; then
			  echo "错误: 请输入远端服务器IP。"
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
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
	  send_stats "定时远程备份"
	  read -e -p "输入远程服务器IP: " useip
	  read -e -p "输入远程服务器密码: " usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. 每周备份                 2. 每天备份"
	  read -e -p "请输入你的选择: " dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "选择每周备份的星期几 (0-6，0代表星期日): " weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "选择每天备份的时间（小时，0-23）: " hour
			  (crontab -l ; echo "0 $hour * * * ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  *)
			  break  # 跳出
			  ;;
	  esac

	  install sshpass

	  ;;

	34)
	  root_use
	  send_stats "LDNMP环境还原"
	  echo "可用的站点备份"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # 如果用户没有输入文件名，使用最新的压缩包
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}正在解压 $filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "没有找到压缩包。"
	  fi

	  ;;

	35)
	  send_stats "LDNMP环境防御"
	  while true; do
		check_waf_status
		check_cf_mode
		if docker inspect fail2ban &>/dev/null ; then
			  clear
			  echo -e "服务器防御程序已启动 ${gl_lv}${CFmessage} ${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 开启SSH防暴力破解              2. 关闭SSH防暴力破解"
			  echo "3. 开启网站保护                   4. 关闭网站保护"
			  echo "------------------------"
			  echo "5. 查看SSH拦截记录                6. 查看网站拦截记录"
			  echo "7. 查看防御规则列表               8. 查看日志实时监控"
			  echo "------------------------"
			  echo "11. 配置拦截参数"
			  echo "------------------------"
			  echo "21. cloudflare模式                22. 高负载开启5秒盾"
			  echo "------------------------"
			  echo "31. 开启WAF                       32. 关闭WAF"
			  echo "------------------------"
			  echo "9. 卸载防御程序"
			  echo "------------------------"
			  echo "0. 退出"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
					  sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/alpine-ssh.conf
					  sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/linux-ssh.conf
					  sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/centos-ssh.conf
					  f2b_status
					  ;;
				  2)
					  sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/alpine-ssh.conf
					  sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/linux-ssh.conf
					  sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/centos-ssh.conf
					  f2b_status
					  ;;
				  3)
					  sed -i 's/false/true/g' /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  ;;
				  4)
					  sed -i 's/true/false/g' /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  ;;
				  5)
					  echo "------------------------"
					  f2b_sshd
					  echo "------------------------"
					  ;;
				  6)

					  echo "------------------------"
					  local xxx="fail2ban-nginx-cc"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-bad-request"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-botsearch"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-http-auth"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-limit-req"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-php-url-fopen"
					  f2b_status_xxx
					  echo "------------------------"

					  ;;

				  7)
					  docker exec -it fail2ban fail2ban-client status
					  ;;
				  8)
					  tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log

					  ;;
				  9)
					  docker rm -f fail2ban
					  rm -rf /path/to/fail2ban
					  crontab -l | grep -v "CF-Under-Attack.sh" | crontab - 2>/dev/null
					  echo "Fail2Ban防御程序已卸载"
					  break
					  ;;

				  11)
					  install nano
					  nano /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status

					  break
					  ;;
				  21)
					  send_stats "cloudflare模式"
					  echo "到cf后台右上角我的个人资料，选择左侧API令牌，获取Global API Key"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "输入CF的账号: " cfuser
					  read -e -p "输入CF的Global API Key: " cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker restart nginx

					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /path/to/fail2ban/config/fail2ban/action.d
					  curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "已配置cloudflare模式，可在cf后台，站点-安全性-事件中查看拦截记录"
					  ;;

				  22)
					  send_stats "高负载开启5秒盾"
					  echo -e "${gl_huang}网站每5分钟自动检测，当达检测到高负载会自动开盾，低负载也会自动关闭5秒盾。${gl_bai}"
					  echo "--------------"
					  echo "获取CF参数: "
					  echo -e "到cf后台右上角我的个人资料，选择左侧API令牌，获取${gl_huang}Global API Key${gl_bai}"
					  echo -e "到cf后台域名概要页面右下方获取${gl_huang}区域ID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "输入CF的账号: " cfuser
					  read -e -p "输入CF的Global API Key: " cftoken
					  read -e -p "输入CF中域名的区域ID: " cfzonID

					  cd ~
					  install jq bc
					  check_crontab_installed
					  curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh
					  chmod +x CF-Under-Attack.sh
					  sed -i "s/AAAA/$cfuser/g" ~/CF-Under-Attack.sh
					  sed -i "s/BBBB/$cftoken/g" ~/CF-Under-Attack.sh
					  sed -i "s/CCCC/$cfzonID/g" ~/CF-Under-Attack.sh

					  local cron_job="*/5 * * * * ~/CF-Under-Attack.sh"

					  local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

					  if [ -z "$existing_cron" ]; then
						  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
						  echo "高负载自动开盾脚本已添加"
					  else
						  echo "自动开盾脚本已存在，无需添加"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "站点WAF已开启"
					  send_stats "站点WAF已开启"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "站点WAF已关闭"
					  send_stats "站点WAF已关闭"
					  ;;

				  *)
					  break
					  ;;
			  esac
		elif [ -x "$(command -v fail2ban-client)" ] ; then
			clear
			echo "卸载旧版fail2ban"
			read -e -p "确定继续吗？(Y/N): " choice
			case "$choice" in
			  [Yy])
				remove fail2ban
				rm -rf /etc/fail2ban
				echo "Fail2Ban防御程序已卸载"
				;;
			  *)
				echo "已取消"
				break
				;;
			esac

		else
			clear
			f2b_install_sshd
			cd /path/to/fail2ban/config/fail2ban/filter.d
			curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
			cd /path/to/fail2ban/config/fail2ban/jail.d/
			curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf
			sed -i "/cloudflare/d" /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
			f2b_status
			cd ~
			echo "防御程序已开启"
		fi
	  break_end
	  done

		;;

	36)
		  while true; do
			  clear
			  send_stats "优化LDNMP环境"
			  echo "优化LDNMP环境"
			  echo "------------------------"
			  echo "1. 标准模式              2. 高性能模式 (推荐2H2G以上)"
			  echo "------------------------"
			  echo "0. 退出"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
				  send_stats "站点标准模式"
				  # nginx调优
				  sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

				  # php调优
				  wget -O /home/optimized_php.ini ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php调优
				  wget -O /home/www.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  # mysql调优
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced

				  echo "LDNMP环境已设置成 标准模式"

					  ;;
				  2)
				  send_stats "站点高性能模式"
				  # nginx调优
				  sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

				  # php调优
				  wget -O /home/optimized_php.ini ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php调优
				  wget -O /home/www.conf ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  # mysql调优
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

				  echo "LDNMP环境已设置成 高性能模式"

					  ;;
				  *)
					  break
					  ;;
			  esac
			  break_end

		  done
		;;


	37)
	  root_use
	  while true; do
		  clear
		  send_stats "更新LDNMP环境"
		  echo "更新LDNMP环境"
		  echo "------------------------"
		  ldnmp_v
		  echo "发现新版本的组件"
		  echo "------------------------"
		  check_docker_image_update nginx
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}nginx $update_status${gl_bai}"
		  fi
		  check_docker_image_update php
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}php $update_status${gl_bai}"
		  fi
		  check_docker_image_update mysql
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}mysql $update_status${gl_bai}"
		  fi
		  check_docker_image_update redis
		  if [ -n "$update_status" ]; then
			echo -e "${gl_huang}redis $update_status${gl_bai}"
		  fi
		  echo "------------------------"
		  echo
		  echo "1. 更新nginx               2. 更新mysql              3. 更新php              4. 更新redis"
		  echo "------------------------"
		  echo "5. 更新完整环境"
		  echo "------------------------"
		  echo "0. 返回上一级"
		  echo "------------------------"
		  read -e -p "请输入你的选择: " sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "请输入${ldnmp_pods}版本号 （如: 8.0 8.3 8.4 9.0）（回车获取最新版）: " version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "请输入${ldnmp_pods}版本号 （如: 7.4 8.0 8.1 8.2 8.3）（回车获取最新版）: " version
			  local version=${version:-8.3}
			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/kjlion\///g" /home/web/docker-compose.yml > /dev/null 2>&1
			  sed -i "s/image: php:fpm-alpine/image: php:${version}-fpm-alpine/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
  			  docker images --filter=reference="kjlion/${ldnmp_pods}*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker exec php chown -R www-data:www-data /var/www/html

			  run_command docker exec php sed -i "s/dl-cdn.alpinelinux.org/mirrors.aliyun.com/g" /etc/apk/repositories > /dev/null 2>&1

			  docker exec php apk update
			  curl -sL ${gh_proxy}https://github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions
			  docker exec php mkdir -p /usr/local/bin/
			  docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/
			  docker exec php chmod +x /usr/local/bin/install-php-extensions

			  docker exec php sh -c "\
							apk add --no-cache imagemagick imagemagick-dev \
							&& apk add --no-cache git autoconf gcc g++ make pkgconfig \
							&& rm -rf /tmp/imagick \
							&& git clone ${gh_proxy}https://github.com/Imagick/imagick /tmp/imagick \
							&& cd /tmp/imagick \
							&& phpize \
							&& ./configure \
							&& make \
							&& make install \
							&& echo 'extension=imagick.so' > /usr/local/etc/php/conf.d/imagick.ini \
							&& rm -rf /tmp/imagick"


			  docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis


			  docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "memory_limit=256M" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_vars=3000" > /usr/local/etc/php/conf.d/max_input_vars.ini' > /dev/null 2>&1


			  docker restart $ldnmp_pods > /dev/null 2>&1
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  restart_redis
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}⚠️  提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "完整更新LDNMP环境"
					cd /home/web/
					docker compose down
					docker compose down --rmi all

					check_port
					install_dependency
					install_docker
					install_certbot
					install_ldnmp
					;;
				  *)
					;;
				esac
				  ;;
			  *)
				  break
				  ;;
		  esac
		  break_end
	  done


	  ;;

	38)
		root_use
		send_stats "卸载LDNMP环境"
		read -e -p "$(echo -e "${gl_hong}🚨  强烈建议：${gl_bai}先备份全部网站数据，再卸载LDNMP环境。确定删除所有网站数据吗？(Y/N): ")" choice
		case "$choice" in
		  [Yy])
			cd /home/web/
			docker compose down
			docker compose down --rmi all
			docker compose -f docker-compose.phpmyadmin.yml down > /dev/null 2>&1
			docker compose -f docker-compose.phpmyadmin.yml down --rmi all > /dev/null 2>&1
			rm -rf /home/web
			;;
		  [Nn])

			;;
		  *)
			echo "无效的选择，请输入 Y 或 N。"
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "无效的输入!"
	esac
	break_end

  done

}



linux_panel() {

	while true; do
	  clear
	  # send_stats "应用市场"
	  echo -e "▶ 🛒 应用市场"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}宝塔面板官方版                      ${gl_kjlan}2.   ${gl_bai}aaPanel宝塔国际版"
	  echo -e "${gl_kjlan}3.   ${gl_bai}1Panel新一代管理面板                ${gl_kjlan}4.   ${gl_bai}NginxProxyManager可视化面板"
	  echo -e "${gl_kjlan}5.   ${gl_bai}AList多存储文件列表程序             ${gl_kjlan}6.   ${gl_bai}Ubuntu远程桌面网页版"
	  echo -e "${gl_kjlan}7.   ${gl_bai}哪吒探针VPS监控面板                 ${gl_kjlan}8.   ${gl_bai}QB离线BT磁力下载面板"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Poste.io邮件服务器程序              ${gl_kjlan}10.  ${gl_bai}RocketChat多人在线聊天系统"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}禅道项目管理软件                    ${gl_kjlan}12.  ${gl_bai}青龙面板定时任务管理平台"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Cloudreve网盘 ${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}简单图床图片管理程序"
	  echo -e "${gl_kjlan}15.  ${gl_bai}emby多媒体管理系统                  ${gl_kjlan}16.  ${gl_bai}Speedtest测速面板"
	  echo -e "${gl_kjlan}17.  ${gl_bai}AdGuardHome去广告软件               ${gl_kjlan}18.  ${gl_bai}onlyoffice在线办公OFFICE"
	  echo -e "${gl_kjlan}19.  ${gl_bai}雷池WAF防火墙面板                   ${gl_kjlan}20.  ${gl_bai}portainer容器管理面板"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}VScode网页版                        ${gl_kjlan}22.  ${gl_bai}UptimeKuma监控工具"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Memos网页备忘录                     ${gl_kjlan}24.  ${gl_bai}Webtop远程桌面网页版 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${gl_bai}Nextcloud网盘                       ${gl_kjlan}26.  ${gl_bai}QD-Today定时任务管理框架"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Dockge容器堆栈管理面板              ${gl_kjlan}28.  ${gl_bai}LibreSpeed测速工具"
	  echo -e "${gl_kjlan}29.  ${gl_bai}searxng聚合搜索站 ${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}PhotoPrism私有相册系统"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}StirlingPDF工具大全                 ${gl_kjlan}32.  ${gl_bai}drawio免费的在线图表软件 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Sun-Panel导航面板                   ${gl_kjlan}34.  ${gl_bai}Pingvin-Share文件分享平台"
	  echo -e "${gl_kjlan}35.  ${gl_bai}极简朋友圈                          ${gl_kjlan}36.  ${gl_bai}LobeChatAI聊天聚合网站"
	  echo -e "${gl_kjlan}37.  ${gl_bai}MyIP工具箱 ${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}小雅alist全家桶"
	  echo -e "${gl_kjlan}39.  ${gl_bai}Bililive直播录制工具                ${gl_kjlan}40.  ${gl_bai}webssh网页版SSH连接工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}耗子管理面板                	 ${gl_kjlan}42.  ${gl_bai}Nexterm远程连接工具"
	  echo -e "${gl_kjlan}43.  ${gl_bai}RustDesk远程桌面(服务端)            ${gl_kjlan}44.  ${gl_bai}RustDesk远程桌面(中继端)"
	  echo -e "${gl_kjlan}45.  ${gl_bai}Docker加速站            		 ${gl_kjlan}46.  ${gl_bai}GitHub加速站"
	  echo -e "${gl_kjlan}47.  ${gl_bai}普罗米修斯监控			 ${gl_kjlan}48.  ${gl_bai}普罗米修斯(主机监控)"
	  echo -e "${gl_kjlan}49.  ${gl_bai}普罗米修斯(容器监控)		 ${gl_kjlan}50.  ${gl_bai}补货监控工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${gl_bai}PVE开小鸡面板			 ${gl_kjlan}52.  ${gl_bai}DPanel容器管理面板"
	  echo -e "${gl_kjlan}53.  ${gl_bai}ollama聊天AI大模型"
	  echo -e "${gl_kjlan}55.  ${gl_bai}FRP内网穿透(服务端)		 ${gl_kjlan}56.  ${gl_bai}FRP内网穿透(客户端)"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="宝塔面板"

			local gongneng1="bt"
			local gongneng1_1=""
			local gongneng2="curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh"
			local gongneng2_1="chmod +x bt-uninstall.sh"
			local gongneng2_2="./bt-uninstall.sh"

			local panelurl="https://www.bt.cn/new/index.html"


			local centos_mingling="wget -O install.sh https://download.bt.cn/install/install_6.0.sh"
			local centos_mingling2="sh install.sh ed8484bec"

			local ubuntu_mingling="wget -O install.sh https://download.bt.cn/install/install-ubuntu_6.0.sh"
			local ubuntu_mingling2="bash install.sh ed8484bec"

			install_panel



			  ;;
		  2)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="aapanel"

			local gongneng1="bt"
			local gongneng1_1=""
			local gongneng2="curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh"
			local gongneng2_1="chmod +x bt-uninstall.sh"
			local gongneng2_2="./bt-uninstall.sh"

			local panelurl="https://www.aapanel.com/new/index.html"

			local centos_mingling="wget -O install.sh http://www.aapanel.com/script/install_6.0_en.sh"
			local centos_mingling2="bash install.sh aapanel"

			local ubuntu_mingling="wget -O install.sh http://www.aapanel.com/script/install-ubuntu_6.0_en.sh"
			local ubuntu_mingling2="bash install.sh aapanel"

			install_panel

			  ;;
		  3)

			local lujing="command -v 1pctl > /dev/null 2>&1 "
			local panelname="1Panel"

			local gongneng1="1pctl user-info"
			local gongneng1_1="1pctl update password"
			local gongneng2="1pctl uninstall"
			local gongneng2_1=""
			local gongneng2_2=""

			local panelurl="https://1panel.cn/"


			local centos_mingling="curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh"
			local centos_mingling2="sh quick_start.sh"

			local ubuntu_mingling="curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh"
			local ubuntu_mingling2="bash quick_start.sh"

			install_panel

			  ;;
		  4)

			local docker_name="npm"
			local docker_img="jc21/nginx-proxy-manager:latest"
			local docker_port=81
			local docker_rum="docker run -d \
						  --name=$docker_name \
						  -p 80:80 \
						  -p 81:$docker_port \
						  -p 443:443 \
						  -v /home/docker/npm/data:/data \
						  -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
						  --restart=always \
						  $docker_img"
			local docker_describe="如果您已经安装了其他面板或者LDNMP建站环境，建议先卸载，再安装npm！"
			local docker_url="官网介绍: https://nginxproxymanager.com/"
			local docker_use="echo \"初始用户名: admin@example.com\""
			local docker_passwd="echo \"初始密码: changeme\""

			docker_app

			  ;;

		  5)

			local docker_name="alist"
			local docker_img="xhofe/alist-aria2:latest"
			local docker_port=5244
			local docker_rum="docker run -d \
								--restart=always \
								-v /home/docker/alist:/opt/alist/data \
								-p 5244:5244 \
								-e PUID=0 \
								-e PGID=0 \
								-e UMASK=022 \
								--name="alist" \
								xhofe/alist-aria2:latest"
			local docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
			local docker_url="官网介绍: https://alist.nn.ci/zh/"
			local docker_use="docker exec -it alist ./alist admin random"
			local docker_passwd=""

			docker_app

			  ;;

		  6)

			local docker_name="webtop-ubuntu"
			local docker_img="lscr.io/linuxserver/webtop:ubuntu-kde"
			local docker_port=3006
			local docker_rum="docker run -d \
						  --name=webtop-ubuntu \
						  --security-opt seccomp=unconfined \
						  -e PUID=1000 \
						  -e PGID=1000 \
						  -e TZ=Etc/UTC \
						  -e SUBFOLDER=/ \
						  -e TITLE=Webtop \
						  -p 3006:3000 \
						  -v /home/docker/webtop/data:/config \
						  -v /var/run/docker.sock:/var/run/docker.sock \
						  --shm-size="1gb" \
						  --restart unless-stopped \
						  lscr.io/linuxserver/webtop:ubuntu-kde"

			local docker_describe="webtop基于Ubuntu的容器，包含官方支持的完整桌面环境，可通过任何现代 Web 浏览器访问"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
			docker_app


			  ;;
		  7)
			clear
			send_stats "搭建哪吒"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "哪吒监控 $check_docker $update_status"
				echo "开源、轻量、易用的服务器监控与运维工具"
				echo "视频介绍: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. 使用           2. 域名访问           0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						install unzip jq
						install_docker
						curl -sL ${gh_proxy}https://raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && ./nezha.sh
						local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
						check_docker_app_ip
						;;
					2)
						echo "${docker_name}域名访问设置"
						send_stats "${docker_name}域名访问设置"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						;;

					*)
						break
						;;

				esac
				break_end
			done
			  ;;

		  8)

			local docker_name="qbittorrent"
			local docker_img="lscr.io/linuxserver/qbittorrent:latest"
			local docker_port=8081
			local docker_rum="docker run -d \
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
			local docker_describe="qbittorrent离线BT磁力下载服务"
			local docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
			local docker_use="sleep 3"
			local docker_passwd="docker logs qbittorrent"

			docker_app

			  ;;

		  9)
			send_stats "搭建邮局"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "邮局服务 $check_docker $update_status"
				echo "poste.io 是一个开源的邮件服务器解决方案，"
				echo "视频介绍: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo ""
				echo "端口检测"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
				  echo -e "${gl_lv}端口 $port 当前可用${gl_bai}"
				else
				  echo -e "${gl_hong}端口 $port 当前不可用${gl_bai}"
				fi
				echo ""

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "访问地址: "
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. 安装           2. 更新           3. 卸载"
				echo "------------------------"
				echo "0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						read -e -p "请设置邮箱域名 例如 mail.yuming.com : " yuming
						mkdir -p /home/docker
						echo "$yuming" > /home/docker/mail.txt
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

						install jq
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

					2)
						docker rm -f mailserver
						docker rmi -f analogic/poste.i
						yuming=$(cat /home/docker/mail.txt)
						docker run \
							--net=host \
							-e TZ=Europe/Prague \
							-v /home/docker/mail:/data \
							--name "mailserver" \
							-h "$yuming" \
							--restart=always \
							-d analogic/poste.i
						clear
						echo "poste.io已经安装完成"
						echo "------------------------"
						echo "您可以使用以下地址访问poste.io:"
						echo "https://$yuming"
						echo ""
						;;
					3)
						docker rm -f mailserver
						docker rmi -f analogic/poste.io
						rm /home/docker/mail.txt
						rm -rf /home/docker/mail
						echo "应用已卸载"
						;;

					*)
						break
						;;

				esac
				break_end
			done

			  ;;

		  10)
			send_stats "搭建聊天"

			local docker_name=rocketchat
			local docker_port=3897
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "聊天服务 $check_docker $update_status"
				echo "Rocket.Chat 是一个开源的团队通讯平台，支持实时聊天、音视频通话、文件共享等多种功能，"
				echo "官网介绍: https://www.rocket.chat"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. 安装           2. 更新           3. 卸载"
				echo "------------------------"
				echo "5. 域名访问"
				echo "------------------------"
				echo "0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						install jq
						install_docker
						docker run --name db -d --restart=always \
							-v /home/docker/mongo/dump:/dump \
							mongo:latest --replSet rs5 --oplogSize 256
						sleep 1
						docker exec -it db mongosh --eval "printjson(rs.initiate())"
						sleep 5
						docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

						clear

						ip_address
						echo "rocket.chat已经安装完成"
						check_docker_app_ip
						echo ""

						;;

					2)
						docker rm -f rocketchat
						docker rmi -f rocket.chat:6.3
						docker run --name rocketchat --restart=always -p 3897:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
						clear
						ip_address
						echo "rocket.chat已经安装完成"
						check_docker_app_ip
						echo ""
						;;
					3)
						docker rm -f rocketchat
						docker rmi -f rocket.chat
						docker rm -f db
						docker rmi -f mongo:latest
						rm -rf /home/docker/mongo
						echo "应用已卸载"

						;;
					5)
						echo "${docker_name}域名访问设置"
						send_stats "${docker_name}域名访问设置"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						;;

					*)
						break
						;;

				esac
				break_end
			done
			  ;;



		  11)
			local docker_name="zentao-server"
			local docker_img="idoop/zentao:latest"
			local docker_port=82
			local docker_rum="docker run -d -p 82:80 -p 3308:3306 \
							  -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
							  -e BIND_ADDRESS="false" \
							  -v /home/docker/zentao-server/:/opt/zbox/ \
							  --add-host smtp.exmail.qq.com:163.177.90.125 \
							  --name zentao-server \
							  --restart=always \
							  idoop/zentao:latest"
			local docker_describe="禅道是通用的项目管理软件"
			local docker_url="官网介绍: https://www.zentao.net/"
			local docker_use="echo \"初始用户名: admin\""
			local docker_passwd="echo \"初始密码: 123456\""
			docker_app

			  ;;

		  12)
			local docker_name="qinglong"
			local docker_img="whyour/qinglong:latest"
			local docker_port=5700
			local docker_rum="docker run -d \
					  -v /home/docker/qinglong/data:/ql/data \
					  -p 5700:5700 \
					  --name qinglong \
					  --hostname qinglong \
					  --restart unless-stopped \
					  whyour/qinglong:latest"
			local docker_describe="青龙面板是一个定时任务管理平台"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			docker_app

			  ;;
		  13)
			send_stats "搭建网盘"


			local docker_name=cloudreve
			local docker_port=5212
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "网盘服务 $check_docker $update_status"
				echo "cloudreve是一个支持多家云存储的网盘系统"
				echo "视频介绍: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. 安装           2. 更新           3. 卸载"
				echo "------------------------"
				echo "5. 域名访问"
				echo "------------------------"
				echo "0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						install jq
						install_docker
						cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
						curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
						cd /home/docker/cloud/ && docker compose up -d

						clear
						echo "cloudreve已经安装完成"
						check_docker_app_ip
						sleep 3
						docker logs cloudreve
						echo ""


						;;

					2)
						docker rm -f cloudreve
						docker rmi -f cloudreve/cloudreve:latest
						docker rm -f aria2
						docker rmi -f p3terx/aria2-pro
						cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
						curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}https://raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
						cd /home/docker/cloud/ && docker compose up -d
						clear
						echo "cloudreve已经安装完成"
						check_docker_app_ip
						sleep 3
						docker logs cloudreve
						echo ""
						;;
					3)

						docker rm -f cloudreve
						docker rmi -f cloudreve/cloudreve:latest
						docker rm -f aria2
						docker rmi -f p3terx/aria2-pro
						rm -rf /home/docker/cloud
						echo "应用已卸载"

						;;
					5)
						echo "${docker_name}域名访问设置"
						send_stats "${docker_name}域名访问设置"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						;;

					*)
						break
						;;

				esac
				break_end
			done
			  ;;

		  14)
			local docker_name="easyimage"
			local docker_img="ddsderek/easyimage:latest"
			local docker_port=85
			local docker_rum="docker run -d \
					  --name easyimage \
					  -p 85:80 \
					  -e TZ=Asia/Shanghai \
					  -e PUID=1000 \
					  -e PGID=1000 \
					  -v /home/docker/easyimage/config:/app/web/config \
					  -v /home/docker/easyimage/i:/app/web/i \
					  --restart unless-stopped \
					  ddsderek/easyimage:latest"
			local docker_describe="简单图床是一个简单的图床程序"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/icret/EasyImages2.0"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  15)
			local docker_name="emby"
			local docker_img="linuxserver/emby:latest"
			local docker_port=8096
			local docker_rum="docker run -d --name=emby --restart=always \
						-v /home/docker/emby/config:/config \
						-v /home/docker/emby/share1:/mnt/share1 \
						-v /home/docker/emby/share2:/mnt/share2 \
						-v /mnt/notify:/mnt/notify \
						-p 8096:8096 -p 8920:8920 \
						-e UID=1000 -e GID=100 -e GIDLIST=100 \
						linuxserver/emby:latest"
			local docker_describe="emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
			local docker_url="官网介绍: https://emby.media/"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  16)
			local docker_name="looking-glass"
			local docker_img="wikihostinc/looking-glass-server"
			local docker_port=89
			local docker_rum="docker run -d --name looking-glass --restart always -p 89:80 wikihostinc/looking-glass-server"
			local docker_describe="Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/wikihost-opensource/als"
			local docker_use=""
			local docker_passwd=""
			docker_app

			  ;;
		  17)

			local docker_name="adguardhome"
			local docker_img="adguard/adguardhome"
			local docker_port=3000
			local docker_rum="docker run -d \
							--name adguardhome \
							-v /home/docker/adguardhome/work:/opt/adguardhome/work \
							-v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
							-p 53:53/tcp \
							-p 53:53/udp \
							-p 3000:3000/tcp \
							--restart always \
							adguard/adguardhome"
			local docker_describe="AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
			local docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
			local docker_use=""
			local docker_passwd=""
			docker_app

			  ;;


		  18)

			local docker_name="onlyoffice"
			local docker_img="onlyoffice/documentserver"
			local docker_port=8082
			local docker_rum="docker run -d -p 8082:80 \
						--restart=always \
						--name onlyoffice \
						-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
						-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
						 onlyoffice/documentserver"
			local docker_describe="onlyoffice是一款开源的在线office工具，太强大了！"
			local docker_url="官网介绍: https://www.onlyoffice.com/"
			local docker_use=""
			local docker_passwd=""
			docker_app

			  ;;

		  19)
			send_stats "搭建雷池"


			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "雷池服务 $check_docker"
				echo "雷池是长亭科技开发的WAF站点防火墙程序面板，可以反代站点进行自动化防御"
				echo "视频介绍: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. 安装           2. 更新           3. 重置密码           4. 卸载"
				echo "------------------------"
				echo "0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						install_docker
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
						clear
						echo "雷池WAF面板已经安装完成"
						check_docker_app_ip
						docker exec safeline-mgt resetadmin

						;;

					2)
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
						docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
						echo ""
						clear
						echo "雷池WAF面板已经更新完成"
						check_docker_app_ip
						;;
					3)
						docker exec safeline-mgt resetadmin
						;;
					4)
						cd /data/safeline
						docker compose down
						docker compose down --rmi all
						echo "如果你是默认安装目录那现在项目已经卸载。如果你是自定义安装目录你需要到安装目录下自行执行:"
						echo "docker compose down && docker compose down --rmi all"
						;;
					*)
						break
						;;

				esac
				break_end
			done

			  ;;

		  20)
			local docker_name="portainer"
			local docker_img="portainer/portainer"
			local docker_port=9050
			local docker_rum="docker run -d \
					--name portainer \
					-p 9050:9000 \
					-v /var/run/docker.sock:/var/run/docker.sock \
					-v /home/docker/portainer:/data \
					--restart always \
					portainer/portainer"
			local docker_describe="portainer是一个轻量级的docker容器管理面板"
			local docker_url="官网介绍: https://www.portainer.io/"
			local docker_use=""
			local docker_passwd=""
			docker_app

			  ;;

		  21)
			local docker_name="vscode-web"
			local docker_img="codercom/code-server"
			local docker_port=8180
			local docker_rum="docker run -d -p 8180:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart always codercom/code-server"
			local docker_describe="VScode是一款强大的在线代码编写工具"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/coder/code-server"
			local docker_use="sleep 3"
			local docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
			docker_app
			  ;;
		  22)
			local docker_name="uptime-kuma"
			local docker_img="louislam/uptime-kuma:latest"
			local docker_port=3003
			local docker_rum="docker run -d \
							--name=uptime-kuma \
							-p 3003:3001 \
							-v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
							--restart=always \
							louislam/uptime-kuma:latest"
			local docker_describe="Uptime Kuma 易于使用的自托管监控工具"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/louislam/uptime-kuma"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  23)
			local docker_name="memos"
			local docker_img="ghcr.io/usememos/memos:latest"
			local docker_port=5230
			local docker_rum="docker run -d --name memos -p 5230:5230 -v /home/docker/memos:/var/opt/memos --restart always ghcr.io/usememos/memos:latest"
			local docker_describe="Memos是一款轻量级、自托管的备忘录中心"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/usememos/memos"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  24)
			local docker_name="webtop"
			local docker_img="lscr.io/linuxserver/webtop:latest"
			local docker_port=3083
			local docker_rum="docker run -d \
						  --name=webtop \
						  --security-opt seccomp=unconfined \
						  -e PUID=1000 \
						  -e PGID=1000 \
						  -e TZ=Etc/UTC \
						  -e SUBFOLDER=/ \
						  -e TITLE=Webtop \
						  -e LC_ALL=zh_CN.UTF-8 \
						  -e DOCKER_MODS=linuxserver/mods:universal-package-install \
						  -e INSTALL_PACKAGES=font-noto-cjk \
						  -p 3083:3000 \
						  -v /home/docker/webtop/data:/config \
						  -v /var/run/docker.sock:/var/run/docker.sock \
						  --shm-size="1gb" \
						  --restart unless-stopped \
						  lscr.io/linuxserver/webtop:latest"

			local docker_describe="webtop基于 Alpine、Ubuntu、Fedora 和 Arch 的容器，包含官方支持的完整桌面环境，可通过任何现代 Web 浏览器访问"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  25)
			local docker_name="nextcloud"
			local docker_img="nextcloud:latest"
			local docker_port=8989
			local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
			local docker_rum="docker run -d --name nextcloud --restart=always -p 8989:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud"
			local docker_describe="Nextcloud拥有超过 400,000 个部署，是您可以下载的最受欢迎的本地内容协作平台"
			local docker_url="官网介绍: https://nextcloud.com/"
			local docker_use="echo \"账号: nextcloud  密码: $rootpasswd\""
			local docker_passwd=""
			docker_app
			  ;;

		  26)
			local docker_name="qd"
			local docker_img="qdtoday/qd:latest"
			local docker_port=8923
			local docker_rum="docker run -d --name qd -p 8923:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd"
			local docker_describe="QD-Today是一个HTTP请求定时任务自动执行框架"
			local docker_url="官网介绍: https://qd-today.github.io/qd/zh_CN/"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;
		  27)
			local docker_name="dockge"
			local docker_img="louislam/dockge:latest"
			local docker_port=5003
			local docker_rum="docker run -d --name dockge --restart unless-stopped -p 5003:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v  /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge"
			local docker_describe="dockge是一个可视化的docker-compose容器管理面板"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/louislam/dockge"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  28)
			local docker_name="speedtest"
			local docker_img="ghcr.io/librespeed/speedtest"
			local docker_port=8028
			local docker_rum="docker run -d -p 8028:8080 --name speedtest --restart always ghcr.io/librespeed/speedtest"
			local docker_describe="librespeed是用Javascript实现的轻量级速度测试工具，即开即用"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/librespeed/speedtest"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  29)
			local docker_name="searxng"
			local docker_img="alandoyle/searxng:latest"
			local docker_port=8700
			local docker_rum="docker run --name=searxng \
							-d --init \
							--restart=unless-stopped \
							-v /home/docker/searxng/config:/etc/searxng \
							-v /home/docker/searxng/templates:/usr/local/searxng/searx/templates/simple \
							-v /home/docker/searxng/theme:/usr/local/searxng/searx/static/themes/simple \
							-p 8700:8080/tcp \
							alandoyle/searxng:latest"
			local docker_describe="searxng是一个私有且隐私的搜索引擎站点"
			local docker_url="官网介绍: https://hub.docker.com/r/alandoyle/searxng"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  30)
			local docker_name="photoprism"
			local docker_img="photoprism/photoprism:latest"
			local docker_port=2342
			local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
			local docker_rum="docker run -d \
							--name photoprism \
							--restart always \
							--security-opt seccomp=unconfined \
							--security-opt apparmor=unconfined \
							-p 2342:2342 \
							-e PHOTOPRISM_UPLOAD_NSFW="true" \
							-e PHOTOPRISM_ADMIN_PASSWORD="$rootpasswd" \
							-v /home/docker/photoprism/storage:/photoprism/storage \
							-v /home/docker/photoprism/Pictures:/photoprism/originals \
							photoprism/photoprism"
			local docker_describe="photoprism非常强大的私有相册系统"
			local docker_url="官网介绍: https://www.photoprism.app/"
			local docker_use="echo \"账号: admin  密码: $rootpasswd\""
			local docker_passwd=""
			docker_app
			  ;;


		  31)
			local docker_name="s-pdf"
			local docker_img="frooodle/s-pdf:latest"
			local docker_port=8020
			local docker_rum="docker run -d \
							--name s-pdf \
							--restart=always \
							 -p 8020:8080 \
							 -v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
							 -v /home/docker/s-pdf/extraConfigs:/configs \
							 -v /home/docker/s-pdf/logs:/logs \
							 -e DOCKER_ENABLE_SECURITY=false \
							 frooodle/s-pdf:latest"
			local docker_describe="这是一个强大的本地托管基于 Web 的 PDF 操作工具，使用 docker，允许您对 PDF 文件执行各种操作，例如拆分合并、转换、重新组织、添加图像、旋转、压缩等。"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/Stirling-Tools/Stirling-PDF"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  32)
			local docker_name="drawio"
			local docker_img="jgraph/drawio"
			local docker_port=7080
			local docker_rum="docker run -d --restart=always --name drawio -p 7080:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio"
			local docker_describe="这是一个强大图表绘制软件。思维导图，拓扑图，流程图，都能画"
			local docker_url="官网介绍: https://www.drawio.com/"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  33)
			local docker_name="sun-panel"
			local docker_img="hslr/sun-panel"
			local docker_port=3009
			local docker_rum="docker run -d --restart=always -p 3009:3002 \
							-v /home/docker/sun-panel/conf:/app/conf \
							-v /home/docker/sun-panel/uploads:/app/uploads \
							-v /home/docker/sun-panel/database:/app/database \
							--name sun-panel \
							hslr/sun-panel"
			local docker_describe="Sun-Panel服务器、NAS导航面板、Homepage、浏览器首页"
			local docker_url="官网介绍: https://doc.sun-panel.top/zh_cn/"
			local docker_use="echo \"账号: admin@sun.cc  密码: 12345678\""
			local docker_passwd=""
			docker_app
			  ;;

		  34)
			local docker_name="pingvin-share"
			local docker_img="stonith404/pingvin-share"
			local docker_port=3060
			local docker_rum="docker run -d \
							--name pingvin-share \
							--restart always \
							-p 3060:3000 \
							-v /home/docker/pingvin-share/data:/opt/app/backend/data \
							stonith404/pingvin-share"
			local docker_describe="Pingvin Share 是一个可自建的文件分享平台，是 WeTransfer 的一个替代品"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/stonith404/pingvin-share"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;


		  35)
			local docker_name="moments"
			local docker_img="kingwrcy/moments:latest"
			local docker_port=8035
			local docker_rum="docker run -d --restart unless-stopped \
							-p 8035:3000 \
							-v /home/docker/moments/data:/app/data \
							-v /etc/localtime:/etc/localtime:ro \
							-v /etc/timezone:/etc/timezone:ro \
							--name moments \
							kingwrcy/moments:latest"
			local docker_describe="极简朋友圈，高仿微信朋友圈，记录你的美好生活"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use="echo \"账号: admin  密码: a123456\""
			local docker_passwd=""
			docker_app
			  ;;



		  36)
			local docker_name="lobe-chat"
			local docker_img="lobehub/lobe-chat:latest"
			local docker_port=8036
			local docker_rum="docker run -d -p 8036:3210 \
							--name lobe-chat \
							--restart=always \
							lobehub/lobe-chat"
			local docker_describe="LobeChat聚合市面上主流的AI大模型，ChatGPT/Claude/Gemini/Groq/Ollama"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/lobehub/lobe-chat"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  37)
			local docker_name="myip"
			local docker_img="ghcr.io/jason5ng32/myip:latest"
			local docker_port=8037
			local docker_rum="docker run -d -p 8037:18966 --name myip --restart always ghcr.io/jason5ng32/myip:latest"
			local docker_describe="是一个多功能IP工具箱，可以查看自己IP信息及连通性，用网页面板呈现"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  38)
			send_stats "小雅全家桶"
			clear
			install_docker
			bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
			  ;;

		  39)

			if [ ! -d /home/docker/bililive-go/ ]; then
				mkdir -p /home/docker/bililive-go/ > /dev/null 2>&1
				wget -O /home/docker/bililive-go/config.yml ${gh_proxy}https://raw.githubusercontent.com/hr3lxphr6j/bililive-go/master/config.yml > /dev/null 2>&1
			fi

			local docker_name="bililive-go"
			local docker_img="chigusa/bililive-go"
			local docker_port=8039
			local docker_rum="docker run --restart=always --name bililive-go -v /home/docker/bililive-go/config.yml:/etc/bililive-go/config.yml -v /home/docker/bililive-go/Videos:/srv/bililive -p 8039:8080 -d chigusa/bililive-go"
			local docker_describe="Bililive-go是一个支持多种直播平台的直播录制工具"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/hr3lxphr6j/bililive-go"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  40)
			local docker_name="webssh"
			local docker_img="jrohy/webssh"
			local docker_port=8040
			local docker_rum="docker run -d -p 8040:5032 --restart always --name webssh -e TZ=Asia/Shanghai jrohy/webssh"
			local docker_describe="简易在线ssh连接工具和sftp工具"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/Jrohy/webssh"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  41)
			send_stats "耗子面板"
			while true; do
				clear
				echo "耗子管理面板"
				echo "使用 Golang + Vue 开发的开源轻量 Linux 服务器运维管理面板。"
				echo "官方地址: ${gh_proxy}https://github.com/TheTNB/panel"
				echo "------------------------"
				echo "1. 安装            2. 管理            3. 卸载"
				echo "------------------------"
				echo "0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o install.sh https://dl.cdn.haozi.net/panel/install.sh && bash install.sh
						cd ~
						;;
					2)
						panel-cli
						;;
					3)
						mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o uninstall.sh https://dl.cdn.haozi.net/panel/uninstall.sh && bash uninstall.sh
						cd ~
						;;
					*)
						break
						;;

				esac
				break_end
			done
			  ;;


		  42)
			local docker_name="nexterm"
			local docker_img="germannewsmaker/nexterm:latest"
			local docker_port=8042
			local docker_rum="docker run -d \
						  --name nexterm \
						  -p 8042:6989 \
						  -v /home/docker/nexterm:/app/data \
						  --restart unless-stopped \
						  germannewsmaker/nexterm:latest"
			local docker_describe="nexterm是一款强大的在线SSH/VNC/RDP连接工具。"
			local docker_url="官网介绍: ${gh_proxy}https://github.com/gnmyt/Nexterm"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  43)
			local docker_name="hbbs"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=21116
			local docker_rum="docker run --name hbbs -v /home/docker/hbbs/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbs"
			local docker_describe="rustdesk开源的远程桌面(服务端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="docker logs hbbs"
			local docker_passwd="echo \"把你的IP和key记录下，会在远程桌面客户端中用到。去44选项装中继端吧！\""
			docker_app
			  ;;

		  44)
			local docker_name="hbbr"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=21116
			local docker_rum="docker run --name hbbr -v /home/docker/hbbr/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbr"
			local docker_describe="rustdesk开源的远程桌面(中继端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="echo \"前往官网下载远程桌面的客户端: https://rustdesk.com/zh-cn/\""
			local docker_passwd=""
			docker_app
			  ;;

		  45)
			local docker_name="registry"
			local docker_img="registry:2"
			local docker_port=8045
			local docker_rum="docker run -d \
							-p 8045:5000 \
							--name registry \
							-v /home/docker/registry:/var/lib/registry \
							-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
							--restart always \
							registry:2"
			local docker_describe="Docker Registry 是一个用于存储和分发 Docker 镜像的服务。"
			local docker_url="官网介绍: https://hub.docker.com/_/registry"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  46)
			local docker_name="ghproxy"
			local docker_img="wjqserver/ghproxy:latest"
			local docker_port=8046
			local docker_rum="docker run -d --name ghproxy --restart always -p 8046:80 wjqserver/ghproxy:latest"
			local docker_describe="使用Go实现的GHProxy，用于加速部分地区Github仓库的拉取。"
			local docker_url="官网介绍: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  47)
			send_stats "普罗米修斯监控"

			local docker_name=prometheus
			local docker_port=8047
			while true; do
				check_docker_app
				clear
				echo -e "普罗米修斯监控 $check_docker"
				echo "Prometheus+Grafana企业级监控系统"
				echo "官网介绍: https://prometheus.io"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. 安装           2. 更新           3. 卸载"
				echo "------------------------"
				echo "5. 域名访问"
				echo "------------------------"
				echo "0. 返回上一级"
				echo "------------------------"
				read -e -p "输入你的选择: " choice

				case $choice in
					1)
						install_docker
						prometheus_install

						clear

						ip_address
						echo "普罗米修斯监控 已经安装完成"
						check_docker_app_ip
						echo "用户名密码均为: admin"

						;;

					2)
						docker rm -f node-exporter prometheus grafana
						docker rmi -f prom/node-exporter
						docker rmi -f prom/prometheus:latest
						docker rmi -f grafana/grafana:latest
						prometheus_install

						clear

						ip_address
						echo "普罗米修斯监控 已经安装完成"
						check_docker_app_ip

						;;
					3)
						docker rm -f node-exporter prometheus grafana
						docker rmi -f prom/node-exporter
						docker rmi -f prom/prometheus:latest
						docker rmi -f grafana/grafana:latest

						rm -rf /home/docker/monitoring
						echo "应用已卸载"

						;;
					5)
						echo "${docker_name}域名访问设置"
						send_stats "${docker_name}域名访问设置"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						;;

					*)
						break
						;;

				esac
				break_end
			done
			  ;;

		  48)
			local docker_name="node-exporter"
			local docker_img="prom/node-exporter"
			local docker_port=8048
			local docker_rum="docker run -d \
  								--name=node-exporter \
  								-p 8048:9100 \
  								--restart unless-stopped \
  								prom/node-exporter"
			local docker_describe="这是一个普罗米修斯的主机数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/prometheus/node_exporter"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  49)
			local docker_name="cadvisor"
			local docker_img="gcr.io/cadvisor/cadvisor:latest"
			local docker_port=8049
			local docker_rum="docker run -d \
  								--name=cadvisor \
  								--restart unless-stopped \
  								-p 8049:8080 \
  								--volume=/:/rootfs:ro \
  								--volume=/var/run:/var/run:rw \
  								--volume=/sys:/sys:ro \
  								--volume=/var/lib/docker/:/var/lib/docker:ro \
  								gcr.io/cadvisor/cadvisor:latest \
  								-housekeeping_interval=10s \
  								-docker_only=true"
			local docker_describe="这是一个普罗米修斯的容器数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/google/cadvisor"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;


		  50)
			local docker_name="changedetection"
			local docker_img="dgtlmoon/changedetection.io:latest"
			local docker_port=8050
			local docker_rum="docker run -d --restart always -p 8050:5000 \
								-v /home/docker/datastore:/datastore \
								--name changedetection dgtlmoon/changedetection.io:latest"
			local docker_describe="这是一款网站变化检测、补货监控和通知的小工具"
			local docker_url="官网介绍: https://github.com/dgtlmoon/changedetection.io"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;


		  51)
			clear
			send_stats "PVE开小鸡"
			curl -L ${gh_proxy}https://raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
			  ;;


		  52)
			local docker_name="dpanel"
			local docker_img="dpanel/dpanel:lite"
			local docker_port=8052
			local docker_rum="docker run -it -d --name dpanel --restart=always \
  								-p 8052:8080 -e APP_NAME=dpanel \
  								-v /var/run/docker.sock:/var/run/docker.sock \
  								-v /home/docker/dpanel:/dpanel \
  								dpanel/dpanel:lite"
			local docker_describe="Docker可视化面板系统，提供完善的docker管理功能。"
			local docker_url="官网介绍: https://github.com/donknap/dpanel"
			local docker_use=""
			local docker_passwd=""
			docker_app
			  ;;

		  53)
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:Ollama"
			local docker_port=8053
			local docker_rum="docker run -d -p 8053:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart always ghcr.io/open-webui/open-webui:ollama"
			local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的llama3大语言模型"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run llama3"
			local docker_passwd=""
			docker_app
			  ;;

		  55)
		  	frps_panel
			  ;;

		  56)
			frpc_panel
			  ;;


		  0)
			  kejilion
			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end

	done
}


linux_work() {

	while true; do
	  clear
	  send_stats "我的工作区"
	  echo -e "▶ 📁 我的工作区"
	  echo -e "系统将为你提供可以后台常驻运行的工作区，你可以用来执行长时间的任务"
	  echo -e "即使你断开SSH，工作区中的任务也不会中断，后台常驻任务。"
	  echo -e "${gl_huang}⚠️  提示: ${gl_bai}进入工作区后使用Ctrl+b再单独按d，退出工作区！"
	  echo -e "${gl_kjlan}------------------------"
	  echo "当前已存在的工作区列表"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}1号工作区"
	  echo -e "${gl_kjlan}2.   ${gl_bai}2号工作区"
	  echo -e "${gl_kjlan}3.   ${gl_bai}3号工作区"
	  echo -e "${gl_kjlan}4.   ${gl_bai}4号工作区"
	  echo -e "${gl_kjlan}5.   ${gl_bai}5号工作区"
	  echo -e "${gl_kjlan}6.   ${gl_bai}6号工作区"
	  echo -e "${gl_kjlan}7.   ${gl_bai}7号工作区"
	  echo -e "${gl_kjlan}8.   ${gl_bai}8号工作区"
	  echo -e "${gl_kjlan}9.   ${gl_bai}9号工作区"
	  echo -e "${gl_kjlan}10.  ${gl_bai}10号工作区"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH常驻模式 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}创建/进入工作区"
	  echo -e "${gl_kjlan}23.  ${gl_bai}注入命令到后台工作区"
	  echo -e "${gl_kjlan}24.  ${gl_bai}删除指定工作区"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "启动工作区$SESSION_NAME"
			  tmux_run
			  ;;

		  21)
			while true; do
			  clear
			  if grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc; then
				  local tmux_sshd_status="${gl_lv}开启${gl_bai}"
			  else
				  local tmux_sshd_status="${gl_hui}关闭${gl_bai}"
			  fi
			  send_stats "SSH常驻模式 "
			  echo -e "SSH常驻模式 ${tmux_sshd_status}"
			  echo "开启后SSH连接后会直接进入常驻模式，直接回到之前的工作状态。"
			  echo "------------------------"
			  echo "1. 开启            2. 关闭"
			  echo "------------------------"
			  echo "0. 返回上一级"
			  echo "------------------------"
			  read -e -p "请输入你的选择: " gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "启动工作区$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# 自动进入 tmux 会话\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
				  source ~/.bashrc
			  	  tmux_run
				  ;;
				2)
				  sed -i '/# 自动进入 tmux 会话/,+4d' ~/.bashrc
				  tmux kill-window -t sshd
				  ;;
				*)
				  break
				  ;;
			  esac
			done
			  ;;

		  22)
			  read -e -p "请输入你创建或进入的工作区名称，如1001 kj001 work1: " SESSION_NAME
			  tmux_run
			  send_stats "自定义工作区"
			  ;;


		  23)
			  read -e -p "请输入你要后台执行的命令，如:curl -fsSL https://get.docker.com | sh: " tmuxd
			  tmux_run_d
			  send_stats "注入命令到后台工作区"
			  ;;

		  24)
			  read -e -p "请输入要删除的工作区名称: " gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "删除工作区"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # send_stats "系统工具"
	  echo -e "▶ ⚙️  系统工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}设置脚本启动快捷键                 ${gl_kjlan}2.   ${gl_bai}修改登录密码"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ROOT密码登录模式                   ${gl_kjlan}4.   ${gl_bai}安装Python指定版本"
	  echo -e "${gl_kjlan}5.   ${gl_bai}开放所有端口                       ${gl_kjlan}6.   ${gl_bai}修改SSH连接端口"
	  echo -e "${gl_kjlan}7.   ${gl_bai}优化DNS地址                        ${gl_kjlan}8.   ${gl_bai}一键重装系统 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}禁用ROOT账户创建新账户             ${gl_kjlan}10.  ${gl_bai}切换优先ipv4/ipv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}查看端口占用状态                   ${gl_kjlan}12.  ${gl_bai}修改虚拟内存大小"
	  echo -e "${gl_kjlan}13.  ${gl_bai}用户管理                           ${gl_kjlan}14.  ${gl_bai}用户/密码生成器"
	  echo -e "${gl_kjlan}15.  ${gl_bai}系统时区调整                       ${gl_kjlan}16.  ${gl_bai}设置BBR3加速"
	  echo -e "${gl_kjlan}17.  ${gl_bai}防火墙高级管理器                   ${gl_kjlan}18.  ${gl_bai}修改主机名"
	  echo -e "${gl_kjlan}19.  ${gl_bai}切换系统更新源                     ${gl_kjlan}20.  ${gl_bai}定时任务管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}本机host解析                       ${gl_kjlan}22.  ${gl_bai}fail2banSSH防御程序"
	  echo -e "${gl_kjlan}23.  ${gl_bai}限流自动关机                       ${gl_kjlan}24.  ${gl_bai}ROOT私钥登录模式"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot系统监控预警                 ${gl_kjlan}26.  ${gl_bai}修复OpenSSH高危漏洞（岫源）"
	  echo -e "${gl_kjlan}27.  ${gl_bai}红帽系Linux内核升级                ${gl_kjlan}28.  ${gl_bai}Linux系统内核参数优化 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}病毒扫描工具 ${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}文件管理器"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}切换系统语言                       ${gl_kjlan}32.  ${gl_bai}命令行美化工具"
	  echo -e "${gl_kjlan}33.  ${gl_bai}设置系统回收站"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}留言板                             ${gl_kjlan}66.  ${gl_bai}一条龙系统调优 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}重启服务器                         ${gl_kjlan}100. ${gl_bai}隐私与安全"
	  echo -e "${gl_kjlan}101. ${gl_bai}k命令高级用法 ${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}卸载科技lion脚本"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "请输入你的快捷按键（输入0退出）: " kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  sed -i '/alias .*='\''k'\''$/d' ~/.bashrc
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "快捷键已设置"
				  send_stats "脚本快捷键已设置"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "设置你的登录密码"
			  echo "设置你的登录密码"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "root密码模式"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "py版本管理"
			echo "python版本管理"
			echo "视频介绍: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "该功能可无缝安装python官方支持的任何版本！"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "当前python版本号: ${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "推荐版本:  3.12    3.11    3.10    3.9    3.8    2.7"
			echo "查询更多版本: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "输入你要安装的python版本号（输入0退出）: " py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "脚本PY管理"
				break_end
				linux_Settings
			fi


			if ! grep -q 'export PYENV_ROOT="\$HOME/.pyenv"' ~/.bashrc; then
				if command -v yum &>/dev/null; then
					yum update -y && yum install git -y
					yum groupinstall "Development Tools" -y
					yum install openssl-devel bzip2-devel libffi-devel ncurses-devel zlib-devel readline-devel sqlite-devel xz-devel findutils -y

					curl -O https://www.openssl.org/source/openssl-1.1.1u.tar.gz
					tar -xzf openssl-1.1.1u.tar.gz
					cd openssl-1.1.1u
					./config --prefix=/usr/local/openssl --openssldir=/usr/local/openssl shared zlib
					make
					make install
					echo "/usr/local/openssl/lib" > /etc/ld.so.conf.d/openssl-1.1.1u.conf
					ldconfig -v
					cd ..

					export LDFLAGS="-L/usr/local/openssl/lib"
					export CPPFLAGS="-I/usr/local/openssl/include"
					export PKG_CONFIG_PATH="/usr/local/openssl/lib/pkgconfig"

				elif command -v apt &>/dev/null; then
					apt update -y && apt install git -y
					apt install build-essential libssl-dev zlib1g-dev libbz2-dev libreadline-dev libsqlite3-dev wget curl llvm libncurses5-dev libncursesw5-dev xz-utils tk-dev libffi-dev liblzma-dev libgdbm-dev libnss3-dev libedit-dev -y
				elif command -v apk &>/dev/null; then
					apk update && apk add git
					apk add --no-cache bash gcc musl-dev libffi-dev openssl-dev bzip2-dev zlib-dev readline-dev sqlite-dev libc6-compat linux-headers make xz-dev build-base  ncurses-dev
				else
					echo "未知的包管理器!"
					return
				fi

				curl https://pyenv.run | bash
				cat << EOF >> ~/.bashrc

export PYENV_ROOT="\$HOME/.pyenv"
if [[ -d "\$PYENV_ROOT/bin" ]]; then
  export PATH="\$PYENV_ROOT/bin:\$PATH"
fi
eval "\$(pyenv init --path)"
eval "\$(pyenv init -)"
eval "\$(pyenv virtualenv-init -)"

EOF

			fi

			sleep 1
			source ~/.bashrc
			sleep 1
			pyenv install $py_new_v
			pyenv global $py_new_v

			rm -rf /tmp/python-build.*
			rm -rf $(pyenv root)/cache/*

			local VERSION=$(python -V 2>&1 | awk '{print $2}')
			echo -e "当前python版本号: ${gl_huang}$VERSION${gl_bai}"
			send_stats "脚本PY版本切换"

			  ;;

		  5)
			  root_use
			  send_stats "开放端口"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "端口已全部开放"

			  ;;
		  6)
			root_use
			send_stats "修改SSH端口"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# 读取当前的 SSH 端口号
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 打印当前的 SSH 端口号
				echo -e "当前的 SSH 端口号是:  ${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "端口号范围1到65535之间的数字。（输入0退出）"

				# 提示用户输入新的 SSH 端口号
				read -e -p "请输入新的 SSH 端口号: " new_port

				# 判断端口号是否在有效范围内
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "端口号无效，请输入1到65535之间的数字。"
						send_stats "输入无效SSH端口"
						break_end
					fi
				else
					echo "输入无效，请输入数字。"
					send_stats "输入无效SSH端口"
					break_end
				fi
			done


			  ;;


		  7)
			set_dns_ui
			  ;;

		  8)

			dd_xitong
			  ;;
		  9)
			root_use
			send_stats "新用户禁用root"
			read -e -p "请输入新用户名（输入0退出）: " new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "操作已完成。"
			;;


		  10)
			root_use
			send_stats "设置v4/v6优先级"
			while true; do
				clear
				echo "设置v4/v6优先级"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "当前网络优先级设置: ${gl_huang}IPv4${gl_bai} 优先"
				else
					echo -e "当前网络优先级设置: ${gl_huang}IPv6${gl_bai} 优先"
				fi
				echo ""
				echo "------------------------"
				echo "1. IPv4 优先          2. IPv6 优先          3. IPv6 修复工具          0. 退出"
				echo "------------------------"
				read -e -p "选择优先的网络: " choice

				case $choice in
					1)
						sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
						echo "已切换为 IPv4 优先"
						send_stats "已切换为 IPv4 优先"
						;;
					2)
						sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
						echo "已切换为 IPv6 优先"
						send_stats "已切换为 IPv6 优先"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "该功能由jhb大神提供，感谢他！"
						send_stats "ipv6修复"
						;;

					*)
						break
						;;

				esac
			done
			;;

		  11)
			clear
			ss -tulnape
			;;

		  12)
			root_use
			send_stats "设置虚拟内存"
			while true; do
				clear
				echo "设置虚拟内存"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dMB/%dMB (%d%%)", used, total, percentage}')

				echo -e "当前虚拟内存: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 分配1024MB         2. 分配2048MB         3. 自定义大小         0. 退出"
				echo "------------------------"
				read -e -p "请输入你的选择: " choice

				case "$choice" in
				  1)
					send_stats "已设置1G虚拟内存"
					add_swap 1024

					;;
				  2)
					send_stats "已设置2G虚拟内存"
					add_swap 2048

					;;
				  3)
					read -e -p "请输入虚拟内存大小MB: " new_swap
					add_swap "$new_swap"
					send_stats "已设置自定义虚拟内存"
					;;

				  *)
					break
					;;
				esac
			done
			;;

		  13)
			  while true; do
				root_use
				send_stats "用户管理"
				echo "用户列表"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
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
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
					   # 提示用户输入新用户名
					   read -e -p "请输入新用户名: " new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "操作已完成。"
						  ;;

					  2)
					   # 提示用户输入新用户名
					   read -e -p "请输入新用户名: " new_username

					   # 创建新用户并设置密码
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # 赋予新用户sudo权限
					   echo "$new_username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers

					   echo "操作已完成。"

						  ;;
					  3)
					   read -e -p "请输入用户名: " username
					   # 赋予新用户sudo权限
					   echo "$username ALL=(ALL:ALL) ALL" | sudo tee -a /etc/sudoers
						  ;;
					  4)
					   read -e -p "请输入用户名: " username
					   # 从sudoers文件中移除用户的sudo权限
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "请输入要删除的用户名: " username
					   # 删除用户及其主目录
					   userdel -r "$username"
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  14)
			clear
			send_stats "用户信息生成器"
			echo "随机用户名"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "随机用户名 $i: $username"
			done

			echo ""
			echo "随机姓名"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5个随机用户姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
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
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "随机密码 $i: $password"
			done

			echo ""
			echo "32位随机密码"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "随机密码 $i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "换时区"
			while true; do
				clear
				echo "系统时间信息"

				# 获取当前系统时区
				local timezone=$(current_timezone)

				# 获取当前系统时间
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 显示时区和时间
				echo "当前系统时区：$timezone"
				echo "当前系统时间：$current_time"

				echo ""
				echo "时区切换"
				echo "------------------------"
				echo "亚洲"
				echo "1.  中国上海时间             2.  中国香港时间"
				echo "3.  日本东京时间             4.  韩国首尔时间"
				echo "5.  新加坡时间               6.  印度加尔各答时间"
				echo "7.  阿联酋迪拜时间           8.  澳大利亚悉尼时间"
				echo "9.  泰国曼谷时间"
				echo "------------------------"
				echo "欧洲"
				echo "11. 英国伦敦时间             12. 法国巴黎时间"
				echo "13. 德国柏林时间             14. 俄罗斯莫斯科时间"
				echo "15. 荷兰尤特赖赫特时间       16. 西班牙马德里时间"
				echo "------------------------"
				echo "美洲"
				echo "21. 美国西部时间             22. 美国东部时间"
				echo "23. 加拿大时间               24. 墨西哥时间"
				echo "25. 巴西时间                 26. 阿根廷时间"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "请输入你的选择: " sub_choice


				case $sub_choice in
					1) set_timedate Asia/Shanghai ;;
					2) set_timedate Asia/Hong_Kong ;;
					3) set_timedate Asia/Tokyo ;;
					4) set_timedate Asia/Seoul ;;
					5) set_timedate Asia/Singapore ;;
					6) set_timedate Asia/Kolkata ;;
					7) set_timedate Asia/Dubai ;;
					8) set_timedate Australia/Sydney ;;
					9) set_timedate Asia/Bangkok ;;
					11) set_timedate Europe/London ;;
					12) set_timedate Europe/Paris ;;
					13) set_timedate Europe/Berlin ;;
					14) set_timedate Europe/Moscow ;;
					15) set_timedate Europe/Amsterdam ;;
					16) set_timedate Europe/Madrid ;;
					21) set_timedate America/Los_Angeles ;;
					22) set_timedate America/New_York ;;
					23) set_timedate America/Vancouver ;;
					24) set_timedate America/Mexico_City ;;
					25) set_timedate America/Sao_Paulo ;;
					26) set_timedate America/Argentina/Buenos_Aires ;;
					*) break ;; # 跳出循环，退出菜单
				esac
			done
			  ;;

		  16)

			bbrv3
			  ;;

		  17)
		  root_use
		  while true; do
			if dpkg -l | grep -q iptables-persistent; then
				  clear
				  echo "高级防火墙管理"
				  send_stats "高级防火墙管理"
				  echo "------------------------"
				  iptables -L INPUT

				  echo ""
				  echo "防火墙管理"
				  echo "------------------------"
				  echo "1.  开放指定端口                 2.  关闭指定端口"
				  echo "3.  开放所有端口                 4.  关闭所有端口"
				  echo "------------------------"
				  echo "5.  IP白名单                  	 6.  IP黑名单"
				  echo "7.  清除指定IP"
				  echo "------------------------"
				  echo "11. 允许PING                  	 12. 禁止PING"
				  echo "------------------------"
				  echo "99. 卸载防火墙"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						   read -e -p "请输入开放的端口号: " o_port
						   sed -i "/COMMIT/i -A INPUT -p tcp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
						   sed -i "/COMMIT/i -A INPUT -p udp --dport $o_port -j ACCEPT" /etc/iptables/rules.v4
						   iptables-restore < /etc/iptables/rules.v4
						   send_stats "开放指定端口"

						  ;;
					  2)
						  read -e -p "请输入关闭的端口号: " c_port
						  sed -i "/--dport $c_port/d" /etc/iptables/rules.v4
						  iptables-restore < /etc/iptables/rules.v4
						  send_stats "关闭指定端口"
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
						  send_stats "开放所有端口"
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
						  send_stats "关闭所有端口"
						  ;;

					  5)
						  read -e -p "请输入放行的IP: " o_ip
						  sed -i "/COMMIT/i -A INPUT -s $o_ip -j ACCEPT" /etc/iptables/rules.v4
						  iptables-restore < /etc/iptables/rules.v4
						  send_stats "IP白名单"
						  ;;

					  6)
						  read -e -p "请输入封锁的IP: " c_ip
						  sed -i "/COMMIT/i -A INPUT -s $c_ip -j DROP" /etc/iptables/rules.v4
						  iptables-restore < /etc/iptables/rules.v4
						  send_stats "IP黑名单"
						  ;;

					  7)
						  read -e -p "请输入清除的IP: " d_ip
						  sed -i "/-A INPUT -s $d_ip/d" /etc/iptables/rules.v4
						  iptables-restore < /etc/iptables/rules.v4
						  send_stats "清除指定IP"
						  ;;

					  11)
						  sed -i '$i -A INPUT -p icmp --icmp-type echo-request -j ACCEPT' /etc/iptables/rules.v4
						  sed -i '$i -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT' /etc/iptables/rules.v4
						  iptables-restore < /etc/iptables/rules.v4
						  send_stats "允许ping"
						  ;;

					  12)
						  sed -i "/icmp/d" /etc/iptables/rules.v4
						  iptables-restore < /etc/iptables/rules.v4
						  send_stats "禁用ping"
						  ;;

					  99)
						  remove iptables-persistent
						  rm /etc/iptables/rules.v4
						  send_stats "卸载防火墙"
						  break

						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			else

				clear
				echo "将为你安装防火墙，该防火墙仅支持Debian/Ubuntu"
				echo "------------------------------------------------"
				read -e -p "确定继续吗？(Y/N): " choice

				case "$choice" in
				  [Yy])
					if [ -r /etc/os-release ]; then
						. /etc/os-release
						if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
							echo "当前环境不支持，仅支持Debian和Ubuntu系统"
							break_end
							linux_Settings
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

					local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

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
					break_end
					;;
				  *)
					echo "已取消"
					break
					;;
				esac
			fi
		  done
			  ;;

		  18)
		  root_use
		  send_stats "修改主机名"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "当前主机名: ${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "请输入新的主机名（输入0退出）: " new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # 其他系统，如 Debian, Ubuntu, CentOS 等
					  hostnamectl set-hostname "$new_hostname"
					  sed -i "s/$current_hostname/$new_hostname/g" /etc/hostname
					  systemctl restart systemd-hostnamed
				  fi

				  if grep -q "127.0.0.1" /etc/hosts; then
					  sed -i "s/127.0.0.1 .*/127.0.0.1       $new_hostname localhost localhost.localdomain/g" /etc/hosts
				  else
					  echo "127.0.0.1       $new_hostname localhost localhost.localdomain" >> /etc/hosts
				  fi

				  if grep -q "^::1" /etc/hosts; then
					  sed -i "s/^::1 .*/::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback/g" /etc/hosts
				  else
					  echo "::1             $new_hostname localhost localhost.localdomain ipv6-localhost ipv6-loopback" >> /etc/hosts
				  fi

				  echo "主机名已更改为: $new_hostname"
				  send_stats "主机名已更改"
				  sleep 1
			  else
				  echo "已退出，未更改主机名。"
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "换系统更新源"
		  clear
		  echo "选择更新源区域"
		  echo "接入LinuxMirrors切换系统更新源"
		  echo "------------------------"
		  echo "1. 中国大陆【默认】          2. 中国大陆【教育网】          3. 海外地区"
		  echo "------------------------"
		  echo "0. 返回上一级"
		  echo "------------------------"
		  read -e -p "输入你的选择: " choice

		  case $choice in
			  1)
				  send_stats "中国大陆默认源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "中国大陆教育源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "海外源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
				  echo "已取消"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "定时任务管理"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "定时任务列表"
				  crontab -l
				  echo ""
				  echo "操作"
				  echo "------------------------"
				  echo "1. 添加定时任务              2. 删除定时任务              3. 编辑定时任务"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "请输入新任务的执行命令: " newquest
						  echo "------------------------"
						  echo "1. 每月任务                 2. 每周任务"
						  echo "3. 每天任务                 4. 每小时任务"
						  echo "------------------------"
						  read -e -p "请输入你的选择: " dingshi

						  case $dingshi in
							  1)
								  read -e -p "选择每月的几号执行任务？ (1-30): " day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "选择周几执行任务？ (0-6，0代表星期日): " weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "选择每天几点执行任务？（小时，0-23）: " hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "输入每小时的第几分钟执行任务？（分钟，0-60）: " minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "添加定时任务"
						  ;;
					  2)
						  read -e -p "请输入需要删除任务的关键字: " kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "删除定时任务"
						  ;;
					  3)
						  crontab -e
						  send_stats "编辑定时任务"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "本地host解析"
			  while true; do
				  clear
				  echo "本机host解析列表"
				  echo "如果你在这里添加解析匹配，将不再使用动态解析了"
				  cat /etc/hosts
				  echo ""
				  echo "操作"
				  echo "------------------------"
				  echo "1. 添加新的解析              2. 删除解析地址"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " host_dns

				  case $host_dns in
					  1)
						  read -e -p "请输入新的解析记录 格式: 110.25.5.33 kejilion.pro : " addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "本地host解析新增"

						  ;;
					  2)
						  read -e -p "请输入需要删除的解析内容关键字: " delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "本地host解析删除"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "ssh防御"
		  while true; do
			if docker inspect fail2ban &>/dev/null ; then
					clear
					echo "SSH防御程序已启动"
					echo "------------------------"
					echo "1. 查看SSH拦截记录"
					echo "2. 日志实时监控"
					echo "------------------------"
					echo "9. 卸载防御程序"
					echo "------------------------"
					echo "0. 退出"
					echo "------------------------"
					read -e -p "请输入你的选择: " sub_choice
					case $sub_choice in

						1)
							echo "------------------------"
							f2b_sshd
							echo "------------------------"
							break_end
							;;
						2)
							tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log
							break
							;;
						9)
							docker rm -f fail2ban
							rm -rf /path/to/fail2ban
							echo "Fail2Ban防御程序已卸载"
							break
							;;
						*)
							echo "已取消"
							break
							;;
					esac

			elif [ -x "$(command -v fail2ban-client)" ] ; then
				clear
				echo "卸载旧版fail2ban"
				read -e -p "确定继续吗？(Y/N): " choice
				case "$choice" in
				  [Yy])
					remove fail2ban
					rm -rf /etc/fail2ban
					echo "Fail2Ban防御程序已卸载"
					break_end
					;;
				  *)
					echo "已取消"
					break
					;;
				esac

			else

			  clear
			  echo "fail2ban是一个SSH防止暴力破解工具"
			  echo "官网介绍: ${gh_proxy}https://github.com/fail2ban/fail2ban"
			  echo "------------------------------------------------"
			  echo "工作原理：研判非法IP恶意高频访问SSH端口，自动进行IP封锁"
			  echo "------------------------------------------------"
			  read -e -p "确定继续吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  clear
				  install_docker
				  f2b_install_sshd

				  cd ~
				  f2b_status
				  echo "Fail2Ban防御程序已开启"
				  send_stats "ssh防御安装完成"
				  break_end
				  ;;
				*)
				  echo "已取消"
				  break
				  ;;
			  esac
			fi
		  done
			  ;;


		  23)
			root_use
			send_stats "限流关机功能"
			while true; do
				clear
				echo "限流关机功能"
				echo "视频介绍: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "当前流量使用情况，重启服务器流量计算会清零！"
				output_status
				echo "$output"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}当前设置的进站限流阈值为: ${gl_huang}${rx_threshold_gb}${gl_lv}GB${gl_bai}"
					echo -e "${gl_lv}当前设置的出站限流阈值为: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}当前未启用限流关机功能${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "系统每分钟会检测实际流量是否到达阈值，到达后会自动关闭服务器！"
				read -e -p "1. 开启限流关机功能    2. 停用限流关机功能    0. 退出  : " Limiting

				case "$Limiting" in
				  1)
					# 输入新的虚拟内存大小
					echo "如果实际服务器就100G流量，可设置阈值为95G，提前关机，以免出现流量误差或溢出。"
					read -e -p "请输入进站流量阈值（单位为GB，默认100G）: " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "请输入出站流量阈值（单位为GB，默认100G）: " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "请输入流量重置日期（默认每月1日重置）: " cz_day
					cz_day=${cz_day:-1}

					cd ~
					curl -Ss -o ~/Limiting_Shut_down.sh ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh
					chmod +x ~/Limiting_Shut_down.sh
					sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
					sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					(crontab -l ; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab - > /dev/null 2>&1
					crontab -l | grep -v 'reboot' | crontab -
					(crontab -l ; echo "0 1 $cz_day * * reboot") | crontab - > /dev/null 2>&1
					echo "限流关机已设置"
					send_stats "限流关机已设置"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "已关闭限流关机功能"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "私钥登录"
			  while true; do
				  clear
			  	  echo "ROOT私钥登录模式"
			  	  echo "视频介绍: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
			  	  echo "------------------------------------------------"
			  	  echo "将会生成密钥对，更安全的方式SSH登录"
				  echo "------------------------"
				  echo "1. 生成新密钥              2. 导入已有密钥              3. 查看本机密钥"
				  echo "------------------------"
				  echo "0. 返回上一级选单"
				  echo "------------------------"
				  read -e -p "请输入你的选择: " host_dns

				  case $host_dns in
					  1)
				  		send_stats "生成新密钥"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "导入已有公钥"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "查看本机密钥"
						echo "------------------------"
						echo "公钥信息"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "私钥信息"
						cat ~/.ssh/sshkey
						echo "------------------------"
						break_end

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  25)
			  root_use
			  send_stats "电报预警"
			  echo "TG-bot监控预警功能"
			  echo "视频介绍: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "您需要配置tg机器人API和接收预警的用户ID，即可实现本机CPU，内存，硬盘，流量，SSH登录的实时监控预警"
			  echo "到达阈值后会向用户发预警消息"
			  echo -e "${gl_hui}-关于流量，重启服务器将重新计算-${gl_bai}"
			  read -e -p "确定继续吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  send_stats "电报预警启用"
				  cd ~
				  install nano tmux bc jq
				  check_crontab_installed
				  if [ -f ~/TG-check-notify.sh ]; then
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  else
					  curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/TG-check-notify.sh
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  fi
				  tmux kill-session -t TG-check-notify > /dev/null 2>&1
				  tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
				  crontab -l | grep -v '~/TG-check-notify.sh' | crontab - > /dev/null 2>&1
				  (crontab -l ; echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'") | crontab - > /dev/null 2>&1

				  curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "3i$(grep '^TELEGRAM_BOT_TOKEN=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh > /dev/null 2>&1
				  sed -i "4i$(grep '^CHAT_ID=' ~/TG-check-notify.sh)" TG-SSH-check-notify.sh
				  chmod +x ~/TG-SSH-check-notify.sh

				  # 添加到 ~/.profile 文件中
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "TG-bot预警系统已启动"
				  echo -e "${gl_hui}你还可以将root目录中的TG-check-notify.sh预警文件放到其他机器上直接使用！${gl_bai}"
				  ;;
				[Nn])
				  echo "已取消"
				  ;;
				*)
				  echo "无效的选择，请输入 Y 或 N。"
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "修复SSH高危漏洞"
			  cd ~
			  curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/upgrade_openssh9.8p1.sh
			  chmod +x ~/upgrade_openssh9.8p1.sh
			  ~/upgrade_openssh9.8p1.sh
			  rm -f ~/upgrade_openssh9.8p1.sh
			  ;;

		  27)
			  elrepo
			  ;;
		  28)
			  Kernel_optimize
			  ;;

		  29)
			  clamav
			  ;;

		  30)
			  linux_file
			  ;;

		  31)
			  linux_language
			  ;;

		  32)
			  shell_bianse
			  ;;
		  33)
			  linux_trash
			  ;;
		  41)
			clear
			send_stats "留言板"
			echo "科技lion留言板已迁移至官方社区！请在官方社区进行留言噢！"
			echo "https://bbs.kejilion.pro/"
			  ;;

		  66)

			  root_use
			  send_stats "一条龙调优"
			  echo "一条龙系统调优"
			  echo "------------------------------------------------"
			  echo "将对以下内容进行操作与优化"
			  echo "1. 更新系统到最新"
			  echo "2. 清理系统垃圾文件"
			  echo -e "3. 设置虚拟内存${gl_huang}1G${gl_bai}"
			  echo -e "4. 设置SSH端口号为${gl_huang}5522${gl_bai}"
			  echo -e "5. 开放所有端口"
			  echo -e "6. 开启${gl_huang}BBR${gl_bai}加速"
			  echo -e "7. 设置时区到${gl_huang}上海${gl_bai}"
			  echo -e "8. 自动优化DNS地址${gl_huang}海外: 1.1.1.1 8.8.8.8  国内: 223.5.5.5 ${gl_bai}"
			  echo -e "9. 安装基础工具${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10. Linux系统内核参数优化切换到${gl_huang}均衡优化模式${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "确定一键保养吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "一条龙调优启动"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/10. 更新系统到最新"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/10. 清理系统垃圾文件"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/10. 设置虚拟内存${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/10. 设置SSH端口号为${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 5/10. 开放所有端口"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 6/10. 开启${gl_huang}BBR${gl_bai}加速"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 7/10. 设置时区到${gl_huang}上海${gl_bai}"

				  echo "------------------------------------------------"
				  local country=$(curl -s ipinfo.io/country)
				  if [ "$country" = "CN" ]; then
					 local dns1_ipv4="223.5.5.5"
					 local dns2_ipv4="183.60.83.19"
					 local dns1_ipv6="2400:3200::1"
					 local dns2_ipv6="2400:da00::6666"
				  else
					 local dns1_ipv4="1.1.1.1"
					 local dns2_ipv4="8.8.8.8"
					 local dns1_ipv6="2606:4700:4700::1111"
					 local dns2_ipv6="2001:4860:4860::8888"
				  fi

				  set_dns
				  echo -e "[${gl_lv}OK${gl_bai}] 8/10. 自动优化DNS地址${gl_huang}${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 9/10. 安装基础工具${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10. Linux系统内核参数优化"
				  echo -e "${gl_lv}一条龙系统调优已完成${gl_bai}"

				  ;;
				[Nn])
				  echo "已取消"
				  ;;
				*)
				  echo "无效的选择，请输入 Y 或 N。"
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "重启系统"
			  server_reboot
			  ;;
		  100)

			root_use
			while true; do
			  clear
			  if grep -q '^ENABLE_STATS="true"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_lv}正在采集数据${gl_bai}"
			  elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_hui}采集已关闭${gl_bai}"
			  else
			  	local status_message="无法确定的状态"
			  fi

			  echo "隐私与安全"
			  echo "脚本将收集用户使用功能的数据，优化脚本体验，制作更多好玩好用的功能"
			  echo "将收集脚本版本号，使用的时间，系统版本，CPU架构，机器所属国家和使用的功能的名称，"
			  echo "------------------------------------------------"
			  echo -e "当前状态: $status_message"
			  echo "--------------------"
			  echo "1. 开启采集"
			  echo "2. 关闭采集"
			  echo "--------------------"
			  echo "0. 返回上一级"
			  echo "--------------------"
			  read -e -p "请输入你的选择: " sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "已开启采集"
					  send_stats "隐私与安全已开启采集"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "已关闭采集"
					  send_stats "隐私与安全已关闭采集"
					  ;;
				  *)
					  break
					  ;;
			  esac
			done
			  ;;

		  101)
			  clear
			  k_info
			  ;;

		  102)
			  clear
			  send_stats "卸载科技lion脚本"
			  echo "卸载科技lion脚本"
			  echo "------------------------------------------------"
			  echo "将彻底卸载kejilion脚本，不影响你其他功能"
			  read -e -p "确定继续吗？(Y/N): " choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "脚本已卸载，再见！"
				  break_end
				  clear
				  exit
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
			  kejilion

			  ;;
		  *)
			  echo "无效的输入!"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "文件管理器"
	while true; do
		clear
		echo "文件管理器"
		echo "------------------------"
		echo "当前路径"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1.  进入目录           2.  创建目录             3.  修改目录权限         4.  重命名目录"
		echo "5.  删除目录           6.  返回上一级目录"
		echo "------------------------"
		echo "11. 创建文件           12. 编辑文件             13. 修改文件权限         14. 重命名文件"
		echo "15. 删除文件"
		echo "------------------------"
		echo "21. 压缩文件目录       22. 解压文件目录         23. 移动文件目录         24. 复制文件目录"
		echo "25. 传文件至其他服务器"
		echo "------------------------"
		echo "0.  返回上一级"
		echo "------------------------"
		read -e -p "请输入你的选择: " Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "请输入目录名: " dirname
				cd "$dirname" 2>/dev/null || echo "无法进入目录"
				send_stats "进入目录"
				;;
			2)  # 创建目录
				read -e -p "请输入要创建的目录名: " dirname
				mkdir -p "$dirname" && echo "目录已创建" || echo "创建失败"
				send_stats "创建目录"
				;;
			3)  # 修改目录权限
				read -e -p "请输入目录名: " dirname
				read -e -p "请输入权限 (如 755): " perm
				chmod "$perm" "$dirname" && echo "权限已修改" || echo "修改失败"
				send_stats "修改目录权限"
				;;
			4)  # 重命名目录
				read -e -p "请输入当前目录名: " current_name
				read -e -p "请输入新目录名: " new_name
				mv "$current_name" "$new_name" && echo "目录已重命名" || echo "重命名失败"
				send_stats "重命名目录"
				;;
			5)  # 删除目录
				read -e -p "请输入要删除的目录名: " dirname
				rm -rf "$dirname" && echo "目录已删除" || echo "删除失败"
				send_stats "删除目录"
				;;
			6)  # 返回上一级目录
				cd ..
				send_stats "返回上一级目录"
				;;
			11) # 创建文件
				read -e -p "请输入要创建的文件名: " filename
				touch "$filename" && echo "文件已创建" || echo "创建失败"
				send_stats "创建文件"
				;;
			12) # 编辑文件
				read -e -p "请输入要编辑的文件名: " filename
				install nano
				nano "$filename"
				send_stats "编辑文件"
				;;
			13) # 修改文件权限
				read -e -p "请输入文件名: " filename
				read -e -p "请输入权限 (如 755): " perm
				chmod "$perm" "$filename" && echo "权限已修改" || echo "修改失败"
				send_stats "修改文件权限"
				;;
			14) # 重命名文件
				read -e -p "请输入当前文件名: " current_name
				read -e -p "请输入新文件名: " new_name
				mv "$current_name" "$new_name" && echo "文件已重命名" || echo "重命名失败"
				send_stats "重命名文件"
				;;
			15) # 删除文件
				read -e -p "请输入要删除的文件名: " filename
				rm -f "$filename" && echo "文件已删除" || echo "删除失败"
				send_stats "删除文件"
				;;
			21) # 压缩文件/目录
				read -e -p "请输入要压缩的文件/目录名: " name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "已压缩为 $name.tar.gz" || echo "压缩失败"
				send_stats "压缩文件/目录"
				;;
			22) # 解压文件/目录
				read -e -p "请输入要解压的文件名 (.tar.gz): " filename
				install tar
				tar -xzvf "$filename" && echo "已解压 $filename" || echo "解压失败"
				send_stats "解压文件/目录"
				;;

			23) # 移动文件或目录
				read -e -p "请输入要移动的文件或目录路径: " src_path
				if [ ! -e "$src_path" ]; then
					echo "错误: 文件或目录不存在。"
					send_stats "移动文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "请输入目标路径 (包括新文件名或目录名): " dest_path
				if [ -z "$dest_path" ]; then
					echo "错误: 请输入目标路径。"
					send_stats "移动文件或目录失败: 目标路径未指定"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "文件或目录已移动到 $dest_path" || echo "移动文件或目录失败"
				send_stats "移动文件或目录"
				;;


		   24) # 复制文件目录
				read -e -p "请输入要复制的文件或目录路径: " src_path
				if [ ! -e "$src_path" ]; then
					echo "错误: 文件或目录不存在。"
					send_stats "复制文件或目录失败: 文件或目录不存在"
					continue
				fi

				read -e -p "请输入目标路径 (包括新文件名或目录名): " dest_path
				if [ -z "$dest_path" ]; then
					echo "错误: 请输入目标路径。"
					send_stats "复制文件或目录失败: 目标路径未指定"
					continue
				fi

				# 使用 -r 选项以递归方式复制目录
				cp -r "$src_path" "$dest_path" && echo "文件或目录已复制到 $dest_path" || echo "复制文件或目录失败"
				send_stats "复制文件或目录"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "请输入要传送的文件路径: " file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "错误: 文件不存在。"
					send_stats "传送文件失败: 文件不存在"
					continue
				fi

				read -e -p "请输入远端服务器IP: " remote_ip
				if [ -z "$remote_ip" ]; then
					echo "错误: 请输入远端服务器IP。"
					send_stats "传送文件失败: 未输入远端服务器IP"
					continue
				fi

				read -e -p "请输入远端服务器用户名 (默认root): " remote_user
				remote_user=${remote_user:-root}

				read -e -p "请输入远端服务器密码: " -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "错误: 请输入远端服务器密码。"
					send_stats "传送文件失败: 未输入远端服务器密码"
					continue
				fi

				read -e -p "请输入登录端口 (默认22): " remote_port
				remote_port=${remote_port:-22}

				# 清除已知主机的旧条目
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# 使用scp传输文件
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "文件已传送至远程服务器home目录。"
					send_stats "文件传送成功"
				else
					echo "文件传送失败。"
					send_stats "文件传送失败"
				fi

				break_end
				;;



			0)  # 返回上一级
				send_stats "返回上一级菜单"
				break
				;;
			*)  # 处理无效输入
				echo "无效的选择，请重新输入"
				send_stats "无效选择"
				;;
		esac
	done
}






cluster_python3() {
	install python3 python3-paramiko
	cd ~/cluster/
	curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
	python3 ~/cluster/$py_task
}


run_commands_on_servers() {

	local SERVERS_FILE="$HOME/cluster/servers.py"
	local SERVERS=$(grep -oP '{"name": "\K[^"]+|"hostname": "\K[^"]+|"port": \K[^,]+|"username": "\K[^"]+|"password": "\K[^"]+' "$SERVERS_FILE")

	# 将提取的信息转换为数组
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# 遍历服务器并执行命令
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}连接到 $name ($hostname)...${gl_bai}"
		# sshpass -p "$password" ssh -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
		sshpass -p "$password" ssh -t -o StrictHostKeyChecking=no "$username@$hostname" -p "$port" "$1"
	done
	echo
	break_end

}


linux_cluster() {
mkdir cluster
if [ ! -f ~/cluster/servers.py ]; then
	cat > ~/cluster/servers.py << EOF
servers = [

]
EOF
fi

while true; do
	  clear
	  send_stats "集群控制中心"
	  echo "▶ 📡 服务器集群控制"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}服务器列表管理${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}添加服务器               ${gl_kjlan}2.  ${gl_bai}删除服务器            ${gl_kjlan}3.  ${gl_bai}编辑服务器"
	  echo -e "${gl_kjlan}4.  ${gl_bai}备份集群                 ${gl_kjlan}5.  ${gl_bai}还原集群"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}批量执行任务${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}安装科技lion脚本         ${gl_kjlan}12. ${gl_bai}更新系统              ${gl_kjlan}13. ${gl_bai}清理系统"
	  echo -e "${gl_kjlan}14. ${gl_bai}安装docker               ${gl_kjlan}15. ${gl_bai}安装BBR3              ${gl_kjlan}16. ${gl_bai}设置1G虚拟内存"
	  echo -e "${gl_kjlan}17. ${gl_bai}设置时区到上海           ${gl_kjlan}18. ${gl_bai}开放所有端口	       ${gl_kjlan}51. ${gl_bai}自定义指令"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}返回上一级选单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice

	  case $sub_choice in
		  1)
			  send_stats "添加集群服务器"
			  read -e -p "服务器名称: " server_name
			  read -e -p "服务器IP: " server_ip
			  read -e -p "服务器端口（22）: " server_port
			  local server_port=${server_port:-22}
			  read -e -p "服务器用户名（root）: " server_username
			  local server_username=${server_username:-root}
			  read -e -p "服务器用户密码: " server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "删除集群服务器"
			  read -e -p "请输入需要删除的关键字: " rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "编辑集群服务器"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "备份集群"
			  echo -e "请将 ${gl_huang}/root/cluster/servers.py${gl_bai} 文件下载，完成备份！"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "还原集群"
			  echo "请上传您的servers.py，按任意键开始上传！"
			  echo -e "请上传您的 ${gl_huang}servers.py${gl_bai} 文件到 ${gl_huang}/root/cluster/${gl_bai} 完成还原！"
			  break_end
			  ;;

		  11)
			  local py_task="install_kejilion.py"
			  cluster_python3
			  ;;
		  12)
			  run_commands_on_servers "k update"
			  ;;
		  13)
			  run_commands_on_servers "k clean"
			  ;;
		  14)
			  run_commands_on_servers "k docker install"
			  ;;
		  15)
			  run_commands_on_servers "k bbr3"
			  ;;
		  16)
			  run_commands_on_servers "k swap 1024"
			  ;;
		  17)
			  run_commands_on_servers "k time Asia/Shanghai"
			  ;;
		  18)
			  run_commands_on_servers "k iptables_open"
			  ;;

		  51)
			  send_stats "自定义执行命令"
			  read -e -p "请输入批量执行的命令: " mingling
			  run_commands_on_servers "${mingling}"
			  ;;

		  *)
			  kejilion
			  ;;
	  esac
done

}




kejilion_Affiliates() {

clear
send_stats "广告专栏"
echo "💼 广告专栏"
echo "------------------------"
echo "将为用户提供更简单优雅的推广与购买体验！"
echo ""
echo -e "服务器优惠"
echo "------------------------"
echo -e "${gl_lan}RackNerd 10.18刀每年 美国 1核心 768M内存 15G硬盘 1T流量每月${gl_bai}"
echo -e "${gl_bai}网址: https://my.racknerd.com/aff.php?aff=5501&pid=792${gl_bai}"
echo "------------------------"
echo -e "${gl_lv}Cloudcone 10刀每年 美国 1核心 768M内存 5G硬盘 3T流量每月${gl_bai}"
echo -e "${gl_bai}网址: https://app.cloudcone.com.cn/vps/261/create?ref=8355&token=cloudcone.cc-24-vps-2${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}搬瓦工 49刀每季 美国CN2GIA 日本软银 2核心 1G内存 20G硬盘 1T流量每月${gl_bai}"
echo -e "${gl_bai}网址: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT 28刀每季 美国CN2GIA 1核心 2G内存 20G硬盘 800G流量每月${gl_bai}"
echo -e "${gl_bai}网址: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS 6.9刀每月 东京软银 2核心 1G内存 20G硬盘 1T流量每月${gl_bai}"
echo -e "${gl_bai}网址: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}VPS更多热门优惠${gl_bai}"
echo -e "${gl_bai}网址: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "域名优惠"
echo "------------------------"
echo -e "${gl_lan}GNAME 8.8刀首年COM域名 6.68刀首年CC域名${gl_bai}"
echo -e "${gl_bai}网址: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "科技lion周边"
echo "------------------------"
echo -e "${gl_kjlan}B站:   ${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}油管:     ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}官网:  ${gl_bai}https://kejilion.pro/               ${gl_kjlan}导航:     ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}博客:  ${gl_bai}https://blog.kejilion.pro/          ${gl_kjlan}软件中心: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

	send_stats "脚本更新"
	cd ~
	clear
	echo "🔃 更新日志"
	echo "------------------------"
	echo "全部日志: ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 35
	local sh_v_new=$(curl -s ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}你已经是最新版本！${gl_huang}v$sh_v${gl_bai}"
		send_stats "脚本已经最新了，无需更新"
	else
		echo "发现新版本！"
		echo -e "当前版本 v$sh_v        最新版本 ${gl_huang}v$sh_v_new${gl_bai}"
		echo "------------------------"
		echo "1. 现在更新            2. 自动更新            0. 返回主菜单"
		echo "------------------------"
		read -e -p "请输入你的选择: " choice

		case "$choice" in
			1)
				clear
				local country=$(curl -s ipinfo.io/country)
				if [ "$country" = "CN" ]; then
					curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/cn/kejilion.sh && chmod +x kejilion.sh
				else
					curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh
				fi
				canshu_v6
				CheckFirstRun_true
				yinsiyuanquan2
				cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1
				echo -e "${gl_lv}脚本已更新到最新版本！${gl_huang}v$sh_v_new${gl_bai}"
				send_stats "脚本已经最新$sh_v_new"
				break_end
				~/kejilion.sh
				exit
				;;
			2)
				clear
				local country=$(curl -s ipinfo.io/country)
				local ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)

				if [ "$country" = "CN" ]; then
					SH_Update_task="curl -sS -O https://gh.kejilion.pro/https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"CN\"/g' ./kejilion.sh && ./kejilion.sh"
				elif [ -n "$ipv6_address" ]; then
					SH_Update_task="curl -sS -O https://gh.kejilion.pro/https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"V6\"/g' ./kejilion.sh && ./kejilion.sh"
				else
					SH_Update_task="curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && ./kejilion.sh"
				fi

				check_crontab_installed
				(crontab -l | grep -v "kejilion.sh") | crontab -
				(crontab -l 2>/dev/null; echo "0 2 * * * /usr/bin/timeout 10 /bin/bash -c \"$SH_Update_task\"") | crontab -

				echo -e "${gl_lv}自动更新已设置，每天凌晨2点脚本会自动更新！${gl_bai}"
				send_stats "开启脚本自动更新"
				break_end
				kejilion_sh
				;;
			*)
				kejilion_sh
				;;
		esac
	fi


}





kejilion_sh() {
while true; do
clear
echo -e "${gl_kjlan}"
echo "╦╔═╔═╗ ╦╦╦  ╦╔═╗╔╗╔ ╔═╗╦ ╦"
echo "╠╩╗║╣  ║║║  ║║ ║║║║ ╚═╗╠═╣"
echo "╩ ╩╚═╝╚╝╩╩═╝╩╚═╝╝╚╝o╚═╝╩ ╩"
echo -e "科技lion脚本工具箱 v$sh_v"
echo -e "命令行输入${gl_huang}k${gl_kjlan}可快速启动脚本${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   💻 ${gl_bai}系统信息查询"
echo -e "${gl_kjlan}2.   🔄 ${gl_bai}系统更新"
echo -e "${gl_kjlan}3.   🧹 ${gl_bai}系统清理"
echo -e "${gl_kjlan}4.   🛠️  ${gl_bai}基础工具 ▶"
echo -e "${gl_kjlan}5.   🚀 ${gl_bai}BBR管理 ▶"
echo -e "${gl_kjlan}6.   🐳 ${gl_bai}Docker管理 ▶ "
echo -e "${gl_kjlan}7.   🌍 ${gl_bai}WARP管理 ▶ "
echo -e "${gl_kjlan}8.   🧪 ${gl_bai}测试脚本合集 ▶ "
echo -e "${gl_kjlan}9.   🏢 ${gl_bai}甲骨文云脚本合集 ▶ "
echo -e "${gl_huang}10.  🌐 ${gl_bai}LDNMP建站 ▶ "
echo -e "${gl_kjlan}11.  🛒 ${gl_bai}应用市场 ▶ "
echo -e "${gl_kjlan}12.  📁 ${gl_bai}我的工作区 ▶ "
echo -e "${gl_kjlan}13.  ⚙️  ${gl_bai}系统工具 ▶ "
echo -e "${gl_kjlan}14.  📡 ${gl_bai}服务器集群控制 ▶ "
echo -e "${gl_kjlan}15.  💼 ${gl_bai}广告专栏"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   🎮 ${gl_bai}幻兽帕鲁开服脚本 ▶"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  🔃 ${gl_bai}脚本更新"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ❌ ${gl_bai}退出脚本"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "请输入你的选择: " choice

case $choice in
  1) linux_ps ;;
  2) clear ; send_stats "系统更新" ; linux_update ;;
  3) clear ; send_stats "系统清理" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "warp管理" ; install wget
	wget -N https://gitlab.com/fscarmen/warp/-/raw/main/menu.sh ; bash menu.sh [option] [lisence/url/token]
	;;
  8) linux_test ;;
  9) linux_Oracle ;;
  10) linux_ldnmp ;;
  11) linux_panel ;;
  12) linux_work ;;
  13) linux_Settings ;;
  14) linux_cluster ;;
  15) kejilion_Affiliates ;;
  p) send_stats "幻兽帕鲁开服脚本" ; cd ~
	 curl -sS -O ${gh_proxy}https://raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "无效的输入!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k命令参考用例"
echo "-------------------"
echo "视频介绍: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
echo "以下是k命令参考用例："
echo "启动脚本            k"
echo "安装软件包          k install nano wget | k add nano wget | k 安装 nano wget"
echo "卸载软件包          k remove nano wget | k del nano wget | k uninstall nano wget | k 卸载 nano wget"
echo "更新系统            k update | k 更新"
echo "清理系统垃圾        k clean | k 清理"
echo "打开重装系统面板    k dd | k 重装"
echo "打开bbr3控制面板    k bbr3 | k bbrv3"
echo "打开内核调优面板    k nhyh | k 内核优化"
echo "设置虚拟内存        k swap 2048"
echo "设置虚拟时区        k time Asia/Shanghai | k 时区 Asia/Shanghai"
echo "打开系统回收站      k trash | k hsz | k 回收站"
echo "内网穿透（服务端）  k frps"
echo "内网穿透（客户端）  k frpc"
echo "软件启动            k start sshd | k 启动 sshd "
echo "软件停止            k stop sshd | k 停止 sshd "
echo "软件重启            k restart sshd | k 重启 sshd "
echo "软件状态查看        k status sshd | k 状态 sshd "
echo "软件开机启动        k enable docker | k autostart docke | k 开机启动 docker "
echo "域名证书申请        k ssl"
echo "域名证书到期查询    k ssl ps"
echo "docker环境安装      k docker install |k docker 安装"
echo "docker容器管理      k docker ps |k docker 容器"
echo "docker镜像管理      k docker img |k docker 镜像"
echo "LDNMP站点管理       k web"
echo "LDNMP缓存清理       k web cache"
echo "安装WordPress       k wp |k wordpress |k wp xxx.com"
echo "安装反向代理        k fd |k rp |k 反代 |k fd xxx.com"

}



if [ "$#" -eq 0 ]; then
	# 如果没有参数，运行交互式逻辑
	kejilion_sh
else
	# 如果有参数，执行相应函数
	case $1 in
		install|add|安装)
			shift
			send_stats "安装软件"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "卸载软件"
			remove "$@"
			;;
		update|更新)
			linux_update
			;;
		clean|清理)
			linux_clean
			;;
		dd|重装)
			dd_xitong
			;;
		bbr3|bbrv3)
			bbrv3
			;;
		nhyh|内核优化)
			Kernel_optimize
			;;
		trash|hsz|回收站)
			linux_trash
			;;
		wp|wordpress)
			shift
			ldnmp_wp "$@"

			;;
		fd|rp|反代)
			shift
			ldnmp_Proxy "$@"
			;;

		swap)
			shift
			send_stats "快速设置虚拟内存"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "快速设置时区"
			set_timedate "$@"
			;;


		iptables_open)
			iptables_open
			;;

		frps)
			frps_panel
			;;

		frpc)
			frpc_panel
			;;




		status|状态)
			shift
			send_stats "软件状态查看"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "软件启动"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "软件暂停"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "软件重启"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "软件开机自启"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "查看证书状态"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "快速申请证书"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "快速申请证书"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "快捷安装docker"
					install_docker
					;;
				ps|容器)
					send_stats "快捷容器管理"
					docker_ps
					;;
				img|镜像)
					send_stats "快捷镜像管理"
					docker_image
					;;
				*)
					k_info
					;;
			esac
			;;

		web)
		   shift
			if [ "$1" = "cache" ]; then
				web_cache
			elif [ -z "$1" ]; then
				ldnmp_web_status
			else
				k_info
			fi
			;;
		*)
			k_info
			;;
	esac
fi
