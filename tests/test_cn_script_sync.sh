#!/bin/bash
set -euo pipefail

project_root="${PROJECT_ROOT:-$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)}"
temporary_dir="$(mktemp -d)"
trap 'rm -rf -- "${temporary_dir}"' EXIT

normalize_script() {
	local source_path="$1" target_path="$2"
	sed -e 's/\r$//' \
		-e 's/^canshu="default"$/canshu="REGION"/' \
		-e 's/^canshu="CN"$/canshu="REGION"/' \
		"${source_path}" >"${target_path}"
}

normalize_script "${project_root}/kejilion.sh" "${temporary_dir}/root.sh"
normalize_script "${project_root}/cn/kejilion.sh" "${temporary_dir}/cn.sh"

bash -n "${temporary_dir}/root.sh"
bash -n "${temporary_dir}/cn.sh"

if ! cmp -s "${temporary_dir}/root.sh" "${temporary_dir}/cn.sh"; then
	echo "FAIL: cn/kejilion.sh must match kejilion.sh except for canshu region value" >&2
	diff -u "${temporary_dir}/root.sh" "${temporary_dir}/cn.sh" || true
	exit 1
fi

echo "PASS: root and cn scripts are synchronized"
