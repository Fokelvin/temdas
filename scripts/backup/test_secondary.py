import contextlib
import hashlib
import io
import json
from pathlib import Path
import tempfile
import types
import unittest
from unittest.mock import patch

import backup as b
import secondary as s


class CopyTests(unittest.TestCase):
    def setUp(self):
        self.tmp = tempfile.TemporaryDirectory()
        self.addCleanup(self.tmp.cleanup)
        self.root = Path(self.tmp.name) / 'primary'
        self.target = Path(self.tmp.name) / 'secondary'
        (self.root / 'archives').mkdir(parents=True)
        self.target.mkdir()
        self.installation = 'a' * 32
        self.config = {'data_dir': str(self.root), 'external_dir': str(self.target), 'daily_keep': 7, 'weekly_keep': 4}
        self.record = self.make_record('20261028T000000Z', '12345678', '2026-10-28T00:00:00+00:00')
        self.state([self.record])

    def make_record(self, stamp, suffix, utc):
        name = f'temdas-prod-{stamp}-{suffix}.cms'
        data = (b'encrypted-fixture-' + stamp.encode()) * 300
        (self.root / 'archives' / name).write_bytes(data)
        return {'file': name, 'utc': utc, 'sha256': hashlib.sha256(data).hexdigest(), 'bytes': len(data), 'installation': self.installation}

    def state(self, records):
        (self.root / 'state.json').write_text(json.dumps({'installation': self.installation, 'records': records}))

    def sync(self, records=None):
        with patch.object(s, 'target_directory', return_value=self.target):
            return s.sync(self.config, self.root, records or [self.record], b.digest, b.retention_keep)

    def test_copy_hash_atomic_publication_and_deduplication(self):
        self.assertEqual(self.sync()['copied'], 1)
        self.assertEqual(b.digest(self.target / self.record['file']), self.record['sha256'])
        self.assertEqual(self.sync()['reused'], 1)
        self.assertEqual(len(list(self.target.glob('*.cms'))), 1)
        self.assertEqual(list(self.target.glob('*.partial')), [])
        index = (self.target / s.INDEX).read_text()
        self.assertNotIn('password', index)
        self.assertNotIn('private.pem', index)
        self.assertNotIn('recovery_key', index)
        self.assertEqual({p.name for p in self.target.iterdir()}, {self.record['file'], s.INDEX})

    def test_unmounted_or_readonly_or_wrong_drive_is_rejected(self):
        c = {'external_dir': '/mnt/f/TEMDAS/backups'}
        cases = [None, {'target': '/mnt/f', 'source': 'F:\\', 'fstype': '9p', 'options': 'ro'},
                 {'target': '/mnt/f', 'source': 'C:\\', 'fstype': '9p', 'options': 'rw'},
                 {'target': '/mnt/f', 'source': '/dev/sda', 'fstype': 'ext4', 'options': 'rw'}]
        for item in cases:
            result = types.SimpleNamespace(returncode=0 if item else 1, stdout=json.dumps({'filesystems': [item] if item else []}))
            with patch.object(s.subprocess, 'run', return_value=result), self.assertRaisesRegex(s.SecondaryError, 'external_mount_unavailable'):
                s.target_directory(c)

    def test_copy_action_failure_never_contacts_database_or_changes_primary(self):
        before = (self.root / 'state.json').read_bytes()
        with patch.object(s, 'target_directory', side_effect=s.SecondaryError('external_mount_unavailable')), patch.object(b, 'SQL') as sql, contextlib.redirect_stdout(io.StringIO()):
            with self.assertRaisesRegex(b.BackupError, 'external_mount_unavailable'):
                b.copy_existing(self.config)
            sql.assert_not_called()
        self.assertEqual((self.root / 'state.json').read_bytes(), before)
        self.assertEqual(b.digest(self.root / 'archives' / self.record['file']), self.record['sha256'])
        self.assertEqual(list(self.target.iterdir()), [])

    def test_copy_concurrency_uses_primary_lock(self):
        with (self.root / 'backup.lock').open('a') as lock:
            b.fcntl.flock(lock, b.fcntl.LOCK_EX | b.fcntl.LOCK_NB)
            with patch.object(s, 'sync') as sync, contextlib.redirect_stdout(io.StringIO()) as output:
                b.copy_existing(self.config)
            sync.assert_not_called()
            self.assertIn('skipped_concurrent', output.getvalue())

    def test_interrupted_copy_removes_only_its_temporary_file(self):
        unknown = self.target / 'unknown.file'
        unknown.write_bytes(b'preserve')
        def interrupt(src, dst, size):
            dst.write(b'partial')
            raise OSError('fixture')
        with patch.object(s.shutil, 'copyfileobj', side_effect=interrupt), self.assertRaisesRegex(s.SecondaryError, 'external_copy_io'):
            self.sync()
        self.assertEqual(unknown.read_bytes(), b'preserve')
        self.assertEqual({p.name for p in self.target.iterdir()}, {'unknown.file'})

    def test_disappearing_mount_prevents_publication(self):
        with patch.object(s, 'target_directory', side_effect=[self.target, s.SecondaryError('external_mount_unavailable')]), self.assertRaises(s.SecondaryError):
            s.sync(self.config, self.root, [self.record], b.digest, b.retention_keep)
        self.assertEqual(list(self.target.iterdir()), [])

    def test_existing_different_file_is_never_overwritten(self):
        target = self.target / self.record['file']
        target.write_bytes(b'old-preserved')
        with self.assertRaisesRegex(s.SecondaryError, 'external_archive_collision'):
            self.sync()
        self.assertEqual(target.read_bytes(), b'old-preserved')

    def test_existing_unknown_index_is_never_overwritten(self):
        p = self.target / s.INDEX
        p.write_text('{"format":"unrelated"}')
        with self.assertRaisesRegex(s.SecondaryError, 'external_index_collision'):
            self.sync()
        self.assertEqual(p.read_text(), '{"format":"unrelated"}')
        self.assertFalse((self.target / self.record['file']).exists())

    def test_source_corruption_is_rejected(self):
        (self.root / 'archives' / self.record['file']).write_bytes(b'corrupt')
        with self.assertRaisesRegex(s.SecondaryError, 'external_source_integrity'):
            self.sync()
        self.assertEqual(list(self.target.iterdir()), [])

    def test_retention_preserves_unknown_files_and_latest_valid(self):
        self.config.update(daily_keep=1, weekly_keep=0)
        self.sync()
        unknown = self.target / 'unknown.cms'
        unknown.write_bytes(b'foreign')
        new = self.make_record('20261128T000000Z', '87654321', '2026-11-28T00:00:00+00:00')
        self.state([self.record, new])
        metrics = self.sync([new])
        self.assertEqual(metrics['removed'], 1)
        self.assertFalse((self.target / self.record['file']).exists())
        self.assertEqual(b.digest(self.target / new['file']), new['sha256'])
        self.assertEqual(unknown.read_bytes(), b'foreign')
        self.assertTrue((self.root / 'archives' / self.record['file']).exists())

    def test_identical_preexisting_backup_is_reused_but_never_owned_for_deletion(self):
        self.config.update(daily_keep=1, weekly_keep=0)
        (self.target / self.record['file']).write_bytes((self.root / 'archives' / self.record['file']).read_bytes())
        self.sync()
        new = self.make_record('20261128T000000Z', '87654321', '2026-11-28T00:00:00+00:00')
        self.state([self.record, new])
        self.sync([new])
        self.assertTrue((self.target / self.record['file']).exists())

    def test_publish_does_not_overwrite_in_a_race(self):
        (self.target / 'temporary').write_bytes(b'new')
        (self.target / 'existing').write_bytes(b'old')
        import os
        fd = os.open(self.target, os.O_RDONLY | os.O_DIRECTORY)
        try:
            with self.assertRaises(OSError):
                s.publish(fd, 'temporary', 'existing')
        finally:
            os.close(fd)
        self.assertEqual((self.target / 'existing').read_bytes(), b'old')


if __name__ == '__main__':
    unittest.main()
