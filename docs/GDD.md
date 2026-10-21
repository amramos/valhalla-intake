# Valhalla Intake — Game Design Document

**Provisional** — written by an agent panel from a short intake; the decisions marked *assumed* in
the appendix are the owner's to confirm.

**Version:** 0.1 · **Last full revision:** 2026-10-21
**Amendments:** 2026-10-21 — **core loop chosen by prototype: pins are validated instantly, as threads; a pin with no seam costs extra time (§3.3, Appendix A)**
2026-10-21 — **vertical-slice planning: the desk becomes layout A3, doors in the gate band; the clock runs in real time plus action costs; claims run 3–4 lines; decree wording made consistent (§3.1, §3.7, §5; `docs/plans/vertical-slice-ledger.md` D4, D7, D10, D21, D32)**

This is the **single source of truth for design and scope**. Where it conflicts with an older ADR,
this document wins and the ADR gets a superseded note. Where it conflicts with the code, the code
wins for *what exists today*, and this document describes *what is being built*.

Markers: **[BUILT]** is shipped behavior. **[DESIGNED]** is specified but not built. **[OPEN]** is a
decision deliberately not made yet — it needs an answer from the owner, never an invented one.

---

## 1. Pitch

You are a valkyrie clerk at the gate of Valhalla, eight days before Ragnarök. The dead queue at
your desk, each with a heroic saga of how they died, and you must judge from their bodies, their
words and their witnesses whether that death earns Valhalla, Fólkvangr, Hel or Rán.

**The fantasy:** being the cold, overworked official who decides who was a hero, under a god who
keeps changing what heroism means.
**The hook:** the evidence is the death itself. A wound in the back, an empty hand or dry clothes on
a man who "hid in the river" can expose a lie. The worthy souls you damn come back from Hel to
fight against you at Ragnarök.

**Closest comparables:** Papers, Please (decrees that pile up day by day, at a desk, under time
pressure), Death and Taxes (a god-boss and visible consequences of your verdicts), Return of the
Obra Dinn (a death read as evidence), Valkyrie Profile (a god redefining the "worthy hero").

### The rule that governs everything

> **Every verdict is a contradiction you found, or chose to ignore.**

Two tests make this rule checkable, and any mechanic or case that fails them is cut:
1. No verdict hinges on anything but a contradiction. A contradiction can be between two pieces of
   evidence, or between the truth and a decree.
2. No citation is ever given for a contradiction the player could not have seen at the desk.

## 2. Core loop **[DESIGNED]**

- **Moment to moment:** a soul stands at the desk. You read the **body**, the **claim** and, from
  day 2, a **witness**. You **pin** pairs of evidence that contradict each other (or contradict the
  **Law**). Then you **stamp** the soul through a realm door. An honest soul takes about three
  clicks; a hard one takes a minute of thought.
- **Session (one day, ~8–10 minutes):** dawn brings Odin's **quota** and any new **decree**. You
  work the queue against a day clock until the **dusk horn**. At dusk you get **citations**, quota
  feathers, and a **recap** that reveals the truth about two or three souls. There are also god
  requests and, on some days, one story beat. Everything between days fits in about 90 seconds and
  can be skipped.
- **Long loop (8 days, ~90–120 minutes):** the Law grows, realms open, souls you wronged return,
  and Eyvind, your brother, moves toward your queue. On day 8 the horn becomes Ragnarök. The ending
  is computed from your record of verdicts and names the souls that caused it.
- **Win and loss:** there is no game over mid-run. Running out of **feathers** costs you a **rank**.
  Running out at the lowest rank is the *Cast down* ending, and you may retry the current day.

## 3. Mechanics **[DESIGNED]**

### 3.1 The desk
One screen, no page-flipping, at 480×270. This is layout A3; see
`docs/plans/vertical-slice-sketches/A3-populated-x3.png`.
- **Gate band** (top): the realm doors with their glyphs; Huginn on his perch; the waiting soul with
  a name plate. The HUD sits in the top-right corner: clock, feathers, Huginn's answers, and the
  ledger tray.
- **Left of the desk:** the body, shown front and back side by side like a coroner's chart; the
  mentor's portrait below it.
