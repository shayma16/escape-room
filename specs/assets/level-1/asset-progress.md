
---

# BUILD-3 consistency re-roll (R2-031 scene->close-up EXACT recreation) [2026-07-09]

PROGRESS: COMPLETE (Part 1 + Part 2) | 0 retrying | 0 failed | $17.25 spent | cap $18.90 -> $1.65 remaining, UNDER CAP

_Branch level1-rebuild-build3. 3 flagged close-ups were generated fresh (pre-R2-031) and do NOT match their approved base scenes. Re-derive each by CROPPING the canonical 4K base-plate region and using that exact crop as the `edit` base (NOT a fresh "in the style of" render); enhance detail / apply state only. Model fal-ai/nano-banana-pro, edit endpoint, std tier $0.15._
_Pre-gen estimate (Part 1): 3 fresh edits x $0.15 = $0.45 base; ~$0.90 with a 1-retry buffer each. State variants (basin-filled/drained, vines-withered/gone, bolt-slid; cu-slots-seated/empty; cu-statue-key-taken) = FREE PIL off the corrected close-ups. Part 1 total well under the ~$2.85 remaining -> PROCEED with Part 1._
_Part 2 (G1/G2/G3) evaluated only after Part 1 lands, if budget allows._

## Canonical base facts recorded (downstream close-ups/variants MUST reproduce):
- **z1/v-entry door beak-basin** (base z1-entry-base): carved COOL GREY STONE crow's head on a cool weathered vertical-plank wood door; open beak forms the rune BASIN bowl, beak opening DOWN-RIGHT; iron sliding BOLT directly below with a dark thorny leafless VINE wound around it. NOT brown wood.
- **z2/v-cabinet slots** (base z2-cabinet-base): TWO-DOOR panelled ARMOIRE, dark warm wood; SUN emblem on the LEFT door panel, crescent MOON emblem on the RIGHT door panel, brass ring-pull below each. Recesses (puzzle need) sit ON these door panels. NOT a bank of drawers.
- **z4/v-alcove statue** (base z4-alcove-base): dignified carved BRONZE-BROWN WOOD crow in profile facing LEFT on a plain wood base, on a PLAIN grey stone-block ledge/wall; holds a GOLD skeleton key hanging from beak, bow = open 5-POINT STAR. NOT silver/pewter; NO rune-carved arch.

| # | Asset | Method | Status | Cost | Note |
|---|-------|--------|--------|------|------|
| R1 | z1/v-entry/cu-door-lock-nb | crop base -> edit | done | $0.15 | GREY STONE beak-basin restored (beak down-right, open beak=basin bowl), iron bolt+thorny vine below - matches z1-entry-base. seed 60311. Grayscale PASS. |
| R2 | z2/v-cabinet/cu-slots-nb | crop base -> edit | done | $0.15 | ARMOIRE two doors: SUN recess LEFT door + crescent MOON recess RIGHT door, ring pulls kept (was wrongly drawers). seed 60322. Grayscale PASS (sun vs moon by shape). |
| R3 | z4/v-alcove/cu-statue-key-nb | crop base -> edit | done | $0.15 | GOLD 5-point star key hanging from beak + PLAIN grey stone (was silver + invented rune arch). seed 60344. Grayscale PASS (star reads). |

### Part 1 state-variant re-derivations (from corrected -nb bases)
_Architecture note (confirmed from EscapeRoom Swift): wide-scene door states are OVERLAY-driven (ov-vines-gone etc.); the only door close-up image literals the game LOADS are `cu-door-lock` and `cu-door-lock-vines-gone`. basin/bolt/withered close-up variant files are legacy/overlay-source, delivered correct anyway so no stale painterly art lingers._

