# entities/

Concrete desk objects, composed from components. Each exposes signals and setters; the desk
system connects them to the commands. None of them reads the run state directly.

| Entity | What it is |
|---|---|
| `body_chart/` | Front and back views with a hit area per fact, absences included (D5) |
| `evidence_panel/` | A parchment panel of numbered lines: claim, witness or Law (D7, D32) |
| `thread_line/` | A thread's route, pattern and grey knot (D8) |
| `door/` | A realm door's hit area, glyph tag and lock (D4, D21) |
| `waiting_soul/` | The soul at the gate and its name plate (D21) |
| `hud/` | Clock, feathers, quota, Huginn and the ledger badge (D21) |
| `stamp_prompt/` | "Stamp <name> to <realm>?" and the guarded confirm (D9) |
| `phase_card/` | A minimal dawn, dusk and ending card with one button (WP1 stand-in) |
| `black_feather/` | The citation's black feather; a click shows the citation again (D14, D33) |

Art is a texture slot on each entity; until final art lands, the style frames in
`docs/art/frames/` are read from disk as placeholders (`PlaceholderArt`).
