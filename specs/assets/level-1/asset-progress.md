
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
