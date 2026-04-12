#!/bin/bash
sh_v="4.1.6"


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



# 명령을 실행하는 함수 정의
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



# 이 기능은 함수에 묻혀있는 정보를 수집하고 사용자가 사용하는 현재 스크립트 버전 번호, 사용 시간, 시스템 버전, CPU 아키텍처, 시스템 국가 및 기능 이름을 기록합니다. 민감한 정보는 포함되어 있지 않으니 걱정하지 마세요! 저를 믿어주세요!
# 이 기능은 왜 설계되었나요? 그 목적은 사용자가 사용하고 싶어하는 기능을 더 잘 이해하고, 기능을 더욱 최적화하고 사용자 요구에 맞는 더 많은 기능을 출시하는 것입니다.
# send_stats 함수 호출 위치에 대한 전문을 검색할 수 있습니다. 투명하고 오픈 소스입니다. 불편하신 점이 있으시면 이용을 거부하실 수 있습니다.



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

# 사용자에게 약관에 동의하라는 메시지를 표시합니다.
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}기술 사자 스크립트 도구 상자에 오신 것을 환영합니다${gl_bai}"
	echo "스크립트를 처음 사용하는 경우 사용자 라이센스 계약을 읽고 동의하십시오."
	echo "사용자 라이센스 계약: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "위의 약관에 동의하십니까? (예/아니요):" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "라이센스 계약"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "허가가 거부되었습니다"
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
		echo "패키지 매개변수가 제공되지 않았습니다!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}설치 중$package...${gl_bai}"
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
				echo "알 수 없는 패키지 관리자입니다!"
				return 1
			fi
		fi
	done
}


check_disk_space() {
	local required_gb=$1
	local path=${2:-/}

	local required_space_mb=$((required_gb * 1024))
	local available_space_mb=$(df -m "$path" | awk 'NR==2 {print $4}')

	if [ "$available_space_mb" -lt "$required_space_mb" ]; then
		echo -e "${gl_huang}힌트:${gl_bai}디스크 공간이 부족합니다!"
		echo "현재 사용 가능한 공간: $((available_space_mb/1024))G"
		echo "최소 필요 공간:${required_gb}G"
		echo "설치를 계속할 수 없습니다. 디스크 공간을 비운 후 다시 시도하십시오."
		send_stats "디스크 공간이 부족합니다."
		break_end
		kejilion
	fi
}



install_dependency() {
	install wget unzip tar jq grep
}

remove() {
	if [ $# -eq 0 ]; then
		echo "패키지 매개변수가 제공되지 않았습니다!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}제거 중$package...${gl_bai}"
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
			echo "알 수 없는 패키지 관리자입니다!"
			return 1
		fi
	done
}


# 다양한 배포판에 적합한 범용 systemctl 기능
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# 서비스 다시 시작
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스가 다시 시작되었습니다."
	else
		echo "오류: 다시 시작$1서비스가 실패했습니다."
	fi
}

# 서비스 시작
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스가 시작되었습니다."
	else
		echo "오류: 시작$1서비스가 실패했습니다."
	fi
}

# 서비스 중지
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스가 중지되었습니다."
	else
		echo "오류: 중지$1서비스가 실패했습니다."
	fi
}

# 서비스 상태 확인
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1서비스 상태가 표시됩니다."
	else
		echo "오류: 표시할 수 없습니다.$1서비스 상태."
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME부팅시 자동으로 시작되도록 설정되어 있습니다."
}



break_end() {
	  echo -e "${gl_lv}작업 완료${gl_bai}"
	  echo "계속하려면 아무 키나 누르세요..."
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
	echo -e "${gl_huang}도커 환경 설치 중...${gl_bai}"
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
	echo "컨테이너 운영"
	echo "------------------------"
	echo "1. 새 컨테이너 생성"
	echo "------------------------"
	echo "2. 지정된 컨테이너 시작 6. 모든 컨테이너 시작"
	echo "3. 지정된 컨테이너를 중지합니다. 7. 모든 컨테이너를 중지합니다."
	echo "4. 지정된 컨테이너 삭제 8. 모든 컨테이너 삭제"
	echo "5. 지정된 컨테이너를 다시 시작합니다. 9. 모든 컨테이너를 다시 시작합니다."
	echo "------------------------"
	echo "11. 지정된 컨테이너를 입력합니다. 12. 컨테이너 로그를 봅니다."
	echo "13. 컨테이너 네트워크 확인 14. 컨테이너 점유율 확인"
	echo "------------------------"
	echo "15. 컨테이너 포트 액세스 활성화 16. 컨테이너 포트 액세스 닫기"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택사항을 입력하세요:" sub_choice
	case $sub_choice in
		1)
			send_stats "새 컨테이너 만들기"
			read -e -p "생성 명령을 입력하십시오:" dockername
			$dockername
			;;
		2)
			send_stats "지정된 컨테이너 시작"
			read -e -p "컨테이너 이름을 입력하세요(여러 컨테이너 이름을 공백으로 구분하세요)." dockername
			docker start $dockername
			;;
		3)
			send_stats "지정된 컨테이너 중지"
			read -e -p "컨테이너 이름을 입력하세요(여러 컨테이너 이름을 공백으로 구분하세요)." dockername
			docker stop $dockername
			;;
		4)
			send_stats "지정된 컨테이너 삭제"
			read -e -p "컨테이너 이름을 입력하세요(여러 컨테이너 이름을 공백으로 구분하세요)." dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "지정된 컨테이너를 다시 시작합니다."
			read -e -p "컨테이너 이름을 입력하세요(여러 컨테이너 이름을 공백으로 구분하세요)." dockername
			docker restart $dockername
			;;
		6)
			send_stats "모든 컨테이너 시작"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "모든 컨테이너 중지"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "모든 컨테이너 삭제"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "선택이 잘못되었습니다. Y 또는 N을 입력하세요."
				;;
			esac
			;;
		9)
			send_stats "모든 컨테이너 다시 시작"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "컨테이너를 입력하세요"
			read -e -p "컨테이너 이름을 입력하세요:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "컨테이너 로그 보기"
			read -e -p "컨테이너 이름을 입력하세요:" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "컨테이너 네트워크 보기"
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
			send_stats "컨테이너 점유율 보기"
			docker stats --no-stream
			break_end
			;;

		15)
			send_stats "컨테이너 포트 액세스 허용"
			read -e -p "컨테이너 이름을 입력하세요:" docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "컨테이너 포트 접근 차단"
			read -e -p "컨테이너 이름을 입력하세요:" docker_name
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
	send_stats "도커 이미지 관리"
	echo "도커 이미지 목록"
	docker image ls
	echo ""
	echo "미러 작동"
	echo "------------------------"
	echo "1. 지정된 이미지 가져오기 3. 지정된 이미지 삭제"
	echo "2. 지정된 이미지 업데이트 4. 모든 이미지 삭제"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택사항을 입력하세요:" sub_choice
	case $sub_choice in
		1)
			send_stats "이미지 가져오기"
			read -e -p "이미지 이름을 입력하세요(여러 이미지 이름은 공백으로 구분하세요):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}이미지 가져오기:$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "이미지 업데이트"
			read -e -p "이미지 이름을 입력하세요(여러 이미지 이름은 공백으로 구분하세요):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}이미지 업데이트 중:$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "이미지 삭제"
			read -e -p "이미지 이름을 입력하세요(여러 이미지 이름은 공백으로 구분하세요):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "모든 이미지 삭제"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "선택이 잘못되었습니다. Y 또는 N을 입력하세요."
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
				echo "지원되지 않는 배포판:$ID"
				return
				;;
		esac
	else
		echo "운영 체제를 확인할 수 없습니다."
		return
	fi

	echo -e "${gl_lv}crontab이 설치되어 있고 cron 서비스가 실행 중입니다.${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 구성 파일이 있는지 확인하고, 없으면 파일을 생성하고 기본 설정을 씁니다.
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# jq를 사용하여 구성 파일 업데이트 처리
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 현재 구성에 이미 ipv6 설정이 있는지 확인하십시오.
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 구성 업데이트 및 IPv6 활성화
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 원래 구성을 새 구성과 비교
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}현재 IPv6 액세스가 활성화되어 있습니다.${gl_bai}"
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

	# 구성 파일이 있는지 확인하십시오.
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}구성 파일이 존재하지 않습니다.${gl_bai}"
		return
	fi

	# 현재 구성 읽기
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# jq를 사용하여 구성 파일 업데이트 처리
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 현재 ipv6 상태 확인
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 원래 구성을 새 구성과 비교
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}IPv6 액세스는 현재 폐쇄되었습니다.${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}IPv6 액세스가 성공적으로 종료되었습니다.${gl_bai}"
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
		echo "포트 번호를 하나 이상 입력하세요."
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 기존 종료 규칙 삭제
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# 공개 규칙 추가
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "포트가 열렸습니다.$port"
		fi
	done

	save_iptables_rules
	send_stats "포트가 열렸습니다."
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "포트 번호를 하나 이상 입력하세요."
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 기존 공개 규칙 삭제
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 종료 규칙 추가
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "항구 폐쇄$port"
		fi
	done

	# 기존 규칙 삭제(있는 경우)
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 첫 번째 규칙에 새 규칙을 삽입합니다.
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "항구 폐쇄"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "IP 주소 또는 IP 세그먼트를 하나 이상 입력하세요."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 기존 차단 규칙 삭제
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 허용 규칙 추가
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "공개된 IP$ip"
		fi
	done

	save_iptables_rules
	send_stats "공개된 IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "IP 주소 또는 IP 세그먼트를 하나 이상 입력하세요."
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 기존 허용 규칙 삭제
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# 차단 규칙 추가
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP가 차단됨$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP가 차단됨"
}







enable_ddos_defense() {
	# DDoS 보호 켜기
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "DDoS 방어 켜기"
}

# DDoS 방어 끄기
disable_ddos_defense() {
	# DDoS 보호 끄기
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "DDoS 방어 끄기"
}





# 국가 IP 규칙을 관리하는 기능
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
					echo "오류: 다운로드$country_codeIP 영역 파일 실패"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "성공적으로 차단되었습니다$country_codeIP 주소"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "오류: 다운로드$country_codeIP 영역 파일 실패"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "허용되었습니다.$country_codeIP 주소"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "성공적으로 제거되었습니다$country_codeIP 주소 제한"
				;;

			*)
				echo "사용법: prepare_country_rules {block|allow|unblock} <country_code...>"
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
		  echo "고급 방화벽 관리"
		  send_stats "고급 방화벽 관리"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "방화벽 관리"
		  echo "------------------------"
		  echo "1. 지정 포트 열기 2. 지정 포트 닫기"
		  echo "3. 모든 포트를 엽니다. 4. 모든 포트를 닫습니다."
		  echo "------------------------"
		  echo "5. IP 화이트리스트 6. IP 블랙리스트"
		  echo "7. 지정된 IP 지우기"
		  echo "------------------------"
		  echo "11. PING 허용 12. PING 비활성화"
		  echo "------------------------"
		  echo "13. DDOS 방어 시작 14. DDOS 방어 끄기"
		  echo "------------------------"
		  echo "15. 특정 국가 IP 차단 16. 특정 국가 IP만 허용"
		  echo "17. 지정된 국가의 IP 제한을 해제합니다."
		  echo "------------------------"
		  echo "0. 이전 메뉴로 돌아가기"
		  echo "------------------------"
		  read -e -p "선택사항을 입력하세요:" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "열려 있는 포트 번호를 입력하세요." o_port
				  open_port $o_port
				  send_stats "지정된 포트 열기"
				  ;;
			  2)
				  read -e -p "닫힌 포트 번호를 입력하세요:" c_port
				  close_port $c_port
				  send_stats "지정된 포트 닫기"
				  ;;
			  3)
				  # 모든 포트 열기
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
				  send_stats "모든 포트 열기"
				  ;;
			  4)
				  # 모든 포트를 닫으세요
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
				  send_stats "모든 포트를 닫으세요"
				  ;;

			  5)
				  # IP 화이트리스트
				  read -e -p "허용된 IP 또는 IP 세그먼트를 입력하세요." o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP 블랙리스트
				  read -e -p "차단된 IP 또는 IP 범위를 입력하세요." c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 지정된 IP 지우기
				  read -e -p "삭제된 IP를 입력하세요:" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "지정된 IP 지우기"
				  ;;
			  11)
				  # 핑 허용
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "핑 허용"
				  ;;
			  12)
				  # 핑 비활성화
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "핑 비활성화"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "차단된 국가 코드를 입력하세요(여러 국가 코드는 CN US JP와 같이 공백으로 구분될 수 있음)." country_code
				  manage_country_rules block $country_code
				  send_stats "국가 허용$country_codeIP"
				  ;;
			  16)
				  read -e -p "허용되는 국가 코드를 입력하십시오(여러 국가 코드는 CN US JP와 같이 공백으로 구분할 수 있음)." country_code
				  manage_country_rules allow $country_code
				  send_stats "블록 국가$country_codeIP"
				  ;;

			  17)
				  read -e -p "지워진 국가 코드를 입력하십시오(여러 국가 코드는 CN US JP와 같이 공백으로 구분될 수 있음)." country_code
				  manage_country_rules unblock $country_code
				  send_stats "명확한 국가$country_codeIP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}






add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 현재 시스템의 모든 스왑 파티션을 가져옵니다.
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 모든 스왑 파티션을 탐색하고 삭제합니다.
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# /swapfile이 더 이상 사용되지 않는지 확인하세요.
	swapoff /swapfile

	# 이전 /swap 파일 삭제
	rm -f /swapfile

	# 새로운 스왑 파티션 생성
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

	echo -e "가상 메모리 크기가 다음과 같이 조정되었습니다.${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 가상 메모리를 만들어야 하는지 확인
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # nginx 버전 받기
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # mysql 버전 받기
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # PHP 버전 받기
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # Redis 버전 받기
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 필요한 디렉토리 및 파일 생성
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf
  wget -O /home/web/redis/valkey.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/valkey.conf


  default_server_ssl

  # docker-compose.yml 파일을 다운로드하여 교체하세요.
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # docker-compose.yml 파일에서 교체
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
	echo "갱신 작업이 업데이트되었습니다."
}


install_ssltls() {
	  docker stop nginx > /dev/null 2>&1
	  check_port > /dev/null 2>&1
	  cd ~

	  local file_path="/etc/letsencrypt/live/$yuming/fullchain.pem"
	  if [ ! -f "$file_path" ]; then
		 	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
			local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'
			# local ipv6_pattern='^([0-9A-Fa-f]{1,4}:){7}[0-9A-Fa-f]{1,4}$'
	  		# local ipv6_pattern='^(([0-9a-fA-F]{1,4}:){7,7}[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,7}:|([0-9a-fA-F]{1,4}:){1,6}:[0-9a-fA-F]{1,4}|([0-9a-fA-F]{1,4}:){1,5}(:[0-9a-fA-F]{1,4}){1,2}|([0-9a-fA-F]{1,4}:){1,4}(:[0-9a-fA-F]{1,4}){1,3}|([0-9a-fA-F]{1,4}:){1,3}(:[0-9a-fA-F]{1,4}){1,4}|([0-9a-fA-F]{1,4}:){1,2}(:[0-9a-fA-F]{1,4}){1,5}|[0-9a-fA-F]{1,4}:((:[0-9a-fA-F]{1,4}){1,6})|:((:[0-9a-fA-F]{1,4}){1,7}|:)|fe80:(:[0-9a-fA-F]{0,4}){0,4}%[0-9a-zA-Z]{1,}|::(ffff(:0{1,4}){0,1}:){0,1}((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))|([0-9a-fA-F]{1,4}:){1,4}:((25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?)\.){3}(25[0-5]|(2[0-4][0-9]|[01]?[0-9][0-9]?))))$'
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
	echo -e "${gl_huang}$yuming공개키 정보${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming개인 키 정보${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}인증서 저장 경로${gl_bai}"
	echo "공개 키: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "개인 키: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}SSL 인증서를 빠르게 신청하고 만료되기 전에 자동으로 갱신하세요.${gl_bai}"
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
	echo -e "${gl_huang}신청한 인증서의 만료 상태${gl_bai}"
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
		send_stats "도메인 이름 인증서 신청이 성공했습니다."
	else
		send_stats "도메인 이름 인증서 신청 실패"
		echo -e "${gl_hong}알아채다:${gl_bai}인증서 신청이 실패했습니다. 다음 가능한 이유를 확인하고 다시 시도하십시오."
		echo -e "1. 도메인 이름이 잘못 입력되었습니다. ➠ 도메인 이름이 올바르게 입력되었는지 확인하세요."
		echo -e "2. DNS 확인 문제 ➠ 도메인 이름이 서버 IP로 올바르게 확인되었는지 확인"
		echo -e "3. 네트워크 구성 문제 ➠ Cloudflare Warp 등 가상 네트워크를 사용하는 경우 일시적으로 종료하세요."
		echo -e "4. 방화벽 제한사항 ➠ 포트 80/443이 열려 있는지 확인하고 접근이 가능한지 확인하세요."
		echo -e "5. 신청 횟수가 한도를 초과했습니다. ➠ Let's Encrypt에는 주간 한도(5회/도메인 이름/주)가 있습니다."
		echo -e "6. 국내 등록 제한 ➠ 중국 ​​본토 환경의 경우 도메인 이름 등록 여부를 확인하시기 바랍니다."
		break_end
		clear
		echo "다시 배포해 보세요.$webname"
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
	  echo -e "먼저 도메인 이름을 로컬 IP로 확인합니다.${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "귀하의 IP 또는 확인된 도메인 이름을 입력하십시오:" yuming
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
  echo "로그인 정보:"
  echo "사용자 이름:$dbuse"
  echo "비밀번호:$dbusepasswd"
  echo
  send_stats "시작하다$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 구성 파일이 있는지 확인하십시오.
  if [ -f "$CONFIG_FILE" ]; then
	# 구성 파일에서 API_TOKEN 및 zone_id를 읽습니다.
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# ZONE_IDS를 어레이로 변환
	ZONE_IDS=($ZONE_IDS)
  else
	# 캐시를 지울지 여부를 사용자에게 묻습니다.
	read -e -p "Cloudflare의 캐시를 지워야 합니까? (예/아니요):" answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF 정보는 다음 위치에 저장됩니다.$CONFIG_FILE, 나중에 CF 정보를 수정할 수 있습니다."
	  read -e -p "API_TOKEN을 입력하세요:" API_TOKEN
	  read -e -p "CF 사용자 이름을 입력하세요:" EMAIL
	  read -e -p "zone_id를 입력하십시오(여러 개는 공백으로 구분)." -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 각 zone_id를 반복하고 캐시 지우기 명령을 실행합니다.
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "zone_id에 대한 캐시 지우기:$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "캐시 삭제 요청이 전송되었습니다."
}



