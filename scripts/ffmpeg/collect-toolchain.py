"""Retain distro runtime/compiler sources and notices for the exact packages used.
Ubuntu 24.04; deb-src repositories must be enabled. Runs without sudo.
"""
import pathlib, re, subprocess, sys

source, notices = map(pathlib.Path, sys.argv[1:])
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
    subprocess.run(['apt-get', 'source', '--download-only', name + '=' + version], cwd=source, check=True)
(source / 'source-packages.txt').write_text(''.join(f'{name}={version}\n' for name,version in sorted(sources)))
