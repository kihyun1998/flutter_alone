# flutter_alone

A robust Flutter plugin for preventing duplicate execution of desktop applications, offering advanced process management, window control, and cross-user detection.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Features

- **Duplicate Execution Prevention**
  - System-wide mutex management
  - Cross-user account detection
  - Process-level duplicate checking
  - Debug mode support with configurable options
  - Customizable mutex naming strategies:
    - Application ID based naming (DefaultMutexConfig)
    - Custom mutex name specification (CustomMutexConfig)

- **Window Management**
  - Automatic window focusing
  - Window restoration handling
  - Bring to front functionality
  - Enhanced taskbar identification
  - Rich MessageBox with application icon
  - Window detection by window title
  - System tray application support

- **Customizable Messaging**
  - Multi-language support (English/Korean)
  - Custom message templates
  - Configurable message box display
  - UTF-8 text encoding support

- **Process Management**
  - Detailed process information tracking
  - Safe resource cleanup
  - Robust error handling

## Platform Support

| Windows | macOS | Linux |
|:-------:|:-----:|:-----:|
|    ✅    |   🚧   |   🚧   |

## ⚠️ **Critical Setup for window_manager Users**

If you're using flutter_alone with the **window_manager** package, you **MUST** configure window titles correctly to avoid detection failures.

### 🚨 **The Problem**
When window_manager and flutter_alone use **identical window titles**, window detection fails in system tray scenarios.

### ❌ **Incorrect Setup (Detection Fails)**
```dart
// main.dart
const String appTitle = 'My Flutter App';

WindowOptions windowOptions = const WindowOptions(
  title: appTitle,  // "My Flutter App"
);

FlutterAloneConfig config = FlutterAloneConfig(
  windowConfig: const WindowConfig(
    windowTitle: appTitle,  // "My Flutter App" (same!)
  ),
  messageConfig: const EnMessageConfig(),
);
```

```cpp
// windows/runner/main.cpp
if (!window.Create(L"My Flutter App", origin, size)) {  // Same title!
    return EXIT_FAILURE;
}
```

### ✅ **Correct Setup (Detection Works)**
```dart
// main.dart - Keep your desired titles
const String appTitle = 'My Flutter App';

WindowOptions windowOptions = const WindowOptions(
  title: appTitle,  // "My Flutter App" (user-visible)
);

FlutterAloneConfig config = FlutterAloneConfig(
  windowConfig: const WindowConfig(
    windowTitle: appTitle,  // "My Flutter App" (detection)
  ),
  messageConfig: const EnMessageConfig(),
);
```

```cpp
// windows/runner/main.cpp - Make this different!
if (!window.Create(L"MyFlutterApp", origin, size)) {  // 🎯 Different!
    return EXIT_FAILURE;
}
```

### 📝 **Quick Fix Guide**

#### 1. **Modify windows/runner/main.cpp Only**
```cpp
// BEFORE (same title - causes issues)
if (!window.Create(L"My Flutter App", origin, size)) {
    return EXIT_FAILURE;
}

// AFTER (remove spaces or use underscores)
if (!window.Create(L"MyFlutterApp", origin, size)) {        // Remove spaces
    return EXIT_FAILURE;
}

// OR
if (!window.Create(L"My_Flutter_App", origin, size)) {      // Use underscores
    return EXIT_FAILURE;
}
```

#### 2. **Keep Dart Code Unchanged**
```dart
// Your flutter_alone and window_manager code stays the same
const String appTitle = 'My Flutter App';  // Spaces OK here!

WindowOptions windowOptions = const WindowOptions(
  title: appTitle,  // User sees this title
);

FlutterAloneConfig config = FlutterAloneConfig(
  windowConfig: const WindowConfig(
    windowTitle: appTitle,  // flutter_alone uses this for detection
  ),
);
```

### 🤔 **Why Does This Happen?**

Flutter Windows apps create windows in two stages:
1. **Native Creation**: `window.Create()` creates the initial Win32 window
2. **Flutter Setup**: `window_manager` later changes the title with `SetWindowText()`

When titles are identical, the Windows `FindWindow()` API becomes unpredictable with multiple windows having the same name, causing detection failures.