web_cache() {
  send_stats "사이트 캐시 지우기"
  cf_purge_cache
  cd /home/web && docker compose restart
  restart_redis
}



web_del() {

	send_stats "사이트 데이터 삭제"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "사이트 데이터를 삭제하려면 도메인 이름을 입력하세요(여러 도메인 이름은 공백으로 구분)." yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "도메인 이름을 삭제하는 중입니다:$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# 도메인 이름을 데이터베이스 이름으로 변환
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# 오류를 방지하려면 데이터베이스를 삭제하기 전에 데이터베이스가 존재하는지 확인하세요.
		echo "데이터베이스 삭제 중:$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# 모드 매개변수에 따라 WAF를 켤지 끌지 결정합니다.
	if [ "$mode" == "on" ]; then
		# WAF 켜기: 댓글 제거
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# WAF 끄기: 댓글 추가
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "잘못된 인수: 'on' 또는 'off'를 사용하세요."
		return 1
	fi

	# nginx 이미지를 확인하고 그에 따라 처리하세요.
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
	if [ -f "/etc/fail2ban/action.d/cloudflare-docker.conf" ]; then
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
	# 이전 정의 삭제
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# "HappyPublishing"이 포함된 줄 앞에 새 정의를 삽입합니다.
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
	# 이전 정의 삭제
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# "HappyPublishing"이 포함된 줄 앞에 새 정의를 삽입합니다.
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
		# Brotli 켜기: 댓글 제거
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
		# Brotli 닫기: 댓글 추가
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
		echo "잘못된 인수: 'on' 또는 'off'를 사용하세요."
		return 1
	fi

	# nginx 이미지를 확인하고 그에 따라 처리하세요.
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
		# Zstd 켜기: 주석 제거
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
		# Zstd 닫기: 설명 추가
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
		echo "잘못된 인수: 'on' 또는 'off'를 사용하세요."
		return 1
	fi

	# nginx 이미지를 확인하고 그에 따라 처리하세요.
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
		echo "잘못된 인수: 'on' 또는 'off'를 사용하세요."
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP 환경 방어"
	  while true; do
		check_f2b_status
		check_waf_status
		check_cf_mode
			  clear
			  echo -e "서버 웹사이트 방어 프로그램${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 방어 프로그램 설치"
			  echo "------------------------"
			  echo "5. SSH 차단 기록 보기 6. 웹사이트 차단 기록 보기"
			  echo "7. 방어규칙 목록 보기 8. 실시간 모니터링을 위한 로그 보기"
			  echo "------------------------"
			  echo "11. 차단 매개변수 구성 12. 차단된 IP 모두 삭제"
			  echo "------------------------"
			  echo "21. cloudflare 모드 22. 고부하에서 5초 보호 활성화"
			  echo "------------------------"
			  echo "31. WAF 켜기 32. WAF 끄기"
			  echo "33. DDOS 방어 켜기 34. DDOS 방어 끄기"
			  echo "------------------------"
			  echo "9. 방어 프로그램 제거"
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아가기"
			  echo "------------------------"
			  read -e -p "선택사항을 입력하세요:" sub_choice
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
					  echo "Fail2Ban 방어 프로그램이 제거되었습니다."
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
					  send_stats "클라우드플레어 모드"
					  echo "cf 백엔드 오른쪽 상단에 있는 내 프로필로 이동하여 왼쪽에 있는 API 토큰을 선택하고 글로벌 API 키를 받으세요."
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "CF의 계좌번호를 입력하세요:" cfuser
					  read -e -p "CF의 글로벌 API 키를 입력하세요:" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /etc/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "Cloudflare 모드가 구성되었으며, 차단 기록은 cf 백그라운드, site-security-events에서 볼 수 있습니다."
					  ;;

				  22)
					  send_stats "고부하로 5초 쉴드 가능"
					  echo -e "${gl_huang}웹사이트는 5분마다 자동으로 감지합니다. 높은 부하를 감지하면 자동으로 쉴드가 열리고, 낮은 부하가 감지되면 자동으로 5초 동안 쉴드가 닫힙니다.${gl_bai}"
					  echo "--------------"
					  echo "CF 매개변수 가져오기:"
					  echo -e "cf 백엔드 오른쪽 상단에 있는 내 프로필로 이동하여 왼쪽에 있는 API 토큰을 선택하고${gl_huang}Global API Key${gl_bai}"
					  echo -e "cf 백엔드 도메인 이름 요약 페이지 오른쪽 하단으로 이동하여 가져오세요.${gl_huang}지역 ID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "CF의 계좌번호를 입력하세요:" cfuser
					  read -e -p "CF의 글로벌 API 키를 입력하세요:" cftoken
					  read -e -p "CF에 도메인 이름의 영역 ID를 입력하세요." cfzonID

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
						  echo "고부하 자동 쉴드 오픈 스크립트가 추가되었습니다."
					  else
						  echo "자동 방패 열기 스크립트가 이미 있으므로 추가할 필요가 없습니다."
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "사이트 WAF가 활성화되었습니다"
					  send_stats "사이트 WAF가 활성화되었습니다"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "사이트 WAF가 다운되었습니다"
					  send_stats "사이트 WAF가 다운되었습니다"
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



check_nginx_mode() {

CONFIG_FILE="/home/web/nginx.conf"

# 현재 작업자_프로세스 설정 값을 가져옵니다.
current_value=$(grep -E '^\s*worker_processes\s+[0-9]+;' "$CONFIG_FILE" | awk '{print $2}' | tr -d ';')

# 값에 따라 모드 정보 설정
if [ "$current_value" = "8" ]; then
	mode_info=" 高性能模式"
else
	mode_info=" 标准模式"
fi



}


check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# zstd가 켜져 있고 주석 처리가 해제되어 있는지 확인하세요. (전체 줄은 zstd on으로 시작됩니다.)
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status=" zstd压缩已开启"
	else
		zstd_status=""
	fi

	# brotli가 활성화되어 있고 주석 처리가 해제되어 있는지 확인하세요.
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status=" br压缩已开启"
	else
		br_status=""
	fi

	# gzip이 활성화되어 있고 주석 처리가 해제되어 있는지 확인하세요.
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
			  send_stats "LDNMP 환경 최적화"
			  echo -e "LDNMP 환경 최적화${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 표준 모드 2. 고성능 모드(2H4G 이상 권장)"
			  echo "------------------------"
			  echo "3. gzip 압축 켜기 4. gzip 압축 끄기"
			  echo "5. br 압축을 켭니다. 6. br 압축을 끕니다."
			  echo "7. zstd 압축을 켭니다. 8. zstd 압축을 끕니다."
			  echo "------------------------"
			  echo "0. 이전 메뉴로 돌아가기"
			  echo "------------------------"
			  read -e -p "선택사항을 입력하세요:" sub_choice
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


				  echo "LDNMP 환경이 표준 모드로 설정되었습니다."

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

				  echo "LDNMP 환경이 고성능 모드로 설정되었습니다."

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
		check_docker="${gl_lv}已安装${gl_bai}"
	else
		check_docker="${gl_hui}未安装${gl_bai}"
	fi
}



# check_docker_app() {

# if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
# check_docker="${gl_lv}가 ${gl_bai}를 설치했습니다."
# else
# check_docker="${gl_hui}이(가) ${gl_bai}" 설치되지 않았습니다.
# fi

# }


check_docker_app_ip() {
echo "------------------------"
echo "방문 주소:"
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

	# 컨테이너의 생성 시간과 이미지 이름을 가져옵니다.
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# 이미지 저장소 및 태그 추출
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# 기본 태그는 최신입니다.
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# 공식 이미지에 대한 지원 추가
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# Docker Hub API에서 이미지 릴리스 시간 가져오기
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# 획득한 시간을 확인
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# 타임스탬프 비교
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

	# 컨테이너의 IP 주소 가져오기
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 다른 모든 IP를 확인하고 차단하세요.
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 지정된 IP 확인 및 해제
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 127.0.0.0/8 확인 및 허용
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# 다른 모든 IP를 확인하고 차단하세요.
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 지정된 IP 확인 및 해제
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 127.0.0.0/8 확인 및 허용
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+포트가 서비스 접근을 차단했습니다."
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# 컨테이너의 IP 주소 가져오기
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 다른 모든 IP를 차단하는 명확한 규칙
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 특정 IP를 허용하는 규칙 지우기
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 127.0.0.0/8을 허용하는 규칙을 지웁니다.
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# 다른 모든 IP를 차단하는 명확한 규칙
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 특정 IP를 허용하는 규칙 지우기
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# 로컬 네트워크 127.0.0.0/8을 허용하는 규칙을 지웁니다.
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+포트로 서비스 접속이 허용되었습니다"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "오류: 액세스를 허용하려면 포트 번호와 IP를 입력하세요."
		echo "사용법: block_host_port <포트 번호> <허용 IP>"
		return 1
	fi

	install iptables


	# 다른 모든 IP의 접근을 거부
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 지정된 IP에 대한 접근을 허용
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 로컬 액세스 허용
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 다른 모든 IP의 접근을 거부
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 지정된 IP에 대한 접근을 허용
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# 로컬 액세스 허용
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 확립된 관련 연결에 대한 트래픽 허용
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "IP+포트가 서비스 접근을 차단했습니다."
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "오류: 액세스를 허용하려면 포트 번호와 IP를 입력하세요."
		echo "사용법:clear_host_port_rules <포트 번호> <허용 IP>"
		return 1
	fi

	install iptables


	# 다른 모든 IP의 접근을 차단하는 규칙을 삭제하세요.
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# 로컬 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 지정된 IP로부터의 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 다른 모든 IP의 접근을 차단하는 규칙을 삭제하세요.
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# 로컬 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 지정된 IP로부터의 액세스를 허용하는 명확한 규칙
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "IP+포트로 서비스 접속이 허용되었습니다"
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
send_stats "${docker_name}관리하다"

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
	echo "1. 설치 2. 업데이트 3. 제거"
	echo "------------------------"
	echo "5. 도메인 이름 액세스 추가 6. 도메인 이름 액세스 삭제"
	echo "7. IP+포트 접근 허용 8. IP+포트 접근 차단"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택사항을 입력하세요:" choice
	 case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			read -e -p "애플리케이션 외부 서비스 포트를 입력하고 Enter 키를 누르면 기본적으로 사용됩니다.${docker_port}포트:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			add_app_id

			clear
			echo "$docker_name설치 완료"
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

			add_app_id

			clear
			echo "$docker_name설치 완료"
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

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "앱이 제거되었습니다."
			send_stats "제거$docker_name"
			;;

		5)
			echo "${docker_name}도메인 이름 액세스 설정"
			send_stats "${docker_name}도메인 이름 액세스 설정"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "https://가 없는 도메인 이름 형식 example.com"
			web_del
			;;

		7)
			send_stats "IP 액세스 허용${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "IP 접근 차단${docker_name}"
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
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "------------------------"
		echo "5. 도메인 이름 액세스 추가 6. 도메인 이름 액세스 삭제"
		echo "7. IP+포트 접근 허용 8. IP+포트 접근 차단"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택 항목을 입력하세요." choice
		case $choice in
			1)
				setup_docker_dir
				check_disk_space $app_size /home/docker
				read -e -p "애플리케이션 외부 서비스 포트를 입력하고 Enter 키를 누르면 기본적으로 사용됩니다.${docker_port}포트:" app_port
				local app_port=${app_port:-${docker_port}}
				local docker_port=$app_port
				install jq
				install_docker
				docker_app_install
				echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

				add_app_id
				;;
			2)
				docker_app_update

				add_app_id
				;;
			3)
				docker_app_uninstall
				rm -f /home/docker/${docker_name}_port.conf

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt

				;;
			5)
				echo "${docker_name}도메인 이름 액세스 설정"
				send_stats "${docker_name}도메인 이름 액세스 설정"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "https://가 없는 도메인 이름 형식 example.com"
				web_del
				;;
			7)
				send_stats "IP 액세스 허용${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "IP 접근 차단${docker_name}"
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

# 세션이 존재하는지 확인하는 함수
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 존재하지 않는 세션 이름을 찾을 때까지 반복
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 새 tmux 세션 만들기
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
		check_f2b_status="${gl_lv}已安装${gl_bai}"
	else
		check_f2b_status="${gl_hui}未安装${gl_bai}"
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
		echo "다시 시작됨"
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
	echo -e "${gl_huang}힌트:${gl_bai}홈페이지 구축 환경이 설치되었습니다. 다시 설치할 필요가 없습니다!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "LDNMP 환경 설치"
root_use
clear
echo -e "${gl_huang}LDNMP 환경이 설치되지 않았습니다. LDNMP 환경 설치를 시작합니다...${gl_bai}"
check_disk_space 3 /home
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "nginx 환경 설치"
root_use
clear
echo -e "${gl_huang}nginx가 설치되지 않았습니다. nginx 환경 설치를 시작하세요...${gl_bai}"
check_disk_space 1 /home
check_port
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "nginx가 설치되었습니다"
echo -e "현재 버전:${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "먼저 LDNMP 환경을 설치해 주세요"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "먼저 nginx 환경을 설치해주세요"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "당신의$webname지어졌습니다!"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webname설치정보는 다음과 같습니다."

}

