import 'config.dart';

/// Base abstract class for Windows mutex configuration
abstract class WindowsMutexConfig implements AloneConfig {
  static const String _globalPrefix = r'Global\';
  static const String _mutexNameKey = 'mutexName';

  const WindowsMutexConfig();

  /// Get the complete mutex name to be used
  String getMutexName();

  @override
  Map<String, dynamic> toMap() {
    return {
      _mutexNameKey: getMutexName(),
    };
  }
}

/// Configuration for mutex naming using package ID and app name
class DefaultWindowsMutexConfig extends WindowsMutexConfig {
  /// Package identifier for mutex name generation
  final String packageId;

  /// Application name for mutex name generation
  final String appName;

  /// Optional suffix for mutex name
  final String? mutexSuffix;

  const DefaultWindowsMutexConfig({
    required this.packageId,
    required this.appName,
    this.mutexSuffix,
  });

  @override
  String getMutexName() {
    final String baseName =
        '${WindowsMutexConfig._globalPrefix}${packageId}_$appName';
    return mutexSuffix != null ? '${baseName}_$mutexSuffix' : baseName;
  }
}

/// Configuration for mutex using a custom name
class CustomWindowsMutexConfig extends WindowsMutexConfig {
  /// Custom mutex name to use directly
  final String customMutexName;

  CustomWindowsMutexConfig({
    required this.customMutexName,
  }) {
    if (customMutexName.isEmpty) {
      throw ArgumentError.value(
        customMutexName,
        'customMutexName',
        'Must not be empty',
      );
    }
  }

  @override
  String getMutexName() {
    if (customMutexName.startsWith(WindowsMutexConfig._globalPrefix)) {
      return customMutexName;
    }
    return '${WindowsMutexConfig._globalPrefix}$customMutexName';
  }
}
