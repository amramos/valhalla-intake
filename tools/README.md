# tools/

Development-only scripts and harnesses, **never shipped** and never referenced by game code.

- `ci/export_all.py` — exports every preset into `build/<channel>/` (used by the release workflow).
- `ci/export_smoke_test.sh` — boots the exported Linux build headless and fails on errors.
- `ci/check_art_coverage.py` — fails when an image under `assets/art/` matches no pixelforge canvas.
- `harness/` — the headless text harness: the slice played as text through `DeskCommands` (D13).
- `fitcheck/fit_check.gd` — the D21 fit check: renders the desk at 480×270 with the slice's longest
  text and saves `docs/plans/vertical-slice-fitcheck.png` (and a ×3 copy). Run in a window:
  `godot --path . --resolution 480x270 -s tools/fitcheck/fit_check.gd`.
- `desk_shots/desk_shots.gd` — plays the real desk with real mouse events, checks each step (exit 1 on a failure) and saves a 1:1
  screenshot per step: `godot --path . --resolution 480x270 -s tools/desk_shots/desk_shots.gd -- <folder>`.
- `audit_kit/audit_kit.gd` — the evidence auditor's kit (D26): for every encounter, a 1:1 desk PNG and a
  text file of only what the player can read. Run in a window:
  `godot --path . --resolution 480x270 -s tools/audit_kit/audit_kit.gd -- <folder>`.
