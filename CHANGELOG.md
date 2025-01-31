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