#!/usr/bin/env python3
"""Level 2 / z2 glyph-integration + close-up build (batch 2, 2026-07-19).

Same canonical-wide pipeline as l2_z1_build: deterministic overlays (ALL
load-bearing glyphs from l2_glyphs + sheet-B die PNGs — the generative model
never re-draws them) composited into the @3x wides; CUs cropped from the
INTEGRATED wides with native-res overlay re-composite where the CU upsamples.

z2 integrations:
  - clockrow: canonical numeral rings on all 4 HAND-LESS dials; landmark
    plates stamped with sheet-B dies + offset stamps, binding order
    Burj +IV | Big Ben (star) | Fuji +IX | Liberty -V.
  - frame: XII / VIII pinion stamps (crank pinion / post-A collar);
    gear-ring brick carve (die_gear + die_notch_ring, SAME dies as watch B);
    six brass rack gears 16/24/36/40/48/72 — EXACT tooth counts asserted,
    canonical render_arabic stamps, diameters monotonic in tooth count,
    square arbor holes (9.3 rhyme), delivered also as standalone props.

Usage: python l2_z2_build.py <gears|integrate|cus|all>
"""
import json
import math
import os
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import (render_numeral, render_arabic, die_star, die_gear,
                       die_notch_ring, tint)

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z2 = os.path.join(A2, "z2")
GLY = os.path.join(A2, "masters", "glyphs")
REJ = os.path.join(A2, "_rejects")
SCR = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")
WK = os.path.join(SCR, "z2work")
os.makedirs(WK, exist_ok=True)
CU_W, CU_H = 2048, 1536
RNG = np.random.default_rng(20260720)

WIDES = {
    "frame": os.path.join(Z2, "v-frame", "z2-frame-base@3x.png"),
    "clockrow": os.path.join(Z2, "v-clockrow", "z2-clockrow-base@3x.png"),
}
# CU frames in wide @3x coords (all exact 4:3)
FRAMES = {
    "cu-gear-frame":     ("frame",    660, 660, 2100, 1740),
    "cu-gear-rack":      ("frame",    1905, 940, 2705, 1540),
    "cu-gear-ring":      ("frame",    2560, 940, 3120, 1360),
    "cu-brick-cache":    ("frame",    2470, 935, 3030, 1355),
    "cu-clockrow-plates": ("clockrow", 760, 180, 3000, 1860),
    "cu-cabinet-drawer": ("clockrow", 2050, 1095, 3150, 1920),
    "cu-display-case":   ("clockrow", 620, 840, 2060, 1920),
}
OUT_DIR = {
    "cu-gear-frame": "v-frame", "cu-gear-rack": "v-frame",
    "cu-gear-ring": "v-frame", "cu-brick-cache": "v-frame",
    "cu-clockrow-plates": "v-clockrow", "cu-cabinet-drawer": "v-clockrow",
    "cu-display-case": "v-clockrow",
}

# dial estimates (center x, y, face radius) in clockrow @3x — refined by probe
DIALS = [(998, 570, 186, 205), (1625, 560, 205, 212), (2215, 564, 193, 196), (2780, 564, 186, 188)]
# plate inner faces (x0,y0,x1,y1) in clockrow @3x, binding left->right order
PLATES = [
    ("burj",    "+IV", (900, 895, 1240, 1035)),
    ("bigben",  "*",   (1470, 890, 1800, 1030)),
    ("fuji",    "+IX", (2020, 895, 2360, 1025)),
    ("liberty", "-V",  (2600, 895, 2930, 1025)),
]
# gear rack: six anchor points (peg positions) in frame @3x + perspective
GEAR_ANCHORS = {   # teeth -> (cx, cy)
    36: (2182, 1152), 48: (2300, 1160), 24: (2425, 1170),
    40: (2195, 1337), 16: (2305, 1345), 72: (2428, 1355),
}
GEAR_DIA = {16: 70, 24: 83, 36: 102, 40: 112, 48: 118, 72: 148}  # @3x, monotonic
RACK_SQUASH, RACK_ROT = 0.88, -3.0
PINION_XII = (1055, 1102)      # crank pinion hub (frame @3x)
COLLAR_VIII = (1435, 1300)     # post-A mount block face (frame @3x)
GRING = (2850, 1097, 50)       # gear-ring brick carve center + ring dia (frame @3x)


