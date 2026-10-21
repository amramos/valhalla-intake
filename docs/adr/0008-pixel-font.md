# ADR-0008: One pixel font, m5x7 (CC0)

**Status:** Accepted
**Date:** 2026-10-21

## Context

Every word of evidence (claims, witnesses, decrees, hover labels, captions) is rendered by the
engine at the base resolution of 480×270 and must read at 1:1 (D7, D21). The font must:

- be licensed CC0 or OFL, so it ships in every build without conditions;
- carry á, ó, ö and þ (Fólkvangr, names, Old Norse words);
- read at about 7 px tall, so a claim line of about 18–22 characters fits a desk panel beside the
  128 px body chart.

## Decision

Use **m5x7** by Daniel Linssen, a proportional 5×7 pixel font:

- **Source:** <https://managore.itch.io/m5x7>, the author's own page, file `m5x7.ttf` (retrieved
  2026-10-21, SHA-256 in the licence file).
- **Licence:** CC0 1.0 Universal, as the source page states. `assets/fonts/m5x7-LICENSE.txt`
  records the source and reproduces the CC0 legal code; credit is appreciated, not required.
- **Coverage:** checked in Godot 4.7.1 (`FontFile.has_char`): á ó ö þ Þ Á Ó Ö é í ú ð æ and the
  straight quotes are present. Curly quotes, the em dash, the ellipsis and ♥ are not, so authored
  text uses straight `'` and `"` only.
- **Use:** size 16, where one font pixel is one screen pixel (cap height 7 px, descent 2 px). The
  desk draws lines on a 10 px pitch (`line_spacing` −3).
- **Rendering settings:** `*.import` files are not committed (`.gitignore`), so import options
  would be lost on a fresh checkout. The desk sets antialiasing off, hinting off and subpixel
  positioning off on the font at runtime (`PixelFont.configure`).

## Alternatives considered

- **monogram** (datagoblin, CC0): monospaced at 6 px a character, so a 25-character prefixed claim
  line needs 150 px, which leaves the Law too narrow for its decrees.
- **m3x6** (same author): narrower, but its page says "free to use with attribution" with no CC0
  or OFL licence, and at 6 px tall it misses the readability target.
- **Larger CC0/OFL pixel fonts** (Press Start 2P, Pixeloid Sans and the like): not measured here;
  their glyphs are 7–8 px wide or more, and m5x7 already fills the panels at 5 px.

## Consequences

- A prefixed line of 22 characters measures 133–142 px. The WP1 fit check
  (`docs/plans/vertical-slice-fitcheck.png`) sets the per-line cap from those measurements.
- At 1:1 no 5×7-class font puts the longest decree (L1, 556 px) on two lines in layout A3; the fit
  check reports how many lines each decree takes.
- Curly punctuation in authored text renders as missing glyphs; content must use straight quotes.

**Revisit when:** a target platform renders text at a non-integer scale, the slice adds a language
whose letters m5x7 lacks, or playtesters find the evidence text hard to read at 1:1.
