# ci

## What it is
What guards a change before it merges: the GitHub Actions workflow (Dart format/analyze/test, native builds of the example and native unit tests on each OS), the standalone native test harnesses it drives, and Dependabot for dependency releases.

## Governing decisions
**None.**

## Design model
From `.github/workflows/ci.yml`:
- Runs on push to `main` and on every pull request. Every job installs Flutter from `flutter-version-file: example/pubspec.yaml`, which is `environment.flutter` and must be an exact version. `.claude/hooks/session-start.sh` reads the same line. This is the single Flutter pin (see Cross-cutting invariants).
- Jobs: `dart` (format with `--set-exit-if-changed`, `flutter analyze`, `flutter test`); `linux` (build example, then `linux/test` gtest); `windows` (build example, then `windows/test` gtest under MSVC); `macos` (build example, then XCTest `RunnerTests`).
- The native harnesses compile the pure seams alone — `lock_file.cc`, `mutex_guard.cpp`, `message_utils.cpp`, `process_utils.cpp` — with GoogleTest v1.15.2 fetched at configure time; the seams must stay free of Flutter/GTK headers to remain testable (commits 60fa1cb, fd10e3a).
- The plugin's activation and dialog code is compiled by the example builds but executed by no test.
- `.github/dependabot.yml`: root pub weekly with `increase-if-necessary`, one PR per dependency (`plugin_platform_interface`, `flutter_lints`) — each a floor decision for consumers, since the root commits no lockfile; `/example` pub and GitHub Actions monthly, each grouped into one PR; all labelled `needs-triage` ([#21](https://github.com/kihyun1998/flutter_alone/issues/21)). Dependabot does not bump the Flutter pin; it is raised by hand.

## Code
- `.github/workflows/ci.yml`
- `.github/dependabot.yml`
- `linux/test/CMakeLists.txt`, `linux/test/lock_file_test.cc`
- `windows/test/CMakeLists.txt`, `windows/test/*.cpp`
- `example/macos/RunnerTests/RunnerTests.swift`
- `test/*.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
- **One Flutter pin, read by CI, Dependabot and the session hook.** The `/example` pub updater resolves with the newest stable Flutter release that satisfies `example/pubspec.yaml`'s `environment.sdk` and `environment.flutter` (dependabot-core `pub/helpers/bin/infer_sdk_versions.dart`; it falls back to `stable` if nothing matches). With an exact `flutter:` there, Dependabot resolves on the same SDK as CI. Before that line existed, `sdk: ^3.6.1` let Dependabot pick the latest stable. It then proposed packages above CI's SDK: `cupertino_icons 2.0.0` needs Dart ^3.12.0, and `mockito 5.8.1` needs `meta ^1.18.3`. Its lockfile also carried that newer Flutter's pins (`meta 1.19.0`, `test_api 0.7.12`). See [#25](https://github.com/kihyun1998/flutter_alone/pull/25). Raising Flutter means editing that one line. A second copy of the version anywhere reopens the gap.

## Blast radius
- [instance-lock-linux](instance-lock-linux.md), [instance-lock-windows](instance-lock-windows.md) — their seams are what the native jobs test; a new dependency in a seam must be added to the harness.
- [example-app](example-app.md) — every native job starts by building the example; an example break turns all three red.
- [shipping](shipping.md) — dependency updates (Dependabot) change what consumers resolve.

## Known holes / open
- Whether Dependabot's first run succeeds is visible only in the repository's Dependabot status, not in CI.
- The root pub updater has no pin. The root `pubspec.yaml`'s `flutter: ">=3.0.0"` is the consumer floor, so it resolves on the latest stable. Since the root commits no lockfile, only the constraint floor it proposes reaches consumers.
- A grouped `/example` PR stops at the first package that does not resolve, so the packages after it go unverified until that one is held back.
- No test runs two real instances against each other on any platform (the commented-out `example/integration_test/plugin_integration_test.dart` was deleted 2026-10-24). Tracked: [#23](https://github.com/kihyun1998/flutter_alone/issues/23).
