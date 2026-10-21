# ADR-0006: pixelforge lints every asset against the style guide

**Status:** Accepted
**Date:** 2026-10-21

## Context

The art is generated, mostly by agents, against the style guide in `docs/art/`. Without a check, each
generated asset drifts a little. The style frames showed how it drifts:

- generated skin came back tan instead of ashen;
- parchment snapped to Hel's bile green;
- hair snapped to the blood colour that marks wounds.

These are colour-by-meaning errors that a reviewer misses at ×1 and that confuse players, because
in this game colour is evidence: ember means Valhalla, bile means Hel, blood means a wound.

## Decision

Adopt **pixelforge** as the art linter. `pixelforge.toml` at the repository root points at
`docs/art/palette.gpl` and declares:

- one canvas per asset kind under `assets/art/` (scene, soul, body chart, prop, Law scroll), each
  with a size and a colour budget;
- three reserved ramps: Ember only in scenes, doors and UI; Bile only in scenes and doors; Blood
  only in scenes, souls and body charts.

CI runs `python -m pixelforge lint` and `tools/ci/check_art_coverage.py` (every image under
`assets/art/` must match a canvas) on every pull request, pinned to a commit of
`github.com/amramos/pixelforge`. pixelforge's `clean` command snaps generated art onto the palette
and canvas (`docs/art/art-direction.md`, "Prompt core").

pixelforge matches canvas paths with `fnmatch`, so `dir/**/*.png` needs at least one subfolder.
Each canvas therefore lists `dir/*.png` and `dir/**/*.png`.

## Alternatives considered

- **A review rule only** ("check the palette by eye"): it already failed on the style frames, where
  three meaning errors passed a first look.
- **Our own script in `tools/`:** it would re-implement pixelforge's palette snap, canvas fit and
  reserved colours, which already exist and are tested.
- **Aseprite palettes and manual export:** this assumes a human artist at every step. Agents produce
  most of the art here.

## Consequences

- A wrong colour, size or budget fails CI instead of reaching review. Reserved colours are enforced
  per asset path, not per region inside an image: a soul may carry Blood anywhere in its file, so
  where it sits inside the image is still a review and auditor check.
- Adding an asset kind means adding a canvas to `pixelforge.toml` first.
- CI depends on a public GitHub repository at a pinned commit. Moving the pin is a deliberate edit.

**Revisit when:** the game stops being palette-locked pixel art, or pixelforge stops being maintained
or can't express a rule the art needs (for example, per-region reserved colours inside one scene).
