#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d)"
trap 'rm -rf -- "$fixture"' EXIT

for script_path in "$project_root/kejilion.sh" "$project_root/cn/kejilion.sh"; do
	# Remap the fixed state directories to an isolated fixture; do not touch host state.
	eval "$(sed -n '/^kpanel_ldnmp_escape() {/,/^}$/p; /^kpanel_ldnmp_result() {/,/^}$/p' "$script_path" |
		sed -e "s|/var/lib/kejilion-panel/environment-jobs/|$fixture/legacy/|g" \
			-e "s|/home/docker/kpanel/data/agent/environment-jobs/|$fixture/app/|g")"
	mkdir -p "$fixture/legacy" "$fixture/app" "$fixture/outside"
	for directory in legacy app; do
		export KJ_LDNMP_RECEIPT="$fixture/$directory/test.receipt"
		for status in succeeded failed needs_attention; do
			output="$(kpanel_ldnmp_result "$status" install 'result "quoted"')"
			if [ ! -f "$KJ_LDNMP_RECEIPT" ]; then
				printf 'FAIL: missing %s receipt (%s)\n' "$directory" "$script_path" >&2
				exit 1
			fi
			[ "$(cat "$KJ_LDNMP_RECEIPT")" = "${output#KPANEL_LDNMP_RESULT }" ]
			grep -F "\"status\":\"$status\"" "$KJ_LDNMP_RECEIPT" >/dev/null
			[ -z "$(find "$fixture/$directory" -name '*.tmp.*' -print)" ]
		done
	done

	export KJ_LDNMP_RECEIPT="$fixture/outside/test.receipt"
	kpanel_ldnmp_result succeeded install rejected >/dev/null
	[ ! -e "$KJ_LDNMP_RECEIPT" ]
	export KJ_LDNMP_RECEIPT="$fixture/app/missing/test.receipt"
	if kpanel_ldnmp_result succeeded install missing >/dev/null 2>&1; then
		echo 'FAIL: receipt write failure was ignored' >&2; exit 1
	fi
	unset KJ_LDNMP_RECEIPT
	kpanel_ldnmp_result succeeded install interactive >/dev/null
done

printf '%s\n' 'kpanel_ldnmp_receipt=pass'
