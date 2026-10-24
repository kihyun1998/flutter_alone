# name-validation-mirror

## The fact
Every name the native side would reject must be rejected first in Dart with `ArgumentError`: the Windows mutex name (non-empty, ≤ 260, no `\` after index 7) and the Unix lock file name (non-empty, no `/`, not `.`/`..`; Dart and macOS also reject `\` and NUL).

## Why it is cross-cutting
The checks live twice — Dart (`WindowsMutexConfig.validateMutexName`, `MacOSConfig`/`LinuxConfig` constructors) and native (`IsValidMutexName`, Linux `handle_check_and_run`, macOS `handle`) — and neither calls the other. A native rejection on Windows is not reported as an error: `Acquire` returns `kInvalidName`, which `checkAndRun` turns into `false`, i.e. "another instance is running", and the consumer's `exit(0)` follows. Loosening Dart without the native, or tightening the native without Dart, reopens that.

## Territories it holds in
- [configuration](../territory/configuration.md) — `WindowsMutexConfig.validateMutexName`, `maxMutexNameLength`; `MacOSConfig`, `LinuxConfig` constructors
- [instance-lock-windows](../territory/instance-lock-windows.md) — `IsValidMutexName`, `kMaxMutexNameLength`
- [instance-lock-linux](../territory/instance-lock-linux.md) — the `lockFileName` checks in `handle_check_and_run` (no `\`/NUL check — harmless on Linux)
- [instance-lock-macos](../territory/instance-lock-macos.md) — the `lockFileName` checks in `handle(_:result:)`

## What a violation looks like
Windows: a consumer passes a name the native rejects and Dart accepts → the app exits on every launch with no dialog and no error (issue #2, fixed by commit a9308a0). Unix: the native returns `INVALID_ARGUMENT` → `AloneException` at startup.

## Discovery history
- Issue #2 — Windows invalid-mutex-name handling; fixed by moving validation into Dart (a9308a0, CHANGELOG 4.1.0).
- Both 260 constants carry a comment naming the other (`windows_config.dart`, `mutex_guard.h`).

## Where it will recur
If a function decides whether a config name is acceptable, on either side, it is subject to this: find its twin on the other side and keep the predicates equal or the Dart one stricter.
