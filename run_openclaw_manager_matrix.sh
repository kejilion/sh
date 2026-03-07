#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

IMAGES=(
  "debian:12"
  "debian:13"
  "ubuntu:22.04"
  "ubuntu:24.04"
  "rockylinux:9"
  "almalinux:9"
  "fedora:41"
)

install_cmd() {
  case "$1" in
    debian:*|ubuntu:*)
      echo 'apt-get update -y >/dev/null && DEBIAN_FRONTEND=noninteractive apt-get install -y bash jq grep sed coreutils >/dev/null'
      ;;
    rockylinux:*|almalinux:*|fedora:*)
      echo 'dnf install -y bash jq grep sed coreutils >/dev/null'
      ;;
    *)
      return 1
      ;;
  esac
}

for img in "${IMAGES[@]}"; do
  echo "===== $img ====="
  cmd=$(install_cmd "$img")
  if docker run --rm -v "$PWD":/src -w /src "$img" bash -lc "$cmd && bash -n kejilion.sh && ./tests_openclaw_manager_smoke.sh"; then
    echo "RESULT $img OK"
  else
    echo "RESULT $img FAIL"
  fi
  echo
 done
