#!/usr/bin/env python3
"""TEMDAS read-only source backups and disposable, socket-only restore checks.

Only fixed event codes and numeric metrics reach logs. No subprocess output or
exception text is logged. Configuration, credentials, archives and keys live
outside the repository. Requires PostgreSQL 17 and OpenSSL CMS AES-256-GCM.
"""
import argparse
import datetime as dt
import fcntl
import hashlib
import json
import os
import re
from pathlib import Path
import shutil
import stat
import subprocess
import tarfile
import tempfile
import time
import uuid

PROD = 'vberbygddnootjcbkajc'
VALIDATION_SCHEMAS = ('public', 'auth', 'storage', 'supabase_migrations')


class BackupError(Exception):
    pass


def utcnow():
    return dt.datetime.now(dt.timezone.utc)


def atomic_json(path, data):
    tmp = path.with_suffix('.new')
    with tmp.open('w') as f:
        json.dump(data, f, sort_keys=True, indent=2)
        f.flush()
        os.fsync(f.fileno())
    os.chmod(tmp, 0o600)
    tmp.replace(path)


def digest(path):
    h = hashlib.sha256()
    with path.open('rb') as f:
        for block in iter(lambda: f.read(1024 * 1024), b''):
            h.update(block)
    return h.hexdigest()


def private_file(path):
    s = path.lstat()
    if not stat.S_ISREG(s.st_mode) or s.st_uid != os.getuid() or s.st_mode & 0o077:
        raise BackupError('private_file_permissions')


def load_config(path, needs_source_credentials=True):
    private_file(path)
    c = json.loads(path.read_text())
    if c['project_ref'] != PROD or c['host'] != f'db.{PROD}.supabase.co':
        raise BackupError('source_not_prod')
    if c['port'] != 5432 or c['database'] != 'postgres':
        raise BackupError('unexpected_source_endpoint')
    if needs_source_credentials:
        private_file(Path(c['password_file']))
    for parent in Path(__file__).resolve().parents:
        if (parent / '.git').exists() and Path(c['data_dir']).resolve().is_relative_to(parent):
            raise BackupError('storage_inside_repository')
    return c


def pg_env(c, source=True):
    # Strip all inherited libpq connection overrides, including service files.
    e = {k: v for k, v in os.environ.items() if k in ('PATH', 'LANG', 'LC_ALL', 'HOME', 'TZ')}
    e.update(LD_LIBRARY_PATH=c['pg_lib'], PGTZ='UTC', PGCONNECT_TIMEOUT='15',
             PGOPTIONS='-c extra_float_digits=3 -c datestyle=ISO,YMD -c intervalstyle=postgres')
    if source:
        e.update(PGHOST=c['host'], PGPORT=str(c['port']), PGDATABASE=c['database'],
                 PGUSER=c['user'], PGPASSFILE=c['password_file'],
                 PGSSLMODE='verify-full', PGSSLROOTCERT=c['ca_file'],
                 PGOPTIONS=e['PGOPTIONS'] + ' -c default_transaction_read_only=on -c statement_timeout=600000 -c lock_timeout=10000')
    return e


def command(args, stage, env=None, stdout=None):
    result = subprocess.run(args, env=env, stdout=stdout or subprocess.PIPE,
                            stderr=subprocess.PIPE, timeout=1800)
    if result.returncode:
        # Categorize known environmental limitations without logging raw output.
        detail = result.stderr.lower()
        suffix = ('_permissions' if b'permission denied' in detail else
                  '_certificate' if b'certificate' in detail else
                  '_extension_unavailable' if b'extension' in detail and b'not available' in detail else
                  '_missing_schema' if b'schema' in detail and b'does not exist' in detail else
                  '_missing_function' if b'function' in detail and b'does not exist' in detail else
                  '_missing_type' if b'type' in detail and b'does not exist' in detail else
                  '_already_exists' if b'already exists' in detail else
                  '_configuration_parameter' if b'configuration parameter' in detail else '')
        if suffix == '_missing_schema':
            match = re.search(rb'schema "(extensions|auth|storage|public|vault|realtime)" does not exist', detail)
            if match:
                suffix += '_' + match.group(1).decode()
        raise BackupError(stage + suffix)
    return result.stdout


