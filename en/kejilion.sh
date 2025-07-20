#!/bin/bash
sh_v="4.0.2"


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



# Define a function to execute commands
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



# Functions that collect function buried point information, record the current script version number, usage time, system version, CPU architecture, the country of the machine and the function name used by the user. They absolutely do not involve any sensitive information, please rest assured! Please believe me!
# Why do we need to design this function? The purpose is to better understand the functions that users like to use, and further optimize the functions to launch more functions that meet user needs.
# For the full text, you can search for the send_stats function call location, transparent and open source, and you can refuse to use it if you have any concerns.



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

# Prompt the user to agree to the terms
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}Welcome to the Tech lion script toolbox${gl_bai}"
	echo "For the first time using the script, please read and agree to the user license agreement."
	echo "User License Agreement: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "Do you agree to the above terms? (y/n):" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "License consent"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "Rejection of permission"
		clear
		exit
	fi
}

CheckFirstRun_false





ip_address() {

ipv4_address=$(curl -s https://ipinfo.io/ip && echo)
ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)

}



install() {
	if [ $# -eq 0 ]; then
		echo "Package parameters are not provided!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}Installing$package...${gl_bai}"
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
				echo "Unknown package manager!"
				return 1
			fi
		fi
	done
}


check_disk_space() {

	required_gb=$1
	required_space_mb=$((required_gb * 1024))
	available_space_mb=$(df -m / | awk 'NR==2 {print $4}')

	if [ $available_space_mb -lt $required_space_mb ]; then
		echo -e "${gl_huang}hint:${gl_bai}Insufficient disk space!"
		echo "Current available space: $((available_space_mb/1024))G"
		echo "Minimum demand space:${required_gb}G"
		echo "The installation cannot be continued. Please clean the disk space and try again."
		send_stats "Insufficient disk space"
		break_end
		kejilion
	fi
}


install_dependency() {
	install wget unzip tar jq grep
}

remove() {
	if [ $# -eq 0 ]; then
		echo "Package parameters are not provided!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}Uninstalling$package...${gl_bai}"
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
			echo "Unknown package manager!"
			return 1
		fi
	done
}


# Universal systemctl function, suitable for various distributions
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# Restart the service
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1The service has been restarted."
	else
		echo "Error: Restart$1Service failed."
	fi
}

# Start the service
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1The service has been started."
	else
		echo "Error: Start$1Service failed."
	fi
}

# Stop service
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1Service has been stopped."
	else
		echo "Error: Stop$1Service failed."
	fi
}

# Check service status
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1The service status is displayed."
	else
		echo "Error: Unable to display$1Service status."
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAMESet to power on."
}



break_end() {
	  echo -e "${gl_lv}Operation completed${gl_bai}"
	  echo "Press any key to continue..."
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
  "registry-mirrors": [
	"https://docker-0.unsee.tech",
	"https://docker.1panel.live",
	"https://registry.dockermirror.com",
	"https://docker.imgdb.de",
	"https://docker.m.daocloud.io",
	"https://hub.firefly.store",
	"https://hub.littlediary.cn",
	"https://hub.rat.dev",
	"https://dhub.kubesre.xyz",
	"https://cjie.eu.org",
	"https://docker.1panelproxy.com",
	"https://docker.hlmirror.com",
	"https://hub.fast360.xyz",
	"https://dockerpull.cn",
	"https://cr.laoyou.ip-ddns.com",
	"https://docker.melikeme.cn",
	"https://docker.kejilion.pro"
  ]
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
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/install && chmod +x install
	sh install --mirror Aliyun
	rm -f install
else
	curl -fsSL https://get.docker.com | sh
fi
install_add_docker_cn


}



install_add_docker() {
	echo -e "${gl_huang}Installing docker environment...${gl_bai}"
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
	fi
}


docker_ps() {
while true; do
	clear
	send_stats "Docker container management"
	echo "Docker container list"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "Container operation"
	echo "------------------------"
	echo "1. Create a new container"
	echo "------------------------"
	echo "2. Start the specified container 6. Start all containers"
	echo "3. Stop the specified container 7. Stop all containers"
	echo "4. Delete the specified container 8. Delete all containers"
	echo "5. Restart the specified container 9. Restart all containers"
	echo "------------------------"
	echo "11. Enter the specified container 12. View the container log"
	echo "13. View container network 14. View container occupancy"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your selection:" sub_choice
	case $sub_choice in
		1)
			send_stats "Create a new container"
			read -e -p "Please enter the creation command:" dockername
			$dockername
			;;
		2)
			send_stats "Start the specified container"
			read -e -p "Please enter the container name (multiple container names separated by spaces):" dockername
			docker start $dockername
			;;
		3)
			send_stats "Stop the specified container"
			read -e -p "Please enter the container name (multiple container names separated by spaces):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "Delete the specified container"
			read -e -p "Please enter the container name (multiple container names separated by spaces):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "Restart the specified container"
			read -e -p "Please enter the container name (multiple container names separated by spaces):" dockername
			docker restart $dockername
			;;
		6)
			send_stats "Start all containers"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "Stop all containers"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "Delete all containers"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "Invalid selection, please enter Y or N."
				;;
			esac
			;;
		9)
			send_stats "Restart all containers"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "Enter the container"
			read -e -p "Please enter the container name:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "View container log"
			read -e -p "Please enter the container name:" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "View container network"
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
			send_stats "View container occupancy"
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
	send_stats "Docker image management"
	echo "Docker image list"
	docker image ls
	echo ""
	echo "Mirror operation"
	echo "------------------------"
	echo "1. Get the specified image 3. Delete the specified image"
	echo "2. Update the specified image 4. Delete all images"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your selection:" sub_choice
	case $sub_choice in
		1)
			send_stats "Pull the mirror"
			read -e -p "Please enter the mirror name (please separate multiple mirror names with spaces):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}Getting the image:$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "Update the image"
			read -e -p "Please enter the mirror name (please separate multiple mirror names with spaces):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}Updated image:$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "Delete the mirror"
			read -e -p "Please enter the mirror name (please separate multiple mirror names with spaces):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "Delete all images"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "Invalid selection, please enter Y or N."
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
				echo "Unsupported distributions:$ID"
				return
				;;
		esac
	else
		echo "The operating system cannot be determined."
		return
	fi

	echo -e "${gl_lv}crontab is installed and the cron service is running.${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# Check if the configuration file exists, create the file and write the default settings if it does not exist
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# Use jq to handle updates of configuration files
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# Check whether the current configuration already has ipv6 settings
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# Update configuration and enable IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# Comparing original configuration with new configuration
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}IPv6 access is currently enabled${gl_bai}"
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

	# Check if the configuration file exists
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}The configuration file does not exist${gl_bai}"
		return
	fi

	# Read the current configuration
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# Use jq to handle updates of configuration files
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# Check the current ipv6 status
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# Comparing original configuration with new configuration
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}IPv6 access is currently closed${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}IPv6 access has been successfully closed${gl_bai}"
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
		echo "Please provide at least one port number"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# Delete existing closing rules
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# Add Open Rules
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "The port has been opened$port"
		fi
	done

	save_iptables_rules
	send_stats "The port has been opened"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "Please provide at least one port number"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# Delete existing open rules
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# Add a close rule
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "Port closed$port"
		fi
	done

	# Delete existing rules (if any)
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# Insert new rules to first
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "Port closed"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "Please provide at least one IP address or IP segment"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# Delete existing blocking rules
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# Add allow rules
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "Released IP$ip"
		fi
	done

	save_iptables_rules
	send_stats "Released IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "Please provide at least one IP address or IP segment"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# Delete existing allow rules
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# Add blocking rules
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP blocked$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP blocked"
}







enable_ddos_defense() {
	# Turn on defense DDoS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "Turn on DDoS defense"
}

# Turn off DDoS Defense
disable_ddos_defense() {
	# Turn off defense DDoS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "Turn off DDoS Defense"
}





# Functions that manage national IP rules
manage_country_rules() {
	local action="$1"
	local country_code="$2"
	local ipset_name="${country_code,,}_block"
	local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

	install ipset

	case "$action" in
		block)
			# Create if ipset does not exist
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# Download IP area file
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "Error: Download$country_codeIP zone file failed"
				exit 1
			fi

			# Add IP to ipset
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# Block IP with iptables
			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
			iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

			echo "Blocked successfully$country_codeIP address"
			rm "${country_code,,}.zone"
			;;

		allow)
			# Create an ipset for allowed countries (if not exist)
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# Download IP area file
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "Error: Download$country_codeIP zone file failed"
				exit 1
			fi

			# Delete existing national rules
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null
			ipset flush "$ipset_name"

			# Add IP to ipset
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# Only IPs in designated countries are allowed
			iptables -P INPUT DROP
			iptables -P OUTPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
			iptables -A OUTPUT -m set --match-set "$ipset_name" dst -j ACCEPT

			echo "Successfully only allowed$country_codeIP address"
			rm "${country_code,,}.zone"
			;;

		unblock)
			# Delete the iptables rules for the country
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null

			# Destroy ipset
			if ipset list "$ipset_name" &> /dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "Successfully lifted$country_codeIP address restrictions"
			;;

		*)
			;;
	esac
}




iptables_panel() {
  root_use
  install iptables
  save_iptables_rules
  while true; do
		  clear
		  echo "Advanced Firewall Management"
		  send_stats "Advanced Firewall Management"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "Firewall Management"
		  echo "------------------------"
		  echo "1. Open the specified port 2. Close the specified port"
		  echo "3. Open all ports 4. Close all ports"
		  echo "------------------------"
		  echo "5. IP whitelist 6. IP blacklist"
		  echo "7. Clear the specified IP"
		  echo "------------------------"
		  echo "11. Allow PING 12. Disable PING"
		  echo "------------------------"
		  echo "13. Start DDOS Defense 14. Turn off DDOS Defense"
		  echo "------------------------"
		  echo "15. Block specified country IP 16. Only specified country IPs are allowed"
		  echo "17. Release IP restrictions in designated countries"
		  echo "------------------------"
		  echo "0. Return to the previous menu"
		  echo "------------------------"
		  read -e -p "Please enter your selection:" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "Please enter the open port number:" o_port
				  open_port $o_port
				  send_stats "Open a specified port"
				  ;;
			  2)
				  read -e -p "Please enter the closed port number:" c_port
				  close_port $c_port
				  send_stats "Close the specified port"
				  ;;
			  3)
				  # Open all ports
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
				  send_stats "Open all ports"
				  ;;
			  4)
				  # Close all ports
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
				  send_stats "Close all ports"
				  ;;

			  5)
				  # IP whitelist
				  read -e -p "Please enter the IP or IP segment to be released:" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP blacklist
				  read -e -p "Please enter the blocked IP or IP segment:" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # Clear the specified IP
				  read -e -p "Please enter the cleared IP:" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "Clear the specified IP"
				  ;;
			  11)
				  # Allow PING
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "Allow PING"
				  ;;
			  12)
				  # Disable PING
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "Disable PING"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "Please enter the blocked country code (such as CN, US, JP):" country_code
				  manage_country_rules block $country_code
				  send_stats "Allowed countries$country_codeIP"
				  ;;
			  16)
				  read -e -p "Please enter the allowed country code (such as CN, US, JP):" country_code
				  manage_country_rules allow $country_code
				  send_stats "Block the country$country_codeIP"
				  ;;

			  17)
				  read -e -p "Please enter the cleared country code (such as CN, US, JP):" country_code
				  manage_country_rules unblock $country_code
				  send_stats "Clear the country$country_codeIP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}








add_swap() {
	local new_swap=$1  # 获取传入的参数

	# Get all swap partitions in the current system
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# Iterate over and delete all swap partitions
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# Make sure /swapfile is no longer used
	swapoff /swapfile

	# Delete the old /swapfile
	rm -f /swapfile

	# Create a new swap partition
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

	echo -e "The virtual memory size has been resized to${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# Determine whether virtual memory needs to be created
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # Get nginx version
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # Get the mysql version
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # Get the php version
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # Get the redis version
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # Create necessary directories and files
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf
  wget -O /home/web/redis/valkey.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/valkey.conf


  default_server_ssl

  # Download the docker-compose.yml file and replace it
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # Replace in docker-compose.yml file
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}





install_ldnmp() {

	  check_swap

	  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

	  if ! grep -q "network_mode" /home/web/docker-compose.yml; then
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

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -

	  fix_phpfpm_conf php
	  fix_phpfpm_conf php74
	  restart_ldnmp


	  clear
	  echo "LDNMP environment has been installed"
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
	echo "Renewal task has been updated"
}


install_ssltls() {
	  docker stop nginx > /dev/null 2>&1
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
	  mkdir -p /home/web/certs/
	  cp /etc/letsencrypt/live/$yuming/fullchain.pem /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1
	  cp /etc/letsencrypt/live/$yuming/privkey.pem /home/web/certs/${yuming}_key.pem > /dev/null 2>&1

	  docker start nginx > /dev/null 2>&1
}



install_ssltls_text() {
	echo -e "${gl_huang}$yumingPublic key information${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yumingPrivate key information${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}Certificate storage path${gl_bai}"
	echo "Public key: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "Private key: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}Quickly apply for an SSL certificate, automatically renew your signature before expiration${gl_bai}"
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
	echo -e "${gl_huang}The expiration of the applied certificate${gl_bai}"
	echo "Site information Certificate expiration time"
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
		send_stats "Successful application for domain name certificate"
	else
		send_stats "Application for domain name certificate failed"
		echo -e "${gl_hong}Notice:${gl_bai}The certificate application failed. Please check the following possible reasons and try again:"
		echo -e "1. Domain name spelling error ➠ Please check whether the domain name is entered correctly"
		echo -e "2. DNS resolution problem ➠ Confirm that the domain name has been correctly resolved to this server IP"
		echo -e "3. Network configuration issues ➠ If you use Cloudflare Warp and other virtual networks, please temporarily shut down"
		echo -e "4. Firewall restrictions ➠ Check whether port 80/443 is open to ensure verification is accessible"
		echo -e "5. The number of applications exceeds the limit ➠ Let's Encrypt has a weekly limit (5 times/domain name/week)"
		echo -e "6. Domestic registration restrictions ➠ Please confirm whether the domain name is registered in mainland China"
		break_end
		clear
		echo "Please try deploying again$webname"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "Domain name reuse"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "First resolve the domain name to the local IP:${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "Please enter your IP or the resolved domain name:" yuming
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
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/0.0.0.0/$ipv4_address/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|0000|$duankou|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on
	  docker exec nginx nginx -s reload
}


