#!/usr/bin/env python3
"""Programmatic moonbeam compositor for z3 beam matrix (batch 3).
Deterministic, pixel-aligned, identical #DCE8F2 treatment on every plate.
"""
import math
import random
from PIL import Image, ImageDraw, ImageFilter, ImageChops, ImageEnhance

import progress_lib

R = "C:/Users/shaim/escape-room/specs/assets/level-1"
SCR = r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad"
BEAM = (220, 232, 242)  # DCE8F2
DONOR_RECT = (150, 10, 700, 580)


def prep_donor():
    """Fog the moon disc into glow; restamp square socket on winch hub."""
    d = Image.open(SCR + "/z3-shutter-open-donor@3x.png").convert("RGB")
    # fog the opening interior (moon disc -> haze)
    box = (248, 25, 415, 395)
    reg = d.crop(box).filter(ImageFilter.GaussianBlur(42))
    reg = ImageEnhance.Brightness(reg).enhance(1.12)
    mask = Image.new("L", (box[2]-box[0], box[3]-box[1]), 0)
    ImageDraw.Draw(mask).rounded_rectangle((10, 10, box[2]-box[0]-10, box[3]-box[1]-10), 40, fill=255)
    mask = mask.filter(ImageFilter.GaussianBlur(12))
    d.paste(reg, (box[0], box[1]), mask)
    # restamp square socket at hub (donor hub ~ (470,380))
    dr = ImageDraw.Draw(d)
    cx, cy, s = 470, 380, 15
    pts = []
    for ang in (45, 135, 225, 315):
        a = math.radians(ang + 8)
        pts.append((cx + s*1.35*math.cos(a), cy + s*1.35*math.sin(a)))
    dr.polygon(pts, fill=(16, 15, 13))
    dr.line([pts[3], pts[0]], fill=(120, 122, 118), width=2)
    d.save(SCR + "/z3-shutter-open-donor-prepped.png")
    return d


def quad(draw, p1, p2, p3, p4, fill):
    draw.polygon([p1, p2, p3, p4], fill=fill)


def beam_layer(size, segs, motes_seed=7):
    """segs: list of dicts {src:(pA,pB), dst:(pC,pD), core_alpha, halo_alpha}"""
    halo = Image.new("RGBA", size, (0, 0, 0, 0))
    core = Image.new("RGBA", size, (0, 0, 0, 0))
    dh, dc = ImageDraw.Draw(halo), ImageDraw.Draw(core)
    for s in segs:
        (a, b), (c, d2) = s["src"], s["dst"]
        quad(dh, a, b, d2, c, BEAM + (s.get("halo_alpha", 60),))
        # inset core
        def lerp(p, q, t):
            return (p[0]+(q[0]-p[0])*t, p[1]+(q[1]-p[1])*t)
        ai, bi = lerp(a, b, 0.18), lerp(b, a, 0.18)
        ci, di = lerp(c, d2, 0.18), lerp(d2, c, 0.18)
        quad(dc, ai, bi, di, ci, BEAM + (s.get("core_alpha", 55),))
    halo = halo.filter(ImageFilter.GaussianBlur(16))
    core = core.filter(ImageFilter.GaussianBlur(5))
    layer = Image.alpha_composite(halo, core)
    # dust motes inside seg bounding quads
    rng = random.Random(motes_seed)
    md = ImageDraw.Draw(layer)
    for s in segs:
        (a, b), (c, d2) = s["src"], s["dst"]
        for _ in range(s.get("motes", 160)):
            t, u = rng.random(), rng.random()
            top = (a[0]+(b[0]-a[0])*u, a[1]+(b[1]-a[1])*u)
            bot = (c[0]+(d2[0]-c[0])*u, c[1]+(d2[1]-c[1])*u)
            x, y = top[0]+(bot[0]-top[0])*t, top[1]+(bot[1]-top[1])*t
            r = rng.uniform(0.8, 3.4)
            al = rng.randint(70, 210)
            md.ellipse((x-r, y-r, x+r, y+r), fill=(240, 246, 252, al))
    return layer


def glow_ellipse(layer, center, rx, ry, alpha=200, blur=22, halo_scale=1.9, halo_alpha=70):
    g = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    cx, cy = center
    d.ellipse((cx-rx*halo_scale, cy-ry*halo_scale, cx+rx*halo_scale, cy+ry*halo_scale),
              fill=BEAM + (halo_alpha,))
    d.ellipse((cx-rx, cy-ry, cx+rx, cy+ry), fill=(238, 245, 250, alpha))
    g = g.filter(ImageFilter.GaussianBlur(blur))
    return Image.alpha_composite(layer, g)


