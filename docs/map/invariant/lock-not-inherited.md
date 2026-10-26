# lock-not-inherited

## The fact
The lock a running instance holds is never inherited by a process it starts. On Linux and macOS the lock file is opened with `O_CLOEXEC`, so an exec'd child does not share the open file description the `flock` belongs to. On Windows the mutex is created with `SECURITY_ATTRIBUTES.bInheritHandle = FALSE`. When the running instance dies, the lock goes with it, even while a child it started is still running.

## Why it is cross-cutting
The three lock implementations share no code: Linux `AcquireLock` (C++), macOS `checkAndRun(lockFilePath:…)` (Swift), Windows `MutexGuard::Acquire`. Each one sets its own flag at its own creation call, and nothing checks one against the others. The rule is what keeps [ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md)'s "released by the kernel on process death ⇒ no stale lock" true. Without it, the kernel only releases the lock once every process sharing it is gone.

## Territories it holds in
- [instance-lock-linux](../territory/instance-lock-linux.md) — `AcquireLock`'s `open` flags. `LockOpenedFile` takes an fd its caller opened, so the flag belongs at the `open`.
- [instance-lock-macos](../territory/instance-lock-macos.md) — the `open` in `checkAndRun(lockFilePath:showMessageBox:title:message:)`
- [instance-lock-windows](../territory/instance-lock-windows.md) — `MutexGuard::Acquire`'s `SECURITY_ATTRIBUTES`

## What a violation looks like
The app starts a long-running helper. On Linux, Dart's `Process.start` in its default attached modes fork+execs without closing inherited descriptors (Dart SDK `runtime/bin/process_linux.cc`, `ExecProcess`). Then the app crashes or is killed. The helper still holds the lock, so every new launch is refused as a duplicate launch: the lock file names a dead PID, activation fails, and the already-running dialog shows. This lasts until the helper exits.

On macOS, Dart spawns every mode with `POSIX_SPAWN_CLOEXEC_DEFAULT`, so children started from Dart never inherited the lock. Children created any other way could.

## Discovery history
- #33 — found by the completeness read on #27. Reproduced 2026-10-26 on WSL2 (kernel 6.18) against the unmodified Linux seam: holder killed, child alive → `kHeldByOther` with the dead holder's PID; with `O_CLOEXEC` → `kAcquired`.
- Regression test `ChildOfAKilledOwnerDoesNotKeepTheLock` (Linux). The owner reports its helper only after the helper's exec, which it detects as EOF on a close-on-exec pipe. Before that, a forked helper still shares every descriptor, and reporting earlier made the test fail even with the fix. Removing `O_CLOEXEC` turns the test red 50 of 50 runs; with it, the suite passed 50 of 50.
- Windows already created the mutex non-inheritable before #33.

## Where it will recur
If a function creates or duplicates the lock's handle or descriptor on any platform (`open`, `dup`, `fcntl(F_DUPFD)`, `CreateMutexW`, `DuplicateHandle`), it is subject to this. The macOS copy has no test; it is held by this note and the CI build only.
