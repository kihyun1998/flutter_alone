import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  debugPrint('[DEBUG] main 함수 시작');

  WidgetsFlutterBinding.ensureInitialized();
  debugPrint('[DEBUG] FlutterAlone.checkAndRun 호출 전');
  final messageConfig = CustomMessageConfig(
    customTitle: 'Example App',
    messageTemplate: 'Application is already running by {domain}\\{userName}',
  );

  if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
    debugPrint('[DEBUG] 중복 실행 감지, 앱 종료');
    exit(0);
  }
  debugPrint('[DEBUG] 정상 실행, 앱 시작');
  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void dispose() {
    FlutterAlone.instance.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Alone Example'),
        ),
        body: const Center(
          child:
              Text('The app ran normally with custom message configuration.'),
        ),
      ),
    );
  }
}
