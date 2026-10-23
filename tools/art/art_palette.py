"""The project palette (docs/art/palette.gpl) for the art scripts in tools/art/.

Every script here writes only palette colours, so each loads the palette from the one file the
lint reads and checks its own output against it before saving.
"""

from __future__ import annotations

from pathlib import Path

from PIL import Image

ROOT = Path(__file__).resolve().parents[2]
PALETTE_FILE = ROOT / "docs" / "art" / "palette.gpl"
ART = ROOT / "assets" / "art"

Rgb = tuple[int, int, int]


def load_palette(path: Path = PALETTE_FILE) -> dict[str, Rgb]:
    """The palette's colours by name ("Night 0", "Fog 2", ...), in file order."""
    colours: dict[str, Rgb] = {}
    for line in path.read_text(encoding="utf-8").splitlines():
        parts = line.split()
        if len(parts) >= 4 and all(part.isdigit() for part in parts[:3]):
            colours[" ".join(parts[3:])] = (int(parts[0]), int(parts[1]), int(parts[2]))
    return colours


PALETTE = load_palette()


def ramp(name: str) -> list[Rgb]:
    """A ramp's colours from darkest to lightest: "Night" gives Night 0 .. Night 5."""
    found = [(int(key.split()[-1]), rgb) for key, rgb in PALETTE.items()
             if key.startswith(name + " ") and key.split()[-1].isdigit()]
    return [rgb for _, rgb in sorted(found)]


def off_palette(image: Image.Image) -> list[tuple[int, int, Rgb]]:
    """Every opaque pixel whose colour is not in the palette (empty when the image is clean)."""
    allowed = set(PALETTE.values())
    rgba = image.convert("RGBA")
    bad = []
    for y in range(rgba.height):
        for x in range(rgba.width):
            red, green, blue, alpha = rgba.getpixel((x, y))
            if alpha and (red, green, blue) not in allowed:
                bad.append((x, y, (red, green, blue)))
    return bad


def save(image: Image.Image, path: Path) -> None:
    """Saves `image` as a PNG after checking it is palette-only with hard alpha."""
    rgba = image.convert("RGBA")
    if off_palette(rgba):
        raise ValueError(f"{path}: off-palette pixels {off_palette(rgba)[:5]}")
    alphas = {rgba.getpixel((x, y))[3] for y in range(rgba.height) for x in range(rgba.width)}
    if not alphas <= {0, 255}:
        raise ValueError(f"{path}: soft alpha {sorted(alphas)}")
    path.parent.mkdir(parents=True, exist_ok=True)
    rgba.save(path, optimize=True)


def same_pixels(path: Path, image: Image.Image) -> bool:
    """True when the PNG at `path` holds exactly `image`'s pixels (the scripts' --check)."""
    if not path.exists():
        return False
    on_disk = Image.open(path).convert("RGBA")
    return on_disk.size == image.size and on_disk.tobytes() == image.convert("RGBA").tobytes()
