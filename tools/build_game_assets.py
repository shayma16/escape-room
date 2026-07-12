#!/usr/bin/env python3
"""Build the app bundle asset set for Level 1 from the approved specs/assets art.

Developer Agent pipeline (deterministic, re-runnable):
  1. Ships every needed @3x plate: opaque plates -> JPEG (q87), RGBA sprites/icons -> PNG.
  2. Computes state-overlay crops by diffing base plates against state-variant plates,
     so the SpriteKit layer can compose ANY combination of latched states
     (condition-driven plate selection, never event-ordered).
  3. Inpaints (onion-peel) "item taken" variants where the art batch shipped no
     emptied-container state, and erases the painted clock hands so the movable-hands
     mechanic can render synthetic hands.
  4. Generates placeholder chrome art (app icon, keyhole emblem, pause rune glyph,
     level thumbnail, synthetic clock hands).
  5. Synthesizes the functional SFX set + per-zone ambient loops (original works,
     no third-party license needed) as 22.05 kHz 16-bit WAV.

Run from repo root:  python tools/build_game_assets.py
"""

import json
import math
import os
import random
import shutil
import struct
import wave

from PIL import Image, ImageChops, ImageDraw, ImageFilter

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "specs", "assets", "level-1")
OUT = os.path.join(ROOT, "EscapeRoom", "Resources", "GameAssets", "level-1")
AUDIO_OUT = os.path.join(ROOT, "EscapeRoom", "Resources", "Audio")
CHROME_OUT = os.path.join(ROOT, "EscapeRoom", "Resources", "GameAssets", "chrome")
XCASSETS = os.path.join(ROOT, "EscapeRoom", "Resources", "Assets.xcassets")

JPEG_Q = 87


# Build-3 stale close-up shadow fix (2026-07-09).
# ROOT CAUSE (fixed): the build-3 render rebuild delivered close-ups / state variants
# under raw "-nb" (nano-banana) filenames while the OLD build-2 painterly art still sat
# at the plain canonical names. resolve_src used to prefer the canonical name (or fall
# back to a generic same-stem "-nb"), so ~70 build-3 close-ups were SHADOWED by stale
# build-2 canonical files and the bundle shipped the old painterly art for them.
#
# FIX (Option B): every FINAL intended build-3 "-nb" derived asset was PROMOTED to its
# canonical name on disk (specs/assets/level-1/), and the superseded build-2 canonicals
# were archived to specs/assets/level-1/_rejects/flux-painterly/*-build2@Nx.png. The tree
# is now unambiguous: the canonical name IS the shipped build-3 art. That means:
#   * no SRC_OVERRIDE table is needed (the door-lock/statue re-roll art now lives at its
#     canonical name — the override was only a workaround for the stale shadow), and
#   * resolve_src must NOT silently fall back to a "-nb" sibling anymore. A leftover "-nb"
#     next to a canonical is the exact stale-shadow signature we just eliminated; if one
#     re-appears we FAIL THE BUILD (assert_no_nb_shadow) instead of silently picking one.
#
# NON-PROMOTED "-nb" files remaining in specs/ are deliberately UNUSED by the pipeline
# (astrolabe-plate-N / cu-rim-rune -> PIL sprites are authoritative; cu-coin-hallmark,
# z3-cellar-nobeam, z1-entry-basin-* wides, cu-slots-nb whose content already equals the
# canonical cu-slots-empty). They are not loaded by name here, so they cannot shadow.


def resolve_src(path):
    """Map a requested canonical asset path to the file that ships in specs/.

    Build-3 fix: the canonical name is authoritative. We do NOT fall back to a "-nb"
    sibling — that fallback is what allowed stale build-2 art to shadow build-3 deliveries.
    A missing canonical now fails loudly at open() with a clear FileNotFoundError instead
    of silently substituting art.
    """
    return path


def assert_no_nb_shadow():
    """Anti-recurrence guard: fail the build if any canonical asset that the pipeline
    loads by name still has a "-nb" sibling on disk (the stale-shadow signature).

    We check every canonical @3x path the build requests (PLAIN_PLATES, RGBA_SPRITES,
    ICONS, and the wide/close-up variant plates loaded by build_inpainted / OVERLAYS /
    MANUAL_OVERLAYS). If a "-nb" sibling exists next to a requested canonical, staging is
    ambiguous exactly the way build-3 shipped stale close-ups — so we refuse to build.
    """
    requested = set(PLAIN_PLATES) | set(RGBA_SPRITES) | set(ICONS)
    for (view, var, *_rest) in MANUAL_OVERLAYS:
        requested.add(f"{view}/{var}@3x.png")
    for (view, base, var, *_rest) in OVERLAYS:
        requested.add(f"{view}/{base}@3x.png")
        requested.add(f"{view}/{var}@3x.png")
    # variant plates loaded directly in build_inpainted() by canonical name
    requested |= {
        "z1/v-hearth/cu-clock-unspent@3x.png",  # Q3: cuckoo pop/spent no longer staged
        "z1/v-hearth/z1-hearth-rug-moved@3x.png",
        "z1/v-hearth/z1-hearth-trapdoor-open@3x.png",
        "z2/v-cabinet/cu-astrolabe-drawer-open@3x.png",
        "z3/v-cellar/z3-cellar-drawer-open@3x.png",
        "z3/v-cellar/z3-cellar-barrel-pried@3x.png",
        "z2/v-cabinet/z2-cabinet-open@3x.png",
    }
    shadows = []
    for rel in sorted(requested):
        nb = rel.replace("@3x.png", "-nb@3x.png")
        if os.path.exists(src(rel)) and os.path.exists(src(nb)):
            shadows.append(f"{rel}  <-shadowed-by->  {nb}")
    if shadows:
        raise SystemExit(
            "STALE-SHADOW GUARD FAILED: a build-loaded canonical asset still has a '-nb' "
            "sibling on disk. Promote the intended art to the canonical name (Option B) or "
            "delete the stray '-nb'. Offenders:\n  " + "\n  ".join(shadows))


def src(path):
    return os.path.join(SRC, path.replace("/", os.sep))


# Chrome assets that must always ship the manifest-current source (R3-002 follow-up).
# Maps each canonical SOURCE (under specs/assets/level-1/) to every staged DESTINATION
# that must byte-match it. Unlike the scene plates (which the pipeline transcodes to
# JPEG), the thumbnail is copied verbatim, so a straight byte-equality check is exact and
# unambiguous — chrome art can never silently go stale (the build FAILS if it does).
CHROME_STAGED = {
    "chrome/level1-thumb.jpg": [
        os.path.join(XCASSETS, "level1-thumb.imageset", "level1-thumb.jpg"),
        os.path.join(CHROME_OUT, "level1-thumb.jpg"),
    ],
}


def assert_chrome_current():
    """Fail the build if any staged chrome asset does not match its manifest-current
    source. Runs AFTER staging so it validates what actually shipped. This is the chrome
    analogue of assert_no_nb_shadow: the load-bearing thumbnail (the app reads the asset
    catalog copy) can never be a stale build-2 image again (R3-002)."""
    stale = []
    for source_rel, dests in CHROME_STAGED.items():
        s = src(source_rel)
        if not os.path.exists(s):
            raise SystemExit(f"CHROME GUARD: missing source {source_rel}")
        want = open(s, "rb").read()
        for d in dests:
            if not os.path.exists(d):
                stale.append(f"{d}  <-MISSING (source {source_rel})")
            elif open(d, "rb").read() != want:
                stale.append(f"{d}  <-STALE, differs from {source_rel}")
    if stale:
        raise SystemExit(
            "CHROME STALENESS GUARD FAILED: a staged chrome asset does not match the "
            "manifest-current source (would ship stale menu art). Offenders:\n  "
            + "\n  ".join(stale))


def load(path):
    return Image.open(src(resolve_src(path)))


def ensure(d):
    os.makedirs(d, exist_ok=True)
    return d


def out_path(rel):
    p = os.path.join(OUT, rel.replace("/", os.sep))
    ensure(os.path.dirname(p))
    return p


def save_plate(im, rel):
    """Save an opaque plate as JPEG."""
    p = out_path(rel)
    im.convert("RGB").save(p, "JPEG", quality=JPEG_Q, subsampling=1)
    return p


def save_png(im, rel):
    p = out_path(rel)
    im.save(p, "PNG")
    return p


# ---------------------------------------------------------------- inpainting

def flatten_hue(rgb, mask, ring=25):  # was 70 — a 141px MaxFilter is O(minutes) on 4K
    """Recolour masked pixels to the average surround hue, keeping luminance."""
    grown = mask.filter(ImageFilter.MaxFilter(ring * 2 + 1))
    ring_mask = ImageChops.subtract(grown, mask)
    px = rgb.load()
    rm = ring_mask.load()
    mk = mask.load()
    w, h = rgb.size
    sr = sg = sb = cnt = 0
    for y in range(0, h, 3):
        for x in range(0, w, 3):
            if rm[x, y] > 127:
                r, g, b = px[x, y]
                sr += r; sg += g; sb += b; cnt += 1
    if not cnt:
        return rgb
    ar, ag, ab = sr / cnt, sg / cnt, sb / cnt
    alum = max(1.0, 0.299 * ar + 0.587 * ag + 0.114 * ab)
    for y in range(h):
        for x in range(w):
            if mk[x, y] > 127:
                r, g, b = px[x, y]
                lum = 0.299 * r + 0.587 * g + 0.114 * b
                f = lum / alum
                px[x, y] = (int(min(255, ar * f)), int(min(255, ag * f)),
                            int(min(255, ab * f)))
    return rgb


