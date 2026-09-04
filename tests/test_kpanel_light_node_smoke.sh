#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script_path="${SCRIPT_PATH:-${project_root}/kejilion.sh}"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "${temporary_dir}"' EXIT

normalized_script="${temporary_dir}/kejilion.sh"
sed 's/\r$//' "${script_path}" >"${normalized_script}"
bash -n "${normalized_script}"

extract_heredoc() {
	local marker="$1" terminator="$2" output="$3"
	awk -v marker="$marker" -v terminator="$terminator" '
		$0 == marker { capture=1; next }
		capture && $0 == terminator { exit }
		capture { print }
	' "${normalized_script}" >"${output}"
}

updater="${temporary_dir}/update.sh"
extract_heredoc "\tcat >\"\$KPANEL_NODE_UPDATER\" <<'KPANEL_NODE_UPDATE'" "KPANEL_NODE_UPDATE" "${updater}"
test -s "${updater}"
bash -n "${updater}"

file_service="${temporary_dir}/kejilion-node-file.service"
extract_heredoc "\tcat >/etc/systemd/system/kejilion-node-file.service <<'KPANEL_NODE_FILE_SERVICE'" "KPANEL_NODE_FILE_SERVICE" "${file_service}"
test -s "${file_service}"

ssh_login_service="${temporary_dir}/kejilion-node-ssh-login.service"
extract_heredoc "\tcat >\"\$KPANEL_NODE_SSH_LOGIN_SERVICE\" <<'KPANEL_NODE_SSH_LOGIN_SERVICE'" "KPANEL_NODE_SSH_LOGIN_SERVICE" "${ssh_login_service}"
test -s "${ssh_login_service}"

protocol_body="$(
	awk '
		/^kpanel_protocol_active\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${normalized_script}"
)"
dispatch_body="$(
	awk '
		/^kpanel_node_dispatch\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${normalized_script}"
)"
join_body="$(
	awk '
		/^kpanel_node_join\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${normalized_script}"
)"
activate_body="$(
	awk '
		/^kpanel_node_activate\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${normalized_script}"
)"
account_body="$(
	awk '
		/^kpanel_node_ensure_account\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${normalized_script}"
)"
service_body="$(sed -n "/^\[Unit\]$/,/^KPANEL_NODE_SERVICE$/p" "${normalized_script}" | head -n -1)"
terminal_service_body="$(sed -n "/^Description=KPanel Lightweight Node Root PTY Broker$/,/^KPANEL_NODE_TERMINAL_SERVICE$/p" "${normalized_script}" | head -n -1)"
timer_body="$(sed -n "/^\[Timer\]$/,/^KPANEL_NODE_UPDATE_TIMER$/p" "${normalized_script}" | head -n -1)"

printf '%s\n' "${protocol_body}" | grep -F '[ "${KJ_LIGHT_NODE_PROTOCOL:-}" = "1" ]' >/dev/null
grep -F 'KJ_LIGHT_NODE_PROTOCOL=1' "${normalized_script}" >/dev/null
grep -F 'kpanel_node_dispatch "$@"' "${normalized_script}" >/dev/null
printf '%s\n' "${dispatch_body}" | grep -F 'join) kpanel_node_join "$@"' >/dev/null
printf '%s\n' "${dispatch_body}" | grep -F 'status) kpanel_node_status' >/dev/null
printf '%s\n' "${dispatch_body}" | grep -F 'update) kpanel_node_update' >/dev/null
printf '%s\n' "${dispatch_body}" | grep -F 'uninstall|remove) kpanel_node_uninstall' >/dev/null

