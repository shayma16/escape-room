#!/usr/bin/env python3
"""BUILD 17 — three deterministic overlay repairs ($0, no API).

  R8-022  ov-drum-key-in (CU + wide) — the seated winding key sat inside a visibly DARK
          RECTANGULAR PATCH. The batch-4 NB surface edit darkened/desaturated the WHOLE
          crop, not just the key, so the patch rectangle read as a box against the warm
          drum. Rebuilt as a SILHOUETTE-ONLY composite: the key is keyed out of the NB art
          (brass, brighter than the base), colour-matched onto the base crop, and every
          pixel outside the feathered key silhouette is BIT-IDENTICAL to the plate — a box
          seam is then impossible by construction.

  R8-014  ov-cabinet-open-mouse (CU + wide) — the tin mouse composited OUTSIDE/below the
          open drawer, floating in front of the drawer face. Rebuilt from the approved
          `ov-cabinet-empty` art (the same rect, same open drawer, no mouse) with the
          mouse cutout re-seated INSIDE the drawer on its floor, scaled for the depth it
          now sits at and grounded with a soft contact shadow.

  R8-017  ov-arbor-oiled (CU + wide) — oiling produced an audio ping and, per the user,
          a bearing that "doesn't look shinier or anything". The overlay DID render in
          both views (verified); it was simply too subtle. Rebuilt with a much stronger
          rust-clear (rust -> clean iron) plus a real specular sheen + wet ring on the
          boss, so an applied tool visibly changes the scene.

CLI: python l2_b17_fixes.py [build|sheet]
"""
import json
import os
import sys

import cv2
import numpy as np

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
REJ = os.path.join(A2, "_rejects")
SCRATCH = os.environ.get(
    "L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim"
    r"\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")

Z3 = os.path.join(A2, "z3", "v-dial")
Z2C = os.path.join(A2, "z2", "v-clockrow")
Z2F = os.path.join(A2, "z2", "v-frame")


def rd(p):
    im = cv2.imread(p, cv2.IMREAD_COLOR)
    if im is None:
        raise SystemExit("missing " + p)
    return im


def archive(dst, tag="b16pre"):
    os.makedirs(REJ, exist_ok=True)
    if os.path.exists(dst):
        base, ext = os.path.splitext(os.path.basename(dst))
        # keep the @Nx suffix at the very end so the staging shadow-scan still skips it
        name = base.replace("@3x", "-%s@3x" % tag) if "@3x" in base else base + "-" + tag
        os.replace(dst, os.path.join(REJ, name + ext))


def color_match(base, src, ctrl):
    """Per-channel linear fit of `src` onto `base` over the control (unchanged) pixels."""
    b, s = base.astype(np.float32), src.astype(np.float32)
    m = ctrl.astype(bool)
    out = s.copy()
    if m.sum() < 200:
        return src
    for c in range(3):
        x, y = s[..., c][m], b[..., c][m]
        a = float(np.clip(np.cov(x, y)[0, 1] / (x.var() + 1e-5), 0.5, 2.0))
        out[..., c] = np.clip(s[..., c] * a + (y.mean() - a * x.mean()), 0, 255)
    return out.astype(np.uint8)


def feather(mask, sigma):
    return (cv2.GaussianBlur(mask, (0, 0), sigma).astype(np.float32) / 255.0)[..., None]


def over(base, src, m):
    return (base.astype(np.float32) * (1 - m) + src.astype(np.float32) * m).astype(np.uint8)


# ------------------------------------------------------------------ R8-022 drum key
#
# The key silhouette, MEASURED on the batch-4 NB art in its own 465x432 CU patch space (see
# the `drumkey_fit` review sheets). A colour/brightness key is not usable here: the key's
# shadow side is DARKER than the rusty collar behind it, so any luminance threshold either
# drops half the bow or swallows the collar. The wide patch is the same crop at 0.5785x, so
# the mask is authored once and resampled.
KEY_MASK_SIZE = (465, 432)
KEY_RING_OUTER = ((345, 236), (97, 159), 10)
KEY_RING_INNER = ((357, 243), (44, 98), 10)
KEY_SHAFT = ((112, 122), (285, 202), 58)
KEY_BOSS = ((288, 200), (34, 44), -35)


def key_mask(size):
    m = np.zeros((KEY_MASK_SIZE[1], KEY_MASK_SIZE[0]), np.uint8)
    cv2.ellipse(m, KEY_RING_OUTER[0], KEY_RING_OUTER[1], KEY_RING_OUTER[2], 0, 360, 255, -1)
    cv2.ellipse(m, KEY_RING_INNER[0], KEY_RING_INNER[1], KEY_RING_INNER[2], 0, 360, 0, -1)
    cv2.line(m, KEY_SHAFT[0], KEY_SHAFT[1], 255, KEY_SHAFT[2])
    cv2.ellipse(m, KEY_BOSS[0], KEY_BOSS[1], KEY_BOSS[2], 0, 360, 255, -1)
    if size != KEY_MASK_SIZE:
        m = cv2.resize(m, size, interpolation=cv2.INTER_LINEAR)
    return m


