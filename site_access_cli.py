"""Fixed, structured adapter for website access-password operations.

Only JSON on stdin carries credentials. No password is accepted in argv or the
environment. The caller passes resource fingerprints from the latest read.
"""
from __future__ import annotations

import json
import os
import re
import sys

from site_access_accounts import edit_account
from site_access_config import edit_config, nginx_command
from site_access_nginx import ConfigError, effective_auth, parse, select_context
from site_access_rules import add_rule, nginx_worker_group, check_worker_read, quarantine_created_config, nginx_global_config
from site_access_transaction import Conflict, TransactionError, _matches, _read, digest, rename_noreplace


MAX_REQUEST = 16384
MOUNTS = {'/etc/nginx/conf.d/': 'conf.d', '/etc/nginx/certs/': 'certs', '/var/www/html/': 'html'}


def directory_beneath(rootfd, parts):
    current = os.dup(rootfd)
    try:
        for part in parts:
            if not part or part in ('.', '..') or '\x00' in part or '/' in part or '\\' in part:
                raise ConfigError('invalid path')
            following = os.open(part, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC,
                                dir_fd=current)
            os.close(current)
            current = following
        return current
    except BaseException:
        os.close(current)
        raise


def file_target(rootfd, nginx_path):
    if not isinstance(nginx_path, str) or any(c in nginx_path for c in ('\0', '$', '\\')):
        raise ConfigError('invalid password file path')
    if not nginx_path.startswith('/'):
        if not nginx_path or any(part in ('', '.', '..') for part in nginx_path.split('/')):
            raise ConfigError('invalid password file path')
        nginx_path = '/etc/nginx/' + nginx_path
    for prefix, mount in MOUNTS.items():
        if nginx_path.startswith(prefix):
            parts = nginx_path[len(prefix):].split('/')
            if not parts[-1] or parts[-1] in ('.', '..'):
                raise ConfigError('invalid password file path')
            return directory_beneath(rootfd, [mount] + parts[:-1]), parts[-1]
    raise ConfigError('password file mount unavailable')


def read_checked(dirfd, name, expected, limit):
    fd, _, data = _read(dirfd, name, limit)
    os.close(fd)
    if digest(data) != expected:
        raise Conflict('site or password file changed')
    return data


def apply_account(rootfd, request):
    required = {'operation', 'configName', 'configVersion', 'fileVersion', 'serverIndex',
                'scope', 'path', 'modifier', 'username'}
    optional = {'password', 'previousUsername'}
    if not isinstance(request, dict) or not required <= request.keys() or request.keys() - required - optional:
        raise ConfigError('invalid request fields')
    config_name = request['configName']
    if not isinstance(config_name, str) or not re.fullmatch(r'[A-Za-z0-9_.-]{1,253}\.conf', config_name):
        raise ConfigError('invalid configuration name')
    if request['operation'] not in ('add', 'update', 'delete'):
        raise ConfigError('invalid account action')
    config_dir = directory_beneath(rootfd, ['conf.d'])
    try:
        config = read_checked(config_dir, config_name, request['configVersion'], 2 << 20)
        try:
            ast = parse(config.decode('utf-8'))
        except UnicodeDecodeError as exc:
            raise ConfigError('site configuration is not UTF-8') from exc
        block = select_context(ast, request['serverIndex'], request['scope'], request['path'], request['modifier'])
        auth = effective_auth(ast, block)
        if auth is None:
            raise Conflict('authentication rule no longer exists')
        password_dir, password_name = file_target(rootfd, auth[1])
        try:
            def verify_context():
                read_checked(config_dir, config_name, request['configVersion'], 2 << 20)
            return edit_account(password_dir, password_name, request['fileVersion'], request['operation'],
                                request['username'], password=request.get('password', ''),
                                previous_username=request.get('previousUsername'), assert_context=verify_context)
        finally:
            os.close(password_dir)
    finally:
        os.close(config_dir)


def apply_rule(rootfd, request, *, validate=None, reload_config=None,
               worker_group=nginx_worker_group, verify_read=check_worker_read, global_policy=nginx_global_config):
    common = {'operation', 'configName', 'configVersion', 'scope', 'path', 'modifier'}
    action = request.get('operation') if isinstance(request, dict) else None
    needed = {'username', 'password', 'serverIndices'} if action == 'rule-add' else {'fileVersion', 'serverIndex'} if action == 'rule-delete' else set()
    if action not in ('rule-add', 'rule-delete') or request.keys() != common | needed:
        raise ConfigError('invalid rule request')
    name = request['configName']
    if not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9_.-]{1,253}\.conf', name):
        raise ConfigError('invalid configuration name')
    validate = validate or (lambda: nginx_command('-t'))
    reload_config = reload_config or (lambda: nginx_command('-s', 'reload'))
    config_dir = directory_beneath(rootfd, ['conf.d'])
    try:
        if action == 'rule-add':
            return add_rule(config_dir, name, request['configVersion'], request['serverIndices'],
                            request['scope'], request['path'], request['modifier'],
                            request['username'], request['password'], validate=validate,
                            reload_config=reload_config, worker_group=worker_group, verify_read=verify_read,
                            global_policy=global_policy)
        data = read_checked(config_dir, name, request['configVersion'], 2 << 20)
        try:
            tree = parse(data.decode('utf-8'))
        except UnicodeDecodeError as exc:
            raise ConfigError('site configuration is not UTF-8') from exc
        block = select_context(tree, request['serverIndex'], request['scope'], request['path'], request['modifier'])
        auth = effective_auth(tree, block)
        if auth is None:
            raise Conflict('authentication rule no longer exists')
        password_dir, password_name = file_target(rootfd, auth[1])
        try:
            def verify_file():
                read_checked(password_dir, password_name, request['fileVersion'], 1 << 20)
            verify_file()
            return edit_config(config_dir, name, request['configVersion'], request['serverIndex'],
                               request['scope'], request['path'], request['modifier'], 'delete',
                               validate=validate, reload_config=reload_config, assert_context=verify_file)
        finally:
            os.close(password_dir)
    finally:
        os.close(config_dir)


