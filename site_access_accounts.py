"""Account updates for Nginx password files using the shared transaction."""
from __future__ import annotations

import subprocess

from site_access_nginx import ConfigError, update_account
from site_access_transaction import replace_existing


def hash_password(password: str) -> str:
    if not isinstance(password, str):
        raise ConfigError('invalid password')
    raw = password.encode('utf-8')
    # openssl passwd -apr1 silently truncates stdin passwords after 256 bytes.
    if not raw or len(raw) > 256 or any(char in raw for char in (b'\x00', b'\r', b'\n')):
        raise ConfigError('invalid password')
    try:
        result = subprocess.run(['/usr/bin/openssl', 'passwd', '-apr1', '-stdin'],
                                input=raw + b'\n', stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'},
                                timeout=10, check=True)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ConfigError('password hashing unavailable') from exc
    try:
        return result.stdout.decode('ascii').strip()
    except UnicodeDecodeError as exc:
        raise ConfigError('password hashing failed') from exc


def edit_account(directory: str, name: str, expected_sha256: str, action: str,
                 username: str, *, password: str = '', previous_username: str | None = None,
                 hasher=hash_password, assert_context=None) -> str:
    if action not in ('add', 'update', 'delete'):
        raise ConfigError('invalid account action')
    if action == 'add' and previous_username is not None:
        raise ConfigError('unexpected previous account')
    if action == 'update' and previous_username is None:
        raise ConfigError('previous account is required')
    if action == 'delete' and (previous_username is not None or password):
        raise ConfigError('unexpected deletion arguments')
    new_hash = None if action == 'delete' else hasher(password)
    def transform(content):
        return update_account(content, username, new_hash,
                              previous_username=previous_username,
                              must_create=action == 'add')
    # Nginx reads the password file for each request. No configuration reload
    # is necessary, and no credential is passed through a command line.
    return replace_existing(directory, name, expected_sha256, transform,
                            lambda: None, lambda: None, limit=1 << 20,
                            before_exchange=assert_context)
