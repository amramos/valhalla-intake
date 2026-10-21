# Vertical slice — implementation plan

**State:** PROVISIONALLY APPROVED · **Ledger:** `vertical-slice-ledger.md`

This is the agents' document. Every requirement cites the ledger decision it comes from. A decision
that isn't in the ledger doesn't belong here.

## 1. Goals and non-goals

- **Goals:**
  - A playable 3-day, 12-encounter slice of the inspection desk in Godot 4.7.1, with one return arc,
    one god promise and one ending consequence (D1–D3, D23).
  - Measurements that let the owner set the full encounter count (D12; GDD §11, question 1).
  - Playable by blind AI testers through a harness that shows only what the desk shows (D13).
- **Non-goals:**
  - Days 4–8, Rán and Loki's forgery.
  - Eyvind at the desk, and Ragnarök proper.
  - Saving (D14) and a settings menu (D31).
  - Ambience and music (D11).
  - An itch.io release.
  - Freyja's ask (D1).
  - The Cast down ending (D23).

## 2. Requirements (observable behavior)

### Structure
1. Three days of 4 encounters each, in the roster's order. Day 3's queue runs Freydis, then Hakon
   (returned) or Egil, then Ragna, then Ketil. (D1, D22, D25)
2. Each day opens with a dawn card showing the quota, the clock or "untimed", new decrees, newly
   opened doors and rule changes. The new decree and door carry "NEW" until the day's first stamp.
   (D34)
3. Quotas are 1, 1 and 2, all in data. Day 1 is untimed. Days 2 and 3 run a real-time clock (about
   5 minutes, in data) that only runs while a soul is at the desk. It pauses on Esc and when the
   window loses focus, and warns at 30 s. (D10, D22, D35)

### The desk (layout A3)
4. **Layout at 480×270.**
   - The gate band holds the doors, Huginn's perch, the waiting soul with its name plate, and the
     HUD in the top-right corner.
   - The desk band holds the body chart (left), claim and witness (centre-left), the Law (right)
     and a caption strip running to the right edge.
   - The mentor's portrait sits under the body chart. (D4, D21)
5. **HUD.**
   - The clock, feathers and Huginn's answers are icons with numbers, in parchment or grey; no
     reserved colour.
   - The ledger icon shows a badge while a promise is open.
   - Rank appears only at dusk and on the ending screen. (D21, D29)
6. **Doors.**
   - Each door shows its glyph and name on hover: Valhalla a spear, Hel a serpent, Fólkvangr a boar.
   - A locked door shows a bar and a dimmed glyph, and says "Closed until day N".
   - Hel's tide is drawn as 6 px figures at Hel's door, with empty slots up to the threshold.
     (D4, D21, D23)
7. **The body chart.**
   - Front and back views of a modular body: a base per build (as few builds as the matrix needs,
     D40) plus overlays.
   - Every fact, absences included, is a hit area of at least 8×8 px with a plain-language hover
     label.
   - Hands and clothes differ by shape.
   - Identity layers (head, hair) can't be clicked, and the standing soul shows nothing the chart
     doesn't.
   - A returned soul's change never uses bile.
   - The same back wound appears with two different verdicts, and a back wound alone never proves
     flight. (D5, D6)
8. **Text.**
   - One pixel font, licensed CC0 or OFL, carrying á, ó, ö and þ, readable at 1:1 (ADR-0008).
   - Claims run 3–4 lines and witnesses up to 3, with the per-line cap set by the fit check.
   - Decrees appear word for word as D32, wrapping to 2 lines where needed. (D7, D32)

### Pins and threads
9. **Selecting.**
   - Hovering an item shows its label.
   - The first click selects the item with a visible highlight.
   - Clicking it again, or right-clicking, cancels.
   - The second click makes a pin. (D8)
10. **Resolving a pin.**
    - A true seam draws a thread (red, grey or law) with a distinct line pattern, routed along
      panel edges and never across text.
    - Its caption says what it shows; a law thread names the destination, or says "the saga is
      true".
    - Re-pinning an existing pair is free and just highlights it.
    - A pin with no seam, red herrings included, shows "no seam" and visibly takes 10 s off the
      clock. (D8, D24)