class SQL:
    def __init__(self, c, env):
        self.p = subprocess.Popen([c['pg_bin'] + '/psql', '-X', '-qAt', '-v', 'ON_ERROR_STOP=1'],
                                  stdin=subprocess.PIPE, stdout=subprocess.PIPE,
                                  stderr=subprocess.DEVNULL, text=True, env=env)

    def query(self, sql):
        self.p.stdin.write(sql + ';\n')
        self.p.stdin.flush()
        line = self.p.stdout.readline()
        if not line:
            raise BackupError('snapshot_query_failed')
        return json.loads(line)

    def close(self):
        if self.p.poll() is None:
            self.p.stdin.close()
            try:
                self.p.wait(timeout=5)
            except subprocess.TimeoutExpired:
                self.p.terminate()
                self.p.wait(timeout=5)
        self.p.stdout.close()


def ident(value):
    return '"' + value.replace('"', '""') + '"'


def literal(value):
    return "'" + value.replace("'", "''") + "'"


def inventory(sql):
    schemas = ','.join(literal(x) for x in VALIDATION_SCHEMAS)
    tables = sql.query(f"""SELECT coalesce(json_agg(json_build_array(n.nspname,c.relname) ORDER BY n.nspname,c.relname),'[]')
      FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace
      WHERE n.nspname IN ({schemas}) AND c.relkind IN ('r','p')""")
    counts = {}
    for schema, table in tables:
        # Same exported snapshot as pg_dump. Hashes stay inside the encrypted bundle.
        counts[schema + '.' + table] = sql.query(f"""SELECT json_build_object('rows',count(*),
          'hash',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),'')))
          FROM {ident(schema)}.{ident(table)} t""")
    structure = sql.query(f"""SELECT json_build_object(
      'columns',(SELECT coalesce(json_agg(json_build_array(n.nspname,c.relname,a.attname,format_type(a.atttypid,a.atttypmod),a.attnotnull,pg_get_expr(d.adbin,d.adrelid)) ORDER BY n.nspname,c.relname,a.attnum),'[]') FROM pg_attribute a JOIN pg_class c ON c.oid=a.attrelid JOIN pg_namespace n ON n.oid=c.relnamespace LEFT JOIN pg_attrdef d ON d.adrelid=a.attrelid AND d.adnum=a.attnum WHERE n.nspname IN ({schemas}) AND c.relkind IN ('r','p','v','m') AND a.attnum>0 AND NOT a.attisdropped),
      'indexes',(SELECT coalesce(json_agg(json_build_array(schemaname,tablename,indexname,indexdef) ORDER BY schemaname,tablename,indexname),'[]') FROM pg_indexes WHERE schemaname IN ({schemas})),
      'views',(SELECT coalesce(json_agg(json_build_array(n.nspname,c.relname,pg_get_viewdef(c.oid)) ORDER BY n.nspname,c.relname),'[]') FROM pg_class c JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ({schemas}) AND c.relkind IN ('v','m')),
      'constraints',(SELECT coalesce(json_agg(json_build_array(n.nspname,c.relname,k.conname,pg_get_constraintdef(k.oid),k.convalidated) ORDER BY n.nspname,c.relname,k.conname),'[]') FROM pg_constraint k JOIN pg_class c ON c.oid=k.conrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ({schemas})),
      'functions',(SELECT coalesce(json_agg(json_build_array(n.nspname,p.proname,pg_get_function_identity_arguments(p.oid),pg_get_functiondef(p.oid)) ORDER BY n.nspname,p.proname,p.oid::regprocedure::text),'[]') FROM pg_proc p JOIN pg_namespace n ON n.oid=p.pronamespace WHERE n.nspname IN ({schemas}) AND p.prokind IN ('f','p')),
      'policies',(SELECT coalesce(json_agg(json_build_array(schemaname,tablename,policyname,permissive,roles,cmd,qual,with_check) ORDER BY schemaname,tablename,policyname),'[]') FROM pg_policies WHERE schemaname IN ({schemas})),
      'triggers',(SELECT coalesce(json_agg(json_build_array(n.nspname,c.relname,t.tgname,pg_get_triggerdef(t.oid)) ORDER BY n.nspname,c.relname,t.tgname),'[]') FROM pg_trigger t JOIN pg_class c ON c.oid=t.tgrelid JOIN pg_namespace n ON n.oid=c.relnamespace WHERE n.nspname IN ({schemas}) AND NOT t.tgisinternal))""")
    return {'tables': counts, 'structure': structure}


