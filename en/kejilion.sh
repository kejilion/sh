#!/bin/bash
sh_v="4.3.3"


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



# Define a function to execute the command
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



# This function collects function buried information and records the current script version number, usage time, system version, CPU architecture, machine country and function name used by the user. It does not involve any sensitive information, so don’t worry! Please believe me!
# Why is this function designed? The purpose is to better understand the functions that users like to use, and to further optimize the functions and launch more functions that meet user needs.
# The full text can be searched for the send_stats function call location. It is transparent and open source. If you have any concerns, you can refuse to use it.



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

# Prompt user to agree to terms
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}Welcome to the technology lion script toolbox${gl_bai}"
	echo "When using the script for the first time, please read and agree to the User License Agreement."
	echo "User License Agreement: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "Do you agree to the above terms? (y/n):" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "License agreement"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "permission denied"
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
		echo "No package parameters provided!"
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
	local required_gb=$1
	local path=${2:-/}

	mkdir -p "$path"

	local required_space_mb=$((required_gb * 1024))
	local available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

	if [ "$available_space_mb" -lt "$required_space_mb" ]; then
		echo -e "${gl_huang}hint:${gl_bai}Not enough disk space!"
		echo "Current available space: $((available_space_mb/1024))G"
		echo "Minimum required space:${required_gb}G"
		echo "The installation cannot continue. Please clear the disk space and try again."
		send_stats "Not enough disk space"
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
		echo "No package parameters provided!"
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


# Restart service
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1The service has been restarted."
	else
		echo "Error: Restart$1Service failed."
	fi
}

# Start service
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1The service has started."
	else
		echo "Error: start$1Service failed."
	fi
}

# Stop service
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1Service has stopped."
	else
		echo "Error: stop$1Service failed."
	fi
}

# Check service status
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1Service status is shown."
	else
		echo "Error: cannot be displayed$1Service status."
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAMEIt has been set to start automatically at boot."
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
	echo -e "${gl_huang}Installing docker environment...${gl_bai}"
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
	send_stats "Docker container management"
	echo "Docker container list"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "Container operations"
	echo "------------------------"
	echo "1. Create a new container"
	echo "------------------------"
	echo "2. Start the specified container 6. Start all containers"
	echo "3. Stop the specified container 7. Stop all containers"
	echo "4. Delete the specified container 8. Delete all containers"
	echo "5. Restart the specified container 9. Restart all containers"
	echo "------------------------"
	echo "11. Enter the specified container 12. View the container log"
	echo "13. Check the container network 14. Check the container occupancy"
	echo "------------------------"
	echo "15. Enable container port access 16. Close container port access"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your choice:" sub_choice
	case $sub_choice in
		1)
			send_stats "Create a new container"
			read -e -p "Please enter the create command:" dockername
			$dockername
			;;
		2)
			send_stats "Start the specified container"
			read -e -p "Please enter the container name (please separate multiple container names with spaces):" dockername
			docker start $dockername
			;;
		3)
			send_stats "Stop specified container"
			read -e -p "Please enter the container name (please separate multiple container names with spaces):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "Delete the specified container"
			read -e -p "Please enter the container name (please separate multiple container names with spaces):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "Restart the specified container"
			read -e -p "Please enter the container name (please separate multiple container names with spaces):" dockername
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
			send_stats "View container logs"
			read -e -p "Please enter the container name:" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "View container network"
			echo ""
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			printf "%-25s %-25s %-25s\n" "Container name" "network name" "IP address"
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

		15)
			send_stats "Allow container port access"
			read -e -p "Please enter the container name:" docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "Block container port access"
			read -e -p "Please enter the container name:" docker_name
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
	read -e -p "Please enter your choice:" sub_choice
	case $sub_choice in
		1)
			send_stats "Pull image"
			read -e -p "Please enter the image name (please separate multiple image names with spaces):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}Obtaining image:$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "Update image"
			read -e -p "Please enter the image name (please separate multiple image names with spaces):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}Updating image:$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "Delete image"
			read -e -p "Please enter the image name (please separate multiple image names with spaces):" imagenames
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
		echo "Unable to determine operating system."
		return
	fi

	echo -e "${gl_lv}crontab is installed and cron service is running.${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# Check if the configuration file exists, if not create the file and write the default settings
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# Use jq to handle configuration file updates
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# Check if the current configuration already has ipv6 settings
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# Update configuration and enable IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# Compare original configuration to new configuration
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
		echo -e "${gl_hong}Configuration file does not exist${gl_bai}"
		return
	fi

	# Read current configuration
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# Use jq to handle configuration file updates
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# Check current ipv6 status
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# Compare original configuration to new configuration
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
		# Delete existing shutdown rules
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# Add open rule
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "Port opened$port"
		fi
	done

	save_iptables_rules
	send_stats "Port opened"
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

		# Add shutdown rule
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

	# Insert new rule into the first one
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

		# Add allow rule
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

		# Add blocking rule
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP blocked$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP blocked"
}







enable_ddos_defense() {
	# Turn on DDoS protection
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

# Turn off DDoS defense
disable_ddos_defense() {
	# Turn off DDoS protection
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "Turn off DDoS defense"
}





# Functions to manage national IP rules
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
					echo "Error: Download$country_codeIP zone file failed"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "Blocked successfully$country_codeIP address"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "Error: Download$country_codeIP zone file failed"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "Successfully allowed$country_codeIP address"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "Removed successfully$country_codeIP address restrictions"
				;;

			*)
				echo "Usage: manage_country_rules {block|allow|unblock} <country_code...>"
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
		  echo "Advanced firewall management"
		  send_stats "Advanced firewall management"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "Firewall management"
		  echo "------------------------"
		  echo "1. Open the designated port 2. Close the designated port"
		  echo "3. Open all ports 4. Close all ports"
		  echo "------------------------"
		  echo "5. IP whitelist 6. IP blacklist"
		  echo "7. Clear the specified IP"
		  echo "------------------------"
		  echo "11. Allow PING 12. Disable PING"
		  echo "------------------------"
		  echo "13. Start DDOS defense 14. Turn off DDOS defense"
		  echo "------------------------"
		  echo "15. Block specified country IPs 16. Allow only specified country IPs"
		  echo "17. Lift IP restrictions in designated countries"
		  echo "------------------------"
		  echo "0. Return to the previous menu"
		  echo "------------------------"
		  read -e -p "Please enter your choice:" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "Please enter the open port number:" o_port
				  open_port $o_port
				  send_stats "Open specified port"
				  ;;
			  2)
				  read -e -p "Please enter the closed port number:" c_port
				  close_port $c_port
				  send_stats "Close specified port"
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
				  read -e -p "Please enter the allowed IP or IP segment:" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP blacklist
				  read -e -p "Please enter the blocked IP or IP range:" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # Clear specified IP
				  read -e -p "Please enter the cleared IP:" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "Clear specified IP"
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
				  read -e -p "Please enter the blocked country code (multiple country codes can be separated by spaces, such as CN US JP):" country_code
				  manage_country_rules block $country_code
				  send_stats "allow countries$country_codeIP"
				  ;;
			  16)
				  read -e -p "Please enter the allowed country codes (multiple country codes can be separated by spaces, such as CN US JP):" country_code
				  manage_country_rules allow $country_code
				  send_stats "block country$country_codeIP"
				  ;;

			  17)
				  read -e -p "Please enter the cleared country code (multiple country codes can be separated by spaces, such as CN US JP):" country_code
				  manage_country_rules unblock $country_code
				  send_stats "clear country$country_codeIP"
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

	# Traverse and delete all swap partitions
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# Make sure /swapfile is no longer in use
	swapoff /swapfile

	# Delete old /swapfile
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

	echo -e "The virtual memory size has been adjusted to${gl_huang}${new_swap}${gl_bai}M"
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

	  # Get mysql version
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # Get php version
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # Get redis version
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # Create necessary directories and files
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/stream.d web/redis web/log/nginx web/letsencrypt && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf

  default_server_ssl

  # Download the docker-compose.yml file and replace it
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # Replace in docker-compose.yml file
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}


update_docker_compose_with_db_creds() {

  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

  if ! grep -q "letsencrypt" /home/web/docker-compose.yml; then
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
	# Get the country code (such as CN, US, etc.)
	local country=$(curl -s ipinfo.io/country)

	# Set DNS based on country
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
echo "Switched to IPv4 priority"
send_stats "Switched to IPv4 priority"
}




install_ldnmp() {

	  update_docker_compose_with_db_creds

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -

	  fix_phpfpm_conf php
	  fix_phpfpm_conf php74

	  # mysql tuning
	  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
	  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
	  rm -rf /home/custom_mysql_config.cnf



	  restart_ldnmp
	  sleep 2

	  clear
	  echo "The LDNMP environment is installed"
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
	echo "The renewal task has been updated"
}


install_ssltls() {
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
echo -e "${gl_huang}Quickly apply for an SSL certificate and automatically renew it before expiration${gl_bai}"
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
	echo -e "${gl_huang}Expiration status of applied certificates${gl_bai}"
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
		send_stats "Domain name certificate application successful"
	else
		send_stats "Domain name certificate application failed"
		echo -e "${gl_hong}Notice:${gl_bai}Certificate application failed, please check the following possible reasons and try again:"
		echo -e "1. Domain name is spelled incorrectly ➠ Please check whether the domain name is entered correctly"
		echo -e "2. DNS resolution problem ➠ Confirm that the domain name has been correctly resolved to the server IP"
		echo -e "3. Network configuration issues ➠ If you use virtual networks such as Cloudflare Warp, please temporarily shut down"
		echo -e "4. Firewall restrictions ➠ Check whether port 80/443 is open and ensure that it is accessible"
		echo -e "5. The number of applications exceeds the limit ➠ Let's Encrypt has a weekly limit (5 times/domain name/week)"
		echo -e "6. Domestic registration restrictions ➠ For mainland China environment, please confirm whether the domain name is registered"
		echo "------------------------"
		echo "1. Apply again 2. Import the existing certificate 3. Use HTTP access without certificate 0. Exit"
		echo "------------------------"
		read -e -p "Please enter your choice:" sub_choice
		case $sub_choice in
	  	  1)
	  	  	send_stats "Reapply"
		  	echo "Please try deploying again$webname"
		  	add_yuming
		  	install_ssltls
		  	certs_status

	  		  ;;
	  	  2)
	  	  	send_stats "Import existing certificate"

			# Define file path
			local cert_file="/home/web/certs/${yuming}_cert.pem"
			local key_file="/home/web/certs/${yuming}_key.pem"

			mkdir -p /home/web/certs

			# 1. Enter the certificate (both ECC and RSA certificates start with BEGIN CERTIFICATE)
			echo "Please paste the certificate (CRT/PEM) content (press Enter twice to end):"
			local cert_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$cert_content" == *"-----BEGIN"* ]] && break
				cert_content+="${line}"$'\n'
			done

			# 2. Enter the private key (compatible with RSA, ECC, PKCS#8)
			echo "Please paste the certificate private key (Private Key) content (press Enter twice to end):"
			local key_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$key_content" == *"-----BEGIN"* ]] && break
				key_content+="${line}"$'\n'
			done

			# 3. Intelligent verification
			# Just include "BEGIN CERTIFICATE" and "PRIVATE KEY" to pass
			if [[ "$cert_content" == *"-----BEGIN CERTIFICATE-----"* && "$key_content" == *"PRIVATE KEY-----"* ]]; then
				echo -n "$cert_content" > "$cert_file"
				echo -n "$key_content" > "$key_file"

				chmod 644 "$cert_file"
				chmod 600 "$key_file"

				# Identify the current certificate type and display it
				if [[ "$key_content" == *"EC PRIVATE KEY"* ]]; then
					echo "Detected that the ECC certificate was saved successfully."
				else
					echo "Detected that the RSA certificate was saved successfully."
				fi
				auth_method="ssl_imported"
			else
				echo "Error: Invalid certificate or private key format!"
				certs_status
			fi

	  		  ;;
	  	  3)
	  	  	send_stats "Switch to HTTP access without a certificate"
		  	sed -i '/if (\$scheme = http) {/,/}/s/^/#/' /home/web/conf.d/${yuming}.conf
			sed -i '/ssl_certificate/d; /ssl_certificate_key/d' /home/web/conf.d/${yuming}.conf
			sed -i '/443 ssl/d; /443 quic/d' /home/web/conf.d/${yuming}.conf
	  		  ;;
	  	  *)
	  	  	send_stats "Withdraw application"
			rm -f /home/web/conf.d/${yuming}.conf
			exit
	  		  ;;
		esac
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
	  read -e -p "Please enter your IP or resolved domain name:" yuming
}


check_ip_and_get_access_port() {
	local yuming="$1"

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
		read -e -p "Please enter the access/listening port, and press Enter to use 80 by default:" access_port
		access_port=${access_port:-80}
	fi
}



update_nginx_listen_port() {
	local yuming="$1"
	local access_port="$2"
	local conf="/home/web/conf.d/${yuming}.conf"

	# Skip if access_port is empty
	[ -z "$access_port" ] && return 0

	# Remove all listen lines
	sed -i '/^[[:space:]]*listen[[:space:]]\+/d' "$conf"

	# Insert new listen after server {
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
  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/docker/refs/heads/main/docker-compose.phpmyadmin.yml
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
	# Read API_TOKEN and zone_id from configuration file
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# Convert ZONE_IDS to array
	ZONE_IDS=($ZONE_IDS)
  else
	# Prompt user whether to clear cache
	read -e -p "Need to clear Cloudflare's cache? (y/n):" answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF information is stored in$CONFIG_FILE, you can modify the CF information later"
	  read -e -p "Please enter your API_TOKEN:" API_TOKEN
	  read -e -p "Please enter your CF username:" EMAIL
	  read -e -p "Please enter zone_id (separate multiple with spaces):" -a ZONE_IDS

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

  echo "Cache clearing request has been sent."
}



web_cache() {
  send_stats "Clear site cache"
  cf_purge_cache
  cd /home/web && docker compose restart
}



web_del() {

	send_stats "Delete site data"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "To delete site data, please enter your domain name (separate multiple domain names with spaces):" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "Domain name is being deleted:$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# Convert domain name to database name
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# Check whether the database exists before deleting it to avoid errors.
		echo "Deleting database:$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# Determine whether to turn on or off WAF according to the mode parameter
	if [ "$mode" == "on" ]; then
		# Turn on WAF: remove comments
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# Turn off WAF: add comments
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "Invalid argument: use 'on' or 'off'"
		return 1
	fi

	# Check the nginx image and handle it accordingly
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
		waf_status="WAF is turned on"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/etc/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage="cf mode is on"
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

	# Insert the new definition before the line containing "Happy publishing"
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

	# Insert the new definition before the line containing "Happy publishing"
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
	# Delete old definition
	sed -i "/define(['\"]WP_HOME['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_SITEURL['\"].*/d" "$FILE"

	# Generate insert content
	INSERT="
define('WP_HOME', '$HOME_URL');
define('WP_SITEURL', '$SITE_URL');
"

	# Insert before “Happy publishing”
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
		# Turn on Brotli: remove comments
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
		# Close Brotli: add comments
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
		echo "Invalid argument: use 'on' or 'off'"
		return 1
	fi

	# Check the nginx image and handle it accordingly
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
		# Turn on Zstd: remove comments
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
		# Close Zstd: add comments
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
		echo "Invalid argument: use 'on' or 'off'"
		return 1
	fi

	# Check the nginx image and handle it accordingly
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
		echo "Invalid argument: use 'on' or 'off'"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP environment defense"
	  while true; do
		check_f2b_status
		check_waf_status
		check_cf_mode
			  clear
			  echo -e "Server website defense program${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. Install a defense program"
			  echo "------------------------"
			  echo "5. View SSH interception records 6. View website interception records"
			  echo "7. View the list of defense rules 8. View logs for real-time monitoring"
			  echo "------------------------"
			  echo "11. Configure interception parameters 12. Clear all blocked IPs"
			  echo "------------------------"
			  echo "21. cloudflare mode 22. Enable 5 seconds shield under high load"
			  echo "------------------------"
			  echo "31. Turn on WAF 32. Turn off WAF"
			  echo "33. Turn on DDOS defense 34. Turn off DDOS defense"
			  echo "------------------------"
			  echo "9. Uninstall the defense program"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your choice:" sub_choice
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
					  echo "Fail2Ban defense program has been uninstalled"
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
					  send_stats "cloudflare mode"
					  echo "Go to my profile in the upper right corner of the cf backend, select the API token on the left, and get the Global API Key"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "Enter CF’s account number:" cfuser
					  read -e -p "Enter CF’s Global API Key:" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /etc/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "Cloudflare mode has been configured, and the interception record can be viewed in the cf background, site-security-events"
					  ;;

				  22)
					  send_stats "High load enables 5 seconds shield"
					  echo -e "${gl_huang}The website automatically detects every 5 minutes. When it detects high load, it will automatically open the shield, and when it detects low load, it will automatically close the shield for 5 seconds.${gl_bai}"
					  echo "--------------"
					  echo "Get CF parameters:"
					  echo -e "Go to my profile in the upper right corner of the cf backend, select the API token on the left, and get${gl_huang}Global API Key${gl_bai}"
					  echo -e "Go to the bottom right of the cf backend domain name summary page to get it${gl_huang}Area ID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "Enter CF’s account number:" cfuser
					  read -e -p "Enter CF’s Global API Key:" cftoken
					  read -e -p "Enter the zone ID of the domain name in CF:" cfzonID

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
						  echo "The automatic shield opening script already exists, no need to add it"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "Site WAF is enabled"
					  send_stats "Site WAF is enabled"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "Site WAF is down"
					  send_stats "Site WAF is down"
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

	# Check if MySQL configuration file contains 4096M
	if docker exec "$MYSQL_CONTAINER" grep -q "4096M" "$MYSQL_CONF" 2>/dev/null; then
		mode_info="High performance mode"
	else
		mode_info="Standard mode"
	fi



}


check_nginx_compression() {

	local CONFIG_FILE="/home/web/nginx.conf"

	# Check whether zstd is on and uncommented (the whole line starts with zstd on;)
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status="zstd compression is on"
	else
		zstd_status=""
	fi

	# Check if brotli is enabled and uncommented
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status="brCompression is on"
	else
		br_status=""
	fi

	# Check if gzip is enabled and uncommented
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status="gzip compression is on"
	else
		gzip_status=""
	fi
}