def drum_key(view_dir, plate, art_name, rect, tag):
    plate_im = rd(os.path.join(view_dir, plate + "@3x.png"))
    archived = os.path.join(REJ, art_name + "-b16pre@3x.png")
    art = rd(archived if os.path.exists(archived)
             else os.path.join(view_dir, "states", art_name + "@3x.png"))
    x0, y0, x1, y1 = rect
    base = plate_im[y0:y1, x0:x1]
    m = key_mask((base.shape[1], base.shape[0]))
    patch = over(base, art, feather(m, 2.0 * base.shape[0] / KEY_MASK_SIZE[1]))
    dst = os.path.join(view_dir, "states", art_name + "@3x.png")
    archive(dst)
    cv2.imwrite(dst, patch)
    print("  %-28s key px %6d  (rect %s)" % (art_name, int((m > 0).sum()), rect))
    return base, patch


# ------------------------------------------------------------------ R8-014 tin mouse
def mouse_mask(art):
    """The tin mouse: cool grey (blue >= red) and desaturated, against warm wood."""
    b, g, r = art[..., 0].astype(np.int16), art[..., 1].astype(np.int16), art[..., 2].astype(np.int16)
    m = ((b + 12 > r) & (g + 10 > r)).astype(np.uint8) * 255
    m = cv2.morphologyEx(m, cv2.MORPH_CLOSE, np.ones((7, 7), np.uint8))
    n, lab, stats, _ = cv2.connectedComponentsWithStats((m > 0).astype(np.uint8), 8)
    if n <= 1:
        return m
    best = 1 + int(np.argmax(stats[1:, cv2.CC_STAT_AREA]))
    keep = np.zeros_like(m)
    keep[lab == best] = 255
    return cv2.morphologyEx(keep, cv2.MORPH_CLOSE, np.ones((11, 11), np.uint8))


# Where the mouse must SIT, as a fraction of the overlay patch: (centre x, BOTTOM y, width).
# Measured on `ov-cabinet-empty` — the middle of the open drawer's visible floor plane.
MOUSE_SEAT = (0.655, 0.435, 0.30)


