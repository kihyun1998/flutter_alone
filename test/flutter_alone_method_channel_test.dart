// // test/flutter_alone_method_channel_test.dart
// import 'package:flutter/services.dart';
// import 'package:flutter_alone/flutter_alone.dart';
// import 'package:flutter_alone/flutter_alone_method_channel.dart';
// import 'package:flutter_test/flutter_test.dart';

// void main() {
//   TestWidgetsFlutterBinding.ensureInitialized();

//   group('MethodChannelFlutterAlone Tests', () {
//     late MethodChannelFlutterAlone platform;
//     late List<MethodCall> log;

//     // Set up test method channel
//     const channel = MethodChannel('flutter_alone');

//     setUp(() {
//       platform = MethodChannelFlutterAlone();
//       log = <MethodCall>[];

//       // Configure method channel handler
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         log.add(methodCall);

//         switch (methodCall.method) {
//           case 'checkAndRun':
//             return true;
//           case 'dispose':
//             return null;
//           default:
//             throw PlatformException(
//               code: 'not_implemented',
//               message: 'Method not implemented',
//               details: 'Method: ${methodCall.method}',
//             );
//         }
//       });
//     });

//     tearDown(() {
//       // Reset handler after test
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, null);
//       log.clear();
//     });

//     test('checkAndRun with Korean message config and DefaultMutexConfig',
//         () async {
//       const config = FlutterAloneConfig(
//         mutexConfig: DefaultMutexConfig(
//           packageId: 'com.test.integration',
//           appName: 'IntegrationTest',
//         ),
//         messageConfig: KoMessageConfig(
//           showMessageBox: true,
//         ),
//       );

//       final result = await platform.checkAndRun(config: config);

//       expect(log, hasLength(1));
//       final methodCall = log.first;
//       expect(methodCall.method, 'checkAndRun');
//       expect(methodCall.arguments['type'], 'ko');
//       expect(methodCall.arguments['showMessageBox'], true);
//       expect(methodCall.arguments['mutexName'],
//           'Global\\com.test.integration_IntegrationTest');

//       expect(result, true);
//     });

//     test('checkAndRun with English message config and DefaultMutexConfig',
//         () async {
//       const config = FlutterAloneConfig(
//         mutexConfig: DefaultMutexConfig(
//           packageId: 'com.test.integration',
//           appName: 'IntegrationTest',
//         ),
//         messageConfig: EnMessageConfig(
//           showMessageBox: false,
//         ),
//       );

//       final result = await platform.checkAndRun(config: config);

//       expect(log, hasLength(1));
//       final methodCall = log.first;
//       expect(methodCall.method, 'checkAndRun');
//       expect(methodCall.arguments['type'], 'en');
//       expect(methodCall.arguments['showMessageBox'], false);
//       expect(methodCall.arguments['mutexName'],
//           'Global\\com.test.integration_IntegrationTest');

//       expect(result, true);
//     });

//     test('checkAndRun with custom message config and CustomMutexConfig',
//         () async {
//       const config = FlutterAloneConfig(
//         mutexConfig: CustomMutexConfig(
//           customMutexName: 'TestCustomMutex',
//         ),
//         messageConfig: CustomMessageConfig(
//           customTitle: 'Notice',
//           customMessage: 'Program is already running',
//           showMessageBox: true,
//         ),
//       );

//       final result = await platform.checkAndRun(config: config);

//       expect(log, hasLength(1));
//       final methodCall = log.first;
//       expect(methodCall.method, 'checkAndRun');
//       expect(methodCall.arguments['type'], 'custom');
//       expect(methodCall.arguments['customTitle'], 'Notice');
//       expect(
//           methodCall.arguments['customMessage'], 'Program is already running');
//       expect(methodCall.arguments['showMessageBox'], true);
//       expect(methodCall.arguments['mutexName'], 'Global\\TestCustomMutex');

//       expect(result, true);
//     });

//     test('dispose method call', () async {
//       await platform.dispose();

//       expect(log, hasLength(1));
//       expect(log.first, isMethodCall('dispose', arguments: null));
//     });

