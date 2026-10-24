# already-running-dialog

## What it is
The message a duplicate launch shows when it cannot bring the first instance forward: the text is resolved once in Dart, and each platform only displays it, synchronously, before the duplicate exits.

## Governing decisions
**None.** ADR-0001 named the duplicated per-platform strings as a negative consequence; that consequence was removed by commit b8c1561 (#17, "make Dart the single source of truth for dialog strings"), and no record states the new rule.

## Design model
From the source:
- `MessageConfig` resolves `title` and `message`: `KoMessageConfig` (`알림` / `이미 다른 계정에서 앱을 실행중입니다.`), `EnMessageConfig` (`Notice` / `Application is already running in another account.`), `CustomMessageConfig` (empty values fall back to English). The map carries `type`, `showMessageBox`, `title`, `message`, and for custom also `customTitle`/`customMessage`.
- Natives read only `showMessageBox`, `title`, `message`; `type`, `customTitle` and `customMessage` are sent and read by no platform.
- Display is modal and blocking everywhere: `MessageBoxW` with the exe's icon set through a thread-local `WH_CBT` hook (Windows), `gtk_dialog_run` (Linux), `NSAlert.runModal` (macOS).
- The default text says "another account" even when the running instance is the same user's and simply could not be activated.

## Code
- `lib/src/models/message_config.dart — MessageConfig`, `KoMessageConfig`, `EnMessageConfig`, `CustomMessageConfig`
- `windows/flutter_alone_plugin.cpp — ShowAlreadyRunningMessage`, `ShowMessageBox`; `windows/icon_utils.cpp — IconUtils::GetAppIcon`; `windows/message_utils.cpp — MessageUtils::Utf8ToWide`
- `linux/flutter_alone_plugin.cc — show_message_dialog`, `notify_already_running`
- `macos/Classes/FlutterAlonePlugin.swift — showAlreadyRunningAlert(title:message:)`
- Tests: `test/config_test.dart` (MessageConfig group), `windows/test/message_utils_test.cpp`

## Reference behaviour
**None.**

## Cross-cutting invariants
- [method-channel-contract](../invariant/method-channel-contract.md)
- [duplicate-launch-is-never-silent](../invariant/duplicate-launch-is-never-silent.md)

## Blast radius
- [activation-windows](activation-windows.md), [activation-linux](activation-linux.md), [activation-macos](activation-macos.md) — the dialog is each one's failure branch; what counts as "activated" decides whether it shows.
- [shipping](shipping.md) — default strings are user-visible; a change is a CHANGELOG entry (4.1.0 recorded the Windows title change).

## Known holes / open
- The Linux and macOS natives fall back to an empty title/message when the keys are missing; Windows to empty `std::wstring` — harmless only while Dart always sends them.
- ADR-0001's "Negative" paragraph still describes duplicated strings and macOS not honouring the message config; both are fixed (b8c1561, 363cf8b).
- CHANGELOG 4.1.0 "Internal" still mentions "per-platform message tables" extracted as seams; the tables were removed by b8c1561.
