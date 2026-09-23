#!/usr/bin/env python3
"""Run the script's actual API-management Python against fake credentials."""
import contextlib
import copy
import io
import json
import os
from pathlib import Path
import re
import shutil
import subprocess
import sys
import tempfile
import threading
import time
import unittest
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from unittest.mock import patch


SCRIPT = Path(__file__).resolve().parents[2] / 'kejilion.sh'
if len(sys.argv) > 1 and sys.argv[1].endswith('.sh'):
    SCRIPT = Path(sys.argv.pop(1)).resolve()
SOURCE = SCRIPT.read_text(encoding='utf-8')
FAKE_KEY = 'fixture-only-not-a-real-key'


def body(function, marker):
    source = SOURCE[SOURCE.index(function + '() {'):]
    start = re.search(r"<<-?'" + marker + r"'\n", source).end()
    return source[start:source.index('\n' + marker + '\n', start)]


HELPER = body('openclaw_api_python', 'PY_SECRETS')
CODES = {
    'list': body('openclaw_api_manage_list', 'PY'),
    'sync': body('sync-openclaw-provider-interactive', 'PY2'),
    'all': body('sync_openclaw_api_models', 'PY'),
    'protocol': body('fix-openclaw-provider-protocol-interactive', 'PY'),
}


class SecretRefTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.requests = []

        class Handler(BaseHTTPRequestHandler):
            def do_GET(self):
                auth = self.headers.get('Authorization')
                cls.requests.append(auth)
                ok = auth == 'Bearer ' + FAKE_KEY
                self.send_response(200 if ok else 401)
                self.end_headers()
                self.wfile.write(json.dumps({'data': [{'id': 'new-model'}]} if ok
                                           else {'error': 'unauthorized'}).encode())

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
        self.tmp = tempfile.TemporaryDirectory(prefix='openclaw-api-fixture-')
        self.addCleanup(self.tmp.cleanup)
        self.config = Path(self.tmp.name) / 'openclaw.json'
        self.requests.clear()
        self.resolver_calls = []
        self.resolved_value = FAKE_KEY
        self.resolver_error = None
        self.killed_groups = []
        self.terminated = []
        self.native = False

    def fixture(self, key):
        return {'models': {'providers': {'demo': {
            'api': 'openai-completions',
            'baseUrl': f'http://127.0.0.1:{self.server.server_port}/v1',
            'apiKey': key, 'models': [{'id': 'old-model', 'name': 'Old model'}],
        }}}, 'agents': {'defaults': {
            'model': {'primary': 'demo/old-model'}, 'models': {'demo/old-model': {}},
        }}}

    def write(self, key):
        self.config.write_text(json.dumps(self.fixture(key)), encoding='utf-8')

    def resolve(self, args, **kwargs):
        self.resolver_calls.append(args)
        self.assertNotIn(FAKE_KEY, ' '.join(args))
        self.assertEqual(kwargs['env']['OPENCLAW_CONFIG_PATH'], str(self.config))
        self.assertTrue(kwargs['start_new_session'])
        if isinstance(self.resolver_error, OSError):
            raise self.resolver_error
        owner = self
        class Process:
            pid = 123456789
            returncode = 0
            def __enter__(self):
                return self
            def __exit__(self, *args):
                pass
            def terminate(self):
                owner.terminated.append(self.pid)
            def communicate(self, data=None, timeout=None):
                if data is None:
                    owner.assertEqual(timeout, 5)
                    return '', ''
                owner.assertEqual(timeout, 60)
                if owner.resolver_error:
                    raise owner.resolver_error
                return json.dumps({name: owner.resolved_value
                                   for name in json.loads(data)['names']}), ''
        return Process()

    def run_code(self, kind):
        args = [str(self.config)]
        if kind in ('sync', 'protocol'):
            args.append('demo')
        if kind == 'all':
            args += ['false', 'test']
        if kind == 'protocol':
            args.append('openai-responses')
        output = io.StringIO()
        code = 0
        with contextlib.ExitStack() as stack, \
                patch.object(sys, 'argv', ['fixture'] + args), patch('time.sleep'), \
                patch('getpass.getpass', side_effect=AssertionError('Unexpected key prompt')), \
                patch('builtins.input', side_effect=AssertionError('Unexpected delete prompt')), \
                contextlib.redirect_stdout(output):
            if not self.native:
                stack.enter_context(patch('shutil.which', side_effect=lambda name: '/fixture/' + name))
                stack.enter_context(patch('subprocess.Popen', self.resolve))
                stack.enter_context(patch('os.killpg', create=True,
                                          side_effect=lambda pid, sig: self.killed_groups.append(pid)))
                stack.enter_context(patch('signal.SIGKILL', 9, create=True))
            try:
                exec(compile(HELPER + '\n' + CODES[kind], str(SCRIPT), 'exec'), {})
            except SystemExit as exc:
                code = exc.code or 0
        self.assertNotIn(FAKE_KEY, output.getvalue())
        return code, output.getvalue()

    def test_plaintext_works_without_prompt(self):
        self.write(FAKE_KEY)
        self.assertEqual(self.run_code('list')[0], 0)
        self.assertEqual(self.run_code('sync')[0], 0)
        self.assertEqual(self.resolver_calls, [])
        self.assertEqual(self.requests, ['Bearer ' + FAKE_KEY] * 2)

    def test_secretrefs_list_and_sync_preserve_references(self):
        refs = [{'source': source, 'provider': 'default', 'id': 'FIXTURE_KEY'}
                for source in ('env', 'file', 'exec', 'store')]
        refs += ['${FIXTURE_KEY}', '$FIXTURE_KEY']
        for ref in refs:
            for kind in ('sync', 'all'):
                with self.subTest(ref=ref, kind=kind):
                    self.write(ref)
                    self.requests.clear()
                    code, output = self.run_code('list')
                    self.assertEqual(code, 0)
                    self.assertIn('ms', output)
                    self.assertEqual(self.requests, ['Bearer ' + FAKE_KEY])
                    self.assertEqual(self.run_code(kind)[0], 0)
                    saved = json.loads(self.config.read_text(encoding='utf-8'))
                    provider = saved['models']['providers']['demo']
                    self.assertEqual(provider['apiKey'], ref)
                    self.assertEqual(provider['models'][0]['id'], 'new-model')
                    self.assertEqual(saved['agents']['defaults']['model']['primary'], 'demo/new-model')
                    self.assertEqual(self.requests, ['Bearer ' + FAKE_KEY] * 2)
                    self.assertNotIn(FAKE_KEY, self.config.read_text(encoding='utf-8'))

    def test_resolution_failure_never_probes_deletes_or_writes(self):
        for error in (OSError(FAKE_KEY), ValueError(FAKE_KEY),
                      subprocess.TimeoutExpired('node', 60)):
            with self.subTest(error=type(error).__name__):
                self.write({'source': 'file', 'provider': 'default', 'id': '/key'})
                original = self.config.read_bytes()
                self.resolver_error = error
                code, output = self.run_code('list')
                self.assertEqual(code, 0)
                self.assertIn('密钥引用未解析（未检测）', output)
                self.assertNotIn('\tunavailable', output)
                self.assertEqual(self.run_code('sync')[0], 6)
                code, output = self.run_code('all')
                self.assertEqual(code, 2)
                self.assertNotIn('无需同步', output)
                self.assertEqual(self.requests, [])
                self.assertEqual(self.config.read_bytes(), original)
                if isinstance(error, subprocess.TimeoutExpired):
                    self.assertEqual(self.terminated, [123456789] * 3)
                    self.assertEqual(self.killed_groups, [])

    def test_missing_runtime_never_prompts(self):
        self.write({'source': 'file', 'provider': 'default', 'id': '/key'})
        original = self.config.read_bytes()
        self.native = True
        with patch('shutil.which', return_value=None):
            self.assertEqual(self.run_code('sync')[0], 6)
        self.assertEqual(self.resolver_calls, [])
        self.assertEqual(self.requests, [])
        self.assertEqual(self.config.read_bytes(), original)

    def test_bad_resolved_key_never_offers_to_delete_provider(self):
        self.write({'source': 'file', 'provider': 'default', 'id': '/key'})
        original = self.config.read_bytes()
        self.resolved_value = 'wrong-fixture-key'
        self.assertEqual(self.run_code('all')[0], 2)
        self.assertEqual(len(self.requests), 3)
        self.assertEqual(self.config.read_bytes(), original)

    def test_unresolved_sentinels_are_not_sent_upstream(self):
        for value in (None, {}, '', '${FIXTURE_KEY}', '__OPENCLAW_REDACTED__',
                      'secretref-managed', 'oc-sent-v2.fixture.end', 'key\nheader'):
            with self.subTest(value=value):
                self.write({'source': 'store', 'provider': 'default', 'id': 'FIXTURE_KEY'})
                original = self.config.read_bytes()
                self.resolved_value = value
                self.assertEqual(self.run_code('sync')[0], 6)
                self.assertEqual(self.requests, [])
                self.assertEqual(self.config.read_bytes(), original)

    def test_mixed_sync_is_atomic_when_a_reference_is_unresolved(self):
        fixture = self.fixture({'source': 'exec', 'provider': 'default', 'id': 'key'})
        fixture['models']['providers']['plain'] = copy.deepcopy(fixture['models']['providers']['demo'])
        fixture['models']['providers']['plain']['apiKey'] = FAKE_KEY
        self.config.write_text(json.dumps(fixture), encoding='utf-8')
        original = self.config.read_bytes()
        self.resolved_value = None
        self.assertEqual(self.run_code('all')[0], 2)
        self.assertEqual(self.config.read_bytes(), original)
        self.assertEqual(self.requests, ['Bearer ' + FAKE_KEY])

    def test_protocol_change_keeps_reference(self):
        ref = {'source': 'store', 'provider': 'default', 'id': 'FIXTURE_KEY'}
        self.write(ref)
        self.assertEqual(self.run_code('protocol')[0], 0)
        saved = json.loads(self.config.read_text(encoding='utf-8'))['models']['providers']['demo']
        self.assertEqual(saved['apiKey'], ref)
        self.assertEqual(saved['api'], 'openai-responses')
        self.assertEqual(self.resolver_calls, [])

    @unittest.skipUnless(os.name == 'posix' and shutil.which('jq'), 'requires Linux bash/jq')
    def test_replacing_provider_preserves_reference(self):
        start = SOURCE.index('\twrite-openclaw-provider-models() {')
        end = SOURCE.index('\tadd-all-models-from-provider() {', start)
        harness = ('set -e\nopenclaw_get_config_file() { printf "%s\\n" "$FIXTURE_CONFIG"; }\n'
                   + SOURCE[start:end]
                   + '\nwrite-openclaw-provider-models demo https://example.invalid/v1 '
                   + FAKE_KEY + ' \'[{"id":"replacement"}]\'\n')
        for ref in ({'source': 'file', 'provider': 'default', 'id': '/key'},
                    '${FIXTURE_KEY}', '$FIXTURE_KEY', 'previous-plaintext'):
            with self.subTest(ref=ref):
                self.write(ref)
                result = subprocess.run(['bash'], input=harness, text=True, capture_output=True,
                                        env=dict(os.environ, FIXTURE_CONFIG=str(self.config)))
                self.assertEqual(result.returncode, 0, result.stderr)
                saved = json.loads(self.config.read_text())['models']['providers']['demo']
                self.assertEqual(saved['apiKey'], FAKE_KEY if ref == 'previous-plaintext' else ref)
                self.assertEqual(saved['models'], [{'id': 'replacement'}])

