# flutter_alone
## Project Structure

```
flutter_alone/
├── example/
    ├── integration_test/
    │   └── plugin_integration_test.dart
    ├── lib/
    │   └── main.dart
    └── test/
    │   └── widget_test.dart
├── lib/
    ├── src/
    │   ├── models/
    │   │   ├── message_config.dart
    │   │   └── process_info.dart
    │   ├── exception.dart
    │   ├── flutter_alone_method_channel.dart
    │   └── flutter_alone_platform_interface.dart
    └── flutter_alone.dart
├── test/
    ├── flutter_alone_method_channel_test.dart
    └── flutter_alone_test.dart
└── windows/
    ├── include/
        └── flutter_alone/
        │   └── flutter_alone_plugin_c_api.h
    ├── test/
        └── flutter_alone_plugin_test.cpp
    ├── CMakeLists.txt
    ├── flutter_alone_plugin.cpp
    ├── flutter_alone_plugin.h
    ├── flutter_alone_plugin_c_api.cpp
    ├── message_utils.cpp
    ├── message_utils.h
    ├── process_utils.cpp
    ├── process_utils.h
    ├── window_utils.cpp
    └── window_utils.h
```

## example/integration_test/plugin_integration_test.dart
```dart
import 'dart:io';

import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('Flutter Alone Plugin Integration Tests', () {
    late FlutterAlone flutterAlone;
    const channel = MethodChannel('flutter_alone');

    setUpAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        switch (methodCall.method) {
          case 'checkAndRun':
            return true;
          case 'dispose':
            return null;
          default:
            throw PlatformException(code: 'error');
        }
      });
    });

    setUp(() {
      flutterAlone = FlutterAlone.instance;
    });

    tearDown(() async {
      try {
        await flutterAlone.dispose();
      } catch (e) {
        // Ignore cleanup errors
      }
    });

    tearDownAll(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });

    test('Basic functionality test', () async {
      if (Platform.isWindows) {
        final result = await flutterAlone.checkAndRun();
        expect(result, true);
      }
    });

    test('Error handling test', () async {
      if (Platform.isWindows) {
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
            .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
          throw PlatformException(code: 'error');
        });

        // AloneException을 기대하도록 수정
        expect(() async => await flutterAlone.checkAndRun(),
            throwsA(isA<AloneException>()));
      }
    });
  });
}

```
## example/lib/main.dart
```dart
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final messageConfig = CustomMessageConfig(
    customTitle: 'Example App',
    customMessage: 'Application is already running in another account',
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

```
## example/test/widget_test.dart
```dart
// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:flutter_alone_example/main.dart';

void main() {
  testWidgets('Verify Platform version', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that platform version is retrieved.
    expect(
      find.byWidgetPredicate(
        (Widget widget) => widget is Text &&
                           widget.data!.startsWith('Running on:'),
      ),
      findsOneWidget,
    );
  });
}

```
## lib/flutter_alone.dart
```dart
import 'package:flutter/material.dart';
import 'package:flutter_alone/src/models/message_config.dart';

import 'src/flutter_alone_platform_interface.dart';

export 'src/exception.dart';
export 'src/models/message_config.dart';

/// Main class for the Flutter Alone plugin
class FlutterAlone {
  static final FlutterAlone _instance = FlutterAlone._();
  FlutterAlone._();

  static FlutterAlone get instance => _instance;

  /// Check for duplicate instances and initialize the application
  ///
  /// Returns:
  /// - true: Application can start
  /// - false: Another instance is already running
  Future<bool> checkAndRun({
    MessageConfig messageConfig = const EnMessageConfig(),
  }) async {
    try {
      final result = await FlutterAlonePlatform.instance.checkAndRun(
        messageConfig: messageConfig,
      );
      return result;
    } catch (e) {
      debugPrint('Error checking application instance: $e');
      rethrow;
    }
  }

  /// Clean up resources when application closes
  Future<void> dispose() async {
    try {
      await FlutterAlonePlatform.instance.dispose();
    } catch (e) {
      debugPrint('Error cleaning up resources: $e');
      rethrow;
    }
  }
}

```
## lib/src/exception.dart
```dart
class AloneException implements Exception {
  /// error code
  final String code;

  /// error message
  final String message;

  /// additional details
  final dynamic details;

  AloneException({
    required this.code,
    required this.message,
    this.details,
  });

  @override
  String toString() => 'AloneException($code): $message';
}

```
## lib/src/flutter_alone_method_channel.dart
```dart
import 'package:flutter/services.dart';
import 'package:flutter_alone/src/models/message_config.dart';

import 'exception.dart';
import 'flutter_alone_platform_interface.dart';

/// Platform implementation using method channel
class MethodChannelFlutterAlone extends FlutterAlonePlatform {
  /// Method channel for platform communication
  final MethodChannel _channel = const MethodChannel('flutter_alone');

  @override
  Future<bool> checkAndRun({
    MessageConfig messageConfig = const EnMessageConfig(),
  }) async {
    try {
      final result = await _channel.invokeMethod<bool>(
        'checkAndRun',
        messageConfig.toMap(),
      );
      return result ?? false;
    } on PlatformException catch (e) {
      throw AloneException(
        code: e.code,
        message: e.message ?? 'Error checking application instance',
        details: e.details,
      );
    }
  }

  @override
  Future<void> dispose() async {
    try {
      await _channel.invokeMethod<void>('dispose');
    } on PlatformException catch (e) {
      throw AloneException(
        code: e.code,
        message: e.message ?? 'Error disposing resources',
        details: e.details,
      );
    }
  }
}

```
## lib/src/flutter_alone_platform_interface.dart
```dart
import 'package:flutter_alone/src/models/message_config.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_alone_method_channel.dart';

/// Platform interface for the plugin
/// Defines the interface that all platform implementations must follow
abstract class FlutterAlonePlatform extends PlatformInterface {
  /// Constructs a FlutterAlonePlatform
  FlutterAlonePlatform() : super(token: _token);

  static final Object _token = Object();

  /// Current platform implementation instance
  static FlutterAlonePlatform _instance = MethodChannelFlutterAlone();

  /// Platform implementation instance getter
  static FlutterAlonePlatform get instance => _instance;

  /// Platform implementation setter
  static set instance(FlutterAlonePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  /// Check if application can run and perform initialization
  ///
  /// Returns:
  /// - true: Application can start
  /// - false: Another instance is already running
  Future<bool> checkAndRun({
    MessageConfig messageConfig = const EnMessageConfig(),
  }) {
    throw UnimplementedError('checkAndRun() has not been implemented.');
  }

  /// Clean up resources
  Future<void> dispose() {
    throw UnimplementedError('dispose() has not been implemented.');
  }
}

```
## lib/src/models/message_config.dart
```dart
enum MessageConfigJsonKey {
  type,
  showMessageBox,
  customTitle,
  customMessage,
  ;

  String get key => toString().split('.').last;
}

/// Base abstract class for message configuration
abstract class MessageConfig {
  /// Whether to show message box
  final bool showMessageBox;

  /// Constructor
  const MessageConfig({
    this.showMessageBox = true,
  });

  /// Convert to map for MethodChannel communication
  Map<String, dynamic> toMap();
}

/// Korean message configuration
class KoMessageConfig extends MessageConfig {
  /// Constructor
  const KoMessageConfig({
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() => {
        MessageConfigJsonKey.type.key: 'ko',
        MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      };
}

/// English message configuration
class EnMessageConfig extends MessageConfig {
  /// Constructor
  const EnMessageConfig({
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() => {
        MessageConfigJsonKey.type.key: 'en',
        MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      };
}

/// Custom message configuration
///
/// Example:
/// ```dart
/// final config = CustomMessageConfig(
///   customTitle: "Notice",
///   customMessage: "Application is already running in another account.",
/// );
/// ```
class CustomMessageConfig extends MessageConfig {
  /// Custom title for the message box
  final String customTitle;

