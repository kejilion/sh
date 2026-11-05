"""Isolated Nginx behavior probe; only an ephemeral network-less container is used."""

import base64
import os
from pathlib import Path
import subprocess
import sys
import time
import tempfile
import unittest
import uuid

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
import site_access_nginx
import site_access_accounts
import site_access_transaction
import site_access_rules
import site_access_config

CONFIG = r'''
worker_processes 1;
events { worker_connections 64; }
http {
    map $uri $probe_realm {
        default off;
        ~^/protected(?:/|$) "Private";
    }
    server {
        listen 127.0.0.1:18080;
        auth_basic $probe_realm;
        auth_basic_user_file /etc/nginx/probe.htpasswd;
        location / { proxy_pass http://127.0.0.1:18081; }
        location /protected/bypass/ { auth_basic off; proxy_pass http://127.0.0.1:18081; }
        location = /protected/redirect { return 302 /; }
    }
    server { listen 127.0.0.1:18081; root /usr/share/nginx/html; }
}
'''


class NginxAccessProbe(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.name = "kpanel-auth-probe-" + uuid.uuid4().hex[:12]
        cls.temp = tempfile.TemporaryDirectory(prefix='site-access-live-')
        cls.addClassCleanup(cls.temp.cleanup)
        os.chmod(cls.temp.name, 0o755)
        cls.password_file = Path(cls.temp.name) / 'users'
        cls.password_file.write_text('test:$apr1$12345678$IFpXpDRudqLvk0aO7K4jN.\nprobe:$apr1$12345678$IFpXpDRudqLvk0aO7K4jN.\n')
        os.chmod(cls.password_file, 0o644)
        subprocess.run(["docker", "run", "-d", "--network", "none", "--name", cls.name,
                        "--mount", f"type=bind,src={cls.temp.name},dst=/probe,readonly",
                        "--mount", f"type=bind,src={cls.temp.name},dst=/etc/nginx/conf.d,readonly",
                        "nginx:alpine"], check=True, stdout=subprocess.DEVNULL, timeout=30)
        cls.addClassCleanup(lambda: subprocess.run(["docker", "rm", "-f", cls.name],
                                                   stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=30))
        cls.write('/etc/nginx/nginx.conf', CONFIG)
        cls.write('/etc/nginx/probe.htpasswd', 'test:$apr1$12345678$IFpXpDRudqLvk0aO7K4jN.\n')
        cls.write('/usr/share/nginx/html/index.html', 'probe')
        cls.write('/usr/share/nginx/html/protected', 'protected')
        subprocess.run(["docker", "exec", cls.name, "nginx", "-t"], check=True, timeout=10)
        subprocess.run(["docker", "exec", cls.name, "nginx", "-s", "reload"], check=True, timeout=10)

    @classmethod
    def write(cls, path, text):
        subprocess.run(["docker", "exec", "-i", cls.name, "sh", "-c", 'cat > "$1"', "sh", path],
                       input=text.encode(), check=True, timeout=10)

    def request(self, path, credentials=None):
        command = ["docker", "exec", self.name, "wget", "-S", "-O", "-", "-q"]
        if credentials:
            encoded = base64.b64encode(credentials.encode()).decode()
            command += ["--header", "Authorization: Basic " + encoded]
        result = subprocess.run(command + ["http://127.0.0.1:18080" + path], capture_output=True, timeout=10)
        return result.stderr.decode(errors="replace"), result.stdout.decode(errors="replace")

    def setUp(self):
        self.write('/etc/nginx/nginx.conf', CONFIG)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-s', 'reload'], check=True, timeout=10)
        for _ in range(20):
            headers, _ = self.request('/protected')
            if '401 Unauthorized' in headers:
                return
            time.sleep(.05)
        self.fail('Nginx did not activate the test configuration')

    def test_path_map_preserves_proxy_and_requires_credentials(self):
        headers, body = self.request('/')
        self.assertIn('200 OK', headers)
        self.assertEqual(body, 'probe')
        headers, _ = self.request('/protected')
        self.assertIn('401 Unauthorized', headers)
        headers, body = self.request('/protected', 'test:testpass')
        self.assertIn('200 OK', headers)
        self.assertEqual(body, 'protected')
        headers, _ = self.request('/protected', 'test:wrong')
        self.assertIn('401 Unauthorized', headers)

    def test_explicit_off_and_rewrite_return_can_bypass_server_auth(self):
        headers, _ = self.request('/protected/bypass/missing')
        self.assertNotIn('401 Unauthorized', headers)
        headers, _ = self.request('/protected/redirect')
        self.assertIn('302 Moved Temporarily', headers)
        self.assertNotIn('401 Unauthorized', headers)

    def test_maximum_password_is_not_silently_truncated(self):
        original = 'test:$apr1$12345678$IFpXpDRudqLvk0aO7K4jN.\n'
        self.addCleanup(self.write, '/etc/nginx/probe.htpasswd', original)
        password = 'a' * 256
        self.write('/etc/nginx/probe.htpasswd', 'test:' + site_access_accounts.hash_password(password) + '\n')
        headers, _ = self.request('/protected', 'test:' + password)
        self.assertIn('200 OK', headers)
        headers, _ = self.request('/protected', 'test:' + password + 'x')
        self.assertIn('401 Unauthorized', headers)

    def test_inherited_satisfy_any_is_rejected_before_rule_write(self):
        config = ('server { listen 127.0.0.1:18080; location /private/ { satisfy any; allow all; '
                  'location /private/admin/ { proxy_pass http://127.0.0.1:18081/; } } }')
        target = site_access_nginx.select_context(site_access_nginx.parse(config), 0, 'location', '/private/admin/')
        unsafe = site_access_nginx.replace_auth(config, target, 'Private', '/etc/nginx/probe.htpasswd')
        main = ('worker_processes 1; events { worker_connections 64; } http { ' + unsafe +
                ' server { listen 127.0.0.1:18081; root /usr/share/nginx/html; } }')
        self.write('/etc/nginx/nginx.conf', main)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-t'], check=True, timeout=10)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-s', 'reload'], check=True, timeout=10)
        for _ in range(20):
            headers, body = self.request('/private/admin/')
            if '200 OK' in headers:
                break
            time.sleep(.05)
        self.assertIn('200 OK', headers)
        self.assertEqual(body, 'probe')
        site = Path(self.temp.name) / 'nested-site.conf'
        site.write_text(config)
        fd = os.open(self.temp.name, os.O_RDONLY | os.O_DIRECTORY)
        try:
            with self.assertRaises(site_access_rules.ConfigError):
                site_access_rules.add_rule(fd, site.name, site_access_transaction.digest(config.encode()), [0],
                                           'location', '/private/admin/', '', 'alice', 'password',
                                           validate=lambda: None, reload_config=lambda: None)
            self.assertEqual(site.read_text(), config)
        finally:
            os.close(fd)

    def test_patch_and_remove_rule_without_changing_proxy(self):
        config = r'''worker_processes 1;
events { worker_connections 64; }
http {
    server { listen 127.0.0.1:18080;
        location / { proxy_pass http://127.0.0.1:18081; }
        location /protected { proxy_pass http://127.0.0.1:18081; }
    }
    server { listen 127.0.0.1:18081; root /usr/share/nginx/html; }
}'''
        root = site_access_nginx.parse(config)
        block = site_access_nginx.select_context(root, 0, 'location', '/protected')
        protected = site_access_nginx.replace_auth(config, block, 'Private', '/etc/nginx/probe.htpasswd')
        self.write('/etc/nginx/nginx.conf', protected)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-t'], check=True, timeout=10)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-s', 'reload'], check=True, timeout=10)
        for _ in range(20):
            headers, _ = self.request('/protected')
            if '401 Unauthorized' in headers:
                break
            time.sleep(.05)
        self.assertIn('401 Unauthorized', headers)
        headers, body = self.request('/protected', 'test:testpass')
        self.assertIn('200 OK', headers)
        self.assertEqual(body, 'protected')
        block = site_access_nginx.select_context(site_access_nginx.parse(protected), 0, 'location', '/protected')
        restored = site_access_nginx.replace_auth(protected, block, None, None)
        self.write('/etc/nginx/nginx.conf', restored)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-t'], check=True, timeout=10)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-s', 'reload'], check=True, timeout=10)
        for _ in range(20):
            headers, body = self.request('/protected')
            if '200 OK' in headers:
                break
            time.sleep(.05)
        self.assertIn('200 OK', headers)
        self.assertEqual(body, 'protected')

    def test_account_update_applies_without_reload(self):
        config = CONFIG.replace('/etc/nginx/probe.htpasswd', '/probe/users')
        self.write('/etc/nginx/nginx.conf', config)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-s', 'reload'], check=True, timeout=10)
        for _ in range(20):
            headers, _ = self.request('/protected', 'probe:testpass')
            if '200 OK' in headers:
                break
            time.sleep(.05)
        self.assertIn('200 OK', headers)
        version = site_access_transaction.digest(self.password_file.read_bytes())
        site_access_accounts.edit_account(self.temp.name, 'users', version, 'update', 'test',
                                          previous_username='test', password='newpass')
        headers, _ = self.request('/protected', 'test:testpass')
        self.assertIn('401 Unauthorized', headers)
        headers, body = self.request('/protected', 'test:newpass')
        self.assertIn('200 OK', headers)
        self.assertEqual(body, 'protected')

    def test_new_rule_creates_worker_readable_file_and_can_be_removed(self):
        config = ('server { listen 127.0.0.1:18080; '
                  'location /protected { proxy_pass http://127.0.0.1:18081; } }')
        site_file = Path(self.temp.name) / 'site.conf'
        site_file.write_text(config)
        main = '''worker_processes 1; events { worker_connections 64; } http {
            include /probe/site.conf;
            server { listen 127.0.0.1:18081; root /usr/share/nginx/html; }
        }'''
        self.write('/etc/nginx/nginx.conf', main)
        subprocess.run(['docker', 'exec', self.name, 'nginx', '-s', 'reload'], check=True, timeout=10)
        for _ in range(20):
            headers, _ = self.request('/protected')
            if '200 OK' in headers:
                break
            time.sleep(.05)
        self.assertIn('200 OK', headers)
        directory = os.open(self.temp.name, os.O_RDONLY | os.O_DIRECTORY)
        self.addCleanup(os.close, directory)
        def command(*args):
            subprocess.run(['docker', 'exec', self.name, 'nginx', *args], check=True,
                           stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, timeout=10)
        def worker_group():
            return int(subprocess.check_output(['docker', 'exec', self.name, 'id', '-g', 'nginx'], timeout=10))
        def verify_read(path):
            subprocess.run(['docker', 'exec', '-u', 'nginx', self.name, 'sh', '-c', ': < "$1"', 'sh', path],
                           check=True, timeout=10)
        site_access_rules.add_rule(directory, 'site.conf', site_access_transaction.digest(config.encode()),
                                   0, 'location', '/protected', '', 'newuser', 'newpass',
                                   validate=lambda: command('-t'), reload_config=lambda: command('-s', 'reload'),
                                   worker_group=worker_group, verify_read=verify_read)
        for _ in range(20):
            headers, _ = self.request('/protected')
            if '401 Unauthorized' in headers:
                break
            time.sleep(.05)
        self.assertIn('401 Unauthorized', headers)
        headers, body = self.request('/protected', 'newuser:newpass')
        self.assertIn('200 OK', headers)
        self.assertEqual(body, 'protected')
        site_access_config.edit_config(directory, 'site.conf', site_access_transaction.digest(site_file.read_bytes()),
                                       0, 'location', '/protected', '', 'delete',
                                       validate=lambda: command('-t'), reload_config=lambda: command('-s', 'reload'))
        for _ in range(20):
            headers, _ = self.request('/protected')
            if '200 OK' in headers:
                break
            time.sleep(.05)
        self.assertIn('200 OK', headers)


if __name__ == '__main__':
    unittest.main()
