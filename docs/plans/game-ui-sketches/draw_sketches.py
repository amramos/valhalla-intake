#!/usr/bin/env python3
"""Draw the game-UI layout sketches (forks S1 and S2) over real 1:1 desk captures.

Every pixel is a palette colour (docs/art/palette.gpl); text is m5x7 at size 16 with no
anti-aliasing (ADR-0008). The captures are 480x270 screenshots of the slice, read from SHOTS_DIR.

    py -3 docs/plans/game-ui-sketches/draw_sketches.py [SHOTS_DIR]

SHOTS_DIR defaults to $VI_SHOTS, then to the folder the captures were taken into.
"""

from __future__ import annotations

import math
import os
import random
import re
import sys
from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[2]
DEFAULT_SHOTS = (
    r"C:\Users\Admin\AppData\Local\Temp\claude"
    r"\D--amramos-code-valhalla-intake--claude-worktrees-game-ui-visual-overhaul-7c2517"
    r"\51d760c4-0c53-44fa-86f9-a856f32f03a3\scratchpad\shots"
)
SHOTS = Path(sys.argv[1] if len(sys.argv) > 1 else os.environ.get("VI_SHOTS", DEFAULT_SHOTS))
OUT = HERE

# --------------------------------------------------------------------------- palette

PAL: dict[str, tuple[int, int, int]] = {}
for _line in (ROOT / "docs/art/palette.gpl").read_text(encoding="utf-8").splitlines():
    _m = re.match(r"^\s*(\d+)\s+(\d+)\s+(\d+)\s+(.+)$", _line)
    if _m:
        PAL[_m.group(4).strip()] = (int(_m.group(1)), int(_m.group(2)), int(_m.group(3)))
PAL_SET = set(PAL.values())

N0, N1, N2, N3, N4, N5 = (PAL[f"Night {i}"] for i in range(6))
TIDE = PAL["Tide"]
F0, F1, F2 = (PAL[f"Fog {i}"] for i in range(3))
W0, W1, W2, W3, W4 = (PAL[f"Wood {i}"] for i in range(5))
E0, E1, E2 = (PAL[f"Ember {i}"] for i in range(3))
B0, B1, B2 = (PAL[f"Bile {i}"] for i in range(3))
P0, P1, P2 = (PAL[f"Parchment {i}"] for i in range(3))

# --------------------------------------------------------------------------- font

FONT = ImageFont.truetype(str(ROOT / "assets/fonts/m5x7.ttf"), 16)
ASC = FONT.getbbox("H")[1]  # rows above the cap top inside a rendered line


def tw(s: str) -> int:
    return int(round(FONT.getlength(s)))


def _mask(s: str) -> Image.Image:
    m = Image.new("L", (tw(s) + 2, 16), 0)
    d = ImageDraw.Draw(m)
    d.fontmode = "1"
    d.text((0, 0), s, font=FONT, fill=255)
    return m.point(lambda v: 255 if v >= 128 else 0).convert("1")


def text(img: Image.Image, x: int, y: int, s: str, col, scale: int = 1) -> None:
    """Draw s with its cap top at y (cap 7 px, descent 2 px, at scale 1)."""
    m = _mask(s)
    if scale > 1:
        m = m.resize((m.width * scale, m.height * scale), Image.NEAREST)
    img.paste(col, (x, y - ASC * scale), m)


def carved(img: Image.Image, x: int, y: int, s: str, col=F2, shade=N0) -> None:
    text(img, x - 1, y - 1, s, shade)
    text(img, x, y, s, col)


def wrap(s: str, width: int) -> list[str]:
    lines: list[str] = []
    cur = ""
    for word in s.split(" "):
        t = word if not cur else cur + " " + word
        if tw(t) <= width:
            cur = t
        else:
            lines.append(cur)
            cur = word
    if cur:
        lines.append(cur)
    return lines


def underline_wavy(img, x0: int, x1: int, y: int, col, seed: int) -> None:
    rng = random.Random(seed)
    off = 0
    for x in range(x0, x1 + 1):
        if rng.random() < 0.18:
            off = 1 - off
        P(img, x, y + off, col)


# --------------------------------------------------------------------------- primitives


def P(img, x: int, y: int, col) -> None:
    if 0 <= x < img.width and 0 <= y < img.height:
        img.putpixel((x, y), col)


def R(img, x0: int, y0: int, x1: int, y1: int, col) -> None:
    ImageDraw.Draw(img).rectangle([x0, y0, x1, y1], fill=col)


def bitmap(img, x: int, y: int, rows: list[str], cmap: dict) -> None:
    for j, row in enumerate(rows):
        for i, ch in enumerate(row):
            if ch in cmap:
                P(img, x + i, y + j, cmap[ch])


def rect_mask(x0, y0, x1, y1, cut: int = 1) -> set:
    m = set()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            dx = min(x - x0, x1 - x)
            dy = min(y - y0, y1 - y)
            if dx + dy >= cut:
                m.add((x, y))
    return m


def erode(m: set) -> set:
    return {
        (x, y)
        for (x, y) in m
        if (x + 1, y) in m and (x - 1, y) in m and (x, y + 1) in m and (x, y - 1) in m
    }


def _deckle(n: int, rng: random.Random, deep: float) -> list[int]:
    out: list[int] = []
    while len(out) < n:
        if rng.random() < deep:
            out += [2] * rng.randint(1, 2)
        else:
            out += [rng.choice((0, 0, 1))] * rng.randint(2, 6)
    return out[:n]


def deckled_mask(x0, y0, x1, y1, seed: int, sides: str = "tblr", deep: float = 0.07) -> set:
    """A sheet whose chosen sides are torn: hand-drawn runs of 0-2 px insets."""
    rng = random.Random(seed)
    w, h = x1 - x0 + 1, y1 - y0 + 1
    t = _deckle(w, rng, deep) if "t" in sides else [0] * w
    b = _deckle(w, rng, deep) if "b" in sides else [0] * w
    left = _deckle(h, rng, deep) if "l" in sides else [0] * h
    right = _deckle(h, rng, deep) if "r" in sides else [0] * h
    m = set()
    for y in range(y0, y1 + 1):
        for x in range(x0, x1 + 1):
            i, j = x - x0, y - y0
            if t[i] <= j <= h - 1 - b[i] and left[j] <= i <= w - 1 - right[j]:
                m.add((x, y))
    return m - {(x0, y0), (x1, y0), (x0, y1), (x1, y1)}


def drop_shadow(img, m: set, col=W0, depth: int = 1) -> None:
    for (x, y) in m:
        for d in range(1, depth + 1):
            if (x + d, y + d) not in m:
                P(img, x + d, y + d, col)


