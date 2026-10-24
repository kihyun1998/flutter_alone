# lock-file-ownership

## The fact
On Linux and macOS a process records the lock file's path — and so may later unlink it — only after its own `flock(LOCK_EX|LOCK_NB)` succeeded and its PID was written. A launch that lost the race owns nothing and never deletes the file.

## Why it is cross-cutting
The same lock-file scheme is implemented twice, in C++ for Linux and in Swift for macOS, with no shared code. Linux enforces the rule with a type (`LockHandle`: path non-empty iff held); macOS keeps it by convention (`currentLockFilePath` assigned after the lock). A fix to either that is not carried to the other leaves one platform with the bug.

## Territories it holds in
- [instance-lock-linux](../territory/instance-lock-linux.md) — `AcquireLock`, `LockOpenedFile` (only success sets `handle.path`; inode check), `ReleaseLock`, `handle_check_and_run` (adopts only an acquired handle)
- [instance-lock-macos](../territory/instance-lock-macos.md) — `checkAndRun(lockFilePath:…)` (inode check; sets `currentLockFilePath` last), `dispose()`

## What a violation looks like
A duplicate that recorded the path calls `dispose`, unlinks the primary's lock file, and the next launch creates a fresh file and acquires it — two instances run (issue #1, fixed on Linux in fd10e3a; regression test `ReleasingAFailedDuplicateDoesNotDeleteOwnersLockFile`).

## Discovery history
- Issue #1 — Linux lock-file ownership bug; ADR-0001 names it as a direct consequence of the lock-file model.
- Reading 2026-10-24: the macOS code follows the same order without a type enforcing it.

## Where it will recur
If a function opens, locks, records, releases or unlinks the lock file on either Unix platform, it is subject to this.

A second rule rides on the first: because the owner unlinks on release, a lock is kept only if the locked fd is still the file at the lock path (same device and inode); otherwise the launch drops it and reopens. Linux `LockOpenedFile` → `FdIsFileAtPath`, returning `kStale` to `AcquireLock`'s bounded retry; Swift `fdIsFile(_:atPath:)` inside `checkAndRun`'s loop.

## Known holes
**None.** The unlink race (a launch that opened the file before the owner's unlink locking the deleted inode while the next launch locks a new file) was found by reading on 2026-10-24 and fixed by the inode check above; regression test `LockingAFileTheOwnerUnlinkedIsRefused` (Linux). The macOS copy has no test.
