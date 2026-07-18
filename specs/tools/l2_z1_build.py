#!/usr/bin/env python3
"""Level 2 / z1 close-up + glyph-integration build (batch 1 resume, 2026-07-19).

Pipeline (canonical-wide rule):
  Stage A: per-region deterministic edit OVERLAYS computed in each close-up's own
           2048x1536 space (all load-bearing glyphs stamped from l2_glyphs — the
           ONE canonical source; the generative model never re-draws them).
  Stage B: overlays downscaled into the @3x wides -> new canonical wides
           (superseded wides -> _rejects/).
  Stage C: close-ups cropped from the INTEGRATED wides, upscaled to 2048x1536,
           then each CU's own overlay re-composited at native res so the CU is
           crisp AND pixel-consistent with its wide.

Usage: python l2_z1_build.py <stageA|integrate|cus|wheel|coat|all> [region]
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import (render_numeral, render_arabic, die_star,
                       die_house, die_door, die_notch_ring, tint)

SCR = r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim-escape-room\8c048282-9ce7-4b1a-b54a-04e2ba948c25\scratchpad"
WK = os.path.join(SCR, "l2work")
RAW = os.path.join(SCR, "l2raw")
A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z1 = os.path.join(A2, "z1")
os.makedirs(WK, exist_ok=True)

CU_W, CU_H = 2048, 1536
BONE = (232, 228, 218)          # chalk #E8E4DA
RNG = np.random.default_rng(20260719)

# ---- CU frames in wide @3x coords: (wide, x0, y0, x1, y1)  all exact 4:3 ----
FRAMES = {
    "cu-slate":       ("bench",  1230, 300, 2630, 1350),
    "cu-stove-hob":   ("bench",  2320, 1280, 3160, 1910),
    "cu-barometer":   ("bench",  940, 0, 1620, 510),
    "cu-master-face": ("master", 540, 320, 2500, 1790),
    "cu-door-dial":   ("master", 1900, 420, 3260, 1440),
    "cu-crate-straw": ("master", 2380, 1230, 3300, 1920),
    "cu-sill-tile":   ("door",   2135, 875, 2855, 1415),
    "cu-house-ring":  ("door",   1528, 455, 2248, 995),
    "cu-cat-cushion": ("door",   2450, 1085, 3410, 1805),
    "cu-floor-cache": ("door",   1900, 1140, 2940, 1920),
    "cu-timelock":    ("door",   620, 420, 1820, 1320),
}
WIDES = {
    "bench":  os.path.join(Z1, "v-bench", "z1-bench-base@3x.png"),
    "master": os.path.join(Z1, "v-master", "z1-master-base@3x.png"),
    "door":   os.path.join(Z1, "v-door", "z1-door-base@3x.png"),
}


def frame_scale(name):
    _, x0, y0, x1, y1 = FRAMES[name]
    return CU_W / (x1 - x0)


def to_cu(name, x, y):
    """wide @3x coords -> this CU's native 2048x1536 coords."""
    _, x0, y0, _, _ = FRAMES[name]
    s = frame_scale(name)
    return (x - x0) * s, (y - y0) * s


def cu_base(name):
    wide, x0, y0, x1, y1 = FRAMES[name]
    im = Image.open(WIDES[wide]).convert("RGB")
    return im.crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS)


# ------------------------------------------------------------------ helpers

def feather_circle(size, cx, cy, r, feather=6):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=255)
    return m.filter(ImageFilter.GaussianBlur(feather))


def feather_rect(size, box, feather=6):
    m = Image.new("L", size, 0)
    ImageDraw.Draw(m).rectangle(box, fill=255)
    return m.filter(ImageFilter.GaussianBlur(feather))


def paste_masked(base_rgba, patch_rgb, mask, xy=(0, 0)):
    """Composite patch onto base through mask; also OR mask into base alpha."""
    p = patch_rgb.convert("RGBA")
    p.putalpha(mask)
    base_rgba.alpha_composite(p, (int(xy[0]), int(xy[1])))


def engrave(base_rgba, stamp, cx, cy, target_h=None, target_w=None, rot=0.0,
            ink=(48, 34, 20), hi=(240, 216, 160), ink_a=225, hi_a=100, depth=4,
            max_w=None):
    """Engraved glyph: highlight offset below-right (sun from the right) + ink."""
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
        base_rgba.alpha_composite(layer, (round(cx - st.width / 2 + dx),
                                          round(cy - st.height / 2 + dy)))


def quad_warp(stamp, quad, out_size):
    """Map a stamp (full canvas) onto an arbitrary quad (TL,TR,BR,BL) in out space."""
    # PIL QUAD transform maps OUTPUT rect from SOURCE quad; we need forward warp:
    # build via transform of an enlarged canvas using inverse coefficients.
    w, h = stamp.size
    src = [(0, 0), (w, 0), (w, h), (0, h)]
    dst = quad

    def solve(src_pts, dst_pts):
        A = []
        b = []
        for (sx, sy), (dx, dy) in zip(src_pts, dst_pts):
            A.append([sx, sy, 1, 0, 0, 0, -dx * sx, -dx * sy]); b.append(dx)
            A.append([0, 0, 0, sx, sy, 1, -dy * sx, -dy * sy]); b.append(dy)
        return np.linalg.solve(np.array(A, float), np.array(b, float))

    coef = solve(dst, src)  # inverse mapping for PIL PERSPECTIVE
    out = Image.new("RGBA", out_size, (0, 0, 0, 0))
    warped = stamp.transform(out_size, Image.PERSPECTIVE, coef, Image.BICUBIC)
    out.alpha_composite(warped)
    return out


