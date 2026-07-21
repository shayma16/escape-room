#!/usr/bin/env python3
"""Evidence sheet: for each L2 wide base, draw the iPad dual-safe x-band + the RELIABLE
overlay-anchored art rects (solid) + the STALE Swift hotspot rects (dashed) so the
mismatch is visible. Overlay anchors come from the state-overlays JSONs (plate-derived);
hotspots come from Level2Coordinator.swift (many 'estimated, no overlay anchor')."""
import json, os
from PIL import Image, ImageDraw

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-2"
OUT = os.path.join(ROOT, "_reframe-work")
W3, H3 = 3840, 1920
IPADX = (1/6, 5/6)

BASE = {
    "bench": "z1/v-bench/z1-bench-base@3x.png",
    "master": "z1/v-master/z1-master-base@3x.png",
    "door": "z1/v-door/z1-door-base@3x.png",
    "frame": "z2/v-frame/z2-frame-base@3x.png",
    "clockrow": "z2/v-clockrow/z2-clockrow-base@3x.png",
    "dial": "z3/v-dial/z3-dial-base@3x.png",
    "vault": "z4/v-vault-interior/z4-vault-base@3x.png",
}
# base-plate -> view key
B2V = {"z1-bench-base": "bench", "z1-master-base": "master", "z1-door-base": "door",
       "z2-frame-base": "frame", "z2-clockrow-base": "clockrow", "z3-dial-base": "dial",
       "z4-vault-base": "vault"}

HOTSPOTS = {
    "bench": [("screwdriver",0.255,0.229,0.094,0.349),("stove",0.63,0.70,0.18,0.16),
              ("coat",0.03,0.26,0.17,0.42),("slate",0.35,0.28,0.22,0.32),("barometer",0.80,0.18,0.15,0.26)],
    "master":[("master-clock",0.06,0.08,0.22,0.74),("door-dial",0.52,0.16,0.26,0.60),("crate",0.66,0.78,0.16,0.20)],
    "door":  [("stair-door",0.14,0.30,0.30,0.46),("house-ring",0.52,0.28,0.12,0.16),("sill",0.60,0.46,0.12,0.18),
              ("cat-cushion",0.66,0.55,0.24,0.26),("cat-floor",0.62,0.78,0.22,0.14),("floor-cache",0.6375,0.898,0.1281,0.102)],
    "frame": [("gear-frame",0.20,0.26,0.34,0.48),("arbor",0.15,0.44,0.14,0.22),("gear-rack",0.54,0.52,0.22,0.28),
              ("brick",0.65,0.48,0.16,0.22),("panel",0.19,0.72,0.26,0.26)],
    "clockrow":[("clockrow",0.06,0.26,0.48,0.34),("cabinet",0.58,0.66,0.18,0.24),("display-case",0.76,0.28,0.20,0.38)],
    "dial":  [("great-dial",0.28,0.16,0.22,0.48),("drum",0.08,0.66,0.18,0.28),("pendulum",0.50,0.10,0.12,0.62),("hatch",0.60,0.72,0.28,0.24)],
    "vault": [("key-hook",0.2604,0.2161,0.0664,0.2839),("tag-nail",0.1563,0.2214,0.0964,0.2839),
              ("shelf",0.54,0.28,0.32,0.42),("vault-exit",0.85,0.20,0.13,0.60)],
}

def load_anchors():
    a = {v: [] for v in BASE}
    for f in ["z1/z1-state-overlays.json","z2/z2-state-overlays.json","z3/z3-state-overlays.json","z4/z4-state-overlays.json"]:
        d = json.load(open(os.path.join(ROOT,f)))
        for k,val in d.items():
            if isinstance(val,dict) and "wide_rect_3x" in val:
                wb = val.get("wide_base")
                if wb in B2V:
                    x0,y0,x1,y1 = val["wide_rect_3x"]
                    a[B2V[wb]].append((k, x0/W3, y0/H3, x1/W3, y1/H3))
    return a

def dashed_rect(d, box, color, w=6, dash=28):
    x0,y0,x1,y1 = box
    x=x0
    while x<x1:
        d.line([(x,y0),(min(x+dash,x1),y0)],fill=color,width=w); d.line([(x,y1),(min(x+dash,x1),y1)],fill=color,width=w); x+=2*dash
    y=y0
    while y<y1:
        d.line([(x0,y),(x0,min(y+dash,y1))],fill=color,width=w); d.line([(x1,y),(x1,min(y+dash,y1))],fill=color,width=w); y+=2*dash

def main():
    anchors = load_anchors()
    for view, rel in BASE.items():
        im = Image.open(os.path.join(ROOT,rel)).convert("RGB")
        W,H = im.size
        d = ImageDraw.Draw(im)
        d.line([(IPADX[0]*W,0),(IPADX[0]*W,H)],fill=(0,255,0),width=8)
        d.line([(IPADX[1]*W,0),(IPADX[1]*W,H)],fill=(0,255,0),width=8)
        # reliable anchors (solid): orange if outside band, cyan if inside
        for (k,x0,y0,x1,y1) in anchors[view]:
            out = x0<IPADX[0] or x1>IPADX[1]
            col = (255,120,0) if out else (0,220,255)
            d.rectangle([x0*W,y0*H,x1*W,y1*H],outline=col,width=8)
            d.text((x0*W+4,y0*H+4),k.replace("ov-",""),fill=col)
        # stale hotspots (dashed magenta)
        for (k,x,y,w,h) in HOTSPOTS[view]:
            dashed_rect(d,(x*W,y*H,(x+w)*W,(y+h)*H),(255,0,255))
            d.text(((x)*W+4,(y+h)*H-30),"HS:"+k,fill=(255,0,255))
        im.resize((1400,700),Image.LANCZOS).save(os.path.join(OUT,f"evidence-{view}.png"))
        print("wrote evidence-"+view)

if __name__ == "__main__":
    main()
