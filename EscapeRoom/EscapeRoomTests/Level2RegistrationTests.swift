import XCTest
import UIKit
@testable import EscapeRoom

/// M2 (QA build-1): the human-visible geometry safety net for Level 2, MIRRORING the L1
/// guards in QALevelFlowTests / RenderedFrameOverlayTests but keyed to `Level2OverlayCatalog`
/// + the `Level2Coordinator` hotspot rects. Level 2 previously had ONLY engine-logic unit
/// tests + asset-staging integrity, so the M1 floor-cache misregistration (a hotspot that did
/// not sit over the art it controls) and any R7-001-class art-in-wrong-rect defect were
/// structurally uncatchable in CI. These close that gap:
///
///  * completeness  — every overlay key the coordinator can request resolves to a non-zero rect;
///  * sub-region    — each wide rect is in-bounds, non-degenerate, and not the whole frame;
///  * pixel-1:1     — each wide overlay's ART matches its rect at the @3x wide reference dims
///                    (R7-001 class: art staged at a different size lands rescaled/misplaced);
///  * registration  — every interactive hotspot INTERSECTS the art rect it controls (the exact
///                    M1 invariant: floor-cache had ZERO overlap with the cache art);
///  * player-taps    — tapping WHERE each element VISUALLY sits (its overlay-rect center) hits
///                    that element's hotspot under the real smallest-area-wins hit test (the
///                    direct catcher for M1, m3 key/tag overlap, and m5 dial/pendulum overlap);
///  * 44pt floor     — every L2 hotspot clears the §8 44pt touch floor on the smallest iPhone.
final class Level2RegistrationTests: XCTestCase {

