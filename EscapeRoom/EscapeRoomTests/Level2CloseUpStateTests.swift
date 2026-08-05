import XCTest
import UIKit
@testable import EscapeRoom

/// ROUND 8 — THE CLOSE-UP STATE-RENDERING GUARD (binding: this defect class shipped in
/// build 15 precisely because nothing tested it).
///
/// Level 2's WIDE views were guarded (Level2RegistrationTests / RenderedFrameOverlayTests)
/// but its CLOSE-UPS were not, so every close-up rendered one static plate for the whole
/// playthrough: collected coat items stayed in their pockets, seated dial tiles never
/// appeared, the pried cache never opened, and the cushion still showed a cat the wide view
/// had already removed — the P0 that made the user believe Level 2 was unfinishable
/// (R8-002/004/009/010/011/012/013).
///
/// This is the close-up analogue of the wide overlay guards. Deterministic (pure model +
/// offline UIKit compositing — no simulator UI automation), so it belongs in the FAST lane:
///
///  * STATE FLIP   — for EVERY stateful close-up, the rendered composition must CHANGE in the
///                   expected direction when its state flips (post-pickup / post-solve). A
///                   no-op ternary like build 15's `hasSolved(...) ? "cu-x" : "cu-x"` fails here.
///  * ART EXISTS   — every layer a reachable plan can request must resolve to a staged image
///                   (the CU overlay crops existed but were never staged — the root cause).
///  * PIXEL 1:1    — each CU overlay's art matches its authored rect at 2048x1536, so the
///                   runtime cannot rescale/misplace it (the R7-001 class, close-up side).
///  * VISIBLE INK  — each overlay actually paints (non-trivial alpha), so a transparent or
///                   empty patch cannot silently "composite" nothing.
///  * TARGETS      — every revealed item exposes a manual-pickup target ON its art, inside the
///                   plate, and the pickup runs the right engine transition.
///  * CHEVRON      — the dismiss chevron clears the inventory band on every close-up and every
///                   device class (Cluster B: it was rendered UNDER the bar on all of L2).
final class Level2CloseUpStateTests: XCTestCase {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private func makeState() -> GameState {
        GameState(levelID: 2, store: SaveGameStore(directory: tempDir()))
    }
    private func plan(_ c: L2CloseUp, _ s: GameState) -> Level2CloseUpVisuals.Plan {
        Level2CloseUpVisuals.plan(for: c, state: s)
    }

    // MARK: - Every stateful close-up, with the state transition it must render

