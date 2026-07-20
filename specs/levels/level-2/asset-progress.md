# Level 2 asset generation — BATCH 4 (FINAL: all remaining state overlays + sprites + hatch-wheel carry-in fix)

PROGRESS: 21/21 done | 0 retrying | 0 failed | 0 remaining | $1.65 batch NB spend ($8.85 cumulative) | level cap $15.00 — BATCH 4 COMPLETE 2026-07-20 (LEVEL 2 ART COMPLETE pending user step-10 review)
(session note: items 9,11,12,13,14 done deterministically; item 10 key-in + z4 16/17 redo deferred to NB phase; z4 uncommitted work REJECTED = smear defect, redoing)

_Green-lit by user 2026-07-20 (z3/z4 verdict: approved with hatch-wheel curvature fix).
Final art batch: per-element overlay architecture (patch + rect JSON, pixel-aligned,
seam-checked <=24) matching the Developer compositor; deterministic/PIL wherever possible;
NB edits ONLY for genuine surface changes. UPGRADED GATE in force batch-wide: containment
+ curvature/perspective conformance on every stamped non-planar/oblique surface
(l2_wheelfix.assert_conformal; flat stamp = FAIL even if contained). Overlay JSONs:
z2/z2-state-overlays.json, z3/z3-state-overlays.json, z4/z4-state-overlays.json (schema =
z1-state-overlays.json). L1/round-4 lessons binding: no full-plate swaps, no misregistered
patches, no blur/smear inpaints, manual-pickup states show emptied containers._

## Batch 4 plan (2026-07-20)

