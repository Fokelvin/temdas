"""Synthetic package 4 benchmark. Never connects to a shared or external DB."""
import json
import os
import subprocess
import time
from pathlib import Path

import validate as v

VERSION = '20261029183226724-pacote4-demandas'
BASELINE = '20261029113025000-sprint-integrity'
REPORT = Path('/tmp/temdas-p4-volume-report.json')
class SyntheticDatabase(v.IsolatedDatabase):
    def __enter__(self):
        # Only this owned disposable container gets a larger tmpfs. The original
        # 1GiB harness exhausted space while *generating* 50k fixtures (53100).
        self.cid = v.docker('create', '--name', self.name, '--label', v.LABEL+'='+self.identity,
          '--network=none','--log-driver=none','--memory=3g','--cpus=2','--user=postgres',
          '--security-opt=no-new-privileges','--cap-drop=ALL',
          '--tmpfs','/validation:rw,nosuid,nodev,noexec,size=2147483648,uid=999,gid=999,mode=0700',
          '--tmpfs','/var/run/postgresql:rw,nosuid,nodev,uid=999,gid=999',
          '--tmpfs','/var/lib/postgresql/data:rw,nosuid,nodev,noexec,size=1048576,uid=999,gid=999',
          '-e','PGDATA=/validation/data','-e','POSTGRES_HOST_AUTH_METHOD=trust',
          v.IMAGE,'-c','listen_addresses=','-c','unix_socket_permissions=0700','-c','log_statement=none').decode().strip()
        try:
            self.verify()
            v.docker('start',self.cid)
            for _ in range(60):
                try:
                    v.docker('exec',self.cid,'pg_isready','-q','-h','/var/run/postgresql',timeout=5)
                    break
                except v.ValidationError:
                    time.sleep(1)
            else:
                raise RuntimeError('Disposable PostgreSQL did not become ready')
            v.docker('exec',self.cid,'createdb','-h','/var/run/postgresql','-U','postgres','validation')
            assert self.query("SELECT to_json(current_setting('server_version_num')::int)") == 170011
            return self
        except BaseException:
            self.__exit__(None,None,None)
            raise

    def execute(self, sql):
        args = ['docker','--host=unix:///var/run/docker.sock','exec','-i',self.cid,
                'psql','-X','-qAt','-v','ON_ERROR_STOP=1','-v','VERBOSITY=sqlstate',
                '-h','/var/run/postgresql','-U','postgres','-d','validation']
        result = subprocess.run(args,input=sql.encode(),capture_output=True,timeout=600)
        if result.returncode:
            diagnostic = result.stderr.decode()
            Path('/tmp/temdas-p4-volume-sql-error.txt').write_text(diagnostic)
            raise RuntimeError('Synthetic SQL failed: '+diagnostic[-400:])
        return result.stdout


SQL = (v.MIGRATIONS / VERSION / 'migration.sql').read_text()


