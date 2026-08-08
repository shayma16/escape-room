#!/usr/bin/env python3
"""Level 2 rev-1.4.1 / F1 — the post-A 8-tooth coaxial pinion (LEADS this batch).

Contract (puzzle-graph rev 1.4.1, visually_necessary_elements.z2-workroom + RF-4;
Designer spec clue-legibility-p06-p03.md §1b F1):

  POST A must visibly carry a small pinion of EXACTLY 8 countable teeth, coaxial
  with the empty square arbor, with the canonical VIII stamped on that pinion's
  OWN face annulus -- exactly the treatment the crank's XII pinion already has.
  The bracket-panel VIII engraving is REMOVED.

  RF-4 mesh contract: crank-XII -> [GAP: POST A] -> post-A VIII -> [GAP: POST B]
  -> cam must read as ONE line of drive with TWO identified gaps. With the posts
  empty the crank pinion and the post-A pinion mesh with NOTHING and must not be
  drawn as if they do. Asserted numerically below (NO-MESH GATE).

Deterministic, $0. Geometry source: l2_z2_build.render_gear (the SAME exact-tooth
renderer as the six rack gears + the great wheel); numeral from l2_glyphs
(render_numeral -- the ONE canonical glyph source). Nothing generative.

Placement (measured on the shipped plates, CU space = cu-gear-frame 2048x1536;
wide = z2-frame-base @3x, wide = 660 + cu*0.703125 for both axes):
  post-A bearing collar  CU cx 1121, right edge 1187
  post-A square arbor    CU x 1277..1357 (must stay FREE -- it receives the wheel)
  pinion (this file)     CU centre (1230, 663), tip rx 46 / ry 56
The pinion nests on the arbor between the collar and the square boss: inboard of
the mounting square (so mounting a wheel never removes it from the story) and
outboard of the bearing (so it reads as fixed on the shaft).

Face foreshortening 0.82 (= rx/ry) is taken from the crank pinion's measured face
ellipse (l2_framefix PINION rx64/ry78) so both fixed pinions sit on the same
picture plane; the VIII is squashed by the same factor -> conformal on the face.

Usage: python l2_rev141_pinion.py
"""
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral, tint
import l2_z2_build as z2b
from l2_z2_build import FRAMES, CU_W, CU_H, engrave

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
VF = os.path.join(A2, "z2", "v-frame")
REJ = os.path.join(A2, "_rejects")
TAG = "b17pre-rev141"

# ---- measured geometry -------------------------------------------------------
WX0, WY0, WX1, WY1 = FRAMES["cu-gear-frame"][1:]        # 660,660,2100,1740
S_CU = CU_W / (WX1 - WX0)                                # 1.42222 wide->CU
S_W = 1.0 / S_CU                                         # 0.703125 CU->wide

PIN_CU = (1197.0, 666.0)          # 8t pinion centre, coaxial on the post-A arbor
# TIP radii in CU px.  Sized at the CRANK PINION'S OWN MODULE: the crank's measured
# tooth-root face (l2_framefix rx64/ry78 wide) is z=12, so m = 78/(6-1.25) = 16.4
# wide px; an 8-tooth wheel at that module has r_tip = 5m = 82 wide = 117 CU.  Two
# consequences that are CORRECT and deliberate: (a) 8 teeth are large and trivially
# countable, (b) the pinion is only slightly smaller than the crank's 12t, because
# a low tooth count buys depth, not diameter.  Face squash 0.821 = rx/ry from the
# same measured crank face, so both fixed pinions sit on one picture plane.
PIN_RX, PIN_RY = 70.0, 86.0
PIN_DEPTH = 0.175            # tooth height / tip radius -- the shipped crank
                             # pinion's own short-tooth profile (see render_gear)
PIN_ROT = -3.0                    # same hand-made tilt as the rack gears
TEETH = 8

BOSS_CU = (1272, 585, 1368, 730)  # square arbor boss: stays IN FRONT of the pinion
COLLAR_R_CU = 1187                # bearing collar right edge (pinion is in front)

