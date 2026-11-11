"""Embed the shared site-access Python sources in both standalone scripts."""
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
BEGIN = '# BEGIN GENERATED SITE ACCESS ADAPTER\n'
END = '# END GENERATED SITE ACCESS ADAPTER\n'
FILES = ('site_access_nginx.py', 'site_access_transaction.py', 'site_access_accounts.py',
         'site_access_config.py', 'site_access_rules.py', 'site_access_cli.py')


def embedded():
    lines = [BEGIN, 'kpanel_web_access_password() (\n',
             '  [ "${KJ_WEB_NONINTERACTIVE:-}" = "1" ] || return 64\n',
             '  [ "$(id -u)" = "0" ] || return 1\n',
             '  [ "$#" = "0" ] || return 64\n',
             '  local adapter_dir\n',
             '  adapter_dir=$(mktemp -d /run/kejilion-site-access.XXXXXXXX) || return 1\n',
             '  trap \'rm -rf -- "$adapter_dir"\' EXIT\n',
             '  umask 077\n']
    for name in FILES:
        delimiter = 'KPANEL_EMBEDDED_' + name.upper().replace('.', '_')
        source = (ROOT / name).read_text(encoding='utf-8')
        if delimiter in source:
            raise ValueError('heredoc delimiter occurs in source')
        lines.extend([f'  cat > "$adapter_dir/{name}" <<\'{delimiter}\'\n', source,
                      '' if source.endswith('\n') else '\n', delimiter + '\n'])
    lines += [
        '  python3 -I -c \'import runpy,sys; sys.dont_write_bytecode=True; sys.path.insert(0,sys.argv[1]); runpy.run_path(sys.argv[1]+"/site_access_cli.py",run_name="__main__")\' "$adapter_dir"\n',
        ')\n', END,
    ]
    return ''.join(lines)


def main():
    block = embedded()
    for target in (ROOT / 'kejilion.sh', ROOT / 'cn' / 'kejilion.sh'):
        text = target.read_text(encoding='utf-8')
        if text.count(BEGIN) != 1 or text.count(END) != 1:
            raise ValueError(f'expected exactly one generated block in {target}')
        start, end = text.index(BEGIN), text.index(END) + len(END)
        target.write_text(text[:start] + block + text[end:], encoding='utf-8', newline='\n')


if __name__ == '__main__':
    main()