def baseline(db, count):
    db.execute('DROP SCHEMA public CASCADE; DROP SCHEMA IF EXISTS extensions CASCADE; CREATE SCHEMA public; CHECKPOINT;')
    db.execute((v.MIGRATIONS / BASELINE / 'definition.sql').read_text())
    definition = (v.MIGRATIONS / VERSION / 'definition.sql').read_text()
    db.execute(definition[definition.index('-- Existing custom triggers/checks'):definition.index('-- Custom Sprint objects')])
    # MD5 chunks vary per row and position: extensive text is not one repeated,
    # highly compressible string. Prefix/suffix exercise Unicode and whitespace.
    db.execute(f'''
      INSERT INTO usuarios ("supabaseUserId", "createdAt")
        SELECT 'synthetic-volume-'||g, '2026-01-01'::timestamp FROM generate_series(1,({count}+499)/500) g;
      WITH texts AS MATERIALIZED (
        SELECT g, '  Descrição ç Δ 😀 '||E'\n'||d.texto||'  ' AS descricao,
          '  Observação antiga ç Δ 😀 '||E'\n'||o.texto||'  ' AS observacoes
        FROM generate_series(1,{count}) g
        CROSS JOIN LATERAL (SELECT string_agg(md5(g::text||'/d/'||k),'' ORDER BY k) AS texto
          FROM generate_series(1,CASE WHEN g%997=0 THEN 8192 ELSE 128 END) k) d
        CROSS JOIN LATERAL (SELECT string_agg(md5(g::text||'/o/'||k),'' ORDER BY k) AS texto
          FROM generate_series(1,CASE WHEN g%997=0 THEN 8192 ELSE 128 END) k) o
      )
      INSERT INTO demandas ("usuarioId", "demandaPaiId", titulo, descricao, observacoes,
        status, prioridade, "tempoEstimadoMinutos", "tempoExecutadoMinutos", "criadoEm", "atualizadoEm")
      SELECT (g-1)/500+1, CASE WHEN g%10=0 THEN g-1 END, 'Sintética '||g,
        CASE g%6 WHEN 0 THEN NULL WHEN 1 THEN E' \n\t ' WHEN 4 THEN '' ELSE descricao END,
        CASE g%6 WHEN 3 THEN NULL WHEN 4 THEN '' ELSE observacoes END,
        'aberta','media',120,105,'2026-01-01','2026-01-01'
      FROM texts ORDER BY g;
      INSERT INTO registros_tempo ("demandaId", "inicioEm", "duracaoMinutos", "criadoEm")
        SELECT d.id, '2026-01-01'::timestamp + (((d.id-1)%500)*4+s-1)*interval '1 hour',
          ((s-1)%3+1)*15, '2026-01-01'::timestamp FROM demandas d CROSS JOIN generate_series(1,4) s;
      INSERT INTO sprints ("usuarioId",nome,"nomeNormalizado","dataInicio","dataFim",status)
        SELECT id,'Sintética '||id,'sintética '||id,'2026-01-01','2026-12-31','planejada' FROM usuarios;
      INSERT INTO sprints_demandas ("sprintId","demandaId")
        SELECT "usuarioId",id FROM demandas WHERE id%50=1 ORDER BY id;
      CREATE TABLE expected_demanda AS SELECT id,
        md5((to_jsonb(d)-'descricao')::text) AS restante,
        md5(CASE WHEN observacoes IS NULL OR observacoes='' THEN descricao
          WHEN descricao IS NULL OR descricao !~ '[^[:space:]]' THEN observacoes
          ELSE descricao||E'\n\nObservações anteriores\n'||observacoes END) AS descricao
        FROM demandas d;
      CREATE TABLE expected_tempo AS SELECT id,md5(to_jsonb(r)::text) AS hash FROM registros_tempo r;
    ''')


def snapshot(db):
    return db.query('''SELECT json_build_object(
      'demandas',(SELECT count(*) FROM demandas),'registros_tempo',(SELECT count(*) FROM registros_tempo),
      'usuarios',(SELECT count(*) FROM usuarios),'sprints',(SELECT count(*) FROM sprints),
      'vinculos',(SELECT count(*) FROM sprints_demandas),
      'bytes_texto_antes',(SELECT coalesce(sum(octet_length(descricao)),0)+coalesce(sum(octet_length(observacoes)),0) FROM demandas),
      'maior_descricao_bytes',(SELECT max(octet_length(descricao)) FROM demandas),
      'maior_observacao_bytes',(SELECT max(octet_length(observacoes)) FROM demandas),
      'database_bytes',pg_database_size(current_database()),
      'demandas_hash',(SELECT md5(string_agg(md5(to_jsonb(d)::text),'' ORDER BY id)) FROM demandas d),
      'tempos_hash',(SELECT md5(string_agg(md5(to_jsonb(r)::text),'' ORDER BY id)) FROM registros_tempo r),
      'sprints_hash',(SELECT md5(string_agg(to_jsonb(s)::text,'' ORDER BY id)) FROM sprints s),
      'vinculos_hash',(SELECT md5(string_agg(to_jsonb(s)::text,'' ORDER BY id)) FROM sprints_demandas s),
      'objetos_hash',(SELECT md5(string_agg(pg_get_constraintdef(oid),'' ORDER BY conname)) FROM pg_constraint
        WHERE conrelid IN ('sprints'::regclass,'sprints_demandas'::regclass,'demandas'::regclass)))''')