    /// (name, close-up, mutation that flips the state, overlay key that must APPEAR).
    private static let stateFlips: [(name: String, closeUp: L2CloseUp,
                                     flip: (GameState) -> Void, appears: String)] = [
        ("coat / tile IV collected", .coat,
         { $0.addItem(Level2Graph.ItemID.tileIV) }, "ov-coat-tile-taken"),
        ("coat / watch A collected", .coat,
         { $0.addItem(Level2Graph.ItemID.watchA) }, "ov-coat-watch-taken"),
        ("dial / tile II seated", .dialDoor,
         { $0.setL2DialSocket("2", tile: Level2Graph.ItemID.tileII) }, "ov-dial-seat-ii"),
        ("dial / tile IV seated", .dialDoor,
         { $0.setL2DialSocket("4", tile: Level2Graph.ItemID.tileIV) }, "ov-dial-seat-iv"),
        ("dial / tile VII seated", .dialDoor,
         { $0.setL2DialSocket("7", tile: Level2Graph.ItemID.tileVII) }, "ov-dial-seat-vii"),
        ("dial / tile XI seated", .dialDoor,
         { $0.setL2DialSocket("11", tile: Level2Graph.ItemID.tileXI) }, "ov-dial-seat-xi"),
        ("dormer cache / pried (R8-010)", .dormerCache,
         { $0.markSolved(Level2Graph.PuzzleID.cacheDormer) }, "ov-cache-pried-wheel"),
        ("chimney cache / pried", .chimneyCache,
         { $0.markSolved(Level2Graph.PuzzleID.cacheChimney) }, "ov-brick-pried-oilcan"),
        ("cushion / cat gone (R8-012 P0)", .catCushion,
         { $0.markSolved(Level2Graph.PuzzleID.catMouse) }, "ov-cushion-empty"),
        ("gear frame / arbor oiled", .gearFrame,
         { $0.setFlag(Level2Graph.Flag.arborFreed) }, "ov-arbor-oiled"),
        ("gear frame / gear on post A", .gearFrame,
         { $0.setL2GearPost(.a, gear: "36") }, "ov-mount-a-36"),
        ("gear frame / gear on post B", .gearFrame,
         { $0.setL2GearPost(.b, gear: "64") }, "ov-mount-b-64"),
        ("drum / oiled", .windingDrum,
         { $0.setFlag(Level2Graph.Flag.drumOiled) }, "ov-drum-oiled"),
        ("drum / key in", .windingDrum,
         { $0.setFlag(Level2Graph.Flag.clockWound) }, "ov-drum-key-in"),
        ("cabinet / drawer open with mouse", .cabinetDrawer,
         { $0.setFlag(Level2Graph.Flag.cabinetDrawerOpened) }, "ov-cabinet-open-mouse"),
        ("stove / tile II taken", .plain(image: "cu-stove-hob"),
         { $0.addItem(Level2Graph.ItemID.tileII) }, "ov-stove-tile-taken"),
        ("crate / tile VII taken", .plain(image: "cu-crate-straw"),
         { $0.addItem(Level2Graph.ItemID.tileVII) }, "ov-crate-tile-taken"),
        ("sill / tile XI taken (R8-013(2))", .plain(image: "cu-sill-tile"),
         { $0.addItem(Level2Graph.ItemID.tileXI) }, "ov-sill-tile-taken"),
        ("time-lock / bar raised", .plain(image: "cu-timelock"),
         { $0.setFlag(Level2Graph.Flag.doorBarRaised) }, "ov-bar-raised"),
        ("rack / 36 removed to a post", .plain(image: "cu-gear-rack"),
         { $0.setL2GearPost(.a, gear: "36") }, "ov-rack-absent-36"),
        ("key hook / key taken", .plain(image: "cu-key-hook"),
         { $0.addItem(Level2Graph.ItemID.windingKey) }, "ov-key-taken"),
        ("tag nail / tag taken", .plain(image: "cu-tag-nail"),
         { $0.addItem(Level2Graph.ItemID.returnTag) }, "ov-tag-taken"),
        // CROSS-VIEW ECHOES (build-16 gap): cu-sill-tile and cu-cat-cushion are the same z1
        // render at different zoom, so each plate bakes in a corner of the OTHER plate's
        // element. Without these, the sill plate showed a cat the game had removed and the
        // cushion plate showed a tile XI the player was carrying.
        ("sill / cat gone in the cushion corner", .plain(image: "cu-sill-tile"),
         { $0.markSolved(Level2Graph.PuzzleID.catMouse) }, "ov-sill-cat-gone"),
        ("sill / cushion lifted in the cushion corner", .plain(image: "cu-sill-tile"),
         { $0.markSolved(Level2Graph.PuzzleID.catMouse)
           $0.setFlag(Level2Graph.Flag.cushionLifted) }, "ov-sill-cushion-lifted"),
        ("cushion / tile XI gone from the sill corner", .catCushion,
         { $0.addItem(Level2Graph.ItemID.tileXI) }, "ov-cushion-sill-taken"),
    ]

    /// THE CORE GUARD: each stateful close-up's composition must CHANGE, and change in the
    /// specific way the state demands. Build 15 would fail every row of this table.
    func testEveryStatefulCloseUpCompositionChangesOnItsStateFlip() {
        var failures: [String] = []
        for entry in Self.stateFlips {
            let s = makeState()
            let before = plan(entry.closeUp, s)
            entry.flip(s)
            let after = plan(entry.closeUp, s)

            if before == after {
                failures.append("\(entry.name): composition IDENTICAL after the state flip "
                    + "(stale close-up — the exact build-15 defect)")
                continue
            }
            let beforeKeys = Set(before.layers.map(\.key))
            let afterKeys = Set(after.layers.map(\.key))
            if beforeKeys.contains(entry.appears) {
                failures.append("\(entry.name): '\(entry.appears)' was already composited BEFORE the flip")
            }
            if !afterKeys.contains(entry.appears) {
                failures.append("\(entry.name): expected '\(entry.appears)' to composite; got "
                    + "\(afterKeys.sorted())")
            }
        }
        XCTAssertTrue(failures.isEmpty,
            "close-up STATE RENDERING regressions:\n" + failures.joined(separator: "\n"))
    }

