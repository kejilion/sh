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



# コマンドを実行する関数を定義します
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



# 関数の埋もポイント情報を収集し、現在のスクリプトバージョン番号、使用時間、システムバージョン、CPUアーキテクチャ、マシンの国、ユーザーが使用する関数名を記録する関数。彼らは絶対に機密情報を伴わない、安心してください！私を信じてください！
# なぜこの関数を設計する必要があるのですか？目的は、ユーザーが使用する機能をよりよく理解し、関数をさらに最適化して、ユーザーのニーズを満たすより多くの関数を起動することです。
# 全文の場合、send_stats関数の呼び出し場所、透明性、オープンソースを検索できます。懸念がある場合は、使用を拒否できます。



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

# ユーザーに条件に同意するように促します
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}Tech Lion Script Toolboxへようこそ${gl_bai}"
	echo "スクリプトを初めて使用して、ユーザーライセンス契約を読んで同意してください。"
	echo "ユーザーライセンス契約：https：//blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -r -p "上記の条件に同意しますか？ （y/n）：" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "ライセンスの同意"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "許可の拒否"
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
		echo "パッケージパラメーターは提供されていません！"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_huang}インストール$package...${gl_bai}"
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
				echo "不明なパッケージマネージャー！"
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
		echo -e "${gl_huang}ヒント：${gl_bai}ディスクスペースが不十分です！"
		echo "現在利用可能なスペース：$（（available_space_mb/1024））g"
		echo "最小需要スペース：${required_gb}G"
		echo "インストールは継続できません。ディスクスペースを掃除して、もう一度お試しください。"
		send_stats "ディスクスペースが不十分です"
		break_end
		kejilion
	fi
}


install_dependency() {
	install wget unzip tar jq grep
}

remove() {
	if [ $# -eq 0 ]; then
		echo "パッケージパラメーターは提供されていません！"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_huang}アンインストール$package...${gl_bai}"
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
			echo "不明なパッケージマネージャー！"
			return 1
		fi
	done
}


# さまざまな分布に適したUniversal SystemCTL関数
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# サービスを再起動します
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスは再開されました。"
	else
		echo "エラー：再起動$1サービスは失敗しました。"
	fi
}

# サービスを開始します
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスが開始されました。"
	else
		echo "エラー：開始$1サービスは失敗しました。"
	fi
}

# サービスを停止します
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスは停止しました。"
	else
		echo "エラー：停止します$1サービスは失敗しました。"
	fi
}

# サービスのステータスを確認します
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスステータスが表示されます。"
	else
		echo "エラー：表示できません$1サービスステータス。"
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME電源を入れるように設定します。"
}



break_end() {
	  echo -e "${gl_lv}操作が完了しました${gl_bai}"
	  echo "任意のキーを押して続行します..."
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
	echo -e "${gl_huang}Docker環境のインストール...${gl_bai}"
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
	send_stats "Dockerコンテナ管理"
	echo "Dockerコンテナリスト"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "コンテナ操作"
	echo "------------------------"
	echo "1.新しいコンテナを作成します"
	echo "------------------------"
	echo "2。指定されたコンテナを起動します。6。すべての容器を起動します"
	echo "3.指定された容器を停止します7。すべての容器を停止します"
	echo "4.指定されたコンテナ8を削除します。すべてのコンテナを削除します"
	echo "5。指定されたコンテナを再起動9。すべてのコンテナを再起動します"
	echo "------------------------"
	echo "11。指定されたコンテナを入力します12。コンテナログを表示します"
	echo "13.コンテナネットワークを表示14。コンテナ占有を表示します"
	echo "------------------------"
	echo "0。前のメニューに戻ります"
	echo "------------------------"
	read -e -p "選択を入力してください：" sub_choice
	case $sub_choice in
		1)
			send_stats "新しいコンテナを作成します"
			read -e -p "作成コマンドを入力してください：" dockername
			$dockername
			;;
		2)
			send_stats "指定された容器を起動します"
			read -e -p "コンテナ名（スペースで区切られた複数のコンテナ名）を入力してください。" dockername
			docker start $dockername
			;;
		3)
			send_stats "指定された容器を停止します"
			read -e -p "コンテナ名（スペースで区切られた複数のコンテナ名）を入力してください。" dockername
			docker stop $dockername
			;;
		4)
			send_stats "指定されたコンテナを削除します"
			read -e -p "コンテナ名（スペースで区切られた複数のコンテナ名）を入力してください。" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "指定された容器を再起動します"
			read -e -p "コンテナ名（スペースで区切られた複数のコンテナ名）を入力してください。" dockername
			docker restart $dockername
			;;
		6)
			send_stats "すべてのコンテナを起動します"
			docker start $(docker ps -a -q)
			;;
		7)
			send_stats "すべてのコンテナを停止します"
			docker stop $(docker ps -q)
			;;
		8)
			send_stats "すべてのコンテナを削除します"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "無効な選択、yまたはnを入力してください。"
				;;
			esac
			;;
		9)
			send_stats "すべてのコンテナを再起動します"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "コンテナを入力します"
			read -e -p "コンテナ名を入力してください：" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "コンテナログを表示します"
			read -e -p "コンテナ名を入力してください：" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "コンテナネットワークを表示します"
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
			send_stats "コンテナの占有を表示します"
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
	send_stats "Docker画像管理"
	echo "Docker画像リスト"
	docker image ls
	echo ""
	echo "ミラー操作"
	echo "------------------------"
	echo "1.指定された画像を取得する3。指定された画像を削除します"
	echo "2。指定された画像4を更新します。すべての画像を削除します"
	echo "------------------------"
	echo "0。前のメニューに戻ります"
	echo "------------------------"
	read -e -p "選択を入力してください：" sub_choice
	case $sub_choice in
		1)
			send_stats "鏡を引っ張ります"
			read -e -p "ミラー名を入力してください（スペースで複数のミラー名を分離してください）：" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}画像を取得する：$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "画像を更新します"
			read -e -p "ミラー名を入力してください（スペースで複数のミラー名を分離してください）：" imagenames
			for name in $imagenames; do
				echo -e "${gl_huang}更新された画像：$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "ミラーを削除します"
			read -e -p "ミラー名を入力してください（スペースで複数のミラー名を分離してください）：" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "すべての画像を削除します"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "無効な選択、yまたはnを入力してください。"
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
				echo "サポートされていない分布：$ID"
				return
				;;
		esac
	else
		echo "オペレーティングシステムを決定することはできません。"
		return
	fi

	echo -e "${gl_lv}Crontabがインストールされ、Cronサービスが実行されています。${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 構成ファイルが存在するかどうかを確認し、ファイルが存在しない場合はファイルを作成し、デフォルト設定を書き込む
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# JQを使用して、構成ファイルの更新を処理します
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 現在の構成には既にIPv6設定があるかどうかを確認してください
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 構成を更新し、IPv6を有効にします
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 元の構成と新しい構成を比較します
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}現在、IPv6アクセスが有効になっています${gl_bai}"
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

	# 構成ファイルが存在するかどうかを確認します
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}構成ファイルは存在しません${gl_bai}"
		return
	fi

	# 現在の構成をお読みください
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# JQを使用して、構成ファイルの更新を処理します
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 現在のIPv6ステータスを確認してください
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 元の構成と新しい構成を比較します
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}IPv6アクセスは現在閉じられています${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}IPv6アクセスは正常に閉じられています${gl_bai}"
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
		echo "少なくとも1つのポート番号を提供してください"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 既存のクロージングルールを削除します
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# オープンルールを追加します
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "ポートが開かれました$port"
		fi
	done

	save_iptables_rules
	send_stats "ポートが開かれました"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "少なくとも1つのポート番号を提供してください"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 既存のオープンルールを削除します
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# 緊密なルールを追加します
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "ポートは閉じた$port"
		fi
	done

	# 既存のルールを削除する（ある場合）
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 最初に新しいルールを挿入します
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "ポートは閉じた"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "少なくとも1つのIPアドレスまたはIPセグメントを提供してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 既存のブロッキングルールを削除します
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 許可ルールを追加します
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "IPをリリースしました$ip"
		fi
	done

	save_iptables_rules
	send_stats "IPをリリースしました"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "少なくとも1つのIPアドレスまたはIPセグメントを提供してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 既存の許可ルールを削除します
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# ブロッキングルールを追加します
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IPブロック$ip"
		fi
	done

	save_iptables_rules
	send_stats "IPブロック"
}







enable_ddos_defense() {
	# 防御DDOをオンにします
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "DDOS防御をオンにします"
}

# DDOS防御をオフにします
disable_ddos_defense() {
	# 防御DDOをオフにします
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "DDOS防御をオフにします"
}





# 国家IPルールを管理する機能
manage_country_rules() {
	local action="$1"
	local country_code="$2"
	local ipset_name="${country_code,,}_block"
	local download_url="http://www.ipdeny.com/ipblocks/data/countries/${country_code,,}.zone"

	install ipset

	case "$action" in
		block)
			# IPSETが存在しない場合は作成します
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# IPエリアファイルをダウンロードします
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "エラー：ダウンロード$country_codeIPゾーンファイルが失敗しました"
				exit 1
			fi

			# IPSETにIPを追加します
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# iptablesでIPをブロックします
			iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP
			iptables -I OUTPUT -m set --match-set "$ipset_name" dst -j DROP

			echo "正常にブロックされました$country_codeIPアドレス"
			rm "${country_code,,}.zone"
			;;

		allow)
			# 許可された国のIPSETを作成する（存在しない場合）
			if ! ipset list "$ipset_name" &> /dev/null; then
				ipset create "$ipset_name" hash:net
			fi

			# IPエリアファイルをダウンロードします
			if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
				echo "エラー：ダウンロード$country_codeIPゾーンファイルが失敗しました"
				exit 1
			fi

			# 既存の国家ルールを削除します
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null
			ipset flush "$ipset_name"

			# IPSETにIPを追加します
			while IFS= read -r ip; do
				ipset add "$ipset_name" "$ip"
			done < "${country_code,,}.zone"

			# 指定された国のIPのみが許可されています
			iptables -P INPUT DROP
			iptables -P OUTPUT DROP
			iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT
			iptables -A OUTPUT -m set --match-set "$ipset_name" dst -j ACCEPT

			echo "正常に許可されています$country_codeIPアドレス"
			rm "${country_code,,}.zone"
			;;

		unblock)
			# 国のiptablesルールを削除します
			iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null
			iptables -D OUTPUT -m set --match-set "$ipset_name" dst -j DROP 2>/dev/null

			# Ipsetを破壊します
			if ipset list "$ipset_name" &> /dev/null; then
				ipset destroy "$ipset_name"
			fi

			echo "正常に持ち上げられました$country_codeIPアドレスの制限"
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
		  echo "高度なファイアウォール管理"
		  send_stats "高度なファイアウォール管理"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "ファイアウォール管理"
		  echo "------------------------"
		  echo "1.指定されたポート2を開きます。指定されたポートを閉じます"
		  echo "3.すべてのポートを開きます。4。すべてのポートを閉じます"
		  echo "------------------------"
		  echo "5。IPホワイトリスト6。IPブラックリスト"
		  echo "7.指定されたIPをクリアします"
		  echo "------------------------"
		  echo "11. ping 12を許可します。Pingを無効にします"
		  echo "------------------------"
		  echo "13。DDOS防衛を開始14。DDOS防衛をオフにします"
		  echo "------------------------"
		  echo "15.ブロック指定された国IP16。指定された国のIPのみが許可されます"
		  echo "17.指定国でのIP制限をリリースします"
		  echo "------------------------"
		  echo "0。前のメニューに戻ります"
		  echo "------------------------"
		  read -e -p "選択を入力してください：" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "オープンポート番号を入力してください：" o_port
				  open_port $o_port
				  send_stats "指定されたポートを開きます"
				  ;;
			  2)
				  read -e -p "閉じたポート番号を入力してください：" c_port
				  close_port $c_port
				  send_stats "指定されたポートを閉じます"
				  ;;
			  3)
				  # すべてのポートを開きます
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
				  send_stats "すべてのポートを開きます"
				  ;;
			  4)
				  # すべてのポートを閉じます
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
				  send_stats "すべてのポートを閉じます"
				  ;;

			  5)
				  # IPホワイトリスト
				  read -e -p "リリースするには、IPまたはIPセグメントを入力してください。" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IPブラックリスト
				  read -e -p "ブロックされたIPまたはIPセグメントを入力してください：" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 指定されたIPをクリアします
				  read -e -p "クリアされたIPを入力してください：" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "指定されたIPをクリアします"
				  ;;
			  11)
				  # pingを許可します
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "pingを許可します"
				  ;;
			  12)
				  # pingを無効にします
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "pingを無効にします"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "ブロックされた国コード（CN、米国、JPなど）を入力してください。" country_code
				  manage_country_rules block $country_code
				  send_stats "許可された国$country_codeIP"
				  ;;
			  16)
				  read -e -p "許可された国コード（CN、米国、JPなど）を入力してください。" country_code
				  manage_country_rules allow $country_code
				  send_stats "国をブロックします$country_codeIP"
				  ;;

			  17)
				  read -e -p "クリアされた国コード（CN、米国、JPなど）を入力してください。" country_code
				  manage_country_rules unblock $country_code
				  send_stats "国をきれいにします$country_codeIP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}








add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 現在のシステムですべてのスワップパーティションを取得します
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# 反復して、すべてのスワップパーティションを削除します
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# /swapfileが使用されなくなったことを確認してください
	swapoff /swapfile

	# 古い /swapfileを削除します
	rm -f /swapfile

	# 新しいスワップパーティションを作成します
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

	echo -e "仮想メモリサイズは変更されています${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 仮想メモリを作成する必要があるかどうかを判断します
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # nginxバージョンを取得します
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # MySQLバージョンを取得します
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # PHPバージョンを取得します
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # Redisバージョンを取得します
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 必要なディレクトリとファイルを作成します
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/redis web/log/nginx && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf
  wget -O /home/web/redis/valkey.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/valkey.conf


  default_server_ssl

  # docker-compose.ymlファイルをダウンロードして置き換えます
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # docker-compose.ymlファイルに置き換えます
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
	  echo "LDNMP環境がインストールされています"
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
	echo "更新タスクが更新されました"
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
	echo -e "${gl_huang}$yuming公開鍵情報${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/fullchain.pem
	echo ""
	echo -e "${gl_huang}$yuming秘密のキー情報${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}証明書ストレージパス${gl_bai}"
	echo "公開鍵：/etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "秘密鍵：/etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}SSL証明書をすばやく申請し、有効期限が切れる前に署名を自動的に更新します${gl_bai}"
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
	echo -e "${gl_huang}適用された証明書の有効期限${gl_bai}"
	echo "サイト情報証明書の有効期限"
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
		send_stats "ドメイン名証明書の成功したアプリケーション"
	else
		send_stats "ドメイン名証明書のアプリケーションは失敗しました"
		echo -e "${gl_hong}知らせ：${gl_bai}証明書申請が失敗しました。次の考えられる理由を確認して、もう一度やり直してください。"
		echo -e "1。ドメイン名スペリングエラーdomainドメイン名が正しく入力されているかどうかを確認してください"
		echo -e "2。DNS解像度の問題domainドメイン名がこのサーバーIPに対して正しく解決されたことを確認します"
		echo -e "3.ネットワーク構成の問題cloudflareワープやその他の仮想ネットワークを使用する場合は、一時的にシャットダウンしてください"
		echo -e "4。ファイアウォールの制限orポート80/443が開かれているかどうかを確認して、検証がアクセス可能であることを確認してください"
		echo -e "5.アプリケーションの数が制限を超えています➠暗号化を毎週制限（5回/ドメイン名/週）があります"
		echo -e "6.国内登録制限domainドメイン名が中国本土で登録されているかどうかを確認してください"
		break_end
		clear
		echo "もう一度展開してみてください$webname"
		add_yuming
		install_ssltls
		certs_status
	fi

}


repeat_add_yuming() {
if [ -e /home/web/conf.d/$yuming.conf ]; then
  send_stats "ドメイン名の再利用"
  web_del "${yuming}" > /dev/null 2>&1
fi

}


add_yuming() {
	  ip_address
	  echo -e "最初にドメイン名をローカルIPに解決します。${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "IPまたは解決されたドメイン名を入力してください：" yuming
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

  send_stats "更新します$ldnmp_pods"
  echo "更新します${ldnmp_pods}仕上げる"

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
  echo "ログイン情報："
  echo "ユーザー名：$dbuse"
  echo "パスワード：$dbusepasswd"
  echo
  send_stats "起動する$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 構成ファイルが存在するかどうかを確認します
  if [ -f "$CONFIG_FILE" ]; then
	# 構成ファイルからAPI_TOKENとZONE_IDを読み取ります
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# ゾーン_idsを配列に変換します
	ZONE_IDS=($ZONE_IDS)
  else
	# キャッシュをクリーニングするかどうかをユーザーに促します
	read -e -p "CloudFlareのキャッシュをきれいにする必要がありますか？ （y/n）：" answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF情報が保存されます$CONFIG_FILE、後でCF情報を変更できます"
	  read -e -p "API_TOKENを入力してください：" API_TOKEN
	  read -e -p "CFユーザー名を入力してください：" EMAIL
	  read -e -p "ゾーン_id（スペースで区切られた複数）を入力してください。" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 各ZONE_IDをループして、Clear Cacheコマンドを実行します
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "ゾーン_idのキャッシュのクリア：$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "キャッシュクリアリクエストが送信されました。"
}



web_cache() {
  send_stats "サイトキャッシュをクリーンアップします"
  cf_purge_cache
  cd /home/web && docker compose restart
  restart_redis
}



web_del() {

	send_stats "サイトデータを削除します"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "サイトデータを削除するには、ドメイン名を入力してください（複数のドメイン名がスペースで区切られています）：" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "ドメイン名の削除：$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# ドメイン名をデータベース名に変換します
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# エラーを避けるために、データベースを削除する前にデータベースが存在するかどうかを確認します
		echo "データベースの削除：$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# モードパラメーターに従ってWAFをオンまたはオフにすることを決定します
	if [ "$mode" == "on" ]; then
		# WAFをオンにしてください：コメントを削除します
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# WAFを閉じる：コメントを追加します
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "無効なパラメーター：「オン」または「オフ」を使用します"
		return 1
	fi

	# nginx画像を確認し、状況に応じてそれらを処理します
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
	# 古い定義を削除します
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# 「Happy Publishing」で行の前に新しい定義を挿入する
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
	# 古い定義を削除します
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# 「Happy Publishing」で行の前に新しい定義を挿入する
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
		# Brotliをオンにする：コメントを削除します
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
		# Brotliを閉じる：コメントを追加します
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
		echo "無効なパラメーター：「オン」または「オフ」を使用します"
		return 1
	fi

	# nginx画像を確認し、状況に応じてそれらを処理します
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
		# ZSTDをオンにしてください：コメントを削除します
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
		# ZSTDを閉じる：コメントを追加します
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
		echo "無効なパラメーター：「オン」または「オフ」を使用します"
		return 1
	fi

	# nginx画像を確認し、状況に応じてそれらを処理します
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
		echo "無効なパラメーター：「オン」または「オフ」を使用します"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP環境防御"
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
			  echo -e "サーバーWebサイト防衛プログラム${check_docker}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1.防衛プログラムをインストールします"
			  echo "------------------------"
			  echo "5。SSHインターセプトレコードを表示6。ウェブサイト傍受記録を見る"
			  echo "7。防衛ルールのリストを表示8。ログのリアルタイム監視を表示"
			  echo "------------------------"
			  echo "11.インターセプトパラメーターを構成12。すべてのブロックされたipsをクリアします"
			  echo "------------------------"
			  echo "21。CloudFlareモード22。5秒シールドの高負荷"
			  echo "------------------------"
			  echo "31。WAF32をオンにしてください。WAFをオフにします"
			  echo "33。DDOS防衛をオンにする34。DDOS防衛をオフにする"
			  echo "------------------------"
			  echo "9.防衛プログラムをアンインストールします"
			  echo "------------------------"
			  echo "0。前のメニューに戻ります"
			  echo "------------------------"
			  read -e -p "選択を入力してください：" sub_choice
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
					  echo "Fail2Ban防衛プログラムがアンインストールされています"
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
					  send_stats "CloudFlareモード"
					  echo "CF背景の右上隅に移動し、左側のAPIトークンを選択し、グローバルAPIキーを取得します"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "CFアカウント番号を入力します：" cfuser
					  read -e -p "CFのグローバルAPIキーを入力してください：" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /path/to/fail2ban/config/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /path/to/fail2ban/config/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /path/to/fail2ban/config/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "CloudFlareモードは、CFバックグラウンド、サイトセキュリティイベントでインターセプトレコードを表示するように構成されています"
					  ;;

				  22)
					  send_stats "5秒シールドでの高負荷"
					  echo -e "${gl_huang}ウェブサイトは5分ごとに自動的に検出されます。高負荷の検出に達すると、シールドが自動的にオンになり、低負荷が5秒間自動的にオフになります。${gl_bai}"
					  echo "--------------"
					  echo "CFパラメーターを取得します："
					  echo -e "CFバックグラウンドの右上隅に移動し、左側のAPIトークンを選択して、取得します${gl_huang}Global API Key${gl_bai}"
					  echo -e "CFバックグラウンドドメイン名の概要ページの右下に移動して${gl_huang}リージョンID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "CFアカウント番号を入力します：" cfuser
					  read -e -p "CFのグローバルAPIキーを入力してください：" cftoken
					  read -e -p "CFにドメイン名の領域IDを入力します。" cfzonID

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
						  echo "高負荷自動シールドオープニングスクリプトが追加されました"
					  else
						  echo "自動シールドスクリプトはすでに存在しています、それを追加する必要はありません"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "サイトWAFが有効になっています"
					  send_stats "サイトWAFが有効になっています"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "サイトWAFは閉鎖されています"
					  send_stats "サイトWAFは閉鎖されています"
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