    private let sceneSize = CGSize(width: 2732, height: 1366)
    /// @3x wide plate reference the overlay wide_rect_3x pixel crops are authored against.
    private let wideRefW: CGFloat = 3840, wideRefH: CGFloat = 1920

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }
    private func makeState() -> GameState {
        GameState(levelID: 2, store: SaveGameStore(directory: tempDir()))
    }
    private func coordinator(_ view: L2ViewID) -> Level2Coordinator {
        Level2Coordinator(viewID: view, state: makeState(), size: sceneSize)
    }

    // Every wide overlay key the coordinator can composite, per view (superset of
    // Level2Visuals.wideOverlays across all states + the M3 pendulum/hammer motion beds).
    private static let requiredWideOverlays: [L2ViewID: [String]] = [
        .bench: ["ov-screwdriver-taken", "ov-stove-tile-taken"],
        .master: ["ov-dial-seat-ii", "ov-dial-seat-iv", "ov-dial-seat-vii", "ov-dial-seat-xi",
                  "ov-crate-tile-taken", "ov-workroom-door-open"],
        .door: ["ov-sill-tile-taken", "ov-cache-marked", "ov-cache-pried-wheel", "ov-cache-empty",
                "ov-cushion-reveal", "ov-cushion-empty", "ov-bar-raised"],
        .frame: ["ov-arbor-oiled", "ov-brick-pried-oilcan", "ov-brick-empty", "ov-panel-open"]
            + Level2Graph.rackGears.map { "ov-rack-absent-\($0)" },
        .clockrow: ["ov-cabinet-open-mouse", "ov-cabinet-empty"],
        .dial: ["ov-drum-oiled", "ov-drum-key-in", "ov-hatch-open",
                "ov-pendulum-absent", "ov-hammer-absent"],
        .vault: ["ov-key-taken", "ov-tag-taken"],
    ]

    // Interactive hotspot -> the wide overlay(s) it reveals/controls. Its rect MUST intersect
    // at least one of these (the M1 invariant).
    private static let hotspotControlsOverlay: [(L2ViewID, String, [String])] = [
        (.bench, "screwdriver", ["ov-screwdriver-taken"]),
        (.bench, "stove", ["ov-stove-tile-taken"]),
        (.master, "crate", ["ov-crate-tile-taken"]),
        (.master, "door-dial", ["ov-dial-seat-ii", "ov-dial-seat-iv", "ov-dial-seat-vii",
                                "ov-dial-seat-xi", "ov-workroom-door-open"]),
        (.door, "sill", ["ov-sill-tile-taken"]),
        (.door, "floor-cache", ["ov-cache-marked", "ov-cache-pried-wheel", "ov-cache-empty"]),
        (.door, "cat-cushion", ["ov-cushion-reveal", "ov-cushion-empty"]),
        (.door, "stair-door", ["ov-bar-raised"]),
        (.frame, "arbor", ["ov-arbor-oiled"]),
        (.frame, "brick", ["ov-brick-pried-oilcan", "ov-brick-empty"]),
        (.frame, "panel", ["ov-panel-open"]),
        (.frame, "gear-rack", Level2Graph.rackGears.map { "ov-rack-absent-\($0)" }),
        (.clockrow, "cabinet", ["ov-cabinet-open-mouse", "ov-cabinet-empty"]),
        (.dial, "drum", ["ov-drum-oiled", "ov-drum-key-in"]),
        (.dial, "hatch", ["ov-hatch-open"]),
        (.dial, "pendulum", ["ov-pendulum-absent"]),
        (.vault, "key-hook", ["ov-key-taken"]),
        (.vault, "tag-nail", ["ov-tag-taken"]),
    ]

    // Player-style visual taps: (view, expected hotspot, overlay key whose CENTER is tapped).
    private static let visualTaps: [(L2ViewID, String, String)] = [
        (.bench, "screwdriver", "ov-screwdriver-taken"),
        (.bench, "stove", "ov-stove-tile-taken"),
        (.master, "crate", "ov-crate-tile-taken"),
        (.master, "door-dial", "ov-dial-seat-ii"),
        (.door, "sill", "ov-sill-tile-taken"),
        (.door, "floor-cache", "ov-cache-pried-wheel"),   // M1: taps on the visible cache hit it
        (.door, "cat-cushion", "ov-cushion-reveal"),      // m4: watch-B reveal band tappable
        (.door, "stair-door", "ov-bar-raised"),
        (.frame, "arbor", "ov-arbor-oiled"),
        (.frame, "brick", "ov-brick-pried-oilcan"),
        (.frame, "panel", "ov-panel-open"),
        (.frame, "gear-rack", "ov-rack-absent-16"),
        (.clockrow, "cabinet", "ov-cabinet-open-mouse"),
        (.dial, "drum", "ov-drum-oiled"),
        (.dial, "hatch", "ov-hatch-open"),
        (.dial, "pendulum", "ov-pendulum-absent"),        // m5: pendulum column no longer stolen by the dial
        (.vault, "key-hook", "ov-key-taken"),             // m3: no longer stolen by the tag
        (.vault, "tag-nail", "ov-tag-taken"),
    ]

    // Inspect/look hotspots that have NO state overlay to anchor to (their pickups/reveals
    // happen inside a close-up, not via a wide overlay). Their element ART position on the wide
    // plate was measured from the SHIPPED base plates (see _reframe-work evidence sheets). Each
    // hotspot MUST (a) sit on that art and (b) be reachable INSIDE the iPad dual-safe band — the
    // exact class that shipped stale off-band rects and made L2 uncompletable on iPad (the coat
    // close-up, needed for p01 tile IV, could not be opened). Reverting any of these to its old
    // off-art rect makes the tap-at-art-center check below fail loudly.
    private static let inspectArtRects: [(L2ViewID, String, CGRect)] = [
        (.bench, "coat", CGRect(x: 0.68, y: 0.21, width: 0.13, height: 0.46)),
        (.bench, "barometer", CGRect(x: 0.28, y: 0.05, width: 0.10, height: 0.18)),
        (.master, "master-clock", CGRect(x: 0.31, y: 0.15, width: 0.15, height: 0.73)),
        (.door, "house-ring", CGRect(x: 0.45, y: 0.32, width: 0.10, height: 0.16)),
        // The ⚙+ring12 chimney carve — the ONLY way into cu-gear-ring / clu-ring-chimney.
        // Rect = the carve's ink bbox measured on the SHIPPED z2-frame-base plate (@3x pixels
        // 2826..2875 × 1073..1122, i.e. the l2_z2_build GRING anchor 2850,1097 ± the 50 px die),
        // NOT the hotspot rect: this asserts a tap where the glyph VISUALLY is resolves to the
        // clue hotspot even though the hotspot is deliberately biased off-centre to protect the
        // neighbouring cache tap (see Level2HotspotTable).
        (.frame, "gear-ring", CGRect(x: 2826/3840.0, y: 1073/1920.0,
                                     width: 49/3840.0, height: 49/1920.0)),
        (.clockrow, "clockrow", CGRect(x: 0.18, y: 0.16, width: 0.64, height: 0.42)),
        (.clockrow, "display-case", CGRect(x: 0.17, y: 0.62, width: 0.30, height: 0.30)),
        (.vault, "vault-exit", CGRect(x: 0.30, y: 0.15, width: 0.18, height: 0.70)),
    ]

    // MARK: - Completeness

    func testL2EveryRequiredWideOverlayResolvesToARect() {
        var missing: [String] = []
        for (view, keys) in Self.requiredWideOverlays {
            for key in keys where Level2OverlayCatalog.shared.wideRect(key) == .zero {
                missing.append("\(view.rawValue)/\(key)")
            }
        }
        XCTAssertTrue(missing.isEmpty,
            "coordinator-required L2 wide overlay keys with no rect (would render NOTHING in-game): "
            + missing.joined(separator: "; "))
    }

    // MARK: - Rect sanity (in-bounds, non-degenerate, sub-region)

    func testL2WideOverlayRectsAreSaneSubRegions() {
        var offenders: [String] = []
        for (_, keys) in Self.requiredWideOverlays {
            for key in keys {
                let r = Level2OverlayCatalog.shared.wideRect(key)
                guard r != .zero else { continue }   // completeness asserted separately
                let inBounds = r.minX >= 0 && r.minY >= 0 && r.maxX <= 1.0001 && r.maxY <= 1.0001
                let nonDegenerate = r.width > 0.005 && r.height > 0.005
                let subRegion = r.width < 0.95 || r.height < 0.95
                if !(inBounds && nonDegenerate && subRegion) {
                    offenders.append("\(key) rect=(\(f(r.minX)),\(f(r.minY)),\(f(r.width)),\(f(r.height)))")
                }
            }
        }
        XCTAssertTrue(offenders.isEmpty,
            "L2 wide overlay rects out of bounds / degenerate / full-frame: " + offenders.joined(separator: "; "))
    }

    // MARK: - Pixel-1:1 (R7-001 class, against the @3x wide reference)

    func testL2OverlayArtIsPixel1to1WithItsWideRect() {
        var offenders: [String] = []
        for (_, keys) in Self.requiredWideOverlays {
            for key in keys {
                let r = Level2OverlayCatalog.shared.wideRect(key)
                guard r != .zero, let art = GameAssetLoader.shared.image(named: key + "-wide") else { continue }
                let rectW = r.width * wideRefW, rectH = r.height * wideRefH
                guard rectW > 1, rectH > 1 else { continue }
                let rx = (art.size.width * art.scale) / rectW
                let ry = (art.size.height * art.scale) / rectH
                if abs(rx - 1.0) > 0.02 || abs(ry - 1.0) > 0.02 {
                    offenders.append(String(format: "%@ art %.0fx%.0f vs rect %.0fx%.0f (%.3f/%.3f)",
                        key, art.size.width * art.scale, art.size.height * art.scale, rectW, rectH, rx, ry))
                }
            }
        }
        XCTAssertTrue(offenders.isEmpty,
            "L2 overlay art not pixel-1:1 with its @3x wide rect — the runtime will rescale and MISPLACE it "
            + "(R7-001 class); re-derive the rect from the current plate, never hand-edit: "
            + offenders.joined(separator: "; "))
    }

    // MARK: - Registration (M1): the hotspot must sit ON the art it controls

    func testL2InteractiveHotspotsIntersectTheOverlayTheyControl() {
        var offenders: [String] = []
        for (view, hotspotID, overlayKeys) in Self.hotspotControlsOverlay {
            let coord = coordinator(view)
            guard let hs = coord.scene.hotspots.first(where: { $0.id == hotspotID }) else {
                offenders.append("\(view.rawValue)/\(hotspotID): hotspot not configured")
                continue
            }
            let hits = overlayKeys.contains { key in
                let r = Level2OverlayCatalog.shared.wideRect(key)
                return r != .zero && hs.normalizedRect.intersects(r)
            }
            if !hits {
                let rects = overlayKeys.map { "\($0)=\(rectStr(Level2OverlayCatalog.shared.wideRect($0)))" }
                offenders.append("\(view.rawValue)/\(hotspotID) hs=\(rectStr(hs.normalizedRect)) does not overlap any of "
                    + rects.joined(separator: ","))
            }
        }
        XCTAssertTrue(offenders.isEmpty,
            "L2 hotspot does NOT sit over the art it controls (M1 class): " + offenders.joined(separator: "; "))
    }

    // MARK: - Player-style visual taps (the direct M1 / m3 / m5 catcher)

    func testL2TapsAtVisibleElementPositionsHitTheirHotspots() {
        var misses: [String] = []
        for (view, expected, overlayKey) in Self.visualTaps {
            let coord = coordinator(view)
            let r = Level2OverlayCatalog.shared.wideRect(overlayKey)
            guard r != .zero else { misses.append("\(view.rawValue): \(overlayKey) has no rect"); continue }
            let hit = coord.scene.hotspotIDAtNormalized(r.midX, r.midY)
            if hit != expected {
                misses.append("\(view.rawValue): tap at \(overlayKey) center (\(f(r.midX)),\(f(r.midY))) "
                    + "expected '\(expected)' hit '\(hit ?? "nil")'")
            }
        }
        XCTAssertTrue(misses.isEmpty,
            "player-style L2 taps missed the visible element (hotspot geometry drift):\n" + misses.joined(separator: "\n"))
    }

    // MARK: - Overlay-less inspect hotspots sit on their ART and are iPad-reachable (R-REANCHOR)

    /// Registration for the inspect hotspots that have no overlay to key on: each hotspot must
    /// intersect the measured element ART, a tap at the art center must resolve to that hotspot
    /// under the real smallest-area-wins hit test, and the art center must fall inside the iPad
    /// dual-safe band. This is the guard that catches the "L2 uncompletable on iPad" class for
    /// look/collect hotspots (the coat/p01 blocker), mirroring the overlay-backed M1 invariant.
    func testL2InspectHotspotsSitOnArtAndAreIPadReachable() {
        var offenders: [String] = []
        for (view, hotspotID, art) in Self.inspectArtRects {
            let coord = coordinator(view)
            guard let hs = coord.scene.hotspots.first(where: { $0.id == hotspotID }) else {
                offenders.append("\(view.rawValue)/\(hotspotID): hotspot not configured"); continue
            }
            if !hs.normalizedRect.intersects(art) {
                offenders.append("\(view.rawValue)/\(hotspotID) hs=\(rectStr(hs.normalizedRect)) "
                    + "does NOT overlap its art \(rectStr(art))")
            }
            let hit = coord.scene.hotspotIDAtNormalized(art.midX, art.midY)
            if hit != hotspotID {
                offenders.append("\(view.rawValue): tap at \(hotspotID) art center (\(f(art.midX)),\(f(art.midY))) "
                    + "hit '\(hit ?? "nil")'")
            }
            let inX = Reframe.dualSafeX.contains(art.midX)
            let inY = Reframe.dualSafeY.contains(art.midY)
            if !(inX && inY) {
                offenders.append("\(view.rawValue)/\(hotspotID) art center (\(f(art.midX)),\(f(art.midY))) "
                    + "is OUTSIDE the iPad dual-safe band x\(Reframe.dualSafeX) y\(Reframe.dualSafeY) "
                    + "(would be uncroppable/untappable on iPad)")
            }
        }
        XCTAssertTrue(offenders.isEmpty,
            "L2 inspect hotspot off its art or off the iPad band (R-REANCHOR / iPad-uncompletable class):\n"
            + offenders.joined(separator: "\n"))
    }

    // MARK: - clu-ring-chimney reachability (GATE-1 clarify-clues follow-up)

    /// The ⚙+ring12 carve had NO hotspot: `cu-gear-ring` was staged and
    /// `Level2Coordinator.gatingClues` mapped `plain-cu-gear-ring -> clu-ring-chimney`, but
    /// nothing in v-frame could open it, so the chimney half of the ring/watch clue pair was
    /// unreachable in the shipped build (the ⌂ dormer ring had a hotspot; this one did not).
    ///
    /// This guard pins BOTH halves of the fix: the clue is reachable by tapping the carve, and
    /// adding it did not collapse the neighbouring loose-cache brick — the carve sits INSIDE the
    /// cache patch, and both rects are inflated to the 44 pt floor, so smallest-area-wins could
    /// easily have handed the cache's taps to the clue.
    func testGearRingCarveOpensTheChimneyRingClueWithoutStealingTheCacheTaps() {
        let s = makeState()
        let coord = Level2Coordinator(viewID: .frame, state: s, size: sceneSize)

        XCTAssertFalse(s.hasViewedClue(Level2ClueID.ringChimney))
        coord.scene.onHotspotTap?("gear-ring")
        XCTAssertEqual(coord.activeCloseUp, .plain(image: "cu-gear-ring"),
                       "the carve must open the ⚙-ring clue plate")
        XCTAssertTrue(s.hasViewedClue(Level2ClueID.ringChimney),
                      "clu-ring-chimney must be recorded — it was UNREACHABLE before this hotspot")
        XCTAssertNotNil(GameAssetLoader.shared.image(named: "cu-gear-ring"))
        XCTAssertNotNil(Level2CloseUpVisuals.ringClues["cu-gear-ring"],
                        "the plate must carry its IX pointer annotation entry")

        // Non-collapse: every point the CACHE owns still resolves to `brick`, and every point
        // on the CARVE still resolves to `gear-ring`, under the real smallest-area-wins test.
        // Cache points: the ov-brick-* rect center (what testL2Taps... taps) plus the measured
        // oil-can and pried-recess positions inside that art.
        let cacheRect = Level2OverlayCatalog.shared.wideRect("ov-brick-pried-oilcan")
        XCTAssertNotEqual(cacheRect, .zero)
        let cachePoints: [(String, CGPoint)] = [
            ("cache art center", CGPoint(x: cacheRect.midX, y: cacheRect.midY)),
            ("oil can", CGPoint(x: 0.7167, y: 0.6140)),
            ("pried recess", CGPoint(x: 0.7397, y: 0.6240)),
        ]
        // Carve ink bbox measured on the shipped plate (@3x 2826..2875 × 1073..1122).
        let carvePoints: [(String, CGPoint)] = [
            ("carve center", CGPoint(x: 2850/3840.0, y: 1097/1920.0)),
            ("carve left rim", CGPoint(x: 2826/3840.0, y: 1097/1920.0)),
            ("carve top", CGPoint(x: 2850/3840.0, y: 1073/1920.0)),
            ("carve bottom", CGPoint(x: 2850/3840.0, y: 1122/1920.0)),
        ]
        var offenders: [String] = []
        for (label, p) in cachePoints {
            let hit = coord.scene.hotspotIDAtNormalized(p.x, p.y)
            if hit != "brick" { offenders.append("\(label) (\(f(p.x)),\(f(p.y))) -> '\(hit ?? "nil")' (expected brick)") }
        }
        for (label, p) in carvePoints {
            let hit = coord.scene.hotspotIDAtNormalized(p.x, p.y)
            if hit != "gear-ring" { offenders.append("\(label) (\(f(p.x)),\(f(p.y))) -> '\(hit ?? "nil")' (expected gear-ring)") }
        }
        XCTAssertTrue(offenders.isEmpty,
            "gear-ring / brick-cache overlap-collapse in v-frame:\n" + offenders.joined(separator: "\n"))
    }

    // MARK: - BUILD 17: the z3 CLOCKWORK SPRITE rig (R8-020)
    //
    // Build 16 rendered the pendulum and both dial hands PROCEDURALLY, and the batch-4
    // `ov-pendulum-absent` rect had drifted from the plate: it clipped the painted bob's right
    // crescent and its finial, so those pixels survived beside the animated one — the "double
    // pendulum" in the user's screenshot, the same class as the L1 R7-001 stale rect. These
    // guards pin the sprite rig to the art it was cut from.

    /// The paint-out patch and the sprite MUST occupy the same rect. If they diverge, part of
    /// the painted pendulum is left behind (build 16) or the patch shows past the sprite.
    func testPendulumAbsentPatchAndSpriteShareOneRect() {
        let sprite = Level2SpriteCatalog.shared.pendulum
        let patch = Level2OverlayCatalog.shared.wideRect("ov-pendulum-absent")
        XCTAssertNotEqual(patch, .zero, "ov-pendulum-absent must resolve a wide rect")
        let eps: CGFloat = 0.0005
        XCTAssertEqual(sprite.rect.minX, patch.minX, accuracy: eps)
        XCTAssertEqual(sprite.rect.minY, patch.minY, accuracy: eps)
        XCTAssertEqual(sprite.rect.width, patch.width, accuracy: eps)
        XCTAssertEqual(sprite.rect.height, patch.height, accuracy: eps,
                       "the swinging sprite and the patch that erases the painted pendulum must "
                       + "be registered on the SAME rect — a drift leaves a second pendulum")
    }

    /// The authored cutout ships, is pixel-1:1 with its rect, and its pivot is a real
    /// suspension point at the TOP of the sprite (a pivot in the middle would swing the bob
    /// about its own centre).
    func testPendulumSpriteShipsAndHangsFromItsAuthoredPivot() {
        let p = Level2SpriteCatalog.shared.pendulum
        guard let art = GameAssetLoader.shared.image(named: p.image) else {
            return XCTFail("the authored pendulum cutout '\(p.image)' is not staged")
        }
        let px = art.size.width * art.scale, py = art.size.height * art.scale
        XCTAssertEqual(px / (p.rect.width * wideRefW), 1.0, accuracy: 0.02,
                       "pendulum sprite not pixel-1:1 with its @3x rect (would be rescaled)")
        XCTAssertEqual(py / (p.rect.height * wideRefH), 1.0, accuracy: 0.02)
        XCTAssertTrue((0...1).contains(p.pivot.x) && (0...1).contains(p.pivot.y),
                      "pivot must lie inside the sprite")
        XCTAssertLessThan(p.pivot.y, 0.15, "the pendulum hangs from a pivot near its TOP")
        XCTAssertGreaterThan(p.fullDegrees, p.weakDegrees,
                             "a wound clock must swing wider than an unwound one")
        XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(p.rect))
    }

    /// R8-020(1): the great dial's hands are the AUTHORED sprites, pivoting on the HUB — not
    /// capsules centred on the plate. The hub must be the works arbor (well off plate centre
    /// on this crop), and each hand's pivot must sit near its own tail.
    func testGreatDialHandsUseAuthoredSpritesAnchoredOnTheHub() {
        let rig = Level2SpriteCatalog.shared
        for hand in [rig.hourHand, rig.minuteHand] {
            XCTAssertNotNil(GameAssetLoader.shared.image(named: hand.image),
                            "authored hand sprite '\(hand.image)' is not staged")
            XCTAssertGreaterThan(hand.anchor.y, 0.55,
                                 "\(hand.image): the pivot must sit near the hand's TAIL, so the "
                                 + "sprite sweeps from the hub (build 16's minute hand floated "
                                 + "mid-face because it pivoted on the plate centre)")
            XCTAssertEqual(hand.anchor.x, 0.5, accuracy: 0.08, "a hand pivots on its own axis")
            XCTAssertGreaterThan(hand.length, 100)
        }
        XCTAssertGreaterThan(rig.minuteHand.length, rig.hourHand.length,
                             "the minute hand must be the longer of the two, or the dial is "
                             + "unreadable regardless of anchoring")

        let hub = rig.dial.hub
        XCTAssertTrue(CGRect(x: 0, y: 0, width: 1, height: 1).contains(hub))
        XCTAssertGreaterThan(abs(hub.x - 0.5), 0.05,
                             "the hub is NOT the plate centre on this crop — assuming it was is "
                             + "exactly the build-16 mis-anchor")
        // The minute hand must reach into the numeral ring but stay on the plate.
        let reach = rig.minuteHand.length * rig.dial.cuScale / Level2SpriteCatalog.cuRef.width
        XCTAssertGreaterThan(reach, 0.15)
        XCTAssertLessThan(hub.x + reach, 1.0)
        XCTAssertLessThan(rig.dial.ringSquashX, 1.001)
        XCTAssertGreaterThan(rig.dial.ringSquashX, 0.6)
    }

    /// D1: no time is baked into the art — the FRONT time drives the sprite angles, and the
    /// back view renders them mirrored. This pins the angle contract the hands are drawn with.
    func testMirroredDialAngleContract() {
        let s = makeState()
        s.setL2ClockFrontMinutes(Level2Graph.clockReleaseMinutes)     // 7:20
        XCTAssertEqual(s.data.l2ClockFrontMinutes, 440)
        let hourFront = Double(s.data.l2ClockFrontMinutes) * 0.5      // 220 deg
        let minuteFront = Double(s.data.l2ClockFrontMinutes % 60) * 6 // 120 deg
        XCTAssertEqual(hourFront, 220, accuracy: 0.001)
        XCTAssertEqual(minuteFront, 120, accuracy: 0.001)
        // The view renders -theta (mirror). 7:20 front therefore draws at -220 / -120.
        XCTAssertEqual(-hourFront, -220, accuracy: 0.001)
        XCTAssertEqual(-minuteFront, -120, accuracy: 0.001)
    }

    // MARK: - BUILD 17: diegetic affordance regions (R8-019 / R8-020 sub-item)

    /// The crank and the dial's time-adjust affordances are anchored ON their painted art and
    /// are big enough to hit. (The idiom itself — no `arrow.clockwise` reload glyph, no flat
    /// white +/- chrome — lives in the view; this pins the geometry those regions use.)
    func testDiegeticCrankRegionsSitOnThePlateAndClearTheHitFloor() {
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        for (name, r) in [("gear-frame crank", Level2CloseUpVisuals.crankHandleRect),
                          ("great-dial setting crank", Level2CloseUpVisuals.dialCrankRect),
                          ("cat floor placement (R8-015)", Level2CloseUpVisuals.catFloorRect),
                          ("cat offer band", Level2CloseUpVisuals.catOfferRect)] {
            XCTAssertTrue(unit.contains(r), "\(name) region is off the close-up plate: \(r)")
            // Smallest supported presentation: ~500x375 pt of plate (iPhone SE landscape).
            XCTAssertGreaterThan(min(r.width * 500, r.height * 375), 24,
                                 "\(name) region is too small to hit before the 44pt floor")
        }
        XCTAssertFalse(Level2CloseUpVisuals.catFloorRect.intersects(Level2CloseUpVisuals.catOfferRect),
                       "the PLACE and OFFER regions must be distinct, or p02's two verbs collide")
    }

    // MARK: - REV 1.4.1: the WIDE ring-hand echoes (D12 C1 + C3)

    /// The two new entries are MEASUREMENTS, not choices: they must match
    /// `specs/assets/level-2/ring-clue-wide-geometry.json` exactly, or the hand is pivoted
    /// somewhere other than the ring the art was measured against (the R7-001 / stale-rect
    /// class, pointer edition).
    func testWideRingHandEntriesMatchTheMeasuredGeometry() {
        // (plate, hub, radiusFracOfWidth, hour, gate, multiplier, effective length px @3x)
        let measured: [(String, CGPoint, CGFloat, Int, String, CGFloat, CGFloat)] = [
            ("z1-door-base", CGPoint(x: 0.491302, y: 0.377969), 0.018672, 3,
             Level2ClueID.watchA, 1.35, 83.2),
            ("z2-frame-base", CGPoint(x: 0.742292, y: 0.571667), 0.005495, 9,
             Level2ClueID.watchB, 2.75, 49.9),
        ]
        for (plate, hub, radius, hour, gate, mult, lengthPx) in measured {
            guard let ring = Level2CloseUpVisuals.ringClues[plate] else {
                XCTFail("\(plate): no wide ring-hand entry (C1/C3 not wired)"); continue
            }
            XCTAssertEqual(ring.center.x, hub.x, accuracy: 0.000001, "\(plate) hub x")
            XCTAssertEqual(ring.center.y, hub.y, accuracy: 0.000001, "\(plate) hub y")
            XCTAssertEqual(ring.radiusFracOfWidth, radius, accuracy: 0.000001, "\(plate) radius")
            XCTAssertEqual(ring.hour, hour, "\(plate) bearing")
            XCTAssertEqual(ring.gateClue, gate, "\(plate) gate")
            XCTAssertEqual(ring.pointerMultiplier, mult, accuracy: 0.0001, "\(plate) scale factor")
            XCTAssertEqual(ring.pointerLengthFracOfWidth * wideRefW, lengthPx, accuracy: 0.15,
                           "\(plate): effective pointer length must match the measured proof")
        }
        // The view lookup must find them by the plate the view actually renders.
        XCTAssertEqual(Level2CloseUpVisuals.wideRingClue(.door)?.hour, 3)
        XCTAssertEqual(Level2CloseUpVisuals.wideRingClue(.frame)?.hour, 9)
        XCTAssertNil(Level2CloseUpVisuals.wideRingClue(.bench), "only two wides carry a ring")
    }

    /// CONTAINMENT + PIVOT geometry, computed with the SAME function the SwiftUI close-up and
    /// the SpriteKit wide renderer both use — so this is the composite that actually ships:
    /// the hub anchor lands inside the art, and both the hub and the pointer tip stay on the
    /// plate (an over-scaled hand that ran off the plate would read "keep going that way").
    func testRingHandCompositeIsAnchoredOnTheHubAndStaysOnThePlate() {
        guard let art = GameAssetLoader.shared.image(named: Level2Coordinator.ringHandSprite) else {
            return XCTFail("the canonical hour-hand sprite must ship")
        }
        let pixels = CGSize(width: art.size.width * art.scale, height: art.size.height * art.scale)
        let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
        var offenders: [String] = []
        for (plate, ring) in Level2CloseUpVisuals.ringClues.sorted(by: { $0.key < $1.key }) {
            let width: CGFloat = plate.hasPrefix("cu-") ? 2048 : 3840
            let L = ring.pointerLengthFracOfWidth * width
            let layout = Level2CloseUpVisuals.ringHandLayout(spritePixelSize: pixels, length: L)
            if layout.size.width <= 0 || layout.size.height <= 0 {
                offenders.append("\(plate): degenerate composite"); continue
            }
            if !(0...1).contains(layout.anchor.y) {
                offenders.append(String(format: "%@: the hub anchor (%.3f) falls OUTSIDE the art "
                    + "— the sprite would not pivot on the ring", plate, layout.anchor.y))
            }
            if abs(layout.anchor.x - 0.5) > 0.001 {
                offenders.append("\(plate): a hand pivots on its own axis")
            }
            // Tip, in plate-normalized coordinates: hour*30 clockwise from straight up.
            let theta = Double(ring.degrees) * .pi / 180
            let aspect: CGFloat = plate.hasPrefix("cu-") ? 2048.0 / 1536.0 : 2.0
            let tip = CGPoint(x: ring.center.x + ring.pointerLengthFracOfWidth * CGFloat(sin(theta)),
                              y: ring.center.y - ring.pointerLengthFracOfWidth * aspect * CGFloat(cos(theta)))
            if !unit.contains(tip) || !unit.contains(ring.center) {
                offenders.append("\(plate): hub \(ring.center) / tip \(tip) leaves the plate")
            }
        }
        XCTAssertTrue(offenders.isEmpty, "ring-hand composite geometry:\n" + offenders.joined(separator: "\n"))
    }

    /// The wide hand is PRESENTATION ONLY: it appears exactly on its D7 clue boolean, adds no
    /// hotspot, and — the property that keeps it safe — is invisible to hit testing, so it can
    /// never steal a tap from the ring, the cache or the brick beneath it.
    func testWideRingHandIsGatedAndNeverStealsATap() {
        for (view, gate, neighbour) in [(L2ViewID.door, Level2ClueID.watchA, "house-ring"),
                                        (L2ViewID.frame, Level2ClueID.watchB, "gear-ring")] {
            let s = makeState()
            let coord = Level2Coordinator(viewID: view, state: s, size: sceneSize)
            guard let ring = Level2CloseUpVisuals.wideRingClue(view) else {
                XCTFail("\(view.rawValue): no wide ring entry"); continue
            }
            let idsBefore = Set(coord.scene.hotspots.map(\.id))
            let hitBefore = coord.scene.hotspotIDAtNormalized(ring.center.x, ring.center.y)
            let handName = "ringhand:\(view.baseTexture)"
            XCTAssertFalse(coord.scene.children.contains(where: { $0.name == handName }),
                           "\(view.rawValue): the hand must NOT be composited before \(gate) is viewed")

            s.markClueViewed(gate)
            coord.refresh()
            XCTAssertTrue(coord.scene.children.contains(where: { $0.name == handName }),
                          "\(view.rawValue): the hand must composite once \(gate) is viewed")
            XCTAssertEqual(Set(coord.scene.hotspots.map(\.id)), idsBefore,
                           "\(view.rawValue): the annotation must add NO hotspot")
            XCTAssertEqual(coord.scene.hotspotIDAtNormalized(ring.center.x, ring.center.y), hitBefore,
                           "\(view.rawValue): the hand must not change what a tap on the \(neighbour) ring hits")
        }
    }

    // MARK: - 44pt hit-target floor on the smallest iPhone (BUG-009 class)

    func testL2HotspotsMeet44ptFloorOniPhoneSE() {
        // iPhone SE (3rd gen) landscape 667x375 pt, `.aspectFill` cover scale.
        let scale = max(667.0 / sceneSize.width, 375.0 / sceneSize.height)
        var offenders: [String] = []
        for view in L2ViewID.allCases {
            for hs in coordinator(view).scene.hotspots {
                let w = max(hs.normalizedRect.width * sceneSize.width, hs.minHitSize) * scale
                let h = max(hs.normalizedRect.height * sceneSize.height, hs.minHitSize) * scale
                if min(w, h) < 44 { offenders.append("\(view.rawValue)/\(hs.id) ~\(Int(w))x\(Int(h))pt") }
            }
        }
        XCTAssertTrue(offenders.isEmpty, "L2 hotspots below the 44pt floor on iPhone SE: " + offenders.joined(separator: "; "))
    }

    // MARK: - UI-test-tap <-> hotspot-rect coupling (build-15 stale-coat-tap class)

    /// The exact hotspots the L2 on-device smoke test taps BY CENTER via
    /// `Level2UITests.tapHotspot`. This is the set whose "tap the table center -> that element
    /// reacts" assumption the UI test depends on, so it is the set this guard proves resolvable.
    /// (Keep in lockstep with the `tapHotspot(...)` calls in testL2Z1PickupsCloseUpsAndNavigationSmoke.)
    ///
    /// NOTE — not every hotspot resolves to itself at its EXACT geometric center: a few authored
    /// rects overlap by design and a smaller neighbor can win at the larger one's dead center
    /// (e.g. v-frame `gear-rack`'s center sits on the loose-`brick` hit region; `gear-rack` is
    /// still reachable everywhere left of that overlap). Those hotspots are NOT tapped by center
    /// in any UI test, so they are intentionally excluded here. This is a pre-existing, benign
    /// geometry property (unchanged by the table extraction), flagged in implementation-notes; it
    /// is NOT a stale-tap regression and is out of this fix's scope (hotspot geometry is design).
    private static let uiTappedHotspots: [(view: String, id: String)] = [
        ("v-bench", "screwdriver"), ("v-bench", "stove"), ("v-bench", "coat"),
        ("v-master", "crate"), ("v-master", "door-dial"), ("v-door", "sill"),
    ]

    /// The build-15 TestFlight gate went red because a hand-coded UI-test tap (coat @ x0.17)
    /// desynced from a re-anchored hotspot (coat @ x≈0.74). The fix routes BOTH the game hotspots
    /// AND the UI-test taps through one source, `Level2HotspotTable`. This deterministic guard
    /// (no simulator) locks that coupling from the game side:
    ///
    ///  1. every hotspot the coordinator configures matches the table it is built from — id set
    ///     and rect, ALL views — so the coordinator can never quietly diverge from the table the
    ///     UI tests read; and
    ///  2. for every hotspot the UI test taps by center, a tap at that table entry's CENTER
    ///     (exactly what `tapHotspot` taps) resolves to that same hotspot under the real
    ///     smallest-area-wins hit test — so the UI-test tap assumption is CI-proven.
    func testL2HotspotTableIsTheSingleSourceForCoordinatorAndTapCenters() {
        var offenders: [String] = []

        // (1) Full coordinator <-> table parity, every view.
        for view in L2ViewID.allCases {
            let configured = coordinator(view).scene.hotspots
            let table = Level2HotspotTable.rects(forView: view.rawValue)
            let configuredIDs = Set(configured.map(\.id))
            let tableIDs = Set(table.map(\.id))
            if configuredIDs != tableIDs {
                offenders.append("\(view.rawValue): coordinator ids \(configuredIDs.sorted()) != table ids \(tableIDs.sorted())")
            }
            for (id, rect) in table where configuredIDs.contains(id) {
                if let hs = configured.first(where: { $0.id == id }), hs.normalizedRect != rect {
                    offenders.append("\(view.rawValue)/\(id): coordinator rect \(rectStr(hs.normalizedRect)) != table \(rectStr(rect))")
                }
            }
        }

        // (2) Each UI-tapped hotspot's table center resolves to that hotspot.
        for (view, id) in Self.uiTappedHotspots {
            guard let rect = Level2HotspotTable.rect(id, inView: view) else {
                offenders.append("\(view)/\(id): not in Level2HotspotTable (UI test taps a missing id)"); continue
            }
            let hit = coordinator(L2ViewID(rawValue: view)!).scene.hotspotIDAtNormalized(rect.midX, rect.midY)
            if hit != id {
                offenders.append("\(view): UI tap at \(id) table center (\(f(rect.midX)),\(f(rect.midY))) resolved to '\(hit ?? "nil")'")
            }
        }

        XCTAssertTrue(offenders.isEmpty,
            "Level2HotspotTable <-> coordinator/UI-test-tap coupling broken (stale-tap class):\n"
            + offenders.joined(separator: "\n"))
    }

    private func f(_ v: CGFloat) -> String { String(format: "%.3f", v) }
    private func rectStr(_ r: CGRect) -> String { "(\(f(r.minX)),\(f(r.minY)),\(f(r.width)),\(f(r.height)))" }
}
