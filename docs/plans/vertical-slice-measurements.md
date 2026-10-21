# Vertical slice — measurements (D12)

What the slice cost to author, so the owner can set the full encounter count (GDD §11, question
1). Setup is logged apart from each encounter. Authoring-check runs count as verification (D12).
Results are reported as ranges by case complexity once WP6 adds the playtest time per soul.

## How these were taken

- One agent per pass, wall-clock minutes from the machine clock at the start and end of each
  phase. The per-encounter split is each soul's share of a phase's time, so values under a minute
  are estimates, not measurements.
- **Writing** is the matrix's new text per encounter (WP4 part 1, copied from the matrix's own
  Measurements section). **Data** is transcribing it into typed `.tres` through
  `tools/content/`. **Verification** is the authoring check and the scripted runs. **Rework** is
  changing content already written.

## WP4, 2026-10-21

### Setup (not per encounter)

| Item | Minutes | Notes |
|---|---|---|
| Matrix-pass setup (part 1) | 5 | From the matrix: reading D44-D51, the measuring tool, its first runs |
| Data-pass setup (part 2): reading the brief and the final matrix | 2 | |
| Schema and core text plumbing | 3 | Seam pair text, pronoun, dawn lines, red herrings; `DeskText`, `RecapWriter`, `Ledger` |
| The generator (`tools/content/build_content.gd`) | 2 | Save-by-reference fix after the first run embedded copies |
| The authoring checker and its broken-copy proofs | 5 | Built once; reused by every later run |
| Merging WP3 into WP4 and resolving the core conflicts | 3 | Mentor comments re-done to matrix A2 |

### Per encounter

| Encounter | Writing (min) | Data (min) | Verification (min) | Rework (min) | Notes |
|---|---|---|---|---|---|
| Ulf | 0.3 | 0.4 | 0.3 | 0.4 + 0.1 | Mentor script (4 steps); stamp step's door ruled from WP0 |
| Kolbeinn | 0.3 | 0.4 | 0.3 | 0.1 + 0.1 | Mentor script (4 steps) |
| Hallr | 0.3 | 0.4 | 0.3 | 0.2 | Mentor script (4 steps) |
| Asa | 0.2 | 0.2 | 0.3 | 0.4 | |
| Sigvaldi | 0.2 | 0.2 | 0.3 | 0.6 | Three red herrings |
| Hakon | 0.2 | 0.2 | 0.4 | 0.1 | Return-eligible; both return branches played |
| Grim | 0.2 | 0.3 | 0.3 | 0.2 + 0.1 | Seams reordered so A3's cited pair is the one a citation names |
| Brand | 0.2 | 0.3 | 0.3 | 0.3 | |
| Freydis | 0.2 | 0.2 | 0.3 | 0.1 | Three red herrings |
| Hakon, returned (both variants) | 0.3 | 0.3 | 0.4 | 0.1 | Two `.tres`, one spec |
| Egil | 0.2 | 0.3 | 0.4 | 0.1 | Fallback branch played to the ending |
| Ragna | 0.2 | 0.3 | 0.4 | 0.1 | Hel's mark; promise kept and broken runs |
| Ketil | 0.2 | 0.2 | 0.4 | 0.1 | The only soul that needs Huginn |
| Shared text (section A: pin results, citations, mentor, Huginn, dawn, dusk, recap, ending) | 2.5 | 1.5 | — | 1.0 | Mentor comments re-done after the WP3 merge |

**Verification runs:** the authoring check ran 7 times in the data pass (the first with a
broken-case fixture that was itself wrong; it passed on the real data from the second run).
Each full unit-suite run takes about 3 s, so verification time is reading results, not waiting.

**Totals for WP4:** about 14 minutes for the matrix pass (from the matrix) and about 21 minutes for
the data pass, setup included (15 of them setup). Per encounter, data plus verification ran
0.4-0.8 minutes; guided and branch souls cost the most.

**Unused branches:** returned Hakon (both variants) and Egil are authored in full, though one run
sees only one of the three; their minutes are included above.

**Fixed since:** Ulf's first mentor bubble (it wrapped to 6 lines in a 4-line bubble) was shortened
in the matrix and rebuilt. About 2 minutes of rework, which included giving every guided step a
spare line.

## The other passes, from the agents' run times (2026-10-21)

These are wall-clock minutes for each pass by a single agent, split evenly across the encounters it
covered, so they are rough.

| Pass | Total (min) | Per encounter (min, about) | Notes |
|---|---|---|---|
| WP0: the evidence matrix (design of all 15 variants) | 48 | 3.2 | The first full pass |
| WP0: rework from the gate check and four review rounds | 15 | 1.0 | Review found about 15 pairs that weren't strict contradictions, roughly 40% of the first draft's lie seams (D47) |
| WP2: art (one body build, 13 identity heads, overlays) | 46 | 1.5 (heads and overlays) | Includes two re-placement passes (D51) and the spear-wound redraw. Shared art (backdrop, doors, portraits) is setup |
| WP4: matrix text pass | 14 | 0.3–0.6 | From the table above |
| WP4: data and verification | 21 (15 of them setup) | 0.4–0.8 | From the table above |
| WP6: blind evidence audit | 5 | 0.3 | 14 encounters, one model |

**Blind playtest pace (WP6):** three AI testers took 164–266 s for all three days, about 13–22 s a
soul. That is the harness's pace, not a reader's: it says nothing about human reading time (see
`vertical-slice-playtest.md`).

## What an encounter costs

- **Per encounter, design through verified data and art:** about **6–7 agent-minutes**, with
  guided, branch and Huginn souls at the top of the range.
- **Fixed cost per batch:** about an hour of setup, first spent here, mostly reusable. It covers the
  schema, the generator, the authoring check, the art pipeline and the shared art.
- **The real cost is strictness, not typing.** A first draft gets about 40% of its lie seams non-strict,
  and only adversarial review caught them. The authoring check catches structure (pairs, coverage,
  widths, doors), not whether two lines can both be true.

**For GDD §11, open question 1 (the full count):** at this rate, a full game of 8 days × 7–9 souls
(about 56–70 encounters) is about 6–8 agent-hours of content and art. Then there is a review of
every encounter for strictness, at about 1 agent-minute each plus its rework. The owner's playtime
to judge feel and fairness is the bottleneck, not authoring. **Recommendation:** about 56
encounters (7 a day), written in batches of one or two days. Each batch gets the authoring check, a
blind strictness review and an evidence audit before the next starts. The decision stays the
owner's (GDD §11).
