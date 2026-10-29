#!/usr/bin/env python3
"""Extract signed official PGDG packages for Ubuntu 24.04 into a user directory.

No sudo, global APT configuration, service registration, or cluster creation.
Does not replace an existing tool installation; updates require explicit review.
"""
import argparse
import os
import pwd
from pathlib import Path
import subprocess
import tempfile
import urllib.request


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument('--root', type=Path, default=Path.home() / '.local/share/temdas-backup/tools')
    args = parser.parse_args()
    os.umask(0o077)
    root = args.root.resolve()
    for parent in Path(__file__).resolve().parents:
        if (parent / '.git').exists() and root.is_relative_to(parent):
            raise RuntimeError('Tools must be outside Git')
    binary = root / 'usr/lib/postgresql/17/bin/pg_dump'
    if binary.exists():
        print('PostgreSQL 17 tools already present; no replacement performed.')
        return
    with tempfile.TemporaryDirectory(prefix='temdas-pgdg-') as work:
        work = Path(work)
        for folder in ['lists/partial', 'archives/partial', 'downloads', 'gpg']:
            (work / folder).mkdir(parents=True, exist_ok=True)
        ca = urllib.request.urlopen('https://www.postgresql.org/media/keys/ACCC4CF8.asc', timeout=30).read()
        (work / 'key.asc').write_bytes(ca)
        subprocess.run(['gpg', '--homedir', str(work / 'gpg'), '--batch', '--dearmor', '--output', str(work / 'key.gpg'), str(work / 'key.asc')], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        (work / 'sources.list').write_text(f'deb [signed-by={work / "key.gpg"}] https://apt.postgresql.org/pub/repos/apt noble-pgdg main\n')
        base = ['apt-get', '-o', 'Dir::Etc::sourcelist=' + str(work / 'sources.list'), '-o', 'Dir::Etc::sourceparts=-', '-o', 'Dir::State::lists=' + str(work / 'lists'), '-o', 'Dir::Cache::archives=' + str(work / 'archives'), '-o', 'APT::Sandbox::User=' + pwd.getpwuid(os.getuid()).pw_name]
        subprocess.run(base + ['update'], check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        subprocess.run(base + ['download', 'postgresql-17', 'postgresql-client-17', 'libpq5'], cwd=work / 'downloads', check=True, stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
        root.mkdir(parents=True, exist_ok=True)
        for package in (work / 'downloads').glob('*.deb'):
            subprocess.run(['dpkg-deb', '-x', str(package), str(root)], check=True)
    print('Official PostgreSQL 17 packages extracted; no global service installed.')


if __name__ == '__main__':
    main()
