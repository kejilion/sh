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



# Определите функцию для выполнения команд
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



# Функции, которые собирают функцию, захороненную информацию о том, записывают текущий номер версии сценария, время использования, системную версию, архитектуру ЦП, страну машины и имя функции, используемое пользователем. Они абсолютно не включают конфиденциальную информацию, пожалуйста, будьте уверены! Пожалуйста, поверьте мне!
# Зачем нам разработать эту функцию? Цель состоит в том, чтобы лучше понять функции, которые пользователи любят использовать, и еще больше оптимизировать функции, чтобы запустить больше функций, которые удовлетворяют потребности пользователей.
# Для полного текста вы можете искать местоположение вызова функции Send_stats, прозрачный и открытый исходный код, и вы можете отказаться использовать его, если у вас есть какие -либо проблемы.



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

# Позвольте пользователю согласиться с условиями
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}Добро пожаловать в The Tech Lion Script Toolbox${gl_bai}"
	echo "Впервые используя сценарий, пожалуйста, прочитайте и согласитесь с пользовательским лицензионным соглашением."
	echo "Пользовательский лицензионный соглашение: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "Вы согласны с вышеуказанными условиями? (Y/N):" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "Лицензионное согласие"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "Отказ от разрешения"
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
		echo "Параметры пакета не предоставляются!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}Установка$package...${gl_bai}"
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
				echo "Неизвестный менеджер пакетов!"
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
		echo -e "${gl_huang}намекать:${gl_bai}Недостаточное пространство диска!"
		echo "Текущее доступное пространство: $ ((доступен_space_mb/1024)) g"
		echo "Минимальное пространство спроса:${required_gb}G"
		echo "Установка не может быть продолжена. Пожалуйста, очистите пространство диска и попробуйте еще раз."
		send_stats "Недостаточно дискового пространства"
		break_end
		kejilion
	fi
}


install_dependency() {
	install wget unzip tar jq
}

remove() {
	if [ $# -eq 0 ]; then
		echo "Параметры пакета не предоставляются!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}Удаление$package...${gl_bai}"
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
			echo "Неизвестный менеджер пакетов!"
			return 1
		fi
	done
}


# Универсальная функция SystemCtl, подходящая для различных распределений
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# Перезагрузите услугу
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1Служба была перезапущена."
	else
		echo "Ошибка: перезапуск$1Служба не удалась."
	fi
}

# Начните сервис
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1Служба была начата."
	else
		echo "Ошибка: запуск$1Служба не удалась."
	fi
}

# Остановить обслуживание
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1Служба была остановлена."
	else
		echo "Ошибка: остановиться$1Служба не удалась."
	fi
}

# Проверьте статус службы
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1Статус службы отображается."
	else
		echo "Ошибка: невозможно отобразить$1Служба статуса."
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAMEУстановить на питание."
}



break_end() {
	  echo -e "${gl_lv}Операция завершена${gl_bai}"
	  echo "Нажмите любую клавишу, чтобы продолжить ..."
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
	echo -e "${gl_huang}Установка среды Docker ...${gl_bai}"
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
	send_stats "Управление контейнерами Docker"
	echo "Список контейнеров Docker"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "Работа контейнера"
	echo "------------------------"
	echo "1. Создать новый контейнер"
	echo "------------------------"
	echo "2. Запустите указанный контейнер 6. Запустите все контейнеры"
	echo "3. Остановите указанный контейнер 7. Остановите все контейнеры"
	echo "4. Удалить указанный контейнер 8. Удалить все контейнеры"
	echo "5. Перезагрузите указанный контейнер 9. Перезапустите все контейнеры"
	echo "------------------------"
	echo "11. Введите указанный контейнер 12. Просмотреть журнал контейнера"
	echo "13. Просмотреть сеть контейнеров 14. Просмотреть занятость контейнера"
	echo "------------------------"
	echo "0. Вернитесь в предыдущее меню"
	echo "------------------------"
	read -e -p "Пожалуйста, введите свой выбор:" sub_choice
	case $sub_choice in
		1)
			send_stats "Создать новый контейнер"
			read -e -p "Пожалуйста, введите команду Creation:" dockername
			$dockername
			;;
		2)
			send_stats "Запустите указанный контейнер"
			read -e -p "Пожалуйста, введите имя контейнера (несколько имен контейнеров, разделенных пространствами):" dockername
			docker start $dockername
			;;
		3)
			send_stats "Остановить указанный контейнер"
			read -e -p "Пожалуйста, введите имя контейнера (несколько имен контейнеров, разделенных пространствами):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "Удалить указанный контейнер"
			read -e -p "Пожалуйста, введите имя контейнера (несколько имен контейнеров, разделенных пространствами):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "Перезагрузить указанный контейнер"
			read -e -p "Пожалуйста, введите имя контейнера (несколько имен контейнеров, разделенных пространствами):" dockername
			docker restart $dockername
			;;
		6)
			send_stats "Начните все контейнеры"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "Остановите все контейнеры"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "Удалить все контейнеры"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "Неверный выбор, пожалуйста, введите Y или N."
				;;
			esac
			;;
		9)
			send_stats "Перезапустите все контейнеры"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "Введите контейнер"
			read -e -p "Пожалуйста, введите имя контейнера:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "Просмотреть журнал контейнеров"
			read -e -p "Пожалуйста, введите имя контейнера:" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "Просмотреть контейнерные сеть"
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
			send_stats "Просмотреть занятость контейнера"
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
	send_stats "Docker Management"
	echo "Список изображений Docker"
	docker image ls
	echo ""
	echo "Зеркальная операция"
	echo "------------------------"
	echo "1. Получите указанное изображение 3. Удалить указанное изображение"
	echo "2. Обновите указанное изображение 4. Удалить все изображения"
	echo "------------------------"
	echo "0. Вернитесь в предыдущее меню"
	echo "------------------------"
	read -e -p "Пожалуйста, введите свой выбор:" sub_choice
	case $sub_choice in
		1)
			send_stats "Потяните зеркало"
			read -e -p "Пожалуйста, введите имя зеркала (пожалуйста, разделяйте несколько имен зеркала с пробелами):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}Получение изображения:$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "Обновите изображение"
			read -e -p "Пожалуйста, введите имя зеркала (пожалуйста, разделяйте несколько имен зеркала с пробелами):" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}Обновленное изображение:$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "Удалить зеркало"
			read -e -p "Пожалуйста, введите имя зеркала (пожалуйста, разделяйте несколько имен зеркала с пробелами):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "Удалить все изображения"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "Неверный выбор, пожалуйста, введите Y или N."
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
				echo "Неподдерживаемые распределения:$ID"
				return
				;;
		esac
	else
		echo "Операционная система не может быть определена."
		return
	fi

	echo -e "${gl_lv}Crontab установлен, а сервис Cron работает.${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# Проверьте, существует ли файл конфигурации, создайте файл и напишите настройки по умолчанию, если его не существует
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# Используйте JQ для обработки обновлений файлов конфигурации
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# Проверьте, есть ли текущая конфигурация уже есть настройки IPv6
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# Обновить конфигурацию и включить IPv6
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# Сравнение исходной конфигурации с новой конфигурацией
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}Доступ к IPv6 в настоящее время включен${gl_bai}"
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

	# Проверьте, существует ли файл конфигурации
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}Файла конфигурации не существует${gl_bai}"
		return
	fi

	# Прочитайте текущую конфигурацию
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# Используйте JQ для обработки обновлений файлов конфигурации
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# Проверьте текущий статус IPv6
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# Сравнение исходной конфигурации с новой конфигурацией
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}Доступ к IPv6 в настоящее время закрыт${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}Доступ к IPv6 был успешно закрыт${gl_bai}"
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
		echo "Пожалуйста, предоставьте хотя бы один номер порта"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# Удалить существующие правила закрытия
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# Добавьте открытые правила
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "Порт был открыт$port"
		fi
	done

	save_iptables_rules
	send_stats "Порт был открыт"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "Пожалуйста, предоставьте хотя бы один номер порта"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# Удалить существующие открытые правила
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# Добавить правило
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "Порт закрыт$port"
		fi
	done

	save_iptables_rules
	send_stats "Порт закрыт"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "Пожалуйста, предоставьте хотя бы один IP -адрес или IP -сегмент"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# Удалить существующие правила блокировки
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# Добавить разрешить правила
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "Выпущен IP$ip"
		fi
	done

	save_iptables_rules
	send_stats "Выпущен IP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "Пожалуйста, предоставьте хотя бы один IP -адрес или IP -сегмент"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# Удалить существующие разрешения правил
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# Добавить правила блокировки
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IP заблокирован$ip"
		fi
	done

	save_iptables_rules
	send_stats "IP заблокирован"
}







enable_ddos_defense() {
	# Включите оборону DDOS
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "Включите защиту DDOS"
}

# Выключить защиту DDOS
disable_ddos_defense() {
	# Выключить защиту DDOS
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "Выключить защиту DDOS"
}





# Функции, которые управляют национальными правилами ИС
manage_country_rules() {
	local action="$1"
	local country_code="$2"
	local ipset_name="${country_code,,}_block"
	local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

	install ipset

	case "$action" in
		block)
			# Создайте, если IPSet не существует
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# Скачать файл IP области
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "Ошибка: скачать$country_codeФайл IP Zone не удастся"
				exit 1
			fi

			# Добавить IP в IPSet
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# Block IP с помощью iptables
			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
			iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

			echo "Заблокировано успешно$country_codeIP -адрес"
			rm "${country_code,,}.zone"
			;;

		allow)
			# Создайте IPSet для разрешенных стран (если нет)
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# Скачать файл IP области
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "Ошибка: скачать$country_codeФайл IP Zone не удастся"
				exit 1
			fi

			# Удалить существующие национальные правила
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null
			ipset flush "$ipset_name"

			# Добавить IP в IPSet
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# Разрешены только IPS в назначенных странах
			iptables -P INPUT DROP
			iptables -P OUTPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
			iptables -A OUTPUT -m set --match-set "$ipset_name" dst -j ACCEPT

			echo "Успешно разрешено$country_codeIP -адрес"
			rm "${country_code,,}.zone"
			;;

		unblock)
			# Удалить правила iptables для страны
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null

			# Уничтожить IPSet
			if ipset list "$ipset_name" &> /dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "Успешно поднялся$country_codeОграничения IP -адреса"
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
		  echo "Продвинутый управление брандмауэром"
		  send_stats "Продвинутый управление брандмауэром"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "Управление брандмауэром"
		  echo "------------------------"
		  echo "1. Откройте указанный порт 2. Закройте указанный порт"
		  echo "3. Откройте все порты 4. Закройте все порты"
		  echo "------------------------"
		  echo "5. IP WhiteList 6. IP Blacklist"
		  echo "7. Очистить указанный IP"
		  echo "------------------------"
		  echo "11. разрешить пинг 12. Отключить пинг"
		  echo "------------------------"
		  echo "13. Начать защиту DDOS 14. Выключите защиту DDOS"
		  echo "------------------------"
		  echo "15. Блок Указанный страна IP 16. Разрешены только указанная страна IPS"
		  echo "17. Выпустите ограничения IP в назначенных странах"
		  echo "------------------------"
		  echo "0. Вернитесь в предыдущее меню"
		  echo "------------------------"
		  read -e -p "Пожалуйста, введите свой выбор:" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "Пожалуйста, введите номер открытого порта:" o_port
				  open_port $o_port
				  send_stats "Откройте указанный порт"
				  ;;
			  2)
				  read -e -p "Пожалуйста, введите закрытый номер порта:" c_port
				  close_port $c_port
				  send_stats "Закрыть указанный порт"
				  ;;
			  3)
				  # Откройте все порты
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
				  send_stats "Откройте все порты"
				  ;;
			  4)
				  # Закройте все порты
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
				  send_stats "Закройте все порты"
				  ;;

			  5)
				  # IP Whitelist
				  read -e -p "Пожалуйста, введите сегмент IP или IP, чтобы выпустить:" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IP Blacklist
				  read -e -p "Пожалуйста, введите заблокированный IP или IP -сегмент:" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # Очистить указанный IP
				  read -e -p "Пожалуйста, введите очищенный IP:" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "Очистить указанный IP"
				  ;;
			  11)
				  # Разрешить пинг
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "Разрешить пинг"
				  ;;
			  12)
				  # Отключить пинг
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "Отключить пинг"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "Пожалуйста, введите заблокированный код страны (например, CN, US, JP):" country_code
				  manage_country_rules block $country_code
				  send_stats "Разрешен страны$country_codeIP"
				  ;;
			  16)
				  read -e -p "Пожалуйста, введите разрешенный код страны (например, CN, US, JP):" country_code
				  manage_country_rules allow $country_code
				  send_stats "Заблокировать страну$country_codeIP"
				  ;;

			  17)
				  read -e -p "Пожалуйста, введите код очищенной страны (например, CN, US, JP):" country_code
				  manage_country_rules unblock $country_code
				  send_stats "Очистить страну$country_codeIP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}








add_swap() {
	local new_swap=$1  # 获取传入的参数

	# Получить все перегородки в текущей системе
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# Итерация и удаление всех перегородков обмена
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# Убедитесь, что /Swapfile больше не используется
	swapoff /swapfile

	# Удалить старый /Swapfile
	rm -f /swapfile

	# Создать новый перегородка
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

	echo -e "Размер виртуальной памяти был изменен на${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# Определите, нужно ли создать виртуальную память
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # Получите версию Nginx
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # Получите версию MySQL
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # Получите версию PHP
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # Получить версию Redis
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # Создать необходимые каталоги и файлы
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf
  wget -O /home/web/redis/valkey.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/valkey.conf


  default_server_ssl

  # Загрузите файл docker-compose.yml и замените его
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # Заменить в файле docker-compose.yml
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
	  echo "Среда LDNMP была установлена"
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
	echo "Задача об обновлении была обновлена"
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
	echo -e "${gl_huang}$yumingИнформация об открытом ключе${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yumingИнформация о частном ключе${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}Путь хранения сертификата${gl_bai}"
	echo "Открытый ключ:/etc/letsEncrypt/live/$yuming/fullchain.pem"
	echo "Закрытый ключ:/и т.д./letsEncrypt/live/$yuming/privkey.pem"
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
	echo -e "${gl_huang}Истечение примененного сертификата${gl_bai}"
	echo "Информация о сайте Сертификат истечения срока действия"
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
		send_stats "Успешное заявление на сертификат доменного имени"
	else
		send_stats "Приложение для доменного имени Сертификат не удалось"
		echo -e "${gl_hong}Уведомление:${gl_bai}Заявление о сертификате не удалось. Пожалуйста, проверьте следующие возможные причины и попробуйте еще раз:"
		echo -e "1.. Ошибка орфографии доменного имени ➠ Пожалуйста, проверьте, правильно ли введено доменное имя"
		echo -e "2. Проблема разрешения DNS ➠ Убедитесь, что доменное имя было правильно разрешено для этого сервера IP"
		echo -e "3. Проблемы конфигурации сети ➠ Если вы используете Warpp и другие виртуальные сети CloudFlare, пожалуйста, временно выключите"
		echo -e "4. Ограничения брандмауэра ➠ Проверьте, открыт ли порт 80/443 для обеспечения проверки доступной"
		echo -e "5. Количество приложений превышает предел ➠ Let's Encrypt имеет еженедельный лимит (5 раз/доменное имя/неделя)"
		break_end
		clear
		echo "Пожалуйста, попробуйте развернуть еще раз$webname"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "Повторное использование доменного имени"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "Сначала разрешить доменное имя в локальном IP:${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "Пожалуйста, введите свой IP или разрешенное доменное имя:" yuming
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

  send_stats "обновлять$ldnmp_pods"
  echo "обновлять${ldnmp_pods}Заканчивать"

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
  echo "Информация о входе в систему:"
  echo "имя пользователя:$dbuse"
  echo "пароль:$dbusepasswd"
  echo
  send_stats "запускать$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # Проверьте, существует ли файл конфигурации
  if [ -f "$CONFIG_FILE" ]; then
	# Читать API_TOKEN и ZEAN_ID из файлов конфигурации
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# Преобразовать Zone_IDS в массив
	ZONE_IDS=($ZONE_IDS)
  else
	# Позвольте пользователю чистить кэш
	read -e -p "Нужно чистить кеш Cloudflare? (Y/N):" answer
	if [[ "$answer" == "y" ]]; then
	  echo "Информация CF сохраняется в$CONFIG_FILE, вы можете изменить информацию CF позже"
	  read -e -p "Пожалуйста, введите свой API_TOKEN:" API_TOKEN
	  read -e -p "Пожалуйста, введите свое имя пользователя CF:" EMAIL
	  read -e -p "Пожалуйста, введите Zone_ID (несколько разделенных пробелами):" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # Перевернуть через каждую Zone_id и выполнить команду Clear Cache
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "Кэш очистки для Zone_ID:$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "Запрос Cache Clear был отправлен."
}



web_cache() {
  send_stats "Очистить кеш сайта"
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

	send_stats "Удалить данные сайта"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "Чтобы удалить данные сайта, введите свое доменное имя (несколько доменных имен разделены пространствами):" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "Удаление доменного имени:$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# Преобразовать доменное имя в имя базы данных
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# Проверьте, существует ли база данных перед удалением, чтобы избежать ошибок
		echo "Удаление базы данных:$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# Решите включить или выключить WAF в соответствии с параметрами режима
	if [ "$mode" == "on" ]; then
		# Включите WAF: удалить комментарии
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# Закрыть WAF: добавить комментарии
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "Неверный параметр: используйте 'on' или 'off'"
		return 1
	fi

	# Проверьте изображения Nginx и обрабатывайте их в соответствии с ситуацией
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
echo "Адрес доступа:"
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

	# Получить время создания контейнера и имя изображения
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# Извлекать зеркальные склады и теги
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# Лейбл по умолчанию является последним
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# Добавить поддержку официальных изображений
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# Получить время публикации изображений от Docker Hub API
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# Проверьте время приобретения
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# Сравните временные метки
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

	# Получите IP -адрес контейнера
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "Ошибка: невозможно получить контейнер$container_name_or_idIP -адрес. Пожалуйста, проверьте, является ли имя или идентификатор контейнера."
		return 1
	fi

	install iptables


	# Проверьте и заблокируйте все остальные IPS
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# Проверьте и выпустите указанный IP
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Проверьте и выпустите локальную сеть 127.0.0/8
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# Проверьте и заблокируйте все остальные IPS
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# Проверьте и выпустите указанный IP
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Проверьте и выпустите локальную сеть 127.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "Порты IP+ были заблокированы от доступа к сервису"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# Получите IP -адрес контейнера
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "Ошибка: невозможно получить контейнер$container_name_or_idIP -адрес. Пожалуйста, проверьте, является ли имя или идентификатор контейнера."
		return 1
	fi

	install iptables


	# Четкие правила, которые блокируют все остальные IPS
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# Очистить правила выпуска указанного IP
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Снимите правила для выпуска Local Network 127.0.0.0/8
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# Четкие правила, которые блокируют все остальные IPS
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# Очистить правила выпуска указанного IP
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# Снимите правила для выпуска Local Network 127.0.0.0/8
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "Портам IP+разрешено получить доступ к сервису"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Ошибка: Пожалуйста, предоставьте номер порта и IP, который разрешается получить доступ."
		echo "Использование: block_host_port <Номер порта> <Авторизованный IP>"
		return 1
	fi

	install iptables


	# Отрицал весь другой доступ к IP
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# Разрешить указанный доступ к IP
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# Разрешить местный доступ
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# Отрицал весь другой доступ к IP
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# Разрешить указанный доступ к IP
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# Разрешить местный доступ
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Разрешить трафик для установленных и связанных соединений
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "Порты IP+ были заблокированы от доступа к сервису"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "Ошибка: Пожалуйста, предоставьте номер порта и IP, который разрешается получить доступ."
		echo "Использование: clear_host_port_rules <номер порта> <Авторизованный IP>"
		return 1
	fi

	install iptables


	# Очистить правила, которые блокируют все другие доступ к IP
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# Четкие правила, которые допускают нативный доступ
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Очистить правила, которые разрешают указанный доступ к IP
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# Очистить правила, которые блокируют все другие доступ к IP
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# Четкие правила, которые допускают нативный доступ
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# Очистить правила, которые разрешают указанный доступ к IP
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "Портам IP+разрешено получить доступ к сервису"
	save_iptables_rules

}





