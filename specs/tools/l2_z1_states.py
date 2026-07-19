#!/usr/bin/env python3
"""Level 2 / z1 state-variant overlays (batch 2 fold-in) — deterministic PIL.

Delivery format = per-element PATCH overlays + rect JSON (matches the
Developer's build-10 per-element overlay architecture): each state is a
pixel-aligned patch against its base plate; base plates are NOT modified.

States built here (state matrix, style guide §8):
  screwdriver taken (wide) · stove tile II taken (wide+CU) · crate tile VII
  taken (wide+CU) · sill tile XI taken (wide+CU) · coat watch-A / tile-IV
  taken (CU, independent) · stair bar raised (CU12+wide) · floor cache
  pried+wheel / empty (CU11+wide echo).
Cushion states (cat-gone NB edit + reveal) are built by l2_z1_cushion.py.

Usage: python l2_z1_states.py all
"""
import json
import math
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z1 = os.path.join(A2, "z1")
S = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")
CU_W, CU_H = 2048, 1536
RNG = np.random.default_rng(20260721)
META = {}

CUS = {
    "cu-stove-hob":   ("v-bench", 2320, 1280, 3160, 1910),
    "cu-crate-straw": ("v-master", 2380, 1230, 3300, 1920),
    "cu-sill-tile":   ("v-door", 2135, 875, 2855, 1415),
    "cu-coat-pockets": ("v-bench", None, None, None, None),   # fresh camera, no wide echo
    "cu-timelock":    ("v-door", 620, 420, 1820, 1320),
    "cu-floor-cache": ("v-door", 1900, 1140, 2940, 1920),
}
WIDE_OF = {"v-bench": "z1-bench-base", "v-master": "z1-master-base",
           "v-door": "z1-door-base"}


def cu_path(name):
    return os.path.join(Z1, CUS[name][0], name + "@3x.png")


def load_cu(name):
    return Image.open(cu_path(name)).convert("RGB")


def grid_fill(im, mask, cell=24, blur=14, noise=2.0):
    """Fill mask area with a smooth field fitted from unmasked pixels."""
    a = np.asarray(im, np.float32)
    h, w = a.shape[:2]
    keep = ~np.asarray(mask, bool)
    gh, gw = h // cell + 1, w // cell + 1
    grid = np.full((gh, gw, 3), np.nan, np.float32)
    for gy in range(gh):
        for gx in range(gw):
            sl = np.s_[gy*cell:(gy+1)*cell, gx*cell:(gx+1)*cell]
            m = keep[sl]
            if m.sum() >= 30:
                grid[gy, gx] = np.median(a[sl][m], axis=0)
    for _ in range(120):
        nanm = np.isnan(grid[..., 0])
        if not nanm.any():
            break
        pad = np.pad(grid, ((1, 1), (1, 1), (0, 0)), constant_values=np.nan)
        st = np.stack([pad[1:-1, :-2], pad[1:-1, 2:], pad[:-2, 1:-1], pad[2:, 1:-1]])
        with np.errstate(all="ignore"):
            nb = np.nanmean(st, axis=0)
        grid[nanm] = nb[nanm]
    field = np.asarray(Image.fromarray(grid.astype(np.uint8), "RGB")
                       .resize((w, h), Image.BILINEAR)
                       .filter(ImageFilter.GaussianBlur(blur)), np.float32)
    field += RNG.normal(0, noise, field.shape)
    out = a.copy()
    mm = np.asarray(mask, np.float32)[..., None] / 255.0
    out = out * (1 - mm) + np.clip(field, 0, 255) * mm
    return Image.fromarray(out.astype(np.uint8), "RGB")


def poly_mask(size, polys, feather=8):
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    for p in polys:
        d.polygon(p, fill=255)
    return m.filter(ImageFilter.GaussianBlur(feather))


def clone(im, src_box, dst_xy, feather=8):
    patch = im.crop(src_box)
    m = Image.new("L", patch.size, 0)
    ImageDraw.Draw(m).rectangle([feather, feather, patch.width - feather,
                                 patch.height - feather], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(feather))
    base = im.convert("RGBA")
    p = patch.convert("RGBA")
    p.putalpha(m)
    base.alpha_composite(p, dst_xy)
    return base.convert("RGB")


