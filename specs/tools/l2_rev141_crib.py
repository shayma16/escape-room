#!/usr/bin/env python3
"""Level 2 rev-1.4.1 / F3 + D13 — the gear-frame chalk crib, and the canonical
tally-stroke SPRITES the Developer draws the LIVE block from.

Contract (puzzle-graph rev 1.4.1 clu-frame-tally, developer_notes D13,
visually_necessary_elements.z2-workroom; Designer spec §1b F3/F4; RF-7(a)(b)(c),
V17-W1/W3):

  F3 (Asset-Gen, authored here): the clockmaker's own chalk on the frame's timber
  cheek beside the fold-out crank -- a 24-tally block GROUPED IN FIVES at the
  crank station and a SINGLE matching tally at the cam station (frame-right, the
  direction the cam actually lies). Nothing else: no schematic, no '?' wheels, no
  pinion stamps. The structure is read off the machine (F1); only the TARGET
  PROPORTION is restated here.

  D13 (Developer, drawn at runtime from the sprites authored here): the live
  crank-tally block sits DIRECTLY BENEATH the crib, separated from it by a
  visible chalked RULE. RF-7(b): crib and live block are distinguished by
  POSITION ONLY -- identical chalk value, identical stroke weight, never an
  "old chalk / fresh chalk" treatment, and they must never read as one
  continuous block of 24+N. RF-7(c): no glow / flash / colour change at 24.

  V17-W1/W3 partial stroke: CONSTANT height (never derived from the residue),
  UPRIGHT (never diagonal -- it is not a strike and cannot collide with a
  five-group closing stroke), sharing the full strokes' BASELINE and shortened at
  the TOP only, same chalk value / width / slot pitch, never faded, ghosted,
  dashed or lower-opacity, never grouped into a five, never given a diagonal.

Deterministic PIL, $0.

Usage: python l2_rev141_crib.py
"""
import json
import os
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_z2_build import FRAMES, CU_W, CU_H
from overlay_gate import run as gate_run

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
VF = os.path.join(A2, "z2", "v-frame")
SPR = os.path.join(VF, "sprites")
REJ = os.path.join(A2, "_rejects")
TAG = "prerev141crib"

WX0, WY0, WX1, WY1 = FRAMES["cu-gear-frame"][1:]     # 660,660,2100,1740
S_W = (WX1 - WX0) / CU_W                              # 0.703125 CU -> wide

# ---- the timber cheek, measured on cu-gear-frame ----------------------------
# Clear timber between the crank pinion's teeth (which reach CU x~685) and the
# post-A bracket (CU x~950); above the wall panel (CU y 1052, ov-gearframe-panel-open).
FIELD = (700, 470, 945, 840)

CHALK = (232, 228, 218)      # #E8E4DA -- ONE value for crib AND live block (RF-7b)
SEAT = 0.95
GRAIN = 0.12

# ---- tally notation (cu-gear-frame px) --------------------------------------
STROKE_W = 4.0
STROKE_H = 38.0
PITCH = 14.0                 # slot pitch between uprights
GROUP_GAP = 16.0
ROW_PITCH = 56.0
PARTIAL_H = 19.0             # CONSTANT, exactly half -- never residue-derived
ROW_CAPACITY = 20            # 4 five-groups per row inside FIELD's width
X0 = 702.0
CRIB_ROW_BASE = (522.0, 578.0)
RULE_Y = 604.0
LIVE_ROW_BASE = (664.0, 720.0, 776.0)     # up to 3 rows -> 60 slots >= max 48
CAM_TALLY_X = 937.0                        # far right = the cam station


def draw_stroke(d, x, base_y, h, w, col):
    d.rectangle([x, base_y - h, x + w, base_y], fill=col)


def draw_five(d, x, base_y, p, h, w, col):
    """Four uprights closed by a diagonal FIFTH stroke -- never a strike-out:
    the diagonal spans exactly the four it closes and does not overshoot."""
    for i in range(4):
        draw_stroke(d, x + i * p, base_y, h, w, col)
    d.line([(x - w * 0.2, base_y - w * 0.5), (x + 3 * p + w * 1.2, base_y - h + w * 0.5)],
           fill=col, width=max(1, int(round(w))))


