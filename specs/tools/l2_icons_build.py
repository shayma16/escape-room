#!/usr/bin/env python3
"""Build L2 z1 inventory cutouts from NB raws + canonical glyph stamps.
Deterministic: all numerals/dies come from l2_glyphs (ONE canonical source)."""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral, die_house, die_gear, die_notch_ring

SCR = r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim-escape-room\8c048282-9ce7-4b1a-b54a-04e2ba948c25\scratchpad"
RAW = os.path.join(SCR, "iconsraw")
OUT = r"C:\Users\shaim\escape-room\specs\assets\level-2\z1\icons"
GLY = r"C:\Users\shaim\escape-room\specs\assets\level-2\masters\glyphs"
os.makedirs(OUT, exist_ok=True)

MAGENTA = (255, 0, 255)


def keyed(path):
    """White-key via border flood fill -> RGBA cutout, tight bbox."""
    im = Image.open(path).convert("RGB")
    w, h = im.size
    ImageDraw.floodfill(im, (2, 2), MAGENTA, thresh=26)
    ImageDraw.floodfill(im, (w - 3, 2), MAGENTA, thresh=26)
    ImageDraw.floodfill(im, (2, h - 3), MAGENTA, thresh=26)
    ImageDraw.floodfill(im, (w - 3, h - 3), MAGENTA, thresh=26)
    a = np.array(im)
    bgmask = (a[:, :, 0] == 255) & (a[:, :, 1] == 0) & (a[:, :, 2] == 255)
    alpha = np.where(bgmask, 0, 255).astype(np.uint8)
    # soften 1px edge
    al = Image.fromarray(alpha, "L")
    from PIL import ImageFilter
    al = al.filter(ImageFilter.GaussianBlur(1.0))
    orig = Image.open(path).convert("RGBA")
    orig.putalpha(al)
    return orig.crop(orig.getbbox())


def save_icon(im, name):
    """@3x at 1024 long side + @2x/@1x."""
    s = 1024 / max(im.size)
    im3 = im.resize((round(im.width * s), round(im.height * s)), Image.LANCZOS)
    im3.save(os.path.join(OUT, f"{name}@3x.png"))
    for k, tag in ((2 / 3, "2x"), (1 / 3, "1x")):
        im3.resize((round(im3.width * k), round(im3.height * k)),
                   Image.LANCZOS).save(os.path.join(OUT, f"{name}@{tag}.png"))
    print("saved", name, im3.size)


