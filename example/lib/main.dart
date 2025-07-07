import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone_example/const.dart';
import 'package:path_provider/path_provider.dart';
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
    final config = FlutterAloneConfig.forWindows(
      windowsConfig: const DefaultWindowsMutexConfig(
        packageId: 'com.example.flutter_alone_example',
        appName: appTitle,
      ),
      windowConfig: const WindowConfig(
        windowTitle: appTitle,
      ),
      duplicateCheckConfig: const DuplicateCheckConfig(
        enableInDebugMode: true,
      ),
      messageConfig: const EnMessageConfig(),
    );
    if (!await FlutterAlone.instance.checkAndRun(config: config)) {
      exit(0);
    }
  } else if (Platform.isMacOS) {
    final tempDir = await getTemporaryDirectory();
    print(tempDir);
    final lockFilePath = '${tempDir.path}/flutter_alone_example.lock';

    final config = FlutterAloneConfig.forMacOS(
      macOSConfig: MacOSConfig(
        lockFilePath: lockFilePath,
      ),
      windowConfig: const WindowConfig(
        windowTitle: appTitle,
      ),
      duplicateCheckConfig: const DuplicateCheckConfig(
        enableInDebugMode: true,
      ),
      messageConfig: const EnMessageConfig(),
    );
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
        label: 'Reopen Window', // New menu item
        onClicked: (_) async {
          if (Platform.isMacOS) {
            await FlutterAlone.instance.debugActivateCurrentApp();
          } else {
            debugPrint('[Debug Check] This feature is for macOS only.');
          }
        },
      ),
      MenuItemLabel(
        label: 'Exit',
        onClicked: (_) async {
          await _systemTray.destroy();
          exit(0);
        },
      ),
      MenuSeparator(),
      MenuItemLabel(
        label: 'Debug: Check isRunning',
        onClicked: (_) async {
          if (Platform.isMacOS) {
            try {
              final tempDir = await getTemporaryDirectory();
              final lockFilePath =
                  '${tempDir.path}/flutter_alone_example.lock';
              final file = File(lockFilePath);
              if (await file.exists()) {
                final pidString = await file.readAsString();
                final pid = int.tryParse(pidString.trim());
                if (pid != null) {
                  final running =
                      await FlutterAlone.instance.debugIsRunning(pid: pid);
                  debugPrint(
                      '[Debug Check] PID $pid isRunning: $running');
                } else {
                  debugPrint('[Debug Check] Could not parse PID from lockfile.');
                }
              } else {
                debugPrint('[Debug Check] Lockfile not found.');
              }
            } catch (e) {
              debugPrint('[Debug Check] Error: $e');
            }
          } else {
            debugPrint('[Debug Check] This feature is for macOS only.');
          }
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
