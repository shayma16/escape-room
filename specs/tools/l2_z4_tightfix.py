#!/usr/bin/env python3
"""Level-2 z4 TIGHT AI-repaint fix for the four smeared state overlays
(ov-key-taken / ov-tag-taken, each CU + wide echo).

User decision 2026-07-21: replace the smeared overlays AND the flat-panel
deterministic reclone with a TIGHT nano-banana /edit masonry continuation,
gate-backstopped by specs/tools/overlay_gate.py.

Method per overlay:
  1. NB /edit an EXPANDED region of the CANONICAL base plate: remove ONLY this
     object, continue the beveled masonry through the gap, keep the round peg.
     NO external refs (the wide-base ref made NB hallucinate the staircase into
     the CU crop). edit_region() shift-registers the result onto the wall.
  2. Composite with a TIGHT HAND-TRACED silhouette mask (object footprint only,
     feathered): inside mask = NB clean pixels, outside = base pixels
     (bit-identical). The peg + lamp are carved out of the mask -> stay
     base-identical. The other object is never in this crop (the four rects are
     spatially disjoint), so object independence is automatic.
  3. Crop to the exact overlay rect -> the state-overlay PNG.
  4. GATE with overlay_gate.run(base_crop, result_crop, mask_crop): BOTH
     seam_delta<=24 AND sharpness_ratio>=0.75 must pass.

Run one overlay at a time:  python l2_z4_tightfix.py <key> <seed>
  <key> in {key-cu, tag-cu, key-wide, tag-wide}
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_nb import edit_region
import overlay_gate

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z4 = os.path.join(A2, "z4", "v-vault-interior")
STATES = os.path.join(Z4, "states")
REJ = os.path.join(A2, "_rejects")
OVJSON = os.path.join(A2, "z4", "z4-state-overlays.json")
MASONRY_REF = os.path.join(REJ, "z4-masonry-styleref-warm.png")
SCRATCH = r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad\z4"

KEY_CONTENT = (
    "Erase ONLY the large brass/iron winding key hanging on the stone wall (its "
    "round bow loop, its straight shaft and its square bit at the bottom). "
    "Do NOT redraw or move anything else - keep the exact same stone-block wall, "
    "the same block layout, the same mortar lines, the same oil lamp and the "
    "same composition and camera. Where the key used to be, simply extend the "
    "surrounding beveled sandstone blocks and mortar courses so the wall reads "
    "as solid unbroken stone with NO key-shaped gap, hole, outline or flat "
    "panel. The filled area MUST be built from individual sandstone BLOCKS separated by clear dark mortar lines with soft beveled edges and the same visible surface grain as the rest of the wall - continue the horizontal mortar courses straight across. It must NOT be a smooth blank plaster panel, a washed-out blur, or a flat object-shaped patch. "
    "Keep the small round stone mounting peg/boss the key hung on exactly "
    "where it is; do NOT draw any nail. Single warm golden-hour light, soft "
    "shadows, same stone colour, bevel and grain as the adjacent blocks.")

TAG_CONTENT = (
    "Erase ONLY the brass return-tag and its woven rope loop hanging on the "
    "stone wall. Do NOT redraw or move anything else - keep the exact same "
    "stone-block wall, the same block layout, the same mortar lines and the same "
    "composition and camera. Where the tag and rope used to be, simply extend "
    "the surrounding beveled sandstone blocks and mortar courses so the wall "
    "reads as solid unbroken stone with NO tag-shaped or rope-shaped gap, hole, "
    "outline or flat panel. The filled area MUST be built from individual sandstone BLOCKS separated by clear dark mortar lines with soft beveled edges and the same visible surface grain as the rest of the wall - continue the horizontal mortar courses straight across. It must NOT be a smooth blank plaster panel, a washed-out blur, or a flat object-shaped patch. "
    "Keep the small round stone mounting peg/boss the "
    "rope hung from exactly where it is; do NOT draw any nail. Single warm "
    "golden-hour light, same stone colour, bevel and grain as the adjacent "
    "blocks.")

# ---- per-overlay geometry (rects in full base-plate px; shapes in rect-LOCAL px) ----
# shapes: list of ("ellipse"|"rect"|"poly", coords) painted into the object mask.
# peg  : ellipse (local) carved OUT of the mask -> stays base-identical.
# lamp : optional box (local) carved out.
# emargin: expand of the rect used as the NB edit region.
CFG = {
    "key-cu": dict(
        ovname="ov-key-taken", plate="cu-key-hook", rect=[667, 300, 1236, 1514],
        content=KEY_CONTENT, emargin=140, dilate=40,
        shapes=[("ellipse", [40, 105, 498, 408]),
                ("poly", [(198, 390), (342, 390), (362, 915), (172, 915)]),
                ("rect", [146, 900, 460, 1172])],
        peg=[278, 146, 372, 256], lamp=[0, 875, 150, 1214]),
    "tag-cu": dict(
        ovname="ov-tag-taken", plate="cu-tag-nail", rect=[227, 170, 1070, 1411],
        content=TAG_CONTENT, emargin=140, dilate=40,
        shapes=[("rect", [396, 466, 750, 1040]),
                ("poly", [(474, 138), (652, 138), (636, 556), (520, 560),
                          (496, 470)])],
        peg=[584, 28, 692, 130], lamp=None),
    "key-wide": dict(
        ovname="ov-key-taken", plate="z4-vault-base", rect=[1000, 415, 1255, 960],
        content=KEY_CONTENT, wide=True, emargin=110, dilate=24,
        shapes=[("ellipse", [20, 26, 220, 194]),
                ("poly", [(88, 182), (170, 182), (184, 400), (68, 400)]),
                ("rect", [48, 392, 220, 545])],
        peg=[120, 46, 186, 120], lamp=[0, 470, 46, 545]),
    "tag-wide": dict(
        ovname="ov-tag-taken", plate="z4-vault-base", rect=[600, 425, 970, 970],
        content=TAG_CONTENT, wide=True, emargin=110, dilate=24,
        shapes=[("rect", [164, 208, 336, 466]),
                ("poly", [(196, 18), (306, 18), (306, 88), (278, 92),
                          (278, 226), (196, 226)])],
        peg=[262, 26, 308, 74], lamp=None),
}


def build_mask(base_full, cfg, rect):
    """TIGHT hand-traced object mask (full-image 'L'); peg/lamp carved out."""
    x0, y0 = rect[0], rect[1]
    full = Image.new("L", base_full.size, 0)
    d = ImageDraw.Draw(full)
    for kind, c in cfg["shapes"]:
        if kind == "ellipse":
            d.ellipse([x0 + c[0], y0 + c[1], x0 + c[2], y0 + c[3]], fill=255)
        elif kind == "rect":
            d.rounded_rectangle([x0 + c[0], y0 + c[1], x0 + c[2], y0 + c[3]],
                                radius=28, fill=255)
        else:
            d.polygon([(x0 + px, y0 + py) for px, py in c], fill=255)
    # dilate enough to fully swallow the object's dark outline + AA halo +
    # its near cast-shadow, so the mask boundary lands on genuinely CLEAN stone
    # (otherwise inpaint/clone samples the dark key edge and re-ghosts it).
    import cv2 as _cv2
    import numpy as _np
    dil = int(cfg.get("dilate", 16))
    ker = _cv2.getStructuringElement(_cv2.MORPH_ELLIPSE, (dil * 2 + 1, dil * 2 + 1))
    fa = _cv2.dilate((_np.asarray(full) > 0).astype("uint8") * 255, ker)
    # extra directional grow for the cast shadow, if specified
    sh = cfg.get("shadow_grow")
    if sh:
        sx, sy = sh
        kx = _cv2.getStructuringElement(_cv2.MORPH_ELLIPSE,
                                        (abs(sx) * 2 + 1, abs(sy) * 2 + 1))
        fa2 = _cv2.dilate(fa, kx)
        # keep growth only on the shadow side by translating
        M = _np.float32([[1, 0, sx], [0, 1, sy]])
        fa2 = _cv2.warpAffine(fa2, M, (fa.shape[1], fa.shape[0]))
        fa = _cv2.max(fa, fa2)
    full = Image.fromarray(fa, "L")
    # carve peg + lamp back to base
    prot = Image.new("L", base_full.size, 0)
    pd = ImageDraw.Draw(prot)
    p = cfg["peg"]
    pd.ellipse([x0 + p[0], y0 + p[1], x0 + p[2], y0 + p[3]], fill=255)
    if cfg.get("lamp"):
        l = cfg["lamp"]
        pd.rectangle([x0 + l[0], y0 + l[1], x0 + l[2], y0 + l[3]], fill=255)
    prot = prot.filter(ImageFilter.MaxFilter(5))
    a = np.asarray(full).copy()
    a[np.asarray(prot) > 0] = 0
    return Image.fromarray(a, "L")


REFINE_CONTENT = (
    "The middle of this stone wall has a rough, stretched, duplicated patch of "
    "stone left by a crude repair. Repaint ONLY that patch as clean, natural, "
    "clearly-stylized sandstone masonry: individual blocks with soft beveled "
    "edges and clear dark mortar lines that line up with and continue the "
    "courses of the surrounding wall, with the same warm lamp-lit shading and "
    "surface grain. Remove all horizontal smearing, mirror-duplication and any "
    "object-shaped tonal ghost so the wall reads as solid, believable, unbroken "
    "stone. There is NO key and NO tag in this area any more - do NOT draw, "
    "carve, emboss or imply any key, tag, tool or object shape here; it is "
    "just bare wall to be covered with ordinary blocks. Do NOT change anything else - keep the exact same composition, "
    "camera, lighting, the round stone mounting peg, and every surrounding "
    "block, lamp and edge pixel-identical. Single warm golden-hour light.")


def seed_fill(base, mask_full, rect_ext):
    """Tonally SEAMLESS object-free seed via a true harmonic (Laplace) membrane
    solved at low resolution. A harmonic function attains its extrema on the
    boundary, so the interior tone is bounded by the CLEAN-wall boundary values
    -> no dark dip, no visible object silhouette (provided the mask was dilated
    enough to clear the object's contact-shadow / AO, which build_mask does).
    Upscaled + blurred = smooth correct-tone base. NB then paints block+mortar
    detail on top."""
    import cv2 as _cv2
    import numpy as _np
    rgb = _np.asarray(base).astype(_np.float32)
    H, W, _ = rgb.shape
    M = (_np.asarray(mask_full) > 40)
    sc = 0.18
    sw, sh = max(16, int(W * sc)), max(16, int(H * sc))
    small = _cv2.resize(rgb, (sw, sh), interpolation=_cv2.INTER_AREA)
    ms = _cv2.resize(M.astype("uint8") * 255, (sw, sh), interpolation=_cv2.INTER_AREA)
    ms = _cv2.dilate((ms > 40).astype("uint8"), _np.ones((3, 3), "uint8"))
    hole = ms > 0
    # seed the hole with the mean of the boundary ring
    ring = (_cv2.dilate(hole.astype("uint8"), _np.ones((5, 5), "uint8")) > 0) & (~hole)
    cur = small.copy()
    for c in range(3):
        cur[hole, c] = small[ring, c].mean()
    # Jacobi harmonic iteration (4-neighbour average), boundary fixed
    for _ in range(800):
        avg = (_np.roll(cur, 1, 0) + _np.roll(cur, -1, 0) +
               _np.roll(cur, 1, 1) + _np.roll(cur, -1, 1)) / 4.0
        cur[hole] = avg[hole]
    filled = _cv2.resize(cur, (W, H), interpolation=_cv2.INTER_CUBIC)
    filled = _cv2.GaussianBlur(filled, (0, 0), 5)
    out = rgb.copy()
    out[M] = filled[M]
    out = _np.clip(out, 0, 255).astype("uint8")
    return Image.fromarray(out)






def process(which, seed, resolution="2K", mode="nbseed"):
    cfg = CFG[which]
    rect = cfg["rect"]
    plate = os.path.join(Z4, cfg["plate"] + "@3x.png")
    base = Image.open(plate).convert("RGB")
    W, H = base.size
    x0, y0, x1, y1 = rect
    m = cfg["emargin"]
    ereg = [max(0, x0 - m), max(0, y0 - m), min(W, x1 + m), min(H, y1 + m)]
    mask = build_mask(base, cfg, rect)

    if mode == "seedonly":
        seeded = seed_fill(base, mask, ereg)
        clean = seeded
        used = "seed-deterministic"
        seeded.crop(ereg).save(os.path.join(SCRATCH, f"seed-{which}.png"))
    elif mode == "nbseed":
        seeded = seed_fill(base, mask, ereg)
        seeded.crop(ereg).save(os.path.join(SCRATCH, f"seed-{which}.png"))
        reg, raw, used = edit_region(seeded, ereg, REFINE_CONTENT, seed,
                                     refs=[MASONRY_REF], tag="z4tight-" + which,
                                     resolution=resolution)
        clean = base.copy()
        clean.paste(reg, (ereg[0], ereg[1]))
    else:  # "nb" -- direct removal
        reg, raw, used = edit_region(base, ereg, cfg["content"], seed,
                                     refs=[MASONRY_REF], tag="z4tight-" + which,
                                     resolution=resolution)
        clean = base.copy()
        clean.paste(reg, (ereg[0], ereg[1]))

    fmask = mask.filter(ImageFilter.GaussianBlur(2.5))
    comp = base.copy()
    comp.paste(clean, (0, 0), fmask)

    result = comp.crop(rect)
    base_crop = base.crop(rect)
    mask_crop = mask.crop(rect)
    result.save(os.path.join(SCRATCH, f"cand-{which}.png"))
    base_crop.save(os.path.join(SCRATCH, f"basecrop-{which}.png"))
    mask_crop.save(os.path.join(SCRATCH, f"maskcrop-{which}.png"))

    mbool = np.asarray(mask_crop) > 40
    scores = overlay_gate.run(np.asarray(base_crop), np.asarray(result), mbool)
    scores.update(which=which, seed_used=used, mask_px=int(mbool.sum()))
    print("GATE", json.dumps(scores))
    print("CANDIDATE saved to scratch; promote with l2_z4_promote.py after visual OK")
    return scores


if __name__ == "__main__":
    which = sys.argv[1]
    seed = int(sys.argv[2]) if len(sys.argv) > 2 else 771010
    resolution = sys.argv[3] if len(sys.argv) > 3 else "2K"
    mode = sys.argv[4] if len(sys.argv) > 4 else "nbseed"
    process(which, seed, resolution, mode)
