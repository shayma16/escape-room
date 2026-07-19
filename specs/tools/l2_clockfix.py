#!/usr/bin/env python3
"""Level 2 / z2 clockrow numeral-ring fix (step-10 user verdict, 2026-07-19).

Defect: batch-2 stamped the four wall-clock numeral rings from misestimated
dial geometry (DIALS in l2_z2_build) — numerals spilled outside the dial faces
and rode the bezels (worst on clock 1: center was 49px off).

Deterministic fix (same class as the z1 door-dial fix, $0):
  1. ERASE: revert each clock's bbox (cx±280, cy-280..min(cy+280,830)) to the
     preglyph raw (_rejects/z2-clockrow-base-preglyph@3x.png). Verified before
     coding: every changed pixel in those bboxes is old numeral ink; the guard
     band y795-860 above the plates has zero diff, so the brass timezone plates
     (Burj +IV / Big Ben * / Fuji +IX / Liberty -V) are untouched by
     construction, and pixels outside the bboxes stay bit-identical.
  2. RE-STAMP: canonical I-XII ring (l2_glyphs.render_numeral, sheet A) fitted
     INSIDE each measured face: ring radius 0.60*R, fixed 30px glyph height on
     all four clocks, even 30-degree spacing, XII at top, upright (batch-2
     legibility ruling), max_w clamped. Hand-less faces preserved (no hands).
  3. Propagate: @2x/@1x wide downscales + re-crop cu-clockrow-plates (pure
     0.914 downscale crop of the wide, same frame as l2_z2_build.FRAMES).
     Superseded plates -> _rejects/*-b2pre-ringfix.
  4. Review: before/after crop z2/clockrow-ringfix-before-after.png.

Face geometry measured on the preglyph plate (flood-fit for clocks 2/3,
grid-measured for the shadow-cut clocks 1/4):
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral, tint
from l2_z2_build import engrave, FRAMES, CU_W, CU_H

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
VCR = os.path.join(A2, "z2", "v-clockrow")
REJ = os.path.join(A2, "_rejects")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")

# measured face geometry (cx, cy, R) in clockrow @3x — supersedes l2_z2_build.DIALS
DIALS_FIX = [(1047, 578, 180), (1629, 576, 178), (2210, 575, 177), (2790, 567, 181)]
RING_FRAC = 0.60          # numeral-ring center radius as fraction of face R
GLYPH_H = 30              # fixed on all four clocks (consistent size)
NUMS = ["I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]


def fix():
    cur_p = os.path.join(VCR, "z2-clockrow-base@3x.png")
    pre_p = os.path.join(REJ, "z2-clockrow-base-preglyph@3x.png")
    cur = Image.open(cur_p).convert("RGB")
    pre = Image.open(pre_p).convert("RGB")
    before = cur.copy()

    # 1. erase old rings: bbox revert to preglyph (verified = numeral ink only)
    for cx, cy, r in DIALS_FIX:
        x0, y0 = cx - 280, cy - 280
        x1, y1 = cx + 280, min(cy + 280, 830)
        cur.paste(pre.crop((x0, y0, x1, y1)), (x0, y0))

    # 2. re-stamp canonical rings fitted inside the measured faces
    ov = Image.new("RGBA", cur.size, (0, 0, 0, 0))
    for cx, cy, r in DIALS_FIX:
        ring_r = r * RING_FRAC
        for k in range(1, 13):
            ang = math.radians(k * 30 - 90)
            nx = cx + ring_r * math.cos(ang)
            ny = cy + ring_r * math.sin(ang)
            st = tint(render_numeral(NUMS[k - 1], 200), (58, 46, 34, 255))
            engrave(ov, st, nx, ny, target_h=GLYPH_H, rot=0,
                    max_w=int(r * 0.34), ink=(58, 46, 34), hi=(255, 250, 235),
                    ink_a=235, hi_a=55, depth=2)
        # containment assert: ring + glyph extents stay inside the face
        assert ring_r + GLYPH_H / 2 + 2 < r, "numeral ring must fit inside face"
    out = cur.convert("RGBA")
    out.alpha_composite(ov)
    out = out.convert("RGB")

    # 3a. archive superseded canonicals, save fixed wide at all densities
    os.makedirs(REJ, exist_ok=True)
    for tag, size in (("3x", None), ("2x", (2560, 1280)), ("1x", (1280, 640))):
        src = os.path.join(VCR, f"z2-clockrow-base@{tag}.png")
        dst = os.path.join(REJ, f"z2-clockrow-base-b2pre-ringfix@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        im = out if size is None else out.resize(size, Image.LANCZOS)
        im.save(os.path.join(VCR, f"z2-clockrow-base@{tag}.png"))

    # 3b. re-crop cu-clockrow-plates from the fixed wide (pure downscale crop)
    _, x0, y0, x1, y1 = FRAMES["cu-clockrow-plates"]
    cu = out.crop((x0, y0, x1, y1)).resize((CU_W, CU_H), Image.LANCZOS)
    for tag, size in (("3x", None), ("2x", (1365, 1024)), ("1x", (683, 512))):
        src = os.path.join(VCR, f"cu-clockrow-plates@{tag}.png")
        dst = os.path.join(REJ, f"cu-clockrow-plates-b2pre-ringfix@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        im = cu if size is None else cu.resize(size, Image.LANCZOS)
        im.save(os.path.join(VCR, f"cu-clockrow-plates@{tag}.png"))

    # 4. before/after review crop (clock row band incl. plates)
    bb = (760, 260, 3000, 1060)
    bcrop = before.crop(bb).resize((1600, 571), Image.LANCZOS)
    acrop = out.crop(bb).resize((1600, 571), Image.LANCZOS)
    sheet = Image.new("RGB", (1600, 571 * 2 + 60), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    sheet.paste(bcrop, (0, 20))
    sheet.paste(acrop, (0, 571 + 40))
    dd.text((8, 4), "BEFORE — numerals ride the bezels, rings off-center", fill=(255, 120, 100))
    dd.text((8, 571 + 24), "AFTER — canonical rings fitted inside the measured faces", fill=(140, 255, 140))
    sheet.save(os.path.join(A2, "z2", "clockrow-ringfix-before-after.png"))
    print("clockrow ring fix done; review sheet saved")


if __name__ == "__main__":
    fix()
