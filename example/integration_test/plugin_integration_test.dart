// // example/integration_test/plugin_integration_test.dart
// import 'dart:io';

// import 'package:flutter/services.dart';
// import 'package:flutter_alone/flutter_alone.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:integration_test/integration_test.dart';

// void main() {
//   IntegrationTestWidgetsFlutterBinding.ensureInitialized();

//   // Ensure tests only run on Windows platform
//   if (!Platform.isWindows) {
//     group('Flutter Alone Plugin on non-Windows platforms', () {
//       test('Tests are skipped on non-Windows platforms', () {
//         // Skip tests on non-Windows platforms
//       });
//     });
//     return;
//   }

//   group('Flutter Alone Plugin Integration Tests on Windows', () {
//     late FlutterAlone flutterAlone;
//     const channel = MethodChannel('flutter_alone');

//     // Shared test configuration data with DefaultMutexConfig
//     final defaultMutexTestConfig = FlutterAloneConfig(
//       mutexConfig: const DefaultMutexConfig(
//         packageId: 'com.test.integration',
//         appName: 'IntegrationTestApp',
//       ),
//       duplicateCheckConfig: const DuplicateCheckConfig(
//         enableInDebugMode: true,
//       ),
//       messageConfig: const EnMessageConfig(),
//     );

//     // Shared test configuration data with CustomMutexConfig
//     final customMutexTestConfig = FlutterAloneConfig(
//       mutexConfig: const CustomMutexConfig(
//         customMutexName: 'IntegrationTestMutex',
//       ),
//       duplicateCheckConfig: const DuplicateCheckConfig(
//         enableInDebugMode: true,
//       ),
//       messageConfig: const EnMessageConfig(),
//     );

//     setUpAll(() {
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         switch (methodCall.method) {
//           case 'checkAndRun':
//             return true;
//           case 'dispose':
//             return null;
//           default:
//             throw PlatformException(
//               code: 'unimplemented',
//               message: 'Method not implemented',
//             );
//         }
//       });
//     });

//     setUp(() {
//       flutterAlone = FlutterAlone.instance;
//     });

//     tearDown(() async {
//       try {
//         await flutterAlone.dispose();
//       } catch (e) {
//         // Ignore errors during cleanup
//       }
//     });

//     tearDownAll(() {
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, null);
//     });

//     test('Basic functionality test with DefaultMutexConfig', () async {
//       final result =
//           await flutterAlone.checkAndRun(config: defaultMutexTestConfig);
//       expect(result, true,
//           reason:
//               'Verify successful mutex creation on platform with DefaultMutexConfig');
//     });

//     test('Basic functionality test with CustomMutexConfig', () async {
//       final result =
//           await flutterAlone.checkAndRun(config: customMutexTestConfig);
//       expect(result, true,
//           reason:
//               'Verify successful mutex creation on platform with CustomMutexConfig');
//     });

