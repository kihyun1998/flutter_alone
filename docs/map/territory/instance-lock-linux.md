# instance-lock-linux

## What it is
The Linux single-instance primitive: an advisory `flock` on a lock file in the GLib temp dir, holding the owner's PID so a second launch can find it.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — lock file + `flock(LOCK_EX|LOCK_NB)`, `O_NOFOLLOW`, PID in the file, kernel release on death.

## Design model
From ADR-0001 and `lock_file.h`:
- `LockHandle` invariant: `path` is non-empty iff the lock is held; only `AcquireLock`'s success path populates it, so a duplicate can never unlink the owner's file (issue #1, commit fd10e3a).
- `LockHandle` has no destructor on purpose: the plugin adopts it with `*self->lock = std::move(lock.handle)`; adding RAII without move ops that zero `fd` would double-close.
- `AcquireLock` = `open` (`O_CREAT|O_RDWR|O_NOFOLLOW|O_CLOEXEC`) + `LockOpenedFile`, retried up to `kMaxStaleRetries` (8) while the result is `kStale`. Outcomes reaching the plugin: `kAcquired` (PID written, `fdatasync`), `kHeldByOther` (holder PID read from the file, or -1), `kIoError` (open/write failed, or the file kept being replaced → `IO_ERROR` to Dart).
- After `flock` succeeds, `FdIsFileAtPath` compares the fd's and the path's device/inode; a mismatch means the owner unlinked the file in between, so the lock is dropped (`kStale`).
- Path is `g_get_tmp_dir()` + `/` + `lockFileName` (`get_lock_file_path`) — honours `$TMPDIR`, so two launches with different `TMPDIR` do not contend.
- `ReleaseLock` order: `LOCK_UN`, `close`, `unlink`.

## Code
- `linux/lock_file.h — LockHandle`, `LockOutcome`, `LockResult`
- `linux/lock_file.cc — AcquireLock`, `LockOpenedFile`, `FdIsFileAtPath`, `kMaxStaleRetries`, `ReleaseLock`, `ReadPidFromFd`, `WritePidToFd`
- `linux/flutter_alone_plugin.cc — get_lock_file_path`, `handle_check_and_run`, `release_lock`, `flutter_alone_plugin_dispose`
- Tests: `linux/test/lock_file_test.cc`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [lock-file-ownership](../invariant/lock-file-ownership.md)
- [name-validation-mirror](../invariant/name-validation-mirror.md)
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)
- [lock-not-inherited](../invariant/lock-not-inherited.md)

## Blast radius
- [instance-lock-macos](instance-lock-macos.md) — the same flock scheme is reimplemented in Swift; a fix here is owed there (see the invariant).
- [activation-linux](activation-linux.md) — activation trusts the PID this file holds.
- [ci](ci.md) — `linux/test/CMakeLists.txt` builds `lock_file.cc` alone; it must stay free of Flutter/GTK.

## Known holes / open
- `TMPDIR` differences between sessions/users split the lock (cross-user detection depends on a shared temp dir).