nginx_web_on() {
	  clear
	  echo "당신의$webname지어졌습니다!"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "설치하다$webname"
  echo "배포 시작$webname"
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

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "설치하다$webname"
	echo "배포 시작$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "안티 세대 IP를 입력하세요:" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "안티 세대 포트를 입력하십시오:" port
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
	echo "배포 시작$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "여러 개의 세대 방지 IP+포트를 공백으로 구분하여 입력하세요(예: 127.0.0.1:3000 127.0.0.1:3002)." reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	sed -i "s/# 动态添加/$upstream_servers/g" /home/web/conf.d/$yuming.conf

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
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
		send_stats "LDNMP 사이트 관리"
		echo "LDNMP 환경"
		echo "------------------------"
		ldnmp_v

		echo -e "대지:${output}인증서 만료 시간"
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
		echo -e "데이터 베이스:${db_output}"
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
		echo "1. 도메인 이름 인증서 적용/업데이트 2. 사이트 도메인 이름 변경"
		echo "3. 사이트 캐시 지우기 4. 관련 사이트 생성"
		echo "5. 접속 로그 보기 6. 오류 로그 보기"
		echo "7. 전역 구성 편집 8. 사이트 구성 편집"
		echo "9. 사이트 데이터베이스 관리 10. 사이트 분석 보고서 보기"
		echo "------------------------"
		echo "20. 특정 사이트 데이터 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택사항을 입력하세요:" sub_choice
		case $sub_choice in
			1)
				send_stats "도메인 이름 인증서 신청"
				read -e -p "도메인 이름을 입력하세요:" yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "사이트 도메인 이름 변경"
				echo -e "${gl_hong}적극 권장:${gl_bai}전체 사이트 데이터를 먼저 백업하고 사이트 도메인 이름을 변경하세요!"
				read -e -p "이전 도메인 이름을 입력하세요:" oddyuming
				read -e -p "새 도메인 이름을 입력하세요:" yuming
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

				# 웹사이트 디렉토리 교체
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
				send_stats "연결된 사이트 만들기"
				echo -e "액세스하려면 새 도메인 이름을 기존 사이트에 연결하세요."
				read -e -p "기존 도메인 이름을 입력하세요:" oddyuming
				read -e -p "새 도메인 이름을 입력하세요:" yuming
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
				send_stats "접속 로그 보기"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "오류 로그 보기"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "전역 구성 편집"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "사이트 구성 편집"
				read -e -p "사이트 구성을 편집하려면 편집하려는 도메인 이름을 입력하십시오:" yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "사이트 데이터 보기"
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
	echo "${panelname}대중적이고 강력한 운영 및 유지 관리 관리 패널입니다."
	echo "공식 웹사이트 소개:$panelurl "

	echo ""
	echo "------------------------"
	echo "1. 설치 2. 관리 3. 제거"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택사항을 입력하세요:" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install

			add_app_id
			send_stats "${panelname}설치하다"
			;;
		2)
			panel_app_manage

			add_app_id
			send_stats "${panelname}제어"

			;;
		3)
			panel_app_uninstall

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			send_stats "${panelname}제거"
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

	send_stats "FRP 서버 설치"
	# 임의의 포트 및 자격 증명 생성
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

	# 생성된 정보 출력
	ip_address
	echo "------------------------"
	echo "클라이언트 배포에 필요한 매개변수"
	echo "서비스 IP:$ipv4_address"
	echo "token: $token"
	echo
	echo "FRP 패널 정보"
	echo "FRP 패널 주소: http://$ipv4_address:$dashboard_port"
	echo "FRP 패널 사용자 이름:$dashboard_user"
	echo "FRP 패널 비밀번호:$dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "FRP 클라이언트 설치"
	read -e -p "외부 네트워크 도킹 IP를 입력하세요." server_addr
	read -e -p "외부 네트워크 도킹 토큰을 입력하세요." token
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
	send_stats "FRP 인트라넷 서비스 추가"
	# 사용자에게 서비스 이름 및 전달 정보를 묻는 메시지를 표시합니다.
	read -e -p "서비스 이름을 입력하세요:" service_name
	read -e -p "전달 유형(tcp/udp)을 입력하십시오. [기본값을 tcp로 입력]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "인트라넷 IP를 입력하십시오. [Enter를 누르면 기본값은 127.0.0.1입니다]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "인트라넷 포트를 입력하십시오:" local_port
	read -e -p "외부 네트워크 포트를 입력하세요:" remote_port

	# 구성 파일에 사용자 입력 쓰기
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 생성된 정보 출력
	echo "제공하다$service_namefrpc.toml에 성공적으로 추가되었습니다."

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "FRP 인트라넷 서비스 삭제"
	# 삭제해야 하는 서비스 이름을 입력하라는 메시지를 사용자에게 표시합니다.
	read -e -p "삭제할 서비스 이름을 입력하세요:" service_name
	# sed를 사용하여 서비스 및 관련 구성 삭제
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "제공하다$service_namefrpc.toml에서 성공적으로 제거되었습니다."

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# 헤더 인쇄
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
		# 서비스 정보가 이미 존재하는 경우 새 서비스를 처리하기 전에 현재 서비스를 인쇄하십시오.
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 현재 서비스 이름 업데이트
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# 이전 값 지우기
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
		# 마지막 서비스에 대한 정보 인쇄
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# FRP 서버 포트 가져오기
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# 액세스 주소 생성
generate_access_urls() {
	# 먼저 모든 포트를 확보하십시오.
	get_frp_ports

	# 8055/8056 이외의 포트가 있는지 확인하세요.
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# 유효한 포트가 있는 경우에만 제목과 내용 표시
	if [ "$has_valid_ports" = true ]; then
		echo "FRP 서비스 외부 액세스 주소:"

		# IPv4 주소 처리
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# IPv6 주소가 있는 경우 처리
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
	local app_id="55"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP 서버$check_frp $update_status"
		echo "FRP 인트라넷 침투 서비스 환경을 구축하고 공인 IP가 없는 장치를 인터넷에 노출시킵니다."
		echo "공식 홈페이지 소개: https://github.com/fatedier/frp/"
		echo "비디오 튜토리얼: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "------------------------"
		echo "5. 인트라넷 서비스 도메인 이름 접근 6. 도메인 이름 접근 삭제"
		echo "------------------------"
		echo "7. IP+포트 접근 허용 8. IP+포트 접근 차단"
		echo "------------------------"
		echo "00. 서비스 상태 새로고침 0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택 항목을 입력하세요." choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config

				add_app_id
				echo "FRP 서버가 설치되었습니다"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps

				add_app_id
				echo "FRP 서버가 업데이트되었습니다"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "앱이 제거되었습니다."
				;;
			5)
				echo "도메인 이름 액세스에 대한 역인트라넷 침투 서비스"
				send_stats "FRP 외부 도메인 이름 액세스"
				add_yuming
				read -e -p "인트라넷 침투 서비스 포트를 입력하십시오:" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "https://가 없는 도메인 이름 형식 example.com"
				web_del
				;;

			7)
				send_stats "IP 액세스 허용"
				read -e -p "해제해야 하는 포트를 입력하세요." frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "IP 접근 차단"
				echo "역방향 도메인 이름 접근을 가지고 있는 경우, 이 기능을 사용하면 IP+포트 접근을 차단할 수 있어 더욱 안전합니다."
				read -e -p "차단할 포트를 입력하세요:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "FRP 서비스 상태 새로 고침"
				echo "FRP 서비스 상태가 새로 고쳐졌습니다."
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
	local app_id="56"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRP 클라이언트$check_frp $update_status"
		echo "서버에 연결하세요. 연결 후에는 인트라넷 침투 서비스를 만들어 인터넷에 액세스할 수 있습니다."
		echo "공식 홈페이지 소개: https://github.com/fatedier/frp/"
		echo "비디오 튜토리얼: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "------------------------"
		echo "4. 외부 서비스 추가 5. 외부 서비스 삭제 6. 서비스 수동 구성"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택 항목을 입력하세요." choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc

				add_app_id
				echo "FRP 클라이언트가 설치되었습니다"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc

				add_app_id
				echo "FRP 클라이언트가 업데이트되었습니다."
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "앱이 제거되었습니다."
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
		   local YTDLP_STATUS="${gl_lv}已安装${gl_bai}"
		else
		   local YTDLP_STATUS="${gl_hui}未安装${gl_bai}"
		fi

		clear
		send_stats "yt-dlp 다운로드 도구"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp는 YouTube, Bilibili, Twitter 등과 같은 수천 개의 사이트를 지원하는 강력한 비디오 다운로드 도구입니다."
		echo -e "공식 홈페이지 주소: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "다운로드한 동영상 목록:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(아직 없음)"
		echo "-------------------------"
		echo "1. 설치 2. 업데이트 3. 제거"
		echo "-------------------------"
		echo "5. 단일 비디오 다운로드 6. 일괄 비디오 다운로드 7. 사용자 정의 매개변수 다운로드"
		echo "8. MP3 오디오로 다운로드 9. 비디오 디렉터리 삭제 10. 쿠키 관리(개발 중)"
		echo "-------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "-------------------------"
		read -e -p "옵션 번호를 입력하세요:" choice

		case $choice in
			1)
				send_stats "yt-dlp 설치 중..."
				echo "yt-dlp 설치 중..."
				install ffmpeg
				curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				chmod a+rx /usr/local/bin/yt-dlp

				add_app_id
				echo "설치가 완료되었습니다. 계속하려면 아무 키나 누르세요..."
				read ;;
			2)
				send_stats "yt-dlp 업데이트 중..."
				echo "yt-dlp 업데이트 중..."
				yt-dlp -U

				add_app_id
				echo "업데이트가 완료되었습니다. 계속하려면 아무 키나 누르세요..."
				read ;;
			3)
				send_stats "yt-dlp 제거 중..."
				echo "yt-dlp 제거 중..."
				rm -f /usr/local/bin/yt-dlp

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "제거가 완료되었습니다. 계속하려면 아무 키나 누르세요..."
				read ;;
			5)
				send_stats "단일 비디오 다운로드"
				read -e -p "동영상 링크를 입력하세요:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "다운로드가 완료되었습니다. 계속하려면 아무 키나 누르세요..." ;;
			6)
				send_stats "일괄 비디오 다운로드"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# 여러 개의 동영상 링크 주소를 입력하세요\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "지금 일괄 다운로드를 시작하세요..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "일괄 다운로드가 완료되었습니다. 계속하려면 아무 키나 누르세요..." ;;
			7)
				send_stats "맞춤형 비디오 다운로드"
				read -e -p "전체 yt-dlp 매개변수를 입력하세요(yt-dlp 제외)." custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "실행이 완료되었습니다. 계속하려면 아무 키나 누르세요..." ;;
			8)
				send_stats "MP3 다운로드"
				read -e -p "동영상 링크를 입력하세요:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "오디오 다운로드가 완료되었습니다. 계속하려면 아무 키나 누르세요..." ;;

			9)
				send_stats "동영상 삭제"
				read -e -p "삭제된 동영상의 이름을 입력하세요:" rmdir
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