# 現在のworker_processesの設定値を取得します
current_value=$(grep -E '^\s*worker_processes\s+[0-9]+;' "$CONFIG_FILE" | awk '{print $2}' | tr -d ';')

# 値に応じてモード情報を設定します
if [ "$current_value" = "8" ]; then
	mode_info=" 高性能模式"
else
	mode_info=" 标准模式"
fi



}


check_nginx_compression() {

	CONFIG_FILE="/home/web/nginx.conf"

	# ZSTDが有効になっていてコメントされていないかどうかを確認します（ZSTDで行全体が開始されます;）
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status=" zstd压缩已开启"
	else
		zstd_status=""
	fi

	# Brotliが有効であり、コメントされていないかどうかを確認してください
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status=" br压缩已开启"
	else
		br_status=""
	fi

	# GZIPが有効になっており、コメントされていないかどうかを確認してください
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
			  send_stats "LDNMP環境を最適化します"
			  echo -e "LDNMP環境を最適化します${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1。標準モード2。高性能モード（推奨2H4g以上）"
			  echo "------------------------"
			  echo "3。GZIP圧縮をオンにします4。GZIP圧縮をオフにします"
			  echo "5。BR圧縮をオンにします6。BR圧縮をオフにします"
			  echo "7。ZSTD圧縮をオンにします8。ZSTD圧縮をオフにします"
			  echo "------------------------"
			  echo "0。前のメニューに戻ります"
			  echo "------------------------"
			  read -e -p "選択を入力してください：" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "サイト標準モード"

				  # nginxチューニング
				  sed -i 's/worker_connections.*/worker_connections 10240;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 4;/' /home/web/nginx.conf

				  # PHPチューニング
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHPチューニング
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysqlチューニング
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_balanced


				  echo "LDNMP環境は標準モードに設定されています"

					  ;;
				  2)
				  send_stats "サイトの高性能モード"

				  # nginxチューニング
				  sed -i 's/worker_connections.*/worker_connections 20480;/' /home/web/nginx.conf
				  sed -i 's/worker_processes.*/worker_processes 8;/' /home/web/nginx.conf

				  # PHPチューニング
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHPチューニング
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit 512M 512M
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysqlチューニング
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  restart_redis
				  optimize_web_server

				  echo "LDNMP環境は、高性能モードに設定されています"

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
echo "アクセスアドレス："
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

	# コンテナの作成時間と画像名を取得します
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local image_name=$(echo "$container_info" | cut -d',' -f2)

	# ミラーウェアハウスとタグを抽出します
	local image_repo=${image_name%%:*}
	local image_tag=${image_name##*:}

	# デフォルトのラベルは最新です
	[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"

	# 公式画像のサポートを追加します
	[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

	# Docker Hub APIから画像公開時間を取得します
	local hub_info=$(curl -s "https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag")
	local last_updated=$(echo "$hub_info" | jq -r '.last_updated' 2>/dev/null)

	# 買収の時間を確認します
	if [[ -n "$last_updated" && "$last_updated" != "null" ]]; then
		local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)
		local last_updated_ts=$(date -d "$last_updated" +%s 2>/dev/null)

		# タイムスタンプを比較します
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

	# コンテナのIPアドレスを取得します
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "エラー：コンテナを取得できません$container_name_or_idIPアドレス。コンテナ名またはIDが正しいかどうかを確認してください。"
		return 1
	fi

	install iptables


	# 他のすべてのIPSを確認してブロックします
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 指定されたIPを確認してリリースします
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワークを確認してリリースします127.0.0.0/8
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# 他のすべてのIPSを確認してブロックします
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 指定されたIPを確認してリリースします
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワークを確認してリリースします127.0.0.0/8
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ポートは、サービスへのアクセスをブロックされています"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# コンテナのIPアドレスを取得します
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		echo "エラー：コンテナを取得できません$container_name_or_idIPアドレス。コンテナ名またはIDが正しいかどうかを確認してください。"
		return 1
	fi

	install iptables


	# 他のすべてのIPをブロックするルールを明確にします
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 指定されたIPをリリースするためのルールをクリアします
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワークをリリースするためのルールをクリア127.0.0.0/8
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# 他のすべてのIPをブロックするルールを明確にします
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 指定されたIPをリリースするためのルールをクリアします
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワークをリリースするためのルールをクリア127.0.0.0/8
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ポートはサービスにアクセスすることが許可されています"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "エラー：アクセスを許可されているポート番号とIPを提供してください。"
		echo "使用法：block_host_port <ポート番号> <承認IP>"
		return 1
	fi

	install iptables


	# 他のすべてのIPアクセスを拒否しました
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 指定されたIPアクセスを許可します
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# ローカルアクセスを許可します
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 他のすべてのIPアクセスを拒否しました
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 指定されたIPアクセスを許可します
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# ローカルアクセスを許可します
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 確立された関連接続および関連する接続のトラフィックを許可します
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "IP+ポートは、サービスへのアクセスをブロックされています"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "エラー：アクセスを許可されているポート番号とIPを提供してください。"
		echo "使用法：CLEAR_HOST_PORT_RULES <ポート番号> <認定IP>"
		return 1
	fi

	install iptables


	# 他のすべてのIPアクセスをブロックするルールをクリアします
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# ネイティブアクセスを可能にするルールを明確にします
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 指定されたIPアクセスを許可するルールを明確にします
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 他のすべてのIPアクセスをブロックするルールをクリアします
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# ネイティブアクセスを可能にするルールを明確にします
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 指定されたIPアクセスを許可するルールを明確にします
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "IP+ポートはサービスにアクセスすることが許可されています"
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
send_stats "${docker_name}管理"

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
	echo "1。インストール2。更新3。アンインストール"
	echo "------------------------"
	echo "5.ドメイン名アクセスを追加6。ドメイン名アクセスを削除する"
	echo "7. IP+ポートアクセスを許可8。BlockIP+ポートアクセス"
	echo "------------------------"
	echo "0。前のメニューに戻ります"
	echo "------------------------"
	read -e -p "選択を入力してください：" choice
	 case $choice in
		1)
			check_disk_space $app_size
			read -e -p "アプリケーション外部サービスポートを入力し、デフォルトを入力します${docker_port}ポート：" app_port
			local app_port=${app_port:-${docker_port}}
			local docker_port=$app_port

			install jq
			install_docker
			docker_rum
			setup_docker_dir
			echo "$docker_port" > "/home/docker/${docker_name}_port.conf"

			clear
			echo "$docker_nameインストール"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "インストール$docker_name"
			;;
		2)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			docker_rum
			clear
			echo "$docker_nameインストール"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "更新します$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			rm -f /home/docker/${docker_name}_port.conf
			echo "アプリはアンインストールされています"
			send_stats "アンインストール$docker_name"
			;;

		5)
			echo "${docker_name}ドメインアクセス設定"
			send_stats "${docker_name}ドメインアクセス設定"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "ドメイン名フォーマットexample.comにはhttps：//が付属していません"
			web_del
			;;

		7)
			send_stats "IPアクセスを許可します${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "IPアクセスをブロックします${docker_name}"
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
		echo "1。インストール2。更新3。アンインストール"
		echo "------------------------"
		echo "5.ドメイン名アクセスを追加6。ドメイン名アクセスを削除する"
		echo "7. IP+ポートアクセスを許可8。BlockIP+ポートアクセス"
		echo "------------------------"
		echo "0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "あなたの選択を入力してください：" choice
		case $choice in
			1)
				check_disk_space $app_size
				read -e -p "アプリケーション外部サービスポートを入力し、デフォルトを入力します${docker_port}ポート：" app_port
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
				echo "${docker_name}ドメインアクセス設定"
				send_stats "${docker_name}ドメインアクセス設定"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"
				;;
			6)
				echo "ドメイン名フォーマットexample.comにはhttps：//が付属していません"
				web_del
				;;
			7)
				send_stats "IPアクセスを許可します${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "IPアクセスをブロックします${docker_name}"
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

# セッションが存在するかどうかを確認する関数
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 存在しないセッション名が見つかるまでループします
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 新しいTMUXセッションを作成します
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
		echo "再起動"
		reboot
		;;
	  *)
		echo "キャンセル"
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
	send_stats "LDNMP環境を再度インストールできません"
	echo -e "${gl_huang}ヒント：${gl_bai}ウェブサイトの建設環境がインストールされています。再度インストールする必要はありません！"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "LDNMP環境をインストールします"
root_use
clear
echo -e "${gl_huang}LDNMP環境はインストールされていません。LDNMP環境のインストールを開始します...${gl_bai}"
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
send_stats "Nginx環境をインストールします"
root_use
clear
echo -e "${gl_huang}nginxはインストールされていません、nginx環境のインストールを開始します...${gl_bai}"
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
echo "Nginxがインストールされています"
echo -e "現在のバージョン：${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "LDNMP環境を最初にインストールしてください"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "最初にNGINX環境をインストールしてください"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "あなたの$webname建てられた！"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webnameインストール情報は次のとおりです。"

}

nginx_web_on() {
	  clear
	  echo "あなたの$webname建てられた！"
	  echo "https://$yuming"

}



ldnmp_wp() {
  clear
  # wordpress
  webname="WordPress"
  yuming="${1:-}"
  send_stats "インストール$webname"
  echo "展開を開始します$webname"
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
# エコー「データベース名：$ dbname」
# エコー「ユーザー名：$ dbuse」
# エコー「パスワード：$ dbusepasswd」
# エコー「データベースアドレス：mysql」
# エコー「テーブルプレフィックス：WP_」

}


ldnmp_Proxy() {
	clear
	webname="反向代理-IP+端口"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "インストール$webname"
	echo "展開を開始します$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi
	if [ -z "$reverseproxy" ]; then
		read -e -p "抗ジェネレーションIPを入力してください：" reverseproxy
	fi

	if [ -z "$port" ]; then
		read -e -p "発生防止ポートを入力してください。" port
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

	send_stats "インストール$webname"
	echo "展開を開始します$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	# ユーザーが入力した複数のIPを取得：ポート（スペースで区切られています）
	if [ -z "$reverseproxy_port" ]; then
		read -e -p "スペースで区切られた複数の生成防止IP+ポートを入力してください（たとえば、127.0.0.1：3000 127.0.1:3002）：" reverseproxy_port
	fi

	nginx_install_status
	install_ssltls
	certs_status
	wget -O /home/web/conf.d/map.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/map.conf
	wget -O /home/web/conf.d/$yuming.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/reverse-proxy-backend.conf

	backend=$(tr -dc 'A-Za-z' < /dev/urandom | head -c 8)
	sed -i "s/backend_yuming_com/backend_$backend/g" /home/web/conf.d/"$yuming".conf


	sed -i "s/yuming.com/$yuming/g" /home/web/conf.d/$yuming.conf

	# 上流の構成を動的に生成します
	upstream_servers=""
	for server in $reverseproxy_port; do
		upstream_servers="$upstream_servers    server $server;\n"
	done

	# テンプレートのプレースホルダーを交換します
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
		send_stats "LDNMPサイト管理"
		echo "LDNMP環境"
		echo "------------------------"
		ldnmp_v

		# ls -t /home/web/conf.d | sed 's/\.[^.]*$//'
		echo -e "${output}証明書の有効期限"
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
		echo "サイトディレクトリ"
		echo "------------------------"
		echo -e "データ${gl_hui}/home/web/html${gl_bai}証明書${gl_hui}/home/web/certs${gl_bai}構成${gl_hui}/home/web/conf.d${gl_bai}"
		echo "------------------------"
		echo ""
		echo "動作します"
		echo "------------------------"
		echo "1.ドメイン名証明書を適用/更新する2。サイトドメイン名を変更します"
		echo "3.サイトキャッシュをクリーンアップ4。関連するサイトを作成する"
		echo "5.アクセスログを表示6。エラーログを表示します"
		echo "7.グローバル構成の編集8。サイト構成の編集"
		echo "9.サイトデータベースの管理10。サイト分析レポートを表示します"
		echo "------------------------"
		echo "20.指定されたサイトデータを削除します"
		echo "------------------------"
		echo "0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "選択を入力してください：" sub_choice
		case $sub_choice in
			1)
				send_stats "ドメイン名証明書を申請します"
				read -e -p "ドメイン名を入力してください：" yuming
				install_certbot
				docker run -it --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "サイトドメイン名を変更します"
				echo -e "${gl_hong}強くお勧めします：${gl_bai}最初にサイトデータ全体をバックアップしてから、サイトドメイン名を変更します！"
				read -e -p "古いドメイン名を入力してください：" oddyuming
				read -e -p "新しいドメイン名を入力してください：" yuming
				install_certbot
				install_ssltls
				certs_status

				# MySQLの交換
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

				# ウェブサイトディレクトリの交換
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
				send_stats "関連するサイトを作成します"
				echo -e "アクセスのための既存のサイトの新しいドメイン名を関連付ける"
				read -e -p "既存のドメイン名を入力してください：" oddyuming
				read -e -p "新しいドメイン名を入力してください：" yuming
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
				send_stats "アクセスログを表示します"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "エラーログを表示します"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "グローバル構成を編集します"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "サイト構成を編集します"
				read -e -p "サイト構成を編集するには、編集するドメイン名を入力してください。" yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "サイトデータを表示します"
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
send_stats "${panelname}管理"
while true; do
	clear
	check_panel_app
	echo -e "$panelname $check_panel"
	echo "${panelname}最近では人気のある強力な運用および保守管理パネルです。"
	echo "公式ウェブサイトの紹介：$panelurl "

	echo ""
	echo "------------------------"
	echo "1。インストール2。管理3。アンインストール"
	echo "------------------------"
	echo "0。前のメニューに戻ります"
	echo "------------------------"
	read -e -p "選択を入力してください：" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install
			send_stats "${panelname}インストール"
			;;
		2)
			panel_app_manage
			send_stats "${panelname}コントロール"

			;;
		3)
			panel_app_uninstall
			send_stats "${panelname}アンインストール"
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

	send_stats "FRPサーバーをインストールします"
	# ランダムポートと資格情報を生成します
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

	# 出力生成情報
	ip_address
	echo "------------------------"
	echo "クライアントの展開に必要なパラメーター"
	echo "サービスIP：$ipv4_address"
	echo "token: $token"
	echo
	echo "FRPパネル情報"
	echo "FRPパネルアドレス：http：//$ipv4_address:$dashboard_port"
	echo "FRPパネルのユーザー名：$dashboard_user"
	echo "FRPパネルパスワード：$dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "FRPクライアントをインストールします"
	read -e -p "外部ネットワークドッキングIPを入力してください：" server_addr
	read -e -p "外部ネットワークドッキングトークンを入力してください：" token
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
	send_stats "FRPイントラネットサービスを追加します"
	# ユーザーにサービス名と転送情報を入力するように促します
	read -e -p "サービス名を入力してください：" service_name
	read -e -p "転送タイプ（TCP/UDP）を入力してください[デフォルトTCPを入力]：" service_type
	local service_type=${service_type:-tcp}
	read -e -p "イントラネットIPを入力してください[デフォルト127.0.0.1を入力]：" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "イントラネットポートを入力してください：" local_port
	read -e -p "请输入外网端口: " remote_port

	# ユーザー入力を構成ファイルに書き込みます
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 出力生成情報
	echo "仕える$service_nameFRPC.TOMLに正常に追加されました"

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "FRPイントラネットサービスを削除します"
	# ユーザーに削除する必要があるサービス名を入力するように促します
	read -e -p "削除する必要があるサービス名を入力してください：" service_name
	# SEDを使用して、サービスとその関連構成を削除します
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "仕える$service_nameFRPC.TOMLから削除されました"

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# ヘッダーを印刷します
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
		# サービス情報がある場合は、新しいサービスを処理する前に現在のサービスを印刷します
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}

		# 現在のサービス名を更新します
		if ($1 != "[common]") {
			gsub(/[\[\]]/, "", $1)
			current_service=$1
			# 前の値をクリアします
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
		# 最後のサービスの情報を印刷します
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# FRPサーバーポートを取得します
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# アクセスアドレスを生成します
generate_access_urls() {
	# 最初にすべてのポートを取得します
	get_frp_ports

	# 8055/8056以外のポートがあるかどうかを確認してください
	local has_valid_ports=false
	for port in "${ports[@]}"; do
		if [[ $port != "8055" && $port != "8056" ]]; then
			has_valid_ports=true
			break
		fi
	done

	# 有効なポートがある場合にのみタイトルとコンテンツを表示します
	if [ "$has_valid_ports" = true ]; then
		echo "FRPサービス外部アクセスアドレス："

		# IPv4アドレスを処理します
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# IPv6アドレスを処理する（存在する場合）
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# HTTPS構成の処理
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
	send_stats "FRPサーバー"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRPサーバー$check_frp $update_status"
		echo "FRPイントラネット侵入サービス環境を構築して、パブリックIPなしでインターネットにデバイスを公開する"
		echo "公式ウェブサイトの紹介：https：//github.com/fatedier/frp/"
		echo "ビデオ教育：https：//www.bilibili.com/video/bv1ymw6e2ewl?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1。インストール2。更新3。アンインストール"
		echo "------------------------"
		echo "5。イントラネットサービスのドメイン名アクセス6。ドメイン名アクセスを削除する"
		echo "------------------------"
		echo "7. IP+ポートアクセスを許可8。BlockIP+ポートアクセス"
		echo "------------------------"
		echo "00。サービスのステータスを更新します0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "あなたの選択を入力してください：" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config
				echo "FRPサーバーがインストールされています"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps
				echo "FRPサーバーが更新されました"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				echo "アプリはアンインストールされています"
				;;
			5)
				echo "ドメイン名アクセスへの逆イントラネット侵入サービス"
				send_stats "FRP外部ドメイン名へのアクセス"
				add_yuming
				read -e -p "イントラネット侵入サービスポートを入力してください：" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "ドメイン名フォーマットexample.comにはhttps：//が付属していません"
				web_del
				;;

			7)
				send_stats "IPアクセスを許可します"
				read -e -p "リリースするポートを入力してください：" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "IPアクセスをブロックします"
				echo "アンチジェネレーションドメイン名にアクセスした場合、この関数を使用して、より安全なIP+ポートアクセスをブロックできます。"
				read -e -p "请输入需要阻止的端口: " frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "FRPサービスステータスを更新します"
				echo "FRPサービスステータスは更新されました"
				;;

			*)
				break
				;;
		esac
		break_end
	done
}


