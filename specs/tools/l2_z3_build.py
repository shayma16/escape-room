#!/usr/bin/env python3
"""Level 2 / z3 "Behind the Great Dial" build (batch 3, 2026-07-20).

Base = z3-dial-base-r2 (seed 730303) — chosen over r1 (seed 730301) because r1's
disc geometry made a full in-band mirrored ring geometrically impossible (works
cluster forced ring r>=640 while the iPad 4:3 band forced r<=525). r2 hosts the
ring at r=460 INSIDE its iron glazing ring: all 12 positions on bright glass,
leftmost glyph edge x~1023 >> 640. r1 + its shut-hatch edit -> _rejects.

Deterministic passes (all load-bearing glyphs from l2_glyphs — the model never
draws them):
  1. promote r2 -> canonical z3-dial-base@3x.
  2. erase 4 glazing-bar segments r in [392,505] (radial-clone fill: same-radius
     sampling from clean sectors) — reads as hub cross-bracing + numeral ring +
     outer iron ring.
  3. MIRRORED numeral ring (full 4.2 contract): back position p carries numeral
     (12-p) mirror-flipped (front position k at angle t appears at back -t).
     XII top / VI bottom, flipped letterforms; no legible VII anywhere (mirrored
     VII renders "IIV" by construction). Soft-edged dark silhouettes (glass
     diffusion blur), upright, r=460, glyph h=88. Containment: every glyph bbox
     asserted on glass (inside iron ring, outside hub, off remaining bars) AND
     inside the dual-safe band.
  4. hatch rebuild: erase the 4 generated flat brass discs (plank clone along
     board direction), draw 4 edge-on brass combination thumb-wheels recessed in
     slots along the hatch axis + 4 brass header plates engraved with the
     canonical dies in z3 BINDING order Big Ben (tower+star) | Burj | Liberty |
     Fuji (different from z2 row — forces pictogram matching). Base wheel faces
     show neutral XII / III / VI / IX (not the solution VI-X-I-III).
  5. densities + CUs 20/21/22 (native-res re-stamps where the CU upsamples).
  6. sprites: hour (spade) / minute (plain) hand silhouettes with pivot meta;
     12-position wheel sprite strip (shared by all four wheels).
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral, tint
from l2_z2_build import engrave

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z3 = os.path.join(A2, "z3", "v-dial")
GLY = os.path.join(A2, "masters", "glyphs")
REJ = os.path.join(A2, "_rejects")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")

# iron glazing ring = ELLIPSE fitted from 61 detected ring points (std 1.7%):
ECX, ECY = 1459.8, 889.1    # ellipse center
EA, EB = 464.4, 530.6       # semi-axes (horizontal, vertical)
U_RING = 0.73               # numeral ring at normalized radius u (ring = u 1.0)
GLYPH_H = 88
U_IRON = (0.92, 1.08)       # iron ring band (spared from erase)
HUB_XY, HUB_R = (1522, 878), 195   # works hub exclusion (absolute px)
BAR_X = (1489, 1568)        # vertical bar x-extent
BAR_Y = (807, 913)          # horizontal bar y-extent
INK = (42, 30, 20)


def u_of(x, y):
    return math.hypot((x - ECX) / EA, (y - ECY) / EB)

NUMS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]

# hatch geometry — NB wheel-row edit (seed 730304) composited into the wide;
# canonical glyphs stamped on the GENERATED surfaces (measured rects, @3x):
CROWN_FACES = [  # (x0,y0,x1,y1) flat face panel on each wheel crown
    (2450, 1625, 2525, 1695), (2605, 1680, 2685, 1750),
    (2775, 1730, 2850, 1800), (2945, 1735, 3035, 1815)]
STRIP_RECTS = [  # blank brass header plates above each wheel
    (2595, 1596, 2770, 1639), (2770, 1631, 2940, 1674),
    (2945, 1664, 3110, 1710), (3120, 1696, 3280, 1744)]
# larger header plates drawn over the generated thin strips (cx, cy, w, h):
HEADER_PLATES = [(2682, 1612, 200, 92), (2855, 1648, 194, 92),
                 (3027, 1683, 190, 92), (3148, 1716, 272, 92)]
FACE_ROT, STRIP_ROT = -15, -11
HEADER_DIES = ["bigben", "burj", "liberty", "fuji"]   # z3 binding order (4.3)
BASE_WHEEL_NUMS = ["XII", "III", "VI", "IX"]          # neutral, != solution

CU_W, CU_H = 2048, 1536
CU_FRAMES = {
    "cu-great-dial":   (900, 300, 2596, 1572),
    "cu-winding-drum": (0, 1030, 1187, 1920),
    "cu-hatch-wheels": (2150, 870, 3550, 1920),
}

SAFE_X = (640, 3200)
SAFE_Y = (154, 1766)


# ------------------------------------------------------------ radial fill

def radial_fill(im, seg_mask):
    """Fill masked pixels by sampling glow along the SAME normalized-ellipse
    contour at rotated parametric angles; luminance-guarded (never paints glow
    from dark roof/wall samples); feathered composite edge."""
    a = np.asarray(im, np.float32)
    h, w = a.shape[:2]
    ys, xs = np.nonzero(seg_mask)
    fill = a.copy()
    for y, x in zip(ys, xs):
        u = u_of(x, y)
        if u < 1e-3:
            continue
        phi = math.atan2((y - ECY) / EB, (x - ECX) / EA)
        vals = []
        for dt in (0.16, -0.16, 0.26, -0.26, 0.36, -0.36):
            sx = int(round(ECX + u * EA * math.cos(phi + dt)))
            sy = int(round(ECY + u * EB * math.sin(phi + dt)))
            if 0 <= sx < w and 0 <= sy < h and not seg_mask[sy, sx]:
                v = a[sy, sx]
                if v.mean() > 100:          # glow only, never roof/wall
                    vals.append(v)
        if vals:
            fill[y, x] = np.mean(vals, 0)
    m = Image.fromarray((seg_mask * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(6))
    mf = np.asarray(m, np.float32)[..., None] / 255.0
    out = a * (1 - mf) + fill * mf
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


# per-segment normalized-radius erase ranges (iron ring band spared); outer
# limits stop at each segment's glow boundary (roof/wall/floor/bezel)
SEG_RANGES = {
    "top":    [(0.55, 0.945), (1.055, 1.70)],
    "bottom": [(0.55, 0.945)],                 # bar continues below the ring
    "left":   [(0.55, 0.945), (1.055, 1.80)],  # to the floor = support strut
    "right":  [(0.55, 0.945), (1.055, 1.44)],
}


def bar_segments_mask(size):
    yy, xx = np.mgrid[0:size[1], 0:size[0]]
    uu = np.hypot((xx - ECX) / EA, (yy - ECY) / EB)
    vbar = (xx >= BAR_X[0] - 18) & (xx <= BAR_X[1] + 18)   # +halo margin
    hbar = (yy >= BAR_Y[0] - 18) & (yy <= BAR_Y[1] + 18)
    m = np.zeros((size[1], size[0]), bool)
    for seg, ranges in SEG_RANGES.items():
        if seg == "top":
            region = vbar & (yy < ECY)
        elif seg == "bottom":
            region = vbar & (yy > ECY)
        elif seg == "left":
            region = hbar & (xx < ECX)
        else:
            region = hbar & (xx > ECX)
        for u0, u1 in ranges:
            m |= region & (uu >= u0) & (uu <= u1)
    return m


# ------------------------------------------------------- mirrored ring

def back_position_numeral(p):
    """Back-view position p (clockwise from top) shows numeral (12-p) mod 12."""
    n = (12 - p) % 12
    return NUMS[(n if n != 0 else 12) - 1]


def ring_positions():
    out = []
    for p in range(1, 13):
        ang = math.radians(p * 30 - 90)
        out.append((p, ECX + U_RING * EA * math.cos(ang),
                    ECY + U_RING * EB * math.sin(ang)))
    return out


def assert_glyph_placement(x, y, gw, gh):
    x0, y0, x1, y1 = x - gw / 2, y - gh / 2, x + gw / 2, y + gh / 2
    pts = [(x0, y0), (x1, y0), (x0, y1), (x1, y1)]
    for px, py in pts:
        u = u_of(px, py)
        assert u < U_IRON[0], f"glyph corner ({px:.0f},{py:.0f}) hits iron ring (u={u:.3f})"
        assert math.hypot(px - HUB_XY[0], py - HUB_XY[1]) > HUB_R, \
            "glyph corner inside works hub"
        if BAR_X[0] - 18 <= px <= BAR_X[1] + 18 or BAR_Y[0] - 18 <= py <= BAR_Y[1] + 18:
            assert 0.55 <= u <= 0.92, f"glyph corner on un-erased bar (u={u:.3f})"
    assert SAFE_X[0] <= x0 and x1 <= SAFE_X[1], f"glyph out of iPad band x ({x0:.0f},{x1:.0f})"
    assert SAFE_Y[0] <= y0 and y1 <= SAFE_Y[1], "glyph out of safe band y"


def stamp_ring(layer, scale=1.0, off=(0, 0)):
    """Soft dark mirrored numerals; returns list of (pos, numeral) stamped."""
    ox, oy = off
    placed = []
    for p, x, y in ring_positions():
        n = back_position_numeral(p)
        st = tint(render_numeral(n, 400, mirror=True), INK + (255,))
        gh = GLYPH_H
        gw = st.width * gh / st.height
        if gw > 150:
            gw, gh = 150, gh * 150 / gw
        assert_glyph_placement(x, y, gw, gh)
        sts = st.resize((round(gw * scale), round(gh * scale)), Image.LANCZOS)
        soft = Image.new("RGBA", sts.size, (0, 0, 0, 0))
        soft.alpha_composite(sts)
        soft = soft.filter(ImageFilter.GaussianBlur(1.3 * scale))
        # alpha: silhouette through frosted glass
        r_, g_, b_, a_ = soft.split()
        soft = Image.merge("RGBA", (r_, g_, b_, a_.point(lambda v: v * 205 // 255)))
        layer.alpha_composite(soft, (round((x - ox) * scale - soft.width / 2),
                                     round((y - oy) * scale - soft.height / 2)))
        placed.append((p, n))
    return placed


# --------------------------------------------------------- hatch stamping

def rot_bbox(w, h, deg):
    a = math.radians(abs(deg))
    return (w * math.cos(a) + h * math.sin(a), w * math.sin(a) + h * math.cos(a))


def stamp_hatch(base_rgba, scale=1.0, off=(0, 0)):
    """Engrave canonical numerals on the 4 generated crown faces + canonical
    dies on the 4 generated header plates. Containment asserted vs measured
    surface rects and the dual-safe band."""
    ox, oy = off
    for i in range(4):
        fx0, fy0, fx1, fy1 = CROWN_FACES[i]
        cx, cy = (fx0 + fx1) / 2, (fy0 + fy1) / 2
        n = BASE_WHEEL_NUMS[i]
        st = tint(render_numeral(n, 300), (255, 255, 255, 255))
        gh = 40.0
        gw = st.width * gh / st.height
        if gw > 62:
            gw, gh = 62, gh * 62 / gw
        bw, bh = rot_bbox(gw, gh, FACE_ROT)
        assert fx0 <= cx - bw / 2 and cx + bw / 2 <= fx1 and \
               fy0 <= cy - bh / 2 and cy + bh / 2 <= fy1, \
            f"wheel {i} numeral bbox outside crown face"
        assert SAFE_X[0] <= cx - bw / 2 and cx + bw / 2 <= SAFE_X[1], \
            f"wheel {i} numeral out of iPad band"
        engrave(base_rgba, st, (cx - ox) * scale, (cy - oy) * scale,
                target_h=gh * scale, rot=FACE_ROT, max_w=int(62 * scale),
                ink=(58, 42, 20), hi=(244, 224, 160), ink_a=235,
                hi_a=110, depth=max(2, int(2 * scale)))
        # header die stamped on the GENERATED brass strip (max contrast)
        sx0, sy0, sx1, sy1 = STRIP_RECTS[i]
        dx = (sx0 + sx1) / 2 + [0, 0, 0, -44][i]     # p4 die kept in iPad band
        dy = (sy0 + sy1) / 2 + (dx - (sx0 + sx1) / 2) * math.tan(math.radians(STRIP_ROT))
        die_name = HEADER_DIES[i]
        die = Image.open(os.path.join(GLY, f"die-{die_name}.png")).convert("RGBA")
        ink, hi = (34, 24, 11), (250, 232, 170)
        dh = (sy1 - sy0) * 0.80
        dp = max(1, int(1.2 * scale))
        if die_name == "fuji":
            dw = min(dh * 2.3, 76)
            engrave(base_rgba, die, (dx - ox) * scale, (dy - oy) * scale,
                    target_w=int(dw * scale), rot=STRIP_ROT, ink=ink, hi=hi,
                    ink_a=255, hi_a=70, depth=dp)
            bw = dw
        elif die_name == "bigben":
            engrave(base_rgba, die, (dx - 22 - ox) * scale, (dy - oy) * scale,
                    target_h=int(dh * scale), rot=STRIP_ROT, ink=ink, hi=hi,
                    ink_a=255, hi_a=70, depth=dp)
            from l2_glyphs import die_star
            engrave(base_rgba, die_star(400, (20, 18, 15, 255)),
                    (dx + 20 - ox) * scale, (dy + 4 - oy) * scale,
                    target_h=int(dh * 0.55 * scale), rot=STRIP_ROT, ink=ink,
                    hi=hi, ink_a=255, hi_a=70, depth=dp)
            bw = 78
        else:
            engrave(base_rgba, die, (dx - ox) * scale, (dy - oy) * scale,
                    target_h=int(dh * scale), rot=STRIP_ROT, ink=ink, hi=hi,
                    ink_a=255, hi_a=70, depth=dp)
            bw = max(dh * 0.55, 40)
        assert sx0 - 2 <= dx - bw / 2 and dx + bw / 2 <= sx1 + 2,             f"header {i} die outside plate strip"
        assert SAFE_X[0] <= dx - bw / 2 and dx + bw / 2 <= SAFE_X[1],             f"header {i} die out of iPad band"


# --------------------------------------------------------------- sprites

def build_hand_sprites():
    """Hour (short, spade tip) + minute (long, plain tip) silhouette sprites,
    pivot at arbor. Soft edges (frosted-glass diffusion). Pointing UP (12);
    Developer rotates by mirrored angle -theta per D1."""
    outd = os.path.join(Z3, "sprites")
    os.makedirs(outd, exist_ok=True)
    meta = {}
    for name, length, kind in (("hand-hour", 250, "spade"), ("hand-minute", 380, "plain")):
        L = length
        W = 120
        pad = 40
        Hh = L + 90 + pad
        im = Image.new("RGBA", (W, Hh), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx = W // 2
        py = L + pad          # pivot y (arbor)
        d.line([(cx, py), (cx, py - L * 0.62)], fill=INK + (255,), width=26)
        if kind == "spade":
            tip_y = py - L
            d.polygon([(cx, tip_y), (cx + 34, tip_y + L * 0.30),
                       (cx, tip_y + L * 0.44), (cx - 34, tip_y + L * 0.30)],
                      fill=INK + (255,))
        else:
            d.line([(cx, py - L * 0.55), (cx, py - L)], fill=INK + (255,), width=16)
        d.ellipse([cx - 30, py - 30, cx + 30, py + 30], fill=INK + (255,))
        # counterweight stub
        d.line([(cx, py), (cx, py + 62)], fill=INK + (255,), width=20)
        im = im.filter(ImageFilter.GaussianBlur(1.6))
        r_, g_, b_, a_ = im.split()
        im = Image.merge("RGBA", (r_, g_, b_, a_.point(lambda v: v * 210 // 255)))
        im.save(os.path.join(outd, f"{name}@3x.png"))
        im.resize((W * 2 // 3, Hh * 2 // 3), Image.LANCZOS).save(
            os.path.join(outd, f"{name}@2x.png"))
        im.resize((W // 3, Hh // 3), Image.LANCZOS).save(
            os.path.join(outd, f"{name}@1x.png"))
        meta[name] = {"pivot_px_at_3x": [cx, py], "length_px_at_3x": L,
                      "render_rule": "front angle theta renders at MIRRORED angle -theta (D1); anchor pivot at the works hub arbor (1522,878) in z3-dial-base@3x space; numeral ring is ellipse center (1459.8,889.1) semi-axes (464.4,530.6) at u=0.73"}
    with open(os.path.join(outd, "hand-sprites.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print("hand sprites written")


def build_wheel_strip(blank_wide_rgb):
    """12-position strip: wheel-2's GENERATED blank crown face + canonical
    numeral per frame, at CU22 native scale. JSON records all 4 face rects
    (wide + CU coords) for the Developer's per-element overlays."""
    outd = os.path.join(Z3, "sprites")
    os.makedirs(outd, exist_ok=True)
    x0c, y0c, x1c, y1c = CU_FRAMES["cu-hatch-wheels"]
    scale = CU_W / (x1c - x0c)
    fx0, fy0, fx1, fy1 = CROWN_FACES[1]
    face = blank_wide_rgb.crop((fx0, fy0, fx1, fy1)).resize(
        (int((fx1 - fx0) * scale), int((fy1 - fy0) * scale)), Image.LANCZOS)
    fw, fh = face.size
    strip = Image.new("RGBA", (fw, fh * 12), (0, 0, 0, 0))
    for i, n in enumerate(NUMS):
        fr = face.convert("RGBA")
        st = tint(render_numeral(n, 300), (255, 255, 255, 255))
        gh = 40.0
        gw = st.width * gh / st.height
        if gw > 62:
            gh = gh * 62 / gw
        engrave(fr, st, fw / 2, fh / 2, target_h=gh * scale, rot=FACE_ROT,
                max_w=int(62 * scale), ink=(58, 42, 20), hi=(244, 224, 160),
                ink_a=235, hi_a=110, depth=3)
        strip.alpha_composite(fr, (0, i * fh))
    strip.save(os.path.join(outd, "wheel-strip@3x.png"))
    strip.resize((fw * 2 // 3, fh * 12 * 2 // 3), Image.LANCZOS).save(
        os.path.join(outd, "wheel-strip@2x.png"))
    strip.resize((fw // 3, fh * 12 // 3), Image.LANCZOS).save(
        os.path.join(outd, "wheel-strip@1x.png"))
    meta = {"frame_size_at_3x": [fw, fh], "order": NUMS,
            "crown_face_rects_wide_at_3x": CROWN_FACES,
            "crown_face_rects_cu22_at_3x": [
                [round((r[0] - x0c) * scale), round((r[1] - y0c) * scale),
                 round((r[2] - x0c) * scale), round((r[3] - y0c) * scale)]
                for r in CROWN_FACES],
            "header_dies_left_to_right": HEADER_DIES,
            "base_plate_shows": BASE_WHEEL_NUMS,
            "solution_note": "solution VI-X-I-III set by Developer state; never baked"}
    with open(os.path.join(outd, "wheel-strip.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print("wheel strip written")


# ------------------------------------------------------------------ main

def save_densities(im, out_dir, name, cu=False):
    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, name + "@3x.png"))
    if cu:
        im.resize((1365, 1024), Image.LANCZOS).save(os.path.join(out_dir, name + "@2x.png"))
        im.resize((683, 512), Image.LANCZOS).save(os.path.join(out_dir, name + "@1x.png"))
    else:
        im.resize((2560, 1280), Image.LANCZOS).save(os.path.join(out_dir, name + "@2x.png"))
        im.resize((1280, 640), Image.LANCZOS).save(os.path.join(out_dir, name + "@1x.png"))


def main():
    os.makedirs(REJ, exist_ok=True)
    # 1. archive r1 artifacts, promote r2
    r1_composited = os.path.join(S, "z3-composited@3x.png")
    for tag in ("1x", "2x", "3x"):
        src = os.path.join(Z3, f"z3-dial-base@{tag}.png")
        dst = os.path.join(REJ, f"z3-dial-base-r1-rawgen@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
    if os.path.exists(r1_composited):
        dst = os.path.join(REJ, "z3-dial-base-r1-hatchcomposite@3x.png")
        if not os.path.exists(dst):
            Image.open(r1_composited).save(dst)
    ed = os.path.join(S, "_work", "edit-z3-hatch-shut@3x.png")
    if os.path.exists(ed):
        dst = os.path.join(REJ, "edit-z3-hatch-shut-raw@3x.png")
        if not os.path.exists(dst):
            Image.open(ed).save(dst)
    base = Image.open(os.path.join(S, "_work", "z3-dial-base-r2@3x.png")).convert("RGB")

    # 2. erase bar segments
    mask = bar_segments_mask(base.size)
    base = radial_fill(base, mask)
    print("bar segments erased:", int(mask.sum()), "px")

    # 3. hatch: composite the NB wheel-row edit (registered, feathered,
    #    color-matched — precomputed in scratchpad)
    comp = Image.open(os.path.join(S, "z3-hatchwheels-composited@3x.png")).convert("RGB")
    hb = Image.open(os.path.join(S, "_work", "edit-z3-wheelrow@3x.png"))
    dst = os.path.join(REJ, "edit-z3-wheelrow-raw@3x.png")
    if not os.path.exists(dst):
        hb.save(dst)
    # merge: take the hatch band from comp (comp = bar-unerased base + hatch)
    base_np = np.asarray(base, np.float32)
    comp_np = np.asarray(comp, np.float32)
    band = np.zeros(base_np.shape[:2], np.float32)
    band[1500:1920, 2030:3790] = 1.0
    bm = Image.fromarray((band * 255).astype(np.uint8)).filter(ImageFilter.GaussianBlur(10))
    bmf = np.asarray(bm, np.float32)[..., None] / 255.0
    base = Image.fromarray(np.clip(base_np * (1 - bmf) + comp_np * bmf, 0, 255).astype(np.uint8))

    # 4. integrate: mirrored ring + hatch wheels (wide space)
    rgba = base.convert("RGBA")
    ring_layer = Image.new("RGBA", rgba.size, (0, 0, 0, 0))
    placed = stamp_ring(ring_layer, 1.0, (0, 0))
    rgba.alpha_composite(ring_layer)
    stamp_hatch(rgba, 1.0, (0, 0))
    wide = rgba.convert("RGB")
    save_densities(wide, Z3, "z3-dial-base")
    print("wide integrated; ring:", [(p, n) for p, n in placed])

    # 5. CUs
    for name, (x0, y0, x1, y1) in CU_FRAMES.items():
        s = CU_W / (x1 - x0)
        if name == "cu-great-dial":
            # crop the PRE-ring wide, re-stamp ring at native CU res
            pre = base.convert("RGBA")
            cu = pre.crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS)
            lay = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
            stamp_ring(lay, s, (x0, y0))
            cu.alpha_composite(lay)
        elif name == "cu-hatch-wheels":
            pre = base.convert("RGBA")
            cu = pre.crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS)
            stamp_hatch(cu, s, (x0, y0))
        else:
            cu = wide.convert("RGBA").crop((x0, y0, x1, y1)).resize(
                (CU_W, CU_H), Image.LANCZOS)
        save_densities(cu.convert("RGB"), Z3, name, cu=True)
        print("saved", name)

    # 6. sprites
    build_hand_sprites()
    build_wheel_strip(base)


if __name__ == "__main__":
    main()
