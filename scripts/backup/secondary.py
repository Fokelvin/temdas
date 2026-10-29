"""Encrypted-only secondary storage on the explicitly approved Windows F: drive.

No database connection or credential/key transfer. File operations use a pinned
NTFS directory fd, so an absent/unmounted drive cannot fall back to Linux paths.
"""
import ctypes
import datetime as dt
import errno
import hashlib
import json
import os
from pathlib import Path
import re
import shutil
import stat
import subprocess
import uuid

FORMAT = 'temdas-encrypted-copy-v1'
INDEX = 'temdas-copy-index.json'
NAME = re.compile(r'^temdas-prod-\d{8}T\d{6}Z-[0-9a-f]{8}\.cms$')


class SecondaryError(Exception):
    pass


def target_directory(c):
    target = Path(c['external_dir'])
    mount = Path('/mnt/f')
    if target != mount / 'TEMDAS/backups':
        raise SecondaryError('external_target_not_approved')
    result = subprocess.run(['findmnt', '--json', '--mountpoint', str(mount), '-o', 'TARGET,SOURCE,FSTYPE,OPTIONS'],
                            capture_output=True, text=True, timeout=10)
    try:
        entries = json.loads(result.stdout)['filesystems']
        entry = entries[0] if len(entries) == 1 else {}
    except (ValueError, KeyError, IndexError):
        entry = {}
    if (result.returncode or entry.get('target') != str(mount)
            or not str(entry.get('source', '')).upper().startswith('F:')
            or entry.get('fstype') not in ('9p', 'drvfs')
            or 'rw' not in entry.get('options', '').split(',')):
        raise SecondaryError('external_mount_unavailable')
    for path in (mount, mount / 'TEMDAS', target):
        if path.is_symlink() or not path.is_dir():
            raise SecondaryError('external_directory_unavailable')
    if target.resolve() != target:
        raise SecondaryError('external_directory_symlink')
    return target


def open_regular(directory, name):
    fd = os.open(name, os.O_RDONLY | os.O_NOFOLLOW, dir_fd=directory)
    if not stat.S_ISREG(os.fstat(fd).st_mode):
        os.close(fd)
        raise SecondaryError('external_not_regular_file')
    return fd


def hash_at(directory, name):
    fd = open_regular(directory, name)
    with os.fdopen(fd, 'rb') as stream:
        h = hashlib.sha256()
        for block in iter(lambda: stream.read(1024 * 1024), b''):
            h.update(block)
        return h.hexdigest()


def publish(directory, temporary, final):
    # Linux renameat2 preserves any preexisting target, even across a race.
    libc = ctypes.CDLL(None, use_errno=True)
    rename = getattr(libc, 'renameat2', None)
    if rename is not None:
        rename.argtypes = [ctypes.c_int, ctypes.c_char_p, ctypes.c_int, ctypes.c_char_p, ctypes.c_uint]
        if rename(directory, os.fsencode(temporary), directory, os.fsencode(final), 1) == 0:
            return
        error = ctypes.get_errno()
        if error not in (errno.ENOSYS, errno.EINVAL, errno.EOPNOTSUPP):
            raise OSError(error, 'atomic_publish')
    # Atomic link + unlink is a no-overwrite fallback, never a plain overwrite.
    os.link(temporary, final, src_dir_fd=directory, dst_dir_fd=directory, follow_symlinks=False)
    os.unlink(temporary, dir_fd=directory)


def record_data(record):
    if (not NAME.fullmatch(record['file']) or not re.fullmatch('[0-9a-f]{64}', record['sha256'])
            or not isinstance(record['bytes'], int) or record['bytes'] < 4096
            or not re.fullmatch('[0-9a-f]{32}', record['installation'])):
        raise SecondaryError('external_record_invalid')
    stamp = dt.datetime.fromisoformat(record['utc'])
    if stamp.tzinfo is None:
        raise SecondaryError('external_record_invalid')
    return {k: record[k] for k in ('file', 'utc', 'sha256', 'bytes', 'installation')}


