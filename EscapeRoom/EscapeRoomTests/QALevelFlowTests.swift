import XCTest
import UIKit
@testable import EscapeRoom

/// QA Agent test suite (pipeline step 12) — verifies the BUILT level against
/// specs/levels/level-1/puzzle-graph.json rev 1.2.
///
/// Two kinds of tests live here:
///  1. Verification tests: assert spec-correct behavior that the build satisfies today.
///     These must stay green forever (regression net).
///  2. `XCTExpectFailure` bug records (QA-BUG-nnn, cross-referenced in
///     specs/levels/level-1/qa-report.md): assert the SPEC-CORRECT behavior, wrapped in
///     a strict expected-failure. They keep CI green while the bug exists, and the
///     moment the Developer fixes the bug the XCTExpectFailure itself fails loudly,
///     telling us to unwrap the assertion into the permanent regression net.
///     QA does not fix bugs; these markers are documentation, not workarounds.
final class QALevelFlowTests: XCTestCase {

    // MARK: - Helpers (same pattern as PuzzleEngineTests)

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeState(_ dir: URL) -> GameState {
        GameState(levelID: 1, store: SaveGameStore(directory: dir))
    }

    private let sceneSize = CGSize(width: 2732, height: 1366)

    /// Moves the three brew ingredients from inventory into the cauldron the same way
    /// RoomSceneCoordinator.addCauldronIngredient does (remove from inventory, insert
    /// into cauldron set).
    private func loadCauldron(_ state: GameState, file: StaticString = #filePath, line: UInt = #line) {
        for id in BrewSolution.requiredIngredients {
            XCTAssertTrue(state.hasItem(id), "missing brew ingredient \(id)", file: file, line: line)
            state.removeItem(id)
        }
        state.setCauldronIngredients(BrewSolution.requiredIngredients)
    }

