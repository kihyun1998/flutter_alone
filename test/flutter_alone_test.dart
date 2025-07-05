// import 'package:flutter_alone/flutter_alone.dart';
// import 'package:flutter_alone/flutter_alone_platform_interface.dart';
// import 'package:flutter_test/flutter_test.dart';
// import 'package:plugin_platform_interface/plugin_platform_interface.dart';

// class MockFlutterAlonePlatform
//     with MockPlatformInterfaceMixin
//     implements FlutterAlonePlatform {
//   // Record mock method calls
//   bool checkAndRunCalled = false;
//   bool disposeCalled = false;
//   Map<String, dynamic>? lastArguments;

//   @override
//   Future<bool> checkAndRun({required FlutterAloneConfig config}) async {
//     checkAndRunCalled = true;
//     lastArguments = config.toMap();
//     return true;
//   }

//   @override
//   Future<void> dispose() async {
//     disposeCalled = true;
//   }
// }

// void main() {
//   late FlutterAlone flutterAlone;
//   late MockFlutterAlonePlatform mockPlatform;

//   setUp(() {
//     mockPlatform = MockFlutterAlonePlatform();
//     FlutterAlonePlatform.instance = mockPlatform;
//     flutterAlone = FlutterAlone.instance;
//   });

//   group('Configuration tests', () {
//     test('DefaultMutexConfig should be created correctly', () {
//       const config = DefaultMutexConfig(
//         packageId: 'com.test.app',
//         appName: 'TestApp',
//       );
//       final map = config.toMap();

//       expect(map['mutexName'], 'Global\\com.test.app_TestApp');
//     });

//     test('DefaultMutexConfig with suffix should be created correctly', () {
//       const config = DefaultMutexConfig(
//         packageId: 'com.test.app',
//         appName: 'TestApp',
//         mutexSuffix: 'production',
//       );
//       final map = config.toMap();

//       expect(map['mutexName'], 'Global\\com.test.app_TestApp_production');
//     });

//     test('CustomMutexConfig should be created correctly', () {
//       const config = CustomMutexConfig(
//         customMutexName: 'MyCustomMutex',
//       );
//       final map = config.toMap();

//       expect(map['mutexName'], 'Global\\MyCustomMutex');
//     });

//     test('CustomMutexConfig with Global prefix should preserve it', () {
//       const config = CustomMutexConfig(
//         customMutexName: 'Global\\MyCustomMutex',
//       );
//       final map = config.toMap();

//       expect(map['mutexName'], 'Global\\MyCustomMutex');
//     });

//     test('WindowConfig should be created correctly', () {
//       const config = WindowConfig(
//         windowTitle: 'Test Window',
//       );
//       final map = config.toMap();

//       expect(map['windowTitle'], 'Test Window');
//     });

//     test('DuplicateCheckConfig should be created correctly', () {
//       const config = DuplicateCheckConfig(
//         enableInDebugMode: true,
//       );
//       final map = config.toMap();

//       expect(map['enableInDebugMode'], true);
//     });

//     test('Default DuplicateCheckConfig should have enableInDebugMode=false',
//         () {
//       const config = DuplicateCheckConfig();
//       final map = config.toMap();

//       expect(map['enableInDebugMode'], false);
//     });

//     test('EnMessageConfig should be created correctly', () {
//       const config = EnMessageConfig();
//       final map = config.toMap();

//       expect(map['type'], 'en');
//       expect(map['showMessageBox'], true);
//     });

//     test('KoMessageConfig should be created correctly', () {
//       const config = KoMessageConfig();
//       final map = config.toMap();

//       expect(map['type'], 'ko');
//       expect(map['showMessageBox'], true);
//     });

//     test('CustomMessageConfig should be created correctly', () {
//       const config = CustomMessageConfig(
//         customTitle: 'Test Title',
//         customMessage: 'Test Message',
//         showMessageBox: false,
//       );
//       final map = config.toMap();

