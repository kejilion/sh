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



# 명령을 실행할 함수를 정의합니다
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



# 기능 매장 지점 정보를 수집하는 기능, 현재 스크립트 버전 번호, 사용 시간, 시스템 버전, CPU 아키텍처, 컴퓨터 국가 및 사용자가 사용하는 기능 이름을 기록합니다. 그들은 절대적으로 민감한 정보를 포함하지 않습니다. 제발 나를 믿으세요!
# 이 기능을 설계 해야하는 이유는 무엇입니까? 목적은 사용자가 사용하는 기능을 더 잘 이해하고 기능을 더욱 최적화하여 사용자 요구를 충족시키는 더 많은 기능을 시작하는 것입니다.
# 전체 텍스트의 경우 Send_Stats 기능 호출 위치, 투명 및 오픈 소스를 검색 할 수 있으며 우려 사항이 있으면 사용을 거부 할 수 있습니다.



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

# 사용자에게 이용 약관에 동의하라는 메시지
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}Tech Lion Script Toolbox에 오신 것을 환영합니다${gl_bai}"
	echo "스크립트를 처음 사용하면 사용자 라이센스 계약을 읽고 동의하십시오."
	echo "사용자 라이센스 계약 : https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "위의 용어에 동의하십니까? (Y/N) :" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "라이센스 동의"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "허가 거부"
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
		echo "패키지 매개 변수는 제공되지 않습니다!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}설치$package...${gl_bai}"
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
				echo "알 수없는 패키지 관리자!"
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
		echo -e "${gl_huang}힌트:${gl_bai}불충분 한 디스크 공간!"
		echo "현재 사용 가능한 공간 : $ ((uvery_space_mb/1024)) g"
		echo "최소 수요 공간 :${required_gb}G"
		echo "설치를 계속할 수 없습니다. 디스크 공간을 청소하고 다시 시도하십시오."
		send_stats "불충분 한 디스크 공간"
		break_end
		kejilion
	fi
}


install_dependency() {
	install wget unzip tar jq grep
}

remove() {
	if [ $# -eq 0 ]; then
		echo "패키지 매개 변수는 제공되지 않습니다!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}제거$package...${gl_bai}"
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
			echo "알 수없는 패키지 관리자!"
			return 1
		fi
	done
}


# 다양한 분포에 적합한 범용 SystemCTL 기능
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# 서비스를 다시 시작하십시오
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스가 다시 시작되었습니다."
	else
		echo "오류 : 다시 시작합니다$1서비스가 실패했습니다."
	fi
}

# 서비스를 시작하십시오
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스가 시작되었습니다."
	else
		echo "오류 : 시작$1서비스가 실패했습니다."
	fi
}

# 서비스 중지
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스가 중단되었습니다."
	else
		echo "오류 : 중지$1서비스가 실패했습니다."
	fi
}

# 서비스 상태를 확인하십시오
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스 상태가 표시됩니다."
	else
		echo "오류 : 표시 할 수 없습니다$1서비스 상태."
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME전원 켜기로 설정합니다."
}



break_end() {
	  echo -e "${gl_lv}작업이 완료되었습니다${gl_bai}"
	  echo "계속하려면 키를 누르십시오 ..."
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
	echo -e "${gl_huang}Docker 환경 설치 ...${gl_bai}"
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
	send_stats "도커 컨테이너 관리"
	echo "도커 컨테이너 목록"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "컨테이너 작동"
	echo "------------------------"
	echo "1. 새 컨테이너를 만듭니다"
	echo "------------------------"
	echo "2. 지정된 컨테이너를 시작하십시오. 6. 모든 컨테이너를 시작하십시오"
	echo "3. 지정된 컨테이너를 중지하십시오. 7. 모든 컨테이너를 중지하십시오"
	echo "4. 지정된 컨테이너를 삭제합니다. 8. 모든 컨테이너를 삭제하십시오"
	echo "5. 지정된 컨테이너를 다시 시작하십시오. 9. 모든 컨테이너를 다시 시작하십시오"
	echo "------------------------"
	echo "11. 지정된 컨테이너를 입력하십시오. 12. 컨테이너 로그보기"
	echo "13. 컨테이너 네트워크보기 14. 컨테이너 점유보기"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" sub_choice
	case $sub_choice in
		1)
			send_stats "새 컨테이너를 만듭니다"
			read -e -p "창조 명령을 입력하십시오 :" dockername
			$dockername
			;;
		2)
			send_stats "지정된 컨테이너를 시작하십시오"
			read -e -p "컨테이너 이름 (공백별로 분리 된 여러 컨테이너 이름)을 입력하십시오." dockername
			docker start $dockername
			;;
		3)
			send_stats "지정된 컨테이너를 중지하십시오"
			read -e -p "컨테이너 이름 (공백별로 분리 된 여러 컨테이너 이름)을 입력하십시오." dockername
			docker stop $dockername
			;;
		4)
			send_stats "지정된 컨테이너를 삭제하십시오"
			read -e -p "컨테이너 이름 (공백별로 분리 된 여러 컨테이너 이름)을 입력하십시오." dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "지정된 컨테이너를 다시 시작하십시오"
			read -e -p "컨테이너 이름 (공백별로 분리 된 여러 컨테이너 이름)을 입력하십시오." dockername
			docker restart $dockername
			;;
		6)
			send_stats "모든 컨테이너를 시작하십시오"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "모든 컨테이너를 중지하십시오"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "모든 컨테이너를 삭제하십시오"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "잘못된 선택, y 또는 N을 입력하십시오."
				;;
			esac
			;;
		9)
			send_stats "모든 컨테이너를 다시 시작하십시오"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "컨테이너를 입력하십시오"
			read -e -p "컨테이너 이름을 입력하십시오 :" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "컨테이너 로그를 봅니다"
			read -e -p "컨테이너 이름을 입력하십시오 :" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "컨테이너 네트워크를 봅니다"
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
			send_stats "컨테이너 점유를 봅니다"
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
	send_stats "도커 이미지 관리"
	echo "도커 이미지 목록"
	docker image ls
	echo ""
	echo "미러 작동"
	echo "------------------------"
	echo "1. 지정된 이미지 가져 오기 3. 지정된 이미지 삭제"
	echo "2. 지정된 이미지 업데이트 4. 모든 이미지 삭제"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" sub_choice
	case $sub_choice in
		1)
			send_stats "거울을 당기십시오"
			read -e -p "거울 이름을 입력하십시오 (공백으로 여러 거울 이름을 별도로 분리하십시오) :" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}이미지 얻기 :$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "이미지를 업데이트하십시오"
			read -e -p "거울 이름을 입력하십시오 (공백으로 여러 거울 이름을 별도로 분리하십시오) :" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}업데이트 된 이미지 :$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "거울을 삭제하십시오"
			read -e -p "거울 이름을 입력하십시오 (공백으로 여러 거울 이름을 별도로 분리하십시오) :" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "모든 이미지를 삭제합니다"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "잘못된 선택, y 또는 N을 입력하십시오."
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
				echo "지원되지 않는 분포 :$ID"
				return
				;;
		esac
	else
		echo "운영 체제를 결정할 수 없습니다."
		return
	fi

	echo -e "${gl_lv}Crontab이 설치되고 Cron 서비스가 실행 중입니다.${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 구성 파일이 존재하는지 확인하고 파일을 작성하고 기본 설정이 존재하지 않는 경우 작성하십시오.
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# JQ를 사용하여 구성 파일 업데이트를 처리하십시오
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 현재 구성에 이미 IPv6 설정이 있는지 확인하십시오
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 구성 업데이트 및 IPv6을 활성화하십시오
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 원래 구성과 새로운 구성을 비교합니다
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}IPv6 액세스가 현재 활성화되어 있습니다${gl_bai}"
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

	# 구성 파일이 있는지 확인하십시오
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}구성 파일이 존재하지 않습니다${gl_bai}"
		return
	fi

	# 현재 구성을 읽으십시오
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# JQ를 사용하여 구성 파일 업데이트를 처리하십시오
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 현재 IPv6 상태를 확인하십시오
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 원래 구성과 새로운 구성을 비교합니다
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}IPv6 액세스는 현재 닫힙니다${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}IPv6 액세스가 성공적으로 닫혔습니다${gl_bai}"
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
		echo "하나 이상의 포트 번호를 제공하십시오"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 기존 마감 규칙을 삭제하십시오
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 열린 규칙을 추가하십시오
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "포트가 열렸습니다$port"
		fi
	done

	save_iptables_rules
	send_stats "포트가 열렸습니다"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "하나 이상의 포트 번호를 제공하십시오"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 기존 열린 규칙을 삭제합니다
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 가까운 규칙을 추가하십시오
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "포트 폐쇄$port"
		fi
	done

	# 기존 규칙 삭제 (있는 경우)
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 새로운 규칙을 먼저 삽입하십시오
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "포트 폐쇄"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "하나 이상의 IP 주소 또는 IP 세그먼트를 제공하십시오."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 기존 차단 규칙을 삭제하십시오
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 허용 규칙을 추가하십시오
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP 출시$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP 출시"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "하나 이상의 IP 주소 또는 IP 세그먼트를 제공하십시오."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 删除已存在的允许规则
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 차단 규칙을 추가하십시오
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP 차단$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP 차단"
}







enable_ddos_defense() {
	# 방어 DDO를 켜십시오
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "DDOS 방어를 켜십시오"
}

# DDOS 방어를 끕니다
disable_ddos_defense() {
	# 방어 DDO를 끄십시오
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "DDOS 방어를 끕니다"
}





# 국가 IP 규칙을 관리하는 기능
manage_country_rules() {
	local action="$1"
	local country_code="$2"
	local ipset_name="${country_code,,}_block"
	local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

	install ipset

	case "$action" in
		block)
			# IPSET가 존재하지 않는 경우 작성하십시오
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# IP 영역 파일을 다운로드하십시오
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "오류 : 다운로드$country_codeIP 영역 파일이 실패했습니다"
				exit 1
			fi

			# IPSET에 IP를 추가하십시오
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# iptables와 함께 IP를 차단하십시오
			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
			iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

			echo "성공적으로 차단되었습니다$country_codeIP 주소"
			rm "${country_code,,}.zone"
			;;

		allow)
			# 허용 국가에 대한 IPSET 만들기 (존재하지 않는 경우)
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# IP 영역 파일을 다운로드하십시오
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "오류 : 다운로드$country_codeIP 영역 파일이 실패했습니다"
				exit 1
			fi

			# 기존 국가 규칙을 삭제합니다
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null
			ipset flush "$ipset_name"

			# IPSET에 IP를 추가하십시오
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# 지정된 국가의 IP 만 허용됩니다
			iptables -P INPUT DROP
			iptables -P OUTPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
			iptables -A OUTPUT -m set --match-set "$ipset_name" dst -j ACCEPT

			echo "성공적으로 만 허용됩니다$country_codeIP 주소"
			rm "${country_code,,}.zone"
			;;

		unblock)
			# 국가의 iptables 규칙을 삭제하십시오
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null

			# ipset을 파괴하십시오
			if ipset list "$ipset_name" &> /dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "성공적으로 해제했습니다$country_codeIP 주소 제한"
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
		  echo "고급 방화벽 관리"
		  send_stats "고급 방화벽 관리"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "방화벽 관리"
		  echo "------------------------"
		  echo "1. 지정된 포트 2를 엽니 다. 지정된 포트를 닫으십시오."
		  echo "3. 모든 포트를 엽니 다. 4. 모든 포트를 닫으십시오"
		  echo "------------------------"
		  echo "5. IP 화이트리스트 6. IP 블랙리스트"
		  echo "7. 지정된 IP를 지우십시오"
		  echo "------------------------"
		  echo "11. 핑 허용 12. 핑을 비활성화하십시오"
		  echo "------------------------"
		  echo "13. DDOS 방어 시작 14. DDOS 방어를 끄십시오"
		  echo "------------------------"
		  echo "15. 지정된 국가 IP 16. 지정된 국가 IP 만 허용됩니다."
		  echo "17. 지정된 국가에서 IP 제한을 해제합니다"
		  echo "------------------------"
		  echo "0. 이전 메뉴로 돌아갑니다"
		  echo "------------------------"
		  read -e -p "선택을 입력하십시오 :" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "열린 포트 번호를 입력하십시오 :" o_port
				  open_port $o_port
				  send_stats "지정된 포트를 엽니 다"
				  ;;
			  2)
				  read -e -p "닫힌 포트 번호를 입력하십시오 :" c_port
				  close_port $c_port
				  send_stats "지정된 포트를 닫습니다"
				  ;;
			  3)
				  # 모든 포트를 엽니 다
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
				  send_stats "모든 포트를 엽니 다"
				  ;;
			  4)
				  # 모든 포트를 닫습니다
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
				  send_stats "모든 포트를 닫습니다"
				  ;;

			  5)
				  # IP 화이트리스트
				  read -e -p "해제 할 IP 또는 IP 세그먼트를 입력하십시오." o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP 블랙리스트
				  read -e -p "차단 된 IP 또는 IP 세그먼트를 입력하십시오." c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 지정된 IP를 지우십시오
				  read -e -p "청산 된 IP를 입력하십시오 :" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "지정된 IP를 지우십시오"
				  ;;
			  11)
				  # 핑을 허용하십시오
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "핑을 허용하십시오"
				  ;;
			  12)
				  # 핑을 비활성화합니다
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "핑을 비활성화합니다"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "차단 된 국가 코드 (예 : CN, US, JP)를 입력하십시오." country_code
				  manage_country_rules block $country_code
				  send_stats "허용 국가$country_codeIP"
				  ;;
			  16)
				  read -e -p "허용 된 국가 코드 (예 : CN, US, JP)를 입력하십시오." country_code
				  manage_country_rules allow $country_code
				  send_stats "나라를 차단하십시오$country_codeIP"
				  ;;

			  17)
				  read -e -p "청산 된 국가 코드 (예 : CN, US, JP)를 입력하십시오." country_code
				  manage_country_rules unblock $country_code
				  send_stats "나라를 정리하십시오$country_codeIP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}








add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 현재 시스템에서 모든 스왑 파티션을 얻으십시오
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 모든 스왑 파티션을 반복하고 삭제하십시오
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# /swapfile이 더 이상 사용되지 않도록하십시오
	swapoff /swapfile

	# 이전 /스왑 파일을 삭제하십시오
	rm -f /swapfile

	# 새 스왑 파티션을 만듭니다
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

	echo -e "가상 메모리 크기가 크기가 커졌습니다${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 가상 메모리를 만들어야하는지 확인하십시오
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # nginx 버전을 얻으십시오
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # MySQL 버전을 얻으십시오
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # PHP 버전을 얻으십시오
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # Redis 버전을 얻으십시오
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 필요한 디렉토리 및 파일을 만듭니다
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf
  wget -O /home/web/redis/valkey.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/valkey.conf


  default_server_ssl

  # docker-compose.yml 파일을 다운로드하여 교체하십시오
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # docker-compose.yml 파일로 교체하십시오
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
	  echo "LDNMP 환경이 설치되었습니다"
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
	echo "갱신 작업이 업데이트되었습니다"
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
	echo -e "${gl_huang}$yuming공개 키 정보${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming개인 키 정보${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}인증서 저장 경로${gl_bai}"
	echo "공개 키 :/etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "개인 키 :/etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}SSL 인증서를 신속하게 신청하고 만료 전에 서명을 자동으로 갱신하십시오.${gl_bai}"
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
	echo -e "${gl_huang}응용 인증서 만료${gl_bai}"
	echo "사이트 정보 인증서 만료 시간"
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
		send_stats "도메인 이름 인증서에 대한 성공적인 응용 프로그램"
	else
		send_stats "도메인 이름 인증서 신청에 실패했습니다"
		echo -e "${gl_hong}알아채다:${gl_bai}인증서 응용 프로그램이 실패했습니다. 가능한 이유를 확인하고 다시 시도하십시오."
		echo -e "1. 도메인 이름 철자 오류 ➠ 도메인 이름이 올바르게 입력되었는지 확인하십시오."
		echo -e "2. DNS 해상도 문제 ➠ 도메인 이름 이이 서버 IP로 올바르게 해결되었는지 확인합니다."
		echo -e "3. 네트워크 구성 문제 ➠ CloudFlare Warp 및 기타 가상 네트워크를 사용하는 경우 임시로 종료하십시오."
		echo -e "4. 방화벽 제한 ➠ 검증에 액세스 할 수 있도록 포트 80/443이 열려 있는지 확인"
		echo -e "5. 응용 프로그램 수는 한계를 초과합니다. ➠ 암호화하자는 주간 제한 (5 배/도메인 이름/주)을 갖습니다."
		echo -e "6. 국내 등록 제한 ➠ 도메인 이름이 중국 본토에 등록되어 있는지 확인하십시오."
		break_end
		clear
		echo "다시 배포를 시도하십시오$webname"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "도메인 이름 재사용"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "먼저 도메인 이름을 로컬 IP로 해결합니다.${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "IP 또는 해결 된 도메인 이름을 입력하십시오." yuming
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

  send_stats "고쳐 쓰다$ldnmp_pods"
  echo "고쳐 쓰다${ldnmp_pods}마치다"

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
  echo "로그인 정보 :"
  echo "사용자 이름 :$dbuse"
  echo "비밀번호:$dbusepasswd"
  echo
  send_stats "시작$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 구성 파일이 있는지 확인하십시오
  if [ -f "$CONFIG_FILE" ]; then
	# 구성 파일에서 API_TOKE 및 ZONE_ID를 읽으십시오
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# Zone_ids를 배열로 변환합니다
	ZONE_IDS=($ZONE_IDS)
  else
	# 캐시 청소 여부를 사용자에게 프롬프트하십시오
	read -e -p "CloudFlare의 캐시를 청소해야합니까? (Y/N) :" answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF 정보가 저장됩니다$CONFIG_FILE, 나중에 CF 정보를 수정할 수 있습니다"
	  read -e -p "API_Token을 입력하십시오 :" API_TOKEN
	  read -e -p "CF 사용자 이름을 입력하십시오 :" EMAIL
	  read -e -p "Zone_ID를 입력하십시오 (공백으로 여러 차례 분리) :" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 각 Zone_ID를 루프하고 CLEAR CACHE 명령을 실행하십시오.
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "Zone_ID의 캐시 지우기 :$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "캐시 클리어 요청이 전송되었습니다."
}



web_cache() {
  send_stats "사이트 캐시를 정리하십시오"
  cf_purge_cache
  cd /home/web && docker compose restart
  restart_redis
}



