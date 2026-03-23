#!/usr/bin/env bash
set -euo pipefail

repo_root=$(cd "$(dirname "$0")/.." && pwd)
script="$repo_root/kejilion.sh"

workdir=$(mktemp -d)
trap 'rm -rf "$workdir"' EXIT
export HOME="$workdir/home"
mkdir -p "$HOME/.openclaw"

python_extract() {
python3 - "$script" <<'PY'
import re, sys
text = open(sys.argv[1], encoding='utf-8').read()
patterns = [
    r'openclaw_get_config_file\(\) \{.*?\n\t\t\}',
    r'openclaw_memory_config_file\(\) \{.*?\n\t\}',
    r'openclaw_permission_config_file\(\) \{.*?\n\t\}',
]
for pat in patterns:
    m = re.search(pat, text, re.S)
    if not m:
        raise SystemExit(f'missing pattern: {pat}')
    print(m.group(0))
    print()
PY
}

snippet="$workdir/snippet.sh"
{
  echo '#!/usr/bin/env bash'
  echo 'set -euo pipefail'
  python_extract
  cat <<'SH'
main() {
  echo "CFG=$(openclaw_get_config_file)"
  echo "MEM=$(openclaw_memory_config_file)"
  echo "PERM=$(openclaw_permission_config_file)"
}
main "$@"
SH
} > "$snippet"
chmod +x "$snippet"

assert_eq() {
  local got="$1" expected="$2" msg="$3"
  if [ "$got" != "$expected" ]; then
    echo "ASSERT FAIL: $msg"
    echo "got: $got"
    echo "exp: $expected"
    exit 1
  fi
}

user_cfg="$HOME/.openclaw/openclaw.json"
root_cfg="$workdir/root/.openclaw/openclaw.json"
mkdir -p "$(dirname "$root_cfg")"

out=$("$snippet")
assert_eq "$(printf '%s\n' "$out" | sed -n '1p')" "CFG=$user_cfg" 'default config path should be user path'
assert_eq "$(printf '%s\n' "$out" | sed -n '2p')" "MEM=$user_cfg" 'memory config path should follow helper'
assert_eq "$(printf '%s\n' "$out" | sed -n '3p')" "PERM=$user_cfg" 'permission config path should follow helper'

printf '{}\n' > "$root_cfg"
rm -f "$user_cfg"
out=$("$snippet")
assert_eq "$(printf '%s\n' "$out" | sed -n '1p')" "CFG=$user_cfg" 'non-root should not silently fallback to root config'
assert_eq "$(printf '%s\n' "$out" | sed -n '2p')" "MEM=$user_cfg" 'memory config should stay in user path for non-root'
assert_eq "$(printf '%s\n' "$out" | sed -n '3p')" "PERM=$user_cfg" 'permission config should stay in user path for non-root'

mkdir -p "$(dirname "$user_cfg")"
printf '{"user":true}\n' > "$user_cfg"
out=$("$snippet")
assert_eq "$(printf '%s\n' "$out" | sed -n '1p')" "CFG=$user_cfg" 'user config should take precedence'

echo 'PASS: openclaw config path resolution smoke'
