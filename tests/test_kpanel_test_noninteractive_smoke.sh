#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
source_script="${project_root}/kejilion.sh"
script_path="$(mktemp)"
fake_bin="$(mktemp -d)"
cleanup() {
	rm -f "$script_path" "$fake_bin/curl"
	rmdir "$fake_bin" 2>/dev/null || true
}
trap cleanup EXIT
sed 's/\r$//' "$source_script" >"$script_path"

bash -n "${script_path}"
grep -F 'kpanel_run_test_noninteractive() {' "${script_path}" >/dev/null
grep -F '[ "${KJ_TEST_NONINTERACTIVE:-}" = "1" ] || return 2' "${script_path}" >/dev/null
grep -F 'KPANEL_TEST_ITEM	yabs	hardware' "${script_path}" >/dev/null
grep -F 'KPANEL_TEST_ITEM	nodequality	comprehensive' "${script_path}" >/dev/null
grep -F 'https://raw.githubusercontent.com/i-abc/GB5/main/gb5-test.sh' "${script_path}" >/dev/null
if grep -F 'bash.icu/gb5' "${script_path}" >/dev/null; then
	echo "retired GB5 short URL is still exposed" >&2
	exit 1
fi
grep -F 'kpanel_run_test_noninteractive "$@"' "${script_path}" >/dev/null
grep -F 'kpanel_run_remote_bash() {' "${script_path}" >/dev/null
if sed -n '/^kpanel_run_test_noninteractive()/,/^linux_test()/p' "${script_path}" | grep -Eq '\|[[:space:]]*(ba)?sh'; then
	echo "KPanel diagnostics must download scripts before execution so PTY stdin stays interactive" >&2
	exit 1
fi

protocol_body="$(
	awk '
		/^kpanel_test_catalog\(\) \{/ { capture=1 }
		capture { print }
		/^kpanel_run_test_noninteractive\(\) \{/ { in_dispatch=1 }
		capture && in_dispatch && /^}$/ { exit }
	' "${script_path}"
)"
eval "${protocol_body}"

catalog="$(KJ_TEST_NONINTERACTIVE=1 kpanel_run_test_noninteractive list)"
item_count="$(printf '%s\n' "$catalog" | grep -c '^KPANEL_TEST_ITEM')"
category_count="$(printf '%s\n' "$catalog" | grep -c '^KPANEL_TEST_CATEGORY')"
[ "$item_count" -eq 17 ]
[ "$category_count" -eq 4 ]
printf '%s\n' "$catalog" | grep -F $'KPANEL_TEST_ITEM\tyabs\thardware\tYABS 性能测试' >/dev/null

if KJ_TEST_NONINTERACTIVE=1 kpanel_run_test_noninteractive run unknown >/dev/null 2>&1; then
	echo "unknown test selector was accepted" >&2
	exit 1
fi
if KJ_TEST_NONINTERACTIVE=0 kpanel_run_test_noninteractive list >/dev/null 2>&1; then
	echo "machine protocol ran without opt-in marker" >&2
	exit 1
fi

printf '%s\n' \
	'#!/bin/bash' \
	'while [ "$#" -gt 0 ]; do' \
	'	if [ "$1" = "-o" ]; then output="$2"; shift 2; else shift; fi' \
	'done' \
	'printf '"'"'%s\n'"'"' "printf '"'"'mock-score=123\\n'"'"'" >"$output"' \
	>"$fake_bin/curl"
chmod +x "$fake_bin/curl"
send_stats() { :; }
result="$(PATH="$fake_bin:$PATH" KJ_TEST_NONINTERACTIVE=1 kpanel_run_test_noninteractive run chatgpt)"
printf '%s\n' "$result" | grep -F 'mock-score=123' >/dev/null
printf '%s\n' "$result" | grep -F 'KPANEL_TEST_RESULT succeeded chatgpt' >/dev/null

printf '%s\n' '#!/bin/bash' 'exit 22' >"$fake_bin/curl"
set +e
failure_output="$(PATH="$fake_bin:$PATH" KJ_TEST_NONINTERACTIVE=1 kpanel_run_test_noninteractive run chatgpt 2>&1)"
failure_status=$?
set -e
[ "$failure_status" -eq 22 ]
printf '%s\n' "$failure_output" | grep -F 'KPANEL_TEST_RESULT failed chatgpt' >/dev/null

printf '%s\n' "kpanel_test_noninteractive_smoke=pass"
