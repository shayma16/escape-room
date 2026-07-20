#!/usr/bin/env python3
"""Batch 4 NB-edit helper (fal-ai/nano-banana-pro /edit) + registered
object-removal compositor. Reusable across the batch-4 NB items.

edit_region(base, region, content, seed, refs) submits ONE crop-scoped edit
with the mandatory style template, polls, downloads, fits the result to the
region px, then SHIFT-REGISTERS it against the base on a border ring (so the
unchanged wall aligns). Returns (registered_region_rgb, raw_region_rgb, seed).
Raw is archived to _rejects/ for audit. Callers build masked overlays so ONLY
the intended object pixels change (retained items stay pixel-identical to base).

A fal HTTP 403 with a balance/exhausted body = the USER's fal funds ran out
(distinct from our own compute) -> raise BalanceExhausted; stop and report.
"""
import base64
import io
import json
import os
import sys
import time
import urllib.error
import urllib.request

import numpy as np
from PIL import Image, ImageFilter

ROOT = r"C:\Users\shaim\escape-room"
ENV = os.path.join(ROOT, ".env")
STYLE = open(os.path.join(ROOT, "specs", "tools", "style_template.txt"),
             encoding="utf-8").read().strip()
EDIT_URL = "https://queue.fal.run/fal-ai/nano-banana-pro/edit"
REJ = os.path.join(ROOT, "specs", "assets", "level-2", "_rejects")


class BalanceExhausted(RuntimeError):
    pass


def _key():
    for l in open(ENV, encoding="utf-8"):
        if l.startswith("FAL_KEY="):
            return l.split("=", 1)[1].strip().strip('"').strip("'")
    raise RuntimeError("FAL_KEY not in .env")


KEY = _key()


def _api(url, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data,
                                 method="POST" if data else "GET")
    req.add_header("Authorization", "Key " + KEY)
    req.add_header("Content-Type", "application/json")
    for a in range(4):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")[:400]
            if e.code in (402, 403) and ("balance" in body.lower()
                                         or "exhaust" in body.lower()
                                         or "insufficient" in body.lower()):
                raise BalanceExhausted(f"HTTP {e.code}: {body}")
            if e.code in (403, 429, 500, 502, 503) and a < 3:
                time.sleep(5 * (a + 1))
                continue
            raise RuntimeError(f"HTTP {e.code}: {body}")
        except Exception:
            if a < 3:
                time.sleep(5)
                continue
            raise


def _data_uri(im, max_side=1536):
    im = im.convert("RGB")
    if max(im.size) > max_side:
        im = im.copy()
        im.thumbnail((max_side, max_side), Image.LANCZOS)
    b = io.BytesIO()
    im.save(b, "JPEG", quality=93)
    return "data:image/jpeg;base64," + base64.b64encode(b.getvalue()).decode()


def _nearest_ar(w, h):
    ars = {"21:9": 21 / 9, "16:9": 16 / 9, "3:2": 3 / 2, "4:3": 4 / 3,
           "5:4": 5 / 4, "1:1": 1.0, "4:5": 4 / 5, "3:4": 3 / 4,
           "2:3": 2 / 3, "9:16": 9 / 16}
    t = w / h
    return min(ars, key=lambda k: abs(ars[k] - t))


def _fit(im, tw, th):
    sw, sh = im.size
    tr, sr = tw / th, sw / sh
    if abs(sr - tr) > 1e-3:
        if sr > tr:
            nw = int(round(sh * tr)); x = (sw - nw) // 2
            im = im.crop((x, 0, x + nw, sh))
        else:
            nh = int(round(sw / tr)); y = (sh - nh) // 2
            im = im.crop((0, y, sw, y + nh))
    return im.resize((tw, th), Image.LANCZOS)


