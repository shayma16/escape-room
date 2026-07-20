#!/usr/bin/env python3
"""Level 2 / z4 "The Clockmaker's Vault" build (batch 3, 2026-07-20).

Base = z4-vault-base (seed 730401) + key-relocation edit (seed 730402)
composited (the generated winding key sat outside the iPad 4:3 band and had a
notched door-key bit; the edit gives a crank-type key with a SQUARE socket-cube
bit at in-band x~1010-1210). Deterministic passes:
  1. promote the composite -> canonical; raw + edit raw -> _rejects.
  2. key bit: fill the cube's through-hole -> SOLID square bit (male), per the
     graph ("large square-bit winding key") rhyming with the z3 drum's square
     socket ABSENCE (9.3 square-drive rhyme; p08 key-into-socket grammar).
  3. tag face: canonical mini FRONT-VIEW dial FIXED at 7:20 (spade hour between
     VII and VIII nearer 7, plain minute on IIII-position tick = 4; same hand
     silhouette language as the z3 sprites) + door die below (masters die).
     Containment asserted inside the measured tag face; 7:20 is the
     clu-return-tag payload (p09).
  4. CUs 23-25 (tag native re-stamp / key hook / shelf lore).
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
Z4 = os.path.join(A2, "z4", "v-vault-interior")
GLY = os.path.join(A2, "masters", "glyphs")
REJ = os.path.join(A2, "_rejects")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")

CU_W, CU_H = 2048, 1536
CU_FRAMES = {
    "cu-tag-nail":  (500, 350, 1400, 1025),
    "cu-key-hook":  (700, 280, 1620, 970),
    "cu-shelf":     (1700, 300, 2980, 1260),
}
SAFE_X = (640, 3200)
SAFE_Y = (154, 1766)

KEY_HOLE = (1128, 858, 1172, 902)          # square through-hole to fill (solid bit)
TAG_FACE = (762, 662, 930, 872)            # measured tag face on the composite
TAG_TILT = -3.0
DIAL_C, DIAL_R = (846, 738), 62            # mini dial center/radius on the tag
DOOR_C, DOOR_H = (846, 838), 46            # door die center/height


def fill_key_hole(im):
    """SOLID square bit: paint the cube's through-hole with iron face shading
    sampled from the cube's own face pixels."""
    im = im.copy()
    a = np.asarray(im, np.float32)
    x0, y0, x1, y1 = KEY_HOLE
    # sample the cube face just left of the hole
    patch = a[y0:y1, x0 - 34:x0 - 6].mean(axis=(0, 1)) * 0.78
    d = ImageDraw.Draw(im)
    d.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2],
                fill=tuple(int(c) for c in patch))
    # subtle vertical gradient + inner bevel line so it reads as a solid face
    ov = Image.new("RGBA", im.size, (0, 0, 0, 0))
    dd = ImageDraw.Draw(ov)
    for k in range(y1 - y0 + 4):
        alpha = int(40 * k / (y1 - y0 + 4))
        dd.line([(x0 - 2, y0 - 2 + k), (x1 + 2, y0 - 2 + k)],
                fill=(0, 0, 0, alpha))
    dd.rectangle([x0 - 2, y0 - 2, x1 + 2, y1 + 2], outline=(28, 24, 20, 120), width=2)
    dd.line([(x0 - 1, y0 - 1), (x1 + 1, y0 - 1)], fill=(200, 190, 175, 34), width=2)
    out = im.convert("RGBA")
    out.alpha_composite(ov.filter(ImageFilter.GaussianBlur(1)))
    return out.convert("RGB")