# dpkg 중단 문제 수정
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}시스템 업데이트 진행 중...${gl_bai}"
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
		echo "알 수 없는 패키지 관리자입니다!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}시스템 청소 진행 중...${gl_bai}"
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
		echo "패키지 관리자 캐시 정리..."
		apk cache clean
		echo "시스템 로그 삭제..."
		rm -rf /var/log/*
		echo "APK 캐시 삭제..."
		rm -rf /var/cache/apk/*
		echo "임시 파일 삭제..."
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
		echo "시스템 로그 삭제..."
		rm -rf /var/log/*
		echo "임시 파일 삭제..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "사용하지 않는 종속성을 정리합니다..."
		pkg autoremove -y
		echo "패키지 관리자 캐시 정리..."
		pkg clean -y
		echo "시스템 로그 삭제..."
		rm -rf /var/log/*
		echo "임시 파일 삭제..."
		rm -rf /tmp/*

	else
		echo "알 수 없는 패키지 관리자입니다!"
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

chattr -i /etc/resolv.conf
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

chattr +i /etc/resolv.conf

}


set_dns_ui() {
root_use
send_stats "DNS 최적화"
while true; do
	clear
	echo "DNS 주소 최적화"
	echo "------------------------"
	echo "현재 DNS 주소"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 외국 DNS 최적화:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. 국내 DNS 최적화:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. DNS 구성을 수동으로 편집"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택사항을 입력하세요:" Limiting
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
		chattr -i /etc/resolv.conf
		nano /etc/resolv.conf
		chattr +i /etc/resolv.conf
		send_stats "DNS 구성을 수동으로 편집"
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

	# 발견된 경우 PasswordAuthentication이 yes로 설정되어 있습니다.
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# 발견된 경우 PubkeyAuthentication이 yes로 설정되어 있습니다.
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# PasswordAuthentication과 PubkeyAuthentication이 모두 일치하지 않는 경우 기본값을 설정합니다.
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # SSH 구성 파일 백업
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSH 포트가 다음과 같이 수정되었습니다.$new_port"

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
	echo -e "개인키 정보가 생성되었습니다. 꼭 복사해서 저장하세요. 다음과 같이 저장될 수 있습니다.${gl_huang}${ipv4_address}_ssh.key${gl_bai}향후 SSH 로그인을 위한 파일"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ROOT 개인키 로그인이 활성화되어 있고, ROOT 비밀번호 로그인이 비활성화되어 재접속이 적용됩니다.${gl_bai}"

}


import_sshkey() {

	read -e -p "SSH 공개 키(일반적으로 'ssh-rsa' 또는 'ssh-ed25519'로 시작)의 내용을 입력하세요." public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}오류: 공개 키 내용이 입력되지 않았습니다.${gl_bai}"
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
	echo -e "${gl_lv}공개 키를 성공적으로 가져왔고 ROOT 개인 키 로그인이 활성화되었으며 ROOT 비밀번호 로그인이 종료되었습니다. 다시 연결이 적용됩니다.${gl_bai}"

}




add_sshpasswd() {

echo "루트 비밀번호를 설정하세요"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ROOT 로그인 설정이 완료되었습니다!${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}힌트:${gl_bai}이 기능을 실행하려면 루트 사용자가 필요합니다!" && break_end && kejilion
}



dd_xitong() {
		send_stats "시스템 재설치"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "재설치 후 초기 사용자 이름:${gl_huang}root${gl_bai}초기 비밀번호:${gl_huang}LeitboGi0ro${gl_bai}초기 포트:${gl_huang}22${gl_bai}"
		  echo -e "계속하려면 아무 키나 누르세요..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "재설치 후 초기 사용자 이름:${gl_huang}Administrator${gl_bai}초기 비밀번호:${gl_huang}Teddysun.com${gl_bai}초기 포트:${gl_huang}3389${gl_bai}"
		  echo -e "계속하려면 아무 키나 누르세요..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "재설치 후 초기 사용자 이름:${gl_huang}root${gl_bai}초기 비밀번호:${gl_huang}123@@@${gl_bai}초기 포트:${gl_huang}22${gl_bai}"
		  echo -e "계속하려면 아무 키나 누르세요..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "재설치 후 초기 사용자 이름:${gl_huang}Administrator${gl_bai}초기 비밀번호:${gl_huang}123@@@${gl_bai}초기 포트:${gl_huang}3389${gl_bai}"
		  echo -e "계속하려면 아무 키나 누르세요..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "시스템 재설치"
			echo "--------------------------------"
			echo -e "${gl_hong}알아채다:${gl_bai}재설치 시 연결이 끊어질 수 있으니 걱정되시는 분들은 주의해서 사용해주세요. 재설치에는 약 15분 정도 소요될 예정이오니, 사전에 데이터를 백업해 주시기 바랍니다."
			echo -e "${gl_hui}스크립트를 지원해주신 leitbogioro 보스와 bin456789 보스에게 감사드립니다!${gl_bai} "
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
			echo "35. openSUSE Tumbleweed 36. fnos Feiniu 공개 베타 버전"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2025"
			echo "45. Windows Server 2022       46. Windows Server 2019"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 이전 메뉴로 돌아가기"
			echo "------------------------"
			read -e -p "다시 설치하려는 시스템을 선택하십시오:" sys_choice
			case "$sys_choice" in


			  1)
				send_stats "데비안 13 재설치"
				dd_xitong_3
				bash reinstall.sh debian 13
				reboot
				exit
				;;

			  2)
				send_stats "데비안 12 다시 설치"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  3)
				send_stats "데비안 11 다시 설치"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  4)
				send_stats "데비안 10 다시 설치"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  11)
				send_stats "우분투 24.04 다시 설치"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "우분투 22.04 다시 설치"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "우분투 20.04 다시 설치"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "우분투 18.04 다시 설치"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "rockylinux10 재설치"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "rockylinux9 재설치"
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				send_stats "alma10 재설치"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "alma9 재설치"
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				send_stats "oracle10 재설치"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "oracle9 재설치"
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				send_stats "fedora42 재설치"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "fedora41 재설치"
				dd_xitong_3
				bash reinstall.sh fedora 41
				reboot
				exit
				;;

			  29)
				send_stats "centos10 재설치"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "centos9 재설치"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "알파인 재설치"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "아치 재설치"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "칼리 재설치"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "openeuler 다시 설치"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "Openuse 다시 설치"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "Feiniu 재설치"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;

			  41)
				send_stats "윈도우 11 재설치"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;

			  42)
				dd_xitong_2
				send_stats "윈도우 10 재설치"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;

			  43)
				send_stats "Windows7을 다시 설치하세요."
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "Windows Server 25를 다시 설치하세요."
				dd_xitong_2
				bash InstallNET.sh -windows 2025 -lang "cn"
				reboot
				exit
				;;

			  45)
				send_stats "윈도우 서버 22 재설치"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;

			  46)
				send_stats "윈도우 서버 19 재설치"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "windows11 ARM 재설치"
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
		  send_stats "bbrv3 관리"

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
				  echo "xanmod의 BBRv3 커널이 설치되어 있습니다."
				  echo "현재 커널 버전:$kernel_version"

				  echo ""
				  echo "커널 관리"
				  echo "------------------------"
				  echo "1. BBRv3 커널 업데이트 2. BBRv3 커널 제거"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택사항을 입력하세요:" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# 3단계: 저장소 추가
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "XanMod 커널이 업데이트되었습니다. 재시작 후 적용"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "XanMod 커널이 제거되었습니다. 재시작 후 적용"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "BBR3 가속 설정"
		  echo "영상 소개: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		  echo "------------------------------------------------"
		  echo "데비안/우분투만 지원"
		  echo "데이터를 백업해 주시면 Linux 커널을 업그레이드하고 BBR3을 활성화하겠습니다."
		  echo "------------------------------------------------"
		  read -e -p "계속하시겠습니까? (예/아니요):" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "현재 환경에서는 지원하지 않습니다. Debian 및 Ubuntu 시스템만 지원됩니다."
					break_end
					linux_Settings
				fi
			else
				echo "운영 체제 유형을 확인할 수 없습니다."
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# 3단계: 저장소 추가
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "XanMod 커널이 설치되고 BBR3이 성공적으로 활성화되었습니다. 재시작 후 적용"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "취소"
			  ;;
			*)
			  echo "선택이 잘못되었습니다. Y 또는 N을 입력하세요."
			  ;;
		  esac
		fi

}


elrepo_install() {
	# ELRepo GPG 공개 키 가져오기
	echo "ELRepo GPG 공개 키 가져오기..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# 시스템 버전 확인
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# 지원되는 운영 체제에서 실행되고 있는지 확인하세요.
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "지원되지 않는 운영 체제:$os_name"
		break_end
		linux_Settings
	fi
	# 감지된 운영 체제 정보 인쇄
	echo "감지된 운영 체제:$os_name $os_version"
	# 시스템 버전에 따라 해당 ELRepo 창고 구성을 설치하십시오.
	if [[ "$os_version" == 8 ]]; then
		echo "ELRepo 저장소 구성(버전 8) 설치 중..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "ELRepo 저장소 구성(버전 9) 설치 중..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "ELRepo 저장소 구성(버전 10) 설치 중..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "지원되지 않는 시스템 버전:$os_version"
		break_end
		linux_Settings
	fi
	# ELRepo 커널 저장소를 활성화하고 최신 메인라인 커널을 설치합니다.
	echo "ELRepo 커널 저장소를 활성화하고 최신 메인라인 커널을 설치하세요..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "ELRepo 저장소 구성을 설치하고 최신 메인라인 커널로 업데이트했습니다."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "Red Hat 커널 관리"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "elrepo 커널을 설치했습니다"
				  echo "현재 커널 버전:$kernel_version"

				  echo ""
				  echo "커널 관리"
				  echo "------------------------"
				  echo "1. elrepo 커널 업데이트 2. elrepo 커널 제거"
				  echo "------------------------"
				  echo "0. 이전 메뉴로 돌아가기"
				  echo "------------------------"
				  read -e -p "선택사항을 입력하세요:" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "Red Hat 커널 업데이트"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "elrepo 커널이 제거되었습니다. 재시작 후 적용"
						send_stats "Red Hat 커널 제거"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "데이터를 백업해 주시면 Linux 커널을 업그레이드해 드리겠습니다."
		  echo "영상 소개: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		  echo "------------------------------------------------"
		  echo "Red Hat 시리즈 배포판 CentOS/RedHat/Alma/Rocky/oracle만 지원"
		  echo "Linux 커널을 업그레이드하면 시스템 성능과 보안이 향상될 수 있습니다. 가능하다면 시도해 보시고, 프로덕션 환경도 주의해서 업그레이드하시는 것을 추천드립니다!"
		  echo "------------------------------------------------"
		  read -e -p "계속하시겠습니까? (예/아니요):" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "Red Hat 커널 업그레이드"
			  server_reboot
			  ;;
			[Nn])
			  echo "취소"
			  ;;
			*)
			  echo "선택이 잘못되었습니다. Y 또는 N을 입력하세요."
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}바이러스 데이터베이스 업데이트 중...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "스캔할 디렉터리를 지정하십시오."
		return
	fi

	echo -e "${gl_huang}$@ 디렉터리를 검색하는 중...${gl_bai}"

	# 마운트 매개변수 빌드
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# clamscan 명령 매개변수 빌드
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# 도커 명령 실행
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ 검사가 완료되고 바이러스 보고서가 다음 위치에 저장됩니다.${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}바이러스 있으면 제발${gl_huang}scan.log${gl_lv}파일에서 FOUND 키워드를 검색하여 바이러스 위치를 확인하세요.${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "바이러스 검사 관리"
		  while true; do
				clear
				echo "clamav 바이러스 검사 도구"
				echo "영상 소개: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
				echo "------------------------"
				echo "다양한 유형의 악성 코드를 탐지하고 제거하는 데 주로 사용되는 오픈 소스 바이러스 백신 소프트웨어 도구입니다."
				echo "바이러스, 트로이 목마, 스파이웨어, 악성 스크립트 및 기타 유해한 소프트웨어가 포함됩니다."
				echo "------------------------"
				echo -e "${gl_lv}1. 전체 스캔${gl_bai}             ${gl_huang}2. 중요한 디렉토리 스캔${gl_bai}            ${gl_kjlan}3. 사용자 정의 디렉터리 검색${gl_bai}"
				echo "------------------------"
				echo "0. 이전 메뉴로 돌아가기"
				echo "------------------------"
				read -e -p "선택사항을 입력하세요:" sub_choice
				case $sub_choice in
					1)
					  send_stats "전체 스캔"
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
					  read -e -p "스캔할 디렉터리를 공백으로 구분하여 입력하십시오(예: /etc /var /usr /home /root)." directories
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
	echo -e "${gl_lv}로 전환하다${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}가상 메모리 최적화...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}기타 최적화...${gl_bai}"
	# 대기 시간을 줄이기 위해 투명한 대용량 페이지를 비활성화합니다.
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱 비활성화
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# 균형 모드 최적화 기능
optimize_balanced() {
	echo -e "${gl_lv}이퀄라이제이션 모드로 전환...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}가상 메모리 최적화...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}기타 최적화...${gl_bai}"
	# 투명한 대용량 페이지 복원
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱 복원
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# 기본 설정 복원 기능
restore_defaults() {
	echo -e "${gl_lv}기본 설정으로 되돌리기...${gl_bai}"

	echo -e "${gl_lv}파일 설명자를 복원합니다...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}가상 메모리 복원...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 재설정...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 복원...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}CPU 설정 복원...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}다른 최적화 되돌리기...${gl_bai}"
	# 투명한 대용량 페이지 복원
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱 복원
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# 웹사이트 구축 최적화 기능
optimize_web_server() {
	echo -e "${gl_lv}웹사이트 구축 최적화 모드로 전환...${gl_bai}"

	echo -e "${gl_lv}파일 설명자 최적화...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}가상 메모리 최적화...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}네트워크 설정 최적화...${gl_bai}"
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

	echo -e "${gl_lv}캐시 관리 최적화...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU 설정 최적화...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}기타 최적화...${gl_bai}"
	# 대기 시간을 줄이기 위해 투명한 대용량 페이지를 비활성화합니다.
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# NUMA 밸런싱 비활성화
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linux 커널 튜닝 관리"
	  echo "Linux 시스템 커널 매개변수 최적화"
	  echo "영상 소개: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "다양한 시스템 매개변수 조정 모드를 제공하며 사용자는 자신의 사용 시나리오에 따라 전환하도록 선택할 수 있습니다."
	  echo -e "${gl_huang}힌트:${gl_bai}프로덕션 환경에서는 주의해서 사용해주세요!"
	  echo "--------------------"
	  echo "1. 고성능 최적화 모드: 시스템 성능을 최대화하고 파일 설명자, 가상 메모리, 네트워크 설정, 캐시 관리 및 CPU 설정을 최적화합니다."
	  echo "2. 균형 잡힌 최적화 모드: 일상적인 사용에 적합한 성능과 리소스 소비 사이의 균형을 유지합니다."
	  echo "3. 웹사이트 최적화 모드: 웹사이트 서버를 최적화하여 동시 연결 처리 기능, 응답 속도 및 전반적인 성능을 향상시킵니다."
	  echo "4. 라이브 방송 최적화 모드: 라이브 스트리밍의 특별한 요구 사항을 최적화하여 지연을 줄이고 전송 성능을 향상시킵니다."
	  echo "5. 게임 서버 최적화 모드: 게임 서버를 최적화하여 동시 처리 기능과 응답 속도를 향상시킵니다."
	  echo "6. 기본 설정 복원: 시스템 설정을 기본 구성으로 복원합니다."
	  echo "--------------------"
	  echo "0. 이전 메뉴로 돌아가기"
	  echo "--------------------"
	  read -e -p "선택사항을 입력하세요:" sub_choice
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
			  send_stats "웹사이트 최적화 모드"
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
			  send_stats "기본 설정 복원"
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
				echo -e "${gl_lv}시스템 언어가 다음과 같이 수정되었습니다.$lang적용하려면 SSH에 다시 연결하세요.${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}시스템 언어가 다음과 같이 수정되었습니다.$lang적용하려면 SSH에 다시 연결하세요.${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "지원되지 않는 시스템:$ID"
				break_end
				;;
		esac
	else
		echo "지원되지 않는 시스템, 시스템 유형을 식별할 수 없습니다."
		break_end
	fi
}




linux_language() {
root_use
send_stats "시스템 언어 전환"
while true; do
  clear
  echo "현재 시스템 언어:$LANG"
  echo "------------------------"
  echo "1. 영어 2. 중국어 간체 3. 중국어 번체"
  echo "------------------------"
  echo "0. 이전 메뉴로 돌아가기"
  echo "------------------------"
  read -e -p "선택 항목을 입력하세요." choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "영어로 전환"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "중국어 간체로 전환"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "중국어 번체로 전환"
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
echo -e "${gl_lv}변경이 완료되었습니다. 변경 사항을 보려면 SSH에 다시 연결하세요!${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "명령줄 미화 도구"
  while true; do
	clear
	echo "명령줄 미화 도구"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택 항목을 입력하세요." choice

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
  send_stats "시스템 휴지통"

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
	echo -e "현재 휴지통${trash_status}"
	echo -e "활성화한 후에는 중요한 파일이 실수로 삭제되는 것을 방지하기 위해 rm으로 삭제된 파일이 먼저 휴지통에 들어갑니다!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "휴지통이 비어 있습니다."
	echo "------------------------"
	echo "1. 휴지통 활성화 2. 휴지통 닫기"
	echo "3. 콘텐츠 복원 4. 휴지통 비우기"
	echo "------------------------"
	echo "0. 이전 메뉴로 돌아가기"
	echo "------------------------"
	read -e -p "선택 항목을 입력하세요." choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "휴지통이 활성화되면 삭제된 파일은 휴지통으로 이동됩니다."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "휴지통이 닫히고 파일이 직접 삭제됩니다."
		sleep 2
		;;
	  3)
		read -e -p "복원할 파일 이름을 입력하세요:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restore홈 디렉토리로 복원되었습니다."
		else
		  echo "파일이 존재하지 않습니다."
		fi
		;;
	  4)
		read -e -p "휴지통을 비우시겠습니까? [예/아니요]:" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "휴지통이 비워졌습니다."
		fi
		;;
	  *)
		break
		;;
	esac
  done
}

linux_fav() {
send_stats "명령 즐겨찾기"
bash <(curl -l -s ${gh_proxy}raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh)
}

# 백업 만들기
create_backup() {
	send_stats "백업 만들기"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# 사용자에게 백업 디렉터리를 묻는 메시지 표시
	echo "백업 생성 예:"
	echo "- 단일 디렉터리 백업: /var/www"
	echo "- 여러 디렉터리 백업: /etc /home /var/log"
	echo "- Enter를 눌러 기본 디렉터리(/etc/usr/home)를 사용합니다."
	read -r -p "백업할 디렉터리를 입력하십시오(여러 디렉터리를 공백으로 구분하고 Enter를 눌러 기본 디렉터리를 사용하십시오)." input

	# 사용자가 디렉터리를 입력하지 않으면 기본 디렉터리가 사용됩니다.
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# 사용자가 입력한 디렉토리를 공백으로 배열로 구분합니다.
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# 백업 파일 접두사 생성
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# 디렉토리 이름 추출 및 슬래시 제거
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 마지막 밑줄 제거
	local PREFIX=${PREFIX%_}

	# 백업 파일 이름 생성
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# 사용자가 선택한 디렉토리 인쇄
	echo "선택한 백업 디렉터리는 다음과 같습니다."
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# 백업 만들기
	echo "백업 생성$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# 명령이 성공했는지 확인
	if [ $? -eq 0 ]; then
		echo "백업이 성공적으로 생성되었습니다:$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "백업 생성에 실패했습니다!"
		exit 1
	fi
}

# 백업 복원
restore_backup() {
	send_stats "백업 복원"
	# 복원할 백업을 선택하세요
	read -e -p "복원할 백업 파일 이름을 입력하십시오:" BACKUP_NAME

	# 백업 파일이 있는지 확인
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "백업 파일이 존재하지 않습니다!"
		exit 1
	fi

	echo "백업 복원 중$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "백업 및 복원 성공!"
	else
		echo "백업 복원에 실패했습니다!"
		exit 1
	fi
}

# 백업 나열
list_backups() {
	echo "사용 가능한 백업:"
	ls -1 "$BACKUP_DIR"
}

# 백업 삭제
delete_backup() {
	send_stats "백업 삭제"

	read -e -p "삭제할 백업 파일 이름을 입력하십시오:" BACKUP_NAME

	# 백업 파일이 있는지 확인
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "백업 파일이 존재하지 않습니다!"
		exit 1
	fi

	# 백업 삭제
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "백업이 삭제되었습니다!"
	else
		echo "백업 삭제에 실패했습니다!"
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
		echo "1. 백업 생성 2. 백업 복원 3. 백업 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택사항을 입력하세요:" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "계속하려면 Enter를 누르세요..."
	done
}









# 연결 목록 표시
list_connections() {
	echo "저장된 연결:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 새 연결 추가
add_connection() {
	send_stats "새 연결 추가"
	echo "새 연결 생성의 예:"
	echo "- 연결 이름: my_server"
	echo "- IP 주소: 192.168.1.100"
	echo "- 사용자 이름: 루트"
	echo "- 포트: 22"
	echo "------------------------"
	read -e -p "연결 이름을 입력하세요:" name
	read -e -p "IP 주소를 입력하세요:" ip
	read -e -p "사용자 이름을 입력하십시오(기본값: 루트):" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "포트 번호를 입력하십시오(기본값: 22):" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "인증 방법을 선택하세요:"
	echo "1. 비밀번호"
	echo "2. 열쇠"
	read -e -p "원하는 항목(1/2)을 입력하세요." auth_choice

	case $auth_choice in
		1)
			read -s -p "비밀번호를 입력하세요:" password_or_key
			echo  # 换行
			;;
		2)
			echo "주요 내용을 붙여넣으세요(붙인 후 Enter를 두 번 누르세요)."
			local password_or_key=""
			while IFS= read -r line; do
				# 입력이 빈 줄이고 키 내용에 이미 시작 부분이 포함되어 있으면 입력을 종료합니다.
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 첫 번째 줄이거나 이미 핵심 내용 입력을 시작했다면 계속해서 추가하세요.
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# 핵심 내용인지 확인하세요
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "잘못된 선택입니다!"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "연결이 저장되었습니다!"
}



# 연결 삭제
delete_connection() {
	send_stats "연결 삭제"
	read -e -p "삭제할 연결 번호를 입력하세요:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "오류: 해당 연결을 찾을 수 없습니다."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 연결이 키 파일을 사용하는 경우 키 파일을 삭제하세요.
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "연결이 삭제되었습니다!"
}

# 연결 사용
use_connection() {
	send_stats "연결 사용"
	read -e -p "사용할 연결 번호를 입력하세요:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "오류: 해당 연결을 찾을 수 없습니다."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "연결 중$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# 키를 사용하여 연결
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "연결에 실패했습니다! 다음 사항을 확인하세요."
			echo "1. 키파일 경로가 맞나요?$password_or_key"
			echo "2. 키 파일 권한이 올바른가요(600이어야 함)."
			echo "3. 대상 서버에서 키를 이용한 로그인을 허용하는지 여부."
		fi
	else
		# 비밀번호를 사용하여 연결
		if ! command -v sshpass &> /dev/null; then
			echo "오류: sshpass가 설치되지 않았습니다. 먼저 sshpass를 설치하십시오."
			echo "설치 방법:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "연결에 실패했습니다! 다음 사항을 확인하세요."
			echo "1. 사용자 이름과 비밀번호가 정확합니까?"
			echo "2. 대상 서버에서 비밀번호 로그인을 허용하는지 여부."
			echo "3. 대상 서버의 SSH 서비스가 정상적으로 실행되고 있는지 여부."
		fi
	fi
}


ssh_manager() {
	send_stats "SSH 원격 연결 도구"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 구성 파일과 키 디렉터리가 있는지 확인하고 없으면 만듭니다.
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
		echo "SSH를 통해 다른 Linux 시스템에 연결할 수 있습니다."
		echo "------------------------"
		list_connections
		echo "1. 새 연결 생성 2. 연결 사용 3. 연결 삭제"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택사항을 입력하세요:" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "선택이 잘못되었습니다. 다시 시도해 주세요." ;;
		esac
	done
}












# 사용 가능한 하드 디스크 파티션 나열
list_partitions() {
	echo "사용 가능한 하드 드라이브 파티션:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# 마운트 파티션
mount_partition() {
	send_stats "마운트 파티션"
	read -e -p "마운트할 파티션의 이름을 입력하십시오(예: sda1):" PARTITION

	# 파티션이 존재하는지 확인
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 파티션이 마운트되었는지 확인
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 마운트되었습니다!"
		return
	fi

	# 마운트 지점 생성
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# 마운트 파티션
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "파티션이 성공적으로 마운트되었습니다:$MOUNT_POINT"
	else
		echo "파티션 마운트에 실패했습니다!"
		rmdir "$MOUNT_POINT"
	fi
}

# 파티션 마운트 해제
unmount_partition() {
	send_stats "파티션 마운트 해제"
	read -e -p "마운트 해제할 파티션의 이름을 입력하십시오(예: sda1):" PARTITION

	# 파티션이 마운트되었는지 확인
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "파티션이 마운트되지 않았습니다!"
		return
	fi

	# 파티션 마운트 해제
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "파티션이 성공적으로 제거되었습니다:$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "파티션 제거에 실패했습니다!"
	fi
}

# 마운트된 파티션 나열
list_mounted_partitions() {
	echo "마운트된 파티션:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# 파티션 포맷
format_partition() {
	send_stats "파티션 포맷"
	read -e -p "포맷할 파티션의 이름을 입력하십시오(예: sda1):" PARTITION

	# 파티션이 존재하는지 확인
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 파티션이 마운트되었는지 확인
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 마운트되었습니다. 먼저 마운트를 해제하세요!"
		return
	fi

	# 파일 시스템 유형 선택
	echo "파일 시스템 유형을 선택하십시오:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "선택사항을 입력하세요:" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "잘못된 선택입니다!"; return ;;
	esac

	# 포맷 확인
	read -e -p "포맷된 파티션 /dev/ 확인$PARTITION~을 위한$FS_TYPE? (예/아니요):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "작업이 취소되었습니다."
		return
	fi

	# 파티션 포맷
	echo "파티션 /dev/ 포맷 중$PARTITION~을 위한$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "파티션이 성공적으로 포맷되었습니다!"
	else
		echo "파티션 포맷에 실패했습니다!"
	fi
}

# 파티션 상태 확인
check_partition() {
	send_stats "파티션 상태 확인"
	read -e -p "확인할 파티션 이름을 입력하세요(예: sda1):" PARTITION

	# 파티션이 존재하는지 확인
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "파티션이 존재하지 않습니다!"
		return
	fi

	# 파티션 상태 확인
	echo "파티션 확인 /dev/$PARTITION상태:"
	fsck "/dev/$PARTITION"
}

# 메인 메뉴
disk_manager() {
	send_stats "하드디스크 관리 기능"
	while true; do
		clear
		echo "하드 드라이브 파티션 관리"
		echo -e "${gl_huang}이 기능은 내부 테스트 중이므로 프로덕션 환경에서는 사용하면 안 됩니다.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. 파티션 마운트 2. 파티션 마운트 해제 3. 마운트된 파티션 보기"
		echo "4. 파티션 포맷 5. 파티션 상태 확인"
		echo "------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "------------------------"
		read -e -p "선택사항을 입력하세요:" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "계속하려면 Enter를 누르세요..."
	done
}




# 작업 목록 표시
list_tasks() {
	echo "저장된 동기화 작업:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 새 작업 추가
add_task() {
	send_stats "새 동기화 작업 추가"
	echo "새 동기화 작업 생성의 예:"
	echo "- 작업 이름: backup_www"
	echo "- 로컬 디렉터리: /var/www"
	echo "- 원격 주소: user@192.168.1.100"
	echo "- 원격 디렉터리: /backup/www"
	echo "- 포트 번호(기본값 22)"
	echo "---------------------------------"
	read -e -p "작업 이름을 입력하세요:" name
	read -e -p "로컬 디렉토리를 입력하십시오:" local_path
	read -e -p "원격 디렉토리를 입력하십시오:" remote_path
	read -e -p "원격 user@IP를 입력하십시오:" remote
	read -e -p "SSH 포트(기본값 22)를 입력하세요." port
	port=${port:-22}

	echo "인증 방법을 선택하세요:"
	echo "1. 비밀번호"
	echo "2. 열쇠"
	read -e -p "(1/2)을 선택하세요:" auth_choice

	case $auth_choice in
		1)
			read -s -p "비밀번호를 입력하세요:" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "주요 내용을 붙여넣으세요(붙인 후 Enter를 두 번 누르세요)."
			local password_or_key=""
			while IFS= read -r line; do
				# 입력이 빈 줄이고 키 내용에 이미 시작 부분이 포함되어 있으면 입력을 종료합니다.
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# 첫 번째 줄이거나 이미 핵심 내용 입력을 시작했다면 계속해서 추가하세요.
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# 핵심 내용인지 확인하세요
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "잘못된 키 콘텐츠입니다!"
				return
			fi
			;;
		*)
			echo "잘못된 선택입니다!"
			return
			;;
	esac

	echo "동기화 모드를 선택하십시오:"
	echo "1. 표준 모드(-avz)"
	echo "2. 대상 파일 삭제(-avz --delete)"
	read -e -p "(1/2)을 선택하세요:" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "선택이 잘못되었습니다. 기본값 -avz를 사용하세요."; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "임무가 저장되었습니다!"
}

# 할 일 삭제
delete_task() {
	send_stats "동기화 작업 삭제"
	read -e -p "삭제할 작업 번호를 입력하세요:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "오류: 해당 작업을 찾을 수 없습니다."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 작업이 키 파일을 사용하는 경우 키 파일을 삭제하세요.
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "작업이 삭제되었습니다!"
}


run_task() {
	send_stats "동기화 작업 수행"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# 매개변수 구문 분석
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 작업 번호가 전달되지 않으면 사용자에게 입력하라는 메시지가 표시됩니다.
	if [[ -z "$num" ]]; then
		read -e -p "실행할 작업 번호를 입력하세요:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "오류: 작업을 찾을 수 없습니다!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 동기화 방향에 따라 소스 및 대상 경로 조정
	if [[ "$direction" == "pull" ]]; then
		echo "로컬로 가져오기 및 동기화:$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "원격 끝에 푸시 및 동기화:$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# SSH 연결 공통 매개변수 추가
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "오류: sshpass가 설치되지 않았습니다. 먼저 sshpass를 설치하십시오."
			echo "설치 방법:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# 키 파일이 존재하는지, 권한이 올바른지 확인하세요.
		if [[ ! -f "$password_or_key" ]]; then
			echo "오류: 키 파일이 존재하지 않습니다:$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "경고: 잘못된 키 파일 권한, 수정 중..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "동기화가 완료되었습니다!"
	else
		echo "동기화에 실패했습니다! 다음 사항을 확인하세요."
		echo "1. 네트워크 연결이 정상인가요?"
		echo "2. 원격 호스트에 접근할 수 있나요?"
		echo "3. 인증정보가 정확합니까?"
		echo "4. 로컬 및 원격 디렉터리에 올바른 액세스 권한이 있습니까?"
	fi
}


# 예약된 작업 만들기
schedule_task() {
	send_stats "동기화 예약 작업 추가"

	read -e -p "정기적으로 동기화할 작업 번호를 입력하세요:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "오류: 유효한 작업 번호를 입력하십시오!"
		return
	fi

	echo "예약된 실행 간격을 선택하십시오."
	echo "1) 매 시간마다 한 번씩 실행"
	echo "2) 하루에 한 번 실행"
	echo "3) 일주일에 한 번 실행"
	read -e -p "옵션을 입력하세요(1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "오류: 유효한 옵션을 입력하십시오!" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 동일한 작업이 이미 존재하는지 확인하세요.
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "오류: 이 작업에 대해 예약된 동기화가 이미 존재합니다!"
		return
	fi

	# 사용자의 crontab에 생성
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "예약된 작업이 생성되었습니다:$cron_job"
}

# 예약된 작업 보기
view_tasks() {
	echo "현재 예약된 작업:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# 예약된 작업 삭제
delete_task_schedule() {
	send_stats "동기화 예약 작업 삭제"
	read -e -p "삭제할 작업 번호를 입력하세요:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "오류: 유효한 작업 번호를 입력하십시오!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "태스크 번호가 삭제되었습니다.$num예약된 작업"
}


# 작업 관리 메인 메뉴
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync 원격 동기화 도구"
		echo "원격 디렉터리 간의 동기화는 효율적이고 안정적인 증분 동기화를 지원합니다."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 새 작업 생성 2. 작업 삭제"
		echo "3. 원격 사이트에 대한 로컬 동기화 수행 4. 로컬 사이트에 대한 원격 동기화 수행"
		echo "5. 예약된 작업 생성 6. 예약된 작업 삭제"
		echo "---------------------------------"
		echo "0. 이전 메뉴로 돌아가기"
		echo "---------------------------------"
		read -e -p "선택사항을 입력하세요:" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "선택이 잘못되었습니다. 다시 시도해 주세요." ;;
		esac
		read -e -p "계속하려면 Enter를 누르세요..."
	done
}









linux_info() {

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
	echo -e "${gl_kjlan}호스트 이름:${gl_bai}$hostname"
	echo -e "${gl_kjlan}시스템 버전:${gl_bai}$os_info"
	echo -e "${gl_kjlan}리눅스 버전:${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU 아키텍처:${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPU 모델:${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPU 코어 수:${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU 주파수:${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU 사용량:${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}시스템 부하:${gl_bai}$load"
	echo -e "${gl_kjlan}물리적 메모리:${gl_bai}$mem_info"
	echo -e "${gl_kjlan}가상 메모리:${gl_bai}$swap_info"
	echo -e "${gl_kjlan}하드 드라이브 사용량:${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}받은 총액:${gl_bai}$rx"
	echo -e "${gl_kjlan}보낸 총액:${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}네트워크 알고리즘:${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}연산자:${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4 주소:${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6 주소:${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS 주소:${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}위치:${gl_bai}$country $city"
	echo -e "${gl_kjlan}시스템 시간:${gl_bai}$timezone $current_time"
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
	  echo -e "${gl_kjlan}1.   ${gl_bai}컬 다운로드 도구${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wget 다운로드 도구${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo 최고 관리 권한 도구${gl_kjlan}4.   ${gl_bai}socat 통신 연결 도구"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop 시스템 모니터링 도구${gl_kjlan}6.   ${gl_bai}iftop 네트워크 트래픽 모니터링 도구"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP 압축 및 압축 풀기 도구${gl_kjlan}8.   ${gl_bai}tar GZ 압축 및 압축 해제 도구"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux 다중 채널 백그라운드 실행 도구${gl_kjlan}10.  ${gl_bai}ffmpeg 비디오 인코딩 라이브 스트리밍 도구"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop 최신 모니터링 도구${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}레인저 파일 관리 도구"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu 디스크 사용량 보기 도구${gl_kjlan}14.  ${gl_bai}fzf 글로벌 검색 도구"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim 텍스트 편집기${gl_kjlan}16.  ${gl_bai}나노 텍스트 편집기${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}Git 버전 관리 시스템"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}매트릭스 스크린세이버${gl_kjlan}22.  ${gl_bai}달리는 기차 화면 보호기"
	  echo -e "${gl_kjlan}26.  ${gl_bai}테트리스 미니 게임${gl_kjlan}27.  ${gl_bai}뱀 미니게임"
	  echo -e "${gl_kjlan}28.  ${gl_bai}우주 침략자 미니 게임"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}모두 설치${gl_kjlan}32.  ${gl_bai}모두 설치(화면 보호기 및 게임 제외)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}모두 제거"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}지정된 도구 설치${gl_kjlan}42.  ${gl_bai}지정된 도구 제거"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}메인 메뉴로 돌아가기"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "선택사항을 입력하세요:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  curl --help
			  send_stats "컬 설치"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  wget --help
			  send_stats "wget 설치"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  sudo --help
			  send_stats "sudo 설치"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  socat -h
			  send_stats "socat 설치"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "htop 설치"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "iftop 설치"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  unzip
			  send_stats "설치압축 해제"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  tar --help
			  send_stats "타르 설치"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  tmux --help
			  send_stats "tmux 설치"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "도구가 설치되었으며 다음과 같이 사용됩니다."
			  ffmpeg --help
			  send_stats "ffmpeg 설치"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "btop 설치"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "레인저 설치"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "ncdu 설치"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "fzf 설치"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "vim 설치"
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
			  send_stats "자식 설치"
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
			  send_stats "sl 설치"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "바스테트 설치"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "nsnake 설치"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "닌베이더 설치"
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
		echo -e "${BLUE}当前备份列表:${NC}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "无备份"
	}



	# ----------------------------
	# 备份
	# ----------------------------
	backup_docker() {
		send_stats "Docker备份"

		echo -e "${YELLOW}正在备份 Docker 容器...${NC}"
		docker ps --format '{{.Names}}'
		read -e -p  "请输入要备份的容器名（多个空格分隔，回车备份全部运行中容器）: " containers

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
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && { echo -e "${RED}没有找到容器${NC}"; return; }

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" > "$RESTORE_SCRIPT"
		echo "set -e" >> "$RESTORE_SCRIPT"
		echo "# 自动生成的还原脚本" >> "$RESTORE_SCRIPT"

		# 记录已打包过的 Compose 项目路径，避免重复打包
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${GREEN}备份容器: $c${NC}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" > "$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${BLUE}检测到 $c 是 docker-compose 容器${NC}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p  "未检测到 compose 目录，请手动输入路径: " project_dir
				fi

				# 如果该 Compose 项目已经打包过，跳过
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${YELLOW}Compose 项目 [$project_name] 已备份过，跳过重复打包...${NC}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" > "${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" > "${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# docker-compose 恢复: $project_name" >> "$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >> "$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${GREEN}Compose 项目 [$project_name] 已打包: ${project_dir}${NC}"
				else
					echo -e "${RED}未找到 docker-compose.yml，跳过此容器...${NC}"
				fi
			else
				# 普通容器备份卷
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "打包卷: $path"
					tar -czpf "${BACKUP_DIR}/${c}_$(basename $path).tar.gz" -C / "$(echo $path | sed 's/^\///')"
				done

				# 端口
				local PORT_ARGS=""
				mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[] | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$inspect_file" 2>/dev/null)
				for p in "${PORTS[@]}"; do PORT_ARGS+="-p $p "; done

				# 环境变量
				local ENV_VARS=""
				mapfile -t ENVS < <(jq -r '.[0].Config.Env[] | @sh' "$inspect_file")
				for e in "${ENVS[@]}"; do ENV_VARS+="-e $e "; done

				# 卷映射
				local VOL_ARGS=""
				for path in $VOL_PATHS; do VOL_ARGS+="-v $path:$path "; done

				# 镜像
				local IMAGE
				IMAGE=$(jq -r '.[0].Config.Image' "$inspect_file")

				echo -e "\n# 还原容器: $c" >> "$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >> "$RESTORE_SCRIPT"
			fi
		done


		# 备份 /home/docker 下的所有文件（不含子目录）
		if [ -d "/home/docker" ]; then
			echo -e "${BLUE}备份 /home/docker 下的文件...${NC}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${GREEN}/home/docker 下的文件已打包到: ${BACKUP_DIR}/home_docker_files.tar.gz${NC}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${GREEN}备份完成: ${BACKUP_DIR}${NC}"
		echo -e "${GREEN}可用还原脚本: ${RESTORE_SCRIPT}${NC}"


	}

	# ----------------------------
	# 还原
	# ----------------------------
	restore_docker() {

		send_stats "Docker还原"
		read -e -p  "请输入要还原的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}备份目录不存在${NC}"; return; }

		echo -e "${BLUE}开始执行还原操作...${NC}"

		install tar jq gzip
		install_docker

		# --------- 优先还原 Compose 项目 ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p  "未找到原始路径，请输入还原目录路径: " original_path

				# 检查该 compose 项目的容器是否已经在运行
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${YELLOW}Compose 项目 [$project_name] 已有容器在运行，跳过还原...${NC}"
					continue
				fi

				read -e -p  "确认还原 Compose 项目 [$project_name] 到路径 [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p  "请输入新的还原路径: " original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${GREEN}Compose 项目 [$project_name] 已解压到: $original_path${NC}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${GREEN}Compose 项目 [$project_name] 还原完成！${NC}"
			fi
		done

		# --------- 继续还原普通容器 ---------
		echo -e "${BLUE}检查并还原普通 Docker 容器...${NC}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${GREEN}处理容器: $container${NC}"

			# 检查容器是否已经存在且正在运行
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}容器 [$container] 已在运行，跳过还原...${NC}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && { echo -e "${RED}未找到镜像信息，跳过: $container${NC}"; continue; }

			# 端口映射
			PORT_ARGS=""
			mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[]? | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$json")
			for p in "${PORTS[@]}"; do
				[[ -n "$p" ]] && PORT_ARGS="$PORT_ARGS -p $p"
			done

			# 环境变量
			ENV_ARGS=""
			mapfile -t ENVS < <(jq -r '.[0].Config.Env[]' "$json")
			for e in "${ENVS[@]}"; do
				ENV_ARGS="$ENV_ARGS -e \"$e\""
			done

			# 卷映射 + 卷数据恢复
			VOL_ARGS=""
			mapfile -t VOLS < <(jq -r '.[0].Mounts[] | "\(.Source):\(.Destination)"' "$json")
			for v in "${VOLS[@]}"; do
				VOL_SRC=$(echo "$v" | cut -d':' -f1)
				VOL_DST=$(echo "$v" | cut -d':' -f2)
				mkdir -p "$VOL_SRC"
				VOL_ARGS="$VOL_ARGS -v $VOL_SRC:$VOL_DST"

				VOL_FILE="$BACKUP_DIR/${container}_$(basename $VOL_SRC).tar.gz"
				if [[ -f "$VOL_FILE" ]]; then
					echo "恢复卷数据: $VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 删除已存在但未运行的容器
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${YELLOW}容器 [$container] 存在但未运行，删除旧容器...${NC}"
				docker rm -f "$container"
			fi

			# 启动容器
			echo "执行还原命令: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${YELLOW}未找到普通容器的备份信息${NC}"

		# 还原 /home/docker 下的文件
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${BLUE}正在还原 /home/docker 下的文件...${NC}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${GREEN}/home/docker 下的文件已还原完成${NC}"
		else
			echo -e "${YELLOW}未找到 /home/docker 下文件的备份，跳过...${NC}"
		fi


	}


	# ----------------------------
	# 迁移
	# ----------------------------
	migrate_docker() {
		send_stats "Docker迁移"
		install jq
		read -e -p  "请输入要迁移的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}备份目录不存在${NC}"; return; }

		read -e -p  "目标服务器IP: " TARGET_IP
		read -e -p  "目标服务器SSH用户名: " TARGET_USER
		read -e -p "目标服务器SSH端口 [默认22]: " TARGET_PORT
		local TARGET_PORT=${TARGET_PORT:-22}

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${YELLOW}传输备份中...${NC}"
		if [[ -z "$TARGET_PASS" ]]; then
			# 使用密钥登录
			scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no -r "$LATEST_TAR" "$TARGET_USER@$TARGET_IP:/tmp/"
		fi

	}

	# ----------------------------
	# 删除备份
	# ----------------------------
	delete_backup() {
		send_stats "Docker备份文件删除"
		read -e -p  "请输入要删除的备份目录: " BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${RED}备份目录不存在${NC}"; return; }
		rm -rf "$BACKUP_DIR"
		echo -e "${GREEN}已删除备份: ${BACKUP_DIR}${NC}"
	}

	# ----------------------------
	# 主菜单
	# ----------------------------
	main_menu() {
		send_stats "Docker备份迁移还原"
		while true; do
			clear
			echo "------------------------"
			echo -e "Docker备份/迁移/还原工具"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. 备份docker项目"
			echo -e "2. 迁移docker项目"
			echo -e "3. 还原docker项目"
			echo -e "4. 删除docker项目的备份文件"
			echo "------------------------"
			echo -e "0. 返回上一级菜单"
			echo "------------------------"
			read -e -p  "请选择: " choice
			case $choice in
				1) backup_docker ;;
				2) migrate_docker ;;
				3) restore_docker ;;
				4) delete_backup ;;
				0) return ;;
				*) echo -e "${RED}无效选项${NC}" ;;
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
	  echo -e "${gl_kjlan}1.   ${gl_bai}安装更新Docker环境 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}查看Docker全局状态 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Docker容器管理 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker镜像管理"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker网络管理"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker卷管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}清理无用的docker容器和镜像网络数据卷"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}更换Docker源"
	  echo -e "${gl_kjlan}9.   ${gl_bai}编辑daemon.json文件"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}开启Docker-ipv6访问"
	  echo -e "${gl_kjlan}12.  ${gl_bai}关闭Docker-ipv6访问"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}19.  ${gl_bai}备份/迁移/还原Docker环境"
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
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
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
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
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

		  19)
			  docker_ssh_migration
			  ;;


		  20)
			  clear
			  send_stats "Docker卸载"
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
	  echo -e "测试脚本合集"
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
	  echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality 网络质量体检脚本 ${gl_huang}★${gl_bai}"

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
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
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
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
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
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc多功能测速脚本"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "网络质量测试脚本"
			  bash <(curl -sL Net.Check.Place)
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
	  echo -e "甲骨文云脚本合集"
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
		  echo -e "${gl_hong}注意: ${gl_bai}重装有风险失联，不放心者慎用。重装预计花费15分钟，请提前备份数据。"
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
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
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
			  send_stats "R探长开机脚本"
			  bash <(wget -qO- ${gh_proxy}github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh)
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
local output="${gl_lv}${cert_count}${gl_bai}"

local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml 2>/dev/null | tr -d '[:space:]')
if [ -n "$dbrootpasswd" ]; then
	local db_count=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SHOW DATABASES;" 2>/dev/null | grep -Ev "Database|information_schema|mysql|performance_schema|sys" | wc -l)
fi

local db_output="${gl_lv}${db_count}${gl_bai}"


if command -v docker &>/dev/null; then
	if docker ps --filter "name=nginx" --filter "status=running" | grep -q nginx; then
		echo -e "${gl_huang}------------------------"
		echo -e "${gl_lv}环境已安装${gl_bai}  站点: $output  数据库: $db_output"
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
	echo -e "${gl_huang}1.   ${gl_bai}安装LDNMP环境 ${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}安装WordPress ${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}安装Discuz论坛                    ${gl_huang}4.   ${gl_bai}安装可道云桌面"
	echo -e "${gl_huang}5.   ${gl_bai}安装苹果CMS影视站                 ${gl_huang}6.   ${gl_bai}安装独角数发卡网"
	echo -e "${gl_huang}7.   ${gl_bai}安装flarum论坛网站                ${gl_huang}8.   ${gl_bai}安装typecho轻量博客网站"
	echo -e "${gl_huang}9.   ${gl_bai}安装LinkStack共享链接平台         ${gl_huang}20.  ${gl_bai}自定义动态站点"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}仅安装nginx ${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}站点重定向"
	echo -e "${gl_huang}23.  ${gl_bai}站点反向代理-IP+端口 ${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}站点反向代理-域名"
	echo -e "${gl_huang}25.  ${gl_bai}安装Bitwarden密码管理平台         ${gl_huang}26.  ${gl_bai}安装Halo博客网站"
	echo -e "${gl_huang}27.  ${gl_bai}安装AI绘画提示词生成器            ${gl_huang}28.  ${gl_bai}站点反向代理-负载均衡"
	echo -e "${gl_huang}30.  ${gl_bai}自定义静态站点"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}站点数据管理 ${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}备份全站数据"
	echo -e "${gl_huang}33.  ${gl_bai}定时远程备份                      ${gl_huang}34.  ${gl_bai}还原全站数据"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}防护LDNMP环境                     ${gl_huang}36.  ${gl_bai}优化LDNMP环境"
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
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require flarum/extension-manager:*"
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
	  wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
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

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

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

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/rewrite.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  sed -i "s/baidu.com/$reverseproxy/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  docker exec nginx nginx -s reload

	  nginx_web_on


		;;

	  23)
	  ldnmp_Proxy
	  find_container_by_host_port "$port"
	  if [ -z "$docker_name" ]; then
		close_port "$port"
		echo "已阻止IP+端口访问该服务"
	  else
	  	ip_address
		block_container_port "$docker_name" "$ipv4_address"
	  fi

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
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
	  add_yuming
	  nginx_install_status
	  install_ssltls
	  certs_status

	  docker run -d \
		--name bitwarden \
		--restart=always \
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

	  docker run -d --name halo --restart=always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2
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
	  send_stats "安装$webname"
	  echo "开始部署 $webname"
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
	  docker exec nginx nginx -s reload

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
			read -e -p "目标服务器SSH端口 [默认22]: " TARGET_PORT
			local TARGET_PORT=${TARGET_PORT:-22}
			if [ -z "$remote_ip" ]; then
			  echo "错误: 请输入远端服务器IP。"
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
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
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
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
		web_security
		;;

	36)
		web_optimization
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
		  echo "0. 返回上一级选单"
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
			  restart_redis
			  send_stats "更新$ldnmp_pods"
			  echo "更新${ldnmp_pods}完成"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "完整更新LDNMP环境"
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
		send_stats "卸载LDNMP环境"
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


local sub_choice="$1"


while true; do

	if [ -z "$sub_choice" ]; then
	  clear
	  echo -e "应用市场"
	  echo -e "${gl_kjlan}------------------------"

	  local app_numbers=$([ -f /home/docker/appno.txt ] && cat /home/docker/appno.txt || echo "")

	  # 用循环设置颜色
	  for i in {1..100}; do
		  if echo "$app_numbers" | grep -q "^$i$"; then
			  declare "color$i=${gl_lv}"
		  else
			  declare "color$i=${gl_bai}"
		  fi
	  done

	  echo -e "${gl_kjlan}1.   ${color1}宝塔面板官方版                      ${gl_kjlan}2.   ${color2}aaPanel宝塔国际版"
	  echo -e "${gl_kjlan}3.   ${color3}1Panel新一代管理面板                ${gl_kjlan}4.   ${color4}NginxProxyManager可视化面板"
	  echo -e "${gl_kjlan}5.   ${color5}OpenList多存储文件列表程序          ${gl_kjlan}6.   ${color6}Ubuntu远程桌面网页版"
	  echo -e "${gl_kjlan}7.   ${color7}哪吒探针VPS监控面板                 ${gl_kjlan}8.   ${color8}QB离线BT磁力下载面板"
	  echo -e "${gl_kjlan}9.   ${color9}Poste.io邮件服务器程序              ${gl_kjlan}10.  ${color10}RocketChat多人在线聊天系统"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${color11}禅道项目管理软件                    ${gl_kjlan}12.  ${color12}青龙面板定时任务管理平台"
	  echo -e "${gl_kjlan}13.  ${color13}Cloudreve网盘 ${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${color14}简单图床图片管理程序"
	  echo -e "${gl_kjlan}15.  ${color15}emby多媒体管理系统                  ${gl_kjlan}16.  ${color16}Speedtest测速面板"
	  echo -e "${gl_kjlan}17.  ${color17}AdGuardHome去广告软件               ${gl_kjlan}18.  ${color18}onlyoffice在线办公OFFICE"
	  echo -e "${gl_kjlan}19.  ${color19}雷池WAF防火墙面板                   ${gl_kjlan}20.  ${color20}portainer容器管理面板"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${color21}VScode网页版                        ${gl_kjlan}22.  ${color22}UptimeKuma监控工具"
	  echo -e "${gl_kjlan}23.  ${color23}Memos网页备忘录                     ${gl_kjlan}24.  ${color24}Webtop远程桌面网页版 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${color25}Nextcloud网盘                       ${gl_kjlan}26.  ${color26}QD-Today定时任务管理框架"
	  echo -e "${gl_kjlan}27.  ${color27}Dockge容器堆栈管理面板              ${gl_kjlan}28.  ${color28}LibreSpeed测速工具"
	  echo -e "${gl_kjlan}29.  ${color29}searxng聚合搜索站 ${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${color30}PhotoPrism私有相册系统"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${color31}StirlingPDF工具大全                 ${gl_kjlan}32.  ${color32}drawio免费的在线图表软件 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${color33}Sun-Panel导航面板                   ${gl_kjlan}34.  ${color34}Pingvin-Share文件分享平台"
	  echo -e "${gl_kjlan}35.  ${color35}极简朋友圈                          ${gl_kjlan}36.  ${color36}LobeChatAI聊天聚合网站"
	  echo -e "${gl_kjlan}37.  ${color37}MyIP工具箱 ${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${color38}小雅alist全家桶"
	  echo -e "${gl_kjlan}39.  ${color39}Bililive直播录制工具                ${gl_kjlan}40.  ${color40}webssh网页版SSH连接工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${color41}耗子管理面板                	 ${gl_kjlan}42.  ${color42}Nexterm远程连接工具"
	  echo -e "${gl_kjlan}43.  ${color43}RustDesk远程桌面(服务端) ${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${color44}RustDesk远程桌面(中继端) ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${color45}Docker加速站            		 ${gl_kjlan}46.  ${color46}GitHub加速站 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${color47}普罗米修斯监控			 ${gl_kjlan}48.  ${color48}普罗米修斯(主机监控)"
	  echo -e "${gl_kjlan}49.  ${color49}普罗米修斯(容器监控)		 ${gl_kjlan}50.  ${color50}补货监控工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${color51}PVE开小鸡面板			 ${gl_kjlan}52.  ${color52}DPanel容器管理面板"
	  echo -e "${gl_kjlan}53.  ${color53}llama3聊天AI大模型                  ${gl_kjlan}54.  ${color54}AMH主机建站管理面板"
	  echo -e "${gl_kjlan}55.  ${color55}FRP内网穿透(服务端) ${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${color56}FRP内网穿透(客户端) ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${color57}Deepseek聊天AI大模型                ${gl_kjlan}58.  ${color58}Dify大模型知识库 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${color59}NewAPI大模型资产管理                ${gl_kjlan}60.  ${color60}JumpServer开源堡垒机"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${color61}在线翻译服务器			 ${gl_kjlan}62.  ${color62}RAGFlow大模型知识库"
	  echo -e "${gl_kjlan}63.  ${color63}OpenWebUI自托管AI平台 ${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${color64}it-tools工具箱"
	  echo -e "${gl_kjlan}65.  ${color65}n8n自动化工作流平台 ${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${color66}yt-dlp视频下载工具"
	  echo -e "${gl_kjlan}67.  ${color67}ddns-go动态DNS管理工具 ${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${color68}AllinSSL证书管理平台"
	  echo -e "${gl_kjlan}69.  ${color69}SFTPGo文件传输工具                  ${gl_kjlan}70.  ${color70}AstrBot聊天机器人框架"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}71.  ${color71}Navidrome私有音乐服务器             ${gl_kjlan}72.  ${color72}bitwarden密码管理器 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${color73}LibreTV私有影视                     ${gl_kjlan}74.  ${color74}MoonTV私有影视"
	  echo -e "${gl_kjlan}75.  ${color75}Melody音乐精灵                      ${gl_kjlan}76.  ${color76}在线DOS老游戏"
	  echo -e "${gl_kjlan}77.  ${color77}迅雷离线下载工具                    ${gl_kjlan}78.  ${color78}PandaWiki智能文档管理系统"
	  echo -e "${gl_kjlan}79.  ${color79}Beszel服务器监控                    ${gl_kjlan}80.  ${color80}linkwarden书签管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}81.  ${color81}JitsiMeet视频会议                   ${gl_kjlan}82.  ${color82}gpt-load高性能AI透明代理"
	  echo -e "${gl_kjlan}83.  ${color83}komari服务器监控工具                ${gl_kjlan}84.  ${color84}Wallos个人财务管理工具"
	  echo -e "${gl_kjlan}85.  ${color85}immich图片视频管理器                ${gl_kjlan}86.  ${color86}jellyfin媒体管理系统"
	  echo -e "${gl_kjlan}87.  ${color87}SyncTV一起看片神器                  ${gl_kjlan}88.  ${color88}Owncast自托管直播平台"
	  echo -e "${gl_kjlan}89.  ${color89}FileCodeBox文件快递                 ${gl_kjlan}90.  ${color90}matrix去中心化聊天协议"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}91.  ${color91}gitea私有代码仓库                   ${gl_kjlan}92.  ${color92}FileBrowser文件管理器"
	  echo -e "${gl_kjlan}93.  ${color93}Dufs极简静态文件服务器              ${gl_kjlan}94.  ${color94}Gopeed高速下载工具"
	  echo -e "${gl_kjlan}95.  ${color95}paperless文档管理平台               ${gl_kjlan}96.  ${color96}2FAuth自托管二步验证器"
	  echo -e "${gl_kjlan}97.  ${color97}WireGuard组网(服务端)               ${gl_kjlan}98.  ${color98}WireGuard组网(客户端)"
	  echo -e "${gl_kjlan}99.  ${color99}DSM群晖虚拟机                       ${gl_kjlan}100. ${color100}Syncthing点对点文件同步工具"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}b.   ${gl_bai}备份全部应用数据                    ${gl_kjlan}r.   ${gl_bai}还原全部应用数据"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}返回主菜单"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "请输入你的选择: " sub_choice
	fi

	case $sub_choice in
	  1|bt|baota)
		local app_id="1"
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

		local docker_describe="一个Nginx反向代理工具面板，不支持添加域名访问。"
		local docker_url="官网介绍: https://nginxproxymanager.com/"
		local docker_use="echo \"初始用户名: admin@example.com\""
		local docker_passwd="echo \"初始密码: changeme\""
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


		local docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
		local docker_url="官网介绍: https://github.com/OpenListTeam/OpenList"
		local docker_use="docker exec -it openlist ./openlist admin random"
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

			read -e -p "设置登录用户名: " admin
			read -e -p "设置登录用户密码: " admin_password
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


		local docker_describe="webtop基于Ubuntu的容器。若IP无法访问，请添加域名访问。"
		local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
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
			echo -e "哪吒监控 $check_docker $update_status"
			echo "开源、轻量、易用的服务器监控与运维工具"
			echo "官网搭建文档: https://nezha.wiki/guide/dashboard.html"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
				check_docker_app_ip
			fi
			echo ""
			echo "------------------------"
			echo "1. 使用"
			echo "------------------------"
			echo "0. 返回上一级选单"
			echo "------------------------"
			read -e -p "输入你的选择: " choice

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

		local docker_describe="qbittorrent离线BT磁力下载服务"
		local docker_url="官网介绍: https://hub.docker.com/r/linuxserver/qbittorrent"
		local docker_use="sleep 3"
		local docker_passwd="docker logs qbittorrent"
		local app_size="1"
		docker_app

		  ;;

	  9|mail)
		send_stats "搭建邮局"
		clear
		install telnet
		local app_id="9"
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

			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				yuming=$(cat /home/docker/mail.txt)
				echo "访问地址: "
				echo "https://$yuming"
			fi

			echo "------------------------"
			echo "1. 安装           2. 更新           3. 卸载"
			echo "------------------------"
			echo "0. 返回上一级选单"
			echo "------------------------"
			read -e -p "输入你的选择: " choice

			case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
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


					add_app_id

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


					add_app_id

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

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "应用已卸载"
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
			echo "已经安装完成"
			check_docker_app_ip
		}

		docker_app_update() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat:latest
			docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
			clear
			ip_address
			echo "rocket.chat已经安装完成"
			check_docker_app_ip
		}

		docker_app_uninstall() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat
			docker rm -f db
			docker rmi -f mongo:latest
			rm -rf /home/docker/mongo
			echo "应用已卸载"
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

		local docker_describe="禅道是通用的项目管理软件"
		local docker_url="官网介绍: https://www.zentao.net/"
		local docker_use="echo \"初始用户名: admin\""
		local docker_passwd="echo \"初始密码: 123456\""
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

		local docker_describe="青龙面板是一个定时任务管理平台"
		local docker_url="官网介绍: ${gh_proxy}github.com/whyour/qinglong"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  13|cloudreve)

		local app_id="13"
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
			echo "已经安装完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			cd /home/docker/cloud/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			rm -rf /home/docker/cloud
			echo "应用已卸载"
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

		local docker_describe="简单图床是一个简单的图床程序"
		local docker_url="官网介绍: ${gh_proxy}github.com/icret/EasyImages2.0"
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


		local docker_describe="emby是一个主从式架构的媒体服务器软件，可以用来整理服务器上的视频和音频，并将音频和视频流式传输到客户端设备"
		local docker_url="官网介绍: https://emby.media/"
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

		local docker_describe="Speedtest测速面板是一个VPS网速测试工具，多项测试功能，还可以实时监控VPS进出站流量"
		local docker_url="官网介绍: ${gh_proxy}github.com/wikihost-opensource/als"
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


		local docker_describe="AdGuardHome是一款全网广告拦截与反跟踪软件，未来将不止是一个DNS服务器。"
		local docker_url="官网介绍: https://hub.docker.com/r/adguard/adguardhome"
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

		local docker_describe="onlyoffice是一款开源的在线office工具，太强大了！"
		local docker_url="官网介绍: https://www.onlyoffice.com/"
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
			echo -e "雷池服务 $check_docker"
			echo "雷池是长亭科技开发的WAF站点防火墙程序面板，可以反代站点进行自动化防御"
			echo "视频介绍: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				check_docker_app_ip
			fi
			echo ""

			echo "------------------------"
			echo "1. 安装           2. 更新           3. 重置密码           4. 卸载"
			echo "------------------------"
			echo "0. 返回上一级选单"
			echo "------------------------"
			read -e -p "输入你的选择: " choice

			case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "雷池WAF面板已经安装完成"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "雷池WAF面板已经更新完成"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
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


		local docker_describe="portainer是一个轻量级的docker容器管理面板"
		local docker_url="官网介绍: https://www.portainer.io/"
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


		local docker_describe="VScode是一款强大的在线代码编写工具"
		local docker_url="官网介绍: ${gh_proxy}github.com/coder/code-server"
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


		local docker_describe="Uptime Kuma 易于使用的自托管监控工具"
		local docker_url="官网介绍: ${gh_proxy}github.com/louislam/uptime-kuma"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  23|memos)
		local app_id="23"
		local docker_name="memos"
		local docker_img="ghcr.io/usememos/memos:latest"
		local docker_port=8023

		docker_rum() {

			docker run -d --name memos -p ${docker_port}:5230 -v /home/docker/memos:/var/opt/memos --restart=always ghcr.io/usememos/memos:latest

		}

		local docker_describe="Memos是一款轻量级、自托管的备忘录中心"
		local docker_url="官网介绍: ${gh_proxy}github.com/usememos/memos"
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

			read -e -p "设置登录用户名: " admin
			read -e -p "设置登录用户密码: " admin_password
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


		local docker_describe="webtop基于Alpine的中文版容器。若IP无法访问，请添加域名访问。"
		local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
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

		local docker_describe="Nextcloud拥有超过 400,000 个部署，是您可以下载的最受欢迎的本地内容协作平台"
		local docker_url="官网介绍: https://nextcloud.com/"
		local docker_use="echo \"账号: nextcloud  密码: $rootpasswd\""
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

		local docker_describe="QD-Today是一个HTTP请求定时任务自动执行框架"
		local docker_url="官网介绍: https://qd-today.github.io/qd/zh_CN/"
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

		local docker_describe="dockge是一个可视化的docker-compose容器管理面板"
		local docker_url="官网介绍: ${gh_proxy}github.com/louislam/dockge"
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

		local docker_describe="librespeed是用Javascript实现的轻量级速度测试工具，即开即用"
		local docker_url="官网介绍: ${gh_proxy}github.com/librespeed/speedtest"
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

		local docker_describe="searxng是一个私有且隐私的搜索引擎站点"
		local docker_url="官网介绍: https://hub.docker.com/r/alandoyle/searxng"
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


		local docker_describe="photoprism非常强大的私有相册系统"
		local docker_url="官网介绍: https://www.photoprism.app/"
		local docker_use="echo \"账号: admin  密码: $rootpasswd\""
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

		local docker_describe="这是一个强大的本地托管基于 Web 的 PDF 操作工具，使用 docker，允许您对 PDF 文件执行各种操作，例如拆分合并、转换、重新组织、添加图像、旋转、压缩等。"
		local docker_url="官网介绍: ${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
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


		local docker_describe="这是一个强大图表绘制软件。思维导图，拓扑图，流程图，都能画"
		local docker_url="官网介绍: https://www.drawio.com/"
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

		local docker_describe="Sun-Panel服务器、NAS导航面板、Homepage、浏览器首页"
		local docker_url="官网介绍: https://doc.sun-panel.top/zh_cn/"
		local docker_use="echo \"账号: admin@sun.cc  密码: 12345678\""
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

		local docker_describe="Pingvin Share 是一个可自建的文件分享平台，是 WeTransfer 的一个替代品"
		local docker_url="官网介绍: ${gh_proxy}github.com/stonith404/pingvin-share"
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


		local docker_describe="极简朋友圈，高仿微信朋友圈，记录你的美好生活"
		local docker_url="官网介绍: ${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
		local docker_use="echo \"账号: admin  密码: a123456\""
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
		local docker_url="官网介绍: ${gh_proxy}github.com/lobehub/lobe-chat"
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


		local docker_describe="是一个多功能IP工具箱，可以查看自己IP信息及连通性，用网页面板呈现"
		local docker_url="官网介绍: ${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
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

		local docker_describe="Bililive-go是一个支持多种直播平台的直播录制工具"
		local docker_url="官网介绍: ${gh_proxy}github.com/hr3lxphr6j/bililive-go"
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

		local docker_describe="简易在线ssh连接工具和sftp工具"
		local docker_url="官网介绍: ${gh_proxy}github.com/Jrohy/webssh"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  41|haozi)

		local app_id="41"
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

		local docker_describe="nexterm是一款强大的在线SSH/VNC/RDP连接工具。"
		local docker_url="官网介绍: ${gh_proxy}github.com/gnmyt/Nexterm"
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


		local docker_describe="rustdesk开源的远程桌面(服务端)，类似自己的向日葵私服。"
		local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
		local docker_use="docker logs hbbs"
		local docker_passwd="echo \"把你的IP和key记录下，会在远程桌面客户端中用到。去44选项装中继端吧！\""
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

		local docker_describe="rustdesk开源的远程桌面(中继端)，类似自己的向日葵私服。"
		local docker_url="官网介绍: https://rustdesk.com/zh-cn/"
		local docker_use="echo \"前往官网下载远程桌面的客户端: https://rustdesk.com/zh-cn/\""
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

		local docker_describe="Docker Registry 是一个用于存储和分发 Docker 镜像的服务。"
		local docker_url="官网介绍: https://hub.docker.com/_/registry"
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

		local docker_describe="使用Go实现的GHProxy，用于加速部分地区Github仓库的拉取。"
		local docker_url="官网介绍: https://github.com/WJQSERVER-STUDIO/ghproxy"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  47|prometheus|grafana)

		local app_id="47"
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
			echo "已经安装完成"
			check_docker_app_ip
			echo "初始用户名密码均为: admin"
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
			echo "应用已卸载"
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

		local docker_describe="这是一个普罗米修斯的主机数据采集组件，请部署在被监控主机上。"
		local docker_url="官网介绍: https://github.com/prometheus/node_exporter"
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

		local docker_describe="这是一个普罗米修斯的容器数据采集组件，请部署在被监控主机上。"
		local docker_url="官网介绍: https://github.com/google/cadvisor"
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

		local docker_describe="这是一款网站变化检测、补货监控和通知的小工具"
		local docker_url="官网介绍: https://github.com/dgtlmoon/changedetection.io"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  51|pve)
		clear
		send_stats "PVE开小鸡"
		check_disk_space 1
		curl -L ${gh_proxy}raw.githubusercontent.com/oneclickvirt/pve/main/scripts/install_pve.sh -o install_pve.sh && chmod +x install_pve.sh && bash install_pve.sh
		  ;;


	  52|dpanel)
		local app_id="52"
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

	  53|llama3)
		local app_id="53"
		local docker_name="ollama"
		local docker_img="ghcr.io/open-webui/open-webui:ollama"
		local docker_port=8053

		docker_rum() {

			docker run -d -p ${docker_port}:8080 -v /home/docker/ollama:/root/.ollama -v /home/docker/ollama/open-webui:/app/backend/data --name ollama --restart=always ghcr.io/open-webui/open-webui:ollama

		}

		local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的llama3大语言模型"
		local docker_url="官网介绍: https://github.com/open-webui/open-webui"
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

		local docker_describe="OpenWebUI一款大语言模型网页框架，接入全新的DeepSeek R1大语言模型"
		local docker_url="官网介绍: https://github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;


	  58|dify)
		local app_id="58"
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
			echo "已经安装完成"
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
			echo "应用已卸载"
		}

		docker_app_plus

		  ;;

	  59|new-api)
		local app_id="59"
		local app_name="NewAPI"
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
			echo "已经安装完成"
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
			echo "已经安装完成"
			check_docker_app_ip

		}

		docker_app_uninstall() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			rm -rf /home/docker/new-api
			echo "应用已卸载"
		}

		docker_app_plus

		  ;;


	  60|jms)

		local app_id="60"
		local app_name="JumpServer开源堡垒机"
		local app_text="是一个开源的特权访问管理 (PAM) 工具，该程序占用80端口不支持添加域名访问了"
		local app_url="官方介绍: https://github.com/jumpserver/jumpserver"
		local docker_name="jms_web"
		local docker_port="80"
		local app_size="2"

		docker_app_install() {
			curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
			clear
			echo "已经安装完成"
			check_docker_app_ip
			echo "初始用户名: admin"
			echo "初始密码: ChangeMe"
		}


		docker_app_update() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh upgrade
			echo "应用已更新"
		}


		docker_app_uninstall() {
			cd /opt/jumpserver-installer*/
			./jmsctl.sh uninstall
			cd /opt
			rm -rf jumpserver-installer*/
			rm -rf jumpserver
			echo "应用已卸载"
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

		local docker_describe="免费开源机器翻译 API，完全自托管，它的翻译引擎由开源Argos Translate库提供支持。"
		local docker_url="官网介绍: https://github.com/LibreTranslate/LibreTranslate"
		local docker_use=""
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;



	  62|ragflow)
		local app_id="62"
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
			echo "已经安装完成"
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
			echo "应用已卸载"
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

		local docker_describe="OpenWebUI一款大语言模型网页框架，官方精简版本，支持各大模型API接入"
		local docker_url="官网介绍: https://github.com/open-webui/open-webui"
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

		local docker_describe="对开发人员和 IT 工作者来说非常有用的工具"
		local docker_url="官网介绍: https://github.com/CorentinTh/it-tools"
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

		local docker_describe="是一款功能强大的自动化工作流平台"
		local docker_url="官网介绍: https://github.com/n8n-io/n8n"
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

		local docker_describe="自动将你的公网 IP（IPv4/IPv6）实时更新到各大 DNS 服务商，实现动态域名解析。"
		local docker_url="官网介绍: https://github.com/jeessy2/ddns-go"
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
			docker run -itd --name allinssl -p ${docker_port}:8888 -v /home/docker/allinssl/data:/www/allinssl/data -e ALLINSSL_USER=allinssl -e ALLINSSL_PWD=allinssldocker -e ALLINSSL_URL=allinssl allinssl/allinssl:latest
		}

		local docker_describe="开源免费的 SSL 证书自动化管理平台"
		local docker_url="官网介绍: https://allinssl.com"
		local docker_use="echo \"安全入口: /allinssl\""
		local docker_passwd="echo \"用户名: allinssl  密码: allinssldocker\""
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

		local docker_describe="开源免费随时随地SFTP FTP WebDAV 文件传输工具"
		local docker_url="官网介绍: https://sftpgo.com/"
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

		local docker_describe="开源AI聊天机器人框架，支持微信，QQ，TG接入AI大模型"
		local docker_url="官网介绍: https://astrbot.app/"
		local docker_use="echo \"用户名: astrbot  密码: astrbot\""
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

		local docker_describe="是一个轻量、高性能的音乐流媒体服务器"
		local docker_url="官网介绍: https://www.navidrome.org/"
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

		local docker_describe="一个你可以控制数据的密码管理器"
		local docker_url="官网介绍: https://bitwarden.com/"
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

			read -e -p "设置LibreTV的登录密码: " app_passwd

			docker run -d \
			  --name libretv \
			  --restart=always \
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



	  74|moontv)

		local app_id="74"

		local app_name="moontv私有影视"
		local app_text="免费在线视频搜索与观看平台"
		local app_url="视频介绍: https://github.com/MoonTechLab/LunaTV"
		local docker_name="moontv-core"
		local docker_port="8074"
		local app_size="2"

		docker_app_install() {
			read -e -p "设置登录用户名: " admin
			read -e -p "设置登录用户密码: " admin_password
			read -e -p "输入授权码: " shouquanma


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
			echo "已经安装完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			cd /home/docker/moontv/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			rm -rf /home/docker/moontv
			echo "应用已卸载"
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

		local docker_describe="你的音乐精灵，旨在帮助你更好地管理音乐。"
		local docker_url="官网介绍: https://github.com/foamzou/melody"
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

		local docker_describe="是一个中文DOS游戏合集网站"
		local docker_url="官网介绍: https://github.com/rwv/chinese-dos-games"
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

			read -e -p "设置登录用户名: " app_use
			read -e -p "设置登录密码: " app_passwd

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

		local docker_describe="迅雷你的离线高速BT磁力下载工具"
		local docker_url="官网介绍: https://github.com/cnk3x/xunlei"
		local docker_use="echo \"手机登录迅雷，再输入邀请码，邀请码: 迅雷牛通\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  78|PandaWiki)

		local app_id="78"
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

		local docker_describe="Beszel轻量易用的服务器监控"
		local docker_url="官网介绍: https://beszel.dev/zh/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  80|linkwarden)

		  local app_id="80"
		  local app_name="linkwarden书签管理"
		  local app_text="一个开源的自托管书签管理平台，支持标签、搜索和团队协作。"
		  local app_url="官方网站: https://linkwarden.app/"
		  local docker_name="linkwarden-linkwarden-1"
		  local docker_port="8080"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl
			  mkdir -p /home/docker/linkwarden && cd /home/docker/linkwarden

			  # 下载官方 docker-compose 和 env 文件
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env"

			  # 生成随机密钥与密码
			  local ADMIN_EMAIL="admin@example.com"
			  local ADMIN_PASSWORD=$(openssl rand -hex 8)

			  sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=http://localhost:${docker_port}/api/v1/auth|g" .env
			  sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$(openssl rand -hex 32)|g" .env
			  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 16)|g" .env
			  sed -i "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$(openssl rand -hex 32)|g" .env

			  # 追加管理员账号信息
			  echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >> .env
			  echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> .env

			  sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

			  # 启动容器
			  docker compose up -d

			  clear
			  echo "已经安装完成"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
			  cd /home/docker/linkwarden && docker compose down --rmi all
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env.new"

			  # 保留原本的变量
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
			  echo "应用已卸载"
		  }

		  docker_app_plus

		  ;;



	  81|jitsi)
		  local app_id="81"
		  local app_name="JitsiMeet视频会议"
		  local app_text="一个开源的安全视频会议解决方案，支持多人在线会议、屏幕共享与加密通信。"
		  local app_url="官方网站: https://jitsi.org/"
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
			  echo "应用已卸载"
		  }

		  docker_app_plus

		  ;;



	  82|gpt-load)

		local app_id="82"
		local docker_name="gpt-load"
		local docker_img="tbphp/gpt-load:latest"
		local docker_port=8082

		docker_rum() {

			read -e -p "设置${docker_name}的登录密钥（sk-开头字母和数字组合）如: sk-159kejilionyyds163: " app_passwd

			mkdir -p /home/docker/gpt-load && \
			docker run -d --name gpt-load \
				-p ${docker_port}:3001 \
				-e AUTH_KEY=${app_passwd} \
				-v "/home/docker/gpt-load/data":/app/data \
				tbphp/gpt-load:latest

		}

		local docker_describe="高性能AI接口透明代理服务"
		local docker_url="官网介绍: https://www.gpt-load.com/"
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
			  --restart=always \
			  ghcr.io/komari-monitor/komari:latest

		}

		local docker_describe="轻量级的自托管服务器监控工具"
		local docker_url="官网介绍: https://github.com/komari-monitor/komari/tree/main"
		local docker_use="echo \"默认账号: admin  默认密码: 1212156\""
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

		local docker_describe="开源个人订阅追踪器，可用于财务管理"
		local docker_url="官网介绍: https://github.com/ellite/Wallos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  85|immich)

		  local app_id="85"
		  local app_name="immich图片视频管理器"
		  local app_text="高性能自托管照片和视频管理解决方案。"
		  local app_url="官网介绍: https://github.com/immich-app/immich"
		  local docker_name="immich_server"
		  local docker_port="8085"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl
			  mkdir -p /home/docker/${docker_name} && cd /home/docker/${docker_name}

			  wget -O docker-compose.yml ${gh_proxy}github.com/immich-app/immich/releases/latest/download/docker-compose.yml
			  wget -O .env ${gh_proxy}github.com/immich-app/immich/releases/latest/download/example.env
			  sed -i "s/2283:2283/${docker_port}:2283/g" /home/docker/${docker_name}/docker-compose.yml

			  docker compose up -d

			  clear
			  echo "已经安装完成"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
		  }

		  docker_app_uninstall() {
			  cd /home/docker/${docker_name} && docker compose down --rmi all
			  rm -rf /home/docker/${docker_name}
			  echo "应用已卸载"
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

		local docker_describe="是一款开源媒体服务器软件"
		local docker_url="官网介绍: https://jellyfin.org/"
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

		local docker_describe="远程一起观看电影和直播的程序。它提供了同步观影、直播、聊天等功能"
		local docker_url="官网介绍: https://github.com/synctv-org/synctv"
		local docker_use="echo \"初始账号和密码: root  登陆后请及时修改登录密码\""
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

		local docker_describe="开源、免费的自建直播平台"
		local docker_url="官网介绍: https://owncast.online"
		local docker_use="echo \"访问地址后面带 /admin 访问管理员页面\""
		local docker_passwd="echo \"初始账号: admin  初始密码: abc123  登陆后请及时修改登录密码\""
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

		local docker_describe="匿名口令分享文本和文件，像拿快递一样取文件"
		local docker_url="官网介绍: https://github.com/vastsa/FileCodeBox"
		local docker_use=""
		local docker_passwd=""
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
				docker run -it --rm \
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

			echo "创建初始用户或管理员。请设置以下内容用户名和密码以及是否为管理员。"
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

		local docker_describe="Matrix是一个去中心化的聊天协议"
		local docker_url="官网介绍: https://matrix.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  91|gitea)

		local app_id="91"

		local app_name="gitea私有代码仓库"
		local app_text="免费新一代的代码托管平台，提供接近 GitHub 的使用体验。"
		local app_url="视频介绍: https://github.com/go-gitea/gitea"
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
			echo "已经安装完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			cd /home/docker/gitea/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			rm -rf /home/docker/gitea
			echo "应用已卸载"
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

		local docker_describe="是一个基于Web的文件管理器"
		local docker_url="官网介绍: https://filebrowser.org/"
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

		local docker_describe="极简静态文件服务器，支持上传下载"
		local docker_url="官网介绍: https://github.com/sigoden/dufs"
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

			read -e -p "设置登录用户名: " app_use
			read -e -p "设置登录密码: " app_passwd

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}/downloads:/app/Downloads \
			  -v /home/docker/${docker_name}/storage:/app/storage \
			  -p ${docker_port}:9999 \
			  ${docker_img} -u ${app_use} -p ${app_passwd}

		}

		local docker_describe="分布式高速下载工具，支持多种协议"
		local docker_url="官网介绍: https://github.com/GopeedLab/gopeed"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;



	  95|paperless)

		local app_id="95"

		local app_name="paperless文档管理平台"
		local app_text="开源的电子文档管理系统，它的主要用途是把你的纸质文件数字化并管理起来。"
		local app_url="视频介绍: https://docs.paperless-ngx.com/"
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
			echo "已经安装完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			rm -rf /home/docker/paperless
			echo "应用已卸载"
		}

		docker_app_plus

		  ;;



	  96|2fauth)

		local app_id="96"

		local app_name="2FAuth自托管二步验证器"
		local app_text="自托管的双重身份验证 (2FA) 账户管理和验证码生成工具。"
		local app_url="官网: https://github.com/Bubka/2FAuth"
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
			echo "已经安装完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			rm -rf /home/docker/2fauth
			echo "应用已卸载"
		}

		docker_app_plus

		  ;;



	97|wgs)

		local app_id="97"
		local docker_name="wireguard"
		local docker_img="lscr.io/linuxserver/wireguard:latest"
		local docker_port=8097

		docker_rum() {

		read -e -p  "请输入组网的客户端数量 (默认 5): " COUNT
		COUNT=${COUNT:-5}
		read -e -p  "请输入 WireGuard 网段 (默认 10.13.13.0): " NETWORK
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

		docker exec -it wireguard bash -c '
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
		echo -e "${gl_huang}所有客户端二维码配置: ${gl_bai}"
		docker exec -it wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
		sleep 2
		echo
		echo -e "${gl_huang}所有客户端配置代码: ${gl_bai}"
		docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
		sleep 2
		echo -e "${gl_lv}${COUNT}个客户端配置全部输出，使用方法如下：${gl_bai}"
		echo -e "${gl_lv}1. 手机下载wg的APP，扫描上方二维码，可以快速连接网络${gl_bai}"
		echo -e "${gl_lv}2. Windows下载客户端，复制配置代码连接网络。${gl_bai}"
		echo -e "${gl_lv}3. Linux用脚本部署WG客户端，复制配置代码连接网络。${gl_bai}"
		echo -e "${gl_lv}官方客户端下载方式: https://www.wireguard.com/install/${gl_bai}"
		break_end

		}

		local docker_describe="现代化、高性能的虚拟专用网络工具"
		local docker_url="官网介绍: https://www.wireguard.com/"
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

			# 创建目录（如果不存在）
			mkdir -p "$(dirname "$CONFIG_FILE")"

			echo "请粘贴你的客户端配置，连续按两次回车保存："

			# 初始化变量
			input=""
			empty_line_count=0

			# 逐行读取用户输入
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

			# 写入配置文件
			echo "$input" > "$CONFIG_FILE"

			echo "客户端配置已保存到 $CONFIG_FILE"

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

		local docker_describe="现代化、高性能的虚拟专用网络工具"
		local docker_url="官网介绍: https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  99|dsm)

		local app_id="99"

		local app_name="dsm群晖虚拟机"
		local app_text="Docker容器中的虚拟DSM"
		local app_url="官网: https://github.com/vdsm/virtual-dsm"
		local docker_name="dsm"
		local docker_port="8099"
		local app_size="16"

		docker_app_install() {

			read -e -p "设置 CPU 核数 (默认 2): " CPU_CORES
			local CPU_CORES=${CPU_CORES:-2}

			read -e -p "设置内存大小 (默认 4G): " RAM_SIZE
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
			echo "已经安装完成"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			rm -rf /home/docker/dsm
			echo "应用已卸载"
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

		local docker_describe="开源的点对点文件同步工具，类似于 Dropbox、Resilio Sync，但完全去中心化。"
		local docker_url="官网介绍: https://github.com/syncthing/syncthing"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;

	  b)
	  	clear
	  	send_stats "全部应用备份"

	  	local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
	  	echo -e "${gl_huang}正在备份 $backup_filename ...${gl_bai}"
	  	cd / && tar czvf "$backup_filename" home

	  	while true; do
			clear
			echo "备份文件已创建: /$backup_filename"
			read -e -p "要传送备份数据到远程服务器吗？(Y/N): " choice
			case "$choice" in
			  [Yy])
				read -e -p "请输入远端服务器IP:  " remote_ip
				read -e -p "目标服务器SSH端口 [默认22]: " TARGET_PORT
				local TARGET_PORT=${TARGET_PORT:-22}

				if [ -z "$remote_ip" ]; then
				  echo "错误: 请输入远端服务器IP。"
				  continue
				fi
				local latest_tar=$(ls -t /app*.tar.gz | head -1)
				if [ -n "$latest_tar" ]; then
				  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				  sleep 2  # 添加等待时间
				  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
				  echo "文件已传送至远程服务器/根目录。"
				else
				  echo "未找到要传送的文件。"
				fi
				break
				;;
			  *)
				echo "注意: 目前备份仅包含docker项目，不包含宝塔，1panel等建站面板的数据备份。"
				break
				;;
			esac
	  	done

		  ;;

	  r)
	  	root_use
	  	send_stats "全部应用还原"
	  	echo "可用的应用备份"
	  	echo "-------------------------"
	  	ls -lt /app*.gz | awk '{print $NF}'
	  	echo ""
	  	read -e -p  "回车键还原最新的备份，输入备份文件名还原指定的备份，输入0退出：" filename

	  	if [ "$filename" == "0" ]; then
			  break_end
			  linux_panel
	  	fi

	  	# 如果用户没有输入文件名，使用最新的压缩包
	  	if [ -z "$filename" ]; then
			  local filename=$(ls -t /app*.tar.gz | head -1)
	  	fi

	  	if [ -n "$filename" ]; then
		  	  echo -e "${gl_huang}正在解压 $filename ...${gl_bai}"
		  	  cd / && tar -xzf "$filename"
			  echo "应用数据已还原，目前请手动进入指定应用菜单，更新应用，即可还原应用。"
	  	else
			  echo "没有找到压缩包。"
	  	fi

		  ;;


	  0)
		  kejilion
		  ;;
	  *)
		  ;;
	esac
	break_end
	sub_choice=""

