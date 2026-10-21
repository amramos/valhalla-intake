# WP2 art set: log

Unattended run, 2026-10-21, 14:05 to 14:45 wall clock (about 40 minutes, setup included), plus
4 minutes reworking the set onto the built desk's layout (last section).
Generator: local ComfyUI 0.37, Z-Image Turbo (int8), the art direction's prompt core and settings
(8 steps, cfg 1, res_multistep, simple, shift 3), through the comfyui-art skill's `comfy.py`.
Critic: a second model through `codex exec -s read-only`, which saw only the review sheets, the
target and the art-direction rules. Its briefs and replies are in `critic/`.

Everything is rebuilt by the scripts in `tools/` (in order: `build_base.py`, `heads.py` is imported
by `layers.py`, `build_scene.py`, `finish_props.py`, `nameplates.py`, `layers.py`, `composite.py`,
`review.py`, `lint.sh`). The scripts in `tools/applied/` are the round-2 and round-3 hand fixes,
already applied to `heads.py`, `layers.py`, `glyphs.py` and `build_scene.py`. Do not run them again.

## Time per asset kind (D12)

Wall-clock minutes. Generations ran in the background while other kinds were built, so the minutes
overlap a little, and the sum is more than the 40 minutes the run took.

| Kind | Minutes | Generation rounds | Critic rounds | Critic's last verdict |
|---|---|---|---|---|
| Reading the brief, art direction, matrix, ledger, skill | 5 | — | — | — |
| Body chart: base, night-shirt base, overlays, 13 heads, frost | 19 | 2 (base; heads, which were not used) + 1 night-shirt (not used) | 3 | STOP |
| Standing souls (crops of the body layers) | 1 | 0 | covered by the body rounds | STOP |
| Backdrop (gate-desk) | 7 | 2 desk textures, 1 patch heal (not used) | 3 (with doors) | STOP |
| Doors (6) and glyphs | 8 | 0 (derived from the key scene) | 3 | STOP |
| Mentor, Huginn, feather | 6 | 1 (4 seeds each) | 1 | STOP for all three |
| Name plates (3) | 1 | 0 (placed pixel by pixel: small UI) | 1 (with doors, round 3) | STOP |
| Composites, review sheets, canvases, lint, log | 6 | — | — | — |

## Scene: `scenes/gate-desk.png` (480x270, opaque)

- **Gate band, rows 0–109:** the chosen key scene's own band (`docs/art/frames/key-scene.png`),
  rebuilt in `tools/build_scene.py`:
  - Inside each doorway rectangle, every warm, bile, blood or wood pixel returns to the Night tone
    of the same lightness, so the backdrop has no door glow. Each leaf is replaced by the key
    scene's closed grey leaf.
  - The raven is removed. The stone courses above it fill its place (rows 9–44 copied to 45–80).
    An img2img heal of that patch was tried (`gen/heal_r1`, seeds 11 and 22, denoise 0.5) and
    rejected: it painted a blank slab and speckle.
  - The perch post keeps its wood.
  - Fog banks sit in the two corners only (rows 76–109).
