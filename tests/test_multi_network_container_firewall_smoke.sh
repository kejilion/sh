#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

test_script() (
	local script_path=$1
	local test_root
	local command_log
	local check_status=1
	local insert_status=0
	local docker_addresses

	test_root="$(mktemp -d)"
	trap 'rm -rf "${test_root}"' EXIT
	command_log="${test_root}/iptables.log"

	for helper in \
		get_container_ipv4_addresses \
		ensure_docker_user_rule \
		remove_docker_user_rule \
		block_container_port \
		clear_container_rules
	do
		eval "$(
			awk -v helper="${helper}" '
				$0 ~ "^" helper "\\(\\) \\{" { capture=1 }
				capture { print }
				capture && /^}$/ { exit }
			' "${script_path}"
		)"
	done

	docker() {
		[ "$1" = "inspect" ] || return 1
		printf '%s\n' "${docker_addresses}"
	}
	install() { return 0; }
	save_iptables_rules() { return 0; }
	iptables() {
		case "$1" in
			-C)
				return "${check_status}"
				;;
			-I)
				printf '%s\n' "$*" >>"${command_log}"
				return "${insert_status}"
				;;
			-D)
				printf '%s\n' "$*" >>"${command_log}"
				return 0
				;;
		esac
		return 1
	}

	# 单网络容器保持原有行为。
	docker_addresses="172.22.0.2"
	: >"${command_log}"
	block_container_port test-container 192.0.2.10 >/dev/null
	test "$(wc -l <"${command_log}")" -eq 7
	grep -q -- '-d 172.22.0.2' "${command_log}"

	# 多网络容器应为每个独立 IP 应用规则，不能再拼接地址。
	docker_addresses=$'172.22.0.2\n172.21.0.2\n172.22.0.2'
	: >"${command_log}"
	block_container_port test-container 192.0.2.10 >/dev/null
	test "$(wc -l <"${command_log}")" -eq 14
	test "$(grep -c -- '-d 172.22.0.2' "${command_log}")" -eq 7
	test "$(grep -c -- '-d 172.21.0.2' "${command_log}")" -eq 7
	! grep -q '172.22.0.2172.21.0.2' "${command_log}"

	# 清除规则也必须覆盖全部网络地址。
	check_status=0
	: >"${command_log}"
	clear_container_rules test-container 192.0.2.10 >/dev/null
	test "$(wc -l <"${command_log}")" -eq 14
	test "$(grep -c -- '-D DOCKER-USER' "${command_log}")" -eq 14

	# iptables 写入失败时不得输出成功提示。
	check_status=1
	insert_status=1
	if output="$(block_container_port test-container 192.0.2.10 2>/dev/null)"; then
		printf '%s\n' "iptables failure was reported as successful: ${script_path}" >&2
		exit 1
	fi
	! grep -q '已阻止IP+端口访问该服务' <<<"${output}"
)

test_script "${project_root}/kejilion.sh"
test_script "${project_root}/cn/kejilion.sh"

printf '%s\n' "multi_network_container_firewall=pass"