  /// Message template string
  final String customMessage;

  /// Constructor
  const CustomMessageConfig({
    required this.customTitle,
    required this.customMessage,
    super.showMessageBox,
  });

  @override
  Map<String, dynamic> toMap() => {
        MessageConfigJsonKey.type.key: 'custom',
        MessageConfigJsonKey.customTitle.key: customTitle,
        MessageConfigJsonKey.customMessage.key: customMessage,
        MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      };
}

```
## lib/src/models/process_info.dart
```dart
// ignore_for_file: public_member_api_docs, sort_constructors_first
enum ProcessInfoJsonKey {
  processId,
  windowHandle,
  processPath,
  startTime,
  ;

  String get key => toString().split('.').last;
}

/// Model class for process information
class ProcessInfo {
  /// Process ID
  final int processId;

  /// Window handle
  final int windowHandle;

  /// Process path
  final String processPath;

  /// Process start time (Windows FILETIME)
  final int startTime;

  ProcessInfo({
    required this.processId,
    required this.windowHandle,
    required this.processPath,
    required this.startTime,
  });

  /// Create ProcessInfo from JSON
  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      processId: json[ProcessInfoJsonKey.processId.key] as int,
      windowHandle: json[ProcessInfoJsonKey.windowHandle.key] as int,
      processPath: json[ProcessInfoJsonKey.processPath.key] as String,
      startTime: json[ProcessInfoJsonKey.startTime.key] as int,
    );
  }

  /// Convert ProcessInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      ProcessInfoJsonKey.processId.key: processId,
      ProcessInfoJsonKey.windowHandle.key: windowHandle,
      ProcessInfoJsonKey.processPath.key: processPath,
      ProcessInfoJsonKey.startTime.key: startTime,
    };
  }

  ProcessInfo copyWith({
    int? processId,
    int? windowHandle,
    String? processPath,
    int? startTime,
  }) {
    return ProcessInfo(
      processId: processId ?? this.processId,
      windowHandle: windowHandle ?? this.windowHandle,
      processPath: processPath ?? this.processPath,
      startTime: startTime ?? this.startTime,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessInfo &&
        other.processId == processId &&
        other.windowHandle == windowHandle &&
        other.processPath == processPath &&
        other.startTime == startTime;
  }

  @override
  int get hashCode => Object.hash(
        processId,
        windowHandle,
        processPath,
        startTime,
      );
}

```
## test/flutter_alone_method_channel_test.dart
```dart
// test/flutter_alone_method_channel_test.dart

