import 'package:plugin_platform_interface/plugin_platform_interface.dart';

import 'flutter_alone_method_channel.dart';

abstract class FlutterAlonePlatform extends PlatformInterface {
  /// Constructs a FlutterAlonePlatform.
  FlutterAlonePlatform() : super(token: _token);

  static final Object _token = Object();

  static FlutterAlonePlatform _instance = MethodChannelFlutterAlone();

  /// The default instance of [FlutterAlonePlatform] to use.
  ///
  /// Defaults to [MethodChannelFlutterAlone].
  static FlutterAlonePlatform get instance => _instance;

  /// Platform-specific implementations should set this with their own
  /// platform-specific class that extends [FlutterAlonePlatform] when
  /// they register themselves.
  static set instance(FlutterAlonePlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<String?> getPlatformVersion() {
    throw UnimplementedError('platformVersion() has not been implemented.');
  }
}
