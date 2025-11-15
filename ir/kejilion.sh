#!/bin/bash
sh_v="3.9.3"


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



# یک تابع را برای اجرای دستورات تعریف کنید
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



# کارکردهایی که اطلاعات نقطه دفن شده را جمع می کنند ، شماره نسخه اسکریپت فعلی ، زمان استفاده ، نسخه سیستم ، معماری CPU ، کشور دستگاه و نام عملکردی را که توسط کاربر استفاده می شود ، ضبط کنید. آنها کاملاً اطلاعات حساس را درگیر نمی کنند ، لطفاً مطمئن باشید! لطفا باور کنید!
# چرا ما نیاز به طراحی این عملکرد داریم؟ هدف این است که عملکردهایی را که کاربران دوست دارند از آنها استفاده کنند بهتر درک کنیم و توابع را برای راه اندازی عملکردهای بیشتری که نیازهای کاربر را برآورده می کند ، بهینه سازی کند.
# برای متن کامل ، می توانید مکان تماس عملکرد SEND_STATS ، منبع شفاف و باز را جستجو کنید و در صورت نگرانی می توانید از استفاده از آن خودداری کنید.



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

# کاربر را وادار به موافقت با شرایط کنید
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}به جعبه ابزار Tech Lion Script خوش آمدید${gl_bai}"
	echo "برای اولین بار با استفاده از اسکریپت ، لطفاً توافق نامه مجوز کاربر را بخوانید و موافقت کنید."
	echo "توافق نامه مجوز کاربر: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "آیا با اصطلاحات فوق موافق هستید؟ (y/n):" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "رضایت مجوز"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "رد مجوز"
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
		echo "پارامترهای بسته ارائه نشده است!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}نصب$package...${gl_bai}"
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
				echo "مدیر بسته ناشناخته!"
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
		echo -e "${gl_huang}نکته:${gl_bai}فضای کافی دیسک!"
		echo "فضای موجود در دسترس: $ ((موجود_ space_mb/1024)) g"
		echo "حداقل فضای تقاضا:${required_gb}G"
		echo "نصب نمی تواند ادامه یابد. لطفاً فضای دیسک را تمیز کرده و دوباره امتحان کنید."
		send_stats "فضای دیسک کافی"
		break_end
		kejilion
	fi
}


install_dependency() {
	install wget unzip tar jq
}

remove() {
	if [ $# -eq 0 ]; then
		echo "پارامترهای بسته ارائه نشده است!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}حذف نصب$package...${gl_bai}"
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
			echo "مدیر بسته ناشناخته!"
			return 1
		fi
	done
}


# عملکرد جهانی SystemCtl ، مناسب برای توزیع های مختلف
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# سرویس را مجدداً راه اندازی کنید
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1این سرویس مجدداً راه اندازی شده است."
	else
		echo "خطا: راه اندازی مجدد$1سرویس شکست خورد."
	fi
}

# سرویس را شروع کنید
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1این سرویس آغاز شده است."
	else
		echo "خطا: شروع کنید$1سرویس شکست خورد."
	fi
}

# سرویس توقف
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1سرویس متوقف شده است"
	else
		echo "خطا: توقف$1سرویس شکست خورد."
	fi
}

# وضعیت خدمات را بررسی کنید
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1وضعیت سرویس نمایش داده می شود."
	else
		echo "خطا: نمایش امکان پذیر نیست$1وضعیت خدمات"
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAMEروی قدرت تنظیم کنید."
}



break_end() {
	  echo -e "${gl_lv}عملیات کامل شد${gl_bai}"
	  echo "برای ادامه ... هر کلید را فشار دهید ..."
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
	echo -e "${gl_huang}نصب محیط داکر ...${gl_bai}"
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
	send_stats "مدیریت کانتینر داکر"
	echo "لیست کانتینر داکر"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "کانتینر"
	echo "------------------------"
	echo "1. یک ظرف جدید ایجاد کنید"
	echo "------------------------"
	echo "2. ظرف مشخص شده را شروع کنید 6. همه ظروف را شروع کنید"
	echo "3. کانتینر مشخص شده 7 را متوقف کنید. تمام ظروف را متوقف کنید"
	echo "4. ظرف مشخص شده را حذف کنید 8. همه ظروف را حذف کنید"
	echo "5. ظرف مشخص شده را مجدداً راه اندازی کنید. همه ظروف را مجدداً راه اندازی کنید"
	echo "------------------------"
	echo "11. ظرف مشخص شده 12 را وارد کنید. ورود به سیستم کانتینر را مشاهده کنید"
	echo "13. مشاهده شبکه کانتینر 14. مشاهده اشغال کانتینر"
	echo "------------------------"
	echo "0. به منوی قبلی برگردید"
	echo "------------------------"
	read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
	case $sub_choice in
		1)
			send_stats "یک ظرف جدید ایجاد کنید"
			read -e -p "لطفاً دستور ایجاد را وارد کنید:" dockername
			$dockername
			;;
		2)
			send_stats "ظرف مشخص شده را شروع کنید"
			read -e -p "لطفاً نام کانتینر را وارد کنید (نام چند کانتینر که توسط فضاها جدا شده اند):" dockername
			docker start $dockername
			;;
		3)
			send_stats "ظرف مشخص شده را متوقف کنید"
			read -e -p "لطفاً نام کانتینر را وارد کنید (نام چند کانتینر که توسط فضاها جدا شده اند):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "ظرف مشخص شده را حذف کنید"
			read -e -p "لطفاً نام کانتینر را وارد کنید (نام چند کانتینر که توسط فضاها جدا شده اند):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "ظرف مشخص شده را مجدداً راه اندازی کنید"
			read -e -p "لطفاً نام کانتینر را وارد کنید (چندین نام کانتینر که توسط فضاها جدا شده اند):" dockername
			docker restart $dockername
			;;
		6)
			send_stats "همه ظروف را شروع کنید"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "تمام ظروف را متوقف کنید"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "همه ظروف را حذف کنید"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
				;;
			esac
			;;
		9)
			send_stats "همه ظروف را مجدداً راه اندازی کنید"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "ظرف را وارد کنید"
			read -e -p "لطفاً نام کانتینر را وارد کنید:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "مشاهده کانتینر"
			read -e -p "لطفاً نام کانتینر را وارد کنید:" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "مشاهده شبکه کانتینر"
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
			send_stats "مشاهده اشغال کانتینر"
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
	send_stats "مدیریت تصویر داکر"
	echo "لیست تصویر Docker"
	docker image ls
	echo ""
	echo "عمل آینه"
	echo "------------------------"
	echo "1. تصویر مشخص شده را دریافت کنید. تصویر مشخص شده را حذف کنید"
	echo "2. تصویر مشخص شده را به روز کنید. همه تصاویر را حذف کنید"
	echo "------------------------"
	echo "0. به منوی قبلی برگردید"
	echo "------------------------"
	read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
	case $sub_choice in
		1)
			send_stats "آینه را بکشید"
			read -e -p "لطفاً نام آینه را وارد کنید (لطفاً چندین نام آینه را با فضاها جدا کنید):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}گرفتن تصویر:$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "تصویر را به روز کنید"
			read -e -p "لطفاً نام آینه را وارد کنید (لطفاً چندین نام آینه را با فضاها جدا کنید):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}تصویر به روز شده:$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "آینه را حذف کنید"
			read -e -p "لطفاً نام آینه را وارد کنید (لطفاً چندین نام آینه را با فضاها جدا کنید):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "همه تصاویر را حذف کنید"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
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
				echo "توزیع های پشتیبانی نشده:$ID"
				return
				;;
		esac
	else
		echo "سیستم عامل قابل تعیین نیست."
		return
	fi

	echo -e "${gl_lv}Crontab نصب شده و سرویس Cron در حال اجرا است.${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# بررسی کنید که آیا پرونده پیکربندی وجود دارد ، پرونده را ایجاد کرده و در صورت وجود تنظیمات پیش فرض را بنویسید
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# از JQ برای رسیدگی به به روزرسانی پرونده های پیکربندی استفاده کنید
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# بررسی کنید که آیا پیکربندی فعلی در حال حاضر دارای تنظیمات IPv6 است
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# پیکربندی را به روز کنید و IPv6 را فعال کنید
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# مقایسه پیکربندی اصلی با پیکربندی جدید
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}دسترسی IPv6 در حال حاضر فعال است${gl_bai}"
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

	# بررسی کنید که آیا پرونده پیکربندی وجود دارد
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}پرونده پیکربندی وجود ندارد${gl_bai}"
		return
	fi

	# پیکربندی فعلی را بخوانید
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# از JQ برای رسیدگی به به روزرسانی پرونده های پیکربندی استفاده کنید
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# وضعیت IPv6 فعلی را بررسی کنید
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# مقایسه پیکربندی اصلی با پیکربندی جدید
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}دسترسی IPv6 در حال حاضر بسته است${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}دسترسی IPv6 با موفقیت بسته شده است${gl_bai}"
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
		echo "لطفاً حداقل یک شماره درگاه ارائه دهید"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# قوانین بسته شدن موجود را حذف کنید
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# قوانین باز را اضافه کنید
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "بندر باز شده است$port"
		fi
	done

	save_iptables_rules
	send_stats "بندر باز شده است"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک شماره درگاه ارائه دهید"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# قوانین باز موجود را حذف کنید
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# یک قانون نزدیک اضافه کنید
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "بندر بسته$port"
		fi
	done

	save_iptables_rules
	send_stats "بندر بسته"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک آدرس IP یا بخش IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# قوانین مسدود کردن موجود را حذف کنید
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# قوانین اجازه را اضافه کنید
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IP آزاد شده$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP آزاد شده"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "لطفاً حداقل یک آدرس IP یا بخش IP ارائه دهید"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# قوانین مجاز موجود را حذف کنید
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# قوانین مسدود کردن را اضافه کنید
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP مسدود شده$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP مسدود شده"
}







enable_ddos_defense() {
	# DDO های دفاعی را روشن کنید
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "دفاع DDOS را روشن کنید"
}

# دفاع DDOS را خاموش کنید
disable_ddos_defense() {
	# DDO های دفاع را خاموش کنید
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "دفاع DDOS را خاموش کنید"
}





# کارکردهایی که قوانین ملی IP را مدیریت می کنند
manage_country_rules() {
	local action="$1"
	local country_code="$2"
	local ipset_name="${country_code,,}_block"
	local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

	install ipset

	case "$action" in
		block)
			# اگر IPSET وجود نداشته باشد ایجاد کنید
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# بارگیری پرونده منطقه IP
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "خطا: بارگیری$country_codeپرونده منطقه IP انجام نشد"
				exit 1
			fi

			# IP را به ipset اضافه کنید
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# IP را با iptables مسدود کنید
			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
			iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

			echo "با موفقیت مسدود شد$country_codeآدرس IP"
			rm "${country_code,,}.zone"
			;;

		allow)
			# ایجاد یک IPSET برای کشورهای مجاز (اگر وجود نداشته باشد)
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# بارگیری پرونده منطقه IP
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "خطا: بارگیری$country_codeپرونده منطقه IP انجام نشد"
				exit 1
			fi

			# قوانین ملی موجود را حذف کنید
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null
			ipset flush "$ipset_name"

			# IP را به ipset اضافه کنید
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# فقط IP در کشورهای تعیین شده مجاز است
			iptables -P INPUT DROP
			iptables -P OUTPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
			iptables -A OUTPUT -m set --match-set "$ipset_name" dst -j ACCEPT

			echo "با موفقیت فقط مجاز است$country_codeآدرس IP"
			rm "${country_code,,}.zone"
			;;

		unblock)
			# قوانین iptables را برای کشور حذف کنید
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null

			# Ipset را نابود کنید
			if ipset list "$ipset_name" &> /dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "با موفقیت برداشته شد$country_codeمحدودیت های آدرس IP"
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
		  echo "مدیریت پیشرفته فایروال"
		  send_stats "مدیریت پیشرفته فایروال"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "مدیریت فایروال"
		  echo "------------------------"
		  echo "1. پورت مشخص شده را باز کنید. پورت مشخص شده را ببندید"
		  echo "3. همه درگاه ها را باز کنید. همه درگاه ها را ببندید"
		  echo "------------------------"
		  echo "5. Whitelist IP 6."
		  echo "7. IP مشخص شده را پاک کنید"
		  echo "------------------------"
		  echo "11. اجازه دهید پینگ 12 را غیرفعال کنید"
		  echo "------------------------"
		  echo "13. دفاع DDOS را شروع کنید 14. دفاع DDOS را خاموش کنید"
		  echo "------------------------"
		  echo "15. بلوک کشور مشخص شده IP 16. فقط IP های کشور مشخص مجاز هستند"
		  echo "17. محدودیت های IP را در کشورهای تعیین شده آزاد کنید"
		  echo "------------------------"
		  echo "0. به منوی قبلی برگردید"
		  echo "------------------------"
		  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "لطفاً شماره پورت باز را وارد کنید:" o_port
				  open_port $o_port
				  send_stats "یک درگاه مشخص را باز کنید"
				  ;;
			  2)
				  read -e -p "لطفاً شماره پورت بسته را وارد کنید:" c_port
				  close_port $c_port
				  send_stats "بندر مشخص شده را ببندید"
				  ;;
			  3)
				  # همه بنادر را باز کنید
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
				  send_stats "همه بنادر را باز کنید"
				  ;;
			  4)
				  # همه بنادر را ببندید
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
				  send_stats "همه بنادر را ببندید"
				  ;;

			  5)
				  # وایتلیست
				  read -e -p "لطفاً بخش IP یا IP را وارد کنید تا منتشر شود:" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # لیست سیاه IP
				  read -e -p "لطفاً بخش IP یا IP مسدود شده را وارد کنید:" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # IP مشخص شده را پاک کنید
				  read -e -p "لطفاً IP پاک شده را وارد کنید:" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "IP مشخص شده را پاک کنید"
				  ;;
			  11)
				  # به پینگ اجازه دهید
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "به پینگ اجازه دهید"
				  ;;
			  12)
				  # پینگ را غیرفعال کنید
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "پینگ را غیرفعال کنید"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "لطفاً کد کشور مسدود شده را وارد کنید (مانند CN ، ایالات متحده ، JP):" country_code
				  manage_country_rules block $country_code
				  send_stats "کشورهای مجاز$country_codeبا منبت کاری کردن"
				  ;;
			  16)
				  read -e -p "لطفاً کد کشور مجاز (مانند CN ، ایالات متحده ، JP) را وارد کنید:" country_code
				  manage_country_rules allow $country_code
				  send_stats "کشور را مسدود کنید$country_codeبا منبت کاری کردن"
				  ;;

			  17)
				  read -e -p "لطفاً کد کشور پاک شده را وارد کنید (مانند CN ، ایالات متحده ، JP):" country_code
				  manage_country_rules unblock $country_code
				  send_stats "کشور را پاک کنید$country_codeبا منبت کاری کردن"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}








add_swap() {
	local new_swap=$1  # 获取传入的参数

	# تمام پارتیشن های مبادله را در سیستم فعلی دریافت کنید
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# تمام پارتیشن های مبادله را تکرار کرده و حذف کنید
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# اطمینان حاصل کنید که /Swapfile دیگر استفاده نمی شود
	swapoff /swapfile

	# قدیمی /swapfile را حذف کنید
	rm -f /swapfile

	# یک پارتیشن مبادله جدید ایجاد کنید
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

	echo -e "اندازه حافظه مجازی تغییر یافته است${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# تعیین کنید که آیا حافظه مجازی باید ایجاد شود
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # نسخه nginx را دریافت کنید
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # نسخه MySQL را دریافت کنید
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # نسخه PHP را دریافت کنید
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # نسخه redis را دریافت کنید
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # دایرکتوری ها و پرونده های لازم را ایجاد کنید
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf
  wget -O /home/web/redis/valkey.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/valkey.conf


  default_server_ssl

  # پرونده docker-compose.yml را بارگیری کنید و آن را جایگزین کنید
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # در پرونده docker-compose.yml جایگزین کنید
  sed -i "s#webroot#$dbrootpasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilionYYDS#$dbusepasswd#g" /home/web/docker-compose.yml
  sed -i "s#kejilion#$dbuse#g" /home/web/docker-compose.yml

}





install_ldnmp() {

	  check_swap

	  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml

	  if ! grep -q "php-socket" /home/web/docker-compose.yml; then
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
	  echo "محیط LDNMP نصب شده است"
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
	echo "کار تمدید به روز شده است"
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
	echo -e "${gl_huang}$yumingاطلاعات کلیدی عمومی${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yumingاطلاعات کلید خصوصی${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}مسیر ذخیره گواهینامه${gl_bai}"
	echo "کلید عمومی:/و غیره/letsencrypt/live/$yuming/fullchain.pem"
	echo "کلید خصوصی:/و غیره/letsencrypt/live/$yuming/privkey.pem"
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
	echo -e "${gl_huang}انقضاء گواهی اعمال شده${gl_bai}"
	echo "زمان انقضا گواهی اطلاعات سایت"
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
		send_stats "برنامه موفق برای گواهی نام دامنه"
	else
		send_stats "درخواست گواهی نام دامنه انجام نشد"
		echo -e "${gl_hong}توجه:${gl_bai}برنامه گواهینامه انجام نشد. لطفاً دلایل احتمالی زیر را بررسی کنید و دوباره امتحان کنید:"
		echo -e "1. خطای املایی نام دامنه ➠ لطفا بررسی کنید که آیا نام دامنه به درستی وارد شده است"
		echo -e "2. مشکل وضوح DNS ➠ تأیید کنید که نام دامنه به درستی در این IP سرور حل شده است"
		echo -e "3. مشکلات پیکربندی شبکه ➠ اگر از CloudFlare Warp و سایر شبکه های مجازی استفاده می کنید ، لطفاً به طور موقت خاموش شوید"
		echo -e "4. محدودیت های فایروال ➠ بررسی کنید که آیا پورت 80/443 برای اطمینان از تأیید صحت باز است"
		echo -e "5. تعداد برنامه ها از حد مجاز فراتر می رود ➠ بیایید رمزگذاری کنیم دارای محدودیت هفتگی (5 بار/نام دامنه/هفته) است"
		break_end
		clear
		echo "لطفا دوباره امتحان کنید$webname"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "استفاده مجدد از نام دامنه"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "ابتدا نام دامنه را به IP محلی حل کنید:${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "لطفاً IP یا نام دامنه حل شده خود را وارد کنید:" yuming
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

  send_stats "تمدید کردن$ldnmp_pods"
  echo "تمدید کردن${ldnmp_pods}پایان"

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
  echo "اطلاعات ورود به سیستم:"
  echo "نام کاربری:$dbuse"
  echo "رمز عبور:$dbusepasswd"
  echo
  send_stats "شروع کردن$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # بررسی کنید که آیا پرونده پیکربندی وجود دارد
  if [ -f "$CONFIG_FILE" ]; then
	# از پرونده های پیکربندی api_token و Zone_id را بخوانید
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# تبدیل Zone_ids به یک آرایه
	ZONE_IDS=($ZONE_IDS)
  else
	# کاربر را برای تمیز کردن حافظه نهان راهنمایی کنید
	read -e -p "آیا نیاز به تمیز کردن حافظه پنهان Cloudflare دارید؟ (y/n):" answer
	if [[ "$answer" == "y" ]]; then
	  echo "اطلاعات CF ذخیره می شود$CONFIG_FILE، بعداً می توانید اطلاعات CF را تغییر دهید"
	  read -e -p "لطفاً API_TOKEN خود را وارد کنید:" API_TOKEN
	  read -e -p "لطفا نام کاربری CF خود را وارد کنید:" EMAIL
	  read -e -p "لطفاً Zone_Id را وارد کنید (چند برابر با فضاها از هم جدا شده است):" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # از طریق هر Zone_id حلقه کنید و دستور حافظه پنهان را اجرا کنید
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "پاک کردن حافظه پنهان برای Zone_ID:$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "درخواست Cache Clear ارسال شده است."
}