web_optimization() {
		  while true; do
		  	  check_ldnmp_mode
			  check_nginx_compression
			  clear
			  send_stats "Optimize LDNMP environment"
			  echo -e "Optimize LDNMP environment${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. Standard mode 2. High performance mode (2H4G or above recommended)"
			  echo "------------------------"
			  echo "3. Turn on gzip compression 4. Turn off gzip compression"
			  echo "5. Turn on br compression 6. Turn off br compression"
			  echo "7. Turn on zstd compression 8. Turn off zstd compression"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your choice:" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "site standards mode"

				  local cpu_cores=$(nproc)
				  local connections=$((1024 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf


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

				  optimize_balanced


				  echo "The LDNMP environment has been set to standard mode"

					  ;;
				  2)
				  send_stats "Site high performance mode"

				  # nginx tuning
				  local cpu_cores=$(nproc)
				  local connections=$((2048 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf

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

				  optimize_web_server

				  echo "The LDNMP environment has been set to high performance mode"

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
		check_docker="${gl_lv}Installed${gl_bai}"
	else
		check_docker="${gl_hui}Not installed${gl_bai}"
	fi
}



# check_docker_app() {

# if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
# check_docker="${gl_lv} has installed ${gl_bai}"
# else
# check_docker="${gl_hui} is not installed ${gl_bai}"
# fi

# }


check_docker_app_ip() {
echo "------------------------"
echo "Visit address:"
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

	# 1. Regional inspection
	local country=$(curl -s --max-time 2 ipinfo.io/country)
	[[ "$country" == "CN" ]] && return

	# 2. Get local mirror information
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	[[ -z "$container_info" ]] && return

	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local full_image_name=$(echo "$container_info" | cut -d',' -f2)
	local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)

	# 3. Intelligent routing judgment
	if [[ "$full_image_name" == ghcr.io* ]]; then
		# --- Scenario A: Mirror on GitHub (ghcr.io) ---
		# Extract the warehouse path, for example ghcr.io/onexru/oneimg -> onexru/oneimg
		local repo_path=$(echo "$full_image_name" | sed 's/ghcr.io\///' | cut -d':' -f1)
		# Note: The API of ghcr.io is relatively complex. Usually the fastest way is to check the Release of GitHub Repo
		local api_url="https://api.github.com/repos/$repo_path/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	elif [[ "$full_image_name" == *"oneimg"* ]]; then
		# --- Scenario B: Special designation (even in Docker Hub, I want to judge by GitHub Release) ---
		local api_url="https://api.github.com/repos/onexru/oneimg/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	else
		# --- Scenario C: Standard Docker Hub ---
		local image_repo=${full_image_name%%:*}
		local image_tag=${full_image_name##*:}
		[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"
		[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

		local api_url="https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag"
		local remote_date=$(curl -s "$api_url" | jq -r '.last_updated' 2>/dev/null)
	fi

	# 4. Timestamp comparison
	if [[ -n "$remote_date" && "$remote_date" != "null" ]]; then
		local remote_ts=$(date -d "$remote_date" +%s 2>/dev/null)
		if [[ $container_created_ts -lt $remote_ts ]]; then
			update_status="${gl_huang}New version found!${gl_bai}"
		fi
	fi
}







block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# Get the IP address of the container
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
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

	# Check and allow local network 127.0.0.0/8
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

	# Check and allow local network 127.0.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+port has been blocked from accessing the service"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# Get the IP address of the container
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# Clear rules that block all other IPs
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# Clear the rules that allow specified IPs
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Clear the rules that allow local network 127.0.0.0/8
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# Clear rules that block all other IPs
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# Clear the rules that allow specified IPs
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Clear the rules that allow local network 127.0.0.0/8
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+port has been allowed to access the service"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Error: Please provide port number and IP to allow access."
		echo "Usage: block_host_port <port number> <allowed IP>"
		return 1
	fi

	install iptables


	# Deny access from all other IPs
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# Allow access to specified IP
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# Allow local access
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# Deny access from all other IPs
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# Allow access to specified IP
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

	echo "IP+port has been blocked from accessing the service"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Error: Please provide port number and IP to allow access."
		echo "Usage: clear_host_port_rules <port number> <allowed IP>"
		return 1
	fi

	install iptables


	# Clear the rule that blocks access from all other IPs
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# Clear rules that allow local access
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Clear rules that allow access from specified IPs
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# Clear the rule that blocks access from all other IPs
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# Clear rules that allow local access
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Clear rules that allow access from specified IPs
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "IP+port has been allowed to access the service"
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
send_stats "${docker_name}manage"

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
	echo "1. Install 2. Update 3. Uninstall"
	echo "------------------------"
	echo "5. Add domain name access 6. Delete domain name access"
	echo "7. Allow IP+port access 8. Block IP+port access"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your choice:" choice
	 case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			while true; do
				read -e -p "Enter the application external service port and press Enter to use it by default.${docker_port}port:" app_port
				local app_port=${app_port:-${docker_port}}

				if ss -tuln | grep -q ":$app_port "; then
					echo -e "${gl_hong}mistake:${gl_bai}port$app_portAlready occupied, please change a port"
					send_stats "Application port is occupied"
				else
					local docker_port=$app_port
					break
				fi
			done

			install jq
			install_docker
			docker_rum
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_nameInstallation completed"
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

			add_app_id

			clear
			echo "$docker_nameInstallation completed"
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

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "App has been uninstalled"
			send_stats "uninstall$docker_name"
			;;

		5)
			echo "${docker_name}Domain name access settings"
			send_stats "${docker_name}Domain name access settings"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "Domain name format example.com without https://"
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
		echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
		echo "5. Add domain name access 6. Delete domain name access"
		echo "7. Allow IP+port access 8. Block IP+port access"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Enter your selection:" choice
		case $choice in
			1)
				setup_docker_dir
				check_disk_space $app_size /home/docker
				
				while true; do
					read -e -p "Enter the application external service port and press Enter to use it by default.${docker_port}port:" app_port
					local app_port=${app_port:-${docker_port}}

					if ss -tuln | grep -q ":$app_port "; then
						echo -e "${gl_hong}mistake:${gl_bai}port$app_portAlready occupied, please change a port"
						send_stats "Application port is occupied"
					else
						local docker_port=$app_port
						break
					fi
				done

				install jq
				install_docker
				docker_app_install
				echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

				add_app_id
				send_stats "$app_nameInstall"
				;;

			2)
				docker_app_update
				add_app_id
				send_stats "$app_namerenew"
				;;

			3)
				docker_app_uninstall
				rm -f /home/docker/${docker_name}_port.conf

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				send_stats "$app_nameuninstall"
				;;

			5)
				echo "${docker_name}Domain name access settings"
				send_stats "${docker_name}Domain name access settings"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"

				;;
			6)
				echo "Domain name format example.com without https://"
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

# Function to check if session exists
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# Loop until a non-existing session name is found
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# Create a new tmux session
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
		check_f2b_status="${gl_lv}Installed${gl_bai}"
	else
		check_f2b_status="${gl_hui}Not installed${gl_bai}"
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
	echo -e "${gl_huang}hint:${gl_bai}The website building environment has been installed. No need to install again!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "Install LDNMP environment"
root_use
clear
echo -e "${gl_huang}The LDNMP environment is not installed. Start installing the LDNMP environment...${gl_bai}"
check_disk_space 3 /home
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
check_disk_space 1 /home
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
	  echo "your$webnameIt's built!"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webnameThe installation information is as follows:"

}

nginx_web_on() {
	clear

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	echo "your$webnameIt's built!"

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
  send_stats "Install$webname"
  echo "Start deployment$webname"
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
	webname="Reverse proxy-IP+port"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "Install$webname"
	echo "Start deployment$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy" ]; then
		read -e -p "Please enter your anti-generation IP (press Enter to default to the local IP 127.0.0.1):" reverseproxy
		reverseproxy=${reverseproxy:-127.0.0.1}
	fi

	if [ -z "$port" ]; then
		read -e -p "Please enter your anti-generation port:" port
	fi
	nginx_install_status

	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	reverseproxy_port="$reverseproxy:$port"
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# dynamically add/$upstream_servers/g" /home/web/conf.d/$yuming.conf
	sed -i '/remote_addr/d' /home/web/conf.d/$yuming.conf

	install_ssltls
	certs_status

	update_nginx_listen_port "$yuming" "$access_port"

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}



ldnmp_Proxy_backend() {
	clear
	webname="Reverse proxy-load balancing"

	send_stats "Install$webname"
	echo "Start deployment$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "Please enter your multiple anti-generation IP+ports separated by spaces (for example, 127.0.0.1:3000 127.0.0.1:3002):" reverseproxy_port
	fi

	nginx_install_status

	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# dynamically add/$upstream_servers/g" /home/web/conf.d/$yuming.conf

	install_ssltls
	certs_status

	update_nginx_listen_port "$yuming" "$access_port"

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}






