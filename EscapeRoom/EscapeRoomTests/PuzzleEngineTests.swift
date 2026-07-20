import XCTest
import UIKit
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

    /// Feedback round 1 (clue-gating rev 1.3): direct engine-level solve tests bypass the
    /// close-up UI that records clue views, so a gated puzzle's solution would (correctly)
    /// be refused. This helper marks every gating clue viewed — the engine-level analogue
    /// of a player having opened all the clue close-ups — so that solve-behavior tests
    /// keep asserting the SOLVE grammar. Dedicated gating tests do NOT call this.
    private func satisfyAllGates(_ state: GameState) {
        for clueID in [ClueID.markAir, ClueID.markFire, ClueID.markEarth, ClueID.markWater,
                       ClueID.grimoireElements, ClueID.triptych, ClueID.windowOrion,
                       ClueID.slotShapes, ClueID.recipePage] {
            state.markClueViewed(clueID)
        }
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

    func testItemCombinationFileAndSpoonYieldsShavings_andConsumesBoth_R4_030() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.file)
        state.addItem(PuzzleGraph.ItemID.spoon)
        XCTAssertTrue(ItemCombinations.combine(PuzzleGraph.ItemID.file, PuzzleGraph.ItemID.spoon, state: state))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.shavings))
        // Build 10 (R4-030): p12 is the ONLY graph use of both the file and the spoon,
        // so the uses-driven lifecycle consumes them at the combine.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.spoon), "spoon has no remaining use after p12 — consumed")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.file), "file has no remaining use after p12 — consumed")
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
        satisfyAllGates(state) // rev 1.3: p01 gates on the four marks + page A
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.air, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.fire, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.earth, state: state), .inProgress)
        XCTAssertEqual(PuzzleEngine.pressRuneTile(.water, state: state), .solved)
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.runeDoor))
    }

    func testRuneDoorWrongSequenceResetsWithNoLockout() {
        let state = makeState(tempDir())
        satisfyAllGates(state) // isolate the wrong-vs-correct behavior from the gate
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
        satisfyAllGates(state) // rev 1.3: p02 gates on the triptych clue
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
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        satisfyAllGates(state) // rev 1.3: p14 resolve gates on the recipe page
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
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        satisfyAllGates(state) // isolate the fizzle to the wrong flame stage, not the gate
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
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
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

    // MARK: - Q3: clock cuckoo REMOVED — the clock is a purely inert numeral reference

    func testClockIsInertReference() {
        // Q3 (user decision 2026-07-08): there is no cuckoo latch anymore. The clock
        // never writes state and always renders its single face plate — so it can never
        // gate or reward. Assert the visual resolver is state-independent and inert.
        let state = makeState(tempDir())
        XCTAssertEqual(RoomVisuals.clockState(state), "cu-clock-unspent")
        // Even a legacy save that still carries the retired flag renders the same face.
        state.setFlag(PuzzleGraph.StateFlag.clockCuckooSpent)
        XCTAssertEqual(RoomVisuals.clockState(state), "cu-clock-unspent")
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

    // MARK: - QA fix pass regression net (Developer's own tests for the new surfaces)

    private let sceneSize = CGSize(width: 2732, height: 1366)

    func testStartZoneUnlockedOnFreshSaveAndAfterRestart() {
        let state = makeState(tempDir())
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.startZoneID))
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.restartLevel()
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.startZoneID), "restart must keep the start zone navigable")
        XCTAssertFalse(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
    }

    func testRugDiscoveryGatesDialCloseUp_QA_BUG_010() {
        let state = makeState(tempDir())
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("trapdoor-dial")
        XCTAssertNil(coordinator.activeCloseUp, "the dial panel must not exist before the rug is moved")
        coordinator.scene.onHotspotTap?("rug")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.rugMoved), "rug tap is the free-action discovery")
        coordinator.scene.onHotspotTap?("trapdoor-dial")
        XCTAssertEqual(coordinator.activeCloseUp, .dialPanel)
        // Rug discovery survives relaunch (satisfied-requirement flag).
        XCTAssertTrue(RoomVisuals.rugMoved(state))
    }

    func testWorkbenchUseCombinesFileAndSpoon_QA_BUG_012() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.addItem(PuzzleGraph.ItemID.file)
        state.addItem(PuzzleGraph.ItemID.spoon)
        let coordinator = RoomSceneCoordinator(viewID: .bench, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.file, on: "workbench")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.shavings), "workbench accepts the p12 combination")
        // Build 10 (R4-030): both single-use tools are consumed once p12 is done.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.spoon), "spoon consumed after its only use (p12)")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.file), "file consumed after its only use (p12)")
    }

    func testWorkbenchUseWithoutBothItemsDoesNothing() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.addItem(PuzzleGraph.ItemID.file)
        let coordinator = RoomSceneCoordinator(viewID: .bench, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.file, on: "workbench")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.shavings))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.file))
    }

    func testCabinetWrongSlotUseRejectedWithoutStalePending_QA_BUG_017() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        satisfyAllGates(state) // rev 1.3: p04 gates on clu-slot-shapes (self-satisfying in-app)
        state.addItem(PuzzleGraph.ItemID.goldRing)
        state.addItem(PuzzleGraph.ItemID.silverCoin)
        let coordinator = RoomSceneCoordinator(viewID: .cabinet, state: state, size: sceneSize)
        // Wrong item on the sun slot: pops back, never seats.
        coordinator.useItem(PuzzleGraph.ItemID.silverCoin, on: "sun-slot")
        XCTAssertNil(coordinator.pendingSunItem, "a rejected item must not become a stale pending placement")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.silverCoin))
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon))
        // Correct two-step placement completes.
        coordinator.useItem(PuzzleGraph.ItemID.goldRing, on: "sun-slot")
        XCTAssertEqual(coordinator.pendingSunItem, PuzzleGraph.ItemID.goldRing, "correct item seats visibly")
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon))
        coordinator.useItem(PuzzleGraph.ItemID.silverCoin, on: "moon-slot")
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon))
        // Feedback round 1 (F-023): the yield is NOT auto-granted — the opened
        // cabinet presents the file + phial for manual collection.
        XCTAssertEqual(coordinator.activeCloseUp, .container(.sunMoonCabinet))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.file))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.phial))
        coordinator.collectContainerItem(PuzzleGraph.ItemID.file, from: .sunMoonCabinet)
        coordinator.collectContainerItem(PuzzleGraph.ItemID.phial, from: .sunMoonCabinet)
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.file))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phial))
        // Both placed items were consumed by the engine.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.goldRing))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.silverCoin))
    }

    func testCageTapAfterCrowFreedShowsOpenCageNotRefusal_QA_BUG_020() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.cageKey)
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.cageKey, on: "star-keyhole")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.crowFreed))
        coordinator.showTerminalRefusal = false
        coordinator.dismissCloseUp()
        coordinator.scene.onHotspotTap?("cage")
        XCTAssertFalse(coordinator.showTerminalRefusal, "no refusal after the crow is freed")
        XCTAssertEqual(coordinator.activeCloseUp, .plain(image: "cu-cage-open-empty"))
    }

    func testCageKeyUsedOnCageUnlocks_QA_BUG_018() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.cageKey)
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.cageKey, on: "cage")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.crowFreed), "using the star key on the cage must work")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.feather))
    }

    /// Graph z1 p16 clue: "if crow is freed, it perches on the door lintel above the
    /// basin (silent nudge)". The perch keys on crow-freed ALONE — it must be visible
    /// BEFORE door-unsealed (that is the phase the nudge exists to hint at) and stay
    /// put afterwards. (Polish batch 2026-07-06; found by walkthrough reconciliation.)
    func testCrowPerchesOnLintelOnceFreed_endgameNudge() {
        let state = makeState(tempDir())
        XCTAssertEqual(RoomVisuals.crowLocation(state), "caged")
        state.setFlag(PuzzleGraph.StateFlag.crowFreed)
        XCTAssertEqual(RoomVisuals.crowLocation(state), "on-lintel",
                       "freed crow must perch on the lintel while the door is still sealed")
        state.setFlag(PuzzleGraph.StateFlag.doorUnsealed)
        XCTAssertEqual(RoomVisuals.crowLocation(state), "on-lintel")
    }

    func testPhialUseBeforeDraughtReadyIsRefusedSafely() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.addItem(PuzzleGraph.ItemID.phial)
        let coordinator = RoomSceneCoordinator(viewID: .bench, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.phial, on: "cauldron")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.phial), "the phial must never vanish into a non-ready cauldron")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.phialDraught))
        XCTAssertFalse(state.data.cauldronIngredients.contains(PuzzleGraph.ItemID.phial), "the phial is not an ingredient")
    }

    func testIngredientUseAfterSuccessIsRefused_QA_BUG_006_companion() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        satisfyAllGates(state) // the brew must actually succeed to set draught-ready
        state.setCauldronIngredients(BrewSolution.requiredIngredients)
        _ = PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                     stirDirection: BrewSolution.stirDirection,
                                     stirCount: BrewSolution.stirCount, state: state)
        // A stray feather (e.g. from a hypothetical future level) offered after
        // success must not be consumed into the finished draught.
        state.addItem(PuzzleGraph.ItemID.feather)
        let coordinator = RoomSceneCoordinator(viewID: .bench, state: state, size: sceneSize)
        coordinator.useItem(PuzzleGraph.ItemID.feather, on: "cauldron")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.feather))
        XCTAssertTrue(state.data.cauldronIngredients.isEmpty)
    }

    func testRuneTilePressesFromCloseUpFollowTileMapping() {
        let state = makeState(tempDir())
        satisfyAllGates(state) // rev 1.3: p01 must be ungated for the sequence to solve
        let coordinator = RoomSceneCoordinator(viewID: .study, state: state, size: sceneSize)
        // Solution AIR, FIRE, EARTH, WATER = tiles 3, 1, 4, 2 (manifest mapping).
        coordinator.pressRuneTile(3)
        XCTAssertEqual(coordinator.pressedRuneTiles, [3])
        coordinator.pressRuneTile(1)
        coordinator.pressRuneTile(4)
        coordinator.pressRuneTile(2)
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.runeDoor))
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
        XCTAssertTrue(coordinator.pressedRuneTiles.isEmpty, "tiles reset flush after the sequence resolves")
    }

    func testRuneTileWrongSequenceResetsPressedTiles() {
        let state = makeState(tempDir())
        let coordinator = RoomSceneCoordinator(viewID: .study, state: state, size: sceneSize)
        for tile in [1, 2, 3, 4] { coordinator.pressRuneTile(tile) } // FIRE,WATER,AIR,EARTH = wrong
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.runeDoor))
        XCTAssertTrue(coordinator.pressedRuneTiles.isEmpty, "dull knock resets tiles flush; no lockout")
    }

    /// Q3 (user decision 2026-07-08): the D5 clock cuckoo one-shot was REMOVED, so the
    /// old `testClockCloseUpAdvanceTriggersOneShotAtTwelve_D5` (which asserted the first
    /// XII spent a `clockCuckooSpent` latch) is obsolete and was deleted. Advancing the
    /// hands is now purely cosmetic and must NEVER write clock state — asserted here and
    /// in `testClockIsInertReference`.
    func testAdvancingClockHandsNeverLatchesState_Q3() {
        let state = makeState(tempDir())
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize)
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.clockCuckooSpent))
        // Sweep the hands all the way around (past XII) more than once.
        for _ in 0..<24 { coordinator.advanceClockHour() }
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.clockCuckooSpent),
                       "reaching XII must NOT latch any cuckoo state — the clock is inert (Q3)")
    }

    // MARK: - Feedback round 1 regression net (select-then-tap, containers, nav, audio)

    /// Core interaction-model change (user decision 2026-07-07): merely HOLDING an
    /// item never applies it. A bare tap on the ash pile with the poker in inventory
    /// is a look; only the ARMED poker sifts. (Root cause of F-007/F-020/F-021.)
    func testBareTapNeverAutoAppliesHeldItem_ashSift() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.poker)
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize,
                                               interaction: interaction)
        coordinator.scene.onHotspotTap?("ash")
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.ashSift),
                       "a bare tap must NOT sift just because the poker is held (passive auto-apply removed)")
        XCTAssertEqual(coordinator.activeCloseUp, .ashPile, "bare tap = look at the ash pile")
        coordinator.dismissCloseUp()
        // Arm the poker, then tap the ash: the deliberate select-then-tap use.
        interaction.armedItem = PuzzleGraph.ItemID.poker
        coordinator.scene.onHotspotTap?("ash")
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.ashSift))
        // R2-003a: sifting REVEALS the ring but does NOT auto-grant it — it must be
        // collected with an explicit tap.
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.goldRing), "ring is revealed, not auto-granted")
        XCTAssertTrue(PuzzleEngine.isRingUncollectedInAsh(state), "ring visible+pickable in ash")
        XCTAssertNil(interaction.armedItem, "a successful sift disarms the poker")
        coordinator.collectAshRing()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.goldRing), "explicit tap collects the ring")
    }

    func testBareTapNeverAutoApplies_barrelWinchKeyhole() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.addItem(PuzzleGraph.ItemID.poker)
        state.addItem(PuzzleGraph.ItemID.crank)
        state.addItem(PuzzleGraph.ItemID.cageKey)
        let interaction = InteractionModel()
        let cellar = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize,
                                          interaction: interaction)
        cellar.scene.onHotspotTap?("barrel")
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.barrelPry), "held poker must not auto-pry")
        cellar.scene.onHotspotTap?("winch")
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn), "held crank must not auto-fit")
        let entry = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize,
                                         interaction: interaction)
        entry.scene.onHotspotTap?("star-keyhole")
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.crowFreed), "held key must not auto-unlock")
        // The armed path still works for each.
        interaction.armedItem = PuzzleGraph.ItemID.poker
        cellar.scene.onHotspotTap?("barrel")
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.barrelPry))
        interaction.armedItem = PuzzleGraph.ItemID.crank
        cellar.scene.onHotspotTap?("winch")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn))
        interaction.armedItem = PuzzleGraph.ItemID.cageKey
        entry.scene.onHotspotTap?("star-keyhole")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.crowFreed))
    }

    /// R2-030: a failed use (wrong item on a wrong target) KEEPS the item armed so the
    /// player can immediately try elsewhere, and never mutates state.
    func testFailedUseKeepsItemArmedWithoutStateChurn_R2_030() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.rustedKey)
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize,
                                               interaction: interaction)
        let before = state.data
        interaction.armedItem = PuzzleGraph.ItemID.rustedKey
        coordinator.scene.onHotspotTap?("ash") // rusted key on ash = wrong-target no-op
        XCTAssertEqual(interaction.armedItem, PuzzleGraph.ItemID.rustedKey,
                       "R2-030: a wrong-target no-op keeps the item armed")
        XCTAssertEqual(state.data.inventory, before.inventory)
        XCTAssertEqual(state.data.solvedPuzzles, before.solvedPuzzles)
    }

    /// R2-030 corollary: an intended reaction on the wrong-but-recognized target (the
    /// rusted-key fairness reject at the door) DOES disarm — it engaged the target.
    func testIntendedRejectDisarms_R2_030() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.rustedKey)
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize,
                                               interaction: interaction)
        interaction.armedItem = PuzzleGraph.ItemID.rustedKey
        coordinator.scene.onHotspotTap?("door-lock") // fairness reject = engaged
        XCTAssertNil(interaction.armedItem, "an intended reaction disarms")
    }

    /// F-020: an item armed while a close-up is open routes to the close-up's origin
    /// hotspot, so tool-on-hotspot puzzles are solvable without leaving the zoom.
    func testArmedUseInsideCloseUpRoutesToOriginHotspot() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.poker)
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize,
                                               interaction: interaction)
        coordinator.scene.onHotspotTap?("ash") // open the ash close-up (a look)
        XCTAssertEqual(coordinator.activeCloseUp, .ashPile)
        interaction.armedItem = PuzzleGraph.ItemID.poker
        coordinator.useArmedItemInCloseUp() // tap the plate with the poker armed
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.ashSift),
                      "the close-up must not wall the player off from item use (F-020)")
        // R2-003a: ring revealed, collected via explicit tap.
        XCTAssertTrue(PuzzleEngine.isRingUncollectedInAsh(state))
        coordinator.collectAshRing()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.goldRing))
    }

    // MARK: F-023/F-018 manual container pickup

    func testAstrolabeSolveShowsContentsInsteadOfAutoGranting() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        satisfyAllGates(state) // rev 1.3: p03 gates on the Orion window clue
        let coordinator = RoomSceneCoordinator(viewID: .cabinet, state: state, size: sceneSize)
        coordinator.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex)
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.silverCoin), "no teleporting into inventory (F-023)")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.crank))
        XCTAssertEqual(coordinator.activeCloseUp, .container(.astrolabeDrawer),
                       "solving springs the drawer open with the contents visible")
        XCTAssertEqual(Set(PuzzleEngine.uncollectedItems(in: .astrolabeDrawer, state: state)),
                       [PuzzleGraph.ItemID.silverCoin, PuzzleGraph.ItemID.crank])
        coordinator.collectContainerItem(PuzzleGraph.ItemID.silverCoin, from: .astrolabeDrawer)
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.silverCoin))
        XCTAssertEqual(PuzzleEngine.uncollectedItems(in: .astrolabeDrawer, state: state),
                       [PuzzleGraph.ItemID.crank])
        coordinator.collectContainerItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer)
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.crank))
        XCTAssertTrue(PuzzleEngine.uncollectedItems(in: .astrolabeDrawer, state: state).isEmpty)
    }

    /// Anti-softlock: quitting between solving a container and collecting its items
    /// must leave them collectable after relaunch (derived, not event-ordered).
    func testUncollectedContainerItemsSurviveRelaunch() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        satisfyAllGates(state)
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state))
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.silverCoin, from: .astrolabeDrawer, state: state))
        // Relaunch mid-collection: the crank must still be waiting in the drawer.
        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertEqual(PuzzleEngine.uncollectedItems(in: .astrolabeDrawer, state: resumed),
                       [PuzzleGraph.ItemID.crank])
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer, state: resumed))
    }

    /// Saves from the auto-grant build (items already granted/spent) must show
    /// nothing as collectable — no duplicate yields.
    func testAutoGrantEraSavesShowNoCollectableDuplicates() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        // Simulate the old build: p03/p04 solved with yields auto-granted, coin+ring
        // then spent into the cabinet, phial spent at p15.
        state.markSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
        state.addItem(PuzzleGraph.ItemID.crank)
        state.markSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) // coin consumed by p04
        state.addItem(PuzzleGraph.ItemID.file)
        state.markSolved(PuzzleGraph.PuzzleID.fillPhial)      // phial consumed by p15
        state.addItem(PuzzleGraph.ItemID.phialDraught)
        XCTAssertTrue(PuzzleEngine.uncollectedItems(in: .astrolabeDrawer, state: state).isEmpty)
        XCTAssertTrue(PuzzleEngine.uncollectedItems(in: .sunMoonCabinet, state: state).isEmpty)
    }

    func testCollectItemRefusesUnsolvedOrAlreadyCollected() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        satisfyAllGates(state)
        XCTAssertFalse(PuzzleEngine.collectItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer, state: state),
                       "nothing collectable before the container is solved")
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state))
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer, state: state))
        XCTAssertFalse(PuzzleEngine.collectItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer, state: state),
                       "an item collects exactly once")
    }

    /// Cellar drawer (feedback round 1): shut -> opened (latched free action) ->
    /// spoon taken with its own tap. The old build's overlay mapping was inverted.
    func testCellarDrawerOpensThenSpoonTakenManually() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        let coordinator = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize)
        XCTAssertNil(RoomVisuals.drawerOverlay(state), "drawer starts shut (base art)")
        coordinator.scene.onHotspotTap?("drawer")
        XCTAssertTrue(state.hasFlag(PuzzleGraph.StateFlag.cellarDrawerOpened))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.spoon), "opening does not auto-take the spoon")
        XCTAssertEqual(RoomVisuals.drawerOverlay(state), "ov-drawer-open", "open drawer shows the spoon")
        coordinator.scene.onHotspotTap?("drawer")
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.spoon))
        XCTAssertEqual(RoomVisuals.drawerOverlay(state), "ov-drawer-empty", "taken spoon leaves an empty drawer")
    }

    // MARK: F-011 crow default pose

    func testBareCageTapShowsNeutralPoseNotRefusal_F011() {
        let state = makeState(tempDir())
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize,
                                               interaction: interaction)
        coordinator.scene.onHotspotTap?("cage")
        XCTAssertFalse(coordinator.showTerminalRefusal,
                       "a bare look at the cage must show the NEUTRAL caged pose (F-011)")
        XCTAssertEqual(coordinator.activeCloseUp, .plain(image: "cu-cage-crow"))
        coordinator.dismissCloseUp()
        // The turned-back pose remains exclusively the D3 reaction to a deliberate
        // armed-item reach.
        state.addItem(PuzzleGraph.ItemID.poker)
        interaction.armedItem = PuzzleGraph.ItemID.poker
        coordinator.scene.onHotspotTap?("cage")
        XCTAssertTrue(coordinator.showTerminalRefusal)
        XCTAssertEqual(coordinator.activeCloseUp, .refusal)
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.poker), "refusal returns the item unspent (D3)")
    }

    // MARK: F-006/F-014 dead hotspots are silent (and generic click removed)

    func testDeadHotspotsAreSilent_F006_F014() {
        let state = makeState(tempDir())
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize)
        SoundManager.shared.resetPlayedLog()
        coordinator.scene.onHotspotTap?("poker")
        XCTAssertEqual(SoundManager.shared.playedLog, [.pickup], "first poker tap is the pickup chime")
        SoundManager.shared.resetPlayedLog()
        coordinator.scene.onHotspotTap?("poker")
        XCTAssertTrue(SoundManager.shared.playedLog.isEmpty,
                      "the emptied poker hook must be silent (F-006)")
        // Inert scenery (F-014 class): the workbench strip plays nothing on a bare tap.
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        let bench = RoomSceneCoordinator(viewID: .bench, state: state, size: sceneSize)
        SoundManager.shared.resetPlayedLog()
        bench.scene.onHotspotTap?("workbench")
        XCTAssertTrue(SoundManager.shared.playedLog.isEmpty, "inert scenery must be silent (F-014)")
    }

    func testCloseUpOpensSilently_genericClickRemoved_F005() {
        let state = makeState(tempDir())
        let coordinator = RoomSceneCoordinator(viewID: .study, state: state, size: sceneSize)
        SoundManager.shared.resetPlayedLog()
        coordinator.scene.onHotspotTap?("flowerpot")
        XCTAssertEqual(coordinator.activeCloseUp, .plain(image: "cu-flowerpot"))
        XCTAssertTrue(SoundManager.shared.playedLog.isEmpty,
                      "zooming into an object is silent — the generic psh is gone (F-005)")
    }

    // MARK: F-024 navigation model

    func testChevronsCycleWithinZoneOnly_F024() {
        let dir = tempDir()
        let session = LevelSession(levelID: 1, store: SaveGameStore(directory: dir))
        // Unlock everything; chevrons must STILL never leave the current zone.
        session.state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        session.state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        session.state.unlockZone(PuzzleGraph.ZoneID.z4Alcove)
        XCTAssertEqual(session.currentView, .hearth)
        session.nextView()
        XCTAssertEqual(session.currentView, .study)
        session.nextView()
        XCTAssertEqual(session.currentView, .entry)
        session.nextView()
        XCTAssertEqual(session.currentView, .hearth, "z1 chevrons wrap within z1's three views")
        session.previousView()
        XCTAssertEqual(session.currentView, .entry)
        // z2 is a two-view ring.
        session.goTo(.bench)
        session.nextView()
        XCTAssertEqual(session.currentView, .cabinet)
        session.nextView()
        XCTAssertEqual(session.currentView, .bench)
        XCTAssertTrue(session.hasViewNavigation)
    }

    func testSingleViewZonesHaveNoChevronNavigation_F024() {
        let session = LevelSession(levelID: 1, store: SaveGameStore(directory: tempDir()))
        session.state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        session.goTo(.cellar)
        XCTAssertFalse(session.hasViewNavigation, "z3 is a single wide view — chevrons hidden")
        session.nextView()
        XCTAssertEqual(session.currentView, .cellar, "chevron actions are no-ops in single-view zones")
        session.previousView()
        XCTAssertEqual(session.currentView, .cellar)
    }

    func testDiegeticPassagesNavigateBetweenZones_F024() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.unlockZone(PuzzleGraph.ZoneID.z4Alcove)
        var navigated: [ViewID] = []
        let cellar = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize)
        cellar.onNavigate = { navigated.append($0) }
        cellar.scene.onHotspotTap?("ladder")
        XCTAssertEqual(navigated.last, .hearth, "the cellar ladder climbs back to the hearth")
        cellar.scene.onHotspotTap?("alcove-passage")
        XCTAssertEqual(navigated.last, .alcove, "the slid shelf's gap leads into the alcove")
        let alcove = RoomSceneCoordinator(viewID: .alcove, state: state, size: sceneSize)
        alcove.onNavigate = { navigated.append($0) }
        alcove.scene.onHotspotTap?("cellar-passage")
        XCTAssertEqual(navigated.last, .cellar, "the shelf gap leads back out")
    }

    func testAlcovePassageInertUntilShelfSlid() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar) // z4 NOT unlocked: shelf still closed
        var navigated: [ViewID] = []
        let cellar = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize)
        cellar.onNavigate = { navigated.append($0) }
        cellar.scene.onHotspotTap?("alcove-passage")
        XCTAssertTrue(navigated.isEmpty, "no passage through a closed shelf")
    }

    // MARK: F-004 lineage -> build-10 music-only model (R4-002)

    /// Build 10 (R4-002): the per-zone ambient beds and the sfx-entry swell (the
    /// reported "ocean waves at level entry") are REMOVED — level audio is the looping
    /// music alone, and it restarts cleanly across exit/re-enter (the original F-004
    /// requirement, now asserted against the music player).
    func testLevelAudioIsMusicOnlyAndRestartsCleanly_R4_002_F004() {
        let sound = SoundManager.shared
        let priorAmbiance = sound.ambianceEnabled
        sound.ambianceEnabled = true
        sound.enterLevel()
        XCTAssertTrue(sound.isMusicActive, "level entry starts the music bed")
        sound.exitLevel()
        XCTAssertFalse(sound.isMusicActive, "exit fully stops the music (F-004 root-cause class)")
        sound.enterLevel()
        XCTAssertTrue(sound.isMusicActive, "re-entering the level restarts the music, never debounced")
        sound.exitLevel()
        sound.ambianceEnabled = priorAmbiance
    }

    // MARK: R3-001 level-scoped music + menu SFX

    /// R3-001: level music is bound to the LEVEL SCENE lifecycle — it may only play while
    /// a level is active (enterLevel..exitLevel). Outside a level (menus / pre-level) it
    /// must never start, even if ambiance is on and startMusicIfNeeded fires.
    func testMusicIsScopedToLevelLifecycle_R3_001() {
        let sound = SoundManager.shared
        let priorAmbiance = sound.ambianceEnabled
        sound.ambianceEnabled = true       // ambiance ON, but we are NOT in a level
        sound.exitLevel()                  // ensure menu scope (also stops any music)
        XCTAssertFalse(sound.debugInLevel)
        sound.startMusicIfNeeded()
        XCTAssertFalse(sound.isMusicActive, "level music must NOT play in the menus (R3-001)")

        sound.enterLevel()                 // level scene appears
        XCTAssertTrue(sound.debugInLevel)
        XCTAssertTrue(sound.isMusicActive, "level music starts inside the level (ambiance on)")

        sound.exitLevel()                  // back to the menu
        XCTAssertFalse(sound.debugInLevel)
        XCTAssertFalse(sound.isMusicActive, "exiting a level stops the music (menus are music-free)")

        sound.ambianceEnabled = priorAmbiance
    }

    /// R3-001 -> R4-003: the menu chrome uses ONE consistent cue — the liked
    /// Level-Select ping (menuConfirm). The disliked "tick" (sfx-menu-tap) is retired
    /// and must no longer ship.
    func testMenuPingShipsAndTickIsRetired_R4_003() {
        XCTAssertNotNil(Bundle.main.url(forResource: "sfx-menu-confirm", withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "sfx-menu-confirm", withExtension: "wav"),
                        "sfx-menu-confirm.wav (the liked ping) must ship")
        XCTAssertNil(Bundle.main.url(forResource: "sfx-menu-tap", withExtension: "wav", subdirectory: "Audio"),
                     "the retired menu tick must not ship (R4-003)")
    }

    // MARK: F-012 clue-view tracking substrate (gating pending puzzle-graph rev 1.3)

    func testClueCloseUpViewsAreRecordedAndPersisted() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        let coordinator = RoomSceneCoordinator(viewID: .study, state: state, size: sceneSize)
        XCTAssertFalse(state.hasViewedClue("plain-cu-flowerpot"))
        coordinator.scene.onHotspotTap?("flowerpot")
        XCTAssertTrue(state.hasViewedClue("plain-cu-flowerpot"))
        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertTrue(resumed.hasViewedClue("plain-cu-flowerpot"), "clue views persist in the save")
    }

    /// Saves written by builds that predate `viewedClues` (TestFlight build 1) must
    /// decode instead of resetting the player's progress. Simulated by encoding a
    /// current save and stripping the new key — byte-identical to what build 1 wrote.
    func testBuildOneSaveWithoutViewedCluesStillDecodes() throws {
        // Encode a single LevelSaveData (not the SaveGame wrapper — its [Int: ...] level
        // map has a Foundation-version-dependent JSON shape) and strip the new key from
        // its object dict directly, so this stays encoding-agnostic while still exercising
        // LevelSaveData.decodeIfPresent migration.
        var level = LevelSaveData(levelID: 1)
        level.inventory = ["itm-poker"]
        level.viewedClues = ["plain-cu-flowerpot"]
        let encoded = try JSONEncoder().encode(level)
        var object = try XCTUnwrap(try JSONSerialization.jsonObject(with: encoded) as? [String: Any])
        XCTAssertNotNil(object["viewedClues"], "sanity: the current build writes viewedClues")
        object.removeValue(forKey: "viewedClues") // simulate a build-1 save (key absent)
        let stripped = try JSONSerialization.data(withJSONObject: object)
        let resumedLevel = try JSONDecoder().decode(LevelSaveData.self, from: stripped)
        XCTAssertTrue(resumedLevel.inventory.contains("itm-poker"), "old-save inventory must survive")
        XCTAssertTrue(resumedLevel.viewedClues.isEmpty, "absent viewedClues decodes to empty, not a reset")
    }

    // MARK: F-012 clue-gating enforcement (puzzle-graph rev 1.3)

    /// p01: the CORRECT rune sequence is refused (dull-knock reset, no tell) until all
    /// four rune marks AND grimoire page A have been viewed. Page A is REQUIRED per the
    /// user's FINAL 2026-07-07 ruling; this test locks that ruling in.
    func testRuneDoorGatedUntilFourMarksAndPageAViewed_p01() {
        let state = makeState(tempDir())
        // With NO clues viewed, the correct AIR-FIRE-EARTH-WATER resets instead of solving.
        for rune in RuneDoorSolution.solutionOrder.dropLast() {
            XCTAssertEqual(PuzzleEngine.pressRuneTile(rune, state: state), .inProgress)
        }
        XCTAssertEqual(PuzzleEngine.pressRuneTile(RuneDoorSolution.solutionOrder.last!, state: state), .reset,
                       "gated: even the correct sequence resets with the same dull knock (no tell)")
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.runeDoor))
        // View the four marks only — page A is REQUIRED, so still gated (final ruling).
        for clue in [ClueID.markAir, ClueID.markFire, ClueID.markEarth, ClueID.markWater] {
            state.markClueViewed(clue)
        }
        for rune in RuneDoorSolution.solutionOrder.dropLast() { _ = PuzzleEngine.pressRuneTile(rune, state: state) }
        XCTAssertEqual(PuzzleEngine.pressRuneTile(RuneDoorSolution.solutionOrder.last!, state: state), .reset,
                       "page A is REQUIRED (user final ruling): four marks alone do not open the gate")
        // View page A: now the gate opens and the correct sequence solves.
        state.markClueViewed(ClueID.grimoireElements)
        for rune in RuneDoorSolution.solutionOrder.dropLast() { _ = PuzzleEngine.pressRuneTile(rune, state: state) }
        XCTAssertEqual(PuzzleEngine.pressRuneTile(RuneDoorSolution.solutionOrder.last!, state: state), .solved)
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop))
    }

    /// p02: correct dials refused while gated; IC-1 re-evaluation opens the trapdoor on
    /// close-up entry once the triptych is viewed, with NO input wiggle (stale-correct case).
    func testMoonDialsGatedThenIC1ReevaluatesOnCloseUpEntry_p02() {
        let state = makeState(tempDir())
        state.setMoonDialPosition(dial: 0, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waxingCrescent)!)
        state.setMoonDialPosition(dial: 1, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .full)!)
        state.setMoonDialPosition(dial: 2, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waningGibbous)!)
        XCTAssertFalse(PuzzleEngine.evaluateMoonDials(state: state), "gated: correct dials do not open the trapdoor")
        XCTAssertFalse(state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar))
        // View the triptych, then WITHOUT touching the dials, IC-1 fires on close-up entry.
        state.markClueViewed(ClueID.triptych)
        PuzzleEngine.reevaluateMoonDialsOnCloseUpEntry(state: state)
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.moonTrapdoor),
                      "IC-1: stale-correct dials resolve on re-entry after the clue is viewed (no wiggle)")
        XCTAssertTrue(state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar))
    }

    /// p03: correct plate refused while gated; solves once the Orion window is viewed.
    func testAstrolabeGatedUntilOrionWindowViewed_p03() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        XCTAssertFalse(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state),
                       "gated: the Orion plate does not open the drawer until the window is viewed")
        XCTAssertFalse(state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion))
        state.markClueViewed(ClueID.windowOrion)
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state))
    }

    /// p14: correct brew params fizzle (ingredients returned intact) until the recipe
    /// page is viewed. Nothing is consumed by the gated attempt (one retry at most).
    func testBrewGatedUntilRecipeViewed_p14() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        for id in BrewSolution.requiredIngredients { state.addItem(id) }
        state.setCauldronIngredients(BrewSolution.requiredIngredients)
        for id in BrewSolution.requiredIngredients { state.removeItem(id) }
        let gated = PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                             stirDirection: BrewSolution.stirDirection,
                                             stirCount: BrewSolution.stirCount, state: state)
        XCTAssertEqual(gated, .fizzle, "gated: even the correct brew fizzles until the recipe is viewed (no tell)")
        for id in BrewSolution.requiredIngredients {
            XCTAssertTrue(state.hasItem(id), "\(id) must return intact from a gated resolve (nothing consumed)")
        }
        XCTAssertFalse(state.hasFlag(PuzzleGraph.StateFlag.draughtReady))
        // View the recipe, retry: now it succeeds.
        state.markClueViewed(ClueID.recipePage)
        state.setCauldronIngredients(BrewSolution.requiredIngredients)
        for id in BrewSolution.requiredIngredients { state.removeItem(id) }
        XCTAssertEqual(PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                                stirDirection: BrewSolution.stirDirection,
                                                stirCount: BrewSolution.stirCount, state: state), .success)
    }

    /// D7/IC-2: clue-viewed flags persist across a save/restore and never re-lock a gate.
    func testClueViewedFlagsPersistAndNeverReLock_D7() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        state.markClueViewed(ClueID.windowOrion)
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertTrue(resumed.hasViewedClue(ClueID.windowOrion), "clue-viewed flags survive restore (IC-2)")
        XCTAssertTrue(ClueGate.isSatisfied(PuzzleGraph.PuzzleID.astrolabeOrion, state: resumed),
                      "a restore must never re-lock a gate whose clue was already viewed")
    }

    /// The gating close-ups actually RECORD their clu-* gate ids when opened through the
    /// coordinator (drives the gate purely from views the player opened).
    func testGatingCloseUpsRecordClueNodeIDs() {
        let state = makeState(tempDir())
        let hearth = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize)
        hearth.scene.onHotspotTap?("bellows")
        XCTAssertTrue(state.hasViewedClue(ClueID.markAir), "the bellows close-up reveals the AIR mark")
        hearth.scene.onHotspotTap?("lintel")
        XCTAssertTrue(state.hasViewedClue(ClueID.markFire))
        let study = RoomSceneCoordinator(viewID: .study, state: state, size: sceneSize)
        study.scene.onHotspotTap?("flowerpot")
        XCTAssertTrue(state.hasViewedClue(ClueID.markEarth), "the flowerpot is F-012's missed EARTH clue")
        // R2-007: the triptych is now three per-panel hotspots (there is no single
        // "triptych" hotspot anymore). Any panel opens its own close-up but all share the
        // clu-triptych gate id — tap the right (3-crow) panel and assert the shared gate.
        study.scene.onHotspotTap?("triptych-3")
        XCTAssertTrue(state.hasViewedClue(ClueID.triptych))
        let entry = RoomSceneCoordinator(viewID: .entry, state: state, size: sceneSize)
        entry.scene.onHotspotTap?("windowsill")
        XCTAssertTrue(state.hasViewedClue(ClueID.markWater))
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        let cabinet = RoomSceneCoordinator(viewID: .cabinet, state: state, size: sceneSize)
        cabinet.scene.onHotspotTap?("window")
        XCTAssertTrue(state.hasViewedClue(ClueID.windowOrion))
    }

    func testBuild10CloseUpLayoutSanity() {
        // The new manual-pickup / seat rects are plate-normalized and must be sane.
        for rect in [CloseUpLayout.barrelWeightRect, CloseUpLayout.statueKeyRect]
            + Array(CloseUpLayout.slotSeatRects.values) {
            XCTAssertGreaterThanOrEqual(rect.minX, 0)
            XCTAssertGreaterThanOrEqual(rect.minY, 0)
            XCTAssertLessThanOrEqual(rect.maxX, 1)
            XCTAssertLessThanOrEqual(rect.maxY, 1)
            XCTAssertGreaterThan(rect.width, 0)
            XCTAssertGreaterThan(rect.height, 0)
        }
    }

    func testCloseUpLayoutMatchesBundledRuneTileJSON() throws {
        // Guards against drift between the transcribed CloseUpLayout constants and the
        // asset pipeline's authoritative sprite metadata (requires the QA-BUG-022 fix:
        // the folder hierarchy must exist in the bundle).
        guard let url = Bundle.main.resourceURL?
            .appendingPathComponent("GameAssets/level-1/z1/v-study/sprites/runedoor-tiles.json"),
            let data = try? Data(contentsOf: url) else {
            XCTFail("runedoor-tiles.json must ship in the bundle (QA-BUG-022)")
            return
        }
        struct TileEntry: Decodable { let rect_in_plate_3x: [Double]; let rune: String }
        let decoded = try JSONDecoder().decode([String: TileEntry].self, from: data)
        for (key, entry) in decoded {
            let tile = Int(key.dropFirst("tile".count))!
            let expected = CloseUpLayout.runeTileRects[tile]!
            XCTAssertEqual(expected.minX, entry.rect_in_plate_3x[0] / 2048, accuracy: 0.001)
            XCTAssertEqual(expected.minY, entry.rect_in_plate_3x[1] / 1536, accuracy: 0.001)
            XCTAssertEqual(RuneDoorSolution.tileRune[tile]?.rawValue, entry.rune,
                           "tile-to-rune mapping must match the manifest")
        }
    }
}

