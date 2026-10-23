"""The soul's name plate as an object: a carved wooden plate (the WP2 critic's finding).

Run from anywhere with ``py -3 tools/art/nameplates.py``; ``--check`` only reports whether the
files on disk are what the script would write (exit 1 when not). Every pixel is placed from the
maps below (small UI is placed pixel by pixel, never generated); palette colours only.

The plate is 60x10 with its four corner pixels cut: a Wood 3 (the desk theme's `frame`) outer
rim so its edge stands off the dark gate band on every day (D39), a Wood 0 groove inset inside
it, and a Wood 2 face with a few Wood 1 grain streaks. The engine writes the name on it in
text_light. All three plates share it; the frost plate's rime and Hel's mark sit on top.

- ``ui/nameplate-plain.png``: the plate alone.
- ``ui/nameplate-frost.png`` (a returned soul): rime grown along the top edge and from the
  corners (Fog 1, Fog 2, Ashen 2), and burn cracks (Wood 0) in the face.
- ``ui/nameplate-hel.png`` (a soul Hel asked for): Hel's serpent mark in pale Fog 2 in a recessed
  cell at the right end. Not Bile: lint reserves Bile for Hel's door.
"""

from __future__ import annotations

import argparse
import sys

from PIL import Image

from art_palette import ART, PALETTE, same_pixels, save

WIDTH = 60
HEIGHT = 10
GRAIN = ((3, 38, 45), (6, 7, 12), (5, 49, 54), (7, 26, 30))
# The frost: rime in Fog 1 (f), Fog 2 (F) and Ashen 2 (A), burn cracks (c); "." leaves the plate.
FROST = (
    ".ffffffffffffffffffffffffffffffffffffffffffffffffffffffffff.",
    ".FAF....FF.......FF....FF.........FF.....FF.......FF....FFA.",
    ".FF...................................c..................FF.",
    ".F.......c............................c...................F.",
    "..........c............................c....................",
    "..........c...........................................c.....",
    "...........c...........................................c....",
    ".F.....................................................c..F.",
    ".AF......................................................FA.",
    "............................................................",
)
# Hel's mark: the cell's divider (d), its recessed face (r) and the serpent (F).
HEL = (
    "............................................................",
    "...............................................drrrFFFFrrrr.",
    "...............................................drrFrrrrFrrr.",
    "...............................................drFrrFFrrFrr.",
    "...............................................drFrFrrFrFrr.",
    "...............................................drFrFrFFrFrr.",
    "...............................................drFrrFrrrFrr.",
    "...............................................drrFrrrrFFrr.",
    "...............................................drrrFFFFrFFr.",
    "............................................................",
)
INKS = {
    "f": PALETTE["Fog 1"],
    "F": PALETTE["Fog 2"],
    "A": PALETTE["Ashen 2"],
    "c": PALETTE["Wood 0"],
    "d": PALETTE["Wood 0"],
    "r": PALETTE["Wood 1"],
}


def plate() -> Image.Image:
    """The plain carved plate."""
    image = Image.new("RGBA", (WIDTH, HEIGHT), (0, 0, 0, 0))
    groove, shade, face, rim = (PALETTE[f"Wood {n}"] for n in range(4))
    last_x, last_y = WIDTH - 1, HEIGHT - 1
    for y in range(HEIGHT):
        for x in range(WIDTH):
            if x in (0, last_x) and y in (0, last_y):
                continue
            colour = face
            if x in (0, last_x) or y in (0, last_y):
                colour = rim
            elif x in (1, last_x - 1) or y in (1, last_y - 1):
                colour = groove
            image.putpixel((x, y), (*colour, 255))
    for row, left, right in GRAIN:
        for x in range(left, right + 1):
            image.putpixel((x, row), (*shade, 255))
    return image


def marked(base: Image.Image, rows: tuple[str, ...]) -> Image.Image:
    """`base` with the map's marks drawn on it; corner pixels stay cut."""
    image = base.copy()
    for y, row in enumerate(rows):
        for x, key in enumerate(row):
            if key in INKS and image.getpixel((x, y))[3]:
                image.putpixel((x, y), (*INKS[key], 255))
    return image


def outputs() -> dict:
    """Every file this script writes, by path, with its pixels."""
    ui = ART / "ui"
    base = plate()
    return {
        ui / "nameplate-plain.png": base,
        ui / "nameplate-frost.png": marked(base, FROST),
        ui / "nameplate-hel.png": marked(base, HEL),
    }


def main() -> int:
    parser = argparse.ArgumentParser(description=__doc__.splitlines()[0])
    parser.add_argument("--check", action="store_true", help="only compare with the files on disk")
    args = parser.parse_args()
    for rows in (FROST, HEL):
        if len(rows) != HEIGHT or any(len(row) != WIDTH for row in rows):
            raise ValueError("a mark map is not 60x10")
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