def paint_paper(img, m: set, body=P2, edge=P0, band=P1, shadow=W0, depth: int = 1) -> None:
    if shadow is not None:
        drop_shadow(img, m, shadow, depth)
    inner = erode(m)
    for (x, y) in m:
        if (x, y) not in inner:
            col = edge
        elif (x + 1, y) not in inner or (x, y + 1) not in inner:
            col = band
        else:
            col = body
        P(img, x, y, col)


def paint_slab(img, m: set, surface=N2, groove=F1, inset: int = 3, shadow=W0) -> None:
    """A carved stone tablet: bevelled edge, a Fog 1 groove `inset` px in."""
    if shadow is not None:
        drop_shadow(img, m, shadow, 1)
    rings = [m]
    for _ in range(inset + 1):
        rings.append(erode(rings[-1]))
    for (x, y) in m:
        if (x, y) not in rings[1]:
            lower_right = (x + 1, y) not in m or (x, y + 1) not in m
            col = N0 if lower_right else N4
        elif (x, y) not in rings[2]:
            lower_right = (x + 1, y) not in rings[1] or (x, y + 1) not in rings[1]
            col = N1 if lower_right else N3
        else:
            col = surface
        P(img, x, y, col)
    for (x, y) in rings[inset - 1] - rings[inset]:
        P(img, x, y, N0)
    for (x, y) in rings[inset] - rings[inset + 1]:
        P(img, x, y, groove)


ROUND5 = [".###.", "#####", "#####", "#####", ".###."]


def pin(img, cx: int, cy: int) -> None:
    pts = {(cx - 2 + i, cy - 2 + j) for j, r in enumerate(ROUND5) for i, ch in enumerate(r) if ch == "#"}
    for (x, y) in pts:
        if (x + 1, y + 1) not in pts:
            P(img, x + 1, y + 1, W0)
    for (x, y) in pts:
        P(img, x, y, W1 if ((x + 1, y) not in pts or (x, y + 1) not in pts) else W3)
    P(img, cx - 1, cy - 1, P2)


