#!/usr/bin/env python3
"""Exercise the actual model picker and HTTP probe with isolated credentials."""
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import tempfile
import threading
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer

import test_api_secretrefs as api

SOURCE = api.SOURCE
KEY = api.FAKE_KEY + '/model-probe'
NATIVE = os.environ.get('OPENCLAW_NATIVE_TEST') == '1'
helper_start = SOURCE.index('\topenclaw_api_python() {')
helper_end = SOURCE.index('\tsync_openclaw_api_models() {', helper_start)
HELPER = SOURCE[helper_start:helper_end]
PROBE = re.search(r'\n\t\topenclaw_model_probe\(\) \{.*?\n\t\t\}', SOURCE, re.S).group()
menu_start = SOURCE.index('\tchange_model() {')
menu_end = SOURCE.index('\t\topenclaw_get_config_file() {', menu_start)
MENU = SOURCE[menu_start:menu_end]
sessions_start = SOURCE.index('\t\topenclaw_get_agents_dir() {', menu_end)
sessions_end = SOURCE.index('\t\tresolve_openclaw_plugin_id() {', sessions_start)
SESSIONS = SOURCE[sessions_start:sessions_end]


@unittest.skipUnless(os.name == 'posix' and shutil.which('jq'), 'requires Linux bash/jq')
class ModelSecretRefTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.requests = []
        cls.mode = 'responses'

        class Handler(BaseHTTPRequestHandler):
            def do_POST(self):
                payload = json.loads(self.rfile.read(int(self.headers['Content-Length'])))
                cls.requests.append((self.path, self.headers.get('Authorization'), payload))
                authorized = self.headers.get('Authorization') == 'Bearer ' + KEY
                code = 200
                if not authorized or cls.mode == 'failure':
                    code = 401
                elif cls.mode == 'fallback' and self.path.endswith('/responses'):
                    code = 404
                if code != 200:
                    data = {'error': {'message': 'upstream reflected ' + KEY}}
                elif self.path.endswith('/responses'):
                    data = {'output': [{'content': [{'text': KEY if cls.mode == 'echo' else 'pong responses'}]}]}
                else:
                    data = {'choices': [{'message': {'content': 'pong chat'}}]}
                self.send_response(code)
                self.end_headers()
                # JSON encoders may escape slashes; probe previews decode them again.
                self.wfile.write(json.dumps(data).replace('/', r'\/').encode())

            def log_message(self, *args):
                pass

        cls.server = ThreadingHTTPServer(('127.0.0.1', 0), Handler)
        cls.thread = threading.Thread(target=cls.server.serve_forever, daemon=True)
        cls.thread.start()

    @classmethod
    def tearDownClass(cls):
        cls.server.shutdown()
        cls.server.server_close()
        cls.thread.join()

    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory(prefix='openclaw-model-fixture-')
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name)
        self.state = self.root / 'home' / '.openclaw'
        self.state.mkdir(parents=True, mode=0o700)
        self.config = self.state / 'openclaw.json'
        self.scratch = self.root / 'scratch'
        self.scratch.mkdir()
        self.captured = self.root / 'captured'
        self.captured.mkdir()
        self.requests.clear()
        type(self).mode = 'responses'
        wrappers = self.root / 'bin'
        wrappers.mkdir()
        for name in ('python3', 'node', 'jq'):
            executable = shutil.which(name)
            if not executable:
                continue
            wrapper = wrappers / name
            wrapper.write_text('#!/usr/bin/python3\nimport os,sys\n'
                               + 'assert ' + repr(KEY) + ' not in " ".join(sys.argv[1:])\n'
                               + 'os.execv(' + repr(executable) + ', [' + repr(executable)
                               + '] + sys.argv[1:])\n')
            wrapper.chmod(0o700)
        self.env = dict(os.environ, HOME=str(self.root / 'home'), OPENCLAW_STATE_DIR=str(self.state),
                        OPENCLAW_CONFIG_PATH=str(self.config), TMPDIR=str(self.scratch),
                        CAPTURED=str(self.captured), PATH=str(wrappers) + ':' + os.environ['PATH'])
        self.stubs = '''
openclaw_get_config_file() { printf '%s\n' "$OPENCLAW_CONFIG_PATH"; }
rm() {
    for file in "$@"; do
        if [ -f "$file" ]; then cp -- "$file" "$CAPTURED/$(basename "$file")"; fi
    done
    command rm "$@"
}
'''

    def write(self, ref, secret_providers=None):
        obj = {'models': {'providers': {'demo': {
            'api': 'openai-completions', 'baseUrl': f'http://127.0.0.1:{self.server.server_port}/v1',
            'apiKey': ref, 'models': [{'id': 'old-model', 'name': 'Old'}, {'id': 'new-model', 'name': 'New'}],
        }}}, 'agents': {'defaults': {'models': {'demo/old-model': {}, 'demo/new-model': {}},
                                    'model': {'primary': 'demo/old-model'}}}}
        if secret_providers:
            obj['secrets'] = {'providers': secret_providers}
        self.config.write_text(json.dumps(obj))
        self.config.chmod(0o600)

    def shell(self, code, inputs=''):
        script = self.root / 'harness.sh'
        script.write_text(HELPER + self.stubs + code)
        result = subprocess.run(['bash', str(script)], input=inputs, text=True,
                                capture_output=True, env=self.env, timeout=120)
        output = result.stdout + result.stderr
        self.assertNotIn(KEY, output)
        self.assertNotIn('AssertionError', output)
        for path in self.captured.iterdir():
            self.assertNotIn(KEY.encode(), path.read_bytes(), str(path))
        return result, output

    def probe(self):
        before = self.config.read_bytes()
        self.requests.clear()
        result, output = self.shell(PROBE + '''
openclaw_model_probe demo/new-model
rc=$?
printf 'STATUS=%s\nMESSAGE=%s\nREPLY=%s\n' "$OPENCLAW_PROBE_STATUS" "$OPENCLAW_PROBE_MESSAGE" "$OPENCLAW_PROBE_REPLY"
exit "$rc"
''')
        self.assertEqual(self.config.read_bytes(), before)
        for _, auth, payload in self.requests:
            self.assertEqual(auth, 'Bearer ' + KEY)
            self.assertEqual(payload['model'], 'new-model')
        return result, output

    def test_plaintext_and_dual_endpoint_failures(self):
        self.write(KEY)
        for mode in ('responses', 'fallback', 'failure', 'echo'):
            with self.subTest(mode=mode):
                type(self).mode = mode
                result, output = self.probe()
                self.assertEqual(result.returncode, 1 if mode == 'failure' else 0, output)
                paths = ['/v1/responses'] if mode in ('responses', 'echo') else ['/v1/responses', '/v1/chat/completions']
                self.assertEqual([request[0] for request in self.requests], paths)
                if mode in ('failure', 'echo'):
                    self.assertIn('[REDACTED]', output)

    @unittest.skipUnless(NATIVE, 'opt-in installed OpenClaw SDK tests')
    def test_native_secretrefs_and_fallback(self):
        (self.state / '.env').write_text('FIXTURE_KEY=' + KEY + '\n')
        (self.state / '.env').chmod(0o600)
        keyfile = self.root / 'key.json'
        keyfile.write_text(json.dumps({'key': KEY}))
        keyfile.chmod(0o600)
        command = self.root / 'key-command'
        command.write_text('#!/usr/bin/python3\nimport json,sys\nr=json.load(sys.stdin)\n'
                           + 'print(json.dumps({"protocolVersion":1,"values":{k:'
                           + repr(KEY) + ' for k in r["ids"]}}))\n')
        command.chmod(0o700)
        saved = subprocess.run(['openclaw', 'secrets', 'store', 'set', 'FIXTURE_KEY', '--kind',
                                'secret', '--value-file', '-'], input=KEY, text=True,
                               capture_output=True, env=self.env, timeout=60)
        self.assertEqual(saved.returncode, 0, saved.stderr)
        cases = [
            ({'source': 'env', 'provider': 'default', 'id': 'FIXTURE_KEY'}, None),
            ('${FIXTURE_KEY}', None), ('$FIXTURE_KEY', None),
            ({'source': 'store', 'provider': 'default', 'id': 'FIXTURE_KEY'}, None),
            ({'source': 'file', 'provider': 'fixture', 'id': '/key'},
             {'fixture': {'source': 'file', 'path': str(keyfile), 'mode': 'json'}}),
            ({'source': 'exec', 'provider': 'fixture', 'id': 'key'},
             {'fixture': {'source': 'exec', 'command': str(command), 'trustedDirs': [str(self.root)]}}),
        ]
        for ref, providers in cases:
            for mode in ('responses', 'fallback'):
                with self.subTest(ref=ref, mode=mode):
                    self.write(ref, providers)
                    type(self).mode = mode
                    result, output = self.probe()
                    self.assertEqual(result.returncode, 0, output)
                    self.assertIn('STATUS=OK', output)
                    expected = ['/v1/responses'] if mode == 'responses' else ['/v1/responses', '/v1/chat/completions']
                    self.assertEqual([request[0] for request in self.requests], expected)
        self.write({'source': 'store', 'provider': 'default', 'id': 'FIXTURE_KEY'})
        type(self).mode = 'failure'
        result, output = self.probe()
        self.assertEqual(result.returncode, 1, output)
        self.assertIn('[REDACTED]', output)

    @unittest.skipUnless(NATIVE, 'opt-in installed OpenClaw SDK tests')
    def test_native_missing_key_does_not_send_or_prompt(self):
        self.write({'source': 'env', 'provider': 'default', 'id': 'MISSING_FIXTURE_KEY'})
        result, output = self.probe()
        self.assertEqual(result.returncode, 1, output)
        self.assertIn('STATUS=ERROR', output)
        self.assertIn('未能读取或解析 API Key', output)
        self.assertNotIn('integer expression', output)
        self.assertEqual(self.requests, [])

    @unittest.skipUnless(NATIVE, 'opt-in installed OpenClaw SDK tests')
    def test_picker_switches_with_real_cli_and_preserves_reference(self):
        (self.state / '.env').write_text('FIXTURE_KEY=' + KEY + '\n')
        (self.state / '.env').chmod(0o600)
        ref = {'source': 'env', 'provider': 'default', 'id': 'FIXTURE_KEY'}
        self.write(ref)
        session = self.state / 'agents' / 'main' / 'sessions' / 'sessions.json'
        session.parent.mkdir(parents=True)
        session.write_text(json.dumps({'agent:main:main': {'sessionId': 'fixture',
                                                        'modelOverride': 'old-model',
                                                        'providerOverride': 'demo'}}))
        result, output = self.shell(MENU + SESSIONS + '''
send_stats() { :; }
clear() { :; }
install() { :; }
install_gum() { :; }
break_end() { :; }
start_gateway() { touch "$HOME/restart-requested"; }
gum() {
    case "$1" in
        --version) echo fixture-gum ;;
        filter)
            cat >/dev/null
            if [ ! -f "$HOME/picked" ]; then
                touch "$HOME/picked"
                echo '(1) demo/new-model'
            fi ;;
    esac
}
change_model
''', inputs='y\n')
        self.assertEqual(result.returncode, 0, output)
        self.assertIn('最小检测结果：可用', output)
        saved = json.loads(self.config.read_text())
        self.assertEqual(saved['agents']['defaults']['model']['primary'], 'demo/new-model')
        self.assertEqual(saved['models']['providers']['demo']['apiKey'], ref)
        self.assertNotIn(KEY, self.config.read_text())
        saved_session = json.loads(session.read_text())['agent:main:main']
        self.assertEqual(saved_session['modelOverride'], 'new-model')
        self.assertEqual(saved_session['providerOverride'], 'demo')
        self.assertTrue((self.root / 'home' / 'restart-requested').exists())


if __name__ == '__main__':
    unittest.main()
