#!/usr/bin/env python3
"""Batch 4 / z3 clockwork state overlays + sprites (items 9-14).

Deterministic PIL ($0; drum-key-in uses the plan's NB reserve — the flat 2D
key would not seat convincingly in the axle-end socket, so it is regenerated
in the NB phase, not here). Per-element overlay + sprite rig JSON (schema =
hand-sprites.json). Surface patches seam-checked (<=24). Sprites are RGBA
cutouts via GEOMETRIC masks (robust vs the dial glow / dark machinery where
luminance keying fails) with companion "-absent" background patches so the
Developer can rotate/reposition without ghosting the resting element.

  9  ov-drum-oiled     (CU21 + wide echo)  rust bloom cleared + oil sheen
  11 sp-weight         drive weight sprite + vertical track spec
  12 sp-pendulum       pendulum sprite (still/weak/full) + pivot/amplitude
  13 sp-hammer         hammer twitch keys (rest + lifted) + pivot
  14 strike-rods       JSON notes + rects (z3 + z1 rod ends), no art
(10 ov-drum-key-in is produced in the NB phase — see l2_b4_nb.py)
"""
import json
import os
import sys

import numpy as np
from PIL import Image, ImageDraw, ImageFilter

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_b4_states import seam

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
Z3 = os.path.join(A2, "z3", "v-dial")
WIDE = os.path.join(Z3, "z3-dial-base@3x.png")
STATES = os.path.join(Z3, "states")
SPRITES = os.path.join(Z3, "sprites")
OVJSON = os.path.join(A2, "z3", "z3-state-overlays.json")
CU_W, CU_H = 2048, 1536
CU_DRUM = (0, 1030, 1187, 1920)
CU_DRUM_S = CU_W / (CU_DRUM[2] - CU_DRUM[0])


def load_json():
    return json.load(open(OVJSON)) if os.path.exists(OVJSON) else {}


def save_json(m):
    with open(OVJSON, "w") as f:
        json.dump(m, f, indent=1)


def oil(crop, boss_local):
    a = np.asarray(crop, np.float32)
    R, G, B = a[..., 0], a[..., 1], a[..., 2]
    rust = (R - B > 40) & (R > 90) & (R - G > 16)
    m = Image.fromarray((rust * 255).astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(2))
    mf = np.asarray(m, np.float32)[..., None] / 255.0
    lum = (0.35 * R + 0.45 * G + 0.2 * B)[..., None]
    iron = np.concatenate([lum * 0.94, lum * 0.90, lum * 0.86], axis=2)
    out = a * (1 - mf * 0.85) + iron * (mf * 0.85)
    h, w = out.shape[:2]
    yy, xx = np.mgrid[0:h, 0:w].astype(np.float32)
    bx, by = boss_local
    rr = np.hypot((xx - bx) / (0.6 * w / 2), (yy - by) / (0.6 * h / 2))
    gloss = np.clip(1.0 - rr, 0, 1) ** 2.2
    streak = np.clip(1 - np.abs((yy - by) - 0.55 * (xx - bx)) / 26.0, 0, 1)
    sheen = (gloss * 0.55 + gloss * streak * 0.45)[..., None]
    out = out + sheen * np.array([56, 50, 40]) * 0.8
    wet = (np.clip(rr, 0, 1.6) < 1.25)[..., None] * (1 - sheen) * 0.10
    out = out * (1 - wet)
    patch = Image.fromarray(np.clip(out, 0, 255).astype(np.uint8))
    fm = Image.new("L", patch.size, 0)
    ImageDraw.Draw(fm).rectangle([6, 6, patch.width - 7, patch.height - 7],
                                 fill=255)
    fm = fm.filter(ImageFilter.GaussianBlur(4))
    return Image.composite(patch, crop, fm)


def save_surface(meta, name, patch, rect, base, note, wide=False, cu_base=None):
    os.makedirs(STATES, exist_ok=True)
    suffix = "-wide@3x.png" if wide else "@3x.png"
    patch.convert("RGB").save(os.path.join(STATES, name + suffix))
    sc = seam(base, patch.convert("RGB"), rect)
    assert sc <= 24, f"{name}{' wide' if wide else ''} seam {sc:.1f}"
    e = meta.setdefault(name, {})
    if wide:
        e["wide_base"] = "z3-dial-base"
        e["wide_rect_3x"] = list(rect)
    else:
        e["base"] = cu_base or "cu-winding-drum"
        e["rect_3x"] = list(rect)
    e["note"] = note
    print(f"  {name}{' (wide)' if wide else ''}: rect {rect} seam {sc:.1f} PASS")