def chalkify(layer_rgba, roughness=0.35, blur=0.5):
    """Give a drawn RGBA layer a chalk-on-slate feel: alpha noise + slight blur."""
    a = np.asarray(layer_rgba.split()[3], dtype=np.float32)
    noise = RNG.uniform(1.0 - roughness, 1.0, a.shape).astype(np.float32)
    # low-freq dropout patches
    low = np.kron(RNG.uniform(0.75, 1.0, (a.shape[0] // 24 + 1, a.shape[1] // 24 + 1)),
                  np.ones((24, 24)))[:a.shape[0], :a.shape[1]]
    a = np.clip(a * noise * low, 0, 255).astype(np.uint8)
    out = layer_rgba.copy()
    out.putalpha(Image.fromarray(a, "L").filter(ImageFilter.GaussianBlur(blur)))
    return out


def sample_median(im, box, exclude_dark=None):
    a = np.asarray(im.crop(box).convert("RGB"), dtype=np.float32).reshape(-1, 3)
    if exclude_dark is not None:
        keep = a.sum(1) > exclude_dark * 3
        if keep.any():
            a = a[keep]
    return tuple(int(v) for v in np.median(a, axis=0))


def radial_rebuild(cu, cx, cy, r_max, seed=7):
    """Rebuild a clean radial-gradient disc from the existing face's band stats."""
    src = np.asarray(cu.convert("RGB"), dtype=np.float32)
    H_, W_ = src.shape[:2]
    yy, xx = np.mgrid[0:H_, 0:W_]
    rr = np.sqrt((xx - cx) ** 2 + (yy - cy) ** 2)
    bands = []
    for k in range(12):
        r0, r1 = r_max * k / 12, r_max * (k + 1) / 12
        m = (rr >= r0) & (rr < r1)
        px = src[m].reshape(-1, 3)
        if len(px) == 0:
            bands.append(bands[-1] if bands else np.array([200, 190, 170.0]))
            continue
        # robust: take the 40-75th percentile band per channel (skip dark marks)
        lum = px.sum(1)
        lo, hi_ = np.percentile(lum, 45), np.percentile(lum, 85)
        sel = px[(lum >= lo) & (lum <= hi_)]
        bands.append(np.median(sel if len(sel) else px, axis=0))
    bands = np.array(bands)
    t = np.clip(rr / r_max * 12, 0, 11.999)
    k0 = t.astype(int)
    frac = (t - k0)[..., None]
    disc = bands[k0] * (1 - frac) + bands[np.minimum(k0 + 1, 11)] * frac
    rng = np.random.default_rng(seed)
    disc = np.clip(disc + rng.normal(0, 2.2, disc.shape), 0, 255).astype(np.uint8)
    return Image.fromarray(disc, "RGB")


# =========================================================== region overlays
# Each returns an RGBA overlay in the host CU's 2048x1536 space.

def ov_slate():
    name = "cu-slate"
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    # slate interior quad in CU coords
    q = [to_cu(name, *p) for p in
         [(1610, 405), (2160, 420), (2220, 1235), (1655, 1255)]]
    # draw the schematic in rectified 720x1000 space, then perspective-warp
    R = Image.new("RGBA", (720, 1000), (0, 0, 0, 0))
    d = ImageDraw.Draw(R)
    W_ = 7  # chalk stroke width

    def circ(c, r, w=W_):
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r],
                  outline=BONE + (255,), width=w)

    def dot(c, r=6):
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=BONE + (255,))

    # 1) crank circle + EXACTLY 24 tally ticks (4 groups of 6, gapped for counting)
    c1, r1 = (190, 155), 95
    circ(c1, r1)
    dot(c1)
    d.line([c1, (c1[0] + 52, c1[1] - 52)], fill=BONE + (255,), width=W_)
    dot((c1[0] + 58, c1[1] - 58), 9)
    n_tally = 0
    for g in range(4):
        for i in range(6):
            ang = math.radians(g * 90 + 12 + i * 13)
            x0 = c1[0] + (r1 + 8) * math.cos(ang)
            y0 = c1[1] + (r1 + 8) * math.sin(ang)
            x1_ = c1[0] + (r1 + 40) * math.cos(ang)
            y1_ = c1[1] + (r1 + 40) * math.sin(ang)
            d.line([(x0, y0), (x1_, y1_)], fill=BONE + (255,), width=5)
            n_tally += 1
    assert n_tally == 24, "slate tally contract"
    # 2) mesh line to pinion XII
    d.line([(258, 218), (430, 292)], fill=BONE + (255,), width=4)
    c2, r2 = (474, 322), 47
    circ(c2, r2)
    # 3) wheel A '?' + coaxial pinion VIII below-left via axis connector
    c3, r3 = (330, 490), 108
    circ(c3, r3)
    dot(c3)
    for t in np.linspace(0.45, 0.9, 4):  # dotted axis to pinion VIII
        p = (c3[0] + (240 - c3[0]) * t, c3[1] + (612 - c3[1]) * t)
        dot(p, 4)
    c4, r4 = (238, 628), 46
    circ(c4, r4)
    # 4) wheel B '?'
    c5, r5 = (430, 762), 108
    circ(c5, r5)
    dot(c5)
    # mesh ticks XII|A and VIII|B
    for a_, b_ in (((410, 380), (438, 408)), ((300, 672), (330, 700))):
        d.line([a_, b_], fill=BONE + (255,), width=4)
        d.line([(a_[0] + 14, a_[1] - 10), (b_[0] + 14, b_[1] - 10)],
               fill=BONE + (255,), width=4)
    # 5) cam circle: dotted axis from wheel B, one notch + door die
    for t in np.linspace(0.5, 0.85, 3):
        dot((c5[0] + (545 - c5[0]) * t, c5[1] + (884 - c5[1]) * t), 4)
    c6, r6 = (552, 886), 55
    circ(c6, r6)
    dot(c6)
    d.polygon([(552 + 55, 886 - 10), (552 + 55, 886 + 10), (552 + 34, 886)],
              fill=(20, 22, 26, 255))  # notch: dark cut INTO the chalk circle
    # question marks (deterministic strokes)
    for cq, hq in ((c3, 84), (c5, 84)):
        qw = hq * 0.62
        bx, by = cq[0], cq[1] - 34
        d.arc([bx - qw / 2, by - hq / 2, bx + qw / 2, by + qw / 2 - hq / 2 + qw / 2],
              start=150, end=60, fill=BONE + (255,), width=W_)
        d.line([(bx + qw * 0.36, by - hq * 0.5 + qw * 0.78),
                (bx, by + hq * 0.12)], fill=BONE + (255,), width=W_)
        dot((bx, by + hq * 0.38), 7)
    # numeral + door stamps in chalk
    ch = tint(render_numeral("XII", 200), BONE + (255,))
    R.alpha_composite(ch.resize((int(ch.width * 40 / ch.height), 40), Image.LANCZOS),
                      (int(c2[0] - ch.width * 40 / ch.height / 2), int(c2[1] - 20)))
    ch = tint(render_numeral("VIII", 200), BONE + (255,))
    R.alpha_composite(ch.resize((int(ch.width * 34 / ch.height), 34), Image.LANCZOS),
                      (int(c4[0] - ch.width * 34 / ch.height / 2), int(c4[1] - 17)))
    dd = tint(die_door(200), BONE + (255,)).resize((62, 62), Image.LANCZOS)
    R.alpha_composite(dd, (int(c6[0] + 70), int(c6[1] - 31)))
    R = chalkify(R)
    ov.alpha_composite(quad_warp(R, q, (CU_W, CU_H)))
    return ov


