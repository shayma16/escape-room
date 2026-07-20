# Level 2 asset generation — BATCH 3 (z3 + z4 + gear-frame carry-in fix)

PROGRESS: 1/17 done | 0 retrying | 0 failed | 16 remaining | $0.00 batch spend ($5.55 cumulative) | level cap $15.00

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
| 2 | z3-dial-base wide 3840x1920: chamber contre-jour, glowing amber dial disc from behind (glass BLANK — no numerals/no hands, stamped deterministically after), setting crank at hub + clear D9 staging area, winding drum (dry, square socket, weight low on line), dead-still pendulum, strike train + hammers, linkage rods exiting right, floor hatch w/ 4 blank brass wheels + header plates | NB t2i 4K, 14 refs | 0.30 | pending |
| 3 | z3 glyph integration rev ($0): MIRRORED numeral ring from sheet A -mir set fitted inside measured disc (full 4.2 contract: whole-ring mirror, XII top/VI bottom flipped letterforms, mirrored-IV=malformed-VI, NO legible VII anywhere); hatch wheel I-XII engraves (neutral non-solution position) + 4 canonical header dies (BigBen* Burj Liberty Fuji — binding z3 order); containment asserts | deterministic PIL (l2_z3_build.py) | 0 | pending |
| 4 | CU20 cu-great-dial (interactive; carries clu-mirrored-numerals; native-res mirrored ring re-stamp; D9 space clear; numeral >=5% screen width floor) | crop + native overlay | 0 | pending |
| 5 | CU21 cu-winding-drum (interactive; dry bearing + square socket reads as square absence) | crop (+native detail if upsample soft) | 0 | pending |
| 6 | CU22 cu-hatch-wheels (interactive; 4 header dies + engraved wheel numerals legible simultaneously) | crop + native deterministic wheel band + dies | 0 | pending |
| 7 | dial hand sprites: hour (short, spade tip) + minute (long, plain tip) silhouette soft-edge RGBA, arbor-anchored (D1: Developer renders front time th at mirrored -th; art bakes NO time) | deterministic PIL | 0 | pending |
| 8 | hatch wheel 12-position engraved sprite strip (shared x4 wheels, canonical numerals) | deterministic PIL | 0 | pending |
| 9 | mirror-contract gate sheet: front ring (std) vs back plate side-by-side + malformed-VI/IIV crops + grayscale squint record | PIL | 0 | pending |
| 10 | z4-vault-base wide 3840x1920: strongroom, steps down back-left w/ amber hatch spill, one warm lamp pocket (#D9973F), winding key on hook (large SQUARE bit silhouette — drum-socket rhyme), blank brass tag on nail, shelf (blank ledger spines + wrapped watch), second cushion + empty saucer | NB t2i 4K, 14 refs | 0.30 | pending |
| 11 | z4 glyph integration rev ($0): tag face mini FRONT-VIEW dial FIXED 7:20 (canonical numerals, spade hour @7:20 pos, plain minute on 4) over door die; key square-bit geometry check; containment asserts | deterministic PIL (l2_z4_build.py) | 0 | pending |
| 12 | CU23 cu-tag-nail (7:20 unambiguous at CU + native tag re-stamp) | crop + native overlay | 0 | pending |
| 13 | CU24 cu-key-hook (square bit rhyme legible) | crop | 0 | pending |
| 14 | CU25 cu-shelf (lore inspect; nothing puzzle-bearing, spines glyph-free) | crop | 0 | pending |
| 15 | inv-winding-key cutout (>=1024px RGBA; square bit) | NB raw + keyed RGBA | 0.15 | pending |
| 16 | inv-return-tag cutout (>=1024px RGBA; front face ONLY per D9 — no reverse side; deterministic 7:20 dial + door die identical to cu-tag-nail stamps) | NB blank-tag raw + keyed + PIL | 0.15 | pending |
| 17 | review deliverables: z3+z4 contact sheet + gear-frame before/after + manifest batch-3 block + progress updates | PIL | 0 | pending |

Planned NB spend: $0.90 (2 wides @4K + 2 icon raws @std). Retry reserve $0.60 (wide
re-roll if dial arrives pre-numeraled/hatch wheel count wrong; icon re-key). Worst case
$1.50 -> cumulative $7.05, hard stop far inside the $15.00 cap ($9.45 headroom at start).

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
