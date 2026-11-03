#!/usr/bin/env python3
"""Run Sprint/AAL2 integration tests on an owned, disposable local database.

Bootstraps the latest clean schema; never executes migration.sql, connects to
shared databases, mounts existing volumes or uses production data/credentials.
"""
import json
import os
from pathlib import Path
import subprocess
import sys
import time
import uuid
from contextlib import nullcontext

from pg_latency_proxy import PgLatencyProxy

ROOT = Path(__file__).resolve().parents[2]
SERVER = ROOT / 'serverpod/temdas_backend/temdas_backend_server'
IMAGE = 'postgres:17.11-bookworm@sha256:839fbb5a4942a7758dd93e18b42ea5649807491a0545b5eeeb8f0b8bb11857a5'

def run(args, **kwargs):
    return subprocess.run(args, check=True, **kwargs)

def main():
    name = 'temdas-spr-tests-' + uuid.uuid4().hex
    cid = None
    try:
        cid = subprocess.check_output(['docker', '--host=unix:///var/run/docker.sock', 'create', '--name', name,
            '--label', 'br.com.temdas.sprint-tests=' + name, '--log-driver=none',
            '--memory=1g', '--cpus=2', '--security-opt=no-new-privileges',
            '--tmpfs', '/var/lib/postgresql/data:rw,nosuid,nodev,size=536870912',
            '-p', '127.0.0.1::5432', '-e', 'POSTGRES_HOST_AUTH_METHOD=trust',
            '-e', 'POSTGRES_DB=temdas_backend_test', IMAGE], text=True).strip()
        run(['docker', 'start', cid], stdout=subprocess.DEVNULL)
        for _ in range(60):
            ready = subprocess.run(['docker', 'exec', cid, 'pg_isready', '-q', '-h', '127.0.0.1', '-U', 'postgres'], capture_output=True)
            if ready.returncode == 0:
                break
            time.sleep(.5)
        else:
            raise RuntimeError('Disposable database did not start')
        port = subprocess.check_output(['docker', 'port', cid, '5432/tcp'], text=True).strip().rsplit(':',1)[1]
        migrations = SERVER / 'migrations'
        version = (migrations / 'migration_registry.txt').read_text().splitlines()[-1]
        definition = (migrations / version / 'definition.sql').read_bytes()
        run(['docker', 'exec', '-i', cid, 'psql', '-X', '-q', '-v', 'ON_ERROR_STOP=1',
            '-U', 'postgres', '-d', 'temdas_backend_test'], input=definition, capture_output=True)
        env = {k:v for k,v in os.environ.items() if not k.startswith(('SERVERPOD_', 'PG'))}
        env.update(SERVERPOD_DATABASE_HOST='127.0.0.1', SERVERPOD_DATABASE_PORT=port,
            SERVERPOD_DATABASE_NAME='temdas_backend_test', SERVERPOD_DATABASE_USER='postgres')
        tests = sys.argv[1:] or ['test/integration/sprint_endpoint_test.dart', 'test/integration/ownership_aal2_test.dart']
        print(json.dumps({'schema':version, 'database':'disposable-local', 'migration_sql_executed':False, 'tests':tests}), flush=True)
        benchmark = os.environ.get('TEMDAS_SPR_BENCHMARK') == '1'
        with PgLatencyProxy(port) if benchmark else nullcontext() as proxy:
            if proxy:
                env['SERVERPOD_DATABASE_PORT'] = str(proxy.port)
                env['TEMDAS_SPR_PROXY_CONTROL_PORT'] = str(proxy.control_port)
            # Only explicitly opted-in, owned loopback infrastructure is exposed
            # to the benchmark; never inherit an external control endpoint.
            else:
                env.pop('TEMDAS_SPR_PROXY_CONTROL_PORT', None)
            run(['dart','test','--concurrency=1','--reporter=expanded', *tests], cwd=SERVER, env=env)
    finally:
        if cid:
            info = json.loads(subprocess.check_output(['docker','inspect',cid]))[0]
            if info['Name'] != '/' + name or info['Config']['Labels'].get('br.com.temdas.sprint-tests') != name:
                raise RuntimeError('Refusing cleanup: container identity mismatch')
            run(['docker','rm','-f',cid], stdout=subprocess.DEVNULL)

if __name__ == '__main__':
    main()
