#!/usr/bin/env bash
# Run in a clean Ubuntu 24.04 build machine (or the supplied manual workflow).
# Produces a dedicated Windows x64 distribution, never alters installed Framebit.
set -euo pipefail
umask 022
recipe_dir=$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)
out=${1:?Usage: build-win64.sh OUTPUT_DIRECTORY}
mkdir -p -- "$out"
out=$(cd -- "$out" && pwd)
if find "$out" -mindepth 1 -print -quit | read -r _; then
    echo 'Output directory must be empty; existing build materials will not be overwritten.' >&2
    exit 1
fi
work=$(mktemp -d)
trap 'rm -rf -- "$work"' EXIT
exec > >(tee "$out/build.log") 2>&1
export LC_ALL=C TZ=UTC
ffmpeg_version=9.0.2
x264_commit=baee400fa9ced6f5481a728138fed6e867b0ff7f
export SOURCE_DATE_EPOCH=1770000000
cross=x86_64-w64-mingw32-
cc=${cross}gcc-posix
for tool in "$cc" "${cross}objdump" git curl gpg nasm make pkg-config python3 dpkg-query apt-get; do
    command -v "$tool" >/dev/null || { echo "Missing build tool: $tool"; exit 1; }
done
mkdir -p "$out/bin" "$out/notices/toolchain" "$out/materials/sources" "$work/source/scripts/ffmpeg" "$work/source/.github/workflows" "$work/prefix"
cp "$recipe_dir/build-win64.sh" "$recipe_dir/collect-toolchain.py" "$recipe_dir/package.py" "$work/source/scripts/ffmpeg/"
cp "$recipe_dir/../Test-FramebitFFmpeg.ps1" "$work/source/scripts/"
cp "$recipe_dir/../../.github/workflows/build-framebit-ffmpeg.yml" "$work/source/.github/workflows/"
curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
    "https://ffmpeg.org/releases/ffmpeg-$ffmpeg_version.tar.xz" -o "$work/source/ffmpeg.tar.xz"
curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
    "https://ffmpeg.org/releases/ffmpeg-$ffmpeg_version.tar.xz.asc" -o "$work/source/ffmpeg.tar.xz.asc"
curl --fail --location --retry 3 --proto '=https' --tlsv1.2 \
    https://ffmpeg.org/ffmpeg-devel.asc -o "$work/source/ffmpeg-signing-key.asc"
mkdir -m 700 "$work/keyring"
gpg --homedir "$work/keyring" --import "$work/source/ffmpeg-signing-key.asc"
gpg --homedir "$work/keyring" --status-fd 1 --verify \
    "$work/source/ffmpeg.tar.xz.asc" "$work/source/ffmpeg.tar.xz" > "$work/source/ffmpeg-signature.txt"
# VALIDSIG's final field is the primary key fingerprint (or the signer itself).
python3 - "$work/source/ffmpeg-signature.txt" <<'PY'
import sys
lines=open(sys.argv[1]).read().splitlines()
key='FCF986EA15E6E293A5644F10B4322F04D67658D8'
assert any(line.startswith('[GNUPG:] VALIDSIG ') and key in (line.split()[2],line.split()[-1]) for line in lines), 'Unexpected FFmpeg signing key'
PY
tar -xJf "$work/source/ffmpeg.tar.xz" -C "$work"
git init "$work/x264"
git -C "$work/x264" remote add origin https://code.videolan.org/videolan/x264.git
git -C "$work/x264" fetch --depth 1 origin "$x264_commit"
git -C "$work/x264" checkout --detach FETCH_HEAD
test "$(git -C "$work/x264" rev-parse HEAD)" = "$x264_commit"
git -C "$work/x264" archive --format=tar --prefix=x264/ HEAD | gzip -n > "$work/source/x264.tar.gz"
printf '%s\n' "FFmpeg: https://ffmpeg.org/releases/ffmpeg-$ffmpeg_version.tar.xz (upstream PGP verified)" \
    "x264: https://code.videolan.org/videolan/x264.git commit $x264_commit" > "$work/source/ORIGINS.txt"
