# Game UI overhaul — implementation plan

**State:** PROVISIONALLY APPROVED · **Ledger:** `game-ui-ledger.md`

This is the agents' document. Every requirement cites the ledger decision it comes from. A decision
that isn't in the ledger doesn't belong here.

## 1. Goals and non-goals

- **Goals:**
  - The built slice reads and feels like a game at a stone desk, under the three pillars (D1):
    the dead tell their tale, the stamp has weight, everything on screen is an object.
  - Nothing a player learned about how to play changes: the rules, the map, the font, the
    commands and the text harness's screens (D2, D3, D6, D44).
  - Verified by a blind critic, the desk-shots time budget, the audit kit, the fit check and the
    full GUT suite (D30, D46).
- **Non-goals:** new content or rules; days 4–8; "gods or monsters in disguise" (D29); a
  resolution or map change (D2); a second font file (D3); music; Steam; merging to `main` (D32).

## 2. Requirements (observable behavior)

Each requirement is a summary. **The ledger rows it cites are the full specification** and bind
the builder: where a number, a word or a condition is in the row and not here, the row wins.

### The tale
1. A soul's claim lines are written one at a time at the text speed (40 cps normal, 80 fast,
   instant), with a 0.25 s pause between lines, while its name plate lights, its figure bobs 1 px
   and voice blips play. The witness follows on its own sheet. One consumed click finishes every
   pending telling (at "instant" the telling ends by rule and no click is consumed). The telling
   replays after a restart. Lines are pinnable as they appear. The stamp can't be raised until the telling
   ends. The sheet, pace and blip rule are identical for every soul. (D4, D7, D37, D41)
2. The day clock does not run until the telling ends or is skipped; the mentor's guided steps wait
   too. (D5)
3. The claim sheet is headed by the soul's name; the witness sheet by the witness's name, with the
   description on hover; the Law by "Odin's Law". No "C1"/"W1" prefix shows on the desk. Decrees
   show roman numerals I–V, and L5 reads "…whatever I, III and IV say". Headings are full Ink.
   (D6, D33)
4. A thread's caption quotes words: an excerpt of each line's first words, width-measured, cut
   with ASCII "..." and extended until unique on the desk; body facts by their label; a grey
   thread's caption names both speakers. The same formatter feeds the desk and the text harness.
   (D6, D44)
5. Sheets are parchment with a torn edge and a heading rule, each line opening with a hanging
   straight quote; no edge crosses the text area or a hit rect; the per-line cap is re-measured
   by the fit check. (D8)
6. The Law is a scroll with wooden ends at 204×144 whose visible parchment grows with the decrees
   in force; the newest decree carries a 7×7 wax seal at its numeral until the day's first stamp;
   decrees wrap to at most 3 lines; a newly opened door shows freshly unbarred with "(NEW)" on
   hover. (D9, D33)

### The desk as a place
7. The clerk's note (the bottom edge of a parchment page) shows captions with a speaker mark:
   a pin in the thread's colour, the raven, the mentor's face, the black feather. Thread captions
   and Huginn's answers show within 0.2 s; mentor comments and citations write at 60 cps with a
   1 s maximum, and the 3 s hold starts when writing ends. Priority and take-over rules are the
   slice's. The note may take two lines. (D10, D43)
8. The HUD is objects: a candle that burns down with the clock with m:ss always beside it on timed
   days (blinking in the last 30 s; unlit with "untimed" on day 1), a quill with the feather
   count, a tally slate for the quota, raven marks on the post for answers left, a small book with
   a wax dot while a promise is open. All numbers readable at all times, on every day's band. (D11,
   D33, D39)
9. A pin head sits at each end of a thread; the thread is 3 px in all (core, highlight, halo) and
   draws taut in about 0.15 s with a tack; patterns per kind stay; the grey knot is an 8 px knot
   sprite; hovering a line underlines it; the first selected item shows a stuck pin in ember, and
   the cursor carries a pin while an item is selected and becomes a grab over the soul. (D12, D13)
10. A pin with no seam: the second pin pops out, the thread slackens and drops (0.4 s at most,
    interruptible, never blocking), a dull tick plays, the candle gutters with "-0:10" when
    charged, and the note writes "No seam between those two." (D36)
11. The body chart lies on a stone slab (rim and shadow outside the 128×100 chart and every hit
    area; no Ashen value in the rim). (D35)