list_stream_services() {

	STREAM_DIR="/home/web/stream.d"
	printf "%-25s %-18s %-25s %-20s\n" "Service name" "Communication type" "Local address" "Backend address"

	if [ -z "$(ls -A "$STREAM_DIR")" ]; then
		return
	fi

	for conf in "$STREAM_DIR"/*; do
		# Service name takes file name
		service_name=$(basename "$conf" .conf)

		# Get the server backend IP:port in the upstream block
		backend=$(grep -Po '(?<=server )[^;]+' "$conf" | head -n1)

		# Get listen port
		listen_port=$(grep -Po '(?<=listen )[^;]+' "$conf" | head -n1)

		# Default local IP
		ip_address
		local_ip="$ipv4_address"

		# Get the communication type, first judging from the file name suffix or content
		if grep -qi 'udp;' "$conf"; then
			proto="udp"
		else
			proto="tcp"
		fi

		# Splice listening IP:port
		local_addr="$local_ip:$listen_port"

		printf "%-22s %-14s %-21s %-20s\n" "$service_name" "$proto" "$local_addr" "$backend"
	done
}









stream_panel() {
	send_stats "Stream four-layer proxy"
	local app_id="104"
	local docker_name="nginx"

	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "Stream four-layer proxy forwarding tool$check_docker $update_status"
		echo "NGINX Stream is the TCP/UDP proxy module of NGINX, which is used to achieve high-performance transport layer traffic forwarding and load balancing."
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
		echo "4. Add forwarding service 5. Modify forwarding service 6. Delete forwarding service"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Enter your selection:" choice
		case $choice in
			1)
				nginx_install_status
				add_app_id
				send_stats "Install Stream four-layer agent"
				;;
			2)
				update_docker_compose_with_db_creds
				nginx_upgrade
				add_app_id
				send_stats "Update Stream four-layer proxy"
				;;
			3)
				read -e -p "Are you sure you want to delete the nginx container? This may affect website functionality! (y/N):" confirm
				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					docker rm -f nginx
					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					send_stats "Update Stream four-layer proxy"
					echo "nginx container has been deleted."
				else
					echo "The operation has been cancelled."
				fi

				;;

			4)
				ldnmp_Proxy_backend_stream
				add_app_id
				send_stats "Add layer 4 proxy"
				;;
			5)
				send_stats "Edit forwarding configuration"
				read -e -p "Please enter the service name you want to edit:" stream_name
				install nano
				nano /home/web/stream.d/$stream_name.conf
				docker restart nginx
				send_stats "Modify layer 4 proxy"
				;;
			6)
				send_stats "Delete forwarding configuration"
				read -e -p "Please enter the service name you want to delete:" stream_name
				rm /home/web/stream.d/$stream_name.conf > /dev/null 2>&1
				docker restart nginx
				send_stats "Delete layer 4 proxy"
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
	webname="Stream four-layer proxy-load balancing"

	send_stats "Install$webname"
	echo "Start deployment$webname"

	# Get agent name
	read -rp "Please enter a proxy forwarding name (e.g. mysql_proxy):" proxy_name
	if [ -z "$proxy_name" ]; then
		echo "Name cannot be empty"; return 1
	fi

	# Get listening port
	read -rp "Please enter the local listening port (such as 3306):" listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "Port must be numeric"; return 1
	fi

	echo "Please select agreement type:"
	echo "1. TCP    2. UDP"
	read -rp "Please enter the serial number [1-2]:" proto_choice

	case "$proto_choice" in
		1) proto="tcp"; listen_suffix="" ;;
		2) proto="udp"; listen_suffix=" udp" ;;
		*) echo "Invalid selection"; return 1 ;;
	esac

	read -e -p "Please enter one or more of your backend IP+ports separated by spaces (for example, 10.13.0.2:3306 10.13.0.3:3306):" reverseproxy_port

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

	sed -i "s/# dynamically add/$upstream_servers/g" /home/web/stream.d/$proxy_name.conf

	docker exec nginx nginx -s reload
	clear
	echo "your$webnameIt's built!"
	echo "------------------------"
	echo "Visit address:"
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
		send_stats "LDNMP site management"
		echo "LDNMP environment"
		echo "------------------------"
		ldnmp_v

		echo -e "Site:${output}Certificate expiration time"
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
		echo -e "database:${db_output}"
		echo -e "------------------------"
		local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2> /dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys"

		echo "------------------------"
		echo ""
		echo "site directory"
		echo "------------------------"
		echo -e "data${gl_hui}/home/web/html${gl_bai}Certificate${gl_hui}/home/web/certs${gl_bai}Configuration${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "operate"
		echo "------------------------"
		echo "1. Apply/update domain name certificate 2. Clone site domain name"
		echo "3. Clear site cache 4. Create associated site"
		echo "5. View the access log 6. View the error log"
		echo "7. Edit global configuration 8. Edit site configuration"
		echo "9. Manage site database 10. View site analysis reports"
		echo "------------------------"
		echo "20. Delete specified site data"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your choice:" sub_choice
		case $sub_choice in
			1)
				send_stats "Apply for a domain name certificate"
				read -e -p "Please enter your domain name:" yuming
				install_certbot
				docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "Clone site domain name"
				read -e -p "Please enter the old domain name:" oddyuming
				read -e -p "Please enter new domain name:" yuming
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

				# Website directory replacement
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
				send_stats "Create associated sites"
				echo -e "Associate a new domain name with the existing site for access"
				read -e -p "Please enter an existing domain name:" oddyuming
				read -e -p "Please enter new domain name:" yuming
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
				read -e -p "To edit site configuration, please enter the domain name you want to edit:" yuming
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
	check_panel="${gl_lv}Installed${gl_bai}"
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
	echo "${panelname}It is a popular and powerful operation and maintenance management panel."
	echo "Official website introduction:$panelurl "

	echo ""
	echo "------------------------"
	echo "1. Install 2. Manage 3. Uninstall"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Please enter your choice:" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install

			add_app_id
			send_stats "${panelname}Install"
			;;
		2)
			panel_app_manage

			add_app_id
			send_stats "${panelname}control"

			;;
		3)
			panel_app_uninstall

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
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
	check_frp="${gl_lv}Installed${gl_bai}"
else
	check_frp="${gl_hui}Not installed${gl_bai}"
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

	send_stats "Install frp server"
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

	# Output the generated information
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
	send_stats "Install frp client"
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
	send_stats "Add frp intranet service"
	# Prompts user for service name and forwarding information
	read -e -p "Please enter service name:" service_name
	read -e -p "Please enter the forwarding type (tcp/udp) [Enter to default to tcp]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "Please enter the intranet IP [default is 127.0.0.1 when pressing Enter]:" local_ip
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

	# Output the generated information
	echo "Serve$service_nameSuccessfully added to frpc.toml"

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "Delete frp intranet service"
	# Prompt the user to enter the name of the service that needs to be deleted
	read -e -p "Please enter the service name to be deleted:" service_name
	# Use sed to delete the service and its related configuration
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "Serve$service_nameSuccessfully removed from frpc.toml"

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# Print header
	printf "%-20s %-25s %-30s %-10s\n" "Service name" "Intranet address" "External network address" "protocol"

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
		# If service information already exists, print the current service before processing the new service
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# Update current service name
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# Clear previous value
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
		# Print information about the last service
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# Get FRP server port
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# Generate access address
generate_access_urls() {
	# First get all ports
	get_frp_ports

	# Check if there is a port other than 8055/8056
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# Show title and content only if there is a valid port
	if [ "$has_valid_ports" = true ]; then
		echo "FRP service external access address:"

		# Handling IPv4 addresses
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# Handle IPv6 address if present
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# Handle HTTPS configuration
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
	local app_id="55"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP server$check_frp $update_status"
		echo "Build an FRP intranet penetration service environment and expose devices without public IP to the Internet"
		echo "Official website introduction: https://github.com/fatedier/frp/"
		echo "Video tutorial: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
		echo "5. Intranet service domain name access 6. Delete domain name access"
		echo "------------------------"
		echo "7. Allow IP+port access 8. Block IP+port access"
		echo "------------------------"
		echo "00. Refresh service status 0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Enter your selection:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config

				add_app_id
				echo "The FRP server has been installed"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps

				add_app_id
				echo "The FRP server has been updated"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "App has been uninstalled"
				;;
			5)
				echo "Reverse intranet penetration service into domain name access"
				send_stats "FRP external domain name access"
				add_yuming
				read -e -p "Please enter your intranet penetration service port:" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "Domain name format example.com without https://"
				web_del
				;;

			7)
				send_stats "Allow IP access"
				read -e -p "Please enter the port that needs to be released:" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "Block IP access"
				echo "If you have reversed domain name access, you can use this function to block IP+port access, which is safer."
				read -e -p "Please enter the port to be blocked:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "Refresh FRP service status"
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
	send_stats "FRP client"
	local app_id="56"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP client$check_frp $update_status"
		echo "Connect with the server. After the connection, you can create an intranet penetration service to access the Internet."
		echo "Official website introduction: https://github.com/fatedier/frp/"
		echo "Video tutorial: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. Install 2. Update 3. Uninstall"
		echo "------------------------"
		echo "4. Add external services 5. Delete external services 6. Manually configure services"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Enter your selection:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc

				add_app_id
				echo "The FRP client has been installed"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc

				add_app_id
				echo "The FRP client has been updated"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "App has been uninstalled"
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
		   local YTDLP_STATUS="${gl_lv}Installed${gl_bai}"
		else
		   local YTDLP_STATUS="${gl_hui}Not installed${gl_bai}"
		fi

		clear
		send_stats "yt-dlp download tool"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp is a powerful video download tool that supports thousands of sites such as YouTube, Bilibili, Twitter, etc."
		echo -e "Official website address: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "Downloaded video list:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(None yet)"
		echo "-------------------------"
		echo "1. Install 2. Update 3. Uninstall"
		echo "-------------------------"
		echo "5. Single video download 6. Batch video download 7. Custom parameter download"
		echo "8. Download as MP3 audio 9. Delete video directory 10. Cookie management (under development)"
		echo "-------------------------"
		echo "0. Return to the previous menu"
		echo "-------------------------"
		read -e -p "Please enter option number:" choice

		case $choice in
			1)
				send_stats "Installing yt-dlp..."
				echo "Installing yt-dlp..."
				install ffmpeg
				curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				chmod a+rx /usr/local/bin/yt-dlp

				add_app_id
				echo "The installation is complete. Press any key to continue..."
				read ;;
			2)
				send_stats "Updating yt-dlp..."
				echo "Updating yt-dlp..."
				yt-dlp -U

				add_app_id
				echo "Update completed. Press any key to continue..."
				read ;;
			3)
				send_stats "Uninstalling yt-dlp..."
				echo "Uninstalling yt-dlp..."
				rm -f /usr/local/bin/yt-dlp

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "Uninstallation completed. Press any key to continue..."
				read ;;
			5)
				send_stats "Single video download"
				read -e -p "Please enter video link:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "Download completed, press any key to continue..." ;;
			6)
				send_stats "Batch video download"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# Enter multiple video link addresses\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "Start batch download now..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "Batch download completed, press any key to continue..." ;;
			7)
				send_stats "Custom video download"
				read -e -p "Please enter the complete yt-dlp parameters (excluding yt-dlp):" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "Execution completed, press any key to continue..." ;;
			8)
				send_stats "MP3 download"
				read -e -p "Please enter video link:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "Audio download complete, press any key to continue..." ;;

			9)
				send_stats "Delete video"
				read -e -p "Please enter the name of the deleted video:" rmdir
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



# Fix dpkg interruption problem
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}System update in progress...${gl_bai}"
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
	echo -e "${gl_huang}System cleaning in progress...${gl_bai}"
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
		echo "Clean package manager cache..."
		apk cache clean
		echo "Delete system log..."
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
		echo "Delete system log..."
		rm -rf /var/log/*
		echo "Delete temporary files..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "Clean up unused dependencies..."
		pkg autoremove -y
		echo "Clean package manager cache..."
		pkg clean -y
		echo "Delete system log..."
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
	read -e -p "Please enter your choice:" Limiting
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
		chattr -i /etc/resolv.conf
		nano /etc/resolv.conf
		chattr +i /etc/resolv.conf
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

	# If found PasswordAuthentication is set to yes
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

	# Sets default value if neither PasswordAuthentication nor PubkeyAuthentication matches
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # Back up SSH configuration files
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
	echo -e "The private key information has been generated. Be sure to copy and save it. It can be saved as${gl_huang}${ipv4_address}_ssh.key${gl_bai}file for future SSH logins"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT private key login has been turned on, ROOT password login has been turned off, reconnection will take effect${gl_bai}"

}


import_sshkey() {

	read -e -p "Please enter the contents of your SSH public key (usually starts with 'ssh-rsa' or 'ssh-ed25519'):" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}Error: Public key content not entered.${gl_bai}"
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
	echo -e "${gl_lv}The public key has been successfully imported, ROOT private key login has been enabled, and ROOT password login has been closed. Reconnection will take effect.${gl_bai}"

}




add_sshpasswd() {

echo "Set your ROOT password"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ROOT login setup is completed!${gl_bai}"

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
		  echo -e "${gl_huang}After reinstallation, please change the initial password in time to prevent violent intrusion. Enter passwd on the command line to change the password.${gl_bai}"
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
			echo -e "${gl_hong}Notice:${gl_bai}Reinstalling may cause loss of connection, so use with caution if you are worried. Reinstallation is expected to take 15 minutes, please back up your data in advance."
			echo -e "${gl_hui}Thanks to boss bin456789 and boss leitbogioro for their script support!${gl_bai} "
			echo -e "${gl_hui}bin456789 project address: https://github.com/bin456789/reinstall${gl_bai}"
			echo -e "${gl_hui}leitbogioro project address: https://github.com/leitbogioro/Tools${gl_bai}"
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
			echo "35. openSUSE Tumbleweed 36. fnos Feiniu public beta version"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2025"
			echo "45. Windows Server 2022       46. Windows Server 2019"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. Return to the previous menu"
			echo "------------------------"
			read -e -p "Please select the system you want to reinstall:" sys_choice
			case "$sys_choice" in


			  1)
				send_stats "Reinstall debian 13"
				dd_xitong_3
				bash reinstall.sh debian 13
				reboot
				exit
				;;

			  2)
				send_stats "Reinstall debian 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  3)
				send_stats "Reinstall debian 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  4)
				send_stats "Reinstall debian 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
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
				send_stats "Reinstall Feiniu"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;

			  41)
				send_stats "Reinstall Windows 11"
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
				send_stats "Reinstall windows7"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "Reinstall windows server 25"
				dd_xitong_2
				bash InstallNET.sh -windows 2025 -lang "cn"
				reboot
				exit
				;;

			  45)
				send_stats "Reinstall windows server 22"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;

			  46)
				send_stats "Reinstall windows server 19"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
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
				  echo "You have xanmod's BBRv3 kernel installed"
				  echo "Current kernel version:$kernel_version"

				  echo ""
				  echo "Kernel management"
				  echo "------------------------"
				  echo "1. Update BBRv3 kernel 2. Uninstall BBRv3 kernel"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# Step 3: Add repository
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "XanMod kernel has been updated. Take effect after restart"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "The XanMod kernel has been uninstalled. Take effect after restart"
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
		  echo "Only supports Debian/Ubuntu"
		  echo "Please back up your data and we will upgrade your Linux kernel and enable BBR3."
		  echo "------------------------------------------------"
		  read -e -p "Are you sure you want to continue? (Y/N):" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "The current environment does not support it. Only Debian and Ubuntu systems are supported."
					break_end
					linux_Settings
				fi
			else
				echo "Unable to determine operating system type"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# Step 3: Add repository
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "The XanMod kernel is installed and BBR3 is enabled successfully. Take effect after restart"
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
	# Import the ELRepo GPG public key
	echo "Import the ELRepo GPG public key..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# Check system version
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# Make sure we're running on a supported operating system
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "Unsupported operating systems:$os_name"
		break_end
		linux_Settings
	fi
	# Print detected operating system information
	echo "Detected operating systems:$os_name $os_version"
	# Install the corresponding ELRepo warehouse configuration according to the system version
	if [[ "$os_version" == 8 ]]; then
		echo "Installing the ELRepo repository configuration (version 8)..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "Installing the ELRepo repository configuration (version 9)..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "Installing the ELRepo repository configuration (version 10)..."
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
	echo "Installed ELRepo repository configuration and updated to latest mainline kernel."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "Red Hat Kernel Management"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "You have installed elrepo kernel"
				  echo "Current kernel version:$kernel_version"

				  echo ""
				  echo "Kernel management"
				  echo "------------------------"
				  echo "1. Update elrepo kernel 2. Uninstall elrepo kernel"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "Update Red Hat Kernel"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "The elrepo kernel has been uninstalled. Take effect after restart"
						send_stats "Uninstall Red Hat Kernel"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "Please back up your data and we will upgrade the Linux kernel for you."
		  echo "Video introduction: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		  echo "------------------------------------------------"
		  echo "Only supports Red Hat series distributions CentOS/RedHat/Alma/Rocky/oracle"
		  echo "Upgrading the Linux kernel can improve system performance and security. It is recommended to try it if possible, and upgrade the production environment with caution!"
		  echo "------------------------------------------------"
		  read -e -p "Are you sure you want to continue? (Y/N):" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "Upgrade Red Hat kernel"
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
	echo -e "${gl_huang}Updating virus database...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "Please specify the directories to scan."
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

	# Execute Docker command
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ 扫描完成，病毒报告存放在${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}If there is a virus please${gl_huang}scan.log${gl_lv}Search the file for the FOUND keyword to confirm the location of the virus${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "Virus scan management"
		  while true; do
				clear
				echo "clamav virus scanning tool"
				echo "Video introduction: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
				echo "------------------------"
				echo "It is an open source antivirus software tool mainly used to detect and remove various types of malware."
				echo "Includes viruses, Trojan horses, spyware, malicious scripts and other harmful software."
				echo "------------------------"
				echo -e "${gl_lv}1. Full scan${gl_bai}             ${gl_huang}2. Scan important directories${gl_bai}            ${gl_kjlan}3. Custom directory scanning${gl_bai}"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your choice:" sub_choice
				case $sub_choice in
					1)
					  send_stats "Full scan"
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
					  send_stats "Custom directory scan"
					  read -e -p "Please enter the directories to scan, separated by spaces (for example: /etc /var /usr /home /root):" directories
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




# High performance mode optimization function
optimize_high_performance() {
	echo -e "${gl_lv}switch to${tiaoyou_moshi}...${gl_bai}"

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
	# Disable transparent huge pages to reduce latency
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# Disable NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# Balanced mode optimization function
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
	# Restore transparent huge pages
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# Restore NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# Restore default settings function
restore_defaults() {
	echo -e "${gl_lv}Revert to default settings...${gl_bai}"

	echo -e "${gl_lv}Restore file descriptors...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}Restore virtual memory...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}Reset network settings...${gl_bai}"
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

	echo -e "${gl_lv}Revert other optimizations...${gl_bai}"
	# Restore transparent huge pages
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# Restore NUMA balancing
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# Website building optimization function
optimize_web_server() {
	echo -e "${gl_lv}Switch to website construction optimization mode...${gl_bai}"

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
	# Disable transparent huge pages to reduce latency
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# Disable NUMA balancing
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux kernel tuning management"
	  echo "Linux system kernel parameter optimization"
	  echo "Video introduction: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "Provides a variety of system parameter tuning modes, and users can choose to switch according to their own usage scenarios."
	  echo -e "${gl_huang}hint:${gl_bai}Please use it with caution in production environment!"
	  echo "--------------------"
	  echo "1. High-performance optimization mode: Maximize system performance and optimize file descriptors, virtual memory, network settings, cache management and CPU settings."
	  echo "2. Balanced optimization mode: strikes a balance between performance and resource consumption, suitable for daily use."
	  echo "3. Website optimization mode: Optimize the website server to improve concurrent connection processing capabilities, response speed and overall performance."
	  echo "4. Live broadcast optimization mode: Optimize the special needs of live streaming to reduce delays and improve transmission performance."
	  echo "5. Game server optimization mode: Optimize the game server to improve concurrent processing capabilities and response speed."
	  echo "6. Restore default settings: Restore system settings to default configuration."
	  echo "--------------------"
	  echo "0. Return to the previous menu"
	  echo "--------------------"
	  read -e -p "Please enter your choice:" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="High performance optimization mode"
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
			  local tiaoyou_moshi="Live broadcast optimization mode"
			  optimize_high_performance
			  send_stats "Live streaming optimization"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="Game server optimization mode"
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
				echo -e "${gl_lv}The system language has been modified to:$langReconnect to SSH to take effect.${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}The system language has been modified to:$langReconnect to SSH to take effect.${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "Unsupported systems:$ID"
				break_end
				;;
		esac
	else
		echo "Unsupported system, system type cannot be identified."
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
  read -e -p "Enter your selection:" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "switch to english"
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
echo -e "${gl_lv}Change completed. Reconnect to SSH to see the changes!${gl_bai}"

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
	read -e -p "Enter your selection:" choice

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
  send_stats "System Recycle Bin"

  local bashrc_profile="/root/.bashrc"
  local TRASH_DIR="$HOME/.local/share/Trash/files"

  while true; do

	local trash_status
	if ! grep -q "trash-put" "$bashrc_profile"; then
		trash_status="${gl_hui}Not enabled${gl_bai}"
	else
		trash_status="${gl_lv}Enabled${gl_bai}"
	fi

	clear
	echo -e "Current recycle bin${trash_status}"
	echo -e "After enabling it, files deleted by rm will be put into the recycle bin first to prevent accidental deletion of important files!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "Recycle bin is empty"
	echo "------------------------"
	echo "1. Enable Recycle Bin 2. Close Recycle Bin"
	echo "3. Restore content 4. Empty Recycle Bin"
	echo "------------------------"
	echo "0. Return to the previous menu"
	echo "------------------------"
	read -e -p "Enter your selection:" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "Recycle Bin is enabled, deleted files will be moved to Recycle Bin."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "The recycle bin is closed and the files will be deleted directly."
		sleep 2
		;;
	  3)
		read -e -p "Enter the file name to be restored:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restoreRestored to home directory."
		else
		  echo "File does not exist."
		fi
		;;
	  4)
		read -e -p "Are you sure you want to empty the Recycle Bin? [y/n]:" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "Recycle Bin has been emptied."
		fi
		;;
	  *)
		break
		;;
	esac
  done
}

linux_fav() {
send_stats "Command Favorites"
bash <(curl -l -s ${gh_proxy}raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh)
}

# Create a backup
create_backup() {
	send_stats "Create a backup"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# Prompt user for backup directory
	echo "Example of creating a backup:"
	echo "- Back up a single directory: /var/www"
	echo "- Back up multiple directories: /etc /home /var/log"
	echo "- Press Enter to use the default directory (/etc /usr /home)"
	read -r -p "Please enter the directory to be backed up (separate multiple directories with spaces, and press Enter to use the default directory):" input

	# If the user does not enter a directory, the default directory is used
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# Separate the directories entered by the user into an array by spaces
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

	# Print directory selected by user
	echo "The backup directory you selected is:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# Create a backup
	echo "Creating backup$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# Check if the command was successful
	if [ $? -eq 0 ]; then
		echo "Backup created successfully:$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "Backup creation failed!"
		exit 1
	fi
}

# Restore backup
restore_backup() {
	send_stats "Restore backup"
	# Select the backup to restore
	read -e -p "Please enter the backup file name to be restored:" BACKUP_NAME

	# Check if the backup file exists
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "The backup file does not exist!"
		exit 1
	fi

	echo "Restoring backup$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "Backup and restore successful!"
	else
		echo "Backup restore failed!"
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

	read -e -p "Please enter the backup file name to be deleted:" BACKUP_NAME

	# Check if the backup file exists
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "The backup file does not exist!"
		exit 1
	fi

	# Delete backup
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "Backup deleted successfully!"
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
		echo "1. Create backup 2. Restore backup 3. Delete backup"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your choice:" choice
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
	echo "Saved connections:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# Add new connection
add_connection() {
	send_stats "Add new connection"
	echo "Example of creating a new connection:"
	echo "- Connection name: my_server"
	echo "- IP address: 192.168.1.100"
	echo "- Username: root"
	echo "- Port: 22"
	echo "------------------------"
	read -e -p "Please enter a connection name:" name
	read -e -p "Please enter IP address:" ip
	read -e -p "Please enter username (default: root):" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "Please enter the port number (default: 22):" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "Please select an authentication method:"
	echo "1. Password"
	echo "2. Key"
	read -e -p "Please enter your choice (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "Please enter password:" password_or_key
			echo  # 换行
			;;
		2)
			echo "Please paste the key content (press Enter twice after pasting):"
			local password_or_key=""
			while IFS= read -r line; do
				# If the input is a blank line and the key content already contains the beginning, end the input
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# If it is the first line or you have already started entering the key content, continue adding
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
	echo "Connection saved!"
}



# Delete connection
delete_connection() {
	send_stats "Delete connection"
	read -e -p "Please enter the connection number to be deleted:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Error: Corresponding connection not found."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# If the connection is using a key file, delete the key file
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "Connection deleted!"
}

# Use connection
use_connection() {
	send_stats "Use connection"
	read -e -p "Please enter the connection number to use:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Error: Corresponding connection not found."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "Connecting to$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# Connect using a key
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "Connection failed! Please check the following:"
			echo "1. Is the key file path correct?$password_or_key"
			echo "2. Are the key file permissions correct (should be 600)."
			echo "3. Whether the target server allows login using a key."
		fi
	else
		# Connect using password
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
			echo "1. Are the username and password correct?"
			echo "2. Whether the target server allows password login."
			echo "3. Whether the SSH service of the target server is running normally."
		fi
	fi
}


ssh_manager() {
	send_stats "ssh remote connection tool"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# Check if the configuration file and key directory exist, create them if they do not exist
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "SSH remote connection tool"
		echo "Can connect to other Linux systems via SSH"
		echo "------------------------"
		list_connections
		echo "1. Create a new connection 2. Use the connection 3. Delete the connection"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your choice:" choice
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
	echo "Available hard drive partitions:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# Mount partition
mount_partition() {
	send_stats "Mount partition"
	read -e -p "Please enter the name of the partition to be mounted (e.g. sda1):" PARTITION

	# Check if the partition exists
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "The partition does not exist!"
		return
	fi

	# Check whether the partition is mounted
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "The partition has been mounted!"
		return
	fi

	# Create mount point
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# Mount partition
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "Partition mounted successfully:$MOUNT_POINT"
	else
		echo "Partition mount failed!"
		rmdir "$MOUNT_POINT"
	fi
}

# Unmount partition
unmount_partition() {
	send_stats "Unmount partition"
	read -e -p "Please enter the name of the partition to be unmounted (e.g. sda1):" PARTITION

	# Check whether the partition is mounted
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "The partition is not mounted!"
		return
	fi

	# Unmount partition
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "Partition uninstalled successfully:$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "Partition uninstall failed!"
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
	read -e -p "Please enter the name of the partition to be formatted (e.g. sda1):" PARTITION

	# Check if the partition exists
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "The partition does not exist!"
		return
	fi

	# Check whether the partition is mounted
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "The partition has been mounted, please unmount it first!"
		return
	fi

	# Select file system type
	echo "Please select a file system type:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "Please enter your choice:" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "Invalid choice!"; return ;;
	esac

	# Confirm formatting
	read -e -p "Confirm formatted partition /dev/$PARTITIONfor$FS_TYPE? (y/n):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "The operation has been cancelled."
		return
	fi

	# Format partition
	echo "Formatting partition /dev/$PARTITIONfor$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "Partition formatted successfully!"
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
	echo "Check partition /dev/$PARTITIONstatus:"
	fsck "/dev/$PARTITION"
}

# Main menu
disk_manager() {
	send_stats "Hard disk management function"
	while true; do
		clear
		echo "Hard drive partition management"
		echo -e "${gl_huang}This feature is under internal testing and should not be used in a production environment.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. Mount the partition 2. Unmount the partition 3. View the mounted partition"
		echo "4. Format partition 5. Check partition status"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your choice:" choice
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
	echo "Saved sync tasks:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# Add new task
add_task() {
	send_stats "Add new sync task"
	echo "Example of creating a new sync task:"
	echo "- Task name: backup_www"
	echo "- Local directory: /var/www"
	echo "- Remote address: user@192.168.1.100"
	echo "- Remote directory: /backup/www"
	echo "- Port number (default 22)"
	echo "---------------------------------"
	read -e -p "Please enter the task name:" name
	read -e -p "Please enter the local directory:" local_path
	read -e -p "Please enter the remote directory:" remote_path
	read -e -p "Please enter remote user@IP:" remote
	read -e -p "Please enter the SSH port (default 22):" port
	port=${port:-22}

	echo "Please select an authentication method:"
	echo "1. Password"
	echo "2. Key"
	read -e -p "Please select (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "Please enter password:" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "Please paste the key content (press Enter twice after pasting):"
			local password_or_key=""
			while IFS= read -r line; do
				# If the input is a blank line and the key content already contains the beginning, end the input
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# If it is the first line or you have already started entering the key content, continue adding
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

	echo "Please select synchronization mode:"
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

	echo "Mission saved!"
}

# Delete task
delete_task() {
	send_stats "Delete sync task"
	read -e -p "Please enter the task number to be deleted:" num

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
	echo "Task has been deleted!"
}


run_task() {
	send_stats "Perform synchronization tasks"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# Parse parameters
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# If no task number is passed in, the user is prompted to enter
	if [[ -z "$num" ]]; then
		read -e -p "Please enter the task number to be executed:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "Error: The task was not found!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# Adjust source and destination paths based on synchronization direction
	if [[ "$direction" == "pull" ]]; then
		echo "Pulling and synchronizing to local:$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "Pushing and synchronizing to the remote end:$local_path -> $remote:$remote_path"
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
			echo "Error: Key file does not exist:$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "Warning: Incorrect key file permissions, fixing..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "Synchronization completed!"
	else
		echo "Sync failed! Please check the following:"
		echo "1. Is the network connection normal?"
		echo "2. Whether the remote host is accessible"
		echo "3. Is the authentication information correct?"
		echo "4. Do the local and remote directories have correct access permissions?"
	fi
}


# Create a scheduled task
schedule_task() {
	send_stats "Add synchronization scheduled tasks"

	read -e -p "Please enter the task number to be synchronized regularly:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Error: Please enter a valid task number!"
		return
	fi

	echo "Please select the scheduled execution interval:"
	echo "1) Execute once every hour"
	echo "2) Execute once a day"
	echo "3) Execute once a week"
	read -e -p "Please enter options (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "Error: Please enter valid options!" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# Check if the same task already exists
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "Error: The scheduled synchronization for this task already exists!"
		return
	fi

	# Create to user's crontab
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "Scheduled task has been created:$cron_job"
}

# View scheduled tasks
view_tasks() {
	echo "Current scheduled tasks:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# Delete scheduled tasks
delete_task_schedule() {
	send_stats "Delete synchronization scheduled tasks"
	read -e -p "Please enter the task number to be deleted:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Error: Please enter a valid task number!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "Task number deleted$numscheduled tasks"
}


# Task management main menu
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync remote synchronization tool"
		echo "Synchronization between remote directories supports incremental synchronization, which is efficient and stable."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. Create a new task 2. Delete a task"
		echo "3. Perform local synchronization to the remote site 4. Perform remote synchronization to the local site"
		echo "5. Create a scheduled task 6. Delete a scheduled task"
		echo "---------------------------------"
		echo "0. Return to the previous menu"
		echo "---------------------------------"
		read -e -p "Please enter your choice:" choice
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









linux_info() {

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

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1% 3600) / 60); if (run_days > 0) printf("%d day ", run_days); if (run_hours > 0) printf("%d hour ", run_hours); printf("%d minute\n", run_minutes)}')

	local timezone=$(current_timezone)

	local tcp_count=$(ss -t | wc -l)
	local udp_count=$(ss -u | wc -l)


	echo ""
	echo -e "System information query"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Hostname:${gl_bai}$hostname"
	echo -e "${gl_kjlan}System version:${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linux version:${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU architecture:${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPU model:${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}Number of CPU cores:${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU frequency:${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU usage:${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}System load:${gl_bai}$load"
	echo -e "${gl_kjlan}Number of TCP|UDP connections:${gl_bai}$tcp_count|$udp_count"
	echo -e "${gl_kjlan}Physical memory:${gl_bai}$mem_info"
	echo -e "${gl_kjlan}Virtual memory:${gl_bai}$swap_info"
	echo -e "${gl_kjlan}Hard drive usage:${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Total received:${gl_bai}$rx"
	echo -e "${gl_kjlan}Total sent:${gl_bai}$tx"
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
	echo -e "${gl_kjlan}Location:${gl_bai}$country $city"
	echo -e "${gl_kjlan}System time:${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Running time:${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "Basic tools"
	  echo -e "basic tools"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}curl download tool${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget download tool${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo super administrative privilege tool${gl_kjlan}4.   ${gl_bai}socat communication connection tool"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop system monitoring tool${gl_kjlan}6.   ${gl_bai}iftop network traffic monitoring tool"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP compression and decompression tool${gl_kjlan}8.   ${gl_bai}tar GZ compression and decompression tool"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux multi-channel background running tool${gl_kjlan}10.  ${gl_bai}ffmpeg video encoding live streaming tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop modern monitoring tool${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}ranger file management tool"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu disk usage viewing tool${gl_kjlan}14.  ${gl_bai}fzf global search tool"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim text editor${gl_kjlan}16.  ${gl_bai}nano text editor${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}git version control system${gl_kjlan}18.  ${gl_bai}opencode AI programming assistant${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}The Matrix Screensaver${gl_kjlan}22.  ${gl_bai}Running train screensaver"
	  echo -e "${gl_kjlan}26.  ${gl_bai}Tetris mini game${gl_kjlan}27.  ${gl_bai}Snake mini game"
	  echo -e "${gl_kjlan}28.  ${gl_bai}space invaders mini game"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Install all${gl_kjlan}32.  ${gl_bai}Install all (excluding screensavers and games)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Uninstall all"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}Install specified tools${gl_kjlan}42.  ${gl_bai}Uninstall the specified tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "The tool has been installed and is used as follows:"
			  curl --help
			  send_stats "Install curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "The tool has been installed and is used as follows:"
			  wget --help
			  send_stats "Install wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "The tool has been installed and is used as follows:"
			  sudo --help
			  send_stats "install sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "The tool has been installed and is used as follows:"
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
			  echo "The tool has been installed and is used as follows:"
			  unzip
			  send_stats "installunzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "The tool has been installed and is used as follows:"
			  tar --help
			  send_stats "Install tar"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "The tool has been installed and is used as follows:"
			  tmux --help
			  send_stats "Install tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "The tool has been installed and is used as follows:"
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

			18)
			  clear
			  cd ~
			  curl -fsSL https://opencode.ai/install | bash
			  source ~/.bashrc
			  source ~/.profile
			  opencode
			  send_stats "Install opencode"
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
			  send_stats "Install all (excluding games and screensavers)"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "Uninstall all"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  opencode uninstall
			  rm -rf ~/.opencode
			  ;;

		  41)
			  clear
			  read -e -p "Please enter the installed tool name (wget curl sudo htop):" installname
			  install $installname
			  send_stats "Install specified software"
			  ;;
		  42)
			  clear
			  read -e -p "Please enter the uninstalled tool name (htop ufw tmux cmatrix):" removename
			  remove $removename
			  send_stats "Uninstall specified software"
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
			  echo "BBR management"
			  echo "------------------------"
			  echo "1. Turn on BBRv3 2. Turn off BBRv3 (it will restart)"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your choice:" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "alpine opens bbr3"
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
		echo -e "${BLUE}Current backup list:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "No backup"
	}



	# ----------------------------
	# backup
	# ----------------------------
	backup_docker() {
		send_stats "Docker backup"

		echo -e "${YELLOW}Backing up Docker containers...${NC}"
		docker ps --format '{{.Names}}'
		read -e -p  "Please enter the name of the container to be backed up (separate multiple spaces and press Enter to back up all running containers):" containers

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
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && { echo -e "${RED}Container not found${NC}"; return; }

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" > "$RESTORE_SCRIPT"
		echo "set -e" >> "$RESTORE_SCRIPT"
		echo "# Automatically generated restore script" >> "$RESTORE_SCRIPT"

		# Record the packaged Compose project path to avoid repeated packaging
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN}Backup container:$c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" > "$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE}detected$cis a docker-compose container${NC}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p  "The compose directory is not detected, please enter the path manually:" project_dir
				fi

				# If the Compose project has already been packaged, skip
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}Compose project [$project_name] Already backed up, skip repeated packaging...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" > "${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" > "${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# docker-compose restore:$project_name" >> "$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >> "$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}Compose project [$project_name] Packaged:${project_dir}${NC}"
				else
					echo -e "${RED}docker-compose.yml not found, skipping this container...${NC}"
				fi
			else
				# Ordinary container backup volume
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "Packing volume:$path"
					tar -czpf "${BACKUP_DIR}/${c}_$(basename $path).tar.gz" -C / "$(echo $path | sed 's/^\///')"
				done

				# port
				local PORT_ARGS=""
				mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[] | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$inspect_file" 2>/dev/null)
				for p in "${PORTS[@]}"; do PORT_ARGS+="-p $p "; done

				# environment variables
				local ENV_VARS=""
				mapfile -t ENVS < <(jq -r '.[0].Config.Env[] | @sh' "$inspect_file")
				for e in "${ENVS[@]}"; do ENV_VARS+="-e $e "; done

				# volume mapping
				local VOL_ARGS=""
				for path in $VOL_PATHS; do VOL_ARGS+="-v $path:$path "; done

				# mirror
				local IMAGE
				IMAGE=$(jq -r '.[0].Config.Image' "$inspect_file")

				echo -e "\n# Restore container:$c" >> "$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >> "$RESTORE_SCRIPT"
			fi
		done


		# Back up all files under /home/docker (excluding subdirectories)
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE}Back up files under /home/docker...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${GREEN}Files under /home/docker have been packaged to:${BACKUP_DIR}/home_docker_files.tar.gz${NC}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN}Backup completed:${BACKUP_DIR}${NC}"
		echo -e "${GREEN}Available restore scripts:${RESTORE_SCRIPT}${NC}"


	}

	# ----------------------------
	# reduction
	# ----------------------------
	restore_docker() {

		send_stats "Docker restore"
		read -e -p  "Please enter the backup directory to be restored:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}The backup directory does not exist${NC}"; return; }

		echo -e "${BLUE}Starting the restore operation...${NC}"

		install tar jq gzip
		install_docker

		# --------- Prioritize restoring Compose projects ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p  "Original path not found, please enter the restore directory path:" original_path

				# Check whether the container of the compose project is already running
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${YELLOW}Compose project [$project_name] Containers are already running, skip restore...${NC}"
					continue
				fi

				read -e -p  "Confirm to restore Compose project [$project_name] to path [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p  "Please enter a new restore path:" original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN}Compose project [$project_name] has been extracted to:$original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN}Compose project [$project_name] Restore completed!${NC}"
			fi
		done

		# --------- Continue to restore normal containers ---------
		echo -e "${BLUE}Check and restore normal Docker containers...${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${GREEN}Processing container:$container${NC}"

			# Check if the container already exists and is running
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}container [$container] already running, skipping restore...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && { echo -e "${RED}Mirror information not found, skip:$container${NC}"; continue; }

			# port mapping
			PORT_ARGS=""
			mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[]? | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$json")
			for p in "${PORTS[@]}"; do
				[[ -n "$p" ]] && PORT_ARGS="$PORT_ARGS -p $p"
			done

			# environment variables
			ENV_ARGS=""
			mapfile -t ENVS < <(jq -r '.[0].Config.Env[]' "$json")
			for e in "${ENVS[@]}"; do
				ENV_ARGS="$ENV_ARGS -e \"$e\""
			done

			# Volume mapping + volume data recovery
			VOL_ARGS=""
			mapfile -t VOLS < <(jq -r '.[0].Mounts[] | "\(.Source):\(.Destination)"' "$json")
			for v in "${VOLS[@]}"; do
				VOL_SRC=$(echo "$v" | cut -d':' -f1)
				VOL_DST=$(echo "$v" | cut -d':' -f2)
				mkdir -p "$VOL_SRC"
				VOL_ARGS="$VOL_ARGS -v $VOL_SRC:$VOL_DST"

				VOL_FILE="$BACKUP_DIR/${container}_$(basename $VOL_SRC).tar.gz"
				if [[ -f "$VOL_FILE" ]]; then
					echo "Recover volume data:$VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# Delete existing but not running containers
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}container [$container] exists but is not running, delete the old container...${NC}"
				docker rm -f "$container"
			fi

			# Start container
			echo "Execute the restore command: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW}No backup information for common containers found${NC}"

		# Restore files under /home/docker
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE}Restoring files under /home/docker...${NC}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${GREEN}Files under /home/docker have been restored${NC}"
		else
			echo -e "${YELLOW}The backup of the file under /home/docker was not found, skipping...${NC}"
		fi


	}


	# ----------------------------
	# migrate
	# ----------------------------
	migrate_docker() {
		send_stats "Docker migration"
		install jq
		read -e -p  "Please enter the backup directory to be migrated:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}The backup directory does not exist${NC}"; return; }

		read -e -p  "Target server IP:" TARGET_IP
		read -e -p  "Target server SSH username:" TARGET_USER
		read -e -p "Target server SSH port [default 22]:" TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW}Transferring backup...${NC}"
		if [[ -z "$TARGET_PASS" ]]; then
			# Log in using key
			scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no -r "$LATEST_TAR" "$TARGET_USER@$TARGET_IP:/tmp/"
		fi

	}

	# ----------------------------
	# Delete backup
	# ----------------------------
	delete_backup() {
		send_stats "Docker backup file deletion"
		read -e -p  "Please enter the backup directory to be deleted:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}The backup directory does not exist${NC}"; return; }
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN}Deleted backup:${BACKUP_DIR}${NC}"
	}

	# ----------------------------
	# Main menu
	# ----------------------------
	main_menu() {
		send_stats "Docker backup migration restore"
		while true; do
			clear
			echo "------------------------"
			echo -e "Docker backup/migration/restore tool"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. Back up docker project"
			echo -e "2. Migrate docker project"
			echo -e "3. Restore docker project"
			echo -e "4. Delete the backup file of the docker project"
			echo "------------------------"
			echo -e "0. Return to the previous menu"
			echo "------------------------"
			read -e -p  "Please select:" choice
			case $choice in
				1) backup_docker ;;
				2) migrate_docker ;;
				3) restore_docker ;;
				4) delete_backup ;;
				0) return ;;
				*) echo -e "${RED}Invalid option${NC}" ;;
			esac
		break_end
		done
	}

	main_menu
}





linux_docker() {

	while true; do
	  clear
	  # send_stats "docker management"
	  echo -e "Docker management"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Install and update the Docker environment${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}View Docker global status${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Docker container management${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker image management"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker network management"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker volume management"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Clean up useless docker containers and mirror network data volumes"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Change Docker source"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Edit daemon.json file"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Enable Docker-ipv6 access"
	  echo -e "${gl_kjlan}12.  ${gl_bai}Turn off Docker-ipv6 access"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Backup/migrate/restore Docker environment"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Uninstall the Docker environment"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

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

			  send_stats "docker global status"
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
			  echo -e "Docker volumes:${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Docker network:${gl_lv}$network_count${gl_bai}"
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
				  send_stats "Docker network management"
				  echo "Docker network list"
				  echo "------------------------------------------------------------"
				  docker network ls
				  echo ""

				  echo "------------------------------------------------------------"
				  container_ids=$(docker ps -q)
				  printf "%-25s %-25s %-25s\n" "Container name" "network name" "IP address"

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
				  echo "network operations"
				  echo "------------------------"
				  echo "1. Create a network"
				  echo "2. Join the network"
				  echo "3. Exit the network"
				  echo "4. Delete network"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "Create network"
						  read -e -p "Set new network name:" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "Join the network"
						  read -e -p "Add network name:" dockernetwork
						  read -e -p "Which containers join the network (please separate multiple container names with spaces):" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "Join the network"
						  read -e -p "Exit network name:" dockernetwork
						  read -e -p "Those containers exit the network (please separate multiple container names with spaces):" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "delete network"
						  read -e -p "Please enter the network name to be deleted:" dockernetwork
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
				  echo "Volume operations"
				  echo "------------------------"
				  echo "1. Create a new volume"
				  echo "2. Delete the specified volume"
				  echo "3. Delete all volumes"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "Create new volume"
						  read -e -p "Set new volume name:" dockerjuan
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
			  send_stats "Docker cleanup"
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
			  send_stats "Docker v6 on"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker v6 Close"
			  docker_ipv6_off
			  ;;

		  19)
			  docker_ssh_migration
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
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPT unlock status detection"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Region streaming media unlock test"
	  echo -e "${gl_kjlan}3.   ${gl_bai}yeahwu streaming media unlock detection"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP quality check script${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Network line speed test"
	  echo -e "${gl_kjlan}11.  ${gl_bai}besttrace three network backhaul delay routing test"
	  echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace triple network backhaul line test"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed triple network speed test"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace fast backhaul test script"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace specifies IP backhaul test script"
	  echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 three network line test"
	  echo -e "${gl_kjlan}17.  ${gl_bai}i-abc multi-function speed test script"
	  echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality network quality check script${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Hardware performance testing"
	  echo -e "${gl_kjlan}21.  ${gl_bai}yabs performance test"
	  echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU performance test script"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Comprehensive testing"
	  echo -e "${gl_kjlan}31.  ${gl_bai}bench performance test"
	  echo -e "${gl_kjlan}32.  ${gl_bai}spiritysdx fusion monster evaluation${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}nodequality fusion monster evaluation${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

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
			  send_stats "xykt_IP quality check script"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "besttrace triple network backhaul delay routing test"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "mtr_trace triple network backhaul line test"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "Superspeed triple network speed test"
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
			  echo "Reference IP list"
			  echo "------------------------"
			  echo "Beijing Telecom: 219.141.136.12"
			  echo "Beijing Unicom: 202.106.50.1"
			  echo "Beijing Mobile: 221.179.155.161"
			  echo "Shanghai Telecom: 202.96.209.133"
			  echo "Shanghai Unicom: 210.22.97.1"
			  echo "Shanghai Mobile: 211.136.112.200"
			  echo "Guangzhou Telecom: 58.60.188.222"
			  echo "Guangzhou China Unicom: 210.21.196.6"
			  echo "Guangzhou Mobile: 120.196.165.24"
			  echo "Chengdu Telecom: 61.139.2.69"
			  echo "Chengdu China Unicom: 119.6.6.6"
			  echo "Chengdu Mobile: 211.137.96.205"
			  echo "Hunan Telecom: 36.111.200.100"
			  echo "Hunan Unicom: 42.48.16.100"
			  echo "Hunan Mobile: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "Enter a specific IP:" testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "ludashi2020 three network line test"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc multifunctional speed test script"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "Network quality test script"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "yabs performance test"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "icu/gb5 CPU performance test script"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "bench performance test"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "spiritysdx fusion monster review"
			  clear
			  curl -L ${gh_proxy}gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  33)
			  send_stats "nodequality fusion monster evaluation"
			  clear
			  bash <(curl -sL https://run.NodeQuality.com)
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
	  echo -e "${gl_kjlan}2.   ${gl_bai}Uninstall active scripts from idle machines"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD reinstall system script"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Detective R startup script"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Enable ROOT password login mode"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPV6 recovery tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "Active script: CPU usage 10-20% Memory usage 20%"
			  read -e -p "Are you sure you want to install it? (Y/N):" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # Set default value
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # Prompts the user to enter the number of CPU cores and occupancy percentage. If the user presses Enter, the default value will be used.
				  read -e -p "Please enter the number of CPU cores [Default:$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "Please enter the CPU usage percentage range (e.g. 10-20) [Default:$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "Please enter the memory usage percentage [Default:$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "Please enter Speedtest interval time (seconds) [Default:$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # Run Docker container
				  docker run -d --name=lookbusy --restart=always \
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
		  echo -e "${gl_hong}Notice:${gl_bai}Reinstalling may cause loss of connection, so use with caution if you are worried. Reinstallation is expected to take 15 minutes, please back up your data in advance."
		  read -e -p "Are you sure you want to continue? (Y/N):" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "Please select the system you want to reinstall: 1. Debian12 | 2. Ubuntu20.04:" sys_choice

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

			  read -e -p "Please enter your password after reinstallation:" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "Oracle Cloud reinstall system script"
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
			  send_stats "Detective R startup script"
			  bash <(wget -qO- ${gh_proxy}github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh)
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "This function is provided by jhb, thank him!"
			  send_stats "ipv6 repair"
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
local output="${gl_lv}${cert_count}${gl_bai}"

local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
if [ -n "$dbrootpasswd" ]; then
	local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
fi

local db_output="${gl_lv}${db_count}${gl_bai}"


if command -v docker &>/dev/null; then
	if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_lv}Environment is installed${gl_bai}Site:$outputdatabase:$db_output"
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
	echo -e "${gl_huang}3.   ${gl_bai}Install Discuz Forum${gl_huang}4.   ${gl_bai}Install Kedao Cloud Desktop"
	echo -e "${gl_huang}5.   ${gl_bai}Install Apple CMS Movie and TV Station${gl_huang}6.   ${gl_bai}Install Unicorn Digital Card Network"
	echo -e "${gl_huang}7.   ${gl_bai}Install flarum forum website${gl_huang}8.   ${gl_bai}Install typecho lightweight blog website"
	echo -e "${gl_huang}9.   ${gl_bai}Install LinkStack sharing link platform${gl_huang}20.  ${gl_bai}Custom dynamic site"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}Only install nginx${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}site redirect"
	echo -e "${gl_huang}23.  ${gl_bai}Site reverse proxy-IP+port${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}Site reverse proxy-domain name"
	echo -e "${gl_huang}25.  ${gl_bai}Install Bitwarden Password Management Platform${gl_huang}26.  ${gl_bai}Install Halo Blog Site"
	echo -e "${gl_huang}27.  ${gl_bai}Install the AI ​​painting prompt word generator${gl_huang}28.  ${gl_bai}Site reverse proxy-load balancing"
	echo -e "${gl_huang}29.  ${gl_bai}Stream four-layer proxy forwarding${gl_huang}30.  ${gl_bai}Custom static site"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}Site data management${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}Back up site-wide data"
	echo -e "${gl_huang}33.  ${gl_bai}Scheduled remote backup${gl_huang}34.  ${gl_bai}Restore whole site data"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}Protect LDNMP environments${gl_huang}36.  ${gl_bai}Optimize LDNMP environment"
	echo -e "${gl_huang}37.  ${gl_bai}Update LDNMP environment${gl_huang}38.  ${gl_bai}Uninstall the LDNMP environment"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}Return to main menu"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "Please enter your choice:" sub_choice


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
	  webname="Discuz Forum"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  echo "Database address: mysql"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Table prefix: discuz_"


		;;

	  4)
	  clear
	  # Kedao cloud desktop
	  webname="Kedao cloud desktop"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  echo "Database address: mysql"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Database name:$dbname"
	  echo "redis host: redis"

		;;

	  5)
	  clear
	  # AppleCMS
	  webname="AppleCMS"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  echo "Database address: mysql"
	  echo "Database port: 3306"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Database prefix: mac_"
	  echo "------------------------"
	  echo "After successful installation, log in to the backend address"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # One-legged number card
	  webname="One-legged number card"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  echo "Database address: mysql"
	  echo "Database port: 3306"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo ""
	  echo "redis address: redis"
	  echo "redis password: not filled in by default"
	  echo "redis port: 6379"
	  echo ""
	  echo "Website url: https://$yuming"
	  echo "Backend login path: /admin"
	  echo "------------------------"
	  echo "Username: admin"
	  echo "Password: admin"
	  echo "------------------------"
	  echo "If a red error0 appears in the upper right corner when logging in, please use the following command:"
	  echo "I am also very angry about why the Unicorn Number Card is so troublesome and has such problems!"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # flarum forum
	  webname="flarum forum"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  echo "Database address: mysql"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
	  echo "Table prefix: flarum_"
	  echo "Administrator information can be set by oneself"

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
	  echo "Database address: mysql"
	  echo "Database port: 3306"
	  echo "Database name:$dbname"
	  echo "username:$dbuse"
	  echo "password:$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP dynamic site"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  echo -e "[${gl_huang}1/6${gl_bai}] Upload PHP source code"
	  echo "-------------"
	  echo "Currently, only source code packages in zip format are allowed to be uploaded. Please put the source code packages in /home/web/html/${yuming}under directory"
	  read -e -p "You can also enter the download link to download the source code package remotely. Press Enter directly to skip the remote download:" url_download

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

	  read -e -p "Please enter the path to index.php, similar to (/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] Please select PHP version"
	  echo "-------------"
	  read -e -p "1. php latest version | 2. php7.4:" pho_v
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
	  echo -e "[${gl_huang}4/6${gl_bai}] Install specified extension"
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
	  echo "Press any key to continue. You can set the site configuration in detail, such as pseudo-static content."
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] Database management"
	  echo "-------------"
	  read -e -p "1. I build a new site 2. I build an old site and have a database backup:" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "Database backup must be a compressed package ending in .gz. Please put it in the /home/ directory to support the import of Pagoda/1panel backup data."
			  read -e -p "You can also enter the download link to download the backup data remotely. Press Enter directly to skip the remote download:" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "Database imported table data"
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
	  webname="site redirect"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  read -e -p "Please enter the redirect domain name:" reverseproxy
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
		echo "IP+port has been blocked from accessing the service"
	  else
	  	ip_address
		block_container_port "$docker_name" "$ipv4_address"
	  fi

		;;

	  24)
	  clear
	  webname="Reverse proxy-domain name"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming
	  echo -e "Domain name format:${gl_huang}google.com${gl_bai}"
	  read -e -p "Please enter your reverse proxy domain name:" fandai_yuming
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
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
	  add_yuming

	  docker run -d --name halo --restart=always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2

	  duankou=8010
	  ldnmp_Proxy ${yuming} 127.0.0.1 $duankou

		;;

	  27)
	  clear
	  webname="AI painting prompt word generator"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  webname="static site"
	  send_stats "Install$webname"
	  echo "Start deployment$webname"
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
	  echo -e "[${gl_huang}1/2${gl_bai}] Upload static source code"
	  echo "-------------"
	  echo "Currently, only source code packages in zip format are allowed to be uploaded. Please put the source code packages in /home/web/html/${yuming}under directory"
	  read -e -p "You can also enter the download link to download the source code package remotely. Press Enter directly to skip the remote download:" url_download

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
		echo "Backup file created: /home/$backup_filename"
		read -e -p "Do you want to transfer backup data to a remote server? (Y/N):" choice
		case "$choice" in
		  [Yy])
			read -e -p "Please enter the remote server IP:" remote_ip
			read -e -p "Target server SSH port [default 22]:" TARGET_PORT
			local TARGET_PORT=${TARGET_PORT:-22}
			if [ -z "$remote_ip" ]; then
			  echo "Error: Please enter the remote server IP."
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
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
	  send_stats "Scheduled remote backup"
	  read -e -p "Enter the remote server IP:" useip
	  read -e -p "Enter the remote server password:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. Weekly backup 2. Daily backup"
	  read -e -p "Please enter your choice:" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "Select the day of the week for weekly backup (0-6, 0 represents Sunday):" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "Select daily backup time (hour, 0-23):" hour
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
	  read -e -p  "Press the Enter key to restore the latest backup, enter the backup file name to restore the specified backup, enter 0 to exit:" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # If the user does not enter a file name, the latest compressed package is used
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}Unzipping$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "No compressed package found."
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
		  echo "New version of component found"
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
		  read -e -p "Please enter your choice:" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "Please enter${ldnmp_pods}Version number (such as: 8.0 8.3 8.4 9.0) (press enter to get the latest version):" version
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
			  read -e -p "Please enter${ldnmp_pods}Version number (such as: 7.4 8.0 8.1 8.2 8.3) (press enter to get the latest version):" version
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
			  send_stats "renew$ldnmp_pods"
			  echo "renew${ldnmp_pods}Finish"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "Complete update of LDNMP environment"
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
		send_stats "Uninstall the LDNMP environment"
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
	  echo -e "application market"
	  echo -e "${gl_kjlan}-------------------------"

	  local app_numbers=$([ -f /home/docker/appno.txt ] && cat /home/docker/appno.txt || echo "")

	  # Set color with loop
	  for i in {1..150}; do
		  if echo "$app_numbers" | grep -q "^$i$"; then
			  declare "color$i=${gl_lv}"
		  else
			  declare "color$i=${gl_bai}"
		  fi
	  done

	  echo -e "${gl_kjlan}1.   ${color1}Pagoda panel official version${gl_kjlan}2.   ${color2}aaPanel Pagoda International Version"
	  echo -e "${gl_kjlan}3.   ${color3}1Panel new generation management panel${gl_kjlan}4.   ${color4}NginxProxyManager visualization panel"
	  echo -e "${gl_kjlan}5.   ${color5}OpenList multi-store file list program${gl_kjlan}6.   ${color6}Ubuntu Remote Desktop Web Edition"
	  echo -e "${gl_kjlan}7.   ${color7}Nezha Probe VPS Monitoring Panel${gl_kjlan}8.   ${color8}QB offline BT magnetic download panel"
	  echo -e "${gl_kjlan}9.   ${color9}Poste.io mail server program${gl_kjlan}10.  ${color10}RocketChat multi-person online chat system"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}11.  ${color11}ZenTao project management software${gl_kjlan}12.  ${color12}Qinglong panel scheduled task management platform"
	  echo -e "${gl_kjlan}13.  ${color13}Cloudreve network disk${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${color14}Simple picture bed picture management program"
	  echo -e "${gl_kjlan}15.  ${color15}emby multimedia management system${gl_kjlan}16.  ${color16}Speedtest speed test panel"
	  echo -e "${gl_kjlan}17.  ${color17}AdGuardHome removes adware${gl_kjlan}18.  ${color18}onlyofficeOnline office OFFICE"
	  echo -e "${gl_kjlan}19.  ${color19}Leichi WAF firewall panel${gl_kjlan}20.  ${color20}portainer container management panel"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}21.  ${color21}VScode web version${gl_kjlan}22.  ${color22}UptimeKuma monitoring tool"
	  echo -e "${gl_kjlan}23.  ${color23}Memos web memo${gl_kjlan}24.  ${color24}Webtop remote desktop web version${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${color25}Nextcloud network disk${gl_kjlan}26.  ${color26}QD-Today scheduled task management framework"
	  echo -e "${gl_kjlan}27.  ${color27}Dockge container stack management panel${gl_kjlan}28.  ${color28}LibreSpeed ​​speed test tool"
	  echo -e "${gl_kjlan}29.  ${color29}searxng aggregated search station${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${color30}PhotoPrism Private Album System"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}31.  ${color31}StirlingPDF Tools Collection${gl_kjlan}32.  ${color32}drawio free online charting software${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${color33}Sun-Panel Navigation Panel${gl_kjlan}34.  ${color34}Pingvin-Share file sharing platform"
	  echo -e "${gl_kjlan}35.  ${color35}Minimalist circle of friends${gl_kjlan}36.  ${color36}LobeChatAI chat aggregation website"
	  echo -e "${gl_kjlan}37.  ${color37}MyIP Toolbox${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${color38}Xiaoya alist family bucket"
	  echo -e "${gl_kjlan}39.  ${color39}Bililive live broadcast recording tool${gl_kjlan}40.  ${color40}webssh web version SSH connection tool"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}41.  ${color41}Mouse management panel${gl_kjlan}42.  ${color42}Nexterm remote connection tool"
	  echo -e "${gl_kjlan}43.  ${color43}RustDesk remote desktop (server)${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${color44}RustDesk remote desktop (relay)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${color45}Docker acceleration station${gl_kjlan}46.  ${color46}GitHub acceleration station${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${color47}Prometheus monitoring${gl_kjlan}48.  ${color48}Prometheus (host monitoring)"
	  echo -e "${gl_kjlan}49.  ${color49}Prometheus (container monitoring)${gl_kjlan}50.  ${color50}Replenishment monitoring tools"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}51.  ${color51}PVE open chick panel${gl_kjlan}52.  ${color52}DPanel container management panel"
	  echo -e "${gl_kjlan}53.  ${color53}llama3 chat AI large model${gl_kjlan}54.  ${color54}AMH host website building management panel"
	  echo -e "${gl_kjlan}55.  ${color55}FRP intranet penetration (server)${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${color56}FRP intranet penetration (client)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${color57}Deepseek chat AI large model${gl_kjlan}58.  ${color58}Dify large model knowledge base${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${color59}NewAPI large model asset management${gl_kjlan}60.  ${color60}JumpServer open source bastion machine"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}61.  ${color61}Online translation server${gl_kjlan}62.  ${color62}RAGFlow large model knowledge base"
	  echo -e "${gl_kjlan}63.  ${color63}OpenWebUI self-hosted AI platform${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${color64}it-tools toolbox"
	  echo -e "${gl_kjlan}65.  ${color65}n8n automated workflow platform${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${color66}yt-dlp video download tool"
	  echo -e "${gl_kjlan}67.  ${color67}ddns-go dynamic DNS management tool${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${color68}AllinSSL certificate management platform"
	  echo -e "${gl_kjlan}69.  ${color69}SFTPGo file transfer tool${gl_kjlan}70.  ${color70}AstrBot chatbot framework"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}71.  ${color71}Navidrome private music server${gl_kjlan}72.  ${color72}bitwarden password manager${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${color73}LibreTV Private Movies${gl_kjlan}74.  ${color74}MoonTV private movies"
	  echo -e "${gl_kjlan}75.  ${color75}Melody music wizard${gl_kjlan}76.  ${color76}Online DOS old games"
	  echo -e "${gl_kjlan}77.  ${color77}Thunder offline download tool${gl_kjlan}78.  ${color78}PandaWiki intelligent document management system"
	  echo -e "${gl_kjlan}79.  ${color79}Beszel server monitoring${gl_kjlan}80.  ${color80}linkwarden bookmark management"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}81.  ${color81}JitsiMeet video conference${gl_kjlan}82.  ${color82}gpt-load high-performance AI transparent proxy"
	  echo -e "${gl_kjlan}83.  ${color83}komari server monitoring tool${gl_kjlan}84.  ${color84}Wallos personal financial management tool"
	  echo -e "${gl_kjlan}85.  ${color85}immich picture video manager${gl_kjlan}86.  ${color86}jellyfin media management system"
	  echo -e "${gl_kjlan}87.  ${color87}SyncTV is a great tool for watching movies together${gl_kjlan}88.  ${color88}Owncast self-hosted live streaming platform"
	  echo -e "${gl_kjlan}89.  ${color89}FileCodeBox file express${gl_kjlan}90.  ${color90}matrix decentralized chat protocol"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}91.  ${color91}gitea private code repository${gl_kjlan}92.  ${color92}FileBrowser file manager"
	  echo -e "${gl_kjlan}93.  ${color93}Dufs minimalist static file server${gl_kjlan}94.  ${color94}Gopeed high-speed download tool"
	  echo -e "${gl_kjlan}95.  ${color95}paperless document management platform${gl_kjlan}96.  ${color96}2FAuth self-hosted two-step authenticator"
	  echo -e "${gl_kjlan}97.  ${color97}WireGuard networking (server)${gl_kjlan}98.  ${color98}WireGuard networking (client)"
	  echo -e "${gl_kjlan}99.  ${color99}DSM Synology Virtual Machine${gl_kjlan}100. ${color100}Syncthing peer-to-peer file synchronization tool"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}101. ${color101}AI video generation tool${gl_kjlan}102. ${color102}VoceChat multi-person online chat system"
	  echo -e "${gl_kjlan}103. ${color103}Umami website statistics tool${gl_kjlan}104. ${color104}Stream four-layer proxy forwarding tool"
	  echo -e "${gl_kjlan}105. ${color105}Siyuan Notes${gl_kjlan}106. ${color106}Drawnix open source whiteboard tool"
	  echo -e "${gl_kjlan}107. ${color107}PanSou network disk search${gl_kjlan}108. ${color108}LangBot chatbot"
	  echo -e "${gl_kjlan}109. ${color109}ZFile online network disk${gl_kjlan}110. ${color110}Karakeep bookmark management"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}111. ${color111}Multi-format file conversion tool${gl_kjlan}112. ${color112}Lucky large intranet penetration tool"
	  echo -e "${gl_kjlan}113. ${color113}Firefox browser"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}Third-party application list"
  	  echo -e "${gl_kjlan}Want your app to appear here? Check out the developer guide:${gl_huang}https://dev.kejilion.sh/${gl_bai}"

	  for f in "$HOME"/apps/*.conf; do
		  [ -e "$f" ] || continue
		  local base_name=$(basename "$f" .conf)
		  # Get app description
		  local app_text=$(grep "app_text=" "$f" | cut -d'=' -f2 | tr -d '"' | tr -d "'")

		  # Check installation status (match ID in appno.txt)
		  # It is assumed here that what is recorded in appno.txt is base_name (i.e. file name)
		  if echo "$app_numbers" | grep -q "^$base_name$"; then
			  # If installed: show base_name - description [Installed] (green)
			  echo -e "${gl_kjlan}$base_name${gl_bai} - ${gl_lv}$app_text[Installed]${gl_bai}"
		  else
			  # If not installed: display normally
			  echo -e "${gl_kjlan}$base_name${gl_bai} - $app_text"
		  fi
	  done



	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}b.   ${gl_bai}Back up all application data${gl_kjlan}r.   ${gl_bai}Restore all app data"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice
	fi

	case $sub_choice in
	  1|bt|baota)
		local app_id="1"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="pagoda panel"
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

		local docker_describe="An Nginx reverse proxy tool panel that does not support adding domain name access."
		local docker_url="Official website introduction: https://nginxproxymanager.com/"
		local docker_use="echo \"Initial username: admin@example.com\""
		local docker_passwd="echo \"Initial password: changeme\""
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


		local docker_describe="A file listing program that supports multiple storages, web browsing and WebDAV, powered by gin and Solidjs"
		local docker_url="Official website introduction: https://github.com/OpenListTeam/OpenList"
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

			read -e -p "Set login username:" admin
			read -e -p "Set login user password:" admin_password
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


		local docker_describe="webtop is an Ubuntu-based container. If the IP cannot be accessed, please add a domain name for access."
		local docker_url="Official website introduction: https://docs.linuxserver.io/images/docker-webtop/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app


		  ;;
	  7|nezha)
		clear
		send_stats "Build Nezha"

		local app_id="7"
		local docker_name="nezha-dashboard"
		local docker_port=8008
		while true; do
			check_docker_app
			check_docker_image_update $docker_name
			clear
			echo -e "Nezha monitoring$check_docker $update_status"
			echo "Open source, lightweight, easy-to-use server monitoring and operation and maintenance tool"
			echo "Official website construction documentation: https://nezha.wiki/guide/dashboard.html"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
				check_docker_app_ip
			fi
			echo ""
			echo "------------------------"
			echo "1. Use"
			echo "------------------------"
			echo "0. Return to the previous menu"
			echo "------------------------"
			read -e -p "Enter your selection:" choice

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

		local docker_describe="qbittorrent offline BT magnetic download service"
		local docker_url="Official website introduction: https://hub.docker.com/r/linuxserver/qbittorrent"
		local docker_use="sleep 3"
		local docker_passwd="docker logs qbittorrent"
		local app_size="1"
		docker_app

		  ;;

	  9|mail)
		send_stats "Build a post office"
		clear
		install telnet
		local app_id="9"
		local docker_name=“mailserver”
		while true; do
			check_docker_app
			check_docker_image_update $docker_name

			clear
			echo -e "postal service$check_docker $update_status"
			echo "poste.io is an open source mail server solution,"
			echo "Video introduction: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

			echo ""
			echo "Port detection"
			port=25
			timeout=3
			if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
			  echo -e "${gl_lv}port$portCurrently available${gl_bai}"
			else
			  echo -e "${gl_hong}port$portCurrently unavailable${gl_bai}"
			fi
			echo ""

			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				yuming=$(cat /home/docker/mail.txt)
				echo "Visit address:"
				echo "https://$yuming"
			fi

			echo "------------------------"
			echo "1. Install 2. Update 3. Uninstall"
			echo "------------------------"
			echo "0. Return to the previous menu"
			echo "------------------------"
			read -e -p "Enter your selection:" choice

			case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "Please set the email domain name, for example mail.yuming.com:" yuming
					mkdir -p /home/docker
					echo "$yuming" > /home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "First parse these DNS records"
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


					add_app_id

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


					add_app_id

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

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "App has been uninstalled"
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
		local app_name="Rocket.Chat chat system"
		local app_text="Rocket.Chat is an open source team communication platform that supports real-time chat, audio and video calls, file sharing and other functions."
		local app_url="Official introduction: https://www.rocket.chat/"
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
			echo "Installation completed"
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
			echo "App has been uninstalled"
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

		local docker_describe="ZenTao is a universal project management software"
		local docker_url="Official website introduction: https://www.zentao.net/"
		local docker_use="echo \"Initial username: admin\""
		local docker_passwd="echo \"Initial password: 123456\""
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

		local docker_describe="Qinglong Panel is a scheduled task management platform"
		local docker_url="Official website introduction:${gh_proxy}github.com/whyour/qinglong"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  13|cloudreve)

		local app_id="13"
		local app_name="cloudreve network disk"
		local app_text="cloudreve is a network disk system that supports multiple cloud storages"
		local app_url="Video introduction: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
			echo "Installation completed"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			cd /home/docker/cloud/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			rm -rf /home/docker/cloud
			echo "App has been uninstalled"
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

		local docker_describe="Simple drawing bed is a simple drawing bed program"
		local docker_url="Official website introduction:${gh_proxy}github.com/icret/EasyImages2.0"
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


		local docker_describe="emby is a master-slave architecture media server software that can be used to organize video and audio on the server and stream audio and video to client devices"
		local docker_url="Official website introduction: https://emby.media/"
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

		local docker_describe="Speedtest speed measurement panel is a VPS network speed test tool with multiple test functions and can also monitor VPS inbound and outbound traffic in real time."
		local docker_url="Official website introduction:${gh_proxy}github.com/wikihost-opensource/als"
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


		local docker_describe="AdGuardHome is a network-wide ad blocking and anti-tracking software that will be more than just a DNS server in the future."
		local docker_url="Official website introduction: https://hub.docker.com/r/adguard/adguardhome"
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

		local docker_describe="onlyoffice is an open source online office tool, so powerful!"
		local docker_url="Official website introduction: https://www.onlyoffice.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app

		  ;;

	  19|safeline)
		send_stats "Build a thunder pool"

		local app_id="19"
		local docker_name=safeline-mgt
		local docker_port=9443
		while true; do
			check_docker_app
			clear
			echo -e "Thunder pool service$check_docker"
			echo "Leichi is a WAF site firewall program panel developed by Changting Technology, which can reverse the site for automated defense."
			echo "Video introduction: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				check_docker_app_ip
			fi
			echo ""

			echo "------------------------"
			echo "1. Install 2. Update 3. Reset password 4. Uninstall"
			echo "------------------------"
			echo "0. Return to the previous menu"
			echo "------------------------"
			read -e -p "Enter your selection:" choice

			case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "The Leichi WAF panel has been installed"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "The Leichi WAF panel has been updated"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "If you are in the default installation directory, the project has been uninstalled now. If you customize the installation directory, you need to go to the installation directory and execute it yourself:"
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


		local docker_describe="portainer is a lightweight docker container management panel"
		local docker_url="Official website introduction: https://www.portainer.io/"
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


		local docker_describe="VScode is a powerful online code writing tool"
		local docker_url="Official website introduction:${gh_proxy}github.com/coder/code-server"
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


		local docker_describe="Uptime Kuma Easy-to-use self-hosted monitoring tool"
		local docker_url="Official website introduction:${gh_proxy}github.com/louislam/uptime-kuma"
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

		local docker_describe="Memos is a lightweight, self-hosted memo center"
		local docker_url="Official website introduction:${gh_proxy}github.com/usememos/memos"
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

			read -e -p "Set login username:" admin
			read -e -p "Set login user password:" admin_password
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


		local docker_describe="webtop is based on the Chinese version of Alpine container. If the IP cannot be accessed, please add a domain name for access."
		local docker_url="Official website introduction: https://docs.linuxserver.io/images/docker-webtop/"
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

		local docker_describe="With over 400,000 deployments, Nextcloud is the most popular local content collaboration platform you can download"
		local docker_url="Official website introduction: https://nextcloud.com/"
		local docker_use="echo \"Account: nextcloud Password:$rootpasswd\""
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

		local docker_describe="QD-Today is an HTTP request scheduled task automatic execution framework"
		local docker_url="Official website introduction: https://qd-today.github.io/qd/zh_CN/"
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

		local docker_describe="dockge is a visual docker-compose container management panel"
		local docker_url="Official website introduction:${gh_proxy}github.com/louislam/dockge"
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

		local docker_describe="librespeed is a lightweight speed testing tool implemented in Javascript that can be used out of the box"
		local docker_url="Official website introduction:${gh_proxy}github.com/librespeed/speedtest"
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

		local docker_describe="searxng is a private and private search engine site"
		local docker_url="Official website introduction: https://hub.docker.com/r/alandoyle/searxng"
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


		local docker_describe="Photoprism is a very powerful private photo album system"
		local docker_url="Official website introduction: https://www.photoprism.app/"
		local docker_use="echo \"Account: admin Password:$rootpasswd\""
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

		local docker_describe="This is a powerful locally hosted web-based PDF manipulation tool using docker that allows you to perform various operations on PDF files such as split merge, convert, reorganize, add images, rotate, compress, etc."
		local docker_url="Official website introduction:${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
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


		local docker_describe="This is a powerful charting software. You can draw mind maps, topology diagrams, and flow charts."
		local docker_url="Official website introduction: https://www.drawio.com/"
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

		local docker_describe="Sun-Panel server, NAS navigation panel, Homepage, browser homepage"
		local docker_url="Official website introduction: https://doc.sun-panel.top/zh_cn/"
		local docker_use="echo \"Account: admin@sun.cc Password: 12345678\""
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

		local docker_describe="Pingvin Share is a self-buildable file sharing platform and an alternative to WeTransfer"
		local docker_url="Official website introduction:${gh_proxy}github.com/stonith404/pingvin-share"
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


		local docker_describe="Minimalist Moments, high imitation WeChat Moments, record your wonderful life"
		local docker_url="Official website introduction:${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
		local docker_use="echo \"Account: admin Password: a123456\""
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

		local docker_describe="LobeChat aggregates the mainstream AI large models on the market, ChatGPT/Claude/Gemini/Groq/Ollama"
		local docker_url="Official website introduction:${gh_proxy}github.com/lobehub/lobe-chat"
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


		local docker_describe="It is a multifunctional IP toolbox that allows you to view your own IP information and connectivity, and displays it using a web panel."
		local docker_url="Official website introduction:${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  38|xiaoya)
		send_stats "Xiaoya family bucket"
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

		local docker_describe="Bililive-go is a live broadcast recording tool that supports multiple live broadcast platforms"
		local docker_url="Official website introduction:${gh_proxy}github.com/hr3lxphr6j/bililive-go"
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

		local docker_describe="Simple online ssh connection tool and sftp tool"
		local docker_url="Official website introduction:${gh_proxy}github.com/Jrohy/webssh"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  41|haozi)

		local app_id="41"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="mouse panel"
		local panelurl="Official address:${gh_proxy}github.com/TheTNB/panel"

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

		local docker_describe="nexterm is a powerful online SSH/VNC/RDP connection tool."
		local docker_url="Official website introduction:${gh_proxy}github.com/gnmyt/Nexterm"
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


		local docker_describe="Rustdesk's open source remote desktop (server) is similar to its own Sunflower private server."
		local docker_url="Official website introduction: https://rustdesk.com/zh-cn/"
		local docker_use="docker logs hbbs"
		local docker_passwd="echo \"Record your IP and key, which will be used in the remote desktop client. Go to option 44 to install the relay!\""
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

		local docker_describe="Rustdesk's open source remote desktop (relay) is similar to its own Sunflower private server."
		local docker_url="Official website introduction: https://rustdesk.com/zh-cn/"
		local docker_use="echo \"Go to the official website to download the remote desktop client: https://rustdesk.com/zh-cn/\""
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

		local docker_describe="Docker Registry is a service for storing and distributing Docker images."
		local docker_url="Official website introduction: https://hub.docker.com/_/registry"
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

		local docker_describe="GHProxy implemented using Go is used to accelerate the pulling of Github repositories in some areas."
		local docker_url="Official website introduction: https://github.com/WJQSERVER-STUDIO/ghproxy"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  47|prometheus|grafana)

		local app_id="47"
		local app_name="Prometheus monitoring"
		local app_text="Prometheus+Grafana enterprise-level monitoring system"
		local app_url="Official website introduction: https://prometheus.io"
		local docker_name="grafana"
		local docker_port="8047"
		local app_size="2"

		docker_app_install() {
			prometheus_install
			clear
			ip_address
			echo "Installation completed"
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
			echo "App has been uninstalled"
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

		local docker_describe="This is a Prometheus host data collection component, please deploy it on the monitored host."
		local docker_url="Official website introduction: https://github.com/prometheus/node_exporter"
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

		local docker_describe="This is a Prometheus container data collection component, please deploy it on the monitored host."
		local docker_url="Official website introduction: https://github.com/google/cadvisor"
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

		local docker_describe="This is a small tool for website change detection, replenishment monitoring and notification"
		local docker_url="Official website introduction: https://github.com/dgtlmoon/changedetection.io"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  51|pve)
		clear
		send_stats "PVE open chick"
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

		local docker_describe="Docker visual panel system provides complete docker management functions."
		local docker_url="Official website introduction: https://github.com/donknap/dpanel"
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

		local docker_describe="OpenWebUI is a large language model web page framework that is connected to the new llama3 large language model."
		local docker_url="Official website introduction: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run llama3.2:1b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;

	  54|amh)

		local app_id="54"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="AMH panel"
		local panelurl="Official address: https://amh.sh/index.htm?amh"

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

		local docker_describe="OpenWebUI is a large language model web page framework that is connected to the new DeepSeek R1 large language model."
		local docker_url="Official website introduction: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;


	  58|dify)
		local app_id="58"
		local app_name="DifyKnowledge Base"
		local app_text="It is an open source large language model (LLM) application development platform. Self-hosted training data for AI generation"
		local app_url="Official website: https://docs.dify.ai/zh-hans"
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
			echo "Installation completed"
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
			echo "App has been uninstalled"
		}

		docker_app_plus

		  ;;

	  59|new-api)
		local app_id="59"
		local app_name="NewAPI"
		local app_text="New generation of large model gateway and AI asset management system"
		local app_url="Official website: https://github.com/Calcium-Ion/new-api"
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
			echo "Installation completed"
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
			echo "Installation completed"
			check_docker_app_ip

		}

		docker_app_uninstall() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			rm -rf /home/docker/new-api
			echo "App has been uninstalled"
		}

		docker_app_plus

		  ;;


	  60|jms)

		local app_id="60"
		local app_name="JumpServer open source bastion machine"
		local app_text="It is an open source privileged access management (PAM) tool. This program occupies port 80 and does not support adding domain names for access."
		local app_url="Official introduction: https://github.com/jumpserver/jumpserver"
		local docker_name="jms_web"
		local docker_port="80"
		local app_size="2"

		docker_app_install() {
			curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
			clear
			echo "Installation completed"
			check_docker_app_ip
			echo "Initial username: admin"
			echo "Initial password: ChangeMe"
		}


		docker_app_update() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh upgrade
			echo "App has been updated"
		}


		docker_app_uninstall() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh uninstall
			cd /opt
			rm -rf jumpserver-installer*/
			rm -rf jumpserver
			echo "App has been uninstalled"
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

		local docker_describe="Free open source machine translation API, fully self-hosted, and its translation engine is powered by the open source Argos Translate library."
		local docker_url="Official website introduction: https://github.com/LibreTranslate/LibreTranslate"
		local docker_use=""
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;



	  62|ragflow)
		local app_id="62"
		local app_name="RAGFlow knowledge base"
		local app_text="Open source RAG (Retrieval Augmented Generation) engine based on deep document understanding"
		local app_url="Official website: https://github.com/infiniflow/ragflow"
		local docker_name="ragflow-server"
		local docker_port="8062"
		local app_size="8"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
			sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
			docker compose up -d
			clear
			echo "Installation completed"
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
			echo "App has been uninstalled"
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

		local docker_describe="OpenWebUI is a large language model web page framework, the official simplified version supports API access to all major models."
		local docker_url="Official website introduction: https://github.com/open-webui/open-webui"
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

		local docker_describe="Very useful tool for developers and IT workers"
		local docker_url="Official website introduction: https://github.com/CorentinTh/it-tools"
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

		local docker_describe="It is a powerful automated workflow platform"
		local docker_url="Official website introduction: https://github.com/n8n-io/n8n"
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

		local docker_describe="Automatically update your public IP (IPv4/IPv6) to major DNS service providers in real time to achieve dynamic domain name resolution."
		local docker_url="Official website introduction: https://github.com/jeessy2/ddns-go"
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

		local docker_describe="Open source free SSL certificate automation management platform"
		local docker_url="Official website introduction: https://allinssl.com"
		local docker_use="echo \"Security entrance: /allinssl\""
		local docker_passwd="echo \"Username: allinssl Password: allinssldocker\""
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

		local docker_describe="Open source free anytime, anywhere SFTP FTP WebDAV file transfer tool"
		local docker_url="Official website introduction: https://sftpgo.com/"
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

		local docker_describe="Open source AI chatbot framework, supporting WeChat, QQ, and TG access to large AI models"
		local docker_url="Official website introduction: https://astrbot.app/"
		local docker_use="echo \"Username: astrbot Password: astrbot\""
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

		local docker_describe="It is a lightweight, high-performance music streaming server"
		local docker_url="Official website introduction: https://www.navidrome.org/"
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

		local docker_describe="A password manager that puts you in control of your data"
		local docker_url="Official website introduction: https://bitwarden.com/"
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

			read -e -p "Set LibreTV login password:" app_passwd

			docker run -d \
			  --name libretv \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -e PASSWORD=${app_passwd} \
			  bestzwei/libretv:latest

		}

		local docker_describe="Free online video search and viewing platform"
		local docker_url="Official website introduction: https://github.com/LibreSpark/LibreTV"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  74|moontv)

		local app_id="74"

		local app_name="moontv private film and television"
		local app_text="Free online video search and viewing platform"
		local app_url="Video introduction: https://github.com/MoonTechLab/LunaTV"
		local docker_name="moontv-core"
		local docker_port="8074"
		local app_size="2"

		docker_app_install() {
			read -e -p "Set login username:" admin
			read -e -p "Set login user password:" admin_password
			read -e -p "Enter authorization code:" shouquanma


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
			echo "Installation completed"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			cd /home/docker/moontv/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			rm -rf /home/docker/moontv
			echo "App has been uninstalled"
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

		local docker_describe="Your music wizard, designed to help you better manage your music."
		local docker_url="Official website introduction: https://github.com/foamzou/melody"
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

		local docker_describe="It is a Chinese DOS game collection website"
		local docker_url="Official website introduction: https://github.com/rwv/chinese-dos-games"
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

			read -e -p "Set login username:" app_use
			read -e -p "Set login password:" app_passwd

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

		local docker_describe="Xunlei, your offline high-speed BT magnetic download tool"
		local docker_url="Official website introduction: https://github.com/cnk3x/xunlei"
		local docker_use="echo \"Log in to Xunlei with your mobile phone and enter the invitation code. Invitation code: Xunlei Niutong\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  78|PandaWiki)

		local app_id="78"
		local app_name="PandaWiki"
		local app_text="PandaWiki is an open source intelligent document management system driven by AI large models. It is strongly recommended not to customize port deployment."
		local app_url="Official introduction: https://github.com/chaitin/PandaWiki"
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

		local docker_describe="Beszel is lightweight and easy-to-use server monitoring"
		local docker_url="Official website introduction: https://beszel.dev/zh/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  80|linkwarden)

		  local app_id="80"
		  local app_name="linkwarden bookmark management"
		  local app_text="An open source, self-hosted bookmark management platform that supports tagging, search, and team collaboration."
		  local app_url="Official website: https://linkwarden.app/"
		  local docker_name="linkwarden-linkwarden-1"
		  local docker_port="8080"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl
			  mkdir -p /home/docker/linkwarden && cd /home/docker/linkwarden

			  # Download the official docker-compose and env files
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env"

			  # Generate random keys and passwords
			  local ADMIN_EMAIL="admin@example.com"
			  local ADMIN_PASSWORD=$(openssl rand -hex 8)

			  sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=http://localhost:${docker_port}/api/v1/auth|g" .env
			  sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$(openssl rand -hex 32)|g" .env
			  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 16)|g" .env
			  sed -i "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$(openssl rand -hex 32)|g" .env

			  # Add administrator account information
			  echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >> .env
			  echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> .env

			  sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

			  # Start container
			  docker compose up -d

			  clear
			  echo "Installation completed"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
			  cd /home/docker/linkwarden && docker compose down --rmi all
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env.new"

			  # Keep original variables
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
			  echo "App has been uninstalled"
		  }

		  docker_app_plus

		  ;;



	  81|jitsi)
		  local app_id="81"
		  local app_name="JitsiMeet video conference"
		  local app_text="An open source secure video conferencing solution that supports multi-person online conferencing, screen sharing and encrypted communication."
		  local app_url="Official website: https://jitsi.org/"
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
			  echo "App has been uninstalled"
		  }

		  docker_app_plus

		  ;;



	  82|gpt-load)

		local app_id="82"
		local docker_name="gpt-load"
		local docker_img="tbphp/gpt-load:latest"
		local docker_port=8082

		docker_rum() {

			read -e -p "set up${docker_name}Login key (sk-a combination of letters and numbers starting with) such as: sk-159kejilionyyds163:" app_passwd

			mkdir -p /home/docker/gpt-load && \
			docker run -d --name gpt-load \
				-p ${docker_port}:3001 \
				-e AUTH_KEY=${app_passwd} \
				-v "/home/docker/gpt-load/data":/app/data \
				tbphp/gpt-load:latest

		}

		local docker_describe="High-performance AI interface transparent proxy service"
		local docker_url="Official website introduction: https://www.gpt-load.com/"
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

		local docker_describe="Lightweight self-hosted server monitoring tool"
		local docker_url="Official website introduction: https://github.com/komari-monitor/komari/tree/main"
		local docker_use="echo \"Default account: admin Default password: 1212156\""
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

		local docker_describe="Open source personal subscription tracker for financial management"
		local docker_url="Official website introduction: https://github.com/ellite/Wallos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  85|immich)

		  local app_id="85"
		  local app_name="immich picture video manager"
		  local app_text="High-performance self-hosted photo and video management solution."
		  local app_url="Official website introduction: https://github.com/immich-app/immich"
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
			  echo "Installation completed"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
		  }

		  docker_app_uninstall() {
			  cd /home/docker/${docker_name} && docker compose down --rmi all
			  rm -rf /home/docker/${docker_name}
			  echo "App has been uninstalled"
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

		local docker_describe="Is an open source media server software"
		local docker_url="Official website introduction: https://jellyfin.org/"
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

		local docker_describe="A program to watch movies and live broadcasts together remotely. It provides simultaneous viewing, live broadcast, chat and other functions"
		local docker_url="Official website introduction: https://github.com/synctv-org/synctv"
		local docker_use="echo \"Initial account and password: root. Please change the login password in time after logging in\""
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

		local docker_describe="Open source, free self-built live broadcast platform"
		local docker_url="Official website introduction: https://owncast.online"
		local docker_use="echo \"The access address is followed by /admin to access the administrator page\""
		local docker_passwd="echo \"Initial account: admin Initial password: abc123 Please change the login password in time after logging in\""
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

		local docker_describe="Share texts and files with anonymous passwords, and pick up files like express delivery"
		local docker_url="Official website introduction: https://github.com/vastsa/FileCodeBox"
		local docker_use="echo \"The access address is followed by /#/admin to access the administrator page\""
		local docker_passwd="echo \"Administrator password: FileCodeBox2023\""
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

			echo "Create an initial user or administrator. Please set the following username and password and whether you are an administrator."
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

		local docker_describe="Matrix is ​​a decentralized chat protocol"
		local docker_url="Official website introduction: https://matrix.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  91|gitea)

		local app_id="91"

		local app_name="gitea private code repository"
		local app_text="A free new generation code hosting platform that provides an experience close to GitHub."
		local app_url="Video introduction: https://github.com/go-gitea/gitea"
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
			echo "Installation completed"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			cd /home/docker/gitea/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			rm -rf /home/docker/gitea
			echo "App has been uninstalled"
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

		local docker_describe="Is a web-based file manager"
		local docker_url="Official website introduction: https://filebrowser.org/"
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

		local docker_describe="Minimalist static file server, supports upload and download"
		local docker_url="Official website introduction: https://github.com/sigoden/dufs"
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

			read -e -p "Set login username:" app_use
			read -e -p "Set login password:" app_passwd

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}/downloads:/app/Downloads \
			  -v /home/docker/${docker_name}/storage:/app/storage \
			  -p ${docker_port}:9999 \
			  ${docker_img} -u ${app_use} -p ${app_passwd}

		}

		local docker_describe="Distributed high-speed download tool, supporting multiple protocols"
		local docker_url="Official website introduction: https://github.com/GopeedLab/gopeed"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;



	  95|paperless)

		local app_id="95"

		local app_name="paperless document management platform"
		local app_text="An open source electronic document management system, its main purpose is to digitize and manage your paper documents."
		local app_url="Video introduction: https://docs.paperless-ngx.com/"
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
			echo "Installation completed"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			rm -rf /home/docker/paperless
			echo "App has been uninstalled"
		}

		docker_app_plus

		  ;;



	  96|2fauth)

		local app_id="96"

		local app_name="2FAuth self-hosted two-step authenticator"
		local app_text="Self-hosted two-factor authentication (2FA) account management and verification code generation tool."
		local app_url="Official website: https://github.com/Bubka/2FAuth"
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
			echo "Installation completed"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			rm -rf /home/docker/2fauth
			echo "App has been uninstalled"
		}

		docker_app_plus

		  ;;



	97|wgs)

		local app_id="97"
		local docker_name="wireguard"
		local docker_img="lscr.io/linuxserver/wireguard:latest"
		local docker_port=8097

		docker_rum() {

		read -e -p  "Please enter the number of clients in the network (default 5):" COUNT
		COUNT=${COUNT:-5}
		read -e -p  "Please enter the WireGuard network segment (default 10.13.13.0):" NETWORK
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
		echo -e "${gl_huang}All client QR code configurations:${gl_bai}"
		docker exec wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
		sleep 2
		echo
		echo -e "${gl_huang}All client configuration codes:${gl_bai}"
		docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
		sleep 2
		echo -e "${gl_lv}${COUNT}Configure all outputs for each client. The usage method is as follows:${gl_bai}"
		echo -e "${gl_lv}1. Download the wg APP on your mobile phone and scan the QR code above to quickly connect to the Internet.${gl_bai}"
		echo -e "${gl_lv}2. Download the client for Windows and copy the configuration code to connect to the network.${gl_bai}"
		echo -e "${gl_lv}3. Use a script to deploy the WG client on Linux and copy the configuration code to connect to the network.${gl_bai}"
		echo -e "${gl_lv}Official client download method: https://www.wireguard.com/install/${gl_bai}"
		break_end

		}

		local docker_describe="Modern, high-performance virtual private network tools"
		local docker_url="Official website introduction: https://www.wireguard.com/"
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

			# Create directory if it does not exist
			mkdir -p "$(dirname "$CONFIG_FILE")"

			echo "Please paste your client configuration and press Enter twice to save:"

			# initialize variables
			input=""
			empty_line_count=0

			# Read user input line by line
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

			# Write configuration file
			echo "$input" > "$CONFIG_FILE"

			echo "Client configuration saved to$CONFIG_FILE"

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

		local docker_describe="Modern, high-performance virtual private network tools"
		local docker_url="Official website introduction: https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  99|dsm)

		local app_id="99"

		local app_name="dsm synology virtual machine"
		local app_text="Virtual DSM in Docker container"
		local app_url="Official website: https://github.com/vdsm/virtual-dsm"
		local docker_name="dsm"
		local docker_port="8099"
		local app_size="16"

		docker_app_install() {

			read -e -p "Set the number of CPU cores (default 2):" CPU_CORES
			local CPU_CORES=${CPU_CORES:-2}

			read -e -p "Set memory size (default 4G):" RAM_SIZE
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
			echo "Installation completed"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			rm -rf /home/docker/dsm
			echo "App has been uninstalled"
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

		local docker_describe="An open source peer-to-peer file synchronization tool, similar to Dropbox and Resilio Sync, but completely decentralized."
		local docker_url="Official website introduction: https://github.com/syncthing/syncthing"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  101|moneyprinterturbo)
		local app_id="101"
		local app_name="AI video generation tool"
		local app_text="MoneyPrinterTurbo is a tool that uses AI large models to synthesize high-definition short videos"
		local app_url="Official website: https://github.com/harry0703/MoneyPrinterTurbo"
		local docker_name="moneyprinterturbo"
		local docker_port="8101"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/harry0703/MoneyPrinterTurbo.git && cd MoneyPrinterTurbo/
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml

			docker compose up -d
			clear
			echo "Installation completed"
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
			echo "App has been uninstalled"
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

		local docker_describe="It is a personal cloud social media chat service that supports independent deployment."
		local docker_url="Official website introduction: https://github.com/Privoce/vocechat-web"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  103|umami)
		local app_id="103"
		local app_name="Umami website statistics tool"
		local app_text="Open source, lightweight, privacy-friendly website analysis tool, similar to Google Analytics."
		local app_url="Official website: https://github.com/umami-software/umami"
		local docker_name="umami-umami-1"
		local docker_port="8103"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/umami-software/umami.git && cd umami
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/umami/docker-compose.yml

			docker compose up -d
			clear
			echo "Installation completed"
			check_docker_app_ip
			echo "Initial username: admin"
			echo "Initial password: umami"
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
			echo "App has been uninstalled"
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

			read -e -p "Set login password:" app_passwd

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

		local docker_describe="Siyuan Notes is a privacy-first knowledge management system"
		local docker_url="Official website introduction: https://github.com/siyuan-note/siyuan"
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

		local docker_describe="It is a powerful open source whiteboard tool that integrates mind maps, flow charts, etc."
		local docker_url="Official website introduction: https://github.com/plait-board/drawnix"
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

		local docker_describe="PanSou is a high-performance network disk resource search API service."
		local docker_url="Official website introduction: https://github.com/fish2018/pansou"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;




	  108|langbot)
		local app_id="108"
		local app_name="LangBot chatbot"
		local app_text="It is an open source large language model native instant messaging robot development platform."
		local app_url="Official website: https://github.com/langbot-app/LangBot"
		local docker_name="langbot_plugin_runtime"
		local docker_port="8108"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/langbot-app/LangBot && cd LangBot/docker
			sed -i "s/5300:5300/${docker_port}:5300/g" /home/docker/LangBot/docker/docker-compose.yaml

			docker compose up -d
			clear
			echo "Installation completed"
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
			echo "App has been uninstalled"
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

		local docker_describe="It is an online network disk program suitable for individuals or small teams."
		local docker_url="Official website introduction: https://github.com/zfile-dev/zfile"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  110|karakeep)
		local app_id="110"
		local app_name="karakeep bookmark management"
		local app_text="is a self-hosted bookmarking app with artificial intelligence capabilities designed for data hoarders."
		local app_url="Official website: https://github.com/karakeep-app/karakeep"
		local docker_name="docker-web-1"
		local docker_port="8110"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/karakeep-app/karakeep.git && cd karakeep/docker && cp .env.sample .env
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/karakeep/docker/docker-compose.yml

			docker compose up -d
			clear
			echo "Installation completed"
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
			echo "App has been uninstalled"
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

		local docker_describe="It is a powerful multi-format file conversion tool (supports documents, images, audio and video, etc.) It is strongly recommended to add domain name access"
		local docker_url="Project address: https://github.com/c4illin/ConvertX"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app

		  ;;


	  112|lucky)

		local app_id="112"
		local docker_name="lucky"
		local docker_img="gdy666/lucky:v2"
		# Since Lucky uses the host network mode, the port here is only for record/explanation reference and is actually controlled by the application itself (default 16601)
		local docker_port=8112

		docker_rum() {

			docker run -d --name=${docker_name} --restart=always \
				--network host \
				-v /home/docker/lucky/conf:/app/conf \
				-v /var/run/docker.sock:/var/run/docker.sock \
				${docker_img}

			echo "Waiting for Lucky to initialize..."
			sleep 10
			docker exec lucky /app/lucky -rSetHttpAdminPort ${docker_port}

		}

		local docker_describe="Lucky is a large intranet penetration and port forwarding management tool that supports DDNS, reverse proxy, WOL and other functions."
		local docker_url="Project address: https://github.com/gdy666/lucky"
		local docker_use="echo \"Default account password: 666\""
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

			read -e -p "Set login password:" admin_password

			docker run -d --name=${docker_name} --restart=always \
				-p ${docker_port}:5800 \
				-v /home/docker/firefox:/config:rw \
				-e ENABLE_CJK_FONT=1 \
				-e WEB_AUDIO=1 \
				-e VNC_PASSWORD="${admin_password}" \
				${docker_img}
		}

		local docker_describe="It is a Firefox browser running in Docker that supports direct access to the desktop browser interface through the web page."
		local docker_url="Project address: https://github.com/jlesage/docker-firefox"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  b)
	  	clear
	  	send_stats "All application backup"

	  	local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
	  	echo -e "${gl_huang}Backing up$backup_filename ...${gl_bai}"
	  	cd / && tar czvf "$backup_filename" home

	  	while true; do
			clear
			echo "Backup file created: /$backup_filename"
			read -e -p "Do you want to transfer backup data to a remote server? (Y/N):" choice
			case "$choice" in
			  [Yy])
				read -e -p "Please enter the remote server IP:" remote_ip
				read -e -p "Target server SSH port [default 22]:" TARGET_PORT
				local TARGET_PORT=${TARGET_PORT:-22}

				if [ -z "$remote_ip" ]; then
				  echo "Error: Please enter the remote server IP."
				  continue
				fi
				local latest_tar=$(ls -t /app*.tar.gz | head -1)
				if [ -n "$latest_tar" ]; then
				  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				  sleep 2  # 添加等待时间
				  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
				  echo "File transferred to remote server/root directory."
				else
				  echo "The file to be transferred was not found."
				fi
				break
				;;
			  *)
				echo "Note: The current backup only includes docker projects, and does not include data backup of website building panels such as Pagoda and 1panel."
				break
				;;
			esac
	  	done

		  ;;

	  r)
	  	root_use
	  	send_stats "Restore all apps"
	  	echo "Available application backups"
	  	echo "-------------------------"
	  	ls -lt /app*.gz | awk '{print $NF}'
	  	echo ""
	  	read -e -p  "Press the Enter key to restore the latest backup, enter the backup file name to restore the specified backup, enter 0 to exit:" filename

	  	if [ "$filename" == "0" ]; then
			  break_end
			  linux_panel
	  	fi

	  	# If the user does not enter a file name, the latest compressed package is used
	  	if [ -z "$filename" ]; then
			  local filename=$(ls -t /app*.tar.gz | head -1)
	  	fi

	  	if [ -n "$filename" ]; then
		  	  echo -e "${gl_huang}Unzipping$filename ...${gl_bai}"
		  	  cd / && tar -xzf "$filename"
			  echo "The application data has been restored. Currently, please manually enter the specified application menu and update the application to restore the application."
	  	else
			  echo "No compressed package found."
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
			echo -e "${gl_hong}Error: Not found with number${sub_choice}application configuration${gl_bai}"
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
	  send_stats "Backend workspace"
	  echo -e "Backend workspace"
	  echo -e "The system will provide you with a workspace that can run permanently in the background, which you can use to perform long-term tasks."
	  echo -e "Even if you disconnect SSH, the tasks in the workspace will not be interrupted, and the tasks will remain in the background."
	  echo -e "${gl_huang}hint:${gl_bai}After entering the workspace, use Ctrl+b and then press d alone to exit the workspace!"
	  echo -e "${gl_kjlan}------------------------"
	  echo "List of currently existing workspaces"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Work Area 1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Work Area 2"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Work Area 3"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Work Area 4"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Workspace No. 5"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Work Area 6"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Work Area 7"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Work Area 8"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Workspace No. 9"
	  echo -e "${gl_kjlan}10.  ${gl_bai}Workspace 10"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH resident mode${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}Create/enter workspace"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Inject commands into the background workspace"
	  echo -e "${gl_kjlan}24.  ${gl_bai}Delete specified workspace"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "Start workspace$SESSION_NAME"
			  tmux_run
			  ;;

		  21)
			while true; do
			  clear
			  if grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc; then
				  local tmux_sshd_status="${gl_lv}turn on${gl_bai}"
			  else
				  local tmux_sshd_status="${gl_hui}closure${gl_bai}"
			  fi
			  send_stats "SSH resident mode"
			  echo -e "SSH resident mode${tmux_sshd_status}"
			  echo "After opening the SSH connection, it will directly enter the resident mode and return directly to the previous working state."
			  echo "------------------------"
			  echo "1. On 2. Off"
			  echo "------------------------"
			  echo "0. Return to the previous menu"
			  echo "------------------------"
			  read -e -p "Please enter your choice:" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "Start workspace$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# Automatically enter tmux session\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
				  source ~/.bashrc
			  	  tmux_run
				  ;;
				2)
				  sed -i '/# Automatically enter tmux session/,+4d' ~/.bashrc
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
			  send_stats "Delete workspace"
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