VIII_H_CU = 26.0                  # VIII cap height on the pinion face (CU px)
VIII_DX_CU = -8.0                 # lower-LEFT of the hub -- the crank XII's own
VIII_DY_CU = 38.0                 # placement, and it stays clear of mounted wheels

# old bracket VIII (l2_framefix stamped it at 1436,1230 h26 max_w76, depth 2)
ERASE_W = (1388, 1203, 1486, 1252)

# RF-4 no-mesh partners, wide @3x
CRANK_W = (1054.0, 1100.0, 74.0)          # cx, cy, tip rx  (l2_framefix PINION)
POSTB_W = (1802.0, 1149.0)                # post-B arbor centre


def pinion_stamp(scale):
    """RGBA 8-tooth brass pinion, tip radii (PIN_RX,PIN_RY)*scale, VIII on face.

    Geometry comes from l2_z2_build.render_gear -- the same renderer, and the same
    exact-tooth-count assertion, as every other gear in the level.  Its built-in
    Arabic web stamp is suppressed (a FIXED pinion carries a Roman stamp, like the
    crank's XII); VIII is engraved afterwards so its size/containment is checked
    against the measured face here.
    """
    rx, ry = PIN_RX * scale, PIN_RY * scale
    SSF = 6
    dia = int(round(2 * ry / 0.98 * SSF))
    # suppress render_gear's Arabic web stamp for this one call
    orig = z2b.render_arabic
    z2b.render_arabic = lambda text, height=400, color=(20, 18, 15, 255): \
        Image.new("RGBA", (4, 4), (0, 0, 0, 0))
    try:
        g = z2b.render_gear(TEETH, dia, ss=1, depth_frac=PIN_DEPTH)  # exact 8-tooth
    finally:
        z2b.render_arabic = orig
    g = g.resize((int(round(2 * rx / 0.98)), int(round(2 * ry / 0.98))),
                 Image.LANCZOS)
    # VIII on the face annulus, squashed by the same rx/ry so it lies ON the face
    st = tint(render_numeral("VIII", 300), (255, 255, 255, 255))
    h = VIII_H_CU * scale
    w = st.width * h / st.height * (rx / ry)
    st = st.resize((max(2, int(round(w))), max(2, int(round(h)))), Image.LANCZOS)
    cx, cy = g.width / 2, g.height / 2
    dx = VIII_DX_CU * scale
    dy = VIII_DY_CU * scale
    # CONTAINMENT GATE: the stamp must sit inside the tooth-ROOT face ellipse and
    # clear of the hub boss -- same class of gate as l2_framefix's.
    r_root_x = rx * (1 - PIN_DEPTH)
    r_root_y = ry * (1 - PIN_DEPTH)
    hub_r = 0.30 * ry
    for px, py in ((dx - st.width / 2, dy - st.height / 2), (dx + st.width / 2, dy - st.height / 2),
                   (dx - st.width / 2, dy + st.height / 2), (dx + st.width / 2, dy + st.height / 2)):
        v = (px / r_root_x) ** 2 + (py / r_root_y) ** 2
        assert v <= 1.0, f"VIII CONTAINMENT FAIL: ({px:.1f},{py:.1f}) v={v:.3f} off the pinion face"
    assert dy - st.height / 2 >= hub_r * 0.62, "VIII CONTAINMENT FAIL: intrudes into the hub boss"
    engrave(g, st, cx + dx, cy + dy, target_h=st.height, max_w=st.width,
            ink=(46, 34, 17), hi=(236, 210, 146), ink_a=238, hi_a=150,
            depth=max(1, int(round(1.6 * scale))))
    if PIN_ROT:
        g = g.rotate(PIN_ROT, expand=True, resample=Image.BICUBIC)
    # SEATING: the deterministic brass comes out at rack-gear value; post A sits in
    # the frame's cooler shadow half, so multiply to the local plate value and warm
    # it a hair (one-sun continuity -- warm spill from frame-right).
    arr = np.asarray(g, np.float32)
    arr[..., 0] *= 0.90
    arr[..., 1] *= 0.87
    arr[..., 2] *= 0.83
    g = Image.fromarray(arr.clip(0, 255).astype(np.uint8), "RGBA")
    # CONTACT SHADOW: light comes from frame-right, so the cast falls down-LEFT.
    sh_off = (int(round(-7 * scale)), int(round(8 * scale)))
    pad = 14
    out = Image.new("RGBA", (g.width + 2 * pad, g.height + 2 * pad), (0, 0, 0, 0))
    sh = Image.new("RGBA", g.size, (18, 12, 6, 0))
    sh.putalpha(g.split()[3].point(lambda v: int(v * 0.42))
                .filter(ImageFilter.GaussianBlur(max(1.5, 3.5 * scale))))
    out.alpha_composite(sh, (pad + sh_off[0], pad + sh_off[1]))
    out.alpha_composite(g, (pad, pad))
    return out


