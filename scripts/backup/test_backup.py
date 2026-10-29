import contextlib
import datetime as dt
import importlib.util
import io
import json
import os
from pathlib import Path
import subprocess
import tarfile
import tempfile
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location('backup', Path(__file__).with_name('backup.py'))
b = importlib.util.module_from_spec(spec)
spec.loader.exec_module(b)


class SafetyTests(unittest.TestCase):
    def test_source_tls_and_readonly_cannot_be_overridden_by_environment(self):
        c = dict(pg_lib='/tools', host='db.prod', port=5432, database='postgres', user='postgres', password_file='/private/pgpass', ca_file='/private/ca')
        with patch.dict(os.environ, {'PGSSLMODE': 'disable', 'PGPASSWORD': 'NEVER_PRINT', 'PGSERVICE': 'dev', 'SUPABASE_SECRET_KEY': 'NEVER_PRINT'}):
            e = b.pg_env(c)
        self.assertEqual(e['PGSSLMODE'], 'verify-full')
        self.assertIn('extra_float_digits=3', e['PGOPTIONS'])
        self.assertIn('default_transaction_read_only=on', e['PGOPTIONS'])
        self.assertNotIn('PGPASSWORD', e)
        self.assertNotIn('PGSERVICE', e)
        self.assertNotIn('SUPABASE_SECRET_KEY', e)
        local = b.pg_env(c, False)
        self.assertNotIn('PGHOST', local)
        self.assertNotIn('PGPASSFILE', local)

    def test_private_file_requires_owner_only_permissions(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'key'
            p.write_text('fixture')
            p.chmod(0o644)
            with self.assertRaises(b.BackupError):
                b.private_file(p)
            p.chmod(0o600)
            b.private_file(p)
            link = Path(d) / 'link'
            link.symlink_to(p)
            with self.assertRaises(b.BackupError):
                b.private_file(link)

    def test_dev_source_rejected_before_any_database_command(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'config.json'
            p.write_text(json.dumps({'project_ref': 'ddzwawlamjnzwjjxuava', 'host': 'db.dev'}))
            p.chmod(0o600)
            with self.assertRaisesRegex(b.BackupError, 'source_not_prod'):
                b.load_config(p)

    def test_retention_keeps_newest_seven_days_and_four_weeks(self):
        now = dt.datetime(2026, 10, 28, tzinfo=dt.timezone.utc)
        records = [{'file': str(i), 'utc': (now - dt.timedelta(days=i)).isoformat()} for i in range(50)]
        keep = b.retention_keep(records)
        self.assertTrue(set(str(i) for i in range(7)).issubset(keep))
        self.assertIn('0', keep)
        self.assertLessEqual(len(keep), 11)
        self.assertNotIn('49', keep)

    def test_same_day_manual_backups_are_preserved_and_last_never_deleted(self):
        records = [{'file': 'first', 'utc': '2026-10-28T00:00:00+00:00'}, {'file': 'second', 'utc': '2026-10-28T01:00:00+00:00'}]
        self.assertEqual(b.retention_keep(records), {'first', 'second'})
        self.assertEqual(b.retention_keep(records, 0, 0), {'second'})

    def test_dump_failure_preserves_last_valid_and_foreign_archive(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'archives').mkdir()
            old = root / 'archives/valid.cms'
            foreign = root / 'archives/preexisting.backup'
            old.write_bytes(b'old-valid')
            foreign.write_bytes(b'foreign')
            state = {'installation': 'fixture', 'records': [{'file': 'valid.cms', 'utc': '2026-01-01T00:00:00+00:00', 'installation': 'fixture'}]}
            b.atomic_json(root / 'state.json', state)
            c = dict(data_dir=d, pg_lib='/lib', host='db.prod', port=5432, user='postgres', database='postgres', password_file='/private/p', ca_file='/ca', pg_bin='/bin')
            class SQL:
                def __init__(self, *args):
                    pass
                def query(self, query):
                    return 170011 if 'server_version' in query else 'snapshot-fixture' if 'export_snapshot' in query else True
                def close(self):
                    pass
            baseline = {'tables': {'public.fixture': {}, 'auth.users': {}}, 'structure': {}}
            with patch.object(b, 'SQL', SQL), patch.object(b, 'inventory', return_value=baseline), patch.object(b, 'command', side_effect=b.BackupError('pg_dump')):
                with self.assertRaises(b.BackupError):
                    b.backup(c)
            self.assertEqual(old.read_bytes(), b'old-valid')
            self.assertEqual(foreign.read_bytes(), b'foreign')
            self.assertEqual(json.loads((root / 'state.json').read_text()), state)
            self.assertEqual(list((root / 'archives').glob('*.partial')), [])

    def test_concurrent_run_never_opens_a_source_connection(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            with (root / 'backup.lock').open('a') as lock:
                b.fcntl.flock(lock, b.fcntl.LOCK_EX | b.fcntl.LOCK_NB)
                with patch.object(b, 'SQL') as sql, contextlib.redirect_stdout(io.StringIO()) as out:
                    b.backup({'data_dir': d})
                sql.assert_not_called()
                self.assertIn('skipped_concurrent', out.getvalue())


    def test_success_records_missed_days_and_preserves_previous_backup(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'archives').mkdir()
            old = root / 'archives/previous.cms'
            old.write_bytes(b'previous-valid')
            state = {'installation': 'fixture', 'records': [{'file': 'previous.cms', 'utc': '2026-10-24T00:00:00+00:00', 'installation': 'fixture', 'sha256': b.digest(old)}]}
            b.atomic_json(root / 'state.json', state)
            c = dict(data_dir=d, pg_lib='/lib', host='db.prod', port=5432, user='postgres', database='postgres', password_file='/private/p', ca_file='/ca', pg_bin='/bin', external_dir=None, daily_keep=7, weekly_keep=4)
            class SQL:
                def __init__(self, *args):
                    pass
                def query(self, query):
                    return 170011 if 'server_version' in query else 'snapshot-fixture' if 'export_snapshot' in query else True
                def close(self):
                    pass
            def cmd(args, stage, env=None, stdout=None):
                if stage == 'pg_dump':
                    Path(next(a[7:] for a in args if a.startswith('--file='))).write_bytes(b'PGDMP' + b'x' * 5000)
                if stage == 'roles_dump':
                    stdout.write(b'fixture-role-metadata' * 20)
                return b''
            def encrypt(c, payload, target):
                target.write_bytes(b'encrypted-fixture' * 1000)
            with patch.object(b, 'SQL', SQL), patch.object(b, 'inventory', return_value={'tables': {'public.fixture': {}, 'auth.users': {}}, 'structure': {}}), patch.object(b, 'command', side_effect=cmd), patch.object(b, 'encrypt', side_effect=encrypt), patch.object(b, 'utcnow', return_value=dt.datetime(2026, 10, 28, tzinfo=dt.timezone.utc)), contextlib.redirect_stdout(io.StringIO()) as out:
                b.backup(c)
            self.assertEqual(old.read_bytes(), b'previous-valid')
            self.assertIn('"missed_days": 3', out.getvalue())
            self.assertIn('backup_success', out.getvalue())
            self.assertEqual(len(json.loads((root / 'state.json').read_text())['records']), 2)

    def test_tar_rejects_traversal_and_duplicate_or_link_entries(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d) / 'bad.tar'
            for names in [['../database.dump', 'roles.sql', 'manifest.json'], ['database.dump', 'roles.sql', 'manifest.json', 'manifest.json']]:
                with tarfile.open(p, 'w') as tar:
                    for name in names:
                        m = tarfile.TarInfo(name)
                        tar.addfile(m, io.BytesIO())
                with self.assertRaises(b.BackupError):
                    b.extract_payload(p, Path(d))

    def test_arbitrary_exception_text_never_reaches_logs(self):
        with patch('sys.argv', ['backup.py', 'run']), patch.object(b, 'load_config', side_effect=ValueError('SECRET_FIXTURE')), contextlib.redirect_stdout(io.StringIO()) as out:
            self.assertEqual(b.main(), 1)
        self.assertNotIn('SECRET_FIXTURE', out.getvalue())
        self.assertIn('internal_failure', out.getvalue())

    def test_cms_authenticated_encryption_and_tamper_rejection(self):
        with tempfile.TemporaryDirectory() as d:
            p = Path(d)
            subprocess.run(['openssl', 'req', '-x509', '-newkey', 'rsa:2048', '-nodes', '-days', '1', '-subj', '/CN=fixture', '-keyout', str(p / 'key'), '-out', str(p / 'cert')], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL, check=True)
            (p / 'key').chmod(0o600)
            (p / 'input').write_bytes(b'PRIVATE_FIXTURE' * 100)
            c = dict(recipient_cert=str(p / 'cert'), recovery_key=str(p / 'key'))
            b.encrypt(c, p / 'input', p / 'cipher')
            self.assertNotIn(b'PRIVATE_FIXTURE', (p / 'cipher').read_bytes())
            b.decrypt(c, p / 'cipher', p / 'output')
            self.assertEqual((p / 'input').read_bytes(), (p / 'output').read_bytes())
            data = bytearray((p / 'cipher').read_bytes())
            data[-20] ^= 1
            (p / 'cipher').write_bytes(data)
            with self.assertRaises(b.BackupError):
                b.decrypt(c, p / 'cipher', p / 'invalid-output')


if __name__ == '__main__':
    unittest.main()
