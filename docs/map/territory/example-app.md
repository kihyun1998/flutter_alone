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
- Depends on the plugin by `path: ../`; `example/pubspec.lock` is committed.

## Code
- `example/lib/main.dart — main`, `_MyAppState`; `example/lib/const.dart — appTitle`
- `example/pubspec.yaml`, `example/pubspec.lock`
- `example/windows/runner/main.cpp`, `example/linux/runner/`, `example/macos/Runner/`
- `example/integration_test/plugin_integration_test.dart` (commented out)

## Reference behaviour
**None.**

## Cross-cutting invariants
**None.**

## Blast radius
- [ci](ci.md) — all native jobs build this app first.
- [activation-windows](activation-windows.md) — its tray-hide is the reference manual test for restoring a hidden window.

## Known holes / open
- `example/pubspec.lock` is stale against the pinned Flutter SDK: `flutter pub get` rewrites it (e.g. `characters` 1.4.0→1.4.1, the plugin's own version 4.0.3→4.1.0), so every fresh checkout that runs pub get leaves it modified.
- Dependency updates for `system_tray`, `window_manager`, `mockito` are not watched — Tracked: [#21](https://github.com/kihyun1998/flutter_alone/issues/21).
