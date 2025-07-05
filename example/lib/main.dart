import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // Add this import
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone_example/const.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 800),
    center: true,
    title: appTitle,
  );

  windowManager.waitUntilReadyToShow(windowOptions, () async {
    debugPrint('main: Initial window show and focus');
    await windowManager.show();
    await windowManager.focus();
  });

  // Platform-specific checkAndRun logic
  if (Platform.isWindows || Platform.isMacOS) {
    final customConfig = FlutterAloneConfig(
      mutexConfig: const CustomMutexConfig(
        customMutexName: 'MyUniqueApplicationMutex',
      ),
      windowConfig: const WindowConfig(
        windowTitle: appTitle,
      ),
      duplicateCheckConfig: const DuplicateCheckConfig(
        enableInDebugMode: true,
      ),
      messageConfig: const EnMessageConfig(),
    );

    final config = customConfig;

    debugPrint('main: Calling checkAndRun');
    if (!await FlutterAlone.instance.checkAndRun(
      config: config,
      onDuplicateLaunch: () async {
        debugPrint('main: onDuplicateLaunch callback invoked');
        await windowManager.show();
        await windowManager.focus();
      },
    )) {
      debugPrint('main: Duplicate instance detected, exiting.');
      exit(0);
    }
  }

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final SystemTray _systemTray = SystemTray();
  static const MethodChannel _channel = MethodChannel('flutter_alone');

  @override
  void initState() {
    super.initState();
    debugPrint('MyAppState: initState called');
    _initSystemTray();
  }

  @override
  void dispose() {
    debugPrint('MyAppState: dispose called');
    FlutterAlone.instance.dispose();
    super.dispose();
  }

  Future<void> _initSystemTray() async {
    debugPrint('MyAppState: _initSystemTray called');
    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon_64.png';
    if (!await File(path).exists()) {
      debugPrint("MyAppState: Icon file not found: (path)");
    }

    await _systemTray.initSystemTray(iconPath: path);

    _systemTray.setTitle('Flutter alone example');
    _systemTray.setToolTip('Flutter alone example');

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Open',
        onClicked: (_) async {
          debugPrint('MyAppState: System tray menu - Open clicked');
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (_) async {
          debugPrint('MyAppState: System tray menu - Exit clicked');
          await _systemTray.destroy();
          exit(0);
        },
      ),
    ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler(
      (eventName) async {
        debugPrint('MyAppState: System tray event received: (eventName)');
        if (eventName == kSystemTrayEventClick) {
          if (Platform.isWindows) {
            await windowManager.show();
            await windowManager.focus();
          } else {
            await _systemTray.popUpContextMenu();
          }
        } else if (eventName == kSystemTrayEventRightClick) {
          if (Platform.isWindows) {
            await _systemTray.popUpContextMenu();
          } else {
            await windowManager.show();
            await windowManager.focus();
          }
        }
      },
    );
  }

  Future<void> hideWindow() async {
    debugPrint('MyAppState: hideWindow called');
    await windowManager.hide();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: appTitle,
      home: Scaffold(
        appBar: AppBar(
          title: const Text(appTitle),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                'The app ran normally.',
                style: TextStyle(fontSize: 18),
              ),
              const SizedBox(height: 20),
              const Text(
                'Prevent duplicate execution with custom mutex:',
                style: TextStyle(fontSize: 14),
              ),
              const Text(
                'Using CustomMutexConfig with name: MyUniqueApplicationMutex',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 20),
              ElevatedButton(
                onPressed: hideWindow,
                child: const Text('Hide window'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
