import 'dart:io' show Platform;

import '../method_channel_keys.dart';
import 'linux_config.dart';
import 'macos_config.dart';
import 'message_config.dart';
import 'windows_config.dart';

/// The desktop platform a [FlutterAloneConfig] is serialized for.
///
/// Passed to [FlutterAloneConfig.toMapFor] so serialization does not depend on
/// the runtime OS and can be unit-tested for every platform on any OS.
enum AlonePlatform { windows, macOS, linux, other }

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
      MethodChannelKeys.enableInDebugMode: enableInDebugMode,
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
      map[MethodChannelKeys.windowTitle] = windowTitle;
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
  Map<String, dynamic> toMap() => toMapFor(_currentPlatform());

  /// Serializes this config for an explicit [platform].
  ///
  /// Unlike [toMap], this does not read the runtime OS, so every platform
  /// branch is testable on any OS. [toMap] delegates here with the current
  /// platform. Throws [StateError] if the config lacks the platform-specific
  /// section required by [platform] (e.g. a config built with
  /// [FlutterAloneConfig.forMacOS] serialized for [AlonePlatform.windows]).
  Map<String, dynamic> toMapFor(AlonePlatform platform) {
    final map = <String, dynamic>{};
    map.addAll(duplicateCheckConfig.toMap());

    switch (platform) {
      case AlonePlatform.windows:
        if (windowsConfig == null) {
          throw StateError(
              'FlutterAloneConfig.forWindows must be used on Windows');
        }
        map.addAll(windowsConfig!.toMap());
        break;
      case AlonePlatform.macOS:
        if (macOSConfig == null) {
          throw StateError('FlutterAloneConfig.forMacOS must be used on macOS');
        }
        map.addAll(macOSConfig!.toMap());
        break;
      case AlonePlatform.linux:
        if (linuxConfig == null) {
          throw StateError('FlutterAloneConfig.forLinux must be used on Linux');
        }
        map.addAll(linuxConfig!.toMap());
        break;
      case AlonePlatform.other:
        break;
    }

    map.addAll(windowConfig.toMap());
    map.addAll(messageConfig.toMap());
    return map;
  }

  static AlonePlatform _currentPlatform() {
    if (Platform.isWindows) return AlonePlatform.windows;
    if (Platform.isMacOS) return AlonePlatform.macOS;
    if (Platform.isLinux) return AlonePlatform.linux;
    return AlonePlatform.other;
  }
}
