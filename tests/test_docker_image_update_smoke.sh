#!/usr/bin/env bash
set -euo pipefail

repo_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
script_path="${repo_root}/kejilion.sh"
tmp_dir="$(mktemp -d)"
trap 'rm -rf "$tmp_dir"' EXIT

awk '
	/^check_docker_image_update\(\) \{/ { capture=1 }
	capture { print }
	capture && /^}/ { exit }
' "$script_path" | sed 's/\r$//' >"$tmp_dir/function.sh"

mkdir -p "$tmp_dir/bin"
cat >"$tmp_dir/bin/docker" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
if [[ "$1" == "inspect" ]]; then
	printf '%s\n' '2026-07-27T00:00:00Z,docker.io/kjlion/kejilion-panel:latest,sha256:local-image'
	exit 0
fi
if [[ "$1" == "image" && "$2" == "inspect" ]]; then
	printf 'docker.io/kjlion/kejilion-panel@%s\n' "${LOCAL_DIGEST:?}"
	exit 0
fi
exit 1
EOF
cat >"$tmp_dir/bin/curl" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
url="${@: -1}"
printf '%s\n' "$url" >>"${CURL_LOG:?}"
printf '%s\n' '{"digest":"placeholder","last_updated":"2026-07-28T00:00:00Z"}'
EOF
cat >"$tmp_dir/bin/jq" <<'EOF'
#!/usr/bin/env bash
set -euo pipefail
cat >/dev/null
case "$*" in
	*'.digest // empty'*) printf '%s\n' "${REMOTE_DIGEST:?}" ;;
	*'.last_updated // empty'*) printf '%s\n' '2026-07-28T00:00:00Z' ;;
	*) exit 1 ;;
esac
EOF
chmod +x "$tmp_dir/bin/docker" "$tmp_dir/bin/curl" "$tmp_dir/bin/jq"

# shellcheck disable=SC1090
source "$tmp_dir/function.sh"
gl_huang=""
gl_bai=""
export CURL_LOG="$tmp_dir/curl.log"
export LOCAL_DIGEST="sha256:$(printf 'a%.0s' {1..64})"
export REMOTE_DIGEST="sha256:$(printf 'b%.0s' {1..64})"
PATH="$tmp_dir/bin:$PATH"

check_docker_image_update kpanel
test "$update_status" = "发现新版本!"
grep -Fx 'https://hub.docker.com/v2/repositories/kjlion/kejilion-panel/tags/latest' "$CURL_LOG" >/dev/null
if grep -q 'ipinfo.io' "$CURL_LOG"; then
	printf '%s\n' "update detection still depends on IP geolocation" >&2
	exit 1
fi

: >"$CURL_LOG"
export REMOTE_DIGEST="$LOCAL_DIGEST"
check_docker_image_update kpanel
test -z "$update_status"

printf '%s\n' "docker_image_update_smoke=pass"
