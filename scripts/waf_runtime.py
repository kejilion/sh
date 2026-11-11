#!/usr/bin/env python3
"""Trusted bootstrap, embedded verbatim in both native scripts. Linux/root only."""
import base64
import contextlib
import fcntl
import hashlib
import importlib
import json
import os
from pathlib import Path
import re
import signal
import stat
import subprocess
import sys
import tempfile
import time
import urllib.parse
import urllib.request

PUBLIC_KEY = '-----BEGIN PUBLIC KEY-----\nMIIBojANBgkqhkiG9w0BAQEFAAOCAY8AMIIBigKCAYEAyq8p95fmcKVyOfUAar4l\nLsztlRIx9rsEYJzoYlT0RTacFlYfGGfBt3w8KL5AgvCeFuqdrB48NVw7bWM+x5pj\ntGKHRk61UHP01vinZlp6tyQ9gCeKtCtmok9anFssdtGI48cFurY3q7lOrQalmEyb\nJ+Cr9+Oy9egLLE8Lbv/32j/qbQoUgmuHC9Tnn25g1G1Dn5N9UgxZgexDGKdtqli2\ndg2qb7J39nRcbbWioKbeJSAKef0ATz0RSygoG4974Ibn8naC2DkDtS7nT4DAmcts\nw25VNLZ3P2iZIgHQwqYBWFy8llrFNpK/e/NDYHUh7ctDxiHrBEsfrQZevKjmXqdI\nAd24aBbQxM1sCGoDYOfue+ridalr4TftDYxa8o//hLir2g9e9NmWHQDkEA2tG9Ne\nLs+GC20/eE4byS5zXXFiMjfvRmUNAEjD2O9r/ELtmDCrAJGKneZYJeWwswvhTn4Q\nlE1Xk3bXQIyAua3THx9/XODJ1bUgGaQf5JyrWPhwdGznAgMBAAE=\n-----END PUBLIC KEY-----\n'
BASELINE = {'sequence': 0, 'revision': '041d91ac33e8c74d8fcf97d30a73cef5910e6528', 'files': {'configure.py': '7be23f9abbeb83427b1a138a97e9fd1fdbb0c0ad357d4d02f604699a2a24dffe', 'policy.py': '116d6f22dacae66f8e146ebe701e030693db0ec94bef37999a24e6950d21f39d', 'nginx_edit.py': '93adcf667d3bab494dea93681524c6828dab9d5c36b0c9147229e02e7433360e', 'ban.py': 'e0aab32f1386a2180288f748c4f0643f9c252c5ddb2dedbf06befc4e36fd6a60', 'example-policy.json': 'aee6fd651ceb6441acce6dc6b510e504d7127b2bba1ce84ca361655590c615b0', 'cloudflare-ips.json': 'e6be6df199bc4ad607b6bcd7273a62a4884e5aa841786db1d8d5a2284f573179', 'legacy-jails.local': '6fd82147b99201beebe7b1a983f146e5c23ade7f9454ac883830848b7f753e30'}}
FILES = ('configure.py', 'policy.py', 'nginx_edit.py', 'ban.py',
         'example-policy.json', 'cloudflare-ips.json', 'legacy-jails.local')
CHANNEL = 'raw.githubusercontent.com/kejilion/nginx/main/waf/channels/stable-v1.json'
ACTIONS = {'plan','apply','configure','doctor','rollback','refresh-ips','retire-jails',
           'existing-filters','rotation','trust-cloudflare','ban-preflight','ban-install',
           'ban-clear','ban-remove','cf-on','cf-off','status','ban-status'}

def unique(pairs):
    result = {}
    for key, value in pairs:
        if key in result: raise ValueError('Duplicate JSON key')
        result[key] = value
    return result

def decode(data):
    return json.loads(data, object_pairs_hook=unique)

def digest(data):
    return hashlib.sha256(data).hexdigest()

def sync(path):
    fd=os.open(path,os.O_RDONLY | os.O_NOFOLLOW)
    try: os.fsync(fd)
    finally: os.close(fd)