frpc_panel() {
	send_stats "FRPクライアント"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRPクライアント$check_frp $update_status"
		echo "サーバーでドッキングした後、ドッキングした後、インターネットへのアクセスにイントラネット侵入サービスを作成できます"
		echo "公式ウェブサイトの紹介：https：//github.com/fatedier/frp/"
		echo "ビデオ教育：https：//www.bilibili.com/video/bv1ymw6e2ewl?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1。インストール2。更新3。アンインストール"
		echo "------------------------"
		echo "4.外部サービスの追加5.外部サービスを削除6。サービスを手動で構成する"
		echo "------------------------"
		echo "0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "あなたの選択を入力してください：" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc
				echo "FRPクライアントがインストールされています"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc
				echo "FRPクライアントが更新されました"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055
				echo "アプリはアンインストールされています"
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
		send_stats "YT-DLPダウンロードツール"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "YT-DLPは、YouTube、Bilibili、Twitterなどを含む何千ものサイトをサポートする強力なビデオダウンロードツールです。"
		echo -e "公式ウェブサイトの住所：https：//github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "ダウンロードされたビデオリスト："
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "（まだありません）"
		echo "-------------------------"
		echo "1。インストール2。更新3。アンインストール"
		echo "-------------------------"
		echo "5。シングルビデオダウンロード6。バッチビデオダウンロード7。カスタムパラメーターダウンロード"
		echo "8。mp3オーディオ9としてダウンロードします。ビデオディレクトリ10を削除します。クッキー管理（開発中）"
		echo "-------------------------"
		echo "0。前のメニューに戻ります"
		echo "-------------------------"
		read -e -p "オプション番号を入力してください：" choice

		case $choice in
			1)
				send_stats "YT-DLPのインストール..."
				echo "YT-DLPのインストール..."
				install ffmpeg
				sudo curl -L https://github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				sudo chmod a+rx /usr/local/bin/yt-dlp
				echo "インストールが完了しました。任意のキーを押して続行します..."
				read ;;
			2)
				send_stats "yt-dlpを更新..."
				echo "yt-dlpを更新..."
				sudo yt-dlp -U
				echo "更新が完了しました。任意のキーを押して続行します..."
				read ;;
			3)
				send_stats "yt-dlpのアンインストール..."
				echo "yt-dlpのアンインストール..."
				sudo rm -f /usr/local/bin/yt-dlp
				echo "アンインストールが完了しました。任意のキーを押して続行します..."
				read ;;
			5)
				send_stats "単一のビデオダウンロード"
				read -e -p "ビデオリンクを入力してください：" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "ダウンロードが完了したら、任意のキーを押して続行します..." ;;
			6)
				send_stats "バッチビデオのダウンロード"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "＃複数のビデオリンクアドレスを入力\ n＃https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.Episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "バッチダウンロードを開始します..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "批量下载完成，按任意键继续..." ;;
			7)
				send_stats "カスタムビデオのダウンロード"
				read -e -p "完全なYT-DLPパラメーター（YT-DLPを除く）を入力してください。" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "実行が完了したら、キーを押して続行します..." ;;
			8)
				send_stats "MP3ダウンロード"
				read -e -p "ビデオリンクを入力してください：" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "オーディオのダウンロードが完了しました、任意のキーを押して続行します..." ;;

			9)
				send_stats "ビデオを削除します"
				read -e -p "削除ビデオの名前を入力してください：" rmdir
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



# DPKG割り込みの問題を修正します
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_huang}システムの更新...${gl_bai}"
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
		echo "不明なパッケージマネージャー！"
		return
	fi
}



