#!/usr/bin/env python3
"""Exact-artifact, offline Package 4 release rehearsal using the encrypted backup.

Never connects to PROD or applies remote SQL. Existing generic SQL gate is unchanged.
"""
import hashlib
import json
from pathlib import Path
import tempfile
import time
import validate as v

P4 = '20261029183226724-pacote4-demandas'
FIX = '20261029220000000-restore-schema-guards'
PINS = {'20261029183226724-pacote4-demandas': '90c8737d3f50fa828c82d43e903112f71520f915f7c8404a69ca7e36b661deec', '20261029220000000-restore-schema-guards': 'cda3f1ca6b2f4c03df951c39cbf89e85fd7f9e047f8b025b0817ac22ee329982'}  # Reviewed SQL pins; changes require a new rehearsal.


def sql(version):
    content = (v.MIGRATIONS / version / 'migration.sql').read_bytes()
    if hashlib.sha256(content).hexdigest() != PINS[version]:
        raise v.ValidationError('release_sql_hash_mismatch')
    return content.decode()


def guards(db):
    return db.query("""SELECT json_build_object(
      'triggers',(SELECT count(*) FROM pg_trigger WHERE NOT tgisinternal AND tgrelid IN
        ('public.demandas'::regclass,'public.sprints'::regclass,'public.sprints_demandas'::regclass)),
      'functions',(SELECT count(*) FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace
        WHERE n.nspname='public' AND p.proname LIKE 'temdas\\_%' ESCAPE '\\'),
      'checks',(SELECT count(*) FROM pg_constraint WHERE convalidated AND connamespace='public'::regnamespace
        AND conname IN ('sprints_periodo_valido_check','emails_whitelist_email_normalizado_check')))""")


def correction_delta(before, after):
    for kind, original in before['structure'].items():
        added = [r for r in after['structure'][kind] if r not in original]
        if any(r not in after['structure'][kind] for r in original):
            raise v.ValidationError('existing_schema_object_changed')
        # Four deferred constraint triggers also have pg_constraint rows.
        expected = {'triggers': 7, 'functions': 5, 'constraints': 6}.get(kind, 0)
        if len(added) != expected or any(r[0] != 'public' for r in added):
            raise v.ValidationError('unexpected_corrective_schema_delta')
        if kind == 'constraints' and {r[2] for r in added} != {
            'sprints_periodo_valido_check', 'emails_whitelist_email_normalizado_check',
            'demandas_validar_owner_filha', 'demandas_validar_owner_vinculos',
            'sprints_validar_owner_vinculos', 'sprints_demandas_validar_owner'}:
            raise v.ValidationError('unexpected_corrective_constraint_names')
    if before['tables'].keys() != after['tables'].keys():
        raise v.ValidationError('unexpected_corrective_table_delta')


def verify_rejection(db, content):
    before = v.b.inventory(db)
    try:
        db.execute(content)
    except v.ValidationError:
        if v.b.inventory(db) != before:
            raise v.ValidationError('rejected_transaction_changed_database')
    else:
        raise v.ValidationError('unsafe_migration_was_not_rejected')


