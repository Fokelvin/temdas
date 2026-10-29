#!/usr/bin/env python3
"""PROD-02: offline rehearsal only, never a production migration executor.

No database URL option, remote SQL, source credentials, host mounts, published
ports or production apply command. Command output and exception bodies are not
logged. A successful rehearsal still needs separate human production approval.
"""
import argparse
import contextlib
import datetime as dt
import fcntl
import hashlib
import json
import os
from pathlib import Path
import re
import stat
import subprocess
import sys
import tempfile
import time
import uuid

ROOT = Path(__file__).resolve().parents[2]
sys.path.insert(0, str(ROOT / 'scripts/backup'))
import backup as b
import secondary

MIGRATIONS = ROOT / 'serverpod/temdas_backend/temdas_backend_server/migrations'
IMAGE = 'postgres:17.11-bookworm@sha256:839fbb5a4942a7758dd93e18b42ea5649807491a0545b5eeeb8f0b8bb11857a5'
LABEL = 'br.com.temdas.migration-validation'
CUSTOM = {'sprints_uma_ativa_por_usuario_idx',
          'sprints_periodos_sem_sobreposicao_por_usuario'}
SPRINT_BASELINE = '20261009000123093-convite-cooldown'
SPRINT_CORRECTION = '20261029113025000-sprint-integrity'
# Reviewed exception for ONE SQL-only migration, not a generic SQL bypass.
# Changing any artifact requires review of this pin and all correction tests.
SPRINT_ARTIFACTS = {
    'definition.json': '5f3553068ec38af03ab97ac8f9ff9947f4398383371f7ab772a62a7f624034f7',
    'definition.sql': '99358d0ca3132717ed27026d8ca7ed74c28619e97eb59b88891d2940bae620b1',
    'definition_project.json': '476ece184d747e195b42d3b490edab22b6e465578279aeef3aa1e8e8c03375fb',
    'migration.json': '5f269a504f0fee5ddda966c1055ebe30d57585c0e9edfe7afc42dc1f175c0500',
    'migration.sql': 'e46a7e8013f1c51069c3e31a5faf1ff0a6f8d3b7c46028181f199822a8f8e230',
}


class ValidationError(Exception):
    def __init__(self, reason, evidence=None):
        super().__init__(reason)
        self.evidence = evidence or {}


@contextlib.contextmanager
def rehearsal_lock():
    path = Path(tempfile.gettempdir()) / ('temdas-migrations-' + str(os.getuid()) + '.lock')
    fd = os.open(path, os.O_RDWR | os.O_CREAT | os.O_NOFOLLOW, 0o600)
    try:
        info = os.fstat(fd)
        if not stat.S_ISREG(info.st_mode) or info.st_uid != os.getuid() or info.st_mode & 0o077:
            raise ValidationError('validation_lock_permissions')
        try:
            fcntl.flock(fd, fcntl.LOCK_EX | fcntl.LOCK_NB)
        except BlockingIOError:
            raise ValidationError('validation_already_running') from None
        yield
    finally:
        os.close(fd)


def call(args, *, data=None, stage='docker', timeout=600):
    # Do not inherit libpq, Docker remote contexts, or credential/proxy overrides.
    env = {k: v for k, v in os.environ.items() if k in ('PATH', 'HOME', 'LANG', 'LC_ALL')}
    try:
        r = subprocess.run(args, input=data, capture_output=True, env=env, timeout=timeout)
    except (OSError, subprocess.TimeoutExpired):
        raise ValidationError(stage + '_unavailable') from None
    if r.returncode:
        if stage == 'isolated_sql':
            # psql VERBOSITY=sqlstate; only predefined classifications escape.
            for state in ('23505', '23P01', '42501', '55P03', '57014', 'P0001'):
                if re.search(rb'\b' + state.encode() + rb'\b', r.stderr):
                    raise ValidationError(stage + '_failed_' + state)
        raise ValidationError(stage + '_failed')
    return r.stdout


def docker(*args, **kwargs):
    return call(['docker', '--host=unix:///var/run/docker.sock', *args], **kwargs)


