# 0001 — Per-platform single-instance enforcement strategy

- Status: Accepted (documents an already-shipped decision, as of v4.0.4)
- Date: 2026-07-01

## Context

`flutter_alone` guarantees that only one instance of a desktop application runs at
a time, across Windows, macOS, and Linux. There is no single cross-platform
primitive that provides "single instance" semantics with the properties we need:

- **Atomic acquire-or-fail** — the second launcher must reliably lose the race.
- **Automatic release on process death** — a crashed instance must not permanently
  lock out future launches (no stale lock).
- **Cross-user / cross-session awareness** — detect an instance owned by another OS
  account where the product requires it.
- **Ability to locate and re-activate the existing instance's window**, not merely
  refuse to start.

Each OS exposes a different idiomatic mechanism that satisfies the first two
properties, and a different mechanism for locating the running instance's window.
Forcing a single shared abstraction would mean emulating one OS's model on top of
another and losing the kernel-provided guarantees.

## Decision

Use a **different native mechanism per platform**, unified only at the Dart API
surface (`FlutterAloneConfig.forWindows/forMacOS/forLinux` → `checkAndRun`).

### Windows — named mutex
- Create a named mutex via `CreateMutexW` with a `Global\` (cross-session) or
  `Local\` (per-session) prefix. `ERROR_ALREADY_EXISTS` ⇒ another instance owns it.
- A SDDL security descriptor grants `SYNCHRONIZE` to Everyone and full access to the
  creator/owner, so a mutex created by one user is detectable by another.
- Kernel releases the mutex when the owning process exits ⇒ no stale lock.
- To re-activate the existing window: enumerate processes (Toolhelp snapshot) for the
  same executable path, then `EnumWindows` matching window title **and** owning-process
  path (so a portable build and an installed build with the same title are not confused).

### macOS & Linux — lock file + advisory `flock`
- `open(O_CREAT | O_RDWR | O_NOFOLLOW)` a lock file in the system temp dir, then
  `flock(LOCK_EX | LOCK_NB)`. Failure ⇒ another instance holds it.
- The advisory lock is bound to the open file description and released by the kernel
  on process death ⇒ no stale lock. The holder writes its PID into the file so a
  second launcher can identify and activate the existing instance.
- **macOS**: locate via `NSRunningApplication(processIdentifier:)`, verify bundle IDs
  match, then unhide / `NSWorkspace.open` to restore.
- **Linux**: verify identity via `/proc/<pid>/exe`, then activate through X11
  (`_NET_ACTIVE_WINDOW` using `_NET_CLIENT_LIST` + `_NET_WM_PID`) or, on Wayland,
  best-effort `xdotool` via `posix_spawn`.

## Consequences

**Positive**
- Each platform uses its kernel-backed primitive, so acquire/release and
  crash-safety are provided by the OS rather than emulated.
- The Dart layer stays thin; platform specifics live entirely in native code.

**Negative / trade-offs**
- Three independent implementations to maintain and keep behaviorally consistent.
  Divergence is a real risk — e.g. localized message strings are currently duplicated
  in Windows and Linux native code, and macOS does not yet honor the message config
  at all (tracked in the issue tracker).
- The lock-file approach requires careful ownership handling: the lock is on the fd,
  but the lock *file* is a separate resource that must only be unlinked by the true
  owner (see the Linux lock-file ownership bug, issue #1).
- `lockFileName` (Unix) vs `mutexName` (Windows) are different configuration concepts,
  so the config API is necessarily platform-shaped rather than uniform.

## Related
- Issue #1 — Linux lock-file ownership bug (a direct consequence of the lock-file model).
- Issue #2 — Windows invalid-mutex-name handling.
- Issue #3 — macOS message-config parity.