def save_patch(state_name, view, base_stem, img, bbox, wide_frame=None, note=""):
    """Save CU patch + optional wide echo patch + register in META."""
    outd = os.path.join(Z1, view, "states")
    os.makedirs(outd, exist_ok=True)
    patch = img.crop(bbox)
    patch.save(os.path.join(outd, state_name + "@3x.png"))
    rec = {"base": base_stem, "rect_3x": list(bbox), "note": note}
    if wide_frame:
        x0, y0, x1, y1 = wide_frame
        s = (x1 - x0) / CU_W
        wb = [round(x0 + bbox[0] * s), round(y0 + bbox[1] * s),
              round(x0 + bbox[2] * s), round(y0 + bbox[3] * s)]
        wb[3] = min(wb[3], 1920)
        wpatch = patch.resize((wb[2] - wb[0], wb[3] - wb[1]), Image.LANCZOS)
        wpatch.save(os.path.join(outd, state_name + "-wide@3x.png"))
        rec["wide_base"] = WIDE_OF[view]
        rec["wide_rect_3x"] = wb
    META[state_name] = rec
    print("state", state_name)
    return patch


# ------------------------------------------------------------------- states

def screwdriver_taken():
    """Wide-space removal: rail clone + wall grid-fill (v-bench)."""
    wp = os.path.join(Z1, "v-bench", "z1-bench-base@3x.png")
    im = Image.open(wp).convert("RGB")
    reg = im.crop((960, 420, 1360, 1120))     # working region, wide coords
    # rail band clone over the handle top (rail y 95..205 in region coords)
    reg = clone(reg, (178, 88, 248, 208), (85, 88), feather=6)
    reg = clone(reg, (178, 88, 248, 208), (128, 88), feather=6)
    # wall + shadow: grid-fill over screwdriver + its cast shadow
    m = poly_mask(reg.size, [[(88, 205), (185, 205), (185, 660), (88, 660)],
                             [(48, 330), (95, 360), (95, 670), (48, 670)]], 6)
    reg = grid_fill(reg, m, cell=22, blur=10)
    out = im.copy()
    out.paste(reg, (960, 420))
    outd = os.path.join(Z1, "v-bench", "states")
    os.makedirs(outd, exist_ok=True)
    patch = out.crop((980, 440, 1340, 1110))
    patch.save(os.path.join(outd, "ov-screwdriver-taken-wide@3x.png"))
    META["ov-screwdriver-taken"] = {"wide_base": "z1-bench-base",
                                    "wide_rect_3x": [980, 440, 1340, 1110],
                                    "note": "rack empty after pickup; no CU hosts this region"}
    print("state ov-screwdriver-taken")


def stove_tile_taken():
    im = load_cu("cu-stove-hob")
    m = poly_mask(im.size, [[(700, 470), (1140, 365), (1650, 460), (1600, 540),
                             (1280, 700), (790, 685)]], 12)
    out = grid_fill(im, m, cell=22, blur=10)
    save_patch("ov-stove-tile-taken", "v-bench", "cu-stove-hob", out,
               (640, 310, 1720, 760), CUS["cu-stove-hob"][1:],
               "tile II removed from the cold hob")


def crate_tile_taken():
    im = load_cu("cu-crate-straw")
    out = im.convert("RGBA")

    def blob(src_box, dst_xy, seed):
        patch = im.crop(src_box)
        m = Image.new("L", patch.size, 0)
        bd = ImageDraw.Draw(m)
        rng = np.random.default_rng(seed)
        cx_, cy_ = patch.width / 2, patch.height / 2
        pts = []
        for i in range(26):
            ang = i / 26 * 2 * math.pi
            rr = 0.60 + 0.36 * rng.random()
            pts.append((cx_ + cx_ * rr * math.cos(ang) * 0.94,
                        cy_ + cy_ * rr * math.sin(ang) * 0.94))
        bd.polygon(pts, fill=255)
        m = m.filter(ImageFilter.GaussianBlur(12))
        pp = patch.convert("RGBA")
        pp.putalpha(m)
        out.alpha_composite(pp, dst_xy)

    blob((1250, 1030, 1600, 1330), (770, 1000), 1)
    blob((380, 930, 740, 1200), (860, 1110), 2)
    blob((1240, 1110, 1560, 1340), (900, 1080), 3)
    blob((420, 1000, 700, 1220), (790, 1160), 4)
    out = out.convert("RGB")
    save_patch("ov-crate-tile-taken", "v-master", "cu-crate-straw", out,
               (770, 1000, 1290, 1340), CUS["cu-crate-straw"][1:],
               "tile VII taken; straw closed over")


