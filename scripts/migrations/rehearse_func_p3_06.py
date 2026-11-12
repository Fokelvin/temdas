#!/usr/bin/env python3
"""Rehearse the reviewed To-do SQL on an isolated PROD-02 clone only."""
import fcntl
import hashlib
import json
from pathlib import Path
import tempfile
import time

import validate as v

VERSION = '20261111230242894-todos'
BASELINE = '20261111180305263-backlog-p2-01'
SQL_SHA256 = '5cdd0a4027d2c38ddcad3192d52006f8816529d5904356abd2bc2d19b210eab7'


def require(condition, reason):
    if not condition:
        raise v.ValidationError(reason)


def verify_delta(db, before, after):
    require(set(after['tables']) == set(before['tables']) | {'public.todos'}
            and after['tables']['public.todos']['rows'] == 0, 'unexpected_table_delta')
    for kind, original in before['structure'].items():
        actual = after['structure'][kind]
        if kind in ('columns', 'indexes', 'constraints'):
            actual = [row for row in actual if row[:2] != ['public', 'todos']]
        require(actual == original, 'unexpected_schema_delta_' + kind)

    indexes = {row[2]: row[3] for row in after['structure']['indexes']
               if row[:2] == ['public', 'todos']}
    require(indexes == {
        'todos_pkey': 'CREATE UNIQUE INDEX todos_pkey ON public.todos USING btree (id)',
        'todos_usuario_posicao_idx': 'CREATE INDEX todos_usuario_posicao_idx ON public.todos USING btree ("usuarioId", posicao)',
        'todos_demanda_idx': 'CREATE INDEX todos_demanda_idx ON public.todos USING btree ("demandaId")',
    }, 'unexpected_todos_indexes')
    constraints = {row[2]: row[3:] for row in after['structure']['constraints']
                   if row[:2] == ['public', 'todos']}
    require(constraints == {
        'todos_pkey': ['PRIMARY KEY (id)', True],
        'todos_fk_0': ['FOREIGN KEY ("usuarioId") REFERENCES usuarios(id)', True],
        'todos_fk_1': ['FOREIGN KEY ("demandaId") REFERENCES demandas(id) ON DELETE CASCADE', True],
    }, 'unexpected_todos_constraints')
    require(db.query("""SELECT to_json(relrowsecurity)
        FROM pg_class WHERE oid = 'public.todos'::regclass"""), 'todos_rls_disabled')


def verify_behavior(db):
    db.execute("""
BEGIN;
INSERT INTO public.usuarios (id, "supabaseUserId", "createdAt")
VALUES (-306, 'func-p3-06-rehearsal', now());
INSERT INTO public.demandas (id, "usuarioId", titulo, status, prioridade,
    "tempoEstimadoMinutos", "tempoExecutadoMinutos", "criadoEm", "atualizadoEm")
VALUES (-306, -306, 'Rehearsal demand', 'aberta', 'media', 30, 0, now(), now());
INSERT INTO public.todos (id, "usuarioId", "demandaId", conteudo, "criadoEm")
VALUES (-306, -306, -306, 'Linked', now()), (-307, -306, NULL, 'Unlinked', now());
DO $test$
BEGIN
    BEGIN
        INSERT INTO public.todos (id, "usuarioId", conteudo, "criadoEm")
        VALUES (-308, -307, 'Invalid owner', now());
        RAISE EXCEPTION 'Owner FK accepted a missing user';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
    BEGIN
        INSERT INTO public.todos (id, "usuarioId", "demandaId", conteudo, "criadoEm")
        VALUES (-308, -306, -307, 'Invalid demand', now());
        RAISE EXCEPTION 'Demand FK accepted a missing demand';
    EXCEPTION WHEN foreign_key_violation THEN NULL;
    END;
END
$test$;

GRANT USAGE ON SCHEMA public TO anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON public.todos TO anon, authenticated;
""" + '\n'.join(f"""
SET LOCAL ROLE {role};
DO $test$
BEGIN
    IF EXISTS (SELECT FROM public.todos) THEN
        RAISE EXCEPTION 'RLS exposed a row';
    END IF;
    UPDATE public.todos SET conteudo = 'Forbidden';
    IF FOUND THEN RAISE EXCEPTION 'RLS permitted update'; END IF;
    DELETE FROM public.todos;
    IF FOUND THEN RAISE EXCEPTION 'RLS permitted delete'; END IF;
    BEGIN
        INSERT INTO public.todos (id, "usuarioId", conteudo, "criadoEm")
        VALUES (-308, -306, 'Forbidden', now());
        RAISE EXCEPTION 'RLS permitted insert';
    EXCEPTION WHEN insufficient_privilege THEN NULL;
    END;
END
$test$;
RESET ROLE;
""" for role in ('anon', 'authenticated')) + """
DELETE FROM public.demandas WHERE id = -306;
DO $test$
BEGIN
    IF EXISTS (SELECT FROM public.todos WHERE id = -306)
        OR NOT EXISTS (SELECT FROM public.todos WHERE id = -307) THEN
        RAISE EXCEPTION 'Cascade did not preserve the unlinked card';
    END IF;
    BEGIN
        DELETE FROM public.usuarios WHERE id = -306;
        RAISE EXCEPTION 'Deletion accepted a referenced user';
    EXCEPTION WHEN foreign_key_violation THEN
        DECLARE
            violated text;
        BEGIN
            GET STACKED DIAGNOSTICS violated = CONSTRAINT_NAME;
            IF violated <> 'todos_fk_0' THEN RAISE; END IF;
        END;
    END;
END
$test$;
ROLLBACK;
""")


