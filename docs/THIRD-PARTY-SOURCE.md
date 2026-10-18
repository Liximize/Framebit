# FFmpeg and other third-party source

Third-party license permissions are separate from Framebit's proprietary free-use terms.

## Observed preview build

The uploaded installed-app archive reports FFmpeg `9.0.2-full_build-www.gyan.dev`, configured with GPL/version3 support and statically included external libraries. Its retained records are in [licenses/ffmpeg-observed](../licenses/ffmpeg-observed/BUILD.txt). These records identify what that archive reports; they do not independently authenticate the executable or identify every external library revision.

The provider currently identifies FFmpeg release 9.0.2 with upstream commit [`946fcce07b`](https://github.com/FFmpeg/FFmpeg/commit/946fcce07b). That is a provenance lead, **not a complete corresponding-source bundle** for a binary with many statically included libraries.

## Release-specific source materials

For a redistribution release, its exact FFmpeg executable and included libraries must be paired with the applicable license texts, corresponding source, modifications and build materials required by their licenses. Source-download instructions must identify that release's actual materials rather than pointing generically at a newer branch.

This documentation package contains license texts and observed build records. It does not yet provide the complete matching FFmpeg/dependency source bundle or certify that a published installer meets every redistribution requirement. That release work remains pending; this page must be updated with the real source asset names and links when the materials are assembled.

Useful upstream references:

- [FFmpeg licensing](https://ffmpeg.org/legal.html)
- [Gyan's Windows FFmpeg builds](https://www.gyan.dev/ffmpeg/builds/)
- [GNU GPLv3](https://www.gnu.org/licenses/gpl-3.0.html)

Other bundled components retain their own source and notice requirements. See [Third-party notices](../THIRD_PARTY_NOTICES.md).
