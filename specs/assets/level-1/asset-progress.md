
---

# BUILD-3 consistency re-roll (R2-031 scene->close-up EXACT recreation) [2026-07-09]

PROGRESS: 3/3 close-ups done (Part 1) | 0 retrying | 0 failed | state-variant re-derivation in progress (FREE PIL) | $16.50 spent | cap $18.90 -> ~$2.40 remaining

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