12. Each soul's writ with its name lies under the doors. Clicking a door raises the stamp over the
    writ showing the realm's glyph and name with "?"; clicking the stamp (guarded) slams on press:
    a 2 px desk-band jolt settling within 100 ms, a 70 ms hold, the thud, the glyph inked in Ink
    on the writ; then the door flares and the soul walks into the light. Clicking elsewhere or
    right-clicking puts the stamp down. Drag onto a door previews and slams on drop. Nothing about
    the slam varies with the truth. (D14)
13. The next soul walks in from the left in 0.3 s while its sheet slides in; a click skips both.
    After a citation (or a day-1 warning) the soul, its lit pair, its writ and the feather stay
    until the player clicks the writ ("Send it on" on hover). (D15, D27)
14. On a citation the black feather falls from above onto the writ (0.5 s, one bounce) with a dry
    caw; its click target and the citation's accounting are live at once; clicking it lights the
    pair. (D16)
15. Hel's tide gains a figure at the slam (0.3 s at most, immediate under reduce motion),
    triggered by the committed stamp's increment. (D38)
16. The mentor blinks; Huginn tilts his head; a returned soul's frost glints; no glint touches
    evidence. The mentor's bubble is a drawn bubble with a tail, wide enough for "Stamp him." on
    one line, with a blinking arrow; the first click completes her reveal, a later click advances.
    (D17, D18)
17. Door glow pulses at 2 s or slower inside the doors' sprites; fog drifts in the band's corners as
    palette-safe frames; the band's background darkens one ramp value per day while doors, glyphs,
    light, the soul and plate, the raven, the bar and the HUD keep their values; the desk never
    changes lighting. (D19, D39)
18. Hover labels are small parchment tags with a pin, same text, same mouse-through. (D20)
19. Clicking the raven (bird and post) asks Huginn about the selected grey thread; hover gives the
    count, the precondition or the price; nothing is spent on a click with no selection or on a
    consumed skip click; the "Ask Huginn" button is gone. (D40)
20. While a thread's caption shows in the note, its pair lights on the desk, automatically. (D28)

### Between days and the shell
21. Dawn: the screen falls to Night with "DAY N" in carved capitals and a horn (1.5 s at most,
    skippable); then Odin's writ hangs by the doors with every D34 dawn fact in one short line each
    and "Begin" on its tab; clicking it begins the day. The D53 explanatory lines move to the mentor
    when they first matter, except the day-2 citation rule, which stays on the writ. (D21)
22. Dusk: the desk dims to candlelight; the day-book opens; citations and quota on the left page,
    the recap on the right; requests and the story beat on the next spread; "No citations today."
    never alone on a page; the dog-ear is labelled "Next", the ribbon "Skip all"; the recap keeps
    two phrasings; skipping records every request; the mentor's dusk comment is on the page under
    her mark or in her bubble. (D22, D34)
23. The ending: one of three tableaux on the gate band (figures marching from the bile door;
    empty benches under the ember door; the gate standing), then the day-book's last page with
    the carved outcome heading, one row per soul (stamped glyph and word, truth glyph and word, the
    record mark with its word, and when cited the black feather with "ignored"/"missed" after
    it (D47); "never judged"), the standing as a wax seal with the feathers and rank, "Play
    again" on a ribbon on the page. (D23, D34, D47)
24. Title: the gate with drifting fog and pulsing glow, the name in carved capitals, Start and Quit
    as parchment tags, a wind drone; Options reachable. (D24, D37)
25. Pause: dimmed desk, hanging parchment "Paused", tags for Resume, Options, Restart the run,
    Quit; confirms as a second tag row away from the opener, deliberate click only; Esc resumes.
    (D42)
26. Options: text speed, reduce motion (every decorative motion replaced by its end state; state
    cues kept), master volume, mute; saved in `user://options.cfg`; validated defaults. (D37)
27. Sound: synthesized by `tools/audio/synth_sounds.py` and credited; wind on the title and between
    days, a drone under the day-book, and at the desk only action sounds (blips, tack, pull, tick,
    slam, flare, caw, page, horn); the seam sound stays second loudest. (D25, D41)
28. Reserved colours as the art direction; the stamped glyph is Ink; ember accents only under
    `ui/**` (seal, selected pin). (D26)
