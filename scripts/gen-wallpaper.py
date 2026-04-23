#!/usr/bin/env python3
"""Generate a subtle two-color vertical gradient wallpaper (3840x2160) with
light noise to avoid banding. Defaults are gruvbox-dark; other themes pass
their own colors so the wallpaper complements the conky panel.

Usage:
    gen-wallpaper.py [OUT]                       # gruvbox dark defaults
    gen-wallpaper.py --top HEX --bottom HEX [OUT]
    gen-wallpaper.py OUT --top HEX --bottom HEX
"""

from PIL import Image
from pathlib import Path
import argparse
import random


def parse_hex(s: str) -> tuple[int, int, int]:
    s = s.lstrip("#")
    if len(s) != 6:
        raise argparse.ArgumentTypeError(f"expected 6-digit hex, got {s!r}")
    return (int(s[0:2], 16), int(s[2:4], 16), int(s[4:6], 16))


p = argparse.ArgumentParser()
p.add_argument("out", nargs="?",
               default=str(Path.home() / "Pictures/Wallpapers/gruvbox_dark_minimal.png"))
p.add_argument("--top",    type=parse_hex, default=(0x32, 0x30, 0x2f))
p.add_argument("--bottom", type=parse_hex, default=(0x1d, 0x20, 0x21))
p.add_argument("--size",   default="3840x2160")
p.add_argument("--seed",   type=int, default=42)
args = p.parse_args()

W, H = (int(x) for x in args.size.split("x"))
out = Path(args.out)
out.parent.mkdir(parents=True, exist_ok=True)

img = Image.new("RGB", (W, H))
px = img.load()
tr, tg, tb = args.top
br, bg, bb = args.bottom
for y in range(H):
    t = y / (H - 1)
    r = int(tr + (br - tr) * t)
    g = int(tg + (bg - tg) * t)
    b = int(tb + (bb - tb) * t)
    for x in range(W):
        px[x, y] = (r, g, b)

rng = random.Random(args.seed)
for y in range(0, H, 2):
    for x in range(0, W, 2):
        r, g, b = px[x, y]
        n = rng.randint(-2, 2)
        px[x, y] = (max(0, min(255, r + n)),
                    max(0, min(255, g + n)),
                    max(0, min(255, b + n)))

img.save(out, optimize=True)
print(out)