def retention_keep(records, daily=7, weekly=4):
    ordered = sorted(records, key=lambda r: r['utc'], reverse=True)
    days, weeks, keep = set(), set(), set()
    for r in ordered:
        stamp = dt.datetime.fromisoformat(r['utc'])
        day, week = stamp.date(), stamp.isocalendar()[:2]
        if day in days or len(days) < daily:
            days.add(day)
            keep.add(r['file'])
        if week not in weeks and len(weeks) < weekly:
            weeks.add(week)
            keep.add(r['file'])
    if ordered:
        keep.add(ordered[0]['file'])
    return keep


def event(root, code, **metrics):
    # Callers pass only fixed labels, booleans, timestamps and numeric metrics.
    record = {'utc': utcnow().isoformat(), 'event': code, **metrics}
    with (root / 'events.jsonl').open('a') as f:
        f.write(json.dumps(record, sort_keys=True) + '\n')
    print(json.dumps(record, sort_keys=True))


def encrypt(c, source, target):
    command(['openssl', 'cms', '-encrypt', '-aes-256-gcm', '-binary', '-stream',
             '-outform', 'DER', '-in', str(source), '-out', str(target), c['recipient_cert']], 'encrypt')


def decrypt(c, source, target):
    private_file(Path(c['recovery_key']))
    command(['openssl', 'cms', '-decrypt', '-binary', '-inform', 'DER',
             '-in', str(source), '-inkey', c['recovery_key'], '-out', str(target)], 'decrypt_integrity')


def export_external(c, root, record):
    if not c.get('external_dir'):
        return False
    target = Path(c['external_dir'])
    if not target.is_dir() or target.resolve().is_relative_to(root.resolve()):
        raise BackupError('external_directory_invalid')
    source = root / 'archives' / record['file']
    final = target / record['file']
    if final.exists():
        if digest(final) == record['sha256']:
            return True
        raise BackupError('external_archive_collision')
    tmp = target / (record['file'] + '.' + uuid.uuid4().hex + '.partial')
    shutil.copyfile(source, tmp)
    os.chmod(tmp, 0o600)
    if digest(tmp) != record['sha256']:
        raise BackupError('external_copy_integrity')
    tmp.replace(target / record['file'])
    return True


