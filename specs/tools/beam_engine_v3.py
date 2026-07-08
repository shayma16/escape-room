#!/usr/bin/env python3
"""PIL moonbeam compositor for z3 beam matrix (build-3). Cool moonlight #DCE8F2 core.
Draws a soft volumetric shaft from the ceiling shutter + a bright landing spot,
screen-blended over a base plate. No API cost."""
import os
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
def p(rel): return os.path.join(ROOT, rel)
BEAM = (220, 232, 242)

def save(im, out):
    w, h = im.size
    im.save(p(out+"@3x.png"), "PNG")
    im.resize((round(w*2/3), round(h*2/3)), Image.LANCZOS).save(p(out+"@2x.png"), "PNG")
    im.resize((round(w/3), round(h/3)), Image.LANCZOS).save(p(out+"@1x.png"), "PNG")

def shaft(size, x_top, x_bot, y_top, y_bot, wt, wb, inten=205):
    W, H = size
    layer = Image.new("L", (W, H), 0); d = ImageDraw.Draw(layer)
    steps = 60
    for i in range(steps):
        t = i/(steps-1)
        y = y_top + (y_bot-y_top)*t; x = x_top + (x_bot-x_top)*t
        hw = (wt + (wb-wt)*t)/2
        a = int(inten*(0.35+0.65*(1-t)))
        d.ellipse([x-hw, y-6, x+hw, y+6], fill=a)
    return layer.filter(ImageFilter.GaussianBlur(28))

def spot(size, cx, cy, rx, ry, inten=235):
    W, H = size
    layer = Image.new("L", (W, H), 0)
    ImageDraw.Draw(layer).ellipse([cx-rx, cy-ry, cx+rx, cy+ry], fill=inten)
    return layer.filter(ImageFilter.GaussianBlur(24))

def apply_glow(base, glow_L, color=BEAM):
    col = Image.new("RGB", base.size, color)
    glow = Image.composite(col, Image.new("RGB", base.size, (0,0,0)), glow_L)
    return ImageChops.screen(base, glow)

SRC_X, SRC_Y = 690, 150

def build():
    base = Image.open(p("z3/v-cellar/z3-cellar-base@3x.png")).convert("RGB")
    shelf_slid = Image.open(p("z3/v-cellar/z3-cellar-shelf-slid-nb@3x.png")).convert("RGB")
    W, H = base.size
    save(base.copy(), "z3/v-cellar/z3-cellar-nobeam-nb")
    g = shaft((W,H), SRC_X, 950, SRC_Y, 1520, 150, 300, 200)
    g = ImageChops.add(g, spot((W,H), 950, 1540, 260, 90, 235))
    save(apply_glow(base, g), "z3/v-cellar/z3-cellar-beam-floor-nb")
    g = shaft((W,H), SRC_X, 1000, SRC_Y, 780, 150, 240, 195)
    g = ImageChops.add(g, spot((W,H), 1360, 1020, 210, 210, 245))
    g = ImageChops.add(g, spot((W,H), 1360, 1020, 340, 320, 120))
    save(apply_glow(base, g), "z3/v-cellar/z3-cellar-beam-blocked-nb")
    g = shaft((W,H), SRC_X, 1000, SRC_Y, 780, 150, 220, 190)
    g = ImageChops.add(g, spot((W,H), 1380, 1050, 150, 240, 210))
    save(apply_glow(shelf_slid, g), "z3/v-cellar/z3-cellar-beam-alcove-nb")
    print("beam matrix built")

if __name__ == "__main__":
    build()
