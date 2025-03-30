## 2.2.0

* **New Features**
  * Added window title parameter for better window identification
  * Improved window detection for system tray applications
  * Enhanced same-user window activation and focusing
  * Added system tray example implementation to demonstration project

* **Improvements**
  * Better window management for minimized or hidden windows
  * Optimized cross-user and same-user application instance detection
  * Enhanced error handling for window activation failures

## 2.1.0

* **New Features**
  * Added customizable mutex name configuration
  * Added package ID and app name parameters for fine-grained mutex control
  * Added optional mutex suffix parameter
  * Added automatic application information detection using package_info_plus

* **Improvements**
  * Enhanced mutex name generation with sanitization and validation
  * Improved error handling for invalid mutex names
  * Added comprehensive documentation for mutex customization
  * Optimized mutex resource management

## 2.0.2

* **New Features**
  * Added debug mode configuration option
  * Added `enableInDebugMode` flag to control duplicate checks in debug mode
  * Automatically skips duplicate checks in debug mode by default

## 2.0.1

* **Enhancements**
 * Improved MessageBox taskbar icon display
 * Added application icon management system
 * Enhanced MessageBox window hook implementation
 * Optimized taskbar visual identification

## 2.0.0

* **Breaking Changes**
  * Restructured platform implementation for better stability
  * Redesigned message configuration system

* **New Features**
  * Added process information model with detailed system data
  * Enhanced Windows mutex handling
  * Improved window management (restore, focus, bring to front)
  * Added comprehensive test coverage (unit, integration, method channel)
  * Added detailed process utilities for Windows

* **Improvements**
  * Enhanced error handling with custom exceptions
  * Improved resource cleanup
  * Better cross-user detection
  * Added documentation and examples

## 1.1.1

* Fixed Korean text encoding issues in message box
* Improved message configuration architecture
* Enhanced type safety with dedicated message config classes
* Added template support for custom messages

## 1.1.0

* Added message configuration (English/Korean/Custom)
* Added message box display control option
* Enhanced process information model
* Improved code structure and stability

## 1.0.0

* Implemented duplicate execution prevention for Windows
* Added system-level duplicate detection using global mutex
* Added multi-user account support