// MARK: - Build 10, cluster A/F/D regression net (round-4 fix batch, 2026-07-11)

/// Developer's own tests for the build-10 fix batch:
/// - Cluster A: the graph-driven item lifecycle (retain while ANY use unsatisfied,
///   consume once ALL satisfied), asserted as an INVARIANT against the puzzle graph for
///   EVERY item across multiple full solve orderings — including the R4-019 soft-lock
///   ordering (p06 before p05) and a cellar-first path.
/// - Cluster A: manual pickup for the barrel weight (R4-013) and statue key (R4-026).
/// - Cluster F: armed-item model — armed never blocks looks; tap-away/re-tap disarms.
/// - Cluster D + R4-002/003: the retired audio assets can never silently ship again.
final class Build10LifecycleAndInteractionTests: XCTestCase {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeState(_ dir: URL) -> GameState {
        GameState(levelID: 1, store: SaveGameStore(directory: dir))
    }

    private func satisfyAllGates(_ state: GameState) {
        for clueID in [ClueID.markAir, ClueID.markFire, ClueID.markEarth, ClueID.markWater,
                       ClueID.grimoireElements, ClueID.triptych, ClueID.windowOrion,
                       ClueID.slotShapes, ClueID.recipePage] {
            state.markClueViewed(clueID)
        }
    }