def draw_crib(scale, origin, min_stroke_w=0.0):
    """RGBA crib layer. `scale` = px per CU px; `origin` = (x,y) in CU space."""
    W = int(round((FIELD[2] - FIELD[0] + 20) * scale))
    H = int(round((FIELD[3] - FIELD[1] + 20) * scale))
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    d = ImageDraw.Draw(lay)
    col = tuple(int(c * SEAT) for c in CHALK) + (255,)
    w = max(min_stroke_w, STROKE_W * scale)
    p = PITCH * scale
    h = STROKE_H * scale
    gg = GROUP_GAP * scale
    gspan = 3 * p + w

    def P(x, y):
        return ((x - origin[0]) * scale, (y - origin[1]) * scale)

    # crib row A: four five-groups = 20
    x, base = P(X0, CRIB_ROW_BASE[0])
    n = 0
    for g in range(4):
        draw_five(d, x + g * (gspan + gg), base, p, h, w, col)
        n += 5
    # crib row B: the remaining four singles
    x, base = P(X0, CRIB_ROW_BASE[1])
    for i in range(4):
        draw_stroke(d, x + i * p, base, h, w, col)
        n += 1
    assert n == 24, f"F3 crib contract: {n} != 24"
    # the CAM-station tally: ONE mark in the IDENTICAL stroke style, parked at the
    # far right of row B (the cam lies frame-right of the crank on this machine).
    # Its gap to the 24-block is many times the group gap, so it can never be read
    # into the block as a 25th stroke (RC-3 class constraint).
    xc, _ = P(CAM_TALLY_X, CRIB_ROW_BASE[1])
    draw_stroke(d, xc, base, h, w, col)
    gap_px = (CAM_TALLY_X - (X0 + 3 * PITCH + STROKE_W)) * scale
    assert gap_px > 6 * gg, "RC-3 FAIL: cam tally too close to the 24-block"
    # the RULE: position-only separation from the D13 live block (RF-7b)
    rx0, ry = P(X0 - 2, RULE_Y)
    rx1, _ = P(CAM_TALLY_X + STROKE_W + 2, RULE_Y)
    d.line([(rx0, ry), (rx1, ry)], fill=col, width=max(1, int(round(w * 0.7))))
    return lay


def grain_modulate(lay, base_rgb):
    gl = base_rgb.convert("L")
    g = np.asarray(gl, np.float32)
    hp = g - np.asarray(gl.filter(ImageFilter.GaussianBlur(2.2)), np.float32)
    f = np.clip(0.5 + hp / (4.0 * (hp.std() + 1e-6)), 0.0, 1.0)
    f = 1.0 - GRAIN * (1.0 - f)
    a = np.asarray(lay.split()[3], np.float32) * f
    out = lay.copy()
    out.putalpha(Image.fromarray(a.clip(0, 255).astype(np.uint8), "L"))
    return out


def lum(rgb):
    c = np.asarray(rgb, np.float32) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def rf7a(base, out, alpha, label):
    core = np.asarray(alpha, np.float32) / 255.0 >= 0.85
    lb, lo = lum(np.asarray(base, np.float32))[core], lum(np.asarray(out, np.float32))[core]
    cr = (np.maximum(lb, lo) + 0.05) / (np.minimum(lb, lo) + 0.05)
    print(f"  RF-7(a) {label}: {core.sum()} core chalk px, min {cr.min():.2f}:1  "
          f"median {np.median(cr):.2f}:1")
    assert cr.min() >= 3.0, f"RF-7(a) FAIL {label}: {cr.min():.2f}:1"
    return round(float(cr.min()), 2), round(float(np.median(cr)), 2)


# ------------------------------------------------------------------- sprites
SS = 4          # sprites authored at 4x CU px so the runtime can scale cleanly


