// example/lib/main.dart
import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // final messageConfig = MessageConfig(
  //   type: MessageType.custom,
  //   customTitle: 'Example App',
  //   customMessage: 'App is already running! ( 이미 실행 중이에요. )',
  //   showMessageBox: true,
  // );

  final messageConfig = MessageConfig(
    type: MessageType.en,
    customTitle: 'Example App',
    customMessage: 'App is already running! ( 이미 실행 중이에요. )',
    showMessageBox: true,
  );

  if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
    return;
  }

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