def sill_tile_taken():
    im = load_cu("cu-sill-tile")
    patch = im.crop((1215, 265, 1795, 845)).transpose(Image.FLIP_LEFT_RIGHT)
    parr = np.asarray(patch, np.float32) * 0.97    # settle the glow a touch
    patch = Image.fromarray(parr.clip(0, 255).astype(np.uint8), "RGB")
    m = Image.new("L", patch.size, 0)
    ImageDraw.Draw(m).rectangle([18, 18, patch.width - 18, patch.height - 18], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(14))
    outr = im.convert("RGBA")
    pp = patch.convert("RGBA")
    pp.putalpha(m)
    outr.alpha_composite(pp, (680, 265))
    out = outr.convert("RGB")
    save_patch("ov-sill-tile-taken", "v-door", "cu-sill-tile", out,
               (670, 255, 1270, 855), CUS["cu-sill-tile"][1:],
               "tile XI taken off the dormer sill")


def coat_states():
    im = load_cu("cu-coat-pockets")
    # --- tile IV taken: wool blob over the tile above the rim, pocket-front
    #     band below, rim line redrawn (pocket itself stays) ---
    tr = im.convert("RGBA")
    wool = im.crop((500, 890, 920, 1200))          # clean coat wool below pocket
    mw = Image.new("L", wool.size, 0)
    dw = ImageDraw.Draw(mw)
    dw.polygon([(18, 30), (200, 10), (395, 26), (410, 160), (398, 292),
                (170, 300), (14, 270), (6, 120)], fill=255)
    mw = mw.filter(ImageFilter.GaussianBlur(12))
    wp = wool.convert("RGBA")
    wp.putalpha(mw)
    tr.alpha_composite(wp, (455, 455))             # covers tile y 455..755
    wp2 = wool.convert("RGBA")
    wp2.putalpha(mw)
    tr.alpha_composite(wp2, (470, 540))            # second pass: bottom rim glow
    # pocket-front band behind the tile bottom
    band = im.crop((860, 745, 1010, 870)).resize((480, 125), Image.LANCZOS)
    mb = Image.new("L", band.size, 0)
    ImageDraw.Draw(mb).rectangle([12, 12, 468, 113], fill=255)
    mb = mb.filter(ImageFilter.GaussianBlur(12))
    bp = band.convert("RGBA")
    bp.putalpha(mb)
    tr.alpha_composite(bp, (470, 742))
    # soft bounded rim stroke (curved, fades at both ends)
    rim = Image.new("RGBA", tr.size, (0, 0, 0, 0))
    rd = ImageDraw.Draw(rim)
    pts = [(525, 791), (620, 782), (720, 770), (820, 758), (900, 750)]
    rd.line(pts, fill=(34, 28, 23, 190), width=5, joint="curve")
    rd.line([(px, py - 6) for px, py in pts], fill=(92, 82, 70, 110), width=2,
            joint="curve")
    rim = rim.filter(ImageFilter.GaussianBlur(1.4))
    fade = Image.new("L", tr.size, 255)
    fd = ImageDraw.Draw(fade)
    fd.rectangle([0, 0, 540, 1536], fill=0)
    fd.rectangle([890, 0, 2048, 1536], fill=0)
    fade = fade.filter(ImageFilter.GaussianBlur(30))
    r_, g_, b_, a_ = rim.split()
    from PIL import ImageChops
    rim.putalpha(ImageChops.multiply(a_, fade))
    tr.alpha_composite(rim)
    t = tr.convert("RGB")
    save_patch("ov-coat-tile-taken", "v-bench", "cu-coat-pockets", t,
               (465, 455, 950, 860), None, "tile IV gone from left pocket")
    # --- watch A taken: flap bottom + slot + pocket front reconstruction ---
    w = im.convert("RGBA")

    def stretch_clone(base, src_box, dst_box, feather=12):
        patch = im.crop(src_box).resize((dst_box[2] - dst_box[0],
                                         dst_box[3] - dst_box[1]), Image.LANCZOS)
        m = Image.new("L", patch.size, 0)
        ImageDraw.Draw(m).rectangle([feather, feather, patch.width - feather,
                                     patch.height - feather], fill=255)
        m = m.filter(ImageFilter.GaussianBlur(feather))
        pp = patch.convert("RGBA")
        pp.putalpha(m)
        base.alpha_composite(pp, (dst_box[0], dst_box[1]))

    stretch_clone(w, (1044, 400, 1140, 600), (1090, 400, 1540, 600))
    stretch_clone(w, (1040, 560, 1130, 660), (1090, 555, 1530, 665))
    stretch_clone(w, (990, 640, 1130, 960), (1100, 640, 1290, 960))
    stretch_clone(w, (990, 640, 1130, 960), (1270, 645, 1450, 960))
    stretch_clone(w, (990, 640, 1130, 960), (1400, 650, 1540, 960))
    w = w.convert("RGB")
    save_patch("ov-coat-watch-taken", "v-bench", "cu-coat-pockets", w,
               (1060, 380, 1560, 980), None, "watch A + chain gone from right pocket")


