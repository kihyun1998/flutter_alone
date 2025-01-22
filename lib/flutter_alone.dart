
import 'flutter_alone_platform_interface.dart';

class FlutterAlone {
  Future<String?> getPlatformVersion() {
    return FlutterAlonePlatform.instance.getPlatformVersion();
  }
}