def integrity(db, migrated):
    if migrated:
        return db.query('''SELECT json_build_object(
          'descricoes_divergentes',(SELECT count(*) FROM demandas d JOIN expected_demanda e USING(id)
            WHERE md5(d.descricao) IS DISTINCT FROM e.descricao),
          'outros_campos_divergentes',(SELECT count(*) FROM demandas d JOIN expected_demanda e USING(id)
            WHERE md5((to_jsonb(d)-'descricao')::text) <> e.restante),
          'tempos_divergentes',(SELECT count(*) FROM registros_tempo r JOIN expected_tempo e USING(id)
            WHERE md5((to_jsonb(r)-'observacao'-'observacaoOrigens')::text) <> e.hash),
          'campos_novos_preenchidos',(SELECT count(*) FROM registros_tempo WHERE observacao IS NOT NULL OR "observacaoOrigens" IS NOT NULL),
          'anotacoes_artificiais',(SELECT count(*) FROM anotacoes_demanda),
          'vinculos_orfaos',(SELECT count(*) FROM sprints_demandas sd LEFT JOIN demandas d ON d.id=sd."demandaId"
            LEFT JOIN sprints s ON s.id=sd."sprintId" WHERE d.id IS NULL OR s.id IS NULL OR d."usuarioId"<>s."usuarioId"),
          'revisao',(SELECT version FROM serverpod_migrations WHERE module='temdas_backend'))''')
    return db.query('''SELECT json_build_object(
      'tabela_nova_ausente',to_regclass('public.anotacoes_demanda') IS NULL,
      'colunas_novas_ausentes',NOT EXISTS(SELECT 1 FROM information_schema.columns
        WHERE table_name='registros_tempo' AND column_name IN ('observacao','observacaoOrigens')),
      'revisao',(SELECT version FROM serverpod_migrations WHERE module='temdas_backend'))''')


def measure(db, sql):
    start = time.monotonic()
    output = db.execute(sql).decode()
    return round(time.monotonic()-start, 3), output


def expected_failure(db, sql, code):
    start = time.monotonic()
    args = ['docker','exec','-i',db.cid,'psql','-X','-qAt','-v','ON_ERROR_STOP=1',
            '-v','VERBOSITY=sqlstate','-h','/var/run/postgresql','-U','postgres','-d','validation']
    result = subprocess.run(args, input=sql.encode(), capture_output=True, timeout=75)
    elapsed = round(time.monotonic()-start, 3)
    assert result.returncode != 0 and code in result.stderr.decode(), result.stderr.decode()
    checks = integrity(db, False)
    assert checks == {'tabela_nova_ausente': True, 'colunas_novas_ausentes': True, 'revisao': BASELINE}, checks
    return {'duracao_segundos': elapsed, 'sqlstate': code, 'rollback': checks}