    private func setMoonDialsToSolution(_ state: GameState) {
        state.setMoonDialPosition(dial: 0, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waxingCrescent)!)
        state.setMoonDialPosition(dial: 1, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .full)!)
        state.setMoonDialPosition(dial: 2, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waningGibbous)!)
    }

    private func pressRunes(_ state: GameState) {
        for rune in RuneDoorSolution.solutionOrder {
            PuzzleEngine.pressRuneTile(rune, state: state)
        }
    }

    private func runEndgame(_ state: GameState, file: StaticString = #filePath, line: UInt = #line) {
        loadCauldron(state, file: file, line: line)
        let outcome = PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                               stirDirection: BrewSolution.stirDirection,
                                               stirCount: BrewSolution.stirCount,
                                               state: state)
        XCTAssertEqual(outcome, .success, file: file, line: line)
        XCTAssertTrue(PuzzleEngine.fillPhial(state: state), file: file, line: line)
        XCTAssertTrue(PuzzleEngine.pourDraughtOnBasin(state: state), file: file, line: line)
        XCTAssertTrue(PuzzleEngine.slideBoltAndLeave(state: state), file: file, line: line)
        XCTAssertTrue(state.isComplete, file: file, line: line)
    }

    // MARK: - 1. Full solve paths (engine level): graph solve_path_notes orderings A/B/C

    func testSolvePathOrderingA_engineLevel() {
        let state = makeState(tempDir())
        // move rug (free action; no engine flag exists — see QA-BUG-010 report entry)
        setMoonDialsToSolution(state)
        XCTAssertTrue(PuzzleEngine.evaluateMoonDials(state: state))                  // p02
        state.addItem(PuzzleGraph.ItemID.poker)                                      // take poker
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))                          // p06
        XCTAssertTrue(PuzzleEngine.hangWeight(state: state))                         // p07
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove))
        state.addItem(PuzzleGraph.ItemID.cageKey)                                    // take cage key
        XCTAssertTrue(PuzzleEngine.unlockCage(state: state))                         // p11
        pressRunes(state)                                                            // p01
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state)) // p03
        XCTAssertTrue(PuzzleEngine.siftAsh(state: state))                            // p05
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                                     moon: CabinetSolution.moonSlotItem, state: state)) // p04
        XCTAssertTrue(PuzzleEngine.fitCrankAndTurn(state: state))                    // p08
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state) // p09
        XCTAssertTrue(state.evaluateCondition("cond-beam-at-alcove"))
        XCTAssertTrue(PuzzleEngine.pickBlossom(state: state))                        // p10
        state.addItem(PuzzleGraph.ItemID.spoon)                                      // take spoon
        XCTAssertTrue(PuzzleEngine.fileShavings(state: state))                       // p12
        XCTAssertTrue(PuzzleEngine.grindPaste(state: state))                         // p13
        runEndgame(state)                                                            // p14-p17
    }

    func testSolvePathOrderingB_engineLevel() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.poker)
        pressRunes(state)                                                            // p01
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state)) // p03
        XCTAssertTrue(PuzzleEngine.siftAsh(state: state))                            // p05
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                                     moon: CabinetSolution.moonSlotItem, state: state)) // p04
        setMoonDialsToSolution(state)
        XCTAssertTrue(PuzzleEngine.evaluateMoonDials(state: state))                  // p02
        state.addItem(PuzzleGraph.ItemID.spoon)
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))                          // p06
        XCTAssertTrue(PuzzleEngine.hangWeight(state: state))                         // p07
        state.addItem(PuzzleGraph.ItemID.cageKey)
        XCTAssertTrue(PuzzleEngine.fitCrankAndTurn(state: state))                    // p08
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state) // p09
        XCTAssertTrue(PuzzleEngine.pickBlossom(state: state))                        // p10
        XCTAssertTrue(PuzzleEngine.unlockCage(state: state))                         // p11
        XCTAssertTrue(PuzzleEngine.fileShavings(state: state))                       // p12
        XCTAssertTrue(PuzzleEngine.grindPaste(state: state))                         // p13
        runEndgame(state)
    }

    /// Ordering C: mirror set to detent-3 BEFORE the shutter is ever opened.
    /// Exercises D2 / Validator required fix 2 end-to-end.
    func testSolvePathOrderingC_mirrorFirst_engineLevel() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.poker)
        setMoonDialsToSolution(state)
        XCTAssertTrue(PuzzleEngine.evaluateMoonDials(state: state))                  // p02
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state) // p09 FIRST
        XCTAssertFalse(state.evaluateCondition("cond-beam-at-alcove"), "condition must not hold before the shutter opens")
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))                          // p06
        XCTAssertTrue(PuzzleEngine.hangWeight(state: state))                         // p07
        state.addItem(PuzzleGraph.ItemID.cageKey)
        state.addItem(PuzzleGraph.ItemID.spoon)
        pressRunes(state)                                                            // p01
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state)) // p03
        XCTAssertTrue(PuzzleEngine.siftAsh(state: state))                            // p05
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                                     moon: CabinetSolution.moonSlotItem, state: state)) // p04
        XCTAssertTrue(PuzzleEngine.fitCrankAndTurn(state: state))                    // p08: condition latches HERE
        XCTAssertTrue(state.evaluateCondition("cond-beam-at-alcove"), "mirror-first path must latch the condition at p08")
        XCTAssertTrue(PuzzleEngine.pickBlossom(state: state))                        // p10
        XCTAssertTrue(PuzzleEngine.unlockCage(state: state))                         // p11
        XCTAssertTrue(PuzzleEngine.fileShavings(state: state))                       // p12
        XCTAssertTrue(PuzzleEngine.grindPaste(state: state))                         // p13
        runEndgame(state)
    }

    // MARK: - 2. Failure behaviors (graceful, no lockout, nothing consumed)

    func testWrongAstrolabePlateYieldsNothing() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        for plate in [1, 3, 4, 5, 6] {
            XCTAssertFalse(PuzzleEngine.selectAstrolabePlate(plate, state: state), "plate \(plate) must not open the drawer")
        }
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.crank))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.silverCoin))
        // No lockout: correct plate still works.
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state))
    }

    func testSwappedCabinetPlacementRejectedWithoutLoss() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.addItem(PuzzleGraph.ItemID.goldRing)
        state.addItem(PuzzleGraph.ItemID.silverCoin)
        XCTAssertFalse(PuzzleEngine.placeCabinetItems(sun: PuzzleGraph.ItemID.silverCoin,
                                                      moon: PuzzleGraph.ItemID.goldRing, state: state))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.goldRing), "rejected item must return to inventory")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.silverCoin), "rejected item must return to inventory")
        // No lockout.
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: PuzzleGraph.ItemID.goldRing,
                                                     moon: PuzzleGraph.ItemID.silverCoin, state: state))
    }

    func testMoonDialsRetainPositionAfterWrongAttempt() {
        let state = makeState(tempDir())
        state.setMoonDialPosition(dial: 0, phase: 2)
        state.setMoonDialPosition(dial: 1, phase: 5)
        state.setMoonDialPosition(dial: 2, phase: 7)
        XCTAssertFalse(PuzzleEngine.evaluateMoonDials(state: state))
        XCTAssertEqual(state.data.moonDialPositions, [2, 5, 7], "dials must retain position (no reset, no lockout)")
    }

    func testFailedBrewReturnsFeatherPasteShavingsAndIsInfinitelyRetryable() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        for id in BrewSolution.requiredIngredients { state.addItem(id) }
        // Wrong stir direction.
        loadCauldron(state)
        XCTAssertEqual(PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                                stirDirection: .clockwise,
                                                stirCount: BrewSolution.stirCount, state: state), .fizzle)
        for id in BrewSolution.requiredIngredients {
            XCTAssertTrue(state.hasItem(id), "\(id) must be returned intact on fizzle")
        }
        // Wrong stir count.
        loadCauldron(state)
        XCTAssertEqual(PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                                stirDirection: BrewSolution.stirDirection,
                                                stirCount: 4, state: state), .fizzle)
        for id in BrewSolution.requiredIngredients { XCTAssertTrue(state.hasItem(id)) }
        // Then success on the third try.
        loadCauldron(state)
        XCTAssertEqual(PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                                stirDirection: BrewSolution.stirDirection,
                                                stirCount: BrewSolution.stirCount, state: state), .success)
    }

    // MARK: - 3. Red herrings and D3/D4/D1 refusals (coordinator level)

    func testFeedCupRefusesEveryInventoryItemUnspent_D4() {
        for def in ItemCatalog.all {
            let state = makeState(tempDir())
            state.addItem(def.id)
            let before = state.data
            let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
            coordinator.handleExternalDrop(itemID: def.id, hotspotID: "feed-cup")
            XCTAssertEqual(state.data.inventory, before.inventory, "\(def.id) must return to inventory unspent (D4)")
            XCTAssertEqual(state.data.flags, before.flags, "feed-cup offer of \(def.id) must not change flags")
            XCTAssertEqual(state.data.solvedPuzzles, before.solvedPuzzles, "feed-cup offer of \(def.id) must not solve anything")
        }
    }

    func testDraughtMisPourAtFeedCupBlocked_D1_thenBasinPourStillWorks() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.phialDraught)
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.handleExternalDrop(itemID: PuzzleGraph.ItemID.phialDraught, hotspotID: "feed-cup")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phialDraught), "D1 BLOCK: draught must never be spent at the feed cup")
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
        // The rune basin remains the one valid pour target (p16).
        coordinator.handleExternalDrop(itemID: PuzzleGraph.ItemID.phialDraught, hotspotID: "door-lock")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.phialDraught))
    }

    func testCageReachRefusalMutatesNothing_D3() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.rustedKey)
        let before = state.data
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("cage")
        coordinator.scene.onHotspotTap?("cage") // repeat: identical, no escalation state
        XCTAssertEqual(state.data.inventory, before.inventory)
        XCTAssertEqual(state.data.flags, before.flags)
        XCTAssertEqual(state.data.solvedPuzzles, before.solvedPuzzles)
    }

    func testRustedKeyIsPickupableAndUnlocksNothing() {
        let state = makeState(tempDir())
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("rusted-key")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.rustedKey))
        // Rusted key on the star keyhole / cage / door must never free the crow or unseal.
        coordinator.handleExternalDrop(itemID: PuzzleGraph.ItemID.rustedKey, hotspotID: "star-keyhole")
        coordinator.handleExternalDrop(itemID: PuzzleGraph.ItemID.rustedKey, hotspotID: "door-lock")
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.crowFreed))
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.rustedKey), "red-herring key must never be consumed")
    }

    // MARK: - 4. Coordinator tap plumbing (what IS wired works)

    func testHearthTapFlow_pokerPickupAndAshSift() {
        let state = makeState(tempDir())
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("poker")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.poker))
        coordinator.scene.onHotspotTap?("ash")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.goldRing), "p05: poker + ash yields the gold ring")
    }

    func testCellarFlow_barrelHookWinchMirror() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.addItem(PuzzleGraph.ItemID.poker)
        state.addItem(PuzzleGraph.ItemID.crank)
        let coordinator = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("barrel")                                   // p06 (tap fallback with poker held)
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.weight))
        coordinator.handleExternalDrop(itemID: PuzzleGraph.ItemID.weight, hotspotID: "hook") // p07
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove))
        coordinator.scene.onHotspotTap?("winch")                                    // p08
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn))
        coordinator.scene.onHotspotTap?("mirror")                                   // detent 1 -> 2
        coordinator.scene.onHotspotTap?("mirror")                                   // detent 2 -> 3
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.mirrorDetent3))
        XCTAssertTrue(state.evaluateCondition("cond-beam-at-alcove"))
    }

    func testEntryStarKeyholeFreesCrowExactlyOnce() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.cageKey)
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("star-keyhole")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.crowFreed))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.feather))
        state.removeItem(PuzzleGraph.ItemID.feather) // spent into cauldron
        coordinator.scene.onHotspotTap?("star-keyhole")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.feather), "feather is granted exactly once (anti-softlock invariant)")
    }

    // MARK: - 5. Save / resume at arbitrary points (incl. hidden zones), J5

    func testRelaunchMidRuneSequenceContinuesToSolve_J5() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        PuzzleEngine.pressRuneTile(.air, state: state)
        PuzzleEngine.pressRuneTile(.fire, state: state)
        // Simulate exit-to-menu + full app relaunch mid-puzzle.
        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertEqual(resumed.data.runeDoorProgress, ["AIR", "FIRE"], "in-progress rune entry must survive relaunch")
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.earth, state: resumed), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.water, state: resumed), .solved)
        XCTAssertTrue(resumed.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
    }

    func testRelaunchInsideNestedHiddenZoneMidPuzzleLosesNothing() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        // Ordering-C midpoint: inside z3/z4 with mirror pre-set, dials solved, brew pending.
        state.addItem(PuzzleGraph.ItemID.poker)
        setMoonDialsToSolution(state)
        _ = PuzzleEngine.evaluateMoonDials(state: state)
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state)
        _ = PuzzleEngine.pryBarrel(state: state)
        _ = PuzzleEngine.hangWeight(state: state)
        state.addItem(PuzzleGraph.ItemID.cageKey)
        state.setCauldronFlameStage(2)

        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertTrue(resumed.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar))
        XCTAssertTrue(resumed.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove))
        XCTAssertTrue(resumed.hasFlag(PuzzleGraph.StateFlag.mirrorDetent3))
        XCTAssertEqual(resumed.data.mirrorDetent, MirrorSolution.solutionDetent)
        XCTAssertEqual(resumed.data.cauldronFlameStage, 2)
        XCTAssertTrue(resumed.hasItem(PuzzleGraph.ItemID.cageKey))
        // And the mirror-first latch still completes correctly after resume.
        pressRunes(resumed)
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: resumed))
        XCTAssertTrue(PuzzleEngine.fitCrankAndTurn(state: resumed))
        XCTAssertTrue(resumed.evaluateCondition("cond-beam-at-alcove"))
        XCTAssertTrue(PuzzleEngine.pickBlossom(state: resumed))
    }

    func testClockCuckooOneShotLatchSurvivesRelaunch_D5() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertEqual(PuzzleEngine.setClockToTwelve(state: state), .popped)
        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertEqual(PuzzleEngine.setClockToTwelve(state: resumed), .spentAlready, "one-shot pop is per save file")
    }

    func testRestartLevelResetsApparatusPositionsAndFlags() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        setMoonDialsToSolution(state)
        _ = PuzzleEngine.evaluateMoonDials(state: state)
        state.setCauldronFlameStage(3)
        PuzzleEngine.rotateMirror(toDetent: 3, state: state)
        state.restartLevel()
        XCTAssertEqual(state.data.moonDialPositions, [0, 0, 0])
        XCTAssertEqual(state.data.cauldronFlameStage, 0)
        XCTAssertEqual(state.data.mirrorDetent, 1)
        XCTAssertTrue(state.data.flags.isEmpty)
        XCTAssertTrue(state.data.unlockedZones.isEmpty || !state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar))
    }

    func testCompletionBadgeAndResetProgressRoundTrip() {
        let dir = tempDir()
        let store = SaveGameStore(directory: dir)
        let state = GameState(levelID: 1, store: store)
        state.setFlag(PuzzleGraph.StateFlag.doorUnsealed)
        XCTAssertTrue(PuzzleEngine.slideBoltAndLeave(state: state))
        XCTAssertTrue(store.isLevelComplete(1), "completion must propagate to the Level Select badge source")
        store.resetAllProgress()
        XCTAssertFalse(store.isLevelComplete(1))
    }

    // MARK: - 6. QA-BUG records (strict expected failures; see qa-report.md)

    /// QA-BUG-001 (critical) — FIXED: the start zone is unlocked on every GameState
    /// init (fresh save, migration of older saves, and after Restart Level).
    func testQA_BUG_001_freshSessionExposesStartZoneViews() {
        let session = LevelSession(levelID: 1, store: SaveGameStore(directory: tempDir()))
        let views = session.availableViews()
        XCTAssertTrue(views.contains(.hearth), "v-hearth must be reachable from a fresh save")
        XCTAssertTrue(views.contains(.study), "v-study must be reachable from a fresh save")
        XCTAssertTrue(views.contains(.entry), "v-entry must be reachable from a fresh save")
    }

    /// QA-BUG-002 (critical): p15 (bottle the draught) has no interaction path.
    /// PuzzleEngine.fillPhial exists but no scene/UI code ever calls it; dropping the
    /// empty phial on the cauldron is swallowed by the ingredient-only drop handler.
    func testQA_BUG_002_emptyPhialOnReadyCauldronBottlesDraught() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.addItem(PuzzleGraph.ItemID.phial)
        state.setFlag(PuzzleGraph.StateFlag.draughtReady)
        let coordinator = RoomSceneCoordinator(viewID: .bench, state: state, size: sceneSize)
        coordinator.handleExternalDrop(itemID: PuzzleGraph.ItemID.phial, hotspotID: "cauldron")
        // Anti-softlock: whatever happens, the phial must not vanish.
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phial) || state.hasItem(PuzzleGraph.ItemID.phialDraught))
        // FIXED: the cauldron drop handler routes the empty phial to PuzzleEngine.fillPhial.
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phialDraught),
                      "using the empty phial on the ready cauldron must yield itm-phial-draught (p15)")
    }

    /// QA-BUG-003 (critical): p17 (slide bolt and leave) has no interaction path.
    /// No tap handler exists for the door after door-unsealed; PuzzleEngine.slideBoltAndLeave
    /// is never called from scene/UI code, so the level can never be completed in-app.
    func testQA_BUG_003_doorTapAfterUnsealCompletesLevel() {
        let state = makeState(tempDir())
        state.setFlag(PuzzleGraph.StateFlag.doorUnsealed)
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("door-lock")
        // FIXED: once door-unsealed holds, the door tap slides the bolt (p17) and wins.
        XCTAssertTrue(state.isComplete, "tapping the unsealed door/bolt must complete the level (p17)")
    }

    /// QA-BUG-005 (major): tapping the astrolabe hotspot auto-solves p03 — the
    /// coordinator passes the CORRECT plate index itself. There is no six-plate
    /// selection mini-game, so the puzzle's fixed solution (plate-2 / Orion) is never
    /// actually derived or entered by the player.
    func testQA_BUG_005_astrolabeTapMustNotAutoSolve() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        let coordinator = RoomSceneCoordinator(viewID: .cabinet, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("astrolabe")
        // FIXED: a bare tap opens the six-plate close-up; only the player's plate
        // choice reaches the engine.
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion),
                       "a bare tap (no plate chosen) must not solve p03")
        XCTAssertEqual(coordinator.activeCloseUp, .astrolabe, "the tap must open the plate-selection mini-game")
        // The mini-game path: wrong plates reject, the Orion plate solves.
        coordinator.selectAstrolabePlate(4)
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion))
        coordinator.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex)
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.crank))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.silverCoin))
    }

    /// QA-BUG-006 (major): resolveBrew never clears cauldronIngredients on success and
    /// has no already-solved guard, so pressing Stir + Release Ladle again AFTER a
    /// successful brew fizzles and returns paste/shavings/feather to inventory while
    /// draught-ready stays latched — duplicating spent ingredients.
    func testQA_BUG_006_reResolvingAfterSuccessMustNotReturnSpentIngredients() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        for id in BrewSolution.requiredIngredients { state.addItem(id) }
        loadCauldron(state)
        XCTAssertEqual(PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                                stirDirection: BrewSolution.stirDirection,
                                                stirCount: BrewSolution.stirCount, state: state), .success)
        // Player stirs again with wrong parameters after success (reachable via BrewControlView).
        _ = PuzzleEngine.resolveBrew(flameStage: 1, stirDirection: .clockwise, stirCount: 1, state: state)
        // FIXED: success consumes the ingredients into the draught and later resolves
        // are no-ops; draught-ready stays latched.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.feather),
                       "spent feather must not be re-granted by a post-success fizzle")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.paste))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.shavings))
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.draughtReady))
    }

    /// QA-BUG-007 (minor): pickBlossom has no already-solved guard, so after grinding
    /// the blossom into paste the planter grants a second, useless blossom.
    func testQA_BUG_007_blossomNotRegrantableAfterGrinding() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.unlockZone(PuzzleGraph.ZoneID.z4Alcove)
        state.setFlag(PuzzleGraph.StateFlag.moonbeamOn)
        state.setFlag(PuzzleGraph.StateFlag.mirrorDetent3)
        XCTAssertTrue(PuzzleEngine.pickBlossom(state: state))
        XCTAssertTrue(PuzzleEngine.grindPaste(state: state))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.blossom))
        _ = PuzzleEngine.pickBlossom(state: state)
        // FIXED: the already-solved guard prevents re-granting the single blossom.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.blossom),
                       "the single blossom was already picked and consumed (visual state: 'one blossom picked')")
    }

    /// QA-BUG-008 (minor): rotateMirror marks p09-mirror-aim as SOLVED at any detent,
    /// not just detent-3 (the puzzle's fixed solution).
    func testQA_BUG_008_mirrorAimSolvedOnlyAtDetent3() {
        let state = makeState(tempDir())
        PuzzleEngine.rotateMirror(toDetent: 1, state: state)
        // FIXED: only detent-3 marks p09 solved.
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.mirrorAim),
                       "p09 solution_fixed is detent-3; detent-1 must not mark it solved")
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state)
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.mirrorAim))
    }

    /// QA-BUG-009 (major): Hotspot.minHitSize (44) is applied in SCENE PIXELS, not
    /// screen points. Under .aspectFill on the smallest supported iPhone the effective
    /// on-screen hit target of several puzzle-critical hotspots falls well below the
    /// style guide Section 8 floor of >= 44 pt (e.g. star-keyhole ~21 pt tall).
    func testQA_BUG_009_hotspotEffectiveHitTargetsMeet44ptOniPhoneSE() {
        // iPhone SE (3rd gen) landscape: 667 x 375 pt; scene 2732 x 1366, .aspectFill.
        // Plate pixel size is a repo-verified constant (all seven base plates are
        // 2560 x 1280) rather than a bundle load, because QA-BUG-022 makes the plates
        // unreachable through GameAssetLoader in the built bundle.
        let scale = max(667.0 / sceneSize.width, 375.0 / sceneSize.height)
        let plateSize = CGSize(width: 2560, height: 1280)
        var offenders: [String] = []
        for viewID in ViewID.allCases {
            let coordinator = RoomSceneCoordinator(viewID: viewID, state: makeState(tempDir()), size: sceneSize)
            for hotspot in coordinator.scene.hotspots {
                let w = max(hotspot.normalizedRect.width * plateSize.width, hotspot.minHitSize) * scale
                let h = max(hotspot.normalizedRect.height * plateSize.height, hotspot.minHitSize) * scale
                if min(w, h) < 44 {
                    offenders.append("\(viewID.rawValue)/\(hotspot.id) ~\(Int(w))x\(Int(h))pt")
                }
            }
        }
        // FIXED: Hotspot.minHitSceneSize is 44 pt converted at the smallest supported
        // device's .aspectFill scale, so every hotspot clears the floor in points.
        XCTAssertTrue(offenders.isEmpty, "hotspots below the 44pt floor on iPhone SE: \(offenders.joined(separator: "; "))")
    }

    /// QA-BUG-022 (critical): no game art is reachable through GameAssetLoader in the
    /// built app bundle (empirically: image(named:) returns nil for every base plate in
    /// the hosted test runner, whose Bundle.main IS the app bundle). GameAssetLoader
    /// expects GameAssets/ and Audio/ directory trees under the bundle resource root,
    /// but the pbxproj ships Resources via a file-system-synchronized group, which does
    /// not preserve that folder hierarchy. Consequence in the shipped app: every
    /// RoomScene base texture is nil (black scenes) AND configureHotspots() returns
    /// early without creating hotspot nodes, so scene tap targets are dead too.
    func testQA_BUG_022_gameArtReachableThroughAssetLoaderInAppBundle() {
        // FIXED: Resources/GameAssets and Resources/Audio ship as folder REFERENCES
        // (hierarchy-preserving) instead of a file-system-synchronized group.
        for plate in ["z1-hearth-base", "z1-study-base", "z1-entry-base", "z2-bench-base",
                      "z2-cabinet-base", "z3-cellar-base", "z4-alcove-base", "dial-face"] {
            XCTAssertNotNil(GameAssetLoader.shared.image(named: plate),
                            "\(plate) must be loadable from the app bundle at runtime")
        }
        // Audio must ship the same way (SoundManager subdirectory lookup).
        XCTAssertNotNil(Bundle.main.url(forResource: "sfx-click", withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "sfx-click", withExtension: "wav"),
                        "sfx-click.wav must be loadable from the app bundle at runtime")
    }

    /// QA-BUG-004 (critical, iPad): several puzzle-critical hotspots sit outside the
    /// dual-safe zone (style guide Section 8). Under .aspectFill the iPad 4:3 frame
    /// crops the 2:1 plate to roughly the central 2/3; hotspots (and the art they
    /// cover: cage star-keyhole, feed cup, barrel, astrolabe) are partly or wholly
    /// OFF-SCREEN on the primary device.
    func testQA_BUG_004_criticalHotspotsInsideDualSafeZone() {
        // iPad Pro 13" landscape: 1376 x 1032 pt. .aspectFill scale is height-bound
        // (1032/1366); visible scene width = 1376 / scale ~= 1821 of 2732. The base
        // plates are 2560 px wide, centered in the 2732-wide scene.
        let iPadScale = max(1376.0 / sceneSize.width, 1032.0 / sceneSize.height)
        let halfVisibleScene = (1376.0 / iPadScale) / 2.0
        let plateWidth: CGFloat = 2560
        let minVisibleX = (plateWidth / 2 - halfVisibleScene) / plateWidth   // ~0.144
        let maxVisibleX = 1 - minVisibleX                                    // ~0.856

        // (Hotspot inventory updated in the fix pass: per-tile rune hotspots became the
        // single "rune-door" close-up trigger; the bench gained "workbench" for p12.)
        let critical: [ViewID: [String]] = [
            .hearth: ["poker", "ash", "clock", "bellows", "lintel", "trapdoor-dial"],
            .study: ["grimoire", "triptych", "flowerpot", "rune-door"],
            .entry: ["door-lock", "rusted-key", "windowsill", "cage", "feed-cup", "star-keyhole"],
            .bench: ["cauldron", "floor-bellows", "ladle", "mortar", "workbench"],
            .cabinet: ["sun-slot", "moon-slot", "astrolabe", "window", "potion-shelf"],
            .cellar: ["barrel", "drawer", "hook", "winch", "mirror"],
            .alcove: ["planter", "statue-key"],
        ]
        var offenders: [String] = []
        for (viewID, ids) in critical {
            let coordinator = RoomSceneCoordinator(viewID: viewID, state: makeState(tempDir()), size: sceneSize)
            for hotspot in coordinator.scene.hotspots where ids.contains(hotspot.id) {
                let r = hotspot.normalizedRect
                if r.minX < minVisibleX || r.maxX > maxVisibleX {
                    offenders.append("\(viewID.rawValue)/\(hotspot.id) x:[\(String(format: "%.2f", r.minX)),\(String(format: "%.2f", r.maxX))]")
                }
            }
        }
        // STILL OPEN (deliberately): the user chose an ART RE-FRAME fix for QA-BUG-004.
        // The Asset Generation agent is re-framing the offending plates (z1 v-entry,
        // z3 v-cellar, z1 hearth bellows region, z2 cabinet potion-shelf/astrolabe/
        // window region); the affected hotspots keep their old out-of-band values
        // until that batch lands, at which point this expected failure gets unwrapped
        // together with the final hotspot alignment.
        XCTExpectFailure("QA-BUG-004: awaiting the art re-frame batch; affected plates' hotspots aligned last") {
            XCTAssertTrue(offenders.isEmpty, "outside dual-safe zone: \(offenders.joined(separator: "; "))")
        }
    }
}
