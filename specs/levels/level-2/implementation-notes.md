# Level 2 "The Clockmaker's Attic" — Implementation Notes

Developer Agent build notes for `puzzle-graph.json` rev 1.3. The Documentation Agent
reconciles the walkthrough against the judgment calls flagged here. Every fixed solution
value is implemented exactly as specified (never randomized).

## Architecture — reuse, not reinvent

Level 2 is a **parallel stack that reuses every shared Level-1 system** rather than a
generic engine rewrite (which would have risked the shipped L1 / TestFlight build 14):

- **Shared, unchanged-behavior infra:** `GameState`, `SaveGameStore`, `LevelSaveData`
  (one save format, superset of fields), `RoomScene`, `Hotspot`, `GameAssetLoader`,
  `SoundManager`, `InventoryBarView`, `ItemInspectView`, `GameImage`, `NavChevron`,
  chrome, `PauseMenuView`.
- **New `LevelRules` abstraction** (`Core/LevelRules.swift`): `GameState` resolves per-level
  rules (start zone + item-lifecycle reconcile) from `levelID`. **Level 1 is byte-identical**
  (`Level1Rules == PuzzleGraph.startZoneID + ItemLifecycle.reconcile`). A regression test
  (`testLevel1RulesUnaffected`) asserts L1 still unlocks `z1-cabin`, not the L2 attic.
