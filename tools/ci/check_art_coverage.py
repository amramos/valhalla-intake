"""Fail when an image under assets/art/ matches no canvas in pixelforge.toml.

pixelforge lints only the files its canvases match, so an asset in an unplanned folder would pass
CI unchecked. Adding an asset kind means adding its canvas first (ADR-0006).
Standard library only; run from the project root: python tools/ci/check_art_coverage.py
"""

from __future__ import annotations

import fnmatch
from pathlib import Path
import sys
import tomllib


def main() -> int:
    root = Path.cwd()
    config = tomllib.loads((root / "pixelforge.toml").read_text(encoding="utf-8"))
    patterns = [pattern for canvas in config.get("canvas", []) for pattern in canvas.get("paths", [])]
    uncovered = [
        path.relative_to(root).as_posix()
        for path in sorted((root / "assets" / "art").rglob("*.png"))
        if not any(fnmatch.fnmatch(path.relative_to(root).as_posix(), pattern) for pattern in patterns)
    ]
    for path in uncovered:
        print(f"no canvas in pixelforge.toml matches {path}")
    if uncovered:
        print("Add a [[canvas]] for this asset kind before adding its files (ADR-0006).")
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