//     test('checkAndRun platform error handling', () async {
//       // Change to error-throwing handler
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         throw PlatformException(
//           code: 'error',
//           message: 'Error checking for duplicate execution',
//           details: 'Failed to access system resources',
//         );
//       });

//       const config = FlutterAloneConfig(
//         mutexConfig: DefaultMutexConfig(
//           packageId: 'com.test.integration',
//           appName: 'IntegrationTest',
//         ),
//         messageConfig: EnMessageConfig(
//           showMessageBox: false,
//         ),
//       );

//       expect(
//         () => platform.checkAndRun(config: config),
//         throwsA(
//           isA<AloneException>()
//               .having((e) => e.code, 'code', 'error')
//               .having(
//                 (e) => e.message,
//                 'message',
//                 'Error checking for duplicate execution',
//               )
//               .having(
//                 (e) => e.details,
//                 'details',
//                 'Failed to access system resources',
//               ),
//         ),
//       );
//     });

//     test('checkAndRun with full configuration using DefaultMutexConfig',
//         () async {
//       const config = FlutterAloneConfig(
//         mutexConfig: DefaultMutexConfig(
//           packageId: 'com.test.integration',
//           appName: 'IntegrationTest',
//           mutexSuffix: 'test',
//         ),
//         windowConfig: WindowConfig(
//           windowTitle: 'Test Window Title',
//         ),
//         duplicateCheckConfig: DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: CustomMessageConfig(
//           customTitle: 'Notice',
//           customMessage: 'Program is already running',
//           showMessageBox: true,
//         ),
//       );

//       final result = await platform.checkAndRun(config: config);

//       expect(log, hasLength(1));
//       final methodCall = log.first;
//       expect(methodCall.method, 'checkAndRun');

//       // Check all configuration parameters
//       expect(methodCall.arguments['mutexName'],
//           'Global\\com.test.integration_IntegrationTest_test');
//       expect(methodCall.arguments['windowTitle'], 'Test Window Title');
//       expect(methodCall.arguments['enableInDebugMode'], true);
//       expect(methodCall.arguments['type'], 'custom');
//       expect(methodCall.arguments['customTitle'], 'Notice');
//       expect(
//           methodCall.arguments['customMessage'], 'Program is already running');
//       expect(methodCall.arguments['showMessageBox'], true);

//       expect(result, true);
//     });

//     test('checkAndRun with full configuration using CustomMutexConfig',
//         () async {
//       const config = FlutterAloneConfig(
//         mutexConfig: CustomMutexConfig(
//           customMutexName: 'MyUniqueTestMutex',
//         ),
//         windowConfig: WindowConfig(
//           windowTitle: 'Test Window Title',
//         ),
//         duplicateCheckConfig: DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: CustomMessageConfig(
//           customTitle: 'Notice',
//           customMessage: 'Program is already running',
//           showMessageBox: true,
//         ),
//       );

//       final result = await platform.checkAndRun(config: config);

//       expect(log, hasLength(1));
//       final methodCall = log.first;
//       expect(methodCall.method, 'checkAndRun');

//       // Check all configuration parameters
//       expect(methodCall.arguments['mutexName'], 'Global\\MyUniqueTestMutex');
//       expect(methodCall.arguments['windowTitle'], 'Test Window Title');
//       expect(methodCall.arguments['enableInDebugMode'], true);
//       expect(methodCall.arguments['type'], 'custom');
//       expect(methodCall.arguments['customTitle'], 'Notice');
//       expect(
//           methodCall.arguments['customMessage'], 'Program is already running');
//       expect(methodCall.arguments['showMessageBox'], true);

//       expect(result, true);
//     });

//     test('dispose platform error handling', () async {
//       // Change to error-throwing handler
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         throw PlatformException(
//           code: 'error',
//           message: 'Error while cleaning up resources',
//           details: 'Failed to release system mutex',
//         );
//       });

//       expect(
//         () => platform.dispose(),
//         throwsA(
//           isA<AloneException>()
//               .having((e) => e.code, 'code', 'error')
//               .having(
//                 (e) => e.message,
//                 'message',
//                 'Error while cleaning up resources',
//               )
//               .having(
//                 (e) => e.details,
//                 'details',
//                 'Failed to release system mutex',
//               ),
//         ),
//       );
//     });

//     test('invalid method call', () async {
//       TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
//           .setMockMethodCallHandler(channel, (MethodCall methodCall) async {
//         throw PlatformException(
//           code: 'not_implemented',
//           message: 'Method not implemented',
//         );
//       });

//       expect(
//         () => channel.invokeMethod<void>('invalidMethod'),
//         throwsA(isA<PlatformException>()),
//       );
//     });
//   });
// }