import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('MethodChannelFlutterAlone Tests', () {
    late MethodChannelFlutterAlone platform;
    late List<MethodCall> log;

    // Set up test method channel
    const channel = MethodChannel('flutter_alone');

    setUp(() {
      platform = MethodChannelFlutterAlone();
      log = <MethodCall>[];

      // Configure method channel handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        log.add(methodCall);

        switch (methodCall.method) {
          case 'checkAndRun':
            return true;
          case 'dispose':
            return null;
          default:
            throw PlatformException(
              code: 'not_implemented',
              message: 'Method not implemented',
              details: 'Method: ${methodCall.method}',
            );
        }
      });
    });

    tearDown(() {
      // Reset handler after test
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkAndRun with Korean message config', () async {
      const messageConfig = KoMessageConfig(showMessageBox: true);

      final result = await platform.checkAndRun(messageConfig: messageConfig);

      expect(log, hasLength(1));
      expect(
        log.first,
        isMethodCall('checkAndRun', arguments: {
          'type': 'ko',
          'showMessageBox': true,
        }),
      );
      expect(result, true);
    });

    test('checkAndRun with English message config', () async {
      const messageConfig = EnMessageConfig(showMessageBox: false);

      final result = await platform.checkAndRun(messageConfig: messageConfig);

      expect(log, hasLength(1));
      expect(
        log.first,
        isMethodCall('checkAndRun', arguments: {
          'type': 'en',
          'showMessageBox': false,
        }),
      );
      expect(result, true);
    });

    test('checkAndRun with custom message config', () async {
      const messageConfig = CustomMessageConfig(
        customTitle: 'Notice',
        customMessage: 'Program is already running',
        showMessageBox: true,
      );

      final result = await platform.checkAndRun(messageConfig: messageConfig);

      expect(log, hasLength(1));
      expect(
        log.first,
        isMethodCall('checkAndRun', arguments: {
          'type': 'custom',
          'customTitle': 'Notice',
          'customMessage': 'Program is already running',
          'showMessageBox': true,
        }),
      );
      expect(result, true);
    });

    test('dispose method call', () async {
      await platform.dispose();

      expect(log, hasLength(1));
      expect(log.first, isMethodCall('dispose', arguments: null));
    });

    test('checkAndRun platform error handling', () async {
      // Change to error-throwing handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Error checking for duplicate execution',
          details: 'Failed to access system resources',
        );
      });

      expect(
        () => platform.checkAndRun(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having(
                (e) => e.message,
                'message',
                'Error checking for duplicate execution',
              )
              .having(
                (e) => e.details,
                'details',
                'Failed to access system resources',
              ),
        ),
      );
    });

    test('dispose platform error handling', () async {
      // Change to error-throwing handler
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Error while cleaning up resources',
          details: 'Failed to release system mutex',
        );
      });

      expect(
        () => platform.dispose(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having(
                (e) => e.message,
                'message',
                'Error while cleaning up resources',
              )
              .having(
                (e) => e.details,
                'details',
                'Failed to release system mutex',
              ),
        ),
      );
    });

    test('invalid method call', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'not_implemented',
          message: 'Method not implemented',
        );
      });

      expect(
        () => channel.invokeMethod<void>('invalidMethod'),
        throwsA(isA<PlatformException>()),
      );
    });
  });
}

```
## test/flutter_alone_test.dart
```dart
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockFlutterAlonePlatform
    with MockPlatformInterfaceMixin
    implements FlutterAlonePlatform {
  // mock 메서드 호출 기록
  bool checkAndRunCalled = false;
  bool disposeCalled = false;
  MessageConfig? lastMessageConfig;

  @override
  Future<bool> checkAndRun({
    MessageConfig messageConfig = const EnMessageConfig(),
  }) async {
    checkAndRunCalled = true;
    lastMessageConfig = messageConfig;
    return true;
  }

  @override
  Future<void> dispose() async {
    disposeCalled = true;
  }
}

