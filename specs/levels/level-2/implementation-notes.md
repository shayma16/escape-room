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