# ---------------------------------------------------------------- item 9
def drum_oiled(meta):
    wide = Image.open(WIDE).convert("RGB")
    r = (415, 1355, 815, 1760)
    crop = oil(wide.crop(r), (610 - r[0], 1540 - r[1]))
    save_surface(meta, "ov-drum-oiled", crop, r, wide,
                 "winding-drum bearing oiled: dry rust bloom cleared "
                 "(recolored to clean iron, texture kept) + oil sheen at the "
                 "boss/socket collar; bearing zone only per style 8", wide=True)
    cu = wide.crop(CU_DRUM).resize((CU_W, CU_H), Image.LANCZOS)
    s = CU_DRUM_S
    rc = (int(r[0] * s), int((r[1] - 1030) * s),
          int(r[2] * s), int((r[3] - 1030) * s))
    bl = (610 * s - rc[0], (1540 - 1030) * s - rc[1])
    cropc = oil(cu.crop(rc), bl)
    save_surface(meta, "ov-drum-oiled", cropc, rc, cu,
                 "winding-drum bearing oiled (CU21): dry bloom cleared + oil "
                 "sheen at boss/socket", wide=False, cu_base="cu-winding-drum")


# --------------------------------------------------- geometric-mask sprite
def geo_sprite(wide, rect, mask_draw, feather=1.4):
    crop = wide.crop(rect).convert("RGBA")
    ox, oy = rect[0], rect[1]
    mask = Image.new("L", crop.size, 0)
    mask_draw(ImageDraw.Draw(mask), ox, oy)
    mask = mask.filter(ImageFilter.GaussianBlur(feather))
    sp = crop.copy()
    sp.putalpha(mask)
    return sp