void main() {
  late FlutterAlone flutterAlone;
  late MockFlutterAlonePlatform mockPlatform;

  setUp(() {
    mockPlatform = MockFlutterAlonePlatform();
    FlutterAlonePlatform.instance = mockPlatform;
    flutterAlone = FlutterAlone.instance;
  });

  group('메시지 설정 테스트', () {
    test('한국어 메시지 설정이 올바르게 생성되어야 함', () {
      const config = KoMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'ko');
      expect(map['showMessageBox'], true);
    });

    test('영어 메시지 설정이 올바르게 생성되어야 함', () {
      const config = EnMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('커스텀 메시지가 올바르게 처리되어야 함', () {
      const config =
          CustomMessageConfig(customTitle: '테스트 제목', customMessage: '테스트 메시지');
      final map = config.toMap();

      expect(map['type'], 'custom');
      expect(map['customTitle'], '테스트 제목');
      expect(map['customMessage'], '테스트 메시지');
      expect(map['showMessageBox'], true);
    });
  });

  group('플러그인 기본 기능 테스트', () {
    test('checkAndRun이 올바르게 호출되어야 함', () async {
      const messageConfig =
          CustomMessageConfig(customTitle: '테스트', customMessage: '메시지');

      final result =
          await flutterAlone.checkAndRun(messageConfig: messageConfig);

      expect(result, true);
      expect(mockPlatform.checkAndRunCalled, true);
      expect(mockPlatform.lastMessageConfig, messageConfig);
    });

    test('dispose가 올바르게 호출되어야 함', () async {
      await flutterAlone.dispose();
      expect(mockPlatform.disposeCalled, true);
    });
  });
}

```
## windows/CMakeLists.txt
```txt
﻿# The Flutter tooling requires that developers have a version of Visual Studio
# installed that includes CMake 3.14 or later. You should not increase this
# version, as doing so will cause the plugin to fail to compile for some
# customers of the plugin.
cmake_minimum_required(VERSION 3.14)

# Project-level configuration.
set(PROJECT_NAME "flutter_alone")
project(${PROJECT_NAME} LANGUAGES CXX)

# Explicitly opt in to modern CMake behaviors to avoid warnings with recent
# versions of CMake.
cmake_policy(VERSION 3.14...3.25)

# This value is used when generating builds using this plugin, so it must
# not be changed
set(PLUGIN_NAME "flutter_alone_plugin")

# Any new source files that you add to the plugin should be added here.
list(APPEND PLUGIN_SOURCES
  "flutter_alone_plugin.cpp"
  "flutter_alone_plugin.h"
  "process_utils.cpp"
  "process_utils.h"
  "message_utils.cpp"
  "message_utils.h"
  "window_utils.cpp"
  "window_utils.h"
)

# Define the plugin library target. Its name must not be changed (see comment
# on PLUGIN_NAME above).
add_library(${PLUGIN_NAME} SHARED
  "include/flutter_alone/flutter_alone_plugin_c_api.h"
  "flutter_alone_plugin_c_api.cpp"
  ${PLUGIN_SOURCES}
)

# Apply a standard set of build settings that are configured in the
# application-level CMakeLists.txt. This can be removed for plugins that want
# full control over build settings.
apply_standard_settings(${PLUGIN_NAME})

# Symbols are hidden by default to reduce the chance of accidental conflicts
# between plugins. This should not be removed; any symbols that should be
# exported should be explicitly exported with the FLUTTER_PLUGIN_EXPORT macro.
set_target_properties(${PLUGIN_NAME} PROPERTIES
  CXX_VISIBILITY_PRESET hidden)
target_compile_definitions(${PLUGIN_NAME} PRIVATE FLUTTER_PLUGIN_IMPL SECURITY_WIN32)

# Source include directories and library dependencies. Add any plugin-specific
# dependencies here.
target_include_directories(${PLUGIN_NAME} INTERFACE
  "${CMAKE_CURRENT_SOURCE_DIR}/include")
target_link_libraries(${PLUGIN_NAME} PRIVATE flutter flutter_wrapper_plugin)

# List of absolute paths to libraries that should be bundled with the plugin.
# This list could contain prebuilt libraries, or libraries created by an
# external build triggered from this build file.
set(flutter_alone_bundled_libraries
  ""
  PARENT_SCOPE
)
```
## windows/flutter_alone_plugin.cpp
```cpp
﻿#include "flutter_alone_plugin.h"

// This must be included before many other Windows headers.
#include <windows.h>

// For getPlatformVersion; remove unless needed for your plugin implementation.
#include <VersionHelpers.h>

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include <flutter/standard_method_codec.h>
#include "window_utils.h"

#include <memory>
#include <sstream>

namespace flutter_alone {

// Global mutex handle
static HANDLE g_hMutex = NULL;

// static
void FlutterAlonePlugin::RegisterWithRegistrar(
    flutter::PluginRegistrarWindows *registrar) {
  // create method channel
  auto channel =
      std::make_unique<flutter::MethodChannel<flutter::EncodableValue>>(
          registrar->messenger(), "flutter_alone",
          &flutter::StandardMethodCodec::GetInstance());
  // create plugin
  auto plugin = std::make_unique<FlutterAlonePlugin>();
  // set method call handler
  channel->SetMethodCallHandler(
      [plugin_pointer = plugin.get()](const auto &call, auto result) {
        plugin_pointer->HandleMethodCall(call, std::move(result));
      });
  // add plugin
  registrar->AddPlugin(std::move(plugin));
}
// constructor
FlutterAlonePlugin::FlutterAlonePlugin() {}

// destructor
FlutterAlonePlugin::~FlutterAlonePlugin() {
  CleanupResources();
}

// Display running process information in MessageBox
void FlutterAlonePlugin::ShowAlreadyRunningMessage(
    const std::wstring& title,
    const std::wstring& message,
    bool showMessageBox) {
    if(!showMessageBox) {
        OutputDebugStringW(L"[DEBUG] showMessageBox is false, skipping message display\n");
        return;
    }
    
    MessageBoxW(
        NULL,
        message.c_str(),
        title.c_str(),
        MB_OK | MB_ICONINFORMATION | MB_SYSTEMMODAL
    );
}
ProcessCheckResult FlutterAlonePlugin::CheckRunningInstance() {
    ProcessCheckResult result;
    result.canRun = true;
    
    // Check for global mutex
    HANDLE existingMutex = OpenMutexW(MUTEX_ALL_ACCESS, FALSE, L"Global\\FlutterAloneApp_UniqueId");

    if (existingMutex != NULL) {
        OutputDebugStringW(L"[DEBUG] Existing mutex found\n");
        CloseHandle(existingMutex);
        result.canRun = false;
        
        // 기존 프로세스 찾기 - 같은 사용자인지 확인용
        auto existingProcess = ProcessUtils::FindExistingProcess();
        if (existingProcess.has_value()) {
            result.existingWindow = existingProcess->windowHandle;
            OutputDebugStringW(L"[DEBUG] Existing process window found\n");
        }
    }

    return result;
}

// Check for duplicate instance function
bool FlutterAlonePlugin::CheckAndCreateMutex() {
  if (g_hMutex != NULL) {
    return false;
  }

  // Set security attributes - Allow access all user
  SECURITY_ATTRIBUTES sa;
  sa.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle = TRUE;
  
  SECURITY_DESCRIPTOR sd;
  InitializeSecurityDescriptor(&sd, SECURITY_DESCRIPTOR_REVISION);
  SetSecurityDescriptorDacl(&sd, TRUE, NULL, FALSE);
  sa.lpSecurityDescriptor = &sd;

  // Try to create global mutex
  g_hMutex = CreateMutexW(
      &sa,     // security attribute
      TRUE,    // request init
      L"Global\\FlutterAloneApp_UniqueId"  // uniqe mutex name
  );

  if (g_hMutex == NULL) {
    return false;
  }

  if (GetLastError() == ERROR_ALREADY_EXISTS) {
    CleanupResources();
    return false;
  }

  return true;
}

// Resource cleanup function
void FlutterAlonePlugin::CleanupResources() {
  if (g_hMutex != NULL) {
    ReleaseMutex(g_hMutex);  // release mutex
    CloseHandle(g_hMutex);   // close handle
    g_hMutex = NULL;
  }
}

// Method call handler function
void FlutterAlonePlugin::HandleMethodCall(
    const flutter::MethodCall<flutter::EncodableValue> &method_call,
    std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result) {
    if (method_call.method_name().compare("checkAndRun") == 0) {
        OutputDebugStringW(L"[DEBUG] HandleMethodCall: checkAndRun 시작\n");
        
        const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());
        
        // 메시지 설정 가져오기
        std::string typeStr = std::get<std::string>(arguments->at(flutter::EncodableValue("type")));
        bool showMessageBox = std::get<bool>(arguments->at(flutter::EncodableValue("showMessageBox")));
        
        MessageType type;
        if(typeStr == "ko") type = MessageType::ko;
        else if(typeStr == "en") type = MessageType::en;
        else type = MessageType::custom;
        
        std::wstring customTitle, customMessage;
        if (type == MessageType::custom) {
            customTitle = MessageUtils::Utf8ToWide(
                std::get<std::string>(arguments->at(flutter::EncodableValue("customTitle"))));
            customMessage = MessageUtils::Utf8ToWide(
                std::get<std::string>(arguments->at(flutter::EncodableValue("customMessage"))));
        }

        // 실행 중인 인스턴스 확인
        auto checkResult = CheckRunningInstance();

        
          if (!checkResult.canRun) {
            // 같은 창인 경우 - 창 활성화
            if (checkResult.existingWindow != NULL) {
                OutputDebugStringW(L"[DEBUG] Existing window found - activating window\n");
                WindowUtils::RestoreWindow(checkResult.existingWindow);
                WindowUtils::BringWindowToFront(checkResult.existingWindow);
                WindowUtils::FocusWindow(checkResult.existingWindow);
            } 
            // 다른 계정에서 실행 중인 경우 - 메시지 표시
            else {
                OutputDebugStringW(L"[DEBUG] No existing window - showing message\n");
                std::wstring title = MessageUtils::GetTitle(type, customTitle);
                std::wstring message = MessageUtils::GetMessage(type, customMessage);
                ShowAlreadyRunningMessage(title, message, showMessageBox);
            }
            
            result->Success(flutter::EncodableValue(false));
            return;
        }

        // 새로운 뮤텍스 생성
        bool success = CheckAndCreateMutex();
        result->Success(flutter::EncodableValue(success));
    } 
    else if (method_call.method_name().compare("dispose") == 0) {
        CleanupResources();
        result->Success();
    } 
    else {
        result->NotImplemented();
    }
}

}  // namespace flutter_alone

void FlutterAlonePluginRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_alone::FlutterAlonePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}
```
## windows/flutter_alone_plugin.h
```h
﻿#ifndef FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_
#define FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_

#include <flutter/method_channel.h>
#include <flutter/plugin_registrar_windows.h>
#include "process_utils.h"
#include "message_utils.h"

#include <memory>

namespace flutter_alone {

struct ProcessCheckResult {
  bool canRun;        
  bool isSameUser;    
  HWND existingWindow;

  ProcessCheckResult() : canRun(true), isSameUser(false), existingWindow(NULL) {}
};

class FlutterAlonePlugin : public flutter::Plugin {
 public:
  static void RegisterWithRegistrar(flutter::PluginRegistrarWindows *registrar);

  FlutterAlonePlugin();

  virtual ~FlutterAlonePlugin();

  // Disallow copy and assign.
  FlutterAlonePlugin(const FlutterAlonePlugin&) = delete;
  FlutterAlonePlugin& operator=(const FlutterAlonePlugin&) = delete;

  // Called when a method is called on this plugin's channel from Dart.
  void HandleMethodCall(
      const flutter::MethodCall<flutter::EncodableValue> &method_call,
      std::unique_ptr<flutter::MethodResult<flutter::EncodableValue>> result);
	
	// check and create mutex
  bool CheckAndCreateMutex();
  
