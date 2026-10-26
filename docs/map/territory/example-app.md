# example-app

## What it is
The in-repo demo app: shows the intended call pattern on all three platforms together with `window_manager` and `system_tray`, and doubles as the build target every native CI job compiles.

## Governing decisions
**None.**

## Design model
From the source:
- `main()` builds a platform config and passes it to `checkAndRunOrExit`, which calls `checkAndRun` and exits on `false` before `runApp` (code 0, or 3 in self-test mode) — the contract [dart-api](dart-api.md) assumes.
- It enables the check in debug mode, so `flutter run` exercises the native path.
- It can hide its window to the tray (`windowManager.hide`) — the scenario the Windows no-visibility-filter and the xdotool no-`--onlyvisible` rules exist for.
- `windowTitle` is `appTitle` ('Flutter Alone Example', set by `window_manager`); the Windows runner's native title is `FlutterAloneExample`. README's FAQ explains why the two differ when `window_manager` is used.
- `dispose` calls `FlutterAlone.instance.dispose()`.
- **Self-test mode**: on when `FLUTTER_ALONE_SELFTEST` names a status file, read at runtime (`SelfTest`). In this mode:
  - the dialog is off, which the invariant allows ([duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)); a modal dialog would hang a headless run where activation fails;
  - the lock identity differs from a normal run (`flutter_alone_example.selftest.lock`, Windows mutex suffix `selftest`), so a self-test never contends with a developer's run;
  - the system tray is not initialised (its icon path is relative to the working directory);
  - the app reports its outcome through the status file and exit code that the header of `tool/two_instance_test.dart` defines.
  - Without the variable: dialog on, lock file `flutter_alone_example.lock`, the mutex name without a suffix, exit 0 on a duplicate launch, tray initialised. `checkAndRunOrExit` holds the one `checkAndRun` call the three platform blocks share. The contract is owned by `tool/two_instance_test.dart` (see [ci](ci.md)).
- `environment.flutter` is the exact Flutter version CI, Dependabot and the session hook all use. Pub refuses `flutter pub get` here under any other Flutter (see [ci](ci.md)).
- Depends on the plugin by `path: ../`; `example/pubspec.lock` is committed. Its dependencies are updated by one grouped monthly Dependabot PR (see [ci](ci.md)).

## Code
- `example/lib/main.dart — main`, `checkAndRunOrExit`, `_MyAppState`; `example/lib/self_test.dart — SelfTest`; `example/lib/const.dart — appTitle`
- `example/pubspec.yaml`, `example/pubspec.lock`
- `example/windows/runner/main.cpp`, `example/linux/runner/`, `example/macos/Runner/`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [ci](ci.md) — all native jobs build this app first; the `linux` job also launches it three times in self-test mode, so a change to `SelfTest` or `checkAndRunOrExit` is a change to the test.
- [activation-windows](activation-windows.md) — its tray-hide is the reference manual test for restoring a hidden window.

## Known holes / open
- `example/pubspec.lock` records the plugin's own version, so it goes stale on every release until someone runs `flutter pub get` in `example/` (it had drifted to 4.0.3 until 2026-10-24).