docker_app() {
send_stats "${docker_name}управлять"

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
	echo "1. Установите 2. Обновление 3. Удалить"
	echo "------------------------"
	echo "5. Добавьте доменное имя доступа 6. Удалить домен и имя домена"
	echo "7. Разрешить IP+ Port Access 8. Block IP+ Access Access"
	echo "------------------------"
	echo "0. Вернитесь в предыдущее меню"
	echo "------------------------"
	read -e -p "Пожалуйста, введите свой выбор:" choice
	 case $choice in
		1)
			check_disk_space $app_size
			read -e -p "Введите внешний сервисный порт приложения и введите по умолчанию${docker_port}Порт:" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			clear
			echo "$docker_nameУстановлен"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "Установить$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum
			clear
			echo "$docker_nameУстановлен"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "обновлять$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			echo "Приложение было удалено"
			send_stats "удалить$docker_name"
			;;

		5)
			echo "${docker_name}Настройки домена домена"
			send_stats "${docker_name}Настройки домена домена"
			add_yuming
			ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "Формат доменного имени example.com не поставляется с https: //"
			web_del
			;;

		7)
			send_stats "Разрешить IP -доступ${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "Block IP Access${docker_name}"
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
		echo "1. Установите 2. Обновление 3. Удалить"
		echo "------------------------"
		echo "5. Добавьте доменное имя доступа 6. Удалить домен и имя домена"
		echo "7. Разрешить IP+ Port Access 8. Block IP+ Access Access"
		echo "------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice
		case $choice in
			1)
				check_disk_space $app_size
				read -e -p "Введите внешний сервисный порт приложения и введите по умолчанию${docker_port}Порт:" app_port
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
				echo "${docker_name}Настройки домена домена"
				send_stats "${docker_name}Настройки домена домена"
				add_yuming
				ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "Формат доменного имени example.com не поставляется с https: //"
				web_del
				;;
			7)
				send_stats "Разрешить IP -доступ${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "Block IP Access${docker_name}"
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

# Функции, которые проверяют, существует ли сеанс
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# Цикл до тех пор, пока не найдено не существующее имя сеанса
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# Создать новый сеанс TMUX
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
		echo "Перезагружен"
		reboot
		;;
	  *)
		echo "Отменен"
		;;
	esac


}

# output_status() {
# 	output=$(awk 'BEGIN { rx_total = 0; tx_total = 0 }
# # Сопоставьте общие общедоступные сетевые карты имена: ETH*, ENS*, ENP*, ENO*
# 		$1 ~ /^(eth|ens|enp|eno)[0-9]+/ {
# 			rx_total += $2
# 			tx_total += $10
# 		}
# 		END {
# 			rx_units = "Bytes";
# 			tx_units = "Bytes";
# 			if (rx_total > 1024) { rx_total /= 1024; rx_units = "K"; }
# 			if (rx_total > 1024) { rx_total /= 1024; rx_units = "M"; }
# 			if (rx_total > 1024) { rx_total /= 1024; rx_units = "G"; }

# 			if (tx_total > 1024) { tx_total /= 1024; tx_units = "K"; }
# 			if (tx_total > 1024) { tx_total /= 1024; tx_units = "M"; }
# 			if (tx_total > 1024) { tx_total /= 1024; tx_units = "G"; }

# printf («Общий прием: %.2f %s \ ntotal передача: %.2f %s \ n», rx_total, rx_units, tx_total, tx_units);
# 		}' /proc/net/dev)
# 	# echo "$output"
# }


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
	send_stats "Невозможно снова установить среду LDNMP"
	echo -e "${gl_huang}намекать:${gl_bai}Среда строительства веб -сайта установлена. Не нужно снова устанавливать!"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "Установите среду LDNMP"
root_use
clear
echo -e "${gl_huang}Среда LDNMP не установлена, начните установить среду LDNMP ...${gl_bai}"
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
send_stats "Установите среду Nginx"
root_use
clear
echo -e "${gl_huang}Nginx не установлен, начните установить среду Nginx ...${gl_bai}"
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
echo "nginx был установлен"
echo -e "Текущая версия:${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "Пожалуйста, сначала установите среду LDNMP"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "Пожалуйста, сначала установите среду nginx"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "Ваш$webnameПостроен!"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webnameИнформация об установке следующая:"

}

nginx_web_on() {
	  clear
	  echo "Ваш$webnameПостроен!"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "Установить$webname"
  echo "Начните развертывание$webname"
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
# Эхо "Имя базы данных: $ dbname"
# Эхо "Имя пользователя: $ dbuse"
# Эхо "пароль: $ dbusepasswd"
# Эхо "Адрес базы данных: mysql"
# Echo "таблица префикс: wp_"

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "Установить$webname"
	echo "Начните развертывание$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "Пожалуйста, введите свой анти-поколение IP:" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "Пожалуйста, введите свой порт против поколения:" port
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

	send_stats "Установить$webname"
	echo "Начните развертывание$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# Получите несколько IPS, введенные пользователем: порты (разделенные пространствами)
	if [ -z "$reverseproxy_port" ]; then
		read -e -p "Пожалуйста, введите свои порты с несколькими антигенерациями IP+, разделенные пространствами (например, 127.0.0.1:3000 127.0.0.1:3002):" reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	# Динамически генерировать конфигурацию вверх по течению
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	# Заменить заполнители в шаблонах
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
		send_stats "Управление сайтом LDNMP"
		echo "LDNMP среда"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}Срок действия сертификата"
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
		echo "Справочник сайта"
		echo "------------------------"
		echo -e "данные${gl_hui}/home/web/html${gl_bai}Сертификат${gl_hui}/home/web/certs${gl_bai}Конфигурация${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "работать"
		echo "------------------------"
		echo "1. Подать заявку на/обновить сертификат доменного имени. 2. Измените имя домена Сайта"
		echo "3. Очистите кэш сайта 4. Создайте связанный сайт"
		echo "5. Просмотреть журнал доступа 6. Просмотреть журнал ошибок"
		echo "7. Редактировать глобальную конфигурацию 8. Редактировать конфигурацию сайта"
		echo "9. Управление базой данных сайта 10. Просмотреть отчет об анализе сайтов"
		echo "------------------------"
		echo "20. Удалить указанные данные сайта"
		echo "------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите свой выбор:" sub_choice
		case $sub_choice in
			1)
				send_stats "Подать заявку на сертификат доменного имени"
				read -e -p "Пожалуйста, введите свое доменное имя:" yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "Измените доменное имя сайта"
				echo -e "${gl_hong}Настоятельно рекомендуется:${gl_bai}Сначала резервните все данные сайта, а затем измените доменное имя сайта!"
				read -e -p "Пожалуйста, введите старое доменное имя:" oddyuming
				read -e -p "Пожалуйста, введите новое доменное имя:" yuming
				install_certbot
				install_ssltls
				certs_status

				# замена MySQL
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

				# Замена каталога веб -сайтов
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
				send_stats "Создать связанный сайт"
				echo -e "Связывать новое доменное имя для существующего сайта для доступа"
				read -e -p "Пожалуйста, введите существующее доменное имя:" oddyuming
				read -e -p "Пожалуйста, введите новое доменное имя:" yuming
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
				send_stats "Просмотреть журнал доступа"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "Просмотреть журнал ошибок"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "Редактировать глобальную конфигурацию"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "Редактировать конфигурацию сайта"
				read -e -p "Чтобы отредактировать конфигурацию сайта, введите доменное имя, которое вы хотите отредактировать:" yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "Просмотреть данные сайта"
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
send_stats "${panelname}управлять"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname}В настоящее время это популярная и мощная панель управления операцией и обслуживанием."
	echo "Официальное веб -сайт Введение:$panelurl "

	echo ""
	echo "------------------------"
	echo "1. Установить 2. Управление 3. Удалить"
	echo "------------------------"
	echo "0. Вернитесь в предыдущее меню"
	echo "------------------------"
	read -e -p "Пожалуйста, введите свой выбор:" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install
			send_stats "${panelname}Установить"
			;;
		2)
			panel_app_manage
			send_stats "${panelname}контроль"

			;;
		3)
			panel_app_uninstall
			send_stats "${panelname}удалить"
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
		echo "Текущая архитектура процессора не поддерживается:$arch"
	fi

	# Найдите последний загруженный файл FRP
	latest_file=$(ls -t /home/frp/frp_*.tar.gz | head -n 1)

	# Разанипируйте файл
	tar -zxvf "$latest_file"

	# Получите имя декомпрессированной папки
	dir_name=$(tar -tzf "$latest_file" | head -n 1 | cut -f 1 -d '/')

	# Переименовать папку беззазамета в единое имя версии
	mv "$dir_name" "frp_0.61.0_linux_amd64"



}



generate_frps_config() {

	send_stats "Установите FRP -сервер"
	# Генерировать случайные порты и учетные данные
	local bind_port=8055
	local dashboard_port=8056
	local token=$(openssl rand -hex 16)
	local dashboard_user="user_$(openssl rand -hex 4)"
	local dashboard_pwd=$(openssl rand -hex 8)

	donlond_frp

	# Создайте файл frps.toml
	cat <<EOF > /home/frp/frp_0.61.0_linux_amd64/frps.toml
[common]
bind_port = $bind_port
authentication_method = token
token = $token
dashboard_port = $dashboard_port
dashboard_user = $dashboard_user
dashboard_pwd = $dashboard_pwd
EOF

	# Вывод сгенерированной информации
	ip_address
	echo "------------------------"
	echo "Параметры, необходимые для развертывания клиента"
	echo "Сервис IP:$ipv4_address"
	echo "token: $token"
	echo
	echo "Информация о панели FRP"
	echo "Адрес панели FRP: http: //$ipv4_address:$dashboard_port"
	echo "Имя пользователя FRP панели:$dashboard_user"
	echo "Пароль панели FRP:$dashboard_pwd"
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
	send_stats "Установите клиент FRP"
	read -e -p "Пожалуйста, введите внешнюю сеть стыковки стыковки:" server_addr
	read -e -p "Пожалуйста, введите токен внешней сети стыковки:" token
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
	send_stats "Добавить FRP Intranet Service"
	# Позвольте пользователю ввести имя службы и информацию о пересылке
	read -e -p "Пожалуйста, введите имя службы:" service_name
	read -e -p "Пожалуйста, введите тип пересылки (TCP/UDP) [Enter Default TCP]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "Пожалуйста, введите интранет IP [Enter Default 127.0.0.1]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "Пожалуйста, введите интранет -порт:" local_port
	read -e -p "Пожалуйста, введите внешний сетевой порт:" remote_port

	# Записать пользовательский ввод в файл конфигурации
	cat <<EOF >> /home/frp/frp_0.61.0_linux_amd64/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# Вывод сгенерированной информации
	echo "Служить$service_nameУспешно добавлен в FRPC.Toml"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "Удалить службу интрасети FRP"
	# Предложите пользователю ввести имя службы, которое необходимо удалить
	read -e -p "Пожалуйста, введите имя службы, которое необходимо удалить:" service_name
	# Используйте SED, чтобы удалить службу и связанные с ним конфигурации
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frp_0.61.0_linux_amd64/frpc.toml
	echo "Служить$service_nameУспешно удален из FRPC.Toml"

	tmux kill-session -t frpc >/dev/null 2>&1
	tmux new -d -s "frpc" "cd /home/frp/frp_0.61.0_linux_amd64 && ./frpc -c frpc.toml"

}


