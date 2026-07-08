#!/usr/bin/env python3
"""Stamp canonical 7-dot Orion onto the BLANK brass astrolabe plate at exact relative
geometry (orion-canonical.json). Preview by default; --commit writes @3x/@2x/@1x."""
import os, sys, json, math
from PIL import Image, ImageDraw, ImageFilter

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
SCRATCH = r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim-escape-room\8c048282-9ce7-4b1a-b54a-04e2ba948c25\scratchpad"
SRC = os.path.join(ROOT, "z2", "v-cabinet", "cu-astrolabe-plate-nb@3x.png")
CANON = json.load(open(os.path.join(ROOT, "masters", "orion-canonical.json")))

# blank-plate face center + radius on 2048x1536 (measured from render: hub ~ (1035,765))
PCX, PCY, PR = 1035, 690, 560
OFF = CANON["offsets"]
maxr = max(math.hypot(x, y) for (x, y, s) in OFF.values())
scale = (PR * 0.66) / maxr
DOTR = 30

def stamp():
    im = Image.open(SRC).convert("RGB")
    d = ImageDraw.Draw(im)
    for name, (ox, oy, s) in OFF.items():
        px = PCX + ox * scale
        py = PCY + oy * scale
        r = DOTR * (0.78 + 0.22 * s)
        d.ellipse([px-r, py-r, px+r, py+r], fill=(46, 36, 16))
        d.ellipse([px-r*0.6, py-r*0.6, px+r*0.6, py+r*0.6], fill=(24, 18, 8))
        d.arc([px-r, py-r, px+r, py+r], start=25, end=145, fill=(214, 184, 116), width=max(2, int(r*0.16)))
    return im

if __name__ == "__main__":
    out = stamp()
    if "--commit" in sys.argv:
        w, h = out.size
        out.save(SRC, "PNG")
        out.resize((round(w*2/3), round(h*2/3)), Image.LANCZOS).save(SRC.replace("@3x", "@2x"), "PNG")
        out.resize((round(w/3), round(h/3)), Image.LANCZOS).save(SRC.replace("@3x", "@1x"), "PNG")
        print("COMMITTED", SRC)
    else:
        p = os.path.join(SCRATCH, "orion_preview.png"); out.resize((683, 512)).save(p, "PNG")
        out.convert("L").resize((683, 512)).save(os.path.join(SCRATCH, "orion_preview_GRAY.png"), "PNG")
        print("preview ->", p)
