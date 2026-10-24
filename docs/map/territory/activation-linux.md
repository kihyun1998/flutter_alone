# activation-linux

## What it is
On Linux, when the lock is held: confirm the PID in the lock file is a live process running our executable, then ask the window manager to activate its window — through X11 EWMH, or through `xdotool` as a best effort on Wayland.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — `/proc/<pid>/exe` identity, X11 `_NET_ACTIVE_WINDOW` via `_NET_CLIENT_LIST` + `_NET_WM_PID`, Wayland best-effort `xdotool` via `posix_spawn`.

## Design model
From the source:
- Identity: `is_process_running` (`kill(pid,0)`, `EPERM` counts as running — cross-user) and `is_same_executable` (`readlink` of `/proc/self/exe` vs `/proc/<pid>/exe`). Reading another user's `/proc/<pid>/exe` normally fails, so a cross-user holder fails identity and gets the dialog.
- X11 is tried only when `is_x11_session()` and the build had `HAVE_X11` (`linux/CMakeLists.txt` defines it when `find_package(X11)` succeeds).
- X11: the first `_NET_CLIENT_LIST` window whose `_NET_WM_PID` equals the PID gets a `_NET_ACTIVE_WINDOW` client message (source indication 2) and `XMapRaised`. Input bound: at most `kMaxClientListItems` (4096) windows are read; truncation is warned, not handled.
- Otherwise `xdotool search --pid <pid> --limit 1 windowactivate` via `posix_spawnp` (no shell; CHANGELOG 4.0.0), without `--onlyvisible` so a hidden window can be reached (4.0.2).
- Any activation failure falls back to the dialog.

## Code
- `linux/flutter_alone_plugin.cc — is_process_running`, `is_same_executable`, `is_x11_session`, `find_window_by_pid`, `activate_window_x11`, `run_command`, `activate_window_wayland`, `activate_existing_window`, `handle_check_and_run`
- `linux/CMakeLists.txt` — the optional X11 link and `HAVE_X11`

## Reference behaviour
**None.** (EWMH is followed but not recorded as a reference in [thegraph.md](../../agents/thegraph.md).)

## Cross-cutting invariants
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)

## Blast radius
- [instance-lock-linux](instance-lock-linux.md) — trusts the PID the lock file holds.
- [already-running-dialog](already-running-dialog.md) — the fallback when activation returns false.
- [ci](ci.md) — CI installs `libx11-dev`; without it `HAVE_X11` is off and only the xdotool path is compiled.

## Known holes / open
- `activate_window_x11` returns `true` once the event is sent; whether the WM honoured it is not checked.
- On pure Wayland without XWayland or without `xdotool` installed, activation always fails and the dialog shows.
- `_NET_WM_PID` matching picks the first window of the PID, which may be a helper window.
