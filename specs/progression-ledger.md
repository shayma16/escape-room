# Progression Ledger

_Maintained by the Producer. This is the cross-level memory that keeps difficulty
escalating, mechanics varied, art style consistent, and spend visible._

## Per-level difficulty scores

_(from each level's validation-report.md; per-zone and overall)_

| Level | Theme | Overall difficulty | Per-zone scores | Status |
|-------|-------|--------------------|-----------------|--------|
| 2 | The Clockmaker's Attic (mechanical/time: gear ratios, clock hands, time zones, Roman numerals; attic-as-machine) | 6.5/10 (Validator official, rev 1.2: z1 5.0 · z2 7.0 · z3 7.0 · z4 3.5) | z1 Main Attic 5.0 · z2 Movement Loft 7.0 · z3 Behind the Great Dial (hidden) 7.0 · z4 Clockmaker's Vault (hidden nested, reward room) 3.5 | IN DESIGN: graph rev 1.2 validated PASS (delta re-verification 2026-07-18); user checkpoint rulings applied (IV not IIII; Dubai/Big Ben/Liberty/Fuji city set, vault code VI-X-I-III; mirror-trap easing valve D9 spec'd dormant). Next: blind layout -> Blind Playtester |
| 1 | The Wizard's Cabin (abandoned wizard's cabin in the woods; caged crow, potions) | 6.0/10 (Validator official; unchanged at rev 1.3) | z1 Main Room 5.0 · z2 Potion Workshop 6.0 · z3 Hidden Cellar 4.0 · z4 Walled Alcove 5.0 | RELEASED to TestFlight (build 1) 2026-07-06. Feedback round 1 IN PROGRESS 2026-07-07 → build 2: puzzle-graph rev 1.3 (clue-gating) validated PASS (difficulty holds 6.0); Developer fix batch + art fixes running. Art spend $8.63 (+ round-1 fixes TBD) |

## Puzzle mechanics used

_(track so later levels escalate and don't over-repeat)_

| Mechanic | Levels used in | Notes |
|----------|----------------|-------|
| Environmental scavenger hunt + symbol mapping (ordered code) | 1 | Element runes + Roman numerals → workshop door |
| Shape-orientation dial code (moon phases) | 1 | Pure shape copying; no lunar knowledge required |
| Star-pattern matching (RWK-assisted) | 1 | Orion; solvable as pure dot-matching |
| Dual-cue item placement (knowledge + physical fit) | 1 | Sun/gold, moon/silver cabinet lock |
| Tool-on-hotspot hidden items | 1 | Poker in ash, file on shavings, etc. |
| Counterweight/mechanism completion (nested zone unlock) | 1 | Cellar alcove shelf |
| Light-routing apparatus (winch + mirror) | 1 | Moonbeam to moonflower/alcove; latched condition |
| Character interaction beat | 1 | Crow's freely-given feather |
| Item combination | 1 | File + spoon → silver shavings |
| Procedural brewing (parameterized, order-free ingredients) | 1 | Flame III, 5 CCW stirs; precision peak of level |
| Numeric-code lock | — | Deliberately ABSENT from level 1 (theme cohesion); USER DIRECTIVE 2026-07-04: include in a future level |

## Real-world-knowledge domains used

_(track so knowledge puzzles stay varied and calibrated)_

| Domain / fact | Level | User-approved? |
|---------------|-------|----------------|
| Roman numerals I–IV | 1 | Yes (2026-07-04 checkpoint) |
| Orion's Belt star pattern | 1 | Yes (2026-07-04 checkpoint) |
| Alchemical sun=gold / moon=silver | 1 | Yes (2026-07-04 checkpoint) |
| Moonflowers bloom in moonlight (folkloric) | 1 | Yes (2026-07-04 checkpoint) |

## Approved style-reference image library (cumulative, all levels)

_Feed the FULL list to Asset Generation before every level, not just the previous
level's, to prevent cross-level style drift._

| Image path | Level | Zone | What it anchors |
|------------|-------|------|-----------------|
| specs/assets/level-1/masters/sky-master@3x.png | 1 | shared | Canonical night sky: waxing gibbous ~85%, Orion at 35° (geometry in masters/orion-canonical.json — binding for z2 astrolabe plate-2 + workshop window); series mood anchor |
| specs/assets/level-1/z1/v-hearth/z1-hearth-base@1x.png | 1 | z1 | Series look: painterly realism, warm/cool duet, wood/stone material rendering |
| specs/assets/level-1/z1/v-study/z1-study-base@1x.png | 1 | z1 | Desk/grimoire/triptych dressing density; prop register |
| specs/assets/level-1/z1/v-entry/z1-entry-base@1x.png | 1 | z1 | Door/vines/cage focal treatment; composited canonical sky in window pane |

## Cumulative Flux API spend

| Level | Estimated | Actual | Running total |
|-------|-----------|--------|---------------|
| 1 — batch 1 of 4 (sky + z1) | ~$4.70 nominal / ~$6 w/ retries | $4.11 (80 generations incl. all retries/rejects + $0.04 Producer verification probe) | $4.11 |
| 1 — batch 2 of 4 (z2 workshop) | <$5 cap | $2.01 (57 attempts, 54 billable; crop-scoped edits kept variants cheap) | $6.12 |
| 1 — batch 3 of 3 (z3 cellar + z4 alcove + icon cleanup) | ~$2.50 proj / $4 cap | $1.99 (62 calls, 61 ok) | $8.11 |
| global (one-time): app icon + launch screens | $2 cap | $0.41 (4/4 ok, zero retries; launch screens $0 PIL) | $8.52 |
| 1 — BUG-004 re-frame batch (QA fix: dual-safe-zone violations; 4 views re-framed) | ~$0.35 proj / $4 cap | $0.11 (11 crop-edits; all moves/verification $0 PIL; safe-zone + grayscale + orion-canonical checks PASS) | **$8.63** |

**Post-release feedback round 4 (build 9, processed 2026-07-11).** No difficulty rescore —
no balance changes requested or made; Level 1 holds 6.0. Mechanics touched by the routed
fixes: item-lifecycle engine (uses-driven retain/consume — fixes the poker soft-lock
R4-019 and non-consumption R4-030; preserves anti_softlock_invariants), manual-pickup
uniformity (weight, statue key), armed-item interaction model (deselect +
inspect-while-armed), scene-state rendering (full-plate swaps → per-element overlay
compositing), p02 waning-gibbous dial art corrected to spec (dark-bite-RIGHT, matches
triptych). Solvability: build 9 verified completable end-to-end (standard order) by the
user; alternate-order completability restored by the lifecycle fix (Validator to
re-confirm).

_Report the running total to the user after each level completes._

## Reusable production tooling (Level 2+)

- `specs/tools/beam_engine.py` — deterministic PIL beam compositor pinned to #DCE8F2
  (r/b 0.909, g/b 0.959). USE THIS for every future light-shaft/moonbeam plate; Flux
  full-frame beam attempts drifted twice in Level 1 and were rejected.
- `specs/tools/fal_gen.py` — queue-based Flux 2 Pro driver (t2i + crop-scoped edits,
  @1x/@2x/@3x export, per-image cost logging). Crop-scoped edits are the standing
  state-variant technique (~25x cheaper than full-frame re-renders, pixel-aligned).
- fal seed-replay is NOT reproducible — never plan on regenerating a plate by seed.

**Post-release feedback round 6 (build-11 milestone, processed 2026-07-14).** No difficulty
rescore — no balance change; Level 1 holds 6.0. Mechanics touched: container-reveal→collect
taken-state rendering (close-up + wide) and hotspot/overlay re-frame coordinate remap (both
render/UX, not logic); rusted key demoted to non-collectible decoy (no solve path used it);
grimoire recipe stir glyph corrected to canon (5 CCW — clue, not solution). Art re-rolls this
round: recipe spiral crop-edit, EARTH glyph re-stamp ($0), re-frame band sweep, un-deferred
QA-B10-002 flame1/2/3 + slots-seated. Est. art spend this round ~$0.79 (worst case ~$2.61) —
within the $3.20 headroom on the $23.00 cap. R6-009 poker-lifecycle: unconfirmed; gated on
screenshot-based alt-order UI validation before release.

**Build-11 spend update (2026-07-12):** gap-fill batch (19 never-regenerated build-1 files
incl. one game-loaded image that never existed) = $0.45. **Running Level-1 art total: $19.80
of the $23.00 hard cap** ($3.20 headroom). Nano Banana Pro since 2026-07-08 (earlier rows
above were the Flux era; tooling notes above predate the switch — fal_gen.py now targets
fal-ai/nano-banana-pro).