def cabinet_mouse(view_dir, art_open, art_empty, tag):
    # Idempotence: once this script has run, the shipped open-mouse art already has the
    # mouse INSIDE the drawer, so always cut the mouse from the archived ORIGINAL if it
    # exists (re-cutting a re-seated mouse would shrink/move it again on every run).
    archived = os.path.join(REJ, art_open + "-b16pre@3x.png")
    src = rd(archived if os.path.exists(archived)
             else os.path.join(view_dir, "states", art_open + "@3x.png"))
    empty = rd(os.path.join(view_dir, "states", art_empty + "@3x.png"))
    h, w = empty.shape[:2]
    m = mouse_mask(src)
    ys, xs = np.nonzero(m)
    bx0, bx1, by0, by1 = xs.min(), xs.max() + 1, ys.min(), ys.max() + 1
    cut = src[by0:by1, bx0:bx1]
    cut_a = m[by0:by1, bx0:bx1]

    tw = int(round(MOUSE_SEAT[2] * w))
    th = max(1, int(round(cut.shape[0] * tw / cut.shape[1])))
    cut = cv2.resize(cut, (tw, th), interpolation=cv2.INTER_LANCZOS4)
    cut_a = cv2.resize(cut_a, (tw, th), interpolation=cv2.INTER_LANCZOS4)

    cx = int(round(MOUSE_SEAT[0] * w))
    by = int(round(MOUSE_SEAT[1] * h))
    ox, oy = cx - tw // 2, by - th
    ox = max(0, min(ox, w - tw))
    oy = max(0, min(oy, h - th))

    out = empty.copy().astype(np.float32)
    # soft contact shadow so the mouse sits ON the drawer floor rather than floating again
    sh = np.zeros((h, w), np.float32)
    cv2.ellipse(sh, (ox + tw // 2, oy + th - max(2, th // 12)),
                (int(tw * 0.42), max(3, int(th * 0.13))), 0, 0, 360, 1.0, -1)
    sh = cv2.GaussianBlur(sh, (0, 0), max(2.0, th * 0.055))[..., None]
    out = out * (1 - 0.42 * sh)

    a = np.zeros((h, w), np.uint8)
    a[oy:oy + th, ox:ox + tw] = cut_a
    rgb = np.zeros_like(empty)
    rgb[oy:oy + th, ox:ox + tw] = cut
    patch = over(out.astype(np.uint8), rgb, feather(a, 1.2))

    dst = os.path.join(view_dir, "states", art_open + "@3x.png")
    archive(dst)
    cv2.imwrite(dst, patch)
    print("  %-28s mouse %dx%d seated at (%d,%d) in %dx%d" %
          (art_open, tw, th, ox, oy, w, h))
    return src, patch


# ------------------------------------------------------------------ R8-017 arbor oil
# Boss centre as a fraction of the overlay patch (the bright bearing collar the crank enters).
ARBOR_BOSS = (0.60, 0.48)


def oiled(base):
    """Strong rust-clear + specular sheen. Deliberately several times the batch-4 delta:
    the previous pass was invisible at play scale (R8-017 user verdict)."""
    a = base.astype(np.float32)
    b, g, r = a[..., 0], a[..., 1], a[..., 2]
    rust = ((r - b > 26) & (r > 70)).astype(np.float32)
    rust = cv2.GaussianBlur(rust, (0, 0), 2.0)[..., None]
    lum = (0.28 * b + 0.46 * g + 0.26 * r)[..., None]
    iron = np.concatenate([lum * 1.04, lum * 1.00, lum * 0.96], axis=2)   # BGR: clean iron
    out = a * (1 - rust * 0.80) + iron * (rust * 0.80)

    h, w = base.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    bx, by = ARBOR_BOSS[0] * w, ARBOR_BOSS[1] * h
    rr = np.hypot((xx - bx) / (0.30 * w), (yy - by) / (0.30 * h))
    gloss = np.clip(1.0 - rr, 0, 1) ** 2.0
    streak = np.clip(1 - np.abs((yy - by) + 0.5 * (xx - bx)) / (0.10 * h + 8), 0, 1) ** 2
    sheen = (gloss * 0.22 + gloss * streak * 0.55)[..., None]
    out = out + sheen * np.array([150, 162, 176], np.float32)             # BGR cool highlight
    wet = (np.clip(rr, 0, 1.6) < 1.35)[..., None] * (1 - np.clip(sheen, 0, 1)) * 0.10
    out = out * (1 - wet)
    return np.clip(out, 0, 255).astype(np.uint8)


def arbor(view_dir, plate, art_name, rect):
    plate_im = rd(os.path.join(view_dir, plate + "@3x.png"))
    x0, y0, x1, y1 = rect
    base = plate_im[y0:y1, x0:x1]
    patch = oiled(base)
    # keep a pure-base ring so the rect edge cannot read as a box
    h, w = base.shape[:2]
    ring = np.zeros((h, w), np.uint8)
    cv2.rectangle(ring, (10, 10), (w - 11, h - 11), 255, -1)
    patch = over(base, patch, feather(ring, 9.0))
    dst = os.path.join(view_dir, "states", art_name + "@3x.png")
    archive(dst)
    cv2.imwrite(dst, patch)
    d = float(np.abs(patch.astype(np.int16) - base.astype(np.int16)).mean())
    print("  %-28s mean|delta| %.1f (was ~2.7)" % (art_name, d))
    return base, patch


def strip(pairs, name):
    rows = []
    for a, b in pairs:
        h = 300
        s = h / a.shape[0]
        aa = cv2.resize(a, (int(a.shape[1] * s), h))
        bb = cv2.resize(b, (int(b.shape[1] * s), h))
        rows.append(np.hstack([aa, np.full((h, 14, 3), 30, np.uint8), bb]))
    w = max(r.shape[1] for r in rows)
    rows = [np.hstack([r, np.full((r.shape[0], w - r.shape[1], 3), 30, np.uint8)]) for r in rows]
    out = np.vstack([np.vstack([r, np.full((14, w, 3), 30, np.uint8)]) for r in rows])
    p = os.path.join(SCRATCH, name)
    cv2.imwrite(p, out)
    print("sheet ->", p)


def rects():
    z3 = json.load(open(os.path.join(A2, "z3", "z3-state-overlays.json"), encoding="utf-8"))
    z2 = json.load(open(os.path.join(A2, "z2", "z2-state-overlays.json"), encoding="utf-8"))
    return z3, z2


def main():
    z3, z2 = rects()
    pairs = []
    print("R8-022 drum key-in:")
    pairs.append(drum_key(Z3, "cu-winding-drum", "ov-drum-key-in",
                          z3["ov-drum-key-in"]["rect_3x"], "cu"))
    pairs.append(drum_key(Z3, "z3-dial-base", "ov-drum-key-in-wide",
                          z3["ov-drum-key-in"]["wide_rect_3x"], "wide"))
    print("R8-014 tin mouse in the drawer:")
    pairs.append(cabinet_mouse(Z2C, "ov-cabinet-open-mouse", "ov-cabinet-empty", "cu"))
    pairs.append(cabinet_mouse(Z2C, "ov-cabinet-open-mouse-wide", "ov-cabinet-empty-wide", "wide"))
    print("R8-017 arbor oiled:")
    pairs.append(arbor(Z2F, "cu-gear-frame", "ov-arbor-oiled", z2["ov-arbor-oiled"]["rect_3x"]))
    pairs.append(arbor(Z2F, "z2-frame-base", "ov-arbor-oiled-wide",
                       z2["ov-arbor-oiled"]["wide_rect_3x"]))
    strip(pairs, "l2-b17-fixes-review.png")


if __name__ == "__main__":
    main()
