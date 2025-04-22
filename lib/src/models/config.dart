import 'message_config.dart';
import 'mutex_config.dart';

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

  /// Configuration for mutex naming
  final MutexConfig mutexConfig;

  /// Configuration for window management
  final WindowConfig windowConfig;

  /// Configuration for message display
  final MessageConfig messageConfig;

  /// Constructor
  const FlutterAloneConfig({
    this.duplicateCheckConfig = const DuplicateCheckConfig(),
    required this.mutexConfig,
    this.windowConfig = const WindowConfig(),
    required this.messageConfig,
  });

  @override
  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{};
    map.addAll(duplicateCheckConfig.toMap());
    map.addAll(mutexConfig.toMap());
    map.addAll(windowConfig.toMap());
    map.addAll(messageConfig.toMap());
    return map;
  }
}