def lex(sql):
    """Fail-closed SQL lexer. Not a substitute for PostgreSQL or human review."""
    tokens, i = [], 0
    while i < len(sql):
        c = sql[i]
        if c.isspace():
            i += 1
        elif sql.startswith('--', i):
            end = sql.find('\n', i)
            i = len(sql) if end < 0 else end + 1
        elif sql.startswith('/*', i):
            depth, i = 1, i + 2
            while i < len(sql) and depth:
                if sql.startswith('/*', i):
                    depth, i = depth + 1, i + 2
                elif sql.startswith('*/', i):
                    depth, i = depth - 1, i + 2
                else:
                    i += 1
            if depth:
                raise ValidationError('sql_unterminated_comment')
        elif c in "'\"":
            quote, value, i = c, '', i + 1
            while i < len(sql):
                if sql[i] == '\\':
                    raise ValidationError('sql_escape_requires_review')
                if sql[i] == quote:
                    if i + 1 < len(sql) and sql[i + 1] == quote:
                        value, i = value + quote, i + 2
                        continue
                    i += 1
                    break
                value, i = value + sql[i], i + 1
            else:
                raise ValidationError('sql_unterminated_quote')
            tokens.append(('string', value) if quote == "'" else ('identifier', value))
        elif c in '$\\':
            raise ValidationError('sql_dynamic_or_meta_requires_review')
        else:
            m = re.match(r'[A-Za-z_][A-Za-z_0-9]*|[0-9]+|.', sql[i:])
            tokens.append(('word', m.group().upper()))
            i += len(m.group())
    return tokens


def statements(sql):
    result, current = [], []
    for token in lex(sql):
        if token == ('word', ';'):
            if current:
                result.append(current)
                current = []
        else:
            current.append(token)
    if current:
        raise ValidationError('sql_missing_terminator')
    if not result or result[0] != [('word', 'BEGIN')] or result[-1] != [('word', 'COMMIT')]:
        raise ValidationError('sql_transaction_wrapper_required')
    return result[1:-1]


def inspect_sql(sql):
    risks = set()
    for s in statements(sql):
        words = [v for k, v in s if k == 'word']
        if not words:
            raise ValidationError('sql_unsupported_statement')
        if set(words) & {'DROP', 'TRUNCATE', 'DELETE', 'CASCADE', 'PROGRAM', 'EXECUTE',
                         'GRANT', 'REVOKE', 'COPY', 'RESET', 'RENAME', 'DISABLE', 'ENABLE',
                         'FORCE', 'ATTACH', 'DETACH', 'OWNER', 'TABLESPACE'}:
            raise ValidationError('sql_destructive_or_privileged_blocked')
        normalized = [v.upper() for k, v in s if k != 'string']
        if words[0] != 'INSERT' and set(words) & {'SET', 'UPDATE', 'SELECT', 'INHERITS'}:
            raise ValidationError('sql_statement_requires_manual_review')
        if normalized[:2] == ['CREATE', 'TABLE'] and (len(s) < 4 or s[3] != ('word', '(')):
            raise ValidationError('sql_create_table_requires_explicit_columns')
        if words[0] == 'INSERT':
            # Exact generated Serverpod history upsert; arbitrary DML is blocked.
            pattern = re.compile(r'''INSERT\s+INTO\s+"serverpod_migrations"\s*\(\s*"module"\s*,\s*"version"\s*,\s*"timestamp"\s*\)\s*
                VALUES\s*\(\s*'([a-z_]+)'\s*,\s*'([a-zA-Z0-9_-]+)'\s*,\s*now\(\)\s*\)\s*
                ON\s+CONFLICT\s*\(\s*"module"\s*\)\s*DO\s+UPDATE\s+SET\s*"version"\s*=\s*'\2'\s*,\s*"timestamp"\s*=\s*now\(\)''', re.I | re.X)
            rebuilt = ' '.join("'" + v.replace("'", "''") + "'" if k == 'string' else
                               '"' + v.replace('"', '""') + '"' if k == 'identifier' else v for k, v in s)
            rebuilt = re.sub(r'NOW\s*\(\s*\)', 'now()', rebuilt)
            if not pattern.fullmatch(rebuilt):
                raise ValidationError('sql_history_only_dml')
        elif normalized[:2] in (['CREATE', 'TABLE'], ['CREATE', 'INDEX']) or normalized[:3] == ['CREATE', 'UNIQUE', 'INDEX']:
            risks.add('table_or_index_lock_and_capacity_review')
        elif normalized[:2] == ['ALTER', 'TABLE'] and 'ADD' in words and 'ALTER' not in words[1:] and 'DO' not in words:
            risks.add('access_exclusive_lock_and_default_review')
        else:
            raise ValidationError('sql_statement_requires_manual_review')
        # Unknown executable expressions/extensions must not silently pass.
        allowed_calls = {'NOW', 'NEXTVAL', 'KEY', 'UNIQUE', 'CHECK', 'VARCHAR', 'CHARACTER',
                         'NUMERIC', 'DECIMAL', 'TIMESTAMP', 'TIME', 'VALUES', 'CONFLICT', 'BTREE', 'GIST'}
        for i, (kind, value) in enumerate(s[:-1]):
            if kind in ('word', 'identifier') and s[i + 1] == ('word', '('):
                structural = i > 0 and (s[i - 1][1].upper() in ('TABLE', 'ON', 'INTO', 'REFERENCES')
                                             or (s[0][1] == 'CREATE' and i in (2, 3)))
                if not structural and value.upper() not in allowed_calls:
                    raise ValidationError('sql_expression_requires_manual_review')
    return sorted(risks)