printf '%s\n' "${join_body}" | grep -F 'kpl1.*)' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'kpanel_node_ensure_account || return 1' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'kpanel_node_write_uninstall_helper || ! kpanel_node_write_units' >/dev/null
printf '%s\n' "${join_body}" | grep -F "LC_ALL=C tr -cd '[:alnum:]_. -'" >/dev/null
printf '%s\n' "${join_body}" | grep -F 'resume_enrollment=true' >/dev/null
printf '%s\n' "${join_body}" | grep -Eq '授权已保存|authorization (has been )?saved|授權已儲存' >/dev/null
printf '%s\n' "${join_body}" | grep -F '"$KPANEL_NODE_INSTALL_BIN" -d -o root -g kejilion-node' >/dev/null
printf '%s\n' "${join_body}" | grep -F -- '--terminal-config "$KPANEL_NODE_TERMINAL_CONFIG"' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'useradd --system --no-create-home' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'systemd-sysusers "$sysusers_config"' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'adduser --system --group --no-create-home' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'adduser -S -D -H' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'id -gn kejilion-node' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chown root:kejilion-node "$KPANEL_NODE_CONFIG"' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chmod 0640 "$KPANEL_NODE_CONFIG"' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chown root:root "$KPANEL_NODE_TERMINAL_CONFIG"' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chmod 0600 "$KPANEL_NODE_TERMINAL_CONFIG"' >/dev/null
grep -F '[ -d /run/systemd/system ]' "${normalized_script}" >/dev/null
grep -F 'KPANEL_NODE_INSTALL_BIN="$(type -P install 2>/dev/null || true)"' "${normalized_script}" >/dev/null
grep -F 'KPANEL_NODE_SYSTEMCTL="$(type -P systemctl 2>/dev/null || true)"' "${normalized_script}" >/dev/null
grep -F '"$KPANEL_NODE_INSTALL_BIN" -d -o root -g root' "${normalized_script}" >/dev/null
if grep -F $'\tinstall -d -o root' "${normalized_script}" >/dev/null; then
	echo "lightweight node installer is shadowed by the package install helper" >&2
	exit 1
fi
if printf '%s\n' "${join_body}" | grep -Eq 'docker|podman'; then
	echo "lightweight node installer unexpectedly depends on a container runtime" >&2
	exit 1
fi
if printf '%s\n' "${activate_body}" | grep -Eq 'enable --now|is-active --quiet'; then
	echo "lightweight node activation uses wrapper-incompatible systemctl arguments" >&2
	exit 1
fi

grep -F 'base_url="https://github.com/kejilion/KPanel/releases/latest/download"' "${updater}" >/dev/null
grep -F -- "--proto '=https' --tlsv1.2" "${updater}" >/dev/null
grep -F 'SHA256SUMS' "${updater}" >/dev/null
grep -F 'sha256sum' "${updater}" >/dev/null
grep -F "grep -Eq '^[^[:space:]]+ light-v1$'" "${updater}" >/dev/null
grep -F 'was rolled back' "${updater}" >/dev/null
if grep -Eq 'curl .*(-k|--insecure)' "${updater}"; then
	echo "lightweight node updater disables TLS verification" >&2
	exit 1
fi

printf '%s\n' "${service_body}" | grep -Fx 'User=kejilion-node' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'RuntimeDirectory=kejilion-node' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'RuntimeDirectoryMode=0700' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'RuntimeDirectoryPreserve=yes' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'NoNewPrivileges=true' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'ProtectSystem=strict' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'ProtectHome=true' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'CapabilityBoundingSet=' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'Wants=kejilion-node-terminal.service' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'User=root' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'Group=root' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'ConditionPathExists=/etc/kejilion-node/terminal.json' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'ExecStart=/usr/local/lib/kejilion-node/kejilion-node terminal-broker --config /etc/kejilion-node/node.json --terminal-config /etc/kejilion-node/terminal.json' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'ProtectSystem=false' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'ProtectHome=false' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'PrivateDevices=false' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'NoNewPrivileges=false' >/dev/null
printf '%s\n' "${terminal_service_body}" | grep -Fx 'UMask=0077' >/dev/null
if printf '%s\n' "${terminal_service_body}" | grep -Eq 'Listen(Stream|Datagram)=|ExecStart=.*(sshd|socket)'; then
	echo "lightweight node terminal broker unexpectedly exposes a local listener" >&2
	exit 1
