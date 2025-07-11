# Flutter Alone

A robust Flutter plugin to ensure only one instance of your desktop application runs at a time. Supports Windows and macOS.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Features

- Prevents duplicate application instances on Windows & macOS.
- Automatically focuses the original window when a duplicate is launched.
- Customizable alert messages with multi-language support.
- Flexible configuration for mutexes (Windows) and lockfiles (macOS).
- Special handling for debug mode to improve development workflow.

## Platform Support

| Windows | macOS | Linux |
|:-------:|:-----:|:-----:|
|    ✅    |   ✅   |   🚧   |

## Installation

Add `flutter_alone` to your `pubspec.yaml` file:

```yaml
dependencies:
  flutter_alone: ^3.2.4
```

Then, run `flutter pub get`.

## Platform-Specific Setup

For the plugin to work correctly, some platform-specific setup is required. Please follow the detailed instructions in our **[Platform Setup Guide](./PLATFORM_SETUP.md)**.

This guide covers:
- **Windows**: Resolving conflicts when using the `window_manager` package.
- **macOS**: Handling app reactivation (e.g., clicking the dock icon). This is **critical for system tray apps** to ensure the window reappears correctly.

## Basic Usage

Import the package in your `main.dart` file and add the initialization logic before `runApp`.

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Platform-specific configuration
  FlutterAloneConfig? config;
  if (Platform.isWindows) {
    config = FlutterAloneConfig.forWindows(
      windowsConfig: const DefaultWindowsMutexConfig(
        packageId: 'com.example.myapp',
        appName: 'My App',
      ),
      messageConfig: const EnMessageConfig(),
    );
  } else if (Platform.isMacOS) {
    config = FlutterAloneConfig.forMacOS(
      macOSConfig: const MacOSConfig(
        lockFileName: 'my_app.lock',
      ),
      messageConfig: const EnMessageConfig(),
    );
  }

  // Check for duplicate instance
  if (config != null && !await FlutterAlone.instance.checkAndRun(config: config)) {
    // Exit if another instance is running
    exit(0);
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    // IMPORTANT: Release resources on exit
    FlutterAlone.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(
        body: Center(
          child: Text('Hello, World!'),
        ),
      ),
    );
  }
}
```

## Advanced Configuration

For more detailed options, such as custom mutexes, messages, and debug settings, please see our **[Advanced Configuration Guide](./GUIDE.md)**.

## FAQ

### Q: Why do I need different native window titles with `window_manager`?
A: It prevents the Windows `FindWindow()` API from failing. See the [Platform Setup Guide](./PLATFORM_SETUP.md) for a full explanation.

### Q: Does the user see the native window title?
A: No. The user only sees the final title set by `window_manager`.

### Q: What if I don't use `window_manager`?
A: You can ignore the `window_manager` setup guide.

## Contributing

Contributions are welcome! Please feel free to submit pull requests or create issues.
