#!/bin/bash
sh_v="4.3.1"


gl_hui='\e[37m'
gl_hong='\033[31m'
gl_lv='\033[32m'
gl_huang='\033[33m'
gl_lan='\033[34m'
gl_bai='\033[0m'
gl_zi='\033[35m'
gl_kjlan='\033[96m'


canshu="default"
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
	gh_proxy="https://"
fi

}
quanju_canshu



# 定義一個函數來執行命令
run_command() {
	if [ "$zhushi" -eq 0 ]; then
		"$@"
	fi
}


canshu_v6() {
	if grep -q '^canshu="V6"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^canshu="default"/canshu="V6"/' ~/kejilion.sh
	fi
}


CheckFirstRun_true() {
	if grep -q '^permission_granted="true"' /usr/local/bin/k > /dev/null 2>&1; then
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
	fi
}



# 收集功能埋點信息的函數，記錄當前腳本版本號，使用時間，系統版本，CPU架構，機器所在國家和用戶使用的功能名稱，絕對不涉及任何敏感信息，請放心！請相信我！
# 為什麼要設計這個功能，目的更好的了解用戶喜歡使用的功能，進一步優化功能推出更多符合用戶需求的功能。
# 全文可搜搜 send_stats 函數調用位置，透明開源，如有顧慮可拒絕使用。



send_stats() {
	if [ "$ENABLE_STATS" == "false" ]; then
		return
	fi

	local country=$(curl -s ipinfo.io/country)
	local os_info=$(grep PRETTY_NAME /etc/os-release | cut -d '=' -f2 | tr -d '"')
	local cpu_arch=$(uname -m)

	(
		curl -s -X POST "https://api.kejilion.pro/api/log" \
			-H "Content-Type: application/json" \
			-d "{\"action\":\"$1\",\"timestamp\":\"$(date -u '+%Y-%m-%d %H:%M:%S')\",\"country\":\"$country\",\"os_info\":\"$os_info\",\"cpu_arch\":\"$cpu_arch\",\"version\":\"$sh_v\"}" \
		&>/dev/null
	) &

}


yinsiyuanquan2() {

if grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
	sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
fi

}



canshu_v6
CheckFirstRun_true
yinsiyuanquan2


sed -i '/^alias k=/d' ~/.bashrc > /dev/null 2>&1
sed -i '/^alias k=/d' ~/.profile > /dev/null 2>&1
sed -i '/^alias k=/d' ~/.bash_profile > /dev/null 2>&1
cp -f ./kejilion.sh ~/kejilion.sh > /dev/null 2>&1
cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1



CheckFirstRun_false() {
	if grep -q '^permission_granted="false"' /usr/local/bin/k > /dev/null 2>&1; then
		UserLicenseAgreement
	fi
}

# 提示用戶同意條款
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}歡迎使用科技lion腳本工具箱${gl_bai}"
	echo "首次使用腳本，請先閱讀並同意用戶許可協議。"
	echo "用戶許可協議: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "是否同意以上條款？ (y/n):" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "許可同意"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "許可拒絕"
		clear
		exit
	fi
}

CheckFirstRun_false





ip_address() {

get_public_ip() {
	curl -s https://ipinfo.io/ip && echo
}

get_local_ip() {
	ip route get 8.8.8.8 2>/dev/null | grep -oP 'src \K[^ ]+' || \
	hostname -I 2>/dev/null | awk '{print $1}' || \
	ifconfig 2>/dev/null | grep -E 'inet [0-9]' | grep -v '127.0.0.1' | awk '{print $2}' | head -n1
}

public_ip=$(get_public_ip)
isp_info=$(curl -s --max-time 3 http://ipinfo.io/org)


if echo "$isp_info" | grep -Eiq 'mobile|unicom|telecom'; then
  ipv4_address=$(get_local_ip)
else
  ipv4_address="$public_ip"
fi


# ipv4_address=$(curl -s https://ipinfo.io/ip && echo)
ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)

}



install() {
	if [ $# -eq 0 ]; then
		echo "未提供軟件包參數!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}正在安裝$package...${gl_bai}"
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
			elif command -v pkg &>/dev/null; then
				pkg update
				pkg install -y "$package"
			else
				echo "未知的包管理器!"
				return 1
			fi
		fi
	done
}


check_disk_space() {
	local required_gb=$1
	local path=${2:-/}

	mkdir -p "$path"

	local required_space_mb=$((required_gb * 1024))
	local available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

	if [ "$available_space_mb" -lt "$required_space_mb" ]; then
		echo -e "${gl_huang}提示:${gl_bai}磁盤空間不足！"
		echo "當前可用空間: $((available_space_mb/1024))G"
		echo "最小需求空間:${required_gb}G"
		echo "無法繼續安裝，請清理磁盤空間後重試。"
		send_stats "磁盤空間不足"
		break_end
		kejilion
	fi
}



install_dependency() {
	switch_mirror false false
	check_port
	check_swap
	prefer_ipv4
	auto_optimize_dns
	install wget unzip tar jq grep

}

remove() {
	if [ $# -eq 0 ]; then
		echo "未提供軟件包參數!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}正在卸載$package...${gl_bai}"
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
		elif command -v pkg &>/dev/null; then
			pkg delete -y "$package"
		else
			echo "未知的包管理器!"
			return 1
		fi
	done
}


# 通用 systemctl 函數，適用於各種發行版
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# 重啟服務
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1服務已重啟。"
	else
		echo "錯誤：重啟$1服務失敗。"
	fi
}

# 啟動服務
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1服務已啟動。"
	else
		echo "錯誤：啟動$1服務失敗。"
	fi
}

# 停止服務
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1服務已停止。"
	else
		echo "錯誤：停止$1服務失敗。"
	fi
}

# 查看服務狀態
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1服務狀態已顯示。"
	else
		echo "錯誤：無法顯示$1服務狀態。"
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME已設置為開機自啟。"
}



break_end() {
	  echo -e "${gl_lv}操作完成${gl_bai}"
	  echo "按任意鍵繼續..."
	  read -n 1 -s -r -p ""
	  echo ""
	  clear
}

kejilion() {
			cd ~
			kejilion_sh
}




stop_containers_or_kill_process() {
	local port=$1
	local containers=$(docker ps --filter "publish=$port" --format "{{.ID}}" 2>/dev/null)

	if [ -n "$containers" ]; then
		docker stop $containers
	else
		install lsof
		for pid in $(lsof -t -i:$port); do
			kill -9 $pid
		done
	fi
}


check_port() {
	stop_containers_or_kill_process 80
	stop_containers_or_kill_process 443
}


install_add_docker_cn() {

local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	cat > /etc/docker/daemon.json << EOF
{
  "registry-mirrors": [
	"https://docker.1ms.run",
	"https://docker.m.ixdev.cn",
	"https://hub.rat.dev",
	"https://dockerproxy.net",
	"https://docker-registry.nmqu.com",
	"https://docker.amingg.com",
	"https://docker.hlmirror.com",
	"https://hub1.nat.tf",
	"https://hub2.nat.tf",
	"https://hub3.nat.tf",
	"https://docker.m.daocloud.io",
	"https://docker.kejilion.pro",
	"https://docker.367231.xyz",
	"https://hub.1panel.dev",
	"https://dockerproxy.cool",
	"https://docker.apiba.cn",
	"https://proxy.vvvv.ee"
  ]
}
EOF
fi


enable docker
start docker
restart docker

}



linuxmirrors_install_docker() {

local country=$(curl -s ipinfo.io/country)
if [ "$country" = "CN" ]; then
	bash <(curl -sSL https://linuxmirrors.cn/docker.sh) \
	  --source mirrors.huaweicloud.com/docker-ce \
	  --source-registry docker.1ms.run \
	  --protocol https \
	  --use-intranet-source false \
	  --install-latest true \
	  --close-firewall false \
	  --ignore-backup-tips
else
	bash <(curl -sSL https://linuxmirrors.cn/docker.sh) \
	  --source download.docker.com \
	  --source-registry registry.hub.docker.com \
	  --protocol https \
	  --use-intranet-source false \
	  --install-latest true \
	  --close-firewall false \
	  --ignore-backup-tips
fi

install_add_docker_cn

}



install_add_docker() {
	echo -e "${gl_huang}正在安裝docker環境...${gl_bai}"
	if command -v apt &>/dev/null || command -v yum &>/dev/null || command -v dnf &>/dev/null; then
		linuxmirrors_install_docker
	else
		install docker docker-compose
		install_add_docker_cn

	fi
	sleep 2
}


install_docker() {
	if ! command -v docker &>/dev/null; then
		install_add_docker
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
	echo "1. 創建新的容器"
	echo "------------------------"
	echo "2. 啟動指定容器             6. 啟動所有容器"
	echo "3. 停止指定容器             7. 停止所有容器"
	echo "4. 刪除指定容器             8. 刪除所有容器"
	echo "5. 重啟指定容器             9. 重啟所有容器"
	echo "------------------------"
	echo "11. 進入指定容器           12. 查看容器日誌"
	echo "13. 查看容器網絡           14. 查看容器佔用"
	echo "------------------------"
	echo "15. 開啟容器端口訪問       16. 關閉容器端口訪問"
	echo "------------------------"
	echo "0. 返回上一級選單"
	echo "------------------------"
	read -e -p "請輸入你的選擇:" sub_choice
	case $sub_choice in
		1)
			send_stats "新建容器"
			read -e -p "請輸入創建命令:" dockername
			$dockername
			;;
		2)
			send_stats "啟動指定容器"
			read -e -p "請輸入容器名（多個容器名請用空格分隔）:" dockername
			docker start $dockername
			;;
		3)
			send_stats "停止指定容器"
			read -e -p "請輸入容器名（多個容器名請用空格分隔）:" dockername
			docker stop $dockername
			;;
		4)
			send_stats "刪除指定容器"
			read -e -p "請輸入容器名（多個容器名請用空格分隔）:" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "重啟指定容器"
			read -e -p "請輸入容器名（多個容器名請用空格分隔）:" dockername
			docker restart $dockername
			;;
		6)
			send_stats "啟動所有容器"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "停止所有容器"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "刪除所有容器"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "無效的選擇，請輸入 Y 或 N。"
				;;
			esac
			;;
		9)
			send_stats "重啟所有容器"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "進入容器"
			read -e -p "請輸入容器名:" dockername
			docker exec $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "查看容器日誌"
			read -e -p "請輸入容器名:" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "查看容器網絡"
			echo ""
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			printf "%-25s %-25s %-25s\n" "容器名稱" "網絡名稱" "IP地址"
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
			send_stats "查看容器佔用"
			docker stats --no-stream
			break_end
			;;

		15)
			send_stats "允許容器端口訪問"
			read -e -p "請輸入容器名:" docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "阻止容器端口訪問"
			read -e -p "請輸入容器名:" docker_name
			ip_address
			block_container_port "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
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
	send_stats "Docker鏡像管理"
	echo "Docker鏡像列表"
	docker image ls
	echo ""
	echo "鏡像操作"
	echo "------------------------"
	echo "1. 獲取指定鏡像             3. 刪除指定鏡像"
	echo "2. 更新指定鏡像             4. 刪除所有鏡像"
	echo "------------------------"
	echo "0. 返回上一級選單"
	echo "------------------------"
	read -e -p "請輸入你的選擇:" sub_choice
	case $sub_choice in
		1)
			send_stats "拉取鏡像"
			read -e -p "請輸入鏡像名（多個鏡像名請用空格分隔）:" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在獲取鏡像:$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "更新鏡像"
			read -e -p "請輸入鏡像名（多個鏡像名請用空格分隔）:" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}正在更新鏡像:$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "刪除鏡像"
			read -e -p "請輸入鏡像名（多個鏡像名請用空格分隔）:" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "刪除所有鏡像"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "無效的選擇，請輸入 Y 或 N。"
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
	if ! command -v crontab >/dev/null 2>&1; then
		install_crontab
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
			iStoreOS|openwrt|ImmortalWrt|lede)
				opkg update
				opkg install cron
				/etc/init.d/cron enable
				/etc/init.d/cron start
				;;
			FreeBSD)
				pkg install -y cronie
				sysrc cron_enable="YES"
				service cron start
				;;
			*)
				echo "不支持的發行版:$ID"
				return
				;;
		esac
	else
		echo "無法確定操作系統。"
		return
	fi

	echo -e "${gl_lv}crontab 已安裝且 cron 服務正在運行。${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 檢查配置文件是否存在，如果不存在則創建文件並寫入默認設置
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# 使用jq處理配置文件的更新
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 檢查當前配置是否已經有 ipv6 設置
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 更新配置，開啟 IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 對比原始配置與新配置
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}當前已開啟ipv6訪問${gl_bai}"
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

	# 檢查配置文件是否存在
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}配置文件不存在${gl_bai}"
		return
	fi

	# 讀取當前配置
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# 使用jq處理配置文件的更新
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 檢查當前的 ipv6 狀態
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 對比原始配置與新配置
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}當前已關閉ipv6訪問${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}已成功關閉ipv6訪問${gl_bai}"
	fi
}



save_iptables_rules() {
	mkdir -p /etc/iptables
	touch /etc/iptables/rules.v4
	iptables-save > /etc/iptables/rules.v4
	check_crontab_installed
	crontab -l | grep -v 'iptables-restore' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot iptables-restore < /etc/iptables/rules.v4') | crontab - > /dev/null 2>&1

}




iptables_open() {
	install iptables
	save_iptables_rules
	iptables -P INPUT ACCEPT
	iptables -P FORWARD ACCEPT
	iptables -P OUTPUT ACCEPT
	iptables -F

	ip6tables -P INPUT ACCEPT
	ip6tables -P FORWARD ACCEPT
	ip6tables -P OUTPUT ACCEPT
	ip6tables -F

}



open_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "請提供至少一個端口號"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 刪除已存在的關閉規則
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 添加打開規則
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "已打開端口$port"
		fi
	done

	save_iptables_rules
	send_stats "已打開端口"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "請提供至少一個端口號"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 刪除已存在的打開規則
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 添加關閉規則
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "已關閉端口$port"
		fi
	done

	# 刪除已存在的規則（如果有）
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 插入新規則到第一條
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "已關閉端口"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "請提供至少一個IP地址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 刪除已存在的阻止規則
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 添加允許規則
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "已放行IP$ip"
		fi
	done

	save_iptables_rules
	send_stats "已放行IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "請提供至少一個IP地址或IP段"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 刪除已存在的允許規則
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 添加阻止規則
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "已阻止IP$ip"
		fi
	done

	save_iptables_rules
	send_stats "已阻止IP"
}







enable_ddos_defense() {
	# 開啟防禦 DDoS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "開啟DDoS防禦"
}

# 關閉DDoS防禦
disable_ddos_defense() {
	# 關閉防禦 DDoS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "關閉DDoS防禦"
}





# 管理國家IP規則的函數
manage_country_rules() {
	local action="$1"
	shift  # 去掉第一个参数，剩下的全是国家代码

	install ipset

	for country_code in "$@"; do
		local ipset_name="${country_code,,}_block"
		local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

		case "$action" in
			block)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "錯誤：下載$country_code的 IP 區域文件失敗"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "已成功阻止$country_code的 IP 地址"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "錯誤：下載$country_code的 IP 區域文件失敗"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "已成功允許$country_code的 IP 地址"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "已成功解除$country_code的 IP 地址限制"
				;;

			*)
				echo "用法: manage_country_rules {block|allow|unblock} <country_code...>"
				;;
		esac
	done
}










iptables_panel() {
  root_use
  install iptables
  save_iptables_rules
  while true; do
		  clear
		  echo "高級防火牆管理"
		  send_stats "高級防火牆管理"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "防火牆管理"
		  echo "------------------------"
		  echo "1.  開放指定端口                 2.  關閉指定端口"
		  echo "3.  開放所有端口                 4.  關閉所有端口"
		  echo "------------------------"
		  echo "5.  IP白名單                  	 6.  IP黑名單"
		  echo "7.  清除指定IP"
		  echo "------------------------"
		  echo "11. 允許PING                  	 12. 禁止PING"
		  echo "------------------------"
		  echo "13. 啟動DDOS防禦                 14. 關閉DDOS防禦"
		  echo "------------------------"
		  echo "15. 阻止指定國家IP               16. 僅允許指定國家IP"
		  echo "17. 解除指定國家IP限制"
		  echo "------------------------"
		  echo "0. 返回上一級選單"
		  echo "------------------------"
		  read -e -p "請輸入你的選擇:" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "請輸入開放的端口號:" o_port
				  open_port $o_port
				  send_stats "開放指定端口"
				  ;;
			  2)
				  read -e -p "請輸入關閉的端口號:" c_port
				  close_port $c_port
				  send_stats "關閉指定端口"
				  ;;
			  3)
				  # 開放所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT ACCEPT
				  iptables -P FORWARD ACCEPT
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "開放所有端口"
				  ;;
			  4)
				  # 關閉所有端口
				  current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')
				  iptables -F
				  iptables -X
				  iptables -P INPUT DROP
				  iptables -P FORWARD DROP
				  iptables -P OUTPUT ACCEPT
				  iptables -A INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A OUTPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
				  iptables -A INPUT -i lo -j ACCEPT
				  iptables -A FORWARD -i lo -j ACCEPT
				  iptables -A INPUT -p tcp --dport $current_port -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "關閉所有端口"
				  ;;

			  5)
				  # IP 白名單
				  read -e -p "請輸入放行的IP或IP段:" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP 黑名單
				  read -e -p "請輸入封鎖的IP或IP段:" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 清除指定 IP
				  read -e -p "請輸入清除的IP:" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "清除指定IP"
				  ;;
			  11)
				  # 允許 PING
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "允許PING"
				  ;;
			  12)
				  # 禁用 PING
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "禁用PING"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "請輸入阻止的國家代碼（多個國家代碼可用空格隔開如 CN US JP）:" country_code
				  manage_country_rules block $country_code
				  send_stats "允許國家$country_code的IP"
				  ;;
			  16)
				  read -e -p "請輸入允許的國家代碼（多個國家代碼可用空格隔開如 CN US JP）:" country_code
				  manage_country_rules allow $country_code
				  send_stats "阻止國家$country_code的IP"
				  ;;

			  17)
				  read -e -p "請輸入清除的國家代碼（多個國家代碼可用空格隔開如 CN US JP）:" country_code
				  manage_country_rules unblock $country_code
				  send_stats "清除國家$country_code的IP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}






add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 獲取當前系統中所有的 swap 分區
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 遍歷並刪除所有的 swap 分區
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# 確保 /swapfile 不再被使用
	swapoff /swapfile

	# 刪除舊的 /swapfile
	rm -f /swapfile

	# 創建新的 swap 分區
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

	echo -e "虛擬內存大小已調整為${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 判斷是否需要創建虛擬內存
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # 獲取nginx版本
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # 獲取mysql版本
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # 獲取php版本
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # 獲取redis版本
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 創建必要的目錄和文件
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/stream.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf

  default_server_ssl

  # 下載 docker-compose.yml 文件並進行替換
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # 在 docker-compose.yml 文件中進行替換
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}


update_docker_compose_with_db_creds() {

  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

  if ! grep -q "stream" /home/web/docker-compose.yml; then
	wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml

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

}





auto_optimize_dns() {
	# 獲取國家代碼（如 CN、US 等）
	local country=$(curl -s ipinfo.io/country)

	# 根據國家設置 DNS
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


}


prefer_ipv4() {
grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null \
	|| echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
echo "已切換為 IPv4 優先"
send_stats "已切換為 IPv4 優先"
}




install_ldnmp() {

	  update_docker_compose_with_db_creds

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -

	  fix_phpfpm_conf php
	  fix_phpfpm_conf php74

	  # mysql調優
	  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
	  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
	  rm -rf /home/custom_mysql_config.cnf



	  restart_ldnmp
	  sleep 2

	  clear
	  echo "LDNMP環境安裝完畢"
	  echo "------------------------"
	  ldnmp_v

}


install_certbot() {

	cd ~
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/auto_cert_renewal.sh
	chmod +x auto_cert_renewal.sh

	check_crontab_installed
	local cron_job="0 0 * * * ~/auto_cert_renewal.sh"
	crontab -l 2>/dev/null | grep -vF "$cron_job" | crontab -
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "續簽任務已更新"
}









install_ssltls() {
	  check_port > /dev/null 2>&1
	  docker stop nginx > /dev/null 2>&1
	  cd ~

	  local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	  if [ ! -f "$file_path" ]; then
		 	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
			local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'
			if [[ ($yuming =~ $ipv4_pattern || $yuming =~ $ipv6_pattern) ]]; then
				mkdir -p /etc/letsencrypt/live/$yuming/
				if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
					openssl req -x509 -nodes -newkey ec -pkeyopt ec_paramgen_curve:prime256v1 -keyout /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				else
					openssl genpkey -algorithm Ed25519 -out /etc/letsencrypt/live/$yuming/privkey.pem
					openssl req -x509 -key /etc/letsencrypt/live/$yuming/privkey.pem -out /etc/letsencrypt/live/$yuming/fullchain.pem -days 5475 -subj "/C=US/ST=State/L=City/O=Organization/OU=Organizational Unit/CN=Common Name"
				fi
			else
				if ! iptables -C INPUT -p tcp --dport 80 -j ACCEPT 2>/dev/null; then
					iptables -I INPUT 1 -p tcp --dport 80 -j ACCEPT
				fi
				docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
			fi
	  fi
	  mkdir -p /home/web/certs/
	  cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
	  cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

	  docker start nginx > /dev/null 2>&1
}



install_ssltls_text() {
	echo -e "${gl_huang}$yuming公鑰信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming私鑰信息${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}證書存放路徑${gl_bai}"
	echo "公鑰: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "私鑰: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}快速申請SSL證書，過期前自動續簽${gl_bai}"
yuming="${1:-}"
if [ -z "$yuming" ]; then
	add_yuming
fi
install_docker
install_certbot
docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
install_ssltls
certs_status
install_ssltls_text
ssl_ps
}


ssl_ps() {
	echo -e "${gl_huang}已申請的證書到期情況${gl_bai}"
	echo "站點信息                      證書到期時間"
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
		send_stats "域名證書申請成功"
	else
		send_stats "域名證書申請失敗"
		echo -e "${gl_hong}注意:${gl_bai}證書申請失敗，請檢查以下可能原因並重試："
		echo -e "1. 域名拼寫錯誤 ➠ 請檢查域名輸入是否正確"
		echo -e "2. DNS解析問題 ➠ 確認域名已正確解析到本服務器IP"
		echo -e "3. 網絡配置問題 ➠ 如使用Cloudflare Warp等虛擬網絡請暫時關閉"
		echo -e "4. 防火牆限制 ➠ 檢查80/443端口是否開放，確保驗證可訪問"
		echo -e "5. 申請次數超限 ➠ Let's Encrypt有每週限額(5次/域名/週)"
		echo -e "6. 國內備案限制 ➠ 中國大陸環境請確認域名是否備案"
		echo "------------------------"
		echo "1. 重新申請        2. 導入已有證書        3. 不帶證書改用HTTP訪問        0. 退出"
		echo "------------------------"
		read -e -p "請輸入你的選擇:" sub_choice
		case $sub_choice in
	  	  1)
	  	  	send_stats "重新申請"
		  	echo "請再次嘗試部署$webname"
		  	add_yuming
		  	install_ssltls
		  	certs_status

	  		  ;;
	  	  2)
	  	  	send_stats "導入已有證書"

			# 定義文件路徑
			local cert_file="/home/web/certs/${yuming}_cert.pem"
			local key_file="/home/web/certs/${yuming}_key.pem"

			mkdir -p /home/web/certs

			# 1. 輸入證書 (ECC 和 RSA 證書開頭都是 BEGIN CERTIFICATE)
			echo "請粘貼 證書 (CRT/PEM) 內容 (按兩次回車結束)："
			local cert_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$cert_content" == *"-----BEGIN"* ]] && break
				cert_content+="${line}"$'\n'
			done

			# 2. 輸入私鑰 (兼容 RSA, ECC, PKCS#8)
			echo "請粘貼 證書私鑰 (Private Key) 內容 (按兩次回車結束)："
			local key_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$key_content" == *"-----BEGIN"* ]] && break
				key_content+="${line}"$'\n'
			done

			# 3. 智能校驗
			# 只要包含 "BEGIN CERTIFICATE" 和 "PRIVATE KEY" 即可通過
			if [[ "$cert_content" == *"-----BEGIN CERTIFICATE-----"* && "$key_content" == *"PRIVATE KEY-----"* ]]; then
				echo -n "$cert_content" > "$cert_file"
				echo -n "$key_content" > "$key_file"

				chmod 644 "$cert_file"
				chmod 600 "$key_file"

				# 識別當前證書類型並顯示
				if [[ "$key_content" == *"EC PRIVATE KEY"* ]]; then
					echo "檢測到 ECC 證書已成功保存。"
				else
					echo "檢測到 RSA 證書已成功保存。"
				fi
				auth_method="ssl_imported"
			else
				echo "錯誤：無效的證書或私鑰格式！"
				certs_status
			fi

	  		  ;;
	  	  3)
	  	  	send_stats "不帶證書改用HTTP訪問"
		  	sed -i '/if (\$scheme = http) {/,/}/s/^/#/' /home/web/conf.d/${yuming}.conf
			sed -i '/ssl_certificate/d; /ssl_certificate_key/d' /home/web/conf.d/${yuming}.conf
			sed -i '/443 ssl/d; /443 quic/d' /home/web/conf.d/${yuming}.conf
	  		  ;;
	  	  *)
	  	  	send_stats "退出申請"
			exit
	  		  ;;
		esac
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "域名重複使用"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "先將域名解析到本機IP:${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "請輸入你的IP或者解析過的域名:" yuming
}


check_ip_and_get_access_port() {
	local yuming="$1"

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
		read -e -p "請輸入訪問/監聽端口，回車默認使用 80:" access_port
		access_port=${access_port:-80}
	fi
}



update_nginx_listen_port() {
	local yuming="$1"
	local access_port="$2"
	local conf="/home/web/conf.d/${yuming}.conf"

	# 如果 access_port 為空，則跳過
	[ -z "$access_port" ] && return 0

	# 刪除所有 listen 行
	sed -i '/^[[:space:]]*listen[[:space:]]\+/d' "$conf"

	# 在 server { 後插入新的 l​​isten
	sed -i "/server {/a\\
	listen ${access_port};\\
	listen [::]:${access_port};
" "$conf"
}



add_db() {
	  dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
	  dbname="${dbname}"

	  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbuse=$(grep -oP 'MYSQL_USER:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  dbusepasswd=$(grep -oP 'MYSQL_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  docker exec mysql mysql -u root -p"$dbrootpasswd" -e "CREATE DATABASE $dbname; GRANT ALL PRIVILEGES ON $dbname.* TO \"$dbuse\"@\"%\";"
}


restart_ldnmp() {
	  docker exec nginx chown -R nginx:nginx /var/www/html > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx mkdir -p /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/proxy > /dev/null 2>&1
	  docker exec nginx chown -R nginx:nginx /var/cache/nginx/fastcgi > /dev/null 2>&1
	  docker exec php chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  docker exec php74 chown -R www-data:www-data /var/www/html > /dev/null 2>&1
	  cd /home/web && docker compose restart


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
  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
  docker compose -f docker-compose.phpmyadmin.yml up -d
  clear
  ip_address

  check_docker_app_ip
  echo "登錄信息:"
  echo "使用者名稱:$dbuse"
  echo "密碼:$dbusepasswd"
  echo
  send_stats "啟動$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 檢查配置文件是否存在
  if [ -f "$CONFIG_FILE" ]; then
	# 從配置文件讀取 API_TOKEN 和 zone_id
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# 將 ZONE_IDS 轉換為數組
	ZONE_IDS=($ZONE_IDS)
  else
	# 提示用戶是否清理緩存
	read -e -p "需要清理 Cloudflare 的緩存嗎？ （y/n）:" answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF信息保存在$CONFIG_FILE，可以後期修改CF信息"
	  read -e -p "請輸入你的 API_TOKEN:" API_TOKEN
	  read -e -p "請輸入你的CF用戶名:" EMAIL
	  read -e -p "請輸入 zone_id（多個用空格分隔）:" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 循環遍歷每個 zone_id 並執行清除緩存命令
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "正在清除緩存 for zone_id:$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "緩存清除請求已發送完畢。"
}



web_cache() {
  send_stats "清理站點緩存"
  cf_purge_cache
  cd /home/web && docker compose restart
}



web_del() {

	send_stats "刪除站點數據"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "刪除站點數據，請輸入你的域名（多個域名用空格隔開）:" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "正在刪除域名:$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# 將域名轉換為數據庫名
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 刪除數據庫前檢查是否存在，避免報錯
		echo "正在刪除數據庫:$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 根據 mode 參數來決定開啟或關閉 WAF
	if [ "$mode" == "on" ]; then
		# 開啟 WAF：去掉註釋
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# 關閉 WAF：加上註釋
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	# 檢查 nginx 鏡像並根據情況處理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi

}

check_waf_status() {
	if grep -q "^\s*#\s*modsecurity on;" /home/web/nginx.conf; then
		waf_status=""
	elif grep -q "modsecurity on;" /home/web/nginx.conf; then
		waf_status="WAF已開啟"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/etc/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage="cf模式已開啟"
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


patch_wp_memory_limit() {
  local MEMORY_LIMIT="${1:-256M}"      # 第一个参数，默认256M
  local MAX_MEMORY_LIMIT="${2:-256M}"  # 第二个参数，默认256M
  local TARGET_DIR="/home/web/html"    # 路径写死

  find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
	# 刪除舊定義
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# 插入新定義，放在含 "Happy publishing" 的行前
	awk -v insert="define('WP_MEMORY_LIMIT', '$MEMORY_LIMIT');\ndefine('WP_MAX_MEMORY_LIMIT', '$MAX_MEMORY_LIMIT');" \
	'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Replaced WP_MEMORY_LIMIT in $FILE"
  done
}




patch_wp_debug() {
  local DEBUG="${1:-false}"           # 第一个参数，默认false
  local DEBUG_DISPLAY="${2:-false}"   # 第二个参数，默认false
  local DEBUG_LOG="${3:-false}"       # 第三个参数，默认false
  local TARGET_DIR="/home/web/html"   # 路径写死

  find "$TARGET_DIR" -type f -name "wp-config.php" | while read -r FILE; do
	# 刪除舊定義
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# 插入新定義，放在含 "Happy publishing" 的行前
	awk -v insert="define('WP_DEBUG_DISPLAY', $DEBUG_DISPLAY);\ndefine('WP_DEBUG_LOG', $DEBUG_LOG);" \
	'
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Replaced WP_DEBUG settings in $FILE"
  done
}




patch_wp_url() {
  local HOME_URL="$1"
  local SITE_URL="$2"
  local TARGET_DIR="/home/web/html"

  find "$TARGET_DIR" -type f -name "wp-config-sample.php" | while read -r FILE; do
	# 刪除舊定義
	sed -i "/define(['\"]WP_HOME['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_SITEURL['\"].*/d" "$FILE"

	# 生成插入內容
	INSERT="
define('WP_HOME', '$HOME_URL');
define('WP_SITEURL', '$SITE_URL');
"

	# 插入到 “Happy publishing” 之前
	awk -v insert="$INSERT" '
	  /Happy publishing/ {
		print insert
	  }
	  { print }
	' "$FILE" > "$FILE.tmp" && mv -f "$FILE.tmp" "$FILE"

	echo "[+] Updated WP_HOME and WP_SITEURL in $FILE"
  done
}








nginx_br() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 開啟 Brotli：去掉註釋
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)# brotli on;|\1brotli on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_static on;|\1brotli_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_comp_level \(.*\);|\1brotli_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_buffers \(.*\);|\1brotli_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_min_length \(.*\);|\1brotli_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_window \(.*\);|\1brotli_window \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# brotli_types \(.*\);|\1brotli_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/brotli_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf

	elif [ "$mode" == "off" ]; then
		# 關閉 Brotli：加上註釋
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|# load_module /etc/nginx/modules/ngx_http_brotli_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)brotli on;|\1# brotli on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_static on;|\1# brotli_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_comp_level \(.*\);|\1# brotli_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_buffers \(.*\);|\1# brotli_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_min_length \(.*\);|\1# brotli_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_window \(.*\);|\1# brotli_window \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)brotli_types \(.*\);|\1# brotli_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/brotli_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf

	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	# 檢查 nginx 鏡像並根據情況處理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi


}



nginx_zstd() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# 開啟 Zstd：去掉註釋
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)# zstd on;|\1zstd on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_static on;|\1zstd_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_comp_level \(.*\);|\1zstd_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_buffers \(.*\);|\1zstd_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_min_length \(.*\);|\1zstd_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# zstd_types \(.*\);|\1zstd_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/zstd_types/,+6 s/^\(\s*\)#\s*/\1/' /home/web/nginx.conf



	elif [ "$mode" == "off" ]; then
		# 關閉 Zstd：加上註釋
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_filter_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|# load_module /etc/nginx/modules/ngx_http_zstd_static_module.so;|' /home/web/nginx.conf > /dev/null 2>&1

		sed -i 's|^\(\s*\)zstd on;|\1# zstd on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_static on;|\1# zstd_static on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_comp_level \(.*\);|\1# zstd_comp_level \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_buffers \(.*\);|\1# zstd_buffers \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_min_length \(.*\);|\1# zstd_min_length \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)zstd_types \(.*\);|\1# zstd_types \2;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i '/zstd_types/,+6 {
			/^[[:space:]]*[^#[:space:]]/ s/^\(\s*\)/\1# /
		}' /home/web/nginx.conf


	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	# 檢查 nginx 鏡像並根據情況處理
	if grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		docker exec nginx nginx -s reload
	else
		sed -i 's|nginx:alpine|kjlion/nginx:alpine|g' /home/web/docker-compose.yml
		nginx_upgrade
	fi



}








nginx_gzip() {

	local mode=$1
	if [ "$mode" == "on" ]; then
		sed -i 's|^\(\s*\)# gzip on;|\1gzip on;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		sed -i 's|^\(\s*\)gzip on;|\1# gzip on;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "無效的參數：使用 'on' 或 'off'"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP環境防禦"
	  while true; do
		check_f2b_status
		check_waf_status
		check_cf_mode
			  clear
			  echo -e "服務器網站防禦程序${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 安裝防禦程序"
			  echo "------------------------"
			  echo "5. 查看SSH攔截記錄                6. 查看網站攔截記錄"
			  echo "7. 查看防禦規則列表               8. 查看日誌實時監控"
			  echo "------------------------"
			  echo "11. 配置攔截參數                  12. 清除所有拉黑的IP"
			  echo "------------------------"
			  echo "21. cloudflare模式                22. 高負載開啟5秒盾"
			  echo "------------------------"
			  echo "31. 開啟WAF                       32. 關閉WAF"
			  echo "33. 開啟DDOS防禦                  34. 關閉DDOS防禦"
			  echo "------------------------"
			  echo "9. 卸載防禦程序"
			  echo "------------------------"
			  echo "0. 返回上一級選單"
			  echo "------------------------"
			  read -e -p "請輸入你的選擇:" sub_choice
			  case $sub_choice in
				  1)
					  f2b_install_sshd
					  cd /etc/fail2ban/filter.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-418.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-deny.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-unauthorized.conf
					  wget ${gh_proxy}https://raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-bad-request.conf

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf
					  sed -i "/cloudflare/d" /etc/fail2ban/jail.d/nginx-docker-cc.conf
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
					  local xxx="nginx-418"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-bad-request"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-badbots"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-botsearch"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-deny"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-http-auth"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="nginx-unauthorized"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="php-url-fopen"
					  f2b_status_xxx
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
					  rm -rf /etc/fail2ban
					  crontab -l | grep -v "CF-Under-Attack.sh" | crontab - 2>/dev/null
					  echo "Fail2Ban防禦程序已卸載"
					  break
					  ;;

				  11)
					  install nano
					  nano /etc/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  break
					  ;;

				  12)
					  fail2ban-client unban --all
					  ;;

				  21)
					  send_stats "cloudflare模式"
					  echo "到cf後台右上角我的個人資料，選擇左側API令牌，獲取Global API Key"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "輸入CF的賬號:" cfuser
					  read -e -p "輸入CF的Global API Key:" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /etc/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "已配置cloudflare模式，可在cf後台，站點-安全性-事件中查看攔截記錄"
					  ;;

				  22)
					  send_stats "高負載開啟5秒盾"
					  echo -e "${gl_huang}網站每5分鐘自動檢測，當達檢測到高負載會自動開盾，低負載也會自動關閉5秒盾。${gl_bai}"
					  echo "--------------"
					  echo "獲取CF參數:"
					  echo -e "到cf後台右上角我的個人資料，選擇左側API令牌，獲取${gl_huang}Global API Key${gl_bai}"
					  echo -e "到cf後台域名概要頁面右下方獲取${gl_huang}區域ID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "輸入CF的賬號:" cfuser
					  read -e -p "輸入CF的Global API Key:" cftoken
					  read -e -p "輸入CF中域名的區域ID:" cfzonID

					  cd ~
					  install jq bc
					  check_crontab_installed
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/CF-Under-Attack.sh
					  chmod +x CF-Under-Attack.sh
					  sed -i "s/AAAA/$cfuser/g" ~/CF-Under-Attack.sh
					  sed -i "s/BBBB/$cftoken/g" ~/CF-Under-Attack.sh
					  sed -i "s/CCCC/$cfzonID/g" ~/CF-Under-Attack.sh

					  local cron_job="*/5 * * * * ~/CF-Under-Attack.sh"

					  local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

					  if [ -z "$existing_cron" ]; then
						  (crontab -l 2>/dev/null; echo "$cron_job") | crontab -
						  echo "高負載自動開盾腳本已添加"
					  else
						  echo "自動開盾腳本已存在，無需添加"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "站點WAF已開啟"
					  send_stats "站點WAF已開啟"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "站點WAF已關閉"
					  send_stats "站點WAF已關閉"
					  ;;

				  33)
					  enable_ddos_defense
					  ;;

				  34)
					  disable_ddos_defense
					  ;;

				  *)
					  break
					  ;;
			  esac
	  break_end
	  done
}



