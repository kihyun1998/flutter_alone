# activation-macos

## What it is
On macOS, when the lock is held: confirm the PID belongs to an app with our bundle identifier and bring it forward — unhide, then reopen through `NSWorkspace` so Dock-minimized windows come back.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — `NSRunningApplication(processIdentifier:)`, bundle-ID match, unhide / `NSWorkspace.open`.

## Design model
From the source and CHANGELOG 4.0.4:
- `activateExistingInstance(pid:)` requires a live PID (`isRunning`, `EPERM` counts), an `NSRunningApplication`, and both bundle IDs present and equal; otherwise it returns `false` and the caller shows the dialog.
- `unhide()` first (Cmd+H), then `NSWorkspace.shared.open(bundleURL)`, which sends `applicationShouldHandleReopen` to the running app and restores Dock-minimized windows; `activate(options:)` only when there is no bundle URL (4.0.4).
- It never touches `NSApplication.shared.windows`: from the duplicate's process those are the duplicate's own windows (4.0.4).
- `true` means "activation attempted", not "succeeded".

## Code
- `macos/Classes/FlutterAlonePlugin.swift — activateExistingInstance(pid:)`, `isRunning(pid:)`, `readPid(from:)`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)

## Blast radius
- [instance-lock-macos](instance-lock-macos.md) — consumes its PID; called from its contention branch.
- [already-running-dialog](already-running-dialog.md) — the fallback.

## Known holes / open
- `NSWorkspace.open(bundleURL)` on a bundle with several copies installed may open a different copy; not examined.
- `WindowConfig.windowTitle` is ignored here.
