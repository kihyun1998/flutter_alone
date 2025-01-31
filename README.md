# flutter_alone

A robust Flutter plugin for preventing duplicate execution of desktop applications, offering advanced process management and cross-user detection.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Features

- **Duplicate Execution Prevention**
  - System-wide mutex management
  - Cross-user account detection
  - Process-level duplicate checking

- **Window Management**
  - Automatic window focusing
  - Window restoration handling
  - Bring to front functionality

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
  flutter_alone: ^2.0.0
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
  
  if (!await FlutterAlone.instance.checkAndRun()) {  // Uses EnMessageConfig by default
    exit(0);
  }
  
  runApp(const MyApp());
}
```

### Using Korean Messages
```dart
if (!await FlutterAlone.instance.checkAndRun(
  messageConfig: const KoMessageConfig(),
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
);

if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
  exit(0);
}
```

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

### Windows Implementation Details
- Uses Windows Named Mutex for system-wide instance detection
- Implements robust cross-user detection through global mutex naming
- Ensures proper cleanup of system resources
- Full Unicode support for international character sets
- Advanced window management capabilities

## Error Handling

The plugin provides detailed error information through the `AloneException` class:
```dart
try {
  await FlutterAlone.instance.checkAndRun();
} on AloneException catch (e) {
  print('Error Code: ${e.code}');
  print('Message: ${e.message}');
  print('Details: ${e.details}');
}
```

## Contributing

Contributions are welcome! Please read our contributing guidelines before submitting pull requests.