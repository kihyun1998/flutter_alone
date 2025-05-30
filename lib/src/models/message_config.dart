// ignore_for_file: public_member_api_docs, sort_constructors_first

import 'config.dart';

enum MessageConfigJsonKey {
  type,
  showMessageBox,
  customTitle,
  customMessage,
  ;

  String get key => toString().split('.').last;
}

/// Base abstract class for message configuration
abstract class MessageConfig implements AloneConfig {
  /// Whether to show message box
  final bool showMessageBox;

  /// Constructor
  const MessageConfig({
    this.showMessageBox = true,
  });
}

/// Korean message configuration
class KoMessageConfig extends MessageConfig {
  /// Constructor
  const KoMessageConfig({
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      MessageConfigJsonKey.type.key: 'ko',
      MessageConfigJsonKey.showMessageBox.key: showMessageBox,
    };
  }
}

/// English message configuration
class EnMessageConfig extends MessageConfig {
  /// Constructor
  const EnMessageConfig({
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      MessageConfigJsonKey.type.key: 'en',
      MessageConfigJsonKey.showMessageBox.key: showMessageBox,
    };
  }
}

/// Custom message configuration
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
  });

  @override
  Map<String, dynamic> toMap() {
    return {
      MessageConfigJsonKey.type.key: 'custom',
      MessageConfigJsonKey.customTitle.key: customTitle,
      MessageConfigJsonKey.customMessage.key: customMessage,
      MessageConfigJsonKey.showMessageBox.key: showMessageBox,
    };
  }
}
