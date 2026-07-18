#!/usr/bin/env python3
"""Stamp the canonical crescent hallmark (crescent-hallmark.json: outer circle minus
inner circle offset +0.38R on x, horns pointing RIGHT) into a target region as an
engraved mark (dark pit + lower-right lip highlight). Preview by default; --commit."""
import os, sys
from PIL import Image, ImageDraw, ImageFilter, ImageChops

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
SCRATCH = r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim-escape-room\8c048282-9ce7-4b1a-b54a-04e2ba948c25\scratchpad"

def crescent_mask(S):
    """L mask, 255 = crescent body. Outer R=0.42*S, inner r=0.90R offset +0.38R x
    (subtract shifted disc toward the RIGHT so opening faces right / horns point right)."""
    m = Image.new("L", (S, S), 0)
    R = 0.42 * S
    cx = cy = S / 2
    outer = Image.new("L", (S, S), 0)
    ImageDraw.Draw(outer).ellipse([cx-R, cy-R, cx+R, cy+R], fill=255)
    r = 0.90 * R
    ox = cx + 0.38 * R
    inner = Image.new("L", (S, S), 0)
    ImageDraw.Draw(inner).ellipse([ox-r, cy-r, ox+r, cy+r], fill=255)
    return ImageChops.subtract(outer, inner)

def stamp(src, cx, cy, size, squash=1.0, commit=False):
    im = Image.open(src).convert("RGB")
    S = size
    cm = crescent_mask(S)
    # engraved: dark pit under the crescent + a lower-right bright lip
    pit = Image.new("RGB", (S, S), (150, 145, 150))  # slightly darker silver
    dark = ImageChops.multiply(Image.new("RGB", (S, S), (110, 108, 116)), Image.new("RGB",(S,S),(255,255,255)))
    layer = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    # pit tone
    pitrgba = Image.new("RGBA", (S, S), (120, 118, 126, 255))
    layer = Image.composite(pitrgba, layer, cm)
    # lip highlight: shift crescent mask down-right and take the difference as a bright edge
    lip = ImageChops.subtract(cm, cm.transform(cm.size, Image.AFFINE, (1,0,-3,0,1,-3)))
    hi = Image.new("RGBA", (S, S), (232, 230, 236, 255))
    layer = Image.composite(hi, layer, lip.filter(ImageFilter.GaussianBlur(0.6)))
    # squash vertically for the bowl foreshortening
    if squash != 1.0:
        layer = layer.resize((S, int(S*squash)), Image.LANCZOS)
    layer = layer.filter(ImageFilter.GaussianBlur(0.4))
    lw, lh = layer.size
    im.paste(layer, (int(cx-lw/2), int(cy-lh/2)), layer)
    if commit:
        w, h = im.size
        im.save(src, "PNG")
        im.resize((round(w*2/3), round(h*2/3)), Image.LANCZOS).save(src.replace("@3x", "@2x"), "PNG")
        im.resize((round(w/3), round(h/3)), Image.LANCZOS).save(src.replace("@3x", "@1x"), "PNG")
        print("COMMITTED", src)
    else:
        p = os.path.join(SCRATCH, "crescent_preview.png")
        im.crop((int(cx-260), int(cy-220), int(cx+260), int(cy+220))).save(p, "PNG")
        print("preview ->", p)
    return im

if __name__ == "__main__":
    # argv: src cx cy size squash [--commit]
    src, cx, cy, size, squash = sys.argv[1], float(sys.argv[2]), float(sys.argv[3]), int(sys.argv[4]), float(sys.argv[5])
    stamp(src, cx, cy, size, squash, "--commit" in sys.argv)