check_ldnmp_mode() {

	local MYSQL_CONTAINER="mysql"
	local MYSQL_CONF="/etc/mysql/conf.d/custom_mysql_config.cnf"

	# 檢查 MySQL 配置文件中是否包含 4096M
	if docker exec "$MYSQL_CONTAINER" grep -q "4096M" "$MYSQL_CONF" 2>/dev/null; then
		mode_info="高性能模式"
	else
		mode_info="標準模式"
	fi



}


check_nginx_compression() {

	local CONFIG_FILE="/home/web/nginx.conf"

	# 檢查 zstd 是否開啟且未被註釋（整行以 zstd on; 開頭）
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status="zstd壓縮已開啟"
	else
		zstd_status=""
	fi

	# 檢查 brotli 是否開啟且未被註釋
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status="br壓縮已開啟"
	else
		br_status=""
	fi

	# 檢查 gzip 是否開啟且未被註釋
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status="gzip壓縮已開啟"
	else
		gzip_status=""
	fi
}




web_optimization() {
		  while true; do
		  	  check_ldnmp_mode
			  check_nginx_compression
			  clear
			  send_stats "優化LDNMP環境"
			  echo -e "優化LDNMP環境${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 標準模式              2. 高性能模式 (推薦2H4G以上)"
			  echo "------------------------"
			  echo "3. 開啟gzip壓縮          4. 關閉gzip壓縮"
			  echo "5. 開啟br壓縮            6. 關閉br壓縮"
			  echo "7. 開啟zstd壓縮          8. 關閉zstd壓縮"
			  echo "------------------------"
			  echo "0. 返回上一級選單"
			  echo "------------------------"
			  read -e -p "請輸入你的選擇:" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "站點標準模式"

				  local cpu_cores=$(nproc)
				  local connections=$((1024 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf


				  # php調優
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php調優
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql調優
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  optimize_balanced


				  echo "LDNMP環境已設置成 標準模式"

					  ;;
				  2)
				  send_stats "站點高性能模式"

				  # nginx調優
				  local cpu_cores=$(nproc)
				  local connections=$((2048 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf

				  # php調優
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php調優
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit 512M 512M
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql調優
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  optimize_web_server

				  echo "LDNMP環境已設置成 高性能模式"

					  ;;
				  3)
				  send_stats "nginx_gzip on"
				  nginx_gzip on
					  ;;
				  4)
				  send_stats "nginx_gzip off"
				  nginx_gzip off
					  ;;
				  5)
				  send_stats "nginx_br on"
				  nginx_br on
					  ;;
				  6)
				  send_stats "nginx_br off"
				  nginx_br off
					  ;;
				  7)
				  send_stats "nginx_zstd on"
				  nginx_zstd on
					  ;;
				  8)
				  send_stats "nginx_zstd off"
				  nginx_zstd off
					  ;;
				  *)
					  break
					  ;;
			  esac
			  break_end

		  done


}










check_docker_app() {
	if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name" ; then
		check_docker="${gl_lv}已安裝${gl_bai}"
	else
		check_docker="${gl_hui}未安裝${gl_bai}"
	fi
}



# check_docker_app() {

# if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
# check_docker="${gl_lv}已安裝${gl_bai}"
# else
# check_docker="${gl_hui}未安裝${gl_bai}"
# fi

# }


