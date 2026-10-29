"""Artifact regression tests for the approved additive guard restoration."""
import hashlib
import unittest
import rehearse_pacote4_release as release


class ReleaseGuardArtifactTests(unittest.TestCase):
    def test_reviewed_sql_and_historical_package4_are_pinned(self):
        for version in (release.P4, release.FIX):
            self.assertEqual(hashlib.sha256(release.sql(version).encode()).hexdigest(), release.PINS[version])
        self.assertEqual(release.PINS[release.P4], '90c8737d3f50fa828c82d43e903112f71520f915f7c8404a69ca7e36b661deec')

    def test_guard_bodies_match_existing_approved_definition_verbatim(self):
        definition = (release.v.MIGRATIONS / release.P4 / 'definition.sql').read_text()
        block = definition[definition.index('-- Existing custom triggers/checks'):definition.index('-- Custom Sprint objects')]
        sql = release.sql(release.FIX)
        self.assertIn(block, sql)
        self.assertEqual(sql.count('CREATE OR REPLACE FUNCTION'), 5)
        self.assertEqual(sql.count('CREATE TRIGGER') + sql.count('CREATE CONSTRAINT TRIGGER'), 7)
        self.assertEqual(sql.count('ADD CONSTRAINT'), 2)
        for forbidden in ('DROP ', 'DELETE FROM', 'TRUNCATE ', 'ALTER COLUMN'):
            self.assertNotIn(forbidden, sql)

    def test_delta_rejects_removed_or_changed_existing_index(self):
        before = {'structure': {'indexes': [['public','sprints','original','CREATE INDEX']]}, 'tables': {}}
        after = {'structure': {'indexes': []}, 'tables': {}}
        with self.assertRaises(release.v.ValidationError):
            release.correction_delta(before, after)

    def test_constraint_triggers_have_catalog_rows_in_addition_to_checks(self):
        names = ['sprints_periodo_valido_check','emails_whitelist_email_normalizado_check',
                 'demandas_validar_owner_filha','demandas_validar_owner_vinculos',
                 'sprints_validar_owner_vinculos','sprints_demandas_validar_owner']
        before = {'structure': {'constraints': []}, 'tables': {}}
        after = {'structure': {'constraints': [['public','table',n] for n in names]}, 'tables': {}}
        release.correction_delta(before, after)
        after['structure']['constraints'][0][2] = 'unexpected'
        with self.assertRaises(release.v.ValidationError):
            release.correction_delta(before, after)

    def test_corrective_migration_is_last_and_requires_package4(self):
        registry = release.v.load_registry()
        self.assertEqual(registry[-2:], [release.P4, release.FIX])
        sql = release.sql(release.FIX)
        self.assertIn("version = '" + release.P4 + "'", sql)
        self.assertIn("lock_timeout = '5s'", sql)
        self.assertIn("statement_timeout = '60s'", sql)
        self.assertIn('restore_guards_existing_data_violates_invariants', sql)
        self.assertTrue(sql.startswith('BEGIN;'))
        self.assertTrue(sql.rstrip().endswith('COMMIT;'))


if __name__ == '__main__':
    unittest.main()
