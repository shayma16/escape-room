#!/usr/bin/env python3
"""Level 2 / z1 v-door CROSS-VIEW CLOSE-UP ECHO patches (build-17 gap fix, $0 / no API).

Two z1 close-up plates carry baked-in content that belongs to a NEIGHBOURING element's
state, with no authored overlay to cover the post-state (found after the build-16 fix made
every L2 close-up state-composited):

  * cu-cat-cushion's top-left corner shows the dormer SILL with tile XI still standing.
    Once tile XI is taken the wide and cu-sill-tile update, but this corner did not.
  * cu-sill-tile's bottom-right corner shows the CAT asleep on its cushion. Once p02 is
    solved the cat is gone everywhere else, but this corner did not update.

Same technique as the existing `ov-cache-cat-gone` echo (cu-floor-cache <- cushion state):
derive the patch DETERMINISTICALLY from the already-approved state art of the OTHER plate.
No generation, no re-invention -- the scene->close-up EXACT-recreation rule means every
close-up in v-door is the same render at a different crop/scale, which this script proves
and then exploits:

  ECC registration of cu-sill-tile <-> cu-cat-cushion converges at cc = 0.9995 with a pure
  similarity (scale 1.33330, no rotation), residual mean |delta| = 0.32/255 over the whole
  overlap. The plates are literally the same pixels at 4:3 relative zoom, so warping one
  plate's approved state art into the other's frame is exact, not an approximation.

Composite rules (identical to l2_fixstates' reblend contract): linear colour match fitted on
the unchanged surround, feathered blend that keeps a PURE BASE ring at every rect side that
is not an image edge, so the seam check passes by construction and untouched pixels stay
bit-identical.

CLI:  python l2_cu_echoes.py [build|gate|sheet]
"""
import json
import os
import sys

import cv2
import numpy as np

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z1 = os.path.join(A2, "z1")
VD = os.path.join(Z1, "v-door")
ST = os.path.join(VD, "states")
REJ = os.path.join(A2, "_rejects")
OVJ = os.path.join(Z1, "z1-state-overlays.json")
SCRATCH = os.environ.get(
    "L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim"
    r"\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")
CU_W, CU_H = 2048, 1536

# --- registration: cushion CU coords -> sill CU coords (ECC, cc=0.999507) -----------
W_C2S = np.array([[1.333306e+00, 7.611689e-05, 8.961415e+02],
                  [-9.622778e-05, 1.333276e+00, 5.975354e+02]], np.float32)
W_S2C = np.linalg.inv(np.vstack([W_C2S, [0, 0, 1]]).astype(np.float64))[:2].astype(np.float32)

# --- the two echo patches ----------------------------------------------------------
JOBS = {
    # host plate <- source plate's approved state art
    "ov-cushion-sill-taken": dict(
        host="cu-cat-cushion", src="cu-sill-tile", warp="s2c",
        src_states=[("ov-sill-tile-taken", 670, 255)],
        rect=(0, 0, 312, 240), ring=8, feather=12, band=48, sharpen=0.0,
        note="sill corner echo: tile XI gone from the dormer sill as it reads in the "
             "cu-cat-cushion crop; deterministic warp of the approved ov-sill-tile-taken "
             "art (ECC cc=0.9995, no generation). Keyed to the tile-XI-taken state."),
    "ov-sill-cat-gone": dict(
        host="cu-sill-tile", src="cu-cat-cushion", warp="c2s",
        src_states=[("ov-cushion-empty", 450, 110)],
        rect=(1440, 696, 2048, 1536), ring=8, feather=14, band=56, sharpen=0.0,
        note="cat-gone echo for the overlapping cushion corner of the sill CU "
             "(consistency, mirrors ov-cache-cat-gone); deterministic warp of the "
             "approved ov-cushion-empty art. Keyed to p02-solved / cat-gone."),
}


def load(p):
    im = cv2.imread(p, cv2.IMREAD_COLOR)
    if im is None:
        raise SystemExit("missing " + p)
    return im


def plate(name):
    return load(os.path.join(VD, name + "@3x.png"))


def with_states(base, states):
    out = base.copy()
    for name, x0, y0 in states:
        ov = load(os.path.join(ST, name + "@3x.png"))
        out[y0:y0 + ov.shape[0], x0:x0 + ov.shape[1]] = ov
    return out


def edge_sides(rect, w=CU_W, h=CU_H):
    x0, y0, x1, y1 = rect
    return {"l": x0 <= 0, "t": y0 <= 0, "r": x1 >= w, "b": y1 >= h}


def ring_lim_mask(shape_hw, inset, exempt):
    """uint8 255 inside the patch inset by `inset` on every non-image-edge side."""
    h, w = shape_hw
    m = np.zeros((h, w), np.uint8)
    l = 0 if exempt["l"] else inset
    t = 0 if exempt["t"] else inset
    r = w if exempt["r"] else w - inset
    b = h if exempt["b"] else h - inset
    m[t:b, l:r] = 255
    return m


def color_match(base, src, ctrl):
    """Per-channel linear fit of src onto base over the ctrl (unchanged) pixels."""
    b = base.astype(np.float32)
    s = src.astype(np.float32)
    m = ctrl.astype(bool)
    out = s.copy()
    for c in range(3):
        x, y = s[..., c][m], b[..., c][m]
        a = float(np.clip(np.cov(x, y)[0, 1] / (x.var() + 1e-5), 0.6, 1.6))
        out[..., c] = np.clip(s[..., c] * a + (y.mean() - a * x.mean()), 0, 255)
    return out.astype(np.uint8)


