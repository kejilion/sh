#!/usr/bin/env python3
"""Exercise port cleanup with real sockets, without stopping any real service."""
import os
import pathlib
import shutil
import socket
import subprocess
import sys
import tempfile

ROOT = pathlib.Path(__file__).resolve().parents[1]


def helper(script):
    source = script.read_text()
    start = source.index("stop_containers_or_kill_process() {")
    return source[start:source.index("\n}", start) + 2]


def cleanup(script, port, directory, containers=""):
    log = directory / "actions"
    log.write_text("")
    # Only process discovery is real; destructive commands are recorded.
    subprocess.run(
        ["bash", "-c", helper(script) + r'''
install() { :; }
docker() {
    if [ "$1" = ps ]; then printf '%s' "$CONTAINERS";
    else printf 'docker %s\n' "$*" >> "$LOG"; fi
}
kill() { printf 'kill %s\n' "$*" >> "$LOG"; }
stop_containers_or_kill_process "$PORT"
'''],
        env={**os.environ, "PORT": str(port), "LOG": str(log),
             "CONTAINERS": containers}, check=True, timeout=15,
    )
    return log.read_text().splitlines()


def socket_case(script, family, address, directory):
    server_code = '''
import socket, sys
s = socket.socket(int(sys.argv[1]))
s.bind((sys.argv[2], 0))
s.listen()
print(s.getsockname()[1], flush=True)
c, _ = s.accept()
sys.stdin.read()
'''
    client_code = '''
import socket, sys
s = socket.socket(int(sys.argv[1]))
s.connect((sys.argv[2], int(sys.argv[3])))
print("connected", flush=True)
sys.stdin.read()
'''
    with subprocess.Popen([sys.executable, "-c", server_code, str(int(family)), address],
                          stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True) as server:
        try:
            port = server.stdout.readline().strip()
            assert port, "listener failed to start"
            with subprocess.Popen([sys.executable, "-c", client_code, str(int(family)), address, port],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE, text=True) as client:
                try:
                    assert client.stdout.readline().strip() == "connected"
                    # Confirm this fixture exposes the original bug: both PIDs match.
                    old_pids = subprocess.check_output(
                        ["lsof", "-t", f"-i:{port}"], text=True, timeout=15).splitlines()
                    assert str(server.pid) in old_pids and str(client.pid) in old_pids
                    actions = cleanup(script, port, directory)
                    assert actions == [f"kill -9 {server.pid}"], actions
                    assert client.poll() is None, "outbound client must survive"
                finally:
                    client.stdin.close()
        finally:
            server.stdin.close()


def main():
    if not shutil.which("lsof"):
        raise SystemExit("lsof is required (run on Linux)")
    with tempfile.TemporaryDirectory() as temporary:
        directory = pathlib.Path(temporary)
        for script in (ROOT / "kejilion.sh", ROOT / "cn/kejilion.sh"):
            socket_case(script, socket.AF_INET, "127.0.0.1", directory)
            if socket.has_ipv6:
                socket_case(script, socket.AF_INET6, "::1", directory)
            with socket.socket() as unused:
                unused.bind(("127.0.0.1", 0))
                assert cleanup(script, unused.getsockname()[1], directory) == []
            assert cleanup(script, 443, directory, "web1\nweb2") == ["docker stop web1 web2"]
            print(f"PASS: {script.relative_to(ROOT)} listeners only; outbound clients preserved")


if __name__ == "__main__":
    main()
