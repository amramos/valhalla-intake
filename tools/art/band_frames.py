"""Recolours the gate band by day, and makes the doors' glow pulse and the corner fog frames.

Run from anywhere with ``py -3 tools/art/band_frames.py``; ``--check`` only reports whether the
files on disk are what the script would write (exit 1 when not). Pillow only, no randomness: the
same inputs always give the same pixels. Inputs are never written: ``scenes/gate-desk.png`` and
the doors' ``<realm>-lit.png`` / ``<realm>-locked.png``.

- **Days darken (D39):** day N is the gate band (rows 0-95 of ``gate-desk.png``) with every Night
  and Fog colour N-1 steps down its own ramp (Night 0 and Fog 0 are the floors). Every other
  colour (the post's Wood, the Tide glints) and the whole desk keep their values. Outputs
  ``scenes/gate-desk-day<N>.png`` for days 2..DAYS (day 1 is ``gate-desk.png`` itself).
- **The doors on later days:** each door sprite carries its own arch stones, so a door keeps its
  light, glyph and bar, and its Night and Fog stones step down with the band; otherwise its
  rectangle would show against the darker wall. Outputs ``doors/day<N>/<realm>-<kind>.png``.
- **The glow pulse (D19):** ``<realm>-lit-dim.png`` is the lit sprite with the outer two pixels of
  its brightest glow band's outline one ramp step darker (into the band around it), so the core
  shrinks and swells between the two frames. Nothing outside that band changes; never a tint.
- **Fog (D19):** ``fog/fog-day<N>.png`` is three 480x20 frames stacked (rows 76-95 of the band):
  frame 0 is the day's band as painted; in frames 1 and 2 every third 4-pixel column of the fog
  inside the two corner masks lifts by one pixel (a different third each frame), so a swell runs
  along the banks. Everything outside the masks is transparent.
"""

from __future__ import annotations

import argparse
import sys

from PIL import Image

from art_palette import ART, Rgb, ramp, same_pixels, save, PALETTE

DAYS = 3
BAND_ROWS = 96
FOG_TOP = 76
FOG_ROWS = BAND_ROWS - FOG_TOP
FOG_FRAMES = 3
# The fog banks' masks (rows and x inclusive, measured on gate-desk.png): the corners beside the
# wall, wider in the lower rows where the banks run on to the doors: (top, bottom, left, right).
FOG_MASKS = (
    (76, 85, 0, 52),
    (86, 95, 0, 88),
    (76, 85, 412, 479),
    (86, 95, 392, 479),
)
# The fog's colours on day 1 and the open dark it drifts in: the only pixels the drift moves.
FOG_AIR = (PALETTE["Night 1"], PALETTE["Night 4"], PALETTE["Fog 0"])
FOG_COLUMN = 4
REALMS = ("valhalla", "hel", "folkvangr")
# Each lit door's two brightest glow bands: the core and the band around it.
GLOW_CORE: dict[str, tuple[str, str]] = {
    "valhalla": ("Ember 2", "Ember 1"),
    "hel": ("Bile 2", "Bile 1"),
    "folkvangr": ("Parchment 1", "Parchment 0"),
}
# The dim frame pulls the core's outline in this far, after closing gaps this wide in it.
CORE_RIM = 2
CORE_CLOSE = 2

NIGHT = ramp("Night")
FOG = ramp("Fog")


def darker(colour: Rgb, steps: int) -> Rgb:
    """`colour` `steps` values down its own ramp when it is Night or Fog, else unchanged."""
    for shades in (NIGHT, FOG):
        if colour in shades:
            return shades[max(0, shades.index(colour) - steps)]
    return colour


def darkened(image: Image.Image, steps: int, rows: int | None = None) -> Image.Image:
    """A copy of `image` with its Night and Fog pixels `steps` down (only the first `rows` rows)."""
    result = image.convert("RGBA").copy()
    pixels = result.load()
    for y in range(result.height if rows is None else rows):
        for x in range(result.width):
            red, green, blue, alpha = pixels[x, y]
            if alpha:
                pixels[x, y] = (*darker((red, green, blue), steps), alpha)
    return result


def _grown(mask: set, size: tuple[int, int], radius: int) -> set:
    """`mask` dilated by `radius` (Chebyshev) inside an image of `size`."""
    width, height = size
    return {
        (x, y)
        for y in range(height)
        for x in range(width)
        if any(
            (nx, ny) in mask
            for ny in range(y - radius, y + radius + 1)
            for nx in range(x - radius, x + radius + 1)
        )
    }