| # | Variant | Method | Status | Cost | Note |
|---|---------|--------|--------|------|------|
| V1 | z2/v-cabinet/cu-slots-empty | copy of corrected cu-slots-nb | done | $0 | both recesses empty (armoire, sun-left moon-right) |
| V2 | z2/v-cabinet/cu-slots-seated | edit on corrected cu-slots-nb | done | $0.15 | gold ring embedded in SUN recess + silver crescent-hallmark coin in MOON recess; armoire layout kept. seed 60377 |
| V3 | z4/v-alcove/cu-statue-key-taken-nb | PIL stone-clone over key | done | $0 | key removed, empty beak, plain stone bg (tonally matched; minor soft block-edge in out-of-focus bg, read=no key PASS) |
| V4 | z1/v-entry/cu-door-lock-basin-drained | copy of corrected cu-door-lock-nb | done | $0 | empty grey-stone basin (drained) |
| V5 | z1/v-entry/cu-door-lock-basin-filled | edit on corrected cu-door-lock-nb | done | $0.15 | pearlescent #DCE8F2 pool inside beak bowl, grey stone kept. seed 60391 |
| V6 | z1/v-entry/cu-door-lock-vines-withered | PIL tonal (transient frame) | done | $0 | near-noop safe change on cool-grey vines (vines are grey not warm; withered is a transient pre-gone frame per RoomViewState, not persisted) |
| V7 | z1/v-entry/cu-door-lock-vines-gone | edit on corrected cu-door-lock-nb | done | $0.15 | vines fully removed, clean iron bolt + grey-stone basin - REPLACES old build-2 painterly art (this file IS game-loaded). seed 60412 |
| V8 | z1/v-entry/cu-door-lock-bolt-slid | copy of corrected vines-gone | done | $0 | = unsealed close-up (bolt free); overlay carries the slide motion. PIL rod-shift attempt discarded (bolt mostly below crop + seam artifact) |

Part 1 API spend: $0.45 (3 close-ups) + $0.45 (3 variant edits: slots-seated, basin-filled, vines-gone) = $0.90. Running total $16.95 / $18.90 cap.

### Part 2 (G1/G2/G3) outcome
| Item | Status | Cost | Note |
|------|--------|------|------|
| G1 z1-hearth-rug-moved-nb | done | $0.30 | 4K edit on z1-hearth-base: rug folded back revealing CLOSED trapdoor + iron ring pull. seed 60433. (Developer cuts ov-rug-moved from it.) |
| G1 poker-taken / trapdoor-open | verified done | $0 | z1-hearth-poker-taken-nb + trapdoor-open-nb already fresh-base-aligned canonical build-3 plates. No re-derive needed. |
| G2/G3 cellar wide overlays | VERIFIED NO-OP | $0 | build-3 -nb cellar state plates (barrel-pried/weight-hung/shelf-slid/crank-fitted/drawer-open/mirror-d2/d3) ALREADY exist at 4K 3840x1920 derived from the fresh 4K base. Diff-check: each changes only its local mechanism region (0.8-2.5% px), pixel-identical elsewhere = pixel-aligned + tonally matched. The 2560x1280 plain-named plates are superseded legacy; Developer stages the -nb 4K versions. No re-derivation needed. |

## FINAL — consistency re-roll spend
- Part 1: $0.90 (3 close-ups @ $0.45 + 3 variant edits @ $0.45).
- Part 2: $0.30 (G1 rug-moved 4K; G2/G3 = $0 verified no-op).
- Pass total: $1.20 API. Running project total: $16.05 (build-3 baseline) + $1.20 = **$17.25 of $18.90 cap** (UNDER by $1.65). No items deferred for budget.

---

# BUILD-10 art batch (round-4: letterbox re-frame + R4-007 dial + R4-008 ghost sweep) [2026-07-11]

PROGRESS: 12/12 done | 0 retrying | 0 failed | 0 remaining | $2.10 spent this batch | project $19.35 of $23.00 HARD CAP (UNDER projection $20.20)

