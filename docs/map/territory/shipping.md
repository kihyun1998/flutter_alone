# shipping

## What it is
Publishing the package to pub.dev: the package metadata and version, what the published archive includes, the release notes, and the CocoaPods spec the macOS build reads.

## Governing decisions
**None.**

## Design model
From the source:
- `pubspec.yaml` holds the published version (4.1.0) and the constraints consumers resolve against: `sdk >=3.0.0 <4.0.0`, `flutter >=3.0.0`, `plugin_platform_interface ^2.0.2`, dev `flutter_lints: any`. No root lockfile is committed.
- `.pubignore` *replaces* `.gitignore` for publishing, so it repeats build excludes and adds repo/agent metadata (`docs/`, `CLAUDE.md`) — this map is never published (commits 4de85b5, 386484a).
- `CHANGELOG.md` is the release record; each version lists user-visible changes by platform.
- `macos/flutter_alone.podspec` — `source_files = 'Classes/**/*'`, platform `osx 10.11`; the privacy manifest's resource bundle is commented out.
- Windows sources must stay ASCII-only: consumer MSVC builds on non-UTF-8 code pages (CP949) fail with C4819 promoted by `/WX` (CHANGELOG 4.0.3).

## Code
- `pubspec.yaml`, `.pubignore`, `CHANGELOG.md`, `LICENSE`, `README.md`, `GUIDE.md`
- `macos/flutter_alone.podspec`, `macos/Resources/PrivacyInfo.xcprivacy`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [dart-api](dart-api.md), [configuration](configuration.md) — published API; a change here is a version decision.
- [plugin-registration](plugin-registration.md) — sources listed in CMake/podspec are what consumers compile.
- [ci](ci.md) — CI pins its own Flutter version; the `environment` floor here is not what CI tests.

## Known holes / open
- `macos/flutter_alone.podspec` says version 3.2.4 and homepage `github.com/kihyun-park/flutter_alone`, not 4.1.0 / `kihyun1998` — not intentionally left (maintainer, 2026-10-24).
- `flutter_lints: any` in dev dependencies; whether `any` is intended is open ([#21](https://github.com/kihyun1998/flutter_alone/issues/21) raises it).
- Windows ASCII-only rule is enforced by nothing but review.
