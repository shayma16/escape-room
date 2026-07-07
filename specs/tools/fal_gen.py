#!/usr/bin/env python3
"""Flux 2 Pro batch driver for escape-room asset generation.

Usage: python fal_gen.py <jobs.json>

jobs.json = list of job objects:
{
  "name": "sky-master",            # output base name
  "out_dir": "masters",            # relative to ASSET_ROOT
  "endpoint": "t2i" | "edit",
  "prompt": "...",
  "width": 2752, "height": 1376,
  "refs": ["abs/path/img.png", ...]   # only for edit
  "seed": 12345                        # optional
}

Never prints the API key. Appends results to results.jsonl in scratchpad.
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

# Scratchpad for the RESULTS log. Overridable via FALGEN_SCRATCH so the driver
# survives session-specific scratch paths (the committed default is a fallback).
SCRATCH = os.environ.get(
    "FALGEN_SCRATCH",
    r"C:\Users\shaim\AppData\Local\Temp\claude\C--Users-shaim\d551cf43-749e-4f4a-81be-1d18a3d3b5ca\scratchpad",
)
os.makedirs(SCRATCH, exist_ok=True)
ASSET_ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
ENV_PATH = r"C:\Users\shaim\escape-room\.env"
RESULTS = os.path.join(SCRATCH, "results.jsonl")
PRICE_PER_MP = 0.03  # USD, Flux 2 Pro published output rate

ENDPOINTS = {
    "t2i": "https://queue.fal.run/fal-ai/flux-2-pro",
    "edit": "https://queue.fal.run/fal-ai/flux-2-pro/edit",
}


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


def ref_to_data_uri(path, max_side=2752):
    im = Image.open(path).convert("RGB")
    if max(im.size) > max_side:
        im.thumbnail((max_side, max_side), Image.LANCZOS)
    buf = io.BytesIO()
    im.save(buf, "JPEG", quality=90)
    return "data:image/jpeg;base64," + base64.b64encode(buf.getvalue()).decode()


def submit(job):
    payload = {
        "prompt": job["prompt"],
        "output_format": "png",
        "safety_tolerance": "2",
        "image_size": {"width": job["width"], "height": job["height"]},
    }
    if "seed" in job:
        payload["seed"] = job["seed"]
    if job["endpoint"] == "edit":
        payload["image_urls"] = [ref_to_data_uri(p) for p in job["refs"]]
    res = api(ENDPOINTS[job["endpoint"]], payload)
    return res  # has status_url / response_url / request_id


def save_scaled(png_bytes, out_dir, name):
    os.makedirs(out_dir, exist_ok=True)
    im = Image.open(io.BytesIO(png_bytes)).convert("RGB")
    w, h = im.size
    p3 = os.path.join(out_dir, f"{name}@3x.png")
    im.save(p3, "PNG")
    im.resize((round(w * 2 / 3), round(h * 2 / 3)), Image.LANCZOS).save(
        os.path.join(out_dir, f"{name}@2x.png"), "PNG")
    im.resize((round(w / 3), round(h / 3)), Image.LANCZOS).save(
        os.path.join(out_dir, f"{name}@1x.png"), "PNG")
    return p3, w, h


def run(jobs):
    inflight = {}  # name -> (job, status_url, response_url, t0)
    results = []
    queue = list(jobs)
    MAX_INFLIGHT = 6
    while queue or inflight:
        while queue and len(inflight) < MAX_INFLIGHT:
            job = queue.pop(0)
            try:
                res = submit(job)
                inflight[job["name"]] = (job, res["status_url"], res["response_url"], time.time())
                print(f"submitted {job['name']}")
            except Exception as e:
                print(f"SUBMIT FAIL {job['name']}: {e}")
                results.append({"name": job["name"], "ok": False, "error": str(e)})
        time.sleep(4)
        for name in list(inflight):
            job, surl, rurl, t0 = inflight[name]
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
                    path3x, w, h = save_scaled(png, out_dir, name)
                    mp = w * h / 1e6
                    rec = {"name": name, "ok": True, "path": path3x, "w": w, "h": h,
                           "mp": round(mp, 3), "est_cost": round(mp * PRICE_PER_MP, 4),
                           "seed": out.get("seed"), "endpoint": job["endpoint"],
                           "prompt": job["prompt"], "elapsed_s": round(time.time() - t0, 1)}
                    results.append(rec)
                    print(f"DONE {name} {w}x{h} est ${rec['est_cost']}")
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
    print(f"phase done: {sum(1 for r in results if r.get('ok'))}/{len(results)} ok, est ${total:.2f}")


if __name__ == "__main__":
    with open(sys.argv[1], "r", encoding="utf-8") as f:
        jobs = json.load(f)
    run(jobs)
