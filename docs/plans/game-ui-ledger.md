# Game UI overhaul — decisions ledger

**State:** BUILT (WP1-WP5, stacked PRs #26-#30 on the plan's #25), unmerged: awaiting the owner's play and merge
**Mode:** hands-off · **Plan:** `game-ui-plan.md` · **Epic:** [#19](https://github.com/amramos/valhalla-intake/issues/19) (features #20-#24)
**After the plan:** the owner chose `team-lead-handsoff` (2026-10-23). See D-row on delivery.

This is the owner's document: read this, not the plan. Every decision the plan relies on is a row
below; the plan cites these ids, and a reviewer checks that it holds every decision and invents none.

## Intent

- **Problem observed (the owner, 2026-10-23):** the slice is fully playable, but visually it is a
  wall of text that looks and feels like a web page: flat parchment rectangles with numbered lines
  ("C1 Speared, in battle."), a black caption bar of system text, a dark modal card with "Next" and
  "Skip all" for dawn and dusk, and an ending that is a list of lines in a box. Papers, Please is
  text-heavy too, but its text is diegetic (in papers you handle) and intentional (bureaucracy is
  the point). Ours is neither yet.
- **Player promise after the change:** a soul stands at the gate and tells you its saga; you read
  its body on the slab and pin its words against Odin's sealed Law with real pins and thread; you
  stamp its writ with a slam you feel; a black feather falls when you break the Law; the day ends
  with a candle and the clerk's day-book, not a dialog box. Everything you read is an object on a stone
  desk eight days before the end of the world.
- **Stays familiar:** the rules (GDD §3 as built), the desk's map (layout A3: D4, D21, D51), the
  reading font (ADR-0008), every verdict hinging on a visible contradiction, the clock, quota,
  citations and endings. Nothing a blind tester learned about *how to play* changes.
- **Replaced or removed:** the flat panels, the "CLAIM/WITNESS/LAW" headings and the "C1/L1"
  prefixes on the desk, the black caption strip, the HUD box, the "Stamp X to Y?" text prompt, the
  dark phase cards, the list-ending, the "Ask Huginn" and "Next soul" buttons.
- **Not doing (non-goals):** new content or rules; days 4–8; "gods or monsters in disguise" (a
  content idea the owner raised, parked in the GDD); a resolution change; voice acting; music beyond
  ambience; Steam.
- **Cost:** amendments to D10 (the clock during the telling), D11 (sound), D21 (the HUD), D31
  (a small options panel), D33/D34 (captions and the dawn card), D15/D23 (dusk and the ending as
  the ledger), D8's "Ask Huginn" control; GDD §3.1, §3.7, §3.10, §7, §8 amended; most UI tests and
  the desk-shots run rewritten for the new objects; every text harness screen unchanged in words
  (D13) but the desk's captions reworded to quote lines instead of ids.

## The three pillars

Every decision in this feature is tested against these. The owner gave the first two; the panel
refined them and defined the third.

**P1 — The weight of the stamp.** Every verdict is a moral act with a cost you can see. The Law and
the truth pull apart: the heroic who fail Odin's letter, the qualified who deserve it less, the ones
who game it. The stamp is final and physical, the loudest moment in the game, and what it costs (a
black feather, a figure joining Hel's tide, a frost-burned name plate coming back) lands where you
can see it. *Tie-breaker (player advocate): the 12th soul must feel faster than the 1st, so the
polish never slows the loop.*

**P2 — The dead tell their tale.** A soul stands before you and speaks its saga, with pride, fear
or cunning, in its own voice. It is not a form. The claim arrives as speech, headed by the soul's
name, with no "C1". The witness is another dead person speaking. The Law is Odin's word, carved and
sealed, not a list. Every caption is said by someone: the mentor, the raven, or the clerk's own hand
in the ledger.

**P3 — A desk at the end of the world.** Everything the player reads or touches is an object on
the desk at Valhalla's stone gate, eight days before the end: parchment, wax, feathers, a candle, a
raven, doors that glow in the cold. Nothing is a window on a page. Heroism is read, not told: a
wound in the chest and a sword still gripped say more than words, and the ember door is the prize
you can see. Days pass as light, sound and a ledger closing, never as a dialog box.

**Where the heroism feeling comes from** (the owner's question): from the body on the slab (a death
faced, a weapon kept); from the telling (the saga's voice, cadence and the soul's name over it);
from the Law's confirmation lighting the ember door's glyph when a thread says "the saga is true";
from the passage (the door flares, the horn, the soul walks into the light); and from the dusk
epitaphs and the names at the ending, written like a saga in the clerk's day-book. The liar's crack,
a red thread pulled taut against the body, makes the hero stand out by contrast.

## Decisions

Panel: designer (Claude Fable), player advocate (Claude Opus), skeptic (GPT via Codex); the lead
is this session. "panel" means unanimous or the lead's resolution of a split (the dissent is named).

| Id | Question | Answer | Decided by | Date |
|---|---|---|---|---|
| D1 | The pillars | P1–P3 as written above, with three amendments: P1 gets the tie-breaker "the 12th soul must feel faster than the 1st" (player); P2 gets "the telling never tells: voice, pitch, cadence and sheet are the same for a liar and a hero; only the words and the body differ" (designer, D45); P3's "heroism is read" keeps GDD §3.2's limit: the body shows events, not motives (skeptic). Words: the caption strip becomes the **clerk's note**, the dusk book the **day-book**; "Ledger" keeps its one meaning, the tray of god requests (skeptic) | panel | 2026-10-23 |
| D2 | Resolution and map | 480×270 and layout A3's geometry stay (D4, D21, D51 of the slice). Materials, text treatment, feedback, motion, sound and the between-day screens change; the map does not. The populated day-3 fit check (slice D21) is repeated on the new materials before final assets, against D49–D52 | panel | 2026-10-23 |
| D3 | Type | m5x7 stays the one font file (ADR-0008). Titles (the game's name, "DAY I–III", "Dusk", the endings' names, realm names on the stamp) use **hand-placed pixel capitals** drawn in code (about 8×11 px), never a second font file and never on anything pinnable. Rejected: an OFL display font (licensing, glyph and download work; skeptic) | panel | 2026-10-23 |
| D4 | The telling | The claim's lines are written one at a time at 40 characters a second with a 0.25 s pause between lines, while the soul speaks: its name plate lights, its head bobs 1 px, and a voice blip plays at a pitch derived from a hash of the soul's name (never an authored field, so it can't encode honesty). Any click finishes every pending telling at once; that click is consumed. Lines are pinnable as they appear; the stamp can't be raised until the telling ends. The sheet is the same for every soul. On a soul's second showing (a restart) the telling still plays, since any click ends it. Dissent: the skeptic wanted all evidence at once (GDD §3.1); §3.1 is amended to "visible at once after the telling, which lasts seconds and any click ends" | panel — assumed | 2026-10-23 |
| D5 | The clock during the telling | The day clock does not run until the telling is finished or skipped; the mentor's guided steps wait too. Amends slice D10 and GDD §3.7 ("real time from the end of the telling, plus action costs"). The skeptic's cost (a few seconds of free inspection per soul) is accepted as bounded; the player advocate's case (a telling that eats the clock is skipped from day 2 on, and P2 dies) decides it | panel — assumed | 2026-10-23 |
| D6 | Headings, ids and captions | Panel headings become speakers: the soul's name; the witness's name with the description on hover (slice D52 kept); "Odin's Law". Claim and witness lines carry no id on the desk. Decrees carry **roman numerals** (I–V) on the scroll; L5's text becomes "…whatever I, III and IV say" (amends slice D32). Captions quote words instead of ids, from a shared formatter in core so the desk and the text harness say the same words (slice D13): an excerpt is the line's first words, width-measured, cut with ASCII "..." and extended until unique on the desk; a grey thread's caption names both speakers ("Ulf's 'Took it in the chest' against Bersi's 'He ran'"); the body's facts are named by their label. Data, tests and harness commands keep the ids | panel | 2026-10-23 |
| D7 | The witness | Told right after the claim, the same way, on its own sheet; one click finishes both tellings. "No witness came back." stays as the only line on an empty sheet, unquoted | panel | 2026-10-23 |
| D8 | Saga sheets | Claim and witness are parchment sheets with a 1–2 px torn edge and a faint rule under the heading, the speaker heading in soft ink, each line opening with a hanging straight quote mark. The sheet slides in within 0.2 s. No edge or texture crosses the text area or a hit rectangle. The hanging mark costs about 4 px and dropping the prefix frees about 15 px: the 132 px cap (slice D50) is re-measured by the fit check, not loosened | panel | 2026-10-23 |
| D9 | The Law scroll | The Law is a scroll with wooden knotwork ends at the full 204×144 panel (a new frame; the 80×150 style frame is reference only), headed "Odin's Law", decrees as verses with carved numerals. The scroll's visible length grows with the decrees in force (day 1 shows less parchment). A new decree carries a small **wax seal** in ember (an allowed UI accent, under `assets/art/ui/`) until the day's first stamp, replacing the "NEW:" heading; the seal is designed so day 7's forgery can be "the seal that looks different". A newly opened door keeps its own mark (slice D34): freshly unbarred, with "(NEW)" on hover. Decrees still wrap to at most 3 lines (slice D49) | panel | 2026-10-23 |
| D10 | The clerk's note | The caption strip becomes the bottom edge of an open parchment page, the clerk's note, with a speaker mark at its left: a pin in the thread's colour for a thread's caption, the raven for Huginn, the mentor's face for her comment, the black feather for a citation. Thread captions and Huginn's answers appear at once (within 0.2 s); the mentor's comments and citations are written with a quill reveal, skippable by a consumed click, and the 3 s hold (slice D33) starts when the writing ends. Priority order and take-over rules are unchanged. The note may take two lines; the fit check measures the longest caption with its mark | panel | 2026-10-23 |
| D11 | The HUD as objects | In the gate band's corner: a candle that burns down with the clock, with m:ss always drawn beside it on timed days (the last 30 s blink as today); on day 1 the candle is unlit with "untimed"; a no-seam pin gutters the flame and floats "-0:10" off it. Feathers: a quill mark with the count. Quota: tally marks on a slate. Huginn's answers: raven marks on the raven's post. The ledger: a small book with a wax dot while a promise is open. Numbers stay readable at all times; the fit check covers the HUD's 94×21 box (it may grow downward into the band's empty corner). Amends slice D21's icon-and-number cells | panel | 2026-10-23 |
| D12 | Pins and thread | A pin head (5×5) at each end of a thread; the thread is a 1 px core with a 1 px highlight and a 1 px dark halo (3 px in all, inside A3's 4 px gutters), drawn taut in about 0.15 s with a tack sound when a seam is found; patterns per kind stay (red bold and unbroken, grey dotted, law dashed) so colour is never the only cue; the grey knot becomes a tied-knot sprite of 8 px; hovering a line underlines it in ink; the first selected item gets a pin stuck in it, in ember (an allowed accent). Dissent: the skeptic wanted 1 px threads for the gutters; the 3 px total keeps the gutters clear | panel | 2026-10-23 |
| D13 | The cursor | A pixel pointer; while an item is selected the cursor carries a pin; over the soul (and while dragging it) it is a grab hand. Hotspots are verified at integer scale against the smallest hit areas (8×8) | panel | 2026-10-23 |
| D14 | The stamp | Each soul's **writ** (an intake slip with its name) lies under the doors. Clicking a door selects it (the door brightens) and raises the stamp over the writ, its face showing the realm's glyph and the realm's name with a question mark; the name on the writ keeps slice D9's explicit recipient. Clicking the stamp (still a guarded confirm) **slams** it on press: the desk band jolts 2 px and settles within 100 ms, a 70 ms hold, the thud, the glyph inked in Ink on the writ (never a reserved colour, never varying with the truth); then the door flares and the soul walks into the light, and the next soul may arrive during the walk. Clicking anywhere but the stamp, or right-clicking, puts the stamp down. Dragging the soul onto a door previews the same and slams on drop; releasing elsewhere cancels | panel | 2026-10-23 |
| D15 | Arrival and departure | The next soul walks in from the left (0.3 s) while its sheet slides in; nothing is blocked for longer than that and a click skips it. A stamped writ is swept off at the walk, except a held one: after a citation or a day-1 warning the stamped soul, its lit pair, its writ and the feather stay (slice D48) until the player clicks the writ ("Send it on", its hover label), which replaces the "Next soul" button | panel | 2026-10-23 |
| D16 | The citation | The black feather falls from above onto the writ (0.5 s, one bounce) with a dry caw distinct from Huginn's voice; its click target and the citation's accounting are live at once; clicking it lights the pair again (slice D33) | panel | 2026-10-23 |
| D17 | Presence | Two-frame idles: the mentor blinks, Huginn tilts his head. The waiting soul bobs 1 px only while it speaks and is otherwise still; a returned soul's frost glints. No glint touches evidence. Dissent: the designer wanted the soul still throughout; the bob during the telling is what sells "it is telling me" (player) | panel | 2026-10-23 |
| D18 | The mentor's bubble | A drawn speech bubble with a tail, wide enough that "Stamp him." never breaks one word per line, a blinking arrow when a click will advance it. The first click completes the reveal; a later deliberate click advances (double-click protection kept). Her guided prompts stay in the bubble, never in the note (slice D33) | panel | 2026-10-23 |
| D19 | Light | The doors' glow pulses slowly (2 s or more) inside their own sprites' pixels; fog drifts in the gate band's corners as palette-safe frames in masked regions, never a smooth alpha tint. The desk stays plainly lit and fog-free | panel | 2026-10-23 |
| D20 | Hover labels | Plain-language labels stay, drawn as a small parchment tag with a pin; exact text, mouse-through, and edge placement kept | panel | 2026-10-23 |
| D21 | Dawn | The screen falls to Night, "DAY I/II/III" in the carved capitals with a distant horn (1.5 s at most, skippable). Then **Odin's writ** hangs by the doors: a sealed parchment with every fact slice D34 lists (quota, the clock or "untimed", new decrees, doors opened, rule changes), one short line each, and "Begin" written on its tab; taking it down begins the day. The explanatory sentences added by slice D53 move to the mentor at the moment they first matter (the tide when its first figure joins, already hers; Huginn's role when he first perches), except the day-2 citation rule, which stays one line on the writ. The dawn fit check is re-run | panel — assumed | 2026-10-23 |
| D22 | Dusk | The desk dims to candlelight and the **day-book** opens over it: a two-page spread per beat group, written in ink with a skippable reveal: citations and the quota on the left page, the recap on the right; requests and the story beat on the next spread. "No citations today." never takes a page of its own. The page corner is dog-eared and labelled "Next"; a ribbon bookmark labelled "Skip all" closes the book (slice D15's discoverability). The recap keeps two phrasings, a broken decree apart from an unresolved truth. Skipping still records every request | panel | 2026-10-23 |
| D23 | The ending | A short tableau on the gate band (figures marching from the bile door for Hel's tide; empty benches under the ember door for the hollow hall; the gate standing for the Hall holds), then the day-book's last page: the outcome as a carved heading, one row per soul with the stamped realm's glyph and word, the truth's glyph and word, and a mark with its word: a tick (matched), frost (worthy damned), a hollow ring (liar admitted), a black feather with "ignored" or "missed" (a citation); "never judged" for the unjudged; the standing as a wax seal with the feathers and rank; "Play again" on a ribbon. The worst-case 12-row ending fit test is re-run on the page | panel | 2026-10-23 |
| D24 | Title | The gate at dusk with drifting fog and pulsing door glow, the name in the carved capitals, Start and Quit as parchment tags (slice D31's controls), a wind drone. The title joins the critic's screens | panel | 2026-10-23 |
| D25 | Sound | Reverses slice D11's "no ambience", within GDD §7's "silence while you inspect": wind plays on the title and between days only, a drone under the day-book stands in for the hymn, and the desk itself is quiet except for actions: voice blips (short, quiet, one sample pitched per soul), pin tack, thread pull, the no-seam tick, the stamp slam (kept), door flare, the feather's caw, the page turn, the horn. The seam sound stays the second loudest. All sounds are **synthesized by a script in `tools/`** (reproducible, no downloads, no licence), credited as generated in `assets/audio/CREDITS.md`. A master volume and mute live in the options (D-row in round 2) | panel | 2026-10-23 |
| D26 | Reserved colours | Unchanged from the art direction and `pixelforge.toml`'s per-path rules: ember only on Valhalla's door, its flare, and UI accents under `ui/**` (the wax seal, the selected pin); bile only on Hel's door and its light; blood only on wounds. The stamped glyph is Ink even for Valhalla. Runtime drawing is checked by review and the critic, since lint sees files only | panel | 2026-10-23 |
| D27 | Skipping | Every presentation (telling, reveal, slide, fall, page) is finished by a consumed click that never also pins, selects, stamps, advances or acknowledges; a consumed press also consumes its release. The slam is the one block (about 0.5 s with the flare): presses during it are ignored outright, and the next soul can arrive during the walk that follows. Restart cancels every animation | panel | 2026-10-23 |
| D28 | Quoted pairs | A caption's quoted pair also lights on the desk while the caption shows, so the quote is a reminder and the desk is the link | panel | 2026-10-23 |
| D29 | Gods and monsters in disguise | A content idea for days 4–8, recorded as parked in GDD §10; it needs body facts and authored seams, not a detection mechanic | panel | 2026-10-23 |
| D30 | How we know | Before each merge: (1) a blind critic from another vendor scores 1:1 before/after screenshots and short desk-shots frame sequences of six moments (title, the desk mid-pin, the stamp, dawn, dusk, the ending), on a liar and on a hero, against the pillars and a checklist: every text block has a speaker or a material; no block is a bordered rectangle of system text; every state change has motion and sound; numbers are objects; the stamp is the loudest moment; everything reads at 1:1; nothing differs between a liar and a hero before a thread; (2) the desk-shots run measures forced (unskippable) time per honest soul, which must stay at 2 s or less; (3) the audit kit, the fit check and every GUT test pass. The owner's play remains the final gate; the critic never replaces it | panel | 2026-10-23 |
| D31 | The playable slice | The first work package builds day 1 (Ulf, Kolbeinn) plus a timed day-2 probe with a witness and a held citation (Sigvaldi; Hakon admitted) on the new desk: sheets with the telling, the clerk's note, pins and thread, the writ and the slam, the candle, the feather. The lead plays it and the critic scores it before the rest is built; the populated day-3 fit fixture is added in the same package | panel | 2026-10-23 |
| D33 | Fork S1, the desk's materials | **S1-A, Parchment and ink**, unanimous by eye. Conditions: speaker headings in full Ink, not soft ink (they were too pale to find); the HUD's framed box is replaced by the objects of D11, not decorated; the wax seal is a distinct 7×7 wax blob with an impressed mark placed at the decree's numeral, never an ember dot like a pin head, because an ember dot on the desk means exactly one thing, "pinned" (amends D9); the mentor's bubble is widened (D18); the populated day-3 fit check is re-run (D2). From S1-C only the stamp as an object (D14); from S1-B nothing | panel | 2026-10-23 |
| D34 | Fork S2, between days | **S2-A, the day-book**, unanimous, with S2-B's dark "DAY N" card as the dawn beat (D21) and S2-C's one object, the black feather drawn on the page as the citation's mark (D23). Conditions: the dog-ear is labelled "Next" and the ribbon "Skip all"; "Play again" sits on the last page, not outside the book; the ending's marks differ by shape and carry their words (D23); the mentor's dusk comment goes on the page under her mark or in her bubble, never in a bar under the book; a real two-page fit test replaces the 470 px card test (worst case: 12 rows with glyphs and mark words) | panel | 2026-10-23 |
| D35 | The slab | The body chart becomes a stone slab: a Night 3 top with a lighter rim (never an Ashen value) and a shadow, both outside the 128×100 chart and never over a wound or a hit area; the chart's pixels and hit areas are untouched; every body variant is checked against it | panel | 2026-10-23 |
| D36 | A pin with no seam | The second pin pops out, the thread goes slack and drops off the desk (0.4 s at most, interrupted by the next click, never blocking a pin), a dull tick plays, and on a timed day the candle gutters with "-0:10" floating off it (only when charged). The note writes **"No seam between those two."**, never "those two agree": the caption says only what the pin showed, since "agree" would read as the body confirming a lie (D45; designer and skeptic). One animation for every no-seam pin, so a red herring and an unrelated pair look identical | panel | 2026-10-23 |
| D37 | Options | A small options panel reached from the pause and the title: **text speed** (normal 40 cps, fast 80 cps, instant), **reduce motion** (removes every decorative movement: jolt, fog drift, glow pulse, bob, slides, the feather's bounce, the tide's step, the marching tableau, each replaced by its static end state; never a state cue: the thud, the inked glyph, the feather landing and "-0:10" stay), **master volume** and **mute**. Saved in `user://options.cfg`, with validated defaults when the file is missing or unreadable. At "instant" the telling ends by rule at once and no click is consumed. Amends slice D31 ("no settings") and GDD §8: text speed is offered, text size is not (one font at 480×270, D3) | panel — assumed | 2026-10-23 |
| D38 | Hel's tide at the slam | The 6 px figure steps into the line at Hel's door at the slam (0.3 s at most, never blocking the next soul; immediate under reduce motion), triggered by the committed stamp's tide increment, never by a desk refresh (so it can't duplicate or attach to the next encounter). The mentor's comment on the first figure stays | panel | 2026-10-23 |
| D39 | Days darken | The gate band's background frames are recoloured one ramp value darker per day (day 1 is the current dusk; headroom for eight steps toward Night 0), as palette-safe frames, never a tint. The doors, their glyphs and light, the soul and its plate, the raven, the barred door's bar, and the HUD keep their values; each day's band is contrast-checked for them in the fit check. The desk never darkens | panel | 2026-10-23 |
| D40 | Asking Huginn | Clicking the raven (hit area: the bird and his post) asks him about the selected grey thread, through the existing eligibility and payment path; hover says "Ask Huginn: N answers left", "Select a grey thread first." or "Extra answer: 2 feathers". A click with nothing selected costs nothing; a consumed skip click never spends an answer. The answer count stays visible as raven marks (D11). The mentor's line when he first perches says to click him. Days 1–2 show an empty post. Replaces the "Ask Huginn" button (slice D8's separate control is the raven) | panel | 2026-10-23 |
| D41 | Voice blips | One short synthesized sample; pitch from a hash of the soul's name over about an octave; one blip per 3 non-space characters, capped at about 13 a second at every speed, stopped at once on skip, pause or restart, silent at "instant". Only the dead speak: the mentor's bubble and written comments are silent. Dissent: the brief's one per 2 characters (a buzz by the 12th soul) | panel | 2026-10-23 |
| D42 | The pause | The desk dims and a hanging parchment reads "Paused" in carved capitals with tags for Resume, Options, Restart the run and Quit; a confirm is a second tag row placed away from the tag that opened it, taken only by a deliberate click (never the consumed one); the opening actions are disabled while a confirm shows; Esc resumes; `PauseOverlay`'s input blocking and the guarded buttons stay | panel | 2026-10-23 |
| D43 | Written reveals | The mentor's comments and citations write at 60 cps, with a maximum reveal of 1 s (longer text writes faster); the 3 s hold starts when the writing ends; fast and instant speeds apply; a consumed click finishes it | panel | 2026-10-23 |
| D44 | The text harness | Prints the same captions, dusk and ending words through the shared formatters, keeps its id commands, and prints no telling, pitch or timing (slice D13) | panel | 2026-10-23 |
| D45 | Work packages | Four, each one stacked pull request with its docs and tests in it: **WP1** the playable slice (D31) now including the slab (D35), the no-seam failure (D36), the scroll frame with numerals (seal deferred), the candle HUD, the held writ, the loop's synthesized sounds and the options core (text speed and reduce motion respected; the panel itself later), gated by the lead's play, the critic and the time budget; **WP2** the rest of the desk (wax seal and growing scroll, the raven, hover tags, cursor, idles, light and fog, days darkening, the tide's step, the mentor's bubble, the populated day-3 fit check); **WP3** between days (dawn, the day-book with the ending's tableau and page, the title, the pause and options panel); **WP4** verification and docs (the critic over six moments on a hero and a liar, the desk-shots time budget, the audit kit, GDD/ADR amendments, docs cleanup, the story page) | panel | 2026-10-23 |
| D46 | What the critic cannot settle | The skeptic's standing objection is recorded: a forced-time ceiling and screenshots cannot prove the 12th soul feels faster; only complete timed runs and the owner's play can. The lead's full-run play with the real clock is part of WP4, and the owner's play remains the final gate (D30) | panel | 2026-10-23 |
| D47 | Two marks on an ending row (from the review) | A row may carry two marks: the record mark first (tick, frost for a worthy soul damned, a hollow ring for a liar admitted) and, when the stamp drew a citation, the black feather with "ignored" or "missed" after it. The two-page fit test covers the widest such row with a returned name | lead (review) | 2026-10-23 |
| D48 | The cursor is drawn in the scene (from the review) | The OS cursor is hidden over the game and a cursor sprite follows the mouse on a top canvas layer, so it is pixel-consistent at every integer scale with no OS cursor sizing (web limits and HiDPI don't apply); the OS cursor returns when the window loses focus or the mouse leaves it. Hotspots are tested against 8×8 targets at 1× and 3×. Refines D13 | lead (review) | 2026-10-23 |
| D49 | Five work packages (amends D45) | WP1 is split so the first checkpoint comes early: **WP1** day 1 on the new desk (the input and stamp lifecycle contracts with their tests, the populated day-3 fit fixture, sheets with the telling, the clerk's note, pins and thread, the slab, the writ and the slam, the scroll frame with numerals, the loop's sounds, the options core) with the Ulf/Kolbeinn checkpoint; **WP2** the timed probe (candle HUD, the no-seam failure, the feather's fall, the held writ, walk-in, the tide's step at the slam, Sigvaldi with Bersi, Hakon admitted) with the critic's first scoring and the time budget; **WP3** the rest of the desk (seal and growing scroll, the raven, hover tags, cursor, idles, light and fog, days darkening, the mentor's bubble, the day-3 fit re-run, the audit kit); **WP4** between days and the shell; **WP5** final verification and docs. Each PR carries its own tests and doc amendments; WP5 only verifies and cleans | lead (review) | 2026-10-23 |
| D50 | Sound formats and the two kept sounds (amends D25) | New sounds are generated as 16-bit WAV by `tools/audio/synth_sounds.py` with Python's standard `wave` module (Godot imports WAV natively; no encoder, no download). The existing thud and seam sounds stay the Kenney CC0 files they are, credited as before. On the web, audio starts at the first click (the title's Start), so the title's wind may begin then | lead (review) | 2026-10-23 |
| D51 | The no-seam drop and clicks (amends D36) | The slack thread's drop is cosmetic: a click during it is never consumed by it; the drop simply ends. Only tellings, written reveals and the dawn card consume a finishing click (D27) | lead (review) | 2026-10-23 |
| D52 | The gutter's label (from the WP2 review; amends D11 and D36) | The "-0:10" label never covers a HUD number: it appears on the stone to the left of the candle (above the boar door's arch) for 0.6 s with an ink fade, no rise, the same under reduce motion; the candle's flicker stays. The reviewer found the rising label hid the quota and clock for 0.6 s, against D11's "readable at all times" | lead (review) | 2026-10-23 |
| D53 | Where the feather lands (from the WP2 review; amends D16) | The black feather keeps its resting place on the desk beside the mentor (the slice's placement, and the feather the owner saw). It drifts in from the gate's left edge at that height over 0.5 s with a sway and the caw, crossing no evidence (a fall from above would cross the slab); its click target is live at rest from the first frame; reduce motion: in place. "Onto the writ" is withdrawn: a 32 px feather on a 70x16 writ would cover the inked verdict | lead (review) | 2026-10-23 |
| D54 | The stamp's presence (from the blind critic's first scoring) | The critic scored "the weight of the stamp" 2/5: a small icon beside "Valhalla?", an impact dominated by the door, and the next soul's sheets already on the desk at the impact. So: the stamp face is 24x24 with a visible handle, raised over the writ and allowed to overlap the foot of the door behind it; at the impact it squashes for two frames and an ink ring shows on the writ for three; the previous soul's sheets, slab and note stay until the slam releases (0.5 s), and the next sheets slide in with the walk-in. Nothing varies with the truth (D14). The critic re-scores on unguided souls (day 2: Sigvaldi against Grim), since the mentor's lit pair on day 1 read as a tell | lead (critic) | 2026-10-23 |
| D55 | The impact dominates (from the critic's re-score; extends D54) | The critic scored the stamp 3/5 after D54: the impact still looked modest beside the bright doors and the sheets. So at the impact everything but the writ and the stamp yields for 0.12 s: the desk and the gate band darken one step (the one allowed transient tint, a state cue, skipped under reduce motion); the inked impression is the realm's glyph at 2x in a 17x17 ink box with a 21x21 ring for 0.12 s; the thud plays on the impact frame. Identical for a liar and a hero (D14). The critic's remaining item, the surviving controls (the mentor's Next, Ask Huginn, the name plate's dark rectangle, the body facts' outline, the blank note), is WP3's and is listed on #22 | lead (critic) | 2026-10-23 |
| D56 | The choice dims the desk and the impact emits (from the fallback critic; extends D54, D55; amends D14's jolt) | The fallback critic (a different Claude model, blind, after Codex ran out of quota) still scored the stamp 3/5 on D55's frames: the dim barely registered, the impact emitted nothing, the ring read as a border. So: while the stamp is raised the desk yields (a 0.25 veil over everything but the writ, the stamp, its label and the three doors; the mentor's bubble and Huginn dim with the rest), the impact deepens it to 0.55 until the lift at 0.15 s; an ink burst at the impact (eight streaks, Parchment 2 at 3 px then Fog 2 at 6 px, two frames); the ring is a shockwave (21 px in ink, then 27 px in Fog 2, 0.05 s each); the jolt is 3 px (amends D14's 2). Reduce motion: no veil at all (the squash, ink, burst and shockwave stay as state cues). `project.godot` caps the frame rate at 60 so every timed cue lasts at least a frame; tests bound waits by seconds, never frames. This is the last stamp iteration inside WP2: the owner's play judges the rest | lead (critic) | 2026-10-23 |
| D57 | The stamp's size is bounded by the map; the owner decides the next step (from WP3's critic) | Across WP2 and WP3 the stamp went through four iterations (D54-D56, then an 8 px rise with a shadow, 3 px strokes, a 28 px face, moving sparks, a flash, a dent). The Codex critic holds "the stamp is the loudest moment" at 3/5 ("the small stamp... struggles against the large, bright Law sheet") while a different model's blind critic scored it 4/5; every other item scores 4 and the leak item 5. The stamp cannot grow further where it is: the writ lies in the 20 px strip under the doors (D2 kept layout A3). A bigger stamp means moving the writ and the stamp onto the desk (for example over the note's right end, or replacing the mentor's corner), which changes the map the owner approved. The lead stops iterating here and leaves the choice to the owner's play: keep the stamp as built, or move the writ onto the desk in a later pass. The critic's readability item (small marks at 1:1: the seal, the pin head, the slate, the book) gets hover labels on the HUD objects in WP4 | lead (critic) | 2026-10-23 |
| D58 | The ending's marks and the day-book's shape (from WP4's build and review; amends D22, D23, D47) | The record marks (a tick, frost, a hollow ring) keep their words, on the page and in the harness together (D44 asks for the same words, not frozen words): "Matched.", "Worthy, damned.", "Liar, admitted." after the truth, then the feather's "Ignored." / "Missed."; "never judged." stays; the page carries the column headers Sent, Truth, Record. (The build first dropped the words to keep the harness text unchanged; the reviewer and the critic both found the marks unreadable without them.) A row for a wrong door that is neither Hel nor Valhalla carries no record mark. The dusk book is 300x170 and grows (to 440x250, closing its paragraph gaps, then running the left page onto the right) for the heaviest dusk; the ending book is 470 wide with each row running across the spine (the name on the left page, the Sent column beside it, then Truth, Record and Cited on the right page; the row carries no "Truth:" label since the headers say it, and the feather with "Ignored." / "Missed." sits under Cited), since the widest row needs about 270 px. The ending adds Hel's ledger line to the last page. "Play again" and "Skip all" are nailed paper tags in a darker face than the title's; "Next" stays the dog-ear; the ribbon is gone. The desk is covered in Night under the ending tableau so empty papers never show. The dawn card's numeral is drawn at 2x and the writ carries Odin's name; every tag keeps 3 px of ground after its text. The day-book's candle flame is ember like the HUD's. The dawn writ shows its lines at once (not told) and covers the doors (x 120-360) rather than hanging beside them; the D53 explanatory lines left the dawn data and the mentor's first-tide comment now says "At 3, they march." (digits, to fit the note's 330 px line) | lead (build) | 2026-10-23 |
| D32 | After the plan | The owner chose `team-lead-handsoff`. That skill refuses model invocation in this session (it is reserved for the owner typing the command), so the build runs under `team-lead`: stacked pull requests, reviewed by Codex, **not merged**. Under ADR-0007 only the hands-off lead may merge, so the PRs wait for the owner, who can merge them or run `/game-sdlc:team-lead-handsoff` on the epic | lead (constraint) | 2026-10-23 |

**Assumed by the panel** (the owner skims these first; each is the owner's by nature):
- **D4:** the claim and witness are told line by line (seconds, any click ends it), which amends
  GDD §3.1's "every item visible at once" to "after the telling".
- **D5:** the day clock waits for the telling (GDD §3.7 and slice D10 amended).
- **D21:** the dawn card's explanatory sentences from the WP6 playtest (slice D53) move to the
  mentor at the desk, except the day-2 citation rule; the dawn writ keeps every D34 fact.
- **D37:** a small options panel (text speed, reduce motion, volume), reversing slice D31's "no
  settings"; GDD §8 offers text speed instead of text size.
- **D25:** ambience and action sounds reverse slice D11, within GDD §7's "silence while you
  inspect"; all sounds synthesized by a script, no downloads.
- **D32:** the build runs under `team-lead`, not `team-lead-handsoff`, because the latter refuses
  model invocation; the PRs wait for the owner to merge.
- **D57 (open for the owner):** whether the stamp stays in the band's strip under the doors (as
  built, scored 3/5 by one critic and 4/5 by another) or the writ and stamp move onto the desk for
  a bigger stamp, a map change.

## The experience, walked through

1. **Title.** The gate at dusk: fog drifts in the band's corners, the ember and bile doors pulse
   slowly, the name "Valhalla Intake" stands in carved lettering over the wall. Two parchment tags
   nailed to the desk read Start and Quit. A wind drone plays. Start: a distant horn.
2. **Dawn, day 1.** The screen falls to Night; "DAY I" in the carved lettering; the horn fades. The
   desk lights, and Odin's writ hangs by the doors: a sealed parchment with the quota ("Odin wants
   1 for Valhalla"), "Untimed", and the three decrees in force. Taking it down (one click) begins
   the day; the writ slides off.
3. **The first soul (Ulf).** Ulf walks in from the left and stops at the gate; his name plate lights.
   A saga sheet slides onto the desk under his name, "Ulf", and his lines are written as he speaks,
   one at a time, with a low voice blip: `"Speared, in battle.` ... Any click finishes the telling;
   the click is consumed. The body chart beside it is a stone slab with his corpse laid front and
   back. The Law is a scroll on the right, "Odin's Law", decrees I-III. The clock does not run.
4. **Learning the verb.** The mentor's bubble, by her portrait, says "Read the body first." with a
   blinking arrow; clicking the bubble advances her. Hovering the chest shows a pinned parchment
   tag: "spear wound, chest". She lights his first line and decree I; the player clicks the line (a
   pin sticks in it, the cursor now carries a pin), then the decree: a thread snaps taut between
   them with a tack, and the clerk's note at the bottom writes, after a pin mark in the thread's
   colour: `"Speared, in battle" against decree I: the saga is true. I sends him to Valhalla.` The
   spear glyph on the ember door glows a step brighter.
5. **The stamp.** She points at the doors. Ulf's writ lies under them with his name. Clicking the
   ember door raises the stamp over the writ, its face showing the spear and the word "Valhalla?".
   Clicking the stamp slams it: the desk jolts 2 px, a 70 ms hold, the thud, the spear inked in
   black on the writ. The door flares, Ulf walks into the light, the writ is swept off, and
   Kolbeinn is already walking in. Dragging Ulf onto the door does the same.
6. **The first lie (Kolbeinn).** His sheet is written. The mentor lights "no wound" on the slab and
   his line `"Three Danes cut me down.`; the pin, the thread, and the clerk's note: `"Three Danes
   cut me down" against the body: the body gives the lie.` The thread is red and bold. He goes to
   Hel: the slam, the bile door flares, and no figure joins Hel's tide (he was not worthy). Later,
   when Asa is sent to Hel, a figure steps into the line at the bile door at the slam, and the
   mentor comments on it.
7. **A pin with no seam.** Pinning two lines with no seam between them: the pin pops out, the thread goes slack
   and drops, a dull tick; on a timed day the candle gutters and "-0:10" floats off it; the clerk's
   note writes "No seam between those two."
8. **Dusk, day 1.** The horn. The desk dims to candlelight; the day-book opens over it. The
   left page: "Dusk, day 1", citations ("No citations today.") and the quota with the feathers;
   the right page: the recap of two or three souls, written in ink. The page corner is dog-eared:
   clicking it turns the page (a page sound) to requests and the story beat; a ribbon bookmark
   closes the book ("Skip all"). Closing it: "DAY II" in the dark, the horn, the writ.
9. **Day 2 (timed).** The candle in the gate band's corner burns down with the clock, "5:00"
   beside it. Sigvaldi speaks, then Bersi his witness speaks on a second sheet; one click finishes
   both tellings. The clock starts when the telling ends. Hakon's law thread writes "the saga is
   true. IV sends him to Hel." The player stamps him to Valhalla anyway: at the slam a black
   feather falls from above and lands on the writ with a dry caw; the clerk's note writes the
   citation after a feather mark, with the pair lit on the desk; the held writ waits. Clicking the
   feather lights the pair again. Clicking the held writ ("Send it on") calls the next soul.
10. **Failure, two kinds.** A missed seam on Grim: the feather falls, the clerk's note names the
    pair; the dusk page marks him *missed*. Ketil admitted on an unresolved grey thread: no
    feather (D37), but at the ending his row carries the hollow ring.
11. **Huginn.** On day 3 the raven sits on his post. Clicking a grey thread's knot selects it;
    clicking Huginn (hover: "Ask Huginn: 2 answers left") spends an answer, the raven tilts his
    head, and the clerk's note writes his answer after the raven mark.
12. **The ending.** After day 3's dusk the day-book's last spread: a short tableau on the gate band
    (figures marching from the bile door for Hel's tide; empty benches for the hollow hall; the
    gate holding), then the last page: the outcome as a heading, one row per soul with the door
    glyph stamped and the truth's glyph beside it, a mark (tick, frost, hollow ring, black feather
    with *ignored* or *missed*), the clerk's standing as a wax seal, and a ribbon "Play again".
13. **Cancellation and unavailable actions.** Clicking the pinned item again, or right-clicking,
    pulls the pin out. Clicking anywhere but the stamp, or right-clicking, puts the stamp down.
    Releasing a dragged soul off a door drops it back. The barred boar door says "Closed until
    day 3" on hover. Huginn's hover says "Select a grey thread first." when none is selected. Esc
    pauses and dims the desk; the pause offers text speed, reduce motion and volume beside Resume,
    Restart and Quit.
14. **The 12th soul.** Every telling, reveal and transition can be clicked through; the forced
    time per honest soul (walk-in, slam, flare) stays at 2 s or less, measured by the desk-shots
    run. The 12th soul is faster than the 1st.

## Sketches

Drawn over 1:1 captures of the built desk, in the palette and font (`game-ui-sketches/`, each at
1× and ×3; `draw_sketches.py` re-draws them from a captures folder).

**Fork S1, the desk's materials** (`S1-compare-x3.png`):

| Option | File | For | Against |
|---|---|---|---|
| A. Parchment and ink | `S1-A-x3.png` | Matches the art direction's parchment text surface; best contrast at 1:1; cheapest (frames, marks, a seal) | The least radical: three paper blocks where the boxes were |
| B. Carved stone | `S1-B-x3.png` | Coldest and most Norse; nothing resembles a web page | Light text on dark surfaces reads worse at 1:1; the scroll frame already exists for parchment |
| C. Papers, Please literal | `S1-C-x3.png` | The most tactile; loose slips, a rulebook and a stamp tray | Overlapping slips and a rulebook that opens break "every item visible at once" (GDD §3.1) under a clock; the largest code and test cost |

Borrowed: A from Pentiment's speaker-headed pages and Strange Horticulture's candle-lit desk
objects; B from Return of the Obra Dinn's engraved look and Death and Taxes' fixed props; C from
Papers, Please itself.

**Fork S2, between days** (`S2-compare-x3.png`; dusk on the left, the ending on the right):

| Option | Files | For | Against |
|---|---|---|---|
| A. The clerk's day-book | `S2-A-dusk-x3.png`, `S2-A-ending-x3.png`, `S2-A-dawn-x3.png` | One object carries dusk, recap, ending and standing; pages and ribbons replace buttons; reads well | A book over the desk is still a modal by another name; needs book art and page sounds |
| B. Title cards | `S2-B-dusk-x3.png`, `S2-B-ending-x3.png` | Cheapest; the most "game" transition (dark, carved words, the doors glowing) | The dusk's beats have no surface; 12 ending rows don't fit on a wall; the same list in the dark |
| C. Objects on the desk | `S2-C-dusk-x3.png`, `S2-C-ending-x3.png` | The most diegetic (Papers, Please's letters instead of a stats screen) | 3 days × 5 beats of bespoke objects; the ending still needs a page; the hardest to skip cleanly |

Borrowed: A from Strange Horticulture's handwritten book and Pentiment's turned page; B from
Obra Dinn's black chapter cards and Papers, Please's sparse end-of-day text; C from Death and
Taxes' end-of-shift results on the desk and Papers, Please's citation slip.

## How it could pass and still fail

| Way | Guard |
|---|---|
| The sheets, scroll and day-book are drawn but the text still reads as a form: headings in caps, ids in captions, a bordered box around every block | The critic's checklist (D30); the walkthrough's exact note lines are acceptance text |
| The telling is pretty but slows the loop; from day 2 players skip every telling, and P2 dies | The clock waits for the telling (D5); 40 cps; one click finishes all pending tellings; the forced-time budget (D30) |
| The slam is juicy but blocks the next soul; the 12th soul feels slower than the 1st | The slam's hold is 70 ms and the walk never blocks arrival (D14, D27); desk-shots measures it |
| Something on the desk differs between an honest soul and a liar before a thread is made: a voice pitch, a sheet, a sound | Pitch derives from the soul's name, never a field (D4); the critic scores a liar and a hero side by side (D30) |
| Ornament crosses the evidence: a torn edge under a line, a glow over the slab, a vignette on the papers | The art direction's rule is a review line; the fit check and the audit kit are re-run |
| Captions quote four words that miss the contradiction | The pair lights on the desk whenever its caption writes (D28) |
| The dusk book is beautiful and the recap no longer tells a broken decree from an unresolved truth | Two phrasings kept (D22); the harness prints the same words |
| The feel is made of prose in the plan: "the stamp feels heavy" | Acceptance is numbers and screenshots: jolt px, hold ms, sound played, frames captured |

## Review (big plan)

- **Reviewer:** Codex (GPT), another vendor's model, in a fresh session; not the panel's skeptic.
- **Verdict:** NOT READY at first pass, on four material points, all taken; a second pass found three contradictions the fixes introduced (WAV vs ogg, the tide's step's package, feathers only on citations), all fixed in the same documents: a scene-owned
  presentation/input lifecycle contract with executable tests (plan §3, WP1); an exactly-once
  stamp consequence contract (plan §3); the text migration inventory (plan §4); WP1 too large
  (D49 splits it). Verdict after the fixes: recorded under "Approval record".
- **Ledger -> plan:** 38 rows were carried as summaries that dropped a detail (the exact "No
  witness came back.", the 94×21 HUD box, the 5×5 pin heads, the masked fog regions...). Fixed by
  the plan's rule that each requirement is a summary and its cited rows are the full
  specification, plus corrections where the plan's meaning differed: D28 (the pair lights
  automatically while its caption shows, never on a click), D4 (a head bob, the telling replays
  after a restart), D27 (the slam's block is about 0.5 s), D30 (before/after comparisons on every
  PR, the audit kit in the gate), D32 (delivery under `team-lead` with Codex review).
- **Plan -> ledger:** three invented choices, now decided: click-to-light (removed; D28 stands),
  the leak check's scope (narrowed to the telling's cues, D1/D4; consequences such as the
  feather, the tide and the ending are authorized to differ), the cursor's package (D49).
- **Challenges answered:** an input arbiter (`PresentationGate`, plan §3); a captured stamp
  context with an exactly-once tide delta (plan §3, D38); pause stops tellers, tweens and audio
  through the gate, the slam's hold is a local tween interval, never a time scale (plan §3); a
  typed caption payload (plan §3); the text migration through the content generator (plan §4);
  typed spreads and ending rows with mark precedence (D47); the in-scene cursor (D48); options
  ownership and web storage limits (plan §3, §6); WAV generation and the two kept Kenney sounds
  (D50); instrumented gates and a scored rubric (plan §6); the walkthrough reconciled with D1,
  D36 and D51; amendments land in the package that introduces each change (D49).

## Built

What the team delivered against this ledger (2026-10-23 to 2026-10-24), as evidence for the owner's
play, which remains the gate (D30, D46). Nothing is merged (D32).

| WP | Pull request | Gate at the PR | Review | The blind critic |
|---|---|---|---|---|
| WP1 day 1 on the new desk (#20) | [#26](https://github.com/amramos/valhalla-intake/pull/26) on #25 | the lead's play of day 1 with real input; the fit check; the leak test; GUT green | Codex: findings fixed, re-review approved | not yet scored (the checkpoint was the lead's play) |
| WP2 the timed probe (#21) | [#27](https://github.com/amramos/valhalla-intake/pull/27) on #26 | forced time 0.52 s per soul (budget 2.0); fit check; GUT green | Codex eight findings, then a fallback Claude review four more, all fixed | the stamp 2/5, then 3/5 after D54-D55, then 4/5 after D56; the leak item 5/5; overall 4/5 PASS |
| WP3 the rest of the desk (#22) | [#28](https://github.com/amramos/valhalla-intake/pull/28) on #27 | the audit kit; the day-3 fit re-run; desk-shots; GUT green | Codex five findings plus one from the re-review, all fixed | A-D 4/5, the leak 5/5, overall 4/5; the stamp 3/5 and small marks 3/5 (D57) |
| WP4 between days and the shell (#23) | [#29](https://github.com/amramos/valhalla-intake/pull/29) on #28 | the two-page ending fit; desk-shots from the title to "Play again"; 80 scripts, 731 tests | Codex eight findings, fixed; a fallback Claude re-review approved | Codex 4/3/3/3/2/3, overall 4 FAIL; after a fix round the fallback 4/4/4/3/3/3, overall 4 FAIL; every named defect fixed in the PR |
| WP5 verification and docs (#24) | [#30](https://github.com/amramos/valhalla-intake/pull/30) on #29 | the final critic; the timed play; every gate re-run: 81 scripts, 733 tests | none needed: a harness, one defect fix with its test, docs | see below |

**The final critic (Codex, blind, 27 before/after captures of the six moments on a hero and a
liar, D30):** A material and speaker 4/5; B no web pages 3/5; C the dead tell their tale 3/5; D the
weight of the stamp 3/5; E days and the reckoning 4/5; F touchable controls and readability 3/5;
overall 4/5, BEFORE lower on every item; "the 12th soul would probably feel faster than the 1st".
FAIL on B, C, D, F. What it named, and what the lead did with each:

- *the stamp's consequence is not visible, the held writ does not read as the gate refusing* (D):
  stills cannot show the slam, the veil, the walk or the feather; the stamp is at its D57 bound,
  and the owner decides the next step. Declined in WP5.
- *the liar's raised name slip is obscured by the sheet* (F): a real defect. The slip is the next
  soul's writ, and the capture caught it 0.7 s after a stamp, rising from under the sheets during
  the sweep inside a clip that ran 1 px onto the Claim and the Law. Fixed in WP5: the next writ is
  set in its place and fades in over the same 0.15 s (the WP2 sweep had the next writ rise into place; the stamped writ still slides off the desk edge), the clip ends at
  the sheets' top, and a test holds the longest names whole and off every sheet through every frame
  of the slam and sweep.
- *pause and options remain centred dialogs with stacked controls* (B): the hanging parchment keeps
  the layout D37 chose; a redesign is a new decision for the owner. Declined.
- *the testimony reads transcribed, the soul stands apart from its transcript* (C): the telling is
  motion and sound (D4, D17: the plate lights and the figure dips on each voice); a still shows
  the sheet. Declined; the owner's play judges it.
- *tiny marks (the continuation mark, the HUD book, pin symbols) at native scale* (F): hover tags
  name every HUD object (WP4); the marks stay the size the 480x270 map allows (D3). Declined.

**The lead's timed play (D46), a measurement, not a verdict:** `tools/timed_play/` plays all three days as a careful player at the normal text speed: it waits for every telling to end by itself, reads every claim and witness line at 1.5 s a line, pins every seam the soul has, checks each thread, and stamps, with 0.5 s before every click. Two runs agreed within 0.1 s. Per soul (telling / reading / pinning / total, seconds): day 1 Ulf 2.8/6.0/3.7/13.2, Kolbeinn 3.3/6.0/7.4/17.4, Hallr 3.2/6.0/5.8/15.7, Asa 3.3/6.0/1.2/11.2; day 2 Sigvaldi 4.8/10.5/1.2/17.2, Hakon 5.4/10.5/2.4/19.0, Grim 5.1/10.5/6.0/22.3, Brand 5.3/10.5/6.0/22.4; day 3 Freydis 5.0/10.5/1.2/17.4, Hakon (returned) 3.4/6.0/2.4/12.5, Ragna 5.1/10.5/3.6/19.9, Ketil 5.3/10.5/1.2/17.7. The clock (which waits for the tale, D5) left **4:01 on day 2 and 4:12 on day 3**: about 59 s and 48 s of the 300 s were used, and no day ran out. The dawn card's gated wait was 1.49, 1.45 and 1.45 s when left to run out. At the instant speed desk-shots' forced wait is 0.52 s per soul, the slam window and nothing else. What this cannot say: whether 4 minutes of slack makes the clock feel idle (slice D42) or safe; the owner's play decides.

**Harness parity (D44):** the harness prints the same words as the desk, asserted by
`tests/unit/core/caption_formatter_test.gd`, `screen_text_test.gd`, `screen_text_spreads_test.gd`,
`tests/unit/tools/harness/harness_caption_test.gd`, `harness_flow_test.gd`, `harness_test.gd`, and
on the desk by `tests/integration/scenes/desk/desk_day_book_test.gd`, `desk_ending_fit_test.gd`,
`desk_dawn_test.gd` and `desk_flow_test.gd`.

**What the owner decides next:** the assumed decisions (D4, D5, D21, D25, D32, D37) on the first
play; D57 (the stamp as built, or the writ onto the desk); whether the m5x7 capital N (a Π when
zoomed) needs a glyph fix (ADR-0008); and the merge of #25-#30 in order.

## Approval record

- **Authorized experience:** the three-day slice as built, re-presented as a game at a stone desk:
  the dead tell their tale line by line in their own voice; the Law is a sealed scroll; captions
  are the clerk's note with a speaker mark; the HUD is a candle, a quill, a slate, raven marks and
  a book; pins and thread are real; the stamp slams a writ; a black feather falls on a citation;
  dawn is a dark carved card then Odin's writ; dusk and the ending are the clerk's day-book; the
  title and pause are the gate and a hanging parchment; sound is quiet at the desk and present at
  the edges. Nothing about how to play changes.
- **Preserved / removed:**
  - preserved: every rule, the map, the font, the body art, the doors, the harness's commands,
    the core tests;
  - replaced: the flat panels, the ids on the desk, the caption bar, the HUD box, the stamp prompt,
    the phase cards, the list ending, the "Ask Huginn" and "Next soul" buttons;
  - not built: new content, days 4-8, disguises (parked), a resolution change, music, Steam.
- **Cost:** GDD sections 3.1, 3.7, 3.10, 7, 8, 10 amended; slice decisions amended (the slice's
  D10, D11, D21, D31, D32, D34, D53) and recorded as superseded in this ledger's rows; one ADR for
  the overhaul's new rules (sound provenance, the options file, the telling's clock gate, the
  presentation gate); about 25-40 UI tests rewritten in 10-13 files; about 30 new small assets.
- **First checkpoint:** after WP1, the lead plays day 1 (Ulf, Kolbeinn) on the new desk with real
  input; after WP2 the critic scores it and desk-shots measures forced time. Content beyond those
  souls waits for WP1's pass.
- **Open questions:** none.
- **Provisionally approved by the panel:** 2026-10-23. The owner's first read is the "Assumed by
  the panel" list (D4, D5, D21, D25, D32, D37). Every gate stays provisional until the owner plays
  the result; any assumption they overturn is a `design-change` on what was built from it.
