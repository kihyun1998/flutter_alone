import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  /// Example with debug mode settings
  final messageConfig = CustomMessageConfig(
    customTitle: 'Example App',
    customMessage: 'Application is already running in another account',
    enableInDebugMode: true, // Enable duplicate check even in debug mode
  );

  // Also can use predefined configurations:
  // final messageConfig = EnMessageConfig(); // English messages
  // final messageConfig = KoMessageConfig(); // Korean messages

  if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
    exit(0);
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
