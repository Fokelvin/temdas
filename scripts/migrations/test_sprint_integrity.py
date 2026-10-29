"""Pinned corrective migration tests. Real SQL runs only in owned Docker tmpfs."""
import copy
import json
import os
from pathlib import Path
import shutil
import tempfile
import unittest
from unittest.mock import patch

import validate as v


class CorrectionGateTests(unittest.TestCase):
    def test_reviewed_artifacts_match_exact_hashes(self):
        v.correction_artifacts()

    def test_modified_sql_or_metadata_cannot_use_exception(self):
        for name in v.SPRINT_ARTIFACTS:
            with self.subTest(name=name), tempfile.TemporaryDirectory() as directory:
                target = Path(directory) / v.SPRINT_CORRECTION
                shutil.copytree(v.MIGRATIONS / v.SPRINT_CORRECTION, target)
                with (target / name).open('a') as file:
                    file.write('\n')
                with patch.object(v, 'MIGRATIONS', Path(directory)):
                    with self.assertRaisesRegex(v.ValidationError, 'hash_mismatch'):
                        v.correction_artifacts()

    def test_renamed_correction_is_not_a_generic_sql_allowlist(self):
        sql = (v.MIGRATIONS / v.SPRINT_CORRECTION / 'migration.sql').read_text()
        with self.assertRaises(v.ValidationError):
            v.inspect_sql(sql)

    def test_extra_artifact_rejected(self):
        with tempfile.TemporaryDirectory() as directory:
            target = Path(directory) / v.SPRINT_CORRECTION
            shutil.copytree(v.MIGRATIONS / v.SPRINT_CORRECTION, target)
            (target / 'unreviewed.sql').write_text('SELECT 1;')
            with patch.object(v, 'MIGRATIONS', Path(directory)):
                with self.assertRaisesRegex(v.ValidationError, 'artifacts_unexpected'):
                    v.correction_artifacts()

    def test_managed_target_json_changes_only_project_version(self):
        for name in ('definition.json', 'definition_project.json'):
            before = json.loads((v.MIGRATIONS / v.SPRINT_BASELINE / name).read_text())
            after = json.loads((v.MIGRATIONS / v.SPRINT_CORRECTION / name).read_text())
            for module in after['installedModules']:
                if module['module'] == 'temdas_backend':
                    self.assertEqual(module['version'], v.SPRINT_CORRECTION)
                    module['version'] = v.SPRINT_BASELINE
            self.assertEqual(after, before)


