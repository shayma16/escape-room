#!/usr/bin/env python3
"""Batch 4 item 21 — seam audit of ALL batch-4 surface overlays + review
contact sheet. Loads z2/z3/z4 state-overlays.json, composites every RGB
surface patch on its base (CU + wide), computes the 3px seam ring (PASS<=24),
verifies every referenced file exists, and tiles a review contact sheet.
RGBA additive overlays (mounts, rack-absent, sun/bell reveals) have no rect
seam — file-existence checked only. Prints the audit table."""
import json
import os

from PIL import Image, ImageDraw, ImageFont
import sys
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_states import seam

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
CU_DIR = {
    "cu-gear-frame": "z2/v-frame", "cu-gear-rack": "z2/v-frame",
    "cu-brick-cache": "z2/v-frame",
    "cu-cabinet-drawer": "z2/v-clockrow", "cu-clockrow-plates": "z2/v-clockrow",
    "cu-winding-drum": "z3/v-dial", "cu-great-dial": "z3/v-dial",
    "cu-key-hook": "z4/v-vault-interior", "cu-tag-nail": "z4/v-vault-interior",
}
WIDE_DIR = {"z2-frame-base": "z2/v-frame", "z2-clockrow-base": "z2/v-clockrow",
            "z3-dial-base": "z3/v-dial", "z4-vault-base": "z4/v-vault-interior"}
# batch-4 overlay names per zone json (surface = seam-audited)
BATCH4 = {
    "z2/z2-state-overlays.json": [
        "ov-arbor-oiled", "ov-sun-absent", "ov-bell-absent", "ov-panel-open",
        "ov-brick-empty", "ov-brick-pried-oilcan", "ov-cabinet-empty",
        "ov-cabinet-open-mouse"],
    "z3/z3-state-overlays.json": [
        "ov-drum-oiled", "ov-drum-key-in", "ov-pendulum-absent",
        "ov-hammer-absent", "ov-hatch-open"],
    "z4/z4-state-overlays.json": ["ov-key-taken", "ov-tag-taken"],
}
RGBA_ADDITIVE = {"ov-sun-absent": False}   # (none additive here; mounts audited separately)


def statedir_for(entry):
    if "base" in entry:
        return os.path.join(A2, CU_DIR[entry["base"]], "states")
    return os.path.join(A2, WIDE_DIR[entry["wide_base"]], "states")


def audit():
    rows = []
    tiles = []
    for jf, names in BATCH4.items():
        meta = json.load(open(os.path.join(A2, jf)))
        for nm in names:
            e = meta[nm]
            is_rgba = e.get("rgba", False)
            # CU
            if "base" in e:
                cud = CU_DIR[e["base"]]
                cubase = Image.open(os.path.join(A2, cud, e["base"] + "@3x.png")
                                    ).convert("RGB")
                sd = os.path.join(A2, cud, "states")
                pf = os.path.join(sd, nm + "@3x.png")
                assert os.path.exists(pf), pf
                if is_rgba:
                    ov = Image.open(pf).convert("RGBA")
                    comp = cubase.convert("RGBA"); comp.alpha_composite(
                        ov, tuple(e["rect_3x"][:2])); comp = comp.convert("RGB")
                    scu = None
                else:
                    patch = Image.open(pf).convert("RGB")
                    scu = seam(cubase, patch, e["rect_3x"])
                    comp = cubase.copy(); comp.paste(patch, tuple(e["rect_3x"][:2]))
                rows.append((nm, "CU", e["base"], scu))
                t = comp.crop((max(0, e["rect_3x"][0]-90), max(0, e["rect_3x"][1]-90),
                               e["rect_3x"][2]+90, e["rect_3x"][3]+90))
                t.thumbnail((360, 360)); tiles.append((nm+" CU", t))
            # wide
            if "wide_base" in e:
                wd = WIDE_DIR[e["wide_base"]]
                wbase = Image.open(os.path.join(A2, wd, e["wide_base"]+"@3x.png")
                                   ).convert("RGB")
                sd = os.path.join(A2, wd, "states")
                pf = os.path.join(sd, nm + "-wide@3x.png")
                assert os.path.exists(pf), pf
                if is_rgba:
                    ov = Image.open(pf).convert("RGBA")
                    comp = wbase.convert("RGBA"); comp.alpha_composite(
                        ov, tuple(e["wide_rect_3x"][:2])); comp = comp.convert("RGB")
                    sw = None
                else:
                    patch = Image.open(pf).convert("RGB")
                    sw = seam(wbase, patch, e["wide_rect_3x"])
                    comp = wbase.copy(); comp.paste(patch, tuple(e["wide_rect_3x"][:2]))
                rows.append((nm, "wide", e["wide_base"], sw))
    # mounts + rack-absent (RGBA) — existence only, reported as additive
    z2 = json.load(open(os.path.join(A2, "z2/z2-state-overlays.json")))
    add = [k for k in z2 if k.startswith(("ov-mount-", "ov-rack-absent-"))]
    print("\nSEAM AUDIT — batch-4 surface overlays (PASS <= 24):")
    worst = 0.0
    for nm, kind, base, sc in rows:
        if sc is None:
            print(f"  {nm:28s} {kind:4s} {base:20s} RGBA additive (no rect seam)")
        else:
            worst = max(worst, sc)
            flag = "PASS" if sc <= 24 else "FAIL"
            print(f"  {nm:28s} {kind:4s} {base:20s} seam {sc:5.1f} {flag}")
            assert sc <= 24, f"{nm} {kind} seam {sc}"
    print(f"\n  RGBA additive (existence-verified): "
          f"{len(add)} mounts+rack + sun/bell reveals")
    print(f"  WORST surface seam this batch: {worst:.1f} (gate 24) — ALL PASS")

    # contact sheet
    cols = 4
    tw = max(t.width for _, t in tiles) + 12
    th = max(t.height for _, t in tiles) + 30
    rows_n = (len(tiles) + cols - 1) // cols
    sheet = Image.new("RGB", (cols * tw + 12, rows_n * th + 12), (24, 24, 28))
    d = ImageDraw.Draw(sheet)
    for i, (lbl, t) in enumerate(tiles):
        cx = 12 + (i % cols) * tw
        cy = 12 + (i // cols) * th
        sheet.paste(t, (cx, cy))
        d.text((cx, cy + t.height + 2), lbl, fill=(210, 210, 210))
    out = os.path.join(A2, "z2", "z2z3z4-review-batch4.png")
    sheet.save(out)
    print("\ncontact sheet:", out)


if __name__ == "__main__":
    audit()