web_cache() {
  send_stats "حافظه پنهان سایت را تمیز کنید"
  cf_purge_cache
  docker exec php php -r 'opcache_reset();'
  docker exec php74 php -r 'opcache_reset();'
  docker exec nginx nginx -s stop
  docker exec nginx rm -rf /var/cache/nginx/*
  docker exec nginx nginx
  docker restart redis
  restart_redis
}



web_del() {

	send_stats "داده های سایت را حذف کنید"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "برای حذف داده های سایت ، لطفاً نام دامنه خود را وارد کنید (نام دامنه های چندگانه توسط فضاها از هم جدا می شوند):" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "حذف نام دامنه:$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# نام دامنه را به نام پایگاه داده تبدیل کنید
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# بررسی کنید که آیا پایگاه داده قبل از حذف آن وجود دارد تا از خطا جلوگیری شود
		echo "حذف بانک اطلاعاتی:$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# تصمیم بگیرید WAF را با توجه به پارامتر حالت روشن یا خاموش کنید
	if [ "$mode" == "on" ]; then
		# WAF را روشن کنید: نظرات را حذف کنید
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# بستن WAF: اضافه کردن نظرات
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "پارامتر نامعتبر: از "ON" یا "خاموش" استفاده کنید"
		return 1
	fi

	# تصاویر nginx را بررسی کنید و مطابق با وضعیت آنها را کنترل کنید
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




















check_docker_app() {

if docker inspect "$docker_name" &>/dev/null; then
	check_docker="${gl_lv}已安装${gl_bai}"
else
	check_docker="${gl_hui}未安装${gl_bai}"
fi

}


check_docker_app_ip() {
echo "------------------------"
echo "آدرس دسترسی:"
ip_address
if [ -n "$ipv4_address" ]; then
	echo "http://$ipv4_address:${docker_port}"
fi

if [ -n "$ipv6_address" ]; then
	echo "http://[$ipv6_address]:${docker_port}"
fi

local search_pattern="$ipv4_address:${docker_port}"

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

	# زمان و نام تصویر ایجاد کانتینر را دریافت کنید
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# انبارهای آینه و برچسب ها را استخراج کنید
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# برچسب پیش فرض آخرین است
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# پشتیبانی از تصاویر رسمی را اضافه کنید
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# زمان انتشار تصویر را از Docker Hub API دریافت کنید
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# زمان کسب را تأیید کنید
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# مقایسه های زمانی را مقایسه کنید
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

	# آدرس IP ظرف را دریافت کنید
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "خطا: نمی توان کانتینر را دریافت کرد$container_name_or_idآدرس IP لطفاً بررسی کنید که آیا نام کانتینر یا شناسه صحیح است."
		return 1
	fi

	install iptables


	# همه IP های دیگر را بررسی و مسدود کنید
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# IP مشخص شده را بررسی و آزاد کنید
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# شبکه محلی 127.0.0.0/8 را بررسی و آزاد کنید
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# همه IP های دیگر را بررسی و مسدود کنید
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# IP مشخص شده را بررسی و آزاد کنید
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# شبکه محلی 127.0.0.0/8 را بررسی و آزاد کنید
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "درگاه های IP از دسترسی به سرویس مسدود شده اند"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# آدرس IP ظرف را دریافت کنید
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "خطا: نمی توان کانتینر را دریافت کرد$container_name_or_idآدرس IP لطفاً بررسی کنید که آیا نام کانتینر یا شناسه صحیح است."
		return 1
	fi

	install iptables


	# قوانین روشن که همه IP های دیگر را مسدود می کند
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# قوانین انتشار IP مشخص شده را پاک کنید
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# قوانین مربوط به انتشار شبکه محلی 127.0.0.0/8 را پاک کنید
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# قوانین روشن که همه IP های دیگر را مسدود می کند
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# قوانین انتشار IP مشخص شده را پاک کنید
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# قوانین مربوط به انتشار شبکه محلی 127.0.0.0/8 را پاک کنید
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "درگاه های IP+مجاز به دسترسی به سرویس هستند"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "خطا: لطفاً شماره پورت و IP را که مجاز به دسترسی است ، تهیه کنید."
		echo "استفاده: block_host_port <شماره پورت> <مجاز IP>"
		return 1
	fi

	install iptables


	# دسترسی به IP دیگر را رد کرد
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# دسترسی به IP مشخص شده
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# دسترسی به محلی
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# دسترسی به IP دیگر را رد کرد
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# دسترسی به IP مشخص شده
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# دسترسی به محلی
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# اجازه ترافیک برای اتصالات ایجاد شده و مرتبط را داشته باشید
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "درگاه های IP از دسترسی به سرویس مسدود شده اند"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "خطا: لطفاً شماره پورت و IP را که مجاز به دسترسی است ، تهیه کنید."
		echo "استفاده: clear_host_port_rules <شماره پورت> <مجاز IP>"
		return 1
	fi

	install iptables


	# قوانین را روشن کنید که تمام دسترسی IP را مسدود می کند
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# قوانین روشن که امکان دسترسی بومی را فراهم می کند
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# قوانین را پاک کنید که امکان دسترسی به IP مشخص شده را فراهم می کند
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# قوانین را روشن کنید که تمام دسترسی IP را مسدود می کند
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# قوانین روشن که امکان دسترسی بومی را فراهم می کند
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# قوانین را پاک کنید که امکان دسترسی به IP مشخص شده را فراهم می کند
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "درگاه های IP+مجاز به دسترسی به سرویس هستند"
	save_iptables_rules

}





docker_app() {
send_stats "${docker_name}مدیریت کردن"

while true; do
	clear
	check_docker_app
	check_docker_image_update $docker_name
	echo -e "$docker_name $check_docker $update_status"
	echo "$docker_describe"
	echo "$docker_url"
	if docker inspect "$docker_name" &>/dev/null; then
		local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
		docker_port=${docker_port:-0000}
		check_docker_app_ip
	fi
	echo ""
	echo "------------------------"
	echo "1. نصب 2. بروزرسانی 3. حذف نصب کنید"
	echo "------------------------"
	echo "5. دسترسی به نام دامنه را اضافه کنید 6. دسترسی به نام دامنه را حذف کنید"
	echo "7. اجازه دسترسی به پورت IP+ 8 را داشته باشید."
	echo "------------------------"
	echo "0. به منوی قبلی برگردید"
	echo "------------------------"
	read -e -p "لطفا انتخاب خود را وارد کنید:" choice
	 case $choice in
		1)
			check_disk_space $app_size
			read -e -p "درگاه سرویس خارجی برنامه را وارد کنید و پیش فرض را وارد کنید${docker_port}بندر:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			clear
			echo "$docker_nameنصب شده"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "نصب کردن$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum
			clear
			echo "$docker_nameنصب شده"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "تمدید کردن$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			echo "برنامه حذف شده است"
			send_stats "حذف کردن$docker_name"
			;;

		5)
			echo "${docker_name}تنظیمات دسترسی دامنه"
			send_stats "${docker_name}تنظیمات دسترسی دامنه"
			add_yuming
			ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "فرمت نام دامنه مثال. com با https: // همراه نیست"
			web_del
			;;

		7)
			send_stats "دسترسی به IP${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "دسترسی به IP${docker_name}"
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
			local docker_port=$(docker port "$docker_name" | head -n1 | awk -F'[:]' '/->/ {print $NF; exit}')
			docker_port=${docker_port:-0000}
			check_docker_app_ip
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. بروزرسانی 3. حذف نصب کنید"
		echo "------------------------"
		echo "5. دسترسی به نام دامنه را اضافه کنید 6. دسترسی به نام دامنه را حذف کنید"
		echo "7. اجازه دسترسی به پورت IP+ 8 را داشته باشید."
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice
		case $choice in
			1)
				check_disk_space $app_size
				read -e -p "درگاه سرویس خارجی برنامه را وارد کنید و پیش فرض را وارد کنید${docker_port}بندر:" app_port
				local app_port=${app_port:-${docker_port}}
				local docker_port=$app_port
				install jq
				install_docker
				docker_app_install
				;;
			2)
				docker_app_update
				;;
			3)
				docker_app_uninstall
				;;
			5)
				echo "${docker_name}تنظیمات دسترسی دامنه"
				send_stats "${docker_name}تنظیمات دسترسی دامنه"
				add_yuming
				ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "فرمت نام دامنه مثال. com با https: // همراه نیست"
				web_del
				;;
			7)
				send_stats "دسترسی به IP${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "دسترسی به IP${docker_name}"
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

# توابعی که بررسی می کنند جلسه وجود دارد
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# حلقه تا زمانی که نام جلسه غیر موجود پیدا شود
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# یک جلسه TMUX جدید ایجاد کنید
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

	read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}现在重启服务器吗？(Y/N): ")" rboot
	case "$rboot" in
	  [Yy])
		echo "مجدداً"
		reboot
		;;
	  *)
		echo "لغو شده"
		;;
	esac


}

output_status() {
	output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
		# مطابقت با نام کارتهای شبکه عمومی عمومی: ETH*، ENS*، ENP*، ENO*
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

			printf("总接收:       %.2f%s\n总发送:       %.2f%s\n", rx_total, rx_units, tx_total, tx_units);
		}' /proc/net/dev)
	# echo "$output"
}



ldnmp_install_status_one() {

   if docker inspect "php" &>/dev/null; then
	clear
	send_stats "دوباره نصب محیط LDNMP امکان پذیر نیست"
	echo -e "${gl_huang}نکته:${gl_bai}محیط ساخت وب سایت نصب شده است. نیازی به نصب مجدد نیست!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "محیط LDNMP را نصب کنید"
root_use
clear
echo -e "${gl_huang}محیط LDNMP نصب نشده است ، شروع به نصب محیط LDNMP ...${gl_bai}"
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
send_stats "محیط nginx را نصب کنید"
root_use
clear
echo -e "${gl_huang}nginx نصب نشده است ، شروع به نصب محیط nginx ...${gl_bai}"
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
echo "nginx نصب شده است"
echo -e "نسخه فعلی:${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "لطفاً ابتدا محیط LDNMP را نصب کنید"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "لطفاً ابتدا محیط nginx را نصب کنید"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "مال شما$webnameساخته شده!"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webnameاطلاعات نصب به شرح زیر است:"

}

nginx_web_on() {
	  clear
	  echo "مال شما$webnameساخته شده!"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "نصب کردن$webname"
  echo "استقرار را شروع کنید$webname"
  if [ -z "$yuming" ]; then
	add_yuming
  fi
  repeat_add_yuming
  ldnmp_install_status
  install_ssltls
  certs_status
  add_db
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
# echo "نام پایگاه داده: $ dbname"
# اکو "نام کاربری: $ dbuse"
# ECHO "رمز عبور: $ dbusepasswd"
# ECHO "آدرس پایگاه داده: MySQL"
# ECHO "پیشوند جدول: WP_"

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "نصب کردن$webname"
	echo "استقرار را شروع کنید$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "لطفاً IP ضد نسل خود را وارد کنید:" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "لطفاً درگاه ضد نسل خود را وارد کنید:" port
	fi
	nginx_install_status
	install_ssltls
	certs_status
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

	send_stats "نصب کردن$webname"
	echo "استقرار را شروع کنید$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# دریافت چندین IP توسط کاربر: پورت ها (جدا شده توسط فضاها)
	if [ -z "$reverseproxy_port" ]; then
		read -e -p "لطفاً چندین پورت IP+ ضد نسل خود را که توسط فضاها از هم جدا شده اند وارد کنید (به عنوان مثال ، 127.0.0.1:3000 127.0.0.1:3002):" reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	# به صورت پویا پیکربندی بالادست تولید می کند
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	# متغیرها را در قالب ها جایگزین کنید
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
		send_stats "مدیریت سایت LDNMP"
		echo "محیط LDNMP"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}زمان انقضا گواهی"
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
		echo "فهرست سایت"
		echo "------------------------"
		echo -e "داده${gl_hui}/home/web/html${gl_bai}گواهی${gl_hui}/home/web/certs${gl_bai}پیکربندی${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "عمل کردن"
		echo "------------------------"
		echo "1. درخواست/به روزرسانی گواهی نام دامنه 2. نام دامنه سایت را تغییر دهید"
		echo "3. حافظه پنهان سایت را تمیز کنید. یک سایت مرتبط ایجاد کنید"
		echo "5. مشاهده ورود به سیستم دسترسی 6. مشاهده خطای خطای"
		echo "7. ویرایش پیکربندی جهانی 8. پیکربندی سایت را ویرایش کنید"
		echo "9. مدیریت پایگاه داده سایت 10. مشاهده گزارش تجزیه و تحلیل سایت"
		echo "------------------------"
		echo "20. داده های سایت مشخص شده را حذف کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		case $sub_choice in
			1)
				send_stats "برای گواهی نام دامنه اقدام کنید"
				read -e -p "لطفاً نام دامنه خود را وارد کنید:" yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "نام دامنه سایت را تغییر دهید"
				echo -e "${gl_hong}بسیار توصیه می شود:${gl_bai}ابتدا از کل داده های سایت نسخه پشتیبان تهیه کرده و سپس نام دامنه سایت را تغییر دهید!"
				read -e -p "لطفاً نام دامنه قدیمی را وارد کنید:" oddyuming
				read -e -p "لطفاً نام دامنه جدید را وارد کنید:" yuming
				install_certbot
				install_ssltls
				certs_status

				# جایگزینی mysql
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

				# جایگزینی فهرست وب سایت
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
				send_stats "یک سایت مرتبط ایجاد کنید"
				echo -e "نام دامنه جدیدی را برای سایت موجود برای دسترسی مرتبط کنید"
				read -e -p "لطفاً نام دامنه موجود را وارد کنید:" oddyuming
				read -e -p "لطفاً نام دامنه جدید را وارد کنید:" yuming
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
				send_stats "مشاهده ورود به سیستم دسترسی"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "مشاهده خطای مشاهده"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "پیکربندی جهانی را ویرایش کنید"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "پیکربندی سایت را ویرایش کنید"
				read -e -p "برای ویرایش پیکربندی سایت ، لطفاً نام دامنه مورد نظر برای ویرایش را وارد کنید:" yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "مشاهده داده های سایت"
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
if $lujing ; then
	check_panel="${gl_lv}已安装${gl_bai}"
else
	check_panel=""
fi
}



install_panel() {
send_stats "${panelname}مدیریت کردن"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname}امروزه این یک هیئت مدیره عملیاتی و مدیریت نگهداری محبوب و قدرتمند است."
	echo "معرفی رسمی وب سایت:$panelurl "

	echo ""
	echo "------------------------"
	echo "1. نصب 2. مدیریت 3. حذف نصب کنید"
	echo "------------------------"
	echo "0. به منوی قبلی برگردید"
	echo "------------------------"
	read -e -p "لطفا انتخاب خود را وارد کنید:" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install
			send_stats "${panelname}نصب کردن"
			;;
		2)
			panel_app_manage
			send_stats "${panelname}کنترل کردن"

			;;
		3)
			panel_app_uninstall
			send_stats "${panelname}حذف کردن"
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
	rm -rf /home/frp/frp_0.61.0_linux_amd64

	arch=$(uname -m)
	frp_v=$(curl -s https://api.github.com/repos/fatedier/frp/releases/latest | grep -oP '"tag_name": "v\K.*?(?=")')

	if [[ "$arch" == "x86_64" ]]; then
		curl -L ${gh_proxy}github.com/fatedier/frp/releases/download/v${frp_v}/frp_${frp_v}_linux_amd64.tar.gz -o frp_${frp_v}_linux_amd64.tar.gz
	elif [[ "$arch" == "armv7l" || "$arch" == "aarch64" ]]; then
		curl -L ${gh_proxy}github.com/fatedier/frp/releases/download/v${frp_v}/frp_${frp_v}_linux_arm.tar.gz -o frp_${frp_v}_linux_amd64.tar.gz
	else
		echo "معماری CPU فعلی پشتیبانی نمی شود:$arch"
	fi

	# آخرین پرونده FRP بارگیری شده را پیدا کنید
	latest_file=$(ls -t /home/frp/frp_*.tar.gz | head -n 1)

	# پرونده را از حالت فشرده خارج کنید
	tar -zxvf "$latest_file"

	# نام پوشه فشرده شده را دریافت کنید
	dir_name=$(tar -tzf "$latest_file" | head -n 1 | cut -f 1 -d '/')

	# پوشه را به نام نسخه یکپارچه تغییر نام دهید
	mv "$dir_name" "frp_0.61.0_linux_amd64"



}



generate_frps_config() {

	send_stats "سرور FRP را نصب کنید"
	# درگاه ها و اعتبارنامه های تصادفی تولید کنید
	local bind_port=8055
	local dashboard_port=8056
	local token=$(openssl rand -hex 16)
	local dashboard_user="user_$(openssl rand -hex 4)"
	local dashboard_pwd=$(openssl rand -hex 8)

	donlond_frp

	# یک فایل frps.toml ایجاد کنید
	cat <<EOF > /home/frp/frp_0.61.0_linux_amd64/frps.toml
[common]
bind_port = $bind_port
authentication_method = token
token = $token
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
EOF

	# اطلاعات تولید شده
	ip_address
	echo "------------------------"
	echo "پارامترهای مورد نیاز برای استقرار مشتری"
	echo "سرویس IP:$ipv4_address"
	echo "token: $token"
	echo
	echo "اطلاعات پانل FRP"
	echo "آدرس پنل FRP: http: //$ipv4_address:$dashboard_port"
	echo "نام کاربری پنل FRP:$dashboard_user"
	echo "رمز عبور پنل FRP:$dashboard_pwd"
	echo
	echo "------------------------"
	install tmux
	tmux kill-session -t frps >/dev/null 2>&1
	tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"
	check_crontab_installed
	crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
	(crontab -l ; echo '@reboot tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"') | crontab - > /dev/null 2>&1

	open_port 8055 8056

}



configure_frpc() {
	send_stats "مشتری FRP را نصب کنید"
	read -e -p "لطفاً IP Docking Network External را وارد کنید:" server_addr
	read -e -p "لطفاً توکن docking شبکه خارجی را وارد کنید:" token
	echo

	if command -v opkg >/dev/null 2>&1; then
		opkg update
		opkg install grep
	fi

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

	open_port 8055

}

add_forwarding_service() {
	send_stats "سرویس Intranet FRP را اضافه کنید"
	# کاربر را وادار به وارد کردن نام سرویس و اطلاعات ارسال کنید
	read -e -p "لطفاً نام سرویس را وارد کنید:" service_name
	read -e -p "لطفاً نوع حمل و نقل (TCP/UDP) را وارد کنید [TCP پیش فرض] را وارد کنید:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "لطفاً IP Intranet را وارد کنید [پیش فرض 127.0.0.1 را وارد کنید]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "لطفاً درگاه اینترانت را وارد کنید:" local_port
	read -e -p "لطفاً درگاه شبکه خارجی را وارد کنید:" remote_port

	# ورودی کاربر را به پرونده پیکربندی بنویسید
	cat <<EOF >> /home/frp/frp_0.61.0_linux_amd64/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# اطلاعات تولید شده
	echo "خدمت کردن$service_nameبا موفقیت به frpc.toml اضافه شد"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "سرویس Intranet FRP را حذف کنید"
	# کاربر را وادار به وارد کردن نام خدماتی که باید حذف شود
	read -e -p "لطفاً نام خدماتی را که باید حذف شود وارد کنید:" service_name
	# برای حذف سرویس و تنظیمات مربوط به آن از SED استفاده کنید
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frp_0.61.0_linux_amd64/frpc.toml
	echo "خدمت کردن$service_nameبا موفقیت از frpc.toml حذف شد"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

}


list_forwarding_services() {
	local config_file="$1"

	# هدر را چاپ کنید
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
		# اگر اطلاعات سرویس وجود دارد ، قبل از پردازش سرویس جدید ، سرویس فعلی را چاپ کنید
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# نام سرویس فعلی را به روز کنید
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# مقدار قبلی را پاک کنید
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
		# اطلاعات را برای آخرین سرویس چاپ کنید
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# درگاه سرور FRP را دریافت کنید
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# ایجاد آدرس دسترسی
generate_access_urls() {
	# ابتدا همه درگاه ها را دریافت کنید
	get_frp_ports

	# بررسی کنید که آیا پورت هایی غیر از 8055/8056 وجود دارد؟
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# عنوان و محتوا را فقط در صورت وجود درگاه معتبر نشان دهید
	if [ "$has_valid_ports" = true ]; then
		echo "آدرس دسترسی خارجی خدمات FRP:"

		# پردازش آدرس IPv4
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# پردازش آدرس های IPv6 (در صورت وجود)
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# رسیدگی به پیکربندی HTTPS
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				frps_search_pattern="${ipv4_address}:${port}"
				for file in /home/web/conf.d/*.conf; do
					if [ -f "$file" ]; then
						if grep -q "$frps_search_pattern" "$file" 2>/dev/null; then
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
	send_stats "سرور FRP"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		echo -e "سرور FRP$check_frp"
		echo "برای افشای دستگاه ها بدون IP عمومی در اینترنت ، یک محیط سرویس نفوذ Intranet FRP ایجاد کنید"
		echo "معرفی وب سایت رسمی: https://github.com/fatedier/frp/"
		echo "آموزش ویدیو: https://www.bilibili.com/video/bv1ymw6e2ewl؟t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. بروزرسانی 3. حذف نصب کنید"
		echo "------------------------"
		echo "5. دسترسی به نام دامنه برای سرویس Intranet 6. دسترسی به نام دامنه را حذف کنید"
		echo "------------------------"
		echo "7. اجازه دسترسی به پورت IP+ 8 را داشته باشید."
		echo "------------------------"
		echo "00. وضعیت خدمات را تازه کنید. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice
		case $choice in
			1)
				generate_frps_config
				rm -rf /home/frp/*.tar.gz
				echo "سرور FRP نصب شده است"
				;;
			2)
				cp -f /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp
				cp -f /home/frp/frps.toml /home/frp/frp_0.61.0_linux_amd64/frps.toml
				tmux kill-session -t frps >/dev/null 2>&1
				tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				(crontab -l ; echo '@reboot tmux new -d -s "frps" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frps -c frps.toml"') | crontab - > /dev/null 2>&1
				rm -rf /home/frp/*.tar.gz
				echo "سرور FRP به روز شده است"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				rm -rf /home/frp
				close_port 8055 8056

				echo "برنامه حذف شده است"
				;;
			5)
				echo "سرویس نفوذ اینترانت معکوس در دسترسی به نام دامنه"
				send_stats "دسترسی FRP به نام دامنه خارجی"
				add_yuming
				read -e -p "لطفاً درگاه سرویس نفوذ Intranet خود را وارد کنید:" frps_port
				ldnmp_Proxy ${yuming} ${ipv4_address} ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "فرمت نام دامنه مثال. com با https: // همراه نیست"
				web_del
				;;

			7)
				send_stats "دسترسی به IP"
				read -e -p "لطفاً برای انتشار درگاه را وارد کنید:" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "دسترسی به IP"
				echo "اگر به نام دامنه ضد نسل دسترسی پیدا کرده اید ، می توانید از این عملکرد برای مسدود کردن دسترسی به پورت IP+ استفاده کنید ، که امنیت بیشتری دارد."
				read -e -p "لطفاً درگاه مورد نیاز خود را وارد کنید:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "وضعیت سرویس FRP را تازه کنید"
				echo "وضعیت خدمات FRP تازه شده است"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "مشتری FRP"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		echo -e "مشتری FRP$check_frp"
		echo "با اتصال به سرور ، پس از اتصال ، می توانید سرویس نفوذ اینترانت را به دسترسی به اینترنت ایجاد کنید"
		echo "معرفی وب سایت رسمی: https://github.com/fatedier/frp/"
		echo "آموزش ویدیو: https://www.bilibili.com/video/bv1ymw6e2ewl؟t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			list_forwarding_services "/home/frp/frp_0.61.0_linux_amd64/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. نصب 2. بروزرسانی 3. حذف نصب کنید"
		echo "------------------------"
		echo "4. اضافه کردن خدمات خارجی 5. خدمات خارجی را حذف کنید 6. پیکربندی خدمات به صورت دستی"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "انتخاب خود را وارد کنید:" choice
		case $choice in
			1)
				configure_frpc
				rm -rf /home/frp/*.tar.gz
				echo "مشتری FRP نصب شده است"
				;;
			2)
				cp -f /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp
				cp -f /home/frp/frpc.toml /home/frp/frp_0.61.0_linux_amd64/frpc.toml
				tmux kill-session -t frpc >/dev/null 2>&1
				tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				(crontab -l ; echo '@reboot tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"') | crontab - > /dev/null 2>&1
				rm -rf /home/frp/*.tar.gz
				echo "مشتری FRP به روز شده است"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				rm -rf /home/frp
				close_port 8055
				echo "برنامه حذف شده است"
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
		send_stats "ابزار بارگیری YT-DLP"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "YT-DLP یک ابزار قدرتمند بارگیری ویدیویی است که از هزاران سایت از جمله YouTube ، Bilibili ، Twitter و غیره پشتیبانی می کند."
		echo -e "آدرس وب سایت رسمی: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "لیست ویدیویی بارگیری شده:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(هنوز هیچ)"
		echo "-------------------------"
		echo "1. نصب 2. بروزرسانی 3. حذف نصب کنید"
		echo "-------------------------"
		echo "5. دانلود ویدیوی مجرد 6. دانلود ویدیوی دسته ای 7. پارامتر سفارشی"
		echo "8. بارگیری به عنوان MP3 Audio 9. حذف فهرست ویدیو 10. مدیریت کوکی (در حال توسعه)"
		echo "-------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "-------------------------"
		read -e -p "لطفاً شماره گزینه را وارد کنید:" choice

		case $choice in
			1)
				send_stats "نصب YT-DLP ..."
				echo "نصب YT-DLP ..."
				install ffmpeg
				sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				sudo chmod a+rx /usr/local/bin/yt-dlp
				echo "نصب کامل است. برای ادامه ... هر کلید را فشار دهید ..."
				read ;;
			2)
				send_stats "yt-dlp را به روز کنید ..."
				echo "yt-dlp را به روز کنید ..."
				sudo yt-dlp -U
				echo "به روزرسانی کامل شد. برای ادامه ... هر کلید را فشار دهید ..."
				read ;;
			3)
				send_stats "حذف yt-dlp ..."
				echo "حذف yt-dlp ..."
				sudo rm -f /usr/local/bin/yt-dlp
				echo "حذف نصب کامل است. برای ادامه ... هر کلید را فشار دهید ..."
				read ;;
			5)
				send_stats "بارگیری ویدیویی تک"
				read -e -p "لطفا لینک ویدیویی را وارد کنید:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "پس از اتمام بارگیری ، هر کلید را فشار دهید تا ادامه یابد ..." ;;
			6)
				send_stats "دانلود ویدیوی دسته ای"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# چندین آدرس پیوند ویدیویی را وارد کنید \ n# https://www.bilibili.com/bangumi/play/ep733316؟spm_id_from=333.337.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "اکنون بارگیری دسته را شروع کنید ..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "بارگیری دسته ای تکمیل شده است ، برای ادامه ... هر کلید را فشار دهید ..." ;;
			7)
				send_stats "بارگیری ویدیوی سفارشی"
				read -e -p "لطفاً پارامتر کامل YT-DLP را وارد کنید (به استثنای YT-DLP):" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "پس از اتمام اجرای ، برای ادامه ... هر کلید را فشار دهید ..." ;;
			8)
				send_stats "دانلود MP3"
				read -e -p "لطفا لینک ویدیویی را وارد کنید:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "بارگیری صوتی به پایان رسیده است ، برای ادامه ... هر کلید را فشار دهید ..." ;;

			9)
				send_stats "حذف ویدیو"
				read -e -p "لطفاً نام فیلم حذف را وارد کنید:" rmdir
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



# مشکل قطع DPKG را برطرف کنید
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}به روزرسانی سیستم ...${gl_bai}"
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
		echo "مدیر بسته ناشناخته!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}تمیز کردن سیستم ...${gl_bai}"
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
		echo "حافظه پنهان مدیر بسته را تمیز کنید ..."
		apk cache clean
		echo "ورود به سیستم سیستم ..."
		rm -rf /var/log/*
		echo "حذف حافظه پنهان APK ..."
		rm -rf /var/cache/apk/*
		echo "پرونده های موقت را حذف کنید ..."
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
		echo "ورود به سیستم سیستم ..."
		rm -rf /var/log/*
		echo "پرونده های موقت را حذف کنید ..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "وابستگی های بلااستفاده را پاک کنید ..."
		pkg autoremove -y
		echo "حافظه پنهان مدیر بسته را تمیز کنید ..."
		pkg clean -y
		echo "ورود به سیستم سیستم ..."
		rm -rf /var/log/*
		echo "پرونده های موقت را حذف کنید ..."
		rm -rf /tmp/*

	else
		echo "مدیر بسته ناشناخته!"
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
send_stats "DNS را بهینه کنید"
while true; do
	clear
	echo "آدرس DNS را بهینه کنید"
	echo "------------------------"
	echo "آدرس DNS فعلی"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. بهینه سازی DNS خارجی:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. بهینه سازی DNS داخلی:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. تنظیمات DNS را بصورت دستی ویرایش کنید"
	echo "------------------------"
	echo "0. به منوی قبلی برگردید"
	echo "------------------------"
	read -e -p "لطفا انتخاب خود را وارد کنید:" Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "بهینه سازی DNS خارجی"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "بهینه سازی DNS داخلی"
		;;
	  3)
		install nano
		nano /etc/resolv.conf
		send_stats "پیکربندی DNS را به صورت دستی ویرایش کنید"
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

	# اگر رمزعبور Authentication پیدا شد ، روی بله تنظیم کنید
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# در صورت یافتن pubkeyauthentication روی بله تنظیم شده است
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# اگر نه با رمز عبور و نه با pubkeyauthentication مطابقت ندارد ، مقدار پیش فرض را تنظیم کنید
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # از فایلهای پیکربندی SSH پشتیبان تهیه کنید
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "درگاه SSH به: اصلاح شده است:$new_port"

  sleep 1

}



add_sshkey() {

	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""

	cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys


	ip_address
	echo -e "اطلاعات کلیدی خصوصی تولید شده است. حتماً آن را کپی و ذخیره کنید.${gl_huang}${ipv4_address}_ssh.key${gl_bai}پرونده برای ورود به سیستم SSH آینده"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	echo -e "${gl_lv}ورود به سیستم کلید خصوصی Root فعال شده است ، ورود به سیستم رمز عبور بسته شده است ، اتصال مجدد اثر خواهد داشت${gl_bai}"

}


import_sshkey() {

	read -e -p "لطفاً محتویات کلید عمومی SSH خود را وارد کنید (معمولاً با "SSH-RSA" یا "SSH-ED25519" شروع می شود):" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}خطا: محتوای کلید عمومی وارد نشده است.${gl_bai}"
		return 1
	fi

	echo "$public_key" >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	echo -e "${gl_lv}کلید عمومی با موفقیت وارد شده است ، ورود به سیستم Root Private Key فعال شده است ، ورود به سیستم رمز عبور بسته شده است و اتصال مجدد اثر خواهد داشت${gl_bai}"

}




add_sshpasswd() {

echo "رمز عبور ریشه خود را تنظیم کنید"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ورود به سیستم ریشه تنظیم شده است!${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}نکته:${gl_bai}این ویژگی به کاربر root نیاز دارد تا اجرا شود!" && break_end && kejilion
}



dd_xitong() {
		send_stats "نصب مجدد سیستم"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "نام کاربری اولیه پس از نصب مجدد:${gl_huang}root${gl_bai}رمز عبور اولیه:${gl_huang}LeitboGi0ro${gl_bai}بندر اولیه:${gl_huang}22${gl_bai}"
		  echo -e "برای ادامه ... هر کلید را فشار دهید ..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "نام کاربری اولیه پس از نصب مجدد:${gl_huang}Administrator${gl_bai}رمز عبور اولیه:${gl_huang}Teddysun.com${gl_bai}بندر اولیه:${gl_huang}3389${gl_bai}"
		  echo -e "برای ادامه ... هر کلید را فشار دهید ..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "نام کاربری اولیه پس از نصب مجدد:${gl_huang}root${gl_bai}رمز عبور اولیه:${gl_huang}123@@@${gl_bai}بندر اولیه:${gl_huang}22${gl_bai}"
		  echo -e "برای ادامه ... هر کلید را فشار دهید ..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "نام کاربری اولیه پس از نصب مجدد:${gl_huang}Administrator${gl_bai}رمز عبور اولیه:${gl_huang}123@@@${gl_bai}بندر اولیه:${gl_huang}3389${gl_bai}"
		  echo -e "برای ادامه ... هر کلید را فشار دهید ..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "نصب مجدد سیستم"
			echo "--------------------------------"
			echo -e "${gl_hong}توجه:${gl_bai}نصب مجدد برای از دست دادن تماس خطرناک است و کسانی که نگران هستند باید با احتیاط از آن استفاده کنند. انتظار می رود نصب مجدد 15 دقیقه طول بکشد ، لطفاً از قبل از داده ها نسخه پشتیبان تهیه کنید."
			echo -e "${gl_hui}با تشکر از مولیلاو و BIN456789 برای پشتیبانی از فیلمنامه!${gl_bai} "
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
			echo "29. CentOS 10                 30. CentOS 9"
			echo "------------------------"
			echo "31. Alpine Linux              32. Arch Linux"
			echo "33. Kali Linux                34. openEuler"
			echo "35. OpenSUSE TUMBLEWEED 36"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2022"
			echo "45. Windows Server 2019       46. Windows Server 2016"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. به منوی قبلی برگردید"
			echo "------------------------"
			read -e -p "لطفاً سیستم را برای نصب مجدد انتخاب کنید:" sys_choice
			case "$sys_choice" in
			  1)
				send_stats "نصب مجدد دبیان 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  2)
				send_stats "نصب مجدد دبیان 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  3)
				send_stats "نصب مجدد دبیان 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  4)
				send_stats "نصب مجدد دبیان 9"
				dd_xitong_1
				bash InstallNET.sh -debian 9
				reboot
				exit
				;;
			  11)
				send_stats "Ubuntu 24.04 را دوباره نصب کنید"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "22.04 اوبونتو را دوباره نصب کنید"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "20.04 اوبونتو را دوباره نصب کنید"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "Ubuntu 18.04 را دوباره نصب کنید"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "Rockylinux9 را دوباره نصب کنید"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "Rockylinux8 را دوباره نصب کنید"
				dd_xitong_3
				bash reinstall.sh rocky 8
				reboot
				exit
				;;

			  23)
				send_stats "نصب مجدد alma9"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "نصب مجدد alma8"
				dd_xitong_3
				bash reinstall.sh almalinux 8
				reboot
				exit
				;;

			  25)
				send_stats "اوراکل 9 را دوباره نصب کنید"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "دوباره نصب Oracle8"
				dd_xitong_3
				bash reinstall.sh oracle 8
				reboot
				exit
				;;

			  27)
				send_stats "نصب مجدد fedora41"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "نصب مجدد Fedora40"
				dd_xitong_3
				bash reinstall.sh fedora 40
				reboot
				exit
				;;

			  29)
				send_stats "نصب مجدد Centos10"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "نصب مجدد Centos9"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "نصب مجدد آلپ"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "مجدداً قوس را نصب کنید"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "کالی را دوباره نصب کنید"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "بازگرداندن اوپنولر"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "بازگرداندن OpenSuse"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "بارگیری مجدد گاو پرواز"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;


			  41)
				send_stats "نصب ویندوز 11"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;
			  42)
				dd_xitong_2
				send_stats "ویندوز 10 را دوباره نصب کنید"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;
			  43)
				send_stats "نصب ویندوز 7"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "ویندوز سرور 22 را دوباره نصب کنید"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;
			  45)
				send_stats "ویندوز سرور 19 را دوباره نصب کنید"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;
			  46)
				send_stats "ویندوز سرور 16 را دوباره نصب کنید"
				dd_xitong_2
				bash InstallNET.sh -windows 2016 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "بازوی Windows11 را دوباره نصب کنید"
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
		  send_stats "مدیریت BBRV3"

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
				  echo "شما هسته bbrv3 xanmod را نصب کرده اید"
				  echo "نسخه هسته فعلی:$kernel_version"

				  echo ""
				  echo "مدیریت هسته"
				  echo "------------------------"
				  echo "1. هسته BBRV3 را به روز کنید. هسته BBRV3 را حذف کنید"
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# مرحله 3: یک مخزن اضافه کنید
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "هسته XanMod به روز شده است. بعد از راه اندازی مجدد عمل کنید"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "هسته Xanmod حذف نشده است. بعد از راه اندازی مجدد عمل کنید"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "شتاب BBR3 را تنظیم کنید"
		  echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv14k421x7bs؟t=0.1"
		  echo "------------------------------------------------"
		  echo "فقط از دبیان/اوبونتو پشتیبانی کنید"
		  echo "لطفاً از داده ها نسخه پشتیبان تهیه کنید و BBR3 را برای ارتقاء هسته لینوکس فعال کنید."
		  echo "VPS دارای حافظه 512 متر است ، لطفاً حافظه مجازی 1G را از قبل اضافه کنید تا از تماس تلفنی به دلیل حافظه ناکافی جلوگیری شود!"
		  echo "------------------------------------------------"
		  read -e -p "آیا مطمئناً ادامه خواهید داد؟ (y/n):" choice

		  case "$choice" in
			[Yy])
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "محیط فعلی از آن پشتیبانی نمی کند ، فقط از سیستم های Debian و Ubuntu پشتیبانی می کند"
					break_end
					linux_Settings
				fi
			else
				echo "برای تعیین نوع سیستم عامل امکان پذیر نیست"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# مرحله 3: یک مخزن اضافه کنید
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "هسته XANMOD نصب شده و BBR3 با موفقیت فعال می شود. بعد از راه اندازی مجدد عمل کنید"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "لغو شده"
			  ;;
			*)
			  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
			  ;;
		  esac
		fi

}


elrepo_install() {
	# وارد کردن کلید عمومی Elrepo GPG
	echo "کلید عمومی Elrepo GPG را وارد کنید ..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# نسخه سیستم را تشخیص دهید
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# اطمینان حاصل کنید که ما روی یک سیستم عامل پشتیبانی شده اجرا می کنیم
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "سیستم عامل های پشتیبانی نشده:$os_name"
		break_end
		linux_Settings
	fi
	# اطلاعات سیستم عامل شناسایی شده را چاپ کنید
	echo "سیستم عامل شناسایی شده:$os_name $os_version"
	# پیکربندی انبار الپو مربوطه را مطابق با نسخه سیستم نصب کنید
	if [[ "$os_version" == 8 ]]; then
		echo "تنظیمات مخزن Elrepo (نسخه 8) را نصب کنید ..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "تنظیمات مخزن Elrepo را نصب کنید (نسخه 9) ..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	else
		echo "نسخه های سیستم پشتیبانی نشده:$os_version"
		break_end
		linux_Settings
	fi
	# مخزن هسته Elrepo را فعال کرده و جدیدترین هسته اصلی را نصب کنید
	echo "مخزن هسته Elrepo را فعال کنید و آخرین هسته اصلی را نصب کنید ..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "پیکربندی مخزن Elrepo در آخرین هسته اصلی خط نصب و به روز شده است."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "مدیریت هسته Red Hat"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "شما هسته Elrepo را نصب کرده اید"
				  echo "نسخه هسته فعلی:$kernel_version"

				  echo ""
				  echo "مدیریت هسته"
				  echo "------------------------"
				  echo "1. هسته Elrepo را به روز کنید."
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "هسته Red Hat را به روز کنید"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "هسته Elrepo حذف نشده است. بعد از راه اندازی مجدد عمل کنید"
						send_stats "هسته Red Hat را حذف نصب کنید"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "لطفاً از داده ها نسخه پشتیبان تهیه کنید و هسته لینوکس را برای شما به روز می کند"
		  echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1mh4y1w7qa؟t=529.2"
		  echo "------------------------------------------------"
		  echo "فقط پشتیبانی از توزیع سری Red Hat Centos/Redhat/Alma/Rocky/Oracle"
		  echo "ارتقاء هسته لینوکس می تواند عملکرد و امنیت سیستم را بهبود بخشد. توصیه می شود در صورت اجازه و ارتقاء محیط تولید با احتیاط ، آن را امتحان کنید!"
		  echo "------------------------------------------------"
		  read -e -p "آیا مطمئناً ادامه خواهید داد؟ (y/n):" choice

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
			  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
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
		echo "لطفاً دایرکتوری را برای اسکن مشخص کنید."
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

	echo -e "${gl_lv}$@ اسکن تکمیل شده است ، گزارش ویروس ذخیره می شود${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}如果有病毒请在${gl_huang}scan.log${gl_lv}文件中搜索FOUND关键字确认病毒位置 ${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "病毒扫描管理"
		  while true; do
				clear
				echo "ابزار اسکن ویروس Clamav"
				echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1tqvze4eqm؟t=0.1"
				echo "------------------------"
				echo "این یک ابزار نرم افزاری آنتی ویروس منبع باز است که عمدتاً برای تشخیص و حذف انواع بدافزار مورد استفاده قرار می گیرد."
				echo "از جمله ویروس ها ، اسب های تروجان ، جاسوس ، اسکریپت های مخرب و سایر نرم افزارهای مضر."
				echo "------------------------"
				echo -e "${gl_lv}1 اسکن کامل دیسک${gl_bai}             ${gl_huang}2. فهرست مهم را اسکن کنید${gl_bai}            ${gl_kjlan}3. اسکن دایرکتوری سفارشی${gl_bai}"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
				case $sub_choice in
					1)
					  send_stats "اسکن دیسک کامل"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "اسکن دایرکتوری مهم"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "اسکن دایرکتوری سفارشی"
					  read -e -p "لطفاً برای اسکن ، جدا شده توسط فضاها (به عنوان مثال: /etc /var /usr /home /root) دایرکتوری را وارد کنید:" directories
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




# عملکرد بهینه سازی حالت با کارایی بالا
optimize_high_performance() {
	echo -e "${gl_lv}روی دادن${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}توصیف کننده های پرونده را بهینه کنید ...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}بهینه سازی حافظه مجازی ...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}تنظیمات شبکه را بهینه کنید ...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت حافظه پنهان ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}تنظیمات CPU را بهینه کنید ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر ...${gl_bai}"
	# برای کاهش تأخیر صفحات بزرگ را غیرفعال کنید
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# تعادل Numa را غیرفعال کنید
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# عملکرد بهینه سازی حالت تساوی
optimize_balanced() {
	echo -e "${gl_lv}تغییر به حالت تساوی ...${gl_bai}"

	echo -e "${gl_lv}توصیف کننده های پرونده را بهینه کنید ...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}بهینه سازی حافظه مجازی ...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}تنظیمات شبکه را بهینه کنید ...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت حافظه پنهان ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}تنظیمات CPU را بهینه کنید ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر ...${gl_bai}"
	# صفحه شفاف را بازیابی کنید
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# تعادل Numa را بازیابی کنید
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# عملکرد تنظیمات پیش فرض را بازیابی کنید
restore_defaults() {
	echo -e "${gl_lv}به تنظیمات پیش فرض بازگردید ...${gl_bai}"

	echo -e "${gl_lv}بازگرداندن توصیف کننده پرونده ...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}بازیابی حافظه مجازی ...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}بازگرداندن تنظیمات شبکه ...${gl_bai}"
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

	echo -e "${gl_lv}بازگرداندن مدیریت حافظه پنهان ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}تنظیمات CPU را بازیابی کنید ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر را بازیابی کنید ...${gl_bai}"
	# صفحه شفاف را بازیابی کنید
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# تعادل Numa را بازیابی کنید
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# عملکرد بهینه سازی ساختمان وب سایت
optimize_web_server() {
	echo -e "${gl_lv}به حالت بهینه سازی ساختمان وب سایت بروید ...${gl_bai}"

	echo -e "${gl_lv}توصیف کننده های پرونده را بهینه کنید ...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}بهینه سازی حافظه مجازی ...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}تنظیمات شبکه را بهینه کنید ...${gl_bai}"
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

	echo -e "${gl_lv}بهینه سازی مدیریت حافظه پنهان ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}تنظیمات CPU را بهینه کنید ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}بهینه سازی های دیگر ...${gl_bai}"
	# برای کاهش تأخیر صفحات بزرگ را غیرفعال کنید
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# تعادل Numa را غیرفعال کنید
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "مدیریت تنظیم هسته لینوکس"
	  echo "بهینه سازی پارامترهای هسته در سیستم لینوکس"
	  echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1kb421j7yg؟t=0.1"
	  echo "------------------------------------------------"
	  echo "انواع مختلفی از حالت های تنظیم پارامتر سیستم ارائه شده است و کاربران می توانند مطابق سناریوهای استفاده خودشان انتخاب و تغییر کنند."
	  echo -e "${gl_huang}نکته:${gl_bai}لطفاً از آن با احتیاط در محیط تولید استفاده کنید!"
	  echo "--------------------"
	  echo "1. حالت بهینه سازی با کارایی بالا: عملکرد سیستم را به حداکثر برساند و توصیف کننده های فایل ، حافظه مجازی ، تنظیمات شبکه ، مدیریت حافظه نهان و تنظیمات CPU را بهینه کنید."
	  echo "2. حالت بهینه سازی متعادل: تعادل بین عملکرد و مصرف منابع ، مناسب برای استفاده روزانه."
	  echo "3. حالت بهینه سازی وب سایت: برای بهبود قابلیت های پردازش اتصال همزمان ، سرعت پاسخ و عملکرد کلی ، برای سرور وب سایت بهینه سازی کنید."
	  echo "4. حالت بهینه سازی پخش زنده: برای کاهش تأخیر و بهبود عملکرد انتقال ، نیازهای ویژه جریان پخش زنده را بهینه کنید."
	  echo "5. حالت بهینه سازی سرور بازی: برای بهبود قابلیت های پردازش همزمان و سرعت پاسخ ، برای سرورهای بازی بهینه سازی کنید."
	  echo "6. تنظیمات پیش فرض را بازیابی کنید: تنظیمات سیستم را به پیکربندی پیش فرض بازیابی کنید."
	  echo "--------------------"
	  echo "0. به منوی قبلی برگردید"
	  echo "--------------------"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "بهینه سازی حالت با کارایی بالا"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "بهینه سازی حالت متعادل"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "مدل بهینه سازی وب سایت"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "بهینه سازی جریان مستقیم"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "بهینه سازی سرور بازی"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "تنظیمات پیش فرض را بازیابی کنید"
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
				echo -e "${gl_lv}زبان سیستم به:$langاتصال مجدد SSH عملی می شود.${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}زبان سیستم به:$langاتصال مجدد SSH عملی می شود.${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "سیستم های پشتیبانی نشده:$ID"
				break_end
				;;
		esac
	else
		echo "سیستم های پشتیبانی نشده ، نوع سیستم قابل تشخیص نیست."
		break_end
	fi
}




linux_language() {
root_use
send_stats "سوئیچ زبان سیستم"
while true; do
  clear
  echo "زبان فعلی سیستم:$LANG"
  echo "------------------------"
  echo "1. انگلیسی 2. ساده چینی 3. چینی سنتی"
  echo "------------------------"
  echo "0. به منوی قبلی برگردید"
  echo "------------------------"
  read -e -p "انتخاب خود را وارد کنید:" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "تغییر به انگلیسی"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "تغییر به چینی ساده شده"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "به چینی سنتی بروید"
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
echo -e "${gl_lv}تغییر تکمیل شده است SSH را دوباره وصل کنید تا تغییرات را مشاهده کنید!${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "ابزار زیباسازی خط فرمان"
  while true; do
	clear
	echo "ابزار زیباسازی خط فرمان"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. به منوی قبلی برگردید"
	echo "------------------------"
	read -e -p "انتخاب خود را وارد کنید:" choice

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
  send_stats "ایستگاه بازیافت سیستم"

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
	echo -e "سطل بازیافت فعلی${trash_status}"
	echo -e "پس از فعال کردن ، پرونده های حذف شده توسط RM ابتدا وارد سطل بازیافت می شوند تا از حذف اشتباه پرونده های مهم جلوگیری شود!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "سطل بازیافت خالی است"
	echo "------------------------"
	echo "1. سطل بازیافت را فعال کنید. سطل بازیافت را ببندید"
	echo "3. بازیابی مطالب 4. سطل بازیافت را پاک کنید"
	echo "------------------------"
	echo "0. به منوی قبلی برگردید"
	echo "------------------------"
	read -e -p "انتخاب خود را وارد کنید:" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "سطل بازیافت فعال شده و پرونده های حذف شده به سطل بازیافت منتقل می شوند."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "سطل بازیافت بسته است و پرونده مستقیماً حذف می شود."
		sleep 2
		;;
	  3)
		read -e -p "برای بازیابی نام پرونده را وارد کنید:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restoreبه فهرست خانه بازگردانده شد."
		else
		  echo "پرونده وجود ندارد"
		fi
		;;
	  4)
		read -e -p "تأیید سطل بازیافت را تأیید کنید؟ [y/n]:" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "سطل بازیافت پاک شده است."
		fi
		;;
	  *)
		break
		;;
	esac
  done
}



# تهیه نسخه پشتیبان
create_backup() {
	send_stats "تهیه نسخه پشتیبان"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# کاربر را وادار به وارد کردن فهرست پشتیبان کنید
	echo "یک مثال پشتیبان ایجاد کنید:"
	echo "- از یک دایرکتوری واحد نسخه پشتیبان تهیه کنید: /var /www"
	echo "- پشتیبان گیری از دایرکتوری های متعدد: /etc /home /var /log"
	echo "- Enter Enter از دایرکتوری پیش فرض ( /etc /usr /home) استفاده می کند"
	read -r -p "لطفاً برای تهیه نسخه پشتیبان از دایرکتوری وارد کنید (چندین دایرکتوری توسط فضاها از هم جدا می شوند و اگر مستقیماً وارد شوید ، از فهرست پیش فرض استفاده کنید):" input

	# اگر کاربر دایرکتوری را وارد نکرد ، از فهرست پیش فرض استفاده کنید
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# دایرکتوری را که توسط کاربر وارد شده است در یک آرایه توسط فضاها جدا کنید
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# پیشوند پرونده پشتیبان تهیه کنید
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# نام دایرکتوری را استخراج کنید و برش ها را حذف کنید
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# آخرین زیر را حذف کنید
	local PREFIX=${PREFIX%_}

	# نام پرونده پشتیبان تهیه کنید
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# دایرکتوری را که توسط کاربر انتخاب شده است چاپ کنید
	echo "دایرکتوری پشتیبان که شما انتخاب کردید:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# تهیه نسخه پشتیبان
	echo "ایجاد یک نسخه پشتیبان$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# بررسی کنید که آیا دستور موفقیت آمیز است
	if [ $? -eq 0 ]; then
		echo "نسخه پشتیبان با موفقیت ایجاد شد:$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "ایجاد پشتیبان گیری نشد!"
		exit 1
	fi
}

# بازیابی پشتیبان گیری
restore_backup() {
	send_stats "بازیابی پشتیبان گیری"
	# پشتیبان مورد نظر برای بازیابی را انتخاب کنید
	read -e -p "لطفاً نام پرونده پشتیبان را برای بازیابی وارد کنید:" BACKUP_NAME

	# بررسی کنید که آیا پرونده پشتیبان وجود دارد
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "پرونده پشتیبان وجود ندارد!"
		exit 1
	fi

	echo "بازیابی پشتیبان گیری$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "پشتیبان گیری و بازیابی با موفقیت!"
	else
		echo "بازیابی پشتیبان گیری نشد!"
		exit 1
	fi
}

# تهیه نسخه پشتیبان
list_backups() {
	echo "نسخه پشتیبان تهیه شده در دسترس:"
	ls -1 "$BACKUP_DIR"
}

# تهیه نسخه پشتیبان
delete_backup() {
	send_stats "تهیه نسخه پشتیبان"

	read -e -p "لطفاً نام پرونده پشتیبان را وارد کنید تا حذف شود:" BACKUP_NAME

	# بررسی کنید که آیا پرونده پشتیبان وجود دارد
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "پرونده پشتیبان وجود ندارد!"
		exit 1
	fi

	# تهیه نسخه پشتیبان
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "نسخه پشتیبان با موفقیت حذف شد!"
	else
		echo "حذف پشتیبان انجام نشد!"
		exit 1
	fi
}

# منوی اصلی تهیه نسخه پشتیبان
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "عملکرد پشتیبان گیری سیستم"
		echo "عملکرد پشتیبان گیری سیستم"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. یک نسخه پشتیبان تهیه کنید. بازیابی پشتیبان 3 را بازیابی کنید. نسخه پشتیبان را حذف کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "برای ادامه ... Enter را فشار دهید ..."
	done
}









# نمایش لیست اتصال
list_connections() {
	echo "اتصال ذخیره شده:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# یک اتصال جدید اضافه کنید
add_connection() {
	send_stats "یک اتصال جدید اضافه کنید"
	echo "مثال برای ایجاد یک اتصال جدید:"
	echo "- نام اتصال: my_server"
	echo "- آدرس IP: 192.168.1.100"
	echo "- نام کاربری: ریشه"
	echo "- بندر: 22"
	echo "------------------------"
	read -e -p "لطفاً نام اتصال را وارد کنید:" name
	read -e -p "لطفا آدرس IP خود را وارد کنید:" ip
	read -e -p "لطفاً نام کاربری (پیش فرض: ریشه) را وارد کنید:" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "لطفاً شماره پورت را وارد کنید (پیش فرض: 22):" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "لطفاً روش احراز هویت را انتخاب کنید:"
	echo "1. رمز عبور"
	echo "2. کلید"
	read -e -p "لطفاً انتخاب را وارد کنید (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "لطفا رمز ورود خود را وارد کنید:" password_or_key
			echo  # 换行
			;;
		2)
			echo "لطفاً محتوای کلیدی را بچسبانید (بعد از چسباندن دو بار فشار دهید) را فشار دهید:"
			local password_or_key=""
			while IFS= read -r line; do
				# اگر ورودی خالی باشد و محتوای کلیدی در حال حاضر حاوی آغاز باشد ، ورودی به پایان می رسد
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# اگر خط اول است یا محتوای کلید وارد شده است ، به اضافه کردن ادامه دهید
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# بررسی کنید که آیا این محتوای کلیدی است
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "انتخاب نامعتبر!"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "اتصال ذخیره می شود!"
}



# اتصال را حذف کنید
delete_connection() {
	send_stats "اتصال را حذف کنید"
	read -e -p "لطفاً شماره اتصال را وارد کنید تا حذف شود:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "خطا: اتصال مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# اگر اتصال از یک فایل کلید استفاده می کند ، پرونده کلید را حذف کنید
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "اتصال حذف شده است!"
}

# از اتصال استفاده کنید
use_connection() {
	send_stats "از اتصال استفاده کنید"
	read -e -p "لطفاً شماره اتصال را برای استفاده وارد کنید:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "خطا: اتصال مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "اتصال به$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# با یک کلید ارتباط برقرار کنید
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال شکست خورد! لطفا موارد زیر را بررسی کنید:"
			echo "1. آیا مسیر فایل کلید صحیح است؟$password_or_key"
			echo "2. آیا مجوزهای پرونده کلیدی صحیح است (باید 600 باشد)."
			echo "3. آیا سرور هدف اجازه ورود به سیستم را با استفاده از کلید می دهد."
		fi
	else
		# با یک رمز عبور ارتباط برقرار کنید
		if ! command -v sshpass &> /dev/null; then
			echo "خطا: SShpass نصب نشده است ، لطفاً ابتدا SSHPASS را نصب کنید."
			echo "روش نصب:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "اتصال شکست خورد! لطفا موارد زیر را بررسی کنید:"
			echo "1. آیا نام کاربری و رمز عبور صحیح است."
			echo "2. آیا سرور هدف اجازه ورود به رمز عبور را می دهد."
			echo "3. آیا سرویس SSH سرور هدف به طور عادی در حال اجرا است."
		fi
	fi
}


ssh_manager() {
	send_stats "ابزار اتصال از راه دور SSH"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# بررسی کنید که آیا پرونده پیکربندی و فهرست کلید وجود دارد و آیا وجود ندارد ، آن را ایجاد کنید
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "ابزار اتصال از راه دور SSH"
		echo "از طریق SSH می تواند به سایر سیستم های لینوکس متصل شود"
		echo "------------------------"
		list_connections
		echo "1. یک اتصال جدید ایجاد کنید. از یک اتصال استفاده کنید 3. یک اتصال را حذف کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "انتخاب نامعتبر ، لطفاً دوباره امتحان کنید." ;;
		esac
	done
}












# لیست پارتیشن های دیسک سخت موجود
list_partitions() {
	echo "پارتیشن های دیسک سخت موجود:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# پارتیشن را سوار کنید
mount_partition() {
	send_stats "پارتیشن را سوار کنید"
	read -e -p "لطفاً نام پارتیشن را برای نصب وارد کنید (به عنوان مثال SDA1):" PARTITION

	# بررسی کنید که آیا پارتیشن وجود دارد
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# بررسی کنید که آیا پارتیشن از قبل نصب شده است
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "پارتیشن از قبل نصب شده است!"
		return
	fi

	# یک نقطه کوه ایجاد کنید
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# پارتیشن را سوار کنید
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "پارتیشن با موفقیت:$MOUNT_POINT"
	else
		echo "پارتیشن کوه شکست خورد!"
		rmdir "$MOUNT_POINT"
	fi
}

# پارتیشن را حذف نصب کنید
unmount_partition() {
	send_stats "پارتیشن را حذف نصب کنید"
	read -e -p "لطفاً نام پارتیشن را وارد کنید (به عنوان مثال SDA1):" PARTITION

	# بررسی کنید که آیا پارتیشن از قبل نصب شده است
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "پارتیشن نصب نشده است!"
		return
	fi

	# پارتیشن را حذف نصب کنید
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "حذف پارتیشن با موفقیت:$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "حذف پارتیشن انجام نشد!"
	fi
}

# لیست پارتیشن های نصب شده
list_mounted_partitions() {
	echo "پارتیشن نصب شده:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# پارتیشن فرمت
format_partition() {
	send_stats "پارتیشن فرمت"
	read -e -p "لطفاً نام پارتیشن را به قالب وارد کنید (به عنوان مثال SDA1):" PARTITION

	# بررسی کنید که آیا پارتیشن وجود دارد
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# بررسی کنید که آیا پارتیشن از قبل نصب شده است
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "پارتیشن نصب شده است ، لطفاً ابتدا آن را حذف کنید!"
		return
	fi

	# نوع سیستم فایل را انتخاب کنید
	echo "لطفاً نوع سیستم فایل را انتخاب کنید:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "لطفا انتخاب خود را وارد کنید:" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "انتخاب نامعتبر!"; return ;;
	esac

	# تأیید قالب بندی
	read -e -p "تأیید قالب بندی پارتیشن /dev /$PARTITIONبرای$FS_TYPEاین است؟ (y/n):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "این عملیات لغو شده است."
		return
	fi

	# پارتیشن فرمت
	echo "قالب بندی پارتیشن /dev /$PARTITIONبرای$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "قالب پارتیشن موفقیت آمیز بود!"
	else
		echo "قالب بندی پارتیشن شکست خورد!"
	fi
}

# وضعیت پارتیشن را بررسی کنید
check_partition() {
	send_stats "وضعیت پارتیشن را بررسی کنید"
	read -e -p "لطفاً نام پارتیشن را برای بررسی وارد کنید (به عنوان مثال SDA1):" PARTITION

	# بررسی کنید که آیا پارتیشن وجود دارد
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "پارتیشن وجود ندارد!"
		return
	fi

	# وضعیت پارتیشن را بررسی کنید
	echo "پارتیشن /dev /را بررسی کنید$PARTITIONوضعیت:"
	fsck "/dev/$PARTITION"
}

# منوی اصلی
disk_manager() {
	send_stats "عملکرد مدیریت دیسک سخت"
	while true; do
		clear
		echo "مدیریت پارتیشن دیسک سخت"
		echo -e "${gl_huang}این عملکرد در داخل دوره آزمایش آزمایش می شود ، لطفاً از آن در محیط تولید استفاده نکنید.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. پارتیشن را سوار کنید. پارتیشن را حذف کنید. نمایش پارتیشن نصب شده"
		echo "4. پارتیشن 5 را قالب بندی کنید. وضعیت پارتیشن را بررسی کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "برای ادامه ... Enter را فشار دهید ..."
	done
}




# لیست کار را نشان دهید
list_tasks() {
	echo "وظایف همگام سازی ذخیره شده:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# یک کار جدید اضافه کنید
add_task() {
	send_stats "یک کار همگام سازی جدید اضافه کنید"
	echo "یک مثال کار همگام سازی جدید ایجاد کنید:"
	echo "- نام کار: backup_www"
	echo "- دایرکتوری محلی: /var /www"
	echo "- آدرس از راه دور: user@192.168.1.100"
	echo "- دایرکتوری از راه دور: /پشتیبان /www"
	echo "- شماره پورت (پیش فرض 22)"
	echo "---------------------------------"
	read -e -p "لطفاً نام کار را وارد کنید:" name
	read -e -p "لطفا وارد فهرست محلی شوید:" local_path
	read -e -p "لطفاً فهرست راه دور را وارد کنید:" remote_path
	read -e -p "لطفاً کاربر از راه دور IP را وارد کنید:" remote
	read -e -p "لطفاً درگاه SSH را وارد کنید (پیش فرض 22):" port
	port=${port:-22}

	echo "لطفاً روش احراز هویت را انتخاب کنید:"
	echo "1. رمز عبور"
	echo "2. کلید"
	read -e -p "لطفاً (1/2) را انتخاب کنید:" auth_choice

	case $auth_choice in
		1)
			read -s -p "لطفا رمز ورود خود را وارد کنید:" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "لطفاً محتوای کلیدی را بچسبانید (بعد از چسباندن دو بار فشار دهید) را فشار دهید:"
			local password_or_key=""
			while IFS= read -r line; do
				# اگر ورودی خالی باشد و محتوای کلیدی در حال حاضر حاوی آغاز باشد ، ورودی به پایان می رسد
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# اگر خط اول است یا محتوای کلید وارد شده است ، به اضافه کردن ادامه دهید
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# بررسی کنید که آیا این محتوای کلیدی است
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "محتوای کلیدی نامعتبر!"
				return
			fi
			;;
		*)
			echo "انتخاب نامعتبر!"
			return
			;;
	esac

	echo "لطفاً حالت همگام سازی را انتخاب کنید:"
	echo "1. حالت استاندارد (-AVZ)"
	echo "2. پرونده هدف را حذف کنید (-avz-delete)"
	read -e -p "لطفاً (1/2) را انتخاب کنید:" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "انتخاب نامعتبر ، از پیش فرض -avz استفاده کنید"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "کار ذخیره شد!"
}

# یک کار را حذف کنید
delete_task() {
	send_stats "کارهای همگام سازی را حذف کنید"
	read -e -p "لطفاً شماره کار را وارد کنید تا حذف شود:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "خطا: کار مربوطه یافت نشد."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# اگر کار از یک فایل کلید استفاده می کند ، پرونده کلید را حذف کنید
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "کار حذف شد!"
}


run_task() {
	send_stats "انجام کارهای هماهنگ سازی"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# پارامترها را تجزیه و تحلیل کنید
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# اگر شماره کار ورودی وجود ندارد ، کاربر را مجبور به ورود کنید
	if [[ -z "$num" ]]; then
		read -e -p "لطفاً شماره کار را برای اجرای آن وارد کنید:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "خطا: کار یافت نشد!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# منبع و مسیر هدف را مطابق با جهت همگام سازی تنظیم کنید
	if [[ "$direction" == "pull" ]]; then
		echo "کشیدن هماهنگ سازی به محلی:$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "همگام سازی را به انتهای از راه دور فشار دهید:$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# پارامترهای مشترک اتصال SSH را اضافه کنید
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "خطا: SShpass نصب نشده است ، لطفاً ابتدا SSHPASS را نصب کنید."
			echo "روش نصب:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# بررسی کنید که آیا پرونده اصلی وجود دارد و آیا مجوزها صحیح هستند
		if [[ ! -f "$password_or_key" ]]; then
			echo "خطا: پرونده کلیدی وجود ندارد:$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "هشدار: مجوزهای کلیدی پرونده نادرست است و تعمیر می شوند ..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "هماهنگ سازی کامل است!"
	else
		echo "هماهنگ سازی شکست خورد! لطفا موارد زیر را بررسی کنید:"
		echo "1. آیا اتصال شبکه طبیعی است؟"
		echo "2. آیا میزبان از راه دور در دسترس است؟"
		echo "3. آیا اطلاعات احراز هویت صحیح است؟"
		echo "4. آیا دایرکتوری های محلی و از راه دور مجوزهای دسترسی صحیح دارند"
	fi
}


# یک کار به موقع ایجاد کنید
schedule_task() {
	send_stats "کارهای زمان بندی همگام سازی را اضافه کنید"

	read -e -p "لطفاً شماره کار را وارد کنید تا مرتباً هماهنگ شود:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً یک شماره کار معتبر وارد کنید!"
		return
	fi

	echo "لطفاً فاصله اجرای به موقع را انتخاب کنید:"
	echo "1) یک بار در ساعت اجرا کنید"
	echo "2) یک بار در روز اجرا کنید"
	echo "3) هفته ای یک بار اجرا کنید"
	read -e -p "لطفاً گزینه ها را وارد کنید (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "خطا: لطفاً یک گزینه معتبر وارد کنید!" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# بررسی کنید که آیا همان کار قبلاً وجود دارد
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "خطا: همگام سازی زمان این کار از قبل وجود دارد!"
		return
	fi

	# یک crontab برای کاربر ایجاد کنید
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "کار زمان بندی ایجاد شده است:$cron_job"
}

# مشاهده وظایف برنامه ریزی شده
view_tasks() {
	echo "کارهای زمان بندی فعلی:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# کارهای زمان بندی را حذف کنید
delete_task_schedule() {
	send_stats "وظایف زمان بندی همگام سازی را حذف کنید"
	read -e -p "لطفاً شماره کار را وارد کنید تا حذف شود:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "خطا: لطفاً یک شماره کار معتبر وارد کنید!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "شماره کار حذف شده$numکارهای زمان بندی"
}


# منوی اصلی مدیریت کار
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "ابزار همگام سازی از راه دور RSYNC"
		echo "هماهنگ سازی بین دایرکتوری های از راه دور از هماهنگ سازی افزایشی ، کارآمد و پایدار پشتیبانی می کند."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. ایجاد یک کار جدید 2. یک کار را حذف کنید"
		echo "3. هماهنگ سازی محلی را در انتهای از راه دور انجام دهید. هماهنگ سازی از راه دور را به انتهای محلی انجام دهید"
		echo "5. یک کار زمان بندی ایجاد کنید 6. یک کار زمان بندی را حذف کنید"
		echo "---------------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "---------------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "انتخاب نامعتبر ، لطفاً دوباره امتحان کنید." ;;
		esac
		read -e -p "برای ادامه ... Enter را فشار دهید ..."
	done
}









linux_ps() {

	clear
	send_stats "پرس و جو اطلاعاتی سیستم"

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
	echo -e "پرس و جو اطلاعاتی سیستم"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}نام میزبان:${gl_bai}$hostname"
	echo -e "${gl_kjlan}نسخه سیستم:${gl_bai}$os_info"
	echo -e "${gl_kjlan}نسخه لینوکس:${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}معماری CPU:${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}مدل CPU:${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}تعداد هسته های CPU:${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}فرکانس CPU:${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}اشغال CPU:${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}بار سیستم:${gl_bai}$load"
	echo -e "${gl_kjlan}حافظه فیزیکی:${gl_bai}$mem_info"
	echo -e "${gl_kjlan}حافظه مجازی:${gl_bai}$swap_info"
	echo -e "${gl_kjlan}اشغال دیسک سخت:${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}$output"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}الگوریتم شبکه:${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}اپراتور:${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}آدرس IPv4:${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}آدرس IPv6:${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}آدرس DNS:${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}موقعیت جغرافیایی:${gl_bai}$country $city"
	echo -e "${gl_kjlan}زمان سیستم:${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}زمان اجرا:${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "ابزارهای اساسی"
	  echo -e "ابزارهای اساسی"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ابزار دانلود فرفری${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}ابزار بارگیری Wget${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ابزار مجوز مدیریت فوق العاده سودو${gl_kjlan}4.   ${gl_bai}ابزار ارتباط ارتباطی SOCAT"
	  echo -e "${gl_kjlan}5.   ${gl_bai}ابزار نظارت بر سیستم HTOP${gl_kjlan}6.   ${gl_bai}ابزار نظارت بر ترافیک شبکه IFTOP"
	  echo -e "${gl_kjlan}7.   ${gl_bai}ابزار فشرده سازی فشرده سازی زیپ از حالت فشرده${gl_kjlan}8.   ${gl_bai}ابزار فشرده سازی فشرده سازی TAR GZ"
	  echo -e "${gl_kjlan}9.   ${gl_bai}ابزار اجرای پس زمینه چند کانال Tmux${gl_kjlan}10.  ${gl_bai}FFMPEG ویدیوی رمزگذاری ابزار پخش مستقیم"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}ابزارهای نظارت مدرن BTOP${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}ابزار مدیریت پرونده"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ابزار مشاهده اشغال دیسک NCDU${gl_kjlan}14.  ${gl_bai}ابزار جستجوی جهانی FZF"
	  echo -e "${gl_kjlan}15.  ${gl_bai}ویرایشگر متن VIM${gl_kjlan}16.  ${gl_bai}ویرایشگر متن نانو${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}سیستم کنترل نسخه GIT"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}ضمانت صفحه ماتریس${gl_kjlan}22.  ${gl_bai}امنیت صفحه نمایش"
	  echo -e "${gl_kjlan}26.  ${gl_bai}بازی تتریس${gl_kjlan}27.  ${gl_bai}بازی خوردن مار"
	  echo -e "${gl_kjlan}28.  ${gl_bai}بازی مهاجم فضا"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}همه را نصب کنید${gl_kjlan}32.  ${gl_bai}همه نصب ها (به استثنای ذخیره کننده های صفحه نمایش و بازی)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}حذف همه"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}ابزار مشخص شده را نصب کنید${gl_kjlan}42.  ${gl_bai}ابزار مشخص شده را حذف کنید"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  curl --help
			  send_stats "پیچ را نصب کنید"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  wget --help
			  send_stats "نصب wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  sudo --help
			  send_stats "sudo را نصب کنید"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  socat -h
			  send_stats "SOCAT را نصب کنید"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "HTOP را نصب کنید"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "iftop را نصب کنید"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  unzip
			  send_stats "anzip را نصب کنید"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  tar --help
			  send_stats "تار نصب"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  tmux --help
			  send_stats "نصب tmux"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "این ابزار نصب شده است و روش استفاده به شرح زیر است:"
			  ffmpeg --help
			  send_stats "نصب ffmpeg"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "BTOP را نصب کنید"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "Ranger را نصب کنید"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "NCDU را نصب کنید"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "FZF را نصب کنید"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "نصب ویم"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "نانو را نصب کنید"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "git را نصب کنید"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "نصب cmatrix"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "نصب SL"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "باست را نصب کنید"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "nsnake را نصب کنید"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "ninvaders را نصب کنید"
			  ;;

		  31)
			  clear
			  send_stats "همه را نصب کنید"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "نصب همه (به استثنای بازی ها و ذخیره های صفحه نمایش)"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "حذف همه"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "لطفاً نام ابزار نصب شده را وارد کنید (wget curl sudo htop):" installname
			  install $installname
			  send_stats "نرم افزار مشخص شده را نصب کنید"
			  ;;
		  42)
			  clear
			  read -e -p "لطفاً نام ابزار حذف شده را وارد کنید (HTOP UFW TMUX CMATRIX):" removename
			  remove $removename
			  send_stats "نرم افزار مشخص شده را حذف کنید"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "ورودی نامعتبر!"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "مدیریت BBR"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			  echo "الگوریتم مسدود کننده TCP فعلی:$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "مدیریت BBR"
			  echo "------------------------"
			  echo "1. BBRV3 را روشن کنید. BBRV3 را خاموش کنید (راه اندازی مجدد)"
			  echo "------------------------"
			  echo "0. به منوی قبلی برگردید"
			  echo "------------------------"
			  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "Alpine BBR3 را فعال کنید"
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
	  # Send_stats "مدیریت داکر"
	  echo -e "مدیریت داکر"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}محیط داکر را نصب و به روز کنید${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}مشاهده وضعیت جهانی Docker${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}مدیریت کانتینر داکر${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}مدیریت تصویر داکر"
	  echo -e "${gl_kjlan}5.   ${gl_bai}مدیریت شبکه داکر"
	  echo -e "${gl_kjlan}6.   ${gl_bai}مدیریت حجم داکر"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}ظروف داکر بی فایده و حجم داده های شبکه آینه را تمیز کنید"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}منبع Docker را جایگزین کنید"
	  echo -e "${gl_kjlan}9.   ${gl_bai}پرونده daemon.json را ویرایش کنید"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}دسترسی Docker-IPV6 را فعال کنید"
	  echo -e "${gl_kjlan}12.  ${gl_bai}دسترسی نزدیک Docker-IPV6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}20.  ${gl_bai}محیط داکر را حذف کنید"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "محیط داکر را نصب کنید"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "داکر وضعیت جهانی"
			  echo "نسخه داکر"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "تصویر داکر:${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "ظرف داکر:${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "حجم داکر:${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "شبکه داکر:${gl_lv}$network_count${gl_bai}"
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
				  send_stats "مدیریت شبکه داکر"
				  echo "لیست شبکه داکر"
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
				  echo "شبکه"
				  echo "------------------------"
				  echo "1. ایجاد یک شبکه"
				  echo "2. به اینترنت بپیوندید"
				  echo "3. از شبکه خارج شوید"
				  echo "4. شبکه را حذف کنید"
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "ایجاد یک شبکه"
						  read -e -p "یک نام شبکه جدید تنظیم کنید:" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "به اینترنت بپیوندید"
						  read -e -p "به نام شبکه بپیوندید:" dockernetwork
						  read -e -p "این ظروف به شبکه اضافه می شوند (نام های چند ظرف توسط فضاها از هم جدا می شوند):" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "به اینترنت بپیوندید"
						  read -e -p "نام شبکه خروجی:" dockernetwork
						  read -e -p "این ظروف از شبکه خارج می شوند (نام های چند ظرف توسط فضاها از هم جدا می شوند):" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "شبکه را حذف کنید"
						  read -e -p "لطفاً نام شبکه را وارد کنید تا حذف شود:" dockernetwork
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
				  send_stats "مدیریت حجم داکر"
				  echo "لیست حجم داکر"
				  docker volume ls
				  echo ""
				  echo "عملیات حجم"
				  echo "------------------------"
				  echo "1. یک جلد جدید ایجاد کنید"
				  echo "2. حجم مشخص شده را حذف کنید"
				  echo "3. همه جلد ها را حذف کنید"
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "یک جلد جدید ایجاد کنید"
						  read -e -p "نام جلد جدید را تنظیم کنید:" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "نام حجم حذف را وارد کنید (لطفاً چندین نام حجم را با فضاها جدا کنید):" dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "همه حجم ها را حذف کنید"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
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
			  send_stats "تمیز کردن داکر"
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "منبع"
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
			  send_stats "Docker V6 باز است"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker V6 سطح"
			  docker_ipv6_off
			  ;;

		  20)
			  clear
			  send_stats "داکر حذف نصب"
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
				  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "ورودی نامعتبر!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "مجموعه اسکریپت تست"
	  echo -e "مجموعه اسکریپت تست"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}تشخیص وضعیت IP و باز کردن وضعیت"
	  echo -e "${gl_kjlan}1.   ${gl_bai}تشخیص وضعیت قفل chatgpt"
	  echo -e "${gl_kjlan}2.   ${gl_bai}تست قفل رسانه جریان منطقه"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Yeahwu Streaming Media Detection Ollock"
	  echo -e "${gl_kjlan}4.   ${gl_bai}اسکریپت معاینه فیزیکی با کیفیت IP Xykt${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}اندازه گیری سرعت شبکه"
	  echo -e "${gl_kjlan}11.  ${gl_bai}BestTrace سه تست مسیریابی تأخیر Backhaul Network"
	  echo -e "${gl_kjlan}12.  ${gl_bai}تست خط سه شبکه MTR_TRACE"
	  echo -e "${gl_kjlan}13.  ${gl_bai}اندازه گیری سرعت سه شبکه فوق العاده"
	  echo -e "${gl_kjlan}14.  ${gl_bai}اسکریپت تست Backhaul NxTrace"
	  echo -e "${gl_kjlan}15.  ${gl_bai}NxTrace اسکریپت تست Backhaul IP را مشخص می کند"
	  echo -e "${gl_kjlan}16.  ${gl_bai}آزمون خط سه شبکه Ludashi2020"
	  echo -e "${gl_kjlan}17.  ${gl_bai}اسکریپت تست سرعت چند منظوره I-ABC"
	  echo -e "${gl_kjlan}18.  ${gl_bai}اسکریپت معاینه فیزیکی با کیفیت شبکه NetQuality${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}تست عملکرد سخت افزار"
	  echo -e "${gl_kjlan}21.  ${gl_bai}تست عملکرد YABS"
	  echo -e "${gl_kjlan}22.  ${gl_bai}اسکریپت تست عملکرد CPU IICU/GB5"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}تست جامع"
	  echo -e "${gl_kjlan}31.  ${gl_bai}تست عملکرد نیمکت"
	  echo -e "${gl_kjlan}32.  ${gl_bai}بررسی هیولا فیوژن SpiritySDX${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "تشخیص وضعیت قفل chatgpt"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "تست قفل رسانه جریان منطقه"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "Yeahwu Streaming Media Detection Ollock"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "اسکریپت معاینه فیزیکی با کیفیت xykt_ip"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "BestTrace سه تست مسیریابی تأخیر Backhaul Network"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "MTR_TRACE سه تست خط بازگشت شبکه"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "اندازه گیری سرعت سه شبکه فوق العاده"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "اسکریپت تست Backhaul NxTrace"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "NxTrace اسکریپت تست Backhaul IP را مشخص می کند"
			  echo "لیست IP هایی که می توانند ارجاع شوند"
			  echo "------------------------"
			  echo "مخابرات پکن: 219.141.136.12"
			  echo "پکن یونیکوم: 202.106.50.1"
			  echo "موبایل پکن: 221.179.155.161"
			  echo "مخابرات شانگهای: 202.96.209.133"
			  echo "شانگهای یونیکوم: 210.22.97.1"
			  echo "موبایل شانگهای: 211.136.112.200"
			  echo "Telecom Guangzhou: 58.60.188.222"
			  echo "Guangzhou Unicom: 210.21.196.6"
			  echo "موبایل گوانگژو: 120.196.165.24"
			  echo "چنگدو از راه دور: 61.139.2.69"
			  echo "چنگدو یونیکوم: 119.6.6.6"
			  echo "Chengdu Mobile: 211.137.96.205"
			  echo "Hunan Telecom: 36.111.200.100"
			  echo "Hunan Unicom: 42.48.16.100"
			  echo "Hunan Mobile: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "یک IP مشخص را وارد کنید:" testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "آزمون خط سه شبکه Ludashi2020"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "اسکریپت تست سرعت چند منظوره I-ABC"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "اسکریپت تست کیفیت شبکه"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "تست عملکرد YABS"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "اسکریپت تست عملکرد CPU IICU/GB5"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "تست عملکرد نیمکت"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "بررسی هیولا فیوژن SpiritySDX"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "ورودی نامعتبر!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "مجموعه اسکریپت Oracle Cloud"
	  echo -e "مجموعه اسکریپت Oracle Cloud"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}اسکریپت فعال دستگاه بیکار را نصب کنید"
	  echo -e "${gl_kjlan}2.   ${gl_bai}اسکریپت فعال دستگاه بیکار را حذف نصب کنید"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD اسکریپت سیستم را دوباره نصب کنید"
	  echo -e "${gl_kjlan}4.   ${gl_bai}کارآگاه r فیلمنامه را شروع کنید"
	  echo -e "${gl_kjlan}5.   ${gl_bai}حالت ورود به سیستم رمز عبور را روشن کنید"
	  echo -e "${gl_kjlan}6.   ${gl_bai}ابزار بازیابی IPv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "اسکریپت فعال: CPU 10-20 ٪ حافظه 20 ٪ اشغال می کند"
			  read -e -p "آیا مطمئناً آن را نصب می کنید؟ (y/n):" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # مقادیر پیش فرض را تنظیم کنید
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # کاربر را وادار کنید تا تعداد هسته های CPU و درصد اشغال را وارد کند و در صورت ورود ، از مقدار پیش فرض استفاده کنید.
				  read -e -p "لطفاً تعداد هسته های CPU را وارد کنید [پیش فرض:$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "لطفاً محدوده درصد استفاده از CPU را وارد کنید (به عنوان مثال ، 10-20) [پیش فرض:$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "لطفاً درصد استفاده از حافظه را وارد کنید [پیش فرض:$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "لطفاً زمان فاصله زمانی (ثانیه) را وارد کنید [پیش فرض:$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # ظرف داکر را اجرا کنید
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "اسکریپت فعال نصب Oracle Cloud"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "Oracle Cloud اسکریپت فعال را حذف نصب کرد"
			  ;;

		  3)
		  clear
		  echo "نصب مجدد سیستم"
		  echo "--------------------------------"
		  echo -e "${gl_hong}توجه:${gl_bai}نصب مجدد برای از دست دادن تماس خطرناک است و کسانی که نگران هستند باید با احتیاط از آن استفاده کنند. انتظار می رود نصب مجدد 15 دقیقه طول بکشد ، لطفاً از قبل از داده ها نسخه پشتیبان تهیه کنید."
		  read -e -p "آیا مطمئناً ادامه خواهید داد؟ (y/n):" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "لطفاً سیستم را برای نصب مجدد انتخاب کنید: 1. Debian12 | 2. Ubuntu20.04:" sys_choice

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
					echo "انتخاب نامعتبر ، لطفاً دوباره وارد شوید."
					;;
				esac
			  done

			  read -e -p "لطفاً رمز ورود مجدد خود را وارد کنید:" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "Oracle Cloud دوباره نصب اسکریپت سیستم"
			  ;;
			[Nn])
			  echo "لغو شده"
			  ;;
			*)
			  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  echo "این ویژگی در مرحله توسعه است ، بنابراین با ما همراه باشید!"
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "این عملکرد توسط استاد JHB ارائه شده است ، به لطف او!"
			  send_stats "رفع IPv6"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "ورودی نامعتبر!"
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
		echo -e "${gl_lv}محیط نصب شده است${gl_bai}ظرف:${gl_lv}$container_count${gl_bai}آینه:${gl_lv}$image_count${gl_bai}شبکه:${gl_lv}$network_count${gl_bai}رول:${gl_lv}$volume_count${gl_bai}"
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
		echo -e "${gl_lv}محیط نصب شده است${gl_bai}  $output  $db_output"
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
	# SEND_STATS "ساختمان وب سایت LDNMP"
	echo -e "${gl_huang}ساختمان وب سایت LDNMP"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}محیط LDNMP را نصب کنید${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}وردپرس را نصب کنید${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}تالار گفتمان دیسکو را نصب کنید${gl_huang}4.   ${gl_bai}دسک تاپ Kadao Cloud را نصب کنید"
	echo -e "${gl_huang}5.   ${gl_bai}ایستگاه فیلم و تلویزیون Apple CMS را نصب کنید${gl_huang}6.   ${gl_bai}یک شبکه کارت دیجیتال Unicorn نصب کنید"
	echo -e "${gl_huang}7.   ${gl_bai}وب سایت Flarum Forum را نصب کنید${gl_huang}8.   ${gl_bai}وب سایت وبلاگ سبک Typecho را نصب کنید"
	echo -e "${gl_huang}9.   ${gl_bai}بستر لینک مشترک Linkstack را نصب کنید${gl_huang}20.  ${gl_bai}سایت پویا را سفارشی کنید"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}فقط nginx را نصب کنید${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}هدایت سایت"
	echo -e "${gl_huang}23.  ${gl_bai}پورت معکوس Proxy-IP+${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}پروکسی معکوس سایت - نام دامنه"
	echo -e "${gl_huang}25.  ${gl_bai}بستر مدیریت رمز عبور Bitwarden را نصب کنید${gl_huang}26.  ${gl_bai}وب سایت وبلاگ هاله را نصب کنید"
	echo -e "${gl_huang}27.  ${gl_bai}Generator Word Prompt Word Painting AI را نصب کنید${gl_huang}28.  ${gl_bai}تعادل بار پروکسی معکوس سایت"
	echo -e "${gl_huang}30.  ${gl_bai}سایت استاتیک را سفارشی کنید"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}مدیریت داده های سایت${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}از کل داده های سایت پشتیبان تهیه کنید"
	echo -e "${gl_huang}33.  ${gl_bai}پشتیبان گیری از راه دور به موقع${gl_huang}34.  ${gl_bai}کل داده های سایت را بازیابی کنید"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}محافظت از محیط LDNMP${gl_huang}36.  ${gl_bai}محیط LDNMP را بهینه کنید"
	echo -e "${gl_huang}37.  ${gl_bai}محیط LDNMP را به روز کنید${gl_huang}38.  ${gl_bai}حذف محیط LDNMP"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}بازگشت به منوی اصلی"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice


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
	  # تالار گفتمان
	  webname="Discuz论坛"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

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
	  echo "آدرس پایگاه داده: MySQL"
	  echo "نام بانک اطلاعاتی:$dbname"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
	  echo "پیشوند جدول: discuz_"


		;;

	  4)
	  clear
	  # دسک تاپ کدا
	  webname="可道云桌面"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

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
	  echo "آدرس پایگاه داده: MySQL"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
	  echo "نام بانک اطلاعاتی:$dbname"
	  echo "میزبان redis: redis"

		;;

	  5)
	  clear
	  # CM Apple
	  webname="苹果CMS"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

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
	  echo "آدرس پایگاه داده: MySQL"
	  echo "درگاه پایگاه داده: 3306"
	  echo "نام بانک اطلاعاتی:$dbname"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
	  echo "پیشوند پایگاه داده: MAC_"
	  echo "------------------------"
	  echo "پس از موفقیت نصب ، وارد آدرس پس زمینه شوید"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # کارت شمارش یک پا
	  webname="独脚数卡"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/dujiaoka.com.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming
	  wget ${gh_proxy}github.com/assimon/dujiaoka/releases/download/2.0.6/2.0.6-antibody.tar.gz && tar -zxvf 2.0.6-antibody.tar.gz && rm 2.0.6-antibody.tar.gz

	  restart_ldnmp


	  ldnmp_web_on
	  echo "آدرس پایگاه داده: MySQL"
	  echo "درگاه پایگاه داده: 3306"
	  echo "نام بانک اطلاعاتی:$dbname"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
	  echo ""
	  echo "آدرس redis: redis"
	  echo "رمز عبور redis: به طور پیش فرض پر نشده است"
	  echo "بندر ردیس: 6379"
	  echo ""
	  echo "URL وب سایت: https: //$yuming"
	  echo "مسیر ورود به سیستم پس زمینه: /مدیر"
	  echo "------------------------"
	  echo "نام کاربری: مدیر"
	  echo "رمز عبور: مدیر"
	  echo "------------------------"
	  echo "اگر Red Error0 هنگام ورود به سیستم در گوشه سمت راست بالا ظاهر می شود ، لطفاً از دستور زیر استفاده کنید:"
	  echo "من همچنین بسیار عصبانی هستم که کارت شماره یونیکورن بسیار مشکل ساز است و چنین مشکلاتی وجود خواهد داشت!"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # انجمن
	  webname="flarum论坛"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

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
	  echo "آدرس پایگاه داده: MySQL"
	  echo "نام بانک اطلاعاتی:$dbname"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
	  echo "پیشوند جدول: flarum_"
	  echo "اطلاعات سرپرست توسط خودتان تنظیم شده است"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

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
	  echo "پیشوند پایگاه داده: typecho_"
	  echo "آدرس پایگاه داده: MySQL"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
	  echo "نام بانک اطلاعاتی:$dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

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
	  echo "آدرس پایگاه داده: MySQL"
	  echo "درگاه پایگاه داده: 3306"
	  echo "نام بانک اطلاعاتی:$dbname"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  repeat_add_yuming
	  ldnmp_install_status
	  install_ssltls
	  certs_status
	  add_db

	  wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/index_php.conf
	  sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf
	  nginx_http_on

	  cd /home/web/html
	  mkdir $yuming
	  cd $yuming

	  clear
	  echo -e "[${gl_huang}1/6${gl_bai}] کد منبع PHP را بارگذاری کنید"
	  echo "-------------"
	  echo "در حال حاضر ، فقط بسته های کد منبع زیپ مجاز است. لطفاً بسته های کد منبع را در/صفحه اصلی/وب/html/قرار دهید${yuming}در فهرست"
	  read -e -p "همچنین می توانید لینک بارگیری را برای بارگیری از راه دور بسته کد منبع وارد کنید. مستقیماً Enter را فشار دهید تا از راه دور بارگیری کنید:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] مسیری که در آن index.php قرار دارد"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "لطفاً مسیر index.php را وارد کنید ، مشابه (/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] لطفاً نسخه PHP را انتخاب کنید"
	  echo "-------------"
	  read -e -p "1. آخرین نسخه PHP | 2. PHP7.4:" pho_v
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
		  echo "انتخاب نامعتبر ، لطفاً دوباره وارد شوید."
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] پسوند مشخص شده را نصب کنید"
	  echo "-------------"
	  echo "پسوند نصب شده"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] پیکربندی سایت را ویرایش کنید"
	  echo "-------------"
	  echo "برای ادامه هر کلید ، هر کلید را فشار دهید ، و می توانید پیکربندی سایت را با جزئیات ، مانند محتوای شبه استاتیک و غیره تنظیم کنید."
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] مدیریت پایگاه داده"
	  echo "-------------"
	  read -e -p "1. من یک سایت جدید می سازم. من یک سایت قدیمی می سازم و یک نسخه پشتیبان از پایگاه داده دارم:" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "پشتیبان گیری از پایگاه داده باید یک بسته فشرده شده .GZ-end باشد. لطفاً آن را در/خانه/فهرست قرار دهید تا از واردات داده های پشتیبان Pagoda/1Panel پشتیبانی کنید."
			  read -e -p "همچنین می توانید لینک بارگیری را برای بارگیری از راه دور داده های پشتیبان وارد کنید. مستقیماً Enter را فشار دهید از راه دور بارگیری می شود:" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "داده های جدول واردات پایگاه داده"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "واردات پایگاه داده تکمیل شد"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "آدرس پایگاه داده: MySQL"
	  echo "نام بانک اطلاعاتی:$dbname"
	  echo "نام کاربری:$dbuse"
	  echo "رمز عبور:$dbusepasswd"
	  echo "پیشوند جدول:$prefix"
	  echo "اطلاعات ورود به سیستم توسط خود شما تنظیم شده است"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  read -e -p "لطفاً نام دامنه پرش را وارد کنید:" reverseproxy
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
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
	  add_yuming
	  echo -e "قالب نام دامنه:${gl_huang}google.com${gl_bai}"
	  read -e -p "لطفاً نام دامنه ضد نسل خود را وارد کنید:" fandai_yuming
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
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
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
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
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
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
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
	  send_stats "نصب کردن$webname"
	  echo "استقرار را شروع کنید$webname"
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
	  echo -e "[${gl_huang}1/2${gl_bai}] کد منبع استاتیک را بارگذاری کنید"
	  echo "-------------"
	  echo "در حال حاضر ، فقط بسته های کد منبع زیپ مجاز است. لطفاً بسته های کد منبع را در/صفحه اصلی/وب/html/قرار دهید${yuming}در فهرست"
	  read -e -p "همچنین می توانید لینک بارگیری را برای بارگیری از راه دور بسته کد منبع وارد کنید. مستقیماً Enter را فشار دهید تا از راه دور بارگیری کنید:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] مسیری که در آن index.html واقع شده است"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "لطفاً مسیر index.html را وارد کنید ، مشابه (/home/web/html/$yuming/index/）： " index_lujing

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
	  send_stats "نسخه پشتیبان از محیط زیست LDNMP"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}پشتیبان گیری$backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "پرونده پشتیبان ایجاد شده است: /صفحه اصلی$backup_filename"
		read -e -p "آیا می خواهید داده های پشتیبان را به یک سرور از راه دور منتقل کنید؟ (y/n):" choice
		case "$choice" in
		  [Yy])
			read -e -p "لطفاً IP از راه دور سرور را وارد کنید:" remote_ip
			if [ -z "$remote_ip" ]; then
			  echo "خطا: لطفاً IP از راه دور سرور را وارد کنید."
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "این پرونده به دایرکتوری خانه از راه دور سرور منتقل شده است."
			else
			  echo "پرونده منتقل شده یافت نشد."
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "پشتیبان گیری از راه دور به موقع"
	  read -e -p "IP سرور از راه دور را وارد کنید:" useip
	  read -e -p "رمز ورود سرور از راه دور را وارد کنید:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. پشتیبان گیری هفتگی 2. پشتیبان گیری روزانه"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "روز هفته را برای پشتیبان گیری هفتگی خود انتخاب کنید (0-6 ، 0 نشان دهنده یکشنبه):" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "زمان پشتیبان گیری روزانه (ساعت ، 0-23) را انتخاب کنید:" hour
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
	  send_stats "ترمیم محیط LDNMP"
	  echo "پشتیبان گیری سایت موجود"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "برای بازیابی آخرین نسخه پشتیبان وارد شوید ، نام فایل پشتیبان را وارد کنید تا نسخه پشتیبان تهیه شده را بازیابی کنید ، 0 را وارد کنید تا از آن خارج شوید:" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # اگر کاربر نام پرونده را وارد نکرد ، از آخرین بسته فشرده شده استفاده کنید
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}رفع فشار انجام می شود$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "هیچ بسته فشرده سازی یافت نشد."
	  fi

	  ;;

	35)
	  send_stats "دفاع محیط زیست LDNMP"
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
			  echo -e "برنامه دفاع وب سایت سرور${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. برنامه دفاع را نصب کنید"
			  echo "------------------------"
			  echo "5. مشاهده سابقه رهگیری SSH 6. مشاهده سابقه رهگیری وب سایت"
			  echo "7. لیست قوانین دفاعی را مشاهده کنید 8. مشاهده نظارت بر زمان واقعی سیاههها"
			  echo "------------------------"
			  echo "11. پیکربندی پارامترهای رهگیری 12. همه IP های مسدود شده را پاک کنید"
			  echo "------------------------"
			  echo "21. حالت Cloudflare 22. بار زیاد در 5 ثانیه سپر"
			  echo "------------------------"
			  echo "31. WAF 32 را روشن کنید. WAF را خاموش کنید"
			  echo "33. DDOS Defense 34 را روشن کنید. دفاع DDOS را خاموش کنید"
			  echo "------------------------"
			  echo "9. برنامه دفاعی را حذف کنید"
			  echo "------------------------"
			  echo "0. به منوی قبلی برگردید"
			  echo "------------------------"
			  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
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
					  echo "برنامه دفاعی Fail2ban حذف نشده است"
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
					  send_stats "حالت CloudFlare"
					  echo "به گوشه سمت راست بالای پس زمینه CF بروید ، API Token را در سمت چپ انتخاب کنید و کلید جهانی API را بدست آورید"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "شماره حساب CF را وارد کنید:" cfuser
					  read -e -p "کلید جهانی API را برای CF وارد کنید:" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /path/to/fail2ban/config/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "حالت CloudFlare برای مشاهده سوابق رهگیری در پس زمینه CF ، سایت های امنیت-امنیت پیکربندی شده است"
					  ;;

				  22)
					  send_stats "بار زیاد در سپر 5 ثانیه"
					  echo -e "${gl_huang}وب سایت به طور خودکار هر 5 دقیقه یکبار تشخیص می دهد. هنگامی که بار زیاد تشخیص داده می شود ، سپر به طور خودکار روشن می شود و بار کم به مدت 5 ثانیه به طور خودکار خاموش می شود.${gl_bai}"
					  echo "--------------"
					  echo "پارامترهای CF را دریافت کنید:"
					  echo -e "به گوشه سمت راست بالای پس زمینه CF بروید ، API Token را در سمت چپ انتخاب کنید و آن را بدست آورید${gl_huang}Global API Key${gl_bai}"
					  echo -e "برای دریافت به سمت راست پایین صفحه خلاصه نام دامنه پس زمینه CF بروید${gl_huang}شناسه منطقه${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "شماره حساب CF را وارد کنید:" cfuser
					  read -e -p "کلید جهانی API را برای CF وارد کنید:" cftoken
					  read -e -p "شناسه منطقه نام دامنه را در CF وارد کنید:" cfzonID

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
						  echo "اسکریپت باز شدن محافظ اتوماتیک بار بالا اضافه شده است"
					  else
						  echo "اسکریپت Shield Automatic در حال حاضر وجود دارد ، نیازی به اضافه کردن آن نیست"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "سایت WAF فعال است"
					  send_stats "سایت WAF فعال است"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "سایت WAF بسته شده است"
					  send_stats "سایت WAF بسته شده است"
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
		;;

	36)
		  while true; do
			  clear
			  send_stats "محیط LDNMP را بهینه کنید"
			  echo "محیط LDNMP را بهینه کنید"
			  echo "------------------------"
			  echo "1. حالت استاندارد 2. حالت عملکرد بالا (توصیه می شود 2H2G یا بالاتر)"
			  echo "------------------------"
			  echo "0. به منوی قبلی برگردید"
			  echo "------------------------"
			  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "حالت استاندارد سایت"

				  # تنظیم nginx
				  sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

				  # تنظیم PHP
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # تنظیم PHP
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # تنظیم mysql
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced


				  echo "محیط LDNMP روی حالت استاندارد تنظیم شده است"

					  ;;
				  2)
				  send_stats "حالت عملکرد بالا سایت"

				  # تنظیم nginx
				  sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

				  # تنظیم PHP
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # تنظیم PHP
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # تنظیم mysql
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

				  echo "محیط LDNMP روی حالت عملکرد بالا تنظیم شده است"

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
		  send_stats "محیط LDNMP را به روز کنید"
		  echo "محیط LDNMP را به روز کنید"
		  echo "------------------------"
		  ldnmp_v
		  echo "نسخه جدیدی از قطعات را کشف کنید"
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
		  echo "1. به روزرسانی Nginx 2. MySQL 3 را به روز کنید. PHP 4 را به روز کنید. Redis را به روز کنید"
		  echo "------------------------"
		  echo "5. محیط کامل را به روز کنید"
		  echo "------------------------"
		  echo "0. به منوی قبلی برگردید"
		  echo "------------------------"
		  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "لطفا وارد کنید${ldnmp_pods}شماره نسخه (مانند: 8.0 8.3 8.4 9.0) (برای دریافت آخرین نسخه وارد شوید):" version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "تمدید کردن$ldnmp_pods"
			  echo "تمدید کردن${ldnmp_pods}پایان"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "لطفا وارد کنید${ldnmp_pods}شماره نسخه (مانند: 7.4 8.0 8.1 8.2 8.3) (برای دریافت آخرین نسخه وارد شوید):" version
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
			  docker exec php sh -c 'echo "memory_limit=256M" > /usr/local/etc/php/conf.d/memory.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_execution_time=1200" > /usr/local/etc/php/conf.d/max_execution_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_time=600" > /usr/local/etc/php/conf.d/max_input_time.ini' > /dev/null 2>&1
			  docker exec php sh -c 'echo "max_input_vars=5000" > /usr/local/etc/php/conf.d/max_input_vars.ini' > /dev/null 2>&1

			  fix_phpfpm_con $ldnmp_pods

			  docker restart $ldnmp_pods > /dev/null 2>&1
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "تمدید کردن$ldnmp_pods"
			  echo "تمدید کردن${ldnmp_pods}پایان"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  restart_redis
			  send_stats "تمدید کردن$ldnmp_pods"
			  echo "تمدید کردن${ldnmp_pods}پایان"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "محیط LDNMP را کاملاً به روز کنید"
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
		send_stats "حذف محیط LDNMP"
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
			echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "ورودی نامعتبر!"
	esac
	break_end

  done

}



linux_panel() {

	while true; do
	  clear
	  # send_stats "بازار برنامه"
	  echo -e "بازار کاربرد"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}نسخه رسمی پنل باوتا${gl_kjlan}2.   ${gl_bai}نسخه بین المللی Aapanel"
	  echo -e "${gl_kjlan}3.   ${gl_bai}پانل مدیریت نسل 1 پانل${gl_kjlan}4.   ${gl_bai}پانل بصری nginxproxymanager"
	  echo -e "${gl_kjlan}5.   ${gl_bai}برنامه لیست پرونده های چند فروشگاهی Alist${gl_kjlan}6.   ${gl_bai}نسخه وب دسک تاپ Ubuntu از راه دور"
	  echo -e "${gl_kjlan}7.   ${gl_bai}پانل نظارت Nezha Probe VPS${gl_kjlan}8.   ${gl_bai}پانل بارگیری مغناطیسی QB آفلاین BT"
	  echo -e "${gl_kjlan}9.   ${gl_bai}برنامه سرور پستی Poste.io${gl_kjlan}10.  ${gl_bai}سیستم چت آنلاین چند نفره Rocketchat"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}نرم افزار مدیریت پروژه Zendao${gl_kjlan}12.  ${gl_bai}پانل qinglong پانل مدیریت وظیفه به موقع"
	  echo -e "${gl_kjlan}13.  ${gl_bai}دیسک شبکه CloudReve${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}برنامه ساده مدیریت عکس تختخواب"
	  echo -e "${gl_kjlan}15.  ${gl_bai}سیستم مدیریت چندرسانه ای Emby${gl_kjlan}16.  ${gl_bai}پانل تست سرعت سرعت"
	  echo -e "${gl_kjlan}17.  ${gl_bai}Adguardhome Adware${gl_kjlan}18.  ${gl_bai}Office Office Office Office Office"
	  echo -e "${gl_kjlan}19.  ${gl_bai}پانل فایروال Thunder Pool WAF${gl_kjlan}20.  ${gl_bai}پانل مدیریت کانتینر Portainer"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}نسخه وب VScode${gl_kjlan}22.  ${gl_bai}ابزار نظارت بر Uptimekuma"
	  echo -e "${gl_kjlan}23.  ${gl_bai}یادداشت صفحه وب یادداشت${gl_kjlan}24.  ${gl_bai}Webtop Remote Desktop Edition${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${gl_bai}دیسک شبکه NextCloud${gl_kjlan}26.  ${gl_bai}چارچوب مدیریت وظیفه زمان بندی QD-Today"
	  echo -e "${gl_kjlan}27.  ${gl_bai}پنل مدیریت پشته ظرف Dockge${gl_kjlan}28.  ${gl_bai}ابزار تست سرعت Librespeed"
	  echo -e "${gl_kjlan}29.  ${gl_bai}سایت جستجوی جمع آوری Searxng${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}سیستم آلبوم خصوصی Photoprism"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}مجموعه ابزار stirlingpdf${gl_kjlan}32.  ${gl_bai}نرم افزار نمودار آنلاین Drawio رایگان${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}پانل ناوبری آفتاب${gl_kjlan}34.  ${gl_bai}پلت فرم اشتراک فایل Pingvin-Share"
	  echo -e "${gl_kjlan}35.  ${gl_bai}دایره مینیمالیستی دوستان${gl_kjlan}36.  ${gl_bai}وب سایت جمع آوری چت Lobechatai"
	  echo -e "${gl_kjlan}37.  ${gl_bai}جعبه ابزار myip${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}سطل خانوادگی شیایایا آلیست"
	  echo -e "${gl_kjlan}39.  ${gl_bai}ابزار ضبط پخش زنده Bililive${gl_kjlan}40.  ${gl_bai}نسخه وب وب سایت ابزار اتصال SSH"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}پنل مدیریت ماوس${gl_kjlan}42.  ${gl_bai}ابزار اتصال از راه دور Nexte"
	  echo -e "${gl_kjlan}43.  ${gl_bai}میز از راه دور Rustdesk (سرور)${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}میز از راه دور Rustdesk (رله)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${gl_bai}ایستگاه شتاب داکر${gl_kjlan}46.  ${gl_bai}ایستگاه شتاب GitHub${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${gl_bai}نظارت بر پرومتئوس${gl_kjlan}48.  ${gl_bai}پرومتئوس (نظارت میزبان)"
	  echo -e "${gl_kjlan}49.  ${gl_bai}پرومتئوس (نظارت بر کانتینر)${gl_kjlan}50.  ${gl_bai}ابزار نظارت دوباره پر کردن"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${gl_bai}پنل مرغ PVE${gl_kjlan}52.  ${gl_bai}پنل مدیریت کانتینر dpanel"
	  echo -e "${gl_kjlan}53.  ${gl_bai}LLAMA3 CHAT AI MODEL${gl_kjlan}54.  ${gl_bai}پانل مدیریت ساختمان وب سایت میزبان AMH"
	  echo -e "${gl_kjlan}55.  ${gl_bai}نفوذ اینترانت FRP (سمت سرور)${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${gl_bai}نفوذ اینترانت FRP (مشتری)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${gl_bai}Deepseek Chat AI مدل بزرگ${gl_kjlan}58.  ${gl_bai}پایگاه دانش مدل بزرگ متفاوت${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${gl_bai}مدیریت دارایی مدل بزرگ Newapi${gl_kjlan}60.  ${gl_bai}ماشین سنگر منبع باز Jumpserver"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${gl_bai}سرور ترجمه آنلاین${gl_kjlan}62.  ${gl_bai}پایه دانش مدل بزرگ ragflow"
	  echo -e "${gl_kjlan}63.  ${gl_bai}پلت فرم AI خود میزبان OpenWebui${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}جعبه ابزار آن"
	  echo -e "${gl_kjlan}65.  ${gl_bai}پلت فرم گردش کار اتوماسیون N8N${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}ابزار بارگیری ویدیویی YT-DLP"
	  echo -e "${gl_kjlan}67.  ${gl_bai}DDNS-GO ابزار مدیریت DNS DNS${gl_huang}★${gl_bai}               ${gl_kjlan}68.  ${gl_bai}بستر مدیریت گواهینامه Allinssl"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

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

			local lujing="command -v 1pctl > /dev/null 2>&1"
			local panelname="1Panel"
			local panelurl="https://1panel.cn/"

			panel_app_install() {
				install bash
				curl -sSL https://resource.fit2cloud.com/1panel/package/quick_start.sh -o quick_start.sh && bash quick_start.sh
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

			local docker_describe="如果您已经安装了其他面板或者LDNMP建站环境，建议先卸载，再安装npm！"
			local docker_url="官网介绍: https://nginxproxymanager.com/"
			local docker_use="echo \"初始用户名: admin@example.com\""
			local docker_passwd="echo \"初始密码: changeme\""
			local app_size="1"

			docker_app

			  ;;

		  5)

			local docker_name="alist"
			local docker_img="xhofe/alist-aria2:latest"
			local docker_port=5244

			docker_rum() {

				docker run -d \
					--restart=always \
					-v /home/docker/alist:/opt/alist/data \
					-p ${docker_port}:5244 \
					-e PUID=0 \
					-e PGID=0 \
					-e UMASK=022 \
					--name="alist" \
					xhofe/alist-aria2:latest

			}


			local docker_describe="一个支持多种存储，支持网页浏览和 WebDAV 的文件列表程序，由 gin 和 Solidjs 驱动"
			local docker_url="官网介绍: https://alist.nn.ci/zh/"
			local docker_use="docker exec -it alist ./alist admin random"
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
						  -p ${docker_port}:3000 \
						  -v /home/docker/webtop/data:/config \
						  -v /var/run/docker.sock:/var/run/docker.sock \
						  --shm-size="1gb" \
						  --restart unless-stopped \
						  lscr.io/linuxserver/webtop:ubuntu-kde



			}


			local docker_describe="webtop基于Ubuntu的容器，包含官方支持的完整桌面环境，可通过任何现代 Web 浏览器访问"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
			local app_size="2"
			docker_app


			  ;;
		  7)
			clear
			send_stats "Nezha بسازید"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "نظارت بر نزا$check_docker $update_status"
				echo "منبع باز ، نظارت بر سرور سبک و کاربردی آسان و کاربردی و بهره برداری از سرور"
				echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1wv421c71t؟t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1. استفاده کنید"
				echo "------------------------"
				echo "5. دسترسی به نام دامنه را اضافه کنید 6. دسترسی به نام دامنه را حذف کنید"
				echo "7. اجازه دسترسی به پورت IP+ 8 را داشته باشید."
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید:" choice

				case $choice in
					1)
						check_disk_space 1
						install unzip jq
						install_docker
						curl -sL ${gh_proxy}raw.githubusercontent.com/nezhahq/scripts/refs/heads/main/install.sh -o nezha.sh && chmod +x nezha.sh && ./nezha.sh
						local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
						check_docker_app_ip
						;;
					5)
						echo "${docker_name}تنظیمات دسترسی دامنه"
						send_stats "${docker_name}تنظیمات دسترسی دامنه"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						block_container_port "$docker_name" "$ipv4_address"
						;;

					6)
						echo "فرمت نام دامنه مثال. com با https: // همراه نیست"
						web_del
						;;

					7)
						send_stats "دسترسی به IP${docker_name}"
						clear_container_rules "$docker_name" "$ipv4_address"
						;;

					8)
						send_stats "دسترسی به IP${docker_name}"
						block_container_port "$docker_name" "$ipv4_address"
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
			send_stats "یک اداره پست بسازید"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "خدمات پستی$check_docker $update_status"
				echo "Poste.io یک راه حل سرور Mail Source Source است."
				echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1wv421c71t؟t=0.1"

				echo ""
				echo "تشخیص بندر"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
				  echo -e "${gl_lv}بندر$portدر حال حاضر موجود است${gl_bai}"
				else
				  echo -e "${gl_hong}بندر$portدر حال حاضر موجود نیست${gl_bai}"
				fi
				echo ""

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "آدرس دسترسی:"
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. نصب 2. بروزرسانی 3. حذف نصب کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید:" choice

				case $choice in
					1)
						check_disk_space 2
						read -e -p "لطفاً نام دامنه ایمیل را به عنوان مثال ، mail.yuming.com تنظیم کنید:" yuming
						mkdir -p /home/docker
						echo "$yuming" > /home/docker/mail.txt
						echo "------------------------"
						ip_address
						echo "ابتدا این سوابق DNS را تجزیه کنید"
						echo "A           mail            $ipv4_address"
						echo "CNAME       imap            $yuming"
						echo "CNAME       pop             $yuming"
						echo "CNAME       smtp            $yuming"
						echo "MX          @               $yuming"
						echo "TXT         @               v=spf1 mx ~all"
						echo "TXT         ?               ?"
						echo ""
						echo "------------------------"
						echo "برای ادامه ... هر کلید را فشار دهید ..."
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
						echo "poste.io نصب شده است"
						echo "------------------------"
						echo "با استفاده از آدرس زیر می توانید به Poste.io دسترسی پیدا کنید:"
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
						echo "poste.io نصب شده است"
						echo "------------------------"
						echo "با استفاده از آدرس زیر می توانید به Poste.io دسترسی پیدا کنید:"
						echo "https://$yuming"
						echo ""
						;;
					3)
						docker rm -f mailserver
						docker rmi -f analogic/poste.io
						rm /home/docker/mail.txt
						rm -rf /home/docker/mail
						echo "برنامه حذف شده است"
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
				echo "نصب شده"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "Rocket.Chat نصب شده است"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "برنامه حذف شده است"
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
				echo "نصب شده"
				check_docker_app_ip
			}


			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}


			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "برنامه حذف شده است"
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
			send_stats "یک استخر رعد و برق بسازید"

			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "سرویس استخر تندر$check_docker"
				echo "لی چی یک صفحه برنامه فایروال سایت WAF است که توسط Changting Technology ساخته شده است که می تواند سایت آژانس را برای دفاع خودکار معکوس کند."
				echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1mz421t74c؟t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. نصب 2. بروزرسانی 3. تنظیم مجدد رمز عبور 4. حذف نصب کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "انتخاب خود را وارد کنید:" choice

				case $choice in
					1)
						install_docker
						check_disk_space 5
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
						clear
						echo "پانل Whunder Pool WAF نصب شده است"
						check_docker_app_ip
						docker exec safeline-mgt resetadmin

						;;

					2)
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
						docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
						echo ""
						clear
						echo "پانل WAF THIRDER POOL WAF به روز شده است"
						check_docker_app_ip
						;;
					3)
						docker exec safeline-mgt resetadmin
						;;
					4)
						cd /data/safeline
						docker compose down --rmi all
						echo "اگر شما فهرست نصب پیش فرض هستید ، این پروژه اکنون حذف نشده است. اگر دایرکتوری نصب را سفارشی می کنید ، برای اجرای آن باید به دایرکتوری نصب بروید:"
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


			local docker_describe="webtop基于 Alpine、Ubuntu、Fedora 和 Arch 的容器，包含官方支持的完整桌面环境，可通过任何现代 Web 浏览器访问"
			local docker_url="官网介绍: https://docs.linuxserver.io/images/docker-webtop/"
			local docker_use=""
			local docker_passwd=""
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
			local docker_img="alandoyle/searxng:latest"
			local docker_port=8700

			docker_rum() {
				docker run --name=searxng \
					-d --init \
					--restart=unless-stopped \
					-v /home/docker/searxng/config:/etc/searxng \
					-v /home/docker/searxng/templates:/usr/local/searxng/searx/templates/simple \
					-v /home/docker/searxng/theme:/usr/local/searxng/searx/static/themes/simple \
					-p ${docker_port}:8080/tcp \
					alandoyle/searxng:latest
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
			local docker_url="معرفی رسمی وب سایت:${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
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
			send_stats "سطل خانوادگی شیایایا"
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
				echo "نصب شده"
				check_docker_app_ip
				echo "نام کاربری و رمز عبور اولیه عبارتند از: مدیر"
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
				echo "برنامه حذف شده است"
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
			send_stats "مرغ"
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
				echo "نصب شده"
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
				echo "برنامه حذف شده است"
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
				echo "نصب شده"
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
				echo "نصب شده"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "برنامه حذف شده است"
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
				echo "نصب شده"
				check_docker_app_ip
				echo "نام کاربری اولیه: مدیر"
				echo "رمز عبور اولیه: Changeme"
			}


			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "برنامه به روز شده است"
			}


			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "برنامه حذف شده است"
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
				echo "نصب شده"
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
				echo "برنامه حذف شده است"
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

				ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
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
			local docker_port=9876

			docker_rum() {
				docker run -d \
						 --name ddns-go \
						 --restart=always \
						 -p ${docker_port}:9876 \
						 -v /home/docker/ddns-go:/root \
						 jeessy/ddns-go

			}

			local docker_describe="自动将你的公网 IP（IPv4/IPv6）实时更新到各大 DNS 服务商，实现动态域名解析。"
			local docker_url="官网介绍: https://github.com/CorentinTh/it-tools"
			local docker_use=""
			local docker_passwd=""
			local app_size="1"
			docker_app
			  ;;

		  68)
			local docker_name="allinssl"
			local docker_img="allinssl/allinssl:latest"
			local docker_port=7979

			docker_rum() {
				docker run -itd --name allinssl -p ${docker_port}:8888 -v /home/docker/allinssl/data:/www/allinssl/data -e ALLINSSL_USER=allinssl -e ALLINSSL_PWD=allinssldocker -e ALLINSSL_URL=allinssl allinssl/allinssl:latest
			}

			local docker_describe="开源免费的 SSL 证书自动化管理平台"
			local docker_url="官网介绍: https://allinssl.com"
			local docker_use="echo \"初始用户名: allinssl\""
			local docker_passwd="echo \"初始密码: allinssldocker\""
			local app_size="1"
			docker_app
			  ;;


		  0)
			  kejilion
			  ;;
		  *)
			  echo "ورودی نامعتبر!"
			  ;;
	  esac
	  break_end

	done
}


linux_work() {

	while true; do
	  clear
	  send_stats "فضای کاری من"
	  echo -e "فضای کاری من"
	  echo -e "این سیستم فضای کاری را در اختیار شما قرار می دهد که می تواند روی پس زمینه اجرا شود ، که می توانید برای انجام کارهای بلند مدت از آن استفاده کنید."
	  echo -e "حتی اگر SSH را قطع کنید ، وظایف موجود در فضای کاری قطع نمی شود و وظایف موجود در پس زمینه مقیم خواهد شد."
	  echo -e "${gl_huang}نکته:${gl_bai}پس از ورود به فضای کاری ، از Ctrl+B استفاده کنید و D را به تنهایی فشار دهید تا از فضای کاری خارج شوید!"
	  echo -e "${gl_kjlan}------------------------"
	  echo "لیست فضاهای کاری موجود موجود"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}فضای کاری شماره 1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}فضای کاری شماره 2"
	  echo -e "${gl_kjlan}3.   ${gl_bai}فضای کاری شماره 3"
	  echo -e "${gl_kjlan}4.   ${gl_bai}فضای کاری شماره 4"
	  echo -e "${gl_kjlan}5.   ${gl_bai}فضای کاری شماره 5"
	  echo -e "${gl_kjlan}6.   ${gl_bai}فضای کاری شماره 6"
	  echo -e "${gl_kjlan}7.   ${gl_bai}فضای کاری شماره 7"
	  echo -e "${gl_kjlan}8.   ${gl_bai}فضای کاری شماره 8"
	  echo -e "${gl_kjlan}9.   ${gl_bai}فضای کاری شماره 9"
	  echo -e "${gl_kjlan}10.  ${gl_bai}فضای کاری شماره 10"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}حالت مقیم SSH${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}فضای کاری را ایجاد و وارد کنید"
	  echo -e "${gl_kjlan}23.  ${gl_bai}دستورات را به فضای کاری پس زمینه تزریق کنید"
	  echo -e "${gl_kjlan}24.  ${gl_bai}فضای کاری مشخص شده را حذف کنید"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
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
			  send_stats "حالت مقیم SSH"
			  echo -e "حالت مقیم SSH${tmux_sshd_status}"
			  echo "پس از فعال شدن اتصال SSH ، مستقیماً وارد حالت مقیم شده و به حالت کار قبلی باز می گردد."
			  echo "------------------------"
			  echo "1. روشن را روشن کنید. خاموش کنید"
			  echo "------------------------"
			  echo "0. به منوی قبلی برگردید"
			  echo "------------------------"
			  read -e -p "لطفا انتخاب خود را وارد کنید:" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "فضای کاری را شروع کنید$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\ n# به طور خودکار جلسه tmux \ nif را وارد کنید [[-z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
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
			  read -e -p "لطفاً نام فضای کاری را که ایجاد کرده اید یا وارد کرده اید ، مانند 1001 KJ001 Work1 وارد کنید:" SESSION_NAME
			  tmux_run
			  send_stats "فضای کاری سفارشی"
			  ;;


		  23)
			  read -e -p "لطفاً دستور مورد نظر خود را در پس زمینه وارد کنید ، مانند: curl -fssl https://get.docker.com | sh:" tmuxd
			  tmux_run_d
			  send_stats "دستورات را به فضای کاری پس زمینه تزریق کنید"
			  ;;

		  24)
			  read -e -p "لطفاً نام فضای کاری را که می خواهید حذف کنید وارد کنید:" gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "فضای کاری را حذف کنید"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "ورودی نامعتبر!"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # SEND_STATS "ابزارهای سیستم"
	  echo -e "ابزار سیستم"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}کلیدهای میانبر راه اندازی اسکریپت را تنظیم کنید${gl_kjlan}2.   ${gl_bai}رمز ورود ورود به سیستم را تغییر دهید"
	  echo -e "${gl_kjlan}3.   ${gl_bai}حالت ورود به سیستم رمز عبور${gl_kjlan}4.   ${gl_bai}نسخه مشخص شده پایتون را نصب کنید"
	  echo -e "${gl_kjlan}5.   ${gl_bai}همه بنادر را باز کنید${gl_kjlan}6.   ${gl_bai}پورت اتصال SSH را اصلاح کنید"
	  echo -e "${gl_kjlan}7.   ${gl_bai}优化DNS地址                        ${gl_kjlan}8.   ${gl_bai}سیستم نصب مجدد یک کلیک${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}禁用ROOT账户创建新账户             ${gl_kjlan}10.  ${gl_bai}اولویت IPv4/IPv6 را تغییر دهید"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}查看端口占用状态                   ${gl_kjlan}12.  ${gl_bai}اندازه حافظه مجازی را تغییر دهید"
	  echo -e "${gl_kjlan}13.  ${gl_bai}مدیریت کاربر${gl_kjlan}14.  ${gl_bai}ژنراتور کاربر/رمز عبور"
	  echo -e "${gl_kjlan}15.  ${gl_bai}تنظیم منطقه زمانی سیستم${gl_kjlan}16.  ${gl_bai}شتاب BBR3 را تنظیم کنید"
	  echo -e "${gl_kjlan}17.  ${gl_bai}فایروال مدیر پیشرفته${gl_kjlan}18.  ${gl_bai}نام میزبان را تغییر دهید"
	  echo -e "${gl_kjlan}19.  ${gl_bai}منبع به روزرسانی سیستم سوئیچ${gl_kjlan}20.  ${gl_bai}مدیریت وظیفه زمان بندی"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}تجزیه میزبان بومی${gl_kjlan}22.  ${gl_bai}SSH防御程序"
	  echo -e "${gl_kjlan}23.  ${gl_bai}خاموش کردن خودکار از حد فعلی${gl_kjlan}24.  ${gl_bai}حالت ورود به سیستم کلید خصوصی"
	  echo -e "${gl_kjlan}25.  ${gl_bai}نظارت بر سیستم TG-BOT و هشدار زودهنگام${gl_kjlan}26.  ${gl_bai}رفع آسیب پذیری های پرخطر Openssh (Xiuyuan)"
	  echo -e "${gl_kjlan}27.  ${gl_bai}ارتقاء هسته Red Hat Linux${gl_kjlan}28.  ${gl_bai}بهینه سازی پارامترهای هسته در سیستم لینوکس${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}ابزار اسکن ویروس${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}مدیر پرونده"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}سوئیچ زبان سیستم${gl_kjlan}32.  ${gl_bai}ابزار زیباسازی خط فرمان${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}سطل بازیافت سیستم را تنظیم کنید${gl_kjlan}34.  ${gl_bai}تهیه نسخه پشتیبان از سیستم و بازیابی"
	  echo -e "${gl_kjlan}35.  ${gl_bai}ابزار اتصال از راه دور SSH${gl_kjlan}36.  ${gl_bai}ابزار مدیریت پارتیشن دیسک سخت"
	  echo -e "${gl_kjlan}37.  ${gl_bai}تاریخ خط فرمان${gl_kjlan}38.  ${gl_bai}ابزار همگام سازی از راه دور RSYNC"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}صفحه پیام${gl_kjlan}66.  ${gl_bai}بهینه سازی سیستم یک مرحله ای${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}سرور را مجدداً راه اندازی کنید${gl_kjlan}100. ${gl_bai}حریم خصوصی و امنیت"
	  echo -e "${gl_kjlan}101. ${gl_bai}استفاده پیشرفته از فرمان k${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}حذف اسکریپت شیر ​​فناوری"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "لطفاً کلید میانبر خود را وارد کنید (0 را برای خروج وارد کنید):" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "کلیدهای میانبر تنظیم شده اند"
				  send_stats "کلیدهای میانبر اسکریپت تنظیم شده اند"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "رمز ورود ورود خود را تنظیم کنید"
			  echo "رمز ورود ورود خود را تنظیم کنید"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "حالت رمز عبور"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "مدیریت نسخه PY"
			echo "مدیریت نسخه پایتون"
			echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1pm42157ck؟t=0.1"
			echo "---------------------------------------"
			echo "این ویژگی یکپارچه هر نسخه ای را که به طور رسمی توسط پایتون پشتیبانی می شود نصب می کند!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "شماره نسخه پیتون فعلی:${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "نسخه توصیه شده: 3.12 3.11 3.10 3.9 3.8 2.7"
			echo "پرس و جو نسخه های بیشتر: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "شماره نسخه Python را که می خواهید نصب کنید وارد کنید (0 را برای خروج وارد کنید):" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "مدیریت اسکریپت PY"
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
					echo "مدیر بسته ناشناخته!"
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
			echo -e "شماره نسخه پیتون فعلی:${gl_huang}$VERSION${gl_bai}"
			send_stats "نسخه PY SCRIPT SCRIPT"

			  ;;

		  5)
			  root_use
			  send_stats "بندر"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "همه درگاه ها باز هستند"

			  ;;
		  6)
			root_use
			send_stats "درگاه SSH را اصلاح کنید"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# شماره پورت SSH فعلی را بخوانید
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# شماره پورت SSH فعلی را چاپ کنید
				echo -e "شماره پورت SSH فعلی:${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "اعداد با شماره پورت از 1 تا 65535. (برای خروج 0 را وارد کنید)"

				# کاربر را وادار به وارد کردن شماره پورت SSH جدید کنید
				read -e -p "لطفاً شماره پورت جدید SSH را وارد کنید:" new_port

				# تعیین کنید که آیا شماره پورت در محدوده معتبر است
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "درگاه SSH اصلاح شده است"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "از اصلاح بندر SSH خارج شوید"
						break
					else
						echo "شماره پورت نامعتبر است ، لطفاً یک عدد بین 1 تا 65535 وارد کنید."
						send_stats "ورودی پورت SSH نامعتبر است"
						break_end
					fi
				else
					echo "ورودی نامعتبر است ، لطفاً شماره را وارد کنید."
					send_stats "ورودی پورت SSH نامعتبر است"
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
			send_stats "کاربران جدید ریشه را غیرفعال می کنند"
			read -e -p "لطفاً نام کاربری جدید را وارد کنید (برای خروج 0 را وارد کنید):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "این عملیات به پایان رسیده است."
			;;


		  10)
			root_use
			send_stats "اولویت V4/V6 را تنظیم کنید"
			while true; do
				clear
				echo "اولویت V4/V6 را تنظیم کنید"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "تنظیمات اولویت شبکه فعلی:${gl_huang}IPv4${gl_bai}اولویت"
				else
					echo -e "تنظیمات اولویت شبکه فعلی:${gl_huang}IPv6${gl_bai}اولویت"
				fi
				echo ""
				echo "------------------------"
				echo "1. اولویت IPv4 2. اولویت IPv6 3. ابزار تعمیر IPv6"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "یک شبکه ترجیحی را انتخاب کنید:" choice

				case $choice in
					1)
						sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
						echo "به اولویت IPv4 تبدیل شد"
						send_stats "به اولویت IPv4 تبدیل شد"
						;;
					2)
						sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
						echo "به اولویت IPv6 تغییر یافته است"
						send_stats "به اولویت IPv6 تغییر یافته است"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "این عملکرد توسط استاد JHB ارائه شده است ، به لطف او!"
						send_stats "رفع IPv6"
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
			send_stats "حافظه مجازی را تنظیم کنید"
			while true; do
				clear
				echo "حافظه مجازی را تنظیم کنید"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "حافظه مجازی فعلی:${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 1024m 2 را اختصاص دهید. 2048m 3 را اختصاص دهید. 4096m را اختصاص دهید. اندازه سفارشی"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" choice

				case "$choice" in
				  1)
					send_stats "حافظه مجازی 1G تنظیم شده است"
					add_swap 1024

					;;
				  2)
					send_stats "2G حافظه مجازی تنظیم شده است"
					add_swap 2048

					;;
				  3)
					send_stats "حافظه مجازی 4G تنظیم شده است"
					add_swap 4096

					;;

				  4)
					read -e -p "لطفاً اندازه حافظه مجازی (واحد M) را وارد کنید:" new_swap
					add_swap "$new_swap"
					send_stats "حافظه مجازی سفارشی تنظیم شده است"
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
				send_stats "مدیریت کاربر"
				echo "لیست کاربری"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "عملیات حساب"
				  echo "------------------------"
				  echo "1. یک حساب عادی ایجاد کنید. یک حساب حق بیمه ایجاد کنید"
				  echo "------------------------"
				  echo "3. بالاترین مجوزها را بدهید 4. بالاترین مجوزها را لغو کنید"
				  echo "------------------------"
				  echo "5. حساب را حذف کنید"
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				  case $sub_choice in
					  1)
					   # کاربر را وادار به وارد کردن نام کاربری جدید کند
					   read -e -p "لطفا یک نام کاربری جدید وارد کنید:" new_username

					   # یک کاربر جدید ایجاد کنید و رمز عبور را تنظیم کنید
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "این عملیات به پایان رسیده است."
						  ;;

					  2)
					   # کاربر را وادار به وارد کردن نام کاربری جدید کند
					   read -e -p "لطفا یک نام کاربری جدید وارد کنید:" new_username

					   # یک کاربر جدید ایجاد کنید و رمز عبور را تنظیم کنید
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # به کاربران جدید مجوزهای سودو را اعطا کنید
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   echo "این عملیات به پایان رسیده است."

						  ;;
					  3)
					   read -e -p "لطفا نام کاربری خود را وارد کنید:" username
					   # به کاربران جدید مجوزهای سودو را اعطا کنید
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
						  ;;
					  4)
					   read -e -p "لطفا نام کاربری خود را وارد کنید:" username
					   # مجوزهای سودو کاربر را از پرونده sudoers حذف کنید
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "لطفاً برای حذف نام کاربری را وارد کنید:" username
					   # کاربر و فهرست خانه آن را حذف کنید
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
			send_stats "تولید کننده اطلاعات کاربر"
			echo "نام کاربری تصادفی"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "نام کاربری تصادفی$i: $username"
			done

			echo ""
			echo "نام تصادفی"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 5 نام کاربری تصادفی ایجاد کنید
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "نام کاربری تصادفی$i: $user_name"
			done

			echo ""
			echo "uuid تصادفی"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "uuid تصادفی$i: $uuid"
			done

			echo ""
			echo "رمز عبور تصادفی 16 بیتی"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "رمز عبور تصادفی$i: $password"
			done

			echo ""
			echo "رمز عبور تصادفی 32 بیتی"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "رمز عبور تصادفی$i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "تغییر منطقه زمانی"
			while true; do
				clear
				echo "اطلاعات زمان سیستم"

				# منطقه زمانی سیستم فعلی را دریافت کنید
				local timezone=$(current_timezone)

				# زمان فعلی سیستم را دریافت کنید
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# منطقه زمانی و زمان را نشان دهید
				echo "منطقه زمانی فعلی سیستم:$timezone"
				echo "زمان فعلی سیستم:$current_time"

				echo ""
				echo "سوئیچینگ منطقه زمانی"
				echo "------------------------"
				echo "آسیا"
				echo "1. زمان شانگهای در چین 2. زمان هنگ کنگ در چین"
				echo "3 زمان توکیو در ژاپن 4. زمان سئول در کره جنوبی"
				echo "5. زمان سنگاپور 6. زمان کلکته در هند"
				echo "7. زمان دبی در امارات 8. زمان سیدنی در استرالیا"
				echo "9. زمان در بانکوک ، تایلند"
				echo "------------------------"
				echo "اروپا"
				echo "11. زمان لندن در انگلستان 12. زمان پاریس در فرانسه"
				echo "13. برلین زمان ، آلمان 14. زمان مسکو ، روسیه"
				echo "15. زمان اوترخت در هلند 16. زمان مادرید در اسپانیا"
				echo "------------------------"
				echo "آمریکا"
				echo "21. زمان غربی 22. زمان شرقی"
				echo "23. زمان کانادا 24. زمان مکزیک"
				echo "25. زمان برزیل 26. زمان آرژانتین"
				echo "------------------------"
				echo "31. UTC زمان استاندارد جهانی"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice


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
		  send_stats "نام میزبان را تغییر دهید"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "نام میزبان فعلی:${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "لطفاً نام میزبان جدید را وارد کنید (0 را برای خروج وارد کنید):" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # سیستم های دیگر مانند Debian ، Ubuntu ، Centos و غیره
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

				  echo "نام میزبان به:$new_hostname"
				  send_stats "نام میزبان تغییر کرده است"
				  sleep 1
			  else
				  echo "خارج شده ، نام میزبان تغییر نکرده است."
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "منبع بروزرسانی سیستم را تغییر دهید"
		  clear
		  echo "منطقه منبع بروزرسانی را انتخاب کنید"
		  echo "برای تغییر منبع به روزرسانی سیستم به LinuxMirrors متصل شوید"
		  echo "------------------------"
		  echo "1. سرزمین اصلی چین [پیش فرض] 2. سرزمین اصلی چین [شبکه آموزش] 3 مناطق خارج از کشور"
		  echo "------------------------"
		  echo "0. به منوی قبلی برگردید"
		  echo "------------------------"
		  read -e -p "انتخاب خود را وارد کنید:" choice

		  case $choice in
			  1)
				  send_stats "منبع پیش فرض در سرزمین اصلی چین"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "منبع آموزش در سرزمین اصلی چین"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "مبداء خارج از کشور"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
				  echo "لغو شده"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "مدیریت وظیفه زمان بندی"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "لیست کار به موقع"
				  crontab -l
				  echo ""
				  echo "عمل کردن"
				  echo "------------------------"
				  echo "1. اضافه کردن وظایف زمان بندی 2. کارهای زمان بندی را حذف کنید."
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "لطفاً دستور اجرای کار جدید را وارد کنید:" newquest
						  echo "------------------------"
						  echo "1. وظایف ماهانه 2. وظایف هفتگی"
						  echo "3 وظایف روزانه 4. وظایف ساعتی"
						  echo "------------------------"
						  read -e -p "لطفا انتخاب خود را وارد کنید:" dingshi

						  case $dingshi in
							  1)
								  read -e -p "انتخاب کنید چه روز از هر ماه برای انجام وظایف؟ (1-30):" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "انتخاب کنید که چه هفته ای برای انجام کار انجام شود؟ (0-6 ، 0 نشان دهنده یکشنبه):" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "انتخاب کنید که هر روز چه زمانی انجام دهید؟ (ساعت ، 0-23):" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "برای انجام کار کدام دقیقه از ساعت را وارد کنید؟ (دقیقه ، 0-60):" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "کارهای به موقع اضافه کنید"
						  ;;
					  2)
						  read -e -p "لطفاً کلمات کلیدی را که باید حذف شوند وارد کنید:" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "کارهای زمان بندی را حذف کنید"
						  ;;
					  3)
						  crontab -e
						  send_stats "کارهای زمان بندی را ویرایش کنید"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "تجزیه میزبان محلی"
			  while true; do
				  clear
				  echo "لیست تجزیه میزبان بومی"
				  echo "اگر مسابقات پارس را در اینجا اضافه کنید ، دیگر از تجزیه پویا استفاده نمی شود"
				  cat /etc/hosts
				  echo ""
				  echo "عمل کردن"
				  echo "------------------------"
				  echo "1. یک تجزیه جدید را اضافه کنید. آدرس تجزیه را حذف کنید"
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" host_dns

				  case $host_dns in
					  1)
						  read -e -p "لطفاً یک فرمت جدید تجزیه و تحلیل را وارد کنید: 110.25.5.5.33 Kejilion.pro:" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "تجزیه میزبان محلی اضافه شده است"

						  ;;
					  2)
						  read -e -p "لطفاً کلمات کلیدی محتوای تجزیه کننده را که باید حذف شوند وارد کنید:" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "تجزیه و حذف میزبان محلی"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "دفاع SSH"
		  while true; do
			if [ -x "$(command -v fail2ban-client)" ] ; then
				clear
				remove fail2ban
				rm -rf /etc/fail2ban
			else
				clear
				docker_name="fail2ban"
				check_docker_app
				echo -e "برنامه دفاعی SSH$check_docker"
				echo "Fail2ban ابزاری SSH برای جلوگیری از نیروی بی رحمانه است"
				echo "معرفی رسمی وب سایت:${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. برنامه دفاع را نصب کنید"
				echo "------------------------"
				echo "2. مشاهده سوابق رهگیری SSH"
				echo "3. نظارت بر ورود به سیستم در زمان واقعی"
				echo "------------------------"
				echo "9. برنامه دفاعی را حذف کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
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
						echo "برنامه دفاعی Fail2ban حذف نشده است"
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
			send_stats "عملکرد خاموش محدودیت فعلی"
			while true; do
				clear
				echo "عملکرد خاموش محدودیت فعلی"
				echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1mc411j7qd؟t=0.1"
				echo "------------------------------------------------"
				echo "استفاده فعلی ترافیک ، راه اندازی مجدد محاسبه ترافیک سرور پاک می شود!"
				output_status
				echo "$output"

				# بررسی کنید که آیا پرونده Limiting_shut_down.sh وجود دارد
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# مقدار آستانه_ gb را دریافت کنید
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}آستانه محدودیت جریان ورودی جریان فعلی: این است:${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}آستانه محدودیت جریان خروجی فعلی:${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}عملکرد خاموش محدود فعلی فعال نیست${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "این سیستم تشخیص می دهد که آیا ترافیک واقعی هر دقیقه به آستانه می رسد و سرور پس از رسیدن به طور خودکار خاموش می شود!"
				echo "------------------------"
				echo "1. عملکرد خاموش کردن محدودیت فعلی را روشن کنید. عملکرد خاموش کردن محدودیت فعلی را غیرفعال کنید"
				echo "------------------------"
				echo "0. به منوی قبلی برگردید"
				echo "------------------------"
				read -e -p "لطفا انتخاب خود را وارد کنید:" Limiting

				case "$Limiting" in
				  1)
					# اندازه حافظه مجازی جدید را وارد کنید
					echo "اگر سرور واقعی دارای 100 گرم ترافیک باشد ، می توان آستانه را روی 95 گرم تنظیم کرده و از قبل برق را خاموش کرد تا از خطاهای ترافیکی یا سرریز جلوگیری شود."
					read -e -p "لطفاً آستانه ترافیک دریافتی را وارد کنید (واحد G ، پیش فرض 100 گرم است):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "لطفاً آستانه ترافیک برون مرزی را وارد کنید (واحد G ، پیش فرض 100 گرم است):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "لطفاً تاریخ تنظیم مجدد ترافیک را وارد کنید (تنظیم مجدد پیش فرض در اول هر ماه):" cz_day
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
					echo "خاموش کردن محدودیت فعلی تنظیم شده است"
					send_stats "خاموش کردن محدودیت فعلی تنظیم شده است"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "عملکرد خاموش کردن محدودیت فعلی خاموش شده است"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "ورود به سیستم خصوصی"
			  while true; do
				  clear
			  	  echo "حالت ورود به سیستم کلید خصوصی"
			  	  echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1q4421x78n؟t=209.4"
			  	  echo "------------------------------------------------"
			  	  echo "یک جفت کلیدی تولید می شود ، یک روش امن تر برای ورود به سیستم SSH"
				  echo "------------------------"
				  echo "1. یک کلید جدید را تولید کنید. یک کلید موجود را وارد کنید 3. کلید بومی را مشاهده کنید"
				  echo "------------------------"
				  echo "0. به منوی قبلی برگردید"
				  echo "------------------------"
				  read -e -p "لطفا انتخاب خود را وارد کنید:" host_dns

				  case $host_dns in
					  1)
				  		send_stats "یک کلید جدید ایجاد کنید"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "یک کلید عمومی موجود را وارد کنید"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "کلید مخفی محلی را مشاهده کنید"
						echo "------------------------"
						echo "اطلاعات کلیدی عمومی"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "اطلاعات کلید خصوصی"
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
			  send_stats "هشدار تلگرام"
			  echo "نظارت بر TG-BOT و عملکرد هشدار زودهنگام"
			  echo "مقدمه ویدیویی: https://youtu.be/vll-eb3z_ty"
			  echo "------------------------------------------------"
			  echo "برای دریافت هشدارهای اولیه برای تحقق نظارت بر زمان واقعی و هشدار زودهنگام CPU ، حافظه ، هارد دیسک ، ترافیک و ورود به سیستم SSH ، باید API TG Robot و ID کاربر را پیکربندی کنید."
			  echo "پس از رسیدن به آستانه ، کاربر به کاربر ارسال می شود"
			  echo -e "${gl_hui}- در مورد ترافیک ، راه اندازی مجدد سرور دوباره محاسبه می شود-${gl_bai}"
			  read -e -p "آیا مطمئناً ادامه خواهید داد؟ (y/n):" choice

			  case "$choice" in
				[Yy])
				  send_stats "هشدار تلگرام فعال است"
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

				  # به پرونده ~/.profile اضافه کنید
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "سیستم هشدار زودهنگام TG-BOT آغاز شده است"
				  echo -e "${gl_hui}You can also place the TG-check-notify.sh warning file in the root directory on other machines and use it directly!${gl_bai}"
				  ;;
				[Nn])
				  echo "لغو شده"
				  ;;
				*)
				  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "آسیب پذیری های پرخطر را در SSH رفع کنید"
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
			  send_stats "تاریخ خط فرمان"
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
			send_stats "صفحه پیام"
			echo "صفحه پیام Lion Technology به جامعه رسمی منتقل شده است! لطفاً پیامی را در جامعه رسمی بگذارید!"
			echo "https://bbs.kejilion.pro/"
			  ;;

		  66)

			  root_use
			  send_stats "تنظیم یک مرحله"
			  echo "بهینه سازی سیستم یک مرحله ای"
			  echo "------------------------------------------------"
			  echo "موارد زیر اداره و بهینه می شود"
			  echo "1. سیستم را به جدیدترین به روز کنید"
			  echo "2. پرونده های ناخواسته سیستم را تمیز کنید"
			  echo -e "3. حافظه مجازی را تنظیم کنید${gl_huang}1G${gl_bai}"
			  echo -e "4. شماره پورت SSH را روی آن تنظیم کنید${gl_huang}5522${gl_bai}"
			  echo -e "5. همه درگاه ها را باز کنید"
			  echo -e "6. روشن کنید${gl_huang}BBR${gl_bai}تسریع کردن"
			  echo -e "7. منطقه زمانی را تنظیم کنید${gl_huang}وابسته به شانگهای${gl_bai}"
			  echo -e "8. به طور خودکار آدرس DNS را بهینه کنید${gl_huang}خارج از کشور: 1.1.1.1 8.8.8.8 داخلی: 223.5.5.5${gl_bai}"
			  echo -e "9. ابزارهای اساسی را نصب کنید${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10. بهینه سازی پارامتر هسته در سیستم لینوکس را تغییر دهید${gl_huang}حالت بهینه سازی متعادل${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "آیا مطمئناً تعمیر و نگهداری یک کلیک دارید؟ (y/n):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "شروع تنظیم یک مرحله ای"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/10. سیستم را به آخرین به روز کنید"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/10. پرونده های ناخواسته سیستم را تمیز کنید"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/10. حافظه مجازی را تنظیم کنید${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/10. شماره پورت SSH را روی تنظیم کنید${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 5/10. همه بنادر را باز کنید"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 6/10. باز${gl_huang}BBR${gl_bai}تسریع کردن"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 7/10. منطقه زمانی را تنظیم کنید${gl_huang}وابسته به شانگهای${gl_bai}"

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
				  echo -e "[${gl_lv}OK${gl_bai}] 8/10. به طور خودکار آدرس DNS را بهینه کنید${gl_huang}${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 9/10. ابزارهای اساسی را نصب کنید${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10. بهینه سازی پارامترهای هسته برای سیستم لینوکس"
				  echo -e "${gl_lv}تنظیم سیستم یک مرحله ای به پایان رسیده است${gl_bai}"

				  ;;
				[Nn])
				  echo "لغو شده"
				  ;;
				*)
				  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "سیستم را مجدداً راه اندازی کنید"
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

			  echo "حریم خصوصی و امنیت"
			  echo "اسکریپت داده هایی را در مورد توابع کاربر جمع آوری می کند ، تجربه اسکریپت را بهینه می کند و عملکردهای سرگرم کننده و مفید تری ایجاد می کند."
			  echo "شماره نسخه اسکریپت ، زمان استفاده ، نسخه سیستم ، معماری CPU ، کشور دستگاه و نام عملکرد مورد استفاده را جمع آوری می کند."
			  echo "------------------------------------------------"
			  echo -e "وضعیت فعلی:$status_message"
			  echo "--------------------"
			  echo "1. مجموعه را روشن کنید"
			  echo "2. مجموعه را ببندید"
			  echo "--------------------"
			  echo "0. به منوی قبلی برگردید"
			  echo "--------------------"
			  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "مجموعه فعال شده است"
					  send_stats "جمع آوری حریم خصوصی و امنیت فعال شده است"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "مجموعه بسته"
					  send_stats "حریم خصوصی و امنیت برای جمع آوری بسته شده است"
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
			  send_stats "حذف اسکریپت شیر ​​فناوری"
			  echo "حذف اسکریپت شیر ​​فناوری"
			  echo "------------------------------------------------"
			  echo "اسکریپت kejilion را کاملاً حذف کرده و بر عملکردهای دیگر شما تأثیر نمی گذارد"
			  read -e -p "آیا مطمئناً ادامه خواهید داد؟ (y/n):" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "فیلمنامه حذف شده است ، خداحافظ!"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "لغو شده"
				  ;;
				*)
				  echo "انتخاب نامعتبر ، لطفاً Y یا N را وارد کنید."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "ورودی نامعتبر!"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "مدیر پرونده"
	while true; do
		clear
		echo "مدیر پرونده"
		echo "------------------------"
		echo "مسیر فعلی"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. دایرکتوری را وارد کنید 2. دایرکتوری را ایجاد کنید. مجوزهای فهرست را تغییر دهید."
		echo "5. فهرست را حذف کنید 6. به فهرست منو قبلی برگردید"
		echo "------------------------"
		echo "11. یک پرونده 12 ایجاد کنید. یک پرونده را ویرایش کنید."
		echo "15. پرونده را حذف کنید"
		echo "------------------------"
		echo "21. دایرکتوری پرونده فشرده 22. فهرست پرونده unzip 23. فهرست پرونده های پرونده 24. کپی کردن دایرکتوری پرونده"
		echo "25. پرونده را به سرور دیگری منتقل کنید"
		echo "------------------------"
		echo "0. به منوی قبلی برگردید"
		echo "------------------------"
		read -e -p "لطفا انتخاب خود را وارد کنید:" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "لطفاً نام دایرکتوری را وارد کنید:" dirname
				cd "$dirname" 2>/dev/null || echo "ورود به دایرکتوری امکان پذیر نیست"
				send_stats "به دایرکتوری بروید"
				;;
			2)  # 创建目录
				read -e -p "لطفاً نام دایرکتوری را وارد کنید تا ایجاد کنید:" dirname
				mkdir -p "$dirname" && echo "دایرکتوری ایجاد شده است" || echo "آفرینش شکست خورد"
				send_stats "دایرکتوری ایجاد کنید"
				;;
			3)  # 修改目录权限
				read -e -p "لطفاً نام دایرکتوری را وارد کنید:" dirname
				read -e -p "لطفاً مجوزها را وارد کنید (مانند 755):" perm
				chmod "$perm" "$dirname" && echo "مجوزها اصلاح شده اند" || echo "اصلاح انجام نشد"
				send_stats "مجوزهای فهرست را اصلاح کنید"
				;;
			4)  # 重命名目录
				read -e -p "لطفاً نام فهرست فعلی را وارد کنید:" current_name
				read -e -p "لطفاً نام دایرکتوری جدید را وارد کنید:" new_name
				mv "$current_name" "$new_name" && echo "دایرکتوری تغییر نام داده است" || echo "تغییر نام انجام نشد"
				send_stats "تغییر نام دایرکتوری"
				;;
			5)  # 删除目录
				read -e -p "لطفاً نام دایرکتوری را وارد کنید تا حذف شود:" dirname
				rm -rf "$dirname" && echo "فهرست حذف شده است" || echo "حذف انجام نشد"
				send_stats "فهرست را حذف کنید"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "به فهرست منوی قبلی برگردید"
				;;
			11) # 创建文件
				read -e -p "لطفاً نام پرونده را برای ایجاد وارد کنید:" filename
				touch "$filename" && echo "پرونده ایجاد شده است" || echo "آفرینش شکست خورد"
				send_stats "یک فایل ایجاد کنید"
				;;
			12) # 编辑文件
				read -e -p "لطفاً نام پرونده را برای ویرایش وارد کنید:" filename
				install nano
				nano "$filename"
				send_stats "پرونده ها را ویرایش کنید"
				;;
			13) # 修改文件权限
				read -e -p "لطفاً نام پرونده را وارد کنید:" filename
				read -e -p "لطفاً مجوزها را وارد کنید (مانند 755):" perm
				chmod "$perm" "$filename" && echo "مجوزها اصلاح شده اند" || echo "اصلاح انجام نشد"
				send_stats "مجوزهای پرونده را اصلاح کنید"
				;;
			14) # 重命名文件
				read -e -p "لطفاً نام پرونده فعلی را وارد کنید:" current_name
				read -e -p "لطفاً یک نام پرونده جدید وارد کنید:" new_name
				mv "$current_name" "$new_name" && echo "پرونده تغییر نام داد" || echo "تغییر نام انجام نشد"
				send_stats "تغییر نام پرونده"
				;;
			15) # 删除文件
				read -e -p "لطفاً نام پرونده را وارد کنید تا حذف شود:" filename
				rm -f "$filename" && echo "پرونده حذف شده است" || echo "حذف انجام نشد"
				send_stats "پرونده ها را حذف کنید"
				;;
			21) # 压缩文件/目录
				read -e -p "لطفاً نام پرونده/دایرکتوری را وارد کنید تا فشرده شود:" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "فشرده به$name.tar.gz" || echo "فشرده سازی انجام نشد"
				send_stats "پرونده ها/دایرکتوری های فشرده شده"
				;;
			22) # 解压文件/目录
				read -e -p "لطفاً نام پرونده را وارد کنید (.tar.gz):" filename
				install tar
				tar -xzvf "$filename" && echo "فشرده شده$filename" || echo "رفع فشار انجام نشد"
				send_stats "پرونده ها/دایرکتوری ها"
				;;

			23) # 移动文件或目录
				read -e -p "لطفاً برای حرکت پرونده یا مسیر دایرکتوری را وارد کنید:" src_path
				if [ ! -e "$src_path" ]; then
					echo "خطا: پرونده یا فهرست وجود ندارد."
					send_stats "جابجایی پرونده یا دایرکتوری انجام نشد: پرونده یا دایرکتوری وجود ندارد"
					continue
				fi

				read -e -p "لطفاً مسیر هدف را وارد کنید (از جمله نام پرونده جدید یا نام دایرکتوری):" dest_path
				if [ -z "$dest_path" ]; then
					echo "خطا: لطفاً مسیر هدف را وارد کنید."
					send_stats "فایل یا فهرست جابجایی انجام نشد: مسیر مقصد مشخص نشده است"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "پرونده یا دایرکتوری به$dest_path" || echo "جابجایی پرونده ها یا دایرکتوری ها انجام نشد"
				send_stats "جابجایی پرونده ها یا دایرکتوری ها"
				;;


		   24) # 复制文件目录
				read -e -p "لطفاً برای کپی کردن پرونده یا مسیر دایرکتوری را وارد کنید:" src_path
				if [ ! -e "$src_path" ]; then
					echo "خطا: پرونده یا فهرست وجود ندارد."
					send_stats "کپی کردن یک پرونده یا دایرکتوری انجام نشد: پرونده یا دایرکتوری وجود ندارد"
					continue
				fi

				read -e -p "لطفاً مسیر هدف را وارد کنید (از جمله نام پرونده جدید یا نام دایرکتوری):" dest_path
				if [ -z "$dest_path" ]; then
					echo "خطا: لطفاً مسیر هدف را وارد کنید."
					send_stats "کپی کردن پرونده یا دایرکتوری انجام نشد: مسیر مقصد مشخص نشده است"
					continue
				fi

				# از گزینه -r برای کپی مجدد دایرکتوری استفاده کنید
				cp -r "$src_path" "$dest_path" && echo "پرونده یا دایرکتوری در آن کپی شده است$dest_path" || echo "کپی کردن یک پرونده یا فهرست انجام نشد"
				send_stats "کپی کردن پرونده ها یا دایرکتوری ها"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "لطفاً مسیر فایل را برای انتقال وارد کنید:" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "خطا: پرونده وجود ندارد."
					send_stats "انتقال پرونده انجام نشد: پرونده وجود ندارد"
					continue
				fi

				read -e -p "لطفاً IP از راه دور سرور را وارد کنید:" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "خطا: لطفاً IP از راه دور سرور را وارد کنید."
					send_stats "انتقال پرونده انجام نشد: IP از راه دور سرور وارد نشده است"
					continue
				fi

				read -e -p "لطفاً نام کاربری سرور از راه دور (ریشه پیش فرض) را وارد کنید:" remote_user
				remote_user=${remote_user:-root}

				read -e -p "لطفاً رمز عبور سرور از راه دور را وارد کنید:" -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "خطا: لطفاً رمز عبور سرور از راه دور را وارد کنید."
					send_stats "انتقال پرونده انجام نشد: رمز عبور سرور از راه دور وارد نشده است"
					continue
				fi

				read -e -p "لطفاً درگاه ورود را وارد کنید (پیش فرض 22):" remote_port
				remote_port=${remote_port:-22}

				# ورودی های قدیمی را برای میزبان های شناخته شده پاک کنید
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# انتقال پرونده ها با استفاده از SCP
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "این پرونده به دایرکتوری خانه از راه دور سرور منتقل شده است."
					send_stats "انتقال پرونده با موفقیت"
				else
					echo "انتقال پرونده انجام نشد."
					send_stats "انتقال پرونده انجام نشد"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "به منوی منوی قبلی برگردید"
				break
				;;
			*)  # 处理无效输入
				echo "انتخاب نامعتبر ، لطفا دوباره وارد شوید"
				send_stats "انتخاب نامعتبر"
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

	# تبدیل اطلاعات استخراج شده به یک آرایه
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# از طریق سرور تکرار کنید و دستورات را اجرا کنید
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}وصل کردن به$name ($hostname)...${gl_bai}"
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
	  send_stats "مرکز کنترل خوشه"
	  echo "کنترل خوشه سرور"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}مدیریت لیست سرور${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}یک سرور اضافه کنید${gl_kjlan}2.  ${gl_bai}سرور را حذف کنید${gl_kjlan}3.  ${gl_bai}ویرایش سرور"
	  echo -e "${gl_kjlan}4.  ${gl_bai}خوشه${gl_kjlan}5.  ${gl_bai}بازگرداندن خوشه"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}وظایف را در دسته ها انجام دهید${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}اسکریپت شیر ​​فنی را نصب کنید${gl_kjlan}12. ${gl_bai}سیستم را به روز کنید${gl_kjlan}13. ${gl_bai}سیستم را تمیز کنید"
	  echo -e "${gl_kjlan}14. ${gl_bai}داکر را نصب کنید${gl_kjlan}15. ${gl_bai}BBR3 را نصب کنید${gl_kjlan}16. ${gl_bai}حافظه مجازی 1G را تنظیم کنید"
	  echo -e "${gl_kjlan}17. ${gl_bai}منطقه زمانی را به شانگهای تنظیم کنید${gl_kjlan}18. ${gl_bai}همه بنادر را باز کنید${gl_kjlan}51. ${gl_bai}دستورات سفارشی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}بازگشت به منوی اصلی"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "لطفا انتخاب خود را وارد کنید:" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "یک سرور خوشه اضافه کنید"
			  read -e -p "نام سرور:" server_name
			  read -e -p "IP سرور:" server_ip
			  read -e -p "درگاه سرور (22):" server_port
			  local server_port=${server_port:-22}
			  read -e -p "نام کاربری سرور (ریشه):" server_username
			  local server_username=${server_username:-root}
			  read -e -p "رمز عبور کاربر سرور:" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "سرور خوشه را حذف کنید"
			  read -e -p "لطفاً کلمات کلیدی مورد نیاز برای حذف را وارد کنید:" rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "سرور خوشه را ویرایش کنید"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "خوشه"
			  echo -e "لطفا${gl_huang}/root/cluster/servers.py${gl_bai}فایل را بارگیری کنید و نسخه پشتیبان تهیه کنید!"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "بازگرداندن خوشه"
			  echo "لطفاً Servers.py خود را بارگذاری کرده و برای شروع بارگذاری ، هر کلید را فشار دهید!"
			  echo -e "لطفا خود را بارگذاری کنید${gl_huang}servers.py${gl_bai}پرونده به${gl_huang}/root/cluster/${gl_bai}بازیابی را کامل کنید!"
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
			  send_stats "اجرای دستورات را سفارشی کنید"
			  read -e -p "لطفاً دستور اجرای دسته را وارد کنید:" mingling
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
send_stats "ستون تبلیغاتی"
echo "ستون تبلیغاتی"
echo "------------------------"
echo "این یک تجربه تبلیغی و خرید ساده تر و زیبا تر را در اختیار کاربران قرار می دهد!"
echo ""
echo -e "پیشنهادات سرور"
echo "------------------------"
echo -e "${gl_lan}Leica Cloud Hong Kong CN2 GIA کره جنوبی دوتایی ISP US CN2 GIA تخفیف${gl_bai}"
echo -e "${gl_bai}وب سایت: https://www.lcayun.com/aff/zexuqbim${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}Racknerd 10.99 دلار در سال ایالات متحده 1 هسته اصلی 1G حافظه 20G هارد 1T ترافیک در هر ماه${gl_bai}"
echo -e "${gl_bai}وب سایت: https://my.racknerd.com/aff.php؟aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52.7 دلار در سال ایالات متحده 1 Core 4g Memory 50G هارد 4T ترافیک در هر ماه${gl_bai}"
echo -e "${gl_bai}وب سایت: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f؟_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}آجر کننده ، 49 دلار در هر سه ماهه ، CN2GIA ایالات متحده ، ژاپن Softbank ، 2 هسته ، حافظه 1 گرم ، هارد 20 گرم ، ترافیک 1T در هر ماه${gl_bai}"
echo -e "${gl_bai}وب سایت: https://bandwagonhost.com/aff.php؟aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT 28 دلار در هر سه ماهه CN2GIA 1 CORE 2G حافظه 20G هارد 800 گرم ترافیک در هر ماه${gl_bai}"
echo -e "${gl_bai}وب سایت: https://www.dmit.io/aff.php؟aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS 6.9 دلار در هر ماه توکیو SoftBank 2 هسته 1G حافظه 20G هارد 1T ترافیک در هر ماه${gl_bai}"
echo -e "${gl_bai}وب سایت: https://vps.hosting/cart/tokyo-cloud-kvm-vps/؟id=148&؟affid=1355&؟affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}پیشنهادات VPS محبوب تر${gl_bai}"
echo -e "${gl_bai}وب سایت: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "تخفیف نام دامنه"
echo "------------------------"
echo -e "${gl_lan}GNAME 8.8 دلار نام دامنه COM سال اول 6.68 دلار نام دامنه CC سال اول${gl_bai}"
echo -e "${gl_bai}وب سایت: https://www.gname.com/register؟tt=86836&ttcode=kejilion86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "شیر فناوری اطراف"
echo "------------------------"
echo -e "${gl_kjlan}ایستگاه ب:${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}لوله روغن:${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}وب سایت رسمی:${gl_bai}https://kejilion.pro/               ${gl_kjlan}ناوبری:${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}وبلاگ:${gl_bai}https://blog.kejilion.pro/          ${gl_kjlan}مرکز نرم افزار:${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "به روزرسانی اسکریپت"
cd ~
while true; do
	clear
	echo "گزارش به روزرسانی"
	echo "------------------------"
	echo "همه گزارش ها:${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}شما در حال حاضر آخرین نسخه هستید!${gl_huang}v$sh_v${gl_bai}"
		send_stats "اسکریپت به روز است و به روزرسانی لازم نیست"
	else
		echo "نسخه جدیدی را کشف کنید!"
		echo -e "نسخه فعلی V$sh_vآخرین نسخه${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}به روزرسانی خودکار فعال است و اسکریپت هر روز به طور خودکار ساعت 2 صبح به روز می شود!${gl_bai}"
	fi

	echo "------------------------"
	echo "1. به روز کنید اکنون 2. بروزرسانی خودکار را روشن کنید. به روزرسانی خودکار را خاموش کنید"
	echo "------------------------"
	echo "0. به منوی اصلی برگردید"
	echo "------------------------"
	read -e -p "لطفا انتخاب خود را وارد کنید:" choice
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
			echo -e "${gl_lv}اسکریپت به آخرین نسخه به روز شده است!${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "فیلمنامه به روز است$sh_v_new"
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
			echo -e "${gl_lv}به روزرسانی خودکار فعال است و اسکریپت هر روز به طور خودکار ساعت 2 صبح به روز می شود!${gl_bai}"
			send_stats "بروزرسانی خودکار اسکریپت را روشن کنید"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}به روزرسانی خودکار بسته است${gl_bai}"
			send_stats "به روزرسانی خودکار اسکریپت را ببندید"
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
echo -e "جعبه ابزار Script Lion Technology V$sh_v"
echo -e "ورودی خط فرمان${gl_huang}k${gl_kjlan}سریع اسکریپت ها را شروع کنید${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}پرس و جو اطلاعاتی سیستم"
echo -e "${gl_kjlan}2.   ${gl_bai}بروزرسانی سیستم"
echo -e "${gl_kjlan}3.   ${gl_bai}پاکسازی سیستم"
echo -e "${gl_kjlan}4.   ${gl_bai}ابزارهای اساسی"
echo -e "${gl_kjlan}5.   ${gl_bai}مدیریت BBR"
echo -e "${gl_kjlan}6.   ${gl_bai}مدیریت داکر"
echo -e "${gl_kjlan}7.   ${gl_bai}مدیریت پیچ و خم"
echo -e "${gl_kjlan}8.   ${gl_bai}مجموعه اسکریپت تست"
echo -e "${gl_kjlan}9.   ${gl_bai}مجموعه اسکریپت Oracle Cloud"
echo -e "${gl_huang}10.  ${gl_bai}ساختمان وب سایت LDNMP"
echo -e "${gl_kjlan}11.  ${gl_bai}بازار کاربرد"
echo -e "${gl_kjlan}12.  ${gl_bai}فضای کاری من"
echo -e "${gl_kjlan}13.  ${gl_bai}ابزار سیستم"
echo -e "${gl_kjlan}14.  ${gl_bai}کنترل خوشه سرور"
echo -e "${gl_kjlan}15.  ${gl_bai}ستون تبلیغاتی"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}اسکریپت افتتاح سرور Palu Palu Phantom Beast"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}به روزرسانی اسکریپت"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}اسکریپت خروجی"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "لطفا انتخاب خود را وارد کنید:" choice

case $choice in
  1) linux_ps ;;
  2) clear ; send_stats "بروزرسانی سیستم" ; linux_update ;;
  3) clear ; send_stats "پاکسازی سیستم" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "مدیریت پیچ و خم" ; install wget
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
  p) send_stats "اسکریپت افتتاح سرور Palu Palu Phantom Beast" ; cd ~
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "ورودی نامعتبر!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k مورد استفاده مرجع فرمان"
echo "-------------------"
echo "مقدمه ویدیویی: https://www.bilibili.com/video/bv1ib421e7it؟t=0.1"
echo "موارد زیر مورد استفاده مرجع فرمان K است:"
echo "شروع اسکریپت k"
echo "نصب بسته نرم افزاری k نصب nano wget | k اضافه کردن نانو wget | k نصب نانو wget"
echo "بسته بندی k حذف nano wget | K Del Nano Wget | k حذف نانو wget | k حذف نانو wget"
echo "به روزرسانی سیستم K به روزرسانی | k به روزرسانی"
echo "زباله های سیستم تمیز K Clean | k تمیز"
echo "نصب مجدد صفحه سیستم k dd | k نصب مجدد"
echo "کنترل پنل BBR3 K BBR3 | k bbrv3"
echo "پنل تنظیم هسته K NHYH | بهینه سازی هسته"
echo "تنظیم حافظه مجازی k مبادله 2048"
echo "تنظیم منطقه زمانی مجازی k زمان آسیا/شانگهای | k منطقه زمانی آسیا/شانگهای"
echo "سطل زباله بازیافت سیستم | K HSZ | سطل بازیافت k"
echo "عملکرد پشتیبان گیری از سیستم K Backup | k bf | پشتیبان گیری K"
echo "ابزار اتصال از راه دور SSH K SSH | k اتصال از راه دور"
echo "ابزار همگام سازی از راه دور RSYNC K RSYNC | k هماهنگ سازی از راه دور"
echo "ابزار مدیریت دیسک سخت دیسک k | مدیریت دیسک سخت"
echo "نفوذ Intranet (سمت سرور) K FRPS"
echo "نفوذ Intranet (مشتری) K FRPC"
echo "نرم افزار شروع K شروع SSHD | k شروع SSHD"
echo "نرم افزار STOP K STOP SSHD | k متوقف SSHD"
echo "راه اندازی مجدد نرم افزار K Restart SSHD | k راه اندازی مجدد SSHD"
echo "مشاهده وضعیت نرم افزار وضعیت K SSHD | K وضعیت SSHD"
echo "نرم افزار بوت K فعال کردن Docker | k autostart docke | k Docker Startup"
echo "گواهی نام دامنه برنامه K SSL"
echo "نام دامنه گواهینامه انقضاء k ssl ps"
echo "نصب محیط Docker نصب K Docker | K Docker نصب"
echo "Docker Container Management K Docker PS | K Docker Container"
echo "docker镜像管理      k docker img |k docker 镜像"
echo "مدیریت سایت LDNMP K وب"
echo "پاک کردن حافظه پنهان LDNMP k حافظه نهان"
echo "نصب وردپرس k wp | k وردپرس | k wp xxx.com"
echo "پروکسی معکوس k fd | k rp | k anti-generation | k fd xxx.com"
echo "نصب بار تعادل K LoadBalance | K متعادل کننده بار"
echo "صفحه فایروال K FHQ | K فایروال"
echo "Open Port K DKDK 8080 | K درگاه باز 8080"
echo "بستن بندر K GBDK 7800 | K نزدیک بندر 7800"
echo "انتشار IP K fxip 127.0.0.0/8 | k نسخه IP 127.0.0.0/8"
echo "Block IP K Zzip 177.5.25.36 | K بلوک IP 177.5.25.36"


}



if [ "$#" -eq 0 ]; then
	# اگر پارامتری وجود ندارد ، منطق تعاملی را اجرا کنید
	kejilion_sh
else
	# اگر پارامترهایی وجود دارد ، عملکرد مربوطه را اجرا کنید
	case $1 in
		install|add|安装)
			shift
			send_stats "نصب نرم افزار"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "نرم افزار را حذف نصب کنید"
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
			send_stats "همگام سازی RSYNC به موقع"
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
			send_stats "به سرعت حافظه مجازی را تنظیم کنید"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "به سرعت منطقه زمانی را تنظیم کنید"
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
			send_stats "نمای وضعیت نرم افزار"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "راه اندازی نرم افزار"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "مکث نرم افزاری"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "راه اندازی مجدد نرم افزار"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "چکمه های نرم افزاری بالا"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "وضعیت گواهی را بررسی کنید"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "به سرعت برای یک گواهی درخواست کنید"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "به سرعت برای یک گواهی درخواست کنید"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "داکر را به سرعت نصب کنید"
					install_docker
					;;
				ps|容器)
					send_stats "مدیریت سریع کانتینر"
					docker_ps
					;;
				img|镜像)
					send_stats "مدیریت سریع آینه"
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
