# tools/

Development-only scripts and harnesses, **never shipped** and never referenced by game code.

- `ci/export_all.py` — exports every preset into `build/<channel>/` (used by the release workflow).
- `ci/export_smoke_test.sh` — boots the exported Linux build headless and fails on errors.
- `ci/check_art_coverage.py` — fails when an image under `assets/art/` matches no pixelforge canvas.
- `harness/` — the headless text harness: the slice played as text through `DeskCommands` (D13).
- `fitcheck/fit_check.gd` — the D21 fit check: renders the desk at 480×270 with the slice's longest
  text and saves `docs/plans/vertical-slice-fitcheck.png` (and a ×3 copy). Run in a window:
  `godot --path . --resolution 480x270 -s tools/fitcheck/fit_check.gd`.
- `desk_shots/desk_shots.gd` — plays the real desk with real mouse events, checks each step (exit 1
  on a failure) and saves a 1:1 screenshot per step, the title's and the pause's options, each dawn's
  card and writ, each day-book spread and the ending's tableau included. It prints a `DAWN <day>
  <seconds>` line per dawn (the dark card's gated time) and a `FORCED <soul> <seconds>` line per
  soul: `godot --path . --resolution 480x270 -s tools/desk_shots/desk_shots.gd -- <folder>`.
- `audit_kit/audit_kit.gd` — the evidence auditor's kit (D26): for every encounter, a 1:1 desk PNG and a
  text file of only what the player can read. Run in a window:
  `godot --path . --resolution 480x270 -s tools/audit_kit/audit_kit.gd -- <folder>`.
- `audio/synth_sounds.py` — synthesizes the game's own sounds into `assets/audio/` (stdlib only,
  fixed seed); `--check` reads them back (length, peak, a one-shot's silent edges, a loop's seam).
  Run with `py -3 tools/audio/synth_sounds.py`; credits in `assets/audio/CREDITS.md`.
- `content/` — rebuilds the content `.tres` files from the matrix's transcription (its README).
- `art/` — palette-only art made by script (Pillow, no randomness; `--check` exits 1 when a file on
  disk differs from what the script would write). Run with `py -3 tools/art/<script>.py`, then
  `pixelforge lint` and `godot --headless --import`:
  - `band_frames.py` — the gate band darkened per day (D39), the doors' sprites for later days and
    their glow pulse's dim frames (D19), and the corner fog's frames (D19);
  - `sprite_frames.py` — Huginn's moonlit rim, head tilt and ruffle, and the mentor's blink (D17);
  - `nameplates.py` — the soul's name plate as a carved wooden plate, plain, frost and Hel's mark.
