#!/bin/bash
sh_v="4.4.7"


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

gh_https_url="https://"

}
quanju_canshu



# コマンドを実行する関数を定義する
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



# この機能は、機能の埋め込み情報を収集し、現在のスクリプトのバージョン番号、使用時間、システム バージョン、CPU アーキテクチャ、マシンの国、およびユーザーが使用した機能名を記録します。機密情報は含まれませんので、ご安心ください。信じてください！
# なぜこの機能が設計されたのでしょうか?その目的は、ユーザーが使いたい機能をより深く理解し、機能をさらに最適化し、ユーザーのニーズを満たす機能をさらに投入することです。
# send_stats 関数の呼び出し位置を全文検索できます。これは透明性があり、オープンソースです。ご不安がある場合はご利用をお断りすることも可能です。



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
ln -sf /usr/local/bin/k /usr/bin/k > /dev/null 2>&1



CheckFirstRun_false() {
	if grep -q '^permission_granted="false"' /usr/local/bin/k > /dev/null 2>&1; then
		UserLicenseAgreement
	fi
}

# ユーザーに規約への同意を求めるプロンプトを表示する
UserLicenseAgreement() {
	clear
	echo -e "${gl_kjlan}テクノロジー ライオン スクリプト ツールボックスへようこそ${gl_bai}"
	echo "初めてスクリプトを使用する場合は、ユーザー使用許諾契約を読み、同意してください。"
	echo "ユーザー使用許諾契約書: https://blog.kejilion.pro/user-license-agreement/"
	echo -e "----------------------"
	read -e -p "上記の条件に同意しますか? (y/n):" user_input


	if [ "$user_input" = "y" ] || [ "$user_input" = "Y" ]; then
		send_stats "ライセンス契約"
		sed -i 's/^permission_granted="false"/permission_granted="true"/' ~/kejilion.sh
		sed -i 's/^permission_granted="false"/permission_granted="true"/' /usr/local/bin/k
	else
		send_stats "許可が拒否されました"
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


if echo "$isp_info" | grep -Eiq 'CHINANET|mobile|unicom|telecom'; then
  ipv4_address=$(get_local_ip)
else
  ipv4_address="$public_ip"
fi


# ipv4_address=$(curl -s https://ipinfo.io/ip && echo)
ipv6_address=$(curl -s --max-time 1 https://v6.ipinfo.io/ip && echo)

}



install() {
	if [ $# -eq 0 ]; then
		echo "パッケージパラメータが指定されていません!"
		return 1
	fi

	for package in "$@"; do
		if ! command -v "$package" &>/dev/null; then
			echo -e "${gl_kjlan}インストール中$package...${gl_bai}"
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
				echo "不明なパッケージマネージャーです!"
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
		echo -e "${gl_huang}ヒント：${gl_bai}ディスク容量が足りません!"
		echo "現在利用可能なスペース: $((available_space_mb/1024))G"
		echo "最低限必要なスペース:${required_gb}G"
		echo "インストールを続行できません。ディスク容量をクリアして、再試行してください。"
		send_stats "ディスク容量が足りない"
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
		echo "パッケージパラメータが指定されていません!"
		return 1
	fi

	for package in "$@"; do
		echo -e "${gl_kjlan}アンインストールする$package...${gl_bai}"
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
			echo "不明なパッケージマネージャーです!"
			return 1
		fi
	done
}


# さまざまなディストリビューションに適したユニバーサル systemctl 関数
systemctl() {
	local COMMAND="$1"
	local SERVICE_NAME="$2"

	if command -v apk &>/dev/null; then
		service "$SERVICE_NAME" "$COMMAND"
	else
		/bin/systemctl "$COMMAND" "$SERVICE_NAME"
	fi
}


# サービスを再起動する
restart() {
	systemctl restart "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスが再開されました。"
	else
		echo "エラー: 再起動$1サービスが失敗しました。"
	fi
}

# サービス開始
start() {
	systemctl start "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスが開始されました。"
	else
		echo "エラー: 開始$1サービスが失敗しました。"
	fi
}

# サービスを停止する
stop() {
	systemctl stop "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスが停止されました。"
	else
		echo "エラー: 停止$1サービスが失敗しました。"
	fi
}

# サービスステータスを確認する
status() {
	systemctl status "$1"
	if [ $? -eq 0 ]; then
		echo "$1サービスのステータスが表示されます。"
	else
		echo "エラー: 表示できません$1サービスのステータス。"
	fi
}


enable() {
	local SERVICE_NAME="$1"
	if command -v apk &>/dev/null; then
		rc-update add "$SERVICE_NAME" default
	else
	   /bin/systemctl enable "$SERVICE_NAME"
	fi

	echo "$SERVICE_NAME起動時に自動で起動するように設定してあります。"
}



break_end() {
	  echo -e "${gl_lv}操作が完了しました${gl_bai}"
	  echo "続行するには任意のキーを押してください..."
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
	echo -e "${gl_kjlan}Docker 環境をインストールしています...${gl_bai}"
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
	send_stats "Dockerコンテナ管理"
	echo "Dockerコンテナリスト"
	docker ps -a --format "table {{.ID}}\t{{.Names}}\t{{.Status}}\t{{.Ports}}"
	echo ""
	echo "コンテナの運用"
	echo "------------------------"
	echo "1. 新しいコンテナを作成する"
	echo "------------------------"
	echo "2. 指定したコンテナを起動します。 6. すべてのコンテナを起動します。"
	echo "3. 指定したコンテナを停止します。 7. すべてのコンテナを停止します。"
	echo "4. 指定したコンテナを削除します。 8. すべてのコンテナを削除します。"
	echo "5. 指定したコンテナを再起動します。 9. すべてのコンテナを再起動します。"
	echo "------------------------"
	echo "11. 指定したコンテナを入力します。 12. コンテナのログを表示します。"
	echo "13. コンテナネットワークを確認します。 14. コンテナ占有率を確認します。"
	echo "------------------------"
	echo "15. コンテナ ポート アクセスを有効にする 16. コンテナ ポート アクセスを閉じる"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択肢を入力してください:" sub_choice
	case $sub_choice in
		1)
			send_stats "新しいコンテナを作成する"
			read -e -p "作成コマンドを入力してください:" dockername
			$dockername
			;;
		2)
			send_stats "指定したコンテナを起動する"
			read -e -p "コンテナ名を入力してください (複数のコンテナ名はスペースで区切ってください):" dockername
			docker start $dockername
			;;
		3)
			send_stats "指定したコンテナを停止する"
			read -e -p "コンテナ名を入力してください (複数のコンテナ名はスペースで区切ってください):" dockername
			docker stop $dockername
			;;
		4)
			send_stats "指定したコンテナを削除します"
			read -e -p "コンテナ名を入力してください (複数のコンテナ名はスペースで区切ってください):" dockername
			docker rm -f $dockername
			;;
		5)
			send_stats "指定したコンテナを再起動します"
			read -e -p "コンテナ名を入力してください (複数のコンテナ名はスペースで区切ってください):" dockername
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
			send_stats "すべてのコンテナを削除する"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有容器吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rm -f $(docker ps -a -q)
				;;
			  [Nn])
				;;
			  *)
				echo "選択が無効です。Y または N を入力してください。"
				;;
			esac
			;;
		9)
			send_stats "すべてのコンテナを再起動します"
			docker restart $(docker ps -q)
			;;
		11)
			send_stats "コンテナに入る"
			read -e -p "コンテナ名を入力してください:" dockername
			docker exec -it $dockername /bin/sh
			break_end
			;;
		12)
			send_stats "コンテナログの表示"
			read -e -p "コンテナ名を入力してください:" dockername
			docker logs $dockername
			break_end
			;;
		13)
			send_stats "コンテナネットワークを表示する"
			echo ""
			container_ids=$(docker ps -q)
			echo "------------------------------------------------------------"
			printf "%-25s %-25s %-25s\n" "コンテナ名" "ネットワーク名" "IPアドレス"
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
			send_stats "コンテナ占有率の表示"
			docker stats --no-stream
			break_end
			;;

		15)
			send_stats "コンテナポートへのアクセスを許可する"
			read -e -p "コンテナ名を入力してください:" docker_name
			ip_address
			clear_container_rules "$docker_name" "$ipv4_address"
			local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
			check_docker_app_ip
			break_end
			;;

		16)
			send_stats "コンテナポートへのアクセスをブロックする"
			read -e -p "コンテナ名を入力してください:" docker_name
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
	send_stats "Dockerイメージ管理"
	echo "Dockerイメージリスト"
	docker image ls
	echo ""
	echo "ミラー操作"
	echo "------------------------"
	echo "1. 指定した画像を取得 3. 指定した画像を削除"
	echo "2. 指定した画像を更新 4. すべての画像を削除"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択肢を入力してください:" sub_choice
	case $sub_choice in
		1)
			send_stats "イメージをプルする"
			read -e -p "イメージ名を入力してください (複数のイメージ名はスペースで区切ってください):" imagenames
			for name in $imagenames; do
				echo -e "${gl_kjlan}画像の取得：$name${gl_bai}"
				docker pull $name
			done
			;;
		2)
			send_stats "画像を更新"
			read -e -p "イメージ名を入力してください (複数のイメージ名はスペースで区切ってください):" imagenames
			for name in $imagenames; do
				echo -e "${gl_kjlan}画像の更新:$name${gl_bai}"
				docker pull $name
			done
			;;
		3)
			send_stats "画像の削除"
			read -e -p "イメージ名を入力してください (複数のイメージ名はスペースで区切ってください):" imagenames
			for name in $imagenames; do
				docker rmi -f $name
			done
			;;
		4)
			send_stats "すべての画像を削除する"
			read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有镜像吗？(Y/N): ")" choice
			case "$choice" in
			  [Yy])
				docker rmi -f $(docker images -q)
				;;
			  [Nn])
				;;
			  *)
				echo "選択が無効です。Y または N を入力してください。"
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
				echo "サポートされていないディストリビューション:$ID"
				return
				;;
		esac
	else
		echo "オペレーティング システムを特定できません。"
		return
	fi

	echo -e "${gl_lv}crontab がインストールされており、cron サービスが実行されています。${gl_bai}"
}



docker_ipv6_on() {
	root_use
	install jq

	local CONFIG_FILE="/etc/docker/daemon.json"
	local REQUIRED_IPV6_CONFIG='{"ipv6": true, "fixed-cidr-v6": "2001:db8:1::/64"}'

	# 構成ファイルが存在するかどうかを確認し、存在しない場合はファイルを作成し、デフォルト設定を書き込みます
	if [ ! -f "$CONFIG_FILE" ]; then
		echo "$REQUIRED_IPV6_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
	else
		# jq を使用して構成ファイルの更新を処理する
		local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

		# 現在の構成にすでに ipv6 設定があるかどうかを確認します
		local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq '.ipv6 // false')

		# 構成を更新してIPv6を有効にする
		if [[ "$CURRENT_IPV6" == "false" ]]; then
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {ipv6: true, "fixed-cidr-v6": "2001:db8:1::/64"}')
		else
			UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq '. + {"fixed-cidr-v6": "2001:db8:1::/64"}')
		fi

		# 元の構成と新しい構成を比較する
		if [[ "$ORIGINAL_CONFIG" == "$UPDATED_CONFIG" ]]; then
			echo -e "${gl_huang}IPv6 アクセスは現在有効です${gl_bai}"
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

	# 設定ファイルが存在するかどうかを確認する
	if [ ! -f "$CONFIG_FILE" ]; then
		echo -e "${gl_hong}設定ファイルが存在しません${gl_bai}"
		return
	fi

	# 現在の構成を読み取る
	local ORIGINAL_CONFIG=$(<"$CONFIG_FILE")

	# jq を使用して構成ファイルの更新を処理する
	local UPDATED_CONFIG=$(echo "$ORIGINAL_CONFIG" | jq 'del(.["fixed-cidr-v6"]) | .ipv6 = false')

	# 現在のIPv6ステータスを確認する
	local CURRENT_IPV6=$(echo "$ORIGINAL_CONFIG" | jq -r '.ipv6 // false')

	# 元の構成と新しい構成を比較する
	if [[ "$CURRENT_IPV6" == "false" ]]; then
		echo -e "${gl_huang}IPv6アクセスは現在停止中です${gl_bai}"
	else
		echo "$UPDATED_CONFIG" | jq . > "$CONFIG_FILE"
		restart docker
		echo -e "${gl_huang}IPv6 アクセスが正常に終了しました${gl_bai}"
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
		echo "少なくとも 1 つのポート番号を入力してください"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 既存のシャットダウン ルールを削除する
		iptables -D INPUT -p tcp --dport $port -j DROP 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j DROP 2>/dev/null

		# オープンルールを追加
		if ! iptables -C INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j ACCEPT
		fi

		if ! iptables -C INPUT -p udp --dport $port -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j ACCEPT
			echo "ポートがオープンしました$port"
		fi
	done

	save_iptables_rules
	send_stats "ポートがオープンしました"
}


close_port() {
	local ports=($@)  # 将传入的参数转换为数组
	if [ ${#ports[@]} -eq 0 ]; then
		echo "少なくとも 1 つのポート番号を入力してください"
		return 1
	fi

	install iptables

	for port in "${ports[@]}"; do
		# 既存のオープンルールを削除する
		iptables -D INPUT -p tcp --dport $port -j ACCEPT 2>/dev/null
		iptables -D INPUT -p udp --dport $port -j ACCEPT 2>/dev/null

		# シャットダウンルールを追加する
		if ! iptables -C INPUT -p tcp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p tcp --dport $port -j DROP
		fi

		if ! iptables -C INPUT -p udp --dport $port -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -p udp --dport $port -j DROP
			echo "ポートが閉じられています$port"
		fi
	done

	# 既存のルール (存在する場合) を削除します。
	iptables -D INPUT -i lo -j ACCEPT 2>/dev/null
	iptables -D FORWARD -i lo -j ACCEPT 2>/dev/null

	# 最初のルールに新しいルールを挿入します
	iptables -I INPUT 1 -i lo -j ACCEPT
	iptables -I FORWARD 1 -i lo -j ACCEPT

	save_iptables_rules
	send_stats "ポートが閉じられています"
}


allow_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "少なくとも 1 つの IP アドレスまたは IP セグメントを入力してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 既存のブロック ルールを削除する
		iptables -D INPUT -s $ip -j DROP 2>/dev/null

		# 許可ルールを追加する
		if ! iptables -C INPUT -s $ip -j ACCEPT 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j ACCEPT
			echo "リリース済みIP$ip"
		fi
	done

	save_iptables_rules
	send_stats "リリース済みIP"
}

block_ip() {
	local ips=($@)  # 将传入的参数转换为数组
	if [ ${#ips[@]} -eq 0 ]; then
		echo "少なくとも 1 つの IP アドレスまたは IP セグメントを入力してください"
		return 1
	fi

	install iptables

	for ip in "${ips[@]}"; do
		# 既存の許可ルールを削除する
		iptables -D INPUT -s $ip -j ACCEPT 2>/dev/null

		# ブロックルールを追加する
		if ! iptables -C INPUT -s $ip -j DROP 2>/dev/null; then
			iptables -I INPUT 1 -s $ip -j DROP
			echo "IPがブロックされました$ip"
		fi
	done

	save_iptables_rules
	send_stats "IPがブロックされました"
}







enable_ddos_defense() {
	# DDoS 保護を有効にする
	iptables -A DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A DOCKER-USER -p tcp --syn -j DROP
	iptables -A DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A DOCKER-USER -p udp -j DROP
	iptables -A INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT
	iptables -A INPUT -p tcp --syn -j DROP
	iptables -A INPUT -p udp -m limit --limit 3000/s -j ACCEPT
	iptables -A INPUT -p udp -j DROP

	send_stats "DDoS 防御をオンにする"
}

# DDoS 防御をオフにする
disable_ddos_defense() {
	# DDoS 保護をオフにする
	iptables -D DOCKER-USER -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p tcp --syn -j DROP 2>/dev/null
	iptables -D DOCKER-USER -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D DOCKER-USER -p udp -j DROP 2>/dev/null
	iptables -D INPUT -p tcp --syn -m limit --limit 500/s --limit-burst 100 -j ACCEPT 2>/dev/null
	iptables -D INPUT -p tcp --syn -j DROP 2>/dev/null
	iptables -D INPUT -p udp -m limit --limit 3000/s -j ACCEPT 2>/dev/null
	iptables -D INPUT -p udp -j DROP 2>/dev/null

	send_stats "DDoS 防御をオフにする"
}





# 国内の知財ルールを管理する機能
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
					echo "エラー: ダウンロード$country_codeIPゾーンファイルが失敗しました"
					continue
				fi

				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"

				iptables -I INPUT -m set --match-set "$ipset_name" src -j DROP

				echo "正常にブロックされました$country_codeIPアドレス"
				rm "${country_code,,}.zone"
				;;

			allow)
				if ! ipset list "$ipset_name" &> /dev/null; then
					ipset create "$ipset_name" hash:net
				fi

				if ! wget -q "$download_url" -O "${country_code,,}.zone"; then
					echo "エラー: ダウンロード$country_codeIPゾーンファイルが失敗しました"
					continue
				fi

				ipset flush "$ipset_name"
				while IFS= read -r ip; do
					ipset add "$ipset_name" "$ip" 2>/dev/null
				done < "${country_code,,}.zone"


				iptables -P INPUT DROP
				iptables -A INPUT -m set --match-set "$ipset_name" src -j ACCEPT

				echo "正常に許可されました$country_codeIPアドレス"
				rm "${country_code,,}.zone"
				;;

			unblock)
				iptables -D INPUT -m set --match-set "$ipset_name" src -j DROP 2>/dev/null

				if ipset list "$ipset_name" &> /dev/null; then
					ipset destroy "$ipset_name"
				fi

				echo "正常に削除されました$country_codeIPアドレス制限"
				;;

			*)
				echo "使用法: manage_country_rules {block|allow|unblock} <country_code...>"
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
		  echo "高度なファイアウォール管理"
		  send_stats "高度なファイアウォール管理"
		  echo "------------------------"
		  iptables -L INPUT
		  echo ""
		  echo "ファイアウォール管理"
		  echo "------------------------"
		  echo "1. 指定されたポートをオープンします。 2. 指定されたポートを閉じます。"
		  echo "3. すべてのポートを開く 4. すべてのポートを閉じる"
		  echo "------------------------"
		  echo "5. IP ホワイトリスト 6. IP ブラックリスト"
		  echo "7. 指定したIPをクリアします"
		  echo "------------------------"
		  echo "11. PING を許可する 12. PING を無効にする"
		  echo "------------------------"
		  echo "13. DDOS 防御を開始します。 14. DDOS 防御をオフにします。"
		  echo "------------------------"
		  echo "15. 指定した国の IP をブロックする 16. 指定した国の IP のみを許可する"
		  echo "17. 指定国における知的財産制限を解除する"
		  echo "------------------------"
		  echo "0. 前のメニューに戻る"
		  echo "------------------------"
		  read -e -p "選択肢を入力してください:" sub_choice
		  case $sub_choice in
			  1)
				  read -e -p "開いているポート番号を入力してください:" o_port
				  open_port $o_port
				  send_stats "指定したポートを開く"
				  ;;
			  2)
				  read -e -p "閉じられたポート番号を入力してください:" c_port
				  close_port $c_port
				  send_stats "指定したポートを閉じる"
				  ;;
			  3)
				  # すべてのポートを開く
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
				  send_stats "すべてのポートを開く"
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
				  read -e -p "許可された IP または IP セグメントを入力してください:" o_ip
				  allow_ip $o_ip
				  ;;
			  6)
				  # IPブラックリスト
				  read -e -p "ブロックされた IP または IP 範囲を入力してください:" c_ip
				  block_ip $c_ip
				  ;;
			  7)
				  # 指定したIPをクリア
				  read -e -p "クリアされた IP を入力してください:" d_ip
				  iptables -D INPUT -s $d_ip -j ACCEPT 2>/dev/null
				  iptables -D INPUT -s $d_ip -j DROP 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "指定したIPをクリア"
				  ;;
			  11)
				  # PINGを許可する
				  iptables -A INPUT -p icmp --icmp-type echo-request -j ACCEPT
				  iptables -A OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "PINGを許可する"
				  ;;
			  12)
				  # PINGを無効にする
				  iptables -D INPUT -p icmp --icmp-type echo-request -j ACCEPT 2>/dev/null
				  iptables -D OUTPUT -p icmp --icmp-type echo-reply -j ACCEPT 2>/dev/null
				  iptables-save > /etc/iptables/rules.v4
				  send_stats "PINGを無効にする"
				  ;;
			  13)
				  enable_ddos_defense
				  ;;
			  14)
				  disable_ddos_defense
				  ;;

			  15)
				  read -e -p "ブロックされている国コードを入力してください (CN US JP のように、複数の国コードをスペースで区切ることができます):" country_code
				  manage_country_rules block $country_code
				  send_stats "国を許可する$country_codeIP"
				  ;;
			  16)
				  read -e -p "許可されている国コードを入力してください (CN US JP のように、複数の国コードをスペースで区切ることができます)。" country_code
				  manage_country_rules allow $country_code
				  send_stats "ブロック国$country_codeIP"
				  ;;

			  17)
				  read -e -p "クリアされた国コードを入力してください (CN US JP のように、複数の国コードをスペースで区切ることができます)。" country_code
				  manage_country_rules unblock $country_code
				  send_stats "澄んだ国$country_codeIP"
				  ;;

			  *)
				  break  # 跳出循环，退出菜单
				  ;;
		  esac
  done

}






add_swap() {
	local new_swap=$1  # 获取传入的参数

	# 現在のシステム内のすべてのスワップ パーティションを取得します
	local swap_partitions=$(grep -E '^/dev/' /proc/swaps | awk '{print $1}')

	# すべてのスワップ パーティションを走査して削除します
	for partition in $swap_partitions; do
		swapoff "$partition"
		wipefs -a "$partition"
		mkswap -f "$partition"
	done

	# /swapfile が使用されていないことを確認してください
	swapoff /swapfile

	# 古い /swapfile を削除する
	rm -f /swapfile

	# 新しいスワップ パーティションを作成する
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

	echo -e "仮想メモリのサイズは次のように調整されました。${gl_huang}${new_swap}${gl_bai}M"
}




check_swap() {

local swap_total=$(free -m | awk 'NR==3{print $2}')

# 仮想メモリを作成する必要があるかどうかを判断する
[ "$swap_total" -gt 0 ] || add_swap 1024


}









ldnmp_v() {

	  # nginxのバージョンを取得する
	  local nginx_version=$(docker exec nginx nginx -v 2>&1)
	  local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "nginx : ${gl_huang}v$nginx_version${gl_bai}"

	  # mysqlのバージョンを取得する
	  local dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
	  local mysql_version=$(docker exec mysql mysql -u root -p"$dbrootpasswd" -e "SELECT VERSION();" 2>/dev/null | tail -n 1)
	  echo -n -e "            mysql : ${gl_huang}v$mysql_version${gl_bai}"

	  # PHPのバージョンを取得する
	  local php_version=$(docker exec php php -v 2>/dev/null | grep -oP "PHP \K[0-9]+\.[0-9]+\.[0-9]+")
	  echo -n -e "            php : ${gl_huang}v$php_version${gl_bai}"

	  # Redis バージョンを取得する
	  local redis_version=$(docker exec redis redis-server -v 2>&1 | grep -oP "v=+\K[0-9]+\.[0-9]+")
	  echo -e "            redis : ${gl_huang}v$redis_version${gl_bai}"

	  echo "------------------------"
	  echo ""

}



install_ldnmp_conf() {

  # 必要なディレクトリとファイルを作成する
  cd /home && mkdir -p web/html web/mysql web/certs web/conf.d web/stream.d web/redis web/log/nginx web/letsencrypt && touch web/docker-compose.yml
  wget -O /home/web/nginx.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf
  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default10.conf

  default_server_ssl

  # docker-compose.yml ファイルをダウンロードして置き換えます
  wget -O /home/web/docker-compose.yml ${gh_proxy}raw.githubusercontent.com/kejilion/docker/main/LNMP-docker-compose-10.yml
  dbrootpasswd=$(openssl rand -base64 16) ; dbuse=$(openssl rand -hex 4) ; dbusepasswd=$(openssl rand -base64 8)

  # docker-compose.yml ファイル内で置き換えます
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
	# 国コードを取得します (CN、US など)。
	local country=$(curl -s ipinfo.io/country)

	# 国に基づいてDNSを設定する
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
echo "IPv4優先に切り替えました"
send_stats "IPv4優先に切り替えました"
}




install_ldnmp() {

	  update_docker_compose_with_db_creds

	  cd /home/web && docker compose up -d
	  sleep 1
  	  crontab -l 2>/dev/null | grep -v 'logrotate' | crontab -
  	  (crontab -l 2>/dev/null; echo '0 2 * * * docker exec nginx apk add logrotate && docker exec nginx logrotate -f /etc/logrotate.conf') | crontab -

	  fix_phpfpm_conf php
	  fix_phpfpm_conf php74

	  # mysqlのチューニング
	  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
	  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
	  rm -rf /home/custom_mysql_config.cnf



	  restart_ldnmp
	  sleep 2

	  clear
	  echo "LDNMP環境がインストールされている"
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
				docker run --rm -p 80:80 -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot certonly --standalone -d "$yuming" --email your@email.com --agree-tos --no-eff-email --force-renewal --key-type ecdsa
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
	echo -e "${gl_huang}$yuming秘密鍵情報${gl_bai}"
	cat /etc/letsencrypt/live/$yuming/privkey.pem
	echo ""
	echo -e "${gl_huang}証明書の保存パス${gl_bai}"
	echo "公開キー: /etc/letsencrypt/live/$yuming/fullchain.pem"
	echo "秘密鍵: /etc/letsencrypt/live/$yuming/privkey.pem"
	echo ""
}





add_ssl() {
echo -e "${gl_huang}SSL 証明書をすばやく申請し、有効期限が切れる前に自動的に更新します${gl_bai}"
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
	echo -e "${gl_huang}適用された証明書の有効期限ステータス${gl_bai}"
	echo "サイト情報 証明書の有効期限"
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
		send_stats "ドメイン名証明書の申請が成功しました"
	else
		send_stats "ドメイン名証明書の申請に失敗しました"
		echo -e "${gl_hong}知らせ：${gl_bai}証明書の申請に失敗しました。次の考えられる理由を確認して、再試行してください。"
		echo -e "1. ドメイン名のスペルが間違っています ➠ ドメイン名が正しく入力されているかどうかを確認してください"
		echo -e "2. DNS 解決の問題 ➠ ドメイン名がサーバー IP に正しく解決されていることを確認します。"
		echo -e "3. ネットワーク構成の問題 ➠ Cloudflare Warp などの仮想ネットワークを使用している場合は、一時的にシャットダウンしてください"
		echo -e "4. ファイアウォールの制限 ➠ ポート 80/443 が開いているかどうかを確認し、アクセス可能であることを確認します。"
		echo -e "5. アプリケーション数が制限を超えている ➠ Let's Encrypt には週制限あり (5 回/ドメイン名/週)"
		echo -e "6. 国内登録制限 ➠ 中国本土環境の場合は、ドメイン名が登録されているかをご確認ください。"
		echo "------------------------"
		echo "1. 再適用 2. 既存の証明書をインポート 0. 終了"
		echo "------------------------"
		read -e -p "選択肢を入力してください:" sub_choice
		case $sub_choice in
	  	  1)
	  	  	send_stats "再申請"
		  	echo "もう一度デプロイしてみてください$webname"
		  	add_yuming
		  	install_ssltls
		  	certs_status

	  		  ;;
	  	  2)
	  	  	send_stats "既存の証明書をインポートする"

			# ファイルパスを定義する
			local cert_file="/home/web/certs/${yuming}_cert.pem"
			local key_file="/home/web/certs/${yuming}_key.pem"

			mkdir -p /home/web/certs

			# 1. 証明書を入力します (ECC 証明書と RSA 証明書はどちらも BEGIN CERTIFICATE で始まります)
			echo "証明書 (CRT/PEM) の内容を貼り付けてください (Enter を 2 回押して終了します)。"
			local cert_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$cert_content" == *"-----BEGIN"* ]] && break
				cert_content+="${line}"$'\n'
			done

			# 2. 秘密キーを入力します (RSA、ECC、PKCS#8 と互換性があります)
			echo "証明書の秘密キー (Private Key) の内容を貼り付けてください (Enter を 2 回押して終了します)。"
			local key_content=""
			while IFS= read -r line; do
				[[ -z "$line" && "$key_content" == *"-----BEGIN"* ]] && break
				key_content+="${line}"$'\n'
			done

			# 3. インテリジェントな検証
			# 「BEGIN CERTIFICATE」と「PRIVATE KEY」を含めるだけで渡されます
			if [[ "$cert_content" == *"-----BEGIN CERTIFICATE-----"* && "$key_content" == *"PRIVATE KEY-----"* ]]; then
				echo -n "$cert_content" > "$cert_file"
				echo -n "$key_content" > "$key_file"

				chmod 644 "$cert_file"
				chmod 600 "$key_file"

				# 現在の証明書の種類を特定して表示します。
				if [[ "$key_content" == *"EC PRIVATE KEY"* ]]; then
					echo "ECC証明書が正常に保存されたことが検出されました。"
				else
					echo "RSA証明書が正常に保存されたことが検出されました。"
				fi
				auth_method="ssl_imported"
			else
				echo "エラー: 証明書または秘密キーの形式が無効です。"
				certs_status
			fi
	  		  ;;
	  	  *)
		  	  exit
	  		  ;;
		esac
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
	  echo -e "まず、ドメイン名をローカル IP に解決します。${gl_huang}$ipv4_address  $ipv6_address${gl_bai}"
	  read -e -p "IP または解決されたドメイン名を入力してください:" yuming
}


check_ip_and_get_access_port() {
	local yuming="$1"

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	if [[ "$yuming" =~ $ipv4_pattern || "$yuming" =~ $ipv6_pattern ]]; then
		read -e -p "デフォルトで 80 を使用するには、アクセス/リスニング ポートを入力し、Enter キーを押してください。" access_port
		access_port=${access_port:-80}
	fi
}



update_nginx_listen_port() {
	local yuming="$1"
	local access_port="$2"
	local conf="/home/web/conf.d/${yuming}.conf"

	# access_port が空の場合はスキップします
	[ -z "$access_port" ] && return 0

	# すべてのリッスン行を削除します
	sed -i '/^[[:space:]]*listen[[:space:]]\+/d' "$conf"

	# サーバー { の後に新しいリッスンを挿入します
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

  send_stats "更新する$ldnmp_pods"
  echo "更新する${ldnmp_pods}仕上げる"

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
  echo "ログイン情報:"
  echo "ユーザー名:$dbuse"
  echo "パスワード：$dbusepasswd"
  echo
  send_stats "起動する$ldnmp_pods"
}


cf_purge_cache() {
  local CONFIG_FILE="/home/web/config/cf-purge-cache.txt"
  local API_TOKEN
  local EMAIL
  local ZONE_IDS

  # 設定ファイルが存在するかどうかを確認する
  if [ -f "$CONFIG_FILE" ]; then
	# 構成ファイルから API_TOKEN とzone_idを読み取ります
	read API_TOKEN EMAIL ZONE_IDS < "$CONFIG_FILE"
	# ZONE_IDS を配列に変換する
	ZONE_IDS=($ZONE_IDS)
  else
	# キャッシュをクリアするかどうかをユーザーに確認する
	read -e -p "Cloudflareのキャッシュをクリアする必要がありますか? (y/n):" answer
	if [[ "$answer" == "y" ]]; then
	  echo "CF 情報は次の場所に保存されます。$CONFIG_FILECF 情報は後で変更できます。"
	  read -e -p "API_TOKEN を入力してください:" API_TOKEN
	  read -e -p "CF ユーザー名を入力してください:" EMAIL
	  read -e -p "zone_id を入力してください (複数の場合はスペースで区切ります):" -a ZONE_IDS

	  mkdir -p /home/web/config/
	  echo "$API_TOKEN $EMAIL ${ZONE_IDS[*]}" > "$CONFIG_FILE"
	fi
  fi

  # 各zone_idをループし、キャッシュクリアコマンドを実行します。
  for ZONE_ID in "${ZONE_IDS[@]}"; do
	echo "zone_id のキャッシュをクリアします:$ZONE_ID"
	curl -X POST "https://api.cloudflare.com/client/v4/zones/$ZONE_ID/purge_cache" \
	-H "X-Auth-Email: $EMAIL" \
	-H "X-Auth-Key: $API_TOKEN" \
	-H "Content-Type: application/json" \
	--data '{"purge_everything":true}'
  done

  echo "キャッシュクリアリクエストが送信されました。"
}



web_cache() {
  send_stats "サイトキャッシュをクリアする"
  cf_purge_cache
  cd /home/web && docker compose restart
}



web_del() {

	send_stats "サイトデータを削除する"
	yuming_list="${1:-}"
	if [ -z "$yuming_list" ]; then
		read -e -p "サイト データを削除するには、ドメイン名を入力してください (複数のドメイン名はスペースで区切ります)。" yuming_list
		if [[ -z "$yuming_list" ]]; then
			return
		fi
	fi

	for yuming in $yuming_list; do
		echo "ドメイン名が削除されています:$yuming"
		rm -r /home/web/html/$yuming > /dev/null 2>&1
		rm /home/web/conf.d/$yuming.conf > /dev/null 2>&1
		rm /home/web/certs/${yuming}_key.pem > /dev/null 2>&1
		rm /home/web/certs/${yuming}_cert.pem > /dev/null 2>&1

		# ドメイン名をデータベース名に変換する
		dbname=$(echo "$yuming" | sed -e 's/[^A-Za-z0-9]/_/g')
		dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')

		# エラーを避けるために、データベースを削除する前にデータベースが存在するかどうかを確認してください。
		echo "データベースを削除しています:$dbname"
		docker exec mysql mysql -u root -p"$dbrootpasswd" -e "DROP DATABASE ${dbname};" > /dev/null 2>&1
	done

	docker exec nginx nginx -s reload

}


nginx_waf() {
	local mode=$1

	if ! grep -q "kjlion/nginx:alpine" /home/web/docker-compose.yml; then
		wget -O /home/web/nginx.conf "${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/nginx10.conf"
	fi

	# モードパラメータに従ってWAFをオンにするかオフにするかを決定します。
	if [ "$mode" == "on" ]; then
		# WAF をオンにする: コメントを削除する
		sed -i 's|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity on;|\1modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	elif [ "$mode" == "off" ]; then
		# WAF をオフにする: コメントを追加する
		sed -i 's|^load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|# load_module /etc/nginx/modules/ngx_http_modsecurity_module.so;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity on;|\1# modsecurity on;|' /home/web/nginx.conf > /dev/null 2>&1
		sed -i 's|^\(\s*\)modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|\1# modsecurity_rules_file /etc/nginx/modsec/modsecurity.conf;|' /home/web/nginx.conf > /dev/null 2>&1
	else
		echo "無効な引数: 'on' または 'off' を使用してください"
		return 1
	fi

	# nginx イメージを確認し、それに応じて処理します
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
		waf_status="WAFがオンになっている"
	else
		waf_status=""
	fi
}


check_cf_mode() {
	if [ -f "/etc/fail2ban/action.d/cloudflare-docker.conf" ]; then
		CFmessage="cfモードがオンになっています"
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
	# 古い定義を削除する
	sed -i "/define(['\"]WP_MEMORY_LIMIT['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_MAX_MEMORY_LIMIT['\"].*/d" "$FILE"

	# 「Happy Publishing」を含む行の前に新しい定義を挿入します。
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
	# 古い定義を削除する
	sed -i "/define(['\"]WP_DEBUG['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_DISPLAY['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_DEBUG_LOG['\"].*/d" "$FILE"

	# 「Happy Publishing」を含む行の前に新しい定義を挿入します。
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
	# 古い定義を削除する
	sed -i "/define(['\"]WP_HOME['\"].*/d" "$FILE"
	sed -i "/define(['\"]WP_SITEURL['\"].*/d" "$FILE"

	# 挿入コンテンツの生成
	INSERT="
define('WP_HOME', '$HOME_URL');
define('WP_SITEURL', '$SITE_URL');
"

	# 「出版おめでとうございます」の前に挿入
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
		# Brotli をオンにする: コメントを削除する
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
		# ブロトリを閉じる: コメントを追加
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
		echo "無効な引数: 'on' または 'off' を使用してください"
		return 1
	fi

	# nginx イメージを確認し、それに応じて処理します
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
		# Zstd をオンにする: コメントを削除する
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
		# Zstdを閉じる: コメントを追加
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
		echo "無効な引数: 'on' または 'off' を使用してください"
		return 1
	fi

	# nginx イメージを確認し、それに応じて処理します
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
		echo "無効な引数: 'on' または 'off' を使用してください"
		return 1
	fi

	docker exec nginx nginx -s reload

}






web_security() {
	  send_stats "LDNMP環境防御"
	  while true; do
		check_f2b_status
		check_waf_status
		check_cf_mode
			  clear
			  echo -e "サーバー Web サイト防御プログラム${check_f2b_status}${gl_lv}${CFmessage}${waf_status}${gl_bai}"
			  echo "------------------------"
			  echo "1. 防御プログラムをインストールする"
			  echo "------------------------"
			  echo "5. SSH 傍受記録の表示 6. Web サイト傍受記録の表示"
			  echo "7. 防御ルールのリストを表示します。 8. リアルタイム監視のログを表示します。"
			  echo "------------------------"
			  echo "11. インターセプトパラメータを設定します。 12. ブロックされたすべての IP をクリアします。"
			  echo "------------------------"
			  echo "21. クラウドフレア モード 22. 高負荷時に 5 秒間のシールドを有効にする"
			  echo "------------------------"
			  echo "31. WAF をオンにする 32. WAF をオフにする"
			  echo "33. DDOS 防御をオンにする 34. DDOS 防御をオフにする"
			  echo "------------------------"
			  echo "9. 防御プログラムをアンインストールする"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択肢を入力してください:" sub_choice
			  case $sub_choice in
				  1)
					  f2b_install_sshd
					  cd /etc/fail2ban/filter.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/fail2ban-nginx-cc.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-418.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-deny.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-unauthorized.conf
					  wget ${gh_proxy}raw.githubusercontent.com/linuxserver/fail2ban-confs/master/filter.d/nginx-bad-request.conf

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
					  echo "Fail2Ban 防御プログラムがアンインストールされました"
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
					  send_stats "クラウドフレアモード"
					  echo "cf バックエンドの右上隅にある私のプロフィールに移動し、左側で API トークンを選択し、グローバル API キーを取得します。"
					  echo "https://dash.cloudflare.com/login"
					  read -e -p "CF の口座番号を入力してください:" cfuser
					  read -e -p "CF のグローバル API キーを入力します。" cftoken

					  wget -O /home/web/conf.d/default.conf ${gh_proxy}raw.githubusercontent.com/kejilion/nginx/main/default11.conf
					  docker exec nginx nginx -s reload

					  cd /etc/fail2ban/jail.d/
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/nginx-docker-cc.conf

					  cd /etc/fail2ban/action.d
					  curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/config/main/fail2ban/cloudflare-docker.conf

					  sed -i "s/kejilion@outlook.com/$cfuser/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  sed -i "s/APIKEY00000/$cftoken/g" /etc/fail2ban/action.d/cloudflare-docker.conf
					  f2b_status

					  echo "Cloudflare モードが設定されており、傍受記録は cf バックグラウンド、site-security-events で表示できます。"
					  ;;

				  22)
					  send_stats "高負荷により5秒シールドが可能"
					  echo -e "${gl_huang}Web サイトは 5 分ごとに自動的に検出します。高負荷を検出すると自動的にシールドが開き、低負荷を検出すると5秒間自動的にシールドが閉じます。${gl_bai}"
					  echo "--------------"
					  echo "CFパラメータを取得します。"
					  echo -e "cf バックエンドの右上隅にある私のプロフィールに移動し、左側で API トークンを選択して、${gl_huang}Global API Key${gl_bai}"
					  echo -e "cf バックエンド ドメイン名の概要ページの右下に移動して取得します。${gl_huang}エリアID${gl_bai}"
					  echo "https://dash.cloudflare.com/login"
					  echo "--------------"
					  read -e -p "CF の口座番号を入力してください:" cfuser
					  read -e -p "CF のグローバル API キーを入力します。" cftoken
					  read -e -p "CF にドメイン名のゾーン ID を入力します。" cfzonID

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
						  echo "高負荷自動シールド開放スクリプトを追加しました"
					  else
						  echo "自動シールド開放スクリプトはすでに存在するため、追加する必要はありません"
					  fi

					  ;;

				  31)
					  nginx_waf on
					  echo "サイトWAFが有効になっています"
					  send_stats "サイトWAFが有効になっています"
					  ;;

				  32)
				  	  nginx_waf off
					  echo "サイト WAF がダウンしています"
					  send_stats "サイト WAF がダウンしています"
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

	# MySQL 設定ファイルに 4096M が含まれているかどうかを確認する
	if docker exec "$MYSQL_CONTAINER" grep -q "4096M" "$MYSQL_CONF" 2>/dev/null; then
		mode_info="ハイパフォーマンスモード"
	else
		mode_info="標準モード"
	fi



}


check_nginx_compression() {

	local CONFIG_FILE="/home/web/nginx.conf"

	# zstd がオンでコメントが解除されているかどうかを確認します (行全体が zstd on で始まります)。
	if grep -qE '^\s*zstd\s+on;' "$CONFIG_FILE"; then
		zstd_status="zstd圧縮がオンになっています"
	else
		zstd_status=""
	fi

	# Brotli が有効になっていてコメントが解除されているかどうかを確認します
	if grep -qE '^\s*brotli\s+on;' "$CONFIG_FILE"; then
		br_status="br圧縮がオンになっています"
	else
		br_status=""
	fi

	# gzip が有効になっていてコメントが解除されているかどうかを確認します
	if grep -qE '^\s*gzip\s+on;' "$CONFIG_FILE"; then
		gzip_status="gzip圧縮がオンになっています"
	else
		gzip_status=""
	fi
}




web_optimization() {
		  while true; do
		  	  check_ldnmp_mode
			  check_nginx_compression
			  clear
			  send_stats "LDNMP環境の最適化"
			  echo -e "LDNMP環境の最適化${gl_lv}${mode_info}${gzip_status}${br_status}${zstd_status}${gl_bai}"
			  echo "------------------------"
			  echo "1.スタンダードモード 2.ハイパフォーマンスモード(2H4G以上推奨)"
			  echo "------------------------"
			  echo "3. gzip 圧縮をオンにする 4. gzip 圧縮をオフにする"
			  echo "5. br 圧縮をオンにする 6. br 圧縮をオフにする"
			  echo "7. zstd 圧縮をオンにする 8. zstd 圧縮をオフにする"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択肢を入力してください:" sub_choice
			  case $sub_choice in
				  1)
				  send_stats "サイト標準モード"

				  local cpu_cores=$(nproc)
				  local connections=$((1024 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf


				  # PHPのチューニング
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHPのチューニング
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www-1.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysqlのチューニング
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config-1.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf


				  cd /home/web && docker compose restart

				  optimize_balanced


				  echo "LDNMP環境は標準モードに設定されています"

					  ;;
				  2)
				  send_stats "サイトハイパフォーマンスモード"

				  # nginxのチューニング
				  local cpu_cores=$(nproc)
				  local connections=$((2048 * ${cpu_cores}))
				  sed -i "s/worker_processes.*/worker_processes ${cpu_cores};/" /home/web/nginx.conf
				  sed -i "s/worker_connections.*/worker_connections ${connections};/" /home/web/nginx.conf

				  # PHPのチューニング
				  wget -O /home/optimized_php.ini ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/optimized_php.ini
				  docker cp /home/optimized_php.ini php:/usr/local/etc/php/conf.d/optimized_php.ini
				  docker cp /home/optimized_php.ini php74:/usr/local/etc/php/conf.d/optimized_php.ini
				  rm -rf /home/optimized_php.ini

				  # PHPのチューニング
				  wget -O /home/www.conf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/www.conf
				  docker cp /home/www.conf php:/usr/local/etc/php-fpm.d/www.conf
				  docker cp /home/www.conf php74:/usr/local/etc/php-fpm.d/www.conf
				  rm -rf /home/www.conf

				  patch_wp_memory_limit 512M 512M
				  patch_wp_debug

				  fix_phpfpm_conf php
				  fix_phpfpm_conf php74

				  # mysqlのチューニング
				  wget -O /home/custom_mysql_config.cnf ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/custom_mysql_config.cnf
				  docker cp /home/custom_mysql_config.cnf mysql:/etc/mysql/conf.d/
				  rm -rf /home/custom_mysql_config.cnf

				  cd /home/web && docker compose restart

				  optimize_web_server

				  echo "LDNMP 環境が高パフォーマンス モードに設定されている"

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
		check_docker="${gl_lv}インストール済み${gl_bai}"
	else
		check_docker="${gl_hui}インストールされていません${gl_bai}"
	fi
}



# check_docker_app() {

# if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
# check_docker="${gl_lv} は ${gl_bai} をインストールしました"
# else
# check_docker="${gl_hui} がインストールされていません ${gl_bai}"
# fi

# }


check_docker_app_ip() {
echo "------------------------"
echo "訪問先住所:"
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

	# 1. 地域検査
	local country=$(curl -s --max-time 2 ipinfo.io/country)
	[[ "$country" == "CN" ]] && return

	# 2. ローカルミラー情報の取得
	local container_info=$(docker inspect --format='{{.Created}},{{.Config.Image}}' "$container_name" 2>/dev/null)
	[[ -z "$container_info" ]] && return

	local container_created=$(echo "$container_info" | cut -d',' -f1)
	local full_image_name=$(echo "$container_info" | cut -d',' -f2)
	local container_created_ts=$(date -d "$container_created" +%s 2>/dev/null)

	# 3. インテリジェントな配線判断
	if [[ "$full_image_name" == ghcr.io* ]]; then
		# --- シナリオ A: GitHub (ghcr.io) 上のミラー ---
		# ウェアハウスのパスを抽出します (例: ghcr.io/onexru/oneimg -> onexru/oneimg)
		local repo_path=$(echo "$full_image_name" | sed 's/ghcr.io\///' | cut -d':' -f1)
		# 注: ghcr.io の API は比較的複雑です。通常、最も早い方法は、GitHub リポジトリのリリースを確認することです。
		local api_url="https://api.github.com/repos/$repo_path/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	elif [[ "$full_image_name" == *"oneimg"* ]]; then
		# --- シナリオB：特別指定（Docker HubでもGitHub Releaseで判断したい） ---
		local api_url="https://api.github.com/repos/onexru/oneimg/releases/latest"
		local remote_date=$(curl -s "$api_url" | jq -r '.published_at' 2>/dev/null)

	else
		# --- シナリオ C: 標準 Docker ハブ ---
		local image_repo=${full_image_name%%:*}
		local image_tag=${full_image_name##*:}
		[[ "$image_repo" == "$image_tag" ]] && image_tag="latest"
		[[ "$image_repo" != */* ]] && image_repo="library/$image_repo"

		local api_url="https://hub.docker.com/v2/repositories/$image_repo/tags/$image_tag"
		local remote_date=$(curl -s "$api_url" | jq -r '.last_updated' 2>/dev/null)
	fi

	# 4. タイムスタンプの比較
	if [[ -n "$remote_date" && "$remote_date" != "null" ]]; then
		local remote_ts=$(date -d "$remote_date" +%s 2>/dev/null)
		if [[ $container_created_ts -lt $remote_ts ]]; then
			update_status="${gl_huang}新しいバージョンが見つかりました!${gl_bai}"
		fi
	fi
}







block_container_port() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# コンテナのIPアドレスを取得する
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 他のすべての IP をチェックしてブロックします
	if ! iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 指定したIPの確認と解放
	if ! iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワーク127.0.0.0/8を確認して許可します。
	if ! iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi



	# 他のすべての IP をチェックしてブロックします
	if ! iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -I DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 指定したIPの確認と解放
	if ! iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワーク127.0.0.0/8を確認して許可します。
	if ! iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi

	if ! iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -I DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ポートはサービスへのアクセスをブロックされています"
	save_iptables_rules
}




clear_container_rules() {
	local container_name_or_id=$1
	local allowed_ip=$2

	# コンテナのIPアドレスを取得する
	local container_ip=$(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{end}}' "$container_name_or_id")

	if [ -z "$container_ip" ]; then
		return 1
	fi

	install iptables


	# 他のすべての IP をブロックする明確なルール
	if iptables -C DOCKER-USER -p tcp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -d "$container_ip" -j DROP
	fi

	# 指定したIPを許可するルールをクリアします
	if iptables -C DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワーク 127.0.0.0/8 を許可するルールをクリアします
	if iptables -C DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p tcp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi





	# 他のすべての IP をブロックする明確なルール
	if iptables -C DOCKER-USER -p udp -d "$container_ip" -j DROP &>/dev/null; then
		iptables -D DOCKER-USER -p udp -d "$container_ip" -j DROP
	fi

	# 指定したIPを許可するルールをクリアします
	if iptables -C DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s "$allowed_ip" -d "$container_ip" -j ACCEPT
	fi

	# ローカルネットワーク 127.0.0.0/8 を許可するルールをクリアします
	if iptables -C DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -p udp -s 127.0.0.0/8 -d "$container_ip" -j ACCEPT
	fi


	if iptables -C DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT &>/dev/null; then
		iptables -D DOCKER-USER -m state --state ESTABLISHED,RELATED -d "$container_ip" -j ACCEPT
	fi


	echo "IP+ポートによるサービスへのアクセスが許可されました"
	save_iptables_rules
}






block_host_port() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "エラー: アクセスを許可するには、ポート番号と IP を入力してください。"
		echo "使用法: block_host_port <ポート番号> <許可された IP>"
		return 1
	fi

	install iptables


	# 他のすべての IP からのアクセスを拒否する
	if ! iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -j DROP
	fi

	# 指定したIPへのアクセスを許可する
	if ! iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# ローカルアクセスを許可する
	if ! iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi





	# 他のすべての IP からのアクセスを拒否する
	if ! iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -j DROP
	fi

	# 指定したIPへのアクセスを許可する
	if ! iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi

	# ローカルアクセスを許可する
	if ! iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -I INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 確立された接続と関連する接続のトラフィックを許可する
	if ! iptables -C INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT &>/dev/null; then
		iptables -I INPUT -m state --state ESTABLISHED,RELATED -j ACCEPT
	fi

	echo "IP+ポートはサービスへのアクセスをブロックされています"
	save_iptables_rules
}




clear_host_port_rules() {
	local port=$1
	local allowed_ip=$2

	if [[ -z "$port" || -z "$allowed_ip" ]]; then
		echo "エラー: アクセスを許可するには、ポート番号と IP を入力してください。"
		echo "使用法: clear_host_port_rules <ポート番号> <許可された IP>"
		return 1
	fi

	install iptables


	# 他のすべての IP からのアクセスをブロックするルールをクリアします
	if iptables -C INPUT -p tcp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -j DROP
	fi

	# ローカルアクセスを許可する明確なルール
	if iptables -C INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 指定したIPからのアクセスを許可する明確なルール
	if iptables -C INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p tcp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	# 他のすべての IP からのアクセスをブロックするルールをクリアします
	if iptables -C INPUT -p udp --dport "$port" -j DROP &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -j DROP
	fi

	# ローカルアクセスを許可する明確なルール
	if iptables -C INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s 127.0.0.0/8 -j ACCEPT
	fi

	# 指定したIPからのアクセスを許可する明確なルール
	if iptables -C INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT &>/dev/null; then
		iptables -D INPUT -p udp --dport "$port" -s "$allowed_ip" -j ACCEPT
	fi


	echo "IP+ポートによるサービスへのアクセスが許可されました"
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
	echo "1. インストール 2. アップデート 3. アンインストール"
	echo "------------------------"
	echo "5. ドメイン名アクセスを追加します。 6. ドメイン名アクセスを削除します。"
	echo "7. IP+ポートアクセスを許可します。 8. IP+ポートアクセスをブロックします。"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択肢を入力してください:" choice
	 case $choice in
		1)
			setup_docker_dir
			check_disk_space $app_size /home/docker
			while true; do
				read -e -p "アプリケーションの外部サービス ポートを入力し、Enter キーを押してデフォルトで使用します。${docker_port}ポート：" app_port
				local app_port=${app_port:-${docker_port}}

				if ss -tuln | grep -q ":$app_port "; then
					echo -e "${gl_hong}間違い：${gl_bai}ポート$app_portすでに占有されています。ポートを変更してください"
					send_stats "アプリケーションポートが占有されています"
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
			echo "$docker_nameインストール完了"
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

			add_app_id

			clear
			echo "$docker_nameインストール完了"
			check_docker_app_ip
			echo ""
			$docker_use
			$docker_passwd
			send_stats "更新する$docker_name"
			;;
		3)
			docker rm -f "$docker_name"
			docker rmi -f "$docker_img"
			rm -rf "/home/docker/$docker_name"
			rm -f /home/docker/${docker_name}_port.conf

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			echo "アプリがアンインストールされました"
			send_stats "アンインストールする$docker_name"
			;;

		5)
			echo "${docker_name}ドメイン名アクセス設定"
			send_stats "${docker_name}ドメイン名アクセス設定"
			add_yuming
			ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
			block_container_port "$docker_name" "$ipv4_address"
			;;

		6)
			echo "ドメイン名の形式 example.com (https:// なし)"
			web_del
			;;

		7)
			send_stats "IPアクセスを許可する${docker_name}"
			clear_container_rules "$docker_name" "$ipv4_address"
			;;

		8)
			send_stats "IPアクセスをブロックする${docker_name}"
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
		echo "1. インストール 2. アップデート 3. アンインストール"
		echo "------------------------"
		echo "5. ドメイン名アクセスを追加します。 6. ドメイン名アクセスを削除します。"
		echo "7. IP+ポートアクセスを許可します。 8. IP+ポートアクセスをブロックします。"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択内容を入力してください:" choice
		case $choice in
			1)
				setup_docker_dir
				check_disk_space $app_size /home/docker

				while true; do
					read -e -p "アプリケーションの外部サービス ポートを入力し、Enter キーを押してデフォルトで使用します。${docker_port}ポート：" app_port
					local app_port=${app_port:-${docker_port}}

					if ss -tuln | grep -q ":$app_port "; then
						echo -e "${gl_hong}間違い：${gl_bai}ポート$app_portすでに占有されています。ポートを変更してください"
						send_stats "アプリケーションポートが占有されています"
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
				send_stats "$app_nameインストール"
				;;

			2)
				docker_app_update
				add_app_id
				send_stats "$app_name更新する"
				;;

			3)
				docker_app_uninstall
				rm -f /home/docker/${docker_name}_port.conf

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				send_stats "$app_nameアンインストールする"
				;;

			5)
				echo "${docker_name}ドメイン名アクセス設定"
				send_stats "${docker_name}ドメイン名アクセス設定"
				add_yuming
				ldnmp_Proxy ${yuming} 127.0.0.1 ${docker_port}
				block_container_port "$docker_name" "$ipv4_address"

				;;
			6)
				echo "ドメイン名の形式 example.com (https:// なし)"
				web_del
				;;
			7)
				send_stats "IPアクセスを許可する${docker_name}"
				clear_container_rules "$docker_name" "$ipv4_address"
				;;
			8)
				send_stats "IPアクセスをブロックする${docker_name}"
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

# セッションが存在するかどうかを確認する機能
session_exists() {
  tmux has-session -t $1 2>/dev/null
}

# 存在しないセッション名が見つかるまでループします
while session_exists "$base_name-$tmuxd_ID"; do
  local tmuxd_ID=$((tmuxd_ID + 1))
done

# 新しい tmux セッションを作成する
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
		check_f2b_status="${gl_lv}インストール済み${gl_bai}"
	else
		check_f2b_status="${gl_hui}インストールされていません${gl_bai}"
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

# 基本パラメータ設定: 禁止期間 (bantime)、時間枠 (findtime)、再試行回数 (maxretry)
# 例証します:
# - /etc/fail2ban/jail.d/sshd.local への書き込みを優先します (デフォルトのjail設定を上書きし、アップグレード時に失われにくくなります)
# - Alpine で、jail 名が異なる場合でも、sshd.local と書き込みます。 Fail2Ban は、jail 名に従って一致します。
f2b_basic_config() {
	root_use
	install nano

	if ! command -v fail2ban-client >/dev/null 2>&1; then
		echo -e "${gl_hui}failed2ban-client が検出されません。まず、fail2ban をインストールしてください。${gl_bai}"
		return
	fi

	local jail_name="sshd"
	if grep -qi 'Alpine' /etc/issue 2>/dev/null; then
		# Alpine のデフォルトの刑務所は通常 sshd です。カスタム alpine-sshd ルールが検出された場合にのみ切り替えます
		if [ -f /etc/fail2ban/filter.d/alpine-sshd.conf ] || [ -f /etc/fail2ban/jail.d/alpine-ssh.conf ] || [ -f /etc/fail2ban/jail.d/alpine-sshd.local ]; then
			jail_name="alpine-sshd"
		fi
	fi

	echo "SSH ジェイルを構成しようとしています:$jail_name"
	read -e -p "Bantime 禁止時間 (秒/分/時間、3600 または 1 時間など) [デフォルトは 1 時間]:" bantime
	read -e -p "タイムウィンドウ findtime (秒/分/時間、例: 600 または 10 分) [デフォルトは 10 分]:" findtime
	read -e -p "再試行回数 maxretry (整数) [デフォルト 5]:" maxretry

	bantime=${bantime:-1h}
	findtime=${findtime:-10m}
	maxretry=${maxretry:-5}

	mkdir -p /etc/fail2ban/jail.d
	cat > /etc/fail2ban/jail.d/sshd.local <<EOF
[$jail_name]
# Managed by kejilion.sh
# Note: enable the jail so these parameters take effect
enabled = true
bantime = $bantime
findtime = $findtime
maxretry = $maxretry
EOF

	# Ensure a logfile exists for sshd jail on Debian/Ubuntu minimal images
	# (without it, fail2ban-server may refuse to start)
	if [ "$jail_name" = "sshd" ]; then
		if [ -f /etc/fail2ban/jail.d/sshd.local ]; then
			grep -qE '^\s*logpath\s*=' /etc/fail2ban/jail.d/sshd.local || echo 'logpath = /var/log/auth.log' >> /etc/fail2ban/jail.d/sshd.local
		fi
	fi

	echo -e "${gl_lv}設定が書き込まれました${gl_bai}: /etc/fail2ban/jail.d/sshd.local"
	fail2ban-client reload >/dev/null 2>&1 || true
	sleep 2
	fail2ban-client status $jail_name || true
}

# メイン構成/オーバーレイ構成エディター (nano) を直接開きます。
# /etc/fail2ban/jail.d/sshd.local を最初に編集し (より安全です)、存在しない場合は作成します
f2b_edit_config() {
	root_use
	install nano

	if [ ! -d /etc/fail2ban ]; then
		echo -e "${gl_hui}/etc/fail2ban が存在しません。まず、fail2ban をインストールしてください。${gl_bai}"
		return
	fi

	mkdir -p /etc/fail2ban/jail.d
	local cfg="/etc/fail2ban/jail.d/sshd.local"
	[ -f "$cfg" ] || printf "[sshd]\n# bantime/findtime/maxretry\n" > "$cfg"

	nano "$cfg"
	echo -e "${gl_lv}保存されました${gl_bai}、fail2ban をリロード中..."
	fail2ban-client reload >/dev/null 2>&1 || true
}



server_reboot() {

	read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}现在重启服务器吗？(Y/N): ")" rboot
	case "$rboot" in
	  [Yy])
		echo "再起動しました"
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
	send_stats "LDNMP環境を再インストールできません"
	echo -e "${gl_huang}ヒント：${gl_bai}ウェブサイト構築環境を導入しました。再度インストールする必要はありません。"
	break_end
	linux_ldnmp
   fi

}


ldnmp_install_all() {
cd ~
send_stats "LDNMP環境をインストールする"
root_use
clear
echo -e "${gl_huang}LDNMP環境がインストールされていません。 LDNMP 環境のインストールを開始します...${gl_bai}"
check_disk_space 3 /home
install_dependency
install_docker
install_certbot
install_ldnmp_conf
install_ldnmp

}


nginx_install_all() {
cd ~
send_stats "nginx環境をインストールする"
root_use
clear
echo -e "${gl_huang}nginx がインストールされていません。nginx 環境のインストールを開始してください...${gl_bai}"
install_dependency
install_docker
install_certbot
install_ldnmp_conf
nginx_upgrade
clear
local nginx_version=$(docker exec nginx nginx -v 2>&1)
local nginx_version=$(echo "$nginx_version" | grep -oP "nginx/\K[0-9]+\.[0-9]+\.[0-9]+")
echo "nginxがインストールされました"
echo -e "現在のバージョン:${gl_huang}v$nginx_version${gl_bai}"
echo ""

}




ldnmp_install_status() {

	if ! docker inspect "php" &>/dev/null; then
		send_stats "最初に LDNMP 環境をインストールしてください"
		ldnmp_install_all
	fi

}


nginx_install_status() {

	if ! docker inspect "nginx" &>/dev/null; then
		send_stats "まずnginx環境をインストールしてください"
		nginx_install_all
	fi

}




ldnmp_web_on() {
	  clear
	  echo "あなたの$webname建てられました！"
	  echo "https://$yuming"
	  echo "------------------------"
	  echo "$webnameインストール情報は次のとおりです。"

}

nginx_web_on() {
	clear

	local ipv4_pattern='^[0-9]+\.[0-9]+\.[0-9]+\.[0-9]+$'
	local ipv6_pattern='^(([0-9A-Fa-f]{1,4}:){1,7}:|([0-9A-Fa-f]{1,4}:){7,7}[0-9A-Fa-f]{1,4}|::1)$'

	echo "あなたの$webname建てられました！"

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
  send_stats "インストール$webname"
  echo "導入を開始する$webname"
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
	webname="リバースプロキシ IP+ポート"
	yuming="${1:-}"
	reverseproxy="${2:-}"
	port="${3:-}"

	send_stats "インストール$webname"
	echo "導入を開始する$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy" ]; then
		read -e -p "アンチジェネレーション IP を入力してください (Enter キーを押すとデフォルトでローカル IP 127.0.0.1 になります):" reverseproxy
		reverseproxy=${reverseproxy:-127.0.0.1}
	fi

	if [ -z "$port" ]; then
		read -e -p "アンチジェネレーションポートを入力してください:" port
	fi
	nginx_install_status


	install_ssltls
	certs_status

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

	sed -i "s/# 動的に追加/$upstream_servers/g" /home/web/conf.d/$yuming.conf
	sed -i '/remote_addr/d' /home/web/conf.d/$yuming.conf

	update_nginx_listen_port "$yuming" "$access_port"

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}



ldnmp_Proxy_backend() {
	clear
	webname="リバースプロキシ負荷分散"

	send_stats "インストール$webname"
	echo "導入を開始する$webname"
	if [ -z "$yuming" ]; then
		add_yuming
	fi

	check_ip_and_get_access_port "$yuming"

	if [ -z "$reverseproxy_port" ]; then
		read -e -p "複数のアンチジェネレーション IP + ポートをスペースで区切って入力してください (例: 127.0.0.1:3000 127.0.0.1:3002):" reverseproxy_port
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

	sed -i "s/# 動的に追加/$upstream_servers/g" /home/web/conf.d/$yuming.conf


	update_nginx_listen_port "$yuming" "$access_port"

	nginx_http_on
	docker exec nginx nginx -s reload
	nginx_web_on
}






list_stream_services() {

	STREAM_DIR="/home/web/stream.d"
	printf "%-25s %-18s %-25s %-20s\n" "サービス名" "通信タイプ" "ローカルアドレス" "バックエンドアドレス"

	if [ -z "$(ls -A "$STREAM_DIR")" ]; then
		return
	fi

	for conf in "$STREAM_DIR"/*; do
		# サービス名はファイル名を取得します
		service_name=$(basename "$conf" .conf)

		# 上流ブロックでサーバーのバックエンド IP:ポートを取得します。
		backend=$(grep -Po '(?<=server )[^;]+' "$conf" | head -n1)

		# リッスンポートの取得
		listen_port=$(grep -Po '(?<=listen )[^;]+' "$conf" | head -n1)

		# デフォルトのローカルIP
		ip_address
		local_ip="$ipv4_address"

		# ファイル名の接尾辞または内容から最初に判断して通信タイプを取得します
		if grep -qi 'udp;' "$conf"; then
			proto="udp"
		else
			proto="tcp"
		fi

		# スプライス リスニング IP:ポート
		local_addr="$local_ip:$listen_port"

		printf "%-22s %-14s %-21s %-20s\n" "$service_name" "$proto" "$local_addr" "$backend"
	done
}









stream_panel() {
	send_stats "ストリーム 4 層プロキシ"
	local app_id="104"
	local docker_name="nginx"

	while true; do
		clear
		check_docker_app
		check_docker_image_update $docker_name
		echo -e "ストリーム 4 層プロキシ転送ツール$check_docker $update_status"
		echo "NGINX Stream は NGINX の TCP/UDP プロキシ モジュールであり、高性能のトランスポート層トラフィック転送とロード バランシングを実現するために使用されます。"
		echo "------------------------"
		if [ -d "/home/web/stream.d" ]; then
			list_stream_services
		fi
		echo ""
		echo "------------------------"
		echo "1. インストール 2. アップデート 3. アンインストール"
		echo "------------------------"
		echo "4. 転送サービスの追加 5. 転送サービスの変更 6. 転送サービスの削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択内容を入力してください:" choice
		case $choice in
			1)
				nginx_install_status
				add_app_id
				send_stats "Stream 4 層エージェントのインストール"
				;;
			2)
				update_docker_compose_with_db_creds
				nginx_upgrade
				add_app_id
				send_stats "ストリームの 4 層プロキシを更新します"
				;;
			3)
				read -e -p "nginx コンテナを削除してもよろしいですか?これはウェブサイトの機能に影響を与える可能性があります。 (y/N):" confirm
				if [[ "$confirm" =~ ^[Yy]$ ]]; then
					docker rm -f nginx
					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					send_stats "ストリームの 4 層プロキシを更新します"
					echo "nginxコンテナは削除されました。"
				else
					echo "操作はキャンセルされました。"
				fi

				;;

			4)
				ldnmp_Proxy_backend_stream
				add_app_id
				send_stats "レイヤー 4 プロキシを追加する"
				;;
			5)
				send_stats "転送設定の編集"
				read -e -p "編集するサービス名を入力してください:" stream_name
				install nano
				nano /home/web/stream.d/$stream_name.conf
				docker restart nginx
				send_stats "レイヤ 4 プロキシを変更する"
				;;
			6)
				send_stats "転送設定の削除"
				read -e -p "削除するサービス名を入力してください:" stream_name
				rm /home/web/stream.d/$stream_name.conf > /dev/null 2>&1
				docker restart nginx
				send_stats "レイヤ 4 プロキシを削除する"
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
	webname="ストリーム 4 層プロキシ負荷分散"

	send_stats "インストール$webname"
	echo "導入を開始する$webname"

	# エージェント名を取得する
	read -erp "プロキシ転送名を入力してください (例: mysql_proxy):" proxy_name
	if [ -z "$proxy_name" ]; then
		echo "名前を空にすることはできません"; return 1
	fi

	# リスニングポートの取得
	read -erp "ローカルのリスニング ポート (3306 など) を入力してください。" listen_port
	if ! [[ "$listen_port" =~ ^[0-9]+$ ]]; then
		echo "ポートは数値である必要があります"; return 1
	fi

	echo "契約の種類を選択してください:"
	echo "1. TCP    2. UDP"
	read -erp "シリアル番号を入力してください [1-2]:" proto_choice

	case "$proto_choice" in
		1) proto="tcp"; listen_suffix="" ;;
		2) proto="udp"; listen_suffix=" udp" ;;
		*) echo "無効な選択"; return 1 ;;
	esac

	read -e -p "1 つ以上のバックエンド IP + ポートをスペースで区切って入力してください (例: 10.13.0.2:3306 10.13.0.3:3306)。" reverseproxy_port

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

	sed -i "s/# 動的に追加/$upstream_servers/g" /home/web/stream.d/$proxy_name.conf

	docker exec nginx nginx -s reload
	clear
	echo "あなたの$webname建てられました！"
	echo "------------------------"
	echo "訪問先住所:"
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
		send_stats "LDNMP サイト管理"
		echo "LDNMP環境"
		echo "------------------------"
		ldnmp_v

		echo -e "サイト：${output}証明書の有効期限"
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
		echo -e "データベース:${db_output}"
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
		echo "操作する"
		echo "------------------------"
		echo "1. ドメイン名証明書の適用/更新 2. サイトのドメイン名の複製"
		echo "3. サイトのキャッシュをクリアします。 4. 関連するサイトを作成します。"
		echo "5. アクセスログの表示 6. エラーログの表示"
		echo "7. グローバル構成の編集 8. サイト構成の編集"
		echo "9. サイトデータベースの管理 10. サイト分析レポートの表示"
		echo "------------------------"
		echo "20. 指定したサイトデータを削除する"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択肢を入力してください:" sub_choice
		case $sub_choice in
			1)
				send_stats "ドメイン名証明書を申請する"
				read -e -p "ドメイン名を入力してください:" yuming
				install_certbot
				docker run --rm -v /etc/letsencrypt/:/etc/letsencrypt certbot/certbot delete --cert-name "$yuming" -n 2>/dev/null
				install_ssltls
				certs_status

				;;

			2)
				send_stats "クローンサイトのドメイン名"
				read -e -p "古いドメイン名を入力してください:" oddyuming
				read -e -p "新しいドメイン名を入力してください:" yuming
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

				# Web サイトのディレクトリの置き換え
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
				send_stats "関連サイトの作成"
				echo -e "新しいドメイン名を既存のサイトに関連付けてアクセスする"
				read -e -p "既存のドメイン名を入力してください:" oddyuming
				read -e -p "新しいドメイン名を入力してください:" yuming
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
				send_stats "アクセスログを見る"
				tail -n 200 /home/web/log/nginx/access.log
				break_end
				;;
			6)
				send_stats "エラーログを表示する"
				tail -n 200 /home/web/log/nginx/error.log
				break_end
				;;
			7)
				send_stats "グローバル構成の編集"
				install nano
				nano /home/web/nginx.conf
				docker exec nginx nginx -s reload
				;;

			8)
				send_stats "サイト構成を編集する"
				read -e -p "サイト設定を編集するには、編集するドメイン名を入力してください:" yuming
				install nano
				nano /home/web/conf.d/$yuming.conf
				docker exec nginx nginx -s reload
				;;
			9)
				phpmyadmin_upgrade
				break_end
				;;
			10)
				send_stats "サイトデータの表示"
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
	check_panel="${gl_lv}インストール済み${gl_bai}"
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
	echo "${panelname}人気の強力な運用保守管理盤です。"
	echo "公式サイト紹介：$panelurl "

	echo ""
	echo "------------------------"
	echo "1. インストール 2. 管理 3. アンインストール"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択肢を入力してください:" choice
	 case $choice in
		1)
			check_disk_space 1
			install wget
			iptables_open
			panel_app_install

			add_app_id
			send_stats "${panelname}インストール"
			;;
		2)
			panel_app_manage

			add_app_id
			send_stats "${panelname}コントロール"

			;;
		3)
			panel_app_uninstall

			sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
			send_stats "${panelname}アンインストールする"
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
	check_frp="${gl_lv}インストール済み${gl_bai}"
else
	check_frp="${gl_hui}インストールされていません${gl_bai}"
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

	send_stats "FRPサーバーをインストールする"
	# ランダムなポートと認証情報を生成する
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

	# 生成された情報を出力する
	ip_address
	echo "------------------------"
	echo "クライアントの展開に必要なパラメータ"
	echo "サービスIP:$ipv4_address"
	echo "token: $token"
	echo
	echo "FRPパネル情報"
	echo "FRPパネルアドレス：http://$ipv4_address:$dashboard_port"
	echo "FRP パネルのユーザー名:$dashboard_user"
	echo "FRPパネルのパスワード：$dashboard_pwd"
	echo

	open_port 8055 8056

}



configure_frpc() {
	send_stats "FRPクライアントをインストールする"
	read -e -p "外部ネットワークのドッキング IP を入力してください:" server_addr
	read -e -p "外部ネットワーク ドッキング トークンを入力してください:" token
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
	send_stats "FRPイントラネットサービスを追加"
	# ユーザーにサービス名と転送情報の入力を求めるプロンプトを表示します
	read -e -p "サービス名を入力してください:" service_name
	read -e -p "転送タイプ (tcp/udp) を入力してください [デフォルトで tcp を入力する]:" service_type
	local service_type=${service_type:-tcp}
	read -e -p "イントラネット IP を入力してください [Enter キーを押すときのデフォルトは 127.0.0.1]:" local_ip
	local local_ip=${local_ip:-127.0.0.1}
	read -e -p "イントラネット ポートを入力してください:" local_port
	read -e -p "外部ネットワーク ポートを入力してください:" remote_port

	# ユーザー入力を構成ファイルに書き込む
	cat <<EOF >> /home/frp/frpc.toml
[$service_name]
type = ${service_type}
local_ip = ${local_ip}
local_port = ${local_port}
remote_port = ${remote_port}

EOF

	# 生成された情報を出力する
	echo "仕える$service_namefrpc.toml に正常に追加されました"

	docker restart frpc

	open_port $local_port

}



delete_forwarding_service() {
	send_stats "FRPイントラネットサービスの削除"
	# 削除する必要があるサービスの名前を入力するようにユーザーに求めます
	read -e -p "削除するサービス名を入力してください:" service_name
	# sed を使用してサービスとその関連構成を削除します
	sed -i "/\[$service_name\]/,/^$/d" /home/frp/frpc.toml
	echo "仕える$service_namefrpc.toml から正常に削除されました"

	docker restart frpc

}


list_forwarding_services() {
	local config_file="$1"

	# ヘッダーを印刷します
	printf "%-20s %-25s %-30s %-10s\n" "サービス名" "イントラネットアドレス" "外部ネットワークアドレス" "プロトコル"

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
		# サービス情報がすでに存在する場合は、新しいサービスを処理する前に現在のサービスを出力します。
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
			# 前回の値をクリア
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
		# 最後のサービスに関する情報を出力します
		if (current_service != "" && current_service != "common" && local_ip != "" && local_port != "") {
			printf "%-16s %-21s %-26s %-10s\n", \
				current_service, \
				local_ip ":" local_port, \
				server_addr ":" remote_port, \
				type
		}
	}' "$config_file"
}



# FRPサーバーポートの取得
get_frp_ports() {
	mapfile -t ports < <(ss -tulnape | grep frps | awk '{print $5}' | awk -F':' '{print $NF}' | sort -u)
}

# アクセスアドレスの生成
generate_access_urls() {
	# まずすべてのポートを取得します
	get_frp_ports

	# 8055/8056以外のポートがあるか確認する
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

		# IPv4 アドレスの処理
		for port in "${ports[@]}"; do
			if [[ $port != "8055" && $port != "8056" ]]; then
				echo "http://${ipv4_address}:${port}"
			fi
		done

		# IPv6 アドレスが存在する場合は処理します
		if [ -n "$ipv6_address" ]; then
			for port in "${ports[@]}"; do
				if [[ $port != "8055" && $port != "8056" ]]; then
					echo "http://[${ipv6_address}]:${port}"
				fi
			done
		fi

		# HTTPS 構成を処理する
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
	local app_id="55"
	local docker_name="frps"
	local docker_port=8056
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRPサーバー$check_frp $update_status"
		echo "FRPイントラネットペネトレーションサービス環境を構築し、パブリックIPを持たないデバイスをインターネットに公開"
		echo "公式サイト紹介：${gh_https_url}github.com/fatedier/frp/"
		echo "ビデオチュートリアル: https://www.bilibili.com/video/BV1yMw6e2EwL?t=124.0"
		if [ -d "/home/frp/" ]; then
			check_docker_app_ip
			frps_main_ports
		fi
		echo ""
		echo "------------------------"
		echo "1. インストール 2. アップデート 3. アンインストール"
		echo "------------------------"
		echo "5. イントラネット サービスのドメイン名アクセス 6. ドメイン名アクセスの削除"
		echo "------------------------"
		echo "7. IP+ポートアクセスを許可します。 8. IP+ポートアクセスをブロックします。"
		echo "------------------------"
		echo "00. サービスステータスを更新します。 0. 前のメニューに戻ります。"
		echo "------------------------"
		read -e -p "選択内容を入力してください:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				generate_frps_config

				add_app_id
				echo "FRPサーバーを導入しました"
				;;
			2)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frps.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frps.toml /home/frp/frps.toml
				donlond_frp frps

				add_app_id
				echo "FRPサーバーを更新しました"
				;;
			3)
				crontab -l | grep -v 'frps' | crontab - > /dev/null 2>&1
				tmux kill-session -t frps >/dev/null 2>&1
				docker rm -f frps && docker rmi kjlion/frp:alpine
				rm -rf /home/frp

				close_port 8055 8056

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "アプリがアンインストールされました"
				;;
			5)
				echo "ドメイン名アクセスへのイントラネット侵入サービスのリバース"
				send_stats "FRP 外部ドメイン名アクセス"
				add_yuming
				read -e -p "イントラネット侵入サービス ポートを入力してください:" frps_port
				ldnmp_Proxy ${yuming} 127.0.0.1 ${frps_port}
				block_host_port "$frps_port" "$ipv4_address"
				;;
			6)
				echo "ドメイン名の形式 example.com (https:// なし)"
				web_del
				;;

			7)
				send_stats "IPアクセスを許可する"
				read -e -p "解放する必要があるポートを入力してください:" frps_port
				clear_host_port_rules "$frps_port" "$ipv4_address"
				;;

			8)
				send_stats "IPアクセスをブロックする"
				echo "ドメイン名アクセスを逆にしている場合は、この機能を使用して IP+ポート アクセスをブロックすることができ、より安全になります。"
				read -e -p "ブロックするポートを入力してください:" frps_port
				block_host_port "$frps_port" "$ipv4_address"
				;;

			00)
				send_stats "FRPサービスステータスを更新"
				echo "FRPサービスステータスが更新されました"
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
	local app_id="56"
	local docker_name="frpc"
	local docker_port=8055
	while true; do
		clear
		check_frp_app
		check_docker_image_update $docker_name
		echo -e "FRPクライアント$check_frp $update_status"
		echo "サーバーに接続します。接続後、インターネットにアクセスするためのイントラネット侵入サービスを作成できます。"
		echo "公式サイト紹介：${gh_https_url}github.com/fatedier/frp/"
		echo "ビデオチュートリアル: https://www.bilibili.com/video/BV1yMw6e2EwL?t=173.9"
		echo "------------------------"
		if [ -d "/home/frp/" ]; then
			[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
			list_forwarding_services "/home/frp/frpc.toml"
		fi
		echo ""
		echo "------------------------"
		echo "1. インストール 2. アップデート 3. アンインストール"
		echo "------------------------"
		echo "4. 外部サービスの追加 5. 外部サービスの削除 6. サービスの手動構成"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択内容を入力してください:" choice
		case $choice in
			1)
				install jq grep ss
				install_docker
				configure_frpc

				add_app_id
				echo "FRPクライアントがインストールされています"
				;;
			2)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine >/dev/null 2>&1
				[ -f /home/frp/frpc.toml ] || cp /home/frp/frp_0.61.0_linux_amd64/frpc.toml /home/frp/frpc.toml
				donlond_frp frpc

				add_app_id
				echo "FRPクライアントが更新されました"
				;;

			3)
				crontab -l | grep -v 'frpc' | crontab - > /dev/null 2>&1
				tmux kill-session -t frpc >/dev/null 2>&1
				docker rm -f frpc && docker rmi kjlion/frp:alpine
				rm -rf /home/frp
				close_port 8055

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "アプリがアンインストールされました"
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
		   local YTDLP_STATUS="${gl_lv}インストール済み${gl_bai}"
		else
		   local YTDLP_STATUS="${gl_hui}インストールされていません${gl_bai}"
		fi

		clear
		send_stats "yt-dlp ダウンロードツール"
		echo -e "yt-dlp $YTDLP_STATUS"
		echo -e "yt-dlp は、YouTube、Bilibili、Twitter などの何千ものサイトをサポートする強力な動画ダウンロード ツールです。"
		echo -e "公式サイトアドレス：${gh_https_url}github.com/yt-dlp/yt-dlp"
		echo "-------------------------"
		echo "ダウンロードしたビデオのリスト:"
		ls -td "$VIDEO_DIR"/*/ 2>/dev/null || echo "(まだありません)"
		echo "-------------------------"
		echo "1. インストール 2. アップデート 3. アンインストール"
		echo "-------------------------"
		echo "5. 単一ビデオのダウンロード 6. バッチビデオのダウンロード 7. カスタムパラメータのダウンロード"
		echo "8. MP3 オーディオとしてダウンロード 9. ビデオ ディレクトリを削除 10. Cookie 管理 (開発中)"
		echo "-------------------------"
		echo "0. 前のメニューに戻る"
		echo "-------------------------"
		read -e -p "オプション番号を入力してください:" choice

		case $choice in
			1)
				send_stats "yt-dlp をインストールしています..."
				echo "yt-dlp をインストールしています..."
				install ffmpeg
				curl -L ${gh_https_url}github.com/yt-dlp/yt-dlp/releases/latest/download/yt-dlp -o /usr/local/bin/yt-dlp
				chmod a+rx /usr/local/bin/yt-dlp

				add_app_id
				echo "インストールが完了しました。続行するには任意のキーを押してください..."
				read ;;
			2)
				send_stats "yt-dlp を更新しています..."
				echo "yt-dlp を更新しています..."
				yt-dlp -U

				add_app_id
				echo "アップデートが完了しました。続行するには任意のキーを押してください..."
				read ;;
			3)
				send_stats "yt-dlp をアンインストールしています..."
				echo "yt-dlp をアンインストールしています..."
				rm -f /usr/local/bin/yt-dlp

				sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
				echo "アンインストールが完了しました。続行するには任意のキーを押してください..."
				read ;;
			5)
				send_stats "単一のビデオのダウンロード"
				read -e -p "ビデオリンクを入力してください:" url
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "ダウンロードが完了しました。続行するには任意のキーを押してください..." ;;
			6)
				send_stats "ビデオのバッチダウンロード"
				install nano
				if [ ! -f "$URL_FILE" ]; then
				  echo -e "# 複数のビデオ リンク アドレスを入力します\n# https://www.bilibili.com/bangumi/play/ep733316?spm_id_from=333.337.0.0&from_spmid=666.25.episode.0" > "$URL_FILE"
				fi
				nano $URL_FILE
				echo "今すぐバッチダウンロードを開始してください..."
				yt-dlp -P "$VIDEO_DIR" -f "bv*+ba/b" --merge-output-format mp4 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-a "$URL_FILE" \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "バッチダウンロードが完了しました。続行するには任意のキーを押してください..." ;;
			7)
				send_stats "カスタムビデオのダウンロード"
				read -e -p "完全な yt-dlp パラメータを入力してください (yt-dlp を除く)。" custom
				yt-dlp -P "$VIDEO_DIR" $custom \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites
				read -e -p "実行が完了しました。続行するには任意のキーを押してください..." ;;
			8)
				send_stats "MP3ダウンロード"
				read -e -p "ビデオリンクを入力してください:" url
				yt-dlp -P "$VIDEO_DIR" -x --audio-format mp3 \
					--write-subs --sub-langs all \
					--write-thumbnail --embed-thumbnail \
					--write-info-json \
					-o "$VIDEO_DIR/%(title)s/%(title)s.%(ext)s" \
					--no-overwrites --no-post-overwrites "$url"
				read -e -p "音声のダウンロードが完了しました。続行するには任意のキーを押してください..." ;;

			9)
				send_stats "ビデオを削除する"
				read -e -p "削除されたビデオの名前を入力してください:" rmdir
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



# dpkgの中断問題を修正
fix_dpkg() {
	pkill -9 -f 'apt|dpkg'
	rm -f /var/lib/dpkg/lock-frontend /var/lib/dpkg/lock
	DEBIAN_FRONTEND=noninteractive dpkg --configure -a
}


linux_update() {
	echo -e "${gl_kjlan}システムアップデート中です...${gl_bai}"
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
		echo "不明なパッケージマネージャーです!"
		return
	fi
}



linux_clean() {
	echo -e "${gl_kjlan}システムクリーニング中...${gl_bai}"
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
		echo "パッケージマネージャーのキャッシュをクリーンアップ..."
		apk cache clean
		echo "システムログを削除します..."
		rm -rf /var/log/*
		echo "APKキャッシュを削除..."
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
		echo "システムログを削除します..."
		rm -rf /var/log/*
		echo "一時ファイルを削除します..."
		rm -rf /tmp/*

	elif command -v pkg &>/dev/null; then
		echo "未使用の依存関係をクリーンアップします..."
		pkg autoremove -y
		echo "パッケージマネージャーのキャッシュをクリーンアップ..."
		pkg clean -y
		echo "システムログを削除します..."
		rm -rf /var/log/*
		echo "一時ファイルを削除します..."
		rm -rf /tmp/*

	else
		echo "不明なパッケージマネージャーです!"
		return
	fi
	return
}



bbr_on() {

# カーネルチューニングモジュールとの競合を防ぐためのsysctl.dへの書き込みを統合
local CONF="/etc/sysctl.d/99-kejilion-bbr.conf"
mkdir -p /etc/sysctl.d
echo "net.core.default_qdisc=fq" > "$CONF"
echo "net.ipv4.tcp_congestion_control=bbr" >> "$CONF"

# 競合を引き起こす可能性のある古い sysctl.conf の残りをクリーンアップします。
sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null
sed -i '/net.core.default_qdisc/d' /etc/sysctl.conf 2>/dev/null

sysctl -p "$CONF" >/dev/null 2>&1 || sysctl --system >/dev/null 2>&1

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
send_stats "DNSの最適化"
while true; do
	clear
	echo "DNSアドレスを最適化する"
	echo "------------------------"
	echo "現在のDNSアドレス"
	cat /etc/resolv.conf
	echo "------------------------"
	echo ""
	echo "1. 外部 DNS の最適化:"
	echo " v4: 1.1.1.1 8.8.8.8"
	echo " v6: 2606:4700:4700::1111 2001:4860:4860::8888"
	echo "2.国内DNSの最適化:"
	echo " v4: 223.5.5.5 183.60.83.19"
	echo " v6: 2400:3200::1 2400:da00::6666"
	echo "3. DNS 構成を手動で編集する"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択肢を入力してください:" Limiting
	case "$Limiting" in
	  1)
		local dns1_ipv4="1.1.1.1"
		local dns2_ipv4="8.8.8.8"
		local dns1_ipv6="2606:4700:4700::1111"
		local dns2_ipv6="2001:4860:4860::8888"
		set_dns
		send_stats "外部DNSの最適化"
		;;
	  2)
		local dns1_ipv4="223.5.5.5"
		local dns2_ipv4="183.60.83.19"
		local dns1_ipv6="2400:3200::1"
		local dns2_ipv6="2400:da00::6666"
		set_dns
		send_stats "国内DNS最適化"
		;;
	  3)
		install nano
		chattr -i /etc/resolv.conf
		nano /etc/resolv.conf
		chattr +i /etc/resolv.conf
		send_stats "DNS 構成を手動で編集する"
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


	if grep -Eq "^\s*PasswordAuthentication\s+no" "$sshd_config"; then
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
			   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' "$sshd_config"
	else
		sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin yes/' \
			   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication yes/' \
			   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' "$sshd_config"
	fi

	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
}


new_ssh_port() {

  local new_port=$1

  cp /etc/ssh/sshd_config /etc/ssh/sshd_config.bak

  sed -i '/^\s*#\?\s*Port\s\+/d' /etc/ssh/sshd_config
  echo "Port $new_port" >> /etc/ssh/sshd_config

  correct_ssh_config

  restart_ssh
  open_port $new_port
  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1

  echo "SSH ポートは次のように変更されました。$new_port"

  sleep 1

}



sshkey_on() {

	sed -i -e 's/^\s*#\?\s*PermitRootLogin .*/PermitRootLogin prohibit-password/' \
		   -e 's/^\s*#\?\s*PasswordAuthentication .*/PasswordAuthentication no/' \
		   -e 's/^\s*#\?\s*PubkeyAuthentication .*/PubkeyAuthentication yes/' \
		   -e 's/^\s*#\?\s*ChallengeResponseAuthentication .*/ChallengeResponseAuthentication no/' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*
	restart_ssh
	echo -e "${gl_lv}ユーザーキーログインモードがオンになり、パスワードログインモードがオフになりました。再接続が有効になります。${gl_bai}"

}



add_sshkey() {
	chmod 700 "${HOME}"
	mkdir -p "${HOME}/.ssh"
	chmod 700 "${HOME}/.ssh"
	touch "${HOME}/.ssh/authorized_keys"

	ssh-keygen -t ed25519 -C "xxxx@gmail.com" -f "${HOME}/.ssh/sshkey" -N ""

	cat "${HOME}/.ssh/sshkey.pub" >> "${HOME}/.ssh/authorized_keys"
	chmod 600 "${HOME}/.ssh/authorized_keys"

	ip_address
	echo -e "秘密鍵情報が生成されました。必ずコピーして保存してください。として保存できます${gl_huang}${ipv4_address}_ssh.key${gl_bai}今後の SSH ログイン用のファイル"

	echo "--------------------------------"
	cat "${HOME}/.ssh/sshkey"
	echo "--------------------------------"

	sshkey_on
}





import_sshkey() {

	local public_key="$1"
	local base_dir="${2:-$HOME}"
	local ssh_dir="${base_dir}/.ssh"
	local auth_keys="${ssh_dir}/authorized_keys"

	if [[ -z "$public_key" ]]; then
		read -e -p "SSH 公開キーの内容を入力してください (通常は「ssh-rsa」または「ssh-ed25519」で始まります):" public_key
	fi

	if [[ -z "$public_key" ]]; then
		echo -e "${gl_hong}エラー: 公開キーの内容が入力されていません。${gl_bai}"
		return 1
	fi

	if [[ ! "$public_key" =~ ^ssh-(rsa|ed25519|ecdsa) ]]; then
		echo -e "${gl_hong}エラー: 正規の SSH 公開キーのようには見えません。${gl_bai}"
		return 1
	fi

	if grep -Fxq "$public_key" "$auth_keys" 2>/dev/null; then
		echo "公開キーはすでに存在するため、再度追加する必要はありません"
		return 0
	fi

	mkdir -p "$ssh_dir"
	chmod 700 "$ssh_dir"
	touch "$auth_keys"
	echo "$public_key" >> "$auth_keys"
	chmod 600 "$auth_keys"

	sshkey_on
}



fetch_remote_ssh_keys() {

	local keys_url="$1"
	local base_dir="${2:-$HOME}"
	local ssh_dir="${base_dir}/.ssh"
	local authorized_keys="${ssh_dir}/authorized_keys"
	local temp_file

	if [[ -z "${keys_url}" ]]; then
		read -e -p "リモート公開キーの URL を入力してください:" keys_url
	fi

	echo "このスクリプトは、リモート URL から SSH 公開キーを取得し、それを${authorized_keys}"
	echo ""
	echo "リモート公開鍵アドレス:"
	echo "  ${keys_url}"
	echo ""

	# 一時ファイルを作成する
	temp_file=$(mktemp)

	# 公開キーをダウンロードする
	if command -v curl >/dev/null 2>&1; then
		curl -fsSL --connect-timeout 10 "${keys_url}" -o "${temp_file}" || {
			echo "エラー: URL から公開キーをダウンロードできません (ネットワークの問題または無効なアドレス)" >&2
			rm -f "${temp_file}"
			return 1
		}
	elif command -v wget >/dev/null 2>&1; then
		wget -q --timeout=10 -O "${temp_file}" "${keys_url}" || {
			echo "エラー: URL から公開キーをダウンロードできません (ネットワークの問題または無効なアドレス)" >&2
			rm -f "${temp_file}"
			return 1
		}
	else
		echo "エラー: システムにcurlまたはwgetが見つからないため、公開キーをダウンロードできません" >&2
		rm -f "${temp_file}"
		return 1
	fi

	# コンテンツが有効かどうかを確認する
	if [[ ! -s "${temp_file}" ]]; then
		echo "エラー: ダウンロードされたファイルは空であり、URL には公開キーが含まれていない可能性があります" >&2
		rm -f "${temp_file}"
		return 1
	fi

	mkdir -p "${ssh_dir}"
	chmod 700 "${ssh_dir}"
	touch "${authorized_keys}"
	chmod 600 "${authorized_keys}"

	# 元のauthorized_keysをバックアップする
	if [[ -f "${authorized_keys}" ]]; then
		cp "${authorized_keys}" "${authorized_keys}.bak.$(date +%Y%m%d-%H%M%S)"
		echo "元のauthorized_keysファイルがバックアップされました"
	fi

	# 公開キーを追加（重複を避ける）
	local added=0
	while IFS= read -r line; do
		[[ -z "${line}" || "${line}" =~ ^# ]] && continue

		if ! grep -Fxq "${line}" "${authorized_keys}" 2>/dev/null; then
			echo "${line}" >> "${authorized_keys}"
			((added++))
		fi
	done < "${temp_file}"

	rm -f "${temp_file}"

	echo ""
	if (( added > 0 )); then
		echo "正常に追加されました${added}新しい公開鍵が到着する${authorized_keys}"
		sshkey_on
	else
		echo "新しい公開キーを追加する必要はありません (すべてがすでに存在している可能性があります)"
	fi

	echo ""
}




fetch_github_ssh_keys() {

	local username="$1"
	local base_dir="${2:-$HOME}"

	echo "続行する前に、SSH 公開キーを GitHub アカウントに追加していることを確認してください。"
	echo "1. ログイン${gh_https_url}github.com/settings/keys"
	echo "2. [新しい SSH キー] または [SSH キーの追加] をクリックします。"
	echo "3. タイトルは必要に応じて入力できます (例: Home Laptop 2026)"
	echo "4. ローカル公開鍵の内容 (通常は ~/.ssh/id_ed25519.pub または id_rsa.pub の内容全体) を「Key」フィールドに貼り付けます。"
	echo "5. [SSH キーの追加] をクリックして追加を完了します。"
	echo ""
	echo "追加すると、すべての公開キーが GitHub で公開されます。"
	echo "  ${gh_https_url}github.com/あなたのユーザー名.keys"
	echo ""


	if [[ -z "${username}" ]]; then
		read -e -p "GitHub ユーザー名 (@ のないユーザー名) を入力してください:" username
	fi

	if [[ -z "${username}" ]]; then
		echo "エラー: GitHub ユーザー名を空にすることはできません" >&2
		return 1
	fi

	keys_url="${gh_https_url}github.com/${username}.keys"

	fetch_remote_ssh_keys "${keys_url}" "${base_dir}"

}


sshkey_panel() {
  root_use
  send_stats "ユーザーキーログイン"
  while true; do
	  clear
	  local REAL_STATUS=$(grep -i "^PubkeyAuthentication" /etc/ssh/sshd_config | tr '[:upper:]' '[:lower:]')
	  if [[ "$REAL_STATUS" =~ "yes" ]]; then
		  IS_KEY_ENABLED="${gl_lv}有効${gl_bai}"
	  else
	  	  IS_KEY_ENABLED="${gl_hui}有効になっていません${gl_bai}"
	  fi
  	  echo -e "ユーザーキーログインモード${IS_KEY_ENABLED}"
  	  echo "高度なゲームプレイ: https://blog.kejilion.pro/ssh-key"
  	  echo "------------------------------------------------"
  	  echo "キーペアが生成され、SSH 経由でログインするためのより安全な方法になります。"
	  echo "------------------------"
	  echo "1. 新しいキーペアを生成します。 2. 既存の公開キーを手動で入力します。"
	  echo "3. GitHub から既存の公開キーをインポートします。 4. URL から既存の公開キーをインポートします。"
	  echo "5. 公開鍵ファイルを編集します。 6. ローカル鍵を表示します。"
	  echo "------------------------"
	  echo "0. 前のメニューに戻る"
	  echo "------------------------"
	  read -e -p "選択肢を入力してください:" host_dns
	  case $host_dns in
		  1)
	  		send_stats "新しいキーを生成する"
	  		add_sshkey
			break_end
			  ;;
		  2)
			send_stats "既存の公開キーをインポートする"
			import_sshkey
			break_end
			  ;;
		  3)
			send_stats "GitHub リモート公開キーをインポートする"
			fetch_github_ssh_keys
			break_end
			  ;;
		  4)
			send_stats "URL リモート公開キーをインポートする"
			read -e -p "リモート公開キーの URL を入力してください:" keys_url
			fetch_remote_ssh_keys "${keys_url}"
			break_end
			  ;;

		  5)
			send_stats "公開鍵ファイルを編集する"
			install nano
			nano ${HOME}/.ssh/authorized_keys
			break_end
			  ;;

		  6)
			send_stats "ローカルキーを表示する"
			echo "------------------------"
			echo "公開鍵情報"
			cat ${HOME}/.ssh/authorized_keys
			echo "------------------------"
			echo "秘密鍵情報"
			cat ${HOME}/.ssh/sshkey
			echo "------------------------"
			break_end
			  ;;
		  *)
			  break  # 跳出循环，退出菜单
			  ;;
	  esac
  done


}






add_sshpasswd() {

	root_use
	send_stats "パスワードログインモードを設定する"
	echo "パスワードログインモードを設定する"

	local target_user="$1"

	# パラメータが渡されない場合は、対話的に入力します
	if [[ -z "$target_user" ]]; then
		read -e -p "パスワードを変更するユーザー名を入力してください (デフォルトは root):" target_user
	fi

	# Enter キーを押して入力しないでください。デフォルトは root です
	target_user=${target_user:-root}

	# ユーザーが存在することを確認する
	if ! id "$target_user" >/dev/null 2>&1; then
		echo "エラー: ユーザー$target_user存在しません"
		return 1
	fi

	passwd "$target_user"

	if [[ "$target_user" == "root" ]]; then
		sed -i 's/^\s*#\?\s*PermitRootLogin.*/PermitRootLogin yes/g' /etc/ssh/sshd_config
	fi

	sed -i 's/^\s*#\?\s*PasswordAuthentication.*/PasswordAuthentication yes/g' /etc/ssh/sshd_config
	rm -rf /etc/ssh/sshd_config.d/* /etc/ssh/ssh_config.d/*

	restart_ssh

	echo -e "${gl_lv}パスワードが設定され、パスワードログインモードに変更されました。${gl_bai}"
}














root_use() {
clear
[ "$EUID" -ne 0 ] && echo -e "${gl_huang}ヒント：${gl_bai}この機能を実行するには root ユーザーが必要です。" && break_end && kejilion
}












dd_xitong() {
		send_stats "システムを再インストールする"
		dd_xitong_MollyLau() {
			wget --no-check-certificate -qO InstallNET.sh "${gh_proxy}raw.githubusercontent.com/leitbogioro/Tools/master/Linux_reinstall/InstallNET.sh" && chmod a+x InstallNET.sh

		}

		dd_xitong_bin456789() {
			curl -O ${gh_proxy}raw.githubusercontent.com/bin456789/reinstall/main/reinstall.sh
		}

		dd_xitong_1() {
		  echo -e "再インストール後の初期ユーザー名:${gl_huang}root${gl_bai}初期パスワード:${gl_huang}LeitboGi0ro${gl_bai}初期ポート:${gl_huang}22${gl_bai}"
		  echo -e "${gl_huang}再インストール後は、暴力的な侵入を防ぐため、初期パスワードを適時に変更してください。パスワードを変更するには、コマンドラインに passwd と入力します。${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_2() {
		  echo -e "再インストール後の初期ユーザー名:${gl_huang}Administrator${gl_bai}初期パスワード:${gl_huang}Teddysun.com${gl_bai}初期ポート:${gl_huang}3389${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  install wget
		  dd_xitong_MollyLau
		}

		dd_xitong_3() {
		  echo -e "再インストール後の初期ユーザー名:${gl_huang}root${gl_bai}初期パスワード:${gl_huang}123@@@${gl_bai}初期ポート:${gl_huang}22${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		dd_xitong_4() {
		  echo -e "再インストール後の初期ユーザー名:${gl_huang}Administrator${gl_bai}初期パスワード:${gl_huang}123@@@${gl_bai}初期ポート:${gl_huang}3389${gl_bai}"
		  echo -e "続行するには任意のキーを押してください..."
		  read -n 1 -s -r -p ""
		  dd_xitong_bin456789
		}

		  while true; do
			root_use
			echo "システムを再インストールする"
			echo "--------------------------------"
			echo -e "${gl_hong}知らせ：${gl_bai}再インストールすると接続が切れる可能性がありますので、不安な方はご注意ください。再インストールには 15 分程度かかることが予想されますので、事前にデータをバックアップしてください。"
			echo -e "${gl_hui}スクリプトをサポートしてくれたボス bin456789 とボス leitbogioro に感謝します。${gl_bai} "
			echo -e "${gl_hui}bin456789 プロジェクトのアドレス:${gh_https_url}github.com/bin456789/reinstall${gl_bai}"
			echo -e "${gl_hui}leitbogioro プロジェクトのアドレス:${gh_https_url}github.com/leitbogioro/Tools${gl_bai}"
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
			echo "35. openSUSE Tumbleweed 36. fnos Feiniu パブリックベータ版"
			echo "------------------------"
			echo "41. Windows 11                42. Windows 10"
			echo "43. Windows 7                 44. Windows Server 2025"
			echo "45. Windows Server 2022       46. Windows Server 2019"
			echo "47. Windows 11 ARM"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "再インストールするシステムを選択してください:" sys_choice
			case "$sys_choice" in


			  1)
				send_stats "debian13を再インストールする"
				dd_xitong_3
				bash reinstall.sh debian 13
				reboot
				exit
				;;

			  2)
				send_stats "debian12を再インストールする"
				dd_xitong_1
				bash InstallNET.sh -debian 12
				reboot
				exit
				;;
			  3)
				send_stats "debian11を再インストールする"
				dd_xitong_1
				bash InstallNET.sh -debian 11
				reboot
				exit
				;;
			  4)
				send_stats "debian10を再インストールする"
				dd_xitong_1
				bash InstallNET.sh -debian 10
				reboot
				exit
				;;
			  11)
				send_stats "ubuntu 24.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 24.04
				reboot
				exit
				;;
			  12)
				send_stats "ubuntu 22.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 22.04
				reboot
				exit
				;;
			  13)
				send_stats "ubuntu 20.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 20.04
				reboot
				exit
				;;
			  14)
				send_stats "ubuntu 18.04を再インストールします"
				dd_xitong_1
				bash InstallNET.sh -ubuntu 18.04
				reboot
				exit
				;;


			  21)
				send_stats "Rockylinux10を再インストールする"
				dd_xitong_3
				bash reinstall.sh rocky
				reboot
				exit
				;;

			  22)
				send_stats "Rockylinux9 を再インストールする"
				dd_xitong_3
				bash reinstall.sh rocky 9
				reboot
				exit
				;;

			  23)
				send_stats "alma10を再インストールする"
				dd_xitong_3
				bash reinstall.sh almalinux
				reboot
				exit
				;;

			  24)
				send_stats "alma9を再インストールする"
				dd_xitong_3
				bash reinstall.sh almalinux 9
				reboot
				exit
				;;

			  25)
				send_stats "oracle10を再インストールする"
				dd_xitong_3
				bash reinstall.sh oracle
				reboot
				exit
				;;

			  26)
				send_stats "oracle9を再インストールする"
				dd_xitong_3
				bash reinstall.sh oracle 9
				reboot
				exit
				;;

			  27)
				send_stats "fedora42を再インストールする"
				dd_xitong_3
				bash reinstall.sh fedora
				reboot
				exit
				;;

			  28)
				send_stats "fedora41を再インストールする"
				dd_xitong_3
				bash reinstall.sh fedora 41
				reboot
				exit
				;;

			  29)
				send_stats "centos10を再インストールする"
				dd_xitong_3
				bash reinstall.sh centos 10
				reboot
				exit
				;;

			  30)
				send_stats "centos9を再インストールする"
				dd_xitong_3
				bash reinstall.sh centos 9
				reboot
				exit
				;;

			  31)
				send_stats "アルパインを再インストールする"
				dd_xitong_1
				bash InstallNET.sh -alpine
				reboot
				exit
				;;

			  32)
				send_stats "アーチを再インストールする"
				dd_xitong_3
				bash reinstall.sh arch
				reboot
				exit
				;;

			  33)
				send_stats "kaliを再インストールする"
				dd_xitong_3
				bash reinstall.sh kali
				reboot
				exit
				;;

			  34)
				send_stats "オープニューラーを再インストールする"
				dd_xitong_3
				bash reinstall.sh openeuler
				reboot
				exit
				;;

			  35)
				send_stats "opensuse を再インストールする"
				dd_xitong_3
				bash reinstall.sh opensuse
				reboot
				exit
				;;

			  36)
				send_stats "Feiniu を再インストールする"
				dd_xitong_3
				bash reinstall.sh fnos
				reboot
				exit
				;;

			  41)
				send_stats "Windows 11を再インストールする"
				dd_xitong_2
				bash InstallNET.sh -windows 11 -lang "cn"
				reboot
				exit
				;;

			  42)
				dd_xitong_2
				send_stats "Windows 10を再インストールする"
				bash InstallNET.sh -windows 10 -lang "cn"
				reboot
				exit
				;;

			  43)
				send_stats "Windows7を再インストールする"
				dd_xitong_4
				bash reinstall.sh windows --iso="https://drive.massgrave.dev/cn_windows_7_professional_with_sp1_x64_dvd_u_677031.iso" --image-name='Windows 7 PROFESSIONAL'
				reboot
				exit
				;;

			  44)
				send_stats "Windowsサーバー25を再インストールします"
				dd_xitong_2
				bash InstallNET.sh -windows 2025 -lang "cn"
				reboot
				exit
				;;

			  45)
				send_stats "Windowsサーバー22を再インストールします"
				dd_xitong_2
				bash InstallNET.sh -windows 2022 -lang "cn"
				reboot
				exit
				;;

			  46)
				send_stats "Windowsサーバー19を再インストールします"
				dd_xitong_2
				bash InstallNET.sh -windows 2019 -lang "cn"
				reboot
				exit
				;;

			  47)
				send_stats "Windows11 ARMを再インストールする"
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
				  echo "xanmod の BBRv3 カーネルがインストールされている"
				  echo "現在のカーネル バージョン:$kernel_version"

				  echo ""
				  echo "カーネル管理"
				  echo "------------------------"
				  echo "1. BBRv3 カーネルを更新します。 2. BBRv3 カーネルをアンインストールします。"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択肢を入力してください:" sub_choice

				  case $sub_choice in
					  1)
						apt purge -y 'linux-*xanmod1*'
						update-grub

						# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
						wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

						# ステップ 3: リポジトリを追加する
						echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

						# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
						local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

						apt update -y
						apt install -y linux-xanmod-x64v$version

						echo "XanMod カーネルが更新されました。再起動後に有効になります"
						rm -f /etc/apt/sources.list.d/xanmod-release.list
						rm -f check_x86-64_psabi.sh*

						server_reboot

						  ;;
					  2)
						apt purge -y 'linux-*xanmod1*'
						update-grub
						echo "XanMod カーネルがアンインストールされました。再起動後に有効になります"
						server_reboot
						  ;;

					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "BBR3アクセラレーションの設定"
		  echo "ビデオ紹介: https://www.bilibili.com/video/BV14K421x7BS?t=0.1"
		  echo "------------------------------------------------"
		  echo "Debian/Ubuntu のみをサポートします"
		  echo "データをバックアップしてください。Linux カーネルをアップグレードして BBR3 を有効にします。"
		  echo "------------------------------------------------"
		  read -e -p "続行してもよろしいですか? (はい/いいえ):" choice

		  case "$choice" in
			[Yy])
			check_disk_space 3
			if [ -r /etc/os-release ]; then
				. /etc/os-release
				if [ "$ID" != "debian" ] && [ "$ID" != "ubuntu" ]; then
					echo "現在の環境では対応しておりません。 Debian および Ubuntu システムのみがサポートされています。"
					break_end
					linux_Settings
				fi
			else
				echo "オペレーティング システムの種類を特定できません"
				break_end
				linux_Settings
			fi

			check_swap
			install wget gnupg

			# wget -qO - https://dl.xanmod.org/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes
			wget -qO - ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/archive.key | gpg --dearmor -o /usr/share/keyrings/xanmod-archive-keyring.gpg --yes

			# ステップ 3: リポジトリを追加する
			echo 'deb [signed-by=/usr/share/keyrings/xanmod-archive-keyring.gpg] http://deb.xanmod.org releases main' | tee /etc/apt/sources.list.d/xanmod-release.list

			# version=$(wget -q https://dl.xanmod.org/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')
			local version=$(wget -q ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/check_x86-64_psabi.sh && chmod +x check_x86-64_psabi.sh && ./check_x86-64_psabi.sh | grep -oP 'x86-64-v\K\d+|x86-64-v\d+')

			apt update -y
			apt install -y linux-xanmod-x64v$version

			bbr_on

			echo "XanMod カーネルがインストールされ、BBR3 が正常に有効になります。再起動後に有効になります"
			rm -f /etc/apt/sources.list.d/xanmod-release.list
			rm -f check_x86-64_psabi.sh*
			server_reboot

			  ;;
			[Nn])
			  echo "キャンセル"
			  ;;
			*)
			  echo "選択が無効です。Y または N を入力してください。"
			  ;;
		  esac
		fi

}


elrepo_install() {
	# ELRepo GPG 公開キーをインポートする
	echo "ELRepo GPG 公開キーをインポートします..."
	rpm --import https://www.elrepo.org/RPM-GPG-KEY-elrepo.org
	# システムバージョンを確認する
	local os_version=$(rpm -q --qf "%{VERSION}" $(rpm -qf /etc/os-release) 2>/dev/null | awk -F '.' '{print $1}')
	local os_name=$(awk -F= '/^NAME/{print $2}' /etc/os-release)
	# サポートされているオペレーティング システムで実行されていることを確認してください
	if [[ "$os_name" != *"Red Hat"* && "$os_name" != *"AlmaLinux"* && "$os_name" != *"Rocky"* && "$os_name" != *"Oracle"* && "$os_name" != *"CentOS"* ]]; then
		echo "サポートされていないオペレーティング システム:$os_name"
		break_end
		linux_Settings
	fi
	# 検出されたオペレーティング システム情報を印刷する
	echo "検出されたオペレーティング システム:$os_name $os_version"
	# システムのバージョンに応じて、対応する ELRepo ウェアハウス構成をインストールします。
	if [[ "$os_version" == 8 ]]; then
		echo "ELRepo リポジトリ構成 (バージョン 8) をインストールしています..."
		yum -y install https://www.elrepo.org/elrepo-release-8.el8.elrepo.noarch.rpm
	elif [[ "$os_version" == 9 ]]; then
		echo "ELRepo リポジトリ構成 (バージョン 9) をインストールしています..."
		yum -y install https://www.elrepo.org/elrepo-release-9.el9.elrepo.noarch.rpm
	elif [[ "$os_version" == 10 ]]; then
		echo "ELRepo リポジトリ構成 (バージョン 10) をインストールしています..."
		yum -y install https://www.elrepo.org/elrepo-release-10.el10.elrepo.noarch.rpm
	else
		echo "サポートされていないシステム バージョン:$os_version"
		break_end
		linux_Settings
	fi
	# ELRepo カーネル リポジトリを有効にし、最新のメインライン カーネルをインストールします。
	echo "ELRepo カーネル リポジトリを有効にし、最新のメインライン カーネルをインストールします..."
	# yum -y --enablerepo=elrepo-kernel install kernel-ml
	yum --nogpgcheck -y --enablerepo=elrepo-kernel install kernel-ml
	echo "ELRepo リポジトリ構成をインストールし、最新のメインライン カーネルに更新しました。"
	server_reboot

}


elrepo() {
		  root_use
		  send_stats "Red Hat カーネル管理"
		  if uname -r | grep -q 'elrepo'; then
			while true; do
				  clear
				  kernel_version=$(uname -r)
				  echo "elrepo カーネルがインストールされています"
				  echo "現在のカーネル バージョン:$kernel_version"

				  echo ""
				  echo "カーネル管理"
				  echo "------------------------"
				  echo "1. elrepo カーネルを更新します。 2. elrepo カーネルをアンインストールします。"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択肢を入力してください:" sub_choice

				  case $sub_choice in
					  1)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						elrepo_install
						send_stats "Red Hat カーネルを更新する"
						server_reboot

						  ;;
					  2)
						dnf remove -y elrepo-release
						rpm -qa | grep elrepo | grep kernel | xargs rpm -e --nodeps
						echo "elrepo カーネルがアンインストールされました。再起動後に有効になります"
						send_stats "Red Hat カーネルをアンインストールする"
						server_reboot

						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;

				  esac
			done
		else

		  clear
		  echo "データをバックアップしてください。Linux カーネルをアップグレードします。"
		  echo "ビデオ紹介: https://www.bilibili.com/video/BV1mH4y1w7qA?t=529.2"
		  echo "------------------------------------------------"
		  echo "Red Hat シリーズのディストリビューション CentOS/RedHat/Alma/Rocky/oracle のみをサポートします"
		  echo "Linux カーネルをアップグレードすると、システムのパフォーマンスとセキュリティが向上します。可能であれば試して、慎重に実稼働環境をアップグレードすることをお勧めします。"
		  echo "------------------------------------------------"
		  read -e -p "続行してもよろしいですか? (はい/いいえ):" choice

		  case "$choice" in
			[Yy])
			  check_swap
			  elrepo_install
			  send_stats "Red Hat カーネルをアップグレードする"
			  server_reboot
			  ;;
			[Nn])
			  echo "キャンセル"
			  ;;
			*)
			  echo "選択が無効です。Y または N を入力してください。"
			  ;;
		  esac
		fi

}




clamav_freshclam() {
	echo -e "${gl_kjlan}ウイルスデータベースを更新しています...${gl_bai}"
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

	echo -e "${gl_kjlan}ディレクトリ $@ をスキャンしています...${gl_bai}"

	# ビルドマウントパラメータ
	local MOUNT_PARAMS=""
	for dir in "$@"; do
		MOUNT_PARAMS+="--mount type=bind,source=${dir},target=/mnt/host${dir} "
	done

	# clamscan コマンドパラメータを構築する
	local SCAN_PARAMS=""
	for dir in "$@"; do
		SCAN_PARAMS+="/mnt/host${dir} "
	done

	mkdir -p /home/docker/clamav/log/ > /dev/null 2>&1
	> /home/docker/clamav/log/scan.log > /dev/null 2>&1

	# Dockerコマンドを実行する
	docker run --rm \
		--name clamav \
		--mount source=clam_db,target=/var/lib/clamav \
		$MOUNT_PARAMS \
		-v /home/docker/clamav/log/:/var/log/clamav/ \
		clamav/clamav-debian:latest \
		clamscan -r --log=/var/log/clamav/scan.log $SCAN_PARAMS

	echo -e "${gl_lv}$@ 扫描完成，病毒报告存放在${gl_huang}/home/docker/clamav/log/scan.log${gl_bai}"
	echo -e "${gl_lv}ウイルスがある場合はお願いします${gl_huang}scan.log${gl_lv}ファイル内で FOUND キーワードを検索して、ウイルスの場所を確認します。${gl_bai}"

}







clamav() {
		  root_use
		  send_stats "ウイルススキャン管理"
		  while true; do
				clear
				echo "Clamav ウイルス スキャン ツール"
				echo "ビデオ紹介: https://www.bilibili.com/video/BV1TqvZe4EQm?t=0.1"
				echo "------------------------"
				echo "これは、主にさまざまな種類のマルウェアを検出して削除するために使用されるオープンソースのウイルス対策ソフトウェア ツールです。"
				echo "ウイルス、トロイの木馬、スパイウェア、悪意のあるスクリプト、その他の有害なソフトウェアが含まれます。"
				echo "------------------------"
				echo -e "${gl_lv}1.フルスキャン${gl_bai}             ${gl_huang}2. 重要なディレクトリをスキャンする${gl_bai}            ${gl_kjlan}3. カスタムディレクトリスキャン${gl_bai}"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択肢を入力してください:" sub_choice
				case $sub_choice in
					1)
					  send_stats "フルスキャン"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /
					  break_end

						;;
					2)
					  send_stats "重要なディレクトリのスキャン"
					  install_docker
					  docker volume create clam_db > /dev/null 2>&1
					  clamav_freshclam
					  clamav_scan /etc /var /usr /home /root
					  break_end
						;;
					3)
					  send_stats "カスタムディレクトリスキャン"
					  read -e -p "スキャンするディレクトリをスペースで区切って入力してください (例: /etc /var /usr /home /root):" directories
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


# ============================================================================
# Linuxカーネルチューニングモジュール（リファクタリング版）
# 統合されたコア機能 + シーン区別パラメータ + 設定ファイルの永続性 + ハードウェア適応
# 元の optimize_high_performance / optimize_balance / optimize_web_server /restore_defaults を置き換えます
# ============================================================================

# メモリサイズ(MB)を取得
_get_mem_mb() {
	awk '/MemTotal/{printf "%d", $2/1024}' /proc/meminfo
}

# 統合されたカーネルチューニングのコア機能
# パラメータ: $1 = モード名、$2 = シーン (高/バランス/ウェブ/ストリーム/ゲーム)
_kernel_optimize_core() {
	local mode_name="$1"
	local scene="${2:-high}"
	local CONF="/etc/sysctl.d/99-kejilion-optimize.conf"
	local MEM_MB=$(_get_mem_mb)

	echo -e "${gl_lv}に切り替える${mode_name}...${gl_bai}"

	# ──シーンに合わせてパラメータを設定──
	local SWAPPINESS DIRTY_RATIO DIRTY_BG_RATIO OVERCOMMIT MIN_FREE_KB VFS_PRESSURE
	local RMEM_MAX WMEM_MAX TCP_RMEM TCP_WMEM
	local SOMAXCONN BACKLOG SYN_BACKLOG
	local PORT_RANGE SCHED_AUTOGROUP THP NUMA FIN_TIMEOUT
	local KEEPALIVE_TIME KEEPALIVE_INTVL KEEPALIVE_PROBES

	case "$scene" in
		high|stream|game)
			# 高性能/ライブブロードキャスト/ゲーム: ラジカルパラメータ
			SWAPPINESS=10
			DIRTY_RATIO=15
			DIRTY_BG_RATIO=5
			OVERCOMMIT=1
			VFS_PRESSURE=50
			RMEM_MAX=67108864
			WMEM_MAX=67108864
			TCP_RMEM="4096 262144 67108864"
			TCP_WMEM="4096 262144 67108864"
			SOMAXCONN=8192
			BACKLOG=250000
			SYN_BACKLOG=8192
			PORT_RANGE="1024 65535"
			SCHED_AUTOGROUP=0
			THP="never"
			NUMA=0
			FIN_TIMEOUT=10
			KEEPALIVE_TIME=300
			KEEPALIVE_INTVL=30
			KEEPALIVE_PROBES=5
			;;
		web)
			# Web サイトサーバー: 同時実行の優先度が高い
			SWAPPINESS=10
			DIRTY_RATIO=20
			DIRTY_BG_RATIO=10
			OVERCOMMIT=1
			VFS_PRESSURE=50
			RMEM_MAX=33554432
			WMEM_MAX=33554432
			TCP_RMEM="4096 131072 33554432"
			TCP_WMEM="4096 131072 33554432"
			SOMAXCONN=16384
			BACKLOG=10000
			SYN_BACKLOG=16384
			PORT_RANGE="1024 65535"
			SCHED_AUTOGROUP=0
			THP="never"
			NUMA=0
			FIN_TIMEOUT=15
			KEEPALIVE_TIME=600
			KEEPALIVE_INTVL=60
			KEEPALIVE_PROBES=5
			;;
		balanced)
			# バランスモード: 中程度の最適化
			SWAPPINESS=30
			DIRTY_RATIO=20
			DIRTY_BG_RATIO=10
			OVERCOMMIT=0
			VFS_PRESSURE=75
			RMEM_MAX=16777216
			WMEM_MAX=16777216
			TCP_RMEM="4096 87380 16777216"
			TCP_WMEM="4096 65536 16777216"
			SOMAXCONN=4096
			BACKLOG=5000
			SYN_BACKLOG=4096
			PORT_RANGE="1024 49151"
			SCHED_AUTOGROUP=1
			THP="always"
			NUMA=1
			FIN_TIMEOUT=30
			KEEPALIVE_TIME=600
			KEEPALIVE_INTVL=60
			KEEPALIVE_PROBES=5
			;;
	esac

	# ── メモリサイズに応じて適応的に調整 ──
	if [ "$MEM_MB" -ge 16384 ]; then
		MIN_FREE_KB=131072
		[ "$scene" != "balanced" ] && SWAPPINESS=5
	elif [ "$MEM_MB" -ge 4096 ]; then
		MIN_FREE_KB=65536
	elif [ "$MEM_MB" -ge 1024 ]; then
		MIN_FREE_KB=32768
		# 小さいメモリ縮小バッファ
		if [ "$scene" != "balanced" ]; then
			RMEM_MAX=16777216
			WMEM_MAX=16777216
			TCP_RMEM="4096 87380 16777216"
			TCP_WMEM="4096 65536 16777216"
		fi
	else
		MIN_FREE_KB=16384
		SWAPPINESS=30
		OVERCOMMIT=0
		RMEM_MAX=4194304
		WMEM_MAX=4194304
		TCP_RMEM="4096 32768 4194304"
		TCP_WMEM="4096 32768 4194304"
		SOMAXCONN=1024
		BACKLOG=1000
	fi

	# ── ライブブロードキャストシナリオの追加：UDPバッファの拡大 ──
	local STREAM_EXTRA=""
	if [ "$scene" = "stream" ]; then
		STREAM_EXTRA="
# ライブストリーミング UDP の最適化
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_notsent_lowat = 16384"
	fi

	# ── ゲームサーバーシーン番外編：低遅延優先 ──
	local GAME_EXTRA=""
	if [ "$scene" = "game" ]; then
		GAME_EXTRA="
# ゲームサーバーの低遅延の最適化
net.ipv4.udp_rmem_min = 16384
net.ipv4.udp_wmem_min = 16384
net.ipv4.tcp_notsent_lowat = 16384
net.ipv4.tcp_slow_start_after_idle = 0"
	fi

	# ── BBRモジュールのロード ──
	local CC="bbr"
	local QDISC="fq"
	local KVER
	KVER=$(uname -r | grep -oP '^\d+\.\d+')
	if printf '%s\n%s' "4.9" "$KVER" | sort -V -C; then
		if ! lsmod 2>/dev/null | grep -q tcp_bbr; then
			modprobe tcp_bbr 2>/dev/null
		fi
		if ! sysctl net.ipv4.tcp_available_congestion_control 2>/dev/null | grep -q bbr; then
			CC="cubic"
			QDISC="fq_codel"
		fi
	else
		CC="cubic"
		QDISC="fq_codel"
	fi

	# ── 既存の構成をバックアップします ──
	[ -f "$CONF" ] && cp "$CONF" "${CONF}.bak.$(date +%s)"

	# ── 設定ファイルの書き込み（永続化） ──
	echo -e "${gl_lv}最適化構成を書き込みます...${gl_bai}"
	cat > "$CONF" << SYSCTL
# kejilion カーネルチューニング構成
# モード: $モード名 |シーン: $scene
# メモリ: ${MEM_MB}MB |生成時間: $(日付 '+%Y-%m-%d %H:%M:%S')

# ──TCP輻輳制御──
net.core.default_qdisc = $QDISC
net.ipv4.tcp_congestion_control = $CC

# ── TCPバッファ ──
net.core.rmem_max = $RMEM_MAX
net.core.wmem_max = $WMEM_MAX
net.core.rmem_default = $(echo "$TCP_RMEM" | awk '{print $2}')
net.core.wmem_default = $(echo "$TCP_WMEM" | awk '{print $2}')
net.ipv4.tcp_rmem = $TCP_RMEM
net.ipv4.tcp_wmem = $TCP_WMEM

# ── 接続キュー ──
net.core.somaxconn = $SOMAXCONN
net.core.netdev_max_backlog = $BACKLOG
net.ipv4.tcp_max_syn_backlog = $SYN_BACKLOG

# ── TCP接続の最適化 ──
net.ipv4.tcp_fastopen = 3
net.ipv4.tcp_tw_reuse = 1
net.ipv4.tcp_fin_timeout = $FIN_TIMEOUT
net.ipv4.tcp_keepalive_time = $KEEPALIVE_TIME
net.ipv4.tcp_keepalive_intvl = $KEEPALIVE_INTVL
net.ipv4.tcp_keepalive_probes = $KEEPALIVE_PROBES
net.ipv4.tcp_max_tw_buckets = 65536
net.ipv4.tcp_syncookies = 1
net.ipv4.tcp_synack_retries = 2
net.ipv4.tcp_syn_retries = 3
net.ipv4.tcp_mtu_probing = 1
net.ipv4.tcp_sack = 1
net.ipv4.tcp_timestamps = 1
net.ipv4.tcp_window_scaling = 1

# ── ポートとメモリ ──
net.ipv4.ip_local_port_range = $PORT_RANGE
net.ipv4.tcp_mem = $((MEM_MB * 1024 / 8)) $((MEM_MB * 1024 / 4)) $((MEM_MB * 1024 / 2))
net.ipv4.tcp_max_orphans = 32768

# ── 仮想メモリ ──
vm.swappiness = $SWAPPINESS
vm.dirty_ratio = $DIRTY_RATIO
vm.dirty_background_ratio = $DIRTY_BG_RATIO
vm.overcommit_memory = $OVERCOMMIT
vm.min_free_kbytes = $MIN_FREE_KB
vm.vfs_cache_pressure = $VFS_PRESSURE

# ──CPU/カーネルのスケジューリング──
kernel.sched_autogroup_enabled = $SCHED_AUTOGROUP
$([ -f /proc/sys/kernel/numa_balancing ] && echo "kernel.numa_balancing = $NUMA" || echo "# uma_balancing はサポートされていません")

# ──安全保護──
net.ipv4.conf.all.rp_filter = 1
net.ipv4.conf.default.rp_filter = 1
net.ipv4.icmp_echo_ignore_broadcasts = 1
net.ipv4.icmp_ignore_bogus_error_responses = 1
net.ipv4.conf.all.accept_redirects = 0
net.ipv4.conf.default.accept_redirects = 0
net.ipv4.conf.all.send_redirects = 0
net.ipv4.conf.default.send_redirects = 0
net.ipv6.conf.all.accept_redirects = 0
net.ipv6.conf.default.accept_redirects = 0

# ── ファイル記述子 ──
fs.file-max = 1048576
fs.nr_open = 1048576

# ── 接続追跡 ──
$(if [ -f /proc/sys/net/netfilter/nf_conntrack_max ]; then
echo "net.netfilter.nf_conntrack_max = $((SOMAXCONN * 32))"
echo "net.netfilter.nf_conntrack_tcp_timeout_established = 7200"
echo "net.netfilter.nf_conntrack_tcp_timeout_time_wait = 30"
echo "net.netfilter.nf_conntrack_tcp_timeout_close_wait = 15"
echo "net.netfilter.nf_conntrack_tcp_timeout_fin_wait = 15"
else
echo "# conntrack が有効になっていません"
fi)
$STREAM_EXTRA
$GAME_EXTRA
SYSCTL

	# ── 設定を適用します (1 行ずつ、サポートされていないパラメータをスキップします) ──
	echo -e "${gl_lv}最適化パラメータを適用します...${gl_bai}"
	local applied=0 skipped=0
	while IFS= read -r line; do
		# コメントと空白行をスキップする
		[[ "$line" =~ ^[[:space:]]*# ]] && continue
		[[ -z "${line// /}" ]] && continue
		if sysctl -w "$line" >/dev/null 2>&1; then
			applied=$((applied + 1))
		else
			skipped=$((skipped + 1))
		fi
	done < "$CONF"
	echo -e "${gl_lv}適用済み${applied}アイテムパラメータ ${skipped:+、スキップ${skipped}項目がサポートされていないパラメータ}${gl_bai}"

	# ── 透明大判ページ ──
	if [ -f /sys/kernel/mm/transparent_hugepage/enabled ]; then
		echo "$THP" > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null
	fi

	# ── ファイル記述子の制限事項 ──
	if ! grep -q "# kejilion-optimize" /etc/security/limits.conf 2>/dev/null; then
		cat >> /etc/security/limits.conf << 'LIMITS'

# kejilion-optimize
* soft nofile 1048576
* hard nofile 1048576
root soft nofile 1048576
root hard nofile 1048576
LIMITS
	fi

	# ── BBRのこだわり ──
	if [ "$CC" = "bbr" ]; then
		echo "tcp_bbr" > /etc/modules-load.d/bbr.conf 2>/dev/null
		# 古い sysctl.conf 内の bbr 設定をクリーンアップします (競合を避けるため)。
		sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null
	fi

	echo -e "${gl_lv}${mode_name}最適化が完了しました！構成は永続化されています${CONF}${gl_bai}"
	echo -e "${gl_lv}メモリ：${MEM_MB}MB |輻輳アルゴリズム:${CC}|列：${QDISC}${gl_bai}"
}

# ── 各モードのエントリ機能（元の呼び出しインターフェースはそのまま） ──

optimize_high_performance() {
	_kernel_optimize_core "${tiaoyou_moshi:-高性能优化模式}" "high"
}

optimize_balanced() {
	_kernel_optimize_core "バランスのとれた最適化モード" "balanced"
}

optimize_web_server() {
	_kernel_optimize_core "ウェブサイト構築最適化モード" "web"
}

# ── 还原默认设置（完全清理） ──
restore_defaults() {
	echo -e "${gl_lv}デフォルト設定に戻す...${gl_bai}"

	local CONF="/etc/sysctl.d/99-kejilion-optimize.conf"

	# 最適化設定ファイル(外部リンク自動チューニング設定含む)を削除します。
	rm -f "$CONF"
	rm -f /etc/sysctl.d/99-network-optimize.conf

	# sysctl.conf に残っている可能性のある bbr 設定をクリーンアップする
	sed -i '/net.ipv4.tcp_congestion_control/d' /etc/sysctl.conf 2>/dev/null

	# システムのデフォルト設定をリロードする
	sysctl --system 2>/dev/null | tail -1

	# 透明な巨大ページを復元する
	[ -f /sys/kernel/mm/transparent_hugepage/enabled ] && \
		echo always > /sys/kernel/mm/transparent_hugepage/enabled 2>/dev/null

	# クリーンなファイル記述子の構成
	if grep -q "# kejilion-optimize" /etc/security/limits.conf 2>/dev/null; then
		sed -i '/# kejilion-optimize/,+4d' /etc/security/limits.conf
	fi

	# BBR 永続性をクリーンアップする
	rm -f /etc/modules-load.d/bbr.conf 2>/dev/null

	echo -e "${gl_lv}システムがデフォルト設定に復元されました${gl_bai}"
}


Kernel_optimize() {
	root_use
	while true; do
	  clear
	  send_stats "Linuxカーネルチューニング管理"
	  local current_mode=$(grep "^# モード:" /etc/sysctl.d/99-kejilion-optimize.conf 2>/dev/null | sed 's/# モード: //' | awk -F'|' '{print $1}' | xargs)
	  [ -z "$current_mode" ] && [ -f /etc/sysctl.d/99-network-optimize.conf ] && current_mode="オートチューニングモード"
	  echo "Linuxシステムのカーネルパラメータの最適化"
	  if [ -n "$current_mode" ]; then
		  echo -e "現在のモード:${gl_lv}${current_mode}${gl_bai}"
	  else
		  echo -e "現在のモード:${gl_hui}最適化されていない${gl_bai}"
	  fi
	  echo "ビデオ紹介: https://www.bilibili.com/video/BV1Kb421J7yg?t=0.1"
	  echo "------------------------------------------------"
	  echo "さまざまなシステムパラメータチューニングモードを提供し、ユーザーは独自の使用シナリオに応じて切り替えることができます。"
	  echo -e "${gl_huang}ヒント：${gl_bai}本番環境では注意して使用してください。"
	  echo -e "--------------------"
	  echo -e "1. ハイパフォーマンス最適化モード: システムパフォーマンス、積極的なメモリ、およびネットワークパラメータを最大化します。"
	  echo -e "2. バランスのとれた最適化モード: パフォーマンスとリソース消費のバランスをとり、日常の使用に適しています。"
	  echo -e "3. Web サイト最適化モード: Web サイトサーバー、超高同時接続キュー用に最適化されています。"
	  echo -e "4. ライブ ブロードキャスト最適化モード: ライブ ストリーミングの最適化では、遅延を減らすために UDP バッファーが拡大されます。"
	  echo -e "5. ゲームサーバー最適化モード：低遅延を優先してゲームサーバーに最適化します。"
	  echo -e "6. デフォルト設定の復元: システム設定をデフォルト構成に復元します。"
	  echo -e "7. 自動チューニング: テストデータに基づいてカーネルパラメータを自動的にチューニングします。${gl_huang}★${gl_bai}"
	  echo "--------------------"
	  echo "0. 前のメニューに戻る"
	  echo "--------------------"
	  read -e -p "選択肢を入力してください:" sub_choice
	  case $sub_choice in
		  1)
			  cd ~
			  clear
			  local tiaoyou_moshi="高性能最適化モード"
			  optimize_high_performance
			  send_stats "ハイパフォーマンスモードの最適化"
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
			  send_stats "ウェブサイト最適化モード"
			  ;;
		  4)
			  cd ~
			  clear
			  _kernel_optimize_core "ライブブロードキャスト最適化モード" "stream"
			  send_stats "ライブストリーミングの最適化"
			  ;;
		  5)
			  cd ~
			  clear
			  _kernel_optimize_core "ゲームサーバー最適化モード" "game"
			  send_stats "ゲームサーバーの最適化"
			  ;;
		  6)
			  cd ~
			  clear
			  restore_defaults
			  curl -sS ${gh_proxy}raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh -o /tmp/network-optimize.sh && source /tmp/network-optimize.sh && restore_network_defaults
			  send_stats "デフォルト設定を復元する"
			  ;;

		  7)
			  cd ~
			  clear
			  curl -sS ${gh_proxy}raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh | bash
			  send_stats "カーネル自動チューニング"
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
				echo -e "${gl_lv}システム言語は次のように変更されました。$lang有効にするには、SSH に再接続します。${gl_bai}"
				hash -r
				break_end

				;;
			centos|rhel|almalinux|rocky|fedora)
				install glibc-langpack-zh
				localectl set-locale LANG=${lang}
				echo "LANG=${lang}" | tee /etc/locale.conf
				echo -e "${gl_lv}システム言語は次のように変更されました。$lang有効にするには、SSH に再接続します。${gl_bai}"
				hash -r
				break_end
				;;
			*)
				echo "サポートされていないシステム:$ID"
				break_end
				;;
		esac
	else
		echo "サポートされていないシステムです。システムの種類を識別できません。"
		break_end
	fi
}




linux_language() {
root_use
send_stats "システム言語を切り替える"
while true; do
  clear
  echo "現在のシステム言語:$LANG"
  echo "------------------------"
  echo "1. 英語 2. 簡体字中国語 3. 繁体字中国語"
  echo "------------------------"
  echo "0. 前のメニューに戻る"
  echo "------------------------"
  read -e -p "選択内容を入力してください:" choice

  case $choice in
	  1)
		  update_locale "en_US.UTF-8" "en_US.UTF-8"
		  send_stats "英語に切り替えて"
		  ;;
	  2)
		  update_locale "zh_CN.UTF-8" "zh_CN.UTF-8"
		  send_stats "簡体字中国語に切り替える"
		  ;;
	  3)
		  update_locale "zh_TW.UTF-8" "zh_TW.UTF-8"
		  send_stats "繁体字中国語に切り替える"
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
echo -e "${gl_lv}変更が完了しました。 SSH に再接続して変更を確認してください。${gl_bai}"

hash -r
break_end

}



shell_bianse() {
  root_use
  send_stats "コマンドライン美化ツール"
  while true; do
	clear
	echo "コマンドライン美化ツール"
	echo "------------------------"
	echo -e "1. \033[1;32mroot \033[1;34mlocalhost \033[1;31m~ \033[0m${gl_bai}#"
	echo -e "2. \033[1;35mroot \033[1;36mlocalhost \033[1;33m~ \033[0m${gl_bai}#"
	echo -e "3. \033[1;31mroot \033[1;32mlocalhost \033[1;34m~ \033[0m${gl_bai}#"
	echo -e "4. \033[1;36mroot \033[1;33mlocalhost \033[1;37m~ \033[0m${gl_bai}#"
	echo -e "5. \033[1;37mroot \033[1;31mlocalhost \033[1;32m~ \033[0m${gl_bai}#"
	echo -e "6. \033[1;33mroot \033[1;34mlocalhost \033[1;35m~ \033[0m${gl_bai}#"
	echo -e "7. root localhost ~ #"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択内容を入力してください:" choice

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
  send_stats "システムのごみ箱"

  local bashrc_profile="/root/.bashrc"
  local TRASH_DIR="$HOME/.local/share/Trash/files"

  while true; do

	local trash_status
	if ! grep -q "trash-put" "$bashrc_profile"; then
		trash_status="${gl_hui}有効になっていません${gl_bai}"
	else
		trash_status="${gl_lv}有効${gl_bai}"
	fi

	clear
	echo -e "現在のごみ箱${trash_status}"
	echo -e "有効にすると、重要なファイルを誤って削除することを防ぐために、rm によって削除されたファイルは最初にごみ箱に入れられます。"
	echo "------------------------------------------------"
	ls -l --color=auto "$TRASH_DIR" 2>/dev/null || echo "ごみ箱が空です"
	echo "------------------------"
	echo "1. ごみ箱を有効にする 2. ごみ箱を閉じる"
	echo "3. コンテンツを復元する 4. ごみ箱を空にする"
	echo "------------------------"
	echo "0. 前のメニューに戻る"
	echo "------------------------"
	read -e -p "選択内容を入力してください:" choice

	case $choice in
	  1)
		install trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='trash-put'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "ごみ箱が有効になっていると、削除されたファイルはごみ箱に移動されます。"
		sleep 2
		;;
	  2)
		remove trash-cli
		sed -i '/alias rm/d' "$bashrc_profile"
		echo "alias rm='rm -i'" >> "$bashrc_profile"
		source "$bashrc_profile"
		echo "ごみ箱が閉じられ、ファイルは直接削除されます。"
		sleep 2
		;;
	  3)
		read -e -p "復元するファイル名を入力してください:" file_to_restore
		if [ -e "$TRASH_DIR/$file_to_restore" ]; then
		  mv "$TRASH_DIR/$file_to_restore" "$HOME/"
		  echo "$file_to_restoreホームディレクトリに復元されました。"
		else
		  echo "ファイルが存在しません。"
		fi
		;;
	  4)
		read -e -p "ごみ箱を空にしてもよろしいですか? [y/n]:" confirm
		if [[ "$confirm" == "y" ]]; then
		  trash-empty
		  echo "ごみ箱が空になりました。"
		fi
		;;
	  *)
		break
		;;
	esac
  done
}

linux_fav() {
send_stats "コマンドのお気に入り"
bash <(curl -l -s ${gh_proxy}raw.githubusercontent.com/byJoey/cmdbox/refs/heads/main/install.sh)
}

# バックアップの作成
create_backup() {
	send_stats "バックアップの作成"
	local TIMESTAMP=$(date +"%Y%m%d%H%M%S")

	# ユーザーにバックアップ ディレクトリの入力を求めるプロンプトを表示する
	echo "バックアップの作成例:"
	echo "- 単一ディレクトリをバックアップします: /var/www"
	echo "- 複数のディレクトリをバックアップします: /etc /home /var/log"
	echo "- Enter キーを押して、デフォルトのディレクトリ (/etc /usr /home) を使用します。"
	read -e -p "バックアップするディレクトリを入力してください (複数のディレクトリをスペースで区切って、Enter キーを押してデフォルトのディレクトリを使用します)。" input

	# ユーザーがディレクトリを入力しない場合は、デフォルトのディレクトリが使用されます。
	if [ -z "$input" ]; then
		BACKUP_PATHS=(
			"/etc"              # 配置文件和软件包配置
			"/usr"              # 已安装的软件文件
			"/home"             # 用户数据
		)
	else
		# ユーザーが配列に入力したディレクトリをスペースで区切ります。
		IFS=' ' read -r -a BACKUP_PATHS <<< "$input"
	fi

	# バックアップ ファイルのプレフィックスを生成する
	local PREFIX=""
	for path in "${BACKUP_PATHS[@]}"; do
		# ディレクトリ名を抽出し、スラッシュを削除します
		dir_name=$(basename "$path")
		PREFIX+="${dir_name}_"
	done

	# 最後のアンダースコアを削除します
	local PREFIX=${PREFIX%_}

	# バックアップファイル名の生成
	local BACKUP_NAME="${PREFIX}_$TIMESTAMP.tar.gz"

	# ユーザーが選択した印刷ディレクトリ
	echo "選択したバックアップ ディレクトリは次のとおりです。"
	for path in "${BACKUP_PATHS[@]}"; do
		echo "- $path"
	done

	# バックアップの作成
	echo "バックアップの作成$BACKUP_NAME..."
	install tar
	tar -czvf "$BACKUP_DIR/$BACKUP_NAME" "${BACKUP_PATHS[@]}"

	# コマンドが成功したかどうかを確認する
	if [ $? -eq 0 ]; then
		echo "バックアップが正常に作成されました:$BACKUP_DIR/$BACKUP_NAME"
	else
		echo "バックアップの作成に失敗しました!"
		exit 1
	fi
}

# バックアップを復元する
restore_backup() {
	send_stats "バックアップを復元する"
	# 復元するバックアップを選択してください
	read -e -p "復元するバックアップ ファイル名を入力してください:" BACKUP_NAME

	# バックアップファイルが存在するか確認する
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルが存在しません!"
		exit 1
	fi

	echo "バックアップの復元$BACKUP_NAME..."
	tar -xzvf "$BACKUP_DIR/$BACKUP_NAME" -C /

	if [ $? -eq 0 ]; then
		echo "バックアップと復元が成功しました。"
	else
		echo "バックアップ復元に失敗しました!"
		exit 1
	fi
}

# バックアップの一覧表示
list_backups() {
	echo "利用可能なバックアップ:"
	ls -1 "$BACKUP_DIR"
}

# バックアップの削除
delete_backup() {
	send_stats "バックアップの削除"

	read -e -p "削除するバックアップ ファイル名を入力してください:" BACKUP_NAME

	# バックアップファイルが存在するか確認する
	if [ ! -f "$BACKUP_DIR/$BACKUP_NAME" ]; then
		echo "バックアップファイルが存在しません!"
		exit 1
	fi

	# バックアップの削除
	rm -f "$BACKUP_DIR/$BACKUP_NAME"

	if [ $? -eq 0 ]; then
		echo "バックアップが正常に削除されました。"
	else
		echo "バックアップの削除に失敗しました!"
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
		echo "1. バックアップの作成 2. バックアップの復元 3. バックアップの削除"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択肢を入力してください:" choice
		case $choice in
			1) create_backup ;;
			2) restore_backup ;;
			3) delete_backup ;;
			*) break ;;
		esac
		read -e -p "続行するには Enter キーを押してください..."
	done
}









# SSH入力正規化機能
kj_ssh_validate_host() {
	local host="$1"
	[[ -n "$host" && ! "$host" =~ [[:space:]] && "$host" =~ ^[A-Za-z0-9._:-]+$ ]]
}

kj_ssh_validate_port() {
	local port="$1"
	[[ "$port" =~ ^[0-9]+$ ]] && [ "$port" -ge 1 ] && [ "$port" -le 65535 ]
}

kj_ssh_validate_user() {
	local user="$1"
	[[ -n "$user" && "$user" =~ ^[A-Za-z_][A-Za-z0-9._-]*$ ]]
}

kj_ssh_read_host_port() {
	local host_prompt="$1"
	local port_prompt="$2"
	local default_port="${3:-22}"

	while true; do
		read -e -p "$host_prompt" KJ_SSH_HOST
		if kj_ssh_validate_host "$KJ_SSH_HOST"; then
			break
		fi
		echo "エラー: 有効なサーバー アドレスを入力してください。"
	done

	while true; do
		read -e -p "$port_prompt" KJ_SSH_PORT
		KJ_SSH_PORT=${KJ_SSH_PORT:-$default_port}
		if kj_ssh_validate_port "$KJ_SSH_PORT"; then
			break
		fi
		echo "エラー: ポートは 1 ～ 65535 の数値である必要があります。"
	done
}

kj_ssh_read_host_user_port() {
	local host_prompt="$1"
	local user_prompt="$2"
	local port_prompt="$3"
	local default_user="${4:-root}"
	local default_port="${5:-22}"

	kj_ssh_read_host_port "$host_prompt" "$port_prompt" "$default_port"

	while true; do
		read -e -p "$user_prompt" KJ_SSH_USER
		KJ_SSH_USER=${KJ_SSH_USER:-$default_user}
		if kj_ssh_validate_user "$KJ_SSH_USER"; then
			break
		fi
		echo "エラー: ユーザー名の形式が正しくありません。"
	done
}

kj_ssh_parse_remote() {
	local remote_raw="$1"
	local default_user="${2:-root}"
	local remote_user remote_host

	if [[ "$remote_raw" == *@* ]]; then
		remote_user="${remote_raw%@*}"
		remote_host="${remote_raw#*@}"
	else
		remote_user="$default_user"
		remote_host="$remote_raw"
	fi

	if ! kj_ssh_validate_user "$remote_user"; then
		echo "エラー: SSH ユーザー名の形式が正しくありません。"
		return 1
	fi

	if ! kj_ssh_validate_host "$remote_host"; then
		echo "エラー: SSH ホスト アドレスの形式が正しくありません。"
		return 1
	fi

	KJ_SSH_USER="$remote_user"
	KJ_SSH_HOST="$remote_host"
	KJ_SSH_REMOTE="$remote_user@$remote_host"
}

kj_ssh_read_auth() {
	local key_file="$1"
	local password_or_key=""

	echo "認証方法を選択してください:"
	echo "1. パスワード"
	echo "2. キー"
	read -e -p "選択肢を入力してください (1/2):" auth_choice

	case $auth_choice in
		1)
			read -s -p "パスワードを入力してください:" password_or_key
			echo
			if [ -z "$password_or_key" ]; then
				echo "エラー: パスワードを空にすることはできません。"
				return 1
			fi
			KJ_SSH_AUTH_METHOD="password"
			KJ_SSH_AUTH_SECRET="$password_or_key"
			;;
		2)
			echo "キーの内容を貼り付けてください (貼り付け後に Enter を 2 回押します)。"
			while IFS= read -r line; do
				if [[ -z "$line" && "$password_or_key" == *"-----BEGIN"* ]]; then
					break
				fi
				if [[ -n "$line" || "$password_or_key" == *"-----BEGIN"* ]]; then
					password_or_key+="${line}"$'\n'
				fi
			done

			if [[ "$password_or_key" != *"-----BEGIN"* || "$password_or_key" != *"PRIVATE KEY-----"* ]]; then
				echo "キーの内容が無効です!"
				return 1
			fi

			mkdir -p "$(dirname "$key_file")"
			echo -n "$password_or_key" > "$key_file"
			chmod 600 "$key_file"
			KJ_SSH_AUTH_METHOD="key"
			KJ_SSH_AUTH_SECRET="$key_file"
			;;
		*)
			echo "無効な選択です!"
			return 1
			;;
	esac
}

kj_ssh_read_password() {
	local prompt="${1:-请输入密码: }"
	while true; do
		read -e -s -p "$prompt" KJ_SSH_PASSWORD
		echo
		[ -n "$KJ_SSH_PASSWORD" ] && break
		echo "エラー: パスワードを空にすることはできません。"
	done
}

kj_ssh_read_port() {
	local port_prompt="$1"
	local default_port="${2:-22}"
	while true; do
		read -e -p "$port_prompt" KJ_SSH_PORT
		KJ_SSH_PORT=${KJ_SSH_PORT:-$default_port}
		if kj_ssh_validate_port "$KJ_SSH_PORT"; then
			return 0
		fi
		echo "エラー: ポートは 1 ～ 65535 の数値である必要があります。"
	done
}

# 接続リストを表示
list_connections() {
	echo "保存された接続:"
	echo "------------------------"
	cat "$CONFIG_FILE" | awk -F'|' '{print NR " - " $1 " (" $2 ")"}'
	echo "------------------------"
}


# 新しい接続を追加
add_connection() {
	send_stats "新しい接続を追加"
	echo "新しい接続を作成する例:"
	echo "- 接続名: my_server"
	echo "- IP アドレス: 192.168.1.100"
	echo "- ユーザー名: root"
	echo "- ポート: 22"
	echo "------------------------"
	read -e -p "接続名を入力してください:" name

	kj_ssh_read_host_user_port "IP アドレスを入力してください:" "ユーザー名を入力してください (デフォルト: root):" "ポート番号を入力してください (デフォルト: 22):" "root" "22"
	if ! kj_ssh_read_auth "$KEY_DIR/$name.key"; then
		return
	fi

	echo "$name|$KJ_SSH_HOST|$KJ_SSH_USER|$KJ_SSH_PORT|$KJ_SSH_AUTH_SECRET" >> "$CONFIG_FILE"
	echo "接続が保存されました!"
}



# 接続の削除
delete_connection() {
	send_stats "接続の削除"
	read -e -p "削除する接続番号を入力してください:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "エラー: 対応する接続​​が見つかりません。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	# 接続にキー ファイルが使用されている場合は、キー ファイルを削除します
	if [[ "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "接続が削除されました!"
}

# 接続を使用する
use_connection() {
	send_stats "接続を使用する"
	read -e -p "使用する接続番号を入力してください:" num

	local connection=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$connection" ]]; then
		echo "エラー: 対応する接続​​が見つかりません。"
		return
	fi

	IFS='|' read -r name ip user port password_or_key <<< "$connection"

	echo "接続先$name ($ip)..."
	if [[ -f "$password_or_key" ]]; then
		# キーを使用して接続する
		ssh -o StrictHostKeyChecking=no -i "$password_or_key" -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました!以下の点をご確認ください。"
			echo "1. キーファイルのパスは正しいですか?$password_or_key"
			echo "2. キー ファイルのアクセス許可は正しいか (600 である必要があります)。"
			echo "3. ターゲットサーバーがキーを使用したログインを許可するかどうか。"
		fi
	else
		# パスワードを使用して接続する
		if ! command -v sshpass &> /dev/null; then
			echo "エラー: sshpass がインストールされていません。最初に sshpass をインストールしてください。"
			echo "インストール方法:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" ssh -o StrictHostKeyChecking=no -p "$port" "$user@$ip"
		if [[ $? -ne 0 ]]; then
			echo "接続に失敗しました!以下の点をご確認ください。"
			echo "1. ユーザー名とパスワードは正しいですか?"
			echo "2. ターゲットサーバーがパスワードログインを許可するかどうか。"
			echo "3. 対象サーバのSSHサービスが正常に動作しているか。"
		fi
	fi
}


ssh_manager() {
	send_stats "SSHリモート接続ツール"

	CONFIG_FILE="$HOME/.ssh_connections"
	KEY_DIR="$HOME/.ssh/ssh_manager_keys"

	# 設定ファイルとキーディレクトリが存在するかどうかを確認し、存在しない場合は作成します。
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
		echo "SSH経由で他のLinuxシステムに接続可能"
		echo "------------------------"
		list_connections
		echo "1. 新しい接続を作成します。 2. 接続を使用します。 3. 接続を削除します。"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択肢を入力してください:" choice
		case $choice in
			1) add_connection ;;
			2) use_connection ;;
			3) delete_connection ;;
			0) break ;;
			*) echo "選択が無効です。もう一度お試しください。" ;;
		esac
	done
}












# 利用可能なハードディスクのパーティションをリストする
list_partitions() {
	echo "利用可能なハードドライブのパーティション:"
	lsblk -o NAME,SIZE,FSTYPE,MOUNTPOINT | grep -v "sr\|loop"
}


# 永続的にマウントされたパーティション
mount_partition() {
	send_stats "パーティションのマウント"
	read -e -p "マウントするパーティションの名前を入力してください (例: sda1):" PARTITION

	DEVICE="/dev/$PARTITION"
	MOUNT_POINT="/mnt/$PARTITION"

	# パーティションが存在するかどうかを確認する
	if ! lsblk -no NAME | grep -qw "$PARTITION"; then
		echo "パーティションが存在しません!"
		return 1
	fi

	# 実装されているか確認する
	if mount | grep -qw "$DEVICE"; then
		echo "パーティションが取り付けられました！"
		return 1
	fi

	# UUIDを取得する
	UUID=$(blkid -s UUID -o value "$DEVICE")
	if [ -z "$UUID" ]; then
		echo "UUIDを取得できません!"
		return 1
	fi

	# ファイルシステムの種類を取得する
	FSTYPE=$(blkid -s TYPE -o value "$DEVICE")
	if [ -z "$FSTYPE" ]; then
		echo "ファイル システム タイプを取得できません!"
		return 1
	fi

	# マウントポイントの作成
	mkdir -p "$MOUNT_POINT"

	# マウント
	if ! mount "$DEVICE" "$MOUNT_POINT"; then
		echo "パーティションのマウントに失敗しました!"
		rmdir "$MOUNT_POINT"
		return 1
	fi

	echo "パーティションが正常にマウントされました$MOUNT_POINT"

	# /etc/fstab をチェックして、UUID またはマウント ポイントがすでに存在するかどうかを確認します。
	if grep -qE "UUID=$UUID|[[:space:]]$MOUNT_POINT[[:space:]]" /etc/fstab; then
		echo "パーティション レコードはすでに /etc/fstab に存在するため、書き込みをスキップします"
		return 0
	fi

	# /etc/fstab に書き込みます
	echo "UUID=$UUID $MOUNT_POINT $FSTYPE defaults,nofail 0 2" >> /etc/fstab

	echo "永続的なマウントを実現するために /etc/fstab に書き込まれます"
}


# パーティションをアンマウントする
unmount_partition() {
	send_stats "パーティションをアンマウントする"
	read -e -p "アンマウントするパーティションの名前を入力してください (例: sda1):" PARTITION

	# パーティションがマウントされているかどうかを確認する
	MOUNT_POINT=$(lsblk -o MOUNTPOINT | grep -w "$PARTITION")
	if [ -z "$MOUNT_POINT" ]; then
		echo "パーティションがマウントされていません!"
		return
	fi

	# パーティションをアンマウントする
	umount "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティションが正常にアンインストールされました:$MOUNT_POINT"
		rmdir "$MOUNT_POINT"
	else
		echo "パーティションのアンインストールに失敗しました!"
	fi
}

# マウントされたパーティションをリストする
list_mounted_partitions() {
	echo "マウントされたパーティション:"
	df -h | grep -v "tmpfs\|udev\|overlay"
}

# パーティションをフォーマットする
format_partition() {
	send_stats "パーティションをフォーマットする"
	read -e -p "フォーマットするパーティションの名前を入力してください (例: sda1):" PARTITION

	# パーティションが存在するかどうかを確認する
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションが存在しません!"
		return
	fi

	# パーティションがマウントされているかどうかを確認する
	if lsblk -o MOUNTPOINT | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションはマウントされています。最初にアンマウントしてください。"
		return
	fi

	# ファイルシステムの種類を選択してください
	echo "ファイル システムのタイプを選択してください:"
	echo "1. ext4"
	echo "2. xfs"
	echo "3. ntfs"
	echo "4. vfat"
	read -e -p "選択肢を入力してください:" FS_CHOICE

	case $FS_CHOICE in
		1) FS_TYPE="ext4" ;;
		2) FS_TYPE="xfs" ;;
		3) FS_TYPE="ntfs" ;;
		4) FS_TYPE="vfat" ;;
		*) echo "無効な選択です!"; return ;;
	esac

	# フォーマットの確認
	read -e -p "フォーマットされたパーティション /dev/ を確認します$PARTITIONのために$FS_TYPE? (y/n):" CONFIRM
	if [ "$CONFIRM" != "y" ]; then
		echo "操作はキャンセルされました。"
		return
	fi

	# パーティションをフォーマットする
	echo "パーティション /dev/ をフォーマットしています$PARTITIONのために$FS_TYPE ..."
	mkfs.$FS_TYPE "/dev/$PARTITION"

	if [ $? -eq 0 ]; then
		echo "パーティションが正常にフォーマットされました。"
	else
		echo "パーティションのフォーマットに失敗しました!"
	fi
}

# パーティションのステータスを確認する
check_partition() {
	send_stats "パーティションのステータスを確認する"
	read -e -p "確認するパーティション名を入力してください (例: sda1):" PARTITION

	# パーティションが存在するかどうかを確認する
	if ! lsblk -o NAME | grep -w "$PARTITION" > /dev/null; then
		echo "パーティションが存在しません!"
		return
	fi

	# パーティションのステータスを確認する
	echo "パーティション /dev/ を確認してください$PARTITION状態："
	fsck "/dev/$PARTITION"
}

# メインメニュー
disk_manager() {
	send_stats "ハードディスク管理機能"
	while true; do
		clear
		echo "ハードドライブのパーティション管理"
		echo -e "${gl_huang}この機能は内部テスト中であるため、運用環境では使用しないでください。${gl_bai}"
		echo "------------------------"
		list_partitions
		echo "------------------------"
		echo "1. パーティションをマウントします。 2. パーティションをアンマウントします。 3. マウントされたパーティションを表示します。"
		echo "4. パーティションをフォーマットします。 5. パーティションのステータスを確認します。"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択肢を入力してください:" choice
		case $choice in
			1) mount_partition ;;
			2) unmount_partition ;;
			3) list_mounted_partitions ;;
			4) format_partition ;;
			5) check_partition ;;
			*) break ;;
		esac
		read -e -p "続行するには Enter キーを押してください..."
	done
}




# タスクリストを表示
list_tasks() {
	echo "保存された同期タスク:"
	echo "---------------------------------"
	awk -F'|' '{print NR " - " $1 " ( " $2 " -> " $3":"$4 " )"}' "$CONFIG_FILE"
	echo "---------------------------------"
}

# 新しいタスクを追加する
add_task() {
	send_stats "新しい同期タスクを追加する"
	echo "新しい同期タスクの作成例:"
	echo "- タスク名:backup_www"
	echo "- ローカルディレクトリ: /var/www"
	echo "- リモートアドレス: user@192.168.1.100"
	echo "- リモートディレクトリ: /backup/www"
	echo "- ポート番号 (デフォルトは 22)"
	echo "---------------------------------"
	read -e -p "タスク名を入力してください:" name
	read -e -p "ローカル ディレクトリを入力してください:" local_path
	read -e -p "リモート ディレクトリを入力してください:" remote_path

	while true; do
		read -e -p "リモート ユーザー@IP を入力してください:" remote
		if kj_ssh_parse_remote "$remote" "root"; then
			remote="$KJ_SSH_REMOTE"
			break
		fi
	done

	kj_ssh_read_port "SSH ポート (デフォルトは 22) を入力してください:" "22"
	port="$KJ_SSH_PORT"

	if ! kj_ssh_read_auth "$KEY_DIR/${name}_sync.key"; then
		return
	fi
	auth_method="$KJ_SSH_AUTH_METHOD"
	password_or_key="$KJ_SSH_AUTH_SECRET"

	echo "同期モードを選択してください:"
	echo "1. 標準モード (-avz)"
	echo "2. 対象ファイルを削除(-avz --delete)"
	read -e -p "(1/2) を選択してください:" mode
	case $mode in
		1) options="-avz" ;;
		2) options="-avz --delete" ;;
		*) echo "選択が無効です。デフォルトの -avz を使用してください"; options="-avz" ;;
	esac

	echo "$name|$local_path|$remote|$remote_path|$port|$options|$auth_method|$password_or_key" >> "$CONFIG_FILE"

	install rsync rsync

	echo "ミッションが保存されました！"
}


# タスクの削除
delete_task() {
	send_stats "同期タスクの削除"
	read -e -p "削除するタスク番号を入力してください:" num

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "エラー: 対応するタスクが見つかりませんでした。"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# タスクがキー ファイルを使用している場合は、キー ファイルを削除します
	if [[ "$auth_method" == "key" && "$password_or_key" == "$KEY_DIR"* ]]; then
		rm -f "$password_or_key"
	fi

	sed -i "${num}d" "$CONFIG_FILE"
	echo "タスクが削除されました!"
}


run_task() {
	send_stats "同期タスクを実行する"

	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	# パラメータを解析する
	local direction="push"  # 默认是推送到远端
	local num

	if [[ "$1" == "push" || "$1" == "pull" ]]; then
		direction="$1"
		num="$2"
	else
		num="$1"
	fi

	# タスク番号が渡されない場合、ユーザーは入力を求められます。
	if [[ -z "$num" ]]; then
		read -e -p "実行するタスク番号を入力してください:" num
	fi

	local task=$(sed -n "${num}p" "$CONFIG_FILE")
	if [[ -z "$task" ]]; then
		echo "エラー: タスクが見つかりませんでした。"
		return
	fi

	IFS='|' read -r name local_path remote remote_path port options auth_method password_or_key <<< "$task"

	# 同期方向に基づいてソースパスと宛先パスを調整する
	if [[ "$direction" == "pull" ]]; then
		echo "ローカルへのプルと同期:$remote:$local_path -> $remote_path"
		source="$remote:$local_path"
		destination="$remote_path"
	else
		echo "リモートエンドへのプッシュと同期:$local_path -> $remote:$remote_path"
		source="$local_path"
		destination="$remote:$remote_path"
	fi

	# SSH接続の共通パラメータを追加する
	local ssh_options="-p $port -o StrictHostKeyChecking=no -o UserKnownHostsFile=/dev/null"

	if [[ "$auth_method" == "password" ]]; then
		if ! command -v sshpass &> /dev/null; then
			echo "エラー: sshpass がインストールされていません。最初に sshpass をインストールしてください。"
			echo "インストール方法:"
			echo "  - Ubuntu/Debian: apt install sshpass"
			echo "  - CentOS/RHEL: yum install sshpass"
			return
		fi
		sshpass -p "$password_or_key" rsync $options -e "ssh $ssh_options" "$source" "$destination"
	else
		# キーファイルが存在するかどうか、および権限が正しいかどうかを確認してください
		if [[ ! -f "$password_or_key" ]]; then
			echo "エラー: キー ファイルが存在しません:$password_or_key"
			return
		fi

		if [[ "$(stat -c %a "$password_or_key")" != "600" ]]; then
			echo "警告: キー ファイルのアクセス許可が正しくありません。修正中です..."
			chmod 600 "$password_or_key"
		fi

		rsync $options -e "ssh -i $password_or_key $ssh_options" "$source" "$destination"
	fi

	if [[ $? -eq 0 ]]; then
		echo "同期が完了しました！"
	else
		echo "同期に失敗しました!以下の点をご確認ください。"
		echo "1. ネットワーク接続は正常ですか?"
		echo "2. リモート ホストにアクセスできますか?"
		echo "3. 認証情報は正しいですか?"
		echo "4. ローカル ディレクトリとリモート ディレクトリには正しいアクセス許可がありますか?"
	fi
}


# スケジュールされたタスクを作成する
schedule_task() {
	send_stats "同期スケジュールされたタスクを追加する"

	read -e -p "定期的に同期するタスク番号を入力してください:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "エラー: 有効なタスク番号を入力してください。"
		return
	fi

	echo "スケジュールされた実行間隔を選択してください:"
	echo "1) 1時間に1回実行"
	echo "2) 1日1回実行"
	echo "3) 週に1回実行"
	read -e -p "オプションを入力してください (1/2/3):" interval

	local random_minute=$(shuf -i 0-59 -n 1)  # 生成 0-59 之间的随机分钟数
	local cron_time=""
	case "$interval" in
		1) cron_time="$random_minute * * * *" ;;  # 每小时，随机分钟执行
		2) cron_time="$random_minute 0 * * *" ;;  # 每天，随机分钟执行
		3) cron_time="$random_minute 0 * * 1" ;;  # 每周，随机分钟执行
		*) echo "エラー: 有効なオプションを入力してください。" ; return ;;
	esac

	local cron_job="$cron_time k rsync_run $num"
	local cron_job="$cron_time k rsync_run $num"

	# 同じタスクがすでに存在するかどうかを確認する
	if crontab -l | grep -q "k rsync_run $num"; then
		echo "エラー: このタスクのスケジュールされた同期はすでに存在します。"
		return
	fi

	# ユーザーのcrontabに作成
	(crontab -l 2>/dev/null; echo "$cron_job") | crontab -
	echo "スケジュールされたタスクが作成されました:$cron_job"
}

# スケジュールされたタスクを表示する
view_tasks() {
	echo "現在スケジュールされているタスク:"
	echo "---------------------------------"
	crontab -l | grep "k rsync_run"
	echo "---------------------------------"
}

# スケジュールされたタスクを削除する
delete_task_schedule() {
	send_stats "同期のスケジュールされたタスクを削除する"
	read -e -p "削除するタスク番号を入力してください:" num
	if ! [[ "$num" =~ ^[0-9]+$ ]]; then
		echo "エラー: 有効なタスク番号を入力してください。"
		return
	fi

	crontab -l | grep -v "k rsync_run $num" | crontab -
	echo "タスク番号が削除されました$numスケジュールされたタスク"
}


# タスク管理メインメニュー
rsync_manager() {
	CONFIG_FILE="$HOME/.rsync_tasks"
	CRON_FILE="$HOME/.rsync_cron"

	while true; do
		clear
		echo "Rsync リモート同期ツール"
		echo "リモート ディレクトリ間の同期は、効率的で安定した増分同期をサポートしています。"
		echo "---------------------------------"
		list_tasks
		echo
		view_tasks
		echo
		echo "1. 新しいタスクを作成します。 2. タスクを削除します。"
		echo "3. リモート サイトへのローカル同期を実行します。 4. ローカル サイトへのリモート同期を実行します。"
		echo "5. スケジュールされたタスクを作成します。 6. スケジュールされたタスクを削除します。"
		echo "---------------------------------"
		echo "0. 前のメニューに戻る"
		echo "---------------------------------"
		read -e -p "選択肢を入力してください:" choice
		case $choice in
			1) add_task ;;
			2) delete_task ;;
			3) run_task push;;
			4) run_task pull;;
			5) schedule_task ;;
			6) delete_task_schedule ;;
			0) break ;;
			*) echo "選択が無効です。もう一度お試しください。" ;;
		esac
		read -e -p "続行するには Enter キーを押してください..."
	done
}









linux_info() {



	clear
	echo -e "${gl_kjlan}システム情報を問い合わせています...${gl_bai}"
	send_stats "システム情報の問い合わせ"

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

	local runtime=$(cat /proc/uptime | awk -F. '{run_days=int($1 / 86400);run_hours=int(($1 % 86400) / 3600);run_minutes=int(($1% 3600) / 60); if (run_days > 0) printf("%d day ", run_days); if (実行時間 > 0) printf("%d 時間 ", 実行時間); printf("%d 分\n", run_ minutes)}')

	local timezone=$(current_timezone)

	local tcp_count=$(ss -t | wc -l)
	local udp_count=$(ss -u | wc -l)

	clear
	echo -e "システム情報の問い合わせ"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ホスト名:${gl_bai}$hostname"
	echo -e "${gl_kjlan}システムバージョン:${gl_bai}$os_info"
	echo -e "${gl_kjlan}Linux バージョン:${gl_bai}$kernel_version"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU アーキテクチャ:${gl_bai}$cpu_arch"
	echo -e "${gl_kjlan}CPUモデル:${gl_bai}$cpu_info"
	echo -e "${gl_kjlan}CPUコアの数:${gl_bai}$cpu_cores"
	echo -e "${gl_kjlan}CPU周波数:${gl_bai}$cpu_freq"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}CPU使用率:${gl_bai}$cpu_usage_percent%"
	echo -e "${gl_kjlan}システム負荷:${gl_bai}$load"
	echo -e "${gl_kjlan}TCP|UDP 接続の数:${gl_bai}$tcp_count|$udp_count"
	echo -e "${gl_kjlan}物理メモリ:${gl_bai}$mem_info"
	echo -e "${gl_kjlan}仮想メモリ:${gl_bai}$swap_info"
	echo -e "${gl_kjlan}ハードドライブの使用状況:${gl_bai}$disk_info"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}受け取った合計:${gl_bai}$rx"
	echo -e "${gl_kjlan}送信合計:${gl_bai}$tx"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}ネットワークアルゴリズム:${gl_bai}$congestion_algorithm $queue_algorithm"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}オペレーター：${gl_bai}$isp_info"
	if [ -n "$ipv4_address" ]; then
		echo -e "${gl_kjlan}IPv4アドレス:${gl_bai}$ipv4_address"
	fi

	if [ -n "$ipv6_address" ]; then
		echo -e "${gl_kjlan}IPv6アドレス:${gl_bai}$ipv6_address"
	fi
	echo -e "${gl_kjlan}DNS アドレス:${gl_bai}$dns_addresses"
	echo -e "${gl_kjlan}位置：${gl_bai}$country $city"
	echo -e "${gl_kjlan}システム時間:${gl_bai}$timezone $current_time"
	echo -e "${gl_kjlan}-------------"
	echo -e "${gl_kjlan}実行時間:${gl_bai}$runtime"
	echo



}



linux_tools() {

  while true; do
	  clear
	  # send_stats "基本ツール"
	  echo -e "基本的なツール"

	  tools=(
		curl wget sudo socat htop iftop unzip tar tmux ffmpeg
		btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders
		vim nano git
	  )

	  if command -v apt >/dev/null 2>&1; then
		PM="apt"
	  elif command -v dnf >/dev/null 2>&1; then
		PM="dnf"
	  elif command -v yum >/dev/null 2>&1; then
		PM="yum"
	  elif command -v pacman >/dev/null 2>&1; then
		PM="pacman"
	  elif command -v apk >/dev/null 2>&1; then
		PM="apk"
	  elif command -v zypper >/dev/null 2>&1; then
		PM="zypper"
	  elif command -v opkg >/dev/null 2>&1; then
		PM="opkg"
	  elif command -v pkg >/dev/null 2>&1; then
		PM="pkg"
	  else
		echo "❌ 認識されないパッケージマネージャー"
		exit 1
	  fi

	  echo "📦 パッケージマネージャーを使用します:$PM"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"

	  for ((i=0; i<${#tools[@]}; i+=2)); do
		# 左の列
		if command -v "${tools[i]}" >/dev/null 2>&1; then
		  left=$(printf "✅ %-12s がインストールされました" "${tools[i]}")
		else
		  left=$(printf "❌ %-12s がインストールされていません" "${tools[i]}")
		fi

		# 右列 (配列が範囲外になるのを防ぐため)
		if [[ -n "${tools[i+1]}" ]]; then
		  if command -v "${tools[i+1]}" >/dev/null 2>&1; then
			right=$(printf "✅ %-12s がインストールされました" "${tools[i+1]}")
		  else
			right=$(printf "❌ %-12s がインストールされていません" "${tools[i+1]}")
		  fi
		  printf "%-42s %s\n" "$left" "$right"
		else
		  printf "%s\n" "$left"
		fi
	  done

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}カールダウンロードツール${gl_huang}★${gl_bai}                   ${gl_kjlan}2.   ${gl_bai}wgetダウンロードツール${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}3.   ${gl_bai}sudo スーパー管理者特権ツール${gl_kjlan}4.   ${gl_bai}socat通信接続ツール"
	  echo -e "${gl_kjlan}5.   ${gl_bai}htop システム監視ツール${gl_kjlan}6.   ${gl_bai}iftop ネットワークトラフィック監視ツール"
	  echo -e "${gl_kjlan}7.   ${gl_bai}unzip ZIP圧縮・解凍ツール${gl_kjlan}8.   ${gl_bai}tar GZ 圧縮および解凍ツール"
	  echo -e "${gl_kjlan}9.   ${gl_bai}tmux マルチチャネル バックグラウンド実行ツール${gl_kjlan}10.  ${gl_bai}ffmpeg ビデオエンコードライブストリーミングツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}btop 最新の監視ツール${gl_huang}★${gl_bai}             ${gl_kjlan}12.  ${gl_bai}レンジャーファイル管理ツール"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ncdu ディスク使用量表示ツール${gl_kjlan}14.  ${gl_bai}fzf グローバル検索ツール"
	  echo -e "${gl_kjlan}15.  ${gl_bai}vim テキストエディタ${gl_kjlan}16.  ${gl_bai}ナノテキストエディタ${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}17.  ${gl_bai}git バージョン管理システム${gl_kjlan}18.  ${gl_bai}opencode AI プログラミング アシスタント${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}マトリックス スクリーンセーバー${gl_kjlan}22.  ${gl_bai}走る電車のスクリーンセーバー"
	  echo -e "${gl_kjlan}26.  ${gl_bai}テトリスのミニゲーム${gl_kjlan}27.  ${gl_bai}ヘビのミニゲーム"
	  echo -e "${gl_kjlan}28.  ${gl_bai}スペースインベーダーのミニゲーム"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}すべてインストールする${gl_kjlan}32.  ${gl_bai}すべてインストール (スクリーンセーバーとゲームを除く)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}すべてアンインストールする"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}指定されたツールをインストールする${gl_kjlan}42.  ${gl_bai}指定されたツールをアンインストールします"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  install curl
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  curl --help
			  send_stats "カールをインストールする"
			  ;;
		  2)
			  clear
			  install wget
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  wget --help
			  send_stats "wgetをインストールする"
			  ;;
			3)
			  clear
			  install sudo
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  sudo --help
			  send_stats "sudoをインストールする"
			  ;;
			4)
			  clear
			  install socat
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  socat -h
			  send_stats "socatをインストールする"
			  ;;
			5)
			  clear
			  install htop
			  clear
			  htop
			  send_stats "htopをインストールする"
			  ;;
			6)
			  clear
			  install iftop
			  clear
			  iftop
			  send_stats "iftopをインストールする"
			  ;;
			7)
			  clear
			  install unzip
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  unzip
			  send_stats "インストール解凍"
			  ;;
			8)
			  clear
			  install tar
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  tar --help
			  send_stats "tarをインストールする"
			  ;;
			9)
			  clear
			  install tmux
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  tmux --help
			  send_stats "tmuxをインストールする"
			  ;;
			10)
			  clear
			  install ffmpeg
			  clear
			  echo "ツールはインストールされており、次のように使用されます。"
			  ffmpeg --help
			  send_stats "ffmpegをインストールする"
			  ;;

			11)
			  clear
			  install btop
			  clear
			  btop
			  send_stats "btopをインストールする"
			  ;;
			12)
			  clear
			  install ranger
			  cd /
			  clear
			  ranger
			  cd ~
			  send_stats "レンジャーをインストールする"
			  ;;
			13)
			  clear
			  install ncdu
			  cd /
			  clear
			  ncdu
			  cd ~
			  send_stats "ncdu をインストールする"
			  ;;
			14)
			  clear
			  install fzf
			  cd /
			  clear
			  fzf
			  cd ~
			  send_stats "fzfをインストールする"
			  ;;
			15)
			  clear
			  install vim
			  cd /
			  clear
			  vim -h
			  cd ~
			  send_stats "vimをインストールする"
			  ;;
			16)
			  clear
			  install nano
			  cd /
			  clear
			  nano -h
			  cd ~
			  send_stats "ナノをインストールする"
			  ;;


			17)
			  clear
			  install git
			  cd /
			  clear
			  git --help
			  cd ~
			  send_stats "gitをインストールする"
			  ;;

			18)
			  clear
			  cd ~
			  curl -fsSL https://opencode.ai/install | bash
			  source ~/.bashrc
			  source ~/.profile
			  opencode
			  send_stats "オープンコードをインストールする"
			  ;;


			21)
			  clear
			  install cmatrix
			  clear
			  cmatrix
			  send_stats "cmatrix をインストールする"
			  ;;
			22)
			  clear
			  install sl
			  clear
			  sl
			  send_stats "SLをインストールする"
			  ;;
			26)
			  clear
			  install bastet
			  clear
			  bastet
			  send_stats "バステトをインストールする"
			  ;;
			27)
			  clear
			  install nsnake
			  clear
			  nsnake
			  send_stats "nsnakeをインストールする"
			  ;;

			28)
			  clear
			  install ninvaders
			  clear
			  ninvaders
			  send_stats "ニンベーダーをインストールする"
			  ;;

		  31)
			  clear
			  send_stats "すべてインストールする"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  ;;

		  32)
			  clear
			  send_stats "すべてインストール (ゲームとスクリーンセーバーを除く)"
			  install curl wget sudo socat htop iftop unzip tar tmux ffmpeg btop ranger ncdu fzf vim nano git
			  ;;


		  33)
			  clear
			  send_stats "すべてアンインストールする"
			  remove htop iftop tmux ffmpeg btop ranger ncdu fzf cmatrix sl bastet nsnake ninvaders vim nano git
			  opencode uninstall
			  rm -rf ~/.opencode
			  ;;

		  41)
			  clear
			  read -e -p "インストールされているツール名 (wgetcurlsudohtop) を入力してください:" installname
			  install $installname
			  send_stats "指定されたソフトウェアをインストールする"
			  ;;
		  42)
			  clear
			  read -e -p "アンインストールされたツール名 (htop ufw tmux cmatrix) を入力してください:" removename
			  remove $removename
			  send_stats "指定したソフトウェアをアンインストールする"
			  ;;

		  0)
			  kejilion
			  ;;

		  *)
			  echo "無効な入力です!"
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
			  echo "現在の TCP ブロック アルゴリズム:$congestion_algorithm $queue_algorithm"

			  echo ""
			  echo "BBR管理"
			  echo "------------------------"
			  echo "1. BBRv3 をオンにする 2. BBRv3 をオフにする (再起動します)"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択肢を入力してください:" sub_choice

			  case $sub_choice in
				  1)
					bbr_on
					send_stats "アルパインがBBR3をオープン"
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

	is_compose_container() {
		local container=$1
		docker inspect "$container" | jq -e '.[0].Config.Labels["com.docker.compose.project"]' >/dev/null 2>&1
	}

	list_backups() {
		local BACKUP_ROOT="/tmp"
		echo -e "${gl_kjlan}現在のバックアップ リスト:${gl_bai}"
		ls -1dt ${BACKUP_ROOT}/docker_backup_* 2>/dev/null || echo "バックアップなし"
	}



	# ----------------------------
	# バックアップ
	# ----------------------------
	backup_docker() {
		send_stats "Dockerバックアップ"

		echo -e "${gl_kjlan}Docker コンテナをバックアップしています...${gl_bai}"
		docker ps --format '{{.Names}}'
		read -e -p  "バックアップするコンテナの名前を入力してください (実行中のすべてのコンテナをバックアップするには、複数のスペースを区切って Enter キーを押します)。" containers

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
		[[ ${#TARGET_CONTAINERS[@]} -eq 0 ]] && { echo -e "${gl_hong}コンテナが見つかりません${gl_bai}"; return; }

		local BACKUP_DIR="${BACKUP_ROOT}/docker_backup_${DATE_STR}"
		mkdir -p "$BACKUP_DIR"

		local RESTORE_SCRIPT="${BACKUP_DIR}/docker_restore.sh"
		echo "#!/bin/bash" > "$RESTORE_SCRIPT"
		echo "set -e" >> "$RESTORE_SCRIPT"
		echo "# 自動生成された復元スクリプト" >> "$RESTORE_SCRIPT"

		# パッケージ化の繰り返しを避けるために、パッケージ化された Compose プロジェクトのパスを記録します。
		declare -A PACKED_COMPOSE_PATHS=()

		for c in "${TARGET_CONTAINERS[@]}"; do
			echo -e "${gl_lv}バックアップコンテナ:$c${gl_bai}"
			local inspect_file="${BACKUP_DIR}/${c}_inspect.json"
			docker inspect "$c" > "$inspect_file"

			if is_compose_container "$c"; then
				echo -e "${gl_kjlan}検出されました$cdocker-compose コンテナーです${gl_bai}"
				local project_dir=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project.working_dir"] // empty')
				local project_name=$(docker inspect "$c" | jq -r '.[0].Config.Labels["com.docker.compose.project"] // empty')

				if [ -z "$project_dir" ]; then
					read -e -p  "作成ディレクトリが検出されません。パスを手動で入力してください。" project_dir
				fi

				# Compose プロジェクトがすでにパッケージ化されている場合は、スキップしてください
				if [[ -n "${PACKED_COMPOSE_PATHS[$project_dir]}" ]]; then
					echo -e "${gl_huang}プロジェクトの作成 [$project_name] すでにバックアップされているため、繰り返しのパッケージ化をスキップします...${gl_bai}"
					continue
				fi

				if [ -f "$project_dir/docker-compose.yml" ]; then
					echo "compose" > "${BACKUP_DIR}/backup_type_${project_name}"
					echo "$project_dir" > "${BACKUP_DIR}/compose_path_${project_name}.txt"
					tar -czf "${BACKUP_DIR}/compose_project_${project_name}.tar.gz" -C "$project_dir" .
					echo "# docker-compose 復元:$project_name" >> "$RESTORE_SCRIPT"
					echo "cd \"$project_dir\" && docker compose up -d" >> "$RESTORE_SCRIPT"
					PACKED_COMPOSE_PATHS["$project_dir"]=1
					echo -e "${gl_lv}プロジェクトの作成 [$project_name] パッケージ内容:${project_dir}${gl_bai}"
				else
					echo -e "${gl_hong}docker-compose.yml が見つからないため、このコンテナをスキップします...${gl_bai}"
				fi
			else
				# 通常のコンテナバックアップボリューム
				local VOL_PATHS
				VOL_PATHS=$(docker inspect "$c" --format '{{range .Mounts}}{{.Source}} {{end}}')
				for path in $VOL_PATHS; do
					echo "梱包量:$path"
					tar -czpf "${BACKUP_DIR}/${c}_$(basename $path).tar.gz" -C / "$(echo $path | sed 's/^\///')"
				done

				# ポート
				local PORT_ARGS=""
				mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[] | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$inspect_file" 2>/dev/null)
				for p in "${PORTS[@]}"; do PORT_ARGS+="-p $p "; done

				# 環境変数
				local ENV_VARS=""
				mapfile -t ENVS < <(jq -r '.[0].Config.Env[] | @sh' "$inspect_file")
				for e in "${ENVS[@]}"; do ENV_VARS+="-e $e "; done

				# ボリュームマッピング
				local VOL_ARGS=""
				for path in $VOL_PATHS; do VOL_ARGS+="-v $path:$path "; done

				# 鏡
				local IMAGE
				IMAGE=$(jq -r '.[0].Config.Image' "$inspect_file")

				echo -e "\n# コンテナを復元:$c" >> "$RESTORE_SCRIPT"
				echo "docker run -d --name $c $PORT_ARGS $VOL_ARGS $ENV_VARS $IMAGE" >> "$RESTORE_SCRIPT"
			fi
		done


		# /home/docker 下のすべてのファイルをバックアップします (サブディレクトリを除く)。
		if [ -d "/home/docker" ]; then
			echo -e "${gl_kjlan}/home/docker 下のファイルをバックアップします...${gl_bai}"
			find /home/docker -maxdepth 1 -type f | tar -czf "${BACKUP_DIR}/home_docker_files.tar.gz" -T -
			echo -e "${gl_lv}/home/docker 下のファイルは次のようにパッケージ化されています。${BACKUP_DIR}/home_docker_files.tar.gz${gl_bai}"
		fi

		chmod +x "$RESTORE_SCRIPT"
		echo -e "${gl_lv}バックアップが完了しました:${BACKUP_DIR}${gl_bai}"
		echo -e "${gl_lv}利用可能な復元スクリプト:${RESTORE_SCRIPT}${gl_bai}"


	}

	# ----------------------------
	# 削減
	# ----------------------------
	restore_docker() {

		send_stats "Docker の復元"
		read -e -p  "復元するバックアップ ディレクトリを入力してください:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${gl_hong}バックアップディレクトリが存在しません${gl_bai}"; return; }

		echo -e "${gl_kjlan}復元操作を開始しています...${gl_bai}"

		install tar jq gzip
		install_docker

		# --------- Compose プロジェクトの復元を優先します ---------
		for f in "$BACKUP_DIR"/backup_type_*; do
			[[ ! -f "$f" ]] && continue
			if grep -q "compose" "$f"; then
				project_name=$(basename "$f" | sed 's/backup_type_//')
				path_file="$BACKUP_DIR/compose_path_${project_name}.txt"
				[[ -f "$path_file" ]] && original_path=$(cat "$path_file") || original_path=""
				[[ -z "$original_path" ]] && read -e -p  "元のパスが見つかりません。復元ディレクトリのパスを入力してください:" original_path

				# 作成プロジェクトのコンテナがすでに実行されているかどうかを確認します
				running_count=$(docker ps --filter "label=com.docker.compose.project=$project_name" --format '{{.Names}}' | wc -l)
				if [[ "$running_count" -gt 0 ]]; then
					echo -e "${gl_huang}プロジェクトの作成 [$project_name] コンテナはすでに実行されているため、復元をスキップします...${gl_bai}"
					continue
				fi

				read -e -p  "Compose プロジェクトの復元を確認します [$project_name] からパス [$original_path] ? (y/n): " confirm
				[[ "$confirm" != "y" ]] && read -e -p  "新しい復元パスを入力してください:" original_path

				mkdir -p "$original_path"
				tar -xzf "$BACKUP_DIR/compose_project_${project_name}.tar.gz" -C "$original_path"
				echo -e "${gl_lv}プロジェクトの作成 [$project_name] は次のように抽出されました。$original_path${gl_bai}"

				cd "$original_path" || return
				docker compose down || true
				docker compose up -d
				echo -e "${gl_lv}プロジェクトの作成 [$project_name】レストア完了！${gl_bai}"
			fi
		done

		# --------- 通常のコンテナの復元を続行 ---------
		echo -e "${gl_kjlan}通常の Docker コンテナを確認して復元します...${gl_bai}"
		local has_container=false
		for json in "$BACKUP_DIR"/*_inspect.json; do
			[[ ! -f "$json" ]] && continue
			has_container=true
			container=$(basename "$json" | sed 's/_inspect.json//')
			echo -e "${gl_lv}処理容器：$container${gl_bai}"

			# コンテナがすでに存在し、実行されているかどうかを確認します
			if docker ps --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${gl_huang}容器 [$container] すでに実行中のため、復元をスキップしています...${gl_bai}"
				continue
			fi

			IMAGE=$(jq -r '.[0].Config.Image' "$json")
			[[ -z "$IMAGE" || "$IMAGE" == "null" ]] && { echo -e "${gl_hong}ミラー情報が見つかりません。スキップしてください:$container${gl_bai}"; continue; }

			# ポートマッピング
			PORT_ARGS=""
			mapfile -t PORTS < <(jq -r '.[0].HostConfig.PortBindings | to_entries[]? | "\(.value[0].HostPort):\(.key | split("/")[0])"' "$json")
			for p in "${PORTS[@]}"; do
				[[ -n "$p" ]] && PORT_ARGS="$PORT_ARGS -p $p"
			done

			# 環境変数
			ENV_ARGS=""
			mapfile -t ENVS < <(jq -r '.[0].Config.Env[]' "$json")
			for e in "${ENVS[@]}"; do
				ENV_ARGS="$ENV_ARGS -e \"$e\""
			done

			# ボリュームマッピング + ボリュームデータリカバリ
			VOL_ARGS=""
			mapfile -t VOLS < <(jq -r '.[0].Mounts[] | "\(.Source):\(.Destination)"' "$json")
			for v in "${VOLS[@]}"; do
				VOL_SRC=$(echo "$v" | cut -d':' -f1)
				VOL_DST=$(echo "$v" | cut -d':' -f2)
				mkdir -p "$VOL_SRC"
				VOL_ARGS="$VOL_ARGS -v $VOL_SRC:$VOL_DST"

				VOL_FILE="$BACKUP_DIR/${container}_$(basename $VOL_SRC).tar.gz"
				if [[ -f "$VOL_FILE" ]]; then
					echo "ボリュームデータを復元します。$VOL_SRC"
					tar -xzf "$VOL_FILE" -C /
				fi
			done

			# 既存だが実行されていないコンテナを削除する
			if docker ps -a --format '{{.Names}}' | grep -q "^${container}$"; then
				echo -e "${gl_huang}容器 [$container] は存在しますが実行されていない場合は、古いコンテナを削除してください...${gl_bai}"
				docker rm -f "$container"
			fi

			# コンテナの起動
			echo "復元コマンドを実行します: docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
			eval "docker run -d --name \"$container\" $PORT_ARGS $VOL_ARGS $ENV_ARGS \"$IMAGE\""
		done

		[[ "$has_container" == false ]] && echo -e "${gl_huang}共通コンテナのバックアップ情報が見つかりません${gl_bai}"

		# /home/docker 下のファイルを復元します
		if [ -f "$BACKUP_DIR/home_docker_files.tar.gz" ]; then
			echo -e "${gl_kjlan}/home/docker の下にファイルを復元しています...${gl_bai}"
			mkdir -p /home/docker
			tar -xzf "$BACKUP_DIR/home_docker_files.tar.gz" -C /
			echo -e "${gl_lv}/home/docker 下のファイルが復元されました${gl_bai}"
		else
			echo -e "${gl_huang}/home/docker の下にあるファイルのバックアップが見つかりませんでした。スキップしています...${gl_bai}"
		fi


	}


	# ----------------------------
	# 移行する
	# ----------------------------
	migrate_docker() {
		send_stats "Docker の移行"
		install jq
		read -e -p  "移行するバックアップ ディレクトリを入力してください:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${gl_hong}バックアップディレクトリが存在しません${gl_bai}"; return; }

		kj_ssh_read_host_user_port "ターゲットサーバーIP:" "ターゲットサーバーの SSH ユーザー名 [デフォルトのルート]:" "ターゲット サーバーの SSH ポート [デフォルト 22]:" "root" "22"
		local TARGET_IP="$KJ_SSH_HOST"
		local TARGET_USER="$KJ_SSH_USER"
		local TARGET_PORT="$KJ_SSH_PORT"

		local LATEST_TAR="$BACKUP_DIR"

		echo -e "${gl_huang}バックアップを転送中...${gl_bai}"
		if [[ -z "$TARGET_PASS" ]]; then
			# キーを使用してログインする
			scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no -r "$LATEST_TAR" "$TARGET_USER@$TARGET_IP:/tmp/"
		fi

	}

	# ----------------------------
	# バックアップの削除
	# ----------------------------
	delete_backup() {
		send_stats "Dockerバックアップファイルの削除"
		read -e -p  "削除するバックアップ ディレクトリを入力してください:" BACKUP_DIR
		[[ ! -d "$BACKUP_DIR" ]] && { echo -e "${gl_hong}バックアップディレクトリが存在しません${gl_bai}"; return; }
		rm -rf "$BACKUP_DIR"
		echo -e "${gl_lv}削除されたバックアップ:${BACKUP_DIR}${gl_bai}"
	}

	# ----------------------------
	# メインメニュー
	# ----------------------------
	main_menu() {
		send_stats "Docker バックアップ 移行 復元"
		while true; do
			clear
			echo "------------------------"
			echo -e "Docker バックアップ/移行/復元ツール"
			echo "------------------------"
			list_backups
			echo -e ""
			echo "------------------------"
			echo -e "1. Docker プロジェクトをバックアップする"
			echo -e "2. Docker プロジェクトを移行する"
			echo -e "3. Docker プロジェクトを復元する"
			echo -e "4. Dockerプロジェクトのバックアップファイルを削除する"
			echo "------------------------"
			echo -e "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p  "選択してください:" choice
			case $choice in
				1) backup_docker ;;
				2) migrate_docker ;;
				3) restore_docker ;;
				4) delete_backup ;;
				0) return ;;
				*) echo -e "${gl_hong}無効なオプション${gl_bai}" ;;
			esac
		break_end
		done
	}

	main_menu
}





linux_docker() {

	while true; do
	  clear
	  # send_stats "ドッカー管理"
	  echo -e "Docker管理"
	  docker_tato
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}Docker環境のインストールと更新${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}2.   ${gl_bai}Docker のグローバル ステータスを表示する${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Dockerコンテナ管理${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}4.   ${gl_bai}Dockerイメージ管理"
	  echo -e "${gl_kjlan}5.   ${gl_bai}Dockerネットワーク管理"
	  echo -e "${gl_kjlan}6.   ${gl_bai}Docker ボリューム管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}7.   ${gl_bai}不要な Docker コンテナをクリーンアップし、ネットワーク データ ボリュームをミラーリングします。"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}8.   ${gl_bai}Dockerソースを変更する"
	  echo -e "${gl_kjlan}9.   ${gl_bai}daemon.json ファイルを編集する"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}Docker-ipv6 アクセスを有効にする"
	  echo -e "${gl_kjlan}12.  ${gl_bai}Docker-ipv6 アクセスをオフにする"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}19.  ${gl_bai}Docker環境のバックアップ/移行/復元"
	  echo -e "${gl_kjlan}20.  ${gl_bai}Docker環境をアンインストールする"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in
		  1)
			clear
			send_stats "Docker環境をインストールする"
			install_add_docker

			  ;;
		  2)
			  clear
			  local container_count=$(docker ps -a -q 2>/dev/null | wc -l)
			  local image_count=$(docker images -q 2>/dev/null | wc -l)
			  local network_count=$(docker network ls -q 2>/dev/null | wc -l)
			  local volume_count=$(docker volume ls -q 2>/dev/null | wc -l)

			  send_stats "ドッカーのグローバルステータス"
			  echo "Docker のバージョン"
			  docker -v
			  docker compose version

			  echo ""
			  echo -e "Docker イメージ:${gl_lv}$image_count${gl_bai} "
			  docker image ls
			  echo ""
			  echo -e "Docker コンテナ:${gl_lv}$container_count${gl_bai}"
			  docker ps -a
			  echo ""
			  echo -e "Docker ボリューム:${gl_lv}$volume_count${gl_bai}"
			  docker volume ls
			  echo ""
			  echo -e "Docker ネットワーク:${gl_lv}$network_count${gl_bai}"
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
				  printf "%-25s %-25s %-25s\n" "コンテナ名" "ネットワーク名" "IPアドレス"

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
				  echo "ネットワーク運用"
				  echo "------------------------"
				  echo "1. ネットワークを作成する"
				  echo "2. ネットワークに参加する"
				  echo "3. ネットワークを終了します"
				  echo "4. ネットワークの削除"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択肢を入力してください:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "ネットワークの作成"
						  read -e -p "新しいネットワーク名を設定します。" dockernetwork
						  docker network create $dockernetwork
						  ;;
					  2)
						  send_stats "ネットワークに参加する"
						  read -e -p "ネットワーク名を追加します:" dockernetwork
						  read -e -p "どのコンテナがネットワークに参加しますか (複数のコンテナ名はスペースで区切ってください):" dockernames

						  for dockername in $dockernames; do
							  docker network connect $dockernetwork $dockername
						  done
						  ;;
					  3)
						  send_stats "ネットワークに参加する"
						  read -e -p "出口ネットワーク名:" dockernetwork
						  read -e -p "これらのコンテナはネットワークから終了します (複数のコンテナ名はスペースで区切ってください)。" dockernames

						  for dockername in $dockernames; do
							  docker network disconnect $dockernetwork $dockername
						  done

						  ;;

					  4)
						  send_stats "ネットワークを削除する"
						  read -e -p "削除するネットワーク名を入力してください:" dockernetwork
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
				  send_stats "Docker ボリューム管理"
				  echo "Dockerボリュームリスト"
				  docker volume ls
				  echo ""
				  echo "ボリューム操作"
				  echo "------------------------"
				  echo "1. 新しいボリュームを作成する"
				  echo "2. 指定したボリュームを削除します"
				  echo "3. すべてのボリュームを削除します"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択肢を入力してください:" sub_choice

				  case $sub_choice in
					  1)
						  send_stats "新しいボリュームを作成する"
						  read -e -p "新しいボリューム名を設定します。" dockerjuan
						  docker volume create $dockerjuan

						  ;;
					  2)
						  read -e -p "削除ボリューム名を入力します (複数のボリューム名はスペースで区切ってください):" dockerjuans

						  for dockerjuan in $dockerjuans; do
							  docker volume rm $dockerjuan
						  done

						  ;;

					   3)
						  send_stats "すべてのボリュームを削除する"
						  read -e -p "$(echo -e "${gl_hong}注意: ${gl_bai}确定删除所有未使用的卷吗？(Y/N): ")" choice
						  case "$choice" in
							[Yy])
							  docker volume prune -f
							  ;;
							[Nn])
							  ;;
							*)
							  echo "選択が無効です。Y または N を入力してください。"
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
			  send_stats "Docker のクリーンアップ"
			  read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}将清理无用的镜像容器网络，包括停止的容器，确定清理吗？(Y/N): ")" choice
			  case "$choice" in
				[Yy])
				  docker system prune -af --volumes
				  ;;
				[Nn])
				  ;;
				*)
				  echo "選択が無効です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;
		  8)
			  clear
			  send_stats "Docker ソース"
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
			  send_stats "Docker v6 がオン"
			  docker_ipv6_on
			  ;;

		  12)
			  clear
			  send_stats "Docker v6 閉じる"
			  docker_ipv6_off
			  ;;

		  19)
			  docker_ssh_migration
			  ;;


		  20)
			  clear
			  send_stats "Docker のアンインストール"
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
				  echo "選択が無効です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無効な入力です!"
			  ;;
	  esac
	  break_end


	done


}



linux_test() {

	while true; do
	  clear
	  # send_stats "テストスクリプト集"
	  echo -e "テストスクリプト集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}IPおよびロック解除ステータスの検出"
	  echo -e "${gl_kjlan}1.   ${gl_bai}ChatGPTロック解除状態検出"
	  echo -e "${gl_kjlan}2.   ${gl_bai}リージョンストリーミングメディアロック解除テスト"
	  echo -e "${gl_kjlan}3.   ${gl_bai}Yeawu ストリーミング メディアのロック解除の検出"
	  echo -e "${gl_kjlan}4.   ${gl_bai}xykt IP 品質チェック スクリプト${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}ネットワーク回線速度テスト"
	  echo -e "${gl_kjlan}11.  ${gl_bai}besttrace 3 ネットワーク バックホール遅延ルーティング テスト"
	  echo -e "${gl_kjlan}12.  ${gl_bai}mtr_trace トリプルネットワークバックホール回線テスト"
	  echo -e "${gl_kjlan}13.  ${gl_bai}超高速トリプルネットワーク速度テスト"
	  echo -e "${gl_kjlan}14.  ${gl_bai}nxtrace 高速バックホール テスト スクリプト"
	  echo -e "${gl_kjlan}15.  ${gl_bai}nxtrace は IP バックホール テスト スクリプトを指定します"
	  echo -e "${gl_kjlan}16.  ${gl_bai}ludashi2020 3つのネットワーク回線テスト"
	  echo -e "${gl_kjlan}17.  ${gl_bai}i-abc 多機能速度テスト スクリプト"
	  echo -e "${gl_kjlan}18.  ${gl_bai}NetQuality ネットワーク品質チェック スクリプト${gl_huang}★${gl_bai}"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}ハードウェアパフォーマンステスト"
	  echo -e "${gl_kjlan}21.  ${gl_bai}yabsパフォーマンステスト"
	  echo -e "${gl_kjlan}22.  ${gl_bai}icu/gb5 CPU パフォーマンステストスクリプト"

	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}総合的なテスト"
	  echo -e "${gl_kjlan}31.  ${gl_bai}ベンチパフォーマンステスト"
	  echo -e "${gl_kjlan}32.  ${gl_bai}Spiritysdx融合モンスターの評価${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}ノードクオリティ融合モンスターの評価${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  send_stats "ChatGPTロック解除状態検出"
			  bash <(curl -Ls https://cdn.jsdelivr.net/gh/missuo/OpenAI-Checker/openai.sh)
			  ;;
		  2)
			  clear
			  send_stats "リージョンストリーミングメディアロック解除テスト"
			  bash <(curl -L -s check.unlock.media)
			  ;;
		  3)
			  clear
			  send_stats "Yeawu ストリーミング メディアのロック解除の検出"
			  install wget
			  wget -qO- ${gh_proxy}github.com/yeahwu/check/raw/main/check.sh | bash
			  ;;
		  4)
			  clear
			  send_stats "xykt_IP 品質チェック スクリプト"
			  bash <(curl -Ls IP.Check.Place)
			  ;;


		  11)
			  clear
			  send_stats "besttrace トリプル ネットワーク バックホール遅延ルーティング テスト"
			  install wget
			  wget -qO- git.io/besttrace | bash
			  ;;
		  12)
			  clear
			  send_stats "mtr_trace トリプルネットワークバックホール回線テスト"
			  curl ${gh_proxy}raw.githubusercontent.com/zhucaidan/mtr_trace/main/mtr_trace.sh | bash
			  ;;
		  13)
			  clear
			  send_stats "超高速トリプルネットワーク速度テスト"
			  bash <(curl -Lso- https://git.io/superspeed_uxh)
			  ;;
		  14)
			  clear
			  send_stats "nxtrace 高速バックホール テスト スクリプト"
			  curl nxtrace.org/nt |bash
			  nexttrace --fast-trace --tcp
			  ;;
		  15)
			  clear
			  send_stats "nxtrace は IP バックホール テスト スクリプトを指定します"
			  echo "参照IPリスト"
			  echo "------------------------"
			  echo "北京電信: 219.141.136.12"
			  echo "北京ユニコム: 202.106.50.1"
			  echo "北京モバイル: 221.179.155.161"
			  echo "上海電信: 202.96.209.133"
			  echo "上海ユニコム: 210.22.97.1"
			  echo "上海モバイル: 211.136.112.200"
			  echo "広州電信: 58.60.188.222"
			  echo "広州チャイナユニコム: 210.21.196.6"
			  echo "広州モバイル: 120.196.165.24"
			  echo "成都電信: 61.139.2.69"
			  echo "成都チャイナユニコム: 119.6.6.6"
			  echo "成都携帯電話: 211.137.96.205"
			  echo "湖南電信: 36.111.200.100"
			  echo "湖南ユニコム: 42.48.16.100"
			  echo "湖南省モバイル: 39.134.254.6"
			  echo "------------------------"

			  read -e -p "特定の IP を入力します。" testip
			  curl nxtrace.org/nt |bash
			  nexttrace $testip
			  ;;

		  16)
			  clear
			  send_stats "ludashi2020 3つのネットワーク回線テスト"
			  curl ${gh_proxy}raw.githubusercontent.com/ludashi2020/backtrace/main/install.sh -sSf | sh
			  ;;

		  17)
			  clear
			  send_stats "i-abc 多機能速度テスト スクリプト"
			  bash <(curl -sL ${gh_proxy}raw.githubusercontent.com/i-abc/Speedtest/main/speedtest.sh)
			  ;;

		  18)
			  clear
			  send_stats "ネットワーク品質テストスクリプト"
			  bash <(curl -sL Net.Check.Place)
			  ;;

		  21)
			  clear
			  send_stats "yabsパフォーマンステスト"
			  check_swap
			  curl -sL yabs.sh | bash -s -- -i -5
			  ;;
		  22)
			  clear
			  send_stats "icu/gb5 CPU パフォーマンステストスクリプト"
			  check_swap
			  bash <(curl -sL bash.icu/gb5)
			  ;;

		  31)
			  clear
			  send_stats "ベンチパフォーマンステスト"
			  curl -Lso- bench.sh | bash
			  ;;
		  32)
			  send_stats "Spiritysdx フュージョンモンスター レビュー"
			  clear
			  curl -L ${gh_proxy}gitlab.com/spiritysdx/za/-/raw/main/ecs.sh -o ecs.sh && chmod +x ecs.sh && bash ecs.sh
			  ;;

		  33)
			  send_stats "ノードクオリティ融合モンスターの評価"
			  clear
			  bash <(curl -sL https://run.NodeQuality.com)
			  ;;



		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力です!"
			  ;;
	  esac
	  break_end

	done


}


linux_Oracle() {


	 while true; do
	  clear
	  send_stats "Oracle Cloudスクリプト・コレクション"
	  echo -e "Oracle Cloudスクリプト・コレクション"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}アイドル状態のマシンのアクティブ スクリプトをインストールする"
	  echo -e "${gl_kjlan}2.   ${gl_bai}アイドル状態のマシンからアクティブなスクリプトをアンインストールする"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}3.   ${gl_bai}DD 再インストール システム スクリプト"
	  echo -e "${gl_kjlan}4.   ${gl_bai}探偵R起動スクリプト"
	  echo -e "${gl_kjlan}5.   ${gl_bai}ROOTパスワードログインモードを有効にする"
	  echo -e "${gl_kjlan}6.   ${gl_bai}IPV6回復ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in
		  1)
			  clear
			  echo "アクティブ スクリプト: CPU 使用率 10 ～ 20% メモリ使用率 20%"
			  read -e -p "インストールしてもよろしいですか? (はい/いいえ):" choice
			  case "$choice" in
				[Yy])

				  install_docker

				  # デフォルト値を設定する
				  local DEFAULT_CPU_CORE=1
				  local DEFAULT_CPU_UTIL="10-20"
				  local DEFAULT_MEM_UTIL=20
				  local DEFAULT_SPEEDTEST_INTERVAL=120

				  # ユーザーに CPU コアの数と占有率を入力するよう求めます。ユーザーが Enter キーを押すと、デフォルト値が使用されます。
				  read -e -p "CPU コアの数を入力してください [デフォルト:$DEFAULT_CPU_CORE]: " cpu_core
				  local cpu_core=${cpu_core:-$DEFAULT_CPU_CORE}

				  read -e -p "CPU 使用率の範囲 (例: 10 ～ 20) を入力してください [デフォルト:$DEFAULT_CPU_UTIL]: " cpu_util
				  local cpu_util=${cpu_util:-$DEFAULT_CPU_UTIL}

				  read -e -p "メモリ使用率を入力してください [デフォルト:$DEFAULT_MEM_UTIL]: " mem_util
				  local mem_util=${mem_util:-$DEFAULT_MEM_UTIL}

				  read -e -p "Speedtest の間隔時間 (秒) を入力してください [デフォルト:$DEFAULT_SPEEDTEST_INTERVAL]: " speedtest_interval
				  local speedtest_interval=${speedtest_interval:-$DEFAULT_SPEEDTEST_INTERVAL}

				  # Dockerコンテナを実行する
				  docker run -d --name=lookbusy --restart=always \
					  -e TZ=Asia/Shanghai \
					  -e CPU_UTIL="$cpu_util" \
					  -e CPU_CORE="$cpu_core" \
					  -e MEM_UTIL="$mem_util" \
					  -e SPEEDTEST_INTERVAL="$speedtest_interval" \
					  fogforest/lookbusy
				  send_stats "Oracle Cloudインストール・アクティブ・スクリプト"

				  ;;
				[Nn])

				  ;;
				*)
				  echo "選択が無効です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;
		  2)
			  clear
			  docker rm -f lookbusy
			  docker rmi fogforest/lookbusy
			  send_stats "Oracle Cloudアンインストール・アクティブ・スクリプト"
			  ;;

		  3)
		  clear
		  echo "システムを再インストールする"
		  echo "--------------------------------"
		  echo -e "${gl_hong}知らせ：${gl_bai}再インストールすると接続が切れる可能性がありますので、不安な方はご注意ください。再インストールには 15 分程度かかることが予想されますので、事前にデータをバックアップしてください。"
		  read -e -p "続行してもよろしいですか? (はい/いいえ):" choice

		  case "$choice" in
			[Yy])
			  while true; do
				read -e -p "再インストールするシステムを選択してください: 1. Debian12 | 2.Ubuntu20.04:" sys_choice

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
					echo "選択が無効です。再入力してください。"
					;;
				esac
			  done

			  read -e -p "再インストール後にパスワードを入力してください:" vpspasswd
			  install wget
			  bash <(wget --no-check-certificate -qO- "${gh_proxy}raw.githubusercontent.com/MoeClub/Note/master/InstallNET.sh") $xitong -v 64 -p $vpspasswd -port 22
			  send_stats "Oracle Cloud再インストールシステムスクリプト"
			  ;;
			[Nn])
			  echo "キャンセル"
			  ;;
			*)
			  echo "選択が無効です。Y または N を入力してください。"
			  ;;
		  esac
			  ;;

		  4)
			  clear
			  send_stats "探偵R起動スクリプト"
			  bash <(wget -qO- ${gh_proxy}github.com/Yohann0617/oci-helper/releases/latest/download/sh_oci-helper_install.sh)
			  ;;
		  5)
			  clear
			  add_sshpasswd
			  ;;
		  6)
			  clear
			  bash <(curl -L -s jhb.ovh/jb/v6.sh)
			  echo "この機能は jhb によって提供されています。ありがとう!"
			  send_stats "IPv6修復"
			  ;;
		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力です!"
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
		echo -e "${gl_lv}環境がインストールされました${gl_bai}容器：${gl_lv}$container_count${gl_bai}鏡：${gl_lv}$image_count${gl_bai}ネットワーク：${gl_lv}$network_count${gl_bai}ロール：${gl_lv}$volume_count${gl_bai}"
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
		echo -e "${gl_lv}環境がインストールされています${gl_bai}サイト：$outputデータベース:$db_output"
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
	# send_stats "LDNMP Web サイトの構築"
	echo -e "${gl_huang}LDNMP Web サイトの構築"
	ldnmp_tato
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}1.   ${gl_bai}LDNMP環境をインストールする${gl_huang}★${gl_bai}                   ${gl_huang}2.   ${gl_bai}WordPressをインストールする${gl_huang}★${gl_bai}"
	echo -e "${gl_huang}3.   ${gl_bai}Discuz フォーラムをインストールする${gl_huang}4.   ${gl_bai}Kedao クラウド デスクトップをインストールする"
	echo -e "${gl_huang}5.   ${gl_bai}Apple CMS ムービーおよび TV ステーションをインストールする${gl_huang}6.   ${gl_bai}Unicorn デジタル カード ネットワークをインストールする"
	echo -e "${gl_huang}7.   ${gl_bai}flarumフォーラムWebサイトをインストールする${gl_huang}8.   ${gl_bai}typecho 軽量ブログ Web サイトをインストールする"
	echo -e "${gl_huang}9.   ${gl_bai}LinkStack 共有リンク プラットフォームをインストールする${gl_huang}20.  ${gl_bai}カスタム動的サイト"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}21.  ${gl_bai}nginxのみをインストールする${gl_huang}★${gl_bai}                     ${gl_huang}22.  ${gl_bai}サイトリダイレクト"
	echo -e "${gl_huang}23.  ${gl_bai}サイト リバース プロキシ - IP+ポート${gl_huang}★${gl_bai}            ${gl_huang}24.  ${gl_bai}サイト リバース プロキシ ドメイン名"
	echo -e "${gl_huang}25.  ${gl_bai}Bitwarden パスワード管理プラットフォームをインストールする${gl_huang}26.  ${gl_bai}Halo ブログ サイトをインストールする"
	echo -e "${gl_huang}27.  ${gl_bai}AI絵画プロンプトワードジェネレーターをインストールする${gl_huang}28.  ${gl_bai}サイト リバース プロキシ負荷分散"
	echo -e "${gl_huang}29.  ${gl_bai}ストリーム 4 層プロキシ転送${gl_huang}30.  ${gl_bai}カスタム静的サイト"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}31.  ${gl_bai}サイトデータ管理${gl_huang}★${gl_bai}                    ${gl_huang}32.  ${gl_bai}サイト全体のデータをバックアップする"
	echo -e "${gl_huang}33.  ${gl_bai}スケジュールされたリモートバックアップ${gl_huang}34.  ${gl_bai}サイト全体のデータを復元する"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}35.  ${gl_bai}LDNMP環境を保護する${gl_huang}36.  ${gl_bai}LDNMP環境の最適化"
	echo -e "${gl_huang}37.  ${gl_bai}LDNMP環境を更新する${gl_huang}38.  ${gl_bai}LDNMP環境をアンインストールする"
	echo -e "${gl_huang}------------------------"
	echo -e "${gl_huang}0.   ${gl_bai}メインメニューに戻る"
	echo -e "${gl_huang}------------------------${gl_bai}"
	read -e -p "選択肢を入力してください:" sub_choice


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
	  # ディスカスフォーラム
	  webname="ディスカスフォーラム"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  wget -O latest.zip ${gh_proxy}github.com/kejilion/Website_source_code/raw/main/Discuz_X3.5_SC_UTF8_20250901.zip
	  unzip latest.zip
	  rm latest.zip

	  restart_ldnmp


	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "データベース名:$dbname"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "テーブル接頭辞: discuz_"


		;;

	  4)
	  clear
	  # Kedao クラウド デスクトップ
	  webname="Kedao クラウド デスクトップ"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  echo "データベースアドレス: mysql"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "データベース名:$dbname"
	  echo "redisホスト: redis"

		;;

	  5)
	  clear
	  # AppleCMS
	  webname="AppleCMS"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  echo "データベースアドレス: mysql"
	  echo "データベースポート: 3306"
	  echo "データベース名:$dbname"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "データベース接頭辞: mac_"
	  echo "------------------------"
	  echo "インストールが成功したら、バックエンド アドレスにログインします。"
	  echo "https://$yuming/vip.php"

		;;

	  6)
	  clear
	  # 一本足のナンバーカード
	  webname="一本足のナンバーカード"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  echo "データベースアドレス: mysql"
	  echo "データベースポート: 3306"
	  echo "データベース名:$dbname"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo ""
	  echo "redisアドレス: redis"
	  echo "redis パスワード: デフォルトでは入力されていません"
	  echo "Redis ポート: 6379"
	  echo ""
	  echo "ウェブサイトURL：https://$yuming"
	  echo "バックエンドのログイン パス: /admin"
	  echo "------------------------"
	  echo "ユーザー名: 管理者"
	  echo "パスワード: 管理者"
	  echo "------------------------"
	  echo "ログイン時に右上隅に赤色の error0 が表示される場合は、次のコマンドを使用してください。"
	  echo "私も、なぜユニコーンナンバーカードがこんなに面倒で、問題が多いのか、とても腹が立っています。"
	  echo "sed -i 's/ADMIN_HTTPS=false/ADMIN_HTTPS=true/g' /home/web/html/$yuming/dujiaoka/.env"

		;;

	  7)
	  clear
	  # フララムフォーラム
	  webname="フララムフォーラム"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/upload"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/gamification"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require fof/byobu:*"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require v17development/flarum-seo"
	  docker exec php sh -c "cd /var/www/html/$yuming && composer require clarkwinkelmann/flarum-ext-emojionearea"


	  restart_ldnmp


	  ldnmp_web_on
	  echo "データベースアドレス: mysql"
	  echo "データベース名:$dbname"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "テーブル接頭辞: flarum_"
	  echo "管理者情報を自分で設定可能"

		;;

	  8)
	  clear
	  # typecho
	  webname="typecho"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  echo "データベース接頭辞: typecho_"
	  echo "データベースアドレス: mysql"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "データベース名:$dbname"

		;;


	  9)
	  clear
	  # LinkStack
	  webname="LinkStack"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  echo "データベースアドレス: mysql"
	  echo "データベースポート: 3306"
	  echo "データベース名:$dbname"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
		;;

	  20)
	  clear
	  webname="PHP動的サイト"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  echo -e "[${gl_huang}1/6${gl_bai}] PHPソースコードをアップロードする"
	  echo "-------------"
	  echo "現在、zip 形式のソース コード パッケージのみをアップロードできます。ソースコードパッケージを/home/web/html/に置いてください。${yuming}ディレクトリの下"
	  read -e -p "ダウンロード リンクを入力して、ソース コード パッケージをリモートでダウンロードすることもできます。 Enter を直接押して、リモート ダウンロードをスキップします。" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/6${gl_bai}]index.phpが配置されているパス"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.php" -print
	  find "$(realpath .)" -name "index.php" -print | xargs -I {} dirname {}

	  read -e -p "(/home/web/html/ のような、index.php へのパスを入力してください)$yuming/wordpress/）： " index_lujing

	  sed -i "s#root /var/www/html/$yuming/#root $index_lujing#g" /home/web/conf.d/$yuming.conf
	  sed -i "s#/home/web/#/var/www/#g" /home/web/conf.d/$yuming.conf

	  clear
	  echo -e "[${gl_huang}3/6${gl_bai}] PHPバージョンを選択してください"
	  echo "-------------"
	  read -e -p "1.php最新バージョン | 2.php7.4:" pho_v
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
		  echo "選択が無効です。再入力してください。"
		  ;;
	  esac


	  clear
	  echo -e "[${gl_huang}4/6${gl_bai}] 指定された拡張機能をインストールします"
	  echo "-------------"
	  echo "インストールされている拡張機能"
	  docker exec php php -m

	  read -e -p "$(echo -e "输入需要安装的扩展名称，如 ${gl_huang}SourceGuardian imap ftp${gl_bai} 等等。直接回车将跳过安装 ： ")" php_extensions
	  if [ -n "$php_extensions" ]; then
		  docker exec $PHP_Version install-php-extensions $php_extensions
	  fi


	  clear
	  echo -e "[${gl_huang}5/6${gl_bai}] サイト構成を編集する"
	  echo "-------------"
	  echo "続行するには任意のキーを押してください。擬似静的コンテンツなどのサイト構成を詳細に設定できます。"
	  read -n 1 -s -r -p ""
	  install nano
	  nano /home/web/conf.d/$yuming.conf


	  clear
	  echo -e "[${gl_huang}6/6${gl_bai}] データベース管理"
	  echo "-------------"
	  read -e -p "1. 新しいサイトを構築します。 2. 古いサイトを構築し、データベースのバックアップを作成します。" use_db
	  case $use_db in
		  1)
			  echo
			  ;;
		  2)
			  echo "データベースのバックアップは、.gz で終わる圧縮パッケージである必要があります。 Pagoda/1panel バックアップ データのインポートをサポートするには、/home/ ディレクトリに配置してください。"
			  read -e -p "ダウンロード リンクを入力してバックアップ データをリモートでダウンロードすることもできます。 Enter を直接押して、リモート ダウンロードをスキップします。" url_download_db

			  cd /home/
			  if [ -n "$url_download_db" ]; then
				  wget "$url_download_db"
			  fi
			  gunzip $(ls -t *.gz | head -n 1)
			  latest_sql=$(ls -t *.sql | head -n 1)
			  dbrootpasswd=$(grep -oP 'MYSQL_ROOT_PASSWORD:\s*\K.*' /home/web/docker-compose.yml | tr -d '[:space:]')
			  docker exec -i mysql mysql -u root -p"$dbrootpasswd" $dbname < "/home/$latest_sql"
			  echo "データベースにインポートされたテーブルデータ"
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
	  echo "データベースアドレス: mysql"
	  echo "データベース名:$dbname"
	  echo "ユーザー名:$dbuse"
	  echo "パスワード：$dbusepasswd"
	  echo "テーブルの接頭辞:$prefix"
	  echo "管理者のログイン情報は自分で設定します"

		;;


	  21)
	  ldnmp_install_status_one
	  nginx_install_all
		;;

	  22)
	  clear
	  webname="サイトリダイレクト"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
	  add_yuming
	  read -e -p "リダイレクト ドメイン名を入力してください:" reverseproxy
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
		echo "IP+ポートはサービスへのアクセスをブロックされています"
	  else
	  	ip_address
		close_port "$port"
		block_container_port "$docker_name" "$ipv4_address"
	  fi

		;;

	  24)
	  clear
	  webname="リバースプロキシドメイン名"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
	  add_yuming
	  echo -e "ドメイン名の形式:${gl_huang}google.com${gl_bai}"
	  read -e -p "リバース プロキシ ドメイン名を入力してください:" fandai_yuming
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
	  echo "導入を開始する$webname"
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
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
	  add_yuming

	  docker run -d --name halo --restart=always -p 8010:8090 -v /home/web/html/$yuming/.halo2:/root/.halo2 halohub/halo:2

	  duankou=8010
	  ldnmp_Proxy ${yuming} 127.0.0.1 $duankou

		;;

	  27)
	  clear
	  webname="AI絵画プロンプトワードジェネレーター"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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


	  29)
	  stream_panel
		;;

	  30)
	  clear
	  webname="静的サイト"
	  send_stats "インストール$webname"
	  echo "導入を開始する$webname"
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
	  echo -e "[${gl_huang}1/2${gl_bai}] 静的ソースコードをアップロードする"
	  echo "-------------"
	  echo "現在、zip 形式のソース コード パッケージのみをアップロードできます。ソースコードパッケージを/home/web/html/に置いてください。${yuming}ディレクトリの下"
	  read -e -p "ダウンロード リンクを入力して、ソース コード パッケージをリモートでダウンロードすることもできます。 Enter を直接押して、リモート ダウンロードをスキップします。" url_download

	  if [ -n "$url_download" ]; then
		  wget "$url_download"
	  fi

	  unzip $(ls -t *.zip | head -n 1)
	  rm -f $(ls -t *.zip | head -n 1)

	  clear
	  echo -e "[${gl_huang}2/2${gl_bai}]index.html が配置されているパス"
	  echo "-------------"
	  # find "$(realpath .)" -name "index.html" -print
	  find "$(realpath .)" -name "index.html" -print | xargs -I {} dirname {}

	  read -e -p "(/home/web/html/ のような、index.html へのパスを入力してください)$yuming/index/）： " index_lujing

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
	  send_stats "LDNMP環境のバックアップ"

	  local backup_filename="web_$(date +"%Y%m%d%H%M%S").tar.gz"
	  echo -e "${gl_kjlan}バックアップ中$backup_filename ...${gl_bai}"
	  cd /home/ && tar czvf "$backup_filename" web

	  while true; do
		clear
		echo "バックアップファイルが作成されました: /home/$backup_filename"
		read -e -p "バックアップ データをリモート サーバーに転送しますか? (はい/いいえ):" choice
		case "$choice" in
		  [Yy])
			kj_ssh_read_host_port "リモートサーバーのIPを入力してください:" "ターゲット サーバーの SSH ポート [デフォルト 22]:" "22"
			local remote_ip="$KJ_SSH_HOST"
			local TARGET_PORT="$KJ_SSH_PORT"
			local latest_tar=$(ls -t /home/*.tar.gz | head -1)
			if [ -n "$latest_tar" ]; then
			  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
			  sleep 2  # 添加等待时间
			  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/home/"
			  echo "ファイルはリモート サーバーのホーム ディレクトリに転送されました。"
			else
			  echo "転送するファイルが見つかりませんでした。"
			fi
			break
			;;
		  [Nn])
			break
			;;
		  *)
			echo "選択が無効です。Y または N を入力してください。"
			;;
		esac
	  done
	  ;;

	33)
	  clear
	  send_stats "スケジュールされたリモートバックアップ"
	  read -e -p "リモート サーバーの IP を入力します。" useip
	  read -e -p "リモートサーバーのパスワードを入力してください:" usepasswd

	  cd ~
	  wget -O ${useip}_beifen.sh ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/beifen.sh > /dev/null 2>&1
	  chmod +x ${useip}_beifen.sh

	  sed -i "s/0.0.0.0/$useip/g" ${useip}_beifen.sh
	  sed -i "s/123456/$usepasswd/g" ${useip}_beifen.sh

	  echo "------------------------"
	  echo "1. 毎週のバックアップ 2. 毎日のバックアップ"
	  read -e -p "選択肢を入力してください:" dingshi

	  case $dingshi in
		  1)
			  check_crontab_installed
			  read -e -p "毎週のバックアップの曜日を選択します (0 ～ 6、0 は日曜日を表します)。" weekday
			  (crontab -l ; echo "0 0 * * $weekday ./${useip}_beifen.sh") | crontab - > /dev/null 2>&1
			  ;;
		  2)
			  check_crontab_installed
			  read -e -p "毎日のバックアップ時間 (時間、0 ～ 23) を選択します。" hour
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
	  send_stats "LDNMP環境の復元"
	  echo "利用可能なサイトのバックアップ"
	  echo "-------------------------"
	  ls -lt /home/*.gz | awk '{print $NF}'
	  echo ""
	  read -e -p  "Enter キーを押して最新のバックアップを復元し、バックアップ ファイル名を入力して指定したバックアップを復元し、0 を入力して終了します。" filename

	  if [ "$filename" == "0" ]; then
		  break_end
		  linux_ldnmp
	  fi

	  # ユーザーがファイル名を入力しない場合は、最新の圧縮パッケージが使用されます。
	  if [ -z "$filename" ]; then
		  local filename=$(ls -t /home/*.tar.gz | head -1)
	  fi

	  if [ -n "$filename" ]; then
		  cd /home/web/ > /dev/null 2>&1
		  docker compose down > /dev/null 2>&1
		  rm -rf /home/web > /dev/null 2>&1

		  echo -e "${gl_kjlan}解凍中$filename ...${gl_bai}"
		  cd /home/ && tar -xzf "$filename"

		  install_dependency
		  install_docker
		  install_certbot
		  install_ldnmp
	  else
		  echo "圧縮パッケージが見つかりませんでした。"
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
		  send_stats "LDNMP環境を更新する"
		  echo "LDNMP環境を更新する"
		  echo "------------------------"
		  ldnmp_v
		  echo "新しいバージョンのコンポーネントが見つかりました"
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
		  echo "1. nginx を更新します。 2. mysql を更新します。 3. php を更新します。 4. redis を更新します。"
		  echo "------------------------"
		  echo "5. 環境全体を更新する"
		  echo "------------------------"
		  echo "0. 前のメニューに戻る"
		  echo "------------------------"
		  read -e -p "選択肢を入力してください:" sub_choice
		  case $sub_choice in
			  1)
			  nginx_upgrade

				  ;;

			  2)
			  local ldnmp_pods="mysql"
			  read -e -p "入力してください${ldnmp_pods}バージョン番号 (例: 8.0 8.3 8.4 9.0) (Enter キーを押して最新バージョンを取得します):" version
			  local version=${version:-latest}

			  cd /home/web/
			  cp /home/web/docker-compose.yml /home/web/docker-compose1.yml
			  sed -i "s/image: mysql/image: mysql:${version}/" /home/web/docker-compose.yml
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods
			  cp /home/web/docker-compose1.yml /home/web/docker-compose.yml
			  send_stats "更新する$ldnmp_pods"
			  echo "更新する${ldnmp_pods}仕上げる"

				  ;;
			  3)
			  local ldnmp_pods="php"
			  read -e -p "入力してください${ldnmp_pods}バージョン番号 (例: 7.4 8.0 8.1 8.2 8.3) (Enter キーを押して最新バージョンを取得します):" version
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
			  send_stats "更新する$ldnmp_pods"
			  echo "更新する${ldnmp_pods}仕上げる"

				  ;;
			  4)
			  local ldnmp_pods="redis"
			  cd /home/web/
			  docker rm -f $ldnmp_pods
			  docker images --filter=reference="$ldnmp_pods*" -q | xargs docker rmi > /dev/null 2>&1
			  docker compose up -d --force-recreate $ldnmp_pods
			  docker restart $ldnmp_pods > /dev/null 2>&1
			  send_stats "更新する$ldnmp_pods"
			  echo "更新する${ldnmp_pods}仕上げる"

				  ;;
			  5)
				read -e -p "$(echo -e "${gl_huang}提示: ${gl_bai}长时间不更新环境的用户，请慎重更新LDNMP环境，会有数据库更新失败的风险。确定更新LDNMP环境吗？(Y/N): ")" choice
				case "$choice" in
				  [Yy])
					send_stats "LDNMP環境の完全アップデート"
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
		send_stats "LDNMP環境をアンインストールする"
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
			echo "選択が無効です。Y または N を入力してください。"
			;;
		esac
		;;

	0)
		kejilion
	  ;;

	*)
		echo "無効な入力です!"
	esac
	break_end

  done

}






moltbot_menu() {
	local app_id="114"

	send_stats "クロードボット/モルトボットの管理"

	check_openclaw_update() {
		if ! command -v npm >/dev/null 2>&1; then
			return 1
		fi

		# --no-update-notifier を追加し、エラー リダイレクトが正しい場所にあることを確認します。
		local_version=$(npm list -g openclaw --depth=0 --no-update-notifier 2>/dev/null | grep openclaw | awk '{print $NF}' | sed 's/^.*@//')

		if [ -z "$local_version" ]; then
			return 1
		fi

		remote_version=$(npm view openclaw version --no-update-notifier 2>/dev/null)

		if [ -z "$remote_version" ]; then
			return 1
		fi

		if [ "$local_version" != "$remote_version" ]; then
			echo "${gl_huang}新しいバージョンが検出されました:$remote_version${gl_bai}"
		else
			echo "${gl_lv}現在のバージョンは最新です:$local_version${gl_bai}"
		fi
	}


	get_install_status() {
		if command -v openclaw >/dev/null 2>&1; then
			echo "${gl_lv}インストール済み${gl_bai}"
		else
			echo "${gl_hui}インストールされていません${gl_bai}"
		fi
	}

	get_running_status() {
		if pgrep -f "openclaw-gatewa" >/dev/null 2>&1; then
			echo "${gl_lv}ランニング${gl_bai}"
		else
			echo "${gl_hui}稼働していない${gl_bai}"
		fi
	}


	show_menu() {


		clear

		local install_status=$(get_install_status)
		local running_status=$(get_running_status)
		local update_message=$(check_openclaw_update)

		echo "======================================="
		echo -e "ClawdBot > MoltBot > OpenClaw 管理"
		echo -e "$install_status $running_status $update_message"
		echo "======================================="
		echo "1. インストール"
		echo "2.スタート"
		echo "3. 停止"
		echo "--------------------"
		echo "4. ステータスログの表示"
		echo "5.機種変更"
		echo "6. API管理"
		echo "7. ロボットの接続とドッキング"
		echo "8. プラグイン管理（インストール・削除）"
		echo "9. スキル管理（設置・撤去）"
		echo "10. メイン設定ファイルを編集します"
		echo "11. 設定ウィザード"
		echo "12. 健全性の検出と修復"
		echo "13. WebUI へのアクセスと設定"
		echo "14. TUIコマンドラインダイアログウィンドウ"
		echo "15. 記憶・記憶"
		echo "--------------------"
		echo "16. バックアップと復元"
		echo "17. アップデート"
		echo "18. アンインストール"
		echo "--------------------"
		echo "0. 前のメニューに戻る"
		echo "--------------------"
		printf "オプションを入力して Enter を押してください:"
	}


	start_gateway() {
		openclaw gateway stop
		openclaw gateway start
		sleep 3
	}


	install_node_and_tools() {
		if command -v dnf &>/dev/null; then
			curl -fsSL https://rpm.nodesource.com/setup_24.x | sudo bash -
			dnf update -y
			dnf group install -y "Development Tools" "Development Libraries"
			dnf install -y cmake libatomic nodejs
		fi

		if command -v apt &>/dev/null; then
			curl -fsSL https://deb.nodesource.com/setup_24.x | bash -
			apt update -y
			apt install build-essential python3 libatomic1 nodejs -y
		fi
	}

	configure_openclaw_session_policy() {
		local config_file="${HOME}/.openclaw/openclaw.json"

		[ ! -f "$config_file" ] && return 1

		python3 - "$config_file" <<'PY'
import json, sys
path = sys.argv[1]
with open(path, 'r', encoding='utf-8') as f:
    obj = json.load(f)

session = obj.setdefault('session', {})
session['dmScope'] = session.get('dmScope', 'per-channel-peer')
session['resetTriggers'] = ['/new', '/reset']
session['reset'] = {
    'mode': 'idle',
    'idleMinutes': 10080
}
session['resetByType'] = {
    'direct': {'mode': 'idle', 'idleMinutes': 10080},
    'thread': {'mode': 'idle', 'idleMinutes': 1440},
    'group': {'mode': 'idle', 'idleMinutes': 120}
}

with open(path, 'w', encoding='utf-8') as f:
    json.dump(obj, f, ensure_ascii=False, indent=2)
    f.write('\n')
PY
	}


	sync_openclaw_api_models() {
		local config_file="${HOME}/.openclaw/openclaw.json"

		[ ! -f "$config_file" ] && return 0

		install jq curl >/dev/null 2>&1

		python3 - "$config_file" "$ENABLE_STATS" "$sh_v" <<'PY'
import copy
import json
import os
import platform
import sys
import time
import urllib.request
from datetime import datetime, timezone

path = sys.argv[1]
stats_enabled = (sys.argv[2].lower() == "true") if len(sys.argv) > 2 else True
script_version = sys.argv[3] if len(sys.argv) > 3 else ""

def probe_endpoint(base_url, api_key, path, timeout=6):
    url = base_url.rstrip('/') + path
    req = urllib.request.Request(
        url,
        data=b'{}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'OpenClaw-API-Manage/1.0',
        },
        method='POST',
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.getcode(), None
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return None, e


def detect_api_protocol(base_url, api_key):
    code, err = probe_endpoint(base_url, api_key, '/responses')
    if code is not None and code not in (404, 405):
        return 'openai-responses', f'POST /responses -> HTTP {code}', None
    if err:
        return 'openai-completions', 'fallback: probe failed', err
    return 'openai-completions', f'POST /responses={code} -> fallback /completions', None


def send_stat(action):
    if not stats_enabled:
        return
    payload = {
        "action": action,
        "timestamp": datetime.now(timezone.utc).strftime("%Y-%m-%d %H:%M:%S"),
        "country": "",
        "os_info": platform.platform(),
        "cpu_arch": platform.machine(),
        "version": script_version,
    }
    try:
        req = urllib.request.Request(
            "https://api.kejilion.pro/api/log",
            data=json.dumps(payload).encode("utf-8"),
            headers={"Content-Type": "application/json"},
            method="POST",
        )
        with urllib.request.urlopen(req, timeout=3):
            pass
    except Exception:
        pass

with open(path, 'r', encoding='utf-8') as f:
    obj = json.load(f)

work = copy.deepcopy(obj)
models_cfg = work.setdefault('models', {})
providers = models_cfg.get('providers', {})
if not isinstance(providers, dict) or not providers:
    print('ℹ️ API プロバイダーが検出されず、モデルの同期がスキップされました')
    raise SystemExit(0)

agents = work.setdefault('agents', {})
defaults = agents.setdefault('defaults', {})
defaults_models_raw = defaults.get('models')
if isinstance(defaults_models_raw, dict):
    defaults_models = defaults_models_raw
elif isinstance(defaults_models_raw, list):
    defaults_models = {str(x): {} for x in defaults_models_raw if isinstance(x, str)}
else:
    defaults_models = {}
defaults['models'] = defaults_models

SUPPORTED_APIS = {'openai-completions', 'openai-responses'}

changed = False
fatal_errors = []
summary = []


def model_ref(provider_name, model_id):
    return f"{provider_name}/{model_id}"


def get_primary_ref(defaults_obj):
    model_obj = defaults_obj.get('model')
    if isinstance(model_obj, str):
        return model_obj
    if isinstance(model_obj, dict):
        primary = model_obj.get('primary')
        if isinstance(primary, str):
            return primary
    return None


def set_primary_ref(defaults_obj, new_ref):
    model_obj = defaults_obj.get('model')
    if isinstance(model_obj, str):
        defaults_obj['model'] = new_ref
    elif isinstance(model_obj, dict):
        model_obj['primary'] = new_ref
    else:
        defaults_obj['model'] = {'primary': new_ref}


def ref_provider(ref):
    if not isinstance(ref, str) or '/' not in ref:
        return None
    return ref.split('/', 1)[0]


def collect_available_refs(exclude_provider=None):
    refs = []
    if not isinstance(providers, dict):
        return refs
    for pname, p in providers.items():
        if exclude_provider and pname == exclude_provider:
            continue
        if not isinstance(p, dict):
            continue
        for m in p.get('models', []) or []:
            if isinstance(m, dict) and m.get('id'):
                refs.append(model_ref(pname, str(m['id'])))
    return refs


def prompt_delete_provider(name):
    prompt = f"⚠️ {name} /models プローブは 3 回連続で失敗しました。この API プロバイダーとすべての関連モデルを削除しますか? [y/N]:"
    try:
        ans = input(prompt).strip().lower()
    except EOFError:
        return False
    return ans in ('y', 'yes')


def rebind_defaults_before_delete(name):
    global changed

    replacement = None

    def get_replacement():
        nonlocal replacement
        if replacement is None:
            candidates = collect_available_refs(exclude_provider=name)
            replacement = candidates[0] if candidates else None
        return replacement

    primary_ref = get_primary_ref(defaults)
    if ref_provider(primary_ref) == name:
        repl = get_replacement()
        if not repl:
            summary.append(f'❌ {name}: デフォルトのメイン モデルはこのプロバイダーを指していますが、利用可能な代替モデルがないため、削除は中止されました。')
            return False
        set_primary_ref(defaults, repl)
        changed = True
        summary.append(f'🔁 デフォルトのプライマリ モデルは削除前に切り替えられています: {primary_ref} -> {repl}')

    for fk in ('modelFallback', 'imageModelFallback'):
        val = defaults.get(fk)
        if ref_provider(val) == name:
            repl = get_replacement()
            if not repl:
                summary.append(f'❌ {name}: {fk} はプロバイダーを指しますが、使用可能な代替モデルがないため、削除は中止されました')
                return False
            defaults[fk] = repl
            changed = True
            summary.append(f'🔁 削除前に切り替えられた {fk}: {val} -> {repl}')

    return True


def delete_provider_and_refs(name):
    global changed

    if not rebind_defaults_before_delete(name):
        return False

    removed_refs = [r for r in list(defaults_models.keys()) if r.startswith(name + '/')]
    for r in removed_refs:
        defaults_models.pop(r, None)
    if removed_refs:
        changed = True

    if name in providers:
        providers.pop(name, None)
        changed = True

    summary.append(f'🗑️ プロバイダー {name} が削除され、defaults.models の下の {len(removed_refs)} モデル参照が削除されました')
    return True


def probe_endpoint(base_url, api_key, path, timeout=6):
    url = base_url.rstrip('/') + path
    req = urllib.request.Request(
        url,
        data=b'{}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'OpenClaw-API-Manage/1.0',
        },
        method='POST',
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.getcode(), None
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return None, e


def detect_api_protocol(base_url, api_key):
    code, err = probe_endpoint(base_url, api_key, '/responses')
    if code is not None and code not in (404, 405):
        return 'openai-responses', f'POST /responses -> HTTP {code}', None
    if err:
        return 'openai-completions', 'fallback: probe failed', err
    return 'openai-completions', f'POST /responses={code} -> fallback /completions', None


def fetch_remote_models_with_retry(name, base_url, api_key, retries=3):
    last_error = None
    for attempt in range(1, retries + 1):
        req = urllib.request.Request(
            base_url.rstrip('/') + '/models',
            headers={
                'Authorization': f'Bearer {api_key}',
                'User-Agent': 'Mozilla/5.0',
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                payload = resp.read().decode('utf-8', 'ignore')
            data = json.loads(payload)
            return data, None, attempt
        except Exception as e:
            last_error = e
            if attempt < retries:
                time.sleep(1)
    return None, last_error, retries


for name, provider in list(providers.items()):
    if not isinstance(provider, dict):
        summary.append(f'ℹ️ {name} をスキップ: プロバイダー構造が不正です')
        continue

    api = provider.get('api', '')
    base_url = provider.get('baseUrl')
    api_key = provider.get('apiKey')
    model_list = provider.get('models', [])

    if not base_url or not api_key or not isinstance(model_list, list) or not model_list:
        summary.append(f'ℹ️ {name} をスキップ: なしbaseUrl/apiKey/models')
        continue

    if api not in SUPPORTED_APIS:
        summary.append(f'🔁 {name}: 不正なプロトコル {api または "(unset)"} が見つかりました。再検出されます')
        provider['api'] = ''
        api = ''
        changed = True

    try:
        detected_api, detected_reason, detect_err = detect_api_protocol(base_url, api_key)
        if detected_api and api != detected_api:
            provider['api'] = detected_api
            api = detected_api
            changed = True
            summary.append(f'🔁 {name}: プロトコルは自動的に {detected_api} ({detected_reason}) に修正されました')
    except Exception as e:
        summary.append(f'⚠️ {name}: プロトコルの検出に失敗しました。修正をスキップします ({type(e).__name__}: {e})')

    data, err, attempts = fetch_remote_models_with_retry(name, base_url, api_key, retries=3)
    if err is not None:
        summary.append(f'⚠️ {name}: /models の検出に失敗しました。{attempts} 回再試行しました ({type(err).__name__}: {err})')
        send_stat('OpenClaw API は介入を確認しました')
        if prompt_delete_provider(name):
            deleted = delete_provider_and_refs(name)
            if deleted:
                send_stat('OpenClaw API の削除に失敗しましたプロバイダー確認')
                summary.append(f'✅ {name}: ユーザーはプロバイダーとすべての関連モデル参照を削除することを確認しました')
        else:
            send_stat('OpenClaw API の削除に失敗しましたプロバイダーによって拒否されました')
            summary.append(f'ℹ️ {name}: ユーザーは削除を確認しておらず、既存のプロバイダー構成を保持しています。')
        continue

    if attempts > 1:
        summary.append(f'🔁 {name}: /models {attempts} 回の再試行後に成功しました')

    if not (isinstance(data, dict) and isinstance(data.get('data'), list)):
        summary.append(f'⚠️ {name} をスキップ: /models 戻り構造が認識されません')
        continue

    remote_ids = []
    for item in data['data']:
        if isinstance(item, dict) and item.get('id'):
            remote_ids.append(str(item['id']))
    remote_set = set(remote_ids)

    if not remote_set:
        fatal_errors.append(f'❌ {name} の上流 /models は空であるため、このプロバイダーにボトムアップ モデルを提供できません。')
        continue

    local_models = [m for m in model_list if isinstance(m, dict) and m.get('id')]
    local_ids = [str(m['id']) for m in local_models]
    local_set = set(local_ids)

    template = None
    for m in local_models:
        template = copy.deepcopy(m)
        break
    if template is None:
        summary.append(f'⚠️ {name} をスキップ: ローカル モデルに有効なテンプレート モデルがありません')
        continue

    removed_ids = [mid for mid in local_ids if mid not in remote_set]
    added_ids = [mid for mid in remote_ids if mid not in local_set]

    if added_ids:
        summary.append(f'➕ 新しいモデルを追加します ({len(added_ids)}):')
        for mid in added_ids:
            summary.append(f'  + {mid}')
    if removed_ids:
        summary.append(f'➖ モデルを削除します ({len(removed_ids)}):')
        for mid in removed_ids:
            summary.append(f'  - {mid}')

    kept_models = [copy.deepcopy(m) for m in local_models if str(m['id']) in remote_set]
    new_models = kept_models[:]

    for mid in added_ids:
        nm = copy.deepcopy(template)
        nm['id'] = mid
        if isinstance(nm.get('name'), str):
            nm['name'] = f'{name} / {mid}'
        new_models.append(nm)

    if not new_models:
        fatal_errors.append(f'❌ {name} には同期後に使用可能なモデルがなく、デフォルト モデル/フォールバック モデルは保証されません。')
        continue

    expected_refs = {model_ref(name, str(m['id'])) for m in new_models if isinstance(m, dict) and m.get('id')}
    local_refs = {model_ref(name, mid) for mid in local_ids}

    first_ref = model_ref(name, str(new_models[0]['id']))

    primary_ref = get_primary_ref(defaults)
    if isinstance(primary_ref, str) and primary_ref in (local_refs - expected_refs):
        set_primary_ref(defaults, first_ref)
        changed = True
        summary.append(f'🔁 デフォルトのモデルは完全に置き換えられました: {primary_ref} -> {first_ref}')

    for fk in ('modelFallback', 'imageModelFallback'):
        val = defaults.get(fk)
        if isinstance(val, str) and val in (local_refs - expected_refs):
            defaults[fk] = first_ref
            changed = True
            summary.append(f'🔁 {fk} は完全に置き換えられました: {val} -> {first_ref}')

    stale_refs = [r for r in list(defaults_models.keys()) if r.startswith(name + '/') and r not in expected_refs]
    for r in stale_refs:
        defaults_models.pop(r, None)
        changed = True

    for r in sorted(expected_refs):
        if r not in defaults_models:
            defaults_models[r] = {}
            changed = True

    if removed_ids or added_ids or len(local_models) != len(new_models):
        provider['models'] = new_models
        changed = True

    summary.append(f'✅ {name}: {len(removed_ids)} を削除、{len(added_ids)} を追加、現在の {len(new_models)}')

if fatal_errors:
    for line in summary:
        print(line)
    for err in fatal_errors:
        print(err)
    print('❌ モデルの同期に失敗しました: プロバイダーがあります。同期後、使用可能なモデルが存在しないため、書き込みは中止されました。')
    raise SystemExit(2)

if changed:
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(work, f, ensure_ascii=False, indent=2)
        f.write('\n')
    for line in summary:
        print(line)
    print('✅ OpenClaw API モデルの整合性同期が完了し、設定が書き込まれました')
else:
    for line in summary:
        print(line)
    print('ℹ️ 同期は必要ありません: 構成はすでに上流の /models と一致しています')
PY
	}



	install_moltbot() {
		echo "OpenClaw のインストールを開始します..."
		send_stats "OpenClaw のインストールを開始します..."

		install_node_and_tools

		country=$(curl -s ipinfo.io/country)
		if [[ "$country" == "CN" || "$country" == "HK" ]]; then
			npm config set registry https://registry.npmmirror.com
		fi

		git config --global url."${gh_https_url}github.com/".insteadOf ssh://git@github.com/
		git config --global url."${gh_https_url}github.com/".insteadOf git@github.com:

		npm install -g openclaw@latest
		openclaw onboard --install-daemon
		openclaw config set tools.profile full
		# ヒント: 構成を変更してすぐに有効にする必要がある場合は、ゲートウェイを再起動します: openclaw ゲートウェイの再起動
		configure_openclaw_session_policy
		start_gateway
		add_app_id
		break_end

	}


	start_bot() {
		echo "OpenClaw を開始しています..."
		send_stats "OpenClaw を開始しています..."
		start_gateway
		break_end
	}

	stop_bot() {
		echo "OpenClaw を停止します..."
		send_stats "OpenClaw を停止します..."
		tmux kill-session -t gateway > /dev/null 2>&1
		openclaw gateway stop
		break_end
	}

	view_logs() {
		echo "OpenClaw ステータス ログを表示する"
		send_stats "OpenClaw ログを表示する"
		openclaw status
		openclaw gateway status
		openclaw logs
		break_end
	}





	# OpenClaw API プロトコル検出 (優先応答 -> 完了)
	openclaw_probe_api_endpoint() {
		local base_url="$1"
		local api_key="$2"
		local path="$3"
		local url="${base_url%/}${path}"
		local http_code
		http_code=$(curl -s -o /dev/null -w "%{http_code}" -m 8 \
			-X POST \
			-H "Authorization: Bearer $api_key" \
			-H "Content-Type: application/json" \
			-d '{}' "$url" 2>/dev/null || echo "000")
		if [ -z "$http_code" ]; then
			http_code="000"
		fi
		echo "$http_code"
	}

	openclaw_detect_api_protocol() {
		local base_url="$1"
		local api_key="$2"
		local code_responses="000"

		DETECTED_API="openai-completions"
		DETECTED_REASON="fallback: /responses not supported"

		code_responses=$(openclaw_probe_api_endpoint "$base_url" "$api_key" "/responses")
		if [[ "$code_responses" != "404" && "$code_responses" != "405" && "$code_responses" != "000" ]]; then
			DETECTED_API="openai-responses"
			DETECTED_REASON="POST /responses -> HTTP $code_responses"
			return 0
		fi

		DETECTED_API="openai-completions"
		DETECTED_REASON="POST /responses=$code_responses -> fallback /completions"
		return 0
	}

	# コア機能: すべてのモデルの取得と追加
	add-all-models-from-provider() {
		local provider_name="$1"
		local base_url="$2"
		local api_key="$3"
		local config_file="${HOME}/.openclaw/openclaw.json"

		echo "🔍 取得中$provider_name利用可能なすべてのモデル..."

		# API プロトコルを自動的に識別する
		install curl >/dev/null 2>&1
		openclaw_detect_api_protocol "$base_url" "$api_key"

		# モデルリストの取得
		local models_json=$(curl -s -m 10 \
			-H "Authorization: Bearer $api_key" \
			"${base_url}/models")

		if [[ -z "$models_json" ]]; then
			echo "❌ モデルリストを取得できません"
			return 1
		fi

		# すべてのモデル ID を抽出します
		local model_ids=$(echo "$models_json" | grep -oP '"id":\s*"\K[^"]+')

		if [[ -z "$model_ids" ]]; then
			echo "❌ モデルが見つかりません"
			return 1
		fi

		local model_count=$(echo "$model_ids" | wc -l)
		echo "✅ 発見する$model_countモデル"

		# モデルパラメータのインテリジェントな推論
		local models_array="["
		local first=true

		while read -r model_id; do
			[[ $first == false ]] && models_array+=","
			first=false

			# context と max_tokens は完全にロードされているため、大きな問題を恐れる必要はありません
			local context_window=1048576
			local max_tokens=128000

			# 評価する必要があるのは価格だけです
			local input_cost=0.15
			local output_cost=0.60

			case "$model_id" in
				*opus*|*pro*|*preview*|*thinking*|*sonnet*)
					input_cost=2.00
					output_cost=12.00
					;;
				*gpt-5*|*codex*)
					input_cost=1.25
					output_cost=10.00
					;;
				*flash*|*lite*|*haiku*|*mini*|*nano*)
					input_cost=0.10
					output_cost=0.40
					;;
			esac

			models_array+=$(cat <<EOF
{
	"id": "$model_id",
	"name": "$provider_name / $model_id",
	"input": ["text", "image"],
	"contextWindow": $context_window,
	"maxTokens": $max_tokens,
	"cost": {
		"input": $input_cost,
		"output": $output_cost,
		"cacheRead": 0,
		"cacheWrite": 0
	}
}
EOF
)
		done <<< "$model_ids"

		models_array+="]"

		# バックアップ構成
		[[ -f "$config_file" ]] && cp "$config_file" "${config_file}.bak.$(date +%s)"

		# jq を使用してすべてのモデルを挿入し、defaults.models を同期します。
		jq --arg prov "$provider_name" \
		   --arg url "$base_url" \
		   --arg key "$api_key" \
		   --arg api "$DETECTED_API" \
		   --argjson models "$models_array" \
		'
		.models |= (
			(. // { mode: "merge", providers: {} })
			| .mode = "merge"
			| .providers[$prov] = {
				baseUrl: $url,
				apiKey: $key,
				api: $api,
				models: $models
			}
		)
		| .agents |= (. // {})
		| .agents.defaults |= (. // {})
		| .agents.defaults.models |= (
			(if type == "object" then .
			 elif type == "array" then reduce .[] as $m ({}; if ($m|type) == "string" then .[$m] = {} else . end)
			 else {}
			 end) as $existing
			| reduce ($models[]? | .id? // empty | tostring) as $mid (
				$existing;
				if ($mid | length) > 0 then
					.["\($prov)/\($mid)"] //= {}
				else
					.
				end
			)
		)
		' "$config_file" > "${config_file}.tmp" && mv "${config_file}.tmp" "$config_file"

		if [[ $? -eq 0 ]]; then
			echo "✅ 正常に追加されました$model_countモデルが到着$provider_name"
			echo "📦 モデル参照形式:$provider_name/<model-id>"
			return 0
		else
			echo "❌ 構成の挿入に失敗しました"
			return 1
		fi
	}

	add-openclaw-provider-interactive() {
		send_stats "OpenClaw API が追加されました"
		echo "=== OpenClaw プロバイダー (フルモデル) を対話的に追加 ==="

		# 1.プロバイダ名
		read -erp "プロバイダー名を入力してください (例: deepseek):" provider_name
		while [[ -z "$provider_name" ]]; do
			echo "❌ プロバイダー名を空にすることはできません"
			read -erp "プロバイダー名を入力してください:" provider_name
		done

		# 2. Base URL
		read -erp "ベース URL (例: https://api.xxx.com/v1) を入力してください:" base_url
		while [[ -z "$base_url" ]]; do
			echo "❌ ベース URL を空にすることはできません"
			read -erp "ベース URL を入力してください:" base_url
		done
		base_url="${base_url%/}"

		# 3. API Key
		read -rsp "API キーを入力してください (入力は表示されません):" api_key
		echo
		while [[ -z "$api_key" ]]; do
			echo "❌ API キーを空にすることはできません"
			read -rsp "API キーを入力してください:" api_key
			echo
		done

		# 4. プロトコル検出 (無意味)
		install curl >/dev/null 2>&1
		openclaw_detect_api_protocol "$base_url" "$api_key"

		# 5. モデルリストの取得
		echo "🔍 利用可能なモデルのリストを取得中..."
		models_json=$(curl -s -m 10 \
			-H "Authorization: Bearer $api_key" \
			"${base_url}/models")

		if [[ -n "$models_json" ]]; then
			available_models=$(echo "$models_json" | grep -oP '"id":\s*"\K[^"]+' | sort)

			if [[ -n "$available_models" ]]; then
				model_count=$(echo "$available_models" | wc -l)
				echo "✅ 発見する$model_count利用可能なモデル:"
				echo "--------------------------------"
				# すべて表示 (シリアル番号付き)
				i=1
				model_list=()
				while read -r model; do
					echo "[$i] $model"
					model_list+=("$model")
					((i++))
				done <<< "$available_models"
				echo "--------------------------------"
			fi
		fi

		# 5. デフォルトのモデルを選択します
		echo
		read -erp "デフォルトのモデル ID (またはシリアル番号、最初のものを使用する場合は空白のままにしておきます) を入力してください:" input_model

		if [[ -z "$input_model" && -n "$available_models" ]]; then
			default_model=$(echo "$available_models" | head -1)
			echo "🎯 最初のモデルの使用:$default_model"
		elif [[ "$input_model" =~ ^[0-9]+$ ]] && [ "${#model_list[@]}" -gt 0 ] && [ "$input_model" -ge 1 ] && [ "$input_model" -le "${#model_list[@]}" ]; then
			default_model="${model_list[$((input_model-1))]}"
			echo "🎯 選択されたモデル:$default_model"
		else
			default_model="$input_model"
		fi

		# 6. 情報の確認
		echo
		echo "====== 確認 ======"
		echo "Provider    : $provider_name"
		echo "Base URL    : $base_url"
		echo "API Key     : ${api_key:0:8}****"
		echo "デフォルトのモデル:$default_model"
		echo "モデルの総数:$model_count"
		echo "======================"

		read -erp "すべて追加することを確認します$model_countA model? (y/N):" confirm
		if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
			echo "❎ キャンセルされました"
			return 1
		fi

		install jq
		add-all-models-from-provider "$provider_name" "$base_url" "$api_key"

		if [[ $? -eq 0 ]]; then
			echo
			echo "🔄 设置默认模型并重启网关..."
			openclaw models set "$provider_name/$default_model"
			start_gateway
			echo "✅完了！全て$model_countロードされたモデル"
			echo "✅ 契約は次のように自動的に識別されます。$DETECTED_API"
		fi

		break_end
	}


	
openclaw_api_manage_list() {
	local config_file="${HOME}/.openclaw/openclaw.json"
	send_stats "OpenClaw API リスト"

	while IFS=$'\t' read -r rec_type idx name base_url model_count api_type latency_txt latency_level; do
		case "$rec_type" in
			MSG)
				echo "$idx"
				;;
			ROW)
				local latency_color="$gl_bai"
				case "$latency_level" in
					low) latency_color="$gl_lv" ;;
					medium) latency_color="$gl_huang" ;;
					high|unavailable) latency_color="$gl_hong" ;;
					unchecked) latency_color="$gl_bai" ;;
				esac

				printf '%b\n' "[$idx] ${name} | API: ${base_url}|合意：${api_type}|モデル数:${gl_huang}${model_count}${gl_bai}|遅延/ステータス:${latency_color}${latency_txt}${gl_bai}"
				;;
		esac
	done < <(python3 - "$config_file" <<-'PY'
import json
import sys
import time
import urllib.request

path = sys.argv[1]
SUPPORTED_APIS = {'openai-completions', 'openai-responses'}


def ping_models(base_url, api_key):
    req = urllib.request.Request(
        base_url.rstrip('/') + '/models',
        headers={
            'Authorization': f'Bearer {api_key}',
            'User-Agent': 'OpenClaw-API-Manage/1.0',
        },
    )
    start = time.perf_counter()
    with urllib.request.urlopen(req, timeout=4) as resp:
        resp.read(2048)
    return int((time.perf_counter() - start) * 1000)


def classify_latency(latency):
    if latency == '利用不可':
        return '利用不可', 'unavailable'
    if latency == '検出されませんでした':
        return '検出されませんでした', 'unchecked'
    if isinstance(latency, int):
        if latency <= 800:
            level = 'low'
        elif latency <= 2000:
            level = 'medium'
        else:
            level = 'high'
        return f'{latency}ms', level
    return str(latency), 'unchecked'


try:
    with open(path, 'r', encoding='utf-8') as f:
        obj = json.load(f)
except FileNotFoundError:
    print('MSG\tℹ️ openclaw.json が見つかりません。最初にインストール/初期化を完了してください。')
    raise SystemExit(0)
except Exception as e:
    print(f'MSG\t❌ 構成の読み取りに失敗しました: {type(e).__name__}: {e}')
    raise SystemExit(0)

providers = ((obj.get('models') or {}).get('providers') or {})
if not isinstance(providers, dict) or not providers:
    print('MSG\tℹ️ 現在構成されている API プロバイダーはありません。')
    raise SystemExit(0)

print('MSG\t--- 構成された API リスト ---')

for idx, name in enumerate(sorted(providers.keys()), start=1):
    provider = providers.get(name)
    if not isinstance(provider, dict):
        base_url = '-'
        model_count = 0
        latency_raw = '利用不可'
    else:
        base_url = provider.get('baseUrl') or provider.get('url') or provider.get('endpoint') or '-'
        models = provider.get('models') if isinstance(provider.get('models'), list) else []
        model_count = sum(1 for m in models if isinstance(m, dict) and m.get('id'))
        api = provider.get('api', '')
        api_key = provider.get('apiKey')

        latency_raw = '検出されませんでした'
        if api in SUPPORTED_APIS:
            if isinstance(base_url, str) and base_url != '-' and isinstance(api_key, str) and api_key:
                try:
                    latency_raw = ping_models(base_url, api_key)
                except Exception:
                    latency_raw = '利用不可'
            else:
                latency_raw = '利用不可'

    latency_text, latency_level = classify_latency(latency_raw)
    api_label = api if api in SUPPORTED_APIS else '-'
    print(
        'ROW\t' + '\t'.join([
            str(idx),
            str(name),
            str(base_url),
            str(model_count),
            str(api_label),
            str(latency_text),
            str(latency_level),
        ])
    )
PY
)
}
sync-openclaw-provider-interactive() {
	local config_file="${HOME}/.openclaw/openclaw.json"
	send_stats "プロバイダーによる OpenClaw API の同期"

	if [ ! -f "$config_file" ]; then
		echo "❌ 設定ファイルが見つかりません:$config_file"
		break_end
		return 1
	fi

	read -erp "同期する API 名 (プロバイダー) を入力してください:" provider_name
	if [ -z "$provider_name" ]; then
		echo "❌ プロバイダー名を空にすることはできません"
		break_end
		return 1
	fi

	install jq curl >/dev/null 2>&1

	python3 - "$config_file" "$provider_name" <<'PY2'
import copy
import json
import sys
import time
import urllib.request

path = sys.argv[1]
target = sys.argv[2]
SUPPORTED_APIS = {'openai-completions', 'openai-responses'}

def probe_endpoint(base_url, api_key, path, timeout=6):
    url = base_url.rstrip('/') + path
    req = urllib.request.Request(
        url,
        data=b'{}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'OpenClaw-API-Manage/1.0',
        },
        method='POST',
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.getcode(), None
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return None, e


def detect_api_protocol(base_url, api_key):
    code, err = probe_endpoint(base_url, api_key, '/responses')
    if code is not None and code not in (404, 405):
        return 'openai-responses', f'POST /responses -> HTTP {code}', None
    if err:
        return 'openai-completions', 'fallback: probe failed', err
    return 'openai-completions', f'POST /responses={code} -> fallback /completions', None

with open(path, 'r', encoding='utf-8') as f:
    obj = json.load(f)

work = copy.deepcopy(obj)
models_cfg = work.setdefault('models', {})
providers = models_cfg.get('providers', {})
if not isinstance(providers, dict) or not providers:
    print('❌ API プロバイダーが検出されず、同期できない')
    raise SystemExit(2)

provider = providers.get(target)
if not isinstance(provider, dict):
    print(f'❌ プロバイダー: {target} が見つかりません')
    raise SystemExit(2)

agents = work.setdefault('agents', {})
defaults = agents.setdefault('defaults', {})
defaults_models_raw = defaults.get('models')
if isinstance(defaults_models_raw, dict):
    defaults_models = defaults_models_raw
elif isinstance(defaults_models_raw, list):
    defaults_models = {str(x): {} for x in defaults_models_raw if isinstance(x, str)}
else:
    defaults_models = {}
defaults['models'] = defaults_models


def model_ref(provider_name, model_id):
    return f"{provider_name}/{model_id}"


def get_primary_ref(defaults_obj):
    model_obj = defaults_obj.get('model')
    if isinstance(model_obj, str):
        return model_obj
    if isinstance(model_obj, dict):
        primary = model_obj.get('primary')
        if isinstance(primary, str):
            return primary
    return None


def set_primary_ref(defaults_obj, new_ref):
    model_obj = defaults_obj.get('model')
    if isinstance(model_obj, str):
        defaults_obj['model'] = new_ref
    elif isinstance(model_obj, dict):
        model_obj['primary'] = new_ref
    else:
        defaults_obj['model'] = {'primary': new_ref}


def fetch_remote_models_with_retry(base_url, api_key, retries=3):
    last_error = None
    for attempt in range(1, retries + 1):
        req = urllib.request.Request(
            base_url.rstrip('/') + '/models',
            headers={
                'Authorization': f'Bearer {api_key}',
                'User-Agent': 'Mozilla/5.0',
            },
        )
        try:
            with urllib.request.urlopen(req, timeout=12) as resp:
                payload = resp.read().decode('utf-8', 'ignore')
            return json.loads(payload), None, attempt
        except Exception as e:
            last_error = e
            if attempt < retries:
                time.sleep(1)
    return None, last_error, retries


api = provider.get('api', '')
base_url = provider.get('baseUrl')
api_key = provider.get('apiKey')
model_list = provider.get('models', [])

if not base_url or not api_key or not isinstance(model_list, list) or not model_list:
    print(f'❌ プロバイダー {target} にbaseUrl/apiKey/models がないため、同期を実行できません')
    raise SystemExit(3)

if api not in SUPPORTED_APIS:
    print(f'ℹ️ プロバイダー {target} の現在の api={api}、プロトコルを再検出して続行します')
    provider['api'] = ''
    api = ''

protocol_msg = None
try:
    detected_api, detected_reason, detect_err = detect_api_protocol(base_url, api_key)
    if detected_api and api != detected_api:
        provider['api'] = detected_api
        api = detected_api
        protocol_msg = f'🔁 自動修正されたプロトコル: {target} {api} ({detected_reason})'
except Exception as e:
    protocol_msg = f'⚠️ プロトコルの検出に失敗しました。修正をスキップしました: {target} ({type(e).__name__}: {e})'

data, err, attempts = fetch_remote_models_with_retry(base_url, api_key, retries=3)
if err is not None:
    print(f'❌ {target}: /models の検出に失敗しました。{attempts} 回再試行しました ({type(err).__name__}: {err})')
    raise SystemExit(4)

if not (isinstance(data, dict) and isinstance(data.get('data'), list)):
    print(f'❌ {target}: /models 返された構造は認識されません')
    raise SystemExit(4)

remote_ids = []
for item in data['data']:
    if isinstance(item, dict) and item.get('id'):
        remote_ids.append(str(item['id']))
remote_set = set(remote_ids)
if not remote_set:
    print(f'❌ {target}: 上流の /models は空です。同期は中止されました。')
    raise SystemExit(5)

local_models = [m for m in model_list if isinstance(m, dict) and m.get('id')]
local_ids = [str(m['id']) for m in local_models]
local_set = set(local_ids)

template = copy.deepcopy(local_models[0]) if local_models else None
if template is None:
    print(f'❌ {target}: ローカル モデルには有効なテンプレート モデルがないため、新しいモデルを追加できません。')
    raise SystemExit(3)

removed_ids = [mid for mid in local_ids if mid not in remote_set]
added_ids = [mid for mid in remote_ids if mid not in local_set]

if added_ids:
    print(f'➕ 新しいモデルを追加します ({len(added_ids)}):')
    for mid in added_ids:
        print(f'  + {mid}')
if removed_ids:
    print(f'➖ モデルを削除します ({len(removed_ids)}):')
    for mid in removed_ids:
        print(f'  - {mid}')

kept_models = [copy.deepcopy(m) for m in local_models if str(m['id']) in remote_set]
new_models = kept_models[:]
for mid in added_ids:
    nm = copy.deepcopy(template)
    nm['id'] = mid
    if isinstance(nm.get('name'), str):
        nm['name'] = f'{target} / {mid}'
    new_models.append(nm)

if not new_models:
    print(f'❌ {target}: 同期後に使用可能なモデルがないため、書き込みが中止されました')
    raise SystemExit(5)

expected_refs = {model_ref(target, str(m['id'])) for m in new_models if isinstance(m, dict) and m.get('id')}
local_refs = {model_ref(target, mid) for mid in local_ids}
removed_refs = local_refs - expected_refs
first_ref = model_ref(target, str(new_models[0]['id']))

changed = False
primary_ref = get_primary_ref(defaults)
if isinstance(primary_ref, str) and primary_ref in removed_refs:
    set_primary_ref(defaults, first_ref)
    changed = True
    print(f'🔁 デフォルトのモデルは完全に置き換えられました: {primary_ref} -> {first_ref}')

for fk in ('modelFallback', 'imageModelFallback'):
    val = defaults.get(fk)
    if isinstance(val, str) and val in removed_refs:
        defaults[fk] = first_ref
        changed = True
        print(f'🔁 {fk} は完全に置き換えられました: {val} -> {first_ref}')

stale_refs = [r for r in list(defaults_models.keys()) if r.startswith(target + '/') and r not in expected_refs]
for r in stale_refs:
    defaults_models.pop(r, None)
    changed = True

for r in sorted(expected_refs):
    if r not in defaults_models:
        defaults_models[r] = {}
        changed = True

if removed_ids or added_ids or len(local_models) != len(new_models):
    provider['models'] = new_models
    changed = True

if protocol_msg:
    print(protocol_msg)

if changed:
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(work, f, ensure_ascii=False, indent=2)
        f.write('\n')

print(f'✅ {target}: {len(removed_ids)} を削除、{len(added_ids)} を追加、現在の {len(new_models)}')
if changed:
    print('✅ 指定されたプロバイダーモデルの整合性同期が完了し、設定が書き込まれました')
else:
    print('ℹ️ 同期は必要ありません。プロバイダーの構成はすでにアップストリームの /models と一致しています。')
PY2
	local rc=$?
	case "$rc" in
		0)
			echo "✅ 同期実行が完了しました"
			start_gateway
			;;
		2)
			echo "❌ 同期に失敗しました: プロバイダーが存在しないか、構成されていません"
			;;
		3)
			echo "❌ 同期に失敗しました: プロバイダーの構成が不完全であるか、タイプがサポートされていません"
			;;
		4)
			echo "❌ 同期に失敗しました: アップストリーム /models リクエストが失敗しました"
			;;
		5)
			echo "❌ 同期に失敗しました: 上流モデルが空であるか、同期後に使用可能なモデルがありません"
			;;
		*)
			echo "❌ 同期に失敗しました: 設定ファイルの構造またはログ出力を確認してください。"
			;;
	esac

	break_end
}

openclaw_detect_api_protocol_by_provider() {
	local config_file="$1"
	local provider_name="$2"

	python3 - "$config_file" "$provider_name" <<'PY'
import json
import sys
import urllib.request

path = sys.argv[1]
name = sys.argv[2]
SUPPORTED_APIS = {'openai-completions', 'openai-responses'}

def probe_endpoint(base_url, api_key, path, timeout=6):
    url = base_url.rstrip('/') + path
    req = urllib.request.Request(
        url,
        data=b'{}',
        headers={
            'Authorization': f'Bearer {api_key}',
            'Content-Type': 'application/json',
            'User-Agent': 'OpenClaw-API-Manage/1.0',
        },
        method='POST',
    )
    try:
        with urllib.request.urlopen(req, timeout=timeout) as resp:
            return resp.getcode(), None
    except urllib.error.HTTPError as e:
        return e.code, None
    except Exception as e:
        return None, e


def detect_api_protocol(base_url, api_key):
    code, err = probe_endpoint(base_url, api_key, '/responses')
    if code is not None and code not in (404, 405):
        return 'openai-responses', f'POST /responses -> HTTP {code}', None
    if err:
        return 'openai-completions', 'fallback: probe failed', err
    return 'openai-completions', f'POST /responses={code} -> fallback /completions', None

try:
    with open(path, 'r', encoding='utf-8') as f:
        obj = json.load(f)
except FileNotFoundError:
    print('❌ openclaw.json が見つかりません')
    raise SystemExit(2)

providers = ((obj.get('models') or {}).get('providers') or {})
provider = providers.get(name) if isinstance(providers, dict) else None
if not isinstance(provider, dict):
    print(f'❌ プロバイダー: {name} が見つかりません')
    raise SystemExit(2)

base_url = provider.get('baseUrl')
api_key = provider.get('apiKey')
if not base_url or not api_key:
    print(f'❌ プロバイダー {name} に BaseUrl/apiKey がありません')
    raise SystemExit(3)

current_api = provider.get('api', '')
if current_api not in SUPPORTED_APIS:
    current_api = ''

api, reason, err = detect_api_protocol(base_url, api_key)
if api and api != current_api:
    provider['api'] = api
    with open(path, 'w', encoding='utf-8') as f:
        json.dump(obj, f, ensure_ascii=False, indent=2)
        f.write('\n')
    print(f'✅ プロバイダー {name} プロトコルを更新しました: {current_api または "(unset)"} -> {api} ({reason})')
else:
    print(f'ℹ️ 更新は必要ありません: プロトコルは {current_api または api} のままです')
PY
}

fix-openclaw-provider-protocol-interactive() {
	local config_file="${HOME}/.openclaw/openclaw.json"
	send_stats "OpenClaw API プロトコルの修正"

	if [ ! -f "$config_file" ]; then
		echo "❌ 設定ファイルが見つかりません:$config_file"
		break_end
		return 1
	fi

	read -erp "修復するプロトコルの API 名 (プロバイダー) を入力してください:" provider_name
	if [ -z "$provider_name" ]; then
		echo "❌ プロバイダー名を空にすることはできません"
		break_end
		return 1
	fi

	install jq curl >/dev/null 2>&1
	openclaw_detect_api_protocol_by_provider "$config_file" "$provider_name"
	local rc=$?
	case "$rc" in
		0)
			echo "✅契約はテストされ、更新されています（変更される可能性があります）"
			start_gateway
			;;
		2)
			echo "❌ 修復に失敗しました: プロバイダーが存在しないか、構成されていません"
			;;
		3)
			echo "❌ 修復に失敗しました: プロバイダーの構成が不完全です"
			;;
		*)
			echo "❌ 修復に失敗しました: 設定ファイルの構造またはログ出力を確認してください。"
			;;
	esac

	break_end
}

	delete-openclaw-provider-interactive() {
		local config_file="${HOME}/.openclaw/openclaw.json"
		send_stats "OpenClaw API エントリの削除"

		if [ ! -f "$config_file" ]; then
			echo "❌ 設定ファイルが見つかりません:$config_file"
			break_end
			return 1
		fi

		read -erp "削除するAPI名(プロバイダー)を入力してください:" provider_name
		if [ -z "$provider_name" ]; then
			send_stats "OpenClaw API 削除 キャンセル"
			echo "❌ プロバイダー名を空にすることはできません"
			break_end
			return 1
		fi

		python3 - "$config_file" "$provider_name" <<'PY'
import copy
import json
import sys

path = sys.argv[1]
name = sys.argv[2]

with open(path, 'r', encoding='utf-8') as f:
    obj = json.load(f)

work = copy.deepcopy(obj)
models_cfg = work.setdefault('models', {})
providers = models_cfg.get('providers', {})
if not isinstance(providers, dict) or name not in providers:
    print(f'❌ プロバイダー: {name} が見つかりません')
    raise SystemExit(2)

agents = work.setdefault('agents', {})
defaults = agents.setdefault('defaults', {})
defaults_models_raw = defaults.get('models')
if isinstance(defaults_models_raw, dict):
    defaults_models = defaults_models_raw
elif isinstance(defaults_models_raw, list):
    defaults_models = {str(x): {} for x in defaults_models_raw if isinstance(x, str)}
else:
    defaults_models = {}
defaults['models'] = defaults_models


def model_ref(provider_name, model_id):
    return f"{provider_name}/{model_id}"


def ref_provider(ref):
    if not isinstance(ref, str) or '/' not in ref:
        return None
    return ref.split('/', 1)[0]


def get_primary_ref(defaults_obj):
    model_obj = defaults_obj.get('model')
    if isinstance(model_obj, str):
        return model_obj
    if isinstance(model_obj, dict):
        primary = model_obj.get('primary')
        if isinstance(primary, str):
            return primary
    return None


def set_primary_ref(defaults_obj, new_ref):
    model_obj = defaults_obj.get('model')
    if isinstance(model_obj, str):
        defaults_obj['model'] = new_ref
    elif isinstance(model_obj, dict):
        model_obj['primary'] = new_ref
    else:
        defaults_obj['model'] = {'primary': new_ref}


def collect_available_refs(exclude_provider=None):
    refs = []
    if not isinstance(providers, dict):
        return refs
    for pname, p in providers.items():
        if exclude_provider and pname == exclude_provider:
            continue
        if not isinstance(p, dict):
            continue
        for m in p.get('models', []) or []:
            if isinstance(m, dict) and m.get('id'):
                refs.append(model_ref(pname, str(m['id'])))
    return refs


replacement_candidates = collect_available_refs(exclude_provider=name)
replacement = replacement_candidates[0] if replacement_candidates else None

primary_ref = get_primary_ref(defaults)
if ref_provider(primary_ref) == name:
    if not replacement:
        print('❌ 削除は中止されました: デフォルトのメイン モデルはプロバイダーを指しており、使用可能な代替モデルはありません')
        raise SystemExit(3)
    set_primary_ref(defaults, replacement)
    print(f'🔁 デフォルトのプライマリ モデルの切り替え: {primary_ref} -> {replacement}')

for fk in ('modelFallback', 'imageModelFallback'):
    val = defaults.get(fk)
    if ref_provider(val) == name:
        if not replacement:
            print(f'❌ 削除は中止されました: {fk} はプロバイダーを指しており、使用可能な代替モデルはありません')
            raise SystemExit(3)
        defaults[fk] = replacement
        print(f'🔁 {fk} スイッチ: {val} -> {replacement}')

removed_refs = [r for r in list(defaults_models.keys()) if r.startswith(name + '/')]
for r in removed_refs:
    defaults_models.pop(r, None)

providers.pop(name, None)

with open(path, 'w', encoding='utf-8') as f:
    json.dump(work, f, ensure_ascii=False, indent=2)
    f.write('\n')

print(f'🗑️ 削除されたプロバイダー: {name}')
print(f'🧹defaults.models 内の {len(removed_refs)} に関連するモデル参照をクリーンアップしました')
PY
		local rc=$?
		case "$rc" in
			0)
				send_stats "OpenClaw APIの削除確認"
				echo "✅削除完了"
				start_gateway
				;;
			2)
				echo "❌ 削除に失敗しました: プロバイダーが存在しません"
				;;
			3)
				send_stats "OpenClaw API 削除 キャンセル"
				echo "❌ 削除に失敗しました: 代替モデルはありません。元の構成は維持されています。"
				;;
			*)
				echo "❌ 削除に失敗しました: 構成ファイルの構造またはログ出力を確認してください。"
				;;
		esac

		break_end
	}

	openclaw_api_manage_menu() {
		send_stats "OpenClaw APIの入口"
		while true; do
			clear
			echo "======================================="
			echo "OpenClaw API 管理"
			echo "======================================="
			openclaw_api_manage_list
			echo "---------------------------------------"
			echo "1. APIの追加"
			echo "2. APIプロバイダーモデルリストを同期する"
			echo "3. APIの削除"
			echo "4. プロトコルの修復/再検出"
			echo "0.終了"
			echo "---------------------------------------"
			read -erp "選択肢を入力してください:" api_choice

			case "$api_choice" in
				1)
					add-openclaw-provider-interactive
					;;
				2)
					sync-openclaw-provider-interactive
					;;
				3)
					delete-openclaw-provider-interactive
					;;
				4)
					fix-openclaw-provider-protocol-interactive
					;;
				0)
					return 0
					;;
				*)
					echo "選択が無効です。もう一度お試しください。"
					sleep 1
					;;
			esac
		done
	}



	install_gum() {
	    if command -v gum >/dev/null 2>&1; then
	        return 0
	    fi
	    if [ -f /etc/debian_version ]; then
	        mkdir -p /etc/apt/keyrings
	        curl -fsSL https://repo.charm.sh/apt/gpg.key | gpg --dearmor -o /etc/apt/keyrings/charm.gpg
	        echo "deb [signed-by=/etc/apt/keyrings/charm.gpg] https://repo.charm.sh/apt/ * *" | tee /etc/apt/sources.list.d/charm.list > /dev/null
	        apt update && apt install -y gum
	    elif command -v dnf >/dev/null 2>&1 || command -v yum >/dev/null 2>&1; then
	        cat > /etc/yum.repos.d/charm.repo <<'REPO'
[charm]
name=Charm
baseurl=https://repo.charm.sh/yum/
enabled=1
gpgcheck=1
gpgkey=https://repo.charm.sh/yum/gpg.key
REPO
	        rpm --import https://repo.charm.sh/yum/gpg.key
	        if command -v dnf >/dev/null 2>&1; then
	            dnf install -y gum
	        else
	            yum install -y gum
	        fi
	    elif command -v zypper >/dev/null 2>&1; then
	        zypper --non-interactive refresh
	        zypper --non-interactive install gum
	    fi
	}


	
	change_model() {
		send_stats "機種変更"

		local orange="#FF8C00"

		clear

		while true; do
			local models_raw models_list default_model model_count selected_model

			# 構成ファイルからモデル キーを読み取ります (openclaw モデル リストを呼び出すことなく)
			local oc_config
			oc_config="${HOME}/.openclaw/openclaw.json"
			[ ! -f "$oc_config" ] && [ -f /root/.openclaw/openclaw.json ] && oc_config="/root/.openclaw/openclaw.json"

			models_raw=$(jq -r '.agents.defaults.models | if type == "object" then keys[] else .[] end' "$oc_config" 2>/dev/null | sed '/^\s*$/d')
			if [ -z "$models_raw" ]; then
				echo "モデルのリストを取得できませんでした: 構成ファイルに Agents.defaults.models が見つかりません。"
				break_end
				return 1
			fi

			# 簡単に見つけられるように各モデルに番号を付けます (例: "(10) or-api/...:free")
			models_list=$(echo "$models_raw" | awk '{print "(" NR ") " $0}')
			model_count=$(echo "$models_list" | sed '/^\s*$/d' | wc -l | tr -d ' ')

			# 構成ファイルからデフォルトのモデルを読み取ります (高速)。失敗時に openclaw コマンドにフォールバックする
			default_model=$(jq -r '.agents.defaults.model.primary // empty' "$oc_config" 2>/dev/null)
			[ -z "$default_model" ] && default_model="(unknown)"


			install_gum
			install gum

			clear

				# ガムが存在しない場合は、元の手動入力プロセスにダウングレードします (以前とまったく同じままです)。
			if ! command -v gum >/dev/null 2>&1; then
				echo "---モデル管理---"
				echo "現在入手可能なモデル:"
				jq -r '.agents.defaults.models | if type == "object" then keys[] else .[] end' "$oc_config" 2>/dev/null | sed '/^\s*$/d'
				echo "----------------"
				read -e -p "設定するモデル名を入力してください (例: openrouter/openai/gpt-4o) (終了するには 0 を入力します):" selected_model

				# 1.終了するには0を入力したかどうかを確認します
				if [ "$selected_model" = "0" ]; then
					echo "操作がキャンセルされました。終了しています..."
					break  # 跳出 while 循环
				fi

				# 2. 入力が空であることを確認します
				if [ -z "$selected_model" ]; then
					echo "エラー: モデル名を空にすることはできません。もう一度試してください。"
					echo "" # 换行美化
					continue # 跳过本次循环，重新开始
				fi
			else
				gum style --foreground "$orange" --bold "モデル管理"
				gum style --foreground "$orange" "利用可能なモデル (認証=はい):${model_count}"
				gum style --foreground "$orange" "現在のデフォルト:${default_model}"
				echo ""

				# ボトムチップ
				gum style --faint "↑↓ 選択 / Enter で確認 / Esc で終了"
				echo ""

				# ガムフィルター: 検索付き;ガムのバージョンは大きく異なります。ここでは最も互換性のあるフラグのみが使用されます
				selected_model=$(echo "$models_list" | gum filter \
					--placeholder "モデルの検索 (cli-api/gpt-5.2 など)" \
					--prompt "モデルを選択 >" \
					--indicator "➜ " \
					--prompt.foreground "$orange" \
					--indicator.foreground "$orange" \
					--cursor-text.foreground "$orange" \
					--match.foreground "$orange" \
					--header "" \
					--height 35)

				if [ -z "$selected_model" ] || echo "$selected_model" | head -n 1 | grep -iqE '^(error|usage|gum:)'; then
					echo "操作がキャンセルされました。終了しています..."
					break
				fi
			fi

			# 番号の接頭辞を削除します: 「(10) モデル」 -> 「モデル」
			selected_model=$(echo "$selected_model" | sed -E 's/^\([0-9]+\)[[:space:]]+//')

			# スイッチの実行
			echo "切り替わる機種は以下の通りです。$selected_model ..."
			if ! openclaw models set "$selected_model"; then
				echo "切り替えに失敗しました: openclaw モデル セットがエラーを返しました。"
				break_end
				return 1
			fi
			start_gateway

			break_end
			done
	}


		resolve_openclaw_plugin_id() {
			local raw_input="$1"
			local plugin_id="$raw_input"

			plugin_id="${plugin_id#@openclaw/}"
			if [[ "$plugin_id" == @*/* ]]; then
				plugin_id="${plugin_id##*/}"
			fi
			plugin_id="${plugin_id%%@*}"
			echo "$plugin_id"
		}

		sync_openclaw_plugin_allowlist() {
			local plugin_id="$1"
			[ -z "$plugin_id" ] && return 1

			local home_config="${HOME}/.openclaw/openclaw.json"
			local root_config="/root/.openclaw/openclaw.json"
			local config_file="$home_config"
			if [ ! -f "$home_config" ] && [ -f "$root_config" ]; then
				config_file="$root_config"
			fi

			mkdir -p "$(dirname "$config_file")"
			if [ ! -s "$config_file" ]; then
				echo '{}' > "$config_file"
			fi

			if command -v jq >/dev/null 2>&1; then
				local tmp_json
				tmp_json=$(mktemp)
				if jq --arg pid "$plugin_id" '
					.plugins = (if (.plugins | type) == "object" then .plugins else {} end)
					| .plugins.allow = (if (.plugins.allow | type) == "array" then .plugins.allow else [] end)
					| if (.plugins.allow | index($pid)) == null then .plugins.allow += [$pid] else . end
				' "$config_file" > "$tmp_json" 2>/dev/null && mv "$tmp_json" "$config_file"; then
					echo "✅ 同期された plugins.allow ホワイトリスト:$plugin_id"
					return 0
				fi
				rm -f "$tmp_json"
			fi

			if command -v python3 >/dev/null 2>&1; then
				if python3 - "$config_file" "$plugin_id" <<'PYTHON_EOF'
import json
import sys
from pathlib import Path

config_file = Path(sys.argv[1])
plugin_id = sys.argv[2]

try:
    data = json.loads(config_file.read_text(encoding='utf-8')) if config_file.exists() else {}
    if not isinstance(data, dict):
        data = {}
except Exception:
    data = {}

plugins = data.get('plugins')
if not isinstance(plugins, dict):
    plugins = {}

a = plugins.get('allow')
if not isinstance(a, list):
    a = []

if plugin_id not in a:
    a.append(plugin_id)

plugins['allow'] = a
data['plugins'] = plugins
config_file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding='utf-8')
PYTHON_EOF
				then
					echo "✅ 同期された plugins.allow ホワイトリスト:$plugin_id"
					return 0
				fi
			fi

			echo "⚠️ プラグインはインストールされましたが、plugins.allow の同期に失敗しました。手動で確認してください:$config_file"
			return 1
		}

		sync_openclaw_plugin_denylist() {
			local plugin_id="$1"
			[ -z "$plugin_id" ] && return 1

			local home_config="${HOME}/.openclaw/openclaw.json"
			local root_config="/root/.openclaw/openclaw.json"
			local config_file="$home_config"
			if [ ! -f "$home_config" ] && [ -f "$root_config" ]; then
				config_file="$root_config"
			fi

			mkdir -p "$(dirname "$config_file")"
			if [ ! -s "$config_file" ]; then
				echo '{}' > "$config_file"
			fi

			if command -v jq >/dev/null 2>&1; then
				local tmp_json
				tmp_json=$(mktemp)
				if jq --arg pid "$plugin_id" '
					.plugins = (if (.plugins | type) == "object" then .plugins else {} end)
					| .plugins.allow = (if (.plugins.allow | type) == "array" then .plugins.allow else [] end)
					| .plugins.allow = (.plugins.allow | map(select(. != $pid)))
				' "$config_file" > "$tmp_json" 2>/dev/null && mv "$tmp_json" "$config_file"; then
					echo "✅ plugins.allow から削除されました:$plugin_id"
					return 0
				fi
				rm -f "$tmp_json"
			fi

			if command -v python3 >/dev/null 2>&1; then
				if python3 - "$config_file" "$plugin_id" <<'PYTHON_EOF'
import json
import sys
from pathlib import Path

config_file = Path(sys.argv[1])
plugin_id = sys.argv[2]

try:
    data = json.loads(config_file.read_text(encoding='utf-8')) if config_file.exists() else {}
    if not isinstance(data, dict):
        data = {}
except Exception:
    data = {}

plugins = data.get('plugins')
if not isinstance(plugins, dict):
    plugins = {}

a = plugins.get('allow')
if not isinstance(a, list):
    a = []

a = [x for x in a if x != plugin_id]
plugins['allow'] = a
data['plugins'] = plugins
config_file.write_text(json.dumps(data, ensure_ascii=False, indent=2) + "\n", encoding='utf-8')
PYTHON_EOF
				then
					echo "✅ plugins.allow から削除されました:$plugin_id"
					return 0
				fi
			fi

			echo "⚠️ plugins.allow の削除に失敗しました。手動で確認してください:$config_file"
			return 1
		}





		
		install_plugin() {
		send_stats "プラグイン管理"
		while true; do
			clear
			echo "========================================"
			echo "プラグイン管理（インストール/削除）"
			echo "========================================"
			echo "現在のプラグインのリスト:"
			openclaw plugins list
			echo "--------------------------------------------------------"
			echo "推奨される一般的に使用されるプラグイン ID (括弧内の ID をコピーするだけです):"
			echo "--------------------------------------------------------"
			echo "📱 コミュニケーションチャネル:"
			echo "- [フェイシュ] #フェイシュ/ラーク統合"
			echo "- [電報] #電報ボット"
			echo "- [slack] #Slack コーポレートコミュニケーション"
			echo "  - [msteams]      	# Microsoft Teams"
			echo "- [discord] #Discordコミュニティ運営"
			echo "- [whatsapp] #WhatsApp オートメーション"
			echo ""
			echo "🧠 メモリと AI:"
			echo "- [memory-core] # 基本メモリ (ファイル取得)"
			echo "- [memory-lancedb] # メモリの強化 (ベクターデータベース)"
			echo "- [copilot-proxy] # コパイロットインターフェイスの転送"
			echo ""
			echo "⚙️機能拡張:"
			echo "- [lobster] # 承認フロー（手動確認あり）"
			echo "- [voice-call] # 音声通話機能"
			echo "- [nostr] # 暗号化されたプライベートチャット"
			echo "--------------------------------------------------------"

			echo "1) プラグインのインストール/有効化"
			echo "2) プラグインの削除/無効化"
			echo "0) 戻る"
			read -e -p "アクションを選択してください:" plugin_action

			[ "$plugin_action" = "0" ] && break
			[ -z "$plugin_action" ] && continue

			read -e -p "プラグイン ID を入力してください (スペースで区切って、終了するには 0 を入力してください):" raw_input
			[ "$raw_input" = "0" ] && break
			[ -z "$raw_input" ] && continue

			local success_list=""
			local failed_list=""
			local skipped_list=""
			local changed=false
			local token

			for token in $raw_input; do
				local plugin_id
				local plugin_full
				plugin_id=$(resolve_openclaw_plugin_id "$token")
				plugin_full="$token"
				[ -z "$plugin_id" ] && continue

				if [ "$plugin_action" = "1" ]; then
					echo "🔍 プラグインのステータスを確認する:$plugin_id"
					local plugin_list
					plugin_list=$(openclaw plugins list 2>/dev/null)

					if echo "$plugin_list" | grep -qw "$plugin_id" && echo "$plugin_list" | grep "$plugin_id" | grep -q "disabled"; then
						echo "💡プラグイン [$plugin_id] プリインストールされており、アクティベート中..."
						if openclaw plugins enable "$plugin_id"; then
							sync_openclaw_plugin_allowlist "$plugin_id"
							success_list="$success_list $plugin_id"
							changed=true
						else
							failed_list="$failed_list $plugin_id"
						fi
						continue
					fi

					if [ -d "/usr/lib/node_modules/openclaw/extensions/$plugin_id" ]; then
						echo "💡 プラグインがシステムの組み込みディレクトリに存在することがわかりました。直接有効にしてみてください..."
						if openclaw plugins enable "$plugin_id"; then
							sync_openclaw_plugin_allowlist "$plugin_id"
							success_list="$success_list $plugin_id"
							changed=true
						else
							failed_list="$failed_list $plugin_id"
						fi
						continue
					fi

					echo "📥 ローカルに見つかりません。ダウンロードしてインストールしてください:$plugin_full"
					rm -rf "/root/.openclaw/extensions/$plugin_id"
					if openclaw plugins install "$plugin_full"; then
						echo "✅ ダウンロードに成功しました。アクティブ化しています..."
						if openclaw plugins enable "$plugin_id"; then
							sync_openclaw_plugin_allowlist "$plugin_id"
							success_list="$success_list $plugin_id"
							changed=true
						else
							failed_list="$failed_list $plugin_id"
						fi
					else
						echo "❌ インストールに失敗しました:$plugin_full"
						failed_list="$failed_list $plugin_id"
					fi
				else
					echo "🗑️ プラグインの削除/無効化:$plugin_id"
					openclaw plugins disable "$plugin_id" >/dev/null 2>&1
					if openclaw plugins uninstall "$plugin_id"; then
						echo "✅ アンインストール済み:$plugin_id"
					else
						echo "⚠️ アンインストールに失敗しました。プリインストールされたプラグインである可能性があります。以下を無効にするだけです。$plugin_id"
					fi
					sync_openclaw_plugin_denylist "$plugin_id" >/dev/null 2>&1
					success_list="$success_list $plugin_id"
					changed=true
				fi
			done

			echo ""
			echo "====== 操作概要 ======"
			echo "✅ 成功:$success_list"
			[ -n "$failed_list" ] && echo "❌ 失敗:$failed_list"
			[ -n "$skipped_list" ] && echo "⏭️スキップ:$skipped_list"

			if [ "$changed" = true ]; then
				echo "🔄 変更をロードするために OpenClaw サービスを再起動しています..."
				start_gateway
			fi
			break_end
		done
	}


	install_skill() {
		send_stats "スキル管理"
		while true; do
			clear
			echo "========================================"
			echo "スキル管理（インストール/削除）"
			echo "========================================"
			echo "現在インストールされているスキル:"
			openclaw skills list
			echo "----------------------------------------"

			# 推奨実践スキルリストを出力
			echo "推奨される実践スキル (名前を直接コピーして入力できます):"
			echo "github # GitHub の問題/PR/CI を管理する (gh CLI)"
			echo "notion # Notion のページ、データベース、ブロックを操作する"
			echo "apple-notes # macOS ネイティブのノート管理 (作成/編集/検索)"
			echo "apple-reminders # macOS リマインダー管理 (ToDo リスト)"
			echo "1password # 1Password キーの読み取りと挿入を自動化します"
			echo "gog # Google Workspace (Gmail/クラウド ディスク/ドキュメント) 万能アシスタント"
			echo "things-mac # Things 3 タスク管理の緊密な統合"
			echo "bluebubbles # BlueBubbles で iMessage を完璧に送受信"
			echo "ヒマラヤ # 端末メール管理（IMAP/SMTP強力ツール）"
			echo "要約 # ウェブページ/ポッドキャスト/YouTube ビデオ コンテンツのワンクリック要約"
			echo "openhue # Philips Hue スマート照明シーンを制御する"
			echo "video-frames # ビデオフレーム抽出とショートクリップ編集 (ffmpeg ドライバー)"
			echo "openai-whisper # ローカル音声をテキストに変換 (オフラインのプライバシー保護)"
			echo "coding-agent # Claude Code/Codex などのプログラミング アシスタントを自動的に実行する"
			echo "----------------------------------------"

			echo "1) 取り付けスキル"
			echo "2) スキルの削除"
			echo "0) 戻る"
			read -e -p "アクションを選択してください:" skill_action

			[ "$skill_action" = "0" ] && break
			[ -z "$skill_action" ] && continue

			read -e -p "スキル名を入力してください (スペースで区切って、終了するには 0 を入力してください):" skill_input
			[ "$skill_input" = "0" ] && break
			[ -z "$skill_input" ] && continue

			local success_list=""
			local failed_list=""
			local skipped_list=""
			local changed=false
			local token

			if [ "$skill_action" = "2" ]; then
				read -e -p "二次確認: 削除はユーザー ディレクトリ ~/.openclaw/workspace/skills にのみ影響します。続けてもよろしいですか? (y/N):" confirm_del
				if [[ ! "$confirm_del" =~ ^[Yy]$ ]]; then
					echo "削除がキャンセルされました。"
					break_end
					continue
				fi
			fi

			for token in $skill_input; do
				local skill_name
				skill_name="$token"
				[ -z "$skill_name" ] && continue

				if [ "$skill_action" = "1" ]; then
					local skill_found=false
					if [ -d "${HOME}/.openclaw/workspace/skills/${skill_name}" ]; then
						echo "💡 スキル [$skill_name] がユーザーディレクトリにインストールされます。"
						skill_found=true
					elif [ -d "/usr/lib/node_modules/openclaw/skills/${skill_name}" ]; then
						echo "💡 スキル [$skill_name]がシステムディレクトリにインストールされます。"
						skill_found=true
					fi

					if [ "$skill_found" = true ]; then
						read -e -p "スキル [$skill_name] すでにインストールされていますが、再インストールしますか? (y/N):" reinstall
						if [[ ! "$reinstall" =~ ^[Yy]$ ]]; then
							skipped_list="$skipped_list $skill_name"
							continue
						fi
					fi

					echo "スキルのインストール:$skill_name ..."
					if npx clawhub install "$skill_name" --yes --no-input 2>/dev/null || npx clawhub install "$skill_name"; then
						echo "✅ スキル$skill_nameインストールが成功しました。"
						success_list="$success_list $skill_name"
						changed=true
					else
						echo "❌ インストールに失敗しました:$skill_name"
						failed_list="$failed_list $skill_name"
					fi
				else
					echo "🗑️ スキルの削除:$skill_name"
					npx clawhub uninstall "$skill_name" --yes --no-input 2>/dev/null || npx clawhub uninstall "$skill_name" >/dev/null 2>&1
					if [ -d "${HOME}/.openclaw/workspace/skills/${skill_name}" ]; then
						rm -rf "${HOME}/.openclaw/workspace/skills/${skill_name}"
						echo "✅ ユーザースキルディレクトリが削除されました:$skill_name"
						success_list="$success_list $skill_name"
						changed=true
					else
						echo "⏭️ ユーザー スキル ディレクトリが見つかりません:$skill_name"
						skipped_list="$skipped_list $skill_name"
					fi
				fi
			done

			echo ""
			echo "====== 操作概要 ======"
			echo "✅ 成功:$success_list"
			[ -n "$failed_list" ] && echo "❌ 失敗:$failed_list"
			[ -n "$skipped_list" ] && echo "⏭️スキップ:$skipped_list"

			if [ "$changed" = true ]; then
				echo "🔄 変更をロードするために OpenClaw サービスを再起動しています..."
				start_gateway
			fi
			break_end
		done
	}

openclaw_json_get_bool() {
		local expr="$1"
		local config_file="${HOME}/.openclaw/openclaw.json"
		if [ ! -s "$config_file" ]; then
			echo "false"
			return
		fi
		jq -r "$expr" "$config_file" 2>/dev/null || echo "false"
	}

	openclaw_channel_has_cfg() {
		local channel="$1"
		local config_file="${HOME}/.openclaw/openclaw.json"
		if [ ! -s "$config_file" ]; then
			echo "false"
			return
		fi
		jq -r --arg c "$channel" '
			(.channels[$c] // null) as $v
			| if ($v | type) != "object" then
				false
			  else
				([ $v
				   | to_entries[]
				   | select((.key == "enabled" or .key == "dmPolicy" or .key == "groupPolicy" or .key == "streaming") | not)
				   | .value
				   | select(. != null and . != "" and . != false)
				 ] | length) > 0
			  end
		' "$config_file" 2>/dev/null || echo "false"
	}

	openclaw_dir_has_files() {
		local dir="$1"
		[ -d "$dir" ] && find "$dir" -type f -print -quit 2>/dev/null | grep -q .
	}

	openclaw_plugin_local_installed() {
		local plugin="$1"
		local config_file="${HOME}/.openclaw/openclaw.json"
		if [ -s "$config_file" ] && jq -e --arg p "$plugin" '.plugins.installs[$p]' "$config_file" >/dev/null 2>&1; then
			return 0
		fi

		# 2 つの一般的なディレクトリ名と互換性があります。
		# - ~/.openclaw/extensions/qqbot
		# - ~/.openclaw/extensions/openclaw-qqbot
		# 無知な部分文字列を避け、完全一致と openclaw プレフィックス一致を優先します。
		[ -d "${HOME}/.openclaw/extensions/${plugin}" ] \
			|| [ -d "${HOME}/.openclaw/extensions/openclaw-${plugin}" ] \
			|| [ -d "/usr/lib/node_modules/openclaw/extensions/${plugin}" ] \
			|| [ -d "/usr/lib/node_modules/openclaw/extensions/openclaw-${plugin}" ]
	}

	openclaw_bot_status_text() {
		local enabled="$1"
		local configured="$2"
		local connected="$3"
		local abnormal="$4"
		if [ "$abnormal" = "true" ]; then
			echo "異常な"
		elif [ "$enabled" != "true" ]; then
			echo "有効になっていません"
		elif [ "$connected" = "true" ]; then
			echo "接続済み"
		elif [ "$configured" = "true" ]; then
			echo "設定済み"
		else
			echo "未設定"
		fi
	}

	openclaw_colorize_bot_status() {
		local status="$1"
		case "$status" in
			已连接) echo -e "${gl_lv}${status}${gl_bai}" ;;
			已配置) echo -e "${gl_huang}${status}${gl_bai}" ;;
			异常) echo -e "${gl_hong}${status}${gl_bai}" ;;
			*) echo "$status" ;;
		esac
	}

	openclaw_print_bot_status_line() {
		local label="$1"
		local status="$2"
		echo -e "- ${label}: $(openclaw_colorize_bot_status "$status")"
	}

	openclaw_show_bot_local_status_block() {
		local config_file="${HOME}/.openclaw/openclaw.json"
		local json_ok="false"
		if [ -s "$config_file" ] && jq empty "$config_file" >/dev/null 2>&1; then
			json_ok="true"
		fi

		local tg_enabled tg_cfg tg_connected tg_abnormal tg_status
		tg_enabled=$(openclaw_json_get_bool '.channels.telegram.enabled // .plugins.entries.telegram.enabled // false')
		tg_cfg=$(openclaw_channel_has_cfg "telegram")
		tg_connected="false"
		if openclaw_dir_has_files "${HOME}/.openclaw/telegram"; then
			tg_connected="true"
		fi
		tg_abnormal="false"
		if [ "$tg_enabled" = "true" ] && [ "$json_ok" != "true" ]; then
			tg_abnormal="true"
		fi
		tg_status=$(openclaw_bot_status_text "$tg_enabled" "$tg_cfg" "$tg_connected" "$tg_abnormal")

		local feishu_enabled feishu_cfg feishu_connected feishu_abnormal feishu_status
		feishu_enabled=$(openclaw_json_get_bool '.plugins.entries.feishu.enabled // .channels.feishu.enabled // false')
		feishu_cfg=$(openclaw_channel_has_cfg "feishu")
		feishu_connected="false"
		if openclaw_dir_has_files "${HOME}/.openclaw/feishu"; then
			feishu_connected="true"
		fi
		feishu_abnormal="false"
		if [ "$feishu_enabled" = "true" ] && ! openclaw_plugin_local_installed "feishu"; then
			feishu_abnormal="true"
		fi
		if [ "$feishu_enabled" = "true" ] && [ "$json_ok" != "true" ]; then
			feishu_abnormal="true"
		fi
		feishu_status=$(openclaw_bot_status_text "$feishu_enabled" "$feishu_cfg" "$feishu_connected" "$feishu_abnormal")

		local wa_enabled wa_cfg wa_connected wa_abnormal wa_status
		wa_enabled=$(openclaw_json_get_bool '.plugins.entries.whatsapp.enabled // .channels.whatsapp.enabled // false')
		wa_cfg=$(openclaw_channel_has_cfg "whatsapp")
		wa_connected="false"
		if openclaw_dir_has_files "${HOME}/.openclaw/whatsapp"; then
			wa_connected="true"
		fi
		wa_abnormal="false"
		if [ "$wa_enabled" = "true" ] && ! openclaw_plugin_local_installed "whatsapp"; then
			wa_abnormal="true"
		fi
		if [ "$wa_enabled" = "true" ] && [ "$json_ok" != "true" ]; then
			wa_abnormal="true"
		fi
		wa_status=$(openclaw_bot_status_text "$wa_enabled" "$wa_cfg" "$wa_connected" "$wa_abnormal")

		local dc_enabled dc_cfg dc_connected dc_abnormal dc_status
		dc_enabled=$(openclaw_json_get_bool '.channels.discord.enabled // .plugins.entries.discord.enabled // false')
		dc_cfg=$(openclaw_channel_has_cfg "discord")
		dc_connected="false"
		if openclaw_dir_has_files "${HOME}/.openclaw/discord"; then
			dc_connected="true"
		fi
		dc_abnormal="false"
		if [ "$dc_enabled" = "true" ] && [ "$json_ok" != "true" ]; then
			dc_abnormal="true"
		fi
		dc_status=$(openclaw_bot_status_text "$dc_enabled" "$dc_cfg" "$dc_connected" "$dc_abnormal")

		local slack_enabled slack_cfg slack_connected slack_abnormal slack_status
		slack_enabled=$(openclaw_json_get_bool '.plugins.entries.slack.enabled // .channels.slack.enabled // false')
		slack_cfg=$(openclaw_channel_has_cfg "slack")
		slack_connected="false"
		if openclaw_dir_has_files "${HOME}/.openclaw/slack"; then
			slack_connected="true"
		fi
		slack_abnormal="false"
		if [ "$slack_enabled" = "true" ] && ! openclaw_plugin_local_installed "slack"; then
			slack_abnormal="true"
		fi
		if [ "$slack_enabled" = "true" ] && [ "$json_ok" != "true" ]; then
			slack_abnormal="true"
		fi
		slack_status=$(openclaw_bot_status_text "$slack_enabled" "$slack_cfg" "$slack_connected" "$slack_abnormal")

		local qq_enabled qq_cfg qq_connected qq_abnormal qq_status
		qq_enabled=$(openclaw_json_get_bool '.plugins.entries.qqbot.enabled // .channels.qqbot.enabled // false')
		qq_cfg=$(openclaw_channel_has_cfg "qqbot")
		qq_connected="false"
		if openclaw_dir_has_files "${HOME}/.openclaw/qqbot/sessions" || openclaw_dir_has_files "${HOME}/.openclaw/qqbot/data"; then
			qq_connected="true"
		fi
		qq_abnormal="false"
		if [ "$qq_enabled" = "true" ] && ! openclaw_plugin_local_installed "qqbot"; then
			qq_abnormal="true"
		fi
		if [ "$qq_enabled" = "true" ] && [ "$json_ok" != "true" ]; then
			qq_abnormal="true"
		fi
		qq_status=$(openclaw_bot_status_text "$qq_enabled" "$qq_cfg" "$qq_connected" "$qq_abnormal")

		echo "ローカル ステータス (ローカル構成/キャッシュのみ、ネットワーク検出なし):"
		openclaw_print_bot_status_line "Telegram" "$tg_status"
		openclaw_print_bot_status_line "ヒバリ" "$feishu_status"
		openclaw_print_bot_status_line "WhatsApp" "$wa_status"
		openclaw_print_bot_status_line "Discord" "$dc_status"
		openclaw_print_bot_status_line "Slack" "$slack_status"
		openclaw_print_bot_status_line "QQ Bot" "$qq_status"
	}

	change_tg_bot_code() {
		send_stats "ロボットドッキング"
		while true; do
			clear
			echo "========================================"
			echo "ロボットの接続とドッキング"
			echo "========================================"
			openclaw_show_bot_local_status_block
			echo "----------------------------------------"
			echo "1. テレグラムロボットドッキング"
			echo "2.フェイシュ(ヒバリ)ロボットドッキング"
			echo "3. WhatsApp ボットのドッキング"
			echo "----------------------------------------"
			echo "0. 前のメニューに戻る"
			echo "----------------------------------------"
			read -e -p "選択肢を入力してください:" bot_choice

			case $bot_choice in
				1)
					read -e -p "TG ロボットが受信した接続コード (NYA99R2F など) を入力してください (終了するには 0 を入力します)。" code
					if [ "$code" = "0" ]; then continue; fi
					if [ -z "$code" ]; then echo "エラー: 接続コードを空にすることはできません。"; sleep 1; continue; fi
					openclaw pairing approve telegram "$code"
					break_end
					;;
				2)
					read -e -p "Feishu Robot が受信した接続コード (例: NYA99R2F) を入力してください (終了するには 0 を入力します)。" code
					if [ "$code" = "0" ]; then continue; fi
					if [ -z "$code" ]; then echo "エラー: 接続コードを空にすることはできません。"; sleep 1; continue; fi
					openclaw pairing approve feishu "$code"
					break_end
					;;
				3)
					read -e -p "WhatsApp で受信した接続コード (例: NYA99R2F) を入力してください (終了するには 0 を入力してください):" code
					if [ "$code" = "0" ]; then continue; fi
					if [ -z "$code" ]; then echo "エラー: 接続コードを空にすることはできません。"; sleep 1; continue; fi
					openclaw pairing approve whatsapp "$code"
					break_end
					;;
				0)
					return 0
					;;
				*)
					echo "選択が無効です。もう一度お試しください。"
					sleep 1
					;;
			esac
		done
	}


	openclaw_backup_root() {
		echo "${HOME}/.openclaw/backups"
	}

	openclaw_is_interactive_terminal() {
		[ -t 0 ] && [ -t 1 ]
	}

	openclaw_has_command() {
		command -v "$1" >/dev/null 2>&1
	}


	openclaw_is_safe_relpath() {
		local rel="$1"
		[ -z "$rel" ] && return 1
		[[ "$rel" = /* ]] && return 1
		[[ "$rel" == *"//"* ]] && return 1
		[[ "$rel" == *$'\n'* ]] && return 1
		[[ "$rel" == *$'\r'* ]] && return 1
		case "$rel" in
			../*|*/../*|*/..|..)
				return 1
				;;
		esac
		return 0
	}

	openclaw_restore_path_allowed() {
		local mode="$1"
		local rel="$2"
		case "$mode" in
			memory)
				case "$rel" in
					MEMORY.md|AGENTS.md|USER.md|SOUL.md|TOOLS.md|memory/*) return 0 ;;
					*) return 1 ;;
				esac
				;;
			project)
				case "$rel" in
					openclaw.json|workspace/*|extensions/*|skills/*|prompts/*|tools/*|telegram/*|feishu/*|whatsapp/*|discord/*|slack/*|qqbot/*|logs/*) return 0 ;;
					*) return 1 ;;
				esac
				;;
			*)
				return 1
				;;
		esac
	}

	openclaw_pack_backup_archive() {
		local backup_type="$1"
		local export_mode="$2"
		local payload_dir="$3"
		local output_file="$4"

		local tmp_root
		tmp_root=$(mktemp -d) || return 1
		local pack_dir="$tmp_root/package"
		mkdir -p "$pack_dir"

		cp -a "$payload_dir" "$pack_dir/payload"

		(
			cd "$pack_dir/payload" || exit 1
			find . -type f | sed 's|^\./||' | sort > "$pack_dir/manifest.files"
			: > "$pack_dir/manifest.sha256"
			while IFS= read -r f; do
				[ -z "$f" ] && continue
				sha256sum "$f" >> "$pack_dir/manifest.sha256"
			done < "$pack_dir/manifest.files"
		) || { rm -rf "$tmp_root"; return 1; }

		cat > "$pack_dir/backup.meta" <<EOF
TYPE=$backup_type
MODE=$export_mode
CREATED_AT=$(date -u +'%Y-%m-%dT%H:%M:%SZ')
HOST=$(hostname)
EOF

		mkdir -p "$(dirname "$output_file")"
		tar -C "$pack_dir" -czf "$output_file" backup.meta manifest.files manifest.sha256 payload
		local rc=$?
		rm -rf "$tmp_root"
		return $rc
	}

	openclaw_offer_transfer_hint() {
		local file_path="$1"

		echo "バックアップ ファイルは次の方法でダウンロードできます。"
		echo "- ローカルパス:$file_path"
		echo "- scp の例: scp root@yourserver:$file_path ./"
		echo "- またはSFTPクライアントを使用してダウンロード"
	}

	openclaw_prepare_import_archive() {
		local expected_type="$1"
		local archive_path="$2"
		local unpack_root="$3"

		[ ! -f "$archive_path" ] && { echo "❌ ファイルが存在しません:$archive_path"; return 1; }
		mkdir -p "$unpack_root"
		tar -xzf "$archive_path" -C "$unpack_root" || { echo "❌ バックアップパッケージの解凍に失敗しました"; return 1; }

		local pkg_dir="$unpack_root/package"
		if [ -f "$unpack_root/backup.meta" ]; then
			pkg_dir="$unpack_root"
		fi

		for required in backup.meta manifest.files manifest.sha256 payload; do
			[ -e "$pkg_dir/$required" ] || { echo "❌ バックアップ パッケージに必要なファイルがありません:$required"; return 1; }
		done

		local real_type
		real_type=$(grep '^TYPE=' "$pkg_dir/backup.meta" | head -n1 | cut -d'=' -f2-)
		if [ "$real_type" != "$expected_type" ]; then
			echo "❌ バックアップ タイプの不一致が予想されます:$expected_type、実際: ${real_type:-unknown}"
			return 1
		fi

		(
			cd "$pkg_dir/payload" || exit 1
			sha256sum -c ../manifest.sha256 >/dev/null
		) || { echo "❌ sha256 検証が失敗し、復元が拒否されました"; return 1; }

		echo "$pkg_dir"
		return 0
	}

	openclaw_memory_backup_export() {
		send_stats "OpenClaw メモリの完全バックアップ"
		local workspace_dir="${HOME}/.openclaw/workspace"
		local backup_root
		backup_root=$(openclaw_backup_root)
		local ts
		ts=$(date +%Y%m%d-%H%M%S)
		local out_file="$backup_root/openclaw-memory-full-${ts}.tar.gz"

		mkdir -p "$backup_root"
		if [ ! -d "$workspace_dir" ]; then
			echo "❌ ワークスペース ディレクトリが見つかりません:$workspace_dir"
			break_end
			return 1
		fi

		local tmp_payload
		tmp_payload=$(mktemp -d) || return 1

		[ -f "$workspace_dir/MEMORY.md" ] && cp -a "$workspace_dir/MEMORY.md" "$tmp_payload/"
		[ -d "$workspace_dir/memory" ] && cp -a "$workspace_dir/memory" "$tmp_payload/"

		read -e -p "AGENTS/USER/SOUL/TOOLS ファイルは付属していますか? (y/N):" include_optional
		if [[ "$include_optional" =~ ^[Yy]$ ]]; then
			for f in AGENTS.md USER.md SOUL.md TOOLS.md; do
				[ -f "$workspace_dir/$f" ] && cp -a "$workspace_dir/$f" "$tmp_payload/"
			done
		fi

		if ! find "$tmp_payload" -mindepth 1 -print -quit | grep -q .; then
			echo "❌ バックアップメモリ​​ファイルが見つかりません"
			rm -rf "$tmp_payload"
			break_end
			return 1
		fi

		if openclaw_pack_backup_archive "memory-full" "default" "$tmp_payload" "$out_file"; then
			echo "✅ メモリ全体のバックアップが完了しました:$out_file"
			openclaw_offer_transfer_hint "$out_file"
		else
			echo "❌ フルメモリバックアップに失敗しました"
		fi

		rm -rf "$tmp_payload"
		break_end
	}

	openclaw_read_import_path() {
		local prompt_text="$1"
		local file_input file_path backup_root
		echo "$prompt_text" >&2

		echo "まず scp/sftp 経由でバックアップ パッケージをサーバーにアップロードし、次にパスを入力します。" >&2
		echo "scp の例: scp /local/backup package.tar.gz root@yourserver:/tmp/" >&2
		echo "ヒント: ファイル名を入力すると、デフォルトではバックアップ ディレクトリ内で検索されます。 / を含むパスを入力すると、フルパスで検証されます。" >&2
		read -e -p "バックアップ ファイル名またはパスを入力してください:" file_input
		[ -z "$file_input" ] && { echo ""; return 0; }

		backup_root=$(openclaw_backup_root)
		mkdir -p "$backup_root"

		if [[ "$file_input" == */* ]]; then
			file_path="$file_input"
		else
			file_path="$backup_root/$file_input"
		fi

		if [ ! -f "$file_path" ]; then
			echo "❌ バックアップ ファイルが存在しません:$file_path" >&2
			echo ""
			return 1
		fi

		echo "$file_path"
	}

	openclaw_memory_backup_import() {
		send_stats "OpenClaw メモリ完全復元"
		local workspace_dir="${HOME}/.openclaw/workspace"
		mkdir -p "$workspace_dir"

		local archive_path
		archive_path=$(openclaw_read_import_path "復元前に、タイプ検証 + sha256 検証 + パス ホワイトリスト検証が実行されます。")
		[ -z "$archive_path" ] && { echo "❌ バックアップ パスが入力されていません"; break_end; return 1; }

		local tmp_unpack
		tmp_unpack=$(mktemp -d) || return 1
		local pkg_dir
		pkg_dir=$(openclaw_prepare_import_archive "memory-full" "$archive_path" "$tmp_unpack") || { rm -rf "$tmp_unpack"; break_end; return 1; }

		local invalid=0
		local valid_list
		valid_list=$(mktemp)
		while IFS= read -r rel; do
			[ -z "$rel" ] && continue
			if ! openclaw_is_safe_relpath "$rel" || ! openclaw_restore_path_allowed memory "$rel"; then
				echo "❌ 違法または無許可のパスが検出されました:$rel"
				invalid=1
				break
			fi
			echo "$rel" >> "$valid_list"
		done < "$pkg_dir/manifest.files"

		if [ "$invalid" -ne 0 ]; then
			rm -f "$valid_list"
			rm -rf "$tmp_unpack"
			echo "❌ 復元は中止されました: 安全でないパスが存在します"
			break_end
			return 1
		fi


		while IFS= read -r rel; do
			mkdir -p "$workspace_dir/$(dirname "$rel")"
			cp -a "$pkg_dir/payload/$rel" "$workspace_dir/$rel"
		done < "$valid_list"

		rm -f "$valid_list"
		rm -rf "$tmp_unpack"
		echo "✅ 完全なメモリ復元が完了しました"
		break_end
	}

	openclaw_project_backup_export() {
		send_stats "OpenClaw プロジェクトのバックアップ"
		local openclaw_root="${HOME}/.openclaw"
		if [ ! -d "$openclaw_root" ]; then
			echo "❌ OpenClaw ルート ディレクトリが見つかりません:$openclaw_root"
			break_end
			return 1
		fi

		echo "バックアップモード:"
		echo "1. セーフ モード (デフォルト、推奨): ワークスペース + openclaw.json + 拡張機能/スキル/プロンプト/ツール (存在する場合)"
		echo "2. 完全モード (より多くの状態が含まれ、機密性のリスクが高くなります)"
		read -e -p "バックアップ モードを選択してください (デフォルト 1):" export_mode
		[ -z "$export_mode" ] && export_mode="1"

		local mode_label="safe"
		local tmp_payload
		tmp_payload=$(mktemp -d) || return 1

		if [ "$export_mode" = "2" ]; then
			mode_label="full"
			for d in workspace extensions skills prompts tools; do
				[ -e "$openclaw_root/$d" ] && cp -a "$openclaw_root/$d" "$tmp_payload/"
			done
			[ -f "$openclaw_root/openclaw.json" ] && cp -a "$openclaw_root/openclaw.json" "$tmp_payload/"
			for d in telegram feishu whatsapp discord slack qqbot logs; do
				[ -e "$openclaw_root/$d" ] && cp -a "$openclaw_root/$d" "$tmp_payload/"
			done
		else
			[ -d "$openclaw_root/workspace" ] && cp -a "$openclaw_root/workspace" "$tmp_payload/"
			[ -f "$openclaw_root/openclaw.json" ] && cp -a "$openclaw_root/openclaw.json" "$tmp_payload/"
			for d in extensions skills prompts tools; do
				[ -e "$openclaw_root/$d" ] && cp -a "$openclaw_root/$d" "$tmp_payload/"
			done
		fi

		if ! find "$tmp_payload" -mindepth 1 -print -quit | grep -q .; then
			echo "❌ バックアップ可能な OpenClaw プロジェクト コンテンツが見つかりません"
			rm -rf "$tmp_payload"
			break_end
			return 1
		fi

		local backup_root
		backup_root=$(openclaw_backup_root)
		mkdir -p "$backup_root"
		local out_file="$backup_root/openclaw-project-${mode_label}-$(date +%Y%m%d-%H%M%S).tar.gz"

		if openclaw_pack_backup_archive "openclaw-project" "$mode_label" "$tmp_payload" "$out_file"; then
			echo "✅ OpenClaw プロジェクトのバックアップが完了しました (${mode_label}): $out_file"
			openclaw_offer_transfer_hint "$out_file"
		else
			echo "❌ OpenClaw プロジェクトのバックアップに失敗しました"
		fi

		rm -rf "$tmp_payload"
		break_end
	}

	openclaw_project_backup_import() {
		send_stats "OpenClaw プロジェクトの復元"
		local openclaw_root="${HOME}/.openclaw"
		mkdir -p "$openclaw_root"

		echo "⚠️ リスクの高い操作: プロジェクトを復元すると、OpenClaw 構成とワークスペースのコンテンツが上書きされます。"
		echo "⚠️マニフェスト/sha256の検証、ホワイトリストの復元、ゲートウェイのシャットダウン、ヘルスチェックが復元前に実行されます。"
		read -e -p "続行するには、確認の単語 [リスクが高いことを承知しており、復元を続行します] を入力してください:" confirm_text
		if [ "$confirm_text" != "高いリスクを認識しており、復旧を続けています" ]; then
			echo "❌ 確認ワードが一致しなかったため、リストアはキャンセルされました。"
			break_end
			return 1
		fi

		local archive_path
		archive_path=$(openclaw_read_import_path "OpenClaw プロジェクトのバックアップ パッケージのパスを入力してください")
		[ -z "$archive_path" ] && { echo "❌ バックアップ パスが入力されていません"; break_end; return 1; }

		local tmp_unpack
		tmp_unpack=$(mktemp -d) || return 1
		local pkg_dir
		pkg_dir=$(openclaw_prepare_import_archive "openclaw-project" "$archive_path" "$tmp_unpack") || { rm -rf "$tmp_unpack"; break_end; return 1; }

		local invalid=0
		local valid_list
		valid_list=$(mktemp)
		while IFS= read -r rel; do
			[ -z "$rel" ] && continue
			if ! openclaw_is_safe_relpath "$rel" || ! openclaw_restore_path_allowed project "$rel"; then
				echo "❌ 違法または無許可のパスが検出されました:$rel"
				invalid=1
				break
			fi
			echo "$rel" >> "$valid_list"
		done < "$pkg_dir/manifest.files"

		if [ "$invalid" -ne 0 ]; then
			rm -f "$valid_list"
			rm -rf "$tmp_unpack"
			echo "❌ 復元は中止されました: 安全でないパスが存在します"
			break_end
			return 1
		fi


		if command -v openclaw >/dev/null 2>&1; then
			echo "⏸️ 復元する前に OpenClaw ゲートウェイを停止してください..."
			openclaw gateway stop >/dev/null 2>&1
		fi

		while IFS= read -r rel; do
			mkdir -p "$openclaw_root/$(dirname "$rel")"
			cp -a "$pkg_dir/payload/$rel" "$openclaw_root/$rel"
		done < "$valid_list"

		if command -v openclaw >/dev/null 2>&1; then
			echo "▶️ 復元後に OpenClaw ゲートウェイを起動します..."
			openclaw gateway start >/dev/null 2>&1
			sleep 2
			echo "🩺 ゲートウェイのヘルスチェック:"
			openclaw gateway status || true
		fi

		rm -f "$valid_list"
		rm -rf "$tmp_unpack"
		echo "✅ OpenClaw プロジェクトの復元が完了しました"
		break_end
	}

	openclaw_backup_detect_type() {
		local file_name="$1"
		if [[ "$file_name" == openclaw-memory-full-*.tar.gz ]]; then
			echo "メモリバックアップファイル"
		elif [[ "$file_name" == openclaw-project-*.tar.gz ]]; then
			echo "プロジェクトのバックアップファイル"
		else
			echo "その他のバックアップファイル"
		fi
	}

	openclaw_backup_collect_files() {
		local backup_root
		backup_root=$(openclaw_backup_root)
		mkdir -p "$backup_root"
		mapfile -t OPENCLAW_BACKUP_FILES < <(find "$backup_root" -maxdepth 1 -type f -name '*.tar.gz' -printf '%f\n' | sort -r)
	}


	openclaw_backup_render_file_list() {
		local backup_root i file_name file_path file_type file_size file_time
		local has_memory=0 has_project=0 has_other=0
		backup_root=$(openclaw_backup_root)
		openclaw_backup_collect_files

		echo "バックアップディレクトリ:$backup_root"
		if [ ${#OPENCLAW_BACKUP_FILES[@]} -eq 0 ]; then
			echo "まだバックアップファイルがありません"
			return 0
		fi

		for i in "${!OPENCLAW_BACKUP_FILES[@]}"; do
			file_type=$(openclaw_backup_detect_type "${OPENCLAW_BACKUP_FILES[$i]}")
			case "$file_type" in
				"メモリバックアップファイル") has_memory=1 ;;
				"プロジェクトのバックアップファイル") has_project=1 ;;
				"その他のバックアップファイル") has_other=1 ;;
			esac
		done

		if [ "$has_memory" -eq 1 ]; then
			echo "メモリバックアップファイル"
			for i in "${!OPENCLAW_BACKUP_FILES[@]}"; do
				file_name="${OPENCLAW_BACKUP_FILES[$i]}"
				file_type=$(openclaw_backup_detect_type "$file_name")
				[ "$file_type" != "メモリバックアップファイル" ] && continue
				file_path="$backup_root/$file_name"
				file_size=$(ls -lh "$file_path" | awk '{print $5}')
				file_time=$(date -d "$(stat -c %y "$file_path")" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || stat -c %y "$file_path" | awk '{print $1" "$2}')
				printf "%s | %s | %s\n" "$file_name" "$file_size" "$file_time"
			done
		fi

		if [ "$has_project" -eq 1 ]; then
			echo "プロジェクトのバックアップファイル"
			for i in "${!OPENCLAW_BACKUP_FILES[@]}"; do
				file_name="${OPENCLAW_BACKUP_FILES[$i]}"
				file_type=$(openclaw_backup_detect_type "$file_name")
				[ "$file_type" != "プロジェクトのバックアップファイル" ] && continue
				file_path="$backup_root/$file_name"
				file_size=$(ls -lh "$file_path" | awk '{print $5}')
				file_time=$(date -d "$(stat -c %y "$file_path")" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || stat -c %y "$file_path" | awk '{print $1" "$2}')
				printf "%s | %s | %s\n" "$file_name" "$file_size" "$file_time"
			done
		fi

		if [ "$has_other" -eq 1 ]; then
			echo "その他のバックアップファイル"
			for i in "${!OPENCLAW_BACKUP_FILES[@]}"; do
				file_name="${OPENCLAW_BACKUP_FILES[$i]}"
				file_type=$(openclaw_backup_detect_type "$file_name")
				[ "$file_type" != "その他のバックアップファイル" ] && continue
				file_path="$backup_root/$file_name"
				file_size=$(ls -lh "$file_path" | awk '{print $5}')
				file_time=$(date -d "$(stat -c %y "$file_path")" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || stat -c %y "$file_path" | awk '{print $1" "$2}')
				printf "%s | %s | %s\n" "$file_name" "$file_size" "$file_time"
			done
		fi
	}

	openclaw_backup_file_exists_in_list() {
		local target_file="$1"
		local item
		for item in "${OPENCLAW_BACKUP_FILES[@]}"; do
			[ "$item" = "$target_file" ] && return 0
		done
		return 1
	}

	openclaw_backup_delete_file() {
		send_stats "OpenClaw はバックアップ ファイルを削除します"
		local backup_root backup_root_real user_input target_file target_path target_type
		backup_root=$(openclaw_backup_root)

		openclaw_backup_render_file_list
		if [ ${#OPENCLAW_BACKUP_FILES[@]} -eq 0 ]; then
			break_end
			return 0
		fi

		read -e -p "削除するファイル名またはフルパスを入力してください (キャンセルするには 0):" user_input
		if [ "$user_input" = "0" ]; then
			echo "削除がキャンセルされました。"
			break_end
			return 0
		fi
		if [ -z "$user_input" ]; then
			echo "❌ 入力を空にすることはできません。"
			break_end
			return 1
		fi

		backup_root_real=$(realpath -m "$backup_root")
		if [[ "$user_input" == /* ]]; then
			target_path=$(realpath -m "$user_input")
			case "$target_path" in
				"$backup_root_real"/*) ;;
				*)
					echo "❌ 範囲外のパス: バックアップ ルート ディレクトリ内のファイルのみを削除できます。"
					break_end
					return 1
					;;
			esac
			target_file=$(basename "$target_path")
		else
			target_file=$(basename -- "$user_input")
			target_path="$backup_root/$target_file"
		fi

		if [ ! -f "$target_path" ]; then
			echo "❌ 対象のファイルが存在しません:$target_path"
			break_end
			return 1
		fi

		if ! openclaw_backup_file_exists_in_list "$target_file"; then
			echo "❌ ターゲットファイルは現在のバックアップリストにありません。"
			break_end
			return 1
		fi

		target_type=$(openclaw_backup_detect_type "$target_file")

		echo "削除されようとしています: [$target_type] $target_path"
		read -e -p "最初の確認: 「yes」と入力して確認し、続行します。" confirm_step1
		if [ "$confirm_step1" != "yes" ]; then
			echo "削除がキャンセルされました。"
			break_end
			return 0
		fi
		read -e -p "2 番目の確認: 「DELETE」と入力して削除します。" confirm_step2
		if [ "$confirm_step2" != "DELETE" ]; then
			echo "削除がキャンセルされました。"
			break_end
			return 0
		fi

		if rm -f -- "$target_path"; then
			echo "✅ 削除が成功しました:$target_file"
		else
			echo "❌ 削除に失敗しました:$target_file"
		fi
		break_end
	}

	openclaw_backup_list_files() {
		openclaw_backup_render_file_list
		break_end
	}

	openclaw_memory_config_file() {
		echo "${HOME}/.openclaw/openclaw.json"
	}

	openclaw_memory_config_get() {
		local key="$1"
		local default_value="${2:-}"
		local value
		value=$(openclaw config get "$key" 2>/dev/null | head -n 1 | sed -e 's/^"//' -e 's/"$//')
		if [ -z "$value" ] || [ "$value" = "null" ] || [ "$value" = "undefined" ]; then
			echo "$default_value"
			return 0
		fi
		echo "$value"
	}

	openclaw_memory_config_set() {
		local key="$1"
		shift
		openclaw config set "$key" "$@" >/dev/null 2>&1
	}

	openclaw_memory_config_unset() {
		local key="$1"
		openclaw config unset "$key" >/dev/null 2>&1
	}

	openclaw_memory_cleanup_legacy_keys() {
		openclaw_memory_config_unset "memory.local"
	}

	openclaw_memory_status_value() {
		local key="$1"
		openclaw memory status 2>/dev/null | awk -F': ' -v k="$key" '$1==k {print $2; exit}'
	}

	openclaw_memory_expand_path() {
		local raw_path="$1"
		if [ -z "$raw_path" ]; then
			echo ""
			return 0
		fi
		raw_path=$(echo "$raw_path" | sed 's/^[[:space:]]*//;s/[[:space:]]*$//')
		if [[ "$raw_path" == ~* ]]; then
			echo "${raw_path/#\~/$HOME}"
		else
			echo "$raw_path"
		fi
	}

	openclaw_memory_rebuild_index_safe() {
		local store_raw store_file ts backup_file
		store_raw=$(openclaw_memory_status_value "Store")
		store_file=$(openclaw_memory_expand_path "$store_raw")
		if [ -z "$store_file" ] || [ ! -f "$store_file" ]; then
			echo "⚠️ インデックス ライブラリ ファイルが見つかりませんでした。空であるか、存在しない可能性があります。"
			echo "生の値を保存: ${store_raw:-<empty>}"
			echo "インデックスの再作成は引き続き実行されます。"
		else
			ts=$(date +%Y%m%d_%H%M%S)
			backup_file="${store_file}.bak.${ts}"
			if mv "$store_file" "$backup_file"; then
				echo "✅ インデックスのバックアップ:$backup_file"
			else
				echo "⚠️ インデックスのバックアップに失敗しました。再構築を続けてください。"
			fi
		fi
		openclaw memory index --force
		openclaw gateway restart
		echo "✅ インデックスが再構築され、ゲートウェイが自動的に再起動されました。"
		echo ""
		openclaw_memory_render_status
	}

	openclaw_memory_prepare_workspace() {
		local workspace memory_dir
		workspace=$(openclaw_memory_status_value "Workspace")
		if [ -z "$workspace" ]; then
			echo "⚠️ ワークスペースのパスを取得できませんでした。ディレクトリの修復はスキップされました。"
			return 1
		fi
		memory_dir="$workspace/memory"
		if [ ! -d "$memory_dir" ]; then
			echo "🔧 メモリ ディレクトリは存在しないため、自動的に作成されます。$memory_dir"
			mkdir -p "$memory_dir"
		fi
		return 0
	}

	openclaw_memory_render_status() {
		local status_output status_lines config_file config_display
		status_output=$(openclaw memory status 2>/dev/null)
		if [ $? -ne 0 ] || [ -z "$status_output" ]; then
			echo "ステータスの取得に失敗しました"
		else
			status_lines=$(echo "$status_output" | grep -E "^(Provider|Vector|Indexed)" | head -n 3 | sed -e 's/^プロバイダ: /基礎となるソリューション: /' -e 's/^Vector: /Vector ライブラリのステータス: /' -e 's/^インデックス付き: /含まれるファイル: /')
			if [ -z "$status_lines" ]; then
				echo "インストールされていない/起動されていない"
			else
				echo "$status_lines"
			fi
		fi
	}

	openclaw_memory_get_backend() {
		local backend
		backend=$(openclaw_memory_config_get "memory.backend")
		if [ "$backend" = "local" ]; then
			echo "builtin"
		else
			echo "$backend"
		fi
	}

	openclaw_memory_get_local_model_path() {
		openclaw_memory_config_get "agents.defaults.memorySearch.local.modelPath"
	}

	openclaw_memory_local_model_status() {
		local model_path="$1"
		if [ -z "$model_path" ]; then
			echo "missing"
			return
		fi
		if [[ "$model_path" == hf:* ]]; then
			echo "hf"
			return
		fi
		if [ -f "$model_path" ]; then
			echo "ok"
		else
			echo "missing"
		fi
	}

	openclaw_memory_qmd_available() {
		if command -v qmd >/dev/null 2>&1; then
			echo "true"
			return
		fi
		local backend
		backend=$(openclaw_memory_config_get "memory.backend")
		if [ "$backend" = "qmd" ]; then
			echo "true"
			return
		fi
		echo "false"
	}

	openclaw_memory_probe_url() {
		local url="$1"
		if ! command -v curl >/dev/null 2>&1; then
			echo "unknown"
			return
		fi
		if [ -z "$url" ]; then
			echo "unknown"
			return
		fi
		if curl -I -m 2 -s "$url" >/dev/null 2>&1; then
			echo "ok"
		else
			echo "fail"
		fi
	}

	openclaw_memory_recommend() {
		local qmd_ok model_path model_status hf_ok mirror_ok
		qmd_ok=$(openclaw_memory_qmd_available)
		model_path=$(openclaw_memory_get_local_model_path)
		model_status=$(openclaw_memory_local_model_status "$model_path")
		hf_ok=$(openclaw_memory_probe_url "https://huggingface.co")
		mirror_ok=$(openclaw_memory_probe_url "https://hf-mirror.com")

		OPENCLAW_MEMORY_RECOMMEND_REASON=()
		if [ "$qmd_ok" = "true" ]; then
			OPENCLAW_MEMORY_RECOMMEND_REASON+=("QMDが利用可能です")
		else
			OPENCLAW_MEMORY_RECOMMEND_REASON+=("QMDが検出されませんでした")
		fi
		if [ -n "$model_path" ]; then
			OPENCLAW_MEMORY_RECOMMEND_REASON+=("ローカル モデル パス:$model_path")
		else
			OPENCLAW_MEMORY_RECOMMEND_REASON+=("ローカル モデル パスが構成されていません")
		fi
		case "$model_status" in
			ok) OPENCLAW_MEMORY_RECOMMEND_REASON+=("ローカルモデルファイルが存在します") ;;
			hf) OPENCLAW_MEMORY_RECOMMEND_REASON+=("モデルは HF ダウンロード ソースからのものです (中国では遅い/失敗する可能性があります)") ;;
			*) OPENCLAW_MEMORY_RECOMMEND_REASON+=("ローカル モデル ファイルが存在しないか、使用できません") ;;
		esac
		if [ "$hf_ok" = "ok" ]; then
			OPENCLAW_MEMORY_RECOMMEND_REASON+=("ハグフェイス.co にアクセスできます")
		elif [ "$mirror_ok" = "ok" ]; then
			OPENCLAW_MEMORY_RECOMMEND_REASON+=("hf-mirror.com にアクセスできます")
		else
			OPENCLAW_MEMORY_RECOMMEND_REASON+=("Huggingface.co / hf-mirror.com にアクセスできない可能性があります (国内/制限付きネットワークの疑い)")
		fi

		if [ "$qmd_ok" = "true" ]; then
			if [ "$model_status" = "ok" ]; then
				OPENCLAW_MEMORY_RECOMMEND="local"
			elif [ "$model_status" = "hf" ] && { [ "$hf_ok" = "ok" ] || [ "$mirror_ok" = "ok" ]; }; then
				OPENCLAW_MEMORY_RECOMMEND="local"
			elif [ "$model_status" = "hf" ] && [ "$hf_ok" = "fail" ] && [ "$mirror_ok" = "fail" ]; then
				OPENCLAW_MEMORY_RECOMMEND="qmd"
			else
				OPENCLAW_MEMORY_RECOMMEND="qmd"
			fi
		else
			if [ "$model_status" = "ok" ]; then
				OPENCLAW_MEMORY_RECOMMEND="local"
			else
				OPENCLAW_MEMORY_RECOMMEND="qmd"
			fi
		fi
	}


	openclaw_memory_detect_region() {
		OPENCLAW_MEMORY_COUNTRY="unknown"
		OPENCLAW_MEMORY_USE_MIRROR="false"
		if command -v curl >/dev/null 2>&1; then
			OPENCLAW_MEMORY_COUNTRY=$(curl -s -m 2 ipinfo.io/country | tr -d '
' | tr -d '
')
		fi
		case "$OPENCLAW_MEMORY_COUNTRY" in
			CN|HK)
				OPENCLAW_MEMORY_USE_MIRROR="true"
				;;
		esac
	}

	openclaw_memory_select_sources() {
		local hf_ok mirror_ok
		hf_ok=$(openclaw_memory_probe_url "https://huggingface.co")
		mirror_ok=$(openclaw_memory_probe_url "https://hf-mirror.com")
		OPENCLAW_MEMORY_HF_OK="$hf_ok"
		OPENCLAW_MEMORY_MIRROR_OK="$mirror_ok"
		if [ "$OPENCLAW_MEMORY_USE_MIRROR" = "true" ]; then
			if [ "$mirror_ok" = "ok" ]; then
				OPENCLAW_MEMORY_HF_BASE="https://hf-mirror.com"
			elif [ "$hf_ok" = "ok" ]; then
				OPENCLAW_MEMORY_HF_BASE="https://huggingface.co"
			else
				OPENCLAW_MEMORY_HF_BASE="https://hf-mirror.com"
			fi
			OPENCLAW_MEMORY_GH_PROXY="https://gh.kejilion.pro/"
		else
			if [ "$hf_ok" = "ok" ]; then
				OPENCLAW_MEMORY_HF_BASE="https://huggingface.co"
			elif [ "$mirror_ok" = "ok" ]; then
				OPENCLAW_MEMORY_HF_BASE="https://hf-mirror.com"
			else
				OPENCLAW_MEMORY_HF_BASE="https://huggingface.co"
			fi
			OPENCLAW_MEMORY_GH_PROXY="https://"
		fi
	}

	openclaw_memory_download_file() {
		local url="$1"
		local dest="$2"
		mkdir -p "$(dirname "$dest")"
		if command -v curl >/dev/null 2>&1; then
			curl -L --fail --retry 2 -o "$dest" "$url"
			return $?
		fi
		if command -v wget >/dev/null 2>&1; then
			wget -O "$dest" "$url"
			return $?
		fi
		echo "❌ Curl または wget が検出されず、ダウンロードできません。"
		return 1
	}

	openclaw_memory_check_sqlite() {
		if ! command -v sqlite3 >/dev/null 2>&1; then
			echo "⚠️ sqlite3 が検出されない場合、QMD が正しく機能しない可能性があります。"
			return 1
		fi
		local ver
		ver=$(sqlite3 --version 2>/dev/null | awk '{print $1}')
		echo "✅ sqlite3 が利用可能: ${ver:-unknown}"
		echo "ℹ️ sqlite 拡張機能のサポートは確実に検出できないため、継続されます。"
		return 0
	}

	openclaw_memory_ensure_bun() {
		if [ -x "$HOME/.bun/bin/bun" ]; then
			export PATH="$HOME/.bun/bin:$PATH"
		fi
		if command -v bun >/dev/null 2>&1; then
			echo "✅ パンはすでに存在します"
			return 0
		fi
		echo "⬇️バンをインストール..."
		if command -v curl >/dev/null 2>&1; then
			curl -fsSL https://bun.sh/install | bash
		elif command -v wget >/dev/null 2>&1; then
			wget -qO- https://bun.sh/install | bash
		else
			echo "❌curl または wget が検出されないため、bun をインストールできません。"
			return 1
		fi
		if [ -d "$HOME/.bun/bin" ]; then
			export PATH="$HOME/.bun/bin:$PATH"
		fi
		if command -v bun >/dev/null 2>&1; then
			echo "✅パンの取り付けが完了しました"
			return 0
		fi
		echo "❌ バンのインストールに失敗しました"
		return 1
	}

	openclaw_memory_ensure_qmd() {
		local qmd_path
		qmd_path=$(command -v qmd 2>/dev/null || true)
		if [ -n "$qmd_path" ]; then
			echo "✅ qmd はすでに存在します:$qmd_path"
			OPENCLAW_MEMORY_QMD_PATH="$qmd_path"
			return 0
		fi
		openclaw_memory_ensure_bun || return 1
		local qmd_url="${OPENCLAW_MEMORY_GH_PROXY}github.com/tobi/qmd"
		echo "⬇️ bun 経由で qmd をインストールします。$qmd_url"
		bun install -g "$qmd_url"
		qmd_path=$(command -v qmd 2>/dev/null || true)
		if [ -z "$qmd_path" ] && [ -x "$HOME/.bun/bin/qmd" ]; then
			qmd_path="$HOME/.bun/bin/qmd"
		fi
		if [ -z "$qmd_path" ]; then
			echo "❌ qmd のインストールに失敗しました"
			return 1
		fi
		OPENCLAW_MEMORY_QMD_PATH="$qmd_path"
		echo "✅ qmd のインストールが完了しました:$qmd_path"
		return 0
	}

	openclaw_memory_render_auto_summary() {
		echo "---------------------------------------"
		echo "✅ 環境準備完了"
		echo "スキーム: ${OPENCLAW_MEMORY_AUTO_SCHEME:-unknown}"
		if [ "$OPENCLAW_MEMORY_CONFIG_ONLY" = "true" ]; then
			echo "モード: 設定の書き込みのみ (インストールされない/ダウンロードされない)"
		fi
		if [ "$OPENCLAW_MEMORY_PREHEAT" = "true" ]; then
			echo "インデックス: 実行されました"
		else
			echo "インデックス: スキップされました"
		fi
		if [ "$OPENCLAW_MEMORY_RESTARTED" = "true" ]; then
			echo "再起動: 実行されました"
		else
			echo "再起動: スキップされました"
		fi
		if [ -n "$OPENCLAW_MEMORY_QMD_PATH" ]; then
			echo "qmd: $OPENCLAW_MEMORY_QMD_PATH"
		fi
		if [ -n "$OPENCLAW_MEMORY_MODEL_PATH" ]; then
			echo "モデル：$OPENCLAW_MEMORY_MODEL_PATH"
		fi
		if [ -n "$OPENCLAW_MEMORY_COUNTRY" ]; then
			echo "エリア：$OPENCLAW_MEMORY_COUNTRY"
		fi
		if [ -n "$OPENCLAW_MEMORY_HF_BASE" ]; then
			echo "ダウンロードソース:$OPENCLAW_MEMORY_HF_BASE"
		fi
		echo "最終ステータス:"
		openclaw_memory_render_status
		echo "---------------------------------------"
	}

	openclaw_memory_auto_confirm() {
		local scheme_label="$1"
		OPENCLAW_MEMORY_PREHEAT="true"
		OPENCLAW_MEMORY_RESTARTED="false"
		OPENCLAW_MEMORY_CONFIG_ONLY="false"
		echo "自動デプロイメントが実行されようとしています (冗長モード)"
		echo "対象プラン：$scheme_label"
		echo "地域: ${OPENCLAW_MEMORY_COUNTRY:-不明}"
		echo "ミラーソース検出:huggingface.co=${OPENCLAW_MEMORY_HF_OK:-unknown} hf-mirror.com=${OPENCLAW_MEMORY_MIRROR_OK:-unknown}"
		echo "ダウンロード ソース: ${OPENCLAW_MEMORY_HF_BASE:-unknown}"
		if [ -n "$OPENCLAW_MEMORY_EXPECT_PATH" ]; then
			echo "推定ダウンロード パス:$OPENCLAW_MEMORY_EXPECT_PATH"
		fi
		if [ -n "$OPENCLAW_MEMORY_EXPECT_SIZE" ]; then
			echo "考えられるトラフィック/ディスク使用量:$OPENCLAW_MEMORY_EXPECT_SIZE"
		else
			echo "考えられるトラフィック/ディスク使用量: 実際の状況によって異なります"
		fi
		echo "確認後、自動的にインストール/ダウンロード、構成の書き込み、インデックスの構築、ゲートウェイの再起動が行われます。"
		echo "詳細オプション: config を入力して構成のみを書き込みます (インストールなし、ダウンロードなし、インデックス作成なし、再起動なし)。"
		read -e -p "続行することを確認するには「yes」と入力します (デフォルトは N):" confirm_step
		case "$confirm_step" in
			yes|YES)
				OPENCLAW_MEMORY_PREHEAT="true"
				;;
			config|CONFIG)
				OPENCLAW_MEMORY_CONFIG_ONLY="true"
				OPENCLAW_MEMORY_PREHEAT="false"
				;;
			*)
				echo "自動デプロイがキャンセルされました。"
				return 1
				;;
		esac
		if [ "$OPENCLAW_MEMORY_CONFIG_ONLY" = "true" ]; then
			echo "⚠️ 構成の書き込みのみを選択し、インストールやダウンロードは行いません"
		else
			echo "✅ インデックスが自動的に構築され、ゲートウェイが再起動されます。"
		fi
		return 0
	}

	openclaw_memory_auto_setup_qmd() {
		echo "🔍 QMD環境を検出"
		openclaw_memory_cleanup_legacy_keys
		openclaw_memory_check_sqlite || true
		if [ "$OPENCLAW_MEMORY_CONFIG_ONLY" = "true" ]; then
			if command -v qmd >/dev/null 2>&1; then
				OPENCLAW_MEMORY_QMD_PATH=$(command -v qmd)
			else
				OPENCLAW_MEMORY_QMD_PATH="qmd"
			fi
		else
			openclaw_memory_ensure_qmd || return 1
		fi
		local backend
		backend=$(openclaw_memory_get_backend)
		if [ "$backend" = "qmd" ]; then
			echo "✅memory.backendはすでにqmdです"
		else
			openclaw_memory_config_set "memory.backend" "qmd"
			echo "✅memory.backend=qmdが設定されています"
		fi
		local qmd_cmd
		qmd_cmd=$(openclaw_memory_config_get "memory.qmd.command")
		if [ -z "$qmd_cmd" ] || [[ "$qmd_cmd" != /* ]] || [ "$qmd_cmd" != "$OPENCLAW_MEMORY_QMD_PATH" ]; then
			openclaw_memory_config_set "memory.qmd.command" "$OPENCLAW_MEMORY_QMD_PATH"
			echo "✅memory.qmd.commandに書き込まれます:$OPENCLAW_MEMORY_QMD_PATH"
		else
			echo "✅memory.qmd.commandは正しいです"
		fi
		if [ "$OPENCLAW_MEMORY_PREHEAT" = "true" ]; then
			echo "🔥 ウォームインデックス (おそらくダウンロードモデル)"
			openclaw_memory_prepare_workspace
			openclaw memory index --force
		else
			echo "⏭️ 予熱をスキップしました"
		fi
		echo "✅ QMD自動展開が完了しました"
	}

	openclaw_memory_auto_setup_local() {
		echo "🔍 ローカル環境を検出"
		openclaw_memory_cleanup_legacy_keys
		local backend provider
		backend=$(openclaw_memory_get_backend)
		if [ "$backend" = "builtin" ] || [ "$backend" = "local" ]; then
			echo "✅memory.backendはすでに組み込まれています"
		else
			openclaw_memory_config_set "memory.backend" "builtin"
			echo "✅memory.backend=builtinが設定されています"
		fi
		provider=$(openclaw_memory_config_get "agents.defaults.memorySearch.provider")
		if [ "$provider" = "local" ]; then
			echo "✅memorySearch.providerはすでにローカルです"
		else
			openclaw_memory_config_set "agents.defaults.memorySearch.provider" "local"
			echo "✅ Agents.defaults.memorySearch.provider=ローカルセット"
		fi

		local model_path model_status
		model_path=$(openclaw_memory_get_local_model_path)
		model_path=$(openclaw_memory_expand_path "$model_path")
		model_status=$(openclaw_memory_local_model_status "$model_path")
		if [ "$model_status" = "ok" ]; then
			echo "✅ モデルファイルはすでに存在します:$model_path"
			OPENCLAW_MEMORY_MODEL_PATH="$model_path"
		else
			local model_name="embeddinggemma-300M-Q8_0.gguf"
			local model_dir="$HOME/.openclaw/models/embedding"
			local model_dest="$model_dir/$model_name"
			local model_url="${OPENCLAW_MEMORY_HF_BASE}/ggml-org/embeddinggemma-300M-GGUF/resolve/main/$model_name"
			if [ "$OPENCLAW_MEMORY_CONFIG_ONLY" = "true" ]; then
				echo "ℹ️ 書き込み専用構成モード: モデルのダウンロードをスキップ"
				OPENCLAW_MEMORY_MODEL_PATH="$model_dest"
			else
				if [ -f "$model_dest" ]; then
					echo "✅ デフォルトのモデルファイルが見つかりました:$model_dest"
				else
					echo "⬇️ ダウンロードモデル:$model_url"
					openclaw_memory_download_file "$model_url" "$model_dest" || return 1
					echo "✅ モデルがダウンロードされました:$model_dest"
				fi
				OPENCLAW_MEMORY_MODEL_PATH="$model_dest"
			fi
			openclaw_memory_config_set "agents.defaults.memorySearch.local.modelPath" "$model_dest"
			echo "✅ モデルパスが記述されている"
		fi
		if [ "$OPENCLAW_MEMORY_PREHEAT" = "true" ]; then
			echo "🔥 ウォームインデックス (おそらくダウンロードモデル)"
			openclaw_memory_prepare_workspace
			openclaw memory index --force
		else
			echo "⏭️ 予熱をスキップしました"
		fi
		echo "✅ ローカル自動展開が完了しました"
	}

	openclaw_memory_auto_setup_run() {
		local scheme="$1"
		local scheme_label
		OPENCLAW_MEMORY_QMD_PATH=""
		OPENCLAW_MEMORY_MODEL_PATH=""
		OPENCLAW_MEMORY_EXPECT_PATH=""
		OPENCLAW_MEMORY_EXPECT_SIZE=""
		openclaw_memory_detect_region
		openclaw_memory_select_sources
		if [ "$scheme" = "auto" ]; then
			openclaw_memory_recommend
			scheme="$OPENCLAW_MEMORY_RECOMMEND"
		fi
		case "$scheme" in
			qmd)
				scheme_label="QMD"
				OPENCLAW_MEMORY_EXPECT_PATH="$HOME/.bun (qmd インストールディレクトリ)"
				OPENCLAW_MEMORY_EXPECT_SIZE="約20～50MB"
				;;
			local)
				scheme_label="Local"
				OPENCLAW_MEMORY_EXPECT_PATH="$HOME/.openclaw/models/embedding/embeddinggemma-300M-Q8_0.gguf"
				OPENCLAW_MEMORY_EXPECT_SIZE="約350～600MB"
				;;
			*)
				echo "❌ 不明な解決策:$scheme"
				return 1
				;;
		esac
		OPENCLAW_MEMORY_AUTO_SCHEME="$scheme_label"
		openclaw_memory_auto_confirm "$scheme_label" || return 0
		case "$scheme" in
			qmd) openclaw_memory_auto_setup_qmd || return 1 ;;
			local) openclaw_memory_auto_setup_local || return 1 ;;
			*) return 1 ;;
		esac
		if [ "$OPENCLAW_MEMORY_CONFIG_ONLY" = "true" ]; then
			OPENCLAW_MEMORY_RESTARTED="false"
			openclaw_memory_render_auto_summary
			return 0
		fi
		echo "♻️ OpenClaw ゲートウェイを再起動します"
		if declare -F start_gateway >/dev/null 2>&1; then
			start_gateway
		else
			openclaw gateway restart
		fi
		OPENCLAW_MEMORY_RESTARTED="true"
		openclaw_memory_render_auto_summary
		return 0
	}

	openclaw_memory_auto_setup_menu() {
		while true; do
			clear
			echo "======================================="
			echo "メモリソリューションの自動導入"
			echo "======================================="
			echo "1. QMD"
			echo "2. Local"
			echo "3.オート（自動選択）"
			echo "0. 前のレベルに戻ります"
			echo "---------------------------------------"
			read -e -p "選択肢を入力してください:" auto_choice
			case "$auto_choice" in
				1)
					openclaw_memory_auto_setup_run "qmd"
					break_end
					;;
				2)
					openclaw_memory_auto_setup_run "local"
					break_end
					;;
				3)
					openclaw_memory_auto_setup_run "auto"
					break_end
					;;
				0)
					return 0
					;;
				*)
					echo "選択が無効です。もう一度お試しください。"
					sleep 1
					;;
			esac
		done
	}

	openclaw_memory_apply_scheme() {
		local scheme="$1"
		openclaw_memory_cleanup_legacy_keys
		case "$scheme" in
			qmd)
				openclaw_memory_config_set "memory.backend" "qmd"
				if [ $? -ne 0 ]; then
					echo "❌ 設定の書き込みに失敗しました"
					return 1
				fi
				openclaw_memory_config_set "memory.qmd.command" "qmd" >/dev/null 2>&1
				;;
			local)
				openclaw_memory_config_set "memory.backend" "builtin"
				if [ $? -ne 0 ]; then
					echo "❌ 設定の書き込みに失敗しました"
					return 1
				fi
				openclaw_memory_config_set "agents.defaults.memorySearch.provider" "local" >/dev/null 2>&1
				;;
			*)
				echo "❌ 不明な解決策:$scheme"
				return 1
			esac
		echo "✅ メモリスキーム構成が更新されました"
		return 0
	}

	openclaw_memory_offer_restart() {
		echo "設定は書き込まれており、OpenClaw ゲートウェイの再起動後に有効にするには、再起動する必要があります。"
		read -e -p "今すぐ OpenClaw ゲートウェイを再起動しますか? (はい/いいえ):" restart_choice
		if [[ "$restart_choice" =~ ^[Nn]$ ]]; then
			echo "再起動はスキップされました。後で実行できます: openclaw ゲートウェイの再起動"
			return 0
		fi
		if declare -F start_gateway >/dev/null 2>&1; then
			start_gateway
		else
			openclaw gateway restart
		fi
	}

	openclaw_memory_fix_index() {
		local backend
		backend=$(openclaw_memory_get_backend)
		if [ "$backend" = "qmd" ] && ! command -v qmd >/dev/null 2>&1; then
			echo "⚠️ 現在のスキームは QMD として検出されますが、qmd コマンドがインストールされていません。"
			echo "ローカルに切り替えるか、bun + qmd をインストールして再試行してください。"
		fi
		echo "適用可能なシナリオ: インデックス付きの分子 > 分母 (収集を繰り返すと異常なカウントが発生します)"
		read -e -p "includeDefaultMemory を false に設定してもよろしいですか? (y/N):" confirm_fix
		if [[ ! "$confirm_fix" =~ ^[Yy]$ ]]; then
			echo "キャンセル。"
			break_end
			return 0
		fi
		openclaw_memory_config_set "memory.qmd.includeDefaultMemory" false
		if [ $? -ne 0 ]; then
			echo "❌ 設定の書き込みに失敗しました"
			break_end
			return 1
		fi
		echo "✅ includeDefaultMemory=false セット"
		echo "推奨される実行: インデックスをクリーンアップして再構築する"
		read -e -p "インデックスをクリーンして再構築しますか (推奨)? (はい/いいえ):" rebuild_choice
		if [[ ! "$rebuild_choice" =~ ^[Nn]$ ]]; then
			openclaw_memory_rebuild_index_safe
		else
			echo "ステータスは後でメモリ管理で確認できます。"
		fi
		break_end
	}

	openclaw_memory_scheme_menu() {
		while true; do
			clear
			echo "======================================="
			echo "OpenClaw メモリ ソリューション"
			echo "======================================="
			local backend current_label
			backend=$(openclaw_memory_get_backend)
			case "$backend" in
				qmd) current_label="QMD" ;;
				builtin|local) current_label="Local" ;;
				*) current_label="未設定" ;;
			esac
			echo "現在の計画:$current_label"
			echo ""
			echo "QMD: qmd コマンドに依存する軽量インデックス (ネットワーク制約に適しています)"
			echo "ローカル: 埋め込みモデル ファイルに依存するローカル ベクトル取得"
			echo "自動: 自動推奨 (可用性 + ネットワーク検出に基づく)"
			echo "---------------------------------------"
			echo "1. QMD の切り替え (自動展開/既にインストールされている場合はスキップ)"
			echo "2. ローカルに切り替えます (自動展開/既にインストールされている場合はスキップ)"
			echo "3. Auto (自動推奨と自動デプロイ)"
			echo "0. 前のレベルに戻ります"
			echo "---------------------------------------"
			read -e -p "選択肢を入力してください:" scheme_choice
			case "$scheme_choice" in
				1)
					openclaw_memory_auto_setup_run "qmd"
					break_end
					;;
				2)
					openclaw_memory_auto_setup_run "local"
					break_end
					;;
				3)
					openclaw_memory_auto_setup_run "auto"
					break_end
					;;
				0)
					return 0
					;;
				*)
					echo "選択が無効です。もう一度お試しください。"
					sleep 1
					;;
			esac
		done
	}

	openclaw_memory_file_collect() {
		OPENCLAW_MEMORY_FILES=()
		local base_dir="${HOME}/.openclaw/workspace"
		local memory_dir="$base_dir/memory"
		local memory_file="$base_dir/MEMORY.md"
		[ -f "$memory_file" ] && OPENCLAW_MEMORY_FILES+=("$memory_file")
		if [ -d "$memory_dir" ]; then
			while IFS= read -r file; do
				[ -f "$file" ] && OPENCLAW_MEMORY_FILES+=("$file")
			done < <(find "$memory_dir" -type f -name '*.md' | sort)
		fi
	}

	openclaw_memory_file_render_list() {
		local base_dir="${HOME}/.openclaw/workspace"
		openclaw_memory_file_collect
		if [ ${#OPENCLAW_MEMORY_FILES[@]} -eq 0 ]; then
			echo "メモリファイルが見つかりません。"
			return 0
		fi
		echo "番号 |相対パス |サイズ |修正時間"
		echo "---------------------------------------"
		local i file rel size mtime
		for i in "${!OPENCLAW_MEMORY_FILES[@]}"; do
			file="${OPENCLAW_MEMORY_FILES[$i]}"
			rel="${file#$base_dir/}"
			size=$(ls -lh "$file" | awk '{print $5}')
			mtime=$(date -d "$(stat -c %y "$file")" '+%Y-%m-%d %H:%M:%S' 2>/dev/null || stat -c %y "$file" | awk '{print $1" "$2}')
			printf "%s | %s | %s | %s\\n" "$((i+1))" "$rel" "$size" "$mtime"
		done
	}

	openclaw_memory_view_file() {
		local file="$1"
		[ -f "$file" ] || {
			echo "❌ ファイルが存在しません:$file"
			return 1
		}
		local total_lines
		total_lines=$(wc -l < "$file" 2>/dev/null || echo 0)
		local default_lines=120
		local start_line count
		echo "書類：$file"
		echo "総行数:$total_lines"
		read -e -p "開始行を入力してください (Enter キーを押すとデフォルトで行の終わりになります)$default_linesわかりました）：" start_line
		read -e -p "表示する行数を入力してください (デフォルトでは Enter を押します)$default_lines）: " count
		[ -z "$count" ] && count=$default_lines
		if [ -z "$start_line" ]; then
			if [ "$total_lines" -le "$count" ]; then
				start_line=1
			else
				start_line=$((total_lines - count + 1))
			fi
		fi
		if ! [[ "$start_line" =~ ^[0-9]+$ ]] || ! [[ "$count" =~ ^[0-9]+$ ]]; then
			echo "❌ 有効な番号を入力してください。"
			return 1
		fi
		if [ "$start_line" -lt 1 ]; then
			start_line=1
		fi
		if [ "$count" -le 0 ]; then
			echo "❌ 行数は 0 より大きくなければなりません。"
			return 1
		fi
		local end_line=$((start_line + count - 1))
		if [ "$end_line" -gt "$total_lines" ]; then
			end_line=$total_lines
		fi
		if [ "$total_lines" -eq 0 ]; then
			echo "(空のファイル)"
			return 0
		fi
		echo "---------------------------------------"
		sed -n "${start_line},${end_line}p" "$file"
		echo "---------------------------------------"
	}

	openclaw_memory_files_menu() {
		while true; do
			clear
			echo "======================================="
			echo "OpenClaw メモリ ファイル"
			echo "======================================="
			openclaw_memory_file_render_list
			echo "---------------------------------------"
			read -e -p "表示するファイル番号を入力してください (0 を返します):" file_choice
			if [ "$file_choice" = "0" ]; then
				return 0
			fi
			if ! [[ "$file_choice" =~ ^[0-9]+$ ]]; then
				echo "選択が無効です。もう一度お試しください。"
				sleep 1
				continue
			fi
			openclaw_memory_file_collect
			if [ ${#OPENCLAW_MEMORY_FILES[@]} -eq 0 ]; then
				read -p "メモリ ファイルが見つかりません。Enter キーを押して戻ります..."
				return 0
			fi
			local idx=$((file_choice-1))
			if [ "$idx" -lt 0 ] || [ "$idx" -ge ${#OPENCLAW_MEMORY_FILES[@]} ]; then
				echo "番号が無効です。もう一度お試しください。"
				sleep 1
				continue
			fi
			openclaw_memory_view_file "${OPENCLAW_MEMORY_FILES[$idx]}"
			read -p "Enter キーを押してリストに戻ります..."
			done
	}

	openclaw_memory_menu() {
		send_stats "OpenClaw のメモリ管理"
		while true; do
			clear
			echo "======================================="
			echo "OpenClaw のメモリ管理"
			echo "======================================="
			openclaw_memory_render_status
			echo "1. メモリインデックスを更新する"
			echo "2. メモリファイルを表示する"
			echo "3. インデックス修復（インデックス例外）"
			echo "4. メモリ ソリューション (QMD/ローカル/自動)"
			echo "0. 前のレベルに戻ります"
			echo "---------------------------------------"
			read -e -p "選択肢を入力してください:" memory_choice
			case "$memory_choice" in
				1)
					echo "メモリインデックスは間もなく更新されます。"
					read -e -p "最初の確認: 「yes」と入力して続行します:" confirm_step1
					if [ "$confirm_step1" != "yes" ]; then
						echo "キャンセル。"
						break_end
						continue
					fi
				openclaw_memory_prepare_workspace
				read -e -p "2 番目の確認: 全額を使用するには、force を入力します (増分の場合は空白のままにします):" confirm_step2
				if [ "$confirm_step2" = "force" ]; then
					echo "⚠️ 完全な再構築はより徹底的ですが、時間がかかります。"
					echo "推奨事項: 安全に再構築するには、再構築を入力してください (最初にインデックス データベースをバックアップします)。"
					read -e -p "3 番目の確認: 安全な再構築を実行するには、「再構築」と入力します。 Enter キーを押して通常の力で続行します。" confirm_step3
					if [ "$confirm_step3" = "rebuild" ]; then
						openclaw_memory_rebuild_index_safe
					else
						openclaw memory index --force
						openclaw gateway restart
						echo "✅ インデックスが再構築され、ゲートウェイが自動的に再起動されました。"
					fi
				else
					openclaw memory index
				fi
				break_end
					;;
				2)
					openclaw_memory_files_menu
					;;
				3)
					openclaw_memory_fix_index
					;;
				4)
					openclaw_memory_scheme_menu
					;;
				0)
					return 0
					;;
				*)
					echo "選択が無効です。もう一度お試しください。"
					sleep 1
					;;
			esac
		done
	}

	openclaw_backup_restore_menu() {

		send_stats "OpenClaw のバックアップと復元"
		while true; do
			clear
			echo "======================================="
			echo "OpenClaw のバックアップと復元"
			echo "======================================="
			openclaw_backup_render_file_list
			echo "---------------------------------------"
			echo "1. メモリ全体をバックアップする"
			echo "2. メモリ全体を復元する"
			echo "3. OpenClaw プロジェクトをバックアップします (デフォルトのセーフ モード)"
			echo "4. OpenClaw プロジェクトの復元 (高度/高リスク)"
			echo "5. バックアップファイルを削除する"
			echo "0. 前のレベルに戻ります"
			echo "---------------------------------------"
			read -e -p "選択肢を入力してください:" backup_choice

			case "$backup_choice" in
				1) openclaw_memory_backup_export ;;
				2) openclaw_memory_backup_import ;;
				3) openclaw_project_backup_export ;;
				4) openclaw_project_backup_import ;;
				5) openclaw_backup_delete_file ;;
				0) return 0 ;;
				*)
					echo "選択が無効です。もう一度お試しください。"
					sleep 1
					;;
			esac
		done
	}


	update_moltbot() {
		echo "OpenClaw を更新..."
		send_stats "OpenClaw を更新..."
		install_node_and_tools
		git config --global url."${gh_https_url}github.com/".insteadOf ssh://git@github.com/
		git config --global url."${gh_https_url}github.com/".insteadOf git@github.com:
		npm install -g openclaw@latest
		crontab -l 2>/dev/null | grep -v "s gateway" | crontab -
		start_gateway
		hash -r
		add_app_id
		echo "アップデート完了"
		break_end
	}


	uninstall_moltbot() {
		echo "OpenClaw をアンインストールします..."
		send_stats "OpenClaw をアンインストールします..."
		openclaw uninstall
		npm uninstall -g openclaw
		crontab -l 2>/dev/null | grep -v "s gateway" | crontab -
		rm -rf /root/.openclaw
		hash -r
		sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
		echo "アンインストールが完了しました"
		break_end
	}

	nano_openclaw_json() {
		send_stats "OpenClaw 設定ファイルを編集する"
		install nano
		nano ~/.openclaw/openclaw.json
		start_gateway
	}






	openclaw_find_webui_domain() {
		local conf domain_list

		domain_list=$(
			grep -R "18789" /home/web/conf.d/*.conf 2>/dev/null \
			| awk -F: '{print $1}' \
			| sort -u \
			| while read conf; do
				basename "$conf" .conf
			done
		)

		if [ -n "$domain_list" ]; then
			echo "$domain_list"
		fi
	}



	openclaw_show_webui_addr() {
		local local_ip token domains

		echo "=================================="
		echo "OpenClaw WebUI アクセス アドレス"
		local_ip="127.0.0.1"

		token=$(
			openclaw dashboard 2>/dev/null \
			| sed -n 's/.*:18789\/#token=\([a-f0-9]\+\).*/\1/p' \
			| head -n 1
		)
		echo
		echo "ローカルアドレス:"
		echo "http://${local_ip}:18789/#token=${token}"

		domains=$(openclaw_find_webui_domain)
		if [ -n "$domains" ]; then
			echo "ドメイン名アドレス:"
			echo "$domains" | while read d; do
				echo "https://${d}/#token=${token}"
			done
		fi

		echo "=================================="
	}



	# ドメイン名を追加します（指定した関数を呼び出します）
	openclaw_domain_webui() {
		add_yuming
		ldnmp_Proxy ${yuming} 127.0.0.1 18789

		token=$(
			openclaw dashboard 2>/dev/null \
			| sed -n 's/.*:18789\/#token=\([a-f0-9]\+\).*/\1/p' \
			| head -n 1
		)

		clear
		echo "訪問先住所:"
		echo "https://${yuming}/#token=$token"
		echo "まず URL にアクセスしてデバイス ID をトリガーし、Enter キーを押してペアリングを続行します。"
		read
		echo -e "${gl_kjlan}デバイスリストをロード中...${gl_bai}"
		# ドメイン名を allowedOrigins に自動的に追加する
		config_file="$HOME/.openclaw/openclaw.json"
		if [ -f "$config_file" ]; then
			new_origin="https://${yuming}"
			# jq を使用して JSON を安全に変更し、構造が存在し、ドメイン名が繰り返し追加されないようにします。
			if command -v jq >/dev/null 2>&1; then
				tmp_json=$(mktemp)
				jq 'if .gateway.controlUi == null then .gateway.controlUi = {"allowedOrigins": ["http://127.0.0.1"]} else . end | if (.gateway.controlUi.allowedOrigins | contains([$origin]) | not) then .gateway.controlUi.allowedOrigins += [$origin] else . end' --arg origin "$new_origin" "$config_file" > "$tmp_json" && mv "$tmp_json" "$config_file"
				echo -e "${gl_kjlan}ドメイン名は${yuming}allowedOrigins 構成を追加する${gl_bai}"
				openclaw gateway restart >/dev/null 2>&1
			fi
		fi

		openclaw devices list

		read -e -p "Request_Key を入力してください:" Request_Key

		[ -z "$Request_Key" ] && {
			echo "Request_Key を空にすることはできません"
			return 1
		}

		openclaw devices approve "$Request_Key"

	}

	# ドメイン名の削除
	openclaw_remove_domain() {
		echo "ドメイン名の形式 example.com (https:// なし)"
		web_del
	}

	# メインメニュー
	openclaw_webui_menu() {

		send_stats "WebUI へのアクセスと設定"
		while true; do
			clear
			openclaw_show_webui_addr
			echo
			echo "1. ドメイン名アクセスを追加する"
			echo "2. ドメイン名アクセスの削除"
			echo "0.終了"
			echo
			read -e -p "選択してください:" choice

			case "$choice" in
				1)
					openclaw_domain_webui
					echo
					read -p "Enter を押してメニューに戻ります..."
					;;
				2)
					openclaw_remove_domain
					read -p "Enter を押してメニューに戻ります..."
					;;
				0)
					break
					;;
				*)
					echo "無効なオプション"
					sleep 1
					;;
			esac
		done
	}



	# メインループ
	while true; do
		show_menu
		read choice
		case $choice in
			1) install_moltbot ;;
			2) start_bot ;;
			3) stop_bot ;;
			4) view_logs ;;
			5) change_model ;;
			6) openclaw_api_manage_menu ;;
			7) change_tg_bot_code ;;
			8) install_plugin ;;
			9) install_skill ;;
			10) nano_openclaw_json ;;
			11) send_stats "初期設定ウィザード"
				openclaw onboard --install-daemon
				break_end
				;;
			12) send_stats "健全性の検出と修復"
				openclaw doctor --fix
				send_stats "OpenClaw API の同期トリガー"
				if sync_openclaw_api_models; then
					start_gateway
				else
					echo "❌ API モデルの同期に失敗しました。ゲートウェイの再起動は中止されました。プロバイダー/モデルを確認し、戻ってからもう一度お試しください。"
				fi
				break_end
			 	;;
			13) openclaw_webui_menu ;;
			14) send_stats "TUI コマンドラインでの会話"
				openclaw tui
				break_end
			 	;;
			15) openclaw_memory_menu ;;
			16) openclaw_backup_restore_menu ;;
			17) update_moltbot ;;
			18) uninstall_moltbot ;;
			*) break ;;
		esac
	done

}




linux_panel() {

local sub_choice="$1"

clear
cd ~
install git
echo -e "${gl_kjlan}アプリケーションリストは更新中です。お待ちください...${gl_bai}"
if [ ! -d apps/.git ]; then
	timeout 10s git clone ${gh_proxy}github.com/kejilion/apps.git
else
	cd apps
	# git pull origin main > /dev/null 2>&1
	timeout 10s git pull ${gh_proxy}github.com/kejilion/apps.git main > /dev/null 2>&1
fi

while true; do

	if [ -z "$sub_choice" ]; then
	  clear
	  echo -e "アプリケーション市場"
	  echo -e "${gl_kjlan}-------------------------"

	  local app_numbers=$([ -f /home/docker/appno.txt ] && cat /home/docker/appno.txt || echo "")

	  # ループで色を設定する
	  for i in {1..150}; do
		  if echo "$app_numbers" | grep -q "^$i$"; then
			  declare "color$i=${gl_lv}"
		  else
			  declare "color$i=${gl_bai}"
		  fi
	  done

	  echo -e "${gl_kjlan}1.   ${color1}パゴダパネル正式版${gl_kjlan}2.   ${color2}aaPanel パゴダ国際版"
	  echo -e "${gl_kjlan}3.   ${color3}1Panel 新世代管理パネル${gl_kjlan}4.   ${color4}NginxProxyManager 視覚化パネル"
	  echo -e "${gl_kjlan}5.   ${color5}OpenList マルチストア ファイル リスト プログラム${gl_kjlan}6.   ${color6}Ubuntu リモート デスクトップ Web バージョン"
	  echo -e "${gl_kjlan}7.   ${color7}Nezha Probe VPS 監視パネル${gl_kjlan}8.   ${color8}QBオフラインBT磁気ダウンロードパネル"
	  echo -e "${gl_kjlan}9.   ${color9}Poste.io メール サーバー プログラム${gl_kjlan}10.  ${color10}RocketChat 複数人オンライン チャット システム"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}11.  ${color11}ZenTao プロジェクト管理ソフトウェア${gl_kjlan}12.  ${color12}Qinglong パネルのスケジュールされたタスク管理プラットフォーム"
	  echo -e "${gl_kjlan}13.  ${color13}Cloudreve ネットワークディスク${gl_huang}★${gl_bai}                     ${gl_kjlan}14.  ${color14}シンプルなピクチャーベッド画像管理プログラム"
	  echo -e "${gl_kjlan}15.  ${color15}emby マルチメディア管理システム${gl_kjlan}16.  ${color16}Speedtest スピードテストパネル"
	  echo -e "${gl_kjlan}17.  ${color17}AdGuardHome はアドウェアを削除します${gl_kjlan}18.  ${color18}Onlyofficeオンラインオフィス OFFICE"
	  echo -e "${gl_kjlan}19.  ${color19}Leichi WAF ファイアウォール パネル${gl_kjlan}20.  ${color20}ポーターコンテナ管理パネル"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}21.  ${color21}VScode Web バージョン${gl_kjlan}22.  ${color22}UptimeKuma監視ツール"
	  echo -e "${gl_kjlan}23.  ${color23}メモウェブメモ${gl_kjlan}24.  ${color24}Webtop リモート デスクトップ Web バージョン${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}25.  ${color25}Nextcloud ネットワーク ディスク${gl_kjlan}26.  ${color26}QD-Today スケジュールされたタスク管理フレームワーク"
	  echo -e "${gl_kjlan}27.  ${color27}Dockge コンテナ スタック管理パネル${gl_kjlan}28.  ${color28}LibreSpeed 速度テストツール"
	  echo -e "${gl_kjlan}29.  ${color29}searxng 集約検索ステーション${gl_huang}★${gl_bai}                 ${gl_kjlan}30.  ${color30}PhotoPrismプライベートアルバムシステム"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}31.  ${color31}StirlingPDF ツール コレクション${gl_kjlan}32.  ${color32}無料のオンライングラフ作成ソフトウェアdrawio${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${color33}Sun-Panel ナビゲーション パネル${gl_kjlan}34.  ${color34}Pingvin-Share ファイル共有プラットフォーム"
	  echo -e "${gl_kjlan}35.  ${color35}ミニマリストの友達の輪${gl_kjlan}36.  ${color36}LobeChatAIチャットアグリゲーションサイト"
	  echo -e "${gl_kjlan}37.  ${color37}MyIP ツールボックス${gl_huang}★${gl_bai}                        ${gl_kjlan}38.  ${color38}Xiaoya alistファミリーバケット"
	  echo -e "${gl_kjlan}39.  ${color39}Bililive ライブ配信録画ツール${gl_kjlan}40.  ${color40}webssh Web版 SSH接続ツール"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}41.  ${color41}マウス管理パネル${gl_kjlan}42.  ${color42}Nexterm リモート接続ツール"
	  echo -e "${gl_kjlan}43.  ${color43}RustDesk リモート デスクトップ (サーバー)${gl_huang}★${gl_bai}          ${gl_kjlan}44.  ${color44}RustDesk リモート デスクトップ (リレー)${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}45.  ${color45}Docker アクセラレーション ステーション${gl_kjlan}46.  ${color46}GitHub アクセラレーション ステーション${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}47.  ${color47}プロメテウスの監視${gl_kjlan}48.  ${color48}Prometheus (ホスト監視)"
	  echo -e "${gl_kjlan}49.  ${color49}Prometheus (コンテナ監視)${gl_kjlan}50.  ${color50}補充監視ツール"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}51.  ${color51}PVEオープンチックパネル${gl_kjlan}52.  ${color52}DPanel コンテナ管理パネル"
	  echo -e "${gl_kjlan}53.  ${color53}llama3チャットAI大型モデル${gl_kjlan}54.  ${color54}AMH ホスト Web サイト構築管理パネル"
	  echo -e "${gl_kjlan}55.  ${color55}FRPイントラネット普及（サーバー）${gl_huang}★${gl_bai}	         ${gl_kjlan}56.  ${color56}FRPイントラネット普及（クライアント）${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}57.  ${color57}ディープシークチャットAI大型モデル${gl_kjlan}58.  ${color58}Dify 大規模モデルのナレッジ ベース${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}59.  ${color59}NewAPI 大規模モデル資産管理${gl_kjlan}60.  ${color60}JumpServer オープンソース要塞マシン"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}61.  ${color61}オンライン翻訳サーバー${gl_kjlan}62.  ${color62}RAGFlow 大規模モデルのナレッジ ベース"
	  echo -e "${gl_kjlan}63.  ${color63}OpenWebUI セルフホスト型 AI プラットフォーム${gl_huang}★${gl_bai}             ${gl_kjlan}64.  ${color64}ITツールツールボックス"
	  echo -e "${gl_kjlan}65.  ${color65}n8n自動ワークフロープラットフォーム${gl_huang}★${gl_bai}               ${gl_kjlan}66.  ${color66}yt-dlp ビデオ ダウンロード ツール"
	  echo -e "${gl_kjlan}67.  ${color67}ddns-go ダイナミック DNS 管理ツール${gl_huang}★${gl_bai}            ${gl_kjlan}68.  ${color68}AllinSSL 証明書管理プラットフォーム"
	  echo -e "${gl_kjlan}69.  ${color69}SFTPGo ファイル転送ツール${gl_kjlan}70.  ${color70}AstBot チャットボット フレームワーク"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}71.  ${color71}Navidrome プライベート ミュージック サーバー${gl_kjlan}72.  ${color72}bitwarden パスワードマネージャー${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}73.  ${color73}LibreTV プライベートムービー${gl_kjlan}74.  ${color74}MoonTV のプライベート ムービー"
	  echo -e "${gl_kjlan}75.  ${color75}メロディー音楽の魔法使い${gl_kjlan}76.  ${color76}オンライン DOS 古いゲーム"
	  echo -e "${gl_kjlan}77.  ${color77}Thunder オフライン ダウンロード ツール${gl_kjlan}78.  ${color78}PandaWiki インテリジェント文書管理システム"
	  echo -e "${gl_kjlan}79.  ${color79}Beszel サーバーの監視${gl_kjlan}80.  ${color80}リンクワーデンのブックマーク管理"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}81.  ${color81}JitsiMeet ビデオ会議${gl_kjlan}82.  ${color82}gpt-load 高性能 AI 透過プロキシ"
	  echo -e "${gl_kjlan}83.  ${color83}komariサーバー監視ツール${gl_kjlan}84.  ${color84}Wallos の個人財務管理ツール"
	  echo -e "${gl_kjlan}85.  ${color85}イミッチピクチャービデオマネージャー${gl_kjlan}86.  ${color86}ジェリーフィンメディア管理システム"
	  echo -e "${gl_kjlan}87.  ${color87}SyncTV は一緒に映画を見るための素晴らしいツールです${gl_kjlan}88.  ${color88}Owncast の自己ホスト型ライブ ストリーミング プラットフォーム"
	  echo -e "${gl_kjlan}89.  ${color89}FileCodeBox ファイルエクスプレス${gl_kjlan}90.  ${color90}マトリックス分散型チャットプロトコル"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}91.  ${color91}gitea プライベート コード リポジトリ${gl_kjlan}92.  ${color92}FileBrowser ファイルマネージャー"
	  echo -e "${gl_kjlan}93.  ${color93}Dufs のミニマリスト静的ファイル サーバー${gl_kjlan}94.  ${color94}Gopeed高速ダウンロードツール"
	  echo -e "${gl_kjlan}95.  ${color95}ペーパーレス文書管理プラットフォーム${gl_kjlan}96.  ${color96}2FAuth セルフホスト型 2 段階認証システム"
	  echo -e "${gl_kjlan}97.  ${color97}WireGuard ネットワーキング (サーバー)${gl_kjlan}98.  ${color98}WireGuard ネットワーキング (クライアント)"
	  echo -e "${gl_kjlan}99.  ${color99}DSM Synology 仮想マシン${gl_kjlan}100. ${color100}Syncthing ピアツーピア ファイル同期ツール"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}101. ${color101}AI動画生成ツール${gl_kjlan}102. ${color102}VoceChat 複数人オンライン チャット システム"
	  echo -e "${gl_kjlan}103. ${color103}Umami ウェブサイト統計ツール${gl_kjlan}104. ${color104}ストリーム 4 層プロキシ転送ツール"
	  echo -e "${gl_kjlan}105. ${color105}思源ノート${gl_kjlan}106. ${color106}Drawnix オープンソース ホワイトボード ツール"
	  echo -e "${gl_kjlan}107. ${color107}PanSou ネットワークディスク検索${gl_kjlan}108. ${color108}LangBot チャットボット"
	  echo -e "${gl_kjlan}109. ${color109}ZFileオンラインネットワークディスク${gl_kjlan}110. ${color110}カラオケのブックマーク管理"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}111. ${color111}マルチフォーマットファイル変換ツール${gl_kjlan}112. ${color112}Lucky 大規模イントラネット侵入ツール"
	  echo -e "${gl_kjlan}113. ${color113}Firefoxブラウザ${gl_kjlan}114. ${color114}OpenClaw ボット管理ツール${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}サードパーティ製アプリケーションのリスト"
  	  echo -e "${gl_kjlan}あなたのアプリをここに表示したいですか?開発者ガイドを確認してください。${gl_huang}https://dev.kejilion.sh/${gl_bai}"

	  for f in "$HOME"/apps/*.conf; do
		  [ -e "$f" ] || continue
		  local base_name=$(basename "$f" .conf)
		  # アプリの説明を取得する
		  local app_text=$(grep "app_text=" "$f" | cut -d'=' -f2 | tr -d '"' | tr -d "'")

		  # インストールステータスを確認します (appno.txt の ID と一致します)。
		  # ここでは、appno.txtに記録されているのはbase_name（つまりファイル名）であると仮定します。
		  if echo "$app_numbers" | grep -q "^$base_name$"; then
			  # インストールされている場合: showbase_name - description [インストール済み] (緑色)
			  echo -e "${gl_kjlan}$base_name${gl_bai} - ${gl_lv}$app_text[インストール済み]${gl_bai}"
		  else
			  # インストールされていない場合：通常通り表示
			  echo -e "${gl_kjlan}$base_name${gl_bai} - $app_text"
		  fi
	  done



	  echo -e "${gl_kjlan}-------------------------"
	  echo -e "${gl_kjlan}b.   ${gl_bai}すべてのアプリケーション データをバックアップする${gl_kjlan}r.   ${gl_bai}すべてのアプリデータを復元する"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice
	fi

	case $sub_choice in
	  1|bt|baota)
		local app_id="1"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="パゴダパネル"
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

		local docker_describe="ドメイン名アクセスの追加をサポートしていない Nginx リバース プロキシ ツール パネル。"
		local docker_url="公式サイト紹介：https://nginxproxymanager.com/"
		local docker_use="echo \"初期ユーザー名: admin@example.com\""
		local docker_passwd="echo \"初期パスワード:changeme\""
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


		local docker_describe="gin と Solidjs を利用した、複数のストレージ、Web ブラウジング、WebDAV をサポートするファイル一覧プログラム"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/OpenListTeam/OpenList"
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

			read -e -p "ログインユーザー名を設定します:" admin
			read -e -p "ログインユーザーのパスワードを設定します。" admin_password
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


		local docker_describe="webtop は Ubuntu ベースのコンテナです。 IP にアクセスできない場合は、アクセス用のドメイン名を追加してください。"
		local docker_url="公式Webサイトの紹介：https://docs.linuxserver.io/images/docker-webtop/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app


		  ;;
	  7|nezha)
		clear
		send_stats "ネザを構築する"

		local app_id="7"
		local docker_name="nezha-dashboard"
		local docker_port=8008
		while true; do
			check_docker_app
			check_docker_image_update $docker_name
			clear
			echo -e "ネザ監視$check_docker $update_status"
			echo "オープンソースの軽量で使いやすいサーバー監視および運用保守ツール"
			echo "公式 Web サイト構築ドキュメント: https://nezha.wiki/guide/dashboard.html"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				local docker_port=$(docker port $docker_name | awk -F'[:]' '/->/ {print $NF}' | uniq)
				check_docker_app_ip
			fi
			echo ""
			echo "------------------------"
			echo "1. 使用方法"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "選択内容を入力してください:" choice

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

		local docker_describe="qbittorrent オフライン BT 磁気ダウンロード サービス"
		local docker_url="公式サイト紹介：https://hub.docker.com/r/linuxserver/qbittorrent"
		local docker_use="sleep 3"
		local docker_passwd="docker logs qbittorrent"
		local app_size="1"
		docker_app

		  ;;

	  9|mail)
		send_stats "郵便局を建てる"
		clear
		install telnet
		local app_id="9"
		local docker_name=“mailserver”
		while true; do
			check_docker_app
			check_docker_image_update $docker_name

			clear
			echo -e "郵便サービス$check_docker $update_status"
			echo "poste.io はオープンソースのメール サーバー ソリューションです。"
			echo "ビデオ紹介: https://www.bilibili.com/video/BV1wv421C71t?t=0.1"

			echo ""
			echo "ポート検出"
			port=25
			timeout=3
			if echo "quit" | timeout $timeout telnet smtp.qq.com $port | grep 'Connected'; then
			  echo -e "${gl_lv}ポート$port現在利用可能${gl_bai}"
			else
			  echo -e "${gl_hong}ポート$port現在利用不可${gl_bai}"
			fi
			echo ""

			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				yuming=$(cat /home/docker/mail.txt)
				echo "訪問先住所:"
				echo "https://$yuming"
			fi

			echo "------------------------"
			echo "1. インストール 2. アップデート 3. アンインストール"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "選択内容を入力してください:" choice

			case $choice in
				1)
					setup_docker_dir
					check_disk_space 2 /home/docker
					read -e -p "電子メールのドメイン名を設定してください (例: mail.yuming.com)。" yuming
					mkdir -p /home/docker
					echo "$yuming" > /home/docker/mail.txt
					echo "------------------------"
					ip_address
					echo "まずこれらの DNS レコードを解析します"
					echo "A           mail            $ipv4_address"
					echo "CNAME       imap            $yuming"
					echo "CNAME       pop             $yuming"
					echo "CNAME       smtp            $yuming"
					echo "MX          @               $yuming"
					echo "TXT         @               v=spf1 mx ~all"
					echo "TXT         ?               ?"
					echo ""
					echo "------------------------"
					echo "続行するには任意のキーを押してください..."
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
					echo "poste.ioがインストールされました"
					echo "------------------------"
					echo "次のアドレスを使用して poste.io にアクセスできます。"
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
					echo "poste.ioがインストールされました"
					echo "------------------------"
					echo "次のアドレスを使用して poste.io にアクセスできます。"
					echo "https://$yuming"
					echo ""
					;;
				3)
					docker rm -f mailserver
					docker rmi -f analogic/poste.io
					rm /home/docker/mail.txt
					rm -rf /home/docker/mail

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "アプリがアンインストールされました"
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
		local app_name="Rocket.Chat チャット システム"
		local app_text="Rocket.Chat は、リアルタイム チャット、音声およびビデオ通話、ファイル共有、その他の機能をサポートするオープンソースのチーム コミュニケーション プラットフォームです。"
		local app_url="公式紹介：https://www.rocket.chat/"
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
			echo "インストール完了"
			check_docker_app_ip
		}

		docker_app_update() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat:latest
			docker run --name rocketchat --restart=always -p ${docker_port}:3000 --link db --env ROOT_URL=http://localhost --env MONGO_OPLOG_URL=mongodb://db:27017/rs5 -d rocket.chat
			clear
			ip_address
			echo "rocket.chat がインストールされました"
			check_docker_app_ip
		}

		docker_app_uninstall() {
			docker rm -f rocketchat
			docker rmi -f rocket.chat
			docker rm -f db
			docker rmi -f mongo:latest
			rm -rf /home/docker/mongo
			echo "アプリがアンインストールされました"
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

		local docker_describe="ZenTao はユニバーサルなプロジェクト管理ソフトウェアです"
		local docker_url="公式サイト紹介：https://www.zentao.net/"
		local docker_use="echo \"初期ユーザー名: admin\""
		local docker_passwd="echo 「初期パスワード: 123456」"
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

		local docker_describe="Qinglong Panel はスケジュールされたタスク管理プラットフォームです"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/whyour/qinglong"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;
	  13|cloudreve)

		local app_id="13"
		local app_name="クラウドリーブネットワークディスク"
		local app_text="Cloudreve は、複数のクラウド ストレージをサポートするネットワーク ディスク システムです。"
		local app_url="ビデオ紹介: https://www.bilibili.com/video/BV13F4m1c7h7?t=0.1"
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
			echo "インストール完了"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			cd /home/docker/cloud/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/cloud/ && docker compose down --rmi all
			rm -rf /home/docker/cloud
			echo "アプリがアンインストールされました"
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

		local docker_describe="シンプルドローイングベッドはシンプルなドローイングベッドプログラムです"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/icret/EasyImages2.0"
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


		local docker_describe="emby は、サーバー上でビデオとオーディオを整理し、クライアント デバイスにオーディオとビデオをストリーミングするために使用できるマスター/スレーブ アーキテクチャのメディア サーバー ソフトウェアです。"
		local docker_url="公式サイト紹介：https://emby.media/"
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

		local docker_describe="Speedtest 速度測定パネルは、複数のテスト機能を備えた VPS ネットワーク速度テスト ツールで、VPS のインバウンドおよびアウトバウンドのトラフィックをリアルタイムで監視することもできます。"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/wikihost-opensource/als"
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


		local docker_describe="AdGuardHome は、将来的には単なる DNS サーバー以上のネットワーク全体の広告ブロックおよび追跡防止ソフトウェアです。"
		local docker_url="公式サイト紹介：https://hub.docker.com/r/adguard/adguardhome"
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

		local docker_describe="Onlyoffice はオープンソースのオンライン オフィス ツールで、非常に強力です。"
		local docker_url="公式サイト紹介：https://www.onlyoffice.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app

		  ;;

	  19|safeline)
		send_stats "雷のプールを作る"

		local app_id="19"
		local docker_name=safeline-mgt
		local docker_port=9443
		while true; do
			check_docker_app
			clear
			echo -e "サンダープールサービス$check_docker"
			echo "Leichi は、Changting Technology によって開発された WAF サイト ファイアウォール プログラム パネルで、自動防御のためにサイトを反転できます。"
			echo "ビデオ紹介: https://www.bilibili.com/video/BV1mZ421T74c?t=0.1"
			if docker ps -a --format '{{.Names}}' 2>/dev/null | grep -q "$docker_name"; then
				check_docker_app_ip
			fi
			echo ""

			echo "------------------------"
			echo "1. インストール 2. アップデート 3. パスワードのリセット 4. アンインストール"
			echo "------------------------"
			echo "0. 前のメニューに戻る"
			echo "------------------------"
			read -e -p "選択内容を入力してください:" choice

			case $choice in
				1)
					install_docker
					check_disk_space 5
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/setup.sh)"

					add_app_id
					clear
					echo "Leichi WAFパネルを導入しました"
					check_docker_app_ip
					docker exec safeline-mgt resetadmin

					;;

				2)
					bash -c "$(curl -fsSLk https://waf-ce.chaitin.cn/release/latest/upgrade.sh)"
					docker rmi $(docker images | grep "safeline" | grep "none" | awk '{print $3}')
					echo ""

					add_app_id
					clear
					echo "Leichi WAF パネルが更新されました"
					check_docker_app_ip
					;;
				3)
					docker exec safeline-mgt resetadmin
					;;
				4)
					cd /data/safeline
					docker compose down --rmi all

					sed -i "/\b${app_id}\b/d" /home/docker/appno.txt
					echo "デフォルトのインストール ディレクトリにいる場合、プロジェクトはすでにアンインストールされています。インストール ディレクトリをカスタマイズする場合は、インストール ディレクトリに移動して自分で実行する必要があります。"
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


		local docker_describe="portainer は軽量の Docker コンテナ管理パネルです"
		local docker_url="公式サイト紹介：https://www.porttainer.io/"
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


		local docker_describe="VScode は強力なオンライン コード作成ツールです"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/coder/code-server"
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


		local docker_describe="Uptime Kuma 使いやすいセルフホスト型監視ツール"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/louislam/uptime-kuma"
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

		local docker_describe="Memos は軽量の自己ホスト型メモ センターです"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/usememos/memos"
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

			read -e -p "ログインユーザー名を設定します:" admin
			read -e -p "ログインユーザーのパスワードを設定します。" admin_password
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


		local docker_describe="Webtop は、Alpine コンテナの中国語版に基づいています。 IP にアクセスできない場合は、アクセス用のドメイン名を追加してください。"
		local docker_url="公式Webサイトの紹介：https://docs.linuxserver.io/images/docker-webtop/"
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

		local docker_describe="400,000 を超える導入実績を持つ Nextcloud は、ダウンロードできる最も人気のあるローカル コンテンツ コラボレーション プラットフォームです。"
		local docker_url="公式サイト紹介：https://nextcloud.com/"
		local docker_use="echo \"アカウント: nextcloud パスワード:$rootpasswd\""
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

		local docker_describe="QD-Today は、HTTP リクエストのスケジュールされたタスク自動実行フレームワークです。"
		local docker_url="公式サイト紹介：https://qd-today.github.io/qd/zh_CN/"
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

		local docker_describe="dockge は、視覚的な docker-compose コンテナー管理パネルです。"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/louislam/dockge"
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

		local docker_describe="librespeed は、JavaScript で実装され、すぐに使用できる軽量の速度テスト ツールです。"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/librespeed/speedtest"
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

		local docker_describe="searxng は非公開の検索エンジン サイトです。"
		local docker_url="公式サイト紹介：https://hub.docker.com/r/alandoyle/searxng"
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


		local docker_describe="Photoprism は非常に強力なプライベート フォト アルバム システムです"
		local docker_url="公式サイト紹介：https://www.photoprism.app/"
		local docker_use="echo \"アカウント: admin パスワード:$rootpasswd\""
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

		local docker_describe="これは、Docker を使用してローカルでホストされる強力な Web ベースの PDF 操作ツールで、分割マージ、変換、再編成、画像の追加、回転、圧縮など、PDF ファイルに対してさまざまな操作を実行できます。"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/Stirling-Tools/Stirling-PDF"
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


		local docker_describe="これは強力なグラフ作成ソフトウェアです。マインド マップ、トポロジ図、フローチャートを描画できます。"
		local docker_url="公式サイト紹介：https://www.drawio.com/"
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

		local docker_describe="Sun-Panel サーバー、NAS ナビゲーション パネル、ホームページ、ブラウザー ホームページ"
		local docker_url="公式サイト紹介：https://doc.sun-panel.top/zh_cn/"
		local docker_use="echo 「アカウント: admin@sun.cc パスワード: 12345678」"
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

		local docker_describe="Pingvin Share は自己構築可能なファイル共有プラットフォームであり、WeTransfer の代替品です"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/stonith404/pingvin-share"
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


		local docker_describe="ミニマリストの瞬間、模倣性の高いWeChatの瞬間、あなたの素晴らしい人生を記録してください"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/kingwrcy/moments?tab=readme-ov-file"
		local docker_use="echo 「アカウント: admin パスワード: a123456」"
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

		local docker_describe="LobeChat は、市場で主流の AI 大型モデル、ChatGPT/Claude/Gemini/Groq/Ollama を集約しています。"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/lobehub/lobe-chat"
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


		local docker_describe="独自の IP 情報と接続性を表示し、Web パネルを使用して表示できる多機能 IP ツールボックスです。"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/jason5ng32/MyIP/blob/main/README_ZH.md"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  38|xiaoya)
		send_stats "シャオヤファミリーバケツ"
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

		local docker_describe="Bililive-go は、複数のライブ ブロードキャスト プラットフォームをサポートするライブ ブロードキャスト録画ツールです"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/hr3lxphr6j/bililive-go"
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

		local docker_describe="シンプルなオンライン SSH 接続ツールと SFTP ツール"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/Jrohy/webssh"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  41|haozi|acepanel)

		local app_id="41"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="AcePanelオリジナルマウスパネル"
		local panelurl="正式な住所:${gh_proxy}github.com/acepanel/panel"

		panel_app_install() {
			cd ~
			bash <(curl -sSLm 10 https://dl.acepanel.net/helper.sh)
		}

		panel_app_manage() {
			acepanel help
		}

		panel_app_uninstall() {
			cd ~
			bash <(curl -sSLm 10 https://dl.acepanel.net/helper.sh)

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

		local docker_describe="nexterm は、強力なオンライン SSH/VNC/RDP 接続ツールです。"
		local docker_url="公式サイト紹介：${gh_proxy}github.com/gnmyt/Nexterm"
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


		local docker_describe="Rustdesk のオープンソース リモート デスクトップ (サーバー) は、自社の Sunflower プライベート サーバーに似ています。"
		local docker_url="公式サイト紹介：https://rustdesk.com/zh-cn/"
		local docker_use="docker logs hbbs"
		local docker_passwd="echo \"リモート デスクトップ クライアントで使用される IP とキーを記録します。オプション 44 に進んでリレーをインストールしてください!\""
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

		local docker_describe="Rustdesk のオープンソース リモート デスクトップ (リレー) は、独自の Sunflower プライベート サーバーに似ています。"
		local docker_url="公式サイト紹介：https://rustdesk.com/zh-cn/"
		local docker_use="echo \"公式 Web サイトにアクセスして、リモート デスクトップ クライアントをダウンロードします: https://rustdesk.com/zh-cn/\""
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

		local docker_describe="Docker Registry は、Docker イメージを保存および配布するためのサービスです。"
		local docker_url="公式サイト紹介：https://hub.docker.com/_/registry"
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

		local docker_describe="Go を使用して実装された GHProxy は、一部の領域で Github リポジトリのプルを高速化するために使用されます。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/WJQSERVER-STUDIO/ghproxy"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;

	  47|prometheus|grafana)

		local app_id="47"
		local app_name="プロメテウスの監視"
		local app_text="Prometheus+Grafana エンタープライズレベルの監視システム"
		local app_url="公式サイト紹介：https://prometheus.io"
		local docker_name="grafana"
		local docker_port="8047"
		local app_size="2"

		docker_app_install() {
			prometheus_install
			clear
			ip_address
			echo "インストール完了"
			check_docker_app_ip
			echo "初期のユーザー名とパスワードは次のとおりです: admin"
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
			echo "アプリがアンインストールされました"
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

		local docker_describe="これは Prometheus ホスト データ収集コンポーネントです。監視対象ホストにデプロイしてください。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/prometheus/node_exporter"
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

		local docker_describe="これは Prometheus コンテナーのデータ収集コンポーネントです。監視対象ホストにデプロイしてください。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/google/cadvisor"
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

		local docker_describe="これは、Web サイトの変更の検出、補充の監視、通知を行うための小さなツールです。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/dgtlmoon/changedetection.io"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app
		  ;;


	  51|pve)
		clear
		send_stats "PVE オープンひよこ"
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

		local docker_describe="Docker ビジュアル パネル システムは、完全な Docker 管理機能を提供します。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/donknap/dpanel"
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

		local docker_describe="OpenWebUI は、新しい llama3 ラージ言語モデルに接続されているラージ言語モデル Web ページ フレームワークです。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run llama3.2:1b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;

	  54|amh)

		local app_id="54"
		local lujing="[ -d "/www/server/panel" ]"
		local panelname="AMHパネル"
		local panelurl="公式アドレス：https://amh.sh/index.htm?amh"

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

		local docker_describe="OpenWebUI は、新しい DeepSeek R1 大規模言語モデルに接続されている大規模言語モデル Web ページ フレームワークです。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/open-webui/open-webui"
		local docker_use="docker exec ollama ollama run deepseek-r1:1.5b"
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;


	  58|dify)
		local app_id="58"
		local app_name="Difyナレッジベース"
		local app_text="これは、オープンソースの大規模言語モデル (LLM) アプリケーション開発プラットフォームです。 AI生成用の自己ホスト型トレーニングデータ"
		local app_url="公式ウェブサイト：https://docs.dify.ai/zh-hans"
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
			echo "インストール完了"
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
			echo "アプリがアンインストールされました"
		}

		docker_app_plus

		  ;;

	  59|new-api)
		local app_id="59"
		local app_name="NewAPI"
		local app_text="新世代の大型モデルゲートウェイとAI資産管理システム"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/Calcium-Ion/new-api"
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
			echo "インストール完了"
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
			echo "インストール完了"
			check_docker_app_ip

		}

		docker_app_uninstall() {
			cd  /home/docker/new-api/ && docker compose down --rmi all
			rm -rf /home/docker/new-api
			echo "アプリがアンインストールされました"
		}

		docker_app_plus

		  ;;


	  60|jms)

		local app_id="60"
		local app_name="JumpServer オープンソース要塞マシン"
		local app_text="これは、オープンソースの特権アクセス管理 (PAM) ツールです。このプログラムはポート 80 を占有しているため、アクセス用のドメイン名の追加はサポートされていません。"
		local app_url="公式紹介:${gh_https_url}github.com/jumpserver/jumpserver"
		local docker_name="jms_web"
		local docker_port="80"
		local app_size="2"

		docker_app_install() {
			curl -sSL ${gh_proxy}github.com/jumpserver/jumpserver/releases/latest/download/quick_start.sh | bash
			clear
			echo "インストール完了"
			check_docker_app_ip
			echo "初期ユーザー名: admin"
			echo "初期パスワード：ChangeMe"
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
			echo "アプリがアンインストールされました"
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

		local docker_describe="無料のオープンソース機械翻訳 API は完全に自己ホストされており、その翻訳エンジンはオープンソースの Argos Translate ライブラリを利用しています。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/LibreTranslate/LibreTranslate"
		local docker_use=""
		local docker_passwd=""
		local app_size="5"
		docker_app
		  ;;



	  62|ragflow)
		local app_id="62"
		local app_name="RAGFlow ナレッジベース"
		local app_text="ドキュメントの深い理解に基づくオープンソース RAG (Retrieval Augmented Generation) エンジン"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/infiniflow/ragflow"
		local docker_name="ragflow-server"
		local docker_port="8062"
		local app_size="8"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/infiniflow/ragflow.git && cd ragflow/docker
			sed -i "s/- 80:80/- ${docker_port}:80/; /- 443:443/d" docker-compose.yml
			docker compose up -d
			clear
			echo "インストール完了"
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
			echo "アプリがアンインストールされました"
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

		local docker_describe="OpenWebUI は大規模な言語モデルの Web ページ フレームワークであり、公式の簡易バージョンではすべての主要モデルへの API アクセスがサポートされています。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/open-webui/open-webui"
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

		local docker_describe="開発者と IT ワーカーにとって非常に便利なツール"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/CorentinTh/it-tools"
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

		local docker_describe="強力な自動ワークフロー プラットフォームです"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/n8n-io/n8n"
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

		local docker_describe="パブリック IP (IPv4/IPv6) を主要な DNS サービス プロバイダーにリアルタイムで自動的に更新し、動的なドメイン名解決を実現します。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/jeessy2/ddns-go"
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

		local docker_describe="オープンソースの無料 SSL 証明書自動化管理プラットフォーム"
		local docker_url="公式サイト紹介：https://allinssl.com"
		local docker_use="echo \"セキュリティの入り口: /allinssl\""
		local docker_passwd="echo \"ユーザー名: allinssl パスワード: allinssldocker\""
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

		local docker_describe="オープンソースでいつでもどこでも無料の SFTP FTP WebDAV ファイル転送ツール"
		local docker_url="公式サイト紹介：https://sftpgo.com/"
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

		local docker_describe="オープンソース AI チャットボット フレームワーク。WeChat、QQ、TG による大規模 AI モデルへのアクセスをサポート"
		local docker_url="公式サイト紹介：https://astrbot.app/"
		local docker_use="echo \"ユーザー名: astrbot パスワード: astrbot\""
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

		local docker_describe="軽量で高性能な音楽ストリーミングサーバーです"
		local docker_url="公式サイト紹介：https://www.navidrome.org/"
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

		local docker_describe="データを管理できるパスワード マネージャー"
		local docker_url="公式サイト紹介：https://bitwarden.com/"
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

			read -e -p "LibreTV のログイン パスワードを設定します。" app_passwd

			docker run -d \
			  --name libretv \
			  --restart=always \
			  -p ${docker_port}:8080 \
			  -e PASSWORD=${app_passwd} \
			  bestzwei/libretv:latest

		}

		local docker_describe="無料のオンラインビデオ検索および視聴プラットフォーム"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/LibreSpark/LibreTV"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  74|moontv)

		local app_id="74"

		local app_name="MoonTV プライベート映画とテレビ"
		local app_text="無料のオンラインビデオ検索および視聴プラットフォーム"
		local app_url="ビデオの紹介:${gh_https_url}github.com/MoonTechLab/LunaTV"
		local docker_name="moontv-core"
		local docker_port="8074"
		local app_size="2"

		docker_app_install() {
			read -e -p "ログインユーザー名を設定します:" admin
			read -e -p "ログインユーザーのパスワードを設定します。" admin_password
			read -e -p "認証コードを入力してください:" shouquanma


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
			echo "インストール完了"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			cd /home/docker/moontv/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/moontv/ && docker compose down --rmi all
			rm -rf /home/docker/moontv
			echo "アプリがアンインストールされました"
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

		local docker_describe="音楽をより適切に管理できるように設計された音楽ウィザード。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/foamzou/melody"
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

		local docker_describe="中華DOSゲームまとめサイトです"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/rwv/chinese-dos-games"
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

			read -e -p "ログインユーザー名を設定します:" app_use
			read -e -p "ログインパスワードを設定します:" app_passwd

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

		local docker_describe="Xunlei、オフライン高速 BT 磁気ダウンロード ツール"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/cnk3x/xunlei"
		local docker_use="echo \"携帯電話で Xunlei にログインし、招待コードを入力してください。招待コード: Xunlei Niutong\""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  78|PandaWiki)

		local app_id="78"
		local app_name="PandaWiki"
		local app_text="PandaWiki は、AI 大型モデルによって駆動されるオープンソースのインテリジェントな文書管理システムです。ポートの展開をカスタマイズしないことを強くお勧めします。"
		local app_url="公式紹介:${gh_https_url}github.com/chaitin/PandaWiki"
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

		local docker_describe="Beszel は軽量で使いやすいサーバー監視です"
		local docker_url="公式サイト紹介：https://beszel.dev/zh/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  80|linkwarden)

		  local app_id="80"
		  local app_name="リンクワーデンのブックマーク管理"
		  local app_text="タグ付け、検索、チーム コラボレーションをサポートする、オープン ソースの自己ホスト型ブックマーク管理プラットフォーム。"
		  local app_url="公式サイト：https://linkwarden.app/"
		  local docker_name="linkwarden-linkwarden-1"
		  local docker_port="8080"
		  local app_size="3"

		  docker_app_install() {
			  install git openssl
			  mkdir -p /home/docker/linkwarden && cd /home/docker/linkwarden

			  # 公式の docker-compose および env ファイルをダウンロードする
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env"

			  # ランダムなキーとパスワードを生成する
			  local ADMIN_EMAIL="admin@example.com"
			  local ADMIN_PASSWORD=$(openssl rand -hex 8)

			  sed -i "s|^NEXTAUTH_URL=.*|NEXTAUTH_URL=http://localhost:${docker_port}/api/v1/auth|g" .env
			  sed -i "s|^NEXTAUTH_SECRET=.*|NEXTAUTH_SECRET=$(openssl rand -hex 32)|g" .env
			  sed -i "s|^POSTGRES_PASSWORD=.*|POSTGRES_PASSWORD=$(openssl rand -hex 16)|g" .env
			  sed -i "s|^MEILI_MASTER_KEY=.*|MEILI_MASTER_KEY=$(openssl rand -hex 32)|g" .env

			  # 管理者アカウント情報を追加する
			  echo "ADMIN_EMAIL=${ADMIN_EMAIL}" >> .env
			  echo "ADMIN_PASSWORD=${ADMIN_PASSWORD}" >> .env

			  sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/linkwarden/docker-compose.yml

			  # コンテナの起動
			  docker compose up -d

			  clear
			  echo "インストール完了"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
			  cd /home/docker/linkwarden && docker compose down --rmi all
			  curl -O ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/docker-compose.yml
			  curl -L ${gh_proxy}raw.githubusercontent.com/linkwarden/linkwarden/refs/heads/main/.env.sample -o ".env.new"

			  # 元の変数を保持する
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
			  echo "アプリがアンインストールされました"
		  }

		  docker_app_plus

		  ;;



	  81|jitsi)
		  local app_id="81"
		  local app_name="JitsiMeet ビデオ会議"
		  local app_text="複数人でのオンライン会議、画面共有、暗号化通信をサポートするオープンソースの安全なビデオ会議ソリューション。"
		  local app_url="公式サイト：https://jitsi.org/"
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
			  echo "アプリがアンインストールされました"
		  }

		  docker_app_plus

		  ;;



	  82|gpt-load)

		local app_id="82"
		local docker_name="gpt-load"
		local docker_img="tbphp/gpt-load:latest"
		local docker_port=8082

		docker_rum() {

			read -e -p "設定${docker_name}ログイン キー (sk- で始まる文字と数字の組み合わせ) 例: sk-159kejilionyyds163:" app_passwd

			mkdir -p /home/docker/gpt-load && \
			docker run -d --name gpt-load \
				-p ${docker_port}:3001 \
				-e AUTH_KEY=${app_passwd} \
				-v "/home/docker/gpt-load/data":/app/data \
				tbphp/gpt-load:latest

		}

		local docker_describe="高性能AIインターフェース透過プロキシサービス"
		local docker_url="公式サイト紹介：https://www.gpt-load.com/"
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

		local docker_describe="軽量のセルフホスト型サーバー監視ツール"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/komari-monitor/komari/tree/main"
		local docker_use="echo \"デフォルトのアカウント: admin デフォルトのパスワード: 1212156\""
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

		local docker_describe="財務管理用のオープンソースの個人サブスクリプション トラッカー"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/ellite/Wallos"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  85|immich)

		  local app_id="85"
		  local app_name="イミッチピクチャービデオマネージャー"
		  local app_text="高性能の自己ホスト型写真およびビデオ管理ソリューション。"
		  local app_url="公式サイト紹介：${gh_https_url}github.com/immich-app/immich"
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
			  echo "インストール完了"
		  	  check_docker_app_ip

		  }

		  docker_app_update() {
				cd /home/docker/${docker_name} && docker compose down --rmi all
				docker_app_install
		  }

		  docker_app_uninstall() {
			  cd /home/docker/${docker_name} && docker compose down --rmi all
			  rm -rf /home/docker/${docker_name}
			  echo "アプリがアンインストールされました"
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

		local docker_describe="オープンソースのメディアサーバーソフトウェアです"
		local docker_url="公式サイト紹介：https://jellyfin.org/"
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

		local docker_describe="リモートで映画や生放送を一緒に見るプログラム。同時視聴、ライブブロードキャスト、チャットなどの機能を提供します"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/synctv-org/synctv"
		local docker_use="echo \"初期アカウントとパスワード: root。ログイン後、時間内にログイン パスワードを変更してください\""
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

		local docker_describe="オープンソース、無料の自社構築ライブ ブロードキャスト プラットフォーム"
		local docker_url="公式サイト紹介：https://owncast.online"
		local docker_use="echo \"管理者ページにアクセスするには、アクセス アドレスの後に /admin を続けます\""
		local docker_passwd="echo \"初期アカウント: admin 初期パスワード: abc123 ログイン後、時間内にログイン パスワードを変更してください\""
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

		local docker_describe="匿名のパスワードでテキストやファイルを共有し、速達のようにファイルを受け取ります"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/vastsa/FileCodeBox"
		local docker_use="echo \"管理者ページにアクセスするには、アクセス アドレスの後に /#/admin を続けます\""
		local docker_passwd="echo \"管理者パスワード: FileCodeBox2023\""
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

			echo "初期ユーザーまたは管理者を作成します。以下のユーザー名とパスワード、および管理者であるかどうかを設定してください。"
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

		local docker_describe="Matrix は分散型チャット プロトコルです"
		local docker_url="公式サイト紹介：https://matrix.org/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;



	  91|gitea)

		local app_id="91"

		local app_name="gitea プライベート コード リポジトリ"
		local app_text="GitHub に近いエクスペリエンスを提供する、無料の新世代コード ホスティング プラットフォーム。"
		local app_url="ビデオの紹介:${gh_https_url}github.com/go-gitea/gitea"
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
			echo "インストール完了"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			cd /home/docker/gitea/ && docker compose up -d
		}


		docker_app_uninstall() {
			cd /home/docker/gitea/ && docker compose down --rmi all
			rm -rf /home/docker/gitea
			echo "アプリがアンインストールされました"
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

		local docker_describe="Webベースのファイルマネージャーです"
		local docker_url="公式サイト紹介：https://filebrowser.org/"
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

		local docker_describe="シンプルな静的ファイル サーバー、アップロードとダウンロードをサポート"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/sigoden/dufs"
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

			read -e -p "ログインユーザー名を設定します:" app_use
			read -e -p "ログインパスワードを設定します:" app_passwd

			docker run -d \
			  --name ${docker_name} \
			  --restart=always \
			  -v /home/docker/${docker_name}/downloads:/app/Downloads \
			  -v /home/docker/${docker_name}/storage:/app/storage \
			  -p ${docker_port}:9999 \
			  ${docker_img} -u ${app_use} -p ${app_passwd}

		}

		local docker_describe="複数のプロトコルをサポートする分散型高速ダウンロード ツール"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/GopeedLab/gopeed"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;



	  95|paperless)

		local app_id="95"

		local app_name="ペーパーレス文書管理プラットフォーム"
		local app_text="オープンソースの電子文書管理システムであり、その主な目的は紙文書をデジタル化して管理することです。"
		local app_url="ビデオ紹介: https://docs.paperless-ngx.com/"
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
			echo "インストール完了"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/paperless/ && docker compose down --rmi all
			rm -rf /home/docker/paperless
			echo "アプリがアンインストールされました"
		}

		docker_app_plus

		  ;;



	  96|2fauth)

		local app_id="96"

		local app_name="2FAuth セルフホスト型 2 段階認証システム"
		local app_text="セルフホスト型の 2 要素認証 (2FA) アカウント管理および検証コード生成ツール。"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/Bubka/2FAuth"
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
			echo "インストール完了"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/2fauth/ && docker compose down --rmi all
			rm -rf /home/docker/2fauth
			echo "アプリがアンインストールされました"
		}

		docker_app_plus

		  ;;



	97|wgs)

		local app_id="97"
		local docker_name="wireguard"
		local docker_img="lscr.io/linuxserver/wireguard:latest"
		local docker_port=8097

		docker_rum() {

		read -e -p  "ネットワーク内のクライアントの数を入力してください (デフォルトは 5):" COUNT
		COUNT=${COUNT:-5}
		read -e -p  "WireGuard ネットワーク セグメントを入力してください (デフォルトは 10.13.13.0)。" NETWORK
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
		echo -e "${gl_huang}すべてのクライアント QR コード構成:${gl_bai}"
		docker exec wireguard bash -c 'for i in $(ls /config | grep peer_ | sed "s/peer_//"); do echo "--- $i ---"; /app/show-peer $i; done'
		sleep 2
		echo
		echo -e "${gl_huang}すべてのクライアント構成コード:${gl_bai}"
		docker exec wireguard sh -c 'for d in /config/peer_*; do echo "# $(basename $d) "; cat $d/*.conf; echo; done'
		sleep 2
		echo -e "${gl_lv}${COUNT}各クライアントのすべての出力を構成します。利用方法は以下の通りです。${gl_bai}"
		echo -e "${gl_lv}1. 携帯電話に wg APP をダウンロードし、上の QR コードをスキャンして、すぐにインターネットに接続します。${gl_bai}"
		echo -e "${gl_lv}2. Windows 用クライアントをダウンロードし、ネットワークに接続するための構成コードをコピーします。${gl_bai}"
		echo -e "${gl_lv}3. スクリプトを使用して Linux に WG クライアントを展開し、構成コードをコピーしてネットワークに接続します。${gl_bai}"
		echo -e "${gl_lv}公式クライアントのダウンロード方法：https://www.wireguard.com/install/${gl_bai}"
		break_end

		}

		local docker_describe="最新の高性能仮想プライベート ネットワーク ツール"
		local docker_url="公式サイト紹介：https://www.wireguard.com/"
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

			# ディレクトリが存在しない場合は作成する
			mkdir -p "$(dirname "$CONFIG_FILE")"

			echo "クライアント設定を貼り付け、Enter キーを 2 回押して保存してください。"

			# 変数を初期化する
			input=""
			empty_line_count=0

			# ユーザー入力を 1 行ずつ読み取ります
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

			# 設定ファイルの書き込み
			echo "$input" > "$CONFIG_FILE"

			echo "クライアント設定の保存場所$CONFIG_FILE"

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

		local docker_describe="最新の高性能仮想プライベート ネットワーク ツール"
		local docker_url="公式サイト紹介：https://www.wireguard.com/"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  99|dsm)

		local app_id="99"

		local app_name="DSM Synology 仮想マシン"
		local app_text="Dockerコンテナ内の仮想DSM"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/vdsm/virtual-dsm"
		local docker_name="dsm"
		local docker_port="8099"
		local app_size="16"

		docker_app_install() {

			read -e -p "CPU コアの数を設定します (デフォルトは 2)。" CPU_CORES
			local CPU_CORES=${CPU_CORES:-2}

			read -e -p "メモリ サイズを設定します (デフォルトは 4G):" RAM_SIZE
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
			echo "インストール完了"
			check_docker_app_ip
		}


		docker_app_update() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			docker_app_install
		}


		docker_app_uninstall() {
			cd /home/docker/dsm/ && docker compose down --rmi all
			rm -rf /home/docker/dsm
			echo "アプリがアンインストールされました"
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

		local docker_describe="オープンソースのピアツーピア ファイル同期ツール。Dropbox や Resilio Sync に似ていますが、完全に分散化されています。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/syncthing/syncthing"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		;;


	  101|moneyprinterturbo)
		local app_id="101"
		local app_name="AI動画生成ツール"
		local app_text="MoneyPrinterTurbo は、AI ラージモデルを使用して高解像度のショートビデオを合成するツールです"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/harry0703/MoneyPrinterTurbo"
		local docker_name="moneyprinterturbo"
		local docker_port="8101"
		local app_size="3"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/harry0703/MoneyPrinterTurbo.git && cd MoneyPrinterTurbo/
			sed -i "s/8501:8501/${docker_port}:8501/g" /home/docker/MoneyPrinterTurbo/docker-compose.yml

			docker compose up -d
			clear
			echo "インストール完了"
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
			echo "アプリがアンインストールされました"
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

		local docker_describe="独自導入をサポートするパーソナルクラウドソーシャルメディアチャットサービスです。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/Privoce/vocechat-web"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  103|umami)
		local app_id="103"
		local app_name="Umami ウェブサイト統計ツール"
		local app_text="Google Analytics に似た、オープンソースの軽量でプライバシーに配慮した Web サイト分析ツール。"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/umami-software/umami"
		local docker_name="umami-umami-1"
		local docker_port="8103"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/umami-software/umami.git && cd umami
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/umami/docker-compose.yml

			docker compose up -d
			clear
			echo "インストール完了"
			check_docker_app_ip
			echo "初期ユーザー名: admin"
			echo "初期パスワード：umami"
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
			echo "アプリがアンインストールされました"
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

			read -e -p "ログインパスワードを設定します:" app_passwd

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

		local docker_describe="Siyuan Notes はプライバシーを最優先したナレッジ管理システムです"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/siyuan-note/siyuan"
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

		local docker_describe="これは、マインド マップ、フローチャートなどを統合する強力なオープンソース ホワイトボード ツールです。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/plait-board/drawnix"
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

		local docker_describe="PanSou は、高パフォーマンスのネットワーク ディスク リソース検索 API サービスです。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/fish2018/pansou"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;




	  108|langbot)
		local app_id="108"
		local app_name="LangBot チャットボット"
		local app_text="これは、オープンソースの大規模言語モデルのネイティブ インスタント メッセージング ロボット開発プラットフォームです。"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/langbot-app/LangBot"
		local docker_name="langbot_plugin_runtime"
		local docker_port="8108"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/langbot-app/LangBot && cd LangBot/docker
			sed -i "s/5300:5300/${docker_port}:5300/g" /home/docker/LangBot/docker/docker-compose.yaml

			docker compose up -d
			clear
			echo "インストール完了"
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
			echo "アプリがアンインストールされました"
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

		local docker_describe="これは、個人または小規模チームに適したオンライン ネットワーク ディスク プログラムです。"
		local docker_url="公式サイト紹介：${gh_https_url}github.com/zfile-dev/zfile"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;


	  110|karakeep)
		local app_id="110"
		local app_name="karakeepのブックマーク管理"
		local app_text="は、データ蓄積者向けに設計された人工知能機能を備えた自己ホスト型ブックマーク アプリです。"
		local app_url="公式ウェブサイト:${gh_https_url}github.com/karakeep-app/karakeep"
		local docker_name="docker-web-1"
		local docker_port="8110"
		local app_size="1"

		docker_app_install() {
			install git
			mkdir -p  /home/docker/ && cd /home/docker/ && git clone ${gh_proxy}github.com/karakeep-app/karakeep.git && cd karakeep/docker && cp .env.sample .env
			sed -i "s/3000:3000/${docker_port}:3000/g" /home/docker/karakeep/docker/docker-compose.yml

			docker compose up -d
			clear
			echo "インストール完了"
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
			echo "アプリがアンインストールされました"
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

		local docker_describe="これは強力なマルチフォーマット ファイル変換ツールです (ドキュメント、画像、オーディオ、ビデオなどをサポート)。ドメイン名アクセスを追加することを強くお勧めします。"
		local docker_url="プロジェクトアドレス:${gh_https_url}github.com/c4illin/ConvertX"
		local docker_use=""
		local docker_passwd=""
		local app_size="2"
		docker_app

		  ;;


	  112|lucky)

		local app_id="112"
		local docker_name="lucky"
		local docker_img="gdy666/lucky:v2"
		# Lucky はホスト ネットワーク モードを使用するため、ここでのポートは記録と説明の参照のみを目的としており、実際にはアプリケーション自体によって制御されます (デフォルトは 16601)。
		local docker_port=8112

		docker_rum() {

			docker run -d --name=${docker_name} --restart=always \
				--network host \
				-v /home/docker/lucky/conf:/app/conf \
				-v /var/run/docker.sock:/var/run/docker.sock \
				${docker_img}

			echo "Lucky が初期化されるのを待っています..."
			sleep 10
			docker exec lucky /app/lucky -rSetHttpAdminPort ${docker_port}

		}

		local docker_describe="Lucky は、DDNS、リバース プロキシ、WOL、その他の機能をサポートする大規模なイントラネット ペネトレーションおよびポート フォワーディング管理ツールです。"
		local docker_url="プロジェクトアドレス:${gh_https_url}github.com/gdy666/lucky"
		local docker_use="echo \"デフォルトのアカウントパスワード: 666\""
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

			read -e -p "ログインパスワードを設定します:" admin_password

			docker run -d --name=${docker_name} --restart=always \
				-p ${docker_port}:5800 \
				-v /home/docker/firefox:/config:rw \
				-e ENABLE_CJK_FONT=1 \
				-e WEB_AUDIO=1 \
				-e VNC_PASSWORD="${admin_password}" \
				${docker_img}
		}

		local docker_describe="これは、Web ページを介したデスクトップ ブラウザ インターフェイスへの直接アクセスをサポートする、Docker で実行される Firefox ブラウザです。"
		local docker_url="プロジェクトアドレス:${gh_https_url}github.com/jlesage/docker-firefox"
		local docker_use=""
		local docker_passwd=""
		local app_size="1"
		docker_app

		  ;;

	  114|Moltbot|ClawdBot|moltbot|clawdbot|openclaw|OpenClaw)
	  	  moltbot_menu
		  ;;


	  b)
	  	clear
	  	send_stats "すべてのアプリケーションのバックアップ"

	  	local backup_filename="app_$(date +"%Y%m%d%H%M%S").tar.gz"
	  	echo -e "${gl_kjlan}バックアップ中$backup_filename ...${gl_bai}"
	  	cd / && tar czvf "$backup_filename" home

	  	while true; do
			clear
			echo "バックアップファイルが作成されました: /$backup_filename"
			read -e -p "バックアップ データをリモート サーバーに転送しますか? (はい/いいえ):" choice
			case "$choice" in
			  [Yy])
				kj_ssh_read_host_port "リモートサーバーのIPを入力してください:" "ターゲット サーバーの SSH ポート [デフォルト 22]:" "22"
				local remote_ip="$KJ_SSH_HOST"
				local TARGET_PORT="$KJ_SSH_PORT"
				local latest_tar=$(ls -t /app*.tar.gz | head -1)
				if [ -n "$latest_tar" ]; then
				  ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				  sleep 2  # 添加等待时间
				  scp -P "$TARGET_PORT" -o StrictHostKeyChecking=no "$latest_tar" "root@$remote_ip:/"
				  echo "ファイルはリモート サーバー/ルート ディレクトリに転送されます。"
				else
				  echo "転送するファイルが見つかりませんでした。"
				fi
				break
				;;
			  *)
				echo "注: 現在のバックアップには Docker プロジェクトのみが含まれており、Pagoda や 1panel などの Web サイト構築パネルのデータ バックアップは含まれていません。"
				break
				;;
			esac
	  	done

		  ;;

	  r)
	  	root_use
	  	send_stats "すべてのアプリを復元する"
	  	echo "利用可能なアプリケーションのバックアップ"
	  	echo "-------------------------"
	  	ls -lt /app*.gz | awk '{print $NF}'
	  	echo ""
	  	read -e -p  "Enter キーを押して最新のバックアップを復元し、バックアップ ファイル名を入力して指定したバックアップを復元し、0 を入力して終了します。" filename

	  	if [ "$filename" == "0" ]; then
			  break_end
			  linux_panel
	  	fi

	  	# ユーザーがファイル名を入力しない場合は、最新の圧縮パッケージが使用されます。
	  	if [ -z "$filename" ]; then
			  local filename=$(ls -t /app*.tar.gz | head -1)
	  	fi

	  	if [ -n "$filename" ]; then
		  	  echo -e "${gl_kjlan}解凍中$filename ...${gl_bai}"
		  	  cd / && tar -xzf "$filename"
			  echo "アプリケーションデータが復元されました。現在、アプリケーションを復元するには、手動で指定されたアプリケーションメニューに入り、アプリケーションを更新してください。"
	  	else
			  echo "圧縮パッケージが見つかりませんでした。"
	  	fi

		  ;;

	  0)
		  kejilion
		  ;;
	  *)
		cd ~
		install git
		if [ ! -d apps/.git ]; then
			timeout 10s git clone ${gh_proxy}github.com/kejilion/apps.git
		else
			cd apps
			# git pull origin main > /dev/null 2>&1
			timeout 10s git pull ${gh_proxy}github.com/kejilion/apps.git main > /dev/null 2>&1
		fi
		local custom_app="$HOME/apps/${sub_choice}.conf"
		if [ -f "$custom_app" ]; then
			. "$custom_app"
		else
			echo -e "${gl_hong}エラー: 番号が見つかりません${sub_choice}アプリケーション構成${gl_bai}"
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
	  send_stats "バックエンドワークスペース"
	  echo -e "バックエンドワークスペース"
	  echo -e "システムは、バックグラウンドで永続的に実行できるワークスペースを提供し、長期的なタスクを実行するために使用できます。"
	  echo -e "SSH を切断しても、ワークスペース内のタスクは中断されず、タスクはバックグラウンドで残ります。"
	  echo -e "${gl_huang}ヒント：${gl_bai}ワークスペースに入ったら、Ctrl+b を使用し、d を単独で押してワークスペースを終了します。"
	  echo -e "${gl_kjlan}------------------------"
	  echo "現在存在するワークスペースのリスト"
	  echo -e "${gl_kjlan}------------------------"
	  tmux list-sessions
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}作業エリア1"
	  echo -e "${gl_kjlan}2.   ${gl_bai}作業エリア 2"
	  echo -e "${gl_kjlan}3.   ${gl_bai}作業エリア 3"
	  echo -e "${gl_kjlan}4.   ${gl_bai}作業エリア 4"
	  echo -e "${gl_kjlan}5.   ${gl_bai}ワークスペースNo.5"
	  echo -e "${gl_kjlan}6.   ${gl_bai}作業エリア6"
	  echo -e "${gl_kjlan}7.   ${gl_bai}作業エリア 7"
	  echo -e "${gl_kjlan}8.   ${gl_bai}作業エリア8"
	  echo -e "${gl_kjlan}9.   ${gl_bai}ワークスペースNo.9"
	  echo -e "${gl_kjlan}10.  ${gl_bai}ワークスペース10"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}SSH常駐モード${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}22.  ${gl_bai}ワークスペースの作成/入力"
	  echo -e "${gl_kjlan}23.  ${gl_bai}バックグラウンドワークスペースにコマンドを挿入する"
	  echo -e "${gl_kjlan}24.  ${gl_bai}指定したワークスペースを削除します"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in

		  1)
			  clear
			  install tmux
			  local SESSION_NAME="work1"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run

			  ;;
		  2)
			  clear
			  install tmux
			  local SESSION_NAME="work2"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  3)
			  clear
			  install tmux
			  local SESSION_NAME="work3"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  4)
			  clear
			  install tmux
			  local SESSION_NAME="work4"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  5)
			  clear
			  install tmux
			  local SESSION_NAME="work5"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  6)
			  clear
			  install tmux
			  local SESSION_NAME="work6"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  7)
			  clear
			  install tmux
			  local SESSION_NAME="work7"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  8)
			  clear
			  install tmux
			  local SESSION_NAME="work8"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  9)
			  clear
			  install tmux
			  local SESSION_NAME="work9"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;
		  10)
			  clear
			  install tmux
			  local SESSION_NAME="work10"
			  send_stats "ワークスペースの開始$SESSION_NAME"
			  tmux_run
			  ;;

		  21)
			while true; do
			  clear
			  if grep -q 'tmux attach-session -t sshd || tmux new-session -s sshd' ~/.bashrc; then
				  local tmux_sshd_status="${gl_lv}オンにする${gl_bai}"
			  else
				  local tmux_sshd_status="${gl_hui}閉鎖${gl_bai}"
			  fi
			  send_stats "SSH常駐モード"
			  echo -e "SSH常駐モード${tmux_sshd_status}"
			  echo "SSH 接続を開いた後、直接常駐モードに入り、前の動作状態に直接戻ります。"
			  echo "------------------------"
			  echo "1. オン 2. オフ"
			  echo "------------------------"
			  echo "0. 前のメニューに戻る"
			  echo "------------------------"
			  read -e -p "選択肢を入力してください:" gongzuoqu_del
			  case "$gongzuoqu_del" in
				1)
			  	  install tmux
			  	  local SESSION_NAME="sshd"
			  	  send_stats "ワークスペースの開始$SESSION_NAME"
				  grep -q "tmux attach-session -t sshd" ~/.bashrc || echo -e "\n# 自動的に tmux セッションに入ります\nif [[ -z \"\$TMUX\" ]]; then\n    tmux attach-session -t sshd || tmux new-session -s sshd\nfi" >> ~/.bashrc
				  source ~/.bashrc
			  	  tmux_run
				  ;;
				2)
				  sed -i '/# 自動的に tmux セッションに入ります/,+4d' ~/.bashrc
				  tmux kill-window -t sshd
				  ;;
				*)
				  break
				  ;;
			  esac
			done
			  ;;

		  22)
			  read -e -p "作成または入力したワークスペースの名前を入力してください (1001 kj001 work1 など)。" SESSION_NAME
			  tmux_run
			  send_stats "カスタムワークスペース"
			  ;;


		  23)
			  read -e -p "バックグラウンドで実行するコマンドを入力してください。たとえば、curl -fsSL https://get.docker.com |し:" tmuxd
			  tmux_run_d
			  send_stats "バックグラウンドワークスペースにコマンドを挿入する"
			  ;;

		  24)
			  read -e -p "削除するワークスペースの名前を入力してください:" gongzuoqu_name
			  tmux kill-window -t $gongzuoqu_name
			  send_stats "ワークスペースの削除"
			  ;;

		  0)
			  kejilion
			  ;;
		  *)
			  echo "無効な入力です!"
			  ;;
	  esac
	  break_end

	done


}










# インテリジェントスイッチングミラーソース機能
switch_mirror() {
	# オプションのパラメータ、デフォルトは false
	local upgrade_software=${1:-false}
	local clean_cache=${2:-false}

	# ユーザーの国を取得する
	local country
	country=$(curl -s ipinfo.io/country)

	echo "検出された国:$country"

	if [ "$country" = "CN" ]; then
		echo "国内のミラーソースを使用..."
		bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
		  --source mirrors.huaweicloud.com \
		  --protocol https \
		  --use-intranet-source false \
		  --backup true \
		  --upgrade-software "$upgrade_software" \
		  --clean-cache "$clean_cache" \
		  --ignore-backup-tips \
		  --install-epel false \
		  --pure-mode
	else
		echo "海外のミラーソースを使用..."
		if [ -f /etc/os-release ] && grep -qi "oracle" /etc/os-release; then
			bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
			  --source mirrors.xtom.com \
			  --protocol https \
			  --use-intranet-source false \
			  --backup true \
			  --upgrade-software "$upgrade_software" \
			  --clean-cache "$clean_cache" \
			  --ignore-backup-tips \
			  --install-epel false \
			  --pure-mode
		else
			bash <(curl -sSL https://linuxmirrors.cn/main.sh) \
				--use-official-source true \
				--protocol https \
				--use-intranet-source false \
				--backup true \
				--upgrade-software "$upgrade_software" \
				--clean-cache "$clean_cache" \
				--ignore-backup-tips \
				--install-epel false \
				--pure-mode
		fi
	fi
}


fail2ban_panel() {
		  root_use
		  send_stats "SSH防御"
		  while true; do

				check_f2b_status
				echo -e "SSH防御プログラム$check_f2b_status"
				echo "failed2ban はブルート フォース クラッキングを防ぐ SSH ツールです"
				echo "公式サイト紹介：${gh_proxy}github.com/fail2ban/fail2ban"
				echo "------------------------"
				echo "1. 防御プログラムをインストールする"
				echo "------------------------"
				echo "2. SSH インターセプト記録の表示"
				echo "3. リアルタイムログ監視"
				echo "------------------------"
				echo "4. 基本パラメータ設定（禁止期間/時間枠/リトライ回数）"
				echo "5. 設定ファイル(nano)の編集"
				echo "------------------------"
				echo "9. 防御プログラムをアンインストールする"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択肢を入力してください:" sub_choice
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
					4)
						send_stats "SSH防御基本パラメータ設定"
						f2b_basic_config
						break_end
						;;
					5)
						send_stats "SSH 防御構成ファイルの編集"
						f2b_edit_config
						break_end
						;;
					9)
						remove fail2ban
						rm -rf /etc/fail2ban
						echo "Fail2Ban 防御プログラムがアンインストールされました"
						break
						;;
					*)
						break
						;;
				esac
		  done

}





net_menu() {

	send_stats "ネットワークカード管理ツール"
	show_nics() {
		echo "================ 現在のネットワークカード情報 ================"
		printf "%-18s %-12s %-20s %-26s\n" "ネットワークカード名" "州" "IPアドレス" "MACアドレス"
		echo "------------------------------------------------"
		for nic in $(ls /sys/class/net); do
			state=$(cat /sys/class/net/$nic/operstate 2>/dev/null)
			ipaddr=$(ip -4 addr show $nic | awk '/inet /{print $2}' | head -n1)
			mac=$(cat /sys/class/net/$nic/address 2>/dev/null)
			printf "%-15s %-10s %-18s %-20s\n" "$nic" "$state" "${ipaddr:-无}" "$mac"
		done
		echo "================================================"
	}

	while true; do
		clear
		show_nics
		echo
		echo "=========== ネットワークカード管理メニュー ==========="
		echo "1.ネットワークカードを有効にする"
		echo "2.ネットワークカードを無効にする"
		echo "3. ネットワークカードの詳細を表示する"
		echo "4. ネットワークカード情報を更新する"
		echo "0. 前のメニューに戻る"
		echo "===================================="
		read -erp "アクションを選択してください:" choice

		case $choice in
			1)
				send_stats "ネットワークカードを有効にする"
				read -erp "有効にするネットワーク カードの名前を入力してください:" nic
				if ip link show "$nic" &>/dev/null; then
					ip link set "$nic" up && echo "✔ ネットワークカード$nic有効"
				else
					echo "✘ ネットワークカードが存在しません"
				fi
				read -erp "続行するには Enter キーを押してください..."
				;;
			2)
				send_stats "ネットワークカードを無効にする"
				read -erp "無効にするネットワーク カードの名前を入力してください:" nic
				if ip link show "$nic" &>/dev/null; then
					ip link set "$nic" down && echo "✔ ネットワークカード$nic無効"
				else
					echo "✘ ネットワークカードが存在しません"
				fi
				read -erp "続行するには Enter キーを押してください..."
				;;
			3)
				send_stats "ネットワークカードの詳細を表示する"
				read -erp "表示したいネットワーク カードの名前を入力してください:" nic
				if ip link show "$nic" &>/dev/null; then
					echo "========== $nic詳細 =========="
					ip addr show "$nic"
					ethtool "$nic" 2>/dev/null | head -n 10
				else
					echo "✘ ネットワークカードが存在しません"
				fi
				read -erp "続行するには Enter キーを押してください..."
				;;
			4)
				send_stats "ネットワークカード情報を更新する"
				continue
				;;
			*)
				break
				;;
		esac
	done
}



log_menu() {
	send_stats "システムログ管理ツール"

	show_log_overview() {
		echo "============= システムログの概要 ============="
		echo "ホスト名: $(ホスト名)"
		echo "システム時間: $(日付)"
		echo
		echo "[/var/logディレクトリ占有]"
		du -sh /var/log 2>/dev/null
		echo
		echo "【日記ログ職業】"
		journalctl --disk-usage 2>/dev/null
		echo "========================================"
	}

	while true; do
		clear
		show_log_overview
		echo
		echo "=========== システムログ管理メニュー ==========="
		echo "1. 最新のシステムログ（ジャーナル）を表示する"
		echo "2. 指定したサービスログを表示します。"
		echo "3. ログイン/セキュリティログの表示"
		echo "4. リアルタイム追跡ログ"
		echo "5. 古いジャーナル ログをクリーンアップする"
		echo "0. 前のメニューに戻る"
		echo "======================================="
		read -erp "アクションを選択してください:" choice

		case $choice in
			1)
				send_stats "最近のログを表示する"
				read -erp "最近のログ行を何行表示しましたか? [デフォルト 100]:" lines
				lines=${lines:-100}
				journalctl -n "$lines" --no-pager
				read -erp "続行するには Enter キーを押してください..."
				;;
			2)
				send_stats "指定したサービスログを表示する"
				read -erp "サービス名 (sshd、nginx など) を入力してください:" svc
				if systemctl list-unit-files | grep -q "^$svc"; then
					journalctl -u "$svc" -n 100 --no-pager
				else
					echo "✘ サービスが存在しないか、ログがありません"
				fi
				read -erp "続行するには Enter キーを押してください..."
				;;
			3)
				send_stats "ログイン/セキュリティログの表示"
				echo "====== 最近のログインログ ======"
				last -n 10
				echo
				echo "====== 認証ログ ======"
				if [ -f /var/log/secure ]; then
					tail -n 20 /var/log/secure
				elif [ -f /var/log/auth.log ]; then
					tail -n 20 /var/log/auth.log
				else
					echo "セキュリティログファイルが見つかりません"
				fi
				read -erp "続行するには Enter キーを押してください..."
				;;
			4)
				send_stats "リアルタイム追跡ログ"
				echo "1) システムログ"
				echo "2) サービスログの指定"
				read -erp "追跡タイプを選択します:" t
				if [ "$t" = "1" ]; then
					journalctl -f
				elif [ "$t" = "2" ]; then
					read -erp "サービス名を入力してください:" svc
					journalctl -u "$svc" -f
				else
					echo "無効な選択"
				fi
				;;
			5)
				send_stats "古いジャーナル ログをクリーンアップする"
				echo "⚠️ ジャーナルをクリーンアップします (安全な方法)"
				echo "1) 過去 7 日間を保存します"
				echo "2) 過去 3 日間を保存します"
				echo "3) 最大ログ サイズを 500M に制限する"
				read -erp "クリーニング方法を選択してください:" c
				case $c in
					1) journalctl --vacuum-time=7d ;;
					2) journalctl --vacuum-time=3d ;;
					3) journalctl --vacuum-size=500M ;;
					*) echo "無効なオプション" ;;
				esac
				echo "✔ ジャーナルログのクリーニングが完了しました"
				sleep 2
				;;
			*)
				break
				;;
		esac
	done
}



env_menu() {

	BASHRC="$HOME/.bashrc"
	PROFILE="$HOME/.profile"

	send_stats "システム変数管理ツール"

	show_env_vars() {
		clear
		send_stats "現在有効な環境変数"
		echo "========== 現在有効な環境変数（抜粋） =========="
		printf "%-20s %s\n" "変数名" "価値"
		echo "-----------------------------------------------"
		for v in USER HOME SHELL LANG PWD; do
			printf "%-20s %s\n" "$v" "${!v}"
		done

		echo
		echo "PATH:"
		echo "$PATH" | tr ':' '\n' | nl -ba

		echo
		echo "========== 設定ファイルに定義されている変数 (解析) =========="

		parse_file_vars() {
			local file="$1"
			[ -f "$file" ] || return

			echo
			echo ">>> ソースファイル:$file"
			echo "-----------------------------------------------"

			# 抽出エクスポート VAR=xxx または VAR=xxx
			grep -Ev '^\s*#|^\s*$' "$file" \
			| grep -E '^(export[[:space:]]+)?[A-Za-z_][A-Za-z0-9_]*=' \
			| while read -r line; do
				var=$(echo "$line" | sed -E 's/^(export[[:space:]]+)?([A-Za-z_][A-Za-z0-9_]*).*/\2/')
				val=$(echo "$line" | sed -E 's/^[^=]+=//')
				printf "%-20s %s\n" "$var" "$val"
			done
		}

		parse_file_vars "$HOME/.bashrc"
		parse_file_vars "$HOME/.profile"

		echo
		echo "==============================================="
		read -erp "続行するには Enter キーを押してください..."
	}


	view_file() {
		local file="$1"
		send_stats "変数ファイルを表示する$file"
		clear
		if [ -f "$file" ]; then
			echo "========== ファイルを表示:$file =========="
			cat -n "$file"
			echo "===================================="
		else
			echo "ファイルが存在しません:$file"
		fi
		read -erp "続行するには Enter キーを押してください..."
	}

	edit_file() {
		local file="$1"
		send_stats "変数ファイルを編集する$file"
		install nano
		nano "$file"
	}

	source_files() {
		echo "環境変数を再ロードしています..."
		send_stats "環境変数の再読み込み"
		source "$BASHRC"
		source "$PROFILE"
		echo "✔ 環境変数がリロードされました"
		read -erp "続行するには Enter キーを押してください..."
	}

	while true; do
		clear
		echo "=========== システム環境変数の管理 =========="
		echo "現在のユーザー:$USER"
		echo "--------------------------------------"
		echo "1. 現在一般的に使用されている環境変数を確認します。"
		echo "2. ~/.bashrc を表示する"
		echo "3. ~/.profile を表示する"
		echo "4. ~/.bashrc を編集する"
		echo "5. ~/.profile を編集する"
		echo "6. 環境変数（ソース）をリロードします。"
		echo "--------------------------------------"
		echo "0. 前のメニューに戻る"
		echo "--------------------------------------"
		read -erp "アクションを選択してください:" choice

		case "$choice" in
			1)
				show_env_vars
				;;
			2)
				view_file "$BASHRC"
				;;
			3)
				view_file "$PROFILE"
				;;
			4)
				edit_file "$BASHRC"
				;;
			5)
				edit_file "$PROFILE"
				;;
			6)
				source_files
				;;
			0)
				break
				;;
			*)
				echo "無効なオプション"
				sleep 1
				;;
		esac
	done
}


create_user_with_sshkey() {
	local new_username="$1"
	local is_sudo="${2:-false}"
	local sshkey_vl

	if [[ -z "$new_username" ]]; then
		echo "使用法: create_user_with_sshkey <ユーザー名>"
		return 1
	fi

	# ユーザーの作成
	useradd -m -s /bin/bash "$new_username" || return 1

	echo "公開鍵をインポートする例:"
	echo "  - URL：      ${gh_https_url}github.com/torvalds.keys"
	echo "- 直接貼り付けます: ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAI..."
	read -e -p "輸入してください${new_username}公開鍵:" sshkey_vl

	case "$sshkey_vl" in
		http://*|https://*)
			send_stats "URLからSSH公開キーをインポート"
			fetch_remote_ssh_keys "$sshkey_vl" "/home/$new_username"
			;;
		ssh-rsa*|ssh-ed25519*|ssh-ecdsa*)
			send_stats "公開鍵を直接インポートする"
			import_sshkey "$sshkey_vl" "/home/$new_username"
			;;
		*)
			echo "エラー: 不明なパラメータ '$sshkey_vl'"
			return 1
			;;
	esac


	# 権限を修正する
	chown -R "$new_username:$new_username" "/home/$new_username/.ssh"

	install sudo

	# sudo パスワード不要
	if [[ "$is_sudo" == "true" ]]; then
		cat >"/etc/sudoers.d/$new_username" <<EOF
$new_username ALL=(ALL) NOPASSWD:ALL
EOF
		chmod 440 "/etc/sudoers.d/$new_username"
	fi

	sed -i '/^\s*#\?\s*UsePAM\s\+/d' /etc/ssh/sshd_config
	echo 'UsePAM yes' >> /etc/ssh/sshd_config
	passwd -l "$new_username" &>/dev/null
	restart_ssh

	echo "ユーザー$new_username作成完了"
}















linux_Settings() {

	while true; do
	  clear
	  # send_stats 「システムツール」
	  echo -e "システムツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1.   ${gl_bai}スクリプト起動のショートカットキーを設定する${gl_kjlan}2.   ${gl_bai}ログインパスワードを変更する"
	  echo -e "${gl_kjlan}3.   ${gl_bai}ユーザーパスワードログインモード${gl_kjlan}4.   ${gl_bai}指定されたバージョンの Python をインストールします"
	  echo -e "${gl_kjlan}5.   ${gl_bai}すべてのポートを開く${gl_kjlan}6.   ${gl_bai}SSH接続ポートを変更する"
	  echo -e "${gl_kjlan}7.   ${gl_bai}DNSアドレスを最適化する${gl_kjlan}8.   ${gl_bai}ワンクリックでシステムを再インストールします${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}9.   ${gl_bai}ROOTアカウントを無効にして新しいアカウントを作成する${gl_kjlan}10.  ${gl_bai}スイッチ優先度 ipv4/ipv6"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}11.  ${gl_bai}ポートの占有状況を確認する${gl_kjlan}12.  ${gl_bai}仮想メモリのサイズを変更する"
	  echo -e "${gl_kjlan}13.  ${gl_bai}ユーザー管理${gl_kjlan}14.  ${gl_bai}ユーザー/パスワード生成器"
	  echo -e "${gl_kjlan}15.  ${gl_bai}システムのタイムゾーン調整${gl_kjlan}16.  ${gl_bai}BBR3アクセラレーションの設定"
	  echo -e "${gl_kjlan}17.  ${gl_bai}ファイアウォール アドバンスト マネージャー${gl_kjlan}18.  ${gl_bai}ホスト名の変更"
	  echo -e "${gl_kjlan}19.  ${gl_bai}システムアップデート元の切り替え${gl_kjlan}20.  ${gl_bai}スケジュールされたタスクの管理"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}21.  ${gl_bai}ネイティブホスト解像度${gl_kjlan}22.  ${gl_bai}SSH防御プログラム"
	  echo -e "${gl_kjlan}23.  ${gl_bai}電流制限自動シャットダウン${gl_kjlan}24.  ${gl_bai}ユーザーキーログインモード"
	  echo -e "${gl_kjlan}25.  ${gl_bai}TG-bot システムの監視と早期警告${gl_kjlan}26.  ${gl_bai}OpenSSH の高リスク脆弱性を修正"
	  echo -e "${gl_kjlan}27.  ${gl_bai}Red Hat Linux カーネルのアップグレード${gl_kjlan}28.  ${gl_bai}Linuxシステムのカーネルパラメータの最適化${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}29.  ${gl_bai}ウイルススキャンツール${gl_huang}★${gl_bai}                     ${gl_kjlan}30.  ${gl_bai}ファイルマネージャー"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}31.  ${gl_bai}システム言語を切り替える${gl_kjlan}32.  ${gl_bai}コマンドライン美化ツール${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}33.  ${gl_bai}システムのごみ箱をセットアップする${gl_kjlan}34.  ${gl_bai}システムのバックアップとリカバリ"
	  echo -e "${gl_kjlan}35.  ${gl_bai}SSHリモート接続ツール${gl_kjlan}36.  ${gl_bai}ハードディスクパーティション管理ツール"
	  echo -e "${gl_kjlan}37.  ${gl_bai}コマンドラインの履歴${gl_kjlan}38.  ${gl_bai}rsync リモート同期ツール"
	  echo -e "${gl_kjlan}39.  ${gl_bai}コマンドのお気に入り${gl_huang}★${gl_bai}                       ${gl_kjlan}40.  ${gl_bai}ネットワークカード管理ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}41.  ${gl_bai}システムログ管理ツール${gl_huang}★${gl_bai}                 ${gl_kjlan}42.  ${gl_bai}システム変数管理ツール"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}61.  ${gl_bai}掲示板${gl_kjlan}66.  ${gl_bai}ワンストップのシステムチューニング${gl_huang}★${gl_bai}"
	  echo -e "${gl_kjlan}99.  ${gl_bai}サーバーを再起動します${gl_kjlan}100. ${gl_bai}プライバシーとセキュリティ"
	  echo -e "${gl_kjlan}101. ${gl_bai}k コマンドの高度な使用法${gl_huang}★${gl_bai}                    ${gl_kjlan}102. ${gl_bai}Tech Lion スクリプトをアンインストールする"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0.   ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in
		  1)
			  while true; do
				  clear
				  read -e -p "ショートカット キーを入力してください (終了するには 0 を入力してください):" kuaijiejian
				  if [ "$kuaijiejian" == "0" ]; then
					   break_end
					   linux_Settings
				  fi
				  find /usr/local/bin/ -type l -exec bash -c 'test "$(readlink -f {})" = "/usr/local/bin/k" && rm -f {}' \;
				  if [ "$kuaijiejian" != "k" ]; then
					  ln -sf /usr/local/bin/k /usr/local/bin/$kuaijiejian
				  fi
				  ln -sf /usr/local/bin/k /usr/bin/$kuaijiejian > /dev/null 2>&1
				  echo "ショートカットキーが設定されている"
				  send_stats "スクリプトのショートカットキーが設定されました"
				  break_end
				  linux_Settings
			  done
			  ;;

		  2)
			  clear
			  send_stats "ログインパスワードを設定する"
			  echo "ログインパスワードを設定する"
			  passwd
			  ;;
		  3)
			  clear
			  add_sshpasswd
			  ;;

		  4)
			root_use
			send_stats "pyのバージョン管理"
			echo "Pythonのバージョン管理"
			echo "ビデオ紹介: https://www.bilibili.com/video/BV1Pm42157cK?t=0.1"
			echo "---------------------------------------"
			echo "この機能を使用すると、Python で公式にサポートされているバージョンをシームレスにインストールできます。"
			local VERSION=$(python3 -V 2>&1 | awk '{print $2}')
			echo -e "現在のPythonのバージョン番号:${gl_huang}$VERSION${gl_bai}"
			echo "------------"
			echo "推奨バージョン: 3.12 3.11 3.10 3.9 3.8 2.7"
			echo "他のバージョンを確認してください: https://www.python.org/downloads/"
			echo "------------"
			read -e -p "インストールする Python のバージョン番号を入力します (終了するには 0 を入力します)。" py_new_v


			if [[ "$py_new_v" == "0" ]]; then
				send_stats "スクリプト PY 管理"
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
					echo "不明なパッケージマネージャーです!"
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
			echo -e "現在のPythonのバージョン番号:${gl_huang}$VERSION${gl_bai}"
			send_stats "スクリプトPYバージョン切り替え"

			  ;;

		  5)
			  root_use
			  send_stats "ポートを開く"
			  iptables_open
			  remove iptables-persistent ufw firewalld iptables-services > /dev/null 2>&1
			  echo "すべてのポートが開いています"

			  ;;
		  6)
			root_use
			send_stats "SSHポートを変更する"

			while true; do
				clear
				sed -i 's/^\s*#\?\s*Port/Port/' /etc/ssh/sshd_config

				# 現在の SSH ポート番号を読み取ります
				local current_port=$(grep -E '^ *Port [0-9]+' /etc/ssh/sshd_config | awk '{print $2}')

				# 現在の SSH ポート番号を出力する
				echo -e "現在の SSH ポート番号は次のとおりです。${gl_huang}$current_port ${gl_bai}"

				echo "------------------------"
				echo "ポート番号の範囲は 1 ～ 65535 です (終了するには 0 を入力します)。"

				# 新しい SSH ポート番号の入力をユーザーに求める
				read -e -p "新しい SSH ポート番号を入力してください:" new_port

				# ポート番号が有効な範囲内であるかどうかを確認します。
				if [[ $new_port =~ ^[0-9]+$ ]]; then  # 检查输入是否为数字
					if [[ $new_port -ge 1 && $new_port -le 65535 ]]; then
						send_stats "SSHポートが変更されました"
						new_ssh_port $new_port
					elif [[ $new_port -eq 0 ]]; then
						send_stats "SSHポート変更の終了"
						break
					else
						echo "ポート番号が無効です。 1 ～ 65535 の数字を入力してください。"
						send_stats "無効な SSH ポートが入力されました"
						break_end
					fi
				else
					echo "入力が無効です。数値を入力してください。"
					send_stats "無効な SSH ポートが入力されました"
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
			send_stats "新規ユーザーの root を無効にする"
			read -e -p "新しいユーザー名を入力してください (終了するには 0 を入力してください):" new_username
			if [ "$new_username" == "0" ]; then
				break_end
				linux_Settings
			fi

			create_user_with_sshkey $new_username true

			ssh-keygen -l -f /home/$new_username/.ssh/authorized_keys &>/dev/null && {
				passwd -l root &>/dev/null
				sed -i 's/^[[:space:]]*#\?[[:space:]]*PermitRootLogin.*/PermitRootLogin no/' /etc/ssh/sshd_config
			}

			;;


		  10)
			root_use
			send_stats "v4/v6 の優先順位を設定する"
			while true; do
				clear
				echo "v4/v6 の優先順位を設定する"
				echo "------------------------"


				if grep -Eq '^\s*precedence\s+::ffff:0:0/96\s+100\s*$' /etc/gai.conf 2>/dev/null; then
					echo -e "現在のネットワーク優先設定:${gl_huang}IPv4${gl_bai}優先度"
				else
					echo -e "現在のネットワーク優先設定:${gl_huang}IPv6${gl_bai}優先度"
				fi

				echo ""
				echo "------------------------"
				echo "1. IPv4 が先 2. IPv6 が先 3. IPv6 修復ツール"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "優先ネットワークを選択してください:" choice

				case $choice in
					1)
						prefer_ipv4
						;;
					2)
						rm -f /etc/gai.conf
						echo "IPv6優先に切り替えました"
						send_stats "IPv6優先に切り替えました"
						;;

					3)
						clear
						bash <(curl -L -s jhb.ovh/jb/v6.sh)
						echo "この機能は jhb によって提供されています。ありがとう!"
						send_stats "IPv6修復"
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
			send_stats "仮想メモリを設定する"
			while true; do
				clear
				echo "仮想メモリを設定する"
				local swap_used=$(free -m | awk 'NR==3{print $3}')
				local swap_total=$(free -m | awk 'NR==3{print $2}')
				local swap_info=$(free -m | awk 'NR==3{used=$3; total=$2; if (total == 0) {percentage=0} else {percentage=used*100/total}; printf "%dM/%dM (%d%%)", used, total, percentage}')

				echo -e "現在の仮想メモリ:${gl_huang}$swap_info${gl_bai}"
				echo "------------------------"
				echo "1. 1024M の割り当て 2. 2048M の割り当て 3. 4096M の割り当て 4. カスタム サイズ"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択肢を入力してください:" choice

				case "$choice" in
				  1)
					send_stats "1Gの仮想メモリが設定されています"
					add_swap 1024

					;;
				  2)
					send_stats "2Gの仮想メモリが設定されています"
					add_swap 2048

					;;
				  3)
					send_stats "4G仮想メモリが設定されました"
					add_swap 4096

					;;

				  4)
					read -e -p "仮想メモリ サイズ (単位 M) を入力してください:" new_swap
					add_swap "$new_swap"
					send_stats "カスタム仮想メモリセット"
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
				printf "%-24s %-34s %-20s %-10s\n" "ユーザー名" "ユーザー権限" "ユーザーグループ" "sudo 権限"
				while IFS=: read -r username _ userid groupid _ _ homedir shell; do
					local groups=$(groups "$username" | cut -d : -f 2)
					local sudo_status
					if sudo -n -lU "$username" 2>/dev/null | grep -q "(ALL) \(NOPASSWD: \)\?ALL"; then
						sudo_status="Yes"
					else
						sudo_status="No"
					fi
					printf "%-20s %-30s %-20s %-10s\n" "$username" "$homedir" "$groups" "$sudo_status"
				done < /etc/passwd


				  echo ""
				  echo "アカウント操作"
				  echo "------------------------"
				  echo "1. 通常ユーザーを作成します。 2. 上級ユーザーを作成します。"
				  echo "------------------------"
				  echo "3. 最高の権限を付与する 4. 最高の権限を削除する"
				  echo "------------------------"
				  echo "5. アカウントを削除する"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択肢を入力してください:" sub_choice

				  case $sub_choice in
					  1)
					   # ユーザーに新しいユーザー名の入力を求める
					   read -e -p "新しいユーザー名を入力してください:" new_username
					   create_user_with_sshkey $new_username false

						  ;;

					  2)
					   # ユーザーに新しいユーザー名の入力を求める
					   read -e -p "新しいユーザー名を入力してください:" new_username
					   create_user_with_sshkey $new_username true

						  ;;
					  3)
					   read -e -p "ユーザー名を入力してください:" username
					   install sudo
					   cat >"/etc/sudoers.d/$username" <<EOF
$username ALL=(ALL) NOPASSWD:ALL
EOF
					  chmod 440 "/etc/sudoers.d/$username"

						  ;;
					  4)
					   read -e -p "ユーザー名を入力してください:" username
				  	   if [[ -f "/etc/sudoers.d/$username" ]]; then
						   grep -lR "^$username" /etc/sudoers.d/ 2>/dev/null | xargs rm -f
					   fi
					   sed -i "/^$username\s*ALL=(ALL)/d" /etc/sudoers
						  ;;
					  5)
					   read -e -p "削除するユーザー名を入力してください:" username
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
			send_stats "ユーザー情報ジェネレータ"
			echo "ランダムなユーザー名"
			echo "------------------------"
			for i in {1..5}; do
				username="user$(< /dev/urandom tr -dc _a-z0-9 | head -c6)"
				echo "ランダムなユーザー名$i: $username"
			done

			echo ""
			echo "ランダムな名前"
			echo "------------------------"
			local first_names=("John" "Jane" "Michael" "Emily" "David" "Sophia" "William" "Olivia" "James" "Emma" "Ava" "Liam" "Mia" "Noah" "Isabella")
			local last_names=("Smith" "Johnson" "Brown" "Davis" "Wilson" "Miller" "Jones" "Garcia" "Martinez" "Williams" "Lee" "Gonzalez" "Rodriguez" "Hernandez")

			# 5 つのランダムなユーザー名を生成する
			for i in {1..5}; do
				local first_name_index=$((RANDOM % ${#first_names[@]}))
				local last_name_index=$((RANDOM % ${#last_names[@]}))
				local user_name="${first_names[$first_name_index]} ${last_names[$last_name_index]}"
				echo "ランダムなユーザー名$i: $user_name"
			done

			echo ""
			echo "ランダムな UUID"
			echo "------------------------"
			for i in {1..5}; do
				uuid=$(cat /proc/sys/kernel/random/uuid)
				echo "ランダムな UUID$i: $uuid"
			done

			echo ""
			echo "16桁のランダムなパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c16)
				echo "ランダムなパスワード$i: $password"
			done

			echo ""
			echo "32ビットのランダムなパスワード"
			echo "------------------------"
			for i in {1..5}; do
				local password=$(< /dev/urandom tr -dc _A-Z-a-z-0-9 | head -c32)
				echo "ランダムなパスワード$i: $password"
			done
			echo ""

			  ;;

		  15)
			root_use
			send_stats "タイムゾーンを変更する"
			while true; do
				clear
				echo "システム時刻情報"

				# 現在のシステムのタイムゾーンを取得する
				local timezone=$(current_timezone)

				# 現在のシステム時刻を取得します
				local current_time=$(date +"%Y-%m-%d %H:%M:%S")

				# タイムゾーンと時間を表示する
				echo "現在のシステムのタイムゾーン:$timezone"
				echo "現在のシステム時間:$current_time"

				echo ""
				echo "タイムゾーンスイッチ"
				echo "------------------------"
				echo "アジア"
				echo "1. 中国上海時間 2. 中国香港時間"
				echo "3. 東京、日本時間 4. ソウル、韓国時間"
				echo "5. シンガポール時間 6. インド、コルカタ時間"
				echo "7. アラブ首長国連邦、ドバイ時間 8. オーストラリア、シドニー時間"
				echo "9.タイ・バンコク時間"
				echo "------------------------"
				echo "ヨーロッパ"
				echo "11. ロンドン、イギリス時間 12. パリ、フランス時間"
				echo "13. ベルリン、ドイツ時間 14. モスクワ、ロシア時間"
				echo "15. ユトラハト時間、オランダ 16. マドリッド時間、スペイン"
				echo "------------------------"
				echo "アメリカ"
				echo "21. 米国西部時間 22. 米国東部時間"
				echo "23. カナダ時間 24. メキシコ時間"
				echo "25. ブラジル時間 26. アルゼンチン時間"
				echo "------------------------"
				echo "31. UTC 世界標準時"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択肢を入力してください:" sub_choice


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
		  send_stats "ホスト名の変更"

		  while true; do
			  clear
			  local current_hostname=$(uname -n)
			  echo -e "現在のホスト名:${gl_huang}$current_hostname${gl_bai}"
			  echo "------------------------"
			  read -e -p "新しいホスト名を入力してください (終了するには 0 を入力してください):" new_hostname
			  if [ -n "$new_hostname" ] && [ "$new_hostname" != "0" ]; then
				  if [ -f /etc/alpine-release ]; then
					  # Alpine
					  echo "$new_hostname" > /etc/hostname
					  hostname "$new_hostname"
				  else
					  # Debian、Ubuntu、CentOS などのその他のシステム
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

				  echo "ホスト名は次のように変更されました。$new_hostname"
				  send_stats "ホスト名が変更されました"
				  sleep 1
			  else
				  echo "ホスト名を変更せずに終了しました。"
				  break
			  fi
		  done
			  ;;

		  19)
		  root_use
		  send_stats "システムアップデートソースを変更する"
		  clear
		  echo "更新元リージョンの選択"
		  echo "LinuxMirror にアクセスしてシステム アップデート ソースを切り替える"
		  echo "------------------------"
		  echo "1. 中国本土 [デフォルト] 2. 中国本土 [教育ネットワーク] 3. 海外地域 4. 更新ソースのインテリジェントな切り替え"
		  echo "------------------------"
		  echo "0. 前のメニューに戻る"
		  echo "------------------------"
		  read -e -p "選択内容を入力してください:" choice

		  case $choice in
			  1)
				  send_stats "中国本土のデフォルトのソース"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh)
				  ;;
			  2)
				  send_stats "中国本土の教育源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --edu
				  ;;
			  3)
				  send_stats "海外情報源"
				  bash <(curl -sSL https://linuxmirrors.cn/main.sh) --abroad
				  ;;
			  4)
				  send_stats "アップデートソースのインテリジェントな切り替え"
				  switch_mirror false false
				  ;;

			  *)
				  echo "キャンセル"
				  ;;

		  esac

			  ;;

		  20)
		  send_stats "スケジュールされたタスクの管理"
			  while true; do
				  clear
				  check_crontab_installed
				  clear
				  echo "スケジュールされたタスクのリスト"
				  crontab -l
				  echo ""
				  echo "操作する"
				  echo "------------------------"
				  echo "1. スケジュールされたタスクを追加します。 2. スケジュールされたタスクを削除します。 3. スケジュールされたタスクを編集します。"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択肢を入力してください:" sub_choice

				  case $sub_choice in
					  1)
						  read -e -p "新しいタスクの実行コマンドを入力してください:" newquest
						  echo "------------------------"
						  echo "1. 月次タスク 2. 週次タスク"
						  echo "3. 毎日のタスク 4. 時間ごとのタスク"
						  echo "------------------------"
						  read -e -p "選択肢を入力してください:" dingshi

						  case $dingshi in
							  1)
								  read -e -p "タスクを実行する日は月の何日ですか? (1-30):" day
								  (crontab -l ; echo "0 0 $day * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  2)
								  read -e -p "タスクを実行する曜日を選択しますか? (0 ～ 6、0 は日曜日を表します):" weekday
								  (crontab -l ; echo "0 0 * * $weekday $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  3)
								  read -e -p "毎日、そのタスクを実行する時刻を選択しますか? (時、0-23):" hour
								  (crontab -l ; echo "0 $hour * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  4)
								  read -e -p "タスクを実行する時間を入力してください。 (分、0 ～ 60):" minute
								  (crontab -l ; echo "$minute * * * * $newquest") | crontab - > /dev/null 2>&1
								  ;;
							  *)
								  break  # 跳出
								  ;;
						  esac
						  send_stats "スケジュールされたタスクを追加する"
						  ;;
					  2)
						  read -e -p "削除するタスクのキーワードを入力してください:" kquest
						  crontab -l | grep -v "$kquest" | crontab -
						  send_stats "スケジュールされたタスクを削除する"
						  ;;
					  3)
						  crontab -e
						  send_stats "スケジュールされたタスクを編集する"
						  ;;
					  *)
						  break  # 跳出循环，退出菜单
						  ;;
				  esac
			  done

			  ;;

		  21)
			  root_use
			  send_stats "ローカルホストの解決"
			  while true; do
				  clear
				  echo "ネイティブホスト解決リスト"
				  echo "ここに解析一致を追加すると、動的解析は使用されなくなります"
				  cat /etc/hosts
				  echo ""
				  echo "操作する"
				  echo "------------------------"
				  echo "1. 新しい解決策を追加 2. 解決策アドレスを削除"
				  echo "------------------------"
				  echo "0. 前のメニューに戻る"
				  echo "------------------------"
				  read -e -p "選択肢を入力してください:" host_dns

				  case $host_dns in
					  1)
						  read -e -p "新しい解析レコード形式を入力してください: 110.25.5.33 kejilion.pro:" addhost
						  echo "$addhost" >> /etc/hosts
						  send_stats "ローカルホスト解像度が追加されました"

						  ;;
					  2)
						  read -e -p "削除する必要がある解析済みコンテンツのキーワードを入力してください:" delhost
						  sed -i "/$delhost/d" /etc/hosts
						  send_stats "ローカルホストの解決と削除"
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
			send_stats "電流制限シャットダウン機能"
			while true; do
				clear
				echo "電流制限シャットダウン機能"
				echo "ビデオ紹介: https://www.bilibili.com/video/BV1mC411j7Qd?t=0.1"
				echo "------------------------------------------------"
				echo "現在のトラフィック使用量は、サーバーが再起動されるとクリアされます。"
				output_status
				echo -e "${gl_kjlan}受け取った合計:${gl_bai}$rx"
				echo -e "${gl_kjlan}送信合計:${gl_bai}$tx"

				# Limiting_Shut_down.sh ファイルが存在するかどうかを確認します
				if [ -f ~/Limiting_Shut_down.sh ]; then
					# しきい値_gbの値を取得する
					local rx_threshold_gb=$(grep -oP 'rx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					local tx_threshold_gb=$(grep -oP 'tx_threshold_gb=\K\d+' ~/Limiting_Shut_down.sh)
					echo -e "${gl_lv}現在設定されている受信トラフィック制限のしきい値は次のとおりです。${gl_huang}${rx_threshold_gb}${gl_lv}G${gl_bai}"
					echo -e "${gl_lv}現在設定されている送信トラフィック制限のしきい値は次のとおりです。${gl_huang}${tx_threshold_gb}${gl_lv}GB${gl_bai}"
				else
					echo -e "${gl_hui}電流制限シャットダウン機能は現在有効になっていません。${gl_bai}"
				fi

				echo
				echo "------------------------------------------------"
				echo "システムは実際のトラフィックがしきい値に達したかどうかを毎分検出し、しきい値に達するとサーバーを自動的にシャットダウンします。"
				echo "------------------------"
				echo "1. 電流制限シャットダウン機能を有効にする 2. 電流制限シャットダウン機能を無効にする"
				echo "------------------------"
				echo "0. 前のメニューに戻る"
				echo "------------------------"
				read -e -p "選択肢を入力してください:" Limiting

				case "$Limiting" in
				  1)
					# 新しい仮想メモリ サイズを入力してください
					echo "実際のサーバーのトラフィックが 100G しかない場合は、しきい値を 95G に設定し、事前にシャットダウンして、トラフィック エラーやオーバーフローを回避できます。"
					read -e -p "受信トラフィックのしきい値を入力してください (単位は G、デフォルトは 100G):" rx_threshold_gb
					rx_threshold_gb=${rx_threshold_gb:-100}
					read -e -p "送信トラフィックのしきい値を入力してください (単位は G、デフォルトは 100G):" tx_threshold_gb
					tx_threshold_gb=${tx_threshold_gb:-100}
					read -e -p "トラフィックのリセット日を入力してください (デフォルトは毎月 1 日にリセットされます)。" cz_day
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
					echo "電流制限シャットダウンが設定されています"
					send_stats "電流制限シャットダウンが設定されています"
					;;
				  2)
					check_crontab_installed
					crontab -l | grep -v '~/Limiting_Shut_down.sh' | crontab -
					crontab -l | grep -v 'reboot' | crontab -
					rm ~/Limiting_Shut_down.sh
					echo "電流制限シャットダウン機能がオフになる"
					;;
				  *)
					break
					;;
				esac
			done
			  ;;


		  24)
			sshkey_panel
			  ;;

		  25)
			  root_use
			  send_stats "電報警報"
			  echo "TG-bot監視・早期警告機能"
			  echo "動画紹介：https://youtu.be/vLL-eb3Z_TY"
			  echo "------------------------------------------------"
			  echo "ローカル CPU、メモリ、ハードディスク、トラフィック、SSH ログインのリアルタイム監視とアラートを実現するには、tg robot API とアラートを受信するユーザー ID を設定する必要があります。"
			  echo "しきい値に達すると、警告メッセージがユーザーに送信されます。"
			  echo -e "${gl_hui}- 通信量についてはサーバーを再起動すると再計算されます -${gl_bai}"
			  read -e -p "続行してもよろしいですか? (はい/いいえ):" choice

			  case "$choice" in
				[Yy])
				  send_stats "テレグラム警告が有効になっています"
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

				  # ~/.profile ファイルに追加
				  if ! grep -q 'bash ~/TG-SSH-check-notify.sh' ~/.profile > /dev/null 2>&1; then
					  echo 'bash ~/TG-SSH-check-notify.sh' >> ~/.profile
					  if command -v dnf &>/dev/null || command -v yum &>/dev/null; then
						 echo 'source ~/.profile' >> ~/.bashrc
					  fi
				  fi

				  source ~/.profile

				  clear
				  echo "TG-bot早期警戒システムが作動しました"
				  echo -e "${gl_hui}TG-check-notify.sh 警告ファイルを他のマシンのルート ディレクトリに置き、それを直接使用することもできます。${gl_bai}"
				  ;;
				[Nn])
				  echo "キャンセル"
				  ;;
				*)
				  echo "選択が無効です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;

		  26)
			  root_use
			  send_stats "高リスクの SSH 脆弱性を修正する"
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


		  39)
			  clear
			  linux_fav
			  ;;

		  40)
			  clear
			  net_menu
			  ;;

		  41)
			  clear
			  log_menu
			  ;;

		  42)
			  clear
			  env_menu
			  ;;


		  61)
			clear
			send_stats "掲示板"
			echo "Technology Lion の公式掲示板をご覧ください。脚本についてのアイデアがあれば、メッセージを残して交換してください。"
			echo "https://board.kejilion.pro"
			echo "公開パスワード: kejilion.sh"
			  ;;

		  66)

			  root_use
			  send_stats "ワンストップチューニング"
			  echo "ワンストップのシステムチューニング"
			  echo "------------------------------------------------"
			  echo "以下のコンテンツを運用・最適化していきます"
			  echo "1. システムアップデートソースを最適化し、システムを最新にアップデートします。"
			  echo "2. システムジャンクファイルをクリーンアップする"
			  echo -e "3. 仮想メモリを設定する${gl_huang}1G${gl_bai}"
			  echo -e "4. SSH ポート番号を次のように設定します。${gl_huang}5522${gl_bai}"
			  echo -e "5. SSH ブルート フォース クラッキングを防ぐために、fail2ban を開始します。"
			  echo -e "6.すべてのポートを開きます"
			  echo -e "7.電源を入れます${gl_huang}BBR${gl_bai}加速する"
			  echo -e "8. タイムゾーンを次のように設定します。${gl_huang}上海${gl_bai}"
			  echo -e "9. DNS アドレスを自動的に最適化する${gl_huang}海外：1.1.1.1 8.8.8.8 国内：223.5.5.5${gl_bai}"
		  	  echo -e "10. ネットワークを次のように設定します。${gl_huang}IPv4優先度${gl_bai}"
			  echo -e "11. 基本ツールのインストール${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
			  echo -e "12. Linuxシステムのカーネルパラメータの最適化${gl_huang}ネットワーク環境に応じて自動チューニング${gl_bai}"
			  echo "------------------------------------------------"
			  read -e -p "ワンクリックメンテナンスを実行してもよろしいですか? (はい/いいえ):" choice

			  case "$choice" in
				[Yy])
				  clear
				  send_stats "ワンストップチューニングが始まります"
				  echo "------------------------------------------------"
				  switch_mirror false false
				  linux_update
				  echo -e "[${gl_lv}OK${gl_bai}】1/12。システムを最新のものにアップデートする"

				  echo "------------------------------------------------"
				  linux_clean
				  echo -e "[${gl_lv}OK${gl_bai}】2/12。システムのジャンクファイルをクリーンアップする"

				  echo "------------------------------------------------"
				  add_swap 1024
				  echo -e "[${gl_lv}OK${gl_bai}】3/12。仮想メモリを設定する${gl_huang}1G${gl_bai}"

				  echo "------------------------------------------------"
				  new_ssh_port 5522
				  echo -e "[${gl_lv}OK${gl_bai}】4/12。 SSH ポート番号を次のように設定します。${gl_huang}5522${gl_bai}"
				  echo "------------------------------------------------"
				  f2b_install_sshd
				  cd ~
				  f2b_status
				  echo -e "[${gl_lv}OK${gl_bai}】5/12。 SSH ブルート フォース クラッキングを防ぐために、fail2ban を開始します。"

				  echo "------------------------------------------------"
				  echo -e "[${gl_lv}OK${gl_bai}】6/12。すべてのポートを開く"

				  echo "------------------------------------------------"
				  bbr_on
				  echo -e "[${gl_lv}OK${gl_bai}】7/12。開ける${gl_huang}BBR${gl_bai}加速する"

				  echo "------------------------------------------------"
				  set_timedate Asia/Shanghai
				  echo -e "[${gl_lv}OK${gl_bai}】8/12。タイムゾーンを次のように設定します${gl_huang}上海${gl_bai}"

				  echo "------------------------------------------------"
				  auto_optimize_dns
				  echo -e "[${gl_lv}OK${gl_bai}】9/12。 DNSアドレスを自動的に最適化する${gl_huang}${gl_bai}"
				  echo "------------------------------------------------"
				  prefer_ipv4
				  echo -e "[${gl_lv}OK${gl_bai}】10/12。ネットワークを次のように設定します${gl_huang}IPv4優先度${gl_bai}}"

				  echo "------------------------------------------------"
				  install_docker
				  install wget sudo tar unzip socat btop nano vim
				  echo -e "[${gl_lv}OK${gl_bai}】11/12。基本的なツールをインストールする${gl_huang}docker wget sudo tar unzip socat btop nano vim${gl_bai}"
				  echo "------------------------------------------------"

				  curl -sS ${gh_proxy}raw.githubusercontent.com/kejilion/sh/refs/heads/main/network-optimize.sh | bash
				  echo -e "[${gl_lv}OK${gl_bai}】12/12。 Linuxシステムのカーネルパラメータの最適化"
				  echo -e "${gl_lv}ワンストップでのシステムチューニングが完了${gl_bai}"

				  ;;
				[Nn])
				  echo "キャンセル"
				  ;;
				*)
				  echo "選択が無効です。Y または N を入力してください。"
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
			  	local status_message="${gl_lv}データの収集${gl_bai}"
			  elif grep -q '^ENABLE_STATS="false"' /usr/local/bin/k > /dev/null 2>&1; then
			  	local status_message="${gl_hui}コレクションは終了しました${gl_bai}"
			  else
			  	local status_message="不確実なステータス"
			  fi

			  echo "プライバシーとセキュリティ"
			  echo "スクリプトはユーザーの機能使用に関するデータを収集し、スクリプト エクスペリエンスを最適化し、より楽しくて便利な機能を作成します。"
			  echo "スクリプトのバージョン番号、使用時間、システムバージョン、CPUアーキテクチャ、マシンの国、使用された機能の名前が収集されます。"
			  echo "------------------------------------------------"
			  echo -e "現在のステータス:$status_message"
			  echo "--------------------"
			  echo "1.収集を開始する"
			  echo "2. コレクションを閉じる"
			  echo "--------------------"
			  echo "0. 前のメニューに戻る"
			  echo "--------------------"
			  read -e -p "選択肢を入力してください:" sub_choice
			  case $sub_choice in
				  1)
					  cd ~
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="false"/ENABLE_STATS="true"/' ~/kejilion.sh
					  echo "収集が開始されました"
					  send_stats "プライバシーとセキュリティの収集がオンになっています"
					  ;;
				  2)
					  cd ~
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' /usr/local/bin/k
					  sed -i 's/^ENABLE_STATS="true"/ENABLE_STATS="false"/' ~/kejilion.sh
					  echo "コレクションは終了しました"
					  send_stats "プライバシーとセキュリティの収集がオフになっています"
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
			  send_stats "Tech Lion スクリプトをアンインストールする"
			  echo "Tech Lion スクリプトをアンインストールする"
			  echo "------------------------------------------------"
			  echo "kejilion スクリプトは、他の機能に影響を与えることなく完全にアンインストールされます。"
			  read -e -p "続行してもよろしいですか? (はい/いいえ):" choice

			  case "$choice" in
				[Yy])
				  clear
				  (crontab -l | grep -v "kejilion.sh") | crontab -
				  rm -f /usr/local/bin/k
				  rm ~/kejilion.sh
				  echo "スクリプトはアンインストールされました、さようなら!"
				  break_end
				  clear
				  exit
				  ;;
				[Nn])
				  echo "キャンセル"
				  ;;
				*)
				  echo "選択が無効です。Y または N を入力してください。"
				  ;;
			  esac
			  ;;

		  0)
			  kejilion

			  ;;
		  *)
			  echo "無効な入力です!"
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
		echo "1. ディレクトリを入力します。 2. ディレクトリを作成します。 3. ディレクトリのアクセス許可を変更します。 4. ディレクトリの名前を変更します。"
		echo "5. ディレクトリを削除します。 6. 前のメニュー ディレクトリに戻ります。"
		echo "------------------------"
		echo "11. ファイルの作成 12. ファイルの編集 13. ファイル権限の変更 14. ファイル名の変更"
		echo "15. ファイルの削除"
		echo "------------------------"
		echo "21. ファイル ディレクトリの圧縮 22. ファイル ディレクトリの解凍 23. ファイル ディレクトリの移動 24. ファイル ディレクトリのコピー"
		echo "25. 他のサーバーにファイルを転送する"
		echo "------------------------"
		echo "0. 前のメニューに戻る"
		echo "------------------------"
		read -e -p "選択肢を入力してください:" Limiting

		case "$Limiting" in
			1)  # 进入目录
				read -e -p "ディレクトリ名を入力してください:" dirname
				cd "$dirname" 2>/dev/null || echo "ディレクトリに入れません"
				send_stats "ディレクトリを入力してください"
				;;
			2)  # 创建目录
				read -e -p "作成するディレクトリ名を入力してください:" dirname
				mkdir -p "$dirname" && echo "ディレクトリが作成されました" || echo "作成に失敗しました"
				send_stats "ディレクトリの作成"
				;;
			3)  # 修改目录权限
				read -e -p "ディレクトリ名を入力してください:" dirname
				read -e -p "権限を入力してください (例: 755):" perm
				chmod "$perm" "$dirname" && echo "権限が変更されました" || echo "変更に失敗しました"
				send_stats "ディレクトリの権限を変更する"
				;;
			4)  # 重命名目录
				read -e -p "現在のディレクトリ名を入力してください:" current_name
				read -e -p "新しいディレクトリ名を入力してください:" new_name
				mv "$current_name" "$new_name" && echo "ディレクトリの名前が変更されました" || echo "名前の変更に失敗しました"
				send_stats "ディレクトリの名前を変更する"
				;;
			5)  # 删除目录
				read -e -p "削除するディレクトリ名を入力してください:" dirname
				rm -rf "$dirname" && echo "ディレクトリが削除されました" || echo "削除に失敗しました"
				send_stats "ディレクトリを削除する"
				;;
			6)  # 返回上一级选单目录
				cd ..
				send_stats "前のメニュー ディレクトリに戻る"
				;;
			11) # 创建文件
				read -e -p "作成するファイル名を入力してください:" filename
				touch "$filename" && echo "ファイルが作成されました" || echo "作成に失敗しました"
				send_stats "ファイルの作成"
				;;
			12) # 编辑文件
				read -e -p "編集するファイル名を入力してください:" filename
				install nano
				nano "$filename"
				send_stats "ファイルを編集する"
				;;
			13) # 修改文件权限
				read -e -p "ファイル名を入力してください:" filename
				read -e -p "権限を入力してください (例: 755):" perm
				chmod "$perm" "$filename" && echo "権限が変更されました" || echo "変更に失敗しました"
				send_stats "ファイル権限を変更する"
				;;
			14) # 重命名文件
				read -e -p "現在のファイル名を入力してください:" current_name
				read -e -p "新しいファイル名を入力してください:" new_name
				mv "$current_name" "$new_name" && echo "ファイル名が変更されました" || echo "名前の変更に失敗しました"
				send_stats "ファイル名の変更"
				;;
			15) # 删除文件
				read -e -p "削除するファイル名を入力してください:" filename
				rm -f "$filename" && echo "ファイルが削除されました" || echo "削除に失敗しました"
				send_stats "ファイルの削除"
				;;
			21) # 压缩文件/目录
				read -e -p "圧縮するファイル/ディレクトリ名を入力してください:" name
				install tar
				tar -czvf "$name.tar.gz" "$name" && echo "に圧縮$name.tar.gz" || echo "圧縮に失敗しました"
				send_stats "圧縮ファイル/ディレクトリ"
				;;
			22) # 解压文件/目录
				read -e -p "抽出するファイル名 (.tar.gz) を入力してください:" filename
				install tar
				tar -xzvf "$filename" && echo "解凍された$filename" || echo "解凍に失敗しました"
				send_stats "ファイル/ディレクトリを解凍する"
				;;

			23) # 移动文件或目录
				read -e -p "移動するファイルまたはディレクトリのパスを入力してください:" src_path
				if [ ! -e "$src_path" ]; then
					echo "エラー: ファイルまたはディレクトリが存在しません。"
					send_stats "ファイルまたはディレクトリの移動に失敗しました: ファイルまたはディレクトリが存在しません"
					continue
				fi

				read -e -p "宛先パス (新しいファイル名またはディレクトリ名を含む) を入力してください:" dest_path
				if [ -z "$dest_path" ]; then
					echo "エラー: 宛先パスを入力してください。"
					send_stats "ファイルまたはディレクトリの移動に失敗しました: 宛先パスが指定されていません"
					continue
				fi

				mv "$src_path" "$dest_path" && echo "ファイルまたはディレクトリの移動先$dest_path" || echo "ファイルまたはディレクトリの移動に失敗しました"
				send_stats "ファイルまたはディレクトリを移動する"
				;;


		   24) # 复制文件目录
				read -e -p "コピーするファイルまたはディレクトリのパスを入力してください:" src_path
				if [ ! -e "$src_path" ]; then
					echo "エラー: ファイルまたはディレクトリが存在しません。"
					send_stats "ファイルまたはディレクトリのコピーに失敗しました: ファイルまたはディレクトリが存在しません"
					continue
				fi

				read -e -p "宛先パス (新しいファイル名またはディレクトリ名を含む) を入力してください:" dest_path
				if [ -z "$dest_path" ]; then
					echo "エラー: 宛先パスを入力してください。"
					send_stats "ファイルまたはディレクトリのコピーに失敗しました: 宛先パスが指定されていません"
					continue
				fi

				# -r オプションを使用してディレクトリを再帰的にコピーします
				cp -r "$src_path" "$dest_path" && echo "コピー先のファイルまたはディレクトリ$dest_path" || echo "ファイルまたはディレクトリのコピーに失敗しました"
				send_stats "ファイルまたはディレクトリをコピーする"
				;;


			 25) # 传送文件至远端服务器
				read -e -p "転送するファイル パスを入力してください:" file_to_transfer
				if [ ! -f "$file_to_transfer" ]; then
					echo "エラー: ファイルが存在しません。"
					send_stats "ファイルの転送に失敗しました: ファイルが存在しません"
					continue
				fi

				kj_ssh_read_host_user_port "リモートサーバーのIPを入力してください:" "リモート サーバーのユーザー名 (デフォルトの root) を入力してください:" "ログイン ポートを入力してください (デフォルトは 22):" "root" "22"
				local remote_ip="$KJ_SSH_HOST"
				local remote_user="$KJ_SSH_USER"
				local remote_port="$KJ_SSH_PORT"

				kj_ssh_read_password "リモートサーバーのパスワードを入力してください:"
				local remote_password="$KJ_SSH_PASSWORD"

				# 既知のホストの古いエントリをクリアする
				ssh-keygen -f "/root/.ssh/known_hosts" -R "$remote_ip"
				sleep 2  # 等待时间

				# scpを使用してファイルを転送する
				scp -P "$remote_port" -o StrictHostKeyChecking=no "$file_to_transfer" "$remote_user@$remote_ip:/home/" <<EOF
$remote_password
EOF

				if [ $? -eq 0 ]; then
					echo "ファイルはリモート サーバーのホーム ディレクトリに転送されました。"
					send_stats "ファイル転送が成功しました"
				else
					echo "ファイル転送に失敗しました。"
					send_stats "ファイル転送に失敗しました"
				fi

				break_end
				;;



			0)  # 返回上一级选单
				send_stats "前のメニューに戻る"
				break
				;;
			*)  # 处理无效输入
				echo "選択が無効です。再入力してください"
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

	# 抽出した情報を配列に変換する
	IFS=$'\n' read -r -d '' -a SERVER_ARRAY <<< "$SERVERS"

	# サーバーを横断してコマンドを実行する
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
	  send_stats "クラスターコントロールセンター"
	  echo "サーバークラスタ制御"
	  cat ~/cluster/servers.py
	  echo
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}サーバーリスト管理${gl_bai}"
	  echo -e "${gl_kjlan}1.  ${gl_bai}サーバーの追加${gl_kjlan}2.  ${gl_bai}サーバーの削除${gl_kjlan}3.  ${gl_bai}サーバーの編集"
	  echo -e "${gl_kjlan}4.  ${gl_bai}バックアップクラスタ${gl_kjlan}5.  ${gl_bai}クラスターを復元する"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}タスクをバッチで実行する${gl_bai}"
	  echo -e "${gl_kjlan}11. ${gl_bai}テクノロジ ライオン スクリプトをインストールする${gl_kjlan}12. ${gl_bai}アップデートシステム${gl_kjlan}13. ${gl_bai}システムをクリーンアップする"
	  echo -e "${gl_kjlan}14. ${gl_bai}ドッカーをインストールする${gl_kjlan}15. ${gl_bai}BBR3をインストールする${gl_kjlan}16. ${gl_bai}1Gの仮想メモリを設定する"
	  echo -e "${gl_kjlan}17. ${gl_bai}タイムゾーンを上海に設定${gl_kjlan}18. ${gl_bai}すべてのポートを開く${gl_kjlan}51. ${gl_bai}カスタム命令"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  echo -e "${gl_kjlan}0.  ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in
		  1)
			  send_stats "クラスターサーバーの追加"
			  read -e -p "サーバー名:" server_name
			  read -e -p "サーバーIP:" server_ip
			  read -e -p "サーバーポート (22):" server_port
			  local server_port=${server_port:-22}
			  read -e -p "サーバーのユーザー名 (root):" server_username
			  local server_username=${server_username:-root}
			  read -e -p "サーバーユーザーのパスワード:" server_password

			  sed -i "/servers = \[/a\    {\"name\": \"$server_name\", \"hostname\": \"$server_ip\", \"port\": $server_port, \"username\": \"$server_username\", \"password\": \"$server_password\", \"remote_path\": \"/home/\"}," ~/cluster/servers.py

			  ;;
		  2)
			  send_stats "クラスターサーバーの削除"
			  read -e -p "削除するキーワードを入力してください:" rmserver
			  sed -i "/$rmserver/d" ~/cluster/servers.py
			  ;;
		  3)
			  send_stats "クラスターサーバーの編集"
			  install nano
			  nano ~/cluster/servers.py
			  ;;

		  4)
			  clear
			  send_stats "バックアップクラスタ"
			  echo -e "変更してください${gl_huang}/root/cluster/servers.py${gl_bai}ファイルをダウンロードしてバックアップを完了してください。"
			  break_end
			  ;;

		  5)
			  clear
			  send_stats "クラスターを復元する"
			  echo "servers.py をアップロードし、任意のキーを押してアップロードを開始してください。"
			  echo -e "をアップロードしてください${gl_huang}servers.py${gl_bai}ファイルに${gl_huang}/root/cluster/${gl_bai}復元完了！"
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
			  send_stats "カスタム実行コマンド"
			  read -e -p "バッチ実行用のコマンドを入力してください:" mingling
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
send_stats "広告コラム"
echo "広告コラム"
echo "------------------------"
echo "ユーザーには、よりシンプルでエレガントなプロモーションと購入エクスペリエンスが提供されます。"
echo ""
echo -e "サーバー割引"
echo "------------------------"
echo -e "${gl_lan}Laika Cloud 香港 CN2 GIA 韓国のデュアル ISP 米国 CN2 GIA プロモーション${gl_bai}"
echo -e "${gl_bai}ウェブサイト: https://www.lcayun.com/aff/ZEXUQBIM${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}RackNerd 年間 10.99 ドル、米国、1 コア、1G メモリ、20G ハードドライブ、月あたり 1T トラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://my.racknerd.com/aff.php?aff=5501&pid=879${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}Hostinger 年間 $52.7 米国 1 コア 4G メモリ 50G ハードドライブ 月額 4T トラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://cart.hostinger.com/pay/d83c51e9-0c28-47a6-8414-b8ab010ef94f?_ga=GA1.3.942352702.1711283207${gl_bai}"
echo "------------------------"
echo -e "${gl_huang}Bricklayer 四半期あたり 49 ドル 米国 CN2GIA 日本 ソフトバンク 2 コア 1G メモリ 20G ハードドライブ 1T トラフィック/月${gl_bai}"
echo -e "${gl_bai}ウェブサイト: https://bandwagonhost.com/aff.php?aff=69004&pid=87${gl_bai}"
echo "------------------------"
echo -e "${gl_lan}DMIT 四半期あたり 28 ドル 米国 CN2GIA 1 コア 2G メモリ 20G ハード ドライブ 1 か月あたり 800G トラフィック${gl_bai}"
echo -e "${gl_bai}URL: https://www.dmit.io/aff.php?aff=4966&pid=100${gl_bai}"
echo "------------------------"
echo -e "${gl_zi}V.PS 月額 6.9 ドル 東京ソフトバンク 2 コア 1G メモリ 20G ハードドライブ 月額 1T トラフィック${gl_bai}"
echo -e "${gl_bai}URL：https://vps.hosting/cart/tokyo-cloud-kvm-vps/?id=148&?affid=1355&?affid=1355${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}さらに人気のある VPS オファー${gl_bai}"
echo -e "${gl_bai}ウェブサイト：https://kejilion.pro/topvps/${gl_bai}"
echo "------------------------"
echo ""
echo -e "ドメイン名の割引"
echo "------------------------"
echo -e "${gl_lan}GNAME 初年度 8.8 ドル COM ドメイン名 初年度 6.68 ドル CC ドメイン名${gl_bai}"
echo -e "${gl_bai}ウェブサイト: https://www.gname.com/register?tt=86836&ttcode=KEJILION86836&ttbj=sh${gl_bai}"
echo "------------------------"
echo ""
echo -e "テクノロジーライオン周辺機器"
echo "------------------------"
echo -e "${gl_kjlan}ステーションB:${gl_bai}https://b23.tv/2mqnQyh              ${gl_kjlan}オイルパイプ：${gl_bai}https://www.youtube.com/@kejilion${gl_bai}"
echo -e "${gl_kjlan}公式ウェブサイト:${gl_bai}https://kejilion.pro/              ${gl_kjlan}ナビゲーション:${gl_bai}https://dh.kejilion.pro/${gl_bai}"
echo -e "${gl_kjlan}ブログ:${gl_bai}https://blog.kejilion.pro/         ${gl_kjlan}ソフトウェアセンター:${gl_bai}https://app.kejilion.pro/${gl_bai}"
echo "------------------------"
echo -e "${gl_kjlan}スクリプト公式サイト：${gl_bai}https://kejilion.sh            ${gl_kjlan}GitHub アドレス:${gl_bai}${gh_https_url}github.com/kejilion/sh${gl_bai}"
echo "------------------------"
echo ""
}




games_server_tools() {

	while true; do
	  clear
	  echo -e "ゲームサーバー起動スクリプト集"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}1. ${gl_bai}Eudemons Parlu サーバー開始スクリプト"
	  echo -e "${gl_kjlan}2. ${gl_bai}Minecraft サーバーを開くスクリプト"
	  echo -e "${gl_kjlan}------------------------"
	  echo -e "${gl_kjlan}0. ${gl_bai}メインメニューに戻る"
	  echo -e "${gl_kjlan}------------------------${gl_bai}"
	  read -e -p "選択肢を入力してください:" sub_choice

	  case $sub_choice in

		  1) send_stats "Eudemons Parlu サーバー開始スクリプト" ; cd ~
			 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/palworld.sh ; chmod +x palworld.sh ; ./palworld.sh
			 exit
			 ;;
		  2) send_stats "Minecraft サーバーを開くスクリプト" ; cd ~
			 curl -sS -O ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/mc.sh ; chmod +x mc.sh ; ./mc.sh
			 exit
			 ;;

		  0)
			kejilion
			;;

		  *)
			echo "無効な入力です!"
			;;
	  esac
	  break_end

	done


}





















kejilion_update() {

send_stats "スクリプトの更新"
cd ~
while true; do
	clear
	echo "変更ログ"
	echo "------------------------"
	echo "すべてのログ:${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt"
	echo "------------------------"

	curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion_sh_log.txt | tail -n 30
	local sh_v_new=$(curl -s ${gh_proxy}raw.githubusercontent.com/kejilion/sh/main/kejilion.sh | grep -o 'sh_v="[0-9.]*"' | cut -d '"' -f 2)

	if [ "$sh_v" = "$sh_v_new" ]; then
		echo -e "${gl_lv}すでに最新バージョンを使用しています。${gl_huang}v$sh_v${gl_bai}"
		send_stats "スクリプトはすでに最新であるため、更新する必要はありません"
	else
		echo "新しいバージョン発見！"
		echo -e "現在のバージョン v$sh_v最新バージョン${gl_huang}v$sh_v_new${gl_bai}"
	fi


	local cron_job="kejilion.sh"
	local existing_cron=$(crontab -l 2>/dev/null | grep -F "$cron_job")

	if [ -n "$existing_cron" ]; then
		echo "------------------------"
		echo -e "${gl_lv}自動更新がオンになっており、スクリプトは毎日午前 2 時に自動的に更新されます。${gl_bai}"
	fi

	echo "------------------------"
	echo "1. 今すぐ更新します。 2. 自動更新をオンにします。 3. 自動更新をオフにします。"
	echo "------------------------"
	echo "0. メインメニューに戻る"
	echo "------------------------"
	read -e -p "選択肢を入力してください:" choice
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
			echo -e "${gl_lv}スクリプトが最新バージョンに更新されました。${gl_huang}v$sh_v_new${gl_bai}"
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
			echo -e "${gl_lv}自動更新がオンになっており、スクリプトは毎日午前 2 時に自動的に更新されます。${gl_bai}"
			send_stats "スクリプトの自動更新を有効にする"
			break_end
			;;
		3)
			clear
			(crontab -l | grep -v "kejilion.sh") | crontab -
			echo -e "${gl_lv}自動更新はオフになっています${gl_bai}"
			send_stats "スクリプトの自動更新をオフにする"
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
echo -e "テクノロジー ライオン スクリプト ツールボックス v$sh_v"
echo -e "コマンドライン入力${gl_huang}k${gl_kjlan}クイックスタートスクリプト${gl_bai}"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}1.   ${gl_bai}システム情報の問い合わせ"
echo -e "${gl_kjlan}2.   ${gl_bai}システムアップデート"
echo -e "${gl_kjlan}3.   ${gl_bai}システムのクリーンアップ"
echo -e "${gl_kjlan}4.   ${gl_bai}基本的なツール"
echo -e "${gl_kjlan}5.   ${gl_bai}BBR管理"
echo -e "${gl_kjlan}6.   ${gl_bai}Docker管理"
echo -e "${gl_kjlan}7.   ${gl_bai}ワープ管理"
echo -e "${gl_kjlan}8.   ${gl_bai}テストスクリプト集"
echo -e "${gl_kjlan}9.   ${gl_bai}Oracle Cloudスクリプト・コレクション"
echo -e "${gl_huang}10.  ${gl_bai}LDNMP Web サイトの構築"
echo -e "${gl_kjlan}11.  ${gl_bai}アプリケーション市場"
echo -e "${gl_kjlan}12.  ${gl_bai}バックエンドワークスペース"
echo -e "${gl_kjlan}13.  ${gl_bai}システムツール"
echo -e "${gl_kjlan}14.  ${gl_bai}サーバークラスタ制御"
echo -e "${gl_kjlan}15.  ${gl_bai}広告コラム"
echo -e "${gl_kjlan}16.  ${gl_bai}ゲームサーバー起動スクリプト集"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}00.  ${gl_bai}スクリプトの更新"
echo -e "${gl_kjlan}------------------------${gl_bai}"
echo -e "${gl_kjlan}0.   ${gl_bai}終了スクリプト"
echo -e "${gl_kjlan}------------------------${gl_bai}"
read -e -p "選択肢を入力してください:" choice

case $choice in
  1) linux_info ;;
  2) clear ; send_stats "システムアップデート" ; linux_update ;;
  3) clear ; send_stats "システムのクリーンアップ" ; linux_clean ;;
  4) linux_tools ;;
  5) linux_bbr ;;
  6) linux_docker ;;
  7) clear ; send_stats "反り管理" ; install wget
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
  *) echo "無効な入力です!" ;;
esac
	break_end
done
}


k_info() {
send_stats "k コマンドのリファレンス例"
echo "-------------------"
echo "ビデオ紹介: https://www.bilibili.com/video/BV1ib421E7it?t=0.1"
echo "以下は、k コマンドの参考使用例です。"
echo "スクリプトkを開始します"
echo "パッケージをインストールします k install nano wget | k ナノ wget を追加 | nano wgetをインストールします"
echo "パッケージをアンインストールします。 k 削除 nano wget | kデルナノwget | nano wget をアンインストールする | nano wgetをアンインストールします"
echo "システム k アップデートを更新 | kアップデート"
echo "クリーン系ジャンククリーン |きれいだ"
echo "システムパネルを再度取り付けます。 k再インストール"
echo "BBR3 コントロール パネル K BBR3 | k bbrv3"
echo "カーネル チューニング パネルk カーネルの最適化"
echo "仮想メモリ k スワップを設定 2048"
echo "仮想タイムゾーンを設定します k 時間 アジア/上海 | k タイムゾーン アジア/上海"
echo "システムごみ箱のゴミ箱 | k hz | k ごみ箱"
echo "システムバックアップ機能 kバックアップ | k bf | k バックアップ"
echo "ssh リモート接続ツール k ssh | k リモート接続"
echo "rsync リモート同期ツール k rsync | k リモート同期"
echo "ハードディスク管理ツール k ディスク | k ハードディスクの管理"
echo "イントラネット普及率 (サーバー) k frps"
echo "イントラネット浸透率 (クライアント) k frpc"
echo "ソフトウェア起動 k start sshd | sshdを起動します"
echo "ソフトウェア停止 k 停止 sshd | k ストップ sshd"
echo "ソフトウェア再起動 k 再起動 sshd | k sshdを再起動します"
echo "ソフトウェアのステータスを確認します。 k ステータス sshd | kステータスsshd"
echo "k ドッカーを有効にする | k 自動開始ドッカー | k ソフトウェアの起動時に Docker を有効にする"
echo "ドメイン名証明書アプリケーション k ssl"
echo "ドメイン名証明書の有効期限のクエリ k ssl ps"
echo "docker 管理プレーン k docker"
echo "docker 環境のインストール k docker install |k docker インストール"
echo "docker コンテナ管理 k docker ps |k docker コンテナ"
echo "docker イメージ管理 k docker img |k docker image"
echo "LDNMP サイト管理 k Web"
echo "LDNMP キャッシュのクリーニング k Web キャッシュ"
echo "WordPress をインストールします。 kワードプレス | k wp xxx.com"
echo "リバース プロキシをインストールします k fd |k rp |k リバース プロキシ |k fd xxx.com"
echo "ロード バランシングのインストール k ロード バランシング |k ロード バランシング"
echo "L4 ロード バランシング k ストリーム |k L4 ロード バランシングをインストールする"
echo "ファイアウォール パネル k fhq |k ファイアウォール"
echo "ポートを開きます k dkdk 8080 |k ポートを開きます 8080"
echo "ポート k gbdk 7800 を閉じる |k ポート 7800 を閉じる"
echo "リリース IP k fxip 127.0.0.0/8 |k リリース IP 127.0.0.0/8"
echo "ブロック IP k zzip 177.5.25.36 |k ブロック IP 177.5.25.36"
echo "コマンド お気に入り k お気に入り | k コマンドのお気に入り"
echo "アプリケーションマーケット管理kアプリ"
echo "申請番号の迅速な管理 k app 26 | kアプリ1パネル | k アプリ npm"
echo "フェイル 2 バン管理 k フェイル 2 バン | k f2b"
echo "システム情報を表示 k info"
echo "ROOT キー管理 k sshkey"
echo "SSH 公開キーのインポート (URL) k sshkey <url>"
echo "SSH 公開キーのインポート (GitHub) k sshkey github <user>"

}



if [ "$#" -eq 0 ]; then
	# 引数なしで対話型ロジックを実行します
	kejilion_sh
else
	# パラメータがある場合は、対応する関数を実行します
	case $1 in
		install|add|安装)
			shift
			send_stats "ソフトウェアのインストール"
			install "$@"
			;;
		remove|del|uninstall|卸载)
			shift
			send_stats "ソフトウェアのアンインストール"
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
			send_stats "スケジュールされたrsync同期"
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
			  echo "IP+ポートはサービスへのアクセスをブロックされています"
	  		else
			  ip_address
			  close_port "$port"
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
			send_stats "仮想メモリをすばやくセットアップする"
			add_swap "$@"
			;;

		time|时区)
			shift
			send_stats "タイムゾーンを素早く設定"
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
			send_stats "ソフトウェアのステータスを確認する"
			status "$@"
			;;
		start|启动)
			shift
			send_stats "ソフトウェアの起動"
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
			send_stats "起動時にソフトウェアが自動的に起動します"
			enable "$@"
			;;

		ssl)
			shift
			if [ "$1" = "ps" ]; then
				send_stats "証明書ステータスの表示"
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
					send_stats "Docker をすばやくインストールする"
					install_docker
					;;
				ps|容器)
					send_stats "迅速なコンテナ管理"
					docker_ps
					;;
				img|镜像)
					send_stats "素早い画像管理"
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
			send_stats "申し込む$@"
			linux_panel "$@"
			;;


		info)
			linux_info
			;;

		fail2ban|f2b)
			fail2ban_panel
			;;


		sshkey)

			shift
			case "$1" in
				"" )
					# sshkey → インタラクティブメニュー
					send_stats "SSHKey 対話型メニュー"
					sshkey_panel
					;;
				github )
					shift
					send_stats "GitHub から SSH 公開キーをインポートする"
					fetch_github_ssh_keys "$1"
					;;
				http://*|https://* )
					send_stats "URLからSSH公開キーをインポート"
					fetch_remote_ssh_keys "$1"
					;;
				ssh-rsa*|ssh-ed25519*|ssh-ecdsa* )
					send_stats "公開鍵を直接インポートする"
					import_sshkey "$1"
					;;
				* )
					echo "エラー: 不明なパラメータ '$1'"
					echo "使用法："
					echo "k sshkey は対話型メニューに入ります"
					echo "k sshkey \"<pubkey>\" SSH 公開キーを直接インポートします"
					echo "k sshkey <url> URL から SSH 公開キーをインポートします"
					echo "k sshkey github <user> GitHub から SSH 公開キーをインポートします"
					;;
			esac

			;;
		*)
			k_info
			;;
	esac
fi
