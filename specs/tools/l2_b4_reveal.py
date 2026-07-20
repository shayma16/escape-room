#!/usr/bin/env python3
"""Batch 4 NB reveal/add overlays (items 6,7,8,10,15). Dispatch per item:
  python l2_b4_reveal.py drum-key-in | brick | cabinet | panel | hatch

Each: ONE nano-banana /edit (crop-scoped) -> shift-register -> CHANGE-MASK
composite (only NB-changed pixels replace base; unchanged surface stays
pixel-identical) -> wide patch (+CU echo where the item has a CU) -> seam
check (<=24). Canonical-prop variants (oil-can, tin-mouse) are composited
deterministically on top. $0.15 per item.
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_nb import edit_region
from l2_b4_states import seam

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
CU_W, CU_H = 2048, 1536
Z2F = os.path.join(A2, "z2", "v-frame")
Z2C = os.path.join(A2, "z2", "v-clockrow")
Z3 = os.path.join(A2, "z3", "v-dial")
Z2JSON = os.path.join(A2, "z2", "z2-state-overlays.json")
Z3JSON = os.path.join(A2, "z3", "z3-state-overlays.json")


def reveal(base, region, content, seed, tag, thresh=17):
    reg, raw, s = edit_region(base, region, content, seed, tag=tag)
    print("  fal seed:", s)
    x0, y0, x1, y1 = region
    b = np.asarray(base.crop(region), np.int16)
    e = np.asarray(reg, np.int16)
    ch = np.abs(e - b).max(2) > thresh
    m = Image.fromarray((ch * 255).astype(np.uint8)).filter(
        ImageFilter.MaxFilter(9)).filter(ImageFilter.GaussianBlur(3))
    full = base.copy()
    full.paste(reg, (x0, y0), m)
    # change bbox (in full coords)
    ys, xs = np.nonzero(np.asarray(m) > 20)
    if len(xs) == 0:
        raise RuntimeError("no change detected — edit had no effect")
    bb = (x0 + int(xs.min()) - 4, y0 + int(ys.min()) - 4,
          x0 + int(xs.max()) + 5, y0 + int(ys.max()) + 5)
    return full, bb


def save_wide(meta, name, full, base, rect, wide_base, note):
    patch = full.crop(rect)
    sc = seam(base, patch.convert("RGB"), rect)
    assert sc <= 24, f"{name} wide seam {sc:.1f}"
    stdir = os.path.dirname(base_path_of(wide_base)) + os.sep + "states"
    os.makedirs(stdir, exist_ok=True)
    patch.convert("RGB").save(os.path.join(stdir, name + "-wide@3x.png"))
    e = meta.setdefault(name, {})
    e["wide_base"] = wide_base
    e["wide_rect_3x"] = list(rect)
    e["note"] = note
    print(f"  {name} (wide): rect {rect} seam {sc:.1f} PASS")


def save_cu(meta, name, full, cu_frame, cu_base_name, wide_rect, note):
    fx0, fy0, fx1, fy1 = cu_frame
    s = CU_W / (fx1 - fx0)
    cu_base = Image.open(cu_base_name + "@3x.png").convert("RGB")
    cu_new = full.crop((fx0, fy0, fx1, fy1)).resize((CU_W, CU_H), Image.LANCZOS)
    wr = wide_rect
    cx0 = max(0, int((wr[0] - fx0) * s)); cy0 = max(0, int((wr[1] - fy0) * s))
    cx1 = min(CU_W, int((wr[2] - fx0) * s) + 1)
    cy1 = min(CU_H, int((wr[3] - fy0) * s) + 1)
    cpatch = cu_new.crop((cx0, cy0, cx1, cy1))
    sc = seam(cu_base, cpatch, (cx0, cy0, cx1, cy1))
    assert sc <= 24, f"{name} CU seam {sc:.1f}"
    stdir = os.path.dirname(cu_base_name) + os.sep + "states"
    os.makedirs(stdir, exist_ok=True)
    cpatch.save(os.path.join(stdir, name + "@3x.png"))
    e = meta.setdefault(name, {})
    e["base"] = os.path.basename(cu_base_name)
    e["rect_3x"] = [cx0, cy0, cx1, cy1]
    e["note"] = note
    print(f"  {name} (CU): seam {sc:.1f} PASS")


def base_path_of(wide_base):
    return {"z2-frame-base": os.path.join(Z2F, "z2-frame-base@3x.png"),
            "z2-clockrow-base": os.path.join(Z2C, "z2-clockrow-base@3x.png"),
            "z3-dial-base": os.path.join(Z3, "z3-dial-base@3x.png")}[wide_base]


def load(p):
    return json.load(open(p)) if os.path.exists(p) else {}


# ---------------------------------------------------------------- items
def do_drum_key_in():
    base = Image.open(base_path_of("z3-dial-base")).convert("RGB")
    region = (450, 1360, 900, 1760)
    content = ("a brass winding key is now inserted into the square socket on "
               "the drum's axle end; its round ring-handle (bow) and shaft "
               "protrude out toward the viewer, seated firmly IN the square "
               "socket (the square bit is hidden inside the socket). The rest "
               "of the winding drum, rope and bearing are unchanged.")
    full, bb = reveal(base, region, content, 740410, "z3-drumkey")
    meta = load(Z3JSON)
    save_wide(meta, "ov-drum-key-in", full, base, bb, "z3-dial-base",
              "winding key seated in the drum's square socket (NB): ring "
              "handle + shaft protrude, square bit hidden in socket (square-bit "
              "rhyme preserved).")
    save_cu(meta, "ov-drum-key-in", full, (0, 1030, 1187, 1920),
            os.path.join(Z3, "cu-winding-drum"), bb,
            "winding key seated in socket (CU21).")
    json.dump(meta, open(Z3JSON, "w"), indent=1)


def do_brick():
    base = Image.open(base_path_of("z2-frame-base")).convert("RGB")
    region = (2560, 990, 3010, 1330)
    content = ("one brick just below the small carved gear-and-ring mark is "
               "pried loose and removed, leaving a dark rectangular cavity "
               "recessed into the brick chimney; the surrounding bricks, "
               "mortar and the carved mark are unchanged.")
    full, bb = reveal(base, region, content, 740407, "z2-brick")
    meta = load(Z2JSON)
    cuf = (2470, 935, 3030, 1355)
    cub = os.path.join(Z2F, "cu-brick-cache")
    # empty variant
    save_wide(meta, "ov-brick-empty", full, base, bb, "z2-frame-base",
              "brick pried loose: empty dark cavity (manual pickup done).")
    save_cu(meta, "ov-brick-empty", full, cuf, cub, bb,
            "brick cache pried, empty cavity (CU16).")
    # oil-can variant: composite canonical icon into the cavity
    oil = Image.open(os.path.join(A2, "z2", "icons", "inv-oil-can@3x.png")
                     ).convert("RGBA")
    cav = (bb[0], bb[1], bb[2], bb[3])
    cw = int((cav[2] - cav[0]) * 0.62)
    oil2 = oil.copy()
    oil2.thumbnail((cw, cw), Image.LANCZOS)
    ocx = (cav[0] + cav[2]) // 2 - oil2.width // 2
    ocy = (cav[1] + cav[3]) // 2 - oil2.height // 2 + 10
    full2 = full.copy()
    # slight interior shadow behind can
    sh = Image.new("RGBA", oil2.size, (0, 0, 0, 0))
    sh.putalpha(oil2.split()[3].point(lambda v: v * 110 // 255))
    sh = sh.filter(ImageFilter.GaussianBlur(9))
    full2.paste(sh, (ocx + 8, ocy + 10), sh)
    full2.paste(oil2, (ocx, ocy), oil2)
    save_wide(meta, "ov-brick-pried-oilcan", full2, base, bb, "z2-frame-base",
              "brick pried loose: canonical oil can nestled in the cavity.")
    save_cu(meta, "ov-brick-pried-oilcan", full2, cuf, cub, bb,
            "brick cache pried + oil can in cavity (CU16).")
    json.dump(meta, open(Z2JSON, "w"), indent=1)


def do_cabinet():
    base = Image.open(base_path_of("z2-clockrow-base")).convert("RGB")
    region = (2330, 1360, 2770, 1650)
    content = ("the top-center drawer of the parts cabinet is pulled open "
               "toward the viewer, its front jutting out and the empty wooden "
               "drawer interior (bottom and side walls) now visible; the other "
               "drawers and the cabinet top are unchanged.")
    full, bb = reveal(base, region, content, 740408, "z2-cabinet")
    meta = load(Z2JSON)
    cuf = (2050, 1095, 3150, 1920)
    cub = os.path.join(Z2C, "cu-cabinet-drawer")
    save_cu(meta, "ov-cabinet-empty", full, cuf, cub, bb,
            "top drawer open, empty interior (CU18); manual pickup done.")
    save_wide(meta, "ov-cabinet-empty", full, base, bb, "z2-clockrow-base",
              "top drawer open, empty.")
    # mouse variant
    mouse = Image.open(os.path.join(A2, "z2", "icons", "inv-toy-mouse@3x.png")
                       ).convert("RGBA")
    mw = int((bb[2] - bb[0]) * 0.5)
    m2 = mouse.copy(); m2.thumbnail((mw, mw), Image.LANCZOS)
    mcx = (bb[0] + bb[2]) // 2 - m2.width // 2
    mcy = bb[3] - m2.height - 20
    full2 = full.copy()
    sh = Image.new("RGBA", m2.size, (0, 0, 0, 0))
    sh.putalpha(m2.split()[3].point(lambda v: v * 100 // 255))
    sh = sh.filter(ImageFilter.GaussianBlur(8))
    full2.paste(sh, (mcx + 6, mcy + 8), sh)
    full2.paste(m2, (mcx, mcy), m2)
    save_cu(meta, "ov-cabinet-open-mouse", full2, cuf, cub, bb,
            "top drawer open with the tin toy mouse inside (CU18); round-winged "
            "butterfly key visible.")
    save_wide(meta, "ov-cabinet-open-mouse", full2, base, bb,
              "z2-clockrow-base", "top drawer open + tin mouse.")
    json.dump(meta, open(Z2JSON, "w"), indent=1)


def do_panel():
    base = Image.open(base_path_of("z2-frame-base")).convert("RGB")
    region = (760, 1420, 1700, 1920)
    content = ("the framed wooden wall panel is swung OPEN on its hinge like a "
               "small door, revealing a dark rectangular opening into the next "
               "chamber; a soft warm amber glow (the great clock dial beyond) "
               "leaks out of the opening. The panel door hangs open to one "
               "side. The gear frame, latch hardware and surrounding wall wood "
               "are unchanged.")
    full, bb = reveal(base, region, content, 740406, "z2-panel", thresh=20)
    meta = load(Z2JSON)
    save_wide(meta, "ov-panel-open", full, base, bb, "z2-frame-base",
              "wall panel latched open onto the z3 doorway: dark opening + "
              "warm amber dial glow leak; panel door swung aside (sanctioned "
              "amber leak through an opening, one-sun continuity preserved).")
    json.dump(meta, open(Z2JSON, "w"), indent=1)


def do_hatch():
    base = Image.open(base_path_of("z3-dial-base")).convert("RGB")
    region = (2350, 1490, 3280, 1910)
    content = ("the floor hatch is now OPEN: its lid is lifted away, revealing "
               "a dark rectangular opening in the floorboards with wooden steps "
               "descending into a lower chamber; a warm amber lamp glow rises "
               "up out of the opening from below. The surrounding floor planks "
               "and frame are unchanged.")
    full, bb = reveal(base, region, content, 740415, "z3-hatch", thresh=20)
    meta = load(Z3JSON)
    save_wide(meta, "ov-hatch-open", full, base, bb, "z3-dial-base",
              "floor hatch open onto the stair mouth down to z4 + warm lamp "
              "leak (sanctioned amber leak through an opening).")
    json.dump(meta, open(Z3JSON, "w"), indent=1)


DISP = {"drum-key-in": do_drum_key_in, "brick": do_brick,
        "cabinet": do_cabinet, "panel": do_panel, "hatch": do_hatch}

if __name__ == "__main__":
    DISP[sys.argv[1]]()
    print("done", sys.argv[1])
