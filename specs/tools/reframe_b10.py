#!/usr/bin/env python3
"""BUILD-10 letterbox re-frame (round-4 BUG-004-class dual-safe-zone fix).

Re-frames each view's 3840x1920 wide plates into the style-guide S8 dual-safe band
(iPad 4:3 crop x[640,3200] + iPhone 19.5:9 band y[74,1846]) so the Developer can
restore .aspectFill: content = uniform scale s + offset (ox,oy); the exposed border
band is filled DETERMINISTICALLY with an edge-replicate smear of the plate, progressively
blurred + darkened + re-grained (vignette). Overscan carries atmosphere only per
style guide S8, so the vignette band is legal; the seam is C0-continuous by
construction (edge padding). Mirror-pad was tested and rejected: it duplicated
objects (second/third moon in the cabinet window band).

NOTE (2026-07-11): the planned nano-banana-pro border OUTPAINT was attempted and
REJECTED: the edit endpoint re-renders the whole scene (registration off by >15
mean-abs even after shift search; content redrawn), violating the binding
"content IDENTICAL, only framing changes" constraint. Outputs archived in
_work-build10/reframe/ for reference. This PIL fallback keeps interior pixels
byte-identical (single LANCZOS resample, same for base + every state variant of
the view, so state swaps stay pixel-aligned by construction).

Usage: python reframe_b10.py            # processes all views/plates listed below
"""
import json
import os

import numpy as np
from PIL import Image, ImageFilter

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"

# view -> (dir, scale, ox, oy, [plate names])
VIEWS = {
    "z1-hearth": ("z1/v-hearth", 0.955, 86, 86,
                  ["z1-hearth-base", "z1-hearth-poker-taken",
                   "z1-hearth-rug-moved", "z1-hearth-trapdoor-open"]),
    "z1-study": ("z1/v-study", 0.86, 538, 240, ["z1-study-base"]),
    "z1-entry": ("z1/v-entry", 0.74, 425, 250,
                 ["z1-entry-base", "z1-entry-basin-drained-nb",
                  "z1-entry-basin-filled-nb", "z1-entry-cage-open",
                  "z1-entry-crow-lintel", "z1-entry-vines-gone",
                  "z1-entry-vines-withered"]),
    "z2-bench": ("z2/v-bench", 0.83, 430, 163, ["z2-bench-base"]),
    "z2-cabinet": ("z2/v-cabinet", 0.70, 630, 288,
                   ["z2-cabinet-base", "z2-cabinet-drawer-open",
                    "z2-cabinet-open"]),
    "z3-cellar": ("z3/v-cellar", 0.82, 445, 173,
                  ["z3-cellar-base", "z3-cellar-barrel-pried",
                   "z3-cellar-beam-alcove", "z3-cellar-beam-blocked",
                   "z3-cellar-beam-floor-shelf-slid", "z3-cellar-beam-floor",
                   "z3-cellar-crank-fitted", "z3-cellar-drawer-open",
                   "z3-cellar-mirror-d2", "z3-cellar-mirror-d3",
                   "z3-cellar-nobeam-nb", "z3-cellar-shelf-slid",
                   "z3-cellar-weight-hung"]),
}

W, H = 3840, 1920
DARKEN_MAX = 0.45     # band darkens up to this fraction at the canvas edge
BLUR_R = 18           # band blur radius
GRAIN = 1.6           # band regrain sigma


def reframe(plate_path, s, ox, oy, rng):
    im = Image.open(plate_path).convert("RGB")
    cw, ch = round(W * s), round(H * s)
    content = np.asarray(im.resize((cw, ch), Image.LANCZOS), dtype=np.float32)
    pl, pt = ox, oy
    pr, pb = W - ox - cw, H - oy - ch
    arr = np.pad(content, ((pt, pb), (pl, pr), (0, 0)), mode="edge")

    # normalized outside-distance t: 0 at content rect edge, 1 at canvas edge
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    tx = np.zeros((H, W), np.float32)
    if pl:
        tx = np.maximum(tx, np.clip((ox - xx) / pl, 0, 1))
    if pr:
        tx = np.maximum(tx, np.clip((xx - (ox + cw - 1)) / pr, 0, 1))
    ty = np.zeros((H, W), np.float32)
    if pt:
        ty = np.maximum(ty, np.clip((oy - yy) / pt, 0, 1))
    if pb:
        ty = np.maximum(ty, np.clip((yy - (oy + ch - 1)) / pb, 0, 1))
    t = np.maximum(tx, ty)

    blurred = np.asarray(Image.fromarray(arr.astype(np.uint8))
                         .filter(ImageFilter.GaussianBlur(BLUR_R)), dtype=np.float32)
    wblur = np.clip(t * 2.5, 0, 1)[..., None]
    out = arr * (1 - wblur) + blurred * wblur
    out *= (1 - DARKEN_MAX * t)[..., None]
    band = t > 0
    noise = rng.normal(0, GRAIN, out.shape).astype(np.float32)
    out[band] += noise[band]
    return Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))


def export(im, out3x):
    im.save(out3x, "PNG")
    w, h = im.size
    im.resize((round(w * 2 / 3), round(h * 2 / 3)), Image.LANCZOS).save(
        out3x.replace("@3x", "@2x"), "PNG")
    im.resize((round(w / 3), round(h / 3)), Image.LANCZOS).save(
        out3x.replace("@3x", "@1x"), "PNG")


if __name__ == "__main__":
    rng = np.random.default_rng(1010)
    manifest = {}
    for view, (d, s, ox, oy, plates) in VIEWS.items():
        for nm in plates:
            src = os.path.join(ROOT, "_work-build10", "reframe", "input",
                               f"{nm}@3x.png")
            dst = os.path.join(ROOT, d, f"{nm}@3x.png")
            out = reframe(src, s, ox, oy, rng)
            export(out, dst)
            print(f"reframed {view}/{nm} (s={s} ox={ox} oy={oy})")
        manifest[view] = {"scale": s, "ox": ox, "oy": oy,
                          "plates": plates,
                          "rect_map": "new_px = old_px * s + (ox, oy)"}
    with open(os.path.join(ROOT, "_work-build10", "reframe",
                           "applied-transforms.json"), "w") as f:
        json.dump(manifest, f, indent=1)
    print("all views reframed")