11. **Grey threads and Huginn.**
    - A grey thread has an 8 px knot that selects it.
    - "Ask Huginn" (on day 3, below the HUD) answers which side lies, costs 5 s, and spends one of
      2 daily answers; a third answer costs 2 feathers.
    - The answer stays on its thread.
    - The HUD shows "extra answer: 2 feathers" by his icon.
    - A day-3 dawn card and one mentor line introduce him. (D8, D29, D30)
12. **Every pin is recorded,** so a wrong stamp is classed as *ignored* (the seam was pinned) or
    *missed*. (D8)

### Stamping and consequences
13. **Stamping.**
    - Clicking a door selects it and shows "Stamp <name> to <realm>?" with a separate confirm
      button. A double-click doesn't commit, and nothing hints at correctness.
    - Dragging the waiting soul onto a door shows the same preview; releasing on a door commits,
      and releasing elsewhere cancels.
    - Then a visual thud: a hold, a door flare, the soul walking through.
    - There is no undo. (D9)
14. **Citations.**
    - A stamp that breaks the Law where a seam was visible costs a citation: −2 feathers on days 2
      and 3, and only a mentor warning on day 1 ("from tomorrow this costs feathers").
    - The black feather stays on the desk until the next soul; clicking it shows its line and
      lights up the pair.
    - The line adds "You threaded it yourself" when the stamp was ignored.
    - An unresolved grey thread is permitted uncertainty: no citation, and the recap says "couldn't be
      proven at the desk". (D28, D33, D37; GDD §3.7)
    - Both lie seams (red, grey) and law threads count as seams for pins and citations. A law
      thread may confirm a saga ("the saga is true"). (D38)
15. **Feathers and rank.**
    - Start at 10.
    - Losses (citations, quota shortfall of −1 per missing soul) are capped at 5 a day.
    - Spends are never capped.
    - Meeting the quota pays +2. Rewards apply after the stamp's citation.
    - Demotion is checked after every feather change: at 0 the clerk drops a rank and refills to 5.
    - If the clock runs out mid-action, the action finishes first. (D35, D36)
16. **The mentor.**
    - She guides souls 1–3 with step prompts in a bubble by her portrait: read, then pin the pair
      she highlights (the player makes the pin), then stamp.
    - On soul 1 the pin is Ulf's claim against L1.
    - Afterwards she only comments, in the caption strip, telling an illegal stamp from a deliberate
      mercy, and each warning names the visible pair. (D16, D25)
17. **The caption strip.**
    - Priority runs citation, newest thread caption, Huginn's answer, then mentor comment.
    - Each message holds at least 3 s.
    - A deliberate click on a thread, the mentor or the feather takes the strip over and shows its
      text again. (D33)

### The arc, the promise and the ending
18. **The return arc.**
    - If Hakon (slot 6) was stamped to Hel, slot 10 is returned Hakon: a frost-burned name plate,
      and a dusk line "Hakon is back" at the end of day 2.
    - His one seam is a lie in a claim line (L2 sends him to Hel, or the player chooses mercy).
    - His lines differ depending on whether he was ignored or missed on day 2.
    - Otherwise slot 10 is Egil. (D2, D25, D32)
19. **Hel's offer.**
    - At dusk on day 2, Hel's offer names Ragna. It is recorded in the ledger even if dusk is
      skipped, and Ragna wears the serpent mark with a hover label.
    - Stamping her to Hel pays 4 feathers at the stamp, after the citation.
    - If she goes unjudged, the promise lapses and the ledger says so. (D3, D22, D29)
20. **Day-2 dusk** carries Eyvind's prayer, naming their father's ring, as its one story beat. (D1;
    GDD §6)
21. **Dusk.**
    - Cards with "Next" and "Skip all".
    - A summary of the citations already given, the quota result, a recap of up to 3 souls (what
      really happened), requests and the story beat.
    - Skipping hides nothing that has consequences. (D15)
