#!/usr/bin/env python3
"""z1 door-dial fix (user step-10 verdict 2026-07-19) — deterministic PIL, $0.

Defects fixed on cu-door-dial (and propagated to z1-master-base wide +
cu-master-face / cu-crate-straw patches):
  1. Stamped numerals bled OUTSIDE the brass tile faces; tiles (donor crops)
     were misregistered against their sockets (tile + stray hole both visible
     per position); stray original NB holes at off-canon positions.
  2. Tray read as "a fallen bracket": upright plank artifact in the interior;
     the VI decoy leaned over the back rail.

Fix: rebuild the whole socket annulus deterministically —
  - clean face field re-fit from face-like pixels (grid median + fill + blur,
    vertical grain restored), annulus r in [162, 367] repainted;
  - 12 square recessed seats at the canonical clock positions (light from
    upper-left: inner shadow top/left, catch-light bottom inner lip);
  - 8 seated tiles = the canonical cast tile (masters/glyphs/tile-blank.png,
    same die as the inventory tiles) at I/III/V/VI/VIII/IX/X/XII, canonical
    numeral stamps CONTAINED in the face (target_h 44, max_w 66 on a 92 tile);
  - gaps exactly at 2/4/7/11 (empty recesses);
  - tray interior repainted (artifact removed), VI decoy re-laid FLAT in the
    tray (canonical tile squashed for foreshortening) — decoy KEPT per user.

Also exports the 4 per-socket seated-state overlays (II/IV/VII/XI at 2/4/7/11)
for the state matrix, from the SAME renderer (identical-die rule).

Usage: python l2_dialfix.py <preview|apply|overlays>
"""
import math
import os
import shutil
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_glyphs import render_numeral, tint

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z1 = os.path.join(A2, "z1")
REJ = os.path.join(A2, "_rejects")
SCR = os.environ.get("L2_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad")
CU_W, CU_H = 2048, 1536
OCX, OCY, FACE_R, RING_R = 994.0, 557.0, 373.5, 265.0
SEATED = {1: "I", 3: "III", 5: "V", 6: "VI", 8: "VIII", 9: "IX", 10: "X", 12: "XII"}
EMPTY = [2, 4, 7, 11]
GAP_NUM = {2: "II", 4: "IV", 7: "VII", 11: "XI"}
REC_S, TILE_S = 100, 92          # recess side / tile side (px, CU space)
DIAL_PATH = os.path.join(Z1, "v-master", "cu-door-dial@3x.png")
WIDE_PATH = os.path.join(Z1, "v-master", "z1-master-base@3x.png")
MFACE_PATH = os.path.join(Z1, "v-master", "cu-master-face@3x.png")
CRATE_PATH = os.path.join(Z1, "v-master", "cu-crate-straw@3x.png")
DIAL_FRAME = (1900, 420, 3260, 1440)     # cu-door-dial frame in wide @3x
MFACE_FRAME = (540, 320, 2500, 1790)
CRATE_FRAME = (2380, 1230, 3300, 1920)
RNG = np.random.default_rng(20260719)


def clockpos(k, r=RING_R):
    a = math.radians(k * 30 - 90)
    return OCX + r * math.cos(a), OCY + r * math.sin(a)


def tile_blank(side):
    t = Image.open(os.path.join(A2, "masters", "glyphs", "tile-blank.png"))
    t = t.crop((10, 10, t.width - 10, t.height - 10))   # shave keying junk
    return t.resize((side, side), Image.LANCZOS)


