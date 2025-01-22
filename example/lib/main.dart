import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  // Flutter 바인딩 초기화
  WidgetsFlutterBinding.ensureInitialized();

  // FlutterAlone 인스턴스 가져오기
  final aloneInstance = FlutterAlone.instance;

  try {
    // 중복 실행 체크
    final canRun = await aloneInstance.checkAndRun();
    if (!canRun) {
      print('앱이 이미 실행 중입니다.');
      exit(0); // 앱 종료
    }

    // 앱 실행
    runApp(const MyApp());
  } catch (e) {
    print('오류 발생: $e');
    exit(1);
  }
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Alone Example'),
        ),
        body: const Center(
          child: Text('앱이 정상적으로 실행되었습니다.'),
        ),
      ),
    );
  }
}