def stamp_tag(base_rgba, scale=1.0, off=(0, 0)):
    """Mini FRONT-VIEW dial fixed 7:20 + door die on the brass tag. All marks
    containment-asserted inside TAG_FACE and the dual-safe band."""
    ox, oy = off
    cx, cy = DIAL_C
    r = DIAL_R
    fx0, fy0, fx1, fy1 = TAG_FACE
    # containment (plate space): dial circle + door die inside the tag face
    assert fx0 <= cx - r and cx + r <= fx1 and fy0 <= cy - r and cy + r <= fy1, \
        "mini dial outside tag face"
    dx, dyc = DOOR_C
    assert fx0 <= dx - DOOR_H / 2 and dx + DOOR_H / 2 <= fx1 and \
        dyc + DOOR_H / 2 <= fy1, "door die outside tag face"
    assert SAFE_X[0] <= fx0 and fx1 <= SAFE_X[1] and fy1 <= SAFE_Y[1], \
        "tag face out of safe band"

    lay = Image.new("RGBA", base_rgba.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    ink = (52, 38, 18, 235)
    hi = (250, 236, 180, 90)

    def P(x, y):
        return ((x - ox) * scale, (y - oy) * scale)

    # engraved dial ring
    for col, w, dxy in ((hi, 3.2, 1.5), (ink, 3.2, 0)):
        x0, y0 = P(cx - r + dxy, cy - r + dxy)
        x1, y1 = P(cx + r + dxy, cy + r + dxy)
        d.ellipse([x0, y0, x1, y1], outline=col, width=max(2, round(w * scale)))
    # 12 ticks (heavier at 12) + tiny canonical numerals at quarters
    for k in range(12):
        ang = math.radians(k * 30 - 90)
        r0 = r * (0.82 if k % 3 == 0 else 0.88)
        heavy = 3.6 if k == 0 else 2.4
        p0 = P(cx + r0 * math.cos(ang), cy + r0 * math.sin(ang))
        p1 = P(cx + r * 0.97 * math.cos(ang), cy + r * 0.97 * math.sin(ang))
        d.line([p0, p1], fill=ink, width=max(2, round(heavy * scale)))
    for n, ang_deg in (("XII", -90), ("III", 0), ("VI", 90), ("IX", 180)):
        st = tint(render_numeral(n, 200), (52, 38, 18, 255))
        nx = cx + r * 0.64 * math.cos(math.radians(ang_deg))
        ny = cy + r * 0.64 * math.sin(math.radians(ang_deg))
        engrave(lay, st, (nx - ox) * scale, (ny - oy) * scale,
                target_h=int(15 * scale), max_w=int(26 * scale),
                ink=(52, 38, 18), hi=(250, 236, 180), ink_a=235, hi_a=80,
                depth=max(1, round(scale)))
    # hands FIXED at 7:20 — hour (spade, short) at 220 deg, minute (plain,
    # long) at 120 deg from 12
    for ang_deg, ln, kind in ((220, r * 0.52, "spade"), (120, r * 0.80, "plain")):
        a_ = math.radians(ang_deg - 90)
        tipx = cx + ln * math.cos(a_)
        tipy = cy + ln * math.sin(a_)
        d.line([P(cx, cy), P(tipx, tipy)], fill=ink,
               width=max(2, round((4.2 if kind == "spade" else 3.0) * scale)))
        if kind == "spade":
            bx = cx + ln * 0.72 * math.cos(a_)
            by = cy + ln * 0.72 * math.sin(a_)
            half = math.radians(90)
            px1 = (bx + 6.5 * math.cos(a_ + half), by + 6.5 * math.sin(a_ + half))
            px2 = (bx + 6.5 * math.cos(a_ - half), by + 6.5 * math.sin(a_ - half))
            d.polygon([P(tipx, tipy), P(*px1), P(*px2)], fill=ink)
    hubx, huby = P(cx, cy)
    hr = 3.4 * scale
    d.ellipse([hubx - hr, huby - hr, hubx + hr, huby + hr], fill=ink)
    # door die below the dial
    die = Image.open(os.path.join(GLY, "die-door.png")).convert("RGBA")
    engrave(lay, die, (dx - ox) * scale, (dyc - oy) * scale,
            target_h=int(DOOR_H * scale), rot=TAG_TILT, ink=(52, 38, 18),
            hi=(250, 236, 180), ink_a=235, hi_a=90, depth=max(1, round(scale)))
    if TAG_TILT:
        pass  # dial drawn upright; tag tilt is subtle (<3deg) and reads natural
    base_rgba.alpha_composite(lay)


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
    # 1. archive raw + edit raw, promote composite
    for tag in ("1x", "2x", "3x"):
        src = os.path.join(Z4, f"z4-vault-base@{tag}.png")
        dst = os.path.join(REJ, f"z4-vault-base-rawgen@{tag}.png")
        if os.path.exists(src) and not os.path.exists(dst):
            os.replace(src, dst)
    ed = os.path.join(S, "_work", "edit-z4-key@3x.png")
    dst = os.path.join(REJ, "edit-z4-key-raw@3x.png")
    if os.path.exists(ed) and not os.path.exists(dst):
        Image.open(ed).save(dst)
    base = Image.open(os.path.join(S, "z4-composited@3x.png")).convert("RGB")

    # 2. solid square bit
    base = fill_key_hole(base)

    # 2b. blank the UNFINISHED pocket watch's face (generated with a readable
    #     wrong time + markings; a legible time on any dial is clue-material in
    #     this level — the unfinished watch reads blank, which is the point)
    a = np.asarray(base, np.float32)
    fx, fy, fr = 2722, 633, 0  # ellipse below
    ring = a[fy - 30:fy + 30, fx - 30:fx + 30]
    face_col = tuple(int(c) for c in a[fy - 20:fy - 8, fx - 12:fx + 12].mean(axis=(0, 1)))
    # rotated-ellipse blank matched to the tilted face (rx 44, ry 36, rot 33)
    sp = Image.new("RGBA", (120, 120), (0, 0, 0, 0))
    dd = ImageDraw.Draw(sp)
    dd.ellipse([60 - 44, 60 - 36, 60 + 44, 60 + 36], fill=face_col + (255,))
    dd.ellipse([60 - 44, 60 + 10, 60 + 44, 60 + 36], fill=(60, 48, 32, 30))
    sp = sp.rotate(33, resample=Image.BICUBIC)
    sp = sp.filter(ImageFilter.GaussianBlur(0.8))
    b2 = base.convert("RGBA")
    b2.alpha_composite(sp, (fx - 60, fy - 60))
    base = b2.convert("RGB")

    # 3. tag stamped into the wide
    rgba = base.convert("RGBA")
    stamp_tag(rgba, 1.0, (0, 0))
    wide = rgba.convert("RGB")
    save_densities(wide, Z4, "z4-vault-base")
    print("z4 wide integrated")

    # 4. CUs (tag CU re-stamps at native res from the PRE-stamp base)
    for name, (x0, y0, x1, y1) in CU_FRAMES.items():
        s = CU_W / (x1 - x0)
        if name == "cu-tag-nail":
            cu = base.convert("RGBA").crop((x0, y0, x1, y1)).resize(
                (CU_W, CU_H), Image.LANCZOS)
            stamp_tag(cu, s, (x0, y0))
        else:
            cu = wide.convert("RGBA").crop((x0, y0, x1, y1)).resize(
                (CU_W, CU_H), Image.LANCZOS)
        save_densities(cu.convert("RGB"), Z4, name, cu=True)
        print("saved", name)


if __name__ == "__main__":
    main()