def pending(registry, installed):
    if not registry or len(registry) != len(set(registry)) or registry != sorted(registry):
        raise ValidationError('migration_registry_invalid')
    if any(not re.fullmatch(r'[0-9]{17}(?:-[a-zA-Z0-9_-]+)?', v) for v in registry):
        raise ValidationError('migration_name_invalid')
    if installed not in registry:
        raise ValidationError('baseline_version_unknown_no_empty_bootstrap')
    return registry[registry.index(installed) + 1:]


def load_registry():
    registry = [line.strip() for line in (MIGRATIONS / 'migration_registry.txt').read_text().splitlines()
                if line.strip() and not line.lstrip().startswith('#')]
    # Serverpod 3.4.11's FileSystemMigrationArtifactStore lists/sorts directories.
    # Require the generated registry to agree, including unregistered artifacts.
    directories = sorted(p.name for p in MIGRATIONS.iterdir() if p.is_dir())
    if registry != directories or any(p.is_symlink() for p in MIGRATIONS.iterdir()):
        raise ValidationError('migration_registry_directory_mismatch')
    return registry


def checked_backup(c, now=None):
    root = Path(c['data_dir'])
    state = json.loads((root / 'state.json').read_text())
    if not state['records']:
        raise ValidationError('backup_missing')
    record = max(state['records'], key=lambda r: r['utc'])
    age = ((now or b.utcnow()) - dt.datetime.fromisoformat(record['utc'])).total_seconds()
    if not 0 <= age <= 86400:
        raise ValidationError('backup_freshness_24h_failed')
    if not secondary.NAME.fullmatch(record['file']) or record['installation'] != state['installation']:
        raise ValidationError('backup_identity_invalid')
    primary = root / 'archives' / record['file']
    external = secondary.target_directory(c)
    index = json.loads((external / secondary.INDEX).read_text())
    if index['installation'] != state['installation'] or not any(
        x['file'] == record['file'] and x['sha256'] == record['sha256'] and x['bytes'] == record['bytes']
        for x in index['records']):
        raise ValidationError('backup_external_index_mismatch')
    for archive in (primary, external / record['file']):
        if archive.is_symlink() or not archive.is_file() or archive.stat().st_size != record['bytes'] or b.digest(archive) != record['sha256']:
            raise ValidationError('backup_integrity_or_external_copy_failed')
    secondary.target_directory(c)  # The approved disk must still be mounted.
    return primary, record