def main():
    report = {'postgres':'17.11','cpu_limit':2,'memory_limit':'3GiB','tmpfs_data_limit':'2GiB',
              'network':'none','synthetic_only':True,'migration':VERSION,'perfis':[],
              'primeira_tentativa':{'tmpfs':'1GiB','resultado':'53100 na preparação de 50k; sem executar a migration nesse perfil'}}
    counts = [int(n) for n in os.environ.get('TEMDAS_VOLUME_COUNTS', '10000,50000').split(',') if n]
    if not counts and REPORT.exists():
        report = json.loads(REPORT.read_text())
        report['ajuste_ensaio_rollback'] = 'Comparar dados/schema/revisão, não tamanho físico: páginas/WAL podem crescer mesmo com rollback.'
    report['status'] = 'running'
    REPORT.write_text(json.dumps(report,indent=2,ensure_ascii=False))
    def check_rollback(before, after):
        assert {k:v for k,v in before.items() if k!='database_bytes'} == {k:v for k,v in after.items() if k!='database_bytes'}
        return {'snapshot_logico_igual': True, 'delta_armazenamento_bytes': after['database_bytes']-before['database_bytes']}
    with SyntheticDatabase() as db:
        for count in counts:
            print(f'Preparing synthetic profile: {count} demands / {count*4} time entries', flush=True)
            started = time.monotonic()
            baseline(db,count)
            before = snapshot(db)
            instrumented = SQL.replace('$baseline$;', '''$baseline$;
SELECT json_build_object('lock_timeout',current_setting('lock_timeout'),
  'statement_timeout',current_setting('statement_timeout'));''',1)
            elapsed, output = measure(db,instrumented)
            settings = json.loads(next(line for line in output.splitlines() if line.startswith('{')))
            assert settings == {'lock_timeout':'5s','statement_timeout':'1min'},settings
            checks = integrity(db, True)
            assert checks.pop('revisao') == VERSION
            assert all(value == 0 for value in checks.values()), checks
            after = snapshot(db)
            for key in ['demandas','registros_tempo','usuarios','sprints','vinculos','sprints_hash','vinculos_hash','objetos_hash']:
                assert before[key] == after[key], key
            item = {'geracao_e_preparacao_segundos':round(time.monotonic()-started-elapsed,3),
                    'migration_segundos':elapsed,'before':before,'after':after,'settings':settings,'checks':checks}
            report['perfis'].append(item)
            REPORT.write_text(json.dumps(report,indent=2,ensure_ascii=False))
            print(json.dumps({'demandas':count,'migration_segundos':elapsed,'checks':checks}),flush=True)
        # Exercise the *actual* time limits from the unchanged migration, with
        # intentional local contention and a diagnostic sleep before commit.
        baseline(db,1000)
        before = snapshot(db)
        args = ['docker','exec','-i',db.cid,'psql','-X','-qAt','-v','ON_ERROR_STOP=1',
                '-h','/var/run/postgresql','-U','postgres','-d','validation']
        holder = subprocess.Popen(args,stdin=subprocess.PIPE,stdout=subprocess.PIPE,stderr=subprocess.PIPE,text=True)
        try:
            holder.stdin.write("BEGIN; LOCK TABLE demandas IN ROW EXCLUSIVE MODE; SELECT 'locked';\n")
            holder.stdin.flush()
            assert holder.stdout.readline().strip() == 'locked'
            report['lock_timeout'] = expected_failure(db,SQL,'55P03')
            report['lock_timeout']['integridade'] = check_rollback(before, snapshot(db))
            REPORT.write_text(json.dumps(report,indent=2,ensure_ascii=False))
        finally:
            if holder.poll() is None:
                holder.communicate('ROLLBACK;\n\\q\n',timeout=10)
        print('lock_timeout verified; exercising actual statement_timeout (60 seconds).',flush=True)
        report['statement_timeout'] = expected_failure(db,SQL.replace('COMMIT;','SELECT pg_sleep(61);\nCOMMIT;'),'57014')
        report['statement_timeout']['integridade'] = check_rollback(before, snapshot(db))
        report['owned_database_cleanup'] = 'context-managed; discarded on exit'
    report['status'] = 'passed'
    REPORT.write_text(json.dumps(report,indent=2,ensure_ascii=False))
    print(json.dumps(report,ensure_ascii=False),flush=True)
    print('Owned disposable database removed. Report:',REPORT,flush=True)


if __name__ == '__main__':
    try:
        main()
    except BaseException as error:
        failed = json.loads(REPORT.read_text()) if REPORT.exists() else {}
        failed.update(status='failed', error=str(error)[:500])
        REPORT.write_text(json.dumps(failed,indent=2,ensure_ascii=False))
        raise