def apply_creation(rootfd, request, *, expected_version, expected_domain, staged_name='',
                   worker_group=nginx_worker_group, verify_read=check_worker_read, global_policy=nginx_global_config):
    fields = {'operation', 'configName', 'scope', 'path', 'username', 'password'}
    if not isinstance(request, dict) or request.keys() != fields or request.get('operation') != 'create-stage':
        raise ConfigError('invalid creation request')
    name = request['configName']
    if not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9_.-]{1,253}\.conf', name):
        raise ConfigError('invalid configuration name')
    domain = name[:-5].lower()
    if domain != expected_domain or not re.fullmatch(r'[0-9a-f]{64}', expected_version):
        raise ConfigError('creation identity is invalid')
    if not re.fullmatch(r'\.site-create-[a-f0-9]{32}\.pending', staged_name):
        raise ConfigError('creation staging identity is invalid')
    source_name = staged_name
    directory = directory_beneath(rootfd, ['conf.d'])
    try:
        fd, _, data = _read(directory, source_name, 2 << 20)
        os.close(fd)
        if digest(data) != expected_version:
            raise Conflict('site configuration changed during creation')
        try:
            root = parse(data.decode('utf-8'))
        except UnicodeDecodeError as exc:
            raise ConfigError('site configuration is not UTF-8') from exc
        servers = []
        for block in root.children:
            if block.words == ['server']:
                servers.append(block)
            elif block.words == ['http']:
                servers.extend(child for child in block.children if child.words == ['server'])
        indices = []
        for index, server in enumerate(servers):
            names = [word.lower().rstrip('.') for directive in server.directives
                     if directive.words[0] == 'server_name' for word in directive.words[1:]]
            if domain in names:
                indices.append(index)
        if not indices:
            raise ConfigError('site server context unavailable')
        version = add_rule(directory, source_name, digest(data), indices, request['scope'], request['path'], '',
                           request['username'], request['password'], validate=lambda: None,
                           reload_config=lambda: None, worker_group=worker_group, verify_read=verify_read,
                           global_policy=global_policy)
        fd, info, staged = _read(directory, staged_name, 2 << 20)
        os.close(fd)
        if digest(staged) != version:
            raise Conflict('staged configuration changed')
        rename_noreplace(directory, staged_name, name)
        os.fsync(directory)
        if not _matches(directory, name, info, version, 2 << 20):
            # The published path now belongs to an external writer. Moving it
            # back would displace their changes, so leave it for inspection.
            raise Conflict('published configuration changed; inspect site')
        return version
    finally:
        os.close(directory)


def apply_quarantine(rootfd, request, *, validate=None, reload_config=None):
    if not isinstance(request, dict) or request.keys() != {'operation', 'configName', 'configVersion'} or request.get('operation') != 'quarantine':
        raise ConfigError('invalid quarantine request')
    name, version = request['configName'], request['configVersion']
    if not isinstance(name, str) or not re.fullmatch(r'[A-Za-z0-9_.-]{1,253}\.conf', name) or not isinstance(version, str) or not re.fullmatch(r'[0-9a-f]{64}', version):
        raise ConfigError('invalid quarantine identity')
    directory = directory_beneath(rootfd, ['conf.d'])
    try:
        quarantine_created_config(directory, name, version,
                                  validate=validate or (lambda: nginx_command('-t')),
                                  reload_config=reload_config or (lambda: nginx_command('-s', 'reload')))
    finally:
        os.close(directory)
    return version


def main():
    data = sys.stdin.buffer.read(MAX_REQUEST + 1)
    if len(data) > MAX_REQUEST:
        raise ConfigError('request too large')
    request = json.loads(data)
    rootfd = os.open('/home/web', os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC)
    try:
        if isinstance(request, dict) and request.get('operation') == 'create-stage':
            version = apply_creation(rootfd, request,
                                     expected_version=os.environ.get('KJ_WEB_ACCESS_CONFIG_VERSION', ''),
                                     expected_domain=os.environ.get('KJ_WEB_ACCESS_DOMAIN', ''),
                                     staged_name=os.environ.get('KJ_WEB_ACCESS_STAGED_NAME', ''))
        elif isinstance(request, dict) and request.get('operation') == 'quarantine':
            version = apply_quarantine(rootfd, request)
        elif isinstance(request, dict) and request.get('operation') in ('rule-add', 'rule-delete'):
            version = apply_rule(rootfd, request)
        else:
            version = apply_account(rootfd, request)
    finally:
        os.close(rootfd)
    print(json.dumps({'ok': True, 'fileVersion': version}, separators=(',', ':')))


if __name__ == '__main__':
    try:
        main()
    except (ConfigError, Conflict, TransactionError, OSError, ValueError, TypeError) as error:
        # Never echo input, credentials, Nginx paths, or exception text.
        if isinstance(error, Conflict):
            code = 'resource_conflict'
        elif isinstance(error, TransactionError):
            code = 'needs_attention'
        elif isinstance(error, (ConfigError, ValueError, TypeError)):
            code = 'invalid_request'
        else:
            code = 'unavailable'
        print(json.dumps({'ok': False, 'error': code}, separators=(',', ':')))
        sys.exit(1)