_Scope per Producer handoff: (1) re-frame build-3 WIDE plates of all 7 views into style-guide S8
dual-safe band (iPad 4:3 crop x[640,3200] on 3840x1920 @3x; iPhone 19.5:9 band y[74,1846]) so the
Developer restores .aspectFill; crop/outpaint only - content IDENTICAL, only framing changes;
(2) R4-007 moon-dial waning-gibbous presentation fix; (3) R4-008 v-entry ghost-glyph sweep._
_Technique: per view, uniform scale s + offset (ox,oy) -> content canvas; border band outpainted via
nano-banana-pro edit 4K; registered feathered composite keeps interior pixels ORIGINAL (byte-identical);
identical transform propagated to ALL wide state variants of the view (PIL $0, pixel-aligned by
construction); @2x/@1x re-export; superseded plates -> _rejects/build10-pre-reframe/._
_Measured violations (@3x): study flowerpot L155; entry sill-tablet L325 + cage R3710; bench
floor-bellows L270 + mortar R3290; cabinet bottles L45 + window moon R3635; cellar mirror L280 +
winch L550 + ladder R3310; hearth clock crown/cuckoo-door top y10 (iPhone band). z4-alcove PASSES
as-is (statue 2070-2670, planter core central) - verification recorded, no edit._
_Found defects (this batch, fixed at $0 unless noted): cabinet window moon MIRROR-FLIPPED vs canonical
sky-master (corr 0.57 flipped vs 0.08; breaks F1 no-mirror-adjacency intent) -> PIL re-stamp from
sky-master; cabinet second-moon arc artifact at top edge (3550-3840, 0-100) -> PIL clean._
_R4-007 root cause CONFIRMED by simulation: dial-face sprite marks are drawn upright + canonically
correct (wanG dark-bite-RIGHT), but MoonDialControlView rotates the disc -45deg*p, tilting the
at-detent mark; detent p=5 presents dark centroid at (-39,+52) = dark bite LEFT (user report). Fix:
rebuild sprite with each mark PRE-ROTATED +45deg*k so the mark under the top notch presents upright
canonical. PIL, $0; acceptance = simulated-rotation centroid test + waxG/wanG distinctness + grayscale._
_Pre-generation estimate: 1 std edit (ghost clean $0.15) + 6 x 4K outpaint ($1.80) = $1.95 base,
~$2.95 with retries -> projected $20.20 of $23.00 -> PROCEED. fal 403 balance-exhausted = STOP+report._

