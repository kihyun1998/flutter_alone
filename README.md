# flutter_alone

A robust Flutter plugin for preventing duplicate execution of desktop applications.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Features

- Prevent multiple instances of Windows desktop applications
- Cross-user detection support
- System-wide mutex management
- Customizable message handling with template support
- Multi-language support (English, Korean)
- Safe resource cleanup

## Platform Support

| Windows | macOS | Linux |
|:-------:|:-----:|:-----:|
|    ✅    |   🚧   |   🚧   |

## Getting Started

Add flutter_alone to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_alone: ^1.1.1
```

## Usage

Import the package:
```dart
import 'package:flutter_alone/flutter_alone.dart';
```

Basic usage with default English messages:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  if (!await FlutterAlone.instance.checkAndRun()) {  // Uses EnMessageConfig by default
    return;
  }
  
  runApp(const MyApp());
}
```

Using Korean messages:
```dart
if (!await FlutterAlone.instance.checkAndRun(
  messageConfig: const KoMessageConfig(),
)) {
  return;
}
```

Using custom messages with template:
```dart
final messageConfig = CustomMessageConfig(
  customTitle: 'App Running',
  messageTemplate: 'Application is already running by {domain}\\{userName}',
  showMessageBox: true,  // Optional, defaults to true
);

if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
  return;
}
```

Clean up resources:
```dart
@override
void dispose() {
  FlutterAlone.instance.dispose();
  super.dispose();
}
```

## Additional Information

### Message Configuration
The plugin provides three types of message configurations:
- `EnMessageConfig`: Default English messages
- `KoMessageConfig`: Korean messages
- `CustomMessageConfig`: Custom messages with template support

### Windows Implementation
- Uses Windows Named Mutex for system-wide instance detection
- Implements cross-user detection through global mutex naming
- Ensures proper cleanup of system resources
- Proper Unicode support for all languages