    private let sceneSize = CGSize(width: 2732, height: 1366)

    // MARK: cluster A — the lifecycle table covers the whole graph

    func testEveryGraphItemHasALifecycleEntry() {
        // ItemCatalog.all now spans both levels; each item must appear in ITS level's
        // lifecycle table (L1 ItemLifecycle.uses OR L2 Level2Graph.itemUses).
        for def in ItemCatalog.all {
            let inL1 = ItemLifecycle.uses[def.id] != nil
            let inL2 = Level2Graph.itemUses[def.id] != nil
            XCTAssertTrue(inL1 || inL2,
                          "\(def.id) must appear in a level lifecycle table (transcribed from puzzle-graph.json)")
        }
        // And the red-herring rule: an empty uses array is NEVER consumed.
        XCTAssertTrue(ItemLifecycle.uses[PuzzleGraph.ItemID.rustedKey]?.isEmpty == true)
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.rustedKey)
        // Solve literally everything; the rusted key must survive.
        satisfyAllGates(state)
        for puzzle in [PuzzleGraph.PuzzleID.runeDoor, PuzzleGraph.PuzzleID.moonTrapdoor,
                       PuzzleGraph.PuzzleID.astrolabeOrion, PuzzleGraph.PuzzleID.cabinetSunMoon,
                       PuzzleGraph.PuzzleID.ashSift, PuzzleGraph.PuzzleID.barrelPry,
                       PuzzleGraph.PuzzleID.shelfCounterweight, PuzzleGraph.PuzzleID.shutterWinch,
                       PuzzleGraph.PuzzleID.mirrorAim, PuzzleGraph.PuzzleID.moonflowerBloom,
                       PuzzleGraph.PuzzleID.cageUnlock, PuzzleGraph.PuzzleID.fileShavings,
                       PuzzleGraph.PuzzleID.grindPaste, PuzzleGraph.PuzzleID.brew,
                       PuzzleGraph.PuzzleID.fillPhial, PuzzleGraph.PuzzleID.doorUnseal,
                       PuzzleGraph.PuzzleID.escape] {
            state.markSolved(puzzle)
        }
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.rustedKey),
                      "red herring (uses []) must never be auto-consumed")
    }

    // MARK: cluster A — invariant harness: full playthroughs in multiple orderings

    /// One scripted step of a full engine-level playthrough.
    private struct Step {
        let name: String
        let run: (GameState) -> Void
    }

    /// The invariant: an item that was ever acquired and is now in NEITHER the
    /// inventory NOR the cauldron must have ALL its graph uses satisfied. Checked
    /// after EVERY step of every ordering, for EVERY item.
    private func runOrderingAssertingInvariant(_ steps: [Step], label: String,
                                               file: StaticString = #filePath, line: UInt = #line) {
        let state = makeState(tempDir())
        satisfyAllGates(state)
        var everAcquired: Set<String> = []
        for step in steps {
            step.run(state)
            everAcquired.formUnion(state.inventory)
            for itemID in everAcquired {
                let heldSomewhere = state.hasItem(itemID)
                    || state.data.cauldronIngredients.contains(itemID)
                if !heldSomewhere {
                    XCTAssertTrue(ItemLifecycle.isDepleted(itemID, state: state),
                                  "[\(label)] \(itemID) left play at step '\(step.name)' with an UNSATISFIED use — anti-softlock violation (R4-019 class)",
                                  file: file, line: line)
                }
            }
        }
        XCTAssertTrue(state.isComplete, "[\(label)] ordering must complete the level", file: file, line: line)
    }

    private func setDialsToSolution(_ s: GameState) {
        s.setMoonDialPosition(dial: 0, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waxingCrescent)!)
        s.setMoonDialPosition(dial: 1, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .full)!)
        s.setMoonDialPosition(dial: 2, phase: MoonDialSolution.clockwiseOrder.firstIndex(of: .waningGibbous)!)
    }

    private func pressRunes(_ s: GameState) {
        for rune in RuneDoorSolution.solutionOrder { PuzzleEngine.pressRuneTile(rune, state: s) }
    }

    private func brewAndEscape(_ s: GameState) {
        for id in [PuzzleGraph.ItemID.paste, PuzzleGraph.ItemID.shavings, PuzzleGraph.ItemID.feather] {
            s.removeItem(id)
        }
        s.setCauldronIngredients(BrewSolution.requiredIngredients)
        _ = PuzzleEngine.resolveBrew(flameStage: BrewSolution.flameStage,
                                     stirDirection: BrewSolution.stirDirection,
                                     stirCount: BrewSolution.stirCount, state: s)
        _ = PuzzleEngine.fillPhial(state: s)
        _ = PuzzleEngine.pourDraughtOnBasin(state: s)
        _ = PuzzleEngine.slideBoltAndLeave(state: s)
    }

    /// Shared step bank; orderings pick sequences from these.
    private var stepBank: [String: Step] {
        var bank: [String: Step] = [:]
        func add(_ name: String, _ run: @escaping (GameState) -> Void) {
            bank[name] = Step(name: name, run: run)
        }
        add("takePoker") { $0.addItem(PuzzleGraph.ItemID.poker) }
        add("p01") { self.pressRunes($0) }
        add("p02") { self.setDialsToSolution($0); _ = PuzzleEngine.evaluateMoonDials(state: $0) }
        add("p03") { _ = PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: $0) }
        add("collectDrawer") {
            _ = PuzzleEngine.collectItem(PuzzleGraph.ItemID.silverCoin, from: .astrolabeDrawer, state: $0)
            _ = PuzzleEngine.collectItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer, state: $0)
        }
        add("p05") { _ = PuzzleEngine.siftAsh(state: $0) }
        add("collectRing") { _ = PuzzleEngine.collectAshRing($0) }
        add("p06") { _ = PuzzleEngine.pryBarrel(state: $0) }
        add("collectWeight") { _ = PuzzleEngine.collectBarrelWeight($0) }
        add("p07") { _ = PuzzleEngine.hangWeight(state: $0) }
        add("p04") {
            _ = PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                               moon: CabinetSolution.moonSlotItem, state: $0)
        }
        add("collectCabinet") {
            _ = PuzzleEngine.collectItem(PuzzleGraph.ItemID.file, from: .sunMoonCabinet, state: $0)
            _ = PuzzleEngine.collectItem(PuzzleGraph.ItemID.phial, from: .sunMoonCabinet, state: $0)
        }
        add("p08") { _ = PuzzleEngine.fitCrankAndTurn(state: $0) }
        add("p09") { PuzzleEngine.rotateMirror(toDetent: MirrorSolution.solutionDetent, state: $0) }
        add("p10") { _ = PuzzleEngine.pickBlossom(state: $0) }
        add("collectKey") { _ = PuzzleEngine.collectStatueKey($0) }
        add("p11") { _ = PuzzleEngine.unlockCage(state: $0) }
        add("p12") { _ = PuzzleEngine.fileShavings(state: $0) }
        add("p13") { _ = PuzzleEngine.grindPaste(state: $0) }
        add("takeSpoon") { $0.addItem(PuzzleGraph.ItemID.spoon) }
        add("endgame") { self.brewAndEscape($0) }
        return bank
    }

    private func steps(_ names: [String]) -> [Step] {
        let bank = stepBank
        return names.map { bank[$0]! }
    }

    /// Ordering A (graph solve_path_notes): cellar chain early, p01 late — includes
    /// p06 BEFORE p05, the exact R4-019 soft-lock ordering.
    func testInvariantAndCompletability_orderingA_p06BeforeP05() {
        runOrderingAssertingInvariant(steps([
            "p02", "takePoker", "p06", "collectWeight", "p07", "collectKey", "p11",
            "p01", "p03", "collectDrawer", "p05", "collectRing", "p04", "collectCabinet",
            "p08", "p09", "p10", "takeSpoon", "p12", "p13", "endgame",
        ]), label: "ordering A (p06-before-p05)")
    }

    /// Ordering B: workshop first, cellar later.
    func testInvariantAndCompletability_orderingB() {
        runOrderingAssertingInvariant(steps([
            "takePoker", "p01", "p03", "collectDrawer", "p05", "collectRing", "p04",
            "collectCabinet", "p02", "takeSpoon", "p06", "collectWeight", "p07",
            "collectKey", "p08", "p09", "p10", "p11", "p12", "p13", "endgame",
        ]), label: "ordering B")
    }

    /// Ordering C: mirror set to detent-3 BEFORE the shutter opens (D2), and the
    /// cellar-first branch taken as far as possible before p01.
    func testInvariantAndCompletability_orderingC_mirrorFirst_cellarFirst() {
        runOrderingAssertingInvariant(steps([
            "takePoker", "p02", "p09", "p06", "collectWeight", "p07", "collectKey",
            "takeSpoon", "p01", "p03", "collectDrawer", "p05", "collectRing", "p04",
            "collectCabinet", "p08", "p10", "p11", "p12", "p13", "endgame",
        ]), label: "ordering C (mirror-first, cellar-first)")
    }

    // MARK: cluster A — the R4-019 soft-lock, reproduced at the coordinator layer

    func testPokerSurvivesBarrelBeforeAsh_thenConsumesAfterBoth_R4_019() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.addItem(PuzzleGraph.ItemID.poker)
        let interaction = InteractionModel()
        let cellar = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize,
                                          interaction: interaction)
        // The user's exact path: poker on the BARREL first (never sifted the ash).
        interaction.armedItem = PuzzleGraph.ItemID.poker
        cellar.scene.onHotspotTap?("barrel")
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.barrelPry))
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.poker),
                      "R4-019: the poker MUST survive p06 while p05 (ash sift) is unsatisfied")
        cellar.collectBarrelWeight()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.weight))
        // Now the ash: the second (and final) poker use.
        let hearth = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize,
                                          interaction: interaction)
        interaction.armedItem = PuzzleGraph.ItemID.poker
        hearth.scene.onHotspotTap?("ash")
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.ashSift))
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.poker),
                       "with BOTH uses satisfied the poker is consumed (uses-driven rule)")
        // The gold ring — the item R4-019 stranded — is still obtainable and usable.
        hearth.collectAshRing()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.goldRing), "the ring is NOT stranded")
    }

    /// Migration: a build-9 save that under-consumed (R4-030: spoon+file lingering
    /// after p12) comes clean; nothing with a remaining use is touched.
    func testBuild9SaveMigrationReconcilesLingeringItems() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        state.addItem(PuzzleGraph.ItemID.spoon)
        state.addItem(PuzzleGraph.ItemID.file)
        state.addItem(PuzzleGraph.ItemID.poker) // p05/p06 unsolved: must survive
        // Simulate the stale build-9 shape: p12 solved while its items are still held —
        // the markSolved hook (and, for an on-disk stale save, the init-time reconcile)
        // consumes them.
        state.markSolved(PuzzleGraph.PuzzleID.fileShavings)
        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertFalse(resumed.hasItem(PuzzleGraph.ItemID.spoon))
        XCTAssertFalse(resumed.hasItem(PuzzleGraph.ItemID.file))
        XCTAssertTrue(resumed.hasItem(PuzzleGraph.ItemID.poker), "items with remaining uses are untouched")
    }

    // MARK: cluster A — manual pickups (R4-013 weight, R4-026 statue key)

    func testStatueKeyIsManualPickupFromCloseUp_R4_026() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.unlockZone(PuzzleGraph.ZoneID.z4Alcove)
        let coordinator = RoomSceneCoordinator(viewID: .alcove, state: state, size: sceneSize)
        coordinator.scene.onHotspotTap?("statue-key")
        XCTAssertEqual(coordinator.activeCloseUp, .statueKey, "statue tap opens the close-up")
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.cageKey), "key is NOT auto-granted (R4-026)")
        XCTAssertTrue(PuzzleEngine.isStatueKeyUncollected(state), "key visible+pickable in the beak")
        coordinator.collectStatueKey()
        XCTAssertTrue(state.hasItem(PuzzleGraph.ItemID.cageKey), "explicit tap collects the key")
        XCTAssertFalse(PuzzleEngine.isStatueKeyUncollected(state))
        // Key-taken state renders afterwards (and after the key is SPENT at p11 too).
        XCTAssertTrue(RoomVisuals.cageKeyTaken(state))
        _ = PuzzleEngine.unlockCage(state: state) // consumes the key (its only use)
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.cageKey))
        XCTAssertTrue(RoomVisuals.cageKeyTaken(state), "consumed key must NOT re-appear in the beak")
        XCTAssertFalse(PuzzleEngine.isStatueKeyUncollected(state))
    }

    func testWeightManualPickupSurvivesRelaunch_antiSoftlock() {
        let dir = tempDir()
        let state = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        state.addItem(PuzzleGraph.ItemID.poker)
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))
        // Quit between prying and collecting: the weight must still be waiting.
        let resumed = GameState(levelID: 1, store: SaveGameStore(directory: dir))
        XCTAssertTrue(PuzzleEngine.isWeightUncollectedInBarrel(resumed))
        XCTAssertTrue(PuzzleEngine.collectBarrelWeight(resumed))
        XCTAssertTrue(resumed.hasItem(PuzzleGraph.ItemID.weight))
    }

    /// Consumed items must not re-appear as collectable in their containers
    /// (derived-uncollected predicates exclude every sink).
    func testConsumedItemsNeverReappearCollectable() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar) // fitCrankAndTurn requires z3 (CI run 29164191154 fix)
        satisfyAllGates(state)
        XCTAssertTrue(PuzzleEngine.selectAstrolabePlate(AstrolabeSolution.solutionPlateIndex, state: state))
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.crank, from: .astrolabeDrawer, state: state))
        _ = PuzzleEngine.fitCrankAndTurn(state: state) // crank consumed (p08)
        XCTAssertFalse(state.hasItem(PuzzleGraph.ItemID.crank))
        XCTAssertFalse(PuzzleEngine.isUncollected(PuzzleGraph.ItemID.crank, state: state),
                       "a consumed crank must not re-appear in the drawer")
        // Same for the file after p12.
        state.addItem(PuzzleGraph.ItemID.silverCoin)
        state.addItem(PuzzleGraph.ItemID.goldRing)
        XCTAssertTrue(PuzzleEngine.placeCabinetItems(sun: CabinetSolution.sunSlotItem,
                                                     moon: CabinetSolution.moonSlotItem, state: state))
        XCTAssertTrue(PuzzleEngine.collectItem(PuzzleGraph.ItemID.file, from: .sunMoonCabinet, state: state))
        state.addItem(PuzzleGraph.ItemID.spoon)
        XCTAssertTrue(PuzzleEngine.fileShavings(state: state)) // file+spoon consumed (p12)
        XCTAssertFalse(PuzzleEngine.isUncollected(PuzzleGraph.ItemID.file, state: state),
                       "a consumed file must not re-appear in the cabinet")
        // And the drawer never re-shows a consumed spoon (R4-012(2) class).
        XCTAssertEqual(RoomVisuals.drawerOverlay(state), "ov-drawer-empty")
    }

    // MARK: cluster F — armed-item model (R4-005)

    func testArmedItemNeverBlocksLooks_R4_005() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.rustedKey)
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize,
                                               interaction: interaction)
        interaction.armedItem = PuzzleGraph.ItemID.rustedKey
        // The rusted key has no use at the clock — the tap must FALL THROUGH to the
        // normal look (close-up opens) with the item STILL armed.
        coordinator.scene.onHotspotTap?("clock")
        XCTAssertEqual(coordinator.activeCloseUp, .clock,
                       "an armed item must never block opening a close-up (R4-005)")
        XCTAssertEqual(interaction.armedItem, PuzzleGraph.ItemID.rustedKey,
                       "the failed use keeps the item armed (R2-030)")
        coordinator.dismissCloseUp()
        // Clue close-ups too (the user's exact report: rune marks not inspectable).
        coordinator.scene.onHotspotTap?("lintel")
        XCTAssertEqual(coordinator.activeCloseUp, .plain(image: "cu-lintel"))
        XCTAssertTrue(state.hasViewedClue(ClueID.markFire),
                      "clue recording works even while an item is armed")
        XCTAssertEqual(interaction.armedItem, PuzzleGraph.ItemID.rustedKey)
    }

    func testEmptySceneTapDisarms_R4_005() {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.poker)
        let interaction = InteractionModel()
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize,
                                               interaction: interaction)
        interaction.armedItem = PuzzleGraph.ItemID.poker
        coordinator.scene.onEmptyTap?()
        XCTAssertNil(interaction.armedItem, "tapping empty space disarms (tap-away deselect)")
    }

    // MARK: R4-020(1) — per-slot placement feedback + gate interaction

    func testCorrectPartialPlacementGivesPositiveFeedback_R4_020() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state.addItem(PuzzleGraph.ItemID.goldRing)
        state.addItem(PuzzleGraph.ItemID.silverCoin)
        // Deliberately do NOT satisfy any gates: seating an item must itself count as
        // seeing the slot shapes (equivalent exposure), so a correct pair placed from
        // the wide view can never be silently refused by the gate.
        let coordinator = RoomSceneCoordinator(viewID: .cabinet, state: state, size: sceneSize)
        SoundManager.shared.resetPlayedLog()
        // COIN FIRST (the user's order in R4-020).
        coordinator.useItem(PuzzleGraph.ItemID.silverCoin, on: "moon-slot")
        XCTAssertEqual(coordinator.pendingMoonItem, PuzzleGraph.ItemID.silverCoin, "correct item seats visibly")
        XCTAssertTrue(SoundManager.shared.playedLog.contains(.seat),
                      "a correct partial placement plays the POSITIVE seat cue")
        XCTAssertFalse(SoundManager.shared.playedLog.contains(.wrong),
                       "no negative-sounding cue on a correct placement (R4-020(1))")
        XCTAssertTrue(state.hasViewedClue(ClueID.slotShapes), "seating records the slot-shapes clue")
        // Ring completes the pair.
        coordinator.useItem(PuzzleGraph.ItemID.goldRing, on: "sun-slot")
        XCTAssertTrue(state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon))
        XCTAssertTrue(SoundManager.shared.playedLog.contains(.solve))
        // And the reverse order still works (fresh state) — ring first.
        let state2 = makeState(tempDir())
        state2.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
        state2.addItem(PuzzleGraph.ItemID.goldRing)
        state2.addItem(PuzzleGraph.ItemID.silverCoin)
        let coordinator2 = RoomSceneCoordinator(viewID: .cabinet, state: state2, size: sceneSize)
        coordinator2.useItem(PuzzleGraph.ItemID.goldRing, on: "sun-slot")
        XCTAssertEqual(coordinator2.pendingSunItem, PuzzleGraph.ItemID.goldRing)
        coordinator2.useItem(PuzzleGraph.ItemID.silverCoin, on: "moon-slot")
        XCTAssertTrue(state2.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon))
    }

    // MARK: cluster D — the default-tap/nav "psh" class can never silently return

    /// The four reported psh instances (nav chevrons R4-027, cellar entry R4-010,
    /// drawer R4-012(1), workshop entry R4-017) all traced to ONE asset — sfx-wood —
    /// fired as a blanket navigation/passage beat. Guard: the retired assets are GONE
    /// from the bundle, so no surviving trigger could even play them.
    func testRetiredPshAndOceanAssetsDoNotShip_build10() {
        for retired in ["sfx-wood", "sfx-entry", "amb-z1", "amb-z2", "amb-z3", "amb-z4",
                        "sfx-menu-tap", "sfx-click"] {
            XCTAssertNil(Bundle.main.url(forResource: retired, withExtension: "wav", subdirectory: "Audio")
                ?? Bundle.main.url(forResource: retired, withExtension: "wav"),
                         "\(retired).wav is retired (cluster D / R4-002 / R4-003) and must NOT ship")
        }
        // The new positive seat cue ships.
        XCTAssertNotNil(Bundle.main.url(forResource: "sfx-seat", withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "sfx-seat", withExtension: "wav"),
                        "sfx-seat.wav (R4-020(1) positive placement cue) must ship")
    }

    func testDrawerOpenIsSilent_spoonPickupChimes_clusterD() {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        let coordinator = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize)
        SoundManager.shared.resetPlayedLog()
        coordinator.scene.onHotspotTap?("drawer") // open: visual only (R4-012(1))
        XCTAssertTrue(SoundManager.shared.playedLog.isEmpty,
                      "drawer open is silent — the sfx-wood psh is removed (cluster D)")
        coordinator.scene.onHotspotTap?("drawer") // take spoon
        XCTAssertEqual(SoundManager.shared.playedLog, [.pickup])
    }
}

