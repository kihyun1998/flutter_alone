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
    │   │   ├── process_info.dart
    │   │   └── window_config.dart
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
    └── process_utils.h
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
import 'package:flutter/material.dart';
import 'package:flutter_alone/flutter_alone.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final messageConfig = CustomMessageConfig(
    customTitle: 'Example App',
    messageTemplate: 'Application is already running by {domain}\\{userName}',
  );

  if (!await FlutterAlone.instance.checkAndRun(messageConfig: messageConfig)) {
    return;
  }

  runApp(const MyApp());
}

class WindowConfig {}

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
export 'src/models/window_config.dart';

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
import 'package:flutter_alone/src/models/window_config.dart';

enum MessageConfigJsonKey {
  type,
  showMessageBox,
  customTitle,
  messageTemplate,
  ;

  String get key => toString().split('.').last;
}

/// Base abstract class for message configuration
abstract class MessageConfig {
  /// Whether to show message box
  final bool showMessageBox;

  /// window config
  final WindowConfig windowConfig;

  /// Constructor
  const MessageConfig({
    this.showMessageBox = true,
    this.windowConfig = const WindowConfig(activateExistingWindow: true),
  });

  /// Convert to map for MethodChannel communication
  Map<String, dynamic> toMap() {
    final baseMap = {
      MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      ...windowConfig.toMap(),
    };
    return addTypeSpecificConfig(baseMap);
  }

  Map<String, dynamic> addTypeSpecificConfig(Map<String, dynamic> baseMap);
}

/// Korean message configuration
class KoMessageConfig extends MessageConfig {
  /// Constructor
  const KoMessageConfig({
    super.showMessageBox,
    super.windowConfig,
  });

  @override
  Map<String, dynamic> addTypeSpecificConfig(Map<String, dynamic> baseMap) => {
        ...baseMap,
        MessageConfigJsonKey.type.key: 'ko',
        MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      };
}

/// English message configuration
class EnMessageConfig extends MessageConfig {
  /// Constructor
  const EnMessageConfig({
    super.showMessageBox,
    super.windowConfig,
  });

  @override
  Map<String, dynamic> addTypeSpecificConfig(Map<String, dynamic> baseMap) => {
        ...baseMap,
        MessageConfigJsonKey.type.key: 'en',
        MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      };
}

/// Custom message configuration
///
/// Available placeholders in [messageTemplate]:
/// - {domain}: User domain
/// - {userName}: User name
///
/// Example:
/// ```dart
/// final config = CustomMessageConfig(
///   customTitle: "Running",
///   messageTemplate: "Program is running by {domain}\\{userName}",
/// );
/// ```
class CustomMessageConfig extends MessageConfig {
  /// Custom title for the message box
  final String customTitle;

  /// Message template string
  /// Can use {domain} and {userName} placeholders
  final String messageTemplate;

  /// Constructor
  const CustomMessageConfig({
    required this.customTitle,
    required this.messageTemplate,
    super.showMessageBox,
    super.windowConfig,
  });

  @override
  Map<String, dynamic> addTypeSpecificConfig(Map<String, dynamic> baseMap) => {
        ...baseMap,
        MessageConfigJsonKey.type.key: 'custom',
        MessageConfigJsonKey.customTitle.key: customTitle,
        MessageConfigJsonKey.messageTemplate.key: messageTemplate,
        MessageConfigJsonKey.showMessageBox.key: showMessageBox,
      };
}

```
## lib/src/models/process_info.dart
```dart
// ignore_for_file: public_member_api_docs, sort_constructors_first
enum ProcessInfoJsonKey {
  domain,
  userName,
  processId,
  windowHandle,
  ;

  String get key => toString().split('.').last;
}

/// Model class for process information
class ProcessInfo {
  /// Domain of the running user (e.g., DESKTOP-123)
  final String domain;

  /// Username of the running user
  final String userName;

  /// Process ID
  final int processId;

  /// Window handle (HWND) as int64
  /// 0 if window not found
  final int windowHandle;

  /// Default Constructor
  ProcessInfo({
    required this.domain,
    required this.userName,
    required this.processId,
    this.windowHandle = 0,
  });

