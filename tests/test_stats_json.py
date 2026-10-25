"""Telemetry encoding and request budgets, with no external requests."""
import json
import os
from pathlib import Path
import subprocess
import tempfile
import unittest


@unittest.skipUnless(os.name == 'posix', 'requires Bash')
class StatsJSONTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.addCleanup(self.temporary.cleanup)
        self.root = Path(self.temporary.name)
        source = (Path(__file__).resolve().parents[1] / 'kejilion.sh').read_text()
        blocks = []
        for name in ['stats_json_escape', 'send_stats']:
            start = source.index(name + '() {\n')
            end = source.index('\n}\n', start) + 3
            blocks.append(source[start:end])
        self.functions = self.root / 'functions.sh'
        self.functions.write_text('\n'.join(blocks))
        self.bin = self.root / 'bin'
        self.bin.mkdir()
        curl = self.bin / 'curl'
        curl.write_text('''#!/usr/bin/env python3
import json,os,sys,time
from pathlib import Path
args=sys.argv[1:]
with Path(os.environ['CALLS']).open('a') as f:f.write(json.dumps(args)+'\\n')
if 'https://ipinfo.io/country' in args:
 print(os.environ.get('COUNTRY','US'))
else:
 time.sleep(float(os.environ.get('POST_DELAY','0')))
 with Path(os.environ['PAYLOADS']).open('a') as f:f.write(args[args.index('--data-binary')+1]+'\\n')
''')
        curl.chmod(0o700)

    def run_script(self, body, **extra):
        env = dict(os.environ, PATH=str(self.bin) + ':' + os.environ['PATH'],
                   CALLS=str(self.root / 'calls'), PAYLOADS=str(self.root / 'payloads'), **extra)
        return subprocess.run(['bash', '-c', 'set -eu; source "$1"; sh_v=4.5.14; ENABLE_STATS=true; ' + body,
                               'fixture', str(self.functions)], env=env, text=True,
                              capture_output=True, timeout=15)

    def test_escape_round_trips_quotes_backslashes_unicode_and_all_control_characters(self):
        value = '中文 "quote" \\ path &' + ''.join(chr(i) for i in range(1, 32))
        result = self.run_script('stats_json_escape "$VALUE"', VALUE=value)
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads('"' + result.stdout + '"'), value)

    def test_payload_is_valid_and_network_requests_have_deadlines(self):
        value = '安装 "Nginx"\n下一行\x1b[31m'
        result = self.run_script('send_stats "$VALUE"; wait', VALUE=value)
        self.assertEqual(result.returncode, 0, result.stderr)
        payload = json.loads((self.root / 'payloads').read_text())
        self.assertEqual(payload['action'], value)
        self.assertEqual(payload['country'], 'US')
        for args in map(json.loads, (self.root / 'calls').read_text().splitlines()):
            self.assertIn('--connect-timeout', args)
            self.assertIn('--max-time', args)
            self.assertNotIn('--retry', args)

    def test_non_country_provider_response_cannot_inject_into_json(self):
        result = self.run_script('send_stats test; wait', COUNTRY='<html>"error"\n</html>')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(json.loads((self.root / 'payloads').read_text())['country'], '')

    def test_rapid_repeated_calls_send_only_one_request(self):
        result = self.run_script('for i in {1..100}; do send_stats test; done; wait', POST_DELAY='0.2')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertEqual(len((self.root / 'payloads').read_text().splitlines()), 1)

    def test_disabled_telemetry_never_calls_network(self):
        result = self.run_script('ENABLE_STATS=false; send_stats test; wait')
        self.assertEqual(result.returncode, 0, result.stderr)
        self.assertFalse((self.root / 'calls').exists())


if __name__ == '__main__':
    unittest.main()
