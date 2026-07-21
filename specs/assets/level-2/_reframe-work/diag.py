#!/usr/bin/env python3
"""Diagnostic: overlay hotspot rects + iPad/iPhone dual-safe band on each L2 wide base.
Purely for visual verification of what falls outside the iPad x-band."""
import os
from PIL import Image, ImageDraw

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-2"
OUT = os.path.join(ROOT, "_reframe-work")

# iPad 4:3 aspectFill on 2:1 plate: visible x in [1/6, 5/6]; iPhone 19.5:9 visible y in [0.03846,0.96154]
IPAD_X = (1/6, 5/6)
IPHONE_Y = (0.03846, 0.96154)

# hotspots (id, x0,y0,w,h) transcribed from Level2Coordinator.swift
HOTSPOTS = {
    "bench": [
        ("screwdriver", 0.255, 0.229, 0.094, 0.349),
        ("stove", 0.63, 0.70, 0.18, 0.16),
        ("coat", 0.03, 0.26, 0.17, 0.42),
        ("slate", 0.35, 0.28, 0.22, 0.32),
        ("barometer", 0.80, 0.18, 0.15, 0.26),
    ],
    "master": [
        ("master-clock", 0.06, 0.08, 0.22, 0.74),
        ("door-dial", 0.52, 0.16, 0.26, 0.60),
        ("crate", 0.66, 0.78, 0.16, 0.20),
    ],
    "door": [
        ("stair-door", 0.14, 0.30, 0.30, 0.46),
        ("house-ring", 0.52, 0.28, 0.12, 0.16),
        ("sill", 0.60, 0.46, 0.12, 0.18),
        ("cat-cushion", 0.66, 0.55, 0.24, 0.26),
        ("cat-floor", 0.62, 0.78, 0.22, 0.14),
        ("floor-cache", 0.6375, 0.898, 0.1281, 0.102),
    ],
    "frame": [
        ("gear-frame", 0.20, 0.26, 0.34, 0.48),
        ("arbor", 0.15, 0.44, 0.14, 0.22),
        ("gear-rack", 0.54, 0.52, 0.22, 0.28),
        ("brick", 0.65, 0.48, 0.16, 0.22),
        ("panel", 0.19, 0.72, 0.26, 0.26),
    ],
    "clockrow": [
        ("clockrow", 0.06, 0.26, 0.48, 0.34),
        ("cabinet", 0.58, 0.66, 0.18, 0.24),
        ("display-case", 0.76, 0.28, 0.20, 0.38),
    ],
    "dial": [
        ("great-dial", 0.28, 0.16, 0.22, 0.48),
        ("drum", 0.08, 0.66, 0.18, 0.28),
        ("pendulum", 0.50, 0.10, 0.12, 0.62),
        ("hatch", 0.60, 0.72, 0.28, 0.24),
    ],
    "vault": [
        ("key-hook", 0.2604, 0.2161, 0.0664, 0.2839),
        ("tag-nail", 0.1563, 0.2214, 0.0964, 0.2839),
        ("shelf", 0.54, 0.28, 0.32, 0.42),
        ("vault-exit", 0.85, 0.20, 0.13, 0.60),
    ],
}

BASE = {
    "bench": "z1/v-bench/z1-bench-base@3x.png",
    "master": "z1/v-master/z1-master-base@3x.png",
    "door": "z1/v-door/z1-door-base@3x.png",
    "frame": "z2/v-frame/z2-frame-base@3x.png",
    "clockrow": "z2/v-clockrow/z2-clockrow-base@3x.png",
    "dial": "z3/v-dial/z3-dial-base@3x.png",
    "vault": "z4/v-vault-interior/z4-vault-base@3x.png",
}

def analyze():
    for view, hs in HOTSPOTS.items():
        im = Image.open(os.path.join(ROOT, BASE[view])).convert("RGB")
        W, H = im.size
        d = ImageDraw.Draw(im)
        # iPad band (green vertical lines) + iPhone band (blue horizontal lines)
        d.line([(IPAD_X[0]*W, 0), (IPAD_X[0]*W, H)], fill=(0, 255, 0), width=6)
        d.line([(IPAD_X[1]*W, 0), (IPAD_X[1]*W, H)], fill=(0, 255, 0), width=6)
        d.line([(0, IPHONE_Y[0]*H), (W, IPHONE_Y[0]*H)], fill=(0, 128, 255), width=6)
        d.line([(0, IPHONE_Y[1]*H), (W, IPHONE_Y[1]*H)], fill=(0, 128, 255), width=6)
        print(f"\n=== {view} (band x[{IPAD_X[0]:.3f},{IPAD_X[1]:.3f}]) ===")
        for (hid, x, y, w, h) in hs:
            x0, y0, x1, y1 = x, y, x+w, y+h
            out_l = x0 < IPAD_X[0]
            out_r = x1 > IPAD_X[1]
            out_t = y0 < IPHONE_Y[0]
            out_b = y1 > IPHONE_Y[1]
            flags = []
            if out_l: flags.append(f"LEFT({x0:.3f})")
            if out_r: flags.append(f"RIGHT({x1:.3f})")
            if out_t: flags.append(f"TOP({y0:.3f})")
            if out_b: flags.append(f"BOT({y1:.3f})")
            col = (255, 0, 0) if flags else (255, 220, 0)
            d.rectangle([x0*W, y0*H, x1*W, y1*H], outline=col, width=8)
            d.text((x0*W+6, y0*H+6), hid, fill=col)
            print(f"  {hid:14s} x[{x0:.3f},{x1:.3f}] y[{y0:.3f},{y1:.3f}]  {'OUT '+' '.join(flags) if flags else 'in'}")
        im.resize((1280, 640), Image.LANCZOS).save(os.path.join(OUT, f"diag-{view}.png"))

if __name__ == "__main__":
    analyze()
