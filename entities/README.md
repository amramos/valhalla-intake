# entities/

Concrete desk objects, composed from components. Each exposes signals and setters; the desk
system connects them to the commands. None of them reads the run state directly.

| Entity | What it is |
|---|---|
| `body_chart/` | Front and back views drawn from the soul's layer stack (`body_stacks.tres`) on the top of a stone slab (a rim and shadow drawn outside its rect), a hit area per fact, absences included (D5, D35) |
| `evidence_panel/` | A paper of evidence lines: a saga sheet (claim or witness: torn parchment headed by the speaker, a hanging quote per line, no ids) or the Law scroll (knotwork rods, roman numerals, its parchment ending just under the last decree, a wax seal, `WaxSeal`, left of each new decree's numeral); `tell()` writes the lines out through a `Teller` (D4, D6–D9, D33) |
| `thread_line/` | A thread's route: 5×5 pin heads at its ends, a 3 px line in its kind's colour and pattern, the tied grey knot, the taut draw-in and the slack drop (D8, D12) |
| `door/` | A realm door: lit or locked sprite, hover glyph and name, NEW tag, Hel's tide, drop target for the soul (D4, D9, D21). `DoorLight` picks today's sprites (each later day has its own copies, D39) and pulses the glow between the lit sprite and its dim frame (D19); `DoorCarving` finds the carved glyph's pixels in the lit sprite for the glyph cue a law caption lights (`set_glyph_lit`) |
| `waiting_soul/` | The soul at the gate (its front-view stack, draggable) and its carved plain, frost or Hel plate (D21); a returned soul's frost glints now and then (D17) |
| `hud/` | Objects on the stone: a candle burning down beside the m:ss (turned over in the last 30 s), a quill with the feathers, a tally slate for the quota, Huginn's answers left on day 3, the ledger as a closed book (D11, D22, D33); `HudReadout` is what it shows. An extra answer's price is the raven's hover, not the HUD's (D40) |
| `raven/` | Huginn on his post in the gate band, the control that asks him (D40): a click on the bird or the post asks about the selected grey thread (nothing selected: nothing happens, nothing is spent); the hover names the answers left, the precondition or the price. A seeded head tilt and a ruffle on an answer (D17) |
| `stamp_prompt/` | The soul's writ under the doors and the stamp raised over it as the guarded confirm (D9, D14): `StampFace` the carved block, `Writ` the slip the slam marks, `ImpactMarks` the veil, burst and shockwave of the impact (D54–D56) |
| `phase_card/` | A dawn card, one dusk card or the ending: given text, sized to fit, "Next" and "Skip all" (D15, D23, D34) |
| `pause_overlay/` | The pause that dims the desk: Resume, Restart the run and Quit, each final choice confirmed (D31) |
| `ledger_tray/` | The ledger icon's click area and its one-line view of Hel's promise (D3, D29) |
| `mentor/` | The mentor's drawn speech bubble by her portrait: her guided step written out at 60 cps; a click finishes the writing, a later click advances a step that only has to be read, while a 3×5 arrow blinks (D16, D18) |

Art comes from `assets/art/` (WP2) as texture slots set in `scenes/desk/desk.tscn`. An encounter
without a layer stack falls back to the style frames in `docs/art/frames/` (`PlaceholderArt`).