linux_clean() {
	echo -e "${gl_huang}システムのクリーンアップ...${gl_bai}"
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
		echo "パッケージマネージャーのキャッシュを掃除します..."
		apk cache clean
		echo "システムログを削除してください..."
		rm -rf /var/log/*
		echo "APKキャッシュを削除してください..."
		rm -rf /var/cache/apk/*
		echo "一時ファイルを削除します..."
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
		echo "システムログを削除してください..."
		rm -rf /var/log/*
		echo "一時ファイルを削除します..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "未使用の依存関係をクリーンアップ..."
		pkg autoremove -y
		echo "パッケージマネージャーのキャッシュを掃除します..."
		pkg clean -y
		echo "システムログを削除してください..."
		rm -rf /var/log/*
		echo "一時ファイルを削除します..."
		rm -rf /tmp/*

	else
		echo "不明なパッケージマネージャー！"
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
send_stats "DNSを最適化します"
while true; do
	clear
	echo "DNSアドレスを最適化します"
	echo "------------------------"
	echo "現在のDNSアドレス"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1。外国DNS最適化："
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2。国内のDNS最適化："
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3。DNS構成を手動で編集します"
	echo "------------------------"
	echo "0。前のメニューに戻ります"
	echo "------------------------"
	read -e -p "選択を入力してください：" Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "外国のDNS最適化"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "国内のDNS最適化"
		;;
	  3)
		install nano
		nano /etc/resolv.conf
		send_stats "DNS構成を手動で編集します"
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

	# PasswordAuthenticationが見つかった場合は、はいに設定します
	if grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

	# 発見された場合、pubkeyauthenticationはyesに設定されています
	if grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	fi

	# PasswordAuthenticationもPubKeyAuthenticationが一致しない場合は、デフォルト値を設定します
	if ! grep -Eq "^PasswordAuthentication\s+yes" "$sshd_config" && ! grep -Eq "^PubkeyAuthentication\s+yes" "$sshd_config"; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' "$sshd_config"
		sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' "$sshd_config"
	fi

}


new_ssh_port() {

  # バックアップSSH構成ファイル
  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config
  sed -i "s/Port [0-9]\+/Port $new_port/g" /etc/ssh/sshd_config

  correct_ssh_config
  rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSHポートは次のように変更されています。$new_port"

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
	echo -e "秘密のキー情報が生成されました。必ずコピーして保存してください。${gl_huang}${ipv4_address}_ssh.key${gl_bai}将来のSSHログイン用のファイル"

	echo "--------------------------------"
	cat ~/.ssh/sshkey
	echo "--------------------------------"

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ルートプライベートキーログインが有効になり、ルートパスワードログインが閉じられ、再接続が有効になります${gl_bai}"

}


import_sshkey() {

	read -e -p "SSH公開キーの内容を入力してください（通常は「SSH-RSA」または「SSH-ED25519」から始まります）：" public_key

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}エラー：公開キーのコンテンツは入力されませんでした。${gl_bai}"
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
	echo -e "${gl_lv}公開キーが正常にインポートされ、ルート秘密キーログインが有効になり、ルートパスワードログインが閉じられ、再接続が有効になります${gl_bai}"

}




add_sshpasswd() {

echo "ルートパスワードを設定します"
passwd
sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config;
sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config;
rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
restart_ssh
echo -e "${gl_lv}ルートログインがセットアップされます！${gl_bai}"

}


root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}ヒント：${gl_bai}この機能には、ルートユーザーを実行する必要があります！" && break_end && kejilion
}



dd_xitong() {
		send_stats "システムを再インストールします"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "再インストール後の初期ユーザー名：${gl_huang}root${gl_bai}最初のパスワード：${gl_huang}LeitboGi0ro${gl_bai}初期ポート：${gl_huang}22${gl_bai}"
		  echo -e "任意のキーを押して続行します..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "再インストール後の初期ユーザー名：${gl_huang}Administrator${gl_bai}最初のパスワード：${gl_huang}Teddysun.com${gl_bai}初期ポート：${gl_huang}3389${gl_bai}"
		  echo -e "任意のキーを押して続行します..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "再インストール後の初期ユーザー名：${gl_huang}root${gl_bai}最初のパスワード：${gl_huang}123@@@${gl_bai}初期ポート：${gl_huang}22${gl_bai}"
		  echo -e "任意のキーを押して続行します..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "再インストール後の初期ユーザー名：${gl_huang}Administrator${gl_bai}最初のパスワード：${gl_huang}123@@@${gl_bai}初期ポート：${gl_huang}3389${gl_bai}"
		  echo -e "任意のキーを押して続行します..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "システムを再インストールします"
			echo "--------------------------------"
			echo -e "${gl_hong}知らせ：${gl_bai}再インストールは接触を失う危険であり、心配している人はそれを注意して使用する必要があります。再インストールには15分かかると予想されます。事前にデータをバックアップしてください。"
			echo -e "${gl_hui}スクリプトサポートについては、MollylauとBin456789に感謝します！${gl_bai} "
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
			echo "35。OpenSuseTumbleWeed36。FNOSFEINIU PUBLIC BETAバージョン"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2022"
			echo "45. Windows Server 2019       46. Windows Server 2016"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0。前のメニューに戻ります"
			echo "------------------------"
			read -e -p "再インストールするシステムを選択してください：" sys_choice
			case "$sys_choice" in
			  1)
				send_stats "Debian 12を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  2)
				send_stats "Debian 11を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  3)
				send_stats "Debian 10を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  4)
				send_stats "Debian 9を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -debian 9
				reboot
				exit
				;;
			  11)
				send_stats "Ubuntu 24.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "Ubuntu 22.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "Ubuntu 20.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "Ubuntu 18.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "Rockylinux10を再インストールします"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "Rockylinux9を再インストールします"
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				send_stats "alma10を再インストールします"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "alma9を再インストールします"
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				send_stats "Oracle10を再インストールします"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "Oracle9を再インストールします"
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				send_stats "Fedora42を再インストールします"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "Fedora41を再インストールします"
				dd_xitong_3
				bash reinstall.sh fedora 41
				reboot
				exit
				;;

			  29)
				send_stats "CENTOS10を再インストールします"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "CENTOS9を再インストールします"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "アルパインを再インストールします"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "アーチを再インストールします"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "Kaliを再インストールします"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "Openeulerを再インストールします"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "OpenSuseを再インストールします"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "飛ぶ牛をリロードします"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;


			  41)
				send_stats "Windows11を再インストールします"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;
			  42)
				dd_xitong_2
				send_stats "Windows 10を再インストールします"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;
			  43)
				send_stats "Windows 7を再インストールします"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "Windows Server 22を再インストールします"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;
			  45)
				send_stats "Windows Server 19を再インストールします"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;
			  46)
				send_stats "Windows Server 16を再インストールします"
				dd_xitong_2
				bash InstallNET.sh -windows 2016 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "Windows11アームを再インストールします"
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
		  send_stats "BBRV3管理"

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
				  echo "XanmodのBBRV3カーネルをインストールしました"
				  echo "現在のカーネルバージョン：$kernel_version"

				  echo ""
				  echo "カーネル管理"
				  echo "------------------------"
				  echo "1。BBRV3カーネルを更新する2。BBRV3カーネルをアンインストールします"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# ステップ3：リポジトリを追加します
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "Xanmodカーネルが更新されました。再起動後に有効になります"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "Xanmodカーネルはアンインストールされています。再起動後に有効になります"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "BBR3加速度をセットアップします"
		  echo "ビデオの紹介：https：//www.bilibili.com/video/bv14k421x7bs?t=0.1"
		  echo "------------------------------------------------"
		  echo "Debian/Ubuntuのみをサポートします"
		  echo "请备份数据，将为你升级Linux内核开启BBR3"
		  echo "VPSには512mのメモリがあります。メモリが不十分なため、接触の欠落を防ぐために、事前に1G仮想メモリを追加してください！"
		  echo "------------------------------------------------"
		  read -e -p "必ず続行しますか？ （y/n）：" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "現在の環境はそれをサポートせず、DebianとUbuntuシステムのみをサポートしています"
					break_end
					linux_Settings
				fi
			else
				echo "オペレーティングシステムの種類を決定できません"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# ステップ3：リポジトリを追加します
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "Xanmodカーネルがインストールされ、BBR3が正常に有効になります。再起動後に有効になります"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "キャンセル"
			  ;;
			*)
			  echo "無効な選択、yまたはnを入力してください。"
			  ;;
		  esac
		fi

}


elrepo_install() {
	# Elrepo GPG公開キーをインポートします
	echo "Elrepo GPG公開キーをインポートしてください..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# システムバージョンを検出します
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# サポートされているオペレーティングシステムで実行されていることを確認してください
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "サポートされていないオペレーティングシステム：$os_name"
		break_end
		linux_Settings
	fi
	# 検出されたオペレーティングシステム情報を印刷します
	echo "検出されたオペレーティングシステム：$os_name $os_version"
	# システムバージョンに応じて、対応するElrepo Warehouse構成をインストールする
	if [[ "$os_version" == 8 ]]; then
		echo "Elrepoリポジトリ構成（バージョン8）をインストールしてください..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "Elrepoリポジトリ構成（バージョン9）をインストールしてください..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "Elrepoリポジトリ構成（バージョン10）をインストールしてください..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "サポートされていないシステムバージョン：$os_version"
		break_end
		linux_Settings
	fi
	# Elrepoカーネルリポジトリを有効にし、最新のメインラインカーネルをインストールします
	echo "Elrepoカーネルリポジトリを有効にし、最新のメインラインカーネルをインストールしてください..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "Elrepoリポジトリ構成がインストールされ、最新のメインラインカーネルに更新されます。"
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "レッドハットカーネル管理"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "Elrepo Kernelをインストールしました"
				  echo "現在のカーネルバージョン：$kernel_version"

				  echo ""
				  echo "カーネル管理"
				  echo "------------------------"
				  echo "1. Elrepo Kernel 2を更新します。ElrepoKernelをアンインストールします"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "Red Hatカーネルを更新します"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "Elrepoカーネルはアンインストールされています。再起動後に有効になります"
						send_stats "レッドハットカーネルをアンインストールします"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "データをバックアップしてください、そしてあなたのためにLinuxカーネルをアップグレードします"
		  echo "ビデオの紹介：https：//www.bilibili.com/video/bv1mh4y1w7qa?t=529.2"
		  echo "------------------------------------------------"
		  echo "レッドハットシリーズの分布のみをサポートしますCentos/Redhat/Alma/Rocky/Oracle"
		  echo "Linuxカーネルをアップグレードすると、システムのパフォーマンスとセキュリティが向上する可能性があります。条件が許可され、生産環境を慎重にアップグレードする場合は、試してみることをお勧めします！"
		  echo "------------------------------------------------"
		  read -e -p "必ず続行しますか？ （y/n）：" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "Red Hatカーネルをアップグレードします"
			  server_reboot
			  ;;
			[Nn])
			  echo "キャンセル"
			  ;;
			*)
			  echo "無効な選択、yまたはnを入力してください。"
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_huang}ウイルスデータベースを更新してください...${gl_bai}"
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		clamav/clamav-debian:latest \
		freshclam
}

clamav_scan() {
	if [ $# -eq 0 ]; then
		echo "スキャンするディレクトリを指定してください。"
		return
	fi

	echo -e "${gl_huang}スキャンディレクトリ$@...${gl_bai}"

	# マウントパラメーターを構築します
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# CLAMSCANコマンドパラメーターを作成します
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# Dockerコマンドを実行します
	docker run -it --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@スキャンが完了し、ウイルスレポートが保存されます${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}ウイルスがある場合は、お願いします${gl_huang}scan.log${gl_lv}ファイルで見つかったキーワードを検索して、ウイルスの場所を確認する${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "ウイルススキャン管理"
		  while true; do
				clear
				echo "クラマブウイルススキャンツール"
				echo "ビデオの紹介：https：//www.bilibili.com/video/bv1tqvze4eqm?t=0.1"
				echo "------------------------"
				echo "これは、主にさまざまな種類のマルウェアを検出および除去するために使用されるオープンソースのウイルス対策ソフトウェアツールです。"
				echo "ウイルス、トロイの木馬、スパイウェア、悪意のあるスクリプト、その他の有害なソフトウェアを含む。"
				echo "------------------------"
				echo -e "${gl_lv}1。フルディスクスキャン${gl_bai}             ${gl_huang}2.重要なディレクトリをスキャンします${gl_bai}            ${gl_kjlan}3。カスタムディレクトリスキャン${gl_bai}"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "選択を入力してください：" sub_choice
				case $sub_choice in
					1)
					  send_stats "フルディスクスキャン"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "重要なディレクトリスキャン"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "カスタムディレクトリスキャン"
					  read -e -p "スペースで区切られたスキャンにディレクトリを入力してください（例： /etc /var /usr /home /root）：" directories
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




# 高性能モード最適化関数
optimize_high_performance() {
	echo -e "${gl_lv}に切り替えます${tiaoyou_moshi}...${gl_bai}"

	echo -e "${gl_lv}ファイル記述子を最適化します...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}仮想メモリを最適化します...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=15 2>/dev/null
	sysctl -w vm.dirty_background_ratio=5 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化します...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を最適化します...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化します...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}その他の最適化...${gl_bai}"
	# レイテンシを減らすために、大きな透明なページを無効にします
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# numaバランスを無効にします
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}

# イコライゼーションモード最適化関数
optimize_balanced() {
	echo -e "${gl_lv}イコライゼーションモードに切り替えます...${gl_bai}"

	echo -e "${gl_lv}ファイル記述子を最適化します...${gl_bai}"
	ulimit -n 32768

	echo -e "${gl_lv}仮想メモリを最適化します...${gl_bai}"
	sysctl -w vm.swappiness=30 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=32768 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化します...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を最適化します...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=75 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化します...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}その他の最適化...${gl_bai}"
	# 透明なページを復元します
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# numaバランスを復元します
	sysctl -w kernel.numa_balancing=1 2>/dev/null


}

# デフォルト設定関数を復元します
restore_defaults() {
	echo -e "${gl_lv}デフォルト設定に復元します...${gl_bai}"

	echo -e "${gl_lv}ファイル記述子を復元します...${gl_bai}"
	ulimit -n 1024

	echo -e "${gl_lv}仮想メモリを復元します...${gl_bai}"
	sysctl -w vm.swappiness=60 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=0 2>/dev/null
	sysctl -w vm.min_free_kbytes=16384 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を復元します...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を復元します...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=100 2>/dev/null

	echo -e "${gl_lv}CPU設定を復元します...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=1 2>/dev/null

	echo -e "${gl_lv}他の最適化を復元します...${gl_bai}"
	# 透明なページを復元します
	echo always > /sys/kernel/mm/transparent_hugepage/enabled
	# numaバランスを復元します
	sysctl -w kernel.numa_balancing=1 2>/dev/null

}



# ウェブサイトの構築最適化機能
optimize_web_server() {
	echo -e "${gl_lv}ウェブサイトの構築最適化モードに切り替えます...${gl_bai}"

	echo -e "${gl_lv}ファイル記述子を最適化します...${gl_bai}"
	ulimit -n 65535

	echo -e "${gl_lv}仮想メモリを最適化します...${gl_bai}"
	sysctl -w vm.swappiness=10 2>/dev/null
	sysctl -w vm.dirty_ratio=20 2>/dev/null
	sysctl -w vm.dirty_background_ratio=10 2>/dev/null
	sysctl -w vm.overcommit_memory=1 2>/dev/null
	sysctl -w vm.min_free_kbytes=65536 2>/dev/null

	echo -e "${gl_lv}ネットワーク設定を最適化します...${gl_bai}"
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

	echo -e "${gl_lv}キャッシュ管理を最適化します...${gl_bai}"
	sysctl -w vm.vfs_cache_pressure=50 2>/dev/null

	echo -e "${gl_lv}CPU設定を最適化します...${gl_bai}"
	sysctl -w kernel.sched_autogroup_enabled=0 2>/dev/null

	echo -e "${gl_lv}その他の最適化...${gl_bai}"
	# レイテンシを減らすために、大きな透明なページを無効にします
	echo never > /sys/kernel/mm/transparent_hugepage/enabled
	# numaバランスを無効にします
	sysctl -w kernel.numa_balancing=0 2>/dev/null


}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linuxカーネルチューニング管理"
	  echo "Linuxシステムにおけるカーネルパラメーターの最適化"
	  echo "ビデオの紹介：https：//www.bilibili.com/video/bv1kb421j7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "さまざまなシステムパラメーターチューニングモードが提供され、ユーザーは独自の使用シナリオに従って選択および切り替えることができます。"
	  echo -e "${gl_huang}ヒント：${gl_bai}生産環境では注意して使用してください！"
	  echo "--------------------"
	  echo "1.高性能最適化モード：システムパフォーマンスを最大化し、ファイル記述子、仮想メモリ、ネットワーク設定、キャッシュ管理、CPU設定を最適化します。"
	  echo "2。バランスの取れた最適化モード：毎日の使用に適したパフォーマンスとリソース消費のバランス。"
	  echo "3.ウェブサイトの最適化モード：Webサイトサーバーを最適化して、接続処理機能、応答速度、全体的なパフォーマンスを並行します。"
	  echo "4。ライブブロードキャスト最適化モード：ライブブロードキャストストリーミングの特別なニーズを最適化して、遅延を減らし、伝送パフォーマンスを向上させます。"
	  echo "5。ゲームサーバーの最適化モード：ゲームサーバーを最適化して、同時処理機能と応答速度を改善します。"
	  echo "6.デフォルト設定を復元します：システム設定をデフォルトの構成に復元します。"
	  echo "--------------------"
	  echo "0。前のメニューに戻ります"
	  echo "--------------------"
	  read -e -p "選択を入力してください：" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能优化模式"
			  optimize_high_performance
			  send_stats "高性能モードの最適化"
			  ;;
		  2)
			  cd ~
			  clear
			  optimize_balanced
			  send_stats "バランスモードの最適化"
			  ;;
		  3)
			  cd ~
			  clear
			  optimize_web_server
			  send_stats "ウェブサイトの最適化モデル"
			  ;;
		  4)
			  cd ~
			  clear
			  local tiaoyou_moshi="直播优化模式"
			  optimize_high_performance
			  send_stats "ライブストリーミング最適化"
			  ;;
		  5)
			  cd ~
			  clear
			  local tiaoyou_moshi="游戏服优化模式"
			  optimize_high_performance
			  send_stats "ゲームサーバーの最適化"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  send_stats "デフォルト設定を復元します"
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
				echo -e "${gl_lv}システム言語は次のように変更されています。$langSSHの再接続が有効になります。${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}システム言語は次のように変更されています。$langSSHの再接続が有効になります。${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "サポートされていないシステム：$ID"
				break_end
				;;
		esac
	else
		echo "サポートされていないシステム、システムタイプは認識できません。"
		break_end
	fi
}




linux_language() {
root_use
send_stats "システム言語を切り替えます"
while true; do
  clear
  echo "現在のシステム言語：$LANG"
  echo "------------------------"
  echo "1。英語2。簡素化された中国語3。伝統的な中国語"
  echo "------------------------"
  echo "0。前のメニューに戻ります"
  echo "------------------------"
  read -e -p "あなたの選択を入力してください：" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "英語に切り替えます"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "簡素化された中国人に切り替えます"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "伝統的な中国人に切り替えます"
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
echo -e "${gl_lv}変更が完了します。 SSHを再接続して変更を表示します！${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "コマンドラインの美化ツール"
  while true; do
	clear
	echo "コマンドラインの美化ツール"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0。前のメニューに戻ります"
	echo "------------------------"
	read -e -p "あなたの選択を入力してください：" choice

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
  send_stats "システムリサイクルステーション"

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
	echo -e "現在のリサイクルビン${trash_status}"
	echo -e "有効になった後、RMによって削除されたファイルは、最初にリサイクルビンに入り、重要なファイルの誤った削除を防ぎます！"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "リサイクルビンは空です"
	echo "------------------------"
	echo "1.リサイクルビン2を有効にします。リサイクルビンを閉じます"
	echo "3。コンテンツを復元4。リサイクルビンをクリアします"
	echo "------------------------"
	echo "0。前のメニューに戻ります"
	echo "------------------------"
	read -e -p "あなたの選択を入力してください：" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "リサイクルビンが有効になり、削除されたファイルがリサイクルビンに移動されます。"
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "リサイクルビンが閉じられ、ファイルが直接削除されます。"
		sleep 2
		;;
	  3)
		read -e -p "復元するにはファイル名を入力してください。" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restoreホームディレクトリに復元されました。"
		else
		  echo "ファイルは存在しません。"
		fi
		;;
	  4)
		read -e -p "リサイクルビンをクリアすることを確認しますか？ [Y/N]：" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "リサイクルビンがクリアされました。"
		fi
		;;
	  *)
		break
		;;
	esac
  done
}



# バックアップを作成します
create_backup() {
	send_stats "バックアップを作成します"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# ユーザーにバックアップディレクトリを入力するように求めます
	echo "バックアップ例を作成します："
	echo "- 単一のディレクトリをバックアップします： /var /www"
	echo "- バックアップ複数のディレクトリ： /etc /home /var /log"
	echo "-directEnterはデフォルトのディレクトリ（ /etc /usr /home）を使用します"
	read -r -p "ディレクトリを入力してバックアップしてください（複数のディレクトリがスペースで区切られています。直接入力する場合は、デフォルトのディレクトリを使用してください）：" input

	# ユーザーがディレクトリを入力しない場合は、デフォルトのディレクトリを使用します
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# ユーザーが入力したディレクトリをスペースごとに配列に分離します
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# バックアップファイルプレフィックスを生成します
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# ディレクトリ名を抽出し、スラッシュを削除します
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 最後のアンダースコアを削除します
	local PREFIX=${PREFIX%_}

	# バックアップファイル名を生成します
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# ユーザーが選択したディレクトリを印刷します
	echo "選択したバックアップディレクトリは次のとおりです。"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# バックアップを作成します
	echo "バックアップを作成します$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# コマンドが成功しているかどうかを確認してください
	if [ $? -eq 0 ]; then
		echo "バックアップは正常に作成されました：$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "バックアップの作成に失敗しました！"
		exit 1
	fi
}

# バックアップを復元します
restore_backup() {
	send_stats "バックアップを復元します"
	# 復元するバックアップを選択します
	read -e -p "復元するには、バックアップファイル名を入力してください。" BACKUP_NAME

	# バックアップファイルが存在するかどうかを確認します
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルは存在しません！"
		exit 1
	fi

	echo "バックアップの回復$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "バックアップと復元を正常に！"
	else
		echo "バックアップリカバリに失敗しました！"
		exit 1
	fi
}

# バックアップをリストします
list_backups() {
	echo "利用可能なバックアップ："
	ls -1 "$BACKUP_DIR"
}

# バックアップを削除します
delete_backup() {
	send_stats "バックアップを削除します"

	read -e -p "削除するには、バックアップファイル名を入力してください。" BACKUP_NAME

	# バックアップファイルが存在するかどうかを確認します
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルは存在しません！"
		exit 1
	fi

	# バックアップを削除します
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "バックアップは正常に削除されました！"
	else
		echo "バックアップの削除が失敗しました！"
		exit 1
	fi
}

# バックアップメインメニュー
linux_backup() {
	BACKUP_DIR="/backups"
	mkdir -p "$BACKUP_DIR"
	while true; do
		clear
		send_stats "システムバックアップ機能"
		echo "システムバックアップ機能"
		echo "------------------------"
		list_backups
		echo "------------------------"
		echo "1.バックアップを作成する2。バックアップを復元3。バックアップを削除します"
		echo "------------------------"
		echo "0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "選択を入力してください：" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "Enterを押して続行します..."
	done
}









# 接続リストを表示します
list_connections() {
	echo "接続の保存："
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 新しい接続を追加します
add_connection() {
	send_stats "新しい接続を追加します"
	echo "新しい接続を作成する例："
	echo "- 接続名：my_server"
	echo "-  IPアドレス：192.168.1.100"
	echo "- ユーザー名：root"
	echo "- ポート：22"
	echo "------------------------"
	read -e -p "接続名を入力してください：" name
	read -e -p "IPアドレスを入力してください：" ip
	read -e -p "ユーザー名（デフォルト：root）を入力してください：" user
	local user=${user:-root}  # 如果用户未输入，则使用默认值 root
	read -e -p "ポート番号を入力してください（デフォルト：22）：" port
	local port=${port:-22}  # 如果用户未输入，则使用默认值 22

	echo "認証方法を選択してください："
	echo "1。パスワード"
	echo "2。キー"
	read -e -p "選択（1/2）を入力してください：" auth_choice

	case $auth_choice in
		1)
			read -s -p "パスワードを入力してください：" password_or_key
			echo  # 换行
			;;
		2)
			echo "キーコンテンツを貼り付けてください（貼り付け後に2回Enterを押します）を押してください）："
			local password_or_key=""
			while IFS= read -r line; do
				# 入力が空で、キーコンテンツにすでに開始が含まれている場合、入力は終了します
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# それが最初の行であるか、キーコンテンツが入力されている場合は、さらに追加し続けます
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					local password_or_key+="${line}"$'\n'
				fi
			done

			# キーコンテンツのかどうかを確認してください
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/$name.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				local password_or_key="$key_file"
			fi
			;;
		*)
			echo "無効な選択！"
			return
			;;
	esac

	echo "$name|$ip|$user|$port|$password_or_key" >> "$CONFIG_FILE"
	echo "接続が保存されます！"
}



# 接続を削除します
delete_connection() {
	send_stats "接続を削除します"
	read -e -p "削除するには、接続番号を入力してください。" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "エラー：対応する接続は見つかりませんでした。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 接続がキーファイルを使用している場合、キーファイルを削除します
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "接続が削除されました！"
}

# 接続を使用します
use_connection() {
	send_stats "接続を使用します"
	read -e -p "使用するには、接続番号を入力してください。" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "エラー：対応する接続は見つかりませんでした。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "接続$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# キーに接続します
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました！以下を確認してください。"
			echo "1。キーファイルパスは正しいですか？$password_or_key"
			echo "2。キーファイルの権限が正しいかどうか（600である必要があります）。"
			echo "3.ターゲットサーバーがキーを使用してログインできるかどうか。"
		fi
	else
		# パスワードで接続します
		if ! command -v sshpass &> /dev/null; then
			echo "エラー：SSHPassはインストールされていません。最初にSSHPassをインストールしてください。"
			echo "インストール方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました！以下を確認してください。"
			echo "1.ユーザー名とパスワードが正しいかどうか。"
			echo "2。ターゲットサーバーがパスワードログインを許可するかどうか。"
			echo "3.ターゲットサーバーのSSHサービスが正常に実行されているかどうか。"
		fi
	fi
}


ssh_manager() {
	send_stats "SSHリモート接続ツール"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 構成ファイルとキーディレクトリが存在するかどうかを確認し、それが存在しない場合は、それを作成します
	if [[ ! -f "$CONFIG_FILE" ]]; then
		touch "$CONFIG_FILE"
	fi

	if [[ ! -d "$KEY_DIR" ]]; then
		mkdir -p "$KEY_DIR"
		chmod 700 "$KEY_DIR"
	fi

	while true; do
		clear
		echo "SSHリモート接続ツール"
		echo "SSHを介して他のLinuxシステムに接続できます"
		echo "------------------------"
		list_connections
		echo "1.新しい接続を作成する2。接続を使用する3。接続を削除します"
		echo "------------------------"
		echo "0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "選択を入力してください：" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "無効な選択、もう一度やり直してください。" ;;
		esac
	done
}












# 利用可能なハードディスクパーティションをリストします
list_partitions() {
	echo "利用可能なハードディスクパーティション："
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}

# パーティションをマウントします
mount_partition() {
	send_stats "パーティションをマウントします"
	read -e -p "マウントするパーティション名を入力してください（たとえば、SDA1）：" PARTITION

	# パーティションが存在するかどうかを確認します
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションは存在しません！"
		return
	fi

	# パーティションが既にマウントされているかどうかを確認してください
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションはすでに取り付けられています！"
		return
	fi

	# マウントポイントを作成します
	MOUNT_POINT="/mnt/$PARTITION"
	mkdir -p "$MOUNT_POINT"

	# パーティションをマウントします
	mount "/dev/$PARTITION" "$MOUNT_POINT"

	if [ $? -eq 0 ]; then
		echo "パーティションマウントに正常に：$MOUNT_POINT"
	else
		echo "パーティションマウントは失敗しました！"
		rmdir "$MOUNT_POINT"
	fi
}

# パーティションをアンインストールします
unmount_partition() {
	send_stats "パーティションをアンインストールします"
	read -e -p "パーティション名（たとえば、SDA1）を入力してください。" PARTITION

	# パーティションが既にマウントされているかどうかを確認してください
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "パーティションはマウントされていません！"
		return
	fi

	# パーティションをアンインストールします
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティションのアンインストールに正常に：$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "パーティションのアンインストールに失敗しました！"
	fi
}

# マウントされたパーティションをリストします
list_mounted_partitions() {
	echo "マウントされたパーティション："
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# フォーマットパーティション
format_partition() {
	send_stats "フォーマットパーティション"
	read -e -p "パーティション名を入力してフォーマット（たとえば、SDA1）：" PARTITION

	# パーティションが存在するかどうかを確認します
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションは存在しません！"
		return
	fi

	# パーティションが既にマウントされているかどうかを確認してください
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションがマウントされました。最初にアンインストールしてください！"
		return
	fi

	# ファイルシステムタイプを選択します
	echo "ファイルシステムタイプを選択してください："
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "選択を入力してください：" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "無効な選択！"; return ;;
	esac

	# フォーマットを確認します
	read -e -p "フォーマットパーティション /dev /$PARTITIONのために$FS_TYPEそれですか？ （y/n）：" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "操作はキャンセルされました。"
		return
	fi

	# フォーマットパーティション
	echo "パーティション /dev /のフォーマット /$PARTITIONのために$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティション形式は成功しました！"
	else
		echo "パーティションのフォーマットが失敗しました！"
	fi
}

# パーティションステータスを確認します
check_partition() {
	send_stats "パーティションステータスを確認します"
	read -e -p "パーティション名を入力して確認してください（たとえばSDA1）：" PARTITION

	# パーティションが存在するかどうかを確認します
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションは存在しません！"
		return
	fi

	# パーティションステータスを確認します
	echo "パーティション /dev /$PARTITION状態："
	fsck "/dev/$PARTITION"
}

# メインメニュー
disk_manager() {
	send_stats "ハードディスク管理機能"
	while true; do
		clear
		echo "ハードディスクパーティション管理"
		echo -e "${gl_huang}この関数は、テスト期間中に内部的にテストされています。生産環境では使用しないでください。${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1。パーティションをマウント2。パーティションをアンインストールする3。マウントされたパーティションを表示"
		echo "4。パーティション5をフォーマットします。パーティションステータスを確認します"
		echo "------------------------"
		echo "0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "選択を入力してください：" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "Enterを押して続行します..."
	done
}




# タスクリストを表示します
list_tasks() {
	echo "保存された同期タスク："
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 新しいタスクを追加します
add_task() {
	send_stats "新しい同期タスクを追加します"
	echo "新しい同期タスクを作成する例："
	echo "- タスク名：backup_www"
	echo "- ローカルディレクトリ： /var /www"
	echo "- リモートアドレス：user@192.168.1.100"
	echo "- リモートディレクトリ： /バックアップ /www"
	echo "- ポート番号（デフォルト22）"
	echo "---------------------------------"
	read -e -p "タスク名を入力してください：" name
	read -e -p "ローカルディレクトリを入力してください：" local_path
	read -e -p "リモートディレクトリを入力してください：" remote_path
	read -e -p "リモートユーザー@IPを入力してください：" remote
	read -e -p "SSHポートを入力してください（デフォルト22）：" port
	port=${port:-22}

	echo "認証方法を選択してください："
	echo "1。パスワード"
	echo "2。キー"
	read -e -p "（1/2）を選択してください：" auth_choice

	case $auth_choice in
		1)
			read -s -p "パスワードを入力してください：" password_or_key
			echo  # 换行
			auth_method="password"
			;;
		2)
			echo "キーコンテンツを貼り付けてください（貼り付け後に2回Enterを押します）を押してください）："
			local password_or_key=""
			while IFS= read -r line; do
				# 入力が空で、キーコンテンツにすでに開始が含まれている場合、入力は終了します
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				# それが最初の行であるか、キーコンテンツが入力されている場合は、さらに追加し続けます
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			# キーコンテンツのかどうかを確認してください
			if [[ "$password_or_key" == *"-----BEGIN"* && "$password_or_key" == *"PRIVATE KEY-----"* ]]; then
				local key_file="$KEY_DIR/${name}_sync.key"
				echo -n "$password_or_key" > "$key_file"
				chmod 600 "$key_file"
				password_or_key="$key_file"
				auth_method="key"
			else
				echo "無効なキーコンテンツ！"
				return
			fi
			;;
		*)
			echo "無効な選択！"
			return
			;;
	esac

	echo "同期モードを選択してください："
	echo "1。標準モード（-AVZ）"
	echo "2。ターゲットファイル（-avz  -  delete）を削除します"
	read -e -p "（1/2）を選択してください：" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "無効な選択、デフォルト-AVZを使用します"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "タスクが節約されました！"
}

# タスクを削除します
delete_task() {
	send_stats "同期タスクを削除します"
	read -e -p "削除するには、タスク番号を入力してください。" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "エラー：対応するタスクは見つかりませんでした。"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# タスクがキーファイルを使用している場合、キーファイルを削除します
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "削除されたタスク！"
}


run_task() {
	send_stats "同期タスクを実行します"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# パラメーターを分析します
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# 着信タスク番号がない場合は、ユーザーに入力するように促します
	if [[ -z "$num" ]]; then
		read -e -p "実行するタスク番号を入力してください：" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "エラー：タスクは見つかりませんでした！"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 同期の方向に従ってソースとターゲットのパスを調整します
	if [[ "$direction" == "pull" ]]; then
		echo "同期をローカルに引く：$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "同期をリモートエンドに押します：$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# SSH接続の共通パラメーターを追加します
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "エラー：SSHPassはインストールされていません。最初にSSHPassをインストールしてください。"
			echo "インストール方法："
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# キーファイルが存在するかどうか、およびアクセス許可が正しいかどうかを確認します
		if [[ ! -f "$password_or_key" ]]; then
			echo "エラー：キーファイルが存在しません：$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "警告：キーファイルのアクセス許可が正しくなく、修理されています..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "同期は完了です！"
	else
		echo "同期は失敗しました！以下を確認してください。"
		echo "1。ネットワーク接続は正常ですか？"
		echo "2。リモートホストにアクセスできますか？"
		echo "3。認証情報は正しいですか？"
		echo "4.ローカルおよびリモートディレクトリには正しいアクセス許可がありますか"
	fi
}


# 時限タスクを作成します
schedule_task() {
	send_stats "同期タイミングタスクを追加します"

	read -e -p "定期的に同期するには、タスク番号を入力してください。" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "エラー：有効なタスク番号を入力してください！"
		return
	fi

	echo "時限実行間隔を選択してください："
	echo "1）1時間に1回実行します"
	echo "2）1日1回実行します"
	echo "3）週に1回実行します"
	read -e -p "オプションを入力してください（1/2/3）：" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "エラー：有効なオプションを入力してください！" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 同じタスクが既に存在するかどうかを確認してください
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "エラー：このタスクのタイミング同期はすでに存在しています！"
		return
	fi

	# ユーザーにクロンタブを作成します
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "タイミングタスクが作成されました。$cron_job"
}

# スケジュールされたタスクを表示します
view_tasks() {
	echo "現在のタイミングタスク："
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# タイミングタスクを削除します
delete_task_schedule() {
	send_stats "同期タイミングタスクを削除します"
	read -e -p "削除するには、タスク番号を入力してください。" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "エラー：有効なタスク番号を入力してください！"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "削除されたタスク番号$numタイミングタスク"
}


# タスク管理メインメニュー
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "RSYNCリモート同期ツール"
		echo "リモートディレクトリ間の同期は、増分同期、効率的、安定性をサポートします。"
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1.新しいタスクを作成します2。タスクを削除します"
		echo "3.リモートエンドにローカル同期を実行する4。ローカルエンドにリモート同期を実行する"
		echo "5.タイミングタスクを作成6。タイミングタスクを削除します"
		echo "---------------------------------"
		echo "0。前のメニューに戻ります"
		echo "---------------------------------"
		read -e -p "選択を入力してください：" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "無効な選択、もう一度やり直してください。" ;;
		esac
		read -e -p "Enterを押して続行します..."
	done
}









linux_ps() {

	clear
	send_stats "システム情報クエリ"

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
	echo -e "システム情報クエリ"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ホスト名：${gl_bai}$hostname"
	echo -e "${gl_kjlan}システムバージョン：${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linuxバージョン：${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPUアーキテクチャ：${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPUモデル：${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPUコアの数：${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU頻度：${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU占有：${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}システムの負荷：${gl_bai}$load"
	echo -e "${gl_kjlan}物理的記憶：${gl_bai}$mem_info"
	echo -e "${gl_kjlan}仮想メモリ：${gl_bai}$swap_info"
	echo -e "${gl_kjlan}ハードディスクの職業：${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}合計受信：${gl_bai}$rx"
	echo -e "${gl_kjlan}合計送信：${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ネットワークアルゴリズム：${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}オペレーター：${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4アドレス：${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6アドレス：${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNSアドレス：${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}地理的場所：${gl_bai}$country $city"
	echo -e "${gl_kjlan}システム時間：${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ランタイム：${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats「基本ツール」
	  echo -e "基本的なツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}カールダウンロードツール${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}WGETダウンロードツール${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}SUDOスーパー管理許可ツール${gl_kjlan}4.   ${gl_bai}Socat Communication Connection Tool"
	  echo -e "${gl_kjlan}5.   ${gl_bai}HTOPシステム監視ツール${gl_kjlan}6.   ${gl_bai}IFTOPネットワークトラフィック監視ツール"
	  echo -e "${gl_kjlan}7.   ${gl_bai}ジップzip圧縮減圧ツールを解凍します${gl_kjlan}8.   ${gl_bai}TAR GZ圧縮減圧ツール"
	  echo -e "${gl_kjlan}9.   ${gl_bai}TMUXマルチチャネルバックグラウンドランニングツール${gl_kjlan}10.  ${gl_bai}Live StreamingツールをエンコードするFFMPEGビデオ"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}BTOPモダン監視ツール${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}範囲ファイル管理ツール"
	  echo -e "${gl_kjlan}13.  ${gl_bai}NCDUディスク職業視聴ツール${gl_kjlan}14.  ${gl_bai}fzf 全局搜索工具"
	  echo -e "${gl_kjlan}15.  ${gl_bai}VIMテキストエディター${gl_kjlan}16.  ${gl_bai}ナノテキストエディター${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}gitバージョン制御システム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}マトリックス画面保証${gl_kjlan}22.  ${gl_bai}列車のスクリーンのセキュリティ"
	  echo -e "${gl_kjlan}26.  ${gl_bai}テトリスゲーム${gl_kjlan}27.  ${gl_bai}ヘビを食べるゲーム"
	  echo -e "${gl_kjlan}28.  ${gl_bai}スペースインベーダーゲーム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}すべてをインストールします${gl_kjlan}32.  ${gl_bai}すべてのインストール（スクリーンセーバーとゲームを除く）${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}すべてをアンインストールします"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}指定されたツールをインストールします${gl_kjlan}42.  ${gl_bai}指定されたツールをアンインストールします"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  curl --help
			  send_stats "カールをインストールします"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  wget --help
			  send_stats "WGETをインストールします"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  sudo --help
			  send_stats "sudoをインストールします"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  socat -h
			  send_stats "SOCATをインストールします"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "HTOPをインストールします"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "IFTOPをインストールします"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  unzip
			  send_stats "unzipをインストールします"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  tar --help
			  send_stats "タールをインストールします"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  tmux --help
			  send_stats "tmuxをインストールします"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "ツールがインストールされており、使用方法は次のとおりです。"
			  ffmpeg --help
			  send_stats "ffmpegをインストールします"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "BTOPをインストールします"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "レンジャーをインストールします"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "NCDUをインストールします"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "FZFをインストールします"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "VIMをインストールします"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "ナノをインストールします"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "gitをインストールします"
			  ;;

			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "cmatrixをインストールします"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "SLをインストールします"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "バステットをインストールします"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "nsnakeをインストールします"
			  ;;
			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "Ninvadersをインストールします"
			  ;;

		  31)
			  clear
			  send_stats "すべてをインストールします"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "すべてをインストールします（ゲームやスクリーンセーバーを除く）"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "すべてをアンインストールします"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  41)
			  clear
			  read -e -p "インストールされているツール名（Wget Curl Sudo htop）を入力してください。" installname
			  install $installname
			  send_stats "指定されたソフトウェアをインストールします"
			  ;;
		  42)
			  clear
			  read -e -p "アンインストールされていないツール名（HTOP UFW TMUX CMATRIX）を入力してください。" removename
			  remove $removename
			  send_stats "指定されたソフトウェアをアンインストールします"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end
  done




}


linux_bbr() {
	clear
	send_stats "BBR管理"
	if [ -f "/etc/alpine-release" ]; then
		while true; do
			  clear
			  local congestion_algorithm=$(sysctl -n net.ipv4.tcp_congestion_control)
			  local queue_algorithm=$(sysctl -n net.core.default_qdisc)
			  echo "現在のTCPブロッキングアルゴリズム：$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR管理"
			  echo "------------------------"
			  echo "1。BBRV3 2をオンにします。BBRV3（再起動）をオフにします"
			  echo "------------------------"
			  echo "0。前のメニューに戻ります"
			  echo "------------------------"
			  read -e -p "選択を入力してください：" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "AlpineはBBR3を有効にします"
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
	  # send_stats「Docker Management」
	  echo -e "Docker管理"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Docker環境をインストールして更新します${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Dockerグローバルステータスを表示します${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Dockerコンテナ管理${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Docker画像管理"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Dockerネットワーク管理"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Dockerボリューム管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}清潔な役に立たないドッカーコンテナとミラーネットワークデータボリューム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Dockerソースを交換します"
	  echo -e "${gl_kjlan}9.   ${gl_bai}daemon.jsonファイルを編集します"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}docker-ipv6アクセスを有効にします"
	  echo -e "${gl_kjlan}12.  ${gl_bai}docker-ipv6アクセスを閉じます"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Docker環境をアンインストールします"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "Docker環境をインストールします"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "Dockerグローバルステータス"
			  echo "Dockerバージョン"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker画像：${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "Dockerコンテナ：${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Dockerボリューム：${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Dockerネットワーク：${gl_lv}$network_count${gl_bai}"
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
				  send_stats "Dockerネットワーク管理"
				  echo "Dockerネットワークリスト"
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
				  echo "ネットワーク操作"
				  echo "------------------------"
				  echo "1.ネットワークを作成します"
				  echo "2。インターネットに参加してください"
				  echo "3。ネットワークを終了します"
				  echo "4.ネットワークを削除します"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "ネットワークを作成します"
						  read -e -p "新しいネットワーク名を設定します：" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "インターネットに参加してください"
						  read -e -p "ネットワーク名に参加してください：" dockernetwork
						  read -e -p "これらのコンテナはネットワークに追加されます（複数のコンテナ名はスペースで区切られています）：" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "インターネットに参加してください"
						  read -e -p "出口ネットワーク名：" dockernetwork
						  read -e -p "これらのコンテナはネットワークを終了します（複数のコンテナ名はスペースで区切られています）：" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "ネットワークを削除します"
						  read -e -p "削除するには、ネットワーク名を入力してください。" dockernetwork
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
				  send_stats "Dockerボリューム管理"
				  echo "Dockerボリュームリスト"
				  docker volume ls
				  echo ""
				  echo "ボリューム操作"
				  echo "------------------------"
				  echo "1.新しいボリュームを作成します"
				  echo "2。指定されたボリュームを削除します"
				  echo "3.すべてのボリュームを削除します"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "新しいボリュームを作成します"
						  read -e -p "新しいボリューム名を設定します：" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "削除ボリューム名を入力します（スペースで複数のボリューム名を分離してください）：" dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "すべてのボリュームを削除します"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "無効な選択、yまたはnを入力してください。"
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
			  send_stats "Dockerクリーニング"
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "無効な選択、yまたはnを入力してください。"
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "Dockerソース"
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
			  send_stats "Docker V6が開いています"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker V6レベル"
			  docker_ipv6_off
			  ;;

		  20)
			  clear
			  send_stats "Dockerアンインストール"
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
				  echo "無効な選択、yまたはnを入力してください。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats「テストスクリプトコレクション」
	  echo -e "テストスクリプトコレクション"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IPおよびロック解除ステータス検出"
	  echo -e "${gl_kjlan}1.   ${gl_bai}CHATGPTはステータス検出のロックを解除します"
	  echo -e "${gl_kjlan}2.   ${gl_bai}リージョンストリーミングメディアのロック解除テスト"
	  echo -e "${gl_kjlan}3.   ${gl_bai}YeahWUストリーミングメディアのロック解除検出"
	  echo -e "${gl_kjlan}4.   ${gl_bai}XYKT IP品質の身体検査スクリプト${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}ネットワーク速度測定"
	  echo -e "${gl_kjlan}11.  ${gl_bai}BestTrace 3ネットワークバックホール遅延ルーティングテスト"
	  echo -e "${gl_kjlan}12.  ${gl_bai}MTR_TRACE 3ネットワークバックホールラインテスト"
	  echo -e "${gl_kjlan}13.  ${gl_bai}SuperSpeed Three-Net速度測定"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace高速バックホールテストスクリプト"
	  echo -e "${gl_kjlan}15.  ${gl_bai}Nxtraceは、IPバックホールテストスクリプトを指定します"
	  echo -e "${gl_kjlan}16.  ${gl_bai}Ludashi2020 3ネットワークラインテスト"
	  echo -e "${gl_kjlan}17.  ${gl_bai}I-ABC多機能速度テストスクリプト"
	  echo -e "${gl_kjlan}18.  ${gl_bai}ネットワーク品質の高品質の身体検査スクリプト${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}ハードウェアパフォーマンステスト"
	  echo -e "${gl_kjlan}21.  ${gl_bai}YABSパフォーマンステスト"
	  echo -e "${gl_kjlan}22.  ${gl_bai}IICU/GB5 CPUパフォーマンステストスクリプト"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}包括的なテスト"
	  echo -e "${gl_kjlan}31.  ${gl_bai}ベンチパフォーマンステスト"
	  echo -e "${gl_kjlan}32.  ${gl_bai}SpiritySDX Fusion Monster Review${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "CHATGPTはステータス検出のロックを解除します"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "リージョンストリーミングメディアのロック解除テスト"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "YeahWUストリーミングメディアのロック解除検出"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "XYKT_IP品質の身体検査スクリプト"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "BestTrace 3ネットワークバックホール遅延ルーティングテスト"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "MTR_TRACE 3ネットワークリターンラインテスト"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "SuperSpeed Three-Net速度測定"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace高速バックホールテストスクリプト"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "Nxtraceは、IPバックホールテストスクリプトを指定します"
			  echo "参照できるIPのリスト"
			  echo "------------------------"
			  echo "北京テレコム：219.141.136.12"
			  echo "北京ユニコム：202.106.50.1"
			  echo "北京モバイル：221.179.155.161"
			  echo "上海通信：202.96.209.133"
			  echo "上海ユニコム：210.22.97.1"
			  echo "上海モバイル：211.136.112.200"
			  echo "広州通信：58.60.188.222"
			  echo "広州ユニコム：210.21.196.6"
			  echo "広州モバイル：120.196.165.24"
			  echo "成都通信：61.139.2.69"
			  echo "成都ユニコム：119.6.6.6"
			  echo "成都モバイル：211.137.96.205"
			  echo "Hunan Telecom：36.111.200.100"
			  echo "Hunan Unicom：42.48.16.100"
			  echo "Hunan Mobile：39.134.254.6"
			  echo "------------------------"

			  read -e -p "指定されたIPを入力してください：" testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "Ludashi2020 3ネットワークラインテスト"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "I-ABC多機能速度テストスクリプト"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "ネットワーク品質のテストスクリプト"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "YABSパフォーマンステスト"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "IICU/GB5 CPUパフォーマンステストスクリプト"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "ベンチパフォーマンステスト"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "SpiritySDX Fusion Monster Review"
			  clear
			  curl -L https://gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "Oracle Cloud Scriptコレクション"
	  echo -e "Oracle Cloud Scriptコレクション"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}アイドルマシンアクティブスクリプトをインストールします"
	  echo -e "${gl_kjlan}2.   ${gl_bai}アイドルマシンアクティブスクリプトをアンインストールします"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DDシステムスクリプトを再インストールします"
	  echo -e "${gl_kjlan}4.   ${gl_bai}探偵r開始スクリプト"
	  echo -e "${gl_kjlan}5.   ${gl_bai}ルートパスワードログインモードをオンにします"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPv6回復ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "アクティブスクリプト：CPUが10-20％を占めるメモリは20％を占めています"
			  read -e -p "必ずインストールしますか？ （y/n）：" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # デフォルト値を設定します
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # ユーザーにCPUコアの数と占有率の数を入力するように促し、入力した場合はデフォルト値を使用します。
				  read -e -p "CPUコアの数を入力してください[デフォルト：$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "CPU使用率の範囲（たとえば、10-20）を入力してください[デフォルト：$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "メモリの使用率を入力してください[デフォルト：$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "SpeedTest間隔時間（秒）を入力してください[デフォルト：$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # Dockerコンテナを実行します
				  docker run -itd --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "Oracle Cloudインストールアクティブスクリプト"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "無効な選択、yまたはnを入力してください。"
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "Oracle Cloudはアクティブスクリプトをアンインストールします"
			  ;;

		  3)
		  clear
		  echo "システムを再インストールします"
		  echo "--------------------------------"
		  echo -e "${gl_hong}知らせ：${gl_bai}再インストールは接触を失う危険であり、心配している人はそれを注意して使用する必要があります。再インストールには15分かかると予想されます。事前にデータをバックアップしてください。"
		  read -e -p "必ず続行しますか？ （y/n）：" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "再インストールするシステムを選択してください：1。Debian12| 2。Ubuntu20.04：" sys_choice

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
					echo "選択の無効な、再入力してください。"
					;;
				esac
			  done

			  read -e -p "再インストールされたパスワードを入力してください：" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "Oracle Cloud再インストールシステムスクリプト"
			  ;;
			[Nn])
			  echo "キャンセル"
			  ;;
			*)
			  echo "無効な選択、yまたはnを入力してください。"
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  echo "この機能は開発段階にあるので、お楽しみに！"
			  ;;
		  5)
			  clear
			  add_sshpasswd

			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "この関数は、彼のおかげで、マスターJHBによって提供されます！"
			  send_stats "IPv6修正"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力！"
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
		echo -e "${gl_lv}環境がインストールされています${gl_bai}容器：${gl_lv}$container_count${gl_bai}鏡：${gl_lv}$image_count${gl_bai}ネットワーク：${gl_lv}$network_count${gl_bai}ロール：${gl_lv}$volume_count${gl_bai}"
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
		echo -e "${gl_lv}環境がインストールされています${gl_bai}  $output  $db_output"
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
	# send_stats "ldnmp webサイトビルディング"
	echo -e "${gl_huang}LDNMP Webサイトビルディング"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}LDNMP環境をインストールします${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}WordPressをインストールします${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}Discuzフォーラムをインストールします${gl_huang}4.   ${gl_bai}Kadao Cloudデスクトップをインストールします"
	echo -e "${gl_huang}5.   ${gl_bai}Apple CMSフィルムとテレビ局をインストールします${gl_huang}6.   ${gl_bai}ユニコーンデジタルカードネットワークをインストールします"
	echo -e "${gl_huang}7.   ${gl_bai}Flarum Forum Webサイトをインストールします${gl_huang}8.   ${gl_bai}Typecho Lightweight Blog Webサイトをインストールします"
	echo -e "${gl_huang}9.   ${gl_bai}LinkStack共有リンクプラットフォームをインストールします${gl_huang}20.  ${gl_bai}動的サイトをカスタマイズします"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}nginxのみをインストールします${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}サイトリダイレクト"
	echo -e "${gl_huang}23.  ${gl_bai}サイトリバースプロキシ-IP+ポート${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}サイトリバースプロキシ - ドメイン名"
	echo -e "${gl_huang}25.  ${gl_bai}Bitwardenパスワード管理プラットフォームをインストールします${gl_huang}26.  ${gl_bai}HaloブログのWebサイトをインストールします"
	echo -e "${gl_huang}27.  ${gl_bai}AIペイントプロンプトワードジェネレーターをインストールします${gl_huang}28.  ${gl_bai}サイトの逆プロキシロードバランス"
	echo -e "${gl_huang}30.  ${gl_bai}静的サイトをカスタマイズします"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}サイトデータ管理${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}サイトデータ全体をバックアップします"
	echo -e "${gl_huang}33.  ${gl_bai}タイミングのリモートバックアップ${gl_huang}34.  ${gl_bai}サイトデータ全体を復元します"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}LDNMP環境を保護します${gl_huang}36.  ${gl_bai}LDNMP環境を最適化します"
	echo -e "${gl_huang}37.  ${gl_bai}LDNMP環境を更新します${gl_huang}38.  ${gl_bai}LDNMP環境をアンインストールします"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}メインメニューに戻ります"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "選択を入力してください：" sub_choice


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
	  # ディスクフォーラム
	  webname="Discuz论坛"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo "データベースアドレス：mysql"
	  echo "データベース名：$dbname"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "テーブルプレフィックス：discuz_"


		;;

	  4)
	  clear
	  # Kedao Cloudデスクトップ
	  webname="可道云桌面"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo "データベースアドレス：mysql"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "データベース名：$dbname"
	  echo "Redisホスト：Redis"

		;;

	  5)
	  clear
	  # Apple CMS
	  webname="苹果CMS"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo "データベースアドレス：mysql"
	  echo "データベースポート：3306"
	  echo "データベース名：$dbname"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "データベースプレフィックス：mac_"
	  echo "------------------------"
	  echo "インストールが成功した後、バックグラウンドアドレスにログインします"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 一本足のカウントカード
	  webname="独脚数卡"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo "データベースアドレス：mysql"
	  echo "データベースポート：3306"
	  echo "データベース名：$dbname"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo ""
	  echo "Redisアドレス：Redis"
	  echo "Redisパスワード：デフォルトで記入されていません"
	  echo "Redisポート：6379"
	  echo ""
	  echo "ウェブサイトURL：https：//$yuming"
	  echo "バックグラウンドログインパス： /admin"
	  echo "------------------------"
	  echo "ユーザー名：admin"
	  echo "パスワード：管理者"
	  echo "------------------------"
	  echo "ログインするときに右上隅に赤いerror0が表示される場合は、次のコマンドを使用してください。"
	  echo "また、ユニコーン番号カードがとても面倒で、そのような問題があることに非常に腹を立てています！"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # フララムフォーラム
	  webname="flarum论坛"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo "データベースアドレス：mysql"
	  echo "データベース名：$dbname"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "テーブルプレフィックス：flarum_"
	  echo "管理者情報は自分で設定されます"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo "データベースプレフィックス：typecho_"
	  echo "データベースアドレス：mysql"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "データベース名：$dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo "データベースアドレス：mysql"
	  echo "データベースポート：3306"
	  echo "データベース名：$dbname"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP动态站点"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo -e "[${gl_huang}1/6${gl_bai}] PHPソースコードをアップロードします"
	  echo "-------------"
	  echo "現在、zip-formatソースコードパッケージのみが許可されています。ソースコードパッケージを/home/web/html/に入れてください${yuming}ディレクトリ内"
	  read -e -p "ダウンロードリンクを入力して、ソースコードパッケージをリモートでダウンロードすることもできます。 Enterを直接押してリモートダウンロードをスキップします。" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}] index.phpが配置されているパス"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "（/home/web/html/に似たindex.phpのパスを入力してください$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] PHPバージョンを選択してください"
	  echo "-------------"
	  read -e -p "1。PHPの最新バージョン| 2。Php7.4：" pho_v
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
		  echo "選択の無効な、再入力してください。"
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}]指定された拡張機能をインストールします"
	  echo "-------------"
	  echo "インストールされた拡張機能"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}]サイト構成を編集します"
	  echo "-------------"
	  echo "任意のキーを押して続行すると、擬似静的コンテンツなど、サイト構成を詳細に設定できます。"
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}]データベース管理"
	  echo "-------------"
	  read -e -p "1.新しいサイトを構築します2。古いサイトを構築し、データベースのバックアップがあります。" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "データベースのバックアップは、.GZ-endコンプレッションパッケージである必要があります。 Pagoda/1panelのバックアップデータのインポートをサポートするために、/home/directoryに入れてください。"
			  read -e -p "ダウンロードリンクを入力して、バックアップデータをリモートでダウンロードすることもできます。 Enterを直接押して、リモートダウンロードをスキップします：" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "データベースインポートテーブルデータ"
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" -e "USE $dbname; SHOW TABLES;"
			  rm -f *.sql
			  echo "データベースのインポートが完了しました"
			  ;;
		  *)
			  echo
			  ;;
	  esac

	  docker exec php rm -f /usr/local/etc/php/conf.d/optimized_php.ini

	  restart_ldnmp
	  ldnmp_web_on
	  prefix="web$(shuf -i 10-99 -n 1)_"
	  echo "データベースアドレス：mysql"
	  echo "データベース名：$dbname"
	  echo "ユーザー名：$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "テーブルプレフィックス：$prefix"
	  echo "管理者ログイン情報は自分で設定されます"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="站点重定向"
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
	  add_yuming
	  read -e -p "ジャンプドメイン名を入力してください：" reverseproxy
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
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
	  add_yuming
	  echo -e "ドメイン名形式：${gl_huang}google.com${gl_bai}"
	  read -e -p "抗ジェネレーションドメイン名を入力してください。" fandai_yuming
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
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  send_stats "インストール$webname"
	  echo "展開を開始します$webname"
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
	  echo -e "[${gl_huang}1/2${gl_bai}]静的ソースコードをアップロードします"
	  echo "-------------"
	  echo "現在、zip-formatソースコードパッケージのみが許可されています。ソースコードパッケージを/home/web/html/に入れてください${yuming}ディレクトリ内"
	  read -e -p "ダウンロードリンクを入力して、ソースコードパッケージをリモートでダウンロードすることもできます。 Enterを直接押してリモートダウンロードをスキップします。" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}] index.htmlが配置されているパス"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "（/home/web/html/に似たindex.htmlへのパスを入力してください$yuming/index/）： " index_lujing

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
	  send_stats "LDNMP環境バックアップ"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_huang}バックアップ$backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "バックアップファイルが作成されました： /home /$backup_filename"
		read -e -p "バックアップデータをリモートサーバーに転送しますか？ （y/n）：" choice
		case "$choice" in
		  [Yy])
			read -e -p "リモートサーバーIPを入力してください：" remote_ip
			if [ -z "$remote_ip" ]; then
			  echo "エラー：リモートサーバーIPを入力してください。"
			  continue
			fi
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "このファイルは、リモートサーバーホームディレクトリに転送されました。"
			else
			  echo "転送されるファイルは見つかりませんでした。"
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "無効な選択、yまたはnを入力してください。"
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "タイミングのリモートバックアップ"
	  read -e -p "リモートサーバーIPを入力してください：" useip
	  read -e -p "リモートサーバーのパスワードを入力してください：" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1。毎週のバックアップ2。毎日のバックアップ"
	  read -e -p "選択を入力してください：" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "毎週のバックアップ（0-6、0は日曜日を表す）の曜日を選択します。" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "毎日のバックアップの時間を選択します（時間、0-23）：" hour
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
	  send_stats "LDNMP環境修復"
	  echo "利用可能なサイトバックアップ"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "入力して最新のバックアップを復元し、バックアップファイル名を入力して指定されたバックアップを復元し、0を入力して終了します。" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # ユーザーがファイル名を入力しない場合は、最新の圧縮パッケージを使用します
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_huang}減圧が行われています$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  check_port
		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "圧縮パッケージは見つかりませんでした。"
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
		  send_stats "LDNMP環境を更新します"
		  echo "LDNMP環境を更新します"
		  echo "------------------------"
		  ldnmp_v
		  echo "コンポーネントの新しいバージョンを発見します"
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
		  echo "1。更新nginx2。mysql3を更新します。php4を更新します。redisを更新します"
		  echo "------------------------"
		  echo "5。完全な環境を更新します"
		  echo "------------------------"
		  echo "0。前のメニューに戻ります"
		  echo "------------------------"
		  read -e -p "選択を入力してください：" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "入力してください${ldnmp_pods}バージョン番号（8.0 8.3 8.4 9.0など）（最新バージョンを取得するには入力）：" version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新します$ldnmp_pods"
			  echo "更新します${ldnmp_pods}仕上げる"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "入力してください${ldnmp_pods}バージョン番号（7.4 8.0 8.1 8.2 8.3）（最新バージョンを入手するには入力）：" version
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
			  send_stats "更新します$ldnmp_pods"
			  echo "更新します${ldnmp_pods}仕上げる"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  restart_redis
			  send_stats "更新します$ldnmp_pods"
			  echo "更新します${ldnmp_pods}仕上げる"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "LDNMP環境を完全に更新します"
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
		send_stats "LDNMP環境をアンインストールします"
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
			echo "無効な選択、yまたはnを入力してください。"
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "無効な入力！"
	esac
	break_end

  done

}



linux_panel() {

	while true; do
	  clear
	  # send_stats「アプリマーケット」
	  echo -e "アプリケーション市場"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Baotaパネルの公式バージョン${gl_kjlan}2.   ${gl_bai}Aapanel International Edition"
	  echo -e "${gl_kjlan}3.   ${gl_bai}1パネルの新世代管理パネル${gl_kjlan}4.   ${gl_bai}nginxproxymanagerビジュアルパネル"
	  echo -e "${gl_kjlan}5.   ${gl_bai}OpenListマルチストアファイルリストプログラム${gl_kjlan}6.   ${gl_bai}UbuntuリモートデスクトップWebエディション"
	  echo -e "${gl_kjlan}7.   ${gl_bai}Nezha Probe VPS監視パネル${gl_kjlan}8.   ${gl_bai}QBオフラインBT磁気ダウンロードパネル"
	  echo -e "${gl_kjlan}9.   ${gl_bai}poste.ioメールサーバープログラム${gl_kjlan}10.  ${gl_bai}Rocketchatマルチプレイヤーオンラインチャットシステム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Zendaoプロジェクト管理ソフトウェア${gl_kjlan}12.  ${gl_bai}Qinglongパネルの時限タスク管理プラットフォーム"
	  echo -e "${gl_kjlan}13.  ${gl_bai}CloudReveネットワークディスク${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${gl_bai}シンプルな写真ベッド画像管理プログラム"
	  echo -e "${gl_kjlan}15.  ${gl_bai}Emby Multimedia Management System${gl_kjlan}16.  ${gl_bai}SpeedTest速度テストパネル"
	  echo -e "${gl_kjlan}17.  ${gl_bai}AdGuardhomeアドウェア${gl_kjlan}18.  ${gl_bai}唯一のオフィスオンラインオフィスオフィス"
	  echo -e "${gl_kjlan}19.  ${gl_bai}サンダープールWAFファイアウォールパネル${gl_kjlan}20.  ${gl_bai}Portainerコンテナ管理パネル"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}vscode webバージョン${gl_kjlan}22.  ${gl_bai}UptimeKuma監視ツール"
	  echo -e "${gl_kjlan}23.  ${gl_bai}メモWebページメモ${gl_kjlan}24.  ${gl_bai}webtopリモートデスクトップWebエディション${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${gl_bai}NextCloudネットワークディスク${gl_kjlan}26.  ${gl_bai}QD-Todayタイミングタスク管理フレームワーク"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Dockge Container Stack Managementパネル${gl_kjlan}28.  ${gl_bai}librespeed速度テストツール"
	  echo -e "${gl_kjlan}29.  ${gl_bai}searxng集約検索サイト${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${gl_bai}フォトプリズムプライベートアルバムシステム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}StirlingPDFツールコレクション${gl_kjlan}32.  ${gl_bai}Drawio無料のオンラインチャートソフトウェア${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}サンパネルナビゲーションパネル${gl_kjlan}34.  ${gl_bai}Pingvin-Shareファイル共有プラットフォーム"
	  echo -e "${gl_kjlan}35.  ${gl_bai}友達のミニマリストのサークル${gl_kjlan}36.  ${gl_bai}Lobechataiチャット集約Webサイト"
	  echo -e "${gl_kjlan}37.  ${gl_bai}MyIPツールボックス${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${gl_bai}Xiaoya alistファミリーバケット"
	  echo -e "${gl_kjlan}39.  ${gl_bai}Bililive Live Broadcast Recording Tool${gl_kjlan}40.  ${gl_bai}WebSH WebバージョンSSH接続ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}マウス管理パネル${gl_kjlan}42.  ${gl_bai}NEXTEリモート接続ツール"
	  echo -e "${gl_kjlan}43.  ${gl_bai}Rustdeskリモートデスク（サーバー）${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${gl_bai}Rustdeskリモートデスク（リレー）${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${gl_bai}Docker加速ステーション${gl_kjlan}46.  ${gl_bai}GitHubアクセラレーションステーション${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${gl_bai}プロメテウス監視${gl_kjlan}48.  ${gl_bai}プロメテウス（ホスト監視）"
	  echo -e "${gl_kjlan}49.  ${gl_bai}プロメテウス（コンテナ監視）${gl_kjlan}50.  ${gl_bai}補充監視ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}51.  ${gl_bai}PVEチキンパネル${gl_kjlan}52.  ${gl_bai}dPanelコンテナ管理パネル"
	  echo -e "${gl_kjlan}53.  ${gl_bai}llama3チャットAIモデル${gl_kjlan}54.  ${gl_bai}AMHホストWebサイトビルディングマネジメントパネル"
	  echo -e "${gl_kjlan}55.  ${gl_bai}FRPイントラネット浸透（サーバー側）${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${gl_bai}FRPイントラネット浸透（クライアント）${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${gl_bai}deepseekチャットaiビッグモデル${gl_kjlan}58.  ${gl_bai}Dify Big Model Knowledge Base${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${gl_bai}Newapi Big Model Asset Management${gl_kjlan}60.  ${gl_bai}Jumpserverオープンソースバス剤マシン"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${gl_bai}オンライン翻訳サーバー${gl_kjlan}62.  ${gl_bai}Ragflow Big Model Knowledge Base"
	  echo -e "${gl_kjlan}63.  ${gl_bai}OpenWebui自己ホストAIプラットフォーム${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${gl_bai}IT-Toolsツールボックス"
	  echo -e "${gl_kjlan}65.  ${gl_bai}N8Nオートメーションワークフロープラットフォーム${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${gl_bai}YT-DLPビデオダウンロードツール"
	  echo -e "${gl_kjlan}67.  ${gl_bai}DDNS-GOダイナミックDNS管理ツール${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${gl_bai}AllinsSL証明書管理プラットフォーム"
	  echo -e "${gl_kjlan}69.  ${gl_bai}SFTPGOファイル転送ツール${gl_kjlan}70.  ${gl_bai}アストロボットチャットロボットフレームワーク"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}71.  ${gl_bai}Navidromeプライベートミュージックサーバー${gl_kjlan}72.  ${gl_bai}Bitwardenパスワードマネージャー${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${gl_bai}libretvプライベート映画とテレビ${gl_kjlan}74.  ${gl_bai}MOONTVプライベート映画"
	  echo -e "${gl_kjlan}75.  ${gl_bai}メロディーミュージックエルフ${gl_kjlan}76.  ${gl_bai}オンラインDOS古いゲーム"
	  echo -e "${gl_kjlan}77.  ${gl_bai}サンダーオフラインダウンロードツール${gl_kjlan}78.  ${gl_bai}Pandawikiインテリジェントドキュメント管理システム"
	  echo -e "${gl_kjlan}79.  ${gl_bai}Beszelサーバーの監視"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

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
			send_stats "ネザを作る"
			local docker_name="nezha-dashboard"
			local docker_port=8008
			while true; do
				check_docker_app
				check_docker_image_update $docker_name
				clear
				echo -e "Nezhaの監視$check_docker $update_status"
				echo "オープンソース、軽量で使いやすいサーバーの監視と操作およびメンテナンスツール"
				echo "公式ウェブサイトの建設文書：https：//nezha.wiki/guide/dashboard.html"
				if docker inspect "$docker_name" &>/dev/null; then
					local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
					check_docker_app_ip
				fi
				echo ""
				echo "------------------------"
				echo "1。使用します"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "あなたの選択を入力してください：" choice

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
			send_stats "郵便局を建設します"
			clear
			install telnet
			local docker_name=“mailserver”
			while true; do
				check_docker_app
				check_docker_image_update $docker_name

				clear
				echo -e "郵便局サービス$check_docker $update_status"
				echo "Poste.ioはオープンソースメールサーバーソリューションです。"
				echo "ビデオの紹介：https：//www.bilibili.com/video/bv1wv421c71t?t=0.1"

				echo ""
				echo "ポート検出"
				port=25
				timeout=3
				if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
				  echo -e "${gl_lv}ポート$port現在利用可能です${gl_bai}"
				else
				  echo -e "${gl_hong}ポート$port現在利用できません${gl_bai}"
				fi
				echo ""

				if docker inspect "$docker_name" &>/dev/null; then
					yuming=$(cat /home/docker/mail.txt)
					echo "アクセスアドレス："
					echo "https://$yuming"
				fi

				echo "------------------------"
				echo "1。インストール2。更新3。アンインストール"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "あなたの選択を入力してください：" choice

				case $choice in
					1)
						check_disk_space 2
						read -e -p "たとえば、mail.yuming.comなど、電子メールドメイン名を設定してください。" yuming
						mkdir -p /home/docker
						echo "$yuming" > /home/docker/mail.txt
						echo "------------------------"
						ip_address
						echo "これらのDNSレコードを最初に解析します"
						echo "A           mail            $ipv4_address"
						echo "CNAME       imap            $yuming"
						echo "CNAME       pop             $yuming"
						echo "CNAME       smtp            $yuming"
						echo "MX          @               $yuming"
						echo "TXT         @               v=spf1 mx ~all"
						echo "TXT         ?               ?"
						echo ""
						echo "------------------------"
						echo "任意のキーを押して続行します..."
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
						echo "Poste.ioがインストールされています"
						echo "------------------------"
						echo "次のアドレスを使用してposte.ioにアクセスできます。"
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
						echo "Poste.ioがインストールされています"
						echo "------------------------"
						echo "次のアドレスを使用してposte.ioにアクセスできます。"
						echo "https://$yuming"
						echo ""
						;;
					3)
						docker rm -f mailserver
						docker rmi -f analogic/poste.io
						rm /home/docker/mail.txt
						rm -rf /home/docker/mail
						echo "アプリはアンインストールされています"
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
				echo "インストール"
				check_docker_app_ip
			}

			docker_app_update() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat:latest
				docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
				clear
				ip_address
				echo "Rocket.chatがインストールされています"
				check_docker_app_ip
			}

			docker_app_uninstall() {
				docker rm -f rocketchat
				docker rmi -f rocket.chat
				docker rm -f db
				docker rmi -f mongo:latest
				rm -rf /home/docker/mongo
				echo "アプリはアンインストールされています"
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
				echo "インストール"
				check_docker_app_ip
			}


			docker_app_update() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				cd /home/docker/cloud/ && docker compose up -d
			}


			docker_app_uninstall() {
				cd /home/docker/cloud/ && docker compose down --rmi all
				rm -rf /home/docker/cloud
				echo "アプリはアンインストールされています"
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
			send_stats "サンダープールを構築します"

			local docker_name=safeline-mgt
			local docker_port=9443
			while true; do
				check_docker_app
				clear
				echo -e "サンダープールサービス$check_docker"
				echo "Lei Chiは、Changting Technologyによって開発されたWAFサイトファイアウォールプログラムパネルであり、自動防衛のために代理店サイトを逆転させることができます。"
				echo "ビデオの紹介：https：//www.bilibili.com/video/bv1mz421t74c?t=0.1"
				if docker inspect "$docker_name" &>/dev/null; then
					check_docker_app_ip
				fi
				echo ""

				echo "------------------------"
				echo "1。インストール2。更新3。パスワードのリセット4。アンインストール"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "あなたの選択を入力してください：" choice

				case $choice in
					1)
						install_docker
						check_disk_space 5
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"
						clear
						echo "サンダープールWAFパネルがインストールされています"
						check_docker_app_ip
						docker exec safeline-mgt resetadmin

						;;

					2)
						bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
						docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
						echo ""
						clear
						echo "サンダープールWAFパネルが更新されました"
						check_docker_app_ip
						;;
					3)
						docker exec safeline-mgt resetadmin
						;;
					4)
						cd /data/safeline
						docker compose down --rmi all
						echo "デフォルトのインストールディレクトリである場合、プロジェクトはアンインストールされました。インストールディレクトリをカスタマイズする場合は、インストールディレクトリにアクセスして自分で実行する必要があります。"
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
			local docker_url="公式ウェブサイトの紹介：${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
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
			send_stats "Xiaoyaファミリーバケット"
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
				echo "インストール"
				check_docker_app_ip
				echo "最初のユーザー名とパスワードは次のとおりです"
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
				echo "アプリはアンインストールされています"
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
			send_stats "PVEチキン"
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
				echo "インストール"
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
				echo "アプリはアンインストールされています"
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
				echo "インストール"
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
				echo "インストール"
				check_docker_app_ip

			}

			docker_app_uninstall() {
				cd  /home/docker/new-api/ && docker compose down --rmi all
				rm -rf /home/docker/new-api
				echo "アプリはアンインストールされています"
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
				echo "インストール"
				check_docker_app_ip
				echo "初期ユーザー名：admin"
				echo "最初のパスワード：changeme"
			}


			docker_app_update() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh upgrade
				echo "アプリが更新されました"
			}


			docker_app_uninstall() {
				cd /opt/jumpserver-installer*/
				./jmsctl.sh uninstall
				cd /opt
				rm -rf jumpserver-installer*/
				rm -rf jumpserver
				echo "アプリはアンインストールされています"
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
				echo "インストール"
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
				echo "アプリはアンインストールされています"
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

				read -e -p "libretvログインパスワードを設定します。" app_passwd

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

				read -e -p "MOONTVログインパスワードを設定します。" app_passwd

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

				read -e -p "設定${docker_name}ログインユーザー名：" app_use
				read -e -p "設定${docker_name}ログインパスワード：" app_passwd

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
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done
}


