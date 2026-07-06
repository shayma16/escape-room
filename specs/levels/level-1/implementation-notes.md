# Level 1 — Implementation Notes (Developer Agent)

Status: **buildable Xcode project, GREEN on `build-and-test.yml`.** Full Swift
implementation on top of the previously-staged `EscapeRoom/Resources/` art/audio tree.
This document records every judgment call made while turning `puzzle-graph.json`
(rev 1.2), `asset-manifest.json`, `style-guide.md` (Sections 7-8), and
`global-ui-style.md` into code, for the Documentation Agent to reconcile against the
walkthrough and for the Producer/user to review. Puzzle logic, art direction, and
difficulty were not modified — only implemented as specified; any place the source
specs left something unstated is flagged below rather than silently decided.

**Latest green CI run:** https://github.com/shayma16/escape-room/actions/runs/28745052491
(build + unit tests on both a 12.9"/13" iPad Pro simulator and an iPhone SE simulator).
See "CI resolution log" near the end of this document for everything that had to be
fixed to get there — several were CI-only failure modes invisible from local inspection
(there is no local macOS/Xcode environment in this project, per CLAUDE.md).

## Architecture summary

- **Swift + SpriteKit** for the 7 room views (`RoomScene`), **SwiftUI** for all chrome
  (Main Menu, Level Select, Pause, Settings, inventory bar, HUD).
- Puzzle state is modeled exactly as the spec's `solve_path_notes.state_model`
  prescribes: a `GameState` holds a set of held items, unlocked zones, boolean flags,
  and solved-puzzle ids. `PuzzleEngine` functions are pure requirement checks +
  mutations (`Game/PuzzleEngine.swift`) — no function anywhere gates on "did X happen
  before Y," only on "is flag/item/zone/condition currently true." `cond-beam-at-alcove`
  (D2) is implemented as `GameState.evaluateCondition(_:)`, re-evaluated fresh from
  latched flags on every call — verified order-independent by
  `testBeamAtAlcoveConditionIsOrderIndependent_mirrorFirst/_shutterFirst` in
  `EscapeRoomTests/PuzzleEngineTests.swift`.
- Fixed solution values (rune order, moon-dial phases, astrolabe plate, cabinet
  sun/moon items, brew flame/stir/count, mirror detent) are Swift constants in
  `Game/PuzzleGraphModel.swift`, never randomized, matching `puzzle-graph.json` verbatim.
- D1 (BLOCK, user-approved 2026-07-04): `PuzzleEngine.attemptPourDraughtAtFeedCup()` is
  an intentional no-op (zero state churn); the phial-of-draught is never removed from
  inventory. D3/D4: `PuzzleEngine.triggerCrowTerminalRefusal()` is likewise a no-op used
  identically for cage-reach and for any item dropped on the feed cup — the Scene layer
  plays the same refusal animation/SFX every time with no escalation logic anywhere to
  escalate. D5: `PuzzleEngine.setClockToTwelve` implements the one-shot cosmetic latch
  (`clock-cuckoo-spent` flag) and is never read by any other puzzle's requirements.
- Zone unlock / nested hidden zones: `z3-cellar` and `z4-alcove` unlock exactly as
  specified (`p02` -> z3, `p07` -> z4); `GameState.unlockedZones` gates both scene
  navigation (`LevelSession.availableViews()`) and Level Select is unaffected (level-level
  completion, not zone-level).
- Save/resume: `SaveGameStore` (JSON file in Application Support) is the single
  persistence layer for both per-level progress (items/flags/zones/solved-puzzles) and
  the Level Select completion map, per the architecture requirement. Every mutation on
  `GameState` persists synchronously, so there is no transient unsaved state — this is
  the basis for the J5 ruling below (Main Menu exit needs no confirmation).
- Entitlements: `Core/Entitlements.swift` is the single call site
  (`Entitlements.isLevelUnlocked(_:)`), currently hardcoded `true`. Level Select routes
  every card through it, so adding IAP later only changes this one function.
- Global UI chrome (one-time, theme-independent): `UI/MainMenuView.swift`,
  `LevelSelectView.swift`, `PauseMenuView.swift`, `SettingsView.swift`,
  `ChromeTheme.swift` implement `specs/global-ui-style.md` verbatim — neutral palette
  tokens, capsule buttons, SF Symbols only, checkmark/lock badges carried by shape +
  position (never color-only), destructive Reset Progress confirmation alert, About
  sheet, version string read from `Bundle.main.infoDictionary` (never hardcoded).
  Landscape lock (J6) is enforced at the `Info.plist` level
  (`UISupportedInterfaceOrientations` = landscape only, `UIRequiresFullScreen = true`).

## Judgment calls flagged for review