def sprint_check(before, after=None):
    def objects(inv):
        return {k: [r for r in inv['structure'][k] if r[0] == 'public' and r[1] == 'sprints']
                for k in ('indexes', 'constraints', 'triggers')}
    original = objects(before)
    if not CUSTOM <= {r[2] for r in original['indexes']}:
        raise ValidationError('baseline_sprint_custom_objects_missing')
    exclusion = [r for r in original['constraints'] if r[2] == 'sprints_periodos_sem_sobreposicao_por_usuario']
    active = next(r for r in original['indexes'] if r[2] == 'sprints_uma_ativa_por_usuario_idx')
    if (len(exclusion) != 1 or not exclusion[0][3].startswith('EXCLUDE USING gist') or not exclusion[0][4] or
        not active[3].startswith('CREATE UNIQUE INDEX') or ' WHERE ' not in active[3]):
        raise ValidationError('baseline_sprint_custom_semantics_invalid')
    if after is not None and objects(after) != original:
        raise ValidationError('sprint_custom_objects_changed')


def correction_artifacts():
    folder = MIGRATIONS / SPRINT_CORRECTION
    artifacts = {}
    if folder.is_symlink() or {p.name for p in folder.iterdir()} != set(SPRINT_ARTIFACTS):
        raise ValidationError('sprint_correction_artifacts_unexpected')
    for name, digest in SPRINT_ARTIFACTS.items():
        path = folder / name
        if path.is_symlink() or not path.is_file():
            raise ValidationError('sprint_correction_artifact_hash_mismatch')
        content = path.read_bytes()
        if hashlib.sha256(content).hexdigest() != digest:
            raise ValidationError('sprint_correction_artifact_hash_mismatch')
        artifacts[name] = content
    return artifacts


def correction_preflight(db, before, versions):
    correction_artifacts()
    if versions != [SPRINT_CORRECTION] or history(db) != {
        'temdas_backend': SPRINT_BASELINE, 'serverpod': '20260129180959368'
    }:
        raise ValidationError('sprint_correction_baseline_or_sequence_mismatch')
    indexes = [r for r in before['structure']['indexes'] if r[:2] == ['public', 'sprints']]
    constraints = [r for r in before['structure']['constraints'] if r[:2] == ['public', 'sprints']]
    if indexes != [
        ['public', 'sprints', 'sprints_nome_normalizado_idx', 'CREATE UNIQUE INDEX sprints_nome_normalizado_idx ON public.sprints USING btree ("usuarioId", "nomeNormalizado")'],
        ['public', 'sprints', 'sprints_pkey', 'CREATE UNIQUE INDEX sprints_pkey ON public.sprints USING btree (id)'],
    ] or constraints != [
        ['public', 'sprints', 'sprints_fk_0', 'FOREIGN KEY ("usuarioId") REFERENCES usuarios(id)', True],
        ['public', 'sprints', 'sprints_pkey', 'PRIMARY KEY (id)', True],
    ]:
        raise ValidationError('sprint_correction_unexpected_initial_objects')
    if db.query("SELECT to_json(EXISTS(SELECT 1 FROM pg_extension WHERE extname='btree_gist'))"):
        raise ValidationError('sprint_correction_unexpected_initial_extension')
    check_definition(db, json.loads((MIGRATIONS / SPRINT_BASELINE / 'definition.json').read_text()))


def correction_final(db):
    objects = db.query("""SELECT json_agg(json_build_object('name',c.relname,'method',am.amname,
      'unique',i.indisunique,'exclusion',i.indisexclusion,'valid',i.indisvalid,'ready',i.indisready,
      'predicate',pg_get_expr(i.indpred,i.indrelid),
      'elements',(SELECT json_agg(pg_get_indexdef(i.indexrelid,s,true) ORDER BY s)
                  FROM generate_series(1,i.indnkeyatts) s)) ORDER BY c.relname)
      FROM pg_index i JOIN pg_class c ON c.oid=i.indexrelid JOIN pg_am am ON am.oid=c.relam
      WHERE i.indrelid='public.sprints'::regclass
        AND c.relname IN ('sprints_uma_ativa_por_usuario_idx','sprints_periodos_sem_sobreposicao_por_usuario')""")
    common = {'valid': True, 'ready': True}
    expected = [
        dict(common, name='sprints_periodos_sem_sobreposicao_por_usuario', method='gist', unique=False,
             exclusion=True, predicate="(status = ANY (ARRAY['planejada'::text, 'ativa'::text, 'concluida'::text]))",
             elements=['"usuarioId"', 'daterange("dataInicio"::date, "dataFim"::date, \'[]\'::text)']),
        dict(common, name='sprints_uma_ativa_por_usuario_idx', method='btree', unique=True,
             exclusion=False, predicate="(status = 'ativa'::text)", elements=['"usuarioId"']),
    ]
    if objects != expected:
        raise ValidationError('sprint_correction_final_index_semantics_mismatch')
    extension = db.query("""SELECT json_build_array(n.nspname,e.extversion)
      FROM pg_extension e JOIN pg_namespace n ON n.oid=e.extnamespace WHERE e.extname='btree_gist'""")
    if extension != ['extensions', '1.7']:
        raise ValidationError('sprint_correction_final_extension_mismatch')
    constraint_ok = db.query("""SELECT to_json(count(*)=1) FROM pg_constraint
      WHERE conrelid='public.sprints'::regclass
      AND conname='sprints_periodos_sem_sobreposicao_por_usuario' AND contype='x'
      AND convalidated AND NOT condeferrable AND NOT condeferred""")
    if not constraint_ok:
        raise ValidationError('sprint_correction_final_constraint_mismatch')


