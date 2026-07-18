#!/usr/bin/env python3
"""Nano Banana Pro batch driver for escape-room asset generation.

Model switch (user decision 2026-07-07): Flux 2 Pro produced a painterly/matte look
the user rejected; replaced by Nano Banana Pro (fal-ai/nano-banana-pro). Engine-render
style is enforced by the mandatory style template composed into every prompt by the
caller (see .claude/agents/asset-generation.md). This driver only transports prompts,
reference images (up to 14), and size, then saves @3x/@2x/@1x.

Usage: python fal_gen.py <jobs.json>

jobs.json = list of job objects:
{
  "name": "z1-hearth-base",         # output base name
  "out_dir": "z1/v-hearth",         # relative to ASSET_ROOT
  "endpoint": "t2i" | "edit",       # edit = image-to-image / inpaint-style with refs
  "prompt": "...",
  "width": 3840, "height": 1920,     # exact target px; saved by center-crop+resize
  "refs": ["abs/path/img.png", ...],  # up to 14 anchors (both t2i and edit accept refs)
  "resolution_tier": "4k" | "std",   # pricing/quality; "4k" => $0.30, else $0.15
  "seed": 12345,                      # optional
  "keep_rgba": true                   # optional (icons/sprites cut out later)
}

Nano Banana Pro takes a NAMED aspect_ratio enum (not raw px) and resolution "1K/2K/4K".
The driver maps target w:h to the nearest allowed aspect, requests it, then
center-crops + resizes the returned image to the EXACT target pixels (no distortion).

Never prints the API key. Appends results to results.jsonl in scratchpad.
Pricing: $0.15/image standard, $0.30 at 4K (verified 2026-07-08).
"""
import base64
import io
import json
import os
import sys
import time
import urllib.request
import urllib.error

from PIL import Image

SCRATCH = os.environ.get(
    "FALGEN_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim-escape-room\8c048282-9ce7-4b1a-b54a-04e2ba948c25\scratchpad",
)
os.makedirs(SCRATCH, exist_ok=True)
ASSET_ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
ENV_PATH = r"C:\Users\shaim\escape-room\.env"
RESULTS = os.path.join(SCRATCH, "results.jsonl")

PRICE_STD = 0.15
PRICE_4K = 0.30
MAX_REFS = 14

ENDPOINTS = {
    "t2i": "https://queue.fal.run/fal-ai/nano-banana-pro",
    "edit": "https://queue.fal.run/fal-ai/nano-banana-pro/edit",
}

# Allowed aspect_ratio enum -> numeric w/h ratio.
ALLOWED_AR = {
    "21:9": 21 / 9, "16:9": 16 / 9, "3:2": 3 / 2, "4:3": 4 / 3, "5:4": 5 / 4,
    "1:1": 1.0, "4:5": 4 / 5, "3:4": 3 / 4, "2:3": 2 / 3, "9:16": 9 / 16,
}


def nearest_ar(w, h):
    target = w / h
    return min(ALLOWED_AR, key=lambda k: abs(ALLOWED_AR[k] - target))


def load_key():
    with open(ENV_PATH, "r", encoding="utf-8") as f:
        for line in f:
            line = line.strip()
            if line.startswith("FAL_KEY="):
                return line.split("=", 1)[1].strip().strip('"').strip("'")
    raise SystemExit("FAL_KEY not found in .env")


KEY = load_key()


def api(url, payload=None, method=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method=method or ("POST" if data else "GET"))
    req.add_header("Authorization", "Key " + KEY)
    req.add_header("Content-Type", "application/json")
    for attempt in range(4):
        try:
            with urllib.request.urlopen(req, timeout=180) as r:
                return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            body = e.read().decode(errors="replace")[:500]
            if e.code in (403, 429, 500, 502, 503) and attempt < 3:
                time.sleep(5 * (attempt + 1))
                continue
            raise RuntimeError(f"HTTP {e.code} at {url}: {body}")
        except Exception:
            if attempt < 3:
                time.sleep(5)
                continue
            raise


def ref_to_data_uri(path, max_side=1536):
    im = Image.open(path).convert("RGB")
    if max(im.size) > max_side:
        im.thumbnail((max_side, max_side), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=90)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def submit(job):
    w, h = job["width"], job["height"]
    tier = job.get("resolution_tier", "4k" if max(w, h) >= 3000 else "std")
    ar = job.get("aspect_ratio") or nearest_ar(w, h)
    payload = {
        "prompt": job["prompt"],
        "output_format": "png",
        "num_images": 1,
        "aspect_ratio": ar,
        "resolution": "4K" if tier == "4k" else "2K",
    }
    if "seed" in job:
        payload["seed"] = job["seed"]
    refs = job.get("refs", [])[:MAX_REFS]
    if refs:
        payload["image_urls"] = [ref_to_data_uri(p) for p in refs]
    res = api(ENDPOINTS[job["endpoint"]], payload)
    return res, tier


