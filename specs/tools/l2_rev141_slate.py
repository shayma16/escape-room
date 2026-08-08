#!/usr/bin/env python3
"""Level 2 rev-1.4.1 / F2 — the slate compares like with like.

Contract (puzzle-graph rev 1.4.1 clu-slate-ratio + visually_necessary_elements.z1-attic;
Designer spec §1b F2; Validator RC-3):

  1. The crank circle's 24 tallies are GROUPED IN FIVES -- four groups of five
     (four radial uprights closed by a diagonal FIFTH stroke) plus four singles.
     The hard exact-count contract (= 24) is preserved and re-asserted here.
  2. The cam circle gains ONE tally stroke on its rim, in the IDENTICAL chalk
     stroke style, alongside (not replacing) its physical single notch -- so the
     ratio reads as a direct like-for-like proportion of MARKS.
  3. RC-3: the cam tally is spatially far from the 24-block (different circle,
     ~700 rectified units away) so no player can read a total of 25; and the
     group-closing diagonal is angle- and length-matched to the four uprights it
     closes and never overshoots them, so it reads as a FIFTH STROKE, not a
     strike-out.
  4. Nothing else on the slate changes: XII pinion, two '?' wheels, VIII coaxial
     pinion, cam notch and door die are byte-identical in content to the approved
     plate.

Deterministic PIL, $0.  Re-renders the whole slate schematic through the SAME
renderer that authored the approved plate (l2_z1_build.ov_slate, copied here with
only the tally block changed), over a clean slate surface restored from the
pre-glyph raw, then re-integrates the wide and re-cuts cu-slate from it.

Usage: python l2_rev141_slate.py
"""
import math
import os
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral, die_door, tint
import l2_z1_build as z1b
from l2_z1_build import (FRAMES, WIDES, CU_W, CU_H, BONE, to_cu, quad_warp,
                         chalkify)

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
VB = os.path.join(A2, "z1", "v-bench")
REJ = os.path.join(A2, "_rejects")
TAG = "b17pre-rev141"

SLATE_QUAD_W = [(1610, 405), (2160, 420), (2220, 1235), (1655, 1255)]
ERASE_W = (1596, 391, 2234, 1269)          # quad bbox + margin, wide @3x

# ---- tally geometry (rectified 720x1000 slate space) -------------------------
C1, R1 = (190, 155), 95        # crank circle
TICK_IN, TICK_OUT = 8, 40      # radial tick, measured from the circle
TICK_W = 5
D_ANG = 9.0                    # angular pitch between uprights inside a group
CLUSTERS = [55.0, 127.0, 199.0, 271.0, 343.0]   # 4 groups of five + 1 of four
C6, R6 = (552, 886), 55        # cam circle
CAM_TALLY_ANG = 168.0          # cam-rim tally: opposite the notch and the door die


def _radial(d, c, r, ang_deg, r0, r1_, w):
    a = math.radians(ang_deg)
    d.line([(c[0] + (r + r0) * math.cos(a), c[1] + (r + r0) * math.sin(a)),
            (c[0] + (r + r1_) * math.cos(a), c[1] + (r + r1_) * math.sin(a))],
           fill=BONE + (255,), width=w)


def draw_tally_ring(d):
    """24 marks on the crank rim, grouped in fives. Returns the exact count."""
    n = 0
    for k, a0 in enumerate(CLUSTERS):
        count = 5 if k < 4 else 4
        uprights = 4 if count == 5 else 4          # both shapes carry 4 uprights
        for i in range(uprights):
            _radial(d, C1, R1, a0 + i * D_ANG, TICK_IN, TICK_OUT, TICK_W)
            n += 1
        if count == 5:
            # the FIFTH stroke: a diagonal closing exactly the four it crosses --
            # inner end at the first upright, outer end at the last. No overshoot
            # (RC-3): its angular span equals the group's own span.
            a_lo = math.radians(a0)
            a_hi = math.radians(a0 + 3 * D_ANG)
            p0 = (C1[0] + (R1 + TICK_IN) * math.cos(a_lo),
                  C1[1] + (R1 + TICK_IN) * math.sin(a_lo))
            p1 = (C1[0] + (R1 + TICK_OUT) * math.cos(a_hi),
                  C1[1] + (R1 + TICK_OUT) * math.sin(a_hi))
            d.line([p0, p1], fill=BONE + (255,), width=TICK_W)
            n += 1
    return n


