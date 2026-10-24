# lock-file-ownership

## The fact
On Linux and macOS a process records the lock file's path — and so may later unlink it — only after its own `flock(LOCK_EX|LOCK_NB)` succeeded and its PID was written. A launch that lost the race owns nothing and never deletes the file.

## Why it is cross-cutting
The same lock-file scheme is implemented twice, in C++ for Linux and in Swift for macOS, with no shared code. Linux enforces the rule with a type (`LockHandle`: path non-empty iff held); macOS keeps it by convention (`currentLockFilePath` assigned after the lock). A fix to either that is not carried to the other leaves one platform with the bug.

## Territories it holds in
- [instance-lock-linux](../territory/instance-lock-linux.md) — `AcquireLock` (only success sets `handle.path`), `ReleaseLock`, `handle_check_and_run` (adopts only an acquired handle)
- [instance-lock-macos](../territory/instance-lock-macos.md) — `checkAndRun(lockFilePath:…)` (sets `currentLockFilePath` last), `dispose()`

## What a violation looks like
A duplicate that recorded the path calls `dispose`, unlinks the primary's lock file, and the next launch creates a fresh file and acquires it — two instances run (issue #1, fixed on Linux in fd10e3a; regression test `ReleasingAFailedDuplicateDoesNotDeleteOwnersLockFile`).

## Discovery history
- Issue #1 — Linux lock-file ownership bug; ADR-0001 names it as a direct consequence of the lock-file model.
- Reading 2026-10-24: the macOS code follows the same order without a type enforcing it.

## Where it will recur
If a function opens, locks, records, releases or unlinks the lock file on either Unix platform, it is subject to this.

## Known holes
- **Unlink race on release.** Both release in the order unlock → close → unlink (`ReleaseLock`; Swift `dispose`). A launch B that opened the old file before the unlink can take the lock on the now-unlinked inode, and a later launch C creates a new file and takes that lock too — two instances. Not known before this reading (maintainer, 2026-10-24); open.
