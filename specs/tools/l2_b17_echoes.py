#!/usr/bin/env python3
"""BUILD 17 — CROSS-ELEMENT CLOSE-UP ECHOES for Level 2 ($0, deterministic, no API).

WHY (R8-021 root cause). Every L2 close-up plate is a CROP of its wide plate (verified:
crop+LANCZOS of the wide reproduces each shipped CU plate to mean |delta| <= 0.2/255), so a
close-up frequently BAKES IN a neighbouring element as well as its own. Through build 16 the
close-up resolver only ever composited a plate's OWN element state, so:

    cu-tag-nail shows the tag AND the winding key; cu-key-hook shows the key AND the tag.

Collect both z4 pickups and re-open either close-up and the OTHER item is still hanging
there — the "stale key" the user reported. The 22-row close-up state-flip guard did not
catch it because every row paired a close-up with its OWN element; nothing in the table
tested a close-up against a NEIGHBOUR's state. The two z1 echoes that did exist
(`ov-cache-cat-gone`, and the build-16 sill/cushion pair) were added ad hoc after a user
report rather than derived from plate geometry.

This script derives every missing echo the same way, from measured geometry:

  1. take the WIDE plate and the WIDE state overlay of the *source* element (both approved);
  2. crop BOTH through the HOST close-up's authored camera frame and resample to 2048x1536 —
     the exact transform that produced the host plate, so the result is registered by
     construction (no ECC, no hand-placed rects);
  3. bbox the changed pixels, pad, and blend that region onto the shipped host plate with a
     pure-base ring + feather, so untouched pixels stay bit-identical and the seam gate
     passes by construction;
  4. register `<key>` in the zone's state-overlay JSON with `base` = host CU + `rect_3x`.

Alternative states of one element (pried/empty, open/empty) are built as a GROUP over one
shared rect, so swapping the composited layer restores the plate exactly — the same contract
`ov-cache-pried-wheel` / `ov-cache-empty` already use.

CLI: python l2_b17_echoes.py [build|gate|sheet]
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
CU_W, CU_H = 2048, 1536

# view -> (zone, asset subdirectory, wide plate name)
VIEWS = {
    "v-bench": ("z1", os.path.join("z1", "v-bench"), "z1-bench-base"),
    "v-master": ("z1", os.path.join("z1", "v-master"), "z1-master-base"),
    "v-door": ("z1", os.path.join("z1", "v-door"), "z1-door-base"),
    "v-frame": ("z2", os.path.join("z2", "v-frame"), "z2-frame-base"),
    "v-clockrow": ("z2", os.path.join("z2", "v-clockrow"), "z2-clockrow-base"),
    "v-dial": ("z3", os.path.join("z3", "v-dial"), "z3-dial-base"),
    "v-vault": ("z4", os.path.join("z4", "v-vault-interior"), "z4-vault-base"),
}

# Close-up camera frames on the @3x wide plate (the crops the CU plates were rendered from —
# see specs/tools/l2_z1_build.py / l2_z2_build.py / l2_z3_build.py / l2_z4_build.py).
CU_FRAMES = {
    "cu-slate": ("v-bench", (1230, 300, 2630, 1350)),
    "cu-stove-hob": ("v-bench", (2320, 1280, 3160, 1910)),
    "cu-barometer": ("v-bench", (940, 0, 1620, 510)),
    "cu-master-face": ("v-master", (540, 320, 2500, 1790)),
    "cu-door-dial": ("v-master", (1900, 420, 3260, 1440)),
    "cu-crate-straw": ("v-master", (2380, 1230, 3300, 1920)),
    "cu-sill-tile": ("v-door", (2135, 875, 2855, 1415)),
    "cu-house-ring": ("v-door", (1528, 455, 2248, 995)),
    "cu-cat-cushion": ("v-door", (2450, 1085, 3410, 1805)),
    "cu-floor-cache": ("v-door", (1900, 1140, 2940, 1920)),
    "cu-timelock": ("v-door", (620, 420, 1820, 1320)),
    "cu-gear-frame": ("v-frame", (660, 660, 2100, 1740)),
    "cu-gear-rack": ("v-frame", (1905, 940, 2705, 1540)),
    "cu-gear-ring": ("v-frame", (2560, 940, 3120, 1360)),
    "cu-brick-cache": ("v-frame", (2470, 935, 3030, 1355)),
    "cu-clockrow-plates": ("v-clockrow", (760, 180, 3000, 1860)),
    "cu-cabinet-drawer": ("v-clockrow", (2050, 1095, 3150, 1920)),
    "cu-display-case": ("v-clockrow", (620, 840, 2060, 1920)),
    "cu-great-dial": ("v-dial", (900, 300, 2596, 1572)),
    "cu-winding-drum": ("v-dial", (0, 1030, 1187, 1920)),
    "cu-hatch-wheels": ("v-dial", (2150, 870, 3550, 1920)),
    "cu-tag-nail": ("v-vault", (500, 350, 1400, 1025)),
    "cu-key-hook": ("v-vault", (700, 280, 1620, 970)),
    "cu-shelf": ("v-vault", (1700, 300, 2980, 1260)),
}

# Groups of echoes that must share ONE rect (mutually exclusive states of one element).
# key -> dict(host, source wide overlay list, note); members of a group are built together.
GROUPS = [
    dict(host="cu-key-hook", under=None, members=[
        ("ov-keyhook-tag-taken", ["ov-tag-taken"],
         "R8-021 cross-element echo: the KEY-hook close-up also depicts the return TAG. "
         "Once the tag is collected this patch clears it here too, exactly as the wide and "
         "cu-tag-nail already did. Derived by re-cropping the approved ov-tag-taken wide "
         "art through cu-key-hook's own camera frame (no generation)."),
    ]),
    dict(host="cu-tag-nail", under=None, members=[
        ("ov-tagnail-key-taken", ["ov-key-taken"],
         "R8-021 THE REPORTED DEFECT: the tag-nail close-up also depicts the winding KEY, "
         "so after collecting both z4 pickups this plate still showed a stale key. Derived "
         "by re-cropping the approved ov-key-taken wide art through cu-tag-nail's frame."),
    ]),
    dict(host="cu-gear-ring", under=None, members=[
        ("ov-gearring-brick-pried", ["ov-brick-pried-oilcan"],
         "cross-element echo: the p04 ring-clue plate is cropped from the chimney breast and "
         "bakes in the loose cache brick, so it must follow the cache's pried state."),
        ("ov-gearring-brick-empty", ["ov-brick-empty"],
         "cross-element echo: cache pried AND emptied, as it reads in the ring-clue crop. "
         "Shares ov-gearring-brick-pried's rect so the two are interchangeable."),
    ]),
    dict(host="cu-gear-frame", under=None, members=[
        ("ov-gearframe-panel-open", ["ov-panel-open"],
         "cross-element echo: the opened z3 wall panel is inside the gear-frame close-up's "
         "crop, so the frame plate must show it open once z3 is unlocked."),
    ]),
    dict(host="cu-master-face", under=None, members=[
        ("ov-masterface-door-open", ["ov-workroom-door-open"],
         "cross-element echo: the workroom door stands behind the master clock and is inside "
         "this close-up's crop, so it must read OPEN after p01."),
    ]),
    dict(host="cu-crate-straw", under=None, members=[
        ("ov-crate-door-open", ["ov-workroom-door-open"],
         "cross-element echo: the straw-crate close-up's crop includes the workroom doorway; "
         "it must read OPEN after p01."),
    ]),
    dict(host="cu-house-ring", under=None, members=[
        ("ov-housering-bar-raised", ["ov-bar-raised"],
         "cross-element echo: the dormer ⌂-ring clue post crop includes the stair-door "
         "time-lock bar, which must read RAISED once the timelock releases."),
    ]),
    dict(host="cu-cat-cushion", under=None, members=[
        ("ov-cushion-cache-pried", ["ov-cache-pried-wheel"],
         "cross-element echo: the cushion close-up's crop includes the dormer floor cache; "
         "it must show the pried board + great wheel once p03 is solved."),
        ("ov-cushion-cache-empty", ["ov-cache-empty"],
         "cross-element echo: cache pried AND emptied as it reads in the cushion crop. "
         "Shares ov-cushion-cache-pried's rect."),
    ]),
    dict(host="cu-floor-cache", under="ov-cache-cat-gone", members=[
        ("ov-cache-cushion-lifted", ["ov-cushion-empty", "ov-cushion-reveal"],
         "TRANSIENT cross-element echo: the floor-cache crop includes the cat's bench, and "
         "ov-cache-cat-gone already tracks the vacated cushion. This adds the LIFT window "
         "(cushion tipped up, watch B on the bench) and composites OVER ov-cache-cat-gone, "
         "mirroring ov-sill-cushion-lifted on the sill plate."),
    ]),
]

MIN_AREA = 400          # ignore a change smaller than this in CU pixels
PAD = 26
RING = 8
FEATHER = 12


def path(view, *parts):
    return os.path.join(A2, VIEWS[view][1], *parts)


def rd(p):
    im = cv2.imread(p, cv2.IMREAD_COLOR)
    if im is None:
        raise SystemExit("missing " + p)
    return im


def wide_with(view, keys, meta):
    base = rd(path(view, VIEWS[view][2] + "@3x.png"))
    out = base.copy()
    for k in keys:
        r = meta[k]["wide_rect_3x"]
        art = rd(path(view, "states", k + "-wide@3x.png"))
        out[r[1]:r[3], r[0]:r[2]] = art
    return base, out


def through_frame(img, frame):
    x0, y0, x1, y1 = frame
    return cv2.resize(img[y0:y1, x0:x1], (CU_W, CU_H), interpolation=cv2.INTER_LANCZOS4)


def host_plate(host, under, meta):
    plate = rd(path(CU_FRAMES[host][0], host + "@3x.png"))
    if under:
        r = meta[under]["rect_3x"]
        art = rd(path(CU_FRAMES[host][0], "states", under + "@3x.png"))
        plate[r[1]:r[3], r[0]:r[2]] = art
    return plate


def ring_mask(shape_hw, rect, inset):
    h, w = shape_hw
    x0, y0, x1, y1 = rect
    m = np.zeros((h, w), np.uint8)
    l = 0 if x0 <= 0 else inset
    t = 0 if y0 <= 0 else inset
    r = w if x1 >= CU_W else w - inset
    b = h if y1 >= CU_H else h - inset
    m[t:b, l:r] = 255
    return m


def build_group(group, meta, save=True):
    host = group["host"]
    view, frame = CU_FRAMES[host]
    plate = host_plate(host, group.get("under"), meta)

    # 1) one shared rect for the whole group = padded union of every member's change bbox
    changed = np.zeros((CU_H, CU_W), bool)
    rendered = {}
    for key, srcs, _note in group["members"]:
        base, mod = wide_with(view, srcs, meta)
        a = through_frame(base, frame)
        b = through_frame(mod, frame)
        rendered[key] = b
        d = cv2.absdiff(a, b).astype(np.int16).sum(2)
        changed |= (cv2.GaussianBlur(d.astype(np.float32), (0, 0), 2.0) > 24)
    ys, xs = np.nonzero(changed)
    if xs.size < MIN_AREA:
        print("  %-28s SKIP (change %d px < %d)" % (host, xs.size, MIN_AREA))
        return []
    rect = (max(0, int(xs.min()) - PAD), max(0, int(ys.min()) - PAD),
            min(CU_W, int(xs.max()) + 1 + PAD), min(CU_H, int(ys.max()) + 1 + PAD))

    # 2) blend each member onto the host plate over that shared rect
    x0, y0, x1, y1 = rect
    hc = plate[y0:y1, x0:x1]
    mm = ring_mask(hc.shape[:2], rect, RING).astype(np.float32) / 255.0
    mf = cv2.GaussianBlur(mm, (0, 0), FEATHER)
    lim = ring_mask(hc.shape[:2], rect, max(1, RING // 2)).astype(np.float32) / 255.0
    mf = np.clip(mf * lim, 0, 1)[..., None]

    out = []
    for key, _srcs, note in group["members"]:
        wc = rendered[key][y0:y1, x0:x1]
        patch = (hc.astype(np.float32) * (1 - mf) + wc.astype(np.float32) * mf).astype(np.uint8)
        e = {"base": host, "rect_3x": list(rect), "note": note}
        if group.get("under"):
            e["composites_over"] = group["under"]
        meta[key] = e
        if save:
            dst = path(view, "states", key + "@3x.png")
            os.makedirs(REJ, exist_ok=True)
            if os.path.exists(dst):
                os.replace(dst, os.path.join(REJ, key + "-b16pre@3x.png"))
            cv2.imwrite(dst, patch)
        out.append((key, plate, patch, rect))
        print("  %-28s host %-20s rect %s" % (key, host, rect))
    return out


def zone_meta():
    m = {}
    for z in ["z1", "z2", "z3", "z4"]:
        p = os.path.join(A2, z, "%s-state-overlays.json" % z)
        m[z] = json.load(open(p, encoding="utf-8"))
    return m


def flat(meta_by_zone):
    out = {}
    for z in ["z1", "z2", "z3", "z4"]:
        out.update(meta_by_zone[z])
    return out


def save_zone_meta(meta_by_zone, produced):
    """Write each new key back into the zone JSON that owns its HOST close-up."""
    host_zone = {cu: VIEWS[v][0] for cu, (v, _f) in CU_FRAMES.items()}
    for key, host, entry in produced:
        meta_by_zone[host_zone[host]][key] = entry
    for z in ["z1", "z2", "z3", "z4"]:
        p = os.path.join(A2, z, "%s-state-overlays.json" % z)
        json.dump(meta_by_zone[z], open(p, "w", encoding="utf-8"), indent=1)
    print("registered %d echo overlays" % len(produced))


def main():
    cmd = sys.argv[1] if len(sys.argv) > 1 else "build"
    mz = zone_meta()
    meta = flat(mz)
    save = cmd == "build"
    sheets = []
    produced = []
    for group in GROUPS:
        for key, plate, patch, rect in build_group(group, meta, save=save):
            sheets.append((key, plate, patch, rect))
            produced.append((key, group["host"], meta[key]))
    if save:
        save_zone_meta(mz, produced)
    if cmd in ("build", "sheet"):
        rows = []
        for key, plate, patch, rect in sheets:
            x0, y0, x1, y1 = rect
            pad = 60
            cx0, cy0 = max(0, x0 - pad), max(0, y0 - pad)
            cx1, cy1 = min(CU_W, x1 + pad), min(CU_H, y1 + pad)
            after = plate.copy()
            after[y0:y1, x0:x1] = patch
            a, b = plate[cy0:cy1, cx0:cx1], after[cy0:cy1, cx0:cx1]
            h = 300
            s = h / a.shape[0]
            a = cv2.resize(a, (int(a.shape[1] * s), h))
            b = cv2.resize(b, (int(b.shape[1] * s), h))
            cv2.putText(a, key, (6, 22), cv2.FONT_HERSHEY_SIMPLEX, 0.55, (60, 255, 255), 1)
            rows.append(np.hstack([a, np.full((h, 14, 3), 30, np.uint8), b]))
        w = max(r.shape[1] for r in rows)
        rows = [np.hstack([r, np.full((r.shape[0], w - r.shape[1], 3), 30, np.uint8)]) for r in rows]
        out = np.vstack([np.vstack([r, np.full((14, w, 3), 30, np.uint8)]) for r in rows])
        p = os.path.join(SCRATCH, "l2-b17-echoes-review.png")
        cv2.imwrite(p, out)
        print("sheet ->", p)


if __name__ == "__main__":
    main()
