#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
script_path="${project_root}/kejilion.sh"
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
account_body="$(
	awk '
		/^kpanel_node_ensure_account\(\) \{/ { capture=1 }
		capture { print }
		capture && /^}$/ { exit }
	' "${normalized_script}"
)"
service_body="$(sed -n "/^\[Unit\]$/,/^KPANEL_NODE_SERVICE$/p" "${normalized_script}" | head -n -1)"
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
printf '%s\n' "${join_body}" | grep -F '"$KPANEL_NODE_INSTALL_BIN" -d -o root -g kejilion-node' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'useradd --system --no-create-home' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'systemd-sysusers "$sysusers_config"' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'adduser --system --group --no-create-home' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'adduser -S -D -H' >/dev/null
printf '%s\n' "${account_body}" | grep -F 'id -gn kejilion-node' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chown root:kejilion-node "$KPANEL_NODE_CONFIG"' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chmod 0640 "$KPANEL_NODE_CONFIG"' >/dev/null
grep -F '[ -d /run/systemd/system ]' "${normalized_script}" >/dev/null
grep -F 'KPANEL_NODE_INSTALL_BIN="$(type -P install 2>/dev/null || true)"' "${normalized_script}" >/dev/null
grep -F '"$KPANEL_NODE_INSTALL_BIN" -d -o root -g root' "${normalized_script}" >/dev/null
if grep -F $'\tinstall -d -o root' "${normalized_script}" >/dev/null; then
	echo "lightweight node installer is shadowed by the package install helper" >&2
	exit 1
fi
if printf '%s\n' "${join_body}" | grep -Eq 'docker|podman'; then
	echo "lightweight node installer unexpectedly depends on a container runtime" >&2
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
printf '%s\n' "${service_body}" | grep -Fx 'NoNewPrivileges=true' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'ProtectSystem=strict' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'ProtectHome=true' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'CapabilityBoundingSet=' >/dev/null
printf '%s\n' "${service_body}" | grep -Fx 'RestrictAddressFamilies=AF_UNIX AF_INET AF_INET6' >/dev/null
printf '%s\n' "${timer_body}" | grep -Fx 'OnUnitActiveSec=24h' >/dev/null
printf '%s\n' "${timer_body}" | grep -Fx 'RandomizedDelaySec=6h' >/dev/null
printf '%s\n' "${timer_body}" | grep -Fx 'Persistent=true' >/dev/null

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

echo "KPanel lightweight-node installer smoke checks passed."
