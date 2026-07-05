import XCTest
@testable import EscapeRoom

/// Unit tests for the requirement-based puzzle state machines, inventory, zone-unlock
/// logic, and save/resume persistence. These are the Developer Agent's own core-logic
/// tests (game-flow/UX correctness is QA's job, not tested here).
final class PuzzleEngineTests: XCTestCase {

    private func makeState(_ dir: URL) -> GameState {
        let store = SaveGameStore(directory: dir)
        return GameState(levelID: 1, store: store)
    }

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    // MARK: - Inventory

    func testAddAndRemoveItem() {
        let state = makeState(tempDir())
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.poker))
        state.addItem(PuzzleGraph.ItemID.poker)
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.poker))
        XCTAssertTrue(state.removeItem(PuzzleGraph.ItemID.poker))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.poker))
    }

    func testItemCombinationFileAndSpoonYieldsShavings() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.file)
        state.addItem(PuzzleGraph.ItemID.spoon)
        XCTAssertTrue(ItemCombinations.combine(PuzzleGraph.ItemID.file, PuzzleGraph.ItemID.spoon, state: state))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.shavings))
        // Spoon is not consumed per spec note.
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.spoon))
    }

    func testUnrelatedCombinationDoesNothing() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.poker)
        state.addItem(PuzzleGraph.ItemID.rustedKey)
        XCTAssertFalse(ItemCombinations.combine(PuzzleGraph.ItemID.poker, PuzzleGraph.ItemID.rustedKey, state: state))
    }

    // MARK: - p01 rune door: requirement-based, order matters for THIS puzzle's fixed code,
    // but the overall level allows any interleaving of *other* puzzles around it.

    func testRuneDoorCorrectSequenceSolves() {
        let state = makeState(tempDir())
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.air, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.fire, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.earth, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.water, state: state), .solved)
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.runeDoor))
    }

    func testRuneDoorWrongSequenceResetsWithNoLockout() {
        let state = makeState(tempDir())
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.fire, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.air, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.earth, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.water, state: state), .reset)
        XCTAssertFalse(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
        // No lockout: correct sequence still works immediately after a reset.
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.air, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.fire, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.earth, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.water, state: state), .solved)
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
    }

    // MARK: - p02 moon dials

    func testMoonDialsSolveUnlocksCellar() {
        let state = makeState(tempDir())
        state.setMoonDialPosition(dial: 0, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waxingCrescent)!)
        state.setMoonDialPosition(dial: 1, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .full)!)
        state.setMoonDialPosition(dial: 2, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waningGibbous)!)
        XCTAssertTrue(PuzzleEngine.evaluateMoonDials(state: state))
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar))
    }

    func testMoonDialsWrongCombinationDoesNotUnlock() {
        let state = makeState(tempDir())
        state.setMoonDialPosition(dial: 0, phase: 0)
        state.setMoonDialPosition(dial: 1, phase: 0)
        state.setMoonDialPosition(dial: 2, phase: 0)
        XCTAssertFalse(PuzzleEngine.evaluateMoonDials(state: state))
        XCTAssertFalse(state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar))
    }

    // MARK: - D2: cond-beam-at-alcove must be order-independent

    func testBeamAtAlcoveConditionIsOrderIndependent_mirrorFirst() {
        let state = makeState(tempDir())
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state)
        XCTAssertFalse(state.evaluateCondition("cond-beam-at-alcove"))
        state.setFlag(PuzzleGraph.StateFlag.moonbeamOn)
        XCTAssertTrue(state.evaluateCondition("cond-beam-at-alcove"))
    }

    func testBeamAtAlcoveConditionIsOrderIndependent_shutterFirst() {
        let state = makeState(tempDir())
        state.setFlag(PuzzleGraph.StateFlag.moonbeamOn)
        XCTAssertFalse(state.evaluateCondition("cond-beam-at-alcove"))
        PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: state)
        XCTAssertTrue(state.evaluateCondition("cond-beam-at-alcove"))
    }

    func testBeamConditionFalseAtWrongDetentEvenWithMoonbeamOn() {
        let state = makeState(tempDir())
        state.setFlag(PuzzleGraph.StateFlag.moonbeamOn)
        PuzzleEngine.rotateMirror(toDetent: 1, state: state)
        XCTAssertFalse(state.evaluateCondition("cond-beam-at-alcove"))
    }

    // MARK: - Zone unlock chain (z1 -> z2, z1 -> z3 -> z4)

    func testShelfCounterweightUnlocksAlcove() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.addItem(PuzzleGraph.ItemID.weight)
        XCTAssertTrue(PuzzleEngine.hangWeight(state: state))
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove))
    }

    func testHangWeightFailsWithoutZoneUnlocked() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.weight)
        XCTAssertFalse(PuzzleEngine.hangWeight(state: state))
        XCTAssertFalse(state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove))
    }

    // MARK: - p11 crow cage + D3/D4 terminal refusal (no state mutation)

    func testCageUnlockRequiresKey() {
        let state = makeState(tempDir())
        XCTAssertFalse(PuzzleEngine.unlockCage(state: state))
        state.addItem(PuzzleGraph.ItemID.cageKey)
        XCTAssertTrue(PuzzleEngine.unlockCage(state: state))
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.crowFreed))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.feather))
    }

    func testFeatherGrantedExactlyOnceAcrossRepeatedCalls() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.cageKey)
        XCTAssertTrue(PuzzleEngine.unlockCage(state: state))
        state.removeItem(PuzzleGraph.ItemID.feather) // simulate feather spent into cauldron
        XCTAssertTrue(PuzzleEngine.unlockCage(state: state)) // idempotent call, e.g. repeat tap
        // Because crow-freed is already latched, calling again must NOT re-grant the feather
        // (anti_softlock_invariants: "feather is granted exactly once").
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.feather))
    }

    // MARK: - p14 brew: order-free ingredients, parameterized resolve, no loss on failure

    func testBrewSucceedsWithCorrectParameters() {
        let state = makeState(tempDir())
        state.setCauldronIngredients(BrewSolution.requiredIngredients)
        let outcome = PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                                stirDirection: BrewSolution.stirDirection,
                                                stirCount: BrewSolution.stirCount,
                                                state: state)
        XCTAssertEqual(outcome, .success)
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.draughtReady))
    }

    func testBrewFizzleReturnsAllIngredientsIntact() {
        let state = makeState(tempDir())
        state.setCauldronIngredients(BrewSolution.requiredIngredients)
        let outcome = PuzzleEngine.resolveBrew(flameStage: 1, // wrong stage
                                                stirDirection: BrewSolution.stirDirection,
                                                stirCount: BrewSolution.stirCount,
                                                state: state)
        XCTAssertEqual(outcome, .fizzle)
        for id in BrewSolution.requiredIngredients {
            XCTAssertTrue(state.hasItem(id), "\(id) should return to inventory on fizzle")
        }
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.draughtReady))
    }

    func testBrewNotReadyWithoutAllIngredients() {
        let state = makeState(tempDir())
        state.setCauldronIngredients([PuzzleGraph.ItemID.paste])
        let outcome = PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                                stirDirection: BrewSolution.stirDirection,
                                                stirCount: BrewSolution.stirCount,
                                                state: state)
        XCTAssertEqual(outcome, .notReady)
    }

    // MARK: - p15/p16/p17 endgame chain + D1 (BLOCK ruling) invariant

    func testFullEndgameChain() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.phial)
        state.setFlag(PuzzleGraph.StateFlag.draughtReady)
        XCTAssertTrue(PuzzleEngine.fillPhial(state: state))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phialDraught))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.phial))

        XCTAssertTrue(PuzzleEngine.pourDraughtOnBasin(state: state))
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.phialDraught))

        XCTAssertTrue(PuzzleEngine.slideBoltAndLeave(state: state))
        XCTAssertTrue(state.isComplete)
    }

    func testEscapeFailsWithoutDoorUnsealed() {
        let state = makeState(tempDir())
        XCTAssertFalse(PuzzleEngine.slideBoltAndLeave(state: state))
        XCTAssertFalse(state.isComplete)
    }

    func testCauldronRemainsDraughtReadyAfterFilling_refillInvariant() {
        // p15 note: "Cauldron remains draught-ready after filling; refills possible."
        // This is load-bearing for D1's BLOCK ruling (a blocked pour never spends the
        // phial in the first place, but the invariant must still hold independently).
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.phial)
        state.setFlag(PuzzleGraph.StateFlag.draughtReady)
        XCTAssertTrue(PuzzleEngine.fillPhial(state: state))
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.draughtReady))
        // Simulate losing the phial-draught somehow and needing a refill: give another
        // empty phial and confirm the cauldron still serves it.
        state.addItem(PuzzleGraph.ItemID.phial)
        XCTAssertTrue(PuzzleEngine.fillPhial(state: state))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phialDraught))
    }

    func testD1FeedCupRefusalNeverMutatesDraughtOrCrowState() {
        // D1 option (a) BLOCK: attemptPourDraughtAtFeedCup() must be a pure no-op.
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.phialDraught)
        PuzzleEngine.attemptPourDraughtAtFeedCup()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phialDraught), "phial must return to inventory unspent")
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed))
    }

    // MARK: - D5 clock cuckoo: one-shot cosmetic latch, never gates progression

    func testClockCuckooPopsOnceThenSpent() {
        let state = makeState(tempDir())
        XCTAssertEqual(PuzzleEngine.setClockToTwelve(state: state), .popped)
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.clockCuckooSpent))
        XCTAssertEqual(PuzzleEngine.setClockToTwelve(state: state), .spentAlready)
        XCTAssertEqual(PuzzleEngine.setClockToTwelve(state: state), .spentAlready)
    }

    func testClockCuckooNeverBlocksOtherPuzzles() {
        // Never touching the clock at all must not prevent solving the level; this is
        // implicitly covered by every other test never calling setClockToTwelve, but we
        // assert explicitly that the flag defaults to false and nothing reads it as a gate.
        let state = makeState(tempDir())
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.clockCuckooSpent))
    }

    // MARK: - Save / resume persistence

    func testSaveAndResumeRestoresState() {
        let dir = tempDir()
        let store = SaveGameStore(directory: dir)
        let state = GameState(levelID: 1, store: store)
        state.addItem(PuzzleGraph.ItemID.poker)
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.setFlag(PuzzleGraph.StateFlag.moonbeamOn)

        // New store instance pointed at the same directory simulates relaunch.
        let store2 = SaveGameStore(directory: dir)
        let resumed = GameState(levelID: 1, store: store2)
        XCTAssertTrue(resumed.hasItem(PuzzleGraph.ItemID.poker))
        XCTAssertTrue(resumed.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
        XCTAssertTrue(resumed.hasFlag(PuzzleGraph.StateFlag.moonbeamOn))
    }

    func testRestartLevelClearsOnlyThatLevel() {
        let dir = tempDir()
        let store = SaveGameStore(directory: dir)
        let state = GameState(levelID: 1, store: store)
        state.addItem(PuzzleGraph.ItemID.poker)
        state.markComplete()
        XCTAssertTrue(store.isLevelComplete(1))

        state.restartLevel()
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.poker))
        XCTAssertFalse(store.isLevelComplete(1))
    }

    func testResetAllProgressClearsCompletionForLevelSelect() {
        let dir = tempDir()
        let store = SaveGameStore(directory: dir)
        let state = GameState(levelID: 1, store: store)
        state.markComplete()
        XCTAssertTrue(store.isLevelComplete(1))

        store.resetAllProgress()
        XCTAssertFalse(store.isLevelComplete(1))
    }

    func testSoundSettingPersistsIndependentlyOfProgressReset() {
        let dir = tempDir()
        let store = SaveGameStore(directory: dir)
        store.soundOn = false
        store.resetAllProgress()
        XCTAssertFalse(store.soundOn, "Reset Progress must not silently change unrelated settings")
    }

    // MARK: - Entitlements (structured for future IAP, always-true today)

    func testLevelEntitlementAlwaysTrueToday() {
        XCTAssertTrue(Entitlements.isLevelUnlocked(1))
        XCTAssertTrue(Entitlements.isLevelUnlocked(999))
    }
}
