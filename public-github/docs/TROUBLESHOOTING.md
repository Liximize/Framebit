# Troubleshooting

## The buffer stopped or a clip did not save

Note the exact message and your app version. Check free space on both the temporary-buffer drive and your save drive. Do not repeatedly start another recorder while Framebit says cleanup is still pending. An interrupted session can lose unsaved replay history; saved files are separate.

Newer test builds may attempt bounded recovery after a capture failure. A restart is an interruption, not evidence that the underlying issue has been solved.

To find logs, press **Win + R**, enter `%LOCALAPPDATA%\SimpleClips`, and look for:

- `errors.log`: recording, save and other application errors.
- `capture-sync.log`: capture/audio timing information written when saving a replay.
- `buffer-diagnostics.log`: detailed buffer-stage diagnostics in builds that include them.
- Matching `.previous` files, if present.

The legacy folder name is retained for compatibility. A log may be absent if that build does not include it or no relevant event has occurred. Review logs before sharing: remove personal paths or information you do not want to publish. Do not upload your whole AppData folder, account tokens or unrelated recordings.

## Missing or out-of-sync audio

Check the selected microphone and enabled audio sources. Try the same saved clip in another player and in Framebit's editor. Report whether audio is absent, early or late, whether the output device changed, and whether the issue began after switching games. Include the relevant `capture-sync.log` entries if available.

## Memory usage is high

Include replay length, resolution, FPS, quality, whether the editor was open and how long buffering had been running. Note whether memory levels off or keeps increasing. The application uses multiple processes, including WebView2, the capture worker and FFmpeg; identify which process or group you measured. There is no published universal 500 MB guarantee.

## A game is not detected

Use **Add game** in Settings as a fallback. Report the game's title and launcher. Detection is used for classification; screen capture should not require every game to appear in an automatic list.

## YouTube is unavailable

YouTube publishing is not yet configured for general availability. A disabled upload action does not require you to install third-party uploading tools. Public Google authentication setup remains pending.

## Updating fails

Record the error and installed version. Finish active editing or saving, then retry from Settings. If necessary, download the setup EXE directly from [official Releases](https://github.com/Liximize/Framebit/releases) and install over the existing app. Do not delete your recordings or settings to troubleshoot an update.

## Report a bug

Use the [bug report form](https://github.com/Liximize/Framebit/issues/new/choose). Include steps, expected behavior, actual behavior, app version, Windows version and relevant hardware. For a security concern, use the route in [SECURITY.md](../SECURITY.md) instead of posting sensitive details publicly.
