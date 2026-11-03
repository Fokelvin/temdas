"""Static checks of SPR-P2-01 artifacts. Does not execute migration SQL."""
import hashlib
from pathlib import Path
import re
import unittest

ROOT = Path(__file__).resolve().parents[2]
MIGRATIONS = ROOT / 'serverpod/temdas_backend/temdas_backend_server/migrations'
VERSION = '20261103123548408-spr-p2-01'
BASELINE = '20261029220000000-restore-schema-guards'

def functions(sql):
    return {name: body for body, name in re.findall(
        r'(CREATE OR REPLACE FUNCTION "([^"]+)"\(\).*?\$\$;)', sql, re.S)}


class SprintMultiArtifacts(unittest.TestCase):
    def test_historical_baseline_untouched(self):
        self.assertEqual(hashlib.sha256((MIGRATIONS/BASELINE/'migration.sql').read_bytes()).hexdigest(),
            'cda3f1ca6b2f4c03df951c39cbf89e85fd7f9e047f8b025b0817ac22ee329982')
        registry=(MIGRATIONS/'migration_registry.txt').read_text().splitlines()
        self.assertEqual(registry[-2:],[BASELINE,VERSION])

    def test_delta_changes_only_two_trigger_bodies_and_adds_index(self):
        sql=(MIGRATIONS/VERSION/'migration.sql').read_text()
        bodies=functions(sql)
        self.assertEqual(set(bodies),{'temdas_validar_vinculo_sprint_aberta','temdas_validar_reabertura_sprint'})
        for forbidden in ('DROP ', 'DELETE FROM', 'TRUNCATE ', 'UPDATE public.', 'ALTER COLUMN'):
            self.assertNotIn(forbidden,sql)
        self.assertIn("version = '"+BASELINE+"'",sql)
        self.assertIn("lock_timeout = '5s'",sql)
        self.assertIn('CREATE INDEX "sprints_demandas_demanda_idx"',sql)
        self.assertTrue(sql.startswith('BEGIN;'))
        self.assertTrue(sql.rstrip().endswith('COMMIT;'))

    def test_clean_schema_has_same_functions_and_all_previous_protections(self):
        sql=(MIGRATIONS/VERSION/'migration.sql').read_text()
        definition=(MIGRATIONS/VERSION/'definition.sql').read_text()
        for name,body in functions(sql).items():
            self.assertEqual(functions(definition)[name],body)
        original=functions((MIGRATIONS/BASELINE/'definition.sql').read_text())
        for name,body in original.items():
            if name not in functions(sql):
                self.assertEqual(functions(definition)[name],body)
        self.assertIn('sprints_demandas_sprint_demanda_idx',definition)
        self.assertIn('sprints_uma_ativa_por_usuario_idx',definition)
        self.assertIn('sprints_periodos_sem_sobreposicao_por_usuario',definition)
        self.assertEqual(definition.count('CREATE CONSTRAINT TRIGGER'),4)

if __name__=='__main__':
    unittest.main()
