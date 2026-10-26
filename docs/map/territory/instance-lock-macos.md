# instance-lock-macos

## What it is
The macOS single-instance primitive: the same `flock`-on-a-lock-file scheme as Linux, written in Swift inside the plugin class, in `FileManager.default.temporaryDirectory`.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — lock file + advisory `flock`, PID in the file.

## Design model
From the source:
- `checkAndRun(lockFilePath:…)`: `open(O_CREAT|O_RDWR|O_NOFOLLOW|O_CLOEXEC, 0644)`, `flock(LOCK_EX|LOCK_NB)`; on `EWOULDBLOCK`/`EAGAIN` read the PID by path and try activation; after a successful lock `fdIsFile(_:atPath:)` checks the fd is still the file at the path and reopens if not (up to `maxStaleRetries`, 8); then write the PID and keep the fd open.
- `currentLockFilePath` is set only after the lock and the PID write succeed, so `dispose` unlinks only a file this process owns — the Swift copy of Linux's `LockHandle` rule, without a type enforcing it.
- Every I/O failure — open, non-contention `flock` error, PID write, a file that kept being replaced — returns `FlutterError("IO_ERROR")` through `ioError(_:)`, matching Linux; `handle(_:result:)` passes either the `Bool` or the error to `result`.
- The temp dir is per user on macOS (`/var/folders/.../T/`, or the app container when sandboxed), so the lock is per user — accepted in [ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) because a shared path would break sandboxed apps (maintainer, 2026-10-24).

## Code
- `macos/Classes/FlutterAlonePlugin.swift — handle(_:result:)`, `checkAndRun(lockFilePath:showMessageBox:title:message:)`, `fdIsFile(_:atPath:)`, `ioError(_:)`, `writePid(to:pid:)`, `readPid(from:)`, `dispose()`, `removeLockFile(path:)`
- Tests: `example/macos/RunnerTests/RunnerTests.swift` (argument handling only; no lock test)

## Reference behaviour
**None.**

## Cross-cutting invariants
- [lock-file-ownership](../invariant/lock-file-ownership.md)
- [name-validation-mirror](../invariant/name-validation-mirror.md)
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)
- [lock-not-inherited](../invariant/lock-not-inherited.md)

## Blast radius
- [instance-lock-linux](instance-lock-linux.md) — same scheme, separate code; fixes travel both ways.
- [activation-macos](activation-macos.md) — consumes the PID read here.
- [already-running-dialog](already-running-dialog.md) — shown from this function when activation fails.

## Known holes / open
- No unit test covers the lock itself on macOS (Linux has `lock_file_test.cc`).
