#!/bin/bash
set -euo pipefail

project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
test_root=$(mktemp -d)
trap 'rm -rf -- "$test_root"' EXIT
mkdir -p "$test_root/fixture/jumpserver-installer-v4.10.19" "$test_root/opt"
cat > "$test_root/fixture/jumpserver-installer-v4.10.19/config-example.txt" <<'EOF'
HTTP_PORT=80
HTTPS_PORT=443
DOMAINS=
SECRET_KEY=fixture-key
EOF
cat > "$test_root/fixture/jumpserver-installer-v4.10.19/jmsctl.sh" <<'EOF'
#!/bin/bash
echo "$1" >> "$JMS_TEST_LOG"
if [[ $1 == install ]]; then
  [[ ${AUTO_INSTALL:-} == 1 ]] || exit 99
  exit "${JMS_INSTALL_STATUS:-0}"
fi
exit "${JMS_START_STATUS:-0}"
EOF
chmod +x "$test_root/fixture/jumpserver-installer-v4.10.19/jmsctl.sh"
archive=jumpserver-installer-v4.10.19.tar.gz
tar -czf "$test_root/fixture/$archive" -C "$test_root/fixture" jumpserver-installer-v4.10.19
(cd "$test_root/fixture" && sha256sum "$archive" > "$archive.sha256")
export JMS_TEST_LOG="$test_root/actions"
gh_https_url=https://
gh_proxy=https://

# Run the actual application branch, redirecting its /opt paths into a sandbox.
awk '/^[[:space:]]*60\|jms\)/ { capture=1; next }
     /^[[:space:]]*61\|libretranslate\)/ { exit }
     capture && !/^[[:space:]]*;;/ { print }' "$project_root/kejilion.sh" |
  sed -e "s|/opt|$test_root/opt|g" -e "s|3a9fb2b5256ae60eff1340cca24a1546157d09fc174244b342f38e4117418f87|$(sha256sum "${test_root}/fixture/${archive}" | cut -d ' ' -f 1)|g" > "$test_root/branch.sh"
is_valid_port() { [[ $1 =~ ^[0-9]+$ ]] && (( 10#$1 >= 1 && 10#$1 <= 65535 )); }
install() { :; }
clear() { :; }
ip_address() { ipv4_address=192.0.2.1; ipv6_address=2001:db8::1; }
check_docker_app_ip() { echo "access-port=$docker_port"; }
jmsctl() { return 37; }
curl() {
  local output=""
  while (( $# )); do
    if [[ $1 == -o ]]; then output=$2; shift; fi
    shift
  done
  [[ ${JMS_DOWNLOAD_FAIL:-0} == 0 ]] || return 1
  cp "$test_root/fixture/$(basename "$output")" "$output"
  if [[ ${JMS_CORRUPT:-0} == 1 && $output == *.tar.gz ]]; then echo corrupt >> "$output"; fi
}
docker_app_plus() {
  local bad status
  for bad in 80 443 080 0443 0 65536 abc; do
    docker_port=$bad
    if docker_app_install > "$test_root/output" 2>&1; then
      echo "FAIL: accepted port $bad"; exit 1
    fi
    [[ ! -e $JMS_TEST_LOG ]]
  done
  docker_port=18060
  JMS_DOWNLOAD_FAIL=1
  if docker_app_install > "$test_root/output" 2>&1; then exit 1; fi
  unset JMS_DOWNLOAD_FAIL
  JMS_CORRUPT=1
  if docker_app_install > "$test_root/output" 2>&1; then exit 1; fi
  unset JMS_CORRUPT
  [[ ! -e $JMS_TEST_LOG ]]
  docker_app_install > "$test_root/output" 2>&1
  local config="$test_root/opt/jumpserver/config/config.txt"
  grep -qx 'HTTP_PORT=18060' "$config"
  grep -qx 'HTTPS_PORT=' "$config"
  grep -qx 'DOMAINS=localhost:18060,127.0.0.1:18060,192.0.2.1:18060,\[2001:db8::1\]:18060' "$config"
  grep -qx 'SECRET_KEY=fixture-key' "$config"
  [[ $(cat "$JMS_TEST_LOG") == $'install\nstart' ]]
  cp "$config" "$test_root/config-before"
  if docker_app_install > "$test_root/output" 2>&1; then exit 1; fi
  cmp "$config" "$test_root/config-before"
  for stage in install start; do
    rm -f "$config" "$JMS_TEST_LOG"
    export JMS_INSTALL_STATUS=0 JMS_START_STATUS=0
    if [[ $stage == install ]]; then JMS_INSTALL_STATUS=37; else JMS_START_STATUS=37; fi
    if docker_app_install > "$test_root/output" 2>&1; then exit 1; fi
    ! grep -q '已经安装完成' "$test_root/output"
    if [[ $stage == install ]]; then [[ $(cat "$JMS_TEST_LOG") == install ]]; fi
  done
  status=0; docker_app_update > /dev/null || status=$?
  [[ $status == 1 ]]
  status=0; docker_app_uninstall > /dev/null || status=$?
  [[ $status == 1 ]]
}
run_branch() { source "$test_root/branch.sh"; }
run_branch
echo 'PASS: JumpServer custom port, config preservation, checksum and failure handling'
