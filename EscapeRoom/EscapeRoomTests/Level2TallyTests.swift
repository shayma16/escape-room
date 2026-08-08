import XCTest
import UIKit
@testable import EscapeRoom

/// REV 1.4.1 / D13 — GUARDS FOR THE LIVE CRANK-TALLY READOUT.
///
/// D13 is the safety net for p06: it delivers the no-algebra counting route that D5 and blind
/// playtest 2b have promised since rev 1.0 and that build 16 never shipped (one press ran a
/// whole cam cycle and left nothing on screen to count). Because it is the route a stuck player
/// falls back on, its FORM contracts are as load-bearing as its arithmetic, and every one of
/// them is machine-checkable here — deterministic, no simulator UI, fast lane:
///
///  * ARITHMETIC   — R = A*B/96 crank revolutions per cam cycle; the solution pair reads 24 with
///                   NO partial, in either post order (the QA commutativity flag);
///  * ANTI-OSCILLATION — the same mounted pair renders a byte-identical block on every cycle
///                   (the whole reason accrual is accumulated ROTATION, not index crossings);
///  * PARTIAL FORM — exactly the three non-integer pairs draw N full + ONE partial; the partial
///                   is upright, constant-height, never struck, never grouped into a five, and
///                   its geometry is independent of the residue (V17-W1/W3);
///  * NO LEAK      — nothing in the drawn picture varies with closeness to 24, and there is no
///                   special case at 24 at all (RF-7c: no glow/flash/colour change);
///  * SEPARATION   — the live block sits BELOW the crib's chalked rule and inside its authored
///                   rect (RF-7b: position-only separation, never one continuous block);
///  * PERSISTENCE  — transient view state: cleared on mount/unmount, on fewer than two gears,
///                   on scene/save reload, and redrawn from zero by the next press. It is never
///                   written to the save and never readable by a gate.
final class Level2TallyTests: XCTestCase {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private func makeState(store: SaveGameStore? = nil) -> GameState {
        GameState(levelID: 2, store: store ?? SaveGameStore(directory: tempDir()))
    }
    /// A state with the frame ready to crank: z2 open, arbor freed, both posts loaded.
    private func crankable(_ a: String, _ b: String) -> GameState {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.setFlag(Level2Graph.Flag.arborFreed)
        s.setL2GearPost(.a, gear: a)
        s.setL2GearPost(.b, gear: b)
        return s
    }

    /// Every pair the level can physically mount: the six rack gears + the found great wheel,
    /// two distinct posts, one of each gear in existence (so no A==B pair).
    private static var allPairs: [(String, String)] {
        let gears = Level2Graph.rackGears + [Level2Graph.gearGreatWheelValue]
        var out: [(String, String)] = []
        for (i, a) in gears.enumerated() {
            for b in gears.dropFirst(i + 1) { out.append((a, b)) }
        }
        return out
    }

    // MARK: - Notation

    /// The notation must come from the STAGED metadata the sprites were cut against, not from
    /// hand-transcribed Swift constants (the build-16 rect-drift class).
    func testNotationIsLoadedFromTheAuthoredMetadata() {
        let n = Level2Tally.notation
        XCTAssertEqual(n.slotPitch, 14, accuracy: 0.001)
        XCTAssertEqual(n.groupGap, 16, accuracy: 0.001)
        XCTAssertEqual(n.rowPitch, 56, accuracy: 0.001)
        XCTAssertEqual(n.rowCapacity, 20, "4 five-groups per row")
        XCTAssertEqual(n.rowBaselines.count, 3, "3 rows -> 60 slots >= the worst case of 48")
        XCTAssertEqual(n.rowBaselines, [664, 720, 776])
        XCTAssertEqual(n.x0, 702, accuracy: 0.001)
        XCTAssertEqual(n.ruleY, 604, accuracy: 0.001)
        XCTAssertEqual(n.strokeSize.width, 4, accuracy: 0.001)
        XCTAssertEqual(n.strokeSize.height, 38, accuracy: 0.001)
        XCTAssertEqual(n.strikeSize.width, 47.6, accuracy: 0.01)
        XCTAssertGreaterThanOrEqual(n.capacity, 48)
        // Row baselines step by the authored row pitch.
        for i in 1..<n.rowBaselines.count {
            XCTAssertEqual(n.rowBaselines[i] - n.rowBaselines[i - 1], n.rowPitch, accuracy: 0.001)
        }
    }

