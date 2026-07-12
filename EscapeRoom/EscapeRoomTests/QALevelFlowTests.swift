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

    /// Feedback round 1 (clue-gating rev 1.3): engine-level solve paths bypass the
    /// close-up UI that records clue views, so a gated puzzle would (correctly) refuse
    /// its solution. This marks every gating clue viewed — the player-opened-all-clues
    /// analogue — so solve-path assertions still exercise the SOLVE grammar. Dedicated
    /// gating tests (in PuzzleEngineTests) do NOT call this.
    private func satisfyAllGates(_ state: GameState) {
        for clueID in [ClueID.markAir, ClueID.markFire, ClueID.markEarth, ClueID.markWater,
                       ClueID.grimoireElements, ClueID.triptych, ClueID.windowOrion,
                       ClueID.slotShapes, ClueID.recipePage] {
            state.markClueViewed(clueID)
        }
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

    /// Feedback round 1 (F-023): container yields are collected manually after the
    /// solve. Engine-level solve paths therefore collect explicitly, exactly like a
    /// player tapping each visible item.
    private func collectAstrolabeYield(_ state: GameState, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.silverCoin, from: .astrolabeDrawer, state: state),
                      file: file, line: line)
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer, state: state),
                      file: file, line: line)
    }

    /// R2-003a: sifting reveals the ring; a player then collects it with an explicit tap.
    /// This helper mirrors that two-step flow so the full-playthrough tests obtain the
    /// gold ring exactly as a human does (test-like-a-player mandate).
    private func siftAndCollectRing(_ state: GameState, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(PuzzleEngine.siftAsh(state: state), file: file, line: line)
        XCTAssertTrue(PuzzleEngine.isRingUncollectedInAsh(state), file: file, line: line)
        XCTAssertTrue(PuzzleEngine.collectAshRing(state), file: file, line: line)
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.goldRing), file: file, line: line)
    }

    private func collectCabinetYield(_ state: GameState, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.file, from: .sunMoonCabinet, state: state),
                      file: file, line: line)
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.phial, from: .sunMoonCabinet, state: state),
                      file: file, line: line)
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
        satisfyAllGates(state) // rev 1.3 clue-gating: all gate clues "viewed" for the engine path
        // move rug (free action; no engine flag exists — see QA-BUG-010 report entry)
        setMoonDialsToSolution(state)
        XCTAssertTrue(PuzzleEngine.evaluateMoonDials(state: state))                  // p02
        state.addItem(PuzzleGraph.ItemID.poker)                                      // take poker
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))                          // p06
        // Ordering A pries the barrel BEFORE sifting the ash (p05 comes later) — the
        // R4-019 soft-lock ordering. The poker MUST survive p06 (p05 still pending).
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.poker),
                      "R4-019: poker retained after p06 while p05 is unsatisfied")
        XCTAssertTrue(PuzzleEngine.collectBarrelWeight(state))                       // manual pickup (R4-013)
        XCTAssertTrue(PuzzleEngine.hangWeight(state: state))                         // p07
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove))
        state.addItem(PuzzleGraph.ItemID.cageKey)                                    // take cage key
        XCTAssertTrue(PuzzleEngine.unlockCage(state: state))                         // p11
        pressRunes(state)                                                            // p01
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state)) // p03
        collectAstrolabeYield(state)
        siftAndCollectRing(state)                                                    // p05
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                                     moon: CabinetSolution.moonSlotItem, state: state)) // p04
        collectCabinetYield(state)
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
        satisfyAllGates(state) // rev 1.3 clue-gating
        state.addItem(PuzzleGraph.ItemID.poker)
        pressRunes(state)                                                            // p01
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state)) // p03
        collectAstrolabeYield(state)
        siftAndCollectRing(state)                                                    // p05
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                                     moon: CabinetSolution.moonSlotItem, state: state)) // p04
        collectCabinetYield(state)
        setMoonDialsToSolution(state)
        XCTAssertTrue(PuzzleEngine.evaluateMoonDials(state: state))                  // p02
        state.addItem(PuzzleGraph.ItemID.spoon)
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))                          // p06
        XCTAssertTrue(PuzzleEngine.collectBarrelWeight(state))                       // manual pickup (R4-013)
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
        satisfyAllGates(state) // rev 1.3 clue-gating
        state.addItem(PuzzleGraph.ItemID.poker)
        setMoonDialsToSolution(state)
        XCTAssertTrue(PuzzleEngine.evaluateMoonDials(state: state))                  // p02
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state) // p09 FIRST
        XCTAssertFalse(state.evaluateCondition("cond-beam-at-alcove"), "condition must not hold before the shutter opens")
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))                          // p06
        XCTAssertTrue(PuzzleEngine.collectBarrelWeight(state))                       // manual pickup (R4-013)
        XCTAssertTrue(PuzzleEngine.hangWeight(state: state))                         // p07
        state.addItem(PuzzleGraph.ItemID.cageKey)
        state.addItem(PuzzleGraph.ItemID.spoon)
        pressRunes(state)                                                            // p01
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state)) // p03
        collectAstrolabeYield(state)
        siftAndCollectRing(state)                                                    // p05
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                                     moon: CabinetSolution.moonSlotItem, state: state)) // p04
        collectCabinetYield(state)
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
        satisfyAllGates(state) // isolate wrong-vs-correct plate from the clue gate
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
        satisfyAllGates(state) // isolate swapped-vs-correct from the clue gate
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
        satisfyAllGates(state) // isolate wrong-vs-correct params from the recipe gate
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
            coordinator.useItem(def.id, on: "feed-cup")
            XCTAssertEqual(state.data.inventory, before.inventory, "\(def.id) must return to inventory unspent (D4)")
            XCTAssertEqual(state.data.flags, before.flags, "feed-cup offer of \(def.id) must not change flags")
            XCTAssertEqual(state.data.solvedPuzzles, before.solvedPuzzles, "feed-cup offer of \(def.id) must not solve anything")
        }
    }

    func testDraughtMisPourAtFeedCupBlocked_D1_thenBasinPourStillWorks() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.phialDraught)
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.phialDraught, on: "feed-cup")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phialDraught), "D1 BLOCK: draught must never be spent at the feed cup")
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
        // The rune basin remains the one valid pour target (p16).
        coordinator.useItem(PuzzleGraph.ItemID.phialDraught, on: "door-lock")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.phialDraught))
    }

    /// UPDATED for the select-then-tap model (feedback round 1): a BARE cage tap is
    /// now a neutral look (F-011); the D3 refusal fires on a deliberate armed-item
    /// reach. Both must leave state untouched.
    func testCageReachRefusalMutatesNothing_D3() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.rustedKey)
        state.addItem(PuzzleGraph.ItemID.poker)
        let before = state.data
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("cage") // bare look: neutral pose, no churn
        coordinator.useItem(PuzzleGraph.ItemID.poker, on: "cage") // reach: refusal
        coordinator.useItem(PuzzleGraph.ItemID.poker, on: "cage") // repeat: identical, no escalation state
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
        coordinator.useItem(PuzzleGraph.ItemID.rustedKey, on: "star-keyhole")
        coordinator.useItem(PuzzleGraph.ItemID.rustedKey, on: "door-lock")
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.crowFreed))
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.rustedKey), "red-herring key must never be consumed")
    }

    // MARK: - 4. Coordinator plumbing (what IS wired works; select-then-tap model)

    func testHearthFlow_pokerPickupAndArmedAshSift() {
        let state = makeState(tempDir())
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize,
                                               interaction: interaction)
        coordinator.scene.onHotspotTap?("poker")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.poker))
        interaction.armedItem = PuzzleGraph.ItemID.poker // player arms the poker
        coordinator.scene.onHotspotTap?("ash")
        // R2-003a: sifting reveals the ring; the player collects it with an explicit tap.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.goldRing), "ring is revealed, not auto-granted")
        XCTAssertTrue(PuzzleEngine.isRingUncollectedInAsh(state))
        coordinator.collectAshRing()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.goldRing), "p05: explicit tap collects the gold ring")
    }

    func testCellarFlow_barrelHookWinchMirror() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.addItem(PuzzleGraph.ItemID.poker)
        state.addItem(PuzzleGraph.ItemID.crank)
        let coordinator = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.poker, on: "barrel")                 // p06
        // Build 10 (R4-013): the weight is REVEALED in the pried barrel (close-up
        // presented) and collected with its own explicit tap — no auto-grant.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.weight), "weight revealed, not auto-granted")
        XCTAssertEqual(coordinator.activeCloseUp, .barrel)
        XCTAssertTrue(PuzzleEngine.isWeightUncollectedInBarrel(state))
        coordinator.collectBarrelWeight()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.weight))
        coordinator.dismissCloseUp()
        coordinator.useItem(PuzzleGraph.ItemID.weight, on: "hook")                  // p07
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove))
        coordinator.useItem(PuzzleGraph.ItemID.crank, on: "winch")                  // p08
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn))
        coordinator.scene.onHotspotTap?("mirror")                                   // detent 1 -> 2
        coordinator.scene.onHotspotTap?("mirror")                                   // detent 2 -> 3
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.mirrorDetent3))
        XCTAssertTrue(state.evaluateCondition("cond-beam-at-alcove"))
    }

    func testEntryStarKeyUseFreesCrowExactlyOnce() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.cageKey)
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.cageKey, on: "star-keyhole")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.crowFreed))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.feather))
        state.removeItem(PuzzleGraph.ItemID.feather) // spent into cauldron
        coordinator.useItem(PuzzleGraph.ItemID.cageKey, on: "star-keyhole")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.feather), "feather is granted exactly once (anti-softlock invariant)")
    }

    // MARK: - 5. Save / resume at arbitrary points (incl. hidden zones), J5

    func testRelaunchMidRuneSequenceContinuesToSolve_J5() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        satisfyAllGates(state) // clue-viewed flags must persist across relaunch (D7/IC-2)
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
        satisfyAllGates(state) // clue gates satisfied + persisted through the relaunch
        // Ordering-C midpoint: inside z3/z4 with mirror pre-set, dials solved, brew pending.
        state.addItem(PuzzleGraph.ItemID.poker)
        setMoonDialsToSolution(state)
        _ = PuzzleEngine.evaluateMoonDials(state: state)
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state)
        _ = PuzzleEngine.pryBarrel(state: state)
        _ = PuzzleEngine.collectBarrelWeight(state) // manual pickup (R4-013)
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
        collectAstrolabeYield(resumed)
        XCTAssertTrue(PuzzleEngine.fitCrankAndTurn(state: resumed))
        XCTAssertTrue(resumed.evaluateCondition("cond-beam-at-alcove"))
        XCTAssertTrue(PuzzleEngine.pickBlossom(state: resumed))
    }

    func testClockIsInertAfterCuckooRemoval_Q3() {
        // Q3: the cuckoo is gone; the clock never gates progression and the level is
        // still completable without ever touching it (covered by the full-playthrough
        // tests, none of which touch the clock). Assert the clock render is inert.
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertEqual(RoomVisuals.clockState(state), "cu-clock-unspent")
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
        coordinator.useItem(PuzzleGraph.ItemID.phial, on: "cauldron")
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
        satisfyAllGates(state) // rev 1.3: the Orion plate must solve once ungated
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
        // Feedback round 1 (F-023/F-018): the drawer springs open with the coin +
        // crank visible; each is collected with its own tap (no auto-grant).
        XCTAssertEqual(coordinator.activeCloseUp, .container(.astrolabeDrawer))
        coordinator.collectContainerItem(PuzzleGraph.ItemID.silverCoin, from: .astrolabeDrawer)
        coordinator.collectContainerItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer)
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
        satisfyAllGates(state) // the brew must succeed to reach the re-resolve guard
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
    /// screen points. On the smallest supported iPhone the effective on-screen hit target of
    /// several puzzle-critical hotspots must still clear the style guide Section 8 floor of
    /// >= 44 pt (e.g. star-keyhole ~21 pt tall pre-fix).
    ///
    /// BUILD 9 LETTERBOX FOLLOW-UP: the scene is now `.aspectFit`, so the iPhone SE scale is
    /// the MIN ratio (0.24414, width-bound), SMALLER than the old `.aspectFill` MAX (0.27452).
    /// The floor was re-derived at this smaller scale (Hotspot.minHitSceneSize raised
    /// 168 -> 182 = 44/0.24414 rounded up), so this asserts every hotspot still clears 44 pt
    /// under the letterboxed presentation on the tightest device.
    func testQA_BUG_009_hotspotEffectiveHitTargetsMeet44ptOniPhoneSE() {
        // iPhone SE (3rd gen) landscape: 667 x 375 pt; scene 2732 x 1366. BUILD 10: the
        // presentation is `.aspectFill` again (letterbox removed), so the per-scene-pixel
        // scale is the MAX ratio (cover) = max(667/2732, 375/1366) = 0.2745, LARGER than the
        // interim letterbox min (0.2441). A hotspot that clears 44 pt at this scale clears it
        // on every larger device too; the 182-scene-px minHit floor gives 182*0.2745 = 50 pt.
        let scale = max(667.0 / sceneSize.width, 375.0 / sceneSize.height)
        // Hotspot nodes are sized in SCENE space (RoomScene.configureHotspots uses the scene
        // size 2732x1366 as baseSize), so measure the on-screen hit target against that.
        let plateSize = sceneSize
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
        // Audio must ship the same way (SoundManager subdirectory lookup). Every LIVE
        // Effect case must resolve. Build 10 (cluster D + R4-002/003) REMOVED from the
        // bundle: sfx-wood (surviving default-nav "psh"), sfx-entry ("ocean waves"
        // swell), amb-z1..z4 (per-zone beds — level audio is music only), sfx-menu-tap
        // (disliked tick); sfx-seat (positive placement cue) was ADDED. Their absence
        // is asserted by the build-10 regression guard in PuzzleEngineTests.
        for effect in ["sfx-pickup", "sfx-wrong", "sfx-solve", "sfx-unlock", "sfx-refusal",
                       "sfx-clack", "sfx-fizzle", "sfx-page", "sfx-stone", "sfx-tick",
                       "sfx-seat", "sfx-grind", "sfx-bellows", "sfx-stir", "sfx-cloth",
                       "sfx-door", "sfx-menu-confirm", "music-level1"] {
            XCTAssertNotNil(Bundle.main.url(forResource: effect, withExtension: "wav", subdirectory: "Audio")
                ?? Bundle.main.url(forResource: effect, withExtension: "wav"),
                            "\(effect).wav must be loadable from the app bundle at runtime")
        }
        XCTAssertNil(Bundle.main.url(forResource: "sfx-click", withExtension: "wav", subdirectory: "Audio"),
                     "the retired generic interaction click must not ship (F-005)")
    }

    /// QA-BUG-004 (critical, iPad) — RECONCILED for the INTERIM iPad LETTERBOX (build 9
    /// follow-up).
    ///
    /// ORIGINAL failure: under `.aspectFill` the iPad 4:3 frame cropped the 2:1 plate to
    /// roughly its central 2/3, pushing edge hotspots (flowerpot, potion shelf, windowsill,
    /// mirror, winch, mortar, astrolabe, cage, feed cup, ladder, barrel …) OFF-SCREEN on the
    /// PRIMARY device — the level was uncompletable on iPad. The build-3 art regeneration had
    /// dropped BUG-004's dual-safe-zone re-framing, so a strict `XCTExpectFailure` tracked
    /// the owed Asset-Gen re-frame.
    ///
    /// NEW invariant (letterbox): the room scene is now presented `.aspectFit` (RoomScene),
    /// so the WHOLE 2:1 plate is visible on every device — on iPad, letterboxed with dark
    /// bars top+bottom instead of cropped left/right. There is therefore NO horizontal crop:
    /// the visible band under `.aspectFit` is the entire plate, x∈[0,1] AND y∈[0,1]. The real
    /// requirement QA-BUG-004 was always about — "no puzzle-critical element is cropped
    /// off-screen on iPad" — is now SATISFIED by construction, so this is a PERMANENT passing
    /// assertion again (no `XCTExpectFailure`).
    ///
    /// This asserts every critical hotspot lies fully within the letterboxed-visible plate
    /// bounds (a tiny epsilon guards against sub-pixel rect maxima at exactly 1.0). NOTE: the
    /// build-10 permanent fix re-frames the plates into the §8 iPad 4:3 dual-safe band so
    /// `.aspectFill` can return WITHOUT the letterbox; if/when that lands, this test tightens
    /// back to the dual-safe band and the presentation flips to `.aspectFill`.
    func testQA_BUG_004_criticalHotspotsInsideDualSafeZone() {
        // BUILD 10: `.aspectFill` restored on the re-framed plates. A critical element is
        // reachable on BOTH devices iff its hotspot CENTER lies inside the dual-safe band
        // (iPad-4:3 ∩ iPhone-19.5:9 crops) — Reframe.dualSafeX / dualSafeY from the manifest.
        // The reframe was designed to bring every interactive ART element into that band; the
        // hotspots here are already remapped by the same transform (configure* wraps them in
        // Reframe.map), so this asserts the reframe + remap landed correctly.
        //
        // EXCLUDED (redundant access, so a frame-edge position is acceptable — verified
        // separately): `ladder` and the alcove/cellar diegetic passages have the always-
        // present chrome down-chevron (`zone-exit`, GameRoomView.singleViewExitTarget) as
        // their real iPad exit; `workbench` is a SECONDARY p12 path (the primary combine is
        // the inventory combine gesture). Both are covered by other tests.
        let critical: [ViewID: [String]] = [
            .hearth: ["poker", "ash", "clock", "bellows", "lintel", "trapdoor-dial"],
            .study: ["grimoire", "triptych-1", "triptych-2", "triptych-3", "flowerpot", "rune-door"],
            .entry: ["door-lock", "rusted-key", "windowsill", "cage", "feed-cup", "star-keyhole"],
            .bench: ["cauldron", "floor-bellows", "ladle", "mortar"],
            .cabinet: ["sun-slot", "moon-slot", "astrolabe", "window", "potion-shelf"],
            .cellar: ["barrel", "drawer", "hook", "winch", "mirror"],
            .alcove: ["planter", "statue-key"],
        ]
        var offenders: [String] = []
        for (viewID, ids) in critical {
            let coordinator = RoomSceneCoordinator(viewID: viewID, state: makeState(tempDir()), size: sceneSize)
            for hotspot in coordinator.scene.hotspots where ids.contains(hotspot.id) {
                let r = hotspot.normalizedRect
                let cx = r.midX, cy = r.midY
                if !Reframe.dualSafeX.contains(cx) || !Reframe.dualSafeY.contains(cy) {
                    offenders.append("\(viewID.rawValue)/\(hotspot.id) center:(\(String(format: "%.3f", cx)),\(String(format: "%.3f", cy)))")
                }
            }
        }
        XCTAssertTrue(offenders.isEmpty,
                      "puzzle-critical element center outside the iPad dual-safe band under .aspectFill (BUG-004): \(offenders.joined(separator: "; "))")
    }

    // MARK: - R3-005 player-style hotspot verification (build 9)

    /// R3-005: tapping WHERE A HUMAN SEES each element (its visual position on the build-3
    /// plate) must resolve to that element's hotspot — the exact failure the user hit
    /// (rune marks not inspectable R3-004; taps landing on the wrong/stale target). Each
    /// (view, id, nx, ny) point below is a spot the element is clearly VISIBLE at in the
    /// build-3 art; the assertion drives the real scene hit-test (smallest-area-wins).
    func testTapsAtVisibleElementPositionsHitTheirHotspots_R3_005() {
        // BUILD 10: these points are authored where each element VISUALLY sat on the OLD
        // framing; the re-frame moved every element by its view transform, so the tap points
        // are reframed by the SAME transform (mirroring what a human sees on the new plate)
        // before hit-testing the (also-reframed) hotspots.
        let cases: [(ViewID, String, CGFloat, CGFloat)] = [
            // hearth
            (.hearth, "poker", 0.248, 0.50), (.hearth, "ash", 0.44, 0.68),
            (.hearth, "clock", 0.405, 0.10), (.hearth, "bellows", 0.613, 0.53),
            (.hearth, "lintel", 0.585, 0.275),
            // study — the four p01 element/clue targets that were un-tappable (R3-004)
            (.study, "grimoire", 0.46, 0.66), (.study, "triptych-1", 0.257, 0.29),
            (.study, "triptych-2", 0.377, 0.30), (.study, "triptych-3", 0.472, 0.32),
            (.study, "flowerpot", 0.10, 0.78), (.study, "rune-door", 0.762, 0.52),
            // entry — WATER mark (R3-004) + door/cage
            (.entry, "windowsill", 0.105, 0.62), (.entry, "door-lock", 0.58, 0.31),
            (.entry, "rusted-key", 0.715, 0.53), (.entry, "cage", 0.88, 0.20),
            (.entry, "feed-cup", 0.90, 0.475), (.entry, "star-keyhole", 0.81, 0.385),
            // bench
            (.bench, "cauldron", 0.315, 0.54), (.bench, "mortar", 0.84, 0.55),
            (.bench, "floor-bellows", 0.19, 0.86),
            // cabinet
            (.cabinet, "sun-slot", 0.465, 0.475), (.cabinet, "moon-slot", 0.58, 0.475),
            (.cabinet, "astrolabe", 0.79, 0.52), (.cabinet, "window", 0.93, 0.31),
            (.cabinet, "potion-shelf", 0.20, 0.37),
            // cellar
            (.cellar, "barrel", 0.735, 0.66), (.cellar, "drawer", 0.555, 0.40),
            (.cellar, "hook", 0.23, 0.33), (.cellar, "winch", 0.195, 0.10),
            (.cellar, "mirror", 0.13, 0.62),
            // alcove
            (.alcove, "planter", 0.57, 0.76), (.alcove, "statue-key", 0.605, 0.31),
        ]
        var misses: [String] = []
        for (viewID, id, nx, ny) in cases {
            let coordinator = RoomSceneCoordinator(viewID: viewID, state: makeState(tempDir()), size: sceneSize)
            let p = Reframe.transform(for: viewID).map(CGRect(x: nx, y: ny, width: 0, height: 0))
            let hit = coordinator.scene.hotspotIDAtNormalized(p.minX, p.minY)
            if hit != id {
                misses.append("\(viewID.rawValue): tap at (\(nx),\(ny))->(\(String(format: "%.3f", p.minX)),\(String(format: "%.3f", p.minY))) on '\(id)' hit '\(hit ?? "nil")'")
            }
        }
        XCTAssertTrue(misses.isEmpty, "player-style taps missed the visible element:\n" + misses.joined(separator: "\n"))
    }

    /// R3-005: the cuckoo was REMOVED (Q3). Tapping LEFT of the clock — where the stale
    /// cuckoo close-up used to open — must hit NOTHING (empty stone), and the clock hotspot
    /// must cover only the clock itself. This is the exact "tapping left of the clock opens
    /// the old cuckoo close-up" bug the user reported.
    func testTapLeftOfClockHitsNothing_R3_005_cuckooRemoved() {
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: makeState(tempDir()), size: sceneSize)
        let hT = Reframe.transform(for: .hearth)
        func h(_ x: CGFloat, _ y: CGFloat) -> (CGFloat, CGFloat) {
            let p = hT.map(CGRect(x: x, y: y, width: 0, height: 0)); return (p.minX, p.minY)
        }
        // Empty stone left of the clock (old cuckoo-hotspot territory, x~0.28), reframed.
        let left = h(0.28, 0.10)
        XCTAssertNil(coordinator.scene.hotspotIDAtNormalized(left.0, left.1),
                     "tapping left of the clock must do nothing (no stale cuckoo close-up)")
        // The clock itself is hit on its face (reframed).
        let face = h(0.405, 0.10)
        XCTAssertEqual(coordinator.scene.hotspotIDAtNormalized(face.0, face.1), "clock")
        // No cuckoo asset ships anymore.
        XCTAssertNil(GameAssetLoader.shared.image(named: "cu-clock-pop"),
                     "cu-clock-pop must not ship (Q3 cuckoo removed)")
        XCTAssertNil(GameAssetLoader.shared.image(named: "cu-clock-spent"),
                     "cu-clock-spent must not ship (Q3 cuckoo removed)")
    }

    /// R3-005 + R3-007: p01 is solvable end-to-end via the rune door once the correct tiles
    /// are pressed in the fixed order. Drives the coordinator's real tile-press path (the
    /// same call the close-up UI makes), proving the press-plate resolves the puzzle.
    func testRuneDoorSolvableByPressingCorrectTiles_p01() {
        let state = makeState(tempDir())
        satisfyAllGates(state) // a thorough player has viewed the grimoire + marks (rev 1.3)
        let coordinator = RoomSceneCoordinator(viewID: .study, state: state, size: sceneSize)
        // Fixed solution order AIR, FIRE, EARTH, WATER == tiles 3,1,4,2
        // (RuneDoorSolution.tileRune / solutionOrder).
        let tilesForSolution = RuneDoorSolution.solutionOrder.map { rune in
            RuneDoorSolution.tileRune.first(where: { $0.value == rune })!.key
        }
        for tile in tilesForSolution {
            coordinator.pressRuneTile(tile)
        }
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.runeDoor),
                      "pressing the correct tiles in order must solve p01 (rune door)")
    }
}