/// Round 6 Cluster A — container/pickup TAKEN-STATE render guard (close-up + wide).
///
/// Extends the build-10 rendered-frame overlay guard to cover EVERY element's
/// partial/taken/emptied state, not a sample. The close-up compositor is SwiftUI, so it is
/// guarded here at the pure decision layer (`ContainerCloseUpModel.plan`) — which, by
/// construction, has NO masking layer, so the "black box" (R6-008/-010) cannot recur. The
/// wide taken-state is guarded via the `RoomVisuals` resolvers. R6-008 (astrolabe drawer:
/// coin + crank, all three defects on one close-up) is the regression fixture.
final class ContainerTakenStateGuardTests: XCTestCase {
    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private func makeState() -> GameState { GameState(levelID: 1, store: SaveGameStore(directory: tempDir())) }

    private func ids(_ items: [CloseUpLayout.ContainerItemVisual]) -> [String] { items.map { $0.id } }

    // MARK: Close-up per-element decision (R6-008 fixture: astrolabe coin + crank)

    func testAstrolabeCloseUpTakenState_R6_008() {
        let state = makeState()
        state.markSolved(PuzzleGraph.PuzzleID.astrolabeOrion) // drawer sprung, both uncollected
        let existsAll: (String) -> Bool = { _ in true }

        // 0 taken: the painted open plate shows both; no icons, both tappable.
        var plan = ContainerCloseUpModel.plan(.astrolabeDrawer, state: state, assetExists: existsAll)
        XCTAssertEqual(plan.base, "cu-astrolabe-drawer-open")
        XCTAssertTrue(plan.iconItems.isEmpty)
        XCTAssertEqual(Set(ids(plan.tapTargets)), [PuzzleGraph.ItemID.silverCoin, PuzzleGraph.ItemID.crank])

        // 1 taken (coin): empty base + crank icon only; the coin DISAPPEARS (no black box,
        // never appears in icons OR tap targets).
        state.addItem(PuzzleGraph.ItemID.silverCoin)
        plan = ContainerCloseUpModel.plan(.astrolabeDrawer, state: state, assetExists: existsAll)
        XCTAssertEqual(plan.base, "cu-astrolabe-drawer-empty")
        XCTAssertEqual(ids(plan.iconItems), [PuzzleGraph.ItemID.crank])
        XCTAssertEqual(ids(plan.tapTargets), [PuzzleGraph.ItemID.crank])
        XCTAssertFalse(ids(plan.iconItems).contains(PuzzleGraph.ItemID.silverCoin))
        XCTAssertFalse(ids(plan.tapTargets).contains(PuzzleGraph.ItemID.silverCoin))

        // 2 taken: empty base, nothing composited, nothing tappable — reads empty.
        state.addItem(PuzzleGraph.ItemID.crank)
        plan = ContainerCloseUpModel.plan(.astrolabeDrawer, state: state, assetExists: existsAll)
        XCTAssertEqual(plan.base, "cu-astrolabe-drawer-empty")
        XCTAssertTrue(plan.iconItems.isEmpty)
        XCTAssertTrue(plan.tapTargets.isEmpty)
    }

