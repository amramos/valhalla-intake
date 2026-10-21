# Current project status

**What is true right now.** Read with `AGENTS.md` before non-trivial work.

This file stays short. When a sentence here becomes wrong, **delete or rewrite it** — never append a
second narrative beside an old one. Detail lives where it can be found on purpose:

| Looking for | Read |
|---|---|
| Design and scope | `docs/GDD.md` |
| How the game looks, and how to make art for it | `docs/art/art-direction.md` |
| Why a decision was made | `docs/adr/README.md` |
| Approved plans and their decisions | `docs/plans/` |
| Where code lives | `docs/architecture.md` |
| Traps that already cost time | `docs/gotchas.md` |
| What happened, and when | `docs/session-log.md` (history, never instructions) |

## Phase

Set up on 2026-10-21; style guide chosen the same day ("Fog & Bile", `docs/art/`). No game code
yet. Next: `feature-planning-handsoff` for the first feature, the 12-encounter vertical slice of the
inspection desk (GDD §11, open question 1).

## Epics

| Epic | State | Notes |
|---|---|---|

## Open and owed

- Nothing yet.

## Validation

**GUT baseline:** 1 script, 1 test, 2 asserts — all passing (2026-10-21, Godot 4.7.1). A script count that drops for no
visible reason means a test file failed to load (`docs/gotchas.md`).