def fit_exact(im, tw, th):
    """Center-crop to target aspect, then resize to exact target px. No distortion."""
    sw, sh = im.size
    tr = tw / th
    sr = sw / sh
    if abs(sr - tr) > 1e-3:
        if sr > tr:  # source wider -> crop width
            nw = int(round(sh * tr))
            x0 = (sw - nw) // 2
            im = im.crop((x0, 0, x0 + nw, sh))
        else:        # source taller -> crop height
            nh = int(round(sw / tr))
            y0 = (sh - nh) // 2
            im = im.crop((0, y0, sw, y0 + nh))
    if im.size != (tw, th):
        im = im.resize((tw, th), Image.LANCZOS)
    return im


def save_scaled(png_bytes, out_dir, name, target_w, target_h, keep_rgba=False):
    os.makedirs(out_dir, exist_ok=True)
    im = Image.open(io.BytesIO(png_bytes))
    im = im.convert("RGBA" if keep_rgba else "RGB")
    im = fit_exact(im, target_w, target_h)
    w, h = im.size
    p3 = os.path.join(out_dir, f"{name}@3x.png")
    im.save(p3, "PNG")
    im.resize((round(w * 2 / 3), round(h * 2 / 3)), Image.LANCZOS).save(
        os.path.join(out_dir, f"{name}@2x.png"), "PNG")
    im.resize((round(w / 3), round(h / 3)), Image.LANCZOS).save(
        os.path.join(out_dir, f"{name}@1x.png"), "PNG")
    return p3, w, h


def run(jobs):
    inflight = {}
    results = []
    queue = list(jobs)
    MAX_INFLIGHT = 6
    while queue or inflight:
        while queue and len(inflight) < MAX_INFLIGHT:
            job = queue.pop(0)
            try:
                res, tier = submit(job)
                inflight[job["name"]] = (job, tier, res["status_url"], res["response_url"], time.time())
                print(f"submitted {job['name']} ({tier})")
            except Exception as e:
                print(f"SUBMIT FAIL {job['name']}: {e}")
                results.append({"name": job["name"], "ok": False, "error": str(e)})
        time.sleep(4)
        for name in list(inflight):
            job, tier, surl, rurl, t0 = inflight[name]
            try:
                st = api(surl)
            except Exception as e:
                print(f"poll error {name}: {e}")
                continue
            status = st.get("status")
            if status == "COMPLETED":
                try:
                    out = api(rurl)
                    img = out["images"][0]
                    with urllib.request.urlopen(img["url"], timeout=300) as r:
                        png = r.read()
                    out_dir = os.path.join(ASSET_ROOT, job["out_dir"])
                    cost = PRICE_4K if tier == "4k" else PRICE_STD
                    path3x, w, h = save_scaled(
                        png, out_dir, name, job["width"], job["height"],
                        keep_rgba=job.get("keep_rgba", False))
                    rec = {"name": name, "ok": True, "path": path3x, "w": w, "h": h,
                           "tier": tier, "est_cost": cost,
                           "seed": out.get("seed"), "endpoint": job["endpoint"],
                           "prompt": job["prompt"], "elapsed_s": round(time.time() - t0, 1)}
                    results.append(rec)
                    print(f"DONE {name} {w}x{h} ({tier}) ${cost}")
                except Exception as e:
                    results.append({"name": name, "ok": False, "error": str(e)})
                    print(f"FETCH FAIL {name}: {e}")
                del inflight[name]
            elif status in ("IN_QUEUE", "IN_PROGRESS"):
                if time.time() - t0 > 600:
                    results.append({"name": name, "ok": False, "error": "timeout"})
                    print(f"TIMEOUT {name}")
                    del inflight[name]
            else:
                results.append({"name": name, "ok": False, "error": f"status={status} {st}"})
                print(f"BAD STATUS {name}: {status}")
                del inflight[name]
    with open(RESULTS, "a", encoding="utf-8") as f:
        for r in results:
            f.write(json.dumps(r) + "\n")
    total = sum(r.get("est_cost", 0) for r in results if r.get("ok"))
    print(f"phase done: {sum(1 for r in results if r.get('ok'))}/{len(results)} ok, spend ${total:.2f}")


if __name__ == "__main__":
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        jobs = json.load(f)
    run(jobs)
