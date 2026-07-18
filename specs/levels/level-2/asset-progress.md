# Level 2 asset generation progress — BATCH 1 (canonical sheets + z1)

PROGRESS: 25/25 done | 0 retrying | 0 failed | 0 remaining | $2.55 total ($2.25 predecessor + $0.30 this session) | batch cap ~$5 | level cap $15.00

BATCH 1 COMPLETE (z1) — awaiting step-10 user review of `specs/assets/level-2/z1/z1-review-batch1.png`.

_Model: fal-ai/nano-banana-pro (t2i + edit) + deterministic PIL for all load-bearing
glyphs/counts (l2_glyphs.py = ONE canonical source; l2_z1_build.py = the region build
pipeline). Session NB spend: exactly 2 generations, $0.30, zero retries._

## Done (recovered, commits deabd17 + e6e1381) — $2.25
Sheets A+B, 3 z1 wide bases, 7 inventory cutouts (see asset-manifest.json).

## Done this session (2026-07-19) — $0.30
| # | Item | Status |
|---|------|--------|
| W1 | slate chalk ratio diagram (24 tallies ASSERTED, XII/VIII, two ?, cam notch + door die) | done — grayscale gate PASS |
| W2 | stove tile II canonical engrave | done (legibility-cheated perspective) |
| W3 | barometer face rebuild (de-text, rain/cloud/sun, fixed needle) | done |
| W4 | longcase: canonical numeral ring + 6:00 sharp + canonical star | done |
| W5 | door dial rebuild: 12 sockets, seated I/III/V/VI/VIII/IX/X/XII, EMPTY 2/4/7/11 | done ($0.15 NB disc-clean, face pixels only) |
| W6 | tray: ONE loose VI tile (extra object removed) | done |
| W7 | crate tile VII + straw half-bury (partial numeral) | done |
| W8 | D8 DEFECT FIXED: generative keyhole on door handle plate patched out | done |
| W9 | beam mark: canonical house die + 12-notch ring (replaced drifted gear/leaf mark) | done |
| W10 | sill tile XI canonical engrave | done |
| W11 | cat recolor to F3 gray-blue #8C8C90 (warm rim kept) | done |
| CU 1–12 | cu-slate, cu-stove-hob, cu-coat-pockets ($0.15 fresh NB), cu-barometer, cu-master-face, cu-door-dial, cu-crate-straw, cu-sill-tile, cu-house-ring, cu-cat-cushion, cu-floor-cache, cu-timelock — all 2048×1536 @3x/@2x/@1x | done |
| 22 | inv-great-wheel: EXACTLY 64 teeth (asserted), '64' canonical Arabic stamp, square arbor, RGBA | done |
| 23 | wides re-integrated + re-derived @3x/@2x/@1x; pre-glyph wides → _rejects/*-preglyph | done |
| 24 | z1-review-batch1.png montage + grayscale gate checks | done |
| 25 | manifest reconciled, spend logged | done |

Canonical-filename rule honored: every canonical path holds current art; superseded
versions in _rejects/. cu-master-face frame shifted to (540,320)-(2500,1790) so the case
star clears the 72pt iPad pill band (7-R1.5).

## NOT in batch 1 (next)
- z1 state-variant overlays (~14 crop edits: taken states, cushion reveal, cache pried,
  dial per-socket seats, door open, bar raised, win-beat evening step F4) — cheap PIL
  crop edits over the now-canonical wides; propose folding into batch 2's wave.
- Batch 2 (z2): v-frame + v-clockrow wides, CUs 13–19, gear-rack prop plates
  (16/24/36/40/48/72 — deterministic teeth per F6, reusing render_arabic), toy-mouse +
  oil-can cutouts, canonical clock-row plates (dies from sheet B), mural sprite layers.
- Batches 3/4: z3 (great-dial mirror contract plate — most protected asset), z4.
