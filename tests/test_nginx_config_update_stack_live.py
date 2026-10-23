"""Opt-in real PHP-FPM/MySQL/Redis cold-backup and rollback integration test."""
import json
import os
from pathlib import Path
import tempfile
import time
import subprocess
import unittest
import urllib.request
import uuid
from unittest.mock import patch

from test_nginx_config_update import updater, template


@unittest.skipUnless(os.environ.get('KJ_NGINX_UPDATE_STACK_LIVE') == '1', 'opt-in isolated Docker stack')
class StackUpdateTests(unittest.TestCase):
    def test_real_stack_success_and_data_rollback(self):
        real = updater.command
        name = 'kj-stack-update-' + uuid.uuid4().hex[:12]
        base = tempfile.TemporaryDirectory(prefix=name + '-', dir='/root')
        root = Path(base.name)
        names = {service: name + '-' + service for service in ('nginx', 'php', 'mysql', 'redis')}
        compose = ['docker', 'compose', '--project-directory', str(root), '-f', str(root / 'docker-compose.yml')]
        candidate_image = name + ':candidate'
        created_image = False
        mode = {'value': 'initial'}
        from_images = {'nginx': os.environ.get('KJ_STACK_FROM_NGINX_IMAGE', 'nginx:1.29-alpine'),
                       'mysql': os.environ.get('KJ_STACK_FROM_MYSQL_IMAGE', 'mysql:8.4'),
                       'redis': os.environ.get('KJ_STACK_FROM_REDIS_IMAGE', 'redis:7-alpine')}
        to_images = {service: os.environ.get('KJ_STACK_TO_' + service.upper() + '_IMAGE', image) for service, image in from_images.items()}
        try:
            for folder in ('conf.d', 'stream.d', 'certs', 'html', 'mysql'):
                (root / folder).mkdir(mode=0o755)
            real('openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', '-subj', '/CN=localhost',
                 '-keyout', str(root / 'certs/default_server.key'), '-out', str(root / 'certs/default_server.crt'))
            for relative, source in (('nginx.conf', 'nginx10.conf'), ('conf.d/default.conf', 'default10.conf'), ('conf.d/map.conf', 'map.conf')):
                (root / relative).write_text(template(updater.LEGACY, source))
            (root / 'html/index.php').write_text('''<?php
$db = new mysqli("mysql", "root", "fixture-only-password", "fixture");
$value = $db->query("SELECT value FROM marker")->fetch_row()[0];
$redis = fsockopen("redis", 6379, $errno, $errstr, 3);
fwrite($redis, "GET fixture-marker\\r\\n");
fgets($redis);
$cached = trim(fgets($redis));
echo "stack-php-ok:$value:$cached";
?>''')
            (root / 'html/index.php').chmod(0o644)
            site = 'server { listen 80; server_name stack.example; root /var/www/html; location / { include fastcgi_params; fastcgi_param SCRIPT_FILENAME /var/www/html/index.php; fastcgi_pass unix:/run/php/php-fpm.sock; } }\n'
            (root / 'conf.d/stack.conf').write_text(site)
            volumes = {'php-socket': {'driver': 'local', 'driver_opts': {'type': 'tmpfs', 'device': 'tmpfs', 'o': 'size=64m'}},
                       'redis-data': {}}
            model = {'name': name, 'services': {
                'nginx': {'image': from_images['nginx'], 'container_name': names['nginx'], 'ports': ['127.0.0.1::80'],
                          'volumes': [str(root / source) + ':' + target for source, target in (
                              ('nginx.conf', '/etc/nginx/nginx.conf'), ('conf.d', '/etc/nginx/conf.d'),
                              ('stream.d', '/etc/nginx/stream.d'), ('certs', '/etc/nginx/certs'), ('html', '/var/www/html'))] + ['php-socket:/run/php']},
                'php': {'image': 'kjlion/php:fpm-alpine', 'container_name': names['php'],
                        'volumes': [str(root / 'html') + ':/var/www/html', 'php-socket:/run/php']},
                'mysql': {'image': from_images['mysql'], 'container_name': names['mysql'], 'restart': 'always',
                          'environment': {'MYSQL_ROOT_PASSWORD': 'fixture-only-password', 'MYSQL_ROOT_HOST': '%'},
                          'volumes': [str(root / 'mysql') + ':/var/lib/mysql'],
                          'healthcheck': {'test': ['CMD', 'mysqladmin', 'ping', '-h', 'localhost', '-uroot', '-pfixture-only-password'],
                                          'interval': '1s', 'timeout': '3s', 'retries': 90}},
                'redis': {'image': from_images['redis'], 'container_name': names['redis'], 'restart': 'always', 'volumes': ['redis-data:/data']}},
                     'volumes': volumes}
            (root / 'docker-compose.yml').write_text(json.dumps(model))
            real(*compose, 'up', '-d', '--wait', '--wait-timeout', '150')
            real('docker', 'exec', names['php'], 'sh', '-c',
                 "mkdir -p /run/php; chmod 777 /run/php; sed -i '/^listen =/d' /usr/local/etc/php-fpm.d/www.conf; "
                 "sed -i '1i [global]\\ndaemonize = no' /usr/local/etc/php-fpm.d/www.conf; "
                 "printf '\nlisten = /run/php/php-fpm.sock\nlisten.owner = www-data\nlisten.group = www-data\nlisten.mode = 0777\n' >> /usr/local/etc/php-fpm.d/www.conf; "
                 'rm -f /usr/local/etc/php-fpm.d/zz-docker.conf')
            real('docker', 'restart', names['php'])
            mysql_config = root / 'custom_mysql_config.cnf'
            mysql_config.write_text('[mysqld]\nmax_connections=123\n')
            real('docker', 'cp', str(mysql_config), names['mysql'] + ':/etc/mysql/conf.d/custom_mysql_config.cnf')
            real('docker', 'restart', names['mysql'])

            def sql(query):
                return real('docker', 'exec', '-e', 'MYSQL_PWD=fixture-only-password', names['mysql'],
                            'mysql', '-uroot', '--batch', '--skip-column-names', '-e', query).strip()

            def wait_sql():
                for _ in range(90):
                    try:
                        if sql('SELECT 1') == '1':
                            return
                    except RuntimeError:
                        pass
                    time.sleep(1)
                self.fail('MySQL failed to accept real SQL')

            def redis(*args):
                return real('docker', 'exec', names['redis'], 'redis-cli', '--raw', *args).strip()

            def http(expected=b'stack-php-ok:baseline:baseline'):
                binding = real(*compose, 'port', 'nginx', '80').strip()
                request = urllib.request.Request('http://' + binding + '/', headers={'Host': 'stack.example'})
                for _ in range(30):
                    try:
                        with urllib.request.build_opener(urllib.request.ProxyHandler({})).open(request, timeout=3) as response:
                            self.assertEqual(response.read(), expected)
                            return
                    except (OSError, AssertionError):
                        time.sleep(1)
                self.fail('real Nginx to PHP-FPM socket request failed')

            wait_sql()
            sql("CREATE DATABASE fixture; CREATE TABLE fixture.marker (value VARCHAR(30)); INSERT INTO fixture.marker VALUES ('baseline')")
            self.assertEqual(sql('SELECT @@max_connections'), '123')
            redis('SET', 'fixture-marker', 'baseline')
            redis('SAVE')
            http()
            old_image = json.loads(real('docker', 'inspect', names['nginx']))[0]['Image']
            if not os.environ.get('KJ_STACK_TO_NGINX_IMAGE'):
                real('docker', 'commit', '-c', 'LABEL kejilion.updater.fixture=true', names['nginx'], candidate_image)
                created_image = True
                to_images['nginx'] = candidate_image
            for service, image in to_images.items():
                model['services'][service]['image'] = image
            (root / 'docker-compose.yml').write_text(json.dumps(model))

            def command(*args):
                if args[:3] in (('docker', 'exec', 'nginx'), ('docker', 'top', 'nginx')):
                    args = (*args[:2], names['nginx'], *args[3:])
                if args[:2] == ('docker', 'compose') and 'pull' in args:
                    return ''  # Fixture inputs were explicitly pulled and frozen before the test.
                result = real(*args)
                isolated_start = 'database-validation.json' in ' '.join(args)
                if mode['value'] == 'failure' and args[:2] == ('docker', 'compose') and 'start' in args and isolated_start:
                    mode['value'] = 'recovering'
                    for database in ('mysql', 'redis'):
                        actual = json.loads(real('docker', 'inspect', names[database]))[0]
                        self.assertEqual(actual['HostConfig']['NetworkMode'], 'none')
                        self.assertFalse(actual['HostConfig'].get('PortBindings'))
                    for application in ('nginx', 'php'):
                        self.assertFalse(json.loads(real('docker', 'inspect', names[application]))[0]['State']['Running'])
                    wait_sql()
                    sql("UPDATE fixture.marker SET value='candidate'; CREATE TABLE fixture.candidate_only (id INT)")
                    redis('SET', 'fixture-marker', 'candidate')
                    redis('SAVE')
                    print('ISOLATION VERIFIED: network_mode=none; no published DB ports; nginx/php stopped; writes are internal probes')
                    raise RuntimeError('fixture: failure after isolated candidate probe writes')
                if mode['value'] == 'business-failure' and args[:2] == ('docker', 'compose') and 'start' in args and not isolated_start:
                    mode['value'] = 'business-exposed'
                    wait_sql()
                    sql("UPDATE fixture.marker SET value='business'; CREATE TABLE fixture.business_only (id INT)")
                    redis('SET', 'fixture-marker', 'business')
                    redis('SAVE')
                    raise RuntimeError('fixture: failure after acknowledged business writes')
                return result

            def recovery(label):
                directory = root / 'backups/nginx-update' / label
                directory.mkdir(parents=True, mode=0o700)
                updater.snapshot(root, directory)
                return directory

            with patch.object(updater, 'command', side_effect=command), patch.object(updater, 'download', side_effect=template):
                if os.environ.get('KJ_STACK_EXPECT_UPGRADE_REJECTION') == '1':
                    rejected = recovery('unsupported-upgrade')
                    mode['value'] = 'expected-rejection'
                    with self.assertRaisesRegex(RuntimeError, '未通过就绪检查'):
                        updater.execute_update(root, rejected, 'all', 'https://')
                    logs = subprocess.run(['docker', 'logs', '--tail', '120', names['mysql']], capture_output=True, text=True, timeout=30)
                    engine_log = logs.stdout + logs.stderr
                    self.assertRegex(engine_log.lower(), 'upgrade')
                    self.assertRegex(engine_log, '804|8\\.4')
                    print('UPSTREAM UPGRADE REJECTION LOG:\n' + engine_log)
                    updater.rollback(root, rejected)
                    wait_sql()
                    self.assertEqual(sql('SELECT value FROM fixture.marker'), 'baseline')
                    self.assertEqual(sql('SELECT @@max_connections'), '123')
                    self.assertEqual(redis('GET', 'fixture-marker'), 'baseline')
                    self.assertEqual(json.loads(real('docker', 'inspect', names['nginx']))[0]['Image'], old_image)
                    self.assertFalse((root / updater.STATE).exists())
                    http()
                    print('UNSUPPORTED UPGRADE SAFELY REJECTED:', json.dumps({'from': from_images, 'to': to_images,
                          'restored_mysql_version': sql('SELECT VERSION()'), 'sql_marker': sql('SELECT value FROM fixture.marker'),
                          'redis_marker': redis('GET', 'fixture-marker'), 'php_http': 'baseline:baseline'}))
                    return
                first = recovery('rollback')
                mode['value'] = 'failure'
                with self.assertRaisesRegex(RuntimeError, 'after isolated candidate probe writes'):
                    updater.execute_update(root, first, 'all', 'https://')
                updater.rollback(root, first)
                wait_sql()
                self.assertEqual(sql('SELECT value FROM fixture.marker'), 'baseline')
                self.assertEqual(sql("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='fixture' AND table_name='candidate_only'"), '0')
                self.assertEqual(sql('SELECT @@max_connections'), '123')
                self.assertEqual(redis('GET', 'fixture-marker'), 'baseline')
                self.assertEqual(json.loads(real('docker', 'inspect', names['nginx']))[0]['Image'], old_image)
                print('ROLLBACK VERIFIED:', json.dumps({'mysql_version': sql('SELECT VERSION()'),
                      'mysql_marker': sql('SELECT value FROM fixture.marker'), 'max_connections': sql('SELECT @@max_connections'),
                      'candidate_table_count': sql("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='fixture' AND table_name='candidate_only'"),
                      'redis_marker': redis('GET', 'fixture-marker'), 'nginx_image': old_image}))
                http()
                cold = json.loads((first / 'data.json').read_text())
                self.assertEqual({record['type'] for record in cold['records']}, {'bind', 'volume'})
                print('COLD BACKUP VERIFIED:', json.dumps(cold))
                mode['value'] = 'success'
                second = recovery('success')
                updater.execute_update(root, second, 'all', 'https://')
                wait_sql()
                self.assertEqual(sql('SELECT value FROM fixture.marker'), 'baseline')
                self.assertEqual(sql('SELECT @@max_connections'), '123')
                self.assertEqual(redis('GET', 'fixture-marker'), 'baseline')
                self.assertEqual((root / 'conf.d/stack.conf').read_text(), site)
                http()
                print('UPGRADE VERIFIED:', json.dumps({'from': from_images, 'to': to_images,
                      'mysql_version': sql('SELECT VERSION()'), 'redis_version': redis('INFO', 'server').splitlines()[1],
                      'images': {service: json.loads(real('docker', 'inspect', names[service]))[0]['Image'] for service in names}}))
                third = recovery('business-writes')
                mode['value'] = 'business-failure'
                with self.assertRaisesRegex(RuntimeError, 'acknowledged business writes'):
                    updater.execute_update(root, third, 'all', 'https://')
                with self.assertRaisesRegex(RuntimeError, '业务写入阶段'):
                    updater.rollback(root, third)
                self.assertEqual(sql('SELECT value FROM fixture.marker'), 'business')
                self.assertEqual(sql("SELECT COUNT(*) FROM information_schema.tables WHERE table_schema='fixture' AND table_name='business_only'"), '1')
                self.assertEqual(redis('GET', 'fixture-marker'), 'business')
                http(b'stack-php-ok:business:business')
                print('BUSINESS WRITES PRESERVED: SQL=business; business table exists; Redis=business; PHP HTTP reflects both; automatic data/image rollback refused')
                print('STACK VERIFIED: real PHP socket HTTP; MySQL SQL/config; Redis persistence; bind/named cold backup; data rollback; successful full update')
        finally:
            real(*compose, 'down', '--volumes', '--remove-orphans')
            if created_image:
                real('docker', 'image', 'rm', candidate_image)
            base.cleanup()


if __name__ == '__main__':
    unittest.main()
