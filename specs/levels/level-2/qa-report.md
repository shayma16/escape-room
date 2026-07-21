# Level 2 "The Clockmaker's Attic" — QA Report

Authority for correctness: `puzzle-graph.json` rev 1.3 + `walkthrough.md` + `validation-report.md`
+ the four `*-state-overlays.json`. Tested build: CI run **29786847406** (branch
`level2-clockmakers-attic`), FULLY GREEN. QA method: no local Mac — analysis of the built
sources under test, the shipped overlay rect catalog vs the coordinator hotspot rects
(human-visible geometry), and the CI artifact set (`gh run download 29786847406`: 3 unit-test
device xcresults + 3 UI-test device xcresults). Per the binding **R2-META-QA** lesson, verdicts
assert what a HUMAN sees (resulting scene state, hotspot reachability at VISUAL positions, item
collectibility, overlay rendering) — not merely engine flags.

---

## BUILD-1 SECTION

### Headline verdict

**CONDITIONAL GO** for continued integration; **NOT yet release-ready.** Engine logic and
end-to-end completability are solid, all 11 puzzles solve at the engine level in every legal
ordering, no soft-locks, and Level 1 is not regressed. But Level 2 ships with **zero automated
human-visible verification** (see M2), and static geometry analysis surfaced one **MAJOR hotspot
miss (M1)** and one **MAJOR endgame-feedback gap (M3)** that a green CI cannot catch. The
decision is the user's at checkpoint-2; this time the TestFlight spot-check is load-bearing.

---

### Per-puzzle verdicts (engine PASS unless noted; human-visible caveats called out)

| # | Puzzle | Engine | Human-visible | Notes |
|---|--------|--------|---------------|-------|
| p01 | Numeral-dial door | PASS | PASS | Any-order seating of II/IV/VII/XI → sockets 2/4/7/11; tray **VI decoy rejected** (never an inventory item, can never match `dialSolution`); completes → unlocks z2. `testDialDoorCompletesAndUnlocksZ2_anyOrder`, `testDialDoorWrongTileAndDecoyRejected`. |
| p02 | Cat + wind-up mouse | PASS | CAVEAT | Mouse **placed on floor** at cat solves & yields watch B; mouse **offered directly** = D3 tell, mouse returned (`testCatOfferGrammar`). Cushion-reveal overlay shows watch B. Cat pose/skitter/tell/relocation **animations deferred** (see §Deferred). |
| p03 | Dormer floorboard cache | PASS | **MAJOR (M1)** | Gate on watch A + D10 faint-tell correct; great wheel collectable. BUT the `floor-cache` **hotspot does not sit over the cache art it reveals** — see hotspot miss list. |
| p04 | Chimney brick cache | PASS | PASS | Gate on watch B + z2; brick hotspot well-anchored to `ov-brick-*`. Yields oil can. `testChimneyPryRequiresZ2AndWatchB`. |
| p05 | Free the seized arbor | PASS | PASS | Oil-can on arbor → `arbor-freed`; `ov-arbor-oiled` renders over the anchored `arbor` hotspot. |
| p06 | Automaton gear train | PASS | PASS | **Both {36,64} arrangements** solve (either post); **lone-48 trap** holds (`Set==={36,64}`); requires arbor-freed. `testGearTrainBothArrangementsSolve`, `testGearTrainWrongRatioAndLone48`. Mural sun-cross / bell-strike **motion deferred**. |
| p07 | Four-wheel vault hatch | PASS | PASS | Code **VI-X-I-III** = `[6,10,1,3]`, gated on master-time + world-clock-row; wheels retain, wrong stays shut (no tell). `testVaultCorrectCodeGatedThenUnlocks`, `testVaultWrongCodeStaysShut`. |
| p08 | Oil + wind the movement | PASS | PASS | Oil-before-wind enforced (`testWindRequiresOilFirst`); `ov-drum-oiled`/`ov-drum-key-in` over the anchored `drum` hotspot. |
| p09 | Set hands (mirrored dial) | PASS | **MAJOR (M3)** | Front **7:20** releases; **naive 4:40 trap** stays inert (`testNaiveTrapDoesNotReleaseButTrueTimeDoes`); gate on return-tag. Hands rendered mirrored (−θ) as SwiftUI capsules in the CU, no digital readout (intended). BUT the **D11 alive-wrong-time feedback is unrendered** (neither audio nor animation) — re-exposes the "feels broken" bug-read on the hardest puzzle. |
| p10 | Start the pendulum | PASS | minor (m2) | `pushPendulum` latches + tick SFX. **No visual swing** — the push produces no on-screen change (pendulum overlay is background-clear only). Idempotent, so harmless but confusing. |
| p11 | Open stair door and leave | PASS | PASS | `cond-timelock-release` latches **order-free** and **permanently** (`testTimelockOrderFree_pendulumFirst`, `testTimelockLatchesPermanently`); `ov-bar-raised` in z1, win beat. |

