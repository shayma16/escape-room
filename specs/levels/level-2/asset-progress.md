# Level 2 asset generation progress — BATCH 1 (canonical sheets + z1)

PROGRESS: 9/25 done | 0 retrying | 0 failed | 16 remaining | $2.25 spent (predecessor; $0.00 this session) | batch cap ~$5 | level cap $15.00

_Resumed 2026-07-19 after session-limit cutoff (second resumer session). Recovered state
registered in asset-manifest.json. Spend correction vs the handoff's $1.80: the 3 icon
raws (est $0.45) were generated after commit deabd17's $1.80 tally — honest predecessor
total $2.25._

_Model: fal-ai/nano-banana-pro (t2i + edit) + deterministic PIL for all load-bearing
glyphs/counts. Pricing: $0.30 4K, $0.15 std/2K. This session's NB plan: 2 generations
(cu-coat-pockets fresh; door-dial disc-clean edit) = $0.30–0.60 with retry allowance;
all other CUs are pure crops + PIL stamps at $0 (lower drift risk than per-CU NB edits —
wide stays canonical truth). Projected batch total $2.55–2.85._

## Done (recovered, commits deabd17 + e6e1381)
| # | Asset | Cost | Status |
|---|-------|------|--------|
| 1 | masters/numerals-canonical (sheet A) | $0 | done — mirror contracts PASS |
| 2 | masters/landmark-dies (sheet B) + small-mark dies | $0.15 | done — 7 rays verified; 24px distinctness PASS |
| 3 | z1/v-bench/z1-bench-base wide | $1.05 | done (r1 reject + r2 + relocation + coat crop-fix) |
| 4 | z1/v-master/z1-master-base wide | $0.30 | done (glyph-integration fixes pending below) |
| 5 | z1/v-door/z1-door-base wide | $0.30 | done (glyph-integration fixes pending below) |
| 6 | z1/icons/inv-screwdriver | $0.15 | done |
| 7 | z1/icons/inv-tile-ii/iv/vii/xi (one raw + canonical stamps) | $0.15 | done |
| 8 | z1/icons/inv-watch-a | $0.15 (shared raw) | done |
| 9 | z1/icons/inv-watch-b | — | done |

## This session — deterministic glyph-integration passes on the wides (PIL, $0)
Wides are canonical truth; each fix is built at CU resolution and composited back into
the @3x wide so wide and close-up stay pixel-consistent. Superseded wides → _rejects/.
| # | Fix | Wide | Status |
|---|-----|------|--------|
| W1 | slate chalk ratio diagram (EXACTLY 24 tallies, XII/VIII, two ?, cam notch + door die) | v-bench | pending |
| W2 | stove hob tile II canonical engrave | v-bench | pending |
| W3 | barometer face rebuild (de-text; sun/cloud/rain pictograms; fixed needle) | v-bench | pending |
| W4 | master longcase: canonical numeral ring + verified 6:00 hands + canonical ★ restamp | v-master | pending |
| W5 | door dial rebuild: 12 sockets, seated I/III/V/VI/VIII/IX/X/XII, EMPTY at 2/4/7/11 (NB disc-clean + PIL) | v-master | pending |
| W6 | tray: remove extra gold object → ONE loose VI tile | v-master | pending |
| W7 | crate tile VII engrave + straw half-bury | v-master | pending |
| W8 | door handle keyhole check (D8) — patch if keyhole-like | v-master | pending |
| W9 | beam mark rebuild: canonical ⌂ die + 12-notch ring (replaces drifted gear/leaf mark) | v-door | pending |
| W10 | sill tile XI canonical engrave | v-door | pending |
| W11 | cat recolor to F3 gray-blue #8C8C90 (warm rim preserved) | v-door | pending |

## This session — close-up plates (12, 2048×1536 @3x, predecessor's canonical names)
| # | Plate | Method | Est | Status |
|---|-------|--------|-----|--------|
| 10 | z1/v-bench/cu-slate | crop + W1 | $0 | pending |
| 11 | z1/v-bench/cu-stove-hob | crop + W2 | $0 | pending |
| 12 | z1/v-bench/cu-coat-pockets | FRESH NB t2i+refs + IV stamp | $0.15–0.30 | pending |
| 13 | z1/v-bench/cu-barometer | crop + W3 | $0 | pending |
| 14 | z1/v-master/cu-master-face | crop + W4 | $0 | pending |
| 15 | z1/v-master/cu-door-dial (incl. tray) | crop + NB disc-clean + W5/W6 | $0.15–0.30 | pending |
| 16 | z1/v-master/cu-crate-straw | crop + W7 | $0 | pending |
| 17 | z1/v-door/cu-sill-tile | crop + W10 | $0 | pending |
| 18 | z1/v-door/cu-house-ring | crop + W9 | $0 | pending |
| 19 | z1/v-door/cu-cat-cushion | crop + W11 | $0 | pending |
| 20 | z1/v-door/cu-floor-cache (flush; NO tell) | pure crop | $0 | pending |
| 21 | z1/v-door/cu-timelock (NO keyhole) | pure crop | $0 | pending |

## This session — remaining z1 cutout + wrap-up
| # | Item | Status |
|---|------|--------|
| 22 | z1/icons/inv-great-wheel (EXACTLY 64 teeth, "64" stamp, bronze, square arbor hole) — deterministic PIL | pending |
| 23 | re-derive canonical wides @3x/@2x/@1x; archive superseded to _rejects/ | pending |
| 24 | z1 review montage bundle + grayscale gate checks | pending |
| 25 | manifest reconciliation + spend report | pending |

NOT in batch 1: z2/z3/z4, sprites/rigs, the ~46 state edits. F2 resolved: L1 pause rune
stays series-wide. Toy mouse cutout: z2-scoped → batch 2. Oil can z2; winding key + tag z4.
