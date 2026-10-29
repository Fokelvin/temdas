from pathlib import Path
import tempfile
import unittest
from unittest.mock import patch

import backup as b


class ExtensionRestoreTests(unittest.TestCase):
    def test_old_backup_without_dependency_requires_no_extension(self):
        with patch.object(b, 'command') as command:
            self.assertEqual(b.restore_extension_sql({}, Path('dump'), '1; 0 0 EXTENSION - pgcrypto owner', Path('/tmp')), '')
            command.assert_not_called()

    def test_only_pinned_extension_sql_is_returned(self):
        with tempfile.TemporaryDirectory() as directory:
            c = {'pg_bin': '/local/tools', 'pg_lib': '/local/lib'}
            ddl = b'CREATE EXTENSION IF NOT EXISTS "btree_gist" WITH SCHEMA "extensions";'
            with patch.object(b, 'command', return_value=ddl):
                sql = b.restore_extension_sql(c, Path('dump'), '1; 0 0 EXTENSION - btree_gist owner', Path(directory))
            self.assertEqual(sql, "CREATE SCHEMA IF NOT EXISTS extensions;\nCREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA extensions VERSION '1.7';\n")

    def test_unexpected_schema_or_duplicate_entries_blocked(self):
        with tempfile.TemporaryDirectory() as directory:
            c = {'pg_bin': '/local/tools', 'pg_lib': '/local/lib'}
            with patch.object(b, 'command', return_value=b'CREATE EXTENSION IF NOT EXISTS btree_gist WITH SCHEMA public;'):
                with self.assertRaisesRegex(b.BackupError, 'schema_unsupported'):
                    b.restore_extension_sql(c, Path('dump'), '1; 0 0 EXTENSION - btree_gist owner', Path(directory))
            with self.assertRaisesRegex(b.BackupError, 'entry_ambiguous'):
                b.restore_extension_sql(c, Path('dump'), '1; 0 0 EXTENSION - btree_gist owner\n2; 0 0 EXTENSION - btree_gist owner', Path(directory))


if __name__ == '__main__':
    unittest.main()
