# duplicate-launch-is-never-silent

## The fact
When `checkAndRun` returns `false` because another instance holds the lock, the duplicate either brings that instance forward or shows the already-running dialog (unless `showMessageBox` is false). It never just exits.

## Why it is cross-cutting
Each native handler decides its own branches — Windows `HandleMethodCall`, Linux `handle_check_and_run`, macOS `checkAndRun(lockFilePath:…)` — and they share no code. The rule was made explicit when macOS was brought to "parity with Win/Linux" (commit 363cf8b, #3; comment in the Swift contention branch). Changing a branch on one platform without the others makes the same misconfiguration silent on one OS only.

## Territories it holds in
- [instance-lock-windows](../territory/instance-lock-windows.md) — the `canRun == false` branch of `HandleMethodCall`
- [instance-lock-linux](../territory/instance-lock-linux.md) — the `kHeldByOther` branch of `handle_check_and_run`
- [instance-lock-macos](../territory/instance-lock-macos.md) — the `EWOULDBLOCK`/`EAGAIN` branch
- [activation-windows](../territory/activation-windows.md), [activation-linux](../territory/activation-linux.md), [activation-macos](../territory/activation-macos.md) — "activated" is what suppresses the dialog
- [already-running-dialog](../territory/already-running-dialog.md) — the fallback each branch calls

## What a violation looks like
The user double-clicks the app and nothing happens. Known paths where it happens today:
- Windows: `Exists` false, then `Acquire` returns `kAlreadyExists` (race), `kInvalidName` or `kError` → `false` with no dialog.
- macOS: lock-file `open` failure, PID write failure or a non-contention `flock` errno → `false` with no dialog.
- Linux reports I/O failure as `IO_ERROR` (an `AloneException`), which is loud but not the dialog.

## Discovery history
- #3 — macOS did not honour the message config; fixed in 363cf8b (CHANGELOG 4.1.0).
- #2 — Windows invalid name exited silently; fixed in Dart (a9308a0).
- Reading 2026-10-24: the remaining silent paths above.

## Where it will recur
If a native code path returns `false` from `checkAndRun`, it is subject to this: it must have activated, shown the dialog, or be the `showMessageBox == false` case.