# Intelligent switching mirror source function
switch_mirror() {
	# Optional parameter, default is false
	local upgrade_software=${1:-false}
	local clean_cache=${2:-false}

	# Get user country
	local country
	country=$(curl -s ipinfo.io/country)

	echo "Countries detected:$country"

	if [ "$country" = "CN" ]; then
		echo "Use domestic mirror sources..."
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
		echo "Use official mirror source..."
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
		  send_stats "ssh defense"
		  while true; do

				check_f2b_status
				echo -e "SSH defense program$check_f2b_status"
				echo "fail2ban is an SSH tool to prevent brute force cracking"
				echo "Official website introduction:${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. Install a defense program"
				echo "------------------------"
				echo "2. View SSH interception records"
				echo "3. Real-time log monitoring"
				echo "------------------------"
				echo "9. Uninstall the defense program"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your choice:" sub_choice
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
						echo "Fail2Ban defense program has been uninstalled"
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
	  # send_stats "System Tools"
	  echo -e "system tools"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Set script startup shortcut key${gl_kjlan}2.   ${gl_bai}Change login password"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ROOT password login mode${gl_kjlan}4.   ${gl_bai}Install the specified version of Python"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Open all ports${gl_kjlan}6.   ${gl_bai}Modify SSH connection port"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Optimize DNS address${gl_kjlan}8.   ${gl_bai}Reinstall the system with one click${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Disable ROOT account and create new account${gl_kjlan}10.  ${gl_bai}Switch priority ipv4/ipv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Check port occupation status${gl_kjlan}12.  ${gl_bai}Modify virtual memory size"
	  echo -e "${gl_kjlan}13.  ${gl_bai}User management${gl_kjlan}14.  ${gl_bai}User/password generator"
	  echo -e "${gl_kjlan}15.  ${gl_bai}System time zone adjustment${gl_kjlan}16.  ${gl_bai}Set up BBR3 acceleration"
	  echo -e "${gl_kjlan}17.  ${gl_bai}Firewall Advanced Manager${gl_kjlan}18.  ${gl_bai}Modify hostname"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Switch system update source${gl_kjlan}20.  ${gl_bai}Scheduled task management"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}Native host resolution${gl_kjlan}22.  ${gl_bai}SSH defense program"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Current limiting automatic shutdown${gl_kjlan}24.  ${gl_bai}ROOT private key login mode"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot system monitoring and early warning${gl_kjlan}26.  ${gl_bai}Fix OpenSSH high-risk vulnerabilities"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat Linux kernel upgrade${gl_kjlan}28.  ${gl_bai}Linux system kernel parameter optimization${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}Virus scanning tools${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}file manager"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Switch system language${gl_kjlan}32.  ${gl_bai}Command line beautification tool${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Set up system recycle bin${gl_kjlan}34.  ${gl_bai}System backup and recovery"
	  echo -e "${gl_kjlan}35.  ${gl_bai}ssh remote connection tool${gl_kjlan}36.  ${gl_bai}Hard disk partition management tool"
	  echo -e "${gl_kjlan}37.  ${gl_bai}Command line history${gl_kjlan}38.  ${gl_bai}rsync remote synchronization tool"
	  echo -e "${gl_kjlan}39.  ${gl_bai}Command Favorites${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}message board${gl_kjlan}66.  ${gl_bai}One-stop system tuning${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}Restart the server${gl_kjlan}100. ${gl_bai}Privacy and security"
	  echo -e "${gl_kjlan}101. ${gl_bai}Advanced usage of k command${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}Uninstall tech lion script"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "Please enter your shortcut keys (enter 0 to exit):" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "Shortcut keys have been set"
				  send_stats "Script shortcut key has been set"
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
			echo "python version management"
			echo "Video introduction: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "This function can seamlessly install any version officially supported by Python!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "Current python version number:${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "Recommended versions: 3.12 3.11 3.10 3.9 3.8 2.7"
			echo "Check more versions: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "Enter the python version number you want to install (enter 0 to exit):" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "Script PY management"
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
			send_stats "Script PY version switching"

			  ;;

		  5)
			  root_use
			  send_stats "open port"
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

				# Print current SSH port number
				echo -e "The current SSH port number is:${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "The port number ranges from 1 to 65535. (Enter 0 to exit)"

				# Prompt user for new SSH port number
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
						echo "The port number is invalid. Please enter a number between 1 and 65535."
						send_stats "Invalid SSH port entered"
						break_end
					fi
				else
					echo "Invalid input, please enter a number."
					send_stats "Invalid SSH port entered"
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
			send_stats "Disable root for new users"
			read -e -p "Please enter a new username (enter 0 to exit):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			install sudo

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "The operation is complete."
			;;


		  10)
			root_use
			send_stats "Set v4/v6 priority"
			while true; do
				clear
				echo "Set v4/v6 priority"
				echo "------------------------"


				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "Current network priority settings:${gl_huang}IPv4${gl_bai}priority"
				else
					echo -e "Current network priority settings:${gl_huang}IPv6${gl_bai}priority"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 first 2. IPv6 first 3. IPv6 repair tool"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Choose your preferred network:" choice

				case $choice in
					1)
						prefer_ipv4
						;;
					2)
						rm -f /etc/gai.conf
						echo "Switched to IPv6 first"
						send_stats "Switched to IPv6 first"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "This function is provided by jhb, thank him!"
						send_stats "ipv6 repair"
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
				echo "1. Allocate 1024M 2. Allocate 2048M 3. Allocate 4096M 4. Custom size"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your choice:" choice

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
					send_stats "4G virtual memory has been set up"
					add_swap 4096

					;;

				  4)
					read -e -p "Please enter the virtual memory size (unit M):" new_swap
					add_swap "$new_swap"
					send_stats "Custom virtual memory set"
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
				send_stats "User management"
				echo "User list"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "username" "User permissions" "User group" "sudo permissions"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "Account operations"
				  echo "------------------------"
				  echo "1. Create a regular account 2. Create a premium account"
				  echo "------------------------"
				  echo "3. Grant the highest authority 4. Remove the highest authority"
				  echo "------------------------"
				  echo "5. Delete account"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" sub_choice

				  case $sub_choice in
					  1)
					   # Prompt user for new username
					   read -e -p "Please enter a new username:" new_username

					   # Create new user and set password
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "The operation is complete."
						  ;;

					  2)
					   # Prompt user for new username
					   read -e -p "Please enter a new username:" new_username

					   # Create new user and set password
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # Give the new user sudo permissions
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo

					   echo "The operation is complete."

						  ;;
					  3)
					   read -e -p "Please enter username:" username
					   # Give the new user sudo permissions
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo
						  ;;
					  4)
					   read -e -p "Please enter username:" username
					   # Remove user's sudo permissions from sudoers file
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "Please enter the username you want to delete:" username
					   # Delete users and their home directories
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
			send_stats "User information generator"
			echo "random username"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "random username$i: $username"
			done

			echo ""
			echo "random name"
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
			echo "16-digit random password"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "random password$i: $password"
			done

			echo ""
			echo "32-bit random password"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "random password$i: $password"
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
				echo "time zone switch"
				echo "------------------------"
				echo "Asia"
				echo "1. Shanghai, China time 2. Hong Kong time, China"
				echo "3. Tokyo, Japan time 4. Seoul, South Korea time"
				echo "5. Singapore time 6. Kolkata, India time"
				echo "7. Dubai, United Arab Emirates time 8. Sydney, Australia time"
				echo "9. Bangkok, Thailand time"
				echo "------------------------"
				echo "Europe"
				echo "11. London, UK time 12. Paris, France time"
				echo "13. Berlin, Germany time 14. Moscow, Russia time"
				echo "15. Utracht Time, Netherlands 16. Madrid Time, Spain"
				echo "------------------------"
				echo "America"
				echo "21. US Western Time 22. US Eastern Time"
				echo "23. Canada time 24. Mexico time"
				echo "25. Brazil time 26. Argentina time"
				echo "------------------------"
				echo "31. UTC global standard time"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your choice:" sub_choice


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
		  send_stats "Modify hostname"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "Current hostname:${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "Please enter a new hostname (enter 0 to exit):" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # Other systems such as Debian, Ubuntu, CentOS, etc.
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

				  echo "The hostname has been changed to:$new_hostname"
				  send_stats "Hostname changed"
				  sleep 1
			  else
				  echo "Exited without changing hostname."
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "Change system update source"
		  clear
		  echo "Select update source region"
		  echo "Access LinuxMirrors to switch system update sources"
		  echo "------------------------"
		  echo "1. Mainland China [Default] 2. Mainland China [Education Network] 3. Overseas regions 4. Intelligent switching of update sources"
		  echo "------------------------"
		  echo "0. Return to the previous menu"
		  echo "------------------------"
		  read -e -p "Enter your selection:" choice

		  case $choice in
			  1)
				  send_stats "Mainland China default source"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "Mainland China Education Source"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "Overseas sources"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  4)
				  send_stats "Intelligent switching of update sources"
				  switch_mirror false false
				  ;;

			  *)
				  echo "Canceled"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "Scheduled task management"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "Scheduled task list"
				  crontab -l
				  echo ""
				  echo "operate"
				  echo "------------------------"
				  echo "1. Add a scheduled task 2. Delete a scheduled task 3. Edit a scheduled task"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "Please enter the execution command of the new task:" newquest
						  echo "------------------------"
						  echo "1. Monthly tasks 2. Weekly tasks"
						  echo "3. Daily tasks 4. Hourly tasks"
						  echo "------------------------"
						  read -e -p "Please enter your choice:" dingshi

						  case $dingshi in
							  1)
								  read -e -p "On what day of the month do you choose to execute the task? (1-30):" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "Choose a day of the week to perform the task? (0-6, 0 represents Sunday):" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "What time do you choose to perform the task every day? (hours, 0-23):" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "Enter what time of the hour the task should be executed? (minutes, 0-60):" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "Add a scheduled task"
						  ;;
					  2)
						  read -e -p "Please enter the keyword of the task to be deleted:" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "Delete scheduled tasks"
						  ;;
					  3)
						  crontab -e
						  send_stats "Edit scheduled tasks"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "Local host resolution"
			  while true; do
				  clear
				  echo "Native host resolution list"
				  echo "If you add parsing matching here, dynamic parsing will no longer be used"
				  cat /etc/hosts
				  echo ""
				  echo "operate"
				  echo "------------------------"
				  echo "1. Add new resolution 2. Delete resolution address"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" host_dns

				  case $host_dns in
					  1)
						  read -e -p "Please enter a new parsing record format: 110.25.5.33 kejilion.pro:" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "Local host resolution is added"

						  ;;
					  2)
						  read -e -p "Please enter the keywords of the parsed content that need to be deleted:" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "Local host resolution and deletion"
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
			send_stats "Current limiting shutdown function"
			while true; do
				clear
				echo "Current limiting shutdown function"
				echo "Video introduction: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "The current traffic usage will be cleared when the server is restarted!"
				output_status
				echo -e "${gl_kjlan}Total received:${gl_bai}$rx"
				echo -e "${gl_kjlan}Total sent:${gl_bai}$tx"

				# Check if Limiting_Shut_down.sh file exists
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# Get the value of threshold_gb
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}The currently set inbound traffic limit threshold is:${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}The currently set outbound traffic limiting threshold is:${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}The current limiting shutdown function is not currently enabled${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "The system will detect whether the actual traffic reaches the threshold every minute, and will automatically shut down the server after reaching the threshold!"
				echo "------------------------"
				echo "1. Enable the current limiting shutdown function 2. Disable the current limiting shutdown function"
				echo "------------------------"
				echo "0. Return to the previous menu"
				echo "------------------------"
				read -e -p "Please enter your choice:" Limiting

				case "$Limiting" in
				  1)
					# Enter new virtual memory size
					echo "If the actual server only has 100G traffic, you can set the threshold to 95G and shut down in advance to avoid traffic errors or overflows."
					read -e -p "Please enter the inbound traffic threshold (unit is G, default is 100G):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "Please enter the outbound traffic threshold (unit is G, default is 100G):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "Please enter the traffic reset date (default resets on the 1st of every month):" cz_day
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
					echo "Current limiting shutdown has been set"
					send_stats "Current limiting shutdown has been set"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "Current limiting shutdown function is turned off"
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
			  	  echo "A key pair will be generated, a more secure way to log in via SSH"
				  echo "------------------------"
				  echo "1. Generate a new key 2. Import an existing key 3. View the local key"
				  echo "------------------------"
				  echo "0. Return to the previous menu"
				  echo "------------------------"
				  read -e -p "Please enter your choice:" host_dns

				  case $host_dns in
					  1)
				  		send_stats "Generate new key"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "Import existing public key"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "View local key"
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
			  send_stats "Telegraph warning"
			  echo "TG-bot monitoring and early warning function"
			  echo "Video introduction: https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "You need to configure the tg robot API and the user ID to receive alerts to achieve real-time monitoring and alerts of local CPU, memory, hard disk, traffic, and SSH login."
			  echo "When the threshold is reached, a warning message will be sent to the user."
			  echo -e "${gl_hui}- Regarding traffic, restarting the server will recalculate -${gl_bai}"
			  read -e -p "Are you sure you want to continue? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  send_stats "Telegram warning enabled"
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
				  echo "TG-bot early warning system has been activated"
				  echo -e "${gl_hui}You can also put the TG-check-notify.sh warning file in the root directory on other machines and use it directly!${gl_bai}"
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
			  send_stats "Fix high-risk SSH vulnerabilities"
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


		  39)
			  clear
			  linux_fav
			  ;;

		  41)
			clear
			send_stats "message board"
			echo "Visit the official message board of Technology Lion. If you have any ideas about the script, please leave a message to exchange!"
			echo "https://board.kejilion.pro"
			echo "Public password: kejilion.sh"
			  ;;

		  66)

			  root_use
			  send_stats "One-stop tuning"
			  echo "One-stop system tuning"
			  echo "------------------------------------------------"
			  echo "The following content will be operated and optimized"
			  echo "1. Optimize the system update source and update the system to the latest"
			  echo "2. Clean up system junk files"
			  echo -e "3. Set up virtual memory${gl_huang}1G${gl_bai}"
			  echo -e "4. Set the SSH port number to${gl_huang}5522${gl_bai}"
			  echo -e "5. Start fail2ban to defend against SSH brute force cracking"
			  echo -e "6. Open all ports"
			  echo -e "7. Turn on${gl_huang}BBR${gl_bai}accelerate"
			  echo -e "8. Set time zone to${gl_huang}Shanghai${gl_bai}"
			  echo -e "9. Automatically optimize DNS addresses${gl_huang}Overseas: 1.1.1.1 8.8.8.8 Domestic: 223.5.5.5${gl_bai}"
		  	  echo -e "10. Set the network to${gl_huang}ipv4 priority${gl_bai}"
			  echo -e "11. Install basic tools${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "12. Linux system kernel parameter optimization switches to${gl_huang}Balanced optimization mode${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "Are you sure you want one-click maintenance? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "One-stop tuning starts"
				  echo "------------------------------------------------"
				  switch_mirror false false
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/12. Update the system to the latest"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/12. Clean up system junk files"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/12. Set up virtual memory${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/12. Set the SSH port number to${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  f2b_install_sshd
				  cd ~
				  f2b_status
				  echo -e "[${gl_lv}OK${gl_bai}] 5/12. Start fail2ban to defend against SSH brute force cracking"

				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 6/12. Open all ports"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 7/12. Open${gl_huang}BBR${gl_bai}accelerate"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 8/12. Set time zone to${gl_huang}Shanghai${gl_bai}"

				  echo "------------------------------------------------"
				  auto_optimize_dns
				  echo -e "[${gl_lv}OK${gl_bai}] 9/12. Automatically optimize DNS address${gl_huang}${gl_bai}"
				  echo "------------------------------------------------"
				  prefer_ipv4
				  echo -e "[${gl_lv}OK${gl_bai}] 10/12. Set the network to${gl_huang}ipv4 priority${gl_bai}}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 11/12. Install basic tools${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 12/12. Linux system kernel parameter optimization"
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
			  	local status_message="${gl_lv}Collecting data${gl_bai}"
			  elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_hui}Collection is closed${gl_bai}"
			  else
			  	local status_message="Uncertain status"
			  fi

			  echo "Privacy and security"
			  echo "The script will collect data on users’ use of functions, optimize the script experience, and create more fun and useful functions."
			  echo "The script version number, time of use, system version, CPU architecture, country of the machine and name of the function used will be collected,"
			  echo "------------------------------------------------"
			  echo -e "Current status:$status_message"
			  echo "--------------------"
			  echo "1. Start collection"
			  echo "2. Close collection"
			  echo "--------------------"
			  echo "0. Return to the previous menu"
			  echo "--------------------"
			  read -e -p "Please enter your choice:" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "Collection has been started"
					  send_stats "Privacy and security collection has been turned on"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "Collection closed"
					  send_stats "Privacy and security collection has been turned off"
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
			  echo "The kejilion script will be completely uninstalled without affecting your other functions."
			  read -e -p "Are you sure you want to continue? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "The script has been uninstalled, bye!"
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
	send_stats "file manager"
	while true; do
		clear
		echo "file manager"
		echo "------------------------"
		echo "current path"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. Enter the directory 2. Create the directory 3. Modify directory permissions 4. Rename the directory"
		echo "5. Delete the directory 6. Return to the previous menu directory"
		echo "------------------------"
		echo "11. Create files 12. Edit files 13. Modify file permissions 14. Rename files"
		echo "15. Delete files"
		echo "------------------------"
		echo "21. Compress file directory 22. Unzip file directory 23. Move file directory 24. Copy file directory"
		echo "25. Transfer files to other servers"
		echo "------------------------"
		echo "0. Return to the previous menu"
		echo "------------------------"
		read -e -p "Please enter your choice:" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "Please enter the directory name:" dirname
				cd "$dirname" 2>/dev/null || echo "Unable to enter directory"
				send_stats "Enter directory"
				;;
			2)  # 创建目录
				read -e -p "Please enter the directory name to be created:" dirname
				mkdir -p "$dirname" && echo "Directory created" || echo "Creation failed"
				send_stats "Create directory"
				;;
			3)  # 修改目录权限
				read -e -p "Please enter the directory name:" dirname
				read -e -p "Please enter permissions (e.g. 755):" perm
				chmod "$perm" "$dirname" && echo "Permissions have been modified" || echo "Modification failed"
				send_stats "Modify directory permissions"
				;;
			4)  # 重命名目录
				read -e -p "Please enter the current directory name:" current_name
				read -e -p "Please enter a new directory name:" new_name
				mv "$current_name" "$new_name" && echo "Directory has been renamed" || echo "Rename failed"
				send_stats "Rename directory"
				;;
			5)  # 删除目录
				read -e -p "Please enter the directory name to be deleted:" dirname
				rm -rf "$dirname" && echo "Directory deleted" || echo "Delete failed"
				send_stats "delete directory"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "Return to the previous menu directory"
				;;
			11) # 创建文件
				read -e -p "Please enter the file name to be created:" filename
				touch "$filename" && echo "File created" || echo "Creation failed"
				send_stats "Create file"
				;;
			12) # 编辑文件
				read -e -p "Please enter the file name to be edited:" filename
				install nano
				nano "$filename"
				send_stats "Edit file"
				;;
			13) # 修改文件权限
				read -e -p "Please enter a file name:" filename
				read -e -p "Please enter permissions (e.g. 755):" perm
				chmod "$perm" "$filename" && echo "Permissions have been modified" || echo "Modification failed"
				send_stats "Modify file permissions"
				;;
			14) # 重命名文件
				read -e -p "Please enter the current file name:" current_name
				read -e -p "Please enter a new file name:" new_name
				mv "$current_name" "$new_name" && echo "File has been renamed" || echo "Rename failed"
				send_stats "Rename file"
				;;
			15) # 删除文件
				read -e -p "Please enter the file name to be deleted:" filename
				rm -f "$filename" && echo "File deleted" || echo "Delete failed"
				send_stats "Delete files"
				;;
			21) # 压缩文件/目录
				read -e -p "Please enter the file/directory name to be compressed:" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "Compressed to$name.tar.gz" || echo "Compression failed"
				send_stats "Compressed files/directories"
				;;
			22) # 解压文件/目录
				read -e -p "Please enter the file name to be extracted (.tar.gz):" filename
				install tar
				tar -xzvf "$filename" && echo "Unzipped$filename" || echo "Decompression failed"
				send_stats "Unzip files/directories"
				;;

			23) # 移动文件或目录
				read -e -p "Please enter the file or directory path to be moved:" src_path
				if [ ! -e "$src_path" ]; then
					echo "Error: File or directory does not exist."
					send_stats "Failed to move file or directory: File or directory does not exist"
					continue
				fi

				read -e -p "Please enter the destination path (including new file or directory name):" dest_path
				if [ -z "$dest_path" ]; then
					echo "Error: Please enter destination path."
					send_stats "Failed to move file or directory: Destination path not specified"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "File or directory moved to$dest_path" || echo "Failed to move file or directory"
				send_stats "Move a file or directory"
				;;


		   24) # 复制文件目录
				read -e -p "Please enter the file or directory path to copy:" src_path
				if [ ! -e "$src_path" ]; then
					echo "Error: File or directory does not exist."
					send_stats "Copying file or directory failed: File or directory does not exist"
					continue
				fi

				read -e -p "Please enter the destination path (including new file or directory name):" dest_path
				if [ -z "$dest_path" ]; then
					echo "Error: Please enter destination path."
					send_stats "Copying file or directory failed: Destination path not specified"
					continue
				fi

				# Use the -r option to copy directories recursively
				cp -r "$src_path" "$dest_path" && echo "File or directory copied to$dest_path" || echo "Failed to copy file or directory"
				send_stats "Copy a file or directory"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "Please enter the file path to be transferred:" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "Error: File does not exist."
					send_stats "Failed to transfer file: file does not exist"
					continue
				fi

				read -e -p "Please enter the remote server IP:" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "Error: Please enter the remote server IP."
					send_stats "File transfer failed: Remote server IP not entered"
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
					send_stats "File transfer successful"
				else
					echo "File transfer failed."
					send_stats "File transfer failed"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "Return to the previous menu"
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

	# Convert the extracted information into an array
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# Traverse the server and execute commands
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}connect to$name ($hostname)...${gl_bai}"
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
	  send_stats "Cluster control center"
	  echo "Server cluster control"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}Server list management${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}Add server${gl_kjlan}2.  ${gl_bai}Delete server${gl_kjlan}3.  ${gl_bai}Edit server"
	  echo -e "${gl_kjlan}4.  ${gl_bai}Backup cluster${gl_kjlan}5.  ${gl_bai}Restore cluster"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}Execute tasks in batches${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}Install technology lion script${gl_kjlan}12. ${gl_bai}Update system${gl_kjlan}13. ${gl_bai}Clean the system"
	  echo -e "${gl_kjlan}14. ${gl_bai}Install docker${gl_kjlan}15. ${gl_bai}Install BBR3${gl_kjlan}16. ${gl_bai}Set 1G virtual memory"
	  echo -e "${gl_kjlan}17. ${gl_bai}Set time zone to Shanghai${gl_kjlan}18. ${gl_bai}Open all ports${gl_kjlan}51. ${gl_bai}Custom instructions"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "Add cluster server"
			  read -e -p "Server name:" server_name
			  read -e -p "Server IP:" server_ip
			  read -e -p "Server port (22):" server_port
			  local server_port=${server_port:-22}
			  read -e -p "Server username (root):" server_username
			  local server_username=${server_username:-root}
			  read -e -p "Server user password:" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "Delete cluster server"
			  read -e -p "Please enter the keywords to be deleted:" rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "Edit cluster server"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "Backup cluster"
			  echo -e "please change${gl_huang}/root/cluster/servers.py${gl_bai}Download the file and complete the backup!"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "Restore cluster"
			  echo "Please upload your servers.py and press any key to start uploading!"
			  echo -e "Please upload your${gl_huang}servers.py${gl_bai}file to${gl_huang}/root/cluster/${gl_bai}Restore completed!"
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
			  send_stats "Custom execution command"
			  read -e -p "Please enter the command for batch execution:" mingling
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
echo -e "Server Discount"
echo "------------------------"
echo -e "${gl_lan}Laika Cloud Hong Kong CN2 GIA Korean dual ISP US CN2 GIA promotions${gl_bai}"
echo -e "${gl_bai}Website: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd $10.99 per year, USA, 1 core, 1G memory, 20G hard drive, 1T traffic per month${gl_bai}"
echo -e "${gl_bai}URL: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger $52.7 per year United States 1 core 4G memory 50G hard drive 4T traffic per month${gl_bai}"
echo -e "${gl_bai}URL: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}Bricklayer 49 dollars per quarter US CN2GIA Japan SoftBank 2 cores 1G memory 20G hard drive 1T traffic per month${gl_bai}"
echo -e "${gl_bai}Website: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT $28 per quarter US CN2GIA 1 core 2G memory 20G hard drive 800G traffic per month${gl_bai}"
echo -e "${gl_bai}URL: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS 6.9 dollars per month Tokyo Softbank 2 cores 1G memory 20G hard drive 1T traffic per month${gl_bai}"
echo -e "${gl_bai}URL: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}More popular VPS offers${gl_bai}"
echo -e "${gl_bai}Website: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "Domain name discount"
echo "------------------------"
echo -e "${gl_lan}GNAME $8.8 first-year COM domain name $6.68 first-year CC domain name${gl_bai}"
echo -e "${gl_bai}Website: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "Technology lion peripherals"
echo "------------------------"
echo -e "${gl_kjlan}Station B:${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}Oil pipe:${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}Official website:${gl_bai}https://kejilion.pro/              ${gl_kjlan}navigation:${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}blog:${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}Software Center:${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}Script official website:${gl_bai}https://kejilion.sh            ${gl_kjlan}GitHub address:${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}




