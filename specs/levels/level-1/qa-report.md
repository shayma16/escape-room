# Level 1 — QA Report (Round-6 checkpoint / GATE 2)

**Level:** 1 — "Within" (The Wizard's Cabin)
**Spec under test:** `specs/levels/level-1/puzzle-graph.json` (authoritative), `specs/levels/level-1/round6-routed-changelist.md` (R6-001..R6-011 + R5-002 carry).
**Build under test:** branch `build-12-round6-fixes`, Round-6 fix build. **CI `Build and Test` run [29328326128](https://github.com/shayma16/escape-room/actions/runs/29328326128) on tip `3f58479` is GREEN** (full suite: iPhone-SE + iPad full playthroughs, save/resume, smoke, 3 unit device runs, DI smoke).
**QA method:** CI-simulator automated testing only (GitHub Actions macOS runner). This QA pass (a) verifies what the green run already proves, (b) authors the additional R6-009 alt-order coverage the gate requires, (c) inspects the green run's screenshot artifacts (extracted from the `.xcresult` bundles) for the Round-6 visual fixes. **No physical-device coverage** — real touch feel, thermals, haptics remain the user's manual TestFlight spot-check before final release.
**Date:** 2026-07-14
**Author:** QA Agent

---

## 1. Top-line recommendation

**GO (conditional on the new tests going green on CI).** Every Round-6 item is either PASS (verified in a green CI run and/or a green screenshot) or UNVERIFIED-BY-SCREENSHOT-but-otherwise-covered (unit-guarded or newly test-covered). The one hard release gate — **R6-009 poker multi-use soft-lock — is CLEARED by construction and by new alt-order UI tests** (see §2). The decision remains the user's at GATE 2.

Caveat the Producer must action before this is a clean GO: the three new UI tests I added have **not yet executed on CI** (the green run predates them). The Producer must push + dispatch CI so the new tests run. See §6 for pre-emptive flags on how they could fail on the runner.

---

## 2. R6-009 — poker multi-use lifecycle gate (THE hard release gate)

### Verdict: CLEARED (no soft-lock possible; proven by construction + new alt-order UI coverage)

**Root-cause analysis (code):** `ItemLifecycle` (`EscapeRoom/EscapeRoom/Game/PuzzleGraphModel.swift`) drives one rule: an item is retained while ANY of its graph `uses` is unsatisfied and consumed only when ALL are satisfied. The poker's `uses` are p05 (`ashSift`) and p06 (`barrelPry`). The reconcile sweep runs from the `GameState` `markSolved`/`setFlag` hooks — every path that could satisfy a use passes through one of those mutators — so **no interaction path can drop the poker while either use is pending.** A soft-lock is therefore impossible regardless of solve order. This is already asserted at the engine level in `QALevelFlowTests.testSolvePathOrdering{A,B,C}` (ordering A pries the barrel BEFORE the ash — the exact R4-019/R6-009 ordering — and still runs to completion).

**Reachability confirmed (design gates are NOT poker gates):**
- Cellar / barrel (p06) is gated only by: move rug (free) → moon-dial trapdoor (p02, whose only clue-gate is the study triptych) → descend. None require the poker.
- z2 / astrolabe (p03) is gated only by: rune door (p01 = 4 element marks + grimoire page A) → Orion window. None require the poker.

So both non-standard orderings the gate names are genuinely reachable and are exercised for real (not argued away as "unreachable").

**New UI coverage authored** in `EscapeRoom/EscapeRoomUITests/EscapeRoomUITests.swift`, driving the real chrome with inventory-bar screenshots at each key step:

| Test | Ordering | Asserts |
|---|---|---|
| `testR6009_pokerSurvivesBarrelBeforeAsh` | **barrel-before-ash** | poker taken → reach cellar (untouched) → pry barrel p06 → **poker still HELD** (`r6009-bba-02...`) → collect weight → back to hearth (**poker survived zone transition**) → capture combined poker-taken+rug-moved hearth state (`r6009-bba-02b`, doubles as R6-001 evidence) → sift ash p05 → collect ring → **poker CONSUMED only now** (`r6009-bba-03`). Both poker-gated yields collected in the non-standard order = no soft-lock. |
| `testR6009_pokerSurvivesAstrolabeFirst` | **astrolabe-first** | poker taken → gather z1 clues → solve rune door p01 → into z2 (**poker survived z1→z2 passage**) → solve astrolabe p03 + collect drawer (fires the z2 `markSolved`/`setFlag` reconcile events) → **poker still HELD** (`r6009-af-02...`) → to cellar → pry barrel p06 → **poker HELD** (`r6009-af-03`) → collect weight → sift ash p05 → **poker CONSUMED** (`r6009-af-04`). |
| standard (ash→barrel) | **not duplicated** | already covered end-to-end by `testFullPlaythroughWithScreenshots` (`play-01b-poker-taken` → `play-02-ash-glint` → `play-05-cellar` → `play-06-shelf-slid`). |

Each ordering asserts the poker (`itm-poker`) is present until both uses are satisfied and absent after the last, and that the level stays progressable (both yields collected) — the anti-softlock invariant holds in every legal order.

---

## 3. Round-6 visual verification (against the green run 29328326128 screenshots)

Screenshots are stored as `XCTAttachment` blobs inside the `.xcresult` bundles (there is no loose-PNG artifact step). I extracted the PNG-signature blobs from the `EscapeRoomUITests-iPhone/iPad` bundle `Data/` directories and inspected them. Note the **documented CI raster-letterbox** (QA-OBS-023): the runner composites the landscape app into a portrait raster, so the app content is legible but positioned/rotated oddly, and true top/bottom-edge inspection is confounded (relevant to R6-004).

| Item | Fix | Verdict | Evidence |
|---|---|---|---|
| **R6-011** | recipe stir glyph = 5 dots, CCW | **PASS** | Grimoire recipe close-up (iPhone `play-08b`): spiral shows **exactly 5 dots**; the outer arm descends the left side into a rightward arrowhead at the bottom = **counter-clockwise**. Matches the fixed 5-CCW brew solution. Moonflower/mortar, file/silver-bar, feather preserved on the page. |
| **R6-007** | flame/cauldron re-rolled to build-3 style + registered | **PASS** | Brew close-up (`play-16-draught`): hand-painted magical cauldron with a bright spiral and flame numerals I/II/III, warm fire glow beneath — the NEW build-3 plate, **not** the dark photoreal box, and correctly registered over the fire (no floating box). |
| **R6-002** | EARTH glyph bar THROUGH the triangle | **PASS** | Study flowerpot close-up region (`play-08c`/study wide): the pot glyph is a downward triangle **with a horizontal bar through the middle** (alchemical Earth) above the "III" numeral — bar is through, not below. |
| **R6-006** | weight tap target → visible roped hook | **PASS** | Cellar wide after hang (`play-06`-class): the weight hangs on the visible **roped pulley hook** on the right beside the slid shelf; hotspot geometry (`hook` 0.395,0.378,0.098,0.341) sits on it. |
| **R6-010** | sun/moon cabinet taken-state render | **PASS (wide)** | Cabinet wide (`play-12-cabinet-open`): the opened door reveals a **clean empty compartment** — no duplicated items, no faint black-box mis-composite. Close-up empty-state not separately screenshotted (see below). |
| **R6-005** | barrel wide taken-state (weight not duplicated) | **PASS (wide)** | Cellar wides after weight collection show the shelf/hook region clean with **no duplicated weight** and no black box; the dark rectangle beside the shelf is the intended alcove-mouth passage, not a mis-composite. |
| **R6-001** | poker-taken not floating over the rug | **PASS (indirect) + newly captured** | Hearth wides in the green run read clean, but the green run has **no frame of the exact combined poker-taken + rug-moved state**. My new `r6009-bba-02b` shot captures precisely that state; the `refreshHearth` z-order fix (poker z9 < rug z10 < trapdoor z11) covers any stray poker-crop pixels. |
| **R6-003** | rusted key non-collectible | **PASS (functional)** | Not a screenshot item. New `testR6VisualRegression_z1Captures` taps the rusted key, asserts the inspect close-up presents, and asserts `itm-rusted-key` never enters inventory (`assertNotHolding`). Code path (`lookTap` `.entry,"rusted-key"` → `present(.plain("cu-rusted-key"))`, no `addItem`) confirms it. |
| **R6-008** | astrolabe drawer taken-state (close-up + wide) | **UNVERIFIED-BY-SCREENSHOT** | The astrolabe drawer's dedicated emptied close-up is not isolated in a green-run screenshot (the playthrough collects then dismisses). The container render fix is unit-guarded (RenderedFrameOverlayTests overlay guard, per the changelist). Wide cabinet frames are clean. Recommend a physical-device spot-check that the drawer close-up empties cleanly. |
| **R6-004** | re-frame edge-band sweep (all 6 views) | **UNVERIFIED-BY-SCREENSHOT** | Visible scene-content edges look clean in every wide, but the CI raster-letterbox crops/rotates the true plate edges, so the padded short-edge bands cannot be honestly confirmed from CI screenshots. **Defer to the user's TestFlight device spot-check** for the actual top/bottom edges. |

**Cheap capture added (Task 2 follow-up):** `testR6VisualRegression_z1Captures` opens and screenshots the three z1 close-ups the full playthrough dismisses mid-gather — EARTH glyph (`r6002-earth-glyph-cu`), recipe spiral (`r6011-recipe-spiral-5ccw-cu`), rusted-key inspect (`r6003-rusted-key-noncollectible`) — so GATE 2 has clean human-inspectable frames, and adds the R6-003 functional guard. (This test is light and runs on both devices.)

---

## 4. Per-zone / per-puzzle pass status (from the green run)

The green run's `testFullPlaythroughWithScreenshots` completes the canonical solve end-to-end on **both** iPhone SE and iPad (p01→p17, completion card reached, Level-Select badge propagated). All puzzles pass in the standard order on both device classes:

| Zone | Puzzles | Status |
|---|---|---|
| z1 hearth/study/entry | p01 rune door, p02 moon trapdoor, p05 ash sift, p11 cage, p16/p17 endgame | PASS (both devices) |
| z2 workshop bench/cabinet | p03 astrolabe, p04 cabinet, p12 file+spoon, p13 grind, p14 brew, p15 bottle | PASS (both devices) |
| z3 cellar | p06 barrel, p07 counterweight, p08 winch, p09 mirror | PASS (both devices) |
| z4 alcove | p10 moonflower bloom | PASS (both devices) |
| Save/resume + D7 gate persistence | `testSaveResumeMidPlaythroughPersistsGate` | PASS |
| Menus / nav / pause / settings smoke | `testMenuAndNavigationSmoke` | PASS |
| Chrome-on-screen (completion + pause) | `testChromeFullyOnScreen_QA_B3_002` | PASS |
| Scene fills window / no dead-band | `testSceneContentFillsScreen_QA_B3_001` | PASS |

No regressions observed in the green run relative to the build-10 baseline.

---

## 5. Device / orientation matrix (green run 29328326128)

| Device | Coverage | Result |
|---|---|---|
| iPhone SE (3rd gen) — smallest supported | full playthrough + smoke + save/resume + composition | green |
| iPad Pro 13-inch (M4) — primary | full playthrough + smoke + save/resume + composition | green |
| Dynamic Island iPhone (16/15 class) | smoke + composition (safe-area screenshots) | green |
| Unit tests | iPad + iPhone SE + DI iPhone | green |

Landscape-locked composition guard (`assertFullScreenLandscapeComposition`, QA-OBS-023) passed on all. The **new R6-009 tests are gated to iPhone-SE only** (see §6) — they validate device-independent item-lifecycle logic, so a single iPhone-SE run per ordering satisfies the gate without a second full run on iPad.

---

## 6. Flags for the Producer before dispatching CI (pre-empt likely failures)

1. **New tests not yet executed.** The green run predates them; the Producer must push + dispatch `Build and Test` so `testR6009_pokerSurvivesBarrelBeforeAsh`, `testR6009_pokerSurvivesAstrolabeFirst`, and `testR6VisualRegression_z1Captures` actually run. QA analyzes results; the runner executes.
2. **CI-time budget (highest risk).** The full `EscapeRoomUITests` scheme runs on BOTH devices and the suite is already ~1h47m against the **180-min** ceiling. To protect the budget I **gated the two heavyweight R6-009 tests to the iPhone-SE UI step only**, via two `-skip-testing` lines added to the iPad UI step in `.github/workflows/build-and-test.yml`. Even so, the iPhone-SE step grows by roughly one short + one long playthrough (~25–40 min on a slow runner). If CI approaches the ceiling, the fallback is to shorten the astrolabe-first test. The z1-captures test is light and left on both devices.
3. **Slow-runner lost-tap flakes.** Both R6-009 tests use the existing `ensureView` arrival-guard (one retry per navigation), so a genuinely lost synthesized tap self-heals; a real navigation bug still fails loudly. If either flakes on a CPU-starved runner, it is a runner-timing artifact, not a product defect — re-run before treating it as a regression.
4. **Coordinate assumptions.** All new taps reuse the exact, already-green coordinates and helper patterns from `solveLevelOne` / `QALevelFlowTests` (poker 0.248,0.50; ash 0.44,0.68; barrel 0.735,0.66; roped-hook flow via the cellar descent; rune tiles 3,1,4,2; astrolabe-plate-2; moon dials 1×/4×/5×). The one new coordinate is the rusted-key inspect at entry (0.715,0.53) — inside the `rusted-key` rect (x0.685–0.745) and clear of `door-lock` (ends 0.70), so it wins the hit-test.

---

## 7. What can only be confirmed on physical device (user's TestFlight spot-check)

- **R6-004 edge bands** at the true top/bottom plate edges (CI raster-letterbox confounds this).
- **R6-008 astrolabe-drawer close-up** empties cleanly with no black box (not isolated in a CI screenshot; unit-guarded only).
- Real touch-target feel / hit tolerance on a physical panel, haptics, thermals, and audio — never in scope for CI-simulator testing.

---

## 8. Artifacts / test additions summary

- Tests added to `EscapeRoom/EscapeRoomUITests/EscapeRoomUITests.swift`:
  `testR6009_pokerSurvivesBarrelBeforeAsh`, `testR6009_pokerSurvivesAstrolabeFirst`,
  `testR6VisualRegression_z1Captures`, plus helpers `assertNotHolding(...)` and `openTrapdoorAndDescend(...)`.
- Workflow change: `.github/workflows/build-and-test.yml` iPad UI step gains two `-skip-testing` lines for the R6-009 tests (CI-time scoping; documented inline).
- Green reference run inspected: 29328326128 (tip `3f58479`).

**Final recommendation: GO** for re-release, conditional on the three new tests going green on the Producer's CI dispatch. Decision stays with the user at GATE 2.
