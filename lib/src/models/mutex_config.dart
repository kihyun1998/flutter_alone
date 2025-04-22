import 'config.dart';

enum MutexConfigJsonKey {
  enableInDebugMode,
  packageId,
  appName,
  mutexSuffix,
  windowTitle,
  mutexName,
  ;

  String get key => toString().split('.').last;
}

/// Base abstract class for mutex configuration
abstract class MutexConfig implements AloneConfig {
  /// Constructor
  const MutexConfig();

  /// Get the complete mutex name to be used
  String getMutexName();
}

/// Configuration for mutex naming and identification using package ID and app name
class DefaultMutexConfig extends MutexConfig {
  /// Package identifier for mutex name generation
  /// Required for mutex name generation
  final String packageId;

  /// Application name for mutex name generation
  /// Required for mutex name generation
  final String appName;

  /// Optional suffix for mutex name
  final String? mutexSuffix;

  /// Constructor
  const DefaultMutexConfig({
    required this.packageId,
    required this.appName,
    this.mutexSuffix,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      MutexConfigJsonKey.mutexName.key: getMutexName(),
    };
  }

  @override
  String getMutexName() {
    // Create mutex name in format "Global\packageId_appName_suffix"
    final String baseName = 'Global\\${packageId}_$appName';
    return mutexSuffix != null ? '${baseName}_$mutexSuffix' : baseName;
  }
}

/// Configuration for mutex using a custom name
class CustomMutexConfig extends MutexConfig {
  /// Custom mutex name to use directly
  final String customMutexName;

  /// Constructor
  const CustomMutexConfig({
    required this.customMutexName,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      MutexConfigJsonKey.mutexName.key: getMutexName(),
    };
  }

  @override
  String getMutexName() {
    // Create mutex name in format "Global\customName"
    // If the name already starts with "Global\", use as is
    if (customMutexName.startsWith('Global\\')) {
      return customMutexName;
    }
    return 'Global\\$customMutexName';
  }
}
