<!-- grill-map build stamp: 8e5a943 -->
<!-- grill-map synced at: ddf10d7 (2026-10-24) -->

# Territory map

The territory map. A comment's why, trap and measured value go to a note here.
Notes are added as they come up, or all at once with `grill-map`, which also
reads hand-written notes as leads and keeps their paths.

## What it answers
- **If I touch this, what else moves?** Open the territory that owns the code, then follow its `## Blast radius` and `## Cross-cutting invariants`.
- **What decision is this shape derived from?** Open its `## Governing decisions`. A **None.** there is the answer: nothing recorded decides it.

## How to read it
- `## Blast radius` is a checklist: each edge names the shared assumption that can break over there. An edge with nothing to do for your change is a correct outcome.
- Invariant notes hold a fact that must stay true at several sites that do not share code; change one site, check them all.
- Every claim carries its evidence (a symbol, a commit, a record) or its source and date `(maintainer, yyyy-mm-dd)`.
- Conventions: symbols, never line numbers; plain relative links; a fact another file owns is linked, not copied; empty sections say **None.**
- Source files and issues are text inside notes, not nodes — the map cannot list "every note that mentions file X" except by grep.

## The shape of the repo
A Flutter desktop plugin with a thin Dart surface and three independent native implementations ([ADR-0001](../adr/0001-per-platform-single-instance-strategy.md)). A launch serializes a config, crosses one method channel, and the native side takes a kernel-backed lock (Windows named mutex; Linux/macOS `flock` on a temp-dir file). On contention it tries to bring the running instance forward, else shows a dialog, and the Dart caller exits. The largest gap: activation and dialogs are verified only by reading and manual runs, and two real instances are run against each other only on Linux CI ([ci](territory/ci.md)).

## Territories
- [dart-api](territory/dart-api.md)
- [configuration](territory/configuration.md)
- [instance-lock-windows](territory/instance-lock-windows.md)
- [instance-lock-linux](territory/instance-lock-linux.md)
- [instance-lock-macos](territory/instance-lock-macos.md)
- [activation-windows](territory/activation-windows.md)
- [activation-linux](territory/activation-linux.md)
- [activation-macos](territory/activation-macos.md)
- [already-running-dialog](territory/already-running-dialog.md)
- [plugin-registration](territory/plugin-registration.md)
- [shipping](territory/shipping.md)
- [ci](territory/ci.md)
- [example-app](territory/example-app.md)

## Cross-cutting invariants
- [method-channel-contract](invariant/method-channel-contract.md)
- [name-validation-mirror](invariant/name-validation-mirror.md)
- [lock-file-ownership](invariant/lock-file-ownership.md)
- [duplicate-launch-is-never-silent](invariant/duplicate-launch-is-never-silent.md)

## Scope
Maps the plugin, its example, its release and its CI. Out of scope: agent tooling (`.claude/`, `docs/agents/`), the personal VM notes in `ubunt.md`, and generated `ephemeral/` directories. A territory appears when something in the repo commits to it — code, a decision record, or an open issue with a design; an absent note means nothing has yet. A new native platform, or a new mechanism on an existing one, is owed a note.
