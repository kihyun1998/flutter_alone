import 'package:flutter/foundation.dart';
import 'package:flutter_alone/src/models/message_config.dart';
import 'package:package_info_plus/package_info_plus.dart';

import 'src/flutter_alone_platform_interface.dart';

export 'src/exception.dart';
export 'src/models/message_config.dart';

/// Main class for the Flutter Alone plugin
class FlutterAlone {
  static final FlutterAlone _instance = FlutterAlone._();
  FlutterAlone._();

  static FlutterAlone get instance => _instance;

  // Package Info cache
  PackageInfo? _packageInfo;

  /// Check for duplicate instances and initialize the application
  ///
  /// Parameters:
  /// - messageConfig: Configuration for message display and content
  /// - packageId: Package identifier used for mutex name generation (e.g. 'com.example.myapp')
  /// - appName: Application name used for mutex name generation
  /// - mutexSuffix: Optional suffix for mutex name to further customize it
  ///
  /// In debug mode, duplicate check is skipped unless enableInDebugMode is true
  /// Returns:
  /// - true: Application can start
  /// - false: Another instance is already running
  Future<bool> checkAndRun({
    MessageConfig messageConfig = const EnMessageConfig(),
    String? packageId,
    String? appName,
    String? mutexSuffix,
    required String windowTitle,
  }) async {
    try {
      // Skip duplicate check in debug mode unless explicitly enabled
      if (kDebugMode && !messageConfig.enableInDebugMode) {
        return true;
      }

      // Automatically fetch if package information is not provided
      final updatedConfig = await _updateMessageConfigWithPackageInfo(
        baseConfig: messageConfig,
        packageId: packageId,
        appName: appName,
        mutexSuffix: mutexSuffix,
        windowTitle: windowTitle,
      );

      final result = await FlutterAlonePlatform.instance.checkAndRun(
        messageConfig: updatedConfig,
      );
      return result;
    } catch (e) {
      debugPrint('Error checking application instance: $e');
      rethrow;
    }
  }

  /// Create an updated message config with app information
  Future<MessageConfig> _updateMessageConfigWithPackageInfo({
    required MessageConfig baseConfig,
    String? packageId = '',
    String? appName = '',
    String? mutexSuffix = '',
    required String windowTitle,
  }) async {
    String finalPackageId = packageId ?? baseConfig.packageId;
    String finalAppName = appName ?? baseConfig.appName;

    // Use package_info_plus if packageID or appName is empty
    if (finalPackageId.isEmpty || finalAppName.isEmpty) {
      try {
        _packageInfo ??= await PackageInfo.fromPlatform();

        // Replace only empty values with package information
        if (finalPackageId.isEmpty) {
          finalPackageId = _packageInfo!.packageName;
        }

        if (finalAppName.isEmpty) {
          finalAppName = _packageInfo!.appName;
        }
      } catch (error) {
        debugPrint("Failed to get package info: $error");
        if (finalPackageId.isEmpty) {
          finalPackageId = "default_app_id";
        }

        if (finalAppName.isEmpty) {
          finalAppName = "default_app_name";
        }
      }
    }

    // 업데이트된 값으로 새 설정 객체 생성
    if (baseConfig is KoMessageConfig) {
      return KoMessageConfig(
        showMessageBox: baseConfig.showMessageBox,
        enableInDebugMode: baseConfig.enableInDebugMode,
        packageId: finalPackageId,
        appName: finalAppName,
        mutexSuffix: mutexSuffix ?? baseConfig.mutexSuffix,
        windowTitle: windowTitle,
      );
    } else if (baseConfig is EnMessageConfig) {
      return EnMessageConfig(
        showMessageBox: baseConfig.showMessageBox,
        enableInDebugMode: baseConfig.enableInDebugMode,
        packageId: finalPackageId,
        appName: finalAppName,
        mutexSuffix: mutexSuffix ?? baseConfig.mutexSuffix,
        windowTitle: windowTitle,
      );
    } else if (baseConfig is CustomMessageConfig) {
      return CustomMessageConfig(
        customTitle: baseConfig.customTitle,
        customMessage: baseConfig.customMessage,
        showMessageBox: baseConfig.showMessageBox,
        enableInDebugMode: baseConfig.enableInDebugMode,
        packageId: finalPackageId,
        appName: finalAppName,
        mutexSuffix: mutexSuffix ?? baseConfig.mutexSuffix,
        windowTitle: windowTitle,
      );
    }

    // 기본값 반환
    return baseConfig;
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