| # | Item | Method | Status | Cost | Note |
|---|------|--------|--------|------|------|
| 1 | z1-entry ghost-glyph clean (R4-008) | crop edit + canonical PIL WATER stamp -> propagate 6 variants | done | $0 | reused prior-session _work-build10 edit (tablet-final.png, edge ring byte-identical to base); pasted at (240,900) into base + 6 variants; keeps IV + ONE plain WATER down-triangle |
| 2 | z2-cabinet moon canon fix | PIL re-stamp from sky-master + arc cleanup -> propagate 3 variants | done | $0 | diffusion-inpaint of arc/blob/banding + old moon; canonical disc re-stamped from sky-master (circle-fit (1014.7,337.0) r145.2 -> (3561,170) r76); gates: lit-RIGHT centroid +5.1, thirds 136/200, corr n/a-rebuilt. Propagated to drawer-open + open (4K). slots-seated is a 2560x1280 LEGACY-ART plate (content != build-3 base, mean diff 45) -> NOT propagatable, flagged; game uses ov-slots-seated overlay, rect remap applies |
| 3 | re-frame z1-hearth (s .955, ox 86, oy 86) | PIL edge-extend band (outpaint REJECTED, see note) + 3 variants | done | $0.30* | clock crown -> y96 PASS; variants pixel-aligned (poker 1.2%, trapdoor 10.9% local; rug-moved 52% PRE-EXISTING global tone diff of the G1 edit plate, unchanged by re-frame) |
| 4 | re-frame z1-study (s .86, ox 538, oy 240) | PIL edge-extend band + 0 variants | done | $0.30* | flowerpot -> 671 PASS |
| 5 | re-frame z1-entry (s .74, ox 425, oy 250) | PIL edge-extend band + 6 variants | done | $0.30* | tablet 666 / cage 3170 PASS; variants local-diff only (2.6-3.0%) |
| 6 | re-frame z2-bench (s .83, ox 430, oy 163) | PIL edge-extend band + 0 of 3 variants | done | $0.30* | bellows 654 / mortar 3161 PASS; flame1/2/3 are 2560x1280 LEGACY-ART plates (content != base, outside-region diff 40) -> NOT re-framed, flagged; game uses ov-flame overlays, rect remap applies |
| 7 | re-frame z2-cabinet (s .70, ox 630, oy 288) | PIL edge-extend band + 2 of 3 variants | done | $0.60* | bottles 662 / moon 3174 PASS; drawer-open + open re-framed (local diff 0.2%/6.0%); slots-seated legacy flagged (see item 2) |
| 8 | re-frame z3-cellar (s .82, ox 445, oy 173) | PIL edge-extend band + 12 variants | done | $0.30* | mirror 675 / winch 896 / ladder 3159 PASS; spot-checked variants local-diff only (0.6-2.3%) |
| 9 | z4-alcove safe-zone verification (no edit) | measurement only | done | $0 | PASS: statue+key x~[2070,2670], planter core central, shelf inside; dual-safe band overlay verified visually |
| 10 | R4-007 dial-face pre-rotated rebuild | PIL, $0 + staged copy update | done | $0 | root cause confirmed (old sprite p=5 dark centroid (-44.7,+50.5) = bite LEFT); marks pre-rotated +45deg*k cw; ALL 8 detents present upright canonical (sim gate PASS, waxG/wanG asym +30.4/-56.2 distinct, grayscale native); specs @1x/2x/3x + staged Resources dial-face.png updated; old sprite -> _rejects |
| 11 | R4-007 triptych-3 waning-gibbous verify | inspect (fix only if flipped) | done | $0 | PASS: cu-triptych-3 moon lit-LEFT 107.9 vs dark-RIGHT 50.9 = dark-bite-RIGHT canonical; no fix needed |
| 12 | Gates: safe-zone + grayscale on all re-framed plates; manifest build10_reframe; rejects archive | PIL | done | $0 | 10/10 safe-zone element checks PASS; grayscale PASS on all 6 bases; manifest build10_reframe block written (transforms, rect-remap formula, R4-007 sprite/view contract, legacy-plate flags); 90 files archived _rejects/build10-pre-reframe/; shadow-scan clean |

_*Outpaint post-mortem (items 3-8): the planned nano-banana-pro border outpaint was run ($1.80, 6 x 4K)
plus one prompt-variant retest on z2-cabinet ($0.30): ALL outputs re-rendered the scene full-bleed
(registration >= 13.5 mean-abs after +-24px shift search; content redrawn/restyled/moved) - violates the
binding content-IDENTICAL constraint, so all 7 outputs were REJECTED (archived in _work-build10/reframe/).
Bands were instead produced with the deterministic $0 PIL fallback (specs/tools/reframe_b10.py):
edge-replicate smear + progressive blur/darken vignette + grain; seam C0-continuous by construction;
mirror-pad variant was also tested and rejected (duplicated the window moon). Interior content = single
LANCZOS resample, identical transform for base + every variant -> state swaps pixel-aligned by construction.
Overscan bands carry atmosphere only, per style-guide S8._

## FINAL - BUILD-10 batch
- Spend: $2.10 API this batch (6 planned 4K outpaints $1.80 + 1 retest $0.30; all 7 outputs REJECTED for
  content non-identity and archived; bands delivered via $0 PIL fallback specs/tools/reframe_b10.py).
  Items 1,2,9,10,11,12 all $0 PIL. Under the $2.95-with-retries estimate.
- Project total: $17.25 + $2.10 = **$19.35 of $23.00 HARD CAP** (under the $20.20 projection by $0.85).
- All 12 items done, none deferred. Legacy-art plates z2-bench-flame1/2/3 + z2-cabinet-slots-seated
  flagged to Producer (NOT re-framed; overlay rect-remap keeps current behavior).

---

# BUILD-11 gap-fill (18 build-1-era stragglers never rebuilt in build 3) [2026-07-12]

PROGRESS: 20/20 done (incl. 10b + item 20 vintage-guard catch 2026-07-13) | 0 retrying | 0 failed | 0 remaining | $0.45 spent this batch | project $19.80 of $23.00 HARD CAP | headroom $3.20

