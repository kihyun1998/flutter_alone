import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('Test multiple instances', (WidgetTester tester) async {
    final FlutterAlone instance1 = FlutterAlone.instance;

    // 첫 번째 인스턴스 실행
    final bool firstRun = await instance1.checkAndRun();
    expect(firstRun, true, reason: '첫 번째 인스턴스는 실행될 수 있어야 함');

    // 동일한 프로세스 내에서 두 번째 체크
    final bool secondRun = await instance1.checkAndRun();
    expect(secondRun, false, reason: '두 번째 체크는 실패해야 함');

    // 리소스 정리
    await instance1.dispose();
  });

  testWidgets('Can dispose resources', (WidgetTester tester) async {
    final FlutterAlone instance = FlutterAlone.instance;
    await expectLater(instance.dispose(), completes);
  });
}