  /// Create ProcessInfo from JSON
  factory ProcessInfo.fromJson(Map<String, dynamic> json) {
    return ProcessInfo(
      domain: json[ProcessInfoJsonKey.domain.key] as String,
      userName: json[ProcessInfoJsonKey.userName.key] as String,
      processId: json[ProcessInfoJsonKey.processId.key] as int,
      windowHandle: json[ProcessInfoJsonKey.windowHandle.key] as int? ?? 0,
    );
  }

  /// Convert ProcessInfo to JSON
  Map<String, dynamic> toJson() {
    return {
      ProcessInfoJsonKey.domain.key: domain,
      ProcessInfoJsonKey.userName.key: userName,
      ProcessInfoJsonKey.processId.key: processId,
      ProcessInfoJsonKey.windowHandle.key: windowHandle,
    };
  }

  ProcessInfo copyWith({
    String? domain,
    String? userName,
    int? processId,
    int? windowHandle,
  }) {
    return ProcessInfo(
      domain: domain ?? this.domain,
      userName: userName ?? this.userName,
      processId: processId ?? this.processId,
      windowHandle: windowHandle ?? this.windowHandle,
    );
  }

  @override
  String toString() {
    return '$domain\\$userName (PID: $processId, HWND: $windowHandle)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProcessInfo &&
        other.domain == domain &&
        other.userName == userName &&
        other.processId == processId &&
        other.windowHandle == windowHandle;
  }

  @override
  int get hashCode => Object.hash(domain, userName, processId, windowHandle);
}

```
## lib/src/models/window_config.dart
```dart
enum WindowConfigJsonKey {
  activateExistingWindow,
  ;

  String get key => toString().split('.').last;
}

/// Configuration for window activation when duplicate execution is detected
class WindowConfig {
  /// Whether to activate an existing window when running under the same account
  ///
  /// true: Finds and activates the existing window
  /// false: Displays only a message box
  final bool activateExistingWindow;

  /// Default Constructor
  const WindowConfig({
    this.activateExistingWindow = true,
  });

  /// Converts to a Map for MethodChannel communication
  Map<String, dynamic> toMap() => {
        WindowConfigJsonKey.activateExistingWindow.key: activateExistingWindow,
      };

  WindowConfig copyWith({
    bool? activateExistingWindow,
  }) {
    return WindowConfig(
      activateExistingWindow:
          activateExistingWindow ?? this.activateExistingWindow,
    );
  }
}

```
## test/flutter_alone_method_channel_test.dart
```dart
import 'package:flutter/services.dart';
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_alone/src/flutter_alone_method_channel.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Method Channel Tests', () {
    late MethodChannelFlutterAlone platform;
    final channel = MethodChannel('flutter_alone');
    final List<MethodCall> log = <MethodCall>[];

    setUp(() {
      platform = MethodChannelFlutterAlone();
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
              details: 'No implementation found for ${methodCall.method}',
            );
        }
      });
    });

    tearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
      log.clear();
    });

    test('checkAndRun should handle message configurations correctly',
        () async {
      final messageConfig = CustomMessageConfig(
        customTitle: 'Custom Title',
        messageTemplate: 'App running as {domain}\\{userName}',
        showMessageBox: true,
      );

      final result = await platform.checkAndRun(messageConfig: messageConfig);

      // Verify method call
      expect(log, hasLength(1));
      expect(
        log.first,
        isMethodCall('checkAndRun', arguments: {
          'type': 'custom',
          'customTitle': 'Custom Title',
          'messageTemplate': 'App running as {domain}\\{userName}',
          'showMessageBox': true,
        }),
      );

      // Verify result
      expect(result, isTrue);
    });

    test('dispose should clean up resources properly', () async {
      await platform.dispose();

      // Verify method call
      expect(log, hasLength(1));
      expect(log.first, isMethodCall('dispose', arguments: null));
    });

    test('checkAndRun should throw AloneException on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Test error message',
          details: 'Error details',
        );
      });

      expect(
        () => platform.checkAndRun(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having((e) => e.message, 'message', 'Test error message')
              .having((e) => e.details, 'details', 'Error details'),
        ),
      );
    });

    test('dispose should throw AloneException on platform error', () async {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
        throw PlatformException(
          code: 'error',
          message: 'Failed to dispose resources',
          details: 'Cleanup error details',
        );
      });

      expect(
        () => platform.dispose(),
        throwsA(
          isA<AloneException>()
              .having((e) => e.code, 'code', 'error')
              .having(
                  (e) => e.message, 'message', 'Failed to dispose resources')
              .having((e) => e.details, 'details', 'Cleanup error details'),
        ),
      );
    });
  });
}