linux_work() {

	while true; do
	  clear
	  send_stats "バックエンドワークスペース"
	  echo -e "バックエンドワークスペース"
	  echo -e "このシステムは、バックエンドで実行できるワークスペースを提供し、長期タスクを実行するために使用できます。"
	  echo -e "SSHを切断したとしても、ワークスペースのタスクは中断されず、バックグラウンドのタスクが居住します。"
	  echo -e "${gl_huang}ヒント：${gl_bai}ワークスペースに入った後、Ctrl+Bを使用してDを押してワークスペースを終了します！"
	  echo -e "${gl_kjlan}------------------------"
	  echo "現在既存のワークスペースのリスト"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ワークスペース番号1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}ワークスペースNo. 2"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ワークスペース番号3"
	  echo -e "${gl_kjlan}4.   ${gl_bai}ワークスペースNo. 4"
	  echo -e "${gl_kjlan}5.   ${gl_bai}ワークスペースNo. 5"
	  echo -e "${gl_kjlan}6.   ${gl_bai}ワークスペースNo. 6"
	  echo -e "${gl_kjlan}7.   ${gl_bai}ワークスペースNo. 7"
	  echo -e "${gl_kjlan}8.   ${gl_bai}ワークスペースNo. 8"
	  echo -e "${gl_kjlan}9.   ${gl_bai}ワークスペースNo. 9"
	  echo -e "${gl_kjlan}10.  ${gl_bai}ワークスペースNo. 10"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH常駐モード${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}ワークスペースを作成/入力します"
	  echo -e "${gl_kjlan}23.  ${gl_bai}バックグラウンドワークスペースにコマンドを注入します"
	  echo -e "${gl_kjlan}24.  ${gl_bai}指定されたワークスペースを削除します"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "ワークスペースを開始します$SESSION_NAME"
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
			  send_stats "SSH常駐モード"
			  echo -e "SSH常駐モード${tmux_sshd_status}"
			  echo "SSH接続が有効になった後、レジデントモードに直接入力し、以前の作業状態に戻ります。"
			  echo "------------------------"
			  echo "1。2をオンにします。オフにします"
			  echo "------------------------"
			  echo "0。前のメニューに戻ります"
			  echo "------------------------"
			  read -e -p "選択を入力してください：" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "ワークスペースを開始します$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\ n＃tmuxセッション\ nif [[-z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
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
			  read -e -p "1001 KJ001 Work1など、作成または入力したワークスペースの名前を入力してください。" SESSION_NAME
			  tmux_run
			  send_stats "カスタムワークスペース"
			  ;;


		  23)
			  read -e -p "次のようなバックグラウンドで実行するコマンドを入力してください：curl -fssl https://get.docker.com SH：" tmuxd
			  tmux_run_d
			  send_stats "バックグラウンドワークスペースにコマンドを注入します"
			  ;;

		  24)
			  read -e -p "削除するワークスペースの名前を入力してください：" gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "ワークスペースを削除します"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done


}












