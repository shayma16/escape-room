#!/usr/bin/env python3
"""Batch 4 item 19 — z1 cat facial keys on cu-cat-cushion (1 NB edit + PIL).

The cushion cat sleeps (eyes closed). ONE nano-banana edit opens its eyes into
an alert amber LOCKED gaze (the mouse-tell, D3 — carried by eyes + tail only,
body stays settled). From that we derive:
  ov-cat-mouse-tell  : eyes open + locked (NB eye region) + tail flick (PIL)
  ov-cat-slow-blink  : half-lidded eyes (PIL blend base<->open) — the slow blink
  ov-cat-tail-flick  : tail-tip lifted (PIL warp) — the tail half of the tell
All on cu-cat-cushion. Real-cat register (9.1): no cartoon eyes. $0.15.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_nb import edit_region
from l2_b4_states import seam

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
ZD = os.path.join(A2, "z1", "v-door")
CU = os.path.join(ZD, "cu-cat-cushion@3x.png")
STATES = os.path.join(ZD, "states")
JSON = os.path.join(A2, "z1", "z1-cat-face.json")
FACE = (560, 200, 1180, 640)        # head/eyes region
EYE = (740, 360, 1080, 520)         # tight eye band (for blend + change mask)
TAIL = (1330, 300, 1720, 620)       # curled tail tip


def main():
    base = Image.open(CU).convert("RGB")
    content = ("the cat's closed sleeping eyes are now OPEN: round alert AMBER "
               "eyes, awake, LOCKED and tracking something just off to the "
               "lower-left (a fixed intent gaze). Keep it a REAL cat (no "
               "cartoon eyes). The head, ears, muzzle, whiskers, fur, body "
               "pose, cushion and warm lighting stay otherwise identical.")
    reg, raw, seed = edit_region(base, FACE, content, 740191, tag="z1-catface")
    print("  fal seed:", seed)
    x0, y0, x1, y1 = FACE
    b = np.asarray(base.crop(FACE), np.int16)
    e = np.asarray(reg, np.int16)
    # accept only the eye band changes (keep muzzle/fur pristine)
    ch = np.abs(e - b).max(2) > 22
    box = np.zeros(b.shape[:2], bool)
    box[(EYE[1] - y0):(EYE[3] - y0), (EYE[0] - x0):(EYE[2] - x0)] = True
    acc = ch & box
    m = Image.fromarray((acc * 255).astype(np.uint8)).filter(
        ImageFilter.MaxFilter(5)).filter(ImageFilter.GaussianBlur(3))
    openface = base.copy()
    openface.paste(reg, (x0, y0), m)

    os.makedirs(STATES, exist_ok=True)
    meta = {}

    def tail_flick(img):
        """Lift the curled tail tip (localized upward warp)."""
        out = img.copy()
        tx0, ty0, tx1, ty1 = TAIL
        tip = img.crop(TAIL)
        # shear the tip upward toward the right (flick up)
        w, h = tip.size
        coeffs = (1, 0, 0, 0.12, 1, -26)   # affine: raise right side
        warped = tip.transform((w, h), Image.AFFINE, coeffs,
                               resample=Image.BICUBIC)
        tm = Image.new("L", (w, h), 0)
        ImageDraw.Draw(tm).ellipse([int(w*0.30), 0, w, h], fill=255)
        tm = tm.filter(ImageFilter.GaussianBlur(10))
        out.paste(warped, (tx0, ty0), tm)
        return out

    # mouse-tell = eyes open + tail flick
    mt = tail_flick(openface)
    r = (EYE[0] - 20, EYE[1] - 20, EYE[2] + 20, EYE[3] + 20)
    patch = mt.crop(r)
    sc = seam(base, patch, r); assert sc <= 24, sc
    patch.save(os.path.join(STATES, "ov-cat-mouse-tell@3x.png"))
    tr = (TAIL[0] - 10, TAIL[1] - 10, TAIL[2] + 10, TAIL[3] + 10)
    tpatch = mt.crop(tr)
    tsc = seam(base, tpatch, tr)
    tpatch.save(os.path.join(STATES, "ov-cat-mouse-tell-tail@3x.png"))
    meta["ov-cat-mouse-tell"] = {
        "base": "cu-cat-cushion", "rect_3x": list(r), "tail_rect_3x": list(tr),
        "note": "mouse-tell (D3): eyes open + amber locked gaze tracking the "
        "offered mouse + tail-tip flick; body stays settled. Two patches "
        "(eyes + tail) so the Developer can flick the tail on a separate beat. "
        f"eye seam {sc:.1f}, tail seam {tsc:.1f}."}

    # slow-blink = half-lid: blend closed(base) <-> open at 0.5 over the eye
    halfa = np.asarray(base.crop(r), np.float32)
    halfb = np.asarray(openface.crop(r), np.float32)
    # heavier weight to the CLOSED lid low in the eye (half-lidded look)
    blend = (0.52 * halfb + 0.48 * halfa)
    half = Image.fromarray(np.clip(blend, 0, 255).astype(np.uint8))
    # feather to base at patch edge
    fm = Image.new("L", half.size, 0)
    ImageDraw.Draw(fm).rectangle([8, 8, half.width-9, half.height-9], fill=255)
    fm = fm.filter(ImageFilter.GaussianBlur(6))
    half = Image.composite(half, base.crop(r), fm)
    sc2 = seam(base, half, r); assert sc2 <= 24, sc2
    half.save(os.path.join(STATES, "ov-cat-slow-blink@3x.png"))
    meta["ov-cat-slow-blink"] = {
        "base": "cu-cat-cushion", "rect_3x": list(r),
        "note": "slow-blink half-lid (9.1 slow blink): 0.52 open / 0.48 closed "
        f"blend over the eye band; the refusal/contentment tell. seam {sc2:.1f}."}

    # tail-flick standalone (tail half of the tell, reusable)
    tf = tail_flick(base)
    tfp = tf.crop(tr)
    tfsc = seam(base, tfp, tr)
    tfp.save(os.path.join(STATES, "ov-cat-tail-flick@3x.png"))
    meta["ov-cat-tail-flick"] = {
        "base": "cu-cat-cushion", "rect_3x": list(tr),
        "note": f"tail-tip flick (PIL upward shear); tail half of the tell / "
        f"idle. seam {tfsc:.1f}."}

    json.dump(meta, open(JSON, "w"), indent=1)
    print(f"  eyes seam {sc:.1f} / blink {sc2:.1f} / tail {tfsc:.1f}")
    print("z1-cat-face.json written")


if __name__ == "__main__":
    main()
