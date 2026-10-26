# dart-api

## What it is
The package's public Dart entry point and its transport: `FlutterAlone.instance.checkAndRun(config:)` decides whether this process may start, `dispose()` gives the lock back, and both cross to native code over one method channel. It also owns the debug-mode short-circuit and the mapping of native errors to `AloneException`.

## Governing decisions
[ADR-0001](../../adr/0001-per-platform-single-instance-strategy.md) — the platforms are unified *only* at this Dart surface; everything platform-specific stays native.

## Design model
From the source and ADR-0001:
- In a debug build `checkAndRun` returns `true` without calling native code unless `DuplicateCheckConfig.enableInDebugMode` is set (`lib/flutter_alone.dart — FlutterAlone.checkAndRun`).
- A `null` native result asserts in debug and is read as **cannot run** in release (`MethodChannelFlutterAlone.checkAndRun`) — safety first: the caller is expected to `exit(0)` on `false`.
- Any `PlatformException` becomes `AloneException(code, message, details)`, with a default message when the native side gave none. Native `false` and native error are two different outcomes; a caller that only checks the bool treats an error as an exception, not as "already running".
- `FlutterAlonePlatform` is a `PlatformInterface` with a verified token, so a fake can replace the method channel in tests (`test/flutter_alone_test.dart`).

## Code
- `lib/flutter_alone.dart — FlutterAlone.checkAndRun`, `FlutterAlone.dispose`, the barrel exports
- `lib/flutter_alone_platform_interface.dart — FlutterAlonePlatform`
- `lib/flutter_alone_method_channel.dart — MethodChannelFlutterAlone.checkAndRun`, `.dispose`
- `lib/src/models/exception.dart — AloneException`

## Reference behaviour
- Flutter plugin docs (docs.flutter.dev, summarized — binding per [thegraph.md](../../agents/thegraph.md)): the platform-interface + method-channel shape. Never compared line by line.

## Cross-cutting invariants
- [method-channel-contract](../invariant/method-channel-contract.md)

## Blast radius
- [configuration](configuration.md) — `checkAndRun` sends whatever `config.toMap()` returns; a change in what the transport expects (a key, a null) must match what serialization produces.
- [plugin-registration](plugin-registration.md) — the channel name `flutter_alone` here must equal the name each native registrar opens.
- [example-app](example-app.md) — the example is the only in-repo caller, and `checkAndRunOrExit` shows the exit-on-`false` contract consumers copy; its two-instance test fails if `checkAndRun` stops returning `false` to a duplicate launch.
- [shipping](shipping.md) — this is the published API; any signature change is a semver decision recorded in `CHANGELOG.md`.

## Known holes / open
- What a caller should do with an `AloneException` is not documented next to the bool contract; the README example only handles `false`.
