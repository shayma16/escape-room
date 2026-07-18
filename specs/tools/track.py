#!/usr/bin/env python3
"""Update the asset-progress.md tracker: set a row's Status/Cost/Note by asset id,
and rewrite the DERIVED PROGRESS header line. Usage:
  track.py setrow "<id>" "<status>" "<cost>" "<note>"
  track.py header "<done>" "<retrying>" "<failed>" "<remaining>" "<spent>" "<tail>"
"""
import sys, re
TRACKER = r"C:\Users\shaim\escape-room\specs\levels\level-1\asset-progress.md"

def load():
    return open(TRACKER, encoding="utf-8").read().splitlines()
def save(lines):
    open(TRACKER, "w", encoding="utf-8").write("\n".join(lines) + "\n")

cmd = sys.argv[1]
lines = load()
if cmd == "setrow":
    aid, status, cost, note = sys.argv[2], sys.argv[3], sys.argv[4], sys.argv[5]
    for i, ln in enumerate(lines):
        cells = [c.strip() for c in ln.split("|")]
        # rows look like: | id | Asset | Method | Status | Cost | Note |  (7 cells incl. edges)
        if len(cells) >= 7 and cells[1] == aid:
            cells[4] = status; cells[5] = cost; cells[6] = note
            lines[i] = "| " + " | ".join(cells[1:7]) + " |"
            print("updated", aid)
            break
        # icon/sprite rows: | id | Asset | Status | Cost | Note | (6 cells)
        if len(cells) == 6 and cells[1] == aid:
            cells[3] = status; cells[4] = cost
            if note != "-": cells[5] = note
            lines[i] = "| " + " | ".join(cells[1:6]) + " |"
            print("updated", aid)
            break
    else:
        print("NOT FOUND", aid); sys.exit(1)
elif cmd == "header":
    done, retry, failed, rem, spent, tail = sys.argv[2:8]
    newhdr = f"DERIVED PROGRESS: {done}/52 fresh done | {retry} retrying | {failed} failed | {rem} remaining | ${spent} spent | {tail}"
    for i, ln in enumerate(lines):
        if ln.startswith("DERIVED PROGRESS:"):
            lines[i] = newhdr; print("header updated"); break
save(lines)
