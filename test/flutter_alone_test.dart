import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Message Configuration Tests', () {
    test('Korean message configuration should be created correctly', () {
      const config = KoMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'ko');
      expect(map['showMessageBox'], true);
    });

    test('English message configuration should be created correctly', () {
      const config = EnMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('Custom message configuration should handle placeholders', () {
      const config = CustomMessageConfig(
          customTitle: 'Test Title',
          messageTemplate: 'Running as {domain}\\{userName}');
      final map = config.toMap();

      expect(map['type'], 'custom');
      expect(map['customTitle'], 'Test Title');
      expect(map['messageTemplate'], 'Running as {domain}\\{userName}');
      expect(map['showMessageBox'], true);
    });

    test('Message configurations should respect showMessageBox parameter', () {
      const config = CustomMessageConfig(
          customTitle: 'Title',
          messageTemplate: 'Message',
          showMessageBox: false);
      final map = config.toMap();

      expect(map['showMessageBox'], false);
    });
  });
}
