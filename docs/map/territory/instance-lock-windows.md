# instance-lock-windows

## What it is
The Windows single-instance primitive: a named kernel mutex, created with a DACL that lets other users detect it, released by the kernel when the owner dies.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — named mutex, `Global\`/`Local\` prefix, SDDL DACL, kernel release on exit.

## Design model
From ADR-0001 and the source:
- `MutexGuard` is move-only RAII; a held guard releases and closes on destruction (`mutex_guard.h`).
- `Acquire` returns `kAcquired` only when this call created the mutex. `ERROR_ALREADY_EXISTS` with a handle, or `ERROR_ACCESS_DENIED` with none (the restrictive DACL denies a second user full access), both mean **held by another** (`MutexGuard::Acquire`).
- DACL `D:(A;;0x00100000;;;WD)(A;;0x001F0001;;;CO)`: Everyone gets `SYNCHRONIZE` only, creator/owner full access — enough for `OpenMutexW(SYNCHRONIZE)` from any user, not enough to squat (CHANGELOG 4.0.0, "prevent mutex squatting").
- The plugin checks `MutexGuard::Exists` first and only then `Acquire` (`FlutterAlonePlugin::CheckRunningInstance`, `HandleMethodCall`). The two calls are not atomic, so `HandleMethodCall` maps every `Acquire` outcome: `kAcquired` → `true`; `kAlreadyExists` (lost the race) → `HandleDuplicate` and `false`; `kInvalidName` → error `INVALID_ARGUMENT`; `kError` → error `MUTEX_ERROR`.
- `IsValidMutexName`: non-empty, ≤ `kMaxMutexNameLength` (260, an app policy, not a kernel limit), no `\` from index 7 on.

## Code
- `windows/mutex_guard.h — kMaxMutexNameLength`, `MutexAcquireOutcome`, `MutexGuard`
- `windows/mutex_guard.cpp — IsValidMutexName`, `MutexGuard::Acquire`, `::Release`, `::Exists`, `kMutexSecurityDescriptor`
- `windows/flutter_alone_plugin.cpp — CheckRunningInstance`, `CheckAndCreateMutex`, `HandleDuplicate`, `CleanupResources`, `HandleMethodCall`
- Tests: `windows/test/mutex_guard_test.cpp`

## Reference behaviour
- Win32 API docs (Microsoft Learn, summarized — binding): `CreateMutexW`, `OpenMutexW`, `ERROR_ALREADY_EXISTS`, SDDL. The `ERROR_ACCESS_DENIED`-means-exists reading rests on this summarized source and needs confirming against real cross-user runs.

## Cross-cutting invariants
- [name-validation-mirror](../invariant/name-validation-mirror.md)
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)
- [lock-not-inherited](../invariant/lock-not-inherited.md)

## Blast radius
- [activation-windows](activation-windows.md) — activation runs only on the "exists" branch; changing when `Exists` reports true changes when a window is brought forward.
- [already-running-dialog](already-running-dialog.md) — the dialog is the fallback on the same branch.
- [configuration](configuration.md) — the name format and the 260 limit are shared with Dart validation.
- [ci](ci.md) — `windows/test/CMakeLists.txt` compiles `mutex_guard.cpp` standalone; a new dependency of it must be added there.

## Known holes / open
- A failed `ConvertStringSecurityDescriptorToSecurityDescriptorW` silently falls back to default security, losing cross-user detection.