```
## test/flutter_alone_test.dart
```dart
import 'package:flutter_alone/flutter_alone.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Message Configuration Tests', () {
    test('Korean message configuration should be created correctly', () {
      const config = KoMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'ko');
      expect(map['showMessageBox'], true);
    });

    test('English message configuration should be created correctly', () {
      const config = EnMessageConfig();
      final map = config.toMap();

      expect(map['type'], 'en');
      expect(map['showMessageBox'], true);
    });

    test('Custom message configuration should handle placeholders', () {
      const config = CustomMessageConfig(
          customTitle: 'Test Title',
          messageTemplate: 'Running as {domain}\\{userName}');
      final map = config.toMap();

      expect(map['type'], 'custom');
      expect(map['customTitle'], 'Test Title');
      expect(map['messageTemplate'], 'Running as {domain}\\{userName}');
      expect(map['showMessageBox'], true);
    });

    test('Message configurations should respect showMessageBox parameter', () {
      const config = CustomMessageConfig(
          customTitle: 'Title',
          messageTemplate: 'Message',
          showMessageBox: false);
      final map = config.toMap();

      expect(map['showMessageBox'], false);
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

bool FlutterAlonePlugin::TryActivateExistingWindow(const ProcessInfo& processInfo){
  if(processInfo.windowHandle != NULL){
    return ProcessUtils::ActivateWindow(processInfo.windowHandle);
  }
  return false;
}

void FlutterAlonePlugin::HandleDuplicateInstance(
    const ProcessInfo& processInfo,
    bool activateExistingWindow,
    const std::wstring& title,
    const std::wstring& message,
    bool showMessageBox){
  
  bool activated = false;
  if(activateExistingWindow && ProcessUtils::IsSameUser(processInfo)){
    activated = TryActivateExistingWindow(processInfo);
  }

  // Show message box if window activation failed or if it's a diffrent user
  if(!activated && showMessageBox){
    ShowAlreadyRunningMessage(processInfo,title,message,showMessageBox);
  }
}


// Check for duplicate instance function
bool FlutterAlonePlugin::CheckAndCreateMutex(bool activateExistingWindow) {
  if (g_hMutex != NULL) {
    return false;
  }

  // Set security attributes - Allow access all user
  SECURITY_ATTRIBUTES sa;
  sa.nLength = sizeof(SECURITY_ATTRIBUTES);
  sa.bInheritHandle = FALSE;
  
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


// Display running process information in MessageBox
void FlutterAlonePlugin::ShowAlreadyRunningMessage(
  const ProcessInfo& processInfo,
  const std::wstring& title,
  const std::wstring& message,
  bool showMessageBox) {

    if(!showMessageBox) return;
    
    MessageBoxW(
        NULL,
        message.c_str(),
        title.c_str(),
        MB_OK | MB_ICONINFORMATION | MB_SYSTEMMODAL
    );
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
    const auto* arguments = std::get_if<flutter::EncodableMap>(method_call.arguments());

    // Get basic parameters
    std::string typeStr = std::get<std::string>(arguments->at(flutter::EncodableValue("type")));
    bool showMessageBox = std::get<bool>(arguments->at(flutter::EncodableValue("showMessageBox")));
    bool activateExistingWindow = std::get<bool>(arguments->at(flutter::EncodableValue("activateExistingWindow")));

    // Convert MessageType
    MessageType type;
    if(typeStr == "ko") type = MessageType::ko;
    else if(typeStr == "en") type = MessageType::en;
    else type = MessageType::custom;

    // Get custom parameters if needed
    std::wstring customTitle, messageTemplate;
    if (type == MessageType::custom) {
        customTitle = MessageUtils::Utf8ToWide(
            std::get<std::string>(arguments->at(flutter::EncodableValue("customTitle"))));
        messageTemplate = MessageUtils::Utf8ToWide(
            std::get<std::string>(arguments->at(flutter::EncodableValue("messageTemplate"))));
    }
    
    // Check duplicate instance
    bool canRun = CheckAndCreateMutex(activateExistingWindow);
    if(!canRun){
      ProcessInfo processInfo = ProcessUtils::GetCurrentProcessInfo();

      // Create message
      std::wstring title = MessageUtils::GetTitle(type, customTitle);
      std::wstring message = MessageUtils::GetMessage(type, processInfo, messageTemplate);

      HandleDuplicateInstance(processInfo,activateExistingWindow,title,message,showMessageBox);
    }

    result->Success(flutter::EncodableValue(canRun));
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
  bool CheckAndCreateMutex(bool activateExistingWindow);
  
  // cleanup resources
  void CleanupResources();

  // show process info
  void ShowAlreadyRunningMessage(
  const ProcessInfo& processInfo,
  const std::wstring& title,
  const std::wstring& message,
  bool showMessageBox);

 private:
  // Mutex handle for single instance check
  HANDLE mutex_handle_;

  // Try to activate existing window
  bool TryActivateExistingWindow(const ProcessInfo& processInfo);

  // Handle duplicate instance case
  void HandleDuplicateInstance(
    const ProcessInfo& processInfo,
    bool activateExistingWindow,
    const std::wstring& title,
    const std::wstring& message,
    bool showMessageBox);
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
    const ProcessInfo& processInfo,
    const std::wstring& messageTemplate
) {
    switch (type) {
        case MessageType::ko:
            return GetKoreanMessage(processInfo);
        case MessageType::en:
            return GetEnglishMessage(processInfo);
        case MessageType::custom:
            return ProcessTemplate(
                messageTemplate.empty() ? L"Another instance is running" : messageTemplate,
                processInfo
            );
        default:
            return L"Another instance is running";
    }
}

std::wstring MessageUtils::GetKoreanMessage(const ProcessInfo& processInfo) {
    return ProcessTemplate(
        L"이미 다른 사용자가 앱을 실행중입니다.\n실행 중인 사용자: {domain}\\{userName}",
        processInfo
    );
}

std::wstring MessageUtils::GetEnglishMessage(const ProcessInfo& processInfo) {
    return ProcessTemplate(
        L"Application is already running by another user.\nRunning user: {domain}\\{userName}",
        processInfo
    );
}

std::wstring MessageUtils::ProcessTemplate(
    const std::wstring& messageTemplate,
    const ProcessInfo& processInfo
) {
    std::wstring result = messageTemplate;
    
    // Replace {domain}
    size_t domainPos = result.find(L"{domain}");
    while (domainPos != std::wstring::npos) {
        result.replace(domainPos, 8, processInfo.domain);
        domainPos = result.find(L"{domain}", domainPos + processInfo.domain.length());
    }
    
    // Replace {userName}
    size_t userNamePos = result.find(L"{userName}");
    while (userNamePos != std::wstring::npos) {
        result.replace(userNamePos, 10, processInfo.userName);
        userNamePos = result.find(L"{userName}", userNamePos + processInfo.userName.length());
    }
    
    return result;
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
        const ProcessInfo& processInfo,
        const std::wstring& messageTemplate = L""
    );

    /**
     * Process message template with placeholders
     * Replaces {domain} and {userName} with actual values
     */
    static std::wstring ProcessTemplate(
        const std::wstring& messageTemplate,
        const ProcessInfo& processInfo
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
    static std::wstring GetKoreanMessage(const ProcessInfo& processInfo);
    static std::wstring GetEnglishMessage(const ProcessInfo& processInfo);
};

}  // namespace flutter_alone

#endif  // FLUTTER_PLUGIN_MESSAGE_UTILS_H_
```
## windows/process_utils.cpp
```cpp
﻿#include "process_utils.h"
#include <windows.h>
#include <security.h>
#include <sddl.h>
#include <sspi.h>

namespace flutter_alone {

ProcessInfo ProcessUtils::GetCurrentProcessInfo() {
    ProcessInfo info;
    info.processId = GetCurrentProcessId();
    info.windowHandle = FindMainWindow();
    
    HANDLE hToken = NULL;
    if (!OpenProcessToken(GetCurrentProcess(), TOKEN_QUERY, &hToken)) {
        return info;
    }

    // Get user from token
    if (!GetUserFromToken(hToken, info.domain, info.userName)) {
        CloseHandle(hToken);
        return info;
    }

    CloseHandle(hToken);
    return info;
}

BOOL CALLBACK ProcessUtils::EnumWindowsCallback(HWND hwnd, LPARAM lParam) {
    auto* params = reinterpret_cast<EnumWindowsCallbackParams*>(lParam);
    DWORD processId = 0;

    // Get process ID for the current window
    GetWindowThreadProcessId(hwnd, &processId);
    if(processId == params->processId && IsWindowVisible(hwnd)){
        // Check if window has a title 
        int length = GetWindowTextLength(hwnd);
        if (length >0 ){
            params->resultHandle = hwnd;
            return FALSE;
        }
    }
    return TRUE;
}

HWND ProcessUtils::FindMainWindow(){
    EnumWindowsCallbackParams params;
    params.processId = GetCurrentProcessId();
    params.resultHandle = NULL;

    // enumerate all windows to find our main window.
    EnumWindows(EnumWindowsCallback, reinterpret_cast<LPARAM>(&params));
    return params.resultHandle;
}

bool ProcessUtils::GetUserFromToken(HANDLE hToken, std::wstring& domain, std::wstring& userName) {
    DWORD dwSize = 0;
    PTOKEN_USER pTokenUser = NULL;
    
    // Get token information
    GetTokenInformation(hToken, TokenUser, NULL, 0, &dwSize);
    if (GetLastError() != ERROR_INSUFFICIENT_BUFFER) {
        return false;
    }
    
    // Allocate memory
    pTokenUser = (PTOKEN_USER)LocalAlloc(LPTR, dwSize);
    if (!pTokenUser) {
        return false;
    }
    
    // Get token information
    if (!GetTokenInformation(hToken, TokenUser, pTokenUser, dwSize, &dwSize)) {
        LocalFree(pTokenUser);
        return false;
    }
    
    WCHAR szUser[256] = {0};
    WCHAR szDomain[256] = {0};
    DWORD dwUserSize = 256;
    DWORD dwDomainSize = 256;
    SID_NAME_USE snu;
    
    // SID를 사용자 이름과 도메인으로 변환
    if (!LookupAccountSidW(
        NULL,                   // Local computer
        pTokenUser->User.Sid,   // SID
        szUser,                 // User Name
        &dwUserSize,           
        szDomain,              // Domain name
        &dwDomainSize,
        &snu)) {
        LocalFree(pTokenUser);
        return false;
    }
    
    domain = szDomain;
    userName = szUser;
    
    LocalFree(pTokenUser);
    return true;
}

bool ProcessUtils::IsSameUser(const ProcessInfo& processInfo){
    ProcessInfo currentInfo = GetCurrentProcessInfo();
    return (currentInfo.domain == processInfo.domain && currentInfo.userName == processInfo.userName);
}

bool ProcessUtils::ActivateWindow(HWND hWnd) {
    if (!hWnd || !IsWindow(hWnd)) {
        return false;
    }

    // If window is minimized, restore it
    if (IsIconic(hWnd)) {
        ShowWindow(hWnd, SW_RESTORE);
    }

    // Bring window to front
    if (!SetForegroundWindow(hWnd)) {
        // If SetForegroundWindow fails, try alternative method
        DWORD foregroundThread = GetWindowThreadProcessId(
            GetForegroundWindow(), NULL);
        DWORD currentThread = GetCurrentThreadId();

        if (foregroundThread != currentThread) {
            AttachThreadInput(currentThread, foregroundThread, TRUE);
            SetForegroundWindow(hWnd);
            AttachThreadInput(currentThread, foregroundThread, FALSE);
        }
    }

    // Set focus to the window
    SetFocus(hWnd);
    return true;
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

namespace flutter_alone {

struct ProcessInfo {
    std::wstring domain;
    std::wstring userName;
    DWORD processId;
    HWND windowHandle;
};

class ProcessUtils {
public:
    // Get current process user information
    static ProcessInfo GetCurrentProcessInfo();

    // Find main window handle for the current process
    static HWND FindMainWindow();

    // Check if the given process belongs to the current user
    static bool IsSameUser(const ProcessInfo& processInfo);

    // Activate the window if it exists
    static bool ActivateWindow(HWND hwnd);
    
    // Generate error message
    static std::wstring GetLastErrorMessage();

private:
    // Extract user information from Windows security token
    static bool GetUserFromToken(HANDLE hToken, std::wstring& domain, std::wstring& userName);

    // Callback function for EnumWindow
    static BOOL CALLBACK EnumWindowsCallback(HWND hwnd, LPARAM lParam);

    // Internal structure for window enumeration
    struct EnumWindowsCallbackParams {
        DWORD processId;
        HWND resultHandle;
    };
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
