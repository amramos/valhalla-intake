# scenes/

Screens and shared scenes that are neither an entity nor a level.

- `title/` — the title (Start, Quit); the main scene. `-- --auto-start` presses Start at once,
  so an exported build's smoke test can boot the desk.
- `desk/` — the inspection desk at 480×270, layout A3 as built (`desk.tscn`), its theme with the
  pixel font and the colour roles (`desk_theme.tres`). Esc opens the pause (D31). `gate_band.gd`
  (`GateBand`) swaps the band's day recolour (D39) and drifts the corner fog (D19); `desk.gd` adds
  the in-scene cursor.
