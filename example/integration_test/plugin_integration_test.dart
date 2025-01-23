import 'dart:io';

import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/exception.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('중복 실행 방지 플러그인 테스트', () {
    late FlutterAlone flutterAlone;

    setUp(() {
      flutterAlone = FlutterAlone.instance;
    });

    tearDown(() async {
      await flutterAlone.dispose();
    });

    testWidgets('첫 번째 실행은 성공해야 함', (tester) async {
      if (Platform.isWindows) {
        final result = await flutterAlone.checkAndRun();
        expect(result, isTrue);
      }
    });

    testWidgets('중복 실행 시도 시 false를 반환하고 메시지 박스가 표시되어야 함', (tester) async {
      if (Platform.isWindows) {
        // 첫 번째 실행
        await flutterAlone.checkAndRun();

        // 두 번째 실행 시도
        final result = await flutterAlone.checkAndRun();
        expect(result, isFalse);

        // MessageBox가 표시되었는지는 OS 레벨에서 직접 확인이 필요
        // 실제 사용자 시나리오에서 수동으로 테스트 필요
      }
    });

    testWidgets('리소스 정리 후 재실행이 가능해야 함', (tester) async {
      if (Platform.isWindows) {
        // 첫 번째 실행
        final firstRun = await flutterAlone.checkAndRun();
        expect(firstRun, isTrue);

        // 리소스 정리
        await flutterAlone.dispose();

        // 재실행
        final secondRun = await flutterAlone.checkAndRun();
        expect(secondRun, isTrue);
      }
    });

    testWidgets('예외 발생 시 AloneException이 throw되어야 함', (tester) async {
      if (Platform.isWindows) {
        // 잘못된 상태에서 dispose 호출
        await flutterAlone.dispose();
        await flutterAlone.dispose(); // 두 번째 dispose는 예외 발생

        expect(() async => await flutterAlone.checkAndRun(),
            throwsA(isA<AloneException>()));
      }
    });
  });
}