def bg_patch(wide, rect, name, meta, note):
    x0, y0, x1, y1 = rect
    a = np.asarray(wide.crop(rect).convert("RGB"), np.float32)
    out = a.copy()
    h, w = a.shape[:2]
    lum = a.mean(2)
    for x in range(w):
        col = a[:, x]
        idx = np.argsort(lum[:, x])[:max(3, h // 4)]
        out[:, x] = col[idx].mean(0)
    out = np.asarray(Image.fromarray(out.astype(np.uint8)).filter(
        ImageFilter.GaussianBlur(9)), np.float32)
    patch = Image.fromarray(out.astype(np.uint8))
    fm = Image.new("L", patch.size, 0)
    ImageDraw.Draw(fm).rectangle([5, 5, w - 6, h - 6], fill=255)
    fm = fm.filter(ImageFilter.GaussianBlur(5))
    blended = Image.composite(patch, wide.crop(rect), fm)
    save_surface(meta, name, blended, rect, wide, note, wide=True)


# ---------------------------------------------------------------- item 12
def pendulum(wide, sj):
    r = (2030, 70, 2280, 1330)

    def draw(md, ox, oy):
        md.polygon([(2181 - ox, 80 - oy), (2199 - ox, 80 - oy),
                    (2152 - ox, 1030 - oy), (2130 - ox, 1030 - oy)], fill=255)
        md.ellipse([2048 - ox, 1005 - oy, 2192 - ox, 1305 - oy], fill=255)
        md.polygon([(2110 - ox, 1300 - oy), (2126 - ox, 1300 - oy),
                    (2118 - ox, 1360 - oy)], fill=255)
    sp = geo_sprite(wide, r, draw)
    os.makedirs(SPRITES, exist_ok=True)
    sp.save(os.path.join(SPRITES, "sp-pendulum@3x.png"))
    sj["sp-pendulum"] = {
        "sprite": "sp-pendulum@3x.png",
        "rect_3x": list(r),
        "pivot_px_local": [2190 - r[0], 80 - r[1]],
        "pivot_px_at_3x": [2190, 80],
        "amplitudes_deg": {"still": 0, "weak": 4, "full": 11},
        "render_rule": "rotate the sprite about pivot; for non-zero amplitude "
        "paint the resting pendulum out with ov-pendulum-absent (wide) first. "
        "still = base as shipped (dead still). Cadence/timing is Developer.",
        "background_patch": "states/ov-pendulum-absent-wide@3x.png"}
    return r


# ---------------------------------------------------------------- item 13
def hammer(wide, sj):
    r = (2320, 130, 2540, 300)
    piv = (2338, 246)                       # arbor pivot (arm root, left)

    def draw(md, ox, oy):
        # head block (dark elegant machinery silhouette per style 227)
        md.polygon([(2432 - ox, 150 - oy), (2512 - ox, 168 - oy),
                    (2506 - ox, 236 - oy), (2426 - ox, 224 - oy)], fill=255)
        # arm/shaft to the pivot
        md.line([(piv[0] - ox, piv[1] - oy), (2470 - ox, 200 - oy)],
                fill=255, width=14)
    sp = geo_sprite(wide, r, draw, feather=1.2)
    os.makedirs(SPRITES, exist_ok=True)
    sp.save(os.path.join(SPRITES, "sp-hammer-rest@3x.png"))
    piv_local = (piv[0] - r[0], piv[1] - r[1])
    lift = sp.rotate(-9, center=piv_local, resample=Image.BICUBIC)
    lift.save(os.path.join(SPRITES, "sp-hammer-lift@3x.png"))
    sj["sp-hammer"] = {
        "rest": "sp-hammer-rest@3x.png",
        "lift": "sp-hammer-lift@3x.png",
        "rect_3x": list(r),
        "pivot_px_local": list(piv_local),
        "twitch_deg": 9,
        "render_rule": "D11 twitch = lift-and-settle between rest and lift "
        "(never contacts the bell); escapement tick is audio. Two hammers "
        "share this sprite (mirror for the right hammer). Paint out with "
        "ov-hammer-absent for non-rest frames.",
        "background_patch": "states/ov-hammer-absent-wide@3x.png"}
    return r


# ---------------------------------------------------------------- item 11
def weight(sj):
    """No distinct drive-weight silhouette exists in the plate (it sits low,
    in shadow, near the drum); deliver a deterministic cast-iron cylindrical
    weight matched to the golden-hour iron palette + a vertical track."""
    W, H = 150, 300
    body = Image.new("L", (W, H), 0)
    ImageDraw.Draw(body).rounded_rectangle([26, 22, W - 26, H - 14], radius=16,
                                           fill=255)
    a = np.zeros((H, W, 4), np.float32)
    xx = np.linspace(-1, 1, W)[None, :]
    shade = 0.55 + 0.5 * np.cos(xx * 1.3)
    rim = np.clip(1 - np.abs(xx - 0.72) / 0.12, 0, 1) * 0.55
    col = np.array([70, 62, 54])[None, None, :] * shade[..., None]
    col = col + np.array([150, 110, 62])[None, None, :] * rim[..., None]
    a[..., :3] = np.clip(col, 0, 255)
    a[..., 3] = np.asarray(body, np.float32)
    sp = Image.fromarray(a.astype(np.uint8))
    dd = ImageDraw.Draw(sp)
    dd.ellipse([26, 12, W - 26, 40], fill=(60, 52, 46, 255),
               outline=(130, 100, 62, 255), width=3)
    dd.rectangle([W // 2 - 6, 0, W // 2 + 6, 22], fill=(40, 34, 30, 255))
    dd.ellipse([26, H - 30, W - 26, H - 6], outline=(30, 26, 22, 200), width=4)
    os.makedirs(SPRITES, exist_ok=True)
    sp.save(os.path.join(SPRITES, "sp-weight@3x.png"))
    sj["sp-weight"] = {
        "sprite": "sp-weight@3x.png",
        "size_px_at_3x": [W, H],
        "hang_point_local": [W // 2, 2],
        "track_at_3x": {"x": 300, "y_low": 1720, "y_rising": 1500,
                        "y_raised": 1300},
        "render_rule": "cast-iron drive weight on the drum cable; positioned "
        "sprite. Deterministic render (no clean weight silhouette in the base "
        "plate). Track x/y are the cable line; Developer tweens low->raised as "
        "the clock winds."}


# ---------------------------------------------------------------- item 14
def strike_rods(sj):
    sj["strike-rods"] = {
        "art": None,
        "z3_rod_rects_at_3x": [[2500, 180, 3600, 420]],
        "z1_rod_note": "the linkage rods exit z3 frame-right and re-enter at "
        "the z1 time-lock housing (cu-timelock) rod ends; same rod line the "
        "player followed all level.",
        "articulation": "strike beat = small axial translate of the rod "
        "(+-6 px @3x along the rod axis) synced to the hammer twitch; key "
        "poses only, no separate art. Translate offsets are Developer timing.",
        "render_rule": "no image asset; overlay/transform notes only."}


def main():
    meta = load_json()
    hs = os.path.join(SPRITES, "hand-sprites.json")
    sj = json.load(open(hs)) if os.path.exists(hs) else {}
    print("item 9 drum-oiled:")
    drum_oiled(meta)
    wide = Image.open(WIDE).convert("RGB")
    print("item 12 pendulum:")
    rp = pendulum(wide, sj)
    bg_patch(wide, rp, "ov-pendulum-absent", meta,
             "dark background behind the pendulum (column dark-median clone) "
             "so the swing sprite can rotate without ghosting")
    print("item 13 hammer:")
    rh = hammer(wide, sj)
    bg_patch(wide, rh, "ov-hammer-absent", meta,
             "dark background behind the strike hammer for twitch frames")
    print("item 11 weight:")
    weight(sj)
    print("item 14 strike-rods:")
    strike_rods(sj)
    save_json(meta)
    with open(os.path.join(SPRITES, "clockwork-sprites.json"), "w") as f:
        json.dump({k: v for k, v in sj.items()
                   if k.startswith(("sp-", "strike"))}, f, indent=1)
    print("z3-state-overlays.json + clockwork-sprites.json written")


if __name__ == "__main__":
    main()
