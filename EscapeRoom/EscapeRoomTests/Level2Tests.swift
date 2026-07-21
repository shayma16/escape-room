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

    // MARK: - Level-scoped music (music-level2.wav is the L2 bed)

    /// The L2 bed is level-scoped like L1's (R3-001): `enterLevel(2)` selects music-level2,
    /// the file must ship, and exiting clears the level scope. Restores the level-1 default
    /// afterward so it does not leak into other tests' shared SoundManager singleton.
    func testLevel2MusicIsLevelScopedAndBundled() {
        XCTAssertNotNil(Bundle.main.url(forResource: "music-level2", withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: "music-level2", withExtension: "wav"),
            "music-level2.wav must ship in the bundle")
        let sm = SoundManager.shared
        sm.enterLevel(levelID: 2)
        XCTAssertEqual(sm.debugMusicResource, "music-level2", "L2 selects its own bed, not the L1 track")
        XCTAssertTrue(sm.debugInLevel)
        sm.exitLevel()
        XCTAssertFalse(sm.debugInLevel, "exiting the level clears the music scope")
        XCTAssertFalse(sm.isMusicActive, "music stops on exit")
        sm.enterLevel(levelID: 1)   // restore default for the shared singleton
        sm.exitLevel()
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

    /// Regression for the discovered critical gap: the bench coat close-up must actually
    /// COLLECT watch A + tile IV (the prior plain-image close-up had no pickup path, so tile
    /// IV was unobtainable and p01 — hence the whole level — was uncompletable through the UI).
    func testCoatCloseUpCollectsWatchAAndTileIV() {
        let s = makeState()
        let coord = Level2Coordinator(viewID: .bench, state: s, size: CGSize(width: 2732, height: 1366))
        coord.scene.onHotspotTap?("coat")
        XCTAssertEqual(coord.activeCloseUp, .coat, "coat tap opens the collectible pocket close-up")
        XCTAssertFalse(s.hasItem(Level2Graph.ItemID.tileIV))
        coord.collectCoatTileIV()
        coord.collectCoatWatchA()
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.tileIV), "tile IV collectable (p01 now solvable in-app)")
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.watchA), "watch A collectable")
        // Idempotent: re-collecting does nothing (already taken).
        coord.collectCoatTileIV()
        XCTAssertEqual(s.inventory.filter { $0 == Level2Graph.ItemID.tileIV }.count, 1)
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

    /// M3 / m2: the pure z3 mechanism descriptor that drives the pendulum swing + D11 ambient.
    /// (The SpriteKit motion itself needs a live view; this locks the state->motion decisions.)
    func testDialMechanismDescriptor() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        // Nothing running yet: no swing, no ambient.
        XCTAssertEqual(Level2Visuals.dialMechanism(s),
                       .init(pendulumSwinging: false, pendulumFullSwing: false, aliveWrongTime: false))
        // Pendulum pushed BEFORE winding: weak swing, no D11 ambient (not wound).
        XCTAssertTrue(Level2Engine.pushPendulum(state: s))
        XCTAssertEqual(Level2Visuals.dialMechanism(s),
                       .init(pendulumSwinging: true, pendulumFullSwing: false, aliveWrongTime: false))
        // Wound at a WRONG time: full swing + D11 alive-wrong-time ambient (m2 + M3).
        s.setFlag(Level2Graph.Flag.clockWound)
        viewGates(s, Level2ClueID.returnTag)
        s.setL2ClockFrontMinutes(Level2Graph.clockNaiveTrapMinutes)
        _ = Level2Engine.evaluateTimelock(state: s)
        XCTAssertEqual(Level2Visuals.dialMechanism(s),
                       .init(pendulumSwinging: true, pendulumFullSwing: true, aliveWrongTime: true))
        // Correct time -> strike fires (door-bar latches): ambient stops, swing continues.
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)
        _ = Level2Engine.evaluateTimelock(state: s)
        XCTAssertEqual(Level2Visuals.dialMechanism(s),
                       .init(pendulumSwinging: true, pendulumFullSwing: true, aliveWrongTime: false))
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

    /// m1 (QA spec-fidelity): itm-screwdriver is marked "NEVER consumed" in the graph, so it
    /// must be retained the WHOLE level even after its last pry (p04) — overriding the generic
    /// consume-when-all-uses-done rule. (Was previously consumed after p04.)
    func testScrewdriverNeverConsumedAfterBothCaches() {
        let s = makeState()
        s.addItem(Level2Graph.ItemID.screwdriver)
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        viewGates(s, Level2ClueID.watchA, Level2ClueID.watchB)
        Level2Engine.pryDormerBoard(isCorrectSpot: true, state: s)   // p03
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.screwdriver), "retained after p03")
        Level2Engine.pryChimneyBrick(isCorrectSpot: true, state: s)  // p04 (its LAST use)
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.screwdriver),
                      "NEVER consumed (graph): retained after its final use")
    }

    /// m1 (QA spec-fidelity): itm-oilcan is marked "NEVER consumed" (retained the whole level
    /// "and beyond"), so it must persist even after BOTH uses (p05 arbor + p08 wind) are done.
    func testOilcanNeverConsumedAcrossBothUses() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.addItem(Level2Graph.ItemID.oilcan)
        Level2Engine.oilArbor(state: s)                              // p05
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.oilcan), "retained after p05")
        s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        s.addItem(Level2Graph.ItemID.windingKey)
        Level2Engine.oilDrum(state: s)
        Level2Engine.windDrum(state: s)                             // p08 (its LAST use)
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.oilcan),
                      "NEVER consumed (graph): retained after both uses")
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

    // MARK: - End-to-end example orderings (graph solve_path_notes) — engine level

    /// Drives the WHOLE 11-puzzle solve in graph `example_ordering_A`, asserting each zone
    /// unlock milestone and final completion. Mirrors L1's testSolvePathOrderingA_engineLevel.
    func testExampleOrderingA_completesEndToEnd() {
        let s = makeState()
        // z1 pickups + p01.
        s.addItem(Level2Graph.ItemID.screwdriver)
        s.addItem(Level2Graph.ItemID.watchA); s.addItem(Level2Graph.ItemID.tileIV)
        s.addItem(Level2Graph.ItemID.tileII); s.addItem(Level2Graph.ItemID.tileVII); s.addItem(Level2Graph.ItemID.tileXI)
        viewGates(s, Level2ClueID.masterTime)                                     // master clock close-up
        for (socket, tile) in [("2", Level2Graph.ItemID.tileII), ("4", Level2Graph.ItemID.tileIV),
                               ("7", Level2Graph.ItemID.tileVII), ("11", Level2Graph.ItemID.tileXI)] {
            _ = Level2Engine.seatDialTile(tile, socket: socket, state: s)
        }
        XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z2Workroom), "p01 unlocked z2")
        // mouse (z2) + caches + p02.
        s.addItem(Level2Graph.ItemID.toyMouse)
        viewGates(s, Level2ClueID.watchA)
        XCTAssertEqual(Level2Engine.pryDormerBoard(isCorrectSpot: true, state: s), .yielded)  // p03
        XCTAssertTrue(Level2Engine.collectGreatWheel(s))
        XCTAssertTrue(Level2Engine.placeMouseAtCat(state: s))                                 // p02 -> watch B
        viewGates(s, Level2ClueID.watchB)
        XCTAssertEqual(Level2Engine.pryChimneyBrick(isCorrectSpot: true, state: s), .yielded) // p04
        XCTAssertTrue(Level2Engine.collectOilcan(s))
        // machine stream p05/p06 -> z3.
        XCTAssertTrue(Level2Engine.oilArbor(state: s))                                        // p05
        XCTAssertTrue(Level2Engine.mountGear("36", on: .a, state: s))
        XCTAssertTrue(Level2Engine.mountGear("64", on: .b, state: s))
        XCTAssertTrue(Level2Engine.crankGearTrain(state: s))                                  // p06
        XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial), "p06 unlocked z3")
        // vault p07 -> z4.
        viewGates(s, Level2ClueID.worldClockRow)
        for (i, v) in Level2Graph.vaultSolution.enumerated() { Level2Engine.setVaultWheel(i, value: v, state: s) }
        XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z4Vault), "p07 unlocked z4")
        // z4 pickups + endgame p08/p09/p10 -> latch -> p11.
        s.addItem(Level2Graph.ItemID.windingKey); s.addItem(Level2Graph.ItemID.returnTag)
        XCTAssertTrue(Level2Engine.oilDrum(state: s))
        XCTAssertTrue(Level2Engine.windDrum(state: s))                                        // p08
        viewGates(s, Level2ClueID.returnTag)
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)                             // p09 (7:20)
        XCTAssertTrue(Level2Engine.pushPendulum(state: s))                                    // p10
        XCTAssertTrue(s.hasFlag(Level2Graph.Flag.doorBarRaised), "trio holds -> timelock latched")
        XCTAssertTrue(Level2Engine.openStairDoor(state: s))                                   // p11
        XCTAssertTrue(s.isComplete)
    }

    /// example_ordering_B: pendulum pushed FIRST (weak swing), hands set before winding, the
    /// winding completes the trio. Proves the order-free timelock across the endgame.
    func testExampleOrderingB_pendulumFirst_completesEndToEnd() {
        let s = makeState()
        s.addItem(Level2Graph.ItemID.screwdriver); s.addItem(Level2Graph.ItemID.watchA)
        for id in [Level2Graph.ItemID.tileII, Level2Graph.ItemID.tileIV,
                   Level2Graph.ItemID.tileVII, Level2Graph.ItemID.tileXI] { s.addItem(id) }
        for (socket, tile) in [("2", Level2Graph.ItemID.tileII), ("4", Level2Graph.ItemID.tileIV),
                               ("7", Level2Graph.ItemID.tileVII), ("11", Level2Graph.ItemID.tileXI)] {
            _ = Level2Engine.seatDialTile(tile, socket: socket, state: s)
        }
        viewGates(s, Level2ClueID.watchA)
        XCTAssertEqual(Level2Engine.pryDormerBoard(isCorrectSpot: true, state: s), .yielded)
        XCTAssertTrue(Level2Engine.collectGreatWheel(s))
        s.addItem(Level2Graph.ItemID.toyMouse)
        XCTAssertTrue(Level2Engine.placeMouseAtCat(state: s))
        viewGates(s, Level2ClueID.watchB)
        XCTAssertEqual(Level2Engine.pryChimneyBrick(isCorrectSpot: true, state: s), .yielded)
        XCTAssertTrue(Level2Engine.collectOilcan(s))
        XCTAssertTrue(Level2Engine.oilArbor(state: s))
        XCTAssertTrue(Level2Engine.mountGear("64", on: .a, state: s))
        XCTAssertTrue(Level2Engine.mountGear("36", on: .b, state: s))
        XCTAssertTrue(Level2Engine.crankGearTrain(state: s))
        // p10 FIRST (pendulum, weak swing — unwound).
        XCTAssertTrue(Level2Engine.pushPendulum(state: s))
        XCTAssertFalse(s.hasFlag(Level2Graph.Flag.doorBarRaised), "just the pendulum: not latched")
        viewGates(s, Level2ClueID.masterTime, Level2ClueID.worldClockRow)
        for (i, v) in Level2Graph.vaultSolution.enumerated() { Level2Engine.setVaultWheel(i, value: v, state: s) }
        XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z4Vault))
        s.addItem(Level2Graph.ItemID.windingKey); s.addItem(Level2Graph.ItemID.returnTag)
        viewGates(s, Level2ClueID.returnTag)
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)                 // p09 (hands set before winding)
        XCTAssertFalse(s.hasFlag(Level2Graph.Flag.doorBarRaised), "not wound yet")
        XCTAssertTrue(Level2Engine.oilDrum(state: s))
        XCTAssertTrue(Level2Engine.windDrum(state: s))                            // p08 completes the trio
        XCTAssertTrue(s.hasFlag(Level2Graph.Flag.doorBarRaised), "winding latched the timelock")
        XCTAssertTrue(Level2Engine.openStairDoor(state: s))
        XCTAssertTrue(s.isComplete)
    }

    /// L2 analogue of L1's testRelaunchInsideNestedHiddenZoneMidPuzzle: relaunch while deep
    /// inside the hidden z3/z4 mid-puzzle (wound + pendulum running at a WRONG time, vault
    /// partially dialed) must lose nothing and remain completable after resume.
    func testRelaunchInsideHiddenZoneMidPuzzleLosesNothing() {
        let dir = tempDir()
        do {
            let s = makeState(dir)
            s.unlockZone(Level2Graph.ZoneID.z2Workroom)
            s.unlockZone(Level2Graph.ZoneID.z3BehindDial)
            s.unlockZone(Level2Graph.ZoneID.z4Vault)
            s.addItem(Level2Graph.ItemID.oilcan)
            s.addItem(Level2Graph.ItemID.windingKey)
            s.addItem(Level2Graph.ItemID.returnTag)
            s.setFlag(Level2Graph.Flag.drumOiled)
            s.setFlag(Level2Graph.Flag.clockWound)
            s.setFlag(Level2Graph.Flag.pendulumRunning)
            s.setL2ClockFrontMinutes(Level2Graph.clockNaiveTrapMinutes)   // wrong time (alive-wrong D11)
            s.setL2VaultWheel(0, value: 6)
            s.markClueViewed(Level2ClueID.returnTag)
        }
        let r = makeState(dir)   // relaunch
        XCTAssertTrue(r.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial))
        XCTAssertTrue(r.isZoneUnlocked(Level2Graph.ZoneID.z4Vault))
        XCTAssertTrue(r.hasFlag(Level2Graph.Flag.clockWound))
        XCTAssertTrue(r.hasFlag(Level2Graph.Flag.pendulumRunning))
        XCTAssertEqual(r.data.l2ClockFrontMinutes, Level2Graph.clockNaiveTrapMinutes)
        XCTAssertEqual(r.data.l2VaultWheels[0], 6)
        XCTAssertTrue(r.hasViewedClue(Level2ClueID.returnTag))
        XCTAssertTrue(Level2Visuals.dialMechanism(r).aliveWrongTime, "D11 state survives relaunch")
        // Still completable: correcting the hands from the resumed state latches + wins.
        r.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)
        XCTAssertTrue(r.hasFlag(Level2Graph.Flag.doorBarRaised))
        XCTAssertTrue(Level2Engine.openStairDoor(state: r))
        XCTAssertTrue(r.isComplete)
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