check_docker_app_ip() {
echo "------------------------"
echo "訪問地址:"
ip_address



if [ -n "$ipv4_address" ]; then
	echo "http://$ipv4_address:${docker_port}"
fi

if [ -n "$ipv6_address" ]; then
	echo "http://[$ipv6_address]:${docker_port}"
fi

local search_pattern1="$ipv4_address:${docker_port}"
local search_pattern2="127.0.0.1:${docker_port}"

for file in /home/web/conf.d/*; do
	if [ -f "$file" ]; then
		if grep -q "$search_pattern1" "$file" 2>/dev/null || grep -q "$search_pattern2" "$file" 2>/dev/null; then
			echo "https://$(basename "$file" | sed 's/\.conf$//')"
		fi
	fi
done


}


check_docker_image_update() {
	local container_name=$1
	update_status=""

	# 1. 區域檢查
	local country=$(curl -s --max-time 2 ipinfo.io/country)
	[[ "$country" == "CN" ]] && return

	# 2. 獲取本地鏡像信息
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	[[ -z "$container_info" ]] && return

	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local full_image_name=$(echo "$container_info" | cut -d',' -f2)
	local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)

	# 3. 智能路由判斷
	if [[ "$full_image_name" == ghcr.io* ]]; then
		# --- 場景 A: 鏡像在 GitHub (ghcr.io) ---
		# 提取倉庫路徑，例如 ghcr.io/onexru/oneimg -> onexru/oneimg
		local repo_path=$(echo "$full_image_name" | sed 's/ghcr.io\///' | cut -d':' -f1)
		# 注意：ghcr.io 的 API 比較複雜，通常最快的方法是查 GitHub Repo 的 Release
		local api_url="https://api.github.com/repos/$repo_path/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	elif [[ "$full_image_name" == *"oneimg"* ]]; then
		# --- 場景 B: 特殊指定 (即便在 Docker Hub，也想通過 GitHub Release 判斷) ---
		local api_url="https://api.github.com/repos/onexru/oneimg/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	else
		# --- 場景 C: 標準 Docker Hub ---
		local image_repo=${full_image_name%%:*}
		local image_tag=${full_image_name##*:}
		[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"
		[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

		local api_url="https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag"
		local remote_date=$(curl -s "$api_url" | jq -r '.last_updated' 2>/dev/null)
	fi

	# 4. 時間戳對比
	if [[ -n "$remote_date" && "$remote_date" != "null" ]]; then
		local remote_ts=$(date -d "$remote_date" +%s 2>/dev/null)
		if [[ $container_created_ts -lt $remote_ts ]]; then
			update_status="${gl_huang}發現新版本!${gl_bai}"
		fi
	fi
}







block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 獲取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 檢查並封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 檢查並放行指定 IP
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 檢查並放行本地網絡 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# 檢查並封禁其他所有 IP
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 檢查並放行指定 IP
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 檢查並放行本地網絡 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "已阻止IP+端口訪問該服務"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 獲取容器的 IP 地址
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 清除封禁其他所有 IP 的規則
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的規則
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地網絡 127.0.0.0/8 的規則
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# 清除封禁其他所有 IP 的規則
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 清除放行指定 IP 的規則
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 清除放行本地網絡 127.0.0.0/8 的規則
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "已允許IP+端口訪問該服務"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "錯誤：請提供端口號和允許訪問的 IP。"
		echo "用法: block_host_port <端口號> <允許的IP>"
		return 1
	fi

	install iptables


	# 拒絕其他所有 IP 訪問
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 允許指定 IP 訪問
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允許本機訪問
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 拒絕其他所有 IP 訪問
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 允許指定 IP 訪問
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 允許本機訪問
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 允許已建立和相關連接的流量
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "已阻止IP+端口訪問該服務"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "錯誤：請提供端口號和允許訪問的 IP。"
		echo "用法: clear_host_port_rules <端口號> <允許的IP>"
		return 1
	fi

	install iptables


	# 清除封禁所有其他 IP 訪問的規則
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# 清除允許本機訪問的規則
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允許指定 IP 訪問的規則
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 清除封禁所有其他 IP 訪問的規則
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# 清除允許本機訪問的規則
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 清除允許指定 IP 訪問的規則
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "已允許IP+端口訪問該服務"
	save_iptables_rules

}



setup_docker_dir() {

	mkdir -p /home /home/docker 2>/dev/null

	if [ -d "/vol1/1000/" ] && [ ! -d "/vol1/1000/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /vol1/1000/docker 2>/dev/null
		ln -s /vol1/1000/docker /home/docker 2>/dev/null
	fi

	if [ -d "/volume1/" ] && [ ! -d "/volume1/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /volume1/docker 2>/dev/null
		ln -s /volume1/docker /home/docker 2>/dev/null
	fi


}


add_app_id() {
mkdir -p /home/docker
touch /home/docker/appno.txt
grep -qxF "${app_id}" /home/docker/appno.txt || echo "${app_id}" >> /home/docker/appno.txt

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
	if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
		if [ ! -f "/home/docker/${docker_name}_port.conf" ]; then
			local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
			docker_port=${docker_port:-0000}
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"
		fi
		local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
		check_docker_app_ip
	fi
	echo ""
	echo "------------------------"
	echo "1. 安裝              2. 更新            3. 卸載"
	echo "------------------------"
	echo "5. 添加域名訪問      6. 刪除域名訪問"
	echo "7. 允許IP+端口訪問   8. 阻止IP+端口訪問"
	echo "------------------------"
	echo "0. 返回上一級選單"
	echo "------------------------"
	read -e -p "請輸入你的選擇:" choice
	 case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "輸入應用對外服務端口，回車默認使用${docker_port}端口:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_name已經安裝完成"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "安裝$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum

			add_app_id

			clear
			echo "$docker_name已經安裝完成"
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
			rm -f /home/docker/${docker_name}_port.conf

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "應用已卸載"
			send_stats "解除安裝$docker_name"
			;;

		5)
			echo "${docker_name}域名訪問設置"
			send_stats "${docker_name}域名訪問設置"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "域名格式 example.com 不帶https://"
			web_del
			;;

		7)
			send_stats "允許IP訪問${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "阻止IP訪問${docker_name}"
			block_container_port "$docker_name" "$ipv4_address"
			;;

		*)
			break
			;;
	 esac
	 break_end
done

}





docker_app_plus() {
	send_stats "$app_name"
	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "$app_name $check_docker $update_status"
		echo "$app_text"
		echo "$app_url"
		if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
			if [ ! -f "/home/docker/${docker_name}_port.conf" ]; then
				local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
				docker_port=${docker_port:-0000}
				echo "$docker_port" > "/home/docker/${docker_name}_port.conf"
			fi
			local docker_port=$(cat "/home/docker/${docker_name}_port.conf")
			check_docker_app_ip
		fi
		echo ""
		echo "------------------------"
		echo "1. 安裝             2. 更新             3. 卸載"
		echo "------------------------"
		echo "5. 添加域名訪問     6. 刪除域名訪問"
		echo "7. 允許IP+端口訪問  8. 阻止IP+端口訪問"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		read -e -p "輸入你的選擇:" choice
		case $choice in
			1)
				setup_docker_dir
				check_disk_space $app_size /home/docker
				read -e -p "輸入應用對外服務端口，回車默認使用${docker_port}端口:" app_port
				local app_port=${app_port:-${docker_port}}
				local docker_port=$app_port
				install jq
				install_docker
				docker_app_install
				echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

				add_app_id
				send_stats "$app_name安裝"
				;;

			2)
				docker_app_update
				add_app_id
				send_stats "$app_name更新"
				;;

			3)
				docker_app_uninstall
				rm -f /home/docker/${docker_name}_port.conf

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				send_stats "$app_name解除安裝"
				;;

			5)
				echo "${docker_name}域名訪問設置"
				send_stats "${docker_name}域名訪問設置"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"

				;;
			6)
				echo "域名格式 example.com 不帶https://"
				web_del
				;;
			7)
				send_stats "允許IP訪問${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "阻止IP訪問${docker_name}"
				block_container_port "$docker_name" "$ipv4_address"
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
	curl -o "$PROMETHEUS_DIR/prometheus.yml" ${gh_proxy}raw.githubusercontent.com/kejilion/config/refs/heads/main/prometheus/prometheus.yml
fi

# Create Docker network for monitoring
docker network create $NETWORK_NAME

# Run Node Exporter container
docker run -d \
  --name=node-exporter \
  --network $NETWORK_NAME \
  --restart=always \
  prom/node-exporter

# Run Prometheus container
docker run -d \
  --name prometheus \
  -v $PROMETHEUS_DIR/prometheus.yml:/etc/prometheus/prometheus.yml \
  -v $PROMETHEUS_DIR/data:/prometheus \
  --network $NETWORK_NAME \
  --restart=always \
  --user 0:0 \
  prom/prometheus:latest

# Run Grafana container
docker run -d \
  --name grafana \
  -p ${docker_port}:3000 \
  -v $GRAFANA_DIR:/var/lib/grafana \
  --network $NETWORK_NAME \
  --restart=always \
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

# 檢查會話是否存在的函數
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 循環直到找到一個不存在的會話名稱
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 創建新的 tmux 會話
tmux new -d -s "$base_name-$tmuxd_ID" "$tmuxd"


}



f2b_status() {
	 fail2ban-client reload
	 sleep 3
	 fail2ban-client status
}

f2b_status_xxx() {
	fail2ban-client status $xxx
}

check_f2b_status() {
	if command -v fail2ban-client >/dev/null 2>&1; then
		check_f2b_status="${gl_lv}已安裝${gl_bai}"
	else
		check_f2b_status="${gl_hui}未安裝${gl_bai}"
	fi
}

f2b_install_sshd() {

	docker rm -f fail2ban >/dev/null 2>&1
	install fail2ban
	start fail2ban
	enable fail2ban

	if command -v dnf &>/dev/null; then
		cd /etc/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf
	fi

	if command -v apt &>/dev/null; then
		install rsyslog
		systemctl start rsyslog
		systemctl enable rsyslog
	fi

}

f2b_sshd() {
	if grep -q 'Alpine' /etc/issue; then
		xxx=alpine-sshd
		f2b_status_xxx
	else
		xxx=sshd
		f2b_status_xxx
	fi
}




server_reboot() {

	read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}现在重启服务器吗？(Y/N): ")" rboot
	case "$rboot" in
	  [Yy])
		echo "已重啟"
		reboot
		;;
	  *)
		echo "已取消"
		;;
	esac


}





output_status() {
	output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
		$1 ~ /^(eth|ens|enp|eno)[0-9]+/ {
			rx_total += $2
			tx_total += $10
		}
		END {
			rx_units = "Bytes";
			tx_units = "Bytes";
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "K"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "M"; }
			if (rx_total > 1024) { rx_total /= 1024; rx_units = "G"; }

			if (tx_total > 1024) { tx_total /= 1024; tx_units = "K"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "M"; }
			if (tx_total > 1024) { tx_total /= 1024; tx_units = "G"; }

			printf("%.2f%s %.2f%s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)

	rx=$(echo "$output" | awk '{print $1}')
	tx=$(echo "$output" | awk '{print $2}')

}




ldnmp_install_status_one() {

   if docker inspect "php" &>/dev/null; then
	clear
	send_stats "無法再次安裝LDNMP環境"
	echo -e "${gl_huang}提示:${gl_bai}建站環境已安裝。無需再次安裝！"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "安裝LDNMP環境"
root_use
clear
echo -e "${gl_huang}LDNMP環境未安裝，開始安裝LDNMP環境...${gl_bai}"
check_disk_space 3 /home
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "安裝nginx環境"
root_use
clear
echo -e "${gl_huang}nginx未安裝，開始安裝nginx環境...${gl_bai}"
check_disk_space 1 /home
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "nginx已安裝完成"
echo -e "當前版本:${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "請先安裝LDNMP環境"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "請先安裝nginx環境"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "您的$webname搭建好了！"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webname安裝信息如下:"

}

nginx_web_on() {
	clear

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	echo "您的$webname搭建好了！"

	if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
		mv /home/web/conf.d/"$yuming".conf /home/web/conf.d/"${yuming}_${access_port}".conf
		echo "http://$yuming:$access_port"
	elif grep -q '^[[:space:]]*#.*if (\$scheme = http)' "/home/web/conf.d/"$yuming".conf"; then
		echo "http://$yuming"
	else
		echo "https://$yuming"
	fi
}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "安裝$webname"
  echo "開始部署$webname"
  if [ -z "$yuming" ]; then
	add_yuming
  fi
  repeat_add_yuming
  ldnmp_install_status

  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
  nginx_http_on

  install_ssltls
  certs_status
  add_db

  cd /home/web/html
  mkdir $yuming
  cd $yuming
  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip
  unzip latest.zip
  rm latest.zip
  echo "define('FS_METHOD', 'direct'); define('WP_REDIS_HOST', 'redis'); define('WP_REDIS_PORT', '6379'); define('WP_REDIS_MAXTTL', 86400); define('WP_CACHE_KEY_SALT', '${yuming}_');" >> /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|database_name_here|$dbname|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|username_here|$dbuse|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|password_here|$dbusepasswd|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  sed -i "s|localhost|mysql|g" /home/web/html/$yuming/wordpress/wp-config-sample.php
  patch_wp_url "https://$yuming" "https://$yuming"
  cp /home/web/html/$yuming/wordpress/wp-config-sample.php /home/web/html/$yuming/wordpress/wp-config.php


  restart_ldnmp
  nginx_web_on

}



ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "安裝$webname"
	echo "開始部署$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy" ]; then
		read -e -p "請輸入你的反代IP (回車默認本機IP 127.0.0.1):" reverseproxy
		reverseproxy=${reverseproxy:-127.0.0.1}
	fi

	if [ -z "$port" ]; then
		read -e -p "請輸入你的反代端口:" port
	fi
	nginx_install_status

	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	install_ssltls
	certs_status


	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	reverseproxy_port="$reverseproxy:$port"
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 動態添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf
	sed -i '/remote_addr/d' /home/web/conf.d/$yuming.conf

	update_nginx_listen_port "$yuming" "$access_port"

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}



ldnmp_Proxy_backend() {
	clear
	webname="反向代理-負載均衡"

	send_stats "安裝$webname"
	echo "開始部署$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "請輸入你的多個反代IP+端口用空格隔開（例如 127.0.0.1:3000 127.0.0.1:3002）：" reverseproxy_port
	fi

	nginx_install_status

	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf


	install_ssltls
	certs_status

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 動態添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf

	update_nginx_listen_port "$yuming" "$access_port"

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}






list_stream_services() {

	STREAM_DIR="/home/web/stream.d"
	printf "%-25s %-18s %-25s %-20s\n" "服務名" "通信類型" "本機地址" "後端地址"

	if [ -z "$(ls -A "$STREAM_DIR")" ]; then
		return
	fi

	for conf in "$STREAM_DIR"/*; do
		# 服務名取文件名
		service_name=$(basename "$conf" .conf)

		# 獲取 upstream 塊中的 server 後端 IP:端口
		backend=$(grep -Po '(?<=server )[^;]+' "$conf" | head -n1)

		# 獲取 listen 端口
		listen_port=$(grep -Po '(?<=listen )[^;]+' "$conf" | head -n1)

		# 默認本地 IP
		ip_address
		local_ip="$ipv4_address"

		# 獲取通信類型，優先從文件名後綴或內容判斷
		if grep -qi 'udp;' "$conf"; then
			proto="udp"
		else
			proto="tcp"
		fi

		# 拼接監聽 IP:端口
		local_addr="$local_ip:$listen_port"

		printf "%-22s %-14s %-21s %-20s\n" "$service_name" "$proto" "$local_addr" "$backend"
	done
}









stream_panel() {
	send_stats "Stream四層代理"
	local app_id="104"
	local docker_name="nginx"

	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "Stream四層代理轉發工具$check_docker $update_status"
		echo "NGINX Stream 是 NGINX 的 TCP/UDP 代理模塊，用於實現高性能的 傳輸層流量轉發和負載均衡。"
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. 安裝               2. 更新               3. 卸載"
		echo "------------------------"
		echo "4. 添加轉發服務       5. 修改轉發服務       6. 刪除轉發服務"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		read -e -p "輸入你的選擇:" choice
		case $choice in
			1)
				nginx_install_status
				add_app_id
				send_stats "安裝Stream四層代理"
				;;
			2)
				update_docker_compose_with_db_creds
				nginx_upgrade
				add_app_id
				send_stats "更新Stream四層代理"
				;;
			3)
				read -e -p "確定要刪除 nginx 容器嗎？這可能會影響網站功能！ (y/N):" confirm
				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					docker rm -f nginx
					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					send_stats "更新Stream四層代理"
					echo "nginx 容器已刪除。"
				else
					echo "操作已取消。"
				fi

				;;

			4)
				ldnmp_Proxy_backend_stream
				add_app_id
				send_stats "添加四層代理"
				;;
			5)
				send_stats "編輯轉發配置"
				read -e -p "請輸入你要編輯的服務名:" stream_name
				install nano
				nano /home/web/stream.d/$stream_name.conf
				docker restart nginx
				send_stats "修改四層代理"
				;;
			6)
				send_stats "刪除轉發配置"
				read -e -p "請輸入你要刪除的服務名:" stream_name
				rm /home/web/stream.d/$stream_name.conf > /dev/null 2>&1
				docker restart nginx
				send_stats "刪除四層代理"
				;;
			*)
				break
				;;
		esac
		break_end
	done
}



ldnmp_Proxy_backend_stream() {
	clear
	webname="Stream四層代理-負載均衡"

	send_stats "安裝$webname"
	echo "開始部署$webname"

	# 獲取代理名稱
	read -rp "請輸入代理轉發名稱 (如 mysql_proxy):" proxy_name
	if [ -z "$proxy_name" ]; then
		echo "名稱不能為空"; return 1
	fi

	# 獲取監聽端口
	read -rp "請輸入本機監聽端口 (如 3306):" listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "端口必須是數字"; return 1
	fi

	echo "請選擇協議類型："
	echo "1. TCP    2. UDP"
	read -rp "請輸入序號 [1-2]:" proto_choice

	case "$proto_choice" in
		1) proto="tcp"; listen_suffix="" ;;
		2) proto="udp"; listen_suffix=" udp" ;;
		*) echo "無效選擇"; return 1 ;;
	esac

	read -e -p "請輸入你的一個或者多個後端IP+端口用空格隔開（例如 10.13.0.2:3306 10.13.0.3:3306）：" reverseproxy_port

	nginx_install_status
	cd /home && mkdir -p web/stream.d
	grep -q '^[[:space:]]*stream[[:space:]]*{' /home/web/nginx.conf || echo -e '\nstream {\n    include /etc/nginx/stream.d/*.conf;\n}' | tee -a /home/web/nginx.conf
	wget -O /home/web/stream.d/$proxy_name.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend-stream.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/${proxy_name}_${backend}/g" /home/web/stream.d/"$proxy_name".conf
	sed -i "s|listen 80|listen $listen_port $listen_suffix|g" /home/web/stream.d/$proxy_name.conf
	sed -i "s|listen \[::\]:|listen [::]:${listen_port} ${listen_suffix}|g" "/home/web/stream.d/${proxy_name}.conf"

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 動態添加/$upstream_servers/g" /home/web/stream.d/$proxy_name.conf

	docker exec nginx nginx -s reload
	clear
	echo "您的$webname搭建好了！"
	echo "------------------------"
	echo "訪問地址:"
	ip_address
	if [ -n "$ipv4_address" ]; then
		echo "$ipv4_address:${listen_port}"
	fi
	if [ -n "$ipv6_address" ]; then
		echo "$ipv6_address:${listen_port}"
	fi
	echo ""
}





find_container_by_host_port() {
	port="$1"
	docker_name=$(docker ps --format '{{.ID}} {{.Names}}' | while read id name; do
		if docker port "$id" | grep -q ":$port"; then
			echo "$name"
			break
		fi
	done)
}




ldnmp_web_status() {
	root_use
	while true; do
		local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
		local output="${gl_lv}${cert_count}${gl_bai}"

		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
		local db_output="${gl_lv}${db_count}${gl_bai}"

		clear
		send_stats "LDNMP站點管理"
		echo "LDNMP環境"
		echo "------------------------"
		ldnmp_v

		echo -e "站點:${output}證書到期時間"
		echo -e "------------------------"
		for cert_file in /home/web/certs/*_cert.pem; do
		  local domain=$(basename "$cert_file" | sed 's/_cert.pem//')
		  if [ -n "$domain" ]; then
			local expire_date=$(openssl x509 -noout -enddate -in "$cert_file" | awk -F'=' '{print $2}')
			local formatted_date=$(date -d "$expire_date" '+%Y-%m-%d')
			printf "%-30s%s\n" "$domain" "$formatted_date"
		  fi
		done

		for conf_file in /home/web/conf.d/*_*.conf; do
		  [ -e "$conf_file" ] || continue
		  basename "$conf_file" .conf
		done

		for conf_file in /home/web/conf.d/*.conf; do
		  [ -e "$conf_file" ] || continue

		  filename=$(basename "$conf_file")

		  if [ "$filename" = "map.conf" ] || [ "$filename" = "default.conf" ]; then
			continue
		  fi

		  if ! grep -q "ssl_certificate" "$conf_file"; then
			basename "$conf_file" .conf
		  fi
		done

		echo "------------------------"
		echo ""
		echo -e "資料庫:${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "站點目錄"
		echo "------------------------"
		echo -e "數據${gl_hui}/home/web/html${gl_bai}證書${gl_hui}/home/web/certs${gl_bai}配置${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "操作"
		echo "------------------------"
		echo "1.  申請/更新域名證書               2.  克隆站點域名"
		echo "3.  清理站點緩存                    4.  創建關聯站點"
		echo "5.  查看訪問日誌                    6.  查看錯誤日誌"
		echo "7.  編輯全局配置                    8.  編輯站點配置"
		echo "9.  管理站點數據庫                  10. 查看站點分析報告"
		echo "------------------------"
		echo "20. 刪除指定站點數據"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		read -e -p "請輸入你的選擇:" sub_choice
		case $sub_choice in
			1)
				send_stats "申請域名證書"
				read -e -p "請輸入你的域名:" yuming
				install_certbot
				docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "克隆站點域名"
				read -e -p "請輸入舊域名:" oddyuming
				read -e -p "請輸入新域名:" yuming
				install_certbot
				install_ssltls
				certs_status


				add_db
				local odd_dbname=$(echo "$oddyuming" | sed -e 's/[^A-Za-z0-9]/_/g')
				local odd_dbname="${odd_dbname}"

				docker exec mysql mysqldump -u root -p"$dbrootpasswd" $odd_dbname | docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname

				local tables=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW TABLES;" | awk '{ if (NR>1) print $1 }')
				for table in $tables; do
					columns=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "SHOW COLUMNS FROM $table;" | awk '{ if (NR>1) print $1 }')
					for column in $columns; do
						docker exec mysql mysql -u root -p"$dbrootpasswd" -D $dbname -e "UPDATE $table SET $column = REPLACE($column, '$oddyuming', '$yuming') WHERE $column LIKE '%$oddyuming%';"
					done
				done

				# 網站目錄替換
				cp -r /home/web/html/$oddyuming /home/web/html/$yuming

				find /home/web/html/$yuming -type f -exec sed -i "s/$odd_dbname/$dbname/g" {} +
				find /home/web/html/$yuming -type f -exec sed -i "s/$oddyuming/$yuming/g" {} +

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf

				cd /home/web && docker compose restart

				;;


			3)
				web_cache
				;;
			4)
				send_stats "創建關聯站點"
				echo -e "為現有的站點再關聯一個新域名用於訪問"
				read -e -p "請輸入現有的域名:" oddyuming
				read -e -p "請輸入新域名:" yuming
				install_certbot
				install_ssltls
				certs_status

				cp /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s|server_name $oddyuming|server_name $yuming|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_cert.pem|/etc/nginx/certs/${yuming}_cert.pem|g" /home/web/conf.d/$yuming.conf
				sed -i "s|/etc/nginx/certs/${oddyuming}_key.pem|/etc/nginx/certs/${yuming}_key.pem|g" /home/web/conf.d/$yuming.conf

				docker exec nginx nginx -s reload

				;;
			5)
				send_stats "查看訪問日誌"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "查看錯誤日誌"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "編輯全局配置"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "編輯站點配置"
				read -e -p "編輯站點配置，請輸入你要編輯的域名:" yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "查看站點數據"
				install goaccess
				goaccess --log-format=COMBINED /home/web/log/nginx/access.log
				;;

			20)
				web_del
				docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null

				;;
			*)
				break  # 跳出循环，退出菜单
				;;
		esac
	done


}


check_panel_app() {
if $lujing > /dev/null 2>&1; then
	check_panel="${gl_lv}已安裝${gl_bai}"
else
	check_panel=""
fi
}



install_panel() {
send_stats "${panelname}管理"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname}是一款時下流行且強大的運維管理面板。"
	echo "官網介紹:$panelurl "

	echo ""
	echo "------------------------"
	echo "1. 安裝            2. 管理            3. 卸載"
	echo "------------------------"
	echo "0. 返回上一級選單"
	echo "------------------------"
	read -e -p "請輸入你的選擇:" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install

			add_app_id
			send_stats "${panelname}安裝"
			;;
		2)
			panel_app_manage

			add_app_id
			send_stats "${panelname}控制"

			;;
		3)
			panel_app_uninstall

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			send_stats "${panelname}解除安裝"
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
	check_frp="${gl_lv}已安裝${gl_bai}"
else
	check_frp="${gl_hui}未安裝${gl_bai}"
fi

}



donlond_frp() {
  role="$1"
  config_file="/home/frp/${role}.toml"

  docker run -d \
	--name "$role" \
	--restart=always \
	--network host \
	-v "$config_file":"/frp/${role}.toml" \
	kjlion/frp:alpine \
	"/frp/${role}" -c "/frp/${role}.toml"

}




generate_frps_config() {

	send_stats "安裝frp服務端"
	# 生成隨機端口和憑證
	local bind_port=8055
	local dashboard_port=8056
	local token=$(openssl rand -hex 16)
	local dashboard_user="user_$(openssl rand -hex 4)"
	local dashboard_pwd=$(openssl rand -hex 8)

	mkdir -p /home/frp
	touch /home/frp/frps.toml
	cat <<EOF > /home/frp/frps.toml
[common]
bind_port = $bind_port
authentication_method = token
token = $token
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
EOF

	donlond_frp frps

	# 輸出生成的信息
	ip_address
	echo "------------------------"
	echo "客戶端部署時需要用的參數"
	echo "服務IP:$ipv4_address"
	echo "token: $token"
	echo
	echo "FRP面板信息"
	echo "FRP面板地址: http://$ipv4_address:$dashboard_port"
	echo "FRP面板用戶名:$dashboard_user"
	echo "FRP面板密碼:$dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "安裝frp客戶端"
	read -e -p "請輸入外網對接IP:" server_addr
	read -e -p "請輸入外網對接token:" token
	echo

	mkdir -p /home/frp
	touch /home/frp/frpc.toml
	cat <<EOF > /home/frp/frpc.toml
[common]
server_addr = ${server_addr}
server_port = 8055
token = ${token}

EOF

	donlond_frp frpc

	open_port 8055

}

add_forwarding_service() {
	send_stats "添加frp內網服務"
	# 提示用戶輸入服務名稱和轉發信息
	read -e -p "請輸入服務名稱:" service_name
	read -e -p "請輸入轉發類型 (tcp/udp) [回​​車默認tcp]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "請輸入內網IP [回車默認127.0.0.1]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "請輸入內網端口:" local_port
	read -e -p "請輸入外網端口:" remote_port

	# 將用戶輸入寫入配置文件
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 輸出生成的信息
	echo "服務$service_name已成功添加到 frpc.toml"

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "刪除frp內網服務"
	# 提示用戶輸入需要刪除的服務名稱
	read -e -p "請輸入需要刪除的服務名稱:" service_name
	# 使用 sed 刪除該服務及其相關配置
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "服務$service_name已成功從 frpc.toml 刪除"

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# 打印表頭
	printf "%-20s %-25s %-30s %-10s\n" "服務名稱" "內網地址" "外網地址" "協定"

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
		# 如果已有服務信息，在處理新服務之前打印當前服務
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 更新當前服務名稱
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
		# 打印最後一個服務的信息
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# 獲取 FRP 服務端端口
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# 生成訪問地址
generate_access_urls() {
	# 首先獲取所有端口
	get_frp_ports

	# 檢查是否有非 8055/8056 的端口
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# 只在有有效端口時顯示標題和內容
	if [ "$has_valid_ports" = true ]; then
		echo "FRP服務對外訪問地址:"

		# 處理 IPv4 地址
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# 處理 IPv6 地址（如果存在）
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# 處理 HTTPS 配置
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				local frps_search_pattern="${ipv4_address}:${port}"
				local frps_search_pattern2="127.0.0.1:${port}"
				for file in /home/web/conf.d/*.conf; do
					if [ -f "$file" ]; then
						if grep -q "$frps_search_pattern" "$file" 2>/dev/null || grep -q "$frps_search_pattern2" "$file" 2>/dev/null; then
							echo "https://$(basename "$file" .conf)"
						fi
					fi
				done
			fi
		done
	fi
}


frps_main_ports() {
	ip_address
	generate_access_urls
}




frps_panel() {
	send_stats "FRP服務端"
	local app_id="55"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP服務端$check_frp $update_status"
		echo "構建FRP內網穿透服務環境，將無公網IP的設備暴露到互聯網"
		echo "官網介紹: https://github.com/fatedier/frp/"
		echo "視頻教學: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. 安裝                  2. 更新                  3. 卸載"
		echo "------------------------"
		echo "5. 內網服務域名訪問      6. 刪除域名訪問"
		echo "------------------------"
		echo "7. 允許IP+端口訪問       8. 阻止IP+端口訪問"
		echo "------------------------"
		echo "00. 刷新服務狀態         0. 返回上一級選單"
		echo "------------------------"
		read -e -p "輸入你的選擇:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config

				add_app_id
				echo "FRP服務端已經安裝完成"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps

				add_app_id
				echo "FRP服務端已經更新完成"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "應用已卸載"
				;;
			5)
				echo "將內網穿透服務反代成域名訪問"
				send_stats "FRP對外域名訪問"
				add_yuming
				read -e -p "請輸入你的內網穿透服務端口:" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "域名格式 example.com 不帶https://"
				web_del
				;;

			7)
				send_stats "允許IP訪問"
				read -e -p "請輸入需要放行的端口:" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "阻止IP訪問"
				echo "如果你已經反代域名訪問了，可用此功能阻止IP+端口訪問，這樣更安全。"
				read -e -p "請輸入需要阻止的端口:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "刷新FRP服務狀態"
				echo "已經刷新FRP服務狀態"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRP客戶端"
	local app_id="56"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP客戶端$check_frp $update_status"
		echo "與服務端對接，對接後可創建內網穿透服務到互聯網訪問"
		echo "官網介紹: https://github.com/fatedier/frp/"
		echo "視頻教學: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. 安裝               2. 更新               3. 卸載"
		echo "------------------------"
		echo "4. 添加對外服務       5. 刪除對外服務       6. 手動配置服務"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		read -e -p "輸入你的選擇:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc

				add_app_id
				echo "FRP客戶端已經安裝完成"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc

				add_app_id
				echo "FRP客戶端已經更新完成"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "應用已卸載"
				;;

			4)
				add_forwarding_service
				;;

			5)
				delete_forwarding_service
				;;

			6)
				install nano
				nano /home/frp/frpc.toml
				docker restart frpc
				;;

			*)
				break
				;;
		esac
		break_end
	done
}




yt_menu_pro() {

	local app_id="66"
	local VIDEO_DIR="/home/yt-dlp"
	local URL_FILE="$VIDEO_DIR/urls.txt"
	local ARCHIVE_FILE="$VIDEO_DIR/archive.txt"

	mkdir -p "$VIDEO_DIR"

	while true; do

		if [ -x "/usr/local/bin/yt-dlp" ]; then
		   local YTDLP_STATUS="${gl_lv}已安裝${gl_bai}"
		else
		   local YTDLP_STATUS="${gl_hui}未安裝${gl_bai}"
		fi

		clear
		send_stats "yt-dlp 下載工具"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp 是一個功能強大的視頻下載工具，支持 YouTube、Bilibili、Twitter 等數千站點。"
		echo -e "官網地址：https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "已下載視頻列表:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "（暫無）"
		echo "-------------------------"
		echo "1.  安裝               2.  更新               3.  卸載"
		echo "-------------------------"
		echo "5.  單個視頻下載       6.  批量視頻下載       7.  自定義參數下載"
		echo "8.  下載為MP3音頻      9.  刪除視頻目錄       10. Cookie管理（開發中）"
		echo "-------------------------"
		echo "0. 返回上一級選單"
		echo "-------------------------"
		read -e -p "請輸入選項編號:" choice

		case $choice in
			1)
				send_stats "正在安裝 yt-dlp..."
				echo "正在安裝 yt-dlp..."
				install ffmpeg
				curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				chmod a+rx /usr/local/bin/yt-dlp

				add_app_id
				echo "安裝完成。按任意鍵繼續..."
				read ;;
			2)
				send_stats "正在更新 yt-dlp..."
				echo "正在更新 yt-dlp..."
				yt-dlp -U

				add_app_id
				echo "更新完成。按任意鍵繼續..."
				read ;;
			3)
				send_stats "正在卸載 yt-dlp..."
				echo "正在卸載 yt-dlp..."
				rm -f /usr/local/bin/yt-dlp

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "卸載完成。按任意鍵繼續..."
				read ;;
			5)
				send_stats "單個視頻下載"
				read -e -p "請輸入視頻鏈接:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "下載完成，按任意鍵繼續..." ;;
			6)
				send_stats "批量視頻下載"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# 輸入多個視頻鏈接地址\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "現在開始批量下載..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "批量下載完成，按任意鍵繼續..." ;;
			7)
				send_stats "自定義視頻下載"
				read -e -p "請輸入完整 yt-dlp 參數（不含 yt-dlp）:" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "執行完成，按任意鍵繼續..." ;;
			8)
				send_stats "MP3下載"
				read -e -p "請輸入視頻鏈接:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "音頻下載完成，按任意鍵繼續..." ;;

			9)
				send_stats "刪除視頻"
				read -e -p "請輸入刪除視頻名稱:" rmdir
				rm -rf "$VIDEO_DIR/$rmdir"
				;;
			*)
				break ;;
		esac
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



# 修復dpkg中斷問題
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}正在系統更新...${gl_bai}"
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
	echo -e "${gl_huang}正在系統清理...${gl_bai}"
	if command -v dnf &>/dev/null; then
		rpm --rebuilddb
		dnf autoremove -y
		dnf clean all
		dnf makecache
		journalctl --rotate
		journalctl --vacuum-time=1s
		journalctl --vacuum-size=500M

	elif command -v yum &>/dev/null; then
		rpm --rebuilddb
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
		echo "清理包管理器緩存..."
		apk cache clean
		echo "刪除系統日誌..."
		rm -rf /var/log/*
		echo "刪除APK緩存..."
		rm -rf /var/cache/apk/*
		echo "刪除臨時文件..."
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
		echo "刪除系統日誌..."
		rm -rf /var/log/*
		echo "刪除臨時文件..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "清理未使用的依賴..."
		pkg autoremove -y
		echo "清理包管理器緩存..."
		pkg clean -y
		echo "刪除系統日誌..."
		rm -rf /var/log/*
		echo "刪除臨時文件..."
		rm -rf /tmp/*

	else
		echo "未知的包管理器!"
		return
	fi
	return
}



bbr_on() {

sed -i '/net.ipv4.tcp_congestion_control=/d' /etc/sysctl.conf
echo "net.ipv4.tcp_congestion_control=bbr" >> /etc/sysctl.conf
sysctl -p

}


set_dns() {

ip_address

chattr -i /etc/resolv.conf
> /etc/resolv.conf

if [ -n "$ipv4_address" ]; then
	echo "nameserver $dns1_ipv4" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv4" >> /etc/resolv.conf
fi

if [ -n "$ipv6_address" ]; then
	echo "nameserver $dns1_ipv6" >> /etc/resolv.conf
	echo "nameserver $dns2_ipv6" >> /etc/resolv.conf
fi

if [ ! -s /etc/resolv.conf ]; then
	echo "nameserver 223.5.5.5" >> /etc/resolv.conf
	echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

chattr +i /etc/resolv.conf

}


set_dns_ui() {
root_use
send_stats "優化DNS"
while true; do
	clear
	echo "優化DNS地址"
	echo "------------------------"
	echo "當前DNS地址"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 國外DNS優化:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 國內DNS優化:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. 手動編輯DNS配置"
	echo "------------------------"
	echo "0. 返回上一級選單"
	echo "------------------------"
	read -e -p "請輸入你的選擇:" Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "國外DNS優化"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "國內DNS優化"
		;;
	  3)
		install nano
		chattr -i /etc/resolv.conf
		nano /etc/resolv.conf
		chattr +i /etc/resolv.conf
		send_stats "手動編輯DNS配置"
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



correct_ssh_config() {

	local sshd_config="/etc/ssh/sshd_config"

	# 如果找到 PasswordAuthentication 設置為 yes
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# 如果找到 PubkeyAuthentication 設置為 yes
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# 如果 PasswordAuthentication 和 PubkeyAuthentication 都沒有匹配，則設置默認值
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # 備份 SSH 配置文件
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSH 端口已修改為:$new_port"

  sleep 1

}



add_sshkey() {
	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""
	cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	ip_address
	echo -e "私鑰信息已生成，務必復制保存，可保存成${gl_huang}${ipv4_address}_ssh.key${gl_bai}文件，用於以後的SSH登錄"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT私鑰登錄已開啟，已關閉ROOT密碼登錄，重連將會生效${gl_bai}"

}


import_sshkey() {

	read -e -p "請輸入您的SSH公鑰內容（通常以 'ssh-rsa' 或 'ssh-ed25519' 開頭）:" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}錯誤：未輸入公鑰內容。${gl_bai}"
		return 1
	fi

	chmod 700 ~/
	mkdir -p ~/.ssh
	chmod 700 ~/.ssh
	touch ~/.ssh/authorized_keys
	echo "$public_key" >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}公鑰已成功導入，ROOT私鑰登錄已開啟，已關閉ROOT密碼登錄，重連將會生效${gl_bai}"

}




add_sshpasswd() {

echo "設置你的ROOT密碼"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ROOT登錄設置完畢！${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}提示:${gl_bai}該功能需要root用戶才能運行！" && break_end && kejilion
}



dd_xitong() {
		send_stats "重裝系統"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "重裝後初始用戶名:${gl_huang}root${gl_bai}初始密碼:${gl_huang}LeitboGi0ro${gl_bai}初始端口:${gl_huang}22${gl_bai}"
		  echo -e "${gl_huang}重裝後請及時修改初始密碼，防止暴力入侵。命令行輸入passwd修改密碼${gl_bai}"
		  echo -e "按任意鍵繼續..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "重裝後初始用戶名:${gl_huang}Administrator${gl_bai}初始密碼:${gl_huang}Teddysun.com${gl_bai}初始端口:${gl_huang}3389${gl_bai}"
		  echo -e "按任意鍵繼續..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "重裝後初始用戶名:${gl_huang}root${gl_bai}初始密碼:${gl_huang}123@@@${gl_bai}初始端口:${gl_huang}22${gl_bai}"
		  echo -e "按任意鍵繼續..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "重裝後初始用戶名:${gl_huang}Administrator${gl_bai}初始密碼:${gl_huang}123@@@${gl_bai}初始端口:${gl_huang}3389${gl_bai}"
		  echo -e "按任意鍵繼續..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "重裝系統"
			echo "--------------------------------"
			echo -e "${gl_hong}注意:${gl_bai}重裝有風險失聯，不放心者慎用。重裝預計花費15分鐘，請提前備份數據。"
			echo -e "${gl_hui}感謝bin456789大佬和leitbogioro大佬的腳本支持！${gl_bai} "
			echo -e "${gl_hui}bin456789項目地址: https://github.com/bin456789/reinstall${gl_bai}"
			echo -e "${gl_hui}leitbogioro項目地址: https://github.com/leitbogioro/Tools${gl_bai}"
			echo "------------------------"
			echo "1. Debian 13                  2. Debian 12"
			echo "3. Debian 11                  4. Debian 10"
			echo "------------------------"
			echo "11. Ubuntu 24.04              12. Ubuntu 22.04"
			echo "13. Ubuntu 20.04              14. Ubuntu 18.04"
			echo "------------------------"
			echo "21. Rocky Linux 10            22. Rocky Linux 9"
			echo "23. Alma Linux 10             24. Alma Linux 9"
			echo "25. oracle Linux 10           26. oracle Linux 9"
			echo "27. Fedora Linux 42           28. Fedora Linux 41"
			echo "29. CentOS 10                 30. CentOS 9"
			echo "------------------------"
			echo "31. Alpine Linux              32. Arch Linux"
			echo "33. Kali Linux                34. openEuler"
			echo "35. openSUSE Tumbleweed       36. fnos飛牛公測版"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2025"
			echo "45. Windows Server 2022       46. Windows Server 2019"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			read -e -p "請選擇要重裝的系統:" sys_choice
			case "$sys_choice" in


			  1)
				send_stats "重裝debian 13"
				dd_xitong_3
				bash reinstall.sh debian 13
				reboot
				exit
				;;

			  2)
				send_stats "重裝debian 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  3)
				send_stats "重裝debian 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  4)
				send_stats "重裝debian 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  11)
				send_stats "重裝ubuntu 24.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "重裝ubuntu 22.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "重裝ubuntu 20.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "重裝ubuntu 18.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "重裝rockylinux10"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "重裝rockylinux9"
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				send_stats "重裝alma10"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "重裝alma9"
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				send_stats "重裝oracle10"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "重裝oracle9"
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				send_stats "重裝fedora42"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "重裝fedora41"
				dd_xitong_3
				bash reinstall.sh fedora 41
				reboot
				exit
				;;

			  29)
				send_stats "重裝centos10"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "重裝centos9"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "重裝alpine"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "重裝arch"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "重裝kali"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "重裝openeuler"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "重裝opensuse"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "重裝飛牛"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;

			  41)
				send_stats "重裝windows11"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;

			  42)
				dd_xitong_2
				send_stats "重裝windows10"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;

			  43)
				send_stats "重裝windows7"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "重裝windows server 25"
				dd_xitong_2
				bash InstallNET.sh -windows 2025 -lang "cn"
				reboot
				exit
				;;

			  45)
				send_stats "重裝windows server 22"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;

			  46)
				send_stats "重裝windows server 19"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "重裝windows11 ARM"
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
				  echo "您已安裝xanmod的BBRv3內核"
				  echo "當前內核版本:$kernel_version"

				  echo ""
				  echo "內核管理"
				  echo "------------------------"
				  echo "1. 更新BBRv3內核              2. 卸載BBRv3內核"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# 步驟3：添加存儲庫
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "XanMod內核已更新。重啟後生效"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "XanMod內核已卸載。重啟後生效"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "設置BBR3加速"
		  echo "視頻介紹: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		  echo "------------------------------------------------"
		  echo "僅支持Debian/Ubuntu"
		  echo "請備份數據，將為你升級Linux內核開啟BBR3"
		  echo "------------------------------------------------"
		  read -e -p "確定繼續嗎？ (Y/N):" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "當前環境不支持，僅支持Debian和Ubuntu系統"
					break_end
					linux_Settings
				fi
			else
				echo "無法確定操作系統類型"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# 步驟3：添加存儲庫
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "XanMod內核安裝並BBR3啟用成功。重啟後生效"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "已取消"
			  ;;
			*)
			  echo "無效的選擇，請輸入 Y 或 N。"
			  ;;
		  esac
		fi

}


elrepo_install() {
	# 導入 ELRepo GPG 公鑰
	echo "導入 ELRepo GPG 公鑰..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 檢測系統版本
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 確保我們在一個支持的操作系統上運行
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "不支持的操作系統：$os_name"
		break_end
		linux_Settings
	fi
	# 打印檢測到的操作系統信息
	echo "檢測到的操作系統:$os_name $os_version"
	# 根據系統版本安裝對應的 ELRepo 倉庫配置
	if [[ "$os_version" == 8 ]]; then
		echo "安裝 ELRepo 倉庫配置 (版本 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "安裝 ELRepo 倉庫配置 (版本 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "安裝 ELRepo 倉庫配置 (版本 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "不支持的系統版本：$os_version"
		break_end
		linux_Settings
	fi
	# 啟用 ELRepo 內核倉庫並安裝最新的主線內核
	echo "啟用 ELRepo 內核倉庫並安裝最新的主線內核..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "已安裝 ELRepo 倉庫配置並更新到最新主線內核。"
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "紅帽內核管理"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "您已安裝elrepo內核"
				  echo "當前內核版本:$kernel_version"

				  echo ""
				  echo "內核管理"
				  echo "------------------------"
				  echo "1. 更新elrepo內核              2. 卸載elrepo內核"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "更新紅帽內核"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "elrepo內核已卸載。重啟後生效"
						send_stats "卸載紅帽內核"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "請備份數據，將為你升級Linux內核"
		  echo "視頻介紹: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		  echo "------------------------------------------------"
		  echo "僅支持紅帽系列發行版 CentOS/RedHat/Alma/Rocky/oracle"
		  echo "升級Linux內核可提升系統性能和安全，建議有條件的嘗試，生產環境謹慎升級！"
		  echo "------------------------------------------------"
		  read -e -p "確定繼續嗎？ (Y/N):" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "升級紅帽內核"
			  server_reboot
			  ;;
			[Nn])
			  echo "已取消"
			  ;;
			*)
			  echo "無效的選擇，請輸入 Y 或 N。"
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}正在更新病毒庫...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "請指定要掃描的目錄。"
		return
	fi

	echo -e "${gl_huang}正在掃描目錄$@...${gl_bai}"

	# 構建 mount 參數
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# 構建 clamscan 命令參數
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# 執行 Docker 命令
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ 扫描完成，病毒报告存放在${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}如果有病毒請在${gl_huang}scan.log${gl_lv}文件中搜索FOUND關鍵字確認病毒位置${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "病毒掃描管理"
		  while true; do
				clear
				echo "clamav病毒掃描工具"
				echo "視頻介紹: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
				echo "------------------------"
				echo "是一個開源的防病毒軟件工具，主要用於檢測和刪除各種類型的惡意軟件。"
				echo "包括病毒、特洛伊木馬、間諜軟件、惡意腳本和其他有害軟件。"
				echo "------------------------"
				echo -e "${gl_lv}1. 全盤掃描${gl_bai}             ${gl_huang}2. 重要目錄掃描${gl_bai}            ${gl_kjlan}3. 自定義目錄掃描${gl_bai}"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				read -e -p "請輸入你的選擇:" sub_choice
				case $sub_choice in
					1)
					  send_stats "全盤掃描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "重要目錄掃描"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "自定義目錄掃描"
					  read -e -p "請輸入要掃描的目錄，用空格分隔（例如：/etc /var /usr /home /root）:" directories
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




# 高性能模式優化函數
optimize_high_performance() {
	echo -e "${gl_lv}切換到${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}優化文件描述符...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}優化虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}優化網絡設置...${gl_bai}"
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

	echo -e "${gl_lv}優化緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}優化CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}其他優化...${gl_bai}"
	# 禁用透明大頁面，減少延遲
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# 均衡模式優化函數
optimize_balanced() {
	echo -e "${gl_lv}切換到均衡模式...${gl_bai}"

	echo -e "${gl_lv}優化文件描述符...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}優化虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}優化網絡設置...${gl_bai}"
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

	echo -e "${gl_lv}優化緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}優化CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}其他優化...${gl_bai}"
	# 還原透明大頁面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 還原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# 還原默認設置函數
restore_defaults() {
	echo -e "${gl_lv}還原到默認設置...${gl_bai}"

	echo -e "${gl_lv}還原文件描述符...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}還原虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}還原網絡設置...${gl_bai}"
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

	echo -e "${gl_lv}還原緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}還原CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}還原其他優化...${gl_bai}"
	# 還原透明大頁面
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# 還原 NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# 網站搭建優化函數
optimize_web_server() {
	echo -e "${gl_lv}切換到網站搭建優化模式...${gl_bai}"

	echo -e "${gl_lv}優化文件描述符...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}優化虛擬內存...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}優化網絡設置...${gl_bai}"
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

	echo -e "${gl_lv}優化緩存管理...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}優化CPU設置...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}其他優化...${gl_bai}"
	# 禁用透明大頁面，減少延遲
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# 禁用 NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux內核調優管理"
	  echo "Linux系統內核參數優化"
	  echo "視頻介紹: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "提供多種系統參數調優模式，用戶可以根據自身使用場景進行選擇切換。"
	  echo -e "${gl_huang}提示:${gl_bai}生產環境請謹慎使用！"
	  echo "--------------------"
	  echo "1. 高性能優化模式：     最大化系統性能，優化文件描述符、虛擬內存、網絡設置、緩存管理和CPU設置。"
	  echo "2. 均衡優化模式：       在性能與資源消耗之間取得平衡，適合日常使用。"
	  echo "3. 網站優化模式：       針對網站服務器進行優化，提高並發連接處理能力、響應速度和整體性能。"
	  echo "4. 直播優化模式：       針對直播推流的特殊需求進行優化，減少延遲，提高傳輸性能。"
	  echo "5. 遊戲服優化模式：     針對遊戲服務器進行優化，提高並發處理能力和響應速度。"
	  echo "6. 還原默認設置：       將系統設置還原為默認配置。"
	  echo "--------------------"
	  echo "0. 返回上一級選單"
	  echo "--------------------"
	  read -e -p "請輸入你的選擇:" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能優化模式"
			  optimize_high_performance
			  send_stats "高性能模式優化"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "均衡模式優化"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "網站優化模式"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播優化模式"
			  optimize_high_performance
			  send_stats "直播推流優化"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="遊戲服優化模式"
			  optimize_high_performance
			  send_stats "遊戲服優化"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "還原默認設置"
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
				echo -e "${gl_lv}系統語言已經修改為:$lang重新連接SSH生效。${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}系統語言已經修改為:$lang重新連接SSH生效。${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "不支持的系統:$ID"
				break_end
				;;
		esac
	else
		echo "不支持的系統，無法識別系統類型。"
		break_end
	fi
}




linux_language() {
root_use
send_stats "切換系統語言"
while true; do
  clear
  echo "當前系統語言:$LANG"
  echo "------------------------"
  echo "1. 英文          2. 簡體中文          3. 繁體中文"
  echo "------------------------"
  echo "0. 返回上一級選單"
  echo "------------------------"
  read -e -p "輸入你的選擇:" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "切換到英文"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "切換到簡體中文"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "切換到繁體中文"
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
echo -e "${gl_lv}變更完成。重新連接SSH後可查看變化！${gl_bai}"

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
	echo "0. 返回上一級選單"
	echo "------------------------"
	read -e -p "輸入你的選擇:" choice

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
  send_stats "系統回收站"

  local bashrc_profile="/root/.bashrc"
  local TRASH_DIR="$HOME/.local/share/Trash/files"

  while true; do

	local trash_status
	if ! grep -q "trash-put" "$bashrc_profile"; then
		trash_status="${gl_hui}未啟用${gl_bai}"
	else
		trash_status="${gl_lv}已啟用${gl_bai}"
	fi

	clear
	echo -e "當前回收站${trash_status}"
	echo -e "啟用後rm刪除的文件先進入回收站，防止誤刪重要文件！"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "回收站為空"
	echo "------------------------"
	echo "1. 啟用回收站          2. 關閉回收站"
	echo "3. 還原內容            4. 清空回收站"
	echo "------------------------"
	echo "0. 返回上一級選單"
	echo "------------------------"
	read -e -p "輸入你的選擇:" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "回收站已啟用，刪除的文件將移至回收站。"
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "回收站已關閉，文件將直接刪除。"
		sleep 2
		;;
	  3)
		read -e -p "輸入要還原的文件名:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restore已還原到主目錄。"
		else
		  echo "文件不存在。"
		fi
		;;
	  4)
		read -e -p "確認清空回收站？ [y/n]:" confirm
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

linux_fav() {
send_stats "命令收藏夾"
bash <(curl -l -s ${gh_proxy}raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh)
}

# 創建備份
create_backup() {
	send_stats "創建備份"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# 提示用戶輸入備份目錄
	echo "創建備份示例："
	echo "- 備份單個目錄: /var/www"
	echo "- 備份多個目錄: /etc /home /var/log"
	echo "- 直接回車將使用默認目錄 (/etc /usr /home)"
	read -r -p "請輸入要備份的目錄（多個目錄用空格分隔，直接回車則使用默認目錄）：" input

	# 如果用戶沒有輸入目錄，則使用默認目錄
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# 將用戶輸入的目錄按空格分隔成數組
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# 生成備份文件前綴
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# 提取目錄名稱並去除斜杠
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 去除最後一個下劃線
	local PREFIX=${PREFIX%_}

	# 生成備份文件名
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# 打印用戶選擇的目錄
	echo "您選擇的備份目錄為："
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 創建備份
	echo "正在創建備份$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 檢查命令是否成功
	if [ $? -eq 0 ]; then
		echo "備份創建成功:$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "備份創建失敗！"
		exit 1
	fi
}

# 恢復備份
restore_backup() {
	send_stats "恢復備份"
	# 選擇要恢復的備份
	read -e -p "請輸入要恢復的備份文件名:" BACKUP_NAME

	# 檢查備份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "備份文件不存在！"
		exit 1
	fi

	echo "正在恢復備份$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "備份恢復成功！"
	else
		echo "備份恢復失敗！"
		exit 1
	fi
}

# 列出備份
list_backups() {
	echo "可用的備份："
	ls -1 "$BACKUP_DIR"
}

# 刪除備份
delete_backup() {
	send_stats "刪除備份"

	read -e -p "請輸入要刪除的備份文件名:" BACKUP_NAME

	# 檢查備份文件是否存在
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "備份文件不存在！"
		exit 1
	fi

	# 刪除備份
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "備份刪除成功！"
	else
		echo "備份刪除失敗！"
		exit 1
	fi
}

# 備份主菜單
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "系統備份功能"
		echo "系統備份功能"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. 創建備份        2. 恢復備份        3. 刪除備份"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		read -e -p "請輸入你的選擇:" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "按回車鍵繼續..."
	done
}









# 顯示連接列表
list_connections() {
	echo "已保存的連接:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 添加新連接
add_connection() {
	send_stats "添加新連接"
	echo "創建新連接示例："
	echo "- 連接名稱: my_server"
	echo "- IP地址: 192.168.1.100"
	echo "- 用戶名: root"
	echo "- 端口: 22"
	echo "------------------------"
	read -e -p "請輸入連接名稱:" name
	read -e -p "請輸入IP地址:" ip
	read -e -p "請輸入用戶名 (默認: root):" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "請輸入端口號 (默認: 22):" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "請選擇身份驗證方式:"
	echo "1. 密碼"
	echo "2. 密鑰"
	read -e -p "請輸入選擇 (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "請輸入密碼:" password_or_key
			echo  # 换行
			;;
		2)
			echo "請粘貼密鑰內容 (粘貼完成後按兩次回車)："
			local password_or_key=""
			while IFS= read -r line; do
				# 如果輸入為空行且密鑰內容已經包含了開頭，則結束輸入
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 如果是第一行或已經開始輸入密鑰內容，則繼續添加
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# 檢查是否是密鑰內容
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "無效的選擇！"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "連接已保存!"
}



# 刪除連接
delete_connection() {
	send_stats "刪除連接"
	read -e -p "請輸入要刪除的連接編號:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "錯誤：未找到對應的連接。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 如果連接使用的是密鑰文件，則刪除該密鑰文件
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "連接已刪除!"
}

# 使用連接
use_connection() {
	send_stats "使用連接"
	read -e -p "請輸入要使用的連接編號:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "錯誤：未找到對應的連接。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "正在連接到$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# 使用密鑰連接
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "連接失敗！請檢查以下內容："
			echo "1. 密鑰文件路徑是否正確：$password_or_key"
			echo "2. 密鑰文件權限是否正確（應為 600）。"
			echo "3. 目標服務器是否允許使用密鑰登錄。"
		fi
	else
		# 使用密碼連接
		if ! command -v sshpass &> /dev/null; then
			echo "錯誤：未安裝 sshpass，請先安裝 sshpass。"
			echo "安裝方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "連接失敗！請檢查以下內容："
			echo "1. 用戶名和密碼是否正確。"
			echo "2. 目標服務器是否允許密碼登錄。"
			echo "3. 目標服務器的 SSH 服務是否正常運行。"
		fi
	fi
}


ssh_manager() {
	send_stats "ssh遠程連接工具"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 檢查配置文件和密鑰目錄是否存在，如果不存在則創建
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "SSH 遠程連接工具"
		echo "可以通過SSH連接到其他Linux系統上"
		echo "------------------------"
		list_connections
		echo "1. 創建新連接        2. 使用連接        3. 刪除連接"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		read -e -p "請輸入你的選擇:" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "無效的選擇，請重試。" ;;
		esac
	done
}












# 列出可用的硬盤分區
list_partitions() {
	echo "可用的硬盤分區："
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 掛載分區
mount_partition() {
	send_stats "掛載分區"
	read -e -p "請輸入要掛載的分區名稱（例如 sda1）:" PARTITION

	# 檢查分區是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "分區不存在！"
		return
	fi

	# 檢查分區是否已經掛載
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "分區已經掛載！"
		return
	fi

	# 創建掛載點
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 掛載分區
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "分區掛載成功:$MOUNT_POINT"
	else
		echo "分區掛載失敗！"
		rmdir "$MOUNT_POINT"
	fi
}

# 卸載分區
unmount_partition() {
	send_stats "卸載分區"
	read -e -p "請輸入要卸載的分區名稱（例如 sda1）:" PARTITION

	# 檢查分區是否已經掛載
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "分區未掛載！"
		return
	fi

	# 卸載分區
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "分區卸載成功:$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "分區卸載失敗！"
	fi
}

# 列出已掛載的分區
list_mounted_partitions() {
	echo "已掛載的分區："
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 格式化分區
format_partition() {
	send_stats "格式化分區"
	read -e -p "請輸入要格式化的分區名稱（例如 sda1）:" PARTITION

	# 檢查分區是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "分區不存在！"
		return
	fi

	# 檢查分區是否已經掛載
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "分區已經掛載，請先卸載！"
		return
	fi

	# 選擇文件系統類型
	echo "請選擇文件系統類型："
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "請輸入你的選擇:" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "無效的選擇！"; return ;;
	esac

	# 確認格式化
	read -e -p "確認格式化分區 /dev/$PARTITION為$FS_TYPE嗎？ (y/n):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "操作已取消。"
		return
	fi

	# 格式化分區
	echo "正在格式化分區 /dev/$PARTITION為$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "分區格式化成功！"
	else
		echo "分區格式化失敗！"
	fi
}

# 檢查分區狀態
check_partition() {
	send_stats "檢查分區狀態"
	read -e -p "請輸入要檢查的分區名稱（例如 sda1）:" PARTITION

	# 檢查分區是否存在
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "分區不存在！"
		return
	fi

	# 檢查分區狀態
	echo "檢查分區 /dev/$PARTITION的狀態："
	fsck "/dev/$PARTITION"
}

# 主菜單
disk_manager() {
	send_stats "硬盤管理功能"
	while true; do
		clear
		echo "硬盤分區管理"
		echo -e "${gl_huang}該功能內部測試階段，請勿在生產環境使用。${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. 掛載分區        2. 卸載分區        3. 查看已掛載分區"
		echo "4. 格式化分區      5. 檢查分區狀態"
		echo "------------------------"
		echo "0. 返回上一級選單"
		echo "------------------------"
		read -e -p "請輸入你的選擇:" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "按回車鍵繼續..."
	done
}




# 顯示任務列表
list_tasks() {
	echo "已保存的同步任務:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 添加新任務
add_task() {
	send_stats "添加新同步任務"
	echo "創建新同步任務示例："
	echo "- 任務名稱: backup_www"
	echo "- 本地目錄: /var/www"
	echo "- 遠程地址: user@192.168.1.100"
	echo "- 遠程目錄: /backup/www"
	echo "- 端口號 (默認 22)"
	echo "---------------------------------"
	read -e -p "請輸入任務名稱:" name
	read -e -p "請輸入本地目錄:" local_path
	read -e -p "請輸入遠程目錄:" remote_path
	read -e -p "請輸入遠程用戶@IP:" remote
	read -e -p "請輸入 SSH 端口 (默認 22):" port
	port=${port:-22}

	echo "請選擇身份驗證方式:"
	echo "1. 密碼"
	echo "2. 密鑰"
	read -e -p "請選擇 (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "請輸入密碼:" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "請粘貼密鑰內容 (粘貼完成後按兩次回車)："
			local password_or_key=""
			while IFS= read -r line; do
				# 如果輸入為空行且密鑰內容已經包含了開頭，則結束輸入
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 如果是第一行或已經開始輸入密鑰內容，則繼續添加
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# 檢查是否是密鑰內容
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "無效的密鑰內容！"
				return
			fi
			;;
		*)
			echo "無效的選擇！"
			return
			;;
	esac

	echo "請選擇同步模式:"
	echo "1. 標準模式 (-avz)"
	echo "2. 刪除目標文件 (-avz --delete)"
	read -e -p "請選擇 (1/2):" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "無效選擇，使用默認 -avz"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "任務已保存!"
}

# 刪除任務
delete_task() {
	send_stats "刪除同步任務"
	read -e -p "請輸入要刪除的任務編號:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "錯誤：未找到對應的任務。"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 如果任務使用的是密鑰文件，則刪除該密鑰文件
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "任務已刪除!"
}


run_task() {
	send_stats "執行同步任務"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# 解析參數
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 如果沒有傳入任務編號，提示用戶輸入
	if [[ -z "$num" ]]; then
		read -e -p "請輸入要執行的任務編號:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "錯誤: 未找到該任務!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 根據同步方向調整源和目標路徑
	if [[ "$direction" == "pull" ]]; then
		echo "正在拉取同步到本地:$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "正在推送同步到遠端:$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# 添加 SSH 連接通用參數
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "錯誤：未安裝 sshpass，請先安裝 sshpass。"
			echo "安裝方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 檢查密鑰文件是否存在和權限是否正確
		if [[ ! -f "$password_or_key" ]]; then
			echo "錯誤：密鑰文件不存在：$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "警告：密鑰文件權限不正確，正在修復..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "同步完成!"
	else
		echo "同步失敗! 請檢查以下內容："
		echo "1. 網絡連接是否正常"
		echo "2. 遠程主機是否可訪問"
		echo "3. 認證信息是否正確"
		echo "4. 本地和遠程目錄是否有正確的訪問權限"
	fi
}


# 創建定時任務
schedule_task() {
	send_stats "添加同步定時任務"

	read -e -p "請輸入要定時同步的任務編號:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "錯誤: 請輸入有效的任務編號！"
		return
	fi

	echo "請選擇定時執行間隔："
	echo "1) 每小時執行一次"
	echo "2) 每天執行一次"
	echo "3) 每週執行一次"
	read -e -p "請輸入選項 (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "錯誤: 請輸入有效的選項！" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 檢查是否已存在相同任務
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "錯誤: 該任務的定時同步已存在！"
		return
	fi

	# 創建到用戶的 crontab
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "定時任務已創建:$cron_job"
}

# 查看定時任務
view_tasks() {
	echo "當前的定時任務:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 刪除定時任務
delete_task_schedule() {
	send_stats "刪除同步定時任務"
	read -e -p "請輸入要刪除的任務編號:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "錯誤: 請輸入有效的任務編號！"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "已刪除任務編號$num的定時任務"
}


# 任務管理主菜單
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync 遠程同步工具"
		echo "遠程目錄之間同步，支持增量同步，高效穩定。"
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 創建新任務                 2. 刪除任務"
		echo "3. 執行本地同步到遠端         4. 執行遠端同步到本地"
		echo "5. 創建定時任務               6. 刪除定時任務"
		echo "---------------------------------"
		echo "0. 返回上一級選單"
		echo "---------------------------------"
		read -e -p "請輸入你的選擇:" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "無效的選擇，請重試。" ;;
		esac
		read -e -p "按回車鍵繼續..."
	done
}









linux_info() {

	clear
	send_stats "系統信息查詢"

	ip_address

	local cpu_info=$(lscpu | awk -F': +' '/Model name:/ {print $2; exit}')

	local cpu_usage_percent=$(awk '{u=$2+$4; t=$2+$4+$5; if (NR==1){u1=u; t1=t;} else printf "%.0f\n", (($2+$4-u1) * 100 / (t-t1))}' \
		<(grep 'cpu ' /proc/stat) <(sleep 1; grep 'cpu ' /proc/stat))

	local cpu_cores=$(nproc)

	local cpu_freq=$(cat /proc/cpuinfo | grep "MHz" | head -n 1 | awk '{printf "%.1f GHz\n", $4/1000}')

	local mem_info=$(free -b | awk 'NR==2{printf "%.2f/%.2fM (%.2f%%)", $3/1024/1024, $2/1024/1024, $3*100/$2}')

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


	local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1% 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d時 ", run_hours); printf("%d分\n", run_minutes)}')

	local timezone=$(current_timezone)

	local tcp_count=$(ss -t | wc -l)
	local udp_count=$(ss -u | wc -l)


	echo ""
	echo -e "系統信息查詢"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}主機名:${gl_bai}$hostname"
	echo -e "${gl_kjlan}系統版本:${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linux版本:${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU架構:${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPU型號:${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPU核心數:${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU頻率:${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU佔用:${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}系統負載:${gl_bai}$load"
	echo -e "${gl_kjlan}TCP|UDP連接數:${gl_bai}$tcp_count|$udp_count"
	echo -e "${gl_kjlan}物理內存:${gl_bai}$mem_info"
	echo -e "${gl_kjlan}虛擬內存:${gl_bai}$swap_info"
	echo -e "${gl_kjlan}硬盤佔用:${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}總接收:${gl_bai}$rx"
	echo -e "${gl_kjlan}總發送:${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}網絡算法:${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}運營商:${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4地址:${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6地址:${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS地址:${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}地理位置:${gl_bai}$country $city"
	echo -e "${gl_kjlan}系統時間:${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}運行時長:${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "基礎工具"
	  echo -e "基礎工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}curl 下載工具${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget 下載工具${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo 超級管理權限工具${gl_kjlan}4.   ${gl_bai}socat 通信連接工具"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop 系統監控工具${gl_kjlan}6.   ${gl_bai}iftop 網絡流量監控工具"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP壓縮解壓工具${gl_kjlan}8.   ${gl_bai}tar GZ壓縮解壓工具"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux 多路後台運行工具${gl_kjlan}10.  ${gl_bai}ffmpeg 視頻編碼直播推流工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop 現代化監控工具${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}ranger 文件管理工具"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu 磁盤佔用查看工具${gl_kjlan}14.  ${gl_bai}fzf 全局搜索工具"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim 文本編輯器${gl_kjlan}16.  ${gl_bai}nano 文本編輯器${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}git 版本控制系統${gl_kjlan}18.  ${gl_bai}opencode AI編程助手${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}黑客帝國屏保${gl_kjlan}22.  ${gl_bai}跑火車屏保"
	  echo -e "${gl_kjlan}26.  ${gl_bai}俄羅斯方塊小遊戲${gl_kjlan}27.  ${gl_bai}貪吃蛇小遊戲"
	  echo -e "${gl_kjlan}28.  ${gl_bai}太空入侵者小遊戲"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}全部安裝${gl_kjlan}32.  ${gl_bai}全部安裝（不含屏保和遊戲）${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}全部卸載"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}安裝指定工具${gl_kjlan}42.  ${gl_bai}卸載指定工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "工具已安裝，使用方法如下："
			  curl --help
			  send_stats "安裝curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "工具已安裝，使用方法如下："
			  wget --help
			  send_stats "安裝wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "工具已安裝，使用方法如下："
			  sudo --help
			  send_stats "安裝sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "工具已安裝，使用方法如下："
			  socat -h
			  send_stats "安裝socat"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "安裝htop"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "安裝iftop"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "工具已安裝，使用方法如下："
			  unzip
			  send_stats "安裝unzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "工具已安裝，使用方法如下："
			  tar --help
			  send_stats "安裝tar"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "工具已安裝，使用方法如下："
			  tmux --help
			  send_stats "安裝tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "工具已安裝，使用方法如下："
			  ffmpeg --help
			  send_stats "安裝ffmpeg"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "安裝btop"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "安裝ranger"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "安裝ncdu"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "安裝fzf"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "安裝vim"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "安裝nano"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "安裝git"
			  ;;

			18)
			  clear
			  cd ~
			  curl -fsSL https://opencode.ai/install | bash
			  source ~/.bashrc
			  source ~/.profile
			  opencode
			  send_stats "安裝opencode"
			  ;;


			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "安裝cmatrix"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "安裝sl"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "安裝bastet"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "安裝nsnake"
			  ;;

			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "安裝ninvaders"
			  ;;

		  31)
			  clear
			  send_stats "全部安裝"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "全部安裝（不含遊戲和屏保）"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "全部卸載"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  opencode uninstall
			  rm -rf ~/.opencode
			  ;;

		  41)
			  clear
			  read -e -p "請輸入安裝的工具名（wget curl sudo htop）:" installname
			  install $installname
			  send_stats "安裝指定軟件"
			  ;;
		  42)
			  clear
			  read -e -p "請輸入卸載的工具名（htop ufw tmux cmatrix）:" removename
			  remove $removename
			  send_stats "卸載指定軟件"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "無效的輸入!"
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
			  echo "當前TCP阻塞算法:$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR管理"
			  echo "------------------------"
			  echo "1. 開啟BBRv3              2. 關閉BBRv3（會重啟）"
			  echo "------------------------"
			  echo "0. 返回上一級選單"
			  echo "------------------------"
			  read -e -p "請輸入你的選擇:" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "alpine開啟bbr3"
					  ;;
				  2)
					sed -i '/net.ipv4.tcp_congestion_control=/d' /etc/sysctl.conf
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
		wget --no-check-certificate -O tcpx.sh ${gh_proxy}raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
		chmod +x tcpx.sh
		./tcpx.sh
	fi


}





docker_ssh_migration() {

	GREEN='\033[0;32m'
	RED='\033[0;31m'
	YELLOW='\033[1;33m'
	BLUE='\033[0;36m'
	NC='\033[0m'

	is_compose_container() {
		local container=$1
		docker inspect "$container" | jq -e '.[0].Config.Labels["com.docker.compose.project"]' >/dev/null 2>&1
	}

	list_backups() {
		local BACKUP_ROOT="/tmp"
		echo -e "${BLUE}當前備份列表:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "無備份"
	}



	# ----------------------------
	# 備份
	# ----------------------------
	backup_docker() {
		send_stats "Docker備份"

		echo -e "${YELLOW}正在備份 Docker 容器...${NC}"
		docker ps --format '{{.Names}}'
		read -e -p  "請輸入要備份的容器名（多個空格分隔，回車備份全部運行中容器）:" containers

		install tar jq gzip
		install_docker

		local BACKUP_ROOT="/tmp"
		local DATE_STR=$(date +%Y%m%d_%H%M%S)
		local TARGET_CONTAINERS=()
		if [ -z "$containers" ]; then
			mapfile -t TARGET_CONTAINERS < <(docker ps --format '{{.Names}}')
		else
			read -ra TARGET_CONTAINERS <<< "$containers"
		fi
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && { echo -e "${RED}沒有找到容器${NC}"; return; }

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" > "$RESTORE_SCRIPT"
		echo "set -e" >> "$RESTORE_SCRIPT"
		echo "# 自動生成的還原腳本" >> "$RESTORE_SCRIPT"

		# 記錄已打包過的 Compose 項目路徑，避免重複打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN}備份容器:$c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" > "$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE}檢測到$c是 docker-compose 容器${NC}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p  "未檢測到 compose 目錄，請手動輸入路徑:" project_dir
				fi

				# 如果該 Compose 項目已經打包過，跳過
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}Compose 項目 [$project_name] 已備份過，跳過重複打包...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" > "${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" > "${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# docker-compose 恢復:$project_name" >> "$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >> "$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}Compose 項目 [$project_name] 已打包:${project_dir}${NC}"
				else
					echo -e "${RED}未找到 docker-compose.yml，跳過此容器...${NC}"
				fi
			else
				# 普通容器備份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "打包卷:$path"
					tar -czpf "${BACKUP_DIR}/${c}_$(basename $path).tar.gz" -C / "$(echo $path | sed 's/^\///')"
				done

				# 端口
				local PORT_ARGS=""
				mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[] | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$inspect_file" 2>/dev/null)
				for p in "${PORTS[@]}"; do PORT_ARGS+="-p $p "; done

				# 環境變量
				local ENV_VARS=""
				mapfile -t ENVS < <(jq -r '.[0].Config.Env[] | @sh' "$inspect_file")
				for e in "${ENVS[@]}"; do ENV_VARS+="-e $e "; done

				# 卷映射
				local VOL_ARGS=""
				for path in $VOL_PATHS; do VOL_ARGS+="-v $path:$path "; done

				# 鏡像
				local IMAGE
				IMAGE=$(jq -r '.[0].Config.Image' "$inspect_file")

				echo -e "\n# 還原容器:$c" >> "$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >> "$RESTORE_SCRIPT"
			fi
		done


		# 備份 /home/docker 下的所有文件（不含子目錄）
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE}備份 /home/docker 下的文件...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${GREEN}/home/docker 下的文件已打包到:${BACKUP_DIR}/home_docker_files.tar.gz${NC}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN}備份完成:${BACKUP_DIR}${NC}"
		echo -e "${GREEN}可用還原腳本:${RESTORE_SCRIPT}${NC}"


	}

	# ----------------------------
	# 還原
	# ----------------------------
	restore_docker() {

		send_stats "Docker還原"
		read -e -p  "請輸入要還原的備份目錄:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}備份目錄不存在${NC}"; return; }

		echo -e "${BLUE}開始執行還原操作...${NC}"

		install tar jq gzip
		install_docker

		# --------- 優先還原 Compose 項目 ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p  "未找到原始路徑，請輸入還原目錄路徑:" original_path

				# 檢查該 compose 項目的容器是否已經在運行
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${YELLOW}Compose 項目 [$project_name] 已有容器在運行，跳過還原...${NC}"
					continue
				fi

				read -e -p  "確認還原 Compose 項目 [$project_name] 到路徑 [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p  "請輸入新的還原路徑:" original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN}Compose 項目 [$project_name] 已解壓到:$original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN}Compose 項目 [$project_name] 還原完成！${NC}"
			fi
		done

		# --------- 繼續還原普通容器 ---------
		echo -e "${BLUE}檢查並還原普通 Docker 容器...${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${GREEN}處理容器:$container${NC}"

			# 檢查容器是否已經存在且正在運行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}容器 [$container] 已在運行，跳過還原...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && { echo -e "${RED}未找到鏡像信息，跳過:$container${NC}"; continue; }

			# 端口映射
			PORT_ARGS=""
			mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[]? | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$json")
			for p in "${PORTS[@]}"; do
				[[ -n "$p" ]] && PORT_ARGS="$PORT_ARGS -p $p"
			done

			# 環境變量
			ENV_ARGS=""
			mapfile -t ENVS < <(jq -r '.[0].Config.Env[]' "$json")
			for e in "${ENVS[@]}"; do
				ENV_ARGS="$ENV_ARGS -e \"$e\""
			done

			# 卷映射 + 卷數據恢復
			VOL_ARGS=""
			mapfile -t VOLS < <(jq -r '.[0].Mounts[] | "\(.Source):\(.Destination)"' "$json")
			for v in "${VOLS[@]}"; do
				VOL_SRC=$(echo "$v" | cut -d':' -f1)
				VOL_DST=$(echo "$v" | cut -d':' -f2)
				mkdir -p "$VOL_SRC"
				VOL_ARGS="$VOL_ARGS -v $VOL_SRC:$VOL_DST"

				VOL_FILE="$BACKUP_DIR/${container}_$(basename $VOL_SRC).tar.gz"
				if [[ -f "$VOL_FILE" ]]; then
					echo "恢復卷數據:$VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 刪除已存在但未運行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}容器 [$container] 存在但未運行，刪除舊容器...${NC}"
				docker rm -f "$container"
			fi

			# 啟動容器
			echo "執行還原命令: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW}未找到普通容器的備份信息${NC}"

		# 還原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE}正在還原 /home/docker 下的文件...${NC}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${GREEN}/home/docker 下的文件已還原完成${NC}"
		else
			echo -e "${YELLOW}未找到 /home/docker 下文件的備份，跳過...${NC}"
		fi


	}


	# ----------------------------
	# 遷移
	# ----------------------------
	migrate_docker() {
		send_stats "Docker遷移"
		install jq
		read -e -p  "請輸入要遷移的備份目錄:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}備份目錄不存在${NC}"; return; }

		read -e -p  "目標服務器IP:" TARGET_IP
		read -e -p  "目標服務器SSH用戶名:" TARGET_USER
		read -e -p "目標服務器SSH端口 [默認22]:" TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW}傳輸備份中...${NC}"
		if [[ -z "$TARGET_PASS" ]]; then
			# 使用密鑰登錄
			scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no -r "$LATEST_TAR" "$TARGET_USER@$TARGET_IP:/tmp/"
		fi

	}

	# ----------------------------
	# 刪除備份
	# ----------------------------
	delete_backup() {
		send_stats "Docker備份文件刪除"
		read -e -p  "請輸入要刪除的備份目錄:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}備份目錄不存在${NC}"; return; }
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN}已刪除備份:${BACKUP_DIR}${NC}"
	}

	# ----------------------------
	# 主菜單
	# ----------------------------
	main_menu() {
		send_stats "Docker備份遷移還原"
		while true; do
			clear
			echo "------------------------"
			echo -e "Docker備份/遷移/還原工具"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. 備份docker項目"
			echo -e "2. 遷移docker項目"
			echo -e "3. 還原docker項目"
			echo -e "4. 刪除docker項目的備份文件"
			echo "------------------------"
			echo -e "0. 返回上一級菜單"
			echo "------------------------"
			read -e -p  "請選擇:" choice
			case $choice in
				1) backup_docker ;;
				2) migrate_docker ;;
				3) restore_docker ;;
				4) delete_backup ;;
				0) return ;;
				*) echo -e "${RED}無效選項${NC}" ;;
			esac
		break_end
		done
	}

	main_menu
}





linux_docker() {

	while true; do
	  clear
	  # send_stats "docker管理"
	  echo -e "Docker管理"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}安裝更新Docker環境${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}查看Docker全局狀態${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Docker容器管理${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker鏡像管理"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker網絡管理"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker捲管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}清理無用的docker容器和鏡像網絡數據卷"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}更換Docker源"
	  echo -e "${gl_kjlan}9.   ${gl_bai}編輯daemon.json文件"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}開啟Docker-ipv6訪問"
	  echo -e "${gl_kjlan}12.  ${gl_bai}關閉Docker-ipv6訪問"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}19.  ${gl_bai}備份/遷移/還原Docker環境"
	  echo -e "${gl_kjlan}20.  ${gl_bai}卸載Docker環境"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "安裝docker環境"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "docker全局狀態"
			  echo "Docker版本"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker鏡像:${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "Docker容器:${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Docker卷:${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Docker網絡:${gl_lv}$network_count${gl_bai}"
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
				  send_stats "Docker網絡管理"
				  echo "Docker網絡列表"
				  echo "------------------------------------------------------------"
				  docker network ls
				  echo ""

				  echo "------------------------------------------------------------"
				  container_ids=$(docker ps -q)
				  printf "%-25s %-25s %-25s\n" "容器名稱" "網絡名稱" "IP地址"

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
				  echo "網絡操作"
				  echo "------------------------"
				  echo "1. 創建網絡"
				  echo "2. 加入網絡"
				  echo "3. 退出網絡"
				  echo "4. 刪除網絡"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "創建網絡"
						  read -e -p "設置新網絡名:" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "加入網絡"
						  read -e -p "加入網絡名:" dockernetwork
						  read -e -p "那些容器加入該網絡（多個容器名請用空格分隔）:" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "加入網絡"
						  read -e -p "退出網絡名:" dockernetwork
						  read -e -p "那些容器退出該網絡（多個容器名請用空格分隔）:" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "刪除網絡"
						  read -e -p "請輸入要刪除的網絡名:" dockernetwork
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
				  send_stats "Docker捲管理"
				  echo "Docker卷列表"
				  docker volume ls
				  echo ""
				  echo "卷操作"
				  echo "------------------------"
				  echo "1. 創建新卷"
				  echo "2. 刪除指定卷"
				  echo "3. 刪除所有捲"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "新建卷"
						  read -e -p "設置新卷名:" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "輸入刪除卷名（多個卷名請用空格分隔）:" dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "刪除所有捲"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "無效的選擇，請輸入 Y 或 N。"
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
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "無效的選擇，請輸入 Y 或 N。"
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
			  send_stats "Docker v6 開"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker v6 關"
			  docker_ipv6_off
			  ;;

		  19)
			  docker_ssh_migration
			  ;;


		  20)
			  clear
			  send_stats "Docker卸載"
			  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定卸载docker环境吗？(Y/N): ")" choice
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
				  echo "無效的選擇，請輸入 Y 或 N。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無效的輸入!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "測試腳本合集"
	  echo -e "測試腳本合集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IP及解鎖狀態檢測"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT 解鎖狀態檢測"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Region 流媒體解鎖測試"
	  echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu 流媒體解鎖檢測"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP質量體檢腳本${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}網絡線路測速"
	  echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 三網回程延遲路由測試"
	  echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace 三網回程線路測試"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 三網測速"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 快速回程測試腳本"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace 指定IP回程測試腳本"
	  echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 三網線路測試"
	  echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 多功能測速腳本"
	  echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality 網絡質量體檢腳本${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}硬件性能測試"
	  echo -e "${gl_kjlan}21.  ${gl_bai}yabs 性能測試"
	  echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU性能測試腳本"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}綜合性測試"
	  echo -e "${gl_kjlan}31.  ${gl_bai}bench 性能測試"
	  echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx 融合怪測評${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}nodequality 融合怪測評${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "ChatGPT解鎖狀態檢測"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "Region流媒體解鎖測試"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "yeahwu流媒體解鎖檢測"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_IP質量體檢腳本"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "besttrace三網回程延遲路由測試"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "mtr_trace三網回程線路測試"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "Superspeed三網測速"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace快速回程測試腳本"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace指定IP回程測試腳本"
			  echo "可參考的IP列表"
			  echo "------------------------"
			  echo "北京電信: 219.141.136.12"
			  echo "北京聯通: 202.106.50.1"
			  echo "北京移動: 221.179.155.161"
			  echo "上海電信: 202.96.209.133"
			  echo "上海聯通: 210.22.97.1"
			  echo "上海移動: 211.136.112.200"
			  echo "廣州電信: 58.60.188.222"
			  echo "廣州聯通: 210.21.196.6"
			  echo "廣州移動: 120.196.165.24"
			  echo "成都電信: 61.139.2.69"
			  echo "成都聯通: 119.6.6.6"
			  echo "成都移動: 211.137.96.205"
			  echo "湖南電信: 36.111.200.100"
			  echo "湖南聯通: 42.48.16.100"
			  echo "湖南移動: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "輸入一個指定IP:" testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "ludashi2020三網線路測試"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc多功能測速腳本"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "網絡質量測試腳本"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "yabs性能測試"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "icu/gb5 CPU性能測試腳本"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "bench性能測試"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "spiritysdx融合怪測評"
			  clear
			  curl -L ${gh_proxy}gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  33)
			  send_stats "nodequality融合怪測評"
			  clear
			  bash <(curl -sL https://run.NodeQuality.com)
			  ;;



		  0)
			  kejilion

			  ;;
		  *)
			  echo "無效的輸入!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "甲骨文云腳本合集"
	  echo -e "甲骨文云腳本合集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}安裝閒置機器活躍腳本"
	  echo -e "${gl_kjlan}2.   ${gl_bai}卸載閒置機器活躍腳本"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD重裝系統腳本"
	  echo -e "${gl_kjlan}4.   ${gl_bai}R探長開機腳本"
	  echo -e "${gl_kjlan}5.   ${gl_bai}開啟ROOT密碼登錄模式"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPV6恢復工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "活躍腳本: CPU佔用10-20% 內存佔用20%"
			  read -e -p "確定安裝嗎？ (Y/N):" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # 設置默認值
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # 提示用戶輸入CPU核心數和占用百分比，如果回車則使用默認值
				  read -e -p "請輸入CPU核心數 [默認:$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "請輸入CPU佔用百分比範圍（例如10-20） [默認:$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "請輸入內存佔用百分比 [默認:$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "請輸入Speedtest間隔時間（秒） [默認:$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # 運行Docker容器
				  docker run -d --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "甲骨文云安裝活躍腳本"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "無效的選擇，請輸入 Y 或 N。"
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "甲骨文云卸載活躍腳本"
			  ;;

		  3)
		  clear
		  echo "重裝系統"
		  echo "--------------------------------"
		  echo -e "${gl_hong}注意:${gl_bai}重裝有風險失聯，不放心者慎用。重裝預計花費15分鐘，請提前備份數據。"
		  read -e -p "確定繼續嗎？ (Y/N):" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "請選擇要重裝的系統:  1. Debian12 | 2. Ubuntu20.04 :" sys_choice

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
					echo "無效的選擇，請重新輸入。"
					;;
				esac
			  done

			  read -e -p "請輸入你重裝後的密碼:" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "甲骨文云重裝系統腳本"
			  ;;
			[Nn])
			  echo "已取消"
			  ;;
			*)
			  echo "無效的選擇，請輸入 Y 或 N。"
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  send_stats "R探長開機腳本"
			  bash <(wget -qO- ${gh_proxy}github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh)
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "該功能由jhb大神提供，感謝他！"
			  send_stats "ipv6修復"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "無效的輸入!"
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
		echo -e "${gl_lv}環境已經安裝${gl_bai}容器:${gl_lv}$container_count${gl_bai}鏡像:${gl_lv}$image_count${gl_bai}網絡:${gl_lv}$network_count${gl_bai}卷:${gl_lv}$volume_count${gl_bai}"
	fi
}



ldnmp_tato() {
local cert_count=$(ls /home/web/certs/*_cert.pem 2>/dev/null | wc -l)
local output="${gl_lv}${cert_count}${gl_bai}"

local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
if [ -n "$dbrootpasswd" ]; then
	local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
fi

local db_output="${gl_lv}${db_count}${gl_bai}"


if command -v docker &>/dev/null; then
	if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_lv}環境已安裝${gl_bai}站點:$output資料庫:$db_output"
	fi
fi

}


fix_phpfpm_conf() {
	local container_name=$1
	docker exec "$container_name" sh -c "mkdir -p /run/$container_name && chmod 777 /run/$container_name"
	docker exec "$container_name" sh -c "sed -i '1i [global]\\ndaemonize = no' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "sed -i '/^listen =/d' /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "echo -e '\nlisten = /run/$container_name/php-fpm.sock\nlisten.owner = www-data\nlisten.group = www-data\nlisten.mode = 0777' >> /usr/local/etc/php-fpm.d/www.conf"
	docker exec "$container_name" sh -c "rm -f /usr/local/etc/php-fpm.d/zz-docker.conf"

	find /home/web/conf.d/ -type f -name "*.conf" -exec sed -i "s#fastcgi_pass ${container_name}:9000;#fastcgi_pass unix:/run/${container_name}/php-fpm.sock;#g" {} \;

}






linux_ldnmp() {
  while true; do

	clear
	# send_stats "LDNMP建站"
	echo -e "${gl_huang}LDNMP建站"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}安裝LDNMP環境${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}安裝WordPress${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}安裝Discuz論壇${gl_huang}4.   ${gl_bai}安裝可道云桌面"
	echo -e "${gl_huang}5.   ${gl_bai}安裝蘋果CMS影視站${gl_huang}6.   ${gl_bai}安裝獨角數發卡網"
	echo -e "${gl_huang}7.   ${gl_bai}安裝flarum論壇網站${gl_huang}8.   ${gl_bai}安裝typecho輕量博客網站"
	echo -e "${gl_huang}9.   ${gl_bai}安裝LinkStack共享鏈接平台${gl_huang}20.  ${gl_bai}自定義動態站點"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}僅安裝nginx${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}站點重定向"
	echo -e "${gl_huang}23.  ${gl_bai}站點反向代理-IP+端口${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}站點反向代理-域名"
	echo -e "${gl_huang}25.  ${gl_bai}安裝Bitwarden密碼管理平台${gl_huang}26.  ${gl_bai}安裝Halo博客網站"
	echo -e "${gl_huang}27.  ${gl_bai}安裝AI繪畫提示詞生成器${gl_huang}28.  ${gl_bai}站點反向代理-負載均衡"
	echo -e "${gl_huang}29.  ${gl_bai}Stream四層代理轉發${gl_huang}30.  ${gl_bai}自定義靜態站點"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}站點數據管理${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}備份全站數據"
	echo -e "${gl_huang}33.  ${gl_bai}定時遠程備份${gl_huang}34.  ${gl_bai}還原全站數據"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}防護LDNMP環境${gl_huang}36.  ${gl_bai}優化LDNMP環境"
	echo -e "${gl_huang}37.  ${gl_bai}更新LDNMP環境${gl_huang}38.  ${gl_bai}卸載LDNMP環境"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}返回主菜單"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "請輸入你的選擇:" sub_choice


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
	  # Discuz論壇
	  webname="Discuz論壇"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf


	  install_ssltls
	  certs_status
	  add_db


	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20250901.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  ldnmp_web_on
	  echo "數據庫地址: mysql"
	  echo "數據庫名:$dbname"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
	  echo "表前綴: discuz_"


		;;

	  4)
	  clear
	  # 可道云桌面
	  webname="可道云桌面"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status
	  add_db

	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/kalcaddle/kodbox/archive/refs/tags/1.50.02.zip
	  unzip -o latest.zip
	  rm latest.zip
	  mv /home/web/html/$yuming/kodbox* /home/web/html/$yuming/kodbox
	  restart_ldnmp

	  ldnmp_web_on
	  echo "數據庫地址: mysql"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
	  echo "數據庫名:$dbname"
	  echo "redis主機: redis"

		;;

	  5)
	  clear
	  # 蘋果CMS
	  webname="蘋果CMS"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status
	  add_db


	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  # wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && rm maccms10.zip
	  wget ${gh_proxy}github.com/magicblack/maccms_down/raw/master/maccms10.zip && unzip maccms10.zip && mv maccms10-*/* . && rm -r maccms10-* && rm maccms10.zip
	  cd /home/web/html/$yuming/template/ && wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/DYXS2.zip && unzip DYXS2.zip && rm /home/web/html/$yuming/template/DYXS2.zip
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/Dyxs2.php /home/web/html/$yuming/application/admin/controller
	  cp /home/web/html/$yuming/template/DYXS2/asset/admin/dycms.html /home/web/html/$yuming/application/admin/view/system
	  mv /home/web/html/$yuming/admin.php /home/web/html/$yuming/vip.php && wget -O /home/web/html/$yuming/application/extra/maccms.php ${gh_proxy}raw.githubusercontent.com/kejilion/Website_source_code/main/maccms.php

	  restart_ldnmp


	  ldnmp_web_on
	  echo "數據庫地址: mysql"
	  echo "數據庫端口: 3306"
	  echo "數據庫名:$dbname"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
	  echo "數據庫前綴: mac_"
	  echo "------------------------"
	  echo "安裝成功後登錄後台地址"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 獨腳數卡
	  webname="獨腳數卡"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status
	  add_db


	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget ${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

	  restart_ldnmp


	  ldnmp_web_on
	  echo "數據庫地址: mysql"
	  echo "數據庫端口: 3306"
	  echo "數據庫名:$dbname"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
	  echo ""
	  echo "redis地址: redis"
	  echo "redis密碼: 默認不填寫"
	  echo "redis端口: 6379"
	  echo ""
	  echo "網站url: https://$yuming"
	  echo "後台登錄路徑: /admin"
	  echo "------------------------"
	  echo "用戶名: admin"
	  echo "密碼: admin"
	  echo "------------------------"
	  echo "登錄時右上角如果出現紅色error0請使用如下命令:"
	  echo "我也很氣憤獨角數卡為啥這麼麻煩，會有這樣的問題！"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # flarum論壇
	  webname="flarum論壇"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status
	  add_db

	  nginx_http_on

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  docker exec php sh -c "php -r \"copy('https://getcomposer.org/installer', 'composer-setup.php');\""
	  docker exec php sh -c "php composer-setup.php"
	  docker exec php sh -c "php -r \"unlink('composer-setup.php');\""
	  docker exec php sh -c "mv composer.phar /usr/local/bin/composer"

	  docker exec php composer create-project flarum/flarum /var/www/html/$yuming
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum-lang/chinese-simplified"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum/extension-manager:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/sitemap"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/oauth"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/best-answer:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/upload"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/gamification"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/byobu:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"


	  restart_ldnmp


	  ldnmp_web_on
	  echo "數據庫地址: mysql"
	  echo "數據庫名:$dbname"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
	  echo "表前綴: flarum_"
	  echo "管理員信息自行設置"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf


	  install_ssltls
	  certs_status
	  add_db

	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/typecho/typecho/releases/latest/download/typecho.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "數據庫前綴: typecho_"
	  echo "數據庫地址: mysql"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
	  echo "數據庫名:$dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf
	  sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" /home/web/conf.d/$yuming.conf
	  sed -i "s|yuming.com|$yuming|g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status
	  add_db

	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/linkstackorg/linkstack/releases/latest/download/linkstack.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  clear
	  ldnmp_web_on
	  echo "數據庫地址: mysql"
	  echo "數據庫端口: 3306"
	  echo "數據庫名:$dbname"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP動態站點"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status

	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status
	  add_db

	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  clear
	  echo -e "[${gl_huang}1/6${gl_bai}] 上傳PHP源碼"
	  echo "-------------"
	  echo "目前只允許上傳zip格式的源碼包，請將源碼包放到/home/web/html/${yuming}目錄下"
	  read -e -p "也可以輸入下載鏈接，遠程下載源碼包，直接回車將跳過遠程下載：" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] index.php所在路徑"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "請輸入index.php的路徑，類似（/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] 請選擇PHP版本"
	  echo "-------------"
	  read -e -p "1. php最新版 | 2. php7.4 :" pho_v
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
		  echo "無效的選擇，請重新輸入。"
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] 安裝指定擴展"
	  echo "-------------"
	  echo "已經安裝的擴展"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] 編輯站點配置"
	  echo "-------------"
	  echo "按任意鍵繼續，可以詳細設置站點配置，如偽靜態等內容"
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] 數據庫管理"
	  echo "-------------"
	  read -e -p "1. 我搭建新站        2. 我搭建老站有數據庫備份：" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "數據庫備份必須是.gz結尾的壓縮包。請放到/home/目錄下，支持寶塔/1panel備份數據導入。"
			  read -e -p "也可以輸入下載鏈接，遠程下載備份數據，直接回車將跳過遠程下載：" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "數據庫導入的表數據"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "數據庫導入完成"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "數據庫地址: mysql"
	  echo "數據庫名:$dbname"
	  echo "使用者名稱:$dbuse"
	  echo "密碼:$dbusepasswd"
	  echo "表前綴:$prefix"
	  echo "管理員登錄信息自行設置"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站點重定向"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  read -e -p "請輸入跳轉域名:" reverseproxy
	  nginx_install_status


	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status

	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on


		;;

	  23)
	  ldnmp_Proxy
	  find_container_by_host_port "$port"
	  if [ -z "$docker_name" ]; then
		close_port "$port"
		echo "已阻止IP+端口訪問該服務"
	  else
	  	ip_address
		block_container_port "$docker_name" "$ipv4_address"
	  fi

		;;

	  24)
	  clear
	  webname="反向代理-域名"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  echo -e "域名格式:${gl_huang}google.com${gl_bai}"
	  read -e -p "請輸入你的反代域名:" fandai_yuming
	  nginx_install_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|fandaicom|$fandai_yuming|g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status

	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;


	  25)
	  clear
	  webname="Bitwarden"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming

	  docker run -d \
		--name bitwarden \
		--restart=always \
		-p 3280:80 \
		-v /home/web/html/$yuming/bitwarden/data:/data \
		vaultwarden/server

	  duankou=3280
	  ldnmp_Proxy ${yuming} 127.0.0.1 $duankou


		;;

	  26)
	  clear
	  webname="halo"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming

	  docker run -d --name halo --restart=always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2

	  duankou=8010
	  ldnmp_Proxy ${yuming} 127.0.0.1 $duankou

		;;

	  27)
	  clear
	  webname="AI繪畫提示詞生成器"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  nginx_install_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status

	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  wget ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/ai_prompt_generator.zip
	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;

	  28)
	  ldnmp_Proxy_backend
		;;


	  29)
	  stream_panel
		;;

	  30)
	  clear
	  webname="靜態站點"
	  send_stats "安裝$webname"
	  echo "開始部署$webname"
	  add_yuming
	  repeat_add_yuming
	  nginx_install_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	  install_ssltls
	  certs_status

	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming


	  clear
	  echo -e "[${gl_huang}1/2${gl_bai}] 上傳靜態源碼"
	  echo "-------------"
	  echo "目前只允許上傳zip格式的源碼包，請將源碼包放到/home/web/html/${yuming}目錄下"
	  read -e -p "也可以輸入下載鏈接，遠程下載源碼包，直接回車將跳過遠程下載：" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] index.html所在路徑"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "請輸入index.html的路徑，類似（/home/web/html/$yuming/index/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  docker exec nginx chmod -R nginx:nginx /var/www/html
	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;







	31)
	  ldnmp_web_status
	  ;;


	32)
	  clear
	  send_stats "LDNMP環境備份"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}正在備份$backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "備份文件已創建: /home/$backup_filename"
		read -e -p "要傳送備份數據到遠程服務器嗎？ (Y/N):" choice
		case "$choice" in
		  [Yy])
			read -e -p "請輸入遠端服務器IP:" remote_ip
			read -e -p "目標服務器SSH端口 [默認22]:" TARGET_PORT
			local TARGET_PORT=${TARGET_PORT:-22}
			if [ -z "$remote_ip" ]; then
			  echo "錯誤: 請輸入遠端服務器IP。"
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "文件已傳送至遠程服務器home目錄。"
			else
			  echo "未找到要傳送的文件。"
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "無效的選擇，請輸入 Y 或 N。"
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "定時遠程備份"
	  read -e -p "輸入遠程服務器IP:" useip
	  read -e -p "輸入遠程服務器密碼:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. 每周備份                 2. 每天備份"
	  read -e -p "請輸入你的選擇:" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "選擇每周備份的星期幾 (0-6，0代表星期日):" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "選擇每天備份的時間（小時，0-23）:" hour
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
	  send_stats "LDNMP環境還原"
	  echo "可用的站點備份"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "回車鍵還原最新的備份，輸入備份文件名還原指定的備份，輸入0退出：" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # 如果用戶沒有輸入文件名，使用最新的壓縮包
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}正在解壓$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "沒有找到壓縮包。"
	  fi

	  ;;

	35)
		web_security
		;;

	36)
		web_optimization
		;;


	37)
	  root_use
	  while true; do
		  clear
		  send_stats "更新LDNMP環境"
		  echo "更新LDNMP環境"
		  echo "------------------------"
		  ldnmp_v
		  echo "發現新版本的組件"
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
		  echo "5. 更新完整環境"
		  echo "------------------------"
		  echo "0. 返回上一級選單"
		  echo "------------------------"
		  read -e -p "請輸入你的選擇:" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "請輸入${ldnmp_pods}版本號 （如: 8.0 8.3 8.4 9.0）（回車獲取最新版）:" version
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
			  read -e -p "請輸入${ldnmp_pods}版本號 （如: 7.4 8.0 8.1 8.2 8.3）（回車獲取最新版）:" version
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
			  curl -sL ${gh_proxy}github.com/mlocati/docker-php-extension-installer/releases/latest/download/install-php-extensions -o /usr/local/bin/install-php-extensions
			  docker exec php mkdir -p /usr/local/bin/
			  docker cp /usr/local/bin/install-php-extensions php:/usr/local/bin/
			  docker exec php chmod +x /usr/local/bin/install-php-extensions
			  docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis imagick soap


			  docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/max_input_vars.ini' > /dev/null 2>&1

			  fix_phpfpm_con $ldnmp_pods

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
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "完整更新LDNMP環境"
					cd /home/web/
					docker compose down --rmi all

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
		send_stats "卸載LDNMP環境"
		read -e -p "$(echo -e "${gl_hong}强烈建议：${gl_bai}先备份全部网站数据，再卸载LDNMP环境。确定删除所有网站数据吗？(Y/N): ")" choice
		case "$choice" in
		  [Yy])
			cd /home/web/
			docker compose down --rmi all
			docker compose -f docker-compose.phpmyadmin.yml down > /dev/null 2>&1
			docker compose -f docker-compose.phpmyadmin.yml down --rmi all > /dev/null 2>&1
			rm -rf /home/web
			;;
		  [Nn])

			;;
		  *)
			echo "無效的選擇，請輸入 Y 或 N。"
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "無效的輸入!"
	esac
	break_end

  done

}