- **Centre:** the claim (3–4 short lines in the soul's own voice) and the witness (2–3 lines).
- **Right:** every active decree, word for word.
- **Bottom:** a caption strip for thread captions, Huginn's answers, citations and the mentor's
  comments.

Every item that can be part of a contradiction is visible at once. Every body fact has a
plain-language label on hover. Mood (fog, torchlight) never covers the body.

### 3.2 Evidence
- **Body:** about 12 facts, introduced across the days, each with a one-line tooltip the first time
  it appears:
  - wound location (front/back/side);
  - wound kind (blade, arrow, axe, spear, knife, bite, none);
  - what is in hand (gripped, nothing, broken);
  - hands, clothes and feet;
  - trinkets;
  - lungs (brine/clear, from day 5).

  The **body never lies**, but it shows events, not motives. A back wound does not prove a man fled.
  Every fact must be able to contradict at least one claim line, witness line or decree, or it is
  cut.
- **Claim:** the soul's own saga of its death. It can lie.
- **Witness:** a fellow dead soul's account, from day 2. It can lie for reasons such as kinship, a
  grudge or shared cowardice.
- **Law:** Odin's decrees. Its lines can be pinned like any evidence.

### 3.3 Pinning (the core verb)
Click one piece of evidence, then a second, to **pin** them. A pin that finds a true contradiction
becomes a **thread**:
- **red:** a body fact against a claim or witness line. This settles it, because the body never
  lies.
- **grey:** a claim line against a witness line. One of them lies, and the pin doesn't say which.
- **law:** a body fact or testimony line against a decree. It shows where the Law sends this soul.
- **forgery:** one decree against another (day 7 onward).

**Instant validation** was chosen by the prototype (Appendix A). A pin that finds a seam becomes a
thread at once and says what it shows. A pin that finds nothing says "no seam" and costs extra
clock time, which makes pairing everything with everything visibly expensive. A thread says *what*
contradicts. Only a law thread names where the decree sends the soul, and on an honest soul it says
so ("the saga is true").

### 3.4 Huginn
Odin's raven arrives on day 3. He **never discovers** anything: he only answers about a thread or
pin the player already made. He tells which side of a grey thread lies. He gives 2 answers per day. You can buy one more by
offering him 2 feathers, which is the only thing feathers buy.

### 3.5 Stamping and the realms
Send the soul through a door by dragging it or clicking the door. There is no undo. The realms are
told apart by evidence, never by a quota split:
- **Valhalla** (from day 1): slain by a weapon in battle, seeking it, weapon in hand.
- **Hel** (from day 1): sickness, age, accident, cowardice, lies.
- **Fólkvangr** (from day 3): fell defending hearth and kin.
- **Rán** (from day 5): the drowned. Brine in the lungs gives away a "sword-death".

### 3.6 Law and truth
Every soul has two destinations:
- its **legal destination**, where the Law sends it;
- its **worthy destination**, what the truth deserves.

Citations follow the Law. Endings, the souls who return from Hel, and Eyvind's closing line follow
the truth. An honest soul you damn because a decree demands it costs you no citation, but it adds
to **Hel's tide**. Sending that soul where it deserves costs a citation. This gap between law and
truth is the moral engine.

Rules that keep it fair (from the prototype, Appendix A):
- **Worthiness is visible when you choose.** A law thread on an honest soul says so ("the saga is
  true"), and Hel's door shows the tide as a growing line of figures. You always damn the worthy
  knowingly.
- **The worthy destination is always an open door** on that day.
- **Precedence is written into the decrees themselves.** The lying decree reads "…goes to Hel,
  whatever else the Law says". A newer decree may narrow an older one but never contradicts it.
  Two decrees that contradict each other always mean Loki's forgery.

### 3.7 Pressure: clock, quota, citations
- **Day clock:** real time while a soul is at the desk, plus action costs (a pin with no seam, a
  Huginn answer). The dusk horn ends the day, and souls not judged by dusk simply go unjudged.
- **Quota:** Odin wants N souls in Valhalla each day. Meeting it earns +2 feathers; each soul short
  costs −1. It is never an instant fail, and it is the main pressure to ignore a seam.
- **Citation:** a stamp that breaks the Law where a contradiction was visible costs −2 feathers. A
  raven drops a **black feather** on the desk with one dry line naming the decree and the visible
  pair. If you had pinned that seam yourself, it adds "You threaded it yourself." Clicking the
  feather highlights the pair. Days 1–2 give the mentor's warning instead. Citations land at the stamp, in step with instant pin feedback.
- **Ignored vs missed:** a wrong stamp after you pinned the seam is recorded as *ignored*, otherwise
  as *missed*. The citations are the same, but recaps, returning souls and Eyvind speak to you
  differently.

### 3.8 Feathers and rank
Feathers are your standing, and they are the only currency. You start with 10. Losses are capped
at 5 per day so one bad day can't spiral.

The ranks are **Chooser of the Slain**, **Gate-warden** and **Hall-sweeper**. At 0 feathers you
drop a rank and refill to 5; the terms do not get harsher. At 0 as Hall-sweeper comes the *Cast
down* ending, with a retry of the current day only. Earlier verdicts stand.

### 3.9 The gods' requests
There are no favour meters. Each request is a concrete promise about **one seam in one soul**,
recorded in the ledger:
- **Odin demands:** the quota, and on day 4 a doubled quota.
- **Freyja asks:** for a particular soul to reach Fólkvangr.
- **Hel offers:** feathers in exchange for a particular soul.

A request either asks you to ignore a seam, or to find one where there is none. A request about
anything else is off-rule and is cut. Loki appears only in the story, and in his forgery.

### 3.10 Dusk
Dusk takes 90 seconds or less, and every beat can be skipped:
- citations and quota;
- the **recap**: what really happened to 2–3 souls, telling a broken decree apart from an
  unresolved truth;
- new requests;
- at most one story beat.

## 4. Progression and economy **[DESIGNED]**

**Within a run, what carries over:**
- feathers and rank;
- the ledger of promises;
- the record of verdicts (correct, missed, ignored, mercy);
- the souls you wronged, who return later;
- Eyvind's recorded answer;
- the Law, which only grows.

**Never carried over:** nothing persists between runs except the endings you have seen. There is no
meta-progression and no unlocks.

**Endings**, in order of precedence and computed only from the verdict record:
1. **Cast down:** you join the queue yourself.
2. **Hel's tide:** too harsh. The worthy you damned break the line.
3. **The hollow hall:** too lenient. The liars you admitted flee.
4. **The Hall holds.**

Each ending names the souls that tipped it. Eyvind's verdict colours each one with a closing line.
The thresholds are tuned by playtest.

## 5. Content **[DESIGNED]**

| Kind | Amount for the first release | Authored or generated |
|---|---|---|
| Days | 8 (demo: days 1–3) | authored |
| Encounters (souls at the desk, returns included) | ~50–70; final count set after the vertical slice **[OPEN]** | authored, each with facts, actual events, legal destination, worthy destination, valid pin pairs, permitted uncertainty |
| Recurring named arcs | 3 (one is the day-6 soul returned from Hel) + Eyvind | authored |
| Decrees | ~10, incl. one reversal (day 6) and one forgery (day 7) | authored |
| Body facts | ~12 | authored |
| God requests | ~8 | authored |
| Endings | 4 + Eyvind's closing variants | authored |
| Dusk story beats | ~6 (incl. Eyvind's two) | authored |

**Day spine** (each day changes exactly one rule or one tension):

1. Valhalla and Hel; body + claim; the mentor hand-holds the first 3 souls. The decrees in force:
   "Valhalla takes only those slain by a weapon in battle. Death by sickness, age or accident goes
   to Hel", "Whoever lies to the Gate goes to Hel, whatever else the Law says" and "Even so, a
   warrior without a weapon in hand goes to Hel".
2. Witnesses arrive, and with them grey threads. New decree: "Even so, those who fled the battle go
   to Hel".
   Eyvind's prayer reaches your shrine.
3. Fólkvangr opens, Huginn arrives, and Freyja makes her first ask. Dusk ends on **Hel's first
   offer, naming a soul you damned**, which is the demo's last scene.
4. Odin doubles the quota, and Hel's offer comes due.
5. Rán opens (lungs), and a famous hero whose saga everyone knows turns out to be false. Eyvind's
   question.
6. The first soul you wronged returns from Hel. A decree reversal ("cowards' sons admitted") makes
   some earlier verdicts wrong in hindsight; no citation.
7. Loki's forged decree, found by pinning it against an older decree ("Odin never takes back his
   word"). The tell stays on the desk all day: the mentor's warning is pinned beside the Law, and
   the forged decree's seal is still wet.
8. Eyvind is in the queue, wearing the father's ring he spoke of. His saga has a seam. Then the
   dusk horn becomes Ragnarök.

**Soul mix:**
- Day 1 is about 65% honest, with 2 obvious liars.
- Hard cases start on day 3 and make up about 25–30% by day 7. A hard case is an honest soul the
  Law damns, or a body that only a second channel or Huginn can resolve.
- From day 2, about half of honest souls carry a red herring: a seam that resolves as innocent.
- After day 2, never more than 3 honest souls in a row.

**Authoring check:** an automatic check confirms that every soul whose stamp can earn a citation
has a visible valid pair, and that every body fact used can contradict something.

## 6. Story and tone **[DESIGNED]**

**Premise:** eight days before Ragnarök, Odin needs einherjar. The gate is understaffed, the Law
keeps changing, and everyone lies about how they died.

**The player** is the unnamed "clerk", a junior valkyrie. A senior valkyrie at the next desk is the
mentor: she teaches by pointing at pairs, never at single facts, and afterwards only comments.

**Eyvind**, the clerk's mortal brother, can't be protected or bought safe. He appears in two short
beats:
- on day 2 his prayer names their father's ring;
- on day 5 he asks, "if my saga isn't true, would you still let me in?", and your answer is
  recorded.

On day 8 he reaches the desk, and the game tests whether you keep your word.

**Tone:** deadpan bureaucratic dark comedy over slowly creeping dread. The jokes are aimed at the
gods' administration and at the dead's self-serving sagas, never at their suffering. The days
darken toward Ragnarök.

**Delivery:** short text at the desk and at dusk. There is no voice acting, no cutscenes beyond
still frames, and no fourth-wall or meta tricks.

## 7. Art and audio direction **[DESIGNED]**

- **Style:** limited-palette pixel art.
- **Camera and resolution:** a fixed desk view at about 480×270, scaled by integer zoom. Text is
  rendered crisp above the art layer.
- **References:**
  - **Papers, Please:** a cold desk UI, a limited palette, the feel of the stamp.
  - **Dredge:** fog and a dusk palette, unease creeping into a cosy routine.
  - **Return of the Obra Dinn:** the death tableau read as evidence. Used for ideas only; it is not
    a fidelity target.
  - **Norwegian stave-church carving:** UI ornament.
- **Palette mood:** ash greys and cold blues, ember orange for Valhalla's door and bile green for
  Hel's. Colour is never the only cue: threads and doors also differ by pattern or icon.
- **Audio mood:**
  - low drones, distant horns, wind, raven calls;
  - silence while you inspect, a hymn at dusk;
  - the **stamp thud** is the most satisfying sound in the game, and a distinct **"seam found"**
    sound is the second.
- **Marketing:** a separate painted key-art piece for the capsule: a bloodied soul, an ember door
  and a raven on cold grey.

## 8. Platform and business **[DESIGNED]**

- **Engine and input:** Godot 4. Mouse only; every drag has a click alternative.
- **Platforms:** Windows and web first. Mac and Linux follow once the demo validates.
- **Session length:** days of about 8–10 minutes, a first run of about 90–120 minutes. Autosave at
  each dawn.
- **Accessibility:** text size and dialogue fast-forward.
- **Price and store:**
  - a free web demo of days 1–3 on itch.io;
  - the full game for $9.99 on itch.io;
  - a Steam page live during development to collect wishlists, with the Steam release after the
    demo validates.
- **Store tags:** Papers Please-like, Norse Mythology, Moral Choices, Narrative, Pixel Graphics.

## 9. Glossary

| Term | Meaning (exactly one) |
|---|---|
| Clerk | The player: an unnamed junior valkyrie working the gate. |
| Mentor | The senior valkyrie at the next desk; tutorial on day 1, comments afterwards. |
| Soul | One dead person at the desk, judged once per encounter. |
| Encounter | One soul's visit to the desk; a returning soul is a new encounter. |
| Body | The soul's corpse as shown on the desk; the only evidence that never lies. |
| Fact | One observable item on the body (a wound, what is in hand, a trinket…). |
| Claim | The soul's own saga of its death, in numbered lines. |
| Witness | Another dead soul's account of the death, in numbered lines; can lie. |
| Law | The list of Odin's decrees in force today. |
| Decree | One line of the Law. |
| Forgery | A decree planted by Loki; it contradicts an older decree. |
| Pin | The act of linking two pieces of evidence the player suspects contradict each other. |
| Seam | A true contradiction in a soul's evidence, or between the evidence and the Law. |
| Thread | A pin that exposed a seam (red, grey, law or forgery). |
| Red herring | Evidence that looks like a seam but resolves innocent. |
| Huginn | Odin's raven; answers about a pin or thread the player already made. Never discovers. |
| Stamp | Sending the soul through a realm door; final. |
| Realm | One destination door: Valhalla, Fólkvangr, Hel or Rán. |
| Legal destination | The realm the Law sends a soul to. |
| Worthy destination | The realm the truth of a soul's death deserves. |
| Quota | The number of souls Odin wants in Valhalla today. |
| Feathers | The clerk's standing; the only currency. |
| Citation | A feather penalty for a stamp that broke the Law where a seam was visible; delivered as a black feather. |
| Ignored | A wrong stamp made after the player pinned the seam. |
| Missed | A wrong stamp where the player never pinned the seam. |
| Rank | Chooser of the Slain → Gate-warden → Hall-sweeper. |
| Demotion | Dropping one rank at 0 feathers. |
| Cast down | The ending reached at 0 feathers as Hall-sweeper. |
| Dusk | The between-days screen: citations, quota, recap, requests, story beat. |
| Recap | The dusk reveal of what really happened to 2–3 souls. |
| Ledger | The tray listing every god request and whether you kept it. |
| Request | A god's concrete per-soul ask: Odin demands, Freyja asks, Hel offers. |
| Returned soul | A worthy soul you damned, back from Hel in a later encounter. |
| Hel's tide | Worthy souls you sent to Hel; an ending when there are too many. |
| Hollow hall | Liars you admitted to Valhalla; an ending when there are too many. |
| Eyvind | The clerk's mortal brother; reaches the desk on day 8. |
| Ragnarök | The end of day 8 and of the run. |

## 10. Scope boundary

**Out of scope for the first release:**
- voice acting;
- meta or fourth-wall tricks;
- any mini-game besides inspection;
- Loki as a faction;
- more than 4 endings;
- procedural souls;
- a second currency;
- undo;
- a tool shop;
- Steam, Mac and Linux releases until the demo validates.

**Parked:**
- the **lantern** (highlights body facts that are part of a seam) and the **Norns' thread** (shows
  how many seams a soul has); both were cut for scope;
- harsher terms per rank;
- an endless mode;
- a daily-seed challenge;
- a second campaign from Freyja's side;
- a fourth recurring arc.

## 11. Open questions **[OPEN]**

1. **Final encounter count.** The options are about 50, 60 or 70. Recommendation: build the
   12-encounter vertical slice (one return arc, one god promise, one ending consequence), measure
   authoring and verification time, then set the count.
2. **Ending thresholds** (how many wrongly damned souls for Hel's tide, how many liars admitted for
   the hollow hall). Recommendation: set them after playtesting the full 8 days, so that strict
   obedience of the Law and lenient mercy both lead somewhere bad.
3. **Steam wishlist target and the capsule/trailer art owner.** This is a business call.
   Recommendation: put the store page up once the vertical slice exists.


## 12. Risks

Kill list, from the skeptic:
1. **The detective work becomes an answer-key hunt.** Players pin every pair, or guess the writer's
   answer.
   - *Mitigation:* the prototype picked a pin model that makes spamming visibly costly; see §3.3.
   - The same wound must support different verdicts depending on context: Sigvaldi and Grim both
     carry a back wound.
   - Every case passes the authoring check.
2. **Hour two is hour one with more text.**
   - *Mitigation:* each day changes exactly one rule or one tension.
   - Returning souls must change a later judgment through evidence, not just deliver news.
   - Build one complete return arc in the vertical slice before writing the rest.
3. **Seventy encounters become a writing-and-QA trap** for one developer.
   - *Mitigation:* the vertical slice sets the count (open question 1).
   - The automatic authoring check enforces test 2 of the governing rule.
   - Three recurring arcs, not four.

Further risks:
- **Novelty risks.** No shipped game we found does these, so each needs a playtest:
  - Loki's forged decree: tested on day 3 of the prototype; see the appendix.
  - Ranks instead of game over: tested in the prototype.
  - Souls returning from Hel to fight you: untested; this is the vertical slice's job.
- **AI playtesting can't judge the desk's usability** (pixel readability, click targets, the feel
  of the stamp). The prototype was played through text only, so a human, the owner first, must play
  the vertical slice before art is commissioned.
- **Days 1–2 were too easy, and the clock rarely bit.** Careful testers finished with 70–80 of 100
  minutes left. Tune in the vertical slice: more souls per day, a tighter clock, and red herrings
  from day 2.
- **The quota rarely forced a choice.** Testers defied the Law out of mercy, never to meet the
  quota. Raise the quota pressure so that admitting a liar is a real temptation.

---

## Appendix A — Prototype lessons

**Question:** does pinning contradictions between body, claim, witness and Law feel like detective
work under pressure (tense and fair) rather than pair-spamming or guesswork?

**Setup:** two throwaway web prototypes, identical except for how pins resolve. Both had three
short days and 15 hand-authored souls, with a clock that counted actions, a quota, feathers, Huginn
from day 3, and Loki's forged decree on day 3. Each was played by three **blind AI playtesters**
(Sonnet, Opus, Haiku) through a text interface. There was no human play.

| Variation | Goal stated correctly | "Another round" (1–10) | Pins per soul | Pins with no seam | Found the forgery | Defied the Law out of mercy |
|---|---|---|---|---|---|---|
| **Red thread** (instant validation) — *chosen* | 3/3 | 7, 8, 7 (median **7**) | 0.4–0.9 | 0, 1, 4 | 1/3 | 1/3 (2 souls) |
| Suspicion (no validation until Huginn or dusk) | 3/3 | 7, 7, 6 (median **7**) | 0.5–0.7 | 2, 0, 1 | 1/3 | 1/3 (1 soul) |

Both variations cleared the bar (goal stated correctly; median at least 6). Red thread wins on the
reports. A Haiku tester said *"The threads are satisfying"*, and the Opus tester gave it 8/10 to
*"save Hakon and Vali and see how the epilogue changes."* On Suspicion, the Opus tester said
*"Pinning seemed to do nothing until Huginn arrived."* No tester spammed pairs. The one who probed
paid for it (*"I wasted about 30 minutes on no-seam pins"*).

**Lessons written into this document:**
1. **Instant threads** are the pin model (§3.3), and citations land at the stamp (§3.7).
2. **Law against truth is the hook.** Every tester named an honest soul the Law damned (Asa, Hakon,
   Vali) or the liar who died for his children (Egil) as their most interesting decision.
3. **Decree precedence must be written down.** Five of six testers guessed whether "liars go to Hel"
   beats "defenders go to Fólkvangr" (§3.6).
4. **The forgery's tell was too weak.** Only 2 of 6 found it, because the hint appeared only at
   dawn. It now stays on the desk, and the forged seal looks different (§5, day 7).
5. **Worthiness was invisible at the moment of choice,** and Hel's tide had no meter: *"the game
   didn't signal their worthiness until dusk, too late to act on."* Law threads now say when a saga
   is true, and Hel's door shows the tide (§3.6).
6. **A worthy destination must be an open door.** Hakon was "worthy of Fólkvangr" on a day
   Fólkvangr was closed (§3.6).
7. **Days 1–2 were too easy, and the quota rarely forced a choice** (§12).

The prototypes were thrown away after this record was written.

## Appendix B — Assumed by the panel

These were decided by the agent panel, not the owner. Each is the owner's to confirm or overturn.

The owner decided only the concept (A, "Einherjar Intake", over B, "The Last Verse"). The scope (a
small release) and platform (desktop and web via itch.io) are the skill's defaults, since the
intake gave none. Everything below was decided by the panel (designer, player advocate, market
analyst, and a Codex skeptic), or by the lead where the panel split.

| # | Assumed decision | § | Runner-up / dissent |
|---|---|---|---|
| A1 | Governing rule: "Every verdict is a contradiction you found, or chose to ignore", with its two tests | 1 | Skeptic: "Every verdict weighs evidence against a divine demand" |
| A2 | Law against truth: each soul has a legal and a worthy destination; citations follow the Law, endings follow the truth | 3.6 | One destination per soul, where the Law is the truth |
| A3 | Eyvind, the brother: narrative only, can't be protected, reaches the desk on day 8; his two beats feed evidence | 6 | Feathers buy his protection, like the family in Papers, Please |
| A4 | 8 days to Ragnarök; 4 endings by precedence, computed from the verdict record and naming the souls | 2, 4 | 10 days and 6 endings (designer/market); 3 endings (skeptic) |
| A5 | Tone: deadpan bureaucratic dark comedy over creeping dread; jokes at the gods' administration, never at suffering | 6 | Pure dread |
| A6 | Title "Valhalla Intake", with no subtitle in the title | — | "Worthy of Valhalla" |
| A7 | Look: limited-palette pixel art at about 480×270, a cold desk, ember and bile doors; references Papers, Please, Dredge, Obra Dinn, stave-church carving | 7 | A painterly or hand-drawn desk |
| A8 | Four realms, layered: Valhalla and Hel on day 1, Fólkvangr on day 3, Rán on day 5; told apart by evidence | 3.5 | Skeptic: cut Rán for scope |
| A9 | Evidence channels staggered across days; Huginn never discovers, only answers about a grey thread | 3.2, 3.4 | Skeptic: no Huginn at all |
| A10 | Pressure: day clock, quota and citations, all paid in feathers; days 1–2 give warnings only | 3.7 | Skeptic: untimed |
| A11 | Feathers are the only currency; the only spend is an extra Huginn answer; three ranks with no harsher terms; daily loss cap; Cast down retries the current day only | 3.8 | Designer: harsher terms per rank; skeptic: no ranks |
| A12 | Shop, lantern and Norns' thread parked for scope | 10 | Designer: keep both tools |
| A13 | Gods: no favour meters; requests are concrete per-soul promises about one seam, in a ledger; Loki in story only | 3.9 | Designer: Freyja and Hel favour tracks |
| A14 | "Ignored" against "missed" is recorded and changes how the game speaks to you | 3.7 | Not tracked |
| A15 | Day spine, including the "cowards' sons" reversal on day 6 and Loki's forgery on day 7 | 5 | Player: Loki earlier, on day 5–6 |
| A16 | Content: about 50–70 hand-authored encounters, 3 recurring arcs plus Eyvind, no procedural souls; count set by the vertical slice | 5 | Procedural honest filler (player/market); 1 arc (skeptic) |
| A17 | Soul mix: day 1 about 65% honest, red herrings from day 2, hard cases from day 3, never more than 3 honest souls in a row | 5 | A flat 50/30/20 |
| A18 | Mentor at the next desk; dusk takes 90 seconds or less and can be skipped | 3.10, 6 | Teaching through the Law alone |
| A19 | Length: days of about 8–10 minutes, a first run of about 90–120 minutes | 8 | Market: 2–2.5 hours |
| A20 | Business: Windows and web first; free web demo of days 1–3 ending on Hel's first offer; $9.99 on itch.io; Steam page live during development, Steam release after the demo | 8 | Market: Steam at launch |
| A21 | Worthiness visible at the moment of choice (law threads say "the saga is true"; a tide tally at Hel's door) — lead, from playtest | 3.6 | Hidden until Ragnarök |
| A22 | Stamping is final, with no undo; no separate "nothing contradicts" button | 3.5 | Undo (market); an explicit "checked" button (player) |
