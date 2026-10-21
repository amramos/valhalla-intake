# entities/

Concrete desk objects, composed from components. Each exposes signals and setters; the desk
system connects them to the commands. None of them reads the run state directly.

| Entity | What it is |
|---|---|
| `body_chart/` | Front and back views drawn from the soul's layer stack (`body_stacks.tres`), a hit area per fact, absences included (D5) |
| `evidence_panel/` | A parchment panel of numbered lines: claim, witness or Law (D7, D32) |
| `thread_line/` | A thread's route, pattern and grey knot (D8) |
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