@unittest.skipUnless(os.environ.get('TEMDAS_MIGRATION_DOCKER_TESTS') == '1', 'explicit local Docker opt-in required')
class CorrectionDockerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lock = v.rehearsal_lock()
        cls.lock.__enter__()
        cls.addClassCleanup(cls.lock.__exit__, None, None, None)
        cls.fingerprint = v.resource_fingerprint()
        cls.manager = v.IsolatedDatabase()
        cls.db = cls.manager.__enter__()
        cls.sql = (v.MIGRATIONS / v.SPRINT_CORRECTION / 'migration.sql').read_text()
        cls.definition = json.loads((v.MIGRATIONS / v.SPRINT_CORRECTION / 'definition.json').read_text())

    @classmethod
    def tearDownClass(cls):
        cls.manager.__exit__(None, None, None)
        if v.resource_fingerprint() != cls.fingerprint:
            raise AssertionError('original Docker resources changed')

    def setUp(self):
        self.db.execute('DROP SCHEMA public CASCADE; DROP SCHEMA IF EXISTS extensions CASCADE; CREATE SCHEMA public;')
        self.db.execute((v.MIGRATIONS / v.SPRINT_BASELINE / 'definition.sql').read_text())
        self.db.execute('''INSERT INTO public.usuarios ("supabaseUserId", "createdAt")
            VALUES ('synthetic-owner-one', '2026-01-01'), ('synthetic-owner-two', '2026-01-01');''')
        self.before = v.b.inventory(self.db)

    def insert(self, name, start, end, status='planejada', owner=1):
        # Synthetic test constants only; never production identifiers or tokens.
        return f'''INSERT INTO public.sprints ("usuarioId", nome, "nomeNormalizado", "dataInicio", "dataFim", status)
          VALUES ({owner}, '{name}', '{name}', '{start}', '{end}', '{status}');'''

    def migrate(self):
        return v.rehearsal(self.db, [v.SPRINT_CORRECTION], self.before)

    def assert_rollback(self, before):
        self.assertEqual(v.b.inventory(self.db), before)
        self.assertFalse(self.db.query("SELECT to_json(EXISTS(SELECT 1 FROM pg_extension WHERE extname='btree_gist'))"))
        self.assertEqual(v.history(self.db)['temdas_backend'], v.SPRINT_BASELINE)

    def test_upgrade_preserves_all_data_and_existing_schema(self):
        self.db.execute(self.insert('baseline', '2026-01-01', '2026-01-05'))
        self.before = v.b.inventory(self.db)
        self.assertEqual(len(self.migrate()), 1)
        v.correction_delta(self.db, self.before, v.b.inventory(self.db))
        self.assertEqual(v.history(self.db)['temdas_backend'], v.SPRINT_CORRECTION)

    def test_clean_install_matches_backend_target_and_custom_objects(self):
        self.db.execute('DROP SCHEMA public CASCADE; CREATE SCHEMA public;')
        self.db.execute((v.MIGRATIONS / v.SPRINT_CORRECTION / 'definition.sql').read_text())
        v.check_definition(self.db, self.definition)
        v.correction_final(self.db)
        v.sprint_check(v.b.inventory(self.db))

    def test_duplicate_active_rejected_even_with_disjoint_dates(self):
        self.migrate()
        self.db.execute(self.insert('first', '2026-01-01', '2026-01-05', 'ativa'))
        with self.assertRaisesRegex(v.ValidationError, '23505'):
            self.db.execute(self.insert('second', '2026-02-01', '2026-02-05', 'ativa'))

    def test_overlap_and_inclusive_boundary_rejected_for_all_protected_statuses(self):
        self.migrate()
        self.db.execute(self.insert('first', '2026-01-01', '2026-01-05'))
        for i, status in enumerate(('planejada', 'ativa', 'concluida')):
            with self.subTest(status=status), self.assertRaisesRegex(v.ValidationError, '23P01'):
                self.db.execute(self.insert('overlap' + str(i), '2026-01-05', '2026-01-08', status))

    def test_different_owners_cancelled_and_adjacent_periods_are_allowed(self):
        self.migrate()
        self.db.execute(self.insert('one', '2026-01-01', '2026-01-05', 'ativa'))
        self.db.execute(self.insert('two', '2026-01-01', '2026-01-05', 'ativa', owner=2))
        self.db.execute(self.insert('cancelled', '2026-01-01', '2026-01-05', 'cancelada'))
        self.db.execute(self.insert('adjacent', '2026-01-06', '2026-01-10'))
        self.assertEqual(self.db.query('SELECT to_json(count(*)) FROM public.sprints'), 4)

    def test_existing_active_conflict_rolls_back_without_changing_data(self):
        self.db.execute(self.insert('one', '2026-01-01', '2026-01-05', 'ativa'))
        self.db.execute(self.insert('two', '2026-02-01', '2026-02-05', 'ativa'))
        before = v.b.inventory(self.db)
        with self.assertRaisesRegex(v.ValidationError, '23505'):
            v.rehearsal(self.db, [v.SPRINT_CORRECTION], before)
        self.assert_rollback(before)

    def test_existing_overlap_rolls_back_extension_and_unique_index(self):
        self.db.execute(self.insert('one', '2026-01-01', '2026-01-05'))
        self.db.execute(self.insert('two', '2026-01-05', '2026-01-08'))
        before = v.b.inventory(self.db)
        with self.assertRaisesRegex(v.ValidationError, '23P01'):
            v.rehearsal(self.db, [v.SPRINT_CORRECTION], before)
        self.assert_rollback(before)

    def test_unexpected_partial_schema_is_blocked_before_execution(self):
        self.db.execute('CREATE UNIQUE INDEX sprints_uma_ativa_por_usuario_idx ON public.sprints ("usuarioId");')
        before = v.b.inventory(self.db)
        with self.assertRaisesRegex(v.ValidationError, 'unexpected_initial_objects'):
            v.rehearsal(self.db, [v.SPRINT_CORRECTION], before)
        self.assertEqual(v.b.inventory(self.db), before)

    def test_wrong_history_and_bundled_migrations_cannot_use_exception(self):
        for versions in ([v.SPRINT_CORRECTION, 'unreviewed'], ['renamed']):
            with self.assertRaisesRegex(v.ValidationError, 'baseline_or_sequence'):
                v.correction_preflight(self.db, self.before, versions)
        self.db.execute("UPDATE public.serverpod_migrations SET version='unexpected' WHERE module='temdas_backend';")
        with self.assertRaisesRegex(v.ValidationError, 'baseline_or_sequence'):
            v.correction_preflight(self.db, self.before, [v.SPRINT_CORRECTION])

    def test_migration_sql_itself_rejects_unknown_baseline(self):
        self.db.execute("UPDATE public.serverpod_migrations SET version='unexpected' WHERE module='temdas_backend';")
        before = v.b.inventory(self.db)
        with self.assertRaisesRegex(v.ValidationError, 'P0001'):
            self.db.execute(self.sql)
        self.assertEqual(v.b.inventory(self.db), before)

    def test_repeated_execution_is_blocked_without_changes(self):
        self.migrate()
        before = v.b.inventory(self.db)
        with self.assertRaisesRegex(v.ValidationError, 'P0001'):
            self.db.execute(self.sql)
        self.assertEqual(v.b.inventory(self.db), before)

    def test_extension_in_wrong_schema_is_not_relocated_or_dropped(self):
        self.db.execute('CREATE EXTENSION btree_gist WITH SCHEMA public;')
        before = v.b.inventory(self.db)
        with self.assertRaisesRegex(v.ValidationError, 'P0001'):
            self.db.execute(self.sql)
        self.assertEqual(v.b.inventory(self.db), before)

    def test_non_superuser_with_supabase_equivalent_required_privileges(self):
        # Local synthetic role only. No remote grants or credentials.
        self.db.execute('''CREATE ROLE migration_operator NOLOGIN NOSUPERUSER;
          GRANT CREATE ON DATABASE validation TO migration_operator;
          CREATE SCHEMA extensions;
          GRANT USAGE, CREATE ON SCHEMA extensions, public TO migration_operator;
          ALTER TABLE public.sprints OWNER TO migration_operator;
          ALTER TABLE public.serverpod_migrations OWNER TO migration_operator;''')
        self.db.execute('SET ROLE migration_operator;\n' + self.sql)
        v.correction_delta(self.db, self.before, v.b.inventory(self.db))
        v.check_definition(self.db, self.definition)

    def test_missing_extension_privilege_rolls_back(self):
        self.db.execute('''CREATE ROLE restricted_migration_operator NOLOGIN NOSUPERUSER;
          CREATE SCHEMA extensions;
          GRANT USAGE, CREATE ON SCHEMA extensions, public TO restricted_migration_operator;
          ALTER TABLE public.sprints OWNER TO restricted_migration_operator;
          ALTER TABLE public.serverpod_migrations OWNER TO restricted_migration_operator;''')
        with self.assertRaisesRegex(v.ValidationError, '42501'):
            self.db.execute('SET ROLE restricted_migration_operator;\n' + self.sql)
        self.assert_rollback(self.before)

    def test_postcheck_detects_weakened_predicate_or_unrelated_change(self):
        self.migrate()
        after = v.b.inventory(self.db)
        weakened = copy.deepcopy(after)
        weakened['structure']['columns'][0][3] = 'unexpected'
        with self.assertRaisesRegex(v.ValidationError, 'unexpected_schema_change'):
            v.correction_delta(self.db, self.before, weakened)
        self.db.execute('DROP INDEX sprints_uma_ativa_por_usuario_idx; CREATE UNIQUE INDEX sprints_uma_ativa_por_usuario_idx ON public.sprints ("usuarioId") WHERE status=\'planejada\';')
        with self.assertRaisesRegex(v.ValidationError, 'final_index_semantics'):
            v.correction_final(self.db)

    def test_backup_of_corrected_schema_restores_extension_and_constraints(self):
        self.migrate()
        self.db.execute(self.insert('roundtrip', '2026-01-01', '2026-01-05'))
        expected = v.b.inventory(self.db)
        dump = v.docker('exec', self.db.cid, 'pg_dump', '-Fc', '--quote-all-identifiers',
                        '-h', '/var/run/postgresql', '-U', 'postgres', '-d', 'validation')
        self.db.execute('DROP SCHEMA public CASCADE; DROP SCHEMA extensions CASCADE; CREATE SCHEMA public;')
        c = v.b.load_config(Path.home() / '.config/temdas-backup/config.json', needs_source_credentials=False)
        with tempfile.TemporaryDirectory(prefix='sprint-restore-test-') as directory:
            work = Path(directory)
            (work / 'database.dump').write_bytes(dump)
            (work / 'roles.sql').write_text('CREATE ROLE restore_fixture_placeholder;\n')
            v.restore(self.db, c, work)
        self.assertEqual(v.b.inventory(self.db), expected)
        v.correction_final(self.db)