- **Desk, rows 110–269:** a generated plank texture banded onto the Wood ramp by lightness
  quantiles, then calmed (a lone pixel in a horizontal run takes its neighbours' colour). A beam line
  runs along the top edge.
  - Round 1 (`gen/desk_r1`, seeds 11 and 33, 1440x480) came back in perspective with vertical
    planks, and was rejected.
  - Round 2 (`gen/desk_r2/prompt.txt`, seed 11 chosen) gave flat horizontal planks.
- **Critic:**
  - Round 1: the desk was too warm and busy. Fixed: no Wood 4, fewer Wood 3 pixels, grain calmed.
  - Round 2: the fog looked like ledges. Fixed: wobbling edges and a darker blue-grey core.
  - Round 3: STOP. The fog still reads a little as ledges.

## Doors: `doors/<realm>-lit.png`, `doors/<realm>-locked.png` (70x96, opaque rectangles)

- Each door is the rectangle around one doorway: the leaf plus the arch stones that its glow
  reaches. This lets the glow spill onto the arch without touching the backdrop.
- **Placement:** (84,14) Valhalla, (191,14) Hel, (312,14) Fólkvangr, matching the key scene's doorways.
- **Lit:**
  - Valhalla and Hel keep the key scene's own glowing leaves.
  - Fólkvangr is Hel's leaf, mirrored and remapped to pale straw-gold. Fólkvangr needed a
    non-reserved colour. Bile became Parchment 0 and 1, with Wood 3 for the edges.
  - The glow on the stones is drawn in three hard distance bands, with no dithering.
- **Locked:** the closed grey leaf, a wooden bar with iron brackets across it, and the glyph
  dimmed (Ember 0, Bile 0 or Wood 3).
- **Glyphs:** spear, coiled serpent and boar, in `tools/glyphs.py`. They are placed pixel by pixel
  and carved dark, with a light catch below and to the right.
- **Critic:**
  - Round 1: the serpent read as a spiral, and the boar as a generic animal. Fixed: the serpent's
    coil ends at the top and rises on a neck into a wedge head, with an eye and a forked tongue.
    The boar got a longer snout, an ear, a tusk and separated legs.
  - Round 2: the boar needed a notch under the snout and a hooked tusk, and the locked serpent's
    head needed to stand out. Both fixed. The locked serpent's head and neck are one step lighter.
  - Round 3: STOP.

## Body chart: `body/` (128x100 layers, front view centred on x=31.5, back view on x=95.5)

- **Base (round 1, `gen/body_r1/prompt.txt`):**
  - Candidates: txt2img with seeds 11 and 22, and img2img from `frames/source/body-chart.png` at
    denoise 0.7 with seeds 11 and 22.
  - The critic picked txt2img seed 22: ashen, plain, no straps. The img2img candidates came back
    tan and bearded.
  - It asked to remove the belt, mirror the figure and make the hands blocky. Mirrored: each view's
    left half is reflected (`tools/build_base.py`). Belt kept, because the matrix lists one; its
    hanging tail was removed. Hands were redrawn as blocks.
  - The head is cut off at the neck: heads are the identity layer.
- **Night-shirt base (`base-nightshirt.png`):**
  - img2img at denoise 0.6 (`gen/nightshirt_r1`, seeds 11, 22 and 33) kept the tunic, and was
    rejected.
  - The night-shirt is built from the tunic base instead: a linen shirt in the Fog ramp, so it
    stays cold beside the Ashen skin. It is open at the neck, has no belt, a hem lowered to row 80
    and fold lines, with bare shins and feet.
  - It is a second base rather than an overlay, because an overlay cannot erase the boots it
    replaces.
- **Left hand:** a layer of its own, `hand-left-calloused` (the default) or `hand-left-soft` (the
  fact). The reason is the same: a slender hand drawn over the base's block would still show the
  block.
- **Overlays:** placed pixel by pixel, in `tools/layers.py`:
  - `wound-front` and `wound-back`: a Blood tear with a torn-cloth ring of Ashen skin and a blood
    tail.
  - `sword`: a fist, a crossguard and a pale blade. The back view shows the blade at his right side.
  - `wet-knee`: a stepped pale tide line, the cloth below it soaked one step darker, and Tide drips
    of different lengths.
  - `neck-broken` and `neck-broken-left`: a crease and a knob of bone. They pair with the tilted
    heads of Hallr and Ragna.
- **Heads (13, including the frost variant):**
  - The img2img variants (`gen/heads_r1`, 12 prompts × seeds 11 and 22, denoise 0.55) changed hair
    colour but not shape: no bald crown, no moustache, no braids. They are used only as reference.
  - The heads are placed pixel by pixel in `tools/heads.py`, over a shared face template.
  - Hallr's and Ragna's heads are tilted by a shear. A rotation was tried first and shredded the
    faces.
  - Hakon's frost is placed rime and icicles, in Fog and Ashen 2, never bile.
- **Critic:**
  - Round 1: the back wound read as a clasp, the wet legs as different boots, the soft hand as
    stray pixels, and the frost as a headband. All fixed.
  - Round 2: the wet line was too symmetric, the soft hand looked skeletal, and Freydis's crown
    read as spiky hair. All fixed.
  - Round 3: STOP. Wet and soft hands are still the weakest cues.
- Every encounter's stack is in `manifest.json`. Composites use 10–17 colours, inside the
  20-colour budget.

## Standing souls: `souls/` (48x96)

- The same layers' front view, cropped from the chart at (8,4)–(56,100). By construction, the
  waiting figure shows nothing the chart does not (D5).
- `wound-back` has no soul layer: nothing of it shows from the front.
- The soul composites use 10–16 colours, inside the soul canvas's 16.

## Mentor, Huginn, feather

Round 1 for all three: 4 seeds each (11, 22, 33 and 44). The prompts are in
`gen/mentor_r1/prompt.txt`, `gen/raven_r1/prompt.txt` and `gen/feather_r1/prompt.txt`.

- **Mentor (`portraits/mentor.png`, 36x36):**
  - Generated at 1152², keyed with `pixel_post.py key`, then cropped to the bust and
    box-downscaled before the palette snap. The mode downscale at 27× lost the faces.
  - The critic picked seed 33. Her skin snaps to Parchment and Wood, not Ashen: she is alive.
  - Hand edits:
    - Parchment 1 merged into Parchment 0.
    - The two pupils and a short mouth placed.
    - Everything outside the face despeckled.
- **Huginn (`portraits/huginn.png`, 48x40):**
  - Generated at 960x800, box-downscaled. The critic picked seed 22.
  - Hand edits:
    - The keyed ground shadow at the feet painted Night 0.
    - The plumage despeckled.
    - A Night 4 rim added along the top edges, so he holds against the wall.
  - He sits on the perch post at (268,43).
- **Feather (`props/feather-black.png`, 32x32, the existing prop canvas):**
  - Generated at 1024², mode-downscaled. The critic picked seed 11. Despeckled, with the quill kept.

## Name plates: `ui/nameplate-*.png` (68x12)

- Placed pixel by pixel, because they are small UI:
  - `plain`;
  - `frost`: rime grown from the corners and the top edge, and dark burn cracks;
  - `hel`: a small serpent mark in its own cell. The mark is pale Fog, not Bile, because lint
    reserves Bile for Hel's door.
- The engine writes the name.
- Critic, round 3: STOP. It suggested sparser frost highlights and a clearer gap in the mark.
  Neither was done.

## Lint

`tools/lint.sh` stages the deliverables under `_lint/assets/art/`, exactly as they would sit in
the repository. It lints them with the repository's `pixelforge.toml` plus `canvases.toml`, with
the palette pointed at the repository's `palette.gpl`:

```
58 file(s) checked, 0 error(s), 0 warning(s)
clean.
```

The repository's `tools/ci/check_art_coverage.py` passes on the same staging, so every file has a
canvas.

Negative check: with the repository's config alone, `body/wound-back.png` fails `reserved` (blood)
and both new folders are `unclaimed`. The fragment is required.

## Rework on the built desk's layout (ruling D51), 14:44 to 14:48, 4 minutes

The built desk (`scenes/desk/desk.tscn`), not the A3 sketch, is now the layout reference.

- **Backdrop:** the band/desk boundary moved to y 96. The gate band is the key scene's rows 9–104.
  The built desk's door centres (119, 226, 348) match the key scene's own doorways, so nothing was
  resampled. The raven patch, the perch post (top now at y 72) and the fog banks moved up with the
  band. The desk texture now fills rows 96–269.
- **Doors:** 60x87 at (89,9), (196,9) and (318,9), with the same leaves, glow bands and glyphs.
  Glyphs and the bar moved 9 px up. The built desk's Hel node is 58 wide; the sprite stays 60.
- **Mentor:** re-cleaned at 32x32 from the same pick (seed 33), with the same hand edits: firm
  brows, the two pupils and a short mouth, plus despeckling outside the face. She sits at (2,204).
- **Huginn:** (268,34), feet on the post top. **Name plates:** 60x10 at (2,86). **Feather:**
  (36,204), beside the mentor, over the desk's 12x12 slot.
- **Soul:** composited at (6,-2). The built desk's WaitingSoul offset, (6,-8), would cut up to
  6 px of hair. At (6,-2) the plate covers the soles.
- **Body chart:** composited on a Night 3 panel, the colour the engine will use. The dark tunics
  now separate from it.
- `canvases.toml` (door 60x87, portrait 32x32, nameplate 60x10) and the `manifest.json`
  placements were updated. The three 1:1 composites in `review/` were redone on these numbers.
  The sketch-layout versions of the scripts are kept in `work/*_a3sketch.py`.
- Lint: `58 file(s) checked, 0 error(s), 0 warning(s)`. The art coverage check passes.

Total time with the rework: about 44 minutes.

## Spear wounds (content follow-up), 15:08 to 15:12, 4 minutes

The final content labels every wound as a spear wound ("spear wound, chest", "spear wound, back").
The diagonal tears read as gashes, which would contradict those labels.

- `body/wound-front.png`, `body/wound-back.png` and `souls/wound-front.png` were redrawn as a small
  round puncture: a 4x4 ring in Blood 1 with a Blood 0 centre, and a 2-pixel blood run below it.
  Blood ramp only.
- The front wound is at (37,34) on the chest; the back wound is at (98,33) on the upper back. Both
  sit inside the body chart's torso hit areas.
- The composites and review sheets were redone. Lint against the repository's config, which now
  carries the WP2 canvases: 58 files, 0 errors.