def no_mesh_gate():
    """RF-4: with the posts EMPTY neither fixed pinion may touch anything."""
    cx, cy, r = CRANK_W
    px = WX0 + PIN_CU[0] * S_W
    py = WY0 + PIN_CU[1] * S_W
    pr = PIN_RX * S_W
    d_crank = math.hypot(px - cx, py - cy)
    assert d_crank > (r + pr) * 1.5, "RF-4 FAIL: crank pinion meshes the post-A pinion"
    d_b = math.hypot(px - POSTB_W[0], py - POSTB_W[1])
    assert d_b > pr * 3.0, "RF-4 FAIL: post-A pinion reaches post B"
    print(f"RF-4 no-mesh gate PASS: crank->postA centre gap {d_crank:.0f} wide px "
          f"(sum of radii {r + pr:.0f}); postA->postB gap {d_b:.0f} px "
          f"(pinion tip r {pr:.0f}) -- one drive line, two wheel-sized vacancies")
    return px, py


def dark_mask(im, box, thr=96):
    """Silhouette mask of the dark iron square-arbor boss inside `box`."""
    x0, y0, x1, y1 = box
    a = np.asarray(im.crop(box).convert("RGB"), np.float32).mean(2)
    m = (a < thr).astype(np.uint8) * 255
    return Image.fromarray(m, "L")


def restore():
    """Idempotency: re-runs always start from the archived pre-rev141 canonicals."""
    import shutil
    for stem in ("z2-frame-base", "cu-gear-frame"):
        for t in ("1x", "2x", "3x"):
            src = os.path.join(REJ, f"{stem}-{TAG}@{t}.png")
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(VF, f"{stem}@{t}.png"))