def build_sprites():
    os.makedirs(SPR, exist_ok=True)
    col = tuple(int(c * SEAT) for c in CHALK) + (255,)
    made = {}

    def save(name, im):
        im.save(os.path.join(SPR, name + "@3x.png"))
        im.resize((max(1, im.width * 2 // 3), max(1, im.height * 2 // 3)),
                  Image.LANCZOS).save(os.path.join(SPR, name + "@2x.png"))
        im.resize((max(1, im.width // 3), max(1, im.height // 3)),
                  Image.LANCZOS).save(os.path.join(SPR, name + "@1x.png"))
        made[name] = list(im.size)

    w, h = int(STROKE_W * SS), int(STROKE_H * SS)
    full = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(full).rectangle([0, 0, w - 1, h - 1], fill=col)
    save("sp-tally-full", full)

    # V17-W3: same baseline, shortened at the TOP only, CONSTANT height, upright,
    # same value/width -- no fade, no dash, no ghost.
    ph = int(PARTIAL_H * SS)
    part = Image.new("RGBA", (w, h), (0, 0, 0, 0))
    ImageDraw.Draw(part).rectangle([0, h - ph, w - 1, h - 1], fill=col)
    save("sp-tally-partial", part)

    # the group-closing FIFTH stroke, matched to the four uprights it crosses
    gw = int((3 * PITCH + STROKE_W * 1.4) * SS)
    strike = Image.new("RGBA", (gw, h), (0, 0, 0, 0))
    ImageDraw.Draw(strike).line(
        [(w * 0.1, h - w * 0.5), (gw - w * 0.5, w * 0.5)], fill=col, width=w)
    save("sp-tally-strike", strike)
    return made


def restore():
    for stem in ("z2-frame-base", "cu-gear-frame"):
        for t in ("1x", "2x", "3x"):
            src = os.path.join(REJ, f"{stem}-{TAG}@{t}.png")
            if os.path.exists(src):
                shutil.copy2(src, os.path.join(VF, f"{stem}@{t}.png"))


def build():
    restore()
    report = {}

    # ---------------- close-up ----------------
    cu = Image.open(os.path.join(VF, "cu-gear-frame@3x.png")).convert("RGB")
    ox, oy = FIELD[0] - 10, FIELD[1] - 10
    lay = draw_crib(1.0, (ox, oy))
    box = (int(ox), int(oy), int(ox) + lay.width, int(oy) + lay.height)
    base = cu.crop(box)
    lay = grain_modulate(lay, base)
    out = base.convert("RGBA")
    out.alpha_composite(lay)
    out = out.convert("RGB")
    report["cu_rf7a"] = rf7a(base, out, lay.split()[3], "crib / cu-gear-frame")
    m = np.asarray(Image.fromarray((np.asarray(lay.split()[3]) > 8).astype(np.uint8) * 255)
                   .filter(ImageFilter.MaxFilter(15))) > 0
    report["cu_gate"] = gate_run(np.asarray(base), np.asarray(out), m)
    print("  overlay_gate cu  :", report["cu_gate"])
    cu.paste(out, (box[0], box[1]))

    # ---------------- wide ----------------
    wide = Image.open(os.path.join(VF, "z2-frame-base@3x.png")).convert("RGB")
    wox, woy = WX0 + ox * S_W, WY0 + oy * S_W
    # sanctioned over-scale (the C1 principle): hold a 4 px minimum stroke so the
    # wide crib keeps its RF-7(a) luminance instead of aliasing into a smudge.
    layw = draw_crib(S_W, (ox, oy), min_stroke_w=4.0)
    wbox = (int(round(wox)), int(round(woy)),
            int(round(wox)) + layw.width, int(round(woy)) + layw.height)
    basew = wide.crop(wbox)
    layw = grain_modulate(layw, basew)
    outw = basew.convert("RGBA")
    outw.alpha_composite(layw)
    outw = outw.convert("RGB")
    report["wide_rf7a"] = rf7a(basew, outw, layw.split()[3], "crib / z2-frame-base")
    mw = np.asarray(Image.fromarray((np.asarray(layw.split()[3]) > 8).astype(np.uint8) * 255)
                    .filter(ImageFilter.MaxFilter(15))) > 0
    report["wide_gate"] = gate_run(np.asarray(basew), np.asarray(outw), mw)
    print("  overlay_gate wide:", report["wide_gate"])
    wide.paste(outw, (wbox[0], wbox[1]))

    # ---------------- write canonicals ----------------
    for stem, im, sizes in (("z2-frame-base", wide, ((2560, 1280), (1280, 640))),
                            ("cu-gear-frame", cu, ((1365, 1024), (683, 512)))):
        for tag, size in (("3x", None), ("2x", sizes[0]), ("1x", sizes[1])):
            src = os.path.join(VF, f"{stem}@{tag}.png")
            dst = os.path.join(REJ, f"{stem}-{TAG}@{tag}.png")
            if os.path.exists(src) and not os.path.exists(dst):
                os.replace(src, dst)
            (im if size is None else im.resize(size, Image.LANCZOS)).save(
                os.path.join(VF, f"{stem}@{tag}.png"))

    # ---------------- D13 sprites + metadata ----------------
    made = build_sprites()

    def norm_cu(x, y):
        return [round(x / CU_W, 6), round(y / CU_H, 6)]

    def norm_wide(x, y):
        return [round((WX0 + x * S_W) / 3840.0, 6), round((WY0 + y * S_W) / 1920.0, 6)]

    meta = {
        "revision": "1.4.1 (F3 crib authored; D13 live block is the Developer's)",
        "owner": "Asset-Gen authors the crib + these sprites; the Developer composites "
                 "the LIVE block from them at runtime (D13).",
        "chalk_value": "#E8E4DA seated x0.95 -- IDENTICAL for the crib and the live "
                       "block (RF-7b: separation is POSITION only, never hue/value; "
                       "no old-chalk/fresh-chalk treatment)",
        "sprites": {
            "sp-tally-full": {
                "size_px": made["sp-tally-full"],
                "pivot": "BOTTOM-LEFT (0, height) -- anchor on the row baseline",
                "draw_size_cu_px": [STROKE_W, STROKE_H],
                "note": "one full crank revolution of accumulated rotation"},
            "sp-tally-partial": {
                "size_px": made["sp-tally-partial"],
                "pivot": "BOTTOM-LEFT (0, height) -- SAME baseline as the full stroke",
                "draw_size_cu_px": [STROKE_W, STROKE_H],
                "ink_height_cu_px": PARTIAL_H,
                "note": "V17-W1/W3: CONSTANT height (never derived from the residue), "
                        "UPRIGHT, shortened at the TOP only, same chalk value, same "
                        "stroke width, same slot pitch. NEVER faded/ghosted/dashed/"
                        "lower-opacity. Never grouped into a five, never struck. At "
                        "most ONE per block. Occupies a FULL slot pitch."},
            "sp-tally-strike": {
                "size_px": made["sp-tally-strike"],
                "pivot": "BOTTOM-LEFT (0, height) at the first upright of the group",
                "draw_size_cu_px": [3 * PITCH + STROKE_W * 1.4, STROKE_H],
                "note": "the group-closing FIFTH stroke; spans exactly the four "
                        "uprights it closes and never overshoots them (reads as a "
                        "fifth stroke, never a strike-out)"},
        },
        "notation": {
            "slot_pitch_cu_px": PITCH,
            "group_gap_cu_px": GROUP_GAP,
            "row_pitch_cu_px": ROW_PITCH,
            "row_capacity_strokes": ROW_CAPACITY,
            "max_strokes": 48,
            "rows_needed_at_max": 3,
            "grouping": "five = four uprights + one diagonal closing stroke"},
        "cu_gear_frame": {
            "plate_px": [CU_W, CU_H],
            "field_px": list(FIELD),
            "crib_row_baselines_px": list(CRIB_ROW_BASE),
            "crib_x0_px": X0,
            "cam_tally_x_px": CAM_TALLY_X,
            "rule_y_px": RULE_Y,
            "live_row_baselines_px": list(LIVE_ROW_BASE),
            "live_x0_px": X0,
            "live_block_rect_norm": [
                round((X0 - 4) / CU_W, 6), round((LIVE_ROW_BASE[0] - STROKE_H - 6) / CU_H, 6),
                round((X0 + ROW_CAPACITY / 5 * (3 * PITCH + STROKE_W + GROUP_GAP) + 4) / CU_W, 6),
                round((LIVE_ROW_BASE[-1] + 6) / CU_H, 6)],
            "live_row_baselines_norm": [norm_cu(X0, b) for b in LIVE_ROW_BASE]},
        "z2_frame_base_wide": {
            "plate_px": [3840, 1920],
            "crib_bbox_px": list(wbox),
            "live_row_baselines_norm": [norm_wide(X0, b) for b in LIVE_ROW_BASE],
            "note": "the wide crib is drawn at the scaled geometry with a 4 px "
                    "minimum stroke width (the sanctioned C1 over-scale principle) "
                    "so it holds its RF-7(a) luminance instead of aliasing away; the "
                    "close-up carries countability."},
        "constraints_for_the_developer": [
            "RF-7(b): the live block NEVER touches or continues the crib -- the "
            "chalked rule at rule_y_px is the separator, and the first live row "
            "baseline is 60 CU px below it.",
            "RF-7(c): no glow, flash or colour change when the live count reaches 24.",
            "D13: transient view state only -- never saved, never gate-readable; "
            "cleared on any mount/unmount, on fewer than two gears, on scene/save "
            "reload, and redrawn from zero at the start of the next crank press.",
            "Accrual is ACCUMULATED CRANK ROTATION since the last cam clack; "
            "index-mark crossing counting is PROHIBITED.",
            "The final block must be fully readable STATICALLY and the accrual "
            "animation must be skippable (RC-4)."],
        "gates": {"cu": report["cu_gate"], "wide": report["wide_gate"],
                  "rf7a_cu_min_median": list(report["cu_rf7a"]),
                  "rf7a_wide_min_median": list(report["wide_rf7a"])},
    }
    with open(os.path.join(SPR, "tally-sprites.json"), "w") as f:
        json.dump(meta, f, indent=1)

    # ---------------- review sheet ----------------
    old = Image.open(os.path.join(REJ, f"cu-gear-frame-{TAG}@3x.png"))
    bx = (620, 420, 1020, 880)
    sheet = Image.new("RGB", (1230, 500), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    dd.text((10, 6), "F3 frame-cheek chalk crib (24 in fives at the crank + ONE tally at "
                     "the cam) -- BEFORE / AFTER; live D13 block goes under the rule",
            fill=(230, 225, 210))
    sheet.paste(old.crop(bx).resize((600, 460), Image.LANCZOS), (2, 30))
    sheet.paste(cu.crop(bx).resize((600, 460), Image.LANCZOS), (614, 30))
    sheet.save(os.path.join(A2, "z2", "frame-crib-before-after.png"))
    print("F3 done: crib authored (24 in fives + cam tally + rule); D13 sprites written")


if __name__ == "__main__":
    build()
