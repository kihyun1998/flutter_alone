import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MessageConfig Tests', () {
    test('Default configuration should be English', () {
      final config = MessageConfig();
      expect(config.type, MessageType.en);
      expect(config.showMessageBox, true);
      expect(config.customTitle, null);
      expect(config.customMessage, null);
    });

    test('Custom configuration should override defaults', () {
      final config = MessageConfig(
        type: MessageType.ko,
        showMessageBox: false,
        customTitle: 'Test Title',
        customMessage: 'Test Message',
      );
      expect(config.type, MessageType.ko);
      expect(config.showMessageBox, false);
      expect(config.customTitle, 'Test Title');
      expect(config.customMessage, 'Test Message');
    });

    test('copyWith should create new instance with specified changes', () {
      final config = MessageConfig();
      final newConfig = config.copyWith(
        type: MessageType.custom,
        showMessageBox: false,
      );
      expect(newConfig.type, MessageType.custom);
      expect(newConfig.showMessageBox, false);
      expect(newConfig.customTitle, null);
      expect(newConfig.customMessage, null);
    });
  });

  group('MessageType Tests', () {
    test('English messages should be formatted correctly', () {
      const type = MessageType.en;
      expect(
        type.getTitle(null),
        'Execution Error',
      );
      expect(
        type.getMessage('DOMAIN', 'USER', null),
        'Application is already running by another user.\nRunning user: DOMAIN\\USER',
      );
    });

    test('Korean messages should be formatted correctly', () {
      const type = MessageType.ko;
      expect(
        type.getTitle(null),
        '실행 오류',
      );
      expect(
        type.getMessage('DOMAIN', 'USER', null),
        '이미 다른 사용자가 앱을 실행중입니다.\n실행 중인 사용자: DOMAIN\\USER',
      );
    });

    test('Custom messages should use provided values', () {
      const type = MessageType.custom;
      expect(
        type.getTitle('Custom Title'),
        'Custom Title',
      );
      expect(
        type.getMessage('DOMAIN', 'USER', 'Custom Message'),
        'Custom Message',
      );
    });
  });
}