list_forwarding_services() {
	local config_file="$1"

	# Распечатайте заголовок
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
		# Если есть информация об обслуживании, распечатайте текущую службу перед обработкой новой службы
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# Обновите текущее имя службы
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# Очистить предыдущее значение
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
		# Распечатайте информацию для последней службы
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# Получить порт сервера FRP
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# Генерировать адрес доступа
generate_access_urls() {
	# Получите все порты в первую очередь
	get_frp_ports

	# Проверьте, есть ли порты, отличные от 8055/8056
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# Показать заголовок и контент только тогда, когда есть действительный порт
	if [ "$has_valid_ports" = true ]; then
		echo "Служба FRP Внешний адрес доступа:"

		# Процесс адреса IPv4
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# Обработать адреса IPv6 (если присутствуют)
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# Обработка конфигурации HTTPS
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
	send_stats "FRP -сервер"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		echo -e "FRP -сервер$check_frp"
		echo "Создайте среду службы проникновения интрасети FR"
		echo "Официальное веб -сайт Введение: https://github.com/fatedier/frp/"
		echo "Обучение видео: https://www.bilibili.com/video/bv1ymw6e2ewl?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. Установите 2. Обновление 3. Удалить"
		echo "------------------------"
		echo "5. Доступ к имени доменного имени для интранет -службы 6. Удалить доменное имя"
		echo "------------------------"
		echo "7. Разрешить IP+ Port Access 8. Block IP+ Access Access"
		echo "------------------------"
		echo "00. Статус обслуживания обновления 0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice
		case $choice in
			1)
				generate_frps_config
				rm -rf /home/frp/*.tar.gz
				echo "FRP -сервер был установлен"
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
				echo "Сервер FRP был обновлен"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				rm -rf /home/frp
				close_port 8055 8056

				echo "Приложение было удалено"
				;;
			5)
				echo "Обратный интранет проникновение"
				send_stats "Доступ к внешним доменным именам"
				add_yuming
				read -e -p "Пожалуйста, введите свой порт службы проникновения интрасети:" frps_port
				ldnmp_Proxy ${yuming} ${ipv4_address} ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "Формат доменного имени example.com не поставляется с https: //"
				web_del
				;;

			7)
				send_stats "Разрешить IP -доступ"
				read -e -p "Пожалуйста, введите порт, который будет выпущен:" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "Block IP Access"
				echo "Если вы получили доступ к имени домена против поколения, вы можете использовать эту функцию для блокировки доступа к порту IP+, что является более безопасным."
				read -e -p "Пожалуйста, введите порт, который вам нужно блокировать:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "Обновить статус обслуживания FRP"
				echo "Статус обслуживания FRP был обновлен"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRP клиент"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		echo -e "FRP клиент$check_frp"
		echo "Натыкает с сервером, после стыковки вы можете создать службу проникновения интрасети в доступ к Интернету"
		echo "Официальное веб -сайт Введение: https://github.com/fatedier/frp/"
		echo "Обучение видео: https://www.bilibili.com/video/bv1ymw6e2ewl?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			list_forwarding_services "/home/frp/frp_0.61.0_linux_amd64/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. Установите 2. Обновление 3. Удалить"
		echo "------------------------"
		echo "4. Добавить внешние службы 5. Удалить внешние сервисы 6. Настроить сервисы вручную"
		echo "------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Введите свой выбор:" choice
		case $choice in
			1)
				configure_frpc
				rm -rf /home/frp/*.tar.gz
				echo "Клиент FRP был установлен"
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
				echo "Клиент FRP был обновлен"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				rm -rf /home/frp
				close_port 8055
				echo "Приложение было удалено"
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
		send_stats "yt-dlp инструмент загрузки"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "YT-DLP-мощный инструмент для загрузки видео, который поддерживает тысячи сайтов, включая YouTube, Bilibili, Twitter и т. Д."
		echo -e "Официальный адрес веб-сайта: https://github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "Скачанный список видео:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(Пока нет)"
		echo "-------------------------"
		echo "1. Установите 2. Обновление 3. Удалить"
		echo "-------------------------"
		echo "5. Скачать одно видео 6. Скачать пакетное видео 7. Скачать пользовательский параметр"
		echo "8. Скачать как mp3 Audio 9. Удалить видео каталог 10. Управление cookie (в разрабатывании)"
		echo "-------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "-------------------------"
		read -e -p "Пожалуйста, введите номер опции:" choice

		case $choice in
			1)
				send_stats "Установка YT-DLP ..."
				echo "Установка YT-DLP ..."
				install ffmpeg
				sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				sudo chmod a+rx /usr/local/bin/yt-dlp
				echo "Установка завершена. Нажмите любую клавишу, чтобы продолжить ..."
				read ;;
			2)
				send_stats "Обновление YT-DLP ..."
				echo "Обновление YT-DLP ..."
				sudo yt-dlp -U
				echo "Обновление завершено. Нажмите любую клавишу, чтобы продолжить ..."
				read ;;
			3)
				send_stats "Удаление yt-dlp ..."
				echo "Удаление yt-dlp ..."
				sudo rm -f /usr/local/bin/yt-dlp
				echo "Удаление завершено. Нажмите любую клавишу, чтобы продолжить ..."
				read ;;
			5)
				send_stats "dange пакетное видео"
				read -e -p "Пожалуйста, введите ссылку на видео:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "После завершения загрузки нажмите любую клавишу, чтобы продолжить ..." ;;
			6)
				send_stats "Скачать пакетное видео"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# Введите несколько адресов ссылки на видео \ n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&fom_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "Теперь начните партию скачать ..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "Загрузка партии завершена, нажмите любую клавишу, чтобы продолжить ..." ;;
			7)
				send_stats "Пользовательский видео скачать"
				read -e -p "Пожалуйста, введите полный параметр YT-DLP (без учета YT-DLP):" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "После завершения выполнения нажмите любую клавишу, чтобы продолжить ..." ;;
			8)
				send_stats "Mp3 скачать"
				read -e -p "Пожалуйста, введите ссылку на видео:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "Загрузка звука завершена, нажмите любую клавишу, чтобы продолжить ..." ;;

			9)
				send_stats "Удалить видео"
				read -e -p "Пожалуйста, введите имя видео Delete:" rmdir
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



# Исправить проблему прерывания DPKG
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}Обновление системы ...${gl_bai}"
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
		echo "Неизвестный менеджер пакетов!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}Очистка системы ...${gl_bai}"
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
		echo "Очистите кеш менеджера пакетов ..."
		apk cache clean
		echo "Удалить системный журнал ..."
		rm -rf /var/log/*
		echo "Удалить кеш APK ..."
		rm -rf /var/cache/apk/*
		echo "Удалить временные файлы ..."
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
		echo "Удалить системный журнал ..."
		rm -rf /var/log/*
		echo "Удалить временные файлы ..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "Очистите неиспользованные зависимости ..."
		pkg autoremove -y
		echo "Очистите кеш менеджера пакетов ..."
		pkg clean -y
		echo "Удалить системный журнал ..."
		rm -rf /var/log/*
		echo "Удалить временные файлы ..."
		rm -rf /tmp/*

	else
		echo "Неизвестный менеджер пакетов!"
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
send_stats "Оптимизировать DNS"
while true; do
	clear
	echo "Оптимизировать адрес DNS"
	echo "------------------------"
	echo "Текущий адрес DNS"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. Оптимизация иностранных DNS:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2. Оптимизация DNS DNS:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. Редактировать конфигурацию DNS вручную"
	echo "------------------------"
	echo "0. Вернитесь в предыдущее меню"
	echo "------------------------"
	read -e -p "Пожалуйста, введите свой выбор:" Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "Иностранная оптимизация DNS"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "Домашняя оптимизация DNS"
		;;
	  3)
		install nano
		nano /etc/resolv.conf
		send_stats "Редактировать конфигурацию DNS вручную"
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

	# Если можно найти пароль, установите на да
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# Если найдено PubkeyAuthentication, установлена ​​да
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# Если не совпадает с паролем, ни PubkeyAuthentication, установите значение по умолчанию по умолчанию
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # Резервное копирование файлов конфигурации SSH
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "Порт SSH был изменен на:$new_port"

  sleep 1

}



add_sshkey() {

	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f /root/.ssh/sshkey -N ""

	cat ~/.ssh/sshkey.pub >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys


	ip_address
	echo -e "Информация о личном ключе была сгенерирована. Обязательно скопируйте и сохраните его.${gl_huang}${ipv4_address}_ssh.key${gl_bai}Файл для будущего входа в SSH"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	echo -e "${gl_lv}Root закрытый ключ включен, вход в систему пароля был закрыт, повторное соединение вступит в силу${gl_bai}"

}


import_sshkey() {

	read -e -p "Пожалуйста, введите содержание общедоступного ключа SSH (обычно начиная с «SSH-RSA» или «SSH-ED25519»):" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}Ошибка: контент открытого ключа не был введен.${gl_bai}"
		return 1
	fi

	echo "$public_key" >> ~/.ssh/authorized_keys
	chmod 600 ~/.ssh/authorized_keys

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	echo -e "${gl_lv}Общедоступный ключ был успешно импортирован, вход в root Private Keo${gl_bai}"

}




add_sshpasswd() {

echo "Установите пароль корня"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}Корневой логин настроен!${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}намекать:${gl_bai}Эта функция требует, чтобы root -пользователь запустил!" && break_end && kejilion
}



dd_xitong() {
		send_stats "Переустановить систему"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "Первоначальное имя пользователя после переустановки:${gl_huang}root${gl_bai}Первоначальный пароль:${gl_huang}LeitboGi0ro${gl_bai}Первоначальный порт:${gl_huang}22${gl_bai}"
		  echo -e "Нажмите любую клавишу, чтобы продолжить ..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "Первоначальное имя пользователя после переустановки:${gl_huang}Administrator${gl_bai}Первоначальный пароль:${gl_huang}Teddysun.com${gl_bai}Первоначальный порт:${gl_huang}3389${gl_bai}"
		  echo -e "Нажмите любую клавишу, чтобы продолжить ..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "Первоначальное имя пользователя после переустановки:${gl_huang}root${gl_bai}Первоначальный пароль:${gl_huang}123@@@${gl_bai}Первоначальный порт:${gl_huang}22${gl_bai}"
		  echo -e "Нажмите любую клавишу, чтобы продолжить ..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "Первоначальное имя пользователя после переустановки:${gl_huang}Administrator${gl_bai}Первоначальный пароль:${gl_huang}123@@@${gl_bai}Первоначальный порт:${gl_huang}3389${gl_bai}"
		  echo -e "Нажмите любую клавишу, чтобы продолжить ..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "Переустановить систему"
			echo "--------------------------------"
			echo -e "${gl_hong}Уведомление:${gl_bai}Установка рискованно потерять контакт, и те, кто обеспокоен, должны использовать его с осторожностью. Ожидается, что переустановка займет 15 минут, пожалуйста, резервную копию данных заранее."
			echo -e "${gl_hui}Спасибо Моллилау и BIN456789 за поддержку сценария!${gl_bai} "
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
			echo "35."
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2022"
			echo "45. Windows Server 2019       46. Windows Server 2016"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. Вернитесь в предыдущее меню"
			echo "------------------------"
			read -e -p "Пожалуйста, выберите систему для переустановки:" sys_choice
			case "$sys_choice" in
			  1)
				send_stats "Переустановите Debian 12"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  2)
				send_stats "Переустановить Debian 11"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  3)
				send_stats "Переустановите Debian 10"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  4)
				send_stats "Переустановите Debian 9"
				dd_xitong_1
				bash InstallNET.sh -debian 9
				reboot
				exit
				;;
			  11)
				send_stats "Переустановить Ubuntu 24.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "Переустановить Ubuntu 22.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "Переустановить Ubuntu 20.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "Переустановите Ubuntu 18.04"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "Переустановите Rockylinux9"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "Переустановите Rockylinux8"
				dd_xitong_3
				bash reinstall.sh rocky 8
				reboot
				exit
				;;

			  23)
				send_stats "Переустановите Alma9"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "Переустановите Alma8"
				dd_xitong_3
				bash reinstall.sh almalinux 8
				reboot
				exit
				;;

			  25)
				send_stats "Переустановить Oracle9"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "Переустановить Oracle8"
				dd_xitong_3
				bash reinstall.sh oracle 8
				reboot
				exit
				;;

			  27)
				send_stats "Переустановите Fedora41"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "Переустановите Fedora40"
				dd_xitong_3
				bash reinstall.sh fedora 40
				reboot
				exit
				;;

			  29)
				send_stats "Переустановите CentOS10"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "Переустановите CentOS9"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "Переустановите альпийский"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "Переустановить арку"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "Переустановить Кали"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "Переустановите открытый"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "Переустановка открывает"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "Перезагрузить летающую корову"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;


			  41)
				send_stats "Переустановите Windows11"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;
			  42)
				dd_xitong_2
				send_stats "Переустановите Windows 10"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;
			  43)
				send_stats "Переустановите Windows 7"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "Переустановить Windows Server 22"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;
			  45)
				send_stats "Переустановить Windows Server 19"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;
			  46)
				send_stats "Переустановить Windows Server 16"
				dd_xitong_2
				bash InstallNET.sh -windows 2016 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "Переустановить Windows11 ARM"
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
		  send_stats "BBRV3 Управление"

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
				  echo "Вы установили ядро ​​BBRV3 Ксанмода"
				  echo "Текущая версия ядра:$kernel_version"

				  echo ""
				  echo "Управление ядрами"
				  echo "------------------------"
				  echo "1. Обновите ядро ​​BBRV3. Установите ядро ​​BBRV3"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# Шаг 3: Добавьте репозиторий
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "Ядро ксанмода было обновлено. Вступить в силу после перезапуска"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "Ядро ксанмода удаляется. Вступить в силу после перезапуска"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "Настройка ускорения BBR3"
		  echo "Введение видео: https://www.bilibili.com/video/bv14k421x7bs?t=0.1"
		  echo "------------------------------------------------"
		  echo "Только поддержка Debian/Ubuntu"
		  echo "Пожалуйста, создайте резервную копию данных и позволите BBR3 для обновления ядра Linux."
		  echo "VPS имеет 512 м память, пожалуйста, добавьте 1G виртуальную память заранее, чтобы предотвратить недостающий контакт из -за недостаточной памяти!"
		  echo "------------------------------------------------"
		  read -e -p "Вы обязательно продолжите? (Y/N):" choice

		  case "$choice" in
			[Yy])
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "Текущая среда не поддерживает его, только поддерживает системы Debian и Ubuntu"
					break_end
					linux_Settings
				fi
			else
				echo "Невозможно определить тип операционной системы"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# Шаг 3: Добавьте репозиторий
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "Ядро ксанмода установлено, и BBR3 успешно включен. Вступить в силу после перезапуска"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "Отменен"
			  ;;
			*)
			  echo "Неверный выбор, пожалуйста, введите Y или N."
			  ;;
		  esac
		fi

}


elrepo_install() {
	# Импорт Elrepo GPG Public Key
	echo "Импортируйте открытый ключ Elrepo GPG ..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# Обнаружение версии системы
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# Убедитесь, что мы работаем в поддерживаемой операционной системе
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "Неподдерживаемые операционные системы:$os_name"
		break_end
		linux_Settings
	fi
	# Печать обнаруженной информации о операционной системе
	echo "Обнаружена операционная система:$os_name $os_version"
	# Установите соответствующую конфигурацию склада Elrepo в соответствии с версией системы
	if [[ "$os_version" == 8 ]]; then
		echo "Установите конфигурацию репозитория Elrepo (версия 8) ..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "Установите конфигурацию репозитория Elrepo (версия 9) ..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	else
		echo "Неподдерживаемые системные версии:$os_version"
		break_end
		linux_Settings
	fi
	# Включить репозиторий Elrepo ядра и установить последнее ядро ​​основного линии
	echo "Включите репозиторий Elrepo ядра и установите новейшее ядро ​​Mainline ..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "Конфигурация репозитория Elrepo установлена ​​и обновляется до последнего основного ядра."
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "Управление ядрами Red Hate"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "Вы установили ядро ​​Elrepo"
				  echo "Текущая версия ядра:$kernel_version"

				  echo ""
				  echo "Управление ядрами"
				  echo "------------------------"
				  echo "1. Обновите ядро ​​Elrepo 2. Удалить ядро ​​Эльрепо"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "Обновите ядро ​​Red Hate"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "Эльрепо ядро ​​удалено. Вступить в силу после перезапуска"
						send_stats "Удалить ядр красной хит"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "Пожалуйста, скажите данные и обновите ядро ​​Linux для вас"
		  echo "Введение видео: https://www.bilibili.com/video/bv1mh4y1w7qa?t=529.2"
		  echo "------------------------------------------------"
		  echo "Поддержка только распределения серии Red Hat Centos/Redhat/Alma/Rocky/Oracle"
		  echo "Обновление ядра Linux может улучшить производительность и безопасность системы. Рекомендуется попробовать это, если условия позволяют и обновлять производственную среду с осторожностью!"
		  echo "------------------------------------------------"
		  read -e -p "Вы обязательно продолжите? (Y/N):" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "Обновить ядро ​​Red Hate"
			  server_reboot
			  ;;
			[Nn])
			  echo "Отменен"
			  ;;
			*)
			  echo "Неверный выбор, пожалуйста, введите Y или N."
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}Обновите базу данных вирусов ...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "Пожалуйста, укажите каталог для сканирования."
		return
	fi

	echo -e "${gl_huang}Сканирующий каталог $@...${gl_bai}"

	# Построить параметры крепления
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# Построить параметры Clamsscan Command
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# Выполнить команды Docker
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ Сканирование завершено, отчет о вирусе хранится${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}Если есть вирус, пожалуйста${gl_huang}scan.log${gl_lv}Поиск найденного ключевого слова в файле, чтобы подтвердить местоположение вируса${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "Управление вирусом"
		  while true; do
				clear
				echo "Инструмент сканирования вируса CLAMAV"
				echo "Введение видео: https://www.bilibili.com/video/bv1tqvze4eqm?t=0.1"
				echo "------------------------"
				echo "Это антивирусный программный инструмент с открытым исходным кодом, который в основном используется для обнаружения и удаления различных типов вредоносных программ."
				echo "Включая вирусы, троянских лошадей, шпионских программ, вредоносных сценариев и другого вредного программного обеспечения."
				echo "------------------------"
				echo -e "${gl_lv}1. Полное сканирование диска${gl_bai}             ${gl_huang}2. Сканируйте важный каталог${gl_bai}            ${gl_kjlan}3. Сканирование пользовательского каталога${gl_bai}"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите свой выбор:" sub_choice
				case $sub_choice in
					1)
					  send_stats "Полное сканирование диска"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "Важное сканирование каталогов"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "Сканирование пользовательского каталога"
					  read -e -p "Пожалуйста, введите каталог для сканирования, разделенный пространствами (например: /etc /var /usr /home /root):" directories
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




# Функция оптимизации высокопроизводительной режима
optimize_high_performance() {
	echo -e "${gl_lv}Переключиться на${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}Оптимизируйте дескрипторы файлов ...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}Оптимизировать виртуальную память ...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}Оптимизируйте настройки сети ...${gl_bai}"
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

	echo -e "${gl_lv}Оптимизируйте управление кэшем ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}Оптимизировать настройки процессора ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}Другие оптимизации ...${gl_bai}"
	# Отключить большие прозрачные страницы, чтобы уменьшить задержку
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# Отключить балансировку NUMA
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# Функция оптимизации режима выравнивания
optimize_balanced() {
	echo -e "${gl_lv}Переключитесь в режим выравнивания ...${gl_bai}"

	echo -e "${gl_lv}Оптимизируйте дескрипторы файлов ...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}Оптимизировать виртуальную память ...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}Оптимизируйте настройки сети ...${gl_bai}"
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

	echo -e "${gl_lv}Оптимизируйте управление кэшем ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}Оптимизировать настройки процессора ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}Другие оптимизации ...${gl_bai}"
	# Восстановите прозрачную страницу
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# Восстановите балансировку NUMA
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# Восстановить функцию настроек по умолчанию
restore_defaults() {
	echo -e "${gl_lv}Восстановите настройки по умолчанию ...${gl_bai}"

	echo -e "${gl_lv}Восстановить дескриптор файла ...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}Восстановите виртуальную память ...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}Восстановить настройки сети ...${gl_bai}"
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

	echo -e "${gl_lv}Восстановите управление кешем ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}Восстановите настройки процессора ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}Восстановить другие оптимизации ...${gl_bai}"
	# Восстановите прозрачную страницу
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# Восстановите балансировку NUMA
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# Функция оптимизации построения веб -сайта
optimize_web_server() {
	echo -e "${gl_lv}Переключитесь на режим оптимизации построения веб -сайта ...${gl_bai}"

	echo -e "${gl_lv}Оптимизируйте дескрипторы файлов ...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}Оптимизировать виртуальную память ...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}Оптимизируйте настройки сети ...${gl_bai}"
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

	echo -e "${gl_lv}Оптимизируйте управление кэшем ...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}Оптимизировать настройки процессора ...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}Другие оптимизации ...${gl_bai}"
	# Отключить большие прозрачные страницы, чтобы уменьшить задержку
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# Отключить балансировку NUMA
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Управление настройкой ядра Linux"
	  echo "Оптимизация параметров ядра в системе Linux"
	  echo "Введение видео: https://www.bilibili.com/video/bv1kb421j7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "Представлены различные режимы настройки систем, и пользователи могут выбирать и переключаться в соответствии со своими сценариями использования."
	  echo -e "${gl_huang}намекать:${gl_bai}Пожалуйста, используйте его с осторожностью в производственной среде!"
	  echo "--------------------"
	  echo "1. Режим высокопроизводительной оптимизации: максимизировать производительность системы и оптимизировать дескрипторы файлов, виртуальную память, настройки сети, управление кэшем и настройки ЦП."
	  echo "2. Сбалансированный режим оптимизации: баланс между производительностью и потреблением ресурсов, подходит для ежедневного использования."
	  echo "3. Режим оптимизации веб -сайта: оптимизируйте для сервера веб -сайта для улучшения возможностей одновременной обработки соединений, скорости отклика и общей производительности."
	  echo "4."
	  echo "5. Режим оптимизации игрового сервера: оптимизируйте для игровых серверов для улучшения возможностей параллельной обработки и скорости отклика."
	  echo "6. Восстановите настройки по умолчанию: восстановить настройки системы в конфигурацию по умолчанию."
	  echo "--------------------"
	  echo "0. Вернитесь в предыдущее меню"
	  echo "--------------------"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "Оптимизация режима высокой производительности"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "Сбалансированная оптимизация режима"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "Модель оптимизации веб -сайта"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "Живая потоковая оптимизация"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "Оптимизация игрового сервера"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "Восстановить настройки по умолчанию"
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
				echo -e "${gl_lv}Язык системы был изменен на:$langВосстанавливающее соединение вступает в силу.${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}Язык системы был изменен на:$langВосстанавливающее соединение вступает в силу.${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "Неподдерживаемые системы:$ID"
				break_end
				;;
		esac
	else
		echo "Неподдерживаемые системы, тип системы не может быть распознан."
		break_end
	fi
}




linux_language() {
root_use
send_stats "Переключение языка системы"
while true; do
  clear
  echo "Текущий язык системы:$LANG"
  echo "------------------------"
  echo "1. Английский 2. Упрощенный китайский 3. Традиционный китайский"
  echo "------------------------"
  echo "0. Вернитесь в предыдущее меню"
  echo "------------------------"
  read -e -p "Введите свой выбор:" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "Переключиться на английский"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "Переключиться на упрощенный китайский"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "Переключиться на традиционный китайский"
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
echo -e "${gl_lv}Изменение завершено. Воссоедините SSH, чтобы просмотреть изменения!${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "Инструмент украшения командной строки"
  while true; do
	clear
	echo "Инструмент украшения командной строки"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. Вернитесь в предыдущее меню"
	echo "------------------------"
	read -e -p "Введите свой выбор:" choice

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
  send_stats "Станция по переработке системы"

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
	echo -e "Текущая корзина для переработки${trash_status}"
	echo -e "После включения файлы, удаленные с помощью RM, сначала введены в корзин, чтобы предотвратить ошибочную удаление важных файлов!"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "Мусорная корзина пуста"
	echo "------------------------"
	echo "1. Включить корзин."
	echo "3. Восстановить содержание 4. Очистить корзин"
	echo "------------------------"
	echo "0. Вернитесь в предыдущее меню"
	echo "------------------------"
	read -e -p "Введите свой выбор:" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "Корректная корзина включена, а удаленные файлы будут перемещены в корзину."
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "Утилизация переработки закрыта, и файл будет удален напрямую."
		sleep 2
		;;
	  3)
		read -e -p "Введите имя файла, чтобы восстановить:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restoreВосстановлен в домашнем каталоге."
		else
		  echo "Файл не существует."
		fi
		;;
	  4)
		read -e -p "Подтвердите, чтобы очистить корзинную корзину? [y/n]:" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "Утильная корзина была очищена."
		fi
		;;
	  *)
		break
		;;
	esac
  done
}



# Создать резервную копию
create_backup() {
	send_stats "Создать резервную копию"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# Позвольте пользователю ввести каталог резервного копирования
	echo "Создайте пример резервного копирования:"
	echo "- Резервное копирование одного каталога: /var /www"
	echo "- Резервное копирование нескольких каталогов: /etc /home /var /log"
	echo "- Direct Enter будет использовать каталог по умолчанию ( /etc /usr /home)"
	read -r -p "Пожалуйста, введите каталог для резервного копирования (несколько каталогов разделены пространствами, и если вы входите напрямую, используйте каталог по умолчанию):" input

	# Если пользователь не вводит каталог, используйте каталог по умолчанию
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# Разделите каталог, введенный пользователем на массив по пространствам
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# Генерировать префикс файла резервного копирования
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# Извлечь имя каталога и удалить черты
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# Удалить последнее подчеркивание
	local PREFIX=${PREFIX%_}

	# Генерировать имя файла резервного копирования
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# Распечатайте каталог, выбранный пользователем
	echo "Выбранный вами каталог резервного копирования:"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# Создать резервную копию
	echo "Создание резервной копии$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# Проверьте, успешна ли команда
	if [ $? -eq 0 ]; then
		echo "Резервная копия была создана успешно:$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "Резервное творение не удалось!"
		exit 1
	fi
}

# Восстановить резервную копию
restore_backup() {
	send_stats "Восстановить резервную копию"
	# Выберите резервную копию, которую хотите восстановить
	read -e -p "Пожалуйста, введите имя файла резервного копирования, чтобы восстановить:" BACKUP_NAME

	# Проверьте, существует ли файл резервного копирования
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "Файл резервного копирования не существует!"
		exit 1
	fi

	echo "Восстановление резервного копирования$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "Резервное копирование и восстановите успешно!"
	else
		echo "Резервное восстановление не удалось!"
		exit 1
	fi
}

# Список резервных копий
list_backups() {
	echo "Доступные резервные копии:"
	ls -1 "$BACKUP_DIR"
}

# Удалить резервную копию
delete_backup() {
	send_stats "Удалить резервную копию"

	read -e -p "Пожалуйста, введите имя файла резервного копирования, чтобы удалить:" BACKUP_NAME

	# Проверьте, существует ли файл резервного копирования
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "Файл резервного копирования не существует!"
		exit 1
	fi

	# Удалить резервную копию
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "Резервное копирование была успешно удалена!"
	else
		echo "Удаление резервного копирования не удалось!"
		exit 1
	fi
}

# Резервное главное меню
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "Функция резервного копирования системы"
		echo "Функция резервного копирования системы"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1. Создайте резервную копию 2. Восстановите резервное копирование 3. Удалить резервную копию"
		echo "------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите свой выбор:" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "Нажмите Enter, чтобы продолжить ..."
	done
}









# Показать список соединений
list_connections() {
	echo "Сохраняемое соединение:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# Добавить новое соединение
add_connection() {
	send_stats "Добавить новое соединение"
	echo "Пример для создания нового соединения:"
	echo "- Имя соединения: my_server"
	echo "- IP -адрес: 192.168.1.100"
	echo "- Имя пользователя: корень"
	echo "- Порт: 22"
	echo "------------------------"
	read -e -p "Пожалуйста, введите имя подключения:" name
	read -e -p "Пожалуйста, введите свой IP -адрес:" ip
	read -e -p "Пожалуйста, введите имя пользователя (по умолчанию: root):" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "Пожалуйста, введите номер порта (по умолчанию: 22):" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "Пожалуйста, выберите метод аутентификации:"
	echo "1. Пароль"
	echo "2. Ключ"
	read -e -p "Пожалуйста, введите выбор (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "Пожалуйста, введите свой пароль:" password_or_key
			echo  # 换行
			;;
		2)
			echo "Пожалуйста, вставьте содержимое клавиши (нажмите Enter дважды после вставки):"
			local password_or_key=""
			while IFS= read -r line; do
				# Если вход пуст, а содержимое ключа уже содержит начало, вход заканчивается
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# Если это первая строка или контент ключа был введен, продолжайте добавлять
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# Проверьте, является ли это контентом ключа
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "Неверный выбор!"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "Соединение сохраняется!"
}



# Удалить соединение
delete_connection() {
	send_stats "Удалить соединение"
	read -e -p "Пожалуйста, введите номер подключения, чтобы удалить:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Ошибка: соответствующее соединение не было найдено."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# Если соединение использует файл ключа, удалите файл ключа
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "Соединение было удалено!"
}

# Используйте соединение
use_connection() {
	send_stats "Используйте соединение"
	read -e -p "Пожалуйста, введите номер подключения для использования:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "Ошибка: соответствующее соединение не было найдено."
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "Подключение к$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# Подключиться с ключом
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "Соединение не удалось! Пожалуйста, проверьте следующее:"
			echo "1. Правильный ли путь к ключе?$password_or_key"
			echo "2. Правильны ли разрешения ключа файла (должно быть 600)."
			echo "3. Позволяет ли целевой сервер, используя ключ."
		fi
	else
		# Подключиться с паролем
		if ! command -v sshpass &> /dev/null; then
			echo "Ошибка: SSHPASS не установлен, пожалуйста, сначала установите SSHPASS."
			echo "Метод установки:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "Соединение не удалось! Пожалуйста, проверьте следующее:"
			echo "1. Правильны ли имя пользователя и пароль."
			echo "2. Позволяет ли целевой сервер входить в систему."
			echo "3. Будь то служба SSH целевого сервера работает нормально."
		fi
	fi
}


ssh_manager() {
	send_stats "инструмент удаленного подключения SSH"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# Проверьте, существует ли файл конфигурации и каталог ключей, и если он не существует, создайте его
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "Инструмент удаленного подключения SSH"
		echo "Может быть подключен к другим системам Linux через SSH"
		echo "------------------------"
		list_connections
		echo "1. Создайте новое соединение 2. Используйте соединение 3. Удалить соединение"
		echo "------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите свой выбор:" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "Неверный выбор, попробуйте еще раз." ;;
		esac
	done
}












# Список доступных перегородков жесткого диска
list_partitions() {
	echo "Доступные перегородки с жестким диском:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# Установите перегородку
mount_partition() {
	send_stats "Установите перегородку"
	read -e -p "Пожалуйста, введите имя разделения, которое будет установлено (например, SDA1):" PARTITION

	# Проверьте, существует ли раздел
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "Разделение не существует!"
		return
	fi

	# Проверьте, уже установлен, раздел уже
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "Разделение уже установлено!"
		return
	fi

	# Создать точку крепления
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# Установите перегородку
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "Перегородка успешно:$MOUNT_POINT"
	else
		echo "Маунт раздела не удалось!"
		rmdir "$MOUNT_POINT"
	fi
}

# Удалить раздел
unmount_partition() {
	send_stats "Удалить раздел"
	read -e -p "Пожалуйста, введите имя раздела (например, SDA1):" PARTITION

	# Проверьте, уже установлен, раздел уже
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "Разделение не установлено!"
		return
	fi

	# Удалить раздел
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "Перегородка удаляет успешно:$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "Разделение удаление не удалось!"
	fi
}

# Список монтированных разделов
list_mounted_partitions() {
	echo "Установленная перегородка:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# Перегородка формата
format_partition() {
	send_stats "Перегородка формата"
	read -e -p "Пожалуйста, введите имя раздела в формате (например, SDA1):" PARTITION

	# Проверьте, существует ли раздел
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "Разделение не существует!"
		return
	fi

	# Проверьте, уже установлен, раздел уже
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "Разделение было установлено, пожалуйста, удалите его первым!"
		return
	fi

	# Выберите тип файловой системы
	echo "Пожалуйста, выберите тип файловой системы:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "Пожалуйста, введите свой выбор:" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "Неверный выбор!"; return ;;
	esac

	# Подтвердите форматирование
	read -e -p "Подтвердите форматирование разделения /dev /$PARTITIONдля$FS_TYPEЭто? (Y/N):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "Операция была отменена."
		return
	fi

	# Перегородка формата
	echo "Форматирование разделения /dev /$PARTITIONдля$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "Формат разделения был успешным!"
	else
		echo "Форматирование разделения не удалось!"
	fi
}

# Проверьте статус разделения
check_partition() {
	send_stats "Проверьте статус разделения"
	read -e -p "Пожалуйста, введите имя раздела, чтобы проверить (например, SDA1):" PARTITION

	# Проверьте, существует ли раздел
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "Разделение не существует!"
		return
	fi

	# Проверьте статус разделения
	echo "Проверьте раздел /dev /$PARTITIONСтатус:"
	fsck "/dev/$PARTITION"
}

# Основное меню
disk_manager() {
	send_stats "Функция управления жестким диском"
	while true; do
		clear
		echo "Управление распределением жестких дисков"
		echo -e "${gl_huang}Эта функция протестирована в проведении внутреннего испытания, пожалуйста, не используйте ее в производственной среде.${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. Установите раздел 2. Удалить раздел 3. Посмотреть на установленное разделение"
		echo "4. Форматируйте раздел 5. Проверьте статус разделения"
		echo "------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите свой выбор:" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "Нажмите Enter, чтобы продолжить ..."
	done
}




# Показать список задач
list_tasks() {
	echo "Сохраненные задачи синхронизации:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# Добавить новую задачу
add_task() {
	send_stats "Добавить новую задачу синхронизации"
	echo "Создайте новую задачу синхронизации:"
	echo "- Имя задачи: Backup_www"
	echo "- локальный каталог: /var /www"
	echo "- Удаленный адрес: user@192.168.1.100"
	echo "- Удаленный каталог: /Backup /www"
	echo "- номер порта (по умолчанию 22)"
	echo "---------------------------------"
	read -e -p "Пожалуйста, введите имя задачи:" name
	read -e -p "Пожалуйста, введите местный каталог:" local_path
	read -e -p "Пожалуйста, введите удаленный каталог:" remote_path
	read -e -p "Пожалуйста, введите удаленный пользователь @ip:" remote
	read -e -p "Пожалуйста, введите порт SSH (по умолчанию 22):" port
	port=${port:-22}

	echo "Пожалуйста, выберите метод аутентификации:"
	echo "1. Пароль"
	echo "2. Ключ"
	read -e -p "Пожалуйста, выберите (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "Пожалуйста, введите свой пароль:" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "Пожалуйста, вставьте содержимое клавиши (нажмите Enter дважды после вставки):"
			local password_or_key=""
			while IFS= read -r line; do
				# Если вход пуст, а содержимое ключа уже содержит начало, вход заканчивается
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# Если это первая строка или контент ключа был введен, продолжайте добавлять
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# Проверьте, является ли это контентом ключа
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "Неверный контент ключа!"
				return
			fi
			;;
		*)
			echo "Неверный выбор!"
			return
			;;
	esac

	echo "Пожалуйста, выберите режим синхронизации:"
	echo "1. Стандартный режим (-AVZ)"
	echo "2. Удалить целевой файл (-avz-delete)"
	read -e -p "Пожалуйста, выберите (1/2):" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "Неверный выбор, используйте по умолчанию -AVZ"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "Задача сохранена!"
}

# Удалить задачу
delete_task() {
	send_stats "Удалить задачи синхронизации"
	read -e -p "Пожалуйста, введите номер задачи, чтобы удалить:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "Ошибка: соответствующая задача не была найдена."
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# Если задача использует файл ключа, удалите файл ключа
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "Задача удалила!"
}


run_task() {
	send_stats "Выполнять задачи синхронизации"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# Анализировать параметры
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# Если нет входящего номера задачи, предложите пользователю ввести
	if [[ -z "$num" ]]; then
		read -e -p "Пожалуйста, введите номер выполнения задачи:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "Ошибка: задача не была найдена!"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# Настроить источник и целевой путь в соответствии с направлением синхронизации
	if [[ "$direction" == "pull" ]]; then
		echo "Тянуть синхронизацию в локацию:$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "Толчок синхронизации к удаленному концу:$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# Добавить общие параметры подключения SSH
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "Ошибка: SSHPASS не установлен, пожалуйста, сначала установите SSHPASS."
			echo "Метод установки:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# Проверьте, существует ли ключевой файл и правильные разрешения
		if [[ ! -f "$password_or_key" ]]; then
			echo "Ошибка: файл ключа не существует:$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "ПРЕДУПРЕЖДЕНИЕ: Ключевые разрешения файла неверны и ремонтируются ..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "Синхронизация завершена!"
	else
		echo "Синхронизация не удалась! Пожалуйста, проверьте следующее:"
		echo "1. Сетевое соединение нормальным?"
		echo "2. Доступен ли удаленный хост?"
		echo "3. правильная информация о аутентификации?"
		echo "4. Имеют ли локальные и удаленные каталоги правильные разрешения на доступ"
	fi
}


# Создать задачу
schedule_task() {
	send_stats "Добавить задачи синхронизации"

	read -e -p "Пожалуйста, введите номер задачи, чтобы регулярно синхронизировать:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Ошибка: введите действительный номер задачи!"
		return
	fi

	echo "Пожалуйста, выберите временный интервал выполнения:"
	echo "1) выполнять один раз в час"
	echo "2) Выступать один раз в день"
	echo "3) Выполнять один раз в неделю"
	read -e -p "Пожалуйста, введите параметры (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "Ошибка: введите действительный вариант!" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# Проверьте, существует ли та же задача
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "Ошибка: синхронизация времени этой задачи уже существует!"
		return
	fi

	# Создайте Crontab для пользователя
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "Задача времени была создана:$cron_job"
}

# Посмотреть запланированные задачи
view_tasks() {
	echo "Текущие задачи времени:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# Удалить временные задачи
delete_task_schedule() {
	send_stats "Удалить задачи синхронизации"
	read -e -p "Пожалуйста, введите номер задачи, чтобы удалить:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "Ошибка: введите действительный номер задачи!"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "Удаленный номер задачи$numВремя задач"
}


# Основное меню управления задачами
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Инструмент дистанционной синхронизации RSYNC"
		echo "Синхронизация между удаленными каталогами поддерживает инкрементную синхронизацию, эффективную и стабильную."
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. Создайте новую задачу 2. Удалить задачу"
		echo "3. Выполните локальную синхронизацию с удаленным конец 4. Выполните удаленную синхронизацию до локального конца"
		echo "5. Создайте задачу времени 6. Удалить задачу времени"
		echo "---------------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "---------------------------------"
		read -e -p "Пожалуйста, введите свой выбор:" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "Неверный выбор, попробуйте еще раз." ;;
		esac
		read -e -p "Нажмите Enter, чтобы продолжить ..."
	done
}









linux_ps() {

	clear
	send_stats "Информационный запрос системы"

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
	echo -e "Информационный запрос системы"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Имя хоста:${gl_bai}$hostname"
	echo -e "${gl_kjlan}Системная версия:${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linux версия:${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Архитектура процессора:${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}Модель процессора:${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}Количество ядер процессора:${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}Частота процессора:${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Занятость процессора:${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}Системная нагрузка:${gl_bai}$load"
	echo -e "${gl_kjlan}Физическая память:${gl_bai}$mem_info"
	echo -e "${gl_kjlan}Виртуальная память:${gl_bai}$swap_info"
	echo -e "${gl_kjlan}Занятие жесткого диска:${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Всего получение:${gl_bai}$rx"
	echo -e "${gl_kjlan}Всего отправить:${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Сетевой алгоритм:${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Оператор:${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}Адрес IPv4:${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}Адрес IPv6:${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}Адрес DNS:${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}Географическое расположение:${gl_bai}$country $city"
	echo -e "${gl_kjlan}Системное время:${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}Время выполнения:${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "Основные инструменты"
	  echo -e "Основные инструменты"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Керл загрузок инструмент${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}Wget Download Tool${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Инструмент разрешения Sudo Super Management${gl_kjlan}4.   ${gl_bai}Инструмент соединения SOCAT Communication"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Инструмент мониторинга системы HTOP${gl_kjlan}6.   ${gl_bai}Инструмент мониторинга сетевого трафика IFTOP"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Инструмент декомпрессии сжатия на молнии${gl_kjlan}8.   ${gl_bai}инструмент декомпрессии сжатия TAR GZ"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Multi-Channel Founk Found${gl_kjlan}10.  ${gl_bai}FFMPEG Video Codiing Live Streaming Tool"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}BTOP Modern Monitoring Tools${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}Инструмент управления файлами диапазона"
	  echo -e "${gl_kjlan}13.  ${gl_bai}инструмент просмотра диска NCDU${gl_kjlan}14.  ${gl_bai}FZF Global Search Tool"
	  echo -e "${gl_kjlan}15.  ${gl_bai}VIM Текстовый редактор${gl_kjlan}16.  ${gl_bai}Нано текстовый редактор${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}система управления версией GIT"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}Гарантия экрана матрицы${gl_kjlan}22.  ${gl_bai}Охрана экрана поезда"
	  echo -e "${gl_kjlan}26.  ${gl_bai}Tetris игра${gl_kjlan}27.  ${gl_bai}Игра змеи"
	  echo -e "${gl_kjlan}28.  ${gl_bai}Space Invader Game"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Установить все${gl_kjlan}32.  ${gl_bai}Все инсталляции (за исключением экранов и игр)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Удалить все"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}Установите указанный инструмент${gl_kjlan}42.  ${gl_bai}Удалить указанный инструмент"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  curl --help
			  send_stats "Установите Curl"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  wget --help
			  send_stats "Установите wget"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  sudo --help
			  send_stats "Установите Sudo"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  socat -h
			  send_stats "Установить Socat"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "Установите HTOP"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "Установите iftop"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  unzip
			  send_stats "Установите Unzip"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  tar --help
			  send_stats "Установить смолу"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  tmux --help
			  send_stats "Установите TMUX"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "Инструмент был установлен, и метод использования следующим образом:"
			  ffmpeg --help
			  send_stats "Установите ffmpeg"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "Установите BTOP"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "Установите Ranger"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "Установите NCDU"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "Установите FZF"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "Установите Vim"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "Установите Nano"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "Установить git"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "Установите Cmatrix"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "Установить Sl"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "Установите Bastet"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "Установите NSNake"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "Установите Ninvaders"
			  ;;

		  31)
			  clear
			  send_stats "Установить все"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "Установите все (за исключением игр и экранов)"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "Удалить все"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "Пожалуйста, введите установленное имя инструмента (Wget Curl Sudo HTOP):" installname
			  install $installname
			  send_stats "Установите указанное программное обеспечение"
			  ;;
		  42)
			  clear
			  read -e -p "Пожалуйста, введите удаленное имя инструмента (HTOP UFW TMUX CMATRIX):" removename
			  remove $removename
			  send_stats "Удалить указанное программное обеспечение"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "Неверный ввод!"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "Управление BBR"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			  echo "Текущий алгоритм блокировки TCP:$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "Управление BBR"
			  echo "------------------------"
			  echo "1. Поверните BBRV3 2. Выключите BBRV3 (перезапуск)"
			  echo "------------------------"
			  echo "0. Вернитесь в предыдущее меню"
			  echo "------------------------"
			  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "Альпийский включает BBR3"
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
	  # send_stats "Docker Management"
	  echo -e "Docker Management"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Установить и обновить среду Docker${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Посмотреть глобальный статус Docker${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Управление контейнерами Docker${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker Management"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Docker Network Management"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Управление томом Docker"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Очистите бесполезные контейнеры Docker и зеркальные сетевые объемы данных"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Замените источник Docker"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Редактировать файл Daemon.json"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Включить доступ Docker-IPV6"
	  echo -e "${gl_kjlan}12.  ${gl_bai}Закрыть доступ к Docker-IPV6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Удалить окружающую среду Docker"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "Установите среду Docker"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "Docker Global Status"
			  echo "Версия Docker"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker Image:${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "Контейнер Docker:${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Том Docker:${gl_lv}$volume_count${gl_bai}"
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
				  echo "Список сети Docker"
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
				  echo "Сетевая операция"
				  echo "------------------------"
				  echo "1. Создать сеть"
				  echo "2. Присоединяйтесь к Интернету"
				  echo "3. Выйдите из сети"
				  echo "4. Удалить сеть"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "Создать сеть"
						  read -e -p "Установите новое имя сети:" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "Присоединяйтесь к Интернету"
						  read -e -p "Присоединяйтесь к названию сети:" dockernetwork
						  read -e -p "Эти контейнеры добавляются в сеть (несколько имен контейнеров разделены пространствами):" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "Присоединяйтесь к Интернету"
						  read -e -p "Имя сети выйти:" dockernetwork
						  read -e -p "Эти контейнеры выходят из сети (несколько имен контейнеров разделены пространствами):" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "Удалить сеть"
						  read -e -p "Пожалуйста, введите имя сети, чтобы удалить:" dockernetwork
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
				  send_stats "Управление томом Docker"
				  echo "Список томов Docker"
				  docker volume ls
				  echo ""
				  echo "Объем операций"
				  echo "------------------------"
				  echo "1. Создайте новый том"
				  echo "2. Удалить указанный объем"
				  echo "3. Удалить все объемы"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "Создать новый том"
						  read -e -p "Установите новое имя тома:" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "Введите имя удаления тома (пожалуйста, разделяйте несколько имен томов с пробелами):" dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "Удалить все объемы"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "Неверный выбор, пожалуйста, введите Y или N."
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
			  send_stats "Уборка докеров"
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "Неверный выбор, пожалуйста, введите Y или N."
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "Docker Source"
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
			  send_stats "Docker V6 Open"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker V6 Уровень"
			  docker_ipv6_off
			  ;;

		  20)
			  clear
			  send_stats "Docker удаляет"
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
				  echo "Неверный выбор, пожалуйста, введите Y или N."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "Неверный ввод!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "Коллекция тестовых скриптов"
	  echo -e "Коллекция тестовых скриптов"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Обнаружение состояния IP и разблокировки"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Обнаружение статуса разблокировки CHATGPT"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Тест разблокировки потоковой передачи региона"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Да, обнаружение разблокировки потоковых медиа"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt ip Quality Examcamination Script${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Измерение скорости сети"
	  echo -e "${gl_kjlan}11.  ${gl_bai}BestTrace Three Network Backhaul задержка"
	  echo -e "${gl_kjlan}12.  ${gl_bai}MTR_TRACE ТЕРЕ-НЕТКОВОЙ РАЗВИТНЫЙ ТЕСТ ЛИНИИ"
	  echo -e "${gl_kjlan}13.  ${gl_bai}SuperSpeed ​​Трехсети измерение скорости"
	  echo -e "${gl_kjlan}14.  ${gl_bai}NXTRACE Fast Backhaul Test Script"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace определяет тестовый скрипт IP -обратного анализа"
	  echo -e "${gl_kjlan}16.  ${gl_bai}Тест на линии с тремя сетью Ludashi2020"
	  echo -e "${gl_kjlan}17.  ${gl_bai}I-ABC Multifunction Speed ​​Test Script"
	  echo -e "${gl_kjlan}18.  ${gl_bai}Сценарий физического экзамена по сети NetQuality${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Тестирование на производительность аппаратного обеспечения"
	  echo -e "${gl_kjlan}21.  ${gl_bai}Ябс тестирование производительности"
	  echo -e "${gl_kjlan}22.  ${gl_bai}Сценарий тестирования производительности процессора IICU/GB5"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}Комплексный тест"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Тест на производительность скамейки"
	  echo -e "${gl_kjlan}32.  ${gl_bai}SpiritySdx Fusion Monster Review${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "Обнаружение статуса разблокировки CHATGPT"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "Тест разблокировки потоковой передачи региона"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "Да, обнаружение разблокировки потоковых медиа"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_ip Quality Examimance Script"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "BestTrace Three Network Backhaul задержка"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "MTR_TRACE ТРЕЗАТЬ ТЕСТРЕЙТНЫ"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "SuperSpeed ​​Трехсети измерение скорости"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "NXTRACE Fast Backhaul Test Script"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace определяет тестовый скрипт IP -обратного анализа"
			  echo "Список IPS, на который можно ссылаться"
			  echo "------------------------"
			  echo "Пекин Телеком: 219.141.136.12"
			  echo "Пекин Unicom: 202.106.50.1"
			  echo "Пекин Мобил: 221.179.155.161"
			  echo "Shanghai Telecom: 202.96.209.133"
			  echo "Shanghai Unicom: 210.22.97.1"
			  echo "Shanghai Mobile: 211.136.112.200"
			  echo "Guangzhou Telecom: 58.60.188.222"
			  echo "Guangzhou Unicom: 210.21.196.6"
			  echo "Guangzhou Mobile: 120.196.165.24"
			  echo "Чэнду телеком: 61.139.2.69"
			  echo "Чэнду Юником: 119,6.6.6"
			  echo "Чэнду Мобил: 211.137.96.205"
			  echo "Hunan Telecom: 36.111.200.100"
			  echo "ХУНАН УНИКОМ: 42.48.16.100"
			  echo "Hunan Mobile: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "Введите указанный IP:" testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "Тест на линии с тремя сетью Ludashi2020"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "I-ABC Multifunction Speed ​​Test Script"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "Сценарий тестирования качества сети"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "Ябс тестирование производительности"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "Сценарий тестирования производительности процессора IICU/GB5"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "Тест на производительность скамейки"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "SpiritySdx Fusion Monster Review"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "Неверный ввод!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "Коллекция сценариев Oracle Cloud"
	  echo -e "Коллекция сценариев Oracle Cloud"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Установите активный скрипт на холостом ходу"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Удалить активный скрипт на холостом ходу."
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD Revestall System Script"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Детектив R START SCRIPT"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Включите режим входа пароля корня"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Инструмент восстановления IPv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "Активный скрипт: ЦП занимает 10-20% памяти, занимает 20%"
			  read -e -p "Вы обязательно установите его? (Y/N):" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # Установить значения по умолчанию
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # Помогайте пользователю ввести количество ядер ЦП и процент занятости, и, если введено, используйте значение по умолчанию.
				  read -e -p "Пожалуйста, введите количество ядер ЦП [по умолчанию:$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "Пожалуйста, введите диапазон процентных процентов использования процессора (например, 10-20) [по умолчанию:$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "Пожалуйста, введите процент использования памяти [по умолчанию:$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "Пожалуйста, введите время интервала SpeedTest (секунды) [по умолчанию:$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # Запустите контейнер Docker
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "Active Script Oracle Cloud Installation"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "Неверный выбор, пожалуйста, введите Y или N."
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "Oracle Cloud удаляет активный скрипт"
			  ;;

		  3)
		  clear
		  echo "Переустановить систему"
		  echo "--------------------------------"
		  echo -e "${gl_hong}Уведомление:${gl_bai}Установка рискованно потерять контакт, и те, кто обеспокоен, должны использовать его с осторожностью. Ожидается, что переустановка займет 15 минут, пожалуйста, резервную копию данных заранее."
		  read -e -p "Вы обязательно продолжите? (Y/N):" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "Пожалуйста, выберите систему для переустановки: 1. Debian12 | 2. Ubuntu20.04:" sys_choice

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
					echo "Неверный выбор, пожалуйста, введите."
					;;
				esac
			  done

			  read -e -p "Пожалуйста, введите свой переустаженный пароль:" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "System System System Oracle Cloud"
			  ;;
			[Nn])
			  echo "Отменен"
			  ;;
			*)
			  echo "Неверный выбор, пожалуйста, введите Y или N."
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  echo "Эта функция находится на стадии разработки, так что следите за обновлениями!"
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "Эта функция предоставлена ​​мастером JHB, благодаря ему!"
			  send_stats "IPv6 исправление"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "Неверный ввод!"
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
		echo -e "${gl_lv}Среда была установлена${gl_bai}контейнер:${gl_lv}$container_count${gl_bai}Зеркало:${gl_lv}$image_count${gl_bai}сеть:${gl_lv}$network_count${gl_bai}рулон:${gl_lv}$volume_count${gl_bai}"
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
		echo -e "${gl_lv}Среда установлена${gl_bai}  $output  $db_output"
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
	# send_stats "
	echo -e "${gl_huang}LDNMP Сайт Построение"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}Установите среду LDNMP${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}Установите WordPress${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}Установите форум Discuz${gl_huang}4.   ${gl_bai}Установите настольный столик Kadao Cloud"
	echo -e "${gl_huang}5.   ${gl_bai}Установите Apple CMS Film и Television Station${gl_huang}6.   ${gl_bai}Установите сеть цифровых карт Unicorn"
	echo -e "${gl_huang}7.   ${gl_bai}Установите веб -сайт Flarum Forum${gl_huang}8.   ${gl_bai}Установите сайт Loolweight Blog Typecho"
	echo -e "${gl_huang}9.   ${gl_bai}Установите платформу общей ссылки Linkstack${gl_huang}20.  ${gl_bai}Настройте динамический сайт"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}Установите только nginx${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}Перенаправление сайта"
	echo -e "${gl_huang}23.  ${gl_bai}Сайт обратный прокси-IP+порт${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}Обратный прокси -сайт сайта - доменное имя"
	echo -e "${gl_huang}25.  ${gl_bai}Установить платформу управления паролями Bitwarden${gl_huang}26.  ${gl_bai}Установите сайт блога Halo"
	echo -e "${gl_huang}27.  ${gl_bai}Установите AI рисунок, генератор слов${gl_huang}28.  ${gl_bai}Обратная прокси-нагрузка сайта"
	echo -e "${gl_huang}30.  ${gl_bai}Настройте статический сайт"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}Управление данными сайта${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}Резервное копирование всего сайта"
	echo -e "${gl_huang}33.  ${gl_bai}Временная удаленная резервная копия${gl_huang}34.  ${gl_bai}Восстановить все данные сайта"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}Защита среды LDNMP${gl_huang}36.  ${gl_bai}Оптимизировать среду LDNMP"
	echo -e "${gl_huang}37.  ${gl_bai}Обновление среды LDNMP${gl_huang}38.  ${gl_bai}Удаление среды LDNMP"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}Вернуться в главное меню"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "Пожалуйста, введите свой выбор:" sub_choice


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
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo "Адрес базы данных: MySQL"
	  echo "Имя базы данных:$dbname"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
	  echo "Префикс таблицы: discuz_"


		;;

	  4)
	  clear
	  # Кедао облачный рабочий стол
	  webname="可道云桌面"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo "Адрес базы данных: MySQL"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
	  echo "Имя базы данных:$dbname"
	  echo "Ведущий Redis: Redis"

		;;

	  5)
	  clear
	  # Apple CMS
	  webname="苹果CMS"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo "Адрес базы данных: MySQL"
	  echo "Порт базы данных: 3306"
	  echo "Имя базы данных:$dbname"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
	  echo "Префикс базы данных: MAC_"
	  echo "------------------------"
	  echo "Войдите по фоновому адресу после успешной установки"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # Одноногие счетные карты
	  webname="独脚数卡"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo "Адрес базы данных: MySQL"
	  echo "Порт базы данных: 3306"
	  echo "Имя базы данных:$dbname"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
	  echo ""
	  echo "Redis Адрес: Redis"
	  echo "Пароль Redis: не заполнен по умолчанию"
	  echo "Порт Redis: 6379"
	  echo ""
	  echo "URL -адрес веб -сайта: https: //$yuming"
	  echo "Фоновый путь входа в систему: /администратор"
	  echo "------------------------"
	  echo "Имя пользователя: администратор"
	  echo "Пароль: администратор"
	  echo "------------------------"
	  echo "Если Red Error0 появляется в правом верхнем углу при входе в систему, пожалуйста, используйте следующую команду:"
	  echo "Я также очень зол, что карта номеров единорога настолько неприятна, и будут такие проблемы!"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # Форум Flarum
	  webname="flarum论坛"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo "Адрес базы данных: MySQL"
	  echo "Имя базы данных:$dbname"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
	  echo "Префикс таблицы: Flarum_"
	  echo "Информация администратора установлена ​​самостоятельно"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo "Префикс базы данных: typecho_"
	  echo "Адрес базы данных: MySQL"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
	  echo "Имя базы данных:$dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo "Адрес базы данных: MySQL"
	  echo "Порт базы данных: 3306"
	  echo "Имя базы данных:$dbname"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo -e "[${gl_huang}1/6${gl_bai}] Загрузить исходный код PHP"
	  echo "-------------"
	  echo "В настоящее время разрешены только пакеты исходного кода в формате Zip. Пожалуйста, поместите пакеты исходного кода в/home/web/html/${yuming}В каталоге"
	  read -e -p "Вы также можете ввести ссылку загрузки, чтобы удаленно загрузить пакет исходного кода. Напрямую нажмите Enter, чтобы пропустить удаленную загрузку:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] Путь, в котором находится index.php"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "Пожалуйста, введите путь index.php, аналогично (/home/web/html/$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] Выберите версию PHP"
	  echo "-------------"
	  read -e -p "1. Последняя версия PHP | 2. Php7.4:" pho_v
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
		  echo "Неверный выбор, пожалуйста, введите."
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] Установите указанное расширение"
	  echo "-------------"
	  echo "Установленные расширения"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] Редактировать конфигурацию сайта"
	  echo "-------------"
	  echo "Нажмите любую клавишу, чтобы продолжить, и вы можете подробно установить конфигурацию сайта, например, псевдо-статическое содержание и т. Д."
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] Управление базой данных"
	  echo "-------------"
	  read -e -p "1. Я строю новый сайт 2. Я строю старый сайт и имею резервную копию базы данных:" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "Резервное копирование базы данных должно быть сжатым пакетом. Пожалуйста, поместите его в/дом/каталог, чтобы поддержать импорт данных резервного копирования Pagoda/1panel."
			  read -e -p "Вы также можете ввести ссылку загрузки, чтобы удаленно загрузить данные резервного копирования. Напрямую нажмите Enter" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "Данные таблицы импорта базы данных"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "Импорт базы данных завершен"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "Адрес базы данных: MySQL"
	  echo "Имя базы данных:$dbname"
	  echo "имя пользователя:$dbuse"
	  echo "пароль:$dbusepasswd"
	  echo "Префикс таблицы:$prefix"
	  echo "Информация администратора входа в систему установлена ​​самостоятельно"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
	  add_yuming
	  read -e -p "Пожалуйста, введите имя домена Jump:" reverseproxy
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
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
	  add_yuming
	  echo -e "Формат доменного имени:${gl_huang}google.com${gl_bai}"
	  read -e -p "Пожалуйста, введите свое имя доменного антигенерации:" fandai_yuming
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
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  send_stats "Установить$webname"
	  echo "Начните развертывание$webname"
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
	  echo -e "[${gl_huang}1/2${gl_bai}] Загрузить статический исходный код"
	  echo "-------------"
	  echo "В настоящее время разрешены только пакеты исходного кода в формате Zip. Пожалуйста, поместите пакеты исходного кода в/home/web/html/${yuming}В каталоге"
	  read -e -p "Вы также можете ввести ссылку загрузки, чтобы удаленно загрузить пакет исходного кода. Напрямую нажмите Enter, чтобы пропустить удаленную загрузку:" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] Путь, в котором находится index.html"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "Пожалуйста, введите путь к index.html, аналогично (/home/web/html/$yuming/index/）： " index_lujing

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
	  send_stats "LDNMP Environment Backup"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}Резервное копирование$backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "Файл резервного копирования был создан: /home /$backup_filename"
		read -e -p "Вы хотите перенести данные резервного копирования на удаленный сервер? (Y/N):" choice
		case "$choice" in
		  [Yy])
			read -e -p "Пожалуйста, введите IP удаленного сервера:" remote_ip
			if [ -z "$remote_ip" ]; then
			  echo "Ошибка: введите IP удаленного сервера."
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "Файл был перенесен в домашний каталог удаленного сервера."
			else
			  echo "Файл, который должен быть передан, не был найден."
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "Неверный выбор, пожалуйста, введите Y или N."
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "Временная удаленная резервная копия"
	  read -e -p "Введите IP удаленного сервера:" useip
	  read -e -p "Введите пароль удаленного сервера:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. Еженедельный резервный резерв 2. Ежедневная резервная копия"
	  read -e -p "Пожалуйста, введите свой выбор:" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "Выберите день недели для вашего еженедельного резервного копирования (0-6, 0 представляет воскресенье):" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "Выберите время для ежедневного резервного копирования (часы, 0-23):" hour
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
	  send_stats "LDNMP Restoration"
	  echo "Доступные резервные копии сайта"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "Введите, чтобы восстановить последнюю резервную копию, введите имя файла резервной копии, чтобы восстановить указанное резервное копирование, введите 0, чтобы выйти:" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # Если пользователь не вводит имя файла, используйте последний сжатый пакет
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}Декомпрессия делается$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "Сжатие не было найдено."
	  fi

	  ;;

	35)
	  send_stats "LDNMP Environment Defense"
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
			  echo -e "Программа защиты веб -сайта сервера${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. Установите защитную программу"
			  echo "------------------------"
			  echo "5. Просмотреть запись перехвата SSH 6. Просмотреть запись перехвата веб -сайтов"
			  echo "7. Просмотреть список правил обороны 8. Просмотреть мониторинг журналов в реальном времени"
			  echo "------------------------"
			  echo "11. Настройка параметров перехвата 12. Очистить все заблокированные IPS"
			  echo "------------------------"
			  echo "21. Cloudflare Mode 22. Высокая нагрузка на 5 секунд щит"
			  echo "------------------------"
			  echo "31. Включите WAF 32. Выключите WAF"
			  echo "33. Включите DDOS Defense 34. Выключите защиту DDOS"
			  echo "------------------------"
			  echo "9. удалить программу обороны"
			  echo "------------------------"
			  echo "0. Вернитесь в предыдущее меню"
			  echo "------------------------"
			  read -e -p "Пожалуйста, введите свой выбор:" sub_choice
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
					  echo "Программа защиты Fail2ban была удалена"
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
					  send_stats "Режим CloudFlare"
					  echo "Перейдите в верхний правый угол фона CF, выберите жетон API слева и получите глобальный ключ API"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "Введите номер учетной записи CF:" cfuser
					  read -e -p "Введите глобальный ключ API для CF:" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /path/to/fail2ban/config/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "Режим CloudFlare настроен для просмотра записей перехвата на фоне CF, Site-Security-Events"
					  ;;

				  22)
					  send_stats "Высокая нагрузка на 5 секунд щит"
					  echo -e "${gl_huang}Веб -сайт автоматически обнаруживается каждые 5 минут. Когда высокая нагрузка будет обнаружена, щит будет автоматически включен, а низкая нагрузка будет автоматически отключаться в течение 5 секунд.${gl_bai}"
					  echo "--------------"
					  echo "Получить параметры CF:"
					  echo -e "Перейдите в верхний правый угол фона CF, выберите жетон API слева и получите его${gl_huang}Global API Key${gl_bai}"
					  echo -e "Перейдите в правом нижнем углу страницы сводного имени доменного домена CF, чтобы получить${gl_huang}Идентификатор региона${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "Введите номер учетной записи CF:" cfuser
					  read -e -p "Введите глобальный ключ API для CF:" cftoken
					  read -e -p "Введите идентификатор региона доменного имени в CF:" cfzonID

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
						  echo "Был добавлен сценарий открытия автоматического экрана с высокой нагрузкой"
					  else
						  echo "Автоматический скрипт щита уже существует, не нужно добавлять его"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "Сайт WAF включен"
					  send_stats "Сайт WAF включен"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "Сайт WAF был закрыт"
					  send_stats "Сайт WAF был закрыт"
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
			  send_stats "Оптимизировать среду LDNMP"
			  echo "Оптимизировать среду LDNMP"
			  echo "------------------------"
			  echo "1. Стандартный режим 2. Высокий режим производительности (рекомендуется 2H2G или выше)"
			  echo "------------------------"
			  echo "0. Вернитесь в предыдущее меню"
			  echo "------------------------"
			  read -e -p "Пожалуйста, введите свой выбор:" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "Стандартный режим сайта"

				  # NGINX TUNing
				  sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

				  # PHP настройка
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHP настройка
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql tuning
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced


				  echo "Среда LDNMP была установлена ​​в стандартный режим"

					  ;;
				  2)
				  send_stats "Режим высокой производительности сайта"

				  # NGINX TUNing
				  sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

				  # PHP настройка
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHP настройка
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysql tuning
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

				  echo "Среда LDNMP была установлена ​​на высокопроизводительный режим"

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
		  send_stats "Обновление среды LDNMP"
		  echo "Обновление среды LDNMP"
		  echo "------------------------"
		  ldnmp_v
		  echo "Откройте для себя новую версию компонентов"
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
		  echo "1. Обновление nginx 2. Обновление MySQL 3. Обновление PHP 4. Обновление Redis"
		  echo "------------------------"
		  echo "5. Обновите полную среду"
		  echo "------------------------"
		  echo "0. Вернитесь в предыдущее меню"
		  echo "------------------------"
		  read -e -p "Пожалуйста, введите свой выбор:" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "Пожалуйста, введите${ldnmp_pods}Номер версии (например: 8.0 8.3 8.4 9.0) (введите, чтобы получить последнюю версию):" version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "обновлять$ldnmp_pods"
			  echo "обновлять${ldnmp_pods}Заканчивать"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "Пожалуйста, введите${ldnmp_pods}Номер версии (например: 7.4 8.0 8.1 8.2 8.3) (введите, чтобы получить последнюю версию):" version
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
			  send_stats "обновлять$ldnmp_pods"
			  echo "обновлять${ldnmp_pods}Заканчивать"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  restart_redis
			  send_stats "обновлять$ldnmp_pods"
			  echo "обновлять${ldnmp_pods}Заканчивать"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "Полностью обновить среду LDNMP"
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
		send_stats "Удаление среды LDNMP"
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
			echo "Неверный выбор, пожалуйста, введите Y или N."
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "Неверный ввод!"
	esac
	break_end

  done

}



linux_panel() {

	while true; do
	  clear
	  # send_stats "Рынок приложений"
	  echo -e "Рынок приложений"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Официальная версия панели Baota${gl_kjlan}2.   ${gl_bai}Aapanel International Edition"
	  echo -e "${gl_kjlan}3.   ${gl_bai}1Panel New Generation Panel${gl_kjlan}4.   ${gl_bai}Nginxproxymanager Visual Panel"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Alist Multi Store File Sirece Sport${gl_kjlan}6.   ${gl_bai}Ubuntu Remote Desktop Web Edition"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Панель мониторинга VPS -зонда Nezha${gl_kjlan}8.   ${gl_bai}QB Offline BT Magnetic Download Panel"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Poste.io программа почтового сервера${gl_kjlan}10.  ${gl_bai}Multiplayer Multiplayer онлайн -чат"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Программное обеспечение для управления проектами Zendao${gl_kjlan}12.  ${gl_bai}Платформа управления задачами на панели Qinglong"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Cloudreve Network Disk${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}Простая программа управления картинками кровати"
	  echo -e "${gl_kjlan}15.  ${gl_bai}Эмби мультимедийная система управления${gl_kjlan}16.  ${gl_bai}Панель испытаний на скорость скорости"
	  echo -e "${gl_kjlan}17.  ${gl_bai}Adguardhome Adware${gl_kjlan}18.  ${gl_bai}OnlyOffice Online Office Office"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Громовой панель брандмауэра WAF WAF${gl_kjlan}20.  ${gl_bai}панель управления контейнерами портайнмера"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}Веб -версия VSCODE${gl_kjlan}22.  ${gl_bai}UPTIMEKUMA Мониторинг инструмент"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Записки для записи веб -страницы${gl_kjlan}24.  ${gl_bai}Webtop удаленное настольное веб -издание${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${gl_bai}NextCloud Network Disk${gl_kjlan}26.  ${gl_bai}QD-тодайская структура управления задачами"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Панель управления стеком контейнеров в док -контейнерах${gl_kjlan}28.  ${gl_bai}Инструмент тестирования скорости"
	  echo -e "${gl_kjlan}29.  ${gl_bai}сайт поиска агрегации Searxng${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}Система частных альбомов PhotoPrism"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Сборник инструментов StirlingPDF${gl_kjlan}32.  ${gl_bai}Бесплатное программное обеспечение для онлайн -диаграммы Drawio${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Навигационная панель Солнца${gl_kjlan}34.  ${gl_bai}Платформа обмена файлами pingvin-share"
	  echo -e "${gl_kjlan}35.  ${gl_bai}Минималистский круг друзей${gl_kjlan}36.  ${gl_bai}Сайт агрегирования чата LobeChatai"
	  echo -e "${gl_kjlan}37.  ${gl_bai}Myip Toolbox${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}Семейное ведро Xiaoya alist"
	  echo -e "${gl_kjlan}39.  ${gl_bai}Bililive Live Live Toolsing инструмент записи трансляции${gl_kjlan}40.  ${gl_bai}Webssh Web Version SSH Инструмент подключения"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}Панель управления мыши${gl_kjlan}42.  ${gl_bai}Инструмент удаленного подключения Nexte"
	  echo -e "${gl_kjlan}43.  ${gl_bai}Rustdesk Remote Desk (сервер)${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}Rustdesk Remote Dest (Relay)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${gl_bai}Станция ускорения Docker${gl_kjlan}46.  ${gl_bai}Станция ускорения GitHub${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${gl_bai}Прометей мониторинг${gl_kjlan}48.  ${gl_bai}Прометей (мониторинг хоста)"
	  echo -e "${gl_kjlan}49.  ${gl_bai}Prometheus (мониторинг контейнеров)${gl_kjlan}50.  ${gl_bai}Инструмент мониторинга пополнения"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${gl_bai}PVE куриная панель${gl_kjlan}52.  ${gl_bai}DPANEL Container Panels"
	  echo -e "${gl_kjlan}53.  ${gl_bai}Llama3 чат модель AI${gl_kjlan}54.  ${gl_bai}AMH Host Host Websity Панель управления строительством"
	  echo -e "${gl_kjlan}55.  ${gl_bai}FRP Intranet Purnation (сторона сервера)${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${gl_bai}FRP Intranet Purnation (клиент)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${gl_bai}DeepSeek Chat Ai Big Model${gl_kjlan}58.  ${gl_bai}Dify Big Model Base Base${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${gl_bai}Newapi Big Model Asset Management${gl_kjlan}60.  ${gl_bai}Jumpserver с открытым исходным кодом"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${gl_bai}Онлайн -сервер перевода${gl_kjlan}62.  ${gl_bai}Ragflow Big Model Base Base"
	  echo -e "${gl_kjlan}63.  ${gl_bai}OpenWebui самостоятельно отправленная платформой ИИ${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}IT-инструмент Tools"
	  echo -e "${gl_kjlan}65.  ${gl_bai}платформа рабочего процесса автоматизации N8N${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}инструмент загрузки видео YT-DLP"
	  echo -e "${gl_kjlan}67.  ${gl_bai}DDNS-GO Dynamic DNS-инструмент управления DNS${gl_huang}★${gl_bai}               ${gl_kjlan}68.  ${gl_bai}Платформа управления сертификатами allinssl"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

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
			send_stats "Построить Неза"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "Nezha Monitoring$check_docker $update_status"
				echo "С открытым исходным кодом, легкий и простой в использовании инструменты мониторинга и эксплуатации и обслуживания сервера"
				echo "Введение видео: https://www.bilibili.com/video/bv1wv421c71t?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1. Используйте"
				echo "------------------------"
				echo "5. Добавьте доменное имя доступа 6. Удалить домен и имя домена"
				echo "7. Разрешить IP+ Port Access 8. Block IP+ Access Access"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Введите свой выбор:" choice

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
						echo "${docker_name}Настройки домена домена"
						send_stats "${docker_name}Настройки домена домена"
						add_yuming
						ldnmp_Proxy ${yuming} ${ipv4_address} ${docker_port}
						block_container_port "$docker_name" "$ipv4_address"
						;;

					6)
						echo "Формат доменного имени example.com не поставляется с https: //"
						web_del
						;;

					7)
						send_stats "Разрешить IP -доступ${docker_name}"
						clear_container_rules "$docker_name" "$ipv4_address"
						;;

					8)
						send_stats "Block IP Access${docker_name}"
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
			send_stats "Построить почтовое отделение"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "Почтовые услуги$check_docker $update_status"
				echo "poste.io - это решение для сервера почтового сервера с открытым исходным кодом."
				echo "Введение видео: https://www.bilibili.com/video/bv1wv421c71t?t=0.1"

				echo ""
				echo "Обнаружение порта"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
				  echo -e "${gl_lv}порт$portВ настоящее время доступно${gl_bai}"
				else
				  echo -e "${gl_hong}порт$portВ настоящее время не доступно${gl_bai}"
				fi
				echo ""

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "Адрес доступа:"
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1. Установите 2. Обновление 3. Удалить"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Введите свой выбор:" choice

				case $choice in
					1)
						check_disk_space 2
						read -e -p "Пожалуйста, установите имя домена электронной почты, например, mail.yuming.com:" yuming
						mkdir -p /home/docker
						echo "$yuming" > /home/docker/mail.txt
						echo "------------------------"
						ip_address
						echo "Сначала проанализировать эти DNS -записи"
						echo "A           mail            $ipv4_address"
						echo "CNAME       imap            $yuming"
						echo "CNAME       pop             $yuming"
						echo "CNAME       smtp            $yuming"
						echo "MX          @               $yuming"
						echo "TXT         @               v=spf1 mx ~all"
						echo "TXT         ?               ?"
						echo ""
						echo "------------------------"
						echo "Нажмите любую клавишу, чтобы продолжить ..."
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
						echo "poste.io был установлен"
						echo "------------------------"
						echo "Вы можете получить доступ к poste.io, используя следующий адрес:"
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
						echo "poste.io был установлен"
						echo "------------------------"
						echo "Вы можете получить доступ к poste.io, используя следующий адрес:"
						echo "https://$yuming"
						echo ""
						;;
					3)
						docker rm -f mailserver
						docker rmi -f analogic/poste.io
						rm /home/docker/mail.txt
						rm -rf /home/docker/mail
						echo "Приложение было удалено"
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
				echo "Установлен"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "Rocket.chat был установлен"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "Приложение было удалено"
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
				echo "Установлен"
				check_docker_app_ip
			}


			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}


			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "Приложение было удалено"
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
			send_stats "Построить гром"

			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "Громовой сервис пула$check_docker"
				echo "Lei Chi - это панель программы брандмауэра на сайте WAF, разработанная технологией Changting Technology, которая может отменить сайт агентства для автоматизированной защиты."
				echo "Введение видео: https://www.bilibili.com/video/bv1mz421t74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1. Установите 2. Обновление 3. Сброс пароля 4. Удалить"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Введите свой выбор:" choice

				case $choice in
					1)
						install_docker
						check_disk_space 5
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
						clear
						echo "Панель WAF бассейна Thunder"
						check_docker_app_ip
						docker exec safeline-mgt resetadmin

						;;

					2)
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
						docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
						echo ""
						clear
						echo "Громовой пул панель WAF была обновлена"
						check_docker_app_ip
						;;
					3)
						docker exec safeline-mgt resetadmin
						;;
					4)
						cd /data/safeline
						docker compose down --rmi all
						echo "Если вы являетесь каталогом установки по умолчанию, проект теперь удален. Если вы настраиваете каталог установки, вам нужно перейти в каталог установки, чтобы выполнить его самостоятельно:"
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
			local docker_url="Официальное веб -сайт Введение:${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
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
			send_stats "Семейное ведро Сяоя"
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
				echo "Установлен"
				check_docker_app_ip
				echo "Первоначальное имя пользователя и пароль: администратор"
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
				echo "Приложение было удалено"
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
			send_stats "PVE курица"
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
				echo "Установлен"
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
				echo "Приложение было удалено"
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
				echo "Установлен"
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
				echo "Установлен"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "Приложение было удалено"
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
				echo "Установлен"
				check_docker_app_ip
				echo "Первоначальное имя пользователя: администратор"
				echo "Первоначальный пароль: Changeme"
			}


			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "Приложение было обновлено"
			}


			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "Приложение было удалено"
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
				echo "Установлен"
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
				echo "Приложение было удалено"
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
			  echo "Неверный ввод!"
			  ;;
	  esac
	  break_end

	done
}


linux_work() {

	while true; do
	  clear
	  send_stats "Мое рабочее пространство"
	  echo -e "Мое рабочее пространство"
	  echo -e "Система предоставит вам рабочее пространство, которое можно запустить на бэкэнд, которую вы можете использовать для выполнения долгосрочных задач."
	  echo -e "Даже если вы отключите SSH, задачи в рабочем пространстве не будут прерваны, а задачи на заднем плане будут резидентами."
	  echo -e "${gl_huang}намекать:${gl_bai}После входа в рабочую область используйте Ctrl+B и нажмите D в одиночку, чтобы выйти из рабочего пространства!"
	  echo -e "${gl_kjlan}------------------------"
	  echo "Список существующих рабочих пространств в настоящее время"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Рабочая область № 1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Рабочая область № 2"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Рабочая область № 3"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Рабочая область № 4"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Рабочая область № 5"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Рабочая область № 6"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Рабочая область № 7"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Рабочая область № 8"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Рабочая область № 9"
	  echo -e "${gl_kjlan}10.  ${gl_bai}Рабочая область № 10"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}Режим резидента SSH${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}Создать/введите рабочую область"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Введите команды в фоновое рабочее пространство"
	  echo -e "${gl_kjlan}24.  ${gl_bai}Удалить указанное рабочее пространство"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "Начните рабочее пространство$SESSION_NAME"
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
			  send_stats "Режим резидента SSH"
			  echo -e "Режим резидента SSH${tmux_sshd_status}"
			  echo "После того, как соединение SSH будет включено, оно напрямую введет режим резидента и вернется в предыдущее рабочее состояние."
			  echo "------------------------"
			  echo "1. Включите 2. Выключите"
			  echo "------------------------"
			  echo "0. Вернитесь в предыдущее меню"
			  echo "------------------------"
			  read -e -p "Пожалуйста, введите свой выбор:" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "Начните рабочее пространство$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\ n# автоматически введите сеанс TMUX \ nif [[-Z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
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
			  read -e -p "Пожалуйста, введите имя созданного или введенного рабочего пространства, например, 1001 KJ001 Work1:" SESSION_NAME
			  tmux_run
			  send_stats "Пользовательская рабочая область"
			  ;;


		  23)
			  read -e -p "Пожалуйста, введите команду, которую хотите выполнить в фоновом режиме, например: curl -fssl https://get.docker.com | SH:" tmuxd
			  tmux_run_d
			  send_stats "Введите команды в фоновое рабочее пространство"
			  ;;

		  24)
			  read -e -p "Пожалуйста, введите имя рабочего пространства, которое вы хотите удалить:" gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "Удалить рабочее пространство"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "Неверный ввод!"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # send_stats "системные инструменты"
	  echo -e "Системные инструменты"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Установить ярлычные клавиши запуска скрипта${gl_kjlan}2.   ${gl_bai}Измените пароль входа в систему"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Режим регистрации пароля корня${gl_kjlan}4.   ${gl_bai}Установите указанную версию Python"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Откройте все порты${gl_kjlan}6.   ${gl_bai}Изменить порт соединения SSH"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Оптимизировать адрес DNS${gl_kjlan}8.   ${gl_bai}Система повторной установки в один клик${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}Отключить корневую учетную запись для создания новой учетной записи${gl_kjlan}10.  ${gl_bai}Переключить приоритет IPv4/IPv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Проверьте статус оккупации порта${gl_kjlan}12.  ${gl_bai}Изменить размер виртуальной памяти"
	  echo -e "${gl_kjlan}13.  ${gl_bai}Управление пользователями${gl_kjlan}14.  ${gl_bai}Пользователь/генератор пароля"
	  echo -e "${gl_kjlan}15.  ${gl_bai}Системная регулировка часового пояса${gl_kjlan}16.  ${gl_bai}Настройка ускорения BBR3"
	  echo -e "${gl_kjlan}17.  ${gl_bai}Брандмауэр продвинутый менеджер${gl_kjlan}18.  ${gl_bai}Измените имя хоста"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Источник обновления системы переключения${gl_kjlan}20.  ${gl_bai}Управление задачами времени"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}Расположение местного хозяина${gl_kjlan}22.  ${gl_bai}SSH защитная программа"
	  echo -e "${gl_kjlan}23.  ${gl_bai}Автоматическое отключение тока ограничения${gl_kjlan}24.  ${gl_bai}Режим входа в лоб"
	  echo -e "${gl_kjlan}25.  ${gl_bai}Мониторинг системы TG-Bot и раннее предупреждение${gl_kjlan}26.  ${gl_bai}Исправление уязвимостей с высоким риском Opensh (Xiuyuan)"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat Hat Linux Upgrade${gl_kjlan}28.  ${gl_bai}Оптимизация параметров ядра в системе Linux${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}Инструмент сканирования вируса${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}Файловый менеджер"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}Переключение языка системы${gl_kjlan}32.  ${gl_bai}Инструмент украшения командной строки${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}Установите мусорное ведро для переработки системы${gl_kjlan}34.  ${gl_bai}Резервное копирование системы и восстановление"
	  echo -e "${gl_kjlan}35.  ${gl_bai}инструмент удаленного подключения SSH${gl_kjlan}36.  ${gl_bai}Инструмент управления распределением жесткого диска"
	  echo -e "${gl_kjlan}37.  ${gl_bai}История командной строки${gl_kjlan}38.  ${gl_bai}инструмент дистанционной синхронизации RSYNC"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}Доска объявлений${gl_kjlan}66.  ${gl_bai}Оптимизация системы универсальной системы${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}Перезагрузите сервер${gl_kjlan}100. ${gl_bai}Конфиденциальность и безопасность"
	  echo -e "${gl_kjlan}101. ${gl_bai}Усовершенствованное использование команды K${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}Сценарий удаления технического льва"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "Пожалуйста, введите свой клавиша сочетания (введите 0 для выхода):" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "Клавиши для сочетания установлены"
				  send_stats "Клавиши для сценария были установлены"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "Установите пароль для входа в систему"
			  echo "Установите пароль для входа в систему"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "Режим пароля корня"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "Управление версией PY"
			echo "Управление версией Python"
			echo "Введение видео: https://www.bilibili.com/video/bv1pm42157ck?t=0.1"
			echo "---------------------------------------"
			echo "Эта функция плавно устанавливает любую версию, официально поддерживаемую Python!"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "Текущий номер версии Python:${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "Рекомендуемая версия: 3.12 3.11 3.10 3.9 3.8 2,7"
			echo "Запрос больше версий: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "Введите номер версии Python, который вы хотите установить (введите 0 для выхода):" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "Скрипт PY Management"
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
					echo "Неизвестный менеджер пакетов!"
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
			echo -e "Текущий номер версии Python:${gl_huang}$VERSION${gl_bai}"
			send_stats "Переключить скрипт py версия"

			  ;;

		  5)
			  root_use
			  send_stats "Открытый порт"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "Все порты открыты"

			  ;;
		  6)
			root_use
			send_stats "Изменить порт SSH"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# Прочитайте текущий номер порта SSH
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# Распечатайте текущий номер порта SSH
				echo -e "Текущий номер порта SSH:${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "Номера с номерами портов в диапазоне от 1 до 65535. (Введите 0, чтобы выходить)"

				# Предложите пользователю ввести новый номер порта SSH
				read -e -p "Пожалуйста, введите новый номер порта SSH:" new_port

				# Определите, находится ли номер порта в пределах достоверного диапазона
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "Порт SSH был изменен"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "Выход модификации порта SSH"
						break
					else
						echo "Номер порта недействителен, введите число от 1 до 65535."
						send_stats "Неверный ввод порта SSH"
						break_end
					fi
				else
					echo "Ввод недействителен, введите номер."
					send_stats "Неверный ввод порта SSH"
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
			send_stats "Новые пользователи отключают root"
			read -e -p "Пожалуйста, введите новое имя пользователя (введите 0 для выхода):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "Операция была завершена."
			;;


		  10)
			root_use
			send_stats "Установите приоритет V4/V6"
			while true; do
				clear
				echo "Установите приоритет V4/V6"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "Текущие настройки приоритета сети:${gl_huang}IPv4${gl_bai}приоритет"
				else
					echo -e "Текущие настройки приоритета сети:${gl_huang}IPv6${gl_bai}приоритет"
				fi
				echo ""
				echo "------------------------"
				echo "1. Приоритет IPv4 2. Приоритет IPv6 3. Инструмент ремонта IPv6"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Выберите предпочтительную сеть:" choice

				case $choice in
					1)
						sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
						echo "Переключен на приоритет IPv4"
						send_stats "Переключен на приоритет IPv4"
						;;
					2)
						sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
						echo "Переключен на приоритет IPv6"
						send_stats "Переключен на приоритет IPv6"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "Эта функция предоставлена ​​мастером JHB, благодаря ему!"
						send_stats "IPv6 исправление"
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
			send_stats "Настройка виртуальной памяти"
			while true; do
				clear
				echo "Настройка виртуальной памяти"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "Текущая виртуальная память:${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. Назначить 1024m 2. Назначить 2048m 3. Назначить 4096m 4. Пользовательский размер"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите свой выбор:" choice

				case "$choice" in
				  1)
					send_stats "1G виртуальная память была установлена"
					add_swap 1024

					;;
				  2)
					send_stats "2G виртуальная память была установлена"
					add_swap 2048

					;;
				  3)
					send_stats "4G виртуальная память была установлена"
					add_swap 4096

					;;

				  4)
					read -e -p "Пожалуйста, введите размер виртуальной памяти (блок M):" new_swap
					add_swap "$new_swap"
					send_stats "Пользовательская виртуальная память была установлена"
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
				send_stats "Управление пользователями"
				echo "Список пользователей"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "Операция учетной записи"
				  echo "------------------------"
				  echo "1. Создайте обычную учетную запись 2. Создайте премиум -аккаунт"
				  echo "------------------------"
				  echo "3. Дайте самые высокие разрешения 4. Отмените самые высокие разрешения"
				  echo "------------------------"
				  echo "5. Удалить учетную запись"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

				  case $sub_choice in
					  1)
					   # Позвольте пользователю ввести новое имя пользователя
					   read -e -p "Пожалуйста, введите новое имя пользователя:" new_username

					   # Создайте нового пользователя и установите пароль
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "Операция была завершена."
						  ;;

					  2)
					   # Позвольте пользователю ввести новое имя пользователя
					   read -e -p "Пожалуйста, введите новое имя пользователя:" new_username

					   # Создайте нового пользователя и установите пароль
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # Предоставить новым пользователям разрешения Sudo
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   echo "Операция была завершена."

						  ;;
					  3)
					   read -e -p "Пожалуйста, введите свое имя пользователя:" username
					   # Предоставить новым пользователям разрешения Sudo
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
						  ;;
					  4)
					   read -e -p "Пожалуйста, введите свое имя пользователя:" username
					   # Удалить разрешения SUDO пользователя из файла Sudoers
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "Пожалуйста, введите имя пользователя, чтобы удалить:" username
					   # Удалить пользователя и его домашний каталог
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
			send_stats "Пользовательский генератор"
			echo "Случайное имя пользователя"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "Случайное имя пользователя$i: $username"
			done

			echo ""
			echo "Случайное имя"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# Сгенерировать 5 случайных имен пользователей
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "Случайное имя пользователя$i: $user_name"
			done

			echo ""
			echo "Случайный Uuid"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "Случайный Uuid$i: $uuid"
			done

			echo ""
			echo "16-битный случайный пароль"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "Случайный пароль$i: $password"
			done

			echo ""
			echo "32-битный случайный пароль"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "Случайный пароль$i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "Смену часовой пояс"
			while true; do
				clear
				echo "Информация о системном времени"

				# Получите текущий часовой пояс системы
				local timezone=$(current_timezone)

				# Получите текущее системное время
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# Показать часовой пояс и время
				echo "Текущий системный часовой пояс:$timezone"
				echo "Текущее системное время:$current_time"

				echo ""
				echo "Переключение часового пояса"
				echo "------------------------"
				echo "Азия"
				echo "1. Шанхайский время в Китае 2. Гонконгский время в Китае"
				echo "3. Tokyo Time в Японии 4. Время в Сеуле в Южной Корее"
				echo "5. Сингапурское время 6. Калькутта Время в Индии"
				echo "7. Dubai Time в ОАЭ 8. Сиднейское время в Австралии"
				echo "9. Время в Бангкоке, Таиланд"
				echo "------------------------"
				echo "Европа"
				echo "11. Лондонское время в Великобритании 12. Парижское время во Франции"
				echo "13. Берлинское время, Германия 14. Москва время, Россия"
				echo "15. Utrecht Time в Нидерландах 16. Мадридское время в Испании"
				echo "------------------------"
				echo "Америка"
				echo "21. Западное время 22. Восточное время"
				echo "23. Канадское время 24. Мексиканское время"
				echo "25. Бразилия 26. Аргентина времени"
				echo "------------------------"
				echo "31. UTC Global Standard Time"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите свой выбор:" sub_choice


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
		  send_stats "Измените имя хоста"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "Текущее имя хоста:${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "Пожалуйста, введите новое имя хоста (введите 0 для выхода):" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # Другие системы, такие как Debian, Ubuntu, Centos и т. Д.
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

				  echo "Имя хоста было изменено на:$new_hostname"
				  send_stats "Имя хоста было изменено"
				  sleep 1
			  else
				  echo "Выйдет, имя хоста не изменилось."
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "Измените источник обновления системы"
		  clear
		  echo "Выберите область источника обновления"
		  echo "Подключитесь к Linuxmirrors, чтобы переключить источник обновления системы"
		  echo "------------------------"
		  echo "1. МАЙСКАЛЬНЫЙ Китай [DEFAULT] 2. МАЙКЛИЧЕСКИЙ КИТАЙС"
		  echo "------------------------"
		  echo "0. Вернитесь в предыдущее меню"
		  echo "------------------------"
		  read -e -p "Введите свой выбор:" choice

		  case $choice in
			  1)
				  send_stats "Источник по умолчанию в материковом Китае"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "Источник образования в материковом Китае"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "Зарубежное происхождение"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
				  echo "Отменен"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "Управление задачами времени"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "Временный список задач"
				  crontab -l
				  echo ""
				  echo "работать"
				  echo "------------------------"
				  echo "1. Добавить задачи времени 2. Удалить задачи времени 3. Редактировать задачи по времени"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "Пожалуйста, введите команду выполнения для новой задачи:" newquest
						  echo "------------------------"
						  echo "1. Ежемесячные задачи 2. Еженедельные задачи"
						  echo "3. Ежедневные задачи 4. Почасовые задачи"
						  echo "------------------------"
						  read -e -p "Пожалуйста, введите свой выбор:" dingshi

						  case $dingshi in
							  1)
								  read -e -p "Выберите, какой день каждого месяца для выполнения задач? (1-30):" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "Выберите, какую неделю выполнить задачу? (0-6, 0 представляет воскресенье):" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "Выберите, в какое время выполнять задачи каждый день? (Часы, 0-23):" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "Введите в какую минуту часа выполнить задачу? (МИНС, 0-60):" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "Добавить временные задачи"
						  ;;
					  2)
						  read -e -p "Пожалуйста, введите ключевые слова, которые необходимо удалить:" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "Удалить временные задачи"
						  ;;
					  3)
						  crontab -e
						  send_stats "Редактировать задачи времени"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "Расположение местного хозяина"
			  while true; do
				  clear
				  echo "Список анализа нативного хоста"
				  echo "Если вы добавите здесь сопоставления Parse, динамический анализ больше не будет использоваться"
				  cat /etc/hosts
				  echo ""
				  echo "работать"
				  echo "------------------------"
				  echo "1. Добавьте новый анализ 2. Удалить адресачрекающий адрес"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" host_dns

				  case $host_dns in
					  1)
						  read -e -p "Пожалуйста, введите новый формат записи анализа: 110.25.5.33 kejilion.pro:" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "Спонирование местного хозяина было добавлено"

						  ;;
					  2)
						  read -e -p "Пожалуйста, введите ключевые слова анализа контента, которые необходимо удалить:" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "Распокация и удаление местного хозяина"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "SSH защита"
		  while true; do
			if [ -x "$(command -v fail2ban-client)" ] ; then
				clear
				remove fail2ban
				rm -rf /etc/fail2ban
			else
				clear
				docker_name="fail2ban"
				check_docker_app
				echo -e "SSH защитная программа$check_docker"
				echo "Fail2ban - это инструмент SSH для предотвращения грубой силы"
				echo "Официальное веб -сайт Введение:${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. Установите защитную программу"
				echo "------------------------"
				echo "2. Просмотреть записи об перехвате SSH"
				echo "3. Мониторинг журналов в реальном времени"
				echo "------------------------"
				echo "9. удалить программу обороны"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите свой выбор:" sub_choice
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
						echo "Программа защиты Fail2ban была удалена"
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
			send_stats "Функция отключения лимита тока"
			while true; do
				clear
				echo "Функция отключения лимита тока"
				echo "Введение видео: https://www.bilibili.com/video/bv1mc411j7qd?t=0.1"
				echo "------------------------------------------------"
				echo "Текущее использование трафика, перезапуск расчета трафика сервера будет очищено!"
				output_status
				echo -e "${gl_kjlan}Всего получение:${gl_bai}$rx"
				echo -e "${gl_kjlan}Всего отправить:${gl_bai}$tx"

				# Проверьте, существует ли файл Limiting_shut_down.sh
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# Получите значение threshold_gb
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}Текущий установление ограничения тока входной станции вступительно:${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}Текущий предел исходящего тока.${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}Функция отключения лимита тока не включена${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "Система обнаружит, достигнет ли фактический трафик по порогу каждую минуту, и сервер будет автоматически выключаться после его прибытия!"
				echo "------------------------"
				echo "1. Включите функцию отключения лимита тока 2. Деактивировать функцию отключения предела тока"
				echo "------------------------"
				echo "0. Вернитесь в предыдущее меню"
				echo "------------------------"
				read -e -p "Пожалуйста, введите свой выбор:" Limiting

				case "$Limiting" in
				  1)
					# Введите новый размер виртуальной памяти
					echo "Если фактический сервер имеет 100G трафик, порог может быть установлен на 95G и заранее отключить питание, чтобы избежать ошибок трафика или переполнения."
					read -e -p "Пожалуйста, введите порог входящего трафика (единица g, по умолчанию 100 г):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "Пожалуйста, введите порог исходящего трафика (единица g, по умолчанию 100 г):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "Пожалуйста, введите дату сброса трафика (сброс по умолчанию 1 -го числа каждого месяца):" cz_day
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
					echo "Отключение лимита тока было установлено"
					send_stats "Отключение лимита тока было установлено"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "Функция отключения лимита тока была отключена"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "Вход в личный ключ"
			  while true; do
				  clear
			  	  echo "Режим входа в лоб"
			  	  echo "Введение видео: https://www.bilibili.com/video/bv1q4421x78n?t=209.4"
			  	  echo "------------------------------------------------"
			  	  echo "Будет сгенерирована пара ключей, более безопасный способ входа в SSH"
				  echo "------------------------"
				  echo "1. Сгенерируйте новую клавишу 2. Импортируйте существующую клавишу 3. Просмотреть собственную клавишу"
				  echo "------------------------"
				  echo "0. Вернитесь в предыдущее меню"
				  echo "------------------------"
				  read -e -p "Пожалуйста, введите свой выбор:" host_dns

				  case $host_dns in
					  1)
				  		send_stats "Генерировать новый ключ"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "Импортировать существующий открытый ключ"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "Посмотреть местный секретный ключ"
						echo "------------------------"
						echo "Информация об открытом ключе"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "Информация о частном ключе"
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
			  send_stats "Телеграмма предупреждение"
			  echo "Мониторинг TG-BOT и раннее предупреждение"
			  echo "Введение видео: https://youtu.be/vll-eb3z_ty"
			  echo "------------------------------------------------"
			  echo "Вам необходимо настроить API TG Robot и идентификатор пользователя для получения ранних предупреждений, чтобы реализовать мониторинг в реальном времени и раннее предупреждение нативного процессора, памяти, жесткого диска, трафика и входа в систему SSH"
			  echo "После достижения порога пользователь будет отправлен пользователю"
			  echo -e "${gl_hui}- Что касается трафика, перезапуск сервера пересчитает-${gl_bai}"
			  read -e -p "Вы обязательно продолжите? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  send_stats "Предупреждение телеграммы включено"
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

				  # Добавить в ~/.profile файл
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "Система раннего предупреждения TG-Bot началась"
				  echo -e "${gl_hui}Вы также можете поместить файл предупреждения tg-notify.sh в корневом каталоге на других машинах и использовать его напрямую!${gl_bai}"
				  ;;
				[Nn])
				  echo "Отменен"
				  ;;
				*)
				  echo "Неверный выбор, пожалуйста, введите Y или N."
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "Исправить уязвимости высокого риска в SSH"
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
			  send_stats "История командной строки"
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
			send_stats "Доска объявлений"
			echo "Доска объявлений Technology Lion была перенесена в официальное сообщество! Пожалуйста, оставьте сообщение в официальном сообществе!"
			echo "https://bbs.kejilion.pro/"
			  ;;

		  66)

			  root_use
			  send_stats "Огнетающая настройка"
			  echo "Оптимизация системы универсальной системы"
			  echo "------------------------------------------------"
			  echo "Следующее будет управлять и оптимизировано"
			  echo "1. Обновите систему до последнего"
			  echo "2. Очистка системных мусорных файлов"
			  echo -e "3. Настройка виртуальной памяти${gl_huang}1G${gl_bai}"
			  echo -e "4. Установите номер порта SSH на${gl_huang}5522${gl_bai}"
			  echo -e "5. Откройте все порты"
			  echo -e "6. включите${gl_huang}BBR${gl_bai}ускорить"
			  echo -e "7. Установите часовой пояс на${gl_huang}Шанхай${gl_bai}"
			  echo -e "8. Автоматически оптимизировать адрес DNS${gl_huang}За рубежом: 1.1.1.1 8.8.8.8.${gl_bai}"
			  echo -e "9. Установите основные инструменты${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10. Переключитесь на оптимизацию параметров ядра в системе Linux${gl_huang}Сбалансированный режим оптимизации${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "Вы уверены, что у вас будет обслуживание на один клик? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "Начальник настройки универсал"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/10. Обновить систему до последнего"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/10. Очистить системные мусорные файлы"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/10. Настройка виртуальной памяти${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/10. Установить номер порта SSH на${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 5/10. Откройте все порты"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 6/10. Открыть${gl_huang}BBR${gl_bai}ускорить"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 7/10. Установить часовой пояс на${gl_huang}Шанхай${gl_bai}"

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
				  echo -e "[${gl_lv}OK${gl_bai}] 8/10. Автоматически оптимизировать адрес DNS${gl_huang}${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 9/10. Установите основные инструменты${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10. Оптимизация параметров ядра для системы Linux"
				  echo -e "${gl_lv}Однопопная система настройки системы была завершена${gl_bai}"

				  ;;
				[Nn])
				  echo "Отменен"
				  ;;
				*)
				  echo "Неверный выбор, пожалуйста, введите Y или N."
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "Перезагрузить систему"
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

			  echo "Конфиденциальность и безопасность"
			  echo "Скрипт будет собирать данные по пользовательским функциям, оптимизировать опыт сценария и создавать больше забавных и полезных функций."
			  echo "Создаст номер версии сценария, время использования, версию системы, архитектура процессора, страна машины и название используемой функции,"
			  echo "------------------------------------------------"
			  echo -e "Текущий статус:$status_message"
			  echo "--------------------"
			  echo "1. Включите коллекцию"
			  echo "2. Закройте коллекцию"
			  echo "--------------------"
			  echo "0. Вернитесь в предыдущее меню"
			  echo "--------------------"
			  read -e -p "Пожалуйста, введите свой выбор:" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "Коллекция была включена"
					  send_stats "Конфиденциальность и сбор безопасности были включены"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "Коллекция закрыта"
					  send_stats "Конфиденциальность и безопасность были закрыты для сбора"
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
			  send_stats "Сценарий удаления технического льва"
			  echo "Сценарий удаления технического льва"
			  echo "------------------------------------------------"
			  echo "Полностью удалит сценарий Kejilion и не повлияет на ваши другие функции"
			  read -e -p "Вы обязательно продолжите? (Y/N):" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "Сценарий был удален, прощай!"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "Отменен"
				  ;;
				*)
				  echo "Неверный выбор, пожалуйста, введите Y или N."
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "Неверный ввод!"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "Файловый менеджер"
	while true; do
		clear
		echo "Файловый менеджер"
		echo "------------------------"
		echo "Текущий путь"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1. Введите каталог 2. Создайте каталог 3. Измените разрешения каталога 4. Переименовать каталог"
		echo "5. Удалить каталог 6. Вернитесь в предыдущий каталог меню"
		echo "------------------------"
		echo "11. Создайте файл 12. Изменить файл 13. Изменить разрешения на файл 14. Переименовать файл"
		echo "15. Удалить файл"
		echo "------------------------"
		echo "21. Сжатие каталога файлов 22. Справочник UNZIP файлов 23. Перемещение файлового каталога 24. Копировать файл каталог"
		echo "25. Передайте файл на другой сервер"
		echo "------------------------"
		echo "0. Вернитесь в предыдущее меню"
		echo "------------------------"
		read -e -p "Пожалуйста, введите свой выбор:" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "Пожалуйста, введите имя каталога:" dirname
				cd "$dirname" 2>/dev/null || echo "Невозможно войти в каталог"
				send_stats "Перейти к каталогу"
				;;
			2)  # 创建目录
				read -e -p "Пожалуйста, введите имя каталога, чтобы создать:" dirname
				mkdir -p "$dirname" && echo "Каталог создан" || echo "Творение не удалось"
				send_stats "Создать каталог"
				;;
			3)  # 修改目录权限
				read -e -p "Пожалуйста, введите имя каталога:" dirname
				read -e -p "Пожалуйста, введите разрешения (например, 755):" perm
				chmod "$perm" "$dirname" && echo "Разрешения были изменены" || echo "Модификация не удалась"
				send_stats "Изменить разрешения каталога"
				;;
			4)  # 重命名目录
				read -e -p "Пожалуйста, введите имя текущего каталога:" current_name
				read -e -p "Пожалуйста, введите новое имя каталога:" new_name
				mv "$current_name" "$new_name" && echo "Каталог был переименован" || echo "Переименование не удалось"
				send_stats "Переименовать каталог"
				;;
			5)  # 删除目录
				read -e -p "Пожалуйста, введите имя каталога, чтобы удалить:" dirname
				rm -rf "$dirname" && echo "Каталог был удален" || echo "Удаление не удалось"
				send_stats "Удалить каталог"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "Вернуться в предыдущий каталог меню"
				;;
			11) # 创建文件
				read -e -p "Пожалуйста, введите имя файла, чтобы создать:" filename
				touch "$filename" && echo "Файл создан" || echo "Творение не удалось"
				send_stats "Создайте файл"
				;;
			12) # 编辑文件
				read -e -p "Пожалуйста, введите имя файла, чтобы редактировать:" filename
				install nano
				nano "$filename"
				send_stats "Редактировать файлы"
				;;
			13) # 修改文件权限
				read -e -p "Пожалуйста, введите имя файла:" filename
				read -e -p "Пожалуйста, введите разрешения (например, 755):" perm
				chmod "$perm" "$filename" && echo "Разрешения были изменены" || echo "Модификация не удалась"
				send_stats "Изменить разрешения на файл"
				;;
			14) # 重命名文件
				read -e -p "Пожалуйста, введите текущее имя файла:" current_name
				read -e -p "Пожалуйста, введите новое имя файла:" new_name
				mv "$current_name" "$new_name" && echo "Файл переименован" || echo "Переименование не удалось"
				send_stats "Переименовать файл"
				;;
			15) # 删除文件
				read -e -p "Пожалуйста, введите имя файла, чтобы удалить:" filename
				rm -f "$filename" && echo "Файл удален" || echo "Удаление не удалось"
				send_stats "Удалить файлы"
				;;
			21) # 压缩文件/目录
				read -e -p "Пожалуйста, введите имя файла/каталога для сжатия:" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "Сжимается$name.tar.gz" || echo "Сжатие не удалось"
				send_stats "Сжатые файлы/каталоги"
				;;
			22) # 解压文件/目录
				read -e -p "Пожалуйста, введите имя файла (.tar.gz):" filename
				install tar
				tar -xzvf "$filename" && echo "Декомпрессированный$filename" || echo "Декомпрессия не удалась"
				send_stats "Файлы/каталоги беззазазации"
				;;

			23) # 移动文件或目录
				read -e -p "Пожалуйста, введите путь к файлу или каталогу для перемещения:" src_path
				if [ ! -e "$src_path" ]; then
					echo "Ошибка: файл или каталог не существует."
					send_stats "Не удалось переместить файл или каталог: файл или каталог не существует"
					continue
				fi

				read -e -p "Пожалуйста, введите целевой путь (включая новое имя файла или имя каталога):" dest_path
				if [ -z "$dest_path" ]; then
					echo "Ошибка: введите целевой путь."
					send_stats "Не удалось перемещение файла или каталога: путь назначения не указан"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "Файл или каталог были перемещены в$dest_path" || echo "Не удалось перемещать файлы или каталоги"
				send_stats "Перемещать файлы или каталоги"
				;;


		   24) # 复制文件目录
				read -e -p "Пожалуйста, введите путь к файлу или каталогу для копирования:" src_path
				if [ ! -e "$src_path" ]; then
					echo "Ошибка: файл или каталог не существует."
					send_stats "Не удалось скопировать файл или каталог: файл или каталог не существует"
					continue
				fi

				read -e -p "Пожалуйста, введите целевой путь (включая новое имя файла или имя каталога):" dest_path
				if [ -z "$dest_path" ]; then
					echo "Ошибка: введите целевой путь."
					send_stats "Не удалось скопировать файл или каталог: Путь назначения не указан"
					continue
				fi

				# Используйте опцию -r, чтобы скопировать каталог рекурсивно
				cp -r "$src_path" "$dest_path" && echo "Файл или каталог были скопированы в$dest_path" || echo "Не удалось скопировать файл или каталог"
				send_stats "Копировать файлы или каталоги"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "Пожалуйста, введите путь к переведению файла:" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "Ошибка: файла не существует."
					send_stats "Не удалось перенести файл: файл не существует"
					continue
				fi

				read -e -p "Пожалуйста, введите IP удаленного сервера:" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "Ошибка: введите IP удаленного сервера."
					send_stats "Неудач"
					continue
				fi

				read -e -p "Пожалуйста, введите имя пользователя удаленного сервера (root по умолчанию):" remote_user
				remote_user=${remote_user:-root}

				read -e -p "Пожалуйста, введите пароль удаленного сервера:" -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "Ошибка: введите пароль удаленного сервера."
					send_stats "Неудача переноса файла: пароль удаленного сервера не введен"
					continue
				fi

				read -e -p "Пожалуйста, введите порт входа в систему (по умолчанию 22):" remote_port
				remote_port=${remote_port:-22}

				# Чистые старые записи для известных хозяев
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# Передача файлов с помощью SCP
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "Файл был перенесен в домашний каталог удаленного сервера."
					send_stats "Передача файла успешно"
				else
					echo "Передача файла не удалась."
					send_stats "Передача файла не удалась"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "Вернитесь в предыдущее меню меню"
				break
				;;
			*)  # 处理无效输入
				echo "Неверный выбор, пожалуйста, введите"
				send_stats "Неверный выбор"
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

	# Преобразовать извлеченную информацию в массив
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# Итерация через сервер и выполнить команды
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}Подключиться к$name ($hostname)...${gl_bai}"
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
	  send_stats "Центр управления кластером"
	  echo "Управление кластером сервера"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}Управление списком серверов${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}Добавить сервер${gl_kjlan}2.  ${gl_bai}Удалить сервер${gl_kjlan}3.  ${gl_bai}Отредактируйте сервер"
	  echo -e "${gl_kjlan}4.  ${gl_bai}Резервный кластер${gl_kjlan}5.  ${gl_bai}Восстановите кластер"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}Выполнять задачи партиями${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}Установите сценарий Tech Lion${gl_kjlan}12. ${gl_bai}Обновите систему${gl_kjlan}13. ${gl_bai}Очистить систему"
	  echo -e "${gl_kjlan}14. ${gl_bai}Установите Docker${gl_kjlan}15. ${gl_bai}Установите BBR3${gl_kjlan}16. ${gl_bai}Настройка 1G виртуальная память"
	  echo -e "${gl_kjlan}17. ${gl_bai}Установите часовой пояс в Шанхай${gl_kjlan}18. ${gl_bai}Откройте все порты${gl_kjlan}51. ${gl_bai}Пользовательские команды"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}Вернуться в главное меню"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "Пожалуйста, введите свой выбор:" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "Добавить сервер кластера"
			  read -e -p "Имя сервера:" server_name
			  read -e -p "Сервер IP:" server_ip
			  read -e -p "Серверный порт (22):" server_port
			  local server_port=${server_port:-22}
			  read -e -p "Имя пользователя сервера (root):" server_username
			  local server_username=${server_username:-root}
			  read -e -p "Пароль пользователя сервера:" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "Удалить сервер кластера"
			  read -e -p "Пожалуйста, введите ключевые слова, необходимые для удаления:" rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "Отредактируйте сервер Cluster"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "Резервный кластер"
			  echo -e "Пожалуйста${gl_huang}/root/cluster/servers.py${gl_bai}Загрузите файл и заполните резервную копию!"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "Восстановите кластер"
			  echo "Пожалуйста, загрузите свой Server.py и нажмите любую клавишу, чтобы начать загрузку!"
			  echo -e "Пожалуйста, загрузите свой${gl_huang}servers.py${gl_bai}Файл в${gl_huang}/root/cluster/${gl_bai}Завершите восстановление!"
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
			  send_stats "Настроить выполнение команд"
			  read -e -p "Пожалуйста, введите команду PACTARE выполнение:" mingling
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
send_stats "Рекламная колонка"
echo "Рекламная колонка"
echo "------------------------"
echo "Он предоставит пользователям более простой и элегантный опыт продвижения и покупки!"
echo ""
echo -e "Сервер предложения"
echo "------------------------"
echo -e "${gl_lan}Leica Cloud Гонконг CN2 GIA Южная Корея Двойной провайдер США CN2 GIA Скидки${gl_bai}"
echo -e "${gl_bai}Веб -сайт: https://www.lcayun.com/aff/zexuqbim${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}Racknerd 10,99 долл. США в год United States 1 Core 1G Memory 20G жесткий диск 1T трафик в месяц${gl_bai}"
echo -e "${gl_bai}Веб -сайт: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52,7 доллара в год США 1 Core 4G Memory 50G жесткий диск 4T трафик в месяц${gl_bai}"
echo -e "${gl_bai}Веб-сайт: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=ga1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}Brickworker, 49 долларов США за квартал, США CN2GIA, Япония SoftBank, 2 ядра, 1 г памяти, 20 г жесткого диска, 1T трафик в месяц${gl_bai}"
echo -e "${gl_bai}Веб -сайт: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIMN 28 долл. США в квартал US CN2GIA 1 CORE 2G MEMOMER 20G Жесткий диск 800 г трафика в месяц${gl_bai}"
echo -e "${gl_bai}Веб -сайт: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.ps $ 6,9 в месяц Tokyo Softbank 2 Core 1G память 20 г жесткого диска 1T трафик в месяц${gl_bai}"
echo -e "${gl_bai}Веб-сайт: https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}Более популярные предложения VPS${gl_bai}"
echo -e "${gl_bai}Веб -сайт: https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "Доменное имя скидка"
echo "------------------------"
echo -e "${gl_lan}Gname 8,8 доллара первого года доменное имя COM 6.68 доллары первого года доменное имя CC${gl_bai}"
echo -e "${gl_bai}Веб -сайт: https://www.gname.com/register?tt=86836&ttcode=kejilion86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "Технологический лев окружает"
echo "------------------------"
echo -e "${gl_kjlan}B Станция:${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}Масляная труба:${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}Официальный веб -сайт:${gl_bai}https://kejilion.pro/               ${gl_kjlan}Навигация:${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}Блог:${gl_bai}https://blog.kejilion.pro/          ${gl_kjlan}Центр программного обеспечения:${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "Обновление скрипта"
cd ~
while true; do
	clear
	echo "Обновление журнала"
	echo "------------------------"
	echo "Все журналы:${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}Вы уже последняя версия!${gl_huang}v$sh_v${gl_bai}"
		send_stats "Сценарий обновлен и обновление не требуется"
	else
		echo "Откройте для себя новую версию!"
		echo -e "Текущая версия V.$sh_vПоследняя версия${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}Автоматическое обновление включено, и скрипт будет автоматически обновляться в 2 часа ночи каждый день!${gl_bai}"
	fi

	echo "------------------------"
	echo "1. Обновление сейчас 2. Включите автоматическое обновление 3. Выключите автоматическое обновление"
	echo "------------------------"
	echo "0. Вернитесь в главное меню"
	echo "------------------------"
	read -e -p "Пожалуйста, введите свой выбор:" choice
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
			echo -e "${gl_lv}Сценарий был обновлен до последней версии!${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "Сценарий обновлен$sh_v_new"
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
			echo -e "${gl_lv}Автоматическое обновление включено, и скрипт будет автоматически обновляться в 2 часа ночи каждый день!${gl_bai}"
			send_stats "Включите автоматическое обновление скрипта"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}Автоматическое обновление закрыто${gl_bai}"
			send_stats "Закрыть автоматическое обновление сценария"
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
echo -e "Technology Lion Script Toolbox V$sh_v"
echo -e "Ввод командной строки${gl_huang}k${gl_kjlan}Быстро запустить сценарии${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}Информационный запрос системы"
echo -e "${gl_kjlan}2.   ${gl_bai}Обновление системы"
echo -e "${gl_kjlan}3.   ${gl_bai}Очистка системы"
echo -e "${gl_kjlan}4.   ${gl_bai}Основные инструменты"
echo -e "${gl_kjlan}5.   ${gl_bai}Управление BBR"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker Management"
echo -e "${gl_kjlan}7.   ${gl_bai}Управление деформацией"
echo -e "${gl_kjlan}8.   ${gl_bai}Коллекция тестовых скриптов"
echo -e "${gl_kjlan}9.   ${gl_bai}Коллекция сценариев Oracle Cloud"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP Сайт Построение"
echo -e "${gl_kjlan}11.  ${gl_bai}Рынок приложений"
echo -e "${gl_kjlan}12.  ${gl_bai}Мое рабочее пространство"
echo -e "${gl_kjlan}13.  ${gl_bai}Системные инструменты"
echo -e "${gl_kjlan}14.  ${gl_bai}Управление кластером сервера"
echo -e "${gl_kjlan}15.  ${gl_bai}Рекламная колонка"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}Сценарий открытия сервера Phantom Beast Palu"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}Обновление скрипта"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}Выход сценария"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "Пожалуйста, введите свой выбор:" choice

case $choice in
  1) linux_ps ;;
  2) clear ; send_stats "Обновление системы" ; linux_update ;;
  3) clear ; send_stats "Очистка системы" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "Управление деформацией" ; install wget
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
  p) send_stats "Сценарий открытия сервера Phantom Beast Palu" ; cd ~
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "Неверный ввод!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k Справочный вариант использования команды"
echo "-------------------"
echo "Введение видео: https://www.bilibili.com/video/bv1ib421e7it?t=0.1"
echo "Ниже приведен пример использования ссылки на команду:"
echo "Начало скрипт k"
echo "Установить программный пакет k Установить Nano Wget | k Добавить нано wget | k Установить Nano Wget"
echo "Удалить пакет k Удалить Nano Wget | K Del Nano Wget | k Удалить Nano Wget | k Удалить Nano Wget"
echo "Обновление системы k Обновление | k Обновление"
echo "Чистая система мусор k чистый | k Чистый"
echo "Переустановить системную панель K DD | k Переустановка"
echo "BBR3 Панель управления K BBR3 | K BBRV3"
echo "Панель настройки ядра K NHYH | K Оптимизация ядра"
echo "Установить виртуальную память k Swap 2048"
echo "Установить виртуальный часовой пояс K Time Asia/Shanghai | k Tome Rota Asia/Shanghai"
echo "Система переработка мусорного мусора K HSZ | К утилизация корзины"
echo "Функция резервного копирования системы K резервное копирование | k bf | K резервная копия"
echo "SSH Удаленное соединение инструмент K SSH | k Удаленное соединение"
echo "rsync удаленной синхронизационной инструмент k rsync | K Удаленная синхронизация"
echo "Инструмент управления жесткими дисками k диск | k Управление жестким диском"
echo "Интранет проникновение (сторона сервера) k FRP"
echo "Интранет проникновение (клиент) K FRPC"
echo "Программное обеспечение Start K Start SSHD | k Start SSHD"
echo "Программное обеспечение Stop K Stop SSHD | k Stop SSHD"
echo "Программное обеспечение перезапустить K перезапустить SSHD | K перезапустить SSHD"
echo "Статус программного обеспечения Просмотр k Статус SSHD | k Статус SSHD"
echo "Программное обеспечение Boot K Enable Docker | K AutoStart Docke | K стартап Docker"
echo "Доменное имя сертификат приложение k ssl"
echo "Сертификат доменного имени Сертификат Запрос k SSL PS"
echo "Установка среды Docker K Docker Установка | K Docker Установка"
echo "Docker Container Management K Docker PS | K Docker Container"
echo "Docker Image Management K Docker IMG | K Docker Image"
echo "LDNMP Управление сайтами K Интернет"
echo "Очистка кэша LDNMP K веб -кэш"
echo "Установите WordPress K WP | K WordPress | K WP XXX.com"
echo "Установите обратный прокси k fd | k rp | k антигенерация | k fd xxx.com"
echo "Установите балансировку нагрузки K LoadBalance | K Балансировка нагрузки"
echo "Панель брандмауэра k fhq | k брандмауэр"
echo "Открытый порт K DKDK 8080 | K Open Port 8080"
echo "Закрыть порт K GBDK 7800 | K Close Port 7800"
echo "Выпустить ip k fxip 127.0.0.0/8 | k Выпуск IP 127.0.0.0/8"
echo "Block IP K Zzip 177.5.25.36 | K Block IP 177.5.25.36"


}



if [ "$#" -eq 0 ]; then
	# Если параметров нет, запустите интерактивную логику
	kejilion_sh
else
	# Если есть параметры, выполните соответствующую функцию
	case $1 in
		install|add|安装)
			shift
			send_stats "Установить программное обеспечение"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "Удалить программное обеспечение"
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
			send_stats "Время синхронизация RSYNC"
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
			send_stats "Быстро настроить виртуальную память"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "Быстро установить часовой пояс"
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
			send_stats "Просмотр статуса программного обеспечения"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "Запуск программного обеспечения"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "Программное обеспечение пауза"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "Перезапуск программного обеспечения"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "Программное обеспечение сапоги"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "Проверьте статус сертификата"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "Быстро подать заявку на сертификат"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "Быстро подать заявку на сертификат"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "Быстро установите Docker"
					install_docker
					;;
				ps|容器)
					send_stats "Быстрое управление контейнерами"
					docker_ps
					;;
				img|镜像)
					send_stats "Управление быстрым зеркалом"
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
