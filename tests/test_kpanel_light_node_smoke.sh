#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
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
printf '%s\n' "${join_body}" | grep -F 'useradd --system --no-create-home' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chown root:kejilion-node "$KPANEL_NODE_CONFIG"' >/dev/null
printf '%s\n' "${join_body}" | grep -F 'chmod 0640 "$KPANEL_NODE_CONFIG"' >/dev/null
grep -F '[ -d /run/systemd/system ]' "${normalized_script}" >/dev/null
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

echo "KPanel lightweight-node installer smoke checks passed."
