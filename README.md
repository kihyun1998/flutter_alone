# flutter_alone

A robust Flutter plugin for preventing duplicate execution of desktop applications, offering advanced process management, window control, and cross-user detection.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Features

- **Duplicate Execution Prevention**
  - System-wide mutex management
  - Cross-user account detection
  - Process-level duplicate checking
  - Debug mode support with configurable options
  - Customizable mutex naming

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

## Getting Started

Add flutter_alone to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_alone: ^2.3.0
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
  
  if (!await FlutterAlone.instance.checkAndRun(
    messageConfig: EnMessageConfig(
      packageId: 'com.example.myapp', 
      appName: 'MyFlutterApp'
    )
  )) {
    exit(0);
  }
  
  runApp(const MyApp());
}
```

### Using Korean Messages
```dart
if (!await FlutterAlone.instance.checkAndRun(
  messageConfig: KoMessageConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp'
  ),
)) {
  exit(0);
}
```

### Custom Message Configuration
```dart
final messageConfig = CustomMessageConfig(
  customTitle: 'Application Notice',
  customMessage: 'Application is already running',
  showMessageBox: true,  // Optional, defaults to true
  packageId: 'com.example.myapp',
  appName: 'MyFlutterApp',
);

if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
  exit(0);
}
```

### Custom Mutex Configuration

You can customize the mutex name with package ID, app name and an optional suffix:

```dart
if (!await FlutterAlone.instance.checkAndRun(
  messageConfig: EnMessageConfig(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp',
    mutexSuffix: 'production',
  ),
)) {
  exit(0);
}
```

### Window Title for Better Window Detection

For system tray applications or when you need specific window identification:

```dart
if (!await FlutterAlone.instance.checkAndRun(
  messageConfig: CustomMessageConfig(
    customTitle: 'Notice',
    customMessage: 'Application is already running',
    windowTitle: 'My Application Window Title',  // Used for window detection
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp',
  ),
)) {
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
final config = EnMessageConfig(
  packageId: 'com.example.myapp',
  appName: 'MyFlutterApp'
);

// Enable duplicate check even in debug mode
final config = EnMessageConfig(
  packageId: 'com.example.myapp',
  appName: 'MyFlutterApp',
  enableInDebugMode: true
);

// Custom configuration with debug mode setting
final config = CustomMessageConfig(
  customTitle: 'Notice',
  customMessage: 'Application is already running',
  packageId: 'com.example.myapp',
  appName: 'MyFlutterApp',
  enableInDebugMode: true,  // Enable duplicate check in debug mode
);
```

### System Tray Applications

For system tray applications, you can use the windowTitle parameter to help the plugin locate and activate your existing window:

```dart
if (!await FlutterAlone.instance.checkAndRun(
  messageConfig: CustomMessageConfig(
    customTitle: 'Notice',
    customMessage: 'Application is already running',
    windowTitle: 'My System Tray App',
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp',
  ),
)) {
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

### Message Configuration Classes
The plugin provides three types of message configurations:
- `EnMessageConfig`: Default English messages
- `KoMessageConfig`: Korean messages
- `CustomMessageConfig`: Custom messages with template support

Each configuration supports:
- `showMessageBox`: Control message box display
- `enableInDebugMode`: Control duplicate checks in debug mode
- `packageId`: Required package identifier for mutex name generation
- `appName`: Required application name for mutex name generation
- `mutexSuffix`: Optional suffix for mutex name customization
- `windowTitle`: Window title for better window detection and activation

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
    messageConfig: EnMessageConfig(
      packageId: 'com.example.myapp', 
      appName: 'MyFlutterApp'
    )
  );
} on AloneException catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  print('Details: ${e.details}');
}
```

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.