def engrave(base, stamp, cx, cy, target_w, squeeze_x=1.0, ink=(58, 44, 26),
            hi=(238, 214, 150), ink_a=235, hi_a=110, depth=4):
    """Composite an engraved-looking glyph: light offset below-right + dark ink."""
    s = target_w / stamp.width
    w = round(stamp.width * s * squeeze_x)
    h = round(stamp.height * s)
    st = stamp.resize((w, h), Image.LANCZOS)
    a = st.split()[3]
    for col, alp, dx, dy in ((hi, hi_a, depth, depth), (ink, ink_a, 0, 0)):
        layer = Image.new("RGBA", st.size, col + (0,))
        layer.putalpha(a.point(lambda v, m=alp: v * m // 255))
        base.alpha_composite(layer, (round(cx - w / 2 + dx), round(cy - h / 2 + dy)))


def find_circle(im, test):
    """bbox center/radius of pixels passing test(r,g,b)."""
    a = np.array(im.convert("RGB"), dtype=np.int16)
    m = test(a[:, :, 0], a[:, :, 1], a[:, :, 2])
    ys, xs = np.where(m)
    return (xs.min() + xs.max()) / 2, (ys.min() + ys.max()) / 2, \
           (xs.max() - xs.min()) / 2, (ys.max() - ys.min()) / 2


def main():
    # 1) screwdriver
    save_icon(keyed(os.path.join(RAW, "icon-screwdriver-raw@3x.png")),
              "inv-screwdriver")

    # 2) tiles II IV VII XI
    tile = keyed(os.path.join(RAW, "icon-tile-blank-raw@3x.png"))
    tile.save(os.path.join(GLY, "tile-blank.png"))  # reused by door-dial rebuild
    for n in ["II", "IV", "VII", "XI"]:
        t = tile.copy()
        st = render_numeral(n, 400)
        engrave(t, st, t.width / 2, t.height / 2,
                target_w=t.width * (0.30 if len(n) < 3 else 0.42))
        save_icon(t, f"inv-tile-{n.lower()}")

    # 3) watches A/B
    watch = keyed(os.path.join(RAW, "icon-watch-blank-raw@3x.png"))
    # locate cream dial (right half): cream = high R,G, mid B, low saturation
    right = watch.crop((watch.width // 2, 0, watch.width, watch.height))
    cx_r, cy_r, rx, ry = find_circle(
        right, lambda r, g, b: (r > 195) & (g > 185) & (b > 150) & (r - b < 90) & (r - b > 25))
    dcx, dcy, dr = watch.width // 2 + cx_r, cy_r, min(rx, ry)
    # lid inner ellipse (left half): brass tones
    left = watch.crop((0, 0, watch.width // 2, watch.height))
    lcx, lcy, lrx, lry = find_circle(
        left, lambda r, g, b: (r > 120) & (r < 215) & (g > 95) & (b < 130) & (r - b > 55))
    lrx *= 0.72; lry *= 0.72  # stay well inside lid rim

    for name, hand_pos in (("inv-watch-a", 3), ("inv-watch-b", 9)):
        w = watch.copy()
        # numeral ring on dial
        for k, num in enumerate(["XII", "I", "II", "III", "IV", "V", "VI",
                                 "VII", "VIII", "IX", "X", "XI"]):
            ang = math.radians(k * 30 - 90)
            nx = dcx + dr * 0.80 * math.cos(ang)
            ny = dcy + dr * 0.80 * math.sin(ang)
            st = render_numeral(num, 200)
            tw = dr * (0.13 if len(num) == 1 else 0.20 if len(num) == 2 else
                       0.26 if len(num) == 3 else 0.30)
            engrave(w, st, nx, ny, target_w=tw, ink=(44, 38, 32), hi=(255, 250, 235),
                    hi_a=70, depth=2)
        # single blued-steel hand frozen at hand_pos
        d = ImageDraw.Draw(w)
        ang = math.radians(hand_pos * 30 - 90)
        L = dr * 0.62
        tipx, tipy = dcx + L * math.cos(ang), dcy + L * math.sin(ang)
        px, py = -math.sin(ang), math.cos(ang)
        steel = (43, 48, 66, 255)
        d.polygon([(dcx + px * dr * 0.030, dcy + py * dr * 0.030),
                   (dcx - px * dr * 0.030, dcy - py * dr * 0.030),
                   (tipx - px * dr * 0.012, tipy - py * dr * 0.012),
                   (tipx + px * dr * 0.012, tipy + py * dr * 0.012)], fill=steel)
        # spade tip
        sx, sy = dcx + L * 1.02 * math.cos(ang), dcy + L * 1.02 * math.sin(ang)
        ex, ey = dcx + L * 1.30 * math.cos(ang), dcy + L * 1.30 * math.sin(ang)
        d.polygon([(sx + px * dr * 0.055, sy + py * dr * 0.055),
                   (sx - px * dr * 0.055, sy - py * dr * 0.055), (ex, ey)],
                  fill=steel)
        # counterweight + boss
        bx, by = dcx - dr * 0.16 * math.cos(ang), dcy - dr * 0.16 * math.sin(ang)
        d.line([(dcx, dcy), (bx, by)], fill=steel, width=max(3, int(dr * 0.05)))
        r0 = dr * 0.055
        d.ellipse([dcx - r0, dcy - r0, dcx + r0, dcy + r0], fill=(120, 98, 60, 255))
        # engraved die + 12-notch ring on inner lid (squeezed to lid ellipse)
        sq = lrx / lry
        ring = die_notch_ring(400, 12)
        engrave(w, ring, lcx, lcy, target_w=2 * lry * 0.92 * sq, squeeze_x=1.0,
                ink=(74, 58, 30), hi=(250, 230, 170), hi_a=95, depth=3)
        die = die_house(400) if name == "inv-watch-a" else die_gear(400)
        engrave(w, die, lcx, lcy, target_w=2 * lry * 0.42 * sq, squeeze_x=1.0,
                ink=(74, 58, 30), hi=(250, 230, 170), hi_a=95, depth=3)
        save_icon(w, name)


if __name__ == "__main__":
    main()