| # | Item | Method | Est $ | Status |
|---|------|--------|-------|--------|
| 1 | CARRY-IN FIX (user verdict 2026-07-20): hatch thumb-wheel numerals conform to crown curvature/perspective — per-wheel surface model (axial/circum frame + bow), strip-warp of canonical numerals, UPGRADED conformance gate (batch-3 flat stamps proven FAIL 4/4); rebuilt z3-dial-base + cu-hatch-wheels + PER-WHEEL 4x12 wheel strip; before/after sheet | deterministic PIL (l2_wheelfix.py) | 0 | done (commit 5205ba3; sweep 11.4deg = model on all 8 stamped surfaces; changed-px audit clean; w4 y-band note = accepted batch-3 flag) |
| 2 | z2 ov-arbor-oiled (CU13 + wide echo): bearing rust bloom cleared + oil sheen, bearing zone only | PIL | 0 | done (seams 6.9/7.1; bearing-only scope) |
| 3 | z2 post-mount overlays x14 (CU13): gears 16/24/36/40/48/72 + great wheel 64, posts A and B, perspective-matched deterministic gear renders + shadow, arbor through square hole | PIL (render_gear/die-64) | 0 | done (RGBA additive, centered on stub axes A(1322,668)/B(1625,695), dia=84+2.1t, square hole shows arbor socket; no collar re-paste artifacts) |
| 4 | z2 rack-absent overlays x6 (CU14 native + wide echo): blank-peg crops from the preglyph frame base (_rejects/z2-frame-base-preglyph) | PIL | 0 | done (RGBA masked, nearest-gear partition + neighbor hard-exclude; all-absent residue 0 px; neighbor-bite 6/6 = 0 px) |
| 5 | z2 mural sprites: sun-disc cutout + track spec; watchman + bell strike key poses; jointed-figure layers (woman/drummer); JSON with track + pose anchors (D5 cadence = Developer timing) | PIL cutouts (+$0.15 NB reserve if strike pose unusable) | 0 | done (sun-disc+bell RGBA cutouts +absent patches; woman/drummer/watchman soft-alpha figure layers; track polyline; mural-sprites.json; strike=bell swing+audio, NB reserve untouched) |
| 6 | z2 ov-panel-open (frame wide): wall panel latched open onto z3 (dark opening + amber dial glow leak) + panel-door cutout sprite for swing keys | NB edit + registered masked composite | 0.15 | done (NB panel swung open onto z3: dark opening + amber dial glow leak visible through it; seam 5.7; +sp-panel-door swing sprite from closed base w/ hinge pivot) |
| 7 | z2 ov-brick-pried-oilcan / ov-brick-empty (CU16 + wide echo): pried cavity NB edit; canonical inv-oil-can composited in cavity; empty = same cavity | NB edit + PIL | 0.15 | done (NB pried cavity, seam 4.4/1.4; canonical oil-can composited for -oilcan; -empty = cavity only) |
| 8 | z2 ov-cabinet-open-mouse / ov-cabinet-empty (CU18): top drawer open (empty interior) NB edit; canonical inv-toy-mouse composited for +mouse | NB edit + PIL | 0.15 | done (NB top-center drawer open; gap-aligned accept mask kills tonal seam; wide 7.6/CU 4.0; canonical tin-mouse for -mouse variant) |
| 9 | z3 ov-drum-oiled (CU21 + wide echo): rust/dry bloom cleared at bearing + oil sheen | PIL | 0 | done (drum-oiled: rust bloom cleared + oil sheen, bearing zone; wide seam 1.9 / CU 1.3) |
| 10 | z3 ov-drum-key-in (CU21 + wide echo): winding key seated in square socket (rhyme read preserved) | PIL composite first; NB reserve | 0(+0.15) | done (NB winding key seated in socket — convincing 3D insertion; brass-only accept mask preserves dial glow, no blob; wide 1.7/CU 1.0; PIL attempt failed=flat, used reserve) |
| 11 | z3 weight sprite + track spec (low->raised positions on line) | PIL cutout + JSON | 0 | done (deterministic cast-iron weight sprite + vertical track spec; no clean plate source noted) |
| 12 | z3 pendulum sprite (still/weak/full amplitudes) + pivot/animation JSON | PIL cutout + JSON | 0 | done (pendulum geo-mask sprite rod+bob; pivot (2190,80); amps still/weak/full 0/4/11; +absent patch) |
| 13 | z3 hammer D11 twitch keys (rest + lifted, never strikes) + JSON | PIL cutout + rotate | 0 | done (hammer geo-mask rest+lift; pivot (2338,246); twitch 9deg; +absent patch) |
| 14 | z3 strike-beat rod articulation key poses/notes (z3 + z1 rod ends, translate offsets) | JSON notes + rects | 0 | done (strike-rods JSON notes+rects, z3+z1 rod ends, axial translate; no art) |
| 15 | z3 ov-hatch-open (wide): hatch open onto stair mouth + warm z4 lamp leak | NB edit + registered masked composite | 0.15 | done (NB floor hatch open onto stair mouth + warm z4 lamp leak; wheels-lid lifted; header retained; seam 2.5) |
| 16 | z4 ov-key-taken (CU24 + wide echo): hook empty | PIL clone-out | 0 | done (REDO: dead-agent smear REJECTED; 1 NB edit removed key+tag -> masonry rebuild; silhouette-masked overlay, tag pristine; wide seam 12.2/CU 10.7; DEVIATION \$0 PIL->\$0.15 NB, flagged) |
| 17 | z4 ov-tag-taken (CU23 + wide echo): nail empty | PIL clone-out | 0 | done (REDO: same NB edit; tag+rope removed, empty nail, key pristine; wide seam 2.1/CU 1.1) |
| 18 | z1 cat pose sprites x4 (pounce-chase, settled-by-door, stretch, exit-trot) — keyed RGBA, F3 cat design refs, 9.1 register (real-cat, no anthropomorphism) | NB raws + keyed RGBA | 0.60 | done (4 NB pose raws from F3 cat design ref -> border-seed floodfill + beige-cleanup keyed RGBA: pounce-chase/settled-by-door/stretch/exit-trot; real-cat register, consistent gray-blue design; cat-sprites.json) |
| 19 | z1 cat facial keys: mouse-tell (eyes locked + tail flick) + slow-blink half-lid on cu-cat-cushion | 1 NB edit + PIL (blend/tail warp) | 0.15 | done (1 NB edit opens sleeping eyes->amber locked mouse-tell; PIL half-lid blend=slow-blink; PIL tail-tip flick; eye/blink/tail seams 3.2/3.2/2.9; z1-cat-face.json) |
| 20 | z1 mouse skitter loop keys (from inv-toy-mouse cutout: tilt frames + motion JSON; D4) + tray-VI seat/pop-back notes (reuses tile-VI cutout, no art) | PIL + JSON | 0 | done (6-frame tin-mouse skitter tilt/bob loop from inv-toy-mouse; round-winged key kept; D4 motion JSON; tray-VI seat/pop-back = note only, no art) |
| 21 | Deliverables: seam audit ALL new overlays (<=24, l2_fixstates ring method); z2/z3/z4 state-overlays.json; batch-4 review contact sheet; manifest batch-4 block; progress/spend reconciliation | PIL | 0 | done (seam audit: 24 surface overlays PASS<=24 worst 20.2; 20 RGBA additive verified; z2/z3/z4 state-overlays.json complete; contact sheet z2/z2z3z4-review-batch4.png; manifest batch-4 block +17 entries; spend reconciled $1.65 -> cumulative $8.85) |