def rehearse(config):
    folder = v.MIGRATIONS / VERSION
    sql = (folder / 'migration.sql').read_bytes()
    require(hashlib.sha256(sql).hexdigest() == SQL_SHA256, 'reviewed_sql_hash_mismatch')
    source = v.source_fingerprint()
    archive, record = v.checked_backup(config)
    resources = v.resource_fingerprint()
    try:
        with tempfile.TemporaryDirectory(prefix='temdas-todos-rehearsal-') as directory:
            work = Path(directory)
            v.b.decrypt(config, archive, work / 'payload.tar')
            v.b.extract_payload(work / 'payload.tar', work)
            manifest = json.loads((work / 'manifest.json').read_text())
            require(manifest['project_ref'] == v.b.PROD
                    and manifest['server_version_num'] == 170011
                    and manifest['utc'] == record['utc']
                    and v.b.digest(work / 'database.dump') == manifest['database_sha256']
                    and v.b.digest(work / 'roles.sql') == manifest['roles_sha256'],
                    'backup_payload_mismatch')
            with v.IsolatedDatabase() as db:
                v.restore(db, config, work)
                before = v.b.inventory(db)
                require(before == manifest['inventory'], 'baseline_inventory_mismatch')
                history = {'temdas_backend': BASELINE, 'serverpod': '20260129180959368'}
                require(v.history(db) == history
                        and v.pending(v.load_registry(), BASELINE) == [VERSION],
                        'baseline_or_pending_sequence_mismatch')
                require(any(row[:4] == ['public', 'demandas', 'localizacao', 'text']
                            and row[4] for row in before['structure']['columns']),
                        'backlog_column_missing')
                v.sprint_check(before)
                start = time.monotonic()
                db.execute(sql.decode('utf-8'))
                elapsed = round(time.monotonic() - start, 3)
                after = v.b.inventory(db)
                verify_delta(db, before, after)
                v.preserved_data(db, before)
                require(v.history(db) == {**history, 'temdas_backend': VERSION}
                        and before['tables']['public.serverpod_migrations']['rows']
                        == after['tables']['public.serverpod_migrations']['rows'],
                        'migration_history_mismatch')
                v.check_definition(db, json.loads((folder / 'definition.json').read_text()))
                verify_behavior(db)
                require(v.b.inventory(db) == after, 'fixture_rollback_mismatch')
    finally:
        require(v.resource_fingerprint() == resources, 'existing_docker_resources_changed')
    require(v.source_fingerprint() == source, 'source_changed_during_rehearsal')
    return {
        'status': 'rehearsal_passed_requires_review',
        'production_authorized': False,
        'migration': VERSION,
        'baseline': BASELINE,
        'sql_sha256': SQL_SHA256,
        'backend_serverpod': '3.4.11',
        'backend_and_migrations_sha256': source,
        'backup_sha256': record['sha256'],
        'backup_utc': record['utc'],
        'second_copy_verified': True,
        'postgres_version': '17.11',
        'tables_restored': len(before['tables']),
        'migration_seconds': elapsed,
        'checks': ['baseline_inventory_matches_manifest', 'backlog_schema_and_data_preserved', 'existing_schema_and_data_preserved',
                   'expected_schema_delta_and_history', 'foreign_keys_and_cascade',
                   'rls_denies_anon_and_authenticated', 'fixtures_rolled_back',
                   'original_docker_resources_unchanged'],
    }


if __name__ == '__main__':
    try:
        config = v.b.load_config(Path.home() / '.config/temdas-backup/config.json',
                                 needs_source_credentials=False)
        with (Path(config['data_dir']) / 'backup.lock').open('a') as backup_lock:
            fcntl.flock(backup_lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            with v.rehearsal_lock():
                print(json.dumps(rehearse(config), sort_keys=True))
    except (v.ValidationError, v.b.BackupError, v.secondary.SecondaryError) as error:
        print(json.dumps({'status': 'blocked', 'reason': str(error),
                          'production_authorized': False}))
        raise SystemExit(1)
    except (OSError, ValueError, KeyError, TypeError) as error:
        print(json.dumps({'status': 'blocked', 'reason': type(error).__name__,
                          'production_authorized': False}))
        raise SystemExit(1)