29. Every telling, written reveal and dawn card is finished by a consumed click that never also
    acts; cosmetic drops are not consumers (D51); the slam is the one block, about 0.5 s with its
    flare; restart cancels every animation; forced time per honest soul stays at 2 s or less.
    (D27, D30, D51)
30. Titles use hand-placed pixel capitals drawn in code; m5x7 stays the only font file; capitals
    never appear on pinnable text. (D3)

## 3. Architecture

The command layer is untouched in shape: the desk's entities still read only `DeskCommands`'
getters and signals, and `DeskSystem` and `StampFlow` still connect them (slice D13; ADR-0005).
Presentation state that core never needs (a telling in progress, a slam, a falling feather) lives
in the entity or the system that owns it, never in `DeskCommands`; the one exception, the clock
waiting for the telling (D5), is a gate in `DeskSystem._process` like `awaiting_next()`, so the
text harness (which has no telling) is unchanged.

Pattern to follow: `entities/door/door.gd` (an entity that draws its own art and state, exposes
signals, and is wired by the system) and `systems/desk/stamp_flow.gd` (a system that owns one
verb's sequence with tweens and kills them on reset).

| Piece | Where | Kind | Replaces / adapts |
|---|---|---|---|
| `PixelCapitals` | `components/pixel_capitals/` | code-drawn 8×11 capital glyphs for titles (D3) | new |
| `Teller` | `components/teller/` | reveals a `Label`'s text at N cps with per-line pauses, blips and a "finish now" method; emits `finished` (D4, D10, D18, D43) | new |
| `ParchmentFrame` | `components/parchment_frame/` | draws a parchment sheet with a 1–2 px torn edge from a seed, never inside a given inner rect (D8) | new |
| `Options` | `core/options.gd` | text speed, reduce motion, volume, mute; load/save `user://options.cfg` with validated defaults and logged write failures; loaded once by the title and the desk on `_ready` and re-applied on every scene entry; on the web `user://` depends on browser storage, so a blocked store falls back to defaults (D37) | new |
| `SagaSheet` | `entities/evidence_panel/` | claim and witness sheets: speaker heading, hanging quotes, no ids, the Teller (D6–D8) | adapts `EvidencePanel` |
| `LawScroll` | `entities/evidence_panel/` | the scroll frame at 204×144, roman numerals, the wax seal, growing length (D9, D33) | adapts `EvidencePanel` (`wrap_lines` variant) |
| `ClerkNote` | `systems/caption_strip/` | parchment, speaker marks, instant vs written captions, hold after writing (D10, D43) | adapts `CaptionStrip`; priority logic unchanged |
| `Hud` | `entities/hud/` | candle, m:ss, quill count, tally slate, raven marks, book with wax dot (D11) | adapts `Hud`/`HudReadout` |
| `ThreadLine` | `entities/thread_line/` | pin heads, 3 px thread, taut tween, knot sprite, slack-drop on no seam (D12, D36) | adapts |
| `PinSelectable` | `components/pin_selectable/` | hover underline, the stuck pin on selection (D12) | adapts |
| `CursorSprite` | `components/cursor_sprite/` | an in-scene cursor on a top `CanvasLayer`, OS cursor hidden over the game; pointer, pin-carrying, grab (D13, D48) | new |
| `PresentationGate` | `systems/desk/presentation_gate.gd` | the one owner of "a presentation is in progress": tellers, written reveals, the dawn card, the slam, the walk; decides per click whether it is consumed as a skip or passed on as an action, exactly one of the two; pauses and resumes every registered teller, tween and player; cancels all on restart; exposes `gated_seconds()` for the time budget (D27, D37, D42, D51) | new |
| `Caption` | `systems/caption_strip/caption.gd` | a typed payload: text, priority, speaker mark, lit pair, reveal policy (instant or written) (D10, D28, D43) | new |
| `Writ` + `Stamp` | `entities/stamp_prompt/` | writ with the name, raised stamp with glyph and realm, the slam, the held writ's "Send it on" (D14, D15) | replaces `StampPrompt`'s label and button; `GuardedButton` semantics kept on the stamp |
| `StampFlow` | `systems/desk/` | captures the stamp context (soul, layers, realm, writ) before `commands.stamp()`, then the slam, the feather's fall, the tide's step from `StampResult.tide_delta` exactly once, the walk-in; `reset()` and `forget_run()` kill every tween (D14–D16, D38) | adapts; `StampResult` gains `tide_delta` and `departing_id` |
| `BodyChart` | `entities/body_chart/` | the slab (D35) | adapts |
| `WaitingSoul` | `entities/waiting_soul/` | walk-in, speaking bob, frost glint (D15, D17) | adapts |
| `MentorBubble` | `entities/mentor/` | drawn bubble, Teller, click-to-advance (D18) | adapts |
| `Door`, gate band | `entities/door/`, `scenes/desk/` | glow pulse frames, fog frames, per-day band recolour, raven click (D19, D39, D40) | adapts |
| `HoverLabel` | `components/hover_label/` | parchment tag with a pin (D20) | adapts |
| `DawnWrit` | `entities/phase_card/` | the dark "DAY N" card, then Odin's writ (D21) | replaces `PhaseCard` for dawn |
| `DayBook` | `entities/day_book/` | dimmed desk, open book, pages, dog-ear, ribbon, the ending's tableau and last page (D22, D23, D34) | replaces `PhaseCard` for dusk and ending |
| `PhaseFlow` | `systems/desk/` | same sequence drawn on `DawnWrit`/`DayBook` (D44) | adapts |
| `ScreenText` / `DeskText` / `DayRules` text | `core/`, `data/` | quoted-pair captions, roman numerals, ending rows with marks, the dawn writ's lines (D6, D21, D23) | adapts; the harness prints the same words |
| `TitleScreen`, `PauseOverlay`, `OptionsPanel` | `scenes/title/`, `entities/pause_overlay/`, `entities/options_panel/` | carved name, tags, fog and pulse; hanging parchment; the options (D24, D37, D42) | adapts / new |
| sound | `assets/audio/`, `tools/audio/synth_sounds.py` | synthesized set, credited; players in `desk.tscn` (D25, D41) | new |

Dependencies still point down: components know nothing of the desk; entities expose signals and
setters; systems connect them; `core/` stays scene-free and keeps every word the harness prints.

**Timing policy.** Simulation time (the day clock) advances only through `DeskCommands.advance_time`
from `DeskSystem._process`, gated by pause, `awaiting_next()` and the telling (D5). Presentation
time (tellers, tweens, audio) is owned by `PresentationGate`: the pause and focus loss stop it
through the gate, never through `SceneTree.paused` or `Engine.time_scale`; the slam's 70 ms hold is
a tween interval on the slam's own tween. Restart cancels everything the gate holds.

**Input contract.** Every mouse press reaches the gate first. If a consuming presentation is in
progress (a telling, a written reveal, the dawn card), the press finishes it and stops there. Else
the press reaches the desk's controls as today, and `_input_held()` still refuses pins and answers
under a pending stamp or a held writ. A consumed press also consumes its release (no drag can
start from it). During the slam window (from the stamp's press until the walk begins, about
0.5 s) the gate ignores presses outright: neither a skip nor an action, the one block (D27). The
walk itself is not a consumer: the next soul may arrive and be acted on during it. Double-clicks,
right-clicks and drag releases are tested in every presentation state: exactly one of skip, act or
ignore (slam window only) per press.

**Stamp lifecycle.** `StampFlow._commit` captures the stamp context (soul id, figure layers,
position, realm, the writ), takes the gate's slam lock, calls `commands.stamp()` (core records the
verdict and either seats the next soul or holds the desk), then runs the slam with the captured
context on the walk layer. The refresh that core triggers may already show the next encounter's
sheets, but `WaitingSoul.show_soul` places a new figure off-screen left and `StampFlow` calls
`soul.arrive()` (the walk-in) only when the slam lock releases, at the walk's start or on restart.
The tide's step and the feather's fall are driven from the `StampResult` the `stamped` signal
carries (`tide_delta`, `citation`), exactly once per stamp; a refresh never triggers them.

