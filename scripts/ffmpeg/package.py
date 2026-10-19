"""Bind the generated executable and source bundle. Never auto-certify review."""
import hashlib,json,pathlib,shutil,sys
root=pathlib.Path(sys.argv[1])
digest=lambda p:hashlib.sha256(p.read_bytes()).hexdigest()
sources=[{'file':p.name,'sha256':digest(p)} for p in sorted((root/'materials/sources').iterdir()) if p.is_file()]
for folder in (root/'notices', root/'materials/notices'):
    folder.mkdir(parents=True,exist_ok=True)
    (folder/'FRAMEBIT-FFMPEG.txt').write_text(
        'Framebit-controlled FFmpeg distribution. FFmpeg and x264 retain their upstream GPL terms.\n'
        'The Framebit application is a separate component with separate terms.\n'
        'See ORIGINS.txt, accompanying license texts, exact source/build archive and toolchain notices.\n'
        'No GPL permissions are restricted by the Framebit application license.\n'
        'Built-in codecs/filters plus x264; no enable-nonfree, network inputs or external codec packs.\n')
shutil.copytree(root/'notices',root/'materials/notices',dirs_exist_ok=True)
shutil.copy2(root/'ORIGINS.txt',root/'materials/notices/ORIGINS.txt')
manifest={'schema':1,'ffmpegSha256':digest(root/'bin/ffmpeg.exe'),
          'correspondingSourceReviewed':False,'sourceArchives':sources,
          'producer':'Framebit source build','windowsSmokeTestPassed':False}
(root/'materials/release-materials.json').write_text(json.dumps(manifest,indent=2)+'\n')
files={str(p.relative_to(root)):digest(p) for p in sorted(root.rglob('*')) if p.is_file() and p.name!='build.log'}
(root/'SHA256SUMS.json').write_text(json.dumps(files,indent=2)+'\n')