def engrave(base, stamp, cx, cy, target_h, max_w, squeeze_y=1.0, rot=0.0,
            ink=(74, 50, 22), hi=(255, 236, 178), ink_a=225, hi_a=110, depth=3):
    w, h = stamp.size
    s = target_h / h
    if w * s > max_w:
        s = max_w / w
    st = stamp.resize((max(1, round(w * s)), max(1, round(h * s * squeeze_y))),
                      Image.LANCZOS)
    if rot:
        st = st.rotate(rot, expand=True, resample=Image.BICUBIC)
    a = st.split()[3]
    for col, alp, dx, dy in ((hi, hi_a, depth, depth), (ink, ink_a, 0, 0)):
        layer = Image.new("RGBA", st.size, col + (0,))
        layer.putalpha(a.point(lambda v, m=alp: v * m // 255))
        base.alpha_composite(layer, (round(cx - st.width / 2 + dx),
                                     round(cy - st.height / 2 + dy)))


# ---------------------------------------------------------------- face field

def face_field(cu):
    """Smooth lighting field of the pale dial face, robust to marks."""
    a = np.asarray(cu.convert("RGB"), np.float32)
    R, G, B = a[..., 0], a[..., 1], a[..., 2]
    yy, xx = np.mgrid[0:CU_H, 0:CU_W]
    rr = np.sqrt((xx - OCX) ** 2 + (yy - OCY) ** 2)
    facelike = ((R > 140) & (B > 90) & ((R - B) > 15) & ((R - B) < 80)
                & (np.abs(R - G) < 70) & (rr < FACE_R - 4))
    # exclude everything near mark positions (tiles/holes/numerals/smears)
    for k in range(1, 13):
        px, py = clockpos(k)
        facelike &= ((xx - px) ** 2 + (yy - py) ** 2) > 92 ** 2
    facelike &= ((xx - 1195) ** 2 + (yy - 360) ** 2) > 70 ** 2   # stray NB hole
    C = 32
    gh, gw = CU_H // C, CU_W // C
    grid = np.full((gh, gw, 3), np.nan, np.float32)
    for gy in range(gh):
        for gx in range(gw):
            m = facelike[gy * C:(gy + 1) * C, gx * C:(gx + 1) * C]
            if m.sum() >= 40:
                cell = a[gy * C:(gy + 1) * C, gx * C:(gx + 1) * C][m]
                grid[gy, gx] = np.median(cell, axis=0)
    # iterative neighbor fill
    for _ in range(80):
        nanm = np.isnan(grid[..., 0])
        if not nanm.any():
            break
        pad = np.pad(grid, ((1, 1), (1, 1), (0, 0)), constant_values=np.nan)
        stack = np.stack([pad[1:-1, :-2], pad[1:-1, 2:], pad[:-2, 1:-1],
                          pad[2:, 1:-1]])
        with np.errstate(all="ignore"):
            nb = np.nanmean(stack, axis=0)
        grid[nanm] = nb[nanm]
    field = np.asarray(Image.fromarray(grid.astype(np.uint8), "RGB")
                       .resize((CU_W, CU_H), Image.BILINEAR)
                       .filter(ImageFilter.GaussianBlur(18)), np.float32)
    # vertical wood grain + fine noise
    col_noise = np.convolve(RNG.normal(0, 1, CU_W + 12), np.ones(7) / 7, "same")[:CU_W]
    field += (col_noise * 3.2)[None, :, None]
    field += RNG.normal(0, 1.6, field.shape)
    return np.clip(field, 0, 255).astype(np.uint8)


def annulus_mask(r1=367, feather=6):
    """Full-face repaint mask (center seam otherwise shows against the
    rebuilt annulus); hub knob is redrawn deterministically after."""
    m = Image.new("L", (CU_W, CU_H), 0)
    d = ImageDraw.Draw(m)
    d.ellipse([OCX - r1, OCY - r1, OCX + r1, OCY + r1], fill=255)
    return m.filter(ImageFilter.GaussianBlur(feather))


def draw_hub(im):
    """Brass center pivot knob at the TRUE ring center (the old knob sat
    off-center of the socket ring; re-centered for the clean-register read)."""
    d = ImageDraw.Draw(im)
    r = 15
    sh = Image.new("RGBA", (2 * r + 18, 2 * r + 18), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([6, 8, 6 + 2 * r + 4, 8 + 2 * r + 2],
                               fill=(30, 18, 8, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(4))
    im.alpha_composite(sh, (int(OCX) - r - 6, int(OCY) - r - 4))
    for rr, col in ((r, (94, 72, 42, 255)), (r - 2, (150, 118, 68, 255)),
                    (r - 5, (176, 142, 86, 255))):
        d.ellipse([OCX - rr, OCY - rr, OCX + rr, OCY + rr], fill=col)
    d.ellipse([OCX - r + 3, OCY - r + 3, OCX - r + 9, OCY - r + 9],
              fill=(235, 210, 160, 200))


# ------------------------------------------------------------------- sockets

def draw_socket(im, k, numeral=None, field=None):
    """Recessed square seat at position k; if numeral, seat the canonical tile
    with that numeral engraved. im = RGBA CU-space canvas."""
    px, py = clockpos(k)
    if field is not None:
        base_c = field[int(py) % CU_H, int(px) % CU_W].astype(np.float32)
    else:
        base_c = np.array([205, 185, 155], np.float32)
    h = REC_S // 2
    x0, y0, x1, y1 = px - h, py - h, px + h, py + h
    # engraved chamfer: highlight below-right, dark outline
    d = ImageDraw.Draw(im)
    d.rounded_rectangle([x0 + 2, y0 + 2, x1 + 2, y1 + 2], 16,
                        outline=(250, 235, 205, 90), width=2)
    # recess floor: vertical gradient of darkened face color + noise
    floor = np.zeros((REC_S, REC_S, 3), np.float32)
    for r_ in range(REC_S):
        t = r_ / REC_S
        floor[r_, :] = base_c * (0.42 + 0.22 * t)
    floor += RNG.normal(0, 2.5, floor.shape)
    fim = Image.fromarray(np.clip(floor, 0, 255).astype(np.uint8), "RGB")
    fmask = Image.new("L", (REC_S, REC_S), 0)
    ImageDraw.Draw(fmask).rounded_rectangle([0, 0, REC_S - 1, REC_S - 1], 16, fill=255)
    fr = fim.convert("RGBA")
    fr.putalpha(fmask)
    im.alpha_composite(fr, (round(x0), round(y0)))
    d.rounded_rectangle([x0, y0, x1, y1], 16, outline=(58, 44, 30, 210), width=3)
    # inner shadow (top/left) + catch-light on the bottom inner lip
    sh = Image.new("RGBA", (REC_S, REC_S), (0, 0, 0, 0))
    sd = ImageDraw.Draw(sh)
    for i in range(26):
        alpha = int(95 * (1 - i / 26) ** 1.5)
        sd.line([(3, 3 + i), (REC_S - 4, 3 + i)], fill=(20, 12, 6, alpha))
    for i in range(16):
        alpha = int(60 * (1 - i / 16) ** 1.5)
        sd.line([(3 + i, 3), (3 + i, REC_S - 4)], fill=(20, 12, 6, alpha))
    sh.putalpha(Image.composite(sh.split()[3], Image.new("L", sh.size, 0), fmask))
    im.alpha_composite(sh, (round(x0), round(y0)))
    d.line([(x0 + 12, y1 - 3), (x1 - 12, y1 - 3)], fill=(255, 240, 210, 100), width=2)
    if numeral is None:
        return
    # seated canonical tile, centered, numeral contained in the face
    t = tile_blank(TILE_S)
    im.alpha_composite(t, (round(px - TILE_S / 2), round(py - TILE_S / 2)))
    st = tint(render_numeral(numeral, 400), (255, 255, 255, 255))
    engrave(im, st, px, py, target_h=44, max_w=66)


def build_fixed(cu):
    """Return the fixed cu-door-dial (RGB) + the bare overlay used."""
    field = face_field(cu)
    out = cu.convert("RGBA")
    # 1) repaint the annulus with the clean field
    fim = Image.fromarray(field, "RGB").convert("RGBA")
    fim.putalpha(annulus_mask())
    out.alpha_composite(fim)
    draw_hub(out)
    # 2) sockets: empty at 2/4/7/11, seated elsewhere
    lay = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
    for k in range(1, 13):
        draw_socket(lay, k, SEATED.get(k), field)
    out.alpha_composite(lay)
    # 3) tray fix
    fix_tray(out)
    return out.convert("RGB")


# ---------------------------------------------------------------------- tray

def fix_tray(out):
    """Remove the upright plank artifact + the rail-straddling decoy; repaint;
    lay the VI decoy FLAT in the tray (canonical tile, foreshortened)."""
    rgb = out.convert("RGB")
    # a) plank artifact at ~(785,1175)-(825,1230): clone interior from right
    src = rgb.crop((860, 1150, 960, 1240))
    m = Image.new("L", src.size, 0)
    ImageDraw.Draw(m).rectangle([6, 6, src.width - 6, src.height - 6], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(4))
    p = src.convert("RGBA"); p.putalpha(m)
    out.alpha_composite(p, (760, 1150))
    # b) old leaning VI decoy at ~(1080,1140)-(1180,1235): clone the clean
    #    rail+interior structure from just right of it (rail edge slopes ~+6px
    #    per 105px -> source shifted up 6)
    src = rgb.crop((1185, 1124, 1330, 1250))
    m = Image.new("L", src.size, 0)
    ImageDraw.Draw(m).rectangle([7, 7, src.width - 7, src.height - 7], fill=255)
    m = m.filter(ImageFilter.GaussianBlur(5))
    p = src.convert("RGBA"); p.putalpha(m)
    out.alpha_composite(p, (1063, 1130))
    # c) new decoy: canonical tile lying flat, foreshortened, slight rotation
    t = tile_blank(112)
    st = tint(render_numeral("VI", 400), (255, 255, 255, 255))
    engrave(t, st, 56, 56, target_h=54, max_w=76, ink=(74, 50, 22),
            hi=(255, 236, 178), depth=3)
    t = t.resize((112, 42), Image.LANCZOS).rotate(-5, expand=True,
                                                  resample=Image.BICUBIC)
    cxy = (1120, 1204)
    # contact shadow
    sh = Image.new("RGBA", (t.width + 20, t.height + 20), (0, 0, 0, 0))
    ImageDraw.Draw(sh).ellipse([6, 10, t.width + 12, t.height + 16],
                               fill=(25, 14, 6, 90))
    sh = sh.filter(ImageFilter.GaussianBlur(5))
    out.alpha_composite(sh, (cxy[0] - t.width // 2 - 6, cxy[1] - t.height // 2 - 2))
    out.alpha_composite(t, (cxy[0] - t.width // 2, cxy[1] - t.height // 2))


# ----------------------------------------------------------- save/propagate

def save_densities(im, out_dir, name, w1=683, h1=512):
    os.makedirs(out_dir, exist_ok=True)
    im.save(os.path.join(out_dir, name + "@3x.png"))
    im.resize((round(im.width * 2 / 3), round(im.height * 2 / 3)),
              Image.LANCZOS).save(os.path.join(out_dir, name + "@2x.png"))
    im.resize((round(im.width / 3), round(im.height / 3)),
              Image.LANCZOS).save(os.path.join(out_dir, name + "@1x.png"))


def archive(path3x_stem_dir, stem, tag):
    os.makedirs(REJ, exist_ok=True)
    for d in ("1x", "2x", "3x"):
        src = os.path.join(path3x_stem_dir, f"{stem}@{d}.png")
        dst = os.path.join(REJ, f"{stem}-{tag}@{d}.png")
        if os.path.exists(src):
            shutil.move(src, dst)


def diff_mask(old, new, thresh=10, grow=5, blur=3):
    a = np.asarray(old.convert("RGB"), np.int16)
    b = np.asarray(new.convert("RGB"), np.int16)
    m = (np.abs(a - b).sum(2) > thresh).astype(np.uint8) * 255
    mi = Image.fromarray(m, "L").filter(ImageFilter.MaxFilter(grow * 2 + 1))
    return mi.filter(ImageFilter.GaussianBlur(blur))


def patch_from_wide(cu_path, frame, wide_new, wide_mask, tag):
    """Re-project the changed wide region into an existing CU plate."""
    x0, y0, x1, y1 = frame
    sub_m = wide_mask.crop(frame)
    if np.asarray(sub_m).max() < 8:
        print("no change intersects", os.path.basename(cu_path))
        return
    cu = Image.open(cu_path).convert("RGBA")
    sub = wide_new.crop(frame).resize(cu.size, Image.LANCZOS)
    sub_m = sub_m.resize(cu.size, Image.BILINEAR)
    p = sub.convert("RGBA"); p.putalpha(sub_m)
    cu.alpha_composite(p)
    d = os.path.dirname(cu_path)
    stem = os.path.basename(cu_path).replace("@3x.png", "")
    archive(d, stem, tag)
    save_densities(cu.convert("RGB"), d, stem)
    print("patched", stem)


def apply():
    old_cu = Image.open(DIAL_PATH).convert("RGB")
    fixed = build_fixed(old_cu)
    # before/after sheet for the user
    sheet = Image.new("RGB", (2 * 760 + 30, 770 + 300 + 40), (24, 22, 20))
    for i, im in enumerate((old_cu, fixed)):
        sheet.paste(im.crop((610, 170, 1380, 940)).resize((760, 770)),
                    (10 + i * 770, 10))
        sheet.paste(im.crop((560, 1110, 1400, 1390)).resize((760, 253)),
                    (10 + i * 770, 800))
    sheet.save(os.path.join(Z1, "dial-fix-before-after.png"))
    # canonical CU swap
    d = os.path.dirname(DIAL_PATH)
    archive(d, "cu-door-dial", "b2pre-dialfix")
    save_densities(fixed, d, "cu-door-dial")
    # wide propagation (masked, so untouched door pixels stay bit-identical)
    wide_old = Image.open(WIDE_PATH).convert("RGB")
    wide_new = wide_old.convert("RGBA")
    x0, y0, x1, y1 = DIAL_FRAME
    m = diff_mask(old_cu, fixed)
    reg = fixed.resize((x1 - x0, y1 - y0), Image.LANCZOS)
    rm = m.resize((x1 - x0, y1 - y0), Image.BILINEAR)
    p = reg.convert("RGBA"); p.putalpha(rm)
    wide_new.alpha_composite(p, (x0, y0))
    wide_new = wide_new.convert("RGB")
    wd = os.path.dirname(WIDE_PATH)
    archive(wd, "z1-master-base", "b2pre-dialfix")
    wide_new.save(os.path.join(wd, "z1-master-base@3x.png"))
    wide_new.resize((2560, 1280), Image.LANCZOS).save(
        os.path.join(wd, "z1-master-base@2x.png"))
    wide_new.resize((1280, 640), Image.LANCZOS).save(
        os.path.join(wd, "z1-master-base@1x.png"))
    # sibling CU patches
    wmask = Image.new("L", wide_new.size, 0)
    wmask.paste(rm, (x0, y0))
    patch_from_wide(MFACE_PATH, MFACE_FRAME, wide_new, wmask, "b2pre-dialfix")
    patch_from_wide(CRATE_PATH, CRATE_FRAME, wide_new, wmask, "b2pre-dialfix")
    print("dial fix applied")


def overlays():
    """4 per-socket seated-state overlays (state matrix) from the same
    renderer: CU patch + wide echo + rect metadata."""
    import json
    cu = Image.open(DIAL_PATH).convert("RGB")
    field = face_field(cu)  # field of the FIXED face (clean now)
    meta = {}
    outdir = os.path.join(Z1, "v-master", "states")
    os.makedirs(outdir, exist_ok=True)
    PAD = 14
    for k in EMPTY:
        num = GAP_NUM[k]
        lay = Image.new("RGBA", (CU_W, CU_H), (0, 0, 0, 0))
        draw_socket(lay, k, num, field)
        px, py = clockpos(k)
        h = REC_S // 2 + PAD
        box = (int(px - h), int(py - h), int(px + h), int(py + h))
        patch = Image.new("RGBA", (box[2] - box[0], box[3] - box[1]), (0, 0, 0, 0))
        base = cu.crop(box).convert("RGBA")
        base.alpha_composite(lay.crop(box))
        patch = base
        name = f"ov-dial-seat-{num.lower()}"
        patch.save(os.path.join(outdir, name + "@3x.png"))
        s = (DIAL_FRAME[2] - DIAL_FRAME[0]) / CU_W
        wbox = [round(DIAL_FRAME[0] + box[0] * s), round(DIAL_FRAME[1] + box[1] * s),
                round(DIAL_FRAME[0] + box[2] * s), round(DIAL_FRAME[1] + box[3] * s)]
        patch.resize((wbox[2] - wbox[0], wbox[3] - wbox[1]), Image.LANCZOS).save(
            os.path.join(outdir, name + "-wide@3x.png"))
        meta[name] = {"cu": "cu-door-dial", "cu_rect_3x": list(box),
                      "wide": "z1-master-base", "wide_rect_3x": wbox,
                      "numeral": num, "socket": k}
    with open(os.path.join(outdir, "dial-seat-overlays.json"), "w") as f:
        json.dump(meta, f, indent=1)
    print("seat overlays written")


def preview():
    cu = Image.open(DIAL_PATH).convert("RGB")
    fixed = build_fixed(cu)
    os.makedirs(SCR, exist_ok=True)
    fixed.save(os.path.join(SCR, "dialfix-preview.png"))
    fixed.crop((560, 1110, 1400, 1390)).save(os.path.join(SCR, "dialfix-tray.png"))
    fixed.crop((850, 140, 1250, 480)).save(os.path.join(SCR, "dialfix-top.png"))
    print("preview written")


if __name__ == "__main__":
    {"preview": preview, "apply": apply, "overlays": overlays}[sys.argv[1]]()
