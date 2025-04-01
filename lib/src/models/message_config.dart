// ignore_for_file: public_member_api_docs, sort_constructors_first

enum MessageConfigJsonKey {
  type,
  showMessageBox,
  customTitle,
  customMessage,
  enableInDebugMode,
  packageId,
  appName,
  mutexSuffix,
  windowTitle,
  ;

  String get key => toString().split('.').last;
}

/// Base abstract class for message configuration
abstract class MessageConfig {
  /// Whether to show message box
  final bool showMessageBox;

  /// Whether to enable duplicate check in debug mode
  /// Defaults to false
  final bool enableInDebugMode;

  /// Package identifier for mutex name generation
  /// Required for mutex name generation
  final String packageId;

  /// Application name for mutex name generation
  /// Required for mutex name generation
  final String appName;

  /// Optional suffix for mutex name
  final String? mutexSuffix;

  /// window title
  final String? windowTitle;

  /// Constructor
  const MessageConfig({
    this.showMessageBox = true,
    this.enableInDebugMode = false,
    required this.packageId,
    required this.appName,
    this.mutexSuffix,
    this.windowTitle,
  });

  /// Convert to map for MethodChannel communication
  Map<String, dynamic> toMap();
}

/// Korean message configuration
class KoMessageConfig extends MessageConfig {
  /// Constructor
  const KoMessageConfig({
    super.showMessageBox,
    super.enableInDebugMode,
    required super.packageId,
    required super.appName,
    super.mutexSuffix,
    super.windowTitle,
  });

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      MessageConfigJsonKey.type.key: 'ko',
      MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      MessageConfigJsonKey.enableInDebugMode.key: enableInDebugMode,
      MessageConfigJsonKey.packageId.key: packageId,
      MessageConfigJsonKey.appName.key: appName,
      MessageConfigJsonKey.mutexSuffix.key: mutexSuffix,
      MessageConfigJsonKey.windowTitle.key: windowTitle,
    };

    return map;
  }
}

/// English message configuration
class EnMessageConfig extends MessageConfig {
  /// Constructor
  const EnMessageConfig({
    super.showMessageBox,
    super.enableInDebugMode,
    required super.packageId,
    required super.appName,
    super.mutexSuffix,
    super.windowTitle,
  });

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      MessageConfigJsonKey.type.key: 'en',
      MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      MessageConfigJsonKey.enableInDebugMode.key: enableInDebugMode,
      MessageConfigJsonKey.packageId.key: packageId,
      MessageConfigJsonKey.appName.key: appName,
      MessageConfigJsonKey.mutexSuffix.key: mutexSuffix,
      MessageConfigJsonKey.windowTitle.key: windowTitle,
    };

    return map;
  }
}

/// Custom message configuration
///
/// Example:
/// ```dart
/// final config = CustomMessageConfig(
///   customTitle: "Notice",
///   customMessage: "Application is already running in another account.",
/// );
/// ```
class CustomMessageConfig extends MessageConfig {
  /// Custom title for the message box
  final String customTitle;

  /// Message template string
  final String customMessage;

  /// Constructor
  const CustomMessageConfig({
    required this.customTitle,
    required this.customMessage,
    super.showMessageBox,
    super.enableInDebugMode,
    required super.packageId,
    required super.appName,
    super.mutexSuffix,
    super.windowTitle,
  });

  @override
  Map<String, dynamic> toMap() {
    final Map<String, dynamic> map = {
      MessageConfigJsonKey.type.key: 'custom',
      MessageConfigJsonKey.customTitle.key: customTitle,
      MessageConfigJsonKey.customMessage.key: customMessage,
      MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      MessageConfigJsonKey.enableInDebugMode.key: enableInDebugMode,
      MessageConfigJsonKey.packageId.key: packageId,
      MessageConfigJsonKey.appName.key: appName,
      MessageConfigJsonKey.mutexSuffix.key: mutexSuffix,
      MessageConfigJsonKey.windowTitle.key: windowTitle,
    };

    return map;
  }
}
