# flutter_alone

A robust Flutter plugin for preventing duplicate execution of desktop applications.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Features

- Prevent multiple instances of Windows desktop applications
- Cross-user detection support
- System-wide mutex management
- Customizable message handling
- Multi-language support (English, Korean, Custom)
- Safe resource cleanup

## Platform Support

| Windows | macOS | Linux |
|:-------:|:-----:|:-----:|
|    ✅    |   🚧   |   🚧   |

## Getting Started

Add flutter_alone to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_alone: ^1.1.0
```

## Usage

Import the package:
```dart
import 'package:flutter_alone/flutter_alone.dart';
```

Initialize in your main function:
```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final messageConfig = MessageConfig(
    type: MessageType.en,  // Language selection
    showMessageBox: true,  // Message box display control
  );
  
  if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
    exit(0);  // Exit if another instance is running
  }
  
  runApp(const MyApp());
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

### Windows Implementation
- Uses Windows Named Mutex for system-wide instance detection
- Implements cross-user detection through global mutex naming
- Ensures proper cleanup of system resources