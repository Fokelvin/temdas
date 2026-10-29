import datetime as dt
import json
from pathlib import Path
import subprocess
import tempfile
import unittest
from unittest.mock import patch

import validate as v

V1 = '20261027000000000'
V2 = '20261028000000000'


def history_sql(version=V2):
    return f'''INSERT INTO "serverpod_migrations" ("module", "version", "timestamp")
      VALUES ('temdas_backend', '{version}', now()) ON CONFLICT ("module")
      DO UPDATE SET "version" = '{version}', "timestamp" = now();'''


class SafetyTests(unittest.TestCase):
    def test_generated_latest_migration_is_accepted(self):
        self.assertIn('access_exclusive_lock_and_default_review',
                      v.inspect_sql((v.MIGRATIONS / '20261009000123093-convite-cooldown' / 'migration.sql').read_text()))

    def test_additive_sql_and_fixed_history_upsert(self):
        sql = 'BEGIN; ALTER TABLE "fixture" ADD COLUMN "extra" text;' + history_sql() + 'COMMIT;'
        self.assertTrue(v.inspect_sql(sql))

    def test_destructive_statements_blocked(self):
        for sql in ('DROP TABLE x', 'TRUNCATE x', 'DELETE FROM x',
                    'ALTER TABLE x DROP COLUMN y', 'ALTER TABLE x ALTER COLUMN y TYPE int',
                    'ALTER TABLE x ALTER COLUMN y SET NOT NULL', 'ALTER TABLE x DISABLE TRIGGER ALL'):
            with self.subTest(sql=sql), self.assertRaises(v.ValidationError):
                v.inspect_sql('BEGIN;' + sql + ';COMMIT;')

    def test_privileges_network_and_dynamic_code_blocked(self):
        for sql in ('COPY x TO PROGRAM \'bad\'', 'CREATE EXTENSION http', 'GRANT ALL ON x TO y',
                    "DO $$ BEGIN NULL; END $$", 'CREATE FUNCTION x() RETURNS int LANGUAGE sql AS \'SELECT 1\'',
                    "ALTER TABLE x ADD COLUMN y int DEFAULT arbitrary_function()",
                    'BEGIN', 'COMMIT', 'ROLLBACK', 'SET search_path=auth', '\\! echo x'):
            with self.subTest(sql=sql), self.assertRaises(v.ValidationError):
                v.inspect_sql('BEGIN;' + sql + ';COMMIT;')

    def test_arbitrary_history_or_business_dml_blocked(self):
        for sql in ('UPDATE x SET y=1', "INSERT INTO x VALUES ('secret')",
                    history_sql().replace("now()", "evil()"),
                    history_sql().replace("'temdas_backend'", "'secret@example.invalid'")):
            with self.subTest(sql=sql), self.assertRaises(v.ValidationError):
                v.inspect_sql('BEGIN;' + sql.rstrip(';') + ';COMMIT;')

    def test_mixed_schema_security_clauses_and_data_copy_blocked(self):
        for sql in ('ALTER TABLE x ADD COLUMN y int, ENABLE ROW LEVEL SECURITY',
                    'ALTER TABLE x ADD COLUMN y int, SET SCHEMA auth',
                    'ALTER TABLE x ADD COLUMN y int, FORCE ROW LEVEL SECURITY',
                    'CREATE TABLE x AS TABLE auth.users', 'CREATE TABLE x AS SELECT * FROM auth.users'):
            with self.subTest(sql=sql), self.assertRaises(v.ValidationError):
                v.inspect_sql('BEGIN;' + sql + ';COMMIT;')

    def test_nested_comments_and_string_keywords_are_not_commands(self):
        sql = "BEGIN; /* DROP /* nested */ TABLE x */ ALTER TABLE x ADD COLUMN y text DEFAULT 'DROP TABLE;';COMMIT;"
        self.assertTrue(v.inspect_sql(sql))

    def test_malformed_lexing_and_transaction_wrappers_blocked(self):
        for sql in ("BEGIN; /* comment", "BEGIN; SELECT 'unfinished", 'BEGIN; SELECT "unfinished',
                    "BEGIN; ALTER TABLE x ADD COLUMN y text DEFAULT E'a\\nb';COMMIT;",
                    'ALTER TABLE x ADD COLUMN y int;', 'BEGIN; COMMIT', 'BEGIN;COMMIT;SELECT 1;'):
            with self.subTest(sql=sql), self.assertRaises(v.ValidationError):
                v.inspect_sql(sql)

    def test_pending_uses_registry_order_from_known_baseline(self):
        self.assertEqual(v.pending([V1, V2], V1), [V2])
        self.assertEqual(v.pending([V1, V2], V2), [])

    def test_real_registry_header_and_directories_agree(self):
        registry = v.load_registry()
        self.assertIn('20261009000123093-convite-cooldown', registry)
        self.assertEqual(v.pending(registry, registry[-1]), [])

    def test_unregistered_migration_directory_is_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            root = Path(d)
            (root / 'migration_registry.txt').write_text('### generated\n\n' + V1 + '\n')
            (root / V1).mkdir()
            (root / V2).mkdir()
            with patch.object(v, 'MIGRATIONS', root), self.assertRaisesRegex(v.ValidationError, 'directory_mismatch'):
                v.load_registry()

    def test_source_fingerprint_uses_dart_workspace_lockfile(self):
        self.assertRegex(v.source_fingerprint(), '^[a-f0-9]{64}$')

    def test_unknown_empty_or_malformed_history_blocked(self):
        for registry, installed in (([V1, V2], None), ([V1, V2], 'unknown'),
                                    ([V1, V1], V1), ([V2, V1], V1), (['../../escape'], V1)):
            with self.subTest(registry=registry), self.assertRaises(v.ValidationError):
                v.pending(registry, installed)

    def test_docker_connection_failure_is_categorized_without_output(self):
        result = subprocess.CompletedProcess([], 1, b'sensitive', b'credentials and details')
        with patch.object(v.subprocess, 'run', return_value=result):
            with self.assertRaisesRegex(v.ValidationError, '^docker_failed$'):
                v.docker('info')

    def test_command_strips_remote_and_secret_environment(self):
        with patch.dict(v.os.environ, {'PGPASSWORD': 'fixture', 'DOCKER_HOST': 'tcp://remote', 'HTTPS_PROXY': 'secret'}):
            with patch.object(v.subprocess, 'run', return_value=subprocess.CompletedProcess([], 0, b'', b'')) as run:
                v.docker('info')
                env = run.call_args.kwargs['env']
                self.assertFalse({'PGPASSWORD', 'DOCKER_HOST', 'HTTPS_PROXY'} & set(env))
                self.assertIn('--host=unix:///var/run/docker.sock', run.call_args.args[0])

    def test_container_cleanup_refuses_wrong_identity(self):
        db = v.IsolatedDatabase()
        db.cid = 'a' * 64
        info = dict(Id=db.cid, Name='/' + db.name,
                    Config={'Labels': {v.LABEL: 'wrong'}, 'Image': v.IMAGE})
        with patch.object(v, 'docker', return_value=json.dumps([info]).encode()) as docker:
            with self.assertRaises(v.ValidationError):
                db.__exit__(None, None, None)
            self.assertFalse(any(c.args[0] == 'rm' for c in docker.call_args_list))

    def test_sprint_missing_or_changed_objects_blocked(self):
        inv = {'structure': {'indexes': [['public', 'sprints', n, 'CREATE UNIQUE INDEX fixture WHERE status=active'] for n in sorted(v.CUSTOM)],
                             'constraints': [['public', 'sprints', 'sprints_periodos_sem_sobreposicao_por_usuario', 'EXCLUDE USING gist fixture', True]], 'triggers': []}}
        v.sprint_check(inv, inv)
        changed = json.loads(json.dumps(inv))
        changed['structure']['indexes'][0][-1] = 'changed predicate'
        with self.assertRaises(v.ValidationError):
            v.sprint_check(inv, changed)
        with self.assertRaisesRegex(v.ValidationError, 'baseline_sprint_custom_objects_missing'):
            v.sprint_check({'structure': {'indexes': [], 'constraints': [], 'triggers': []}})

    def backup_fixture(self, directory, age=0):
        root = Path(directory)
        (root / 'archives').mkdir()
        external = root / 'external'
        external.mkdir()
        filename = 'temdas-prod-20261028T000000Z-1234abcd.cms'
        data = b'ciphertext fixture only'
        (root / 'archives' / filename).write_bytes(data)
        (external / filename).write_bytes(data)
        now = dt.datetime(2026, 10, 28, tzinfo=dt.timezone.utc)
        record = dict(file=filename, bytes=len(data), sha256=v.b.digest(root / 'archives' / filename),
                      utc=(now - dt.timedelta(seconds=age)).isoformat(), installation='fixture')
        state = dict(installation='fixture', records=[record])
        (root / 'state.json').write_text(json.dumps(state))
        (external / v.secondary.INDEX).write_text(json.dumps(state))
        return dict(data_dir=str(root)), now, external

    def test_backup_and_second_copy_validated(self):
        with tempfile.TemporaryDirectory() as d:
            c, now, external = self.backup_fixture(d)
            with patch.object(v.secondary, 'target_directory', return_value=external):
                self.assertTrue(v.checked_backup(c, now)[0].exists())

    def test_stale_future_or_missing_backup_blocked(self):
        for age in (86401, -1):
            with tempfile.TemporaryDirectory() as d:
                c, now, _ = self.backup_fixture(d, age)
                with self.assertRaisesRegex(v.ValidationError, 'freshness'):
                    v.checked_backup(c, now)
        with tempfile.TemporaryDirectory() as d:
            Path(d, 'state.json').write_text('{"records":[]}')
            with self.assertRaisesRegex(v.ValidationError, 'backup_missing'):
                v.checked_backup({'data_dir': d})

    def test_missing_unmounted_or_corrupt_second_copy_blocked(self):
        with tempfile.TemporaryDirectory() as d:
            c, now, external = self.backup_fixture(d)
            with patch.object(v.secondary, 'target_directory', side_effect=v.secondary.SecondaryError('external_mount_unavailable')):
                with self.assertRaises(v.secondary.SecondaryError):
                    v.checked_backup(c, now)
            archive = next(external.glob('*.cms'))
            archive.write_bytes(b'corrupted')
            with patch.object(v.secondary, 'target_directory', return_value=external):
                with self.assertRaisesRegex(v.ValidationError, 'integrity'):
                    v.checked_backup(c, now)

    def test_sensitive_errors_not_rendered_by_cli(self):
        # Only internal fixed categories are passed through. OS/library exceptions
        # become a fixed category; stdout never includes arbitrary exception text.
        import contextlib
        import io
        output = io.StringIO()
        with patch.object(v.b, 'load_config', side_effect=OSError('sensitive example')), patch.object(v.sys, 'argv', ['validate.py']):
            with contextlib.redirect_stdout(output):
                self.assertEqual(v.main(), 1)
        self.assertNotIn('sensitive example', output.getvalue())
        self.assertFalse(json.loads(output.getvalue())['production_authorized'])

    def test_concurrent_rehearsal_is_blocked(self):
        with v.rehearsal_lock():
            with self.assertRaisesRegex(v.ValidationError, 'validation_already_running'):
                with v.rehearsal_lock():
                    self.fail('concurrent entry')

    def test_fingerprint_ignores_docker_mount_order(self):
        def response(*args):
            if args[0] == 'ps':
                return b'container\n'
            if args[0] == 'inspect':
                mounts = [{'Destination': '/one'}, {'Destination': '/two'}]
                if reverse[0]:
                    mounts.reverse()
                return json.dumps([{'Id': 'container', 'Config': {}, 'HostConfig': {}, 'Mounts': mounts}]).encode()
            return b''
        reverse = [False]
        with patch.object(v, 'docker', side_effect=response):
            before = v.resource_fingerprint()
            reverse[0] = True
            self.assertEqual(v.resource_fingerprint(), before)


if __name__ == '__main__':
    unittest.main()
