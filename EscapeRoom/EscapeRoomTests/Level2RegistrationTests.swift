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

    private func f(_ v: CGFloat) -> String { String(format: "%.3f", v) }
    private func rectStr(_ r: CGRect) -> String { "(\(f(r.minX)),\(f(r.minY)),\(f(r.width)),\(f(r.height)))" }
}
