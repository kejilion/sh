import importlib.util
from pathlib import Path
import sys
import unittest

MODULE = Path(__file__).resolve().parents[1] / "site_access_nginx.py"
spec = importlib.util.spec_from_file_location("site_access_nginx", MODULE)
module = importlib.util.module_from_spec(spec)
sys.modules[spec.name] = module
spec.loader.exec_module(module)


class SiteAccessConfigTests(unittest.TestCase):
    def test_scopes_keep_real_nginx_regex_and_quoted_values(self):
        text = r'''server {
    # auth_basic "ignored";
    server_name example.com;
    location ~ \.php$ {
        fastcgi_param REQUEST_URI "${uri}";
        auth_basic "Admin #1";
        auth_basic_user_file /etc/nginx/conf.d/.users;
    }
}'''
        server = module.parse(text).children[0]
        location = server.children[0]
        self.assertEqual(location.words, ["location", "~", r"\.php$"])
        self.assertEqual(location.directives[1].words, ["auth_basic", "Admin #1"])
        changed = module.replace_auth(text, location, "New realm", "/etc/nginx/conf.d/.other")
        self.assertIn('fastcgi_param REQUEST_URI "${uri}";', changed)
        self.assertIn('# auth_basic "ignored";', changed)
        self.assertIn('auth_basic "New realm";', changed)
        self.assertNotIn('auth_basic "Admin #1";', changed)
        module.parse(changed)

    def test_delete_only_removes_directives_in_selected_context(self):
        text = 'server { auth_basic "Outer"; auth_basic_user_file /outer; location / { auth_basic "Inner"; auth_basic_user_file /inner; proxy_pass http://app; } }'
        server = module.parse(text).children[0]
        changed = module.replace_auth(text, server.children[0], None, None)
        self.assertIn('auth_basic "Outer";', changed)
        self.assertIn('auth_basic_user_file /outer;', changed)
        self.assertIn('proxy_pass http://app;', changed)
        self.assertNotIn('auth_basic "Inner";', changed)
        module.parse(changed)

    def test_refuses_invalid_or_ambiguous_edits(self):
        for text in ['server {', 'server { x "bad; }', 'server { x y; }}']:
            with self.subTest(text=text), self.assertRaises(module.ConfigError):
                module.parse(text)
        block = module.parse('server { auth_basic one; auth_basic two; }').children[0]
        with self.assertRaises(module.ConfigError):
            module.replace_auth('server { auth_basic one; auth_basic two; }', block, "new", "/file")
        text = 'server { listen 443; }'
        with self.assertRaises(module.ConfigError):
            module.replace_auth(text, module.parse(text).children[0], 'x"; include /tmp/pwn;', '/file')

    def test_selects_existing_scope_by_index_and_path(self):
        text = 'server { location /admin/ { proxy_pass http://first; } } server { location ^~ /admin/ { proxy_pass http://second; } }'
        root = module.parse(text)
        block = module.select_context(root, 1, "location", "/admin/", "^~")
        changed = module.replace_auth(text, block, "Private", "/etc/nginx/conf.d/users")
        self.assertEqual(changed.count('auth_basic "Private";'), 1)
        self.assertIn('proxy_pass http://first;', changed)
        self.assertIn('proxy_pass http://second;', changed)
        with self.assertRaises(module.ConfigError):
            module.select_context(root, 0, "location", "/missing/")

    def test_rejects_duplicate_matching_context(self):
        root = module.parse('server { location /a { } location /a { } }')
        with self.assertRaises(module.ConfigError):
            module.select_context(root, 0, "location", "/a")

    def test_resolves_explicit_and_inherited_auth_after_parsing(self):
        text = '''http { server {
            location /admin/ { auth_basic "Admin"; }
            location /open/ { auth_basic off; }
            auth_basic "Site";
        } auth_basic_user_file /etc/nginx/conf.d/.users; }'''
        root = module.parse(text)
        admin = module.select_context(root, 0, 'location', '/admin/')
        self.assertEqual(module.effective_auth(root, admin), ('Admin', '/etc/nginx/conf.d/.users'))
        open_location = module.select_context(root, 0, 'location', '/open/')
        self.assertIsNone(module.effective_auth(root, open_location))
        server = module.select_context(root, 0, 'server')
        self.assertEqual(module.effective_auth(root, server), ('Site', '/etc/nginx/conf.d/.users'))

    def test_does_not_guess_effective_auth_across_include(self):
        root = module.parse('server { auth_basic "A"; auth_basic_user_file /users; location /admin { include /etc/nginx/auth.conf; } }')
        target = module.select_context(root, 0, 'location', '/admin')
        with self.assertRaises(module.ConfigError):
            module.effective_auth(root, target)

    def test_direct_auth_can_be_managed_with_unrelated_includes(self):
        root = module.parse('server { include common.conf; location /admin { include proxy.conf; '
                            'auth_basic "A"; auth_basic_user_file /users; } }')
        target = module.select_context(root, 0, 'location', '/admin')
        self.assertEqual(module.effective_auth(root, target), ('A', '/users'))

    def test_account_changes_preserve_other_accounts_and_comments(self):
        before = b'# team\nalice:old-hash\nbob:untouched:comment\n'
        digest = '$apr1$abcdefgh$abcdefghijklmnopqrstuv'
        after = module.update_account(before, 'alice', digest)
        self.assertEqual(after, b'# team\nalice:' + digest.encode() + b'\nbob:untouched:comment\n')
        renamed = module.update_account(after, 'carol', digest, previous_username='alice')
        self.assertIn(b'carol:', renamed)
        self.assertNotIn(b'alice:', renamed)
        self.assertEqual(module.update_account(renamed, 'carol', None), b'# team\nbob:untouched:comment\n')

    def test_account_edits_reject_ambiguous_or_injected_input(self):
        digest = '$apr1$abcdefgh$abcdefghijklmnopqrstuv'
        for content, name in [(b'a:one\na:two\n', 'a'), (b'a:one\n', 'a\nother'), (b'a:one\n', '#comment')]:
            with self.subTest(name=name), self.assertRaises(module.ConfigError):
                module.update_account(content, name, digest)
        with self.assertRaises(module.ConfigError):
            module.update_account(b'a:one\nb:two\n', 'b', digest, previous_username='a')
        with self.assertRaises(module.ConfigError):
            module.update_account(b'a:one\n', 'a', digest, must_create=True)


if __name__ == "__main__":
    unittest.main()
