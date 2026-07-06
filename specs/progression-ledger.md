# Progression Ledger

_Maintained by the Producer. This is the cross-level memory that keeps difficulty
escalating, mechanics varied, art style consistent, and spend visible._

## Per-level difficulty scores

_(from each level's validation-report.md; per-zone and overall)_

| Level | Theme | Overall difficulty | Per-zone scores | Status |
|-------|-------|--------------------|-----------------|--------|
| 1 | The Wizard's Cabin (abandoned wizard's cabin in the woods; caged crow, potions) | 6.0/10 (Validator official; Designer est. 6.5) | z1 Main Room 5.0 · z2 Potion Workshop 6.0 · z3 Hidden Cellar 4.0 · z4 Walled Alcove 5.0 | QA COMPLETE 2026-07-05 — NO-GO recommended (engine faithful, 22 bugs: 7 critical in UI/presentation layer); at step-13 user checkpoint |

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
| global (one-time): app icon + launch screens | $2 cap | $0.41 (4/4 ok, zero retries; launch screens $0 PIL) | **$8.52** |

_Report the running total to the user after each level completes._

## Reusable production tooling (Level 2+)

- `specs/tools/beam_engine.py` — deterministic PIL beam compositor pinned to #DCE8F2
  (r/b 0.909, g/b 0.959). USE THIS for every future light-shaft/moonbeam plate; Flux
  full-frame beam attempts drifted twice in Level 1 and were rejected.
- `specs/tools/fal_gen.py` — queue-based Flux 2 Pro driver (t2i + crop-scoped edits,
  @1x/@2x/@3x export, per-image cost logging). Crop-scoped edits are the standing
  state-variant technique (~25x cheaper than full-frame re-renders, pixel-aligned).
- fal seed-replay is NOT reproducible — never plan on regenerating a plate by seed.