22. **The slice ending,** on day 3's dusk.
    - Hel's tide is any soul not worthy of Hel that was stamped to Hel, threshold 3 (in data).
    - The hollow hall is any soul not worthy of Valhalla that was admitted to Valhalla, threshold 2
      (in data).
    - Otherwise The Hall holds.
    - The screen lists every encounter with verdict and truth, ignored or missed, and never-judged
      souls, names the souls that tipped the ending, shows feathers and rank as standing, and
      offers "Play again". (D23, D29)

### Shell, sound and harness
23. **Shell.**
    - Title: Start and Quit.
    - Esc opens a pause that dims the desk and offers Resume, Restart the run (confirmed, restoring
      the whole day-1 dawn state) and Quit (confirmed). (D31)
24. **Sound.** Two placeholder sounds, the stamp thud and "seam found", from a CC0 source and
    credited. Nothing else. (D11)
25. **The harness.**
    - A debug-only text harness drives the same commands and state as the UI: `describe`,
      `actions`, `act`.
    - It exposes only what the desk shows: never destinations, the seam list or truth.
    - It simulates elapsed clock time per action, and it can jump to any day and soul. (D10, D13)

### Content and verification
26. **Authored content.**
    - 12 roster encounters, plus Egil and two returned-Hakon variants, as typed `.tres` data.
    - Each holds facts, claim and witness lines, decree-checked seams and red herrings, the legal
      destination, the worthy destination and permitted uncertainty.
    - Every human detail sits in a pinnable line.
    - Content follows the evidence matrix (D39), which states each slot's acceptance seam:
      - **Ulf:** C1 against L1, a confirming law thread;
      - **Kolbeinn:** no wound against "cut down";
      - **Hallr:** a broken neck and no cut against a blade death;
      - **Asa:** nothing in hand against L3, "the saga is true";
      - **Sigvaldi:** a back-wound red herring, explained by his witness;
      - **Hakon:** admits leaving the line carrying Ivar, who is not his kin and is never carried
        in defence; L4 sends him to Hel (he grips a sword, so L3 doesn't apply); worthy of Valhalla on both days;
      - **Grim:** wet to the knee against "I never left the hill";
      - **Brand:** soft hands against "thirty winters at the oar";
      - **Freydis:** a back-wound red herring;
      - **returned Hakon:** one lie Hel taught him, in a claim line;
      - **Egil:** lies by L2, worthy of Fólkvangr;
      - **Ragna:** no lie seam; a law thread to L5; her night-shirt explained in her own claim;
      - **Ketil:** a body that fits Valhalla; only a grey thread decides him.
    - Slots 5–7 each carry a clearly different second fact.
    - Builders may change names and lines, never a slot's purpose or its acceptance seam. (D25,
      D27, D32, D38, D39)
27. **The authoring check** (a GUT test), on all content:
    - every citation-capable stamp has a visible valid pair;
    - every fact state has at least one seam use and one red-herring use in the slice;
    - the worthy door is open on that day;
    - law threads name destinations that match D32. (D6, D12, D25, D32)
28. **The evidence auditor** (a different model) sees only 1:1 desk screenshots and hover labels,
    absences included, for all 15 encounters (both Hakon variants and Egil included). It reports:
    - the seams it can see;
    - unreadable or unclickable hit areas;
    - law-thread wording that differs from the decree on screen;
    - unauthored visible seams.

    The lead settles each discrepancy against the evidence. (D26)
29. **The measurements log** records setup time apart from each encounter's writing, art,
    verification and rework, unused branches included. Authoring-check runs count as verification.
    Results are reported as ranges by case complexity. (D12)

## 3. Architecture

**Placement** follows `docs/architecture.md`. Dependencies point down: core ← data ← components ←
entities ← systems ← scenes.

- **`core/`** (pure, no nodes):
  - `run_state.gd`: the day, the queue, feathers, rank, the pins, the verdict record and the
    promise;
  - `pin_resolver.gd`;
  - `verdict_rules.gd`: citation, ignored or missed, permitted uncertainty;
  - `economy.gd`: the daily loss cap, spends and demotion;
  - `day_clock.gd`: real time plus action costs;
  - `ending_calculator.gd`;
  - `desk_commands.gd`: the one command layer that both the UI and the harness call (D13, D25);
  - plain typed classes for an encounter, a seam and a decree.
