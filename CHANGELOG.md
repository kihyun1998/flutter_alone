## 4.0.14

*   **Internal**
    *   Added unit coverage for the remaining pure logic: the `FlutterAlone` debug-mode skip and platform delegation, `AloneException.toString()`, and Windows `ProcessUtils::IsSameExecutable` (a new `process_utils_test` gtest; the method was made public so it can be tested). No behavior change.

## 4.0.13

*   **Internal**
    *   **Windows**: Broke the `process_utils` <-> `window_utils` circular dependency (issue #5 / F6). The existing-instance window lookup moved from `ProcessUtils::GetProcessInfoById` into the plugin, so `process_utils` no longer depends on `window_utils` (the dependency is now one-way). Also made the `ShowMessageBox` CBT-hook state `thread_local` instead of `static` (F7), removing a data race if the dialog is ever shown from multiple threads. No behavior change.

## 4.0.12

*   **Internal**
    *   Centralized the method-channel argument keys into a single `MethodChannelKeys` source on the Dart side, so the config classes no longer repeat the key strings as scattered literals (issue #5 / F5). No behavior change.

## 4.0.11

*   **Consistency**
    *   Unified the "already running" dialog strings into a single source of truth on the Dart side. `MessageConfig` now resolves the `title`/`message` and sends them to every platform, which simply displays them; the per-platform native string tables (Windows `MessageUtils` selection, macOS `DuplicateMessage`, Linux `message_text`) have been removed. This fixes cross-platform drift: the Windows dialog **title** for the built-in `ko`/`en` messages was `실행 오류` / `Execution Error` and is now `알림` / `Notice`, matching macOS and Linux. Message bodies and custom messages are unchanged.

## 4.0.10

*   **Internal**
    *   **Linux**: Extracted the localized message-string selection out of the plugin into a pure, GTK-independent `message_text` seam (`linux/message_text.{h,cc}`), covered by a `linux/test` gtest that now runs in CI. No change in observable behavior. This completes unit-test coverage of the "already running" string table across all three platforms (Windows `MessageUtils`, macOS `DuplicateMessage`, Linux `message_text`).

## 4.0.9

*   **Internal**
    *   **Windows**: Extracted the named-mutex logic into a standalone, Flutter-independent `MutexGuard` seam (`windows/mutex_guard.{h,cpp}`), covered by a `windows/test` gtest suite that now runs in CI via cmake/ctest. No change in observable behavior; the stale `getPlatformVersion` test stub was removed.

## 4.0.8

*   **Bug Fixes**
    *   **macOS**: The message configuration (`type`, `showMessageBox`, `customTitle`, `customMessage`) was previously ignored. When a duplicate instance was detected but the existing instance could not be activated (e.g. a different bundle identifier), the user received no feedback at all. macOS now shows an `NSAlert` with the localized or custom title and message in that case (gated by `showMessageBox`), matching the Windows and Linux behavior. The dialog text selection is factored into a pure `DuplicateMessage` helper covered by the example's XCTest target, which now runs in CI.

## 4.0.7

*   **Bug Fixes**
    *   **Windows**: An invalid mutex name (empty, longer than 260 characters, or containing a backslash after the `Global\` prefix) previously made the native layer return `false`, which `checkAndRun` reports as "already running" — so the app would **silently exit** instead of surfacing the misconfiguration. `WindowsMutexConfig` now validates the generated mutex name and throws `ArgumentError` (consistent with the existing `MacOSConfig`/`LinuxConfig` lock-file-name validation), so a bad configuration fails loudly at `checkAndRun` time. Valid names are unaffected.

## 4.0.6

*   **Refactor**
    *   Decoupled `FlutterAloneConfig.toMap()` from the runtime OS. The serialization logic moved into a new pure method `toMapFor(AlonePlatform)` that takes the target platform as a parameter; `toMap()` now delegates to it using the current OS. Every platform's serialization branch is now unit-testable on any OS/CI runner (previously `toMap()` threw `StateError` for the non-host platform, making off-platform branches untestable). No behavior change for existing callers. Adds the public `AlonePlatform` enum and `FlutterAloneConfig.toMapFor` method.

## 4.0.5

*   **Bug Fixes**
    *   **Linux**: Fixed a duplicate launch being able to delete the primary instance's lock file, which broke the single-instance guarantee on subsequent launches. Previously the lock-file path was recorded before the advisory `flock` was acquired, so a non-owning (duplicate) instance would `unlink` the holder's lock file on dispose. The lock logic is now isolated in a dedicated, ownership-scoped module (`lock_file.h` / `lock_file.cc`): the file path is recorded only when the lock is actually acquired, making the "path recorded but lock not held" state unrepresentable. A standalone gtest regression suite was added under `linux/test/` (buildable independently of the Flutter/GTK toolchain).

## 4.0.4

*   **Bug Fixes**
    *   **macOS**: Fixed hidden and Dock-minimized windows not being restored when a duplicate instance is launched.
        *   `bringWindowsToFront()` was called from the second instance's process context, making `NSApplication.shared.windows` refer to the second instance rather than the first — it has been removed.
        *   Added `app.unhide()` before activation so apps hidden via Cmd+H are properly restored.
        *   Replaced `app.activate(options:)` with `NSWorkspace.shared.open(bundleURL)`, which sends the standard `applicationShouldHandleReopen` event to the running instance and correctly restores Dock-minimized windows — analogous to the `IsWindowVisible` fix applied to Windows in v4.0.2.

## 4.0.3

*   **Bug Fixes**
    *   **Windows**: Fixed build failure in consumer projects on Korean (and other non-UTF-8 default codepage) Windows where MSVC read source files as CP949 and rejected em-dash (`—`, U+2014) characters in the newly added comments of `window_utils.cpp` and `flutter_alone_plugin.cpp` (C4819 promoted to C2220 via `/WX`). All non-ASCII punctuation in plugin source comments has been replaced with ASCII equivalents.

## 4.0.2

*   **Bug Fixes**
    *   **Windows**: Fixed hidden main windows (e.g., minimized to the system tray via `SW_HIDE`) not being found by PID-based lookup. The `IsWindowVisible` filter in `EnumWindowsCallback` was preventing restoration of tray-hidden instances; it has been replaced with a `GetWindow(..., GW_OWNER) == NULL` top-level check, so hidden main windows remain findable while tooltip/popup helper windows are still excluded.
    *   **Windows**: Replaced the `FindWindowW`-based title fallback in `CheckRunningInstance` with a new `WindowUtils::FindWindowByTitleAndPath` helper that enumerates **all** top-level windows with a matching title and picks the one whose owning process matches the current executable path. This fixes a scenario where two builds of the same app (e.g., installed and portable) share the same window title — previously `FindWindowW` would return only the first title match, and path verification would silently fail, leaving the intended instance unreachable.
    *   **Linux (Wayland)**: Removed `--onlyvisible` from the `xdotool` search arguments in `activate_window_wayland` so tray-minimized / hidden windows can still be activated by the fallback path. Added `--limit 1` as a safety bound against activating multiple helper windows that share the PID.

## 4.0.1

*   **Bug Fixes**
    *   **Windows**: Fixed build failure in consumer projects caused by missing `<flutter/encodable_value.h>` include in `flutter_alone_plugin.h`. The header referenced `flutter::EncodableMap` without including the defining header, which only compiled when transitively pulled in by other Flutter headers depending on include order.
    *   **Windows**: Renamed `MessageUtils::GetMessage` / `GetTitle` / `GetKoreanMessage` / `GetEnglishMessage` to `GetMessageText` / `GetTitleText` / `GetKoreanMessageText` / `GetEnglishMessageText` to avoid collision with the `GetMessage` preprocessor macro from `windows.h` (expands to `GetMessageW` under UNICODE), which caused `C2039: 'GetMessageW' is not a member of 'MessageUtils'` compile errors.

## 4.0.0

*   **New Features**
    *   Added full Linux platform support with X11 and Wayland window activation.
    *   Added `LinuxConfig` for lock file configuration on Linux.

*   **Security**
    *   **Windows**: Replaced null DACL with minimal-rights SDDL DACL (Everyone gets SYNCHRONIZE only, Creator/Owner gets full access) to prevent mutex squatting.
    *   **Windows**: Added mutex name validation (length, embedded backslash rejection) and `FindWindowW` title-spoofing defense via process identity verification.
    *   **Linux**: Replaced `system()` calls with `posix_spawnp()` to eliminate command injection risk in Wayland window activation.
    *   **Linux/macOS**: Implemented `flock()`-based advisory locking to eliminate TOCTOU race conditions. Lock files are automatically released by the kernel on process death.
    *   **Linux/macOS**: Added `O_NOFOLLOW` flag to prevent symlink attacks on lock files.
    *   **Linux**: Added process identity verification via `/proc/<pid>/exe` to prevent PID reuse false positives.
    *   **macOS**: Added bundle ID verification to prevent PID reuse false positives.
    *   **Linux/macOS**: Handle `errno == EPERM` from `kill(pid, 0)` for cross-user process detection.
    *   **All platforms**: Added `lockFileName` / `mutexName` input validation with path traversal defense (`.`, `..`, null bytes, path separators).
    *   **Windows**: Guarded all `OutputDebugStringW` calls with `#ifdef _DEBUG` to prevent information leakage in release builds.

*   **Improvements**
    *   **Windows**: Fixed `GetLastError()` being called after `CleanupResources()`, capturing the error code immediately after `CreateMutexW`.
    *   **Windows**: Added null-pointer guard for method call arguments and replaced `std::get<>` with `std::get_if<>` for type-safe argument extraction.
    *   **Windows**: Removed all dead code (unused `MutexConfig`, `GetMutexName`, `StringToWideString/WideStringToString`, `GetCurrentProcessInfo`, `GetLastErrorMessage`, `DestroyAppIcon`, `GetCurrentWindowTitle`, `WideToUtf8`).
    *   **Windows**: Consolidated icon handling (removed duplicate `ProcessUtils::GetExecutableIcon`, using only `IconUtils::GetAppIcon`).
    *   **Windows**: Fixed CBT hook `CallNextHookEx` receiving stale `NULL` handle after self-unhook.
    *   **Windows**: Added explicit `Advapi32` and `Secur32` to CMake `target_link_libraries`.
    *   **macOS**: Fixed `currentLockFilePath` double-assignment bug that could delete another instance's lock file on dispose.
    *   **macOS**: Added proper error logging for all file operations (`NSLog`).
    *   **macOS**: Fixed bundle ID guard logic (now requires both IDs to be present and match).
    *   **macOS**: Fixed podspec placeholder metadata (version, description, homepage, author).
    *   **Linux**: Fixed X11 `_NET_WM_PID` casting from `unsigned long*` to `uint32_t` via `memcpy` for LP64 correctness.
    *   **Linux**: Extracted `release_lock()`, `notify_already_running()`, and `handle_check_and_run()` helpers to reduce complexity.
    *   **Linux**: Fixed flock-fail PID read to use already-opened fd (`read_pid_from_fd`) instead of re-opening the file (TOCTOU fix).
    *   **Linux**: Added `posix_spawn_file_actions_addopen` return value checking.

*   **Breaking Changes**
    *   `MacOSConfig` and `LinuxConfig` constructors are no longer `const` (validation now uses `throw ArgumentError` instead of `assert`).
    *   `CustomWindowsMutexConfig` constructor is no longer `const` (same reason).
    *   `FlutterAloneConfig.toMap()` now throws `StateError` in release mode when platform config is missing (previously silent in release).
    *   `FlutterAlonePlatform.checkAndRun()` and `dispose()` are now abstract methods (previously had default `throw UnimplementedError` bodies).

*   **Dart**
    *   Replaced `assert` with `throw ArgumentError` in `LinuxConfig`, `MacOSConfig`, and `CustomWindowsMutexConfig` for release-mode enforcement.
    *   Replaced `assert` + null-guard with `throw StateError` in `FlutterAloneConfig.toMap()`.
    *   Removed unnecessary `removeWhere` call in method channel.
    *   Removed unnecessary `try/catch/rethrow` in `FlutterAlone.checkAndRun()` and `dispose()`.
    *   Improved `AloneException.toString()` to include `details`.
    *   Extracted `typeString` getter in `MessageConfig` base class to deduplicate `toMap()`.
    *   Extracted `_globalPrefix` and `_mutexNameKey` constants in `WindowsMutexConfig`.
    *   Promoted `toMap()` to base class in `WindowsMutexConfig`.

## 3.2.4
*   **Maintenance**
    *   Maintenance release.

## 3.2.3
*   **Documentation**
    *   Updated `README.md`.

## 3.2.2

*   **Documentation**
    *   Updated `pubspec.yaml` description and keywords.
    *   Updated `README.md`.

## 3.2.1

*   **Documentation**
    *   Updated `README.md` to reflect the latest changes and improvements.

## 3.2.0

*   **New Features**
    *   Added customizable lockfile name for macOS (`MacOSConfig.lockFileName`).

*   **Improvements**
    *   Enhanced macOS window activation logic when a duplicate instance is detected, ensuring hidden or minimized windows are brought to front.
    *   Refactored macOS lockfile path management to use native temporary directory API, removing `path_provider` dependency for lockfile handling.

## 3.1.3

*   **Update**
    *   update license

## 3.1.2

*   **Update**
    *   update license

## 3.1.1

*   **Documentation**
    *   Added critical setup guide for window_manager compatibility
    *   Documented window title conflict resolution
    *   Added FAQ and troubleshooting sections

*   **Improvements**
    *   Enhanced debug logging for window detection
    *   Improved error diagnostics for title conflicts

## 3.1.0

*   **New Features**
    *   Added `CustomMutexConfig` for direct mutex name specification
    *   Refactored mutex configuration to support multiple naming strategies
    *   Simplified mutex name handling across platform boundaries
    *   Enhanced code organization with better abstraction

*   **Breaking Changes**
    *   `MutexConfig` is now an abstract class with implementations:
        *   `DefaultMutexConfig` (backward compatible with existing approach)
        *   `CustomMutexConfig` (new approach with direct mutex name specification)

*   **Improvements**
    *   Moved mutex name generation logic to Dart side for better flexibility
    *   Streamlined native code interfaces
    *   Improved test coverage for various mutex configuration scenarios
    *   Enhanced example application with both configuration approaches

## 3.0.0

*   **Breaking Changes**
    *   Redesigned configuration system with introduction of `FlutterAloneConfig`
    *   Replaced `messageConfig` parameter with unified `config` parameter
    *   Separated configuration objects by concern: `MutexConfig`, `WindowConfig`, `DuplicateCheckConfig`, `MessageConfig`

*   **Improvements**
    *   Enhanced configuration value access in native code
        *   Added null checks for all configuration values
        *   Implemented safe parameter reference handling
        *   Strengthened type verification
    *   Improved error handling and messages
    *   Better code organization through modularized configuration structure

## 2.3.4

*   **Maintenance**
    *   Maintenance release.

## 2.3.1

*   **Improvements**
    *   Applied consistent code formatting throughout the project
    *   Fixed code style issues according to Dart formatting guidelines

## 2.3.0

*   **Breaking Changes**
    *   Simplified `checkAndRun()` method API - now uses only `messageConfig` parameter
    *   Made `packageId` and `appName` required parameters in `MessageConfig` class
    *   Improved API consistency by removing duplicate parameters

*   **Improvements**
    *   Enhanced documentation for message configuration
    *   Optimized automatic package information detection logic
    *   General code base cleanup and refactoring

## 2.2.0

*   **New Features**
    *   Added window title parameter for better window identification
    *   Improved window detection for system tray applications
    *   Enhanced same-user window activation and focusing
    *   Added system tray example implementation to demonstration project

*   **Improvements**
    *   Better window management for minimized or hidden windows
    *   Optimized cross-user and same-user application instance detection
    *   Enhanced error handling for window activation failures

## 2.1.0

*   **New Features**
    *   Added customizable mutex name configuration
    *   Added package ID and app name parameters for fine-grained mutex control
    *   Added optional mutex suffix parameter
    *   Added automatic application information detection using package_info_plus

*   **Improvements**
    *   Enhanced mutex name generation with sanitization and validation
    *   Improved error handling for invalid mutex names
    *   Added comprehensive documentation for mutex customization
    *   Optimized mutex resource management

## 2.0.2

*   **New Features**
    *   Added debug mode configuration option
    *   Added `enableInDebugMode` flag to control duplicate checks in debug mode
    *   Automatically skips duplicate checks in debug mode by default

## 2.0.1

*   **Enhancements**
    *   Improved MessageBox taskbar icon display
    *   Added application icon management system
    *   Enhanced MessageBox window hook implementation
    *   Optimized taskbar visual identification

## 2.0.0

*   **Breaking Changes**
    *   Restructured platform implementation for better stability
    *   Redesigned message configuration system

*   **New Features**
    *   Added process information model with detailed system data
    *   Enhanced Windows mutex handling
    *   Improved window management (restore, focus, bring to front)
    *   Added comprehensive test coverage (unit, integration, method channel)
    *   Added detailed process utilities for Windows

*   **Improvements**
    *   Enhanced error handling with custom exceptions
    *   Improved resource cleanup
    *   Better cross-user detection
    *   Added documentation and examples

## 1.1.1

*   Fixed Korean text encoding issues in message box
*   Improved message configuration architecture
*   Enhanced type safety with dedicated message config classes
*   Added template support for custom messages

## 1.1.0

*   Added message configuration (English/Korean/Custom)
*   Added message box display control option
*   Enhanced process information model
*   Improved code structure and stability

## 1.0.0

*   Implemented duplicate execution prevention for Windows
*   Added system-level duplicate detection using global mutex
*   Added multi-user account support
