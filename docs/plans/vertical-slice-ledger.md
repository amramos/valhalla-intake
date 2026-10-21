# Vertical slice — decisions ledger

**State:** PROVISIONALLY APPROVED
**Mode:** hands-off · **Plan:** `vertical-slice-plan.md` · **Epic:** [#2](https://github.com/amramos/valhalla-intake/issues/2)
**After the plan:** build with `team-lead-handsoff` (owner's choice, 2026-10-21)

This is the owner's document: read this, not the plan. Every decision the plan relies on is a row
below; the plan cites these ids, and a reviewer checks that it holds every decision and invents none.

## Intent

- **Problem observed:** there is no game yet. GDD open question 1 can't be answered (how many
  encounters can one developer author and verify), and the desk loop has only been proven as a text
  prototype played by AI.
- **Player promise after the change:** a first-time player sits at the desk for three days and
  judges twelve encounters. They read bodies, pin contradictions and stamp souls through doors, and
  feel the squeeze between the Law and the truth. The slice ends on a consequence that names the
  souls who caused it.
- **Stays familiar:** the rules the prototype proved: instant red, grey, law and forgery threads; a
  pin with no seam costs time; Huginn answers grey threads; citations follow the Law, endings follow
  the truth (GDD §3).
- **Replaced or removed:** nothing in the game. The text prototype was already thrown away; its
  text interface returns only as a debug harness for blind AI playtesters.
- **Not doing:** days 4–8, Rán, Loki's forgery, Eyvind at the desk, Ragnarök proper, saving, a
  settings menu, and an itch.io release.
- **Cost:** this is the first feature, so no code or content is invalidated. Any GDD section the
  rounds change (for example the desk layout in §3.1) is amended in the same hand-off.

## Decisions

| Id | Question | Answer | Decided by | Date |
|---|---|---|---|---|
| D1 | Slice shape | 12 encounters = 3 days × 4 souls on the GDD's day-1–3 spine, as a compressed slice (not the demo). Every slot is assigned on purpose in a written roster before any build. Freyja's ask is deferred | panel | 2026-10-21 |
| D2 | Return arc | Exactly one return-eligible soul: a worthy man the day-2 decree "those who fled go to Hel" damns, whose saga is true. If damned, he returns on day 3 with a name plate and a dusk line ("Hakon is back"). His day-3 verdict still hinges on a contradiction, and his lines differ if the player ignored rather than missed him. If he wasn't damned, an authored fallback soul takes the slot. Both branches are tested | panel | 2026-10-21 |
| D3 | God promise | Hel's offer comes at dusk on day 2 and names one soul in tomorrow's queue. It asks the clerk to find a seam where there is none: to damn an honest soul whose only "seam" is a red herring. The reward (superseded by D29: 4 feathers at the stamp) is paid if kept. If the soul goes unjudged, the promise lapses. The offer always lands in the ledger, even when dusk is skipped, and the named soul wears a ledger mark. This is a slice exception: GDD §5 (Hel's offer on day 3 dusk, the demo's last scene) is unchanged | panel — assumed | 2026-10-21 |
| D4 | Desk layout | **A, the gate band**, provided a fully populated day 3 fits at 480×270. The HUD goes in the right column, a caption strip under the Law, and a name plate on the waiting soul. Threads never strike through text. Closed doors look locked, and every door shows its glyph and name on hover. GDD §3.1 is amended: the doors move into the gate band | panel — assumed | 2026-10-21 |
| D5 | How bodies are built | Modular: a base chart (front and back) per build, plus overlays only for the combinations the 12 cases need (no general paper-doll editor). The head and hair are an identity layer that is not clickable. Every fact, including an absence ("nothing in hand", "no wound"), is a labelled hit area of at least 8×8 px. Hands and clothes differ by shape, not tint. The standing soul shows nothing the chart doesn't. A returned soul's change never uses bile | panel | 2026-10-21 |
| D6 | Fact vocabulary | Derived from the 12 authored cases, with the distinct visual states counted. A fact stays only if the slice uses it in at least one seam and one red herring. The same back wound appears twice with different verdicts. A back wound never proves flight on its own | panel | 2026-10-21 |
| D7 | Text | One free pixel font (CC0 or OFL; ADR) that carries á, ó, ö and þ. Claims run 3–4 lines and witnesses up to 3. The per-line cap is set from a 1:1 screenshot of the final layout (about 18–22 characters). Decrees may wrap to 2 lines, and precedence wording is never shortened. GDD §3.1 says "3–4 claim lines" | panel | 2026-10-21 |
| D8 | Pinning | Hovering shows the plain-language label. The first selected item is highlighted; clicking it again or right-clicking cancels. Re-pinning an existing pair is free and highlights it. A seam becomes a thread with a distinct line pattern, and its caption says what it shows: a law thread names the destination, or says "the saga is true". A no-seam pin visibly drops the clock. A grey thread has an 8 px knot that selects it, and a separate "Ask Huginn" control spends the answer. Every pin is recorded, so ignored can be told apart from missed | panel | 2026-10-21 |
| D9 | Stamping | The first click on a door selects it and shows "Stamp <name> to <realm>?" with a separate confirm button that ignores double-clicks. It reveals nothing about correctness. Dragging the soul onto a door shows the same preview; releasing on a door commits, and releasing anywhere else cancels. A visual thud follows: a short hold, a door flare, the soul walking through. No undo | panel | 2026-10-21 |
| D10 | Day clock | Real time, the length tunable in data. It starts at about 5 minutes for 4 souls and runs only while a soul is at the desk. **Day 1 is untimed.** A no-seam pin costs 10 s and a Huginn answer 5 s. The clock is shown, pauses on a key press and when the window loses focus, and the harness simulates elapsed time per action. GDD §3.7 now reads "real time, plus action costs" | panel — assumed | 2026-10-21 |
| D11 | Audio | Two placeholder sounds only, the stamp thud and "seam found", from a CC0 source and credited. No ambience or music | panel (dissent: player advocate and skeptic preferred no audio) | 2026-10-21 |
| D12 | What the slice measures | Setup time logged apart from each encounter's writing, art, verification and rework, unused branches included. The GDD's automatic authoring check is built in the slice and its runs count as verification. Playtester time per soul is logged too. Results are reported as ranges by case complexity | panel | 2026-10-21 |
| D13 | AI-playable | A debug-only text harness sharing the UI's commands and state, exposing only what the desk shows (never destinations or the seam list). It can jump to any day and soul for screenshots. AI playtesters play first; the owner plays later | panel | 2026-10-21 |
| D14 | Saving | None in the slice; parked | panel | 2026-10-21 |
| D15 | Dusk | A sequence of cards with "Next" and "Skip all". It summarises the citations already given at the stamp. Skipping hides nothing that has consequences. Day 3's dusk is the slice-ending screen, listing every soul with the verdict beside the truth | panel | 2026-10-21 |
| D16 | The mentor | On screen at the next desk. On soul 1 she walks the player through read, pin and stamp, one step at a time. She highlights a pair, and the player makes the pin. She guides 3 souls in all. After that she only comments, telling an illegal stamp apart from a deliberate mercy, and each warning names the visible pair | panel | 2026-10-21 |
| D17 | After the plan | Build with `team-lead-handsoff`: reviewed PRs merge to `main` without the owner | owner | 2026-10-21 |
| D18 | Agents merging to `main` | ADR-0007: agents still never commit to `main`. The lead may merge a reviewed PR only through the hands-off merge checklist (CI green, reviewer approves, exported-build smoke test, pre-merge tag) | owner (rec) | 2026-10-21 |
| D19 | No branch protection (private repo, current plan) | The merge checklist enforces CI: the lead checks that CI is green on the PR's latest commit before every merge | owner (rec) | 2026-10-21 |
| D20 | Reviewer identity | Codex reviews each PR, and its verdict is posted as a PR comment that gates the merge checklist | owner (rec) | 2026-10-21 |
| D21 | HUD and caption placement | **A3**, with these placements and fixes: <ul><li>**HUD:** top-right of the gate band; the clock, feathers and Huginn's answers each as an icon with a number, in parchment or grey (never a reserved colour); rank shown only at dusk; the ledger an icon with a badge for an open promise.</li><li>**Doors:** a door's name and glyph show on hover, not painted over its art; a locked door shows a bar and a dimmed glyph.</li><li>**Hel's tide:** 6 px figures, with empty slots up to the threshold.</li><li>**Name plate:** Hel's mark is the serpent glyph, with a hover label.</li><li>**Mentor:** a real portrait.</li><li>**Controls:** "Ask Huginn" under the HUD, the stamp confirm by the doors.</li><li>**Fit check:** the first build step is a 1:1 screenshot of the longest text, the knots, both controls and the captions, before any content is authored.</li></ul> | panel | 2026-10-21 |
| D22 | Day-3 queue, and the clock running out | The day-3 queue runs Freydis, then Hakon (returned) or Egil, then Ragna, then Ketil. A warning shows at 30 s left. At the horn, an unjudged named soul lapses Hel's promise (shown in the ledger), and an unjudged soul is "never judged" on the ending screen | panel | 2026-10-21 |
| D23 | The slice ending | It counts each encounter by its **worthy destination**: <ul><li>Hel's tide is any soul not worthy of Hel that was stamped to Hel;</li><li>the hollow hall is any soul not worthy of Valhalla that was admitted to Valhalla;</li><li>returned Hakon counts as his own encounter and is named twice.</li></ul> Thresholds live in data, initially tide 3 or more and hollow 2 or more; otherwise the Hall holds. Cast down can't happen in three days, so the slice ending leaves it out; demotion still works. The screen names the souls, marks ignored or missed, lists anyone never judged, and has "Play again" | panel | 2026-10-21 |
| D24 | A pin on a red herring | "No seam", plus 10 s, like any other pin. The innocent explanation is readable in the soul's own lines (and the witness's where there is one), never in a caption | panel | 2026-10-21 |
| D25 | The roster | The 12 slots of round 2, fixed so every verdict hinges on a strict contradiction:<ul><li>**Ulf:** the mentor highlights his claim against L1, and the law thread reads "the saga is true".</li><li>**Hakon:** worthy of Valhalla on both days. On day 2 his claim admits leaving the shield-wall carrying Ivar; on day 3 his only seam is the lie Hel taught him (Hel by L2, or mercy). He has no Fólkvangr route.</li><li>**Brand:** soft hands against "thirty winters at the oar" (the clean blade can't be seen).</li><li>**Hallr:** a broken neck and no cut against a sword death.</li><li>**Grim:** wet to the knee against "I never left the hill".</li><li>**Ketil:** a body that fits Valhalla, so only the grey thread decides him; no other day-3 soul needs Huginn on its own.</li><li>**Ragna:** a law thread to L5. Her night-shirt red herring is explained in her own claim.</li><li>**Every fact state** gets a seam use and a red-herring use somewhere in the 12 souls, or it is cut.</li><li>**Slots 5–7** each carry a clearly different second fact.</li></ul>Builders may change names and lines, never a slot's purpose | panel | 2026-10-21 |
| D26 | Evidence auditor | A blind review gate run by a different model. It sees only desk screenshots and hover labels, absences included, for both Hakon variants and Egil. It reports the seams it sees, hit areas it couldn't read or click at 1:1, any law-thread wording that differs from the decree on screen, and visible seams nobody authored. The lead settles each discrepancy against the evidence; exact agreement with the authored list isn't required | panel | 2026-10-21 |
| D27 | Does it feel like judging a death? | Every human detail sits in a pinnable line, so the authoring check and the auditor cover it. Before any outcome is revealed, blind testers are asked which verdict mattered, why, and on what evidence, and they name three souls from memory without a prompt. The owner's play is the final gate | panel | 2026-10-21 |
| D28 | Mercy is free on days 1–2 | In this compressed slice, **citations start on day 2**. Day 1 alone gives warnings, and the mentor says "from tomorrow this costs feathers". Day 2's quota is 1, so mercy on Hakon is a straight −2 feathers against tide +1. Playtests measure how often the return arc fires; mercy is a valid result, not a failure. This is a slice exception to GDD §3.7 | panel — assumed | 2026-10-21 |
| D29 | Hel's reward | Hel pays **4 feathers at the stamp** (net +2 before the daily loss cap). In this slice the offer is tested mainly through tide +1, because feathers don't feed the slice ending. The ending screen shows final feathers and rank as the clerk's standing. Playtests log feathers when entering day 3 and how many testers keep the promise. "Extra answer: 2 feathers" sits by Huginn's icon | panel | 2026-10-21 |
| D30 | Huginn's budget and introduction | 2 answers on day 3, each costing 5 s; a third costs 2 feathers. A dawn card says what he does: he answers only about a thread you already made. The mentor adds one line on the first grey thread. Day 2's grey thread (Grim) is settled by the body, and no day-3 soul before Ketil needs him | panel | 2026-10-21 |
| D31 | The shell | Title: Start and Quit. Esc pauses and dims the desk, offering Resume, **Restart the run** (confirmed; it restores the whole day-1 dawn state) and Quit (confirmed). The ending screen has "Play again". There is no "restart the day" (that would be an undo) and no settings | panel | 2026-10-21 |
| D32 | The decree text | <ul><li>**L1:** "Valhalla takes only those slain by a weapon in battle. Death by sickness, age or accident goes to Hel."</li><li>**L2:** "Whoever lies to the Gate goes to Hel, whatever else the Law says."</li><li>**L3:** "Even so, a warrior without a weapon in hand goes to Hel."</li><li>**L4:** "Even so, those who fled the battle go to Hel."</li><li>**L5:** "Those who fell defending hearth and kin go to Fólkvangr, whatever L1, L3 and L4 say."</li></ul>Roster constraints: Ivar is not Hakon's kin, and carrying him never reads as defending. Hel's lie for returned Hakon sits in a claim line. The text must pass the D21 fit check | panel | 2026-10-21 |
| D33 | Caption priority | A citation comes first, then the newest thread's caption, then Huginn's answer, then the mentor's comments. Each message holds at least 3 s, and a deliberate click on a thread, the mentor or the feather takes the strip over. Huginn's answer stays on its thread. The citation's black feather stays on the desk until the next soul. The mentor's guided-step prompts use a bubble by her portrait, never the strip | panel | 2026-10-21 |
| D34 | The dawn card | Each day opens with one card: the quota, the clock (or "untimed"), new decrees, doors that opened, and rule changes (day 2: "citations begin today"; day 3: Huginn). The new decree and the newly opened door carry a "NEW" mark until the day's first stamp | lead (from the player advocate) | 2026-10-21 |
| D35 | Daily quotas | Day 1: 1 (Ulf is the only lawful Valhalla soul; mercy on Asa is a surplus). Day 2: 1 (D28). Day 3: 2 (Freydis is the only lawful one, so admitting a liar such as Ketil, or mercy, fills it). Stored in data | lead | 2026-10-21 |
| D36 | Feather and clock accounting | Losses (citations, quota shortfall) are capped at 5 a day. Spends (Huginn's extra answer) are never capped and never count as losses. Rewards apply after the stamp's citation. Demotion is checked after every change and refills to 5. If the clock runs out during an action (a stamp, a Huginn answer), the action completes, then the horn sounds | lead | 2026-10-21 |
| D37 | A wrong stamp on an unresolved grey thread | Permitted uncertainty: no citation, because the desk couldn't prove which side lied (GDD §1, test 2; prototype lesson). It still counts toward the ending by the worthy destination, and the recap says "couldn't be proven at the desk" | lead (from the GDD) | 2026-10-21 |
| D38 | Seams, law threads and "no seam" | Two kinds of seam. A **lie seam** (red or grey) is evidence against testimony. A **law thread** links a piece of evidence to the decree that decides the soul and names that destination; it may confirm, as in "the saga is true" (Ulf, Asa, Ragna). Both draw threads, and both count as seams for pinning and citations. Hel's "find a seam where there is none" (D3) means Ragna has **no lie seam**; her L5 law thread exists | lead (from the review) | 2026-10-21 |
| D39 | The evidence matrix, before any build | The first work package writes a slot-by-slot evidence matrix for all 15 encounters (12, Egil, and both Hakon variants). For each: facts, line intents, each lie seam and law thread, the red herrings with where their explanation lives, legal and worthy destinations, permitted uncertainty, and the human detail. Plus a coverage table showing each fact state's seam and red-herring use. The designer checks it against GDD §3.6 and D25/D32 before any content or art is built. Egil's purpose: the fallback that keeps day 3's Law-against-truth beat (a liar who died defending kin; worthy Fólkvangr, legal Hel by L2) | lead (from the review) | 2026-10-21 |
| D40 | Values the slice takes from the GDD unchanged | The clerk starts with 10 feathers; meeting the quota pays +2; a shortfall costs −1 per soul (GDD §3.7–3.8). The worthy destination is always an open door that day (GDD §3.6). The number of body builds is whatever the matrix needs, with the fewest that cover the roster | lead (from the GDD) | 2026-10-21 |
| D41 | Who plays at each checkpoint | 3 blind AI playtesters on different models per checkpoint (WP1 and WP6), plus the lead's own playtest at every package | lead | 2026-10-21 |
| D42 | When the clock gets tuned | If careful playtesters end days 2–3 with more than 30% of the clock left, the clock length in data is shortened before the slice is called done. The thresholds are reported, not hidden | lead | 2026-10-21 |
| D43 | If the return arc or the promise never fires | It is reported with the playtest numbers, and the roster isn't changed on that alone: mercy is a valid result (D28). The owner decides after playing | lead | 2026-10-21 |
| D44 | What a law thread's caption names (from the evidence matrix, WP0) | A law thread links evidence to a decree whose condition that evidence shows, and its caption names where **that** decree sends the soul. Precedence between decrees is read from their text ("Even so", "whatever else the Law says"), never stated by a caption. So Egil can show an L5 thread to Fólkvangr while L2 still sends him to Hel. Asa's matrix drops her L1 thread, so the first unguided soul shows one clear thread (L3) | lead (build) | 2026-10-21 |
| D45 | Law threads must not leak who lies | There is no law thread from a line the body shows false, from either line of a grey seam, or on a soul decided by a grey seam alone (Ketil). Otherwise "the saga is true" would answer the question the player must work out. The authoring check (WP4) asserts this | lead (build) | 2026-10-21 |
| D46 | Returned Hakon's witness | None. His witness panel reads "No witness came back." Any witness would add a seam that breaks D25's "his only seam is the lie Hel taught him". The desk and the harness must handle an empty witness panel on day 3 | lead (build) | 2026-10-21 |
| D48 | When the next soul arrives after a citation (from the core review) | After a stamp that draws a citation (or a day-1 warning), the stamped soul stays on the desk with its cited pair lit and the black feather showing; the next soul arrives only when the player clicks "Next soul". The clock doesn't run meanwhile. Without a citation the next soul arrives at once. This is how D33's "clicking the feather lights its pair" can work: the pair must still be on the desk | lead (build, from review) | 2026-10-21 |
| D49 | Decree wrap (from the WP1 fit check) | Supersedes D7's "decrees may wrap to 2 lines": decrees wrap to **at most 3 lines**. In m5x7 no layout puts L1 on 2 lines while the claim column survives; the A3 Law panel holds L1–L5 verbatim (3/2/2/2/3 lines) with 12 px spare | lead (build, fit check) | 2026-10-21 |
| D50 | Testimony line cap (from the WP1 fit check) | Supersedes D7's "about 18–22 characters": a claim or witness line, **prefix included, is at most 132 px in m5x7** (about 20–21 characters). Panels never wrap testimony. WP4 rewords the matrix lines that run over, and the authoring check measures widths with the font | lead (build, fit check) | 2026-10-21 |
| D51 | Layout numbers (from the WP1 desk and the WP2 art) | The built desk is the reference: gate band 0–96 px; body chart x 2–130; claim and witness 134–270; Law 274–478; caption strip 134–478 at y 246–268. The art is placed to these numbers, and the body-chart panel uses Night 3 so dark tunics keep their silhouette | lead (build) | 2026-10-21 |

**Assumed by the panel** (the owner skims these first):
- **D3:** Hel's offer moves to day-2 dusk in the slice, so it can resolve. The demo's last scene in
  the GDD is unchanged.
- **D4 / D21:** layout A3. The doors move from the desk's right column into the gate band, and the
  HUD goes into the gate band's corner (GDD §3.1 amended).
- **D10:** a real-time clock (about 5 minutes for 4 souls, tunable), with day 1 untimed (GDD §3.7
  amended to "real time, plus action costs").
- **D28:** citations start on day 2 in the slice, and day 2's quota is 1, so mercy has a price
  (slice exception to GDD §3.7).

## The experience, walked through

1. **Title → day 1 dawn.** Start. The dawn card reads: "Day 1. Odin wants 1 for Valhalla. Untimed.
   The Law: L1, L2, L3." The desk opens: the gate band with Valhalla's spear door and Hel's serpent
   door (Fólkvangr's boar door barred), Huginn's empty perch, and Ulf waiting with his name plate.
2. **Learning the verb (Ulf).** The mentor's bubble: "Read the body first." Hovering shows labels
   ("axe wound, front", "sword, gripped"). She highlights his claim C1 and decree L1; the player
   clicks one, then the other, and a law thread draws: "C1–L1: the saga is true. L1 sends him to
   Valhalla." She points at the doors. The player clicks the spear door, "Stamp Ulf to Valhalla?",
   and confirms. A short hold, the door flares, and Ulf walks through.
3. **The first lie (Kolbeinn).** She highlights the body's "no wound" and his claim "three Danes cut
   me down"; the player pins them, and a red thread draws: "the body gives the lie". He goes to Hel.
   Hallr follows: a broken neck and no cut against "his blade opened my throat".
4. **The first squeeze (Asa).** Unguided now. Her saga is true, but nothing is in her hand: the law
   thread reads "the saga is true. L3 sends her to Hel". The quota is already met. Stamping her to
   Valhalla is mercy, and the mentor says: "Kind. From tomorrow, that costs feathers." Stamping her
   to Hel adds the first figure at Hel's door.
5. **Dusk, day 1.** Cards: the quota, a recap of up to 3 souls (what really happened), Skip all.
6. **Day 2.** The dawn card: "Witnesses arrive. NEW: L4, those who fled go to Hel. Citations begin
   today. 5 minutes." The clock runs.
   - Sigvaldi's back wound looks like flight, but a pin on it finds "no seam" (−10 s): his witness
     explains the gap in the wall.
   - Hakon admits he left the shield-wall carrying Ivar. His law thread reads "the saga is true. L4
     sends him to Hel." The quota is 1, already filled by Sigvaldi, so mercy costs −2 feathers
     outright.
   - Grim: wet to the knee against "I never left the hill" (a red thread).
   - Brand: soft hands against "thirty winters at the oar".

   Dusk: Eyvind's prayer names their father's ring. Then Hel's offer: "Tomorrow, Ragna. Send her to
   me and I'll pay four feathers." The ledger badge lights up.
7. **Day 3.** The dawn card: "Huginn perches on your desk. Fólkvangr opens. NEW: L5."
   - **Freydis** goes to Valhalla.
   - **Hakon is back** if he was damned. A frost-burned name plate, and the dusk line had warned
     "Hakon is back". His claim holds one lie Hel taught him; pinning it gives a red thread. The
     player chooses: L2 sends him to Hel again, or mercy.
   - **Ragna** wears Hel's serpent mark. Her law thread reads "L5 sends her to Fólkvangr". Keeping
     Hel's promise means a black feather (−2) for the 4 feathers paid, and one more figure at Hel's
     door.
   - **Ketil:** his claim and his witness disagree (a grey thread, with its knot). The player
     selects it and asks Huginn: "The claim lies."
8. **Failure, two kinds:**
   - **A miss.** On day 2 the player never pins Grim's wet boots and admits him. A black feather
     drops: "Citation: L2. His boots, wet to the knee, against 'I never left the hill'." The pair
     lights up, and the recap marks Grim *missed*.
   - **Uncertainty.** On day 3 the player admits Ketil without asking Huginn, to fill the quota.
     The grey thread was never resolved, so there's no citation (D37). At the ending, Ketil stands
     in the hollow hall.
9. **The horn and the ending.** Day 3's dusk is the slice ending, for example: "Hel's tide: Asa,
   Hakon, Hakon (returned) march with Hel." It lists every soul with the verdict beside the truth,
   ignored or missed, shows the clerk's standing, and offers "Play again".
10. **Cancellation and unavailable actions:**
    - clicking the first item again cancels a pin;
    - releasing a drag off a door cancels it;
    - the barred boar door says "Closed until day 3";
    - "Ask Huginn" is greyed when no grey thread is selected or no answer is left;
    - Esc pauses and dims the desk.

## Sketches

Three desk layouts, drawn over the style-guide art at 480×270 (shown ×2):

| Option | File | For | Against |
|---|---|---|---|
| A. Gate band | `vertical-slice-sketches/A-gate-band.png` | Matches the chosen style frame; the doors, Huginn and the waiting soul are the world, and the desk is all evidence | The doors are a long drag from the desk; less room for the Law |
| B. GDD-literal | `vertical-slice-sketches/B-gdd-right-column.png` | Exactly GDD §3.1; doors sit next to the Law they enforce | The doors shrink into tiles and lose the glow that defines the style; the top band is empty mood |
| C. All desk | `vertical-slice-sketches/C-all-desk.png` | The most room for evidence and text | Loses the gate, the doors' glow and Huginn's perch; the world disappears |

**Chosen: A, refined to A3** (`vertical-slice-sketches/A3-populated-x3.png`): drawing A fully populated at 1:1 (`A2-populated-x3.png`) showed the Law could not fit five decrees verbatim beside a HUD column, so the HUD moved into the gate band's empty corner (D21).

Shipped-game references:
- *Papers, Please*: a band of the world above the work desk (borrowed by A).
- *Death and Taxes*: everything on one desk surface (borrowed by C).
- *Return of the Obra Dinn*: the body as the evidence surface (all three).

## Review (big plans)

- **Reviewer:** Codex, another vendor's model, in a fresh session (not the panel's skeptic).
- **Ledger → plan:** eleven decisions were missing details or weakened in the plan:
  - D1 (roster before build);
  - D5/D6 (no bile; one back wound, two verdicts);
  - D7 (CC0 or OFL);
  - D18–D20 (the per-merge gate);
  - D25 (each slot's seam);
  - D26 (both Hakon variants and Egil);
  - D27 (every human detail);
  - D29 (the label);
  - D32 (Ivar never defending);
  - D36 (demotion after every change);
  - D37 (recap wording).

  All are now stated in the plan's requirements or traceability. D3's 3-feather reward is marked as
  superseded by D29.
- **Plan → ledger:** five choices weren't in the ledger:
  - the GDD's economy constants and the open-worthy-door rule, now D40;
  - "two body bases", now "as many builds as the matrix needs" (D40);
  - three testers per checkpoint, now D41;
  - the 30% clock threshold, now D42;
  - "revisit the roster if the arc never fires", replaced by reporting it (D43).
- **Challenges:**
  - *The fit check without the final font* → the font moves into WP1 (D7/D21).
  - *"No seam" for Ragna, and a confirming pair for Ulf, clash with "seam = contradiction"* → D38
    defines law threads.
  - *No slot-by-slot evidence matrix* → WP0 writes it before any build (D39).

## Approval record

- **Authorized experience:** three days at the desk, twelve encounters. The player reads bodies,
  pins lie seams and law threads, and stamps through glowing doors under a real-time clock from
  day 2. One soul can return from Hel. Hel offers a bargain about one soul. The slice ends on a
  consequence that names the souls who caused it.
- **Preserved / removed:**
  - preserved: the prototype's red-thread rules and the GDD's economy;
  - replaced: the setup placeholder scene;
  - not built: days 4–8, Rán, the forgery, Eyvind at the desk, saving, settings, music.
- **Cost:**
  - GDD amendments: §3.1 layout (A3), §3.7 clock (real time), §5 decree wording (D32), claim lines
    3–4;
  - slice exceptions (D3, D28) that the full game revisits;
  - ADR-0007 (agents merge through the checklist);
  - ADR-0008 (the font).
- **First checkpoint:** after WP1, the minimal playable desk with Ulf and Kolbeinn and the fit-check
  screenshot. The lead plays it, and 3 blind AI playtesters play it through the harness. Content
  beyond those 2 souls pauses until it passes.
- **Open questions:** none.
- **Provisionally approved by the panel:** 2026-10-21. The owner's first read is the "Assumed by the
  panel" list (D3, D4/D21, D10, D28). Every gate stays provisional until the owner plays the slice.
