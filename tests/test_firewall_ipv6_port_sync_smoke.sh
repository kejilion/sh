#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

test_script() (
	local script_path=$1
	local test_root
	local command_log
	local v4_command_log
	local test_ipv6_ready=yes
	local insert_status=0

	test_root="$(mktemp -d)"
	trap 'rm -rf "${test_root}"' EXIT
	command_log="${test_root}/ip6tables.log"
	v4_command_log="${test_root}/iptables.log"

	for helper in ip6tables_available open_port close_port; do
		eval "$(
			awk -v helper="${helper}" '
				$0 ~ "^" helper "\\(\\) \\{" { capture=1 }
				capture { print }
				capture && /^}$/ { exit }
			' "${script_path}"
		)"
	done

	install() { return 0; }
	send_stats() { :; }
	save_iptables_rules() { return 0; }
	iptables() {
		case "$1" in
			-C) return 1 ;;
			-I) printf '%s\n' "$*" >>"${v4_command_log}"; return "${insert_status}" ;;
			-D) printf '%s\n' "$*" >>"${v4_command_log}"; return 0 ;;
			*) return 0 ;;
		esac
	}
	ip6tables() {
		if [ "${test_ipv6_ready}" != yes ]; then
			return 1
		fi
		case "$1" in
			-L) return 0 ;;
			-C) return 1 ;;
			-I) printf '%s\n' "$*" >>"${command_log}"; return "${insert_status}" ;;
			-D) printf '%s\n' "$*" >>"${command_log}"; return 0 ;;
			*) return 0 ;;
		esac
	}

	# IPv6 可用时 open_port 必须同步写入两个栈的 ACCEPT。
	: >"${command_log}"; : >"${v4_command_log}"
	open_port 8080 >/dev/null
	grep -q -- '-p tcp --dport 8080 -j ACCEPT' "${command_log}"
	grep -q -- '-p udp --dport 8080 -j ACCEPT' "${command_log}"
	grep -q -- '-p tcp --dport 8080 -j ACCEPT' "${v4_command_log}"
	grep -q -- '-p udp --dport 8080 -j ACCEPT' "${v4_command_log}"

	# IPv6 可用时 close_port 必须同步写入两个栈的 DROP 和 lo 放行。
	: >"${command_log}"; : >"${v4_command_log}"
	close_port 8080 >/dev/null
	grep -q -- '-p tcp --dport 8080 -j DROP' "${command_log}"
	grep -q -- '-p udp --dport 8080 -j DROP' "${command_log}"
	grep -q -- '-D INPUT -i lo -j ACCEPT' "${command_log}"
	grep -q -- '-I INPUT 1 -i lo -j ACCEPT' "${command_log}"
	grep -q -- '-I FORWARD 1 -i lo -j ACCEPT' "${command_log}"
	grep -q -- '-p tcp --dport 8080 -j DROP' "${v4_command_log}"

	# ip6tables 不可用时保持纯 IPv4 行为且不失败。
	test_ipv6_ready=no
	: >"${command_log}"; : >"${v4_command_log}"
	open_port 8080 >/dev/null
	[ "$(wc -l <"${command_log}")" -eq 0 ]
	grep -q -- '-p tcp --dport 8080 -j ACCEPT' "${v4_command_log}"
	close_port 8080 >/dev/null
	[ "$(wc -l <"${command_log}")" -eq 0 ]
	grep -q -- '-p tcp --dport 8080 -j DROP' "${v4_command_log}"

	# 插入失败必须返回非零而不是静默成功。
	test_ipv6_ready=yes
	insert_status=1
	if open_port 8080 >/dev/null 2>&1; then
		printf '%s\n' "open_port reported success despite ip6tables failure: ${script_path}" >&2
		exit 1
	fi
	if close_port 8080 >/dev/null 2>&1; then
		printf '%s\n' "close_port reported success despite ip6tables failure: ${script_path}" >&2
		exit 1
	fi
)

test_contract() {
	local script_path=$1

	# 持久化：v6 规则文件与开机恢复必须存在。
	grep -Fqx $'\t\tip6tables-save > "$rules6_temp" || ! mv -f -- "$rules6_temp" /etc/iptables/rules.v6; then' "${script_path}" ||
		grep -Fq 'mv -f -- "$rules6_temp" /etc/iptables/rules.v6' "${script_path}"
	grep -Fq "'@reboot ip6tables-restore < /etc/iptables/rules.v6'" "${script_path}"
	grep -Fq "grep -v 'ip6tables-restore'" "${script_path}"
	# 菜单全关必须同步收紧 v6 的 INPUT 策略。
	grep -Fq $'\t\t\t\t\t  ip6tables -P INPUT DROP' "${script_path}"
	# 菜单全开必须同步放松 v6 的 INPUT 策略。
	grep -Fq $'\t\t\t\t\t  ip6tables -P INPUT ACCEPT' "${script_path}"
}

for target in kejilion.sh cn/kejilion.sh; do
	script_path="${project_root}/${target}"
	test_script "${script_path}"
	test_contract "${script_path}"
done

printf '%s\n' "firewall_ipv6_port_sync=pass"
