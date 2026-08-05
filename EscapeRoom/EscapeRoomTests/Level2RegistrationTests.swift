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
        .door: ["ov-sill-tile-taken", "ov-cache-pried-wheel", "ov-cache-empty",
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
        (.door, "floor-cache", ["ov-cache-pried-wheel", "ov-cache-empty"]),
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