def correction_delta(db, before, after):
    # Exactly two indexes + one exclusion constraint; no other selected-schema
    # object may disappear/change. Extension members live outside public.
    for kind, original in before['structure'].items():
        current = after['structure'][kind]
        if kind in ('indexes', 'constraints'):
            current = [r for r in current if not (r[:2] == ['public', 'sprints'] and r[2] in CUSTOM)]
        if current != original:
            raise ValidationError('sprint_correction_unexpected_schema_change')
    if before['tables'].keys() != after['tables'].keys():
        raise ValidationError('sprint_correction_unexpected_table_change')
    if before['tables']['public.serverpod_migrations']['rows'] != after['tables']['public.serverpod_migrations']['rows']:
        raise ValidationError('sprint_correction_unexpected_history_rows')
    preserved_data(db, before)
    correction_final(db)


class IsolatedDatabase:
    def __init__(self):
        self.identity = uuid.uuid4().hex
        self.name = 'temdas-migration-' + self.identity
        self.cid = None

    def __enter__(self):
        self.cid = docker('create', '--name', self.name, '--label', LABEL + '=' + self.identity,
                          '--network=none', '--log-driver=none', '--memory=2g', '--cpus=2',
                          '--user=postgres', '--security-opt=no-new-privileges', '--cap-drop=ALL',
                          '--tmpfs=/validation:rw,nosuid,nodev,noexec,size=1073741824,uid=999,gid=999,mode=0700',
                          '--tmpfs=/var/run/postgresql:rw,nosuid,nodev,uid=999,gid=999',
                          '--tmpfs=/var/lib/postgresql/data:rw,nosuid,nodev,noexec,size=1048576,uid=999,gid=999',
                          '-e', 'PGDATA=/validation/data', '-e', 'POSTGRES_HOST_AUTH_METHOD=trust',
                          IMAGE, '-c', 'listen_addresses=', '-c', 'unix_socket_permissions=0700',
                          '-c', 'log_statement=none', stage='docker_create').decode().strip()
        try:
            self.verify()
            docker('start', self.cid, stage='docker_start')
            for _ in range(60):
                try:
                    docker('exec', self.cid, 'pg_isready', '-q', '-h', '/var/run/postgresql', timeout=5)
                    break
                except ValidationError:
                    time.sleep(1)
            else:
                raise ValidationError('docker_database_not_ready')
            docker('exec', self.cid, 'createdb', '-h', '/var/run/postgresql', '-U', 'postgres', 'validation')
            if self.query("SELECT to_json(current_setting('server_version_num')::int)") != 170011:
                raise ValidationError('postgres_version_not_17_11')
            return self
        except BaseException:
            self.__exit__(None, None, None)
            raise

    def verify(self, identity_only=False):
        if not self.cid or not re.fullmatch('[a-f0-9]{64}', self.cid):
            raise ValidationError('temporary_container_identity_missing')
        info = json.loads(docker('inspect', self.cid))[0]
        if (info['Id'] != self.cid or info['Name'] != '/' + self.name or
            info['Config']['Labels'].get(LABEL) != self.identity or info['Config']['Image'] != IMAGE):
            raise ValidationError('temporary_container_identity_or_isolation_failed')
        if not identity_only and (info['HostConfig']['NetworkMode'] != 'none' or info['HostConfig'].get('PortBindings') or
                                 any(m['Type'] in ('bind', 'volume') for m in info['Mounts'])):
            raise ValidationError('temporary_container_identity_or_isolation_failed')

    def execute(self, sql):
        return docker('exec', '-i', self.cid, 'psql', '-X', '-qAt', '-v', 'ON_ERROR_STOP=1',
                      '-v', 'VERBOSITY=sqlstate',
                      '-h', '/var/run/postgresql', '-U', 'postgres', '-d', 'validation',
                      data=("SET extra_float_digits=3; SET datestyle='ISO,YMD'; SET intervalstyle='postgres';\n" + sql).encode(),
                      stage='isolated_sql')

    def query(self, sql):
        return json.loads(self.execute(sql + ';'))

    def __exit__(self, *args):
        if self.cid:
            self.verify(identity_only=True)  # Only our exact ID/name/label/image.
            docker('rm', '-f', self.cid, stage='temporary_cleanup')
            self.cid = None


