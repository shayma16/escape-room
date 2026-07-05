# Level 1 — QA Report (pipeline step 12)

**Level:** 1 — The Wizard's Cabin
**Spec under test:** `specs/levels/level-1/puzzle-graph.json` rev 1.2 (authoritative), `style-guide.md` §7–8, `global-ui-style.md`, `implementation-notes.md` (Developer judgment calls 1–9)
**Build under test:** commit `d024ca8` lineage, `EscapeRoom/EscapeRoom.xcodeproj`, iOS 17+, landscape-locked
**QA method:** CI-simulator automated testing only (GitHub Actions macOS runner, `build-and-test.yml`) + static code inspection + local verification of hotspot geometry against the shipped art plates. No physical-device coverage — real-touch/thermals/haptics remain the user's manual TestFlight spot-check before final release approval.
**Date:** 2026-07-05

## CI runs

| Run | Purpose | Result |
|---|---|---|
| [28745052491](https://github.com/shayma16/escape-room/actions/runs/28745052491) | Developer's green reference build (29 unit tests) | green |
| [28745747644](https://github.com/shayma16/escape-room/actions/runs/28745747644) | First QA-suite run | red — harness structure issue, but empirically exposed **QA-BUG-022** (game art unreachable in the built app bundle) |
| [28745951536](https://github.com/shayma16/escape-room/actions/runs/28745951536) | **Canonical QA run** | **green — 57 tests × 2 device jobs, 0 unexpected failures; all 10 QA-BUG expected-failure records reproduced on both devices** |

QA additions live in `EscapeRoom/EscapeRoomTests/QALevelFlowTests.swift` (38 tests: 28 verification tests that must stay green forever, plus 10 strict `XCTExpectFailure` bug records named `testQA_BUG_nnn_*`). Strict mode means: when the Developer fixes a bug, its record test fails loudly ("expected failure but none recorded") — the fix signal is automatic; the Developer then unwraps the assertion into the permanent regression net. Result bundles (`EscapeRoom-iPad.xcresult`, `EscapeRoom-iPhone.xcresult`) were downloaded and archived from the canonical run.

**Device matrix executed:** iPad Pro 13-inch (M4) simulator and iPhone SE (3rd generation) simulator — the matrix floor from `global-ui-style.md` §11. No XCUITest target exists yet, so screen-level behavior (SwiftUI overlays, real drag gestures, menu navigation, screenshots) was verified by code inspection and coordinator-level tests, not by driven UI automation. See "Test-infrastructure requests" below.

---

## Overall verdict: **NO-GO** (recommendation — decision is the user's)

The puzzle **engine** is a faithful, order-independent implementation of the graph: all three example orderings (including mirror-first C), every failure behavior, D1–D5, and every anti-softlock invariant pass at engine level on both simulators. But the **interaction and presentation layers are incomplete to the point that the level cannot be finished in the actual app by any path**, on any device, for five independent reasons (QA-BUG-001, -002, -003, -012, -022), plus an iPad-specific blocker (QA-BUG-004). This is not a difficulty or design problem — it is unfinished wiring between the (correct) engine and the screen.

---

## 1. Pass/fail matrix — per puzzle node

"Engine" = PuzzleEngine logic vs. graph (automated, both simulators). "UI path" = can a player actually perform it in the built app (code-inspection + coordinator tests).

| Node | Engine | UI path | Notes |
|---|---|---|---|
| p01 rune door | PASS | **FAIL** | Logic + tile mapping correct (see JC-2). But: v-study unreachable from fresh save (BUG-001); tile hotspots misaligned vs the actual press-plate art (BUG-015); no `cu-runedoor-tiles` close-up (BUG-013); scene taps dead without textures (BUG-022) |
| p02 moon trapdoor | PASS | **FAIL (partial)** | Dial logic order-free, retains position, no lockout — PASS. But dial UI floats over the hearth from level start with no rug discovery (BUG-010), dial faces 84 pt vs ≥200 pt iPhone floor (BUG-011) |
| p03 astrolabe | PASS | **FAIL** | Engine rejects plates 1/3/4/5/6, no lockout — PASS. But the tap handler passes the solution plate itself: one bare tap auto-solves p03; the six-plate mini-game does not exist (BUG-005); astrolabe hotspot misaligned & partly outside iPad crop (BUG-004/-015) |
| p04 cabinet | PASS | PARTIAL | Correct/swap/reject logic and yields PASS. No rejection feedback and stale pending placements (BUG-017) |
| p05 ash sift | PASS | PASS* | Tap and drop paths both work (*subject to BUG-001/-022; sifted-glint cue never rendered, BUG-016) |
| p06 barrel pry | PASS | **FAIL on iPad** | Barrel art+hotspot mostly outside the iPad 4:3 crop (BUG-004) |
| p07 counterweight | PASS | PARTIAL | Drop-on-hook works, but drop coordinate stretch on iPad means the release point is over the shelf art, far from the hook (BUG-014) |
| p08 shutter winch | PASS | PASS* | Tap and drop paths work; winch partially cropped on iPad (BUG-004 marginal) |
| p09 mirror aim | PASS | PASS* | Detent cycling + latched flag correct; solved-flag bookkeeping wrong at non-3 detents (BUG-008) |
| p10 moonflower bloom | PASS | PASS* | Condition-driven bloom + pick correct incl. mirror-first path; blossom re-grantable after grinding (BUG-007) |
| p11 cage unlock | PASS | **FAIL on iPad** | Tap star-keyhole with key works, feather granted exactly once — PASS. But star keyhole + feed cup sit entirely outside the iPad-visible band (BUG-004); dropping the key on the keyhole/cage does nothing (BUG-018) |
| p12 file shavings | PASS | **FAIL — no UI path at all** | `ItemCombinations.combine` is never called from app code; the inventory bar has no combine interaction (BUG-012). Shavings unobtainable → level unwinnable |
| p13 grind paste | PASS | PASS* | Drop blossom on mortar works (mortar hotspot misaligned, BUG-015) |
| p14 brew | PASS | PARTIAL | Values spec-exact (stage 3, CCW, 5); fizzle returns all ingredients; order-free adds — PASS. Post-success re-resolve duplicates spent ingredients (BUG-006); success/fizzle liquid states never rendered — the color-blind-safe spiral-pattern cue is missing (BUG-016) |
| p15 fill phial | PASS | **FAIL — no UI path at all** | `fillPhial` has zero call sites outside tests; dropping the empty phial on the cauldron is swallowed by the ingredient-only handler (BUG-002). Level unwinnable |
| p16 door unseal | PASS | PASS* | Drop draught on door-lock hotspot unseals; D1 feed-cup block verified for all 15 items (BUG: basin art sits slightly above the hotspot top, BUG-015 marginal) |
| p17 escape | PASS | **FAIL — no UI path at all** | `slideBoltAndLeave` has zero call sites outside tests; no tap handler on the unsealed door (BUG-003). Level completion and the Level Select badge are unreachable in-app |

## 2. Pass/fail — per zone

| Zone | Engine unlock | In-app status |
|---|---|---|
| z1-cabin (start) | n/a — start zone | **FAIL**: never added to `unlockedZones`, so `availableViews()` excludes all three z1 views; chevron navigation is inert from a fresh save (BUG-001) |
| z2-workshop | PASS (p01 → z2) | Reachable only after BUG-001 fix |
| z3-cellar (hidden) | PASS (p02 → z3) | Same; trapdoor is not a diegetic passage (chevron-cycling only; style-guide §7 deviation, noted) |
| z4-alcove (nested hidden) | PASS (p07 → z4) | Same; nested unlock chain verified z1→z3→z4 |

## 3. Red herrings and character beats

| Item | Result |
|---|---|
| Rusted key | PASS (engine): pickup works, unlocks nothing, never consumed. Gaps: no close-up showing snapped bit (BUG-013); drop on keyhole silently ignored instead of a visible reject (BUG-018) |
| Feed cup universal refusal (D4) | PASS (state): all 15 inventory items return unspent, zero state churn, verified per item on both devices. **But** the refusal pose/animation is never rendered — `showTerminalRefusal` is set and no view observes it; refusal is audio-only (BUG-016), and the cup itself is off-screen on iPad (BUG-004) |
| Draught mis-pour (D1 BLOCK) | PASS (state): draught never spent at cup; basin pour still works afterwards. Same rendering caveats as D4 |
| Cage reach (D3) | PASS (state): no mutation, no escalation across repeats. Cosmetic: cage tap still triggers refusal after the crow is freed (BUG-020) |
| Clock / cuckoo (D5) | Engine one-shot latch PASS incl. persistence across relaunch. **But nothing in the UI ever calls `setClockToTwelve`** — no movable hands, no close-up, so the entire beat (and the numeral-ring clue for p01) is unreachable (BUG-013) |
| Potion shelf, grimoire decoys | **Not experiencable**: no close-up/inspection layer exists at all (BUG-013); potion-shelf hotspot is also misaligned and its art sits outside the iPad crop |

## 4. Save/resume, restart, reset (automated, both devices)

| Scenario | Result |
|---|---|
| Relaunch mid-rune-sequence (2 of 4 pressed) resumes and completes | PASS |
| Relaunch inside nested hidden zones mid-puzzle (dials solved, mirror pre-set at detent-3, weight hung, flame stage 2) → all latched state intact, mirror-first path still completes | PASS |
| Moon dials retain positions across wrong attempts and relaunch | PASS |
| D5 cuckoo one-shot latch persists across relaunch | PASS |
| Restart Level resets dials/mirror/flame/ingredients/flags, leaves other levels + settings | PASS |
| Completion propagates to Level Select badge source; Reset Progress clears it; sound setting survives reset | PASS |
| J5 (Main Menu exit loses nothing) | PASS at persistence layer — every `GameState` mutation persists synchronously. Caveats: `BrewControlView` pending stir direction/count are view-local `@State` and are lost on exit (acceptable: stir is atomic at Release Ladle; not progression-relevant); resume always reopens at v-hearth (current view not persisted — acceptable, not spec-required); see BUG-019 for the Main-Menu navigation mechanism itself |

## 5. Verification of the 5 flagged Developer judgment calls

1. **Hand-placed hotspot rects vs real art — FAIL.** Verified visually against all seven shipped 2560×1280 plates. Multiple hotspots do not cover their art (details in BUG-015): hearth clock (art x≈0.27–0.37, hotspot 0.45–0.61), hand bellows (art x≈0.03–0.06 far-left wall, hotspot 0.62–0.72), lintel (art y≈0.24–0.30, hotspot y 0.05–0.15), entry rusted-key vs windowsill effectively swapped sides, study flowerpot (art ≈0.61–0.66, hotspot 0.08–0.20), rune-tile hotspots span the whole door while the actual press-plate occupies y≈0.36–0.56 at x≈0.77–0.79, cabinet potion-shelf and astrolabe both displaced, bench floor-bellows and mortar displaced, alcove planter half-covered. Plus the safe-zone violations (BUG-004) and the pt-vs-px floor bug (BUG-009).
2. **Tile→rune mapping — PASS.** `PuzzleGraphModel.tileRune` matches `runedoor-tiles.json` exactly (tile1=FIRE, tile2=WATER, tile3=AIR, tile4=EARTH; solution = tiles 3,1,4,2). Note the JSON's rects are for the `cu-runedoor-tiles` close-up plate, which the build never displays.
3. **Tap/button placeholder controls (dials, brew) — values PASS, interaction shape has defects.** Dial cycling order, order-free evaluation, retain-position, and brew parameters/failure semantics are spec-exact (all green). Defects: dial control bypasses the rug-discovery beat (BUG-010), violates the ≥30%-of-iPhone-width dial legibility floor at 84 pt (BUG-011); brew control permits post-success re-resolve duplication (BUG-006) and the R3 CW/CCW affordance + success-pattern rendering don't exist yet (BUG-016).
4. **Vine "withered" mid-state unwired — PASS, no contradiction.** The graph's only transition is `door-unsealed`; alive/gone keyed off that flag is consistent. `ov-vines-withered` remains available for the crossfade polish pass. Not a bug.
5. **J5 / Main Menu exit — premise HOLDS** (see §4). The global-ui-style pairing (no confirmation on Main Menu, confirmation on Restart) is correctly implemented. Separate defect: Main Menu exit is implemented as `fullScreenCover(RootAppView())`, stacking a new root over the live game instead of dismissing to the existing one, and the level's ambient loop keeps playing on the menu (BUG-019).
6. *(Also verified, from note 6)* **Drag-drop coordinate conversion — FAIL**, see BUG-014: the error is systematic, not just "near edges."

---

## 6. Bug list

Severity: **Critical** = level cannot be completed / core content invisible; **Major** = spec violation or player-visible malfunction; **Moderate** = UX/feedback defect; **Minor** = bookkeeping/polish.

### Critical

**QA-BUG-001 — Start zone never unlocked; navigation dead from a fresh save.**
Repro: fresh save → enter level → tap either chevron. Nothing happens; the player is pinned to v-hearth and can never reach v-study (p01) or v-entry. Cause: `LevelSession.availableViews()` filters on `state.isZoneUnlocked(zoneID)` but nothing ever adds `z1-cabin` to `unlockedZones` (`GameState` starts empty; only p01/p02/p07 unlock zones). Graph ref: `zones[0].start_zone: true`. Test: `testQA_BUG_001`.

**QA-BUG-002 — p15 (bottle the draught) has no interaction path; level unwinnable.**
Repro: brew successfully, drag the empty phial onto the cauldron → swallowed silently (`addCauldronIngredient` accepts only paste/shavings/feather). `PuzzleEngine.fillPhial` has zero call sites in app code (verified by exhaustive search). Graph ref: p15 `input: "Use empty phial on ready cauldron"`. Test: `testQA_BUG_002`.

**QA-BUG-003 — p17 (slide bolt and leave) has no interaction path; completion unreachable.**
Repro: set `door-unsealed` (pour draught on basin), then tap the door/bolt → no handler exists; `slideBoltAndLeave` has zero call sites in app code. Win condition, `isComplete`, and the Level Select badge can never trigger in-app. Graph ref: p17. Test: `testQA_BUG_003`.

**QA-BUG-004 — Dual-safe-zone violations: puzzle-critical elements off-screen on iPad (primary device).**
The scene is 2732×1366 `.aspectFill`; on iPad 4:3 only plate-x ∈ [~0.144, ~0.856] is visible. Outside that band: **star-keyhole (0.80–0.86) and feed cup (0.85–0.93) — p11 cannot be performed and the D4 defusal cannot be seen on iPad**; cage (0.73–0.98) mostly cropped; cellar barrel (0.75–0.99, p06) mostly cropped; cabinet astrolabe hotspot (0.72–0.96) and window/Orion clue (0.80–0.98) cropped; hearth hand-bellows art (AIR-rune clue, x≈0.03) and cabinet potion shelf art (x≈0.005–0.12) are outside the band **in the art itself**, not just the hotspots. Style-guide §8 mandates every puzzle-critical element inside the intersection of both crops. Fix requires a cross-agent decision (re-frame art, relayout hotspots to match true art positions where art is safe, or change display policy) — flagged for Producer/user. Test: `testQA_BUG_004`.

**QA-BUG-012 — p12 (file + spoon → shavings) has no UI path; level unwinnable.**
`ItemCombinations.combine` is called only from tests. The inventory bar supports select and drag-to-scene but has no item-on-item combine interaction, and no workbench drop handler accepts file/spoon (graph says the workbench close-up should also accept it). Graph ref: p12 `mechanic: item combination`. (No automated record test — there is no combine surface to drive; verified by call-site search.)

**QA-BUG-022 — Game art (and likely audio) unreachable in the built app bundle: black scenes, dead scene taps.**
Empirical: in the hosted test runner (Bundle.main = the real app bundle), `GameAssetLoader.image(named:)` returns nil for every base plate and sprite, on both simulator jobs. `GameAssetLoader` scans `resourceURL/GameAssets` and `resourceURL/Audio` directory trees, but the pbxproj ships `Resources` via a `PBXFileSystemSynchronizedRootGroup`, which does not preserve that folder hierarchy in the bundle. Runtime consequence: every `RoomScene` base texture is nil → black scenes; **and `configureHotspots()` returns early when the texture is missing, so no hotspot nodes are created → all scene taps are dead**. `OverlayRectCatalog` and `SoundManager` have flat-lookup fallbacks and may partially survive; `GameAssetLoader` has none. This was invisible to the Developer because nothing ever rendered the app (no local Mac, no UI tests, no screenshots). Test: `testQA_BUG_022`.

**QA-BUG-013 — The close-up/inspection layer does not exist; the game is humanly unsolvable and D5 is unreachable.**
No code presents any `cu-*` close-up (all shipped: grimoire pages A/B/recipe/decoys, triptych ×3, clock states, rune marks, keyhole, scratches, barrel gap, etc.). Tapping grimoire, triptych, clock, bellows, lintel, flowerpot, windowsill, potion shelf, or window does nothing but the tap pulse. Without the recipe page, triptych, and rune-numeral clues a human player cannot derive any solution; the style guide's "down-chevron for leaving close-ups" (§7) has nothing to attach to; `setClockToTwelve` (D5) and `RoomVisuals.clockState/ashState/cauldronLiquidState` are dead code. Graph refs: all `clu-*` nodes, D5, `rh-clock`, `rh-grimoire-decoys`, `rh-potion-shelf`.

### Major

**QA-BUG-005 — Astrolabe auto-solves on a bare tap.** `handleTap` calls `selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, …)` — the coordinator supplies the answer. The six-plate selection mini-game (plate sprites are shipped) does not exist; p03's fixed solution is never derived by the player. Test: `testQA_BUG_005`.

**QA-BUG-006 — Post-success brew re-resolve duplicates spent ingredients.** `resolveBrew` neither clears `cauldronIngredients` on success nor guards on already-solved; pressing Stir + Release Ladle again after success fizzles and returns paste/shavings/feather to inventory while `draught-ready` stays latched. Reachable via `BrewControlView` (always shown on v-bench). Violates the spirit of "feather granted exactly once". Test: `testQA_BUG_006`.

**QA-BUG-009 — 44 pt hit-target floor enforced in scene pixels, not screen points.** `Hotspot.minHitSize` (44) is applied against the 2560×1280 plate; at iPhone SE `.aspectFill` scale (×0.2745) the effective floor is ~12 pt. Sub-44 pt puzzle-critical targets on iPhone SE include star-keyhole (~42×21 pt), feed-cup (~56×28 pt), hearth lintel (~35 pt tall). Style-guide §8 violation. Test: `testQA_BUG_009` (offender list auto-computed).

**QA-BUG-010 — p02's hidden-discovery beat is missing.** The rug tap is a no-op, no rug-moved state exists, and `MoonDialControlView` overlays the hearth view from level start (until z3 unlocks). Graph requires `requires: ["free-action: move rug"]` and mechanic "hidden discovery (move rug)"; the trapdoor is supposed to be found, not pre-exposed as floating chrome. Also no `cu-dial-panel` close-up (ties into BUG-013).

**QA-BUG-011 — Moon-dial legibility floor violated.** Dial faces render at fixed 84 pt; style-guide §8 (A5/R5, load-bearing) requires each dial face ≥30% of screen width (≥200 pt) in the dial close-up on the smallest iPhone, with the waxing/waning terminator surviving a grayscale squint test. Color-blind-safety adjacent: the mirrored-shape discrimination is the puzzle.

**QA-BUG-014 — Drag-and-drop coordinate conversion is systematically wrong under `.aspectFill`.** `GameRoomView` maps the view rect linearly onto the full 2732-wide scene, ignoring the crop. Radial stretch from screen center: ×~1.5 on iPad 4:3, ×~1.12 on iPhone SE. Example: to hang the weight (p07) on iPad, the drop registering on "hook" (plate x 0.20–0.30) requires releasing at plate x ≈ 0.30–0.37 — over the shelf art; releasing on the hook art itself resolves to the inert "shelf" hotspot. Confirms and exceeds Developer judgment-call 6's concern: this is not edge drift, it is everywhere except dead center. (Documented analytically; recommend fixing via `SKView.convert` plumbing, then covering with a UI test.)

**QA-BUG-015 — Hand-placed hotspots misaligned against the real art** (Developer judgment call 1 — verification FAILED). Full list in §5 item 1. Worst cases make taps on the visible object land nowhere (clock, bellows, flowerpot, rusted key, windowsill, potion shelf, astrolabe, floor bellows, mortar) or make one rune-tile hotspot cover the entire physical press-plate while the other three cover blank door.

**QA-BUG-016 — State-visual rendering gaps (several are spec-mandated cues).** Never rendered: cauldron liquid states (clear/fizzle/pearlescent-spiral — the **color-blind-safe brew success cue**, graph `colorblind_safety`); ash sifted-glint (p05's secondary discoverability cue); rune-tile pressed sprites; the crow terminal-refusal pose (`showTerminalRefusal` is set but no view observes it — refusal is audio-only, and `cu-cage-crow-refusal.jpg` is unused); `z3-cellar-weight-hung` plate; `lastBrewOutcome`/`justPoppedClock` are write-only. (Partially masked by BUG-022 today, but independent of it.)

### Moderate

**QA-BUG-017 — Cabinet placement: no rejection feedback + stale pending state.** Wrong placement returns false silently (spec: "item pops back out"); no wrong-SFX, no visual. `pendingSunItem`/`pendingMoonItem` persist per coordinator, so an earlier stray placement can complete the puzzle later without the player re-placing both items, and nothing ever renders a single seated item.

**QA-BUG-018 — Dropping keys on the cage/keyhole is silently ignored.** Only a tap on star-keyhole (with key merely in inventory) works. Dragging the star key — the game's universal tool gesture — onto the cage or keyhole does nothing; the graph's "keyhole visibly rejects the rusted key's plain bit" beat is absent.

**QA-BUG-019 — Pause → Main Menu stacks a new root (`fullScreenCover(RootAppView())`)** instead of dismissing to the existing root: repeated menu/level cycles accumulate presentation stacks and live `LevelSession`s, and the level's ambient loop continues playing on the menu (`SoundManager.setAmbientZone` is only called on in-level navigation).

**QA-BUG-020 — Cage tap still plays the terminal refusal after the crow is freed** (cage is open and empty; crow is on the rafters). Cosmetic contradiction with the graph's post-p11 state.

### Minor

**QA-BUG-007 — Blossom re-grantable after grinding** (`pickBlossom` lacks the already-solved guard every sibling has); yields a stray unusable blossom. Test: `testQA_BUG_007`.
**QA-BUG-008 — p09 marked "solved" at any detent**, not just detent-3; latched flags are correct, only the solved-set bookkeeping is wrong. Test: `testQA_BUG_008`.
**QA-BUG-021 — Notes:** brew pending stir count is view-local and lost on menu exit (acceptable under J5 — stir is atomic at resolve); resume always reopens at v-hearth (current view not persisted; not spec-required); Main Menu title shows the Level-1 title as the game title (chrome nit, global-ui spec shows a game-level title); view transitions are instant coordinator swaps, not the §7 300 ms crossfade / 600 ms zone dip.

---

## 7. Performance notes (simulator, unit-level only)

- QA suite runtime: 3.2 s (iPad job) / 22.2 s (iPhone job) for 57 tests; no crashes, no hangs, no memory warnings in simulator logs across either job.
- `SaveGameStore` performs a synchronous whole-file JSON encode+write on **every** state mutation on the calling (main) thread. Fine at current save size (~KB); flag as a watch item if save data grows.
- `RoomScene.setOverlay`/`setBaseTexture` construct a fresh `SKTexture` (and decode a full 2560×1280 JPEG) on every state-driven refresh with no texture cache — potential visible hitches once BUG-022 is fixed and textures actually load. Watch item, re-measure after fixes.
- App-launch/zone-transition wall-clock and memory profiling require a runnable UI (blocked by BUG-022/-001) and an XCUITest pass — deferred to re-test.

## 8. Test-infrastructure requests (route to Developer via Producer)

1. **XCUITest target** with a scripted full playthrough (once BUG-001/-002/-003/-012/-022 are fixed) + screenshot capture per view/state uploaded as CI artifacts, on both matrix devices — required to close hit-target and visual-state verification that unit tests cannot cover, and to produce the missing performance numbers.
2. Add a **notch/Dynamic Island device** (e.g. iPhone 15/16 class) to the CI matrix for safe-area verification (`global-ui-style.md` §11); current floor covers only iPad 13" + SE.
3. Keep the 10 `testQA_BUG_*` strict expected-failure records intact until each fix lands; a fixed bug makes its record test fail — then move the assertion into the permanent net.

## 9. Scope disclaimers

- CI-simulator-based automated testing only. Physical-device feel (touch accuracy under BUG-014 fixes, thermals, haptics, real loading times) is the user's manual TestFlight spot-check at step 16 — not covered here and not claimed.
- Chrome layer (Main Menu, Level Select badge/lock rendering, Settings incl. Reset Progress confirmation, About/version string, dark-only, landscape lock in Info.plist) verified by code inspection and store-level tests only; visually unverified pending the screenshot pipeline.

## 10. Go/no-go recommendation

**NO-GO** for step-13 approval. Return to the Developer Agent (via Producer) with the bug list above. Suggested fix priority:

1. QA-BUG-022 (assets in bundle) — everything else is invisible until this works.
2. QA-BUG-001, -002, -003, -012 (completability chain).
3. QA-BUG-004 (needs a Producer/user decision — art re-frame vs hotspot relayout vs display policy — because several *approved plates* place critical elements outside the §8 safe zone; may loop in Art Director/Asset Generation).
4. QA-BUG-013, -005, -010 (the game as designed: close-ups/clues, real astrolabe puzzle, rug discovery).
5. QA-BUG-006, -009, -011, -014, -015, -016 (correctness + §8 floors + feedback).
6. Moderates/minors with the polish pass.

Engine-level logic needs **no** changes — all 17 nodes, all three orderings, D1–D5, and every anti-softlock invariant verified green on both devices. Re-QA after fixes will rerun the same suite plus the new XCUITest flow.
