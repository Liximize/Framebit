<p align="center"><img src="assets/banner.png?v=2" alt="Framebit — every bit of the moment" width="100%"></p>

<p align="center">
  <a href="https://github.com/Liximize/Framebit/releases/latest"><img alt="Download" src="https://img.shields.io/badge/download-latest%20release-ffe45e?style=flat-square&labelColor=111111"></a>
  <img alt="Windows" src="https://img.shields.io/badge/windows-10%20%2F%2011-74baff?style=flat-square&labelColor=111111">
  <img alt="Version" src="https://img.shields.io/badge/version-1.0.3-c6a0ff?style=flat-square&labelColor=111111">
  <img alt="Free to use" src="https://img.shields.io/badge/licence-free%20to%20use-83e9ad?style=flat-square&labelColor=111111">
</p>

<p align="center">
  A free Windows recorder for the moments you almost missed.<br>
  Keep a replay buffer running, save the last minute, and edit it before you post it.
</p>

---

## Download

| Edition | What it is |
|---|---|
| **Installer** | [Framebit setup](https://github.com/Liximize/Framebit/releases/latest) — recommended. Installs to Program Files, adds Start menu and desktop shortcuts, registers an uninstaller. |
| **Portable** | The portable zip from the same release. Unzip one folder, run `Framebit.exe`. Nothing is installed. |

Windows 10 (1903) or newer, 64-bit. The Microsoft Edge WebView2 Runtime and the Visual C++ 2015–2022 Redistributable are required; both ship inside the setup, and the portable zip carries their installers in `Prerequisites`.

## What it does

**Save what just happened.** A rolling buffer keeps the last 30 seconds to 10 minutes in memory, so when something good happens you press a hotkey and it is already on disk.

**Three audio tracks, if your setup has them.** Game, microphone and everything else are captured separately, so you can mute your friends, boost yourself, or drop the music in the editor.

**An editor that stays out of the way.** Trim, split, delete segments, change speed, and mix the tracks with real faders and level meters. Export a copy as a Finished clip and keep the original untouched.

**A library, not a folder.** Clips are grouped by game, favourites and screenshots, with a seven-day Trash for the ones you delete by accident.

**Optional YouTube.** Connect your channel, upload an edited clip, pick a local thumbnail, add it to a playlist. Entirely optional; nothing is uploaded without you starting it.

**Yours.** Accent colours, custom hotkeys, start with Windows, record from the tray, English and Arabic.

## Install

1. Download `Framebit-1.0.3-preview-setup.exe` from [Releases](https://github.com/Liximize/Framebit/releases).
2. Run it. It installs for all users and asks for permission once.
3. Framebit starts and lives in the system tray. Right-click the tray icon for the menu.

Closing the window sends Framebit to the tray — use **Exit** there to quit it properly.

## Where your files go

| What | Where |
|---|---|
| Clips | `Videos\Framebit` |
| Screenshots | `Pictures\Framebit\Screenshots` |
| Settings | Your Windows user profile |

Setup and uninstall never touch recordings, screenshots or settings. Changing the folders is a setting, not a reinstall.

## Requirements

- Windows 10 build 1903 or newer, or Windows 11, 64-bit.
- Microsoft Edge WebView2 Runtime (present on most Windows 11 PCs).
- Microsoft Visual C++ 2015–2022 Redistributable (x64).
- Hardware encoding works best with a current GPU driver; software encoding works everywhere.

Windows N editions may need the Media Feature Pack before audio capture works.

## Help

- [Getting started](docs/GETTING-STARTED.md)
- [Troubleshooting](docs/TROUBLESHOOTING.md)
- [Report a bug](https://github.com/Liximize/Framebit/issues/new/choose)
- [Privacy](docs/privacy.html) — what stays on your PC, and what leaves it

## Licence

Framebit is free to use, including for monetised recordings. The application, its source and its branding remain the property of the author. Third-party components keep their own licences and are listed in `THIRD_PARTY_NOTICES.md` and in the `licenses` folder of every download.

## Credits

Built with .NET, WebView2, NAudio, ScreenRecorderLib and FFmpeg. The pixel icon set is Pixelarticons; the wordmark and interface use Pixelify Sans and Noto Kufi Arabic. Full texts ship with the app.