### Per-zone verdicts

- **z1 Attic** — PASS engine; **MAJOR M1** (floor-cache hotspot). All other z1 overlays
  (screwdriver, stove tile, dial seats, crate, sill, cushion, bar-raised, workroom-door-open)
  present and anchored.
- **z2 Movement Loft** — PASS. arbor / gear-rack / brick / panel / cabinet hotspots all anchored
  to their overlay rects; per-element compositing confirmed (no full-plate swaps).
- **z3 Behind the Dial** — PASS engine; **MAJOR M3** (endgame feedback). drum/hatch anchored;
  great-dial & pendulum estimated (see m5).
- **z4 Vault** — PASS; **minor m3** (key/tag hotspot overlap). key-hook & tag-nail both anchored,
  but their hotspots overlap the neighbor's art edge.

---

### Bug list (severity-tagged)

**CRITICAL** — none. No engine-level solvability or soft-lock defect; all orderings complete.

**MAJOR**

- **M1 — Dormer floor-cache hotspot misregistration (p03).** The `floor-cache` hotspot is
  `x[0.40,0.60] y[0.80,0.96]`, but the cache art it reveals (`ov-cache-pried-wheel` /
  `ov-cache-empty`) renders at `x[0.6375,0.7656] y[0.898,1.0]` — **zero horizontal overlap**. The
  pried board + great wheel appear ~4% of screen-width to the RIGHT of the tap target, and that
  visual region instead falls under the `cat-floor` / `cat-cushion` hotspots, so tapping the
  visible wheel opens the cat-cushion close-up rather than the cache. A human following the ⌂-ring
  "3 o'clock, board right of the dormer" clue taps right-of-dormer and misses the cache entirely.
  *Repro:* z1 v-door → view watch A → arm screwdriver → tap the visibly-openable board / great
  wheel at bottom-center-right → nothing / wrong CU; the working pry is at empty floor left of the
  dormer. *Fix:* re-anchor `floor-cache` to the `ov-cache-*` wide rect (`x0.6375–0.7656,
  y0.898–1.0`), matching every other overlay-anchored hotspot. This is the L1 **R3-005-class**
  iterative item.

- **M2 — No Level-2 UI/hotspot or overlay-registration test coverage in CI.** The green run's UI
  playthrough (`testFullPlaythroughWithScreenshots`) and the overlay guards
  (`testEveryCoordinatorRequiredOverlayKeyExistsInCatalog`,
  `testOverlayRectsAreSaneSubRegionsOfThePlate`, `testOverlayArtIsPixel1to1WithItsRect`,
  `testTapsAtVisibleElementPositionsHitTheirHotspots_R3_005`) are **Level 1 only** (hearth/entry/
  cellar/alcove, `OverlayRectCatalog`). Level 2 is verified solely by **engine-logic unit tests**
  (`Level2Tests`, 26 tests) + asset-staging integrity (`Level2AssetStagingTests`). Nothing
  exercises L2 hotspot geometry or `Level2OverlayCatalog` rect sanity — so M1, and the same
  art-in-wrong-rect class of defect that reached a user on **L1 build 13** (R7-001), are
  structurally uncatchable for L2 in CI. *Route to Developer:* add an L2 hotspot-reachability test
  (taps at visible element positions hit their intended hotspot with smallest-area-wins) and port
  the overlay rect-sanity + pixel-1:1 guards to `Level2OverlayCatalog`.

