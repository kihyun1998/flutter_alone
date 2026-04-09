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