def pin_icon(img, x: int, y: int) -> None:
    """A 5x5 pin in the law thread's colours (Parchment/Wood dashed)."""
    for j, r in enumerate(ROUND5):
        for i, ch in enumerate(r):
            if ch == "#":
                P(img, x + i, y + j, W3 if (i // 2 + j) % 2 == 0 else P0)
    P(img, x + 1, y + 1, P2)


def thread_path(a, b, sag: int) -> list:
    cx, cy = (a[0] + b[0]) / 2, max(a[1], b[1]) + sag
    pts: list[tuple[int, int]] = []
    for i in range(801):
        t = i / 800
        x = (1 - t) ** 2 * a[0] + 2 * (1 - t) * t * cx + t * t * b[0]
        y = (1 - t) ** 2 * a[1] + 2 * (1 - t) * t * cy + t * t * b[1]
        q = (round(x), round(y))
        if not pts or pts[-1] != q:
            pts.append(q)
    return pts


def thread(img, a, b, sag: int, cols=(W3, P1), dash=(3, 2), shadow=W0) -> list:
    """A 2 px thread sagging from a to b, with a 1 px dark shadow under it."""
    pts = thread_path(a, b, sag)
    for (x, y) in pts:
        P(img, x, y + 2, shadow)
    period = dash[0] + dash[1]
    for k, (x, y) in enumerate(pts):
        col = cols[0] if k % period < dash[0] else cols[1]
        P(img, x, y, col)
        P(img, x, y + 1, col)
    return pts


def seal(img, cx: int, cy: int, r: int, ramp=(E0, E1, E2), shadow=W0, mark: bool = False) -> None:
    pts = {
        (x, y)
        for x in range(cx - r - 1, cx + r + 2)
        for y in range(cy - r - 1, cy + r + 2)
        if (x - cx) ** 2 + (y - cy) ** 2 <= r * r + r * 0.8
    }
    if shadow is not None:
        drop_shadow(img, pts, shadow)
    inner = erode(pts)
    for p in pts:
        P(img, p[0], p[1], ramp[1] if p in inner else ramp[0])
    P(img, cx - 1, cy - 1, ramp[2])
    if r >= 3:
        P(img, cx - 2, cy - 1, ramp[2])
        P(img, cx - 1, cy - 2, ramp[2])
    if mark:  # a pressed spear in the wax
        for y in range(cy - 2, cy + 3):
            P(img, cx + 1, y, ramp[0])
        P(img, cx, cy - 1, ramp[0])
        P(img, cx + 2, cy - 1, ramp[0])


TICK = ["....#", "...##", "#.##.", "###..", ".#..."]
FEATHER5 = ["...##", "..###", ".###.", "###..", "#...."]
FROST = ["#.#.#", ".###.", "##.##", ".###.", "#.#.#"]


def mark(img, x: int, y: int, kind: str) -> None:
    rows, col = {"tick": (TICK, W0), "feather": (FEATHER5, N0), "frost": (FROST, TIDE)}[kind]
    bitmap(img, x, y, rows, {"#": col})


def candle(img, x: int, y: int, h: int = 14) -> None:
    """A 6 x h candle whose body's top-left is (x, y); the flame is Ember 2, 2x3."""
    for j in range(h):
        for i, col in enumerate((P2, P2, P2, P1, P1, P0)):
            P(img, x + i, y + j, col)
    for i in range(6):
        P(img, x + i, y, P1)
    P(img, x + 1, y + 1, P1)
    P(img, x + 1, y + 2, P1)  # a drip
    P(img, x + 2, y - 1, W0)  # wick
    R(img, x + 2, y - 4, x + 3, y - 2, E2)
    R(img, x - 2, y + h, x + 7, y + h, W3)
    R(img, x - 2, y + h + 1, x + 7, y + h + 1, W1)


def ribbon(img, x: int, y0: int, y1: int, fork_at: str, w: int = 5, behind=N0) -> None:
    """A Tide ribbon bookmark; its free end has a V notch showing what lies behind."""
    R(img, x, y0, x + w - 1, y1, TIDE)
    R(img, x + w - 1, y0, x + w - 1, y1, N4)
    R(img, x, y0, x, y1, N3)
    fy, step = (y0, 1) if fork_at == "top" else (y1, -1)
    for k in range(2):
        for i in range(1 + k, w - 1 - k):
            P(img, x + i, fy + step * (1 - k), behind)


def open_book(img, x0: int, y0: int, x1: int, y1: int, seed: int, stack: int = 3):
    """An open ledger: Wood boards, two worn Parchment pages, a spine. Returns page boxes."""
    cover = rect_mask(x0, y0, x1, y1, cut=2)
    drop_shadow(img, cover, N0, 2)
    inner = erode(cover)
    for (x, y) in cover:
        col = W0 if (x, y) not in inner else (W2 if y == y0 + 1 else W1)
        P(img, x, y, col)
    mid = (x0 + x1) // 2
    py0, py1 = y0 + 3, y1 - 3 - stack
    # page stack: the edges of the leaves under the open pages
    for k in range(stack):
        y = py1 + 1 + k
        R(img, x0 + 4 + k, y, mid - 2, y, P0 if k % 2 == 0 else P1)
        R(img, mid + 2, y, x1 - 4 - k, y, P0 if k % 2 == 0 else P1)
    left = deckled_mask(x0 + 4, py0, mid - 2, py1, seed, "tbl", deep=0.03)
    right = deckled_mask(mid + 2, py0, x1 - 4, py1, seed + 1, "tbr", deep=0.03)
    for m in (left, right):
        paint_paper(img, m, shadow=None)
    # gutter shading into the spine
    for y in range(py0 + 1, py1):
        for i, col in enumerate((P0, P1, P1)):
            if (mid - 2 - i, y) in left:
                P(img, mid - 2 - i, y, col)
            if (mid + 2 + i, y) in right:
                P(img, mid + 2 + i, y, col)
    for y in range(y0 + 1, y1):
        P(img, mid - 1, y, W2)
        P(img, mid, y, W0)
        P(img, mid + 1, y, W2)
    # worn outer corners
    for (cx, cy, sx, sy) in ((x0 + 4, py0, 1, 1), (x0 + 4, py1, 1, -1), (x1 - 4, py0, -1, 1), (x1 - 4, py1, -1, -1)):
        for i in range(3):
            for j in range(3 - i):
                P(img, cx + sx * i, cy + sy * j, W1)
        P(img, cx + sx * 3, cy, P0)
        P(img, cx, cy + sy * 3, P0)
    return (x0 + 4, py0, mid - 2, py1), (mid + 2, py0, x1 - 4, py1)


def dog_ear(img, x1: int, y1: int, n: int = 10, behind=W1) -> None:
    """Fold the bottom-right corner (x1, y1) of a page up: a dog-ear the player clicks."""
    bx, by = x1 - n, y1 - n
    for dy in range(n + 1):
        for dx in range(n + 1):
            x, y = bx + dx, by + dy
            if dx + dy > n:
                P(img, x, y, behind)
            elif dx + dy == n:
                P(img, x, y, P0)
            elif dx + dy >= n - 1 - 0:
                P(img, x, y, P1)
    # the flap folded over the page
    for dy in range(n):
        for dx in range(n - dy):
            x, y = bx + dx, by + dy
            col = P1
            if dx == 0 or dy == 0:
                col = P0
            P(img, x, y, col)
    for i in range(n):  # shadow of the flap on the page
        P(img, bx - 1, by + i, P0)
        P(img, bx + i, by - 1, P0)
    for i in range(n + 1):
        P(img, bx + i, by + n - i, W2)


def fill_tile(img, x0: int, y0: int, x1: int, y1: int, tile: Image.Image) -> None:
    for ty in range(y0, y1 + 1, tile.height):
        for tx in range(x0, x1 + 1, tile.width):
            w, h = min(tile.width, x1 + 1 - tx), min(tile.height, y1 + 1 - ty)
            img.paste(tile.crop((0, 0, w, h)), (tx, ty))


def nearest(col) -> tuple[int, int, int]:
    return min(PAL_SET, key=lambda p: sum((a - b) ** 2 for a, b in zip(p, col)))


def dim(img: Image.Image, keep: set, tint=(0.36, 0.42, 0.48)) -> Image.Image:
    """Multiply by a Night tint (about 40%) and snap back onto the palette; `keep` stays lit."""
    out = img.copy()
    src, dst = img.load(), out.load()
    cache: dict = {}
    for y in range(img.height):
        for x in range(img.width):
            if (x, y) in keep:
                continue
            c = src[x, y]
            if c not in cache:
                cache[c] = nearest(tuple(int(v * t) for v, t in zip(c, tint)))
            dst[x, y] = cache[c]
    return out


def arch(x0: int, x1: int, y0: int, y1: int) -> set:
    cx, r = (x0 + x1) / 2, (x1 - x0) / 2
    spring = y0 + r
    return {
        (x, y)
        for x in range(x0, x1 + 1)
        for y in range(y0, y1 + 1)
        if y >= spring or (x - cx) ** 2 + (y - spring) ** 2 <= r * r
    }


DOOR_V = arch(89, 149, 9, 77)  # Valhalla, ember
DOOR_H = arch(196, 256, 9, 77)  # Hel, bile
GLOWING_DOORS = DOOR_V | DOOR_H
HUD_BOX = {(x, y) for x in range(383, 480) for y in range(0, 24)}


def load(name: str) -> Image.Image:
    return Image.open(SHOTS / name).convert("RGB")


# --------------------------------------------------------------------------- content

ULF_CLAIM = ["Speared, in battle.", "Took it in the chest.", "Sword up to the end.", "Sif gets the goat."]
# The witness sheet borrows Bersi's lines from Freydis's encounter: Ulf has no witness on day 1.
BERSI = ["She went over first.", "One hid by the mast.", "Got her from behind."]
DECREES = [
    ("I", "Valhalla takes only those slain by a weapon in battle. Death by sickness, age or accident goes to Hel."),
    ("II", "Whoever lies to the Gate goes to Hel, whatever else the Law says."),
    ("III", "Even so, a warrior without a weapon in hand goes to Hel."),
]
CAPTION_A = '"Speared, in battle" against decree I: the saga is true. I sends him to Valhalla.'
ENDING_TITLE = "Hel's tide"
ENDING_OUTCOME = (
    "The worthy you damned march with Hel. At the first horn they break the line: "
    "Asa, Hakon, Hakon (returned)."
)
ENDING_AFTER = "Broken. Ragna went to Fólkvangr."
# (soul, stamped, truth, mark)
SOULS = [
    ("Ulf", "Valhalla", "Valhalla", "tick"),
    ("Kolbeinn", "Valhalla", "Hel", "feather"),
    ("Hallr", "Hel", "Hel", "tick"),
    ("Asa", "Hel", "Valhalla", "feather"),
    ("Sigvaldi", "Valhalla", "Valhalla", "tick"),
    ("Hakon", "Hel", "Valhalla", "feather"),
    ("Grim", "Hel", "Hel", "tick"),
    ("Brand", "Hel", "Hel", "tick"),
    ("Freydis", "Valhalla", "Valhalla", "tick"),
    ("Hakon (returned)", "Hel", "Valhalla", "frost"),
    ("Ragna", "Fólkvangr", "Fólkvangr", "tick"),
    ("Ketil", "Hel", "Hel", "tick"),
]
DUSK1_CARD1 = ["No citations today."]
DUSK1_CARD2 = [
    "Odin wanted 1. Valhalla took 2. +2 feathers.",
    "Feathers: 10 at dawn, 12 now.",
    "Quota: +2.",
    "Rank: Chooser of the Slain.",
]


def law_text(img, num_right: int, x_text: int, x_max: int, y: int, ink, num_ink) -> tuple[list, list, int]:
    """Decrees with hanging roman numerals. Returns first-line tops, last-line ends, next y."""
    tops, ends = [], []
    for num, s in DECREES:
        text(img, num_right - tw(num), y, num, num_ink)
        tops.append(y)
        lines = wrap(s, x_max - x_text)
        for line in lines:
            text(img, x_text, y, line, ink)
            y += 10
        ends.append((x_text + tw(lines[-1]), y - 10))
        y += 3
    return tops, ends, y


def soul_table(img, x: int, y: int, rows: list, head_ink=W3, ink=W0, rule=P0, width: int = 0) -> int:
    name_w = max(tw(r[0]) for r in SOULS)
    realm_w = max(tw(r[1]) for r in SOULS)
    cx_name, cx_st = x + 9, x + 9 + name_w + 5
    cx_tr = cx_st + realm_w + 5
    text(img, cx_name, y, "Soul", head_ink)
    text(img, cx_st, y, "Stamped", head_ink)
    text(img, cx_tr, y, "Truth", head_ink)
    R(img, x + 1, y + 9, cx_tr + realm_w, y + 9, rule)
    y += 12
    for (name, st, tr, kind) in rows:
        mark(img, x + 1, y + 1, kind)
        text(img, cx_name, y, name, ink)
        text(img, cx_st, y, st, ink)
        text(img, cx_tr, y, tr, ink)
        y += 10
    return y


# --------------------------------------------------------------------------- S1: the desk


def s1_base() -> tuple[Image.Image, Image.Image]:
    img = load("05_law_thread.png")
    wood = img.crop((134, 157, 271, 245))
    img.paste(img.crop((382, 25, 480, 49)), (382, 0))  # stone over the old HUD box
    return img, wood


def stamp_prop() -> Image.Image:
    src = Image.open(ROOT / "docs/art/frames/stamp.png").convert("RGBA").crop((2, 0, 16, 22))
    return src.resize((10, 16), Image.NEAREST)


def paste_prop(img, prop: Image.Image, x: int, y: int) -> None:
    px = prop.load()
    for j in range(prop.height):
        for i in range(prop.width):
            r, g, b, a = px[i, j]
            if a >= 128:
                P(img, x + i, y + j, nearest((r, g, b)))


def writ(img, paper: bool = True) -> None:
    x0, y0, x1, y1 = 196, 80, 266, 95
    if paper:
        paint_paper(img, deckled_mask(x0, y0, x1, y1, 21), shadow=N0)
        R(img, x0 + 4, y0 + 13, x1 - 4, y0 + 13, P0)
        text(img, (x0 + x1) // 2 - tw("Ulf") // 2, y0 + 4, "Ulf", W0)
    else:
        paint_slab(img, rect_mask(x0, y0, x1, y1, cut=2), inset=2, shadow=N0)
        text(img, (x0 + x1) // 2 - tw("Ulf") // 2, y0 + 5, "Ulf", P2)
    paste_prop(img, stamp_prop(), x1 + 5, 80)


def s1_a() -> Image.Image:
    img, wood = s1_base()
    for box in ((132, 97, 273, 205), (272, 97, 479, 245), (132, 244, 479, 269), (68, 201, 133, 269)):
        fill_tile(img, *box, wood)

    # claim: Ulf's saga sheet
    paint_paper(img, deckled_mask(134, 100, 270, 155, 1))
    text(img, 141, 102, "Ulf", W3)
    R(img, 139, 111, 262, 111, P0)
    q = tw('"')
    for i, line in enumerate(ULF_CLAIM):
        text(img, 141 - q, 114 + 10 * i, '"', W2)
        text(img, 141, 114 + 10 * i, line, W0)
    pin_a = (141 + tw(ULF_CLAIM[0]) + 4, 117)

    # witness sheet
    paint_paper(img, deckled_mask(134, 157, 270, 201, 2))
    text(img, 141, 159, "Bersi, a crewman", W3)
    R(img, 139, 168, 262, 168, P0)
    for i, line in enumerate(BERSI):
        text(img, 141 - q, 171 + 10 * i, '"', W2)
        text(img, 141, 171 + 10 * i, line, W0)

    # the Law as a scroll with knotwork rods
    scroll = deckled_mask(278, 104, 474, 239, 3, "lr")
    paint_paper(img, scroll)
    for y in range(106, 238):
        for x, col in ((280, P1), (472, P1)):
            if (x, y) in scroll:
                P(img, x, y, col)
    text(img, 376 - tw("Odin's Law") // 2, 111, "Odin's Law", W3)
    R(img, 300, 120, 452, 120, P0)
    for x in (298, 454):
        bitmap(img, x - 1, 119, [".#.", "###", ".#."], {"#": W3})
    tops, ends, _ = law_text(img, 299, 303, 471, 124, W0, W3)
    pin_b = (285, tops[0] + 3)
    ex, ey = ends[2]
    seal(img, min(ex + 6, 469), ey + 3, 2)
    rod(img, 274, 478, 100)
    rod(img, 274, 478, 237)
    R(img, 279, 108, 473, 108, P0)

    thread(img, pin_a, pin_b, 6)
    pin(img, *pin_a)
    pin(img, *pin_b)

    # caption: the bottom edge of an open ledger page
    page = deckled_mask(134, 246, 478, 274, 4, "t", deep=0.0)
    page -= {(134, 246), (134, 247), (135, 246), (478, 246), (478, 247), (477, 246)}
    paint_paper(img, page)
    R(img, 145, 247, 145, 269, P0)
    R(img, 136, 258, 476, 258, P0)
    pin_icon(img, 138, 250)
    for i, line in enumerate(wrap(CAPTION_A, 476 - 149)):
        text(img, 149, 249 + 10 * i, line, W0)

    # the mentor's remark as a scrap of paper
    paint_paper(img, deckled_mask(72, 204, 130, 242, 5))
    for i, line in enumerate(["The Law", "agrees.", "Stamp him."]):
        text(img, 76, 208 + 10 * i, line, W0)

    hud_objects(img)
    writ(img)
    return img


def rod(img, x0: int, x1: int, y0: int) -> None:
    """A wooden scroll rod with knotwork and turned knobs, 8 px tall."""
    for j, col in enumerate((W0, W2, W4, W3, W3, W2, W1, W0)):
        R(img, x0 + 5, y0 + j, x1 - 5, y0 + j, col)
    tri = [0, 1, 2, 3, 3, 2, 1, 0]
    for x in range(x0 + 8, x1 - 7):
        a = tri[(x - x0) % 8]
        over = ((x - x0 + 4) // 8) % 2 == 0
        first, second = ((y0 + 5 - a, W1), (y0 + 2 + a, W4)) if over else ((y0 + 2 + a, W4), (y0 + 5 - a, W1))
        P(img, x, first[0], first[1])
        P(img, x, second[0], second[1])
    for kx in (x0, x1 - 4):
        knob = rect_mask(kx, y0, kx + 4, y0 + 7, cut=2)
        inner = erode(knob)
        for (x, y) in knob:
            P(img, x, y, W0 if (x, y) not in inner else (W4 if y <= y0 + 2 else W3))
        gx = kx + 5 if kx == x0 else kx - 1
        R(img, gx, y0 + 1, gx, y0 + 6, W0)


def hud_objects(img) -> None:
    """The HUD as objects on the stone: candle (time), quill (feathers), slate (quota), book."""
    candle(img, 387, 7, 13)
    text(img, 396, 5, "untimed", P2)
    bitmap(
        img,
        438,
        3,
        ["......a", ".....aa", "....aab", "...aab.", "..aab..", ".aab...", ".w.....", "w......"],
        {"a": P1, "b": P0, "w": W3},
    )
    text(img, 447, 5, "10", P2)
    slate = rect_mask(395, 13, 419, 23, cut=1)
    for (x, y) in slate:
        edge = x in (395, 419) or y in (13, 23)
        P(img, x, y, W2 if edge else N1)
    R(img, 396, 13, 418, 13, W3)
    text(img, 399, 15, "0/1", F2)
    R(img, 414, 15, 414, 21, F0)  # an empty tally slot
    bitmap(
        img,
        466,
        13,
        ["wwwwwwww.", "wcccccccp", "wcccccccp", "wcccccccp", "wcccccccp", "wcccccccp", "wwwwwwww."],
        {"w": W0, "c": W2, "p": P1},
    )


def s1_b() -> Image.Image:
    img, wood = s1_base()
    for box in ((132, 97, 273, 205), (272, 97, 479, 245), (132, 244, 479, 269), (68, 201, 133, 269)):
        fill_tile(img, *box, wood)

    paint_slab(img, rect_mask(134, 100, 270, 155, cut=3), inset=2)
    text(img, 143, 104, "Ulf", F2)
    for x in range(140, 265, 3):
        P(img, x, 112, F1)
    q = tw('"')
    for i, line in enumerate(ULF_CLAIM):
        text(img, 143 - q, 114 + 10 * i, '"', F1)
        text(img, 143, 114 + 10 * i, line, P2)
    pin_a = (143 + tw(ULF_CLAIM[0]) + 4, 117)

    paint_slab(img, rect_mask(134, 157, 270, 202, cut=3), inset=2)
    text(img, 143, 161, "Bersi, a crewman", F2)
    for x in range(140, 265, 3):
        P(img, x, 169, F1)
    for i, line in enumerate(BERSI):
        text(img, 143 - q, 171 + 10 * i, '"', F1)
        text(img, 143, 171 + 10 * i, line, P2)

    # the Law as a standing rune stone with a rounded top
    x0, y0, x1, y1, rr = 274, 100, 478, 244, 26

    def inside(x: int, y: int) -> bool:
        for cx in (x0 + rr, x1 - rr):
            if (x < cx if cx == x0 + rr else x > cx) and y < y0 + rr:
                return (x - cx) ** 2 + (y - (y0 + rr)) ** 2 <= rr * rr
        return min(x - x0, x1 - x) + min(y - y0, y1 - y) >= 3 or y - y0 < 10

    stone = {(x, y) for x in range(x0, x1 + 1) for y in range(y0, y1 + 1) if inside(x, y)}
    paint_slab(img, stone, inset=4)
    text(img, 376 - tw("Odin's Law") // 2, 108, "Odin's Law", F2)
    runes = ["#.#", "##.", "#.#"], [".#.", "###", ".#."], ["#..", "##.", "#.#"]
    x = 312
    while x < 440:
        bitmap(img, x, 117, runes[(x // 8) % 3], {"#": F1})
        x += 8
    tops, ends, _ = law_text(img, 299, 303, 468, 125, P2, F2)
    pin_b = (285, tops[0] + 3)
    ex, ey = ends[2]
    seal(img, min(ex + 6, 466), ey + 3, 2, shadow=N0)

    thread(img, pin_a, pin_b, 6, shadow=N0)
    pin(img, *pin_a)
    pin(img, *pin_b)

    # caption as a framed slate with chalk
    sl = rect_mask(134, 246, 478, 268, cut=1)
    for (x, y) in sl:
        edge = x - 134 < 2 or 478 - x < 2 or y - 246 < 2 or 268 - y < 2
        P(img, x, y, (W3 if y == 246 else W2) if edge else N1)
    R(img, 134, 268, 478, 268, W0)
    pin_icon(img, 138, 250)
    for i, line in enumerate(wrap(CAPTION_A, 474 - 147)):
        text(img, 147, 249 + 10 * i, line, F2)

    # mentor's remark chalked on a little slate
    ms = rect_mask(70, 203, 131, 242, cut=1)
    for (x, y) in ms:
        edge = x - 70 < 2 or 131 - x < 2 or y - 203 < 2 or 242 - y < 2
        P(img, x, y, W2 if edge else N1)
    for i, line in enumerate(["The Law", "agrees.", "Stamp him."]):
        text(img, 75, 208 + 10 * i, line, F2)

    # HUD carved into the stone
    bitmap(img, 387, 4, ["#####", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#####"], {"#": N0})
    bitmap(img, 388, 5, ["#####", "#...#", ".#.#.", "..#..", ".#.#.", "#...#", "#####"], {"#": F2})
    carved(img, 395, 5, "untimed")
    bitmap(img, 437, 4, ["....#", "...##", "..###", ".###.", ".##..", "#....", "#...."], {"#": N0})
    bitmap(img, 438, 5, ["....#", "...##", "..###", ".###.", ".##..", "#....", "#...."], {"#": F2})
    carved(img, 445, 5, "10")
    for k in range(1):
        R(img, 387 + 3 * k, 14, 387 + 3 * k, 21, N0)
        R(img, 388 + 3 * k, 15, 388 + 3 * k, 22, F2)
    R(img, 391, 15, 391, 22, N3)  # the slot still to carve
    carved(img, 396, 15, "0/1")
    bitmap(img, 466, 14, ["######", "#....#", "#.##.#", "#....#", "#.##.#", "#....#", "######"], {"#": N0})
    bitmap(img, 467, 15, ["######", "#....#", "#.##.#", "#....#", "#.##.#", "#....#", "######"], {"#": F2})

    writ(img, paper=False)
    return img


SPEAR = [
    ".......#.......",
    "......###......",
    "......###......",
    ".....#####.....",
    "......###......",
    ".......#.......",
    ".......#.......",
    "......###......",
    ".......#.......",
    ".......#.......",
    ".......#.......",
    "......#.#......",
]
SERPENT = [
    "......#####....",
    ".....##...##...",
    ".....##........",
    "......###......",
    "........###....",
    "..........##...",
    "..##......##...",
    "...###...##....",
    ".....#####.....",
    "...............",
    "....##.........",
    "...#.#.........",
]
BOAR = [
    "...............",
    "...............",
    "..#.........##.",
    ".##########.#..",
    "##############.",
    "###############",
    ".#############.",
    ".############..",
    "..##.....##....",
    "..##.....##....",
    "...............",
    "...............",
]


def s1_c() -> Image.Image:
    img, wood = s1_base()
    img.paste(load("05_law_thread.png").crop((382, 0, 480, 25)), (382, 0))  # this option keeps the HUD
    for box in ((132, 97, 273, 212), (272, 97, 479, 245), (132, 210, 479, 269)):
        fill_tile(img, *box, wood)

    # claim slip (a typed form); the witness slip is stacked over it, offset
    claim = rect_mask(132, 99, 267, 162, cut=1)
    paint_paper(img, claim, depth=2)
    R(img, 133, 100, 266, 109, P0)
    text(img, 136, 101, "CLAIM", W1)
    text(img, 264 - tw("Ulf"), 101, "Ulf", W0)
    for i, line in enumerate(ULF_CLAIM):
        text(img, 136, 113 + 10 * i, f"C{i + 1} {line}", W0)
    pin_a = (136 + tw("C1 " + ULF_CLAIM[0]) + 4, 116)
    tab = rect_mask(444, 86, 468, 99, cut=1)  # the rulebook's tab
    paint_paper(img, tab, body=P1, edge=W1, band=P1, shadow=None)
    text(img, 456 - tw("LAW") // 2, 88, "LAW", W1)
    book_left = (276, 100)
    pin_b = (book_left[0] + 3, 120)
    pts = thread_path(pin_a, pin_b, 5)
    knot = min(pts, key=lambda p: abs(p[0] - 269))
    R(img, knot[0], knot[1] + 3, knot[0], 217, P0)  # the caption's tie, passing under the witness slip

    wit = rect_mask(138, 156, 292, 206, cut=1)
    paint_paper(img, wit, depth=2)
    R(img, 139, 157, 291, 166, P0)
    text(img, 142, 158, "WITNESS Bersi", W1)
    for i, line in enumerate(BERSI):
        text(img, 142, 170 + 10 * i, f"W{i + 1} {line}", W0)

    # the rulebook, open over the slips (it hides the witness slip's right edge)
    left, right = open_book(img, 272, 97, 479, 214, 7)
    lx0, ly0, lx1, _ = left
    text(img, lx0 + 4, ly0 + 3, "Odin's Law", W3)
    R(img, lx0 + 3, ly0 + 12, lx1 - 3, ly0 + 12, P0)
    for k, (num, s_) in enumerate(DECREES):
        page = left if k == 0 else right
        if k == 0:
            y = ly0 + 17
            pin_b = (page[0] + 3, y + 3)
        elif k == 1:
            y = right[1] + 4
        for line in wrap(f"L{k + 1} {s_}", page[2] - page[0] - 12):
            text(img, page[0] + 8, y, line, W0)
            y += 10
        y += 3
    text(img, right[2] - 4 - tw("3"), right[3] - 11, "3", W3)

    thread(img, pin_a, pin_b, 5)
    pin(img, *pin_a)
    pin(img, *pin_b)

    # the caption as a slip tied to the thread
    slip = rect_mask(140, 218, 330, 243, cut=1)
    paint_paper(img, slip, depth=2)
    pin(img, knot[0], 220)
    for i, line in enumerate(wrap("C1 against L1: the saga is true. L1 sends him to Valhalla.", 180)):
        text(img, 146, 224 + 10 * i, line, W0)

    # stamp tray: one stamp per realm instead of clicking a door
    tray = rect_mask(336, 218, 479, 269, cut=1)
    for (x, y) in tray:
        edge = x - 336 < 2 or 479 - x < 2 or y - 218 < 2
        P(img, x, y, (W3 if y == 218 else W2) if edge else W0)
    for k, (glyph, name) in enumerate(((SPEAR, "Valhalla"), (SERPENT, "Hel"), (BOAR, "Fólkvangr"))):
        cx = 358 + 45 * k
        face = rect_mask(cx - 14, 222, cx + 14, 247, cut=1)
        drop_shadow(img, face, N0)
        inner = erode(face)
        for (x, y) in face:
            P(img, x, y, W3 if (x, y) not in inner else N2)
        R(img, cx - 13, 223, cx + 13, 223, W4)
        bitmap(img, cx - 7, 229, glyph, {"#": P2})
        text(img, cx - tw(name) // 2, 254, name, P1)
    return img


# --------------------------------------------------------------------------- S2: between days


def s2_a_dusk() -> Image.Image:
    img = dim(load("16_dusk1_card1.png"), GLOWING_DOORS | HUD_BOX)
    left, right = open_book(img, 78, 64, 402, 238, 11)
    lx0, ly0, lx1, _ = left
    text(img, lx0 + 6, ly0 + 6, "Dusk, day 1", W3)
    underline_wavy(img, lx0 + 5, lx0 + 7 + tw("Dusk, day 1"), ly0 + 15, W3, 3)
    y = ly0 + 21
    for line in DUSK1_CARD1:
        text(img, lx0 + 6, y, line, W0)
        y += 10
    y += 6
    for para in DUSK1_CARD2:
        for line in wrap(para, lx1 - lx0 - 12):
            text(img, lx0 + 6, y, line, W0)
            y += 10
    rx0, ry0, rx1, ry1 = right
    for ry in range(ry0 + 17, ry1 - 14, 10):
        R(img, rx0 + 6, ry, rx1 - 6, ry, P1)
    dog_ear(img, rx1, ry1, 11)
    text(img, rx1 - 14 - tw("turn"), ry1 - 9, "turn", W3)
    ribbon(img, 352, 54, 72, "top")
    text(img, 360, 56, "Skip all", P2)
    candle(img, 44, 232, 14)
    return img


def s2_a_dawn() -> Image.Image:
    img = dim(load("20_dawn2.png"), GLOWING_DOORS | HUD_BOX)
    left, right = open_book(img, 78, 64, 402, 238, 13)
    lx0, ly0, lx1, _ = left
    text(img, lx0 + 6, ly0 + 6, "Day 2", W3)
    underline_wavy(img, lx0 + 5, lx0 + 7 + tw("Day 2"), ly0 + 15, W3, 5)
    y = ly0 + 21
    for para in (
        "Odin wants 1 soul for Valhalla.",
        "The clock: 5:00. It runs while a soul is at the desk.",
        "Witnesses arrive. Claim against witness makes a grey thread.",
    ):
        for line in wrap(para, lx1 - lx0 - 12):
            text(img, lx0 + 6, y, line, W0)
            y += 10
        y += 4
    rx0, ry0, rx1, ry1 = right
    text(img, rx0 + 6, ry0 + 6, "New decree", W3)
    underline_wavy(img, rx0 + 5, rx0 + 7 + tw("New decree"), ry0 + 15, W3, 6)
    y = ry0 + 21
    text(img, rx0 + 20 - tw("IV"), y, "IV", W3)
    lines = wrap("Even so, those who fled the battle go to Hel.", rx1 - rx0 - 30)
    for line in lines:
        text(img, rx0 + 24, y, line, W0)
        y += 10
    seal(img, rx0 + 24 + tw(lines[-1]) + 6, y - 7, 2)
    y += 6
    for line in wrap("Citations begin today: 2 feathers for any stamp against what the desk can show you.", rx1 - rx0 - 12):
        text(img, rx0 + 6, y, line, W0)
        y += 10
    dog_ear(img, rx1, ry1, 11)
    text(img, rx1 - 14 - tw("begin"), ry1 - 9, "begin", W3)
    candle(img, 44, 232, 14)
    return img


def ending_left_page(img, page, y_title_gap: int = 6) -> None:
    x0, y0, x1, _ = page
    text(img, x0 + 6, y0 + y_title_gap, ENDING_TITLE, W3)
    underline_wavy(img, x0 + 5, x0 + 7 + tw(ENDING_TITLE), y0 + y_title_gap + 9, W3, 9)
    y = y0 + y_title_gap + 15
    for line in wrap(ENDING_OUTCOME, x1 - x0 - 12):
        text(img, x0 + 6, y, line, W0)
        y += 10
    y += 4
    text(img, x0 + 6, y, ENDING_AFTER, W0)


def standing(img, x: int, y: int) -> None:
    seal(img, x + 4, y + 3, 4, mark=True)
    text(img, x + 13, y, "13 feathers", W0)
    text(img, x + 13, y + 10, "Chooser of the Slain", W3)


def s2_a_ending() -> Image.Image:
    base = lit_empty_desk("30_dusk3_card5.png")
    R(base, 137, 248, 475, 266, base.getpixel((300, 266)))  # no caption under the ending
    img = dim(base, GLOWING_DOORS | HUD_BOX)
    left, right = open_book(img, 14, 88, 466, 248, 17)
    ending_left_page(img, left)
    standing(img, left[0] + 6, left[3] - 26)
    soul_table(img, right[0] + 4, right[1] + 6, SOULS)
    ribbon(img, 420, 240, 266, "bottom")
    text(img, 415 - tw("Play again"), 257, "Play again", P2)
    candle(img, 4, 254, 12)
    return img


def dark_with_doors(src: Image.Image) -> Image.Image:
    img = Image.new("RGB", (480, 270), N0)
    sp, dp = src.load(), img.load()
    for (x, y) in GLOWING_DOORS:
        dp[x, y] = sp[x, y]
    return img


def underlined(img, x: int, y: int, s: str) -> None:
    text(img, x, y, s, F2)
    R(img, x, y + 9, x + tw(s) - 1, y + 9, F1)


def s2_b_dusk() -> Image.Image:
    img = dark_with_doors(load("16_dusk1_card1.png"))
    title = "Dusk, day 1"
    text(img, 240 - tw(title), 112, title, P2, scale=2)
    y = 140
    for line in DUSK1_CARD2:
        text(img, 240 - tw(line) // 2, y, line, P2)
        y += 10
    underlined(img, 12, 255, "Skip all")
    underlined(img, 468 - tw("Next"), 255, "Next")
    return img


def s2_b_ending() -> Image.Image:
    img = dark_with_doors(load("16_dusk1_card1.png"))
    text(img, 240 - tw(ENDING_TITLE), 82, ENDING_TITLE, P2, scale=2)
    y = 104
    for line in wrap(ENDING_OUTCOME, 400) + [ENDING_AFTER]:
        text(img, 240 - tw(line) // 2, y, line, P2)
        y += 10
    # the names, carved one per block in the stone wall
    bw, bh, gx, gy = 146, 26, 4, 2
    x_start, y_start = 240 - (3 * bw + 2 * gx) // 2, 135
    for k, (name, st, tr, kind) in enumerate(SOULS):
        col, row = k // 4, k % 4
        bx, by = x_start + col * (bw + gx), y_start + row * (bh + gy)
        paint_slab(img, rect_mask(bx, by, bx + bw - 1, by + bh - 1, cut=2), inset=2, shadow=None)
        glyph = {"tick": TICK, "feather": FEATHER5, "frost": FROST}[kind]
        bitmap(img, bx + 5, by + 5, glyph, {"#": N0})
        bitmap(img, bx + 6, by + 6, glyph, {"#": F2})
        carved(img, bx + 14, by + 5, name)
        realm = st if st == tr else f"{st}; truth {tr}"
        carved(img, bx + 14, by + 15, realm)
    text(img, 240 - tw("Feathers: 13. Rank: Chooser of the Slain.") // 2, 249, "Feathers: 13. Rank: Chooser of the Slain.", P2)
    underlined(img, 468 - tw("Play again"), 259, "Play again")
    return img


def lit_empty_desk(hud_from: str) -> Image.Image:
    """The desk after the last soul: dusk gate band, no soul, empty claim, a clean Law."""
    img = load("16_dusk1_card1.png")
    ulf = load("02_ulf.png")
    img.paste(img.crop((20, 97, 72, 203)), (80, 97))  # the empty chart behind the old card
    img.paste(ulf.crop((128, 97, 134, 203)), (128, 97))  # the chart's right border
    img.paste(ulf.crop((132, 97, 480, 246)), (132, 97))  # claim panel, desk wood, clean Law
    img.paste(load(hud_from).crop((383, 0, 480, 22)), (383, 0))
    inner = img.getpixel((200, 104))
    R(img, 136, 101, 268, 152, inner)
    return img


def s2_c_dusk() -> Image.Image:
    img = lit_empty_desk("16_dusk1_card1.png")
    bg = img.getpixel((300, 266))
    R(img, 137, 248, 475, 266, bg)

    # a black feather lying on the ledger line, with its citation
    feather = [
        "..................##",
        "............#######.",
        "......############..",
        "..#############.....",
        "##############......",
        ".....######.........",
    ]
    fpts = {(139 + i, 250 + j) for j, r in enumerate(feather) for i, ch in enumerate(r) if ch == "#"}
    for (x, y) in fpts:
        for nx, ny in ((x + 1, y), (x - 1, y), (x, y + 1), (x, y - 1)):
            if (nx, ny) not in fpts:
                P(img, nx, ny, F1)
    for (x, y) in fpts:
        P(img, x, y, N0)
    text(img, 164, 249, "Citation: Kolbeinn, stamped against decree I.", P2)
    text(img, 164, 259, "Two feathers off.", P2)

    # the quota on a slate: tallies and a chalked +2
    sl = rect_mask(150, 200, 214, 236, cut=1)
    drop_shadow(img, sl, W0)
    for (x, y) in sl:
        edge = x - 150 < 2 or 214 - x < 2 or y - 200 < 2 or 236 - y < 2
        P(img, x, y, (W3 if y == 200 else W2) if edge else N1)
    text(img, 155, 204, "Odin: 1", F2)
    for k in range(2):
        R(img, 156 + 3 * k, 216, 156 + 3 * k, 226, F2)
    text(img, 166, 218, "+2", F2)

    # the recap: a torn sheet the mentor pushes over the body chart
    sheet = deckled_mask(16, 118, 154, 168, 31)
    paint_paper(img, sheet)
    text(img, 22, 121, "Kolbeinn", W3)
    R(img, 21, 130, 148, 130, P0)
    for i, line in enumerate(["Died in bed, full of mead.", "You sent him to Valhalla.", "The truth was Hel."]):
        text(img, 22, 133 + 10 * i, line, W0)
    R(img, 17, 170, 23, 203, N5)  # the mentor's sleeve
    R(img, 17, 170, 17, 203, N4)
    R(img, 23, 170, 23, 203, N3)
    bitmap(img, 18, 164, [".###.", "#####", "#####", ".###."], {"#": W2})
    R(img, 19, 164, 21, 164, W3)

    # Hel's offer: a folded letter with a bile seal
    letter = rect_mask(298, 190, 456, 240, cut=1)
    paint_paper(img, letter, body=P1, band=P0)
    R(img, 299, 215, 455, 215, P0)
    for i, line in enumerate(["Tomorrow Ragna comes to", "your desk. Send her to me", "and I pay four feathers.", "Hel"]):
        text(img, 306, 194 + 10 * i + (2 if i >= 2 else 0), line, W0)
    seal(img, 444, 229, 4, ramp=(B0, B1, B2))
    return img


def s2_c_ending() -> Image.Image:
    img = lit_empty_desk("30_dusk3_card5.png")
    bg = img.getpixel((300, 266))
    R(img, 137, 248, 475, 266, bg)
    R(img, 276, 101, 476, 242, img.getpixel((470, 238)))  # the ledger hides the Law
    left, right = open_book(img, 20, 98, 460, 250, 23)
    ending_left_page(img, left, 4)
    soul_table(img, left[0] + 4, left[1] + 66, SOULS[:6])
    soul_table(img, right[0] + 4, right[1] + 4, SOULS[6:])
    standing(img, right[0] + 6, right[1] + 92)
    ribbon(img, 432, 246, 266, "bottom")
    text(img, 427 - tw("Play again"), 258, "Play again", P2)
    return img


# --------------------------------------------------------------------------- output


def check(img: Image.Image, name: str) -> None:
    off = [c for _, c in img.getcolors(1 << 20) if c not in PAL_SET]
    if off:
        raise SystemExit(f"{name}: {len(off)} colours outside the palette, e.g. {off[:4]}")


def labelled(img: Image.Image, scale: int, label: str) -> Image.Image:
    big = img.resize((img.width * scale, img.height * scale), Image.NEAREST)
    out = Image.new("RGB", (big.width, big.height + 12), N0)
    out.paste(big, (0, 0))
    text(out, 4, big.height + 2, label, P2)
    return out


def main() -> None:
    jobs = [
        ("S1-A", s1_a, "S1-A  Parchment and ink"),
        ("S1-B", s1_b, "S1-B  Carved stone"),
        ("S1-C", s1_c, "S1-C  Papers, Please literal"),
        ("S2-A-dusk", s2_a_dusk, "S2-A  The clerk's ledger: dusk"),
        ("S2-A-ending", s2_a_ending, "S2-A  The clerk's ledger: ending"),
        ("S2-A-dawn", s2_a_dawn, "S2-A  The clerk's ledger: dawn"),
        ("S2-B-dusk", s2_b_dusk, "S2-B  Title cards: dusk"),
        ("S2-B-ending", s2_b_ending, "S2-B  Title cards: ending"),
        ("S2-C-dusk", s2_c_dusk, "S2-C  On the desk, as objects: dusk (Hel's letter keeps a bile seal: allowed? open question)"),
        ("S2-C-ending", s2_c_ending, "S2-C  On the desk, as objects: ending"),
    ]
    made: dict[str, Image.Image] = {}
    labels: dict[str, str] = {}
    for name, fn, label in jobs:
        img = fn()
        check(img, name)
        img.save(OUT / f"{name}.png")
        x3 = labelled(img, 3, label)
        check(x3, name + "-x3")
        x3.save(OUT / f"{name}-x3.png")
        made[name], labels[name] = img, label
        print("wrote", name)

    gap = 4
    s1 = [labelled(made[n], 3, labels[n]) for n in ("S1-A", "S1-B", "S1-C")]
    sheet = Image.new("RGB", (s1[0].width, sum(i.height for i in s1) + gap * 2), N0)
    y = 0
    for im in s1:
        sheet.paste(im, (0, y))
        y += im.height + gap
    sheet.save(OUT / "S1-compare-x3.png")

    pairs = [("S2-A-dusk", "S2-A-ending"), ("S2-B-dusk", "S2-B-ending"), ("S2-C-dusk", "S2-C-ending")]
    cells = [[labelled(made[n], 2, labels[n]) for n in p] for p in pairs]
    cw, ch = cells[0][0].size
    sheet = Image.new("RGB", (cw * 2 + gap, ch * 3 + gap * 2), N0)
    for r, row in enumerate(cells):
        for c, im in enumerate(row):
            sheet.paste(im, (c * (cw + gap), r * (ch + gap)))
    sheet.save(OUT / "S2-compare-x3.png")
    print("wrote contact sheets")


if __name__ == "__main__":
    main()
