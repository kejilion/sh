#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"

# Extract only the installer wrapper; never source the executable host script.
for script_path in "$project_root/kejilion.sh" "$project_root/cn/kejilion.sh"; do
	eval "$(sed -n '/^ldnmp_environment_install() {/,/^}$/p' "$script_path")"

	kpanel_ldnmp_event() { :; }
	ldnmp_install_all() { return "$install_rc"; }
	nginx_install_all() { return "$install_rc"; }
	docker() {
		case "$1" in
			exec) return "$nginx_rc" ;;
			compose) return "$compose_rc" ;;
			inspect) printf '%s\n' "$container_states"; return "$inspect_rc" ;;
			*) echo "unexpected Docker command: $*" >&2; return 99 ;;
		esac
	}

	check_install() {
		local name="$1" profile="$2" expected="$3" actual=0
		# Match production: the function runs in an if condition, without errexit.
		if ldnmp_environment_install "$profile"; then actual=0; else actual=$?; fi
		if [ "$actual" -ne "$expected" ]; then
			printf 'FAIL: %s (%s): expected %s, got %s\n' "$name" "$script_path" "$expected" "$actual" >&2
			exit 1
		fi
	}

	install_rc=0 nginx_rc=0 compose_rc=0 inspect_rc=0
	container_states=$'true\ntrue\ntrue\ntrue'
	check_install healthy_full full 0
	check_install healthy_nginx nginx 0
	check_install default_profile '' 0
	check_install invalid_profile invalid 2

	install_rc=7
	check_install failed_full_install full 7
	check_install failed_nginx_install nginx 7
	install_rc=0

	nginx_rc=1
	check_install invalid_nginx_full full 1
	check_install invalid_nginx_only nginx 1
	nginx_rc=0 compose_rc=1
	check_install invalid_compose full 1
	compose_rc=0 inspect_rc=1
	check_install failed_inspect_with_output full 1
	inspect_rc=0

	container_states=$'true\nfalse\ntrue\ntrue'
	check_install stopped_container full 1
	container_states=$'true\ntrue\ntrue'
	check_install missing_container full 1
	container_states=''
	check_install empty_inspect full 1
	container_states=$'true\ntrue\ntrue\nnottrue'
	check_install malformed_state full 1
done

printf '%s\n' 'kpanel_ldnmp_install=pass'
