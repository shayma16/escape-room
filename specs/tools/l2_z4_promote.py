#!/usr/bin/env python3
"""Promote a visually-approved + gate-passed z4 tightfix candidate to canonical.
   python l2_z4_promote.py <key>   # copies scratch cand-<key>.png -> states/<outname>
"""
import os
import sys
from PIL import Image

sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from l2_z4_tightfix import CFG, SCRATCH, STATES

which = sys.argv[1]
cfg = CFG[which]
outname = cfg["ovname"] + ("-wide" if cfg.get("wide") else "") + "@3x.png"
Image.open(os.path.join(SCRATCH, f"cand-{which}.png")).save(
    os.path.join(STATES, outname))
print("PROMOTED", which, "->", outname)
