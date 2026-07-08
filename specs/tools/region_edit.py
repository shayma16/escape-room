#!/usr/bin/env python3
"""Region-scoped state variant: crop a region from a fresh base, send to nano-banana
edit with a state prompt, composite the returned region back onto the base with a
feathered mask so ZERO pixels change outside the region. Guarantees style match +
pixel alignment. Emits @3x/@2x/@1x. No full-scene re-render.

Usage: region_edit.py <spec.json>
spec = {
 "base": "z4/v-alcove/z4-alcove-base@3x.png",
 "region": [x0,y0,x1,y1],            # region to re-render (px on @3x base)
 "content": "state description",     # composed with style template
 "refs": ["extra abs/rel refs"],     # optional
 "out": "z4/v-alcove/z4-alcove-blooming-nb",
 "seed": 123, "feather": 40
}
"""
import os, sys, io, json, base64, time, urllib.request, urllib.error
from PIL import Image, ImageFilter

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
ENV = r"C:\Users\shaim\escape-room\.env"
STYLE = open(r"C:\Users\shaim\escape-room\specs\tools\style_template.txt", encoding="utf-8").read().strip()
EDIT_URL = "https://queue.fal.run/fal-ai/nano-banana-pro/edit"

def key():
    for l in open(ENV, encoding="utf-8"):
        if l.startswith("FAL_KEY="):
            v = l.split('=', 1)[1].strip()
            return v.strip(chr(34)).strip(chr(39))
KEY = key()

def api(url, payload=None):
    data = json.dumps(payload).encode() if payload is not None else None
    req = urllib.request.Request(url, data=data, method="POST" if data else "GET")
    req.add_header("Authorization", "Key "+KEY); req.add_header("Content-Type","application/json")
    for a in range(4):
        try:
            with urllib.request.urlopen(req, timeout=180) as r: return json.loads(r.read().decode())
        except urllib.error.HTTPError as e:
            body=e.read().decode(errors="replace")[:300]
            if e.code in (403,429,500,502,503) and a<3: time.sleep(5*(a+1)); continue
            raise RuntimeError(f"HTTP {e.code}: {body}")
        except Exception:
            if a<3: time.sleep(5); continue
            raise

def data_uri(im, max_side=1536):
    im = im.convert("RGB")
    if max(im.size) > max_side: im.thumbnail((max_side,max_side), Image.LANCZOS)
    b=io.BytesIO(); im.save(b,"JPEG",quality=92)
    return "data:image/jpeg;base64,"+base64.b64encode(b.getvalue()).decode()

def absref(p): return p if os.path.isabs(p) else os.path.join(ROOT,p)

def run(spec):
    base = Image.open(absref(spec["base"])).convert("RGB")
    x0,y0,x1,y1 = spec["region"]
    crop = base.crop((x0,y0,x1,y1))
    cw,ch = crop.size
    refs = [data_uri(crop)] + [data_uri(Image.open(absref(p))) for p in spec.get("refs",[])]
    prompt = STYLE + "\n\nEDIT THE PROVIDED IMAGE REGION. Keep the SAME camera, framing, lighting, materials, and every unchanged element pixel-identical. Only change: " + spec["content"]
    payload = {"prompt": prompt, "output_format":"png","num_images":1,
               "aspect_ratio": nearest_ar(cw,ch), "resolution":"2K","image_urls":refs}
    if "seed" in spec: payload["seed"]=spec["seed"]
    res = api(EDIT_URL, payload)
    surl,rurl = res["status_url"], res["response_url"]
    for _ in range(150):
        st = api(surl)
        if st.get("status")=="COMPLETED": break
        if st.get("status") not in ("IN_QUEUE","IN_PROGRESS"): raise RuntimeError("status "+str(st))
        time.sleep(4)
    out = api(rurl); url = out["images"][0]["url"]
    with urllib.request.urlopen(url, timeout=300) as r: png = r.read()
    new = Image.open(io.BytesIO(png)).convert("RGB")
    # fit new to region aspect (center-crop) then resize to region px
    new = fit(new, cw, ch)
    # feathered composite back onto base
    result = base.copy()
    f = spec.get("feather", 40)
    mask = Image.new("L",(cw,ch),255)
    m2 = Image.new("L",(cw,ch),0)
    from PIL import ImageDraw
    ImageDraw.Draw(m2).rectangle([f,f,cw-f,ch-f],fill=255)
    mask = m2.filter(ImageFilter.GaussianBlur(f*0.6))
    result.paste(new,(x0,y0),mask)
    save(result, spec["out"])
    print("DONE", spec["out"], "seed", out.get("seed"))

def nearest_ar(w,h):
    ars={"21:9":21/9,"16:9":16/9,"3:2":3/2,"4:3":4/3,"5:4":5/4,"1:1":1.0,"4:5":4/5,"3:4":3/4,"2:3":2/3,"9:16":9/16}
    t=w/h; return min(ars,key=lambda k:abs(ars[k]-t))

def fit(im,tw,th):
    sw,sh=im.size; tr=tw/th; sr=sw/sh
    if abs(sr-tr)>1e-3:
        if sr>tr: nw=int(round(sh*tr)); x=(sw-nw)//2; im=im.crop((x,0,x+nw,sh))
        else: nh=int(round(sw/tr)); y=(sh-nh)//2; im=im.crop((0,y,sw,y+nh))
    return im.resize((tw,th),Image.LANCZOS)

def save(im,out):
    p=absref(out+"@3x.png"); os.makedirs(os.path.dirname(p),exist_ok=True)
    w,h=im.size; im.save(p,"PNG")
    im.resize((round(w*2/3),round(h*2/3)),Image.LANCZOS).save(absref(out+"@2x.png"),"PNG")
    im.resize((round(w/3),round(h/3)),Image.LANCZOS).save(absref(out+"@1x.png"),"PNG")

if __name__=="__main__":
    specs=json.load(open(sys.argv[1],encoding="utf-8"))
    for s in specs:
        try: run(s)
        except Exception as e: print("FAIL",s.get("out"),e)