def ov_stove():
    name = "cu-stove-hob"
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    q = [to_cu(name, *p) for p in
         [(2620, 1480), (2935, 1450), (2970, 1505), (2655, 1540)]]
    # legibility cheat: keep the face's horizontal axis but stretch the vertical
    # 1.45x so the engraved II survives the foreshortening (contract: legible)
    q = [np.array(pt) for pt in q]
    C = sum(q) / 4
    right = (q[1] - q[0] + q[2] - q[3]) / 2
    down = ((q[3] - q[0] + q[2] - q[1]) / 2) * 1.35
    fw, fh = 0.40, 0.72
    C = C - down * 0.10
    qn = [tuple(C - right * fw / 2 - down * fh / 2),
          tuple(C + right * fw / 2 - down * fh / 2),
          tuple(C + right * fw / 2 + down * fh / 2),
          tuple(C - right * fw / 2 + down * fh / 2)]
    st = tint(render_numeral("II", 400), (255, 255, 255, 255))
    canvas = Image.new("RGBA", (st.width + 60, st.height + 60), (0, 0, 0, 0))
    canvas.alpha_composite(st, (30, 30))
    warped = quad_warp(canvas, qn, (CU_W, CU_H))
    a = warped.split()[3]
    for col, alp, dx, dy in (((255, 242, 198), 140, 3, 3), ((92, 64, 30), 205, 0, 0)):
        layer = Image.new("RGBA", (CU_W, CU_H), col + (0,))
        layer.putalpha(a.point(lambda v, m=alp: v * m // 255))
        ov.alpha_composite(layer, (dx, dy))
    return ov


def ov_barometer():
    name = "cu-barometer"
    cu = cu_base(name)
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    cx, cy = to_cu(name, 1277, 265)
    s = frame_scale(name)
    r_face = 132 * s
    # clean cream face rebuilt from band stats (covers pseudo-text + old scales)
    disc = radial_rebuild(cu, cx, cy, r_face + 6, seed=11)
    paste_masked(ov, disc, feather_circle((CU_W, CU_H), cx, cy, r_face, 5))
    d = ImageDraw.Draw(ov)
    ink = (104, 76, 42, 235)
    # fine tick ring: 48 ticks, every 4th longer
    for k in range(48):
        ang = math.radians(k * 7.5 - 90)
        rr0 = r_face * 0.78 if k % 4 else r_face * 0.72
        rr1 = r_face * 0.88
        d.line([(cx + rr0 * math.cos(ang), cy + rr0 * math.sin(ang)),
                (cx + rr1 * math.cos(ang), cy + rr1 * math.sin(ang))],
               fill=ink, width=3 if k % 4 else 5)
    # pictograms: rain (left) / cloud (top) / sun (right) — weather, "not a clock"
    def cloud(ccx, ccy, sc, with_rain=False):
        for ex, ey, er, a0, a1 in ((-0.32, 0.1, 0.30, 95, 305), (0.0, -0.14, 0.38, 175, 355),
                                   (0.34, 0.12, 0.28, 235, 85)):
            d.arc([ccx + (ex - er) * sc, ccy + (ey - er) * sc,
                   ccx + (ex + er) * sc, ccy + (ey + er) * sc],
                  start=a0, end=a1, fill=ink, width=5)
        d.line([(ccx - 0.55 * sc, ccy + 0.36 * sc), (ccx + 0.55 * sc, ccy + 0.36 * sc)],
               fill=ink, width=5)
        if with_rain:
            for i in range(3):
                x0 = ccx - 0.3 * sc + i * 0.3 * sc
                d.line([(x0, ccy + 0.5 * sc), (x0 - 0.12 * sc, ccy + 0.78 * sc)],
                       fill=ink, width=5)

    r_pic = r_face * 0.52
    cloud(cx - r_pic, cy + r_face * 0.1, r_face * 0.30, with_rain=True)
    cloud(cx, cy - r_pic * 1.05, r_face * 0.30)
    scx, scy, sr = cx + r_pic, cy + r_face * 0.1, r_face * 0.14
    d.ellipse([scx - sr, scy - sr, scx + sr, scy + sr], outline=ink, width=5)
    for k in range(8):
        ang = math.radians(k * 45)
        d.line([(scx + (sr + 6) * math.cos(ang), scy + (sr + 6) * math.sin(ang)),
                (scx + (sr + 18) * math.cos(ang), scy + (sr + 18) * math.sin(ang))],
               fill=ink, width=4)
    # fixed needle toward fair/sun (upper right), counterweight lower-left
    ang = math.radians(-52)
    steel = (48, 47, 52, 255)
    L = r_face * 0.66
    px, py = -math.sin(ang), math.cos(ang)
    tipx, tipy = cx + L * math.cos(ang), cy + L * math.sin(ang)
    d.polygon([(cx + px * 9, cy + py * 9), (cx - px * 9, cy - py * 9),
               (tipx, tipy)], fill=steel)
    bx, by = cx - 0.3 * L * math.cos(ang), cy - 0.3 * L * math.sin(ang)
    d.line([(cx, cy), (bx, by)], fill=steel, width=10)
    d.ellipse([bx - 14, by - 14, bx + 14, by + 14], fill=steel)
    boss = sample_median(cu, (int(cx) - 12, int(cy) - 12, int(cx) + 12, int(cy) + 12))
    d.ellipse([cx - 15, cy - 15, cx + 15, cy + 15], fill=boss + (255,))
    d.arc([cx - 13, cy - 13, cx + 13, cy + 13], start=190, end=300,
          fill=(255, 240, 205, 120), width=3)
    return ov


def detect_disc(img, cx0, cy0, r0):
    """Refine a pale-disc circle estimate: threshold pale pixels near estimate."""
    a = np.asarray(img.convert("RGB"), dtype=np.int16)
    yy, xx = np.mgrid[0:a.shape[0], 0:a.shape[1]]
    near = (xx - cx0) ** 2 + (yy - cy0) ** 2 < (r0 * 1.15) ** 2
    pale = (a[:, :, 0] > 150) & (a[:, :, 2] > 105) & near
    ys, xs = np.where(pale)
    cx, cy = xs.mean(), ys.mean()
    r = math.sqrt(len(xs) / math.pi)
    return cx, cy, r


def dark_centroid(img, cx0, cy0, win=45):
    a = np.asarray(img.convert("RGB"), dtype=np.int16)
    x0, y0 = int(cx0 - win), int(cy0 - win)
    sub = a[y0:y0 + 2 * win, x0:x0 + 2 * win]
    m = sub.sum(2) < np.percentile(sub.sum(2), 25)
    ys, xs = np.where(m)
    return x0 + xs.mean(), y0 + ys.mean()


def clockpos(cx, cy, r, k):
    ang = math.radians(k * 30 - 90)
    return cx + r * math.cos(ang), cy + r * math.sin(ang)


def noisy_fill(size, rgb, sigma=4.0):
    base = np.full((size[1], size[0], 3), rgb, np.float32)
    base += RNG.normal(0, sigma, base.shape)
    return Image.fromarray(base.clip(0, 255).astype(np.uint8))


def ov_master_face():
    name = "cu-master-face"
    cu = cu_base(name)
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    cx, cy = to_cu(name, 1470, 505)
    R = 118 * frame_scale(name)
    disc = radial_rebuild(cu, cx, cy, R + 4, seed=13)
    paste_masked(ov, disc, feather_circle((CU_W, CU_H), cx, cy, R - 1, 3))
    d = ImageDraw.Draw(ov)
    ink = (62, 46, 32, 235)
    for k in range(60):
        ang = math.radians(k * 6 - 90)
        rr0 = R * 0.855 if k % 5 else R * 0.815
        rr1 = R * 0.935
        d.line([(cx + rr0 * math.cos(ang), cy + rr0 * math.sin(ang)),
                (cx + rr1 * math.cos(ang), cy + rr1 * math.sin(ang))],
               fill=ink, width=4 if k % 5 == 0 else 2)
    for k in range(1, 13):
        num = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII",
               "IX", "X", "XI", "XII"][k - 1]
        nx, ny = clockpos(cx, cy, R * 0.70, k)
        st = tint(render_numeral(num, 200), (44, 34, 26, 255))
        engrave(ov, st, nx, ny, target_h=int(R * 0.20), rot=-k * 30,
                max_w=int(R * 0.42), ink=(44, 34, 26), hi=(250, 240, 220),
                ink_a=235, hi_a=60, depth=2)
    steel = (52, 44, 38, 255)
    d.polygon([(cx - 6, cy), (cx + 6, cy), (cx + 3, cy - R * 0.80),
               (cx - 3, cy - R * 0.80)], fill=steel)
    d.polygon([(cx - 7, cy), (cx + 7, cy), (cx + 3.5, cy + R * 0.42),
               (cx - 3.5, cy + R * 0.42)], fill=steel)
    hy = cy + R * 0.44
    d.polygon([(cx, hy - 8), (cx + 13, hy + R * 0.10), (cx, hy + R * 0.20),
               (cx - 13, hy + R * 0.10)], fill=steel)
    d.ellipse([cx - 11, cy - 11, cx + 11, cy + 11], fill=(74, 60, 44, 255))
    d.ellipse([cx - 5, cy - 5, cx + 5, cy + 5], fill=steel)
    sx, sy = to_cu(name, 1457, 1597)
    wood = sample_median(cu, (int(sx - 150), int(sy - 40), int(sx - 70), int(sy + 40)))
    paste_masked(ov, noisy_fill((CU_W, CU_H), wood, 3.5),
                 feather_circle((CU_W, CU_H), sx, sy, 62, 8))
    engrave(ov, die_star(400, (30, 22, 16, 255)), sx, sy, target_h=96,
            ink=(38, 28, 20), hi=(196, 162, 118), ink_a=210, hi_a=95, depth=4)
    return ov


def ov_door_dial():
    name = "cu-door-dial"
    cu = cu_base(name)
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    # disc geometry probe-verified in CU space (yellow-circle check)
    ocx, ocy, faceR = 994.0, 557.0, 373.5
    ringR = 176 * frame_scale(name)
    # --- 1) clean disc face from the NB edit, geometry+tone matched -----------
    nb = Image.open(os.path.join(RAW, "dial-disc-clean-raw@3x.png")).convert("RGB")
    a = np.asarray(nb, np.int16)
    yy, xx = np.mgrid[0:nb.height, 0:nb.width]
    near = (xx - ocx) ** 2 + (yy - ocy) ** 2 < (faceR * 1.05) ** 2
    pale = (a[:, :, 0] > 170) & (a[:, :, 2] > 120) &            ((a[:, :, 0] - a[:, :, 2]) > 25) & ((a[:, :, 0] - a[:, :, 2]) < 95) & near
    ys, xs = np.where(pale)
    ncx, ncy = float(np.median(xs)), float(np.median(ys))
    nrr = math.sqrt(len(xs) / math.pi)
    if abs(ncx - ocx) > 45 or abs(ncy - ocy) > 45 or abs(nrr - faceR) > 40:
        ncx, ncy, nrr = 984.0, 566.0, 375.0   # visual fallback
    sc = faceR / nrr
    nb2 = nb.resize((round(nb.width * sc), round(nb.height * sc)), Image.LANCZOS)
    canvas = Image.new("RGB", (CU_W, CU_H), (0, 0, 0))
    canvas.paste(nb2, (round(ocx - ncx * sc), round(ocy - ncy * sc)))

    def stats(img):
        arr_ = np.asarray(img.convert("RGB"), np.float32)
        yy2, xx2 = np.mgrid[0:CU_H, 0:CU_W]
        rr2 = (xx2 - ocx) ** 2 + (yy2 - ocy) ** 2
        m = (rr2 < (faceR * 0.40) ** 2) & (rr2 > (faceR * 0.10) ** 2)
        return arr_[m].mean(0), arr_[m].std(0) + 1e-3

    mo, so = stats(cu)
    mn, sn = stats(canvas)
    arr = np.asarray(canvas, np.float32)
    arr = (arr - mn) * np.minimum(so / sn, 1.6) + mo
    canvas = Image.fromarray(arr.clip(0, 255).astype(np.uint8))
    paste_masked(ov, canvas, feather_circle((CU_W, CU_H), ocx, ocy, faceR - 8, 8))
    # --- 2) empty sockets at 2/4/7/11 from a donor hole -----------------------
    dhx, dhy = dark_centroid(cu, *clockpos(ocx, ocy, ringR, 3), win=52)
    hole = cu.crop((int(dhx - 76), int(dhy - 76), int(dhx + 76), int(dhy + 76)))
    hmask = feather_circle((152, 152), 76, 76, 66, 6)
    for k in (2, 4, 7, 11):
        px, py = clockpos(ocx, ocy, ringR, k)
        h2 = hole.convert("RGBA")
        h2.putalpha(hmask)
        ov.alpha_composite(h2, (round(px - 76), round(py - 76)))
    # --- 3) seated tiles at I III V VI VIII IX X XII + canonical stamps -------
    dtx, dty = 975, 292
    bwin = np.asarray(cu.crop((dtx - 80, dty - 80, dtx + 80, dty + 80)).convert("RGB"),
                      np.int16)
    bm = (bwin[:, :, 0] > 150) & (bwin[:, :, 0] - bwin[:, :, 2] > 55)
    ys2, xs2 = np.where(bm)
    dtx, dty = dtx - 80 + xs2.mean(), dty - 80 + ys2.mean()
    tile = cu.crop((int(dtx - 82), int(dty - 82), int(dtx + 82), int(dty + 82)))
    # locate + cover the generative emblem on the donor face
    ex, ey = dark_centroid(tile, 82, 82, win=40)
    ring_box = (int(ex - 52), int(ey - 52), int(ex - 36), int(ey - 36))
    brass = sample_median(tile, ring_box)
    tile.paste(noisy_fill(tile.size, brass, 4), (0, 0),
               feather_circle(tile.size, ex, ey, 34, 5))
    tmask = feather_rect(tile.size, (10, 10, 154, 154), 7)
    seat_rot = {1: 2.0, 3: -1.5, 5: 1.0, 6: -2.0, 8: 1.8, 9: -1.0, 10: 2.4, 12: 0.0}
    for k, num in ((1, "I"), (3, "III"), (5, "V"), (6, "VI"), (8, "VIII"),
                   (9, "IX"), (10, "X"), (12, "XII")):
        px, py = clockpos(ocx, ocy, ringR, k)
        t2 = tile.rotate(seat_rot[k], resample=Image.BICUBIC)
        t2 = t2.convert("RGBA")
        t2.putalpha(tmask.rotate(seat_rot[k], resample=Image.BICUBIC))
        ov.alpha_composite(t2, (round(px - 82), round(py - 82)))
        st = tint(render_numeral(num, 200), (255, 255, 255, 255))
        engrave(ov, st, px, py, target_h=52, rot=seat_rot[k], max_w=96,
                ink=(74, 50, 22), hi=(255, 236, 178), ink_a=225, hi_a=110, depth=3)
    # --- 4) tray: remove flat object; VI on the one leaning tile (measured) ---
    donor = cu.crop((630, 1178, 775, 1238))
    cover = Image.new("RGB", (145, 60))
    cover.paste(donor, (0, 0))
    paste_masked(ov, cover.resize((145, 60)),
                 feather_rect((145, 60), (5, 5, 140, 55), 4), (795, 1178))
    ex2, ey2 = dark_centroid(cu, 1128, 1186, win=30)
    brass2 = sample_median(cu, (int(ex2) - 48, int(ey2) - 44,
                                int(ex2) - 30, int(ey2) - 26))
    paste_masked(ov, noisy_fill((80, 80), brass2, 4),
                 feather_circle((80, 80), 40, 40, 31, 4), (ex2 - 40, ey2 - 40))
    engrave(ov, tint(render_numeral("VI", 200), (255, 255, 255, 255)),
            1135, 1191, target_h=46, rot=-6, max_w=76, ink=(74, 50, 22),
            hi=(255, 236, 178), ink_a=225, hi_a=110, depth=3)
    # --- 5) D8: keyhole patched out (vertical lerp), bottom screw preserved ---
    kx0, ky0, kx1, ky1 = 548, 1068, 598, 1140
    a2 = np.asarray(cu.convert("RGB"), np.float32)
    top = a2[ky0 - 4:ky0, kx0:kx1].mean(0)
    bot = a2[ky1:ky1 + 4, kx0:kx1].mean(0)
    fill = np.array([top * (1 - t) + bot * t
                     for t in np.linspace(0, 1, ky1 - ky0)])
    fill += RNG.normal(0, 2.5, fill.shape)
    fp = Image.fromarray(fill.clip(0, 255).astype(np.uint8))
    paste_masked(ov, fp,
                 feather_rect(fp.size, (3, 3, fp.width - 3, fp.height - 3), 3),
                 (kx0, ky0))
    return ov


def ov_crate():
    name = "cu-crate-straw"
    cu = cu_base(name)
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    # tile face quad measured directly in CU space (probe-crate2)
    q = [np.array(p, float) for p in
         [(880, 1092), (1090, 1042), (1180, 1160), (965, 1270)]]
    C = sum(q) / 4
    # cover the generative circular recess with face brass
    brass = sample_median(cu, (1125, 1078, 1165, 1108))
    paste_masked(ov, noisy_fill((220, 220), brass, 4),
                 feather_circle((220, 220), 110, 110, 96, 6), (1038 - 110, 1148 - 110))
    paste_masked(ov, noisy_fill((120, 120), brass, 4),
                 feather_circle((120, 120), 60, 60, 50, 6), (1128 - 60, 1140 - 60))
    # engrave VII (legibility cheat), placed slightly up-right on the face
    right = (q[1] - q[0] + q[2] - q[3]) / 2
    down = ((q[3] - q[0] + q[2] - q[1]) / 2) * 1.30
    Cn = C + right * 0.04 - down * 0.06
    fw, fh = 0.58, 0.60
    qn = [tuple(Cn - right * fw / 2 - down * fh / 2),
          tuple(Cn + right * fw / 2 - down * fh / 2),
          tuple(Cn + right * fw / 2 + down * fh / 2),
          tuple(Cn - right * fw / 2 + down * fh / 2)]
    st = tint(render_numeral("VII", 400), (255, 255, 255, 255))
    canvas = Image.new("RGBA", (st.width + 60, st.height + 60), (0, 0, 0, 0))
    canvas.alpha_composite(st, (30, 30))
    warped = quad_warp(canvas, qn, (CU_W, CU_H))
    wa = warped.split()[3]
    for col, alp, ddx, ddy in (((255, 242, 198), 135, 3, 3), ((92, 64, 30), 205, 0, 0)):
        layer = Image.new("RGBA", (CU_W, CU_H), col + (0,))
        layer.putalpha(wa.point(lambda v, m=alp: v * m // 255))
        ov.alpha_composite(layer, (ddx, ddy))
    # straw half-bury: clone straw over the tile lower-left corner only
    straw = cu.crop((500, 1150, 800, 1360))
    blob = Image.new("L", straw.size, 0)
    bd = ImageDraw.Draw(blob)
    bcx, bcy = straw.width * 0.5, straw.height * 0.5
    ptc = []
    for i in range(24):
        ang = i / 24 * 2 * math.pi
        rr = 92 * (0.72 + 0.38 * RNG.random())
        ptc.append((bcx + rr * math.cos(ang), bcy + rr * 0.68 * math.sin(ang)))
    bd.polygon(ptc, fill=255)
    blob = blob.filter(ImageFilter.GaussianBlur(5))
    paste_masked(ov, straw, blob, (950 - bcx, 1252 - bcy))
    return ov


def ov_house_ring():
    """Replace the drifted gear/leaf carving with the canonical house die +
    12-notch ring (SAME dies as watch A's inner lid — the binding is the match)."""
    name = "cu-house-ring"
    cu = cu_base(name)
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    cx, cy = to_cu(name, 1888, 725)
    s = frame_scale(name)
    cover_r = 95 * s
    # clone post wood from above the mark (vertical grain) over the old carving
    x0, x1 = int(cx - cover_r - 8), int(cx + cover_r + 8)
    strip = cu.crop((x0, int(cy - cover_r - 300), x1, int(cy - cover_r - 40)))
    tile_h = strip.height
    patch = Image.new("RGB", (x1 - x0, int(2 * cover_r + 16)))
    yy = 0
    flip = False
    while yy < patch.height:
        src = strip.transpose(Image.FLIP_TOP_BOTTOM) if flip else strip
        patch.paste(src, (0, yy))
        yy += tile_h
        flip = not flip
    paste_masked(ov, patch, feather_circle(patch.size, patch.width / 2,
                                           patch.height / 2, cover_r, 10),
                 (x0, cy - cover_r - 8))
    # engrave canonical ring + house (sun from frame right -> highlight low-right)
    ring = die_notch_ring(400, 12, color=(30, 22, 16, 255))
    engrave(ov, ring, cx, cy, target_h=int(150 * s), ink=(44, 30, 18),
            hi=(226, 188, 138), ink_a=215, hi_a=95, depth=5)
    house = die_house(400, (30, 22, 16, 255))
    engrave(ov, house, cx, cy, target_h=int(62 * s), ink=(44, 30, 18),
            hi=(226, 188, 138), ink_a=215, hi_a=95, depth=5)
    return ov


def ov_sill_tile():
    """Canonical XI engraved into the sill tile's circular field."""
    name = "cu-sill-tile"
    cu = cu_base(name)
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    cx, cy = to_cu(name, 2472, 1072)
    st = tint(render_numeral("XI", 200), (255, 255, 255, 255))
    engrave(ov, st, cx, cy, target_h=120, rot=-2, max_w=190,
            ink=(96, 66, 30), hi=(255, 246, 210), ink_a=200, hi_a=120, depth=4)
    return ov


def ov_cat():
    """F3: recolor the too-pale cat toward gray-blue #8C8C90, keep warm sun rim."""
    name = "cu-cat-cushion"
    cu = cu_base(name)
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    a = np.asarray(cu.convert("RGB"), np.int16)
    yy, xx = np.mgrid[0:CU_H, 0:CU_W]
    x0, y0 = to_cu(name, 2700, 1188)
    x1, y1 = to_cu(name, 3185, 1390)
    inbox = (xx > x0) & (xx < x1) & (yy > y0) & (yy < y1)
    warm = a[:, :, 0] - a[:, :, 2]
    val = a.mean(2)
    catmask = inbox & (warm < 34) & (val > 100)
    m = Image.fromarray((catmask * 255).astype(np.uint8), "L")
    m = m.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.GaussianBlur(2.5))
    rec = a.astype(np.float32)
    rec[:, :, 0] *= 0.705
    rec[:, :, 1] *= 0.705
    rec[:, :, 2] *= 0.775
    recolored = Image.fromarray(rec.clip(0, 255).astype(np.uint8), "RGB")
    paste_masked(ov, recolored, m)
    return ov


REGIONS_A = {"cu-slate": ov_slate, "cu-stove-hob": ov_stove,
             "cu-barometer": ov_barometer, "cu-master-face": ov_master_face,
             "cu-door-dial": ov_door_dial, "cu-crate-straw": ov_crate,
             "cu-house-ring": ov_house_ring, "cu-sill-tile": ov_sill_tile,
             "cu-cat-cushion": ov_cat}


OUT_DIR = {
    "cu-slate": "v-bench", "cu-stove-hob": "v-bench", "cu-barometer": "v-bench",
    "cu-coat-pockets": "v-bench",
    "cu-master-face": "v-master", "cu-door-dial": "v-master",
    "cu-crate-straw": "v-master",
    "cu-sill-tile": "v-door", "cu-house-ring": "v-door",
    "cu-cat-cushion": "v-door", "cu-floor-cache": "v-door", "cu-timelock": "v-door",
}


def save_densities(im, out_dir, name):
    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, name + "@3x.png"))
    im.resize((1365, 1024), Image.LANCZOS).save(os.path.join(out_dir, name + "@2x.png"))
    im.resize((683, 512), Image.LANCZOS).save(os.path.join(out_dir, name + "@1x.png"))
    print("saved", name)


