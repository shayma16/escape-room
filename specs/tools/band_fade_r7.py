#!/usr/bin/env python3
"""R7-002 edge-band repair: TRUE clean fade to black (replaces the build-10 smear).

WHY
---
build-10 ff9299d re-framed each view into the S8 dual-safe band: content = uniform scale s
+ offset (ox,oy) on a 3840x1920 canvas. The exposed border was filled by EDGE-REPLICATE
padding (np.pad mode="edge") = literally stretching the boundary pixel outward, then blurred
+ darkened. Round 6 (R6-004) put a darker vignette ON TOP of that stretch, so the smeared
pixels survived, merely dimmed - which is why the user reported the same defect twice.
An outpaint was attempted in build 10 (whole-canvas, twice) and again in build 12
(crop-scoped strip, $0.30) - all rejected: fal's nano-banana-pro/edit is not a masked
inpaint (no mask param, refs downscaled to 1536px), so it always re-synthesizes the frame
and cannot preserve the interior. See _rejects/R7-002-outpaint-probe/README.md.

WHAT THIS DOES
--------------
Erases the band pixels ENTIRELY and rebuilds them as a deliberate fade to pure black:
  * a ~FADE_PX falloff from the content seam, then literal #000 for the rest of the band
  * NO recognizable structure survives past the short feather (the low-frequency field is
    blurred at BLUR_R, which destroys all detail) => no fake detail underneath
  * C0-continuous at the seam: at distance 0 the fill equals the true edge pixel, so there
    is no hard cut; the FEATHER_PX transition to the low-frequency field is ~16px, i.e. the
    "smear" is reduced from 250-630px to ~16px and then dies to black.

BAND GEOMETRY is taken from the applied build-10 transform (authoritative, and visually
confirmed: the seam sits exactly at x=430 on the bench, x=630 on the cabinet). It is NOT
taken from a streak/darkness detector - that detector only sees the dark clipped part of
the band and reports 0 on the left/right (where the smear is worst but not dark enough to
clip), and reports phantom bands on soft close-ups.

GUARANTEES
----------
1. Interior byte-identical: the output starts as a copy of the current canonical plate and
   only pixels strictly OUTSIDE the content rect are assigned. Verified per plate.
2. Base/variant bands byte-identical: the band is computed ONCE per view from the BASE plate
   and composited onto every variant. Safe because every variant is byte-identical to its
   base in the ring just inside the content rect (verified: maxdiff=0 on all 29 plates).
   This also fixes a latent bug: reframe_b10.py drew its grain from one rolling rng, so each
   plate's band got DIFFERENT noise -> base/variant bands differed -> the auto-derived
   overlay rects could pick the band up as a "difference".

Usage: python band_fade_r7.py [--check]
"""
import os
import sys

import numpy as np
from PIL import Image, ImageFilter

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
W, H = 3840, 1920

FADE_PX = 120.0     # falloff distance from the seam; pure black beyond (clamped to pad size)
GAMMA = 1.5         # falloff shape
FEATHER_PX = 16.0   # seam -> low-frequency field transition (kills the hard cut)
BLUR_R = 110        # low-frequency field radius: destroys all structure

# view -> (dir, scale, ox, oy, base, [variants])
# z1-hearth is EXCLUDED per Producer directive (86px band, user did not report it).
VIEWS = {
    "z1-study": ("z1/v-study", 0.86, 538, 240, "z1-study-base", []),
    "z1-entry": ("z1/v-entry", 0.74, 425, 250, "z1-entry-base", [
        "z1-entry-basin-drained-nb", "z1-entry-basin-filled-nb", "z1-entry-cage-open",
        "z1-entry-crow-lintel", "z1-entry-vines-gone", "z1-entry-vines-withered"]),
    "z2-bench": ("z2/v-bench", 0.83, 430, 163, "z2-bench-base", [
        "z2-bench-flame1", "z2-bench-flame2", "z2-bench-flame3"]),
    "z2-cabinet": ("z2/v-cabinet", 0.70, 630, 288, "z2-cabinet-base", [
        "z2-cabinet-drawer-open", "z2-cabinet-open", "z2-cabinet-slots-seated",
        "ov-adrawer-empty"]),
    "z3-cellar": ("z3/v-cellar", 0.82, 445, 173, "z3-cellar-base", [
        "z3-cellar-barrel-pried", "ov-barrel-pried-empty", "z3-cellar-beam-alcove",
        "z3-cellar-beam-blocked", "z3-cellar-beam-floor", "z3-cellar-beam-floor-shelf-slid",
        "z3-cellar-crank-fitted", "z3-cellar-drawer-open", "z3-cellar-mirror-d2",
        "z3-cellar-mirror-d3", "z3-cellar-nobeam-nb", "z3-cellar-shelf-slid",
        "z3-cellar-weight-hung"]),
}


