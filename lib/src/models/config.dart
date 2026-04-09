import 'dart:io' show Platform;

import 'linux_config.dart';
import 'macos_config.dart';
import 'message_config.dart';
import 'windows_config.dart';

/// Base configuration interface
abstract class AloneConfig {
  /// Convert to map for MethodChannel communication.
  /// All returned values must be non-null.
  Map<String, dynamic> toMap();
}

/// Configuration for duplicate execution check
class DuplicateCheckConfig implements AloneConfig {
  /// Whether to enable duplicate check in debug mode.
  /// Defaults to false.
  final bool enableInDebugMode;

  const DuplicateCheckConfig({
    this.enableInDebugMode = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'enableInDebugMode': enableInDebugMode,
    };
  }
}

/// Configuration for window management
class WindowConfig implements AloneConfig {
  /// Window title for window identification
  final String? windowTitle;

  const WindowConfig({
    this.windowTitle,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    if (windowTitle != null) {
      map['windowTitle'] = windowTitle;
    }
    return map;
  }
}

/// Combined configuration for flutter_alone plugin.
///
/// Instances must be created via the platform-specific factory constructors:
/// - [FlutterAloneConfig.forWindows] for Windows
/// - [FlutterAloneConfig.forMacOS] for macOS
/// - [FlutterAloneConfig.forLinux] for Linux
///
/// This ensures the correct platform config is paired with the runtime platform.
class FlutterAloneConfig implements AloneConfig {
  final DuplicateCheckConfig duplicateCheckConfig;
  final WindowsMutexConfig? windowsConfig;
  final MacOSConfig? macOSConfig;
  final LinuxConfig? linuxConfig;
  final WindowConfig windowConfig;
  final MessageConfig messageConfig;

  const FlutterAloneConfig._({
    this.duplicateCheckConfig = const DuplicateCheckConfig(),
    this.windowsConfig,
    this.macOSConfig,
    this.linuxConfig,
    this.windowConfig = const WindowConfig(),
    required this.messageConfig,
  });

  /// Factory constructor for Windows with custom settings
  factory FlutterAloneConfig.forWindows({
    DuplicateCheckConfig duplicateCheckConfig = const DuplicateCheckConfig(),
    required WindowsMutexConfig windowsConfig,
    WindowConfig windowConfig = const WindowConfig(),
    required MessageConfig messageConfig,
  }) {
    return FlutterAloneConfig._(
      duplicateCheckConfig: duplicateCheckConfig,
      windowsConfig: windowsConfig,
      windowConfig: windowConfig,
      messageConfig: messageConfig,
    );
  }

  /// Factory constructor for macOS with custom settings
  factory FlutterAloneConfig.forMacOS({
    DuplicateCheckConfig duplicateCheckConfig = const DuplicateCheckConfig(),
    required MacOSConfig macOSConfig,
    WindowConfig windowConfig = const WindowConfig(),
    required MessageConfig messageConfig,
  }) {
    return FlutterAloneConfig._(
      duplicateCheckConfig: duplicateCheckConfig,
      macOSConfig: macOSConfig,
      windowConfig: windowConfig,
      messageConfig: messageConfig,
    );
  }

  /// Factory constructor for Linux with custom settings
  factory FlutterAloneConfig.forLinux({
    DuplicateCheckConfig duplicateCheckConfig = const DuplicateCheckConfig(),
    required LinuxConfig linuxConfig,
    WindowConfig windowConfig = const WindowConfig(),
    required MessageConfig messageConfig,
  }) {
    return FlutterAloneConfig._(
      duplicateCheckConfig: duplicateCheckConfig,
      linuxConfig: linuxConfig,
      windowConfig: windowConfig,
      messageConfig: messageConfig,
    );
  }

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map.addAll(duplicateCheckConfig.toMap());

    if (Platform.isWindows) {
      if (windowsConfig == null) {
        throw StateError('FlutterAloneConfig.forWindows must be used on Windows');
      }
      map.addAll(windowsConfig!.toMap());
    } else if (Platform.isMacOS) {
      if (macOSConfig == null) {
        throw StateError('FlutterAloneConfig.forMacOS must be used on macOS');
      }
      map.addAll(macOSConfig!.toMap());
    } else if (Platform.isLinux) {
      if (linuxConfig == null) {
        throw StateError('FlutterAloneConfig.forLinux must be used on Linux');
      }
      map.addAll(linuxConfig!.toMap());
    }

    map.addAll(windowConfig.toMap());
    map.addAll(messageConfig.toMap());
    return map;
  }
}
