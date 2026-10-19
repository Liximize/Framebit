[CmdletBinding()]
param([Parameter(Mandatory = $true)][string]$DistributionDirectory)
Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$distribution = (Resolve-Path -LiteralPath $DistributionDirectory).Path
$encoder = Join-Path $distribution 'bin\ffmpeg.exe'
$probe = Join-Path $distribution 'bin\ffprobe.exe'
$manifestPath = Join-Path $distribution 'materials\release-materials.json'
$manifest = Get-Content -LiteralPath $manifestPath -Raw | ConvertFrom-Json
if ((Get-FileHash -LiteralPath $encoder -Algorithm SHA256).Hash.ToLowerInvariant() -ne $manifest.ffmpegSha256) {
    throw 'FFmpeg does not match its generated source manifest.'
}
$temporary = Join-Path ([IO.Path]::GetTempPath()) ('Framebit FFmpeg check ' + [Guid]::NewGuid().ToString('N'))
$null = New-Item -ItemType Directory -Path $temporary
# Windows argv quoting; never use Invoke-Expression or shell command evaluation.
function Quote-Argument([string]$Value) {
    if ($Value -notmatch '[\s"]' -and $Value.Length -gt 0) { return $Value }
    return '"' + ([regex]::Replace($Value, '(\\*)"', '$1$1\"') -replace '(\\+)$', '$1$1') + '"'
}
function Invoke-Media([string]$Executable, [string[]]$FFArgs) {
    $info = New-Object Diagnostics.ProcessStartInfo
    $info.FileName = $Executable
    $info.Arguments = (($FFArgs | ForEach-Object { Quote-Argument $_ }) -join ' ')
    $info.WorkingDirectory = $temporary
    $info.UseShellExecute = $false
    $info.CreateNoWindow = $true
    $info.RedirectStandardOutput = $true
    $info.RedirectStandardError = $true
    $info.EnvironmentVariables['PATH'] = (Join-Path $env:SystemRoot 'System32') + ';' + $env:SystemRoot
    $process = New-Object Diagnostics.Process
    $process.StartInfo = $info
    try {
        $null = $process.Start()
        $stdout = $process.StandardOutput.ReadToEndAsync()
        $stderr = $process.StandardError.ReadToEndAsync()
        if (-not $process.WaitForExit(120000)) { $process.Kill(); throw 'FFmpeg compatibility check timed out.' }
        $outputText = $stdout.GetAwaiter().GetResult()
        $errorText = $stderr.GetAwaiter().GetResult()
        if ($process.ExitCode -ne 0) { throw ('Media compatibility check failed: ' + $errorText) }
        return $outputText + $errorText
    } finally { $process.Dispose() }
}
try {
    $version = Invoke-Media $encoder @('-hide_banner', '-version')
    if ($version -notmatch 'framebit1' -or $version -notmatch '--enable-libx264' -or $version -match '--enable-nonfree') {
        throw 'This is not the expected Framebit FFmpeg configuration.'
    }
    # Exercise the same inputs/containers as replay: fMP4 -> disk segments -> concat.
    $null = Invoke-Media $encoder @('-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
        '-f', 'lavfi', '-i', 'testsrc2=size=128x72:rate=30', '-t', '6', '-an',
        '-c:v', 'libx264', '-preset', 'ultrafast', '-g', '60', '-pix_fmt', 'yuv420p',
        '-movflags', '+frag_keyframe+empty_moov', 'fragmented.mp4')
    $null = Invoke-Media $encoder @('-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
        '-i', 'fragmented.mp4', '-map', '0:v:0', '-c', 'copy', '-f', 'segment',
        '-segment_time', '2', '-reset_timestamps', '1', '-segment_list', 'segments.csv',
        '-segment_list_type', 'csv', 'chunk%09d.mp4')
    $chunks = @(Get-ChildItem -LiteralPath $temporary -Filter 'chunk*.mp4' | Sort-Object Name)
    if ($chunks.Count -ne 3) { throw 'The replay segment writer did not produce three expected segments.' }
    @('ffconcat version 1.0') + @($chunks | ForEach-Object { "file '$($_.Name)'" }) |
        Set-Content -LiteralPath (Join-Path $temporary 'join.txt') -Encoding ASCII
    $null = Invoke-Media $encoder @('-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
        '-f', 'concat', '-safe', '1', '-i', 'join.txt', '-c:v', 'copy', '-an', '-movflags', '+faststart', 'joined.mp4')
    # Non-silent independent audio plus default mix, matching the saved clip layout.
    $null = Invoke-Media $encoder @('-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
        '-i', 'joined.mp4', '-f', 'lavfi', '-i', 'sine=frequency=440:sample_rate=48000',
        '-f', 'lavfi', '-i', 'sine=frequency=660:sample_rate=48000', '-f', 'lavfi', '-i', 'sine=frequency=880:sample_rate=48000',
        '-filter_complex', '[1:a]asplit=2[g][gm];[2:a]asplit=2[m][mm];[3:a]asplit=2[o][om];[gm][mm][om]amix=inputs=3:normalize=0,alimiter=limit=0.95[mixed]',
        '-map', '0:v:0', '-map', '[mixed]', '-map', '[g]', '-map', '[m]', '-map', '[o]',
        '-c:v', 'copy', '-c:a', 'aac', '-b:a', '160k', '-t', '6', '-movflags', '+faststart', 'four-track.mp4')
    # Editor trim/speed/concat and mixer chain. Keep all four tracks editable.
    $filters = '[0:v]trim=start=1:end=4,setpts=(PTS-STARTPTS)/1.25,setsar=1,format=yuv420p[v]'
    for ($track = 0; $track -lt 4; $track++) {
        $filters += ";[0:a:$track]atrim=start=1:end=4,asetpts=PTS-STARTPTS,atempo=1.25,aresample=48000,aformat=sample_fmts=fltp:channel_layouts=stereo,volume=0.8,apad,atrim=duration=2.4[a$track]"
    }
    $filters += ';[v][a0][a1][a2][a3]concat=n=1:v=1:a=4[vout][aout][gout][mout][oout]'
    $null = Invoke-Media $encoder @('-hide_banner', '-loglevel', 'error', '-nostdin', '-y',
        '-i', 'four-track.mp4', '-filter_complex', $filters, '-map', '[vout]', '-map', '[aout]',
        '-map', '[gout]', '-map', '[mout]', '-map', '[oout]', '-c:v', 'libx264', '-preset', 'veryfast',
        '-crf', '20', '-pix_fmt', 'yuv420p', '-c:a', 'aac', '-movflags', '+faststart', 'edited.mp4')
    $metadata = (Invoke-Media $probe @('-v', 'quiet', '-show_streams', '-show_format', '-of', 'json', 'edited.mp4')) | ConvertFrom-Json
    if (@($metadata.streams | Where-Object codec_type -eq 'audio').Count -ne 4) { throw 'Independent edited audio tracks were lost.' }
    if (@($metadata.streams | Where-Object codec_type -eq 'video').Count -ne 1) { throw 'Edited video is missing.' }
    if ([Math]::Abs([double]::Parse([string]$metadata.format.duration, [Globalization.CultureInfo]::InvariantCulture) - 2.4) -gt 0.15) {
        throw 'Edited media duration/timing did not match the requested timeline.'
    }
    $null = Invoke-Media $encoder @('-v', 'error', '-nostdin', '-i', 'edited.mp4', '-map', '0', '-f', 'null', '-')
    # Browser proxy, waveform decode and JPEG thumbnails.
    $null = Invoke-Media $encoder @('-v', 'error', '-nostdin', '-y', '-i', 'four-track.mp4',
        '-vf', "scale=w='min(1920,iw)':h=-2", '-t', '0.2', '-c:v', 'libx264', '-preset', 'ultrafast', '-c:a', 'aac', 'proxy.mp4')
    $null = Invoke-Media $encoder @('-v', 'error', '-nostdin', '-y', '-i', 'edited.mp4',
        '-an', '-frames:v', '1', '-vf', 'scale=480:-2', '-q:v', '4', 'thumbnail.jpg')
    $null = Invoke-Media $encoder @('-v', 'error', '-nostdin', '-y', '-i', 'edited.mp4',
        '-map', '0:a:1', '-c:a', 'pcm_s16le', 'audio.wav')
    if ((Get-Item -LiteralPath (Join-Path $temporary 'thumbnail.jpg')).Length -lt 100 -or
        (Get-Item -LiteralPath (Join-Path $temporary 'audio.wav')).Length -lt 1000) { throw 'Thumbnail/audio decoding failed.' }
    $manifest.windowsSmokeTestPassed = $true
    $manifest | ConvertTo-Json -Depth 10 | Set-Content -LiteralPath $manifestPath -Encoding UTF8
    'PASS: Framebit Windows FFmpeg replay segments, concat, four AAC tracks, editing, decode, proxy and thumbnail.' |
        Set-Content -LiteralPath (Join-Path $distribution 'WINDOWS-CHECK.txt') -Encoding UTF8
    foreach ($name in @('encoders', 'decoders', 'filters', 'formats', 'buildconf')) {
        (Invoke-Media $encoder @('-hide_banner', ('-' + $name))) |
            Set-Content -LiteralPath (Join-Path $distribution ($name + '.txt')) -Encoding UTF8
    }
    $hashes = [ordered]@{}
    Get-ChildItem -LiteralPath $distribution -Recurse -File | Where-Object Name -ne 'SHA256SUMS.json' | Sort-Object FullName | ForEach-Object {
        $relative = $_.FullName.Substring($distribution.TrimEnd('\').Length + 1).Replace('\', '/')
        $hashes[$relative] = (Get-FileHash -LiteralPath $_.FullName -Algorithm SHA256).Hash.ToLowerInvariant()
    }
    $hashes | ConvertTo-Json -Depth 5 | Set-Content -LiteralPath (Join-Path $distribution 'SHA256SUMS.json') -Encoding UTF8
    Write-Host 'PASS: Framebit FFmpeg Windows compatibility checks.'
} finally { Remove-Item -LiteralPath $temporary -Recurse -Force }