def seam_streaks(layer, xspan, ys, alpha=90):
    g = Image.new("RGBA", layer.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(g)
    for y in ys:
        d.line((xspan[0], y, xspan[1], y), fill=BEAM + (alpha,), width=7)
    g = g.filter(ImageFilter.GaussianBlur(6))
    return Image.alpha_composite(layer, g)


def compose(base_path, out_name, segs, extras, asset, cost=0.0, note=None):
    base = Image.open(base_path).convert("RGB")
    donor = Image.open(SCR + "/z3-shutter-open-donor-prepped.png").convert("RGB")
    # half-stop darken everything, then paste lit shutter region (donor darkened less)
    dark = ImageEnhance.Brightness(base).enhance(0.74)
    x1, y1, x2, y2 = DONOR_RECT
    reg = donor.crop(DONOR_RECT)
    m = Image.new("L", (x2-x1, y2-y1), 0)
    ImageDraw.Draw(m).rectangle((16, 16, x2-x1-16, y2-y1-16), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(12))
    dark.paste(reg, (x1, y1), m)
    layer = beam_layer(dark.size, segs)
    for ex in extras:
        if ex[0] == "ellipse":
            layer = glow_ellipse(layer, *ex[1:])
        elif ex[0] == "seams":
            layer = seam_streaks(layer, *ex[1:])
    out = Image.alpha_composite(dark.convert("RGBA"), layer).convert("RGB")
    # gentle screen pass of blurred layer for atmosphere
    atm = Image.new("RGB", out.size, (0, 0, 0))
    atm.paste(Image.new("RGB", out.size, (18, 24, 30)), (0, 0))
    out = ImageChops.screen(out, atm)
    p3 = f"{R}/z3/v-cellar/{out_name}@3x.png"
    out.save(p3)
    w, h = out.size
    out.resize((round(w*2/3), round(h*2/3)), Image.LANCZOS).save(p3.replace("@3x", "@2x"))
    out.resize((round(w/3), round(h/3)), Image.LANCZOS).save(p3.replace("@3x", "@1x"))
    progress_lib.mark(asset, "done", cost, note)
    print("composed", out_name)


SRC = ((285, 115), (430, 355))            # beam source edge at shutter mouth
MIRROR_HIT = ((1365, 850), (1520, 1030))  # d3 glass
FLOOR = ((1005, 1105), (1500, 1185))      # floor ellipse edge in front of mirror


def main():
    prep_donor()
    # 9: beam at floor (shutter open, detent 1)
    compose(f"{R}/z3/v-cellar/z3-cellar-base@3x.png", "z3-cellar-beam-floor",
            [{"src": SRC, "dst": FLOOR, "motes": 220}],
            [("ellipse", (1250, 1150), 250, 64, 210, 20)],
            "z3/v-cellar/z3-cellar-beam-floor", 0.0,
            "PIL beam engine v3 (2 API takes rejected); donor shutter + DCE8F2 column")
    # 10: beam at floor + shelf slid
    compose(f"{R}/z3/v-cellar/z3-cellar-shelf-slid@3x.png", "z3-cellar-beam-floor-shelf-slid",
            [{"src": SRC, "dst": FLOOR, "motes": 220}],
            [("ellipse", (1250, 1150), 250, 64, 210, 20)],
            "z3/v-cellar/z3-cellar-beam-floor-shelf-slid", 0.0,
            "same beam geometry as beam-floor; alcove mouth open, unlit")
    # 11: beam blocked on closed shelf face (detent-3)
    compose(f"{R}/z3/v-cellar/z3-cellar-mirror-d3@3x.png", "z3-cellar-beam-blocked",
            [{"src": SRC, "dst": MIRROR_HIT, "motes": 170},
             {"src": ((1380, 880), (1500, 1010)), "dst": ((760, 600), (935, 795)),
              "motes": 130, "halo_alpha": 55, "core_alpha": 50}],
            [("ellipse", (855, 690), 120, 96, 235, 16),
             ("seams", (690, 1020), (642, 700, 756), 95)],
            "z3/v-cellar/z3-cellar-beam-blocked", 0.0,
            "R4: bright spot ON shelf face + seam bleed = 'blocked, look here'")
    # 12: beam into alcove (detent-3, shelf slid) -- composite mirror-d3 rect onto shelf-slid first
    slid = Image.open(f"{R}/z3/v-cellar/z3-cellar-shelf-slid@3x.png").convert("RGB")
    d3 = Image.open(f"{R}/z3/v-cellar/z3-cellar-mirror-d3@3x.png").convert("RGB")
    mr = (1230, 720, 1720, 1250)
    m = Image.new("L", (mr[2]-mr[0], mr[3]-mr[1]), 0)
    ImageDraw.Draw(m).rectangle((16, 16, mr[2]-mr[0]-16, mr[3]-mr[1]-16), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(12))
    slid.paste(d3.crop(mr), (mr[0], mr[1]), m)
    tmp = SCR + "/z3-slid-d3-composite.png"
    slid.save(tmp)
    compose(tmp, "z3-cellar-beam-alcove",
            [{"src": SRC, "dst": MIRROR_HIT, "motes": 170},
             {"src": ((1380, 880), (1500, 1010)), "dst": ((965, 470), (1125, 870)),
              "motes": 130, "halo_alpha": 55, "core_alpha": 50}],
            [("ellipse", (1050, 690), 95, 150, 130, 26)],
            "z3/v-cellar/z3-cellar-beam-alcove", 0.0,
            "beam redirected through alcove mouth; order-free condition plate")


if __name__ == "__main__":
    main()
