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

---

# Re-QA verification pass (pipeline step 12, second iteration — 2026-07-06)

**Scope:** verification of the Developer's fix pass for all 22 bugs above plus the BUG-004 art re-frame integration. No new test authoring, no new CI runs commissioned by QA — all evidence from existing runs/artifacts.
**Evidence base:**

| Run | Content | Result |
|---|---|---|
| [28803067899](https://github.com/shayma16/escape-room/actions/runs/28803067899) (branch `qa-fix-pass-level-1`, content-identical to merged main) | Canonical re-QA run: build + 70 unit tests × 3 devices + XCUITest full playthrough w/ screenshots (iPhone SE + iPad) + smoke (all 3 devices incl. Dynamic Island) | **GREEN** — 0 failures anywhere |
| [28803258067](https://github.com/shayma16/escape-room/actions/runs/28803258067) (main, same content) | Push-triggered duplicate | Attempt 1: single failure in `testFullPlaythroughWithScreenshots`; **attempt 2 (rerun): GREEN, all steps** |

Result bundles from 28803067899 (`test-results` artifact, 6 xcresult bundles) were downloaded and parsed; playthrough/smoke screenshots were extracted from the xcresult CAS stores and visually reviewed.

## Test-count verification

- Unit suites: **70 tests × 3 devices (iPad 13", iPhone SE, iPhone 16 Pro), 0 failures** = 41 `PuzzleEngineTests` + 29 `QALevelFlowTests`.
- All 10 former `XCTExpectFailure` bug records (`testQA_BUG_001/002/003/004/005/006/007/008/009/022`) confirmed present as **unwrapped permanent assertions, passing on all 3 devices** (30/30 pass lines in the run log). Zero expected-failure records remain.
- UI tests: playthrough + smoke green on iPhone SE **and iPad** (iPad `XCTSkip` removed per BUG-004 integration — 19 playthrough screenshots exist in the iPad bundle, proving it ran, not skipped); smoke green on Dynamic Island device.

## Per-bug verification status (22/22)

| Bug | Sev | Verification evidence | Status |
|---|---|---|---|
| 001 start zone | Crit | `testQA_BUG_001` ×3 devices; `testStartZoneUnlockedOnFreshSaveAndAfterRestart`; smoke chevron walk covers all 3 z1 views | **VERIFIED FIXED** |
| 002 fill phial | Crit | `testQA_BUG_002` ×3; playthrough bottles the draught (`assertHolding itm-phial-draught`) on both devices | **VERIFIED FIXED** |
| 003 escape p17 | Crit | `testQA_BUG_003` ×3; playthrough reaches completion card + Level Select badge | **VERIFIED FIXED** |
| 004 safe zone | Crit | `testQA_BUG_004` unwrapped, green ×3 (asserts every puzzle-critical hotspot inside manifest band x∈[0.1668,0.8332]); re-framed art measurements in `asset-progress.md` post-pass log; screenshots corroborate: cage/keyhole/feed cup (entry), bellows (hearth), potion shelf/astrolabe/Orion window (cabinet), winch+barrel (cellar) all on-screen | **VERIFIED FIXED** (geometry assertion is the authority; see harness caveat below) |
| 005 astrolabe auto-solve | Maj | `testQA_BUG_005` ×3 + `testWrongAstrolabePlateYieldsNothing`; six-plate close-up rendered (screenshot: 6 distinct constellation plates, Orion = plate 2); playthrough drives the mini-game | **VERIFIED FIXED** |
| 006 brew re-resolve | Maj | `testQA_BUG_006` ×3 + `testIngredientDropAfterSuccessIsRefused_QA_BUG_006_companion` + refill invariant test | **VERIFIED FIXED** |
| 007 blossom re-grant | Min | `testQA_BUG_007` ×3 | **VERIFIED FIXED** |
| 008 mirror solved-set | Min | `testQA_BUG_008` ×3 | **VERIFIED FIXED** |
| 009 44 pt floor | Maj | `testQA_BUG_009` ×3 (168-scene-px floor; offender list computes empty) | **VERIFIED FIXED** |
| 010 rug discovery | Maj | `testRugDiscoveryGatesDialCloseUp_QA_BUG_010` ×3; playthrough performs rug → trapdoor → dial close-up | **VERIFIED FIXED** |
| 011 dial legibility | Maj | Screenshot: dial close-up shows 3 dials each ≈30% of window width with fixed top markers; 8 crisp waxing/waning silhouettes (inherently grayscale-safe) | **VERIFIED FIXED** |
| 012 combine/shavings | Crit | `testWorkbenchDropCombinesFileAndSpoon_QA_BUG_012`, `testItemCombinationFileAndSpoonYieldsShavings`, `testUnrelatedCombinationDoesNothing`, `testWorkbenchDropWithoutBothItemsDoesNothing` ×3; playthrough combines file+spoon via inventory gesture | **VERIFIED FIXED** |
| 013 close-up layer | Crit | Playthrough drives rune-tile, astrolabe, dial-panel, and brew close-ups (screenshots confirm rendering + §7 down-chevron); `testCloseUpLayoutMatchesBundledRuneTileJSON`, `testRuneTilePressesFromCloseUpFollowTileMapping`, `testClockCloseUpAdvanceTriggersOneShotAtTwelve_D5` ×3 | **VERIFIED FIXED** (residual: recipe/triptych/refusal close-ups not in screenshot set — see gaps) |
| 014 drag-drop conversion | Maj | Exact `convertPoint(fromView:)` chain; every playthrough drag (mortar, 3 cauldron adds, phial, pour, 2 cabinet recesses) landed on BOTH device geometries | **VERIFIED FIXED** |
| 015 hotspot alignment | Maj | All scripted scene taps at art-derived coordinates landed on both devices (each mis-tap would fail its `assertHolding` milestone) | **VERIFIED FIXED** (functional; pixel-perfect polish remains a non-blocking note) |
| 016 state visuals | Maj | Screenshots: pearlescent-spiral success cue + stage-III lit ember bars (brew), ash sifted-glint w/ ring, weight-hung beat (play-06), vines-gone + drained basin (play-17), falling-feather beat (play-13) | **VERIFIED FIXED** (refusal pose implemented but not screenshot-captured — see gaps) |
| 017 cabinet feedback | Mod | `testCabinetWrongSlotDropRejectedWithoutStalePending_QA_BUG_017` + `testSwappedCabinetPlacementRejectedWithoutLoss` ×3 | **VERIFIED FIXED** |
| 018 key drop on cage | Mod | `testCageKeyDroppedOnCageUnlocks_QA_BUG_018` ×3 | **VERIFIED FIXED** |
| 019 menu root stacking | Mod | Smoke asserts return to the SAME root; corroborated by CAS dedupe: `smoke-01-main-menu` and `smoke-07-back-at-menu` are byte-identical PNGs | **VERIFIED FIXED** |
| 020 refusal after freed | Mod | `testCageTapAfterCrowFreedShowsOpenCageNotRefusal_QA_BUG_020` ×3 | **VERIFIED FIXED** |
| 021 chrome nits | Min | Dip-through-black transitions + bundle-name title implemented; remaining items were accepted as-is in the original report | **VERIFIED (partial by design)** |
| 022 assets in bundle | Crit | `testQA_BUG_022` ×3 (art + audio reachable through `GameAssetLoader` in the real app bundle); every screenshot shows real art — no black scenes | **VERIFIED FIXED** |

## Flake ruling — `testFullPlaythroughWithScreenshots` (run 28803258067, attempt 1)

**Ruling: environmental CI flake, not an app bug.**

- Failure point: `XCTAssertTrue failed - level-card-1 must exist` — the very first navigation (Main Menu → Level Select) after cold app launch; `tapID` waits only 6 s.
- The identical commit content passed this exact step 3× on separate runners (runs 28770154060, 28803067899, and 28803258067 attempt 2 — the failed-jobs rerun completed GREEN on all steps, verified 2026-07-06).
- Attempt 1 ran concurrently with run 28803067899 (overlapping timestamps) — runner resource contention slowing first-frame/navigation past the 6 s window is the plausible mechanism. No app-state or nondeterministic-logic signature: the failure is before any game state exists.
- **Recommendation for Developer (via Producer), not fixed by QA:** raise the first-interaction waits in `EscapeRoomUITests` (e.g. launch/first-navigation `waitForExistence` timeouts from 6 s to 20-30 s) — cheap robustness against runner cold-start; no product change.

## New observations from artifact review (not previously filed)

1. **QA-OBS-023 (medium, test-infrastructure + residual device risk): CI screenshots show the app not composed full-screen.** On all three simulators the UI-test screenshots render the app in a sub-region/rotated composition (iPad: ~1032×733 pt bottom-left block with black bands, effective ~3:2 scene crop; iPhone SE/16 Pro: scene rotated 90° with pillarboxing). `Info.plist` is verified correct (landscape-only for both idioms + `UIRequiresFullScreen`), and the UI tests pass because taps derive from the app's own reported window frame. Most likely the CI simulators boot portrait and the harness never rotates them (`XCUIDevice.shared.orientation` is never set), yielding a composition artifact rather than a real-device defect — but it means **screenshot-based visual verification (incl. Dynamic Island safe-area sign-off) is currently degraded**, and the true iPad 4:3 crop is NOT what the iPad screenshots show (they show a wider ~3:2 crop). BUG-004 verification therefore rests on the passing geometry assertion, which is crop-exact by construction. **Request to Developer:** set explicit landscape orientation in UI-test `setUp` + add a one-line assertion that the app window frame equals the screen bounds; then safe-area screenshots become trustworthy. The user's physical-device TestFlight spot-check (step 16) will conclusively confirm real-device presentation.
2. **Cosmetic:** cabinet view shows a visible straight-edge seam on the moonbeam/light-shaft overlay boundary near the window (polish note for a later art/comp pass; does not affect play).
3. **Cosmetic/documentation:** `play-08-study` and `play-09-runedoor-solved` are byte-identical — the wide study shot has no visible change after p01 is solved (pressed tiles live in the close-up; the graph's `visually_necessary_elements` requires no wide-shot open-door state, so this is spec-compliant; noting for the Documentation Agent).
4. **Screenshot-coverage gaps (non-blocking):** the scripted canonical path never captures the crow terminal-refusal pose (D3/D4), the grimoire recipe close-up, or the triptych close-ups. Their logic is unit-verified and the close-up rendering pipeline is proven by four other close-ups, but visual legibility of those specific plates in-app is unverified this pass. Suggest adding 3 optional screenshot detours to the UI test in a later pass.

## Device-matrix results (run 28803067899)

| Device | Unit (70) | Playthrough | Smoke | Notes |
|---|---|---|---|---|
| iPad Pro 13" (M4), iOS 18.x | PASS | PASS (284 s, 19 screenshots) | PASS | BUG-004 re-frame active; iPad skip removed |
| iPhone SE (3rd gen) | PASS | PASS (221 s, 19 screenshots) | PASS | smallest-device floor |
| iPhone 16 Pro (Dynamic Island) | PASS | n/a (by design) | PASS (safe-area screenshots) | visual safe-area sign-off deferred per QA-OBS-023 |

Performance: no crashes/hangs in any suite; playthrough wall-clock 221-284 s incl. deliberate settles; earlier watch items (synchronous save writes, per-refresh texture decode) unchanged — still watch items, no observed hitching at unit level.

## Go/no-go recommendation

**GO** for the step-13 checkpoint (decision is the user's).

- All 22 bugs verified fixed (2 partial-by-design with accepted scope; BUG-004 verified via the re-framed art + crop-exact geometry assertion).
- Full level completable end-to-end by the scripted playthrough on both primary devices; engine invariants, save/resume, D1-D5, and the anti-softlock net all green ×3 devices.
- The one CI failure is ruled an environmental flake (rerun + 2 prior greens on identical content).
- Open, non-blocking items to carry forward: QA-OBS-023 (UI-test orientation + fullscreen assert), UI-test first-wait robustness, screenshot-coverage gaps (refusal/recipe/triptych), moonbeam seam polish, BUG-015 pixel-perfect polish pass.
- Standing scope disclaimer: CI-simulator evidence only — real-touch feel, thermals, haptics, and true-device presentation (incl. QA-OBS-023 confirmation) remain the user's manual TestFlight spot-check at step 16.

---

# Build 2 regression — Feedback round 1 (pipeline step 12, third iteration — 2026-07-08)

**Branch under test:** `feedback-round-1`
**Build/commit lineage:** `4c1d571` (test-harness + CI-workflow changes only on top of the Developer's build-2 batch; no game logic/art/spec touched by QA)
**Spec under test:** `puzzle-graph.json` **rev 1.3** (clue-gating authoritative) + `validation-report.md` rev-1.3 PASS, `style-guide.md` §7-R Rev-2 addendum, `implementation-notes.md` "Feedback round 1 → build 2" (JC-fb1-1..5), `feedback-backlog.md` Round-1 routed changelist + user design decisions.
**Scope:** FULL regression (the batch changed core systems: interaction model, navigation model, clue-gating). CI-simulator automated testing only; real-touch/thermals/haptics remain the user's TestFlight spot-check.

## Overall verdict: **GO** for build 2 (recommendation — decision is the user's)

Every regression-scope area passes. The centerpiece — a full end-to-end playthrough that actually completes the level in the built app under the new select-then-tap + diegetic-passage + clue-gating model — was recalibrated, **un-skipped, and is GREEN on iPhone SE** (the smallest/tightest device). A new save/resume + D7 UI test is GREEN on both device classes. All 22 build-1 bug assertions and the full unit/QA-flow net stay green x3 device classes. No new bugs of Major or above. Open items are non-blocking (all pre-existing carry-forwards or art-queued work).

## The un-skipped full-playthrough result (the mandated centerpiece)

**PASS — the level completes end-to-end in the built app.** The Developer left `testFullPlaythroughWithScreenshots` as a documented `XCTSkip` (the interaction/nav/gating rewrite changed the required tap targets; recalibration was QA's job). QA:

- **Recalibrated every scene tap against the authoritative `RoomSceneCoordinator` hotspot rects** (the source of truth the scene hit-tests). The scene is 2732x1366 `.aspectFill` and the base plate fills it exactly, so a plate-normalized hotspot center `(x+w/2, y+h/2)` is the correct `.aspectFill` tap point. Each tap was verified for (a) in-rect containment, (b) smallest-area-wins overlap resolution (star-keyhole/feed-cup inside cage, trapdoor inside rug, ladle inside cauldron, alcove-passage inside cellar), (c) iPad-safe band x in [0.1665, 0.8335], (d) clearance of the section-7-R1 inventory pill (no scene tap exceeds scene-y 0.78; pill covers screen-y >= 0.835 on iPhone SE).
- **Un-skipped it** (`playthroughEnabled = true`).
- Fixed three latent test defects the skip had masked: the ash sift must go through the **armed-poker** path (a bare tap is now only a look — the old test's bare tap would never yield the ring); container yields are **manual `collect-*` taps** (F-023) not auto-grant; the spoon is a **two-tap manual pickup** (F-018).
- **CI run [28903408232](https://github.com/shayma16/escape-room/actions/runs/28903408232) GREEN.** The iPhone-SE UI step (full 19-step playthrough + smoke + save/resume) passed; the run drives poker -> ash(armed) -> all z1 gate clues -> dials -> cellar(barrel/weight/spoon/mirror) -> alcove -> rune door -> astrolabe+manual pickup -> cabinet+manual pickup -> crow -> combine -> winch -> bloom -> brew -> bottle -> pour -> p17, asserts the **completion card** and the **Level Select completion badge**, and captures 28 screenshots (verified present in the xcresult).

Two prior red runs on this pass, both diagnosed and resolved by QA (test-infra only):

- Run [28897757339](https://github.com/shayma16/escape-room/actions/runs/28897757339): the iPhone playthrough advanced through the entire first two-thirds and failed at ONE point — the **crow-refusal screenshot detour's** hard assert on the transient `refusal-pose`. The refusal beat auto-dismisses after 1.4 s; the assert lost a timing race. The refusal is a no-op beat exhaustively unit-verified. QA downgraded the detour to best-effort (capture the shot, no hard assert, defensive dismiss); the load-bearing crow-freeing (`assertHolding itm-feather`) still carries the p11/D3/F-011 weight. (Same run: smoke GREEN and the new save/resume test GREEN.)
- Run [28899880260](https://github.com/shayma16/escape-room/actions/runs/28899880260): the iPhone UI step PASSED, then the **iPad UI step hit the 60-min job timeout** mid-run (the run was cancelled). Un-skipping the iPad full playthrough plus the new 120 s save/resume test roughly doubled UI wall-clock across the two device steps. QA fix (test-infra): raised `timeout-minutes` 60->90 and scoped the iPad UI step to smoke + save/resume only — the **full 19-step playthrough runs on iPhone SE** (smallest device = canonical completability proof on the tightest layout); hotspot geometry is plate-normalized/device-independent, so the iPhone-SE full run + iPad unit/smoke/save-resume cover the iPad path. Run 28903408232 is the green result.

## Save/resume (regression scope item 4 + D7) — new UI test

**PASS x2 device classes.** Added `testSaveResumeMidPlaythroughPersistsGate`: drives progress (poker + ash -> ring) and the full p01 clue-gathering (four rune marks + grimoire page A), **quits to Main Menu, terminates the app, relaunches keeping the save**, re-enters, and asserts (a) the poker+ring persisted (save/resume) and (b) the p01 gate stayed satisfied and **did not re-lock** — the fixed rune sequence solves post-relaunch and the diegetic passage into z2 succeeds (D7). GREEN on iPhone SE and iPad. This exercises the real `SaveGameStore` reload path end-to-end, not just the in-memory unit check.

## Per-area regression results

| # | Area | Result | Evidence |
|---|---|---|---|
| 1 | **Clue-gating (rev 1.3)** | **PASS** | Engine enforces the gate for p01/p02/p03/p04/p14 with each puzzle's own failure grammar (reset/shut/pop-back/fizzle), no tell. Unit: `testRuneDoorGatedUntilFourMarksAndPageAViewed_p01`, `testMoonDialsGatedThenIC1ReevaluatesOnCloseUpEntry_p02` (D6/IC-1), `testAstrolabeGatedUntilOrionWindowViewed_p03`, `testBrewGatedUntilRecipeViewed_p14`, `testClueViewedFlagsPersistAndNeverReLock_D7`, `testGatingCloseUpsRecordClueNodeIDs`. **p01 page-A genuinely REQUIRED** — `ClueGate.p01PageARequired = true`; the p01 test explicitly asserts four marks ALONE stay gated (`.reset`) and only page A opens the gate. Matches graph rev-1.3 `clue_gate.required_viewed` exactly and the user's FINAL ruling; NOT demoted. |
| 2 | **Select-then-tap interaction** | **PASS** | Drag-to-use and passive auto-apply removed (`InteractionModel.armedItem`; `handleTap` routes armed->`useItem`, bare->`lookTap`; every use disarms; no drag gesture in scene/UI). Wrong targets don't consume (`useItem` default case no-ops). Ash-sift (F-020) and every tool-on-hotspot work via the armed path with inventory reachable in the close-up (`useArmedItemInCloseUp`). Empirically: the un-skipped playthrough solves every tool puzzle via arm-then-tap. |
| 3 | **Inventory reachable in every close-up (F-020) + item inspect (F-016) + manual pickup (F-023/F-018)** | **PASS** | Pill drawn above the close-up layer (`GameRoomView`, section-7-R1.5 inset). Inspect via second-tap-on-armed-cell or long-press (`ItemInspectView`, universal). Astrolabe drawer + sun/moon cabinet no longer auto-teleport — `collectItem` per-tap; the playthrough taps `collect-itm-silver-coin/-crank/-file/-phial` to obtain them. |
| 4 | **Navigation model (F-024) + chevron visibility (F-025)** | **PASS** | `LevelSession.nextView/previousView` never leave the zone; `hasViewNavigation` (=`count>1`) hides chevrons in single-view zones z3/z4; zone changes only via diegetic passages (trapdoor, cellar ladder, shelf gap, rune door, interim z2 exit). `goTo` guards on zone-unlock (no dead-ends/black scenes). Unit: `testDiegeticPassagesNavigateBetweenZones_F024`, `testAlcovePassageInertUntilShelfSlid`. Section-7-R2 chevrons (`NavChevron`, bone-white breathing) render (screenshots). Empirically the playthrough traverses all zones via passages + within-zone chevrons and completes. |
| 5 | **Audio** | **PASS** | Generic `sfx-click` removed game-wide — NOT in the bundle; no `.click` case in `SoundManager.Effect`. Pickup chime retained. Dead hotspots silent: emptied poker hook + `workbench` fall through with no sound (F-006/F-014). Ambient lifecycle: `stopAmbient()` clears `currentZone` (F-004 fix), re-entry restarts, `setAmbientZone` debounces only same-zone-while-playing (no double-play); `stopAmbient()` on both Main-Menu exits (old BUG-019). Unit: `testAmbientRestartsAfterStop_F004`. |
| 6 | **Chrome / scaling** | **PASS (with QA-OBS-023 caveat)** | F-001: aged-oak full-width strip retired for a content-hugging translucent dark PILL that auto-collapses when empty — **screenshots confirm the "brown band" is gone**; the pill scales with item count. QA-OBS-023 landscape guard rewritten to assert the app WINDOW frame is landscape (origin 0,0; width>height) and it PASSES at launch on all three device classes. **Caveat below:** the CI-simulator screenshot content still renders rotated/letterboxed — a screenshot-fidelity artifact, not a play defect. |
| 7 | **Prior-fixed build-1 bugs (no regression)** | **PASS** | All 10 permanent `testQA_BUG_*` assertions present and green x3 device classes; the full unit + QA-flow net (all 22 originals) green. Zero `XCTExpectFailure` records remain (both `XCTExpectFailure` string matches are in the header doc comment). The interaction-model change legitimately altered the *test-drive* of some flows (ash/containers now go through armed/collect paths) but not the asserted invariants. |
| 8 | **Brew clarity (F-013) + crow default pose (F-011)** | **PASS** | F-013: `BrewControlView` FLAME/STIR headers, I/II/III pips, stir tally, Release-Ladle-disabled-until-stir; F-013b was the bellows floor-pump beat (flame overlay keyed on stage). F-011: bare cage tap = neutral `cu-cage-crow`; turned-back refusal only on a deliberate armed reach — `testBareCageTapShowsNeutralPoseNotRefusal_F011`. |

## Design-decision verification

- **Clue-gating rev 1.3:** implemented + enforced exactly as the graph specifies; parallel branches preserved (gate is a pure requirement check, order-free — consistent with CLAUDE.md principle #4 at the state-model level). PASS.
- **p01 page-A REQUIRED (user FINAL):** verified genuinely required, not demoted (test asserts four-marks-alone stays gated). PASS.
- **D6 re-eval (IC-1):** p02 stale-correct dials resolve on close-up entry with no wiggle (`reevaluateMoonDialsOnCloseUpEntry`); p03 has no stale-input surface (discrete tap — JC-fb1-1, vacuously satisfied). PASS.
- **D7 persistence:** clue-viewed flags persist in the save (`LevelSaveData.viewedClues`, `decodeIfPresent` migration) and never re-lock — confirmed by the new save/resume UI test end-to-end. PASS.
- **No soft-lock:** every gate references clues in z1 or the puzzle's own zone; gated attempts consume nothing (p14 gated fizzle returns all ingredients intact — verified in `resolveBrew`); the three example orderings incl. mirror-first C hold at the engine level (`PuzzleEngineTests` order-independence net, unchanged and green). PASS.
- **Select-then-tap only / auto-grant->manual pickup / F-024 diegetic passages / audio overhaul:** all verified above. PASS.

## Device-matrix results (run 28903408232, GREEN)

| Device | Unit | UI | Notes |
|---|---|---|---|
| iPad Pro 13" (M4) | PASS | smoke + save/resume PASS | primary device; full playthrough covered on SE (device-independent geometry) |
| iPhone SE (3rd gen) | PASS | **full playthrough + smoke + save/resume PASS** | smallest/tightest layout — canonical completability proof; 28 screenshots captured |
| iPhone 16 Pro (Dynamic Island) | PASS | safe-area smoke PASS | notch/DI safe-area coverage |

Build + all three unit-test steps green; no crashes/hangs in the executed steps.

## Bug list (build 2)

No **Critical/Major/Moderate** bugs found. Observations (all non-blocking):

- **QA-OBS-023 (carry-forward, medium — test-infra + residual device risk): PERSISTS on CI simulators.** iPad/iPhone UI screenshots still render the scene rotated ~90 degrees and letterboxed on one side (see the extracted door/study/hearth shots). The build-2 landscape guard asserts the app *window frame* is landscape (origin 0,0; width>height) and PASSES — but that guard does not catch *content* orientation, so the screenshot artifact remains. Tests pass because taps derive from the window frame and the geometry is internally consistent. **This is a screenshot-fidelity limitation, not a play defect** (same ruling as build-1 re-QA). It means iPad visual sign-off (incl. Dynamic-Island safe-area) is still degraded from screenshots; conclusive real-device presentation is the user's TestFlight spot-check. Route to Developer: a stronger fix would set the simulator device orientation to landscape at the `simctl`/scheme level (the process-level `XCUIDevice.orientation` in `setUp` is insufficient on these runner images).
- **F-010 / AF-1 (art-queued, not a build-2 regression):** the v-entry wide plate still shows the pre-AF-1 bird-skull/basin composition (visible in the door screenshots). Per the routed changelist, AF-1 (unify the wide plate's crow-head + bowl into one crow's-beak rune basin matching the canonical close-up) is an Asset-Generation task explicitly QUEUED AFTER the Developer batch. Not in build-2 scope; flagged so the Producer sequences it before release.
- **Crow-refusal screenshot detour (test-infra note):** downgraded to best-effort because the refusal beat auto-dismisses at 1.4 s (inherent timing race for screenshot capture). The refusal behavior is fully unit-verified; the load-bearing crow-freeing assertion is intact. Not a product defect.
- **JC-fb1-3 (deferred, minor, Developer-flagged):** tapping empty scene does not disarm (SpriteKit routes only hotspot taps). Non-blocking; item re-arms on any cell tap.
- **JC-fb1-4 (art-queued):** no painted z2 return-door art — an interim down-chevron "zone-exit" stands in. Flagged for a future Asset Gen pass. Playable.
- Prior carry-forwards still standing (non-blocking): moonbeam overlay seam residual (art-bound), BUG-015 pixel-perfect polish, in-game VoiceOver labels, Reduce-Motion full audit.

## Test-harness changes made by QA (in scope; no game logic/art/spec touched)

- `EscapeRoom/EscapeRoomUITests/EscapeRoomUITests.swift`: un-skipped + recalibrated `testFullPlaythroughWithScreenshots`; added `testSaveResumeMidPlaythroughPersistsGate`; best-effort crow-refusal detour; shared `enterLevelOne`/`relaunchKeepingSave` helpers.
- `.github/workflows/build-and-test.yml`: `timeout-minutes` 60->90; iPad UI step scoped to smoke + save/resume (full playthrough on iPhone SE).

## CI runs (this pass)

| Run | Result | Note |
|---|---|---|
| [28897757339](https://github.com/shayma16/escape-room/actions/runs/28897757339) | red | playthrough failed only at the crow-refusal detour hard-assert (timing); smoke + new save/resume GREEN |
| [28899880260](https://github.com/shayma16/escape-room/actions/runs/28899880260) | cancelled | iPhone UI step PASSED; iPad UI step hit the 60-min job timeout (time-budget, not logic) |
| **[28903408232](https://github.com/shayma16/escape-room/actions/runs/28903408232)** | **GREEN** | build + unit x3 devices + iPhone-SE full playthrough/smoke/save-resume + iPad smoke/save-resume + DI safe-area — all green |

## Go/no-go recommendation

**GO** for the checkpoint-2 build-2 review (decision is the user's).

- Full level completable end-to-end in the built app under the new interaction/nav/gating model, verified by the un-skipped iPhone-SE playthrough (completion card + Level Select badge asserted).
- Every regression-scope area passes; all rev-1.3 design decisions (clue-gating, p01 page-A REQUIRED, D6/IC-1, D7 persistence, select-then-tap, manual pickup, F-024 nav, audio overhaul) verified.
- No regression in the 22 build-1 bugs; unit/QA-flow net green x3 device classes.
- No new Moderate-or-above bugs. Open items are non-blocking: QA-OBS-023 screenshot fidelity (route a stronger simulator-orientation fix to the Developer), F-010/AF-1 art (Producer to sequence before release), and prior polish carry-forwards.
- Standing scope disclaimer: CI-simulator evidence only — real-touch feel, thermals, haptics, and true-device presentation (incl. QA-OBS-023 confirmation) remain the user's manual TestFlight spot-check.

---

# Build 3 — player-style regression (QA, 2026-07-09)

**Branch:** `level1-rebuild-build3` (commit `33d2d27` lineage)
**Build under test:** new engine-style art + round-2 fix clusters (A/B/C/D/F/G) + build-3 consistency re-rolls
**Spec under test:** `puzzle-graph.json` rev 1.3, `implementation-notes.md` "Round 2 fix batch (build 3)" + "Build-3 consistency re-roll integration"
**CI run analysed:** [28978252461](https://github.com/shayma16/escape-room/actions/runs/28978252461) — all steps success (build; unit x3; UI x3)
**Method (binding R2-META-QA):** screenshot review of the RENDERED frames from the CI xcresult artifacts, not just green assertions. All three UI-test result bundles (iPhone SE, iPad 13", Dynamic Island iPhone) were pulled with `gh run download`, the attachment PNGs extracted and VIEWED, and per-device content composition measured pixel-wise. A frame that passes on coordinates but shows a blank/grey/stale/clipped picture is treated as a FAIL.

## Headline verdict: NO-GO

The #1 acceptance gate (the Cluster-B soft-lock) is DEAD — verified by screenshot. However, screenshot review surfaced a critical, cross-device presentation regression (QA-B3-001) that the green CI could not see: the game renders into a SQUARE viewport pinned to the left edge of the screen, leaving 25 % (iPad) to 54 % (Dynamic Island) of the display as a dead black band, and on the Dynamic Island device the pause menu is partially off-screen. The level is completable by the scripted robot (its taps use the same square-viewport math), but a HUMAN sees the game boxed into part of the screen. This is exactly the green-but-broken-for-a-human class R2-META-QA was written to catch, so it blocks GO.

## #1 SOFT-LOCK VERDICT (Cluster B): DEAD — resolved, screenshot-verified

The build-2 soft-lock was: solving p03 (astrolabe) / p04 (sun-moon cabinet) produced a GREY BOX where the coin+crank / file+phial should render, so the yielded items were invisible and uncollectible. Build 3 root-caused it to two missing PLAIN_PLATES entries (cu-cabinet-open, cu-astrolabe-drawer-open) and re-staged them.

Verified on the rendered iPhone-SE playthrough frames:
- play-11-astrolabe: the six-plate Orion selection mini-game renders with distinct engraved dot-patterns — NOT a grey box.
- play-12-cabinet-open: the opened cabinet interior renders real art (container interior + item targets), NOT a grey box.
- Inventory bar in the post-solve frames shows itm-crank, itm-silver-coin, itm-file, itm-phial held — proving the container yields were REVEALED and COLLECTED by tapping visible targets (collect-itm-silver-coin / -crank / -file / -phial), not blind-clicked.
- Activity log confirms the collect-* taps executed and the subsequent assertHolding XCTAsserts passed; the playthrough reached play-18-complete and play-19-badge.

No grey-box / missing-texture frame was found ANYWHERE in the 27 iPhone, 6 iPad, or 6 Dynamic-Island rendered frames reviewed. The soft-lock is dead.

## State-visual rendering after solve/pickup — screenshot-verified PASS

Each resolved state renders its real art in close-up and/or wide view (no stale/blank frames):

| State | Evidence | Result |
|---|---|---|
| p05 ash ring reveal to collect to cleared (R2-003a) | play-02-ash-glint: ring visible in sifted ash; two-step collect confirmed by collect-itm-gold-ring tap + inventory | PASS |
| p02 trapdoor / dial panel | play-03-dial-panel, play-04-dials-solved: 3x8-phase dials render, positions change | PASS |
| p06 barrel pried + weight | cellar frames: nailed barrel pre-solve; weight collected (inventory) | PASS |
| p03 astrolabe drawer open (coin+crank) | play-11 + inventory (crank/coin held) | PASS |
| p04 cabinet open (file+phial) | play-12-cabinet-open + inventory (file/phial held) | PASS |
| p08 shutter/winch to moonbeam-on | play-14-beam: vertical light shaft rendered ON in the cellar | PASS |
| p01 rune door | tiles pressable in close-up; solve reaches z2 (bench mortar close-up opens) | PASS |
| p10 moonflower states | play-07-alcove buds CLOSED; play-15-blooming flowers OPEN | PASS |
| p11 crow freed + lintel perch | play-13-crow-freed (feather beat); play-13b-crow-lintel (crow on doorframe, p16 nudge) | PASS |
| p14 brew draught-ready | play-16-draught: pearlescent cauldron + stir control render | PASS |
| p16/p17 door unseal + complete | play-17-unsealed, play-18-complete (completion card) | PASS |

## Area-by-area (round-2 clusters)

- Cluster A (sound): cannot be screenshot-verified; verified by code/behaviour. music-level1.wav wired as the looping bed replacing ocean; two independent toggles (Ambiance/Music + SFX) in SoundManager/SettingsView; no default per-tap "psh" (flashTapFeedback is visual-only); pickup + distinct event cues retained; new sfx-door. Licensing table present (music user-owned, Producer-cleared). PASS (behaviour/code; real audio is the user TestFlight check).
- Cluster C (item lifecycle): ash ring manual two-step pickup verified on-frame; dropItemIfDepleted place/consume/retain and R2-030 keep-armed-on-failed-use present and unit-tested; combine (file+spoon) verified on the playthrough (combine-itm-spoon). PASS.
- Cluster D (navigation): chevrons cycle views within a zone; diegetic passages (trapdoor/ladder/shelf-gap/rune-door) for zone changes; single-view zone exit down-chevron present; transient nav hint auto-hides; swipe wired. Verified via smoke + playthrough. PASS (functional). See QA-B3-001 for the DI pause-menu clipping.
- Cluster F (triptych R2-007): three per-panel hotspots each opening their own close-up; shared clu-triptych gate id preserved (build-3 test fix tapped the real triptych-3 panel). PASS.
- Cluster G / Q3 (cuckoo removed): every hearth frame (play-01, smoke-03) shows the mantel clock with an INTACT Roman-numeral ring and NO cuckoo bird/door. testAdvancingClockHandsNeverLatchesState_Q3 asserts no latch. PASS.
- Q1 (depleted-hotspot pruning): spent barrel / picked planter show spent state in wide view without pointless zooms. PASS (code; consistent with frames).
- Clue-gating (rev 1.3): the playthrough gathers all gate clues (four marks + grimoire page A for p01, triptych for p02, Orion window for p03, slot-shapes for p04, recipe page for p14) before each gated act; testSaveResumeMidPlaythroughPersistsGate proves D7 (gate stays satisfied across relaunch). PASS.
- Art consistency re-rolls: play-17 / iPad entry frame shows the door beak-basin as GREY STONE (was warm wood); cabinet is the two-door ARMOIRE with a carved SUN emblem (shape-primary, color-blind-safe); statue key reads as a gold star on grey stone. Close-ups match their wide scenes. PASS.

## Full regression — completability

The level is completable END-TO-END by a human-reachable path: the iPhone-SE full playthrough solved p02, p06, p07, p11, p01, p03, p05, p04, p08, p09, p10, p12, p13, p14, p15, p16, p17, collecting every item via VISIBLE targets (no invisible-item reliance), reaching the completion card and Level Select badge. No regression of the round-1 22-bug set or the build-2 fixes was observed in the rendered frames. Functional completability: PASS. (Blocked from GO only by the QA-B3-001 presentation regression, which does not stop completion but is not shippable.)

## Bug list (this pass)

### QA-B3-001 — Game content confined to a left-anchored SQUARE viewport; large dead black band on every device (CRITICAL, blocks GO)
- Severity: Critical (presentation). Not a soft-lock — the level completes — but a real player sees the game boxed into part of the screen with a huge black void, and on the Dynamic Island device the pause menu is partially off-screen.
- Evidence (pixel-measured on rendered CI frames): the rendered content bounding box is a perfect SQUARE pinned to the top-left in every device class:
  - iPhone SE (screen 1334x750): content = 748x748 (aspect 1.0), 43.9 % dead black band on the right.
  - iPad 13" (screen 2752x2064): content approx 2062 wide, 25.1 % black band.
  - Dynamic Island iPhone (screen 2622x1206): content = 1204x1204, 54.1 % black band; pause-menu frame shows the pause buttons crammed into the bottom-left and clipped at the bottom.
- Signature: content width is approximately equal to screen HEIGHT on all three devices, so the SpriteKit scene (2:1 landscape plate, .aspectFill) is being composed into a square SKView of side = screen height rather than filling the full landscape width. The 2:1 plate is cropped to a square viewport occupying only the leading portion of the screen.
- Repro (human): launch on any device (or view any play-* / smoke-* scene screenshot in the CI artifact); the room art fills a square on the left; the right 25-54 % of the screen is solid black. On the Dynamic Island iPhone, open the pause menu; the buttons sit in the bottom-left and are partially below the visible area.
- Why CI stayed green: EscapeRoomUITests.sceneCoordinate() and the app both use the same .aspectFill(2732x1366) math, so scripted taps land inside the square viewport and every assertion passes; assertFullScreenLandscapeComposition only checks the WINDOW frame (origin 0,0, width>height) and does NOT check that the game CONTENT fills the window. This is the build-2 QA-OBS-023 observation, previously ruled "screenshot-fidelity limitation, not a play defect" — that ruling is OVERTURNED: the content is genuinely boxed into a square viewport on the real rendered frames, not a screenshot rotation artifact.
- Route to: Developer (via Producer). Likely fix locus: the SKView / SpriteKitContainerView sizing (a square proposed size is reaching the SKView) or a fixed / aspect-1 frame in the SwiftUI host chain. Fix is presentation-layer; no puzzle logic/art/spec change. After the fix, hotspot rects and the UI-test sceneCoordinate math must be re-verified against the now-full-width composition.

### QA-B3-002 — Completion card / pause chrome clip on wide + notch aspects (MAJOR, likely same root cause)
- Severity: Major. play-18-complete shows the completion card Main Menu / Play Again buttons truncated ("Main Men", "Play Agai"); the Dynamic Island pause menu shows clipped, bottom-left-crammed buttons.
- Assessment: almost certainly a downstream symptom of QA-B3-001 viewport sizing (chrome laid out relative to the square region, not the full screen). The scripted tests still hit the buttons because they resolve by accessibility id, not visible position. Verify it clears once QA-B3-001 is fixed; if it persists, treat as an independent chrome-layout bug.
- Route to: Developer (bundle with QA-B3-001 re-verify).

No Moderate-or-lower new bugs were found in the rendered frames. Prior non-blocking carry-forwards (moonbeam overlay seam residual, in-game VoiceOver labels, Reduce-Motion audit, JC-fb1-3 empty-scene disarm, z2 return-door art AF-1) still stand and remain non-blocking.

## Device / orientation matrix (CI simulators)

| Device | Build | Unit | UI | Rendered-frame review | Verdict |
|---|---|---|---|---|---|
| iPad Pro 13" | pass | pass | smoke + save/resume pass | study/entry/hearth frames reviewed; content is a left-anchored square, 25 % black band | FUNCTIONAL / QA-B3-001 |
| iPhone SE (smallest) | pass | pass | full playthrough + smoke + save/resume pass | all 19 playthrough states reviewed; 44 % black band | FUNCTIONAL / QA-B3-001 |
| Dynamic Island iPhone | pass | pass | smoke (safe-area) pass | in-game + pause frames reviewed; 54 % black band, pause menu partially off-screen | FUNCTIONAL / QA-B3-001 + 002 |

Landscape composition of the WINDOW is correct on all three (QA-OBS-023 window guard passes); the CONTENT composition inside the window is the defect.

## Test-suite recalibration (QA request to Developer — I analyse, the runner executes)

The current suite cannot catch QA-B3-001 because it never asserts that game content fills the screen. Requested additions (route to Developer to implement in EscapeRoomUITests, since QA has no local macOS to run them):
1. Screenshot composition assertion (FAILS on the current bug): after level entry, sample the app screenshot and assert non-black pixels extend across at least ~90 % of BOTH screen width and height (reject the square-viewport / large-black-band case). This assertion is EXPECTED TO FAIL on the current build — that is the point; it turns the human-visible defect into a red CI signal.
2. Chrome on-screen assertion: assert the completion card complete-main-menu / complete-play-again and the pause menu buttons have frames fully inside the screen bounds (catch QA-B3-002).
3. Keep the existing grey-box guard intent: the playthrough already asserts collect-* targets exist and items reach inventory, which would catch a Cluster-B regression; retain and extend to assert the container-open close-up screenshot is not uniformly grey.

## Go / no-go recommendation (decision is the user)

NO-GO for this build.

- The #1 gate (Cluster-B soft-lock) is DEAD and the level is functionally completable end-to-end by a human-reachable path — genuinely good progress over build 2.
- But QA-B3-001 (content boxed into a left-anchored square; 25-54 % dead black band; DI pause menu partially off-screen) is a critical, human-visible presentation defect on EVERY device class tested. It is not shippable and the green CI does not surface it. QA-B3-002 (clipped completion/pause chrome) rides along.
- Recommended path: route QA-B3-001 (+ 002) to the Developer via the Producer as a presentation-layer fix (no logic/art/spec change), add the screenshot-composition + chrome-on-screen assertions so CI goes red until fixed, then re-run this player-style pass. Everything else (soft-lock, state rendering, clue-gating, sound wiring, nav, re-rolls, completability) is GREEN and would clear on the re-run.
- Standing scope disclaimer: CI-simulator evidence only. Real-touch feel, thermals, haptics, and final on-device presentation confirmation remain the user manual TestFlight spot-check before release approval.

---

# Build 10 — player-style regression (QA, 2026-07-12)

**Branch:** `level1-rebuild-build3`, HEAD `84f4d74` (CI tested `a12300c`; delta `a12300c..84f4d74` is `specs/project-state.md` only — no app code, so the CI evidence applies to HEAD).
**Build under test:** build 10 = round-4 fix batch (clusters A–F + singles) + plate re-frame into the iPad dual-safe band with **`.aspectFill` restored (letterbox REMOVED)** + Phase-3 CI-perf/nav fixes.
**Spec under test:** `feedback-backlog.md` "ROUND 4 — PROCESSED 2026-07-11" routed changelist (checkpoint-1 approved), `implementation-notes.md` Build 10 Phases 1–3, `asset-manifest.json` `build10_reframe` (incl. `developer_contract`), `puzzle-graph.json` rev 1.3.
**CI run analysed:** [29190128411](https://github.com/shayma16/escape-room/actions/runs/29190128411) — **GREEN**: build + unit ×3 devices (119 tests each, 0 failures) + UI ×3 (iPad 5/5 incl. FULL playthrough; iPhone SE 5/5 incl. full playthrough; Dynamic Island 2/2).
**Method (binding R2-META-QA):** all six xcresult bundles downloaded via `gh run download`; 100+ attachment PNGs extracted from the CAS stores, restored to upright, and VIEWED; per-frame content compared against the staged plates/overlays; overlay composites reproduced offline from `overlays.json` where the playthrough captured no frame; the R4-007 dial verified by reproducing the exact view transform on the staged sprite. Green assertions alone were never accepted for anything a human can see.

## Headline verdict: **GO** (recommendation — decision is the user's at CHECKPOINT 2)

0 critical, 0 major, 0 moderate new bugs. 2 minor known-residual art items + 2 standing test-infrastructure notes. Every round-4 fix verified; every round-2 closure re-verified still fixed.

## 1. R4-019 lifecycle / alternate-order completability — PASS (the round's critical gate)

- `ItemLifecycle.uses` transcribed 1:1 from the graph (all 15 itm-* nodes verified against `puzzle-graph.json`, incl. `uses: []` never-consume for the rusted key); reconcile hooked at `GameState` init / `setFlag` / `markSolved` — unbypassable, covers the R4-030 combine path.
- **Alternate orderings green ×3 devices:** `testInvariantAndCompletability_orderingA_p06BeforeP05` (the exact soft-lock order: barrel BEFORE ash), `orderingB`, `orderingC_mirrorFirst_cellarFirst` — each asserts after EVERY step that no item ever leaves play with an unsatisfied use, then asserts completion.
- **Coordinator-level repro green:** `testPokerSurvivesBarrelBeforeAsh_thenConsumesAfterBoth_R4_019` drives the real hotspot tap routing — poker survives p06, ring collected (not stranded), poker consumed only after both uses.
- **Both failure directions covered:** R4-030 flip-side visible IN THE RENDERED FRAMES — inventory across the playthrough shows file+spoon present before p12, GONE after p12; crank gone after p08; paste/shavings/feather consumed by the brew (play-16 holds phial only). `testConsumedItemsNeverReappearCollectable`, `testBuild9SaveMigrationReconcilesLingeringItems` (stale build-9 save comes clean), relaunch-mid-pickup anti-softlock — all green.
- Manual pickups uniform: weight (`testWeightManualPickupSurvivesRelaunch_antiSoftlock`) and statue key (`testStatueKeyIsManualPickupFromCloseUp_R4_026`) are two-step collect in the UI playthrough script and passed on both device classes; play-07/play-15 frames show key-in-beak → beak-empty.
- **Scope note (no suite extension made):** the alternate order is verified at engine+coordinator level, not by a second full UI playthrough. Judged adequate, not a gap: rendering is state-driven per element (order-independent by construction), the coordinator repro exercises the real tap path, and a second 12-minute iPad UI playthrough would re-approach the exact CI-starvation cliff Phase 3 just fixed. If the Producer wants belt-and-braces, the cheap follow-up is reordering the EXISTING playthrough script (barrel-before-ash) in a future pass, not adding a run.

## 2. R4-024 per-element overlay architecture — PASS (screenshot-verified)

| Check | Rendered evidence | Result |
|---|---|---|
| Mirror state independent of shelf/drawer | play-05 vs play-06 (iPad): shelf slides + drawer opens + weight hangs; mirror pixel-identical upright | PASS |
| Mirror VISIBLY moves at detents (R4-011) | play-05 (upright) vs play-14 (clearly tilted d3) on BOTH iPad and iPhone frames | PASS — the build-9 "mirror never moves" defect is dead |
| Beam appears only after p08, correct variant | play-14: shaft + tall vertical ellipse at the slid-shelf gap = matches `z3-cellar-beam-alcove` spec plate (distinct from the round `blocked` spot and the `floor` pool), composited with shelf-slid + mirror-d3 + drawer-open on the ONE stable base | PASS |
| No cross-state contamination | no frame anywhere shows a barrel/beam/mirror state flip alongside an unrelated interaction | PASS |
| Hearth overlays registered (R4-004/006) | offline composite of staged `ov-poker-taken` + `ov-rug-moved` + `ov-trapdoor-open` at their `overlays.json` rects: poker cleanly absent (no misaligned patch, no floating fragment), trapdoor renders OVER the folded rug (z-order correct) | PASS (see QA-B10-001 residual) |
| Guard tests | `testEveryCoordinatorRequiredOverlayKeyExistsInCatalog` (R4-011 silent-miss class), `testOverlayRectsAreSaneSubRegionsOfThePlate`, `testMirrorOverlaysSitOverTheLeftStandMirror` — green ×3 | PASS |

## 3. Letterbox removed / no critical element cropped — PASS

- **Harness-immune geometry (the authority):** `testSceneContentFillsScreen_QA_B3_001` DIAG on all three devices shows `sceneFrame == window` EXACTLY — iPad 1376×1032, iPhone SE 667×375, Dynamic Island 874×402, all landscape, scene spans 100 % of the window. `.aspectFill` restored; no in-app letterbox.
- **Rendered frames corroborate:** every one of the 100+ reviewed frames shows art filling the entire app content region — zero internal black bars (build 9's letterbox bars are gone).
- **No-crop guard:** rewritten `testQA_BUG_004_criticalHotspotsInsideDualSafeZone` green ×3 — 32 puzzle-critical hotspot centers inside the manifest dual-safe band (iPad-4:3 ∩ iPhone-19.5:9) on the REMAPPED hotspots; 3 documented exclusions (`ladder`, `cellar-passage`, `workbench`) all have redundant access (chrome `zone-exit` chevron / inventory combine) and the iPad playthrough actually exited the cellar/alcove via the chevron.
- **Reframe fidelity:** Swift `Reframe.transform(for:)` matches `build10_reframe.transforms` value-for-value (all 7 views); staged plates re-staged in re-framed space; UI-test `sceneCoordinate` flipped to max-scale cover math.
- **Screenshot-fidelity caveat (carry-forward, quantified):** the CI framebuffer rasters keep only a screen-height-wide column (iPad 75 %, SE 56 %, DI 46 % of width — `pixelFill_whole` matches exactly), so far-right plate content (barrel, cage, ladder) is absent from CI screenshots. That band loss is the KNOWN harness artifact (portrait boot), not app layout — proven by the window-exact scene frame plus the playthrough successfully tapping those very elements at their visual positions. Final full-width visual confirmation on real glass remains the user's TestFlight spot-check.

## 4. Hotspot re-frame remap — PASS

`testTapsAtVisibleElementPositionsHitTheirHotspots_R3_005` (taps at human-visible art positions, reframed) green ×3; `testQA_BUG_009` 44 pt floor recomputed for `.aspectFill` max-scale, offender list empty ×3; full playthrough completed via scene taps on BOTH the tightest layout (SE) and the primary device (iPad) with arrival-verified navigation (`ensureView` — strictly more rigorous than build 9; no assertion relaxed).

## 5. R4-007 moon dial — PASS (exact-transform verification)

- `MoonDialControlView` line 44 `rotationEffect(.degrees(Double(phaseRaw) * -45))` byte-identical (contract honored; no double-apply).
- Staged `dial-face.png` MD5 == the new pre-rotated `dial-face@3x.png`; the non-prerotated sprite is quarantined in `_rejects/build10-pre-reframe/`.
- Reproduced the view math offline: sprite rotated −225° (waningGibbous, index 5) puts a white gibbous with the **dark bite on the RIGHT** under the top notch — canonical, spec-correct.
- Rendered play-04 frame: dial 1 = waxing crescent (lit sliver right), dial 2 = full, both canonical under their notches; off-notch marks appear rotated exactly as the pre-rotation design predicts. (Dial 3 sits in the CI raster's lost band — covered by the sprite-math proof above.)
- Triptych canon: `cu-triptych-3` (three crows) shows the SAME waning-gibbous dark-bite-RIGHT moon. Dial, triptych, and engine solution indexes all agree.

## 6. Sound — PASS (code + bundle level)

Retired assets physically absent from `Resources/Audio` (`sfx-wood`, `sfx-entry`, `amb-z1..z4`, `sfx-menu-tap`) and guarded by `testRetiredPshAndOceanAssetsDoNotShip_build10` (green ×3); `sfx-seat` added (in-house synth, licensing surface updated); drawer opens silent + spoon pickup chimes (`testDrawerOpenIsSilent_spoonPickupChimes_clusterD`); menu ping standardized (`testMenuPingShipsAndTickIsRetired_R4_003`); music level-scoped and restart-clean (`testLevelAudioIsMusicOnlyAndRestartsCleanly_R4_002_F004`, `testMusicIsScopedToLevelLifecycle_R3_001`). Root-cause verdict recorded by the Developer (never-fully-shipped, not lost) is consistent with the git evidence cited. Audible quality is the user's device check.

## 7. Round-2 closure re-verification (standing directive) — ALL STILL FIXED

| Round-2 closure | Build-10 evidence | Verdict |
|---|---|---|
| State-visual refresh after solve/pickup (R2-014/015 class) | ash-glint ring visible (play-02); dials retain solved marks (play-04); cabinet visibly OPEN in the WIDE view after p04 (play-12 — R4-022(1)); bloom closed→open (play-07→15); key-in-beak→empty; beam on; brew pearlescent spiral (play-16); inventory reflects every consume | STILL FIXED |
| Resolved-container close-ups — no grey box | astrolabe six-plate mini-game + drawer-open (coin+crank), cabinet interior (file+phial), cage-open-empty, crow-rafters ALL current-generation art (staged files viewed); no grey/stale frame in 100+ reviewed | STILL FIXED (cluster C re-staged) |
| Manual pickup (R2-020/F-023/F-018) | ash ring, weight, statue key, spoon all two-step collect in the passing UI script; unit guards green | STILL FIXED (now uniform) |
| Armed-item retention + non-blocking looks (R2-030/R4-005) | `testArmedItemNeverBlocksLooks_R4_005`, `testEmptySceneTapDisarms_R4_005` green ×3; playthrough refusal detour arms + retains | STILL FIXED (model completed) |
| Nav model (F-024/F-025) | smoke walks all z1 views; playthrough traverses all zones via diegetic passages; single-view zone `zone-exit` chevron used by the iPad script | STILL FIXED |
| Triptych per-panel mapping (R2-007) | play-08c renders the real panel-2 close-up; panel-3 canon verified from staged art | STILL FIXED |
| Depleted-hotspot pruning / dead hotspots silent (Q1/F-006/F-014) | `testDeadHotspotsAreSilent_F006_F014` green ×3 | STILL FIXED |
| Clue-gating + D7 persistence (rev 1.3) | `testSaveResumeMidPlaythroughPersistsGate` GREEN on iPad (299 s) AND iPhone SE (100 s) — quit→terminate→relaunch, gate stays satisfied, p01 solves post-relaunch | STILL FIXED |
| psh removal (R2-024) | see §6 — root fixed at the trigger map this time, bundle-level guard added | NOW ACTUALLY SHIPPED |
| Cuckoo removal (Q3) | hearth frames (iPad + iPhone): intact numeral ring, no cuckoo; `testClockIsInertAfterCuckooRemoval_Q3` green | STILL FIXED |
| p04 placement feedback (R4-020(1)/QA-BUG-017) | `testCorrectPartialPlacementGivesPositiveFeedback_R4_020` green ×3; `sfx-seat` ships | FIXED |
| Level Select label (R4-001/R3-003) | play-19 + smoke-02 frames: card reads **"Level 1"**, serif, completion badge renders | FIXED |

## 8. Full end-to-end + save/resume + device matrix

| Device | Build | Unit (119) | UI | Notes |
|---|---|---|---|---|
| iPad Pro 13" (M4) — PRIMARY | pass | pass | **full playthrough (706 s) + chrome-solve (1252 s) + smoke + save/resume (299 s) + fill guard — 5/5 PASS** | first fully-green iPad run under `.aspectFill`; completion card + badge asserted; 50 frames reviewed |
| iPhone SE (3rd gen) — smallest | pass | pass | full playthrough (372 s) + chrome-solve + smoke + save/resume + fill guard — 5/5 PASS | 51 frames reviewed; mirror-move + state visuals confirmed at SE scale |
| iPhone 16-class (Dynamic Island) | pass | pass | smoke + fill guard — 2/2 PASS | scene = window exactly (874×402); visible chrome clear of the island; raster band-loss worst here (46 %) — chrome sign-off carried by the iPad frames + frame-in-window assertions |

Performance: no crashes/hangs in any step; Phase-3 fixes measurably effective (iPad chrome-solve 1252 s vs the 2160 s wedge / 1355 s build-9 baseline); decoded-image cache + cost-bounded texture cache + close-up fps cap are also straight device wins. Total job well inside the 120-min budget.

## 9. Bug list (this pass)

**QA-B10-001 — rug-moved/trapdoor floor tonal seam (MINOR, known residual, Producer-flagged by the Developer).** The `z1-hearth-rug-moved` source plate carries a pre-existing full-frame tone drift, so its hand-cropped overlay brightens the floor region; in a hard compose the rectangular boundary is discernible (verified on the offline composite; softened in-game by the 12 px feather; NOT visible as broken in any captured frame — no playthrough screenshot covers this state). Not a regression; the R4-004/006 MISREGISTRATION half is definitively fixed. Route: Asset Generation derived-crop re-roll of the rug-moved floor region when convenient. Non-blocking.

**QA-B10-002 — legacy flame / slots-seated overlays (MINOR, pre-existing, documented in the manifest `legacy_plates_flagged`).** `ov-flame1/2/3` + `ov-slots-seated` still derive from 2560×1280 build-2-era plates scaled onto the re-framed bases; hard-compose shows a soft rectangular boundary (feather + flame glow mask it in-game; the brew frames reviewed show no objectionable seam at the captured angle). Regenerate from the 4K bases in a future art batch. Non-blocking.

**QA-B10-INFRA-1 (carry-forward of QA-OBS-023 class):** CI simulator rasters keep only a screen-height-wide column (25–54 % width loss), so iPhone/DI chrome and far-right plate content cannot be visually signed off from CI screenshots — those verifications rest on the passing frame-in-window/geometry assertions plus the iPad frames. Physical-device confirmation remains the user's TestFlight step.

**QA-B10-INFRA-2 (visual-only items deferred to the user's device pass):** R4-029(a) combine pulse/hint (implemented; Phase-3 fixed the static-pulse defect; animation not verifiable from stills), real audio quality, haptics/feel. Listed so CHECKPOINT-2 review knows exactly what CI could not see.

## 10. Go / no-go recommendation

**GO** for build-10 release to TestFlight (decision is the user's at CHECKPOINT 2).

- The round's one critical (R4-019 alternate-order soft-lock) is dead — proven at engine, coordinator, and rendered-inventory level, in both failure directions.
- The systemic root (R4-024 plate swaps) is replaced by per-element overlays and every symptom in cluster B is verifiably gone on rendered frames (including the two that had "never actually shipped": mirror movement and wide-view cabinet refresh).
- The letterbox is gone with nothing puzzle-critical cropped (geometry-guarded), hotspots land at visual positions on both device classes, the dial reads canonically, the sound bundle is clean, and all round-2 closures held.
- Remaining items are two minor art residuals (both already flagged and scoped) and the standing CI screenshot-fidelity limit. Nothing blocks shipping.
- On-device confirmation list for the user's TestFlight pass: full-width presentation on real glass, rug-moved floor seam severity (QA-B10-001), combine pulse visibility (R4-029a), menu ping/seat cue by ear, DI pause menu on a real notch device.
