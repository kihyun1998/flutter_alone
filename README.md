# flutter_alone

A Flutter plugin to prevent duplicate execution of desktop applications.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Features

- Prevent multiple instances of your Flutter desktop application
- Cross-user detection on Windows
- Safe resource cleanup
- System-wide mutex management

## Platform Support

| Windows | macOS | Linux |
|:-------:|:-----:|:-----:|
|    ✅    |   🚧   |   🚧   |

## Getting started

Add flutter_alone to your `pubspec.yaml`:

```yaml
dependencies:
  flutter_alone: ^1.0.0
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
  
  final flutterAlone = FlutterAlone.instance;
  final canRun = await flutterAlone.checkAndRun();
  
  if (!canRun) {
    // Another instance is already running
    exit(0);
  }
  
  runApp(const MyApp());
}
```

Clean up resources when your app closes:
```dart
@override
void dispose() {
  FlutterAlone.instance.dispose();
  super.dispose();
}
```

## Additional information

### Windows Implementation Details
- Uses Windows Named Mutex for system-wide instance detection
- Supports cross-user detection through global mutex naming
- Proper cleanup of system resources

## Contributing

Feel free to contribute to this project.

1. Fork it
2. Create your feature branch (git checkout -b feature/fooBar)
3. Commit your changes (git commit -am 'Add some fooBar')
4. Push to the branch (git push origin feature/fooBar)
5. Create a new Pull Request

## License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details