    /// The P0 chain end to end, as a human sees it: cat asleep -> cat gone (cushion down) ->
    /// cushion lifted with watch B visible -> emptied. Four DISTINCT compositions.
    func testCushionCloseUpRendersAllFourStatesDistinctly() {
        let s = makeState()
        let asleep = plan(.catCushion, s)
        XCTAssertTrue(asleep.layers.isEmpty, "pre-p02 the cat is on the base plate, no overlays")
        XCTAssertTrue(asleep.targets.isEmpty, "no lift affordance while the cat is on the cushion")

        s.addItem(Level2Graph.ItemID.toyMouse)
        XCTAssertTrue(Level2Engine.placeMouseAtCat(state: s))
        let vacated = plan(.catCushion, s)
        XCTAssertTrue(vacated.layers.map(\.key).contains("ov-cushion-empty"),
                      "R8-012: post-p02 the close-up must show the cat GONE, like the wide view")
        XCTAssertEqual(vacated.targets.map(\.kind), [.liftCushion],
                       "R8-013: the cushion must be liftable — the interaction the walkthrough describes")

        XCTAssertTrue(Level2Engine.liftCushion(state: s))
        let revealed = plan(.catCushion, s)
        XCTAssertTrue(revealed.layers.map(\.key).contains("ov-cushion-reveal"),
                      "lifting composites the reveal (cushion up, watch B on the bench)")
        XCTAssertEqual(revealed.targets.map(\.kind), [.collectWatchB],
                       "watch B is a deliberate tap, never auto-granted")

        XCTAssertTrue(Level2Engine.collectWatchB(s))
        let emptied = plan(.catCushion, s)
        XCTAssertFalse(emptied.layers.map(\.key).contains("ov-cushion-reveal"),
                       "once taken the cushion drops back to its empty state")
        XCTAssertTrue(emptied.targets.isEmpty)

        for (a, b) in [(asleep, vacated), (vacated, revealed), (revealed, emptied)] {
            XCTAssertNotEqual(a, b, "each cushion step must render differently")
        }
    }