  // cleanup resources
  void CleanupResources();

  // show process info
  void ShowAlreadyRunningMessage(
  const std::wstring& title,
  const std::wstring& message,
  bool showMessageBox);

  ProcessCheckResult CheckRunningInstance();

 private:
  // 뮤텍스 핸들 저장
  HANDLE mutex_handle_;
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_H_

```
## windows/flutter_alone_plugin_c_api.cpp
```cpp
﻿#include "include/flutter_alone/flutter_alone_plugin_c_api.h"

#include <flutter/plugin_registrar_windows.h>

#include "flutter_alone_plugin.h"

void FlutterAlonePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar) {
  flutter_alone::FlutterAlonePlugin::RegisterWithRegistrar(
      flutter::PluginRegistrarManager::GetInstance()
          ->GetRegistrar<flutter::PluginRegistrarWindows>(registrar));
}

```
## windows/include/flutter_alone/flutter_alone_plugin_c_api.h
```h
#ifndef FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_C_API_H_
#define FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_C_API_H_

#include <flutter_plugin_registrar.h>

#ifdef FLUTTER_PLUGIN_IMPL
#define FLUTTER_PLUGIN_EXPORT __declspec(dllexport)
#else
#define FLUTTER_PLUGIN_EXPORT __declspec(dllimport)
#endif

#if defined(__cplusplus)
extern "C" {
#endif

FLUTTER_PLUGIN_EXPORT void FlutterAlonePluginCApiRegisterWithRegistrar(
    FlutterDesktopPluginRegistrarRef registrar);

#if defined(__cplusplus)
}  // extern "C"
#endif

#endif  // FLUTTER_PLUGIN_FLUTTER_ALONE_PLUGIN_C_API_H_

```
## windows/message_utils.cpp
```cpp
﻿#include "message_utils.h"
#include <windows.h>

namespace flutter_alone {

std::wstring MessageUtils::GetTitle(MessageType type, const std::wstring& customTitle) {
    switch (type) {
        case MessageType::ko:
            return GetKoreanTitle();
        case MessageType::en:
            return GetEnglishTitle();
        case MessageType::custom:
            return customTitle.empty() ? L"Error" : customTitle;
        default:
            return L"Error";
    }
}

std::wstring MessageUtils::GetMessage(
    MessageType type,
    const std::wstring& customMessage
) {
    switch (type) {
        case MessageType::ko:
            return GetKoreanMessage();
        case MessageType::en:
            return GetEnglishMessage();
        case MessageType::custom:
            return customMessage.empty() ? 
                L"Application is already running in another account" : customMessage;
        default:
            return L"Application is already running in another account";
    }
}

std::wstring MessageUtils::GetKoreanMessage() {
    return L"이미 다른 계정에서 앱을 실행중입니다.";
}

std::wstring MessageUtils::GetEnglishMessage() {
    return L"Application is already running in another account.";
}

std::wstring MessageUtils::Utf8ToWide(const std::string& str) {
    if (str.empty()) return std::wstring();
    
    int size_needed = MultiByteToWideChar(CP_UTF8, 0, str.c_str(), 
        static_cast<int>(str.length()), nullptr, 0);
    
    std::wstring result(size_needed, 0);
    MultiByteToWideChar(CP_UTF8, 0, str.c_str(), 
        static_cast<int>(str.length()), &result[0], size_needed);
    
    return result;
}

std::string MessageUtils::WideToUtf8(const std::wstring& wstr) {
    if (wstr.empty()) return std::string();
    
    int size_needed = WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), 
        static_cast<int>(wstr.length()), nullptr, 0, nullptr, nullptr);
    
    std::string result(size_needed, 0);
    WideCharToMultiByte(CP_UTF8, 0, wstr.c_str(), 
        static_cast<int>(wstr.length()), &result[0], size_needed, nullptr, nullptr);
    
    return result;
}

}  // namespace flutter_alone
```
## windows/message_utils.h
```h
﻿#ifndef FLUTTER_PLUGIN_MESSAGE_UTILS_H_
#define FLUTTER_PLUGIN_MESSAGE_UTILS_H_

#include <string>
#include "process_utils.h"

namespace flutter_alone {

enum class MessageType {
    ko,
    en,
    custom
};

class MessageUtils {
public:
    /**
     * Get title based on message type and configuration
     */
    static std::wstring GetTitle(MessageType type, const std::wstring& customTitle = L"");

    /**
     * Get message based on message type and configuration
     */
    static std::wstring GetMessage(
        MessageType type,
        const std::wstring& customMessage = L""
    );


    /**
     * Convert string encoding between UTF-8 and UTF-16
     */
    static std::wstring Utf8ToWide(const std::string& str);
    static std::string WideToUtf8(const std::wstring& wstr);

private:
    // Default titles
    static std::wstring GetKoreanTitle() { return L"실행 오류"; }
    static std::wstring GetEnglishTitle() { return L"Execution Error"; }
    