done
}


linux_work() {

	while true; do
	  clear
	  send_stats "后台工作区"
	  echo -e "后台工作区"
	  echo -e "系统将为你提供可以后台常驻运行的工作区，你可以用来执行长时间的任务"
	  echo -e "即使你断开SSH，工作区中的任务也不会中断，后台常驻任务。"
	  echo -e "${gl_huang}提示: ${gl_bai}进入工作区后使用Ctrl+b再单独按d，退出工作区！"
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
			  echo "0. 返回上一级选单"
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
	  echo -e "系统工具"
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
	  echo -e "${gl_kjlan}21.  ${gl_bai}本机host解析                       ${gl_kjlan}22.  ${gl_bai}SSH防御程序"
	  echo -e "${gl_kjlan}23.  ${gl_bai}限流自动关机                       ${gl_kjlan}24.  ${gl_bai}ROOT私钥登录模式"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot系统监控预警                 ${gl_kjlan}26.  ${gl_bai}修复OpenSSH高危漏洞"
	  echo -e "${gl_kjlan}27.  ${gl_bai}红帽系Linux内核升级                ${gl_kjlan}28.  ${gl_bai}Linux系统内核参数优化 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}病毒扫描工具 ${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}文件管理器"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}切换系统语言                       ${gl_kjlan}32.  ${gl_bai}命令行美化工具 ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}设置系统回收站                     ${gl_kjlan}34.  ${gl_bai}系统备份与恢复"
	  echo -e "${gl_kjlan}35.  ${gl_bai}ssh远程连接工具                    ${gl_kjlan}36.  ${gl_bai}硬盘分区管理工具"
	  echo -e "${gl_kjlan}37.  ${gl_bai}命令行历史记录                     ${gl_kjlan}38.  ${gl_bai}rsync远程同步工具"
	  echo -e "${gl_kjlan}39.  ${gl_bai}命令收藏夹 ${gl_huang}★${gl_bai}"
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

			install sudo

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


				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "当前网络优先级设置: ${gl_huang}IPv4${gl_bai} 优先"
				else
					echo -e "当前网络优先级设置: ${gl_huang}IPv6${gl_bai} 优先"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 优先          2. IPv6 优先          3. IPv6 修复工具"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "选择优先的网络: " choice

				case $choice in
					1)
						grep -q '^precedence ::ffff:0:0/96  100' /etc/gai.conf 2>/dev/null \
  							|| echo 'precedence ::ffff:0:0/96  100' >> /etc/gai.conf
						echo "已切换为 IPv4 优先"
						send_stats "已切换为 IPv4 优先"
						;;
					2)
						rm -f /etc/gai.conf
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
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "当前虚拟内存: ${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 分配1024M         2. 分配2048M         3. 分配4096M         4. 自定义大小"
				echo "------------------------"
				echo "0. 返回上一级选单"
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
					send_stats "已设置4G虚拟内存"
					add_swap 4096

					;;

				  4)
					read -e -p "请输入虚拟内存大小（单位M）: " new_swap
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
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo

					   echo "操作已完成。"

						  ;;
					  3)
					   read -e -p "请输入用户名: " username
					   # 赋予新用户sudo权限
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   install sudo
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
				echo "31. UTC全球标准时间"
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
		  echo "0. 返回上一级选单"
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

				check_f2b_status
				echo -e "SSH防御程序 $check_f2b_status"
				echo "fail2ban是一个SSH防止暴力破解工具"
				echo "官网介绍: ${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. 安装防御程序"
				echo "------------------------"
				echo "2. 查看SSH拦截记录"
				echo "3. 日志实时监控"
				echo "------------------------"
				echo "9. 卸载防御程序"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "请输入你的选择: " sub_choice
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
						echo "Fail2Ban防御程序已卸载"
						break
						;;
					*)
						break
						;;
				esac
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
				echo -e "${gl_kjlan}总接收: ${gl_bai}$rx"
				echo -e "${gl_kjlan}总发送: ${gl_bai}$tx"

				# 检查是否存在 Limiting_Shut_down.sh 文件
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# 获取 threshold_gb 的值
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}当前设置的进站限流阈值为: ${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}当前设置的出站限流阈值为: ${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}当前未启用限流关机功能${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "系统每分钟会检测实际流量是否到达阈值，到达后会自动关闭服务器！"
				echo "------------------------"
				echo "1. 开启限流关机功能          2. 停用限流关机功能"
				echo "------------------------"
				echo "0. 返回上一级选单"
				echo "------------------------"
				read -e -p "请输入你的选择: " Limiting

				case "$Limiting" in
				  1)
					# 输入新的虚拟内存大小
					echo "如果实际服务器就100G流量，可设置阈值为95G，提前关机，以免出现流量误差或溢出。"
					read -e -p "请输入进站流量阈值（单位为G，默认100G）: " rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "请输入出站流量阈值（单位为G，默认100G）: " tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "请输入流量重置日期（默认每月1日重置）: " cz_day
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
			  send_stats "命令行历史记录"
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
			echo "访问科技lion官方留言板，您对脚本有任何想法欢迎留言交流！"
			echo "https://board.kejilion.pro"
			echo "公共密码: kejilion.sh"
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
			  echo "0. 返回上一级选单"
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
		echo "5.  删除目录           6.  返回上一级选单目录"
		echo "------------------------"
		echo "11. 创建文件           12. 编辑文件             13. 修改文件权限         14. 重命名文件"
		echo "15. 删除文件"
		echo "------------------------"
		echo "21. 压缩文件目录       22. 解压文件目录         23. 移动文件目录         24. 复制文件目录"
		echo "25. 传文件至其他服务器"
		echo "------------------------"
		echo "0.  返回上一级选单"
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
			6)  # 返回上一级选单目录
				cd ..
				send_stats "返回上一级选单目录"
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



			0)  # 返回上一级选单
				send_stats "返回上一级选单菜单"
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
	curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/python-for-vps/main/cluster/$py_task
	python3 ~/cluster/$py_task
}