- **M3 — p09 mirror-trap mitigation (D11) not rendered.** `Level2Engine.isAliveWrongTime` computes
  the D11 state, but nothing plays the specified escapement-tick audio or hammer-twitch, and the
  pendulum has no swing animation. Result: a wound clock with the pendulum started but the hands at
  a wrong time (the 4:40 trap) shows a **fully inert-looking movement** — the exact "the game lied /
  it's broken" bug-read that playtest-tweak-3 / D11 was added to prevent, on the level's hardest
  puzzle (already flagged as possibly too hard). *Recommend:* wire at least the D11 ambient
  **escapement-tick audio** and the pendulum swing before release, or have the user explicitly
  accept the risk at checkpoint-2. (Tied to m2.)

**MINOR**

- **m1 — Screwdriver & oil-can consumed after last use (KNOWN EXPECTED FINDING; CONFIRMED).**
  `Level2Graph.itemUses` gives `itm-screwdriver = [p03,p04]` and `itm-oilcan = [p05,p08]`, and
  `Level2Lifecycle.reconcile` drops each once all uses are satisfied (screwdriver after p04, oil-can
  after p08) — contradicting the graph nodes, which say both are **NEVER consumed / retained the
  whole level** (oil-can "and beyond"). Confirmed via `testScrewdriverConsumedOnlyAfterBothCaches` /
  `testOilcanRetainedAcrossBothUses`. **Does NOT soft-lock** (no further use exists after
  consumption). Spec-fidelity bug, already queued for dev; one-line fix = give both empty effective
  `uses`.
- **m2 — Pendulum push has no visual result (deferred swing).** See p10. Confusing, not blocking.
- **m3 — z4 key-hook / tag-nail hotspot overlap.** `key-hook` `x[0.23,0.37]` covers the right edge
  of the tag art (`ov-tag-taken` `x[0.156,0.253]`); tapping the tag's right edge can trigger key
  pickup. Tighten `key-hook` left edge to ~0.255.
- **m4 — cat-cushion hotspot clips the watch-B reveal.** `cat-cushion` ends at `y0.77` but
  `ov-cushion-reveal` (watch B on the bench) extends to `y0.807`. Watch B is collected inside the
  CU so this doesn't block; extend the hotspot bottom to ~0.81 so the reveal is tappable.
- **m5 — z3 great-dial / pendulum hotspot overlap.** `great-dial` `x[0.28,0.62]` overlaps
  `pendulum` `x[0.50,0.62]`, with the pendulum art band (`ov-pendulum-absent` `x[0.529,0.594]`)
  fully inside the dial rect. Smallest-area-wins should keep the pendulum tappable (area 0.074 vs
  0.163), but the right edge is tight — verify on device and, if needed, notch the dial hotspot to
  exclude the pendulum column.
- **m6 — Gear frame accepts the same rack value on both posts (engine).** e.g. mounting 48 on A and
  48 on B both succeed; the lone-48 trap still holds (`Set` check fails), but the rack physically has
  one of each. Cosmetic/fidelity, not a solvability issue.
