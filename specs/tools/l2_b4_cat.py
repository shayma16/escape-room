#!/usr/bin/env python3
"""Batch 4 item 18 — z1 cat pose sprites x4 (NB raws + keyed RGBA).

Generates 4 new poses of the SAME established cat (F3 design: gray-blue #8C8C90
shorthair, amber eyes, pink nose, real-cat proportions, simplified non-noisy
fur, warm sunbeam rim) on a plain cream background, then flood-fill keys the
background to RGBA. Real-cat register (style 9.1): no anthropomorphism, no
collar, no cartoon eyes. Poses: pounce-chase / settled-by-door / stretch /
exit-trot. $0.15 per pose. Incremental (each pose saved before the next).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_nb import generate

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
CATDIR = os.path.join(A2, "z1", "icons", "cat")
REF = os.path.join(CATDIR, "_cat-design-ref.png")
JSON = os.path.join(CATDIR, "cat-sprites.json")

DESIGN = ("Render the SAME cat as in the reference image: a medium gray-blue "
          "(#8C8C90) shorthair house cat, amber eyes, pink nose, real-cat "
          "proportions and simplified non-noisy fur, a subtle warm golden-hour "
          "rim light. A REAL cat — no anthropomorphism, no collar, no cartoon "
          "eyes, no clothing, dignified. Full body, side profile, the whole "
          "cat inside the frame with margin, centered on a PLAIN FLAT pale "
          "cream background (evenly lit, no objects, no floor detail, no "
          "furniture) with only a soft contact shadow under the paws. ")

POSES = {
    "pounce-chase": DESIGN + "Pose: mid-POUNCE — front legs and chest lowered "
    "to the ground, hindquarters raised, about to lunge forward after prey, "
    "tail streamed out behind; intent, focused.",
    "settled-by-door": DESIGN + "Pose: sitting upright in a calm settled "
    "'loaf'-adjacent sit, front paps together, tail curled around, alert but "
    "relaxed, facing to the side (as if waiting by a door).",
    "stretch": DESIGN + "Pose: a big waking STRETCH — front legs extended far "
    "forward and chest low, back arched into a deep downward-dog stretch, "
    "hindquarters up, tail lifted.",
    "exit-trot": DESIGN + "Pose: walking/TROTTING in side profile, mid-stride "
    "with diagonal legs, tail up in a relaxed question-mark, leaving to the "
    "side; calm, purposeful.",
}
SEEDS = {"pounce-chase": 740181, "settled-by-door": 740182,
         "stretch": 740183, "exit-trot": 740184}


def key_cream(raw, thresh=52):
    """Flood-fill the plain cream background + soft contact shadow to alpha.
    Seeds line the whole border so the gradient shadow (which meets cream at
    the bottom) is consumed without touching the cat's warm rim highlights."""
    im = raw.convert("RGB").copy()
    W, H = im.size
    sentinel = (255, 0, 255)
    seeds = []
    for xf in range(0, W, 55):
        seeds += [(min(xf, W - 1), 2), (min(xf, W - 1), H - 3)]
    for yf in range(0, H, 55):
        seeds += [(2, min(yf, H - 1)), (W - 3, min(yf, H - 1))]
    for xy in seeds:
        if im.getpixel(xy) != sentinel:
            ImageDraw.floodfill(im, xy, sentinel, thresh=thresh)
    a = np.asarray(im)
    bg = (a[..., 0] == 255) & (a[..., 1] == 0) & (a[..., 2] == 255)
    o = np.asarray(raw.convert("RGB"), np.int16)
    mn = o.min(2); mx = o.max(2)
    # bright + near-neutral = cream bg / beige contact shadow the floodfill
    # missed (enclosed under a crouched body). The gray cat is not this bright;
    # the warm rim light is saturated (mx-mn large) -> both preserved.
    beige = (mn > 188) & ((mx - mn) < 30)
    alpha = (~(bg | beige)).astype(np.uint8) * 255
    am = Image.fromarray(alpha)
    # clean: keep largest component, close holes, feather
    am = am.filter(ImageFilter.MaxFilter(3)).filter(ImageFilter.MinFilter(3))
    am = am.filter(ImageFilter.GaussianBlur(1.2))
    out = raw.convert("RGBA")
    out.putalpha(am)
    # crop to content bbox + margin
    bbox = am.getbbox()
    if bbox:
        pad = 14
        bbox = (max(0, bbox[0] - pad), max(0, bbox[1] - pad),
                min(W, bbox[2] + pad), min(H, bbox[3] + pad))
        out = out.crop(bbox)
    return out


def main():
    only = sys.argv[1] if len(sys.argv) > 1 else None
    os.makedirs(CATDIR, exist_ok=True)
    meta = json.load(open(JSON)) if os.path.exists(JSON) else {}
    for pose, content in POSES.items():
        if only and pose != only:
            continue
        print(f"cat pose: {pose}")
        raw, seed = generate([REF], content, SEEDS[pose], aspect="3:2",
                             tag=f"cat-{pose}")
        sp = key_cream(raw)
        # normalize long side to ~1100 px (sprite, >=1024 per 7-R3)
        if max(sp.size) < 1024:
            sc = 1100 / max(sp.size)
            sp = sp.resize((int(sp.width * sc), int(sp.height * sc)),
                           Image.LANCZOS)
        sp.save(os.path.join(CATDIR, f"cat-{pose}@3x.png"))
        meta[f"cat-{pose}"] = {
            "sprite": f"cat/cat-{pose}@3x.png", "size_px": list(sp.size),
            "fal_seed": seed,
            "note": f"z1 cat {pose} pose (real-cat register, F3 design; keyed "
            f"RGBA). Developer positions/timing (D3; identical-on-repeat)."}
        json.dump(meta, open(JSON, "w"), indent=1)
        print(f"  {pose}: sprite {sp.size} seed {seed} saved")
    print("cat sprites done")


if __name__ == "__main__":
    main()
