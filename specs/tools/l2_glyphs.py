#!/usr/bin/env python3
"""Level 2 canonical glyph library — deterministic PIL geometry.

ONE canonical source for every puzzle-load-bearing glyph in Level 2
(binding user directive 2026-07-09): Roman numerals I-XII in the level's
engraved-serif letterform (asymmetric wedge serifs -> mirrored glyphs read
detectably malformed), the mirrored set, the small-mark dies
(star, house, gear, door, 12-notch ring), and the geometric landmark dies
(Big Ben, Burj Khalifa, Fuji; Liberty is NB-generated and threshold-cleaned).

Every dial/tile/stamp/engraving in the level composites THESE stamps —
the generative model never re-draws a load-bearing glyph.

Contracts (style guide 4.1/4.2):
- Standard subtractive notation only: IV, IX. No IIII anywhere.
- Heavier LEFT-foot serif on I; thick/thin stroke contrast on V and X.
- Mirrored IV must read as a MALFORMED VI (thick strokes / foot serifs on
  the wrong side); mirrored VII reads "IIV", never a legible VII.
"""
import json
import os

from PIL import Image, ImageDraw

SS = 4          # supersample factor
H = 400         # glyph design height (final px before caller scaling)
GAP = 40        # inter-glyph spacing inside a numeral

# ---------------------------------------------------------------- primitives
# Each primitive: (advance_width, [polygon, ...]) in a H-tall box, y down.
# Asymmetry is load-bearing: I's bottom-left serif is the heaviest flare;
# V and X carry thick descending / thin ascending stroke contrast.

def _prim_I():
    polys = [
        [(60, 0), (120, 0), (120, 400), (60, 400)],           # stem (thick 60)
        [(34, 0), (138, 0), (120, 30), (60, 30)],             # top serif
        [(60, 370), (120, 370), (142, 400), (14, 400)],       # bottom serif — LEFT foot 46 vs right 22
    ]
    return 156, polys


def _prim_V():
    polys = [
        [(20, 0), (84, 0), (200, 400), (150, 400)],           # thick descending
        [(296, 0), (322, 0), (196, 400), (168, 400)],         # thin ascending
        [(0, 0), (102, 0), (84, 28), (30, 28)],               # top-left serif
        [(272, 0), (340, 0), (322, 26), (296, 26)],           # top-right serif
    ]
    return 340, polys


def _prim_X():
    polys = [
        [(30, 0), (94, 0), (310, 400), (246, 400)],           # thick descending
        [(270, 0), (298, 0), (64, 400), (36, 400)],           # thin ascending
        [(6, 0), (116, 0), (94, 28), (30, 28)],               # TL serif (thick)
        [(248, 0), (318, 0), (298, 24), (270, 24)],           # TR serif (thin)
        [(36, 374), (64, 374), (86, 400), (14, 400)],         # BL serif (thin)
        [(246, 372), (310, 372), (332, 400), (224, 400)],     # BR serif (thick)
    ]
    return 340, polys


PRIMS = {"I": _prim_I, "V": _prim_V, "X": _prim_X}

NUMERALS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII",
            "IX", "X", "XI", "XII"]  # subtractive notation ONLY — no IIII


