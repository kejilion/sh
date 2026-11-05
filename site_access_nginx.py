r"""Lossless Nginx context parsing for website access-password operations.

This module is deliberately independent of the panel and of any persisted
ownership markers: the Nginx configuration remains the source of truth.
"""

from __future__ import annotations

from dataclasses import dataclass, field
import re


class ConfigError(ValueError):
    pass


@dataclass(frozen=True)
class Token:
    value: str
    start: int
    end: int
    delimiter: bool = False


@dataclass
class Directive:
    words: list[str]
    start: int
    end: int


@dataclass
class Block:
    words: list[str]
    start: int
    open_end: int
    end: int = -1
    directives: list[Directive] = field(default_factory=list)
    children: list["Block"] = field(default_factory=list)


def tokenize(text: str):
    """Yield decoded Nginx tokens together with their original source spans."""
    n, i = len(text), 0
    while i < n:
        if text[i].isspace():
            i += 1
            continue
        if text[i] == "#":
            while i < n and text[i] != "\n":
                i += 1
            continue
        if text[i] in "{};":
            yield Token(text[i], i, i + 1, True)
            i += 1
            continue
        start, quote, value = i, None, []
        while i < n:
            c = text[i]
            if c == "\\":
                if i + 1 >= n:
                    raise ConfigError("incomplete escape")
                # Retain non-special escapes such as the backslash in \.php$.
                next_char = text[i + 1]
                if next_char in "\\\"' \t\r\n;{}#":
                    value.append(next_char)
                else:
                    value.extend((c, next_char))
                i += 2
                continue
            if quote:
                if c == quote:
                    quote = None
                else:
                    value.append(c)
                i += 1
                continue
            if c in "\"'":
                quote = c
                i += 1
                continue
            if c == "{" and value and value[-1] == "$":
                end = text.find("}", i + 1)
                if end < 0:
                    raise ConfigError("incomplete variable")
                value.append(text[i:end + 1])
                i = end + 1
                continue
            if c.isspace() or c in "{};#":
                break
            value.append(c)
            i += 1
        if quote:
            raise ConfigError("unterminated quote")
        if i == start:
            raise ConfigError("invalid token")
        yield Token("".join(value), start, i)


def parse(text: str) -> Block:
    root = Block([], 0, 0, len(text))
    stack, words = [root], []
    for token in tokenize(text):
        if not token.delimiter:
            words.append(token)
        elif token.value == ";":
            if not words:
                raise ConfigError("empty directive")
            stack[-1].directives.append(Directive([w.value for w in words], words[0].start, token.end))
            words = []
        elif token.value == "{":
            if not words:
                raise ConfigError("block has no name")
            block = Block([w.value for w in words], words[0].start, token.end)
            stack[-1].children.append(block)
            stack.append(block)
            words = []
        else:
            if words or len(stack) == 1:
                raise ConfigError("unexpected closing brace")
            stack.pop().end = token.end
    if words or len(stack) != 1:
        raise ConfigError("incomplete configuration")
    return root


def select_context(root: Block, server_index: int, scope: str,
                   location: str = "", modifier: str = "") -> Block:
    """Select a concrete server/location without assuming who created it."""
    servers = []
    for child in root.children:
        if child.words == ["server"]:
            servers.append(child)
        elif child.words == ["http"]:
            servers.extend(item for item in child.children if item.words == ["server"])
    if not isinstance(server_index, int) or isinstance(server_index, bool) or not 0 <= server_index < len(servers):
        raise ConfigError("server not found")
    server = servers[server_index]
    if scope == "server":
        if location or modifier:
            raise ConfigError("unexpected server location")
        return server
    if scope != "location" or not location:
        raise ConfigError("invalid scope")
    wanted = ["location", modifier, location] if modifier else ["location", location]
    matches = []

    def visit(parent):
        for child in parent.children:
            if child.words == wanted:
                matches.append(child)
            if child.words and child.words[0] == "location":
                visit(child)

    visit(server)
    if len(matches) != 1:
        raise ConfigError("location is missing or ambiguous")
    return matches[0]