def inpaint(im, mask, blur=3.0, noise=5, seed=7, recolor=False):
    """Onion-peel (BFS) inpaint of masked pixels, then blur+grain inside mask."""
    rgb = im.convert("RGB")
    w, h = rgb.size
    px = rgb.load()
    mk = mask.load()
    unknown = set()
    for y in range(h):
        for x in range(w):
            if mk[x, y] > 127:
                unknown.add((x, y))
    if not unknown:
        return rgb
    # frontier = unknown pixels with a known neighbour
    from collections import deque
    def known_neighbours(x, y):
        vals = []
        for dx in (-1, 0, 1):
            for dy in (-1, 0, 1):
                if dx == 0 and dy == 0:
                    continue
                nx, ny = x + dx, y + dy
                if 0 <= nx < w and 0 <= ny < h and (nx, ny) not in unknown:
                    vals.append(px[nx, ny])
        return vals

    frontier = deque(p for p in unknown if known_neighbours(*p))
    while unknown:
        if not frontier:  # isolated island; seed arbitrarily
            frontier = deque([next(iter(unknown))])
        progressed = False
        next_frontier = deque()
        while frontier:
            x, y = frontier.popleft()
            if (x, y) not in unknown:
                continue
            vals = known_neighbours(x, y)
            if not vals:
                next_frontier.append((x, y))
                continue
            r = sum(v[0] for v in vals) // len(vals)
            g = sum(v[1] for v in vals) // len(vals)
            b = sum(v[2] for v in vals) // len(vals)
            px[x, y] = (r, g, b)
            unknown.discard((x, y))
            progressed = True
            for dx in (-1, 0, 1):
                for dy in (-1, 0, 1):
                    n = (x + dx, y + dy)
                    if n in unknown:
                        next_frontier.append(n)
        frontier = next_frontier
        if not progressed and not frontier and unknown:
            # give up on leftovers (shouldn't happen)
            for (x, y) in list(unknown):
                px[x, y] = (40, 36, 32)
                unknown.discard((x, y))
    if recolor:
        rgb = flatten_hue(rgb, mask)
        px = rgb.load()
    # blur + grain inside mask only
    blurred = rgb.filter(ImageFilter.GaussianBlur(blur))
    rng = random.Random(seed)
    bx = blurred.load()
    mk = mask.load()
    for y in range(h):
        for x in range(w):
            if mk[x, y] > 127:
                r, g, b = bx[x, y]
                n = rng.randint(-noise, noise)
                px[x, y] = (max(0, min(255, r + n)),
                            max(0, min(255, g + n)),
                            max(0, min(255, b + n)))
    return rgb


def clone_patch(im, src_box, dst_xy, feather=25, mirror=True):
    """Clone src rect over dst (top-left), horizontally mirrored, feathered edges."""
    rgb = im.convert("RGB")
    patch = rgb.crop(src_box)
    if mirror:
        patch = patch.transpose(Image.FLIP_LEFT_RIGHT)
    w, h = patch.size
    m = Image.new("L", (w, h), 0)
    ImageDraw.Draw(m).rectangle((feather, feather, w - feather, h - feather), fill=255)
    m = m.filter(ImageFilter.GaussianBlur(feather * 0.6))
    rgb.paste(patch, dst_xy, m)
    return rgb


def polygon_mask(size, polys=(), ellipses=(), grow=0):
    """polys: list of point lists; ellipses: list of (cx, cy, rx, ry)."""
    m = Image.new("L", size, 0)
    d = ImageDraw.Draw(m)
    for poly in polys:
        d.polygon(poly, fill=255)
    for (cx, cy, rx, ry) in ellipses:
        d.ellipse((cx - rx, cy - ry, cx + rx, cy + ry), fill=255)
    if grow:
        m = m.filter(ImageFilter.MaxFilter(grow * 2 + 1))
    return m


def strip_poly(p0, p1, w0, w1, extend=0):
    """Thick line polygon from p0 to p1, half-widths w0/w1, tip extended."""
    x0, y0 = p0
    x1, y1 = p1
    dx, dy = x1 - x0, y1 - y0
    L = math.hypot(dx, dy) or 1.0
    ux, uy = dx / L, dy / L
    nx, ny = -uy, ux
    x1, y1 = x1 + ux * extend, y1 + uy * extend
    return [(x0 + nx * w0, y0 + ny * w0), (x1 + nx * w1, y1 + ny * w1),
            (x1 - nx * w1, y1 - ny * w1), (x0 - nx * w0, y0 - ny * w0)]


# ------------------------------------------------------------- diff overlays