linux_panel() {

local sub_choice="$1"

clear
cd ~
install git
if [ ! -d apps/.git ]; then
	git clone ${gh_proxy}github.com/kejilion/apps.git
else
	cd apps
	# git pull origin main > /dev/null 2>&1
	git pull ${gh_proxy}github.com/kejilion/apps.git main > /dev/null 2>&1
fi

while true; do

	if [ -z "$sub_choice" ]; then
	  clear
	  echo -e "應用市場"
	  echo -e "${gl_kjlan}-------------------------"

	  local app_numbers=$([ -f /home/docker/appno.txt ] && cat /home/docker/appno.txt || echo "")

	  # 用循環設置顏色
	  for i in {1..150}; do
		  if echo "$app_numbers" | grep -q "^$i$"; then
			  declare "color$i=${gl_lv}"
		  else
			  declare "color$i=${gl_bai}"
		  fi
	  done

	  echo -e "${gl_kjlan}1.   ${color1}寶塔面板官方版${gl_kjlan}2.   ${color2}aaPanel寶塔國際版"
	  echo -e "${gl_kjlan}3.   ${color3}1Panel新一代管理面板${gl_kjlan}4.   ${color4}NginxProxyManager可視化面板"
	  echo -e "${gl_kjlan}5.   ${color5}OpenList多存儲文件列表程序${gl_kjlan}6.   ${color6}Ubuntu遠程桌面網頁版"
	  echo -e "${gl_kjlan}7.   ${color7}哪吒探針VPS監控面板${gl_kjlan}8.   ${color8}QB離線BT磁力下載面板"
	  echo -e "${gl_kjlan}9.   ${color9}Poste.io郵件服務器程序${gl_kjlan}10.  ${color10}RocketChat多人在線聊天系統"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}11.  ${color11}禪道項目管理軟件${gl_kjlan}12.  ${color12}青龍面板定時任務管理平台"
	  echo -e "${gl_kjlan}13.  ${color13}Cloudreve網盤${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${color14}簡單圖床圖片管理程序"
	  echo -e "${gl_kjlan}15.  ${color15}emby多媒體管理系統${gl_kjlan}16.  ${color16}Speedtest測速面板"
	  echo -e "${gl_kjlan}17.  ${color17}AdGuardHome去廣告軟件${gl_kjlan}18.  ${color18}onlyoffice在線辦公OFFICE"
	  echo -e "${gl_kjlan}19.  ${color19}雷池WAF防火牆面板${gl_kjlan}20.  ${color20}portainer容器管理面板"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}21.  ${color21}VScode網頁版${gl_kjlan}22.  ${color22}UptimeKuma監控工具"
	  echo -e "${gl_kjlan}23.  ${color23}Memos網頁備忘錄${gl_kjlan}24.  ${color24}Webtop遠程桌面網頁版${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${color25}Nextcloud網盤${gl_kjlan}26.  ${color26}QD-Today定時任務管理框架"
	  echo -e "${gl_kjlan}27.  ${color27}Dockge容器堆棧管理面板${gl_kjlan}28.  ${color28}LibreSpeed測速工具"
	  echo -e "${gl_kjlan}29.  ${color29}searxng聚合搜索站${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${color30}PhotoPrism私有相冊系統"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}31.  ${color31}StirlingPDF工具大全${gl_kjlan}32.  ${color32}drawio免費的在線圖表軟件${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${color33}Sun-Panel導航面板${gl_kjlan}34.  ${color34}Pingvin-Share文件分享平台"
	  echo -e "${gl_kjlan}35.  ${color35}極簡朋友圈${gl_kjlan}36.  ${color36}LobeChatAI聊天聚合網站"
	  echo -e "${gl_kjlan}37.  ${color37}MyIP工具箱${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${color38}小雅alist全家桶"
	  echo -e "${gl_kjlan}39.  ${color39}Bililive直播錄製工具${gl_kjlan}40.  ${color40}webssh網頁版SSH連接工具"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}41.  ${color41}耗子管理面板${gl_kjlan}42.  ${color42}Nexterm遠程連接工具"
	  echo -e "${gl_kjlan}43.  ${color43}RustDesk遠程桌面(服務端)${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${color44}RustDesk遠程桌面(中繼端)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${color45}Docker加速站${gl_kjlan}46.  ${color46}GitHub加速站${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${color47}普羅米修斯監控${gl_kjlan}48.  ${color48}普羅米修斯(主機監控)"
	  echo -e "${gl_kjlan}49.  ${color49}普羅米修斯(容器監控)${gl_kjlan}50.  ${color50}補貨監控工具"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}51.  ${color51}PVE開小雞面板${gl_kjlan}52.  ${color52}DPanel容器管理面板"
	  echo -e "${gl_kjlan}53.  ${color53}llama3聊天AI大模型${gl_kjlan}54.  ${color54}AMH主機建站管理面板"
	  echo -e "${gl_kjlan}55.  ${color55}FRP內網穿透(服務端)${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${color56}FRP內網穿透(客戶端)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${color57}Deepseek聊天AI大模型${gl_kjlan}58.  ${color58}Dify大模型知識庫${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${color59}NewAPI大模型資產管理${gl_kjlan}60.  ${color60}JumpServer開源堡壘機"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}61.  ${color61}在線翻譯服務器${gl_kjlan}62.  ${color62}RAGFlow大模型知識庫"
	  echo -e "${gl_kjlan}63.  ${color63}OpenWebUI自託管AI平台${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${color64}it-tools工具箱"
	  echo -e "${gl_kjlan}65.  ${color65}n8n自動化工作流平台${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${color66}yt-dlp視頻下載工具"
	  echo -e "${gl_kjlan}67.  ${color67}ddns-go動態DNS管理工具${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${color68}AllinSSL證書管理平台"
	  echo -e "${gl_kjlan}69.  ${color69}SFTPGo文件傳輸工具${gl_kjlan}70.  ${color70}AstrBot聊天機器人框架"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}71.  ${color71}Navidrome私有音樂服務器${gl_kjlan}72.  ${color72}bitwarden密碼管理器${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${color73}LibreTV私有影視${gl_kjlan}74.  ${color74}MoonTV私有影視"
	  echo -e "${gl_kjlan}75.  ${color75}Melody音樂精靈${gl_kjlan}76.  ${color76}在線DOS老遊戲"
	  echo -e "${gl_kjlan}77.  ${color77}迅雷離線下載工具${gl_kjlan}78.  ${color78}PandaWiki智能文檔管理系統"
	  echo -e "${gl_kjlan}79.  ${color79}Beszel服務器監控${gl_kjlan}80.  ${color80}linkwarden書籤管理"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}81.  ${color81}JitsiMeet視頻會議${gl_kjlan}82.  ${color82}gpt-load高性能AI透明代理"
	  echo -e "${gl_kjlan}83.  ${color83}komari服務器監控工具${gl_kjlan}84.  ${color84}Wallos個人財務管理工具"
	  echo -e "${gl_kjlan}85.  ${color85}immich圖片視頻管理器${gl_kjlan}86.  ${color86}jellyfin媒體管理系統"
	  echo -e "${gl_kjlan}87.  ${color87}SyncTV一起看片神器${gl_kjlan}88.  ${color88}Owncast自託管直播平台"
	  echo -e "${gl_kjlan}89.  ${color89}FileCodeBox文件快遞${gl_kjlan}90.  ${color90}matrix去中心化聊天協議"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}91.  ${color91}gitea私有代碼倉庫${gl_kjlan}92.  ${color92}FileBrowser文件管理器"
	  echo -e "${gl_kjlan}93.  ${color93}Dufs極簡靜態文件服務器${gl_kjlan}94.  ${color94}Gopeed高速下載工具"
	  echo -e "${gl_kjlan}95.  ${color95}paperless文檔管理平台${gl_kjlan}96.  ${color96}2FAuth自託管二步驗證器"
	  echo -e "${gl_kjlan}97.  ${color97}WireGuard組網(服務端)${gl_kjlan}98.  ${color98}WireGuard組網(客戶端)"
	  echo -e "${gl_kjlan}99.  ${color99}DSM群暉虛擬機${gl_kjlan}100. ${color100}Syncthing點對點文件同步工具"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}101. ${color101}AI視頻生成工具${gl_kjlan}102. ${color102}VoceChat多人在線聊天系統"
	  echo -e "${gl_kjlan}103. ${color103}Umami網站統計工具${gl_kjlan}104. ${color104}Stream四層代理轉發工具"
	  echo -e "${gl_kjlan}105. ${color105}思源筆記${gl_kjlan}106. ${color106}Drawnix開源白板工具"
	  echo -e "${gl_kjlan}107. ${color107}PanSou網盤搜索${gl_kjlan}108. ${color108}LangBot聊天機器人"
	  echo -e "${gl_kjlan}109. ${color109}ZFile在線網盤${gl_kjlan}110. ${color110}Karakeep書籤管理"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}111. ${color111}多格式文件轉換工具${gl_kjlan}112. ${color112}Lucky大內網穿透工具"
	  echo -e "${gl_kjlan}113. ${color113}Firefox瀏覽器"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}第三方應用列表"
  	  echo -e "${gl_kjlan}想要讓你的應用出現在這裡？查看開發者指南:${gl_huang}https://dev.kejilion.sh/${gl_bai}"

	  for f in "$HOME"/apps/*.conf; do
		  [ -e "$f" ] || continue
		  local base_name=$(basename "$f" .conf)
		  # 獲取應用描述
		  local app_text=$(grep "app_text=" "$f" | cut -d'=' -f2 | tr -d '"' | tr -d "'")

		  # 檢查安裝狀態 (匹配 appno.txt 中的 ID)
		  # 這裡假設 appno.txt 中記錄的是 base_name (即文件名)
		  if echo "$app_numbers" | grep -q "^$base_name$"; then
			  # 如果已安裝：顯示 base_name - 描述 [已安裝] (綠色)
			  echo -e "${gl_kjlan}$base_name${gl_bai} - ${gl_lv}$app_text[已安裝]${gl_bai}"
		  else
			  # 如果未安裝：正常顯示
			  echo -e "${gl_kjlan}$base_name${gl_bai} - $app_text"
		  fi
	  done



	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}b.   ${gl_bai}備份全部應用數據${gl_kjlan}r.   ${gl_bai}還原全部應用數據"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice
	fi

	case $sub_choice in
	  1|bt|baota)
		local app_id="1"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="寶塔面板"
		local panelurl="https://www.bt.cn/new/index.html"

		panel_app_install() {
			if [ -f /usr/bin/curl ];then curl -sSO https://download.bt.cn/install/install_panel.sh;else wget -O install_panel.sh https://download.bt.cn/install/install_panel.sh;fi;bash install_panel.sh ed8484bec
		}

		panel_app_manage() {
			bt
		}

		panel_app_uninstall() {
			curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
			chmod +x bt-uninstall.sh
			./bt-uninstall.sh
		}

		install_panel



		  ;;
	  2|aapanel)


		local app_id="2"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="aapanel"
		local panelurl="https://www.aapanel.com/new/index.html"

		panel_app_install() {
			URL=https://www.aapanel.com/script/install_7.0_en.sh && if [ -f /usr/bin/curl ];then curl -ksSO "$URL" ;else wget --no-check-certificate -O install_7.0_en.sh "$URL";fi;bash install_7.0_en.sh aapanel
		}

		panel_app_manage() {
			bt
		}

		panel_app_uninstall() {
			curl -o bt-uninstall.sh http://download.bt.cn/install/bt-uninstall.sh > /dev/null 2>&1 && chmod +x bt-uninstall.sh && ./bt-uninstall.sh
			chmod +x bt-uninstall.sh
			./bt-uninstall.sh
		}

		install_panel

		  ;;
	  3|1p|1panel)

		local app_id="3"
		local lujing="command -v 1pctl"
		local panelname="1Panel"
		local panelurl="https://1panel.cn/"

		panel_app_install() {
			install bash
			bash -c "$(curl -sSL https://resource.fit2cloud.com/1panel/package/v2/quick_start.sh)"
		}

		panel_app_manage() {
			1pctl user-info
			1pctl update password
		}

		panel_app_uninstall() {
			1pctl uninstall
		}

		install_panel

		  ;;
	  4|npm)

		local app_id="4"
		local docker_name="npm"
		local docker_img="jc21/nginx-proxy-manager:latest"
		local docker_port=81

		docker_rum() {

			docker run -d \
			  --name=$docker_name \
			  -p ${docker_port}:81 \
			  -p 80:80 \
			  -p 443:443 \
			  -v /home/docker/npm/data:/data \
			  -v /home/docker/npm/letsencrypt:/etc/letsencrypt \
			  --restart=always \
			  $docker_img


		}

		local docker_describe="一個Nginx反向代理工具面板，不支持添加域名訪問。"
		local docker_url="官網介紹: https://nginxproxymanager.com/"
		local docker_use="echo \"初始用戶名: admin@example.com\""
		local docker_passwd="echo \"初始密碼: changeme\""
		local app_size="1"

		docker_app

		  ;;

	  5|openlist)

		local app_id="5"
		local docker_name="openlist"
		local docker_img="openlistteam/openlist:latest-aria2"
		local docker_port=5244

		docker_rum() {

			mkdir -p /home/docker/openlist
			chmod -R 777 /home/docker/openlist

			docker run -d \
				--restart=always \
				-v /home/docker/openlist:/opt/openlist/data \
				-p ${docker_port}:5244 \
				-e PUID=0 \
				-e PGID=0 \
				-e UMASK=022 \
				--name="openlist" \
				openlistteam/openlist:latest-aria2

		}


		local docker_describe="一個支持多種存儲，支持網頁瀏覽和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驅動"
		local docker_url="官網介紹: https://github.com/OpenListTeam/OpenList"
		local docker_use="docker exec openlist ./openlist admin random"
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  6|webtop-ubuntu)

		local app_id="6"
		local docker_name="webtop-ubuntu"
		local docker_img="lscr.io/linuxserver/webtop:ubuntu-kde"
		local docker_port=3006

		docker_rum() {

			read -e -p "設置登錄用戶名:" admin
			read -e -p "設置登錄用戶密碼:" admin_password
			docker run -d \
			  --name=webtop-ubuntu \
			  --security-opt seccomp=unconfined \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -e TZ=Etc/UTC \
			  -e SUBFOLDER=/ \
			  -e TITLE=Webtop \
			  -e CUSTOM_USER=${admin} \
			  -e PASSWORD=${admin_password} \
			  -p ${docker_port}:3000 \
			  -v /home/docker/webtop/data:/config \
			  -v /var/run/docker.sock:/var/run/docker.sock \
			  --shm-size="1gb" \
			  --restart=always \
			  lscr.io/linuxserver/webtop:ubuntu-kde


		}


		local docker_describe="webtop基於Ubuntu的容器。若IP無法訪問，請添加域名訪問。"
		local docker_url="官網介紹: https://docs.linuxserver.io/images/docker-webtop/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app


		  ;;
	  7|nezha)
		clear
		send_stats "搭建哪吒"

		local app_id="7"
		local docker_name="nezha-dashboard"
		local docker_port=8008
		while true; do
			check_docker_app
			check_docker_image_update $docker_name
			clear
			echo -e "哪吒監控$check_docker $update_status"
			echo "開源、輕量、易用的服務器監控與運維工具"
			echo "官網搭建文檔: https://nezha.wiki/guide/dashboard.html"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
				check_docker_app_ip
			fi
			echo ""
			echo "------------------------"
			echo "1. 使用"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			read -e -p "輸入你的選擇:" choice

			case $choice in
				1)
					check_disk_space 1
					install unzip jq
					install_docker
					curl -sL ${gh_proxy}raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && ./nezha.sh
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
					;;

				*)
					break
					;;

			esac
			break_end
		done
		  ;;

	  8|qb|QB)

		local app_id="8"
		local docker_name="qbittorrent"
		local docker_img="lscr.io/linuxserver/qbittorrent:latest"
		local docker_port=8081

		docker_rum() {

			docker run -d \
			  --name=qbittorrent \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -e TZ=Etc/UTC \
			  -e WEBUI_PORT=${docker_port} \
			  -e TORRENTING_PORT=56881 \
			  -p ${docker_port}:${docker_port} \
			  -p 56881:56881 \
			  -p 56881:56881/udp \
			  -v /home/docker/qbittorrent/config:/config \
			  -v /home/docker/qbittorrent/downloads:/downloads \
			  --restart=always \
			  lscr.io/linuxserver/qbittorrent:latest

		}

		local docker_describe="qbittorrent離線BT磁力下載服務"
		local docker_url="官網介紹: https://hub.docker.com/r/linuxserver/qbittorrent"
		local docker_use="sleep 3"
		local docker_passwd="docker logs qbittorrent"
		local app_size="1"
		docker_app

		  ;;

	  9|mail)
		send_stats "搭建郵局"
		clear
		install telnet
		local app_id="9"
		local docker_name=“mailserver”
		while true; do
			check_docker_app
			check_docker_image_update $docker_name

			clear
			echo -e "郵局服務$check_docker $update_status"
			echo "poste.io 是一個開源的郵件服務器解決方案，"
			echo "視頻介紹: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

			echo ""
			echo "端口檢測"
			port=25
			timeout=3
			if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
			  echo -e "${gl_lv}端口$port當前可用${gl_bai}"
			else
			  echo -e "${gl_hong}端口$port當前不可用${gl_bai}"
			fi
			echo ""

			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				yuming=$(cat /home/docker/mail.txt)
				echo "訪問地址:"
				echo "https://$yuming"
			fi

			echo "------------------------"
			echo "1. 安裝           2. 更新           3. 卸載"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			read -e -p "輸入你的選擇:" choice

			case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "請設置郵箱域名 例如 mail.yuming.com :" yuming
					mkdir -p /home/docker
					echo "$yuming" > /home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "先解析這些DNS記錄"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo ""
					echo "------------------------"
					echo "按任意鍵繼續..."
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


					add_app_id

					clear
					echo "poste.io已經安裝完成"
					echo "------------------------"
					echo "您可以使用以下地址訪問poste.io:"
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


					add_app_id

					clear
					echo "poste.io已經安裝完成"
					echo "------------------------"
					echo "您可以使用以下地址訪問poste.io:"
					echo "https://$yuming"
					echo ""
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "應用已卸載"
					;;

				*)
					break
					;;

			esac
			break_end
		done

		  ;;

	  10|rocketchat)

		local app_id="10"
		local app_name="Rocket.Chat聊天系統"
		local app_text="Rocket.Chat 是一個開源的團隊通訊平台，支持實時聊天、音視頻通話、文件共享等多種功能，"
		local app_url="官方介紹: https://www.rocket.chat/"
		local docker_name="rocketchat"
		local docker_port="3897"
		local app_size="2"

		docker_app_install() {
			docker run --name db -d --restart=always \
				-v /home/docker/mongo/dump:/dump \
				mongo:latest --replSet rs5 --oplogSize 256
			sleep 1
			docker exec db mongosh --eval "printjson(rs.initiate())"
			sleep 5
			docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

			clear
			ip_address
			echo "已經安裝完成"
			check_docker_app_ip
		}

		docker_app_update() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat:latest
			docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
			clear
			ip_address
			echo "rocket.chat已經安裝完成"
			check_docker_app_ip
		}

		docker_app_uninstall() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat
			docker rm -f db
			docker rmi -f mongo:latest
			rm -rf /home/docker/mongo
			echo "應用已卸載"
		}

		docker_app_plus
		  ;;



	  11|zentao)
		local app_id="11"
		local docker_name="zentao-server"
		local docker_img="idoop/zentao:latest"
		local docker_port=82


		docker_rum() {


			docker run -d -p ${docker_port}:80 \
			  -e ADMINER_USER="root" -e ADMINER_PASSWD="password" \
			  -e BIND_ADDRESS="false" \
			  -v /home/docker/zentao-server/:/opt/zbox/ \
			  --add-host smtp.exmail.qq.com:163.177.90.125 \
			  --name zentao-server \
			  --restart=always \
			  idoop/zentao:latest


		}

		local docker_describe="禪道是通用的項目管理軟件"
		local docker_url="官網介紹: https://www.zentao.net/"
		local docker_use="echo \"初始用戶名: admin\""
		local docker_passwd="echo \"初始密碼: 123456\""
		local app_size="2"
		docker_app

		  ;;

	  12|qinglong)
		local app_id="12"
		local docker_name="qinglong"
		local docker_img="whyour/qinglong:latest"
		local docker_port=5700

		docker_rum() {


			docker run -d \
			  -v /home/docker/qinglong/data:/ql/data \
			  -p ${docker_port}:5700 \
			  --name qinglong \
			  --hostname qinglong \
			  --restart=always \
			  whyour/qinglong:latest


		}

		local docker_describe="青龍面板是一個定時任務管理平台"
		local docker_url="官網介紹:${gh_proxy}github.com/whyour/qinglong"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  13|cloudreve)

		local app_id="13"
		local app_name="cloudreve網盤"
		local app_text="cloudreve是一個支持多家云存儲的網盤系統"
		local app_url="視頻介紹: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
		local docker_name="cloudreve"
		local docker_port="5212"
		local app_size="2"

		docker_app_install() {
			cd /home/ && mkdir -p docker/cloud && cd docker/cloud && mkdir temp_data && mkdir -vp cloudreve/{uploads,avatar} && touch cloudreve/conf.ini && touch cloudreve/cloudreve.db && mkdir -p aria2/config && mkdir -p data/aria2 && chmod -R 777 data/aria2
			curl -o /home/docker/cloud/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/cloudreve-docker-compose.yml
			sed -i "s/5212:5212/${docker_port}:5212/g" /home/docker/cloud/docker-compose.yml
			cd /home/docker/cloud/
			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			cd /home/docker/cloud/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			rm -rf /home/docker/cloud
			echo "應用已卸載"
		}

		docker_app_plus
		  ;;

	  14|easyimage)
		local app_id="14"
		local docker_name="easyimage"
		local docker_img="ddsderek/easyimage:latest"
		local docker_port=8014
		docker_rum() {

			docker run -d \
			  --name easyimage \
			  -p ${docker_port}:80 \
			  -e TZ=Asia/Shanghai \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -v /home/docker/easyimage/config:/app/web/config \
			  -v /home/docker/easyimage/i:/app/web/i \
			  --restart=always \
			  ddsderek/easyimage:latest

		}

		local docker_describe="簡單圖床是一個簡單的圖床程序"
		local docker_url="官網介紹:${gh_proxy}github.com/icret/EasyImages2.0"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  15|emby)
		local app_id="15"
		local docker_name="emby"
		local docker_img="linuxserver/emby:latest"
		local docker_port=8015

		docker_rum() {

			docker run -d --name=emby --restart=always \
				-v /home/docker/emby/config:/config \
				-v /home/docker/emby/share1:/mnt/share1 \
				-v /home/docker/emby/share2:/mnt/share2 \
				-v /mnt/notify:/mnt/notify \
				-p ${docker_port}:8096 \
				-e UID=1000 -e GID=100 -e GIDLIST=100 \
				linuxserver/emby:latest

		}


		local docker_describe="emby是一個主從式架構的媒體服務器軟件，可以用來整理服務器上的視頻和音頻，並將音頻和視頻流式傳輸到客戶端設備"
		local docker_url="官網介紹: https://emby.media/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  16|looking)
		local app_id="16"
		local docker_name="looking-glass"
		local docker_img="wikihostinc/looking-glass-server"
		local docker_port=8016


		docker_rum() {

			docker run -d --name looking-glass --restart=always -p ${docker_port}:80 wikihostinc/looking-glass-server

		}

		local docker_describe="Speedtest測速面板是一個VPS網速測試工具，多項測試功能，還可以實時監控VPS進出站流量"
		local docker_url="官網介紹:${gh_proxy}github.com/wikihost-opensource/als"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  17|adguardhome)

		local app_id="17"
		local docker_name="adguardhome"
		local docker_img="adguard/adguardhome"
		local docker_port=8017

		docker_rum() {

			docker run -d \
				--name adguardhome \
				-v /home/docker/adguardhome/work:/opt/adguardhome/work \
				-v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
				-p 53:53/tcp \
				-p 53:53/udp \
				-p ${docker_port}:3000/tcp \
				--restart=always \
				adguard/adguardhome


		}


		local docker_describe="AdGuardHome是一款全網廣告攔截與反跟踪軟件，未來將不止是一個DNS服務器。"
		local docker_url="官網介紹: https://hub.docker.com/r/adguard/adguardhome"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  18|onlyoffice)

		local app_id="18"
		local docker_name="onlyoffice"
		local docker_img="onlyoffice/documentserver"
		local docker_port=8018

		docker_rum() {

			docker run -d -p ${docker_port}:80 \
				--restart=always \
				--name onlyoffice \
				-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
				-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
				 onlyoffice/documentserver


		}

		local docker_describe="onlyoffice是一款開源的在線office工具，太強大了！"
		local docker_url="官網介紹: https://www.onlyoffice.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app

		  ;;

	  19|safeline)
		send_stats "搭建雷池"

		local app_id="19"
		local docker_name=safeline-mgt
		local docker_port=9443
		while true; do
			check_docker_app
			clear
			echo -e "雷池服務$check_docker"
			echo "雷池是長亭科技開發的WAF站點防火牆程序面板，可以反代站點進行自動化防禦"
			echo "視頻介紹: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				check_docker_app_ip
			fi
			echo ""

			echo "------------------------"
			echo "1. 安裝           2. 更新           3. 重置密碼           4. 卸載"
			echo "------------------------"
			echo "0. 返回上一級選單"
			echo "------------------------"
			read -e -p "輸入你的選擇:" choice

			case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "雷池WAF面板已經安裝完成"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "雷池WAF面板已經更新完成"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "如果你是默認安裝目錄那現在項目已經卸載。如果你是自定義安裝目錄你需要到安裝目錄下自行執行:"
					echo "docker compose down && docker compose down --rmi all"
					;;
				*)
					break
					;;

			esac
			break_end
		done

		  ;;

	  20|portainer)
		local app_id="20"
		local docker_name="portainer"
		local docker_img="portainer/portainer"
		local docker_port=8020

		docker_rum() {

			docker run -d \
				--name portainer \
				-p ${docker_port}:9000 \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-v /home/docker/portainer:/data \
				--restart=always \
				portainer/portainer

		}


		local docker_describe="portainer是一個輕量級的docker容器管理面板"
		local docker_url="官網介紹: https://www.portainer.io/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  21|vscode)
		local app_id="21"
		local docker_name="vscode-web"
		local docker_img="codercom/code-server"
		local docker_port=8021


		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart=always codercom/code-server

		}


		local docker_describe="VScode是一款強大的在線代碼編寫工具"
		local docker_url="官網介紹:${gh_proxy}github.com/coder/code-server"
		local docker_use="sleep 3"
		local docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
		local app_size="1"
		docker_app
		  ;;


	  22|uptime-kuma)
		local app_id="22"
		local docker_name="uptime-kuma"
		local docker_img="louislam/uptime-kuma:latest"
		local docker_port=8022


		docker_rum() {

			docker run -d \
				--name=uptime-kuma \
				-p ${docker_port}:3001 \
				-v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
				--restart=always \
				louislam/uptime-kuma:latest

		}


		local docker_describe="Uptime Kuma 易於使用的自託管監控工具"
		local docker_url="官網介紹:${gh_proxy}github.com/louislam/uptime-kuma"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  23|memos)
		local app_id="23"
		local docker_name="memos"
		local docker_img="neosmemo/memos:stable"
		local docker_port=8023

		docker_rum() {

			docker run -d --name memos -p ${docker_port}:5230 -v /home/docker/memos:/var/opt/memos --restart=always neosmemo/memos:stable

		}

		local docker_describe="Memos是一款輕量級、自託管的備忘錄中心"
		local docker_url="官網介紹:${gh_proxy}github.com/usememos/memos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  24|webtop)
		local app_id="24"
		local docker_name="webtop"
		local docker_img="lscr.io/linuxserver/webtop:latest"
		local docker_port=8024

		docker_rum() {

			read -e -p "設置登錄用戶名:" admin
			read -e -p "設置登錄用戶密碼:" admin_password
			docker run -d \
			  --name=webtop \
			  --security-opt seccomp=unconfined \
			  -e PUID=1000 \
			  -e PGID=1000 \
			  -e TZ=Etc/UTC \
			  -e SUBFOLDER=/ \
			  -e TITLE=Webtop \
			  -e CUSTOM_USER=${admin} \
			  -e PASSWORD=${admin_password} \
			  -e LC_ALL=zh_CN.UTF-8 \
			  -e DOCKER_MODS=linuxserver/mods:universal-package-install \
			  -e INSTALL_PACKAGES=font-noto-cjk \
			  -p ${docker_port}:3000 \
			  -v /home/docker/webtop/data:/config \
			  -v /var/run/docker.sock:/var/run/docker.sock \
			  --shm-size="1gb" \
			  --restart=always \
			  lscr.io/linuxserver/webtop:latest

		}


		local docker_describe="webtop基於Alpine的中文版容器。若IP無法訪問，請添加域名訪問。"
		local docker_url="官網介紹: https://docs.linuxserver.io/images/docker-webtop/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app
		  ;;

	  25|nextcloud)
		local app_id="25"
		local docker_name="nextcloud"
		local docker_img="nextcloud:latest"
		local docker_port=8025
		local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

		docker_rum() {

			docker run -d --name nextcloud --restart=always -p ${docker_port}:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud

		}

		local docker_describe="Nextcloud擁有超過 400,000 個部署，是您可以下載的最受歡迎的本地內容協作平台"
		local docker_url="官網介紹: https://nextcloud.com/"
		local docker_use="echo \"賬號: nextcloud  密碼:$rootpasswd\""
		local docker_passwd=""
		local app_size="3"
		docker_app
		  ;;

	  26|qd)
		local app_id="26"
		local docker_name="qd"
		local docker_img="qdtoday/qd:latest"
		local docker_port=8026

		docker_rum() {

			docker run -d --name qd -p ${docker_port}:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd

		}

		local docker_describe="QD-Today是一個HTTP請求定時任務自動執行框架"
		local docker_url="官網介紹: https://qd-today.github.io/qd/zh_CN/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  27|dockge)
		local app_id="27"
		local docker_name="dockge"
		local docker_img="louislam/dockge:latest"
		local docker_port=8027

		docker_rum() {

			docker run -d --name dockge --restart=always -p ${docker_port}:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v  /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge

		}

		local docker_describe="dockge是一個可視化的docker-compose容器管理面板"
		local docker_url="官網介紹:${gh_proxy}github.com/louislam/dockge"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  28|speedtest)
		local app_id="28"
		local docker_name="speedtest"
		local docker_img="ghcr.io/librespeed/speedtest"
		local docker_port=8028

		docker_rum() {

			docker run -d -p ${docker_port}:8080 --name speedtest --restart=always ghcr.io/librespeed/speedtest

		}

		local docker_describe="librespeed是用Javascript實現的輕量級速度測試工具，即開即用"
		local docker_url="官網介紹:${gh_proxy}github.com/librespeed/speedtest"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  29|searxng)
		local app_id="29"
		local docker_name="searxng"
		local docker_img="searxng/searxng"
		local docker_port=8029

		docker_rum() {

			docker run -d \
			  --name searxng \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -v "/home/docker/searxng:/etc/searxng" \
			  searxng/searxng

		}

		local docker_describe="searxng是一個私有且隱私的搜索引擎站點"
		local docker_url="官網介紹: https://hub.docker.com/r/alandoyle/searxng"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  30|photoprism)
		local app_id="30"
		local docker_name="photoprism"
		local docker_img="photoprism/photoprism:latest"
		local docker_port=8030
		local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

		docker_rum() {

			docker run -d \
				--name photoprism \
				--restart=always \
				--security-opt seccomp=unconfined \
				--security-opt apparmor=unconfined \
				-p ${docker_port}:2342 \
				-e PHOTOPRISM_UPLOAD_NSFW="true" \
				-e PHOTOPRISM_ADMIN_PASSWORD="$rootpasswd" \
				-v /home/docker/photoprism/storage:/photoprism/storage \
				-v /home/docker/photoprism/Pictures:/photoprism/originals \
				photoprism/photoprism

		}


		local docker_describe="photoprism非常強大的私有相冊系統"
		local docker_url="官網介紹: https://www.photoprism.app/"
		local docker_use="echo \"賬號: admin  密碼:$rootpasswd\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  31|s-pdf)
		local app_id="31"
		local docker_name="s-pdf"
		local docker_img="frooodle/s-pdf:latest"
		local docker_port=8031

		docker_rum() {

			docker run -d \
				--name s-pdf \
				--restart=always \
				 -p ${docker_port}:8080 \
				 -v /home/docker/s-pdf/trainingData:/usr/share/tesseract-ocr/5/tessdata \
				 -v /home/docker/s-pdf/extraConfigs:/configs \
				 -v /home/docker/s-pdf/logs:/logs \
				 -e DOCKER_ENABLE_SECURITY=false \
				 frooodle/s-pdf:latest
		}

		local docker_describe="這是一個強大的本地託管基於 Web 的 PDF 操作工具，使用 docker，允許您對 PDF 文件執行各種操作，例如拆分合併、轉換、重新組織、添加圖像、旋轉、壓縮等。"
		local docker_url="官網介紹:${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  32|drawio)
		local app_id="32"
		local docker_name="drawio"
		local docker_img="jgraph/drawio"
		local docker_port=8032

		docker_rum() {

			docker run -d --restart=always --name drawio -p ${docker_port}:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio

		}


		local docker_describe="這是一個強大圖表繪製軟件。思維導圖，拓撲圖，流程圖，都能畫"
		local docker_url="官網介紹: https://www.drawio.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  33|sun-panel)
		local app_id="33"
		local docker_name="sun-panel"
		local docker_img="hslr/sun-panel"
		local docker_port=8033

		docker_rum() {

			docker run -d --restart=always -p ${docker_port}:3002 \
				-v /home/docker/sun-panel/conf:/app/conf \
				-v /home/docker/sun-panel/uploads:/app/uploads \
				-v /home/docker/sun-panel/database:/app/database \
				--name sun-panel \
				hslr/sun-panel

		}

		local docker_describe="Sun-Panel服務器、NAS導航面板、Homepage、瀏覽器首頁"
		local docker_url="官網介紹: https://doc.sun-panel.top/zh_cn/"
		local docker_use="echo \"賬號: admin@sun.cc  密碼: 12345678\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  34|pingvin-share)
		local app_id="34"
		local docker_name="pingvin-share"
		local docker_img="stonith404/pingvin-share"
		local docker_port=8034

		docker_rum() {

			docker run -d \
				--name pingvin-share \
				--restart=always \
				-p ${docker_port}:3000 \
				-v /home/docker/pingvin-share/data:/opt/app/backend/data \
				stonith404/pingvin-share
		}

		local docker_describe="Pingvin Share 是一個可自建的文件分享平台，是 WeTransfer 的一個替代品"
		local docker_url="官網介紹:${gh_proxy}github.com/stonith404/pingvin-share"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  35|moments)
		local app_id="35"
		local docker_name="moments"
		local docker_img="kingwrcy/moments:latest"
		local docker_port=8035

		docker_rum() {

			docker run -d --restart=always \
				-p ${docker_port}:3000 \
				-v /home/docker/moments/data:/app/data \
				-v /etc/localtime:/etc/localtime:ro \
				-v /etc/timezone:/etc/timezone:ro \
				--name moments \
				kingwrcy/moments:latest
		}


		local docker_describe="極簡朋友圈，高仿微信朋友圈，記錄你的美好生活"
		local docker_url="官網介紹:${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
		local docker_use="echo \"賬號: admin  密碼: a123456\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;



	  36|lobe-chat)
		local app_id="36"
		local docker_name="lobe-chat"
		local docker_img="lobehub/lobe-chat:latest"
		local docker_port=8036

		docker_rum() {

			docker run -d -p ${docker_port}:3210 \
				--name lobe-chat \
				--restart=always \
				lobehub/lobe-chat
		}

		local docker_describe="LobeChat聚合市面上主流的AI大模型，ChatGPT/Claude/Gemini/Groq/Ollama"
		local docker_url="官網介紹:${gh_proxy}github.com/lobehub/lobe-chat"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app
		  ;;

	  37|myip)
		local app_id="37"
		local docker_name="myip"
		local docker_img="jason5ng32/myip:latest"
		local docker_port=8037

		docker_rum() {

			docker run -d -p ${docker_port}:18966 --name myip jason5ng32/myip:latest

		}


		local docker_describe="是一個多功能IP工具箱，可以查看自己IP信息及連通性，用網頁面板呈現"
		local docker_url="官網介紹:${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  38|xiaoya)
		send_stats "小雅全家桶"
		clear
		install_docker
		check_disk_space 1
		bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
		  ;;

	  39|bililive)

		if [ ! -d /home/docker/bililive-go/ ]; then
			mkdir -p /home/docker/bililive-go/ > /dev/null 2>&1
			wget -O /home/docker/bililive-go/config.yml ${gh_proxy}raw.githubusercontent.com/hr3lxphr6j/bililive-go/master/config.yml > /dev/null 2>&1
		fi

		local app_id="39"
		local docker_name="bililive-go"
		local docker_img="chigusa/bililive-go"
		local docker_port=8039

		docker_rum() {

			docker run --restart=always --name bililive-go -v /home/docker/bililive-go/config.yml:/etc/bililive-go/config.yml -v /home/docker/bililive-go/Videos:/srv/bililive -p ${docker_port}:8080 -d chigusa/bililive-go

		}

		local docker_describe="Bililive-go是一個支持多種直播平台的直播錄製工具"
		local docker_url="官網介紹:${gh_proxy}github.com/hr3lxphr6j/bililive-go"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  40|webssh)
		local app_id="40"
		local docker_name="webssh"
		local docker_img="jrohy/webssh"
		local docker_port=8040
		docker_rum() {
			docker run -d -p ${docker_port}:5032 --restart=always --name webssh -e TZ=Asia/Shanghai jrohy/webssh
		}

		local docker_describe="簡易在線ssh連接工具和sftp工具"
		local docker_url="官網介紹:${gh_proxy}github.com/Jrohy/webssh"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  41|haozi)

		local app_id="41"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="耗子麵板"
		local panelurl="官方地址:${gh_proxy}github.com/TheTNB/panel"

		panel_app_install() {
			mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o install.sh https://dl.cdn.haozi.net/panel/install.sh && bash install.sh
			cd ~
		}

		panel_app_manage() {
			panel-cli
		}

		panel_app_uninstall() {
			mkdir -p ~/haozi && cd ~/haozi && curl -fsLm 10 -o uninstall.sh https://dl.cdn.haozi.net/panel/uninstall.sh && bash uninstall.sh
			cd ~
		}

		install_panel

		  ;;


	  42|nexterm)
		local app_id="42"
		local docker_name="nexterm"
		local docker_img="germannewsmaker/nexterm:latest"
		local docker_port=8042

		docker_rum() {

			ENCRYPTION_KEY=$(openssl rand -hex 32)
			docker run -d \
			  --name nexterm \
			  -e ENCRYPTION_KEY=${ENCRYPTION_KEY} \
			  -p ${docker_port}:6989 \
			  -v /home/docker/nexterm:/app/data \
			  --restart=always \
			  germannewsmaker/nexterm:latest

		}

		local docker_describe="nexterm是一款強大的在線SSH/VNC/RDP連接工具。"
		local docker_url="官網介紹:${gh_proxy}github.com/gnmyt/Nexterm"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  43|hbbs)
		local app_id="43"
		local docker_name="hbbs"
		local docker_img="rustdesk/rustdesk-server"
		local docker_port=0000

		docker_rum() {

			docker run --name hbbs -v /home/docker/hbbs/data:/root -td --net=host --restart=always rustdesk/rustdesk-server hbbs

		}


		local docker_describe="rustdesk開源的遠程桌面(服務端)，類似自己的向日葵私服。"
		local docker_url="官網介紹: https://rustdesk.com/zh-cn/"
		local docker_use="docker logs hbbs"
		local docker_passwd="echo \"把你的IP和key記錄下，會在遠程桌面客戶端中用到。去44選項裝中繼端吧！\""
		local app_size="1"
		docker_app
		  ;;

	  44|hbbr)
		local app_id="44"
		local docker_name="hbbr"
		local docker_img="rustdesk/rustdesk-server"
		local docker_port=0000

		docker_rum() {

			docker run --name hbbr -v /home/docker/hbbr/data:/root -td --net=host --restart=always rustdesk/rustdesk-server hbbr

		}

		local docker_describe="rustdesk開源的遠程桌面(中繼端)，類似自己的向日葵私服。"
		local docker_url="官網介紹: https://rustdesk.com/zh-cn/"
		local docker_use="echo \"前往官網下載遠程桌面的客戶端: https://rustdesk.com/zh-cn/\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  45|registry)
		local app_id="45"
		local docker_name="registry"
		local docker_img="registry:2"
		local docker_port=8045

		docker_rum() {

			docker run -d \
				-p ${docker_port}:5000 \
				--name registry \
				-v /home/docker/registry:/var/lib/registry \
				-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
				--restart=always \
				registry:2

		}

		local docker_describe="Docker Registry 是一個用於存儲和分發 Docker 鏡像的服務。"
		local docker_url="官網介紹: https://hub.docker.com/_/registry"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app
		  ;;

	  46|ghproxy)
		local app_id="46"
		local docker_name="ghproxy"
		local docker_img="wjqserver/ghproxy:latest"
		local docker_port=8046

		docker_rum() {

			docker run -d --name ghproxy --restart=always -p ${docker_port}:8080 -v /home/docker/ghproxy/config:/data/ghproxy/config wjqserver/ghproxy:latest

		}

		local docker_describe="使用Go實現的GHProxy，用於加速部分地區Github倉庫的拉取。"
		local docker_url="官網介紹: https://github.com/WJQSERVER-STUDIO/ghproxy"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  47|prometheus|grafana)

		local app_id="47"
		local app_name="普羅米修斯監控"
		local app_text="Prometheus+Grafana企業級監控系統"
		local app_url="官網介紹: https://prometheus.io"
		local docker_name="grafana"
		local docker_port="8047"
		local app_size="2"

		docker_app_install() {
			prometheus_install
			clear
			ip_address
			echo "已經安裝完成"
			check_docker_app_ip
			echo "初始用戶名密碼均為: admin"
		}

		docker_app_update() {
			docker rm -f node-exporter prometheus grafana
			docker rmi -f prom/node-exporter
			docker rmi -f prom/prometheus:latest
			docker rmi -f grafana/grafana:latest
			docker_app_install
		}

		docker_app_uninstall() {
			docker rm -f node-exporter prometheus grafana
			docker rmi -f prom/node-exporter
			docker rmi -f prom/prometheus:latest
			docker rmi -f grafana/grafana:latest

			rm -rf /home/docker/monitoring
			echo "應用已卸載"
		}

		docker_app_plus
		  ;;

	  48|node-exporter)
		local app_id="48"
		local docker_name="node-exporter"
		local docker_img="prom/node-exporter"
		local docker_port=8048

		docker_rum() {

			docker run -d \
				--name=node-exporter \
				-p ${docker_port}:9100 \
				--restart=always \
				prom/node-exporter


		}

		local docker_describe="這是一個普羅米修斯的主機數據採集組件，請部署在被監控主機上。"
		local docker_url="官網介紹: https://github.com/prometheus/node_exporter"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  49|cadvisor)
		local app_id="49"
		local docker_name="cadvisor"
		local docker_img="gcr.io/cadvisor/cadvisor:latest"
		local docker_port=8049

		docker_rum() {

			docker run -d \
				--name=cadvisor \
				--restart=always \
				-p ${docker_port}:8080 \
				--volume=/:/rootfs:ro \
				--volume=/var/run:/var/run:rw \
				--volume=/sys:/sys:ro \
				--volume=/var/lib/docker/:/var/lib/docker:ro \
				gcr.io/cadvisor/cadvisor:latest \
				-housekeeping_interval=10s \
				-docker_only=true

		}

		local docker_describe="這是一個普羅米修斯的容器數據採集組件，請部署在被監控主機上。"
		local docker_url="官網介紹: https://github.com/google/cadvisor"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  50|changedetection)
		local app_id="50"
		local docker_name="changedetection"
		local docker_img="dgtlmoon/changedetection.io:latest"
		local docker_port=8050

		docker_rum() {

			docker run -d --restart=always -p ${docker_port}:5000 \
				-v /home/docker/datastore:/datastore \
				--name changedetection dgtlmoon/changedetection.io:latest

		}

		local docker_describe="這是一款網站變化檢測、補貨監控和通知的小工具"
		local docker_url="官網介紹: https://github.com/dgtlmoon/changedetection.io"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  51|pve)
		clear
		send_stats "PVE開小雞"
		check_disk_space 1
		curl -L ${gh_proxy}raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
		  ;;


	  52|dpanel)
		local app_id="52"
		local docker_name="dpanel"
		local docker_img="dpanel/dpanel:lite"
		local docker_port=8052

		docker_rum() {

			docker run -d --name dpanel --restart=always \
				-p ${docker_port}:8080 -e APP_NAME=dpanel \
				-v /var/run/docker.sock:/var/run/docker.sock \
				-v /home/docker/dpanel:/dpanel \
				dpanel/dpanel:lite

		}

		local docker_describe="Docker可視化面板系統，提供完善的docker管理功能。"
		local docker_url="官網介紹: https://github.com/donknap/dpanel"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  53|llama3)
		local app_id="53"
		local docker_name="ollama"
		local docker_img="ghcr.io/open-webui/open-webui:ollama"
		local docker_port=8053

		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart=always ghcr.io/open-webui/open-webui:ollama

		}

		local docker_describe="OpenWebUI一款大語言模型網頁框架，接入全新的llama3大語言模型"
		local docker_url="官網介紹: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run llama3.2:1b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;

	  54|amh)

		local app_id="54"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="AMH面板"
		local panelurl="官方地址: https://amh.sh/index.htm?amh"

		panel_app_install() {
			cd ~
			wget https://dl.amh.sh/amh.sh && bash amh.sh
		}

		panel_app_manage() {
			panel_app_install
		}

		panel_app_uninstall() {
			panel_app_install
		}

		install_panel
		  ;;


	  55|frps)
		frps_panel
		  ;;

	  56|frpc)
		frpc_panel
		  ;;

	  57|deepseek)
		local app_id="57"
		local docker_name="ollama"
		local docker_img="ghcr.io/open-webui/open-webui:ollama"
		local docker_port=8053

		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart=always ghcr.io/open-webui/open-webui:ollama

		}

		local docker_describe="OpenWebUI一款大語言模型網頁框架，接入全新的DeepSeek R1大語言模型"
		local docker_url="官網介紹: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;


	  58|dify)
		local app_id="58"
		local app_name="Dify知識庫"
		local app_text="是一款開源的大語言模型(LLM) 應用開發平台。自託管訓練數據用於AI生成"
		local app_url="官方網站: https://docs.dify.ai/zh-hans"
		local docker_name="docker-nginx-1"
		local docker_port="8058"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/langgenius/dify.git && cd dify/docker && cp .env.example .env
			sed -i "s/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/" /home/docker/dify/docker/.env

			docker compose up -d

			chown -R 1001:1001 /home/docker/dify/docker/volumes/app/storage
			chmod -R 755 /home/docker/dify/docker/volumes/app/storage
			docker compose down
			docker compose up -d

			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/dify/docker/ && docker compose down --rmi all
			cd  /home/docker/dify/
			git pull ${gh_proxy}github.com/langgenius/dify.git main > /dev/null 2>&1
			sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=8058/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
			cd  /home/docker/dify/docker/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/dify/docker/ && docker compose down --rmi all
			rm -rf /home/docker/dify
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;

	  59|new-api)
		local app_id="59"
		local app_name="NewAPI"
		local app_text="新一代大模型網關與AI資產管理系統"
		local app_url="官方網站: https://github.com/Calcium-Ion/new-api"
		local docker_name="new-api"
		local docker_port="8059"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/Calcium-Ion/new-api.git && cd new-api

			sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
				   -e 's/container_name: redis/container_name: redis-new-api/g' \
				   -e 's/container_name: mysql/container_name: mysql-new-api/g' \
				   docker-compose.yml


			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			cd  /home/docker/new-api/

			git pull ${gh_proxy}github.com/Calcium-Ion/new-api.git main > /dev/null 2>&1
			sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
				   -e 's/container_name: redis/container_name: redis-new-api/g' \
				   -e 's/container_name: mysql/container_name: mysql-new-api/g' \
				   docker-compose.yml

			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip

		}

		docker_app_uninstall() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			rm -rf /home/docker/new-api
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;


	  60|jms)

		local app_id="60"
		local app_name="JumpServer開源堡壘機"
		local app_text="是一個開源的特權訪問管理 (PAM) 工具，該程序佔用80端口不支持添加域名訪問了"
		local app_url="官方介紹: https://github.com/jumpserver/jumpserver"
		local docker_name="jms_web"
		local docker_port="80"
		local app_size="2"

		docker_app_install() {
			curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
			clear
			echo "已經安裝完成"
			check_docker_app_ip
			echo "初始用戶名: admin"
			echo "初始密碼: ChangeMe"
		}


		docker_app_update() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh upgrade
			echo "應用已更新"
		}


		docker_app_uninstall() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh uninstall
			cd /opt
			rm -rf jumpserver-installer*/
			rm -rf jumpserver
			echo "應用已卸載"
		}

		docker_app_plus
		  ;;

	  61|libretranslate)
		local app_id="61"
		local docker_name="libretranslate"
		local docker_img="libretranslate/libretranslate:latest"
		local docker_port=8061

		docker_rum() {

			docker run -d \
				-p ${docker_port}:5000 \
				--name libretranslate \
				libretranslate/libretranslate \
				--load-only ko,zt,zh,en,ja,pt,es,fr,de,ru

		}

		local docker_describe="免費開源機器翻譯 API，完全自託管，它的翻譯引擎由開源Argos Translate庫提供支持。"
		local docker_url="官網介紹: https://github.com/LibreTranslate/LibreTranslate"
		local docker_use=""
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;



	  62|ragflow)
		local app_id="62"
		local app_name="RAGFlow知識庫"
		local app_text="基於深度文檔理解的開源 RAG（檢索增強生成）引擎"
		local app_url="官方網站: https://github.com/infiniflow/ragflow"
		local docker_name="ragflow-server"
		local docker_port="8062"
		local app_size="8"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
			sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
			cd  /home/docker/ragflow/
			git pull ${gh_proxy}github.com/infiniflow/ragflow.git main > /dev/null 2>&1
			cd  /home/docker/ragflow/docker/
			sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
			docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
			rm -rf /home/docker/ragflow
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;


	  63|open-webui)
		local app_id="63"
		local docker_name="open-webui"
		local docker_img="ghcr.io/open-webui/open-webui:main"
		local docker_port=8063

		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/open-webui:/app/backend/data --name open-webui --restart=always ghcr.io/open-webui/open-webui:main

		}

		local docker_describe="OpenWebUI一款大語言模型網頁框架，官方精簡版本，支持各大模型API接入"
		local docker_url="官網介紹: https://github.com/open-webui/open-webui"
		local docker_use=""
		local docker_passwd=""
		local app_size="3"
		docker_app
		  ;;

	  64|it-tools)
		local app_id="64"
		local docker_name="it-tools"
		local docker_img="corentinth/it-tools:latest"
		local docker_port=8064

		docker_rum() {
			docker run -d --name it-tools --restart=always -p ${docker_port}:80 corentinth/it-tools:latest
		}

		local docker_describe="對開發人員和 IT 工作者來說非常有用的工具"
		local docker_url="官網介紹: https://github.com/CorentinTh/it-tools"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  65|n8n)
		local app_id="65"
		local docker_name="n8n"
		local docker_img="docker.n8n.io/n8nio/n8n"
		local docker_port=8065

		docker_rum() {

			add_yuming
			mkdir -p /home/docker/n8n
			chmod -R 777 /home/docker/n8n

			docker run -d --name n8n \
			  --restart=always \
			  -p ${docker_port}:5678 \
			  -v /home/docker/n8n:/home/node/.n8n \
			  -e N8N_HOST=${yuming} \
			  -e N8N_PORT=5678 \
			  -e N8N_PROTOCOL=https \
			  -e WEBHOOK_URL=https://${yuming}/ \
			  docker.n8n.io/n8nio/n8n

			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"

		}

		local docker_describe="是一款功能強大的自動化工作流平台"
		local docker_url="官網介紹: https://github.com/n8n-io/n8n"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  66|yt)
		yt_menu_pro
		  ;;


	  67|ddns)
		local app_id="67"
		local docker_name="ddns-go"
		local docker_img="jeessy/ddns-go"
		local docker_port=8067

		docker_rum() {
			docker run -d \
				--name ddns-go \
				--restart=always \
				-p ${docker_port}:9876 \
				-v /home/docker/ddns-go:/root \
				jeessy/ddns-go

		}

		local docker_describe="自動將你的公網 IP（IPv4/IPv6）實時更新到各大 DNS 服務商，實現動態域名解析。"
		local docker_url="官網介紹: https://github.com/jeessy2/ddns-go"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  68|allinssl)
		local app_id="68"
		local docker_name="allinssl"
		local docker_img="allinssl/allinssl:latest"
		local docker_port=8068

		docker_rum() {
			docker run -d --name allinssl -p ${docker_port}:8888 -v /home/docker/allinssl/data:/www/allinssl/data -e ALLINSSL_USER=allinssl -e ALLINSSL_PWD=allinssldocker -e ALLINSSL_URL=allinssl allinssl/allinssl:latest
		}

		local docker_describe="開源免費的 SSL 證書自動化管理平台"
		local docker_url="官網介紹: https://allinssl.com"
		local docker_use="echo \"安全入口: /allinssl\""
		local docker_passwd="echo \"用戶名: allinssl  密碼: allinssldocker\""
		local app_size="1"
		docker_app
		  ;;


	  69|sftpgo)
		local app_id="69"
		local docker_name="sftpgo"
		local docker_img="drakkan/sftpgo:latest"
		local docker_port=8069

		docker_rum() {

			mkdir -p /home/docker/sftpgo/data
			mkdir -p /home/docker/sftpgo/config
			chown -R 1000:1000 /home/docker/sftpgo

			docker run -d \
			  --name sftpgo \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -p 22022:2022 \
			  --mount type=bind,source=/home/docker/sftpgo/data,target=/srv/sftpgo \
			  --mount type=bind,source=/home/docker/sftpgo/config,target=/var/lib/sftpgo \
			  drakkan/sftpgo:latest

		}

		local docker_describe="開源免費隨時隨地SFTP FTP WebDAV 文件傳輸工具"
		local docker_url="官網介紹: https://sftpgo.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  70|astrbot)
		local app_id="70"
		local docker_name="astrbot"
		local docker_img="soulter/astrbot:latest"
		local docker_port=8070

		docker_rum() {

			mkdir -p /home/docker/astrbot/data

			docker run -d \
			  -p ${docker_port}:6185 \
			  -p 6195:6195 \
			  -p 6196:6196 \
			  -p 6199:6199 \
			  -p 11451:11451 \
			  -v /home/docker/astrbot/data:/AstrBot/data \
			  --restart=always \
			  --name astrbot \
			  soulter/astrbot:latest

		}

		local docker_describe="開源AI聊天機器人框架，支持微信，QQ，TG接入AI大模型"
		local docker_url="官網介紹: https://astrbot.app/"
		local docker_use="echo \"用戶名: astrbot  密碼: astrbot\""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  71|navidrome)
		local app_id="71"
		local docker_name="navidrome"
		local docker_img="deluan/navidrome:latest"
		local docker_port=8071

		docker_rum() {

			docker run -d \
			  --name navidrome \
			  --restart=always \
			  --user $(id -u):$(id -g) \
			  -v /home/docker/navidrome/music:/music \
			  -v /home/docker/navidrome/data:/data \
			  -p ${docker_port}:4533 \
			  -e ND_LOGLEVEL=info \
			  deluan/navidrome:latest

		}

		local docker_describe="是一個輕量、高性能的音樂流媒體服務器"
		local docker_url="官網介紹: https://www.navidrome.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  72|bitwarden)

		local app_id="72"
		local docker_name="bitwarden"
		local docker_img="vaultwarden/server"
		local docker_port=8072

		docker_rum() {

			docker run -d \
				--name bitwarden \
				--restart=always \
				-p ${docker_port}:80 \
				-v /home/docker/bitwarden/data:/data \
				vaultwarden/server

		}

		local docker_describe="一個你可以控制數據的密碼管理器"
		local docker_url="官網介紹: https://bitwarden.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app


		  ;;



	  73|libretv)

		local app_id="73"
		local docker_name="libretv"
		local docker_img="bestzwei/libretv:latest"
		local docker_port=8073

		docker_rum() {

			read -e -p "設置LibreTV的登錄密碼:" app_passwd

			docker run -d \
			  --name libretv \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -e PASSWORD=${app_passwd} \
			  bestzwei/libretv:latest

		}

		local docker_describe="免費在線視頻搜索與觀看平台"
		local docker_url="官網介紹: https://github.com/LibreSpark/LibreTV"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  74|moontv)

		local app_id="74"

		local app_name="moontv私有影視"
		local app_text="免費在線視頻搜索與觀看平台"
		local app_url="視頻介紹: https://github.com/MoonTechLab/LunaTV"
		local docker_name="moontv-core"
		local docker_port="8074"
		local app_size="2"

		docker_app_install() {
			read -e -p "設置登錄用戶名:" admin
			read -e -p "設置登錄用戶密碼:" admin_password
			read -e -p "輸入授權碼:" shouquanma


			mkdir -p /home/docker/moontv
			mkdir -p /home/docker/moontv/config
			mkdir -p /home/docker/moontv/data
			cd /home/docker/moontv

			curl -o /home/docker/moontv/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/moontv-docker-compose.yml
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/moontv/docker-compose.yml
			sed -i "s|admin_password|${admin_password}|g" /home/docker/moontv/docker-compose.yml
			sed -i "s|admin|${admin}|g" /home/docker/moontv/docker-compose.yml
			sed -i "s|shouquanma|${shouquanma}|g" /home/docker/moontv/docker-compose.yml
			cd /home/docker/moontv/
			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			cd /home/docker/moontv/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			rm -rf /home/docker/moontv
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;


	  75|melody)

		local app_id="75"
		local docker_name="melody"
		local docker_img="foamzou/melody:latest"
		local docker_port=8075

		docker_rum() {

			docker run -d \
			  --name melody \
			  --restart=always \
			  -p ${docker_port}:5566 \
			  -v /home/docker/melody/.profile:/app/backend/.profile \
			  foamzou/melody:latest


		}

		local docker_describe="你的音樂精靈，旨在幫助你更好地管理音樂。"
		local docker_url="官網介紹: https://github.com/foamzou/melody"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app


		  ;;


	  76|dosgame)

		local app_id="76"
		local docker_name="dosgame"
		local docker_img="oldiy/dosgame-web-docker:latest"
		local docker_port=8076

		docker_rum() {
			docker run -d \
				--name dosgame \
				--restart=always \
				-p ${docker_port}:262 \
				oldiy/dosgame-web-docker:latest

		}

		local docker_describe="是一個中文DOS遊戲合集網站"
		local docker_url="官網介紹: https://github.com/rwv/chinese-dos-games"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app


		  ;;

	  77|xunlei)

		local app_id="77"
		local docker_name="xunlei"
		local docker_img="cnk3x/xunlei"
		local docker_port=8077

		docker_rum() {

			read -e -p "設置登錄用戶名:" app_use
			read -e -p "設置登錄密碼:" app_passwd

			docker run -d \
			  --name xunlei \
			  --restart=always \
			  --privileged \
			  -e XL_DASHBOARD_USERNAME=${app_use} \
			  -e XL_DASHBOARD_PASSWORD=${app_passwd} \
			  -v /home/docker/xunlei/data:/xunlei/data \
			  -v /home/docker/xunlei/downloads:/xunlei/downloads \
			  -p ${docker_port}:2345 \
			  cnk3x/xunlei

		}

		local docker_describe="迅雷你的離線高速BT磁力下載工具"
		local docker_url="官網介紹: https://github.com/cnk3x/xunlei"
		local docker_use="echo \"手機登錄迅雷，再輸入邀請碼，邀請碼: 迅雷牛通\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  78|PandaWiki)

		local app_id="78"
		local app_name="PandaWiki"
		local app_text="PandaWiki是一款AI大模型驅動的開源智能文檔管理系統，強烈建議不要自定義端口部署。"
		local app_url="官方介紹: https://github.com/chaitin/PandaWiki"
		local docker_name="panda-wiki-nginx"
		local docker_port="2443"
		local app_size="2"

		docker_app_install() {
			bash -c "$(curl -fsSLk https://release.baizhi.cloud/panda-wiki/manager.sh)"
		}

		docker_app_update() {
			docker_app_install
		}


		docker_app_uninstall() {
			docker_app_install
		}

		docker_app_plus
		  ;;



	  79|beszel)

		local app_id="79"
		local docker_name="beszel"
		local docker_img="henrygd/beszel"
		local docker_port=8079

		docker_rum() {

			mkdir -p /home/docker/beszel && \
			docker run -d \
			  --name beszel \
			  --restart=always \
			  -v /home/docker/beszel:/beszel_data \
			  -p ${docker_port}:8090 \
			  henrygd/beszel

		}

		local docker_describe="Beszel輕量易用的服務器監控"
		local docker_url="官網介紹: https://beszel.dev/zh/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  80|linkwarden)

		  local app_id="80"
		  local app_name="linkwarden書籤管理"
		  local app_text="一個開源的自託管書籤管理平台，支持標籤、搜索和團隊協作。"
		  local app_url="官方網站: https://linkwarden.app/"
		  local docker_name="linkwarden-linkwarden-1"
		  local docker_port="8080"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl
			  mkdir -p /home/docker/linkwarden && cd /home/docker/linkwarden

			  # 下載官方 docker-compose 和 env 文件
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env"

			  # 生成隨機密鑰與密碼
			  local ADMIN_EMAIL="admin@example.com"
			  local ADMIN_PASSWORD=$(openssl rand -hex 8)

			  sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=http://localhost:${docker_port}/api/v1/auth|g" .env
			  sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$(openssl rand -hex 32)|g" .env
			  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 16)|g" .env
			  sed -i "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$(openssl rand -hex 32)|g" .env

			  # 追加管理員賬號信息
			  echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >> .env
			  echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> .env

			  sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

			  # 啟動容器
			  docker compose up -d

			  clear
			  echo "已經安裝完成"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
			  cd /home/docker/linkwarden && docker compose down --rmi all
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env.new"

			  # 保留原本的變量
			  source .env
			  mv .env.new .env
			  echo "NEXTAUTH_URL=$NEXTAUTH_URL" >> .env
			  echo "NEXTAUTH_SECRET=$NEXTAUTH_SECRET" >> .env
			  echo "POSTGRES_PASSWORD=$POSTGRES_PASSWORD" >> .env
			  echo "MEILI_MASTER_KEY=$MEILI_MASTER_KEY" >> .env
			  echo "ADMIN_EMAIL=$ADMIN_EMAIL" >> .env
			  echo "ADMIN_PASSWORD=$ADMIN_PASSWORD" >> .env
			  sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

			  docker compose up -d
		  }

		  docker_app_uninstall() {
			  cd /home/docker/linkwarden && docker compose down --rmi all
			  rm -rf /home/docker/linkwarden
			  echo "應用已卸載"
		  }

		  docker_app_plus

		  ;;



	  81|jitsi)
		  local app_id="81"
		  local app_name="JitsiMeet視頻會議"
		  local app_text="一個開源的安全視頻會議解決方案，支持多人在線會議、屏幕共享與加密通信。"
		  local app_url="官方網站: https://jitsi.org/"
		  local docker_name="jitsi"
		  local docker_port="8081"
		  local app_size="3"

		  docker_app_install() {

			  add_yuming
			  mkdir -p /home/docker/jitsi && cd /home/docker/jitsi
			  wget $(wget -q -O - https://api.github.com/repos/jitsi/docker-jitsi-meet/releases/latest | grep zip | cut -d\" -f4)
			  unzip "$(ls -t | head -n 1)"
			  cd "$(ls -dt */ | head -n 1)"
			  cp env.example .env
			  ./gen-passwords.sh
			  mkdir -p ~/.jitsi-meet-cfg/{web,transcripts,prosody/config,prosody/prosody-plugins-custom,jicofo,jvb,jigasi,jibri}
			  sed -i "s|^HTTP_PORT=.*|HTTP_PORT=${docker_port}|" .env
			  sed -i "s|^#PUBLIC_URL=https://meet.example.com:\${HTTPS_PORT}|PUBLIC_URL=https://$yuming:443|" .env
			  docker compose up -d

			  ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			  block_container_port "$docker_name" "$ipv4_address"

		  }

		  docker_app_update() {
			  cd /home/docker/jitsi
			  cd "$(ls -dt */ | head -n 1)"
			  docker compose down --rmi all
			  docker compose up -d

		  }

		  docker_app_uninstall() {
			  cd /home/docker/jitsi
			  cd "$(ls -dt */ | head -n 1)"
			  docker compose down --rmi all
			  rm -rf /home/docker/jitsi
			  echo "應用已卸載"
		  }

		  docker_app_plus

		  ;;



	  82|gpt-load)

		local app_id="82"
		local docker_name="gpt-load"
		local docker_img="tbphp/gpt-load:latest"
		local docker_port=8082

		docker_rum() {

			read -e -p "設定${docker_name}的登錄密鑰（sk-開頭字母和數字組合）如: sk-159kejilionyyds163:" app_passwd

			mkdir -p /home/docker/gpt-load && \
			docker run -d --name gpt-load \
				-p ${docker_port}:3001 \
				-e AUTH_KEY=${app_passwd} \
				-v "/home/docker/gpt-load/data":/app/data \
				tbphp/gpt-load:latest

		}

		local docker_describe="高性能AI接口透明代理服務"
		local docker_url="官網介紹: https://www.gpt-load.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  83|komari)

		local app_id="83"
		local docker_name="komari"
		local docker_img="ghcr.io/komari-monitor/komari:latest"
		local docker_port=8083

		docker_rum() {

			mkdir -p /home/docker/komari && \
			docker run -d \
			  --name komari \
			  -p ${docker_port}:25774 \
			  -v /home/docker/komari:/app/data \
			  -e ADMIN_USERNAME=admin \
			  -e ADMIN_PASSWORD=1212156 \
			  -e TZ=Asia/Shanghai \
			  --restart=always \
			  ghcr.io/komari-monitor/komari:latest

		}

		local docker_describe="輕量級的自託管服務器監控工具"
		local docker_url="官網介紹: https://github.com/komari-monitor/komari/tree/main"
		local docker_use="echo \"默認賬號: admin  默認密碼: 1212156\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  84|wallos)

		local app_id="84"
		local docker_name="wallos"
		local docker_img="bellamy/wallos:latest"
		local docker_port=8084

		docker_rum() {

			mkdir -p /home/docker/wallos && \
			docker run -d --name wallos \
			  -v /home/docker/wallos/db:/var/www/html/db \
			  -v /home/docker/wallos/logos:/var/www/html/images/uploads/logos \
			  -e TZ=UTC \
			  -p ${docker_port}:80 \
			  --restart=always \
			  bellamy/wallos:latest

		}

		local docker_describe="開源個人訂閱追踪器，可用於財務管理"
		local docker_url="官網介紹: https://github.com/ellite/Wallos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  85|immich)

		  local app_id="85"
		  local app_name="immich圖片視頻管理器"
		  local app_text="高性能自託管照片和視頻管理解決方案。"
		  local app_url="官網介紹: https://github.com/immich-app/immich"
		  local docker_name="immich_server"
		  local docker_port="8085"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl wget
			  mkdir -p /home/docker/${docker_name} && cd /home/docker/${docker_name}

			  wget -O docker-compose.yml ${gh_proxy}github.com/immich-app/immich/releases/latest/download/docker-compose.yml
			  wget -O .env ${gh_proxy}github.com/immich-app/immich/releases/latest/download/example.env
			  sed -i "s/2283:2283/${docker_port}:2283/g" /home/docker/${docker_name}/docker-compose.yml

			  docker compose up -d

			  clear
			  echo "已經安裝完成"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
		  }

		  docker_app_uninstall() {
			  cd /home/docker/${docker_name} && docker compose down --rmi all
			  rm -rf /home/docker/${docker_name}
			  echo "應用已卸載"
		  }

		  docker_app_plus


		  ;;


	  86|jellyfin)

		local app_id="86"
		local docker_name="jellyfin"
		local docker_img="jellyfin/jellyfin"
		local docker_port=8086

		docker_rum() {

			mkdir -p /home/docker/jellyfin/media
			chmod -R 777 /home/docker/jellyfin

			docker run -d \
			  --name jellyfin \
			  --user root \
			  --volume /home/docker/jellyfin/config:/config \
			  --volume /home/docker/jellyfin/cache:/cache \
			  --mount type=bind,source=/home/docker/jellyfin/media,target=/media \
			  -p ${docker_port}:8096 \
			  -p 7359:7359/udp \
			  --restart=always \
			  jellyfin/jellyfin


		}

		local docker_describe="是一款開源媒體服務器軟件"
		local docker_url="官網介紹: https://jellyfin.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  87|synctv)

		local app_id="87"
		local docker_name="synctv"
		local docker_img="synctvorg/synctv"
		local docker_port=8087

		docker_rum() {

			docker run -d \
				--name synctv \
				-v /home/docker/synctv:/root/.synctv \
				-p ${docker_port}:8080 \
				--restart=always \
				synctvorg/synctv

		}

		local docker_describe="遠程一起觀看電影和直播的程序。它提供了同步觀影、直播、聊天等功能"
		local docker_url="官網介紹: https://github.com/synctv-org/synctv"
		local docker_use="echo \"初始賬號和密碼: root  登陸後請及時修改登錄密碼\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  88|owncast)

		local app_id="88"
		local docker_name="owncast"
		local docker_img="owncast/owncast:latest"
		local docker_port=8088

		docker_rum() {

			docker run -d \
				--name owncast \
				-p ${docker_port}:8080 \
				-p 1935:1935 \
				-v /home/docker/owncast/data:/app/data \
				--restart=always \
				owncast/owncast:latest


		}

		local docker_describe="開源、免費的自建直播平台"
		local docker_url="官網介紹: https://owncast.online"
		local docker_use="echo \"訪問地址後面帶 /admin 訪問管理員頁面\""
		local docker_passwd="echo \"初始賬號: admin  初始密碼: abc123  登陸後請及時修改登錄密碼\""
		local app_size="1"
		docker_app

		  ;;



	  89|file-code-box)

		local app_id="89"
		local docker_name="file-code-box"
		local docker_img="lanol/filecodebox:latest"
		local docker_port=8089

		docker_rum() {

			docker run -d \
			  --name file-code-box \
			  -p ${docker_port}:12345 \
			  -v /home/docker/file-code-box/data:/app/data \
			  --restart=always \
			  lanol/filecodebox:latest

		}

		local docker_describe="匿名口令分享文本和文件，像拿快遞一樣取文件"
		local docker_url="官網介紹: https://github.com/vastsa/FileCodeBox"
		local docker_use="echo \"訪問地址後面帶 /#/admin 訪問管理員頁面\""
		local docker_passwd="echo \"管理員密碼: FileCodeBox2023\""
		local app_size="1"
		docker_app

		  ;;




	  90|matrix)

		local app_id="90"
		local docker_name="matrix"
		local docker_img="matrixdotorg/synapse:latest"
		local docker_port=8090

		docker_rum() {

			add_yuming

			if [ ! -d /home/docker/matrix/data ]; then
				docker run --rm \
				  -v /home/docker/matrix/data:/data \
				  -e SYNAPSE_SERVER_NAME=${yuming} \
				  -e SYNAPSE_REPORT_STATS=yes \
				  --name matrix \
				  matrixdotorg/synapse:latest generate
			fi

			docker run -d \
			  --name matrix \
			  -v /home/docker/matrix/data:/data \
			  -p ${docker_port}:8008 \
			  --restart=always \
			  matrixdotorg/synapse:latest

			echo "創建初始用戶或管理員。請設置以下內容用戶名和密碼以及是否為管理員。"
			docker exec -it matrix register_new_matrix_user \
			  http://localhost:8008 \
			  -c /data/homeserver.yaml

			sed -i '/^enable_registration:/d' /home/docker/matrix/data/homeserver.yaml
			sed -i '/^# vim:ft=yaml/i enable_registration: true' /home/docker/matrix/data/homeserver.yaml
			sed -i '/^enable_registration_without_verification:/d' /home/docker/matrix/data/homeserver.yaml
			sed -i '/^# vim:ft=yaml/i enable_registration_without_verification: true' /home/docker/matrix/data/homeserver.yaml

			docker restart matrix

			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"

		}

		local docker_describe="Matrix是一個去中心化的聊天協議"
		local docker_url="官網介紹: https://matrix.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  91|gitea)

		local app_id="91"

		local app_name="gitea私有代碼倉庫"
		local app_text="免費新一代的代碼託管平台，提供接近 GitHub 的使用體驗。"
		local app_url="視頻介紹: https://github.com/go-gitea/gitea"
		local docker_name="gitea"
		local docker_port="8091"
		local app_size="2"

		docker_app_install() {

			mkdir -p /home/docker/gitea
			mkdir -p /home/docker/gitea/gitea
			mkdir -p /home/docker/gitea/data
			mkdir -p /home/docker/gitea/postgres
			cd /home/docker/gitea

			curl -o /home/docker/gitea/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/gitea-docker-compose.yml
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/gitea/docker-compose.yml
			cd /home/docker/gitea/
			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			cd /home/docker/gitea/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			rm -rf /home/docker/gitea
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;




	  92|filebrowser)

		local app_id="92"
		local docker_name="filebrowser"
		local docker_img="hurlenko/filebrowser"
		local docker_port=8092

		docker_rum() {

			docker run -d \
				--name filebrowser \
				--restart=always \
				-p ${docker_port}:8080 \
				-v /home/docker/filebrowser/data:/data \
				-v /home/docker/filebrowser/config:/config \
				-e FB_BASEURL=/filebrowser \
				hurlenko/filebrowser

		}

		local docker_describe="是一個基於Web的文件管理器"
		local docker_url="官網介紹: https://filebrowser.org/"
		local docker_use="docker logs filebrowser"
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	93|dufs)

		local app_id="93"
		local docker_name="dufs"
		local docker_img="sigoden/dufs"
		local docker_port=8093

		docker_rum() {

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}:/data \
			  -p ${docker_port}:5000 \
			  ${docker_img} /data -A

		}

		local docker_describe="極簡靜態文件服務器，支持上傳下載"
		local docker_url="官網介紹: https://github.com/sigoden/dufs"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;

	94|gopeed)

		local app_id="94"
		local docker_name="gopeed"
		local docker_img="liwei2633/gopeed"
		local docker_port=8094

		docker_rum() {

			read -e -p "設置登錄用戶名:" app_use
			read -e -p "設置登錄密碼:" app_passwd

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}/downloads:/app/Downloads \
			  -v /home/docker/${docker_name}/storage:/app/storage \
			  -p ${docker_port}:9999 \
			  ${docker_img} -u ${app_use} -p ${app_passwd}

		}

		local docker_describe="分佈式高速下載工具，支持多種協議"
		local docker_url="官網介紹: https://github.com/GopeedLab/gopeed"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;



	  95|paperless)

		local app_id="95"

		local app_name="paperless文檔管理平台"
		local app_text="開源的電子文檔管理系統，它的主要用途是把你的紙質文件數字化並管理起來。"
		local app_url="視頻介紹: https://docs.paperless-ngx.com/"
		local docker_name="paperless-webserver-1"
		local docker_port="8095"
		local app_size="2"

		docker_app_install() {

			mkdir -p /home/docker/paperless
			mkdir -p /home/docker/paperless/export
			mkdir -p /home/docker/paperless/consume
			cd /home/docker/paperless

			curl -o /home/docker/paperless/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/docker-compose.postgres-tika.yml
			curl -o /home/docker/paperless/docker-compose.env ${gh_proxy}raw.githubusercontent.com/paperless-ngx/paperless-ngx/refs/heads/main/docker/compose/.env

			sed -i "s/8000:8000/${docker_port}:8000/g" /home/docker/paperless/docker-compose.yml
			cd /home/docker/paperless
			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			rm -rf /home/docker/paperless
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;



	  96|2fauth)

		local app_id="96"

		local app_name="2FAuth自託管二步驗證器"
		local app_text="自託管的雙重身份驗證 (2FA) 賬戶管理和驗證碼生成工具。"
		local app_url="官網: https://github.com/Bubka/2FAuth"
		local docker_name="2fauth"
		local docker_port="8096"
		local app_size="1"

		docker_app_install() {

			add_yuming

			mkdir -p /home/docker/2fauth
			mkdir -p /home/docker/2fauth/data
			chmod -R 777 /home/docker/2fauth/
			cd /home/docker/2fauth

			curl -o /home/docker/2fauth/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/2fauth-docker-compose.yml

			sed -i "s/8000:8000/${docker_port}:8000/g" /home/docker/2fauth/docker-compose.yml
			sed -i "s/yuming.com/${yuming}/g" /home/docker/2fauth/docker-compose.yml
			cd /home/docker/2fauth
			docker compose up -d

			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"

			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			rm -rf /home/docker/2fauth
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;



	97|wgs)

		local app_id="97"
		local docker_name="wireguard"
		local docker_img="lscr.io/linuxserver/wireguard:latest"
		local docker_port=8097

		docker_rum() {

		read -e -p  "請輸入組網的客戶端數量 (默認 5):" COUNT
		COUNT=${COUNT:-5}
		read -e -p  "請輸入 WireGuard 網段 (默認 10.13.13.0):" NETWORK
		NETWORK=${NETWORK:-10.13.13.0}

		PEERS=$(seq -f "wg%02g" 1 "$COUNT" | paste -sd,)

		ip link delete wg0 &>/dev/null

		ip_address
		docker run -d \
		  --name=wireguard \
		  --network host \
		  --cap-add=NET_ADMIN \
		  --cap-add=SYS_MODULE \
		  -e PUID=1000 \
		  -e PGID=1000 \
		  -e TZ=Etc/UTC \
		  -e SERVERURL=${ipv4_address} \
		  -e SERVERPORT=51820 \
		  -e PEERS=${PEERS} \
		  -e INTERNAL_SUBNET=${NETWORK} \
		  -e ALLOWEDIPS=${NETWORK}/24 \
		  -e PERSISTENTKEEPALIVE_PEERS=all \
		  -e LOG_CONFS=true \
		  -v /home/docker/wireguard/config:/config \
		  -v /lib/modules:/lib/modules \
		  --restart=always \
		  lscr.io/linuxserver/wireguard:latest


		sleep 3

		docker exec wireguard sh -c "
		f='/config/wg_confs/wg0.conf'
		sed -i 's/51820/${docker_port}/g' \$f
		"

		docker exec wireguard sh -c "
		for d in /config/peer_*; do
		  sed -i 's/51820/${docker_port}/g' \$d/*.conf
		done
		"

		docker exec wireguard sh -c '
		for d in /config/peer_*; do
		  sed -i "/^DNS/d" "$d"/*.conf
		done
		'

		docker exec wireguard sh -c '
		for d in /config/peer_*; do
		  for f in "$d"/*.conf; do
			grep -q "^PersistentKeepalive" "$f" || \
			sed -i "/^AllowedIPs/ a PersistentKeepalive = 25" "$f"
		  done
		done
		'

		docker exec wireguard bash -c '
		for d in /config/peer_*; do
		  cd "$d" || continue
		  conf_file=$(ls *.conf)
		  base_name="${conf_file%.conf}"
		  qrencode -o "$base_name.png" < "$conf_file"
		done
		'

		docker restart wireguard

		sleep 2
		echo
		echo -e "${gl_huang}所有客戶端二維碼配置:${gl_bai}"
		docker exec wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
		sleep 2
		echo
		echo -e "${gl_huang}所有客戶端配置代碼:${gl_bai}"
		docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
		sleep 2
		echo -e "${gl_lv}${COUNT}個客戶端配置全部輸出，使用方法如下：${gl_bai}"
		echo -e "${gl_lv}1. 手機下載wg的APP，掃描上方二維碼，可以快速連接網絡${gl_bai}"
		echo -e "${gl_lv}2. Windows下載客戶端，複製配置代碼連接網絡。${gl_bai}"
		echo -e "${gl_lv}3. Linux用腳本部署WG客戶端，複製配置代碼連接網絡。${gl_bai}"
		echo -e "${gl_lv}官方客戶端下載方式: https://www.wireguard.com/install/${gl_bai}"
		break_end

		}

		local docker_describe="現代化、高性能的虛擬專用網絡工具"
		local docker_url="官網介紹: https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	98|wgc)

		local app_id="98"
		local docker_name="wireguardc"
		local docker_img="kjlion/wireguard:alpine"
		local docker_port=51820

		docker_rum() {

			mkdir -p /home/docker/wireguard/config/

			local CONFIG_FILE="/home/docker/wireguard/config/wg0.conf"

			# 創建目錄（如果不存在）
			mkdir -p "$(dirname "$CONFIG_FILE")"

			echo "請粘貼你的客戶端配置，連續按兩次回車保存："

			# 初始化變量
			input=""
			empty_line_count=0

			# 逐行讀取用戶輸入
			while IFS= read -r line; do
				if [[ -z "$line" ]]; then
					((empty_line_count++))
					if [[ $empty_line_count -ge 2 ]]; then
						break
					fi
				else
					empty_line_count=0
					input+="$line"$'\n'
				fi
			done

			# 寫入配置文件
			echo "$input" > "$CONFIG_FILE"

			echo "客戶端配置已保存到$CONFIG_FILE"

			ip link delete wg0 &>/dev/null

			docker run -d \
			  --name wireguardc \
			  --network host \
			  --cap-add NET_ADMIN \
			  --cap-add SYS_MODULE \
			  -v /home/docker/wireguard/config:/config \
			  -v /lib/modules:/lib/modules:ro \
			  --restart=always \
			  kjlion/wireguard:alpine

			sleep 3

			docker logs wireguardc

		break_end

		}

		local docker_describe="現代化、高性能的虛擬專用網絡工具"
		local docker_url="官網介紹: https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  99|dsm)

		local app_id="99"

		local app_name="dsm群暉虛擬機"
		local app_text="Docker容器中的虛擬DSM"
		local app_url="官網: https://github.com/vdsm/virtual-dsm"
		local docker_name="dsm"
		local docker_port="8099"
		local app_size="16"

		docker_app_install() {

			read -e -p "設置 CPU 核數 (默認 2):" CPU_CORES
			local CPU_CORES=${CPU_CORES:-2}

			read -e -p "設置內存大小 (默認 4G):" RAM_SIZE
			local RAM_SIZE=${RAM_SIZE:-4}

			mkdir -p /home/docker/dsm
			mkdir -p /home/docker/dsm/dev
			chmod -R 777 /home/docker/dsm/
			cd /home/docker/dsm

			curl -o /home/docker/dsm/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/dsm-docker-compose.yml

			sed -i "s/5000:5000/${docker_port}:5000/g" /home/docker/dsm/docker-compose.yml
			sed -i "s|CPU_CORES: "2"|CPU_CORES: "${CPU_CORES}"|g" /home/docker/dsm/docker-compose.yml
			sed -i "s|RAM_SIZE: "2G"|RAM_SIZE: "${RAM_SIZE}G"|g" /home/docker/dsm/docker-compose.yml
			cd /home/docker/dsm
			docker compose up -d

			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			rm -rf /home/docker/dsm
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;



	100|syncthing)

		local app_id="100"
		local docker_name="syncthing"
		local docker_img="syncthing/syncthing:latest"
		local docker_port=8100

		docker_rum() {
			docker run -d \
			  --name=syncthing \
			  --hostname=my-syncthing \
			  --restart=always \
			  -p ${docker_port}:8384 \
			  -p 22000:22000/tcp \
			  -p 22000:22000/udp \
			  -p 21027:21027/udp \
			  -v /home/docker/syncthing:/var/syncthing \
			  syncthing/syncthing:latest
		}

		local docker_describe="開源的點對點文件同步工具，類似於 Dropbox、Resilio Sync，但完全去中心化。"
		local docker_url="官網介紹: https://github.com/syncthing/syncthing"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  101|moneyprinterturbo)
		local app_id="101"
		local app_name="AI視頻生成工具"
		local app_text="MoneyPrinterTurbo是一款使用AI大模型合成高清短視頻的工具"
		local app_url="官方網站: https://github.com/harry0703/MoneyPrinterTurbo"
		local docker_name="moneyprinterturbo"
		local docker_port="8101"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/harry0703/MoneyPrinterTurbo.git && cd MoneyPrinterTurbo/
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml

			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/MoneyPrinterTurbo/ && docker compose down --rmi all
			cd  /home/docker/MoneyPrinterTurbo/

			git pull ${gh_proxy}github.com/harry0703/MoneyPrinterTurbo.git main > /dev/null 2>&1
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml
			cd  /home/docker/MoneyPrinterTurbo/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/MoneyPrinterTurbo/ && docker compose down --rmi all
			rm -rf /home/docker/MoneyPrinterTurbo
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;



	  102|vocechat)

		local app_id="102"
		local docker_name="vocechat-server"
		local docker_img="privoce/vocechat-server:latest"
		local docker_port=8102

		docker_rum() {

			docker run -d --restart=always \
			  -p ${docker_port}:3000 \
			  --name vocechat-server \
			  -v /home/docker/vocechat/data:/home/vocechat-server/data \
			  privoce/vocechat-server:latest

		}

		local docker_describe="是一款支持獨立部署的個人云社交媒體聊天服務"
		local docker_url="官網介紹: https://github.com/Privoce/vocechat-web"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  103|umami)
		local app_id="103"
		local app_name="Umami網站統計工具"
		local app_text="開源、輕量、隱私友好的網站分析工具，類似於GoogleAnalytics。"
		local app_url="官方網站: https://github.com/umami-software/umami"
		local docker_name="umami-umami-1"
		local docker_port="8103"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/umami-software/umami.git && cd umami
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/umami/docker-compose.yml

			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
			echo "初始用戶名: admin"
			echo "初始密碼: umami"
		}

		docker_app_update() {
			cd  /home/docker/umami/ && docker compose down --rmi all
			cd  /home/docker/umami/
			git pull ${gh_proxy}github.com/umami-software/umami.git main > /dev/null 2>&1
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/umami/docker-compose.yml
			cd  /home/docker/umami/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/umami/ && docker compose down --rmi all
			rm -rf /home/docker/umami
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;

	  104|nginx-stream)
		stream_panel
		  ;;


	  105|siyuan)

		local app_id="105"
		local docker_name="siyuan"
		local docker_img="b3log/siyuan"
		local docker_port=8105

		docker_rum() {

			read -e -p "設置登錄密碼:" app_passwd

			docker run -d \
			  --name siyuan \
			  --restart=always \
			  -v /home/docker/siyuan/workspace:/siyuan/workspace \
			  -p ${docker_port}:6806 \
			  -e PUID=1001 \
			  -e PGID=1002 \
			  b3log/siyuan \
			  --workspace=/siyuan/workspace/ \
			  --accessAuthCode="${app_passwd}"

		}

		local docker_describe="思源筆記是一款隱私優先的知識管理系統"
		local docker_url="官網介紹: https://github.com/siyuan-note/siyuan"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  106|drawnix)

		local app_id="106"
		local docker_name="drawnix"
		local docker_img="pubuzhixing/drawnix"
		local docker_port=8106

		docker_rum() {

			docker run -d \
			   --restart=always  \
			   --name drawnix \
			   -p ${docker_port}:80 \
			  pubuzhixing/drawnix

		}

		local docker_describe="是一款強大的開源白板工具，集成思維導圖、流程圖等。"
		local docker_url="官網介紹: https://github.com/plait-board/drawnix"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  107|pansou)

		local app_id="107"
		local docker_name="pansou"
		local docker_img="ghcr.io/fish2018/pansou-web"
		local docker_port=8107

		docker_rum() {

			docker run -d \
			  --name pansou \
			  --restart=always \
			  -p ${docker_port}:80 \
			  -v /home/docker/pansou/data:/app/data \
			  -v /home/docker/pansou/logs:/app/logs \
			  -e ENABLED_PLUGINS="hunhepan,jikepan,panwiki,pansearch,panta,qupansou,
susu,thepiratebay,wanou,xuexizhinan,panyq,zhizhen,labi,muou,ouge,shandian,
duoduo,huban,cyg,erxiao,miaoso,fox4k,pianku,clmao,wuji,cldi,xiaozhang,
libvio,leijing,xb6v,xys,ddys,hdmoli,yuhuage,u3c3,javdb,clxiong,jutoushe,
sdso,xiaoji,xdyh,haisou,bixin,djgou,nyaa,xinjuc,aikanzy,qupanshe,xdpan,
discourse,yunsou,ahhhhfs,nsgame,gying" \
			  ghcr.io/fish2018/pansou-web

		}

		local docker_describe="PanSou是一個高性能的網盤資源搜索API服務。"
		local docker_url="官網介紹: https://github.com/fish2018/pansou"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;




	  108|langbot)
		local app_id="108"
		local app_name="LangBot聊天機器人"
		local app_text="是一個開源的大語言模型原生即時通信機器人開發平台"
		local app_url="官方網站: https://github.com/langbot-app/LangBot"
		local docker_name="langbot_plugin_runtime"
		local docker_port="8108"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/langbot-app/LangBot && cd LangBot/docker
			sed -i "s/5300:5300/${docker_port}:5300/g" /home/docker/LangBot/docker/docker-compose.yaml

			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/LangBot/docker && docker compose down --rmi all
			cd  /home/docker/LangBot/
			git pull ${gh_proxy}github.com/langbot-app/LangBot main > /dev/null 2>&1
			sed -i "s/5300:5300/${docker_port}:5300/g" /home/docker/LangBot/docker/docker-compose.yaml
			cd  /home/docker/LangBot/docker/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/LangBot/docker/ && docker compose down --rmi all
			rm -rf /home/docker/LangBot
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;


	  109|zfile)

		local app_id="109"
		local docker_name="zfile"
		local docker_img="zhaojun1998/zfile:latest"
		local docker_port=8109

		docker_rum() {


			docker run -d --name=zfile --restart=always \
				-p ${docker_port}:8080 \
				-v /home/docker/zfile/db:/root/.zfile-v4/db \
				-v /home/docker/zfile/logs:/root/.zfile-v4/logs \
				-v /home/docker/zfile/file:/data/file \
				-v /home/docker/zfile/application.properties:/root/.zfile-v4/application.properties \
				zhaojun1998/zfile:latest


		}

		local docker_describe="是一個適用於個人或小團隊的在線網盤程序。"
		local docker_url="官網介紹: https://github.com/zfile-dev/zfile"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  110|karakeep)
		local app_id="110"
		local app_name="karakeep書籤管理"
		local app_text="是一款可自行託管的書籤應用，帶有人工智能功能，專為數據囤積者而設計。"
		local app_url="官方網站: https://github.com/karakeep-app/karakeep"
		local docker_name="docker-web-1"
		local docker_port="8110"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/karakeep-app/karakeep.git && cd karakeep/docker && cp .env.sample .env
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/karakeep/docker/docker-compose.yml

			docker compose up -d
			clear
			echo "已經安裝完成"
			check_docker_app_ip
		}

		docker_app_update() {
			cd  /home/docker/karakeep/docker/ && docker compose down --rmi all
			cd  /home/docker/karakeep/
			git pull ${gh_proxy}github.com/karakeep-app/karakeep.git main > /dev/null 2>&1
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/karakeep/docker/docker-compose.yml
			cd  /home/docker/karakeep/docker/ && docker compose up -d
		}

		docker_app_uninstall() {
			cd  /home/docker/karakeep/docker/ && docker compose down --rmi all
			rm -rf /home/docker/karakeep
			echo "應用已卸載"
		}

		docker_app_plus

		  ;;



	  111|convertx)

		local app_id="111"
		local docker_name="convertx"
		local docker_img="ghcr.io/c4illin/convertx:latest"
		local docker_port=8111

		docker_rum() {

			docker run -d --name=${docker_name} --restart=always \
				-p ${docker_port}:3000 \
				-v /home/docker/convertx:/app/data \
				${docker_img}

		}

		local docker_describe="是一個功能強大的多格式文件轉換工具（支持文檔、圖像、音頻視頻等）強烈建議添加域名訪問"
		local docker_url="項目地址: https://github.com/c4illin/ConvertX"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app

		  ;;


	  112|lucky)

		local app_id="112"
		local docker_name="lucky"
		local docker_img="gdy666/lucky:v2"
		# 由於 Lucky 使用 host 網絡模式，這裡的端口僅作記錄/說明參考，實際由應用自身控制（默認16601）
		local docker_port=8112

		docker_rum() {

			docker run -d --name=${docker_name} --restart=always \
				--network host \
				-v /home/docker/lucky/conf:/app/conf \
				-v /var/run/docker.sock:/var/run/docker.sock \
				${docker_img}

			echo "正在等待 Lucky 初始化..."
			sleep 10
			docker exec lucky /app/lucky -rSetHttpAdminPort ${docker_port}

		}

		local docker_describe="Lucky 是一個大內網穿透及端口轉發管理工具，支持 DDNS、反向代理、WOL 等功能。"
		local docker_url="項目地址: https://github.com/gdy666/lucky"
		local docker_use="echo \"默認賬號密碼: 666\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  113|firefox)

		local app_id="113"
		local docker_name="firefox"
		local docker_img="jlesage/firefox:latest"
		local docker_port=8113

		docker_rum() {

			read -e -p "設置登錄密碼:" admin_password

			docker run -d --name=${docker_name} --restart=always \
				-p ${docker_port}:5800 \
				-v /home/docker/firefox:/config:rw \
				-e ENABLE_CJK_FONT=1 \
				-e WEB_AUDIO=1 \
				-e VNC_PASSWORD="${admin_password}" \
				${docker_img}
		}

		local docker_describe="是一個運行在 Docker 中的 Firefox 瀏覽器，支持通過網頁直接訪問桌面版瀏覽器界面。"
		local docker_url="項目地址: https://github.com/jlesage/docker-firefox"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  b)
	  	clear
	  	send_stats "全部應用備份"

	  	local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
	  	echo -e "${gl_huang}正在備份$backup_filename ...${gl_bai}"
	  	cd / && tar czvf "$backup_filename" home

	  	while true; do
			clear
			echo "備份文件已創建: /$backup_filename"
			read -e -p "要傳送備份數據到遠程服務器嗎？ (Y/N):" choice
			case "$choice" in
			  [Yy])
				read -e -p "請輸入遠端服務器IP:" remote_ip
				read -e -p "目標服務器SSH端口 [默認22]:" TARGET_PORT
				local TARGET_PORT=${TARGET_PORT:-22}

				if [ -z "$remote_ip" ]; then
				  echo "錯誤: 請輸入遠端服務器IP。"
				  continue
				fi
				local latest_tar=$(ls -t /app*.tar.gz | head -1)
				if [ -n "$latest_tar" ]; then
				  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				  sleep 2  # 添加等待时间
				  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
				  echo "文件已傳送至遠程服務器/根目錄。"
				else
				  echo "未找到要傳送的文件。"
				fi
				break
				;;
			  *)
				echo "注意: 目前備份僅包含docker項目，不包含寶塔，1panel等建站面板的數據備份。"
				break
				;;
			esac
	  	done

		  ;;

	  r)
	  	root_use
	  	send_stats "全部應用還原"
	  	echo "可用的應用備份"
	  	echo "-------------------------"
	  	ls -lt /app*.gz | awk '{print $NF}'
	  	echo ""
	  	read -e -p  "回車鍵還原最新的備份，輸入備份文件名還原指定的備份，輸入0退出：" filename

	  	if [ "$filename" == "0" ]; then
			  break_end
			  linux_panel
	  	fi

	  	# 如果用戶沒有輸入文件名，使用最新的壓縮包
	  	if [ -z "$filename" ]; then
			  local filename=$(ls -t /app*.tar.gz | head -1)
	  	fi

	  	if [ -n "$filename" ]; then
		  	  echo -e "${gl_huang}正在解壓$filename ...${gl_bai}"
		  	  cd / && tar -xzf "$filename"
			  echo "應用數據已還原，目前請手動進入指定應用菜單，更新應用，即可還原應用。"
	  	else
			  echo "沒有找到壓縮包。"
	  	fi

		  ;;

	  0)
		  kejilion
		  ;;
	  *)
		cd ~
		install git
		if [ ! -d apps/.git ]; then
			git clone ${gh_proxy}github.com/kejilion/apps.git
		else
			cd apps
			# git pull origin main > /dev/null 2>&1
			git pull ${gh_proxy}github.com/kejilion/apps.git main > /dev/null 2>&1
		fi
		local custom_app="$HOME/apps/${sub_choice}.conf"
		if [ -f "$custom_app" ]; then
			. "$custom_app"
		else
			echo -e "${gl_hong}錯誤: 未找到編號為${sub_choice}的應用配置${gl_bai}"
		fi
		  ;;
	esac
	break_end
	sub_choice=""

done
}



linux_work() {

	while true; do
	  clear
	  send_stats "後台工作區"
	  echo -e "後台工作區"
	  echo -e "系統將為你提供可以後台常駐運行的工作區，你可以用來執行長時間的任務"
	  echo -e "即使你斷開SSH，工作區中的任務也不會中斷，後台常駐任務。"
	  echo -e "${gl_huang}提示:${gl_bai}進入工作區後使用Ctrl+b再單獨按d，退出工作區！"
	  echo -e "${gl_kjlan}------------------------"
	  echo "當前已存在的工作區列表"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}1號工作區"
	  echo -e "${gl_kjlan}2.   ${gl_bai}2號工作區"
	  echo -e "${gl_kjlan}3.   ${gl_bai}3號工作區"
	  echo -e "${gl_kjlan}4.   ${gl_bai}4號工作區"
	  echo -e "${gl_kjlan}5.   ${gl_bai}5號工作區"
	  echo -e "${gl_kjlan}6.   ${gl_bai}6號工作區"
	  echo -e "${gl_kjlan}7.   ${gl_bai}7號工作區"
	  echo -e "${gl_kjlan}8.   ${gl_bai}8號工作區"
	  echo -e "${gl_kjlan}9.   ${gl_bai}9號工作區"
	  echo -e "${gl_kjlan}10.  ${gl_bai}10號工作區"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH常駐模式${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}創建/進入工作區"
	  echo -e "${gl_kjlan}23.  ${gl_bai}注入命令到後台工作區"
	  echo -e "${gl_kjlan}24.  ${gl_bai}刪除指定工作區"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "啟動工作區$SESSION_NAME"
			  tmux_run
			  ;;

		  21)
			while true; do
			  clear
			  if grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc; then
				  local tmux_sshd_status="${gl_lv}開啟${gl_bai}"
			  else
				  local tmux_sshd_status="${gl_hui}關閉${gl_bai}"
			  fi
			  send_stats "SSH常駐模式"
			  echo -e "SSH常駐模式${tmux_sshd_status}"
			  echo "開啟後SSH連接後會直接進入常駐模式，直接回到之前的工作狀態。"
			  echo "------------------------"
			  echo "1. 開啟            2. 關閉"
			  echo "------------------------"
			  echo "0. 返回上一級選單"
			  echo "------------------------"
			  read -e -p "請輸入你的選擇:" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "啟動工作區$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# 自動進入 tmux 會話\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
				  source ~/.bashrc
			  	  tmux_run
				  ;;
				2)
				  sed -i '/# 自動進入 tmux 會話/,+4d' ~/.bashrc
				  tmux kill-window -t sshd
				  ;;
				*)
				  break
				  ;;
			  esac
			done
			  ;;

		  22)
			  read -e -p "請輸入你創建或進入的工作區名稱，如1​​001 kj001 work1:" SESSION_NAME
			  tmux_run
			  send_stats "自定義工作區"
			  ;;


		  23)
			  read -e -p "請輸入你要後台執行的命令，如:curl -fsSL https://get.docker.com | sh:" tmuxd
			  tmux_run_d
			  send_stats "注入命令到後台工作區"
			  ;;

		  24)
			  read -e -p "請輸入要刪除的工作區名稱:" gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "刪除工作區"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無效的輸入!"
			  ;;
	  esac
	  break_end

	done


}










# 智能切換鏡像源函數
switch_mirror() {
	# 可選參數，默認為 false
	local upgrade_software=${1:-false}
	local clean_cache=${2:-false}

	# 獲取用戶國家
	local country
	country=$(curl -s ipinfo.io/country)

	echo "檢測到國家：$country"

	if [ "$country" = "CN" ]; then
		echo "使用國內鏡像源..."
		bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
		  --source mirrors.huaweicloud.com \
		  --protocol https \
		  --use-intranet-source false \
		  --backup true \
		  --upgrade-software "$upgrade_software" \
		  --clean-cache "$clean_cache" \
		  --ignore-backup-tips \
		  --install-epel true \
		  --pure-mode
	else
		echo "使用官方鏡像源..."
		bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
		  --use-official-source true \
		  --protocol https \
		  --use-intranet-source false \
		  --backup true \
		  --upgrade-software "$upgrade_software" \
		  --clean-cache "$clean_cache" \
		  --ignore-backup-tips \
		  --install-epel true \
		  --pure-mode
	fi
}


fail2ban_panel() {
		  root_use
		  send_stats "ssh防禦"
		  while true; do

				check_f2b_status
				echo -e "SSH防禦程序$check_f2b_status"
				echo "fail2ban是一個SSH防止暴力破解工具"
				echo "官網介紹:${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. 安裝防禦程序"
				echo "------------------------"
				echo "2. 查看SSH攔截記錄"
				echo "3. 日誌實時監控"
				echo "------------------------"
				echo "9. 卸載防禦程序"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				read -e -p "請輸入你的選擇:" sub_choice
				case $sub_choice in
					1)
						f2b_install_sshd
						cd ~
						f2b_status
						break_end
						;;
					2)
						echo "------------------------"
						f2b_sshd
						echo "------------------------"
						break_end
						;;
					3)
						tail -f /var/log/fail2ban.log
						break
						;;
					9)
						remove fail2ban
						rm -rf /etc/fail2ban
						echo "Fail2Ban防禦程序已卸載"
						break
						;;
					*)
						break
						;;
				esac
		  done

}







linux_Settings() {

	while true; do
	  clear
	  # send_stats "系統工具"
	  echo -e "系統工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}設置腳本啟動快捷鍵${gl_kjlan}2.   ${gl_bai}修改登錄密碼"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ROOT密碼登錄模式${gl_kjlan}4.   ${gl_bai}安裝Python指定版本"
	  echo -e "${gl_kjlan}5.   ${gl_bai}開放所有端口${gl_kjlan}6.   ${gl_bai}修改SSH連接端口"
	  echo -e "${gl_kjlan}7.   ${gl_bai}優化DNS地址${gl_kjlan}8.   ${gl_bai}一鍵重裝系統${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}禁用ROOT賬戶創建新賬戶${gl_kjlan}10.  ${gl_bai}切換優先ipv4/ipv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}查看端口占用狀態${gl_kjlan}12.  ${gl_bai}修改虛擬內存大小"
	  echo -e "${gl_kjlan}13.  ${gl_bai}用戶管理${gl_kjlan}14.  ${gl_bai}用戶/密碼生成器"
	  echo -e "${gl_kjlan}15.  ${gl_bai}系統時區調整${gl_kjlan}16.  ${gl_bai}設置BBR3加速"
	  echo -e "${gl_kjlan}17.  ${gl_bai}防火牆高級管理器${gl_kjlan}18.  ${gl_bai}修改主機名"
	  echo -e "${gl_kjlan}19.  ${gl_bai}切換系統更新源${gl_kjlan}20.  ${gl_bai}定時任務管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}本機host解析${gl_kjlan}22.  ${gl_bai}SSH防禦程序"
	  echo -e "${gl_kjlan}23.  ${gl_bai}限流自動關機${gl_kjlan}24.  ${gl_bai}ROOT私鑰登錄模式"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot系統監控預警${gl_kjlan}26.  ${gl_bai}修復OpenSSH高危漏洞"
	  echo -e "${gl_kjlan}27.  ${gl_bai}紅帽系Linux內核升級${gl_kjlan}28.  ${gl_bai}Linux系統內核參數優化${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}病毒掃描工具${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}文件管理器"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}切換系統語言${gl_kjlan}32.  ${gl_bai}命令行美化工具${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}設置系統回收站${gl_kjlan}34.  ${gl_bai}系統備份與恢復"
	  echo -e "${gl_kjlan}35.  ${gl_bai}ssh遠程連接工具${gl_kjlan}36.  ${gl_bai}硬盤分區管理工具"
	  echo -e "${gl_kjlan}37.  ${gl_bai}命令行歷史記錄${gl_kjlan}38.  ${gl_bai}rsync遠程同步工具"
	  echo -e "${gl_kjlan}39.  ${gl_bai}命令收藏夾${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}留言板${gl_kjlan}66.  ${gl_bai}一條龍系統調優${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}重啟服務器${gl_kjlan}100. ${gl_bai}隱私與安全"
	  echo -e "${gl_kjlan}101. ${gl_bai}k命令高級用法${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}卸載科技lion腳本"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "請輸入你的快捷按鍵（輸入0退出）:" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "快捷鍵已設置"
				  send_stats "腳本快捷鍵已設置"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "設置你的登錄密碼"
			  echo "設置你的登錄密碼"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "root密碼模式"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "py版本管理"
			echo "python版本管理"
			echo "視頻介紹: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "該功能可無縫安裝python官方支持的任何版本！"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "當前python版本號:${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "推薦版本:  3.12    3.11    3.10    3.9    3.8    2.7"
			echo "查詢更多版本: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "輸入你要安裝的python版本號（輸入0退出）:" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "腳本PY管理"
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
			echo -e "當前python版本號:${gl_huang}$VERSION${gl_bai}"
			send_stats "腳本PY版本切換"

			  ;;

		  5)
			  root_use
			  send_stats "開放端口"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "端口已全部開放"

			  ;;
		  6)
			root_use
			send_stats "修改SSH端口"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# 讀取當前的 SSH 端口號
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 打印當前的 SSH 端口號
				echo -e "當前的 SSH 端口號是:${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "端口號範圍1到65535之間的數字。 （輸入0退出）"

				# 提示用戶輸入新的 SSH 端口號
				read -e -p "請輸入新的 SSH 端口號:" new_port

				# 判斷端口號是否在有效範圍內
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH端口已修改"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "退出SSH端口修改"
						break
					else
						echo "端口號無效，請輸入1到65535之間的數字。"
						send_stats "輸入無效SSH端口"
						break_end
					fi
				else
					echo "輸入無效，請輸入數字。"
					send_stats "輸入無效SSH端口"
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
			send_stats "新用戶禁用root"
			read -e -p "請輸入新用戶名（輸入0退出）:" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			install sudo

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "操作已完成。"
			;;


		  10)
			root_use
			send_stats "設置v4/v6優先級"
			while true; do
				clear
				echo "設置v4/v6優先級"
				echo "------------------------"


				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "當前網絡優先級設置:${gl_huang}IPv4${gl_bai}優先"
				else
					echo -e "當前網絡優先級設置:${gl_huang}IPv6${gl_bai}優先"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 優先          2. IPv6 優先          3. IPv6 修復工具"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				read -e -p "選擇優先的網絡:" choice

				case $choice in
					1)
						prefer_ipv4
						;;
					2)
						rm -f /etc/gai.conf
						echo "已切換為 IPv6 優先"
						send_stats "已切換為 IPv6 優先"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "該功能由jhb大神提供，感謝他！"
						send_stats "ipv6修復"
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
			send_stats "設置虛擬內存"
			while true; do
				clear
				echo "設置虛擬內存"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "當前虛擬內存:${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 分配1024M         2. 分配2048M         3. 分配4096M         4. 自定義大小"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				read -e -p "請輸入你的選擇:" choice

				case "$choice" in
				  1)
					send_stats "已設置1G虛擬內存"
					add_swap 1024

					;;
				  2)
					send_stats "已設置2G虛擬內存"
					add_swap 2048

					;;
				  3)
					send_stats "已設置4G虛擬內存"
					add_swap 4096

					;;

				  4)
					read -e -p "請輸入虛擬內存大小（單位M）:" new_swap
					add_swap "$new_swap"
					send_stats "已設置自定義虛擬內存"
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
				send_stats "用戶管理"
				echo "用戶列表"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "使用者名稱" "用戶權限" "用戶組" "sudo權限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "賬戶操作"
				  echo "------------------------"
				  echo "1. 創建普通賬戶             2. 創建高級賬戶"
				  echo "------------------------"
				  echo "3. 賦予最高權限             4. 取消最高權限"
				  echo "------------------------"
				  echo "5. 刪除賬號"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" sub_choice

				  case $sub_choice in
					  1)
					   # 提示用戶輸入新用戶名
					   read -e -p "請輸入新用戶名:" new_username

					   # 創建新用戶並設置密碼
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "操作已完成。"
						  ;;

					  2)
					   # 提示用戶輸入新用戶名
					   read -e -p "請輸入新用戶名:" new_username

					   # 創建新用戶並設置密碼
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # 賦予新用戶sudo權限
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo

					   echo "操作已完成。"

						  ;;
					  3)
					   read -e -p "請輸入用戶名:" username
					   # 賦予新用戶sudo權限
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo
						  ;;
					  4)
					   read -e -p "請輸入用戶名:" username
					   # 從sudoers文件中移除用戶的sudo權限
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "請輸入要刪除的用戶名:" username
					   # 刪除用戶及其主目錄
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
			send_stats "用戶信息生成器"
			echo "隨機用戶名"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "隨機用戶名$i: $username"
			done

			echo ""
			echo "隨機姓名"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 生成5個隨機用戶姓名
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "隨機用戶姓名$i: $user_name"
			done

			echo ""
			echo "隨機UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "隨機UUID$i: $uuid"
			done

			echo ""
			echo "16位隨機密碼"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "隨機密碼$i: $password"
			done

			echo ""
			echo "32位隨機密碼"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "隨機密碼$i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "換時區"
			while true; do
				clear
				echo "系統時間信息"

				# 獲取當前系統時區
				local timezone=$(current_timezone)

				# 獲取當前系統時間
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 顯示時區和時間
				echo "當前系統時區：$timezone"
				echo "當前系統時間：$current_time"

				echo ""
				echo "時區切換"
				echo "------------------------"
				echo "亞洲"
				echo "1.  中國上海時間             2.  中國香港時間"
				echo "3.  日本東京時間             4.  韓國首爾時間"
				echo "5.  新加坡時間               6.  印度加爾各答時間"
				echo "7.  阿聯酋迪拜時間           8.  澳大利亞悉尼時間"
				echo "9.  泰國曼谷時間"
				echo "------------------------"
				echo "歐洲"
				echo "11. 英國倫敦時間             12. 法國巴黎時間"
				echo "13. 德國柏林時間             14. 俄羅斯莫斯科時間"
				echo "15. 荷蘭尤特賴赫特時間       16. 西班牙馬德里時間"
				echo "------------------------"
				echo "美洲"
				echo "21. 美國西部時間             22. 美國東部時間"
				echo "23. 加拿大時間               24. 墨西哥時間"
				echo "25. 巴西時間                 26. 阿根廷時間"
				echo "------------------------"
				echo "31. UTC全球標準時間"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				read -e -p "請輸入你的選擇:" sub_choice


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
					31) set_timedate UTC ;;
					*) break ;;
				esac
			done
			  ;;

		  16)

			bbrv3
			  ;;

		  17)
			  iptables_panel

			  ;;

		  18)
		  root_use
		  send_stats "修改主機名"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "當前主機名:${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "請輸入新的主機名（輸入0退出）:" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # 其他系統，如 Debian, Ubuntu, CentOS 等
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

				  echo "主機名已更改為:$new_hostname"
				  send_stats "主機名已更改"
				  sleep 1
			  else
				  echo "已退出，未更改主機名。"
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "換系統更新源"
		  clear
		  echo "選擇更新源區域"
		  echo "接入LinuxMirrors切換系統更新源"
		  echo "------------------------"
		  echo "1. 中國大陸【默認】          2. 中國大陸【教育網】          3. 海外地區          4. 智能切換更新源"
		  echo "------------------------"
		  echo "0. 返回上一級選單"
		  echo "------------------------"
		  read -e -p "輸入你的選擇:" choice

		  case $choice in
			  1)
				  send_stats "中國大陸默認源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "中國大陸教育源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "海外源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  4)
				  send_stats "智能切換更新源"
				  switch_mirror false false
				  ;;

			  *)
				  echo "已取消"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "定時任務管理"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "定時任務列表"
				  crontab -l
				  echo ""
				  echo "操作"
				  echo "------------------------"
				  echo "1. 添加定時任務              2. 刪除定時任務              3. 編輯定時任務"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "請輸入新任務的執行命令:" newquest
						  echo "------------------------"
						  echo "1. 每月任務                 2. 每週任務"
						  echo "3. 每天任務                 4. 每小時任務"
						  echo "------------------------"
						  read -e -p "請輸入你的選擇:" dingshi

						  case $dingshi in
							  1)
								  read -e -p "選擇每月的幾號執行任務？ (1-30):" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "選擇週幾執行任務？ (0-6，0代表星期日):" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "選擇每天幾點執行任務？ （小時，0-23）:" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "輸入每小時的第幾分鐘執行任務？ （分鐘，0-60）:" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "添加定時任務"
						  ;;
					  2)
						  read -e -p "請輸入需要刪除任務的關鍵字:" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "刪除定時任務"
						  ;;
					  3)
						  crontab -e
						  send_stats "編輯定時任務"
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
				  echo "本機host解析列表"
				  echo "如果你在這裡添加解析匹配，將不再使用動態解析了"
				  cat /etc/hosts
				  echo ""
				  echo "操作"
				  echo "------------------------"
				  echo "1. 添加新的解析              2. 刪除解析地址"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" host_dns

				  case $host_dns in
					  1)
						  read -e -p "請輸入新的解析記錄 格式: 110.25.5.33 kejilion.pro :" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "本地host解析新增"

						  ;;
					  2)
						  read -e -p "請輸入需要刪除的解析內容關鍵字:" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "本地host解析刪除"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
			fail2ban_panel
			  ;;


		  23)
			root_use
			send_stats "限流關機功能"
			while true; do
				clear
				echo "限流關機功能"
				echo "視頻介紹: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "當前流量使用情況，重啟服務器流量計算會清零！"
				output_status
				echo -e "${gl_kjlan}總接收:${gl_bai}$rx"
				echo -e "${gl_kjlan}總發送:${gl_bai}$tx"

				# 檢查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 獲取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}當前設置的進站限流閾值為:${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}當前設置的出站限流閾值為:${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}當前未啟用限流關機功能${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "系統每分鐘會檢測實際流量是否到達閾值，到達後會自動關閉服務器！"
				echo "------------------------"
				echo "1. 開啟限流關機功能          2. 停用限流關機功能"
				echo "------------------------"
				echo "0. 返回上一級選單"
				echo "------------------------"
				read -e -p "請輸入你的選擇:" Limiting

				case "$Limiting" in
				  1)
					# 輸入新的虛擬內存大小
					echo "如果實際服務器就100G流量，可設置閾值為95G，提前關機，以免出現流量誤差或溢出。"
					read -e -p "請輸入進站流量閾值（單位為G，默認100G）:" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "請輸入出站流量閾值（單位為G，默認100G）:" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "請輸入流量重置日期（默認每月1日重置）:" cz_day
					cz_day=${cz_day:-1}

					cd ~
					curl -Ss -o ~/Limiting_Shut_down.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/Limiting_Shut_down1.sh
					chmod +x ~/Limiting_Shut_down.sh
					sed -i "s/110/$rx_threshold_gb/g" ~/Limiting_Shut_down.sh
					sed -i "s/120/$tx_threshold_gb/g" ~/Limiting_Shut_down.sh
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					(crontab -l ; echo "* * * * * ~/Limiting_Shut_down.sh") | crontab - > /dev/null 2>&1
					crontab -l | grep -v 'reboot' | crontab -
					(crontab -l ; echo "0 1 $cz_day * * reboot") | crontab - > /dev/null 2>&1
					echo "限流關機已設置"
					send_stats "限流關機已設置"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "已關閉限流關機功能"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "私鑰登錄"
			  while true; do
				  clear
			  	  echo "ROOT私鑰登錄模式"
			  	  echo "視頻介紹: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
			  	  echo "------------------------------------------------"
			  	  echo "將會生成密鑰對，更安全的方式SSH登錄"
				  echo "------------------------"
				  echo "1. 生成新密鑰              2. 導入已有密鑰              3. 查看本機密鑰"
				  echo "------------------------"
				  echo "0. 返回上一級選單"
				  echo "------------------------"
				  read -e -p "請輸入你的選擇:" host_dns

				  case $host_dns in
					  1)
				  		send_stats "生成新密鑰"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "導入已有公鑰"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "查看本機密鑰"
						echo "------------------------"
						echo "公鑰信息"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "私鑰信息"
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
			  send_stats "電報預警"
			  echo "TG-bot監控預警功能"
			  echo "視頻介紹: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "您需要配置tg機器人API和接收預警的用戶ID，即可實現本機CPU，內存，硬盤，流量，SSH登錄的實時監控預警"
			  echo "到達閾值後會向用戶發預警消息"
			  echo -e "${gl_hui}-關於流量，重啟服務器將重新計算-${gl_bai}"
			  read -e -p "確定繼續嗎？ (Y/N):" choice

			  case "$choice" in
				[Yy])
				  send_stats "電報預警啟用"
				  cd ~
				  install nano tmux bc jq
				  check_crontab_installed
				  if [ -f ~/TG-check-notify.sh ]; then
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  else
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-check-notify.sh
					  chmod +x ~/TG-check-notify.sh
					  nano ~/TG-check-notify.sh
				  fi
				  tmux kill-session -t TG-check-notify > /dev/null 2>&1
				  tmux new -d -s TG-check-notify "~/TG-check-notify.sh"
				  crontab -l | grep -v '~/TG-check-notify.sh' | crontab - > /dev/null 2>&1
				  (crontab -l ; echo "@reboot tmux new -d -s TG-check-notify '~/TG-check-notify.sh'") | crontab - > /dev/null 2>&1

				  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/TG-SSH-check-notify.sh > /dev/null 2>&1
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
				  echo "TG-bot預警系統已啟動"
				  echo -e "${gl_hui}你還可以將root目錄中的TG-check-notify.sh預警文件放到其他機器上直接使用！${gl_bai}"
				  ;;
				[Nn])
				  echo "已取消"
				  ;;
				*)
				  echo "無效的選擇，請輸入 Y 或 N。"
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "修復SSH高危漏洞"
			  cd ~
			  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/upgrade_openssh9.8p1.sh
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
		  34)
			  linux_backup
			  ;;
		  35)
			  ssh_manager
			  ;;
		  36)
			  disk_manager
			  ;;
		  37)
			  clear
			  send_stats "命令行歷史記錄"
			  get_history_file() {
				  for file in "$HOME"/.bash_history "$HOME"/.ash_history "$HOME"/.zsh_history "$HOME"/.local/share/fish/fish_history; do
					  [ -f "$file" ] && { echo "$file"; return; }
				  done
				  return 1
			  }

			  history_file=$(get_history_file) && cat -n "$history_file"
			  ;;

		  38)
			  rsync_manager
			  ;;


		  39)
			  clear
			  linux_fav
			  ;;

		  41)
			clear
			send_stats "留言板"
			echo "訪問科技lion官方留言板，您對腳本有任何想法歡迎留言交流！"
			echo "https://board.kejilion.pro"
			echo "公共密碼: kejilion.sh"
			  ;;

		  66)

			  root_use
			  send_stats "一條龍調優"
			  echo "一條龍系統調優"
			  echo "------------------------------------------------"
			  echo "將對以下內容進行操作與優化"
			  echo "1. 優化系統更新源，更新系統到最新"
			  echo "2. 清理系統垃圾文件"
			  echo -e "3. 設置虛擬內存${gl_huang}1G${gl_bai}"
			  echo -e "4. 設置SSH端口號為${gl_huang}5522${gl_bai}"
			  echo -e "5. 啟動fail2ban防禦SSH暴力破解"
			  echo -e "6. 開放所有端口"
			  echo -e "7. 開啟${gl_huang}BBR${gl_bai}加速"
			  echo -e "8. 設置時區到${gl_huang}上海${gl_bai}"
			  echo -e "9. 自動優化DNS地址${gl_huang}海外: 1.1.1.1 8.8.8.8  國內: 223.5.5.5${gl_bai}"
		  	  echo -e "10. 設置網絡為${gl_huang}ipv4優先${gl_bai}"
			  echo -e "11. 安裝基礎工具${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "12. Linux系統內核參數優化切換到${gl_huang}均衡優化模式${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "確定一鍵保養嗎？ (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "一條龍調優啟動"
				  echo "------------------------------------------------"
				  switch_mirror false false
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/12. 更新系統到最新"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/12. 清理系統垃圾文件"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/12. 設置虛擬內存${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/12. 設置SSH端口號為${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  f2b_install_sshd
				  cd ~
				  f2b_status
				  echo -e "[${gl_lv}OK${gl_bai}] 5/12. 啟動fail2ban防禦SSH暴力破解"

				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 6/12. 開放所有端口"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 7/12. 開啟${gl_huang}BBR${gl_bai}加速"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 8/12. 設置時區到${gl_huang}上海${gl_bai}"

				  echo "------------------------------------------------"
				  auto_optimize_dns
				  echo -e "[${gl_lv}OK${gl_bai}] 9/12. 自動優化DNS地址${gl_huang}${gl_bai}"
				  echo "------------------------------------------------"
				  prefer_ipv4
				  echo -e "[${gl_lv}OK${gl_bai}] 10/12. 設置網絡為${gl_huang}ipv4優先${gl_bai}}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 11/12. 安裝基礎工具${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 12/12. Linux系統內核參數優化"
				  echo -e "${gl_lv}一條龍系統調優已完成${gl_bai}"

				  ;;
				[Nn])
				  echo "已取消"
				  ;;
				*)
				  echo "無效的選擇，請輸入 Y 或 N。"
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "重啟系統"
			  server_reboot
			  ;;
		  100)

			root_use
			while true; do
			  clear
			  if grep -q '^ENABLE_STATS="true"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_lv}正在採集數據${gl_bai}"
			  elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_hui}採集已關閉${gl_bai}"
			  else
			  	local status_message="無法確定的狀態"
			  fi

			  echo "隱私與安全"
			  echo "腳本將收集用戶使用功能的數據，優化腳本體驗，製作更多好玩好用的功能"
			  echo "將收集腳本版本號，使用的時間，系統版本，CPU架構，機器所屬國家和使用的功能的名稱，"
			  echo "------------------------------------------------"
			  echo -e "當前狀態:$status_message"
			  echo "--------------------"
			  echo "1. 開啟採集"
			  echo "2. 關閉採集"
			  echo "--------------------"
			  echo "0. 返回上一級選單"
			  echo "--------------------"
			  read -e -p "請輸入你的選擇:" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "已開啟採集"
					  send_stats "隱私與安全已開啟採集"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "已關閉採集"
					  send_stats "隱私與安全已關閉採集"
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
			  send_stats "卸載科技lion腳本"
			  echo "卸載科技lion腳本"
			  echo "------------------------------------------------"
			  echo "將徹底卸載kejilion腳本，不影響你其他功能"
			  read -e -p "確定繼續嗎？ (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "腳本已卸載，再見！"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "已取消"
				  ;;
				*)
				  echo "無效的選擇，請輸入 Y 或 N。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "無效的輸入!"
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
		echo "當前路徑"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1.  進入目錄           2.  創建目錄             3.  修改目錄權限         4.  重命名目錄"
		echo "5.  刪除目錄           6.  返回上一級選單目錄"
		echo "------------------------"
		echo "11. 創建文件           12. 編輯文件             13. 修改文件權限         14. 重命名文件"
		echo "15. 刪除文件"
		echo "------------------------"
		echo "21. 壓縮文件目錄       22. 解壓文件目錄         23. 移動文件目錄         24. 複製文件目錄"
		echo "25. 傳文件至其他服務器"
		echo "------------------------"
		echo "0.  返回上一級選單"
		echo "------------------------"
		read -e -p "請輸入你的選擇:" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "請輸入目錄名:" dirname
				cd "$dirname" 2>/dev/null || echo "無法進入目錄"
				send_stats "進入目錄"
				;;
			2)  # 创建目录
				read -e -p "請輸入要創建的目錄名:" dirname
				mkdir -p "$dirname" && echo "目錄已創建" || echo "創建失敗"
				send_stats "創建目錄"
				;;
			3)  # 修改目录权限
				read -e -p "請輸入目錄名:" dirname
				read -e -p "請輸入權限 (如 755):" perm
				chmod "$perm" "$dirname" && echo "權限已修改" || echo "修改失敗"
				send_stats "修改目錄權限"
				;;
			4)  # 重命名目录
				read -e -p "請輸入當前目錄名:" current_name
				read -e -p "請輸入新目錄名:" new_name
				mv "$current_name" "$new_name" && echo "目錄已重命名" || echo "重命名失敗"
				send_stats "重命名目錄"
				;;
			5)  # 删除目录
				read -e -p "請輸入要刪除的目錄名:" dirname
				rm -rf "$dirname" && echo "目錄已刪除" || echo "刪除失敗"
				send_stats "刪除目錄"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "返回上一級選單目錄"
				;;
			11) # 创建文件
				read -e -p "請輸入要創建的文件名:" filename
				touch "$filename" && echo "文件已創建" || echo "創建失敗"
				send_stats "創建文件"
				;;
			12) # 编辑文件
				read -e -p "請輸入要編輯的文件名:" filename
				install nano
				nano "$filename"
				send_stats "編輯文件"
				;;
			13) # 修改文件权限
				read -e -p "請輸入文件名:" filename
				read -e -p "請輸入權限 (如 755):" perm
				chmod "$perm" "$filename" && echo "權限已修改" || echo "修改失敗"
				send_stats "修改文件權限"
				;;
			14) # 重命名文件
				read -e -p "請輸入當前文件名:" current_name
				read -e -p "請輸入新文件名:" new_name
				mv "$current_name" "$new_name" && echo "文件已重命名" || echo "重命名失敗"
				send_stats "重命名文件"
				;;
			15) # 删除文件
				read -e -p "請輸入要刪除的文件名:" filename
				rm -f "$filename" && echo "文件已刪除" || echo "刪除失敗"
				send_stats "刪除文件"
				;;
			21) # 压缩文件/目录
				read -e -p "請輸入要壓縮的文件/目錄名:" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "已壓縮為$name.tar.gz" || echo "壓縮失敗"
				send_stats "壓縮文件/目錄"
				;;
			22) # 解压文件/目录
				read -e -p "請輸入要解壓的文件名 (.tar.gz):" filename
				install tar
				tar -xzvf "$filename" && echo "已解壓$filename" || echo "解壓失敗"
				send_stats "解壓文件/目錄"
				;;

			23) # 移动文件或目录
				read -e -p "請輸入要移動的文件或目錄路徑:" src_path
				if [ ! -e "$src_path" ]; then
					echo "錯誤: 文件或目錄不存在。"
					send_stats "移動文件或目錄失敗: 文件或目錄不存在"
					continue
				fi

				read -e -p "請輸入目標路徑 (包括新文件名或目錄名):" dest_path
				if [ -z "$dest_path" ]; then
					echo "錯誤: 請輸入目標路徑。"
					send_stats "移動文件或目錄失敗: 目標路徑未指定"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "文件或目錄已移動到$dest_path" || echo "移動文件或目錄失敗"
				send_stats "移動文件或目錄"
				;;


		   24) # 复制文件目录
				read -e -p "請輸入要復制的文件或目錄路徑:" src_path
				if [ ! -e "$src_path" ]; then
					echo "錯誤: 文件或目錄不存在。"
					send_stats "複製文件或目錄失敗: 文件或目錄不存在"
					continue
				fi

				read -e -p "請輸入目標路徑 (包括新文件名或目錄名):" dest_path
				if [ -z "$dest_path" ]; then
					echo "錯誤: 請輸入目標路徑。"
					send_stats "複製文件或目錄失敗: 目標路徑未指定"
					continue
				fi

				# 使用 -r 選項以遞歸方式複制目錄
				cp -r "$src_path" "$dest_path" && echo "文件或目錄已復製到$dest_path" || echo "複製文件或目錄失敗"
				send_stats "複製文件或目錄"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "請輸入要傳送的文件路徑:" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "錯誤: 文件不存在。"
					send_stats "傳送文件失敗: 文件不存在"
					continue
				fi

				read -e -p "請輸入遠端服務器IP:" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "錯誤: 請輸入遠端服務器IP。"
					send_stats "傳送文件失敗: 未輸入遠端服務器IP"
					continue
				fi

				read -e -p "請輸入遠端服務器用戶名 (默認root):" remote_user
				remote_user=${remote_user:-root}

				read -e -p "請輸入遠端服務器密碼:" -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "錯誤: 請輸入遠端服務器密碼。"
					send_stats "傳送文件失敗: 未輸入遠端服務器密碼"
					continue
				fi

				read -e -p "請輸入登錄端口 (默認22):" remote_port
				remote_port=${remote_port:-22}

				# 清除已知主機的舊條目
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# 使用scp傳輸文件
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "文件已傳送至遠程服務器home目錄。"
					send_stats "文件傳送成功"
				else
					echo "文件傳送失敗。"
					send_stats "文件傳送失敗"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "返回上一級選單菜單"
				break
				;;
			*)  # 处理无效输入
				echo "無效的選擇，請重新輸入"
				send_stats "無效選擇"
				;;
		esac
	done
}






cluster_python3() {
	install python3 python3-paramiko
	cd ~/cluster/
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
	python3 ~/cluster/$py_task
}


run_commands_on_servers() {

	install sshpass

	local SERVERS_FILE="$HOME/cluster/servers.py"
	local SERVERS=$(grep -oP '{"name": "\K[^"]+|"hostname": "\K[^"]+|"port": \K[^,]+|"username": "\K[^"]+|"password": "\K[^"]+' "$SERVERS_FILE")

	# 將提取的信息轉換為數組
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# 遍歷服務器並執行命令
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}連接到$name ($hostname)...${gl_bai}"
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
	  echo "服務器集群控制"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}服務器列表管理${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}添加服務器${gl_kjlan}2.  ${gl_bai}刪除服務器${gl_kjlan}3.  ${gl_bai}編輯服務器"
	  echo -e "${gl_kjlan}4.  ${gl_bai}備份集群${gl_kjlan}5.  ${gl_bai}還原集群"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}批量執行任務${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}安裝科技lion腳本${gl_kjlan}12. ${gl_bai}更新系統${gl_kjlan}13. ${gl_bai}清理系統"
	  echo -e "${gl_kjlan}14. ${gl_bai}安裝docker${gl_kjlan}15. ${gl_bai}安裝BBR3${gl_kjlan}16. ${gl_bai}設置1G虛擬內存"
	  echo -e "${gl_kjlan}17. ${gl_bai}設置時區到上海${gl_kjlan}18. ${gl_bai}開放所有端口${gl_kjlan}51. ${gl_bai}自定義指令"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "添加集群服務器"
			  read -e -p "服務器名稱:" server_name
			  read -e -p "服務器IP:" server_ip
			  read -e -p "服務器端口（22）:" server_port
			  local server_port=${server_port:-22}
			  read -e -p "服務器用戶名（root）:" server_username
			  local server_username=${server_username:-root}
			  read -e -p "服務器用戶密碼:" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "刪除集群服務器"
			  read -e -p "請輸入需要刪除的關鍵字:" rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "編輯集群服務器"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "備份集群"
			  echo -e "請將${gl_huang}/root/cluster/servers.py${gl_bai}文件下載，完成備份！"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "還原集群"
			  echo "請上傳您的servers.py，按任意鍵開始上傳！"
			  echo -e "請上傳您的${gl_huang}servers.py${gl_bai}文件到${gl_huang}/root/cluster/${gl_bai}完成還原！"
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
			  send_stats "自定義執行命令"
			  read -e -p "請輸入批量執行的命令:" mingling
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
send_stats "廣告專欄"
echo "廣告專欄"
echo "------------------------"
echo "將為用戶提供更簡單優雅的推廣與購買體驗！"
echo ""
echo -e "服務器優惠"
echo "------------------------"
echo -e "${gl_lan}萊卡雲 香港CN2 GIA 韓國雙ISP 美國CN2 GIA 優惠活動${gl_bai}"
echo -e "${gl_bai}網址: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd 10.99刀每年 美國 1核心 1G內存 20G硬盤 1T流量每月${gl_bai}"
echo -e "${gl_bai}網址: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52.7刀每年 美國 1核心 4G內存 50G硬盤 4T流量每月${gl_bai}"
echo -e "${gl_bai}網址: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}搬瓦工 49刀每季 美國CN2GIA 日本軟銀 2核心 1G內存 20G硬盤 1T流量每月${gl_bai}"
echo -e "${gl_bai}網址: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT 28刀每季 美國CN2GIA 1核心 2G內存 20G硬盤 800G流量每月${gl_bai}"
echo -e "${gl_bai}網址: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS 6.9刀每月 東京軟銀 2核心 1G內存 20G硬盤 1T流量每月${gl_bai}"
echo -e "${gl_bai}網址: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}VPS更多熱門優惠${gl_bai}"
echo -e "${gl_bai}網址: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "域名優惠"
echo "------------------------"
echo -e "${gl_lan}GNAME 8.8刀首年COM域名 6.68刀首年CC域名${gl_bai}"
echo -e "${gl_bai}網址: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "科技lion周邊"
echo "------------------------"
echo -e "${gl_kjlan}B站:${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}油管:${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}官網:${gl_bai}https://kejilion.pro/              ${gl_kjlan}導航:${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}部落格:${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}軟件中心:${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}腳本官網:${gl_bai}https://kejilion.sh            ${gl_kjlan}GitHub地址:${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}




games_server_tools() {

	while true; do
	  clear
	  echo -e "遊戲開服腳本合集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1. ${gl_bai}幻獸帕魯開服腳本"
	  echo -e "${gl_kjlan}2. ${gl_bai}我的世界開服腳本"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0. ${gl_bai}返回主菜單"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "請輸入你的選擇:" sub_choice

	  case $sub_choice in

		  1) send_stats "幻獸帕魯開服腳本" ; cd ~
			 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
			 exit
			 ;;
		  2) send_stats "我的世界開服腳本" ; cd ~
			 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/mc.sh ; chmod +x mc.sh ; ./mc.sh
			 exit
			 ;;

		  0)
			kejilion
			;;

		  *)
			echo "無效的輸入!"
			;;
	  esac
	  break_end

	done


}





















kejilion_update() {

send_stats "腳本更新"
cd ~
while true; do
	clear
	echo "更新日誌"
	echo "------------------------"
	echo "全部日誌:${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}你已經是最新版本！${gl_huang}v$sh_v${gl_bai}"
		send_stats "腳本已經最新了，無需更新"
	else
		echo "發現新版本！"
		echo -e "當前版本 v$sh_v最新版本${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}自動更新已開啟，每天凌晨2點腳本會自動更新！${gl_bai}"
	fi

	echo "------------------------"
	echo "1. 現在更新            2. 開啟自動更新            3. 關閉自動更新"
	echo "------------------------"
	echo "0. 返回主菜單"
	echo "------------------------"
	read -e -p "請輸入你的選擇:" choice
	case "$choice" in
		1)
			clear
			local country=$(curl -s ipinfo.io/country)
			if [ "$country" = "CN" ]; then
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/cn/kejilion.sh && chmod +x kejilion.sh
			else
				curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh
			fi
			canshu_v6
			CheckFirstRun_true
			yinsiyuanquan2
			cp -f ~/kejilion.sh /usr/local/bin/k > /dev/null 2>&1
			echo -e "${gl_lv}腳本已更新到最新版本！${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "腳本已經最新$sh_v_new"
			break_end
			~/kejilion.sh
			exit
			;;
		2)
			clear
			local country=$(curl -s ipinfo.io/country)
			local ipv6_address=$(curl -s --max-time 1 ipv6.ip.sb)
			if [ "$country" = "CN" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"CN\"/g' ./kejilion.sh"
			elif [ -n "$ipv6_address" ]; then
				SH_Update_task="curl -sS -O https://gh.kejilion.pro/raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh && sed -i 's/canshu=\"default\"/canshu=\"V6\"/g' ./kejilion.sh"
			else
				SH_Update_task="curl -sS -O https://raw.githubusercontent.com/kejilion/sh/main/kejilion.sh && chmod +x kejilion.sh"
			fi
			check_crontab_installed
			(crontab -l | grep -v "kejilion.sh") | crontab -
			# (crontab -l 2>/dev/null; echo "0 2 * * * bash -c \"$SH_Update_task\"") | crontab -
			(crontab -l 2>/dev/null; echo "$(shuf -i 0-59 -n 1) 2 * * * bash -c \"$SH_Update_task\"") | crontab -
			echo -e "${gl_lv}自動更新已開啟，每天凌晨2點腳本會自動更新！${gl_bai}"
			send_stats "開啟腳本自動更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}自動更新已關閉${gl_bai}"
			send_stats "關閉腳本自動更新"
			break_end
			;;
		*)
			kejilion_sh
			;;
	esac
done

}





kejilion_sh() {
while true; do
clear
echo -e "${gl_kjlan}"
echo "╦╔═╔═╗ ╦╦╦  ╦╔═╗╔╗╔ ╔═╗╦ ╦"
echo "╠╩╗║╣  ║║║  ║║ ║║║║ ╚═╗╠═╣"
echo "╩ ╩╚═╝╚╝╩╩═╝╩╚═╝╝╚╝o╚═╝╩ ╩"
echo -e "科技lion腳本工具箱 v$sh_v"
echo -e "命令行輸入${gl_huang}k${gl_kjlan}可快速啟動腳本${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}系統信息查詢"
echo -e "${gl_kjlan}2.   ${gl_bai}系統更新"
echo -e "${gl_kjlan}3.   ${gl_bai}系統清理"
echo -e "${gl_kjlan}4.   ${gl_bai}基礎工具"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR管理"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker管理"
echo -e "${gl_kjlan}7.   ${gl_bai}WARP管理"
echo -e "${gl_kjlan}8.   ${gl_bai}測試腳本合集"
echo -e "${gl_kjlan}9.   ${gl_bai}甲骨文云腳本合集"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP建站"
echo -e "${gl_kjlan}11.  ${gl_bai}應用市場"
echo -e "${gl_kjlan}12.  ${gl_bai}後台工作區"
echo -e "${gl_kjlan}13.  ${gl_bai}系統工具"
echo -e "${gl_kjlan}14.  ${gl_bai}服務器集群控制"
echo -e "${gl_kjlan}15.  ${gl_bai}廣告專欄"
echo -e "${gl_kjlan}16.  ${gl_bai}遊戲開服腳本合集"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}腳本更新"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}退出腳本"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "請輸入你的選擇:" choice

case $choice in
  1) linux_info ;;
  2) clear ; send_stats "系統更新" ; linux_update ;;
  3) clear ; send_stats "系統清理" ; linux_clean ;;
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
  16) games_server_tools ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "無效的輸入!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k命令參考用例"
echo "-------------------"
echo "視頻介紹: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
echo "以下是k命令參考用例："
echo "啟動腳本            k"
echo "安裝軟件包          k install nano wget | k add nano wget | k 安裝 nano wget"
echo "卸載軟件包          k remove nano wget | k del nano wget | k uninstall nano wget | k 卸載 nano wget"
echo "更新系統            k update | k 更新"
echo "清理系統垃圾        k clean | k 清理"
echo "重裝系統面板        k dd | k 重裝"
echo "bbr3控制面板        k bbr3 | k bbrv3"
echo "內核調優面板        k nhyh | k 內核優化"
echo "設置虛擬內存        k swap 2048"
echo "設置虛擬時區        k time Asia/Shanghai | k 時區 Asia/Shanghai"
echo "系統回收站          k trash | k hsz | k 回收站"
echo "系統備份功能        k backup | k bf | k 備份"
echo "ssh遠程連接工具     k ssh | k 遠程連接"
echo "rsync遠程同步工具   k rsync | k 遠程同步"
echo "硬盤管理工具        k disk | k 硬盤管理"
echo "內網穿透（服務端）  k frps"
echo "內網穿透（客戶端）  k frpc"
echo "軟件啟動            k start sshd | k 啟動 sshd"
echo "軟件停止            k stop sshd | k 停止 sshd"
echo "軟件重啟            k restart sshd | k 重啟 sshd"
echo "軟件狀態查看        k status sshd | k 狀態 sshd"
echo "軟件開機啟動        k enable docker | k autostart docke | k 開機啟動 docker"
echo "域名證書申請        k ssl"
echo "域名證書到期查詢    k ssl ps"
echo "docker管理平面      k docker"
echo "docker環境安裝      k docker install |k docker 安裝"
echo "docker容器管理      k docker ps |k docker 容器"
echo "docker鏡像管理      k docker img |k docker 鏡像"
echo "LDNMP站點管理       k web"
echo "LDNMP緩存清理       k web cache"
echo "安裝WordPress       k wp |k wordpress |k wp xxx.com"
echo "安裝反向代理        k fd |k rp |k 反代 |k fd xxx.com"
echo "安裝負載均衡        k loadbalance |k 負載均衡"
echo "安裝L4負載均衡      k stream |k L4負載均衡"
echo "防火牆面板          k fhq |k 防火牆"
echo "開放端口            k dkdk 8080 |k 打開端口 8080"
echo "關閉端口            k gbdk 7800 |k 關閉端口 7800"
echo "放行IP              k fxip 127.0.0.0/8 |k 放行IP 127.0.0.0/8"
echo "阻止IP              k zzip 177.5.25.36 |k 阻止IP 177.5.25.36"
echo "命令收藏夾          k fav | k 命令收藏夾"
echo "應用市場管理        k app"
echo "應用編號快捷管理    k app 26 | k app 1panel | k app npm"
echo "fail2ban管理        k fail2ban | k f2b"
echo "顯示系統信息        k info"
}



if [ "$#" -eq 0 ]; then
	# 如果沒有參數，運行交互式邏輯
	kejilion_sh
else
	# 如果有參數，執行相應函數
	case $1 in
		install|add|安装)
			shift
			send_stats "安裝軟件"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "卸載軟件"
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
		backup|bf|备份)
			linux_backup
			;;
		ssh|远程连接)
			ssh_manager
			;;

		rsync|远程同步)
			rsync_manager
			;;

		rsync_run)
			shift
			send_stats "定時rsync同步"
			run_task "$@"
			;;

		disk|硬盘管理)
			disk_manager
			;;

		wp|wordpress)
			shift
			ldnmp_wp "$@"

			;;
		fd|rp|反代)
			shift
			ldnmp_Proxy "$@"
	  		find_container_by_host_port "$port"
	  		if [ -z "$docker_name" ]; then
	  		  close_port "$port"
			  echo "已阻止IP+端口訪問該服務"
	  		else
			  ip_address
	  		  block_container_port "$docker_name" "$ipv4_address"
	  		fi
			;;

		loadbalance|负载均衡)
			ldnmp_Proxy_backend
			;;


		stream|L4负载均衡)
			ldnmp_Proxy_backend_stream
			;;

		swap)
			shift
			send_stats "快速設置虛擬內存"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "快速設置時區"
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


		打开端口|dkdk)
			shift
			open_port "$@"
			;;

		关闭端口|gbdk)
			shift
			close_port "$@"
			;;

		放行IP|fxip)
			shift
			allow_ip "$@"
			;;

		阻止IP|zzip)
			shift
			block_ip "$@"
			;;

		防火墙|fhq)
			iptables_panel
			;;

		命令收藏夹|fav)
			linux_fav
			;;

		status|状态)
			shift
			send_stats "軟件狀態查看"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "軟件啟動"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "軟件暫停"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "軟件重啟"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "軟件開機自啟"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "查看證書狀態"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "快速申請證書"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "快速申請證書"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "快捷安裝docker"
					install_docker
					;;
				ps|容器)
					send_stats "快捷容器管理"
					docker_ps
					;;
				img|镜像)
					send_stats "快捷鏡像管理"
					docker_image
					;;
				*)
					linux_docker
					;;
			esac
			;;

		web)
		   shift
			if [ "$1" = "cache" ]; then
				web_cache
			elif [ "$1" = "sec" ]; then
				web_security
			elif [ "$1" = "opt" ]; then
				web_optimization
			elif [ -z "$1" ]; then
				ldnmp_web_status
			else
				k_info
			fi
			;;


		app)
			shift
			send_stats "應用$@"
			linux_panel "$@"
			;;


		info)
			linux_info
			;;

		fail2ban|f2b)
			fail2ban_panel
			;;

		*)
			k_info
			;;
	esac
fi
