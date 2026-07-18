#!/usr/bin/env python3
"""Stamp 8 crisp moon-phase silhouettes in a ring on each of the 3 dials.
Waxing lit-RIGHT, waning lit-LEFT. Unmistakable by shape+shadow (2.3 color-blind safe).
Renders to a scratch copy first for verification; --commit overwrites the substrate."""
import os, math, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
SRC = os.path.join(ROOT, "z1", "v-hearth", "cu-dial-panel-nb@3x.png")
SCRATCH = r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim-escape-room\8c048282-9ce7-4b1a-b54a-04e2ba948c25\scratchpad"

DIALS = [(455, 745, 150), (1015, 745, 150), (1580, 745, 150)]
MARK_R = 28
BRASS = (196, 168, 96)   # lit lip
PIT = (44, 38, 22)       # engraved dark

def disc_mask(S, r=None):
    if r is None: r = S/2 - 2
    m = Image.new("L", (S, S), 0)
    c = S/2
    ImageDraw.Draw(m).ellipse([c-r, c-r, c+r, c+r], fill=255)
    return m

def lit_mask(kind, S):
    """L mask, 255 = LIT (bright) portion of the moon for phase kind 0..7."""
    r = S/2 - 3; c = S/2
    full = disc_mask(S, r)
    if kind == 0:                      # new moon: no lit area -> thin rim only
        m = Image.new("L", (S, S), 0)
        ImageDraw.Draw(m).ellipse([c-r, c-r, c+r, c+r], outline=255, width=max(3, S//12))
        return m
    if kind == 4:                      # full
        return full
    if kind in (2, 6):                 # quarters: half disc
        half = Image.new("L", (S, S), 0); d = ImageDraw.Draw(half)
        if kind == 2: d.rectangle([c, 0, S, S], fill=255)   # first qtr lit RIGHT
        else:         d.rectangle([0, 0, c, S], fill=255)   # last qtr lit LEFT
        return ImageChops.multiply(full, half)
    # crescent / gibbous via a shifted carving disc
    shift = Image.new("L", (S, S), 0); sd = ImageDraw.Draw(shift)
    if kind == 1:   lit_right, off = True,  r*0.58   # wax crescent: thin lit RIGHT
    elif kind == 3: lit_right, off = True,  r*0.58   # wax gibbous: mostly lit, dark LEFT sliver
    elif kind == 7: lit_right, off = False, r*0.58   # wan crescent: thin lit LEFT
    else:           lit_right, off = False, r*0.58   # kind 5 wan gibbous: dark RIGHT sliver
    if kind in (1, 7):   # crescent: lit = disc AND shifted-disc(toward lit side)
        ox = off if lit_right else -off
        sd.ellipse([c-r+ox, c-r, c+r+ox, c+r], fill=255)
        return ImageChops.multiply(full, shift)
    else:                # gibbous: lit = disc MINUS shifted-disc(toward dark side)
        ox = -off if lit_right else off
        sd.ellipse([c-r+ox, c-r, c+r+ox, c+r], fill=255)
        return ImageChops.subtract(full, shift)

def stamp():
    base = Image.open(SRC).convert("RGB")
    for (cx, cy, R) in DIALS:
        ring_r = R*0.70
        for k in range(8):
            ang = -math.pi/2 + k*(2*math.pi/8)
            px = cx + ring_r*math.cos(ang); py = cy + ring_r*math.sin(ang)
            S = MARK_R*2 + 10
            x0, y0 = int(px-S/2), int(py-S/2)
            pit = Image.new("RGB", (S, S), PIT)
            pmask = disc_mask(S).filter(ImageFilter.GaussianBlur(0.6))
            base.paste(pit, (x0, y0), pmask)
            lm = lit_mask(k, S).filter(ImageFilter.GaussianBlur(0.5))
            base.paste(Image.new("RGB", (S, S), BRASS), (x0, y0), lm)
    return base

if __name__ == "__main__":
    out = stamp()
    commit = "--commit" in sys.argv
    if commit:
        w, h = out.size
        out.save(SRC, "PNG")
        out.resize((round(w*2/3), round(h*2/3)), Image.LANCZOS).save(SRC.replace("@3x", "@2x"), "PNG")
        out.resize((round(w/3), round(h/3)), Image.LANCZOS).save(SRC.replace("@3x", "@1x"), "PNG")
        print("COMMITTED", SRC)
    else:
        p = os.path.join(SCRATCH, "dial_preview.png"); out.save(p, "PNG")
        # also emit a grayscale + a single-dial crop for the 2.3 gate
        out.convert("L").save(os.path.join(SCRATCH, "dial_preview_GRAY.png"), "PNG")
        out.crop((305, 595, 605, 895)).save(os.path.join(SCRATCH, "dial_preview_L.png"), "PNG")
        print("preview ->", p)
