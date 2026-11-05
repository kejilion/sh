"""Add and remove authentication rules on concrete Nginx contexts."""
from __future__ import annotations

import os
import re
import secrets
import subprocess

from site_access_accounts import hash_password
from site_access_config import edit_config_many
from site_access_nginx import ConfigError, context_chain, parse, select_context, update_account
from site_access_transaction import Conflict, TransactionError, _matches, _read, _same_inode, digest, rename_noreplace


def nginx_worker_group():
    try:
        result = subprocess.run(['/usr/bin/docker', 'exec', 'nginx', 'id', '-g', 'nginx'],
                                stdout=subprocess.PIPE, stderr=subprocess.DEVNULL,
                                env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'},
                                timeout=10, check=True)
        if not re.fullmatch(rb'[0-9]{1,10}\n?', result.stdout):
            raise ConfigError('Nginx worker group unavailable')
        return int(result.stdout)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ConfigError('Nginx worker group unavailable') from exc


def check_worker_read(nginx_path):
    try:
        subprocess.run(['/usr/bin/docker', 'exec', '-u', 'nginx', 'nginx',
                        'sh', '-c', ': < "$1"', 'sh', nginx_path],
                       stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL,
                       env={'PATH': '/usr/bin:/bin', 'LC_ALL': 'C'},
                       timeout=10, check=True)
    except (OSError, subprocess.SubprocessError) as exc:
        raise ConfigError('Nginx worker cannot read password file') from exc


def _no_config_references(dirfd, filename):
    names = os.listdir(dirfd)
    if len(names) > 4096:
        return False
    total = 0
    for name in names:
        if not (name.endswith('.conf') or name.endswith('.pending')):
            continue
        try:
            fd, _, data = _read(dirfd, name, 2 << 20)
            os.close(fd)
        except (OSError, RuntimeError):
            return False
        total += len(data)
        if total > 8 << 20 or filename.encode() in data:
            return False
    return True


def is_https_redirect_only(server):
    """Identify only unconditional server-level redirects to HTTPS."""
    returns = [d.words for d in server.directives if d.words[0] == 'return']
    return (len(returns) == 1 and len(returns[0]) == 3
            and returns[0][1] in ('301', '302', '307', '308')
            and returns[0][2].lower().startswith('https://')
            and not any(d.words[0] == 'rewrite' for d in server.directives)
            and not any(child.words and child.words[0] == 'if' for child in server.children))


def add_rule(confdir: int, config_name: str, config_version: str, server_index: int,
             scope: str, location: str, modifier: str, username: str, password: str,
             *, validate, reload_config, worker_group=nginx_worker_group,
             verify_read=check_worker_read, hasher=hash_password):
    fd, _, source = _read(confdir, config_name, 2 << 20)
    os.close(fd)
    if digest(source) != config_version:
        raise Conflict('site configuration changed')
    try:
        root = parse(source.decode('utf-8'))
    except UnicodeDecodeError as exc:
        raise ConfigError('site configuration is not UTF-8') from exc
    indices = [server_index] if isinstance(server_index, int) and not isinstance(server_index, bool) else server_index
    if not isinstance(indices, list) or not indices or len(indices) > 64 or len(set(indices)) != len(indices):
        raise ConfigError('invalid server list')
    indices = [index for index in indices if not is_https_redirect_only(select_context(root, index, 'server'))]
    if not indices:
        raise ConfigError('site has no content server to protect')
    for index in indices:
        server = select_context(root, index, 'server')
        target = select_context(root, index, scope, location, modifier)
        if any(d.words[0] in ('auth_basic', 'auth_basic_user_file') for d in target.directives):
            raise ConfigError('a password rule already exists in this context')
        # Nginx executes unconditional return before Basic Auth; satisfy any
        # can also make a password optional. Never report these as protection.
        contexts = context_chain(root, target)
        if target is server:
            contexts += [child for child in server.children if child.words == ['location', '/']]
        for context in contexts:
            if any(d.words[0] == 'return' or d.words == ['satisfy', 'any'] for d in context.directives):
                raise ConfigError('site configuration bypasses password authentication')
        # Every nested location inherits its parents' settings unless it
        # overrides them. An inherited "satisfy any" makes auth optional.
        pending = list(target.children)
        while pending:
            child = pending.pop()
            if child.words and child.words[0] == 'location':
                if any(d.words == ['satisfy', 'any'] for d in child.directives):
                    raise ConfigError('a nested location can bypass password authentication')
                pending.extend(child.children)
    content = update_account(b'', username, hasher(password), must_create=True)
    gid = worker_group()
    if not isinstance(gid, int) or isinstance(gid, bool) or gid < 0 or gid > 2**32 - 2:
        raise ConfigError('Nginx worker group unavailable')
    filename = '.site-auth-' + secrets.token_hex(16) + '.passwd'
    filefd = os.open(filename, os.O_WRONLY | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC,
                     0o600, dir_fd=confdir)
    info = os.fstat(filefd)
    try:
        os.fchown(filefd, -1, gid)
        os.fchmod(filefd, 0o640)
        pending = memoryview(content)
        while pending:
            count = os.write(filefd, pending)
            if count <= 0:
                raise ConfigError('password file write failed')
            pending = pending[count:]
        os.fsync(filefd)
    except BaseException:
        os.close(filefd)
        if _same_inode(confdir, filename, info) and _no_config_references(confdir, filename):
            os.unlink(filename, dir_fd=confdir)
            os.fsync(confdir)
        raise
    else:
        os.close(filefd)
    nginx_path = '/etc/nginx/conf.d/' + filename
    try:
        os.fsync(confdir)
        verify_read(nginx_path)
        return edit_config_many(confdir, config_name, config_version, indices, scope, location,
                                modifier, 'Restricted', nginx_path,
                                validate=validate, reload_config=reload_config)
    except BaseException:
        # Remove only our exact file if no Nginx site config references it.
        # Otherwise retain it for recovery rather than delete shared data.
        if _matches(confdir, filename, info, digest(content), 1 << 20) and _no_config_references(confdir, filename):
            os.unlink(filename, dir_fd=confdir)
            os.fsync(confdir)
        raise


def quarantine_created_config(confdir, name, expected_version, *, validate, reload_config):
    """Retain a failed newly generated config outside the loaded *.conf set."""
    fd, info, source = _read(confdir, name, 2 << 20)
    os.close(fd)
    if digest(source) != expected_version:
        raise Conflict('site configuration changed before quarantine')
    retained = '.site-access-failed-' + secrets.token_hex(16) + '.saved'
    rename_noreplace(confdir, name, retained)
    os.fsync(confdir)
    if not _matches(confdir, retained, info, expected_version, 2 << 20):
        # Another writer won the race. Restore the file without replacing a
        # newer path; if restoration cannot be proven, retain the artifact.
        try:
            rename_noreplace(confdir, retained, name)
            os.fsync(confdir)
        except OSError as exc:
            raise TransactionError('site changed; configuration retained for recovery') from exc
        raise Conflict('site configuration changed before quarantine')
    try:
        os.stat(name, dir_fd=confdir, follow_symlinks=False)
    except FileNotFoundError:
        pass
    else:
        raise TransactionError('site entry reappeared while quarantining')
    try:
        validate()
        reload_config()
    except BaseException as exc:
        raise TransactionError('site config retained but Nginx reload could not be confirmed') from exc
    return retained