def restore(db, c, work):
    text = (work / 'roles.sql').read_text()
    roles = re.findall(r'^CREATE ROLE ("(?:[^"]|"")*"|[a-z_][a-z0-9_]*);$', text, re.M)
    if not roles or len(roles) != len(re.findall(r'^CREATE ROLE ', text, re.M)):
        raise ValidationError('baseline_role_names_invalid')
    db.execute('\n'.join('CREATE ROLE ' + role + ' NOLOGIN NOSUPERUSER;' for role in roles if role not in ('postgres', '"postgres"')))
    db.execute('\n'.join('CREATE SCHEMA IF NOT EXISTS ' + b.ident(s) + ';' for s in b.VALIDATION_SCHEMAS))
    toc = b.command([c['pg_bin'] + '/pg_restore', '--list', str(work / 'database.dump')], 'restore_toc', b.pg_env(c, False)).decode()
    extension_sql = b.restore_extension_sql(c, work / 'database.dump', toc, work)
    if extension_sql:
        db.execute(extension_sql)
    toc = '\n'.join(line for line in toc.splitlines() if not re.search(r'\bSCHEMA - (public|auth|storage|supabase_migrations)\b', line))
    docker('exec', '-i', db.cid, 'sh', '-c', 'umask 077; cat > /validation/restore.list', data=toc.encode())
    args = ['exec', '-i', db.cid, 'pg_restore', '--use-list=/validation/restore.list', '--exit-on-error',
            '--no-owner', '--no-privileges', '-h', '/var/run/postgresql', '-U', 'postgres', '-d', 'validation']
    for schema in b.VALIDATION_SCHEMAS:
        args += ['--schema=' + schema]
    docker(*args, data=(work / 'database.dump').read_bytes(), stage='baseline_restore')


def resource_fingerprint(exclude=None):
    ids = sorted(cid for cid in docker('ps', '-aq', '--no-trunc').decode().split() if cid != exclude)
    containers = json.loads(docker('inspect', *ids)) if ids else []
    snapshot = sorted([{'id': x['Id'], 'config': x['Config'], 'mounts': sorted(x['Mounts'], key=lambda m: m['Destination']),
                        'host': x['HostConfig']} for x in containers], key=lambda x: x['id'])
    volumes = sorted(docker('volume', 'ls', '-q').decode().split())
    info = sorted(json.loads(docker('volume', 'inspect', *volumes)), key=lambda x: x['Name']) if volumes else []
    return hashlib.sha256(json.dumps([snapshot, info], sort_keys=True).encode()).hexdigest()


def history(db):
    return db.query("SELECT coalesce(json_object_agg(module,version),'{}') FROM public.serverpod_migrations")


