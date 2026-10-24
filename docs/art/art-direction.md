# Valhalla Intake — art direction

**Chosen:** 2026-10-21, direction "Fog & Bile" (owner's pick of three: Ash & Ember, Fog & Bile,
Carved Ink). **Frames:** `frames/` (game scale) and `frames/source/` (full-size generations, the
image references). **Palette:** `palette.gpl` (30 colours, grouped by meaning). **Lint:**
`pixelforge.toml` at the repository root.

## The style in one paragraph

Chunky limited-palette pixel art at dusk: dark teal and navy stone, low grey fog, cold moonlit
light, and two doors that glow, one ember and one bile, in an otherwise cold world. The routine at
the desk is calm. The unease comes from the dark around it and the light from the doors, never from
the evidence itself. What makes it recognisable: **everything is cold except the destinations**, so
the eye always knows where a soul could go, and the desk under them is lit plainly so the evidence
reads.

![The desk at game scale](frames/key-scene-composite.png)

## Do

- Shade in bands: three or four tones per material, hard pixel edges, no anti-aliasing.
- Keep the desk and the slab plainly lit and fog-free. Mood lives in the gate band and the corners.
- Give the dead **ashen** skin (the Ashen ramp). The living never appear at the desk.
- Make every piece of evidence readable at 1:1 on the 480×270 screen. A wound gets Blood pixels
  where it enters; an object in the body (an arrow, a blade) gets a pale value against the dark
  tunic, as on `frames/body-chart.png`.
- Draw parchment warm off-white (Parchment ramp). Text on it is rendered by the engine, never
  painted.
- Pair every colour cue with a shape. Each realm door carries its own carved glyph: Valhalla a
  spear, Fólkvangr a boar, Hel a coiled serpent, Rán a wave. Threads differ by line pattern as well
  as colour (GDD §7). The door sprites in `assets/art/doors/` carry the glyphs.
- Start every generation from the prompt core below, with the matching file in `frames/source/` as
  an image reference wherever the generator takes one.

## Don't

- No ember outside Valhalla's door, its light and UI accents (see "UI objects" below).
  No bile outside Hel's door and its light. No blood outside wounds. `pixelforge.toml` reserves all
  three **by asset path**: lint fails when one appears in a file whose folder may not use it. Inside
  an allowed file (a soul may carry blood, a scene both doors) the placement is checked by review
  and the evidence auditor, not by lint.
- No fog, glow or vignette crossing the slab, the body chart or the papers.
- No pure black: the darkest colour is Night 0.
- No dithering on characters or evidence. Banded shading only.
- No living skin tones on the dead. Generations often come back tan; recolour them to Ashen.

## References