restart_redis() {
  rm -rf /home/web/redis/*
  docker exec redis redis-cli FLUSHALL > /dev/null 2>&1
  # docker exec -it redis redis-cli CONFIG SET maxmemory 1gb > /dev/null 2>&1
  # docker exec -it redis redis-cli CONFIG SET maxmemory-policy allkeys-lru > /dev/null 2>&1
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

  send_stats "renew$ldnmp_pods"
  echo "renew${ldnmp_pods}Finish"

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
  echo "Login information:"
  echo "username:$dbuse"
  echo "password:$dbusepasswd"
  echo
  send_stats "start up$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # Check if the configuration file exists
  if [ -f "$CONFIG_FILE" ]; then
	# Read API_TOKEN and zone_id from configuration files
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# Convert ZONE_IDS to an array
	ZONE_IDS=($ZONE_IDS)
  else
	# Prompt the user whether to clean the cache
	read -e -p "Need to clean Cloudflare's cache? (y/n):" answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF information is saved in$CONFIG_FILE, you can modify CF information later"
	  read -e -p "Please enter your API_TOKEN:" API_TOKEN
	  read -e -p "Please enter your CF username:" EMAIL
	  read -e -p "Please enter zone_id (multiple separated by spaces):" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # Loop through each zone_id and execute the clear cache command
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "Clearing cache for zone_id:$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "The cache clear request has been sent."
}



web_cache() {
  send_stats "Clean up site cache"
  cf_purge_cache
  cd /home/web && docker compose restart
  restart_redis
}



web_del() {

	send_stats "Delete site data"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "To delete site data, please enter your domain name (multiple domain names are separated by spaces):" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "Deleting the domain name:$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# Convert domain name to database name
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# Check whether the database exists before deleting it to avoid errors
		echo "Deleting the database:$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# Decide to turn on or off WAF according to mode parameters
	if [ "$mode" == "on" ]; then
		# Turn on WAF: Remove comments
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# Close WAF: Add Comments
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "Invalid parameter: Use 'on' or 'off'"
		return 1
	fi

	# Check nginx images and handle them according to the situation
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
		waf_status=" WAF已开启"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage=" cf模式已开启"
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
	# Delete old definition
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# Insert a new definition before the line with "Happy publishing"
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
	# Delete old definition
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# Insert a new definition before the line with "Happy publishing"
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


nginx_br() {

	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	if [ "$mode" == "on" ]; then
		# Turn on Brotli: Remove comments
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
		# Close Brotli: Add comments
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
		echo "Invalid parameter: Use 'on' or 'off'"
		return 1
	fi

	# Check nginx images and handle them according to the situation
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
		# Turn on Zstd: Remove comments
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
		# Close Zstd: Add comments
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
		echo "Invalid parameter: Use 'on' or 'off'"
		return 1
	fi

	# Check nginx images and handle them according to the situation
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
		echo "Invalid parameter: Use 'on' or 'off'"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP environment defense"
	  while true; do
		check_waf_status
		check_cf_mode
		if [ -x "$(command -v fail2ban-client)" ] ; then
			clear
			remove fail2ban
			rm -rf /etc/fail2ban
		else
			  clear
			  docker_name="fail2ban"
			  check_docker_app
			  echo -e "Server website defense program${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. Install the defense program"
			  echo "------------------------"
			  echo "5. View SSH interception record 6. View website interception record"
			  echo "7. View the list of defense rules 8. View real-time monitoring of logs"
			  echo "------------------------"
			  echo "11. Configure intercept parameters 12. Clear all blocked IPs"
			  echo "------------------------"
			  echo "21. cloudflare mode 22. High load on 5 seconds shield"
			  echo "------------------------"
			  echo "31. Turn on WAF 32. Turn off WAF"
			  echo "33. Turn on DDOS Defense 34. Turn off DDOS Defense"
			  echo "------------------------"
			  echo "9. Uninstall the defense program"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your selection:" sub_choice
			  case $sub_choice in
				  1)
					  f2b_install_sshd
					  cd /path/to/fail2ban/config/fail2ban/filter.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf
					  sed -i "/cloudflare/d" /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
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
					  local xxx="docker-nginx-418"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-bad-request"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-badbots"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-botsearch"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-deny"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-http-auth"
					  f2b_status_xxx
					  echo "------------------------"
					  local xxx="docker-nginx-unauthorized"
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
					  echo "Fail2Ban defense program has been uninstalled"
					  ;;

				  11)
					  install nano
					  nano /path/to/fail2ban/config/fail2ban/jail.d/nginx-docker-cc.conf
					  f2b_status
					  break
					  ;;

				  12)
					  docker exec -it fail2ban fail2ban-client unban --all
					  ;;

				  21)
					  send_stats "cloudflare mode"
					  echo "Go to the upper right corner of the cf background, select the API token on the left, and obtain the Global API Key"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "Enter CF account number:" cfuser
					  read -e -p "Enter the Global API Key for CF:" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /path/to/fail2ban/config/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "Cloudflare mode is configured to view intercept records in the cf background, site-security-events"
					  ;;

				  22)
					  send_stats "High load on 5 seconds shield"
					  echo -e "${gl_huang}The website automatically detects every 5 minutes. When it reaches the detection of a high load, the shield will be automatically turned on, and the low load will be automatically turned off for 5 seconds.${gl_bai}"
					  echo "--------------"
					  echo "Get CF parameters:"
					  echo -e "Go to the upper right corner of the cf background, select the API token on the left, and obtain it${gl_huang}Global API Key${gl_bai}"
					  echo -e "Go to the bottom right of the cf background domain name summary page to get${gl_huang}Region ID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "Enter CF account number:" cfuser
					  read -e -p "Enter the Global API Key for CF:" cftoken
					  read -e -p "Enter the region ID of the domain name in CF:" cfzonID

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
						  echo "High load automatic shield opening script has been added"
					  else
						  echo "Automatic shield script already exists, no need to add it"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "Site WAF is enabled"
					  send_stats "Site WAF is enabled"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "Site WAF has been closed"
					  send_stats "Site WAF has been closed"
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
		fi
	  break_end
	  done
}



check_nginx_mode() {

CONFIG_FILE="/home/web/nginx.conf"

# Get the current worker_processes setting value
current_value=$(grep -E '^\s*worker_processes\s+[0-9]+;' "$CONFIG_FILE" | awk '{print $2}' | tr -d ';')

# Set mode information according to value
if [ "$current_value" = "8" ]; then
	mode_info=" 高性能模式"
else
	mode_info=" 标准模式"
fi



}


check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# Check whether zstd is enabled and not commented (the whole line starts with zstd on;)
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status=" zstd压缩已开启"
	else
		zstd_status=""
	fi

	# Check if brotli is enabled and not commented
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status=" br压缩已开启"
	else
		br_status=""
	fi

	# Check if gzip is enabled and not commented
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status=" gzip压缩已开启"
	else
		gzip_status=""
	fi
}




web_optimization() {
		  while true; do
		  	  check_nginx_mode
			  check_nginx_compression
			  clear
			  send_stats "Optimize LDNMP environment"
			  echo -e "Optimize LDNMP environment${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. Standard mode 2. High performance mode (recommended 2H4G or above)"
			  echo "------------------------"
			  echo "3. Turn on gzip compression 4. Turn off gzip compression"
			  echo "5. Turn on br compression 6. Turn off br compression"
			  echo "7. Turn on zstd compression 8. Turn off zstd compression"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your selection:" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "Site standard mode"

				  # nginx tuning
				  sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

				  # php tuning
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php tuning
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql tuning
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced


				  echo "LDNMP environment has been set to standard mode"

					  ;;
				  2)
				  send_stats "Site high performance mode"

				  # nginx tuning
				  sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

				  # php tuning
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # php tuning
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit 512M 512M
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql tuning
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

				  echo "LDNMP environment has been set to high performance mode"

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

if docker inspect "$docker_name" &>/dev/null; then
	check_docker="${gl_lv}已安装${gl_bai}"
else
	check_docker="${gl_hui}未安装${gl_bai}"
fi

}


check_docker_app_ip() {
echo "------------------------"
echo "Access address:"
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

	local country=$(curl -s ipinfo.io/country)
	if [[ "$country" == "CN" ]]; then
		update_status=""
		return
	fi

	# Get the container creation time and image name
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# Extract mirror warehouses and tags
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# The default label is latest
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# Add support for official images
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# Get image publishing time from Docker Hub API
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# Verify the time of acquisition
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# Compare timestamps
		if [[ $container_created_ts -lt $last_updated_ts ]]; then
			update_status="${gl_huang}发现新版本!${gl_bai}"
		else
			update_status=""
		fi
	else
		update_status=""
	fi

}




block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# Get the IP address of the container
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "Error: Unable to get container$container_name_or_idIP address. Please check whether the container name or ID is correct."
		return 1
	fi

	install iptables


	# Check and block all other IPs
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# Check and release the specified IP
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Check and release the local network 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# Check and block all other IPs
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# Check and release the specified IP
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Check and release the local network 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ ports have been blocked from accessing the service"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# Get the IP address of the container
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "Error: Unable to get container$container_name_or_idIP address. Please check whether the container name or ID is correct."
		return 1
	fi

	install iptables


	# Clear rules that block all other IPs
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# Clear the rules for releasing the specified IP
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Clear the rules for release local network 127.0.0.0/8
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# Clear rules that block all other IPs
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# Clear the rules for releasing the specified IP
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Clear the rules for release local network 127.0.0.0/8
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ports have been allowed to access the service"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Error: Please provide the port number and the IP that is allowed to access."
		echo "Usage: block_host_port <port number> <authorized IP>"
		return 1
	fi

	install iptables


	# Denied all other IP access
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# Allow specified IP access
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# Allow local access
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# Denied all other IP access
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# Allow specified IP access
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# Allow local access
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Allow traffic for established and related connections
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "IP+ ports have been blocked from accessing the service"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Error: Please provide the port number and the IP that is allowed to access."
		echo "Usage: clear_host_port_rules <port number> <authorized IP>"
		return 1
	fi

	install iptables


	# Clear rules that block all other IP access
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# Clear rules that allow native access
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Clear rules that allow specified IP access
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# Clear rules that block all other IP access
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# Clear rules that allow native access
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Clear rules that allow specified IP access
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "IP+ports have been allowed to access the service"
	save_iptables_rules

}



setup_docker_dir() {

	mkdir -p /home/docker/ 2>/dev/null
	if [ -d "/vol1/1000/" ] && [ ! -d "/vol1/1000/docker" ]; then
		cp -f /home/docker /home/docker1 2>/dev/null
		rm -rf /home/docker 2>/dev/null
		mkdir -p /vol1/1000/docker 2>/dev/null
		ln -s /vol1/1000/docker /home/docker 2>/dev/null
	fi
}




docker_app() {
send_stats "${docker_name}manage"

while true; do
	clear
	check_docker_app
	check_docker_image_update $docker_name
	echo -e "$docker_name $check_docker $update_status"
	echo "$docker_describe"
	echo "$docker_url"
	if docker inspect "$docker_name" &>/dev/null; then
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
	echo "1. Install 2. Update 3. Uninstall"
	echo "------------------------"
	echo "5. Add domain name access 6. Delete domain name access"
	echo "7. Allow IP+ port access 8. Block IP+ port access"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your selection:" choice
	 case $choice in
		1)
			check_disk_space $app_size
			read -e -p "Enter the application external service port, and enter the default${docker_port}port:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			setup_docker_dir
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			clear
			echo "$docker_nameInstalled"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "Install$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum
			clear
			echo "$docker_nameInstalled"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "renew$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			rm -f /home/docker/${docker_name}_port.conf
			echo "The app has been uninstalled"
			send_stats "uninstall$docker_name"
			;;

		5)
			echo "${docker_name}Domain access settings"
			send_stats "${docker_name}Domain access settings"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "Domain name format example.com does not come with https://"
			web_del
			;;

		7)
			send_stats "Allow IP access${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "Block IP access${docker_name}"
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
		if docker inspect "$docker_name" &>/dev/null; then
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
		echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
		echo "5. Add domain name access 6. Delete domain name access"
		echo "7. Allow IP+ port access 8. Block IP+ port access"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Enter your choice:" choice
		case $choice in
			1)
				check_disk_space $app_size
				read -e -p "Enter the application external service port, and enter the default${docker_port}port:" app_port
				local app_port=${app_port:-${docker_port}}
				local docker_port=$app_port
				install jq
				install_docker
				docker_app_install
				setup_docker_dir
				echo "$docker_port" > "/home/docker/${docker_name}_port.conf"
				;;
			2)
				docker_app_update
				;;
			3)
				docker_app_uninstall
				rm -f /home/docker/${docker_name}_port.conf
				;;
			5)
				echo "${docker_name}Domain access settings"
				send_stats "${docker_name}Domain access settings"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "Domain name format example.com does not come with https://"
				web_del
				;;
			7)
				send_stats "Allow IP access${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "Block IP access${docker_name}"
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
  -p ${docker_port}:3000 \
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

# Functions that check whether the session exists
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# Loop until a non-existent session name is found
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# Create a new tmux session
tmux new -d -s "$base_name-$tmuxd_ID" "$tmuxd"


}



f2b_status() {
	 docker exec -it fail2ban fail2ban-client reload
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
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd.conf
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-sshd-ddos.conf
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/alpine-ssh.conf
	elif command -v dnf &>/dev/null; then
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/centos-ssh.conf
	else
		install rsyslog
		systemctl start rsyslog
		systemctl enable rsyslog
		cd /path/to/fail2ban/config/fail2ban/jail.d/
		curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/linux-ssh.conf
		systemctl restart rsyslog
	fi

	rm -f /path/to/fail2ban/config/fail2ban/jail.d/sshd.conf
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
		echo "Restarted"
		reboot
		;;
	  *)
		echo "Canceled"
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
	send_stats "Unable to install LDNMP environment again"
	echo -e "${gl_huang}hint:${gl_bai}The website construction environment is installed. No need to install again!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "Install LDNMP environment"
root_use
clear
echo -e "${gl_huang}The LDNMP environment is not installed, start installing the LDNMP environment...${gl_bai}"
check_disk_space 3
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "Install nginx environment"
root_use
clear
echo -e "${gl_huang}nginx is not installed, start installing nginx environment...${gl_bai}"
check_disk_space 1
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "nginx has been installed"
echo -e "Current version:${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "Please install the LDNMP environment first"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "Please install nginx environment first"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "Yours$webnameBuilt!"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webnameThe installation information is as follows:"

}

nginx_web_on() {
	  clear
	  echo "Yours$webnameBuilt!"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "Install$webname"
  echo "Start deployment$webname"
  if [ -z "$yuming" ]; then
	add_yuming
  fi
  repeat_add_yuming
  ldnmp_install_status
  install_ssltls
  certs_status
  add_db
  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/wordpress.com.conf
  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
  nginx_http_on

  cd /home/web/html
  mkdir $yuming
  cd $yuming
  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/refs/heads/main/wp-latest.zip
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
# echo "Database name: $dbname"
# echo "Username: $dbuse"
# echo "Password: $dbusepasswd"
# echo "Database address: mysql"
# echo "Table prefix: wp_"

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "Install$webname"
	echo "Start deployment$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "Please enter your anti-generation IP:" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "Please enter your anti-generation port:" port
	fi
	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy.conf
	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	sed -i "s/0.0.0.0/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	sed -i "s|0000|$port|g" /home/web/conf.d/$yuming.conf
	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}



ldnmp_Proxy_backend() {
	clear
	webname="反向代理-负载均衡"
	yuming="${1:-}"
	reverseproxy_port="${2:-}"

	send_stats "Install$webname"
	echo "Start deployment$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# Get multiple IPs entered by the user: ports (separated by spaces)
	if [ -z "$reverseproxy_port" ]; then
		read -e -p "Please enter your multiple anti-generation IP+ ports separated by spaces (for example, 127.0.0.1:3000 127.0.0.1:3002):" reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	# Dynamically generate upstream configuration
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	# Replace placeholders in templates
	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf

	nginx_http_on
	docker exec nginx nginx -s reload
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
		send_stats "LDNMP site management"
		echo "LDNMP environment"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}Certificate expiration time"
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
		echo "Site Directory"
		echo "------------------------"
		echo -e "data${gl_hui}/home/web/html${gl_bai}Certificate${gl_hui}/home/web/certs${gl_bai}Configuration${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "operate"
		echo "------------------------"
		echo "1. Apply for/update the domain name certificate 2. Change the site domain name"
		echo "3. Clean up the site cache 4. Create an associated site"
		echo "5. View access log 6. View error log"
		echo "7. Edit global configuration 8. Edit site configuration"
		echo "9. Manage site database 10. View site analysis report"
		echo "------------------------"
		echo "20. Delete the specified site data"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your selection:" sub_choice
		case $sub_choice in
			1)
				send_stats "Apply for a domain name certificate"
				read -e -p "Please enter your domain name:" yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "Change the site domain name"
				echo -e "${gl_hong}Highly recommended:${gl_bai}First back up the entire site data and then change the site domain name!"
				read -e -p "Please enter the old domain name:" oddyuming
				read -e -p "Please enter the new domain name:" yuming
				install_certbot
				install_ssltls
				certs_status

				# mysql replacement
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

				# Website directory replacement
				mv /home/web/html/$oddyuming /home/web/html/$yuming

				find /home/web/html/$yuming -type f -exec sed -i "s/$odd_dbname/$dbname/g" {} +
				find /home/web/html/$yuming -type f -exec sed -i "s/$oddyuming/$yuming/g" {} +

				mv /home/web/conf.d/$oddyuming.conf /home/web/conf.d/$yuming.conf
				sed -i "s/$oddyuming/$yuming/g" /home/web/conf.d/$yuming.conf

				rm /home/web/certs/${oddyuming}_key.pem
				rm /home/web/certs/${oddyuming}_cert.pem

				docker exec nginx nginx -s reload

				;;


			3)
				web_cache
				;;
			4)
				send_stats "Create an associated site"
				echo -e "Associate a new domain name for the existing site for access"
				read -e -p "Please enter the existing domain name:" oddyuming
				read -e -p "Please enter the new domain name:" yuming
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
				send_stats "View access log"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "View error log"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "Edit global configuration"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "Edit site configuration"
				read -e -p "To edit the site configuration, please enter the domain name you want to edit:" yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "View site data"
				install goaccess
				goaccess --log-format=COMBINED /home/web/log/nginx/access.log
				;;

			20)
				web_del
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null

				;;
			*)
				break  # 跳出循环，退出菜单
				;;
		esac
	done


}


check_panel_app() {
if $lujing > /dev/null 2>&1; then
	check_panel="${gl_lv}已安装${gl_bai}"
else
	check_panel=""
fi
}



install_panel() {
send_stats "${panelname}manage"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname}It is a popular and powerful operation and maintenance management panel nowadays."
	echo "Official website introduction:$panelurl "

	echo ""
	echo "------------------------"
	echo "1. Install 2. Management 3. Uninstall"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your selection:" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install
			send_stats "${panelname}Install"
			;;
		2)
			panel_app_manage
			send_stats "${panelname}control"

			;;
		3)
			panel_app_uninstall
			send_stats "${panelname}uninstall"
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

	send_stats "Install the frp server"
	# Generate random ports and credentials
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

	# Output generated information
	ip_address
	echo "------------------------"
	echo "Parameters required for client deployment"
	echo "Service IP:$ipv4_address"
	echo "token: $token"
	echo
	echo "FRP panel information"
	echo "FRP panel address: http://$ipv4_address:$dashboard_port"
	echo "FRP panel username:$dashboard_user"
	echo "FRP panel password:$dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "Install the frp client"
	read -e -p "Please enter the external network docking IP:" server_addr
	read -e -p "Please enter the external network docking token:" token
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
	send_stats "Add FRP intranet service"
	# Prompt the user to enter the service name and forwarding information
	read -e -p "Please enter the service name:" service_name
	read -e -p "Please enter the forwarding type (tcp/udp) [Enter default tcp]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "Please enter the intranet IP [Enter default 127.0.0.1]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "Please enter the intranet port:" local_port
	read -e -p "Please enter the external network port:" remote_port

	# Write user input to configuration file
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# Output generated information
	echo "Serve$service_nameAdded successfully to frpc.toml"

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "Delete the frp intranet service"
	# Prompt the user to enter the service name that needs to be deleted
	read -e -p "Please enter the service name that needs to be deleted:" service_name
	# Use sed to delete the service and its related configurations
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "Serve$service_nameDeleted successfully from frpc.toml"

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# Print the header
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
		# If there is service information, print the current service before processing the new service
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# Update the current service name
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# Clear the previous value
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
		# Print the information for the last service
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# Get the FRP server port
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# Generate access address
generate_access_urls() {
	# Get all ports first
	get_frp_ports

	# Check if there are ports other than 8055/8056
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# Show title and content only when there is a valid port
	if [ "$has_valid_ports" = true ]; then
		echo "FRP service external access address:"

		# Process IPv4 address
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# Process IPv6 addresses (if present)
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# Handling HTTPS configuration
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
	send_stats "FRP server"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP server$check_frp $update_status"
		echo "Build an FRP intranet penetration service environment to expose devices without public IP to the Internet"
		echo "Official website introduction: https://github.com/fatedier/frp/"
		echo "Video teaching: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
		echo "5. Domain name access for intranet service 6. Delete domain name access"
		echo "------------------------"
		echo "7. Allow IP+ port access 8. Block IP+ port access"
		echo "------------------------"
		echo "00. Refresh service status 0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Enter your choice:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config
				echo "The FRP server has been installed"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps
				echo "The FRP server has been updated"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				echo "The app has been uninstalled"
				;;
			5)
				echo "Reverse intranet penetration service into domain name access"
				send_stats "FRP access to external domain names"
				add_yuming
				read -e -p "Please enter your intranet penetration service port:" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "Domain name format example.com does not come with https://"
				web_del
				;;

			7)
				send_stats "Allow IP access"
				read -e -p "Please enter the port to be released:" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "Block IP access"
				echo "If you have accessed the anti-generation domain name, you can use this function to block IP+ port access, which is more secure."
				read -e -p "Please enter the port you need to block:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "Refresh the FRP service status"
				echo "FRP service status has been refreshed"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRP Client"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP Client$check_frp $update_status"
		echo "Docking with the server, after docking, you can create intranet penetration service to the Internet access"
		echo "Official website introduction: https://github.com/fatedier/frp/"
		echo "Video teaching: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
		echo "4. Add external services 5. Delete external services 6. Configure services manually"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Enter your choice:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc
				echo "The FRP client has been installed"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc
				echo "The FRP client has been updated"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055
				echo "The app has been uninstalled"
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

	local VIDEO_DIR="/home/yt-dlp"
	local URL_FILE="$VIDEO_DIR/urls.txt"
	local ARCHIVE_FILE="$VIDEO_DIR/archive.txt"

	mkdir -p "$VIDEO_DIR"

	while true; do

		if [ -x "/usr/local/bin/yt-dlp" ]; then
		   local YTDLP_STATUS="${gl_lv}已安装${gl_bai}"
		else
		   local YTDLP_STATUS="${gl_hui}未安装${gl_bai}"
		fi

		clear
		send_stats "yt-dlp download tool"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp is a powerful video download tool that supports thousands of sites including YouTube, Bilibili, Twitter, etc."
		echo -e "Official website address: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "Downloaded video list:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(None yet)"
		echo "-------------------------"
		echo "1. Install 2. Update 3. Uninstall"
		echo "-------------------------"
		echo "5. Single video download 6. Batch video download 7. Custom parameter download"
		echo "8. Download as MP3 audio 9. Delete the video directory 10. Cookie management (under development)"
		echo "-------------------------"
		echo "0. Return to the previous menu"
		echo "-------------------------"
		read -e -p "Please enter the option number:" choice

		case $choice in
			1)
				send_stats "Installing yt-dlp..."
				echo "Installing yt-dlp..."
				install ffmpeg
				sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				sudo chmod a+rx /usr/local/bin/yt-dlp
				echo "The installation is complete. Press any key to continue..."
				read ;;
			2)
				send_stats "Update yt-dlp..."
				echo "Update yt-dlp..."
				sudo yt-dlp -U
				echo "Update completed. Press any key to continue..."
				read ;;
			3)
				send_stats "Uninstalling yt-dlp..."
				echo "Uninstalling yt-dlp..."
				sudo rm -f /usr/local/bin/yt-dlp
				echo "Uninstall is complete. Press any key to continue..."
				read ;;
			5)
				send_stats "Single video download"
				read -e -p "Please enter the video link:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "After the download is complete, press any key to continue..." ;;
			6)
				send_stats "Batch video download"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# Enter multiple video link addresses\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "Now start batch download..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "The batch download is completed, press any key to continue..." ;;
			7)
				send_stats "Custom video download"
				read -e -p "Please enter the full yt-dlp parameter (excluding yt-dlp):" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "After the execution is completed, press any key to continue..." ;;
			8)
				send_stats "MP3 download"
				read -e -p "Please enter the video link:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "The audio download is completed, press any key to continue..." ;;

			9)
				send_stats "Delete video"
				read -e -p "Please enter the name of the delete video:" rmdir
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



# Fix dpkg interrupt problem
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}System update...${gl_bai}"
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
		echo "Unknown package manager!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}Cleaning up the system...${gl_bai}"
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
		echo "Clean the package manager cache..."
		apk cache clean
		echo "Delete the system log..."
		rm -rf /var/log/*
		echo "Delete APK cache..."
		rm -rf /var/cache/apk/*
		echo "Delete temporary files..."
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
		echo "Delete the system log..."
		rm -rf /var/log/*
		echo "Delete temporary files..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "Clean up unused dependencies..."
		pkg autoremove -y
		echo "Clean the package manager cache..."
		pkg clean -y
		echo "Delete the system log..."
		rm -rf /var/log/*
		echo "Delete temporary files..."
		rm -rf /tmp/*

	else
		echo "Unknown package manager!"
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
send_stats "Optimize DNS"
while true; do
	clear
	echo "Optimize DNS address"
	echo "------------------------"
	echo "Current DNS address"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. Foreign DNS optimization:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. Domestic DNS optimization:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. Manually edit DNS configuration"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your selection:" Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "Foreign DNS optimization"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "Domestic DNS optimization"
		;;
	  3)
		install nano
		nano /etc/resolv.conf
		send_stats "Manually edit DNS configuration"
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

	# If PasswordAuthentication is found, set to yes
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# If found PubkeyAuthentication is set to yes
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# If neither PasswordAuthentication nor PubkeyAuthentication matches, set the default value
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # Backup SSH configuration files
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "The SSH port has been modified to:$new_port"

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
	echo -e "The private key information has been generated. Be sure to copy and save it.${gl_huang}${ipv4_address}_ssh.key${gl_bai}File for future SSH login"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT private key login is enabled, ROOT password login has been closed, reconnection will take effect${gl_bai}"

}


import_sshkey() {

	read -e -p "Please enter your SSH public key contents (usually starting with 'ssh-rsa' or 'ssh-ed25519'):" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}Error: The public key content was not entered.${gl_bai}"
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
	echo -e "${gl_lv}The public key has been successfully imported, the ROOT private key login has been enabled, the ROOT password login has been closed, and the reconnection will take effect${gl_bai}"

}




add_sshpasswd() {

echo "Set your ROOT password"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ROOT login is set up!${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}hint:${gl_bai}This feature requires root user to run!" && break_end && kejilion
}



dd_xitong() {
		send_stats "Reinstall the system"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "Initial username after reinstallation:${gl_huang}root${gl_bai}Initial password:${gl_huang}LeitboGi0ro${gl_bai}Initial port:${gl_huang}22${gl_bai}"
		  echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "Initial username after reinstallation:${gl_huang}Administrator${gl_bai}Initial password:${gl_huang}Teddysun.com${gl_bai}Initial port:${gl_huang}3389${gl_bai}"
		  echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "Initial username after reinstallation:${gl_huang}root${gl_bai}Initial password:${gl_huang}123@@@${gl_bai}Initial port:${gl_huang}22${gl_bai}"
		  echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "Initial username after reinstallation:${gl_huang}Administrator${gl_bai}Initial password:${gl_huang}123@@@${gl_bai}Initial port:${gl_huang}3389${gl_bai}"
		  echo -e "Press any key to continue..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "Reinstall the system"
			echo "--------------------------------"
			echo -e "${gl_hong}Notice:${gl_bai}Reinstallation is risky to lose contact, and those who are worried should use it with caution. Reinstallation is expected to take 15 minutes, please back up the data in advance."
			echo -e "${gl_hui}Thanks to MollyLau and bin456789 for the script support!${gl_bai} "
			echo "------------------------"
			echo "1. Debian 12                  2. Debian 11"
			echo "3. Debian 10                  4. Debian 9"
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
			echo "35. openSUSE Tumbleweed 36. fnos Feiniu public beta version"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2022"
			echo "45. Windows Server 2019       46. Windows Server 2016"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. Return to the previous menu"
			echo "------------------------"
			read -e -p "Please select the system to reinstall:" sys_choice
			case "$sys_choice" in
			  1)
				send_stats "Reinstall debian 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  2)
				send_stats "Reinstall debian 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  3)
				send_stats "Reinstall debian 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  4)
				send_stats "Reinstall debian 9"
				dd_xitong_1
				bash InstallNET.sh -debian 9
				reboot
				exit
				;;
			  11)
				send_stats "Reinstall ubuntu 24.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "Reinstall ubuntu 22.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "Reinstall ubuntu 20.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "Reinstall ubuntu 18.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "Reinstall rockylinux10"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "Reinstall rockylinux9"
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				send_stats "Reinstall alma10"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "Reinstall alma9"
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				send_stats "Reinstall oracle10"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "Reinstall oracle9"
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				send_stats "Reinstall fedora42"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "Reinstall fedora41"
				dd_xitong_3
				bash reinstall.sh fedora 41
				reboot
				exit
				;;

			  29)
				send_stats "Reinstall centos10"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "Reinstall centos9"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "Reinstall alpine"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "Reinstall arch"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "Reinstall kali"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "Reinstall openeuler"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "Reinstall opensuse"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "Reload flying cow"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;


			  41)
				send_stats "Reinstall windows11"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;
			  42)
				dd_xitong_2
				send_stats "Reinstall Windows 10"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;
			  43)
				send_stats "Reinstall Windows 7"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "Reinstall windows server 22"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;
			  45)
				send_stats "Reinstall windows server 19"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;
			  46)
				send_stats "Reinstall windows server 16"
				dd_xitong_2
				bash InstallNET.sh -windows 2016 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "Reinstall windows11 ARM"
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
		  send_stats "bbrv3 management"

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
				  echo "You have installed xanmod's BBRv3 kernel"
				  echo "Current kernel version:$kernel_version"

				  echo ""
				  echo "Kernel Management"
				  echo "------------------------"
				  echo "1. Update the BBRv3 kernel 2. Uninstall the BBRv3 kernel"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# Step 3: Add a repository
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "The XanMod kernel has been updated. Take effect after restart"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "The XanMod kernel is uninstalled. Take effect after restart"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "Set up BBR3 acceleration"
		  echo "Video introduction: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		  echo "------------------------------------------------"
		  echo "Only support Debian/Ubuntu"
		  echo "Please back up the data and will enable BBR3 for you to upgrade the Linux kernel."
		  echo "VPS has 512M memory, please add 1G virtual memory in advance to prevent missing contact due to insufficient memory!"
		  echo "------------------------------------------------"
		  read -e -p "Are you sure to continue? (Y/N):" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "The current environment does not support it, only supports Debian and Ubuntu systems"
					break_end
					linux_Settings
				fi
			else
				echo "Unable to determine the operating system type"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# Step 3: Add a repository
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "XanMod kernel is installed and BBR3 is enabled successfully. Take effect after restart"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "Canceled"
			  ;;
			*)
			  echo "Invalid selection, please enter Y or N."
			  ;;
		  esac
		fi

}


elrepo_install() {
	# Import ELRepo GPG public key
	echo "Import the ELRepo GPG public key..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# Detect system version
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# Make sure we run on a supported operating system
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "Unsupported operating systems:$os_name"
		break_end
		linux_Settings
	fi
	# Print detected operating system information
	echo "Operating system detected:$os_name $os_version"
	# Install the corresponding ELRepo warehouse configuration according to the system version
	if [[ "$os_version" == 8 ]]; then
		echo "Install ELRepo repository configuration (version 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "Install ELRepo repository configuration (version 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "Install ELRepo repository configuration (version 10)..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "Unsupported system versions:$os_version"
		break_end
		linux_Settings
	fi
	# Enable the ELRepo kernel repository and install the latest mainline kernel
	echo "Enable the ELRepo kernel repository and install the latest mainline kernel..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "The ELRepo repository configuration is installed and updated to the latest mainline kernel."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "Red Hat Kernel Management"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "You have installed the elrepo kernel"
				  echo "Current kernel version:$kernel_version"

				  echo ""
				  echo "Kernel Management"
				  echo "------------------------"
				  echo "1. Update the elrepo kernel 2. Uninstall the elrepo kernel"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "Update the Red Hat kernel"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "The elrepo kernel is uninstalled. Take effect after restart"
						send_stats "Uninstall the Red Hat kernel"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "Please back up the data and will upgrade the Linux kernel for you"
		  echo "Video introduction: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		  echo "------------------------------------------------"
		  echo "Only support Red Hat series distributions CentOS/RedHat/Alma/Rocky/oracle"
		  echo "Upgrading the Linux kernel can improve system performance and security. It is recommended to try it if conditions permit and upgrade the production environment with caution!"
		  echo "------------------------------------------------"
		  read -e -p "Are you sure to continue? (Y/N):" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "Upgrade the Red Hat kernel"
			  server_reboot
			  ;;
			[Nn])
			  echo "Canceled"
			  ;;
			*)
			  echo "Invalid selection, please enter Y or N."
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}Update the virus database...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "Please specify the directory to scan."
		return
	fi

	echo -e "${gl_huang}Scanning directory $@...${gl_bai}"

	# Build mount parameters
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# Build clamscan command parameters
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# Execute Docker commands
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ Scan is completed, virus report is stored${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}If there is a virus, please${gl_huang}scan.log${gl_lv}Search for FOUND keyword in the file to confirm the location of the virus${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "Virus Scan Management"
		  while true; do
				clear
				echo "clamav virus scanning tool"
				echo "Video introduction: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
				echo "------------------------"
				echo "It is an open source antivirus software tool, mainly used to detect and remove various types of malware."
				echo "Including viruses, Trojan horses, spyware, malicious scripts and other harmful software."
				echo "------------------------"
				echo -e "${gl_lv}1. Full disk scan${gl_bai}             ${gl_huang}2. Scan the important directory${gl_bai}            ${gl_kjlan}3. Custom directory scanning${gl_bai}"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your selection:" sub_choice
				case $sub_choice in
					1)
					  send_stats "Full disk scan"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "Important directory scan"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "Custom directory scanning"
					  read -e -p "Please enter the directory to scan, separated by spaces (for example: /etc /var /usr /home /root):" directories
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




# High-performance mode optimization function
optimize_high_performance() {
	echo -e "${gl_lv}Switch to${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}Optimize file descriptors...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}Optimize virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}Optimize network settings...${gl_bai}"
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

	echo -e "${gl_lv}Optimize cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}Optimize CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}Other optimizations...${gl_bai}"
	# Disable large transparent pages to reduce latency
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# Disable NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# Equalization mode optimization function
optimize_balanced() {
	echo -e "${gl_lv}Switch to equalization mode...${gl_bai}"

	echo -e "${gl_lv}Optimize file descriptors...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}Optimize virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}Optimize network settings...${gl_bai}"
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

	echo -e "${gl_lv}Optimize cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}Optimize CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}Other optimizations...${gl_bai}"
	# Restore transparent page
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# Restore NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# Restore the default settings function
restore_defaults() {
	echo -e "${gl_lv}Restore to default settings...${gl_bai}"

	echo -e "${gl_lv}Restore file descriptor...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}Restore virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}Restore network settings...${gl_bai}"
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

	echo -e "${gl_lv}Restore cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}Restore CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}Restore other optimizations...${gl_bai}"
	# Restore transparent page
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# Restore NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# Website building optimization function
optimize_web_server() {
	echo -e "${gl_lv}Switch to the website building optimization mode...${gl_bai}"

	echo -e "${gl_lv}Optimize file descriptors...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}Optimize virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}Optimize network settings...${gl_bai}"
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

	echo -e "${gl_lv}Optimize cache management...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}Optimize CPU settings...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}Other optimizations...${gl_bai}"
	# Disable large transparent pages to reduce latency
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# Disable NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux kernel tuning management"
	  echo "Optimization of kernel parameters in Linux system"
	  echo "Video introduction: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "A variety of system parameter tuning modes are provided, and users can choose and switch according to their own usage scenarios."
	  echo -e "${gl_huang}hint:${gl_bai}Please use it with caution in the production environment!"
	  echo "--------------------"
	  echo "1. High-performance optimization mode: Maximize system performance and optimize file descriptors, virtual memory, network settings, cache management and CPU settings."
	  echo "2. Balanced optimization mode: Balance between performance and resource consumption, suitable for daily use."
	  echo "3. Website optimization mode: Optimize for the website server to improve concurrent connection processing capabilities, response speed and overall performance."
	  echo "4. Live broadcast optimization mode: Optimize the special needs of live broadcast streaming to reduce latency and improve transmission performance."
	  echo "5. Game server optimization mode: Optimize for game servers to improve concurrent processing capabilities and response speed."
	  echo "6. Restore the default settings: Restore the system settings to the default configuration."
	  echo "--------------------"
	  echo "0. Return to the previous menu"
	  echo "--------------------"
	  read -e -p "Please enter your selection:" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "High performance mode optimization"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "Balanced mode optimization"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "Website optimization model"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "Live streaming optimization"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "Game server optimization"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "Restore default settings"
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
				echo -e "${gl_lv}The system language has been modified to:$langReconnecting SSH takes effect.${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}The system language has been modified to:$langReconnecting SSH takes effect.${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "Unsupported systems:$ID"
				break_end
				;;
		esac
	else
		echo "Unsupported systems, system type cannot be recognized."
		break_end
	fi
}




linux_language() {
root_use
send_stats "Switch system language"
while true; do
  clear
  echo "Current system language:$LANG"
  echo "------------------------"
  echo "1. English 2. Simplified Chinese 3. Traditional Chinese"
  echo "------------------------"
  echo "0. Return to the previous menu"
  echo "------------------------"
  read -e -p "Enter your choice:" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "Switch to English"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "Switch to Simplified Chinese"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "Switch to Traditional Chinese"
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
echo -e "${gl_lv}Change is completed. Reconnect SSH to view changes!${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "Command line beautification tool"
  while true; do
	clear
	echo "Command line beautification tool"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Enter your choice:" choice

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
  send_stats "System Recycling Station"

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
	echo -e "Current recycling bin${trash_status}"
	echo -e "After enabling, the files deleted by rm will first enter the recycling bin to prevent the mistaken deletion of important files!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "The recycling bin is empty"
	echo "------------------------"
	echo "1. Enable the Recycle Bin 2. Close the Recycle Bin"
	echo "3. Restore content 4. Clear the recycling bin"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Enter your choice:" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "The Recycle Bin is enabled and deleted files will be moved to the Recycle Bin."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "The recycling bin is closed and the file will be deleted directly."
		sleep 2
		;;
	  3)
		read -e -p "Enter the file name to restore:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restoreRestored to the home directory."
		else
		  echo "The file does not exist."
		fi
		;;
	  4)
		read -e -p "Confirm to clear the recycling bin? [y/n]:" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "The recycling bin has been cleared."
		fi
		;;
	  *)
		break
		;;
	esac
  done
}



# Create a backup
create_backup() {
	send_stats "Create a backup"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# Prompt the user to enter the backup directory
	echo "Create a backup example:"
	echo "- Backup a single directory: /var/www"
	echo "- Backup multiple directories: /etc /home /var/log"
	echo "- Direct Enter will use the default directory (/etc /usr /home)"
	read -r -p "Please enter the directory to back up (multiple directories are separated by spaces, and if you enter directly, use the default directory):" input

	# If the user does not enter a directory, use the default directory
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# Separate the directory entered by the user into an array by spaces
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# Generate backup file prefix
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# Extract directory name and remove slashes
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# Remove the last underscore
	local PREFIX=${PREFIX%_}

	# Generate backup file name
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# Print the directory selected by the user
	echo "The backup directory you selected is:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# Create a backup
	echo "Creating a backup$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# Check if the command is successful
	if [ $? -eq 0 ]; then
		echo "The backup was created successfully:$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "Backup creation failed!"
		exit 1
	fi
}

# Restore backup
restore_backup() {
	send_stats "Restore backup"
	# Select the backup you want to restore
	read -e -p "Please enter the backup file name to restore:" BACKUP_NAME

	# Check if the backup file exists
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "The backup file does not exist!"
		exit 1
	fi

	echo "Recovering backup$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "Backup and restore successfully!"
	else
		echo "Backup recovery failed!"
		exit 1
	fi
}

# List backups
list_backups() {
	echo "Available backups:"
	ls -1 "$BACKUP_DIR"
}

# Delete backup
delete_backup() {
	send_stats "Delete backup"

	read -e -p "Please enter the backup file name to delete:" BACKUP_NAME

	# Check if the backup file exists
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "The backup file does not exist!"
		exit 1
	fi

	# Delete backup
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "The backup was deleted successfully!"
	else
		echo "Backup deletion failed!"
		exit 1
	fi
}

# Backup main menu
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "System backup function"
		echo "System backup function"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. Create a backup 2. Restore a backup 3. Delete the backup"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your selection:" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "Press Enter to continue..."
	done
}









# Show connection list
list_connections() {
	echo "Saved connection:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# Add a new connection
add_connection() {
	send_stats "Add a new connection"
	echo "Example to create a new connection:"
	echo "- Connection name: my_server"
	echo "- IP address: 192.168.1.100"
	echo "- Username: root"
	echo "- Port: 22"
	echo "------------------------"
	read -e -p "Please enter the connection name:" name
	read -e -p "Please enter your IP address:" ip
	read -e -p "Please enter the username (default: root):" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "Please enter the port number (default: 22):" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "Please select the authentication method:"
	echo "1. Password"
	echo "2. Key"
	read -e -p "Please enter the selection (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "Please enter your password:" password_or_key
			echo  # 换行
			;;
		2)
			echo "Please paste the key content (press press Enter twice after pasting):"
			local password_or_key=""
			while IFS= read -r line; do
				# If the input is empty and the key content already contains the beginning, the input ends
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# If it is the first line or the key content has been entered, continue to add
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# Check if it is the key content
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "Invalid choice!"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "The connection is saved!"
}



# Delete a connection
delete_connection() {
	send_stats "Delete a connection"
	read -e -p "Please enter the connection number to delete:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Error: The corresponding connection was not found."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# If the connection is using a key file, delete the key file
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "The connection has been deleted!"
}

# Use connection
use_connection() {
	send_stats "Use connection"
	read -e -p "Please enter the connection number to use:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Error: The corresponding connection was not found."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "Connecting to$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# Connect with a key
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "Connection failed! Please check the following:"
			echo "1. Is the key file path correct?$password_or_key"
			echo "2. Whether the key file permissions are correct (should be 600)."
			echo "3. Whether the target server allows login using the key."
		fi
	else
		# Connect with a password
		if ! command -v sshpass &> /dev/null; then
			echo "Error: sshpass is not installed, please install sshpass first."
			echo "Installation method:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "Connection failed! Please check the following:"
			echo "1. Whether the username and password are correct."
			echo "2. Whether the target server allows password login."
			echo "3. Whether the SSH service of the target server is running normally."
		fi
	fi
}


ssh_manager() {
	send_stats "ssh remote connection tool"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# Check if the configuration file and key directory exist, and if it does not exist, create it
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "SSH Remote Connection Tool"
		echo "Can be connected to other Linux systems via SSH"
		echo "------------------------"
		list_connections
		echo "1. Create a new connection 2. Use a connection 3. Delete a connection"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your selection:" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "Invalid selection, please try again." ;;
		esac
	done
}












# List available hard disk partitions
list_partitions() {
	echo "Available hard disk partitions:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# Mount the partition
mount_partition() {
	send_stats "Mount the partition"
	read -e -p "Please enter the partition name to be mounted (for example, sda1):" PARTITION

	# Check if the partition exists
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "The partition does not exist!"
		return
	fi

	# Check if the partition is already mounted
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "The partition is already mounted!"
		return
	fi

	# Create a mount point
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# Mount the partition
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "Partition mount successfully:$MOUNT_POINT"
	else
		echo "Partition mount failed!"
		rmdir "$MOUNT_POINT"
	fi
}

# Uninstall the partition
unmount_partition() {
	send_stats "Uninstall the partition"
	read -e -p "Please enter the partition name (for example, sda1):" PARTITION

	# Check if the partition is already mounted
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "The partition is not mounted!"
		return
	fi

	# Uninstall the partition
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "Partition uninstallation successfully:$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "Partition uninstallation failed!"
	fi
}

# List mounted partitions
list_mounted_partitions() {
	echo "Mounted partition:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# Format partition
format_partition() {
	send_stats "Format partition"
	read -e -p "Please enter the partition name to format (for example, sda1):" PARTITION

	# Check if the partition exists
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "The partition does not exist!"
		return
	fi

	# Check if the partition is already mounted
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "The partition has been mounted, please uninstall it first!"
		return
	fi

	# Select a file system type
	echo "Please select the file system type:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "Please enter your selection:" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "Invalid choice!"; return ;;
	esac

	# Confirm formatting
	read -e -p "Confirm formatting partition /dev/$PARTITIONfor$FS_TYPEIs it? (y/n):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "The operation has been cancelled."
		return
	fi

	# Format partition
	echo "Formatting partition /dev/$PARTITIONfor$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "The partition format was successful!"
	else
		echo "Partition formatting failed!"
	fi
}

# Check partition status
check_partition() {
	send_stats "Check partition status"
	read -e -p "Please enter the partition name to check (for example sda1):" PARTITION

	# Check if the partition exists
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "The partition does not exist!"
		return
	fi

	# Check partition status
	echo "Check partition /dev/$PARTITIONStatus:"
	fsck "/dev/$PARTITION"
}

# Main Menu
disk_manager() {
	send_stats "Hard disk management function"
	while true; do
		clear
		echo "Hard disk partition management"
		echo -e "${gl_huang}This function is internally tested during the test period, please do not use it in the production environment.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. Mount the partition 2. Uninstall the partition 3. View mounted partition"
		echo "4. Format the partition 5. Check the partition status"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your selection:" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "Press Enter to continue..."
	done
}




# Show task list
list_tasks() {
	echo "Saved synchronization tasks:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# Add a new task
add_task() {
	send_stats "Add a new synchronization task"
	echo "Create a new synchronization task example:"
	echo "- Task name: backup_www"
	echo "- Local Directory: /var/www"
	echo "- Remote address: user@192.168.1.100"
	echo "- Remote Directory: /backup/www"
	echo "- Port number (default 22)"
	echo "---------------------------------"
	read -e -p "Please enter the task name:" name
	read -e -p "Please enter the local directory:" local_path
	read -e -p "Please enter the remote directory:" remote_path
	read -e -p "Please enter the remote user @IP:" remote
	read -e -p "Please enter the SSH port (default 22):" port
	port=${port:-22}

	echo "Please select the authentication method:"
	echo "1. Password"
	echo "2. Key"
	read -e -p "Please select (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "Please enter your password:" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "Please paste the key content (press press Enter twice after pasting):"
			local password_or_key=""
			while IFS= read -r line; do
				# If the input is empty and the key content already contains the beginning, the input ends
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# If it is the first line or the key content has been entered, continue to add
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# Check if it is the key content
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "Invalid key content!"
				return
			fi
			;;
		*)
			echo "Invalid choice!"
			return
			;;
	esac

	echo "Please select the synchronization mode:"
	echo "1. Standard mode (-avz)"
	echo "2. Delete the target file (-avz --delete)"
	read -e -p "Please select (1/2):" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "Invalid selection, use default -avz"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "Task saved!"
}

# Delete a task
delete_task() {
	send_stats "Delete synchronization tasks"
	read -e -p "Please enter the task number to delete:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "Error: The corresponding task was not found."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# If the task is using a key file, delete the key file
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "Task deleted!"
}


run_task() {
	send_stats "Perform synchronization tasks"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# Analyze parameters
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# If there is no incoming task number, prompt the user to enter
	if [[ -z "$num" ]]; then
		read -e -p "Please enter the task number to be executed:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "Error: The task was not found!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# Adjust source and target path according to synchronization direction
	if [[ "$direction" == "pull" ]]; then
		echo "Pulling synchronization to local:$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "Push synchronization to the remote end:$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# Add SSH connection common parameters
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "Error: sshpass is not installed, please install sshpass first."
			echo "Installation method:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# Check whether the key file exists and whether the permissions are correct
		if [[ ! -f "$password_or_key" ]]; then
			echo "Error: The key file does not exist:$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "Warning: The key file permissions are incorrect, and are being repaired..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "Synchronization is complete!"
	else
		echo "Synchronization failed! Please check the following:"
		echo "1. Is the network connection normal?"
		echo "2. Is the remote host accessible?"
		echo "3. Is the authentication information correct?"
		echo "4. Do local and remote directories have correct access permissions"
	fi
}


# Create a timed task
schedule_task() {
	send_stats "Add synchronization timing tasks"

	read -e -p "Please enter the task number to be synchronized regularly:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Error: Please enter a valid task number!"
		return
	fi

	echo "Please select the timed execution interval:"
	echo "1) Execute once an hour"
	echo "2) Perform once a day"
	echo "3) Execute once a week"
	read -e -p "Please enter options (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "Error: Please enter a valid option!" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# Check if the same task already exists
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "Error: The timing synchronization of this task already exists!"
		return
	fi

	# Create a crontab to the user
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "The timing task has been created:$cron_job"
}

# View scheduled tasks
view_tasks() {
	echo "Current timing tasks:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# Delete timing tasks
delete_task_schedule() {
	send_stats "Delete synchronization timing tasks"
	read -e -p "Please enter the task number to delete:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Error: Please enter a valid task number!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "Deleted task number$numTiming tasks"
}


# Task Management Main Menu
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync remote synchronization tool"
		echo "Synchronization between remote directories supports incremental synchronization, efficient and stable."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. Create a new task 2. Delete a task"
		echo "3. Perform local synchronization to the remote end 4. Perform remote synchronization to the local end"
		echo "5. Create a timing task 6. Delete a timing task"
		echo "---------------------------------"
		echo "0. Return to the previous menu"
		echo "---------------------------------"
		read -e -p "Please enter your selection:" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "Invalid selection, please try again." ;;
		esac
		read -e -p "Press Enter to continue..."
	done
}









linux_ps() {

	clear
	send_stats "System information query"

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

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1 % 3600) / 60); if (run_days > 0) printf("%d天 ", run_days); if (run_hours > 0) printf("%d时 ", run_hours); printf("%d分\n", run_minutes)}')

	local timezone=$(current_timezone)


	echo ""
	echo -e "System information query"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Host Name:${gl_bai}$hostname"
	echo -e "${gl_kjlan}System version:${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linux version:${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU architecture:${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPU model:${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}Number of CPU cores:${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU frequency:${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU occupancy:${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}System load:${gl_bai}$load"
	echo -e "${gl_kjlan}Physical memory:${gl_bai}$mem_info"
	echo -e "${gl_kjlan}Virtual memory:${gl_bai}$swap_info"
	echo -e "${gl_kjlan}Hard disk occupation:${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Total Receive:${gl_bai}$rx"
	echo -e "${gl_kjlan}Total send:${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Network algorithm:${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Operator:${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4 address:${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6 address:${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS address:${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}Geographical location:${gl_bai}$country $city"
	echo -e "${gl_kjlan}System time:${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Runtime:${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "Basic Tools"
	  echo -e "Basic tools"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}curl download tool${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget download tool${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo super management permission tool${gl_kjlan}4.   ${gl_bai}socat communication connection tool"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop system monitoring tool${gl_kjlan}6.   ${gl_bai}iftop network traffic monitoring tool"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP compression decompression tool${gl_kjlan}8.   ${gl_bai}tar GZ compression decompression tool"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux multi-channel background running tool${gl_kjlan}10.  ${gl_bai}ffmpeg video encoding live streaming tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop modern monitoring tools${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}range file management tool"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu disk occupation viewing tool${gl_kjlan}14.  ${gl_bai}fzf global search tool"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim text editor${gl_kjlan}16.  ${gl_bai}nano text editor${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}git version control system"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}The Matrix Screen Guarantee${gl_kjlan}22.  ${gl_bai}Train screen security"
	  echo -e "${gl_kjlan}26.  ${gl_bai}Tetris game${gl_kjlan}27.  ${gl_bai}Snake-eating game"
	  echo -e "${gl_kjlan}28.  ${gl_bai}Space Invader Game"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Install all${gl_kjlan}32.  ${gl_bai}All installations (excluding screen savers and games)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Uninstall all"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}Install the specified tool${gl_kjlan}42.  ${gl_bai}Uninstall the specified tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  curl --help
			  send_stats "Install curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  wget --help
			  send_stats "Install wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  sudo --help
			  send_stats "Install sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  socat -h
			  send_stats "Install socat"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "Install htop"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "Install iftop"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  unzip
			  send_stats "Install unzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  tar --help
			  send_stats "Install tar"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  tmux --help
			  send_stats "Install tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "The tool has been installed and the usage method is as follows:"
			  ffmpeg --help
			  send_stats "Install ffmpeg"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "Install btop"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "Install ranger"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "Install ncdu"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "Install fzf"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "Install vim"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "Install nano"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "Install git"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "Install cmatrix"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "Install sl"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "Install bastet"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "Install nsnake"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "Install ninvaders"
			  ;;

		  31)
			  clear
			  send_stats "Install all"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "Install all (excluding games and screen savers)"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "Uninstall all"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "Please enter the installed tool name (wget curl sudo htop):" installname
			  install $installname
			  send_stats "Install the specified software"
			  ;;
		  42)
			  clear
			  read -e -p "Please enter the uninstalled tool name (htop ufw tmux cmatrix):" removename
			  remove $removename
			  send_stats "Uninstall the specified software"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "Invalid input!"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "bbr management"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			  echo "Current TCP blocking algorithm:$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR Management"
			  echo "------------------------"
			  echo "1. Turn on BBRv3 2. Turn off BBRv3 (restarts)"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your selection:" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "Alpine enable bbr3"
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
		wget --no-check-certificate -O tcpx.sh ${gh_proxy}raw.githubusercontent.com/ylx2016/Linux-NetSpeed/master/tcpx.sh
		chmod +x tcpx.sh
		./tcpx.sh
	fi


}





linux_docker() {

	while true; do
	  clear
	  # send_stats "docker management"
	  echo -e "Docker Management"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Install and update Docker environment${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}View Docker global status${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Docker container management${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker image management"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker Network Management"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker volume management"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Clean useless docker containers and mirror network data volumes"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Replace Docker source"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Edit daemon.json file"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Enable Docker-ipv6 access"
	  echo -e "${gl_kjlan}12.  ${gl_bai}Close Docker-ipv6 access"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Uninstall the Docker environment"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "Install docker environment"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "Docker global status"
			  echo "Docker version"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker image:${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "Docker container:${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Docker volume:${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Docker Network:${gl_lv}$network_count${gl_bai}"
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
				  send_stats "Docker Network Management"
				  echo "Docker network list"
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
				  echo "Network operation"
				  echo "------------------------"
				  echo "1. Create a network"
				  echo "2. Join the Internet"
				  echo "3. Exit the network"
				  echo "4. Delete the network"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "Create a network"
						  read -e -p "Set a new network name:" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "Join the Internet"
						  read -e -p "Join the network name:" dockernetwork
						  read -e -p "Those containers are added to the network (multiple container names are separated by spaces):" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "Join the Internet"
						  read -e -p "Exit network name:" dockernetwork
						  read -e -p "Those containers exit the network (multiple container names are separated by spaces):" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "Delete the network"
						  read -e -p "Please enter the network name to delete:" dockernetwork
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
				  send_stats "Docker volume management"
				  echo "Docker volume list"
				  docker volume ls
				  echo ""
				  echo "Volume operation"
				  echo "------------------------"
				  echo "1. Create a new volume"
				  echo "2. Delete the specified volume"
				  echo "3. Delete all volumes"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "Create a new volume"
						  read -e -p "Set the new volume name:" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "Enter the delete volume name (please separate multiple volume names with spaces):" dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "Delete all volumes"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "Invalid selection, please enter Y or N."
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
			  send_stats "Docker cleaning"
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "Docker source"
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
			  send_stats "Docker v6 open"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker v6 level"
			  docker_ipv6_off
			  ;;

		  20)
			  clear
			  send_stats "Docker uninstall"
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
				  echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "Invalid input!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "Test script collection"
	  echo -e "Test script collection"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IP and unlock status detection"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT Unlock Status Detection"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Region streaming media unlock test"
	  echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu streaming media unlock detection"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP quality physical examination script${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Network speed measurement"
	  echo -e "${gl_kjlan}11.  ${gl_bai}besttrace three network backhaul delay routing test"
	  echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace Three-network backhaul line test"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed three-net speed measurement"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace fast backhaul test script"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace Specifies IP backhaul test script"
	  echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 three-network line test"
	  echo -e "${gl_kjlan}17.  ${gl_bai}i-abc multifunction speed test script"
	  echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality Network Quality Physical Examination Script${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Hardware performance testing"
	  echo -e "${gl_kjlan}21.  ${gl_bai}yabs performance testing"
	  echo -e "${gl_kjlan}22.  ${gl_bai}iicu/gb5 CPU performance test script"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Comprehensive test"
	  echo -e "${gl_kjlan}31.  ${gl_bai}bench performance test"
	  echo -e "${gl_kjlan}32.  ${gl_bai}Spiritysdx Fusion Monster Review${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "ChatGPT unlock status detection"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "Region streaming media unlock test"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "yeahwu streaming media unlock detection"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_IP quality physical examination script"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "Besttrace three network backhaul delay routing test"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "mtr_trace three network return line test"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "Superspeed three-net speed measurement"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace fast backhaul test script"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace specifies IP backhaul test script"
			  echo "List of IPs that can be referenced"
			  echo "------------------------"
			  echo "Beijing Telecom: 219.141.136.12"
			  echo "Beijing Unicom: 202.106.50.1"
			  echo "Beijing Mobile: 221.179.155.161"
			  echo "Shanghai Telecom: 202.96.209.133"
			  echo "Shanghai Unicom: 210.22.97.1"
			  echo "Shanghai Mobile: 211.136.112.200"
			  echo "Guangzhou Telecom: 58.60.188.222"
			  echo "Guangzhou Unicom: 210.21.196.6"
			  echo "Guangzhou Mobile: 120.196.165.24"
			  echo "Chengdu Telecom: 61.139.2.69"
			  echo "Chengdu Unicom: 119.6.6.6"
			  echo "Chengdu Mobile: 211.137.96.205"
			  echo "Hunan Telecom: 36.111.200.100"
			  echo "Hunan Unicom: 42.48.16.100"
			  echo "Hunan Mobile: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "Enter a specified IP:" testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "ludashi2020 three-network line test"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc multifunction speed test script"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "Network quality test script"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "yabs performance testing"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "iicu/gb5 CPU performance test script"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "bench performance test"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "Spiritysdx Fusion Monster Review"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "Oracle Cloud Script Collection"
	  echo -e "Oracle Cloud Script Collection"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Install idle machine active script"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Uninstall idle machine active script"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD reinstall system script"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Detective R start script"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Turn on ROOT password login mode"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPV6 recovery tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "Active script: CPU occupies 10-20% memory occupies 20%"
			  read -e -p "Are you sure to install it? (Y/N):" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # Set default values
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # Prompt the user to enter the number of CPU cores and occupancy percentage, and if entered, use the default value.
				  read -e -p "Please enter the number of CPU cores [default:$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "Please enter the CPU usage percentage range (for example, 10-20) [Default:$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "Please enter the memory usage percentage [default:$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "Please enter the Speedtest interval time (seconds) [default:$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # Run Docker container
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "Oracle Cloud Installation Active Script"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "Oracle Cloud Uninstall Active Script"
			  ;;

		  3)
		  clear
		  echo "Reinstall the system"
		  echo "--------------------------------"
		  echo -e "${gl_hong}Notice:${gl_bai}Reinstallation is risky to lose contact, and those who are worried should use it with caution. Reinstallation is expected to take 15 minutes, please back up the data in advance."
		  read -e -p "Are you sure to continue? (Y/N):" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "Please select the system to reinstall: 1. Debian12 | 2. Ubuntu20.04:" sys_choice

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
					echo "Invalid selection, please re-enter."
					;;
				esac
			  done

			  read -e -p "Please enter your reinstalled password:" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "Oracle Cloud Reinstall System Script"
			  ;;
			[Nn])
			  echo "Canceled"
			  ;;
			*)
			  echo "Invalid selection, please enter Y or N."
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  echo "This feature is in the development stage, so stay tuned!"
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "This function is provided by the master jhb, thanks to him!"
			  send_stats "ipv6 fix"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "Invalid input!"
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
		echo -e "${gl_lv}The environment has been installed${gl_bai}container:${gl_lv}$container_count${gl_bai}Mirror:${gl_lv}$image_count${gl_bai}network:${gl_lv}$network_count${gl_bai}roll:${gl_lv}$volume_count${gl_bai}"
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
		echo -e "${gl_lv}The environment is installed${gl_bai}  $output  $db_output"
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
	# send_stats "LDNMP website building"
	echo -e "${gl_huang}LDNMP website building"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}Install LDNMP environment${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}Install WordPress${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}Install Discuz Forum${gl_huang}4.   ${gl_bai}Install the Kadao Cloud Desktop"
	echo -e "${gl_huang}5.   ${gl_bai}Install Apple CMS Film and Television Station${gl_huang}6.   ${gl_bai}Install a Unicorn Digital Card Network"
	echo -e "${gl_huang}7.   ${gl_bai}Install the flarum forum website${gl_huang}8.   ${gl_bai}Install typecho lightweight blog website"
	echo -e "${gl_huang}9.   ${gl_bai}Install LinkStack Shared Link Platform${gl_huang}20.  ${gl_bai}Customize dynamic site"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}Install nginx only${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}Site redirection"
	echo -e "${gl_huang}23.  ${gl_bai}Site reverse proxy-IP+port${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}Site reverse proxy - domain name"
	echo -e "${gl_huang}25.  ${gl_bai}Install Bitwarden password management platform${gl_huang}26.  ${gl_bai}Install Halo Blog Website"
	echo -e "${gl_huang}27.  ${gl_bai}Install AI Painting Prompt Word Generator${gl_huang}28.  ${gl_bai}Site reverse proxy-load balancing"
	echo -e "${gl_huang}30.  ${gl_bai}Customize static site"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}Site data management${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}Back up the entire site data"
	echo -e "${gl_huang}33.  ${gl_bai}Timed remote backup${gl_huang}34.  ${gl_bai}Restore the entire site data"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}Protect LDNMP environment${gl_huang}36.  ${gl_bai}Optimize LDNMP environment"
	echo -e "${gl_huang}37.  ${gl_bai}Update LDNMP environment${gl_huang}38.  ${gl_bai}Uninstall LDNMP environment"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}Return to main menu"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "Please enter your selection:" sub_choice


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
	  # Discuz Forum
	  webname="Discuz论坛"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/discuz.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20240520.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  ldnmp_web_on
	  echo "Database address: mysql"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Table prefix: discuz_"


		;;

	  4)
	  clear
	  # Kedao Cloud Desktop
	  webname="可道云桌面"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/kdy.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
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
	  echo "Database address: mysql"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Database name:$dbname"
	  echo "redis host: redis"

		;;

	  5)
	  clear
	  # Apple CMS
	  webname="苹果CMS"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/maccms.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
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
	  echo "Database address: mysql"
	  echo "Database port: 3306"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Database prefix: mac_"
	  echo "------------------------"
	  echo "Log in to the background address after installation is successful"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # One-legged counting card
	  webname="独脚数卡"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget ${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

	  restart_ldnmp


	  ldnmp_web_on
	  echo "Database address: mysql"
	  echo "Database port: 3306"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo ""
	  echo "redis address: redis"
	  echo "Redis password: Not filled in by default"
	  echo "Redis port: 6379"
	  echo ""
	  echo "Website url: https://$yuming"
	  echo "Background login path: /admin"
	  echo "------------------------"
	  echo "Username: admin"
	  echo "Password: admin"
	  echo "------------------------"
	  echo "If red error0 appears in the upper right corner when logging in, please use the following command:"
	  echo "I am also very angry that the unicorn number card is so troublesome, and there will be such problems!"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # Flarum Forum
	  webname="flarum论坛"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/flarum.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
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
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/polls"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/sitemap"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/oauth"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/best-answer:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"


	  restart_ldnmp


	  ldnmp_web_on
	  echo "Database address: mysql"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Table prefix: flarum_"
	  echo "Administrator information is set by yourself"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/typecho.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
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
	  echo "Database prefix: typecho_"
	  echo "Database address: mysql"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Database name:$dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/refs/heads/main/index_php.conf
	  sed -i "s|/var/www/html/yuming.com/|/var/www/html/yuming.com/linkstack|g" /home/web/conf.d/$yuming.conf
	  sed -i "s|yuming.com|$yuming|g" /home/web/conf.d/$yuming.conf
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
	  echo "Database address: mysql"
	  echo "Database port: 3306"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  clear
	  echo -e "[${gl_huang}1/6${gl_bai}] Upload PHP source code"
	  echo "-------------"
	  echo "Currently, only zip-format source code packages are allowed. Please put the source code packages in /home/web/html/${yuming}In the directory"
	  read -e -p "You can also enter the download link to remotely download the source code package. Directly press Enter to skip remote download:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] The path where index.php is located"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "Please enter the path of index.php, similar to (/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] Please select the PHP version"
	  echo "-------------"
	  read -e -p "1. The latest version of php | 2. php7.4:" pho_v
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
		  echo "Invalid selection, please re-enter."
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] Install the specified extension"
	  echo "-------------"
	  echo "Installed extensions"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] Edit site configuration"
	  echo "-------------"
	  echo "Press any key to continue, and you can set the site configuration in detail, such as pseudo-static contents, etc."
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] Database Management"
	  echo "-------------"
	  read -e -p "1. I build a new site 2. I build an old site and have a database backup:" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "The database backup must be a .gz-end compressed package. Please put it in the /home/ directory to support the import of backup data of Pagoda/1panel."
			  read -e -p "You can also enter the download link to remotely download the backup data. Directly press Enter will skip remote download:" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "Database import table data"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "Database import completed"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "Database address: mysql"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Table prefix:$prefix"
	  echo "Administrator login information is set by yourself"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  read -e -p "Please enter the jump domain name:" reverseproxy
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on


		;;

	  23)
	  ldnmp_Proxy
		;;

	  24)
	  clear
	  webname="反向代理-域名"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  echo -e "Domain name format:${gl_huang}google.com${gl_bai}"
	  read -e -p "Please enter your anti-generation domain name:" fandai_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-domain.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s|fandaicom|$fandai_yuming|g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on

		;;


	  25)
	  clear
	  webname="Bitwarden"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
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


	  30)
	  clear
	  webname="静态站点"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  repeat_add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/html.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming


	  clear
	  echo -e "[${gl_huang}1/2${gl_bai}] Upload static source code"
	  echo "-------------"
	  echo "Currently, only zip-format source code packages are allowed. Please put the source code packages in /home/web/html/${yuming}In the directory"
	  read -e -p "You can also enter the download link to remotely download the source code package. Directly press Enter to skip remote download:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] The path where index.html is located"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "Please enter the path to index.html, similar to (/home/web/html/$yuming/index/）： " index_lujing

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
	  send_stats "LDNMP environment backup"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}Backing up$backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "The backup file has been created: /home/$backup_filename"
		read -e -p "Do you want to transfer backup data to a remote server? (Y/N):" choice
		case "$choice" in
		  [Yy])
			read -e -p "Please enter the remote server IP:" remote_ip
			if [ -z "$remote_ip" ]; then
			  echo "Error: Please enter the remote server IP."
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "The file has been transferred to the remote server home directory."
			else
			  echo "The file to be transferred was not found."
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "Invalid selection, please enter Y or N."
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "Timed remote backup"
	  read -e -p "Enter the remote server IP:" useip
	  read -e -p "Enter the remote server password:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. Weekly backup 2. Daily backup"
	  read -e -p "Please enter your selection:" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "Select the day of the week for your weekly backup (0-6, 0 represents Sunday):" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "Select the time for daily backup (hours, 0-23):" hour
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
	  send_stats "LDNMP environment restoration"
	  echo "Available site backups"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "Enter to restore the latest backup, enter the backup file name to restore the specified backup, enter 0 to exit:" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # If the user does not enter the file name, use the latest compressed package
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}Decompression is being done$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "No compression package was found."
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
		  send_stats "Update LDNMP environment"
		  echo "Update LDNMP environment"
		  echo "------------------------"
		  ldnmp_v
		  echo "Discover new version of components"
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
		  echo "1. Update nginx 2. Update mysql 3. Update php 4. Update redis"
		  echo "------------------------"
		  echo "5. Update the complete environment"
		  echo "------------------------"
		  echo "0. Return to the previous menu"
		  echo "------------------------"
		  read -e -p "Please enter your selection:" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "Please enter${ldnmp_pods}Version number (such as: 8.0 8.3 8.4 9.0) (Enter to get the latest version):" version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "renew$ldnmp_pods"
			  echo "renew${ldnmp_pods}Finish"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "Please enter${ldnmp_pods}Version number (such as: 7.4 8.0 8.1 8.2 8.3) (Enter to get the latest version):" version
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
			  docker exec php install-php-extensions mysqli pdo_mysql gd intl zip exif bcmath opcache redis imagick


			  docker exec php sh -c 'echo "upload_max_filesize=50M " > /usr/local/etc/php/conf.d/uploads.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "post_max_size=50M " > /usr/local/etc/php/conf.d/post.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "memory_limit=512M" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/max_input_vars.ini' > /dev/null 2>&1

			  fix_phpfpm_con $ldnmp_pods

			  docker restart $ldnmp_pods > /dev/null 2>&1
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "renew$ldnmp_pods"
			  echo "renew${ldnmp_pods}Finish"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  restart_redis
			  send_stats "renew$ldnmp_pods"
			  echo "renew${ldnmp_pods}Finish"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "Completely update the LDNMP environment"
					cd /home/web/
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
		send_stats "Uninstall LDNMP environment"
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
			echo "Invalid selection, please enter Y or N."
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "Invalid input!"
	esac
	break_end

  done

}



linux_panel() {

	while true; do
	  clear
	  # send_stats "App Market"
	  echo -e "Application Market"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Official version of Baota Panel${gl_kjlan}2.   ${gl_bai}aaPanel International Edition"
	  echo -e "${gl_kjlan}3.   ${gl_bai}1Panel new generation management panel${gl_kjlan}4.   ${gl_bai}NginxProxyManager Visual Panel"
	  echo -e "${gl_kjlan}5.   ${gl_bai}OpenList multi-store file list program${gl_kjlan}6.   ${gl_bai}Ubuntu Remote Desktop Web Edition"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Nezha Probe VPS Monitoring Panel${gl_kjlan}8.   ${gl_bai}QB Offline BT Magnetic Download Panel"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Poste.io mail server program${gl_kjlan}10.  ${gl_bai}RocketChat multiplayer online chat system"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Zendao project management software${gl_kjlan}12.  ${gl_bai}Qinglong Panel Timed Task Management Platform"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Cloudreve network disk${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}Simple picture bed picture management program"
	  echo -e "${gl_kjlan}15.  ${gl_bai}emby multimedia management system${gl_kjlan}16.  ${gl_bai}Speedtest speed test panel"
	  echo -e "${gl_kjlan}17.  ${gl_bai}AdGuardHome Adware${gl_kjlan}18.  ${gl_bai}onlyoffice online office OFFICE"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Thunder Pool WAF firewall panel${gl_kjlan}20.  ${gl_bai}portainer container management panel"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}VScode web version${gl_kjlan}22.  ${gl_bai}UptimeKuma monitoring tool"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Memos web page memo${gl_kjlan}24.  ${gl_bai}Webtop Remote Desktop Web Edition${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${gl_bai}Nextcloud network disk${gl_kjlan}26.  ${gl_bai}QD-Today timing task management framework"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Dockge Container Stack Management Panel${gl_kjlan}28.  ${gl_bai}LibreSpeed Speed Test Tool"
	  echo -e "${gl_kjlan}29.  ${gl_bai}searxng aggregation search site${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}PhotoPrism Private Album System"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}StirlingPDF tool collection${gl_kjlan}32.  ${gl_bai}drawio free online charting software${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Sun-Panel Navigation Panel${gl_kjlan}34.  ${gl_bai}Pingvin-Share file sharing platform"
	  echo -e "${gl_kjlan}35.  ${gl_bai}Minimalist circle of friends${gl_kjlan}36.  ${gl_bai}LobeChatAI Chat Aggregation Website"
	  echo -e "${gl_kjlan}37.  ${gl_bai}MyIP Toolbox${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}Xiaoya alist family bucket"
	  echo -e "${gl_kjlan}39.  ${gl_bai}Bililive live broadcast recording tool${gl_kjlan}40.  ${gl_bai}webssh web version SSH connection tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}Mouse Management Panel${gl_kjlan}42.  ${gl_bai}Nexte remote connection tool"
	  echo -e "${gl_kjlan}43.  ${gl_bai}RustDesk Remote Desk (Server)${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}RustDesk Remote Desk (Relay)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${gl_bai}Docker acceleration station${gl_kjlan}46.  ${gl_bai}GitHub Acceleration Station${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${gl_bai}Prometheus Monitoring${gl_kjlan}48.  ${gl_bai}Prometheus (host monitoring)"
	  echo -e "${gl_kjlan}49.  ${gl_bai}Prometheus (Container Monitoring)${gl_kjlan}50.  ${gl_bai}Replenishment monitoring tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${gl_bai}PVE Chicken Panel${gl_kjlan}52.  ${gl_bai}DPanel Container Management Panel"
	  echo -e "${gl_kjlan}53.  ${gl_bai}llama3 chat AI model${gl_kjlan}54.  ${gl_bai}AMH Host Website Building Management Panel"
	  echo -e "${gl_kjlan}55.  ${gl_bai}FRP intranet penetration (server side)${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${gl_bai}FRP intranet penetration (client)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${gl_bai}Deepseek chat AI big model${gl_kjlan}58.  ${gl_bai}Dify big model knowledge base${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${gl_bai}NewAPI big model asset management${gl_kjlan}60.  ${gl_bai}JumpServer open source bastion machine"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${gl_bai}Online translation server${gl_kjlan}62.  ${gl_bai}RAGFlow big model knowledge base"
	  echo -e "${gl_kjlan}63.  ${gl_bai}OpenWebUI self-hosted AI platform${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}it-tools toolbox"
	  echo -e "${gl_kjlan}65.  ${gl_bai}n8n Automation Workflow Platform${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}yt-dlp video download tool"
	  echo -e "${gl_kjlan}67.  ${gl_bai}ddns-go Dynamic DNS Management Tool${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${gl_bai}AllinSSL Certificate Management Platform"
	  echo -e "${gl_kjlan}69.  ${gl_bai}SFTPGo file transfer tool${gl_kjlan}70.  ${gl_bai}AstrBot Chat Robot Framework"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}71.  ${gl_bai}Navidrome Private Music Server${gl_kjlan}72.  ${gl_bai}bitwarden Password Manager${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${gl_bai}LibreTV Private Film and Television${gl_kjlan}74.  ${gl_bai}MoonTV Private Movie"
	  echo -e "${gl_kjlan}75.  ${gl_bai}Melody Music Elf${gl_kjlan}76.  ${gl_bai}Online DOS old games"
	  echo -e "${gl_kjlan}77.  ${gl_bai}Thunder offline download tool${gl_kjlan}78.  ${gl_bai}PandaWiki Intelligent Document Management System"
	  echo -e "${gl_kjlan}79.  ${gl_bai}Beszel server monitoring"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in
		  1)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="宝塔面板"
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
		  2)

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
		  3)

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
		  4)

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

			local docker_describe="一个Nginx反向代理工具面板，不支持添加域名访问。"
			local docker_url="官网介绍: https://nginxproxymanager.com/"
			local docker_use="echo \"初始用户名: admin@example.com\""
			local docker_passwd="echo \"初始密码: changeme\""
			local app_size="1"

			docker_app

			  ;;

		  5)

			local docker_name="openlist"
			local docker_img="openlistteam/openlist:latest-aria2"
			local docker_port=5244

			docker_rum() {

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


			local docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
			local docker_url="官网介绍: https://github.com/OpenListTeam/OpenList"
			local docker_use="docker exec -it openlist ./openlist admin random"
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;

		  6)

			local docker_name="webtop-ubuntu"
			local docker_img="lscr.io/linuxserver/webtop:ubuntu-kde"
			local docker_port=3006

			docker_rum() {


				docker run -d \
				  --name=webtop-ubuntu \
				  --security-opt seccomp=unconfined \
				  -e PUID=1000 \
				  -e PGID=1000 \
				  -e TZ=Etc/UTC \
				  -e SUBFOLDER=/ \
				  -e TITLE=Webtop \
				  -e CUSTOM_USER=ubuntu-abc \
				  -e PASSWORD=ubuntuABC123 \
				  -p ${docker_port}:3000 \
				  -v /home/docker/webtop/data:/config \
				  -v /var/run/docker.sock:/var/run/docker.sock \
				  --shm-size="1gb" \
				  --restart unless-stopped \
				  lscr.io/linuxserver/webtop:ubuntu-kde


			}


			local docker_describe="webtop基于Ubuntu的容器。若IP无法访问，请添加域名访问。"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use="echo \"用户名: ubuntu-abc\""
			local docker_passwd="echo \"密码: ubuntuABC123\""
			local app_size="2"
			docker_app


			  ;;
		  7)
			clear
			send_stats "Build Nezha"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "Nezha Monitoring$check_docker $update_status"
				echo "Open source, lightweight and easy-to-use server monitoring and operation and maintenance tools"
				echo "Official website construction document: https://nezha.wiki/guide/dashboard.html"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1. Use"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Enter your choice:" choice

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

		  8)

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
				  --restart unless-stopped \
				  lscr.io/linuxserver/qbittorrent:latest

			}

			local docker_describe="qbittorrent离线BT磁力下载服务"
			local docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
			local docker_use="sleep 3"
			local docker_passwd="docker logs qbittorrent"
			local app_size="1"
			docker_app

			  ;;

		  9)
			send_stats "Build a post office"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "Post Office Services$check_docker $update_status"
				echo "poste.io is an open source mail server solution."
				echo "Video introduction: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

				echo ""
				echo "Port detection"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
				  echo -e "${gl_lv}port$portCurrently available${gl_bai}"
				else
				  echo -e "${gl_hong}port$portNot currently available${gl_bai}"
				fi
				echo ""

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "Access address:"
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. Install 2. Update 3. Uninstall"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Enter your choice:" choice

				case $choice in
					1)
						check_disk_space 2
						read -e -p "Please set the email domain name, for example, mail.yuming.com:" yuming
						mkdir -p /home/docker
						echo "$yuming" > /home/docker/mail.txt
						echo "------------------------"
						ip_address
						echo "Parse these DNS records first"
						echo "A           mail            $ipv4_address"
						echo "CNAME       imap            $yuming"
						echo "CNAME       pop             $yuming"
						echo "CNAME       smtp            $yuming"
						echo "MX          @               $yuming"
						echo "TXT         @               v=spf1 mx ~all"
						echo "TXT         ?               ?"
						echo ""
						echo "------------------------"
						echo "Press any key to continue..."
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
						echo "poste.io has been installed"
						echo "------------------------"
						echo "You can access poste.io using the following address:"
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
						echo "poste.io has been installed"
						echo "------------------------"
						echo "You can access poste.io using the following address:"
						echo "https://$yuming"
						echo ""
						;;
					3)
						docker rm -f mailserver
						docker rmi -f analogic/poste.io
						rm /home/docker/mail.txt
						rm -rf /home/docker/mail
						echo "The app has been uninstalled"
						;;

					*)
						break
						;;

				esac
				break_end
			done

			  ;;

		  10)

			local app_name="Rocket.Chat聊天系统"
			local app_text="Rocket.Chat 是一个开源的团队通讯平台，支持实时聊天、音视频通话、文件共享等多种功能，"
			local app_url="官方介绍: https://www.rocket.chat/"
			local docker_name="rocketchat"
			local docker_port="3897"
			local app_size="2"

			docker_app_install() {
				docker run --name db -d --restart=always \
					-v /home/docker/mongo/dump:/dump \
					mongo:latest --replSet rs5 --oplogSize 256
				sleep 1
				docker exec -it db mongosh --eval "printjson(rs.initiate())"
				sleep 5
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat

				clear
				ip_address
				echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "rocket.chat has been installed"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "The app has been uninstalled"
			}

			docker_app_plus
			  ;;



		  11)
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

			local docker_describe="禅道是通用的项目管理软件"
			local docker_url="官网介绍: https://www.zentao.net/"
			local docker_use="echo \"初始用户名: admin\""
			local docker_passwd="echo \"初始密码: 123456\""
			local app_size="2"
			docker_app

			  ;;

		  12)
			local docker_name="qinglong"
			local docker_img="whyour/qinglong:latest"
			local docker_port=5700

			docker_rum() {


				docker run -d \
				  -v /home/docker/qinglong/data:/ql/data \
				  -p ${docker_port}:5700 \
				  --name qinglong \
				  --hostname qinglong \
				  --restart unless-stopped \
				  whyour/qinglong:latest


			}

			local docker_describe="青龙面板是一个定时任务管理平台"
			local docker_url="官网介绍: ${gh_proxy}github.com/whyour/qinglong"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;
		  13)

			local app_name="cloudreve网盘"
			local app_text="cloudreve是一个支持多家云存储的网盘系统"
			local app_url="视频介绍: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
				echo "Installed"
				check_docker_app_ip
			}


			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}


			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "The app has been uninstalled"
			}

			docker_app_plus
			  ;;

		  14)
			local docker_name="easyimage"
			local docker_img="ddsderek/easyimage:latest"
			local docker_port=85
			docker_rum() {

				docker run -d \
				  --name easyimage \
				  -p ${docker_port}:80 \
				  -e TZ=Asia/Shanghai \
				  -e PUID=1000 \
				  -e PGID=1000 \
				  -v /home/docker/easyimage/config:/app/web/config \
				  -v /home/docker/easyimage/i:/app/web/i \
				  --restart unless-stopped \
				  ddsderek/easyimage:latest

			}

			local docker_describe="简单图床是一个简单的图床程序"
			local docker_url="官网介绍: ${gh_proxy}github.com/icret/EasyImages2.0"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  15)
			local docker_name="emby"
			local docker_img="linuxserver/emby:latest"
			local docker_port=8096

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


			local docker_describe="emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
			local docker_url="官网介绍: https://emby.media/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  16)
			local docker_name="looking-glass"
			local docker_img="wikihostinc/looking-glass-server"
			local docker_port=89


			docker_rum() {

				docker run -d --name looking-glass --restart always -p ${docker_port}:80 wikihostinc/looking-glass-server

			}

			local docker_describe="Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
			local docker_url="官网介绍: ${gh_proxy}github.com/wikihost-opensource/als"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;
		  17)

			local docker_name="adguardhome"
			local docker_img="adguard/adguardhome"
			local docker_port=3000

			docker_rum() {

				docker run -d \
					--name adguardhome \
					-v /home/docker/adguardhome/work:/opt/adguardhome/work \
					-v /home/docker/adguardhome/conf:/opt/adguardhome/conf \
					-p 53:53/tcp \
					-p 53:53/udp \
					-p ${docker_port}:3000/tcp \
					--restart always \
					adguard/adguardhome


			}


			local docker_describe="AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
			local docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;


		  18)

			local docker_name="onlyoffice"
			local docker_img="onlyoffice/documentserver"
			local docker_port=8082

			docker_rum() {

				docker run -d -p ${docker_port}:80 \
					--restart=always \
					--name onlyoffice \
					-v /home/docker/onlyoffice/DocumentServer/logs:/var/log/onlyoffice  \
					-v /home/docker/onlyoffice/DocumentServer/data:/var/www/onlyoffice/Data  \
					 onlyoffice/documentserver


			}

			local docker_describe="onlyoffice是一款开源的在线office工具，太强大了！"
			local docker_url="官网介绍: https://www.onlyoffice.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app

			  ;;

		  19)
			send_stats "Build a Thunder Pool"

			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "Thunder Pool Service$check_docker"
				echo "Lei Chi is a WAF site firewall program panel developed by Changting Technology, which can reverse the agency site for automated defense."
				echo "Video introduction: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. Install 2. Update 3. Reset Password 4. Uninstall"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Enter your choice:" choice

				case $choice in
					1)
						install_docker
						check_disk_space 5
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
						clear
						echo "The Thunder Pool WAF panel has been installed"
						check_docker_app_ip
						docker exec safeline-mgt resetadmin

						;;

					2)
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
						docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
						echo ""
						clear
						echo "Thunder Pool WAF panel has been updated"
						check_docker_app_ip
						;;
					3)
						docker exec safeline-mgt resetadmin
						;;
					4)
						cd /data/safeline
						docker compose down --rmi all
						echo "If you are the default installation directory, the project has now been uninstalled. If you are customizing the installation directory, you need to go to the installation directory to execute it yourself:"
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

			docker_rum() {

				docker run -d \
					--name portainer \
					-p ${docker_port}:9000 \
					-v /var/run/docker.sock:/var/run/docker.sock \
					-v /home/docker/portainer:/data \
					--restart always \
					portainer/portainer

			}


			local docker_describe="portainer是一个轻量级的docker容器管理面板"
			local docker_url="官网介绍: https://www.portainer.io/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;

		  21)
			local docker_name="vscode-web"
			local docker_img="codercom/code-server"
			local docker_port=8180


			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/vscode-web:/home/coder/.local/share/code-server --name vscode-web --restart always codercom/code-server

			}


			local docker_describe="VScode是一款强大的在线代码编写工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/coder/code-server"
			local docker_use="sleep 3"
			local docker_passwd="docker exec vscode-web cat /home/coder/.config/code-server/config.yaml"
			local app_size="1"
			docker_app
			  ;;
		  22)
			local docker_name="uptime-kuma"
			local docker_img="louislam/uptime-kuma:latest"
			local docker_port=3003


			docker_rum() {

				docker run -d \
					--name=uptime-kuma \
					-p ${docker_port}:3001 \
					-v /home/docker/uptime-kuma/uptime-kuma-data:/app/data \
					--restart=always \
					louislam/uptime-kuma:latest

			}


			local docker_describe="Uptime Kuma 易于使用的自托管监控工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/louislam/uptime-kuma"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  23)
			local docker_name="memos"
			local docker_img="ghcr.io/usememos/memos:latest"
			local docker_port=5230

			docker_rum() {

				docker run -d --name memos -p ${docker_port}:5230 -v /home/docker/memos:/var/opt/memos --restart always ghcr.io/usememos/memos:latest

			}

			local docker_describe="Memos是一款轻量级、自托管的备忘录中心"
			local docker_url="官网介绍: ${gh_proxy}github.com/usememos/memos"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  24)
			local docker_name="webtop"
			local docker_img="lscr.io/linuxserver/webtop:latest"
			local docker_port=3083

			docker_rum() {


				docker run -d \
				  --name=webtop \
				  --security-opt seccomp=unconfined \
				  -e PUID=1000 \
				  -e PGID=1000 \
				  -e TZ=Etc/UTC \
				  -e SUBFOLDER=/ \
				  -e TITLE=Webtop \
				  -e CUSTOM_USER=webtop-abc \
				  -e PASSWORD=webtopABC123 \
				  -e LC_ALL=zh_CN.UTF-8 \
				  -e DOCKER_MODS=linuxserver/mods:universal-package-install \
				  -e INSTALL_PACKAGES=font-noto-cjk \
				  -p ${docker_port}:3000 \
				  -v /home/docker/webtop/data:/config \
				  -v /var/run/docker.sock:/var/run/docker.sock \
				  --shm-size="1gb" \
				  --restart unless-stopped \
				  lscr.io/linuxserver/webtop:latest


			}


			local docker_describe="webtop基于Alpine的中文版容器。若IP无法访问，请添加域名访问。"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use="echo \"用户名: webtop-abc\""
			local docker_passwd="echo \"密码: webtopABC123\""
			local app_size="2"
			docker_app
			  ;;

		  25)
			local docker_name="nextcloud"
			local docker_img="nextcloud:latest"
			local docker_port=8989
			local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

			docker_rum() {

				docker run -d --name nextcloud --restart=always -p ${docker_port}:80 -v /home/docker/nextcloud:/var/www/html -e NEXTCLOUD_ADMIN_USER=nextcloud -e NEXTCLOUD_ADMIN_PASSWORD=$rootpasswd nextcloud

			}

			local docker_describe="Nextcloud拥有超过 400,000 个部署，是您可以下载的最受欢迎的本地内容协作平台"
			local docker_url="官网介绍: https://nextcloud.com/"
			local docker_use="echo \"账号: nextcloud  密码: $rootpasswd\""
			local docker_passwd=""
			local app_size="3"
			docker_app
			  ;;

		  26)
			local docker_name="qd"
			local docker_img="qdtoday/qd:latest"
			local docker_port=8923

			docker_rum() {

				docker run -d --name qd -p ${docker_port}:80 -v /home/docker/qd/config:/usr/src/app/config qdtoday/qd

			}

			local docker_describe="QD-Today是一个HTTP请求定时任务自动执行框架"
			local docker_url="官网介绍: https://qd-today.github.io/qd/zh_CN/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;
		  27)
			local docker_name="dockge"
			local docker_img="louislam/dockge:latest"
			local docker_port=5003

			docker_rum() {

				docker run -d --name dockge --restart unless-stopped -p ${docker_port}:5001 -v /var/run/docker.sock:/var/run/docker.sock -v /home/docker/dockge/data:/app/data -v  /home/docker/dockge/stacks:/home/docker/dockge/stacks -e DOCKGE_STACKS_DIR=/home/docker/dockge/stacks louislam/dockge

			}

			local docker_describe="dockge是一个可视化的docker-compose容器管理面板"
			local docker_url="官网介绍: ${gh_proxy}github.com/louislam/dockge"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  28)
			local docker_name="speedtest"
			local docker_img="ghcr.io/librespeed/speedtest"
			local docker_port=8028

			docker_rum() {

				docker run -d -p ${docker_port}:8080 --name speedtest --restart always ghcr.io/librespeed/speedtest

			}

			local docker_describe="librespeed是用Javascript实现的轻量级速度测试工具，即开即用"
			local docker_url="官网介绍: ${gh_proxy}github.com/librespeed/speedtest"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  29)
			local docker_name="searxng"
			local docker_img="searxng/searxng"
			local docker_port=8029

			docker_rum() {

				docker run -d \
				  --name searxng \
				  --restart unless-stopped \
				  -p ${docker_port}:8080 \
				  -v "/home/docker/searxng:/etc/searxng" \
				  searxng/searxng

			}

			local docker_describe="searxng是一个私有且隐私的搜索引擎站点"
			local docker_url="官网介绍: https://hub.docker.com/r/alandoyle/searxng"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  30)
			local docker_name="photoprism"
			local docker_img="photoprism/photoprism:latest"
			local docker_port=2342
			local rootpasswd=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)

			docker_rum() {

				docker run -d \
					--name photoprism \
					--restart always \
					--security-opt seccomp=unconfined \
					--security-opt apparmor=unconfined \
					-p ${docker_port}:2342 \
					-e PHOTOPRISM_UPLOAD_NSFW="true" \
					-e PHOTOPRISM_ADMIN_PASSWORD="$rootpasswd" \
					-v /home/docker/photoprism/storage:/photoprism/storage \
					-v /home/docker/photoprism/Pictures:/photoprism/originals \
					photoprism/photoprism

			}


			local docker_describe="photoprism非常强大的私有相册系统"
			local docker_url="官网介绍: https://www.photoprism.app/"
			local docker_use="echo \"账号: admin  密码: $rootpasswd\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  31)
			local docker_name="s-pdf"
			local docker_img="frooodle/s-pdf:latest"
			local docker_port=8020

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

			local docker_describe="这是一个强大的本地托管基于 Web 的 PDF 操作工具，使用 docker，允许您对 PDF 文件执行各种操作，例如拆分合并、转换、重新组织、添加图像、旋转、压缩等。"
			local docker_url="官网介绍: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  32)
			local docker_name="drawio"
			local docker_img="jgraph/drawio"
			local docker_port=7080

			docker_rum() {

				docker run -d --restart=always --name drawio -p ${docker_port}:8080 -v /home/docker/drawio:/var/lib/drawio jgraph/drawio

			}


			local docker_describe="这是一个强大图表绘制软件。思维导图，拓扑图，流程图，都能画"
			local docker_url="官网介绍: https://www.drawio.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  33)
			local docker_name="sun-panel"
			local docker_img="hslr/sun-panel"
			local docker_port=3009

			docker_rum() {

				docker run -d --restart=always -p ${docker_port}:3002 \
					-v /home/docker/sun-panel/conf:/app/conf \
					-v /home/docker/sun-panel/uploads:/app/uploads \
					-v /home/docker/sun-panel/database:/app/database \
					--name sun-panel \
					hslr/sun-panel

			}

			local docker_describe="Sun-Panel服务器、NAS导航面板、Homepage、浏览器首页"
			local docker_url="官网介绍: https://doc.sun-panel.top/zh_cn/"
			local docker_use="echo \"账号: admin@sun.cc  密码: 12345678\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  34)
			local docker_name="pingvin-share"
			local docker_img="stonith404/pingvin-share"
			local docker_port=3060

			docker_rum() {

				docker run -d \
					--name pingvin-share \
					--restart always \
					-p ${docker_port}:3000 \
					-v /home/docker/pingvin-share/data:/opt/app/backend/data \
					stonith404/pingvin-share
			}

			local docker_describe="Pingvin Share 是一个可自建的文件分享平台，是 WeTransfer 的一个替代品"
			local docker_url="官网介绍: ${gh_proxy}github.com/stonith404/pingvin-share"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  35)
			local docker_name="moments"
			local docker_img="kingwrcy/moments:latest"
			local docker_port=8035

			docker_rum() {

				docker run -d --restart unless-stopped \
					-p ${docker_port}:3000 \
					-v /home/docker/moments/data:/app/data \
					-v /etc/localtime:/etc/localtime:ro \
					-v /etc/timezone:/etc/timezone:ro \
					--name moments \
					kingwrcy/moments:latest
			}


			local docker_describe="极简朋友圈，高仿微信朋友圈，记录你的美好生活"
			local docker_url="Official website introduction:${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
			local docker_use="echo \"账号: admin  密码: a123456\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;



		  36)
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
			local docker_url="官网介绍: ${gh_proxy}github.com/lobehub/lobe-chat"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			  ;;

		  37)
			local docker_name="myip"
			local docker_img="jason5ng32/myip:latest"
			local docker_port=8037

			docker_rum() {

				docker run -d -p ${docker_port}:18966 --name myip jason5ng32/myip:latest

			}


			local docker_describe="是一个多功能IP工具箱，可以查看自己IP信息及连通性，用网页面板呈现"
			local docker_url="官网介绍: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  38)
			send_stats "Xiaoya Family Bucket"
			clear
			install_docker
			check_disk_space 1
			bash -c "$(curl --insecure -fsSL https://ddsrem.com/xiaoya_install.sh)"
			  ;;

		  39)

			if [ ! -d /home/docker/bililive-go/ ]; then
				mkdir -p /home/docker/bililive-go/ > /dev/null 2>&1
				wget -O /home/docker/bililive-go/config.yml ${gh_proxy}raw.githubusercontent.com/hr3lxphr6j/bililive-go/master/config.yml > /dev/null 2>&1
			fi

			local docker_name="bililive-go"
			local docker_img="chigusa/bililive-go"
			local docker_port=8039

			docker_rum() {

				docker run --restart=always --name bililive-go -v /home/docker/bililive-go/config.yml:/etc/bililive-go/config.yml -v /home/docker/bililive-go/Videos:/srv/bililive -p ${docker_port}:8080 -d chigusa/bililive-go

			}

			local docker_describe="Bililive-go是一个支持多种直播平台的直播录制工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  40)
			local docker_name="webssh"
			local docker_img="jrohy/webssh"
			local docker_port=8040
			docker_rum() {
				docker run -d -p ${docker_port}:5032 --restart always --name webssh -e TZ=Asia/Shanghai jrohy/webssh
			}

			local docker_describe="简易在线ssh连接工具和sftp工具"
			local docker_url="官网介绍: ${gh_proxy}github.com/Jrohy/webssh"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  41)

			local lujing="[ -d "/www/server/panel" ]"
			local panelname="耗子面板"
			local panelurl="官方地址: ${gh_proxy}github.com/TheTNB/panel"

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


		  42)
			local docker_name="nexterm"
			local docker_img="germannewsmaker/nexterm:latest"
			local docker_port=8042

			docker_rum() {

				docker run -d \
				  --name nexterm \
				  -p ${docker_port}:6989 \
				  -v /home/docker/nexterm:/app/data \
				  --restart unless-stopped \
				  germannewsmaker/nexterm:latest

			}

			local docker_describe="nexterm是一款强大的在线SSH/VNC/RDP连接工具。"
			local docker_url="官网介绍: ${gh_proxy}github.com/gnmyt/Nexterm"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  43)
			local docker_name="hbbs"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=0000

			docker_rum() {

				docker run --name hbbs -v /home/docker/hbbs/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbs

			}


			local docker_describe="rustdesk开源的远程桌面(服务端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="docker logs hbbs"
			local docker_passwd="echo \"把你的IP和key记录下，会在远程桌面客户端中用到。去44选项装中继端吧！\""
			local app_size="1"
			docker_app
			  ;;

		  44)
			local docker_name="hbbr"
			local docker_img="rustdesk/rustdesk-server"
			local docker_port=0000

			docker_rum() {

				docker run --name hbbr -v /home/docker/hbbr/data:/root -td --net=host --restart unless-stopped rustdesk/rustdesk-server hbbr

			}

			local docker_describe="rustdesk开源的远程桌面(中继端)，类似自己的向日葵私服。"
			local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
			local docker_use="echo \"前往官网下载远程桌面的客户端: https://rustdesk.com/zh-cn/\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  45)
			local docker_name="registry"
			local docker_img="registry:2"
			local docker_port=8045

			docker_rum() {

				docker run -d \
					-p ${docker_port}:5000 \
					--name registry \
					-v /home/docker/registry:/var/lib/registry \
					-e REGISTRY_PROXY_REMOTEURL=https://registry-1.docker.io \
					--restart always \
					registry:2

			}

			local docker_describe="Docker Registry 是一个用于存储和分发 Docker 镜像的服务。"
			local docker_url="官网介绍: https://hub.docker.com/_/registry"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app
			  ;;

		  46)
			local docker_name="ghproxy"
			local docker_img="wjqserver/ghproxy:latest"
			local docker_port=8046

			docker_rum() {

				docker run -d --name ghproxy --restart always -p ${docker_port}:8080 wjqserver/ghproxy:latest

			}

			local docker_describe="使用Go实现的GHProxy，用于加速部分地区Github仓库的拉取。"
			local docker_url="官网介绍: https://github.com/WJQSERVER-STUDIO/ghproxy"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  47)



			local app_name="普罗米修斯监控"
			local app_text="Prometheus+Grafana企业级监控系统"
			local app_url="官网介绍: https://prometheus.io"
			local docker_name="grafana"
			local docker_port="8047"
			local app_size="2"

			docker_app_install() {
				prometheus_install
				clear
				ip_address
				echo "Installed"
				check_docker_app_ip
				echo "The initial username and password are: admin"
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
				echo "The app has been uninstalled"
			}

			docker_app_plus
			  ;;

		  48)
			local docker_name="node-exporter"
			local docker_img="prom/node-exporter"
			local docker_port=8048

			docker_rum() {

				docker run -d \
  					--name=node-exporter \
  					-p ${docker_port}:9100 \
  					--restart unless-stopped \
  					prom/node-exporter


			}

			local docker_describe="这是一个普罗米修斯的主机数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/prometheus/node_exporter"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  49)
			local docker_name="cadvisor"
			local docker_img="gcr.io/cadvisor/cadvisor:latest"
			local docker_port=8049

			docker_rum() {

				docker run -d \
  					--name=cadvisor \
  					--restart unless-stopped \
  					-p ${docker_port}:8080 \
  					--volume=/:/rootfs:ro \
  					--volume=/var/run:/var/run:rw \
  					--volume=/sys:/sys:ro \
  					--volume=/var/lib/docker/:/var/lib/docker:ro \
  					gcr.io/cadvisor/cadvisor:latest \
  					-housekeeping_interval=10s \
  					-docker_only=true

			}

			local docker_describe="这是一个普罗米修斯的容器数据采集组件，请部署在被监控主机上。"
			local docker_url="官网介绍: https://github.com/google/cadvisor"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  50)
			local docker_name="changedetection"
			local docker_img="dgtlmoon/changedetection.io:latest"
			local docker_port=8050

			docker_rum() {

				docker run -d --restart always -p ${docker_port}:5000 \
					-v /home/docker/datastore:/datastore \
					--name changedetection dgtlmoon/changedetection.io:latest

			}

			local docker_describe="这是一款网站变化检测、补货监控和通知的小工具"
			local docker_url="官网介绍: https://github.com/dgtlmoon/changedetection.io"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  51)
			clear
			send_stats "PVE Chicken"
			check_disk_space 1
			curl -L ${gh_proxy}raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
			  ;;


		  52)
			local docker_name="dpanel"
			local docker_img="dpanel/dpanel:lite"
			local docker_port=8052

			docker_rum() {

				docker run -it -d --name dpanel --restart=always \
  					-p ${docker_port}:8080 -e APP_NAME=dpanel \
  					-v /var/run/docker.sock:/var/run/docker.sock \
  					-v /home/docker/dpanel:/dpanel \
  					dpanel/dpanel:lite

			}

			local docker_describe="Docker可视化面板系统，提供完善的docker管理功能。"
			local docker_url="官网介绍: https://github.com/donknap/dpanel"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  53)
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart always ghcr.io/open-webui/open-webui:ollama

			}

			local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的llama3大语言模型"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run llama3.2:1b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			  ;;

		  54)

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


		  55)
		  	frps_panel
			  ;;

		  56)
			frpc_panel
			  ;;

		  57)
			local docker_name="ollama"
			local docker_img="ghcr.io/open-webui/open-webui:ollama"
			local docker_port=8053

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart always ghcr.io/open-webui/open-webui:ollama

			}

			local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的DeepSeek R1大语言模型"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
			local docker_passwd=""
			local app_size="5"
			docker_app
			  ;;


		  58)
			local app_name="Dify知识库"
			local app_text="是一款开源的大语言模型(LLM) 应用开发平台。自托管训练数据用于AI生成"
			local app_url="官方网站: https://docs.dify.ai/zh-hans"
			local docker_name="docker-nginx-1"
			local docker_port="8058"
			local app_size="3"

			docker_app_install() {
				install git
				mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/langgenius/dify.git && cd dify/docker && cp .env.example .env
				# sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				sed -i "s/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=${docker_port}/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/" /home/docker/dify/docker/.env

				docker compose up -d
				clear
				echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				cd  /home/docker/dify/docker/ && docker compose down --rmi all
				cd  /home/docker/dify/
				git pull origin main
				sed -i 's/^EXPOSE_NGINX_PORT=.*/EXPOSE_NGINX_PORT=8058/; s/^EXPOSE_NGINX_SSL_PORT=.*/EXPOSE_NGINX_SSL_PORT=8858/' /home/docker/dify/docker/.env
				cd  /home/docker/dify/docker/ && docker compose up -d
			}

			docker_app_uninstall() {
				cd  /home/docker/dify/docker/ && docker compose down --rmi all
				rm -rf /home/docker/dify
				echo "The app has been uninstalled"
			}

			docker_app_plus

			  ;;

		  59)
			local app_name="New API"
			local app_text="新一代大模型网关与AI资产管理系统"
			local app_url="官方网站: https://github.com/Calcium-Ion/new-api"
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
				echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				cd  /home/docker/new-api/
				git pull origin main
				sed -i -e "s/- \"3000:3000\"/- \"${docker_port}:3000\"/g" \
					   -e 's/container_name: redis/container_name: redis-new-api/g' \
					   -e 's/container_name: mysql/container_name: mysql-new-api/g' \
					   docker-compose.yml

				docker compose up -d
				clear
				echo "Installed"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "The app has been uninstalled"
			}

			docker_app_plus

			  ;;


		  60)

			local app_name="JumpServer开源堡垒机"
			local app_text="是一个开源的特权访问管理 (PAM) 工具，该程序占用80端口不支持添加域名访问了"
			local app_url="官方介绍: https://github.com/jumpserver/jumpserver"
			local docker_name="jms_web"
			local docker_port="80"
			local app_size="2"

			docker_app_install() {
				curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
				clear
				echo "Installed"
				check_docker_app_ip
				echo "Initial username: admin"
				echo "Initial password: ChangeMe"
			}


			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "The app has been updated"
			}


			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "The app has been uninstalled"
			}

			docker_app_plus
			  ;;

		  61)
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

			local docker_describe="免费开源机器翻译 API，完全自托管，它的翻译引擎由开源Argos Translate库提供支持。"
			local docker_url="官网介绍: https://github.com/LibreTranslate/LibreTranslate"
			local docker_use=""
			local docker_passwd=""
			local app_size="5"
			docker_app
			  ;;



		  62)
			local app_name="RAGFlow知识库"
			local app_text="基于深度文档理解的开源 RAG（检索增强生成）引擎"
			local app_url="官方网站: https://github.com/infiniflow/ragflow"
			local docker_name="ragflow-server"
			local docker_port="8062"
			local app_size="8"

			docker_app_install() {
				install git
				mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
				clear
				echo "Installed"
				check_docker_app_ip
			}

			docker_app_update() {
				cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
				cd  /home/docker/ragflow/
				git pull origin main
				cd  /home/docker/ragflow/docker/
				sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
				docker compose up -d
			}

			docker_app_uninstall() {
				cd  /home/docker/ragflow/docker/ && docker compose down --rmi all
				rm -rf /home/docker/ragflow
				echo "The app has been uninstalled"
			}

			docker_app_plus

			  ;;


		  63)
			local docker_name="open-webui"
			local docker_img="ghcr.io/open-webui/open-webui:main"
			local docker_port=8063

			docker_rum() {

				docker run -d -p ${docker_port}:8080 -v /home/docker/open-webui:/app/backend/data --name open-webui --restart always ghcr.io/open-webui/open-webui:main

			}

			local docker_describe="OpenWebUI一款大语言模型网页框架，官方精简版本，支持各大模型API接入"
			local docker_url="官网介绍: https://github.com/open-webui/open-webui"
			local docker_use=""
			local docker_passwd=""
			local app_size="3"
			docker_app
			  ;;

		  64)
			local docker_name="it-tools"
			local docker_img="corentinth/it-tools:latest"
			local docker_port=8064

			docker_rum() {
				docker run -d --name it-tools --restart unless-stopped -p ${docker_port}:80 corentinth/it-tools:latest
			}

			local docker_describe="对开发人员和 IT 工作者来说非常有用的工具"
			local docker_url="官网介绍: https://github.com/CorentinTh/it-tools"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  65)
			local docker_name="n8n"
			local docker_img="docker.n8n.io/n8nio/n8n"
			local docker_port=8065

			docker_rum() {

				add_yuming
				mkdir -p /home/docker/n8n
				chmod -R 777 /home/docker/n8n

				docker run -d --name n8n \
				  --restart always \
				  -p ${docker_port}:5678 \
				  -v /home/docker/n8n:/home/node/.n8n \
				  -e N8N_HOST=${yuming} \
				  -e N8N_PORT=5678 \
				  -e N8N_PROTOCOL=https \
				  -e N8N_WEBHOOK_URL=https://${yuming}/ \
				  docker.n8n.io/n8nio/n8n

				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"

			}

			local docker_describe="是一款功能强大的自动化工作流平台"
			local docker_url="官网介绍: https://github.com/n8n-io/n8n"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  66)
			yt_menu_pro
			  ;;


		  67)
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

			local docker_describe="自动将你的公网 IP（IPv4/IPv6）实时更新到各大 DNS 服务商，实现动态域名解析。"
			local docker_url="官网介绍: https://github.com/jeessy2/ddns-go"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  68)
			local docker_name="allinssl"
			local docker_img="allinssl/allinssl:latest"
			local docker_port=8068

			docker_rum() {
				docker run -itd --name allinssl -p ${docker_port}:8888 -v /home/docker/allinssl/data:/www/allinssl/data -e ALLINSSL_USER=allinssl -e ALLINSSL_PWD=allinssldocker -e ALLINSSL_URL=allinssl allinssl/allinssl:latest
			}

			local docker_describe="开源免费的 SSL 证书自动化管理平台"
			local docker_url="官网介绍: https://allinssl.com"
			local docker_use="echo \"安全入口: /allinssl\""
			local docker_passwd="echo \"用户名: allinssl  密码: allinssldocker\""
			local app_size="1"
			docker_app
			  ;;


		  69)
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

			local docker_describe="开源免费随时随地SFTP FTP WebDAV 文件传输工具"
			local docker_url="官网介绍: https://sftpgo.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  70)
			local docker_name="astrbot"
			local docker_img="soulter/astrbot:latest"
			local docker_port=8070

			docker_rum() {

				mkdir -p /home/docker/astrbot/data

				sudo docker run -d \
				  -p ${docker_port}:6185 \
				  -p 6195:6195 \
				  -p 6196:6196 \
				  -p 6199:6199 \
				  -p 11451:11451 \
				  -v /home/docker/astrbot/data:/AstrBot/data \
				  --restart unless-stopped \
				  --name astrbot \
				  soulter/astrbot:latest

			}

			local docker_describe="开源AI聊天机器人框架，支持微信，QQ，TG接入AI大模型"
			local docker_url="官网介绍: https://astrbot.app/"
			local docker_use="echo \"用户名: astrbot  密码: astrbot\""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  71)
			local docker_name="navidrome"
			local docker_img="deluan/navidrome:latest"
			local docker_port=8071

			docker_rum() {

				docker run -d \
				  --name navidrome \
				  --restart=unless-stopped \
				  --user $(id -u):$(id -g) \
				  -v /home/docker/navidrome/music:/music \
				  -v /home/docker/navidrome/data:/data \
				  -p ${docker_port}:4533 \
				  -e ND_LOGLEVEL=info \
				  deluan/navidrome:latest

			}

			local docker_describe="是一个轻量、高性能的音乐流媒体服务器"
			local docker_url="官网介绍: https://www.navidrome.org/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;


		  72)

			local docker_name="bitwarden"
			local docker_img="vaultwarden/server"
			local docker_port=8072

			docker_rum() {

				docker run -d \
					--name bitwarden \
					--restart always \
					-p ${docker_port}:80 \
					-v /home/docker/bitwarden/data:/data \
					vaultwarden/server

			}

			local docker_describe="一个你可以控制数据的密码管理器"
			local docker_url="官网介绍: https://bitwarden.com/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app


			  ;;



		  73)

			local docker_name="libretv"
			local docker_img="bestzwei/libretv:latest"
			local docker_port=8073

			docker_rum() {

				read -e -p "Set the LibreTV login password:" app_passwd

				docker run -d \
				  --name libretv \
				  --restart unless-stopped \
				  -p ${docker_port}:8080 \
				  -e PASSWORD=${app_passwd} \
				  bestzwei/libretv:latest

			}

			local docker_describe="免费在线视频搜索与观看平台"
			local docker_url="官网介绍: https://github.com/LibreSpark/LibreTV"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;


		  74)

			local docker_name="moontv"
			local docker_img="ghcr.io/senshinya/moontv:latest"
			local docker_port=8074

			docker_rum() {

				read -e -p "Set the MoonTV login password:" app_passwd

					docker run -d \
					  --name moontv \
					  --restart unless-stopped \
					  -p ${docker_port}:3000 \
					  -e PASSWORD=${app_passwd} \
					  ghcr.io/senshinya/moontv:latest

			}

			local docker_describe="免费在线视频搜索与观看平台"
			local docker_url="官网介绍: https://github.com/senshinya/MoonTV"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;


		  75)

			local docker_name="melody"
			local docker_img="foamzou/melody:latest"
			local docker_port=8075

			docker_rum() {

				docker run -d \
				  --name melody \
				  --restart unless-stopped \
				  -p ${docker_port}:5566 \
				  -v /home/docker/melody/.profile:/app/backend/.profile \
				  foamzou/melody:latest


			}

			local docker_describe="你的音乐精灵，旨在帮助你更好地管理音乐。"
			local docker_url="官网介绍: https://github.com/foamzou/melody"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app


			  ;;


		  76)

			local docker_name="dosgame"
			local docker_img="oldiy/dosgame-web-docker:latest"
			local docker_port=8076

			docker_rum() {
				docker run -d \
  					--name dosgame \
  					--restart unless-stopped \
  					-p ${docker_port}:262 \
  					oldiy/dosgame-web-docker:latest

			}

			local docker_describe="是一个中文DOS游戏合集网站"
			local docker_url="官网介绍: https://github.com/rwv/chinese-dos-games"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app


			  ;;

		  77)

			local docker_name="xunlei"
			local docker_img="cnk3x/xunlei"
			local docker_port=8077

			docker_rum() {

				read -e -p "set up${docker_name}Login username:" app_use
				read -e -p "set up${docker_name}Login password:" app_passwd

				docker run -d \
				  --name xunlei \
				  --restart unless-stopped \
				  --privileged \
				  -e XL_DASHBOARD_USERNAME=${app_use} \
				  -e XL_DASHBOARD_PASSWORD=${app_passwd} \
				  -v /home/docker/xunlei/data:/xunlei/data \
				  -v /home/docker/xunlei/downloads:/xunlei/downloads \
				  -p ${docker_port}:2345 \
				  cnk3x/xunlei

			}

			local docker_describe="迅雷你的离线高速BT磁力下载工具"
			local docker_url="官网介绍: https://github.com/cnk3x/xunlei"
			local docker_use="echo \"手机登录迅雷，再输入邀请码，邀请码: 迅雷牛通\""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;



		  78)

			local app_name="PandaWiki"
			local app_text="PandaWiki是一款AI大模型驱动的开源智能文档管理系统，强烈建议不要自定义端口部署。"
			local app_url="官方介绍: https://github.com/chaitin/PandaWiki"
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



		  79)

			local docker_name="beszel"
			local docker_img="henrygd/beszel"
			local docker_port=8079

			docker_rum() {

				mkdir -p /home/docker/beszel && \
				docker run -d \
				  --name beszel \
				  --restart=unless-stopped \
				  -v /home/docker/beszel:/beszel_data \
				  -p ${docker_port}:8090 \
				  henrygd/beszel

			}

			local docker_describe="Beszel轻量易用的服务器监控"
			local docker_url="官网介绍: https://beszel.dev/zh/"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app

			  ;;


		  0)
			  kejilion
			  ;;
		  *)
			  echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done
}


