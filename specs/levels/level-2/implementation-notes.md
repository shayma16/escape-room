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
(1) the coordinator's configured hotspots match the table (id set + rects) for ALL views, and
(2) for every hotspot the UI test taps by center, a tap at that table entry's CENTER — exactly
what `tapHotspot` taps — resolves to that hotspot under the real hit test. This CI-proves the
UI-test tap assumption without an on-device run, so the stale/desynced-tap class fails loudly in
the ~15-min fast lane going forward.

_Benign pre-existing overlap surfaced (out of scope, flagged not fixed): the guard's initial
broad form (every hotspot's exact center resolves to itself) caught `v-frame/gear-rack` — its
dead center (0.65,0.66) sits on the loose-`brick` hit region, so smallest-area-wins returns
`brick` there. `gear-rack` is still reachable everywhere left of the overlap (x<0.65); the rects
are unchanged from before this batch, and hotspot geometry is design (not Developer's to move).
`gear-rack` is not tapped by center in any UI test, so guard part (2) is scoped to the actual
UI-tapped set (`uiTappedHotspots`, kept in lockstep with the smoke test). Recommend the Theme/
Art owner review the gear-rack↔brick hit overlap in a future pass._

**Also updated:** the stale scope-note comment above the smoke test (which still described the
coat as a far-left element off the iPad crop) now reflects the re-anchored in-band coat and
points at the iPad-reachability unit guard.

**Validating runs (this fix):** fast lane <FAST_RUN_URL>; full lane <FULL_RUN_URL> — GREEN on
BOTH hard gates (iPhone-SE UI playthrough + Dynamic Island); the iPad full-playthrough step
stays `continue-on-error`. Links filled in the handoff message.

---

## Round-8 fix batch → build 16 (device feedback, 2026-08-05)

Authority: `specs/levels/level-2/round8-routed-changelist.md` + `specs/feedback-backlog.md`
ROUND 8. All items user-approved at GATE 1 (2026-07-22). Source: TestFlight "Within 1.0 (15)",
iPad, first Level-2 device playthrough. **Art spend this round: $0.00** — every resolved-state
plate this batch needed already existed; it had simply never been staged.

### Cluster A (P0) — close-up STATE rendering

**Confirmed root cause, and one more layer than the changelist found.** Two independent
failures stacked:

1. **Code:** nothing in the close-up path consumed the per-element state overlays.
   `Level2Visuals.wideOverlays` composited them into the WIDE scene only. Every close-up was
   `GameImage(name: <one constant>)`. The worst instance was the literal no-op ternary called
   out in the changelist —
   `coordinator.state.hasSolved(...catMouse) ? "cu-cat-cushion" : "cu-cat-cushion"` — in a view
   with **no tap target at all**, which is why the cushion could never be lifted (R8-013 P0).
2. **Assets (not previously diagnosed):** the CLOSE-UP overlay crops
   (`specs/assets/level-2/**/states/ov-*@3x.png`, the non-`-wide` variants) were authored in
   batches 2/3 **and were never staged into the bundle**. `tools/stage_level2_assets.py`
   deliberately staged only `ov-*-wide@3x.png`, with a comment saying the CU variants were
   "unused by the current presentation". So even a correct compositor would have had nothing
   to draw. Both halves are fixed here.

**The fix — one path, not per-close-up patches.**

- New `EscapeRoom/Game/Level2CloseUpVisuals.swift`: a pure, order-free
  `(L2CloseUp, GameState) -> Plan` resolver — the exact mirror of the wide path. A `Plan` is
  `{ base plate, [Layer], [Target], focus }`, where each `Layer` is an overlay key + its staged
  image + its authored CU rect, and each `Target` is a manual-pickup/lift hit region sitting on
  the art it collects.
- New `L2Plate` in `Level2RoomView.swift` is the **single renderer**. Every close-up — plain
  plates included — now goes through it. Nothing else decides what a close-up shows, so a new
  stateful close-up cannot silently ship stale.
- `tools/stage_level2_assets.py` now stages the CU overlay crops as `<key>-cu.png`. The `-cu`
  suffix exists because `GameAssetLoader` indexes by BASENAME across all levels and the raw CU
  names collide with Level 1 (`ov-key-taken`). The mapping is 1:1, deterministic, recorded in
  `staged-manifest.json` (name → source + sha256), and two sources landing on one canonical name
  still hard-fail the script — so the 2026-07-09 "canonical filename == current art" guarantee
  holds. It also now stages `z1-cat-face.json`, the rack gear cutouts (`z2/props/gear-*`), the
  landmark dies (`masters/glyphs/die-*`) and the canonical hour hand.

**States that now render in close-ups** (each one an R8 item): coat pockets emptying
independently; the four dial sockets showing their seated tiles; the dormer/chimney caches
pried-with-the-find then emptied; the cushion's four-step cat→gone→lifted→emptied chain; the
sill/stove/crate tiles disappearing once taken; the raised time-lock bar; the rack gaps; the
gears mounted on posts A/B; the oiled drum and seated winding key; the emptied key hook and tag
nail; the cabinet drawer with/without the tin mouse.

### Cluster B — the occluded dismiss chevron

Root cause confirmed exactly as diagnosed: `L2CloseUpHost` gave the content
`.padding(.bottom, barHeight)` but the chevron a flat `.padding(.bottom, 12)`, and
`InventoryBarView` is added to the parent ZStack AFTER the close-up host (deliberately —
§7-R1.5 / F-020 require the bar to stay live inside close-ups). The 88×56 chevron therefore sat
inside a 72 pt (iPad) / 62 pt (iPhone) bar band on **every** L2 close-up.

Fixed by matching Level 1's convention (`bottomInset + 10`), and by promoting that convention
into testable data: new `L2CloseUpChrome` (in `Level2CloseUpVisuals.swift`) exposes
`dismissBottomPadding(barHeight:)`, `dismissFrame(in:barHeight:)` and
`inventoryBand(in:barHeight:)`. Z-order is unchanged (the bar stays above the close-up, per
F-020); only the inset changed.

### Cluster C — iPad close-up layout collapse

Root cause confirmed: `L2CoatControl` was `GeometryReader { ZStack { … } }` whose only
full-size children were the CONDITIONAL positioned pocket buttons; when the last one
disappeared the ZStack shrank to the fitted image and GeometryReader re-placed it top-leading.

`L2Plate`'s stack is now explicitly `.frame(width: geo.size.width, height: geo.size.height)`
with a constant `Color.clear` anchor, so its layout is independent of every conditional child.
Because **all** L2 close-ups are built on `L2Plate`, the audit the changelist asked for is
structural rather than per-view: there is no longer a close-up that can collapse.

### Cluster D — the tray-VI decoy

The floating `Button { Text("VI") }.position(x: plate.midX, y: plate.maxY - 20)` is deleted.
The decoy is now a tap region on the **depicted** tile in the tray art. Its rect is
deterministic, not eyeballed: `specs/tools/l2_dialfix.py` lays the canonical foreshortened tile
at center (1120, 1204), ~118×52 after its −5° rotate, on the 2048×1536 plate —
`Level2CloseUpVisuals.trayDecoyRect` is exactly that, with the host applying the 44 pt floor.

**Semantics implemented per the graph, not invented.** p01 `solution_fixed` lists
`"rejected": "tray VI in socket-4"`, and the derivation says "Seating the tray VI in socket-4
whirs, stalls, and pops it back to the tray". So the decoy is *selectable bait*: tap the tile to
pick it up (a pale selection ring — no text, no badge), tap a socket, it is refused and pops
back. It is **never** an inventory item (standing R6-003 principle) — `Level2Engine.seatDialTile`
already guarantees this structurally (`Level2Graph.DecoyTile.trayVI` can never match
`dialSolution`), and `testTrayDecoyIsAnOnPlateRegionAndNeverCollectible` locks it.

### USER RULING — restore the MANUAL cushion pickup (R8-013)

`placeMouseAtCat` no longer calls `state.addItem(watchB)`. p02 now only vacates the cushion; the
graph's yield ("cushion now liftable; watch B beneath") is delivered as two deliberate taps:

    cat asleep  →[p02]→  cat gone, cushion down (liftable)
                →[tap cushion]→  cushion lifted, watch B on the bench
                →[tap watch]→    emptied

New latched flag `Level2Graph.Flag.cushionLifted` (in the existing generic flag bag — no save
schema change), plus `Level2Engine.isCushionLiftable / liftCushion / isWatchBUncollected /
collectWatchB`, all pure functions of latched state.

**Save migration.** A build-15 save that already holds watch B (auto-granted) resolves
`isCushionLiftable == false` and `isWatchBUncollected == false`, so the cushion reads as empty
and the watch is never re-offered — guarded by `testLegacySaveHoldingWatchBShowsNoRevealAndNoLift`.

**FOR DOCUMENTATION:** the FINAL walkthrough's cushion-lift step is now **correct again** and
needs no change on that point. It does need the p03 clarification below.

### USER RULING — near-wordless: literal text UI removed

Replaced with pictogram/glyph affordances from canonical masters. No text labels remain in any
L2 scene or close-up.

| Was | Now |
|---|---|
| `Text("VI")` floating button (p01) | the depicted tray tile + a pale selection ring |
| `Text("Rack")` + `Text("16")…` gear buttons (p06) | the real gear cutouts `z2/props/gear-*`, sized by tooth count so the ratio reads at a glance; `inv-great-wheel` for the 64 |
| `Text("Post A")` / `Text("Post B")` + `Text(current ?? "—")` (p06) | the composited `ov-mount-a/b-<g>` art ON the plate; an empty post shows a faint dashed seat ring |
| `Label("Crank", …)` button (p06) | SF Symbol `arrow.triangle.2.circlepath` only |
| `Text("Big Ben"/"Burj"/"Liberty"/"Fuji")` headers (p07) | the canonical landmark dies `die-bigben/burj/liberty/fuji` — which is what `clu-worldclock-row` says the player matches ("landmark identification is NOT required — pictogram matching to the vault headers suffices") |

**Judgment call (flagged):** the p07 wheel READOUTS still render Roman numerals (`VI`, `X`, …)
and the great-dial has no readout. Numerals are the puzzle's diegetic content, not UI labels, and
they match the numerals painted on the plate itself — so they were kept. If the Producer reads
"near-wordless" as excluding numerals too, say so and they can be swapped for the canonical
`masters/glyphs/num-*` engravings.

### USER RULING — p03/p04 KEEP SIMPLE + CLARIFY (R8-009)

**The pointer MECHANIC was not restored.** The cache stays a single always-correct hotspot gated
on the watch clue. Two presentation-only changes make the clue path legible, both using existing
canonical art:

1. **The ⌂-ring close-up now shows the direction.** Once `clu-watch-a` has been viewed (i.e. the
   player has inspected watch A), `cu-house-ring` composites the canonical hour hand
   (`z3/v-dial/sprites/hand-hour`) pivoted at the ring hub and pointing at the 3-o'clock notch.
   The ring alone said "apply a clock direction HERE" but showed no direction; now the ring and
   the watch are visibly bound. Wordless, deterministic, gated so it never spoils the beat for a
   player who has not read the watch. Table: `Level2CloseUpVisuals.ringClues`.
2. **The clock-row clue reads as a clue.** `cu-clockrow-plates` is an ~80% crop that also carries
   the display case and the parts cabinet, so the four timezone plates rendered small
   (R8-008(2)/(3)). The plan now carries a `focus` rect (`0.02, 0.03, 0.96, 0.52`) and `L2Plate`
   zooms the presentation to the clock band. A deterministic presentation crop — **no new art**.

**Producer decision needed (I did NOT act on it):** no art annotation was generated, per the
"flag first" instruction. If the ring-pointer overlay proves insufficient in the blind re-check,
the next step would be a tiny deterministic engrave on the wide plate — that is an Art
Director/Asset-Gen call, not mine.

**Escalation — `clu-ring-chimney` is UNREACHABLE in the build.** `cu-gear-ring` (the ⚙ ring on
the chimney breast) is staged and `Level2Coordinator.gatingClues` maps
`plain-cu-gear-ring → clu-ring-chimney`, but **no `gear-ring` hotspot exists in
`Level2HotspotTable` for `v-frame`**, so the close-up can never be opened. The clue is
"anchor only, not part of the gate" (graph), so this does not block p04 — but the p04 half of the
ring↔watch beat is currently invisible, and the p03 fix above therefore has no p04 twin. Adding
a hotspot is a geometry/design change (it must pass the M1 registration + iPad-band guards), so
**routing this to the Producer rather than fixing it unilaterally.** The ring-clue table already
contains the `cu-gear-ring` entry (hour IX, gated on `clu-watch-b`), so the annotation lights up
the moment a hotspot is added.

### R8-011(1) — the cat's mouse-tell is now VISIBLE

The rev-1.3 tell shipped sound-only. The facial-key art already existed and was never staged or
loaded: `ov-cat-mouse-tell` (eyes open + locked amber gaze), `ov-cat-mouse-tell-tail` (tail-tip
flick) and `ov-cat-slow-blink`, with rects in `z1/z1-cat-face.json`.

- `Level2OverlayCatalog` now loads `z1-cat-face.json` and registers the second patch of a
  two-patch entry under `<key>-tail` (the file authors `rect_3x` for the eyes and
  `tail_rect_3x` for the tail on one entry).
- Offering ANY item directly to the cat now opens/keeps the cushion close-up and composites the
  matching facial key for a 2 s beat, then clears (`Level2Coordinator.showCatResponse`,
  token-guarded so overlapping offers cannot leave the tell stuck on). The mouse gets the
  eyes+tail tell; everything else the slow blink.
- No new state, no new art, no engine change: `offerItemToCat` still never executes p02 and never
  consumes the item.

### R8-005(3) — dead-tap sweep

Verified per element, not swept:

- **house-ring** — was NOT dead. It presents `cu-house-ring` and always did; build 15's "nothing
  happens" was Cluster B (no visible way out, so the user tapped the backdrop straight back out)
  compounded by a clue plate with nothing to read. Both now fixed.
- **door lock (stair-door)** — by design pre-latch: it presents the `cu-timelock` close-up and
  rattles (D8 keyless remote lock). Unchanged.
- **cat** — by design pre-p02: it presents the cushion close-up. It now also carries a visible
  reaction (above) and, post-p02, the lift affordance.
- **key hook (z4)** — genuinely dead after the key was taken. Now presents the state-resolved
  `cu-key-hook` close-up (empty hook), symmetric with sill/crate/stove/tag.
- **parts cabinet (z2)** — the toy mouse used to be auto-added on a second wide tap with no
  close-up at all. It now opens `cu-cabinet-drawer` and the mouse is a deliberate tap inside it,
  which both kills the invisible-state complaint and matches the manual-pickup principle.

### Stale-close-up sweep — two residues that ARE art-side (flagged, not fixed)

After Cluster A, every close-up resolves its state correctly. Two remaining wrong reads are
baked into the source plates and have **no authored overlay**, so they cannot be fixed in code:

1. **`cu-cat-cushion` contains the sill corner with tile XI** (top-left, roughly plate
   x[0, 235] y[0, 140] @3x). Once tile XI is collected the wide view drops it but this close-up
   still shows it — the user's R8-005(1) "part of the tablet i just picked up". Needs an
   `ov-cushion-xi-taken`-style patch (or a re-crop that excludes the sill).
2. **`cu-sill-tile` contains the cat** (bottom-right, roughly plate x[1380, 2048] y[1275, 1536]
   @3x). Post-p02 the cat is gone everywhere else but present here — R8-013(2). The analogous
   patch exists for the OTHER overlapping crop (`ov-cache-cat-gone`, for `cu-floor-cache`), so
   the precedent and the method are established; the sill twin was simply never authored.

Both are cosmetic (no progression impact) and both are Art Director / Asset-Gen work. They fold
naturally into the R8-008(3) close-up re-crop pass if that is approved. **Routing to the
Producer.**

### NEW CI GUARD — `EscapeRoomTests/Level2CloseUpStateTests.swift` (fast lane)

The binding requirement: this defect class shipped because nothing tested it. L2's WIDE views
had registration/rendered-frame guards; its close-ups had none. The new suite is deterministic
(pure model + offline UIKit image inspection — **no simulator UI automation**), so it belongs in
the fast lane per the CI-efficiency directive.

| Test | What it locks |
|---|---|
| `testEveryStatefulCloseUpCompositionChangesOnItsStateFlip` | **The core guard.** A 22-row table of (close-up, state mutation, overlay that must appear). For each, the plan must CHANGE and change in the right direction. Build 15 fails every row; the no-op ternary fails the "IDENTICAL after the state flip" assertion by construction. |
| `testCushionCloseUpRendersAllFourStatesDistinctly` | The P0 chain end to end: four distinct compositions + the right target at each step. |
| `testCollectingFromACloseUpEmptiesIt` | R8-002(1): collecting through the coordinator empties BOTH coat pockets. |
| `testCacheCloseUpsRenderPriedThenEmptied` | R8-009(2)/R8-010: pried-with-the-find → collected → empty, in the close-up. |
| `testEveryCloseUpLayerResolvesToStagedArt` | The staging half of the root cause — an authored-but-unstaged overlay fails loudly. |
| `testCloseUpLayerArtIsPixel1to1WithItsRect` | R7-001 class, close-up side: art must match its authored rect at 2048×1536 or the runtime rescales and misplaces it. |
| `testEveryCloseUpLayerActuallyPaints` | Mean-alpha check: a transparent/empty patch cannot pass as a "state change". |
| `testCloseUpLayersAndTargetsAreInBoundsAndTappable` | Every layer and every pickup target lies on the plate and is big enough to hit. |
| `testTrayDecoyIsAnOnPlateRegionAndNeverCollectible` | Cluster D: on-plate region, no socket overlap, never an inventory item. |
| `testRingClueAnnotationAppearsOnlyAfterItsWatchIsRead` | The p03 clue clarification is gated and lands inside the plate. |
| `testVaultHeaderPictogramsShip` | The near-wordless replacements actually ship. |
| `testDismissChevronClearsTheInventoryBandOnEveryDeviceClass` | **Cluster B:** pure geometry across iPad 13″/11″ and iPhone SE / 16 Pro — the chevron sits fully above the inventory band with clearance and clears the 44 pt floor. |
| `testEveryCloseUpCaseResolvesToARenderablePlate` | Every close-up case has a bundled base plate and a sane focus rect. Because all close-ups share one host, this + the chevron test cover the whole level. |

`Level2AssetStagingTests` also gained the `-cu` family (and `z1-cat-face.json`'s rects) to its
required-asset and rect-catalog assertions, and its byte-vs-manifest check was de-quadraticised
now that ~150 files ship.

### Security checklist — re-run for this batch

- **No dev-time secrets.** Re-grepped the source tree, the Xcode project and the staged bundle
  resources for the fal.ai key and any `api[_-]?key`/`secret`/`token`/`credential` pattern:
  **zero** hits. The assets added this round are PNGs copied from `specs/assets/`; the only new
  JSON is `z1-cat-face.json` (rect data). `.env` remains gitignored and is not referenced by any
  build phase.
- **Minimal entitlements/permissions.** `Info.plist` and entitlements are **unchanged by this
  batch**. No camera / microphone / location / contacts usage or usage-description strings; no
  capabilities added.

### CI (round 8)

- **FULL LANE GREEN (the handoff gate)** — run `31034965366`
  (<https://github.com/shayma16/escape-room/actions/runs/31034965366>): fast-lane 13m52s +
  full-lane-ui 48m29s. **All three UI steps passed**, including the normally-flaky
  `continue-on-error` iPad playthrough:
  - iPhone SE full playthrough + smoke + save-resume — 10 tests, 0 failures (incl.
    `testL2Z1PickupsCloseUpsAndNavigationSmoke` 53.7s and `testL2SceneContentFillsScreen`);
  - iPad full playthrough — 6 tests, 0 failures;
  - Dynamic Island safe-area — 3 tests, 0 failures.
- **Fast lane** — 190 unit/logic tests, 0 failures, on all three device runtimes, including all
  13 new `Level2CloseUpStateTests` cases.
- **Three failures were caught by CI and fixed in-batch, none chased one-iteration-at-a-time:**
  1. run `31027774811` — BUILD only: two `some View` helpers left without an explicit `return`
     after their `@ViewBuilder` attribute was dropped, plus backward-matching trailing-closure
     warnings. Both diagnosed from one log and fixed together.
  2. a self-caught visual defect before dispatching the full lane: the focus-zoomed clue plate
     needed clipping to its visible window.
  3. run `31031042901` — the **iPhone-SE UI hard gate**, which is exactly what that lane is for:
     `L2Plate` applied the close-up's identifier to its ROOT CONTAINER, which turns the container
     into a single accessibility element and masks its children, so the coat close-up opened but
     `collect-itm-tile-iv` was invisible to XCUITest. This is the documented L1
     `LevelCompleteOverlay` trap. Container identifiers are now dropped level-wide and the
     decorative plate/overlay/pointer views are `accessibilityHidden`.
  Five CI runs total for the whole batch (three fast, two full), with the duplicate
  push-triggered runs cancelled to save macOS minutes.
- The `Level2UITests` smoke test needed no changes: the accessibility identifiers it drives
  (`closeup-dismiss`, `collect-itm-tile-iv`, `collect-itm-watch-a`, `dial-socket-*`) are all
  preserved, and the dial sockets are now real queryable elements rather than `Color.clear`
  Buttons.

### Asset staging verification (user directive 2026-07-09)

Beyond the in-bundle manifest check, the staged tree was verified **byte-for-byte against the
manifest-current sources** in `specs/assets/level-2/`: all **144** staged assets hash-match their
source, there are **no orphans** (every staged PNG is manifest-current) and the script still
hard-fails if two sources would collide on one canonical name. Representative staged close-ups
and CU overlays were also opened and eyeballed across zones (`cu-cat-cushion`, `cu-sill-tile`,
`cu-door-dial`, `cu-gear-frame`, `cu-hatch-wheels`, `cu-clockrow-plates`, `cu-house-ring`,
`ov-cushion-reveal-cu`, `ov-mount-a-36-cu`) — all current, none stale.

---

## Build-16 final wiring batch — cross-view CU echoes + the gear-ring clue hotspot

Two small, self-contained changes closing the last two open items before build 16. No puzzle
logic, no difficulty and no art direction touched.

### 1. The three cross-view close-up echoes are now consumed

`cu-sill-tile` and `cu-cat-cushion` are the SAME z1 render at 4:3 relative zoom (Asset-Gen's ECC
registration: cc = 0.999507, pure similarity), so each plate's crop bakes in a corner of the
OTHER plate's element. Asset-Gen authored three deterministic ($0) patches for that
(51dc362 / 9fe0d41); this batch wires them into the resolver. Wiring only — no new art and no
re-stage (147 canonical assets, zero churn).

`Level2CloseUpVisuals.plainPlan`, `case "cu-sill-tile"` — appended AFTER the existing
`ov-sill-tile-taken` line:

```swift
if s.hasSolved(Level2Graph.PuzzleID.catMouse) { append("ov-sill-cat-gone", to: &layers) }
if Level2Engine.isWatchBUncollected(s) { append("ov-sill-cushion-lifted", to: &layers) }
```

`Level2CloseUpVisuals.catCushionPlan` — prepended at the top of the layer build:

```swift
if Level2Visuals.tileXITaken(s) { append("ov-cushion-sill-taken", to: &layers) }
```

Judgment calls worth recording:

- **Order is load-bearing on the sill plate.** `ov-sill-cushion-lifted` composites OVER
  `ov-sill-cat-gone` at the IDENTICAL rect (the JSON declares `composites_over`), mirroring
  reveal-over-empty on the cushion plate, so simply DROPPING the top patch when watch B is
  collected restores the flat-cushion corner with no seam bookkeeping. Cat-gone is therefore
  appended first. A CI assertion now pins that ordering (and pins the two rects equal).
- **The transient predicate is `Level2Engine.isWatchBUncollected`, NOT `isCushionLiftable`.**
  They are different windows: liftable = p02 solved AND NOT lifted; uncollected = p02 solved AND
  lifted AND watch B not taken. The art depicts a cushion tipped UP, which is only true in the
  second window — and it is the same predicate that gates `ov-cushion-reveal` on the cushion CU
  and in `Level2Visuals.wideOverlays(.door)`.
- **The cushion plate's sill echo is appended first** because its rect (0,0,312,240) is disjoint
  from every cushion overlay, so ordering between them is irrelevant; appending first keeps the
  "neighbour echo, then own state" reading consistent with `dormerCachePlan`.
- Watch B itself is off-plate in the sill crop (Asset-Gen verified: its top edge maps to sill
  y = 1611 vs the 1536 plate bottom), so the sill CU can never show an untappable duplicate of a
  collectable — only the tipped-up cushion. No pickup target is declared there.
- This closes the two "residues that ARE art-side (flagged, not fixed)" items recorded at the end
  of the round-8 section above, plus the third (transient) case Asset-Gen found while authoring.

**Tests.** `Level2CloseUpStateTests.stateFlips` grew from 22 to 25 rows (sill / cat-gone,
sill / cushion-lifted, cushion / tile-XI-gone), and a new
`testCrossViewEchoesTrackTheNeighbouringPlatesState` walks the full transient window —
fresh -> p02 -> lift -> collect — asserting the lift echo OPENS on the lift, composites above
cat-gone, and CLOSES again on pickup, plus the reverse direction (tile XI held *or* seated in
socket 11 both clear the sill corner). The existing art guards (staged / pixel-1:1 / actually
paints / in-bounds) pick the three new keys up automatically, because the `mid` and `late`
progression phases already reach every one of their states.

### 2. `clu-ring-chimney` is reachable — new `gear-ring` hotspot in `v-frame`

Producer-approved follow-up to the round-8 escalation recorded above (within the GATE-1
clarify-clues ruling). `cu-gear-ring` was staged and `gatingClues` mapped
`plain-cu-gear-ring -> clu-ring-chimney`, but nothing could open it.

**Where the hotspot is anchored.** The gear + ring12 brick carve was measured on the SHIPPED
`z2-frame-base` plate, not taken on trust: differencing the current wide against
`_rejects/z2-frame-base-preglyph@3x.png` isolates the carve's ink at @3x pixels
**x 2826…2875, y 1073…1122** (centroid 2850.3, 1097.6) — which matches the `l2_z2_build.py`
`GRING = (2850, 1097, 50)` anchor and, independently, the back-projected
`Level2CloseUpVisuals.ringClues["cu-gear-ring"]` centre. Normalized: **x [0.7359, 0.7487],
y [0.5589, 0.5844]** — a 35 x 35 scene-px glyph. Registration of the close-up against the wide
was also re-confirmed (staged `cu-gear-ring` vs the staged wide crop: cc = 0.9967).

**The rect** (`Level2HotspotTable`, `v-frame`):

```swift
("gear-ring", CGRect(x: 0.7350, y: 0.4620, width: 0.0700, height: 0.1340))
```

**Why it is deliberately off-centre from the glyph (the overlap-collapse judgment call).** The
carve sits INSIDE the loose-cache brick patch (`ov-brick-*` spans x [0.6711, 0.7849],
y [0.5135, 0.6578]), and every hotspot is inflated to the 182-scene-px / 44 pt hit floor. A hit
node CENTRED on the 35 px glyph would span x [0.7090, 0.7756] and therefore swallow the cache's
tap point (0.7280, 0.5857); being the smaller node it would win under smallest-area-wins and
steal the p04 pry taps — exactly the collapse the Producer asked me to check for. The rect is
therefore biased UP and RIGHT, and authored at >= 182 px in both axes so the rect IS the hit node
(no invisible inflation to reason about):

- node = x [0.7350, 0.8050], y [0.4620, 0.5960]; area 34,990 px^2 vs `brick` 131,363 px^2 and
  `gear-rack` 229,886 px^2 — so it wins on its own art;
- it still contains the WHOLE carve (2.5 px of slack past the left rim);
- its left edge clears the cache tap point by 19 scene px, and its bottom edge (0.5960) clears
  the pried recess + oil-can art (measured off `ov-brick-pried-oilcan-wide`: can x [0.699, 0.734]
  y [0.583, 0.645], cavity x [0.717, 0.762] y [0.601, 0.647]) **entirely** — after prying, no
  part of the visible cavity or can sits under the clue hotspot;
- art centre (0.7423, 0.5716) is inside the iPad dual-safe band x [0.1667, 0.8333],
  y [0.0385, 0.9615], and the hit target is 52.5 x 50.3 pt on iPhone SE.

Routing: `Level2Coordinator.lookTap` gains
`case (.frame, "gear-ring"): present(.plain(image: "cu-gear-ring"), from: hotspotID)`. The
existing `gatingClues` entry then records `clu-ring-chimney`, and the existing
`ringClues["cu-gear-ring"]` entry annotates the IX direction once watch B has been read — no
other change was needed.

**Guard coverage.**

- `Level2RegistrationTests.inspectArtRects` gained a `(.frame, "gear-ring", <carve ink bbox>)`
  row, so `testL2InspectHotspotsSitOnArtAndAreIPadReachable` now asserts the hotspot intersects
  the measured carve, that a tap at the carve's centre resolves to `gear-ring` under the real
  smallest-area-wins hit test, and that the carve is inside the iPad dual-safe band. The row uses
  the ART rect (not the hotspot rect) precisely because the hotspot is biased.
- New `testGearRingCarveOpensTheChimneyRingClueWithoutStealingTheCacheTaps`: tapping the hotspot
  presents `cu-gear-ring` AND records `clu-ring-chimney` (the direct reachability assertion for
  the escalation), and four points on the carve resolve to `gear-ring` while three cache points
  (the overlay-rect centre, the oil can, the pried recess) still resolve to `brick`.
- The pre-existing `testL2TapsAtVisibleElementPositionsHitTheirHotspots` row for `brick`, the
  `testL2HotspotsMeet44ptFloorOniPhoneSE` floor check and the hotspot-table/coordinator parity
  guard cover the new hotspot for free; all were re-verified against the new geometry.

### Asset staging verification (user directive 2026-07-09) — re-run for build 16

No art was added by this batch, but the staged tree was re-verified now that Asset-Gen's three
echo patches are in: **147 / 147 staged assets hash-match their manifest-current source in
`specs/assets/level-2/`**, zero orphans, zero shadow-marked files (`@1x/@2x/@3x`, `-b2pre`,
`-b3pre`, `-preglyph`, `_rejects`) anywhere in the staged tree, and no basename collisions. The
three new echoes were spot-checked individually
(`ov-sill-cat-gone-cu.png`, `ov-sill-cushion-lifted-cu.png`, `ov-cushion-sill-taken-cu.png`) —
each byte-identical to its `@3x` source and each pixel-1:1 with its authored CU rect
(608 x 840 / 608 x 840 / 312 x 240). `GameAssets` is a folder reference in the Xcode project, so
they ship without a project change.

### Security checklist — re-run for this batch

- **No dev-time secrets.** Re-grepped the whole source tree, the Xcode project and the staged
  bundle resources for the fal.ai key and for `api[_-]?key` / `secret` / `token` / `credential`
  patterns: **zero** hits. This batch adds Swift code and test code only — no new resources and
  no new build phases. `.env` remains gitignored and is referenced by nothing in the app target.
- **Minimal entitlements/permissions.** `Info.plist` and entitlements are **unchanged**. No
  camera / microphone / location / contacts usage, no usage-description strings, no capabilities
  beyond what the code uses.

### CI — build-16 wiring batch

- **FAST LANE GREEN**, one run for the whole batch (both tasks bundled before dispatch, per the
  CI-efficiency directive): run `31042881390`
  (<https://github.com/shayma16/escape-room/actions/runs/31042881390>), 14m04s, conclusion
  **success**; `full-lane-ui` correctly skipped on a working-branch push.
- **192 unit/logic tests, 0 failures on all three device runtimes** (iPad 13-inch class,
  smallest supported iPhone, Dynamic-Island iPhone) — up from 190, the two new test methods.
  Log excerpts:

  ```
  Unit tests - iPad 13-inch class      Executed 192 tests, with 0 failures (0 unexpected) in 48.362s
  Unit tests - smallest supported iPhone   Executed 192 tests, with 0 failures (0 unexpected) in 25.374s
  Unit tests - Dynamic Island iPhone   Executed 192 tests, with 0 failures (0 unexpected) in 57.841s

  ✓ testCrossViewEchoesTrackTheNeighbouringPlatesState
  ✓ testEveryStatefulCloseUpCompositionChangesOnItsStateFlip      (25-row table)
  ✓ testGearRingCarveOpensTheChimneyRingClueWithoutStealingTheCacheTaps
  ✓ testL2InspectHotspotsSitOnArtAndAreIPadReachable              (+ the gear-ring carve row)
  ```

- No CI iteration loop was needed: the hotspot geometry (smallest-area-wins interplay with
  `brick` / `gear-rack`, the 44 pt floor and the dual-safe band) was simulated offline against
  the exact `configureHotspots` inflation rule before pushing, so the first run was green. The
  superseded in-flight run from the preceding asset commit was cancelled to save macOS minutes.


---

## BUILD-17 TECHNICAL FIX BATCH (round-8 LATE items on build 16, GATE-1 approved 2026-08-06)

Authority: `specs/levels/level-2/build17-routed-changelist.md` + the "Round 8 — LATE ITEMS ON
BUILD 16" sections of `specs/feedback-backlog.md`. Nine user-ruled items, code + staging only —
the p06/p03 clue redesign ran in parallel as a spec-only track and nothing here touches the
puzzle graph, difficulty, or art direction.

### Per-fix status

| # | Item | Status | Where |
|---|---|---|---|
| 1a | R8-020(2) pendulum sprite + `ov-pendulum-absent` registration | **fixed** | `specs/tools/l2_b17_pendulum.py`, `RoomScene.setPendulumSwing`, `Level2Coordinator.updateDialMechanismAnimations` |
| 1b | R8-020(1) dial hands = authored sprites, anchored on the hub | **fixed** | `Level2SpriteCatalog`, `L2GreatDialControl.hand(_:angle:in:)` |
| 2 | R8-015 / Q1 cushion close-up has no PLACEMENT target | **fixed** | `catCushionPlan.uses`, `Level2Coordinator.runCloseUpUse` |
| 3 | R8-018 / Q2 cache close-up collect + systemic parity audit | **fixed (root corrected — see below)** | `L2CacheControl`, plan `uses`, parity matrix tests |
| 4 | R8-021 z4 stale close-ups + the 22-row guard's coverage gap | **fixed** | `specs/tools/l2_b17_echoes.py`, `plainPlan`, `testEveryForeignElementVisibleInACloseUpIsEchoed` |
| 5 | R8-022 key-in-socket seam box | **fixed (deterministic, no art help needed)** | `specs/tools/l2_b17_fixes.py` -> `drum_key` |
| 6 | R8-014 mouse composited outside the drawer | **fixed** | `l2_b17_fixes.py` -> `cabinet_mouse` |
| 7 | R8-017 arbor-oiled invisible | **verified rendering in BOTH views, then strengthened** | `l2_b17_fixes.py` -> `arbor`; plus a real close-up bug found (below) |
| 8 | R8-019 + R8-020 +/- chrome -> diegetic affordances | **fixed** | `TurnArc`, `crankHandleRect`, `dialCrankRect` |
| 9 | R8-016 cat tell mouse-only | **fixed (approved-design reversal, user-confirmed)** | `Level2Coordinator.useItem`, `L2CatCushionView.tellLayers`, `testOnlyTheTinMouseGetsAVisibleCatReaction` |

### 1. R8-020 — the z3 mechanism (user ruling: authored sprites, not procedural)

**The pendulum's root cause was measured, not assumed.** The routed changelist was right that
`ov-pendulum-absent` *was* being invoked, and right to suspect a stale rect. Measuring the
CURRENT `z3-dial-base@3x` against the batch-4 rig showed the rig itself had drifted from the
plate: `sp-pendulum` / `ov-pendulum-absent` were authored for rect `(2030, 70, 2280, 1330)` with
a mask whose rod leans LEFT and whose bob ellipse is `2048..2192 x 1005..1305`, while the plate's
pendulum hangs VERTICAL at x~2178..2199 with a bob centred (2197, 1169), semi-axes ~ (100, 170),
plus a finial down to y~1400. The old rect therefore clipped the bob's **right crescent and its
finial** — precisely the sliver that survived to the RIGHT of the animated one in the user's
screenshot. Same family as the L1 R7-001 stale rect.

Rebuild (`l2_b17_pendulum.py`, deterministic, $0):
- silhouette re-measured against the current plate and verified with a mask overlay sheet;
- `sp-pendulum@3x.png` re-cut as an RGBA cutout over the FULL silhouette (cord + rod + bob +
  finial), rect `(2050, 0, 2334, 1440)`, pivot `(2186, 8)` (the suspension point, at the top);
- `ov-pendulum-absent-wide@3x.png` rebuilt as a **silhouette-only** fill: every pixel outside
  the feathered silhouette is bit-identical to the plate, so the patch cannot show a
  rectangular seam — the flat grey column the old dark-median clone produced is gone;
- rect/pivot/amplitudes re-registered into `z3-state-overlays.json` + `clockwork-sprites.json`.

**Judgment call (flagged): the hole fill.** `cv2.inpaint` (Telea and NS, several radii) all
dragged the bright dial FACE that abuts the hole on the left across the ~240 px bob span and
broke the dial's rim arc — visibly worse than the wall it is meant to reveal. The shipped fill
is a row-wise interpolation weighted `(1-t)^3` toward the WALL-side neighbour, then blurred: the
rim arc reads continuous and the fill settles onto the wall tone. A soft, slightly flat band
remains where the bob rested; it reads as an out-of-focus recess and is mostly covered by the
moving bob. If the Art Director wants it painted properly that is a separate art task — the
registration defect is fixed either way.

**Hands.** `hand-hour` / `hand-minute` (authored spade + plain silhouettes) now render at CU
scale, rotated about their authored pivots, with the pivot placed on the **works hub**. Build 16
rotated SwiftUI capsules about `plate.midX/midY`; the hub is at CU (751, 698) ~ normalized
(0.367, 0.454), i.e. **nowhere near the plate centre on this crop** — that is the whole
mis-anchor. Contracts honoured explicitly and pinned by tests:
- **D1 mirror** — a FRONT angle theta renders at -theta; no time is baked into the plate.
- **R4-007 sprite/view rotation** — the hand art is authored UPRIGHT with no pre-rotation, so
  the view rotation applies the angle exactly ONCE (the L1 trap was a pre-rotated sprite plus a
  view rotation double-applying it).

**Judgment call (flagged): elliptical sweep.** The painted numeral ring is an ellipse (semi-axes
464.4 x 530.6 at @3x — the dial is seen slightly off-axis), so a rigid circular sweep drifts off
the numerals. The hands are squashed horizontally by the ring's own axis ratio (0.875) about the
pivot. Derived from authored metadata, not invented, but it is a presentation choice: a full
homography (the hub does not project to the ring's centre) was judged out of proportion to the
benefit. Flagged for the Art Director's eye at QA.

**Metadata, not constants.** All of it is read at runtime from the staged `hand-sprites.json` +
`clockwork-sprites.json` via the new `Level2SpriteCatalog`, because hand-transcribing rects into
Swift is exactly how build 16's geometry drifted. `hand-sprites.json` gained a structured
`great-dial` block (hub, ring ellipse, CU frame) promoted from prose in the old `render_rule`
and from `l2_z3_build.py`'s `HUB_XY` / `CU_FRAMES`.

### 2-3. Cluster Q — close-up <-> wide interaction parity (systemic, not spot fixes)

**Q1 (R8-015) confirmed exactly as routed.** `L2CatCushionView` hard-coded
`useItem(armed, on: "cat-cushion")` while p02's placement verb lives on the sibling hotspot
`cat-floor`, so from the close-up the armed mouse could only ever produce the tell.

**Q2 (R8-018) — the routed root cause is INACCURATE; flagging it.** The changelist states the
cache close-ups have "no collect target for the revealed item". They do: `chimneyCachePlan`
emits `collect-itm-oilcan` on `oilcanRect`, `L2CacheControl` passes `onTarget:`, and the rect
was verified (by compositing) to sit squarely on the painted oil can. The real Q2 defect is
visible in the same line the changelist quotes: `onPlateTap` was guarded to
`armedItem == screwdriver`, so the cache close-ups implemented **one verb and one item** and any
other armed use was silently dead. (The user's report is retrospective and most plausibly
predates build 16's collect targets.) Recorded here so the Documentation Agent does not
reconcile the walkthrough against a root cause that was not the one fixed.

**The systemic fix.** A close-up no longer hard-codes hotspot ids or item ids. Its `Plan` now
declares `UseTarget`s — on-plate regions that proxy a WIDE hotspot — and
`Level2Coordinator.runCloseUpUse` dispatches them through the **same `useItem` switch a wide tap
uses**. Regions only hit-test while an item is armed, so unarmed taps keep their old behaviour.

Full audit result (every armed verb + every collect target in the level):

| Verb | Wide | Close-up before | Close-up now |
|---|---|---|---|
| p03 pry dormer board (screwdriver) | yes `floor-cache` | yes (screwdriver only) | yes `use-floor-cache` |
| p04 pry chimney brick (screwdriver) | yes `brick` | yes (screwdriver only) | yes `use-brick` |
| p05 oil the arbor (oil can) | yes `arbor` / `gear-frame` | **NO — the interactive gear-frame CU had no plate tap at all** | yes `use-arbor` |
| p02 PLACE the mouse | yes `cat-floor` | **NO — structurally unreachable** | yes `use-cat-floor` |
| p02 OFFER to the cat | yes `cat-cushion` | yes | yes `use-cat-cushion` |
| p08 oil the drum | **NO — dead in the wide** | yes | yes `use-drum` (+ wide now works) |
| p08 wind the drum | **NO — dead in the wide** | yes | yes `use-drum` (+ wide now works) |
| collect great wheel / oil can / mouse / watch A / tile IV / watch B | wide tap opens the CU | yes | yes (unchanged, now guarded) |

Two gaps beyond the two reported: **p08's drum verbs were close-up-only** (the mirror image of
R8-018 — an armed oil can or key tapped on the drum in the wide scene did nothing), and
**p05's oiling was dead on the interactive gear-frame close-up**.

**Related bug found while auditing (fixed).** The `arbor` hotspot presented
`.plain(image: "cu-gear-frame")` — the same plate as `.gearFrame`, but routed through
`plainPlan`, which had **no case for it**. That close-up therefore composited nothing: the oiled
bearing and every mounted gear were invisible on the very close-up the walkthrough sends you to
for p05. This is a second, independent contributor to R8-017's "it looks identical". One plate
now means one close-up: `arbor` presents `.gearFrame`.

The wide `cat-floor` / `cat-cushion` non-mouse branches previously returned `true` (consuming
the tap for a refusal); with R8-016 they return `false` and are inert.

### 4. R8-021 — z4 stale close-ups, and WHY THE 22-ROW GUARD MISSED THEM

The resolver *did* have cases for `cu-key-hook` / `cu-tag-nail`, the `-cu` art *was* staged, and
the guard *did* have rows for both. All three routed suspicions were false.

The actual defect: **`cu-tag-nail` depicts the winding KEY as well as the tag, and `cu-key-hook`
depicts the TAG as well as the key** (both are crops of the same vault wall). The resolver
composited only each plate's OWN element, so after collecting both pickups either close-up still
showed the other item — the "stale key" the user reported.

**Why the guard missed it: every row in the table paired a close-up with its own element.**
Nothing tested a close-up against a NEIGHBOUR's state. The two z1 echoes that already existed
(`ov-cache-cat-gone`, and the build-16 sill/cushion pair) were added ad hoc after user reports,
never derived from a rule — so the rule's blind spot survived.

Closed two ways:
1. **Data.** 11 cross-element echo patches generated deterministically by
   `specs/tools/l2_b17_echoes.py`. Every CU plate is a crop of its wide plate (verified: crop +
   LANCZOS of the wide reproduces each shipped CU plate to mean |delta| <= 0.2/255), so each
   patch is the approved wide state art re-cropped through the host's own camera frame —
   registered by construction, no ECC, no hand-placed rects, no generation. Alternative states
   of one element (pried/empty) share one rect so they stay interchangeable.
2. **Guard.** `testEveryForeignElementVisibleInACloseUpIsEchoed` derives the whole matrix from
   `Level2CloseUpVisuals.cuFrames` x each view's wide overlays: if a foreign overlay covers >=1%
   of a close-up's frame, that close-up's plan MUST change when the state flips, or the pair
   must appear in `echoExempt` **with a reason**. `testEchoExemptionsAllStillApply` stops the
   exemption list rotting into a silencer. 12 rows were also added to the hand-maintained
   state-flip table (22 -> 34) so a failure names the specific plate.

Echoes shipped: `ov-keyhook-tag-taken`, `ov-tagnail-key-taken` (the reported pair);
`ov-masterface-door-open`, `ov-crate-door-open` (the workroom door p01 opens, visible in both z1
master close-ups); `ov-housering-bar-raised` (the time-lock bar in the house-ring clue crop);
`ov-gearring-brick-pried` / `-empty` (the chimney cache in the gear-ring clue crop);
`ov-gearframe-panel-open` (the z3 wall panel behind the gear frame);
`ov-cushion-cache-pried` / `-empty` (the floor cache under the cat's bench);
`ov-cache-cushion-lifted` (the transient watch-B lift window, seen from the floor-cache crop).

**Judgment calls (exemptions, each recorded in code with its reason):** `cu-door-dial` <-
workroom door (unreachable — a solved dial navigates into z2 instead of presenting the
close-up); `cu-hatch-wheels` <- hatch open (same shape of unreachability);
`cu-clockrow-plates` <- cabinet (the plan's focus zoom crops the cabinet out of the visible
window); and four rect-padding-only overlaps whose changed pixels measure < 0.3% of the plate.

### 5-7. Deterministic overlay repairs (`specs/tools/l2_b17_fixes.py`)

- **R8-022 key seam.** The batch-4 NB edit darkened/desaturated the *whole* crop, not just the
  key, which is what made the patch rectangle visible. Rebuilt as base-crop + **key silhouette
  only**. A colour/luminance key is not usable here (the key's shadow side is darker than the
  rusty collar behind it, so any threshold either drops half the bow or swallows the collar), so
  the silhouette is a small authored geometry set — ring annulus + shaft + boss — measured on
  the NB art and resampled for the wide variant (the two crops differ by a uniform 0.5785x).
  **No art help needed; not escalated.**
- **R8-014 drawer mouse.** Rebuilt from the approved `ov-cabinet-empty` art (same rect, drawer
  open, no mouse) plus the mouse cutout re-seated on the drawer floor at 30% of the patch width,
  with a soft contact shadow. Idempotent: the cut is always taken from the archived original in
  `_rejects/`, so re-running cannot shrink the mouse again. **Ownership answered: this was
  overlay content, not a plate offset — Developer-owned, per the changelist's open question 4.**
- **R8-017 arbor.** First verified the claim: `ov-arbor-oiled` **does** composite in both the
  wide and the close-up path; the delta was simply mean |delta| ~ 2.7/255 — invisible at play
  scale. Strengthened to ~7.8 (rust -> clean iron at 0.80 strength, plus a specular sheen and a
  wet ring on the boss), with a pure-base ring so the rect edge cannot read as a box. An
  intermediate pass at ~21 was rejected as blown-out/CG. Note the *other* half of this item was
  the invisible-plan bug in section 2-3 — the close-up the player was looking at resolved no
  layers at all.

### 8. Diegetic affordances (R8-019 + the R8-020 +/- sub-item)

The `arrow.triangle.2.circlepath` crank button and the flat white `plus.circle.fill` /
`minus.circle.fill` dial buttons are gone. Both affordances are now anchored ON the painted art
— the crank arm in `cu-gear-frame`, the setting crank in `cu-great-dial` — with a `TurnArc` mark
(a three-quarter arc + arrowhead in the scene's bone-white at low opacity, the same wordless
grammar as the existing dashed empty-post seat rings). Accessibility identifiers (`gear-crank`,
`dial-crank-plus`, `dial-crank-minus`) and labels are unchanged so the UI tests and VoiceOver
keep working. **Scope note:** the global-UI SF-Symbols-only rule is untouched — that rule governs
the menu chrome layer; these are in-room game affordances, like the seat rings and the tray
selection ring already shipping.

### 9. R8-016 — the cat tell is mouse-exclusive

Implemented as the user confirmed at GATE 1, overriding approved rev-1.3 playtest tweak 2. A
non-mouse offer is now fully inert: `useItem` returns `false` before any response is set, so
there is no `catResponse` beat, no close-up presented, no reaction layer and no sound — and, as
before, the item is never consumed and p02 is never executed. `ov-cat-slow-blink` is no longer
composited; it stays staged (and asset-guarded) rather than being deleted, so reverting is a
one-line change if the "cat feels unresponsive" tradeoff the changelist warned about lands
badly. `Level2Engine.offerItemToCat` still returns `.refusal` for non-mouse items — that is the
engine's *classification*, and the discrimination test still asserts it; only the presentation
changed. `testOnlyTheTinMouseGetsAVisibleCatReaction` replaces the old expectation.

### Guard coverage added this batch

| Guard | What it would have caught |
|---|---|
| `testEveryForeignElementVisibleInACloseUpIsEchoed` | R8-021 and every future cross-element stale close-up, derived from plate geometry rather than memory |
| `testEchoExemptionsAllStillApply` | an exemption outliving the pair it excuses |
| state-flip table: +12 rows (22 -> 34) | each new echo, named individually |
| `testEveryArmedVerbWorksFromBothTheWideViewAndItsCloseUp` | R8-015, R8-018, the p05 gear-frame gap and the p08 wide-side gap — the parity matrix QA asked for |
| `testEveryCloseUpUseRegionProxiesARealWideHotspot` | a close-up proxying a hotspot that does not exist in its view |
| `testEveryRevealedItemIsCollectableFromItsCloseUpReachedFromTheWideScene` | the collect half of parity: the wide tap opens the CU **and** the CU's target grants the item |
| `testPendulumAbsentPatchAndSpriteShareOneRect` | the exact R8-020(2) double pendulum (patch rect != sprite rect) |
| `testPendulumSpriteShipsAndHangsFromItsAuthoredPivot` | an unstaged/rescaled cutout, or a pivot that is not a suspension point |
| `testGreatDialHandsUseAuthoredSpritesAnchoredOnTheHub` | R8-020(1): placeholder strokes, a tail-less pivot, or a hub assumed to be the plate centre |
| `testMirroredDialAngleContract` | a D1 mirror regression on the 7:20 release time |
| `testDiegeticCrankRegionsSitOnThePlateAndClearTheHitFloor` | an affordance region off its art or below the hit floor; PLACE/OFFER regions colliding |
| `testClockworkSpriteRigsShipAndLoad` | the sprite rigs silently not shipping (the runtime would fall back to defaults) |
| `testOnlyTheTinMouseGetsAVisibleCatReaction` | a regression back to reacting to every item |
| asset-staging required list: +13 names | any of the new sprites/echoes silently not shipping |

All are deterministic (pure model + geometry, no simulator UI automation), so they run in the
**fast lane** per the CI-efficiency directive.

### Asset staging verification (user directive 2026-07-09)

Re-staged after every art change: **160 canonical assets** (was 147) — +11 cross-element echo
`-cu` crops, +`hand-minute`, +`sp-pendulum` — plus the two sprite-rig JSONs. All 160 hash-match
their manifest-current source in `specs/assets/level-2/`; zero shadow-marked files
(`@1x/@2x/@3x`, `-b2pre`, `-b3pre`, `-b4pre`, `-b16pre`, `-preglyph`, `_rejects`) anywhere in the
staged tree; zero basename collisions. Every superseded original was archived to
`specs/assets/level-2/_rejects/*-b16pre@3x.png` rather than overwritten, so the pre-build-17 art
is recoverable and can never be re-staged (the staging script skips `_rejects/` and shadow
markers, and `Level2AssetStagingTests` fails loudly on either).

Representative staged close-ups were spot-checked against their sources by compositing them onto
their plates at their authored rects and inspecting the render: `cu-key-hook` + `ov-key-taken`,
`cu-tag-nail` + `ov-tag-taken` + `ov-tagnail-key-taken`, `cu-winding-drum` + `ov-drum-key-in`,
`cu-cabinet-drawer` + `ov-cabinet-open-mouse`, `cu-gear-frame` + `ov-arbor-oiled`,
`cu-brick-cache` + `ov-brick-pried-oilcan`, and the z3 wide + `ov-pendulum-absent` + the swung
sprite at +/-11 degrees.

### Security checklist (run before this QA handoff)

- **No dev-time secrets in the shipped app.** Re-grepped the whole source tree, the Xcode
  project, the tools and the staged bundle resources for the fal.ai key and for
  `api[_-]?key` / `secret` / `token` / `credential` patterns: **zero** hits in anything that
  ships. This batch adds Swift code, tests, PNG/JSON game assets and offline Python tools; no
  new build phases, no network code. `.env` remains gitignored and is referenced by nothing in
  the app target.
- **Minimal entitlements/permissions.** `Info.plist` and entitlements are **unchanged** by this
  batch. No camera / microphone / location / contacts usage, no `NS*UsageDescription` strings,
  no capabilities beyond what the code demonstrably uses.

### Spec ambiguities / corrections to flag to the Producer

1. **The routed Q2 root cause is wrong** (section 2-3): the cache close-ups DO have collect
   targets. The real defect was the single-item plate-tap guard. Fixed either way, but the
   walkthrough reconciliation should not be written against the routed wording.
2. **The routed R8-021 root cause is wrong on all three counts** (section 4): the resolver
   cases, the `-cu` staging and the guard rows all existed. The defect was cross-element, not
   own-element, and the guard's blind spot was structural.
3. **Two parity gaps beyond the two reported** were found and fixed (p05 oil on the interactive
   gear-frame close-up; p08's drum verbs dead in the wide view). QA's parity matrix should cover
   both.
4. **`cu-gear-frame` was reachable through two different close-ups**, one of which resolved no
   state at all. Collapsed to one. A real, previously unreported contributor to R8-017.
5. **Presentation judgment calls** an Art Director may want to review at QA: the pendulum hole
   fill (a soft band where the bob rested), and the 0.875 horizontal squash applied to the dial
   hands so they track the painted numeral ellipse.

### CI — build-17 fix batch

Per the CI-efficiency directive the whole nine-item batch (art regeneration, staging, code and
tests) was bundled into ONE push before dispatching a run — no tweak/wait/fail loop.

- **FAST LANE GREEN on the first run:** `31198731186` / push run
  **`31198731368`** (<https://github.com/shayma16/escape-room/actions/runs/31198731368>),
  conclusion **success**, `full-lane-ui` correctly skipped on a working-branch push. (The
  duplicate `workflow_dispatch` run started alongside the push run was cancelled immediately to
  save macOS minutes.)
- **204 unit/logic tests, 0 failures on all three device runtimes** (up from 192 — the 12 new
  guards). Log excerpts:

  ```
  Unit tests - iPad 13-inch class          Executed 204 tests, with 0 failures (0 unexpected) in 30.838s
  Unit tests - smallest supported iPhone   Executed 204 tests, with 0 failures (0 unexpected) in 21.477s
  Unit tests - Dynamic Island iPhone       Executed 204 tests, with 0 failures (0 unexpected) in 36.612s

  ✓ testEveryArmedVerbWorksFromBothTheWideViewAndItsCloseUp   (parity matrix)
  ✓ testEveryForeignElementVisibleInACloseUpIsEchoed          (the R8-021 coverage guard)
  ✓ testGreatDialHandsUseAuthoredSpritesAnchoredOnTheHub
  ✓ testPendulumAbsentPatchAndSpriteShareOneRect
  ✓ testOnlyTheTinMouseGetsAVisibleCatReaction
  ```

- **FULL LANE GREEN (the one pre-handoff gate):** run **`31200057793`**
  (<https://github.com/shayma16/escape-room/actions/runs/31200057793>), conclusion **success** —
  BOTH jobs green, including the usually-flaky non-blocking iPad playthrough:

  ```
  fast-lane      Unit tests - iPad 13-inch class          Executed 204 tests, 0 failures
  fast-lane      Unit tests - smallest supported iPhone   Executed 204 tests, 0 failures
  fast-lane      Unit tests - Dynamic Island iPhone       Executed 204 tests, 0 failures
  full-lane-ui   UI - smallest supported iPhone (full playthrough + smoke + save-resume)
                                                          Executed  10 tests, 0 failures  (1056s)
  full-lane-ui   UI - iPad (full playthrough + smoke + save-resume) [non-blocking]
                                                          Executed   6 tests, 0 failures  ( 814s)
  full-lane-ui   UI - Dynamic Island iPhone (safe-area screenshots)
                                                          Executed   3 tests, 0 failures  (  99s)
  ```

  Note this is CI's own automation, not a game-flow certification: the level's correctness is
  QA's call, and per the standing rule state/inventory/collect behaviour must be verified from
  RENDERED SCREENSHOTS, not engine flags.
- No CI iteration loop was needed. Every geometric decision (pendulum silhouette and rect, key
  silhouette, mouse seat, hub projection, echo rects, the parity matrix and the echo-coverage
  matrix) was computed and visually verified offline against the shipped plates before the push,
  so the first macOS run was green.

---

## REV 1.4.1 FINAL WIRING BATCH → BUILD 17 (teach-at-dormer + D13 live tally)

Authority: `specs/levels/level-2/puzzle-graph.json` **rev 1.4.1** (developer_notes **D5**, **D12**,
**D13**), `specs/assets/level-2/ring-clue-wide-geometry.json`,
`specs/assets/level-2/z2/v-frame/sprites/tally-sprites.json`, `z1/z1-state-overlays.json`.
Code + tests only — the rev-1.4.1 clue art was already authored, staged and committed (166
canonical assets). **No puzzle logic, no solution value, no gate, no hotspot and no overlay id
changed in this batch**; everything below is presentation rendered off state that already existed.

### Per-item status

| # | Wired item | Status | Where |
|---|---|---|---|
| 1 | Resolver conditions for `ov-cache-marked` (wide + CU) and `ov-cushion-cache-marked` (cushion echo) | **done** | `Level2Engine.isDormerCacheNoteVisible`, `Level2Visuals.wideOverlays(.door,_)`, `Level2CloseUpVisuals.dormerCachePlan` / `catCushionPlan`, `Level2Coordinator.allOverlayNames(.door)` |
| 2 | The two WIDE ring-hand entries (z1 3-o'clock x1.35; z2 9-notch x2.75) | **done** | `Level2CloseUpVisuals.ringClues` (+ `wideRingClue`, `ringHandLayout`), `RoomScene.setRingHand`, `Level2Coordinator.updateRingHand` |
| 3 | D13 live tally block (accumulated-rotation accrual, fives + strike, ONE constant-height partial, clearing rules, transient) | **done** | new `Game/Level2Tally.swift` (`Level2Tally` + `L2TallyAccrual`), `Level2Coordinator` tally section, `L2GearFrameControl.liveTally` |
| 4 | `cu-gear-ring` pointer multiplier 1.0 -> **1.5** (one number) | **done** | `Level2CloseUpVisuals.ringClues["cu-gear-ring"].pointerMultiplier` |
| 5a | COMMUTATIVE acceptance test (36/64 either order computes 24:1 **and** is accepted) | **done** | `Level2TallyTests.testSolutionPairComputes24AndIsAcceptedInEitherPostOrder` (+ the pre-existing `Level2Tests.testGearTrainBothArrangementsSolve`) |
| 5b | Tally cycle-stability test (the D13 anti-oscillation contract) | **done** | `Level2TallyTests.testTallyIsCycleStableAcrossManyCyclesForEveryPair` — 21 pairs x 6 cycles, irregular accrual steps |
| 5c | Luminance (RF-7a) | **no action** — art-side verified (`asset-progress.md`: wide 3.54:1 / CU 3.57:1 / cushion echo 3.34:1 minima) | — |
| 6 | Tests: state-flip rows, ordering, tally units, registration/containment | **done** | see the test inventory below |

### 1. The chalk note: ONE predicate, three frames

`Level2Engine.isDormerCacheNoteVisible(_:) == hasViewedClue(clu-watch-a) && !hasSolved(p03)`.
All three frames that depict the board read that single predicate — the z1 WIDE
(`ov-cache-marked`), `cu-floor-cache` (the same key's CU rect) and `cu-cat-cushion`
(`ov-cushion-cache-marked`, the crop echo) — so wide and close-up **cannot** disagree about the
mark's presence, and the totally ordered set `unmarked -> marked -> pried-with-wheel -> empty`
holds by construction: the note is gone the instant the board is pried and can never return on an
empty cavity. The mark is emitted BEFORE the pried/empty pair it shares a rect with, so the
authored order also holds in the layer list, not only in the predicate.

**RC-6** (`ov-cache-marked` x `ov-cache-cat-gone`): both composite together in `cu-floor-cache`
and their CU rects are disjoint (cat corner `1499..2048 x 0..555` vs board `1080..2048 x
1150..1536`), so the order between them is free — asserted, not assumed, by
`testChalkNoteAndCatGoneAreIndependentAndRectDisjoint`, which fails if a future re-cut makes them
overlap.

### 2. + 4. Ring hands: one composite, four rects

`ringClues` is now keyed by **plate** — the two close-ups plus the two WIDE base plates — and the
composite maths lives in ONE function, `Level2CloseUpVisuals.ringHandLayout`, used by both the
SwiftUI close-up path and the new SpriteKit wide path (`RoomScene.setRingHand`). It reproduces the
shipped close-up composite exactly (sprite aspect-fit into `0.34L x 1.32L`, art centre `0.31L`
along the pointer, rotated about the hub), i.e. the maths Asset-Gen rendered its C1/C3 proof
against, so wide and close-up are the same mark at different scale. The wide hand is a plain
sprite node: it adds no hotspot and is invisible to hit testing (only `hotspot:`-named nodes are
considered), which `testWideRingHandIsGatedAndNeverStealsATap` pins.

The approved tweak is literally one number: `cu-gear-ring`'s `pointerMultiplier` 1.0 -> 1.5, which
takes the tip from inside the carved gear glyph to out past the notch circle
(`testGearRingPointerClearsItsCarvedGlyph` asserts `pointerLength > radius` and that the tip stays
on the plate). The house-ring close-up is untouched at x1.0.

### 3. D13 live crank tally

`Level2Tally` is a pure, notation-driven model; `L2TallyAccrual` is the transient accrual state,
held by `Level2Coordinator` and by nothing else.

- **Accrual is accumulated crank rotation**, never index-mark crossings: one cam cycle consumes
  exactly `R = A*B/96` revolutions (the D5 train `(A/12) x (B/8)`), so the end-of-cycle picture is
  a pure function of the mounted pair and cannot oscillate. The completed block is computed in
  **exact integer arithmetic** (`product / 96`, `product % 96 != 0`) and the accrued path is
  asserted to land on the identical block for all 21 pairs.
- **Notation is read from the staged `tally-sprites.json`** (slot pitch 14, group gap 16, row
  pitch 56, capacity 20/row, 3 rows, `x0` 702, baselines 664/720/776, rule 604, block rect) —
  never hand-transcribed. Fives are four uprights closed by the `sp-tally-strike` diagonal that
  spans exactly those four.
- **The partial** is `sp-tally-partial` drawn in the SAME 4x38 box as a full stroke: the shortened
  top is baked into the sprite, so no runtime height is ever derived from the residue (V17-W1).
  6 2/3 (far from 24) and 26 2/3 (near) render identically in form.
- **No branch on the count anywhere** — 24 is drawn exactly like 23 and 25 (RF-7c). Success stays
  with the latch/panel.
- **Separation is position-only** (RF-7b): the first live baseline is 60 CU px below the crib's
  rule, and every mark of every reachable block sits inside the authored block rect (checked for
  6+partial, 26+partial and the 48-stroke worst case).
- **Clearing**: (i) any mount/unmount at either post -> cleared immediately (`mountGear` /
  `unmountGear`), (ii) fewer than two gears -> nothing drawn (`Level2Engine.canCrank` + a
  view-side guard), (iii) scene reload / save load -> a fresh coordinator starts empty (the block
  lives nowhere in `LevelSaveData`), (iv) the next crank press redraws from zero.
- **RC-4 skippable**: a second crank press, or a tap anywhere on the frame plate, fast-forwards to
  the finished block; the final block is fully readable statically. Accrual duration is a fixed
  1.6 s regardless of the count, so the timing leaks nothing either.

### Judgment calls flagged (rev-1.4.1 batch)

1. **Where the ONE partial sits when the next mark would be a group's closing diagonal.** V17 says
   the partial is upright, never diagonal, never grouped into a five and never struck, so it
   cannot occupy a group's fifth position. Rule implemented: the partial takes the next UPRIGHT
   slot; if four uprights are already standing it steps to the first upright of the NEXT group,
   where it can never be closed. **None of the three shipped non-integer pairs lands there**
   (6, 10 and 26 full strokes leave 1, 0 and 1 uprights standing), so this rule only ever governs
   frames of the accrual animation — but it is deterministic and unit-tested rather than
   accidental.
2. **The live block renders in `cu-gear-frame` only, not in the wide.** D13 says "renders in
   cu-gear-frame and in the wide **if the crank is operable there**". It is not: a wide tap on the
   frame/arbor opens the close-up, and the crank verb exists only inside it. The wide row
   baselines in `tally-sprites.json` are therefore unused for now (they are correct if the crank
   ever becomes a wide verb). Flagged so the walkthrough describes counting in the close-up.
3. **The engine outcome is applied on the press, then the tally accrues as animation.** The cam
   clack/latch (and, on the solution, the panel opening + close-up dismissal) happen immediately;
   the block fills over 1.6 s and stays. The alternative — deferring the solve to the end of the
   accrual — would have made a 1.6 s animation load-bearing for progression, which is worse for
   both QA and accessibility. The counting route is unaffected: the number is readable statically
   after the press.
4. **A rejected mount also clears the block.** D13(i) says "any mount or unmount"; a mount the
   engine refuses cannot change the configuration, but clearing anyway is strictly safer than
   risking a count that belongs to a different configuration.
5. **`Level2Engine.canCrank`** is new but derives only from existing state (zone, arbor flag, the
   two post fields, p06 solved). It introduces no state and no gate; it exists so "the crank
   actually turns" is stated once and shared by the tally and the tests.

### Test coverage added (all fast-lane, deterministic, no simulator UI)

- `Level2TallyTests` (new): notation loaded from the authored metadata; sprite/draw-box
  proportionality; **commutative 24:1 acceptance**; exactly-three-non-integer-pairs; worst case 48
  fits three rows; fives closed by a non-overshooting diagonal; the partial's full V17 contract;
  far/near partial identity; nothing special at 24; rule clearance + block-rect containment;
  **cycle stability across 21 pairs x 6 cycles**; monotonic accrual + RC-4 skip parity; clearing
  on mount/unmount and on fewer than two gears; no tally with a seized arbor; never-saved /
  re-derives-empty-on-load; never varies with any clue flag.
- `Level2CloseUpStateTests`: +2 state-flip rows (`ov-cache-marked`, `ov-cushion-cache-marked`),
  +4 tests (gate -> marked -> pried -> empty across all three frames; same-rect mutual exclusion
  across every board phase; RC-6 independence + rect disjointness; the note sits on the tappable
  board), +1 reachable phase ("dormer board marked, unpried") so the art-integrity guards (staged
  art, pixel-1:1, visible ink, in-bounds) now cover the new overlays, + the gear-ring
  pointer-multiplier test. The systemic echo-coverage guard automatically extends to the new wide
  overlay.
- `Level2RegistrationTests`: `ov-cache-marked` added to the required-wide-overlay set (rect
  sanity + pixel-1:1 + hotspot registration), +3 ring-hand tests (measured geometry vs the
  geometry JSON to 1e-6 / 0.15 px; hub-anchor + tip containment via the shipped composite
  function; gated appearance with no new hotspot and no tap theft).
- `Level2AssetStagingTests`: the three rev-1.4.1 overlays + three tally sprites are now required
  canonical assets; `ov-cache-marked` / `ov-cushion-cache-marked` CU rects and `ov-cache-marked`'s
  wide rect must resolve; new `testTallySpriteRigShipsAndLoads`.

### Asset staging verification (user directive 2026-07-09)

No new staging was needed, but the bundle was re-verified rather than assumed: all **166** entries
of `staged-manifest.json` were hashed and compared **both** against the manifest sha **and against
their `specs/assets/level-2/...` source files** — 166/166 byte-identical, zero basename
collisions, zero staged files outside the manifest, zero manifest-current assets missing. That
includes the plates the rev-1.4.1 art batch regenerated (`z2-frame-base`, `cu-gear-frame` with the
F3 crib, `cu-slate`, the cache-note overlays), so no stale close-up can be shadowing a fresh wide
in this build. The in-CI shadow guard (`testStagedBytesMatchManifest_noStaleShadow` +
`testNoShadowMarkersInStagedTree` + `testNoBasenameCollisionsInLevel2`) still fails loudly on any
regression.

### Security checklist (re-run for this batch)

- **No development-time secrets.** Grepped the whole app source tree, the Xcode project and the
  bundled resource set for `fal.ai` / `api key` / `secret` / `token=` / `bearer` / `password`
  patterns: the only hits are prose attribution in About/Credits and code comments (plus the
  unrelated identifier `catResponseToken`). **Zero keys, tokens or credentials** anywhere in the
  app, the project file or the bundle. `.env` is gitignored, untracked, and not referenced by any
  build phase; `EscapeRoom/Resources` contains only PNG/JPEG/JSON/WAV art, rig and audio files
  (356 tracked files, no stray config).
- **Minimal entitlements/permissions.** `Info.plist` still declares only bundle identity,
  landscape-locked orientation, launch screen, status-bar and `ITSAppUsesNonExemptEncryption
  = false`. **No `*UsageDescription` keys** (no camera / microphone / location / contacts), no
  `.entitlements` file, no `CODE_SIGN_ENTITLEMENTS` setting and no capabilities — unchanged by
  this batch, which adds no OS-facing API beyond SpriteKit/SwiftUI drawing and a `Timer`.

### CI — rev-1.4.1 wiring batch (build 17)

Per the CI-efficiency directive the whole batch (resolver conditions, wide ring hands, the D13
tally, the multiplier tweak and all tests) was bundled into ONE push before any run was
dispatched. No tweak/wait/fail loop: both lanes were green on the first attempt.

- **FAST LANE GREEN, first run** — push run **`31255254769`**
  (<https://github.com/shayma16/escape-room/actions/runs/31255254769>), conclusion **success**,
  `full-lane-ui` correctly skipped on a working-branch push. **229 unit/logic tests, 0 failures**
  on all three device runtimes (up from 204 — the 25 new guards):

  ```
  Unit tests - iPad 13-inch class          Executed 229 tests, with 0 failures (0 unexpected) in 17.068s
  Unit tests - smallest supported iPhone   Executed 229 tests, with 0 failures (0 unexpected) in 43.366s
  Unit tests - Dynamic Island iPhone       Executed 229 tests, with 0 failures (0 unexpected) in 24.292s

  ✓ testChalkNoteAppearsOnTheGateAndIsSuppressedTheMomentTheBoardIsPried
  ✓ testChalkNoteIsCompositedBeforeTheStateItSharesARectWith
  ✓ testChalkNoteAndCatGoneAreIndependentAndRectDisjoint          (RC-6)
  ✓ testChalkNoteSitsOnTheTappableBoard
  ✓ testWideRingHandEntriesMatchTheMeasuredGeometry               (C1 + C3)
  ✓ testRingHandCompositeIsAnchoredOnTheHubAndStaysOnThePlate
  ✓ testWideRingHandIsGatedAndNeverStealsATap
  ✓ testGearRingPointerClearsItsCarvedGlyph                       (the x1.5 tweak)
  ✓ testSolutionPairComputes24AndIsAcceptedInEitherPostOrder      (QA flag a — commutativity)
  ✓ testTallyIsCycleStableAcrossManyCyclesForEveryPair            (QA flag b — anti-oscillation)
  ✓ testExactlyTheThreeNonIntegerPairsDrawAPartial
  ✓ testPartialIsUprightConstantHeightAndNeverGroupedOrStruck     (V17-W1/W3)
  ✓ testNothingSpecialHappensAtTwentyFour                         (RF-7c)
  ✓ testLiveBlockSitsBelowTheCribRuleAndInsideItsAuthoredRect     (RF-7b)
  ✓ testFivesAreClosedByADiagonalThatSpansExactlyItsFourUprights
  ✓ testWorstCaseIs48StrokesAndFitsTheAuthoredRows
  ✓ testAccrualIsMonotonicAndSkippingLandsOnTheFinalBlock         (RC-4)
  ✓ testTallyClearsOnMountUnmountAndOnFewerThanTwoGears           (D13 i/ii)
  ✓ testTallyIsNeverSavedAndReDerivesEmptyOnLoad                  (D13 iii)
  ✓ testTallyNeverVariesWithAnyClueFlag / testNoTallyWhileTheArborIsSeized
  ✓ testNotationIsLoadedFromTheAuthoredMetadata / testTallySpriteRigShipsAndLoads
  ```

- **FULL LANE GREEN (the single pre-release gate)** — dispatch run **`31255684328`**
  (<https://github.com/shayma16/escape-room/actions/runs/31255684328>), conclusion **success**,
  BOTH jobs green including the usually-flaky non-blocking iPad playthrough:

  ```
  fast-lane      Unit tests - iPad 13-inch class          Executed 229 tests, 0 failures
  fast-lane      Unit tests - smallest supported iPhone   Executed 229 tests, 0 failures
  fast-lane      Unit tests - Dynamic Island iPhone       Executed 229 tests, 0 failures
  full-lane-ui   UI - smallest supported iPhone (full playthrough + smoke + save-resume)
                                                          Executed  10 tests, 0 failures  (1116s)
  full-lane-ui   UI - iPad (full playthrough + smoke + save-resume) [non-blocking]
                                                          Executed   6 tests, 0 failures  ( 931s)
  full-lane-ui   UI - Dynamic Island iPhone (safe-area screenshots)
                                                          Executed   3 tests, 0 failures  (  93s)
  ```

  As always this is CI's own automation, not a game-flow certification: level correctness is QA's
  call, and per the standing rule state/inventory/collect behaviour must be verified from RENDERED
  SCREENSHOTS, not engine flags. In particular QA should eyeball, on device: the chalk note's
  appearance at the dormer the moment watch A is inspected (and its disappearance on the pry) in
  all three frames; both wide ring hands at room scale; and the live tally block filling on the
  gear-frame close-up for a wrong pair (count it), for one of the three non-integer pairs (N full
  + one partial), and at the solution (24, with no glow or flash of any kind).

**BUILD-17 READY** — buildable, both lanes green, handed off for QA. Release dispatch is the
Producer's call; `release.yml` was NOT triggered by this batch.