# Capture exact distro sources, including compiler Built-Using source versions,
# not a link to whichever GCC or MinGW version happens to be latest later.
python3 "$recipe_dir/collect-toolchain.py" "$work/source/toolchain" "$out/notices/toolchain"
"$cc" -v 2> "$work/source/compiler.txt"
dpkg-query -W > "$work/source/installed-packages.txt"
uname -a > "$work/source/platform.txt"
export CC="$cc" AR="${cross}ar" RANLIB="${cross}ranlib" STRIP="${cross}strip"
cd "$work/x264"
./configure --host=x86_64-w64-mingw32 --cross-prefix="$cross" --prefix="$work/prefix" \
    --enable-static --disable-cli --disable-opencl --disable-avs --disable-lavf --disable-swscale \
    --enable-win32thread --bit-depth=8 --extra-ldflags='-static -static-libgcc' \
    2>&1 | tee "$work/source/x264-configure.txt"
make -j "$(nproc)"
make install
mkdir -p "$work/source/x264-build"
cp config.mak config.log "$work/source/x264-build/"
cp COPYING "$out/notices/x264-COPYING.txt"
cp AUTHORS "$out/notices/x264-AUTHORS.txt"
cd "$work/ffmpeg-$ffmpeg_version"
export PKG_CONFIG_LIBDIR="$work/prefix/lib/pkgconfig"
export PKG_CONFIG_PATH=
./configure --prefix="$work/ffmpeg-install" --target-os=mingw32 --arch=x86_64 \
    --enable-cross-compile --cross-prefix="$cross" --cc="$cc" --pkg-config=pkg-config \
    --pkg-config-flags=--static --extra-cflags="-I$work/prefix/include" \
    --extra-ldflags="-L$work/prefix/lib -static -static-libgcc" \
    --disable-autodetect --enable-gpl --enable-libx264 --disable-network \
    --disable-indevs --enable-indev=lavfi --disable-outdevs --disable-ffplay --disable-doc --disable-debug \
    --enable-static --disable-shared --enable-w32threads --disable-pthreads \
    --extra-version=framebit1 2>&1 | tee "$work/source/ffmpeg-configure.txt"
# All built-in codecs/filters remain enabled; no externally downloaded codec
# libraries except x264. Input is local files and pipes, never network URLs.
make -j "$(nproc)"
make install
cp "$work/ffmpeg-install/bin/ffmpeg.exe" "$work/ffmpeg-install/bin/ffprobe.exe" "$out/bin/"
cp COPYING* LICENSE.md CREDITS "$out/notices/"
mkdir -p "$work/source/ffmpeg-build"
cp config.h ffbuild/config.mak ffbuild/config.log "$work/source/ffmpeg-build/"
python3 - "$out" "$cross" <<'PY'
import pathlib,re,subprocess,sys
out=pathlib.Path(sys.argv[1])
allowed={'kernel32.dll','msvcrt.dll','ucrtbase.dll','advapi32.dll','user32.dll','shell32.dll',
 'ole32.dll','oleaut32.dll','ws2_32.dll','bcrypt.dll','secur32.dll','gdi32.dll','comdlg32.dll',
 'avicap32.dll','vfw32.dll','winmm.dll','d3d11.dll','dxgi.dll','dxva2.dll','psapi.dll','shlwapi.dll',
 'ntdll.dll','version.dll','combase.dll','setupapi.dll','powrprof.dll','mfplat.dll','mf.dll',
 'mfuuid.dll','propsys.dll','shcore.dll','windowscodecs.dll'}
for exe in (out/'bin').glob('*.exe'):
    text=subprocess.check_output([sys.argv[2]+'objdump','-p',str(exe)],text=True)
    (out/(exe.stem+'-imports.txt')).write_text(text)
    imports=re.findall(r'DLL Name:\s*(\S+)',text)
    unexpected=[name for name in imports if name.lower() not in allowed and not name.lower().startswith(('api-ms-win-','ext-ms-win-'))]
    assert not unexpected, f'Unbundled or unaudited DLL dependencies: {unexpected}'
PY
cp "$recipe_dir/../Test-FramebitFFmpeg.ps1" "$out/"
cp "$work/source/ORIGINS.txt" "$out/"
# A source snapshot contains exact input archives, build recipe/config/logs,
# distro source archives/patches, toolchain notices and versions. It is separate
# from the installer so ordinary users still download one setup EXE.
cp "$out/build.log" "$work/source/build.log"
tar -cJf "$out/materials/sources/framebit-ffmpeg-source.tar.xz" -C "$work" source
python3 "$recipe_dir/package.py" "$out"
echo 'Build complete. Run Test-FramebitFFmpeg.ps1 on Windows before packaging.'