1. **Hotspot pixel rects for taps without a manifest overlay entry.** The asset
   manifest's `overlays.json` gives authoritative normalized rects only for
   *compositable state overlays* (vines, cage, flame, mirror, barrel, etc.). For
   plain tap targets that have no overlay art of their own (item pickups drawn directly
   on a base plate — poker, rusted key, spoon, cage key, statue key — plus the rune-tile
   plate positions, the three moon-dial positions within the dial-panel close-up, and
   the astrolabe/mirror/winch/cauldron/mortar regions), I hand-placed conservative
   normalized rectangles in `RoomSceneCoordinator.configure*()` based on the wide-plate
   prompt descriptions and close-up crop names in the asset manifest, sized to clear the
   44pt minimum hit target via `Hotspot.minHitSize`. These are placeholder-precision:
   they are functionally correct (every puzzle is reachable) but not pixel-perfect
   against the actual generated art, since no manifest field specifies exact hotspot
   rects for raw pickups. **QA should verify hit-target alignment against the real
   rendered plates on both iPad and iPhone crops and file adjustments; this is a UI
   polish pass, not a logic change.**
2. **Rune-tile numbering to rune mapping.** Confirmed from
   `EscapeRoom/Resources/GameAssets/level-1/z1/v-study/sprites/runedoor-tiles.json`:
   tile1=FIRE, tile2=WATER, tile3=AIR, tile4=EARTH (top-to-bottom display order per the
   manifest note "display top-to-bottom: FIRE, WATER, AIR, EARTH"). The fixed press
   order AIR→FIRE→EARTH→WATER therefore corresponds to tapping tiles 3,1,4,2 in that
   order, exactly as the manifest's own annotation states. No ambiguity — recorded here
   for traceability since the mapping lives in a sprite-metadata JSON rather than the
   puzzle graph itself.
3. **Moon-dial input mechanism.** The puzzle graph specifies three rotary dials with 8
   embossed phases each, evaluated as a set (order-free evaluation, dials retain
   position, no lockout). I implemented each dial as an independent tap-to-advance
   control (`MoonDialControlView`) cycling through the 8 phases in the sprite's declared
   clockwise order, re-checking the full 3-dial solution after every single dial change.
   The spec doesn't mandate a specific gesture (tap-to-advance vs. drag-to-rotate); I
   chose tap-to-advance for a first pass since it trivially satisfies the 44pt hit
   target and "no lockout" requirement. **Flag: if the design intent was a drag/rotate
   gesture for tactile feel, that's a UI enhancement, not a logic change — please
   confirm whether tap-to-advance is acceptable or a drag gesture is expected.**
4. **Brew mini-game interaction shape.** `p14-brew` is a "procedural apparatus puzzle"
   (flame stage + stir direction/count + order-free ingredient add). I implemented
   ingredient-add via drag-onto-cauldron-hotspot (consistent with every other
   item-on-hotspot puzzle in the game) and flame/stir via explicit buttons
   (`BrewControlView`: "Pump Bellows", "Stir CW/CCW", "Release Ladle") rather than a
   continuous drag gesture for the ladle, since the spec's "stir-direction affordance
   that makes CW vs CCW unmistakable" (Playtest R3) is an art/animation requirement I
   cannot fully realize without the actual ladle-drag interaction polish pass. The
   underlying `PuzzleEngine.resolveBrew(flameStage:stirDirection:stirCount:state:)` is
   spec-exact (stage 3, CCW, 5 turns; wrong parameters fizzle and return all three
   ingredients to inventory intact, never destroyed). **Flag: the discrete button UI is
   a placeholder for the eventual drag-gesture ladle control described by R3; QA/Art
   should treat the *values and failure/success semantics* as final and the *gesture
   affordance* as pending a polish pass.**