_Scope per Producer handoff: device test proved 18 build-1 painterly images still ship because
build 3 never generated replacements (not shadows — no new version exists). Rebuild all 18 in
build-3 engine style at canonical paths, R2-031 exact-recreation (crop/composite off existing
build-3 canonical plates), originals -> _rejects/flux-painterly/._
_Pre-generation estimate: 15 of 18 derivable at $0 (PIL crop/composite/stamp). Paid nano-banana
std edits ($0.15) planned ONLY for: cu-cage-crow-refusal (crow pose change), cu-cage-open-empty
(crow removal + door state), cu-winch-crank (crank fitted into socket) = $0.45 base; contingency
(cu-star-keyhole-key composite fallback, cu-crow-rafters / drawer-crop detail enhance, 1 retry
each) caps at ~$1.50. UNDER the $3.65 headroom -> PROCEED._
_Source-state note found during prep: cu-astrolabe-drawer-open (handoff called it build-3) is in
fact still BUILD-1 painterly on disk (git: initial commit only). Usable build-3 source is the
wide z2-cabinet-drawer-open (drawer diff region 2569,1303-2926,1552). Deriving BOTH
cu-astrolabe-drawer-open AND cu-astrolabe-drawer-empty from that crop at $0 — flagged below._

| # | Asset | Method | Status | Cost | Note |
|---|-------|--------|--------|------|------|
| 1 | z1/v-entry/cu-cage-crow-refusal | region edit on cu-cage-crow (pose only) + feathered composite | done | $0.15 | seed 61001, region (940,180,1700,1200); crow turned away/head lowered, perch+cup+bars unchanged, outside-region byte-identical |
| 2 | z1/v-entry/cu-cage-open-empty | edit on cu-cage-crow (crow removed/door open), refs wide cage-open | done | $0.15 | seed 61010, region (620,120,1980,1420); crow GONE + right-side barred door ajar (matches wide), perch+cup intact |
| 3 | z1/v-entry/cu-crow-rafters | PIL crop z1-entry-crow-lintel (freed-crow perch = lintel per b3 canon) | done | $0 | crop (1400,0,2600,900)->2048x1536; crow on hinge strap above beak-basin, exact-recreation |
| 4 | z1/v-entry/cu-star-keyhole-key | PIL composite icon-cage-key geometry (gold) into cu-star-keyhole | done | $0 | icon rotated 140.2deg, cut before star bit (inserted), gold LUT from statue-key canon + cool ambient, 12deg gravity droop, soft shadow; anchored in star keyway (1060,736)@3x. Grayscale PASS |
| 5 | z1/v-hearth/cu-trapdoor-open | PIL crop z1-hearth-trapdoor-open wide (open-lid + dark mouth region) | done | $0 | crop (1800,1100,2893,1920)->2048x1536; lid+mouth+rug edge |
| 6-8 | z2/v-bench/sprites/rune-ember-I/II/III | PIL ember-glow stamps masked from cu-brew brass numerals (canonical I/II/III) + rects json update | done | $0 | plaque cutouts from cu-brew-clear w/ white-hot channels + orange halo; rects: I(624,161,279x293) II(1190,169,306x303) III(1543,473,255x326) — MOVED vs build-1, rects json updated w/ size_3x + Swift-sync note (CloseUpLayout.brewEmberRects). Grayscale PASS (stroke count) |
| 9 | z2/v-bench/sprites/ladle-ripple-ccw | PIL CCW arc trail matched to b3 brew liquid | done | $0 | 900x700 RGBA tapered comet arc + glow + echo, pale blue-white matched to liquid; same handedness/geometry as build-1 sprite (game mirrors x for CW) |
| 10 | z2/v-cabinet/cu-astrolabe-drawer-empty | PIL crop wide z2-cabinet-drawer-open + coin/crank removal | done | $0 | row-interp inpaint + felt grain re-tex; coin (838,928)-(1074,1068) + crank (1126,958)-(1350,1100) + front cast shadow removed; NET-NEW file (game-loaded CloseUps.swift:139, was missing) |
| 10b | z2/v-cabinet/cu-astrolabe-drawer-open (FLAGGED extra, $0) | same crop, items kept | done | $0 | crop (2400,1150,3100,1675)->2048x1536 + unsharp 70%; coin hallmark + Z-crank crisp at 2.93x upscale, no paid enhance needed |
| 11-16 | z2/v-cabinet/sprites/astrolabe-plate-1..6 | PIL brass discs sampled from cu-astrolabe; dots re-stamped from b3 plate-N-nb close-ups; plate-2 = canonical Orion (masters/orion-canonical.json) | done | $0 | ONE clean disc base (plate-6-nb, polar-interp fill of dots/hub/needle/ghost-dimples) + ONE canonical dot stamp; plates 1,3-6 = their 7 detected dark dots (uniform r29@3x-closeup); plate-2 = EXACT canonical Orion offsets+scales, belt-centered. NOTE: -nb close-ups carry ghost dimples of other plates' holes (gen artifact, excluded); plate-2-nb close-up itself has DRIFTED Orion (not game-loaded, reference-only — flagged). Window-clue vs plate-2 side-by-side match PASS; grayscale PASS |
| 17 | z2/v-cabinet/sprites/astrolabe-pointer | PIL brass needle matched to cu-astrolabe pointer | done | $0 | 900x90 RGBA 4x-supersampled; palette sampled from cu-astrolabe needle cross-section (body 118,97,62 / dark edge / cool specular ridge); hub boss+ring+pin |
| 18 | z3/v-cellar/cu-winch-crank | region edit on cu-winch-socket, refs icon-crank + wide crank-fitted crop | done | $0.15 | seed 61020, region (600,480,1780,1500); Z-crank seated in square socket; grip came back WOOD -> $0 PIL recolor to all-steel per icon + wide canon |
| 20 | z2/v-cabinet/cu-cabinet-open (ADDED 2026-07-13, vintage-guard catch) | PIL crop wide z2-cabinet-open (b3 canonical open-state) + unsharp(r2,35%) | done | $0 | crop (1112,300,2952,1680)->2048x1536 (1.11x); full armoire standing open, sun medallion on open left door / crescent + ring pull on right, FILE + PHIAL on middle shelf; build-1 t2i photoreal original -> _rejects/flux-painterly/; A/B vs wide + cu-slots-seated PASS (pixel-derived); grayscale PASS; Developer can drop the KNOWN_LEGACY_SOURCES exception for this path |