linux_work() {

	while true; do
	  clear
	  send_stats "Backend workspace"
	  echo -e "Backend workspace"
	  echo -e "The system will provide you with a workspace that can be run on the backend, which you can use to perform long-term tasks."
	  echo -e "Even if you disconnect SSH, tasks in the workspace will not be interrupted, and tasks in the background will be resident."
	  echo -e "${gl_huang}hint:${gl_bai}After entering the workspace, use Ctrl+b and press d alone to exit the workspace!"
	  echo -e "${gl_kjlan}------------------------"
	  echo "List of currently existing workspaces"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Workspace No. 1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Workspace No. 2"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Workspace No. 3"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Workspace No. 4"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Workspace No. 5"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Workspace No. 6"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Workspace No. 7"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Workspace No. 8"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Workspace No. 9"
	  echo -e "${gl_kjlan}10.  ${gl_bai}Workspace No. 10"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH resident mode${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}Create/enter the workspace"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Inject commands into the background workspace"
	  echo -e "${gl_kjlan}24.  ${gl_bai}Delete the specified workspace"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "Start the workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "Start the workspace$SESSION_NAME"
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
			  send_stats "SSH resident mode"
			  echo -e "SSH resident mode${tmux_sshd_status}"
			  echo "After SSH connection is enabled, it will directly enter the resident mode and return to the previous working state."
			  echo "------------------------"
			  echo "1. Turn on 2. Turn off"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your selection:" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "Start the workspace$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# Automatically enter the tmux session\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
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
			  read -e -p "Please enter the name of the workspace you created or entered, such as 1001 kj001 work1:" SESSION_NAME
			  tmux_run
			  send_stats "Custom workspace"
			  ;;


		  23)
			  read -e -p "Please enter the command you want to execute in the background, such as: curl -fsSL https://get.docker.com | sh:" tmuxd
			  tmux_run_d
			  send_stats "Inject commands into the background workspace"
			  ;;

		  24)
			  read -e -p "Please enter the name of the workspace you want to delete:" gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "Delete the workspace"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # send_stats "System Tools"
	  echo -e "System Tools"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Set script startup shortcut keys${gl_kjlan}2.   ${gl_bai}Modify the login password"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ROOT password login mode${gl_kjlan}4.   ${gl_bai}Install the specified version of Python"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Open all ports${gl_kjlan}6.   ${gl_bai}Modify the SSH connection port"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Optimize DNS address${gl_kjlan}8.   ${gl_bai}One-click reinstallation system${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Disable ROOT account to create a new account${gl_kjlan}10.  ${gl_bai}Switch priority ipv4/ipv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Check port occupation status${gl_kjlan}12.  ${gl_bai}Modify virtual memory size"
	  echo -e "${gl_kjlan}13.  ${gl_bai}User Management${gl_kjlan}14.  ${gl_bai}User/Password Generator"
	  echo -e "${gl_kjlan}15.  ${gl_bai}System time zone adjustment${gl_kjlan}16.  ${gl_bai}Set up BBR3 acceleration"
	  echo -e "${gl_kjlan}17.  ${gl_bai}Firewall Advanced Manager${gl_kjlan}18.  ${gl_bai}Modify the host name"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Switch system update source${gl_kjlan}20.  ${gl_bai}Timing task management"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}Native host parsing${gl_kjlan}22.  ${gl_bai}SSH Defense Program"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Automatic shutdown of current limit${gl_kjlan}24.  ${gl_bai}ROOT private key login mode"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot system monitoring and early warning${gl_kjlan}26.  ${gl_bai}Fix OpenSSH high-risk vulnerabilities (Xiuyuan)"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat Linux kernel upgrade${gl_kjlan}28.  ${gl_bai}Optimization of kernel parameters in Linux system${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}Virus scanning tool${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}File Manager"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Switch system language${gl_kjlan}32.  ${gl_bai}Command line beautification tool${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Set up a system recycling bin${gl_kjlan}34.  ${gl_bai}System backup and recovery"
	  echo -e "${gl_kjlan}35.  ${gl_bai}ssh remote connection tool${gl_kjlan}36.  ${gl_bai}Hard disk partition management tool"
	  echo -e "${gl_kjlan}37.  ${gl_bai}Command line history${gl_kjlan}38.  ${gl_bai}rsync remote synchronization tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}Message board${gl_kjlan}66.  ${gl_bai}One-stop system optimization${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}Restart the server${gl_kjlan}100. ${gl_bai}Privacy and Security"
	  echo -e "${gl_kjlan}101. ${gl_bai}Advanced usage of k command${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}Uninstall tech lion script"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "Please enter your shortcut key (enter 0 to exit):" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "Shortcut keys are set"
				  send_stats "Script shortcut keys have been set"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "Set your login password"
			  echo "Set your login password"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "root password mode"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "py version management"
			echo "Python version management"
			echo "Video introduction: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "This feature seamlessly installs any version officially supported by python!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "Current python version number:${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "Recommended version: 3.12 3.11 3.10 3.9 3.8 2.7"
			echo "Query more versions: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "Enter the python version number you want to install (enter 0 to exit):" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "Script PY Management"
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
					echo "Unknown package manager!"
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
			echo -e "Current python version number:${gl_huang}$VERSION${gl_bai}"
			send_stats "Switch script PY version"

			  ;;

		  5)
			  root_use
			  send_stats "Open port"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "All ports are open"

			  ;;
		  6)
			root_use
			send_stats "Modify SSH port"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# Read the current SSH port number
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# Print the current SSH port number
				echo -e "The current SSH port number is:${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "Numbers with port numbers ranging from 1 to 65535. (Enter 0 to exit)"

				# Prompt the user to enter a new SSH port number
				read -e -p "Please enter the new SSH port number:" new_port

				# Determine whether the port number is within the valid range
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH port has been modified"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "Exit SSH port modification"
						break
					else
						echo "The port number is invalid, please enter a number between 1 and 65535."
						send_stats "Invalid SSH port input"
						break_end
					fi
				else
					echo "The input is invalid, please enter the number."
					send_stats "Invalid SSH port input"
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
			send_stats "New users disable root"
			read -e -p "Please enter the new username (enter 0 to exit):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "The operation has been completed."
			;;


		  10)
			root_use
			send_stats "Set v4/v6 priority"
			while true; do
				clear
				echo "Set v4/v6 priority"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "Current network priority settings:${gl_huang}IPv4${gl_bai}priority"
				else
					echo -e "Current network priority settings:${gl_huang}IPv6${gl_bai}priority"
				fi
				echo ""
				echo "------------------------"
				echo "1. IPv4 priority 2. IPv6 priority 3. IPv6 repair tool"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Choose a preferred network:" choice

				case $choice in
					1)
						sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
						echo "Switched to IPv4 priority"
						send_stats "Switched to IPv4 priority"
						;;
					2)
						sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
						echo "Switched to IPv6 priority"
						send_stats "Switched to IPv6 priority"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "This function is provided by the master jhb, thanks to him!"
						send_stats "ipv6 fix"
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
			send_stats "Set up virtual memory"
			while true; do
				clear
				echo "Set up virtual memory"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "Current virtual memory:${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. Assign 1024M 2. Assign 2048M 3. Assign 4096M 4. Custom size"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your selection:" choice

				case "$choice" in
				  1)
					send_stats "1G virtual memory has been set"
					add_swap 1024

					;;
				  2)
					send_stats "2G virtual memory has been set"
					add_swap 2048

					;;
				  3)
					send_stats "4G virtual memory has been set"
					add_swap 4096

					;;

				  4)
					read -e -p "Please enter the virtual memory size (unit M):" new_swap
					add_swap "$new_swap"
					send_stats "Custom virtual memory has been set"
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
				send_stats "User Management"
				echo "User List"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "Account operation"
				  echo "------------------------"
				  echo "1. Create a normal account 2. Create a premium account"
				  echo "------------------------"
				  echo "3. Give the highest permissions 4. Cancel the highest permissions"
				  echo "------------------------"
				  echo "5. Delete the account"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" sub_choice

				  case $sub_choice in
					  1)
					   # Prompt the user to enter a new username
					   read -e -p "Please enter a new username:" new_username

					   # Create a new user and set a password
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "The operation has been completed."
						  ;;

					  2)
					   # Prompt the user to enter a new username
					   read -e -p "Please enter a new username:" new_username

					   # Create a new user and set a password
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # Grant new users sudo permissions
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   echo "The operation has been completed."

						  ;;
					  3)
					   read -e -p "Please enter your username:" username
					   # Grant new users sudo permissions
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
						  ;;
					  4)
					   read -e -p "Please enter your username:" username
					   # Remove user's sudo permissions from sudoers file
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "Please enter the username to delete:" username
					   # Delete the user and its home directory
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
			send_stats "User Information Generator"
			echo "Random username"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "Random username$i: $username"
			done

			echo ""
			echo "Random name"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# Generate 5 random user names
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "Random user name$i: $user_name"
			done

			echo ""
			echo "Random UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "Random UUID$i: $uuid"
			done

			echo ""
			echo "16-bit random password"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "Random password$i: $password"
			done

			echo ""
			echo "32-bit random password"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "Random password$i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "Change time zone"
			while true; do
				clear
				echo "System time information"

				# Get the current system time zone
				local timezone=$(current_timezone)

				# Get the current system time
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# Show time zone and time
				echo "Current system time zone:$timezone"
				echo "Current system time:$current_time"

				echo ""
				echo "Time zone switching"
				echo "------------------------"
				echo "Asia"
				echo "1. Shanghai time in China 2. Hong Kong time in China"
				echo "3. Tokyo time in Japan 4. Seoul time in South Korea"
				echo "5. Singapore time 6. Kolkata time in India"
				echo "7. Dubai time in the UAE 8. Sydney time in Australia"
				echo "9. Time in Bangkok, Thailand"
				echo "------------------------"
				echo "Europe"
				echo "11. London time in the UK 12. Paris time in France"
				echo "13. Berlin time, Germany 14. Moscow time, Russia"
				echo "15. Utrecht time in the Netherlands 16. Madrid time in Spain"
				echo "------------------------"
				echo "America"
				echo "21. Western Time 22. Eastern Time"
				echo "23. Canadian time 24. Mexican time"
				echo "25. Brazil time 26. Argentina time"
				echo "------------------------"
				echo "31. UTC Global Standard Time"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your selection:" sub_choice


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
		  send_stats "Modify the host name"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "Current host name:${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "Please enter the new host name (enter 0 to exit):" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # Other systems, such as Debian, Ubuntu, CentOS, etc.
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

				  echo "The host name has been changed to:$new_hostname"
				  send_stats "Host name has been changed"
				  sleep 1
			  else
				  echo "Exited, hostname not changed."
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "Change the system update source"
		  clear
		  echo "Select the update source area"
		  echo "Connect to LinuxMirrors to switch system update source"
		  echo "------------------------"
		  echo "1. Mainland China [Default] 2. Mainland China [Education Network] 3. Overseas Regions"
		  echo "------------------------"
		  echo "0. Return to the previous menu"
		  echo "------------------------"
		  read -e -p "Enter your choice:" choice

		  case $choice in
			  1)
				  send_stats "Default source in mainland China"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "Source of education in mainland China"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "Overseas origin"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
				  echo "Canceled"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "Timing task management"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "Timed task list"
				  crontab -l
				  echo ""
				  echo "operate"
				  echo "------------------------"
				  echo "1. Add timing tasks 2. Delete timing tasks 3. Edit timing tasks"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "Please enter the execution command for the new task:" newquest
						  echo "------------------------"
						  echo "1. Monthly Tasks 2. Weekly Tasks"
						  echo "3. Daily tasks 4. Hourly tasks"
						  echo "------------------------"
						  read -e -p "Please enter your selection:" dingshi

						  case $dingshi in
							  1)
								  read -e -p "Choose what day of each month to perform tasks? (1-30):" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "Choose what week to perform the task? (0-6, 0 represents Sunday):" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "Choose what time to perform tasks every day? (Hours, 0-23):" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "Enter what minute of the hour to perform the task? (mins, 0-60):" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "Add timed tasks"
						  ;;
					  2)
						  read -e -p "Please enter the keywords that need to be deleted:" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "Delete timing tasks"
						  ;;
					  3)
						  crontab -e
						  send_stats "Edit timing tasks"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "Local host parsing"
			  while true; do
				  clear
				  echo "Native host parsing list"
				  echo "If you add parse matches here, dynamic parsing will no longer be used"
				  cat /etc/hosts
				  echo ""
				  echo "operate"
				  echo "------------------------"
				  echo "1. Add a new parsing 2. Delete the parsing address"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" host_dns

				  case $host_dns in
					  1)
						  read -e -p "Please enter a new parsing record Format: 110.25.5.33 kejilion.pro:" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "Local host parsing has been added"

						  ;;
					  2)
						  read -e -p "Please enter the keywords of parsing content that need to be deleted:" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "Local host parsing and deletion"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "ssh defense"
		  while true; do
			if [ -x "$(command -v fail2ban-client)" ] ; then
				clear
				remove fail2ban
				rm -rf /etc/fail2ban
			else
				clear
				docker_name="fail2ban"
				check_docker_app
				echo -e "SSH Defense Program$check_docker"
				echo "fail2ban is an SSH tool to prevent brute force"
				echo "Official website introduction:${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. Install the defense program"
				echo "------------------------"
				echo "2. View SSH interception records"
				echo "3. Real-time log monitoring"
				echo "------------------------"
				echo "9. Uninstall the defense program"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your selection:" sub_choice
				case $sub_choice in
					1)
						install_docker
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
						tail -f /path/to/fail2ban/config/log/fail2ban/fail2ban.log
						break
						;;
					9)
						docker rm -f fail2ban
						rm -rf /path/to/fail2ban
						echo "Fail2Ban defense program has been uninstalled"
						;;
					*)
						break
						;;
				esac
			fi
		  done
			  ;;


		  23)
			root_use
			send_stats "Current limit shutdown function"
			while true; do
				clear
				echo "Current limit shutdown function"
				echo "Video introduction: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "Current traffic usage, restarting the server traffic calculation will be cleared!"
				output_status
				echo -e "${gl_kjlan}Total Receive:${gl_bai}$rx"
				echo -e "${gl_kjlan}Total send:${gl_bai}$tx"

				# Check if the Limiting_Shut_down.sh file exists
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# Get the value of threshold_gb
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}The current set entry-station current limit threshold is:${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}The current outbound current limit threshold is:${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}Current limit shutdown function is not enabled${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "The system will detect whether the actual traffic reaches the threshold every minute, and the server will be automatically shut down after it arrives!"
				echo "------------------------"
				echo "1. Turn on the current limit shutdown function 2. Deactivate the current limit shutdown function"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your selection:" Limiting

				case "$Limiting" in
				  1)
					# Enter the new virtual memory size
					echo "If the actual server has 100G traffic, the threshold can be set to 95G and shut down the power in advance to avoid traffic errors or overflows."
					read -e -p "Please enter the incoming traffic threshold (unit is G, default is 100G):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "Please enter the outbound traffic threshold (unit is G, default is 100G):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "Please enter the traffic reset date (default reset on the 1st of each month):" cz_day
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
					echo "Current limit shutdown has been set"
					send_stats "Current limit shutdown has been set"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "Current limit shutdown function has been turned off"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "Private key login"
			  while true; do
				  clear
			  	  echo "ROOT private key login mode"
			  	  echo "Video introduction: https://www.bilibili.com/video/BV1Q4421X78n?t=209.4"
			  	  echo "------------------------------------------------"
			  	  echo "A key pair will be generated, a more secure way to SSH login"
				  echo "------------------------"
				  echo "1. Generate a new key 2. Import an existing key 3. View the native key"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your selection:" host_dns

				  case $host_dns in
					  1)
				  		send_stats "Generate a new key"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "Import an existing public key"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "View the local secret key"
						echo "------------------------"
						echo "Public key information"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "Private key information"
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
			  send_stats "Telegram warning"
			  echo "TG-bot monitoring and early warning function"
			  echo "Video introduction: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "You need to configure the tg robot API and the user ID to receive early warnings to realize real-time monitoring and early warning of native CPU, memory, hard disk, traffic, and SSH login"
			  echo "After reaching the threshold, the user will be sent to the user"
			  echo -e "${gl_hui}- Regarding traffic, restarting the server will recalculate-${gl_bai}"
			  read -e -p "Are you sure to continue? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  send_stats "Telegram warning is enabled"
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

				  # Add to ~/.profile file
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "TG-bot early warning system has been started"
				  echo -e "${gl_hui}You can also place the TG-check-notify.sh warning file in the root directory on other machines and use it directly!${gl_bai}"
				  ;;
				[Nn])
				  echo "Canceled"
				  ;;
				*)
				  echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "Fix high-risk vulnerabilities in SSH"
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
			  send_stats "Command line history"
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


		  41)
			clear
			send_stats "Message board"
			echo "The technology lion message board has been moved to the official community! Please leave a message in the official community!"
			echo "https://bbs.kejilion.pro/"
			  ;;

		  66)

			  root_use
			  send_stats "One-stop tuning"
			  echo "One-stop system optimization"
			  echo "------------------------------------------------"
			  echo "The following will be operated and optimized"
			  echo "1. Update the system to the latest"
			  echo "2. Clean up system junk files"
			  echo -e "3. Set up virtual memory${gl_huang}1G${gl_bai}"
			  echo -e "4. Set the SSH port number to${gl_huang}5522${gl_bai}"
			  echo -e "5. Open all ports"
			  echo -e "6. Turn on${gl_huang}BBR${gl_bai}accelerate"
			  echo -e "7. Set the time zone to${gl_huang}Shanghai${gl_bai}"
			  echo -e "8. Automatically optimize DNS address${gl_huang}Overseas: 1.1.1.1 8.8.8.8 Domestic: 223.5.5.5${gl_bai}"
			  echo -e "9. Install the basic tools${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10. Switch to kernel parameter optimization in Linux system${gl_huang}Balanced optimization mode${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "Are you sure to have one-click maintenance? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "One-stop tuning start"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/10. Update the system to the latest"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/10. Clean up system junk files"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/10. Set up virtual memory${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/10. Set the SSH port number to${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 5/10. Open all ports"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 6/10. Open${gl_huang}BBR${gl_bai}accelerate"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 7/10. Set the time zone to${gl_huang}Shanghai${gl_bai}"

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
				  echo -e "[${gl_lv}OK${gl_bai}] 8/10. Automatically optimize DNS address${gl_huang}${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 9/10. Install the basic tools${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10. Optimization of kernel parameters for Linux system"
				  echo -e "${gl_lv}One-stop system tuning has been completed${gl_bai}"

				  ;;
				[Nn])
				  echo "Canceled"
				  ;;
				*)
				  echo "Invalid selection, please enter Y or N."
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "Restart the system"
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

			  echo "Privacy and Security"
			  echo "The script will collect data on user functions, optimize the script experience, and create more fun and useful functions."
			  echo "Will collect the script version number, usage time, system version, CPU architecture, country of the machine and the name of the function used,"
			  echo "------------------------------------------------"
			  echo -e "Current status:$status_message"
			  echo "--------------------"
			  echo "1. Turn on collection"
			  echo "2. Close the collection"
			  echo "--------------------"
			  echo "0. Return to the previous menu"
			  echo "--------------------"
			  read -e -p "Please enter your selection:" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "Collection has been enabled"
					  send_stats "Privacy and security collection has been enabled"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "Collection closed"
					  send_stats "Privacy and Security have been closed for collection"
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
			  send_stats "Uninstall tech lion script"
			  echo "Uninstall tech lion script"
			  echo "------------------------------------------------"
			  echo "Will completely uninstall the kejilion script and will not affect your other functions"
			  read -e -p "Are you sure to continue? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "The script has been uninstalled, goodbye!"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "Canceled"
				  ;;
				*)
				  echo "Invalid selection, please enter Y or N."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "Invalid input!"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "File Manager"
	while true; do
		clear
		echo "File Manager"
		echo "------------------------"
		echo "Current path"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. Enter the directory 2. Create the directory 3. Modify the directory permissions 4. Rename the directory"
		echo "5. Delete the directory 6. Return to the previous menu directory"
		echo "------------------------"
		echo "11. Create a file 12. Edit a file 13. Modify file permissions 14. Rename a file"
		echo "15. Delete the file"
		echo "------------------------"
		echo "21. Compress file directory 22. Unzip file directory 23. Move file directory 24. Copy file directory"
		echo "25. Pass the file to another server"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your selection:" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "Please enter the directory name:" dirname
				cd "$dirname" 2>/dev/null || echo "Unable to enter the directory"
				send_stats "Go to the directory"
				;;
			2)  # 创建目录
				read -e -p "Please enter the directory name to create:" dirname
				mkdir -p "$dirname" && echo "Directory created" || echo "Creation failed"
				send_stats "Create a directory"
				;;
			3)  # 修改目录权限
				read -e -p "Please enter the directory name:" dirname
				read -e -p "Please enter permissions (such as 755):" perm
				chmod "$perm" "$dirname" && echo "Permissions have been modified" || echo "Modification failed"
				send_stats "Modify directory permissions"
				;;
			4)  # 重命名目录
				read -e -p "Please enter the current directory name:" current_name
				read -e -p "Please enter the new directory name:" new_name
				mv "$current_name" "$new_name" && echo "Directory has been renamed" || echo "Rename failed"
				send_stats "Rename the directory"
				;;
			5)  # 删除目录
				read -e -p "Please enter the directory name to delete:" dirname
				rm -rf "$dirname" && echo "Directory has been deleted" || echo "Deletion failed"
				send_stats "Delete Directory"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "Return to the previous menu directory"
				;;
			11) # 创建文件
				read -e -p "Please enter the file name to create:" filename
				touch "$filename" && echo "File created" || echo "Creation failed"
				send_stats "Create a file"
				;;
			12) # 编辑文件
				read -e -p "Please enter the file name to edit:" filename
				install nano
				nano "$filename"
				send_stats "Edit files"
				;;
			13) # 修改文件权限
				read -e -p "Please enter the file name:" filename
				read -e -p "Please enter permissions (such as 755):" perm
				chmod "$perm" "$filename" && echo "Permissions have been modified" || echo "Modification failed"
				send_stats "Modify file permissions"
				;;
			14) # 重命名文件
				read -e -p "Please enter the current file name:" current_name
				read -e -p "Please enter a new file name:" new_name
				mv "$current_name" "$new_name" && echo "File renamed" || echo "Rename failed"
				send_stats "Rename the file"
				;;
			15) # 删除文件
				read -e -p "Please enter the file name to delete:" filename
				rm -f "$filename" && echo "File deleted" || echo "Deletion failed"
				send_stats "Delete files"
				;;
			21) # 压缩文件/目录
				read -e -p "Please enter the file/directory name to be compressed:" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "Compressed to$name.tar.gz" || echo "Compression failed"
				send_stats "Compressed files/directories"
				;;
			22) # 解压文件/目录
				read -e -p "Please enter the file name (.tar.gz):" filename
				install tar
				tar -xzvf "$filename" && echo "Decompressed$filename" || echo "Decompression failed"
				send_stats "Unzip files/directories"
				;;

			23) # 移动文件或目录
				read -e -p "Please enter the file or directory path to move:" src_path
				if [ ! -e "$src_path" ]; then
					echo "Error: The file or directory does not exist."
					send_stats "Failed to move a file or directory: The file or directory does not exist"
					continue
				fi

				read -e -p "Please enter the target path (including the new file name or directory name):" dest_path
				if [ -z "$dest_path" ]; then
					echo "Error: Please enter the target path."
					send_stats "Moving file or directory failed: The destination path is not specified"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "The file or directory has been moved to$dest_path" || echo "Failed to move files or directories"
				send_stats "Move files or directories"
				;;


		   24) # 复制文件目录
				read -e -p "Please enter the file or directory path to copy:" src_path
				if [ ! -e "$src_path" ]; then
					echo "Error: The file or directory does not exist."
					send_stats "Failed to copy a file or directory: The file or directory does not exist"
					continue
				fi

				read -e -p "Please enter the target path (including the new file name or directory name):" dest_path
				if [ -z "$dest_path" ]; then
					echo "Error: Please enter the target path."
					send_stats "Failed to copy file or directory: Destination path not specified"
					continue
				fi

				# Use the -r option to copy the directory recursively
				cp -r "$src_path" "$dest_path" && echo "The file or directory has been copied to$dest_path" || echo "Failed to copy a file or directory"
				send_stats "Copy files or directories"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "Please enter the file path to be transferred:" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "Error: The file does not exist."
					send_stats "Failed to transfer the file: The file does not exist"
					continue
				fi

				read -e -p "Please enter the remote server IP:" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "Error: Please enter the remote server IP."
					send_stats "File transfer failed: Remote server IP was not entered"
					continue
				fi

				read -e -p "Please enter the remote server username (default root):" remote_user
				remote_user=${remote_user:-root}

				read -e -p "Please enter the remote server password:" -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "Error: Please enter the remote server password."
					send_stats "File transfer failed: Remote server password not entered"
					continue
				fi

				read -e -p "Please enter the login port (default 22):" remote_port
				remote_port=${remote_port:-22}

				# Clear old entries for known hosts
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# Transfer files using scp
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "The file has been transferred to the remote server home directory."
					send_stats "File transfer successfully"
				else
					echo "File transfer failed."
					send_stats "File transfer failed"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "Return to the previous menu menu"
				break
				;;
			*)  # 处理无效输入
				echo "Invalid selection, please re-enter"
				send_stats "Invalid selection"
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

	# Convert extracted information into an array
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# Iterate through the server and execute commands
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}Connect to$name ($hostname)...${gl_bai}"
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
	  send_stats "Cluster Control Center"
	  echo "Server cluster control"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}Server List Management${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}Add a server${gl_kjlan}2.  ${gl_bai}Delete the server${gl_kjlan}3.  ${gl_bai}Edit the server"
	  echo -e "${gl_kjlan}4.  ${gl_bai}Backup cluster${gl_kjlan}5.  ${gl_bai}Restore the cluster"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}Execute tasks in batches${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}Install the tech lion script${gl_kjlan}12. ${gl_bai}Update the system${gl_kjlan}13. ${gl_bai}Clean the system"
	  echo -e "${gl_kjlan}14. ${gl_bai}Install docker${gl_kjlan}15. ${gl_bai}Install BBR3${gl_kjlan}16. ${gl_bai}Set up 1G virtual memory"
	  echo -e "${gl_kjlan}17. ${gl_bai}Set the time zone to Shanghai${gl_kjlan}18. ${gl_bai}Open all ports${gl_kjlan}51. ${gl_bai}Custom commands"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your selection:" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "Add a cluster server"
			  read -e -p "Server name:" server_name
			  read -e -p "Server IP:" server_ip
			  read -e -p "Server Port (22):" server_port
			  local server_port=${server_port:-22}
			  read -e -p "Server username (root):" server_username
			  local server_username=${server_username:-root}
			  read -e -p "Server user password:" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "Delete the cluster server"
			  read -e -p "Please enter the keywords you need to delete:" rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "Edit the cluster server"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "Backup cluster"
			  echo -e "Please${gl_huang}/root/cluster/servers.py${gl_bai}Download the file and complete the backup!"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "Restore the cluster"
			  echo "Please upload your servers.py and press any key to start uploading!"
			  echo -e "Please upload your${gl_huang}servers.py${gl_bai}File to${gl_huang}/root/cluster/${gl_bai}Complete the restore!"
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
			  send_stats "Customize the execution of commands"
			  read -e -p "Please enter the batch execution command:" mingling
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
send_stats "Advertising column"
echo "Advertising column"
echo "------------------------"
echo "It will provide users with a simpler and more elegant promotion and purchasing experience!"
echo ""
echo -e "Server Offers"
echo "------------------------"
echo -e "${gl_lan}Leica Cloud Hong Kong CN2 GIA South Korea Dual ISP US CN2 GIA Discounts${gl_bai}"
echo -e "${gl_bai}Website: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd $10.99 per year United States 1 core 1G memory 20G hard drive 1T traffic per month${gl_bai}"
echo -e "${gl_bai}Website: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52.7 dollars per year United States 1 core 4G memory 50G hard drive 4T traffic per month${gl_bai}"
echo -e "${gl_bai}Website: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}Brickworker, $49 per quarter, US CN2GIA, Japan SoftBank, 2 cores, 1G memory, 20G hard drive, 1T traffic per month${gl_bai}"
echo -e "${gl_bai}Website: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT $28 per quarter US CN2GIA 1 core 2G memory 20G hard drive 800G traffic per month${gl_bai}"
echo -e "${gl_bai}Website: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS $6.9 per month Tokyo SoftBank 2 core 1G memory 20G hard drive 1T traffic per month${gl_bai}"
echo -e "${gl_bai}Website: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}More popular VPS offers${gl_bai}"
echo -e "${gl_bai}Website: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "Domain name discount"
echo "------------------------"
echo -e "${gl_lan}GNAME 8.8 dollars first year COM domain name 6.68 dollars first year CC domain name${gl_bai}"
echo -e "${gl_bai}Website: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "Technology lion surrounding"
echo "------------------------"
echo -e "${gl_kjlan}B station:${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}Oil pipe:${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}Official website:${gl_bai}https://kejilion.pro/              ${gl_kjlan}navigation:${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}blog:${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}Software Center:${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}Script official website:${gl_bai}https://kejilion.sh            ${gl_kjlan}GitHub address:${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "Script update"
cd ~
while true; do
	clear
	echo "Update log"
	echo "------------------------"
	echo "All logs:${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}You are already the latest version!${gl_huang}v$sh_v${gl_bai}"
		send_stats "The script is up to date and no update is required"
	else
		echo "Discover a new version!"
		echo -e "Current version v$sh_vLatest version${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}Automatic update is enabled, and the script will be automatically updated at 2 a.m. every day!${gl_bai}"
	fi

	echo "------------------------"
	echo "1. Update now 2. Turn on automatic update 3. Turn off automatic update"
	echo "------------------------"
	echo "0. Return to main menu"
	echo "------------------------"
	read -e -p "Please enter your selection:" choice
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
			echo -e "${gl_lv}The script has been updated to the latest version!${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "The script is up to date$sh_v_new"
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
			echo -e "${gl_lv}Automatic update is enabled, and the script will be automatically updated at 2 a.m. every day!${gl_bai}"
			send_stats "Turn on automatic script update"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}Automatic update is closed${gl_bai}"
			send_stats "Close script automatic update"
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
echo -e "Technology lion script toolbox v$sh_v"
echo -e "Command line input${gl_huang}k${gl_kjlan}Quickly start scripts${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}System information query"
echo -e "${gl_kjlan}2.   ${gl_bai}System update"
echo -e "${gl_kjlan}3.   ${gl_bai}System Cleanup"
echo -e "${gl_kjlan}4.   ${gl_bai}Basic tools"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR Management"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker Management"
echo -e "${gl_kjlan}7.   ${gl_bai}WARP Management"
echo -e "${gl_kjlan}8.   ${gl_bai}Test script collection"
echo -e "${gl_kjlan}9.   ${gl_bai}Oracle Cloud Script Collection"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP website building"
echo -e "${gl_kjlan}11.  ${gl_bai}Application Market"
echo -e "${gl_kjlan}12.  ${gl_bai}Backend workspace"
echo -e "${gl_kjlan}13.  ${gl_bai}System Tools"
echo -e "${gl_kjlan}14.  ${gl_bai}Server cluster control"
echo -e "${gl_kjlan}15.  ${gl_bai}Advertising column"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}Phantom Beast Palu server opening script"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}Script update"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}Exit script"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "Please enter your selection:" choice