linux_Settings() {

	while true; do
	  clear
	  # send_stats "系统工具"
	  echo -e "システムツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}スクリプトの起動ショートカットキーを設定します${gl_kjlan}2.   ${gl_bai}ログインパスワードを変更します"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ルートパスワードログインモード${gl_kjlan}4.   ${gl_bai}指定されたバージョンのPythonをインストールします"
	  echo -e "${gl_kjlan}5.   ${gl_bai}すべてのポートを開きます${gl_kjlan}6.   ${gl_bai}SSH接続ポートを変更します"
	  echo -e "${gl_kjlan}7.   ${gl_bai}DNSアドレスを最適化します${gl_kjlan}8.   ${gl_bai}ワンクリック再インストールシステム${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}ルートアカウントを無効にして新しいアカウントを作成します${gl_kjlan}10.  ${gl_bai}優先順位IPv4/IPv6を切り替えます"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}ポートの職業ステータスを確認してください${gl_kjlan}12.  ${gl_bai}仮想メモリサイズを変更します"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ユーザー管理${gl_kjlan}14.  ${gl_bai}ユーザー/パスワードジェネレーター"
	  echo -e "${gl_kjlan}15.  ${gl_bai}システムタイムゾーンの調整${gl_kjlan}16.  ${gl_bai}BBR3加速度をセットアップします"
	  echo -e "${gl_kjlan}17.  ${gl_bai}ファイアウォール上級マネージャー${gl_kjlan}18.  ${gl_bai}ホスト名を変更します"
	  echo -e "${gl_kjlan}19.  ${gl_bai}システムの更新ソースを切り替えます${gl_kjlan}20.  ${gl_bai}タイミングタスク管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}ネイティブホストの解析${gl_kjlan}22.  ${gl_bai}SSH防衛プログラム"
	  echo -e "${gl_kjlan}23.  ${gl_bai}電流制限の自動シャットダウン${gl_kjlan}24.  ${gl_bai}ルート秘密キーログインモード"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TGボットシステムの監視と早期警告${gl_kjlan}26.  ${gl_bai}opensshの高リスクの脆弱性（xiuyuan）を修正"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat Linuxカーネルのアップグレード${gl_kjlan}28.  ${gl_bai}Linuxシステムにおけるカーネルパラメーターの最適化${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}ウイルススキャンツール${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}ファイルマネージャー"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}システム言語を切り替えます${gl_kjlan}32.  ${gl_bai}コマンドラインの美化ツール${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}システムリサイクルビンをセットアップします${gl_kjlan}34.  ${gl_bai}システムのバックアップと回復"
	  echo -e "${gl_kjlan}35.  ${gl_bai}SSHリモート接続ツール${gl_kjlan}36.  ${gl_bai}ハードディスクパーティション管理ツール"
	  echo -e "${gl_kjlan}37.  ${gl_bai}コマンドラインの履歴${gl_kjlan}38.  ${gl_bai}RSYNCリモート同期ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}メッセージボード${gl_kjlan}66.  ${gl_bai}ワンストップシステムの最適化${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}サーバーを再起動します${gl_kjlan}100. ${gl_bai}プライバシーとセキュリティ"
	  echo -e "${gl_kjlan}101. ${gl_bai}Kコマンドの高度な使用${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}テックライオンスクリプトをアンインストールします"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "ショートカットキーを入力してください（出口に0を入力してください）：" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  ln -s /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  echo "ショートカットキーが設定されています"
				  send_stats "スクリプトのショートカットキーが設定されています"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "ログインパスワードを設定します"
			  echo "ログインパスワードを設定します"
			  passwd
			  ;;
		  3)
			  root_use
			  send_stats "ルートパスワードモード"
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "Pyバージョン管理"
			echo "Pythonバージョン管理"
			echo "ビデオの紹介：https：//www.bilibili.com/video/bv1pm42157ck?t=0.1"
			echo "---------------------------------------"
			echo "この機能は、Pythonが正式にサポートするバージョンをシームレスにインストールします！"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "現在のPythonバージョン番号：${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "推奨バージョン：3.12 3.11 3.10 3.9 3.8 2.7"
			echo "クエリの詳細：https：//www.python.org/downloads/"
			echo "------------"
			read -e -p "インストールするPythonバージョン番号を入力します（Enter 0からExit）：" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "スクリプトPy管理"
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
					echo "不明なパッケージマネージャー！"
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
			echo -e "現在のPythonバージョン番号：${gl_huang}$VERSION${gl_bai}"
			send_stats "スイッチスクリプトPyバージョン"

			  ;;

		  5)
			  root_use
			  send_stats "オープンポート"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "すべてのポートが開いています"

			  ;;
		  6)
			root_use
			send_stats "SSHポートを変更します"

			while true; do
				clear
				sed -i 's/#Port/Port/' /etc/ssh/sshd_config

				# 現在のSSHポート番号をお読みください
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 現在のSSHポート番号を印刷します
				echo -e "現在のSSHポート番号は次のとおりです。${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "ポート番号が1〜65535の範囲の数字（0を入力して終了）"

				# ユーザーに新しいSSHポート番号を入力するように促します
				read -e -p "新しいSSHポート番号を入力してください：" new_port

				# ポート番号が有効な範囲内にあるかどうかを判断します
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSHポートが変更されました"
						new_ssh_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "SSHポート変更を終了します"
						break
					else
						echo "ポート番号は無効です。1〜65535の数字を入力してください。"
						send_stats "無効なSSHポート入力"
						break_end
					fi
				else
					echo "入力が無効です。番号を入力してください。"
					send_stats "無効なSSHポート入力"
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
			send_stats "新しいユーザーはルートを無効にします"
			read -e -p "新しいユーザー名を入力してください（出口に0を入力してください）：" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			useradd -m -s /bin/bash "$new_username"
			passwd "$new_username"

			echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

			passwd -l root

			echo "操作が完了しました。"
			;;


		  10)
			root_use
			send_stats "V4/V6の優先度を設定します"
			while true; do
				clear
				echo "V4/V6の優先度を設定します"
				echo "------------------------"
				local ipv6_disabled=$(sysctl -n net.ipv6.conf.all.disable_ipv6)

				if [ "$ipv6_disabled" -eq 1 ]; then
					echo -e "現在のネットワーク優先設定：${gl_huang}IPv4${gl_bai}優先度"
				else
					echo -e "現在のネットワーク優先設定：${gl_huang}IPv6${gl_bai}優先度"
				fi
				echo ""
				echo "------------------------"
				echo "1。IPv4優先度2。IPv6優先度3。IPv6修理ツール"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "優先ネットワークを選択します。" choice

				case $choice in
					1)
						sysctl -w net.ipv6.conf.all.disable_ipv6=1 > /dev/null 2>&1
						echo "IPv4の優先度に切り替えました"
						send_stats "IPv4の優先度に切り替えました"
						;;
					2)
						sysctl -w net.ipv6.conf.all.disable_ipv6=0 > /dev/null 2>&1
						echo "IPv6の優先度に切り替えました"
						send_stats "IPv6の優先度に切り替えました"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "この関数は、彼のおかげで、マスターJHBによって提供されます！"
						send_stats "IPv6修正"
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
			send_stats "仮想メモリを設定します"
			while true; do
				clear
				echo "仮想メモリを設定します"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "現在の仮想メモリ：${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1。1024Mの割り当て2。2048m3を割り当てます。4096m4。カスタムサイズを割り当てます"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "選択を入力してください：" choice

				case "$choice" in
				  1)
					send_stats "1G仮想メモリが設定されています"
					add_swap 1024

					;;
				  2)
					send_stats "2G仮想メモリが設定されています"
					add_swap 2048

					;;
				  3)
					send_stats "4G仮想メモリが設定されています"
					add_swap 4096

					;;

				  4)
					read -e -p "仮想メモリサイズ（ユニットM）を入力してください：" new_swap
					add_swap "$new_swap"
					send_stats "カスタム仮想メモリが設定されています"
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
				send_stats "ユーザー管理"
				echo "ユーザーリスト"
				echo "----------------------------------------------------------------------------"
				printf "%-24s %-34s %-20s %-10s\n" "用户名" "用户权限" "用户组" "sudo权限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status=$(sudo -n -lU "$username" 2>/dev/null | grep -q '(ALL : ALL)' && echo "Yes" || echo "No")
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "アカウント操作"
				  echo "------------------------"
				  echo "1.通常のアカウントを作成する2。プレミアムアカウントを作成します"
				  echo "------------------------"
				  echo "3.最高の権限を与える4。最高の権限をキャンセルします"
				  echo "------------------------"
				  echo "5.アカウントを削除します"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" sub_choice

				  case $sub_choice in
					  1)
					   # ユーザーに新しいユーザー名を入力するように求めます
					   read -e -p "新しいユーザー名を入力してください：" new_username

					   # 新しいユーザーを作成し、パスワードを設定します
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   echo "操作が完了しました。"
						  ;;

					  2)
					   # ユーザーに新しいユーザー名を入力するように求めます
					   read -e -p "新しいユーザー名を入力してください：" new_username

					   # 新しいユーザーを作成し、パスワードを設定します
					   useradd -m -s /bin/bash "$new_username"
					   passwd "$new_username"

					   # 新規ユーザーのsudo許可を付与します
					   echo "$new_username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers

					   echo "操作が完了しました。"

						  ;;
					  3)
					   read -e -p "ユーザー名を入力してください：" username
					   # 新規ユーザーのsudo許可を付与します
					   echo "$username ALL=(ALL:ALL) ALL" | tee -a /etc/sudoers
						  ;;
					  4)
					   read -e -p "ユーザー名を入力してください：" username
					   # sudoersファイルからユーザーのsudoアクセス許可を削除します
					   sed -i "/^$username\sALL=(ALL:ALL)\sALL/d" /etc/sudoers

						  ;;
					  5)
					   read -e -p "削除するにはユーザー名を入力してください：" username
					   # ユーザーとそのホームディレクトリを削除します
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
			send_stats "ユーザー情報ジェネレーター"
			echo "ランダムユーザー名"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "ランダムユーザー名$i: $username"
			done

			echo ""
			echo "ランダム名"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 5つのランダムユーザー名を生成します
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "ランダムなユーザー名$i: $user_name"
			done

			echo ""
			echo "ランダムuuid"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "ランダムuuid$i: $uuid"
			done

			echo ""
			echo "16ビットランダムパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "ランダムなパスワード$i: $password"
			done

			echo ""
			echo "32ビットランダムパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "ランダムなパスワード$i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "タイムゾーンを変更します"
			while true; do
				clear
				echo "システム時間情報"

				# 現在のシステムタイムゾーンを取得します
				local timezone=$(current_timezone)

				# 現在のシステム時間を取得します
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# タイムゾーンと時間を表示します
				echo "現在のシステムタイムゾーン：$timezone"
				echo "現在のシステム時間：$current_time"

				echo ""
				echo "タイムゾーンの切り替え"
				echo "------------------------"
				echo "アジア"
				echo "1。中国の上海時間2。中国の香港時間"
				echo "3。日本の東京時間4。韓国のソウル時間"
				echo "5。シンガポール時間6。インドのコルカタ時間"
				echo "7。アラブ首長国連邦のドバイ時間8。オーストラリアのシドニー時間"
				echo "9。タイのバンコクでの時間"
				echo "------------------------"
				echo "ヨーロッパ"
				echo "11。英国のロンドン時間12。パリの時間フランスの時間"
				echo "13。ベルリン時代、ドイツ14。モスクワ・タイム、ロシア"
				echo "15。オランダのユトレヒト時間16。スペインでのマドリード時間"
				echo "------------------------"
				echo "アメリカ"
				echo "21。WesternTime22。東部時間"
				echo "23。カナダ時間24。メキシコの時間"
				echo "25。ブラジル時間26。アルゼンチン時間"
				echo "------------------------"
				echo "31。UTCグローバル標準時間"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "選択を入力してください：" sub_choice


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
		  send_stats "ホスト名を変更します"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "現在のホスト名：${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "新しいホスト名を入力してください（出口に0を入力してください）：" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # Debian、Ubuntu、Centosなどの他のシステム。
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

				  echo "ホスト名は次のように変更されています。$new_hostname"
				  send_stats "ホスト名が変更されました"
				  sleep 1
			  else
				  echo "終了すると、ホスト名は変更されていません。"
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "システムの更新ソースを変更します"
		  clear
		  echo "更新ソース領域を選択します"
		  echo "LinuxMirrorsに接続して、システム更新ソースを切り替えます"
		  echo "------------------------"
		  echo "1。中国本土[デフォルト]2。中国本土[教育ネットワーク]3。海外地域"
		  echo "------------------------"
		  echo "0。前のメニューに戻ります"
		  echo "------------------------"
		  read -e -p "あなたの選択を入力してください：" choice

		  case $choice in
			  1)
				  send_stats "中国本土のデフォルトソース"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "中国本土の教育源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "海外起源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  *)
				  echo "キャンセル"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "タイミングタスク管理"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "タイミングされたタスクリスト"
				  crontab -l
				  echo ""
				  echo "動作します"
				  echo "------------------------"
				  echo "1.タイミングタスクの追加2。タイミングタスクを削除する3。タイミングタスクの編集"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "新しいタスクについては、実行コマンドを入力してください。" newquest
						  echo "------------------------"
						  echo "1。毎月のタスク2。毎週のタスク"
						  echo "3。毎日のタスク4。時間ごとのタスク"
						  echo "------------------------"
						  read -e -p "選択を入力してください：" dingshi

						  case $dingshi in
							  1)
								  read -e -p "毎月何日を選択してタスクを実行しますか？ （1-30）：" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "タスクを実行するためにどの週を選択しますか？ （0-6、0は日曜日を表します）：" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "毎日タスクを実行する時間を選択しますか？ （時間、0-23）：" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "タスクを実行するために時間の何時間を入力しますか？ （分、0-60）：" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "時限タスクを追加します"
						  ;;
					  2)
						  read -e -p "削除する必要があるキーワードを入力してください。" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "タイミングタスクを削除します"
						  ;;
					  3)
						  crontab -e
						  send_stats "タイミングタスクを編集します"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "ローカルホストの解析"
			  while true; do
				  clear
				  echo "ネイティブホストのペルシングリスト"
				  echo "ここに解析の一致を追加すると、動的な解析はもはや使用されなくなります"
				  cat /etc/hosts
				  echo ""
				  echo "動作します"
				  echo "------------------------"
				  echo "1.新しい解析2を追加します。解析アドレスを削除します"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" host_dns

				  case $host_dns in
					  1)
						  read -e -p "新しい解析レコード形式を入力してください：110.25.5.33 Kejilion.pro：" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "ローカルホストの解析が追加されました"

						  ;;
					  2)
						  read -e -p "削除する必要があるコンテンツの解析のキーワードを入力してください。" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "ローカルホストの解析と削除"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done
			  ;;

		  22)
		  root_use
		  send_stats "SSH防御"
		  while true; do
			if [ -x "$(command -v fail2ban-client)" ] ; then
				clear
				remove fail2ban
				rm -rf /etc/fail2ban
			else
				clear
				docker_name="fail2ban"
				check_docker_app
				echo -e "SSH防衛プログラム$check_docker"
				echo "Fail2banは、ブルートフォースを防ぐためのSSHツールです"
				echo "公式ウェブサイトの紹介：${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1.防衛プログラムをインストールします"
				echo "------------------------"
				echo "2。SSH傍受記録を表示します"
				echo "3。リアルタイムログ監視"
				echo "------------------------"
				echo "9.防衛プログラムをアンインストールします"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "選択を入力してください：" sub_choice
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
						echo "Fail2Ban防衛プログラムがアンインストールされています"
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
			send_stats "電流制限シャットダウン機能"
			while true; do
				clear
				echo "電流制限シャットダウン機能"
				echo "ビデオの紹介：https：//www.bilibili.com/video/bv1mc411j7qd?t=0.1"
				echo "------------------------------------------------"
				echo "現在のトラフィックの使用、サーバートラフィックの計算の再起動がクリアされます！"
				output_status
				echo -e "${gl_kjlan}合計受信：${gl_bai}$rx"
				echo -e "${gl_kjlan}合計送信：${gl_bai}$tx"

				# limiting_shut_down.shファイルが存在するかどうかを確認してください
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# threshold_gbの値を取得します
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}現在のセットエントリステーション電流制限しきい値は次のとおりです。${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}現在のアウトバウンド電流制限しきい値は次のとおりです。${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}現在の制限シャットダウン機能は有効になりません${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "システムは、実際のトラフィックが毎分でしきい値に達するかどうかを検出し、サーバーが到着した後にサーバーが自動的にシャットダウンされます！"
				echo "------------------------"
				echo "1。現在の制限シャットダウン関数をオンにします2。現在の制限シャットダウン機能を無効にします"
				echo "------------------------"
				echo "0。前のメニューに戻ります"
				echo "------------------------"
				read -e -p "選択を入力してください：" Limiting

				case "$Limiting" in
				  1)
					# 新しい仮想メモリサイズを入力します
					echo "実際のサーバーに100gのトラフィックがある場合、しきい値を95gに設定し、事前に電源をシャットダウンして、トラフィックエラーやオーバーフローを回避できます。"
					read -e -p "着信トラフィックのしきい値を入力してください（ユニットはG、デフォルトは100gです）：" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "アウトバウンドトラフィックのしきい値を入力してください（ユニットはG、デフォルトは100gです）：" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "トラフィックリセット日を入力してください（デフォルトのリセットは、毎月1日目にリセットされます）：" cz_day
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
					echo "現在の制限シャットダウンが設定されています"
					send_stats "現在の制限シャットダウンが設定されています"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "現在の制限シャットダウン関数はオフになっています"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)

			  root_use
			  send_stats "秘密キーログイン"
			  while true; do
				  clear
			  	  echo "ルート秘密キーログインモード"
			  	  echo "ビデオの紹介：https：//www.bilibili.com/video/bv1q4421x78n?t=209.4"
			  	  echo "------------------------------------------------"
			  	  echo "キーペアが生成され、SSHログインのより安全な方法"
				  echo "------------------------"
				  echo "1.新しいキーを生成する2。既存のキーをインポートする3。ネイティブキーを表示します"
				  echo "------------------------"
				  echo "0。前のメニューに戻ります"
				  echo "------------------------"
				  read -e -p "選択を入力してください：" host_dns

				  case $host_dns in
					  1)
				  		send_stats "新しいキーを生成します"
				  		add_sshkey
						break_end

						  ;;
					  2)
						send_stats "既存の公開キーをインポートします"
						import_sshkey
						break_end

						  ;;
					  3)
						send_stats "地元の秘密の鍵を表示します"
						echo "------------------------"
						echo "公開鍵情報"
						cat ~/.ssh/authorized_keys
						echo "------------------------"
						echo "秘密のキー情報"
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
			  send_stats "電報警告"
			  echo "TG-BOTモニタリングと早期警告機能"
			  echo "ビデオの紹介：https：//youtu.be/vll-eb3z_ty"
			  echo "------------------------------------------------"
			  echo "ネイティブCPU、メモリ、ハードディスク、トラフィック、およびSSHログインのリアルタイム監視と早期警告を実現するために、TG Robot APIとユーザーIDを構成する必要があります。"
			  echo "しきい値に達した後、ユーザーはユーザーに送信されます"
			  echo -e "${gl_hui}- トラフィックに関しては、サーバーの再起動が再計算されます -${gl_bai}"
			  read -e -p "必ず続行しますか？ （y/n）：" choice

			  case "$choice" in
				[Yy])
				  send_stats "電報警告が有効になっています"
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

				  # 〜/.Profileファイルに追加します
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "TG-BOT早期警告システムが開始されました"
				  echo -e "${gl_hui}他のマシンのルートディレクトリにTG-Check-notify.sh警告ファイルを配置して、直接使用することもできます。${gl_bai}"
				  ;;
				[Nn])
				  echo "キャンセル"
				  ;;
				*)
				  echo "無効な選択、yまたはnを入力してください。"
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "SSHの高リスクの脆弱性を修正します"
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
			  send_stats "コマンドラインの履歴"
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
			send_stats "メッセージボード"
			echo "テクノロジーライオンメッセージボードは公式コミュニティに移動されました！公式コミュニティにメッセージを残してください！"
			echo "https://bbs.kejilion.pro/"
			  ;;

		  66)

			  root_use
			  send_stats "ワンストップチューニング"
			  echo "ワンストップシステムの最適化"
			  echo "------------------------------------------------"
			  echo "以下が操作され、最適化されます"
			  echo "1.システムを最新の状態に更新します"
			  echo "2。システムジャンクファイルをクリーンアップします"
			  echo -e "3.仮想メモリを設定します${gl_huang}1G${gl_bai}"
			  echo -e "4. SSHポート番号をに設定します${gl_huang}5522${gl_bai}"
			  echo -e "5.すべてのポートを開きます"
			  echo -e "6。電源を入れます${gl_huang}BBR${gl_bai}加速します"
			  echo -e "7.タイムゾーンをに設定します${gl_huang}上海${gl_bai}"
			  echo -e "8。DNSアドレスを自動的に最適化します${gl_huang}海外：1.1.1.1 8.8.8.8国内：223.5.5.5${gl_bai}"
			  echo -e "9.基本ツールをインストールします${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "10。Linuxシステムのカーネルパラメーター最適化に切り替えます${gl_huang}バランスの取れた最適化モード${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "ワンクリックメンテナンスは必ずありますか？ （y/n）：" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "ワンストップチューニングスタート"
				  echo "------------------------------------------------"
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}] 1/10。システムを最新の状態に更新します"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}] 2/10。システムジャンクファイルをクリーンアップします"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}] 3/10。仮想メモリを設定します${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  local new_port=5522
				  new_ssh_port
				  echo -e "[${gl_lv}OK${gl_bai}] 4/10。 SSHポート番号をに設定します${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}] 5/10。すべてのポートを開きます"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}] 6/10。開ける${gl_huang}BBR${gl_bai}加速します"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}] 7/10。タイムゾーンをに設定します${gl_huang}上海${gl_bai}"

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
				  echo -e "[${gl_lv}OK${gl_bai}] 8/10。 DNSアドレスを自動的に最適化します${gl_huang}${gl_bai}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}] 9/10。基本ツールをインストールします${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  echo "------------------------------------------------"
				  optimize_balanced
				  echo -e "[${gl_lv}OK${gl_bai}] 10/10。 Linuxシステムのカーネルパラメーターの最適化"
				  echo -e "${gl_lv}ワンストップシステムのチューニングが完了しました${gl_bai}"

				  ;;
				[Nn])
				  echo "キャンセル"
				  ;;
				*)
				  echo "無効な選択、yまたはnを入力してください。"
				  ;;
			  esac

			  ;;

		  99)
			  clear
			  send_stats "システムを再起動します"
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

			  echo "プライバシーとセキュリティ"
			  echo "スクリプトは、ユーザー機能に関するデータを収集し、スクリプトエクスペリエンスを最適化し、より楽しく便利な機能を作成します。"
			  echo "スクリプトバージョン番号、使用時間、システムバージョン、CPUアーキテクチャ、マシンの国、および使用される関数の名前を収集します。"
			  echo "------------------------------------------------"
			  echo -e "現在のステータス：$status_message"
			  echo "--------------------"
			  echo "1。コレクションをオンにします"
			  echo "2。コレクションを閉じます"
			  echo "--------------------"
			  echo "0。前のメニューに戻ります"
			  echo "--------------------"
			  read -e -p "選択を入力してください：" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "コレクションが有効になっています"
					  send_stats "プライバシーとセキュリティコレクションが有効になっています"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "コレクションは閉じた"
					  send_stats "プライバシーとセキュリティは収集のために閉鎖されています"
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
			  send_stats "テックライオンスクリプトをアンインストールします"
			  echo "テックライオンスクリプトをアンインストールします"
			  echo "------------------------------------------------"
			  echo "Kejilionスクリプトを完全にアンインストールし、他の機能には影響しません"
			  read -e -p "必ず続行しますか？ （y/n）：" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "スクリプトはアンインストールされています、さようなら！"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "キャンセル"
				  ;;
				*)
				  echo "無効な選択、yまたはnを入力してください。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力！"
			  ;;
	  esac
	  break_end

	done



}