- **`RoomScene`** now stores an opaque `String sceneName` (was L1's `ViewID`) so it backs
  both coordinators; it never branches on it. Only L1 call-site touched.
- **`PauseMenuView`** decoupled from the concrete session via an `onRestart` closure.
- **L2-specific new files:** `Level2Graph`, `Level2Engine`, `Level2Visuals`,
  `Level2Coordinator` (Game/), `Level2RoomView` (UI/); tests `Level2Tests`,
  `Level2AssetStagingTests`.
- **Per-element overlay compositor:** one stable base plate + independent state overlays
  keyed by state (never a full-plate swap), rects from the 4 zone `*-state-overlays.json`.

## What shipped per zone / puzzle (all logic unit-tested)

- **z1 attic** — p01 numeral-dial door (seat II/IV/VII/XI into sockets 2/4/7/11, tray-VI
  decoy rejected → unlocks z2); p02 cat + wind-up mouse (place mouse on the **floor** near
  the cat executes p02 and yields watch B; offering it **directly** to the cat is the D3
  tell, mouse returns); p03 dormer floorboard cache (clue-gated on watch A, D10 faint-tell
  pre-clue on the correct board → great wheel).
- **z2 workroom** — p04 chimney brick cache (gated on watch B → oil can); p05 oil the
  seized arbor; p06 gear train (mount {36,64} on posts A/B in **either** order, crank →
  24:1 completes the mural → unlocks z3). Lone-48 trap honored (only one 48 exists).
- **z3 behind the dial** — p07 four-wheel vault hatch (**VI-X-I-III**, code changed at rev
  1.2 for Dubai; gated on master-time + world-clock-row → unlocks z4); p08 oil + wind the
  drum (oil first, then key); p09 set the hands (mirrored dial, **front 7:20**; naive 4:40
  does nothing — the trap is implemented, `testNaiveTrapDoesNotReleaseButTrueTimeDoes`);
  p10 push the pendulum. `cond-timelock-release` latches `door-bar-raised` on first
  wound+at-release+swinging in **any order** (`testTimelockOrderFree_pendulumFirst`,
  `testTimelockLatchesPermanently`).
- **z4 vault** — winding key + return-tag pickups; p11 open the stair door → win.
- **D8 keyless remote lock:** the z1 stair door never accepts item/code input; before the
  bar lifts it rattles (SFX) and shows the timelock CU. **p08 mouse-at-drum interaction is
  NOT built** (dead spec text per the binding flag — the mouse is flavor only).

## Judgment calls flagged (ambiguous spec → decision)

1. **Screwdriver / oil-can consumption.** The item nodes say "NEVER consumed", but
   `anti_softlock_invariants` list them under the uses-driven lifecycle. Following the L1
   poker precedent (the user-approved uses-driven rule supersedes the "never consumed"
   prose at the inventory level), both are **retained while any use is unsatisfied and
   consumed once all are** (screwdriver after p03+p04; oil-can after p05+p08). Tests
   `testScrewdriverConsumedOnlyAfterBothCaches` / `testOilcanRetainedAcrossBothUses`. If the
   Producer prefers literal "never consumed", it is a one-line change to give them empty
   effective uses.
2. **Hotspot calibration is approximate.** Hotspot rects are anchored on the state-overlay
   wide rects where a rect exists (stove tile, dial seats, caches, cushion, arbor, brick,
   cabinet, drum, hatch, key/tag), and **estimated** for elements with no overlay anchor
   (coat, slate, barometer, master clock, gear frame, clock row, display case, pendulum,
   great dial, shelf). This mirrors the L1 R3-005 iterative process — **QA should recalibrate
   against the shipped plates.** Not gating (logic is hotspot-position-independent).
3. **Interactive close-ups are functional SwiftUI controls, not painterly.** Dial-door
   (socket tap + tray-VI selectable), gear-frame (gear/post buttons + crank), vault-wheels
   (per-wheel ± with Roman readout + pictogram headers), great-dial (± 5-min crank with
   **mirrored** hand overlays rendered at −θ per D1; **no digital front-time readout** so the
   mirror inference is preserved), winding-drum (armed oil/key), caches (armed pry + manual
   pickup). Faithful to the logic; visual polish is a follow-up.
4. **Animations deferred (cosmetic, non-gating), flagged for a polish pass:** cat pose
   sprites + mouse-skitter + the D3 mouse-tell/refusal *animation* (SFX plays; no rendered
   tell), mural run + strike sprites, pendulum swing, D11 alive-wrong-time hammer-twitch
   *animation* (the D11 *state* is computed by `Level2Engine.isAliveWrongTime`), and the cat
   relocating to the door after p02. These sprite sheets exist in `specs/assets` but are not
   yet consumed — none affect solvability.
5. **Great-dial hands are drawn as SwiftUI capsules** (mirror geometry exact) rather than
   the `hand-hour/minute` sprites, because the sprite pivot/registration values were not
   needed for correctness; swapping to the art sprites is a localized change.
6. **D9 easing valve: NOT implemented** (spec-only, dormant per the user ruling; the z3
   plate reserves the chalk-sketch area). **D10 faint-tell / D11 ambient** are implemented as
   logic + SFX (`sfx-creak`; the D11 *rendering* layer is the deferred animation above).

## Audio (functional SFX — in scope)

- Reuses the existing **synthesized, commercial-safe** L1 cues (pickup, solve, unlock,
  wrong, door, tick, grind, seat, menu-confirm, refusal) mapped to L2 events.
- **Two new cues, originally synthesized in `tools/stage_level2_assets.py`** (no third-party
  audio, so commercial use is unencumbered — same provenance as the L1 SFX): `sfx-creak`
  (D10 pry faint-tell) and `sfx-chime` (strike-train release). **Never a "psh" whoosh/hiss**
  (hard user rule) — creak is a low woody groan, chime a soft struck-bell decay. Menu
  selection stays the established soft ping.
- **Per-zone ambient loops are a documented follow-up** (not shipped this pass): sourcing 4
  licensed ambient beds was out of reach without network access this session; the level bed
  reuses the existing user-owned `music-level1` track as a placeholder. Flag for the Producer
  if dedicated L2 ambience is wanted before release.

## Asset staging + shadow guard (user directive 2026-07-09)

- `tools/stage_level2_assets.py` stages the **manifest-current** art only: wides `@2x`
  (2560×1280 == 2:1 scene), close-ups `@3x` (2048×1536), **wide** overlays `@3x`, icons
  `@2x`, with the `@Nx` suffix stripped so **canonical filename == current art**. `_rejects/`
  and every `-b2pre/-preglyph/-rN/…` shadow source is excluded; a source→canonical collision
  aborts staging.
- Only the `-wide` overlay crops are staged (the CU-only variants are unused by the current
  presentation **and** one — `ov-key-taken` — would collide by basename with an L1 overlay in
  the shared loader index; staging only `-wide` keeps every L2 name globally unique).
- `staged-manifest.json` (canonical name → sha256) ships in the bundle;
  `Level2AssetStagingTests` reloads it in CI and **fails loudly** on any stale-shadow byte
  mismatch, shadow-marker filename, basename collision, or missing/unloadable canonical
  asset. This is the recurrence guard for the build-3 "70 stale close-ups" defect.
- Spot-checked representative close-ups across zones (cu-door-dial, cu-great-dial,
  cu-hatch-wheels, cu-gear-frame) resolve to their current `@3x` sources.

## Security checklist (run before QA handoff)

- **No dev-time secrets in the app.** `grep` of the source tree + the staged bundle
  resources found **zero** references to the fal.ai key / any API key/credential. `.env` is
  gitignored and never copied into any bundle/build phase. The new SFX are procedurally
  synthesized (no network, no keys).
- **Minimal entitlements/permissions.** No camera / microphone / location / contacts usage;
  no `NSCameraUsageDescription`-class strings and no added capability entitlements. Info.plist
  unchanged by this level.

## Spec ambiguities to escalate to the Producer (ask, don't assume)

1. Screwdriver/oil-can "never consumed" prose vs the uses-driven invariant (see #1 above) —
   confirm the uses-driven consumption is acceptable (matches L1) or should be literal.
2. Per-zone ambient loops: ship dedicated L2 ambience, or is the reused music bed acceptable
   for launch? (Sourcing licensed beds needs a follow-up pass.)

## Open items for QA

- Recalibrate hotspot rects against the shipped plates (estimated for non-overlay-anchored
  elements — see judgment call #2).
- Verify the interactive close-up controls read clearly on iPad + iPhone; the great-dial
  mirror inference (no digital readout) is intentional.
- Confirm the deferred sprite animations (#4) are acceptable for the QA pass or should block.

## CI

Build + tests run on the `build-and-test.yml` GitHub Actions macOS runner (no local Mac).
Branch `level2-clockmakers-attic`. See the run linked in the handoff message for green status.

---

## QA build-1 fix batch (checkpoint-2, 2026-07-21)

Implements the user-approved QA build-1 changelist against `qa-report.md` (build-1 section).

### M1 (MAJOR) — dormer floor-cache hotspot re-anchored
`Level2Coordinator.hotspots(.door)` `floor-cache` moved from `x[0.40,0.60] y[0.80,0.96]`
(zero overlap with the cache art) **onto** the `ov-cache-*` wide rect `x0.6375–0.7656,
y0.898–1.0`. The `minHitSize` floor (182 scene px) expands the short rect **upward**, giving
a comfortable tap target above the inventory pill. Now overlay-anchored like every other L2
hotspot; verified by the new registration + visual-tap guards.

### Minor hotspot calibration (against the shipped plates)
- **m3** — z4 `key-hook` / `tag-nail` re-anchored to their `ov-key-taken` / `ov-tag-taken`
  wide rects (`key` `x0.2604–0.3268`, `tag` `x0.1563–0.2526`); no more overlap of the
  neighbour's art edge (previously `key` `x[0.23,0.37]` covered the tag).
- **m4** — z1 `cat-cushion` bottom extended `0.77 → 0.81` so the `ov-cushion-reveal` band
  (watch B on the bench, to `y0.807`) is tappable.
- **m5** — z3 `great-dial` right edge notched `0.62 → 0.50` so it no longer overlaps the
  `pendulum` column (art band `x[0.529,0.594]`); the pendulum owns its column unambiguously
  rather than relying only on smallest-area-wins.
- **m6/m7 (awareness, unchanged):** the gear frame can hold the same rack value on both posts
  (the lone-48 `Set` trap still holds) and p03/p04 collapse the pointer beat to one always-
  correct spot. Both left as documented design/awareness items per the report; not defects.

### M3 (MAJOR) — p09 endgame feedback (pendulum swing + D11 alive-wrong-time)
`Level2Visuals.dialMechanism(state)` is a pure, order-free descriptor (pendulum swinging /
full-swing / alive-wrong-time). `Level2Coordinator.updateDialMechanismAnimations()` (called
from `refresh()` for `.dial`) drives two procedural SpriteKit motions in `RoomScene`
(`setPendulumSwing`, `setHammerTwitch`):
- **Pendulum swing (m2):** a procedural rod+bob pivoting over the `ov-pendulum-absent` dark
  bed — weak amplitude when unwound, fuller once wound. The **only** on-screen confirmation
  p10 succeeded.
- **D11 alive-wrong-time (M3):** a soft repeating escapement **tick** (via `SoundManager.play(.tick)`,
  so it respects the SFX mute) + an occasional single **hammer twitch** over `ov-hammer-absent`
  that lifts and settles but **never strikes**. Active only while wound AND swinging AND NOT
  at release; stops the instant the strike latches the door bar or any input drops.
- **Judgment call:** these are drawn **procedurally** (no bespoke swing/hammer sprite art
  ships — only the `-absent` dark beds), consistent with L2's mirrored clock hands already
  being procedural SwiftUI capsules. The other deferred cosmetic animations (cat poses, mouse
  skitter, mural strike, cat relocation) remain deferred per the approved scope.

### M2 (MAJOR, process) — human-visible test net for L2
Previously L2 had only engine-unit + asset-staging tests. Added, mirroring the L1 guards:
- **`EscapeRoomTests/Level2RegistrationTests.swift`** (unit, runs on all 3 device runtimes):
  registration guard (**every interactive hotspot must intersect the art rect it controls** —
  the exact M1 invariant), player-style **visual-tap** hit resolution at each element's
  overlay-rect centre under real smallest-area-wins (direct catcher for M1/m3/m5), overlay
  **pixel-1:1** vs the @3x wide rect (R7-001 class), completeness, sub-region sanity, and the
  44 pt hit-target floor on the smallest iPhone.
- **`Level2Tests.swift`** additions: graph **example-ordering A + B** (pendulum-first)
  end-to-end engine solves, a **hidden-zone mid-puzzle save/resume** round-trip, the M3
  dial-mechanism descriptor, the coat-collect regression, and the level-scoped music test.
- **`EscapeRoomUITests/Level2UITests.swift`** (XCUITest): L2 menu/entry, composition guard,
  z1 pickups tapped at their **visual** scene positions (incl. the coat fix), close-up
  presentation, navigation arrival, pause round-trip. **CI device scoping** (build-and-test.yml):
  runs on **iPhone SE** (full L2 smoke + composition) + **Dynamic Island** (L2 composition);
  the whole `Level2UITests` class is **skipped on the iPad UI step**. The iPad full-solve L1
  UI tests already sit at the CI runner's capacity (documented simulator-starvation flakiness —
  across three iPad runs of this batch, three *different* L1 tests flaked: the save-resume
  terminate flake, then the chrome-snapshot UI-query timeout — while `testL2SceneContentFillsScreen`
  passed on iPad every time). Adding L2 UI to that marginal step only worsens it, so L2's iPad
  coverage is the fast, reliable **unit-level** `Level2RegistrationTests` + `Level2Tests`
  (geometry + example-ordering completability), which run in the iPad UNIT step.
- **Scope judgment call (flag to Producer):** a **full blind 11-puzzle XCUITest solve is not
  shipped.** No local Mac + 10× macOS CI cost make a blind full-chrome solve disproportionately
  fragile to author/iterate. The full human-visible **completability** + **every-element-at-its-
  visual-position** verification is instead delivered reliably (and on all three device
  runtimes) by `Level2RegistrationTests` (geometry) + `Level2Tests` example-ordering solves
  (completability), with `Level2UITests` covering the on-device chrome wiring the unit layer
  cannot. If QA requires a literal full-chrome XCUITest playthrough, it should be a scoped
  follow-up.

### Critical completability bug found + fixed while building M2
The bench **coat** close-up shipped as a **plain image with no pickup path**, so `tile IV`
(required by p01) and `watch A` were **unobtainable through the real UI** — Level 2 was
**uncompletable in-app** (engine-only QA missed it; exactly the class M2 exists to catch).
Fixed by a proper two-pocket collect close-up (`L2CloseUp.coat` → `L2CoatControl`, buttons
`collect-itm-tile-iv` / `collect-itm-watch-a`), mirroring the existing cache-collect pattern.
This is a missing-interaction-path fix (Developer scope, like L1 QA-BUG-002/003), **not** a
puzzle-logic change. Regression: `testCoatCloseUpCollectsWatchAAndTileIV`.

### m1 (MINOR) — screwdriver / oil-can literally never consumed
`Level2Graph.neverConsumedItems = {itm-screwdriver, itm-oilcan}`; `Level2Lifecycle.hasRemainingUse`
returns `true` for them regardless of `uses`, so both are retained the whole level per the
graph nodes' explicit "NEVER consumed" (oil-can "and beyond"). No soft-lock (no use exists
after their last). Tests flipped to assert **persistence**
(`testScrewdriverNeverConsumedAfterBothCaches`, `testOilcanNeverConsumedAcrossBothUses`).
This supersedes the earlier "uses-driven consumption acceptable?" escalation (#1 above) — now
implemented literally.

### Music — music-level2.wav wired as the level-scoped L2 bed
`SoundManager.enterLevel(levelID:)` selects `music-level<N>`; L2 now plays **music-level2.wav**
(was reusing the L1 bed), level-scoped exactly like L1: in-level only, stops on exit +
level-complete, under the ambiance/music mute, under gameplay volume. Call sites updated
(`LevelLoadingView` passes the real `levelID`; L2 replay passes 2; L1 passes 1).
**Licensing:** `music-level2.wav` is **fal.ai-generated, user-owned, commercial-use OK
(user-confirmed 2026-07-21)** — recorded here per the sound-scope licensing rule.
Test: `testLevel2MusicIsLevelScopedAndBundled`.

### Security checklist (re-run for this batch)
- **No dev-time secrets:** `grep` of the source tree + staged bundle for
  `fal.ai/api-key/secret/bearer/credential/sk-` found only **comment/credits prose** (SettingsView
  About text; SoundManager licensing comment) — **zero** keys/credentials. `.env` gitignored,
  never bundled. New escapement audio reuses the existing procedurally-synthesized `sfx-tick`.
- **Minimal entitlements/permissions:** no camera/mic/location/contacts usage; no
  `NS*UsageDescription` strings; no capability entitlements added. Info.plist unchanged.

### Residual QA-worthy items surfaced by this batch (flag to Producer — NOT fixed here)

1. **L2 iPad edge-crop (potential MAJOR, L1-BUG-004 class).** The L2 wide plates were never
   re-framed into the §8 iPad-4:3 ∩ iPhone-19.5:9 dual-safe band (L2 hotspots are authored in
   raw final-plate space, no `Reframe`). Under `.aspectFill` on iPad the visible x-range is
   ~[0.167,0.833], so **far-left/right x-edge elements are cropped** — notably the bench
   **coat** (x-center ~0.115), which is **p01-critical** (tile IV). On iPhone-SE the band is
   ~[0.055,0.945] so they are reachable. This means L2 may be **hard/uncompletable on iPad**
   at the coat (and any other x-edge hotspot). Building the M2 UI net surfaced this; the fix
   is an Asset-Gen dual-safe re-frame of the L2 plates + a hotspot remap (as L1 did in build
   10), which is **out of this batch's scope**. Interim: the L2 pickup smoke is iPhone-scoped
   in CI and this is flagged for the TestFlight iPad spot-check + a follow-up re-frame task.
2. **Full-chrome XCUITest playthrough** of p02–p11 is not shipped (see the M2 scope note
   above); completability is proven at engine (example-ordering A/B) + geometry (visual-tap)
   level. A literal full L2 XCUITest solve, if required, is a scoped follow-up (and is blocked
   on item 1 for the iPad half).

### R-REANCHOR (MAJOR) — "L2 uncompletable on iPad" root cause fixed (2026-07-21)

The Asset-Gen re-frame proposed in "Residual item 1" above was **CANCELLED**: a diagnostic
reversed the premise. The wide PLATES are correctly framed — every puzzle-critical element's
ART sits inside the iPad dual-safe band (x∈[0.167,0.833]) on 6 of 7 views. The real cause was
a batch of **stale/"estimated" inspect hotspots that pointed at empty space OUTSIDE the band
while the art was elsewhere IN-band.** The coat hotspot was x[0.03,0.20] (off the iPad left
edge) but the pocketed-coat ART hangs on the RIGHT at x≈[0.68,0.80] — so p01's coat close-up
(tile IV + watch A) could never be opened on iPad. No art changed; only the Swift hotspot
rects were re-anchored to the shipped-plate art (evidence sheets:
`specs/assets/level-2/_reframe-work/evidence-*.png`).

Re-anchor table (old rect → new rect, anchored-to; all measured from the shipped
`Resources/GameAssets/level-2/` base plates):

| view | hotspot | old (x,y,w,h) | new (x,y,w,h) | anchored to |
|------|---------|---------------|---------------|-------------|
| bench | **coat** | 0.03,0.26,0.17,0.42 | 0.68,0.21,0.13,0.46 | pocketed coat on right hook (p01 blocker) |
| bench | barometer | 0.80,0.18,0.15,0.26 | 0.28,0.05,0.10,0.18 | round gauge, top-center |
| master | master-clock | 0.06,0.08,0.22,0.74 | 0.31,0.15,0.15,0.73 | longcase clock, center-left |
| door | house-ring | 0.52,0.28,0.12,0.16 | 0.45,0.32,0.10,0.16 | ring glyph on central post (narrowly missed before) |
| clockrow | clockrow | 0.06,0.26,0.48,0.34 | 0.18,0.16,0.64,0.42 | four world-clocks span |
| clockrow | display-case | 0.76,0.28,0.20,0.38 | 0.17,0.62,0.30,0.30 | glass case, bottom-left |
| vault | vault-exit | 0.85,0.20,0.13,0.60 | 0.30,0.15,0.18,0.70 | exit stairs, center |

All new rect **centers are inside the iPad dual-safe band** (coat 0.745, barometer 0.33,
master-clock 0.385, house-ring 0.50, clockrow 0.50, display-case 0.32, vault-exit 0.39 — all
in x[0.167,0.833], y[0.038,0.962]). **house-ring** was an audit catch beyond the named list:
its old rect started just RIGHT of the glyph and missed it. Every other "estimated"/overlay-
anchored hotspot was audited against its evidence sheet and left as-is — the overlay-backed
set (screwdriver, stove, crate, sill, door-dial, bar, arbor, gear-rack, brick, panel, cabinet,
drum, hatch, key-hook, tag-nail) already matches, and `slate`, `shelf`, `gear-frame`,
`great-dial`, `stair-door`, `cat-cushion`/`cat-floor`, `pendulum` already intersect their art
in-band.

**z3 winding drum (Producer decision, option a):** the drum BODY reads ~left-cropped on iPad,
but its interactive square SOCKET (key-in point) is centered ~x0.198 — in-band and tappable —
and the existing `drum` hotspot x[0.08,0.26] already covers it. Per the decision we ACCEPT the
cosmetic left-crop of the drum body and do NOT re-frame/shrink the hero great-dial. The drum
hotspot was left unchanged. **Flagged for the user's device spot-check: the drum reads slightly
clipped on iPad.**

**Registration-guard coverage:** the overlay-backed hotspots were already covered by the M2
`Level2RegistrationTests` overlay↔hotspot registration + visual-tap guards. The seven re-
anchored inspect hotspots have NO state overlay to key on, so a new guard,
`testL2InspectHotspotsSitOnArtAndAreIPadReachable`, was added: for each it asserts (a) the
hotspot intersects the measured element ART, (b) a tap at the art center resolves to that
hotspot under the real smallest-area-wins hit test, and (c) the art center falls inside
`Reframe.dualSafeX`/`dualSafeY`. Reverting any hotspot to its old off-band rect fails (b)+(c)
loudly. This closes the gap that let a look/collect hotspot drift off its art unnoticed.

**Coat/p01 path now reachable on iPad:** the `coat` hotspot center is x0.745 (in-band), so
tapping the visible coat opens `L2CloseUp.coat`, whose two-pocket collect UI yields tile IV
(feeds the p01 dial) and watch A — the p01 solve path is reachable within the iPad-visible band.

_Supersedes Residual item 1; the Asset-Gen re-frame is no longer needed. Item 2 (full-chrome
XCUITest playthrough) is no longer blocked on an iPad re-frame._

### CI — two-lane split (user-approved efficiency change, 2026-07-21)
`build-and-test.yml` is now split into two jobs:
- **FAST lane** (`fast-lane`, ~15-20 min) — runs on **every push (any branch)** + every
  workflow_dispatch. Build + the full unit/logic suite for all levels on 3 device runtimes,
  INCLUDING the M2 net that actually catches the M1 class: `Level2RegistrationTests` (static
  overlay↔hotspot **registration** guard + player-style **visual-tap** geometry + example-
  ordering **completability**) and `RenderedFrameOverlayTests`. **No simulator UI playthroughs.**
  This is the per-iteration blocking gate.
- **FULL lane** (`full-lane-ui`) — runs **only on push to `main` or a manual dispatch with
  `lane=full`**; `needs: fast-lane`. Adds the heavy on-device UI regression (the ~75-min L1
  iPad full playthrough + the iPhone-SE playthrough/L2 smoke + Dynamic-Island shots). The
  capacity-bound **iPad full-playthrough step is `continue-on-error`** (documented simulator-
  starvation flakiness — it flaked on 3 different L1 tests across this batch's iPad runs while
  every L2 test passed), so a transient iPad flake reports but never holds a batch hostage; the
  reliable iPhone-SE + DI UI steps stay hard gates.

Rationale: the single ~75-min iPad L1 playthrough was the dominant per-iteration cost and the
sole flake source; moving it (and the L2 on-device UI) to the FULL lane lets fix batches
validate the game logic + M1-class geometry in ~15 min. `release.yml` and the green-signal
semantics are unchanged (a run is green iff its non-skipped, non-continue-on-error jobs/steps pass).

**Validating runs (this batch):** fast lane green on branch `level2-clockmakers-attic`
(build + all unit/geometry/registration tests, 3 runtimes); the iPhone-SE full UI suite —
incl. the new L2 smoke + composition — verified green in the pre-split runs
(29832607524's iPhone-SE UI step ✓; L2 `testL2SceneContentFillsScreen` ✓ on iPad too). The
only red ever observed was the pre-existing L1 iPad-runner flakiness, now non-blocking. See
the handoff message for the exact fast-lane + full-lane run links.

### Build-15 pre-release gate fix — STALE UI-TEST COORDINATE, not a game bug (2026-07-22)

**Symptom.** Full-lane gate run `29861667813` failed on the hard-gated *UI tests — smallest
supported iPhone* step: `Level2UITests.testL2Z1PickupsCloseUpsAndNavigationSmoke` asserted the
coat close-up (`closeup-dismiss`) opened after `tapScene(0.17, 0.32)` — it did not. The
Dynamic-Island step never ran (the job aborted after iPhone-SE failed).

**Root cause — definitive: a stale hand-coded UI-test tap, NOT a game regression.** Commit
`203036a` re-anchored the `coat` hotspot from the stale far-left `x[0.03,0.20]` to the actual
pocketed-coat art on the RIGHT hook (`Hotspot(id:"coat", 0.68,0.21,0.13,0.46)`, center
**x0.745, y0.44**). The UI smoke test still tapped the OLD literal **(0.17, 0.32)** — now empty
space — so the coat close-up never presented. The game logic is correct: `Level2Coordinator`
routes `(.bench,"coat") -> present(.coat)` unchanged, and the M2 registration guard
`testL2InspectHotspotsSitOnArtAndAreIPadReachable` (which resolves the tap from the ART CENTER,
not a hardcoded coordinate) PASSED — it proved a tap at the coat's rect center resolves to the
`coat` hotspot under the real smallest-area-wins hit test. On iPhone-SE geometry (landscape,
`.aspectFill`, visible x≈[0.056,0.944]) x0.745 is well inside the crop. So the coat opens
correctly at its real art position; only the test's tap was stale. No game code needed changing
to make the coat open.

**The real fix — UI-test-tap ↔ hotspot-rect coupling (single source of truth).** Fixing just
the coat literal would leave the whole *class* alive (any future re-anchor re-breaks a hardcoded
tap — the same desync that shipped this red gate). So both sides now read ONE table:

- New dependency-free file **`EscapeRoom/Game/Level2HotspotTable.swift`** holds every L2 hotspot
  rect (normalized, keyed by `L2ViewID` raw value). It is compiled into BOTH the app target and
  the `EscapeRoomUITests` target (UI-test target is a separate process, so no duplicate-symbol
  issue; the unit-test target keeps using `@testable import`).
- `Level2Coordinator.hotspots(for:)` is now a 3-line map over `Level2HotspotTable.rects(forView:)`
  — the game hotspots ARE the table.
- `Level2UITests` gained `tapHotspot(_:in:)`, which resolves the element's rect from the SAME
  table and taps its on-screen center. All six scene taps in the smoke test (screwdriver, stove,
  coat, crate, door-dial, sill) were converted from hardcoded literals to `tapHotspot`. A
  re-anchor now moves the game hotspot AND the UI-test tap together — the desync class is closed.
  - `tapHotspot` clamps the tap's window-Y up out of the bottom inventory-bar band while staying
    inside the hotspot rect, so the bottom-heavy `crate` (rect center falls under the bar) is
    tapped on its visible upper art — replacing the old hand-tuned `y=0.80` magic offset with a
    derived one. Purely geometric; no literal re-introduced.
- Among the seven re-anchored hotspots (coat, barometer, master-clock, clockrow, display-case,
  vault-exit, house-ring) only `coat` was actually tapped by a UI test; the audit confirmed the
  other six are not referenced by any L2 UI-test tap. All L2 UI-test taps are now table-derived
  regardless, so the audit result can't silently rot.

**New deterministic guard (fast lane, no simulator).**
`Level2RegistrationTests.testL2HotspotTableIsTheSingleSourceForCoordinatorAndTapCenters` asserts
(1) the coordinator's configured hotspots match the table (id set + rects) per view, and (2) a
tap at each table entry's CENTER — exactly what `tapHotspot` taps — resolves to that hotspot
under the real hit test. This CI-proves the UI-test tap assumption without an on-device run, so
the stale/desynced-tap class fails loudly in the ~15-min fast lane going forward.

**Also updated:** the stale scope-note comment above the smoke test (which still described the
coat as a far-left element off the iPad crop) now reflects the re-anchored in-band coat and
points at the iPad-reachability unit guard.

**Validating runs (this fix):** fast lane <FAST_RUN_URL>; full lane <FULL_RUN_URL> — GREEN on
BOTH hard gates (iPhone-SE UI playthrough + Dynamic Island); the iPad full-playthrough step
stays `continue-on-error`. Links filled in the handoff message.