run_commands_on_servers() {

	install sshpass

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
	  echo "服务器集群控制"
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
	  echo -e "${gl_kjlan}0.  ${gl_bai}返回主菜单"
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
echo "广告专栏"
echo "------------------------"
echo "将为用户提供更简单优雅的推广与购买体验！"
echo ""
echo -e "服务器优惠"
echo "------------------------"
echo -e "${gl_lan}莱卡云 香港CN2 GIA 韩国双ISP 美国CN2 GIA 优惠活动${gl_bai}"
echo -e "${gl_bai}网址: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd 10.99刀每年 美国 1核心 1G内存 20G硬盘 1T流量每月${gl_bai}"
echo -e "${gl_bai}网址: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52.7刀每年 美国 1核心 4G内存 50G硬盘 4T流量每月${gl_bai}"
echo -e "${gl_bai}网址: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
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
echo -e "${gl_kjlan}B站: ${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}油管: ${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}官网: ${gl_bai}https://kejilion.pro/              ${gl_kjlan}导航: ${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}博客: ${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}软件中心: ${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}脚本官网: ${gl_bai}https://kejilion.sh            ${gl_kjlan}GitHub地址: ${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "脚本更新"
cd ~
while true; do
	clear
	echo "更新日志"
	echo "------------------------"
	echo "全部日志: ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}你已经是最新版本！${gl_huang}v$sh_v${gl_bai}"
		send_stats "脚本已经最新了，无需更新"
	else
		echo "发现新版本！"
		echo -e "当前版本 v$sh_v        最新版本 ${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}自动更新已开启，每天凌晨2点脚本会自动更新！${gl_bai}"
	fi

	echo "------------------------"
	echo "1. 现在更新            2. 开启自动更新            3. 关闭自动更新"
	echo "------------------------"
	echo "0. 返回主菜单"
	echo "------------------------"
	read -e -p "请输入你的选择: " choice
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
			echo -e "${gl_lv}自动更新已开启，每天凌晨2点脚本会自动更新！${gl_bai}"
			send_stats "开启脚本自动更新"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}自动更新已关闭${gl_bai}"
			send_stats "关闭脚本自动更新"
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
echo -e "科技lion脚本工具箱 v$sh_v"
echo -e "命令行输入${gl_huang}k${gl_kjlan}可快速启动脚本${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}系统信息查询"
echo -e "${gl_kjlan}2.   ${gl_bai}系统更新"
echo -e "${gl_kjlan}3.   ${gl_bai}系统清理"
echo -e "${gl_kjlan}4.   ${gl_bai}基础工具"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR管理"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker管理"
echo -e "${gl_kjlan}7.   ${gl_bai}WARP管理"
echo -e "${gl_kjlan}8.   ${gl_bai}测试脚本合集"
echo -e "${gl_kjlan}9.   ${gl_bai}甲骨文云脚本合集"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP建站"
echo -e "${gl_kjlan}11.  ${gl_bai}应用市场"
echo -e "${gl_kjlan}12.  ${gl_bai}后台工作区"
echo -e "${gl_kjlan}13.  ${gl_bai}系统工具"
echo -e "${gl_kjlan}14.  ${gl_bai}服务器集群控制"
echo -e "${gl_kjlan}15.  ${gl_bai}广告专栏"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}幻兽帕鲁开服脚本"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}脚本更新"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}退出脚本"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "请输入你的选择: " choice

