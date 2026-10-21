# Valhalla Intake — one-page summary

**Provisional.** An agent panel wrote this from your short intake. The full design is in
[GDD.md](GDD.md), and every decision the panel assumed is listed in its Appendix B.

## Pitch
You are a valkyrie clerk at the gate of Valhalla, eight days before Ragnarök. The dead queue at
your desk, each with a heroic saga of how they died, and you must judge from their bodies, their
words and their witnesses whether that death earns Valhalla, Fólkvangr, Hel or Rán. The evidence is
the death itself: a wound in the back, an empty hand or dry clothes on a man who "hid in the river"
can expose a lie. And the worthy you damn come back from Hel to fight you at Ragnarök.

**Governing rule:** *Every verdict is a contradiction you found, or chose to ignore.*

## The five assumed decisions that shape it most

| # | Assumed | Runner-up |
|---|---|---|
| 1 | **Law against truth.** Each soul has a legal destination (Odin's decrees) and a worthy one (the truth). Citations follow the Law, and the ending follows the truth. Obeying the Law can damn heroes, and mercy costs feathers. | One destination per soul, where the Law is simply right |
| 2 | **Eyvind, your brother.** He is story only and can't be protected. You hear him twice, and he reaches your desk on day 8 with a seam in his saga. | Feathers buy his protection, like the family in Papers, Please |
| 3 | **8 days, 4 endings** (Cast down, Hel's tide, The hollow hall, The Hall holds), computed from your verdicts. Each ending names the souls that caused it. | 10 days and 6 endings |
| 4 | **Tone and look.** Deadpan bureaucratic dark comedy over creeping dread, in limited-palette pixel art at a cold desk. Title: *Valhalla Intake*. | Pure dread; title *Worthy of Valhalla* |
| 5 | **One currency, small scope.** Feathers are your standing, and their only use is buying an extra answer from Huginn. Ranks drop, but there is no game over. No shop and no tools. Windows and web first, $9.99, with a free demo of days 1–3. | A tool shop (lantern, Norns' thread) and harsher terms at each lower rank |

## Playtesters' verdict
Both prototype variations cleared the bar: 6 blind AI testers, all stated the goal correctly, and
the median "another round" score was 7/10. Instant "red thread" feedback won, and every tester
named an honest soul the Law damned as their best moment.

They also flagged three problems: decree precedence was unclear, Loki's forgery was too easy to
miss, and days 1–2 were too easy. All three are now fixed in the GDD. Because the tests ran
through text, nobody has yet checked the desk's readability or click feel.

## Skeptic's kill list
1. **Answer-key hunt:** players spam pins or guess the writer's answer. *Mitigation:* a pin with no
   seam costs extra time, the same wound supports different verdicts in different cases, and an
   automatic authoring check runs on every case.
2. **Hour two is hour one with more text.** *Mitigation:* each day changes one rule, and souls
   return from Hel to change later judgments. One full return arc gets built first.
3. **Writing-and-QA trap** for one developer. *Mitigation:* a 12-encounter vertical slice sets the
   final encounter count (an open question in the GDD).

---

**Change any of these, or continue to setup?**
