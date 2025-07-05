import 'dart:io';

import 'package:flutter/material.dart';
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
    await windowManager.show();
    await windowManager.focus();
  });

  if (Platform.isWindows) {
    // Example 1: Default configuration using fromAppId (Recommended)
    // final defaultConfig = FlutterAloneConfig.fromAppId(
    //   appId: 'com.example.myapp',
    //   appName: 'MyFlutterApp',
    //   windowConfig: const WindowConfig(
    //     windowTitle: 'Tray App Example',
    //   ),
    //   duplicateCheckConfig: const DuplicateCheckConfig(
    //     enableInDebugMode: true,
    //   ),
    //   messageConfig: const CustomMessageConfig(
    //     customTitle: 'Example App',
    //     customMessage: 'Application is already running in another account',
    //     showMessageBox: true,
    //   ),
    // );

    // Example 2: Custom configuration for Windows
    final customConfig = FlutterAloneConfig.forWindows(
      // Custom mutex name for Windows
      windowsConfig: const CustomWindowsMutexConfig(
        customMutexName: 'MyUniqueApplicationMutex',
      ),

      // Window configuration
      windowConfig: const WindowConfig(
        windowTitle: appTitle,
      ),

      // Debug mode setting
      duplicateCheckConfig: const DuplicateCheckConfig(
        enableInDebugMode: true,
      ),

      // Default English messages
      messageConfig: const EnMessageConfig(),
    );

    final config = customConfig; // or use defaultConfig

    if (!await FlutterAlone.instance.checkAndRun(config: config)) {
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

  @override
  void initState() {
    super.initState();
    _initSystemTray();
  }

  @override
  void dispose() {
    FlutterAlone.instance.dispose();
    super.dispose();
  }

  Future<void> _initSystemTray() async {
    String path =
        Platform.isWindows ? 'assets/app_icon.ico' : 'assets/app_icon_64.png';
    if (!await File(path).exists()) {
      debugPrint("Icon file not found: $path");
    }

    await _systemTray.initSystemTray(iconPath: path);

    _systemTray.setTitle('Flutter alone example');
    _systemTray.setToolTip('Flutter alone example');

    final Menu menu = Menu();
    await menu.buildFrom([
      MenuItemLabel(
        label: 'Open',
        onClicked: (_) async {
          await windowManager.show();
          await windowManager.focus();
        },
      ),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (_) async {
          await _systemTray.destroy();
          exit(0);
        },
      ),
    ]);

    await _systemTray.setContextMenu(menu);

    _systemTray.registerSystemTrayEventHandler(
      (eventName) async {
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