@unittest.skipUnless(os.environ.get('TEMDAS_MIGRATION_BACKUP_TESTS') == '1', 'explicit existing-backup opt-in required')
class BackupCorrectionTests(unittest.TestCase):
    def test_real_backup_upgrade_and_conflicts_without_retaining_fixture_data(self):
        c = v.b.load_config(Path.home() / '.config/temdas-backup/config.json', needs_source_credentials=False)
        with (Path(c['data_dir']) / 'backup.lock').open('a') as lock:
            v.fcntl.flock(lock, v.fcntl.LOCK_EX | v.fcntl.LOCK_NB)
            with v.rehearsal_lock():
                fingerprint = v.resource_fingerprint()
                archive, record = v.checked_backup(c)
                try:
                    with tempfile.TemporaryDirectory(prefix='sprint-backup-test-') as directory, v.IsolatedDatabase() as db:
                        work = Path(directory)
                        v.b.decrypt(c, archive, work / 'payload.tar')
                        v.b.extract_payload(work / 'payload.tar', work)
                        manifest = json.loads((work / 'manifest.json').read_text())
                        self.assertEqual(manifest['project_ref'], v.b.PROD)
                        self.assertEqual(manifest['utc'], record['utc'])
                        self.assertEqual(v.b.digest(work / 'database.dump'), manifest['database_sha256'])
                        self.assertEqual(v.b.digest(work / 'roles.sql'), manifest['roles_sha256'])
                        v.restore(db, c, work)
                        before = v.b.inventory(db)
                        # Boolean assertion avoids dumping production inventories if a check fails.
                        self.assertTrue(before == manifest['inventory'], 'baseline inventory mismatch')
                        versions = v.pending(v.load_registry(), v.history(db).get('temdas_backend'))
                        self.assertTrue(versions == [v.SPRINT_CORRECTION], 'unexpected backup version')
                        v.rehearsal(db, versions, before)
                        after = v.b.inventory(db)
                        v.correction_delta(db, before, after)
                        base_id = db.query('SELECT to_json(coalesce(max(id),0)+1000) FROM public.usuarios')
                        prefix = f'''BEGIN;
                          INSERT INTO public.usuarios (id, "supabaseUserId", "createdAt")
                          VALUES ({base_id}, 'prod02-synthetic-first', now()),
                                 ({base_id + 1}, 'prod02-synthetic-second', now());
                          INSERT INTO public.sprints ("usuarioId",nome,"nomeNormalizado","dataInicio","dataFim",status)
                          VALUES ({base_id},'prod02-first','prod02-first','2040-01-01','2040-01-05','ativa');
                        '''
                        template = '''INSERT INTO public.sprints ("usuarioId",nome,"nomeNormalizado","dataInicio","dataFim",status)
                          VALUES ({owner},'prod02-second','prod02-second','{start}','{end}','{status}'); ROLLBACK;'''
                        for state, start, end, status in (('23505', '2040-02-01', '2040-02-05', 'ativa'),
                                                          ('23P01', '2040-01-05', '2040-01-08', 'planejada')):
                            with self.subTest(state=state), self.assertRaisesRegex(v.ValidationError, state):
                                db.execute(prefix + template.format(owner=base_id, start=start, end=end, status=status))
                            self.assertTrue(v.b.inventory(db) == after, 'fixture rollback mismatch')
                        db.execute(prefix + template.format(owner=base_id + 1, start='2040-01-01', end='2040-01-05', status='ativa'))
                        self.assertTrue(v.b.inventory(db) == after, 'independent-owner fixture rollback mismatch')
                finally:
                    self.assertEqual(v.resource_fingerprint(), fingerprint)


if __name__ == '__main__':
    unittest.main()
