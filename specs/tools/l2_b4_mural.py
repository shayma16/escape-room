#!/usr/bin/env python3
"""Batch 4 / item 5 — z2 automaton-wall mural sprites + track (deterministic).

The mural is a carved wood relief; the ANIMATED reward (style 6.4) is the sun
disc crossing the town + the watchman's bell strike. Deliverables:
  - sp-sun        : RGBA sun-disc cutout (radial alpha) — travels the track
  - ov-sun-absent : wall patch behind the sun (start recess) so it can move
  - sp-bell       : RGBA bell cutout — swings for the strike (top pivot)
  - ov-bell-absent: wall patch behind the bell so it can swing
  - sp-figure-*   : woman / drummer / watchman figure layers (soft alpha) +
                    pivot anchors for subtle jointed sway (D5 = Developer)
  - mural-sprites.json : track polyline + pivots + strike/cadence notes
The strike is carried by the bell swing + audio (no NB strike-pose needed;
$0.15 reserve untouched). Base patches seam-checked (<=24).
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_states import seam

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z2 = os.path.join(A2, "z2", "v-frame")
WIDE = os.path.join(Z2, "z2-frame-base@3x.png")
STATES = os.path.join(Z2, "states")
SPRITES = os.path.join(Z2, "sprites")
OVJSON = os.path.join(A2, "z2", "z2-state-overlays.json")

SUN = (1315, 125, 1490, 305)
SUN_C = (1400, 212)
BELL = (2092, 448, 2228, 578)
BELL_PIVOT = (2160, 452)
FIGURES = {
    "woman":   {"rect": (1090, 440, 1285, 725), "pivot": (1180, 720)},
    "drummer": {"rect": (1655, 445, 1855, 775), "pivot": (1748, 765)},
    "watchman": {"rect": (1912, 552, 2068, 872), "pivot": (1990, 862)},
}
# carved sun-track centerline (approx, @3x): sun rides L->R across the town
TRACK = [[690, 250], [1040, 288], [1385, 200], [1660, 250],
         [1900, 430], [1960, 590], [1790, 660]]


def load_json():
    return json.load(open(OVJSON)) if os.path.exists(OVJSON) else {}


def radial_alpha(size, cx, cy, r_in, r_out):
    w, h = size
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    d = np.hypot(xx - cx, yy - cy)
    a = np.clip((r_out - d) / (r_out - r_in), 0, 1)
    return Image.fromarray((a * 255).astype(np.uint8))


def wall_fill(wide, rect):
    """Clone flat wall wood behind an element: per-column vertical linear
    interp between the rows just above/below the element bbox (the wall is a
    smooth vertical-plank panel here, so column interp is seam-clean)."""
    x0, y0, x1, y1 = rect
    pad = 26
    src = wide.crop((x0, y0 - pad, x1, y1 + pad)).convert("RGB")
    a = np.asarray(src, np.float32)
    h, w = a.shape[:2]
    top = a[:pad].mean(0)          # wall strip above
    bot = a[-pad:].mean(0)         # wall strip below
    t = np.linspace(0, 1, h)[:, None, None]
    fill = top[None] * (1 - t) + bot[None] * t
    # add faint plank grain from the top strip (vertical streaks)
    grain = a[:pad] - a[:pad].mean(0, keepdims=True)
    gg = np.tile(grain.mean(0)[None], (h, 1, 1))
    out = fill + gg * 0.4
    patch = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8)).crop(
        (0, pad, w, pad + (y1 - y0)))
    fm = Image.new("L", patch.size, 0)
    ImageDraw.Draw(fm).rectangle([4, 4, patch.width - 5, patch.height - 5],
                                 fill=255)
    fm = fm.filter(ImageFilter.GaussianBlur(4))
    return Image.composite(patch, wide.crop(rect).convert("RGB"), fm)


def save_surface(meta, name, patch, rect, base, note):
    os.makedirs(STATES, exist_ok=True)
    patch.convert("RGB").save(os.path.join(STATES, name + "-wide@3x.png"))
    sc = seam(base, patch.convert("RGB"), rect)
    assert sc <= 24, f"{name} seam {sc:.1f}"
    e = meta.setdefault(name, {})
    e["wide_base"] = "z2-frame-base"
    e["wide_rect_3x"] = list(rect)
    e["note"] = note
    print(f"  {name}: rect {rect} seam {sc:.1f} PASS")


def main():
    wide = Image.open(WIDE).convert("RGB")
    meta = load_json()
    os.makedirs(SPRITES, exist_ok=True)
    sj = {}

    # ---- sun disc ----
    sun = wide.crop(SUN).convert("RGBA")
    cx, cy = SUN_C[0] - SUN[0], SUN_C[1] - SUN[1]
    sun.putalpha(radial_alpha(sun.size, cx, cy, 74, 93))
    sun.save(os.path.join(SPRITES, "sp-sun@3x.png"))
    save_surface(meta, "ov-sun-absent", wall_fill(wide, SUN), SUN, wide,
                 "flat wall behind the sun disc (column interp of the plank "
                 "panel) so the sun can travel the track without ghosting")
    sj["sp-sun"] = {"sprite": "sp-sun@3x.png", "rect_3x": list(SUN),
                    "center_px_at_3x": list(SUN_C),
                    "background_patch": "states/ov-sun-absent-wide@3x.png"}

    # ---- bell ----
    bell = wide.crop(BELL).convert("RGBA")
    bw, bh = bell.size
    bm = Image.new("L", (bw, bh), 0)
    bd = ImageDraw.Draw(bm)
    # bell body: trapezoid/dome + flare
    bd.pieslice([8, 2, bw - 8, bh - 20], 180, 360, fill=255)
    bd.polygon([(14, bh // 2), (bw - 14, bh // 2), (bw - 6, bh - 14),
                (6, bh - 14)], fill=255)
    bm = bm.filter(ImageFilter.GaussianBlur(2))
    bell.putalpha(bm)
    bell.save(os.path.join(SPRITES, "sp-bell@3x.png"))
    save_surface(meta, "ov-bell-absent", wall_fill(wide, BELL), BELL, wide,
                 "flat wall behind the bell so it can swing for the strike")
    sj["sp-bell"] = {"sprite": "sp-bell@3x.png", "rect_3x": list(BELL),
                     "pivot_px_at_3x": list(BELL_PIVOT),
                     "strike_swing_deg": 12,
                     "background_patch": "states/ov-bell-absent-wide@3x.png",
                     "note": "watchman bell: swings about the top yoke for the "
                     "strike beat (carried by swing + audio; no separate strike "
                     "pose art). Key poses = rest 0deg / struck +-12deg."}

    # ---- figures (soft-alpha relief layers) ----
    for name, f in FIGURES.items():
        r = f["rect"]
        fig = wide.crop(r).convert("RGBA")
        fw, fh = fig.size
        m = Image.new("L", (fw, fh), 0)
        ImageDraw.Draw(m).ellipse([int(fw * 0.06), int(fh * 0.03),
                                   int(fw * 0.94), int(fh * 0.98)], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(10))
        fig.putalpha(m)
        fig.save(os.path.join(SPRITES, f"sp-figure-{name}@3x.png"))
        sj[f"sp-figure-{name}"] = {
            "sprite": f"sp-figure-{name}@3x.png",
            "rect_3x": list(r), "pivot_px_at_3x": list(f["pivot"]),
            "note": "carved-relief automaton figure layer (soft-alpha). For "
            "the mural run the Developer applies subtle jointed sway about the "
            "pivot; the relief remains in the base plate behind, so keep the "
            "sway small. Primary animated reward is sun-transit + bell-strike."}

    sj["_mural_run"] = {
        "sun_track_at_3x": TRACK,
        "track_note": "carved sun-track centerline (approx); the sun disc "
        "sweeps L->R along it as the town 'runs'. Variable speed; the one "
        "correct full cycle = sun crosses the town then the watchman bell "
        "strikes (bell swing). D5 cadence/timing is Developer; identical-on-"
        "repeat.",
        "strike_beat": "at end of sun transit, swing sp-bell +-12deg (2-3 "
        "beats) + strike audio; figures may sway subtly (optional)."}

    with open(os.path.join(SPRITES, "mural-sprites.json"), "w") as fp:
        json.dump(sj, fp, indent=1)
    with open(OVJSON, "w") as fp:
        json.dump(meta, fp, indent=1)
    print("mural sprites + track written; z2 overlays updated (absent patches)")


if __name__ == "__main__":
    main()