//       expect(map['type'], 'custom');
//       expect(map['customTitle'], 'Test Title');
//       expect(map['customMessage'], 'Test Message');
//       expect(map['showMessageBox'], false);
//     });
//   });

//   group('FlutterAloneConfig tests', () {
//     test(
//         'Combined config with DefaultMutexConfig should include all components',
//         () {
//       const config = FlutterAloneConfig(
//         mutexConfig: DefaultMutexConfig(
//           packageId: 'com.test.app',
//           appName: 'TestApp',
//           mutexSuffix: 'test',
//         ),
//         windowConfig: WindowConfig(
//           windowTitle: 'Test Window',
//         ),
//         duplicateCheckConfig: DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: CustomMessageConfig(
//           customTitle: 'Test Title',
//           customMessage: 'Test Message',
//           showMessageBox: false,
//         ),
//       );

//       final map = config.toMap();

//       // Check mutex config
//       expect(map['mutexName'], 'Global\\com.test.app_TestApp_test');

//       // Check window config
//       expect(map['windowTitle'], 'Test Window');

//       // Check duplicate check config
//       expect(map['enableInDebugMode'], true);

//       // Check message config
//       expect(map['type'], 'custom');
//       expect(map['customTitle'], 'Test Title');
//       expect(map['customMessage'], 'Test Message');
//       expect(map['showMessageBox'], false);
//     });

//     test('Combined config with CustomMutexConfig should include all components',
//         () {
//       const config = FlutterAloneConfig(
//         mutexConfig: CustomMutexConfig(
//           customMutexName: 'MyCustomMutexName',
//         ),
//         windowConfig: WindowConfig(
//           windowTitle: 'Test Window',
//         ),
//         duplicateCheckConfig: DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: EnMessageConfig(),
//       );

//       final map = config.toMap();

//       // Check mutex config
//       expect(map['mutexName'], 'Global\\MyCustomMutexName');

//       // Check window config
//       expect(map['windowTitle'], 'Test Window');

//       // Check duplicate check config
//       expect(map['enableInDebugMode'], true);

//       // Check message config
//       expect(map['type'], 'en');
//       expect(map['showMessageBox'], true);
//     });
//   });

//   group('Plugin functionality tests', () {
//     test('checkAndRun should pass correct config with DefaultMutexConfig',
//         () async {
//       const config = FlutterAloneConfig(
//         mutexConfig: DefaultMutexConfig(
//           packageId: 'com.test.app',
//           appName: 'TestApp',
//         ),
//         duplicateCheckConfig: DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: EnMessageConfig(),
//       );

//       final result = await flutterAlone.checkAndRun(config: config);

//       expect(result, true);
//       expect(mockPlatform.checkAndRunCalled, true);

//       final args = mockPlatform.lastArguments;
//       expect(args, isNotNull);
//       expect(args!['mutexName'], 'Global\\com.test.app_TestApp');
//       expect(args['type'], 'en');
//     });

//     test('checkAndRun should pass correct config with CustomMutexConfig',
//         () async {
//       const config = FlutterAloneConfig(
//         mutexConfig: CustomMutexConfig(
//           customMutexName: 'MyCustomMutexForTesting',
//         ),
//         duplicateCheckConfig: DuplicateCheckConfig(
//           enableInDebugMode: true,
//         ),
//         messageConfig: EnMessageConfig(),
//       );

//       final result = await flutterAlone.checkAndRun(config: config);

//       expect(result, true);
//       expect(mockPlatform.checkAndRunCalled, true);

//       final args = mockPlatform.lastArguments;
//       expect(args, isNotNull);
//       expect(args!['mutexName'], 'Global\\MyCustomMutexForTesting');
//       expect(args['type'], 'en');
//     });

//     test('dispose should be called correctly', () async {
//       await flutterAlone.dispose();
//       expect(mockPlatform.disposeCalled, true);
//     });
//   });
// }
