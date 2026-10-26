# method-channel-contract

## The fact
The channel name `flutter_alone`, the method names `checkAndRun` and `dispose`, every argument key, and the meaning of the result (`true` run / `false` exit / error) are written separately in Dart and in each of the three natives, and must match in all four.

## Why it is cross-cutting
Dart and native code cannot share a source file, so each side carries its own string literals; nothing generates or checks them against each other (`lib/src/method_channel_keys.dart` doc says so). A key renamed on one side reads as *missing* on the other, and every native treats a missing key as a default — the call still succeeds with the wrong behaviour.

## Territories it holds in
Tool-visible part — the literals at each site: `git grep -nE "\"(checkAndRun|dispose|flutter_alone|windowTitle|mutexName|lockFileName|showMessageBox|title|message)\"" -- lib windows linux macos`.
- [dart-api](../territory/dart-api.md) — `MethodChannelFlutterAlone._channel`, `invokeMethod('checkAndRun')`, `invokeMethod('dispose')`
- [configuration](../territory/configuration.md) — `MethodChannelKeys` (the Dart side's one copy)
- [already-running-dialog](../territory/already-running-dialog.md) — `MessageConfig.toMap` keys
- [plugin-registration](../territory/plugin-registration.md) — the channel name in each registrar: `kChannelName` (Windows `flutter_alone_plugin.h`, Linux `flutter_alone_plugin.cc`), `channelName` (Swift)

Hand-written part — what each native reads:
- Windows `ParseCheckAndRunArgs`: `windowTitle`, `mutexName`, `showMessageBox`, `title`, `message`.
- Linux `handle_check_and_run`: `lockFileName` (required), `showMessageBox`, `title`, `message`.
- macOS `handle(_:result:)`: `lockFileName` (required), `showMessageBox`, `title`, `message`.
- Sent and read by no native: `enableInDebugMode` (consumed in Dart before the call), `type`, `customTitle`, `customMessage`; `windowTitle` on Linux/macOS.
- Error codes differ: Windows `BAD_ARGS`, `INVALID_ARGUMENT`, `MUTEX_ERROR`; Linux `INVALID_ARGUMENT`, `IO_ERROR`; macOS `INVALID_ARGUMENT`, `IO_ERROR`.

## What a violation looks like
A renamed key: Windows reads an empty `mutexName`, `Acquire` returns `kInvalidName`, and `checkAndRun` fails with `INVALID_ARGUMENT` (an `AloneException`) on every launch. Linux/macOS return `INVALID_ARGUMENT` for a missing `lockFileName` (an `AloneException`). A renamed `title`/`message` gives an empty dialog.

## Discovery history
- `method_channel_keys.dart` was introduced to centralize the Dart side and its doc names the native copies (commit 6339811, #5/F5).
- Reading 2026-10-24: the per-native key lists above.

## Where it will recur
Any change that adds, renames or drops a value in a `toMap()`, or a lookup in a native handler, is subject to this: grep the key in `lib/`, `windows/`, `linux/` and `macos/` and change all four.