case $choice in
  1) linux_ps ;;
  2) clear ; send_stats "System update" ; linux_update ;;
  3) clear ; send_stats "System Cleanup" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "warp management" ; install wget
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
  p) send_stats "Phantom Beast Palu server opening script" ; cd ~
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "Invalid input!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k command reference use case"
echo "-------------------"
echo "Video introduction: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
echo "The following is the k command reference use case:"
echo "Start script k"
echo "Install software package k install nano wget | k add nano wget | k Install nano wget"
echo "Uninstall the package k remove nano wget | k del nano wget | k uninstall nano wget | k Uninstall nano wget"
echo "Update system k update | k update"
echo "Clean system garbage k clean | k clean"
echo "Reinstall the system panel k dd | k Reinstall"
echo "bbr3 control panel k bbr3 | k bbrv3"
echo "Kernel Tuning Panel k nhyh | k kernel optimization"
echo "Set virtual memory k swap 2048"
echo "Set virtual time zone k time Asia/Shanghai | k time zone Asia/Shanghai"
echo "System Recycling Bin k trash | k hsz | k Recycling Bin"
echo "System backup function k backup | k bf | k backup"
echo "ssh remote connection tool k ssh | k remote connection"
echo "rsync remote synchronization tool k rsync | k remote synchronization"
echo "Hard disk management tool k disk | k hard disk management"
echo "Intranet penetration (server side) k frps"
echo "Intranet penetration (client) k frpc"
echo "Software start k start sshd | k start sshd"
echo "Software stop k stop sshd | k stop sshd"
echo "Software restart k restart sshd | k restart sshd"
echo "Software status view k status sshd | k status sshd"
echo "Software boot k enable docker | k autostart docke | k startup docker"
echo "Domain name certificate application k ssl"
echo "Domain name certificate expiration query k ssl ps"
echo "docker environment installation k docker install |k docker installation"
echo "docker container management k docker ps |k docker container"
echo "docker image management k docker img |k docker image"
echo "LDNMP site management k web"
echo "LDNMP cache cleanup k web cache"
echo "Install WordPress k wp |k wordpress |k wp xxx.com"
echo "Install the reverse proxy k fd |k rp |k anti-generation |k fd xxx.com"
echo "Install load balancing k loadbalance |k load balancing"
echo "Firewall panel k fhq |k firewall"
echo "Open port k dkdk 8080 |k Open port 8080"
echo "Close port k gbdk 7800 |k Close port 7800"
echo "Release IP k fxip 127.0.0.0/8 |k Release IP 127.0.0.0/8"
echo "Block IP k zzip 177.5.25.36 |k Block IP 177.5.25.36"


}



if [ "$#" -eq 0 ]; then
	# If there are no parameters, run interactive logic
	kejilion_sh
else
	# If there are parameters, execute the corresponding function
	case $1 in
		install|add|安装)
			shift
			send_stats "Install software"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "Uninstall the software"
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
			send_stats "Timed rsync synchronization"
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
			;;

		loadbalance|负载均衡)
			ldnmp_Proxy_backend
			;;

		swap)
			shift
			send_stats "Quickly set up virtual memory"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "Quickly set time zone"
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

		status|状态)
			shift
			send_stats "Software status view"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "Software startup"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "Software pause"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "Software restart"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "Software boots up"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "Check the certificate status"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "Quickly apply for a certificate"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "Quickly apply for a certificate"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "Quickly install docker"
					install_docker
					;;
				ps|容器)
					send_stats "Quick container management"
					docker_ps
					;;
				img|镜像)
					send_stats "Quick mirror management"
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

		*)
			k_info
			;;
	esac
fi

