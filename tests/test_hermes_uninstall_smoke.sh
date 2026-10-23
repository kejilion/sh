#!/bin/bash
set -euo pipefail
root=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
scratch=$(mktemp -d)
trap 'rm -rf -- "$scratch"' EXIT
export HOME="$scratch/home"
mkdir -p "$HOME"
# Only load definitions; never enter the interactive menu or use a real install.
registry="$scratch/appno.txt"
source <(sed -e '/^# 主循环/,$d' -e "s@/home/docker/appno.txt@$registry@g" "$root/hermes_manager.sh")
base_path=/usr/bin:/bin
export PATH="$base_path"

make_cli() {
    mkdir -p "$(dirname "$1")"
    cat > "$1" <<'CLI'
#!/bin/bash
printf '%s\n' "$*" >> "$HOME/calls"
case "${FIXTURE_RESULT:-success}" in
    fail) exit 42 ;;
    cancel) exit 0 ;;
    success) rm -- "$0" ;;
esac
CLI
    chmod +x "$1"
}

# Reproduce non-login shells: none of the fixture locations is on PATH.
for relative in .local/bin .hermes/hermes-agent/venv/bin \
    .hermes/hermes-agent/.venv/bin .hermes/hermes-agent/.hermes/bin; do
    (
        make_cli "$HOME/$relative/hermes"
        check_installed
        test "$(command -v hermes)" = "$HOME/$relative/hermes"
        rm -- "$HOME/$relative/hermes"
    )
done
echo 'PASS: launcher, legacy venv, .venv and current source launcher'

(
    export HERMES_HOME="$scratch/custom home"
    make_cli "$HERMES_HOME/hermes-agent/.hermes/bin/hermes"
    check_installed
    test "$(command -v hermes)" = "$HERMES_HOME/hermes-agent/.hermes/bin/hermes"
    rm -- "$(command -v hermes)"
)
(
    export HERMES_INSTALL_DIR="$scratch/custom install"
    make_cli "$HERMES_INSTALL_DIR/.venv/bin/hermes"
    check_installed
    test "$(command -v hermes)" = "$HERMES_INSTALL_DIR/.venv/bin/hermes"
    rm -- "$(command -v hermes)"
)
echo 'PASS: custom home/install paths with spaces'

(
    make_cli "$scratch/existing/hermes"
    make_cli "$HOME/.local/bin/hermes"
    export PATH="$scratch/existing:$base_path"
    check_installed
    test "$(command -v hermes)" = "$scratch/existing/hermes"
    rm -- "$scratch/existing/hermes" "$HOME/.local/bin/hermes"
)
echo 'PASS: existing PATH command takes priority'

# The loaded definitions use only the temporary application registry above.
reset_case() {
    export PATH="$base_path"
    printf '114\n115\n1150\n116\n' > "$registry"
    : > "$HOME/calls"
    make_cli "$HOME/.local/bin/hermes"
}
assert_registered() { grep -qxF 115 "$registry"; }

reset_case
export FIXTURE_RESULT=fail
if uninstall_hermes <<< y > "$scratch/fail.log"; then exit 1; fi
assert_registered
grep -qxF uninstall "$HOME/calls"
grep -q '卸载失败' "$scratch/fail.log"
echo 'PASS: failed uninstall preserves registry'

reset_case
export FIXTURE_RESULT=cancel
if uninstall_hermes <<< y > "$scratch/cancel.log"; then exit 1; fi
assert_registered
grep -q '仍检测到 Hermes 命令' "$scratch/cancel.log"
echo 'PASS: native cancellation with exit zero preserves registry'

reset_case
uninstall_hermes <<< n > /dev/null
assert_registered
test ! -s "$HOME/calls"
echo 'PASS: outer cancellation never calls uninstall'

reset_case
export FIXTURE_RESULT=success
uninstall_hermes <<< y > "$scratch/success.log"
if assert_registered; then exit 1; fi
grep -qxF 1150 "$registry"
grep -qxF 114 "$registry"
grep -qxF 116 "$registry"
grep -q 'Hermes 已卸载' "$scratch/success.log"
echo 'PASS: successful uninstall removes only exact registry entry'

printf '115\n' > "$registry"
touch "$HOME/.hermes/config.yaml"
if uninstall_hermes <<< y > "$scratch/missing.log"; then exit 1; fi
assert_registered
grep -q '未找到可用的 Hermes 命令' "$scratch/missing.log"
echo 'PASS: residual data alone does not count as an executable install'

# Menu/version queries must not initialize the CLI or its Python dependencies.
make_cli "$HOME/.local/bin/hermes"
: > "$HOME/calls"
source_dir="$HOME/.hermes/hermes-agent"
mkdir -p "$source_dir/hermes_cli"
printf '{"baseVersion": "1.2.3"}\n' > "$source_dir/install-stamp.json"
test "$(get_version)" = 'Hermes Agent v1.2.3'
rm -- "$source_dir/install-stamp.json"
printf '__version__ = "0.13.0"\n' > "$source_dir/hermes_cli/__init__.py"
test "$(get_version)" = 'Hermes Agent v0.13.0'
printf "__version__ = '0.14.0'\n" > "$source_dir/hermes_cli/__init__.py"
test "$(get_version)" = 'Hermes Agent v0.14.0'
rm -- "$source_dir/hermes_cli/__init__.py"
metadata_dir="$source_dir/.venv/lib/python3.11/site-packages/hermes_agent-0.15.0.dist-info"
mkdir -p "$metadata_dir"
printf 'Name: hermes-agent\nVersion: 0.15.0\n' > "$metadata_dir/METADATA"
test "$(get_version)" = 'Hermes Agent v0.15.0'
rm -- "$metadata_dir/METADATA"
test "$(get_version)" = '未知'
test ! -s "$HOME/calls"
echo 'PASS: stamp, legacy source and package metadata without CLI startup'

mkdir -p "$scratch/bin" "$HOME/.cache/hermes-manager"
export PATH="$scratch/bin:$HOME/.local/bin:$base_path"
printf 'v1.3.0\n' > "$HOME/.cache/hermes-manager/hermes-agent-latest-version"
printf '{"baseVersion": "1.2.3"}\n' > "$source_dir/install-stamp.json"
cat > "$scratch/bin/systemctl" <<'SERVICE'
#!/bin/bash
sleep "${FIXTURE_SERVICE_DELAY:-0}"
echo active
SERVICE
printf '#!/bin/bash\nexit 1\n' > "$scratch/bin/pgrep"
chmod +x "$scratch/bin/systemctl" "$scratch/bin/pgrep"
clear() { :; }
(show_menu <<< 0) > "$scratch/menu.log"
grep -q '运行中.*有新版本 V1.3.0' "$scratch/menu.log"
grep -q '当前版本 : Hermes Agent v1.2.3' "$scratch/menu.log"
test ! -s "$HOME/calls"
echo 'PASS: full menu preserves status/update notice without invoking CLI'

export FIXTURE_SERVICE_DELAY=5
timeout 3s bash -c 'source <(sed '\''/^# 主循环/,$d'\'' "$1"); get_gateway_status' _ "$root/hermes_manager.sh" > "$scratch/timeout.log"
grep -q '已停止' "$scratch/timeout.log"
echo 'PASS: unresponsive service manager is bounded and uses process fallback'
