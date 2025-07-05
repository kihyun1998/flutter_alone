import 'config.dart';

/// Base abstract class for Windows mutex configuration
abstract class WindowsMutexConfig implements AloneConfig {
  /// Constructor
  const WindowsMutexConfig();

  /// Get the complete mutex name to be used
  String getMutexName();
}

/// Configuration for mutex naming and identification using package ID and app name
class DefaultWindowsMutexConfig extends WindowsMutexConfig {
  /// Package identifier for mutex name generation
  /// Required for mutex name generation
  final String packageId;

  /// Application name for mutex name generation
  /// Required for mutex name generation
  final String appName;

  /// Optional suffix for mutex name
  final String? mutexSuffix;

  /// Constructor
  const DefaultWindowsMutexConfig({
    required this.packageId,
    required this.appName,
    this.mutexSuffix,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'mutexName': getMutexName(),
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
class CustomWindowsMutexConfig extends WindowsMutexConfig {
  /// Custom mutex name to use directly
  final String customMutexName;

  /// Constructor
  const CustomWindowsMutexConfig({
    required this.customMutexName,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      'mutexName': getMutexName(),
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