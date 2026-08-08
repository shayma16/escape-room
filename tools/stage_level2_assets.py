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

    def add(pattern, scale, suffix="", exclude=()):
        """Stage every @<scale>x source matching `pattern`.

        `suffix` is appended to the canonical (scale-stripped) name. It is used for exactly
        one family — the CLOSE-UP state-overlay crops, staged as `<key>-cu.png` — because the
        shared GameAssetLoader indexes by BASENAME across all levels and the raw CU names
        (e.g. `ov-key-taken`) collide with Level-1 overlays. The mapping is 1:1 and
        deterministic, recorded in staged-manifest.json (name -> source + sha256), and any
        two sources landing on one canonical name still hard-fail in main() below, so the
        "canonical filename == current art" guarantee is preserved.
        """
        for p in glob.glob(os.path.join(SRC, pattern)):
            rel = os.path.relpath(p, SRC)
            if "_rejects" in rel.split(os.sep):
                continue
            base = os.path.splitext(os.path.basename(p))[0]
            if any(m in base for m in SHADOW_MARKERS):
                continue
            if any(m in base for m in exclude):
                continue
            if not base.endswith("@%dx" % scale):
                continue
            dest_base = canonical(base) + suffix + ".png"
            dest_rel = os.path.join(os.path.dirname(rel), dest_base)
            plans.append((p, dest_rel))

    def add_raw(pattern, dest_dir):
        """Stage un-scaled canonical masters (the glyph dies) verbatim."""
        for p in sorted(glob.glob(os.path.join(SRC, pattern))):
            rel = os.path.relpath(p, SRC)
            if "_rejects" in rel.split(os.sep):
                continue
            base = os.path.splitext(os.path.basename(p))[0]
            if any(m in base for m in SHADOW_MARKERS):
                continue
            plans.append((p, os.path.join(dest_dir, base + ".png")))

    add("z*/v-*/z*-base@2x.png", 2)          # wide base plates
    add("z*/v-*/z1-door-win-open@2x.png", 2)  # z1 win plate
    add("z*/v-*/cu-*@3x.png", 3)              # close-ups
    add("z*/v-*/states/ov-*-wide@3x.png", 3)  # per-element WIDE state overlays
    # ROUND 8 CLUSTER A: the CLOSE-UP overlay crops. These were authored in batch 2/3 and
    # then never staged, which is why every L2 close-up rendered a single static plate while
    # the wide view composited correctly (R8-002/004/009/010/011/012/013). Staged with a
    # `-cu` suffix (see add()'s docstring) so the loader's basename index stays collision-free.
    add("z*/v-*/states/ov-*@3x.png", 3, suffix="-cu", exclude=("-wide",))
    add("z*/icons/inv-*@2x.png", 2)           # inventory cutouts
    # Rack-gear cutouts: the p06 gear picker renders the REAL gear art instead of the old
    # Text("16")/Text("24") buttons (near-wordless ruling, round 8 fix 6).
    add("z2/props/gear-*@2x.png", 2)
    # z3 CLOCKWORK SPRITES (build 17 / R8-020, user ruling at GATE 1). The great dial's hands
    # and the pendulum are no longer drawn procedurally (SwiftUI capsules / an SKShapeNode rod
    # + bob): they render from the AUTHORED sprite art, anchored on the authored pivots. The
    # hour hand additionally doubles as the wordless ring pointer on the ⌂/⚙ ring clue
    # close-ups (round 8 fix 5, p03/p04 clue legibility).
    # REV 1.4.1 (D13): the canonical chalk tally-stroke sprites the Developer draws the
    # LIVE crank-tally block from (full stroke, V17 partial stroke, group-closing strike).
    # Geometry/pivots/pitch travel with them in tally-sprites.json, copied below.
    add("z2/v-frame/sprites/sp-tally-*@3x.png", 3)
    add("z3/v-dial/sprites/hand-hour@3x.png", 3)
    add("z3/v-dial/sprites/hand-minute@3x.png", 3)
    add("z3/v-dial/sprites/sp-pendulum@3x.png", 3)
    # Landmark dies: the p07 vault wheel headers are pictogram matches per the graph
    # (clu-worldclock-row: "landmark identification is NOT required"), replacing the old
    # "Big Ben"/"Burj"/"Liberty"/"Fuji" word labels.
    add_raw("masters/glyphs/die-*.png", "masters")
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
    # Cat facial-key rects (R8-011(1): the rev-1.3 mouse-tell needs a VISIBLE cue, not just
    # the sound). Same rect schema, loaded by Level2OverlayCatalog alongside the four zones.
    shutil.copy2(os.path.join(SRC, "z1", "z1-cat-face.json"),
                 os.path.join(DEST, "z1-cat-face.json"))
    # BUILD 17: the authored sprite rigs (hand pivots/lengths + pendulum rect/pivot/
    # amplitudes). Shipped so the runtime reads its geometry from the SAME metadata the art
    # was cut against instead of hand-transcribed constants (Level2SpriteCatalog).
    for name in ("hand-sprites.json", "clockwork-sprites.json"):
        shutil.copy2(os.path.join(SRC, "z3", "v-dial", "sprites", name),
                     os.path.join(DEST, name))
    # REV 1.4.1 (D13): the tally notation rig -- stroke/partial/strike pivots, slot pitch,
    # group gap, row pitch/capacity and the live-block rect in BOTH cu-gear-frame and wide
    # normalized coords, so the runtime block is laid out against the numbers the crib was
    # chalked against (RF-7(b): position-only separation from the crib).
    shutil.copy2(os.path.join(SRC, "z2", "v-frame", "sprites", "tally-sprites.json"),
                 os.path.join(DEST, "tally-sprites.json"))

    with open(os.path.join(DEST, "staged-manifest.json"), "w") as f:
        json.dump({"count": len(manifest), "assets": manifest}, f, indent=1, sort_keys=True)

    synth_sfx()
    make_thumb(manifest)
    print("staged %d canonical Level-2 assets + 4 JSONs + 2 SFX + thumb" % len(manifest))


if __name__ == "__main__":
    main()