    /// All three sprites ship, and each is pixel-proportional to its authored draw box, so the
    /// runtime never rescales a stroke into a different weight (RF-7b: identical stroke weight
    /// to the crib is the whole reason the two blocks read as one hand's chalk).
    func testTallySpritesShipAndAreProportionalToTheirDrawBoxes() {
        let n = Level2Tally.notation
        for kind in [Level2Tally.Mark.Kind.full, .partial, .strike] {
            guard let art = GameAssetLoader.shared.image(named: kind.image) else {
                XCTFail("tally sprite '\(kind.image)' is not staged"); continue
            }
            let px = CGSize(width: art.size.width * art.scale, height: art.size.height * art.scale)
            let box = kind == .strike ? n.strikeSize : n.strokeSize
            XCTAssertEqual(px.width / px.height, box.width / box.height, accuracy: 0.02,
                           "\(kind.image): sprite aspect must match its draw box, or the stroke "
                           + "is drawn at a different weight than the crib's")
        }
    }

    // MARK: - Arithmetic (D5 train: (A/12) x (B/8) -> R = A*B/96)

    /// THE QA COMMUTATIVITY FLAG: 36/64 in EITHER post order both COMPUTE 24:1 and are both
    /// ACCEPTED. (Acceptance was already covered by testGearTrainBothArrangementsSolve; this
    /// pins the computed ratio the player now sees on the cheek as well.)
    func testSolutionPairComputes24AndIsAcceptedInEitherPostOrder() {
        for (a, b) in [("36", "64"), ("64", "36")] {
            XCTAssertEqual(Level2Tally.revolutionsPerCamCycle(postA: a, postB: b), 24.0,
                           "\(a)/\(b) must compute exactly 24 crank turns per cam cycle")
            let block = Level2Tally.finalBlock(postA: a, postB: b)
            XCTAssertEqual(block, Level2Tally.Block(fullStrokes: 24, hasPartial: false),
                           "\(a)/\(b): the solution draws 24 full strokes and NO partial")

            let s = crankable(a, b)
            XCTAssertTrue(Level2Engine.isGearTrainCorrect(s), "\(a)/\(b) must be the 24:1 pair")
            XCTAssertTrue(Level2Engine.crankGearTrain(state: s), "\(a)/\(b) must be accepted")
            XCTAssertTrue(s.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial))
        }
        // …and the two orders are literally the same picture.
        XCTAssertEqual(Level2Tally.marks(for: Level2Tally.finalBlock(postA: "36", postB: "64")!),
                       Level2Tally.marks(for: Level2Tally.finalBlock(postA: "64", postB: "36")!))
    }

    /// Exactly three of the 21 mountable pairs are non-integer, and they are the three D13
    /// enumerates. Everything else is N full strokes with no partial.
    func testExactlyTheThreeNonIntegerPairsDrawAPartial() {
        let expectedPartials: Set<Set<String>> = [["16", "40"], ["16", "64"], ["40", "64"]]
        var partials: Set<Set<String>> = []
        var failures: [String] = []
        for (a, b) in Self.allPairs {
            guard let block = Level2Tally.finalBlock(postA: a, postB: b),
                  let r = Level2Tally.revolutionsPerCamCycle(postA: a, postB: b) else {
                failures.append("\(a)/\(b): no block"); continue
            }
            if block.hasPartial { partials.insert([a, b]) }
            // The exact-integer path and the accrued-rotation path must agree exactly, or the
            // end of a cycle would draw something different from the cycle that produced it.
            XCTAssertEqual(Level2Tally.block(accumulatedRevolutions: r), block,
                           "\(a)/\(b): completed accrual != the cycle's own block")
            XCTAssertEqual(block.fullStrokes, Int(floor(r)), "\(a)/\(b) full strokes")
            let marks = Level2Tally.marks(for: block)
            XCTAssertEqual(marks.filter({ $0.kind == .partial }).count, block.hasPartial ? 1 : 0,
                           "\(a)/\(b): at most ONE partial per block")
        }
        XCTAssertEqual(partials, expectedPartials,
                       "the non-integer pairs must be exactly 16x40 (6 2/3), 16x64 (10 2/3) and "
                       + "40x64 (26 2/3) — got \(partials.map { $0.sorted() })")
        XCTAssertEqual(Level2Tally.finalBlock(postA: "16", postB: "40"),
                       Level2Tally.Block(fullStrokes: 6, hasPartial: true))
        XCTAssertEqual(Level2Tally.finalBlock(postA: "16", postB: "64"),
                       Level2Tally.Block(fullStrokes: 10, hasPartial: true))
        XCTAssertEqual(Level2Tally.finalBlock(postA: "40", postB: "64"),
                       Level2Tally.Block(fullStrokes: 26, hasPartial: true))
        XCTAssertTrue(failures.isEmpty, failures.joined(separator: "\n"))
    }

    /// D13's worst case is 48 strokes (64x72 = 4608/96), NOT 54 — that would need two 72s and
    /// only one exists. It must fit the authored three rows and stay legible via the grouping.
    func testWorstCaseIs48StrokesAndFitsTheAuthoredRows() {
        let worst = Self.allPairs.compactMap { Level2Tally.finalBlock(postA: $0.0, postB: $0.1) }
            .map(\.fullStrokes).max()
        XCTAssertEqual(worst, 48)
        XCTAssertEqual(Level2Tally.finalBlock(postA: "64", postB: "72"),
                       Level2Tally.Block(fullStrokes: 48, hasPartial: false))
        let n = Level2Tally.notation
        let marks = Level2Tally.marks(for: Level2Tally.Block(fullStrokes: 48, hasPartial: false))
        XCTAssertEqual(marks.count, 48, "no mark may be dropped at the worst case")
        XCTAssertEqual(Set(marks.map(\.row)), [0, 1, 2], "48 strokes occupy exactly 3 rows")
        XCTAssertEqual(marks.filter({ $0.kind == .strike }).count, 48 / 5,
                       "every completed five is closed by exactly one diagonal")
        XCTAssertEqual(marks.filter({ $0.kind == .full }).count, 48 - 48 / 5)
        // Row occupancy respects the authored capacity.
        for row in 0..<n.rowBaselines.count {
            XCTAssertLessThanOrEqual(marks.filter({ $0.row == row }).count, n.rowCapacity)
        }
    }

    // MARK: - Form: grouping, the partial, and the position-only separation

    /// Grouping is "four uprights + one diagonal closing stroke", and the diagonal spans exactly
    /// the four it closes — it starts on the group's first upright and never overshoots the
    /// fourth (a strike that overshot would read as a strike-OUT, not a fifth stroke).
    func testFivesAreClosedByADiagonalThatSpansExactlyItsFourUprights() {
        let n = Level2Tally.notation
        let marks = Level2Tally.marks(for: Level2Tally.Block(fullStrokes: 20, hasPartial: false))
        XCTAssertEqual(marks.filter({ $0.kind == .strike }).count, 4)
        for strike in marks.filter({ $0.kind == .strike }) {
            let uprights = marks.filter({ $0.kind == .full && $0.row == strike.row
                                          && $0.group == strike.group })
            XCTAssertEqual(uprights.count, 4, "a diagonal closes exactly four uprights")
            XCTAssertEqual(strike.x, uprights.map(\.x).min()!, accuracy: 0.001,
                           "the diagonal starts at the group's FIRST upright")
            let lastUprightRight = uprights.map(\.x).max()! + n.strokeSize.width
            let strikeRight = strike.x + n.strikeSize.width
            XCTAssertGreaterThanOrEqual(strikeRight, lastUprightRight - 0.5,
                                        "the diagonal must reach the fourth upright")
            XCTAssertLessThan(strikeRight, lastUprightRight + n.groupGap,
                              "the diagonal must not overshoot into the next group")
            XCTAssertEqual(strike.baselineY, uprights[0].baselineY,
                           "the group shares one baseline")
        }
    }

    /// V17-W1/W3, the partial's whole contract, for each of the three non-integer pairs:
    /// UPRIGHT (never the diagonal sprite), CONSTANT height (identical draw box to a full
    /// stroke, so the height cannot become a signal channel), on the SHARED baseline, occupying
    /// a FULL slot pitch, never grouped into a five and never struck.
    func testPartialIsUprightConstantHeightAndNeverGroupedOrStruck() {
        let n = Level2Tally.notation
        for (a, b) in [("16", "40"), ("16", "64"), ("40", "64")] {
            guard let block = Level2Tally.finalBlock(postA: a, postB: b) else {
                XCTFail("\(a)/\(b): no block"); continue
            }
            let marks = Level2Tally.marks(for: block)
            guard let partial = marks.first(where: { $0.kind == .partial }) else {
                XCTFail("\(a)/\(b): the non-integer remainder must draw ONE partial"); continue
            }
            XCTAssertEqual(marks.filter({ $0.kind == .partial }).count, 1)
            // Constant height: the same draw box as a full stroke. The shortened TOP lives in
            // the sprite (sp-tally-partial), never in a runtime height.
            XCTAssertEqual(Level2Tally.drawRect(partial, notation: n).size, n.strokeSize,
                           "\(a)/\(b): the partial must be drawn in the SAME box as a full stroke")
            XCTAssertTrue(n.rowBaselines.contains(partial.baselineY),
                          "\(a)/\(b): the partial must sit on an authored row baseline, shared "
                          + "with the full strokes (V17-W3: shortened at the TOP only)")
            XCTAssertNotEqual(partial.slot, 4, "\(a)/\(b): the partial can never be the diagonal")
            // Never grouped into a five: its group cannot also carry a closing diagonal.
            XCTAssertFalse(marks.contains(where: { $0.kind == .strike && $0.row == partial.row
                                                   && $0.group == partial.group }),
                           "\(a)/\(b): the partial's group must be incomplete (never struck)")
            // Occupies a FULL slot pitch: inside a group it is exactly one pitch from the
            // upright on its left; when it opens a new group it is a full group gap away.
            if let left = marks.filter({ $0.kind == .full && $0.row == partial.row
                                         && $0.x < partial.x }).map(\.x).max() {
                let expected = partial.slot > 0
                    ? n.slotPitch
                    : n.strokeSize.width + n.groupGap
                XCTAssertEqual(partial.x - left, expected, accuracy: 0.001,
                               "\(a)/\(b): the partial must occupy a full slot, never crowd one")
            }
        }
    }

    /// V17-W1 stated as an anti-leak property: the partial's geometry is IDENTICAL for a residue
    /// of 2/3 whether it sits at 6 strokes (far from 24) or 26 (near). Non-integrality is
    /// mechanical truth, never a proximity signal.
    func testFarAndNearNonIntegerPairsRenderTheSamePartialForm() {
        let far = Level2Tally.marks(for: Level2Tally.finalBlock(postA: "16", postB: "40")!)
            .first(where: { $0.kind == .partial })
        let near = Level2Tally.marks(for: Level2Tally.finalBlock(postA: "40", postB: "64")!)
            .first(where: { $0.kind == .partial })
        XCTAssertNotNil(far); XCTAssertNotNil(near)
        XCTAssertEqual(Level2Tally.drawRect(far!).size, Level2Tally.drawRect(near!).size)
        XCTAssertEqual(far!.kind, near!.kind)
        XCTAssertEqual(far!.slot, near!.slot, "6 2/3 and 26 2/3 leave the same slot standing")
    }

    /// RF-7(c): there is NO special case at 24. The block at 24 is the block at 23 plus one
    /// stroke and a prefix of the block at 25 — the same kinds, the same geometry — so success
    /// differentiation stays entirely with the latch taking and the panel opening.
    func testNothingSpecialHappensAtTwentyFour() {
        let at23 = Level2Tally.marks(for: Level2Tally.Block(fullStrokes: 23, hasPartial: false))
        let at24 = Level2Tally.marks(for: Level2Tally.Block(fullStrokes: 24, hasPartial: false))
        let at25 = Level2Tally.marks(for: Level2Tally.Block(fullStrokes: 25, hasPartial: false))
        XCTAssertEqual(Array(at24.dropLast()), at23, "24 is 23 plus one mark, nothing more")
        XCTAssertEqual(Array(at25.prefix(at24.count)), at24, "24 is a prefix of 25")
        XCTAssertTrue(at24.allSatisfy({ $0.kind == .full || $0.kind == .strike }))
        // A correct pair and a wrong pair with the same count are the identical picture.
        XCTAssertEqual(Level2Tally.marks(for: Level2Tally.Block(fullStrokes: 24, hasPartial: false)),
                       at24)
    }

    /// RF-7(b): POSITION-ONLY separation. Every live mark sits below the crib's chalked rule and
    /// inside the authored live-block rect, so the live block can never touch, continue or read
    /// as one block with the crib's 24.
    func testLiveBlockSitsBelowTheCribRuleAndInsideItsAuthoredRect() {
        let n = Level2Tally.notation
        let rect = CGRect(x: n.blockRect.minX * n.plate.width, y: n.blockRect.minY * n.plate.height,
                          width: n.blockRect.width * n.plate.width,
                          height: n.blockRect.height * n.plate.height)
        XCTAssertGreaterThan(n.rowBaselines[0] - n.strokeSize.height, n.ruleY,
                             "the first live row must start BELOW the crib's rule")
        XCTAssertGreaterThanOrEqual(n.rowBaselines[0] - n.ruleY, 55,
                                    "the authored clearance under the rule is 60 CU px")
        var offenders: [String] = []
        // Worst case + a partial-bearing block: every mark inside the authored rect.
        for block in [Level2Tally.Block(fullStrokes: 48, hasPartial: false),
                      Level2Tally.Block(fullStrokes: 26, hasPartial: true),
                      Level2Tally.Block(fullStrokes: 6, hasPartial: true)] {
            for mark in Level2Tally.marks(for: block) {
                let r = Level2Tally.drawRect(mark, notation: n)
                if !rect.insetBy(dx: -0.6, dy: -0.6).contains(r) {
                    offenders.append("\(block.fullStrokes)\(block.hasPartial ? "+p" : ""): "
                                     + "\(mark.kind.rawValue) at \(r) leaves \(rect)")
                }
                if r.maxY > n.plate.height || r.minX < 0 {
                    offenders.append("\(mark.kind.rawValue) off the plate")
                }
            }
        }
        XCTAssertTrue(offenders.isEmpty, "live tally block geometry:\n" + offenders.joined(separator: "\n"))
    }

    // MARK: - Accrual: the anti-oscillation contract

    /// THE D13 ANTI-OSCILLATION CONTRACT (QA flag b): the same mounted pair renders a
    /// state-identical block on EVERY cam cycle. Accrual is accumulated ROTATION, so nothing can
    /// drift in phase; counting index-mark crossings would produce the prohibited 7/7/6 wobble.
    func testTallyIsCycleStableAcrossManyCyclesForEveryPair() {
        var failures: [String] = []
        for (a, b) in Self.allPairs {
            let accrual = L2TallyAccrual()
            var pictures: [[Level2Tally.Mark]] = []
            var blocks: [Level2Tally.Block] = []
            for _ in 0..<6 {
                XCTAssertTrue(accrual.begin(postA: a, postB: b))
                XCTAssertEqual(accrual.block, Level2Tally.Block.empty,
                               "\(a)/\(b): a press must redraw from ZERO")
                // Accrue in irregular steps — phase must not matter.
                var step = 0.037
                while accrual.isAccruing {
                    accrual.advance(by: step)
                    step = step * 1.7 > 0.9 ? 0.041 : step * 1.7
                }
                accrual.finish()
                guard let block = accrual.block else { failures.append("\(a)/\(b): nil block"); break }
                blocks.append(block)
                pictures.append(Level2Tally.marks(for: block))
            }
            if Set(blocks.map { "\($0.fullStrokes)|\($0.hasPartial)" }).count > 1 {
                failures.append("\(a)/\(b): OSCILLATED across cycles -> \(blocks)")
            }
            if let first = pictures.first, pictures.contains(where: { $0 != first }) {
                failures.append("\(a)/\(b): the drawn picture changed between identical cycles")
            }
            if blocks.first != Level2Tally.finalBlock(postA: a, postB: b) {
                failures.append("\(a)/\(b): accrued block \(String(describing: blocks.first)) != "
                                + "\(String(describing: Level2Tally.finalBlock(postA: a, postB: b)))")
            }
        }
        XCTAssertTrue(failures.isEmpty, "D13 cycle stability:\n" + failures.joined(separator: "\n"))
    }

    /// The accrual only ever grows toward the cycle, never past it, and `finish()` (the RC-4
    /// skip) lands on exactly the same picture as watching it fill.
    func testAccrualIsMonotonicAndSkippingLandsOnTheFinalBlock() {
        let watched = L2TallyAccrual()
        watched.begin(postA: "40", postB: "64")
        var last = 0
        while watched.isAccruing {
            watched.advance(by: 0.25)
            let block = watched.block!
            XCTAssertGreaterThanOrEqual(block.fullStrokes, last, "the count must never go DOWN")
            last = block.fullStrokes
        }
        XCTAssertEqual(watched.revolutions, 26 + 2.0 / 3.0, accuracy: 1e-9)

        let skipped = L2TallyAccrual()
        skipped.begin(postA: "40", postB: "64")
        skipped.finish()
        XCTAssertEqual(skipped.block, watched.block,
                       "RC-4: the skipped block must be the watched block")
        XCTAssertEqual(skipped.block, Level2Tally.Block(fullStrokes: 26, hasPartial: true))
    }

    // MARK: - Persistence: transient view state, never saved, never gate-readable

    /// D13's four clearing conditions, through the coordinator that actually owns the state.
    func testTallyClearsOnMountUnmountAndOnFewerThanTwoGears() {
        let s = crankable("40", "48")
        let coord = Level2Coordinator(viewID: .frame, state: s,
                                      size: CGSize(width: 2732, height: 1366))
        XCTAssertNil(coord.tallyBlock, "nothing is drawn before the crank is pressed")

        coord.crankGearTrain()                 // wrong pair: cam runs, latch slips, block draws
        coord.finishTallyAccrual()             // skip the animation
        XCTAssertEqual(coord.tallyBlock, Level2Tally.Block(fullStrokes: 20, hasPartial: false),
                       "40x48 = 1920/96 = 20 crank turns per cam cycle")
        XCTAssertFalse(s.hasSolved(Level2Graph.PuzzleID.gearTrain), "20 != 24: nothing unlocks")

        // (i) a mount clears immediately and completely.
        coord.mountGear("36", on: .a)
        XCTAssertNil(coord.tallyBlock,
                     "D13(i): the frame must never show a count for a configuration that is no "
                     + "longer mounted")

        // (iv) the next press redraws from zero, for the NEW pair.
        coord.crankGearTrain(); coord.finishTallyAccrual()
        XCTAssertEqual(coord.tallyBlock, Level2Tally.Block(fullStrokes: 36 * 48 / 96, hasPartial: false))

        // (i) an unmount clears too; (ii) with fewer than two gears nothing is drawn even if
        // the crank is pressed.
        coord.unmountGear(.b)
        XCTAssertNil(coord.tallyBlock)
        coord.crankGearTrain()
        XCTAssertNil(coord.tallyBlock, "D13(ii): no pair, nothing drawn")
    }

    /// A seized arbor turns nothing, so there is no rotation to accrue and no block — the tally
    /// can never suggest the crank did something it did not.
    func testNoTallyWhileTheArborIsSeized() {
        let s = makeState()
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.setL2GearPost(.a, gear: "36")
        s.setL2GearPost(.b, gear: "64")
        XCTAssertFalse(Level2Engine.canCrank(s))
        let coord = Level2Coordinator(viewID: .frame, state: s,
                                      size: CGSize(width: 2732, height: 1366))
        coord.crankGearTrain()
        XCTAssertNil(coord.tallyBlock)
        XCTAssertFalse(s.hasSolved(Level2Graph.PuzzleID.gearTrain))
    }

    /// D13(iii) + the persistence contract: the block is NEVER saved and re-derives EMPTY on
    /// load. Cranked, then saved and reloaded into a fresh session — the cheek is blank, and no
    /// gate, flag or clue changed because a tally was drawn.
    func testTallyIsNeverSavedAndReDerivesEmptyOnLoad() {
        let store = SaveGameStore(directory: tempDir())
        let s = makeState(store: store)
        s.unlockZone(Level2Graph.ZoneID.z2Workroom)
        s.setFlag(Level2Graph.Flag.arborFreed)
        s.setL2GearPost(.a, gear: "16")
        s.setL2GearPost(.b, gear: "64")
        let coord = Level2Coordinator(viewID: .frame, state: s,
                                      size: CGSize(width: 2732, height: 1366))
        coord.crankGearTrain(); coord.finishTallyAccrual()
        XCTAssertEqual(coord.tallyBlock, Level2Tally.Block(fullStrokes: 10, hasPartial: true))
        let cluesAfter = s.data.viewedClues
        let flagsAfter = s.data.flags

        // Reload the SAME save into a new session + a new scene (D13(iii)).
        let reloaded = GameState(levelID: 2, store: store)
        XCTAssertEqual(reloaded.data.l2GearPostA, "16", "the MOUNTED pair is saved…")
        XCTAssertEqual(reloaded.data.l2GearPostB, "64")
        XCTAssertEqual(reloaded.data.viewedClues, cluesAfter, "…but the tally changed no clue")
        XCTAssertEqual(reloaded.data.flags, flagsAfter, "…and no flag")
        let fresh = Level2Coordinator(viewID: .frame, state: reloaded,
                                     size: CGSize(width: 2732, height: 1366))
        XCTAssertNil(fresh.tallyBlock,
                     "the block is transient view state: it must re-derive EMPTY on load")
    }

    /// The tally is UNGATED, exactly as p06 is, and never varies with any clue-viewed flag —
    /// the block for a pair is the same picture with no clues read and with all of them read.
    func testTallyNeverVariesWithAnyClueFlag() {
        let bare = crankable("36", "48")
        let coordA = Level2Coordinator(viewID: .frame, state: bare,
                                       size: CGSize(width: 2732, height: 1366))
        coordA.crankGearTrain(); coordA.finishTallyAccrual()

        let clued = crankable("36", "48")
        for clue in [Level2ClueID.slateRatio, Level2ClueID.watchA, Level2ClueID.watchB,
                     Level2ClueID.ringDormer, Level2ClueID.ringChimney, Level2ClueID.masterTime,
                     Level2ClueID.worldClockRow, Level2ClueID.mirroredNumerals,
                     Level2ClueID.returnTag] {
            clued.markClueViewed(clue)
        }
        let coordB = Level2Coordinator(viewID: .frame, state: clued,
                                       size: CGSize(width: 2732, height: 1366))
        coordB.crankGearTrain(); coordB.finishTallyAccrual()

        XCTAssertEqual(coordA.tallyBlock, coordB.tallyBlock)
        XCTAssertEqual(Level2Tally.marks(for: coordA.tallyBlock!),
                       Level2Tally.marks(for: coordB.tallyBlock!))
    }
}
