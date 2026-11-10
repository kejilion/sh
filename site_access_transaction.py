"""Linux file transaction primitive for the shared site access adapter.

The caller supplies a previously validated directory and basename. An atomic
exchange leaves the prior inode available until validation and reload succeed.
"""
from __future__ import annotations

import ctypes
import fcntl
import hashlib
import os
import secrets
import stat


class TransactionError(RuntimeError):
    pass


class Conflict(TransactionError):
    pass


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def _read(dirfd, name, limit):
    fd = os.open(name, os.O_RDONLY | os.O_CLOEXEC | os.O_NOFOLLOW | os.O_NONBLOCK, dir_fd=dirfd)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_size > limit:
            raise TransactionError("target is not an accepted regular file")
        chunks, total = [], 0
        while True:
            block = os.read(fd, min(65536, limit + 1 - total))
            if not block:
                break
            chunks.append(block)
            total += len(block)
            if total > limit:
                raise TransactionError("target exceeds size limit")
        return fd, info, b"".join(chunks)
    except BaseException:
        os.close(fd)
        raise


def _same_inode(dirfd, name, info):
    try:
        current = os.stat(name, dir_fd=dirfd, follow_symlinks=False)
    except FileNotFoundError:
        return False
    return stat.S_ISREG(current.st_mode) and (current.st_dev, current.st_ino) == (info.st_dev, info.st_ino)


def _matches(dirfd, name, info, expected_hash, limit):
    try:
        fd, current, contents = _read(dirfd, name, limit)
    except (OSError, TransactionError):
        return False
    try:
        return ((current.st_dev, current.st_ino) == (info.st_dev, info.st_ino)
                and digest(contents) == expected_hash)
    finally:
        os.close(fd)


def _exchange(dirfd, left, right):
    libc = ctypes.CDLL(None, use_errno=True)
    rename = libc.renameat2
    rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    rename.restype = ctypes.c_int
    if rename(dirfd, os.fsencode(left), dirfd, os.fsencode(right), 2) != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error))


def rename_noreplace(dirfd, left, right):
    libc = ctypes.CDLL(None, use_errno=True)
    rename = libc.renameat2
    rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
    rename.restype = ctypes.c_int
    if rename(dirfd, os.fsencode(left), dirfd, os.fsencode(right), 1) != 0:
        error = ctypes.get_errno()
        raise OSError(error, os.strerror(error))


def replace_existing(directory: str | int, name: str, expected_sha256: str, transform,
                     validate, reload_config, *, limit: int = 2 << 20, before_exchange=None):
    """Replace one existing file, validate and reload, or safely restore it.

    ``transform`` is called with prior bytes and returns the candidate bytes.
    Both callbacks must raise on failure. Concurrent external writes are
    detected using the displaced inode and its content, never overwritten.
    """
    if not name or name in (".", "..") or "/" in name or "\x00" in name:
        raise TransactionError("invalid target name")
    if len(expected_sha256) != 64 or any(c not in "0123456789abcdef" for c in expected_sha256):
        raise TransactionError("invalid resource version")
    dirfd = (os.dup(directory) if isinstance(directory, int) else
             os.open(directory, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW | os.O_CLOEXEC))
    if not stat.S_ISDIR(os.fstat(dirfd).st_mode):
        os.close(dirfd)
        raise TransactionError("target directory is unavailable")
    lockfd, originalfd, tempfd = None, None, None
    temporary, temp_info, swapped, retain = None, None, False, False
    displaced_info, displaced_hash, reload_attempted = None, None, False
    try:
        lockfd = os.open('.kpanel-site-access.lock', os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600, dir_fd=dirfd)
        lockinfo = os.fstat(lockfd)
        if not stat.S_ISREG(lockinfo.st_mode) or lockinfo.st_uid != os.geteuid() or lockinfo.st_mode & 0o022:
            raise TransactionError("unsafe transaction lock")
        fcntl.flock(lockfd, fcntl.LOCK_EX)
        originalfd, original_info, original = _read(dirfd, name, limit)
        if digest(original) != expected_sha256:
            raise Conflict("target changed")
        candidate = transform(original)
        if not isinstance(candidate, bytes) or len(candidate) > limit:
            raise TransactionError("invalid candidate")
        if candidate == original:
            return digest(original)
        temporary = '.site-access-' + secrets.token_hex(16)
        tempfd = os.open(temporary, os.O_RDWR | os.O_CREAT | os.O_EXCL | os.O_NOFOLLOW | os.O_CLOEXEC, 0o600, dir_fd=dirfd)
        # Preserve the staged inode identity even if metadata setup fails.
        temp_info = os.fstat(tempfd)
        os.fchown(tempfd, original_info.st_uid, original_info.st_gid)
        os.fchmod(tempfd, stat.S_IMODE(original_info.st_mode))
        for attribute in os.listxattr(originalfd):
            os.setxattr(tempfd, attribute, os.getxattr(originalfd, attribute))
        view = memoryview(candidate)
        while view:
            count = os.write(tempfd, view)
            if count <= 0:
                raise TransactionError("candidate write failed")
            view = view[count:]
        os.fsync(tempfd)
        temp_info = os.fstat(tempfd)
        if before_exchange is not None:
            before_exchange()
        _exchange(dirfd, temporary, name)
        swapped = True
        os.fsync(dirfd)
        try:
            backupfd, backup_info, backup = _read(dirfd, temporary, limit)
        except (OSError, TransactionError):
            retain = True
            raise TransactionError("unable to verify displaced file; backup retained as " + temporary)
        os.close(backupfd)
        displaced_info, displaced_hash = backup_info, digest(backup)
        if ((backup_info.st_dev, backup_info.st_ino) != (original_info.st_dev, original_info.st_ino)
                or digest(backup) != expected_sha256):
            raise Conflict("target changed during publication")
        if not _matches(dirfd, name, temp_info, digest(candidate), limit):
            retain = True
            raise Conflict("candidate changed during publication; backup retained as " + temporary)
        validate()
        if not _matches(dirfd, name, temp_info, digest(candidate), limit):
            retain = True
            raise Conflict("candidate changed during validation; backup retained as " + temporary)
        reload_attempted = True
        reload_config()
        if not _matches(dirfd, name, temp_info, digest(candidate), limit):
            retain = True
            raise Conflict("candidate changed during reload; backup retained as " + temporary)
        if not _matches(dirfd, temporary, original_info, expected_sha256, limit):
            retain = True
            raise Conflict("backup changed during reload; retained as " + temporary)
        os.unlink(temporary, dir_fd=dirfd)
        temporary = None
        os.fsync(dirfd)
        return digest(candidate)
    except BaseException as failure:
        if swapped and not retain:
            # If an external process wins a race, retain both artifacts rather
            # than replacing a newer file or deleting a foreign inode.
            if (displaced_info is not None and _matches(dirfd, name, temp_info, digest(candidate), limit)
                    and _matches(dirfd, temporary, displaced_info, displaced_hash, limit)):
                try:
                    _exchange(dirfd, temporary, name)
                    os.fsync(dirfd)
                    if reload_attempted:
                        reload_config()
                except BaseException as rollback_error:
                    retain = True
                    raise TransactionError("restore or reload failed; candidate retained as " + temporary) from rollback_error
            else:
                retain = True
                raise TransactionError("concurrent change; backup retained as " + temporary) from failure
        raise
    finally:
        if temporary and not retain and temp_info is not None and _same_inode(dirfd, temporary, temp_info):
            os.unlink(temporary, dir_fd=dirfd)
        for fd in (tempfd, originalfd, lockfd):
            if fd is not None:
                os.close(fd)
        os.close(dirfd)
