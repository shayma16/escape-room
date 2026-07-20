import XCTest
@testable import EscapeRoom

/// Unit tests for Level 2 "The Clockmaker's Attic" requirement-based state machines,
/// item lifecycle, zone unlocks, clue gates, the mirror/naive-time trap, and save/resume.
/// (Game-flow/UX correctness is QA's job; these lock the Developer's own core logic.)
final class Level2Tests: XCTestCase {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeState(_ dir: URL? = nil) -> GameState {
        GameState(levelID: 2, store: SaveGameStore(directory: dir ?? tempDir()))
    }

    // Engine-level solve tests bypass the close-up UI that records clue views, so mark the
    // gating clues viewed where a solve (not a gate) is under test.
    private func viewGates(_ state: GameState, _ clues: String...) {
        for c in clues { state.markClueViewed(c) }
    }

    // MARK: - Start zone / rules

    func testLevel2StartZoneUnlocked() {
        let s = makeState()
        XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z1Attic))
        XCTAssertFalse(s.isZoneUnlocked(Level2Graph.ZoneID.z2Workroom))
    }

    func testLevel1RulesUnaffected() {
        // Regression guard: Level 1 GameState still unlocks its own start zone (z1-cabin),
        // NOT the L2 attic — the level-rules split must not cross-wire the levels.
        let s = GameState(levelID: 1, store: SaveGameStore(directory: tempDir()))
        XCTAssertTrue(s.isZoneUnlocked(PuzzleGraph.ZoneID.z1Cabin))
        XCTAssertFalse(s.isZoneUnlocked(Level2Graph.ZoneID.z1Attic))
    }

    // MARK: - p01 numeral-dial door

    func testDialDoorCompletesAndUnlocksZ2_anyOrder() {
        let s = makeState()
        for id in [Level2Graph.ItemID.tileII, Level2Graph.ItemID.tileIV,
                   Level2Graph.ItemID.tileVII, Level2Graph.ItemID.tileXI] { s.addItem(id) }
        // Seat in a scrambled order — requirement-flag model, not step order.
        XCTAssertEqual(Level2Engine.seatDialTile(Level2Graph.ItemID.tileVII, socket: "7", state: s), .seated)
        XCTAssertEqual(Level2Engine.seatDialTile(Level2Graph.ItemID.tileII, socket: "2", state: s), .seated)
        XCTAssertEqual(Level2Engine.seatDialTile(Level2Graph.ItemID.tileXI, socket: "11", state: s), .seated)
        XCTAssertEqual(Level2Engine.seatDialTile(Level2Graph.ItemID.tileIV, socket: "4", state: s), .solved)
        XCTAssertTrue(s.hasSolved(Level2Graph.PuzzleID.dialDoor))
        XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z2Workroom))
        // Tiles seated leave inventory.
        XCTAssertFalse(s.hasItem(Level2Graph.ItemID.tileIV))
    }

    func testDialDoorWrongTileAndDecoyRejected() {
        let s = makeState()
        s.addItem(Level2Graph.ItemID.tileIV)
        // IV into socket 2 (wrong socket): rejected, stays in inventory.
        XCTAssertEqual(Level2Engine.seatDialTile(Level2Graph.ItemID.tileIV, socket: "2", state: s), .rejected)
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.tileIV))
        // The tray VI decoy (never an inventory item) into socket 4: rejected (glyph-order bait).
        XCTAssertEqual(Level2Engine.seatDialTile("tile-vi-decoy", socket: "4", state: s), .rejected)
        XCTAssertFalse(s.hasSolved(Level2Graph.PuzzleID.dialDoor))
    }

    // MARK: - p02 cat and the wind-up mouse

    func testCatMouseYieldsWatchBAndConsumesMouse() {
        let s = makeState()
        s.addItem(Level2Graph.ItemID.toyMouse)
        XCTAssertTrue(Level2Engine.placeMouseAtCat(state: s))
        XCTAssertTrue(s.hasSolved(Level2Graph.PuzzleID.catMouse))
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.watchB))
        XCTAssertFalse(s.hasItem(Level2Graph.ItemID.toyMouse), "cat keeps the mouse (consumed by design)")
    }

    func testCatOfferGrammar() {
        XCTAssertEqual(Level2Engine.offerItemToCat(Level2Graph.ItemID.toyMouse), .mouseTell)
        XCTAssertEqual(Level2Engine.offerItemToCat(Level2Graph.ItemID.screwdriver), .refusal)
        // Offering the mouse directly must NOT execute p02 or lose the mouse (D3/D4).
        let s = makeState()
        s.addItem(Level2Graph.ItemID.toyMouse)
        XCTAssertEqual(Level2Engine.offerItemToCat(Level2Graph.ItemID.toyMouse), .mouseTell)
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.toyMouse))
        XCTAssertFalse(s.hasSolved(Level2Graph.PuzzleID.catMouse))
    }

    // MARK: - p03 / p04 clue-gated pry caches (D10 faint-tell)

    func testDormerPryGateAndFaintTell() {
        let s = makeState()
        s.addItem(Level2Graph.ItemID.screwdriver)
        // Wrong spot pre-clue: dead.
        XCTAssertEqual(Level2Engine.pryDormerBoard(isCorrectSpot: false, state: s), .dead)
        // CORRECT spot pre-clue: faint-tell (D10), no yield, no state change.
        XCTAssertEqual(Level2Engine.pryDormerBoard(isCorrectSpot: true, state: s), .faintTell)
        XCTAssertFalse(s.hasSolved(Level2Graph.PuzzleID.cacheDormer))
        // After viewing watch A: the correct board yields; great wheel becomes collectable.
        viewGates(s, Level2ClueID.watchA)
        XCTAssertEqual(Level2Engine.pryDormerBoard(isCorrectSpot: true, state: s), .yielded)
        XCTAssertTrue(Level2Engine.isGreatWheelUncollected(s))
        XCTAssertTrue(Level2Engine.collectGreatWheel(s))
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.greatWheel))
    }

    func testDormerPryRequiresScrewdriver() {
        let s = makeState()
        viewGates(s, Level2ClueID.watchA)
        XCTAssertEqual(Level2Engine.pryDormerBoard(isCorrectSpot: true, state: s), .dead, "no tool = dead")
    }

    func testChimneyPryRequiresZ2AndWatchB() {
        let s = makeState()
        s.addItem(Level2Graph.ItemID.screwdriver)
        viewGates(s, Level2ClueID.watchB)
        // z2 not unlocked yet: dead.
        XCTAssertEqual(Level2Engine.pryChimneyBrick(isCorrectSpot: true, state: s), .dead)
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        XCTAssertEqual(Level2Engine.pryChimneyBrick(isCorrectSpot: true, state: s), .yielded)
        XCTAssertTrue(Level2Engine.collectOilcan(s))
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.oilcan))
    }

    // MARK: - p05 / p06 machine stream

    func testGearTrainBothArrangementsSolve() {
        for (a, b) in [("36", "64"), ("64", "36")] {
            let s = makeState()
            s.unlockZone(Level2Graph.ZoneID.z2Workroom)
            s.addItem(Level2Graph.ItemID.oilcan)
            XCTAssertTrue(Level2Engine.oilArbor(state: s))
            s.addItem(Level2Graph.ItemID.greatWheel)
            XCTAssertTrue(Level2Engine.mountGear(a, on: .a, state: s))
            XCTAssertTrue(Level2Engine.mountGear(b, on: .b, state: s))
            XCTAssertTrue(Level2Engine.isGearTrainCorrect(s))
            XCTAssertTrue(Level2Engine.crankGearTrain(state: s), "\(a)/\(b) is 24:1")
            XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial))
        }
    }

    func testGearTrainWrongRatioAndLone48() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.addItem(Level2Graph.ItemID.oilcan)
        Level2Engine.oilArbor(state: s)
        // 48 x 48 = 2304 arithmetically, but only one 48 exists (rh-48-gear): can't build it.
        XCTAssertTrue(Level2Engine.mountGear("48", on: .a, state: s))
        XCTAssertTrue(Level2Engine.mountGear("40", on: .b, state: s))   // second 48 unavailable
        XCTAssertFalse(Level2Engine.isGearTrainCorrect(s))
        XCTAssertFalse(Level2Engine.crankGearTrain(state: s))
        XCTAssertFalse(s.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial))
    }

    func testGearTrainRequiresArborFreed() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.addItem(Level2Graph.ItemID.greatWheel)
        Level2Engine.mountGear("36", on: .a, state: s)
        Level2Engine.mountGear("64", on: .b, state: s)
        XCTAssertFalse(Level2Engine.crankGearTrain(state: s), "seized arbor: crank does nothing")
    }

    func testGreatWheelUnmountReturnsToInventory() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.addItem(Level2Graph.ItemID.greatWheel)
        XCTAssertTrue(Level2Engine.mountGear("64", on: .a, state: s))
        XCTAssertFalse(s.hasItem(Level2Graph.ItemID.greatWheel), "mounted: out of inventory")
        Level2Engine.unmountGear(.a, state: s)
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.greatWheel), "unmounted: returns to inventory")
    }

    // MARK: - p07 vault code (clue-gated, code changed to VI-X-I-III at rev 1.2)

    func testVaultCorrectCodeGatedThenUnlocks() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        // Set the correct code but WITHOUT the gating clues: hatch stays shut (no tell).
        for (i, v) in Level2Graph.vaultSolution.enumerated() { Level2Engine.setVaultWheel(i, value: v, state: s) }
        XCTAssertFalse(s.hasSolved(Level2Graph.PuzzleID.vaultWheels))
        // View both clues -> stale-correct-wheels re-evaluates and opens (D6).
        viewGates(s, Level2ClueID.masterTime, Level2ClueID.worldClockRow)
        Level2Engine.reevaluateVaultOnCloseUpEntry(state: s)
        XCTAssertTrue(s.hasSolved(Level2Graph.PuzzleID.vaultWheels))
        XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z4Vault))
    }

    func testVaultWrongCodeStaysShut() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        viewGates(s, Level2ClueID.masterTime, Level2ClueID.worldClockRow)
        for (i, v) in [6, 7, 1, 3].enumerated() { Level2Engine.setVaultWheel(i, value: v, state: s) } // old (pre-1.2) code
        XCTAssertFalse(s.hasSolved(Level2Graph.PuzzleID.vaultWheels))
    }

    // MARK: - p08 oil + wind (order enforced within the mechanism)

    func testWindRequiresOilFirst() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        s.addItem(Level2Graph.ItemID.windingKey)
        s.addItem(Level2Graph.ItemID.oilcan)
        XCTAssertFalse(Level2Engine.windDrum(state: s), "key before oil: won't turn")
        XCTAssertTrue(Level2Engine.oilDrum(state: s))
        XCTAssertTrue(Level2Engine.windDrum(state: s))
        XCTAssertTrue(s.hasFlag(Level2Graph.Flag.clockWound))
    }

    // MARK: - p09 mirrored-dial trap (naive 4:40 vs true 7:20)

    func testNaiveTrapDoesNotReleaseButTrueTimeDoes() {
        let s = wiredForEndgame()
        viewGates(s, Level2ClueID.returnTag)
        // Naive un-mirrored copy sets FRONT to 4:40 -> not release.
        s.setL2ClockFrontMinutes(Level2Graph.clockNaiveTrapMinutes)
        XCTAssertFalse(Level2Engine.isHandsAtRelease(s))
        XCTAssertFalse(Level2Engine.evaluateTimelock(state: s))
        // The mirrored answer, front 7:20 -> release (all three conditions now hold).
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)
        XCTAssertTrue(Level2Engine.isHandsAtRelease(s))
        XCTAssertTrue(Level2Engine.evaluateTimelock(state: s))
        XCTAssertTrue(s.hasFlag(Level2Graph.Flag.doorBarRaised))
    }

    func testHandsAtReleaseGatedByReturnTag() {
        let s = wiredForEndgame()
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes) // correct time...
        XCTAssertFalse(Level2Engine.isHandsAtRelease(s), "...but tag not viewed: never asserts")
        viewGates(s, Level2ClueID.returnTag)
        XCTAssertTrue(Level2Engine.isHandsAtRelease(s))
    }

    // MARK: - cond-timelock-release: order-free + latched

    func testTimelockOrderFree_pendulumFirst() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        viewGates(s, Level2ClueID.returnTag)
        XCTAssertTrue(Level2Engine.pushPendulum(state: s))                 // pendulum first
        Level2Engine.adjustClock(byDetents: Level2Graph.clockReleaseMinutes / 5, state: s) // 7:20
        XCTAssertFalse(s.hasFlag(Level2Graph.Flag.doorBarRaised), "not wound yet")
        s.addItem(Level2Graph.ItemID.oilcan); s.addItem(Level2Graph.ItemID.windingKey)
        Level2Engine.oilDrum(state: s)
        XCTAssertTrue(Level2Engine.windDrum(state: s))                     // winding completes trio
        XCTAssertTrue(s.hasFlag(Level2Graph.Flag.doorBarRaised))
    }

    func testTimelockLatchesPermanently() {
        let s = wiredForEndgame()
        viewGates(s, Level2ClueID.returnTag)
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)
        XCTAssertTrue(Level2Engine.evaluateTimelock(state: s))
        // Fiddling the hands away AFTER the latch must not re-lock the door (D2).
        s.setL2ClockFrontMinutes(0)
        _ = Level2Engine.evaluateTimelock(state: s)
        XCTAssertTrue(s.hasFlag(Level2Graph.Flag.doorBarRaised))
        XCTAssertTrue(Level2Engine.openStairDoor(state: s))
        XCTAssertTrue(s.isComplete)
    }

    func testAliveWrongTimeAmbient() {
        let s = wiredForEndgame()
        viewGates(s, Level2ClueID.returnTag)
        s.setL2ClockFrontMinutes(Level2Graph.clockNaiveTrapMinutes) // wound + swinging + wrong time
        XCTAssertTrue(Level2Engine.isAliveWrongTime(s))
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)
        _ = Level2Engine.evaluateTimelock(state: s)
        XCTAssertFalse(Level2Engine.isAliveWrongTime(s), "strike fires: ambient stops")
    }

    /// z3 reached, wound + pendulum running (but hands not yet at release).
    private func wiredForEndgame() -> GameState {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        s.setFlag(Level2Graph.Flag.clockWound)
        s.setFlag(Level2Graph.Flag.pendulumRunning)
        return s
    }

    // MARK: - Item lifecycle (uses-driven; alternate orderings)

    func testScrewdriverConsumedOnlyAfterBothCaches() {
        let s = makeState()
        s.addItem(Level2Graph.ItemID.screwdriver)
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        viewGates(s, Level2ClueID.watchA, Level2ClueID.watchB)
        Level2Engine.pryDormerBoard(isCorrectSpot: true, state: s)   // p03
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.screwdriver), "one use left (p04) -> retained")
        Level2Engine.pryChimneyBrick(isCorrectSpot: true, state: s)  // p04
        XCTAssertFalse(s.hasItem(Level2Graph.ItemID.screwdriver), "both uses done -> consumed")
    }

    func testOilcanRetainedAcrossBothUses() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.addItem(Level2Graph.ItemID.oilcan)
        Level2Engine.oilArbor(state: s)                              // p05
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.oilcan), "p08 still pending -> retained")
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        s.addItem(Level2Graph.ItemID.windingKey)
        Level2Engine.oilDrum(state: s)
        Level2Engine.windDrum(state: s)                             // p08
        XCTAssertFalse(s.hasItem(Level2Graph.ItemID.oilcan), "both uses done -> consumed")
    }

    func testClueCarriersNeverConsumed() {
        let s = makeState()
        for id in [Level2Graph.ItemID.watchA, Level2Graph.ItemID.watchB, Level2Graph.ItemID.returnTag] {
            s.addItem(id)
        }
        // Solve everything solvable; empty-uses carriers must remain inspectable forever.
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        s.markSolved(Level2Graph.PuzzleID.gearTrain)
        s.markSolved(Level2Graph.PuzzleID.oilWind)
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.watchA))
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.watchB))
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.returnTag))
    }

    // MARK: - Save / resume

    func testSaveResumeRoundTripsAllL2Fields() {
        let dir = tempDir()
        do {
            let s = makeState(dir)
            s.addItem(Level2Graph.ItemID.watchA)
            s.setL2DialSocket("2", tile: Level2Graph.ItemID.tileII)
            s.setL2GearPost(.a, gear: "36")
            s.setL2VaultWheel(1, value: 10)
            s.setL2ClockFrontMinutes(440)
            s.setFlag(Level2Graph.Flag.clockWound)
            s.markClueViewed(Level2ClueID.returnTag)
        }
        // Fresh store over the same directory = relaunch.
        let s2 = makeState(dir)
        XCTAssertTrue(s2.hasItem(Level2Graph.ItemID.watchA))
        XCTAssertEqual(s2.data.l2DialSockets["2"], Level2Graph.ItemID.tileII)
        XCTAssertEqual(s2.data.l2GearPostA, "36")
        XCTAssertEqual(s2.data.l2VaultWheels[1], 10)
        XCTAssertEqual(s2.data.l2ClockFrontMinutes, 440)
        XCTAssertTrue(s2.hasFlag(Level2Graph.Flag.clockWound))
        XCTAssertTrue(s2.hasViewedClue(Level2ClueID.returnTag))
    }

    func testLevelSaveDataCodableRoundTrip() throws {
        var d = LevelSaveData(levelID: 2)
        d.l2VaultWheels = [6, 10, 1, 3]
        d.l2ClockFrontMinutes = 440
        d.l2GearPostB = "64"
        let data = try JSONEncoder().encode(d)
        let back = try JSONDecoder().decode(LevelSaveData.self, from: data)
        XCTAssertEqual(back, d)
    }
}
