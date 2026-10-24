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
arc (Hakon), one god promise (Hel's offer for Ragna) and three endings: Hel's tide, the Hollow hall
and The Hall holds. The plan and its decisions ledger (D1–D54) are in `docs/plans/vertical-slice-*`.

The game UI overhaul (epic #19) re-presents that slice as a game at a stone desk: the dead tell
their tale line by line, the Law is a sealed scroll, the stamp slams a writ, dawn is a carved card
and Odin's writ, dusk and the ending are the clerk's day-book, the title and pause are the gate and
a hanging parchment. The owner played it on 2026-10-24 ("a very substantial improvement, and
actually enjoyable to play") and had it merged to `main` (#25–#30). Its ledger (D1–D58) and plan
are `docs/plans/game-ui-*`; its rules are ADR-0009. Next: the owner rules on the ledger's assumed
decisions and D57, then sets the full encounter count (GDD §11, question 1).

## Epics

| Epic | State | Notes |
|---|---|---|
| #2 Vertical slice of the inspection desk | In Review (until the owner plays it) | WP0–WP6 (#3–#9) merged by the hands-off lead under ADR-0007 |
| #19 Game UI overhaul | In Review (merged 2026-10-24 after the owner's play) | WP1–WP5 (#20–#24) built by the team under `team-lead`; Codex reviewed each, a fallback Claude model where Codex's quota ran out; the blind critic's scores are in each PR |

## Open and owed

- **From the owner's play (2026-10-24), parked:** some over-spelling and walls of text remain from
  the original slice; no action for now.
- **Still the owner's to settle on later plays:**
  - the 5:00 clock on days 2–3 (slice D42 pending, D54) against the telling's pace: the timed
    careful-player run is recorded in the UI ledger's "Built" section as a measurement;
  - the stamp's feel: the UI ledger's D57 leaves the next step to the owner (keep the stamp as
    built, or move the writ onto the desk for a bigger one);
  - readability on a real screen at 1:1, including m5x7's capital N, which reads as a Π when
    zoomed;
  - the UI ledger's assumed decisions (D4, D5, D21, D25, D32, D37), the owner's first read.
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

**GUT baseline:** 29 scripts, 248 tests on `main` (2026-10-21); **81 scripts, 733 tests** at the
top of the UI stack (2026-10-24, Godot 4.7.1). A script count that drops for no visible reason
means a test file failed to load (`docs/gotchas.md`). Other checks: lint, pixelforge, art coverage,
the sound self-check (`tools/audio/synth_sounds.py --check`), the fit check (`tools/fitcheck/`),
`tools/desk_shots/` (prints the forced seconds per soul, budget 2.0), the audit kit
(`tools/audit_kit/`) and the timed careful-player run (`tools/timed_play/`). The authoring check
runs inside the suite.