| Reference | What it contributes |
|---|---|
| Dredge | Dusk palette, low fog, unease creeping into a cosy routine |
| Papers, Please | The desk split: the world in a band on top, the work on the desk below |
| Return of the Obra Dinn | The body read as evidence, laid out like a coroner's chart (ideas only) |
| Norwegian stave-church carving | Knotwork on wooden ends (scroll rods, the raven's post, door glyphs) |

## Sizes and canvases

The base resolution is 480×270, integer-scaled, with nearest filtering (`project.godot`). Canvases
are enforced by `pixelforge.toml`.

| Asset kind | Canvas (px) | Scale in game | Notes |
|---|---|---|---|
| Scene backdrop | 480×270 | 1:1 | Opaque. Gate band on top (~95 px), desk below |
| Soul, standing | 48×96 | 1:1 | The soul waiting at the gate, bottom-anchored |
| Body chart | 128×100 | 1:1 | Front and back side by side on the desk's left; 20-colour budget for evidence |
| Prop | 32×32 | 1:1 | Stamp, feather, trinkets; bottom-anchored |
| Law scroll | 80×150 | 1:1 or 2/3 | UI panel; the engine renders the decrees on it |
| Door | 60×87 | 1:1 | Opaque: the leaf (lit or barred) and the arch stones its glow reaches. Each lit door has a `-lit-dim` pulse frame; `doors/day2/` and `doors/day3/` hold each day's copies |
| Gate band by day | 480×270 | 1:1 | `scenes/gate-desk-day2.png`, `-day3`: the backdrop with the band's Night and Fog one ramp step darker per day (D39); the desk rows unchanged |
| Corner fog | 480×60 | 1:1 | `fog/fog-day<N>.png`: three 480×20 frames stacked for band rows 76–95, opaque only in the two corner masks (D19) |
| Mentor portrait | 32×32 | 1:1 | `portraits/mentor*.png`; `mentor-blink.png` is her idle frame (D17) |
| Huginn | 48×40 | 1:1 | `portraits/huginn*.png`: the rest frame (with a moonlit rim for the darker band), `-tilt` and `-ruffle` |
| Name plate | 60×10 | 1:1 | `ui/nameplate-*.png`: a carved wooden plate, plain, frost or Hel's mark; the engine writes the name |
| UI marks under 32×32 | — | 1:1 | Never generated: placed pixel by pixel by a code-writing agent |

The frames and plates above that are not generations (the day recolours, the door copies and
pulse frames, the fog, the idle frames, the plates) are made by the scripts in `tools/art/`
(`tools/README.md`); run one again rather than editing its output by hand.

## UI objects

Everything the player handles is an object drawn in code, pixel by pixel, in palette colours.
The Law's **wax seal** is a 7×7 blob of Ember 2 with an Ember 0 rim and three pressed Ember 0
pixels, left of a new decree's numeral. A **hover tag** is a small parchment tag held by a 3×3
Wood 3 pin head, its text in Ink. The mentor's **bubble** is parchment with its corners cut and a
3 px tail toward her portrait. The **cursor** is a 7×9 pointer (Ink outline, Parchment 2 fill)
that carries a pin head while an item is selected, and a 9×9 grab hand over the soul. **Huginn**
is a sprite on his post, rimmed in Night 4–5 so he reads on day 3's band. The **stamp** is a
wooden block carved with the realm's glyph; the mark it leaves on the writ is Ink, never a
reserved colour. Ember among the UI objects is only the wax seal and the selected pin (the pin a
selected item, a selected knot or the cursor shows); the HUD's candle flame and the ledger book's
wax dot are its other two ember accents.

Between days and in the shell the same rule holds. **Titles** (the day numeral, PAUSED, the
endings' names, the game's name) are the carved capitals, a code-drawn 8×11 set in Parchment 2
over a Night shadow, drawn at 2x for the day card; no second font file (ADR-0008). **Odin's
writ** is a pinned parchment with a wax seal, its lines in Ink and the signature in soft ink.
The **day-book** is two parchment pages on a Wood spine with a dog-ear for "Next"; its text is
written in Ink and finished by a click. A **tag** ("Begin", Start / Options / Quit, "Skip all",
"Play again") is a torn parchment slip held by a Wood 3 pin head with 3 px of ground after its
text; over a parchment page it takes a darker face (Wood 4 sheet, Wood 3 edges, Ink text) so it
reads as nailed over the page. The **pause** is a hanging parchment; the **options** are rows
on it, the volume a tally of marks filled in Ink up to the level and hollow after. Dawn falls
to Night like a curtain; dusk dims the desk to candlelight before the book opens.

## Prompt core

These are the exact text and settings that produced the chosen frames. Every generation starts
from them.

- **Generator and model:** local ComfyUI 0.37, Z-Image Turbo
  (`z_image_turbo_int8_convrot.safetensors`, `qwen_3_4b_fp8_mixed.safetensors`, `ae.safetensors`),
  through the `comfyui-art` skill's `comfy.py`. No LoRA.
- **Settings:**
  - 8 steps, cfg 1.0, sampler `res_multistep`, scheduler `simple`, shift 3.0;
  - scenes at 1440×816, characters at 896×1152, body charts at 1152×896, props and UI at
    1024×1024;
  - seeds used: scene 33, soul 11, stamp 11, Law scroll 33, body chart 11.
- **Clean-up:**
  - **Opaque scenes:** keep the most common colour in each 3×3 block, then snap to `palette.gpl`
    (redmean) without keying.
  - **Sprites:** `pixel_post.py key`, then `pixelforge clean --canvas <kind>`.
  - **Then fix colours by meaning:** Ashen skin, Hair instead of Blood on heads, reserved ramps out
    of the wrong places.
- **Prompt core** (appended to every prompt):

  > Pixel art, chunky pixels, soft banded shading with three or four tones per material, no
  > anti-aliasing. A deep dusk palette of dark teal, navy and slate blue, thin pale grey fog bands
  > drifting low, cold moonlit blue light; a single ember orange glow is the only warm colour.
  > Quiet, uneasy, creeping dread.

  For sprites and UI, drop "thin pale grey fog bands drifting low": the model paints fog into the
  sprite's background.

- **Per-kind additions** (put before the core):
  - **Scene:**
    - Describe the frame as "the main screen of a desk game, one full-bleed image with plain
      unmarked corners, split into two horizontal bands".
    - The gate wall goes in the top third, seen straight on.
    - The desk fills the bottom two thirds, "seen from directly above".
  - **Character (a soul):**
    - Say what is visible, with no backstory: "one dead Viking warrior standing alone, full body,
      centred, feet near the bottom, front view".
    - Describe the skin as "ashen grey-blue and bloodless".
    - Name each wound with its place and say "clearly visible".
    - End with "Plain flat solid pure magenta background, completely empty, no other figures, no
      ground, no shadow".
    - Never write "queue": the model draws a crowd.
  - **Body chart:** "a coroner's chart of one dead Viking warrior: the same man shown twice side
    by side at the same size, on the left seen from the front, on the right seen from behind…",
    then say which view shows each wound and that the other view shows none.
  - **Prop:** the object alone, "centred, occupying the middle half of the frame", on the magenta
    background.
  - **UI:**
    - Use "warm off-white parchment, faintly yellowed like old paper" and empty ruled lines.
    - Keep the knotwork on wooden ends only.
    - Use the magenta background.

The exact full prompts for each frame are recorded in the pull request that added this guide.