def backup(c, force=False):
    root = Path(c['data_dir'])
    archives = root / 'archives'
    archives.mkdir(parents=True, exist_ok=True, mode=0o700)
    with (root / 'backup.lock').open('a') as lock:
        try:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            event(root, 'skipped_concurrent')
            return
        state_path = root / 'state.json'
        state = json.loads(state_path.read_text()) if state_path.exists() else {'installation': uuid.uuid4().hex, 'records': []}
        now = utcnow()
        last = max((r['utc'] for r in state['records']), default=None)
        newest_record = max(state['records'], key=lambda r: r['utc']) if state['records'] else None
        latest_valid = newest_record and (archives / newest_record['file']).is_file() and digest(archives / newest_record['file']) == newest_record.get('sha256')
        if last and latest_valid and dt.datetime.fromisoformat(last).date() == now.date() and not force:
            # Retry an external copy on later triggers even if today's dump exists.
            newest = max(state['records'], key=lambda r: r['utc'])
            external = export_external(c, root, newest)
            event(root, 'skipped_daily_complete', external_copy=external)
            return
        started = time.monotonic()
        missed = max(0, (now.date() - dt.datetime.fromisoformat(last).date()).days - 1) if last else 0
        source = SQL(c, pg_env(c))
        partial = None
        try:
            if shutil.disk_usage(root).free < 1024 ** 3:
                raise BackupError('insufficient_disk_space')
            snapshot = source.query("BEGIN ISOLATION LEVEL REPEATABLE READ READ ONLY; SELECT to_json(pg_export_snapshot())")
            version = source.query("SELECT to_json(current_setting('server_version_num')::int)")
            if version // 10000 != 17:
                raise BackupError('server_major_not_17')
            if not source.query('SELECT coalesce(to_json(ssl),\'false\'::json) FROM pg_stat_ssl WHERE pid=pg_backend_pid()'):
                raise BackupError('tls_missing')
            baseline = inventory(source)
            if not any(k.startswith('public.') for k in baseline['tables']) or 'auth.users' not in baseline['tables']:
                raise BackupError('required_tables_missing')
            with tempfile.TemporaryDirectory(prefix='backup-', dir=root) as work:
                work = Path(work)
                dump = work / 'database.dump'
                command([c['pg_bin'] + '/pg_dump', '--format=custom', '--compress=gzip:6',
                         '--quote-all-identifiers', '--lock-wait-timeout=10000', '--snapshot=' + snapshot,
                         '--file=' + str(dump)], 'pg_dump', pg_env(c))
                source.close()
                with dump.open('rb') as header_file:
                    valid_header = header_file.read(5) == b'PGDMP'
                if dump.stat().st_size < 4096 or not valid_header:
                    raise BackupError('empty_or_invalid_dump')
                # Expand every archive entry without running any SQL.
                command([c['pg_bin'] + '/pg_restore', '--file=/dev/null', str(dump)], 'dump_readback', pg_env(c, False))
                roles = work / 'roles.sql'
                with roles.open('wb') as f:
                    command([c['pg_bin'] + '/pg_dumpall', '--roles-only', '--no-role-passwords'], 'roles_dump', pg_env(c), f)
                if roles.stat().st_size < 100:
                    raise BackupError('empty_roles')
                manifest = {'project_ref': PROD, 'utc': now.isoformat(), 'server_version_num': version,
                            'canonical_serialization': 'extra_float_digits=3; UTC; ISO,YMD; postgres intervals',
                            'database_sha256': digest(dump), 'roles_sha256': digest(roles), 'inventory': baseline}
                atomic_json(work / 'manifest.json', manifest)
                payload = work / 'payload.tar'
                with tarfile.open(payload, 'w') as tar:
                    for name in ['database.dump', 'roles.sql', 'manifest.json']:
                        tar.add(work / name, arcname=name, recursive=False)
                filename = 'temdas-prod-' + now.strftime('%Y%m%dT%H%M%SZ') + '-' + uuid.uuid4().hex[:8] + '.cms'
                partial = archives / (filename + '.partial')
                encrypt(c, payload, partial)
                if partial.stat().st_size < 4096:
                    raise BackupError('encrypted_output_empty')
                with partial.open('rb') as f:
                    os.fsync(f.fileno())
                record = {'file': filename, 'utc': now.isoformat(), 'sha256': digest(partial),
                          'bytes': partial.stat().st_size, 'installation': state['installation']}
                partial.replace(archives / filename)
                partial = None
                state['records'].append(record)
                atomic_json(state_path, state)
                # Only backups created by this installation are eligible. Never
                # remove foreign/existing archives, or prune before successful publication.
                keep = retention_keep(state['records'], c['daily_keep'], c['weekly_keep'])
                remove = [r for r in state['records'] if r['file'] not in keep and r.get('installation') == state['installation']]
                for r in remove:
                    (archives / r['file']).unlink(missing_ok=True)
                state['records'] = [r for r in state['records'] if r not in remove]
                atomic_json(state_path, state)
                external = export_external(c, root, record)
                event(root, 'backup_success', bytes=record['bytes'], duration_seconds=round(time.monotonic() - started, 2),
                      missed_days=missed, tables_covered=len(baseline['tables']), external_copy=external)
        finally:
            source.close()
            if partial:
                partial.unlink(missing_ok=True)