games_server_tools() {

	while true; do
	  clear
	  echo -e "Collection of game server opening scripts"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1. ${gl_bai}Eudemons Parlu server opening script"
	  echo -e "${gl_kjlan}2. ${gl_bai}Minecraft server opening script"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0. ${gl_bai}Return to main menu"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Please enter your choice:" sub_choice

	  case $sub_choice in

		  1) send_stats "Eudemons Parlu server opening script" ; cd ~
			 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
			 exit
			 ;;
		  2) send_stats "Minecraft server opening script" ; cd ~
			 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/mc.sh ; chmod +x mc.sh ; ./mc.sh
			 exit
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





















kejilion_update() {

send_stats "Script update"
cd ~
while true; do
	clear
	echo "Change log"
	echo "------------------------"
	echo "All logs:${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}You are already on the latest version!${gl_huang}v$sh_v${gl_bai}"
		send_stats "The script is already up to date and does not need to be updated"
	else
		echo "New version discovered!"
		echo -e "Current version v$sh_vlatest version${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}Automatic updates are turned on, and the script will be automatically updated at 2 a.m. every day!${gl_bai}"
	fi

	echo "------------------------"
	echo "1. Update now 2. Turn on automatic updates 3. Turn off automatic updates"
	echo "------------------------"
	echo "0. Return to main menu"
	echo "------------------------"
	read -e -p "Please enter your choice:" choice
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
			echo -e "${gl_lv}Automatic updates are turned on, and the script will be automatically updated at 2 a.m. every day!${gl_bai}"
			send_stats "Enable automatic script updates"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}Automatic updates are turned off${gl_bai}"
			send_stats "Turn off automatic script updates"
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
echo -e "Command line input${gl_huang}k${gl_kjlan}Quick start script${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}System information query"
echo -e "${gl_kjlan}2.   ${gl_bai}System update"
echo -e "${gl_kjlan}3.   ${gl_bai}System cleanup"
echo -e "${gl_kjlan}4.   ${gl_bai}basic tools"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR management"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker management"
echo -e "${gl_kjlan}7.   ${gl_bai}WARP management"
echo -e "${gl_kjlan}8.   ${gl_bai}Test script collection"
echo -e "${gl_kjlan}9.   ${gl_bai}Oracle Cloud Script Collection"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP website building"
echo -e "${gl_kjlan}11.  ${gl_bai}application market"
echo -e "${gl_kjlan}12.  ${gl_bai}Backend workspace"
echo -e "${gl_kjlan}13.  ${gl_bai}system tools"
echo -e "${gl_kjlan}14.  ${gl_bai}Server cluster control"
echo -e "${gl_kjlan}15.  ${gl_bai}Advertising column"
echo -e "${gl_kjlan}16.  ${gl_bai}Collection of game server opening scripts"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}Script update"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}Exit script"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "Please enter your choice:" choice

