"""Collect exact Ubuntu sources, including superseded Built-Using versions.

Prefer APT's authenticated indexes. Historical fallback uses Ubuntu's documented
Launchpad primary-source endpoint over HTTPS and verifies descriptor identity,
then every payload size/SHA-256. It retains, but does not independently verify,
the historical descriptor's OpenPGP signature.
"""
import hashlib
import pathlib
import re
import shutil
import subprocess
import sys
import tempfile
from email.parser import Parser
from urllib.parse import quote


def download(url, destination):
    subprocess.run(['curl', '--fail', '--location', '--retry', '3',
                    '--connect-timeout', '20', '--max-time', '600',
                    '--proto', '=https', '--proto-redir', '=https',
                    '--output', str(destination), url], check=True)


def digest(path):
    with path.open('rb') as stream:
        return hashlib.file_digest(stream, 'sha256').hexdigest()


def read_descriptor(path, name, version):
    if path.stat().st_size > 2 * 1024 * 1024:
        raise ValueError('Source descriptor is unexpectedly large.')
    text = path.read_text(encoding='utf-8')
    if text.startswith('-----BEGIN PGP SIGNED MESSAGE-----'):
        text = text.split('\n\n', 1)[1].split('\n-----BEGIN PGP SIGNATURE-----', 1)[0]
        text = '\n'.join(line[2:] if line.startswith('- ') else line for line in text.splitlines())
    fields = Parser().parsestr(text)
    for field, expected in [('Source', name), ('Version', version)]:
        if len(fields.get_all(field, [])) != 1 or fields[field].strip() != expected:
            raise ValueError(f'Descriptor {field} does not match {name}={version}.')
    if len(fields.get_all('Checksums-Sha256', [])) != 1:
        raise ValueError('Descriptor must provide one SHA-256 payload list.')
    payloads = []
    names = set()
    for line in fields['Checksums-Sha256'].splitlines():
        if not line.strip():
            continue
        parts = line.split()
        if len(parts) != 3:
            raise ValueError('Invalid source SHA-256 record.')
        sha256, size, filename = parts
        if (not re.fullmatch(r'[a-fA-F0-9]{64}', sha256)
                or not size.isdigit() or int(size) <= 0
                or not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9+._~:-]*', filename)
                or filename in names):
            raise ValueError('Unsafe or invalid source payload record.')
        names.add(filename)
        payloads.append((filename, int(size), sha256.lower()))
    if not payloads:
        raise ValueError('Source descriptor contains no payloads.')
    return payloads


def fetch_historical_source(source, name, version):
    if not re.fullmatch(r'[a-z0-9][a-z0-9+.-]*', name):
        raise ValueError('Invalid Ubuntu source package name.')
    if not re.fullmatch(r'[a-zA-Z0-9][a-zA-Z0-9+.:~_-]*', version):
        raise ValueError('Invalid Ubuntu source package version.')
    # Debian epochs belong in the version URL, not in archive filenames.
    descriptor_name = name + '_' + version.split(':', 1)[-1] + '.dsc'
    base_url = ('https://launchpad.net/ubuntu/+archive/primary/+sourcefiles/'
                + quote(name, safe='') + '/' + quote(version, safe='') + '/')
    print(f'Fetching exact historical Ubuntu source: {name}={version}', flush=True)
    with tempfile.TemporaryDirectory(prefix='ubuntu-source-', dir=source) as folder:
        staging = pathlib.Path(folder)
        descriptor = staging / descriptor_name
        download(base_url + quote(descriptor_name, safe=''), descriptor)
        payloads = read_descriptor(descriptor, name, version)
        files = [descriptor]
        for filename, size, sha256 in payloads:
            destination = staging / filename
            download(base_url + quote(filename, safe=''), destination)
            if destination.stat().st_size != size or digest(destination) != sha256:
                raise ValueError(f'Historical source size/SHA-256 mismatch: {filename}')
            files.append(destination)
        # Validate every payload before committing any file to the source bundle.
        for file in files:
            target = source / file.name
            if target.exists() and digest(target) != digest(file):
                raise ValueError(f'Conflicting retained source filename: {file.name}')
        for file in files:
            shutil.copy2(file, source / file.name)
    provenance = source / (name + '_' + version.split(':', 1)[-1] + '-origin.txt')
    provenance.write_text(
        'Source: ' + name + '\nVersion: ' + version + '\n'
        'Descriptor: ' + base_url + quote(descriptor_name, safe='') + '\n'
        'Delivery: official Ubuntu Launchpad primary archive over HTTPS.\n'
        'Validation: descriptor Source/Version; all payload SHA-256 hashes and sizes.\n'
        'Historical descriptor OpenPGP signature retained, not independently verified.\n',
        encoding='utf-8')


def main(source, notices):
    source.mkdir(parents=True, exist_ok=True)
    notices.mkdir(parents=True, exist_ok=True)
    packages = ['gcc-mingw-w64-x86-64-posix', 'gcc-mingw-w64-x86-64-posix-runtime',
                'gcc-mingw-w64-base', 'mingw-w64-common', 'mingw-w64-x86-64-dev',
                'binutils-mingw-w64-x86-64', 'nasm']
    sources = set()
    gcc_inputs = set()
    for package in packages:
        text = subprocess.check_output(['dpkg-query', '-W', '-f',
            '${source:Package}\n${source:Version}\n${Built-Using}\n${Static-Built-Using}\n', package], text=True)
        lines = text.splitlines()
        sources.add((lines[0], lines[1]))
        for name, version in re.findall(r'([a-zA-Z0-9.+-]+)\s*\(=\s*([^\)]+)\)', '\n'.join(lines[2:])):
            sources.add((name, version))
            if re.fullmatch(r'gcc-\d+', name):
                gcc_inputs.add((name, version))
        copyright_file = pathlib.Path('/usr/share/doc') / package / 'copyright'
        if not copyright_file.is_file():
            raise SystemExit(f'Missing toolchain notice: {package}')
        (notices / (package + '-copyright.txt')).write_bytes(copyright_file.read_bytes())
        (source / (package + '-metadata.txt')).write_text(text)
    if not gcc_inputs:
        raise SystemExit('Compiler metadata did not identify exact GCC Built-Using sources. Stop rather than ship an incomplete runtime-source bundle.')
    for name, version in sorted(sources):
        try:
            subprocess.run(['apt-get', 'source', '--download-only', name + '=' + version], cwd=source, check=True)
        except subprocess.CalledProcessError:
            fetch_historical_source(source, name, version)
    (source / 'source-packages.txt').write_text(''.join(f'{name}={version}\n' for name, version in sorted(sources)))


if __name__ == '__main__':
    if len(sys.argv) != 3:
        raise SystemExit('Usage: collect-toolchain.py SOURCE_DIRECTORY NOTICES_DIRECTORY')
    main(*map(pathlib.Path, sys.argv[1:]))
