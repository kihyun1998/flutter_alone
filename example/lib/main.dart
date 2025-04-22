import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:system_tray/system_tray.dart';
import 'package:window_manager/window_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await windowManager.ensureInitialized();

  WindowOptions windowOptions = const WindowOptions(
    size: Size(500, 800),
    center: true,
    title: 'Tray App Example',
  );
  windowManager.waitUntilReadyToShow(windowOptions, () async {
    await windowManager.show();
    await windowManager.focus();
  });

  if (Platform.isWindows) {
    // 사용 예제 1: DefaultMutexConfig (기존 방식)
    final defaultConfig = FlutterAloneConfig(
      // 기존 방식의 뮤텍스 설정 - packageId와 appName 사용
      mutexConfig: const DefaultMutexConfig(
        packageId: 'com.example.myapp',
        appName: 'MyFlutterApp',
        mutexSuffix: 'production',
      ),

      // 창 관리 설정
      windowConfig: const WindowConfig(
        windowTitle: 'Tray App Example',
      ),

      // 디버그 모드 설정
      duplicateCheckConfig: const DuplicateCheckConfig(
        enableInDebugMode: true, // 디버그 모드에서도 중복 실행 검사 활성화
      ),

      // 메시지 설정
      messageConfig: const CustomMessageConfig(
        customTitle: 'Example App',
        customMessage: 'Application is already running in another account',
        showMessageBox: true,
      ),
    );

    // 사용 예제 2: CustomMutexConfig (새로운 방식)
    final customConfig = FlutterAloneConfig(
      // 새로운 방식의 뮤텍스 설정 - 사용자 정의 뮤텍스 이름 직접 사용
      mutexConfig: const CustomMutexConfig(
        customMutexName: 'MyUniqueApplicationMutex',
      ),

      // 창 관리 설정
      windowConfig: const WindowConfig(
        windowTitle: 'Tray App Example',
      ),

      // 디버그 모드 설정
      duplicateCheckConfig: const DuplicateCheckConfig(
        enableInDebugMode: true,
      ),

      // 메시지 설정
      messageConfig: const EnMessageConfig(),
    );

    // 사용할 구성 선택
    final config = customConfig; // 또는 defaultConfig

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
      debugPrint("icon file not found: $path");
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
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Flutter Alone Example'),
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