fi
grep -Fx 'User=root' "${ssh_login_service}" >/dev/null
grep -Fx 'Group=kejilion-node' "${ssh_login_service}" >/dev/null
grep -Fx 'ExecStart=/usr/local/lib/kejilion-node/kejilion-node ssh-login-broker --output /run/kejilion-node-ssh/ssh-login.json' "${ssh_login_service}" >/dev/null
grep -Fx 'RuntimeDirectory=kejilion-node-ssh' "${ssh_login_service}" >/dev/null
grep -Fx 'RuntimeDirectoryMode=0750' "${ssh_login_service}" >/dev/null
grep -Fx 'ProtectSystem=strict' "${ssh_login_service}" >/dev/null
grep -Fx 'ProtectHome=true' "${ssh_login_service}" >/dev/null
grep -Fx 'RestrictAddressFamilies=AF_UNIX' "${ssh_login_service}" >/dev/null
grep -Fx 'CapabilityBoundingSet=CAP_DAC_READ_SEARCH' "${ssh_login_service}" >/dev/null
grep -Fx 'ReadWritePaths=/run/kejilion-node-ssh' "${ssh_login_service}" >/dev/null
grep -Fx 'UMask=0027' "${ssh_login_service}" >/dev/null
if grep -Eq 'Listen(Stream|Datagram)=' "${ssh_login_service}"; then
	echo "SSH login collector unexpectedly exposes a listener" >&2
	exit 1
fi
grep -Fx 'User=root' "${file_service}" >/dev/null
grep -Fx 'Group=root' "${file_service}" >/dev/null
grep -Fx 'ExecStart=/usr/local/lib/kejilion-node/kejilion-node file-broker --config /etc/kejilion-node/node.json --terminal-config /etc/kejilion-node/terminal.json' "${file_service}" >/dev/null
grep -Fx 'ConditionPathExists=/etc/kejilion-node/terminal.json' "${file_service}" >/dev/null
if grep -Eq '^(ProtectSystem|ProtectHome|CapabilityBoundingSet)=' "${file_service}"; then
	echo "lightweight node file broker is isolated from the filesystem it must manage" >&2
	exit 1
fi
printf '%s\n' "${timer_body}" | grep -Fx 'OnUnitActiveSec=24h' >/dev/null
printf '%s\n' "${timer_body}" | grep -Fx 'RandomizedDelaySec=6h' >/dev/null
printf '%s\n' "${timer_body}" | grep -Fx 'Persistent=true' >/dev/null
grep -F 'kejilion-node-uninstall.service' "${normalized_script}" >/dev/null
grep -F 'PathExists=/run/kejilion-node/uninstall.request' "${normalized_script}" >/dev/null

# Exercise the systemd-sysusers fallback used by minimal systemd hosts that do
# not ship useradd. The fake PATH intentionally contains no useradd/adduser.
fallback_bin="${temporary_dir}/fallback-bin"
fallback_marker="${temporary_dir}/account-created"
mkdir -p "${fallback_bin}"
cat >"${fallback_bin}/id" <<'MOCK_ID'
#!/bin/bash
if [ -f "${KPANEL_TEST_ACCOUNT_MARKER}" ]; then
	if [ "${1:-}" = "-gn" ]; then
		printf '%s\n' kejilion-node
	fi
	exit 0
