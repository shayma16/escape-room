#!/usr/bin/env python3
"""Batch-4 carry-in fix (user verdict 2026-07-20): hatch thumb-wheel numerals
must CONFORM to each wheel's cylindrical curvature + perspective.

Defect: batch-3 stamped XII/III/VI/IX flat (screen-upright, single -15 deg
rotation, no warp) onto the curved crown-face plates of the four hatch wheels —
they read as floating decals and overhang the plate edges.

Surface model per wheel (screen space, wide @3x), measured from the blank
pre-stamp plate (each wheel carries a raised, gently-bowed rectangular crown
plate on its camera-facing flank; the plate's edges give the local surface
frame):
    axial dir   alpha  — baseline direction of engraved text (plate top edge)
    circum dir  gamma  — glyph vertical direction (plate side edge; leans left)
    bow         beta   — cylindrical tangent sweep across the glyph height
                         (the plate wraps the drum; verticals bow)
    P(u,v) = path(v) + (u - 0.5) * gw * (cos a, sin a)
    path(v) = C + integral_{0.5}^{v} gh * (cos g(s), sin g(s)) ds,
    g(s) = gamma + beta * (0.5 - s)
Rendered as N thin strips affine-warped to their surface quads.

UPGRADED GATE (binding for batch 4, user directive 2026-07-20): containment
alone is NOT a pass. For every stamp on a non-planar/oblique surface the gate
also asserts, from the ACTUAL rendered strip quads vs the declared surface
model: (1) every vertex inside the surface patch polygon (+ iPad band);
(2) CURVATURE: the glyph-vertical tangent sweeps across strips by the model's
bow (a flat stamp sweeps ~0 deg -> FAIL); (3) PERSPECTIVE: baseline angle
matches the surface's axial direction and the vertical lean matches the
circum direction (screen-upright/unsheared stamps FAIL).
validate_gate_fails_flat() proves the batch-3 stamps fail this gate 4/4.

Pipeline (all deterministic PIL, $0): erase old stamps by restoring blank
drum pixels from the pre-stamp composite (S/z3-hatchwheels-composited@3x.png)
-> warp-stamp canonical numerals (same ink/hi/depth engrave style as batch 3)
-> rebuild z3-dial-base wide, cu-hatch-wheels CU22, per-wheel 12-position
wheel strip -> changed-pixel audit (all changes inside sanctioned zones) ->
before/after sheet. Superseded canonicals -> _rejects/*-b4pre-wheelfix.
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z3 = os.path.join(A2, "z3", "v-dial")
SPR = os.path.join(Z3, "sprites")
REJ = os.path.join(A2, "_rejects")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")

NUMS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]
BASE_WHEEL_NUMS = ["XII", "III", "VI", "IX"]
CU_FRAME = (2150, 870, 3550, 1920)
CU_W, CU_H = 2048, 1536
CU_SCALE = CU_W / (CU_FRAME[2] - CU_FRAME[0])
SAFE_X = (640, 3200)
SAFE_Y = (154, 1766)
INK, INK_A = (58, 42, 20), 235
HI, HI_A = (244, 224, 160), 110
DEPTH = 2
N_STRIPS = 20

# old flat-stamp geometry (batch 3) — erase rects + gate FAIL demo
OLD_CROWN_FACES = [
    (2450, 1625, 2525, 1695), (2605, 1680, 2685, 1750),
    (2775, 1730, 2850, 1800), (2945, 1735, 3035, 1815)]
OLD_ROT = -15

# ---- per-wheel crown-plate surface models (measured on the blank plate;
# plate = measured face quad TL,TR,BR,BL used for containment; C center;
# alpha axial/baseline deg; gamma circum/vertical deg (y-down screen);
# beta bow sweep deg; gh glyph height px along the circum path.
WHEELS = [
    dict(plate=[(2476, 1632), (2546, 1646), (2531, 1683), (2460, 1669)],
         C=(2503, 1657), alpha=11.0, gamma=115.0, beta=12.0, gh=30),
    dict(plate=[(2622, 1678), (2683, 1686), (2668, 1715), (2607, 1708)],
         C=(2645, 1697), alpha=7.5, gamma=117.0, beta=12.0, gh=27),
    dict(plate=[(2807, 1715), (2866, 1739), (2852, 1763), (2790, 1753)],
         C=(2830, 1742), alpha=22.5, gamma=115.0, beta=12.0, gh=27),
    dict(plate=[(2985, 1754), (3062, 1786), (3048, 1810), (2980, 1809)],
         C=(3012, 1787), alpha=23.0, gamma=100.0, beta=12.0, gh=28),
]


def path_points(w, vs):
    """Bowed circum centerline: returns dict v -> (x,y) for requested vs."""
    out = {}
    steps = 200
    g0, b = math.radians(w["gamma"]), math.radians(w["beta"])
    gh = w["gh"]
    # integrate from v=0.5 outward both ways
    pos = {0.5: (float(w["C"][0]), float(w["C"][1]))}
    for direction in (1, -1):
        x, y = pos[0.5]
        v = 0.5
        dv = direction / steps
        for _ in range(steps):
            g = g0 + b * (0.5 - (v + dv / 2))
            x += gh * math.cos(g) * dv
            y += gh * math.sin(g) * dv
            v += dv
            pos[round(v, 6)] = (x, y)
    for v in vs:
        key = round(round(v * steps) / steps, 6)
        out[v] = pos[key]
    return out


def glyph_strip_quads(w, numeral, scale=1.0, off=(0, 0), fill=0.94):
    """Dest quads (top->bottom strips) for the conformal stamp."""
    st = render_numeral(numeral, 400)
    gh = w["gh"]
    plate = w["plate"]
    top_w = math.hypot(plate[1][0] - plate[0][0], plate[1][1] - plate[0][1])
    gw_max = top_w * 0.80
    gw = min(gw_max, gh * st.width / st.height)
    a = math.radians(w["alpha"])
    ax = (math.cos(a), math.sin(a))
    vs = [j / N_STRIPS for j in range(N_STRIPS + 1)]
    pp = path_points(w, vs)
    ox, oy = off
    quads = []
    for j in range(N_STRIPS):
        p0, p1 = pp[vs[j]], pp[vs[j + 1]]
        q = []
        for (px, py), su in ((p0, -1), (p0, 1), (p1, 1), (p1, -1)):
            x = px + su * ax[0] * gw / 2
            y = py + su * ax[1] * gw / 2
            q.append(((x - ox) * scale, (y - oy) * scale))
        quads.append(q)
    return quads, st


def plate_poly(w, scale=1.0, off=(0, 0), grow=1.22):
    """Containment polygon: measured plate quad grown about its center."""
    cx = sum(p[0] for p in w["plate"]) / 4
    cy = sum(p[1] for p in w["plate"]) / 4
    ox, oy = off
    return [((cx + (px - cx) * grow - ox) * scale,
             (cy + (py - cy) * grow - oy) * scale) for px, py in w["plate"]]


def point_in_poly(x, y, poly):
    inside = False
    n = len(poly)
    for i in range(n):
        x1, y1 = poly[i]
        x2, y2 = poly[(i + 1) % n]
        if (y1 > y) != (y2 > y):
            xt = x1 + (y - y1) / (y2 - y1) * (x2 - x1)
            if x < xt:
                inside = not inside
    return inside


# ------------------------------------------------------- UPGRADED GATE

def assert_conformal(quads, w, scale=1.0, off=(0, 0), where="", in_band=True):
    """Containment + curvature/perspective conformance (upgraded gate).
    Judges the ACTUAL rendered strip quads against the declared surface."""
    poly = plate_poly(w, scale, off)
    # (1) containment + safe band
    for q in quads:
        for x, y in q:
            assert point_in_poly(x, y, poly), \
                f"{where}: strip vertex ({x:.0f},{y:.0f}) outside crown-plate patch"
            if in_band:
                wx, wy = x / scale + off[0], y / scale + off[1]
                m_ = f"{where}: strip vertex out of iPad dual-safe band (x)"
                assert SAFE_X[0] <= wx <= SAFE_X[1], m_
                if not (SAFE_Y[0] <= wy <= SAFE_Y[1]):
                    # wheel-4 bottom spacing: USER-ACCEPTED batch-3 flag
                    # (step-10 verdict 2026-07-20); CU22 carries the read.
                    print(f"  NOTE {where}: y={wy:.0f} below iPad band "
                          f"(accepted batch-3 wheel-4 flag)")
    # (2) curvature: vertical tangent sweep across strips ~= bow (flat -> 0 -> FAIL)
    def seg_ang(p0, p1):
        return math.degrees(math.atan2(p1[1] - p0[1], p1[0] - p0[0]))
    def mid(q, i, jj):
        return ((q[i][0] + q[jj][0]) / 2, (q[i][1] + q[jj][1]) / 2)
    t_first = seg_ang(mid(quads[0], 0, 1), mid(quads[0], 3, 2))
    t_last = seg_ang(mid(quads[-1], 0, 1), mid(quads[-1], 3, 2))
    sweep = abs(t_last - t_first)
    sweep = min(sweep, 360 - sweep)
    exp_sweep = w["beta"] * (N_STRIPS - 1) / N_STRIPS
    assert sweep >= max(5.0, 0.6 * exp_sweep), \
        f"{where}: FLAT STAMP — vertical tangent sweep {sweep:.1f} deg; surface " \
        f"is curved (model bow {exp_sweep:.1f} deg)"
    assert abs(sweep - exp_sweep) <= max(3.0, 0.3 * exp_sweep), \
        f"{where}: tangent sweep {sweep:.1f} != model bow {exp_sweep:.1f}"
    # (3) perspective: baseline angle == surface axial dir; vertical lean ==
    #     circum dir (screen-upright/unsheared stamps FAIL)
    base_ang = seg_ang(quads[0][0], quads[0][1])
    assert abs(base_ang - w["alpha"]) <= 3.0, \
        f"{where}: baseline {base_ang:.1f} deg != surface axial {w['alpha']:.1f} deg"
    vert_ang = seg_ang(mid(quads[0], 0, 1), mid(quads[-1], 3, 2))
    assert abs(vert_ang - w["gamma"]) <= max(4.0, w["beta"]), \
        f"{where}: vertical lean {vert_ang:.1f} deg != surface circum {w['gamma']:.1f} deg"
    return sweep, exp_sweep, base_ang, vert_ang


def validate_gate_fails_flat():
    """Prove the upgraded gate rejects flat stamps 4/4 — INCLUDING when the
    flat stamp is fully CONTAINED in the surface patch (the directive's exact
    failure class: containment alone is not conformance)."""
    fails = 0
    for i, w in enumerate(WHEELS):
        # a contained flat stamp: centered on the plate, shrunk to fit
        cx, cy = w["C"]
        gw, gh = 30, 20
        a = math.radians(OLD_ROT)
        ca, sa = math.cos(a), math.sin(a)
        quads = []
        for j in range(N_STRIPS):
            v0, v1 = j / N_STRIPS - 0.5, (j + 1) / N_STRIPS - 0.5
            q = []
            for vx, vy in ((-gw / 2, v0 * gh), (gw / 2, v0 * gh),
                           (gw / 2, v1 * gh), (-gw / 2, v1 * gh)):
                quads_pt = (cx + vx * ca - vy * sa, cy + vx * sa + vy * ca)
                q.append(quads_pt)
            quads.append(q)
        try:
            assert_conformal(quads, w, where=f"old-flat-w{i+1}", in_band=False)
        except AssertionError as e:
            fails += 1
            print(f"  gate correctly FAILS old flat stamp w{i+1}: {str(e)[:110]}")
    assert fails == 4, "gate did not reject all 4 old flat stamps"
    print("gate validation: 4/4 batch-3 flat stamps REJECTED by upgraded gate")


# ------------------------------------------------------- warped engrave

def affine_from_tri(src, dst):
    A = np.array([[dst[0][0], dst[0][1], 1], [dst[1][0], dst[1][1], 1],
                  [dst[2][0], dst[2][1], 1]], float)
    bx = np.array([src[0][0], src[1][0], src[2][0]], float)
    by = np.array([src[0][1], src[1][1], src[2][1]], float)
    cx = np.linalg.solve(A, bx)
    cy = np.linalg.solve(A, by)
    return (cx[0], cx[1], cx[2], cy[0], cy[1], cy[2])


def warped_alpha(quads, st, canvas_size, ss=2):
    W, H = canvas_size
    acc = np.zeros((H * ss, W * ss), np.uint8)
    a = st.split()[3]
    gw, gh = a.size
    for j, q in enumerate(quads):
        y0s, y1s = gh * j / N_STRIPS, gh * (j + 1) / N_STRIPS
        src = [(0, max(0, y0s - 1)), (gw, max(0, y0s - 1)), (gw, min(gh, y1s + 1))]
        def lerp(p1, p2, f):
            return (p1[0] + (p2[0] - p1[0]) * f, p1[1] + (p2[1] - p1[1]) * f)
        ext = 1.0 / max(1e-6, (y1s - y0s))
        d_tl = lerp(q[0], q[3], -ext * 1.0)
        d_tr = lerp(q[1], q[2], -ext * 1.0)
        d_br = lerp(q[1], q[2], 1 + ext * 1.0)
        dst = [(p[0] * ss, p[1] * ss) for p in (d_tl, d_tr, d_br)]
        coef = affine_from_tri(src, dst)
        strip = a.transform((W * ss, H * ss), Image.AFFINE, coef,
                            resample=Image.BILINEAR, fillcolor=0)
        acc = np.maximum(acc, np.asarray(strip))
    return Image.fromarray(acc).resize((W, H), Image.LANCZOS)


def engrave_warped(base_rgba, quads, st, depth=DEPTH):
    W, H = base_rgba.size
    aw = warped_alpha(quads, st, (W, H))
    for col, alp, dx, dy in ((HI, HI_A, depth, depth), (INK, INK_A, 0, 0)):
        layer = Image.new("RGBA", (W, H), col + (0,))
        layer.putalpha(aw.point(lambda v, m=alp: v * m // 255))
        base_rgba.alpha_composite(layer, (dx, dy))
    return aw


# ------------------------------------------------------------- preview

def preview(out="fix-wheelmodel-preview.png"):
    """Render the ACTUAL warped stamps on the blank plate + model overlays."""
    comp = Image.open(os.path.join(S, "z3-hatchwheels-composited@3x.png")).convert("RGB")
    rgba = comp.convert("RGBA")
    for i, w in enumerate(WHEELS):
        quads, st = glyph_strip_quads(w, BASE_WHEEL_NUMS[i])
        engrave_warped(rgba, quads, st)
    x0, y0, x1, y1 = 2380, 1560, 3160, 1900
    Z = 3
    c = rgba.convert("RGB").crop((x0, y0, x1, y1)).resize(
        ((x1 - x0) * Z, (y1 - y0) * Z), Image.LANCZOS)
    d = ImageDraw.Draw(c)
    for i, w in enumerate(WHEELS):
        poly = plate_poly(w)
        d.polygon([((px - x0) * Z, (py - y0) * Z) for px, py in poly],
                  outline=(255, 0, 255))
        d.polygon([((px - x0) * Z, (py - y0) * Z) for px, py in w["plate"]],
                  outline=(0, 255, 0))
    c.save(os.path.join(S, out))
    print("preview ->", out)


def preview_clean(out="fix-wheelresult-preview.png"):
    """Warped stamps only, no overlays — the acceptance view."""
    comp = Image.open(os.path.join(S, "z3-hatchwheels-composited@3x.png")).convert("RGB")
    rgba = comp.convert("RGBA")
    for i, w in enumerate(WHEELS):
        quads, st = glyph_strip_quads(w, BASE_WHEEL_NUMS[i])
        engrave_warped(rgba, quads, st)
    x0, y0, x1, y1 = 2380, 1560, 3160, 1900
    Z = 3
    rgba.convert("RGB").crop((x0, y0, x1, y1)).resize(
        ((x1 - x0) * Z, (y1 - y0) * Z), Image.LANCZOS).save(os.path.join(S, out))
    print("clean preview ->", out)


# ------------------------------------------------------------- rebuild

def erase_rects(scale=1.0, off=(0, 0), pad=22):
    out = []
    for r in OLD_CROWN_FACES:
        x0, y0, x1, y1 = r
        out.append((int((x0 - pad - off[0]) * scale), int((y0 - pad - off[1]) * scale),
                    int(math.ceil((x1 + pad + DEPTH - off[0]) * scale)),
                    int(math.ceil((y1 + pad + DEPTH - off[1]) * scale))))
    return out


def archive(path, tag="-b4pre-wheelfix"):
    if not os.path.exists(path):
        return
    os.makedirs(REJ, exist_ok=True)
    stem, ext = os.path.splitext(os.path.basename(path))
    if "@" in stem:
        name, dens = stem.split("@")
        stem = f"{name}{tag}@{dens}"
        tag = ""
    dst = os.path.join(REJ, stem + tag + ext)
    if not os.path.exists(dst):
        os.replace(path, dst)
    else:
        os.remove(path)


def save_densities(im, out_dir, name, cu=False):
    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, name + "@3x.png"))
    if cu:
        im.resize((1365, 1024), Image.LANCZOS).save(os.path.join(out_dir, name + "@2x.png"))
        im.resize((683, 512), Image.LANCZOS).save(os.path.join(out_dir, name + "@1x.png"))
    else:
        im.resize((2560, 1280), Image.LANCZOS).save(os.path.join(out_dir, name + "@2x.png"))
        im.resize((1280, 640), Image.LANCZOS).save(os.path.join(out_dir, name + "@1x.png"))


def rebuild():
    comp = Image.open(os.path.join(S, "z3-hatchwheels-composited@3x.png")).convert("RGB")
    wide_old = Image.open(os.path.join(Z3, "z3-dial-base@3x.png")).convert("RGB")
    cu_old = Image.open(os.path.join(Z3, "cu-hatch-wheels@3x.png")).convert("RGB")

    # ---- wide
    wide = wide_old.copy()
    for r in erase_rects():
        wide.paste(comp.crop(r), (r[0], r[1]))
    rgba = wide.convert("RGBA")
    report = []
    for i, w in enumerate(WHEELS):
        quads, st = glyph_strip_quads(w, BASE_WHEEL_NUMS[i])
        sweep, exp, ba, va = assert_conformal(quads, w, where=f"wide-w{i+1}")
        engrave_warped(rgba, quads, st)
        report.append(f"wide w{i+1} {BASE_WHEEL_NUMS[i]}: sweep {sweep:.1f}/"
                      f"{exp:.1f} deg, baseline {ba:.1f}, lean {va:.1f}")
    wide_new = rgba.convert("RGB")

    diff = np.abs(np.asarray(wide_new, np.int16) - np.asarray(wide_old, np.int16)).max(2)
    changed = diff > 6
    sanc = np.zeros(changed.shape, bool)
    for r in erase_rects(pad=30):
        sanc[r[1]:r[3], r[0]:r[2]] = True
    for i, w in enumerate(WHEELS):
        quads, _ = glyph_strip_quads(w, BASE_WHEEL_NUMS[i])
        xs = [p[0] for q in quads for p in q]
        ys = [p[1] for q in quads for p in q]
        sanc[int(min(ys)) - 6:int(max(ys)) + 8, int(min(xs)) - 6:int(max(xs)) + 8] = True
    stray = int((changed & ~sanc).sum())
    assert stray == 0, f"AUDIT FAIL: {stray} changed px outside sanctioned zones (wide)"
    print("wide audit: all", int(changed.sum()), "changed px inside sanctioned zones")

    # ---- CU22
    blank_cu = comp.crop(CU_FRAME).resize((CU_W, CU_H), Image.LANCZOS)
    dcu = np.abs(np.asarray(blank_cu, np.int16) - np.asarray(cu_old, np.int16)).max(2)
    mask = np.ones(dcu.shape, bool)
    for r in erase_rects(CU_SCALE, CU_FRAME[:2], pad=30):
        mask[max(0, r[1]):r[3], max(0, r[0]):r[2]] = False
    frac = float((dcu[mask] > 12).mean())
    assert frac < 0.002, f"blank-CU reconstruction mismatch: {frac:.4f} of px differ"
    print(f"blank CU22 reconstruction verified (mismatch frac {frac:.5f})")
    cu_rgba = blank_cu.convert("RGBA")
    for i, w in enumerate(WHEELS):
        quads, st = glyph_strip_quads(w, BASE_WHEEL_NUMS[i], CU_SCALE, CU_FRAME[:2])
        sweep, exp, ba, va = assert_conformal(quads, w, CU_SCALE, CU_FRAME[:2],
                                              where=f"cu22-w{i+1}")
        engrave_warped(cu_rgba, quads, st, depth=max(2, round(DEPTH * CU_SCALE)))
        report.append(f"cu22 w{i+1} {BASE_WHEEL_NUMS[i]}: sweep {sweep:.1f}/"
                      f"{exp:.1f} deg, baseline {ba:.1f}, lean {va:.1f}")
    cu_new = cu_rgba.convert("RGB")

    # ---- per-wheel 12-position strip at CU22-native scale
    cells = []
    meta_frames = []
    for i, w in enumerate(WHEELS):
        xs, ys = [], []
        for n in NUMS:
            quads, _ = glyph_strip_quads(w, n)
            xs += [p[0] for q in quads for p in q]
            ys += [p[1] for q in quads for p in q]
        fr = (int(min(xs)) - 14, int(min(ys)) - 14,
              int(math.ceil(max(xs))) + 16, int(math.ceil(max(ys))) + 16)
        meta_frames.append(fr)
        fw = int(round((fr[2] - fr[0]) * CU_SCALE))
        fh = int(round((fr[3] - fr[1]) * CU_SCALE))
        blank_face = comp.crop(fr).resize((fw, fh), Image.LANCZOS)
        frames = []
        for n in NUMS:
            quads, st = glyph_strip_quads(w, n, CU_SCALE, fr[:2])
            assert_conformal(quads, w, CU_SCALE, fr[:2],
                             where=f"strip-w{i+1}-{n}", in_band=False)
            f = blank_face.convert("RGBA")
            engrave_warped(f, quads, st)
            frames.append(f)
        cells.append(frames)
    cw = max(f[0].width for f in cells)
    ch = max(f[0].height for f in cells)
    strip = Image.new("RGBA", (cw * 4, ch * 12), (0, 0, 0, 0))
    for i, frames in enumerate(cells):
        for j, f in enumerate(frames):
            strip.alpha_composite(f, (i * cw, j * ch))
    x0c, y0c = CU_FRAME[:2]
    meta = {
        "layout": "columns = wheels 1-4 (left->right); rows = numerals I..XII",
        "cell_size_at_3x": [cw, ch],
        "per_wheel_frame_size_at_3x": [
            [int(round((fr[2] - fr[0]) * CU_SCALE)),
             int(round((fr[3] - fr[1]) * CU_SCALE))] for fr in meta_frames],
        "frame_anchor": "each frame drawn at native size, top-left of its cell",
        "order": NUMS,
        "wheel_frame_rects_wide_at_3x": [list(fr) for fr in meta_frames],
        "wheel_frame_rects_cu22_at_3x": [
            [round((fr[0] - x0c) * CU_SCALE), round((fr[1] - y0c) * CU_SCALE),
             round((fr[2] - x0c) * CU_SCALE), round((fr[3] - y0c) * CU_SCALE)]
            for fr in meta_frames],
        "header_dies_left_to_right": ["bigben", "burj", "liberty", "fuji"],
        "base_plate_shows": BASE_WHEEL_NUMS,
        "conformal_model": "numerals cylindrically warped per wheel (bow "
            "+ surface-frame shear); frames are PER-WHEEL — column i must only "
            "ever be composited onto wheel i's frame rect",
        "solution_note": "solution VI-X-I-III set by Developer state; never baked",
    }

    for nm in ("z3-dial-base", "cu-hatch-wheels"):
        for tag in ("1x", "2x", "3x"):
            archive(os.path.join(Z3, f"{nm}@{tag}.png"))
    for tag in ("1x", "2x", "3x"):
        archive(os.path.join(SPR, f"wheel-strip@{tag}.png"))
    save_densities(wide_new, Z3, "z3-dial-base")
    save_densities(cu_new, Z3, "cu-hatch-wheels", cu=True)
    strip.save(os.path.join(SPR, "wheel-strip@3x.png"))
    strip.resize((cw * 4 * 2 // 3, ch * 12 * 2 // 3), Image.LANCZOS).save(
        os.path.join(SPR, "wheel-strip@2x.png"))
    strip.resize((cw * 4 // 3, ch * 12 // 3), Image.LANCZOS).save(
        os.path.join(SPR, "wheel-strip@1x.png"))
    with open(os.path.join(SPR, "wheel-strip.json"), "w") as f:
        json.dump(meta, f, indent=1)
    for line in report:
        print(" ", line)

    # ---- before/after sheet
    wide_rej = Image.open(os.path.join(REJ, "z3-dial-base-b4pre-wheelfix@3x.png")).convert("RGB")
    cu_rej = Image.open(os.path.join(REJ, "cu-hatch-wheels-b4pre-wheelfix@3x.png")).convert("RGB")
    rows = []
    for src_old, src_new, box, label in (
            (wide_rej, wide_new, (2380, 1560, 3200, 1900), "wide"),
            (cu_rej, cu_new, (250, 950, 1500, 1470), "cu22")):
        a = src_old.crop(box)
        b = src_new.crop(box)
        h = 400
        a = a.resize((int(a.width * h / a.height), h), Image.LANCZOS)
        b = b.resize((int(b.width * h / b.height), h), Image.LANCZOS)
        row = Image.new("RGB", (a.width + b.width + 12, h + 30), (16, 16, 16))
        row.paste(a, (0, 30))
        row.paste(b, (a.width + 12, 30))
        d = ImageDraw.Draw(row)
        d.text((4, 8), f"{label} BEFORE (flat stamps)", fill=(255, 120, 120))
        d.text((a.width + 16, 8), f"{label} AFTER (conformal warp)", fill=(120, 255, 120))
        rows.append(row)
    W = max(r.width for r in rows)
    H = sum(r.height for r in rows) + 10 * len(rows)
    sheet = Image.new("RGB", (W, H), (16, 16, 16))
    y = 0
    for r in rows:
        sheet.paste(r, (0, y))
        y += r.height + 10
    sheet.save(os.path.join(Z3, "hatchwheel-warpfix-before-after.png"))
    print("before/after sheet saved")


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "preview"
    if cmd == "preview":
        preview()
    elif cmd == "clean":
        preview_clean()
    elif cmd == "gatecheck":
        validate_gate_fails_flat()
    elif cmd == "rebuild":
        validate_gate_fails_flat()
        rebuild()