## 4. Preserve / adapt / replace / remove

- **Preserve:** every rule in `core/` and `data/` except the text changes below; `DeskCommands`'
  surface; the harness's commands; layout A3's rectangles (D2); m5x7 (D3); the body art, doors,
  portraits, name plates and backdrop (recoloured per day only in the band, D39); the seam sound
  and the thud (D25); the authoring check; the audit kit; the tests of core.
- **Adapt:** `EvidencePanel` → sheets and scroll; `CaptionStrip` → the note; `Hud`; `ThreadLine`;
  `PinSelectable`; `HoverLabel`; `StampFlow`; `WaitingSoul`; `MentorBubble`; `Door`; `BodyChart`;
  `PhaseFlow`; `TitleScreen`; `PauseOverlay`; `ScreenText`/`DeskText`; the desk-shots run, the
  fit check and the audit kit for the new objects; the integration tests that name the old text
  and controls (about 25–40 tests in 10–13 files, the skeptic's estimate).
- **Replace:** `StampPrompt` (writ and stamp); `PhaseCard` (dawn writ and day-book); the "Ask
  Huginn" and "Next soul" buttons (the raven; the held writ); the "NEW:" heading text (the seal).
- **Remove:** nothing a player could do before.
- **Data and content (migrated through the generator, never by hand):** `tools/content/content_souls.gd`
  carries authored seam captions and citation texts that name decree ids ("L3 sends her to
  Hel."); `content_text.gd` carries the dawn lines; `DeskText` carries "those two agree". All
  three are updated at the source (roman numerals in captions and in L5, "No seam between those
  two.", the dawn lines of D21) and `data/` is regenerated with `tools/content/build_content.gd`;
  a test asserts no "L<n>" survives in any displayed caption while harness commands keep ids
  (D6, D21, D36, D44). Also: L5's text (roman references, D6); the dawn lines moved to the mentor (D21);
  `assets/audio/*.wav` generated by the synth script and credited; the thud and seam `.ogg` files stay Kenney's (D25, D50); new art under
  `assets/art/ui/` (seal, pins, knot, tags, candle, slate, quill, book, writ, stamp, cursor,
  bubble, day-book pages, ribbon, dog-ear, tableau figures) and `assets/art/scenes/` (band frames
  per day, fog frames), all pixelforge-linted with canvases added to `pixelforge.toml` (ADR-0006).

## 5. Work packages (D45, D49)

Each is one stacked pull request carrying its own tests and its own GDD/ADR/doc amendments. Every
PR runs the gate (section 6) before review.

| WP | Builds | Depends on | Checkpoint |
|---|---|---|---|
| **WP1 - day 1 on the new desk** | `PresentationGate` with its input contract and tests; the stamp context in `StampFlow` and `StampResult.tide_delta`/`departing_id` with exactly-once tests; the populated day-3 fit fixture (`tools/fitcheck/`); `Teller`, `ParchmentFrame`, `Options` core (text speed and reduce motion respected; the panel comes in WP4); `SagaSheet` and `LawScroll` (frame, knotwork ends, roman numerals; the seal in WP3); `ClerkNote` with `Caption`; pins, 3 px thread, underline, stuck pin; the slab; the writ, the stamp and the slam; the shared caption formatter, L5 and the generator migration; the loop's synthesized sounds (blip, tack, pull, horn; the slam kept) and `tools/audio/synth_sounds.py`; the clock gate (D5). Scope: Ulf and Kolbeinn | - | The lead plays day 1 with real input; the fit check on sheets, note and scroll; the leak test; GUT green. Nothing else is built until this passes |
| **WP2 - the timed probe** | the candle HUD with every object of D11; the no-seam failure; the feather's fall and the dry caw; the held writ ("Send it on"); the walk-in and sweep; the tide's step at the slam; Sigvaldi with Bersi and Hakon admitted on the new desk; desk-shots instrumented with `gated_seconds()` | WP1 | The critic scores the desk mid-pin and the stamp on a hero and a liar, before/after; forced time at most 2 s per honest soul; the fit check on the HUD and the two-line note |
| **WP3 - the rest of the desk** | the wax seal and the growing scroll; the raven (click, marks, hover, the mentor's line); hover tags; `CursorSprite`; idles; glow pulse and fog frames; per-day band recolour with its contrast check; the mentor's bubble; frost glint; the day-3 fit re-run; the audit kit on the new desk | WP2 | The critic scores day 3 mid-pin; the audit kit's readability report; the fit check on all three days' bands |
| **WP4 - between days and the shell** | `DawnWrit`; `DayBook` with typed spreads, the ending's tableaux and last page with `EndingRow` marks (D47); the title; the pause parchment; the options panel; wind and drone; the two-page ending fit test; dawn lines moved to the mentor | WP3 | The critic scores dawn, dusk, the ending and the title; desk-shots plays title to ending |
| **WP5 - final verification and docs** | the critic over all six moments on a hero and a liar; a full-run timed play by the lead with the real clock (D46); the harness parity checks; `docs/current-status.md`, `docs/art/art-direction.md` (UI objects), docs cleanup; the story page. (The GDD and ADR amendments are made in WP1-WP4 by the package that introduces each change) | WP1-WP4 | Every gate green; the report |

## 6. Validation and checkpoints

- **Gate on every PR:** `gdformat --check` and `gdlint` on changed scripts; `pixelforge lint`;
  `godot --headless --import`; the full GUT suite (baseline 29 scripts, 248 tests, all passing on
  `main` 2026-10-23; the count must never drop unexplained); `tools/desk_shots/` passes and prints
  forced time per soul; the fit check images regenerated and read; the audit kit from WP3 on;
  `tools/ci/check_art_coverage.py`; the harness parity test.
- **Instrumented evidence, not prose:**
  - *forced time:* `PresentationGate.gated_seconds()` summed per encounter by desk-shots; the
    budget is at most 2.0 s per honest soul (D30);
  - *input contract:* a GUT test table of (presentation state x press kind) asserting exactly one
    of skip or act (D27, D51);
  - *stamp consequences:* a test that one stamp yields exactly one tide delta, one walk, and one
    feather when the stamp drew a citation (none otherwise), across ordinary, held, last-soul,
    clock-expiry and restart paths (D16, D38);
  - *audio events:* a test spy on the players asserting which sound played for pin, seam, no
    seam, slam, feather, page, horn, and that mute silences all (D25, D41);
  - *the leak test:* for every authored encounter, the telling's inputs (sheet, pace, blip rate,
    pitch) are a pure function of the soul's name and lines; a test diffs the telling of a liar
    and a hero with the same lines and finds no difference (D1, D4). Consequence presentations
    (the feather, the tide, the ending marks) are authorized to differ and are not in its scope;
  - *harness parity:* the harness prints the same caption, dusk and ending words as the desk's
    formatters, and no "L<n>" id appears in any displayed caption (D6, D44).
- **The critic (D30):** a model from another vendor, blind to the plan, scores before/after 1:1
  screenshots and desk-shots frame sequences of the six moments on a hero and a liar; each
  checklist item is scored 1-5 (every text block has a speaker or a material; no bordered
  rectangle of system text; every state change has motion and sound; numbers are objects; the
  stamp is the loudest moment; everything reads at 1:1; nothing differs between a liar and a hero
  before a thread). Pass: every item at least 4, and the leak item 5. Its report is posted in the
  PR.
- **Owner-played checkpoint:** after WP5 (or after WP1 if the owner is back): the owner's play is
  the final gate (D46); the ledger's "Assumed by the panel" list is their first read.

## 7. Parked

- "Gods or monsters in disguise": GDD §10 parked (D29).
- Per-day lighting beyond the band's recolour (full backdrops): parked until days 4–8.
- A text-size option: not offered at 480×270 (D37).

## 8. Traceability

| Requirement | Decisions |
|---|---|
| 1 | D4, D7, D37, D41 |
| 2 | D5 |
| 3 | D6, D33 |
| 4 | D6, D44 |
| 5 | D8 |
| 6 | D9, D33 |
| 7 | D10, D43 |
| 8 | D11, D33, D39 |
| 9 | D12, D13, D48 |
| 10 | D36 |
| 11 | D35 |
| 12 | D14 |
| 13 | D15, D27 |
| 14 | D16 |
| 15 | D38 |
| 16 | D17, D18 |
| 17 | D19, D39 |
| 18 | D20 |
| 19 | D40 |
| 20 | D28 |
| 21 | D21 |
| 22 | D22, D34 |
| 23 | D23, D34, D47 |
| 24 | D24, D37 |
| 25 | D42 |
| 26 | D37 |
| 27 | D25, D41, D50 |
| 28 | D26 |
| 29 | D27, D30, D51 |
| 30 | D3 |
| §3 architecture | D2, D44, ADR-0005 |
| §5 work packages | D31, D45, D49 |
| §6 validation | D30, D46, D1, D38, D51 |
| §7 parked | D29, D37 |
| delivery | D32 |
