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

## Getting Started

Add flutter_alone to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_alone: ^3.1.0
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

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.
