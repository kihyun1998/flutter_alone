# Advanced Configuration Guide

This guide provides detailed configuration options for the `flutter_alone` package.

## Configuration Options

You can customize the plugin's behavior by combining different configuration options.

- **`windowsConfig`**:
  - `DefaultWindowsMutexConfig`: Automatically generates a mutex ID from your app's package ID and name.
  - `CustomWindowsMutexConfig`: Lets you specify a unique mutex ID directly.
- **`macOSConfig`**:
  - `MacOSConfig`: Specify a custom lock file name.
- **`windowConfig`**:
  - `WindowConfig`: Set a `windowTitle` to help find the original window, especially for apps that run in the system tray.
- **`messageConfig`**:
  - `EnMessageConfig` / `KoMessageConfig`: Use default English or Korean messages.
  - `CustomMessageConfig`: Provide your own title and message for the alert dialog.
- **`duplicateCheckConfig`**:
  - `DuplicateCheckConfig`: Use `enableInDebugMode: true` to test the duplicate check logic during development.

## Comprehensive Example (Windows)

Here’s an example that combines several custom configurations for a Windows application.

```dart
final config = FlutterAloneConfig.forWindows(
  // Use a custom mutex name
  windowsConfig: const CustomWindowsMutexConfig(
    customMutexName: 'MyUniqueAppMutexForProduction',
  ),

  // Help find the window if it's in the system tray
  windowConfig: const WindowConfig(
    windowTitle: 'My Application Window',
  ),

  // Force duplicate checks even in debug mode
  duplicateCheckConfig: const DuplicateCheckConfig(
    enableInDebugMode: true,
  ),

  // Show a custom message
  messageConfig: const CustomMessageConfig(
    customTitle: 'Application Notice',
    customMessage: 'Another instance of My App is already running.',
    showMessageBox: true,
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```

## Comprehensive Example (macOS)

Here’s an example that combines several custom configurations for a macOS application.

```dart
final config = FlutterAloneConfig.forMacOS(
  // Specify a custom lock file name for macOS
  macOSConfig: const MacOSConfig(
    lockFileName: 'my_unique_app.lock',
  ),

  // Help find the window if it's in the system tray (if applicable for macOS)
  windowConfig: const WindowConfig(
    windowTitle: 'My Application Window',
  ),

  // Force duplicate checks even in debug mode
  duplicateCheckConfig: const DuplicateCheckConfig(
    enableInDebugMode: true,
  ),

  // Show a custom message
  messageConfig: const CustomMessageConfig(
    customTitle: 'Application Notice',
    customMessage: 'Another instance of My App is already running.',
    showMessageBox: true,
  ),
);

if (!await FlutterAlone.instance.checkAndRun(config: config)) {
  exit(0);
}
```