web_del() {

	send_stats "사이트 데이터 삭제"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "사이트 데이터를 삭제하려면 도메인 이름을 입력하십시오 (여러 도메인 이름이 공간별로 분리됩니다)." yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "도메인 이름 삭제 :$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# 도메인 이름을 데이터베이스 이름으로 변환합니다
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 오류를 피하기 위해 삭제하기 전에 데이터베이스가 존재하는지 확인하십시오.
		echo "데이터베이스 삭제 :$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 모드 매개 변수에 따라 WAF를 켜거나 끄기로 결정
	if [ "$mode" == "on" ]; then
		# WAF 켜기 : 주석을 제거하십시오
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# waf 닫기 : 댓글을 추가하십시오
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "유효하지 않은 매개 변수 : 'ON'또는 'OFF'사용"
		return 1
	fi

	# Nginx 이미지를 확인하고 상황에 따라 처리하십시오.
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
	# 오래된 정의를 삭제하십시오
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# "Happy Publishing"과 함께 새로운 정의를 삽입하십시오.
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
	# 오래된 정의를 삭제하십시오
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# "Happy Publishing"과 함께 새로운 정의를 삽입하십시오.
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
		# Brotli를 켜십시오 : 주석을 제거하십시오
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
		# Brotli를 닫습니다 : 주석을 추가하십시오
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
		echo "유효하지 않은 매개 변수 : 'ON'또는 'OFF'사용"
		return 1
	fi

	# Nginx 이미지를 확인하고 상황에 따라 처리하십시오.
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
		# ZSTD를 켜십시오 : 주석을 제거하십시오
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
		# Zstd를 닫습니다 : 주석을 추가하십시오
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
		echo "유효하지 않은 매개 변수 : 'ON'또는 'OFF'사용"
		return 1
	fi

	# Nginx 이미지를 확인하고 상황에 따라 처리하십시오.
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
		echo "유효하지 않은 매개 변수 : 'ON'또는 'OFF'사용"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP 환경 방어"
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
			  echo -e "서버 웹 사이트 방어 프로그램${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 방어 프로그램을 설치하십시오"
			  echo "------------------------"
			  echo "5. SSH 차단 레코드보기 6. 웹 사이트 차단 레코드보기"
			  echo "7. 방어 규칙 목록보기 8. 로그의 실시간 모니터링보기"
			  echo "------------------------"
			  echo "11. 인터셉트 매개 변수 구성 12. 차단 된 모든 IP를 지우십시오"
			  echo "------------------------"
			  echo "21. CloudFlare 모드 22. 5 초 방패의 높은 하중"
			  echo "------------------------"
			  echo "31. WAF 32를 켜십시오. WAF를 끄십시오"
			  echo "33. DDOS 방어 켜기 34. DDOS 방어 끄기"
			  echo "------------------------"
			  echo "9. 방어 프로그램을 제거하십시오"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아갑니다"
			  echo "------------------------"
			  read -e -p "선택을 입력하십시오 :" sub_choice
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
					  echo "Fail2ban 방어 프로그램은 제거되었습니다"
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
					  send_stats "CloudFlare 모드"
					  echo "CF 배경의 오른쪽 상단 모서리로 이동하여 왼쪽의 API 토큰을 선택하고 글로벌 API 키를 얻습니다."
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "CF 계정 번호를 입력하십시오." cfuser
					  read -e -p "CF의 글로벌 API 키를 입력하십시오." cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /path/to/fail2ban/config/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "CloudFlare 모드는 CF 배경, Site-Security-Events에서 인터셉트 레코드를 보도록 구성됩니다."
					  ;;

				  22)
					  send_stats "5 초 방패의 높은 하중"
					  echo -e "${gl_huang}웹 사이트는 5 분마다 자동으로 감지됩니다. 높은 하중의 감지에 도달하면 방패가 자동으로 켜지고 낮은 부하가 자동으로 5 초 동안 꺼집니다.${gl_bai}"
					  echo "--------------"
					  echo "CF 매개 변수 가져 오기 :"
					  echo -e "CF 배경의 오른쪽 상단 모서리로 이동하여 왼쪽의 API 토큰을 선택하고 얻습니다.${gl_huang}Global API Key${gl_bai}"
					  echo -e "CF 배경 도메인 이름 요약 페이지의 오른쪽 하단으로 이동하려면${gl_huang}지역 ID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "CF 계정 번호를 입력하십시오." cfuser
					  read -e -p "CF의 글로벌 API 키를 입력하십시오." cftoken
					  read -e -p "CF에 도메인 이름의 영역 ID를 입력하십시오." cfzonID

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
						  echo "고 부하 자동 방패 오프닝 스크립트가 추가되었습니다"
					  else
						  echo "자동 방패 스크립트가 이미 존재합니다. 추가 할 필요가 없습니다."
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "사이트 waf가 활성화되어 있습니다"
					  send_stats "사이트 waf가 활성화되어 있습니다"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "사이트 waf가 닫혔습니다"
					  send_stats "사이트 waf가 닫혔습니다"
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

# 현재 Worker_Processes 설정 값을 얻으십시오
current_value=$(grep -E '^\s*worker_processes\s+[0-9]+;' "$CONFIG_FILE" | awk '{print $2}' | tr -d ';')

# 값에 따라 모드 정보를 설정합니다
if [ "$current_value" = "8" ]; then
	mode_info=" 高性能模式"
else
	mode_info=" 标准模式"
fi



}


check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# ZSTD가 활성화되어 있고 주석이 없는지 확인하십시오 (전체 라인은 ZSTD 켜기로 시작합니다.)
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status=" zstd压缩已开启"
	else
		zstd_status=""
	fi

	# Brotli가 활성화되어 있고 댓글이 없는지 확인하십시오
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status=" br压缩已开启"
	else
		br_status=""
	fi

	# GZIP가 활성화되어 있고 댓글을 달지 않은지 확인하십시오
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
			  send_stats "LDNMP 환경을 최적화하십시오"
			  echo -e "LDNMP 환경을 최적화하십시오${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 표준 모드 2. 고성능 모드 (2H4G 이상 권장)"
			  echo "------------------------"
			  echo "3. GZIP 압축 켜기 4. GZIP 압축 끄기"
			  echo "5. BR 압축 켜기 6. BR 압축 끄기"
			  echo "7. ZSTD 압축 켜기 8. ZSTD 압축 끄기"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아갑니다"
			  echo "------------------------"
			  read -e -p "선택을 입력하십시오 :" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "사이트 표준 모드"

				  # nginx 튜닝
				  sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

				  # PHP 튜닝
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHP 튜닝
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # MySQL 튜닝
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced


				  echo "LDNMP 환경은 표준 모드로 설정되었습니다"

					  ;;
				  2)
				  send_stats "사이트 고성능 모드"

				  # nginx 튜닝
				  sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

				  # PHP 튜닝
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHP 튜닝
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit 512M 512M
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # MySQL 튜닝
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

				  echo "LDNMP 환경은 고성능 모드로 설정되었습니다"

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
echo "액세스 주소 :"
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

	# 컨테이너 생성 시간과 이미지 이름을 얻으십시오
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# 거울 창고 및 태그 추출
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# 기본 레이블이 최신입니다
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# 공식 이미지에 대한 지원을 추가하십시오
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# Docker Hub API에서 이미지 게시 시간을 얻으십시오
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# 획득 시간을 확인하십시오
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# 타임 스탬프를 비교하십시오
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

	# 컨테이너의 IP 주소를 가져옵니다
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "오류 : 컨테이너를 얻을 수 없습니다$container_name_or_idIP 주소. 컨테이너 이름 또는 ID가 올바른지 확인하십시오."
		return 1
	fi

	install iptables


	# 다른 모든 IP를 점검하고 차단하십시오
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 지정된 IP를 확인하고 해제하십시오
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 127.0.0.0/8을 확인하고 해제하십시오
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# 다른 모든 IP를 점검하고 차단하십시오
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 지정된 IP를 확인하고 해제하십시오
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 127.0.0.0/8을 확인하고 해제하십시오
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ 포트는 서비스에 액세스하는 것이 차단되었습니다"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 컨테이너의 IP 주소를 가져옵니다
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "오류 : 컨테이너를 얻을 수 없습니다$container_name_or_idIP 주소. 컨테이너 이름 또는 ID가 올바른지 확인하십시오."
		return 1
	fi

	install iptables


	# 다른 모든 IP를 차단하는 명확한 규칙
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 지정된 IP를 공개하기위한 규칙을 지우십시오
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 릴리스 규칙을 지우십시오. 127.0.0.0/8
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# 다른 모든 IP를 차단하는 명확한 규칙
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 지정된 IP를 공개하기위한 규칙을 지우십시오
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 릴리스 규칙을 지우십시오. 127.0.0.0/8
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+포트는 서비스에 액세스 할 수있었습니다"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "오류 : 액세스 할 수있는 포트 번호와 IP를 제공하십시오."
		echo "사용법 : block_host_port <포트 번호> <승인 된 ip>"
		return 1
	fi

	install iptables


	# 다른 모든 IP 액세스를 거부했습니다
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 지정된 IP 액세스를 허용합니다
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 로컬 액세스를 허용합니다
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 다른 모든 IP 액세스를 거부했습니다
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 지정된 IP 액세스를 허용합니다
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 로컬 액세스를 허용합니다
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 확립 및 관련 연결을 위해 트래픽을 허용합니다
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "IP+ 포트는 서비스에 액세스하는 것이 차단되었습니다"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "오류 : 액세스 할 수있는 포트 번호와 IP를 제공하십시오."
		echo "사용법 : CLEAR_HOST_PORT_RULES <포트 번호> <승인 IP>"
		return 1
	fi

	install iptables


	# 다른 모든 IP 액세스를 차단하는 명확한 규칙
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# 기본 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 지정된 IP 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 다른 모든 IP 액세스를 차단하는 명확한 규칙
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# 기본 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 지정된 IP 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "IP+포트는 서비스에 액세스 할 수있었습니다"
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
send_stats "${docker_name}관리하다"

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
	echo "1. 설치 2. 업데이트 3. 제거"
	echo "------------------------"
	echo "5. 도메인 이름 액세스 추가 6. 도메인 이름 액세스 삭제"
	echo "7. IP+ 포트 액세스 허용 8. 블록 IP+ 포트 액세스"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" choice
	 case $choice in
		1)
			check_disk_space $app_size
			read -e -p "응용 프로그램 외부 서비스 포트를 입력하고 기본값을 입력하십시오.${docker_port}포트:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			setup_docker_dir
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			clear
			echo "$docker_name설치"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "설치하다$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum
			clear
			echo "$docker_name설치"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "고쳐 쓰다$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			rm -f /home/docker/${docker_name}_port.conf
			echo "앱이 제거되었습니다"
			send_stats "제거하십시오$docker_name"
			;;

		5)
			echo "${docker_name}도메인 액세스 설정"
			send_stats "${docker_name}도메인 액세스 설정"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "도메인 이름 형식 example.com은 https : //와 함께 제공되지 않습니다."
			web_del
			;;

		7)
			send_stats "IP 액세스 허용${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "IP 액세스를 차단하십시오${docker_name}"
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
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "------------------------"
		echo "5. 도메인 이름 액세스 추가 6. 도메인 이름 액세스 삭제"
		echo "7. IP+ 포트 액세스 허용 8. 블록 IP+ 포트 액세스"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" choice
		case $choice in
			1)
				check_disk_space $app_size
				read -e -p "응용 프로그램 외부 서비스 포트를 입력하고 기본값을 입력하십시오.${docker_port}포트:" app_port
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
				echo "${docker_name}도메인 액세스 설정"
				send_stats "${docker_name}도메인 액세스 설정"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "도메인 이름 형식 example.com은 https : //와 함께 제공되지 않습니다."
				web_del
				;;
			7)
				send_stats "IP 액세스 허용${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "IP 액세스를 차단하십시오${docker_name}"
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

# 세션이 존재하는지 확인하는 기능
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 존재하지 않는 세션 이름이 발견 될 때까지 루프
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 새로운 TMUX 세션을 만듭니다
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
		echo "다시 시작"
		reboot
		;;
	  *)
		echo "취소"
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
	send_stats "LDNMP 환경을 다시 설치할 수 없습니다"
	echo -e "${gl_huang}힌트:${gl_bai}웹 사이트 구성 환경이 설치되었습니다. 다시 설치할 필요가 없습니다!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "LDNMP 환경을 설치하십시오"
root_use
clear
echo -e "${gl_huang}LDNMP 환경이 설치되지 않았으며 LDNMP 환경 설치를 시작하십시오 ...${gl_bai}"
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
send_stats "Nginx 환경을 설치하십시오"
root_use
clear
echo -e "${gl_huang}Nginx가 설치되지 않았고 Nginx 환경 설치 시작 ...${gl_bai}"
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
echo "Nginx가 설치되었습니다"
echo -e "현재 버전 :${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "먼저 LDNMP 환경을 설치하십시오"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "Nginx 환경을 먼저 설치하십시오"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "당신 것$webname세워짐!"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webname설치 정보는 다음과 같습니다."

}

nginx_web_on() {
	  clear
	  echo "당신 것$webname세워짐!"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "설치하다$webname"
  echo "배포를 시작하십시오$webname"
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
# Echo "데이터베이스 이름 : $ dbname"
# Echo "사용자 이름 : $ dbuse"
# echo "비밀번호 : $ dbusepasswd"
# Echo "데이터베이스 주소 : mysql"
# 에코 "테이블 접두사 : wp_"

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "설치하다$webname"
	echo "배포를 시작하십시오$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "반세대 IP를 입력하십시오 :" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "반세대 포트를 입력하십시오 :" port
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

	send_stats "설치하다$webname"
	echo "배포를 시작하십시오$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# 사용자가 입력 한 여러 IP를 얻습니다 : 포트 (공간별로 분리)
	if [ -z "$reverseproxy_port" ]; then
		read -e -p "공간으로 분리 된 여러 반세대 IP+ 포트를 입력하십시오 (예 : 127.0.0.1:3000 127.0.1:3002) :" reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	# 상류 구성을 동적으로 생성합니다
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	# 템플릿의 자리 표시자를 교체하십시오
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
		send_stats "LDNMP 사이트 관리"
		echo "LDNMP 환경"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}인증서 만료 시간"
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
		echo "사이트 디렉토리"
		echo "------------------------"
		echo -e "데이터${gl_hui}/home/web/html${gl_bai}자격증${gl_hui}/home/web/certs${gl_bai}구성${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "작동하다"
		echo "------------------------"
		echo "1. 도메인 이름 인증서 신청/업데이트 2. 사이트 도메인 이름 변경"
		echo "3. 사이트 캐시 정리 4. 관련 사이트 만들기"
		echo "5. 액세스 로그보기 6. 오류 로그보기"
		echo "7. 글로벌 구성 편집 8. 사이트 구성 편집"
		echo "9. 사이트 데이터베이스 관리 10. 사이트 분석 보고서보기"
		echo "------------------------"
		echo "20. 지정된 사이트 데이터를 삭제합니다"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" sub_choice
		case $sub_choice in
			1)
				send_stats "도메인 이름 인증서를 신청하십시오"
				read -e -p "도메인 이름을 입력하십시오 :" yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "사이트 도메인 이름을 변경하십시오"
				echo -e "${gl_hong}적극 권장 :${gl_bai}먼저 전체 사이트 데이터를 백업 한 다음 사이트 도메인 이름을 변경하십시오!"
				read -e -p "이전 도메인 이름을 입력하십시오 :" oddyuming
				read -e -p "새 도메인 이름을 입력하십시오 :" yuming
				install_certbot
				install_ssltls
				certs_status

				# MySQL 교체
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

				# 웹 사이트 디렉토리 교체
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
				send_stats "관련 사이트를 만듭니다"
				echo -e "액세스 용 기존 사이트의 새 도메인 이름을 연결하십시오."
				read -e -p "기존 도메인 이름을 입력하십시오 :" oddyuming
				read -e -p "새 도메인 이름을 입력하십시오 :" yuming
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
				send_stats "액세스 로그를 봅니다"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "오류 로그를 봅니다"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "글로벌 구성 편집"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "사이트 구성 편집"
				read -e -p "사이트 구성을 편집하려면 편집 할 도메인 이름을 입력하십시오." yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "사이트 데이터를 봅니다"
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
send_stats "${panelname}관리하다"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname}요즘 인기 있고 강력한 운영 및 유지 관리 패널입니다."
	echo "공식 웹 사이트 소개 :$panelurl "

	echo ""
	echo "------------------------"
	echo "1. 설치 2. 관리 3. 제거"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install
			send_stats "${panelname}설치하다"
			;;
		2)
			panel_app_manage
			send_stats "${panelname}제어"

			;;
		3)
			panel_app_uninstall
			send_stats "${panelname}제거하십시오"
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

	send_stats "FRP 서버를 설치하십시오"
	# 임의의 포트 및 자격 증명을 생성합니다
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

	# 출력 생성 정보
	ip_address
	echo "------------------------"
	echo "클라이언트 배포에 필요한 매개 변수"
	echo "서비스 IP :$ipv4_address"
	echo "token: $token"
	echo
	echo "FRP 패널 정보"
	echo "FRP 패널 주소 : http : //$ipv4_address:$dashboard_port"
	echo "FRP 패널 사용자 이름 :$dashboard_user"
	echo "FRP 패널 비밀번호 :$dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "FRP 클라이언트를 설치하십시오"
	read -e -p "외부 네트워크 도킹 IP를 입력하십시오." server_addr
	read -e -p "외부 네트워크 도킹 토큰을 입력하십시오." token
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
	send_stats "FRP 인트라넷 서비스를 추가하십시오"
	# 사용자에게 서비스 이름 및 전달 정보를 입력하라는 메시지
	read -e -p "서비스 이름을 입력하십시오 :" service_name
	read -e -p "전달 유형 (TCP/UDP)을 입력하십시오 [기본 TCP 입력] :" service_type
	local service_type=${service_type:-tcp}
	read -e -p "인트라넷 IP를 입력하십시오 [기본값 127.0.0.1 입력] : :" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "인트라넷 포트를 입력하십시오 :" local_port
	read -e -p "외부 네트워크 포트를 입력하십시오 :" remote_port

	# 구성 파일에 사용자 입력을 쓰십시오
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 출력 생성 정보
	echo "제공하다$service_namefrpc.toml에 성공적으로 추가되었습니다"

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "FRP 인트라넷 서비스를 삭제하십시오"
	# 삭제 해야하는 서비스 이름을 입력하라는 메시지
	read -e -p "삭제 해야하는 서비스 이름을 입력하십시오." service_name
	# SED를 사용하여 서비스 및 관련 구성을 삭제하십시오.
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "제공하다$service_namefrpc.toml에서 성공적으로 삭제되었습니다"

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# 헤더를 인쇄하십시오
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
		# 서비스 정보가있는 경우 새 서비스를 처리하기 전에 현재 서비스를 인쇄하십시오.
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 현재 서비스 이름을 업데이트하십시오
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# 이전 값을 지우십시오
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
		# 마지막 서비스에 대한 정보를 인쇄하십시오
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# FRP 서버 포트를 가져옵니다
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# 액세스 주소를 생성합니다
generate_access_urls() {
	# 모든 포트를 먼저 얻으십시오
	get_frp_ports

	# 8055/8056 이외의 포트가 있는지 확인하십시오
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# 유효한 포트가있을 때만 제목과 콘텐츠 표시
	if [ "$has_valid_ports" = true ]; then
		echo "FRP 서비스 외부 액세스 주소 :"

		# 프로세스 IPv4 주소
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# Process IPv6 주소 (현재 경우)
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# HTTPS 구성 처리
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
	send_stats "FRP 서버"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP 서버$check_frp $update_status"
		echo "FRP 인트라넷 침투 서비스 환경을 구축하여 인터넷에 공개 IP없이 장치를 노출시킵니다."
		echo "공식 웹 사이트 소개 : https://github.com/fatedier/frp/"
		echo "비디오 교육 : https://www.bilibili.com/video/bv1ymw6e2ewl?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "------------------------"
		echo "5. 인트라넷 서비스에 대한 도메인 이름 액세스 6. 도메인 이름 액세스 삭제"
		echo "------------------------"
		echo "7. IP+ 포트 액세스 허용 8. 블록 IP+ 포트 액세스"
		echo "------------------------"
		echo "00. 서비스 상태 새로 고침 0. 이전 메뉴로 돌아갑니다."
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config
				echo "FRP 서버가 설치되었습니다"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps
				echo "FRP 서버가 업데이트되었습니다"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				echo "앱이 제거되었습니다"
				;;
			5)
				echo "리버스 인트라넷 침투 서비스를 도메인 이름 액세스로 향합니다"
				send_stats "외부 도메인 이름에 대한 FRP 액세스"
				add_yuming
				read -e -p "인트라넷 침투 서비스 포트를 입력하십시오 :" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "도메인 이름 형식 example.com은 https : //와 함께 제공되지 않습니다."
				web_del
				;;

			7)
				send_stats "IP 액세스 허용"
				read -e -p "해제 할 포트를 입력하십시오." frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "IP 액세스를 차단하십시오"
				echo "반세기 도메인 이름에 액세스 한 경우이 기능을 사용하여 IP+ 포트 액세스를 차단할 수 있습니다."
				read -e -p "차단 해야하는 포트를 입력하십시오." frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "FRP 서비스 상태를 새로 고치십시오"
				echo "FRP 서비스 상태가 새로 고쳐졌습니다"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRP 클라이언트"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP 클라이언트$check_frp $update_status"
		echo "서버로 도킹, 도킹 후 인터넷 액세스에 인트라넷 침투 서비스를 만들 수 있습니다."
		echo "공식 웹 사이트 소개 : https://github.com/fatedier/frp/"
		echo "비디오 교육 : https://www.bilibili.com/video/bv1ymw6e2ewl?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "------------------------"
		echo "4. 외부 서비스 추가 5. 외부 서비스 삭제 6. 서비스 구성 수동으로 서비스 구성"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc
				echo "FRP 클라이언트가 설치되었습니다"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc
				echo "FRP 클라이언트가 업데이트되었습니다"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055
				echo "앱이 제거되었습니다"
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
		send_stats "YT-DLP 다운로드 도구"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "YT-DLP는 YouTube, Bilibili, Twitter 등을 포함한 수천 개의 사이트를 지원하는 강력한 비디오 다운로드 도구입니다."
		echo -e "공식 웹 사이트 주소 : https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "다운로드 된 비디오 목록 :"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(아직 없음)"
		echo "-------------------------"
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "-------------------------"
		echo "5. 단일 비디오 다운로드 6. 배치 비디오 다운로드 7. 사용자 정의 매개 변수 다운로드"
		echo "8. MP3 오디오 9. 비디오 디렉토리 삭제 10. 쿠키 관리 (개발 중)"
		echo "-------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "-------------------------"
		read -e -p "옵션 번호를 입력하십시오 :" choice

		case $choice in
			1)
				send_stats "yt-dlp 설치 ..."
				echo "yt-dlp 설치 ..."
				install ffmpeg
				sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				sudo chmod a+rx /usr/local/bin/yt-dlp
				echo "설치가 완료되었습니다. 계속하려면 키를 누르십시오 ..."
				read ;;
			2)
				send_stats "yt-dlp 업데이트 ..."
				echo "yt-dlp 업데이트 ..."
				sudo yt-dlp -U
				echo "업데이트가 완료되었습니다. 계속하려면 키를 누르십시오 ..."
				read ;;
			3)
				send_stats "yt-dlp 제거 ..."
				echo "yt-dlp 제거 ..."
				sudo rm -f /usr/local/bin/yt-dlp
				echo "제거가 완료되었습니다. 계속하려면 키를 누르십시오 ..."
				read ;;
			5)
				send_stats "단일 비디오 다운로드"
				read -e -p "비디오 링크를 입력하십시오 :" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "다운로드가 완료되면 키를 눌러 계속하십시오 ..." ;;
			6)
				send_stats "배치 비디오 다운로드"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# 여러 비디오 링크 주소를 입력하십시오 \ n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "이제 배치 다운로드를 시작하십시오 ..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "배치 다운로드가 완료되었습니다. 키를 눌러 계속하십시오 ..." ;;
			7)
				send_stats "맞춤형 비디오 다운로드"
				read -e -p "전체 YT-DLP 매개 변수를 입력하십시오 (YT-DLP 제외) :" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "실행이 완료되면 키를 눌러 계속하십시오 ..." ;;
			8)
				send_stats "MP3 다운로드"
				read -e -p "비디오 링크를 입력하십시오 :" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "오디오 다운로드가 완료되었습니다. 키를 누르면 계속하십시오 ..." ;;

			9)
				send_stats "비디오 삭제"
				read -e -p "삭제 비디오의 이름을 입력하십시오." rmdir
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