def assert_no_misplaced_clone_fill(base_im, var_im, bbox, name,
                                   max_shift=260, step=20, ratio=0.55, min_shift=16):
    """R5-001 anti-recurrence guard (build 11): fail the build if a state-variant's
    changed-region content matches the BASE much better at a translated offset than in
    place — the signature of a "misplaced clone" fill.

    Root case this catches: the manifest-current z1-hearth-poker-taken plate's
    generative REMOVE-the-poker edit filled the poker area with a +240 px-shifted copy
    of the fireplace interior (a second andiron + duplicated grate). The plate still
    pixel-REGISTERS with the base (edge-ring diff < 1 grey level), so the auto-diff
    crop + the runtime composite were both geometrically perfect — perfectly registered
    WRONG art, which no registration check can see. Content provenance is checked here
    instead: for the changed bbox's interior, if base@shift matches the variant's fill
    dramatically better (< ratio x the in-place diff) at a non-trivial shift, the fill
    is a misplaced clone of scene content and MUST NOT ship (R4-004 -> R5-001 lineage).

    Measured separation on the current tree (interior mean-abs-diff, grey levels):
    every legitimate variant scores best-shift/zero-shift >= 0.72; the defective poker
    plate scores 0.28 at (+240, 0). Threshold 0.55 splits them with ~2x margin each way.
    """
    from PIL import ImageStat
    x0, y0, x1, y1 = bbox
    inset = 30
    if (x1 - x0) <= 2 * inset + 40 or (y1 - y0) <= 2 * inset + 40:
        return  # too small for a meaningful interior-content comparison
    ix0, iy0, ix1, iy1 = x0 + inset, y0 + inset, x1 - inset, y1 - inset
    base_l = base_im.convert("L")
    var_l = var_im.convert("L")
    if var_l.size != base_l.size:
        var_l = var_l.resize(base_l.size, Image.LANCZOS)
    # Quarter-scale search keeps this pure-PIL pass fast; a >= 16 px clone shift
    # survives the downsample easily (the poker defect is 240 px).
    ds = 4
    bw, bh = base_l.size
    base_s = base_l.resize((bw // ds, bh // ds), Image.BILINEAR)
    var_s = var_l.resize((bw // ds, bh // ds), Image.BILINEAR)
    sx0, sy0, sx1, sy1 = ix0 // ds, iy0 // ds, ix1 // ds, iy1 // ds
    interior = var_s.crop((sx0, sy0, sx1, sy1))

    def mean_diff(dx, dy):
        ax0, ay0 = sx0 + dx // ds, sy0 + dy // ds
        ax1, ay1 = ax0 + (sx1 - sx0), ay0 + (sy1 - sy0)
        if ax0 < 0 or ay0 < 0 or ax1 > base_s.width or ay1 > base_s.height:
            return None
        region = base_s.crop((ax0, ay0, ax1, ay1))
        return ImageStat.Stat(ImageChops.difference(region, interior)).mean[0]

    zero = mean_diff(0, 0)
    if zero is None or zero < 3.0:
        return  # near-identical fill (nothing visibly changed inside) — nothing to clone
    best = (zero, 0, 0)
    for dy in range(-max_shift, max_shift + 1, step):
        for dx in range(-max_shift, max_shift + 1, step):
            if abs(dx) < min_shift and abs(dy) < min_shift:
                continue
            d = mean_diff(dx, dy)
            if d is not None and d < best[0]:
                best = (d, dx, dy)
    if best[0] < ratio * zero:
        raise SystemExit(
            f"MISPLACED-CLONE GUARD FAILED for {name}: the variant's changed region "
            f"matches the base {zero / max(best[0], 1e-6):.1f}x better when shifted by "
            f"({best[1]}, {best[2]}) px (diff {best[0]:.1f} vs {zero:.1f} in place). "
            "The state fill is a misplaced clone of scene content (R5-001 class: e.g. a "
            "duplicated andiron where the poker was removed) and would composite as a "
            "visibly wrong fragment despite perfect registration. Re-derive the variant "
            "plate (Asset Gen) or synthesize the state from the base (build_inpainted).")


def diff_overlay(base_im, var_im, pad=12, thresh=14, clamp=None):
    """Return (bbox, crop) covering where var differs from base, or None.

    Build-3 delivery gap G2 (2026-07-08): the build-3 rebuild shipped fresh 4K base
    plates (3840x1920) but left the state-variant plates at the build-2 dimensions
    (2560x1280). Both share the identical 2:1 framing (region-edits registered to the
    same composition), so we resize the variant up to the base's pixel size before
    diffing — otherwise ImageChops.difference errors / produces garbage full-frame
    overlays. Flagged to the Producer in implementation-notes (gap G2).
    """
    base_rgb = base_im.convert("RGB")
    var_rgb = var_im.convert("RGB")
    if var_rgb.size != base_rgb.size:
        var_rgb = var_rgb.resize(base_rgb.size, Image.LANCZOS)
    diff = ImageChops.difference(base_rgb, var_rgb)
    gray = diff.convert("L")
    mask = gray.point(lambda v: 255 if v > thresh else 0)
    mask = mask.filter(ImageFilter.MinFilter(5))   # kill speckle
    mask = mask.filter(ImageFilter.MaxFilter(5))
    if clamp is not None:
        # Clamp rects were authored in 2560x1280 (build-2) space; scale to the base's
        # actual pixel size so they still clip the right region on 4K build-3 bases (G2).
        sx, sy = base_rgb.size[0] / 2560.0, base_rgb.size[1] / 1280.0
        scaled = (clamp[0] * sx, clamp[1] * sy, clamp[2] * sx, clamp[3] * sy)
        clip = Image.new("L", mask.size, 0)
        ImageDraw.Draw(clip).rectangle(scaled, fill=255)
        mask = ImageChops.multiply(mask, clip)
    bbox = mask.getbbox()
    if bbox is None:
        return None
    w, h = base_rgb.size
    x0 = max(0, bbox[0] - pad)
    y0 = max(0, bbox[1] - pad)
    x1 = min(w, bbox[2] + pad)
    y1 = min(h, bbox[3] + pad)
    # Crop from the SIZE-MATCHED variant (var_rgb), so the bbox (computed in base pixels)
    # indexes the right region regardless of the variant's original dimensions (gap G2).
    return (x0, y0, x1, y1), var_rgb.crop((x0, y0, x1, y1))


def ring_gain(base_im, target_im, bbox, ring=40):
    """Mean-luminance gain between two plates in a ring around bbox."""
    def mean_lum(im):
        x0, y0, x1, y1 = bbox
        w, h = im.size
        rx0, ry0 = max(0, x0 - ring), max(0, y0 - ring)
        rx1, ry1 = min(w, x1 + ring), min(h, y1 + ring)
        outer = im.convert("L").crop((rx0, ry0, rx1, ry1))
        hist_sum = 0
        count = 0
        op = outer.load()
        ow, oh = outer.size
        for y in range(0, oh, 4):
            for x in range(0, ow, 4):
                # ring only: skip inner bbox
                gx, gy = rx0 + x, ry0 + y
                if x0 <= gx < x1 and y0 <= gy < y1:
                    continue
                hist_sum += op[x, y]
                count += 1
        return hist_sum / max(count, 1)
    g = mean_lum(target_im) / max(mean_lum(base_im), 1e-6)
    return max(0.3, min(1.2, g))


def apply_gain(im, gain):
    return im.point(lambda v: max(0, min(255, int(v * gain))))


# ------------------------------------------------------------------- config

# plates shipped verbatim (JPEG), path relative to level dir
PLAIN_PLATES = [
    # z1 wides (bases; variants become overlays)
    "z1/v-hearth/z1-hearth-base@3x.png",
    "z1/v-study/z1-study-base@3x.png",
    "z1/v-entry/z1-entry-base@3x.png",
    # z1 close-ups
    "z1/v-hearth/cu-ash-undisturbed@3x.png",
    "z1/v-hearth/cu-ash-sifted@3x.png",
    "z1/v-hearth/cu-ash-ring-taken@3x.png",
    "z1/v-hearth/cu-bellows@3x.png",
    "z1/v-hearth/cu-lintel@3x.png",
    "z1/v-hearth/cu-dial-panel@3x.png",
    "z1/v-hearth/cu-trapdoor-open@3x.png",
    "z1/v-study/cu-grimoire-pageA@3x.png",
    "z1/v-study/cu-grimoire-pageB@3x.png",
    "z1/v-study/cu-grimoire-recipe@3x.png",
    "z1/v-study/cu-grimoire-zodiac@3x.png",
    "z1/v-study/cu-grimoire-bird@3x.png",
    "z1/v-study/cu-triptych-1@3x.png",
    "z1/v-study/cu-triptych-2@3x.png",
    "z1/v-study/cu-triptych-3@3x.png",
    "z1/v-study/cu-flowerpot@3x.png",
    "z1/v-study/cu-runedoor-tiles@3x.png",
    "z1/v-entry/cu-door-lock@3x.png",
    "z1/v-entry/cu-door-lock-basin-filled@3x.png",
    "z1/v-entry/cu-door-lock-basin-drained@3x.png",
    "z1/v-entry/cu-door-lock-vines-withered@3x.png",
    "z1/v-entry/cu-door-lock-vines-gone@3x.png",
    "z1/v-entry/cu-door-lock-bolt-slid@3x.png",
    "z1/v-entry/cu-rusted-key@3x.png",
    "z1/v-entry/cu-windowsill@3x.png",
    "z1/v-entry/cu-cage-crow@3x.png",
    "z1/v-entry/cu-cage-crow-refusal@3x.png",
    "z1/v-entry/cu-cage-open-empty@3x.png",
    "z1/v-entry/cu-star-keyhole@3x.png",
    "z1/v-entry/cu-star-keyhole-key@3x.png",
    "z1/v-entry/cu-crow-rafters@3x.png",
    # z2
    "z2/v-bench/z2-bench-base@3x.png",
    "z2/v-bench/cu-brew-clear@3x.png",
    "z2/v-bench/cu-brew-fizzle@3x.png",
    "z2/v-bench/cu-brew-draught@3x.png",
    "z2/v-bench/cu-mortar-empty@3x.png",
    "z2/v-bench/cu-mortar-blossom@3x.png",
    "z2/v-bench/cu-mortar-paste@3x.png",
    "z2/v-cabinet/z2-cabinet-base@3x.png",
    "z2/v-cabinet/cu-slots-empty@3x.png",
    "z2/v-cabinet/cu-slots-seated@3x.png",
    "z2/v-cabinet/cu-potion-shelf@3x.png",
    "z2/v-cabinet/cu-astrolabe@3x.png",
    "z2/v-cabinet/cu-window-orion@3x.png",
    # CLUSTER B (round-2 critical soft-lock fix): the two solved-container OPEN close-up
    # plates. These are the backgrounds ContainerCloseUp renders behind the tappable
    # coin/crank (p03) and file/phial (p04); they were MISSING from the bundle, so those
    # close-ups rendered as the grey-box progression soft-lock (R2-018/019/025/026).
    "z2/v-cabinet/cu-cabinet-open@3x.png",
    "z2/v-cabinet/cu-astrolabe-drawer-open@3x.png",
    # z3 (beam matrix = full-plate selection)
    "z3/v-cellar/z3-cellar-base@3x.png",
    "z3/v-cellar/z3-cellar-shelf-slid@3x.png",
    "z3/v-cellar/z3-cellar-weight-hung@3x.png",
    "z3/v-cellar/z3-cellar-beam-floor@3x.png",
    "z3/v-cellar/z3-cellar-beam-floor-shelf-slid@3x.png",
    "z3/v-cellar/z3-cellar-beam-blocked@3x.png",
    "z3/v-cellar/z3-cellar-beam-alcove@3x.png",
    "z3/v-cellar/cu-barrel-gap@3x.png",
    "z3/v-cellar/cu-mirror-scratches@3x.png",
    "z3/v-cellar/cu-winch-socket@3x.png",
    "z3/v-cellar/cu-winch-crank@3x.png",
    "z3/v-cellar/cu-spoon-drawer@3x.png",
    # z4 (full-plate matrix)
    "z4/v-alcove/z4-alcove-base@3x.png",
    "z4/v-alcove/z4-alcove-trembling@3x.png",
    "z4/v-alcove/z4-alcove-blooming@3x.png",
    "z4/v-alcove/z4-alcove-picked@3x.png",
    "z4/v-alcove/z4-alcove-blooming-keytaken@3x.png",
    "z4/v-alcove/z4-alcove-picked-keytaken@3x.png",
    "z4/v-alcove/cu-planter-closed@3x.png",
    "z4/v-alcove/cu-planter-trembling@3x.png",
    "z4/v-alcove/cu-planter-blooming@3x.png",
    "z4/v-alcove/cu-planter-picked@3x.png",
    "z4/v-alcove/cu-statue-key@3x.png",
    "z4/v-alcove/cu-statue-key-taken@3x.png",
]

RGBA_SPRITES = [
    "z1/v-hearth/sprites/dial-face@3x.png",
    "z2/v-bench/sprites/rune-ember-I@3x.png",
    "z2/v-bench/sprites/rune-ember-II@3x.png",
    "z2/v-bench/sprites/rune-ember-III@3x.png",
    "z2/v-bench/sprites/ladle-ripple-ccw@3x.png",
    "z2/v-cabinet/sprites/astrolabe-pointer@3x.png",
    "z2/v-cabinet/sprites/astrolabe-plate-1@3x.png",
    "z2/v-cabinet/sprites/astrolabe-plate-2@3x.png",
    "z2/v-cabinet/sprites/astrolabe-plate-3@3x.png",
    "z2/v-cabinet/sprites/astrolabe-plate-4@3x.png",
    "z2/v-cabinet/sprites/astrolabe-plate-5@3x.png",
    "z2/v-cabinet/sprites/astrolabe-plate-6@3x.png",
    # runedoor pressed tiles are opaque rect swaps but tiny; ship as png
    "z1/v-study/sprites/runedoor-tile1-pressed@3x.png",
    "z1/v-study/sprites/runedoor-tile2-pressed@3x.png",
    "z1/v-study/sprites/runedoor-tile3-pressed@3x.png",
    "z1/v-study/sprites/runedoor-tile4-pressed@3x.png",
]

ICONS = [
    "z1/icons/icon-poker@3x.png",
    "z1/icons/icon-rusted-key@3x.png",
    "z1/icons/icon-gold-ring@3x.png",
    "z1/icons/icon-feather@3x.png",
    "z2/icons/icon-crank@3x.png",
    "z2/icons/icon-silver-coin@3x.png",
    "z2/icons/icon-file@3x.png",
    "z2/icons/icon-phial@3x.png",
    "z2/icons/icon-phial-draught@3x.png",
    "z2/icons/icon-paste@3x.png",
    "z3/icons/icon-spoon@3x.png",
    "z3/icons/icon-weight@3x.png",
    "z3/icons/icon-shavings@3x.png",
    "z4/icons/icon-blossom@3x.png",
    "z4/icons/icon-cage-key@3x.png",
]

# Build-3 gap G3 (2026-07-08): the wide state-VARIANT plates are region-edits of a
# SUPERSEDED base generation and do NOT pixel-align with the fresh build-3 4K base plates
# — a full-frame diff (even at matched size / high threshold) still trips everywhere, so
# the automatic diff-overlay can't localize them. Instead we crop each state's element by
# a HAND-SPECIFIED normalized rect (from the known hotspot geometry) out of the size-
# matched variant and composite that (feathered) over the base. This keeps the multi-state
# overlay layering the coordinator relies on (slots + cabinet + drawer can co-render),
# with only the intended element replaced. Flagged to the Producer (gap G3).
#
# (view_dir, variant, overlay_name, normalized_rect (x,y,w,h), needs_dim)
# --------------------------------------------------- build-10 dual-safe re-frame
# Per-view transform from asset-manifest build10_reframe.transforms (at @3x on
# 3840x1920). new_norm = old_norm * s + off. Hotspot rects live in Swift and are
# remapped there; here we remap the HAND-AUTHORED overlay rects (old framing) so the
# staged overlays.json ships in re-framed space (developer_contract.rect_remap).
REFRAME = {
    "z1/v-hearth": (0.955, 86 / 3840, 86 / 1920),
    "z1/v-study":  (0.86, 538 / 3840, 240 / 1920),
    "z1/v-entry":  (0.74, 425 / 3840, 250 / 1920),
    "z2/v-bench":  (0.83, 430 / 3840, 163 / 1920),
    "z2/v-cabinet": (0.70, 630 / 3840, 288 / 1920),
    "z3/v-cellar": (0.82, 445 / 3840, 173 / 1920),
    "z4/v-alcove": (1.0, 0.0, 0.0),
}


def reframe_rect(view, rect):
    s_, ox, oy = REFRAME[view]
    x, y, w, h = rect
    return (x * s_ + ox, y * s_ + oy, w * s_, h * s_)


MANUAL_OVERLAYS = [
    ("z2/v-cabinet", "z2-cabinet-slots-seated", "ov-slots-seated", (0.150, 0.24, 0.22, 0.22), False, True),
    ("z4/v-alcove",  "z4-alcove-key-taken",     "ov-key-taken",     (0.48, 0.10, 0.22, 0.34), False, False),
]

MANUAL_OVERLAY_BASE = {
    "z1/v-hearth":  "z1/v-hearth/z1-hearth-base@3x.png",
    "z2/v-cabinet": "z2/v-cabinet/z2-cabinet-base@3x.png",
    "z3/v-cellar":  "z3/v-cellar/z3-cellar-base@3x.png",
    "z4/v-alcove":  "z4/v-alcove/z4-alcove-base@3x.png",
}

SPRITE_JSONS = [
    "z1/v-study/sprites/runedoor-tiles.json",
    "z2/v-bench/sprites/rune-ember-rects.json",
]

# (view_dir, base, variant, overlay_name, needs_dim_variant)
# Optional 6th element: clamp rect (x0, y0, x1, y1) restricting the diff, used where
# a re-rendered variant carries low-level drift outside the intended element
# (asset-manifest flag: cage re-render brightness shift).
# Only the state variants that DO pixel-align with the current build-3 base still use the
# automatic diff. Everything else moved to MANUAL_OVERLAYS (gap G3). ov-rug-moved /
# ov-trapdoor-open are computed from build-3-derived extras in main() (gap G1).
#
# R5-001 (build 11): z1-hearth-poker-taken is NO LONGER consumed. It pixel-aligns with
# the base, but its poker-removal fill is a +240 px-shifted clone of the fireplace
# interior (duplicated andiron) — the user-visible "misplaced fireplace fragment".
# ov-poker-taken is now SYNTHESIZED from the base in build_inpainted() (see the extras
# auto-diff loop in main), and assert_no_misplaced_clone_fill guards the whole class.
OVERLAYS = [
    # z1 entry (re-framed variants align — self-locating rects)
    ("z1/v-entry", "z1-entry-base", "z1-entry-cage-open",   "ov-cage-open",   False),
    ("z1/v-entry", "z1-entry-base", "z1-entry-crow-lintel", "ov-crow-lintel", False),
    ("z1/v-entry", "z1-entry-base", "z1-entry-vines-gone",  "ov-vines-gone",  False),
    # z2 cabinet (re-framed variants align)
    ("z2/v-cabinet", "z2-cabinet-base", "z2-cabinet-open",        "ov-cab-open",     False),
    ("z2/v-cabinet", "z2-cabinet-base", "z2-cabinet-drawer-open", "ov-adrawer-open", False),
    # z3 cellar — the R4-024 fix: one base, independent element overlays, all self-located
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-barrel-pried", "ov-barrel-pried", False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-drawer-open",  "ov-drawer-open",  False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-crank-fitted", "ov-crank-fitted", False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-mirror-d2",    "ov-mirror-d2",    False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-mirror-d3",    "ov-mirror-d3",    False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-shelf-slid",   "ov-shelf-slid",   False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-weight-hung",  "ov-weight-hung",  False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-beam-floor",   "ov-beam-floor",   False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-beam-blocked", "ov-beam-blocked", False),
    ("z3/v-cellar", "z3-cellar-base", "z3-cellar-beam-alcove",  "ov-beam-alcove",  False),
]

# Additional misaligned wide overlays (gap G3), same hand-rect crop mechanism as
# MANUAL_OVERLAYS above but for z1-entry / z2-bench. Kept in one place with their bases.
MANUAL_OVERLAYS += [
    # LEGACY 2560 flame plates (contract): crop OLD rect, store REMAPPED rect.
    ("z2/v-bench", "z2-bench-flame1",          "ov-flame1",         (0.13, 0.30, 0.26, 0.34), False, True),
    ("z2/v-bench", "z2-bench-flame2",          "ov-flame2",         (0.13, 0.24, 0.26, 0.40), False, True),
    ("z2/v-bench", "z2-bench-flame3",          "ov-flame3",         (0.13, 0.18, 0.26, 0.46), False, True),
]
MANUAL_OVERLAY_BASE["z2/v-bench"] = "z2/v-bench/z2-bench-base@3x.png"


# ------------------------------------------------------- inpainted variants

def build_inpainted(report):
    """Create emptied-container variants + hands-erased clock plates.

    Returns dict of extra full plates {out_rel: PIL image} to feed overlay pass.
    """
    extras = {}

    # --- clock hands erased (same mask for unspent/pop/spent: same camera) ---
    C = (1055, 850)
    polys = [
        strip_poly(C, (815, 715), 60, 42, extend=26),      # hour hand
        strip_poly(C, (1262, 703), 58, 44, extend=30),     # minute hand
        strip_poly((1000, 880), (800, 795), 70, 55),       # hour-hand shadow
        strip_poly((1120, 800), (1300, 745), 55, 45),      # minute-hand shadow
    ]
    ellipses = [
        (940, 768, 105, 75),    # hour-hand S-curl cluster
        (1105, 782, 85, 60),    # minute-hand curl
        (1240, 715, 55, 45),    # minute arrowhead
        (1055, 850, 100, 100),  # centre boss + hand bases (synthetic boss covers)
        (1290, 655, 85, 80),    # minute shadow remnant upper right
        (1150, 950, 95, 65),    # soft shadow lower right of boss
    ]
    # Q3 (user decision 2026-07-08): the D5 cuckoo is REMOVED. Only the inert numeral-ring
    # face (cu-clock-unspent) is staged now; the cuckoo pop/spent states (cu-clock-pop /
    # cu-clock-spent) are NO LONGER shipped, so no leftover cuckoo close-up can be reached
    # (R3-005 cleanup: those stale plates sat in the bundle unreferenced by code).
    for name in ("cu-clock-unspent",):
        im = load(f"z1/v-hearth/{name}@3x.png")
        mask = polygon_mask(im.size, polys, ellipses)
        fixed = inpaint(im, mask, blur=3.5, noise=6, recolor=True)
        save_plate(fixed, f"z1/v-hearth/{name}.jpg")
        report.append(f"inpaint hands  -> z1/v-hearth/{name}.jpg")

    # NOTE (implementation-notes): no emptied-container close-up is generated for the
    # spoon drawer or ingredient cabinet -- inpaint quality was not shippable there.
    # Instead those close-ups become inert once their item is collected.

    # --- z1 hearth rug/trapdoor chain (build-3 consistency re-roll, 2026-07-09) ---
    # SUPERSEDES the earlier build-3 gap-G1 synthetic derivation: the Asset agent now ships
    # a REAL rug-moved wide plate (z1-hearth-rug-moved-nb, folded rug + CLOSED trapdoor +
    # ring pull), a true 4K region-edit of z1-hearth-base and pixel-aligned with both it and
    # z1-hearth-trapdoor-open-nb. We no longer inpaint the lid out of trapdoor-open; we load
    # the real plate directly. The wide state machine (ov-rug-moved -> ov-trapdoor-open)
    # already exists in RoomSceneCoordinator; only the overlay SOURCE improves.
    rug_moved = load("z1/v-hearth/z1-hearth-rug-moved@3x.png").convert("RGB")  # resolves -nb
    extras["z1/v-hearth#rug-moved"] = rug_moved
    # Persist a full plate too, so ov-trapdoor-open can diff trapdoor-open against it.
    save_plate(rug_moved, "z1/v-hearth/z1-hearth-rug-moved.jpg")
    report.append("stage real rug-moved -> z1/v-hearth/z1-hearth-rug-moved.jpg (re-roll G1)")

    # --- cu-astrolabe-drawer-open -> empty ---
    im = load("z2/v-cabinet/cu-astrolabe-drawer-open@3x.png")
    mask = polygon_mask(im.size,
                        polys=[[(725, 1225), (1430, 1225), (1430, 1392), (725, 1392)]],
                        ellipses=[(830, 1300, 125, 82)])
    fixed = inpaint(im, mask, blur=4.0, noise=5, seed=12)
    save_plate(fixed, "z2/v-cabinet/cu-astrolabe-drawer-empty.jpg")
    report.append("inpaint drawer -> z2/v-cabinet/cu-astrolabe-drawer-empty.jpg")

    # --- z1 wide: poker removed, SYNTHESIZED from the base (R5-001, build 11) ---
    # ROOT CAUSE of the "misplaced fireplace fragment" (R4-004 -> R5-001): the manifest-
    # current z1-hearth-poker-taken plate's generative REMOVE-the-poker edit filled the
    # poker area with a +240 px-shifted CLONE of the fireplace interior (a second
    # andiron + duplicated grate). The plate pixel-REGISTERS with the base perfectly
    # (edge-ring diff < 1 grey level), so build 10's auto-diff cropped it faithfully and
    # the runtime composited it exactly where the rect says — perfectly registered wrong
    # art. The runtime compositor was verified equal to the offline composite; the
    # defect lives in the source plate. Until the Asset agent re-delivers that plate,
    # the poker-taken state is synthesized here by inpainting the poker (tapered handle,
    # thin rod, J-hook) out of the base directly — the same mechanism as the clock-hands
    # / spoon / cabinet-shelf erasures above. Geometry measured off the re-framed base.
    base_hearth = load("z1/v-hearth/z1-hearth-base@3x.png").convert("RGB")
    poker_polys = [
        strip_poly((1057, 1085), (1102, 1520), 16, 15),  # rod, leaning slightly right
        strip_poly((1102, 1500), (1052, 1588), 17, 16),  # hook: lower sweep
        strip_poly((1052, 1588), (1012, 1533), 15, 13),  # hook: tip curling up-left
    ]
    poker_ellipses = [
        (1057, 1040, 30, 68),   # tapered wooden handle
        (1075, 1580, 78, 34),   # hook curve + contact shadow on the hearth ledge
        (1122, 1583, 38, 36),   # hook's rightmost tip resting on the ledge
    ]
    pmask = polygon_mask(base_hearth.size, poker_polys, poker_ellipses, grow=4)
    extras["z1/v-hearth#poker-taken"] = inpaint(base_hearth, pmask, blur=3.0, noise=5, seed=21)
    report.append("inpaint poker  -> wide hearth poker-taken (overlay source, R5-001)")

    # --- z3 wide: drawer-open without spoon (build-10 re-framed coords) ---
    # The spoon sits on the open drawer bottom in the RE-FRAMED z3-cellar-drawer-open
    # plate at ~px (2130..2300, 790..875); mask + inpaint clean wood over it.
    im = load("z3/v-cellar/z3-cellar-drawer-open@3x.png")
    mask = polygon_mask(im.size, polys=[[(2130, 790), (2300, 790), (2300, 878), (2130, 878)]])
    extras["z3/v-cellar#drawer-empty"] = inpaint(im, mask, blur=2.5, noise=5, seed=14)
    report.append("inpaint spoon  -> wide drawer-empty (overlay source, re-framed)")

    # --- z2 wide: cabinet open without file+phial (build-10 re-framed coords) ---
    # File (knife) + phial sit on the middle shelf of the RE-FRAMED z2-cabinet-open plate
    # at ~px (1750..2090, 780..1080).
    im = load("z2/v-cabinet/z2-cabinet-open@3x.png")
    mask = polygon_mask(im.size, polys=[[(1750, 780), (2090, 780), (2090, 1080), (1750, 1080)]])
    extras["z2/v-cabinet#cab-open-empty"] = inpaint(im, mask, blur=2.5, noise=5, seed=16)
    report.append("inpaint shelf  -> wide cab-open-empty (overlay source, re-framed)")

    return extras


# --------------------------------------------------------------- chrome art

def gen_clock_hands():
    """Synthetic clock hands (RGBA), pivot at canvas centre, pointing up."""
    def hand(length, base_w, tip_w, tail, fname):
        S = 2 * (length + 60)
        im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
        d = ImageDraw.Draw(im)
        cx = cy = S // 2
        dark = (30, 27, 24, 255)
        lite = (74, 66, 58, 255)
        # tail
        d.polygon([(cx - base_w * 0.55, cy), (cx + base_w * 0.55, cy),
                   (cx + base_w * 0.35, cy + tail), (cx - base_w * 0.35, cy + tail)],
                  fill=dark)
        # shaft
        d.polygon([(cx - base_w, cy), (cx + base_w, cy),
                   (cx + tip_w, cy - length), (cx - tip_w, cy - length)], fill=dark)
        # spade ornament at 62% length
        oy = cy - length * 0.62
        ow = base_w * 2.1
        d.polygon([(cx, oy - ow * 1.4), (cx + ow, oy), (cx, oy + ow * 1.4), (cx - ow, oy)],
                  fill=dark)
        d.ellipse((cx - ow * 0.42, oy - ow * 0.42, cx + ow * 0.42, oy + ow * 0.42),
                  fill=(0, 0, 0, 0))
        # tip
        d.polygon([(cx - tip_w * 1.8, cy - length), (cx + tip_w * 1.8, cy - length),
                   (cx, cy - length - tip_w * 6)], fill=dark)
        # sheen line
        d.line([(cx - 2, cy - 8), (cx - 2, cy - length + 10)], fill=lite, width=3)
        # boss
        d.ellipse((cx - base_w * 1.9, cy - base_w * 1.9, cx + base_w * 1.9, cy + base_w * 1.9),
                  fill=dark)
        d.ellipse((cx - base_w * 0.8, cy - base_w * 0.8, cx + base_w * 0.8, cy + base_w * 0.8),
                  fill=lite)
        im.save(os.path.join(ensure(CHROME_OUT), fname), "PNG")

    hand(430, 26, 10, 90, "clock-hand-hour.png")
    hand(560, 22, 8, 110, "clock-hand-minute.png")


def gen_pause_glyph():
    """Engraved-rune pause glyph (placeholder until bespoke art exists)."""
    S = 300
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    bone = (242, 245, 248, 255)
    d.ellipse((10, 10, S - 10, S - 10), outline=bone, width=10)
    # twin runic staves with cross-cuts
    for x in (S * 0.40, S * 0.60):
        d.line([(x, S * 0.28), (x, S * 0.72)], fill=bone, width=14)
    d.line([(S * 0.34, S * 0.34), (S * 0.46, S * 0.28)], fill=bone, width=8)
    d.line([(S * 0.54, S * 0.72), (S * 0.66, S * 0.66)], fill=bone, width=8)
    im.save(os.path.join(ensure(CHROME_OUT), "pause-rune.png"), "PNG")


def keyhole_path(d, cx, cy, r, stem_h, stem_w, fill):
    d.ellipse((cx - r, cy - r, cx + r, cy + r), fill=fill)
    d.polygon([(cx - stem_w * 0.45, cy + r * 0.55),
               (cx + stem_w * 0.45, cy + r * 0.55),
               (cx + stem_w, cy + r * 0.55 + stem_h),
               (cx - stem_w, cy + r * 0.55 + stem_h)], fill=fill)


def gen_emblem():
    S = 800
    im = Image.new("RGBA", (S, S), (0, 0, 0, 0))
    d = ImageDraw.Draw(im)
    keyhole_path(d, S / 2, S * 0.38, S * 0.17, S * 0.34, S * 0.10, (255, 255, 255, 255))
    im.save(os.path.join(ensure(CHROME_OUT), "keyhole-emblem.png"), "PNG")


def gen_app_icon():
    """PLACEHOLDER app icon (keyhole in dark wood) until the approved art lands."""
    S = 1024
    rng = random.Random(3)
    im = Image.new("RGB", (S, S), (26, 23, 20))
    d = ImageDraw.Draw(im)
    # wood grain streaks
    for _ in range(140):
        x = rng.randint(0, S)
        w = rng.randint(2, 6)
        shade = rng.randint(-8, 8)
        col = (26 + shade, 23 + shade, 20 + shade)
        d.line([(x, 0), (x + rng.randint(-30, 30), S)], fill=col, width=w)
    im = im.filter(ImageFilter.GaussianBlur(2))
    d = ImageDraw.Draw(im)
    # warm glow behind keyhole
    glow = Image.new("RGB", (S, S), (0, 0, 0))
    gd = ImageDraw.Draw(glow)
    keyhole_path(gd, S / 2, S * 0.40, S * 0.155, S * 0.30, S * 0.09, (217, 151, 63))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    im = ImageChops.add(im, glow)
    d = ImageDraw.Draw(im)
    # brass escutcheon ring
    cx, cy, r = S / 2, S * 0.40, S * 0.155
    plate_r = S * 0.30
    d.ellipse((cx - plate_r, cy - plate_r * 0.85, cx + plate_r, cy + plate_r * 1.45),
              outline=(140, 114, 58), width=14)
    # keyhole (lit interior)
    hole = Image.new("RGB", (S, S), (0, 0, 0))
    hd = ImageDraw.Draw(hole)
    keyhole_path(hd, cx, cy, r, S * 0.29, S * 0.085, (232, 176, 90))
    hole = hole.filter(ImageFilter.GaussianBlur(3))
    im = ImageChops.lighter(im, hole)
    ensure(os.path.join(XCASSETS, "AppIcon.appiconset"))
    im.save(os.path.join(XCASSETS, "AppIcon.appiconset", "AppIcon1024.png"), "PNG")


def gen_thumbnail():
    """R3-002 (build 9): stage the CURRENT build-3 Level-Select thumbnail.

    The thumbnail is authored by the Asset agent and shipped at
    specs/assets/level-1/chrome/level1-thumb.jpg (a build-3 hearth crop, no baked
    level-number — the Roman "I" the user saw was a stale build-2 image). We stage that
    exact file, NOT a re-derived crop, so the manifest-current art is authoritative
    (same canonical-source discipline as the scene plates).

    The app loads the thumbnail via UIImage(named: "level1-thumb") from the ASSET
    CATALOG, so the load-bearing copy is the xcassets imageset. We also drop a copy in
    CHROME_OUT so the stale-shadow guard can cover chrome art (R3-002 follow-up).
    """
    src_thumb = src("chrome/level1-thumb.jpg")
    if not os.path.exists(src_thumb):
        raise SystemExit("R3-002: missing specs/assets/level-1/chrome/level1-thumb.jpg")
    # 1) the app's real load path — the asset catalog imageset
    imageset = os.path.join(XCASSETS, "level1-thumb.imageset")
    ensure(imageset)
    shutil.copyfile(src_thumb, os.path.join(imageset, "level1-thumb.jpg"))
    # 2) a chrome copy the staleness guard checks against the source (assert_chrome_current)
    shutil.copyfile(src_thumb, os.path.join(ensure(CHROME_OUT), "level1-thumb.jpg"))


# ------------------------------------------------------------------- audio

SR = 22050


def write_wav(name, samples):
    p = os.path.join(ensure(AUDIO_OUT), name)
    clipped = bytearray()
    for s in samples:
        v = int(max(-1.0, min(1.0, s)) * 32000)
        clipped += struct.pack("<h", v)
    with wave.open(p, "wb") as w:
        w.setnchannels(1)
        w.setsampwidth(2)
        w.setframerate(SR)
        w.writeframes(bytes(clipped))


def env(i, n, a=0.005, r=0.3):
    """attack/release envelope, times in fraction of n."""
    at = max(1, int(n * a))
    rt = max(1, int(n * r))
    if i < at:
        return i / at
    if i > n - rt:
        return max(0.0, (n - i) / rt)
    return 1.0


def lp_noise(n, cutoff, seed, gain=1.0):
    """One-pole lowpassed white noise."""
    rng = random.Random(seed)
    a = math.exp(-2 * math.pi * cutoff / SR)
    y = 0.0
    out = []
    for _ in range(n):
        y = a * y + (1 - a) * (rng.uniform(-1, 1))
        out.append(y * gain)
    return out


def sine(n, f0, f1=None, amp=1.0, phase=0.0):
    f1 = f1 if f1 is not None else f0
    out = []
    ph = phase
    for i in range(n):
        f = f0 + (f1 - f0) * (i / n)
        ph += 2 * math.pi * f / SR
        out.append(math.sin(ph) * amp)
    return out


def gen_sfx():
    # (feedback round 1: the generic interaction click — the "psh" of F-005/F-009/
    # F-019 — is RETIRED and no longer generated or shipped; every interaction point
    # now uses an object-relevant cue below, or silence.)
    # pickup: two quick soft blips
    n = int(0.16 * SR)
    b1 = sine(n, 660, amp=0.5)
    b2 = sine(n, 990, amp=0.4)
    out = []
    for i in range(n):
        g1 = math.exp(-i / (0.03 * SR))
        j = i - int(0.07 * SR)
        g2 = math.exp(-j / (0.04 * SR)) if j > 0 else 0.0
        out.append((b1[i] * g1 + b2[i] * g2) * 0.6)
    write_wav("sfx-pickup.wav", out)
    # wrong: dull knock
    n = int(0.28 * SR)
    thud = sine(n, 120, 64, 0.9)
    ns = lp_noise(n, 500, 2, 1.6)
    write_wav("sfx-wrong.wav", [(thud[i] + ns[i] * 0.5) * math.exp(-i / (0.05 * SR)) * 0.85
                                for i in range(n)])
    # solve: warm plucked dyad + octave shimmer
    n = int(1.0 * SR)
    c5 = sine(n, 523.25, amp=0.42)
    g5 = sine(n, 784.0, amp=0.34)
    c6 = sine(n, 1046.5, amp=0.16)
    out = []
    for i in range(n):
        g = math.exp(-i / (0.32 * SR))
        go = math.exp(-max(0, i - int(0.12 * SR)) / (0.4 * SR)) if i > int(0.12 * SR) else 0
        out.append((c5[i] + g5[i]) * g * 0.7 + c6[i] * go * 0.5)
    write_wav("sfx-solve.wav", out)
    # zone unlock: stone rumble + soft chime tail
    n = int(1.5 * SR)
    rumble = lp_noise(n, 140, 3, 5.0)
    chime = sine(n, 392, amp=0.22)
    out = []
    for i in range(n):
        sw = math.sin(math.pi * min(1.0, i / (n * 0.6)))
        ct = math.exp(-max(0, i - int(0.8 * SR)) / (0.25 * SR)) if i > int(0.8 * SR) else 0
        out.append(rumble[i] * sw * 0.8 + chime[i] * ct)
    write_wav("sfx-unlock.wav", out)
    # crow refusal: wing-flap snap (three quick air puffs)
    n = int(0.5 * SR)
    ns = lp_noise(n, 900, 4, 3.0)
    out = []
    for i in range(n):
        g = 0.0
        for k, t0 in enumerate((0.02, 0.16, 0.30)):
            j = i - int(t0 * SR)
            if j > 0:
                g += math.exp(-j / (0.025 * SR)) * (1.0 - k * 0.25)
        out.append(ns[i] * g * 0.7)
    write_wav("sfx-refusal.wav", out)
    # cuckoo clack: two dry wooden knocks
    n = int(0.4 * SR)
    ns = lp_noise(n, 2200, 5, 2.4)
    tone = sine(n, 310, amp=0.5)
    out = []
    for i in range(n):
        g = 0.0
        for t0 in (0.02, 0.18):
            j = i - int(t0 * SR)
            if j > 0:
                g += math.exp(-j / (0.02 * SR))
        out.append((ns[i] * 0.8 + tone[i] * 0.6) * g * 0.7)
    write_wav("sfx-clack.wav", out)
    # brew fizzle: hiss decay
    n = int(0.9 * SR)
    ns = lp_noise(n, 3000, 6, 1.8)
    write_wav("sfx-fizzle.wav", [ns[i] * math.exp(-i / (0.3 * SR)) * 0.6 for i in range(n)])

    # ---- feedback round 1 (F-005/F-009/F-019): per-object cues replacing the ----
    # ---- generic interaction click, which is no longer used anywhere.        ----

    # page turn (grimoire/triptych): two overlapping soft paper swishes
    n = int(0.22 * SR)
    ns = lp_noise(n, 1800, 21, 2.2)
    out = []
    for i in range(n):
        g1 = math.sin(math.pi * min(1.0, i / (0.10 * SR))) if i < 0.10 * SR else 0.0
        j = i - int(0.06 * SR)
        g2 = math.sin(math.pi * min(1.0, j / (0.14 * SR))) if 0 < j < 0.14 * SR else 0.0
        out.append(ns[i] * (g1 * 0.5 + g2 * 0.4) * 0.5)
    write_wav("sfx-page.wav", out)
    # stone tile press (rune door): compact stone thunk, higher than sfx-wrong
    n = int(0.22 * SR)
    thud = sine(n, 180, 120, 0.8)
    ns = lp_noise(n, 420, 22, 1.4)
    write_wav("sfx-stone.wav", [(thud[i] + ns[i] * 0.4) * math.exp(-i / (0.06 * SR)) * 0.7
                                for i in range(n)])
    # ratchet tick (dials, clock hand, item seating): tiny dry tick
    n = int(0.08 * SR)
    ns = lp_noise(n, 1400, 23, 2.0)
    tone = sine(n, 520, amp=0.25)
    write_wav("sfx-tick.wav", [(ns[i] * 0.6 + tone[i]) * math.exp(-i / (0.014 * SR)) * 0.5
                               for i in range(n)])
    # mirror detent scrape (stone/iron grind, short)
    n = int(0.35 * SR)
    ns = lp_noise(n, 300, 24, 5.0)
    rough = lp_noise(n, 28, 25, 1.0)
    write_wav("sfx-grind.wav", [ns[i] * (0.5 + 0.5 * abs(rough[i])) * env(i, n, 0.15, 0.35) * 0.5
                                for i in range(n)])
    # bellows air puff (floor bellows + brew pump)
    n = int(0.45 * SR)
    ns = lp_noise(n, 1000, 26, 2.6)
    write_wav("sfx-bellows.wav", [ns[i] * env(i, n, 0.30, 0.50) * 0.55 for i in range(n)])
    # ladle stir swish (also ingredient-into-water)
    n = int(0.5 * SR)
    ns = lp_noise(n, 600, 27, 3.0)
    write_wav("sfx-stir.wav", [ns[i] * math.sin(math.pi * i / n) ** 2 * 0.5 for i in range(n)])
    # rug/cloth slide
    n = int(0.4 * SR)
    ns = lp_noise(n, 800, 28, 2.6)
    write_wav("sfx-cloth.wav", [ns[i] * math.sin(math.pi * min(1.0, i / (n * 0.85))) * 0.45
                                for i in range(n)])
    # (R4-010/012/017/027 / build 10: sfx-wood — the surviving default nav/passage "psh"
    # fired on every zone change + the drawer — is REMOVED. Zone changes announce visually
    # only; the drawer opens silently. No trigger references it anymore.)
    # themed door opening (R2-015a): a low wooden creak that rises then a soft latch
    # clunk — distinct from the stone zone-unlock rumble (sfx-unlock).
    n = int(1.1 * SR)
    creak_ns = lp_noise(n, 320, 41, 3.0)
    groan = sine(n, 90, 140, 0.5)
    out = []
    for i in range(n):
        t = i / SR
        # creak body swells over the first ~0.7s
        body = math.sin(math.pi * min(1.0, t / 0.7)) if t < 0.7 else max(0.0, 1.0 - (t - 0.7) / 0.4)
        # wobble gives the "creak" character
        wob = 0.6 + 0.4 * math.sin(2 * math.pi * 7 * t)
        val = (creak_ns[i] * 0.5 + groan[i]) * body * wob * 0.5
        # latch clunk near the end
        j = i - int(0.82 * SR)
        if j > 0:
            val += math.sin(2 * math.pi * 150 * j / SR) * math.exp(-j / (0.03 * SR)) * 0.5
        out.append(val)
    write_wav("sfx-door.wav", out)
    # ---- R3-001 menu / pre-level chrome SFX (quiet, tasteful; NEVER the psh) ----
    # sfx-seat (build 10 R4-020(1)): warm POSITIVE "item seats into its recess" cue —
    # a soft low wooden settle + a quiet rising major-third confirmation blip, in the
    # register of the liked pickup chime (NOT the removed tick / the dull sfx-wrong).
    n = int(0.42 * SR)
    settle_tone = sine(n, 210, 165, 0.5)
    settle_ns = lp_noise(n, 600, 71, 1.0)
    blip_a = sine(n, 659.3, amp=0.32)
    blip_b = sine(n, 830.6, amp=0.26)
    out = []
    for i in range(n):
        g_settle = math.exp(-i / (0.045 * SR))
        j = i - int(0.06 * SR)
        g_a = math.exp(-j / (0.09 * SR)) if j > 0 else 0.0
        k = i - int(0.13 * SR)
        g_b = math.exp(-k / (0.11 * SR)) if k > 0 else 0.0
        out.append((settle_tone[i] + settle_ns[i] * 0.35) * g_settle * 0.55
                   + blip_a[i] * g_a * 0.55 + blip_b[i] * g_b * 0.55)
    write_wav("sfx-seat.wav", out)
        # menu-confirm: a subtle two-note rising confirm for major actions (Play / enter
    # level) — soft sine dyad (C5 -> G5) with a short warm decay, unobtrusive. ~0.4 s.
    n = int(0.42 * SR)
    a = sine(n, 523.25, amp=0.4)
    b = sine(n, 784.0, amp=0.32)
    out = []
    for i in range(n):
        ga = math.exp(-i / (0.16 * SR))
        j = i - int(0.09 * SR)
        gb = math.exp(-j / (0.18 * SR)) if j > 0 else 0.0
        out.append((a[i] * ga + b[i] * gb) * 0.4)
    write_wav("sfx-menu-confirm.wav", out)

    # (R4-002/build 10: sfx-entry — the reported "ocean waves at level entry" —
    # is REMOVED. Level audio is the user-supplied music-level1.wav only.)


def loopable(samples, fade=1.0):
    """Crossfade tail into head for a seamless loop."""
    nf = int(fade * SR)
    n = len(samples)
    out = samples[:n - nf]
    for i in range(nf):
        t = i / nf
        out.append(samples[n - nf + i] * (1 - t) + samples[i] * t)
    # note: result length n; loop point at start
    return out


def gen_ambients():
    # Feedback round 1 (F-002): the ambient beds are re-synthesized MUCH quieter and
    # sparser — the neutralxe register. The level-entry weather beat lives in
    # sfx-entry; these loops are near-silence with occasional texture (long quiet
    # stretches, sparse events), and SoundManager additionally plays them at a lower
    # volume than build 1. z1's constant rain-like wind bed (the direct subject of
    # F-002) is gone entirely — replaced by two brief, soft wind swells per 24 s.
    dur = 24
    n = dur * SR
    # z1 cabin: two soft wind swells over near-silence
    base = lp_noise(n + SR, 300, 10, 4.0)
    out = []
    for i in range(n + SR):
        t = (i % n) / SR
        g = 0.0
        for t0, ln in ((4.0, 5.0), (15.0, 4.0)):
            if t0 <= t < t0 + ln:
                g += math.sin(math.pi * (t - t0) / ln) ** 2
        out.append(base[i] * (0.010 + 0.055 * g))
    write_wav("amb-z1.wav", loopable(out))
    # z2 workshop: sparse faint ember pops + very low hum, no noise bed
    hum = sine(n + SR, 98, amp=0.012)
    rng = random.Random(20)
    pops = [0.0] * (n + SR)
    for _ in range(24):
        t = rng.randint(0, n - 1)
        ln = rng.randint(60, 240)
        amp = rng.uniform(0.05, 0.16)
        for j in range(ln):
            if t + j < len(pops):
                pops[t + j] += math.exp(-j / 40.0) * amp * rng.uniform(-1, 1)
    out = [pops[i] + hum[i] for i in range(n + SR)]
    write_wav("amb-z2.wav", loopable(out))
    # z3 cellar: whisper 55 Hz drone + three sparse drips
    drone = sine(n + SR, 55, amp=0.020)
    rng = random.Random(30)
    drips = [0.0] * (n + SR)
    for t0 in (5.2, 13.6, 20.9):
        t = int(t0 * SR)
        f = rng.uniform(1400, 2100)
        for j in range(int(0.09 * SR)):
            if t + j < len(drips):
                drips[t + j] += math.sin(2 * math.pi * f * j / SR) \
                    * math.exp(-j / (0.012 * SR)) * 0.10
    out = [drone[i] * (0.7 + 0.3 * math.sin(2 * math.pi * 2 * i / n)) + drips[i]
           for i in range(n + SR)]
    write_wav("amb-z3.wav", loopable(out))
    # z4 alcove: faint reverent triad with slow beating, barely-there air
    t1 = sine(n + SR, 196.0, amp=0.014)
    t2 = sine(n + SR, 294.3, amp=0.011)
    t3 = sine(n + SR, 392.4, amp=0.008)
    air = lp_noise(n + SR, 1200, 13, 0.5)
    out = [(t1[i] + t2[i] + t3[i]) * (0.7 + 0.3 * math.sin(2 * math.pi * 4 * i / n))
           + air[i] * 0.006 for i in range(n + SR)]
    write_wav("amb-z4.wav", loopable(out))


# -------------------------------------------------------------------- main

def main():
    report = []
    assert_no_nb_shadow()  # build-3 stale-shadow anti-recurrence guard (fails loud)
    if os.path.isdir(OUT):
        shutil.rmtree(OUT)
    ensure(OUT)

    print("== 1/6 plain plates ==", flush=True)
    for rel in PLAIN_PLATES:
        im = load(rel)
        save_plate(im, rel.replace("@3x.png", ".jpg"))
    print(f"   {len(PLAIN_PLATES)} plates")

    print("== 2/6 sprites + icons + records ==", flush=True)
    for rel in RGBA_SPRITES + ICONS:
        im = Image.open(src(rel))
        save_png(im, rel.replace("@3x.png", ".png"))
    for rel in SPRITE_JSONS:
        p = out_path(rel)
        shutil.copyfile(src(rel), p)

    print("== 3/6 inpainted variants ==", flush=True)
    extras = build_inpainted(report)

    print("== 4/6 diff overlays ==", flush=True)
    overlays = {}
    base_cache = {}
    for spec in OVERLAYS:
        (view, base, var, name, dim), clamp = spec[:5], (spec[5] if len(spec) > 5 else None)
        bkey = f"{view}/{base}"
        if bkey not in base_cache:
            base_cache[bkey] = load(f"{view}/{base}@3x.png").convert("RGB")
        base_im = base_cache[bkey]
        var_im = load(f"{view}/{var}@3x.png")
        res = diff_overlay(base_im, var_im, clamp=clamp)
        if res is None:
            print(f"   !! no diff for {name}")
            continue
        bbox, crop = res
        # R5-001 guard: a variant whose fill is a misplaced clone of scene content
        # composites as a perfectly registered WRONG fragment — refuse to ship it.
        assert_no_misplaced_clone_fill(base_im, var_im, bbox, name)
        rel = f"{view}/overlays/{name}.jpg"
        save_plate(crop, rel)
        w, h = base_im.size
        entry = {"file": rel, "rect": [bbox[0] / w, bbox[1] / h,
                                       (bbox[2] - bbox[0]) / w, (bbox[3] - bbox[1]) / h]}
        if dim:
            beam = load("z3/v-cellar/z3-cellar-beam-floor@3x.png")
            gain = ring_gain(base_im, beam, bbox)
            dim_crop = apply_gain(crop, gain)
            drel = f"{view}/overlays/{name}-dim.jpg"
            save_plate(dim_crop, drel)
            entry["dimFile"] = drel
            entry["dimGain"] = round(gain, 3)
        overlays.setdefault(view, {})[name] = entry
        print(f"   {name}: bbox={bbox}")

    # Manual hand-rect overlays (gap G3): crop each state's element region out of the
    # size-matched variant and composite. The variant differs globally from the base, so
    # we only take the intended element rect. Overlay texture feathering (SpriteKit side)
    # softens the crop seam; a small tonal patch may remain (flagged, same class as the
    # old ov-adrawer note). The rect goes straight into overlays.json.
    for view, var, name, rect, dim, legacy in MANUAL_OVERLAYS:
        base_im = load(MANUAL_OVERLAY_BASE[view]).convert("RGB")
        w, h = base_im.size
        var_im = load(f"{view}/{var}@3x.png").convert("RGB")
        if var_im.size != base_im.size:
            var_im = var_im.resize(base_im.size, Image.LANCZOS)
        store = reframe_rect(view, rect)          # overlays.json rect (re-framed space)
        # Legacy 2560 plate: its content is at the OLD framing, so crop at the OLD rect
        # and let SpriteKit scale that crop into the smaller remapped rect on the
        # re-framed base. Re-framed source: crop directly at the remapped rect.
        crop_rect = rect if legacy else store
        nx, ny, nw, nh = store
        cx0, cy0 = int(crop_rect[0] * w), int(crop_rect[1] * h)
        cx1, cy1 = int((crop_rect[0] + crop_rect[2]) * w), int((crop_rect[1] + crop_rect[3]) * h)
        crop = var_im.crop((cx0, cy0, cx1, cy1))
        rel = f"{view}/overlays/{name}.jpg"
        save_plate(crop, rel)
        entry = {"file": rel, "rect": [nx, ny, nw, nh]}
        overlays.setdefault(view, {})[name] = entry
        print(f"   {name} (manual, legacy={legacy}): store_rect=({nx:.3f},{ny:.3f},{nw:.3f},{nh:.3f})")

    # Emptied-container overlays (gap G3): inpainted from the 2560 variants, so crop by the
    # SAME hand-rect as their filled counterparts (the empty state shows the same element
    # region, now without the item). rect (view, extras-key, name, filled-rect, dim).
    # + R5-001 (build 11): ov-poker-taken is now sourced from the base-derived inpaint
    # extra (see build_inpainted) instead of the defective clone-fill variant plate; the
    # auto-diff against the base self-locates the tight poker region exactly like the
    # emptied-container overlays. (Synthesized-from-base extras cannot clone-shift, so
    # the misplaced-clone guard applies only to the variant-plate loop above.)
    for view, ekey, name in [
        ("z1/v-hearth", "z1/v-hearth#poker-taken", "ov-poker-taken"),
        ("z3/v-cellar", "z3/v-cellar#drawer-empty", "ov-drawer-empty"),
        ("z2/v-cabinet", "z2/v-cabinet#cab-open-empty", "ov-cab-open-empty"),
    ]:
        base_im = load(MANUAL_OVERLAY_BASE[view]).convert("RGB")
        w, h = base_im.size
        ex = extras[ekey].convert("RGB")
        if ex.size != base_im.size:
            ex = ex.resize(base_im.size, Image.LANCZOS)
        # Auto-diff the inpainted-empty extra against the (closed) base: this self-locates
        # the opened-drawer / opened-cabinet region, so the empty overlay rect matches its
        # auto-diff'd filled counterpart exactly (re-framed space).
        res = diff_overlay(base_im, ex)
        if res is None:
            print(f"   !! no diff for {name}")
            continue
        bbox, crop = res
        rel = f"{view}/overlays/{name}.jpg"
        save_plate(crop, rel)
        overlays.setdefault(view, {})[name] = {
            "file": rel,
            "rect": [bbox[0] / w, bbox[1] / h, (bbox[2] - bbox[0]) / w, (bbox[3] - bbox[1]) / h],
        }
        print(f"   {name} (empty, auto): bbox={bbox}")

    # z1 hearth rug/trapdoor chain overlays (build-3 consistency re-roll, 2026-07-09).
    # The real re-rolled 4K plates (z1-hearth-rug-moved-nb, z1-hearth-trapdoor-open-nb) are
    # nano-banana region-edits of z1-hearth-base and — like the other build-3 wide variants
    # (gap G3) — carry global tonal drift, so a full-frame diff trips everywhere (verified:
    # bbox = whole frame even at threshold 90). We therefore HAND-CROP each state's changed
    # floor region (measured from the plates: the folded rug + exposed closed trapdoor for
    # rug-moved; the raised lid + open hole + haze for trapdoor-open) and composite it over
    # its background, exactly like MANUAL_OVERLAYS. This keeps the two-step wide state chain
    # (base -> ov-rug-moved -> ov-trapdoor-open) that RoomSceneCoordinator already drives;
    # only the intended lower-floor region is replaced. Rects cover the rug hotspot
    # (0.14,0.72,0.56,0.28) / trapdoor-dial hotspot (0.23,0.72,0.39,0.25) footprints.
    hearth_base = base_cache.get("z1/v-hearth/z1-hearth-base") \
        or load("z1/v-hearth/z1-hearth-base@3x.png").convert("RGB")
    rug_moved_im = extras["z1/v-hearth#rug-moved"]  # real re-rolled plate (see build_inpainted)
    trapdoor_open_im = load("z1/v-hearth/z1-hearth-trapdoor-open@3x.png").convert("RGB")
    hw, hh = hearth_base.size
    for name, var_im, (nx, ny, nw, nh) in [
        # base -> rug folded aside revealing the closed trapdoor + ring pull
        ("ov-rug-moved",     rug_moved_im,     reframe_rect("z1/v-hearth", (0.14, 0.70, 0.60, 0.30))),
        # locked -> lid thrown open (raised planks + hole + rising haze)
        ("ov-trapdoor-open", trapdoor_open_im, reframe_rect("z1/v-hearth", (0.30, 0.68, 0.44, 0.32))),
    ]:
        vim = var_im if var_im.size == hearth_base.size else var_im.resize(hearth_base.size, Image.LANCZOS)
        px0, py0 = int(nx * hw), int(ny * hh)
        px1, py1 = int((nx + nw) * hw), int((ny + nh) * hh)
        crop = vim.crop((px0, py0, px1, py1))
        rel = f"z1/v-hearth/overlays/{name}.jpg"
        save_plate(crop, rel)
        overlays.setdefault("z1/v-hearth", {})[name] = {"file": rel, "rect": [nx, ny, nw, nh]}
        print(f"   {name} (manual): rect=({nx},{ny},{nw},{nh})")

    with open(out_path("overlays.json"), "w") as f:
        json.dump(overlays, f, indent=1, sort_keys=True)

    print("== 5/6 chrome art ==", flush=True)
    gen_clock_hands()
    gen_pause_glyph()
    gen_emblem()
    gen_app_icon()
    gen_thumbnail()

    print("== 6/6 audio ==", flush=True)
    gen_sfx()
    # (R4-002/build 10: gen_ambients removed — no per-zone amb-z* beds ship.)

    # R3-002: fail loudly if chrome art (the Level-Select thumbnail) shipped stale.
    assert_chrome_current()

    print("\n".join(report))
    print("DONE")


if __name__ == "__main__":
    main()
