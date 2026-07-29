#!/bin/bash

SCRIPT_PATH=$(readlink -f "$0" 2>/dev/null || printf '%s' "$0")
SCRIPT_DIR=$(dirname "$SCRIPT_PATH")
CONFIG_FILE="$SCRIPT_DIR/.kejilion_traffic_limit.conf"
STATE_FILE="$SCRIPT_DIR/.kejilion_traffic_limit.state"

rx_threshold_gb=110
tx_threshold_gb=120
reset_day=1
persist_after_reboot=0
boot_grace_minutes=15

is_number() {
	[[ "$1" =~ ^[0-9]+$ ]]
}

load_config() {
	if [ -f "$CONFIG_FILE" ]; then
		# shellcheck disable=SC1090
		. "$CONFIG_FILE"
	fi

	is_number "$rx_threshold_gb" || rx_threshold_gb=110
	is_number "$tx_threshold_gb" || tx_threshold_gb=120
	is_number "$reset_day" || reset_day=1
	is_number "$persist_after_reboot" || persist_after_reboot=0
	is_number "$boot_grace_minutes" || boot_grace_minutes=15

	(( reset_day < 1 )) && reset_day=1
	(( reset_day > 31 )) && reset_day=31
	(( boot_grace_minutes < 1 )) && boot_grace_minutes=15
	[ "$persist_after_reboot" -eq 1 ] || persist_after_reboot=0

	rx_threshold=$((rx_threshold_gb * 1024 * 1024 * 1024))
	tx_threshold=$((tx_threshold_gb * 1024 * 1024 * 1024))
}

load_state() {
	last_rx=0
	last_tx=0
	total_rx=0
	total_tx=0
	period_key=""
	last_boot_id=""
	maintenance_until=0
	session_skip_boot_id=""
	prompt_pending=0

	if [ -f "$STATE_FILE" ]; then
		# shellcheck disable=SC1090
		. "$STATE_FILE"
	fi

	is_number "$last_rx" || last_rx=0
	is_number "$last_tx" || last_tx=0
	is_number "$total_rx" || total_rx=0
	is_number "$total_tx" || total_tx=0
	is_number "$maintenance_until" || maintenance_until=0
	is_number "$prompt_pending" || prompt_pending=0
}

save_state() {
	cat > "$STATE_FILE" <<EOF
last_rx=$last_rx
last_tx=$last_tx
total_rx=$total_rx
total_tx=$total_tx
period_key=$period_key
last_boot_id=$last_boot_id
maintenance_until=$maintenance_until
session_skip_boot_id=$session_skip_boot_id
prompt_pending=$prompt_pending
EOF
	chmod 600 "$STATE_FILE"
}

get_boot_id() {
	cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo "unknown-boot"
}

get_public_traffic() {
	awk 'BEGIN { rx_total = 0; tx_total = 0 }
		$1 ~ /^(eth|ens|enp|eno)[0-9]+/ {
			rx_total += $2
			tx_total += $10
		}
		END {
			printf("%.0f %.0f\n", rx_total, tx_total);
		}' /proc/net/dev
}

format_bytes() {
	local bytes="${1:-0}"
	local units=("Bytes" "K" "M" "G" "T" "P")
	local unit_index=0
	local value="$bytes"

	while [ "$(printf '%.0f' "$value")" -ge 1024 ] && [ "$unit_index" -lt 5 ]; do
		value=$(awk -v v="$value" 'BEGIN { printf "%.2f", v / 1024 }')
		unit_index=$((unit_index + 1))
	done

	printf "%s%s" "$value" "${units[$unit_index]}"
}

format_seconds() {
	local seconds="${1:-0}"
	(( seconds < 0 )) && seconds=0

	local hours=$((seconds / 3600))
	local minutes=$(((seconds % 3600) / 60))

	if (( hours > 0 )); then
		printf "%d小时%d分钟" "$hours" "$minutes"
	else
		printf "%d分钟" "$minutes"
	fi
}

