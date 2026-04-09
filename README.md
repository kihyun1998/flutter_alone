# Flutter Alone

A Flutter plugin that ensures only a **single instance** of your desktop application runs at a time.
When a duplicate is launched, it automatically focuses the original window and shows an alert message.

[![pub package](https://img.shields.io/pub/v/flutter_alone.svg)](https://pub.dev/packages/flutter_alone)

## Platform Support

| Windows | macOS | Linux (X11) | Linux (Wayland) |
|:-------:|:-----:|:-----------:|:---------------:|
|    ✅    |   ✅   |      ✅      |   ⚠️ Partial    |

- **Windows**: Detects duplicates using system-level Mutex with cross-user support
- **macOS**: Detects duplicates using advisory file locks (`flock`)
- **Linux (X11)**: Full support — duplicate detection via `flock` and window activation via `_NET_ACTIVE_WINDOW`
- **Linux (Wayland)**: **Partial support** — duplicate detection works reliably, but window activation is best-effort only. Wayland does not provide an API for cross-process window raising by design. The plugin falls back to `xdotool` via XWayland; if `xdotool` is unavailable or the app is a native Wayland client, only the alert dialog is shown (no window activation).

## Installation

```yaml
dependencies:
  flutter_alone: ^4.0.0
```

```bash
flutter pub get
```

## Quick Start

```dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

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
      macOSConfig: MacOSConfig(lockFileName: 'my_app.lock'),
      messageConfig: const EnMessageConfig(),
    );
  } else if (Platform.isLinux) {
    config = FlutterAloneConfig.forLinux(
      linuxConfig: LinuxConfig(lockFileName: 'my_app.lock'),
      messageConfig: const EnMessageConfig(),
    );
  }

  if (config != null && !await FlutterAlone.instance.checkAndRun(config: config)) {
    exit(0); // Another instance is already running
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
    FlutterAlone.instance.dispose(); // Always release resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: Scaffold(body: Center(child: Text('Hello, World!'))),
    );
  }
}
```

## API

### `FlutterAlone.instance`

| Method | Return | Description |
|--------|--------|-------------|
| `checkAndRun(config:)` | `Future<bool>` | Checks for a duplicate instance. Returns `true` if the app can start, `false` if another instance is already running. |
| `dispose()` | `Future<void>` | Releases mutex/lock file resources. Must be called when the app exits. |

### `FlutterAloneConfig`

Use platform-specific factory constructors to create the configuration.

```dart
// Windows
FlutterAloneConfig.forWindows(
  windowsConfig: ...,        // required - Mutex settings
  messageConfig: ...,        // required - Alert message settings
  windowConfig: ...,         // optional - Window identification
  duplicateCheckConfig: ..., // optional - Debug mode behavior
)

// macOS
FlutterAloneConfig.forMacOS(
  macOSConfig: ...,          // required - Lock file settings
  messageConfig: ...,        // required - Alert message settings
  windowConfig: ...,         // optional - Window identification
  duplicateCheckConfig: ..., // optional - Debug mode behavior
)

// Linux
FlutterAloneConfig.forLinux(
  linuxConfig: ...,          // required - Lock file settings
  messageConfig: ...,        // required - Alert message settings
  windowConfig: ...,         // optional - Window identification
  duplicateCheckConfig: ..., // optional - Debug mode behavior
)
```

---

## Configuration Options

### Windows Mutex Config

Configures the system mutex name used for duplicate detection.

#### `DefaultWindowsMutexConfig`

Auto-generates a mutex name from your package ID and app name.

```dart
const DefaultWindowsMutexConfig(
  packageId: 'com.example.myapp',  // required
  appName: 'My App',               // required
  mutexSuffix: 'prod',             // optional
)
// Generated mutex name: "Global\com.example.myapp_My App_prod"
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `packageId` | `String` | Yes | - | Package identifier (e.g., `com.example.myapp`) |
| `appName` | `String` | Yes | - | Application name |
| `mutexSuffix` | `String?` | No | `null` | Suffix appended to the mutex name. Useful for distinguishing environments (e.g., dev/prod) |

#### `CustomWindowsMutexConfig`

Specify the mutex name directly.

```dart
CustomWindowsMutexConfig(
  customMutexName: 'MyUniqueAppMutex',  // required
)
// Automatically prefixed with "Global\" if not already present
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `customMutexName` | `String` | Yes | - | Custom mutex name. `Global\` prefix is added automatically if missing |

---

### macOS Lock File Config

#### `MacOSConfig`

```dart
MacOSConfig(
  lockFileName: 'my_app.lock',  // optional
)
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `lockFileName` | `String` | No | `'.lockfile'` | Name of the lock file created in the system temp directory. **Must be unique per app** to avoid collisions |

---

### Linux Lock File Config

#### `LinuxConfig`

```dart
LinuxConfig(
  lockFileName: 'my_app.lock',  // optional
)
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `lockFileName` | `String` | No | `'.lockfile'` | Name of the lock file created in `/tmp`. **Must be unique per app** to avoid collisions |

> **Note**: On Wayland sessions, window activation of the existing instance requires `xdotool` (run via XWayland). Native Wayland does not permit cross-process window raising, so on pure Wayland setups only the alert dialog will be shown when a duplicate is detected.

---

### Message Config

Configures the alert message shown when a duplicate instance is detected.

#### `EnMessageConfig` - English (built-in)

```dart
const EnMessageConfig(
  showMessageBox: true,  // optional
)
```

#### `KoMessageConfig` - Korean (built-in)

```dart
const KoMessageConfig(
  showMessageBox: true,  // optional
)
```

#### `CustomMessageConfig` - Custom message

```dart
const CustomMessageConfig(
  customTitle: 'Notice',                                  // required
  customMessage: 'The application is already running.',   // required
  showMessageBox: true,                                   // optional
)
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `customTitle` | `String` | Yes | - | Title of the alert dialog |
| `customMessage` | `String` | Yes | - | Body text of the alert dialog |
| `showMessageBox` | `bool` | No | `true` | Set to `false` to silently exit without showing a message box |

---

### Window Config

#### `WindowConfig`

```dart
const WindowConfig(
  windowTitle: 'My Application',  // optional
)
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `windowTitle` | `String?` | No | `null` | Window title used to locate the original window. **Essential for system tray apps** where the window may not be immediately visible |

---

### Duplicate Check Config

#### `DuplicateCheckConfig`

```dart
const DuplicateCheckConfig(
  enableInDebugMode: true,  // optional
)
```

| Parameter | Type | Required | Default | Description |
|-----------|------|----------|---------|-------------|
| `enableInDebugMode` | `bool` | No | `false` | When `true`, performs the duplicate check even in debug mode. By default, the check is skipped in debug mode for a smoother development workflow |

---

## Advanced Example

A full-featured example using all available options, ideal for system tray applications.

```dart
final config = FlutterAloneConfig.forWindows(
  windowsConfig: CustomWindowsMutexConfig(
    customMutexName: 'MyProductionAppMutex',
  ),
  windowConfig: const WindowConfig(
    windowTitle: 'My Application',  // Needed to find the window when minimized to tray
  ),
  duplicateCheckConfig: const DuplicateCheckConfig(
    enableInDebugMode: true,  // Test duplicate detection during development
  ),
  messageConfig: const CustomMessageConfig(
    customTitle: 'Application Notice',
    customMessage: 'Another instance is already running. Check the system tray.',
    showMessageBox: true,
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

## Platform-Specific Setup

Some platforms require additional native-side setup. See the **[Platform Setup Guide](./PLATFORM_SETUP.md)** for details.

- **Windows**: Resolving `FindWindow()` API conflicts when using the `window_manager` package
- **macOS**: Handling app reactivation when the dock icon is clicked (critical for system tray apps)

## FAQ

### Q: Why do I need a different native window title when using `window_manager`?
A: The Windows `FindWindow()` API requires a unique native window title to locate the original window. The user only sees the final title set by `window_manager`.

### Q: What if I don't use `window_manager`?
A: No additional platform setup is needed. The plugin works out of the box.

### Q: The duplicate check doesn't work in debug mode.
A: By default, the check is skipped in debug mode. Set `DuplicateCheckConfig(enableInDebugMode: true)` to enable it.

### Q: Two different apps using flutter_alone conflict with each other.
A: Both `MacOSConfig` and `LinuxConfig` default to `.lockfile`. Use a unique `lockFileName` per app (e.g., `'com.example.myapp.lock'`).

## Contributing

Contributions are welcome! Please submit a pull request or create an [issue](https://github.com/kihyun1998/flutter_alone/issues).