Planned NB spend $1.20 + $0.45 reserves (mural pose, drum key-in, 1 re-roll) = worst $1.65
-> cumulative worst $8.85 of $15.00 (headroom $6.15 at worst). Hard stop $15.00.

GATES (every item): pixel-aligned patch+rect (no full-plate swaps); seam ring <=24;
emptied-container reads for manual pickups; canonical glyphs/dies only (never model-drawn);
canonical-filename discipline (superseded -> _rejects/); upgraded conformance gate on any
stamped curved/oblique surface; one-sun continuity (no lighting shifts except sanctioned
amber leaks through openings); iPad band for interactive points; 7-R1.5 bottom band on CUs.

# Level 2 asset generation — BATCH 3 (z3 + z4 + gear-frame carry-in fix)

PROGRESS: 17/17 done | 0 retrying | 0 failed | 0 remaining | $1.65 batch spend ($7.20 cumulative) | level cap $15.00 — BATCH 3 COMPLETE 2026-07-20

_Green-lit by user 2026-07-20 (fix-pass verdict: "everything checks out"; one carry-in fix
rolled in). Scope per standing plan: z3 (great-dial mirror contract plate — most protected
asset) + z4; z3/z4 STATE overlays stay in batch 4. Model: fal-ai/nano-banana-pro (t2i) +
deterministic PIL for every load-bearing glyph (l2_glyphs.py canonical source; mirrored
numeral set from sheet A). NEW PROGRAMMATIC GATE this batch (user has caught containment
3x): every stamp's bbox is ASSERTED inside its target-surface mask in code, not by eye._

## Batch 3 plan (2026-07-20)

