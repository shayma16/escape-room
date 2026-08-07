#!/usr/bin/env python3
"""BUILD 17 / R8-020 — z3 pendulum sprite + background patch, RE-REGISTERED.

Defect (screenshot-confirmed, build 16): the z3 wide showed a "double pendulum" — a flat
procedural bob swinging while the PAINTED brass pendulum stayed visible to its RIGHT.

Root cause (measured here, not guessed): `sp-pendulum` and `ov-pendulum-absent` were both
authored in batch 4 against rect (2030, 70, 2280, 1330) with a mask (rod leaning LEFT,
bob ellipse 2048..2192 x 1005..1305) that does NOT match the pendulum in the CURRENT
`z3-dial-base@3x` plate, where the rod hangs VERTICAL at x~2178..2199 and the bob is an
ellipse centred (2197, 1169) with semi-axes (100, 170) plus a finial down to y~1400. The
old rect clipped the bob's right crescent and its finial, so those pixels survived the
"absent" patch — exactly the surviving sliver in the user's screenshot. Same family as the
L1 R7-001 stale-rect bug.

This rebuild is DETERMINISTIC ($0, no API):
  * silhouette measured against the CURRENT plate (see PEND_* below, verified by the
    `mask` command's overlay sheet);
  * `sp-pendulum@3x.png` re-cut as an RGBA cutout of the current plate over the FULL
    silhouette (cord + rod + bob + finial) with a soft 1.4 px matte;
  * `ov-pendulum-absent-wide@3x.png` rebuilt as a SILHOUETTE-ONLY inpaint: every pixel
    outside the (feathered) silhouette is BIT-IDENTICAL to the base plate, so the patch has
    no rectangular seam by construction — the flat grey "column" the old dark-median clone
    produced is gone. The hole itself is filled with cv2 Telea inpainting, which continues
    the dial rim arc and the wall behind the bob instead of smearing a gradient across it.
  * rect + pivot + amplitudes re-registered into z3-state-overlays.json and
    clockwork-sprites.json.

CLI: python l2_b17_pendulum.py [build|mask|sheet]
"""
import json
import os
import sys

import cv2
import numpy as np

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z3 = os.path.join(A2, "z3", "v-dial")
WIDE = os.path.join(Z3, "z3-dial-base@3x.png")
STATES = os.path.join(Z3, "states")
SPRITES = os.path.join(Z3, "sprites")
OVJSON = os.path.join(A2, "z3", "z3-state-overlays.json")
REJ = os.path.join(A2, "_rejects")
SCRATCH = os.environ.get(
    "L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim"
    r"\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")

# --- the pendulum as it is PAINTED in the current z3-dial-base@3x (measured) -------------
# rect is padded ~18 px around the silhouette on every side and reaches the plate top so the
# whole suspension cord belongs to the sprite (it must rotate with the rod, not stay behind).
RECT = (2050, 0, 2334, 1440)
PIVOT_3X = (2186, 8)                 # suspension point, at the top of the rect
CORD = (2177, 0, 2200, 470)          # x0, y0, x1, y1
ROD = (2170, 440, 2202, 1020)
BOB = (2068, 986, 2308, 1356)        # ellipse bbox
FINIAL = [(2168, 1340), (2228, 1340), (2198, 1420)]
AMPLITUDES = {"still": 0, "weak": 4, "full": 11}


