# configuration

## What it is
The typed configuration a consumer builds and its serialization to the method-channel map: `FlutterAloneConfig.forWindows/forMacOS/forLinux`, the per-platform sections (`WindowsMutexConfig`, `MacOSConfig`, `LinuxConfig`), the shared sections (`DuplicateCheckConfig`, `WindowConfig`, `MessageConfig`), and up-front validation of names so a bad one fails in Dart instead of natively.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — the config is "necessarily platform-shaped": `mutexName` (Windows) and `lockFileName` (Unix) are different concepts.

## Design model
From the source:
- A config can only be built through a platform factory; the private constructor keeps the platform section paired with the platform (`config.dart — FlutterAloneConfig._`).
- `toMap()` delegates to `toMapFor(AlonePlatform)` with the runtime OS; `toMapFor` throws `StateError` when the config lacks that platform's section, and lets every branch be unit-tested on any OS (commit d6a579f, #4).
- The map is assembled in a fixed order: duplicate-check, platform section, window, message. Every value must be non-null (`AloneConfig.toMap` doc).
- Windows names always carry a single `Global\` prefix: `DefaultWindowsMutexConfig` builds `Global\<packageId>_<appName>[_<suffix>]`; `CustomWindowsMutexConfig` adds the prefix if missing. Both pass `WindowsMutexConfig.validateMutexName`. There is no way to request a `Local\` mutex from Dart, though the native validator accepts one.
- `MacOSConfig` / `LinuxConfig` validate `lockFileName` in their constructors (non-empty, no `/`, `\`, NUL, `.` or `..`); default `.lockfile` — a name every app that keeps the default shares.
- Input bound: names are bounded only for Windows (260 chars); a lock file name has no length check in Dart (the OS rejects > NAME_MAX at `open`).

## Code
- `lib/src/models/config.dart — AlonePlatform`, `AloneConfig`, `DuplicateCheckConfig`, `WindowConfig`, `FlutterAloneConfig.forWindows/forMacOS/forLinux`, `.toMap`, `.toMapFor`
- `lib/src/models/windows_config.dart — WindowsMutexConfig.validateMutexName`, `DefaultWindowsMutexConfig.getMutexName`, `CustomWindowsMutexConfig.getMutexName`
- `lib/src/models/macos_config.dart — MacOSConfig`
- `lib/src/models/linux_config.dart — LinuxConfig`
- `lib/src/models/message_config.dart` — see [already-running-dialog](already-running-dialog.md)
- Tests: `test/config_test.dart`, `test/flutter_alone_config_test.dart`, `test/windows_mutex_config_test.dart`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [method-channel-contract](../invariant/method-channel-contract.md)
- [name-validation-mirror](../invariant/name-validation-mirror.md)

## Blast radius
- [instance-lock-windows](instance-lock-windows.md) — the mutex name built here is used verbatim as the kernel object name; a different prefix or format is a different lock, so two versions of an app stop seeing each other.
- [instance-lock-linux](instance-lock-linux.md), [instance-lock-macos](instance-lock-macos.md) — `lockFileName` is joined to the temp dir unchanged; changing the default or the format changes which file two launches contend on.
- [activation-windows](activation-windows.md) — `WindowConfig.windowTitle` is only read on Windows, for the title fallback.
- [already-running-dialog](already-running-dialog.md) — `MessageConfig` is serialized into this map.
- [shipping](shipping.md) — every public config class is published API.

## Known holes / open
- `windowTitle` is serialized on every platform but only Windows reads it; nothing tells a macOS/Linux consumer it is ignored.
- No Dart length bound on `lockFileName`.