def build_overlays():
    for name, fn in REGIONS_A.items():
        ov = fn()
        ov.save(os.path.join(WK, f"ov-{name}.png"))
        print("overlay", name)


def integrate():
    """Stage B: composite every region overlay (downscaled) into its @3x wide.
    Superseded wides -> _rejects/<name>-preglyph@*.png (canonical-filename rule)."""
    host = {}
    for name in REGIONS_A:
        host.setdefault(FRAMES[name][0], []).append(name)
    rej = os.path.join(A2, "_rejects")
    os.makedirs(rej, exist_ok=True)
    for wide, names in host.items():
        wpath = WIDES[wide]
        base_dir = os.path.dirname(wpath)
        stem = os.path.basename(wpath).replace("@3x.png", "")
        im = Image.open(wpath).convert("RGBA")
        for name in names:
            _, x0, y0, x1, y1 = FRAMES[name]
            ov = Image.open(os.path.join(WK, f"ov-{name}.png"))
            ovs = ov.resize((x1 - x0, y1 - y0), Image.LANCZOS)
            im.alpha_composite(ovs, (x0, y0))
        # archive old canonical set, then write new canonical set
        for tag in ("1x", "2x", "3x"):
            src = os.path.join(base_dir, f"{stem}@{tag}.png")
            dst = os.path.join(rej, f"{stem}-preglyph@{tag}.png")
            if os.path.exists(src) and not os.path.exists(dst):
                os.replace(src, dst)
        out = im.convert("RGB")
        out.save(os.path.join(base_dir, f"{stem}@3x.png"))
        out.resize((2560, 1280), Image.LANCZOS).save(
            os.path.join(base_dir, f"{stem}@2x.png"))
        out.resize((1280, 640), Image.LANCZOS).save(
            os.path.join(base_dir, f"{stem}@1x.png"))
        print("integrated wide", wide, "->", stem)