- **m7 — p03/p04 collapse the "which board/brick" pointer beat to a single always-correct hotspot.**
  `pryDormerBoard(isCorrectSpot: true)` / `pryChimneyBrick(isCorrectSpot: true)` are always called
  with the correct spot, so the spatial clock-hand-as-pointer discrimination (wrong spots giving the
  dead anti-sweep wall) is not exercised in the shipped single-hotspot UI. The clue-gate still
  enforces viewing the watch, so anti-spoiler holds, but the intended spatial-reasoning beat is
  reduced to "arm screwdriver, tap the one cache." Flag for design/dev awareness; address together
  with M1.

---

### Alternate-order completability (task 2)

Engine-level PASS. The order-free derived condition is verified (`testTimelockOrderFree_pendulumFirst`,
`testTimelockLatchesPermanently`), dial seating is order-agnostic, and the gates are all satisfiable
from permanently-reachable zones/inventory (per `anti_softlock_invariants`, re-confirmed against the
engine). No soft-lock path found. **Gap:** unlike L1 (which has explicit `testSolvePathOrderingA/B/C`
in `QALevelFlowTests`), Level 2 has **no single end-to-end test that runs the graph's
`example_ordering_A/B/C`** across all 11 nodes — completability is proven piecewise + by the order-free
timelock tests. Recommend adding the three L2 example orderings as end-to-end engine tests.

### Per-element overlay rendering (task 3)

PASS at the compositor level. `Level2Coordinator.refresh()` clears the view's overlay superset then
re-adds one stable base + independent per-element overlays keyed by state (never a full-plate swap);
`Level2Visuals.wideOverlays` drives them from latched state only. Every overlay key the coordinator
can request resolves to a `wide_rect_3x` in the four `*-state-overlays.json` (cross-checked all keys:
screwdriver/stove/dial-seats/crate/sill/cache/cushion/bar/workroom-door; arbor/rack-absent×6/brick/
panel; cabinet; drum-oiled/drum-key-in/hatch; key/tag). No missing key would silently render nothing.
Manual pickups show emptied containers (`ov-cache-empty`, `ov-cushion-empty`, `ov-cabinet-empty`,
`ov-brick-empty`, `ov-key-taken`, `ov-tag-taken`). Armed-item deselect is discoverable
(`scene.onEmptyTap → disarm`), and close-ups remain reachable while armed (`handleTap` falls through
to `lookTap` when a use returns false). **Caveat:** the only *rendering* miss found is M1 (the cache
overlay is placed correctly on the plate, but its **tap target** is not); overlay *art* pixel-1:1
correctness is NOT independently verified for L2 (M2 — the L1 R7-001 backstop does not cover L2).

### Hotspot hit-target calibration (task 7)

Convention confirmed: hotspot rects use the same normalized top-left pixel convention as the overlay
wide rects (the `screwdriver` hotspot equals `ov-screwdriver-taken` exactly), so overlay-anchored
hotspots are directly comparable. **Well-anchored (PASS):** screwdriver (exact), stove, crate, sill,
door-dial (seats covered), stair-door (bar covered), arbor, gear-rack, brick, panel, cabinet, drum,
hatch, key-hook, tag-nail. **Miss list:** M1 (floor-cache — headline), m3 (key/tag overlap), m4
(cushion clip), m5 (dial/pendulum overlap). **Estimated, no overlay anchor — cannot calibrate from
rects; must be spot-checked on device:** coat *(REQUIRED pickups: watch A + tile IV — verify taps
land)*, slate *(clu-slate-ratio)*, barometer, master-clock *(clu-master-time gate)*, house-ring
*(p03 clue anchor)*, cat-floor *(p02 mouse placement)*, gear-frame, clockrow *(clu-worldclock-row
gate)*, display-case, great-dial *(p09)*, pendulum *(p10)*, shelf. Priority for the TestFlight check:
coat, house-ring, clockrow, master-clock, great-dial, pendulum.

---

### Device / orientation matrix (task — CI)

Runner: `macos-15`, run 29786847406. Resolved destinations:

