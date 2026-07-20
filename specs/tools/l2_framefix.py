#!/usr/bin/env python3
"""Level 2 / z2 gear-frame XII/VIII stamp fix (user verdict 2026-07-20, batch-3 carry-in).

Defect (batch 2): the XII pinion stamp was placed at PINION_XII+(0,52) with a 30px
glyph — it stretches outside the small crank-pinion's face onto the tooth ring; the
VIII stamp at COLLAR_VIII rendered across the bracket/lower-rail joint, floating over
the bracket instead of reading engraved on the post-A mount panel.

Deterministic fix ($0, same class as the door-dial / clockrow fixes):
  1. ERASE: revert the two stamp bboxes on the wide @3x to the preglyph raw
     (_rejects/z2-frame-base-preglyph@3x.png). Safe by construction: the only
     ov_frame_stamps ink in those bboxes is the XII/VIII stamps (rack gears x>=2100,
     gear-ring at x~2850 are far outside).
  2. RE-STAMP, measured on the plate:
     - XII: pinion face ellipse center (1054,1100), rx 64 / ry 78 (tooth-root disc),
       knurled boss r~38 at (1058,1098). Stamp h=24 centered (1054,1152) — the clear
       lower face annulus.
     - VIII: post-A bracket face flat panel (1394..1478, 1200..1265), below the arbor
       hub, above the rivet + lower rail. Stamp h=26 centered (1436,1230).
  3. PROGRAMMATIC CONTAINMENT GATE (new, binding): each stamp's exact rendered bbox
     (incl. depth offset) is asserted inside its target-surface mask (ellipse-minus-boss
     / rect). Fails loudly instead of shipping another containment defect.
  4. Propagate: wide @2x/@1x + re-crop cu-gear-frame from the fixed wide with the same
     stamps re-engraved at native CU res (CU13 has no other native overlays).
     Superseded canonicals -> _rejects/*-b3pre-framefix.
  5. Seam check: wide diff vs before confined to the two erase bboxes; report max ring
     diff. Before/after review sheet z2/gearframe-stampfix-before-after.png.
"""
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral, tint
from l2_z2_build import engrave, FRAMES, CU_W, CU_H

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
VF = os.path.join(A2, "z2", "v-frame")
REJ = os.path.join(A2, "_rejects")

# erase bboxes (wide @3x) — generous around the old stamps incl. depth offsets
ERASE = [(1005, 1115, 1110, 1190),   # old XII (measured 1030-1085 x 1138-1165)
         (1385, 1260, 1495, 1335)]   # old VIII (measured 1402-1472 x 1282-1318)

# measured target surfaces (wide @3x)
PINION = {"cx": 1054, "cy": 1100, "rx": 64, "ry": 78,       # tooth-root face ellipse
          "boss_cx": 1058, "boss_cy": 1098, "boss_r": 40}
BRACKET = (1394, 1200, 1478, 1265)                           # flat panel rect

XII_POS = (1054, 1152, 24)    # cx, cy, glyph h
VIII_POS = (1436, 1230, 26)

INK = (40, 30, 18)
HI = (238, 212, 156)


def stamp_bbox(stamp, cx, cy, target_h, depth, max_w=None):
    """Exact composited bbox of an `engrave` call (ink layer + hi offset)."""
    w, h = stamp.size
    s = target_h / h
    if max_w and w * s > max_w:
        s = max_w / w
    sw, sh = round(w * s), round(h * s)
    x0 = round(cx - sw / 2)
    y0 = round(cy - sh / 2)
    return (x0, y0, x0 + sw + depth, y0 + sh + depth)


def assert_in_ellipse_annulus(bbox, e):
    """Every bbox corner + edge midpoint inside face ellipse and outside boss."""
    x0, y0, x1, y1 = bbox
    pts = [(x0, y0), (x1, y0), (x0, y1), (x1, y1),
           ((x0 + x1) / 2, y0), ((x0 + x1) / 2, y1),
           (x0, (y0 + y1) / 2), (x1, (y0 + y1) / 2)]
    for px, py in pts:
        v = ((px - e["cx"]) / e["rx"]) ** 2 + ((py - e["cy"]) / e["ry"]) ** 2
        assert v <= 1.0, f"CONTAINMENT FAIL: stamp point ({px},{py}) outside pinion face (v={v:.3f})"
    # no overlap with the boss circle: bbox must not intersect boss disc
    bx, by, br = e["boss_cx"], e["boss_cy"], e["boss_r"]
    ncx = min(max(bx, x0), x1)
    ncy = min(max(by, y0), y1)
    d2 = (ncx - bx) ** 2 + (ncy - by) ** 2
    assert d2 >= br * br, f"CONTAINMENT FAIL: stamp bbox intrudes into boss (d={d2 ** 0.5:.1f} < {br})"


def assert_in_rect(bbox, rect):
    x0, y0, x1, y1 = bbox
    rx0, ry0, rx1, ry1 = rect
    assert x0 >= rx0 and y0 >= ry0 and x1 <= rx1 and y1 <= ry1, \
        f"CONTAINMENT FAIL: stamp bbox {bbox} outside bracket panel {rect}"


