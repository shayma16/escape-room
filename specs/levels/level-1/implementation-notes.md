# Level 1 — Implementation Notes (Developer Agent)

Status: initial Xcode project + full Swift implementation scaffolded on top of the
previously-staged `EscapeRoom/Resources/` art/audio tree. This document records every
judgment call made while turning `puzzle-graph.json` (rev 1.2), `asset-manifest.json`,
`style-guide.md` (Sections 7-8), and `global-ui-style.md` into code, for the
Documentation Agent to reconcile against the walkthrough and for the Producer/user to
review. Puzzle logic, art direction, and difficulty were not modified — only implemented
as specified; any place the source specs left something unstated is flagged below
rather than silently decided.

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

- `EscapeRoom/EscapeRoom.xcodeproj` — uses Xcode 16's file-system-synchronized groups
  (`PBXFileSystemSynchronizedRootGroup`) for `EscapeRoom/EscapeRoom` (app sources),
  `EscapeRoom/Resources` (art/audio/xcassets), and `EscapeRoom/EscapeRoomTests`, so new
  Swift files or art added to those folders on disk are picked up automatically without
  further pbxproj edits.
- Two targets: `EscapeRoom` (app) and `EscapeRoomTests` (unit tests, hosted in the app).
- Deployment target iOS 17.0, Swift 5, `TARGETED_DEVICE_FAMILY = "1,2"` (iPhone + iPad).
- Bundle id `com.escaperoom.app.wizardscabin` (placeholder — Release Manager may need to
  change this to match the final App Store Connect app record; flagging since "app name
  / bundle identifier undecided" was already an open item in `specs/project-state.md`).
- CI (`build-and-test.yml`) pins Xcode 16.2, builds for generic iOS Simulator, then runs
  the unit test target against both a 12.9"/13" iPad Pro simulator and an iPhone SE
  simulator (smallest supported iPhone), resolving exact simulator names dynamically
  from `xcrun simctl list devices` so the workflow doesn't hardcode a device name that
  might not exist on a given runner image.

## What's not yet done / next steps before QA

- UI polish flagged in judgment calls 3, 4, 5, 6 above (gesture-based dial/ladle
  controls, exact hotspot rects, vine mid-wither animation, precise drag/drop
  coordinate mapping).
- No accessibility-label pass beyond what's noted in global-ui-style.md Section 9 for
  chrome; in-game hotspots don't yet carry VoiceOver labels (near-wordless game, but
  accessibility labels are still good practice — flagging as a follow-up, not a blocker).
- Reduce Motion is honored for the Level Select transition (`LevelLoadingView`) but not
  yet audited across every SpriteKit animation (tap pulse, refusal pose, etc.).
