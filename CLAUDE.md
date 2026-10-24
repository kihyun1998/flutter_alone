# CLAUDE.md

## Agent skills

### Issue tracker

Issues are tracked in this repo's GitHub Issues via the `gh` CLI; external PRs are not a triage surface. See `docs/agents/issue-tracker.md`.

### Triage labels

Five canonical triage roles, each mapped to its default label string (`needs-triage`, `needs-info`, `ready-for-agent`, `ready-for-human`, `wontfix`). See `docs/agents/triage-labels.md`.

### Domain docs

Single-context: one `GLOSSARY.md` + `docs/adr/` at the repo root. See `docs/agents/domain.md`.

## Comments

A comment says what the code is. Why it is this way, what it deliberately leaves out, the trap and the measured value go to the territory note under `docs/map/`. Where none seems to hold it, search the folder and the code symbol first; only then start a new note, named for what the system does there, not for the file. History goes to the commit message. Comments written before this rule still carry the rest: never delete one whose content the map does not yet hold — move it first (`decant`).

## Territory map

The map lives in [`docs/map/`](docs/map/README.md). Read it before designing a change: open the territory that owns the code and work through its `## Blast radius` and `## Cross-cutting invariants`. After the change lands, update the notes it made false. When a fix reveals a fact, ask whether it holds at every site that shares the same assumption (e.g. every native handler, or both Unix lock-file implementations); if yes, the fix lands with an invariant note.