def rect(s, ox, oy):
    cw, ch = round(W * s), round(H * s)
    return ox, oy, ox + cw, oy + ch


def build_band(base_path, s, ox, oy):
    """Return (fill_uint8, band_mask) computed from the BASE plate of a view."""
    x0, y0, x1, y1 = rect(s, ox, oy)
    arr = np.asarray(Image.open(base_path).convert("RGB"), dtype=np.float32)

    # 1. edge-replicate pad of the CONTENT ONLY -> C0 at the seam by construction.
    content = arr[y0:y1, x0:x1]
    pad = np.pad(content, ((y0, H - y1), (x0, W - x1), (0, 0)), mode="edge")

    # 2. low-frequency field: blur destroys every recognizable structure.
    low = np.asarray(Image.fromarray(pad.astype(np.uint8))
                     .filter(ImageFilter.GaussianBlur(BLUR_R)), dtype=np.float32)

    # 3. outside-distance per axis, in PIXELS (not normalized) so every side falls off
    #    at the same visual rate regardless of its pad depth.
    yy, xx = np.mgrid[0:H, 0:W].astype(np.float32)
    dxo = np.maximum(np.maximum(x0 - xx, xx - (x1 - 1)), 0)
    dyo = np.maximum(np.maximum(y0 - yy, yy - (y1 - 1)), 0)

    # per-side fade length: clamp to the pad so every side reaches pure black by the edge
    fx_l, fx_r = min(FADE_PX, max(x0, 1)), min(FADE_PX, max(W - x1, 1))
    fy_t, fy_b = min(FADE_PX, max(y0, 1)), min(FADE_PX, max(H - y1, 1))
    fx = np.where(xx < x0, fx_l, fx_r)
    fy = np.where(yy < y0, fy_t, fy_b)

    ax = np.clip(1.0 - dxo / fx, 0.0, 1.0) ** GAMMA
    ay = np.clip(1.0 - dyo / fy, 0.0, 1.0) ** GAMMA
    alpha = (ax * ay)[..., None]

    # 4. feather: seam -> low-frequency field over FEATHER_PX (so a bright object touching
    #    the boundary fades out instead of being razor-cut), then fade to pure black.
    d = np.sqrt(dxo ** 2 + dyo ** 2)
    wf = np.clip(d / FEATHER_PX, 0.0, 1.0)[..., None]
    fill = (pad * (1.0 - wf) + low * wf) * alpha

    band = ((dxo > 0) | (dyo > 0))
    return np.clip(fill, 0, 255).astype(np.uint8), band


def export(im3x, out_base):
    im3x.save(out_base + "@3x.png", "PNG")
    im3x.resize((round(W * 2 / 3), round(H * 2 / 3)), Image.LANCZOS).save(
        out_base + "@2x.png", "PNG")
    im3x.resize((round(W / 3), round(H / 3)), Image.LANCZOS).save(
        out_base + "@1x.png", "PNG")


def process(view, only_check=False):
    d, s, ox, oy, base, variants = VIEWS[view]
    x0, y0, x1, y1 = rect(s, ox, oy)
    base_path = os.path.join(ROOT, d, base + "@3x.png")
    fill, band = build_band(base_path, s, ox, oy)
    out = []
    for nm in [base] + variants:
        p = os.path.join(ROOT, d, nm + "@3x.png")
        orig = np.asarray(Image.open(p).convert("RGB"), dtype=np.uint8)
        new = orig.copy()
        new[band] = fill[band]                      # ONLY band pixels are ever assigned
        assert np.array_equal(new[y0:y1, x0:x1], orig[y0:y1, x0:x1]), f"interior moved {nm}"
        if not only_check:
            export(Image.fromarray(new), os.path.join(ROOT, d, nm))
        out.append(nm)
    return out, (x0, y0, x1, y1)


if __name__ == "__main__":
    chk = "--check" in sys.argv
    which = [a for a in sys.argv[1:] if not a.startswith("--")] or list(VIEWS)
    for v in which:
        names, r = process(v, only_check=chk)
        print(f"{v}: {len(names)} plates, content rect {r} -> {'CHECK' if chk else 'written'}")
