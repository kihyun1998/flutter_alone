// Launches a built example app several times and checks that a duplicate
// launch loses to the running instance, and that the lock is free again once
// the running instance is killed.
//
// Usage: dart tool/two_instance_test.dart <path to example executable>
//
// Self-test contract, read by the example app:
//   FLUTTER_ALONE_SELFTEST=<status file>   turns self-test mode on
//   status file reads `acquired`           running instance holds the lock
//   status file reads `error <code>`       checkAndRun threw AloneException
//   exit code 3                            duplicate launch was refused

import 'dart:async';
import 'dart:convert';
import 'dart:io';

const String selfTestVariable = 'FLUTTER_ALONE_SELFTEST';
const int duplicateLaunchExitCode = 3;
const Duration stepTimeout = Duration(seconds: 60);
const Duration pollInterval = Duration(milliseconds: 200);

/// How long the running instance must outlive a refused duplicate launch.
const Duration settleTime = Duration(seconds: 3);

/// Output lines kept per launch, printed when a step fails.
const int outputTailLines = 40;

class StepFailure implements Exception {
  StepFailure(this.step, this.reason);

  final String step;
  final String reason;

  @override
  String toString() => 'FAIL $step: $reason';
}

class Launch {
  Launch._(this.name, this.process, this.statusFile) {
    process.exitCode.then((code) => exitedWith = code);
    for (final stream in [process.stdout, process.stderr]) {
      stream
          .transform(systemEncoding.decoder)
          .transform(const LineSplitter())
          .listen(_keep);
    }
  }

  final List<String> _outputTail = [];

  final String name;
  final Process process;
  final File statusFile;
  int? exitedWith;

  bool get isRunning => exitedWith == null;

  void _keep(String line) {
    _outputTail.add(line);
    if (_outputTail.length > outputTailLines) _outputTail.removeAt(0);
  }

  void printOutputTail() {
    stderr.writeln('--- $name output (last ${_outputTail.length} lines) ---');
    _outputTail.forEach(stderr.writeln);
  }

  static Future<Launch> start(
      String name, String executable, Directory statusDir) async {
    final statusFile = File('${statusDir.path}${Platform.pathSeparator}$name');
    final process = await Process.start(
      executable,
      const [],
      workingDirectory: File(executable).parent.path,
      environment: {selfTestVariable: statusFile.path},
    );
    return Launch._(name, process, statusFile);
  }

  String? readStatus() {
    if (!statusFile.existsSync()) return null;
    return statusFile.readAsStringSync().trim();
  }

  Future<void> kill() async {
    if (!isRunning) return;
    process.kill(ProcessSignal.sigkill);
    await process.exitCode.timeout(stepTimeout);
  }
}

Future<void> expectAcquired(String step, Launch launch) async {
  final deadline = DateTime.now().add(stepTimeout);
  while (DateTime.now().isBefore(deadline)) {
    final status = launch.readStatus();
    if (status == 'acquired') return;
    if (status != null && status.startsWith('error')) {
      throw StepFailure(step, '${launch.name} reported "$status"');
    }
    if (!launch.isRunning) {
      throw StepFailure(step,
          '${launch.name} exited with ${launch.exitedWith} before acquiring');
    }
    await Future<void>.delayed(pollInterval);
  }
  throw StepFailure(step,
      '${launch.name} did not report acquired within ${stepTimeout.inSeconds}s');
}

Future<void> expectDuplicateLaunch(
    String step, Launch duplicate, Launch running) async {
  final int code;
  try {
    code = await duplicate.process.exitCode.timeout(stepTimeout);
  } on TimeoutException {
    throw StepFailure(
        step,
        '${duplicate.name} still running after ${stepTimeout.inSeconds}s '
        '(status: ${duplicate.readStatus()})');
  }
  if (code != duplicateLaunchExitCode) {
    throw StepFailure(
        step,
        '${duplicate.name} exited with $code, expected $duplicateLaunchExitCode '
        '(status: ${duplicate.readStatus()})');
  }
  await Future<void>.delayed(settleTime);
  if (!running.isRunning) {
    throw StepFailure(
        step, '${running.name} exited with ${running.exitedWith} meanwhile');
  }
}

/// Runs [body], reporting any error it throws as a failure of [step].
Future<T> inStep<T>(String step, Future<T> Function() body) async {
  try {
    return await body();
  } on StepFailure {
    rethrow;
  } catch (error) {
    throw StepFailure(step, '$error');
  }
}

Future<void> run(String executable, Directory statusDir) async {
  final launches = <Launch>[];
  Future<Launch> start(String name) async {
    final launch = await Launch.start(name, executable, statusDir);
    launches.add(launch);
    return launch;
  }

  try {
    const step1 = 'step 1 (running instance acquires)';
    final first = await inStep(step1, () async {
      final first = await start('first');
      await expectAcquired(step1, first);
      return first;
    });
    stdout.writeln('ok step 1: first acquired');

    const step2 = 'step 2 (duplicate launch is refused)';
    await inStep(step2, () async {
      await expectDuplicateLaunch(step2, await start('duplicate'), first);
    });
    stdout.writeln('ok step 2: duplicate exited $duplicateLaunchExitCode, '
        'first still running');

    await inStep('step 3 (running instance is killed)', first.kill);
    stdout.writeln('ok step 3: first killed (exit ${first.exitedWith})');

    const step4 = 'step 4 (lock is free after kill)';
    await inStep(step4, () async {
      await expectAcquired(step4, await start('next'));
    });
    stdout.writeln('ok step 4: next acquired');
  } on StepFailure {
    for (final launch in launches) {
      launch.printOutputTail();
    }
    rethrow;
  } finally {
    for (final launch in launches) {
      try {
        await launch.kill();
      } catch (error) {
        stderr.writeln('cleanup: could not kill ${launch.name}: $error');
      }
    }
  }
}

Future<void> main(List<String> args) async {
  if (args.length != 1 || !File(args.single).existsSync()) {
    stderr.writeln('usage: dart tool/two_instance_test.dart <executable>');
    exit(64);
  }
  final statusDir =
      Directory.systemTemp.createTempSync('flutter_alone_selftest_');
  try {
    await run(File(args.single).absolute.path, statusDir);
    stdout.writeln('PASS');
  } on StepFailure catch (failure) {
    stderr.writeln(failure);
    exitCode = 1;
  } catch (error) {
    stderr.writeln('FAIL cleanup: $error');
    exitCode = 1;
  } finally {
    statusDir.deleteSync(recursive: true);
  }
}
