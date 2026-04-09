import 'config.dart';

/// Base abstract class for message configuration
abstract class MessageConfig implements AloneConfig {
  /// Whether to show message box when a duplicate instance is detected
  final bool showMessageBox;

  const MessageConfig({
    this.showMessageBox = true,
  });

  /// Subclasses provide their type string ('ko', 'en', 'custom')
  String get typeString;

  @override
  Map<String, dynamic> toMap() {
    return {
      'type': typeString,
      'showMessageBox': showMessageBox,
    };
  }
}

/// Korean message configuration
class KoMessageConfig extends MessageConfig {
  const KoMessageConfig({
    super.showMessageBox,
  });

  @override
  String get typeString => 'ko';
}

/// English message configuration
class EnMessageConfig extends MessageConfig {
  const EnMessageConfig({
    super.showMessageBox,
  });

  @override
  String get typeString => 'en';
}

/// Custom message configuration
class CustomMessageConfig extends MessageConfig {
  /// Custom title for the message box
  final String customTitle;

  /// Message template string
  final String customMessage;

  const CustomMessageConfig({
    required this.customTitle,
    required this.customMessage,
    super.showMessageBox,
  });

  @override
  String get typeString => 'custom';

  @override
  Map<String, dynamic> toMap() {
    return {
      ...super.toMap(),
      'customTitle': customTitle,
      'customMessage': customMessage,
    };
  }
}