def build():
    restore()
    wide_p = os.path.join(VF, "z2-frame-base@3x.png")
    pre_p = os.path.join(REJ, "z2-frame-base-preglyph@3x.png")
    wide = Image.open(wide_p).convert("RGB")
    before = wide.copy()
    pre = Image.open(pre_p).convert("RGB")

    # 1) ERASE the bracket-panel VIII (F1: the second stage is depicted as
    #    MECHANISM; a duplicate VIII on the timber would read as a label).
    wide.paste(pre.crop(ERASE_W), (ERASE_W[0], ERASE_W[1]))

    px, py = no_mesh_gate()

    # 2) WIDE composite
    out = wide.convert("RGBA")
    g = pinion_stamp(S_W)
    out.alpha_composite(g, (int(round(px - g.width / 2)), int(round(py - g.height / 2))))
    # the square arbor boss is OUTBOARD -> re-assert it in front of the pinion
    bw = tuple(int(round(WX0 + BOSS_CU[i] * S_W)) if i % 2 == 0
               else int(round(WY0 + BOSS_CU[i] * S_W)) for i in range(4))
    m = dark_mask(before, bw)
    patch = before.crop(bw).convert("RGBA")
    patch.putalpha(m)
    out.alpha_composite(patch, (bw[0], bw[1]))
    out = out.convert("RGB")

    for tag, size in (("3x", None), ("2x", (2560, 1280)), ("1x", (1280, 640))):
        src = os.path.join(VF, f"z2-frame-base@{tag}.png")
        dst = os.path.join(REJ, f"z2-frame-base-{TAG}@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        (out if size is None else out.resize(size, Image.LANCZOS)).save(
            os.path.join(VF, f"z2-frame-base@{tag}.png"))

    # 3) CU: re-crop from the integrated wide, then re-render the pinion at NATIVE
    #    CU resolution so the close-up is crisp AND pixel-consistent with the wide.
    cu_src = Image.open(os.path.join(VF, "cu-gear-frame@3x.png")).convert("RGB")
    cu_before = cu_src.copy()
    # erase the old VIII in CU space from the pre-glyph wide, upscaled
    ew_cu = [int(round((ERASE_W[i] - (WX0 if i % 2 == 0 else WY0)) * S_CU))
             for i in range(4)]
    pre_cu = pre.crop((WX0, WY0, WX1, WY1)).resize((CU_W, CU_H), Image.LANCZOS)
    cu_src.paste(pre_cu.crop(tuple(ew_cu)), (ew_cu[0], ew_cu[1]))
    cu = cu_src.convert("RGBA")
    gc = pinion_stamp(1.0)
    cu.alpha_composite(gc, (int(round(PIN_CU[0] - gc.width / 2)),
                            int(round(PIN_CU[1] - gc.height / 2))))
    mc = dark_mask(cu_before, BOSS_CU)
    pc = cu_before.crop(BOSS_CU).convert("RGBA")
    pc.putalpha(mc)
    cu.alpha_composite(pc, (BOSS_CU[0], BOSS_CU[1]))
    cu = cu.convert("RGB")
    for tag, size in (("3x", None), ("2x", (1365, 1024)), ("1x", (683, 512))):
        src = os.path.join(VF, f"cu-gear-frame@{tag}.png")
        dst = os.path.join(REJ, f"cu-gear-frame-{TAG}@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
        (cu if size is None else cu.resize(size, Image.LANCZOS)).save(
            os.path.join(VF, f"cu-gear-frame@{tag}.png"))

    # 4) change-containment audit (wide): every changed pixel inside the erase box
    #    or the pinion/boss footprint.
    a = np.asarray(before, np.int16)
    b = np.asarray(out, np.int16)
    ys, xs = np.nonzero(np.abs(a - b).sum(2) > 6)
    zones = [ERASE_W,
             (int(px - g.width / 2) - 2, int(py - g.height / 2) - 2,
              int(px + g.width / 2) + 2, int(py + g.height / 2) + 2),
             bw]
    stray = sum(1 for x, y in zip(xs, ys)
                if not any(z[0] - 1 <= x <= z[2] + 1 and z[1] - 1 <= y <= z[3] + 1
                           for z in zones))
    assert stray == 0, f"CONTAINMENT FAIL: {stray} changed px outside sanctioned zones"
    print(f"wide change audit PASS: {len(xs)} px changed, all inside erase/pinion/boss zones")

    # 5) review sheet
    old = Image.open(os.path.join(REJ, f"cu-gear-frame-{TAG}@3x.png"))
    bx = (950, 480, 1500, 900)
    sheet = Image.new("RGB", (1220, 500), (24, 22, 20))
    d = ImageDraw.Draw(sheet)
    d.text((10, 6), "F1 post-A 8-tooth pinion + VIII on its own face  --  BEFORE / AFTER",
           fill=(230, 225, 210))
    sheet.paste(old.crop(bx).resize((600, 458), Image.LANCZOS), (2, 30))
    sheet.paste(cu.crop(bx).resize((600, 458), Image.LANCZOS), (614, 30))
    sheet.save(os.path.join(A2, "z2", "postA-pinion-before-after.png"))
    print("F1 done: 8-tooth pinion at post A, VIII on its face, bracket VIII removed")


if __name__ == "__main__":
    build()
