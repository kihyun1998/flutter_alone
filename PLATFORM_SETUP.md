# Platform-Specific Setup

This guide covers necessary platform-specific configurations.

## Windows: `window_manager` Title Conflict

If you use the **`window_manager`** package, you **MUST** set a different native window title to ensure `flutter_alone` can detect the original window correctly, especially in system tray scenarios.

### The Problem
When `window_manager` and the initial native window share the **exact same title**, the Windows `FindWindow()` API behaves unreliably.

### The Fix: Change `windows/runner/main.cpp`

Modify the `window.Create()` call in `windows/runner/main.cpp` to use a title **without spaces or special characters**. Your Dart code remains unchanged.

#### 1. **Modify `windows/runner/main.cpp`**
```cpp
// BEFORE (Causes detection issues)
if (!window.Create(L"My Flutter App", origin, size)) {
    return EXIT_FAILURE;
}

// AFTER (Correct - choose one)
if (!window.Create(L"MyFlutterApp", origin, size)) {        // Option 1: Remove spaces
    return EXIT_FAILURE;
}
// OR
if (!window.Create(L"My_Flutter_App", origin, size)) {      // Option 2: Use underscores
    return EXIT_FAILURE;
}
```

#### 2. **Keep Dart Code Unchanged**
Your `window_manager` and `flutter_alone` configurations in Dart should still use the user-visible title.
```dart
// main.dart - NO CHANGES NEEDED HERE
const String appTitle = 'My Flutter App';

// window_manager setup
WindowOptions windowOptions = const WindowOptions(
  title: appTitle, // User sees this title
);

// flutter_alone setup
FlutterAloneConfig config = FlutterAloneConfig.forWindows(
  windowConfig: const WindowConfig(
    windowTitle: appTitle, // flutter_alone uses this for detection
  ),
  // ... other configs
);
```

### Why?
Flutter on Windows creates a window in two stages. The native window is created first, and then `window_manager` changes its title. By ensuring the initial native title is unique, we avoid conflicts with the `FindWindow()` API, as recommended by [Microsoft's official documentation](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/obtain-console-window-handle).

---

## macOS: Handling App Reactivation

If your app can be hidden (e.g., in the system tray) or if you want to ensure the app window reappears when the user clicks the app icon in the dock, you need to modify your `macos/Runner/AppDelegate.swift` file.

Add the `applicationShouldHandleReopen` method to your `AppDelegate` class.

```swift
import Cocoa
import FlutterMacOS

@main
class AppDelegate: FlutterAppDelegate {
  override func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
    // This should be `false` for system tray apps
    return false
  }

  // Add this method
  override func applicationShouldHandleReopen(
    _ sender: NSApplication,
    hasVisibleWindows flag: Bool
  ) -> Bool {
    if !flag {
      for window in sender.windows {
        window.makeKeyAndOrderFront(self)
      }
    }
    return true
  }

  override func applicationSupportsSecureRestorableState(_ app: NSApplication) -> Bool {
    return true
  }
}
```

This ensures that if the app has no visible windows, clicking the dock icon will bring the main window to the front.