def ov_slate_v2():
    """l2_z1_build.ov_slate with the F2 tally changes. Everything else verbatim."""
    name = "cu-slate"
    ov = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    q = [to_cu(name, *p) for p in SLATE_QUAD_W]
    R = Image.new("RGBA", (720, 1000), (0, 0, 0, 0))
    d = ImageDraw.Draw(R)
    W_ = 7

    def circ(c, r, w=W_):
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r],
                  outline=BONE + (255,), width=w)

    def dot(c, r=6):
        d.ellipse([c[0] - r, c[1] - r, c[0] + r, c[1] + r], fill=BONE + (255,))

    # 1) crank circle + EXACTLY 24 tallies, GROUPED IN FIVES (F2 change)
    c1, r1 = C1, R1
    circ(c1, r1)
    dot(c1)
    d.line([c1, (c1[0] + 52, c1[1] - 52)], fill=BONE + (255,), width=W_)
    dot((c1[0] + 58, c1[1] - 58), 9)
    n_tally = draw_tally_ring(d)
    assert n_tally == 24, f"slate tally contract: {n_tally} != 24"
    # 2) mesh line to pinion XII
    d.line([(258, 218), (430, 292)], fill=BONE + (255,), width=4)
    c2, r2 = (474, 322), 47
    circ(c2, r2)
    # 3) wheel A '?' + coaxial pinion VIII below-left via axis connector
    c3, r3 = (330, 490), 108
    circ(c3, r3)
    dot(c3)
    for t in np.linspace(0.45, 0.9, 4):
        p = (c3[0] + (240 - c3[0]) * t, c3[1] + (612 - c3[1]) * t)
        dot(p, 4)
    c4, r4 = (238, 628), 46
    circ(c4, r4)
    # 4) wheel B '?'
    c5, r5 = (430, 762), 108
    circ(c5, r5)
    dot(c5)
    for a_, b_ in (((410, 380), (438, 408)), ((300, 672), (330, 700))):
        d.line([a_, b_], fill=BONE + (255,), width=4)
        d.line([(a_[0] + 14, a_[1] - 10), (b_[0] + 14, b_[1] - 10)],
               fill=BONE + (255,), width=4)
    # 5) cam circle: dotted axis from wheel B, one notch + door die + ONE TALLY
    for t in np.linspace(0.5, 0.85, 3):
        dot((c5[0] + (545 - c5[0]) * t, c5[1] + (884 - c5[1]) * t), 4)
    c6, r6 = C6, R6
    circ(c6, r6)
    dot(c6)
    d.polygon([(552 + 55, 886 - 10), (552 + 55, 886 + 10), (552 + 34, 886)],
              fill=(20, 22, 26, 255))
    # F2(2): the like-for-like mark -- IDENTICAL stroke width and length to the
    # crank rim's tallies, on the cam's own rim, clear of the notch and door die.
    _radial(d, c6, r6, CAM_TALLY_ANG, TICK_IN, TICK_OUT, TICK_W)
    # question marks
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


def restore():
    for stem in ("z1-bench-base", "cu-slate"):
        for t in ("1x", "2x", "3x"):
            src = os.path.join(REJ, f"{stem}-{TAG}@{t}.png")
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(VB, f"{stem}@{t}.png"))


def build():
    restore()
    wide_p = os.path.join(VB, "z1-bench-base@3x.png")
    pre_p = os.path.join(REJ, "z1-bench-base-preglyph@3x.png")
    wide = Image.open(wide_p).convert("RGB")
    before = wide.copy()
    pre = Image.open(pre_p).convert("RGB")

    # 1) restore a CLEAN slate surface inside the schematic's bbox
    wide.paste(pre.crop(ERASE_W), (ERASE_W[0], ERASE_W[1]))

    # 2) re-draw the schematic, downscale into the wide's cu-slate frame
    ov = ov_slate_v2()
    _, x0, y0, x1, y1 = FRAMES["cu-slate"]
    out = wide.convert("RGBA")
    out.alpha_composite(ov.resize((x1 - x0, y1 - y0), Image.LANCZOS), (x0, y0))
    out = out.convert("RGB")

    # containment audit: nothing changed outside the slate bbox
    a = np.asarray(before, np.int16)
    b = np.asarray(out, np.int16)
    ys, xs = np.nonzero(np.abs(a - b).sum(2) > 6)
    stray = int(((xs < ERASE_W[0]) | (xs > ERASE_W[2]) |
                 (ys < ERASE_W[1]) | (ys > ERASE_W[3])).sum())
    assert stray == 0, f"CONTAINMENT FAIL: {stray} changed px outside the slate bbox"
    print(f"wide change audit PASS: {len(xs)} px changed, all inside the slate quad bbox")

    for tag, size in (("3x", None), ("2x", (2560, 1280)), ("1x", (1280, 640))):
        src = os.path.join(VB, f"z1-bench-base@{tag}.png")
        dst = os.path.join(REJ, f"z1-bench-base-{TAG}@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        (out if size is None else out.resize(size, Image.LANCZOS)).save(
            os.path.join(VB, f"z1-bench-base@{tag}.png"))

    # 3) re-cut cu-slate FROM the integrated wide + native-res overlay re-composite
    cu = out.crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS).convert("RGBA")
    cu.alpha_composite(ov)
    cu = cu.convert("RGB")
    for tag, size in (("3x", None), ("2x", (1365, 1024)), ("1x", (683, 512))):
        src = os.path.join(VB, f"cu-slate@{tag}.png")
        dst = os.path.join(REJ, f"cu-slate-{TAG}@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        (cu if size is None else cu.resize(size, Image.LANCZOS)).save(
            os.path.join(VB, f"cu-slate@{tag}.png"))

    # 4) review sheet
    old = Image.open(os.path.join(REJ, f"cu-slate-{TAG}@3x.png"))
    sheet = Image.new("RGB", (1224, 500), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    dd.text((10, 6), "F2 slate: 24 tallies grouped in fives + ONE matching tally on the cam rim"
                     "  --  BEFORE / AFTER", fill=(230, 225, 210))
    bx = (300, 200, 1500, 1100)
    sheet.paste(old.crop(bx).resize((600, 450), Image.LANCZOS), (2, 30))
    sheet.paste(cu.crop(bx).resize((600, 450), Image.LANCZOS), (614, 30))
    sheet.save(os.path.join(A2, "z1", "slate-regroup-before-after.png"))
    print("F2 done: 24 tallies in fives (4x5 + 4 singles) + cam-rim tally; = 24 asserted")


if __name__ == "__main__":
    build()
