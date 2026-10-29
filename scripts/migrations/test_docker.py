"""Real Docker tests, explicitly opt in. Never use existing databases/volumes."""
import json
import os
from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import validate as v
from test_validate import V1, V2, history_sql


@unittest.skipUnless(os.environ.get('TEMDAS_MIGRATION_DOCKER_TESTS') == '1', 'explicit local Docker opt-in required')
class DockerTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.lock = v.rehearsal_lock()
        cls.lock.__enter__()
        cls.addClassCleanup(cls.lock.__exit__, None, None, None)
        cls.fingerprint = v.resource_fingerprint()
        cls.manager = v.IsolatedDatabase()
        cls.db = cls.manager.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls.manager.__exit__(None, None, None)
        if v.resource_fingerprint() != cls.fingerprint:
            raise AssertionError('original Docker resources changed')

    def setUp(self):
        self.db.execute('''DROP SCHEMA public CASCADE; CREATE SCHEMA public;
          CREATE EXTENSION btree_gist WITH SCHEMA public;
          CREATE TABLE sprints (id bigint PRIMARY KEY, "usuarioId" bigint NOT NULL,
            status text NOT NULL, inicio date NOT NULL, fim date NOT NULL);
          CREATE UNIQUE INDEX sprints_uma_ativa_por_usuario_idx ON sprints ("usuarioId") WHERE status='ativa';
          ALTER TABLE sprints ADD CONSTRAINT sprints_periodos_sem_sobreposicao_por_usuario
            EXCLUDE USING gist ("usuarioId" WITH =, daterange(inicio,fim,'[]') WITH &&);
          CREATE TABLE fixture (id bigint PRIMARY KEY, value text NOT NULL);
          INSERT INTO fixture VALUES (1,'synthetic data');
          CREATE TABLE serverpod_migrations (module text PRIMARY KEY, version text NOT NULL, timestamp timestamp NOT NULL);
        ''' + history_sql(V1))
        self.before = v.b.inventory(self.db)
        self.directory = tempfile.TemporaryDirectory(prefix='migration-artifacts-test-')
        self.addCleanup(self.directory.cleanup)
        self.root = Path(self.directory.name)
        self.patch = patch.object(v, 'MIGRATIONS', self.root)
        self.patch.start()
        self.addCleanup(self.patch.stop)

    def candidate(self, body, extra_columns=()):
        folder = self.root / V2
        folder.mkdir()
        (folder / 'migration.sql').write_text('BEGIN;\n' + body + '\n' + history_sql() + '\nCOMMIT;')
        (folder / 'migration.json').write_text(json.dumps({'warnings': [], 'migrationApiVersion': 1}))
        definition = {'moduleName': 'temdas_backend', 'migrationApiVersion': 1,
                      'installedModules': [{'module': 'temdas_backend', 'version': V2}],
                      'tables': [{'schema': 'public', 'name': 'fixture',
                                  'columns': [{'name': 'id', 'columnType': 6, 'isNullable': False},
                                              {'name': 'value', 'columnType': 0, 'isNullable': False},
                                              *[{'name': c, 'columnType': 0, 'isNullable': True} for c in extra_columns]],
                                  'indexes': [{'indexName': 'fixture_pkey'}]}]}
        (folder / 'definition.json').write_text(json.dumps(definition))

    def test_valid_additive_migration_data_history_and_sprint_preserved(self):
        self.candidate('ALTER TABLE "fixture" ADD COLUMN "extra" text;', ['extra'])
        results = v.rehearsal(self.db, [V2], self.before)
        self.assertEqual(len(results), 1)
        self.assertEqual(v.history(self.db)['temdas_backend'], V2)
        self.assertEqual(self.db.query('SELECT to_json(value) FROM fixture WHERE id=1'), 'synthetic data')
        v.sprint_check(self.before, v.b.inventory(self.db))

    def test_invalid_migration_rollback_leaves_history_and_data_unchanged(self):
        self.candidate('ALTER TABLE "fixture" ADD COLUMN "extra" nonexistent_type;')
        with self.assertRaisesRegex(v.ValidationError, 'isolated_sql_failed'):
            v.rehearsal(self.db, [V2], self.before)
        self.assertEqual(v.b.inventory(self.db), self.before)
        self.assertEqual(v.history(self.db)['temdas_backend'], V1)

    def test_destructive_migration_blocked_before_execution(self):
        self.candidate('DROP TABLE "fixture";')
        with patch.object(self.db, 'execute', wraps=self.db.execute) as execute:
            with self.assertRaisesRegex(v.ValidationError, 'destructive'):
                v.rehearsal(self.db, [V2], self.before)
            execute.assert_not_called()
        self.assertEqual(v.b.inventory(self.db), self.before)

    def test_changed_sprint_custom_definition_blocked(self):
        self.db.execute('DROP INDEX sprints_uma_ativa_por_usuario_idx;')
        with self.assertRaisesRegex(v.ValidationError, 'sprint_custom_objects_changed'):
            v.sprint_check(self.before, v.b.inventory(self.db))

    def test_sprint_constraints_actually_reject_overlap_and_duplicate_active(self):
        self.db.execute("INSERT INTO sprints VALUES (1, 1, 'ativa', '2026-01-01', '2026-01-10');")
        for values in ("(2,1,'planejada','2026-01-05','2026-01-15')",
                       "(2,1,'ativa','2026-02-01','2026-02-10')"):
            with self.assertRaisesRegex(v.ValidationError, 'isolated_sql_failed'):
                self.db.execute('INSERT INTO sprints VALUES ' + values + ';')
        self.db.execute("INSERT INTO sprints VALUES (3, 2, 'ativa', '2026-01-01', '2026-01-10');")
        self.assertEqual(self.db.query('SELECT to_json(count(*)) FROM sprints'), 2)

    def test_container_has_no_network_ports_host_mounts_or_persistent_volume(self):
        self.db.verify()
        info = json.loads(v.docker('inspect', self.db.cid))[0]
        self.assertEqual(info['HostConfig']['NetworkMode'], 'none')
        self.assertFalse(info['HostConfig']['PortBindings'])
        self.assertTrue(all(m['Type'] == 'tmpfs' for m in info['Mounts']))
        self.assertEqual(info['HostConfig']['LogConfig']['Type'], 'none')

    def test_target_definition_mismatch_is_blocked(self):
        self.candidate('ALTER TABLE "fixture" ADD COLUMN "extra" text;')
        with self.assertRaisesRegex(v.ValidationError, 'target_columns_mismatch'):
            v.rehearsal(self.db, [V2], self.before)

    def test_projected_original_data_detects_unexpected_backfill(self):
        self.db.execute("UPDATE fixture SET value='changed' WHERE id=1;")
        with self.assertRaisesRegex(v.ValidationError, 'original_data_changed'):
            v.preserved_data(self.db, self.before)


if __name__ == '__main__':
    unittest.main()