def _register(base_region, edited, ring=42, search=16):
    """Shift edited to best-align with base on an outer ring (unchanged wall)."""
    b = np.asarray(base_region, np.float32)
    e = np.asarray(edited, np.float32)
    h, w = b.shape[:2]
    mask = np.zeros((h, w), bool)
    mask[:ring] = mask[-ring:] = True
    mask[:, :ring] = mask[:, -ring:] = True
    best, bdx, bdy = 1e18, 0, 0
    for dy in range(-search, search + 1, 2):
        for dx in range(-search, search + 1, 2):
            es = np.roll(np.roll(e, dy, 0), dx, 1)
            d = np.abs(es[mask] - b[mask]).mean()
            if d < best:
                best, bdx, bdy = d, dx, dy
    reg = Image.fromarray(np.roll(np.roll(e, bdy, 0), bdx, 1).astype(np.uint8))
    print(f"    register: dx={bdx} dy={bdy} ring-MAE={best:.1f}")
    return reg


def edit_region(base_img, region, content, seed, refs=(), tag="edit",
                resolution="2K"):
    x0, y0, x1, y1 = region
    crop = base_img.crop(region).convert("RGB")
    cw, ch = crop.size
    image_urls = [_data_uri(crop)] + [_data_uri(Image.open(p)) for p in refs]
    prompt = (STYLE + "\n\nEDIT THE PROVIDED IMAGE REGION. Keep the SAME "
              "camera, framing, perspective, lighting, materials and every "
              "unchanged element pixel-identical to the input. Only change: "
              + content)
    payload = {"prompt": prompt, "output_format": "png", "num_images": 1,
               "aspect_ratio": _nearest_ar(cw, ch), "resolution": resolution,
               "image_urls": image_urls, "seed": seed}
    res = _api(EDIT_URL, payload)
    surl, rurl = res["status_url"], res["response_url"]
    for _ in range(180):
        st = _api(surl)
        if st.get("status") == "COMPLETED":
            break
        if st.get("status") not in ("IN_QUEUE", "IN_PROGRESS"):
            raise RuntimeError("status " + str(st))
        time.sleep(4)
    out = _api(rurl)
    url = out["images"][0]["url"]
    with urllib.request.urlopen(url, timeout=300) as r:
        png = r.read()
    raw = Image.open(io.BytesIO(png)).convert("RGB")
    raw = _fit(raw, cw, ch)
    os.makedirs(REJ, exist_ok=True)
    raw.save(os.path.join(REJ, f"{tag}-rawfix@3x.png"))
    reg = _register(crop, raw)
    return reg, raw, out.get("seed", seed)


def obj_overlay(base, clean_full, mask_full, rect):
    """Composite clean-plate pixels over base only inside mask (feathered),
    return the RGB patch cropped to rect."""
    m = mask_full.filter(ImageFilter.GaussianBlur(3))
    comp = base.copy()
    comp.paste(clean_full, (0, 0), m)
    return comp.crop(rect)


def generate(refs, content, seed, aspect="3:2", resolution="2K", tag="gen"):
    """t2i-style generation via /edit with reference images (subject/design
    anchors). Returns the raw output image. Used for cat pose sprites."""
    image_urls = [_data_uri(Image.open(p)) for p in refs]
    prompt = STYLE + "\n\n" + content
    payload = {"prompt": prompt, "output_format": "png", "num_images": 1,
               "aspect_ratio": aspect, "resolution": resolution,
               "image_urls": image_urls, "seed": seed}
    res = _api(EDIT_URL, payload)
    surl, rurl = res["status_url"], res["response_url"]
    for _ in range(180):
        st = _api(surl)
        if st.get("status") == "COMPLETED":
            break
        if st.get("status") not in ("IN_QUEUE", "IN_PROGRESS"):
            raise RuntimeError("status " + str(st))
        time.sleep(4)
    out = _api(rurl)
    url = out["images"][0]["url"]
    with urllib.request.urlopen(url, timeout=300) as r:
        png = r.read()
    raw = Image.open(io.BytesIO(png)).convert("RGB")
    os.makedirs(REJ, exist_ok=True)
    raw.save(os.path.join(REJ, f"{tag}-raw@3x.png"))
    return raw, out.get("seed", seed)
