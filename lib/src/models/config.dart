import 'message_config.dart';
import 'dart:io' show Platform;

import 'message_config.dart';
import 'windows_config.dart';
import 'macos_config.dart';

enum ConfigJsonKey {
  enableInDebugMode,

  windowTitle,
  ;

  String get key => toString().split('.').last;
}

/// Base configuration interface
abstract class AloneConfig {
  /// Convert to map for MethodChannel communication
  Map<String, dynamic> toMap();
}

/// Configuration for duplicate execution check
class DuplicateCheckConfig implements AloneConfig {
  /// Whether to enable duplicate check in debug mode
  /// Defaults to false
  final bool enableInDebugMode;

  /// Constructor
  const DuplicateCheckConfig({
    this.enableInDebugMode = false,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      ConfigJsonKey.enableInDebugMode.key: enableInDebugMode,
    };
  }
}

/// Configuration for window management
class WindowConfig implements AloneConfig {
  /// Window title for window identification
  final String? windowTitle;

  /// Constructor
  const WindowConfig({
    this.windowTitle,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};

    if (windowTitle != null) {
      map[ConfigJsonKey.windowTitle.key] = windowTitle;
    }

    return map;
  }
}

/// Combined configuration for flutter_alone plugin
class FlutterAloneConfig implements AloneConfig {
  /// Configuration for duplicate check behavior
  final DuplicateCheckConfig duplicateCheckConfig;

  /// Windows-specific configuration for mutex naming
  final WindowsMutexConfig? windowsConfig;

  /// macOS-specific configuration for lock file
  final MacOSLockConfig? macOSConfig;

  /// Configuration for window management
  final WindowConfig windowConfig;

  /// Configuration for message display
  final MessageConfig messageConfig;

  /// Private constructor
  const FlutterAloneConfig._({
    this.duplicateCheckConfig = const DuplicateCheckConfig(),
    this.windowsConfig,
    this.macOSConfig,
    this.windowConfig = const WindowConfig(),
    required this.messageConfig,
  });

  /// Default factory constructor
  ///
  /// Creates a configuration with default settings for the current platform.
  /// Requires [appId] for generating unique identifiers.
  factory FlutterAloneConfig.fromAppId({
    required String appId,
    String? appName,
    DuplicateCheckConfig duplicateCheckConfig = const DuplicateCheckConfig(),
    WindowConfig windowConfig = const WindowConfig(),
    required MessageConfig messageConfig,
  }) {
    WindowsMutexConfig? winConfig;
    MacOSLockConfig? macConfig;

    if (Platform.isWindows) {
      winConfig = DefaultWindowsMutexConfig(
        packageId: appId,
        appName: appName ?? appId,
      );
    } else if (Platform.isMacOS) {
      macConfig = DefaultMacOSLockConfig(
        appName: appName ?? appId,
      );
    }

    return FlutterAloneConfig._(
      duplicateCheckConfig: duplicateCheckConfig,
      windowsConfig: winConfig,
      macOSConfig: macConfig,
      windowConfig: windowConfig,
      messageConfig: messageConfig,
    );
  }

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
    required MacOSLockConfig macOSConfig,
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

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map.addAll(duplicateCheckConfig.toMap());
    if (Platform.isWindows && windowsConfig != null) {
      map.addAll(windowsConfig!.toMap());
    } else if (Platform.isMacOS && macOSConfig != null) {
      map.addAll(macOSConfig!.toMap());
    }
    map.addAll(windowConfig.toMap());
    map.addAll(messageConfig.toMap());
    return map;
  }
}
