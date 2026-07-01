import 'config.dart';

/// Base abstract class for Windows mutex configuration
abstract class WindowsMutexConfig implements AloneConfig {
  static const String _globalPrefix = r'Global\';
  static const String _mutexNameKey = 'mutexName';

  const WindowsMutexConfig();

  /// Maximum mutex name length. Mirrors the native `kMaxMutexNameLength`
  /// (an application-level policy, not a kernel limit).
  static const int maxMutexNameLength = 260;

  /// Get the complete mutex name to be used
  String getMutexName();

  /// Validates a fully-qualified mutex [name] against the constraints the native
  /// Windows layer enforces, throwing [ArgumentError] for a bad name instead of
  /// letting the native side reject it silently (which `checkAndRun` reports as
  /// "already running", so the app exits). Returns [name] unchanged when valid.
  static String validateMutexName(String name) {
    if (name.length > maxMutexNameLength) {
      throw ArgumentError.value(
        name,
        'mutexName',
        'Must be at most $maxMutexNameLength characters',
      );
    }
    // A single Global\ prefix is expected; any further backslash is rejected by
    // the native layer. _globalPrefix is 7 chars, so search from index 7.
    if (name.indexOf(r'\', _globalPrefix.length) != -1) {
      throw ArgumentError.value(
        name,
        'mutexName',
        r'Must not contain a backslash after the Global\ prefix',
      );
    }
    return name;
  }

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
    final String name =
        mutexSuffix != null ? '${baseName}_$mutexSuffix' : baseName;
    return WindowsMutexConfig.validateMutexName(name);
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
    final String name =
        customMutexName.startsWith(WindowsMutexConfig._globalPrefix)
            ? customMutexName
            : '${WindowsMutexConfig._globalPrefix}$customMutexName';
    return WindowsMutexConfig.validateMutexName(name);
  }
}