def effective_auth(root: Block, target: Block) -> tuple[str, str] | None:
    """Resolve literal auth settings inherited by one selected context."""
    ancestors = []

    def find(block):
        ancestors.append(block)
        if block is target:
            return True
        for child in block.children:
            if find(child):
                return True
        ancestors.pop()
        return False

    if not find(root):
        raise ConfigError("selected context is not in configuration")
    realm = user_file = None
    # Resolve from the target outward. Once both values are explicit in a
    # nearer context, unrelated parent includes cannot change that rule.
    for block in reversed(ancestors):
        found = {}
        has_include = False
        for directive in block.directives:
            name = directive.words[0]
            if name == "include":
                has_include = True
                continue
            if name not in ("auth_basic", "auth_basic_user_file"):
                continue
            if name in found or len(directive.words) != 2:
                raise ConfigError("ambiguous authentication directive")
            found[name] = directive.words[1]
        if realm is None:
            realm = found.get("auth_basic")
        if user_file is None:
            user_file = found.get("auth_basic_user_file")
        if realm == "off":
            return None
        if has_include and (realm is None or user_file is None):
            raise ConfigError("included configuration must be resolved before account changes")
        if realm is not None and user_file is not None:
            break
    if realm in (None, "off"):
        return None
    if not realm or not user_file or "$" in realm or "$" in user_file:
        raise ConfigError("authentication settings cannot be resolved")
    return realm, user_file


def replace_auth(text: str, block: Block, realm: str | None, user_file: str | None) -> str:
    """Replace only direct Basic Auth directives; keep every other byte intact."""
    if (realm is None) != (user_file is None):
        raise ConfigError("realm and password file must be supplied together")
    auth = [d for d in block.directives if d.words[0] in {"auth_basic", "auth_basic_user_file"}]
    names = [d.words[0] for d in auth]
    if len(names) != len(set(names)):
        raise ConfigError("duplicate authentication directive")
    if realm is not None and (not realm or any(c in realm for c in '\r\n\x00"\\$') or
                              not user_file or any(c in user_file for c in '\r\n\x00"\\$;{}')):
        raise ConfigError("unsafe authentication value")
    edits = [(d.start, d.end, "") for d in auth]
    if realm is not None:
        insertion = f'\n    auth_basic "{realm}";\n    auth_basic_user_file "{user_file}";'
        edits.append((block.open_end, block.open_end, insertion))
    for start, end, replacement in sorted(edits, reverse=True):
        text = text[:start] + replacement + text[end:]
    return text


def update_account(content: bytes, username: str, replacement_hash: str | None, *,
                   previous_username: str | None = None, must_create: bool = False) -> bytes:
    """Edit one htpasswd account while retaining unrelated users and comments.

    ``replacement_hash=None`` removes the account; callers must decide whether
    removing the last account should also remove the corresponding rule.
    Passwords and hashes are never returned in status messages.
    """
    def validate_name(value):
        if not isinstance(value, str) or not value or len(value.encode("utf-8")) > 256:
            raise ConfigError("invalid account name")
        if value.startswith("#") or any(ord(c) < 32 or ord(c) == 127 or c == ":" for c in value):
            raise ConfigError("invalid account name")

    validate_name(username)
    if previous_username is not None:
        validate_name(previous_username)
    if len(content) > 1024 * 1024 or b"\0" in content:
        raise ConfigError("invalid password file")
    if replacement_hash is not None and not re.fullmatch(r"\$apr1\$[./A-Za-z0-9]{1,8}\$[./A-Za-z0-9]{22}", replacement_hash):
        raise ConfigError("invalid password hash")
    try:
        lines = content.decode("utf-8").splitlines(keepends=True)
    except UnicodeDecodeError as exc:
        raise ConfigError("invalid password file encoding") from exc
    names = {}
    for index, raw in enumerate(lines):
        line = raw.rstrip("\r\n")
        if not line or line.startswith("#"):
            continue
        name, separator, digest = line.partition(":")
        if not separator or not name or not digest or name in names:
            raise ConfigError("invalid or ambiguous password file")
        names[name] = index
    old_name = previous_username if previous_username is not None else username
    if must_create and (previous_username is not None or replacement_hash is None or username in names):
        raise ConfigError("account already exists or request is invalid")
    if previous_username is not None and previous_username not in names:
        raise ConfigError("account no longer exists")
    if old_name != username and username in names:
        raise ConfigError("account already exists")
    index = names.get(old_name)
    if replacement_hash is None:
        if index is None:
            raise ConfigError("account no longer exists")
        del lines[index]
    else:
        new_line = f"{username}:{replacement_hash}\n"
        if index is None:
            if lines and not lines[-1].endswith(("\n", "\r")):
                lines[-1] += "\n"
            lines.append(new_line)
        else:
            lines[index] = new_line
    result = "".join(lines).encode("utf-8")
    if len(result) > 1024 * 1024:
        raise ConfigError("password file too large")
    return result
