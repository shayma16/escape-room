#!/usr/bin/env python3
"""Level 2 rev-1.4.1 / C2 (teach-at-dormer) — FIRST AUTHORING of the cache-board
chalk note: hub dot + canonical bearing hand + canonical chalk die-house.

Contract (puzzle-graph rev 1.4.1 z1-attic/v-door floorboards element string = the
authoring contract, D12(2), visually_necessary_elements.z1-attic; Designer spec
rev B.1 §B.1b + the B1c supplement's restated A10):

  ONE composite, three marks read left to right, baked into the EXISTING overlay
  ids ov-cache-marked-wide / ov-cache-marked (no new overlay id, no new state):
    (i)   chalk HUB DOT, one stroke-width across -- a stroke terminal, NOT a ring
          and NOT notched (it must never invite counting);
    (ii)  chalk BEARING HAND -- the canonical hand-hour silhouette (the SAME
          outline C1/C3 composite onto the two rings) filled in chalk #E8E4DA,
          radiating from the hub toward frame-right;
    (iii) the canonical chalk die-house.
  DO NOT AUTHOR THE REV-1.4 SINGLE GLYPH.

  BINDING LAYOUT (all asserted below as the A10 gate):
   * attitude within +/-5 deg of the RENDERED C1 ring hand in the same plate.  The
     ring hand is composited by Level2RoomView at rotationEffect(hour*30) with the
     sprite pointing up, so hour 3 renders EXACTLY horizontal: the chalk hand is
     laid at 0.0 deg and the delta is 0.0 deg by construction.
   * tip ABUTS the house's left edge (touching / slightly overlapping, within one
     glyph-width) and NEVER overshoots it or runs toward the rect edge.
   * the WHOLE note wholly inside the measured ov-cache-* rect x 0.6375-0.7656
     (wide @3x 2448..2940), so what is marked is exactly what is tappable.
   * a visible WAIST between hand tip and house outline (two-part-ness): the hand
     tapers to a point and the house is an OUTLINE, never a filled mass.
   * FALLBACK LADDER: shorten the hand (floor = the house's own width); then close
     hub-to-house spacing to zero; NEVER shrink the house; else escalate.
   * RF-7(a): >= 3:1 luminance contrast against worn timber in raking light in BOTH
     views, measured per-pixel here.  Hand and house are discriminated by SHAPE and
     POSITION only -- identical chalk value, identical stroke weight, and the hand
     is never faded / ghosted / dashed / translucent relative to the house.
     No glow, no flash, no colour change.
  The close-up renders the SAME note at 1.969x and must NOT elaborate it: it is
  literally the same geometry, scaled.

Deterministic PIL, $0.

Usage: python l2_rev141_cache.py
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import die_house, tint
from overlay_gate import run as gate_run

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
VD = os.path.join(A2, "z1", "v-door")
ST = os.path.join(VD, "states")
SPR = os.path.join(A2, "z3", "v-dial", "sprites")

# ---- frames -----------------------------------------------------------------
WIDE = os.path.join(VD, "z1-door-base@3x.png")
CU = os.path.join(VD, "cu-floor-cache@3x.png")
CU_FRAME = (1900, 1140, 2940, 1920)          # l2_z1_build FRAMES["cu-floor-cache"]
S_CU = 2048.0 / (CU_FRAME[2] - CU_FRAME[0])  # 1.969231 wide -> CU

RECT_W = (2448, 1724, 2940, 1920)            # ov-cache-* wide rect (M1)
RECT_CU = (1080, 1150, 2048, 1536)           # ov-cache-* cu-floor-cache rect

# ---- measured cache-board geometry, wide @3x --------------------------------
# Board seams fitted from second-derivative minima on the shipped plate, and
# cross-checked against the cavity edges baked into ov-cache-pried-wheel.
def seam_left(y):  return 2470.0 + 0.43 * (y - 1755.0)
def seam_right(y): return 2697.0 + 0.55 * (y - 1755.0)
CAVITY_W = (2459, 1751, 2692, 1848)          # cavity read off the pried overlay
BOARD_L = lambda y: max(seam_left(y), CAVITY_W[0])
BOARD_R = lambda y: min(seam_right(y), CAVITY_W[2])

# Raking-light band: the sunbeam patch starts at wide y ~1845 and the chalk would
# fall BELOW 3:1 on it, so the note lives in the shadowed upper board.
BAND_Y = (1740, 1835)

# ---- the note, wide @3x ------------------------------------------------------
AXIS_Y = 1790.0
ATTITUDE_DEG = 0.0                 # == the rendered C1 ring hand (hour 3 -> 90 deg
RING_HAND_ATTITUDE_DEG = 0.0       #    of sprite rotation == horizontal)
HOUSE_W, HOUSE_H = 78.0, 62.0      # RF-7(a) wide-legibility floor; NEVER shrunk
HOUSE_X0 = 2610.0
HAND_LEN = 96.0                    # pivot -> tip
TIP_OVERLAP = 2.0                  # tip sits 2 px INSIDE the house's left edge
CHALK = (232, 228, 218)            # #E8E4DA
SEAT = 0.95                        # ambient seat, applied to hand AND house alike
GRAIN = 0.12                       # alpha grain depth (chalk sitting on grain)
STROKE_FRAC = 40.0 / 400.0         # die_house stroke -> ~7.8 px at HOUSE_W


def note_layout():
    """Compute the note in wide @3x space and run the A10 gate. Returns a dict."""
    house_x1 = HOUSE_X0 + HOUSE_W
    house_y0 = AXIS_Y - HOUSE_H / 2
    house_y1 = AXIS_Y + HOUSE_H / 2
    tip_x = HOUSE_X0 + TIP_OVERLAP
    pivot_x = tip_x - HAND_LEN
    stroke = HOUSE_W * STROKE_FRAC
    hub_d = stroke                              # "one stroke-width across"
    # canonical sprite proportions (hand-sprites.json: pivot (60,290), len 250)
    spr = Image.open(os.path.join(SPR, "hand-hour@3x.png"))
    a = np.asarray(spr)[..., 3]
    ys, xs = np.nonzero(a > 10)
    tip_off = 290 - ys.min()                    # pivot -> tip in sprite px
    tail_off = ys.max() - 290                   # pivot -> tail end
    k = HAND_LEN / tip_off
    tail_x = pivot_x - tail_off * k
    half_w = (xs.max() - xs.min()) / 2 * k * (HOUSE_H / HOUSE_W)  # floor squash

    L = dict(house=(HOUSE_X0, house_y0, house_x1, house_y1),
             tip_x=tip_x, pivot=(pivot_x, AXIS_Y), tail_x=tail_x,
             hub_d=hub_d, stroke=stroke, hand_len=HAND_LEN,
             hand_half_w=half_w, sprite_scale=k,
             bbox=(tail_x, min(house_y0, AXIS_Y - half_w),
                   house_x1, max(house_y1, AXIS_Y + half_w)))

    # ---------------- A10 GATE -------------------------------------------
    x0, y0, x1, y1 = L["bbox"]
    steps = []
    assert abs(ATTITUDE_DEG - RING_HAND_ATTITUDE_DEG) <= 5.0, \
        "A10 FAIL: chalk hand attitude off the rendered ring hand by >5 deg"
    assert (RECT_W[0] <= x0 and x1 <= RECT_W[2]
            and RECT_W[1] <= y0 and y1 <= RECT_W[3]), \
        f"A10 FAIL: note bbox {L['bbox']} not wholly inside the ov-cache rect {RECT_W}"
    assert BAND_Y[0] <= y0 and y1 <= BAND_Y[1], \
        f"A10 FAIL: note leaves the shadowed board band {BAND_Y} (RF-7a risk)"
    # the house must sit wholly ON the cache board over its own y-extent
    for yy in (house_y0, AXIS_Y, house_y1):
        assert BOARD_L(yy) <= HOUSE_X0 and house_x1 <= BOARD_R(yy), \
            f"A10 FAIL: house off the cache board at y={yy:.0f} " \
            f"(board {BOARD_L(yy):.0f}..{BOARD_R(yy):.0f})"
    for yy in (AXIS_Y - half_w, AXIS_Y + half_w):
        assert BOARD_L(yy) <= tail_x, \
            f"A10 FAIL: hand tail crosses the board's left seam at y={yy:.0f}"
    # tip abuts and never overshoots
    assert 0.0 <= tip_x - HOUSE_X0 <= HOUSE_W, "A10 FAIL: tip does not abut the house"
    assert tip_x < HOUSE_X0 + HOUSE_W * 0.25, "A10 FAIL: tip overshoots into the house"
    # ladder floor: the hand must stay longer than the house is wide
    assert HAND_LEN >= HOUSE_W, \
        "A10 LADDER BOTTOMED OUT: hand shorter than the house glyph -- ESCALATE"
    if HAND_LEN < 1.15 * HOUSE_W:
        steps.append("hand shortened toward the floor")
    print("A10 layout gate PASS -- FIT ACHIEVED, no fallback-ladder step used"
          if not steps else "A10 layout gate PASS with ladder step: " + "; ".join(steps))
    print(f"  note bbox (wide @3x) x {x0:.0f}..{x1:.0f}  y {y0:.0f}..{y1:.0f}"
          f"  = {x1 - x0:.0f} x {y1 - y0:.0f} px inside a {RECT_W[2] - RECT_W[0]}"
          f" x {RECT_W[3] - RECT_W[1]} rect")
    print(f"  hand {HAND_LEN:.0f} px vs house width {HOUSE_W:.0f} px "
          f"(ratio {HAND_LEN / HOUSE_W:.2f}, floor 1.00); attitude delta "
          f"{abs(ATTITUDE_DEG - RING_HAND_ATTITUDE_DEG):.1f} deg (tol 5.0)")
    return L


def draw_note(L, scale, origin):
    """RGBA layer of the note. `scale` = px per wide px; `origin` = (x,y) wide."""
    W = int(round((RECT_W[2] - RECT_W[0]) * scale))
    H = int(round((RECT_W[3] - RECT_W[1]) * scale))
    lay = Image.new("RGBA", (W, H), (0, 0, 0, 0))

    def P(x, y):
        return ((x - origin[0]) * scale, (y - origin[1]) * scale)

    # (ii) BEARING HAND -- canonical silhouette, chalk-filled, laid horizontally
    spr = Image.open(os.path.join(SPR, "hand-hour@3x.png")).convert("RGBA")
    k = L["sprite_scale"] * scale
    spr = spr.resize((max(2, int(round(spr.width * k))),
                      max(2, int(round(spr.height * k)))), Image.LANCZOS)
    # floor-plane foreshortening: the note lies ON the boards, so it is compressed
    # ACROSS the note's axis (same factor as the house's own squash)
    sq = HOUSE_H / HOUSE_W
    spr = spr.resize((max(2, int(round(spr.width * sq))), spr.height), Image.LANCZOS)
    # The canonical sprite's own alpha peaks at 210/255 (it is drawn as dark iron
    # on a dial, not as a fill).  Normalise it to FULL opacity before tinting:
    # RF-7 binds the chalk hand to the SAME value, weight and luminance floor as
    # the house -- it may never render fainter than the glyph it points at.
    _a = np.asarray(spr.split()[3], np.float32)
    _peak = max(1.0, float(_a.max()))
    spr.putalpha(Image.fromarray(np.clip(_a * 255.0 / _peak, 0, 255).astype(np.uint8), "L"))
    spr = tint(spr, tuple(int(c * SEAT) for c in CHALK) + (255,))
    spr = spr.rotate(-90 - ATTITUDE_DEG, expand=True, resample=Image.BICUBIC)
    # after the -90 rotation the pivot (60,290 in sprite px) maps to:
    pv_x = (380 - 290) * k          # distance from the rotated image's LEFT edge
    pv_y = 60 * k * sq
    px, py = P(*L["pivot"])
    lay.alpha_composite(spr, (int(round(px - pv_x)), int(round(py - pv_y))))

    # (i) HUB DOT -- a filled stroke-terminal at the pivot. NOT a ring, no notches.
    d = ImageDraw.Draw(lay)
    r = L["hub_d"] * scale / 2
    d.ellipse([px - r, py - r * sq, px + r, py + r * sq],
              fill=tuple(int(c * SEAT) for c in CHALK) + (255,))

    # (iii) HOUSE -- canonical die, chalk-filled OUTLINE (never a filled mass)
    hx0, hy0, hx1, hy1 = L["house"]
    die = die_house(400, (255, 255, 255, 255), stroke=int(round(400 * STROKE_FRAC)))
    die = tint(die, tuple(int(c * SEAT) for c in CHALK) + (255,))
    die = die.resize((max(2, int(round((hx1 - hx0) * scale))),
                      max(2, int(round((hy1 - hy0) * scale)))), Image.LANCZOS)
    gx, gy = P(hx0, hy0)
    lay.alpha_composite(die, (int(round(gx)), int(round(gy))))
    return lay


def grain_modulate(lay, base_rgb, rng):
    """Chalk sits on raised timber grain: modulate alpha by the base's own local
    high-frequency texture. Identical treatment for hand AND house (no value cue)."""
    gl = base_rgb.convert("L")
    g = np.asarray(gl, np.float32)
    hp = g - np.asarray(gl.filter(ImageFilter.GaussianBlur(2.2)), np.float32)
    s = hp.std() + 1e-6
    f = np.clip(0.5 + hp / (4.0 * s), 0.0, 1.0)
    f = 1.0 - GRAIN * (1.0 - f)
    a = np.asarray(lay.split()[3], np.float32) * f
    out = lay.copy()
    out.putalpha(Image.fromarray(a.clip(0, 255).astype(np.uint8), "L"))
    return out


def lum(rgb):
    c = np.asarray(rgb, np.float32) / 255.0
    c = np.where(c <= 0.04045, c / 12.92, ((c + 0.055) / 1.055) ** 2.4)
    return 0.2126 * c[..., 0] + 0.7152 * c[..., 1] + 0.0722 * c[..., 2]


def rf7a_gate(base_patch, out_patch, alpha, label):
    """RF-7(a): every CORE chalk pixel holds >= 3:1 against the timber under it."""
    core = np.asarray(alpha, np.float32) / 255.0 >= 0.85
    lb = lum(np.asarray(base_patch, np.float32))[core]
    lo = lum(np.asarray(out_patch, np.float32))[core]
    hi, lo_ = np.maximum(lb, lo), np.minimum(lb, lo)
    cr = (hi + 0.05) / (lo_ + 0.05)
    print(f"  RF-7(a) {label}: {core.sum()} core chalk px, "
          f"contrast min {cr.min():.2f}:1  median {np.median(cr):.2f}:1")
    assert cr.min() >= 3.0, f"RF-7(a) FAIL in {label}: min contrast {cr.min():.2f}:1 < 3:1"
    return float(cr.min()), float(np.median(cr))


def build():
    L = note_layout()
    os.makedirs(ST, exist_ok=True)
    report = {}

    # ---------------- WIDE ----------------
    wide = Image.open(WIDE).convert("RGB")
    base_w = wide.crop(RECT_W)
    lay = grain_modulate(draw_note(L, 1.0, (RECT_W[0], RECT_W[1])), base_w,
                         np.random.default_rng(20260808))
    out_w = base_w.convert("RGBA")
    out_w.alpha_composite(lay)
    out_w = out_w.convert("RGB")
    report["wide_rf7a"] = rf7a_gate(base_w, out_w, lay.split()[3], "ov-cache-marked-wide")
    mask = np.asarray(lay.split()[3]) > 8
    g = gate_run(np.asarray(base_w), np.asarray(out_w),
                 np.asarray(Image.fromarray(mask.astype(np.uint8) * 255)
                            .filter(ImageFilter.MaxFilter(15))) > 0)
    report["wide_gate"] = g
    print("  overlay_gate wide:", g)
    out_w.save(os.path.join(ST, "ov-cache-marked-wide@3x.png"))

    # ---------------- CLOSE-UP (the SAME note, 1.969x, not elaborated) -------
    cu = Image.open(CU).convert("RGB")
    base_c = cu.crop(RECT_CU)
    layc = draw_note(L, S_CU, (RECT_W[0], RECT_W[1]))
    layc = layc.resize((RECT_CU[2] - RECT_CU[0], RECT_CU[3] - RECT_CU[1]),
                       Image.LANCZOS)
    layc = grain_modulate(layc, base_c, np.random.default_rng(20260808))
    out_c = base_c.convert("RGBA")
    out_c.alpha_composite(layc)
    out_c = out_c.convert("RGB")
    report["cu_rf7a"] = rf7a_gate(base_c, out_c, layc.split()[3], "ov-cache-marked")
    maskc = np.asarray(layc.split()[3]) > 8
    gc = gate_run(np.asarray(base_c), np.asarray(out_c),
                  np.asarray(Image.fromarray(maskc.astype(np.uint8) * 255)
                             .filter(ImageFilter.MaxFilter(15))) > 0)
    report["cu_gate"] = gc
    print("  overlay_gate cu  :", gc)
    out_c.save(os.path.join(ST, "ov-cache-marked@3x.png"))

    # ---------------- parity proof sheet ----------------
    sheet = Image.new("RGB", (1240, 640), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    dd.text((10, 6), "C2 rev-1.4.1 cache-board note: hub dot + canonical bearing hand + "
                     "canonical chalk house   (WIDE left / CLOSE-UP right, same note)",
            fill=(230, 225, 210))
    sheet.paste(base_w.resize((600, 239), Image.LANCZOS), (5, 26))
    sheet.paste(out_w.resize((600, 239), Image.LANCZOS), (5, 275))
    sheet.paste(base_c.resize((600, 239), Image.LANCZOS), (620, 26))
    sheet.paste(out_c.resize((600, 239), Image.LANCZOS), (620, 275))
    zw = out_w.crop((40, 20, 260, 120)).resize((600, 273), Image.LANCZOS)
    sheet.paste(zw, (5, 526 - 160))
    sheet.save(os.path.join(A2, "z1", "cache-note-rev141.png"))

    with open(os.path.join(VD, "cache-note-geometry.json"), "w") as f:
        json.dump({
            "revision": "1.4.1 (teach-at-dormer, C2)",
            "attitude_deg_from_horizontal": ATTITUDE_DEG,
            "ring_hand_rendered_attitude_deg": RING_HAND_ATTITUDE_DEG,
            "attitude_delta_deg": abs(ATTITUDE_DEG - RING_HAND_ATTITUDE_DEG),
            "chalk_value": "#E8E4DA seated x0.95, identical for hand and house",
            "wide_rect_3x": list(RECT_W), "cu_rect_3x": list(RECT_CU),
            "wide": {"hub_centre": [L["pivot"][0], L["pivot"][1]],
                     "hub_diameter_px": L["hub_d"],
                     "hand_pivot_to_tip_px": L["hand_len"],
                     "hand_tip_x": L["tip_x"],
                     "house_rect": list(L["house"]),
                     "note_bbox": [round(v, 1) for v in L["bbox"]]},
            "cu_scale_from_wide": S_CU,
            "a10": "FIT ACHIEVED at first authoring; no fallback-ladder step used",
            "rf7a": report["wide_rf7a"] and {
                "wide_min_contrast": report["wide_rf7a"][0],
                "wide_median_contrast": report["wide_rf7a"][1],
                "cu_min_contrast": report["cu_rf7a"][0],
                "cu_median_contrast": report["cu_rf7a"][1]},
            "overlay_gate": {"wide": report["wide_gate"], "cu": report["cu_gate"]},
        }, f, indent=1)
    print("C2 done: ov-cache-marked-wide + ov-cache-marked authored (first authoring)")


if __name__ == "__main__":
    build()