This follows [Microsoft's official recommendation](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/obtain-console-window-handle) to use unique window titles.

### 💡 **Title Conversion Examples**

| Display Title | Native Title (main.cpp) |
|---------------|-------------------------|
| `"My App"` | `"MyApp"` |
| `"Flutter Chat"` | `"FlutterChat"` |  
| `"Data Analyzer"` | `"Data_Analyzer"` |
| `"Music Player"` | `"MusicPlayer"` |

---

## Getting Started

Add flutter_alone to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_alone: ^3.1.3
```

## Usage

Import the package:
```dart
import 'package:flutter_alone/flutter_alone.dart';
```

### Basic Usage with Default Settings
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final config = FlutterAloneConfig(
    mutexConfig: const DefaultMutexConfig(
      packageId: 'com.example.myapp',
      appName: 'MyFlutterApp'
    ),
    messageConfig: const EnMessageConfig(),
  );
  
  if (!await FlutterAlone.instance.checkAndRun(config: config)) {
    exit(0);
  }
  
  runApp(const MyApp());
}
```

### Using Custom Mutex Name

When you need more direct control over mutex naming:

```dart
final config = FlutterAloneConfig(
  mutexConfig: const CustomMutexConfig(
    customMutexName: 'MyUniqueApplicationMutex',
  ),
  messageConfig: const EnMessageConfig(),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

### Using Korean Messages
```dart
final config = FlutterAloneConfig(
  mutexConfig: const DefaultMutexConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp'
  ),
  messageConfig: const KoMessageConfig(),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

### Custom Message Configuration
```dart
final config = FlutterAloneConfig(
  mutexConfig: const DefaultMutexConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp'
  ),
  messageConfig: const CustomMessageConfig(
    customTitle: 'Application Notice',
    customMessage: 'Application is already running',
    showMessageBox: true,  // Optional, defaults to true
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

### Default Mutex Configuration with Suffix

You can customize the default mutex name with package ID, app name and an optional suffix:

```dart
final config = FlutterAloneConfig(
  mutexConfig: const DefaultMutexConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp',
    mutexSuffix: 'production',
  ),
  messageConfig: const EnMessageConfig(),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

### Window Title for Better Window Detection

For system tray applications or when you need specific window identification:

```dart
final config = FlutterAloneConfig(
  mutexConfig: const DefaultMutexConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp',
  ),
  windowConfig: const WindowConfig(
    windowTitle: 'My Application Window Title',  // Used for window detection
  ),
  messageConfig: const CustomMessageConfig(
    customTitle: 'Notice',
    customMessage: 'Application is already running',
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

### Debug Mode Configuration

The plugin provides special handling for debug mode:

- By default, duplicate checks are skipped in debug mode for better development experience
- You can enable duplicate checks in debug mode using the `enableInDebugMode` flag

#### Debug Mode Examples

```dart
// Default behavior (skips duplicate check in debug mode)
final config = FlutterAloneConfig(
  mutexConfig: const DefaultMutexConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp'
  ),
  messageConfig: const EnMessageConfig(),
);