linux_file() {
	root_use
	send_stats "ファイルマネージャー"
	while true; do
		clear
		echo "ファイルマネージャー"
		echo "------------------------"
		echo "現在のパス"
		pwd
		echo "------------------------"
		ls --color=auto -x
		echo "------------------------"
		echo "1.ディレクトリ2を入力します。ディレクトリを作成3。ディレクトリアクセス許可を変更します。4。ディレクトリの名前を変更します"
		echo "5.ディレクトリを削除6。前のメニューディレクトリに戻ります"
		echo "------------------------"
		echo "11。ファイルを作成する12。ファイル13を編集します。ファイル許可を変更14。ファイルの名前を変更します"
		echo "15.ファイルを削除します"
		echo "------------------------"
		echo "21。ファイルディレクトリの圧縮22。UNZIPファイルディレクトリ23。ファイルディレクトリの移動24。ファイルディレクトリをコピーする"
		echo "25。ファイルを別のサーバーに渡します"
		echo "------------------------"
		echo "0。前のメニューに戻ります"
		echo "------------------------"
		read -e -p "選択を入力してください：" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "ディレクトリ名を入力してください：" dirname
				cd "$dirname" 2>/dev/null || echo "ディレクトリを入力できません"
				send_stats "ディレクトリに移動します"
				;;
			2)  # 创建目录
				read -e -p "作成するにはディレクトリ名を入力してください。" dirname
				mkdir -p "$dirname" && echo "作成されたディレクトリ" || echo "作成に失敗しました"
				send_stats "ディレクトリを作成します"
				;;
			3)  # 修改目录权限
				read -e -p "ディレクトリ名を入力してください：" dirname
				read -e -p "許可を入力してください（755など）：" perm
				chmod "$perm" "$dirname" && echo "許可が変更されました" || echo "変更に失敗しました"
				send_stats "ディレクトリ権限を変更します"
				;;
			4)  # 重命名目录
				read -e -p "現在のディレクトリ名を入力してください：" current_name
				read -e -p "新しいディレクトリ名を入力してください：" new_name
				mv "$current_name" "$new_name" && echo "ディレクトリの名前が変更されました" || echo "名前変更に失敗しました"
				send_stats "ディレクトリの名前を変更します"
				;;
			5)  # 删除目录
				read -e -p "削除するには、ディレクトリ名を入力してください。" dirname
				rm -rf "$dirname" && echo "ディレクトリが削除されました" || echo "削除が失敗しました"
				send_stats "ディレクトリを削除します"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "前のメニューディレクトリに戻ります"
				;;
			11) # 创建文件
				read -e -p "作成するにはファイル名を入力してください。" filename
				touch "$filename" && echo "作成されたファイル" || echo "作成に失敗しました"
				send_stats "ファイルを作成します"
				;;
			12) # 编辑文件
				read -e -p "編集するにはファイル名を入力してください：" filename
				install nano
				nano "$filename"
				send_stats "ファイルを編集します"
				;;
			13) # 修改文件权限
				read -e -p "ファイル名を入力してください：" filename
				read -e -p "許可を入力してください（755など）：" perm
				chmod "$perm" "$filename" && echo "許可が変更されました" || echo "変更に失敗しました"
				send_stats "ファイル権限を変更します"
				;;
			14) # 重命名文件
				read -e -p "現在のファイル名を入力してください：" current_name
				read -e -p "新しいファイル名を入力してください：" new_name
				mv "$current_name" "$new_name" && echo "名前の変更" || echo "名前変更に失敗しました"
				send_stats "ファイルの名前を変更します"
				;;
			15) # 删除文件
				read -e -p "削除するには、ファイル名を入力してください。" filename
				rm -f "$filename" && echo "削除されたファイル" || echo "削除が失敗しました"
				send_stats "ファイルを削除します"
				;;
			21) # 压缩文件/目录
				read -e -p "圧縮するには、ファイル/ディレクトリ名を入力してください。" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "圧縮$name.tar.gz" || echo "圧縮に失敗しました"
				send_stats "圧縮ファイル/ディレクトリ"
				;;
			22) # 解压文件/目录
				read -e -p "ファイル名（.tar.gz）を入力してください：" filename
				install tar
				tar -xzvf "$filename" && echo "減圧$filename" || echo "減圧が失敗しました"
				send_stats "ファイル/ディレクトリを解凍します"
				;;

			23) # 移动文件或目录
				read -e -p "移動するには、ファイルまたはディレクトリパスを入力してください。" src_path
				if [ ! -e "$src_path" ]; then
					echo "エラー：ファイルまたはディレクトリは存在しません。"
					send_stats "ファイルまたはディレクトリの移動に失敗しました：ファイルまたはディレクトリは存在しません"
					continue
				fi

				read -e -p "ターゲットパス（新しいファイル名またはディレクトリ名を含む）を入力してください。" dest_path
				if [ -z "$dest_path" ]; then
					echo "エラー：ターゲットパスを入力してください。"
					send_stats "ファイルまたはディレクトリの移動に失敗しました：宛先パスが指定されていません"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "ファイルまたはディレクトリが移動されました$dest_path" || echo "ファイルやディレクトリの移動に失敗しました"
				send_stats "ファイルまたはディレクトリを移動します"
				;;


		   24) # 复制文件目录
				read -e -p "コピーするには、ファイルまたはディレクトリパスを入力してください。" src_path
				if [ ! -e "$src_path" ]; then
					echo "エラー：ファイルまたはディレクトリは存在しません。"
					send_stats "ファイルまたはディレクトリのコピーに失敗しました：ファイルまたはディレクトリが存在しません"
					continue
				fi

				read -e -p "ターゲットパス（新しいファイル名またはディレクトリ名を含む）を入力してください。" dest_path
				if [ -z "$dest_path" ]; then
					echo "エラー：ターゲットパスを入力してください。"
					send_stats "ファイルまたはディレクトリのコピーに失敗しました：宛先パスが指定されていない"
					continue
				fi

				# -Rオプションを使用して、ディレクトリを再帰的にコピーします
				cp -r "$src_path" "$dest_path" && echo "ファイルまたはディレクトリがコピーされています$dest_path" || echo "ファイルまたはディレクトリのコピーに失敗しました"
				send_stats "ファイルまたはディレクトリをコピーします"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "転送されるファイルパスを入力してください。" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "エラー：ファイルは存在しません。"
					send_stats "ファイルの転送に失敗しました：ファイルは存在しません"
					continue
				fi

				read -e -p "リモートサーバーIPを入力してください：" remote_ip
				if [ -z "$remote_ip" ]; then
					echo "エラー：リモートサーバーIPを入力してください。"
					send_stats "ファイル転送に失敗しました：リモートサーバーIPは入力されませんでした"
					continue
				fi

				read -e -p "リモートサーバーのユーザー名（デフォルトルート）を入力してください。" remote_user
				remote_user=${remote_user:-root}

				read -e -p "リモートサーバーのパスワードを入力してください：" -s remote_password
				echo
				if [ -z "$remote_password" ]; then
					echo "エラー：リモートサーバーのパスワードを入力してください。"
					send_stats "ファイル転送の失敗：リモートサーバーパスワードが入力されていません"
					continue
				fi

				read -e -p "ログインポートを入力してください（デフォルト22）：" remote_port
				remote_port=${remote_port:-22}

				# 既知のホストの古いエントリをクリアします
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# SCPを使用してファイルを転送します
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "このファイルは、リモートサーバーホームディレクトリに転送されました。"
					send_stats "ファイル転送に正常に転送します"
				else
					echo "ファイル転送に失敗しました。"
					send_stats "ファイル転送に失敗しました"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "前のメニューメニューに戻ります"
				break
				;;
			*)  # 处理无效输入
				echo "選択の無効な、再入力してください"
				send_stats "無効な選択"
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

	# 抽出された情報を配列に変換します
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# サーバーを繰り返してコマンドを実行します
	for ((i=0; i<${#SERVER_ARRAY[@]}; i+=5)); do
		local name=${SERVER_ARRAY[i]}
		local hostname=${SERVER_ARRAY[i+1]}
		local port=${SERVER_ARRAY[i+2]}
		local username=${SERVER_ARRAY[i+3]}
		local password=${SERVER_ARRAY[i+4]}
		echo
		echo -e "${gl_huang}に接続します$name ($hostname)...${gl_bai}"
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
	  send_stats "クラスター制御センター"
	  echo "サーバークラスター制御"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}サーバーリスト管理${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}サーバーを追加します${gl_kjlan}2.  ${gl_bai}サーバーを削除します${gl_kjlan}3.  ${gl_bai}サーバーを編集します"
	  echo -e "${gl_kjlan}4.  ${gl_bai}バックアップクラスター${gl_kjlan}5.  ${gl_bai}クラスターを復元します"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}バッチでタスクを実行します${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}Tech Lionスクリプトをインストールします${gl_kjlan}12. ${gl_bai}システムを更新します${gl_kjlan}13. ${gl_bai}システムを掃除します"
	  echo -e "${gl_kjlan}14. ${gl_bai}Dockerをインストールします${gl_kjlan}15. ${gl_bai}BBR3をインストールします${gl_kjlan}16. ${gl_bai}1G仮想メモリをセットアップします"
	  echo -e "${gl_kjlan}17. ${gl_bai}タイムゾーンを上海に設定します${gl_kjlan}18. ${gl_bai}すべてのポートを開きます${gl_kjlan}51. ${gl_bai}カスタムコマンド"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}メインメニューに戻ります"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択を入力してください：" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "クラスターサーバーを追加します"
			  read -e -p "サーバー名：" server_name
			  read -e -p "サーバーIP：" server_ip
			  read -e -p "サーバーポート（22）：" server_port
			  local server_port=${server_port:-22}
			  read -e -p "サーバーユーザー名（root）：" server_username
			  local server_username=${server_username:-root}
			  read -e -p "サーバーユーザーパスワード：" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "クラスターサーバーを削除します"
			  read -e -p "削除する必要があるキーワードを入力してください。" rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "クラスターサーバーを編集します"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "バックアップクラスター"
			  echo -e "お願いします${gl_huang}/root/cluster/servers.py${gl_bai}ファイルをダウンロードして、バックアップに記入してください！"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "クラスターを復元します"
			  echo "Servers.pyをアップロードし、キーを押してアップロードを開始してください！"
			  echo -e "アップロードしてください${gl_huang}servers.py${gl_bai}にファイル${gl_huang}/root/cluster/${gl_bai}復元を完了してください！"
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
			  send_stats "コマンドの実行をカスタマイズします"
			  read -e -p "バッチ実行コマンドを入力してください：" mingling
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
send_stats "広告列"
echo "広告列"
echo "------------------------"
echo "これにより、ユーザーはよりシンプルでエレガントなプロモーションと購入エクスペリエンスを提供します！"
echo ""
echo -e "サーバーオファー"
echo "------------------------"
echo -e "${gl_lan}ライカ・クラウド香港CN2 GIA韓国デュアルISP US CN2 GIA割引${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//www.lcayun.com/aff/zexuqbim${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}Racknerd $ 10.99年間米国1コア1Gメモリ20gハードドライブ1tトラフィック${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 52.7ドル年間米国1コア4Gメモリ50Gハードドライブ4Tトラフィック${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=ga1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}ブリックワーカー、四半期あたり49ドル、米国CN2GIA、日本ソフトバンク、2つのコア、1Gメモリ、20gハードドライブ、1か月あたり1Tトラフィック${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//bandwagonhost.com/aff.php?aff = 69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}dmit四半期あたり28ドルUS CN2GIA 1コア2Gメモリ20Gハードドライブ800gトラフィック${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//www.dmit.io/aff.php?aff = 4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS月額6.9 $ 6.9東京ソフトバンク2コア1Gメモリ20gハードドライブ1Tトラフィック${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?faffid=1355 &? affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}より人気のあるVPSオファー${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "ドメイン名割引"
echo "------------------------"
echo -e "${gl_lan}GNAME 8.8ドルファースト年Comドメイン名6.68ドル1年目CCドメイン名${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https：//www.gname.com/register?tt=86836&ttcode=kejilion86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "周囲のテクノロジーライオン"
echo "------------------------"
echo -e "${gl_kjlan}Bステーション：${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}オイルパイプ：${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}公式ウェブサイト：${gl_bai}https://kejilion.pro/              ${gl_kjlan}ナビゲーション：${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}ブログ：ブログ${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}ソフトウェアセンター：${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}スクリプトの公式ウェブサイト：${gl_bai}https://kejilion.sh            ${gl_kjlan}githubアドレス：${gl_bai}https://github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}