def sync_changes(paths,root):
    parents=set()
    for path in paths:
        if path.exists():sync(path)
        for parent in path.parents:
            if parent.exists():parents.add(parent)
            if parent==root:break
    for parent in sorted(parents,key=lambda p:len(p.parts),reverse=True):sync(parent)

def safe(path, directory=False, missing=False):
    path = Path(path).absolute()
    for parent in reversed(path.parents):
        if not parent.exists():
            if missing: continue
            raise ValueError('Missing trusted parent')
        info = parent.lstat()
        if not stat.S_ISDIR(info.st_mode) or info.st_uid != 0 or info.st_mode & 0o022:
            raise ValueError('Untrusted parent: '+str(parent))
    try: info = path.lstat()
    except FileNotFoundError:
        if missing: return
        raise
    kind = stat.S_ISDIR if directory else stat.S_ISREG
    if not kind(info.st_mode) or info.st_uid != 0 or info.st_mode & 0o022:
        raise ValueError('Untrusted path: '+str(path))

def read(path, limit=32768):
    safe(path)
    with open(path, 'rb') as stream: data = stream.read(limit+1)
    if len(data) > limit: raise ValueError('File exceeds budget')
    return data

def atomic(path, data):
    safe(path, missing=True)
    fd, temporary = tempfile.mkstemp(prefix='.state-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data); stream.flush(); os.fsync(stream.fileno())
        os.replace(temporary, path)
        fd = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try: os.fsync(fd)
        finally: os.close(fd)
    finally:
        if os.path.exists(temporary): os.unlink(temporary)

def verify(envelope, fresh=False):
    if envelope == {'baseline': True}: return BASELINE
    if not isinstance(envelope, dict) or set(envelope) != {'payload','signature'}:
        raise ValueError('Invalid signed envelope')
    raw = base64.b64decode(envelope['payload'], validate=True)
    signature = base64.b64decode(envelope['signature'], validate=True)
    if len(raw) > 8192 or len(signature) != 384: raise ValueError('Invalid signature size')
    # OpenSSL verifies raw bytes before any publisher-controlled field is used.
    with tempfile.TemporaryDirectory(prefix='waf-signature-') as tmp:
        key = Path(tmp)/'public.pem'; sig = Path(tmp)/'signature'
        key.write_text(PUBLIC_KEY); sig.write_bytes(signature)
        result = subprocess.run(['openssl','dgst','-sha256','-verify',str(key),
                                 '-signature',str(sig)], input=raw, capture_output=True, timeout=10)
    if result.returncode: raise ValueError('Shared package signature rejected')
    manifest = decode(raw)
    if set(manifest) != {'schema','api','channel','sequence','revision','files','issued','expires'}:
        raise ValueError('Invalid manifest fields')
    for key in ('schema','api','sequence','issued','expires'):
        if type(manifest[key]) is not int: raise ValueError('Invalid manifest number')
    if manifest['schema'] != 1 or manifest['api'] != 1 or manifest['channel'] != 'stable':
        raise ValueError('Incompatible shared package; update the native script')
    if not 1 <= manifest['sequence'] <= 2**53: raise ValueError('Invalid sequence')
    if not isinstance(manifest['revision'], str) or not re.fullmatch('[a-f0-9]{40}', manifest['revision']):
        raise ValueError('Invalid source revision')
    files = manifest['files']
    if not isinstance(files, dict) or set(files) != set(FILES): raise ValueError('Invalid package file list')
    if any(not isinstance(v,str) or not re.fullmatch('[a-f0-9]{64}',v) for v in files.values()):
        raise ValueError('Invalid package digest')
    if not 0 < manifest['expires']-manifest['issued'] <= 366*86400:
        raise ValueError('Invalid publication lifetime')
    if fresh and not manifest['issued']-300 <= time.time() < manifest['expires']:
        raise ValueError('Expired or future shared package manifest')
    return manifest

def fetch(url, limit):
    class HTTPSOnly(urllib.request.HTTPRedirectHandler):
        def redirect_request(self, req, fp, code, msg, headers, url):
            if urllib.parse.urlsplit(url).scheme != 'https': raise ValueError('HTTPS required')
            return super().redirect_request(req,fp,code,msg,headers,url)
    if urllib.parse.urlsplit(url).scheme != 'https': raise ValueError('HTTPS required')
    def expired(*args): raise TimeoutError('Download deadline exceeded')
    previous = signal.signal(signal.SIGALRM, expired)
    signal.alarm(45)
    try:
        request = urllib.request.Request(url, headers={'User-Agent': 'kejilion-sh/waf-package'})
        with urllib.request.build_opener(HTTPSOnly()).open(request, timeout=10) as response:
            data = response.read(limit+1)
        if len(data) > limit: raise ValueError('Download exceeds budget')
        return data
    finally:
        signal.alarm(0); signal.signal(signal.SIGALRM, previous)

class Runtime:
    def __init__(self, root, prefix='https://'):
        self.root = Path(root).absolute()
        self.control = self.root/'config/waf'
        self.state_path = self.control/'package-state.json'
        self.prefix = prefix

    @contextlib.contextmanager
    def locked(self, create):
        safe(self.control, directory=True, missing=True)
        if not self.control.exists():
            if not create:
                yield; return
            self.control.mkdir(parents=True, mode=0o700)
        lock = self.control/'package-update.lock'
        safe(lock, missing=True)
        fd = os.open(lock, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
        try:
            # Bounded contention, never wait indefinitely behind another updater.
            deadline = time.monotonic()+30
            while True:
                try: fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB); break
                except BlockingIOError:
                    if time.monotonic() >= deadline: raise ValueError('Shared package operation busy')
                    time.sleep(.1)
            yield
        finally: os.close(fd)

    def state(self):
        if not self.state_path.exists():
            safe(self.state_path, missing=True)
            return {'active':{'baseline':True}, 'previous':None, 'maximum':0, 'latest':None, 'pending':None}
        state = decode(read(self.state_path))
        if set(state) != {'active','previous','maximum','latest','pending'}:
            raise ValueError('Invalid package state')
        if type(state['maximum']) is not int or not 0 <= state['maximum'] <= 2**53:
            raise ValueError('Invalid update watermark')
        if state['pending'] is not None and (not isinstance(state['pending'], str) or len(state['pending'])>512):
            raise ValueError('Invalid recovery state')
        for field in ('active','previous','latest'):
            if state[field] is not None:
                if verify(state[field])['sequence'] > state['maximum']: raise ValueError('Invalid update watermark')
        return state

    def save(self, state):
        atomic(self.state_path, (json.dumps(state, sort_keys=True)+'\n').encode())

    def remote(self, state):
        envelope = decode(fetch(self.prefix+CHANNEL, 16384))
        # The local baseline sentinel is never accepted from the network.
        if set(envelope) != {'payload','signature'}: raise ValueError('Unsigned channel')
        manifest = verify(envelope, fresh=True)
        if manifest['sequence'] < state['maximum']: raise ValueError('Shared package replay rejected')
        if manifest['sequence'] == state['maximum'] and envelope != state['latest']:
            raise ValueError('Shared package sequence was reused')
        return envelope

    def package(self, envelope, download=False):
        manifest = verify(envelope)
        base = self.control/'packages'
        directory = base/manifest['revision']
        safe(directory, directory=True, missing=True)
        if directory.exists():
            if set(p.name for p in directory.iterdir()) != set(FILES): raise ValueError('Unknown package cache file')
            for name in FILES:
                if digest(read(directory/name, 2097152)) != manifest['files'][name]:
                    raise ValueError('Shared package cache hash mismatch')
            return directory
        if not download: raise ValueError('共享 WAF 包尚未导入；状态查询不会自动下载')
        base.mkdir(parents=True, exist_ok=True, mode=0o700)
        entries = list(base.iterdir())
        if len(entries) >= 16: raise ValueError('WAF cache limit reached; archive an inactive version first')
        total = 0
        for entry in entries:
            safe(entry, directory=True)
            if not re.fullmatch('[a-f0-9]{40}',entry.name): raise ValueError('Unknown cache directory')
            for item in entry.iterdir():
                if item.name not in FILES: raise ValueError('Unknown cache file')
                safe(item); total += item.stat().st_size
        if total > 48*1024*1024: raise ValueError('WAF cache byte limit reached')
        # One reserved, bounded staging directory outside the legacy seven-file
        # package cache. A killed downloader can be retried under the same lock.
        stage=self.control/'package-download-stage'
        safe(stage,directory=True,missing=True)
        stage.mkdir(mode=0o700,exist_ok=True)
        for item in stage.iterdir():
            if item.name not in FILES: raise ValueError('Unknown staging file; preserve for inspection')
            safe(item)
            if item.stat().st_size>2097152: raise ValueError('Staging file exceeds budget')
        for item in stage.iterdir():item.unlink()
        for name in FILES:
            url = self.prefix+'raw.githubusercontent.com/kejilion/nginx/'+manifest['revision']+'/waf/'+name
            data = fetch(url, 2097152)
            if digest(data) != manifest['files'][name]: raise ValueError('Downloaded package hash mismatch')
            path=stage/name
            with path.open('xb') as stream:
                os.fchmod(stream.fileno(),0o600);stream.write(data);stream.flush();os.fsync(stream.fileno())
        sync(stage)
        # All bytes are verified and durable before candidate execution/state commit.
        os.rename(stage,directory);sync(base);sync(self.control)
        return self.package(envelope)

    def execute(self, envelope, args):
        directory = self.package(envelope)
        with os.fdopen(os.dup(3),'rb') as source:
            result = subprocess.run([sys.executable,'-E','-s','-B',str(directory/'configure.py'),
                                     '--root',str(self.root),*args], stdin=source, capture_output=True, timeout=180)
        if result.returncode:
            raise ValueError('WAF '+args[0]+' failed: '+result.stderr.decode(errors='replace')[-1500:])
        return result.stdout

    def module(self, envelope):
        directory = self.package(envelope)
        sys.dont_write_bytecode = True
        for name in ('configure','policy','nginx_edit','ban'): sys.modules.pop(name,None)
        sys.path.insert(0,str(directory))
        try: return importlib.import_module('configure')
        finally: sys.path.pop(0)

    def doctor(self, module):
        config = module.policy.validate(module.load_json(self.control/'policy.json'))
        module.execute('docker','exec',config['container'],'nginx','-t')
        status = module.configured_status(self.root,config)
        if not status['methodOverride']['synchronized'] or not status['requestSemantics']['synchronized']:
            raise ValueError('Managed configuration is not synchronized')

    def restore(self, state, module=None):
        module = module or self.module(state['active'])
        backup = Path(state['pending'])
        records = module.load_json(backup/'manifest.json')['files']
        # After a crash another root manager may have acted. Do not overwrite
        # changes that match neither the recorded preimage nor candidate bytes.
        for relative, item in records.items():
            path = self.root/relative
            if path.resolve()!=path or self.root not in path.parents: raise ValueError('Unsafe recovery path')
            before = base64.b64decode(item['before']) if item['before'] is not None else None
            actual = digest(read(path,2097152)) if path.exists() else None
            if actual not in {digest(before) if before is not None else None,item['afterSha256']}:
                raise ValueError('Recovery conflict: '+relative)
        module.restore(self.root,backup,verify=False)
        config = module.policy.validate(module.load_json(self.control/'policy.json'))
        module.execute('docker','exec',config['container'],'nginx','-t')
        module.reload_nginx(config['container'])
        self.doctor(module)
        sync_changes([self.root/relative for relative in records],self.root)
        state['pending'] = None
        self.save(state)

    def activate(self, state, target):
        self.package(target, download=True)
        self.package(state['active'], download=True)
        old = self.module(state['active'])
        # Same lock as existing configure/manage/ban writers. The outer package
        # lock is always acquired first; no child process waits on our own lock.
        with old.locked(self.control/'install.lock',timeout=30):
            # Freeze legacy adoption under the very same lock as activation.
            if not self.state_path.exists():self.check_legacy_baseline(state,old)
            candidate = self.module(target)
            config = candidate.policy.validate(candidate.load_json(self.control/'policy.json'))
            config = candidate.reconcile_native_switch(self.root,config)
            changes,_ = candidate.make_plan(self.root,config)
            # Snapshot exact preimages, including newly created files, before
            # executing the candidate transaction. It uses the existing format.
            backup = old.snapshot(self.root,changes,'package-update')
            sync(backup/'manifest.json')
            for parent in (backup,*backup.parents):
                sync(parent)
                if parent==self.root:break
            state['pending'] = str(backup)
            self.save(state)
            try:
                candidate.apply(self.root,config,respect_native=True,lock_held=True)
                self.doctor(candidate)
                sync_changes(changes,self.root)
                previous=state['previous'] if target==state['active'] else state['active']
                new = dict(state,active=target,previous=previous,pending=None)
                self.save(new)
            except Exception:
                try: self.restore(state,old)
                except Exception as recovery:
                    raise ValueError('Update failed and recovery incomplete; run package-recover: '+str(recovery))
                raise
        return verify(target)['revision']

    def check_legacy_baseline(self,state,module):
        config=module.policy.validate(module.load_json(self.control/'policy.json'))
        config=module.reconcile_native_switch(self.root,config)
        changes,_=module.make_plan(self.root,config)
        if any(not p.exists() or p.read_bytes()!=data for p,data in changes.items()):
            raise ValueError('Older/unidentified installation: first run k web waf apply, then package-update')

    def run(self, command, args):
        read_only = command in {'cached','package-status'} or (command=='run' and args and args[0] in {'status','ban-status'})
        with self.locked(not read_only):
            state = self.state()
            if command=='package-status':
                return json.dumps({'active':verify(state['active'])['revision'],
                                   'previous':verify(state['previous'])['revision'] if state['previous'] else None,
                                   'maximumSequence':state['maximum'],'recoveryRequired':bool(state['pending'])})
            if command=='package-recover':
                if not state['pending']: return 'No interrupted package update'
                module = self.module(state['active'])
                with module.locked(self.control/'install.lock',timeout=30): self.restore(state,module)
                return 'Previous shared package restored'
            if state['pending']: raise ValueError('Interrupted update; run k web waf package-recover')
            if command=='package-check':
                target = self.remote(state)
                return json.dumps({'available':verify(target)['revision'], 'active':verify(state['active'])['revision']})
            if command=='package-update':
                if not (self.control/'policy.json').exists(): raise ValueError('Install/configure WAF before hot update')
                self.package(state['active'],download=True)
                target = self.remote(state)
                state['maximum'] = verify(target)['sequence']; state['latest'] = target
                # activate persists the replay floor with pending before code can
                # change live resources, under the common installation lock.
                if target == state['active']:
                    self.activate(state,target)
                    return 'Shared package current; managed files reconciled'
                return 'Shared package updated: '+self.activate(state,target)
            if command=='package-rollback':
                if state['previous'] is None: raise ValueError('No previous shared package')
                return 'Shared package rolled back: '+self.activate(state,state['previous'])
            if command not in {'prepare','cached','run'}: raise ValueError('Unknown package command')
            if command=='run' and (not args or args[0] not in ACTIONS): raise ValueError('Action-first WAF syntax required')
            # Adopt existing installations without changing their rules. New installs
            # require a fresh signed channel, not a silent stale fallback.
            if not self.state_path.exists() and not (self.control/'policy.json').exists() and not read_only:
                target = self.remote(state)
                self.package(target, download=True)
                state.update(active=target, maximum=verify(target)['sequence'], latest=target)
                self.save(state)
            directory = self.package(state['active'], download=not read_only)
            if command in {'prepare','cached'}: return str(directory)
            return self.execute(state['active'], args).decode()

def main():
    if os.geteuid()!=0 or sys.version_info<(3,11): raise ValueError('Root and Python 3.11+ required')
    # Arguments are supplied only by the trusted shell wrapper; no remote URL is executable input.
    if len(sys.argv)<4: raise ValueError('Missing runtime arguments')
    print(Runtime(sys.argv[1],sys.argv[2]).run(sys.argv[3],sys.argv[4:]))

if __name__=='__main__':
    try: main()
    except Exception as error:
        print('Shared WAF: '+str(error),file=sys.stderr); raise SystemExit(1)