def timelock_raised():
    im = load_cu("cu-timelock")
    a = im.copy()
    # bar layer: horizontal bar region minus the two fixed guide straps
    bar = im.crop((170, 880, 1600, 1170)).convert("RGBA")
    balpha = Image.new("L", bar.size, 255)
    bd = ImageDraw.Draw(balpha)
    bd.rectangle([444 - 170, 0, 516 - 170, bar.height], fill=0)
    bd.rectangle([1224 - 170, 0, 1296 - 170, bar.height], fill=0)
    balpha = balpha.filter(ImageFilter.GaussianBlur(2))
    bar.putalpha(balpha)
    # fill exposed: door planks (vertical grain -> vertical shift keeps seams)
    planks = im.crop((170, 330, 1600, 620)).resize((1430, 300), Image.LANCZOS)
    out = a.convert("RGBA")
    mp = Image.new("L", planks.size, 0)
    ImageDraw.Draw(mp).rectangle([6, 6, planks.width - 6, planks.height - 6], fill=255)
    mp = mp.filter(ImageFilter.GaussianBlur(6))
    pp = planks.convert("RGBA"); pp.putalpha(mp)
    out.alpha_composite(pp, (170, 875))
    # housing plate region refill (bar crossed IN FRONT of the plate)
    hs = im.crop((810, 820, 1140, 878)).resize((330, 360), Image.LANCZOS)
    mh = Image.new("L", hs.size, 0)
    ImageDraw.Draw(mh).rectangle([6, 6, 324, 354], fill=255)
    mh = mh.filter(ImageFilter.GaussianBlur(6))
    hp = hs.convert("RGBA"); hp.putalpha(mh)
    out.alpha_composite(hp, (810, 862))
    # raised bar: pivot at the right rod block, lifted 9 deg (padded canvas
    # so the risen left end is not clipped)
    PAD = 300
    canvas = Image.new("RGBA", (bar.width, bar.height + PAD), (0, 0, 0, 0))
    canvas.alpha_composite(bar, (0, PAD))
    rb = canvas.rotate(9, center=(1670 - 170, 1030 - 880 + PAD), expand=False,
                       resample=Image.BICUBIC)
    sh = Image.new("RGBA", rb.size, (0, 0, 0, 0))
    sh.putalpha(rb.split()[3].point(lambda v: v * 60 // 255))
    sh = sh.filter(ImageFilter.GaussianBlur(8))
    out.alpha_composite(sh, (170 + 6, 880 - PAD + 10))
    out.alpha_composite(rb, (170, 880 - PAD))
    # fixed guide straps back on top
    for x0, x1 in ((438, 522), (1218, 1302)):
        strap = im.crop((x0, 790, x1, 1250)).convert("RGBA")
        msk = Image.new("L", strap.size, 255)
        msk = msk.filter(ImageFilter.GaussianBlur(2))
        strap.putalpha(msk)
        out.alpha_composite(strap, (x0, 790))
    out = out.convert("RGB")
    save_patch("ov-bar-raised", "v-door", "cu-timelock", out,
               (100, 480, 1720, 1260), CUS["cu-timelock"][1:],
               "time-lock bar pivoted up on its rod crank; cradles empty")


def floor_cache():
    im = load_cu("cu-floor-cache")
    # cavity parallelogram on the cache board (seams measured)
    A_, B_, C_, D_ = (1146, 1240), (1330, 1240), (1395, 1500), (1205, 1500)
    board = im.crop((1120, 1225, 1420, 1515))     # board surface for the pried plank
    out = im.convert("RGBA")
    # cavity: dark interior + side-wall hints
    cav = Image.new("RGBA", im.size, (0, 0, 0, 0))
    cd = ImageDraw.Draw(cav)
    cd.polygon([A_, B_, C_, D_], fill=(26, 18, 11, 255))
    # inner left wall catch-light + front lip
    cd.line([A_, D_], fill=(84, 62, 40, 255), width=7)
    cd.line([(A_[0] + 4, A_[1] + 3), (B_[0] - 4, B_[1] + 3)], fill=(10, 7, 4, 255), width=6)
    cd.line([D_, C_], fill=(96, 74, 48, 255), width=5)
    cav = cav.filter(ImageFilter.GaussianBlur(1.5))
    out.alpha_composite(cav)
    # gradient: deeper darkness toward top of cavity
    gr = Image.new("RGBA", im.size, (0, 0, 0, 0))
    gd = ImageDraw.Draw(gr)
    for i in range(90):
        t = i / 90
        y = int(A_[1] + 6 + t * 110)
        gd.line([(A_[0] + 6 + t * 20, y), (B_[0] - 6 + t * 22, y)],
                fill=(0, 0, 0, int(120 * (1 - t))))
    gr = gr.filter(ImageFilter.GaussianBlur(6))
    out.alpha_composite(gr)
    # pried board lying askew across the neighbor board
    pbr = board.convert("RGBA").rotate(9, expand=True, resample=Image.BICUBIC)
    shb = Image.new("RGBA", pbr.size, (0, 0, 0, 0))
    shb.putalpha(pbr.split()[3].point(lambda v: v * 70 // 255))
    shb = shb.filter(ImageFilter.GaussianBlur(9))
    out.alpha_composite(shb, (1445, 1268))
    out.alpha_composite(pbr, (1436, 1256))
    empty = out.convert("RGB")
    # wheel lying inside (pried state): great wheel, perspective squash, dim
    wheel = Image.open(os.path.join(Z1, "icons", "inv-great-wheel@3x.png")).convert("RGBA")
    wheel = wheel.resize((250, 145), Image.LANCZOS)
    warr = np.asarray(wheel, np.float32)
    warr[..., :3] *= 0.62      # cavity shade
    wheel = Image.fromarray(warr.clip(0, 255).astype(np.uint8), "RGBA")
    pried = empty.convert("RGBA")
    pried.alpha_composite(wheel, (1152, 1300))
    pried = pried.convert("RGB")
    save_patch("ov-cache-pried-wheel", "v-door", "cu-floor-cache", pried,
               (1080, 1180, 1750, 1536), CUS["cu-floor-cache"][1:],
               "cache board pried; great wheel visible in cavity")
    save_patch("ov-cache-empty", "v-door", "cu-floor-cache", empty,
               (1080, 1180, 1750, 1536), CUS["cu-floor-cache"][1:],
               "cache open + empty after wheel taken")


def montage():
    outd = os.path.join(Z1, "states-review")
    tiles = []
    for view in ("v-bench", "v-master", "v-door"):
        sd = os.path.join(Z1, view, "states")
        if not os.path.isdir(sd):
            continue
        for f in sorted(os.listdir(sd)):
            if f.endswith("@3x.png") and ("-wide" not in f or f.startswith("ov-screwdriver")):
                tiles.append((f.replace("@3x.png", ""),
                              Image.open(os.path.join(sd, f))))
    cols = 4
    rows = (len(tiles) + cols - 1) // cols
    TH = 340
    sheet = Image.new("RGB", (cols * 480, rows * (TH + 30)), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    for i, (label, im) in enumerate(tiles):
        s = min(460 / im.width, TH / im.height)
        t = im.resize((int(im.width * s), int(im.height * s)))
        x = (i % cols) * 480 + 10
        y = (i // cols) * (TH + 30) + 10
        sheet.paste(t.convert("RGB"), (x, y))
        dd.text((x + 2, y + TH + 4), label, fill=(230, 225, 210))
    sheet.save(os.path.join(S, "states-montage.png"))
    print("montage", sheet.size)


def main():
    screwdriver_taken()
    stove_tile_taken()
    crate_tile_taken()
    sill_tile_taken()
    coat_states()
    timelock_raised()
    floor_cache()
    # merge META with the dial-seat overlay json if present
    seat_json = os.path.join(Z1, "v-master", "states", "dial-seat-overlays.json")
    if os.path.exists(seat_json):
        with open(seat_json) as f:
            META.update(json.load(f))
    with open(os.path.join(Z1, "z1-state-overlays.json"), "w") as f:
        json.dump(META, f, indent=1)
    montage()


if __name__ == "__main__":
    main()
