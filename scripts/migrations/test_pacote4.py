"""Package 4 SQL rehearsal, synthetic data in an owned, disposable PostgreSQL."""
import os
import unittest

import validate as v

VERSION = '20261029183226724-pacote4-demandas'
BASELINE = '20261029113025000-sprint-integrity'


@unittest.skipUnless(os.environ.get('TEMDAS_MIGRATION_DOCKER_TESTS') == '1',
                     'explicit local Docker opt-in required')
class Package4MigrationTests(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls.manager = v.IsolatedDatabase()
        cls.db = cls.manager.__enter__()
        cls.addClassCleanup(cls.manager.__exit__, None, None, None)

    def setUp(self):
        self.db.execute('DROP SCHEMA public CASCADE; DROP SCHEMA IF EXISTS extensions CASCADE; CREATE SCHEMA public;')
        self.db.execute((v.MIGRATIONS / BASELINE / 'definition.sql').read_text())
        target = (v.MIGRATIONS / VERSION / 'definition.sql').read_text()
        self.db.execute(target[target.index('-- Existing custom triggers/checks'):target.index('-- Custom Sprint objects')])
        self.db.execute('''INSERT INTO usuarios ("supabaseUserId", "createdAt") VALUES ('synthetic-p4', now());
          INSERT INTO demandas ("usuarioId", titulo, descricao, observacoes, status, prioridade,
              "tempoEstimadoMinutos", "tempoExecutadoMinutos", "criadoEm", "atualizadoEm") VALUES
          (1,'vazia',NULL,E' texto antigo\ncom acentos ç ', 'aberta','media',30,0,now(),now()),
          (1,'ambas',E' descrição original ',E' notas antigas\nintegrais ', 'concluida','media',30,0,now(),now()),
          (1,'sem notas','descrição',NULL,'cancelada','media',30,0,now(),now()),
          (1,'branca',E' \n\t ','legado','aberta','media',30,0,now(),now());
          INSERT INTO registros_tempo ("demandaId", "inicioEm", "duracaoMinutos", "criadoEm")
            VALUES (1,'2026-10-01 09:00',30,'2026-10-01 09:30');''')
        self.before = self.db.query('SELECT json_agg(t ORDER BY id) FROM demandas t')

    def migrate(self):
        self.db.execute((v.MIGRATIONS / VERSION / 'migration.sql').read_text())

    def test_upgrade_preserves_integral_text_and_existing_business_data(self):
        self.migrate()
        after = self.db.query('SELECT json_agg(t ORDER BY id) FROM demandas t')
        expected = [' texto antigo\ncom acentos ç ',
                    ' descrição original \n\nObservações anteriores\n notas antigas\nintegrais ',
                    'descrição', 'legado']
        for original, updated, description in zip(self.before, after, expected):
            self.assertEqual(updated.pop('descricao'), description)
            original.pop('descricao')
            self.assertEqual(updated, original)
        self.assertEqual(self.db.query('SELECT to_json(count(*)) FROM anotacoes_demanda'), 0)
        self.assertEqual(self.db.query('SELECT to_json("duracaoMinutos") FROM registros_tempo'), 30)
        self.assertIsNone(self.db.query("SELECT coalesce(to_json(observacao), 'null'::json) FROM registros_tempo"))
        self.assertEqual(self.db.query("SELECT to_json(version) FROM serverpod_migrations WHERE module='temdas_backend'"), VERSION)
        self.assertEqual(self.db.query("SELECT to_json(count(*)) FROM pg_indexes WHERE indexname IN ('sprints_uma_ativa_por_usuario_idx','sprints_periodos_sem_sobreposicao_por_usuario')"), 2)

    def test_reapplying_revision_is_rejected_without_duplicate_text(self):
        self.migrate()
        before = self.db.query('SELECT json_agg(t ORDER BY id) FROM demandas t')
        with self.assertRaises(v.ValidationError):
            self.migrate()
        self.assertEqual(self.db.query('SELECT json_agg(t ORDER BY id) FROM demandas t'), before)

    def test_failure_rolls_back_text_schema_and_revision_together(self):
        sql = (v.MIGRATIONS / VERSION / 'migration.sql').read_text().replace('COMMIT;', "SELECT 1/0; COMMIT;")
        with self.assertRaises(v.ValidationError):
            self.db.execute(sql)
        self.assertEqual(self.db.query('SELECT json_agg(t ORDER BY id) FROM demandas t'), self.before)
        self.assertFalse(self.db.query("SELECT to_json(to_regclass('public.anotacoes_demanda') IS NOT NULL)"))
        self.assertEqual(self.db.query("SELECT to_json(version) FROM serverpod_migrations WHERE module='temdas_backend'"), BASELINE)

    def test_clean_install_matches_generated_target_and_sprint_objects(self):
        self.db.execute('DROP SCHEMA public CASCADE; DROP SCHEMA IF EXISTS extensions CASCADE; CREATE SCHEMA public;')
        self.db.execute((v.MIGRATIONS / VERSION / 'definition.sql').read_text())
        self.assertEqual(self.db.query("SELECT to_json(count(*)) FROM information_schema.columns WHERE table_name='anotacoes_demanda'"), 7)
        self.assertEqual(self.db.query("SELECT to_json(count(*)) FROM pg_indexes WHERE indexname IN ('sprints_uma_ativa_por_usuario_idx','sprints_periodos_sem_sobreposicao_por_usuario')"), 2)


if __name__ == '__main__':
    unittest.main()