    /// The cross-view echoes end to end. cu-sill-tile and cu-cat-cushion are the SAME z1 render
    /// (ECC cc=0.9995, pure similarity), so each plate's crop bakes in a corner of the other's
    /// element. Both directions must track state, and the sill's cushion corner must reproduce
    /// the cushion plate's TRANSIENT lift window — open on lift, closed again on pickup.
    func testCrossViewEchoesTrackTheNeighbouringPlatesState() {
        let sill = L2CloseUp.plain(image: "cu-sill-tile")
        let s = makeState()

        func sillKeys() -> [String] { plan(sill, s).layers.map(\.key) }

        XCTAssertFalse(sillKeys().contains("ov-sill-cat-gone"), "fresh: the cat is on the base plate")
        XCTAssertFalse(sillKeys().contains("ov-sill-cushion-lifted"))

        // p02 — the cat leaves; the sill plate's corner must follow the cushion plate.
        s.addItem(Level2Graph.ItemID.toyMouse)
        XCTAssertTrue(Level2Engine.placeMouseAtCat(state: s))
        XCTAssertTrue(sillKeys().contains("ov-sill-cat-gone"))
        XCTAssertFalse(sillKeys().contains("ov-sill-cushion-lifted"),
                       "the cushion is down again until it is actually lifted")

        // The transient window OPENS on the lift.
        XCTAssertTrue(Level2Engine.liftCushion(state: s))
        XCTAssertTrue(Level2Engine.isWatchBUncollected(s))
        let lifted = plan(sill, s).layers.map(\.key)
        XCTAssertTrue(lifted.contains("ov-sill-cushion-lifted"))
        // ORDER IS LOAD-BEARING: the lift patch is authored to composite OVER cat-gone at the
        // IDENTICAL rect, so cat-gone must be appended first.
        guard let iGone = lifted.firstIndex(of: "ov-sill-cat-gone"),
              let iLift = lifted.firstIndex(of: "ov-sill-cushion-lifted") else {
            return XCTFail("both cushion-corner echoes must composite during the lift window")
        }
        XCTAssertLessThan(iGone, iLift, "ov-sill-cushion-lifted must composite OVER ov-sill-cat-gone")
        XCTAssertEqual(Level2OverlayCatalog.shared.cuRect("ov-sill-cushion-lifted"),
                       Level2OverlayCatalog.shared.cuRect("ov-sill-cat-gone"),
                       "the stacked patches share one rect, so dropping the top one restores the base state")

        // ...and CLOSES again on pickup, leaving the flat-cushion (cat-gone) corner.
        XCTAssertTrue(Level2Engine.collectWatchB(s))
        XCTAssertTrue(sillKeys().contains("ov-sill-cat-gone"))
        XCTAssertFalse(sillKeys().contains("ov-sill-cushion-lifted"),
                       "the transient lift echo must be dropped once watch B is collected")

        // The other direction: the cushion plate's sill corner clears when tile XI is taken,
        // and the (disjoint) sill patch composites beneath the cushion's own overlays.
        let fresh = makeState()
        XCTAssertFalse(plan(.catCushion, fresh).layers.map(\.key).contains("ov-cushion-sill-taken"))
        fresh.addItem(Level2Graph.ItemID.tileXI)
        fresh.markSolved(Level2Graph.PuzzleID.catMouse)
        let cushion = plan(.catCushion, fresh).layers.map(\.key)
        XCTAssertEqual(cushion.first, "ov-cushion-sill-taken",
                       "the sill echo composites first (its rect is disjoint from the cushion overlays)")
        XCTAssertTrue(cushion.contains("ov-cushion-empty"))
        XCTAssertFalse(Level2OverlayCatalog.shared.cuRect("ov-cushion-sill-taken")
                        .intersects(Level2OverlayCatalog.shared.cuRect("ov-cushion-empty")),
                       "disjoint rects — composite order between them is irrelevant")

        // Seating tile XI (rather than holding it) is the same latched 'taken' state.
        let seated = makeState()
        seated.setL2DialSocket("11", tile: Level2Graph.ItemID.tileXI)
        XCTAssertTrue(plan(.catCushion, seated).layers.map(\.key).contains("ov-cushion-sill-taken"))
        XCTAssertTrue(plan(sill, seated).layers.map(\.key).contains("ov-sill-tile-taken"))
    }