def rehearse():
    c = v.b.load_config(Path.home() / '.config/temdas-backup/config.json', needs_source_credentials=False)
    archive, record = v.checked_backup(c)
    print(json.dumps({'stage':'backup_verified'}), flush=True)
    results = []
    with v.rehearsal_lock(), tempfile.TemporaryDirectory(prefix='temdas-p4-real-clone-') as directory:
        work = Path(directory)
        v.b.decrypt(c, archive, work / 'payload.tar')
        v.b.extract_payload(work / 'payload.tar', work)
        manifest = json.loads((work / 'manifest.json').read_text())
        if (manifest['project_ref'] != v.b.PROD or manifest['utc'] != record['utc'] or
            manifest['database_sha256'] != v.b.digest(work / 'database.dump') or
            manifest['roles_sha256'] != v.b.digest(work / 'roles.sql')):
            raise v.ValidationError('backup_payload_integrity_failed')
        with v.IsolatedDatabase() as db:
            v.restore(db, c, work)
            print(json.dumps({'stage':'real_clone_restored'}), flush=True)
            before = v.b.inventory(db)
            if before != manifest['inventory']:
                raise v.ValidationError('real_clone_inventory_mismatch')
            if v.history(db).get('temdas_backend') != v.SPRINT_CORRECTION:
                raise v.ValidationError('real_clone_unexpected_baseline')
            if guards(db) != dict(triggers=0, functions=0, checks=0):
                raise v.ValidationError('real_clone_unexpected_guards')
            v.correction_final(db)
            # Wrong order must fail atomically; nothing can silently skip baseline.
            verify_rejection(db, sql(FIX))
            for version in (P4, FIX):
                print(json.dumps({'stage':'migrate','version':version}), flush=True)
                prior = v.b.inventory(db)
                start = time.monotonic()
                db.execute(sql(version))
                elapsed = round(time.monotonic() - start, 3)
                after = v.b.inventory(db)
                v.preserved_data(db, before)  # Real snapshot currently has no legacy observations.
                if version == P4:
                    v.sprint_check(before, after)
                v.correction_final(db)
                v.check_definition(db, json.loads((v.MIGRATIONS / version / 'definition.json').read_text()))
                if v.history(db).get('temdas_backend') != version:
                    raise v.ValidationError('release_history_mismatch')
                if version == FIX:
                    correction_delta(prior, after)
                results.append(dict(version=version, sql_sha256=PINS[version], seconds=elapsed))
            if guards(db) != dict(triggers=7, functions=5, checks=2):
                raise v.ValidationError('restored_guards_count_mismatch')
            v.correction_final(db)
            verify_rejection(db, sql(FIX))
            # Catch specifically check_violation; other SQL errors must fail the rehearsal.
            db.execute("""BEGIN;
              DO $checks$ BEGIN
                IF NOT EXISTS (SELECT 1 FROM public.sprints) THEN
                  RAISE EXCEPTION 'missing_sprint_fixture';
                END IF;
                BEGIN
                  UPDATE public.sprints SET "dataInicio"="dataFim" + interval '1 day';
                  RAISE EXCEPTION 'period_check_not_enforced';
                EXCEPTION WHEN check_violation THEN NULL;
                END;
                BEGIN
                  INSERT INTO public.emails_whitelist ("emailNormalizado","createdAt") VALUES (' BAD ',now());
                  RAISE EXCEPTION 'email_check_not_enforced';
                EXCEPTION WHEN check_violation THEN NULL;
                END;
              END $checks$;
              ROLLBACK;""")
            counts = {name: row['rows'] for name, row in before['tables'].items()
                      if name in ('public.demandas','public.registros_tempo','public.sprints','public.sprints_demandas')}
    return dict(status='passed', backup_sha256=record['sha256'], backup_utc=record['utc'],
                tables_restored=len(before['tables']), original_rows_and_hashes_preserved=True,
                correction_delta='7 triggers, 5 functions, 2 validated checks only',
                baseline_order_and_reapply_rejected=True, original_counts=counts, migrations=results)


if __name__ == '__main__':
    try:
        result = rehearse()
        report = Path('/tmp/temdas-p4-release-rehearsal.json')
        report.touch(mode=0o600, exist_ok=True)
        report.write_text(json.dumps(result, sort_keys=True))
        print(json.dumps(result, sort_keys=True))
    except (v.ValidationError, v.b.BackupError, OSError, ValueError, KeyError) as error:
        # Only fixed diagnostic codes; never print SQL stderr or database contents.
        print(json.dumps({'status':'blocked','reason':str(error) if isinstance(error,(v.ValidationError,v.b.BackupError)) else type(error).__name__}))
        raise SystemExit(1)