| Device | Class | Build | L2 unit suite | UI coverage |
|--------|-------|-------|---------------|-------------|
| iPad Pro 13-inch (M4) | iPad primary | PASS | PASS | **L1** full playthrough + smoke + save/resume (2 L1 poker tests skipped by design) |
| iPhone SE (3rd gen) | smallest iPhone | PASS | PASS | **L1** full playthrough + smoke + save/resume |
| iPhone 16/15 (Dynamic Island) | notch/DI safe-area | PASS | PASS | DI safe-area smoke + `testSceneContentFillsScreen` only |

L2 unit suite green on all three runtimes. **No L2 UI ran on any device** (M2). CI screenshots are
portrait-letterbox rasters (runner boots simulators portrait; the app itself lays out full-width
landscape — verified by the harness-immune logical guard and the prior on-device check). True
landscape screenshot fidelity + notch/Dynamic-Island safe-area *feel* is deferred to the user's
TestFlight spot-check (per scope: real touch/thermals/haptics are the user's manual step).

### Level 1 regression (task 5)

**PASS.** `testLevel1RulesUnaffected` asserts L1 still unlocks `z1-cabin` (not the L2 attic) through
the shared `LevelRules` abstraction (`Level1Rules == PuzzleGraph.startZoneID + ItemLifecycle.reconcile`,
byte-identical). The full L1 UI playthrough is green on iPhone SE **and** iPad, and L1 save/resume +
D7 gate persistence pass. The shared `GameState`/`SaveGameStore`/`RoomScene` stack was reused, not
forked; no L1 behavior change observed.

### Save / resume (task 4)

**PASS (engine).** `testSaveResumeRoundTripsAllL2Fields` round-trips a **mid-puzzle** state —
dial sockets, gear-post gears, vault-wheel values, clock front-minutes, latched flags, viewed clues —
plus `testLevelSaveDataCodableRoundTrip`. One save format (superset) shared with L1. **Gap:** no
*UI-level* L2 save/resume test inside a hidden zone mid-puzzle (L1 has
`testRelaunchInsideNestedHiddenZoneMidPuzzle`); the engine round-trip is solid, but recommend an L2
equivalent for the hidden z3/z4 states.

### Level Select (task 6)

L2 card present: `LevelMeta(id: 2, title: "The Clockmaker's Attic", thumbnail: "level2-thumb")`.
Completion badge flows through the same shared save layer as L1's tested `level-card-1-complete`
(`GameState(levelID: 2).markComplete()`), so it should render on completion — but this is **not
explicitly UI-tested for L2** (M2). Verify the badge on TestFlight after a full L2 solve.

### Sound (task 8)

**PASS.** No `"psh"`/whoosh/hiss in any L2 event path (the only "psh" hits are comments documenting
its removal). `.wood`/`.fizzle` are not played in L2; L2 zone navigation is **silent** (visual only).
D10 `sfx-creak` (woody groan) and release `sfx-chime` (soft bell) are wired; menu = `menuConfirm`
soft ping (MainMenu, LevelSelect, pause). **`music-level2.wav` staged but NOT wired** — the level bed
still reuses the L1 track. Per instruction this is a pending dev item and is **flagged, not failed:**
`music-not-yet-level2`.

### Deferred cosmetic animations — release assessment (task 9)

Logic present, sprite MOTION deferred (impl-notes judgment call 4): cat poses, mouse skitter, D3
mouse-tell/refusal animation, mural sun-cross + watchman bell-strike, pendulum swing, D11
hammer-twitch, cat relocation to the door.

**Assessment:** Most of these are genuinely cosmetic and **acceptable to defer** for this pass — the
underlying state changes are conveyed by overlays + SFX elsewhere (panel opens, cushion empties, bar
raises, chime fires), so solvability and legibility survive. **Two of the "deferred" items, however,
cross from cosmetic into feedback-necessary and should be re-classified as should-fix-before-release:**

1. **Pendulum swing (m2)** — the *only* on-screen confirmation that p10 succeeded; its absence
   leaves a solved action with no visible result.
2. **D11 alive-wrong-time ambient (M3)** — even just the escapement-tick *audio* — its absence
   re-opens the p09 mirror-trap "feels broken" bug-read on the hardest puzzle.

The remainder (cat poses, mouse skitter, mural strike motion, hammer-twitch sprite, cat relocation)
are **acceptable to defer** to a polish pass and should **not block** checkpoint-2, provided the user
accepts a somewhat static cat and a sound-only gear-train payoff for now.

---

### GO / NO-GO recommendation (user decides at checkpoint-2)

**Recommendation: CONDITIONAL GO** to keep integrating, **NO-GO for release** until the following are
resolved or explicitly accepted by the user:

- **Fix + re-verify M1** (floor-cache hotspot) — currently a human may not reach the dormer cache at
  its visual position.
- **Add L2 UI/overlay test coverage (M2)** — so M1-class and R7-001-class defects become catchable;
  Level 2 presently has no automated human-visible safety net.
- **Wire M3** (D11 tick audio + pendulum swing) or accept the p09 endgame-feel risk in writing.
- **m1** (screwdriver/oil-can consumption) — trivial spec-fidelity fix, already queued.

Everything gating *solvability* passes and L1 is safe, so the level is in good shape structurally.
Because L2 has no automated human-visible verification, the **TestFlight spot-check is decisive this
round** — prioritize the estimated (non-anchored) hotspots listed above and the p09/p10 endgame feel.

---

### Changelist for the Producer to route to the Developer

1. **[MAJOR] M1** — re-anchor z1 `floor-cache` hotspot to the `ov-cache-*` wide rect
   (`x0.6375–0.7656, y0.898–1.0`).
2. **[MAJOR] M2** — add L2 hotspot-reachability test + port overlay rect-sanity & pixel-1:1 guards
   to `Level2OverlayCatalog`; add L2 `example_ordering_A/B/C` end-to-end engine tests + an L2
   hidden-zone mid-puzzle save/resume test.
3. **[MAJOR] M3** — wire D11 ambient escapement-tick audio + pendulum swing (or user-accept).
4. **[MINOR] m1** — make `itm-screwdriver` / `itm-oilcan` never-consumed (empty effective `uses`)
   to match the graph.
5. **[MINOR] m3** — tighten z4 `key-hook` left edge (~0.255) to clear the tag art.
6. **[MINOR] m4** — extend z1 `cat-cushion` hotspot bottom to ~0.81 for the watch-B reveal.
7. **[MINOR] m5** — verify/notch z3 `great-dial` vs `pendulum` overlap on device.
8. **[MINOR] m6/m7] — (awareness) gear frame double-mount of one rack value; p03/p04 single-hotspot
   collapse of the pointer beat.
9. **[FLAG] music-not-yet-level2** — wire `music-level2.wav` (currently L1 bed) — pending dev item,
   not a QA fail.
10. **[VERIFY on TestFlight]** — estimated hotspots (coat / house-ring / clockrow / master-clock /
    great-dial / pendulum), landscape safe-area feel on Dynamic Island, L2 completion badge on Level
    Select.

*Evidence:* CI run 29786847406 (`build-and-test.yml`, all steps green); artifacts `test-results`
(EscapeRoom-{iPad,iPhone,iPhoneDI}.xcresult + EscapeRoomUITests-{iPad,iPhone,iPhoneDI}.xcresult).
Source under test: `Game/Level2{Engine,Graph,Visuals,Coordinator}.swift`, `Core/LevelRules.swift`,
`UI/Level2RoomView.swift`; overlay rects `Resources/GameAssets/level-2/z{1..4}-state-overlays.json`;
tests `EscapeRoomTests/Level2Tests.swift` (26), `Level2AssetStagingTests.swift`.
