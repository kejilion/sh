#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_script="${KEJILION_SCRIPT_PATH:-${project_root}/kejilion.sh}"
temporary="$(mktemp -d)"
trap 'rm -rf -- "$temporary"' EXIT
script_path="$temporary/kejilion.sh"
sed 's/\r$//' "$source_script" > "$script_path"

bash -n "$script_path"
grep -Fqx 'KPANEL_SYSTEM_TUNING_PROTOCOL_VERSION="1"' "$script_path"
[ "$(grep -Fxc 'KPANEL_SYSTEM_TUNING_PROTOCOL_VERSION="1"' "$script_path")" -eq 1 ]
grep -Fqx 'KPANEL_SYSTEM_TUNING_MIRROR_COMMIT="649e948763042e485e411be540d21c32cface1c1"' "$script_path"
grep -Fqx 'KPANEL_SYSTEM_TUNING_MIRROR_SHA256="2e3b78a460f10ef291f30e3cbf3d3b28a9521d6615364f11b36e4a70ec97d18d"' "$script_path"
grep -Fqx 'KPANEL_SYSTEM_TUNING_NETWORK_COMMIT="e9c3078eb516b05f9df6d2a9294cf3b226ca02bd"' "$script_path"
grep -Fqx 'KPANEL_SYSTEM_TUNING_NETWORK_SHA256="94f86598805b7a8155f444f35a446df4657985ef81b25f96f7799aa465033bbb"' "$script_path"
grep -F '[ "${KJ_SYSTEM_TUNING_NONINTERACTIVE:-}" = 1 ] ||' "$script_path" >/dev/null
grep -F 'kpanel_system_tuning_dispatch "$@"' "$script_path" >/dev/null

functions="$(awk '
	/^KPANEL_SYSTEM_TUNING_PROTOCOL_VERSION=/ { capture=1 }
	/^f2b_sshd\(\) \{/ { exit }
	capture { print }
' "$script_path")"
eval "$functions"

kpanel_system_resource_zero_version() { printf '%064d\n' 0; }
: > "$temporary/ready-items"
kpanel_system_tuning_item_ready() { grep -Fxq "$1" "$temporary/ready-items"; }
kpanel_system_tuning_run_item() { printf '%s\n' "$1" >> "$temporary/run-items"; printf '%s\n' "$1" >> "$temporary/ready-items"; }

status_output="$(kpanel_system_tuning_emit ok)"
grep -F 'KPANEL_SYSTEM_TUNING_STATUS=ok' <<< "$status_output" >/dev/null
[ "$(grep -c '^KPANEL_SYSTEM_TUNING_ITEM=' <<< "$status_output")" -eq 12 ]
for item in system-update system-cleanup swap-1g ssh-port-5522 ssh-defense firewall-open-all bbr timezone-shanghai dns-auto ipv4-preferred basic-tools kernel-auto; do
	grep -F "KPANEL_SYSTEM_TUNING_ITEM=$item:pending" <<< "$status_output" >/dev/null
	kpanel_system_tuning_valid_item "$item"
done
version="$(grep '^KPANEL_SYSTEM_TUNING_VERSION=' <<< "$status_output" | cut -d= -f2)"
[[ "$version" =~ ^[0-9a-f]{64}$ ]]
! kpanel_system_tuning_valid_item arbitrary-command

apply_output="$(kpanel_system_tuning_apply_item bbr)"
grep -F 'KPANEL_SYSTEM_TUNING_STATUS=applied' <<< "$apply_output" >/dev/null
grep -F 'KPANEL_SYSTEM_TUNING_SELECTED=bbr' <<< "$apply_output" >/dev/null
grep -F 'KPANEL_SYSTEM_TUNING_ITEM=bbr:ready' <<< "$apply_output" >/dev/null
grep -Fx bbr "$temporary/run-items" >/dev/null

unchanged_output="$(kpanel_system_tuning_apply_item bbr)"
grep -F 'KPANEL_SYSTEM_TUNING_STATUS=unchanged' <<< "$unchanged_output" >/dev/null
[ "$(grep -Fxc bbr "$temporary/run-items")" -eq 1 ]

kpanel_system_tuning_run_item() { return 1; }
if kpanel_system_tuning_apply_item ssh-defense > "$temporary/failure.out" 2>/dev/null; then
	echo "failed item unexpectedly succeeded" >&2
	exit 1
fi
grep -F 'KPANEL_SYSTEM_TUNING_STATUS=needs-attention' "$temporary/failure.out" >/dev/null
grep -F 'KPANEL_SYSTEM_TUNING_SELECTED=ssh-defense' "$temporary/failure.out" >/dev/null

printf 'fixture\n' > "$temporary/source"
source_hash="$(sha256sum "$temporary/source" | awk '{print $1}')"
curl() {
	while [ "$#" -gt 0 ]; do
		[ "$1" = --output ] && { cp -- "$temporary/source" "$2"; return; }
		shift
	done
	return 1
}
kpanel_system_tuning_download_verified https://example.invalid/source "$source_hash" "$temporary/downloaded"
if kpanel_system_tuning_download_verified https://example.invalid/source "$(kpanel_system_resource_zero_version)" "$temporary/rejected"; then
	echo "wrong external source digest unexpectedly accepted" >&2
	exit 1
fi

printf '%s\n' 'kpanel_system_tuning_noninteractive_smoke=pass'
