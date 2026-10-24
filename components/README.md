# components/

Reusable nodes (and their small helpers) that give one behavior to whatever composes them. A
component knows nothing about the desk, the run or any entity; it exposes signals and setters, and
its owner connects it.

| Component | Behavior |
|---|---|
| `pin_selectable/` | A clickable evidence hit area (at least 8×8): select (a stuck pin), cancel, hover (an ink underline or corner marks), highlight (D12) |
| `hover_label/` | A small parchment tag pinned by a 3×3 pin head next to a hovered area: above it, else below, else beside, kept on screen, off its "keep clear" rects and as far as it can off its "avoid" rects (D20) |
| `guarded_button/` | A button that ignores double-clicks and presses right after it appears (D9) |
| `placeholder_art/` | Loads a style frame from disk as placeholder art until the final asset lands |
| `pixel_glyph/` | 7×7 marks drawn pixel by pixel in code: realm glyphs and HUD icons |
| `knot_placer/` | Places a thread's 8×8 knot on its route, clear of every other hit area |
| `drag_source/` | Something the player picks up and drops on a target (the soul onto a door, D9) |
| `clickable_sprite/` | A sprite that can be clicked and hovered (the black feather, the mentor's portrait), with optional idle frames (her blink, D17) |
| `idle_cycle/` | The seeded clock of a decorative idle: rest for a random wait, show the frames in turn, rest again; its owner advances it, so pause and reduce motion stay the owner's (D17, D19) |
| `cursor_sprite/` | The in-scene pixel cursor on canvas layer 100: a 7×9 pointer, the pointer carrying a pin while an item is selected, a 9×9 grab hand over the soul and while dragging; the OS cursor is hidden inside the window. It never takes input (D13, D48) |
| `pixel_font/` | Applies the pixel font's crisp rendering settings at runtime (ADR-0008) |
| `teller/` | Tells a label's text line by line at a set pace with pauses and voice blips; finish-now and pause (D4, D41) |
| `parchment_frame/` | Draws a parchment sheet in code from a seed: deckled or torn edge, rule, shadow; never over its `inner` rect (D8) |