def render_numeral(s, height=400, color=(20, 18, 15, 255), mirror=False):
    """Deterministic render of a numeral string; tight-bbox RGBA stamp.

    mirror=True flips the WHOLE numeral horizontally (glyph order AND each
    letterform), matching the great-dial back-view contract (4.2)."""
    parts = [PRIMS[c]() for c in s]
    total_w = sum(w for w, _ in parts) + GAP * (len(parts) - 1)
    im = Image.new("RGBA", (total_w * SS, H * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x = 0
    for w, polys in parts:
        for poly in polys:
            d.polygon([((x + px) * SS, py * SS) for px, py in poly], fill=color)
        x += w + GAP
    if mirror:
        im = im.transpose(Image.FLIP_LEFT_RIGHT)
    im = im.resize((round(total_w * height / H), height), Image.LANCZOS)
    return im.crop(im.getbbox())


# ---------------------------------------------------------------- small dies

def die_notch_ring(size=400, notches=12, ring_w=14, notch_len=44,
                   color=(20, 18, 15, 255)):
    """Engraved clock-position ring: EXACTLY `notches` radial ticks, one at
    12 o'clock. Used for the ⌂ and ⚙ cache rings (and watch backs)."""
    import math
    im = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size * SS / 2
    r = (size / 2 - notch_len - 8) * SS
    d.ellipse([c - r, c - r, c + r, c + r], outline=color, width=ring_w * SS)
    for k in range(notches):
        a = math.radians(k * 360 / notches - 90)   # k=0 at top
        r0, r1 = r, r + notch_len * SS
        d.line([(c + r0 * math.cos(a), c + r0 * math.sin(a)),
                (c + r1 * math.cos(a), c + r1 * math.sin(a))],
               fill=color, width=(ring_w - 2) * SS)
    return im.resize((size, size), Image.LANCZOS)


def die_star(size=400, color=(20, 18, 15, 255)):
    """5-point star die (master longcase / Big Ben plate+header)."""
    import math
    im = Image.new("RGBA", (size * SS, size * SS), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = size * SS / 2
    R, r = c * 0.96, c * 0.40
    pts = []
    for k in range(10):
        rad = R if k % 2 == 0 else r
        a = math.radians(k * 36 - 90)
        pts.append((c + rad * math.cos(a), c + rad * math.sin(a)))
    d.polygon(pts, fill=color)
    return im.resize((size, size), Image.LANCZOS)


def die_house(size=400, color=(20, 18, 15, 255), stroke=34):
    """⌂ house mark (beam carving, watch A back)."""
    s = size * SS
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    w = stroke * SS
    pts = [(s * 0.14, s * 0.94), (s * 0.14, s * 0.42), (s * 0.5, s * 0.08),
           (s * 0.86, s * 0.42), (s * 0.86, s * 0.94)]
    d.line(pts + [pts[0]], fill=color, width=w, joint="curve")
    return im.resize((size, size), Image.LANCZOS)


def die_gear(size=400, teeth=8, color=(20, 18, 15, 255)):
    """⚙ gear mark (chimney carving, watch B back). 8 square teeth + hub hole."""
    import math
    s = size * SS
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    c = s / 2
    r_body, r_tooth, r_hole = c * 0.62, c * 0.94, c * 0.26
    d.ellipse([c - r_body, c - r_body, c + r_body, c + r_body], fill=color)
    tooth_half = math.pi / teeth * 0.42
    for k in range(teeth):
        a = 2 * math.pi * k / teeth - math.pi / 2
        pts = []
        for da, rr in ((-tooth_half, r_body), (-tooth_half * 0.8, r_tooth),
                       (tooth_half * 0.8, r_tooth), (tooth_half, r_body)):
            pts.append((c + rr * math.cos(a + da), c + rr * math.sin(a + da)))
        d.polygon(pts, fill=color)
    d.ellipse([c - r_hole, c - r_hole, c + r_hole, c + r_hole],
              fill=(0, 0, 0, 0))
    return im.resize((size, size), Image.LANCZOS)


def die_door(size=400, color=(20, 18, 15, 255)):
    """Arched-door mark (slate cam circle, return tag)."""
    s = size * SS
    im = Image.new("RGBA", (s, s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    x0, x1 = s * 0.24, s * 0.76
    ytop, ybot = s * 0.30, s * 0.92
    d.pieslice([x0, s * 0.08, x1, ytop + (ytop - s * 0.08)], 180, 360, fill=color)
    d.rectangle([x0, ytop, x1, ybot], fill=color)
    # engraved inner line + handle dot cut out
    d.rectangle([x0 + s * 0.07, ytop, x1 - s * 0.07, ybot - s * 0.05],
                fill=(0, 0, 0, 0))
    d.rectangle([x0 + s * 0.11, ytop - s * 0.02, x1 - s * 0.11, ybot - s * 0.09],
                fill=color)
    d.ellipse([x1 - s * 0.22, s * 0.56, x1 - s * 0.16, s * 0.62],
              fill=(0, 0, 0, 0))
    return im.resize((size, size), Image.LANCZOS)


# ------------------------------------------------------------- landmark dies

def die_bigben(height=480, color=(20, 18, 15, 255)):
    """Big Ben die: parallel shaft, MANDATORY protruding clock-face stage
    (widest point below the spire) with engraved dial disc, stepped spire.
    Aspect ~4:1."""
    W = 132
    s = SS
    im = Image.new("RGBA", (W * s, height * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    def R(x0, y0, x1, y1):
        d.rectangle([x0 * s, y0 * s, x1 * s, y1 * s], fill=color)
    # plinth + parallel shaft
    R(30, 462, 102, 480)
    R(38, 150, 94, 466)
    # clock-face stage: protrudes BOTH sides — widest point below spire
    R(14, 88, 118, 150)
    # engraved dial disc on the stage (cut out ring + hub)
    cx, cy, r = 66 * s, 119 * s, 24 * s
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=(0, 0, 0, 0))
    d.ellipse([cx - r + 5 * s, cy - r + 5 * s, cx + r - 5 * s, cy + r - 5 * s],
              fill=color)
    d.ellipse([cx - 6 * s, cy - 6 * s, cx + 6 * s, cy + 6 * s], fill=(0, 0, 0, 0))
    # stepped cap over stage, then spire + finial
    R(22, 72, 110, 88)
    R(34, 58, 98, 72)
    d.polygon([(40 * s, 58 * s), (92 * s, 58 * s), (68 * s, 10 * s),
               (64 * s, 10 * s)], fill=color)
    R(62, 0, 70, 12)
    return im.resize((W * height // 480, height), Image.LANCZOS)


def die_burj(height=480, color=(20, 18, 15, 255)):
    """Burj Khalifa die: Y-lobed flared base, stepped setbacks, STRICTLY
    monotonic taper to a needle. Aspect ~8:1. No protrusion anywhere."""
    W = 84
    s = SS
    im = Image.new("RGBA", (W * s, height * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    cx = W / 2
    # (half_width, y_top) steps, monotonically narrowing bottom->top
    steps = [(42, 480), (36, 430), (30, 380), (25, 330), (20, 280),
             (16, 230), (12, 180), (9, 135), (6.5, 100), (4.5, 70)]
    y_prev = 480
    for half, ytop in steps:
        if ytop == 480:
            y_prev = ytop
            continue
        d.rectangle([(cx - half) * s, ytop * s, (cx + half) * s, y_prev * s],
                    fill=color)
        y_prev = ytop
    # base lobes (Y-plan flare read as side steps at the foot)
    d.rectangle([(cx - 42) * s, 430 * s, (cx + 42) * s, 480 * s], fill=color)
    d.polygon([((cx - 42) * s, 480 * s), ((cx - 30) * s, 400 * s),
               ((cx - 30) * s, 480 * s)], fill=color)
    d.polygon([((cx + 42) * s, 480 * s), ((cx + 30) * s, 400 * s),
               ((cx + 30) * s, 480 * s)], fill=color)
    # needle
    d.rectangle([(cx - 2.2) * s, 8 * s, (cx + 2.2) * s, 70 * s], fill=color)
    return im.resize((W * height // 480, height), Image.LANCZOS)


def die_fuji(width=400, color=(20, 18, 15, 255)):
    """Mount Fuji die: the ONLY horizontal mark. Wide symmetric mountain,
    flattened crest, hatched engraved snowcap. Aspect ~1:2.5 (w:h 2.5)."""
    Hh = int(width / 2.5)
    s = SS
    im = Image.new("RGBA", (width * s, Hh * s), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    w, h = width, Hh
    # gently concave flanks via polyline
    pts = [(0.02 * w, 0.96 * h), (0.20 * w, 0.72 * h), (0.34 * w, 0.42 * h),
           (0.42 * w, 0.16 * h), (0.46 * w, 0.10 * h),   # left crest shoulder
           (0.54 * w, 0.10 * h), (0.58 * w, 0.16 * h),   # flattened crest
           (0.66 * w, 0.42 * h), (0.80 * w, 0.72 * h), (0.98 * w, 0.96 * h)]
    poly = [(px * s, py * s) for px, py in pts] + \
           [(0.98 * w * s, 0.96 * h * s), (0.02 * w * s, 0.96 * h * s)]
    d.polygon(poly, fill=color)
    # engraved hatched snowcap: zigzag cap line + hatch strokes cut out
    zig = [(0.40 * w, 0.28 * h), (0.44 * w, 0.34 * h), (0.48 * w, 0.27 * h),
           (0.52 * w, 0.34 * h), (0.56 * w, 0.27 * h), (0.60 * w, 0.28 * h)]
    d.line([(px * s, py * s) for px, py in zig], fill=(0, 0, 0, 0),
           width=int(0.018 * w * s))
    for k in range(5):
        x = (0.42 + 0.04 * k) * w
        d.line([(x * s, 0.135 * h * s), ((x - 0.02 * w) * s, 0.25 * h * s)],
               fill=(0, 0, 0, 0), width=int(0.011 * w * s))
    return im.resize((width, Hh), Image.LANCZOS)


# ------------------------------------------------------- Arabic digit stamps

def render_arabic(text, height=400, color=(20, 18, 15, 255)):
    """Canonical Arabic tooth-count stamps (16/24/36/40/48/64/72), Georgia Bold.
    ONE source for every gear stamp level-wide (added 2026-07-19 for the great
    wheel; z2 rack gears MUST reuse this exact renderer)."""
    from PIL import ImageFont
    font = ImageFont.truetype(r"C:\Windows\Fonts\georgiab.ttf", height * 2)
    x0, y0, x1, y1 = font.getbbox(text)
    im = Image.new("RGBA", (x1 - x0 + 8, y1 - y0 + 8), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    d.text((4 - x0, 4 - y0), text, font=font, fill=color)
    im = im.crop(im.getbbox())
    return im.resize((round(im.width * height / im.height), height), Image.LANCZOS)


# ------------------------------------------------------------------- helpers

def tint(stamp, rgba):
    """Recolor a stamp's ink keeping its alpha."""
    r, g, b, a = stamp.split()
    solid = Image.new("RGBA", stamp.size, rgba)
    out = Image.new("RGBA", stamp.size, (0, 0, 0, 0))
    out.paste(solid, (0, 0), a)
    return out


def main():
    root = r"C:\Users\shaim\escape-room\specs\assets\level-2\masters"
    gdir = os.path.join(root, "glyphs")
    os.makedirs(gdir, exist_ok=True)
    ink = (26, 22, 17, 255)
    # per-numeral stamps, standard + mirrored
    meta = {"numerals": {}, "notes": {
        "notation": "subtractive only — IV/IX, IIII banned (rev 1.2)",
        "asymmetry": "heavy left-foot serif on I; thick descending / thin ascending on V and X",
        "mirror_rule": "mirrored stamps flip glyph order AND letterform (dial back view, 4.2)"}}
    for n in NUMERALS:
        for mir in (False, True):
            im = render_numeral(n, 400, ink, mirror=mir)
            fn = f"num-{n.lower()}{'-mir' if mir else ''}.png"
            im.save(os.path.join(gdir, fn))
            meta["numerals"].setdefault(n, {})["mir" if mir else "std"] = fn
    # small-mark dies
    for name, im in [("die-star", die_star(400, ink)),
                     ("die-house", die_house(400, ink)),
                     ("die-gear", die_gear(400, 8, ink)),
                     ("die-door", die_door(400, ink)),
                     ("die-ring12", die_notch_ring(400, 12, color=ink))]:
        im.save(os.path.join(gdir, name + ".png"))
    # geometric landmark dies
    die_bigben(480, ink).save(os.path.join(gdir, "die-bigben.png"))
    die_burj(480, ink).save(os.path.join(gdir, "die-burj.png"))
    die_fuji(400, ink).save(os.path.join(gdir, "die-fuji.png"))
    with open(os.path.join(root, "numerals-canonical.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print("glyph stamps written")


if __name__ == "__main__":
    main()