def build_cus():
    """Stage C: crop CU frames from the INTEGRATED wides, re-composite each CU's
    own overlay at native res, save @3x/@2x/@1x."""
    for name in FRAMES:
        wide, x0, y0, x1, y1 = FRAMES[name]
        im = Image.open(WIDES[wide]).convert("RGB")
        cu = im.crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS)
        ovp = os.path.join(WK, f"ov-{name}.png")
        if name in REGIONS_A and os.path.exists(ovp):
            cu = cu.convert("RGBA")
            cu.alpha_composite(Image.open(ovp))
            cu = cu.convert("RGB")
        save_densities(cu, os.path.join(Z1, OUT_DIR[name]), name)


def build_coat():
    """cu-coat-pockets: NB raw (tone verified vs wide) + canonical IV stamp."""
    cu = Image.open(os.path.join(RAW, "cu-coat-pockets-raw@3x.png")).convert("RGBA")
    st = tint(render_numeral("IV", 200), (255, 255, 255, 255))
    engrave(cu, st, 655, 645, target_h=108, rot=-8, max_w=170,
            ink=(70, 48, 24), hi=(255, 235, 185), ink_a=215, hi_a=110, depth=4)
    save_densities(cu.convert("RGB"), os.path.join(Z1, "v-bench"), "cu-coat-pockets")