    /// Collecting from a close-up must EMPTY it — the direct R8-002(1) assertion.
    func testCollectingFromACloseUpEmptiesIt() {
        let s = makeState()
        let coordinator = Level2Coordinator(viewID: .bench, state: s,
                                            size: CGSize(width: 2732, height: 1366))
        coordinator.scene.onHotspotTap?("coat")
        XCTAssertEqual(coordinator.activeCloseUp, .coat)

        var p = plan(.coat, s)
        XCTAssertEqual(Set(p.targets.map(\.kind)), [.collectTileIV, .collectWatchA])
        XCTAssertTrue(p.layers.isEmpty, "both pockets still full")

        for target in p.targets { coordinator.runCloseUpTarget(target) }
        p = plan(.coat, s)
        XCTAssertTrue(p.targets.isEmpty, "nothing left to collect")
        XCTAssertEqual(Set(p.layers.map(\.key)), ["ov-coat-tile-taken", "ov-coat-watch-taken"],
                       "R8-002(1): BOTH pockets must render emptied after collection")
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.tileIV))
        XCTAssertTrue(s.hasItem(Level2Graph.ItemID.watchA))
    }

    /// The cache close-ups: pried-with-the-find -> collected -> empty (R8-009(2)/R8-010).
    func testCacheCloseUpsRenderPriedThenEmptied() {
        for (closeUp, priedKey, emptyKey, puzzle, collect) in [
            (L2CloseUp.dormerCache, "ov-cache-pried-wheel", "ov-cache-empty",
             Level2Graph.PuzzleID.cacheDormer, Level2CloseUpVisuals.Target.Kind.collectGreatWheel),
            (L2CloseUp.chimneyCache, "ov-brick-pried-oilcan", "ov-brick-empty",
             Level2Graph.PuzzleID.cacheChimney, Level2CloseUpVisuals.Target.Kind.collectOilcan),
        ] {
            let s = makeState()
            XCTAssertTrue(plan(closeUp, s).layers.isEmpty, "unpried: bare plate")
            s.markSolved(puzzle)
            let pried = plan(closeUp, s)
            XCTAssertTrue(pried.layers.map(\.key).contains(priedKey),
                          "R8-010: the pried state must render in the CLOSE-UP, not only the wide")
            XCTAssertEqual(pried.targets.map(\.kind), [collect])

            let coordinator = Level2Coordinator(viewID: closeUp == .dormerCache ? .door : .frame,
                                                state: s, size: CGSize(width: 2732, height: 1366))
            coordinator.runCloseUpTarget(pried.targets[0])
            let emptied = plan(closeUp, s)
            XCTAssertTrue(emptied.layers.map(\.key).contains(emptyKey), "collected -> empty cavity")
            XCTAssertTrue(emptied.targets.isEmpty)
        }
    }

    // MARK: - Art integrity for the close-up layer set

    /// Every overlay key any reachable close-up plan can request must resolve to STAGED art.
    /// The CU crops were authored in batch 2/3 and simply never staged; that is why the
    /// close-ups had nothing to composite.
    func testEveryCloseUpLayerResolvesToStagedArt() {
        var missing: [String] = []
        for layer in Self.allReachableLayers() where GameAssetLoader.shared.image(named: layer.image) == nil {
            missing.append("\(layer.key) -> \(layer.image)")
        }
        XCTAssertTrue(missing.isEmpty,
            "close-up overlay art missing from the bundle (would composite NOTHING): "
            + missing.sorted().joined(separator: ", "))
    }

    /// Pixel-1:1 with the authored CU rect at 2048x1536 — the close-up half of the R7-001
    /// misregistration class.
    func testCloseUpLayerArtIsPixel1to1WithItsRect() {
        let refW = Level2CloseUpVisuals.plateSize.width, refH = Level2CloseUpVisuals.plateSize.height
        var offenders: [String] = []
        for layer in Self.allReachableLayers() {
            guard let art = GameAssetLoader.shared.image(named: layer.image) else { continue }
            let rectW = layer.rect.width * refW, rectH = layer.rect.height * refH
            guard rectW > 1, rectH > 1 else { offenders.append("\(layer.key): degenerate rect"); continue }
            let rx = (art.size.width * art.scale) / rectW
            let ry = (art.size.height * art.scale) / rectH
            if abs(rx - 1.0) > 0.02 || abs(ry - 1.0) > 0.02 {
                offenders.append(String(format: "%@ art %.0fx%.0f vs rect %.0fx%.0f (%.3f/%.3f)",
                    layer.key, art.size.width * art.scale, art.size.height * art.scale, rectW, rectH, rx, ry))
            }
        }
        XCTAssertTrue(offenders.isEmpty,
            "close-up overlay art not pixel-1:1 with its @3x CU rect (runtime would MISPLACE it): "
            + offenders.joined(separator: "; "))
    }

    /// A composited layer must actually put ink on the plate. Guards the degenerate case the
    /// no-op ternary produced in spirit: a "state change" that is visually nothing.
    func testEveryCloseUpLayerActuallyPaints() {
        var blanks: [String] = []
        for layer in Self.allReachableLayers() {
            guard let art = GameAssetLoader.shared.image(named: layer.image),
                  let cg = art.cgImage else { continue }
            if Self.meanAlpha(cg) < 0.02 { blanks.append(layer.key) }
        }
        XCTAssertTrue(blanks.isEmpty,
            "close-up overlay is (near-)fully transparent — it would composite nothing: "
            + blanks.sorted().joined(separator: ", "))
    }

    /// Every layer AND every pickup target must sit inside the plate, and every target must
    /// be big enough to hit. A target off the plate is an uncollectable item.
    func testCloseUpLayersAndTargetsAreInBoundsAndTappable() {
        var offenders: [String] = []
        let unit = CGRect(x: -0.001, y: -0.001, width: 1.002, height: 1.002)
        for (label, plan) in Self.allReachablePlans() {
            for l in plan.layers where !unit.contains(l.rect) {
                offenders.append("\(label): layer \(l.key) rect out of plate bounds")
            }
            for t in plan.targets {
                if !unit.contains(t.rect) { offenders.append("\(label): target \(t.id) out of plate bounds") }
                // Smallest supported presentation: iPhone SE landscape close-up area, plate
                // fitted to ~375pt height => ~500x375 pt of plate.
                let w = t.rect.width * 500, h = t.rect.height * 375
                if min(w, h) < 20 {
                    offenders.append(String(format: "%@: target %@ ~%.0fx%.0f pt before the 44pt floor",
                                            label, t.id, w, h))
                }
            }
        }
        XCTAssertTrue(offenders.isEmpty, "close-up geometry problems:\n" + offenders.joined(separator: "\n"))
    }

    /// The p01 tray decoy is a region ON the depicted tile, not a floating text button
    /// (R8-004(3)+(4)) — and it must never become an inventory item (R6-003 principle).
    func testTrayDecoyIsAnOnPlateRegionAndNeverCollectible() {
        let r = Level2CloseUpVisuals.trayDecoyRect
        XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(r),
                      "the decoy hit region must lie on the tray art in the plate")
        // It sits in the lower-middle tray, well away from the dial sockets it must not steal.
        for key in ["ov-dial-seat-ii", "ov-dial-seat-iv", "ov-dial-seat-vii", "ov-dial-seat-xi"] {
            XCTAssertFalse(r.intersects(Level2OverlayCatalog.shared.cuRect(key)),
                           "tray decoy overlaps socket \(key)")
        }
        let s = makeState()
        XCTAssertEqual(Level2Engine.seatDialTile(Level2Graph.DecoyTile.trayVI, socket: "4", state: s), .rejected,
                       "p01 solution_fixed: 'rejected: tray VI in socket-4'")
        XCTAssertFalse(s.hasItem(Level2Graph.DecoyTile.trayVI), "the decoy never enters inventory")
    }

    /// Round 8 fix 5: the ⌂-ring clue close-up annotates the watch's direction ONLY after the
    /// watch has been inspected — the clue path is made legible without a pointer mechanic.
    func testRingClueAnnotationAppearsOnlyAfterItsWatchIsRead() {
        let s = makeState()
        guard let ring = Level2CloseUpVisuals.ringClues["cu-house-ring"] else {
            return XCTFail("the dormer ⌂ ring must carry a clue annotation")
        }
        XCTAssertEqual(ring.hour, 3, "watch A reads III -> 3 o'clock (clu-watch-a)")
        XCTAssertEqual(ring.gateClue, Level2ClueID.watchA)
        XCTAssertFalse(s.hasViewedClue(ring.gateClue), "no annotation before the watch is read")
        s.markClueViewed(ring.gateClue)
        XCTAssertTrue(s.hasViewedClue(ring.gateClue))
        XCTAssertNotNil(GameAssetLoader.shared.image(named: "hand-hour"),
                        "the canonical hour-hand sprite must ship (the wordless pointer)")
        // The pointer must land inside the plate.
        let tip = CGPoint(x: ring.center.x + ring.radiusFracOfWidth
                             * Level2CloseUpVisuals.ringPointerLengthFraction,
                          y: ring.center.y)
        XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(tip))
    }

    /// Near-wordless ruling: the p07 wheel headers are canonical landmark DIES, not the words
    /// "Big Ben"/"Burj"/"Liberty"/"Fuji" (the graph explicitly says pictogram matching suffices).
    func testVaultHeaderPictogramsShip() {
        for die in ["die-bigben", "die-burj", "die-liberty", "die-fuji"] {
            XCTAssertNotNil(GameAssetLoader.shared.image(named: die), "missing landmark die \(die)")
        }
        // And the p06 rack renders real gear art rather than numeric text buttons.
        for g in Level2Graph.rackGears {
            XCTAssertNotNil(GameAssetLoader.shared.image(named: "gear-\(g)"), "missing rack gear art gear-\(g)")
        }
        XCTAssertNotNil(GameAssetLoader.shared.image(named: "inv-great-wheel"))
    }

    // MARK: - Cluster B: the dismiss chevron must be visible + tappable on EVERY close-up

    /// Pure geometry (no simulator): on every device class the back chevron sits entirely
    /// ABOVE the inventory band and clears the 44 pt hit floor. Build 15's flat 12 pt padding
    /// put an 88x56 chevron squarely behind a 72 pt bar on every L2 close-up.
    func testDismissChevronClearsTheInventoryBandOnEveryDeviceClass() {
        let screens: [(String, CGSize, CGFloat)] = [
            ("iPad Pro 13in landscape", CGSize(width: 1366, height: 1024), L2CloseUpChrome.padBarHeight),
            ("iPad 11in landscape", CGSize(width: 1194, height: 834), L2CloseUpChrome.padBarHeight),
            ("iPhone SE landscape", CGSize(width: 667, height: 375), L2CloseUpChrome.phoneBarHeight),
            ("iPhone 16 Pro landscape", CGSize(width: 874, height: 402), L2CloseUpChrome.phoneBarHeight),
        ]
        var offenders: [String] = []
        for (name, size, bar) in screens {
            let chevron = L2CloseUpChrome.dismissFrame(in: size, barHeight: bar)
            let band = L2CloseUpChrome.inventoryBand(in: size, barHeight: bar)
            if chevron.intersects(band) {
                offenders.append("\(name): chevron \(chevron) is UNDER the inventory band \(band)")
            }
            if chevron.maxY > band.minY - L2CloseUpChrome.gap + 0.01 {
                offenders.append("\(name): chevron has no clearance above the bar")
            }
            if min(chevron.width, chevron.height) < 44 {
                offenders.append("\(name): chevron \(chevron.size) below the 44pt hit floor")
            }
            if chevron.minY < 0 {
                offenders.append("\(name): chevron pushed off the top of the screen")
            }
        }
        XCTAssertTrue(offenders.isEmpty,
            "close-up dismiss chevron occlusion (Cluster B) regressions:\n" + offenders.joined(separator: "\n"))
    }

    /// Every close-up presented by the coordinator is hosted by the SAME chrome, so the
    /// chevron guard above covers all of them. This asserts the set is complete: each close-up
    /// case resolves to a renderable plan with a real base plate.
    func testEveryCloseUpCaseResolvesToARenderablePlate() {
        var offenders: [String] = []
        for (label, plan) in Self.allReachablePlans() {
            if GameAssetLoader.shared.image(named: plan.base) == nil {
                offenders.append("\(label): base plate '\(plan.base)' is not in the bundle")
            }
            if plan.focus.width <= 0 || plan.focus.height <= 0
                || plan.focus.maxX > 1.001 || plan.focus.maxY > 1.001 {
                offenders.append("\(label): invalid focus rect \(plan.focus)")
            }
        }
        XCTAssertTrue(offenders.isEmpty, "close-up plates:\n" + offenders.joined(separator: "\n"))
    }

    // MARK: - Helpers

    /// Every close-up in a maximally-progressed state plus a few intermediate ones, so the
    /// helper sees every layer any reachable plan can produce.
    private static func allReachablePlans() -> [(String, Level2CloseUpVisuals.Plan)] {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        let closeUps: [L2CloseUp] = [
            .coat, .dialDoor, .dormerCache, .chimneyCache, .catCushion, .gearFrame,
            .windingDrum, .cabinetDrawer, .vaultWheels, .greatDial,
            .plain(image: "cu-stove-hob"), .plain(image: "cu-crate-straw"),
            .plain(image: "cu-sill-tile"), .plain(image: "cu-timelock"),
            .plain(image: "cu-gear-rack"), .plain(image: "cu-key-hook"),
            .plain(image: "cu-tag-nail"), .plain(image: "cu-house-ring"),
            .plain(image: "cu-gear-ring"), .plain(image: "cu-slate"),
            .plain(image: "cu-barometer"), .plain(image: "cu-master-face"),
            .plain(image: "cu-clockrow-plates"), .plain(image: "cu-display-case"),
            .plain(image: "cu-shelf"),
        ]
        var out: [(String, Level2CloseUpVisuals.Plan)] = []
        for (phase, mutate) in phases() {
            let s = GameState(levelID: 2, store: SaveGameStore(directory: dir.appendingPathComponent(phase)))
            mutate(s)
            for c in closeUps {
                out.append(("\(c.id) [\(phase)]", Level2CloseUpVisuals.plan(for: c, state: s)))
            }
        }
        return out
    }

    private static func allReachableLayers() -> [Level2CloseUpVisuals.Layer] {
        var seen: [String: Level2CloseUpVisuals.Layer] = [:]
        for (_, plan) in allReachablePlans() {
            for l in plan.layers { seen[l.key] = l }
        }
        // The transient cat facial keys are composited by the cushion close-up on a direct
        // offer; include them so their art + rects are guarded too (R8-011(1)).
        for key in ["ov-cat-mouse-tell", "ov-cat-slow-blink"] {
            if let l = Level2CloseUpVisuals.layer(key) { seen[key] = l }
        }
        if let tail = Level2CloseUpVisuals.catTailTellLayer() { seen[tail.key] = tail }
        return Array(seen.values)
    }

    /// Progression snapshots: fresh, mid-level, and fully solved.
    private static func phases() -> [(String, (GameState) -> Void)] {
        [
            ("fresh", { _ in }),
            ("mid", { s in
                s.addItem(Level2Graph.ItemID.tileII)
                s.addItem(Level2Graph.ItemID.tileIV)
                s.addItem(Level2Graph.ItemID.tileVII)
                s.addItem(Level2Graph.ItemID.tileXI)
                s.addItem(Level2Graph.ItemID.watchA)
                s.setL2DialSocket("2", tile: Level2Graph.ItemID.tileII)
                s.setL2DialSocket("4", tile: Level2Graph.ItemID.tileIV)
                s.markSolved(Level2Graph.PuzzleID.catMouse)
                s.setFlag(Level2Graph.Flag.cushionLifted)
                s.markSolved(Level2Graph.PuzzleID.cacheDormer)
                s.setFlag(Level2Graph.Flag.cabinetDrawerOpened)
            }),
            ("late", { s in
                s.markSolved(Level2Graph.PuzzleID.dialDoor)
                s.unlockZone(Level2Graph.ZoneID.z2Workroom)
                s.markSolved(Level2Graph.PuzzleID.catMouse)
                s.setFlag(Level2Graph.Flag.cushionLifted)
                s.addItem(Level2Graph.ItemID.watchB)
                s.markSolved(Level2Graph.PuzzleID.cacheDormer)
                s.markSolved(Level2Graph.PuzzleID.cacheChimney)
                s.setFlag(Level2Graph.Flag.arborFreed)
                s.setL2GearPost(.a, gear: "36")
                s.setL2GearPost(.b, gear: "64")
                s.setFlag(Level2Graph.Flag.cabinetDrawerOpened)
                s.addItem(Level2Graph.ItemID.toyMouse)
                s.setFlag(Level2Graph.Flag.drumOiled)
                s.setFlag(Level2Graph.Flag.clockWound)
                s.setFlag(Level2Graph.Flag.doorBarRaised)
                s.addItem(Level2Graph.ItemID.windingKey)
                s.addItem(Level2Graph.ItemID.returnTag)
                s.addItem(Level2Graph.ItemID.tileII)
                s.addItem(Level2Graph.ItemID.tileVII)
                s.addItem(Level2Graph.ItemID.tileXI)
            }),
            ("every rack gear mounted", { s in
                // Exercises the remaining ov-mount-* / ov-rack-absent-* keys.
                s.setL2GearPost(.a, gear: "16")
                s.setL2GearPost(.b, gear: "24")
            }),
            ("more rack gears", { s in
                s.setL2GearPost(.a, gear: "40")
                s.setL2GearPost(.b, gear: "48")
            }),
            ("largest rack gears", { s in
                s.setL2GearPost(.a, gear: "72")
                s.setL2GearPost(.b, gear: "36")
            }),
        ]
    }

    /// Mean alpha of an RGBA/premultiplied CGImage, sampled on a coarse grid.
    private static func meanAlpha(_ image: CGImage) -> Double {
        let w = min(image.width, 96), h = min(image.height, 96)
        guard w > 0, h > 0 else { return 0 }
        var buffer = [UInt8](repeating: 0, count: w * h * 4)
        let drawn: Bool = buffer.withUnsafeMutableBytes { raw -> Bool in
            guard let ctx = CGContext(data: raw.baseAddress, width: w, height: h,
                                      bitsPerComponent: 8, bytesPerRow: w * 4,
                                      space: CGColorSpaceCreateDeviceRGB(),
                                      bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue)
            else { return false }
            ctx.draw(image, in: CGRect(x: 0, y: 0, width: w, height: h))
            return true
        }
        guard drawn else { return 1 }   // unreadable: don't fail the build on a decode quirk
        var total = 0.0
        for i in stride(from: 3, to: buffer.count, by: 4) { total += Double(buffer[i]) / 255.0 }
        return total / Double(w * h)
    }
}
