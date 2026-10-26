# instance-lock-windows

## What it is
The Windows single-instance primitive: a named kernel mutex, created with a DACL that lets other users detect it, released by the kernel when the owner dies.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — named mutex, `Global\`/`Local\` prefix, SDDL DACL, kernel release on exit.

## Design model
From ADR-0001 and the source:
- `MutexGuard` is move-only RAII; a held guard releases and closes on destruction (`mutex_guard.h`).
- `Acquire` returns `kAcquired` when this call created the mutex, **or** took over an existing one that has no live owner. On `ERROR_ALREADY_EXISTS` (a handle came back) or `ERROR_ACCESS_DENIED` (the restrictive DACL denies a second user full access, so it reopens with `SYNCHRONIZE`), it waits on the existing mutex with a zero timeout (`MutexGuard::TakeOver`). `WAIT_ABANDONED` (the owner died) or `WAIT_OBJECT_0` (no owner) transfers ownership to this guard. `WAIT_TIMEOUT` means a live owner, so `kAlreadyExists`. The kernel grants ownership to one waiter only, so two launches racing for a dead owner's mutex cannot both win.
- Mutexes are recursive for their owning thread, so a second guard on the same thread would "take over" its own live mutex. `Acquire` therefore refuses, before any wait, a name another guard in this process holds: `HeldNames()`, a process-wide set under a lock, filled by `Adopt` and emptied by `Release`. This keeps the same-process contract (`SecondAcquireOfHeldNameReportsAlreadyExists`) equal to Linux's (maintainer's call on #38, 2026-10-26, made knowing the recursion).
- The takeover is safe only because ownership belongs to the thread, and the plugin acquires on the platform main thread, which lives as long as the process. Traced in source on 2026-10-26 (engine source read from `master`, not from the pinned 3.41.9 tag):
  - the runner's `wWinMain` builds the `FlutterWindow` on the main thread and runs the message loop until exit;
  - `OnCreate` constructs `FlutterViewController`, and its `CreateViewController` calls `engine()->Run()` (engine `shell/platform/windows/flutter_windows.cc`), which is `FlutterEngineRun`;
  - `embedder.h` says `platform_message_callback` "will be invoked on the thread on which the `FlutterEngineRun` call is made";
  - the plugin's `SetMethodCallHandler` uses no Task Queue.
- `ReleaseMutex` works through a handle opened with `SYNCHRONIZE` only, so `Release` and `dispose` after a takeover of another user's mutex free it normally. Measured 2026-10-26: after the release, another process acquired the mutex; before it, it could not.
- A failed takeover wait (`WAIT_FAILED`) is `kError`, not `kAlreadyExists`, so it surfaces as `MUTEX_ERROR` rather than as a false "already running".
- DACL `D:(A;;0x00100000;;;WD)(A;;0x001F0001;;;CO)`: Everyone gets `SYNCHRONIZE` only, creator/owner full access — enough for `OpenMutexW(SYNCHRONIZE)` from any user, not enough to squat (CHANGELOG 4.0.0, "prevent mutex squatting").
- `HandleMethodCall` decides on `Acquire` alone: `kAcquired` → `true`; `kAlreadyExists` → `HandleDuplicate(CheckRunningInstance(…))` and `false`; `kInvalidName` → error `INVALID_ARGUMENT`; `kError` → error `MUTEX_ERROR`. `CheckRunningInstance` only looks up the running instance's window. `MutexGuard::Exists` never waits: a wait there would take ownership of an abandoned mutex as a side effect, and a process with only `SYNCHRONIZE` could not give it back (#38).
- `IsValidMutexName`: non-empty, ≤ `kMaxMutexNameLength` (260, an app policy, not a kernel limit), no `\` from index 7 on.

## Code
- `windows/mutex_guard.h — kMaxMutexNameLength`, `MutexAcquireOutcome`, `MutexGuard`
- `windows/mutex_guard.cpp — IsValidMutexName`, `MutexGuard::Acquire`, `::TakeOver`, `::Adopt`, `::Release`, `::Exists`, `HeldNames`, `HeldNamesLock`, `kMutexSecurityDescriptor`
- `windows/flutter_alone_plugin.cpp — CheckRunningInstance`, `CheckAndCreateMutex`, `HandleDuplicate`, `CleanupResources`, `HandleMethodCall`
- Tests: `windows/test/mutex_guard_test.cpp`

## Reference behaviour
- Win32 API docs (Microsoft Learn, summarized — binding): `CreateMutexW`, `OpenMutexW`, `ERROR_ALREADY_EXISTS`, SDDL. The `ERROR_ACCESS_DENIED`-means-exists reading rests on this summarized source and needs confirming against real cross-user runs.

## Cross-cutting invariants
- [name-validation-mirror](../invariant/name-validation-mirror.md)
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)
- [lock-not-inherited](../invariant/lock-not-inherited.md)

## Blast radius
- [activation-windows](activation-windows.md) — activation runs only when `Acquire` reports `kAlreadyExists`; changing when `Acquire` takes a mutex over changes when a window is brought forward instead.
- [already-running-dialog](already-running-dialog.md) — the dialog is the fallback on the same branch.
- [configuration](configuration.md) — the name format and the 260 limit are shared with Dart validation.
- [ci](ci.md) — `windows/test/CMakeLists.txt` compiles `mutex_guard.cpp` standalone; a new dependency of it must be added there.

## Known holes / open
- The `ERROR_ACCESS_DENIED` takeover path (an owner of another user or session) is tested by no test; it needs a second account. Its same-user twin, `ERROR_ALREADY_EXISTS`, is covered by `AbandonedMutexKeptOpenByAnotherHandleIsTakenOver` and `UnownedMutexIsTakenOver`.
- After `ERROR_ACCESS_DENIED`, a failed `OpenMutexW(SYNCHRONIZE)` (the mutex vanished in between) is reported as `kAlreadyExists` though nothing runs.
- A failed `ConvertStringSecurityDescriptorToSecurityDescriptorW` silently falls back to default security, losing cross-user detection.
