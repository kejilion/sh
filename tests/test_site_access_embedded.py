import importlib.util
from pathlib import Path
import unittest

root = Path(__file__).resolve().parents[1]
spec = importlib.util.spec_from_file_location('sync_site_access_adapter', root / 'scripts/sync-site-access-adapter.py')
sync = importlib.util.module_from_spec(spec)
spec.loader.exec_module(sync)


class EmbeddedAdapterTests(unittest.TestCase):
    def test_standalone_scripts_include_exact_shared_sources(self):
        expected = sync.embedded()
        for filename in ('kejilion.sh', 'cn/kejilion.sh'):
            text = (root / filename).read_text(encoding='utf-8')
            start = text.index(sync.BEGIN)
            end = text.index(sync.END) + len(sync.END)
            self.assertEqual(text[start:end], expected, filename)


if __name__ == '__main__':
    unittest.main()