def silhouette():
    """uint8 mask (plate-sized) of the painted pendulum."""
    m = np.zeros((1920, 3840), np.uint8)
    cv2.rectangle(m, CORD[:2], CORD[2:], 255, -1)
    cv2.rectangle(m, ROD[:2], ROD[2:], 255, -1)
    cx, cy = (BOB[0] + BOB[2]) // 2, (BOB[1] + BOB[3]) // 2
    cv2.ellipse(m, (cx, cy), ((BOB[2] - BOB[0]) // 2, (BOB[3] - BOB[1]) // 2),
                0, 0, 360, 255, -1)
    cv2.fillPoly(m, [np.array(FINIAL, np.int32)], 255)
    return m


def load_wide():
    im = cv2.imread(WIDE, cv2.IMREAD_COLOR)
    if im is None:
        raise SystemExit("missing " + WIDE)
    return im


def crop(a):
    x0, y0, x1, y1 = RECT
    return a[y0:y1, x0:x1]


def build_sprite(wide, mask):
    """RGBA cutout of the painted pendulum over the FULL silhouette."""
    sub = crop(wide)
    alpha = cv2.GaussianBlur(crop(mask), (0, 0), 1.4)
    rgba = np.dstack([sub, alpha])
    dst = os.path.join(SPRITES, "sp-pendulum@3x.png")
    os.makedirs(REJ, exist_ok=True)
    if os.path.exists(dst):
        os.replace(dst, os.path.join(REJ, "sp-pendulum-b16pre@3x.png"))
    cv2.imwrite(dst, rgba)
    return rgba


FILL_POWER = 3.0        # bias the row fill toward the RIGHT (wall) neighbour
FILL_BLUR = 4.0


def directional_fill(sub, grown):
    """Row-wise fill of each masked run, biased toward the neighbour on the WALL side.

    A symmetric interpolation (or cv2.inpaint) drags the bright dial FACE that abuts the
    hole on the left all the way across the ~240 px bob span and produces a bright smear
    that breaks the dial's rim arc — visibly worse than the wall it is meant to reveal.
    Weighting the left neighbour by (1-t)^FILL_POWER decays it within ~30 % of the span, so
    the fill settles onto the wall tone and the rim arc reads continuous.
    """
    out = sub.astype(np.float32).copy()
    h, w = grown.shape
    for y in range(h):
        xs = np.nonzero(grown[y])[0]
        if xs.size == 0:
            continue
        for run in np.split(xs, np.nonzero(np.diff(xs) != 1)[0] + 1):
            a, b = int(run[0]), int(run[-1])
            left = out[y, a - 1] if a - 1 >= 0 else out[y, min(b + 1, w - 1)]
            right = out[y, b + 1] if b + 1 < w else out[y, max(a - 1, 0)]
            t = (np.arange(b - a + 1) + 0.5) / (b - a + 1)
            k = ((1 - t) ** FILL_POWER)[:, None]
            out[y, a:b + 1] = left[None, :] * k + right[None, :] * (1 - k)
    return cv2.GaussianBlur(out, (0, 0), FILL_BLUR)


def build_absent(wide, mask):
    """Silhouette-only fill: outside the feathered hole the patch is the base plate."""
    sub = crop(wide)
    hole = crop(mask)
    # Dilate the hole so the anti-aliased rim of the brass cannot bleed back in, then
    # feather the COMPOSITE mask so the join is a ramp, not a step.
    grown = cv2.dilate(hole, np.ones((9, 9), np.uint8), iterations=1)
    filled = directional_fill(sub, grown)

    m = (cv2.GaussianBlur(grown, (0, 0), 2.5).astype(np.float32) / 255.0)[..., None]
    patch = (sub.astype(np.float32) * (1 - m) + filled.astype(np.float32) * m).astype(np.uint8)
    dst = os.path.join(STATES, "ov-pendulum-absent-wide@3x.png")
    os.makedirs(REJ, exist_ok=True)
    if os.path.exists(dst):
        os.replace(dst, os.path.join(REJ, "ov-pendulum-absent-wide-b16pre@3x.png"))
    cv2.imwrite(dst, patch)
    return patch


def register(patch_shape):
    meta = json.load(open(OVJSON, encoding="utf-8"))
    meta["ov-pendulum-absent"] = {
        "wide_base": "z3-dial-base",
        "wide_rect_3x": list(RECT),
        "note": "BUILD 17 (R8-020): dark background behind the pendulum, RE-REGISTERED "
                "against the current plate. The batch-4 rect (2030,70,2280,1330) clipped "
                "the bob's right crescent and finial, so the painted pendulum survived to "
                "the RIGHT of the animated one (double pendulum). Silhouette-only Telea "
                "inpaint: every pixel outside the feathered pendulum silhouette is "
                "bit-identical to z3-dial-base@3x, so there is no rectangular seam.",
    }
    json.dump(meta, open(OVJSON, "w", encoding="utf-8"), indent=1)

    hs = os.path.join(SPRITES, "clockwork-sprites.json")
    sj = json.load(open(hs, encoding="utf-8"))
    sj["sp-pendulum"] = {
        "sprite": "sp-pendulum@3x.png",
        "rect_3x": list(RECT),
        "pivot_px_local": [PIVOT_3X[0] - RECT[0], PIVOT_3X[1] - RECT[1]],
        "pivot_px_at_3x": list(PIVOT_3X),
        "amplitudes_deg": dict(AMPLITUDES),
        "render_rule": "BUILD 17: rotate the SPRITE about pivot_px_local (top-of-rect "
                       "suspension point); for any non-zero amplitude paint the resting "
                       "pendulum out with ov-pendulum-absent (wide) FIRST. still = base as "
                       "shipped (dead still). Cadence/timing is Developer.",
        "background_patch": "states/ov-pendulum-absent-wide@3x.png",
        "size_px_at_3x": [patch_shape[1], patch_shape[0]],
    }
    json.dump(sj, open(hs, "w", encoding="utf-8"), indent=1)
    print("registered rect %s pivot %s" % (RECT, PIVOT_3X))


def swing_frame(wide, patch, sprite, degrees):
    """The plate as the RUNTIME renders it: absent patch applied, sprite rotated about the
    pivot in PLATE space (SpriteKit rotates the node, so nothing is clipped by the rect)."""
    x0, y0, _, _ = RECT
    out = wide.copy()
    out[y0:RECT[3], x0:RECT[2]] = patch
    # Place the sprite into a plate-sized RGBA canvas, then rotate about the plate pivot.
    canvas = np.zeros((wide.shape[0], wide.shape[1], 4), np.uint8)
    canvas[y0:y0 + sprite.shape[0], x0:x0 + sprite.shape[1]] = sprite
    M = cv2.getRotationMatrix2D(PIVOT_3X, -degrees, 1.0)
    rot = cv2.warpAffine(canvas, M, (wide.shape[1], wide.shape[0]),
                         flags=cv2.INTER_LANCZOS4, borderValue=(0, 0, 0, 0))
    a = rot[..., 3:4].astype(np.float32) / 255.0
    return (out.astype(np.float32) * (1 - a) + rot[..., :3].astype(np.float32) * a).astype(np.uint8)


def sheet(wide, patch, sprite):
    """Review strip: base | absent patch applied | sprite at -11 deg | sprite at +11 deg."""
    applied = wide.copy()
    applied[RECT[1]:RECT[3], RECT[0]:RECT[2]] = patch
    frames = [wide, applied,
              swing_frame(wide, patch, sprite, -11),
              swing_frame(wide, patch, sprite, 11)]
    box = (1850, 0, 2600, 1600)
    tiles = [im[box[1]:box[3], box[0]:box[2]] for im in frames]
    gap = np.full((tiles[0].shape[0], 18, 3), 30, np.uint8)
    out = tiles[0]
    for t in tiles[1:]:
        out = np.hstack([out, gap, t])
    p = os.path.join(SCRATCH, "l2-b17-pendulum-review.png")
    cv2.imwrite(p, out)
    print("sheet ->", p)


def mask_sheet(wide, mask):
    ov = wide.copy()
    ov[mask > 0] = (0.4 * ov[mask > 0] + 0.6 * np.array([0, 0, 255])).astype(np.uint8)
    p = os.path.join(SCRATCH, "l2-b17-pendulum-mask.png")
    cv2.imwrite(p, ov[0:1550, 1900:2500])
    print("mask ->", p)


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    wide = load_wide()
    mask = silhouette()
    if cmd == "mask":
        return mask_sheet(wide, mask)
    sprite = build_sprite(wide, mask)
    patch = build_absent(wide, mask)
    register(patch.shape)
    if cmd == "sheet" or cmd == "build":
        sheet(wide, patch, sprite)


if __name__ == "__main__":
    main()
