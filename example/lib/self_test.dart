import 'dart:io';

import 'package:flutter_alone/flutter_alone.dart';

/// Self-test mode, on when `FLUTTER_ALONE_SELFTEST` names a status file.
///
/// Driven by `tool/two_instance_test.dart`, which owns the contract.
class SelfTest {
  static const String variable = 'FLUTTER_ALONE_SELFTEST';

  /// Exit code of a duplicate launch in self-test mode.
  static const int duplicateLaunchExitCode = 3;

  static final String? _statusPath = Platform.environment[variable];

  static bool get enabled => _statusPath?.isNotEmpty ?? false;

  static void reportAcquired() => _write('acquired');

  static void reportError(AloneException error) =>
      _write('error ${error.code}');

  static void _write(String status) {
    File(_statusPath!).writeAsStringSync(status, flush: true);
  }
}