def preserved_data(db, before):
    # Project original columns, so additive nullable columns do not change hashes.
    # History legitimately changes; all other original table data must match.
    for table, expected in before['tables'].items():
        if table == 'public.serverpod_migrations':
            continue
        schema, name = table.split('.', 1)
        columns = [r[2] for r in before['structure']['columns'] if r[:2] == [schema, name]]
        projection = ','.join(b.ident(col) for col in columns)
        result = db.query(f"""SELECT json_build_object('rows',count(*),
            'hash',md5(coalesce(string_agg(md5(to_jsonb(t)::text),'' ORDER BY md5(to_jsonb(t)::text)),'')))
            FROM (SELECT {projection} FROM {b.ident(schema)}.{b.ident(name)}) t""")
        if result != expected:
            raise ValidationError('original_data_changed')


def check_definition(db, definition):
    actual = b.inventory(db)
    for table in definition['tables']:
        schema, name = table['schema'], table['name']
        columns = {r[2]: r for r in actual['structure']['columns'] if r[:2] == [schema, name]}
        if set(columns) != {col['name'] for col in table['columns']}:
            raise ValidationError('target_columns_mismatch')
        for col in table['columns']:
            if columns[col['name']][4] != (not col['isNullable']):
                raise ValidationError('target_nullability_mismatch')
            types = {0: 'text', 1: 'boolean', 2: 'integer', 3: 'double precision',
                     4: 'timestamp without time zone', 5: 'bytea', 6: 'bigint', 7: 'uuid', 8: 'json'}
            if col.get('columnType') not in types:
                raise ValidationError('target_type_requires_manual_review')
            if columns[col['name']][3] != types[col['columnType']]:
                raise ValidationError('target_type_mismatch')
            if columns[col['name']][5] != col.get('columnDefault'):
                raise ValidationError('target_default_mismatch_requires_review')
        indexes = {r[2] for r in actual['structure']['indexes'] if r[:2] == [schema, name]}
        if not {idx['indexName'] for idx in table['indexes']} <= indexes:
            raise ValidationError('target_indexes_missing')
        constraints = {r[2] for r in actual['structure']['constraints'] if r[:2] == [schema, name]}
        if not {fk['constraintName'] for fk in table.get('foreignKeys', [])} <= constraints:
            raise ValidationError('target_foreign_keys_missing')
    if any(not r[4] for r in actual['structure']['constraints']):
        raise ValidationError('unvalidated_constraint')
    for module in definition['installedModules']:
        if history(db).get(module['module']) != module['version']:
            raise ValidationError('module_dependency_version_mismatch')


def source_fingerprint():
    server = MIGRATIONS.parent
    files = [p for folder in ('lib', 'bin', 'migrations') for p in (server / folder).rglob('*')
             if p.is_file() and p.suffix in ('.dart', '.json', '.sql', '.txt', '.yaml')]
    files += [server / 'pubspec.yaml', server.parent / 'pubspec.yaml', server.parent / 'pubspec.lock']
    if not re.search(r'^  serverpod: 3\.4\.11$', (server / 'pubspec.yaml').read_text(), re.M):
        raise ValidationError('backend_version_requires_review')
    h = hashlib.sha256()
    for path in sorted(files):
        if path.is_symlink():
            raise ValidationError('source_artifact_symlink')
        h.update(str(path.relative_to(server.parent)).encode() + b'\0' + path.read_bytes())
    return h.hexdigest()


def rehearsal(db, versions, before):
    results = []
    for version in versions:
        folder = MIGRATIONS / version
        sql = (folder / 'migration.sql').read_text()
        corrective = version == SPRINT_CORRECTION
        if corrective:
            correction_preflight(db, before, versions)
            artifacts = correction_artifacts()
            sql = artifacts['migration.sql'].decode()
            migration = json.loads(artifacts['migration.json'])
            definition = json.loads(artifacts['definition.json'])
            risks = ['reviewed_sprint_correction', 'access_exclusive_lock_wait_timeout_5s', 'trusted_extension_1_7_in_extensions']
        else:
            risks = inspect_sql(sql)
            migration = json.loads((folder / 'migration.json').read_text())
            definition = json.loads((folder / 'definition.json').read_text())
        if (migration.get('warnings') or definition.get('moduleName') != 'temdas_backend' or
            migration.get('migrationApiVersion') != 1 or definition.get('migrationApiVersion') != 1):
            raise ValidationError('migration_metadata_requires_review')
        # Same transaction-wrapped files and registry ordering as Serverpod 3.4.11.
        db.execute("SET lock_timeout='5s'; SET statement_timeout='60s';\n" + sql)
        after = b.inventory(db)
        if corrective:
            correction_delta(db, before, after)
        else:
            sprint_check(before, after)
        preserved_data(db, before)
        if history(db).get('temdas_backend') != version:
            raise ValidationError('serverpod_history_not_updated')
        check_definition(db, definition)
        results.append({'version': version, 'sql_sha256': hashlib.sha256(sql.encode()).hexdigest(), 'risks': risks})
    return results


