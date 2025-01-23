/// Base abstract class for message configuration
abstract class MessageConfig {
  /// Whether to show message box
  final bool showMessageBox;

  /// Constructor
  const MessageConfig({
    this.showMessageBox = true,
  });

  /// Convert to map for MethodChannel communication
  Map<String, dynamic> toMap();
}

/// Korean message configuration
class KoMessageConfig extends MessageConfig {
  /// Constructor
  const KoMessageConfig({
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'ko',
        'showMessageBox': showMessageBox,
      };
}

/// English message configuration
class EnMessageConfig extends MessageConfig {
  /// Constructor
  const EnMessageConfig({
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'en',
        'showMessageBox': showMessageBox,
      };
}

/// Custom message configuration
///
/// Available placeholders in [messageTemplate]:
/// - {domain}: User domain
/// - {userName}: User name
///
/// Example:
/// ```dart
/// final config = CustomMessageConfig(
///   customTitle: "Running",
///   messageTemplate: "Program is running by {domain}\\{userName}",
/// );
/// ```
class CustomMessageConfig extends MessageConfig {
  /// Custom title for the message box
  final String customTitle;

  /// Message template string
  /// Can use {domain} and {userName} placeholders
  final String messageTemplate;

  /// Constructor
  const CustomMessageConfig({
    required this.customTitle,
    required this.messageTemplate,
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() => {
        'type': 'custom',
        'customTitle': customTitle,
        'messageTemplate': messageTemplate,
        'showMessageBox': showMessageBox,
      };
}
