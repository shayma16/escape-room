#!/usr/bin/env python3
"""Batch 4 items 16/17 REDO (z4 key-taken / tag-taken).

The dead agent's deterministic row-interp smeared the beveled stone masonry
(forbidden blur/smear inpaint). Redo via ONE nano-banana /edit that removes
BOTH the key and the tag and restores clean masonry + empty mounting nails
(the proven z2 F3/F4 pattern: one combined-empty plate -> two INDEPENDENT
silhouette-masked overlays; the retained item stays pixel-identical to base).
Method deviation from the plan's "$0 PIL clone-out": $0.15 NB (flagged).
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_nb import edit_region, obj_overlay
from l2_b4_states import seam

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z4 = os.path.join(A2, "z4", "v-vault-interior")
STATES = os.path.join(Z4, "states")
REJ = os.path.join(A2, "_rejects")
OVJSON = os.path.join(A2, "z4", "z4-state-overlays.json")
WIDE = os.path.join(Z4, "z4-vault-base@3x.png")
CU_W, CU_H = 2048, 1536
CU = {"cu-key-hook": (700, 280, 1620, 970),
      "cu-tag-nail": (500, 350, 1400, 1025)}
REGION = (680, 400, 1300, 990)
SEED = 740416


def key_mask(size):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    d.ellipse([1018, 436, 1248, 660], fill=255)          # bow
    d.rectangle([1058, 610, 1152, 852], fill=255)        # shaft
    d.rectangle([1002, 820, 1226, 952], fill=255)        # bit/box
    d.rectangle([1035, 424, 1150, 470], fill=255)        # revealed nail zone
    d.polygon([(1150, 470), (1300, 640), (1300, 940),    # cast shadow (right)
               (1150, 900)], fill=140)
    return m


def tag_mask(size):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    d.rectangle([734, 612, 962, 952], fill=255)          # tag body
    d.polygon([(748, 546), (800, 456), (896, 456), (886, 648),
               (782, 668)], fill=255)                    # top wedge + rope
    d.polygon([(694, 552), (784, 700), (752, 950), (694, 950)], fill=255)
    d.polygon([(696, 640), (600, 800), (600, 960), (740, 960)], fill=120)  # shadow left
    return m


def save(meta, name, wide_new, base, cu_name, note):
    x0, y0, x1, y1 = REGION
    # wide patch
    wr = {"ov-key-taken": (1000, 415, 1255, 960),
          "ov-tag-taken": (600, 425, 970, 970)}[name]
    wpatch = wide_new.crop(wr)
    sc = seam(base, wpatch.convert("RGB"), wr)
    assert sc <= 24, f"{name} wide seam {sc:.1f}"
    wpatch.convert("RGB").save(os.path.join(STATES, name + "-wide@3x.png"))
    # CU echo
    fx0, fy0, fx1, fy1 = CU[cu_name]
    s = CU_W / (fx1 - fx0)
    cu_base = Image.open(os.path.join(Z4, cu_name + "@3x.png")).convert("RGB")
    cu_new = wide_new.crop((fx0, fy0, fx1, fy1)).resize((CU_W, CU_H),
                                                        Image.LANCZOS)
    cx0 = max(0, int((wr[0] - fx0) * s)); cy0 = max(0, int((wr[1] - fy0) * s))
    cx1 = min(CU_W, int((wr[2] - fx0) * s) + 1)
    cy1 = min(CU_H, int((wr[3] - fy0) * s) + 1)
    cpatch = cu_new.crop((cx0, cy0, cx1, cy1))
    sc2 = seam(cu_base, cpatch, (cx0, cy0, cx1, cy1))
    assert sc2 <= 24, f"{name} CU seam {sc2:.1f}"
    cpatch.save(os.path.join(STATES, name + "@3x.png"))
    meta[name] = {"base": cu_name, "rect_3x": [cx0, cy0, cx1, cy1],
                  "wide_base": "z4-vault-base", "wide_rect_3x": list(wr),
                  "note": note}
    print(f"  {name}: wide seam {sc:.1f} / CU seam {sc2:.1f} PASS")


def main():
    base = Image.open(WIDE).convert("RGB")
    # archive the old smeared overlays
    for f in os.listdir(STATES):
        if f.startswith(("ov-key-taken", "ov-tag-taken")):
            os.replace(os.path.join(STATES, f),
                       os.path.join(REJ, "z4-" + f.replace("@3x", "-b4smear@3x")))
    content = ("remove BOTH objects hanging on the stone wall: the large iron "
               "winding key (right) and the brass return-tag with its rope loop "
               "(left). Rebuild the clean stylized stone-block masonry wall "
               "behind them so it matches the surrounding blocks, mortar bevels "
               "and the warm lamp lighting exactly. Leave a small empty iron "
               "mounting nail on the wall where EACH one hung (two empty nails). "
               "Keep the glass oil lamp, the wooden stair stringer and the "
               "stone shelf-ledge exactly as they are.")
    reg, raw, seed = edit_region(base, REGION, content, SEED, tag="z4-keytag")
    print("  fal seed:", seed)
    clean_full = base.copy()
    clean_full.paste(reg, (REGION[0], REGION[1]))

    meta = json.load(open(OVJSON)) if os.path.exists(OVJSON) else {}
    km = key_mask(base.size)
    tm = tag_mask(base.size)
    key_new = obj_overlay(base, clean_full, km, (0, 0, base.width, base.height))
    tag_new = obj_overlay(base, clean_full, tm, (0, 0, base.width, base.height))
    save(meta, "ov-key-taken", key_new, base, "cu-key-hook",
         "winding key taken (NB masonry rebuild): clean stone + empty iron "
         "mounting nail revealed; square-bit rhyme leaves with the key. Tag "
         "untouched.")
    save(meta, "ov-tag-taken", tag_new, base, "cu-tag-nail",
         "return tag + rope loop taken (NB masonry rebuild): clean stone + "
         "empty nail; key untouched.")
    json.dump(meta, open(OVJSON, "w"), indent=1)
    print("z4-state-overlays.json updated (redo)")


if __name__ == "__main__":
    main()