def extract_payload(payload, destination):
    with tarfile.open(payload) as tar:
        members = tar.getmembers()
        if len(members) != 3 or {m.name for m in members} != {'database.dump', 'roles.sql', 'manifest.json'} or any(not m.isfile() for m in members):
            raise BackupError('unexpected_archive_members')
        tar.extractall(destination, filter='data')


def restore_check(c):
    root = Path(c['data_dir'])
    state = json.loads((root / 'state.json').read_text())
    record = max(state['records'], key=lambda r: r['utc'])
    archive = root / 'archives' / record['file']
    if digest(archive) != record['sha256']:
        raise BackupError('archive_checksum')
    with tempfile.TemporaryDirectory(prefix='restore-', dir=root) as work:
        work = Path(work)
        decrypt(c, archive, work / 'payload.tar')
        extract_payload(work / 'payload.tar', work)
        manifest = json.loads((work / 'manifest.json').read_text())
        if manifest['project_ref'] != PROD or digest(work / 'database.dump') != manifest['database_sha256'] or digest(work / 'roles.sql') != manifest['roles_sha256']:
            raise BackupError('payload_integrity')
        local = pg_env(c, False)
        local.update(PGHOST=str(work / 'socket'), PGPORT='5432', PGUSER='temdas_restore_admin', PGDATABASE='restore_validation', PGSSLMODE='disable')
        (work / 'socket').mkdir(mode=0o700)
        cluster = work / 'cluster'
        command([c['pg_bin'] + '/initdb', '-D', str(cluster), '-U', local['PGUSER'], '--auth-local=trust', '--auth-host=reject', '--no-instructions'], 'init_local_cluster', local)
        running = False
        try:
            command([c['pg_bin'] + '/pg_ctl', '-D', str(cluster), '-l', str(work / 'server.log'), '-o',
                     f"-k {work / 'socket'} -c listen_addresses='' -c unix_socket_permissions=0700", '-w', 'start'], 'start_local_cluster', local)
            running = True
            # Original role attributes/grants are archived, but must not be
            # replayed blindly outside Supabase. Local NOLOGIN placeholders are
            # sufficient to validate policies without platform role privileges.
            role_text = (work / 'roles.sql').read_text()
            names = re.findall(r'^CREATE ROLE ("(?:[^"]|"")*"|[a-z_][a-z0-9_]*);$', role_text, re.M)
            if not names or len(names) != len(re.findall(r'^CREATE ROLE ', role_text, re.M)):
                raise BackupError('role_names_not_parseable')
            role_file = work / 'local-roles.sql'
            role_file.write_text('\n'.join('CREATE ROLE ' + name + ' NOLOGIN NOSUPERUSER;' for name in names))
            command([c['pg_bin'] + '/psql', '-X', '-v', 'ON_ERROR_STOP=1', '-d', 'postgres', '-f', str(role_file)], 'restore_local_role_names', local)
            command([c['pg_bin'] + '/createdb', local['PGDATABASE']], 'create_disposable_database', local)
            # Selective pg_restore does not reliably include namespace entries
            # with a use-list. Create only empty namespaces in the new database.
            namespaces = work / 'namespaces.sql'
            namespaces.write_text('\n'.join('CREATE SCHEMA IF NOT EXISTS ' + ident(name) + ';' for name in VALIDATION_SCHEMAS))
            command([c['pg_bin'] + '/psql', '-X', '-v', 'ON_ERROR_STOP=1', '-f', str(namespaces)], 'local_namespaces', local)

            # Validate application/Auth/Storage/migration objects. Managed service
            # extensions and platform infrastructure require a fresh Supabase baseline.
            toc = command([c['pg_bin'] + '/pg_restore', '--list', str(work / 'database.dump')], 'restore_toc', local).decode()
            toc_file = work / 'restore.list'
            toc_file.write_text('\n'.join(line for line in toc.splitlines() if not re.search(r'\bSCHEMA - (public|auth|storage|supabase_migrations)\b', line)))
            args = [c['pg_bin'] + '/pg_restore', '--use-list=' + str(toc_file), '--exit-on-error', '--no-owner', '--no-privileges', '--dbname=' + local['PGDATABASE']]
            for schema in VALIDATION_SCHEMAS:
                args += ['--schema=' + schema]
            command(args + [str(work / 'database.dump')], 'restore_selected_schemas', local)
            sql = SQL(c, local)
            try:
                restored = inventory(sql)
            finally:
                sql.close()
            if restored != manifest['inventory']:
                expected = manifest['inventory']
                print(json.dumps({'restore_comparison': {
                    'table_sets_equal': restored['tables'].keys() == expected['tables'].keys(),
                    'table_data_equal': restored['tables'] == expected['tables'],
                    'row_count_mismatch_tables': [k for k,v in expected['tables'].items() if restored['tables'].get(k,{}).get('rows') != v['rows']],
                    'hash_mismatch_tables': [k for k,v in expected['tables'].items() if restored['tables'].get(k,{}).get('hash') != v['hash']],
                    'expected_tables': len(expected['tables']), 'restored_tables': len(restored['tables']),
                    'structure_equal': {k: restored['structure'].get(k) == v for k, v in expected['structure'].items()}
                }}))
                raise BackupError('restored_inventory_mismatch')
            report = {'utc': utcnow().isoformat(), 'archive_sha256': record['sha256'], 'status': 'selected_schemas_verified',
                      'tables_verified': len(restored['tables']), 'rows_and_hashes_match': True, 'constraints_functions_policies_triggers_match': True,
                      'full_supabase_platform_restore': False, 'ownership_and_grants_executed': False}
            atomic_json(root / 'restore-evidence.json', report)
            event(root, 'restore_selected_schemas_success', tables_verified=len(restored['tables']), full_supabase_platform=False)
        finally:
            if running:
                command([c['pg_bin'] + '/pg_ctl', '-D', str(cluster), '-m', 'fast', '-w', 'stop'], 'stop_local_cluster', local)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('action', choices=['run', 'restore-check', 'status'])
    parser.add_argument('--config', type=Path, default=Path.home() / '.config/temdas-backup/config.json')
    parser.add_argument('--force', action='store_true')
    args = parser.parse_args()
    os.umask(0o077)
    c = None
    try:
        c = load_config(args.config, needs_source_credentials=args.action == 'run')
        if args.action == 'run':
            backup(c, args.force)
        elif args.action == 'restore-check':
            restore_check(c)
        else:
            state_path = Path(c['data_dir']) / 'state.json'
            state = json.loads(state_path.read_text()) if state_path.exists() else {'records': []}
            valid = [r for r in state['records'] if (Path(c['data_dir']) / 'archives' / r['file']).is_file() and digest(Path(c['data_dir']) / 'archives' / r['file']) == r['sha256']]
            last = max((r['utc'] for r in valid), default=None)
            age = (utcnow() - dt.datetime.fromisoformat(last)).total_seconds() if last else None
            print(json.dumps({'valid_backups': len(valid), 'last_success_utc': last, 'overdue': age is None or age > 36 * 3600,
                              'external_destination_configured': bool(c.get('external_dir'))}))
    except Exception as error:
        code = str(error) if isinstance(error, BackupError) else 'internal_failure'
        if c:
            event(Path(c['data_dir']), 'failure', phase=code)
        else:
            print(json.dumps({'event': 'failure', 'phase': code}))
        return 1
    return 0


if __name__ == '__main__':
    raise SystemExit(main())