## FINAL - BUILD-11 gapfill
- All 19/19 done (18 planned + 10b drawer-open extra). Spend: $0.45 API (3 std region edits; every retry/fix was $0 PIL) - under the $0.45 base / $1.50 contingency estimate.
- ITEM 20 (2026-07-13): Developer's new vintage guard caught a 20TH stale build-1 file the batch missed -
  cu-cabinet-open (game-loaded, was shipping via tracked KNOWN_LEGACY_SOURCES exception). Re-delivered $0 PIL
  from the b3 wide open-state; total batch count is now 20, spend unchanged.
- Project total: $19.35 + $0.45 = **$19.80 of $23.00 HARD CAP** (headroom $3.20 remaining).
- cu-astrolabe-drawer-empty was MISSING entirely (game-loaded, CloseUps.swift:139) - net-new, live defect fixed.
- HANDOFF FLAGS: (1) rune-ember rects MOVED - Developer must sync CloseUpLayout.brewEmberRects + staged Resources copy of rune-ember-rects.json;
  (2) plate-2-nb close-up (reference-only) shows drifted Orion vs masters/orion-canonical.json - sprites use the canon, close-up flagged to Producer;
  (3) all 20 need staging into EscapeRoom/Resources/GameAssets by Developer (specs/ is source of truth);
  (4) item 20: remove the KNOWN_LEGACY_SOURCES exception for z2/v-cabinet/cu-cabinet-open and restage it.
- Manifest: build11_gapfill block written (per-asset source-derivation + geometry + gates); item 20 appended 2026-07-13.