def validate(c):
    with rehearsal_lock():
        return _validate(c)


def _validate(c):
    archive, record = checked_backup(c)
    registry = load_registry()
    fingerprint = resource_fingerprint()
    source = source_fingerprint()
    evidence = {'backup_integrity_verified': True, 'second_copy_verified': True,
                'backup_utc': record['utc'], 'backup_sha256': record['sha256'],
                'backend_and_migrations_sha256': source}
    try:
        with tempfile.TemporaryDirectory(prefix='temdas-migration-') as directory:
            work = Path(directory)
            b.decrypt(c, archive, work / 'payload.tar')
            b.extract_payload(work / 'payload.tar', work)
            manifest = json.loads((work / 'manifest.json').read_text())
            if (manifest['project_ref'] != b.PROD or manifest['server_version_num'] != 170011 or
                manifest['utc'] != record['utc'] or b.digest(work / 'database.dump') != manifest['database_sha256'] or
                b.digest(work / 'roles.sql') != manifest['roles_sha256']):
                raise ValidationError('baseline_integrity_or_version_failed')
            with IsolatedDatabase() as db:
                restore(db, c, work)
                before = b.inventory(db)
                if before != manifest['inventory']:
                    raise ValidationError('baseline_restore_inventory_mismatch')
                evidence['baseline_restored_inventory_verified'] = True
                versions = pending(registry, history(db).get('temdas_backend'))
                evidence['pending_versions_in_snapshot'] = versions
                if versions == [SPRINT_CORRECTION]:
                    correction_preflight(db, before, versions)
                else:
                    sprint_check(before)
                results = rehearsal(db, versions, before)
    except ValidationError as error:
        error.evidence = evidence
        raise
    finally:
        if resource_fingerprint() != fingerprint:
            raise ValidationError('existing_docker_resources_metadata_changed')
        evidence['original_docker_resources_metadata_unchanged'] = True
    if source_fingerprint() != source:
        raise ValidationError('source_changed_during_rehearsal')
    return {'status': 'rehearsal_passed_requires_review', 'backup_sha256': record['sha256'],
            'backup_utc': record['utc'], 'pending_migrations': results, 'image': IMAGE,
            'original_docker_resources_metadata_unchanged': True, 'remote_database_access': False,
            'backend_and_migrations_sha256': source,
            'production_authorized': False, 'human_approval_required': True,
            'remaining_gates': ['current_prod_history_read_only_comparison', 'sql_human_review',
                                'backend_forward_and_rollback_compatibility', 'recovery_plan_review',
                                'supabase_managed_extensions_roles_and_services_review',
                                'explicit_separate_production_approval']}


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument('--config', type=Path, default=Path.home() / '.config/temdas-backup/config.json')
    args = parser.parse_args()
    try:
        c = b.load_config(args.config, needs_source_credentials=False)
        with (Path(c['data_dir']) / 'backup.lock').open('a') as lock:
            fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            report = validate(c)
        print(json.dumps(report, sort_keys=True))
    except (ValidationError, b.BackupError, secondary.SecondaryError) as error:
        print(json.dumps({'status': 'blocked', 'reason': str(error), 'production_authorized': False,
                          'evidence': getattr(error, 'evidence', {})}))
        return 1
    except (OSError, ValueError, KeyError, TypeError):
        print(json.dumps({'status': 'blocked', 'reason': 'invalid_environment_or_artifact', 'production_authorized': False}))
        return 1
    return 0


if __name__ == '__main__':
    sys.exit(main())