def _shrunk(mask: set, size: tuple[int, int], radius: int) -> set:
    """`mask` eroded by `radius` (Chebyshev); beyond the image counts as outside."""
    width, height = size
    return {
        (x, y)
        for (x, y) in mask
        if all(
            0 <= nx < width and 0 <= ny < height and (nx, ny) in mask
            for ny in range(y - radius, y + radius + 1)
            for nx in range(x - radius, x + radius + 1)
        )
    }


def dimmed(lit: Image.Image, realm: str) -> Image.Image:
    """The pulse's dim frame: the core's outline pulled in by CORE_RIM pixels.

    The core is ragged (planks of the band around it run through it), so its outline is taken
    after closing those gaps (CORE_CLOSE); only core pixels within CORE_RIM of that outline step
    down to the band's colour, and the core shrinks as one shape.
    """
    core, band = (PALETTE[name] for name in GLOW_CORE[realm])
    result = lit.convert("RGBA").copy()
    pixels = result.load()
    size = result.size
    mask = {(x, y) for y in range(size[1]) for x in range(size[0]) if pixels[x, y][:3] == core}
    closed = _shrunk(_grown(mask, size, CORE_CLOSE), size, CORE_CLOSE)
    inner = _shrunk(closed, size, CORE_RIM)
    for x, y in mask - inner:
        pixels[x, y] = (*band, 255)
    return result


def _fog_frame(band: Image.Image, frame: int) -> Image.Image:
    """Day 1's band with the fog banks lifted for `frame` (0 is the band itself).

    The masks are cut into columns FOG_COLUMN wide; in frame 1 every third column from the first
    lifts its fog by one pixel, in frame 2 the next, so a swell runs along the banks. Only the fog
    and the open dark (Night 1, Night 4, Fog 0) move, and only onto each other, so no wall stone
    ever changes.
    """
    result = band.copy()
    if frame == 0:
        return result
    source = band.load()
    out = result.load()
    for top, bottom, left, right in FOG_MASKS:
        for x in range(left, right + 1):
            if (x // FOG_COLUMN) % 3 != frame:
                continue
            for y in range(top, bottom + 1):
                below = y + 1
                if below >= BAND_ROWS:
                    continue
                if source[x, y][:3] in FOG_AIR and source[x, below][:3] in FOG_AIR:
                    out[x, y] = source[x, below]
    return result


def in_fog_mask(x: int, y: int) -> bool:
    """True when the band's pixel (x, y) lies in one of the corner masks."""
    return any(
        top <= y <= bottom and left <= x <= right for top, bottom, left, right in FOG_MASKS
    )


def fog_sheet(day_one: Image.Image, steps: int) -> Image.Image:
    """The day's three fog frames stacked: rows FOG_TOP.. inside the corner masks only."""
    sheet = Image.new("RGBA", (day_one.width, FOG_ROWS * FOG_FRAMES), (0, 0, 0, 0))
    out = sheet.load()
    for frame in range(FOG_FRAMES):
        pixels = darkened(_fog_frame(day_one, frame), steps, BAND_ROWS).load()
        for row in range(FOG_ROWS):
            for x in range(day_one.width):
                if in_fog_mask(x, FOG_TOP + row):
                    out[x, frame * FOG_ROWS + row] = pixels[x, FOG_TOP + row]
    return sheet


def outputs() -> dict:
    """Every file this script writes, by path, with its pixels."""
    files = {}
    backdrop = Image.open(ART / "scenes" / "gate-desk.png").convert("RGBA")
    for day in range(1, DAYS + 1):
        band = darkened(backdrop, day - 1, BAND_ROWS)
        if day > 1:
            files[ART / "scenes" / f"gate-desk-day{day}.png"] = band
        files[ART / "fog" / f"fog-day{day}.png"] = fog_sheet(backdrop, day - 1)
    for realm in REALMS:
        lit = Image.open(ART / "doors" / f"{realm}-lit.png").convert("RGBA")
        locked = Image.open(ART / "doors" / f"{realm}-locked.png").convert("RGBA")
        dim = dimmed(lit, realm)
        files[ART / "doors" / f"{realm}-lit-dim.png"] = dim
        for day in range(2, DAYS + 1):
            folder = ART / "doors" / f"day{day}"
            files[folder / f"{realm}-lit.png"] = darkened(lit, day - 1)
            files[folder / f"{realm}-locked.png"] = darkened(locked, day - 1)
            files[folder / f"{realm}-lit-dim.png"] = darkened(dim, day - 1)
    return files


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="only compare with the files on disk")
    args = parser.parse_args()
    stale = []
    for path, image in outputs().items():
        name = path.relative_to(ART).as_posix()
        if args.check:
            if not same_pixels(path, image):
                stale.append(name)
            continue
        save(image, path)
        print(f"wrote {name} {image.width}x{image.height}")
    for name in stale:
        print(f"out of date: {name}")
    return 1 if stale else 0


if __name__ == "__main__":
    sys.exit(main())
