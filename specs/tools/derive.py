#!/usr/bin/env python3
"""Build-3 derived-asset helpers: PIL crops off 4K bases, RGBA cutouts, @3x/@2x/@1x
exports, grayscale gate. No API cost. Used for zoom close-ups, state variants, icon
cutouts, and scale exports. Fresh renders go through fal_gen.py."""
import os, sys, io, json
from PIL import Image, ImageFilter, ImageDraw, ImageChops, ImageOps

ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"

def _p(rel): return os.path.join(ROOT, rel)

def save_scaled(im, out_dir_rel, name, keep_rgba=False):
    """Save im as @3x, then @2x (2/3) and @1x (1/3)."""
    out_dir = _p(out_dir_rel)
    os.makedirs(out_dir, exist_ok=True)
    im = im.convert("RGBA" if keep_rgba else "RGB")
    w, h = im.size
    im.save(os.path.join(out_dir, f"{name}@3x.png"), "PNG")
    im.resize((round(w*2/3), round(h*2/3)), Image.LANCZOS).save(
        os.path.join(out_dir, f"{name}@2x.png"), "PNG")
    im.resize((round(w/3), round(h/3)), Image.LANCZOS).save(
        os.path.join(out_dir, f"{name}@1x.png"), "PNG")
    return os.path.join(out_dir, f"{name}@3x.png")

def crop_zoom(base_rel, box, out_dir_rel, name, target=(1600,1200)):
    """Crop box=(x0,y0,x1,y1) from a base @3x plate, resize to target aspect, export."""
    base = Image.open(_p(base_rel)).convert("RGB")
    x0,y0,x1,y1 = box
    crop = base.crop((x0,y0,x1,y1))
    # fit to target aspect by center-crop then resize
    tw,th = target
    cw,ch = crop.size
    tr, cr = tw/th, cw/ch
    if abs(cr-tr) > 1e-3:
        if cr > tr:
            nw = int(round(ch*tr)); xo=(cw-nw)//2; crop=crop.crop((xo,0,xo+nw,ch))
        else:
            nh = int(round(cw/tr)); yo=(ch-nh)//2; crop=crop.crop((0,yo,cw,yo+nh))
    crop = crop.resize(target, Image.LANCZOS)
    return save_scaled(crop, out_dir_rel, name)

def cutout_white(src_path, out_dir_rel, name, thresh=238, feather=1.2):
    """White-bg render -> RGBA cutout. thresh = luminance above which -> transparent."""
    im = Image.open(src_path).convert("RGB")
    g = im.convert("L")
    w,h = im.size
    px = g.load()
    mask = Image.new("L",(w,h),0)
    mp = mask.load()
    for y in range(h):
        for x in range(w):
            mp[x,y] = 0 if px[x,y] >= thresh else 255
    # keep only the largest connected opaque blob via flood from border erosion:
    mask = mask.filter(ImageFilter.MaxFilter(3))
    mask = mask.filter(ImageFilter.MinFilter(3))
    if feather: mask = mask.filter(ImageFilter.GaussianBlur(feather))
    out = im.convert("RGBA"); out.putalpha(mask)
    return save_scaled(out, out_dir_rel, name, keep_rgba=True)

def grayscale_check(path, out_scratch):
    """Emit a grayscale version for the 2.3 gate visual check; return path."""
    im = Image.open(path).convert("L")
    p = os.path.join(out_scratch, os.path.basename(path).replace(".png","_GRAY.png"))
    im.save(p,"PNG")
    return p

if __name__ == "__main__":
    # dispatch: python derive.py <json-of-ops>
    ops = json.loads(sys.argv[1])
    for op in ops:
        kind = op["op"]
        if kind == "crop":
            r = crop_zoom(op["base"], tuple(op["box"]), op["out_dir"], op["name"],
                          tuple(op.get("target",[1600,1200])))
            print("CROP", op["name"], "->", r)
        elif kind == "cutout":
            r = cutout_white(_p(op["src"]) if not os.path.isabs(op["src"]) else op["src"],
                             op["out_dir"], op["name"],
                             op.get("thresh",238), op.get("feather",1.2))
            print("CUTOUT", op["name"], "->", r)
