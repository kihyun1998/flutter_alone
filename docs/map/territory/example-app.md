# example-app

## What it is
The in-repo demo app: shows the intended call pattern on all three platforms together with `window_manager` and `system_tray`, and doubles as the build target every native CI job compiles.

## Governing decisions
**None.**

## Design model
From the source:
- `main()` builds a platform config, calls `checkAndRun`, and `exit(0)` on `false` before `runApp` — the contract [dart-api](dart-api.md) assumes.
- It enables the check in debug mode, so `flutter run` exercises the native path.
- It can hide its window to the tray (`windowManager.hide`) — the scenario the Windows no-visibility-filter and the xdotool no-`--onlyvisible` rules exist for.
- `windowTitle` is `appTitle` ('Flutter Alone Example', set by `window_manager`); the Windows runner's native title is `FlutterAloneExample`. README's FAQ explains why the two differ when `window_manager` is used.
- `dispose` calls `FlutterAlone.instance.dispose()`.
- `environment.flutter` is the exact Flutter version CI, Dependabot and the session hook all use. Pub refuses `flutter pub get` here under any other Flutter (see [ci](ci.md)).
- Depends on the plugin by `path: ../`; `example/pubspec.lock` is committed. Its dependencies are updated by one grouped monthly Dependabot PR (see [ci](ci.md)).

## Code
- `example/lib/main.dart — main`, `_MyAppState`; `example/lib/const.dart — appTitle`
- `example/pubspec.yaml`, `example/pubspec.lock`
- `example/windows/runner/main.cpp`, `example/linux/runner/`, `example/macos/Runner/`

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [ci](ci.md) — all native jobs build this app first.
- [activation-windows](activation-windows.md) — its tray-hide is the reference manual test for restoring a hidden window.

## Known holes / open
- `example/pubspec.lock` records the plugin's own version, so it goes stale on every release until someone runs `flutter pub get` in `example/` (it had drifted to 4.0.3 until 2026-10-24).