def build_wheel():
    """inv-great-wheel: deterministic bronze gear, EXACTLY 64 teeth, '64' stamp,
    square arbor hole, open spoke windows (RGBA cutout)."""
    S = 2
    W_ = 1024 * S
    c = W_ / 2
    r_tip, r_root, r_rim_in = 500 * S, 464 * S, 396 * S
    r_hub = 158 * S
    teeth = 64
    # ---- silhouette mask: rim annulus + teeth + 4 spokes + hub ---------------
    sil = Image.new("L", (W_, W_), 0)
    d = ImageDraw.Draw(sil)
    d.ellipse([c - r_root, c - r_root, c + r_root, c + r_root], fill=255)
    n_drawn = 0
    for k in range(teeth):
        a = 2 * math.pi * k / teeth
        half = math.pi / teeth * 0.46
        pts = []
        for da, rr in ((-half, r_root - 6 * S), (-half * 0.66, r_tip),
                       (half * 0.66, r_tip), (half, r_root - 6 * S)):
            pts.append((c + rr * math.cos(a + da), c + rr * math.sin(a + da)))
        d.polygon(pts, fill=255)
        n_drawn += 1
    assert n_drawn == 64, "tooth-count contract"
    # open windows between spokes
    d.ellipse([c - r_rim_in, c - r_rim_in, c + r_rim_in, c + r_rim_in], fill=0)
    for k in range(4):
        a = math.pi / 4 + k * math.pi / 2
        px, py = -math.sin(a), math.cos(a)
        w_in, w_out = 40 * S, 58 * S
        x0_, y0_ = c, c
        x1_, y1_ = c + (r_rim_in + 14 * S) * math.cos(a), c + (r_rim_in + 14 * S) * math.sin(a)
        d.polygon([(x0_ + px * w_in, y0_ + py * w_in), (x1_ + px * w_out, y1_ + py * w_out),
                   (x1_ - px * w_out, y1_ - py * w_out), (x0_ - px * w_in, y0_ - py * w_in)],
                  fill=255)
    d.ellipse([c - r_hub, c - r_hub, c + r_hub, c + r_hub], fill=255)
    sq = 60 * S
    d.rectangle([c - sq, c - sq, c + sq, c + sq], fill=0)   # square arbor hole
    # ---- bronze shading --------------------------------------------------------
    yy, xx = np.mgrid[0:W_, 0:W_]
    rr = np.sqrt((xx - c) ** 2 + (yy - c) ** 2)
    theta = np.arctan2(yy - c, xx - c)
    rng = np.random.default_rng(64)
    bins = 4096
    ang1d = rng.normal(0, 1, bins)
    kern = np.exp(-0.5 * (np.arange(-25, 26) / 9.0) ** 2)
    ang1d = np.convolve(ang1d, kern / kern.sum(), mode="same")
    brushed = ang1d[((theta + math.pi) / (2 * math.pi) * (bins - 1)).astype(int)]
    ldir = ((xx - c) * 0.707 - (yy - c) * 0.707) / r_tip
    base = np.array([138, 111, 62], np.float32)
    shade = (1.0 + 0.17 * ldir - 0.16 * (rr / r_tip) ** 2.2 + 0.05 * brushed)
    lowf = rng.uniform(-0.045, 0.045, (33, 33))
    lowfi = np.asarray(Image.fromarray(((lowf + 1) * 127).astype(np.uint8), "L")
                       .resize((W_, W_), Image.BILINEAR), np.float32) / 127 - 1
    shade *= (1 + 0.5 * lowfi)
    rgb = np.clip(base[None, None, :] * shade[..., None], 0, 255)
    # darker rim band + hub delineation
    band = (rr > r_rim_in) & (rr < r_root)
    rgb[band] *= 0.90
    im = Image.fromarray(
        np.dstack([rgb.astype(np.uint8), np.asarray(sil, np.uint8)]), "RGBA")
    d = ImageDraw.Draw(im)
    # bevel highlights / AO
    d.ellipse([c - r_root, c - r_root, c + r_root, c + r_root],
              outline=(206, 176, 112, 150), width=3 * S)
    d.ellipse([c - r_rim_in, c - r_rim_in, c + r_rim_in, c + r_rim_in],
              outline=(62, 47, 25, 180), width=4 * S)
    d.ellipse([c - r_hub, c - r_hub, c + r_hub, c + r_hub],
              outline=(62, 47, 25, 140), width=3 * S)
    d.arc([c - r_hub + 2 * S, c - r_hub + 2 * S, c + r_hub - 2 * S, c + r_hub - 2 * S],
          start=200, end=340, fill=(214, 184, 122, 160), width=4 * S)
    d.rectangle([c - sq, c - sq, c + sq, c + sq],
                outline=(45, 34, 18, 255), width=6 * S)
    d.line([(c - sq, c + sq), (c + sq, c + sq)],
           fill=(214, 184, 122, 140), width=4 * S)
    # canonical '64' stamp on the hub above the arbor hole
    st = tint(render_arabic("64", 200), (255, 255, 255, 255))
    engrave(im, st, c, c - (sq + r_hub) / 2 - 6 * S, target_h=54 * S,
            ink=(52, 39, 20), hi=(214, 184, 122), ink_a=225, hi_a=130, depth=4 * S)
    im = im.resize((1024, 1024), Image.LANCZOS)
    out = os.path.join(Z1, "icons")
    im.save(os.path.join(out, "inv-great-wheel@3x.png"))
    im.resize((683, 683), Image.LANCZOS).save(
        os.path.join(out, "inv-great-wheel@2x.png"))
    im.resize((341, 341), Image.LANCZOS).save(
        os.path.join(out, "inv-great-wheel@1x.png"))
    print("great wheel saved (64 teeth asserted)")