    func testCabinetCloseUpTakenState_emptyPlateStaged_R6_010() {
        let state = makeState()
        state.markSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
        let existsAll: (String) -> Bool = { _ in true } // simulate cu-cabinet-empty staged (post-JOIN)

        var plan = ContainerCloseUpModel.plan(.sunMoonCabinet, state: state, assetExists: existsAll)
        XCTAssertEqual(plan.base, "cu-cabinet-open") // both present: painted plate
        XCTAssertEqual(Set(ids(plan.tapTargets)), [PuzzleGraph.ItemID.file, PuzzleGraph.ItemID.phial])

        state.addItem(PuzzleGraph.ItemID.file) // take file
        plan = ContainerCloseUpModel.plan(.sunMoonCabinet, state: state, assetExists: existsAll)
        XCTAssertEqual(plan.base, "cu-cabinet-empty") // clean empty base + remaining icon
        XCTAssertEqual(ids(plan.iconItems), [PuzzleGraph.ItemID.phial])
        XCTAssertFalse(ids(plan.tapTargets).contains(PuzzleGraph.ItemID.file), "taken file disappears")

        state.addItem(PuzzleGraph.ItemID.phial)
        plan = ContainerCloseUpModel.plan(.sunMoonCabinet, state: state, assetExists: existsAll)
        XCTAssertEqual(plan.base, "cu-cabinet-empty")
        XCTAssertTrue(plan.iconItems.isEmpty)
        XCTAssertTrue(plan.tapTargets.isEmpty, "container reads empty when all taken")
    }