fi
exit 1
MOCK_ID
cat >"${fallback_bin}/systemd-sysusers" <<'MOCK_SYSUSERS'
#!/bin/bash
grep -F 'u kejilion-node - "KPanel Lightweight Monitoring Node" /nonexistent ' "$1" >/dev/null
touch "${KPANEL_TEST_ACCOUNT_MARKER}"
MOCK_SYSUSERS
cat >"${fallback_bin}/mktemp" <<'MOCK_MKTEMP'
#!/bin/bash
/usr/bin/mktemp "$@"
MOCK_MKTEMP
cat >"${fallback_bin}/rm" <<'MOCK_RM'
#!/bin/bash
/usr/bin/rm "$@"
MOCK_RM
cat >"${fallback_bin}/grep" <<'MOCK_GREP'
#!/bin/bash
/usr/bin/grep "$@"
MOCK_GREP
cat >"${fallback_bin}/touch" <<'MOCK_TOUCH'
#!/bin/bash
/usr/bin/touch "$@"
MOCK_TOUCH
chmod +x "${fallback_bin}"/*
(
	export PATH="${fallback_bin}"
	export KPANEL_TEST_ACCOUNT_MARKER="${fallback_marker}"
	eval "${account_body}"
	kpanel_node_ensure_account
)
test -f "${fallback_marker}"

# Exercise the native systemctl path one unit at a time. kejilion.sh defines a
# compatibility wrapper named systemctl, so node lifecycle calls must bypass it.
systemctl_bin="${temporary_dir}/systemctl"
systemctl_log="${temporary_dir}/systemctl.log"
cat >"${systemctl_bin}" <<'MOCK_SYSTEMCTL'
#!/bin/bash
printf '%s\n' "$*" >>"${KPANEL_TEST_SYSTEMCTL_LOG}"
MOCK_SYSTEMCTL
chmod +x "${systemctl_bin}"
(
	export KPANEL_TEST_SYSTEMCTL_LOG="${systemctl_log}"
	KPANEL_NODE_SYSTEMCTL="${systemctl_bin}"
	KPANEL_NODE_TERMINAL_CONFIG="${temporary_dir}/missing-terminal.json"
	eval "${activate_body}"
	kpanel_node_activate
)
cat >"${temporary_dir}/expected-systemctl.log" <<'EXPECTED_SYSTEMCTL'
daemon-reload
disable kejilion-node-terminal.service
stop kejilion-node-terminal.service
enable kejilion-node.service
enable kejilion-node-ssh-login.service
enable kejilion-node-update.timer
enable kejilion-node-uninstall.path
start kejilion-node-uninstall.path
start kejilion-node-ssh-login.service
start kejilion-node.service
start kejilion-node-update.timer
disable kejilion-node-file.service
stop kejilion-node-file.service
is-active kejilion-node-ssh-login.service
is-active kejilion-node.service
EXPECTED_SYSTEMCTL
cmp "${temporary_dir}/expected-systemctl.log" "${systemctl_log}"

capable_systemctl_log="${temporary_dir}/capable-systemctl.log"
capable_terminal_config="${temporary_dir}/terminal.json"
touch "${capable_terminal_config}"
(
	export KPANEL_TEST_SYSTEMCTL_LOG="${capable_systemctl_log}"
	KPANEL_NODE_SYSTEMCTL="${systemctl_bin}"
	KPANEL_NODE_TERMINAL_CONFIG="${capable_terminal_config}"
	eval "${activate_body}"
	kpanel_node_activate
)
cat >"${temporary_dir}/expected-capable-systemctl.log" <<'EXPECTED_CAPABLE_SYSTEMCTL'
daemon-reload
enable kejilion-node-terminal.service
enable kejilion-node.service
enable kejilion-node-ssh-login.service
enable kejilion-node-update.timer
enable kejilion-node-uninstall.path
start kejilion-node-uninstall.path
start kejilion-node-terminal.service
start kejilion-node-ssh-login.service
start kejilion-node.service
start kejilion-node-update.timer
is-active kejilion-node-terminal.service
enable kejilion-node-file.service
start kejilion-node-file.service
is-active kejilion-node-file.service
is-active kejilion-node-ssh-login.service
is-active kejilion-node.service
EXPECTED_CAPABLE_SYSTEMCTL
cmp "${temporary_dir}/expected-capable-systemctl.log" "${capable_systemctl_log}"

sanitized_name="$(printf '%s' 'edge_node-01 bad@name' | LC_ALL=C tr -cd '[:alnum:]_. -')"
test "${sanitized_name}" = 'edge_node-01 badname'

# Exercise the real join control flow across a post-enrollment service failure.
# The one-time token must not be consumed twice and the saved identity must
# survive so the same command can safely finish activation on the next run.
join_runtime="${temporary_dir}/join-runtime"
mkdir -p "${join_runtime}/bin"
cat >"${join_runtime}/install" <<'MOCK_INSTALL'
#!/bin/bash
target="${@: -1}"
mkdir -p "$target"
MOCK_INSTALL
cat >"${join_runtime}/systemctl" <<'MOCK_JOIN_SYSTEMCTL'
#!/bin/bash
printf '%s\n' "$*" >>"${KPANEL_TEST_JOIN_SYSTEMCTL_LOG}"
if [ "$*" = "start kejilion-node.service" ] && [ ! -f "${KPANEL_TEST_JOIN_FAIL_ONCE}" ]; then
	touch "${KPANEL_TEST_JOIN_FAIL_ONCE}"
	exit 1
fi
MOCK_JOIN_SYSTEMCTL
chmod +x "${join_runtime}/install" "${join_runtime}/systemctl"
(
	export KPANEL_TEST_JOIN_ROOT="${join_runtime}"
	export KPANEL_TEST_JOIN_SYSTEMCTL_LOG="${join_runtime}/systemctl.log"
	export KPANEL_TEST_JOIN_FAIL_ONCE="${join_runtime}/failed-once"
	eval "${activate_body}"
	eval "${join_body}"
	kpanel_node_paths() {
		KPANEL_NODE_HOME="${KPANEL_TEST_JOIN_ROOT}/home"
		KPANEL_NODE_BINARY="${KPANEL_NODE_HOME}/kejilion-node"
		KPANEL_NODE_UPDATER="${KPANEL_NODE_HOME}/update.sh"
		KPANEL_NODE_UNINSTALL_HELPER="${KPANEL_NODE_HOME}/uninstall.sh"
		KPANEL_NODE_UNINSTALL_REQUEST="/run/kejilion-node/uninstall.request"
		KPANEL_NODE_CONFIG_DIR="${KPANEL_TEST_JOIN_ROOT}/config"
		KPANEL_NODE_CONFIG="${KPANEL_NODE_CONFIG_DIR}/node.json"
		KPANEL_NODE_TERMINAL_CONFIG="${KPANEL_NODE_CONFIG_DIR}/terminal.json"
		KPANEL_NODE_SYSTEMCTL="${KPANEL_TEST_JOIN_ROOT}/systemctl"
	}
	kpanel_node_preflight() {
		KPANEL_NODE_INSTALL_BIN="${KPANEL_TEST_JOIN_ROOT}/install"
	}
	kpanel_node_ensure_account() { :; }
	kpanel_node_write_updater() {
		mkdir -p "${KPANEL_NODE_HOME}"
		cat >"${KPANEL_NODE_UPDATER}" <<'MOCK_UPDATER'
#!/bin/bash
exit 0
MOCK_UPDATER
		cat >"${KPANEL_NODE_BINARY}" <<'MOCK_NODE'
#!/bin/bash
if [ "${1:-}" = "enroll" ]; then
	printf '%s\n' enrolled >>"${KPANEL_TEST_JOIN_ROOT}/enroll.log"
	while [ "$#" -gt 0 ]; do
		if [ "$1" = "--config" ]; then
			shift
			printf '%s\n' '{"schemaVersion":1}' >"$1"
			break
		fi
		shift
	done
fi
MOCK_NODE
		chmod +x "${KPANEL_NODE_UPDATER}" "${KPANEL_NODE_BINARY}"
	}
	kpanel_node_write_units() { :; }
	kpanel_node_write_uninstall_helper() { :; }
	kpanel_node_cleanup_failed_join() { rm -rf -- "${KPANEL_NODE_HOME}" "${KPANEL_NODE_CONFIG_DIR}"; }
	chown() { :; }
	if kpanel_node_join 'kpl1.test-token'; then
		echo "first join unexpectedly succeeded despite injected activation failure" >&2
		exit 1
	fi
	test -f "${KPANEL_NODE_CONFIG}"
	kpanel_node_join 'kpl1.test-token'
	test "$(wc -l <"${KPANEL_TEST_JOIN_ROOT}/enroll.log")" -eq 1
)

echo "KPanel lightweight-node installer smoke checks passed."
