#!/usr/bin/env python3
"""Level 2 / z1 state-overlay FIX PASS driver (step-10 z2 verdict, 2026-07-19/20).

Rebuilds the audit-failing state overlays from the predecessor's five paid NB
`edit` raws (seeds 720301-720305, archived in _rejects/edit-*-fixraw@3x.png and
scratchpad nb-fix-raws/) with REGISTERED masked compositing, plus deterministic
re-fills / boundary re-blends. Untouched pixels stay bit-identical to the base:
every composite keeps a pure-base ring at the patch-rect boundary (except sides
that coincide with the image edge), so the 3px seam check passes by
construction.

CLI:  python l2_fixstates.py F2|F3F4|F5|F6|F7|F8|seams|sheet
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z1 = os.path.join(A2, "z1")
REJ = os.path.join(A2, "_rejects")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")
RAWS = os.path.join(S, "nb-fix-raws")
OVJ = os.path.join(Z1, "z1-state-overlays.json")
CU_W, CU_H = 2048, 1536

CUS = {   # CU name -> (view, wide frame x0,y0,x1,y1) — linear crop maps (verified)
    "cu-stove-hob":   ("v-bench", (2320, 1280, 3160, 1910)),
    "cu-crate-straw": ("v-master", (2380, 1230, 3300, 1920)),
    "cu-sill-tile":   ("v-door", (2135, 875, 2855, 1415)),
    "cu-coat-pockets": ("v-bench", None),
    "cu-timelock":    ("v-door", (620, 420, 1820, 1320)),
    "cu-floor-cache": ("v-door", (1900, 1140, 2940, 1920)),
    # cu-cat-cushion intentionally absent: its wide echo is NOT a linear map —
    # cushion wides are re-blended in place (F8), never re-derived.
}
WIDE_OF = {"v-bench": "z1-bench-base", "v-master": "z1-master-base",
           "v-door": "z1-door-base"}


def load(p):
    return Image.open(p).convert("RGB")


def meta_load():
    return json.load(open(OVJ, encoding="utf-8"))


def meta_save(m):
    json.dump(m, open(OVJ, "w", encoding="utf-8"), indent=1)


def archive(dst, tag="-b2pre-fixpass"):
    """Move current canonical file to _rejects (once)."""
    if not os.path.exists(dst):
        return
    name = os.path.basename(dst).replace("@3x.png", tag + "@3x.png")
    old = os.path.join(REJ, name)
    if not os.path.exists(old):
        os.replace(dst, old)


def est_shift(base, nb, ctrl_mask, search=6):
    b = np.asarray(base.resize((CU_W // 2, CU_H // 2), Image.BILINEAR), np.float32).mean(2)
    n = np.asarray(nb.resize((CU_W // 2, CU_H // 2), Image.BILINEAR), np.float32).mean(2)
    m = np.asarray(ctrl_mask.resize((CU_W // 2, CU_H // 2), Image.NEAREST), bool)
    best, bs = (0, 0), 1e18
    for dy in range(-search // 2, search // 2 + 1):
        for dx in range(-search // 2, search // 2 + 1):
            nn = np.roll(np.roll(n, dy, axis=0), dx, axis=1)
            e = np.abs(nn - b)[m].mean()
            if e < bs:
                bs, best = e, (dx * 2, dy * 2)
    return best, bs


def color_match(base, nb, ctrl_mask):
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


def edge_sides(rect, w=CU_W, h=CU_H):
    """Which rect sides lie ON the image edge (ring exempt there)."""
    x0, y0, x1, y1 = rect
    return {"l": x0 <= 0, "t": y0 <= 0, "r": x1 >= w, "b": y1 >= h}


def ring_lim_mask(size, rect, inset, exempt):
    """255 inside rect inset by `inset` on non-exempt sides."""
    w, h = size
    x0, y0, x1, y1 = rect
    lx = x0 + (0 if exempt["l"] else inset)
    ty = y0 + (0 if exempt["t"] else inset)
    rx = x1 - 1 - (0 if exempt["r"] else inset)
    by = y1 - 1 - (0 if exempt["b"] else inset)
    lim = Image.new("L", size, 0)
    ImageDraw.Draw(lim).rectangle([lx, ty, rx, by], fill=255)
    return lim


def composite_nb(cu_name, raw_name, rect, thr=10, dilate=15, feather=14,
                 border=24, tag=""):
    """Registered masked composite of an NB edit raw over its base CU.

    Auto change-mask = smoothed |base-NB| > thr inside rect, dilated+closed,
    clamped so a `border` ring at the rect boundary (non-image-edge sides)
    stays pure base."""
    view, frame = CUS[cu_name]
    base = load(os.path.join(Z1, view, cu_name + "@3x.png"))
    nb = load(os.path.join(RAWS, raw_name + "@3x.png"))
    exempt = edge_sides(rect)

    # 1. rough change area for control mask (whole-image diff)
    d0 = np.abs(np.asarray(nb, np.float32) - np.asarray(base, np.float32)).mean(2)
    d0s = np.asarray(Image.fromarray(d0.astype(np.uint8))
                     .filter(ImageFilter.GaussianBlur(8)), np.float32)
    ctrl = Image.fromarray(((d0s < 8)).astype(np.uint8) * 255, "L") \
        .filter(ImageFilter.MinFilter(9))
    (dx, dy), err = est_shift(base, nb, ctrl)
    if dx or dy:
        nb = Image.fromarray(np.roll(np.roll(np.asarray(nb), dy, axis=0), dx, axis=1))
    nb = color_match(base, nb, ctrl)

    # 2. change mask from registered diff, inside rect only
    d = np.abs(np.asarray(nb, np.float32) - np.asarray(base, np.float32)).mean(2)
    ds = np.asarray(Image.fromarray(d.astype(np.uint8))
                    .filter(ImageFilter.GaussianBlur(6)), np.float32)
    ch = Image.fromarray(((ds > thr)).astype(np.uint8) * 255, "L")
    ch = ch.filter(ImageFilter.MaxFilter(dilate | 1))       # dilate
    ch = ch.filter(ImageFilter.MinFilter(5)).filter(ImageFilter.MaxFilter(9))  # close-ish
    lim = ring_lim_mask(base.size, rect, border, exempt)
    m = np.minimum(np.asarray(ch, np.float32), np.asarray(lim, np.float32))
    m = np.asarray(Image.fromarray(m.astype(np.uint8), "L")
                   .filter(ImageFilter.GaussianBlur(feather)), np.float32)
    lim2 = ring_lim_mask(base.size, rect, 6, exempt)
    m = m * (np.asarray(lim2, np.float32) / 255.0)
    out = (np.asarray(base, np.float32) * (1 - m[..., None] / 255.0)
           + np.asarray(nb, np.float32) * (m[..., None] / 255.0))
    out = Image.fromarray(out.astype(np.uint8), "RGB")
    cov = (m > 128).mean()
    print(f"[{tag or raw_name}] shift=({dx},{dy}) ctrlMAE={err:.2f} maskcov={cov*100:.1f}%")
    return out, Image.fromarray(m.astype(np.uint8), "L")


def save_patch(meta, state_name, cu_name, img, rect, note):
    """Crop rect -> canonical states/<name>@3x.png (+ wide echo via frame map);
    archives superseded files; updates meta rects."""
    view, frame = CUS[cu_name]
    outd = os.path.join(Z1, view, "states")
    os.makedirs(outd, exist_ok=True)
    dst = os.path.join(outd, state_name + "@3x.png")
    archive(dst)
    patch = img.crop(rect)
    patch.save(dst)
    rec = meta.get(state_name, {})
    rec.update({"base": cu_name, "rect_3x": list(rect), "note": note})
    if frame and rec.get("wide_base"):
        x0, y0, _, _ = frame
        sc = (frame[2] - frame[0]) / CU_W
        wb = [round(x0 + rect[0] * sc), round(y0 + rect[1] * sc),
              round(x0 + rect[2] * sc), round(y0 + rect[3] * sc)]
        wb[2] = min(wb[2], 3840); wb[3] = min(wb[3], 1920)
        wdst = os.path.join(outd, state_name + "-wide@3x.png")
        archive(wdst)
        wide = load(os.path.join(Z1, view, WIDE_OF[view] + "@3x.png"))
        wpatch = patch.resize((wb[2] - wb[0], wb[3] - wb[1]), Image.LANCZOS)
        breg = wide.crop(wb)
        we = {"l": wb[0] <= 0, "t": wb[1] <= 0, "r": wb[2] >= 3840, "b": wb[3] >= 1920}
        mm = ring_lim_mask(wpatch.size, (0, 0, wpatch.width, wpatch.height), 12, we)
        mm = np.asarray(mm.filter(ImageFilter.GaussianBlur(6)), np.float32) / 255.0
        wa = (np.asarray(breg, np.float32) * (1 - mm[..., None]) +
              np.asarray(wpatch, np.float32) * mm[..., None])
        Image.fromarray(wa.astype(np.uint8), "RGB").save(wdst)
        rec["wide_base"] = WIDE_OF[view]
        rec["wide_rect_3x"] = wb
    meta[state_name] = rec
    print("saved", state_name, rect)


# ---------------------------------------------------------------- seam check
def seam_score(base_img, patch_img, rect, ring=3, img_w=None, img_h=None):
    """Max + mean abs diff (channel mean) between the patch's outer `ring`
    pixels and the base, skipping image-edge sides."""
    w = img_w or base_img.width; h = img_h or base_img.height
    exempt = edge_sides(rect, w, h)
    b = np.asarray(base_img.crop(rect), np.float32)
    p = np.asarray(patch_img, np.float32)
    if p.shape != b.shape:
        return None
    d = np.abs(p - b).mean(2)
    strips = []
    if not exempt["t"]: strips.append(d[:ring, :])
    if not exempt["b"]: strips.append(d[-ring:, :])
    if not exempt["l"]: strips.append(d[:, :ring])
    if not exempt["r"]: strips.append(d[:, -ring:])
    if not strips:
        return (0.0, 0.0)
    allv = np.concatenate([s.ravel() for s in strips])
    return (float(allv.max()), float(allv.mean()))


def check_all_seams():
    meta = meta_load()
    view_of = dict({k: v[0] for k, v in CUS.items()},
                   **{"cu-cat-cushion": "v-door", "cu-door-dial": "v-master"})
    wides = {v: load(os.path.join(Z1, k, v + "@3x.png"))
             for k, v in WIDE_OF.items()}
    cus = {}

    def cu(view, name):
        key = (view, name)
        if key not in cus:
            cus[key] = load(os.path.join(Z1, view, name + "@3x.png"))
        return cus[key]

    rows = []
    for name, rec in meta.items():
        if rec.get("full_plate"):
            continue
        cub = rec.get("base") or rec.get("cu")
        curect = rec.get("rect_3x") or rec.get("cu_rect_3x")
        if cub and curect:
            view = view_of[cub]
            p = os.path.join(Z1, view, "states", name + "@3x.png")
            if os.path.exists(p):
                sc = seam_score(cu(view, cub), load(p), curect)
                rows.append((name + " (CU)", sc))
        wb = rec.get("wide_base") or rec.get("wide")
        if wb and rec.get("wide_rect_3x"):
            view = [k for k, v in WIDE_OF.items() if v == wb][0]
            p = os.path.join(Z1, view, "states", name + "-wide@3x.png")
            if os.path.exists(p):
                sc = seam_score(wides[wb], load(p), rec["wide_rect_3x"],
                                img_w=3840, img_h=1920)
                rows.append((name + " (wide)", sc))
    for n, sc in rows:
        if sc is None:
            print(f"{n:42s}  SIZE-MISMATCH")
        else:
            verdict = "PASS" if sc[0] <= 24 else "FAIL"
            print(f"{n:42s}  max={sc[0]:6.1f} mean={sc[1]:5.2f}  {verdict}")
    return rows


# ------------------------------------------------------------------- fixes
def f2_bar():
    meta = meta_load()
    rect = (100, 460, 1800, 1280)
    img, _ = composite_nb("cu-timelock", "edit-bar-raised", rect,
                          thr=14, dilate=21, feather=16, border=26, tag="F2 bar")
    save_patch(meta, "ov-bar-raised", "cu-timelock", img, rect,
               "time-lock bar pivoted up ~20deg on right hinge; cradles empty; "
               "fix-pass rebuild from NB edit 720305, registered masked composite")
    meta_save(meta)
    img.resize((1024, 768), Image.LANCZOS).save(os.path.join(S, "fixed-bar.png"))


def f3f4_coat():
    meta = meta_load()
    img_w, _ = composite_nb("cu-coat-pockets", "edit-coat-both-empty",
                            (1040, 370, 1580, 1140), thr=10, tag="F3 watch")
    save_patch(meta, "ov-coat-watch-taken", "cu-coat-pockets", img_w,
               (1040, 370, 1580, 1140),
               "watch A + chain gone from right pocket; fix-pass rebuild from NB "
               "edit 720301 (both-pockets-empty raw), right pocket masked only")
    img_t, _ = composite_nb("cu-coat-pockets", "edit-coat-both-empty",
                            (430, 430, 970, 880), thr=10, tag="F4 tile")
    save_patch(meta, "ov-coat-tile-taken", "cu-coat-pockets", img_t,
               (430, 430, 970, 880),
               "tile IV gone from left pocket; fix-pass rebuild from NB edit "
               "720301 (both-pockets-empty raw), left pocket masked only")
    meta_save(meta)
    img_w.resize((1024, 768), Image.LANCZOS).save(os.path.join(S, "fixed-coat-watch.png"))
    img_t.resize((1024, 768), Image.LANCZOS).save(os.path.join(S, "fixed-coat-tile.png"))


def f5_stove():
    meta = meta_load()
    rect = (430, 300, 1720, 760)
    img, _ = composite_nb("cu-stove-hob", "edit-stove-clear", rect,
                          thr=8, dilate=17, tag="F5 stove")
    save_patch(meta, "ov-stove-tile-taken", "cu-stove-hob", img, rect,
               "tile II removed from the cold hob (incl. its cast shadow); "
               "fix-pass rebuild from NB edit 720302")
    meta_save(meta)
    img.resize((1024, 768), Image.LANCZOS).save(os.path.join(S, "fixed-stove.png"))


def f5b_screwdriver():
    """Deterministic rebuild of ov-screwdriver-taken (wide-only patch), v2:
    mask = screwdriver+shadow ONLY (from base darkness within a hand box),
    rail rows filled by horizontal clone (feathered run edges), wall rows by
    per-row linear interpolation + grain, peg cloned from the right peg."""
    rect = (980, 440, 1340, 1110)
    view = "v-bench"
    wide = load(os.path.join(Z1, view, "z1-bench-base@3x.png"))
    basec = wide.crop(rect)
    b = np.asarray(basec, np.float32)
    H, W = b.shape[:2]

    # --- mask: tool silhouette + wall shadow ---
    mask = Image.new("L", (W, H), 0)
    d = ImageDraw.Draw(mask)
    d.polygon([(70, 60), (162, 60), (162, 355), (140, 540), (152, 555),
               (150, 640), (92, 645), (95, 545), (105, 528), (98, 355),
               (70, 340)], fill=255)                       # handle+shaft+tip
    d.polygon([(20, 430), (105, 430), (105, 660), (18, 665)], fill=255)  # wall shadow
    d.polygon([(40, 330), (100, 330), (100, 440), (30, 445)], fill=255)  # shadow upper
    tool = Image.new("L", (W, H), 0)
    ImageDraw.Draw(tool).polygon([(70, 60), (162, 60), (162, 355), (140, 540),
        (152, 555), (150, 640), (92, 645), (95, 545), (105, 528), (98, 355),
        (70, 340)], fill=255)
    tool = np.asarray(tool.filter(ImageFilter.MaxFilter(9))
                      .filter(ImageFilter.GaussianBlur(2)), np.float32) / 255.0
    mask = mask.filter(ImageFilter.MaxFilter(9))
    m = np.asarray(mask, bool)

    out = b.copy()
    rail_y0, rail_y1 = 60, 187
    src_off = 104                                          # clean rail to the right
    rng = np.random.default_rng(720999)
    for y in range(rail_y0, rail_y1):
        run = np.where(m[y])[0]
        if run.size == 0:
            continue
        x0, x1 = run.min(), run.max()
        for x in run:
            sx = min(W - 1, x + src_off)
            out[y, x] = b[y, sx]
        for k in range(6):
            wgt = (k + 1) / 7.0
            if x0 + k < W:
                out[y, x0 + k] = out[y, x0 + k] * wgt + b[y, x0 + k] * (1 - wgt)
            if x1 - k >= 0:
                out[y, x1 - k] = out[y, x1 - k] * wgt + b[y, x1 - k] * (1 - wgt)
    # wall: smooth low-frequency diffusion fill at 1/8 res (wall is near-
    # featureless plaster; banding-free), plus faint grain
    wall = m.copy(); wall[rail_y0:rail_y1] = False
    F = 8
    hs, ws = H // F, W // F
    small = np.asarray(Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB")
                       .resize((ws, hs), Image.BILINEAR), np.float32)
    msk_s = np.asarray(Image.fromarray((wall * 255).astype(np.uint8), "L")
                       .resize((ws, hs), Image.BILINEAR), np.float32) > 40
    fill = small.copy()
    for _ in range(400):
        up = np.roll(fill, 1, 0); dn = np.roll(fill, -1, 0)
        lf = np.roll(fill, 1, 1); rt = np.roll(fill, -1, 1)
        avg = (up + dn + lf + rt) / 4.0
        fill[msk_s] = avg[msk_s]
    low = np.asarray(Image.fromarray(np.clip(fill, 0, 255).astype(np.uint8), "RGB")
                     .resize((W, H), Image.BICUBIC), np.float32)
    low = np.asarray(Image.fromarray(low.astype(np.uint8), "RGB")
                     .filter(ImageFilter.GaussianBlur(4)), np.float32)
    # high-frequency plaster streaks mirrored in from the clean wall right of
    # the tool (mirror axis x=175 keeps sources in the clean 175..340 zone)
    hp = b - np.asarray(Image.fromarray(np.clip(b, 0, 255).astype(np.uint8), "RGB")
                        .filter(ImageFilter.GaussianBlur(10)), np.float32)
    yy, xx = np.mgrid[0:H, 0:W]
    mx = np.clip(350 - xx, 0, W - 1)
    hf = hp[yy, mx]
    fillv = low + hf * 0.9 + rng.normal(0, 0.8, out.shape)
    # below y~430 the tool shadow crosses the diagonal sunbeam edge, which
    # diffusion cannot reconstruct -> keep base structure there and only
    # ATTENUATE the shadow (ramp 1.0 -> 0.45 replacement strength)
    ramp = np.clip((560 - yy) / 130.0, 0.0, 1.0) * 0.55 + 0.45
    ramp = np.maximum(ramp, tool)          # tool silhouette: always fully replaced
    out[wall] = (b + (fillv - b) * ramp[..., None])[wall]
    # feather whole mask edge into base + enforce pure-base ring at patch edge
    mf = np.asarray(mask.filter(ImageFilter.GaussianBlur(3)), np.float32) / 255.0
    lim = ring_lim_mask((W, H), (0, 0, W, H), 5,
                        {"l": False, "t": False, "r": False, "b": False})
    mf = mf * (np.asarray(lim.filter(ImageFilter.GaussianBlur(3)), np.float32) / 255.0)
    mf = mf * (np.asarray(ring_lim_mask((W, H), (0, 0, W, H), 2,
        {"l": False, "t": False, "r": False, "b": False}), np.float32) / 255.0)
    out = b * (1 - mf[..., None]) + out * mf[..., None]
    # peg clone: right peg box -> restored left peg
    pw, ph = 52, 62
    sx, sy, px, py = 262, 96, 92, 96
    peg = out[sy:sy + ph, sx:sx + pw].copy()
    pm = Image.new("L", (pw, ph), 0)
    ImageDraw.Draw(pm).ellipse([6, 8, pw - 6, ph - 8], fill=255)
    pmf = np.asarray(pm.filter(ImageFilter.GaussianBlur(4)), np.float32) / 255.0
    reg = out[py:py + ph, px:px + pw]
    out[py:py + ph, px:px + pw] = reg * (1 - pmf[..., None]) + peg * pmf[..., None]

    dstp = os.path.join(Z1, view, "states", "ov-screwdriver-taken-wide@3x.png")
    archive(dstp)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB").save(dstp)
    meta = meta_load()
    meta["ov-screwdriver-taken"]["note"] = (
        "rack empty after pickup; fix-pass deterministic rebuild v2: tool+shadow "
        "masked out of the BASE crop, rail cloned, wall row-interpolated w/ grain, "
        "peg restored; no CU host")
    meta_save(meta)
    Image.fromarray(np.clip(out, 0, 255).astype(np.uint8), "RGB")         .resize((W * 2, H * 2), Image.LANCZOS).save(os.path.join(S, "fixed-screw.png"))
    print("saved ov-screwdriver-taken (wide-only)", rect)


def f6_crate():
    meta = meta_load()
    rect = (770, 1000, 1290, 1340)
    img, _ = composite_nb("cu-crate-straw", "edit-crate-clear", rect,
                          thr=10, tag="F6 crate")
    save_patch(meta, "ov-crate-tile-taken", "cu-crate-straw", img, rect,
               "tile VII taken; straw closed over; fix-pass rebuild from NB edit "
               "720303 (registration audit passed contra predecessor's reject call)")
    meta_save(meta)
    img.resize((1024, 768), Image.LANCZOS).save(os.path.join(S, "fixed-crate.png"))


WHEEL = dict(cx=1300, cy=1292, w=310, squash=0.40, rot=-16.0,
             dark=0.42, warm=(1.06, 0.97, 0.82), hi=0.30)


def f7_cache():
    meta = meta_load()
    rect = (1080, 1150, 2048, 1536)
    img, _ = composite_nb("cu-floor-cache", "edit-cache-pried", rect,
                          thr=10, tag="F7 cache")
    # empty first (no wheel)
    save_patch(meta, "ov-cache-empty", "cu-floor-cache", img, rect,
               "cache open + empty after wheel taken; fix-pass rebuild from NB "
               "edit 720304 (real cavity + pried board)")
    # wheel composite into the cavity
    wheel = Image.open(os.path.join(Z1, "icons", "inv-great-wheel@3x.png")).convert("RGBA")
    P = WHEEL
    wh = wheel.resize((P["w"], max(2, int(P["w"] * P["squash"]))), Image.LANCZOS) \
              .rotate(P["rot"], expand=True, resample=Image.BICUBIC)
    wa = np.asarray(wh, np.float32)
    rgb, a = wa[..., :3], wa[..., 3:] / 255.0
    # darken into shadow with warm tint + top-left warm catch light gradient
    hgt, wdt = rgb.shape[:2]
    gy, gx = np.mgrid[0:hgt, 0:wdt]
    g = 1.0 - (gx / wdt * 0.5 + gy / hgt * 0.5)          # 1 top-left -> 0.
    fac = P["dark"] * (1 + P["hi"] * g)[..., None]
    rgb = np.clip(rgb * fac * np.array(P["warm"]), 0, 255)
    wh2 = np.concatenate([rgb, a * 255], axis=2).astype(np.uint8)
    wimg = Image.fromarray(wh2, "RGBA")
    full = img.convert("RGBA")
    full.alpha_composite(wimg, (P["cx"] - wimg.width // 2, P["cy"] - wimg.height // 2))
    full = full.convert("RGB")
    save_patch(meta, "ov-cache-pried-wheel", "cu-floor-cache", full, rect,
               "cache board pried (lies beside opening); canonical great wheel "
               "(inv-great-wheel icon, identical-die contract) lying in shadowed "
               "cavity w/ warm catch-light; fix-pass rebuild from NB edit 720304")
    meta_save(meta)
    full.crop(rect).save(os.path.join(S, "fixed-cache-wheel.png"))
    img.crop(rect).save(os.path.join(S, "fixed-cache-empty.png"))


# ------------------------------------------------------- F8: re-blends
def reblend(patch_path, base_img, rect, ring=6, feather=10, band=40,
            img_w=None, img_h=None, tag=""):
    """Re-blend an existing (content-approved) patch: linear color match to
    base fitted on the outer band, then feathered composite that keeps a pure
    base ring at the boundary (non-image-edge sides)."""
    w = img_w or base_img.width; h = img_h or base_img.height
    exempt = edge_sides(rect, w, h)
    basec = base_img.crop(rect)
    patch = load(patch_path)
    if patch.size != basec.size:
        raise SystemExit(f"{tag}: size mismatch {patch.size} vs {basec.size}")
    pw, ph = patch.size
    inner = ring_lim_mask(patch.size, (0, 0, pw, ph), ring + band, exempt)
    ctrl = Image.fromarray(
        (255 - np.asarray(inner, np.uint8)), "L")           # outer band+ring
    before = seam_score(base_img, patch, rect, img_w=w, img_h=h)
    patch = color_match(basec, patch, ctrl)
    mm = ring_lim_mask(patch.size, (0, 0, pw, ph), ring, exempt)
    mf = np.asarray(mm.filter(ImageFilter.GaussianBlur(feather)), np.float32)
    lim2 = ring_lim_mask(patch.size, (0, 0, pw, ph), max(1, ring // 2), exempt)
    mf = mf * (np.asarray(lim2, np.float32) / 255.0) / 255.0
    out = (np.asarray(basec, np.float32) * (1 - mf[..., None])
           + np.asarray(patch, np.float32) * mf[..., None])
    outi = Image.fromarray(out.astype(np.uint8), "RGB")
    archive(patch_path)
    outi.save(patch_path)
    after = seam_score(base_img, outi, rect, img_w=w, img_h=h)
    print(f"[F8 {tag}] seam max {before[0]:.0f}->{after[0]:.1f} "
          f"mean {before[1]:.1f}->{after[1]:.2f}")


def f8_reblends():
    meta = meta_load()
    wides = {v: load(os.path.join(Z1, k, v + "@3x.png")) for k, v in WIDE_OF.items()}
    cache_cu = load(os.path.join(Z1, "v-door", "cu-floor-cache@3x.png"))
    # 1. ov-cache-cat-gone (CU echo; touches top+right image edges)
    reblend(os.path.join(Z1, "v-door", "states", "ov-cache-cat-gone@3x.png"),
            cache_cu, meta["ov-cache-cat-gone"]["rect_3x"],
            ring=8, feather=12, tag="cache-cat-gone")
    # 2. ov-workroom-door-open (wide-only, master)
    reblend(os.path.join(Z1, "v-master", "states", "ov-workroom-door-open-wide@3x.png"),
            wides["z1-master-base"], meta["ov-workroom-door-open"]["wide_rect_3x"],
            ring=8, feather=12, img_w=3840, img_h=1920, tag="workroom-door-open")
    # 3+4. cushion wides (non-linear map -> re-blend in place)
    for n in ("ov-cushion-empty", "ov-cushion-reveal"):
        reblend(os.path.join(Z1, "v-door", "states", n + "-wide@3x.png"),
                wides["z1-door-base"], meta[n]["wide_rect_3x"],
                ring=6, feather=10, img_w=3840, img_h=1920, tag=n + "-wide")
    # 5. dial-seat wides x4
    for n in ("ov-dial-seat-ii", "ov-dial-seat-iv", "ov-dial-seat-vii", "ov-dial-seat-xi"):
        reblend(os.path.join(Z1, "v-master", "states", n + "-wide@3x.png"),
                wides["z1-master-base"], meta[n]["wide_rect_3x"],
                ring=4, feather=6, band=14, img_w=3840, img_h=1920, tag=n + "-wide")
    # 6. sill wide
    reblend(os.path.join(Z1, "v-door", "states", "ov-sill-tile-taken-wide@3x.png"),
            wides["z1-door-base"], meta["ov-sill-tile-taken"]["wide_rect_3x"],
            ring=5, feather=8, band=24, img_w=3840, img_h=1920, tag="sill-wide")


# ------------------------------------------------------------ F9 sheet
def contact_sheet():
    meta = meta_load()
    items = [
        ("ov-bar-raised", "v-door", "cu-timelock"),
        ("ov-coat-watch-taken", "v-bench", "cu-coat-pockets"),
        ("ov-coat-tile-taken", "v-bench", "cu-coat-pockets"),
        ("ov-stove-tile-taken", "v-bench", "cu-stove-hob"),
        ("ov-crate-tile-taken", "v-master", "cu-crate-straw"),
        ("ov-cache-pried-wheel", "v-door", "cu-floor-cache"),
        ("ov-cache-empty", "v-door", "cu-floor-cache"),
    ]
    TW, TH = 640, 480
    pad, cap = 8, 26
    rows = len(items) + 1   # + screwdriver row
    sheet = Image.new("RGB", (TW * 2 + pad * 3, (TH + cap + pad) * rows + pad),
                      (24, 22, 20))
    dr = ImageDraw.Draw(sheet)
    y = pad
    for name, view, cuname in items:
        rec = meta[name]
        cu = load(os.path.join(Z1, view, cuname + "@3x.png"))
        rect = rec["rect_3x"]
        oldp = os.path.join(REJ, name + "-b2pre-fixpass@3x.png")
        newp = os.path.join(Z1, view, "states", name + "@3x.png")
        for col, pth in ((0, oldp), (1, newp)):
            img = cu.copy()
            if os.path.exists(pth):
                p = Image.open(pth).convert("RGB")
                # old patches may have a different rect: paste centered on old rect if size differs
                r = rect if p.size == (rect[2] - rect[0], rect[3] - rect[1]) else None
                if r is None:
                    # find old rect from archived meta impossible; just fit top-left of rect
                    img.paste(p, (rect[0], rect[1]))
                else:
                    img.paste(p, (r[0], r[1]))
            img = img.resize((TW, TH), Image.LANCZOS)
            sheet.paste(img, (pad + col * (TW + pad), y + cap))
        dr.text((pad, y + 6), f"{name}   LEFT=before  RIGHT=fixed", fill=(235, 225, 205))
        y += TH + cap + pad
    # screwdriver row: before/after patch on bench base
    wide = load(os.path.join(Z1, "v-bench", "z1-bench-base@3x.png"))
    rect = meta["ov-screwdriver-taken"]["wide_rect_3x"]
    view_rect = (rect[0] - 150, rect[1] - 100, rect[2] + 150, rect[3] + 100)
    for col, pth in ((0, os.path.join(REJ, "ov-screwdriver-taken-wide-b2pre-fixpass@3x.png")),
                     (1, os.path.join(Z1, "v-bench", "states", "ov-screwdriver-taken-wide@3x.png"))):
        img = wide.copy()
        if os.path.exists(pth):
            img.paste(Image.open(pth).convert("RGB"), (rect[0], rect[1]))
        crop = img.crop(view_rect).resize((TW, TH), Image.LANCZOS)
        sheet.paste(crop, (pad + col * (TW + pad), y + cap))
    dr.text((pad, y + 6), "ov-screwdriver-taken (wide)   LEFT=before  RIGHT=fixed",
            fill=(235, 225, 205))
    out = os.path.join(Z1, "z1-review-fixpass-overlays.png")
    sheet.save(out)
    print("sheet:", out, sheet.size)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else ""
    {"F2": f2_bar, "F3F4": f3f4_coat, "F5": f5_stove, "F5b": f5b_screwdriver,
     "F6": f6_crate, "F7": f7_cache, "F8": f8_reblends,
     "seams": check_all_seams, "sheet": contact_sheet}[cmd]()