- **`data/`**: `Resource` schemas that convert to the core types, with `.tres` instances under
  `data/encounters/`, `data/days/` and `data/decrees/`. Tunables live here: clock length, costs,
  quotas, thresholds and Hel's reward (D10, D23, D29, D35).
- **`components/`**: a hover label, a fact hit area (at least 8×8), a pin selectable, and a drag
  source.
- **`entities/`**: the body chart, the door, the waiting soul, a thread line (with patterns and a
  knot), Huginn, the black feather and the mentor.
- **`systems/`**: the desk system (connects entities to the commands), the caption strip (D33),
  and the dusk sequence.
- **`scenes/`**: title, the desk, the dawn card, dusk cards, the ending and the pause overlay.
- **`tools/harness/`**: the headless text harness. It is never shipped; the export filter already
  excludes `tools/*`.
- **`assets/art/`**: the canvases in `pixelforge.toml`. New canvases (doors, overlays, portraits,
  icons) are added there first, each with a name and a size (ADR-0006).
- **`assets/audio/`**: the two sounds and their credits.
- **Patterns to follow:**
  - the GUT test style of `tests/unit/project_setup_test.gd`;
  - typed `Resource` data per `AGENTS.md`;
  - the export filter in `export_presets.cfg` (it already excludes `tools/`, `tests/` and
    `addons/gut/`).

### Preserve / adapt / replace / remove

| Item | Action | Note |
|---|---|---|
| `scenes/main.tscn` (setup placeholder) | replace | The title scene becomes the main scene |
| `tests/unit/project_setup_test.gd` | preserve | It stays in the suite |
| `pixelforge.toml` | adapt | Add canvases for doors, overlays, portraits and icons |
| `docs/GDD.md` §3.1, §3.7, §5 | adapt | Layout A3 (D4/D21); real-time clock (D10); decree wording (D32); claim lines 3–4 (D7) |
| `docs/art/frames/` | preserve | References only, never assets |

**Data and content migration:** none; this is the first content.

**New ADRs:**
- ADR-0007, agents merging reviewed PRs (D18), written at hand-off;
- ADR-0008, the pixel font (D7), in WP3.

## 4. Work packages

The packages are stacked: each one's branch starts from the previous one's.