case $choice in
  1) linux_info ;;
  2) clear ; send_stats "System update" ; linux_update ;;
  3) clear ; send_stats "System cleanup" ; linux_clean ;;
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
  16) games_server_tools ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "Invalid input!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k command reference examples"
echo "-------------------"
echo "Video introduction: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
echo "The following is a reference use case for the k command:"
echo "Start script k"
echo "Install packages k install nano wget | k add nano wget | k install nano wget"
echo "Uninstall a package k remove nano wget | k del nano wget | k uninstall nano wget | k uninstall nano wget"
echo "Update system k update | k update"
echo "Clean system junk k clean | k clean"
echo "Reinstall the system panel k dd | k reinstall"
echo "bbr3 control panel k bbr3 | k bbrv3"
echo "Kernel Tuning Panel k nhyh | k Kernel Optimization"
echo "Set virtual memory k swap 2048"
echo "Set virtual time zone k time Asia/Shanghai | k time zone Asia/Shanghai"
echo "System Recycle Bin k trash | k hsz | k Recycle Bin"
echo "System backup function k backup | k bf | k backup"
echo "ssh remote connection tool k ssh | k remote connection"
echo "rsync remote synchronization tool k rsync | k remote synchronization"
echo "Hard disk management tool k disk | k hard disk management"
echo "Intranet penetration (server) k frps"
echo "Intranet penetration (client) k frpc"
echo "Software startup k start sshd | k start sshd"
echo "Software stop k stop sshd | k stop sshd"
echo "Software restart k restart sshd | k restart sshd"
echo "Check software status k status sshd | k status sshd"
echo "k enable docker | k autostart docker | k enable docker when booting the software"
echo "Domain name certificate application k ssl"
echo "Domain name certificate expiry query k ssl ps"
echo "docker management plane k docker"
echo "docker environment installation k docker install |k docker installation"
echo "docker container management k docker ps |k docker container"
echo "docker image management k docker img |k docker image"
echo "LDNMP site management k web"
echo "LDNMP cache cleaning k web cache"
echo "Install WordPress k wp | k wordpress | k wp xxx.com"
echo "Install reverse proxy k fd |k rp |k reverse proxy |k fd xxx.com"
echo "Install load balancing k loadbalance |k load balancing"
echo "Install L4 load balancing k stream |k L4 load balancing"
echo "firewall panel k fhq |k firewall"
echo "open port k dkdk 8080 |k open port 8080"
echo "Close port k gbdk 7800 |k Close port 7800"
echo "Release IP k fxip 127.0.0.0/8 |k Release IP 127.0.0.0/8"
echo "Block IP k zzip 177.5.25.36 |k Block IP 177.5.25.36"
echo "command favorites k fav | k command favorites"
echo "Application market management k app"
echo "Quick management of application numbers k app 26 | k app 1panel | k app npm"
echo "fail2ban management k fail2ban | k f2b"
echo "Display system information k info"
}



if [ "$#" -eq 0 ]; then
	# Without arguments, run interactive logic
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
			send_stats "Uninstall software"
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
			send_stats "Scheduled rsync synchronization"
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
			  echo "IP+port has been blocked from accessing the service"
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

		命令收藏夹|fav)
			linux_fav
			;;

		status|状态)
			shift
			send_stats "Check software status"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "Software startup"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "software pause"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "Software restart"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "Software starts automatically when booting"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "View certificate status"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "Apply for a certificate quickly"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "Apply for a certificate quickly"
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
					send_stats "Quick image management"
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
			send_stats "Apply$@"
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