@unittest.skipUnless(os.environ.get('OPENCLAW_NATIVE_TEST') == '1', 'opt-in installed OpenClaw SDK tests')
class NativeRuntimeTests(unittest.TestCase):
    setUpClass = classmethod(SecretRefTests.setUpClass.__func__)
    tearDownClass = classmethod(SecretRefTests.tearDownClass.__func__)
    setUp = SecretRefTests.setUp
    fixture = SecretRefTests.fixture
    run_code = SecretRefTests.run_code

    def test_native_timeout_reaps_detached_exec(self):
        self.native = True
        marker = Path(self.tmp.name) / 'exec-pid'
        command = Path(self.tmp.name) / 'slow-fixture'
        command.write_text('#!/usr/bin/python3\nimport json,os,sys,time\n'
                           'json.load(sys.stdin)\n'
                           + 'open(' + repr(str(marker)) + ', "w").write(str(os.getpid()))\n'
                           + 'time.sleep(15)\n')
        command.chmod(0o700)
        obj = self.fixture({'source': 'exec', 'provider': 'slow', 'id': 'key'})
        obj['secrets'] = {'providers': {'slow': {
            'source': 'exec', 'command': str(command), 'trustedDirs': [self.tmp.name],
            'timeoutMs': 20000, 'noOutputTimeoutMs': 20000,
        }}}
        self.config.write_text(json.dumps(obj))
        self.config.chmod(0o600)
        original = self.config.read_bytes()
        real_process = subprocess.Popen
        class ShortDeadlineProcess(real_process):
            def communicate(self, input=None, timeout=None):
                return super().communicate(input, timeout=5 if input is not None else timeout)
        try:
            with patch.dict(os.environ, OPENCLAW_STATE_DIR=self.tmp.name), \
                    patch('subprocess.Popen', ShortDeadlineProcess):
                self.assertEqual(self.run_code('sync')[0], 6)
            self.assertTrue(marker.exists(), 'real exec provider must start before the deadline')
            pid = int(marker.read_text())
            stat = Path(f'/proc/{pid}/stat')
            for _ in range(50):
                if not stat.exists() or stat.read_text().split(') ', 1)[1].startswith('Z '):
                    break
                time.sleep(0.02)
            else:
                self.fail('detached exec provider survived resolver timeout')
            self.assertEqual(self.requests, [])
            self.assertEqual(self.config.read_bytes(), original)
        finally:
            # Clean up only our exact fixture process if an assertion above fails.
            if marker.exists():
                pid = int(marker.read_text())
                cmdline = Path(f'/proc/{pid}/cmdline')
                if cmdline.exists() and str(command).encode() in cmdline.read_bytes().split(b'\0'):
                    os.kill(pid, 9)

    def test_native_sources_without_input_or_reference_writeback(self):
        self.native = True
        state = Path(self.tmp.name) / 'state'
        state.mkdir(mode=0o700)
        secret_file = Path(self.tmp.name) / 'secrets.json'
        secret_file.write_text(json.dumps({'key': FAKE_KEY}))
        secret_file.chmod(0o600)
        command = Path(self.tmp.name) / 'resolve-key'
        command.write_text('#!/usr/bin/python3\nimport json,sys\nr=json.load(sys.stdin)\n'
                           + 'print(json.dumps({"protocolVersion":1,"values":{k:'
                           + repr(FAKE_KEY) + ' for k in r["ids"]}}))\n')
        command.chmod(0o700)
        cases = [
            ({'source': 'env', 'provider': 'default', 'id': 'FIXTURE_KEY'}, {}),
            ('${FIXTURE_KEY}', {}), ('$FIXTURE_KEY', {}),
            ({'source': 'file', 'provider': 'fixture', 'id': '/key'},
             {'fixture': {'source': 'file', 'path': str(secret_file), 'mode': 'json'}}),
            ({'source': 'exec', 'provider': 'fixture', 'id': 'key'},
             {'fixture': {'source': 'exec', 'command': str(command),
                          'trustedDirs': [self.tmp.name]}}),
            ({'source': 'store', 'provider': 'default', 'id': 'FIXTURE_KEY'}, {}),
        ]
        with patch.dict(os.environ, OPENCLAW_STATE_DIR=str(state),
                        OPENCLAW_CONFIG_PATH=str(self.config)):
            # The standard migration stores secrets in the isolated official SQLite store.
            saved = subprocess.run(['openclaw', 'secrets', 'store', 'set', 'FIXTURE_KEY',
                                    '--kind', 'secret', '--value-file', '-'],
                                   input=FAKE_KEY, text=True, capture_output=True, timeout=60)
            self.assertEqual(saved.returncode, 0, saved.stderr)
            (state / '.env').write_text('FIXTURE_KEY=' + FAKE_KEY + '\n')
            (state / '.env').chmod(0o600)
            for ref, providers in cases:
                for kind in ('list', 'sync', 'all'):
                    with self.subTest(ref=ref, kind=kind):
                        obj = self.fixture(ref)
                        if providers:
                            obj['secrets'] = {'providers': providers}
                        self.config.write_text(json.dumps(obj))
                        self.config.chmod(0o600)
                        self.requests.clear()
                        code, output = self.run_code(kind)
                        self.assertEqual(code, 0, output)
                        self.assertEqual(self.requests, ['Bearer ' + FAKE_KEY], output)
                        result = json.loads(self.config.read_text())
                        self.assertEqual(result['models']['providers']['demo']['apiKey'], ref)
                        self.assertNotIn(FAKE_KEY, self.config.read_text())
            # config.env uses the same official bootstrap as OpenClaw itself.
            obj = self.fixture({'source': 'env', 'provider': 'default', 'id': 'CONFIG_FIXTURE_KEY'})
            obj['env'] = {'vars': {'CONFIG_FIXTURE_KEY': FAKE_KEY}}
            self.config.write_text(json.dumps(obj))
            self.requests.clear()
            self.assertEqual(self.run_code('list')[0], 0)
            self.assertEqual(self.requests, ['Bearer ' + FAKE_KEY])
            # Replacing a migrated provider asks only for provider/URL/model choices.
            ref = {'source': 'store', 'provider': 'default', 'id': 'FIXTURE_KEY'}
            self.config.write_text(json.dumps(self.fixture(ref)))
            start = SOURCE.index('\topenclaw_api_python() {')
            end = SOURCE.index('\tsync_openclaw_api_models() {', start)
            add_start = SOURCE.index('\tbuild-openclaw-provider-models-json() {')
            add_end = SOURCE.index('openclaw_api_manage_list() {', add_start)
            harness = Path(self.tmp.name) / 'add-provider.sh'
            harness.write_text(SOURCE[start:end] + SOURCE[add_start:add_end] + '''
openclaw_get_config_file() { printf '%s\\n' "$OPENCLAW_CONFIG_PATH"; }
send_stats() { :; }
install() { :; }
break_end() { :; }
start_gateway() { :; }
openclaw_sync_sessions_model() { :; }
openclaw() { :; }
add-openclaw-provider-interactive
''')
            wrappers = Path(self.tmp.name) / 'bin'
            wrappers.mkdir()
            for command_name in ('curl', 'jq'):
                executable = shutil.which(command_name)
                wrapper = wrappers / command_name
                wrapper.write_text('#!/usr/bin/python3\nimport os,sys\n'
                                   + 'assert ' + repr(FAKE_KEY) + ' not in " ".join(sys.argv)\n'
                                   + 'os.execv(' + repr(executable) + ', [' + repr(executable)
                                   + '] + sys.argv[1:])\n')
                wrapper.chmod(0o700)
            for choice in ('n', 'y'):
                self.config.write_text(json.dumps(self.fixture(ref)))
                self.requests.clear()
                replaced = subprocess.run(['bash', str(harness)], text=True, capture_output=True,
                                          input=f'demo\nhttp://127.0.0.1:{self.server.server_port}/v1\n\n{choice}\n',
                                          env=dict(os.environ, PATH=str(wrappers) + ':' + os.environ['PATH']),
                                          timeout=60)
                self.assertEqual(replaced.returncode, 0, replaced.stderr)
                self.assertEqual(self.requests, ['Bearer ' + FAKE_KEY])
                self.assertNotIn(FAKE_KEY[:8], replaced.stdout + replaced.stderr)
                provider = json.loads(self.config.read_text())['models']['providers']['demo']
                self.assertEqual(provider['apiKey'], ref)
                self.assertEqual(provider['models'][0]['id'], 'new-model')
            # Missing sources fail closed and leave bytes untouched.
            obj = self.fixture({'source': 'file', 'provider': 'missing', 'id': '/key'})
            self.config.write_text(json.dumps(obj))
            original = self.config.read_bytes()
            self.requests.clear()
            self.assertEqual(self.run_code('sync')[0], 6)
            self.assertEqual(self.config.read_bytes(), original)
            self.assertEqual(self.requests, [])


if __name__ == '__main__':
    unittest.main()
