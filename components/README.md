# components/

Reusable nodes (and their small helpers) that give one behavior to whatever composes them. A
component knows nothing about the desk, the run or any entity; it exposes signals and setters, and
its owner connects it.

| Component | Behavior |
|---|---|
| `pin_selectable/` | A clickable evidence hit area (at least 8×8): select, cancel, hover, highlight |
| `hover_label/` | A small parchment label shown next to a hovered area, kept on screen |
| `guarded_button/` | A button that ignores double-clicks and presses right after it appears (D9) |
| `placeholder_art/` | Loads a style frame from disk as placeholder art until the final asset lands |
| `pixel_glyph/` | 7×7 marks drawn pixel by pixel in code: realm glyphs and HUD icons |
| `knot_placer/` | Places a thread's 8×8 knot on its route, clear of every other hit area |
| `drag_source/` | Something the player picks up and drops on a target (the soul onto a door, D9) |
| `clickable_sprite/` | A sprite that can be clicked and hovered (the black feather, the mentor's portrait) |
| `pixel_font/` | Applies the pixel font's crisp rendering settings at runtime (ADR-0008) |
