"""Validate Zsh history before startup, preserving evidence before recovery."""

from datetime import datetime
import fcntl
import os
from pathlib import Path
import subprocess
import sys
import tempfile
import time


def acquire(lock, operation):
    deadline = time.monotonic() + 5
    while True:
        try:
            operation(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            return
        except BlockingIOError:
            if time.monotonic() >= deadline:
                raise RuntimeError('history is busy; original left untouched')
            time.sleep(0.02)


def atomic_write(path, data):
    fd, name = tempfile.mkstemp(prefix='.history-', dir=path.parent)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
            stream.flush()
            os.fsync(stream.fileno())
        os.replace(name, path)
        directory = os.open(path.parent, os.O_RDONLY | os.O_DIRECTORY)
        try:
            os.fsync(directory)
        finally:
            os.close(directory)
    finally:
        Path(name).unlink(missing_ok=True)


def readable(data, directory, zsh):
    if b'\0' in data:
        return False
    fd, name = tempfile.mkstemp(prefix='.history-check-', dir=directory)
    try:
        with os.fdopen(fd, 'wb') as stream:
            stream.write(data)
        result = subprocess.run(
            [zsh, '-f', '-c', 'HISTSIZE=100000; fc -R "$1"', 'history-check', name],
            capture_output=True,
            timeout=10,
        )
        return result.returncode == 0 and not result.stderr
    finally:
        Path(name).unlink(missing_ok=True)


def snapshot(history, data, zsh):
    # Keep two distinct valid snapshots; an empty file must not erase them.
    if not data:
        return
    latest = history.with_name('history.last-good')
    previous = history.with_name('history.previous-good')
    old = latest.read_bytes() if latest.exists() else b''
    if old == data:
        return
    if old and readable(old, history.parent, zsh):
        atomic_write(previous, old)
    atomic_write(latest, data)


def guard(history, zsh):
    history.parent.mkdir(mode=0o700, parents=True, exist_ok=True)
    history.parent.chmod(0o700)
    lock_fd = os.open(history.parent / '.history-guard.lock', os.O_CREAT | os.O_RDWR, 0o600)
    with os.fdopen(lock_fd, 'r+b') as lock:
        acquire(lock, fcntl.flock)
        # Zsh also uses an fcntl write lock. Retry if another shell replaced
        # the inode while we were waiting for its lock.
        for _ in range(5):
            fd = os.open(history, os.O_CREAT | os.O_RDWR | os.O_NOFOLLOW, 0o600)
            with os.fdopen(fd, 'r+b') as stream:
                acquire(stream, fcntl.lockf)
                current = history.stat()
                opened = os.fstat(stream.fileno())
                if (opened.st_dev, opened.st_ino) != (current.st_dev, current.st_ino):
                    continue
                if opened.st_uid != os.getuid():
                    raise RuntimeError('history belongs to another user')
                os.fchmod(stream.fileno(), 0o600)
                original = stream.read()
                if readable(original, history.parent, zsh):
                    snapshot(history, original, zsh)
                    return

                # Remove only NUL bytes. Preserve UTF-8, multiline commands,
                # timestamps and every other byte; never use `strings`.
                recovered = original.replace(b'\0', b'')
                method = 'removed invalid NUL bytes'
                if not recovered or not readable(recovered, history.parent, zsh):
                    recovered = None
                    for name in ('history.last-good', 'history.previous-good'):
                        backup = history.with_name(name)
                        if backup.exists():
                            candidate = backup.read_bytes()
                            if candidate and readable(candidate, history.parent, zsh):
                                recovered = candidate
                                method = 'restored ' + name
                                break
                    if recovered is None:
                        raise RuntimeError('no safe repair or readable backup; original left untouched')
                if not recovered.endswith(b'\n'):
                    recovered += b'\n'
                saved = history.with_name('history.corrupt-' + datetime.now().strftime('%Y%m%d-%H%M%S-%f'))
                atomic_write(saved, original)
                atomic_write(history, recovered)
                snapshot(history, recovered, zsh)
                print(f'zsh: history recovered ({method}); original: {saved}', file=sys.stderr)
                return
        raise RuntimeError('history changed repeatedly during startup; retry in a new terminal')


if __name__ == '__main__':
    try:
        guard(Path(sys.argv[1]), sys.argv[2])
    except (OSError, RuntimeError, subprocess.SubprocessError) as error:
        print(f'zsh: history guard: {error}', file=sys.stderr)
        sys.exit(1)