def montage():
    """z1 review sheet: 3 wides + 12 CUs at thumbnail size."""
    names = list(FRAMES) + ["cu-coat-pockets"]
    tiles = []
    for wide in ("bench", "master", "door"):
        tiles.append(("WIDE " + wide, Image.open(WIDES[wide]).resize((960, 480))))
    for name in names:
        p = os.path.join(Z1, OUT_DIR[name], name + "@1x.png")
        tiles.append((name, Image.open(p).resize((640, 480))))
    cols = 3
    rows = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * 980, rows * 520), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    for i, (label, im) in enumerate(tiles):
        x = (i % cols) * 980 + 10
        y = (i // cols) * 520 + 10
        sheet.paste(im.convert("RGB"), (x, y))
        dd.text((x + 4, y + 484), label, fill=(230, 225, 210))
    sheet.save(os.path.join(Z1, "z1-review-batch1.png"))
    print("montage saved", sheet.size)


def main():
    what = sys.argv[1] if len(sys.argv) > 1 else "stageA"
    only = sys.argv[2] if len(sys.argv) > 2 else None
    if what == "stageA":
        for name, fn in REGIONS_A.items():
            if only and name != only:
                continue
            ov = fn()
            ov.save(os.path.join(WK, f"ov-{name}.png"))
            prev = cu_base(name).convert("RGBA")
            prev.alpha_composite(ov)
            prev.convert("RGB").save(os.path.join(WK, f"prev-{name}.png"))
            print("overlay", name)
    elif what == "integrate":
        integrate()
    elif what == "cus":
        build_cus()
    elif what == "coat":
        build_coat()
    elif what == "wheel":
        build_wheel()
    elif what == "montage":
        montage()


if __name__ == "__main__":
    main()
