# instance-lock-macos

## What it is
The macOS single-instance primitive: the same `flock`-on-a-lock-file scheme as Linux, written in Swift inside the plugin class, in `FileManager.default.temporaryDirectory`.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — lock file + advisory `flock`, PID in the file.

## Design model
From the source:
- `checkAndRun(lockFilePath:…)`: `open(O_CREAT|O_RDWR|O_NOFOLLOW, 0644)`, `flock(LOCK_EX|LOCK_NB)`; on `EWOULDBLOCK`/`EAGAIN` read the PID by path and try activation; on success write the PID and keep the fd open.
- `currentLockFilePath` is set only after the lock and the PID write succeed, so `dispose` unlinks only a file this process owns — the Swift copy of Linux's `LockHandle` rule, without a type enforcing it.
- Every failure — open, non-contention `flock` error, PID write — returns `false` (logged with `NSLog`), unlike Linux, which reports `kIoError` as an error.
- The temp dir is per user on macOS (`/var/folders/.../T/`), so the lock is per user.

## Code
- `macos/Classes/FlutterAlonePlugin.swift — handle(_:result:)`, `checkAndRun(lockFilePath:showMessageBox:title:message:)`, `writePid(to:pid:)`, `readPid(from:)`, `dispose()`, `removeLockFile(path:)`
- Tests: `example/macos/RunnerTests/RunnerTests.swift` (argument handling only; no lock test)

## Reference behaviour
**None.**

## Cross-cutting invariants
- [lock-file-ownership](../invariant/lock-file-ownership.md)
- [name-validation-mirror](../invariant/name-validation-mirror.md)
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)

## Blast radius
- [instance-lock-linux](instance-lock-linux.md) — same scheme, separate code; fixes travel both ways.
- [activation-macos](activation-macos.md) — consumes the PID read here.
- [already-running-dialog](already-running-dialog.md) — shown from this function when activation fails.

## Known holes / open
- No unit test covers the lock itself on macOS (Linux has `lock_file_test.cc`).
- Because the temp dir is per user, ADR-0001's "cross-user awareness" does not hold on macOS; whether that is intended is not recorded.
- I/O failures return `false` silently — the app exits with no dialog and no error.