def frame_scale(name):
    _, x0, y0, x1, y1 = FRAMES[name]
    return CU_W / (x1 - x0)


def engrave(base, stamp, cx, cy, target_h=None, target_w=None, rot=0.0,
            ink=(48, 34, 20), hi=(240, 216, 160), ink_a=225, hi_a=100, depth=4,
            max_w=None):
    w, h = stamp.size
    s = (target_h / h) if target_h else (target_w / w)
    if max_w and w * s > max_w:
        s = max_w / w
    st = stamp.resize((max(1, round(w * s)), max(1, round(h * s))), Image.LANCZOS)
    if rot:
        st = st.rotate(rot, expand=True, resample=Image.BICUBIC)
    a = st.split()[3]
    for col, alp, dx, dy in ((hi, hi_a, depth, depth), (ink, ink_a, 0, 0)):
        layer = Image.new("RGBA", st.size, col + (0,))
        layer.putalpha(a.point(lambda v, m=alp: v * m // 255))
        base.alpha_composite(layer, (round(cx - st.width / 2 + dx),
                                     round(cy - st.height / 2 + dy)))


def offset_stamp(text, height=400):
    """Offset stamp: '+'/'-' bar glyphs + canonical numeral, composed once.
    Only sign geometry is local; numerals come from l2_glyphs (ONE source)."""
    sign, num = text[0], text[1:]
    n = render_numeral(num, height)
    bar = height * 0.13
    sw = int(height * 0.42)
    s = Image.new("RGBA", (sw, height), (0, 0, 0, 0))
    d = ImageDraw.Draw(s)
    cy = height * 0.52
    d.rectangle([2, cy - bar / 2, sw - 2, cy + bar / 2], fill=(20, 18, 15, 255))
    if sign == "+":
        cx = sw / 2
        d.rectangle([cx - bar / 2, cy - sw / 2 + 2, cx + bar / 2, cy + sw / 2 - 2],
                    fill=(20, 18, 15, 255))
    out = Image.new("RGBA", (sw + int(height * 0.16) + n.width, height), (0, 0, 0, 0))
    out.alpha_composite(s, (0, 0))
    out.alpha_composite(n, (sw + int(height * 0.16), (height - n.height) // 2))
    return out


# -------------------------------------------------------------------- gears

def render_gear(teeth, dia_px, ss=6, depth_frac=None):
    """Deterministic brass rack gear, EXACT tooth count asserted; square arbor
    hole (9.3 rhyme); solid web + 4 small lightening holes; canonical Arabic
    stamp engraved at 6 o'clock on the web. RGBA.

    `depth_frac` (rev 1.4.1, added for the F1 post-A 8-tooth pinion): tooth height
    as a fraction of the tip radius, overriding the default 2.6/teeth heuristic.
    The heuristic is right for the 16..72-tooth rack wheels but degenerates at
    z=8 into 32%-radius spikes that read as a sunburst rather than a pinion; the
    override lets a LOW-tooth-count wheel keep the shipped crank pinion's short
    tooth profile. Default None = previous behaviour, byte-for-byte."""
    D = dia_px * ss
    c = D / 2
    r_tip = c * 0.98
    r_root = (r_tip * (1.0 - depth_frac) if depth_frac
              else r_tip - max(6 * ss, r_tip * 2.6 / teeth))
    r_hub = c * 0.30
    sq = c * 0.145
    sil = Image.new("L", (D, D), 0)
    d = ImageDraw.Draw(sil)
    d.ellipse([c - r_root, c - r_root, c + r_root, c + r_root], fill=255)
    n = 0
    for k in range(teeth):
        a = 2 * math.pi * k / teeth
        half = math.pi / teeth * 0.48
        pts = []
        for da, rr in ((-half, r_root - 2 * ss), (-half * 0.6, r_tip),
                       (half * 0.6, r_tip), (half, r_root - 2 * ss)):
            pts.append((c + rr * math.cos(a + da), c + rr * math.sin(a + da)))
        d.polygon(pts, fill=255)
        n += 1
    assert n == teeth, f"tooth-count contract {teeth}"
    if teeth >= 36:   # 4 small round lightening holes on the diagonals
        r_lh = c * 0.105
        r_pos = (r_hub + r_root * 0.86) / 2
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            hx, hy = c + r_pos * math.cos(a), c + r_pos * math.sin(a)
            d.ellipse([hx - r_lh, hy - r_lh, hx + r_lh, hy + r_lh], fill=0)
    d.rectangle([c - sq, c - sq, c + sq, c + sq], fill=0)  # square arbor hole
    # brass shading: dulled base, top-left sheen, rim band, brushed angle noise
    yy, xx = np.mgrid[0:D, 0:D]
    rr = np.sqrt((xx - c) ** 2 + (yy - c) ** 2)
    ldir = (-(xx - c) * 0.5 - (yy - c) * 0.5) / max(r_tip, 1)
    base = np.array([186, 151, 72], np.float32)
    shade = 1.0 + 0.14 * ldir - 0.10 * (rr / r_tip) ** 2.4
    theta = np.arctan2(yy - c, xx - c)
    rng = np.random.default_rng(teeth)
    bins = 2048
    ang1d = rng.normal(0, 1, bins)
    kern = np.exp(-0.5 * (np.arange(-19, 20) / 7.0) ** 2)
    ang1d = np.convolve(ang1d, kern / kern.sum(), mode="same")
    shade += 0.045 * ang1d[((theta + math.pi) / (2 * math.pi) * (bins - 1)).astype(int)]
    rgb = np.clip(base[None, None, :] * shade[..., None], 0, 255)
    band = (rr > r_root * 0.86) & (rr < r_root)
    rgb[band] *= 0.88
    hubm = rr < r_hub
    rgb[hubm] *= 1.06
    im = Image.fromarray(np.dstack([rgb.astype(np.uint8),
                                    np.asarray(sil, np.uint8)]), "RGBA")
    d = ImageDraw.Draw(im)
    d.ellipse([c - r_root, c - r_root, c + r_root, c + r_root],
              outline=(64, 50, 26, 150), width=int(1.2 * ss))
    d.arc([c - r_root + 2 * ss, c - r_root + 2 * ss, c + r_root - 2 * ss,
           c + r_root - 2 * ss], start=180, end=300,
          fill=(232, 205, 130, 170), width=int(1.4 * ss))
    d.ellipse([c - r_hub, c - r_hub, c + r_hub, c + r_hub],
              outline=(70, 54, 28, 160), width=int(1.1 * ss))
    if teeth >= 36:
        r_lh = c * 0.105
        r_pos = (r_hub + r_root * 0.86) / 2
        for k in range(4):
            a = math.pi / 4 + k * math.pi / 2
            hx, hy = c + r_pos * math.cos(a), c + r_pos * math.sin(a)
            d.ellipse([hx - r_lh, hy - r_lh, hx + r_lh, hy + r_lh],
                      outline=(64, 50, 26, 170), width=int(1.1 * ss))
    d.rectangle([c - sq, c - sq, c + sq, c + sq],
                outline=(45, 34, 18, 255), width=int(1.5 * ss))
    d.line([(c - sq, c + sq), (c + sq, c + sq)],
           fill=(226, 198, 126, 150), width=int(1.0 * ss))
    # canonical stamp at 6 o'clock on the solid web, between hub and rim
    st = tint(render_arabic(str(teeth), 200), (255, 255, 255, 255))
    sy = c + (r_hub + r_root * 0.86) / 2
    engrave(im, st, c, sy, target_h=int(c * 0.30), ink=(50, 37, 18),
            hi=(232, 204, 132), ink_a=235, hi_a=140, depth=int(0.8 * ss),
            max_w=int(c * 0.62))
    return im.resize((dia_px, dia_px), Image.LANCZOS)


def build_gear_props():
    """Standalone RGBA prop plates (1024 long side) for Developer overlay reuse."""
    outd = os.path.join(Z2, "props")
    os.makedirs(outd, exist_ok=True)
    for t in sorted(GEAR_DIA):
        g = render_gear(t, 1024)
        g.save(os.path.join(outd, f"gear-{t}@3x.png"))
        g.resize((683, 683), Image.LANCZOS).save(os.path.join(outd, f"gear-{t}@2x.png"))
        g.resize((341, 341), Image.LANCZOS).save(os.path.join(outd, f"gear-{t}@1x.png"))
        print(f"gear-{t}: exact {t} teeth asserted")


# ------------------------------------------------------- overlays (wide @3x)

def ov_clockrow(wide):
    """Numeral rings on 4 hand-less dials + stamped landmark plates."""
    ov = Image.new("RGBA", wide.size, (0, 0, 0, 0))
    for (cx, cy, rx, ry) in DIALS:
        # UPRIGHT canonical numerals on the fixed measured rings (auto center
        # detection misfired against the warm-lit wall; radial rotation
        # smeared at this scale — upright per the legibility gate)
        for k in range(1, 13):
            num = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII",
                   "IX", "X", "XI", "XII"][k - 1]
            ang = math.radians(k * 30 - 90)
            nx = cx + rx * 0.71 * math.cos(ang)
            ny = cy + ry * 0.71 * math.sin(ang)
            st = tint(render_numeral(num, 200), (58, 46, 34, 255))
            engrave(ov, st, nx, ny, target_h=int(ry * 0.165), rot=0,
                    max_w=int(rx * 0.34), ink=(58, 46, 34), hi=(255, 250, 235),
                    ink_a=235, hi_a=55, depth=2)
    # plates: sheet-B dies + offsets (binding order)
    for die_name, off, (x0, y0, x1, y1) in PLATES:
        pw, ph = x1 - x0, y1 - y0
        cx, cy = (x0 + x1) / 2, (y0 + y1) / 2
        die = Image.open(os.path.join(GLY, f"die-{die_name}.png")).convert("RGBA")
        ink = (64, 46, 22)
        hi = (255, 238, 190)
        if die_name == "fuji":
            engrave(ov, die, x0 + pw * 0.32, cy, target_w=int(pw * 0.40),
                    ink=ink, hi=hi, depth=3)
        else:
            engrave(ov, die, x0 + pw * 0.30, cy, target_h=int(ph * 0.84),
                    ink=ink, hi=hi, depth=3)
        if off == "*":
            engrave(ov, die_star(400, (20, 18, 15, 255)), x0 + pw * 0.68, cy,
                    target_h=int(ph * 0.46), ink=ink, hi=hi, depth=3)
        else:
            st = offset_stamp(off, 400)
            engrave(ov, st, x0 + pw * 0.68, cy, target_h=int(ph * 0.44),
                    max_w=int(pw * 0.58), ink=ink, hi=hi, depth=3)
    return ov


def ov_frame_stamps(wide):
    """XII / VIII pinion stamps + gear-ring brick carve, wide @3x space."""
    ov = Image.new("RGBA", wide.size, (0, 0, 0, 0))
    st = tint(render_numeral("XII", 200), (40, 30, 18, 255))
    engrave(ov, st, PINION_XII[0], PINION_XII[1] + 52, target_h=30, max_w=76,
            ink=(40, 30, 18), hi=(238, 210, 150), ink_a=235, hi_a=120, depth=2)
    st = tint(render_numeral("VIII", 200), (40, 30, 18, 255))
    engrave(ov, st, COLLAR_VIII[0], COLLAR_VIII[1], target_h=30, max_w=86,
            ink=(30, 22, 14), hi=(232, 206, 152), ink_a=240, hi_a=170, depth=2)
    # gear-ring carve: SAME dies as watch B back (die_gear + die_notch_ring)
    gx, gy, gd = GRING
    ring = die_notch_ring(400, 12, color=(30, 22, 16, 255))
    engrave(ov, ring, gx, gy, target_h=gd, ink=(38, 24, 14),
            hi=(214, 168, 128), ink_a=220, hi_a=95, depth=2)
    gear = die_gear(400, 8, (30, 22, 16, 255))
    engrave(ov, gear, gx, gy, target_h=int(gd * 0.46), ink=(38, 24, 14),
            hi=(214, 168, 128), ink_a=220, hi_a=95, depth=2)
    return ov


def ov_rack_gears(wide):
    """Six deterministic gears hung on the rack pegs (perspective-matched);
    peg tips re-pasted through the square arbor holes."""
    ov = Image.new("RGBA", wide.size, (0, 0, 0, 0))
    base = wide.convert("RGB")
    for t, (cx, cy) in GEAR_ANCHORS.items():
        dia = GEAR_DIA[t]
        g = render_gear(t, dia * 3)          # render 3x then squash+shrink
        g = g.resize((int(dia * RACK_SQUASH), dia), Image.LANCZOS)
        g = g.rotate(RACK_ROT, expand=True, resample=Image.BICUBIC)
        gy = cy + 4                          # hangs on the peg
        # soft shadow (light from right -> shadow left-down)
        sh = Image.new("RGBA", g.size, (0, 0, 0, 0))
        al = g.split()[3].point(lambda v: v * 70 // 255)
        sh.putalpha(al)
        sh = sh.filter(ImageFilter.GaussianBlur(6))
        ov.alpha_composite(sh, (round(cx - g.width / 2 - 8), round(gy - g.height / 2 + 7)))
        ov.alpha_composite(g, (round(cx - g.width / 2), round(gy - g.height / 2)))
    return ov


# ---------------------------------------------------------------- integrate

def integrate():
    for wname, wpath in WIDES.items():
        im = Image.open(wpath).convert("RGBA")
        if wname == "clockrow":
            im.alpha_composite(ov_clockrow(im))
        else:
            im.alpha_composite(ov_frame_stamps(im))
            im.alpha_composite(ov_rack_gears(im))
        base_dir = os.path.dirname(wpath)
        stem = os.path.basename(wpath).replace("@3x.png", "")
        os.makedirs(REJ, exist_ok=True)
        for tag in ("1x", "2x", "3x"):
            src = os.path.join(base_dir, f"{stem}@{tag}.png")
            dst = os.path.join(REJ, f"{stem}-preglyph@{tag}.png")
            if os.path.exists(src) and not os.path.exists(dst):
                os.replace(src, dst)
        out = im.convert("RGB")
        out.save(os.path.join(base_dir, f"{stem}@3x.png"))
        out.resize((2560, 1280), Image.LANCZOS).save(os.path.join(base_dir, f"{stem}@2x.png"))
        out.resize((1280, 640), Image.LANCZOS).save(os.path.join(base_dir, f"{stem}@1x.png"))
        print("integrated", stem)


# ---------------------------------------------------------------------- CUs

def save_densities(im, out_dir, name):
    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, name + "@3x.png"))
    im.resize((1365, 1024), Image.LANCZOS).save(os.path.join(out_dir, name + "@2x.png"))
    im.resize((683, 512), Image.LANCZOS).save(os.path.join(out_dir, name + "@1x.png"))
    print("saved", name)


def build_cus():
    """Crop CUs from INTEGRATED wides; where the CU upsamples (scale > 1),
    re-composite the region's deterministic overlay at native CU res."""
    wides = {k: Image.open(p).convert("RGB") for k, p in WIDES.items()}
    # native-res overlay layers, built once in wide space at CU scale:
    for name in FRAMES:
        wname, x0, y0, x1, y1 = FRAMES[name]
        s = frame_scale(name)
        cu = wides[wname].crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS)
        cu = cu.convert("RGBA")
        if name == "cu-gear-frame":
            lay = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
            st = tint(render_numeral("XII", 200), (40, 30, 18, 255))
            engrave(lay, st, (PINION_XII[0] - x0) * s, (PINION_XII[1] + 52 - y0) * s,
                    target_h=int(30 * s), max_w=int(76 * s), ink=(40, 30, 18),
                    hi=(238, 210, 150), ink_a=235, hi_a=120, depth=3)
            st = tint(render_numeral("VIII", 200), (40, 30, 18, 255))
            engrave(lay, st, (COLLAR_VIII[0] - x0) * s, (COLLAR_VIII[1] - y0) * s,
                    target_h=int(30 * s), max_w=int(86 * s), ink=(30, 22, 14),
                    hi=(232, 206, 152), ink_a=240, hi_a=170, depth=3)
            cu.alpha_composite(lay)
        elif name == "cu-gear-rack":
            # re-render gears at native CU res over the (already-integrated,
            # softened) crop for crisp countable teeth
            lay = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
            raw = wides[wname]
            for t, (cx, cy) in GEAR_ANCHORS.items():
                dia = int(GEAR_DIA[t] * s)
                g = render_gear(t, dia)
                g = g.resize((int(dia * RACK_SQUASH), dia), Image.LANCZOS)
                g = g.rotate(RACK_ROT, expand=True, resample=Image.BICUBIC)
                ccx, ccy = (cx - x0) * s, (cy + 4 - y0) * s
                sh = Image.new("RGBA", g.size, (0, 0, 0, 0))
                sh.putalpha(g.split()[3].point(lambda v: v * 70 // 255))
                sh = sh.filter(ImageFilter.GaussianBlur(6 * s / 2.5))
                lay.alpha_composite(sh, (round(ccx - g.width / 2 - 8 * s / 2.5),
                                         round(ccy - g.height / 2 + 7 * s / 2.5)))
                lay.alpha_composite(g, (round(ccx - g.width / 2),
                                        round(ccy - g.height / 2)))
            cu.alpha_composite(lay)
        elif name == "cu-gear-ring":
            lay = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
            gx, gy, gd = GRING
            ring = die_notch_ring(400, 12, color=(30, 22, 16, 255))
            engrave(lay, ring, (gx - x0) * s, (gy - y0) * s, target_h=int(gd * s),
                    ink=(38, 24, 14), hi=(214, 168, 128), ink_a=220, hi_a=95, depth=4)
            gear = die_gear(400, 8, (30, 22, 16, 255))
            engrave(lay, gear, (gx - x0) * s, (gy - y0) * s,
                    target_h=int(gd * 0.46 * s), ink=(38, 24, 14),
                    hi=(214, 168, 128), ink_a=220, hi_a=95, depth=4)
            cu.alpha_composite(lay)
        save_densities(cu.convert("RGB"), os.path.join(Z2, OUT_DIR[name]), name)


def montage():
    tiles = []
    for wname in WIDES:
        tiles.append(("WIDE " + wname,
                      Image.open(WIDES[wname]).resize((960, 480))))
    for name in FRAMES:
        p = os.path.join(Z2, OUT_DIR[name], name + "@1x.png")
        tiles.append((name, Image.open(p).resize((640, 480))))
    for t in sorted(GEAR_DIA):
        tiles.append((f"gear-{t}", Image.open(
            os.path.join(Z2, "props", f"gear-{t}@2x.png")).resize((480, 480))))
    cols = 3
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * 980, rows * 520), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    for i, (label, im) in enumerate(tiles):
        x = (i % cols) * 980 + 10
        y = (i // cols) * 520 + 10
        sheet.paste(im.convert("RGB"), (x, y))
        dd.text((x + 4, y + 490), label, fill=(230, 225, 210))
    sheet.save(os.path.join(Z2, "z2-review-batch2.png"))
    print("montage saved", sheet.size)


if __name__ == "__main__":
    what = sys.argv[1] if len(sys.argv) > 1 else "all"
    if what in ("gears", "all"):
        build_gear_props()
    if what in ("integrate", "all"):
        integrate()
    if what in ("cus", "all"):
        build_cus()
    if what == "montage":
        montage()
