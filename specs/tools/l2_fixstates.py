#!/usr/bin/env python3
"""Level 2 / z1 state-overlay FIX PASS (step-10 z2 verdict, 2026-07-19).

Rebuilds the audit-failing state overlays from NB `edit` raws with REGISTERED
compositing (the batch-2 deterministic clone/blur attempts are the defect):

  workflow per overlay:
    1. estimate integer global shift of the NB raw vs the base CU on a control
       region (change area excluded), +-SEARCH px, minimizing MAE;
    2. linear per-channel color match NB -> base fitted on the control region;
    3. composite NB pixels ONLY inside a feathered change mask that keeps a
       >=BORDER px ring of pure base at the patch-rect boundary (seam == 0 by
       construction);
    4. crop the patch rect -> states/<name>@3x.png (+ wide echo where the CU
       hosts one), update z1-state-overlays.json rects.

Boundary-only failures (NB edits that are good but were cut at the rect with
no ring) are re-blended with the same ring guarantee, from their archived raws.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z1 = os.path.join(A2, "z1")
REJ = os.path.join(A2, "_rejects")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")
RAWS = os.path.join(S, "nb-fix-raws")
CU_W, CU_H = 2048, 1536

CUS = {   # CU name -> (view, wide frame x0,y0,x1,y1) — from l2_z1_states
    "cu-stove-hob":   ("v-bench", (2320, 1280, 3160, 1910)),
    "cu-crate-straw": ("v-master", (2380, 1230, 3300, 1920)),
    "cu-sill-tile":   ("v-door", (2135, 875, 2855, 1415)),
    "cu-coat-pockets": ("v-bench", None),
    "cu-timelock":    ("v-door", (620, 420, 1820, 1320)),
    "cu-floor-cache": ("v-door", (1900, 1140, 2940, 1920)),
    "cu-cat-cushion": ("v-door", (2101, 782, 3389, 1748)),
}
WIDE_OF = {"v-bench": "z1-bench-base", "v-master": "z1-master-base",
           "v-door": "z1-door-base"}


def load(p):
    return Image.open(p).convert("RGB")


def est_shift(base, nb, ctrl_mask, search=6):
    """Integer (dx, dy) minimizing MAE of nb-shifted vs base on ctrl_mask."""
    b = np.asarray(base.resize((CU_W // 2, CU_H // 2), Image.BILINEAR), np.float32)
    n = np.asarray(nb.resize((CU_W // 2, CU_H // 2), Image.BILINEAR), np.float32)
    m = np.asarray(ctrl_mask.resize((CU_W // 2, CU_H // 2), Image.NEAREST), bool)
    best, bs = None, 1e18
    for dy in range(-search // 2, search // 2 + 1):
        for dx in range(-search // 2, search // 2 + 1):
            nn = np.roll(np.roll(n, dy, axis=0), dx, axis=1)
            e = np.abs(nn - b).mean(axis=2)[m].mean()
            if e < bs:
                bs, best = e, (dx * 2, dy * 2)
    return best, bs


def color_match(base, nb, ctrl_mask):
    """Per-channel linear a*x+b fit on control pixels."""
    b = np.asarray(base, np.float32)
    n = np.asarray(nb, np.float32)
    m = np.asarray(ctrl_mask, bool)
    out = n.copy()
    for c in range(3):
        x = n[..., c][m]; y = b[..., c][m]
        a = np.cov(x, y)[0, 1] / (x.var() + 1e-5)
        a = float(np.clip(a, 0.6, 1.6))
        off = y.mean() - a * x.mean()
        out[..., c] = np.clip(n[..., c] * a + off, 0, 255)
    return Image.fromarray(out.astype(np.uint8), "RGB")


def registered_composite(cu_name, raw_name, change_polys, rect, feather=18,
                         border=24, shift_search=6, save_shift_proof=None):
    """Return full composited CU image + used mask; ring at rect edge == base."""
    view, frame = CUS[cu_name]
    base = load(os.path.join(Z1, view, cu_name + "@3x.png"))
    nb = load(os.path.join(RAWS, raw_name + "@3x.png"))
    # change mask (polys in CU coords)
    ch = Image.new("L", base.size, 0)
    d = ImageDraw.Draw(ch)
    for p in change_polys:
        d.polygon(p, fill=255)
    ctrl = ch.filter(ImageFilter.GaussianBlur(30)).point(lambda v: 255 if v == 0 else 0)
    (dx, dy), err = est_shift(base, nb, ctrl, shift_search)
    if dx or dy:
        nb = Image.fromarray(np.roll(np.roll(np.asarray(nb), dy, axis=0), dx, axis=1))
    nb = color_match(base, nb, ctrl)
    # clamp mask so a border ring inside rect stays pure base
    x0, y0, x1, y1 = rect
    lim = Image.new("L", base.size, 0)
    ImageDraw.Draw(lim).rectangle([x0 + border, y0 + border, x1 - 1 - border, y1 - 1 - border], fill=255)
    m = np.minimum(np.asarray(ch, np.float32), np.asarray(lim, np.float32))
    m = np.asarray(Image.fromarray(m.astype(np.uint8), "L")
                   .filter(ImageFilter.GaussianBlur(feather)), np.float32)
    # re-clamp post-blur so the outer ring is EXACTLY zero
    hard = np.zeros_like(m)
    hard[y0 + 4:y1 - 4, x0 + 4:x1 - 4] = 1.0
    lim2 = Image.new("L", base.size, 0)
    ImageDraw.Draw(lim2).rectangle([x0 + 6, y0 + 6, x1 - 7, y1 - 7], fill=255)
    m = m * (np.asarray(lim2, np.float32) / 255.0)
    b = np.asarray(base, np.float32)
    n = np.asarray(nb, np.float32)
    outa = b * (1 - m[..., None] / 255.0) + n * (m[..., None] / 255.0)
    out = Image.fromarray(outa.astype(np.uint8), "RGB")
    print(f"{raw_name}: shift=({dx},{dy}) ctrl-MAE={err:.2f}")
    return out


def save_patch(meta, state_name, cu_name, img, rect, note):
    view, frame = CUS[cu_name]
    outd = os.path.join(Z1, view, "states")
    os.makedirs(outd, exist_ok=True)
    dst = os.path.join(outd, state_name + "@3x.png")
    old = os.path.join(REJ, state_name + "-b2pre-fixpass@3x.png")
    if os.path.exists(dst) and not os.path.exists(old):
        os.replace(dst, old)
    patch = img.crop(rect)
    patch.save(dst)
    rec = {"base": cu_name, "rect_3x": list(rect), "note": note}
    if frame:
        x0, y0, x1, y1 = frame
        sc = (x1 - x0) / CU_W
        wb = [round(x0 + rect[0] * sc), round(y0 + rect[1] * sc),
              round(x0 + rect[2] * sc), round(y0 + rect[3] * sc)]
        wb[3] = min(wb[3], 1920)
        wdst = os.path.join(outd, state_name + "-wide@3x.png")
        wold = os.path.join(REJ, state_name + "-wide-b2pre-fixpass@3x.png")
        if os.path.exists(wdst) and not os.path.exists(wold):
            os.replace(wdst, wold)
        wpatch = patch.resize((wb[2] - wb[0], wb[3] - wb[1]), Image.LANCZOS)
        # blend the wide echo's own boundary ring into the wide base (12px)
        wide = load(os.path.join(Z1, view, WIDE_OF[view] + "@3x.png"))
        breg = wide.crop(wb)
        mm = Image.new("L", wpatch.size, 0)
        ImageDraw.Draw(mm).rectangle([12, 12, wpatch.width - 13, wpatch.height - 13], fill=255)
        mm = np.asarray(mm.filter(ImageFilter.GaussianBlur(6)), np.float32) / 255.0
        wa = (np.asarray(breg, np.float32) * (1 - mm[..., None]) +
              np.asarray(wpatch, np.float32) * mm[..., None])
        Image.fromarray(wa.astype(np.uint8), "RGB").save(wdst)
        rec["wide_base"] = WIDE_OF[view]
        rec["wide_rect_3x"] = wb
    meta[state_name] = rec
    print("saved", state_name, rect)