// Enable duplicate check even in debug mode
final config = FlutterAloneConfig(
  mutexConfig: const DefaultMutexConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp'
  ),
  duplicateCheckConfig: const DuplicateCheckConfig(
    enableInDebugMode: true
  ),
  messageConfig: const EnMessageConfig(),
);
```

### Comprehensive Configuration Examples

Here are examples with all configuration options:

**Using DefaultMutexConfig:**
```dart
final config = FlutterAloneConfig(
  // Default Mutex configuration
  mutexConfig: const DefaultMutexConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp',
    mutexSuffix: 'production',
  ),

  // Window configuration
  windowConfig: const WindowConfig(
    windowTitle: 'My Application Window',
  ),

  // Duplicate check configuration
  duplicateCheckConfig: const DuplicateCheckConfig(
    enableInDebugMode: true,
  ),

  // Message configuration
  messageConfig: const CustomMessageConfig(
    customTitle: 'Application Notice',
    customMessage: 'Application is already running',
    showMessageBox: true,
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

**Using CustomMutexConfig:**
```dart
final config = FlutterAloneConfig(
  // Custom Mutex configuration
  mutexConfig: const CustomMutexConfig(
    customMutexName: 'MyUniqueAppMutex',
  ),

  // Window configuration
  windowConfig: const WindowConfig(
    windowTitle: 'My Application Window',
  ),

  // Duplicate check configuration
  duplicateCheckConfig: const DuplicateCheckConfig(
    enableInDebugMode: true,
  ),

  // Message configuration
  messageConfig: const CustomMessageConfig(
    customTitle: 'Application Notice',
    customMessage: 'Application is already running',
    showMessageBox: true,
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

### System Tray Applications

For system tray applications, you can use the windowTitle parameter to help the plugin locate and activate your existing window:

```dart
final config = FlutterAloneConfig(
  mutexConfig: const CustomMutexConfig(
    customMutexName: 'MySystemTrayApp',
  ),
  windowConfig: const WindowConfig(
    windowTitle: 'My System Tray App',
  ),
  messageConfig: const CustomMessageConfig(
    customTitle: 'Notice',
    customMessage: 'Application is already running',
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

See the example project for a complete system tray implementation with flutter_alone.

### Resource Cleanup
Always remember to dispose of resources when your application closes:
```dart
class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    FlutterAlone.instance.dispose();
    super.dispose();
  }

  // ... rest of your widget implementation
}
```

## Advanced Features

### Mutex Configuration Types
The plugin now provides two ways to configure mutex names:

- **DefaultMutexConfig**: Uses package ID and app name to generate mutex names (traditional approach)
- **CustomMutexConfig**: Allows direct specification of mutex name (new approach)

### Configuration Classes
The plugin provides a modular configuration system:

- `FlutterAloneConfig`: Main configuration container
  - `MutexConfig`: Abstract base class for mutex configuration
    - `DefaultMutexConfig`: Controls mutex naming using package ID and app name
    - `CustomMutexConfig`: Controls mutex naming with a custom name
  - `WindowConfig`: Window detection settings
  - `DuplicateCheckConfig`: Controls debug mode behavior
  - `MessageConfig`: Message display settings (includes `EnMessageConfig`, `KoMessageConfig`, and `CustomMessageConfig`)

### Windows Implementation Details
- Uses Windows Named Mutex for system-wide instance detection
- Implements robust cross-user detection through global mutex naming
- Ensures proper cleanup of system resources
- Full Unicode support for international character sets
- Advanced window management capabilities
- Enhanced taskbar and message box icon handling
- Customizable mutex naming with sanitization and validation
- Window detection and activation for system tray applications

## Error Handling

The plugin provides detailed error information through the `AloneException` class:
```dart
try {
  await FlutterAlone.instance.checkAndRun(
    config: FlutterAloneConfig(
      mutexConfig: const DefaultMutexConfig(
        packageId: 'com.example.myapp',
        appName: 'MyFlutterApp'
      ),
      messageConfig: const EnMessageConfig(),
    )
  );
} on AloneException catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  print('Details: ${e.details}');
}
```

## Choosing Between Mutex Configuration Types

- Use **DefaultMutexConfig** when:
  - You want automatic mutex name generation based on your app's identity
  - You need backward compatibility with earlier versions
  - You want the plugin to handle name generation and sanitization

- Use **CustomMutexConfig** when:
  - You need full control over mutex naming
  - You have specific mutex naming requirements
  - You want to use the same mutex across different applications

## Frequently Asked Questions (FAQ)

### Q: Why do I need to set different native window titles when using window_manager?
A: Flutter apps create windows in two stages. Having different native titles prevents Windows' FindWindow API from returning unpredictable results when multiple windows temporarily have the same title.

### Q: Does the user see the native window title?
A: No! The user only sees the title set by window_manager. The native title is used internally for window detection.

### Q: Can I automate the title conversion?
A: Yes! You can create a helper function to automatically generate native titles by removing spaces and special characters.

### Q: What if I don't use window_manager?
A: If you're not using window_manager, you don't need to worry about this issue. The plugin will work normally.

### Q: Does this affect other desktop platforms?
A: This is a Windows-specific issue. When macOS and Linux support are added, they may have different requirements.

## Troubleshooting

### System Tray Detection Issues
If your system tray application isn't being detected properly:

1. **Check window titles**: Ensure native and display titles follow the guidelines above
2. **Verify window_manager setup**: Make sure window_manager is properly initialized
3. **Enable debug mode**: Set `enableInDebugMode: true` to test detection in development
4. **Check example project**: Reference the included system tray example

### Window Activation Problems
If existing windows aren't being brought to front:

1. **Verify window title configuration**: Follow the window_manager setup guide
2. **Check window state**: Ensure the window isn't in an invalid state
3. **Test focus behavior**: Some security software may prevent window activation

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.

## References

- [Windows FindWindow API Documentation](https://learn.microsoft.com/en-us/windows/win32/api/winuser/nf-winuser-findwindow)
- [Microsoft: Using Unique Window Titles](https://learn.microsoft.com/en-us/troubleshoot/windows-server/performance/obtain-console-window-handle)
- [Flutter Desktop Documentation](https://docs.flutter.dev/platform-integration/desktop)