| # | Package (issue) | Depends on | Delivers | Checkpoint |
|---|---|---|---|---|
| 0 | **The evidence matrix** (#3) | — | `docs/plans/vertical-slice-matrix.md` (D39): all 15 encounters slot by slot, plus a fact-state coverage table. The designer checks it against GDD §3.6 and D25/D32 | The designer's check passes. No content or art is built before this |
| 1 | **Playable slice: rules core, harness, minimal desk** (#4) | 0 | The `core/` rules, with GUT tests for every rule in §2.10–15 and §2.22; the data schemas; Ulf and Kolbeinn as data; the harness (§2.25); and a minimal desk scene with placeholder art: the body facts, claim and Law, click-to-pin with a thread and its caption, click-to-confirm stamping and the clock. The pixel font is chosen here (ADR-0008), so the D21 fit check uses it: a 1:1 screenshot of the longest matrix text, the five D32 decrees, the knots, both controls and the captions in layout A3 | **The lead plays it, and 3 blind AI playtesters play it through the harness. Content beyond 2 souls pauses until this passes** |
| 2 | **Art set** (#5) (runs in parallel with 1) | 0 | Through `comfyui-art` and pixelforge against `docs/art/`: a gate-band backdrop with no body; three doors with glyphs, each open and locked; the body bases the matrix needs, front and back; the overlays for the roster's facts; the waiting-soul figures; the mentor's portrait; Huginn; the black feather. HUD icons under 32 px are drawn by code. Canvases go into `pixelforge.toml`. Time is logged per asset | Lint clean, and seen at game scale in the desk |
| 3 | **Full desk UI** (#6) | 1, 2 | Layout A3 complete (§2.4–17): hover labels, thread patterns and knots, Ask Huginn, drag and confirm, the thud, the caption-strip priority, the name plate and Hel's mark, the tide figures, NEW marks, the mentor's bubble, the pixel font (from WP1) and the two sounds | Lead playtest; 1:1 screenshots reviewed |
| 4 | **Content and the authoring check** (#7) | 1 (its checkpoint passed) | The D32 decrees; all encounters (the 12, plus Egil and the Hakon variants); day configs; Hel's offer; Eyvind's prayer; the mentor's script; the authoring check (§2.27); the measurements log started (§2.29) | The authoring check passes; the encounter count logged |
| 5 | **Flow and shell** (#8) | 3, 4 | Title; dawn cards; dusk cards with the recap; the return arc and the promise wired end to end; the slice ending with "Play again"; pause and restart of the run; harness parity for every screen | Lead plays the full 3 days |
| 6 | **Verification** (#9) | 5 | The evidence auditor on every encounter (§2.28); a blind AI playtest of the full slice (§5); an exported-build smoke test; the measurements report; `docs-cleanup` | The report reaches the owner. The owner's play is the final gate (D27) |

## 5. Validation

- **Mechanics:** GUT tests per rule:
  - pin results for every thread kind and for no seam;
  - citation, ignored and missed, and permitted uncertainty;
  - the economy, including the cap, spends, demotion and reward order;
  - the clock, including action costs, pause and the horn mid-action;
  - quota results;
  - the promise kept, broken and lapsed;
  - both branches of the return arc;
  - ending thresholds and per-encounter counting;
  - restarting the run restores the full state.
- **Scenes and content:** the authoring check (§2.27); a desk scene smoke test; harness `describe`
  output checked against a list of what the desk shows (no destination, seam or truth fields);
  `pixelforge lint`; the fit-check screenshots.
- **Regressions:** the full GUT suite, hook tests, the sync check, and the export of both presets
  with the Windows build booted headless.
- **Played (D41):** 3 blind AI playtesters on different models per checkpoint, through the harness and screenshots. They
  report:
  - the goal and the best strategy;
  - which verdict mattered, why, and on what evidence, before any outcome is revealed;
  - three souls named from memory, unprompted;
  - whether they ever had to guess.

  Logged per run: time per soul, time left at each horn, feathers when entering day 3, whether the
  return arc fired, whether Hel's promise was kept, and whether Ketil was admitted with his grey thread
  unresolved (D37).

## 6. Traceability

| Decision | Observable behavior | Implementation area | Acceptance check |
|---|---|---|---|
| D1 | 3×4 roster order; no Freyja ask | data/days | Authoring check; harness run |
| D2 | Returned Hakon or Egil in slot 10; ignored and missed lines differ | core/run_state, data/encounters | GUT, both branches |
| D3 | Hel's offer at dusk on day 2 names Ragna; always in the ledger | systems/dusk, core | GUT; skip-all test |
| D4, D21 | Layout A3 with the HUD in the gate band and all fixes | scenes/desk, entities | 1:1 screenshots; fit check |
| D5, D6 | Modular body; at least 8×8 fact hit areas, absences included; each fact used as seam and red herring | entities/body_chart, data | Authoring check; auditor's unclickable report |
| D7 | Pixel font with á, ó, ö, þ; line caps from the fit check | scenes/desk, ADR-0008 | Fit-check screenshot |
| D8 | Select, cancel, re-pin, thread patterns, captions, knots, Ask Huginn, recorded pins | core/pin_resolver, entities/thread | GUT; lead playtest |
| D9 | Confirmed click and previewed drag; no undo; visual thud | components/drag, entities/door | Lead playtest; double-click test |
| D10 | Real time on days 2 and 3, untimed day 1, action costs, pause, focus pause | core/day_clock | GUT; lead playtest |
| D11 | Two CC0 sounds, credited | assets/audio | Credits file present |
| D12 | Measurements log with setup apart from per-encounter time | docs/plans | WP6 report |
| D13 | The harness shares commands; desk-only information; day and soul jump | core/desk_commands, tools/harness | describe() checked against the desk-visible list |
| D14 | No saving | — | — |
| D15 | Dusk cards, Next and Skip all; no consequence hidden | scenes/dusk | GUT and playtest |
| D16 | Mentor guides 3 souls by pairs; comments tell illegal from mercy | entities/mentor, data | Lead playtest; blind tester completes soul 4 alone |
| D17–D20 | Each merge runs team-lead-handsoff's checklist on that PR: CI green on its **latest commit**, a Codex **approve** verdict posted as a PR comment, the **exported-build smoke test passing on that branch**, and `main` tagged before the merge (ADR-0007) | process | The checklist is posted on every PR before it merges |
| D22 | Day-3 queue order; warning at 30 s; lapse rules | data/days, core | GUT |
| D23 | Ending by worthy destination, per encounter; thresholds in data; no Cast down ending | core/ending_calculator | GUT |
| D24 | Red herring gives "no seam" plus 10 s; explanation lives in the lines | core, data | GUT; auditor |
| D25 | The roster with its fixes | data/encounters | Authoring check; auditor |
| D26 | Evidence auditor report settled | WP6 | Report |
| D27 | Human detail in a pinnable line; the memory question; owner play | data, WP6 | Playtest report |
| D28 | Citations from day 2; day-2 quota 1; arc rate measured | data/days, core | GUT; playtest log |
| D29 | Hel pays 4 at the stamp; standing on the ending screen; feathers logged entering day 3 | core/economy, scenes/ending | GUT; log |
| D30 | Huginn's budget and introduction | core, scenes/dawn, mentor | GUT; playtest |
| D31 | Title, pause, restart of the run, quit, play again | scenes | GUT on restart state; playtest |
| D32 | Decree text verbatim; Ivar not kin; Hel's lie in a claim line | data/decrees, data/encounters | Authoring check |
| D33 | Caption priority, hold, re-show on click | systems/caption_strip | GUT; lead playtest |
| D34 | Dawn card and NEW marks | scenes/dawn | Playtest |
| D35 | Quotas 1, 1, 2 | data/days | GUT |
| D36 | Loss cap, spends, reward order, demotion, horn mid-action | core/economy, core/day_clock | GUT |
| D37 | Unresolved grey thread gives no citation and counts at the ending; recap wording | core/verdict_rules | GUT |
| D38 | Law threads and lie seams both count as seams; Ragna has no lie seam | core/pin_resolver, data | Authoring check |
| D39 | The evidence matrix comes before any build | WP0 | The designer's check |
| D40 | 10 feathers, +2 and −1; worthy door open; builds from the matrix | core/economy, authoring check | GUT; authoring check |
| D41 | 3 blind testers per checkpoint, plus the lead's own playtest | WP1, WP6 | Playtest reports |
| D42 | More than 30% clock left means the clock is tuned | data/days | Playtest log |
| D43 | Arc and promise rates are reported, not acted on | WP6 | Report |

## 7. Ways this could pass and still fail

- **A consistent answer-key puzzle that blind AI solves, but nobody feels they judged a death.**
  Caught by the human detail in a pinnable line (D27), the "which verdict mattered" and memory
  questions, and the owner's play as the final gate.
- **The text fits in data but not on screen.** Caught by the WP1 fit check, in the final font, before content (D7, D21).
- **Feedback exists but can't be seen at 1:1** (a 1 px thread). Caught by line patterns, knots,
  1:1 screenshots, and the auditor's unclickable report (D8, D26).
- **The harness leaks more than the desk shows,** so AI testers succeed where humans couldn't.
  Caught by the describe() check against the desk-visible list (D13).
- **The mentor covers for unclear affordances.** Caught by checking that blind testers complete
  soul 4 and day 2 without guidance (D16).
- **The clock never bites again** (GDD §12). Caught by logging time left at each horn; if careful
  testers keep more than 30%, the clock length in data is tuned before WP6 ends (D10, D42).
- **The return arc or the promise never fires.** Caught by measuring how often they fire and
  reporting it to the owner; mercy is a valid result (D2, D28, D29, D43).

## 8. Parked

- A scrollable Law for more than about 6 decrees (day 7).
- Freyja's ask.
- The Cast down ending and retrying a day.
- Saving and settings, text size included.
- Audio beyond the two placeholder sounds.
- The full encounter count (decided from this slice's measurements).
