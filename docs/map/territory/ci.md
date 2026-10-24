# ci

## What it is
What guards a change before it merges: the GitHub Actions workflow (Dart format/analyze/test, native builds of the example and native unit tests on each OS), the standalone native test harnesses it drives, and Dependabot for dependency releases.

## Governing decisions
**None.**

## Design model
From `.github/workflows/ci.yml`:
- Runs on push to `main` and on every pull request; Flutter pinned by `FLUTTER_VERSION` (also read by `.claude/hooks/session-start.sh`).
- Jobs: `dart` (format with `--set-exit-if-changed`, `flutter analyze`, `flutter test`); `linux` (build example, then `linux/test` gtest); `windows` (build example, then `windows/test` gtest under MSVC); `macos` (build example, then XCTest `RunnerTests`).
- The native harnesses compile the pure seams alone — `lock_file.cc`, `mutex_guard.cpp`, `message_utils.cpp`, `process_utils.cpp` — with GoogleTest v1.15.2 fetched at configure time; the seams must stay free of Flutter/GTK headers to remain testable (commits 60fa1cb, fd10e3a).
- The plugin's activation and dialog code is compiled by the example builds but executed by no test.
- `.github/dependabot.yml`: root pub weekly with `increase-if-necessary`, one PR per dependency — each a floor decision for consumers, since the root commits no lockfile; `/example` pub and GitHub Actions monthly, each grouped into one PR; all labelled `needs-triage` ([#21](https://github.com/kihyun1998/flutter_alone/issues/21)). The Flutter pin `FLUTTER_VERSION` is a workflow env value, which the actions ecosystem does not update.

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
**None.**

## Blast radius
- [instance-lock-linux](instance-lock-linux.md), [instance-lock-windows](instance-lock-windows.md) — their seams are what the native jobs test; a new dependency in a seam must be added to the harness.
- [example-app](example-app.md) — every native job starts by building the example; an example break turns all three red.
- [shipping](shipping.md) — dependency updates (Dependabot) change what consumers resolve.

## Known holes / open
- Whether Dependabot's first run succeeds is visible only in the repository's Dependabot status, not in CI.
- No test runs two real instances against each other on any platform (the commented-out `example/integration_test/plugin_integration_test.dart` was deleted 2026-10-24). Tracked: [#23](https://github.com/kihyun1998/flutter_alone/issues/23).