    // Default messages
    static std::wstring GetKoreanMessage();
    static std::wstring GetEnglishMessage();
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_MESSAGE_UTILS_H_
```
## windows/process_utils.cpp
```cpp
﻿#include "process_utils.h"
#include "window_utils.h"
#include <windows.h>
#include <security.h>
#include <sddl.h>
#include <sspi.h>
#include <tlhelp32.h>
#include <vector>

namespace flutter_alone {

ProcessInfo ProcessUtils::GetProcessInfoById(DWORD processId) {
    ProcessInfo info;
    info.processId = processId;
    
    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, TRUE, processId);
    if (hProcess) {
        info.startTime = GetProcessStartTime(hProcess);
        info.processPath = GetProcessPath(processId);
        CloseHandle(hProcess);
    }
    
    info.windowHandle = WindowUtils::FindMainWindow(processId);
    return info;
}

std::optional<ProcessInfo> ProcessUtils::FindExistingProcess() {
    DWORD currentPid = GetCurrentProcessId();
    std::wstring currentPath = GetProcessPath(currentPid);
    
    HANDLE snapshot = CreateToolhelp32Snapshot(TH32CS_SNAPPROCESS, 0);
    if (snapshot == INVALID_HANDLE_VALUE) {
        return std::nullopt;
    }

    PROCESSENTRY32W processEntry;
    processEntry.dwSize = sizeof(processEntry);

    if (Process32FirstW(snapshot, &processEntry)) {
        do {
            if (processEntry.th32ProcessID != currentPid) {
                std::wstring processPath = GetProcessPath(processEntry.th32ProcessID);
                if (IsSameExecutable(currentPath, processPath)) {
                    CloseHandle(snapshot);
                    return GetProcessInfoById(processEntry.th32ProcessID);
                }
            }
        } while (Process32NextW(snapshot, &processEntry));
    }

    CloseHandle(snapshot);
    return std::nullopt;
}

bool ProcessUtils::IsSameExecutable(const std::wstring& path1, const std::wstring& path2) {
    if (path1.empty() || path2.empty()) {
        return false;
    }
    
    WCHAR fullPath1[MAX_PATH];
    WCHAR fullPath2[MAX_PATH];
    
    if (GetFullPathNameW(path1.c_str(), MAX_PATH, fullPath1, NULL) == 0 ||
        GetFullPathNameW(path2.c_str(), MAX_PATH, fullPath2, NULL) == 0) {
        return false;
    }
    
    return _wcsicmp(fullPath1, fullPath2) == 0;
}

ProcessInfo ProcessUtils::GetCurrentProcessInfo() {
    return GetProcessInfoById(GetCurrentProcessId());
}

std::wstring ProcessUtils::GetProcessPath(DWORD processId) {
    std::wstring path;
    HANDLE hProcess = OpenProcess(PROCESS_QUERY_LIMITED_INFORMATION, FALSE, processId);
    if (hProcess) {
        WCHAR buffer[MAX_PATH];
        DWORD size = MAX_PATH;
        if (QueryFullProcessImageNameW(hProcess, 0, buffer, &size)) {
            path = std::wstring(buffer);
        }
        CloseHandle(hProcess);
    }
    return path;
}

FILETIME ProcessUtils::GetProcessStartTime(HANDLE hProcess) {
    FILETIME creation, exit, kernel, user;
    FILETIME empty = {0, 0};
    
    if (!GetProcessTimes(hProcess, &creation, &exit, &kernel, &user)) {
        return empty;
    }
    return creation;
}




std::wstring ProcessUtils::GetLastErrorMessage() {
    DWORD error = GetLastError();
    LPWSTR messageBuffer = nullptr;
    
    FormatMessageW(
        FORMAT_MESSAGE_ALLOCATE_BUFFER | 
        FORMAT_MESSAGE_FROM_SYSTEM |
        FORMAT_MESSAGE_IGNORE_INSERTS,
        NULL,
        error,
        MAKELANGID(LANG_NEUTRAL, SUBLANG_DEFAULT),
        (LPWSTR)&messageBuffer,
        0,
        NULL
    );
    
    std::wstring message = messageBuffer ? messageBuffer : L"Unknown error";
    LocalFree(messageBuffer);
    
    return message;
}

}  // namespace flutter_alone
```
## windows/process_utils.h
```h
﻿#ifndef FLUTTER_PLUGIN_PROCESS_UTILS_H_
#define FLUTTER_PLUGIN_PROCESS_UTILS_H_

#include <windows.h>
#include <string>
#include <optional>

namespace flutter_alone {

struct ProcessInfo {
    DWORD processId;
    HWND windowHandle;
    std::wstring processPath;
    FILETIME startTime;

    ProcessInfo() : processId(0), windowHandle(NULL) {
        startTime.dwLowDateTime = 0;
        startTime.dwHighDateTime = 0;
    }
};

class ProcessUtils {
public:
    /**
     * Get process info for given process ID
     */
    static ProcessInfo GetProcessInfoById(DWORD processId);
    
    /**
     * Get current process information
     */
    static ProcessInfo GetCurrentProcessInfo();
    