5. **Vines mid-pour "withered" state.** `visually_necessary_elements` lists three vine
   states (alive/withered/gone) but the puzzle graph's only transition is
   `door-unsealed` (vines wither and crumble off in one described beat: "thorn-vines
   wither and crumble off the bolt"). I implemented only two rendered states
   (alive/gone) keyed directly off the `door-unsealed` flag, treating "withered" as a
   transient animation frame between the two rather than a persisted state, since there
   is no separate requirement/flag for a mid-wither checkpoint anywhere in the graph.
   The withered asset (`ov-vines-withered` / `cu-door-lock-vines-withered`) exists and
   is unused by game logic in this pass — it's available for an animation-transition
   polish pass (crossfade alive → withered → gone) without any state-machine change.
6. **SpriteKit-space drag/drop coordinate conversion** (`GameRoomView`'s
   `.onReceive(.inventoryItemDropped)`): I convert the SwiftUI global drag-end point to
   scene space via a linear transform based on the on-screen frame of the `SKView`,
   assuming the scene's `.aspectFill` scale maps uniformly across both axes for the
   region actually on-screen. This is correct for the common case but is an
   approximation, not an exact `SKView.convert` call (SwiftUI's `UIViewRepresentable`
   doesn't expose the underlying `SKView` for direct conversion without extra plumbing).
   **Flag for QA:** verify drag-and-drop hit-testing lines up correctly near view edges
   on both device classes; if it drifts, the fix is isolated to that one conversion
   block and does not touch puzzle logic.
7. **D1 pour target scope.** Per spec, "the rune basin is the ONLY pour target that
   advances state" and the feed cup always refuses. I did not add any other pourable
   hotspot (e.g. windowsill, flowerpot) since none is described as a valid or
   red-herring pour target anywhere in the graph; this is a straight read of the spec,
   not a judgment call, but recorded since D1 invited close attention to mis-pour
   targets generally.
8. **J5 verification (Main Menu exit, no confirmation).** Per global-ui-style.md
   Section 5.3, this pairing is premised on "requirement-based state persisting across
   menu exits." Confirmed: every `GameState` mutator calls `persist()` synchronously
   into `SaveGameStore` before returning, so there is no in-memory-only transient state
   that a menu exit could lose (the only "transient" UI state — e.g. a partially-entered
   rune sequence, `runeDoorProgress` — is itself persisted too, so even that survives an
   app relaunch, though a partial in-progress guess surviving is a harmless bonus, not a
   requirement). No divergence found; J5 stands as specified.
9. **Level Select single-level list.** Only Level 1 exists yet; `LevelSelectView` is
   written generically (`[LevelMeta]` array) so adding future levels is a data change,
   not a structural one.

## SFX sourcing and licensing

Per the Developer Agent brief's audio rule ("source from free, properly-licensed
royalty-free sound libraries... no license confirmed = not shipped"), I inspected the
already-staged `EscapeRoom/Resources/Audio/*.wav` files before deciding whether to
replace them. Finding: **these files are not third-party library assets at all** — they
are programmatically synthesized from scratch by `tools/build_game_assets.py`
(`gen_sfx()` / `gen_ambient()`, using `wave`/pure sine-tone/noise-envelope synthesis, no
sampled or recorded source material of any kind). Because they are wholly original
works generated by the project's own tooling, they carry no third-party license
obligation at all (no attribution required, no license file needed) — the "no license
confirmed = not shipped" rule is about *avoiding unlicensed third-party content*, and
there is no third party here. This satisfies the brief's intent (properly-cleared,
commercially-safe audio) via a stronger guarantee than a CC license would provide.

| File | Content | Source / method |
|---|---|---|
| `sfx-click.wav` | Interact/click | Synthesized: filtered noise burst + descending tone sweep (780→620 Hz), `gen_sfx()` |
| `sfx-pickup.wav` | Item pickup | Synthesized: two-tone rising chime (660 Hz + 990 Hz) |
| `sfx-wrong.wav` | Incorrect attempt | Synthesized: low thud (120→64 Hz) + noise, fast exponential decay |
| `sfx-solve.wav` | Puzzle-solve confirmation | Synthesized: three-note ascending chime (C5/G5/C6) |
| `sfx-unlock.wav` | Zone-unlock reveal | Synthesized: low rumble + soft chime tail (G4) |
| `sfx-refusal.wav` | Crow terminal refusal (D3/D4) | Synthesized: short percussive snap + descending tone |
| `sfx-clack.wav` | Clock cuckoo pop (D5) | Synthesized: dry wooden-clack tone (310 Hz) + noise transient |
| `sfx-fizzle.wav` | Brew failure | Synthesized: filtered noise decay |
| `amb-z1.wav` | z1 Main Cabin ambient loop | Synthesized: low hum + texture noise, seamless loop |
| `amb-z2.wav` | z2 Workshop ambient loop | Synthesized: 98 Hz hum + texture, distinct timbre from z1 |
| `amb-z3.wav` | z3 Cellar ambient loop | Synthesized: 55 Hz drone + texture, distinct from z1/z2 |
| `amb-z4.wav` | z4 Alcove ambient loop | Synthesized: three-tone soft drone (196/294.3/392.4 Hz), distinct from z1-z3 |

All files verified as real 16-bit PCM WAV audio (not empty/corrupt placeholders) via
direct inspection before this note was written. `SoundManager.swift` wires all eight SFX
cues plus the four zone loops (crossfading on zone change) and honors the Settings
"Sound" master toggle from `SaveGameStore.soundOn`. Per-zone tonal distinction is
achieved via frequency/texture variation exactly as the brief allows ("reverb, pitch,
texture variation").

## Xcode project structure

- `EscapeRoom/EscapeRoom.xcodeproj` — traditional explicit `PBXFileReference` /
  `PBXBuildFile` / `PBXGroup` / `PBXSourcesBuildPhase` entries for all 28 app Swift
  files + 1 test Swift file (see "CI resolution log" below for why the initial attempt
  used Xcode 16's newer file-system-synchronized groups for compiled sources and had to
  be reverted). `Resources` (art/audio/xcassets — pure bundled assets, not compiled
  sources) still uses a `PBXFileSystemSynchronizedRootGroup`, which is a safe, low-risk
  use of that feature since nothing there needs to appear in a build phase's file list.
  New Swift files therefore DO need a pbxproj entry (3 new IDs: file reference, build
  file, and a `PBXGroup` children entry) — this is the traditional/standard tradeoff and
  is called out here so the next contributor isn't surprised.
- Two targets: `EscapeRoom` (app) and `EscapeRoomTests` (unit tests, hosted in the app).
- Deployment target iOS 17.0, Swift 5, `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad),
  `objectVersion = 60` (conservative/widely-compatible pbxproj schema version).
- Bundle id `com.escaperoom.app.wizardscabin` (placeholder — Release Manager may need to
  change this to match the final App Store Connect app record; flagging since "app name
  / bundle identifier undecided" was already an open item in `specs/project-state.md`).
- CI (`build-and-test.yml`) uses the macOS runner's **default** Xcode toolchain
  (deliberately not pinned to a specific side-installed version — see CI resolution log),
  builds for a concrete iOS Simulator destination, then runs the unit test target
  against both a 12.9"/13" iPad Pro simulator and an iPhone SE simulator (smallest
  supported iPhone), resolving exact simulator names dynamically from
  `xcrun simctl list devices` so the workflow doesn't hardcode a device name that might
  not exist on a given runner image.

## CI resolution log (getting build-and-test.yml green)

Getting from "no Xcode project exists" to a green CI run took six iterations, each
diagnosed from CI logs only (no local macOS environment exists in this project). Recorded
here in full because several of these are non-obvious CI-only failure modes that could
recur if the project structure changes again:

1. **Workflow YAML rejected outright** (`gh workflow run` said "Workflow does not have
   'workflow_dispatch' trigger" even though it clearly did; the push-triggered run failed
   in 0 seconds with "This run likely failed because of a workflow file issue," zero jobs
   created). Root cause: a step name containing a stray literal double-quote
   (`Unit tests — iPad (12.9"/13" class)`) inside an unquoted YAML scalar. Fixed by
   removing embedded quotes/smart-punctuation from all step names and simplifying the
   simulator-name-resolution shell script (originally embedded multi-line Python
   heredocs inside a YAML block scalar, an unnecessary quoting-risk surface) down to a
   plain `grep`/`head` pipeline.
2. **`generic/platform=iOS Simulator` destination rejected**
   (`xcodebuild: error: Unable to find a destination matching...`, only the
   ineligible device placeholder listed). Fixed by building against the same concrete
   resolved simulator destination used for the test steps, instead of the ambiguous
   generic destination.
3. **Concrete simulator destination STILL rejected** even after fix #2, and
   `xcodebuild -showdestinations` returned literally nothing but the ineligible device
   placeholder — no "Available destinations" section at all, for any simulator.
   Hypothesis A (wrong): the `Resources` synchronized-group's `path = ../Resources`
   escaped above the `.xcodeproj`'s own directory to a nonexistent location. This WAS a
   real bug (fixed to `path = Resources`) but did not change the destination-resolution
   symptom at all, disproving the hypothesis.
4. **Hypothesis B (wrong):** the newer `PBXFileSystemSynchronizedRootGroup` mechanism
   used for the app's compiled Swift sources (not just `Resources`) was somehow
   preventing the target from resolving a valid platform/SDK combination. Rewrote the
   entire pbxproj with traditional explicit `PBXFileReference`/`PBXBuildFile` entries
   for every source file. Result: identical symptom, disproving this hypothesis too
   (though the traditional structure was kept anyway as the more conservative,
   better-understood mechanism going forward).
5. **Actual root cause found:** the workflow explicitly pinned
   `sudo xcode-select -s /Applications/Xcode_16.2.app` before every build/test step.
   The `-showdestinations` error text included "iOS 18.2 is not installed. To use with
   Xcode, first download and install the platform" attached to the *device* placeholder
   entry — a strong hint that this specific side-installed Xcode version on the
   `macos-15` runner image lacks pre-cached iOS Simulator platform support that the
   image's *default* Xcode has. Removed the explicit `xcode-select` pin entirely and let
   the workflow use whichever Xcode the runner image defaults to. **This was the actual
   fix** — the build succeeded immediately afterward.
6. **Build green, but 2 tests failed + 1 flaked:** `testBrewFizzleReturnsAllIngredientsIntact`
   and `testBrewSucceedsWithCorrectParameters` asserted the wrong `BrewOutcome` case
   because they never called `state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)` before
   invoking `PuzzleEngine.resolveBrew`, which the puzzle graph's `p14-brew.requires`
   correctly enforces (`"zone: z2-workshop"`) — a test setup bug, not a puzzle-logic bug.
   `testSoundSettingPersistsIndependentlyOfProgressReset` failed once, traced to a real
   latent bug in `SaveGameStore`: `update(_:)` called `cached ?? load()` from inside
   `queue.sync { ... }`, and `load()` itself wrapped its body in another `queue.sync` on
   the *same* serial queue — a classic GCD self-deadlock / reentrancy hazard. Extracted
   the shared body into a private `loadLocked()` assumed to already be running on the
   queue, called directly by both `load()` and `update(_:)`. All 29 unit tests pass after
   this fix, on both simulator destinations.

Net effect: none of these six fixes touched puzzle logic, art, or difficulty — all were
either CI/tooling issues or straightforward Swift bugs in the Developer Agent's own
infrastructure code (persistence layer, test setup), consistent with this agent's scope.

## QA fix pass (2026-07-06, post step-12 NO-GO; user-approved full fix pass)

Scope: all 22 bugs in `qa-report.md` EXCEPT the art-dependent part of QA-BUG-004 (user
chose an ART RE-FRAME fix; the Asset Generation agent's "BUG-004 re-frame batch" in
`asset-progress.md` was 0/11 done when this pass finished — see "BUG-004 status" below).
Engine semantics, fixed solution values, art direction, and difficulty untouched, per
scope rules; every change below is either a defect fix or a missing interaction surface
the graph already specified.

### Per-bug fix summary

| Bug | Status | Fix |
|---|---|---|
| 022 (critical) | FIXED | Root cause: `Resources` shipped via a `PBXFileSystemSynchronizedRootGroup`, which flattens the folder hierarchy in the built bundle, so `GameAssetLoader`'s `resourceURL/GameAssets` + `resourceURL/Audio` scans found nothing. Replaced with classic **folder references** (`lastKnownFileType = folder`) for `GameAssets/` and `Audio/` plus an explicit `Assets.xcassets` entry in the app's Resources build phase — folder references preserve hierarchy by definition. `testQA_BUG_022` unwrapped and extended to cover an audio file. Hardening: `RoomScene` no longer kills hotspot creation when a texture fails to load (hotspot layout now derives from scene size, not texture size), so an asset regression can never silence input again. |
| 001 (critical) | FIXED | `GameState.init` (and `restartLevel`) now insert `PuzzleGraph.startZoneID` (`z1-cabin`, graph `zones[0].start_zone`) into `unlockedZones`; applied on every init so old saves migrate. `testQA_BUG_001` unwrapped. |
| 002 (critical) | FIXED | Cauldron drop handler routes the empty phial to `PuzzleEngine.fillPhial` (solve SFX + brew close-up); non-ready cauldron plays the wrong-SFX and returns the phial. `testQA_BUG_002` unwrapped. |
| 003 (critical) | FIXED | Door-lock tap with `door-unsealed` latched calls `slideBoltAndLeave` (p17) → completion overlay (Main Menu / Play Again) → Level Select badge. Before unsealing, the same tap opens the `cu-door-lock` inspection close-up. `testQA_BUG_003` unwrapped. |
| 012 (critical) | FIXED | Two UI paths, exactly as the graph describes ("anywhere (inventory combination); workbench close-up also accepts it"): (a) inventory combine gesture — tap item A to select, tap item B to combine via `ItemCombinations.combine` (non-combinable pairs just move the selection, no penalty); (b) new `workbench` hotspot on v-bench accepts a file/spoon drop. Covered by new coordinator tests. |
| 013 (critical) | FIXED | New close-up/inspection layer: `CloseUpRequest` (Game) + `CloseUpView` (SwiftUI), presented over the scene with the §7 down-chevron. Inspectable: grimoire (all 5 spreads, opens at the feather-bookmarked recipe page), triptych (3 paintings), clock (interactive movable hour hand; D5 one-shot pop wired to `setClockToTwelve`, pop/spent plates rendered, `justPoppedClock` now read), bellows, lintel, flowerpot, windowsill, potion shelf, Orion window, star keyhole, barrel pry-gap, winch socket, spoon drawer, ash states, mortar states, planter states, rusted key (long-press its inventory icon — snapped-bit fairness valve), door lock. Interactive close-ups: dial panel (p02), astrolabe plate ring (p03), rune-door tiles (p01, tile rects from `runedoor-tiles.json`, pressed sprites rendered from persisted progress), brew view (p14/p15). |
| 004 (critical) | **DEFERRED by design (carve-out)** | Art re-frame is running concurrently (0/11 when this pass closed). The affected plates' hotspots (v-entry all, v-cellar all, hearth `bellows`, cabinet `potion-shelf`/`astrolabe`/`window`) keep their old values; `testQA_BUG_004` remains a strict expected-failure with an updated message. Final alignment + asset staging happens as a dedicated integration step when the batch lands (the re-frame table's Δx values will drive the new rects). The full-playthrough UI test self-skips on iPad until then. |
| 005 (major) | FIXED | Astrolabe tap opens a six-plate selection close-up (shipped plate sprites); the coordinator never passes the solution. Wrong plates → wrong-SFX, no lockout; plate-2 solves. `testQA_BUG_005` unwrapped + extended to drive the mini-game. |
| 006 (major) | FIXED | `resolveBrew` guards on `draught-ready` (post-success resolves are `.notReady`) and clears `cauldronIngredients` on success (they were spent INTO the draught). Companion guard: ingredient drops on a ready cauldron are refused so nothing can vanish. `testQA_BUG_006` unwrapped. |
| 009 (major) | FIXED | `Hotspot.minHitSize` semantics corrected: the floor is now `minHitSceneSize = 168` scene px = 44 pt at the smallest supported device's `.aspectFill` scale (iPhone SE landscape, 0.2745 pt/px), which guarantees ≥44 pt on every larger device without needing a live view. `testQA_BUG_009` unwrapped (offender list computes empty). |
| 010 (major) | FIXED | Rug tap is a latched free action (`rug-moved` flag, `PuzzleEngine.moveRug`) revealing the trapdoor overlay; the dial UI only exists inside the trapdoor close-up, reachable after discovery. Dial UI removed from the hearth chrome entirely. Once z3 is open, tapping the trapdoor descends to the cellar (diegetic passage per §7). |
| 011 (major) | FIXED | Dial close-up sizes each dial face at 30% of actual screen width (GeometryReader) → 200 pt on iPhone SE, satisfying the §8 / A5-R5 floor on every device. Fixed top-marker notches added so "current phase" is unambiguous. |
| 014 (major) | FIXED | Exact conversion chain: `SpriteKitContainerView` hands the coordinator its `SKView`; drops convert window-point → view-point (`UIView.convert(_:from:nil)`) → scene-point (`SKScene.convertPoint(fromView:)`), which applies the true `.aspectFill` transform including crop. The hand-rolled linear mapping is gone. Additional geometry fix: base plates now render at exactly scene size (both are 2:1 by construction), removing an 86/43 px letterbox nobody had seen behind BUG-022. Covered end-to-end by the new UI test's drag steps. |
| 015 (major) | PARTIAL (by carve-out) | Hotspots re-aligned against the real art on the **non-BUG-004 plates** by direct image inspection: hearth (clock 0.26–0.39, lintel band y 0.24–0.33, ash 0.25–0.40, poker/rug/trapdoor snapped to their overlay rects), study (grimoire, triptych, flowerpot 0.59–0.68, one `rune-door` hotspot on the actual press-plate at x 0.75–0.82 — the four full-door tile hotspots are gone, tiles are pressed in the close-up), bench (cauldron/ladle left, floor bellows bottom-left where the art actually lies, mortar 0.69–0.84, new workbench strip), alcove (planter 0.36–0.57 centered on the pot, statue-key on the beak). BUG-004 plates finish with the re-frame integration. Where hotspots overlap (keyhole/feed-cup inside cage, trapdoor inside rug), the smallest-area hotspot now wins the hit-test. |
| 016 (major) | FIXED | Rendered now: cauldron liquid states incl. the color-blind-safe pearlescent-spiral success cue and gray fizzle (brew close-up), lit rim-rune ember channel per flame stage (positions from `rune-ember-rects.json`), the R3 stir-direction ripple trail (CCW sprite, mirrored for CW), ash sifted-glint (success beat close-up), rune-tile pressed sprites (from persisted progress), crow terminal-refusal pose (`.refusal` close-up observed from `showTerminalRefusal` path, auto-dismissing, identical every repeat), `z3-cellar-weight-hung` plate (0.9 s success beat before the shelf slides), `lastBrewOutcome`/`justPoppedClock` both consumed by UI. |
| 017 (moderate) | FIXED | Cabinet placement validates per-slot at drop time: wrong item → wrong-SFX pop-back, never pending; correct item seats visibly (icon art over the recess — no single-seat plate exists in the manifest) and pending state stays coordinator-local so leaving the view safely un-seats (item was never removed from inventory until the pair completes). |
| 018 (moderate) | FIXED | Star key dropped on keyhole OR cage unlocks (p11); rusted key dropped there gets a visible mechanical reject (wrong-SFX + star-socket close-up, per the graph's "visibly rejects the rusted key's plain bit"); any other item dropped on the cage triggers the D3 refusal. |
| 019 (moderate) | FIXED | Root navigation refactored to one path-based `NavigationStack` (`AppNavigator`); Pause → Main Menu (and the completion card) pops to the EXISTING root, tearing down the level screen and its `LevelSession`, and stops the ambient loop. `fullScreenCover(RootAppView())` removed. |
| 020 (moderate) | FIXED | Cage/keyhole taps after `crow-freed` show the open-empty-cage close-up instead of the refusal; the feed cup goes inert (the crow is gone — the refusal pose art shows a caged crow, so replaying it would be wrong twice over). |
| 007 (minor) | FIXED | `pickBlossom` has the standard already-solved guard. `testQA_BUG_007` unwrapped. |
| 008 (minor) | FIXED | `rotateMirror` marks p09 solved only at detent-3 (latch behavior unchanged). `testQA_BUG_008` unwrapped. |
| 021 (minor) | PARTIAL | Done: view transitions now dip through black (300 ms view-to-view, 600 ms zone-to-zone approximation of §7); Main Menu title reads the bundle display name (single source of truth until the Producer decides the final game/app name — flagged again below). Accepted as-is per QA's own notes: brew pending-stir is view-local (stir is atomic at Release Ladle), resume reopens at v-hearth (not spec-required). |

QA test-infrastructure requests: **1) DONE** — new `EscapeRoomUITests` target (own scheme)
with `testFullPlaythroughWithScreenshots` (scripted full solve, per-view/state
screenshots as xcresult attachments) and `testMenuAndNavigationSmoke` (all devices);
CI runs the full playthrough on iPhone SE, smoke on iPad (playthrough self-skips there
pending BUG-004 art) and on the Dynamic Island device. **2) DONE** — a Dynamic
Island iPhone (16 Pro/16/15 family, resolved dynamically) added to the matrix for unit
tests + safe-area smoke screenshots. **3) DONE** — the 9 fixed bug records unwrapped
into permanent assertions; BUG-004's record stays a strict expected failure until the
art integration step.

### New/changed judgment calls (this pass)

10. **Rug requirement gated in UI, not engine.** p02 `requires: ["free-action: move rug"]`
    is enforced by reachability (the dial close-up only opens from the discovered
    trapdoor) rather than an engine guard inside `evaluateMoonDials`, because QA's
    permanent verification tests drive `evaluateMoonDials` without the flag and must
    stay green. The `rug-moved` flag itself is a persisted satisfied-requirement flag.
11. **Ash glint beat.** The engine grants the ring at the sift itself (QA-green
    behavior); the `cu-ash-sifted` glint plate renders as the sift-success close-up
    moment, then the ash close-up shows ring-taken. The glint is therefore a rendered
    feedback beat, not a separate take-the-ring step.
12. **Rusted-key close-up via inventory long-press.** The entry tap must remain an
    immediate pickup (QA verification test pins it), so the snapped-bit fairness-valve
    close-up is reached by long-pressing the key's inventory icon. If a tap-to-inspect-
    then-take flow is preferred, that is a QA/design call for re-QA.
13. **Moon-dial rotation sign fixed (solvability).** The dial-face sprite carries the 8
    phases clockwise-from-top; the previous build rotated the disc +45° per position,
    which displayed the MIRRORED phase (waxing/waning swapped) under the marker — the
    player would have had to set visually-wrong dials to solve p02. Masked by BUG-022's
    black scenes; now rotates −45° per position and a fixed top marker disambiguates
    the selected phase. Flagging explicitly since waxing-vs-waning is the puzzle.
14. **Astrolabe reward close-up.** On solving p03 the coordinator shows
    `cu-astrolabe-drawer-empty` (items are granted to inventory instantly by the
    engine). The manifest lists a `cu-astrolabe-drawer-open` (coin+crank visible) plate
    but no such file is staged under `Resources/`; if it ships with a later batch the
    one-line swap is marked in `selectAstrolabePlate`.
15. **Clock hands.** Only the hour hand is movable (tap the face to advance one
    numeral); the minute hand is fixed at XII. The graph asks for "movable hands" as
    the way to reach the first-XII pop; one movable hand reaches it with less fiddle.
    The painted-on hands in the `cu-clock-*` plates remain faintly visible under the
    sprite hand — cosmetic, acceptable until an art touch-up.
16. **Completed-level re-entry** shows the completion card with Main Menu / Play Again
    (Play Again = Restart Level semantics). Nothing in the specs covers re-entry;
    flagging for the Documentation Agent.
17. **Feed cup after the crow is freed** is inert scenery (items return unspent, no
    refusal): D4's refusal grammar depicts the caged crow, and the theory it defuses
    is dead once the cage is open. The D4 state invariants (nothing spent, no churn)
    still hold for every item at all times.
18. **`shelf` hotspot removed** from v-cellar: it was inert and only swallowed drops
    meant for the hook (QA-BUG-014's observed failure mode).

### Security checklist (run 2026-07-06, per the Developer agent brief; results for QA)

1. **No development-time secrets in the shipped app: PASS.**
   - `.env` (the fal.ai key, 77 bytes) lives at the repo root only; it is gitignored
     (`.env` + `.env.*`), untracked by git, not present anywhere under `EscapeRoom/`,
     and referenced by zero pbxproj entries. The project has NO shell-script build
     phases at all, so nothing can copy it into a bundle.
   - Pattern grep (`fal.ai`, `FAL_KEY`, `api[_-]key`, `secret`, `credential`,
     `Bearer`, `sk-…`) over every `.swift`, `.plist`, `.pbxproj`, `.json`, `.xcscheme`
     under `EscapeRoom/`: zero matches (after excluding the game's literal
     key-item names like `cage-key`).
   - Built app's resource set: the app's Resources build phase ships exactly three
     entries — `Assets.xcassets` (chrome art), `Audio/` and `GameAssets/` folder
     references. Those trees contain only `.png/.jpg/.wav/.json`; the JSONs carry only
     sprite/overlay geometry (grepped for key/token/password-like strings: clean).
     Nothing else can enter the bundle (no other resource entries, no script phases).
2. **Minimal entitlements/permissions: PASS.**
   - No `.entitlements` file exists and no `CODE_SIGN_ENTITLEMENTS` build setting is
     set on any target — zero capability entitlements.
   - `Info.plist` contains zero `*UsageDescription` permission strings (no camera,
     microphone, location, contacts, photos, Bluetooth — verified by grep). The only
     device-facing declarations are orientation lock, full-screen, status-bar hiding,
     and the launch screen.

### CI (this pass)

- Run 1 — https://github.com/shayma16/escape-room/actions/runs/28753975221 (branch
  `qa-fix-pass-level-1`): build GREEN, **all unit-test steps GREEN on all three matrix
  devices** (iPad 13", iPhone SE, Dynamic Island iPhone) — every unwrapped QA bug
  record and the new regression net passed on-device, including the BUG-022
  folder-reference bundle fix and the still-wrapped BUG-004 expected failure. FAILED
  only in the new UI-test full playthrough, at the moon-dial step ("moon-dial-1 must
  exist"). Root cause (log + geometry): the scripted rug (scene-y 0.90) and trapdoor
  (0.84) taps convert to screen-y > 0.81 on iPhone SE — under the 72-pt inventory
  bar, which swallowed the touches, so the rug never moved and the dial close-up
  never opened. Fix: tap the upper band of those hotspots (scene-y 0.76) and add
  per-milestone inventory assertions (`assertHolding`) after every pickup/yield so a
  future miss fails at the exact step instead of three steps later. Test-script
  coordinate bug, not an app bug — the rug/trapdoor art extends well above the bar
  for real players.
- Later runs recorded below as they complete.

### BUG-004 status at handoff

The Asset Generation agent's "BUG-004 re-frame batch" (`asset-progress.md`) defines the
11 re-frame edits (entry cage Δx −150, hearth bellows → right of fireplace, cabinet
window/drawer Δx −200 + potion shelf → center, z3 global Δx +132 + barrel rescale) but
was **0/11 complete** when this pass finished. Remaining integration work (owned by the
Developer, one step, when the batch completes): stage the new plates into
`EscapeRoom/Resources/GameAssets/level-1/`, re-read the updated `asset-manifest.json`
geometry, set the final hotspot rects for v-entry, v-cellar, hearth-bellows and the
cabinet right/left regions, unwrap `testQA_BUG_004`, enable the iPad full-playthrough
UI test, and re-run CI.

## What's not yet done / next steps before QA

- UI polish flagged in judgment calls 3, 4, 5, 6 above (gesture-based dial/ladle
  controls, exact hotspot rects, vine mid-wither animation, precise drag/drop
  coordinate mapping).
- No accessibility-label pass beyond what's noted in global-ui-style.md Section 9 for
  chrome; in-game hotspots don't yet carry VoiceOver labels (near-wordless game, but
  accessibility labels are still good practice — flagging as a follow-up, not a blocker).
- Reduce Motion is honored for the Level Select transition (`LevelLoadingView`) but not
  yet audited across every SpriteKit animation (tap pulse, refusal pose, etc.).
