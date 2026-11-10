#!/usr/bin/env bash
set -eu
root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
fixture="$(mktemp -d /tmp/kpanel-site-public-ports.XXXXXXXX)"
trap 'rm -rf -- "$fixture"' EXIT
sed -n '/^linux_ldnmp() {/,/^moltbot_menu() {/p' "$root/kejilion.sh" > "$fixture/ldnmp"
{
  echo 'run_recipe() { case "$1" in'
  awk '/^[[:space:]]*(25|26)\)/ { active=1 } active { print } active && /^[[:space:]]*;;/ { active=0 }' "$fixture/ldnmp"
  echo 'esac; }'
} > "$fixture/cases"
source "$fixture/cases"
docker() { touch "$fixture/docker-called"; }
export KJ_WEB_ACCESS_PASSWORD_FILE=synthetic
for recipe in 25 26; do
  if run_recipe "$recipe" > "$fixture/output" 2>&1; then exit 1; fi
  grep -Fq '该模板会开放应用直连端口' "$fixture/output"
  [ ! -e "$fixture/docker-called" ]
done
echo 'PASS: access password requests cannot start publicly bound application templates'
