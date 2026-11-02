#!/usr/bin/env python3
"""Keep root/CN bootstrap byte-identical; does not publish or sign anything."""
from pathlib import Path
import argparse

root=Path(__file__).resolve().parents[1]
source=(root/'scripts/waf_runtime.py').read_text(encoding='utf-8')
wrappers='''shared_waf_python() {
    local interpreter
    for interpreter in python3 python3.13 python3.12 python3.11; do
        if command -v "$interpreter" >/dev/null 2>&1 && "$interpreter" -I -c 'import sys; raise SystemExit(sys.version_info < (3,11))' >/dev/null 2>&1; then
            WAF_PYTHON=$(command -v "$interpreter"); return 0
        fi
    done
    echo "WAF 配置工具需要 Python 3.11+" >&2; return 1
}

shared_waf_runtime() {
    shared_waf_python || return 1
    "$WAF_PYTHON" -I - /home/web "${gh_proxy:-https://}" "$@" 3<&0 <<'WAF_RUNTIME'
'''+source+'''WAF_RUNTIME
}

shared_waf_prepare() {
    shared_waf_python || return 1
    WAF_DIRECTORY=$(shared_waf_runtime prepare) || return 1
}

shared_waf_cached() {
    shared_waf_python || return 1
    WAF_DIRECTORY=$(shared_waf_runtime cached) || return 1
}

shared_waf() {
    case "${1:-}" in
        package-check|package-update|package-status|package-rollback|package-recover)
            [ "$#" -eq 1 ] || { echo "共享包命令不接受额外参数" >&2; return 2; }
            shared_waf_runtime "$1" ;;
        status|ban-status|plan|apply|configure|doctor|rollback|refresh-ips|retire-jails|existing-filters|rotation|trust-cloudflare|ban-preflight|ban-install|ban-clear|ban-remove|cf-on|cf-off)
            shared_waf_runtime run "$@" ;;
        *) echo "用法: k web waf <action>；共享包更新: k web waf package-update" >&2; return 2 ;;
    esac
}

'''
parser=argparse.ArgumentParser();parser.add_argument('--check',action='store_true');args=parser.parse_args()
for path in (root/'kejilion.sh',root/'cn/kejilion.sh'):
    text=path.read_text(encoding='utf-8')
    start=text.index('shared_waf_python() {') if 'shared_waf_python() {' in text else text.index('shared_waf_prepare() {')
    end=text.index('shared_waf_refresh() {',start)
    updated=text[:start]+wrappers+text[end:]
    if args.check:
        if text!=updated:raise SystemExit('Embedded runtime out of date: '+str(path))
    else:
        with path.open('w',encoding='utf-8',newline='\n') as stream:stream.write(updated)