def read_index(directory, installation):
    try:
        fd = open_regular(directory, INDEX)
    except FileNotFoundError:
        return {'format': FORMAT, 'installation': installation, 'records': []}
    with os.fdopen(fd, 'rb') as f:
        raw = f.read(1024 * 1024 + 1)
    if len(raw) > 1024 * 1024:
        raise SecondaryError('external_index_invalid')
    try:
        data = json.loads(raw)
        if data['format'] != FORMAT or data['installation'] != installation:
            raise ValueError()
        seen = set()
        for record in data['records']:
            record_data(record)
            if record['file'] in seen or record['installation'] != installation or type(record['owned']) is not bool:
                raise ValueError()
            seen.add(record['file'])
        return data
    except (ValueError, KeyError, TypeError):
        raise SecondaryError('external_index_collision') from None


def write_index(directory, index):
    temporary = '.temdas-index-' + uuid.uuid4().hex + '.partial'
    try:
        fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600, dir_fd=directory)
        with os.fdopen(fd, 'w') as f:
            json.dump(index, f, sort_keys=True, indent=2)
            f.flush()
            os.fsync(f.fileno())
        # Only the recognized, installation-owned index is replaced.
        os.replace(temporary, INDEX, src_dir_fd=directory, dst_dir_fd=directory)
    finally:
        try:
            os.unlink(temporary, dir_fd=directory)
        except FileNotFoundError:
            pass


def sync(c, root, records, digest, retention_keep):
    target = target_directory(c)
    directory = os.open(target, os.O_RDONLY | os.O_DIRECTORY | os.O_NOFOLLOW)
    copied = reused = removed = 0
    try:
        state = json.loads((root / 'state.json').read_text())
        installation = state['installation']
        index = read_index(directory, installation)
        known = {r['file']: r for r in index['records']}
        for source_record in records:
            record = record_data(source_record)
            if record['installation'] != installation:
                raise SecondaryError('external_record_invalid')
            source = root / 'archives' / record['file']
            if source.is_symlink() or digest(source) != record['sha256']:
                raise SecondaryError('external_source_integrity')
            try:
                existing = hash_at(directory, record['file'])
            except FileNotFoundError:
                existing = None
            if existing is not None:
                if existing != record['sha256']:
                    raise SecondaryError('external_archive_collision')
                record['owned'] = known.get(record['file'], {}).get('owned', False)
                reused += 1
            else:
                if shutil.disk_usage(target).free < record['bytes'] * 2 + 16 * 1024 * 1024:
                    raise SecondaryError('external_insufficient_space')
                temporary = '.' + record['file'] + '.' + uuid.uuid4().hex + '.partial'
                try:
                    fd = os.open(temporary, os.O_WRONLY | os.O_CREAT | os.O_EXCL, 0o600, dir_fd=directory)
                    with source.open('rb') as src, os.fdopen(fd, 'wb') as dst:
                        shutil.copyfileobj(src, dst, 1024 * 1024)
                        dst.flush()
                        os.fsync(dst.fileno())
                    if hash_at(directory, temporary) != record['sha256']:
                        raise SecondaryError('external_copy_integrity')
                    # Recheck the mount before publication; pinned fd still
                    # cannot write to the Linux filesystem if it disappears.
                    target_directory(c)
                    publish(directory, temporary, record['file'])
                    if hash_at(directory, record['file']) != record['sha256']:
                        raise SecondaryError('external_copy_integrity')
                    record['owned'] = True
                    copied += 1
                finally:
                    try:
                        os.unlink(temporary, dir_fd=directory)
                    except FileNotFoundError:
                        pass
            known[record['file']] = record
            # Record ownership immediately, before any retention deletion.
            index['records'] = list(known.values())
            write_index(directory, index)
        valid = []
        for record in known.values():
            try:
                matching = hash_at(directory, record['file']) == record['sha256']
            except FileNotFoundError:
                continue
            if not matching:
                raise SecondaryError('external_retention_integrity')
            valid.append(record)
        keep = retention_keep(valid, c['daily_keep'], c['weekly_keep'])
        for record in valid:
            if record['file'] not in keep and record['owned']:
                target_directory(c)
                # Never delete unknown, modified or unowned preexisting files.
                if hash_at(directory, record['file']) != record['sha256']:
                    raise SecondaryError('external_retention_integrity')
                os.unlink(record['file'], dir_fd=directory)
                del known[record['file']]
                removed += 1
        index['records'] = [r for r in valid if r['file'] in known]
        index['updated_utc'] = dt.datetime.now(dt.timezone.utc).isoformat()
        write_index(directory, index)
        return {'copied': copied, 'reused': reused, 'removed': removed, 'verified': len(index['records'])}
    except OSError:
        raise SecondaryError('external_copy_io') from None
    finally:
        os.close(directory)