clamp_reset_day() {
	local year="$1"
	local month="$2"
	local wanted="$3"
	local last_day

	last_day=$(date -d "${year}-${month}-01 +1 month -1 day" +%d 2>/dev/null)
	last_day=$((10#$last_day))
	wanted=$((10#$wanted))

	if (( wanted > last_day )); then
		printf "%d" "$last_day"
	else
		printf "%d" "$wanted"
	fi
}

get_cycle_key() {
	local now_ts="${1:-$(date +%s)}"
	local year month current_day current_boundary prev_ref prev_year prev_month prev_day

	year=$(date -d "@$now_ts" +%Y)
	month=$(date -d "@$now_ts" +%m)
	current_day=$(clamp_reset_day "$year" "$month" "$reset_day")
	current_boundary=$(date -d "${year}-${month}-${current_day} 00:00:00" +%s)

	if (( now_ts >= current_boundary )); then
		printf "%04d-%02d-%02d" "$year" "$((10#$month))" "$current_day"
	else
		prev_ref=$(date -d "${year}-${month}-01 -1 month" +%Y-%m)
		prev_year=${prev_ref%-*}
		prev_month=${prev_ref#*-}
		prev_day=$(clamp_reset_day "$prev_year" "$prev_month" "$reset_day")
		printf "%04d-%02d-%02d" "$prev_year" "$((10#$prev_month))" "$prev_day"
	fi
}

is_over_limit() {
	(( used_rx >= rx_threshold || used_tx >= tx_threshold ))
}

reset_state_now() {
	local current_rx current_tx

	read -r current_rx current_tx < <(get_public_traffic)
	load_state
	total_rx=0
	total_tx=0
	last_rx=$current_rx
	last_tx=$current_tx
	period_key=$(get_cycle_key)
	last_boot_id=$(get_boot_id)
	maintenance_until=0
	session_skip_boot_id=""
	prompt_pending=0
	save_state
}

refresh_usage() {
	local now_ts current_rx current_tx current_boot_id current_period_key delta_rx delta_tx

	now_ts=$(date +%s)
	current_boot_id=$(get_boot_id)
	read -r current_rx current_tx < <(get_public_traffic)

	current_rx=${current_rx:-0}
	current_tx=${current_tx:-0}
	used_rx=$current_rx
	used_tx=$current_tx

	if [ "$persist_after_reboot" -ne 1 ]; then
		return
	fi

	load_state
	current_period_key=$(get_cycle_key "$now_ts")

	if [ "$period_key" != "$current_period_key" ]; then
		total_rx=0
		total_tx=0
		maintenance_until=0
		session_skip_boot_id=""
		prompt_pending=0
	fi

	if [ "$last_boot_id" != "$current_boot_id" ]; then
		delta_rx=$current_rx
		delta_tx=$current_tx
		session_skip_boot_id=""
		total_rx=$((total_rx + delta_rx))
		total_tx=$((total_tx + delta_tx))
		last_rx=$current_rx
		last_tx=$current_tx
		last_boot_id=$current_boot_id
		period_key=$current_period_key
		used_rx=$total_rx
		used_tx=$total_tx

		if [ "$persist_after_reboot" -eq 1 ] && [ "$session_skip_boot_id" != "$current_boot_id" ] && is_over_limit; then
			maintenance_until=$((now_ts + boot_grace_minutes * 60))
			prompt_pending=1
			if command -v wall >/dev/null 2>&1; then
				wall "限流自动关机提示：当前累计流量已达到设定阈值，已为本次开机保留 ${boot_grace_minutes} 分钟维护窗口。登录 root 后会看到处理提示。"
			fi
		fi

		save_state
		return
	else
		if (( current_rx >= last_rx )); then
			delta_rx=$((current_rx - last_rx))
		else
			delta_rx=$current_rx
		fi

		if (( current_tx >= last_tx )); then
			delta_tx=$((current_tx - last_tx))
		else
			delta_tx=$current_tx
		fi
	fi

	total_rx=$((total_rx + delta_rx))
	total_tx=$((total_tx + delta_tx))
	last_rx=$current_rx
	last_tx=$current_tx
	last_boot_id=$current_boot_id
	period_key=$current_period_key
	used_rx=$total_rx
	used_tx=$total_tx

	save_state
}

show_login_prompt() {
	local now_ts current_boot_id remaining_window choice custom_minutes

	[ "$persist_after_reboot" -eq 1 ] || return 0
	[ -t 0 ] || return 0
	[ -t 1 ] || return 0

	refresh_usage
	load_state
	now_ts=$(date +%s)
	current_boot_id=$(get_boot_id)

	if [ "$session_skip_boot_id" = "$current_boot_id" ]; then
		prompt_pending=0
		save_state
		return 0
	fi

	is_over_limit || return 0
	[ "$prompt_pending" -eq 1 ] || return 0

	while true; do
		echo
		echo "================================================"
		echo "当前累计流量已达到设定限额"
		echo "当前累计接收: $(format_bytes "$used_rx") / 阈值 ${rx_threshold_gb}G"
		echo "当前累计发送: $(format_bytes "$used_tx") / 阈值 ${tx_threshold_gb}G"
		echo "当前重置日: 每月 ${reset_day} 日"
		if (( maintenance_until > now_ts )); then
			remaining_window=$((maintenance_until - now_ts))
			echo "当前维护窗口剩余: $(format_seconds "$remaining_window")"
		else
			echo "当前维护窗口: 已过期"
		fi
		echo "------------------------------------------------"
		echo "1. 立即关机"
		echo "2. 使用默认维护窗口 (${boot_grace_minutes} 分钟)"
		echo "3. 自定义维护窗口"
		echo "4. 本次开机不再自动关机"
		echo "0. 保持当前维护窗口"
		echo "------------------------------------------------"
		read -r -p "请输入你的选择: " choice

		case "$choice" in
			1)
				prompt_pending=0
				maintenance_until=0
				save_state
				shutdown -h now
				exit 0
				;;
			2)
				maintenance_until=$((now_ts + boot_grace_minutes * 60))
				session_skip_boot_id=""
				prompt_pending=0
				save_state
				echo "已为本次开机设置 ${boot_grace_minutes} 分钟维护窗口。"
				break
				;;
			3)
				read -r -p "请输入维护窗口分钟数: " custom_minutes
				if is_number "$custom_minutes" && [ "$custom_minutes" -gt 0 ]; then
					maintenance_until=$((now_ts + custom_minutes * 60))
					session_skip_boot_id=""
					prompt_pending=0
					save_state
					echo "已为本次开机设置 ${custom_minutes} 分钟维护窗口。"
					break
				else
					echo "请输入大于 0 的整数分钟数。"
				fi
				;;
			4)
				session_skip_boot_id=$current_boot_id
				maintenance_until=0
				prompt_pending=0
				save_state
				echo "本次开机已暂停自动关机。下次重启后若仍超限，会再次提示。"
				break
				;;
			0|"")
				prompt_pending=0
				save_state
				echo "已保留当前维护窗口。"
				break
				;;
			*)
				echo "无效的选择，请重新输入。"
				;;
		esac
	done
}

run_monitor() {
	local now_ts current_boot_id

	refresh_usage

	echo "当前接收流量: $(format_bytes "$used_rx")"
	echo "当前发送流量: $(format_bytes "$used_tx")"

	if ! is_over_limit; then
		echo "当前流量未达到阈值，继续监视..."
		return 0
	fi

	if [ "$persist_after_reboot" -eq 1 ]; then
		load_state
		now_ts=$(date +%s)
		current_boot_id=$(get_boot_id)

		if [ "$session_skip_boot_id" = "$current_boot_id" ]; then
			echo "当前开机已临时暂停自动关机，等待下次重启后重新检查。"
			return 0
		fi

		if (( maintenance_until > now_ts )); then
			echo "当前已超限，但仍处于维护窗口内。"
			return 0
		fi
	fi

	echo "累计流量达到设定阈值，正在关闭服务器..."
	shutdown -h now
}

load_config

case "$1" in
	--boot-check)
		refresh_usage
		;;
	--login-prompt)
		show_login_prompt
		;;
	--reset-state)
		reset_state_now
		echo "限流累计数据已清零。"
		;;
	*)
		run_monitor
		;;
esac
