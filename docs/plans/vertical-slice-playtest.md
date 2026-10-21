# Vertical slice — blind playtest report (WP6)

**Date:** 2026-10-21. **Build:** `feature/wp6-verification`, the whole slice from the title to the
ending, before the D53 text fixes. **How it was played:** three blind AI playtesters on different
models (D41) played through the text harness (D13). They had only the play command: no design, no
source, no debug commands. **Not tested:** human reading pace, the feel of the stamp, and
readability on a real screen. Those are the owner's play (D27).

## Scores and the bar

| Tester | Model | Another round (1–10) | Goal stated correctly | Named souls from memory |
|---|---|---|---|---|
| A | Sonnet | **8** | yes | Kolbeinn, Brand, Ragna (with their evidence) |
| B | Haiku | **6** | yes | Ulf, Kolbeinn, Hakon (with their evidence) |
| C | Opus | **7** | yes | Asa, Hakon, Ragna (with their evidence) |

**Median 7.** That clears the bar of 6 (the prototype bar, re-used per the plan). The WP1
checkpoint, two souls in one untimed day with no mentor, dawn or dusk, had a median of 5.

## What the slice set out to prove

| Question | Result |
|---|---|
| Does Law against truth land? | Yes. A named Hakon as the verdict that mattered most: "the Law read one way and my gut read another". C named Hakon as "the first time I went against the Law on purpose", after Asa's recap "told me the Law sent her to Hel, the truth was Valhalla" |
| Deliberate mercy, knowingly paid for (D27, D28) | 2 of 3. A spared returned Hakon at a citation; C spared Hakon and Egil at a citation each. B obeyed throughout |
| Did the return arc fire? (D2, D43) | 2 of 3. A and B damned Hakon on day 2, so he returned on day 3. C spared him, so Egil took the slot |
| Was Hel's promise kept? (D3, D29, D43) | 0 of 3. All three refused Hel and sent Ragna to Fólkvangr |
| Was Ketil admitted with his grey thread unresolved? (D37) | 0 of 3. All three asked Huginn first, then stamped him to Hel |
| Did anyone have to guess? | All three said yes, each about a Law-against-truth soul (Asa, Hakon, Egil), not about reading the evidence. Ketil was settled by Huginn every time |
| Ending reached | A: 10 of 12 matched the truth. B: Hel's tide. C: The Hall holds, 11 of 12 |

**Feathers entering day 3:** about 12 (A), 14 (B) and 10–12 (C). The slice's feather pressure is
light, as D29 expected.

## Confusions, and what changed (D53)

- **Hel's tide was never explained** (all three). The figures rose with no word on what they meant
  or what happens at three. *Fixed:* the day-1 dawn card explains the tide, and the mentor comments
  when the first figure joins it.
- **Citations were misread as applying only to pinned seams** (C, after "You threaded it
  yourself"). *Fixed:* the day-2 dawn card states the rule plainly.
- **Day 3's quota and feathers vanished** (C). This was the harness, not the game: the desk always
  showed day 3's dusk before the ending, but the harness jumped straight to the ending. *Fixed in
  the harness* (PR #16 review), so both now show day 3's dusk card, then the ending.
- **The 10 s cost of a pin with no seam discouraged exploring** (A, B). *Kept:* that cost is the
  design's answer to pinning every pair (D8, D24).
- **The day-2 prayer sets up Eyvind with no payoff** (C). *Expected:* Eyvind reaches the desk on
  day 8, outside the slice (plan §1).
- **The mentor's hints gave little reasoning** (B). Noted for the owner's play.

## The clock (D42)

At each day's last soul the harness clock still showed about 3:30–3:55 of 5:00. After that soul's
20 s stamp, roughly 63–72% was left at the end of the day. That is **over D42's 30%**. But by
design (D13) the harness clock counts only action costs (the no-seam penalty, Huginn, and 20 s per
stamp) and no reading time, so AI testers can't say whether 5 minutes is tight for a person.
**D42's gate is pending, not passed** (D54). The clock stays at 5:00 for days 2 and 3, and it is
shortened only if the owner's first play also ends those days with more than 30% left (it is one
value in `data/days/`).

## Not proven by this test

- The feel of the stamp, the thread visuals, and readability at 1:1 on a real screen, beyond the
  fit check and screenshots.
- Human pacing against the clock.
- Whether a human feels they are judging a death (D27) rather than solving a puzzle. The memory
  answers (souls named with their evidence) are the best evidence available here, but only the
  owner's play settles it.
