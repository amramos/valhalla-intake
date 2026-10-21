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

The vertical slice is built: 3 days, 12 encounters, from the title to the ending. It has one return
arc (Hakon), one god promise (Hel's offer for Ragna) and the endings Hel's tide and The Hall holds.
The plan and its decisions ledger (D1–D54) are in `docs/plans/vertical-slice-*`. Next: the owner
plays the slice, then sets the full encounter count (GDD §11, question 1).

## Epics

| Epic | State | Notes |
|---|---|---|
| #2 Vertical slice of the inspection desk | In Review | WP0–WP5 (#3–#8) merged by the hands-off lead under ADR-0007; WP6 (#9) is PR #17 |

## Open and owed

- **The owner's play of the slice** settles three things AI testers couldn't measure:
  - the 5:00 clock on days 2–3 (D42 is pending, D54);
  - the stamp's feel;
  - readability on a real screen.
- **GDD §11, question 1:** the full encounter count. `vertical-slice-measurements.md` recommends
  about 56.
- **Art provenance:**
  - the Z-Image Turbo model's licence is not recorded in the repository;
  - the art generation scripts live only in the local art working folder (`docs/art/slice-art-log.md`).
- **Parked from the evidence audit** (`vertical-slice-audit.md`):
  - remove the glint on Grim's face in the next art pass;
  - some lines sit flush at the 132 px cap;
  - Hakon's "Left the fight." could be made undeniable.

## Validation

**GUT baseline:** 29 scripts, 247 tests, all passing (2026-10-21, Godot 4.7.1, on the WP6 branch). A
script count that drops for no visible reason means a test file failed to load (`docs/gotchas.md`).
Other checks: lint, art coverage and `tools/desk_shots/`. The authoring check runs inside the
suite.
