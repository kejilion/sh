#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
scripts=(
	"${project_root}/kejilion.sh"
	"${project_root}/cn/kejilion.sh"
)

extract_function() {
	local function_name="$1"
	local script_path="$2"
	awk -v signature="${function_name}() {" '
		$0 == signature { capture=1 }
		capture {
			print
			line=$0
			opens=gsub(/{/, "{", line)
			closes=gsub(/}/, "}", line)
			depth += opens - closes
			if (depth == 0) {
				exit
			}
		}
	' "${script_path}"
}

for script_path in "${scripts[@]}"; do
	bash -n "${script_path}"

	prepare_count="$(grep -Fc 'prepare_ldnmp_site_root "$yuming" || return 1' "${script_path}")"
	normalize_count="$(grep -Fc 'normalize_ldnmp_site_permissions "$yuming" || return 1' "${script_path}")"
	[ "${prepare_count}" -eq 11 ]
	[ "${normalize_count}" -eq 11 ]

	if grep -F 'mkdir $yuming' "${script_path}" >/dev/null; then
		printf '%s\n' "unsafe umask-dependent site directory creation remains in ${script_path}" >&2
		exit 1
	fi
	if grep -F 'chmod -R nginx:nginx' "${script_path}" >/dev/null; then
		printf '%s\n' "invalid chmod owner syntax remains in ${script_path}" >&2
		exit 1
	fi

	test_root="$(mktemp -d)"
	(
		eval "$(extract_function ldnmp_site_domain_is_safe "${script_path}")"
		eval "$(extract_function prepare_ldnmp_site_root "${script_path}")"
		eval "$(extract_function normalize_ldnmp_site_permissions "${script_path}")"

		ldnmp_web_root_base="${test_root}/html"
		install() {
			printf '%s\n' "shadowed install() must not be called" >&2
			return 97
		}
		mkdir() {
			printf '%s\n' "shadowed mkdir() must not be called" >&2
			return 98
		}
		chmod() {
			printf '%s\n' "shadowed chmod() must not be called" >&2
			return 99
		}
		umask 0077
		prepare_ldnmp_site_root "wp.example.test"
		command mkdir -p "${ldnmp_web_root_base}/wp.example.test/wordpress/wp-includes"
		printf '%s\n' "body {}" > "${ldnmp_web_root_base}/wp.example.test/wordpress/wp-includes/style.css"
		printf '%s\n' "#!/bin/sh" > "${ldnmp_web_root_base}/wp.example.test/wordpress/task.sh"
		command chmod 0755 "${ldnmp_web_root_base}/wp.example.test/wordpress/task.sh"

		[ "$(stat -c '%a' "${ldnmp_web_root_base}/wp.example.test")" = "755" ]
		[ "$(stat -c '%a' "${ldnmp_web_root_base}/wp.example.test/wordpress")" = "700" ]
		[ "$(stat -c '%a' "${ldnmp_web_root_base}/wp.example.test/wordpress/wp-includes/style.css")" = "600" ]

		normalize_ldnmp_site_permissions "wp.example.test"

		[ "$(stat -c '%a' "${ldnmp_web_root_base}/wp.example.test/wordpress")" = "755" ]
		[ "$(stat -c '%a' "${ldnmp_web_root_base}/wp.example.test/wordpress/wp-includes/style.css")" = "644" ]
		[ "$(stat -c '%a' "${ldnmp_web_root_base}/wp.example.test/wordpress/task.sh")" = "755" ]

		if prepare_ldnmp_site_root "../escape"; then
			printf '%s\n' "path traversal domain was accepted by ${script_path}" >&2
			exit 1
		fi
		[ ! -e "${test_root}/escape" ]
	)
	rm -rf -- "${test_root}"
done

for function_name in ldnmp_site_domain_is_safe prepare_ldnmp_site_root normalize_ldnmp_site_permissions; do
	cmp \
		<(extract_function "${function_name}" "${scripts[0]}") \
		<(extract_function "${function_name}" "${scripts[1]}")
done

grep -F 'chmod 0640 "/home/web/html/$yuming/wordpress/wp-config.php" || return 1' "${scripts[0]}" >/dev/null
grep -F 'chmod 0640 "/home/web/html/$yuming/wordpress/wp-config.php" || return 1' "${scripts[1]}" >/dev/null

printf '%s\n' "LDNMP site permission smoke tests passed"