case $choice in
  1) linux_info ;;
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
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
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
echo "重装系统面板        k dd | k 重装"
echo "bbr3控制面板        k bbr3 | k bbrv3"
echo "内核调优面板        k nhyh | k 内核优化"
echo "设置虚拟内存        k swap 2048"
echo "设置虚拟时区        k time Asia/Shanghai | k 时区 Asia/Shanghai"
echo "系统回收站          k trash | k hsz | k 回收站"
echo "系统备份功能        k backup | k bf | k 备份"
echo "ssh远程连接工具     k ssh | k 远程连接"
echo "rsync远程同步工具   k rsync | k 远程同步"
echo "硬盘管理工具        k disk | k 硬盘管理"
echo "内网穿透（服务端）  k frps"
echo "内网穿透（客户端）  k frpc"
echo "软件启动            k start sshd | k 启动 sshd "
echo "软件停止            k stop sshd | k 停止 sshd "
echo "软件重启            k restart sshd | k 重启 sshd "
echo "软件状态查看        k status sshd | k 状态 sshd "
echo "软件开机启动        k enable docker | k autostart docke | k 开机启动 docker "
echo "域名证书申请        k ssl"
echo "域名证书到期查询    k ssl ps"
echo "docker管理平面      k docker"
echo "docker环境安装      k docker install |k docker 安装"
echo "docker容器管理      k docker ps |k docker 容器"
echo "docker镜像管理      k docker img |k docker 镜像"
echo "LDNMP站点管理       k web"
echo "LDNMP缓存清理       k web cache"
echo "安装WordPress       k wp |k wordpress |k wp xxx.com"
echo "安装反向代理        k fd |k rp |k 反代 |k fd xxx.com"
echo "安装负载均衡        k loadbalance |k 负载均衡"
echo "防火墙面板          k fhq |k 防火墙"
echo "开放端口            k dkdk 8080 |k 打开端口 8080"
echo "关闭端口            k gbdk 7800 |k 关闭端口 7800"
echo "放行IP              k fxip 127.0.0.0/8 |k 放行IP 127.0.0.0/8"
echo "阻止IP              k zzip 177.5.25.36 |k 阻止IP 177.5.25.36"
echo "命令收藏夹          k fav | k 命令收藏夹"
echo "应用市场管理        k app"
echo "应用编号快捷管理    k app 26 | k app 1panel | k app npm"
echo "显示系统信息        k info"
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
			send_stats "定时rsync同步"
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
			  echo "已阻止IP+端口访问该服务"
	  		else
			  ip_address
	  		  block_container_port "$docker_name" "$ipv4_address"
	  		fi
			;;

		loadbalance|负载均衡)
			ldnmp_Proxy_backend
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
			send_stats "应用$@"
			linux_panel "$@"
			;;


		info)
			linux_info
			;;

		*)
			k_info
			;;
	esac
fi
