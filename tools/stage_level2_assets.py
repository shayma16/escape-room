#!/usr/bin/env python3
"""Stage the CURRENT Level-2 art from specs/assets/level-2 into the app bundle
(EscapeRoom/Resources/GameAssets/level-2), plus the 4 state-overlay JSONs, the two
new functional SFX, and the Level-2 select thumbnail.

Asset-staging directive (user, 2026-07-09): never ship a stale shadow. This script
resolves every canonical asset to exactly one source (the manifest-current file living in
the main asset tree, never _rejects/ or a *-b2pre/-preglyph/-r1 variant), strips the @Nx
scale suffix so the canonical filename == current art, and refuses to stage if two sources
would collide onto one canonical name. It writes staged-manifest.json (canonical name ->
source + sha256) which a CI unit test (Level2AssetStagingTests) reloads to FAIL LOUDLY if a
manifest-current asset is ever shadowed by an out-of-date file.

Scale policy: wides @2x (2560x1280 == scene 2:1), close-ups @3x (2048x1536), overlays @3x
(only scale produced), inventory icons @2x. Sprites/props/glyph masters are NOT staged (the
current presentation renders interactive controls in SwiftUI, not from sprite sheets) — a
documented follow-up for animation polish.
"""
import glob, hashlib, json, math, os, re, shutil, struct, wave

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
SRC = os.path.join(ROOT, "specs", "assets", "level-2")
DEST = os.path.join(ROOT, "EscapeRoom", "Resources", "GameAssets", "level-2")
AUDIO = os.path.join(ROOT, "EscapeRoom", "Resources", "Audio")
XCASSETS = os.path.join(ROOT, "EscapeRoom", "Resources", "Assets.xcassets")

SHADOW_MARKERS = ("-b2pre", "-b3pre", "-b4pre", "-preglyph", "-r1", "-r2", "-rawfix",
                  "-rawgen", "-superseded", "-smear", "-fixraw", "-styleref", "before-after",
                  "review", "design-ref", "contract-gate", "warpfix", "stampfix", "ringfix",
                  "paintover", "dialfix", "framefix", "wheelfix", "safezone", "hatchcomposite")


def sha256(path):
    h = hashlib.sha256()
    with open(path, "rb") as f:
        for chunk in iter(lambda: f.read(1 << 16), b""):
            h.update(chunk)
    return h.hexdigest()


def canonical(name):
    """Strip a trailing @1x/@2x/@3x scale suffix -> canonical base name."""
    return re.sub(r"@[123]x$", "", name)


def collect():
    """Return list of (source_abs, dest_rel) for every canonical asset to stage."""
    plans = []

    def add(pattern, scale):
        for p in glob.glob(os.path.join(SRC, pattern)):
            rel = os.path.relpath(p, SRC)
            if "_rejects" in rel.split(os.sep):
                continue
            base = os.path.splitext(os.path.basename(p))[0]
            if any(m in base for m in SHADOW_MARKERS):
                continue
            if not base.endswith("@%dx" % scale):
                continue
            dest_base = canonical(base) + ".png"
            dest_rel = os.path.join(os.path.dirname(rel), dest_base)
            plans.append((p, dest_rel))

    add("z*/v-*/z*-base@2x.png", 2)          # wide base plates
    add("z*/v-*/z1-door-win-open@2x.png", 2)  # z1 win plate
    add("z*/v-*/cu-*@3x.png", 3)              # close-ups
    # Only the WIDE overlay crops (-wide) are composited onto the wide scenes; the CU-only
    # overlay variants are unused by the current presentation AND one of them (ov-key-taken)
    # would collide by basename with a Level-1 overlay in the shared loader index. Staging
    # only the -wide variants keeps every L2 overlay name globally unique (collision-free).
    add("z*/v-*/states/ov-*-wide@3x.png", 3)  # per-element WIDE state overlays
    add("z*/icons/inv-*@2x.png", 2)           # inventory cutouts
    return plans


def write_wav(path, samples, rate=44100):
    with wave.open(path, "w") as w:
        w.setnchannels(1); w.setsampwidth(2); w.setframerate(rate)
        frames = bytearray()
        for s in samples:
            v = max(-1.0, min(1.0, s))
            frames += struct.pack("<h", int(v * 32000))
        w.writeframes(bytes(frames))


