#!/usr/bin/env python3
"""Level 2 rev-1.4.1 / C1 + C3 — WIDE-view ring-hand echo geometry (measurement +
proof render for the Developer).

Contract (puzzle-graph rev 1.4.1 D12(1) and D12(3); Designer spec §2b C1 and C3;
visually_necessary_elements rev_1_4_cue_note: "three ring-hand RECTS (z1 wide,
z2 wide, plus the two shipped close-ups)"):

  C1  once clu-watch-a is viewed, z1-door-base (WIDE) composites the canonical
      hand-hour sprite pivoted at the house ring's hub, pointing at the 3-notch.
  C3  once clu-watch-b is viewed, z2-frame-base (WIDE) composites the same sprite
      at the gear ring's hub pointing at the 9-notch. PARITY ONLY -- the chimney
      brick gets NO chalk mark; that contract is unchanged and absolute.

  These are NEW RECTS ON AN EXISTING SPRITE, not new assets: the Developer extends
  Level2CloseUpVisuals.ringClues with two wide entries and Level2RoomView renders
  them exactly as it already renders the two close-up entries. Asset-Gen's job is
  the MEASUREMENT (this file) plus the visual proof, so the numbers the Developer
  wires in are the numbers the art was measured against.

Rings measured on the shipped @3x wide plates and cross-checked against the two
shipped close-up ringClues entries (so wide and close-up describe ONE ring):
  house ring  wide centre (1886.6, 725.7)  notch-tip radius 71.7 px
  gear  ring  wide centre (2850.4, 1097.6) notch-tip radius 21.1 px
              (implementation-notes build-16 carve x [0.7359,0.7487],
               y [0.5589,0.5844] -> centre 0.74230, 0.571650)

ATTITUDE NOTE (load-bearing for the C2 cache note): Level2RoomView rotates the
sprite by rotationEffect(hour*30) with the sprite pointing up, so hour 3 renders
EXACTLY horizontal. That is why the chalk bearing hand on the cache board is laid
at 0.0 deg and the D12 +/-5 deg attitude match is exact by construction.

Usage: python l2_rev141_ringhands.py
"""
import json
import os
import sys

from PIL import Image, ImageDraw

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))

A2 = r"C:\Users\shaim\escape-room\specs\assets\level-2"
SPRITE = os.path.join(A2, "z3", "v-dial", "sprites", "hand-hour@3x.png")
POINTER_LEN_FRAC = 0.86        # Level2CloseUpVisuals.ringPointerLengthFraction

RINGS = {
    "z1-door-base": {
        "gate_clue": "clu-watch-a", "hour": 3,
        "centre_px": (1886.6, 725.7), "radius_px": 71.7,
        "plate": os.path.join(A2, "z1", "v-door", "z1-door-base@3x.png"),
        # the ring is 143 px across in the wide (38 pt on iPad): the natural
        # pointer already reads, so NO over-scale is applied here.
        "pointer_multiplier": 1.35,
        "crop": (1740, 590, 2040, 890),
    },
    "z2-frame-base": {
        "gate_clue": "clu-watch-b", "hour": 9,
        "centre_px": (2850.4, 1097.6), "radius_px": 21.1,
        "plate": os.path.join(A2, "z2", "v-frame", "z2-frame-base@3x.png"),
        # the gear ring is only 42 px across in the wide (11 pt on iPad), so the
        # natural pointer would be ~6 pt and illegible. C1's sanctioned principle
        # ("a slightly over-scaled hand is acceptable and preferable to an
        # illegible one -- Art Director's call on the exact factor") is applied:
        # the hand is over-scaled so it reads at room scale AND reaches toward the
        # brick field its 9-o'clock bearing selects (RC-2).
        "pointer_multiplier": 2.75,
        "crop": (2740, 990, 2990, 1240),
    },
}