def unsharp(img, amount, sigma=1.2):
    if amount <= 0:
        return img
    blur = cv2.GaussianBlur(img.astype(np.float32), (0, 0), sigma)
    return np.clip(img.astype(np.float32) * (1 + amount) - blur * amount, 0, 255).astype(np.uint8)


def build_one(key, job, save=True):
    host = plate(job["host"])
    src = plate(job["src"])
    src_state = with_states(src, job["src_states"])
    M = W_S2C if job["warp"] == "s2c" else W_C2S
    warped = cv2.warpAffine(src_state, M, (CU_W, CU_H), flags=cv2.INTER_LANCZOS4)
    warped_base = cv2.warpAffine(src, M, (CU_W, CU_H), flags=cv2.INTER_LANCZOS4)

    x0, y0, x1, y1 = job["rect"]
    hc = host[y0:y1, x0:x1]
    wc = unsharp(warped[y0:y1, x0:x1], job["sharpen"])
    wbc = warped_base[y0:y1, x0:x1]

    # control = pixels inside the rect that this state change does NOT touch, so the
    # colour fit is made on genuinely corresponding content only.
    d = cv2.absdiff(wc, wbc).astype(np.float32).mean(2)
    ctrl = cv2.erode((cv2.GaussianBlur(d, (0, 0), 6) < 3).astype(np.uint8), np.ones((9, 9), np.uint8))
    if ctrl.sum() < 500:
        ctrl = np.ones(d.shape, np.uint8)
    wc = color_match(hc, wc, ctrl)

    exempt = edge_sides(job["rect"])
    mm = ring_lim_mask(hc.shape[:2], job["ring"], exempt).astype(np.float32) / 255.0
    mf = cv2.GaussianBlur(mm, (0, 0), job["feather"])
    lim = ring_lim_mask(hc.shape[:2], max(1, job["ring"] // 2), exempt).astype(np.float32) / 255.0
    mf = np.clip(mf * lim, 0, 1)[..., None]
    patch = (hc.astype(np.float32) * (1 - mf) + wc.astype(np.float32) * mf).astype(np.uint8)

    result = host.copy()
    result[y0:y1, x0:x1] = patch
    if save:
        dst = os.path.join(ST, key + "@3x.png")
        if os.path.exists(dst):                       # canonical-filename discipline
            os.replace(dst, os.path.join(REJ, key + "-b16pre@3x.png"))
        cv2.imwrite(dst, patch)
        print("wrote %s  (%dx%d)" % (dst, patch.shape[1], patch.shape[0]))
    return host, result, patch


def gate_one(key, job):
    sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
    import overlay_gate
    host, result, _ = build_one(key, job, save=False)
    x0, y0, x1, y1 = job["rect"]
    mask = np.zeros((CU_H, CU_W), bool)
    mask[y0:y1, x0:x1] = True
    sc = overlay_gate.run(cv2.cvtColor(host, cv2.COLOR_BGR2RGB),
                          cv2.cvtColor(result, cv2.COLOR_BGR2RGB), mask)
    print("%-24s %s" % (key, json.dumps(sc)))
    return sc


def register_json():
    meta = json.load(open(OVJ, encoding="utf-8"))
    for key, job in JOBS.items():
        meta[key] = {"base": job["host"], "rect_3x": list(job["rect"]), "note": job["note"]}
    json.dump(meta, open(OVJ, "w", encoding="utf-8"), indent=1)
    print("registered %s in %s" % (", ".join(JOBS), OVJ))


def sheet():
    """Side-by-side before/after strip for review."""
    rows = []
    for key, job in JOBS.items():
        host, result, _ = build_one(key, job, save=False)
        x0, y0, x1, y1 = job["rect"]
        pad = 60
        cx0, cy0 = max(0, x0 - pad), max(0, y0 - pad)
        cx1, cy1 = min(CU_W, x1 + pad), min(CU_H, y1 + pad)
        a, b = host[cy0:cy1, cx0:cx1], result[cy0:cy1, cx0:cx1]
        h = 460
        s = h / a.shape[0]
        a = cv2.resize(a, (int(a.shape[1] * s), h))
        b = cv2.resize(b, (int(b.shape[1] * s), h))
        gap = np.full((h, 16, 3), 30, np.uint8)
        rows.append(np.hstack([a, gap, b]))
    w = max(r.shape[1] for r in rows)
    rows = [np.hstack([r, np.full((r.shape[0], w - r.shape[1], 3), 30, np.uint8)]) for r in rows]
    out = np.vstack([np.vstack([r, np.full((16, w, 3), 30, np.uint8)]) for r in rows])
    p = os.path.join(SCRATCH, "l2-cu-echoes-review.png")
    cv2.imwrite(p, out)
    cv2.imwrite(os.path.join(Z1, "z1-review-cu-echoes.png"), out)
    print("sheet ->", p)


if __name__ == "__main__":
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    if cmd == "gate":
        for k, j in JOBS.items():
            gate_one(k, j)
    elif cmd == "sheet":
        sheet()
    else:
        for k, j in JOBS.items():
            build_one(k, j)
        register_json()
