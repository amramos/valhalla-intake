"""Huginn's moonlit rim and the idle frames of the desk's characters (D17, D39, D40).

Run from anywhere with ``py -3 tools/art/sprite_frames.py``; ``--check`` only reports whether the
files on disk are what the script would write (exit 1 when not). Each frame is the rest sprite
with a few pixels moved or recoloured, palette colours only, no randomness.

- ``portraits/huginn.png`` (rewritten in place; running again changes nothing): the raven is now
  the Huginn control (D40) and must read on day 3's darker band (D39), so every dark (Night 0-2)
  pixel on his silhouette's edge takes a moonlit rim: Night 5 where the edge faces up, Night 4 on
  the sides.
- ``portraits/huginn-tilt.png``: the head cocked: the beak side (x <= 14) dips one pixel and the
  crown (rows 3-6) leans one pixel forward.
- ``portraits/huginn-ruffle.png``: the plumage puffed: each body row (14-29) one pixel wider on
  both sides, and the crown feathers standing one pixel up.
- ``portraits/mentor-blink.png``: both eyes closed: the pupils and the pixel either side of each
  become a Wood 4 lid line.
"""

from __future__ import annotations

import argparse
import sys

from PIL import Image

from art_palette import ART, PALETTE, same_pixels, save

CLEAR = (0, 0, 0, 0)
# Huginn's head (sprite pixels): rows HEAD_ROWS left of HEAD_RIGHT; the beak is x <= BEAK_RIGHT.
HEAD_ROWS = range(3, 13)
HEAD_RIGHT = 25
BEAK_RIGHT = 14
CROWN_LAST_ROW = 6
BODY_ROWS = range(14, 30)
CROWN_TOP_LIMIT = 6
# The mentor's pupils (portrait pixels, row 13).
EYE_ROW = 13
PUPILS = (12, 18)
LID = PALETTE["Wood 4"]
DARK = tuple(PALETTE[f"Night {n}"] for n in range(3))
RIM_TOP = PALETTE["Night 5"]
RIM_SIDE = PALETTE["Night 4"]


def rimmed(rest: Image.Image) -> Image.Image:
    """Huginn with a moonlit rim on his silhouette's dark edge pixels."""
    source = rest.load()
    width, height = rest.size
    result = rest.copy()
    out = result.load()

    def clear(x: int, y: int) -> bool:
        return not (0 <= x < width and 0 <= y < height) or source[x, y][3] == 0

    for y in range(height):
        for x in range(width):
            if source[x, y][3] == 0 or source[x, y][:3] not in DARK:
                continue
            if clear(x, y - 1):
                out[x, y] = (*RIM_TOP, 255)
            elif clear(x - 1, y) or clear(x + 1, y):
                out[x, y] = (*RIM_SIDE, 255)
    return result


def tilted(rest: Image.Image) -> Image.Image:
    """Huginn with his head cocked: the beak dips, the crown leans forward."""
    source = rest.load()
    result = rest.copy()
    out = result.load()
    for y in HEAD_ROWS:
        for x in range(HEAD_RIGHT):
            out[x, y] = CLEAR
    last = HEAD_ROWS[-1]
    for y in HEAD_ROWS:
        for x in range(HEAD_RIGHT):
            if source[x, y][3] == 0:
                continue
            if x <= BEAK_RIGHT:
                out[x, min(last, y + 1)] = source[x, y]
            elif y <= CROWN_LAST_ROW:
                out[x - 1, y] = source[x, y]
            else:
                out[x, y] = source[x, y]
    # The head's last row meets the neck: whatever the dip left empty there keeps its pixel.
    for x in range(HEAD_RIGHT):
        if out[x, last][3] == 0 and source[x, last][3]:
            out[x, last] = source[x, last]
    return result


def ruffled(rest: Image.Image) -> Image.Image:
    """Huginn with his plumage puffed: the body a pixel wider each side, the crown standing up."""
    source = rest.load()
    width, height = rest.size
    result = rest.copy()
    out = result.load()
    for y in BODY_ROWS:
        filled = [x for x in range(width) if source[x, y][3]]
        if not filled:
            continue
        left, right = min(filled), max(filled)
        if left > 0:
            out[left - 1, y] = source[left, y]
        if right < width - 1:
            out[right + 1, y] = source[right, y]
    for x in range(width):
        column = [y for y in range(height) if source[x, y][3]]
        if column and 0 < column[0] < CROWN_TOP_LIMIT:
            out[x, column[0] - 1] = source[x, column[0]]
    return result


def blinking(rest: Image.Image) -> Image.Image:
    """The mentor with both eyes closed."""
    result = rest.copy()
    for pupil in PUPILS:
        for x in (pupil - 1, pupil, pupil + 1):
            result.putpixel((x, EYE_ROW), (*LID, 255))
    return result


def outputs() -> dict:
    """Every file this script writes, by path, with its pixels."""
    portraits = ART / "portraits"
    huginn = rimmed(Image.open(portraits / "huginn.png").convert("RGBA"))
    mentor = Image.open(portraits / "mentor.png").convert("RGBA")
    return {
        portraits / "huginn.png": huginn,
        portraits / "huginn-tilt.png": tilted(huginn),
        portraits / "huginn-ruffle.png": ruffled(huginn),
        portraits / "mentor-blink.png": blinking(mentor),
    }


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