def do_stamps(ov, scale=1.0, off=(0, 0), depth=2):
    """Stamp XII + VIII into overlay `ov` at given scale/offset (wide or CU space).
    Returns list of (bbox_in_target_space) for seam accounting."""
    ox, oy = off
    boxes = []
    # XII on pinion face
    cx, cy, gh = XII_POS
    st = tint(render_numeral("XII", 200), INK + (255,))
    h = round(gh * scale)
    mw = round(56 * scale)
    bb_w = stamp_bbox(st, cx, cy, gh, depth / max(scale, 1), max_w=56)
    assert_in_ellipse_annulus(bb_w, PINION)
    engrave(ov, st, (cx - ox) * scale, (cy - oy) * scale, target_h=h, max_w=mw,
            ink=INK, hi=HI, ink_a=230, hi_a=95, depth=depth)
    boxes.append(bb_w)
    # VIII on bracket panel
    cx, cy, gh = VIII_POS
    st = tint(render_numeral("VIII", 200), (30, 22, 14, 255))
    h = round(gh * scale)
    mw = round(76 * scale)
    bb_w = stamp_bbox(st, cx, cy, gh, depth / max(scale, 1), max_w=76)
    assert_in_rect(bb_w, BRACKET)
    engrave(ov, st, (cx - ox) * scale, (cy - oy) * scale, target_h=h, max_w=mw,
            ink=(30, 22, 14), hi=(232, 206, 152), ink_a=235, hi_a=150, depth=depth)
    boxes.append(bb_w)
    return boxes


def fix():
    cur_p = os.path.join(VF, "z2-frame-base@3x.png")
    pre_p = os.path.join(REJ, "z2-frame-base-preglyph@3x.png")
    cur = Image.open(cur_p).convert("RGB")
    pre = Image.open(pre_p).convert("RGB")
    before = cur.copy()

    # 1. erase old stamps
    for x0, y0, x1, y1 in ERASE:
        cur.paste(pre.crop((x0, y0, x1, y1)), (x0, y0))

    # 2+3. re-stamp with containment asserts (wide space)
    out = cur.convert("RGBA")
    ov = Image.new("RGBA", out.size, (0, 0, 0, 0))
    do_stamps(ov, scale=1.0, off=(0, 0), depth=2)
    out.alpha_composite(ov)
    out = out.convert("RGB")

    # 5a. seam audit: every changed pixel vs before must lie in an ERASE bbox
    #     or a new-stamp bbox
    a = np.asarray(before, np.int16)
    b = np.asarray(out, np.int16)
    diff = np.abs(a - b).sum(2)
    ys, xs = np.nonzero(diff > 6)
    zones = list(ERASE) + [
        stamp_bbox(render_numeral("XII", 200), *XII_POS, 2, max_w=56),
        stamp_bbox(render_numeral("VIII", 200), *VIII_POS, 2, max_w=76)]
    stray = 0
    for x, y in zip(xs, ys):
        if not any(zx0 - 1 <= x <= zx1 + 1 and zy0 - 1 <= y <= zy1 + 1
                   for zx0, zy0, zx1, zy1 in zones):
            stray += 1
    assert stray == 0, f"SEAM FAIL: {stray} changed pixels outside sanctioned zones"
    print(f"seam audit PASS: {len(xs)} changed px, all inside erase/stamp zones")

    # 4a. archive + save wide at all densities
    for tag, size in (("3x", None), ("2x", (2560, 1280)), ("1x", (1280, 640))):
        src = os.path.join(VF, f"z2-frame-base@{tag}.png")
        dst = os.path.join(REJ, f"z2-frame-base-b3pre-framefix@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        im = out if size is None else out.resize(size, Image.LANCZOS)
        im.save(os.path.join(VF, f"z2-frame-base@{tag}.png"))

    # 4b. re-crop cu-gear-frame from fixed wide + native-res re-stamp
    _, x0, y0, x1, y1 = FRAMES["cu-gear-frame"]
    s = CU_W / (x1 - x0)
    cu = out.crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS).convert("RGBA")
    lay = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    do_stamps(lay, scale=s, off=(x0, y0), depth=3)
    cu.alpha_composite(lay)
    cu = cu.convert("RGB")
    for tag, size in (("3x", None), ("2x", (1365, 1024)), ("1x", (683, 512))):
        src = os.path.join(VF, f"cu-gear-frame@{tag}.png")
        dst = os.path.join(REJ, f"cu-gear-frame-b3pre-framefix@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        im = cu if size is None else cu.resize(size, Image.LANCZOS)
        im.save(os.path.join(VF, f"cu-gear-frame@{tag}.png"))

    # 5b. before/after review sheet (both stamp regions, CU-scale crops)
    old_cu = Image.open(os.path.join(REJ, "cu-gear-frame-b3pre-framefix@3x.png"))
    rows = []
    for label, bx in (("XII on pinion", (300, 450, 900, 950)),
                      ("VIII on post-A panel", (850, 650, 1450, 1150))):
        o = old_cu.crop(bx).resize((600, 500), Image.LANCZOS)
        n = cu.crop(bx).resize((600, 500), Image.LANCZOS)
        rows.append((label, o, n))
    sheet = Image.new("RGB", (1260, 1090), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    dd.text((10, 4), "cu-gear-frame stamp fix — BEFORE (left) / AFTER (right)", fill=(230, 225, 210))
    for i, (label, o, n) in enumerate(rows):
        y = 30 + i * 530
        sheet.paste(o, (10, y))
        sheet.paste(n, (650, y))
        dd.text((10, y + 505), label, fill=(140, 255, 140))
    sheet.save(os.path.join(A2, "z2", "gearframe-stampfix-before-after.png"))
    print("gear-frame stamp fix done; review sheet saved")


if __name__ == "__main__":
    fix()