kejilion_update() {

send_stats "スクリプトの更新"
cd ~
while true; do
	clear
	echo "ログを更新します"
	echo "------------------------"
	echo "すべてのログ：${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}あなたはすでに最新バージョンです！${gl_huang}v$sh_v${gl_bai}"
		send_stats "スクリプトは最新であり、更新は必要ありません"
	else
		echo "新しいバージョンを発見してください！"
		echo -e "現在のバージョンv$sh_v最新バージョン${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}自動更新が有効になり、スクリプトは毎日午前2時に自動的に更新されます！${gl_bai}"
	fi

	echo "------------------------"
	echo "1。今すぐ更新2。自動更新3をオンにしてください。オフの自動更新をオフにします"
	echo "------------------------"
	echo "0。メインメニューに戻ります"
	echo "------------------------"
	read -e -p "選択を入力してください：" choice
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
			echo -e "${gl_lv}スクリプトは最新バージョンに更新されました！${gl_huang}v$sh_v_new${gl_bai}"
			send_stats "スクリプトは最新です$sh_v_new"
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
			echo -e "${gl_lv}自動更新が有効になり、スクリプトは毎日午前2時に自動的に更新されます！${gl_bai}"
			send_stats "自動スクリプトの更新をオンにします"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}自動更新は閉じられています${gl_bai}"
			send_stats "スクリプト自動更新を閉じます"
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
echo -e "テクノロジーライオンスクリプトツールボックスv$sh_v"
echo -e "コマンドライン入力${gl_huang}k${gl_kjlan}スクリプトをすばやく開始します${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}システム情報クエリ"
echo -e "${gl_kjlan}2.   ${gl_bai}システムの更新"
echo -e "${gl_kjlan}3.   ${gl_bai}システムのクリーンアップ"
echo -e "${gl_kjlan}4.   ${gl_bai}基本的なツール"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR管理"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker管理"
echo -e "${gl_kjlan}7.   ${gl_bai}ワープ管理"
echo -e "${gl_kjlan}8.   ${gl_bai}テストスクリプトコレクション"
echo -e "${gl_kjlan}9.   ${gl_bai}Oracle Cloud Scriptコレクション"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP Webサイトビルディング"
echo -e "${gl_kjlan}11.  ${gl_bai}アプリケーション市場"
echo -e "${gl_kjlan}12.  ${gl_bai}バックエンドワークスペース"
echo -e "${gl_kjlan}13.  ${gl_bai}システムツール"
echo -e "${gl_kjlan}14.  ${gl_bai}サーバークラスター制御"
echo -e "${gl_kjlan}15.  ${gl_bai}広告列"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}p.   ${gl_bai}Phantom Beast Palu Serverオープニングスクリプト"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}スクリプトの更新"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}スクリプトを終了します"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "選択を入力してください：" choice

case $choice in
  1) linux_ps ;;
  2) clear ; send_stats "システムの更新" ; linux_update ;;
  3) clear ; send_stats "システムのクリーンアップ" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "ワープ管理" ; install wget
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
  p) send_stats "Phantom Beast Palu Serverオープニングスクリプト" ; cd ~
	 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
	 exit
	 ;;
  00) kejilion_update ;;
  0) clear ; exit ;;
  *) echo "無効な入力！" ;;
esac
	break_end
done
}


k_info() {
send_stats "Kコマンド参照ユースケース"
echo "-------------------"
echo "ビデオの紹介：https：//www.bilibili.com/video/bv1ib421e7it?t=0.1"
echo "以下は、Kコマンドリファレンスユースケースです。"
echo "スクリプトkを開始します"
echo "ソフトウェアパッケージkをインストールしますnano wgetをインストールします| k nano wgetを追加| K nano wgetをインストールします"
echo "パッケージのアンインストールk nano wgetを削除| k del nano wget | K UNINSTALLNANOWGET | K UNINSTALLNANO WGET"
echo "システムKアップデートを更新| Kアップデート"
echo "クリーンシステムガベージkクリーン| kきれい"
echo "システムパネルk dd |を再インストールしますk再インストール"
echo "BBR3コントロールパネルK BBR3 | K BBRV3"
echo "カーネルチューニングパネルk nhyh | Kカーネル最適化"
echo "仮想メモリkスワップ2048を設定します"
echo "仮想タイムゾーンKタイムアジア/上海|を設定しますKタイムゾーンアジア/上海"
echo "システムリサイクルビンKトラッシュ| K HSZ | Kリサイクルビン"
echo "システムバックアップ関数Kバックアップ| k bf | Kバックアップ"
echo "SSHリモート接続ツールK SSH | Kリモート接続"
echo "rsyncリモート同期ツールk rsync | Kリモート同期"
echo "ハードディスク管理ツールKディスク| Kハードディスク管理"
echo "イントラネット浸透（サーバー側）K FRP"
echo "イントラネット浸透（クライアント）K FRPC"
echo "ソフトウェアStart K Start SSHD | k sshdを開始します"
echo "ソフトウェアSTOP K STOP SSHD | k stop sshd"
echo "ソフトウェア再起動k再起動sshd | k再起動sshd"
echo "ソフトウェアステータスビューKステータスSSHD | KステータスSSHD"
echo "ソフトウェアブートk dockerを有効にする| K AutoStart Docke | Kスタートアップドッカー"
echo "ドメイン名証明書アプリケーションK SSL"
echo "ドメイン名証明書の有効期限クエリK SSL PS"
echo "Docker Environment Installation K Dockerインストール| K Dockerのインストール"
echo "Docker Container Management K Docker PS | K Dockerコンテナ"
echo "Docker Image Management K Docker IMG | K Docker画像"
echo "LDNMPサイト管理k Web"
echo "LDNMPキャッシュクリーンアップK Webキャッシュ"
echo "WordPress k wp | k wordpress | k wp xxx.comをインストールします"
echo "リバースプロキシk fd | k rp | k抗ジェネレーション| k fd xxx.comをインストールする"
echo "ロードバランスkロードバランス| kロードバランシングをインストールします"
echo "ファイアウォールパネルk fhq | kファイアウォール"
echo "オープンポートK DKDK 8080 | Kオープンポート8080"
echo "ポートK GBDK 7800を閉じる| kポート7800を閉じます"
echo "IP K FXIP 127.0.0.0/8 | KリリースIP 127.0.0.0/8をリリースします"
echo "ブロックIP K ZZIP 177.5.25.36 | KブロックIP 177.5.25.36"


}



if [ "$#" -eq 0 ]; then
	# パラメーターがない場合は、インタラクティブロジックを実行します
	kejilion_sh
else
	# パラメーターがある場合は、対応する関数を実行します
	case $1 in
		install|add|安装)
			shift
			send_stats "ソフトウェアをインストールします"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "ソフトウェアをアンインストールします"
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
			send_stats "タイム付きRSYNC同期"
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
			send_stats "仮想メモリをすばやく設定します"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "タイムゾーンをすばやく設定します"
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
			send_stats "ソフトウェアステータスビュー"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "ソフトウェアスタートアップ"
			start "$@"
			;;
		stop|停止)
			shift
			send_stats "ソフトウェアの一時停止"
			stop "$@"
			;;
		restart|重启)
			shift
			send_stats "ソフトウェアの再起動"
			restart "$@"
			;;

		enable|autostart|开机启动)
			shift
			send_stats "ソフトウェアが起動します"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "証明書のステータスを確認してください"
				ssl_ps
			elif [ -z "$1" ]; then
				add_ssl
				send_stats "すぐに証明書を申請してください"
			elif [ -n "$1" ]; then
				add_ssl "$1"
				send_stats "すぐに証明書を申請してください"
			else
				k_info
			fi
			;;

		docker)
			shift
			case $1 in
				install|安装)
					send_stats "Dockerをすばやくインストールします"
					install_docker
					;;
				ps|容器)
					send_stats "クイックコンテナ管理"
					docker_ps
					;;
				img|镜像)
					send_stats "クイックミラー管理"
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