| # | Item | Method | Est $ | Status |
|---|------|--------|-------|--------|
| 1 | CARRY-IN FIX (user verdict 2026-07-20): cu-gear-frame XII/VIII re-stamp — erase by preglyph bbox revert; XII contained ON the pinion face annulus (ellipse mask minus boss), VIII engraved on the post-A bracket face (rect mask); programmatic containment asserts; propagate wide @3x/2x/1x + re-crop CU13; before/after sheet | deterministic PIL (l2_framefix.py) | 0 | done (XII h24 @(1054,1152) on pinion face annulus, VIII h26 @(1436,1230) on bracket panel; containment asserts PASS; seam audit: all 3160 changed px inside sanctioned zones; superseded -> _rejects/*-b3pre-framefix; sheet z2/gearframe-stampfix-before-after.png) |
| 2 | z3-dial-base wide 3840x1920: chamber contre-jour, glowing amber dial disc from behind (glass BLANK — no numerals/no hands, stamped deterministically after), setting crank at hub + clear D9 staging area, winding drum (dry, square socket, weight low on line), dead-still pendulum, strike train + hammers, linkage rods exiting right, floor hatch w/ 4 blank brass wheels + header plates | NB t2i 4K, 14 refs | 0.30 | done (r1 730301 REJECTED: disc geometry made a full in-band mirrored ring impossible — works cluster forced ring r>=640 vs iPad-band max 525; r2 730303 kept: ring at u=0.73 of the fitted ellipse, leftmost glyph edge x~1023 >> 640; r1 + $0.15 hatch-shut edit archived to _rejects; +$0.30 retry, +$0.15 hatch edit sunk) |
| 3 | z3 glyph integration rev ($0): MIRRORED numeral ring from sheet A -mir set fitted inside measured disc (full 4.2 contract: whole-ring mirror, XII top/VI bottom flipped letterforms, mirrored-IV=malformed-VI, NO legible VII anywhere); hatch wheel I-XII engraves (neutral non-solution position) + 4 canonical header dies (BigBen* Burj Liberty Fuji — binding z3 order); containment asserts | deterministic PIL (l2_z3_build.py) | 0 | done (iron glazing ring ELLIPSE-fitted from 61 detected points, center (1459.8,889.1) axes 464x531; bar segments erased by luminance-guarded radial-clone fill in u-space; mirrored ring stamped: pos p = numeral (12-p) flipped, IIV at pos 5, malformed-VI at pos 8; hatch wheels = NB surface edit 730304 ($0.15) composited + canonical XII/III/VI/IX on generated crown faces + dies on generated strips; every glyph containment- and band-asserted) |
| 4 | CU20 cu-great-dial (interactive; carries clu-mirrored-numerals; native-res mirrored ring re-stamp; D9 space clear; numeral >=5% screen width floor) | crop + native overlay | 0 | done (native mirrored-ring restamp at 1.207x; glyphs 106px CU (X ~10% screen width); D9 area = clear boards (1600-2100,1450-1570); grayscale squint PASS — see z3-mirror-contract-gate.png) |
| 5 | CU21 cu-winding-drum (interactive; dry bearing + square socket reads as square absence) | crop (+native detail if upsample soft) | 0 | done (pure crop; square socket absence + rust bloom + rope line all read; drum body extends into left overscan — FLAG: interactive points (socket/bearing) are in-band at x>=660, body is scenery) |
| 6 | CU22 cu-hatch-wheels (interactive; 4 header dies + engraved wheel numerals legible simultaneously) | crop + native deterministic wheel band + dies | 0 | done (native restamp at 1.463x; dies on generated strips ~50px CU, crisp; wheel numerals ~60px CU; w4 numeral at y1790 = 6.8% from bottom edge vs the 8% rule — FLAG, CU carries the read) |
| 7 | dial hand sprites: hour (short, spade tip) + minute (long, plain tip) silhouette soft-edge RGBA, arbor-anchored (D1: Developer renders front time th at mirrored -th; art bakes NO time) | deterministic PIL | 0 | done (spade hour 250px / plain minute 380px, soft-edge silhouettes, pivot meta at works hub (1522,878), D1 render rule in hand-sprites.json) |
| 8 | hatch wheel 12-position engraved sprite strip (shared x4 wheels, canonical numerals) | deterministic PIL | 0 | done (12 frames from wheel-2's GENERATED blank crown face + canonical numerals; per-wheel face rects (wide + CU coords) in wheel-strip.json) |
| 9 | mirror-contract gate sheet: front ring (std) vs back plate side-by-side + malformed-VI/IIV crops + grayscale squint record | PIL | 0 | done (z3/z3-mirror-contract-gate.png: color + grayscale squint, malformed-VI/IIV/malformed-IV crops vs TRUE sheet-A letterforms, mapping table) |
| 10 | z4-vault-base wide 3840x1920: strongroom, steps down back-left w/ amber hatch spill, one warm lamp pocket (#D9973F), winding key on hook (large SQUARE bit silhouette — drum-socket rhyme), blank brass tag on nail, shelf (blank ledger spines + wrapped watch), second cushion + empty saucer | NB t2i 4K, 14 refs | 0.30 | done (seed 730401; generated key was a notched door-key OUT of the iPad band (x225-585) -> corrective NB edit 730402 ($0.15): crank key w/ square socket-cube bit relocated in-band (x~1010-1210); masked registered composite, old key + cast shadow cleanly removed) |
| 11 | z4 glyph integration rev ($0): tag face mini FRONT-VIEW dial FIXED 7:20 (canonical numerals, spade hour @7:20 pos, plain minute on 4) over door die; key square-bit geometry check; containment asserts | deterministic PIL (l2_z4_build.py) | 0 | done (key hole filled -> SOLID square bit (male) rhyming the drum's square ABSENCE per graph/9.3; tag face: canonical mini dial 7:20 (spade 220deg / plain 120deg) + door die, containment asserts PASS; unfinished shelf watch face BLANKED — generated with a readable wrong time, a stray dial-time is clue-material in this level) |
| 12 | CU23 cu-tag-nail (7:20 unambiguous at CU + native tag re-stamp) | crop + native overlay | 0 | done (native tag restamp at 2.276x; 7:20 unambiguous; door die crisp) |
| 13 | CU24 cu-key-hook (square bit rhyme legible) | crop | 0 | done (square bit + drum-socket rhyme legible) |
| 14 | CU25 cu-shelf (lore inspect; nothing puzzle-bearing, spines glyph-free) | crop | 0 | done (spines blank; wrapped watch face blanked - no readable time) |
| 15 | inv-winding-key cutout (>=1024px RGBA; square bit) | NB raw + keyed RGBA | 0.15 | done (seed 730402 raw; global near-white keying (halo + enclosed bow hole) + iron recolor to match the scene key; 334x1024 RGBA) |
| 16 | inv-return-tag cutout (>=1024px RGBA; front face ONLY per D9 — no reverse side; deterministic 7:20 dial + door die identical to cu-tag-nail stamps) | NB blank-tag raw + keyed + PIL | 0.15 | done (seed 730403 raw; canonical dial layer rotated -9deg to the tag's hang angle; stamp-off-surface assert PASS; 535x1024 RGBA; front face ONLY per D9) |
| 17 | review deliverables: z3+z4 contact sheet + gear-frame before/after + manifest batch-3 block + progress updates | PIL | 0 | done (z3/z3z4-review-batch3.png contact sheet; z2/gearframe-stampfix-before-after.png; manifest batch-3 block) |

Planned NB spend was $0.90 + $0.60 reserve (worst case $1.50). ACTUAL: $1.65 —
itemized: z3 wide r1 $0.30 + r2 $0.30 (r1 rejected on ring-geometry, unfixable) + z4 wide
$0.30 + hatch-shut edit $0.15 (sunk with r1) + z4 key edit $0.15 + wheel-row surface edit
$0.15 (replaced pasted-looking deterministic wheels — doctrine: model draws surfaces,
canon stamps glyphs) + 2 icon raws $0.30. Variance +$0.15 over planned worst case,
reported to Producer. Cumulative $7.20 of $15.00 (headroom $7.80).

GATES (every plate): programmatic stamp-bbox-inside-surface-mask assert; glyph legibility
+ grayscale squint; one-sun continuity (z3 glow = #F0C060 transmitted sun; z4 lamp
#D9973F + hatch amber leak only); iPad 4:3 dual-safe band (critical elements x in
[640,3200], y in [154,1766] @3x) + 8% edge inset; 7-R1.5 bottom band; canonical-filename
discipline (superseded -> _rejects/); seam checks on all composites; NO legible VII on the
dial back view (asserted per-glyph); D9 staging area clear; no keyholes; no IIII.

# Level 2 asset generation — STEP-10 z2 FIX PASS (2026-07-19, after batch-2 verdict)

PROGRESS: 9/9 done | 0 retrying | 0 failed | 0 remaining | $0.75 fix-pass spend ($5.55 cumulative) | level cap $15.00 — FIX PASS COMPLETE 2026-07-20

FINAL SEAM AUDIT (3px ring vs base, PASS <= 24): all 29 overlay checks PASS — CU patches all 0.0
(cushion-empty 9 / cushion-reveal 5, pre-existing PASS); wides: bar 1.0, stove 1.0, crate 2.0,
cache 3.7/3.7, sill 11.0, screwdriver 6.3, dial-seats 15.0/18.7/20.3/15.3, cushion+workroom+cat-gone 0.0.
Review sheets: z1/z1-review-fixpass-overlays.png (8 before/after rows) + z2/clockrow-ringfix-before-after.png (F1).

SPEND RECONCILIATION (2026-07-20): predecessor agent ran ALL 5 planned NB edits before dying
(results.jsonl evidence, seeds 720301-720305): edit-coat-both-empty, edit-stove-clear,
edit-crate-clear, edit-cache-pried, edit-bar-raised = 5 x $0.15 = $0.75, previously unrecorded.
Raws archived to specs/assets/level-2/_rejects/edit-*-fixraw@3x.png. Registration audit of the
raws (shift search + control-region MAE): ALL FIVE usable for masked registered compositing —
incl. crate (MAE 5.4, 5.4% changed, tile-spot only), contra the predecessor's 're-imagined'
read; no re-roll needed, $0 further NB planned.

User verdict: z2 APPROVED WITH FIXES (batch-2 flags accepted as-is). Fix-pass plan:

| # | Item | Method | Est $ | Status |
|---|------|--------|-------|--------|
| F1 | z2 clockrow numeral rings re-stamped inside measured faces (all 4 clocks, wide + cu-clockrow-plates, plates untouched, masked bbox composite) | deterministic PIL (l2_clockfix.py) | 0 | done |
| F2 | ov-bar-raised rebuild (misregistered: seams, offset dup hardware, wrong-angle bar) | NB edit + registered component composite | 0.15 | done (raw 720305 recovered; rect widened to 100,460,1800,1280; seam CU 0.0 / wide 1.0) |
| F3 | ov-coat-watch-taken redo (smeary blur blob) | ONE NB edit (both pockets emptied) sources both coat patches | 0.15 | done (raw 720301; rect 1040,370,1580,1140; seam 0.0; tile IV untouched) |
| F4 | ov-coat-tile-taken redo (blurred band seams) | same NB edit as F3 | 0 | done (rect 430,430,970,880; seam 0.0; watch A untouched) |
| F5 | AUDIT FAIL ov-stove-tile-taken (blur blob + tile ghost) | NB edit | 0.15 | done (raw 720302; rect widened to 430,300,1720,760 so tile CAST SHADOW is included; seam 0/0.5; + ov-screwdriver-taken smear rebuilt deterministically from base: tool+shadow masked, rail clone, diffusion low-freq + mirrored HF plaster, shadow attenuation ramp at sunbeam edge, peg restored) |
| F6 | AUDIT FAIL ov-crate-tile-taken (brass remnant + blur, seam 92) | NB edit | 0.15 | done (recovered raw 720303 was fine — registered masked composite, tile-spot mask only; seam 92 -> 0) |
| F7 | AUDIT FAIL ov-cache-pried-wheel / ov-cache-empty (pasted-flat cavity, hard board seams 128) | NB edit + canonical wheel composite | 0.15 | done (raw 720304: real cavity + pried board; rect extended to 1080,1150,2048,1536 to contain the board; canonical inv-great-wheel die-64 clipped to cavity interior w/ left catch-light; seams 128 -> 0 CU / 3.7 wide) |
| F8 | AUDIT boundary seams: ov-cache-cat-gone (160), ov-workroom-door-open (48), cushion wides, dial-seat wides, sill/stove wides | deterministic feathered boundary re-blend | 0 | done (ring color-match+feather re-blend: cat-gone 20->0, workroom 49->0, cushion-empty 30->0, cushion-reveal 28->0, dial-seats 36/37/65/44 -> 15/19/20/15, sill 19->11; stove/crate/bar/cache wides re-derived in F2/F5-F7) |
| F9 | review deliverables: clockrow before/after (done in F1) + fixed-overlays contact sheet + manifest fix block | PIL | 0 | done (z1/z1-review-fixpass-overlays.png; manifest fix block + budget reconciliation $0.75 -> cumulative $5.55) |

Audit method: programmatic seam-diff at every patch boundary (3px ring vs base) + 100% visual
inspection of every overlay composited on its base. PASS as-is: ov-screwdriver-taken*(see F8 note),
ov-sill-tile-taken (CU), dial-seat CU overlays x4, ov-cushion-empty, ov-cushion-reveal,
z1-door-win-open, cat-gone visual (boundary only). *ov-screwdriver-taken has a residual vertical
smear ghost - folded into F5 wave as deterministic re-fill if NB not needed.

NB budget: 5 edits x $0.15 = $0.75 planned, +$0.45 retry reserve; hard stop well inside $15 cap.

# Level 2 asset generation progress — BATCH 2 (z2 + z1 dial fix + z1 state overlays)

PROGRESS: 26/26 done | 0 retrying | 0 failed | 0 remaining | $2.25 batch spend ($4.80 cumulative) | est was $1.50-1.95 (+$0.45: 3 rejects re-rolled) | level cap $15.00

_Model: fal-ai/nano-banana-pro (t2i + edit) + deterministic PIL for all load-bearing
glyphs/counts (l2_glyphs.py canonical source). Batch-1 record moved below._

## Batch 2 plan (2026-07-19)

| # | Item | Method | Est $ | Status |
|---|------|--------|-------|--------|
| 1 | z1 FIX (user step-10 verdict): door-dial re-stamp — numerals contained in tile faces, tiles register cleanly with sockets, gaps exactly 2/4/7/11, seated I/III/V/VI/VIII/IX/X/XII, tray tidied to clean wooden shelf w/ VI decoy (KEEP) | deterministic PIL from canonical tile-blank + numeral stamps | 0 | done |
| 2 | z1 FIX propagation: z1-master-base wide + cu-master-face (+ cu-crate-straw sliver check); superseded → _rejects/; before/after crops for user | PIL | 0 | done |
| 3 | z2-frame-base wide 3840x1920 (automaton wall / gear frame / empty rack pegs / chimney) | NB t2i 4K, 14 refs | 0.30 | done |
| 4 | z2-clockrow-base wide 3840x1920 (4 hand-less clocks / blank plates / cabinet / display case) | NB t2i 4K, 14 refs | 0.30 | done |
| 5 | glyph-integration rev of both z2 wides: XII/VIII pinion stamps, ⚙+ring12 brick carve, 4 landmark plates (dies from sheet B + offsets +IV/★/+IX/−V), 6 deterministic rack gears composited, hand-less dial enforcement rebuild if drifted | PIL (canonical) | 0 | done |
| 6 | gear props 16/24/36/40/48/72 teeth — EXACT counts asserted in code, canonical render_arabic stamps, diameters proportional to teeth | deterministic PIL (F6) | 0 | done |
| 7 | CU13 cu-gear-frame (interactive; XII/VIII stamps, posts A/B, rust bloom) | crop + native overlay | 0 | done |
| 8 | CU14 cu-gear-rack (teeth countable at iPhone scale) | crop + native gears | 0 | done |
| 9 | CU15 cu-gear-ring (⚙ die + 12 notches = watch B back die) | crop + canonical engrave | 0 | done |
| 10 | CU16 cu-brick-cache (uniform bricks, NO pre-open tell) | pure crop | 0 | done |
| 11 | CU17 cu-clockrow-plates (all 4 dies + offsets crisp, faces hand-less) | crop + native stamps | 0 | done |
| 12 | CU18 cu-cabinet-drawer (shut, top drawer proud) | pure crop | 0 | done |
| 13 | CU19 cu-display-case (F1 paint-over emphasis: sealed screws, skinned seam) | crop + NB edit inpaint | 0.15 | done |
| 14 | inv-toy-mouse cutout (butterfly key round-winged, never square) | NB raw + keyed RGBA | 0.15 | done |
| 15 | inv-oil-can cutout | NB raw + keyed RGBA | 0.15 | done |
| 16 | z1 state: screwdriver taken (bench wide patch) | PIL clone | 0 | done |
| 17 | z1 state: stove tile II taken (wide patch + CU variant) | PIL | 0 | done |
| 18 | z1 state: coat pockets — watch A taken / tile IV taken (2 independent CU overlays) | PIL | 0 | done |
| 19 | z1 state: crate tile VII taken (wide patch + CU variant) | PIL | 0 | done |
| 20 | z1 state: sill tile XI taken (wide patch + CU variant) | PIL | 0 | done |
| 21 | z1 state: door dial 4x seated-tile overlays at 2/4/7/11 (CU + wide echo) | deterministic PIL (same tile renderer as fix #1) | 0 | done |
| 22 | z1 state: cushion empty (cat gone) — crop-scoped NB edit; then watch-reveal via PIL shift + watch B | edit + PIL | 0.15 | done |
| 23 | z1 state: floor cache pried+wheel / empty (CU variants + wide echo) | PIL | 0 | done |
| 24 | z1 state: stair bar raised (CU12 + wide patch) | PIL | 0 | done |
| 25 | z1 state: workroom door open onto z2 (master wide, crop-scoped) | NB edit | 0.15 | done |
| 26 | z1 state: stair door open evening win-beat F4 (door wide, crop-scoped — sanctioned lighting step) | NB edit | 0.15 | done |

Plus (all DONE): z2/z2-review-batch2.png contact sheet, z1/z1-review-batch2-states.png state
sheet, z1/dial-fix-before-after.png, manifest reconciled.

REJECT LOG (all archived to _rejects/): z2-clockrow-base r1 (safe-zone: row spanned outside the
iPad 4:3 band - BUG-004 class, re-rolled head-on/central $0.30); toy-mouse r1 (RGB lost in mask
surgery, same-seed re-roll $0.15); cushion-reveal r1 (watch on floor instead of bench + model-drawn
non-canonical gear die, re-rolled $0.15). Deviation note: items 25/26 (door-open, win) were always
NB edits in this plan ($0.45), vs the resume-note's blanket 'near-$0 PIL' for states.

STEP-10 FLAGS FOR USER: (1) win plate stairs render ASCENDING (spec says only 'onto the tower
stairs'); (2) F1 paint-over strength one notch heavy at the seam (top-corner globs were cropped
out); (3) rack gears read slightly 'decal-flat' vs scene at full zoom.
Worst-case with 2 wide retries: +$0.60. Hard stop well under $15.00 cap.

## Batch 1 record (COMPLETE — user step-10 verdict 2026-07-19: APPROVED WITH ONE FIX = item 1 above)

PROGRESS: 25/25 done | $2.55 total ($2.25 predecessor + $0.30 resumer session) — see
asset-manifest.json batch-1 entries. User: stove-II / crate-VII legibility stretch fine.
Canonical-filename rule honored; cu-master-face frame (540,320)-(2500,1790).

## NOT in batch 2 (later batches)
- z2 state overlays (arbor oiled, 14 post-mount overlays, rack per-gear absent, mural run
  sprites, panel open, brick cache pried/empty, cabinet open+mouse/empty) — batch 4 with
  sprites/state edits.
- Batch 3: z3 (great-dial mirror contract plate — most protected asset) + z4.
