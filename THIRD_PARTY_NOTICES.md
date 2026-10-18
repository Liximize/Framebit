# Third-party notices

Framebit uses separately licensed software and assets. **Framebit's rights-reserved license does not replace or restrict those licenses.** Copyrights belong to their respective holders.

This inventory reflects the supplied preview source and installed-app archive. It is a starting notice set, not a complete inventory of every native/transitive component in a future installer. Each release must carry the notices and source materials required by its exact dependency builds.

| Component | Observed version / use | License / materials |
| --- | --- | --- |
| ScreenRecorderLib | 7.0.1; Windows video recording | [MIT notice](licenses/ScreenRecorderLib-MIT.txt); [upstream](https://github.com/sskodje/ScreenRecorderLib) |
| NAudio and its resolved subpackages | 2.2.1; audio capture and WAV handling | [MIT notice](licenses/NAudio-MIT.txt); [upstream](https://github.com/naudio/NAudio) |
| Microsoft.Web.WebView2 SDK | 1.0.2903.40; embedded interface | [SDK license](licenses/WebView2-SDK.txt); runtime terms are separate |
| Pixelify Sans | Embedded font/subsets | [SIL Open Font License 1.1](licenses/Pixelify-Sans-OFL.txt) |
| Pixelarticons | Pixel-style icon attribution, including the supplied star design | [MIT notice](licenses/Pixelarticons-MIT.txt); [upstream](https://github.com/halfmage/pixelarticons) |
| FFmpeg | Uploaded archive reports `9.0.2-full_build-www.gyan.dev` | Reports **GPL version 3 or later**; see below |
| .NET runtime and native runtime components | Self-contained Windows deployment; exact patch depends on the build | Preserve the runtime's own LICENSE/ThirdPartyNotices and resolved-package notices |
| Microsoft Edge WebView2 Runtime and Microsoft Visual C++ Redistributable | Installer prerequisites | Their separate Microsoft license/redistribution terms apply |

## FFmpeg

The audited archive includes a Gyan FFmpeg full build whose configuration enables `--enable-gpl`, `--enable-version3` and `--enable-libx264`. Its own license output states GPLv3 or later. The [GPLv3 text](licenses/GPL-3.0.txt) and [observed build records](licenses/ffmpeg-observed/BUILD.txt) are included here; [configuration](licenses/ffmpeg-observed/CONFIGURATION.txt) and [license output](licenses/ffmpeg-observed/LICENSE-OUTPUT.txt) are retained separately.

Those records and a license text **are not the complete corresponding source**. Exact FFmpeg/dependency source and build materials must accompany redistribution or be made available through an applicable license-compliant distribution method. A generic link to the latest upstream source is not a substitute for matching source.

See [FFmpeg source distribution](docs/THIRD-PARTY-SOURCE.md), the [FFmpeg legal page](https://ffmpeg.org/legal.html) and the build provider's [distribution page](https://www.gyan.dev/ffmpeg/builds/). Do not infer that every future Framebit installer uses this exact FFmpeg binary.

Framebit invokes FFmpeg as an external executable. This notice does not determine whether any particular distribution is an independent aggregation or a combined derivative work; actual licensing obligations depend on the delivered components and their integration.

## Fonts and icons

The embedded Pixelify Sans font data retains its own OFL terms and attribution, including when subsetted. Icon attribution does not transfer ownership of upstream icon designs to Framebit. The original Framebit mark remains subject to Framebit's own terms to the extent rights are held by its creator.

## Scope and corrections

Bundled components may carry additional upstream notices. Preserve those materials even if they are not listed above. A notice in this repository does not certify that an already-built installer includes it. Report missing attribution or licensing concerns through the [project](https://github.com/Liximize/Framebit/issues).