# DPKG 인터럽트 문제를 수정하십시오
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}시스템 업데이트 ...${gl_bai}"
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
		echo "알 수없는 패키지 관리자!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}시스템 정리 ...${gl_bai}"
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
		echo "패키지 관리자 캐시 청소 ..."
		apk cache clean
		echo "시스템 로그 삭제 ..."
		rm -rf /var/log/*
		echo "APK 캐시 삭제 ..."
		rm -rf /var/cache/apk/*
		echo "임시 파일 삭제 ..."
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
		echo "시스템 로그 삭제 ..."
		rm -rf /var/log/*
		echo "임시 파일 삭제 ..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "사용하지 않는 의존성 정리 ..."
		pkg autoremove -y
		echo "패키지 관리자 캐시 청소 ..."
		pkg clean -y
		echo "시스템 로그 삭제 ..."
		rm -rf /var/log/*
		echo "임시 파일 삭제 ..."
		rm -rf /tmp/*

	else
		echo "알 수없는 패키지 관리자!"
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
send_stats "DNS 최적화"
while true; do
	clear
	echo "DNS 주소를 최적화합니다"
	echo "------------------------"
	echo "현재 DNS 주소"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 외국 DNS 최적화 :"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 국내 DNS 최적화 :"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. DNS 구성을 수동으로 편집합니다"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "외국 DNS 최적화"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "국내 DNS 최적화"
		;;
	  3)
		install nano
		nano /etc/resolv.conf
		send_stats "DNS 구성을 수동으로 편집합니다"
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

	# PasswordAuthentication이 발견되면 예로 설정하십시오
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# 발견 된 경우 PubKeyAuthentication이 예로 설정됩니다
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# PasswordAuthentication 또는 PubKeyAuthentication이 일치하지 않는 경우 기본값을 설정하십시오.
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # 백업 SSH 구성 파일
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSH 포트는 다음으로 수정되었습니다.$new_port"

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
	echo -e "개인 키 정보가 생성되었습니다. 복사하고 저장하십시오.${gl_huang}${ipv4_address}_ssh.key${gl_bai}향후 SSH 로그인 파일"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}루트 프라이빗 키 로그인이 활성화되고 루트 비밀번호 로그인이 닫히고 재 연결이 적용됩니다.${gl_bai}"

}


import_sshkey() {

	read -e -p "SSH 공개 키 내용을 입력하십시오 (일반적으로 'SSH-RSA'또는 'SSH-ED25519'로 시작) :" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}오류 : 공개 키 컨텐츠가 입력되지 않았습니다.${gl_bai}"
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
	echo -e "${gl_lv}공개 키가 성공적으로 가져 왔고 루트 개인 키 로그인이 활성화되었고 루트 비밀번호 로그인이 닫히고 재 연결이 적용됩니다.${gl_bai}"

}




add_sshpasswd() {

echo "루트 비밀번호를 설정하십시오"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}루트 로그인이 설정되었습니다!${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}힌트:${gl_bai}이 기능은 루트 사용자가 실행해야합니다!" && break_end && kejilion
}



dd_xitong() {
		send_stats "시스템을 다시 설치하십시오"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "재설치 후 초기 사용자 이름 :${gl_huang}root${gl_bai}초기 비밀번호 :${gl_huang}LeitboGi0ro${gl_bai}초기 포트 :${gl_huang}22${gl_bai}"
		  echo -e "계속하려면 키를 누르십시오 ..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "재설치 후 초기 사용자 이름 :${gl_huang}Administrator${gl_bai}초기 비밀번호 :${gl_huang}Teddysun.com${gl_bai}초기 포트 :${gl_huang}3389${gl_bai}"
		  echo -e "계속하려면 키를 누르십시오 ..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "재설치 후 초기 사용자 이름 :${gl_huang}root${gl_bai}초기 비밀번호 :${gl_huang}123@@@${gl_bai}초기 포트 :${gl_huang}22${gl_bai}"
		  echo -e "계속하려면 키를 누르십시오 ..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "재설치 후 초기 사용자 이름 :${gl_huang}Administrator${gl_bai}초기 비밀번호 :${gl_huang}123@@@${gl_bai}초기 포트 :${gl_huang}3389${gl_bai}"
		  echo -e "계속하려면 키를 누르십시오 ..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "시스템을 다시 설치하십시오"
			echo "--------------------------------"
			echo -e "${gl_hong}알아채다:${gl_bai}다시 설치는 접촉을 잃을 위험이 있으며 걱정하는 사람들은 그것을주의해서 사용해야합니다. 재설치는 15 분이 걸릴 것으로 예상됩니다. 데이터를 미리 백업하십시오."
			echo -e "${gl_hui}스크립트 지원을 위해 Mollylau 및 Bin456789에게 감사드립니다!${gl_bai} "
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
			echo "35. OpenSuse Tumbleweed 36. FNOS FEINIU 공개 베타 버전"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2022"
			echo "45. Windows Server 2019       46. Windows Server 2016"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 이전 메뉴로 돌아갑니다"
			echo "------------------------"
			read -e -p "다시 설치할 시스템을 선택하십시오." sys_choice
			case "$sys_choice" in
			  1)
				send_stats "데비안 12를 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  2)
				send_stats "데비안 11을 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  3)
				send_stats "데비안 10을 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  4)
				send_stats "데비안 9를 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -debian 9
				reboot
				exit
				;;
			  11)
				send_stats "우분투 24.04를 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "우분투 22.04를 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "Ubuntu 20.04를 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "우분투 18.04를 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "Rockylinux10을 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "Rockylinux9를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				send_stats "Alma10을 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "Alma9를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				send_stats "Oracle10을 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "Oracle9를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				send_stats "Fedora42를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "Fedora41을 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh fedora 41
				reboot
				exit
				;;

			  29)
				send_stats "CentOS10을 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "CentOS9를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "알파인을 다시 설치하십시오"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "아치를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "칼리를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "Openeuler를 다시 설치하십시오"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "재설치 OpenSuse"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "비행 소부소"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;


			  41)
				send_stats "Windows 11을 다시 설치하십시오"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;
			  42)
				dd_xitong_2
				send_stats "Windows 10을 다시 설치하십시오"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;
			  43)
				send_stats "Windows 7을 다시 설치하십시오"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "Windows Server 22를 다시 설치하십시오"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;
			  45)
				send_stats "Windows Server 19를 다시 설치하십시오"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;
			  46)
				send_stats "Windows Server 16을 다시 설치하십시오"
				dd_xitong_2
				bash InstallNET.sh -windows 2016 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "Windows11 Arm을 다시 설치하십시오"
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
		  send_stats "BBRV3 관리"

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
				  echo "Xanmod의 BBRV3 커널을 설치했습니다"
				  echo "현재 커널 버전 :$kernel_version"

				  echo ""
				  echo "커널 관리"
				  echo "------------------------"
				  echo "1. BBRV3 커널 업데이트 2. BBRV3 커널 제거"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# 3 단계 : 저장소를 추가합니다
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "Xanmod 커널이 업데이트되었습니다. 다시 시작한 후에도 적용됩니다"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "Xanmod 커널은 제거되었습니다. 다시 시작한 후에도 적용됩니다"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "BBR3 가속도를 설정하십시오"
		  echo "비디오 소개 : https://www.bilibili.com/video/bv14k421x7bs?t=0.1"
		  echo "------------------------------------------------"
		  echo "데비안/우분투 만 지원합니다"
		  echo "데이터를 백업하고 BBR3에서 Linux 커널을 업그레이드 할 수 있습니다."
		  echo "VPS는 512m 메모리를 가지고 있습니다. 메모리가 충분하지 않아 접점 누락을 방지하기 위해 1G 가상 메모리를 미리 추가하십시오!"
		  echo "------------------------------------------------"
		  read -e -p "계속할거야? (Y/N) :" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "현재 환경은이를 지원하지 않으며 데비안 및 우분투 시스템 만 지원합니다."
					break_end
					linux_Settings
				fi
			else
				echo "운영 체제 유형을 결정할 수 없습니다"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# 3 단계 : 저장소를 추가합니다
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "Xanmod 커널이 설치되고 BBR3이 성공적으로 활성화됩니다. 다시 시작한 후에도 적용됩니다"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "취소"
			  ;;
			*)
			  echo "잘못된 선택, y 또는 N을 입력하십시오."
			  ;;
		  esac
		fi

}


elrepo_install() {
	# Elrepo GPG 공개 키를 가져 오십시오
	echo "Elrepo GPG 공개 키를 가져 오십시오 ..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 시스템 버전을 감지하십시오
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 지원되는 운영 체제에서 실행하십시오
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "지원되지 않는 운영 체제 :$os_name"
		break_end
		linux_Settings
	fi
	# 감지 된 운영 체제 정보를 인쇄합니다
	echo "운영 체제 감지 :$os_name $os_version"
	# 시스템 버전에 따라 해당 Elrepo 창고 구성을 설치하십시오.
	if [[ "$os_version" == 8 ]]; then
		echo "Elrepo 저장소 구성 (버전 8)을 설치하십시오 ..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "Elrepo 저장소 구성 (버전 9)을 설치하십시오 ..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "Elrepo 저장소 구성 (버전 10)을 설치하십시오 ..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "지원되지 않는 시스템 버전 :$os_version"
		break_end
		linux_Settings
	fi
	# Elrepo 커널 저장소를 활성화하고 최신 메인 라인 커널을 설치하십시오.
	echo "Elrepo 커널 저장소를 활성화하고 최신 메인 라인 커널을 설치하십시오 ..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "Elrepo 저장소 구성이 설치되어 최신 메인 라인 커널로 업데이트됩니다."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "레드 모자 커널 관리"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "Elrepo 커널을 설치했습니다"
				  echo "현재 커널 버전 :$kernel_version"

				  echo ""
				  echo "커널 관리"
				  echo "------------------------"
				  echo "1. Elrepo 커널 업데이트 2. Elrepo 커널 제거"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "Red Hat 커널을 업데이트하십시오"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "Elrepo 커널은 제거되었습니다. 다시 시작한 후에도 적용됩니다"
						send_stats "빨간 모자 커널을 제거하십시오"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "데이터를 백업하고 Linux 커널을 업그레이드합니다."
		  echo "비디오 소개 : https://www.bilibili.com/video/bv1mh4y1w7qa?t=529.2"
		  echo "------------------------------------------------"
		  echo "Red Hat 시리즈 배포 Centos/Redhat/Alma/Rocky/Oracle 만 지원합니다"
		  echo "Linux 커널을 업그레이드하면 시스템 성능 및 보안이 향상 될 수 있습니다. 조건이 허용되고 생산 환경을 조심스럽게 업그레이드하는 경우 시도하는 것이 좋습니다!"
		  echo "------------------------------------------------"
		  read -e -p "계속할거야? (Y/N) :" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "Red Hat 커널을 업그레이드하십시오"
			  server_reboot
			  ;;
			[Nn])
			  echo "취소"
			  ;;
			*)
			  echo "잘못된 선택, y 또는 N을 입력하십시오."
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}바이러스 데이터베이스 업데이트 ...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "스캔 할 디렉토리를 지정하십시오."
		return
	fi

	echo -e "${gl_huang}스캔 디렉토리 $@...${gl_bai}"

	# 마운트 매개 변수를 빌드하십시오
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# Clamscan 명령 매개 변수를 작성하십시오
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# Docker 명령을 실행하십시오
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ scan이 완료되고 바이러스 보고서가 저장됩니다${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}바이러스가 있다면 제발${gl_huang}scan.log${gl_lv}파일에서 찾은 키워드를 검색하여 바이러스의 위치를 확인하십시오.${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "바이러스 스캔 관리"
		  while true; do
				clear
				echo "Clamav 바이러스 스캐닝 도구"
				echo "비디오 소개 : https://www.bilibili.com/video/bv1tqvze4eqm?t=0.1"
				echo "------------------------"
				echo "오픈 소스 바이러스 백신 소프트웨어 도구로 주로 다양한 유형의 맬웨어를 감지하고 제거하는 데 사용됩니다."
				echo "바이러스, 트로이 목마, 스파이웨어, 악성 스크립트 및 기타 유해한 소프트웨어를 포함합니다."
				echo "------------------------"
				echo -e "${gl_lv}1. 전체 디스크 스캔${gl_bai}             ${gl_huang}2. 중요한 디렉토리를 스캔하십시오${gl_bai}            ${gl_kjlan}3. 사용자 정의 디렉토리 스캔${gl_bai}"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" sub_choice
				case $sub_choice in
					1)
					  send_stats "전체 디스크 스캔"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "중요한 디렉토리 스캔"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "사용자 정의 디렉토리 스캔"
					  read -e -p "스캔 할 디렉토리를 입력하십시오." directories
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




# 고성능 모드 최적화 기능
optimize_high_performance() {
	echo -e "${gl_lv}전환하십시오${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화 ...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}가상 메모리 최적화 ...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화 ...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화 ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화 ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}기타 최적화 ...${gl_bai}"
	# 대형 투명 페이지를 비활성화하여 대기 시간을 줄입니다
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱을 비활성화합니다
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# 이퀄라이제이션 모드 최적화 기능
optimize_balanced() {
	echo -e "${gl_lv}이퀄라이제이션 모드로 전환 ...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화 ...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}가상 메모리 최적화 ...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화 ...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화 ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화 ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}기타 최적화 ...${gl_bai}"
	# 투명 페이지를 복원하십시오
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱을 복원하십시오
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# 기본 설정 기능을 복원하십시오
restore_defaults() {
	echo -e "${gl_lv}기본 설정으로 복원하십시오 ...${gl_bai}"

	echo -e "${gl_lv}파일 디스크립터 복원 ...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}가상 메모리 복원 ...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 복원 ...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 복원 ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}CPU 설정 복원 ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}다른 최적화를 복원 ...${gl_bai}"
	# 투명 페이지를 복원하십시오
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱을 복원하십시오
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# 웹 사이트 구축 최적화 기능
optimize_web_server() {
	echo -e "${gl_lv}웹 사이트 구축 최적화 모드로 전환하십시오 ...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화 ...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}가상 메모리 최적화 ...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화 ...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화 ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화 ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}기타 최적화 ...${gl_bai}"
	# 대형 투명 페이지를 비활성화하여 대기 시간을 줄입니다
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱을 비활성화합니다
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux 커널 튜닝 관리"
	  echo "Linux 시스템에서 커널 매개 변수의 최적화"
	  echo "비디오 소개 : https://www.bilibili.com/video/bv1kb421j7 yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "다양한 시스템 매개 변수 튜닝 모드가 제공되며 사용자는 자체 사용 시나리오에 따라 선택하고 전환 할 수 있습니다."
	  echo -e "${gl_huang}힌트:${gl_bai}생산 환경에서주의해서 사용하십시오!"
	  echo "--------------------"
	  echo "1. 고성능 최적화 모드 : 시스템 성능을 극대화하고 파일 설명기, 가상 메모리, 네트워크 설정, 캐시 관리 및 CPU 설정을 최적화합니다."
	  echo "2. 균형 최적화 모드 : 매일 사용하기에 적합한 성능과 자원 소비 사이의 균형."
	  echo "3. 웹 사이트 최적화 모드 : 웹 사이트 서버에 최적화하여 동시 연결 처리 기능, 응답 속도 및 전반적인 성능을 향상시킵니다."
	  echo "4. 라이브 브로드 캐스트 최적화 모드 : 라이브 방송 스트리밍의 특별한 요구를 최적화하여 대기 시간을 줄이고 전송 성능을 향상시킵니다."
	  echo "5. 게임 서버 최적화 모드 : 게임 서버를 위해 동시 처리 기능 및 응답 속도를 향상시킬 최적화."
	  echo "6. 기본 설정을 복원하십시오. 시스템 설정을 기본 구성으로 복원하십시오."
	  echo "--------------------"
	  echo "0. 이전 메뉴로 돌아갑니다"
	  echo "--------------------"
	  read -e -p "선택을 입력하십시오 :" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "고성능 모드 최적화"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "균형 모드 최적화"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "웹 사이트 최적화 모델"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "라이브 스트리밍 최적화"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "게임 서버 최적화"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "기본 설정을 복원하십시오"
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
				echo -e "${gl_lv}시스템 언어는 다음으로 수정되었습니다.$langSSH를 다시 연결하면 적용됩니다.${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}시스템 언어는 다음으로 수정되었습니다.$langSSH를 다시 연결하면 적용됩니다.${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "지원되지 않는 시스템 :$ID"
				break_end
				;;
		esac
	else
		echo "지원되지 않는 시스템, 시스템 유형을 인식 할 수 없습니다."
		break_end
	fi
}




linux_language() {
root_use
send_stats "스위치 시스템 언어"
while true; do
  clear
  echo "현재 시스템 언어 :$LANG"
  echo "------------------------"
  echo "1. 영어 2. 중국어 3. 전통 중국어"
  echo "------------------------"
  echo "0. 이전 메뉴로 돌아갑니다"
  echo "------------------------"
  read -e -p "선택을 입력하십시오 :" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "영어로 전환하십시오"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "단순화 된 중국어로 전환하십시오"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "전통적인 중국어로 전환하십시오"
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
echo -e "${gl_lv}변경이 완료되었습니다. 변경 사항을 볼 수 있도록 SSH를 다시 연결하십시오!${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "명령 라인 미화 도구"
  while true; do
	clear
	echo "명령 라인 미화 도구"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" choice

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
  send_stats "시스템 재활용 스테이션"

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
	echo -e "현재 재활용 쓰레기통${trash_status}"
	echo -e "활성화 후 RM이 삭제 한 파일은 먼저 재활용 빈에 입력하여 중요한 파일의 잘못된 삭제를 방지합니다!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "재활용 쓰레기통은 비어 있습니다"
	echo "------------------------"
	echo "1. 재활용 빈을 활성화합니다. 2. 재활용 쓰레기통을 닫습니다."
	echo "3. 컨텐츠를 복원 4. 재활용 쓰레기통을 지 웁니다"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "Recycle Bin이 활성화되고 삭제 된 파일이 Recycle Bin으로 이동됩니다."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "재활용 빈이 닫히고 파일이 직접 삭제됩니다."
		sleep 2
		;;
	  3)
		read -e -p "복원 할 파일 이름을 입력하십시오." file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restore홈 디렉토리로 복원되었습니다."
		else
		  echo "파일이 존재하지 않습니다."
		fi
		;;
	  4)
		read -e -p "재활용 쓰레기통을 지우셨습니까? [Y/N] :" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "재활용 쓰레기통이 지워졌습니다."
		fi
		;;
	  *)
		break
		;;
	esac
  done
}



# 백업을 만듭니다
create_backup() {
	send_stats "백업을 만듭니다"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# 사용자에게 백업 디렉토리를 입력하라는 메시지를 표시하십시오
	echo "백업 예제 :"
	echo "- 단일 디렉토리를 백업 : /var /www"
	echo "- 여러 디렉토리 백업 : /etc /home /var /log"
	echo "- Direct Enter는 기본 디렉토리 ( /etc /usr /home)를 사용합니다."
	read -r -p "백업 디렉토리를 입력하십시오 (여러 디렉토리가 공간별로 구분되며 직접 입력하면 기본 디렉토리를 사용하십시오)." input

	# 사용자가 디렉토리를 입력하지 않으면 기본 디렉토리를 사용하십시오.
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# 사용자가 입력 한 디렉토리를 공백 별 배열로 분리합니다.
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# 백업 파일 접두사를 생성합니다
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# 디렉토리 이름을 추출하고 슬래시를 제거하십시오
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 마지막 밑줄을 제거하십시오
	local PREFIX=${PREFIX%_}

	# 백업 파일 이름을 생성합니다
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# 사용자가 선택한 디렉토리를 인쇄하십시오
	echo "선택한 백업 디렉토리는 다음과 같습니다."
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 백업을 만듭니다
	echo "백업 생성$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 명령이 성공했는지 확인하십시오
	if [ $? -eq 0 ]; then
		echo "백업은 성공적으로 생성되었습니다.$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "백업 생성이 실패했습니다!"
		exit 1
	fi
}

# 백업을 복원하십시오
restore_backup() {
	send_stats "백업을 복원하십시오"
	# 복원하려는 백업을 선택하십시오
	read -e -p "복원하려면 백업 파일 이름을 입력하십시오." BACKUP_NAME

	# 백업 파일이 있는지 확인하십시오
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "백업 파일이 존재하지 않습니다!"
		exit 1
	fi

	echo "백업 복구$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "백업 및 복원을 성공적으로 복원하십시오!"
	else
		echo "백업 복구 실패!"
		exit 1
	fi
}

# 백업을 나열합니다
list_backups() {
	echo "사용 가능한 백업 :"
	ls -1 "$BACKUP_DIR"
}

# 백업을 삭제하십시오
delete_backup() {
	send_stats "백업을 삭제하십시오"

	read -e -p "삭제하려면 백업 파일 이름을 입력하십시오." BACKUP_NAME

	# 백업 파일이 있는지 확인하십시오
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "백업 파일이 존재하지 않습니다!"
		exit 1
	fi

	# 백업을 삭제하십시오
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "백업이 성공적으로 삭제되었습니다!"
	else
		echo "백업 삭제가 실패했습니다!"
		exit 1
	fi
}

# 백업 메인 메뉴
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "시스템 백업 기능"
		echo "시스템 백업 기능"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. 백업 만들기 2. 백업 복원 3. 백업 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "계속하려면 Enter를 누르십시오 ..."
	done
}









# 연결 목록 표시
list_connections() {
	echo "저장된 연결 :"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 새 연결을 추가하십시오
add_connection() {
	send_stats "새 연결을 추가하십시오"
	echo "새 연결을 만드는 예 :"
	echo "- 연결 이름 : my_server"
	echo "-IP 주소 : 192.168.1.100"
	echo "- 사용자 이름 : 루트"
	echo "- 포트 : 22"
	echo "------------------------"
	read -e -p "연결 이름을 입력하십시오 :" name
	read -e -p "IP 주소를 입력하십시오 :" ip
	read -e -p "사용자 이름 (기본값 : 루트)을 입력하십시오 :" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "포트 번호를 입력하십시오 (기본값 : 22) :" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "인증 방법을 선택하십시오 :"
	echo "1. 비밀번호"
	echo "2. 키"
	read -e -p "선택 (1/2)을 입력하십시오 :" auth_choice

	case $auth_choice in
		1)
			read -s -p "비밀번호를 입력하십시오 :" password_or_key
			echo  # 换行
			;;
		2)
			echo "키 내용을 붙여 넣으십시오 (붙여 넣기 후 Enter Enter를 두 번 누릅니다) :"
			local password_or_key=""
			while IFS= read -r line; do
				# 입력이 비어 있고 키 컨텐츠에 이미 시작이 포함되어 있으면 입력이 끝납니다.
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 첫 번째 줄이거나 키 컨텐츠가 입력 된 경우 계속 추가하십시오.
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# 주요 내용인지 확인하십시오
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "잘못된 선택!"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "연결이 저장됩니다!"
}



# 연결을 삭제하십시오
delete_connection() {
	send_stats "연결을 삭제하십시오"
	read -e -p "삭제하려면 연결 번호를 입력하십시오." num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "오류 : 해당 연결을 찾을 수 없었습니다."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 연결이 키 파일을 사용하는 경우 키 파일을 삭제하십시오.
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "연결이 삭제되었습니다!"
}

# 연결을 사용하십시오
use_connection() {
	send_stats "연결을 사용하십시오"
	read -e -p "사용할 연결 번호를 입력하십시오." num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "오류 : 해당 연결을 찾을 수 없었습니다."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "연결$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# 키와 연결하십시오
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "연결 실패! 다음을 확인하십시오."
			echo "1. 키 파일 경로가 정확합니까?$password_or_key"
			echo "2. 키 파일 권한이 올바른지 여부 (600이어야 함)."
			echo "3. 대상 서버가 키를 사용하여 로그인 할 수 있는지 여부."
		fi
	else
		# 비밀번호로 연결하십시오
		if ! command -v sshpass &> /dev/null; then
			echo "오류 : Sshpass가 설치되지 않았습니다. 먼저 Sshpass를 설치하십시오."
			echo "설치 방법 :"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "연결 실패! 다음을 확인하십시오."
			echo "1. 사용자 이름과 비밀번호가 올바른지 여부."
			echo "2. 대상 서버가 암호 로그인을 허용하는지 여부."
			echo "3. 대상 서버의 SSH 서비스가 정상적으로 실행되는지 여부."
		fi
	fi
}


ssh_manager() {
	send_stats "SSH 원격 연결 도구"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 구성 파일과 키 디렉토리가 존재하는지 확인하고 존재하지 않으면 작성하십시오.
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "SSH 원격 연결 도구"
		echo "SSH를 통해 다른 Linux 시스템에 연결할 수 있습니다"
		echo "------------------------"
		list_connections
		echo "1. 새 연결 만들기 2. 연결 사용 3. 연결 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "잘못된 선택, 다시 시도하십시오." ;;
		esac
	done
}












# 사용 가능한 하드 디스크 파티션을 나열하십시오
list_partitions() {
	echo "사용 가능한 하드 디스크 파티션 :"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 파티션을 장착하십시오
mount_partition() {
	send_stats "파티션을 장착하십시오"
	read -e -p "장착 할 파티션 이름을 입력하십시오 (예 : SDA1) :" PARTITION

	# 파티션이 있는지 확인하십시오
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 파티션이 이미 장착되어 있는지 확인하십시오
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "파티션은 이미 장착되어 있습니다!"
		return
	fi

	# 마운트 포인트를 만듭니다
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 파티션을 장착하십시오
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "파티션 마운트 성공적으로 :$MOUNT_POINT"
	else
		echo "파티션 마운트 실패!"
		rmdir "$MOUNT_POINT"
	fi
}

# 파티션을 제거하십시오
unmount_partition() {
	send_stats "파티션을 제거하십시오"
	read -e -p "파티션 이름 (예 : SDA1)을 입력하십시오." PARTITION

	# 파티션이 이미 장착되어 있는지 확인하십시오
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "파티션이 장착되지 않았습니다!"
		return
	fi

	# 파티션을 제거하십시오
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "파티션 분할 해제 성공 :$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "파티션 제거 실패!"
	fi
}

# 목록 장착 파티션
list_mounted_partitions() {
	echo "마운트 파티션 :"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 형식 파티션
format_partition() {
	send_stats "형식 파티션"
	read -e -p "파티션 이름을 형식 (예 : SDA1)에 입력하십시오." PARTITION

	# 파티션이 있는지 확인하십시오
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 파티션이 이미 장착되어 있는지 확인하십시오
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 장착되었습니다. 먼저 제거하십시오!"
		return
	fi

	# 파일 시스템 유형을 선택하십시오
	echo "파일 시스템 유형을 선택하십시오 :"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "선택을 입력하십시오 :" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "잘못된 선택!"; return ;;
	esac

	# 형식을 확인하십시오
	read -e -p "파티션 형식 확인 /dev /$PARTITION~을 위한$FS_TYPE그게? (Y/N) :" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "작업이 취소되었습니다."
		return
	fi

	# 형식 파티션
	echo "파티션 서식 /dev /$PARTITION~을 위한$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "파티션 형식이 성공적이었습니다!"
	else
		echo "파티션 형식이 실패했습니다!"
	fi
}

# 파티션 상태를 확인하십시오
check_partition() {
	send_stats "파티션 상태를 확인하십시오"
	read -e -p "파티션 이름을 입력하여 확인하십시오 (예 : SDA1) :" PARTITION

	# 파티션이 있는지 확인하십시오
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 파티션 상태를 확인하십시오
	echo "파티션 /개발자 /$PARTITION상태:"
	fsck "/dev/$PARTITION"
}

# 메인 메뉴
disk_manager() {
	send_stats "하드 디스크 관리 기능"
	while true; do
		clear
		echo "하드 디스크 파티션 관리"
		echo -e "${gl_huang}이 기능은 테스트 기간 동안 내부적으로 테스트되므로 생산 환경에서 사용하지 마십시오.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. 파티션 마운트 2. 파티션 3. 마운트 파티션보기"
		echo "4. 파티션 형식 5. 파티션 상태를 확인하십시오"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "계속하려면 Enter를 누르십시오 ..."
	done
}




# 작업 목록 표시
list_tasks() {
	echo "저장된 동기화 작업 :"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 새로운 작업을 추가하십시오
add_task() {
	send_stats "새 동기화 작업을 추가하십시오"
	echo "새 동기화 작업 작성 예 :"
	echo "- 작업 이름 : Backup_www"
	echo "- 로컬 디렉토리 : /var /www"
	echo "- 원격 주소 : user@192.168.1.100"
	echo "- 원격 디렉토리 : /백업 /www"
	echo "- 포트 번호 (기본 22)"
	echo "---------------------------------"
	read -e -p "작업 이름을 입력하십시오 :" name
	read -e -p "로컬 디렉토리를 입력하십시오 :" local_path
	read -e -p "원격 디렉토리를 입력하십시오 :" remote_path
	read -e -p "원격 사용자 @IP를 입력하십시오 :" remote
	read -e -p "SSH 포트 (기본값 22)를 입력하십시오 :" port
	port=${port:-22}

	echo "인증 방법을 선택하십시오 :"
	echo "1. 비밀번호"
	echo "2. 키"
	read -e -p "선택하십시오 (1/2) :" auth_choice

	case $auth_choice in
		1)
			read -s -p "비밀번호를 입력하십시오 :" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "키 내용을 붙여 넣으십시오 (붙여 넣기 후 Enter Enter를 두 번 누릅니다) :"
			local password_or_key=""
			while IFS= read -r line; do
				# 입력이 비어 있고 키 컨텐츠에 이미 시작이 포함되어 있으면 입력이 끝납니다.
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 첫 번째 줄이거나 키 컨텐츠가 입력 된 경우 계속 추가하십시오.
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# 주요 내용인지 확인하십시오
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "잘못된 키 컨텐츠!"
				return
			fi
			;;
		*)
			echo "잘못된 선택!"
			return
			;;
	esac

	echo "동기화 모드를 선택하십시오 :"
	echo "1. 표준 모드 (-avz)"
	echo "2. 대상 파일 삭제 (-avz-delete)"
	read -e -p "선택하십시오 (1/2) :" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "유효하지 않은 선택, 기본값 -AVZ를 사용하십시오"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "작업을 저장했습니다!"
}

# 작업을 삭제하십시오
delete_task() {
	send_stats "동기화 작업을 삭제합니다"
	read -e -p "삭제하려면 작업 번호를 입력하십시오." num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "오류 : 해당 작업을 찾을 수 없었습니다."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 작업이 키 파일을 사용하는 경우 키 파일을 삭제하십시오.
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "작업이 삭제되었습니다!"
}


run_task() {
	send_stats "동기화 작업을 수행하십시오"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# 매개 변수를 분석하십시오
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 들어오는 작업 번호가없는 경우 사용자에게 입력하라는 메시지를 표시하십시오.
	if [[ -z "$num" ]]; then
		read -e -p "실행할 작업 번호를 입력하십시오." num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "오류 : 작업이 찾을 수 없었습니다!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 동기화 방향에 따라 소스 및 대상 경로를 조정하십시오
	if [[ "$direction" == "pull" ]]; then
		echo "로컬로 동기화를 당기기 :$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "동기화를 원격 끝으로 푸시합니다.$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# SSH 연결 공통 매개 변수를 추가하십시오
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "오류 : Sshpass가 설치되지 않았습니다. 먼저 Sshpass를 설치하십시오."
			echo "설치 방법 :"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 키 파일이 존재하는지 여부와 권한이 올바른지 확인
		if [[ ! -f "$password_or_key" ]]; then
			echo "오류 : 키 파일이 존재하지 않습니다.$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "경고 : 키 파일 권한이 잘못되었고 수리 중입니다 ..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "동기화가 완료되었습니다!"
	else
		echo "동기화 실패! 다음을 확인하십시오."
		echo "1. 네트워크 연결이 정상입니까?"
		echo "2. 원격 호스트가 액세스 할 수 있습니까?"
		echo "3. 인증 정보가 정확합니까?"
		echo "4. 로컬 및 원격 디렉토리에 올바른 액세스 권한이 있습니까?"
	fi
}


# 시간이 정한 작업을 만듭니다
schedule_task() {
	send_stats "동기화 타이밍 작업을 추가하십시오"

	read -e -p "정기적으로 동기화 할 작업 번호를 입력하십시오." num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "오류 : 유효한 작업 번호를 입력하십시오!"
		return
	fi

	echo "시간이 정한 실행 간격을 선택하십시오."
	echo "1) 한 시간에 한 번 실행하십시오"
	echo "2) 하루에 한 번 수행하십시오"
	echo "3) 일주일에 한 번 실행하십시오"
	read -e -p "옵션을 입력하십시오 (1/2/3) :" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "오류 : 유효한 옵션을 입력하십시오!" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 동일한 작업이 이미 존재하는지 확인하십시오
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "오류 :이 작업의 타이밍 동기화가 이미 존재합니다!"
		return
	fi

	# 사용자에게 크론AB를 만듭니다
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "타이밍 작업이 만들어졌습니다.$cron_job"
}

# 예정된 작업을 봅니다
view_tasks() {
	echo "현재 타이밍 작업 :"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 타이밍 작업을 삭제하십시오
delete_task_schedule() {
	send_stats "동기화 타이밍 작업을 삭제합니다"
	read -e -p "삭제하려면 작업 번호를 입력하십시오." num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "오류 : 유효한 작업 번호를 입력하십시오!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "삭제 된 작업 번호$num타이밍 작업"
}


# 작업 관리 메인 메뉴
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "RSYNC 원격 동기화 도구"
		echo "원격 디렉토리 간의 동기화는 증분 동기화, 효율적이고 안정적인 지원을 지원합니다."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 새 작업 생성 2. 작업을 삭제하십시오"
		echo "3. 원격 끝에 로컬 동기화 수행 4. 로컬 엔드에 대한 원격 동기화 수행"
		echo "5. 타이밍 작업 만들기 6. 타이밍 작업 삭제"
		echo "---------------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "---------------------------------"
		read -e -p "선택을 입력하십시오 :" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "잘못된 선택, 다시 시도하십시오." ;;
		esac
		read -e -p "계속하려면 Enter를 누르십시오 ..."
	done
}









linux_ps() {

	clear
	send_stats "시스템 정보 쿼리"

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
	echo -e "시스템 정보 쿼리"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}호스트 이름 :${gl_bai}$hostname"
	echo -e "${gl_kjlan}시스템 버전 :${gl_bai}$os_info"
	echo -e "${gl_kjlan}리눅스 버전 :${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU 아키텍처 :${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPU 모델 :${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPU 코어 수 :${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU 주파수 :${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU 점유 :${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}시스템 부하 :${gl_bai}$load"
	echo -e "${gl_kjlan}물리적 기억 :${gl_bai}$mem_info"
	echo -e "${gl_kjlan}가상 메모리 :${gl_bai}$swap_info"
	echo -e "${gl_kjlan}하드 디스크 직업 :${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}총 수신 :${gl_bai}$rx"
	echo -e "${gl_kjlan}총 보내기 :${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}네트워크 알고리즘 :${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}연산자:${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4 주소 :${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6 주소 :${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS 주소 :${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}지리적 위치 :${gl_bai}$country $city"
	echo -e "${gl_kjlan}시스템 시간 :${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}실행 시간:${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "기본 도구"
	  echo -e "기본 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}컬 다운로드 도구${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}WGET 다운로드 도구${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Sudo Super Management 권한 도구${gl_kjlan}4.   ${gl_bai}소사이어티 커뮤니케이션 연결 도구"
	  echo -e "${gl_kjlan}5.   ${gl_bai}HTOP 시스템 모니터링 도구${gl_kjlan}6.   ${gl_bai}IFTOP 네트워크 트래픽 모니터링 도구"
	  echo -e "${gl_kjlan}7.   ${gl_bai}압축 지퍼 압축 압축 압축 도구${gl_kjlan}8.   ${gl_bai}TAR GZ 압축 감압 도구"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Tmux 다중 채널 배경 달리기 도구${gl_kjlan}10.  ${gl_bai}FFMPEG 비디오 라이브 스트리밍 도구 인코딩"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}BTOP 최신 모니터링 도구${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}범위 파일 관리 도구"
	  echo -e "${gl_kjlan}13.  ${gl_bai}NCDU 디스크 직업 관찰 도구${gl_kjlan}14.  ${gl_bai}FZF 글로벌 검색 도구"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim 텍스트 편집기${gl_kjlan}16.  ${gl_bai}나노 텍스트 편집기${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}GIT 버전 제어 시스템"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}매트릭스 화면 보증${gl_kjlan}22.  ${gl_bai}열차 스크린 보안"
	  echo -e "${gl_kjlan}26.  ${gl_bai}테트리스 게임${gl_kjlan}27.  ${gl_bai}뱀 먹는 게임"
	  echo -e "${gl_kjlan}28.  ${gl_bai}우주 침략자 게임"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}모두 설치하십시오${gl_kjlan}32.  ${gl_bai}모든 설치 (스크린 세이버 및 게임 제외)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}모든 것을 제거하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}지정된 도구를 설치하십시오${gl_kjlan}42.  ${gl_bai}지정된 도구를 제거하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  curl --help
			  send_stats "컬을 설치하십시오"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  wget --help
			  send_stats "wget을 설치하십시오"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  sudo --help
			  send_stats "Sudo를 설치하십시오"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  socat -h
			  send_stats "Socat을 설치하십시오"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "HTOP를 설치하십시오"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "iftop을 설치하십시오"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  unzip
			  send_stats "압축을 설치하십시오"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  tar --help
			  send_stats "타르를 설치하십시오"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  tmux --help
			  send_stats "tmux를 설치하십시오"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "도구가 설치되었으며 사용법은 다음과 같습니다."
			  ffmpeg --help
			  send_stats "FFMPEG를 설치하십시오"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "Btop을 설치하십시오"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "레인저를 설치하십시오"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "NCDU를 설치하십시오"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "FZF를 설치하십시오"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "VIM을 설치하십시오"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "나노를 설치하십시오"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "git을 설치하십시오"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "cmatrix를 설치하십시오"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "SL을 설치하십시오"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "Bastet을 설치하십시오"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "NSNAKE를 설치하십시오"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "Ninvaders를 설치하십시오"
			  ;;

		  31)
			  clear
			  send_stats "모두 설치하십시오"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "모든 설치 (게임 및 화면 보호기 제외)"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "모든 것을 제거하십시오"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "설치된 도구 이름 (WGET CURL SUDO HTOP)을 입력하십시오." installname
			  install $installname
			  send_stats "지정된 소프트웨어를 설치하십시오"
			  ;;
		  42)
			  clear
			  read -e -p "제거되지 않은 도구 이름 (HTOP UFW TMUX CMATRIX)을 입력하십시오." removename
			  remove $removename
			  send_stats "지정된 소프트웨어를 제거하십시오"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "BBR 관리"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			  echo "현재 TCP 차단 알고리즘 :$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR 관리"
			  echo "------------------------"
			  echo "1. BBRV3 켜기 2. BBRV3 끄기 (재시작)"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아갑니다"
			  echo "------------------------"
			  read -e -p "선택을 입력하십시오 :" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "알파인 활성화 BBR3"
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
	  # Send_stats "Docker Management"
	  echo -e "도커 관리"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Docker 환경을 설치하고 업데이트하십시오${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Docker Global Status를 봅니다${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}도커 컨테이너 관리${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}도커 이미지 관리"
	  echo -e "${gl_kjlan}5.   ${gl_bai}도커 네트워크 관리"
	  echo -e "${gl_kjlan}6.   ${gl_bai}도커 볼륨 관리"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}쓸모없는 도커 컨테이너 및 미러 네트워크 데이터 볼륨을 청소하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Docker 소스를 교체하십시오"
	  echo -e "${gl_kjlan}9.   ${gl_bai}daemon.json 파일 편집"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Docker-IPV6 액세스를 활성화하십시오"
	  echo -e "${gl_kjlan}12.  ${gl_bai}Docker-IPV6 액세스를 닫습니다"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Docker 환경을 제거하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "Docker 환경을 설치하십시오"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "도커 글로벌 상태"
			  echo "도커 버전"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "도커 이미지 :${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "도커 컨테이너 :${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "도커 볼륨 :${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "도커 네트워크 :${gl_lv}$network_count${gl_bai}"
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
				  send_stats "도커 네트워크 관리"
				  echo "도커 네트워크 목록"
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
				  echo "네트워크 작동"
				  echo "------------------------"
				  echo "1. 네트워크를 만듭니다"
				  echo "2. 인터넷에 가입하십시오"
				  echo "3. 네트워크를 종료하십시오"
				  echo "4. 네트워크를 삭제합니다"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "네트워크를 만듭니다"
						  read -e -p "새 네트워크 이름 설정 :" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "인터넷에 가입하십시오"
						  read -e -p "네트워크 이름에 가입 :" dockernetwork
						  read -e -p "해당 컨테이너는 네트워크에 추가됩니다 (여러 컨테이너 이름은 공간으로 분리됩니다)." dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "인터넷에 가입하십시오"
						  read -e -p "종료 네트워크 이름 :" dockernetwork
						  read -e -p "해당 컨테이너는 네트워크를 종료합니다 (여러 컨테이너 이름은 공간별로 분리됩니다)." dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "네트워크를 삭제하십시오"
						  read -e -p "삭제하려면 네트워크 이름을 입력하십시오." dockernetwork
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
				  send_stats "도커 볼륨 관리"
				  echo "도커 볼륨 목록"
				  docker volume ls
				  echo ""
				  echo "볼륨 작동"
				  echo "------------------------"
				  echo "1. 새 볼륨을 만듭니다"
				  echo "2. 지정된 볼륨을 삭제합니다"
				  echo "3. 모든 볼륨을 삭제하십시오"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "새 볼륨을 만듭니다"
						  read -e -p "새 볼륨 이름 설정 :" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "볼륨 삭제 이름을 입력하십시오 (공백으로 여러 볼륨 이름을 분리하십시오)." dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "모든 볼륨을 삭제하십시오"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "잘못된 선택, y 또는 N을 입력하십시오."
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
			  send_stats "도커 청소"
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "잘못된 선택, y 또는 N을 입력하십시오."
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "도커 소스"
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
			  send_stats "Docker V6 열기"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker V6 레벨"
			  docker_ipv6_off
			  ;;

		  20)
			  clear
			  send_stats "Docker는 제거합니다"
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
				  echo "잘못된 선택, y 또는 N을 입력하십시오."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # Send_stats "테스트 스크립트 컬렉션"
	  echo -e "스크립트 수집 테스트"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IP 및 잠금 해제 상태 감지"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGpt는 상태 감지를 잠금 해제합니다"
	  echo -e "${gl_kjlan}2.   ${gl_bai}지역 스트리밍 미디어 잠금 해제 테스트"
	  echo -e "${gl_kjlan}3.   ${gl_bai}YEAHWU 스트리밍 미디어 잠금 해제 탐지"
	  echo -e "${gl_kjlan}4.   ${gl_bai}XYKT IP 품질 신체 검사 스크립트${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}네트워크 속도 측정"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Besttrace 3 개의 네트워크 백홀 지연 라우팅 테스트"
	  echo -e "${gl_kjlan}12.  ${gl_bai}MTR_TRACE 3- 네트워크 백홀 라인 테스트"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Superspeed 3 Net 속도 측정"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 빠른 백홀 테스트 스크립트"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace는 ip backhaul 테스트 스크립트를 지정합니다"
	  echo -e "${gl_kjlan}16.  ${gl_bai}Ludashi2020 3 네트워크 라인 테스트"
	  echo -e "${gl_kjlan}17.  ${gl_bai}I-ABC 다기능 속도 테스트 스크립트"
	  echo -e "${gl_kjlan}18.  ${gl_bai}Netquality Network 품질 신체 검사 스크립트${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}하드웨어 성능 테스트"
	  echo -e "${gl_kjlan}21.  ${gl_bai}YABS 성능 테스트"
	  echo -e "${gl_kjlan}22.  ${gl_bai}IICU/GB5 CPU 성능 테스트 스크립트"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}포괄적 인 테스트"
	  echo -e "${gl_kjlan}31.  ${gl_bai}벤치 성능 테스트"
	  echo -e "${gl_kjlan}32.  ${gl_bai}SpiritySDX 퓨전 몬스터 검토${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "ChatGpt는 상태 감지를 잠금 해제합니다"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "지역 스트리밍 미디어 잠금 해제 테스트"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "YEAHWU 스트리밍 미디어 잠금 해제 탐지"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_ip 품질 신체 검사 스크립트"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "Besttrace 3 개의 네트워크 백홀 지연 라우팅 테스트"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "MTR_TRACE 3 개의 네트워크 리턴 라인 테스트"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "Superspeed 3 Net 속도 측정"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace 빠른 백홀 테스트 스크립트"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace는 ip backhaul 테스트 스크립트를 지정합니다"
			  echo "참조 할 수있는 IP 목록"
			  echo "------------------------"
			  echo "베이징 통신 : 219.141.136.12"
			  echo "베이징 유니폼 : 202.106.50.1"
			  echo "베이징 모바일 : 221.179.155.161"
			  echo "상하이 통신 : 202.96.209.133"
			  echo "상하이 유니폼 : 210.22.97.1"
			  echo "상하이 모바일 : 211.136.112.200"
			  echo "광저우 통신 : 58.60.188.222"
			  echo "광저우 유니폼 : 210.21.196.6"
			  echo "광저우 모바일 : 120.196.165.24"
			  echo "청두 통신 : 61.139.2.69"
			  echo "청두 유니폼 : 119.6.6.6"
			  echo "청두 모바일 : 211.137.96.205"
			  echo "Hunan Telecom : 36.111.200.100"
			  echo "후난 유니폼 : 42.48.16.100"
			  echo "후난 모바일 : 39.134.254.6"
			  echo "------------------------"

			  read -e -p "지정된 IP를 입력하십시오." testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "Ludashi2020 3 네트워크 라인 테스트"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "I-ABC 다기능 속도 테스트 스크립트"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "네트워크 품질 테스트 스크립트"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "YABS 성능 테스트"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "IICU/GB5 CPU 성능 테스트 스크립트"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "벤치 성능 테스트"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "SpiritySDX 퓨전 몬스터 검토"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "Oracle Cloud 스크립트 컬렉션"
	  echo -e "Oracle Cloud 스크립트 컬렉션"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}유휴 기계 활성 스크립트를 설치하십시오"
	  echo -e "${gl_kjlan}2.   ${gl_bai}유휴 기계 활성 스크립트를 제거하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD 다시 설치 시스템 스크립트"
	  echo -e "${gl_kjlan}4.   ${gl_bai}형사 R 스크립트 시작"
	  echo -e "${gl_kjlan}5.   ${gl_bai}루트 비밀번호 로그인 모드를 켭니다"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPv6 복구 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "활성 스크립트 : CPU는 10-20% 메모리를 점유합니다."
			  read -e -p "설치 하시겠습니까? (Y/N) :" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # 기본값을 설정합니다
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # 사용자에게 CPU 코어 수와 점유율 백분율을 입력하라는 메시지를 표시하고 입력 한 경우 기본값을 사용하십시오.
				  read -e -p "CPU 코어 수를 입력하십시오 [기본값 :$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "CPU 사용 백분율 범위 (예 : 10-20) [기본값 :$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "메모리 사용 백분율을 입력하십시오 [기본값 :$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "스피드 테스트 간격 시간 (초)을 입력하십시오 [기본값 :$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # 도커 컨테이너를 실행하십시오
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "Oracle Cloud 설치 활성 스크립트"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "잘못된 선택, y 또는 N을 입력하십시오."
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "Oracle Cloud는 활성 스크립트를 제거합니다"
			  ;;

		  3)
		  clear
		  echo "시스템을 다시 설치하십시오"
		  echo "--------------------------------"
		  echo -e "${gl_hong}알아채다:${gl_bai}다시 설치는 접촉을 잃을 위험이 있으며 걱정하는 사람들은 그것을주의해서 사용해야합니다. 재설치는 15 분이 걸릴 것으로 예상됩니다. 데이터를 미리 백업하십시오."
		  read -e -p "계속할거야? (Y/N) :" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "다시 설치할 시스템을 선택하십시오 : 1. Debian12 | 2. Ubuntu20.04 :" sys_choice

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
					echo "유효하지 않은 선택, 다시 입력하십시오."
					;;
				esac
			  done

			  read -e -p "다시 설치 한 비밀번호를 입력하십시오." vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "Oracle Cloud 회복 시스템 스크립트"
			  ;;
			[Nn])
			  echo "취소"
			  ;;
			*)
			  echo "잘못된 선택, y 또는 N을 입력하십시오."
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  echo "이 기능은 개발 단계에 있으므로 계속 지켜봐 주시기 바랍니다!"
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "이 기능은 마스터 JHB가 제공합니다."
			  send_stats "IPv6 수정"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "잘못된 입력!"
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
		echo -e "${gl_lv}환경이 설치되었습니다${gl_bai}컨테이너:${gl_lv}$container_count${gl_bai}거울:${gl_lv}$image_count${gl_bai}회로망:${gl_lv}$network_count${gl_bai}연타:${gl_lv}$volume_count${gl_bai}"
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
		echo -e "${gl_lv}환경이 설치됩니다${gl_bai}  $output  $db_output"
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
	# send_stats "ldnmp 웹 사이트 빌딩"
	echo -e "${gl_huang}LDNMP 웹 사이트 구축"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}LDNMP 환경을 설치하십시오${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}WordPress를 설치하십시오${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}Discuz 포럼을 설치하십시오${gl_huang}4.   ${gl_bai}Kadao 클라우드 데스크탑을 설치하십시오"
	echo -e "${gl_huang}5.   ${gl_bai}Apple CMS 영화 및 텔레비전 방송국을 설치하십시오${gl_huang}6.   ${gl_bai}유니콘 디지털 카드 네트워크를 설치하십시오"
	echo -e "${gl_huang}7.   ${gl_bai}Flarum Forum 웹 사이트를 설치하십시오${gl_huang}8.   ${gl_bai}Typecho Lightweight 블로그 웹 사이트를 설치하십시오"
	echo -e "${gl_huang}9.   ${gl_bai}LinkStack 공유 링크 플랫폼을 설치하십시오${gl_huang}20.  ${gl_bai}동적 사이트를 사용자 정의합니다"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}nginx 만 설치하십시오${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}사이트 리디렉션"
	echo -e "${gl_huang}23.  ${gl_bai}사이트 리버스 프록시 -IP+포트${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}사이트 리버스 프록시 - 도메인 이름"
	echo -e "${gl_huang}25.  ${gl_bai}Bitwarden 비밀번호 관리 플랫폼을 설치하십시오${gl_huang}26.  ${gl_bai}후광 블로그 웹 사이트를 설치하십시오"
	echo -e "${gl_huang}27.  ${gl_bai}AI 페인팅 프롬프트 워드 생성기를 설치하십시오${gl_huang}28.  ${gl_bai}사이트 리버스 프록시로드 밸런싱"
	echo -e "${gl_huang}30.  ${gl_bai}정적 사이트를 사용자 정의합니다"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}사이트 데이터 관리${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}전체 사이트 데이터를 백업합니다"
	echo -e "${gl_huang}33.  ${gl_bai}시간이 지정된 원격 백업${gl_huang}34.  ${gl_bai}전체 사이트 데이터를 복원하십시오"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}LDNMP 환경을 보호하십시오${gl_huang}36.  ${gl_bai}LDNMP 환경을 최적화하십시오"
	echo -e "${gl_huang}37.  ${gl_bai}LDNMP 환경을 업데이트하십시오${gl_huang}38.  ${gl_bai}LDNMP 환경을 제거하십시오"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "선택을 입력하십시오 :" sub_choice


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
	  # Discuz 포럼
	  webname="Discuz论坛"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo "데이터베이스 주소 : MySQL"
	  echo "데이터베이스 이름 :$dbname"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
	  echo "테이블 접두사 : discuz_"


		;;

	  4)
	  clear
	  # Kedao 클라우드 데스크탑
	  webname="可道云桌面"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo "데이터베이스 주소 : MySQL"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
	  echo "데이터베이스 이름 :$dbname"
	  echo "Redis 호스트 : Redis"

		;;

	  5)
	  clear
	  # Apple CMS
	  webname="苹果CMS"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo "데이터베이스 주소 : MySQL"
	  echo "데이터베이스 포트 : 3306"
	  echo "데이터베이스 이름 :$dbname"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
	  echo "데이터베이스 접두사 : MAC_"
	  echo "------------------------"
	  echo "설치가 성공한 후 배경 주소에 로그인하십시오."
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 한 다리 카운팅 카드
	  webname="独脚数卡"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo "데이터베이스 주소 : MySQL"
	  echo "데이터베이스 포트 : 3306"
	  echo "데이터베이스 이름 :$dbname"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
	  echo ""
	  echo "Redis 주소 : Redis"
	  echo "Redis Password : 기본적으로 채워지지 않습니다"
	  echo "Redis Port : 6379"
	  echo ""
	  echo "웹 사이트 URL : https : //$yuming"
	  echo "백그라운드 로그인 경로 : /admin"
	  echo "------------------------"
	  echo "사용자 이름 : 관리자"
	  echo "비밀번호 : 관리자"
	  echo "------------------------"
	  echo "로그인 할 때 오른쪽 상단에 빨간색 Error0이 나타나면 다음 명령을 사용하십시오."
	  echo "나는 또한 유니콘 번호 카드가 너무 귀찮다는 것에 대해 매우 화가 났으며 그러한 문제가있을 것입니다!"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # Flarum 포럼
	  webname="flarum论坛"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo "데이터베이스 주소 : MySQL"
	  echo "데이터베이스 이름 :$dbname"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
	  echo "테이블 접두사 : flarum_"
	  echo "관리자 정보는 직접 설정됩니다"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo "데이터베이스 접두사 : typecho_"
	  echo "데이터베이스 주소 : MySQL"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
	  echo "데이터베이스 이름 :$dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo "데이터베이스 주소 : MySQL"
	  echo "데이터베이스 포트 : 3306"
	  echo "데이터베이스 이름 :$dbname"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo -e "[${gl_huang}1/6${gl_bai}] PHP 소스 코드를 업로드하십시오"
	  echo "-------------"
	  echo "현재 Zip-Format 소스 코드 패키지 만 허용됩니다. 소스 코드 패키지를/home/web/html에 넣으십시오.${yuming}디렉토리에서"
	  read -e -p "다운로드 링크를 입력하여 소스 코드 패키지를 원격으로 다운로드 할 수도 있습니다. 원격 다운로드를 건너 뛰려면 Enter를 직접 누르십시오." url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] index.php가있는 경로"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "(/home/web/html/와 유사한 Index.php의 경로를 입력하십시오.$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] PHP 버전을 선택하십시오"
	  echo "-------------"
	  read -e -p "1. PHP의 최신 버전 | 2. PHP7.4 :" pho_v
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
		  echo "유효하지 않은 선택, 다시 입력하십시오."
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] 지정된 확장자를 설치하십시오"
	  echo "-------------"
	  echo "설치된 확장"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] 사이트 구성 편집"
	  echo "-------------"
	  echo "계속하려면 모든 키를 누르면 의사 정적 내용 등과 같은 사이트 구성을 자세히 설정할 수 있습니다."
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] 데이터베이스 관리"
	  echo "-------------"
	  read -e -p "1. 새 사이트를 구축합니다. 2. 이전 사이트를 작성하고 데이터베이스 백업이 있습니다." use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "데이터베이스 백업은 .gz-end 압축 패키지 여야합니다. Pagoda/1Panel의 백업 데이터 가져 오기를 지원하려면/홈/디렉토리에 넣으십시오."
			  read -e -p "다운로드 링크를 입력하여 백업 데이터를 원격으로 다운로드 할 수도 있습니다. Enter가 직접 누르면 원격 다운로드를 건너 뜁니다." url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "데이터베이스 가져 오기 테이블 데이터"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "데이터베이스 가져 오기가 완료되었습니다"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "데이터베이스 주소 : MySQL"
	  echo "데이터베이스 이름 :$dbname"
	  echo "사용자 이름 :$dbuse"
	  echo "비밀번호:$dbusepasswd"
	  echo "테이블 접두사 :$prefix"
	  echo "관리자 로그인 정보는 직접 설정됩니다"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
	  add_yuming
	  read -e -p "점프 도메인 이름을 입력하십시오 :" reverseproxy
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
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
	  add_yuming
	  echo -e "도메인 이름 형식 :${gl_huang}google.com${gl_bai}"
	  read -e -p "반세기 도메인 이름을 입력하십시오 :" fandai_yuming
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
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  send_stats "설치하다$webname"
	  echo "배포를 시작하십시오$webname"
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
	  echo -e "[${gl_huang}1/2${gl_bai}] 정적 소스 코드를 업로드하십시오"
	  echo "-------------"
	  echo "현재 Zip-Format 소스 코드 패키지 만 허용됩니다. 소스 코드 패키지를/home/web/html에 넣으십시오.${yuming}디렉토리에서"
	  read -e -p "다운로드 링크를 입력하여 소스 코드 패키지를 원격으로 다운로드 할 수도 있습니다. 원격 다운로드를 건너 뛰려면 Enter를 직접 누르십시오." url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] index.html이있는 경로"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "(/home/web/html/와 유사한 index.html로가는 경로를 입력하십시오.$yuming/index/）： " index_lujing

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
	  send_stats "LDNMP 환경 백업"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}백업$backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "백업 파일이 작성되었습니다 : /home /$backup_filename"
		read -e -p "백업 데이터를 원격 서버로 전송 하시겠습니까? (Y/N) :" choice
		case "$choice" in
		  [Yy])
			read -e -p "원격 서버 IP를 입력하십시오 :" remote_ip
			if [ -z "$remote_ip" ]; then
			  echo "오류 : 원격 서버 IP를 입력하십시오."
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "파일은 원격 서버 홈 디렉토리로 전송되었습니다."
			else
			  echo "전송할 파일은 찾을 수 없었습니다."
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "잘못된 선택, y 또는 N을 입력하십시오."
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "시간이 지정된 원격 백업"
	  read -e -p "원격 서버 IP를 입력하십시오." useip
	  read -e -p "원격 서버 비밀번호를 입력하십시오." usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. 주간 백업 2. 매일 백업"
	  read -e -p "선택을 입력하십시오 :" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "주간 백업의 요일을 선택하십시오 (0-6, 0은 일요일을 나타냅니다) :" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "매일 백업 시간을 선택하십시오 (시간, 0-23) :" hour
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
	  send_stats "LDNMP 환경 복원"
	  echo "사용 가능한 사이트 백업"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "최신 백업을 복원하려면 입력하고 백업 파일 이름을 입력하여 지정된 백업을 복원하고 0을 입력하려면 다음을 종료하십시오." filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # 사용자가 파일 이름을 입력하지 않으면 최신 압축 패키지를 사용하십시오.
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}감압이 수행되고 있습니다$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "압축 패키지가 발견되지 않았습니다."
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
		  send_stats "LDNMP 환경을 업데이트하십시오"
		  echo "LDNMP 환경을 업데이트하십시오"
		  echo "------------------------"
		  ldnmp_v
		  echo "구성 요소의 새 버전을 발견하십시오"
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
		  echo "1. Nginx 업데이트 2. MySQL 업데이트 3. PHP 업데이트 4. Redis 업데이트"
		  echo "------------------------"
		  echo "5. 전체 환경을 업데이트하십시오"
		  echo "------------------------"
		  echo "0. 이전 메뉴로 돌아갑니다"
		  echo "------------------------"
		  read -e -p "선택을 입력하십시오 :" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "입력하십시오${ldnmp_pods}버전 번호 (예 : 8.0 8.3 8.4 9.0) (최신 버전을 얻으려면 입력) :" version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "고쳐 쓰다$ldnmp_pods"
			  echo "고쳐 쓰다${ldnmp_pods}마치다"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "입력하십시오${ldnmp_pods}버전 번호 (예 : 7.4 8.0 8.1 8.2 8.3) (최신 버전을 얻으려면 입력) :" version
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
			  send_stats "고쳐 쓰다$ldnmp_pods"
			  echo "고쳐 쓰다${ldnmp_pods}마치다"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  restart_redis
			  send_stats "고쳐 쓰다$ldnmp_pods"
			  echo "고쳐 쓰다${ldnmp_pods}마치다"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "LDNMP 환경을 완전히 업데이트하십시오"
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
		send_stats "LDNMP 환경을 제거하십시오"
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
			echo "잘못된 선택, y 또는 N을 입력하십시오."
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "잘못된 입력!"
	esac
	break_end

  done

}



linux_panel() {

	while true; do
	  clear
	  # Send_stats "앱 시장"
	  echo -e "응용 프로그램 시장"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Baota 패널의 공식 버전${gl_kjlan}2.   ${gl_bai}Aapanel International Edition"
	  echo -e "${gl_kjlan}3.   ${gl_bai}1 파넬 신세대 관리 패널${gl_kjlan}4.   ${gl_bai}nginxproxymanager 시각적 패널"
	  echo -e "${gl_kjlan}5.   ${gl_bai}OpenList 멀티 스토어 파일 목록 프로그램${gl_kjlan}6.   ${gl_bai}우분투 원격 데스크탑 웹 에디션"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Nezha 프로브 VPS 모니터링 패널${gl_kjlan}8.   ${gl_bai}QB 오프라인 BT 자기 다운로드 패널"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Poste.io 메일 서버 프로그램${gl_kjlan}10.  ${gl_bai}Rocketchat 멀티 플레이어 온라인 채팅 시스템"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Zendao 프로젝트 관리 소프트웨어${gl_kjlan}12.  ${gl_bai}Qinglong 패널 시간 작업 관리 플랫폼"
	  echo -e "${gl_kjlan}13.  ${gl_bai}CloudReve 네트워크 디스크${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}간단한 그림 침대 그림 관리 프로그램"
	  echo -e "${gl_kjlan}15.  ${gl_bai}EMBY 멀티미디어 관리 시스템${gl_kjlan}16.  ${gl_bai}스피드 테스트 속도 테스트 패널"
	  echo -e "${gl_kjlan}17.  ${gl_bai}Adguardhome Adware${gl_kjlan}18.  ${gl_bai}Office Office Online Office Office"
	  echo -e "${gl_kjlan}19.  ${gl_bai}썬더 풀 WAF 방화벽 패널${gl_kjlan}20.  ${gl_bai}Portainer 컨테이너 관리 패널"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}VSCODE 웹 버전${gl_kjlan}22.  ${gl_bai}Uptimekuma 모니터링 도구"
	  echo -e "${gl_kjlan}23.  ${gl_bai}메모 웹 페이지 메모${gl_kjlan}24.  ${gl_bai}WebTop 원격 데스크탑 웹 에디션${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${gl_bai}NextCloud 네트워크 디스크${gl_kjlan}26.  ${gl_bai}QD-Today 타이밍 작업 관리 프레임 워크"
	  echo -e "${gl_kjlan}27.  ${gl_bai}도크 컨테이너 스택 관리 패널${gl_kjlan}28.  ${gl_bai}Librespeed 속도 테스트 도구"
	  echo -e "${gl_kjlan}29.  ${gl_bai}searxng 집계 검색 사이트${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}Photoprism 개인 앨범 시스템"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Stirlingpdf 도구 컬렉션${gl_kjlan}32.  ${gl_bai}Drawio 무료 온라인 차트 소프트웨어${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}썬 패널 탐색 패널${gl_kjlan}34.  ${gl_bai}Pingvin-Share 파일 공유 플랫폼"
	  echo -e "${gl_kjlan}35.  ${gl_bai}미니멀리스트 친구들${gl_kjlan}36.  ${gl_bai}LobeChatai 채팅 집계 웹 사이트"
	  echo -e "${gl_kjlan}37.  ${gl_bai}MYIP 도구 상자${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}Xiaoya Alist 가족 버킷"
	  echo -e "${gl_kjlan}39.  ${gl_bai}Bilililive 라이브 방송 녹음 도구${gl_kjlan}40.  ${gl_bai}Websh 웹 버전 SSH 연결 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}마우스 관리 패널${gl_kjlan}42.  ${gl_bai}Nexte 원격 연결 도구"
	  echo -e "${gl_kjlan}43.  ${gl_bai}Rustdesk 원격 책상 (서버)${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}Rustdesk 원격 책상 (릴레이)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${gl_bai}도커 가속 스테이션${gl_kjlan}46.  ${gl_bai}Github Acceleration Station${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${gl_bai}프로 메테우스 모니터링${gl_kjlan}48.  ${gl_bai}프로 메테우스 (호스트 모니터링)"
	  echo -e "${gl_kjlan}49.  ${gl_bai}Prometheus (컨테이너 모니터링)${gl_kjlan}50.  ${gl_bai}보충 모니터링 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${gl_bai}PVE 치킨 패널${gl_kjlan}52.  ${gl_bai}DPANEL 컨테이너 관리 패널"
	  echo -e "${gl_kjlan}53.  ${gl_bai}llama3 채팅 AI 모델${gl_kjlan}54.  ${gl_bai}AMH 호스트 웹 사이트 빌딩 관리 패널"
	  echo -e "${gl_kjlan}55.  ${gl_bai}FRP 인트라넷 침투 (서버 측)${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${gl_bai}FRP 인트라넷 침투 (클라이언트)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${gl_bai}DeepSeek 채팅 AI 큰 모델${gl_kjlan}58.  ${gl_bai}Dify Big Model 지식 기반${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${gl_bai}Newapi 큰 모델 자산 관리${gl_kjlan}60.  ${gl_bai}점프 서버 오픈 소스 요새 기계"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${gl_bai}온라인 번역 서버${gl_kjlan}62.  ${gl_bai}래그 플로 큰 모델 지식 기반"
	  echo -e "${gl_kjlan}63.  ${gl_bai}OpenWebui 자체 호스팅 AI 플랫폼${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}it-tools 도구 상자"
	  echo -e "${gl_kjlan}65.  ${gl_bai}N8N 자동화 워크 플로 플랫폼${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}YT-DLP 비디오 다운로드 도구"
	  echo -e "${gl_kjlan}67.  ${gl_bai}DDNS-GO 동적 DNS 관리 도구${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${gl_bai}AllInsSL 인증서 관리 플랫폼"
	  echo -e "${gl_kjlan}69.  ${gl_bai}sftpgo 파일 전송 도구${gl_kjlan}70.  ${gl_bai}Astrbot 채팅 로봇 프레임 워크"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}71.  ${gl_bai}Navidrome 개인 음악 서버${gl_kjlan}72.  ${gl_bai}Bitwarden 비밀번호 관리자${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${gl_bai}Libretv 개인 영화 및 텔레비전${gl_kjlan}74.  ${gl_bai}Moontv 개인 영화"
	  echo -e "${gl_kjlan}75.  ${gl_bai}멜로디 음악 엘프${gl_kjlan}76.  ${gl_bai}온라인 dos 오래된 게임"
	  echo -e "${gl_kjlan}77.  ${gl_bai}천둥 오프라인 다운로드 도구${gl_kjlan}78.  ${gl_bai}Pandawiki 지능형 문서 관리 시스템"
	  echo -e "${gl_kjlan}79.  ${gl_bai}Beszel 서버 모니터링"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

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
			send_stats "Nezha를 구축하십시오"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "Nezha 모니터링$check_docker $update_status"
				echo "오픈 소스, 가볍고 사용하기 쉬운 서버 모니터링 및 작동 및 유지 보수 도구"
				echo "공식 웹 사이트 구성 문서 : https://nezha.wiki/guide/dashboard.html"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1. 사용"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" choice

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
			send_stats "우체국을 건설하십시오"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "우체국 서비스$check_docker $update_status"
				echo "Poste.io는 오픈 소스 메일 서버 솔루션입니다."
				echo "비디오 소개 : https://www.bilibili.com/video/bv1wv421c71t?t=0.1"

				echo ""
				echo "포트 감지"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
				  echo -e "${gl_lv}포트$port현재 사용 가능합니다${gl_bai}"
				else
				  echo -e "${gl_hong}포트$port현재 사용할 수 없습니다${gl_bai}"
				fi
				echo ""

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "액세스 주소 :"
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. 설치 2. 업데이트 3. 제거"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" choice

				case $choice in
					1)
						check_disk_space 2
						read -e -p "이메일 도메인 이름 (예 : Mail.yuming.com)을 설정하십시오." yuming
						mkdir -p /home/docker
						echo "$yuming" > /home/docker/mail.txt
						echo "------------------------"
						ip_address
						echo "이 DNS 레코드를 먼저 구문 분석하십시오"
						echo "A           mail            $ipv4_address"
						echo "CNAME       imap            $yuming"
						echo "CNAME       pop             $yuming"
						echo "CNAME       smtp            $yuming"
						echo "MX          @               $yuming"
						echo "TXT         @               v=spf1 mx ~all"
						echo "TXT         ?               ?"
						echo ""
						echo "------------------------"
						echo "계속하려면 키를 누르십시오 ..."
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
						echo "Poste.io가 설치되었습니다"
						echo "------------------------"
						echo "다음 주소를 사용하여 Poste.io에 액세스 할 수 있습니다."
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
						echo "Poste.io가 설치되었습니다"
						echo "------------------------"
						echo "다음 주소를 사용하여 Poste.io에 액세스 할 수 있습니다."
						echo "https://$yuming"
						echo ""
						;;
					3)
						docker rm -f mailserver
						docker rmi -f analogic/poste.io
						rm /home/docker/mail.txt
						rm -rf /home/docker/mail
						echo "앱이 제거되었습니다"
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
				echo "설치"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "Rocket.chat이 설치되었습니다"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "앱이 제거되었습니다"
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
				echo "설치"
				check_docker_app_ip
			}


			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}


			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "앱이 제거되었습니다"
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
			send_stats "천둥 수영장을 건설하십시오"

			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "썬더 풀 서비스$check_docker"
				echo "Lei Chi는 변경 기술이 개발 한 WAF 사이트 방화벽 프로그램 패널로, 자동 방어를 위해 대행사 사이트를 역전시킬 수 있습니다."
				echo "비디오 소개 : https://www.bilibili.com/video/bv1mz421t74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. 설치 2. 업데이트 3. 비밀번호 재설정 4. 제거"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" choice

				case $choice in
					1)
						install_docker
						check_disk_space 5
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
						clear
						echo "Thunder Pool WAF 패널이 설치되었습니다"
						check_docker_app_ip
						docker exec safeline-mgt resetadmin

						;;

					2)
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
						docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
						echo ""
						clear
						echo "Thunder Pool WAF 패널이 업데이트되었습니다"
						check_docker_app_ip
						;;
					3)
						docker exec safeline-mgt resetadmin
						;;
					4)
						cd /data/safeline
						docker compose down --rmi all
						echo "기본 설치 디렉토리 인 경우 프로젝트가 제거되었습니다. 설치 디렉토리를 사용자 정의하는 경우 직접 실행하려면 설치 디렉토리로 이동해야합니다."
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
			local docker_url="공식 웹 사이트 소개 :${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
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
			send_stats "Xiaoya 가족 버킷"
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
				echo "설치"
				check_docker_app_ip
				echo "초기 사용자 이름과 비밀번호는 다음과 같습니다"
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
				echo "앱이 제거되었습니다"
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
			send_stats "PVE 치킨"
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
				echo "설치"
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
				echo "앱이 제거되었습니다"
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
				echo "설치"
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
				echo "설치"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "앱이 제거되었습니다"
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
				echo "설치"
				check_docker_app_ip
				echo "초기 사용자 이름 : 관리자"
				echo "초기 비밀번호 : changeme"
			}


			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "앱이 업데이트되었습니다"
			}


			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "앱이 제거되었습니다"
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
				echo "설치"
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
				echo "앱이 제거되었습니다"
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

				read -e -p "libretv 로그인 비밀번호 설정 :" app_passwd

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

				read -e -p "MOONTV 로그인 비밀번호 설정 :" app_passwd

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

				read -e -p "설정${docker_name}로그인 사용자 이름 :" app_use
				read -e -p "설정${docker_name}로그인 비밀번호 :" app_passwd

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
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end

	done
}


linux_work() {

	while true; do
	  clear
	  send_stats "백엔드 작업 공간"
	  echo -e "백엔드 작업 공간"
	  echo -e "이 시스템은 백엔드에서 실행할 수있는 작업 공간을 제공하며 장기 작업을 수행하는 데 사용할 수 있습니다."
	  echo -e "SSH를 분리하더라도 작업 공간의 작업이 중단되지 않으며 백그라운드의 작업이 거주됩니다."
	  echo -e "${gl_huang}힌트:${gl_bai}작업 공간에 입력 한 후 Ctrl+B를 사용하고 D 만 눌러 작업 공간을 종료하십시오!"
	  echo -e "${gl_kjlan}------------------------"
	  echo "현재 기존 작업 공간 목록"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}작업 공간 번호 1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}작업 공간 2 번"
	  echo -e "${gl_kjlan}3.   ${gl_bai}작업 공간 번호 3"
	  echo -e "${gl_kjlan}4.   ${gl_bai}작업 공간 No. 4"
	  echo -e "${gl_kjlan}5.   ${gl_bai}작업 공간 번호 5"
	  echo -e "${gl_kjlan}6.   ${gl_bai}작업 공간 No. 6"
	  echo -e "${gl_kjlan}7.   ${gl_bai}작업 공간 번호 7"
	  echo -e "${gl_kjlan}8.   ${gl_bai}작업 공간 번호 8"
	  echo -e "${gl_kjlan}9.   ${gl_bai}작업 공간 No. 9"
	  echo -e "${gl_kjlan}10.  ${gl_bai}작업 공간 번호 10"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH 거주 모드${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}작업 공간을 작성/입력하십시오"
	  echo -e "${gl_kjlan}23.  ${gl_bai}배경 작업 공간에 명령을 주입합니다"
	  echo -e "${gl_kjlan}24.  ${gl_bai}지정된 작업 공간을 삭제하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
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
			  send_stats "SSH 거주 모드"
			  echo -e "SSH 거주 모드${tmux_sshd_status}"
			  echo "SSH 연결이 활성화 된 후에는 거주 모드에 직접 입력하여 이전 작업 상태로 돌아갑니다."
			  echo "------------------------"
			  echo "1. 2를 켜십시오. 2를 끕니다"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아갑니다"
			  echo "------------------------"
			  read -e -p "선택을 입력하십시오 :" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "작업 공간을 시작하십시오$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\ n# 자동으로 tmux 세션을 입력 \ nif [[-z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
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
			  read -e -p "1001 KJ001 Work1과 같이 생성하거나 입력 한 작업 공간의 이름을 입력하십시오." SESSION_NAME
			  tmux_run
			  send_stats "사용자 정의 작업 공간"
			  ;;


		  23)
			  read -e -p "Curl -fssl https://get.docker.com | 쉿:" tmuxd
			  tmux_run_d
			  send_stats "배경 작업 공간에 명령을 주입합니다"
			  ;;

		  24)
			  read -e -p "삭제하려는 작업 공간의 이름을 입력하십시오." gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "작업 공간을 삭제합니다"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # Send_stats "시스템 도구"
	  echo -e "시스템 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}스크립트 스타트 업 단축키 키를 설정하십시오${gl_kjlan}2.   ${gl_bai}로그인 암호를 수정하십시오"
	  echo -e "${gl_kjlan}3.   ${gl_bai}루트 암호 로그인 모드${gl_kjlan}4.   ${gl_bai}지정된 버전의 Python을 설치하십시오"
	  echo -e "${gl_kjlan}5.   ${gl_bai}모든 포트를 엽니 다${gl_kjlan}6.   ${gl_bai}SSH 연결 포트를 수정하십시오"
	  echo -e "${gl_kjlan}7.   ${gl_bai}DNS 주소를 최적화합니다${gl_kjlan}8.   ${gl_bai}원 클릭 복직 시스템${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}루트 계정을 비활성화하여 새 계정을 생성하십시오${gl_kjlan}10.  ${gl_bai}우선 순위 IPv4/IPv6을 전환하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}항구 직업 상태를 확인하십시오${gl_kjlan}12.  ${gl_bai}가상 메모리 크기를 수정합니다"
	  echo -e "${gl_kjlan}13.  ${gl_bai}사용자 관리${gl_kjlan}14.  ${gl_bai}사용자/비밀번호 생성기"
	  echo -e "${gl_kjlan}15.  ${gl_bai}시스템 시간대 조정${gl_kjlan}16.  ${gl_bai}BBR3 가속도를 설정하십시오"
	  echo -e "${gl_kjlan}17.  ${gl_bai}방화벽 고급 관리자${gl_kjlan}18.  ${gl_bai}호스트 이름을 수정하십시오"
	  echo -e "${gl_kjlan}19.  ${gl_bai}스위치 시스템 업데이트 소스${gl_kjlan}20.  ${gl_bai}타이밍 작업 관리"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}기본 호스트 구문 분석${gl_kjlan}22.  ${gl_bai}SSH 방어 프로그램"
	  echo -e "${gl_kjlan}23.  ${gl_bai}현재 한도의 자동 종료${gl_kjlan}24.  ${gl_bai}루트 비공개 키 로그인 모드"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-BOT 시스템 모니터링 및 조기 경고${gl_kjlan}26.  ${gl_bai}OpenSsh 고위험 취약점 수정 (Xiuyuan)"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat Linux 커널 업그레이드${gl_kjlan}28.  ${gl_bai}Linux 시스템에서 커널 매개 변수의 최적화${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}바이러스 스캐닝 도구${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}파일 관리자"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}스위치 시스템 언어${gl_kjlan}32.  ${gl_bai}명령 라인 미화 도구${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}시스템 재활용 빈을 설정하십시오${gl_kjlan}34.  ${gl_bai}시스템 백업 및 복구"
	  echo -e "${gl_kjlan}35.  ${gl_bai}SSH 원격 연결 도구${gl_kjlan}36.  ${gl_bai}하드 디스크 파티션 관리 도구"
	  echo -e "${gl_kjlan}37.  ${gl_bai}명령 줄 기록${gl_kjlan}38.  ${gl_bai}RSYNC 원격 동기화 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}게시판${gl_kjlan}66.  ${gl_bai}원 스톱 시스템 최적화${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}서버를 다시 시작하십시오${gl_kjlan}100. ${gl_bai}개인 정보 및 보안"
	  echo -e "${gl_kjlan}101. ${gl_bai}K 명령의 고급 사용${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}기술 라이온 스크립트를 제거하십시오"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "바로 가기 키를 입력하십시오 (종료하려면 0을 입력하십시오) :" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "바로 가기 키가 설정되어 있습니다"
				  send_stats "스크립트 바로 가기 키가 설정되었습니다"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "로그인 비밀번호를 설정하십시오"
			  echo "로그인 비밀번호를 설정하십시오"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "루트 비밀번호 모드"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "PY 버전 관리"
			echo "파이썬 버전 관리"
			echo "비디오 소개 : https://www.bilibili.com/video/bv1pm42157ck?t=0.1"
			echo "---------------------------------------"
			echo "이 기능은 Python에서 공식적으로 지원되는 모든 버전을 완벽하게 설치합니다!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "현재 파이썬 버전 번호 :${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "권장 버전 : 3.12 3.11 3.10 3.9 3.8 2.7"
			echo "더 많은 버전 : https://www.python.org/downloads/"
			echo "------------"
			read -e -p "설치하려는 Python 버전 번호를 입력하십시오 (종료하려면 0을 입력하십시오) :" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "스크립트 PY 관리"
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
					echo "알 수없는 패키지 관리자!"
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
			echo -e "현재 파이썬 버전 번호 :${gl_huang}$VERSION${gl_bai}"
			send_stats "스크립트 Py 버전을 스위치하십시오"

			  ;;

		  5)
			  root_use
			  send_stats "포트 열기"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "모든 포트가 열려 있습니다"

			  ;;
		  6)
			root_use
			send_stats "SSH 포트를 수정하십시오"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# 현재 SSH 포트 번호를 읽으십시오
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 현재 SSH 포트 번호를 인쇄하십시오
				echo -e "현재 SSH 포트 번호는 다음과 같습니다.${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "1 ~ 65535 범위의 포트 번호가있는 숫자 (종료하려면 0을 입력하십시오)"

				# 사용자에게 새 SSH 포트 번호를 입력하라는 메시지
				read -e -p "새로운 SSH 포트 번호를 입력하십시오 :" new_port

				# 포트 번호가 유효한 범위 내에 있는지 확인
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSH 포트가 수정되었습니다"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "SSH 포트 수정을 종료하십시오"
						break
					else
						echo "포트 번호는 유효하지 않으며 1에서 65535 사이의 숫자를 입력하십시오."
						send_stats "잘못된 SSH 포트 입력"
						break_end
					fi
				else
					echo "입력이 유효하지 않으므로 번호를 입력하십시오."
					send_stats "잘못된 SSH 포트 입력"
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
			send_stats "신규 사용자는 루트를 비활성화합니다"
			read -e -p "새 사용자 이름을 입력하십시오 (종료하려면 0을 입력하십시오) :" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "작업이 완료되었습니다."
			;;


		  10)
			root_use
			send_stats "V4/V6 우선 순위를 설정하십시오"
			while true; do
				clear
				echo "V4/V6 우선 순위를 설정하십시오"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "현재 네트워크 우선 순위 설정 :${gl_huang}IPv4${gl_bai}우선 사항"
				else
					echo -e "현재 네트워크 우선 순위 설정 :${gl_huang}IPv6${gl_bai}우선 사항"
				fi
				echo ""
				echo "------------------------"
				echo "1. IPv4 우선 순위 2. IPv6 우선 순위 3. IPv6 수리 도구"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선호하는 네트워크를 선택하십시오." choice

				case $choice in
					1)
						sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
						echo "IPv4 우선 순위로 전환되었습니다"
						send_stats "IPv4 우선 순위로 전환되었습니다"
						;;
					2)
						sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
						echo "IPv6 우선 순위로 전환되었습니다"
						send_stats "IPv6 우선 순위로 전환되었습니다"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "이 기능은 마스터 JHB가 제공합니다."
						send_stats "IPv6 수정"
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
			send_stats "가상 메모리를 설정합니다"
			while true; do
				clear
				echo "가상 메모리를 설정합니다"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "현재 가상 메모리 :${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 1024m 2. 할당 2048m 3. 4096m 할당 4. 사용자 정의 크기"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" choice

				case "$choice" in
				  1)
					send_stats "1G 가상 메모리가 설정되었습니다"
					add_swap 1024

					;;
				  2)
					send_stats "2G 가상 메모리가 설정되었습니다"
					add_swap 2048

					;;
				  3)
					send_stats "4G 가상 메모리가 설정되었습니다"
					add_swap 4096

					;;

				  4)
					read -e -p "가상 메모리 크기 (단위 M)를 입력하십시오." new_swap
					add_swap "$new_swap"
					send_stats "사용자 정의 가상 메모리가 설정되었습니다"
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
				send_stats "사용자 관리"
				echo "사용자 목록"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "계정 운영"
				  echo "------------------------"
				  echo "1. 일반 계정 만들기 2. 프리미엄 계정 만들기"
				  echo "------------------------"
				  echo "3. 최고 권한을 부여 4. 최고 권한을 취소하십시오."
				  echo "------------------------"
				  echo "5. 계정을 삭제하십시오"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" sub_choice

				  case $sub_choice in
					  1)
					   # 사용자에게 새 사용자 이름을 입력하도록 프롬프트하십시오
					   read -e -p "새 사용자 이름을 입력하십시오 :" new_username

					   # 새 사용자를 생성하고 비밀번호를 설정하십시오
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "작업이 완료되었습니다."
						  ;;

					  2)
					   # 사용자에게 새 사용자 이름을 입력하도록 프롬프트하십시오
					   read -e -p "새 사용자 이름을 입력하십시오 :" new_username

					   # 새 사용자를 생성하고 비밀번호를 설정하십시오
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # 새로운 사용자에게 허가를 부여하십시오
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   echo "작업이 완료되었습니다."

						  ;;
					  3)
					   read -e -p "사용자 이름을 입력하십시오 :" username
					   # 새로운 사용자에게 허가를 부여하십시오
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
						  ;;
					  4)
					   read -e -p "사용자 이름을 입력하십시오 :" username
					   # Sudoers 파일에서 사용자의 Sudo 권한을 제거하십시오
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "삭제하려면 사용자 이름을 입력하십시오." username
					   # 사용자와 홈 디렉토리를 삭제하십시오
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
			send_stats "사용자 정보 생성기"
			echo "임의의 사용자 이름"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "임의의 사용자 이름$i: $username"
			done

			echo ""
			echo "임의 이름"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 5 개의 임의의 사용자 이름을 생성합니다
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "임의의 사용자 이름$i: $user_name"
			done

			echo ""
			echo "무작위 uuid"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "무작위 uuid$i: $uuid"
			done

			echo ""
			echo "16 비트 랜덤 비밀번호"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "랜덤 비밀번호$i: $password"
			done

			echo ""
			echo "32 비트 랜덤 비밀번호"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "랜덤 비밀번호$i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "시간대를 변경하십시오"
			while true; do
				clear
				echo "시스템 시간 정보"

				# 현재 시스템 시간대를 얻으십시오
				local timezone=$(current_timezone)

				# 현재 시스템 시간을 얻으십시오
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# 시간대와 시간을 보여줍니다
				echo "현재 시스템 시간대 :$timezone"
				echo "현재 시스템 시간 :$current_time"

				echo ""
				echo "시간대 스위칭"
				echo "------------------------"
				echo "아시아"
				echo "1. 중국의 상하이 시간 2. 중국의 홍콩 시간"
				echo "3. 일본의 도쿄 시간 4. 한국의 서울 시간"
				echo "5. 싱가포르 시간 6. 인도의 콜카타 시간"
				echo "7. UAE 8의 두바이 시간. 호주 시드니 시간"
				echo "9. 태국 방콕에서의 시간"
				echo "------------------------"
				echo "유럽"
				echo "11. 영국의 런던 시간 12. 프랑스의 파리 시간"
				echo "13. 베를린 시간, 독일 14. 모스크바 시간, 러시아"
				echo "15. 네덜란드에서 우트레흐트 시간 16. 스페인의 마드리드 시간"
				echo "------------------------"
				echo "미국"
				echo "21. 서양 시간 22. 동부 시간"
				echo "23. 캐나다 시간 24. 멕시코 시간"
				echo "25. 브라질 시간 26. 아르헨티나 시간"
				echo "------------------------"
				echo "31. UTC 글로벌 표준 시간"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" sub_choice


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
		  send_stats "호스트 이름을 수정하십시오"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "현재 호스트 이름 :${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "새 호스트 이름을 입력하십시오 (종료하려면 0을 입력하십시오) :" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # Debian, Ubuntu, Centos 등과 같은 다른 시스템
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

				  echo "호스트 이름은 다음으로 변경되었습니다.$new_hostname"
				  send_stats "호스트 이름이 변경되었습니다"
				  sleep 1
			  else
				  echo "종료, 호스트 이름이 변경되지 않았습니다."
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "시스템 업데이트 소스를 변경하십시오"
		  clear
		  echo "업데이트 소스 영역을 선택하십시오"
		  echo "LinuxMirrors에 연결하여 시스템 업데이트 소스를 전환하십시오"
		  echo "------------------------"
		  echo "1. 중국 본토 [기본값] 2. 중국 본토 [교육 네트워크] 3. 해외 지역"
		  echo "------------------------"
		  echo "0. 이전 메뉴로 돌아갑니다"
		  echo "------------------------"
		  read -e -p "선택을 입력하십시오 :" choice

		  case $choice in
			  1)
				  send_stats "중국 본토의 기본 소스"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "중국 본토의 교육 원"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "해외 출신"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
				  echo "취소"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "타이밍 작업 관리"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "시간이 정한 작업 목록"
				  crontab -l
				  echo ""
				  echo "작동하다"
				  echo "------------------------"
				  echo "1. 타이밍 작업 추가 2. 타이밍 작업 삭제 3. 타이밍 작업 편집"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "새 작업에 대한 실행 명령을 입력하십시오." newquest
						  echo "------------------------"
						  echo "1. 월간 작업 2. 주간 작업"
						  echo "3. 일일 작업 4. 시간당 작업"
						  echo "------------------------"
						  read -e -p "선택을 입력하십시오 :" dingshi

						  case $dingshi in
							  1)
								  read -e -p "작업을 수행하려면 매월 어느 날을 선택합니까? (1-30) :" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "작업을 수행 할 일주일을 선택합니까? (0-6, 0은 일요일을 나타냅니다) :" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "매일 작업을 수행 할 시간을 선택하십시오. (시간, 0-23) :" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "작업을 수행하기 위해 몇 분의 시간을 입력합니까? (Mins, 0-60) :" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "시간이 정한 작업을 추가하십시오"
						  ;;
					  2)
						  read -e -p "삭제 해야하는 키워드를 입력하십시오." kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "타이밍 작업을 삭제하십시오"
						  ;;
					  3)
						  crontab -e
						  send_stats "타이밍 작업 편집"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "지역 호스트 구문 분석"
			  while true; do
				  clear
				  echo "기본 호스트 구문 분석 목록"
				  echo "여기에 구문 분석 일치를 추가하면 더 이상 동적 구문 분석이 사용되지 않습니다."
				  cat /etc/hosts
				  echo ""
				  echo "작동하다"
				  echo "------------------------"
				  echo "1. 새 구문 분석 추가 2. 구문 분석 주소 삭제"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" host_dns

				  case $host_dns in
					  1)
						  read -e -p "새 구문 분석 기록 형식을 입력하십시오 : 110.25.5.33 Kejilion.pro :" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "로컬 호스트 구문 분석이 추가되었습니다"

						  ;;
					  2)
						  read -e -p "삭제 해야하는 구문 분석 컨텐츠의 키워드를 입력하십시오." delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "로컬 호스트 구문 분석 및 삭제"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "SSH 방어"
		  while true; do
			if [ -x "$(command -v fail2ban-client)" ] ; then
				clear
				remove fail2ban
				rm -rf /etc/fail2ban
			else
				clear
				docker_name="fail2ban"
				check_docker_app
				echo -e "SSH 방어 프로그램$check_docker"
				echo "FAIL2BAN은 무자비한 힘을 방지하는 SSH 도구입니다"
				echo "공식 웹 사이트 소개 :${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. 방어 프로그램을 설치하십시오"
				echo "------------------------"
				echo "2. SSH 차단 레코드보기"
				echo "3. 실시간 로그 모니터링"
				echo "------------------------"
				echo "9. 방어 프로그램을 제거하십시오"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" sub_choice
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
						echo "Fail2ban 방어 프로그램은 제거되었습니다"
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
			send_stats "현재 제한 종료 기능"
			while true; do
				clear
				echo "현재 제한 종료 기능"
				echo "비디오 소개 : https://www.bilibili.com/video/bv1mc411j7qd?t=0.1"
				echo "------------------------------------------------"
				echo "서버 트래픽 계산을 다시 시작하는 현재 트래픽 사용이 지워집니다!"
				output_status
				echo -e "${gl_kjlan}총 수신 :${gl_bai}$rx"
				echo -e "${gl_kjlan}총 보내기 :${gl_bai}$tx"

				# limiting_shut_down.sh 파일이 있는지 확인하십시오
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# threshold_gb의 값을 얻으십시오
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}현재 세트 입력-스테이션 전류 한계 임계 값은 다음과 같습니다.${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}현재 아웃 바운드 전류 한계 임계 값은 다음과 같습니다.${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}전류 제한 종료 기능이 활성화되지 않았습니다${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "시스템은 실제 트래픽이 1 분마다 임계 값에 도달하는지 여부를 감지하고 서버가 도착하면 자동으로 종료됩니다!"
				echo "------------------------"
				echo "1. 현재 한계 셧다운 함수 켜기 2. 현재 한계 종료 함수 비활성화"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아갑니다"
				echo "------------------------"
				read -e -p "선택을 입력하십시오 :" Limiting

				case "$Limiting" in
				  1)
					# 새 가상 메모리 크기를 입력하십시오
					echo "실제 서버에 트래픽이 100g 인 경우 트래픽 오류 나 오버플로를 피하기 위해 임계 값을 95G로 설정하고 전원을 미리 차단할 수 있습니다."
					read -e -p "들어오는 트래픽 임계 값을 입력하십시오 (단위 G, 기본값은 100G) :" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "아웃 바운드 트래픽 임계 값을 입력하십시오 (단위 G, 기본값은 100g) :" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "트래픽 재설정 날짜를 입력하십시오 (매월 1 일에 기본 재설정) :" cz_day
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
					echo "전류 제한 종료가 설정되었습니다"
					send_stats "전류 제한 종료가 설정되었습니다"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "전류 제한 종료 기능이 꺼졌습니다"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "개인 키 로그인"
			  while true; do
				  clear
			  	  echo "루트 비공개 키 로그인 모드"
			  	  echo "비디오 소개 : https://www.bilibili.com/video/bv1q4421x78n?t=209.4"
			  	  echo "------------------------------------------------"
			  	  echo "키 쌍이 생성되며 SSH 로그인을위한보다 안전한 방법"
				  echo "------------------------"
				  echo "1. 새 키 생성 2. 기존 키 가져 오기 3. 기본 키보기"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아갑니다"
				  echo "------------------------"
				  read -e -p "선택을 입력하십시오 :" host_dns

				  case $host_dns in
					  1)
				  		send_stats "새로운 키를 생성하십시오"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "기존 공개 키를 가져옵니다"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "로컬 비밀 키를보십시오"
						echo "------------------------"
						echo "공개 키 정보"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "개인 키 정보"
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
			  send_stats "전보 경고"
			  echo "TG-BOT 모니터링 및 조기 경고 기능"
			  echo "비디오 소개 : https://youtu.be/vll-eb3z_ty"
			  echo "------------------------------------------------"
			  echo "기본 CPU, 메모리, 하드 디스크, 트래픽 및 SSH 로그인의 실시간 모니터링 및 조기 경고를 실현하려면 조기 경고를 받으려면 TG Robot API 및 사용자 ID를 구성해야합니다."
			  echo "임계 값에 도달하면 사용자가 사용자에게 전송됩니다."
			  echo -e "${gl_hui}- 트래픽과 관련하여 서버를 다시 시작하면 다시 계산됩니다.${gl_bai}"
			  read -e -p "계속할거야? (Y/N) :" choice

			  case "$choice" in
				[Yy])
				  send_stats "전보 경고가 활성화되었습니다"
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

				  # ~/.profile 파일에 추가하십시오
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "TG-BOT 조기 경고 시스템이 시작되었습니다"
				  echo -e "${gl_hui}다른 시스템의 루트 디렉토리에 TG-Check-Notify.sh 경고 파일을 배치하고 직접 사용할 수도 있습니다!${gl_bai}"
				  ;;
				[Nn])
				  echo "취소"
				  ;;
				*)
				  echo "잘못된 선택, y 또는 N을 입력하십시오."
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "SSH에서 고위험 취약점을 수정하십시오"
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
			  send_stats "명령 줄 기록"
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
			send_stats "게시판"
			echo "Technology Lion 게시판은 공식 커뮤니티로 옮겨졌습니다! 공식 커뮤니티에 메시지를 남겨주세요!"
			echo "https://bbs.kejilion.pro/"
			  ;;

		  66)

			  root_use
			  send_stats "원 스톱 튜닝"
			  echo "원 스톱 시스템 최적화"
			  echo "------------------------------------------------"
			  echo "다음은 작동하고 최적화됩니다"
			  echo "1. 시스템을 최신으로 업데이트하십시오"
			  echo "2. 시스템 정크 파일 정리"
			  echo -e "3. 가상 메모리를 설정하십시오${gl_huang}1G${gl_bai}"
			  echo -e "4. SSH 포트 번호를 설정하십시오${gl_huang}5522${gl_bai}"
			  echo -e "5. 모든 포트를 엽니 다"
			  echo -e "6. 켜십시오${gl_huang}BBR${gl_bai}가속"
			  echo -e "7. 시간대를 설정하십시오${gl_huang}상하이${gl_bai}"
			  echo -e "8. DNS 주소를 자동으로 최적화합니다${gl_huang}해외 : 1.1.1.1 8.8.8.8 국내 : 223.5.5.5${gl_bai}"
			  echo -e "9. 기본 도구를 설치하십시오${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10. Linux系统内核参数优化切换到${gl_huang}균형 최적화 모드${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "한 번의 클릭 유지 보수가 있습니까? (Y/N) :" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "원 스톱 튜닝 시작"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/10. 시스템을 최신으로 업데이트하십시오"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/10. 시스템 정크 파일 정리"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/10. 가상 메모리를 설정합니다${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/10. SSH 포트 번호를 설정하십시오${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 5/10. 모든 포트를 엽니 다"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 6/10. 열려 있는${gl_huang}BBR${gl_bai}가속"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 7/10. 시간대를 설정하십시오${gl_huang}상하이${gl_bai}"

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
				  echo -e "[${gl_lv}OK${gl_bai}] 8/10. DNS 주소를 자동으로 최적화합니다${gl_huang}${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 9/10. 기본 도구를 설치하십시오${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10. Linux 시스템의 커널 매개 변수 최적화"
				  echo -e "${gl_lv}원 스톱 시스템 튜닝이 완료되었습니다${gl_bai}"

				  ;;
				[Nn])
				  echo "취소"
				  ;;
				*)
				  echo "잘못된 선택, y 또는 N을 입력하십시오."
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "시스템을 다시 시작하십시오"
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

			  echo "개인 정보 및 보안"
			  echo "스크립트는 사용자 기능에 대한 데이터를 수집하고 스크립트 경험을 최적화하며보다 재미 있고 유용한 기능을 만듭니다."
			  echo "스크립트 버전 번호, 사용 시간, 시스템 버전, CPU 아키텍처, 기계 국가 및 사용 된 기능의 이름을 수집합니다."
			  echo "------------------------------------------------"
			  echo -e "현재 상태 :$status_message"
			  echo "--------------------"
			  echo "1. 수집을 켭니다"
			  echo "2. 컬렉션을 닫습니다"
			  echo "--------------------"
			  echo "0. 이전 메뉴로 돌아갑니다"
			  echo "--------------------"
			  read -e -p "선택을 입력하십시오 :" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "수집이 활성화되었습니다"
					  send_stats "개인 정보 보호 및 보안 컬렉션이 활성화되었습니다"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "컬렉션이 닫혔습니다"
					  send_stats "개인 정보 보호 및 보안이 컬렉션을 위해 마감되었습니다"
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
			  send_stats "기술 라이온 스크립트를 제거하십시오"
			  echo "기술 라이온 스크립트를 제거하십시오"
			  echo "------------------------------------------------"
			  echo "Kejilion 스크립트를 완전히 제거하고 다른 기능에 영향을 미치지 않습니다."
			  read -e -p "계속할거야? (Y/N) :" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "대본은 제거되었습니다."
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "취소"
				  ;;
				*)
				  echo "잘못된 선택, y 또는 N을 입력하십시오."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "잘못된 입력!"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "파일 관리자"
	while true; do
		clear
		echo "파일 관리자"
		echo "------------------------"
		echo "현재 경로"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. 디렉토리를 입력합니다. 2. 디렉토리 만들기 3. 디렉토리 권한 수정 4. 디렉토리 이름 바꾸기"
		echo "5. 디렉토리 삭제 6. 이전 메뉴 디렉토리로 돌아갑니다."
		echo "------------------------"
		echo "11. 파일 만들기 12. 파일 편집 13. 파일 권한 수정 14. 파일 이름 바꾸기"
		echo "15. 파일을 삭제하십시오"
		echo "------------------------"
		echo "21. 파일 디렉토리 압축 22. zip 파일 디렉토리 23. 파일 디렉토리 이동 24. 파일 디렉토리 복사"
		echo "25. 파일을 다른 서버로 전달합니다"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아갑니다"
		echo "------------------------"
		read -e -p "선택을 입력하십시오 :" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "디렉토리 이름을 입력하십시오 :" dirname
				cd "$dirname" 2>/dev/null || echo "디렉토리에 입력 할 수 없습니다"
				send_stats "디렉토리로 이동하십시오"
				;;
			2)  # 创建目录
				read -e -p "작성하려면 디렉토리 이름을 입력하십시오." dirname
				mkdir -p "$dirname" && echo "디렉토리가 생성되었습니다" || echo "창조가 실패했습니다"
				send_stats "디렉토리를 만듭니다"
				;;
			3)  # 修改目录权限
				read -e -p "디렉토리 이름을 입력하십시오 :" dirname
				read -e -p "권한을 입력하십시오 (예 : 755) :" perm
				chmod "$perm" "$dirname" && echo "권한이 수정되었습니다" || echo "수정이 실패했습니다"
				send_stats "디렉토리 권한을 수정하십시오"
				;;
			4)  # 重命名目录
				read -e -p "현재 디렉토리 이름을 입력하십시오 :" current_name
				read -e -p "새 디렉토리 이름을 입력하십시오 :" new_name
				mv "$current_name" "$new_name" && echo "디렉토리의 이름이 바뀌 었습니다" || echo "이름 바꾸지 실패했습니다"
				send_stats "디렉토리의 이름을 바꿉니다"
				;;
			5)  # 删除目录
				read -e -p "삭제하려면 디렉토리 이름을 입력하십시오." dirname
				rm -rf "$dirname" && echo "디렉토리가 삭제되었습니다" || echo "삭제가 실패했습니다"
				send_stats "디렉토리 삭제"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "이전 메뉴 디렉토리로 돌아갑니다"
				;;
			11) # 创建文件
				read -e -p "작성하려면 파일 이름을 입력하십시오." filename
				touch "$filename" && echo "생성 된 파일" || echo "창조가 실패했습니다"
				send_stats "파일을 만듭니다"
				;;
			12) # 编辑文件
				read -e -p "편집 할 파일 이름을 입력하십시오." filename
				install nano
				nano "$filename"
				send_stats "파일 편집"
				;;
			13) # 修改文件权限
				read -e -p "파일 이름을 입력하십시오 :" filename
				read -e -p "권한을 입력하십시오 (예 : 755) :" perm
				chmod "$perm" "$filename" && echo "권한이 수정되었습니다" || echo "수정이 실패했습니다"
				send_stats "파일 권한을 수정하십시오"
				;;
			14) # 重命名文件
				read -e -p "현재 파일 이름을 입력하십시오 :" current_name
				read -e -p "새 파일 이름을 입력하십시오 :" new_name
				mv "$current_name" "$new_name" && echo "이름이 바뀌 었습니다" || echo "이름 바꾸지 실패했습니다"
				send_stats "파일의 이름을 바꿉니다"
				;;
			15) # 删除文件
				read -e -p "삭제하려면 파일 이름을 입력하십시오." filename
				rm -f "$filename" && echo "파일이 삭제되었습니다" || echo "삭제가 실패했습니다"
				send_stats "파일 삭제"
				;;
			21) # 压缩文件/目录
				read -e -p "압축 할 파일/디렉토리 이름을 입력하십시오." name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "압축$name.tar.gz" || echo "압축이 실패했습니다"
				send_stats "압축 파일/디렉토리"
				;;
			22) # 解压文件/目录
				read -e -p "파일 이름 (.tar.gz)을 입력하십시오." filename
				install tar
				tar -xzvf "$filename" && echo "압축 압축$filename" || echo "감압이 실패했습니다"
				send_stats "압축 파일/디렉토리 해제"
				;;

			23) # 移动文件或目录
				read -e -p "이동하려면 파일 또는 디렉토리 경로를 입력하십시오." src_path
				if [ ! -e "$src_path" ]; then
					echo "오류 : 파일 또는 디렉토리가 존재하지 않습니다."
					send_stats "파일 또는 디렉토리를 이동하지 못했습니다 : 파일 또는 디렉토리가 존재하지 않습니다."
					continue
				fi

				read -e -p "대상 경로를 입력하십시오 (새 파일 이름 또는 디렉토리 이름 포함) :" dest_path
				if [ -z "$dest_path" ]; then
					echo "오류 : 대상 경로를 입력하십시오."
					send_stats "움직이는 파일 또는 디렉토리 실패 : 대상 경로가 지정되지 않았습니다."
					continue
				fi

				mv "$src_path" "$dest_path" && echo "파일 또는 디렉토리가 이동했습니다$dest_path" || echo "파일이나 디렉토리를 이동하지 못했습니다"
				send_stats "파일 또는 디렉토리를 이동하십시오"
				;;


		   24) # 复制文件目录
				read -e -p "복사 할 파일 또는 디렉토리 경로를 입력하십시오." src_path
				if [ ! -e "$src_path" ]; then
					echo "오류 : 파일 또는 디렉토리가 존재하지 않습니다."
					send_stats "파일 또는 디렉토리를 복사하지 못했습니다 : 파일 또는 디렉토리가 존재하지 않습니다."
					continue
				fi

				read -e -p "대상 경로를 입력하십시오 (새 파일 이름 또는 디렉토리 이름 포함) :" dest_path
				if [ -z "$dest_path" ]; then
					echo "오류 : 대상 경로를 입력하십시오."
					send_stats "파일 또는 디렉토리 복사에 실패 : 지정되지 않은 대상 경로"
					continue
				fi

				# -r 옵션을 사용하여 디렉토리를 재귀 적으로 복사하십시오
				cp -r "$src_path" "$dest_path" && echo "파일 또는 디렉토리가 복사되었습니다$dest_path" || echo "파일이나 디렉토리를 복사하지 못했습니다"
				send_stats "파일 또는 디렉토리를 복사합니다"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "전송할 파일 경로를 입력하십시오." file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "오류 : 파일이 존재하지 않습니다."
					send_stats "파일을 전송하지 못했습니다 : 파일이 존재하지 않습니다."
					continue
				fi

				read -e -p "원격 서버 IP를 입력하십시오 :" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "오류 : 원격 서버 IP를 입력하십시오."
					send_stats "파일 전송 실패 : 원격 서버 IP가 입력되지 않았습니다"
					continue
				fi

				read -e -p "원격 서버 사용자 이름 (기본 루트)을 입력하십시오." remote_user
				remote_user=${remote_user:-root}

				read -e -p "원격 서버 비밀번호를 입력하십시오 :" -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "오류 : 원격 서버 비밀번호를 입력하십시오."
					send_stats "파일 전송 실패 : 원격 서버 비밀번호를 입력하지 않았습니다"
					continue
				fi

				read -e -p "로그인 포트 (기본값 22)를 입력하십시오 :" remote_port
				remote_port=${remote_port:-22}

				# 알려진 호스트를위한 오래된 항목을 명확하게합니다
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# SCP를 사용하여 파일을 전송합니다
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "파일은 원격 서버 홈 디렉토리로 전송되었습니다."
					send_stats "파일 전송이 성공적으로 전송됩니다"
				else
					echo "파일 전송이 실패했습니다."
					send_stats "파일 전송이 실패했습니다"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "이전 메뉴 메뉴로 돌아갑니다"
				break
				;;
			*)  # 处理无效输入
				echo "유효하지 않은 선택, 다시 입력하십시오"
				send_stats "잘못된 선택"
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

	# 추출 된 정보를 배열로 변환합니다
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# 서버를 통해 반복하고 명령을 실행하십시오
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}연결하십시오$name ($hostname)...${gl_bai}"
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
	  send_stats "클러스터 제어 센터"
	  echo "서버 클러스터 제어"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}서버 목록 관리${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}서버를 추가하십시오${gl_kjlan}2.  ${gl_bai}서버를 삭제하십시오${gl_kjlan}3.  ${gl_bai}서버를 편집하십시오"
	  echo -e "${gl_kjlan}4.  ${gl_bai}백업 클러스터${gl_kjlan}5.  ${gl_bai}클러스터를 복원하십시오"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}배치로 작업을 실행합니다${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}기술 라이온 스크립트를 설치하십시오${gl_kjlan}12. ${gl_bai}시스템을 업데이트하십시오${gl_kjlan}13. ${gl_bai}시스템을 청소하십시오"
	  echo -e "${gl_kjlan}14. ${gl_bai}Docker를 설치하십시오${gl_kjlan}15. ${gl_bai}BBR3을 설치하십시오${gl_kjlan}16. ${gl_bai}1G 가상 메모리를 설정하십시오"
	  echo -e "${gl_kjlan}17. ${gl_bai}시간대를 상하이로 설정하십시오${gl_kjlan}18. ${gl_bai}모든 포트를 엽니 다${gl_kjlan}51. ${gl_bai}맞춤 명령"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}메인 메뉴로 돌아갑니다"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택을 입력하십시오 :" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "클러스터 서버를 추가하십시오"
			  read -e -p "서버 이름 :" server_name
			  read -e -p "서버 IP :" server_ip
			  read -e -p "서버 포트 (22) :" server_port
			  local server_port=${server_port:-22}
			  read -e -p "서버 사용자 이름 (루트) :" server_username
			  local server_username=${server_username:-root}
			  read -e -p "서버 사용자 비밀번호 :" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "클러스터 서버를 삭제합니다"
			  read -e -p "삭제해야 할 키워드를 입력하십시오." rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "클러스터 서버를 편집합니다"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "백업 클러스터"
			  echo -e "제발${gl_huang}/root/cluster/servers.py${gl_bai}파일을 다운로드하고 백업을 완료하십시오!"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "클러스터를 복원하십시오"
			  echo "servers.py를 업로드하고 키를 눌러 업로드를 시작하십시오!"
			  echo -e "업로드하십시오${gl_huang}servers.py${gl_bai}파일로${gl_huang}/root/cluster/${gl_bai}복원을 완료하십시오!"
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
			  send_stats "명령 실행을 사용자 정의하십시오"
			  read -e -p "배치 실행 명령을 입력하십시오." mingling
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
send_stats "광고 열"
echo "광고 열"
echo "------------------------"
echo "그것은 사용자에게 더 간단하고 우아한 홍보 및 구매 경험을 제공 할 것입니다!"
echo ""
echo -e "서버 제안"
echo "------------------------"
echo -e "${gl_lan}Leica Cloud Hong Kong CN2 Gia 한국 이중 ISP US CN2 GIA 할인${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://www.lcayun.com/aff/zexuqbim${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}Racknerd $ 10.99 미국 1 코어 1G 메모리 20G 하드 드라이브 1T 트래픽 월에 한 달에 트래픽${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52.7 달러 미국 1 코어 4G 메모리 50G 하드 드라이브 4T 트래픽 월${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-8ab010ef94f?_ga=ga1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}Brickworker, 분기당 $ 49, 미국 CN2GIA, 일본 소프트 뱅크, 2 코어, 1G 메모리, 20G 하드 드라이브, 월 1 일 트래픽${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT 분기 당 $ 28 미국 CN2GIA 1 코어 2G 메모리 20G 하드 드라이브 800G 월에 트래픽${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}v.ps $ 6.9 월 월 $ 6.9 도쿄 소프트 뱅크 2 코어 1G 메모리 20G 하드 드라이브 1T 트래픽 월${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}더 인기있는 VPS가 제공합니다${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "도메인 이름 할인"
echo "------------------------"
echo -e "${gl_lan}GNAME 8.8 달러 첫해 COM 도메인 이름 6.68 달러 첫해 CC 도메인 이름${gl_bai}"
echo -e "${gl_bai}웹 사이트 : https://www.gname.com/register?tt=86836&ttcode=kejilion86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "주변 기술 사자"
echo "------------------------"
echo -e "${gl_kjlan}B 스테이션 :${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}오일 파이프 :${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}공식 웹 사이트 :${gl_bai}https://kejilion.pro/              ${gl_kjlan}항해:${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}블로그 :${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}소프트웨어 센터 :${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}스크립트 공식 웹 사이트 :${gl_bai}https://kejilion.sh            ${gl_kjlan}Github 주소 :${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "스크립트 업데이트"
cd ~
while true; do
	clear
	echo "로그 업데이트"
	echo "------------------------"
	echo "모든 로그 :${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}당신은 이미 최신 버전입니다!${gl_huang}v$sh_v${gl_bai}"
		send_stats "스크립트는 최신 상태이며 업데이트가 필요하지 않습니다."
	else
		echo "새 버전을 발견하십시오!"
		echo -e "현재 버전 v$sh_v최신 버전${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}자동 업데이트가 활성화되고 스크립트는 매일 오전 2시에 자동으로 업데이트됩니다!${gl_bai}"
	fi

	echo "------------------------"
	echo "1. 지금 업데이트 2. 자동 업데이트 켜기 3. 자동 업데이트 끄기"
	echo "------------------------"
	echo "0. 메인 메뉴로 돌아갑니다"
	echo "------------------------"
	read -e -p "선택을 입력하십시오 :" choice
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
			echo -e "${gl_lv}스크립트는 최신 버전으로 업데이트되었습니다!${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "스크립트는 최신입니다$sh_v_new"
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
			echo -e "${gl_lv}자동 업데이트가 활성화되고 스크립트는 매일 오전 2시에 자동으로 업데이트됩니다!${gl_bai}"
			send_stats "자동 스크립트 업데이트를 켜십시오"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}자동 업데이트가 닫힙니다${gl_bai}"
			send_stats "스크립트 자동 업데이트를 닫습니다"
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
echo -e "기술 라이온 스크립트 도구 상자 v$sh_v"
echo -e "명령 줄 입력${gl_huang}k${gl_kjlan}스크립트를 신속하게 시작하십시오${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}시스템 정보 쿼리"
echo -e "${gl_kjlan}2.   ${gl_bai}시스템 업데이트"
echo -e "${gl_kjlan}3.   ${gl_bai}시스템 정리"
echo -e "${gl_kjlan}4.   ${gl_bai}기본 도구"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR 관리"
echo -e "${gl_kjlan}6.   ${gl_bai}도커 관리"
echo -e "${gl_kjlan}7.   ${gl_bai}워프 관리"
echo -e "${gl_kjlan}8.   ${gl_bai}스크립트 수집 테스트"
echo -e "${gl_kjlan}9.   ${gl_bai}Oracle Cloud 스크립트 컬렉션"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP 웹 사이트 구축"
echo -e "${gl_kjlan}11.  ${gl_bai}응용 프로그램 시장"
echo -e "${gl_kjlan}12.  ${gl_bai}백엔드 작업 공간"
echo -e "${gl_kjlan}13.  ${gl_bai}시스템 도구"
echo -e "${gl_kjlan}14.  ${gl_bai}서버 클러스터 제어"
echo -e "${gl_kjlan}15.  ${gl_bai}광고 열"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}Phantom Beast Palu 서버 오프닝 스크립트"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}스크립트 업데이트"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}종료 스크립트"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "선택을 입력하십시오 :" choice

case $choice in
  1) linux_ps ;;
  2) clear ; send_stats "시스템 업데이트" ; linux_update ;;
  3) clear ; send_stats "시스템 정리" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "워프 관리" ; install wget
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
  p) send_stats "Phantom Beast Palu 서버 오프닝 스크립트" ; cd ~
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "잘못된 입력!" ;;
esac
	break_end
done
}


k_info() {
send_stats "K 명령 참조 사용 사례"
echo "-------------------"
echo "비디오 소개 : https://www.bilibili.com/video/bv1ib421e7it?t=0.1"
echo "다음은 K 명령 참조 유스 케이스입니다."
echo "스크립트 시작 k"
echo "소프트웨어 패키지 설치 K 설치 나노 wget | K 추가 나노 wget | K Nano wget을 설치하십시오"
echo "패키지 k 제거 나노 wget | K del nano wget | k 제거 나노 wget | K를 제거하십시오"
echo "업데이트 시스템 K 업데이트 | K 업데이트"
echo "깨끗한 시스템 쓰레기 K Clean | K 청소"
echo "시스템 패널 k dd |를 다시 설치하십시오 K 재설치"
echo "BBR3 제어판 K BBR3 | K bbrv3"
echo "커널 튜닝 패널 K nhyh | K 커널 최적화"
echo "가상 메모리 K 스왑 2048을 설정하십시오"
echo "가상 시간대 k 시간 아시아/상하이 설정 | k 시내 아시아/상하이"
echo "시스템 재활용 빈 K 쓰레기 | K hsz | K 재활용 빈"
echo "시스템 백업 기능 K 백업 | K bf | K 백업"
echo "SSH 원격 연결 도구 K SSH | K 원격 연결"
echo "rsync 원격 동기화 도구 K rsync | K 원격 동기화"
echo "하드 디스크 관리 도구 K 디스크 | K 하드 디스크 관리"
echo "인트라넷 침투 (서버 측) K frps"
echo "인트라넷 침투 (클라이언트) K frpc"
echo "소프트웨어 시작 K 시작 SSHD | K 시작 SSHD"
echo "소프트웨어 중지 K 중지 SSHD | K 중지 SSHD"
echo "소프트웨어 재시작 K 재시작 SSHD | K는 sshd를 다시 시작합니다"
echo "소프트웨어 상태보기 K 상태 SSHD | K 상태 SSHD"
echo "소프트웨어 부트 K 활성화 Docker | K autostart docke | K 스타트 업 Docker"
echo "도메인 이름 인증서 응용 프로그램 K SSL"
echo "도메인 이름 인증서 만료 쿼리 K SSL PS"
echo "도커 환경 설치 K 도커 설치 | K 도커 설치"
echo "도커 컨테이너 관리 K 도커 PS | K 도커 컨테이너"
echo "Docker Image Management K Docker img | K Docker Image"
echo "LDNMP 사이트 관리 K 웹"
echo "LDNMP 캐시 정리 K 웹 캐시"
echo "WordPress k wp | K WordPress | k wp xxx.com을 설치하십시오"
echo "리버스 프록시 k fd | k rp | k an-generation | k fd xxx.com을 설치하십시오."
echo "로드 밸런싱 k loadbalance | k로드 밸런싱을 설치하십시오"
echo "방화벽 패널 K FHQ | K 방화벽"
echo "포트 k dkdk 8080 | k 오픈 포트 8080"
echo "포트 K GBDK 7800 | K 닫기 포트 7800"
echo "IP K FXIP 127.0.0.0/8 | K 릴리스 IP 127.0.0.0/8 릴리스"
echo "블록 IP K ZZIP 177.5.25.36 | K 블록 IP 177.5.25.36"


}



if [ "$#" -eq 0 ]; then
	# 매개 변수가없는 경우 대화식 로직을 실행하십시오
	kejilion_sh
else
	# 매개 변수가있는 경우 해당 함수를 실행하십시오
	case $1 in
		install|add|安装)
			shift
			send_stats "소프트웨어를 설치하십시오"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "소프트웨어를 제거하십시오"
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
			send_stats "시간이 정한 RSYNC 동기화"
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
			send_stats "가상 메모리를 신속하게 설정했습니다"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "시간대를 빠르게 설정하십시오"
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
			send_stats "소프트웨어 상태보기"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "소프트웨어 시작"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "소프트웨어 일시 정지"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "소프트웨어 재시작"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "소프트웨어 부츠"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "인증서 상태를 확인하십시오"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "인증서를 신속하게 신청하십시오"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "인증서를 신속하게 신청하십시오"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "Docker를 신속하게 설치하십시오"
					install_docker
					;;
				ps|容器)
					send_stats "빠른 컨테이너 관리"
					docker_ps
					;;
				img|镜像)
					send_stats "빠른 미러 관리"
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

