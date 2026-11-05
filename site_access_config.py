"""Apply Basic Auth directives without rewriting the surrounding Nginx site."""
from __future__ import annotations

import subprocess

from site_access_nginx import ConfigError, parse, replace_auth, select_context
from site_access_transaction import replace_existing


def edit_config_many(directory: str, name: str, expected_sha256: str, server_indices: list[int],
                     scope: str, location: str, modifier: str, realm: str, user_file: str,
                     *, validate, reload_config, assert_context=None) -> str:
    if not server_indices or len(server_indices) > 64 or len(set(server_indices)) != len(server_indices):
        raise ConfigError('invalid server list')

    def transform(content):
        try:
            source = content.decode('utf-8')
        except UnicodeDecodeError as exc:
            raise ConfigError('site configuration is not UTF-8') from exc
        tree = parse(source)
        targets = [select_context(tree, index, scope, location, modifier) for index in server_indices]
        for target in targets:
            if any(d.words[0] in ('auth_basic', 'auth_basic_user_file') for d in target.directives):
                raise ConfigError('a password rule already exists in this context')
        for target in sorted(targets, key=lambda block: block.start, reverse=True):
            source = replace_auth(source, target, realm, user_file, enforce_satisfy_all=True)
        parse(source)
        return source.encode('utf-8')

    return replace_existing(directory, name, expected_sha256, transform, validate, reload_config,
                            before_exchange=assert_context)


def edit_config(directory: str, name: str, expected_sha256: str, server_index: int,
                scope: str, location: str, modifier: str, action: str,
                *, realm: str = '', user_file: str = '', validate, reload_config, assert_context=None) -> str:
    if action not in ('set', 'delete'):
        raise ConfigError('invalid configuration action')
    if action == 'delete' and (realm or user_file):
        raise ConfigError('unexpected deletion arguments')

    def transform(content):
        try:
            source = content.decode('utf-8')
        except UnicodeDecodeError as exc:
            raise ConfigError('site configuration is not UTF-8') from exc
        block = select_context(parse(source), server_index, scope, location, modifier)
        direct_auth = [item for item in block.directives
                       if item.words[0] in ('auth_basic', 'auth_basic_user_file')]
        if action == 'delete' and not direct_auth:
            raise ConfigError('no direct authentication rule exists in this context')
        result = replace_auth(source, block, realm if action == 'set' else None,
                              user_file if action == 'set' else None)
        parse(result)
        return result.encode('utf-8')

    return replace_existing(directory, name, expected_sha256, transform, validate, reload_config,
                            before_exchange=assert_context)


def nginx_command(*arguments):
    """Only fixed commands on the script's existing nginx container."""
    try:
        subprocess.run(['/usr/bin/docker', 'exec', 'nginx', 'nginx', *arguments],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'},
                       timeout=30, check=True)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ConfigError('Nginx validation or reload failed') from exc


def apply_config(directory: str, name: str, expected_sha256: str, server_index: int,
                 scope: str, location: str, modifier: str, action: str,
                 *, realm: str = '', user_file: str = '') -> str:
    return edit_config(directory, name, expected_sha256, server_index, scope, location, modifier,
                       action, realm=realm, user_file=user_file,
                       validate=lambda: nginx_command('-t'),
                       reload_config=lambda: nginx_command('-s', 'reload'))
