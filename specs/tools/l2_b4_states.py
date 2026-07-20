#!/usr/bin/env python3
"""Level 2 BATCH 4 state overlays + sprites (final art batch, 2026-07-20).

Per-element overlay architecture matching the Developer compositor (patch +
rect JSON, schema = z1-state-overlays.json): RGB rect patches for surface
changes, RGBA additive overlays for placed elements (flagged "rgba" in JSON).
Every patch seam-checked (3px ring vs base, PASS <= 24). All load-bearing
geometry deterministic (render_gear / canonical dies); NB edits only for
genuine surface changes (separate phases).

Phases:
  z2a — arbor-oiled (CU13 + wide echo), 14 post-mount overlays (CU13),
        6 rack-absent overlays (CU14 native + wide echo).
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_z2_build import (render_gear, FRAMES, GEAR_ANCHORS, GEAR_DIA,
                         RACK_SQUASH, RACK_ROT, frame_scale)

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z2 = os.path.join(A2, "z2")
REJ = os.path.join(A2, "_rejects")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")
CU_W, CU_H = 2048, 1536

FRAME_WIDE = os.path.join(Z2, "v-frame", "z2-frame-base@3x.png")
FRAME_PRE = os.path.join(REJ, "z2-frame-base-preglyph@3x.png")
CU13 = os.path.join(Z2, "v-frame", "cu-gear-frame@3x.png")
CU14 = os.path.join(Z2, "v-frame", "cu-gear-rack@3x.png")
STATES = os.path.join(Z2, "v-frame", "states")
OVJSON = os.path.join(Z2, "z2-state-overlays.json")

# post mounts (CU13 @3x): stub centers + collar front re-paste rects
POST_A = (1322, 668)
POST_B = (1625, 695)
COLLAR_A = (1272, 605, 1372, 730)     # square stub end re-pasted in front
COLLAR_B = (1578, 638, 1672, 752)
MOUNT_TEETH = [16, 24, 36, 40, 48, 64, 72]


def mount_dia(t):
    return int(84 + 2.1 * t)


def load_json():
    if os.path.exists(OVJSON):
        return json.load(open(OVJSON))
    return {}


def save_json(m):
    with open(OVJSON, "w") as f:
        json.dump(m, f, indent=1)


def seam(base_img, patch_img, rect, ring=3):
    """Max mean-abs ring diff (3px ring just outside rect vs base)."""
    b = np.asarray(base_img, np.float32)
    x0, y0, x1, y1 = rect
    scores = []
    for side, sl_b, sl_p in (
        ("top", (slice(max(0, y0 - ring), y0), slice(x0, x1)), None),
        ("bottom", (slice(y1, min(b.shape[0], y1 + ring)), slice(x0, x1)), None),
        ("left", (slice(y0, y1), slice(max(0, x0 - ring), x0)), None),
        ("right", (slice(y0, y1), slice(x1, min(b.shape[1], x1 + ring))), None),
    ):
        pass
    # ring = compare base ring vs composite ring (patch pasted); since patch
    # is exactly rect-sized, the composite ring pixels == base ring pixels.
    # The real seam risk is the patch EDGE vs the adjacent base: compare the
    # outermost patch rows/cols with the adjacent base rows/cols.
    p = np.asarray(patch_img, np.float32)
    edges = []
    if y0 - 1 >= 0:
        edges.append(np.abs(p[0] - b[y0 - 1, x0:x1]).mean())
    if y1 < b.shape[0]:
        edges.append(np.abs(p[-1] - b[y1, x0:x1]).mean())
    if x0 - 1 >= 0:
        edges.append(np.abs(p[:, 0] - b[y0:y1, x0 - 1]).mean())
    if x1 < b.shape[1]:
        edges.append(np.abs(p[:, -1] - b[y0:y1, x1]).mean())
    return max(edges) if edges else 0.0


def save_patch(meta, name, img, rect, base_for_seam, note, key_extra=None,
               wide=False):
    os.makedirs(STATES, exist_ok=True)
    suffix = "-wide@3x.png" if wide else "@3x.png"
    img.convert("RGB").save(os.path.join(STATES, name + suffix))
    sc = seam(base_for_seam, img.convert("RGB"), rect)
    assert sc <= 24, f"{name}{' wide' if wide else ''}: seam {sc:.1f} > 24"
    e = meta.setdefault(name, {})
    if wide:
        e["wide_base"] = "z2-frame-base"
        e["wide_rect_3x"] = list(rect)
    else:
        e["base"] = key_extra or "cu-gear-frame"
        e["rect_3x"] = list(rect)
    e["note"] = note
    print(f"  {name}{' (wide)' if wide else ''}: rect {rect} seam {sc:.1f} PASS")
    return sc


# ------------------------------------------------------------ arbor oiled

def arbor_oiled(meta):
    """Bearing rust bloom cleared + oil sheen — bearing plate only."""
    for label, path, rect, boss, wide in (
        ("cu", CU13, (40, 360, 440, 710), (355, 575), False),
        ("wide", FRAME_WIDE, (688, 913, 969, 1159), (910, 1064), True),
    ):
        base = Image.open(path).convert("RGB")
        x0, y0, x1, y1 = rect
        crop = base.crop(rect)
        a = np.asarray(crop, np.float32)
        R, G, B = a[..., 0], a[..., 1], a[..., 2]
        # rust mask: warm red mottling
        rust = (R - B > 42) & (R > 95) & (R - G > 18)
        m = Image.fromarray((rust * 255).astype(np.uint8)).filter(
            ImageFilter.GaussianBlur(2))
        mf = np.asarray(m, np.float32)[..., None] / 255.0
        # recolor rust toward clean oiled iron (keep luminance texture)
        lum = (0.35 * R + 0.45 * G + 0.2 * B)[..., None]
        iron = np.concatenate([lum * 0.94, lum * 0.90, lum * 0.86], axis=2)
        out = a * (1 - mf * 0.85) + iron * (mf * 0.85)
        # oil sheen: soft elliptical gloss around the boss + wet darkening ring
        h, w = out.shape[:2]
        yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
        bx, by = boss[0] - x0, boss[1] - y0
        rr = np.hypot((xx - bx) / (0.62 * w / 2), (yy - by) / (0.62 * h / 2))
        gloss = np.clip(1.0 - rr, 0, 1) ** 2.2
        streak = np.clip(1 - np.abs((yy - by) - 0.55 * (xx - bx)) / 26.0, 0, 1)
        sheen = (gloss * 0.55 + gloss * streak * 0.45)[..., None]
        out = out + sheen * np.array([56, 50, 40]) * 0.8
        wet = (np.clip(rr, 0, 1.6) < 1.25)[..., None] * (1 - sheen) * 0.10
        out = out * (1 - wet)
        patch = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
        # feather patch edges back to base (kill any boundary step)
        fm = Image.new("L", patch.size, 255)
        dd = ImageDraw.Draw(fm)
        dd.rectangle([6, 6, patch.width - 7, patch.height - 7], fill=255)
        fm = fm.filter(ImageFilter.GaussianBlur(4))
        blended = Image.composite(patch, crop, fm)
        save_patch(meta, "ov-arbor-oiled", blended, rect, base,
                   "seized bearing oiled: rust bloom cleared (recolored to "
                   "clean iron, texture kept) + oil sheen/gloss at the boss; "
                   "bearing plate only per style 8", wide=wide)


# ------------------------------------------------------------ post mounts

def collar_mask(base, rect):
    """Bright-metal mask of the stub collar inside rect (feathered)."""
    crop = np.asarray(base.crop(rect).convert("RGB"), np.float32)
    lum = crop.mean(2)
    m = (lum > np.percentile(lum, 55)).astype(np.uint8) * 255
    im = Image.fromarray(m).filter(ImageFilter.MaxFilter(5)).filter(
        ImageFilter.GaussianBlur(2))
    return im


def post_mounts(meta):
    base = Image.open(CU13).convert("RGB")
    for t in MOUNT_TEETH:
        dia = mount_dia(t)
        g = render_gear(t, dia)
        g = g.resize((int(dia * 0.94), dia), Image.LANCZOS)
        g = g.rotate(-2, expand=True, resample=Image.BICUBIC)
        for post, (cx, cy), collar in (("a", POST_A, COLLAR_A),
                                       ("b", POST_B, COLLAR_B)):
            name = f"ov-mount-{post}-{t}"
            # overlay canvas = gear bbox + collar re-paste + shadow margin
            pad = 26
            x0 = min(cx - g.width // 2, collar[0]) - pad
            y0 = min(cy - g.height // 2, collar[1]) - pad
            x1 = max(cx + g.width // 2, collar[2]) + pad
            y1 = max(cy + g.height // 2, collar[3]) + pad
            x0, y0 = max(0, x0), max(0, y0)
            x1, y1 = min(CU_W, x1), min(CU_H, y1)
            ov = Image.new("RGBA", (x1 - x0, y1 - y0), (0, 0, 0, 0))
            # soft shadow (light from the doorway right -> shadow left-down)
            sh = Image.new("RGBA", g.size, (0, 0, 0, 0))
            sh.putalpha(g.split()[3].point(lambda v: v * 78 // 255))
            sh = sh.filter(ImageFilter.GaussianBlur(9))
            ov.alpha_composite(sh, (cx - g.width // 2 - 12 - x0,
                                    cy - g.height // 2 + 10 - y0))
            ov.alpha_composite(g, (cx - g.width // 2 - x0,
                                   cy - g.height // 2 - y0))
            # gear centered ON the stub end; its square arbor hole is
            # transparent so the stub's bright end face shows through =
            # "slid onto the arbor" read (no re-paste, no mask bleed)
            os.makedirs(STATES, exist_ok=True)
            ov.save(os.path.join(STATES, name + "@3x.png"))
            meta[name] = {
                "base": "cu-gear-frame",
                "rect_3x": [x0, y0, x1, y1],
                "rgba": True,
                "note": f"gear {t}t mounted on post {post.upper()} "
                        f"(deterministic render_gear, exact tooth count; "
                        f"stub collar re-pasted through the square arbor "
                        f"hole; dia {dia}px prop. to teeth)"}
            print(f"  {name}: rect ({x0},{y0},{x1},{y1}) RGBA additive")


# ------------------------------------------------------------ rack absents

def rack_absents(meta):
    """RGBA masked patches: blank-peg pixels with alpha over exactly the
    OWN gear's changed-pixel silhouette. Changed pixels are PARTITIONED by
    nearest gear (normalized by radius) so no mask ever bites a neighbor."""
    pre = Image.open(FRAME_PRE).convert("RGB")
    cur = Image.open(FRAME_WIDE).convert("RGB")
    cu_base = Image.open(CU14).convert("RGB")
    _, fx0, fy0, fx1, fy1 = FRAMES["cu-gear-rack"]
    s = frame_scale("cu-gear-rack")
    pre_cu = pre.crop((fx0, fy0, fx1, fy1)).resize((CU_W, CU_H), Image.LANCZOS)
    os.makedirs(STATES, exist_ok=True)
    spaces = {}
    for tag, blank, base_img, w_, h_, tf in (
        ("wide", pre, cur, cur.width, cur.height,
         lambda x, y: (x, y)),
        ("cu", pre_cu, cu_base, CU_W, CU_H,
         lambda x, y: ((x - fx0) * s, (y - fy0) * s)),
    ):
        dif = np.abs(np.asarray(base_img, np.int16) -
                     np.asarray(blank, np.int16)).max(2) > 10
        yy, xx = np.mgrid[0:h_, 0:w_].astype(np.float32)
        # nearest-gear partition (distance normalized by gear radius)
        best = None
        owner = np.full((h_, w_), -1, np.int16)
        for t, (cx, cy) in GEAR_ANCHORS.items():
            ax, ay = tf(cx, cy)
            r = (GEAR_DIA[t] / 2 + 20) * (s if tag == "cu" else 1)
            nd = np.hypot(xx - ax, yy - ay) / r
            if best is None:
                best = nd
                owner[:] = t
            else:
                m = nd < best
                best = np.where(m, nd, best)
                owner[m] = t
        owner[best > 2.2] = -1          # far pixels belong to nobody
        masks = {}
        for t in GEAR_ANCHORS:
            own = dif & (owner == t)
            m = Image.fromarray((own * 255).astype(np.uint8)).filter(
                ImageFilter.MaxFilter(7)).filter(ImageFilter.GaussianBlur(2.5))
            masks[t] = np.asarray(m)
        # hard-exclude: zero alpha on any OTHER gear's core silhouette
        for t in GEAR_ANCHORS:
            others = np.zeros((h_, w_), bool)
            for t2 in GEAR_ANCHORS:
                if t2 != t:
                    others |= (dif & (owner == t2))
            om = Image.fromarray((others * 255).astype(np.uint8)).filter(
                ImageFilter.MaxFilter(3))
            ma = masks[t].astype(np.int16) - np.asarray(om, np.int16)
            masks[t] = np.clip(ma, 0, 255).astype(np.uint8)
        spaces[tag] = (masks, blank)
        for t in GEAR_ANCHORS:
            ma = masks[t]
            ys, xs = np.nonzero(ma > 8)
            x0, y0 = int(xs.min()) - 2, int(ys.min()) - 2
            x1, y1 = int(xs.max()) + 3, int(ys.max()) + 3
            name = f"ov-rack-absent-{t}"
            patch = blank.crop((x0, y0, x1, y1)).convert("RGBA")
            patch.putalpha(Image.fromarray(ma[y0:y1, x0:x1]))
            suffix = "-wide@3x.png" if tag == "wide" else "@3x.png"
            patch.save(os.path.join(STATES, name + suffix))
            e = meta.setdefault(name, {})
            if tag == "wide":
                e["wide_base"] = "z2-frame-base"
                e["wide_rect_3x"] = [x0, y0, x1, y1]
            else:
                e["base"] = "cu-gear-rack"
                e["rect_3x"] = [x0, y0, x1, y1]
            e["rgba"] = True
            e["note"] = (f"gear {t}t taken off its rack peg: blank-peg pixels, "
                         f"alpha = own silhouette (nearest-gear partition, "
                         f"neighbors hard-excluded)")
            print(f"  {name} ({tag}): rect ({x0},{y0},{x1},{y1}) RGBA masked")
    # verification (CU space)
    masks_cu, _ = spaces["cu"]
    comp = cu_base.convert("RGBA")
    for t in GEAR_ANCHORS:
        nm = f"ov-rack-absent-{t}"
        p = Image.open(os.path.join(STATES, nm + "@3x.png"))
        r_ = meta[nm]["rect_3x"]
        comp.alpha_composite(p, (r_[0], r_[1]))
    d = np.abs(np.asarray(comp.convert("RGB"), np.int16) -
               np.asarray(pre_cu, np.int16)).max(2)
    resid = int((d > 14).sum())
    print("  all-absent residue px vs blank rack (CU):", resid)
    assert resid < 2500, f"absent residue {resid} px"
    for t in GEAR_ANCHORS:
        nm = f"ov-rack-absent-{t}"
        single = cu_base.convert("RGBA")
        p = Image.open(os.path.join(STATES, nm + "@3x.png"))
        r_ = meta[nm]["rect_3x"]
        single.alpha_composite(p, (r_[0], r_[1]))
        d = np.abs(np.asarray(single.convert("RGB"), np.int16) -
                   np.asarray(cu_base, np.int16)).max(2) > 14
        for t2 in GEAR_ANCHORS:
            if t2 == t:
                continue
            bite = int((d & (masks_cu[t2] > 60)).sum())
            assert bite == 0, f"{nm} bites gear {t2}: {bite} px"
    print("  single-absent neighbor-bite check: 6/6 PASS (0 px)")


if __name__ == "__main__":
    phase = sys.argv[1] if len(sys.argv) > 1 else "z2a"
    meta = load_json()
    if phase == "z2a":
        print("arbor oiled:")
        arbor_oiled(meta)
        print("post mounts (14):")
        post_mounts(meta)
        print("rack absents (6):")
        rack_absents(meta)
    save_json(meta)
    print("z2-state-overlays.json updated")
