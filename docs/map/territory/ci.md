# ci

## What it is
What guards a change before it merges: the GitHub Actions workflow (Dart format/analyze/test, native builds of the example and native unit tests on each OS), the standalone native test harnesses it drives, and Dependabot for dependency releases.

## Governing decisions
**None.**

## Design model
From `.github/workflows/ci.yml`:
- Runs on push to `main` and on every pull request. Every job installs Flutter from `flutter-version-file: example/pubspec.yaml`, which is `environment.flutter` and must be an exact version. `.claude/hooks/session-start.sh` reads the same line. This is the single Flutter pin (see Cross-cutting invariants).
- Jobs: `dart` (format with `--set-exit-if-changed`, `flutter analyze`, `flutter test`); `linux` (build example, then `linux/test` gtest, then the two-instance test under `xvfb-run` — last, so its failure cannot skip the gtest); `windows` (build example, then `windows/test` gtest under MSVC, then the two-instance test against the Debug `.exe` — last, as on Linux); `macos` (build example, then XCTest `RunnerTests`).
- The native harnesses compile the pure seams alone — `lock_file.cc`, `mutex_guard.cpp`, `message_utils.cpp`, `process_utils.cpp` — with GoogleTest v1.15.2 fetched at configure time; the seams must stay free of Flutter/GTK headers to remain testable (commits 60fa1cb, fd10e3a).
- The plugin's activation and dialog code is compiled by the example builds and asserted by no test. On Linux and Windows the two-instance test executes the activation attempt and the dialog call, with `showMessageBox: false`, but checks neither.
- The two-instance test (`tool/two_instance_test.dart`) launches the built example in self-test mode (see [example-app](example-app.md)) and checks four steps, using the status and exit-code contract in the file's header. The first launch acquires. A duplicate launch is refused while the first still runs, and the first is still alive `settleTime` (3 s) later. The first is force-killed. A new launch acquires. It drives the native duplicate branch with `showMessageBox: false`, so the dialog is never shown. The check is only that the branch returns `false`.
- It runs as `dart tool/...`, not `dart run`, because it imports only `dart:` libraries and the `linux` job runs `pub get` only in `example/` (through `flutter build`), never at the root. `dart <file>` with a root `pubspec.yaml` and no `.dart_tool/` runs without resolving packages (probe, 2026-10-26). It is excluded from the package by `.pubignore`.
- The harness covers what the seam tests cannot: two Linux mutations of the plugin's `handle_check_and_run` each left `linux/test` at 5/5 passed and were caught only by the harness. With the duplicate branch returning `true`, step 2 failed. With an existing lock file treated as held instead of asking `flock`, step 4 failed (CI runs 40257849957 and 40258244388 on #32, 2026-10-26). On Windows, the duplicate branch of `HandleMethodCall` returning `true` left `windows/test` at 12/12 passed, and the harness failed step 2 (CI run 40271345326 on #36).
- The settle check exists because a running instance can die *after* the duplicate exits: a duplicate posting `WM_CLOSE` to the found window passed the instant check and was caught only after the settle (redden pass on #27, 2026-10-26, Windows local).
- `.github/dependabot.yml`: root pub weekly with `increase-if-necessary`, one PR per dependency (`plugin_platform_interface`, `flutter_lints`) — each a floor decision for consumers, since the root commits no lockfile; `/example` pub and GitHub Actions monthly, each grouped into one PR; all labelled `needs-triage` ([#21](https://github.com/kihyun1998/flutter_alone/issues/21)). Dependabot does not bump the Flutter pin; it is raised by hand.

## Code
- `.github/workflows/ci.yml`
- `.github/dependabot.yml`
- `linux/test/CMakeLists.txt`, `linux/test/lock_file_test.cc`
- `windows/test/CMakeLists.txt`, `windows/test/*.cpp`
- `example/macos/RunnerTests/RunnerTests.swift`
- `test/*.dart`
- `tool/two_instance_test.dart`

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
- Two real instances are run against each other in the `linux` and `windows` jobs only. macOS ([#29](https://github.com/kihyun1998/flutter_alone/issues/29)) is not wired yet, and the native seams contend only within one process ([#30](https://github.com/kihyun1998/flutter_alone/issues/30)). Parent: [#23](https://github.com/kihyun1998/flutter_alone/issues/23).