def synth_sfx():
    """Original synthesized functional cues (no third-party audio, commercial-safe).
    NEVER a 'psh' whoosh/hiss (hard user rule) — creak is a low woody groan, chime a soft
    struck-bell decay."""
    os.makedirs(AUDIO, exist_ok=True)
    rate = 44100
    # sfx-creak: short low woody groan with slow amplitude wobble (D10 pry faint-tell).
    n = int(0.34 * rate); creak = []
    for i in range(n):
        t = i / rate
        env = math.sin(math.pi * i / n) ** 1.5
        wob = 1 + 0.06 * math.sin(2 * math.pi * 7 * t)
        s = 0.5 * math.sin(2 * math.pi * 150 * wob * t) + 0.25 * math.sin(2 * math.pi * 92 * t)
        creak.append(0.6 * env * s)
    write_wav(os.path.join(AUDIO, "sfx-creak.wav"), creak, rate)
    # sfx-chime: soft struck bell (two partials, exp decay) for the strike-train release.
    n = int(1.1 * rate); chime = []
    for i in range(n):
        t = i / rate
        env = math.exp(-3.0 * t)
        s = 0.6 * math.sin(2 * math.pi * 660 * t) + 0.3 * math.sin(2 * math.pi * 990 * t) \
            + 0.15 * math.sin(2 * math.pi * 1320 * t)
        chime.append(0.7 * env * s)
    write_wav(os.path.join(AUDIO, "sfx-chime.wav"), chime, rate)


def make_thumb(manifest_srcs):
    """Level-2 select-card thumbnail: a center crop of the z1-door wide, 440x330."""
    try:
        from PIL import Image
    except ImportError:
        return
    src = os.path.join(SRC, "z1", "v-door", "z1-door-base@2x.png")
    if not os.path.exists(src):
        return
    im = Image.open(src).convert("RGB")
    w, h = im.size
    target = 440 / 330
    cw = min(w, int(h * target)); ch = int(cw / target)
    left = (w - cw) // 2; top = (h - ch) // 2
    im = im.crop((left, top, left + cw, top + ch)).resize((440, 330))
    d = os.path.join(XCASSETS, "level2-thumb.imageset")
    os.makedirs(d, exist_ok=True)
    im.save(os.path.join(d, "level2-thumb.jpg"), quality=85)
    with open(os.path.join(d, "Contents.json"), "w") as f:
        json.dump({"images": [{"idiom": "universal", "filename": "level2-thumb.jpg"}],
                   "info": {"version": 1, "author": "xcode"}}, f, indent=2)


def main():
    if os.path.isdir(DEST):
        shutil.rmtree(DEST)
    os.makedirs(DEST, exist_ok=True)

    plans = collect()
    by_canonical = {}
    manifest = {}
    for src, dest_rel in plans:
        cname = os.path.basename(dest_rel)
        if cname in by_canonical and by_canonical[cname] != src:
            raise SystemExit("SHADOW COLLISION: two sources map to %s:\n  %s\n  %s"
                             % (cname, by_canonical[cname], src))
        by_canonical[cname] = src
        dest_abs = os.path.join(DEST, dest_rel)
        os.makedirs(os.path.dirname(dest_abs), exist_ok=True)
        shutil.copy2(src, dest_abs)
        manifest[cname] = {"source": os.path.relpath(src, ROOT).replace(os.sep, "/"),
                           "sha256": sha256(dest_abs)}

    # State-overlay rect JSONs -> flat under level-2/ (loader subdirectory).
    for zone in ["z1", "z2", "z3", "z4"]:
        s = os.path.join(SRC, zone, "%s-state-overlays.json" % zone)
        shutil.copy2(s, os.path.join(DEST, "%s-state-overlays.json" % zone))

    with open(os.path.join(DEST, "staged-manifest.json"), "w") as f:
        json.dump({"count": len(manifest), "assets": manifest}, f, indent=1, sort_keys=True)

    synth_sfx()
    make_thumb(manifest)
    print("staged %d canonical Level-2 assets + 4 JSONs + 2 SFX + thumb" % len(manifest))


if __name__ == "__main__":
    main()
