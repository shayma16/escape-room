#!/usr/bin/env python3
"""Compose compact close-up/icon specs into full fal_gen.py jobs, prepending the
mandatory style template and resolving ref paths to absolute. Emits jobs.json.

Input (argv[1]) = JSON list of compact specs:
{ "name","out_dir","content","refs":[rel-or-abs...],"endpoint"?,"w"?,"h"?,"seed"?,"keep_rgba"? }
'content' = the Art-Director scene-specific description; style template is prepended.
"""
import json, sys, os
ROOT = r"C:\Users\shaim\escape-room\specs\assets\level-1"
STYLE = open(r"C:\Users\shaim\escape-room\specs\tools\style_template.txt", encoding="utf-8").read().strip()

def absref(p):
    return p if os.path.isabs(p) else os.path.join(ROOT, p)

specs = json.load(open(sys.argv[1], encoding="utf-8"))
jobs = []
for s in specs:
    w = s.get("w", 2048); h = s.get("h", 1536)
    prompt = STYLE + "\n\nSCENE CONTENT: " + s["content"]
    job = {
        "name": s["name"], "out_dir": s["out_dir"],
        "endpoint": s.get("endpoint", "t2i"),
        "prompt": prompt, "width": w, "height": h,
        "refs": [absref(p) for p in s.get("refs", [])],
        "resolution_tier": s.get("tier", "std"),
    }
    if "seed" in s: job["seed"] = s["seed"]
    if s.get("keep_rgba"): job["keep_rgba"] = True
    jobs.append(job)
out = sys.argv[2] if len(sys.argv) > 2 else os.path.join(os.path.dirname(sys.argv[1]), "jobs.json")
json.dump(jobs, open(out, "w", encoding="utf-8"), indent=1)
print("wrote", out, "with", len(jobs), "jobs")