    func testCabinetCloseUpTakenState_interimFallback_noBlackBox() {
        // Interim (my worktree): cu-cabinet-empty NOT yet staged. The fallback keeps the
        // baked plate but composites NO mask — the reported black box cannot occur — and the
        // remaining item stays tappable. Fully clean once the empty plate lands (test above).
        let state = makeState()
        state.markSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
        let emptyAbsent: (String) -> Bool = { $0 != "cu-cabinet-empty" }

        state.addItem(PuzzleGraph.ItemID.file)
        let plan = ContainerCloseUpModel.plan(.sunMoonCabinet, state: state, assetExists: emptyAbsent)
        XCTAssertEqual(plan.base, "cu-cabinet-open")
        XCTAssertFalse(plan.emptyBaseAvailable)
        XCTAssertTrue(plan.iconItems.isEmpty)               // no icons drawn on the baked plate
        XCTAssertEqual(ids(plan.tapTargets), [PuzzleGraph.ItemID.phial]) // taken file untappable
    }

    // MARK: Wide taken-state resolvers

    func testAstrolabeDrawerWideTakenState_R6_008_wide() {
        let state = makeState()
        XCTAssertNil(RoomVisuals.astrolabeDrawerOverlay(state), "closed before solve")
        state.markSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
        XCTAssertEqual(RoomVisuals.astrolabeDrawerOverlay(state), "ov-adrawer-open",
                       "contents shown while uncollected")
        state.addItem(PuzzleGraph.ItemID.silverCoin)
        state.addItem(PuzzleGraph.ItemID.crank)
        // Both collected: the wide must NOT keep showing the coin+crank overlay.
        XCTAssertNotEqual(RoomVisuals.astrolabeDrawerOverlay(state), "ov-adrawer-open",
                          "R6-008-wide: stale contents must not linger after collect")
    }

    func testBarrelWideTakenState_R6_005() {
        let state = makeState()
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        XCTAssertNil(RoomVisuals.barrelOverlay(state), "nailed barrel: no overlay")
        state.addItem(PuzzleGraph.ItemID.poker)
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))
        XCTAssertEqual(RoomVisuals.barrelOverlay(state), "ov-barrel-pried", "weight visible while uncollected")
        XCTAssertTrue(PuzzleEngine.collectBarrelWeight(state)) // take the weight
        let after = RoomVisuals.barrelOverlay(state)
        // R6-005: prefer the emptied-pried overlay when staged; never nil (no re-nailing).
        XCTAssertNotNil(after, "the pried barrel must never re-nail itself")
        if RoomVisuals.assetAvailable("ov-barrel-pried-empty") {
            XCTAssertEqual(after, "ov-barrel-pried-empty", "emptied-pried overlay hides the taken weight")
        } else {
            XCTAssertEqual(after, "ov-barrel-pried", "interim fallback keeps the pried look pending JOIN art")
        }
    }
}