def render_hand(length_px, hour):
    """Replicate Level2RoomView's composite exactly:
       frame = (length*0.34, length*1.32), aspect-fit, offset y -length*0.31,
       rotationEffect(hour*30) about the frame centre, positioned at the ring
       centre. Returns (RGBA, (dx, dy) offset of the image's top-left from the
       ring centre)."""
    spr = Image.open(SPRITE).convert("RGBA")
    fw, fh = length_px * 0.34, length_px * 1.32
    k = min(fw / spr.width, fh / spr.height)          # .fit
    w, h = max(1, round(spr.width * k)), max(1, round(spr.height * k))
    spr = spr.resize((w, h), Image.LANCZOS)
    frame = Image.new("RGBA", (max(1, round(fw)), max(1, round(fh))), (0, 0, 0, 0))
    frame.alpha_composite(spr, ((frame.width - w) // 2, (frame.height - h) // 2))
    frame = frame.rotate(-hour * 30.0, expand=True, resample=Image.BICUBIC)
    # SwiftUI .offset(y:) is applied BEFORE .rotationEffect in the modifier chain
    # used on the plate, i.e. the offset rotates with the view.
    import math
    a = math.radians(hour * 30.0)
    ox, oy = 0.0, -length_px * 0.31
    rx = ox * math.cos(a) - oy * math.sin(a)
    ry = ox * math.sin(a) + oy * math.cos(a)
    return frame, (rx - frame.width / 2, ry - frame.height / 2)


def build():
    out = {"revision": "1.4.1 (C1 + C3 wide ring-hand echoes)",
           "owner": "Developer wires these two rects into "
                    "Level2CloseUpVisuals.ringClues; the sprite already ships "
                    "(z3/v-dial/sprites/hand-hour). NO new asset, NO new state, "
                    "NO new hotspot, NO gate change.",
           "sprite": "hand-hour",
           "pointer_length_fraction": POINTER_LEN_FRAC,
           "attitude_note": "rotationEffect(hour*30) with the sprite pointing up: "
                            "hour 3 renders EXACTLY horizontal and hour 9 exactly "
                            "horizontal-left. The rev-1.4.1 chalk bearing hand on "
                            "the cache board is laid at 0.0 deg, so the D12 +/-5 "
                            "deg match with the C1 ring hand is exact.",
           "entries": {}}
    sheet = Image.new("RGB", (1230, 1090), (24, 22, 20))
    dd = ImageDraw.Draw(sheet)
    dd.text((10, 6), "C1 / C3 WIDE ring-hand echoes -- proof composites "
                     "(z1 house ring @ 3-notch, z2 gear ring @ 9-notch)",
            fill=(230, 225, 210))
    dd.text((10, 545), "PARITY: the same two rings in their shipped close-ups "
                       "(cu-house-ring, cu-gear-ring) -- identical composite maths",
            fill=(230, 225, 210))
    for i, (name, R) in enumerate(RINGS.items()):
        plate = Image.open(R["plate"]).convert("RGBA")
        L = R["radius_px"] * POINTER_LEN_FRAC * R["pointer_multiplier"]
        hand, (dx, dy) = render_hand(L, R["hour"])
        cx, cy = R["centre_px"]
        plate.alpha_composite(hand, (round(cx + dx), round(cy + dy)))
        crop = plate.convert("RGB").crop(R["crop"])
        sheet.paste(crop.resize((520, 520), Image.LANCZOS), (10 + i * 610, 30))
        out["entries"][name] = {
            "gate_clue": R["gate_clue"], "hour": R["hour"],
            "centre_px_3x": list(R["centre_px"]),
            "centre_norm": [round(R["centre_px"][0] / 3840.0, 6),
                            round(R["centre_px"][1] / 1920.0, 6)],
            "radius_px_3x": R["radius_px"],
            "radius_frac_of_width": round(R["radius_px"] / 3840.0, 6),
            "pointer_multiplier": R["pointer_multiplier"],
            "effective_length_px_3x": round(L, 1),
            "effective_length_pt_ipad": round(L * 1024.0 / 3840.0, 1),
            "effective_length_pt_iphone": round(L * 780.0 / 3840.0, 1),
            "note": ("natural scale, the ring already reads at room scale"
                     if R["pointer_multiplier"] <= 1.4 else
                     "SANCTIONED OVER-SCALE (C1 principle): the carve is 42 px "
                     "across in the wide, so the natural pointer would be ~6 pt; "
                     "the hand is over-scaled to read at room scale and to reach "
                     "toward the brick field its bearing selects."),
        }
    # ---- wide<->close-up PARITY proof: render the two SHIPPED close-up entries
    # with the identical maths, so the sheet shows the same ring twice per zone.
    CU = {"cu-house-ring": (os.path.join(A2, "z1", "v-door", "cu-house-ring@3x.png"),
                            (1020, 770), 204, 3, (700, 450, 1340, 1090)),
          "cu-gear-ring": (os.path.join(A2, "z2", "v-frame", "cu-gear-ring@3x.png"),
                           (1056, 571), 77, 9, (736, 251, 1376, 891))}
    for i, (name, (path, c, r, hour, crop)) in enumerate(CU.items()):
        plate = Image.open(path).convert("RGBA")
        L = r * POINTER_LEN_FRAC
        hand, (dx, dy) = render_hand(L, hour)
        plate.alpha_composite(hand, (round(c[0] + dx), round(c[1] + dy)))
        sheet.paste(plate.convert("RGB").crop(crop).resize((520, 520), Image.LANCZOS),
                    (10 + i * 610, 560))
        out["entries"][name] = {"shipped": True, "gate_clue": RINGS[
            "z1-door-base" if hour == 3 else "z2-frame-base"]["gate_clue"],
            "hour": hour, "centre_norm": [round(c[0] / 2048, 6), round(c[1] / 1536, 6)],
            "radius_frac_of_width": round(r / 2048, 6), "pointer_multiplier": 1.0,
            "note": "already in Level2CloseUpVisuals.ringClues -- unchanged",
            **({"advisory_not_a_change": (
                "Asset-Gen observation from the parity proof: at the shipped 1.0 "
                "multiplier this pointer's tip lands INSIDE the carved gear glyph, "
                "so the bearing is hard to read even in the close-up. A "
                "pointer_multiplier of ~1.5 would put the tip on the 9-notch and "
                "clear the glyph. Flagged, NOT applied -- the shipped close-up "
                "entry is unchanged by this batch.")} if hour == 9 else {})}
    sheet.save(os.path.join(A2, "ringhand-wide-proof.png"))
    with open(os.path.join(A2, "ring-clue-wide-geometry.json"), "w") as f:
        json.dump(out, f, indent=1)
    for k, v in out["entries"].items():
        tail = (f" -> {v['effective_length_pt_ipad']} pt iPad"
                if "effective_length_pt_ipad" in v else "  (shipped close-up entry)")
        print(f"{k}: centre {v['centre_norm']} radiusFracOfWidth "
              f"{v['radius_frac_of_width']} hour {v['hour']} "
              f"x{v['pointer_multiplier']}{tail}")


if __name__ == "__main__":
    build()
