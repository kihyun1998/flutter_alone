import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // How to use by specifying the package ID and app name
  if (!await FlutterAlone.instance.checkAndRun(
    packageId: 'com.example.myapp',
    appName: 'MyFlutterApp',
    mutexSuffix: 'production',
    messageConfig: CustomMessageConfig(
      customTitle: 'Example App',
      customMessage: 'Application is already running in another account',
      enableInDebugMode: true, // Enable duplicate check even in debug mode
    ),
  )) {
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
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Text(
                'The app ran normally.',
                style: TextStyle(fontSize: 18),
              ),
              SizedBox(height: 20),
              Text(
                'Prevent duplicate execution with custom mutex name:',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'packageId: com.example.myapp',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'appName: MyFlutterApp',
                style: TextStyle(fontSize: 14),
              ),
              Text(
                'suffix: production',
                style: TextStyle(fontSize: 14),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
