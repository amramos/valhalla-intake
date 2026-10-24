# entities/

Concrete desk objects, composed from components. Each exposes signals and setters; the desk
system connects them to the commands. None of them reads the run state directly.

| Entity | What it is |
|---|---|
| `body_chart/` | Front and back views drawn from the soul's layer stack (`body_stacks.tres`) on the top of a stone slab (a rim and shadow drawn outside its rect), a hit area per fact, absences included (D5, D35) |
| `evidence_panel/` | A paper of evidence lines: a saga sheet (claim or witness: torn parchment headed by the speaker, a hanging quote per line, no ids) or the Law scroll (knotwork rods, roman numerals, length grows with the decrees); `tell()` writes the lines out through a `Teller` (D4, D6–D9) |
| `thread_line/` | A thread's route: 5×5 pin heads at its ends, a 3 px line in its kind's colour and pattern, the tied grey knot, the taut draw-in and the slack drop (D8, D12) |
| `door/` | A realm door: lit or locked sprite, hover glyph and name, NEW tag, Hel's tide, drop target for the soul (D4, D9, D21) |
| `waiting_soul/` | The soul at the gate (its front-view stack, draggable) and its plain, frost or Hel plate (D21) |
| `hud/` | Clock (with the 30 s warning), feathers, quota, Huginn, the extra-answer note and the ledger badge (D21, D22, D30); `HudReadout` is what it shows |
| `stamp_prompt/` | "Stamp <name> to <realm>?" and the guarded confirm (D9) |
| `phase_card/` | A dawn card, one dusk card or the ending: given text, sized to fit, "Next" and "Skip all" (D15, D23, D34) |
| `pause_overlay/` | The pause that dims the desk: Resume, Restart the run and Quit, each final choice confirmed (D31) |
| `ledger_tray/` | The ledger icon's click area and its one-line view of Hel's promise (D3, D29) |
| `mentor/` | The mentor's speech bubble for guided step prompts (D16) |

Art comes from `assets/art/` (WP2) as texture slots set in `scenes/desk/desk.tscn`. An encounter
without a layer stack falls back to the style frames in `docs/art/frames/` (`PlaceholderArt`).