//     test('Error handling test - handles platform exceptions properly',
//         () async {
//       // Replace with handler that throws an exception
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         throw PlatformException(
//           code: 'mutex_error',
//           message: 'Failed to create mutex',
//           details: 'Simulated error for testing',
//         );
//       });

//       // Catch exception and verify type
//       expect(
//         () async =>
//             await flutterAlone.checkAndRun(config: defaultMutexTestConfig),
//         throwsA(isA<AloneException>()
//             .having((e) => e.code, 'error code', 'mutex_error')),
//         reason:
//             'Ensure platform exception is properly converted to AloneException',
//       );

//       // Restore original handler after test
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         switch (methodCall.method) {
//           case 'checkAndRun':
//             return true;
//           case 'dispose':
//             return null;
//           default:
//             throw PlatformException(code: 'unimplemented');
//         }
//       });
//     });

//     // Additional test: Verify that DefaultMutexConfig parameters are correctly passed
//     test('DefaultMutexConfig parameters are correctly passed to platform',
//         () async {
//       bool configVerified = false;

//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         if (methodCall.method == 'checkAndRun') {
//           final args = methodCall.arguments as Map<dynamic, dynamic>;
//           configVerified = args['mutexName'] ==
//                   'Global\\com.test.integration_IntegrationTestApp' &&
//               args['enableInDebugMode'] == true &&
//               args['type'] == 'en';
//           return true;
//         }
//         return null;
//       });

//       await flutterAlone.checkAndRun(config: defaultMutexTestConfig);
//       expect(configVerified, true,
//           reason:
//               'Verify DefaultMutexConfig parameters are passed to platform correctly');
//     });

//     // Additional test: Verify that CustomMutexConfig parameters are correctly passed
//     test('CustomMutexConfig parameters are correctly passed to platform',
//         () async {
//       bool configVerified = false;

//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         if (methodCall.method == 'checkAndRun') {
//           final args = methodCall.arguments as Map<dynamic, dynamic>;
//           configVerified =
//               args['mutexName'] == 'Global\\IntegrationTestMutex' &&
//                   args['enableInDebugMode'] == true &&
//                   args['type'] == 'en';
//           return true;
//         }
//         return null;
//       });

//       await flutterAlone.checkAndRun(config: customMutexTestConfig);
//       expect(configVerified, true,
//           reason:
//               'Verify CustomMutexConfig parameters are passed to platform correctly');
//     });

//     test('Test with all configuration options using DefaultMutexConfig',
//         () async {
//       final fullConfig = FlutterAloneConfig(
//         mutexConfig: const DefaultMutexConfig(
//           packageId: 'com.test.integration',
//           appName: 'IntegrationTestApp',
//           mutexSuffix: 'integration_test',
//         ),
//         windowConfig: const WindowConfig(
//           windowTitle: 'Integration Test Window',
//         ),
//         duplicateCheckConfig: const DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: const CustomMessageConfig(
//           customTitle: 'Integration Test',
//           customMessage: 'Integration test message',
//           showMessageBox: false,
//         ),
//       );

//       Map<String, dynamic>? capturedArguments;

//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         if (methodCall.method == 'checkAndRun') {
//           capturedArguments =
//               Map<String, dynamic>.from(methodCall.arguments as Map);
//           return true;
//         }
//         return null;
//       });

//       await flutterAlone.checkAndRun(config: fullConfig);

//       expect(capturedArguments, isNotNull);
//       expect(capturedArguments!['mutexName'],
//           'Global\\com.test.integration_IntegrationTestApp_integration_test');
//       expect(capturedArguments!['windowTitle'], 'Integration Test Window');
//       expect(capturedArguments!['enableInDebugMode'], true);
//       expect(capturedArguments!['type'], 'custom');
//       expect(capturedArguments!['customTitle'], 'Integration Test');
//       expect(capturedArguments!['customMessage'], 'Integration test message');
//       expect(capturedArguments!['showMessageBox'], false);
//     });

//     test('Test with all configuration options using CustomMutexConfig',
//         () async {
//       final fullConfig = FlutterAloneConfig(
//         mutexConfig: const CustomMutexConfig(
//           customMutexName: 'CustomIntegrationTestMutex',
//         ),
//         windowConfig: const WindowConfig(
//           windowTitle: 'Integration Test Window',
//         ),
//         duplicateCheckConfig: const DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: const CustomMessageConfig(
//           customTitle: 'Integration Test',
//           customMessage: 'Integration test message',
//           showMessageBox: false,
//         ),
//       );

//       Map<String, dynamic>? capturedArguments;

//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         if (methodCall.method == 'checkAndRun') {
//           capturedArguments =
//               Map<String, dynamic>.from(methodCall.arguments as Map);
//           return true;
//         }
//         return null;
//       });

//       await flutterAlone.checkAndRun(config: fullConfig);

//       expect(capturedArguments, isNotNull);
//       expect(capturedArguments!['mutexName'],
//           'Global\\CustomIntegrationTestMutex');
//       expect(capturedArguments!['windowTitle'], 'Integration Test Window');
//       expect(capturedArguments!['enableInDebugMode'], true);
//       expect(capturedArguments!['type'], 'custom');
//       expect(capturedArguments!['customTitle'], 'Integration Test');
//       expect(capturedArguments!['customMessage'], 'Integration test message');
//       expect(capturedArguments!['showMessageBox'], false);
//     });
//   });
// }
