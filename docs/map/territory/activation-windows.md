# activation-windows

## What it is
On Windows, when the mutex already exists: find the running instance's top-level window and restore, raise and focus it, so a duplicate launch brings the first one forward instead of only refusing to start.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — Toolhelp snapshot for the same executable path, then `EnumWindows` matching title **and** owning-process path.

## Design model
From the source and CHANGELOG 4.0.2:
- Primary lookup: `ProcessUtils::FindExistingProcess` — the first other process whose image path equals ours (`IsSameExecutable`: `GetFullPathNameW` + case-insensitive compare) — then `WindowUtils::FindMainWindow(pid)`: the first unowned top-level window with a non-empty title. It does **not** filter on visibility, so a tray-hidden window is still found (4.0.2).
- Fallback, only when `WindowConfig.windowTitle` is set: `FindWindowByTitleAndPath` enumerates every top-level window with that exact title and keeps the one whose process path matches ours, so an installed and a portable build sharing a title are told apart (4.0.2).
- `process_utils` no longer depends on `window_utils`; the plugin does the window lookup (commit 8ba70e0).
- Restore: `ShowWindow(SW_SHOW)` if hidden, `SW_RESTORE` if iconic, then `SetForegroundWindow` and `SetFocus`.
- Path buffers are `MAX_PATH`; a longer image path makes `GetProcessPath` return empty and detection gives up (`FindExistingProcess` returns `nullopt`).

## Code
- `windows/process_utils.cpp — ProcessUtils::FindExistingProcess`, `IsSameExecutable`, `GetProcessPath`, `GetProcessInfoById`, `GetProcessStartTime`
- `windows/window_utils.cpp — WindowUtils::FindMainWindow`, `FindWindowByTitleAndPath`, `RestoreWindow`, `BringWindowToFront`, `FocusWindow`, `EnumWindowsCallback`, `EnumByTitleAndPathCallback`
- `windows/flutter_alone_plugin.cpp — CheckRunningInstance`, `HandleMethodCall` (the restore sequence)
- Tests: `windows/test/process_utils_test.cpp` (`IsSameExecutable` only)

## Reference behaviour
- Win32 API docs (Microsoft Learn, summarized — binding): `SetForegroundWindow` restrictions, `EnumWindows`, `QueryFullProcessImageNameW`. Foreground-lock rules are not handled explicitly; whether `SetForegroundWindow` from the duplicate succeeds needs confirming on real systems.

## Cross-cutting invariants
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)

## Blast radius
- [already-running-dialog](already-running-dialog.md) — the dialog shows exactly when no window was found; widening or narrowing the lookup moves cases between the two.
- [example-app](example-app.md) — the example's tray hide is the scenario the no-visibility-filter rule exists for.
- [configuration](configuration.md) — the title fallback depends on `WindowConfig.windowTitle`.

## Known holes / open
- An instance owned by another user: `OpenProcess` on its process usually fails, so no window is found and the dialog shows instead — consistent with the default message "already running in another account", but not stated anywhere as the design.
- `ProcessInfo.startTime` is collected but never read.
- `MAX_PATH` buffers: long-path installs lose activation.