    /**
     * Find existing instance of our application
     */
    static std::optional<ProcessInfo> FindExistingProcess();
    
    /**
     * Get process executable path
     */
    static std::wstring GetProcessPath(DWORD processId);
    
    /**
     * Get process start time
     */
    static FILETIME GetProcessStartTime(HANDLE hProcess);
    
    /**
     * Get last error message
     */
    static std::wstring GetLastErrorMessage();

private:
    /**
     * Check if two paths point to same executable
     */
    static bool IsSameExecutable(const std::wstring& path1, const std::wstring& path2);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_PROCESS_UTILS_H_
```
## windows/test/flutter_alone_plugin_test.cpp
```cpp
#include <flutter/method_call.h>
#include <flutter/method_result_functions.h>
#include <flutter/standard_method_codec.h>
#include <gtest/gtest.h>
#include <windows.h>

#include <memory>
#include <string>
#include <variant>

#include "flutter_alone_plugin.h"

namespace flutter_alone {
namespace test {

namespace {

using flutter::EncodableMap;
using flutter::EncodableValue;
using flutter::MethodCall;
using flutter::MethodResultFunctions;

}  // namespace

TEST(FlutterAlonePlugin, GetPlatformVersion) {
  FlutterAlonePlugin plugin;
  // Save the reply value from the success callback.
  std::string result_string;
  plugin.HandleMethodCall(
      MethodCall("getPlatformVersion", std::make_unique<EncodableValue>()),
      std::make_unique<MethodResultFunctions<>>(
          [&result_string](const EncodableValue* result) {
            result_string = std::get<std::string>(*result);
          },
          nullptr, nullptr));

  // Since the exact string varies by host, just ensure that it's a string
  // with the expected format.
  EXPECT_TRUE(result_string.rfind("Windows ", 0) == 0);
}

}  // namespace test
}  // namespace flutter_alone

```
## windows/window_utils.cpp
```cpp
﻿#include "window_utils.h"

namespace flutter_alone {

HWND WindowUtils::FindMainWindow(DWORD processId) {
    EnumWindowsCallbackArgs args = {0};
    args.processId = processId;
    args.resultHandle = NULL;
    
    EnumWindows(EnumWindowsCallback, reinterpret_cast<LPARAM>(&args));
    return args.resultHandle;
}

bool WindowUtils::BringWindowToFront(HWND hwnd) {
    if (!IsValidWindow(hwnd)) return false;
    
    // get top
    DWORD foregroundThreadId = GetWindowThreadProcessId(GetForegroundWindow(), NULL);
    DWORD currentThreadId = GetCurrentThreadId();
    
    if (foregroundThreadId != currentThreadId) {
        AttachThreadInput(currentThreadId, foregroundThreadId, TRUE);
        BringWindowToTop(hwnd);
        AttachThreadInput(currentThreadId, foregroundThreadId, FALSE);
    } else {
        BringWindowToTop(hwnd);
    }
    
    return true;
}

bool WindowUtils::RestoreWindow(HWND hwnd) {
    if (!IsValidWindow(hwnd)) return false;
    
    // 최소화된 경우 복원
    if (IsIconic(hwnd)) {
        return ShowWindow(hwnd, SW_RESTORE);
    }
    return true;
}

bool WindowUtils::FocusWindow(HWND hwnd) {
    if (!IsValidWindow(hwnd)) return false;
    
    SetForegroundWindow(hwnd);
    SetFocus(hwnd);
    return true;
}

bool WindowUtils::IsValidWindow(HWND hwnd) {
    return hwnd != NULL && IsWindow(hwnd);
}

BOOL CALLBACK WindowUtils::EnumWindowsCallback(HWND handle, LPARAM lParam) {
    EnumWindowsCallbackArgs* args = reinterpret_cast<EnumWindowsCallbackArgs*>(lParam);
    
    DWORD processId = 0;
    GetWindowThreadProcessId(handle, &processId);
    
    if (processId == args->processId) {
        if (IsWindowVisible(handle)) {
            WCHAR title[256];
            if (GetWindowTextW(handle, title, 256) > 0) {
                args->resultHandle = handle;
                return FALSE;
            }
        }
    }
    return TRUE;
}

}  // namespace flutter_alone
```
## windows/window_utils.h
```h
﻿#ifndef FLUTTER_PLUGIN_WINDOW_UTILS_H_
#define FLUTTER_PLUGIN_WINDOW_UTILS_H_

#include <windows.h>
#include <string>

namespace flutter_alone {

class WindowUtils {
public:
    // Find main window
    static HWND FindMainWindow(DWORD processId);
    
    // Bring window to front
    static bool BringWindowToFront(HWND hwnd);
    
    // Restore window
    static bool RestoreWindow(HWND hwnd);
    
    // Focus Window
    static bool FocusWindow(HWND hwnd);
    
    // Check is valid window
    static bool IsValidWindow(HWND hwnd);

private:
    // EnumWindows struct
    struct EnumWindowsCallbackArgs {
        DWORD processId;
        HWND resultHandle;
    };

    // EnumWindows Callback
    static BOOL CALLBACK EnumWindowsCallback(HWND handle, LPARAM lParam);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_WINDOW_UTILS_H_
```
