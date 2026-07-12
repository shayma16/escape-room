import XCTest
import SpriteKit
import UIKit
@testable import EscapeRoom

/// R5-001 (build 11) — RENDERED-FRAME overlay-registration guard.
///
/// THE QA GAP THIS CLOSES: build 10's overlay architecture was "verified" with an
/// OFFLINE composite (pasting the staged overlay at its overlays.json rect), which
/// validates the assets + rects but says nothing about the RUNTIME compositor. R5-001
/// then shipped a defect the offline check could not see. These tests render the LIVE
/// scene graph through the real SpriteKit renderer (`SKView.texture(from:)` — the same
/// node positions, anchor points, scale mapping, z-ordering and edge-feathering the
/// device composites) and assert the rendered frame matches the expected offline
/// composite of the same bundled assets, region by region:
///
///  * presence   — the rendered frame must be strictly CLOSER to the with-overlay
///                 composite than to the base-only plate (the overlay actually drew);
///  * fidelity   — mean |luma| difference vs the expected composite under tolerance;
///  * registration — the zero-shift alignment must beat every ±16 px probe shift, so a
///                 translated/mis-scaled runtime placement fails loudly even where the
///                 art is low-contrast.
///
/// A divergence between RoomScene.positionOverlay / setOverlay math and the
/// tools/build_game_assets.py rect contract can no longer pass silently.
///
/// (Postscript for the record: applying exactly this comparison to build 10 shows the
/// runtime and the offline composite were IDENTICAL — the R5-001 "misplaced fireplace
/// fragment" was baked into the z1-hearth-poker-taken source plate itself (a +240 px
/// clone-fill), now guarded at the asset pipeline by assert_no_misplaced_clone_fill.)
final class RenderedFrameOverlayTests: XCTestCase {

    private func tempDir() -> URL {
        let dir = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir
    }

    private func makeState(_ dir: URL) -> GameState {
        GameState(levelID: 1, store: SaveGameStore(directory: dir))
    }

    private let sceneSize = CGSize(width: 2732, height: 1366)
    /// Grayscale analysis raster (half scene size): plenty of resolution for ±8 px
    /// (=16 scene px) registration probes while keeping the pixel loops fast on CI.
    private let analysisSize = (w: 1366, h: 683)

    // MARK: - Rendering + compositing

    /// Renders the coordinator's scene through the REAL SpriteKit renderer. This is the
    /// runtime compositing path itself: RoomScene's overlay nodes (anchorPoint, position,
    /// size, zPosition, feathered textures) rasterized exactly as SKView presents them.
    private func renderFrame(_ scene: RoomScene) -> CGImage? {
        let view = SKView(frame: CGRect(x: 0, y: 0, width: 683, height: 341.5))
        view.ignoresSiblingOrder = true // match SpriteKitContainerView's presentation
        view.presentScene(scene)        // texture(from:) is defined for a presented tree
        // Scene anchorPoint is (0.5, 0.5): the plate spans ±width/2 x ±height/2.
        let crop = CGRect(x: -sceneSize.width / 2, y: -sceneSize.height / 2,
                          width: sceneSize.width, height: sceneSize.height)
        guard let texture = view.texture(from: scene, crop: crop) else { return nil }
        return texture.cgImage()
    }

    /// The OFFLINE composite the QA method used: base plate + each overlay drawn at its
    /// overlays.json rect (top-left-origin normalized), in ascending z order.
    private func offlineComposite(base: String, view viewKey: String,
                                  overlays: [String]) -> UIImage? {
        guard let baseImg = GameAssetLoader.shared.image(named: base) else { return nil }
        let size = CGSize(width: analysisSize.w, height: analysisSize.h)
        let fmt = UIGraphicsImageRendererFormat()
        fmt.scale = 1
        return UIGraphicsImageRenderer(size: size, format: fmt).image { _ in
            baseImg.draw(in: CGRect(origin: .zero, size: size))
            for name in overlays {
                guard let rect = OverlayRectCatalog.shared.rect(view: viewKey, overlay: name),
                      let img = GameAssetLoader.shared.image(named: name) else { continue }
                img.draw(in: CGRect(x: rect.minX * size.width, y: rect.minY * size.height,
                                    width: rect.width * size.width, height: rect.height * size.height))
            }
        }
    }

    // MARK: - Grayscale buffers + region metrics

    private struct Gray { let px: [UInt8]; let w: Int; let h: Int }

    private func gray(_ cg: CGImage) -> Gray? {
        let w = analysisSize.w, h = analysisSize.h
        var px = [UInt8](repeating: 0, count: w * h)
        guard let ctx = CGContext(data: &px, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: w, space: CGColorSpaceCreateDeviceGray(),
                                  bitmapInfo: CGImageAlphaInfo.none.rawValue) else { return nil }
        ctx.interpolationQuality = .high
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))
        return Gray(px: px, w: w, h: h)
    }

    /// Mean |a - b| over a normalized (top-left-origin) rect; `offset` shifts where A is
    /// SAMPLED (in analysis pixels) — the registration probe.
    private func meanAbsDiff(_ a: Gray, _ b: Gray, rect: CGRect,
                             offset: (dx: Int, dy: Int) = (0, 0)) -> Double {
        let x0 = max(0, Int(rect.minX * CGFloat(a.w))), x1 = min(a.w, Int(rect.maxX * CGFloat(a.w)))
        let y0 = max(0, Int(rect.minY * CGFloat(a.h))), y1 = min(a.h, Int(rect.maxY * CGFloat(a.h)))
        var total = 0, count = 0
        for y in y0..<y1 {
            let ya = y + offset.dy
            guard ya >= 0, ya < a.h else { continue }
            for x in x0..<x1 {
                let xa = x + offset.dx
                guard xa >= 0, xa < a.w else { continue }
                total += abs(Int(a.px[ya * a.w + xa]) - Int(b.px[y * b.w + x]))
                count += 1
            }
        }
        return count > 0 ? Double(total) / Double(count) : 0
    }

    private func attach(_ cg: CGImage, name: String) {
        let att = XCTAttachment(image: UIImage(cgImage: cg))
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    /// Shared per-overlay assertion block (presence + fidelity + registration).
    private func assertOverlayRegion(_ rendered: Gray, expected: Gray, baseOnly: Gray,
                                     viewKey: String, overlay: String, label: String,
                                     file: StaticString = #filePath, line: UInt = #line) {
        guard let rect = OverlayRectCatalog.shared.rect(view: viewKey, overlay: overlay) else {
            XCTFail("\(label): \(overlay) missing from overlays.json", file: file, line: line)
            return
        }
        let dExpected = meanAbsDiff(rendered, expected, rect: rect)
        let dBaseOnly = meanAbsDiff(rendered, baseOnly, rect: rect)
        let probes = [(-8, 0), (8, 0), (0, -8), (0, 8)].map {
            meanAbsDiff(rendered, expected, rect: rect, offset: (dx: $0.0, dy: $0.1))
        }
        let diag = "\(label) \(overlay): dExpected=\(String(format: "%.2f", dExpected)) " +
            "dBaseOnly=\(String(format: "%.2f", dBaseOnly)) " +
            "probes(±8px)=\(probes.map { String(format: "%.2f", $0) }.joined(separator: ","))"
        print("RENDERED-FRAME GUARD: \(diag)")
        let att = XCTAttachment(string: diag)
        att.name = "registration-\(label)-\(overlay)"
        att.lifetime = .keepAlways
        add(att)

        // Fidelity: the live SpriteKit render must match the offline composite.
        XCTAssertLessThan(dExpected, 4.0,
            "\(label): rendered frame diverges from the offline composite in the \(overlay) " +
            "region — runtime compositor no longer matches the overlays.json contract. \(diag)",
            file: file, line: line)
        // Presence: strictly closer to with-overlay than to base-only (the overlay drew;
        // catches a nil texture / stale-node / wrong-state-selection failure even for
        // subtle overlays whose absolute diff vs base is small).
        XCTAssertLessThan(dExpected, dBaseOnly,
            "\(label): rendered frame is closer to the BASE-ONLY plate than to the " +
            "with-overlay composite — \(overlay) did not actually render. \(diag)",
            file: file, line: line)
        // Registration: zero shift must beat every ±16-scene-px probe. A translated /
        // mis-scaled runtime placement loses this even where tones are similar.
        if dExpected >= 1.5 {
            for (i, p) in probes.enumerated() {
                XCTAssertGreaterThan(p, dExpected,
                    "\(label): probe shift #\(i) aligns BETTER than zero shift — the " +
                    "\(overlay) overlay is misregistered in the rendered frame. \(diag)",
                    file: file, line: line)
            }
        }
    }

    // MARK: - Case 1: poker-taken (the R5-001 report surface)

    func testRenderedFramePokerTakenMatchesOfflineComposite_R5_001() throws {
        let state = makeState(tempDir())
        state.addItem(PuzzleGraph.ItemID.poker) // pokerTaken(state) == true
        let coordinator = RoomSceneCoordinator(viewID: .hearth, state: state, size: sceneSize)
        guard let frame = renderFrame(coordinator.scene) else {
            XCTFail("SKView.texture(from:) returned nil — cannot render the hearth scene")
            return
        }
        attach(frame, name: "rendered-hearth-poker-taken")
        guard let expectedImg = offlineComposite(base: "z1-hearth-base", view: "z1/v-hearth",
                                                 overlays: ["ov-poker-taken"])?.cgImage,
              let baseImg = offlineComposite(base: "z1-hearth-base", view: "z1/v-hearth",
                                             overlays: [])?.cgImage,
              let rendered = gray(frame), let expected = gray(expectedImg),
              let baseOnly = gray(baseImg) else {
            XCTFail("could not build offline composites for the hearth")
            return
        }
        // Whole-frame sanity: base plate + overlay render as one coherent composite.
        let dGlobal = meanAbsDiff(rendered, expected, rect: CGRect(x: 0, y: 0, width: 1, height: 1))
        XCTAssertLessThan(dGlobal, 4.0,
            "hearth: whole rendered frame diverges from the offline composite (global " +
            "mean |luma| diff \(String(format: "%.2f", dGlobal))) — base plate or scene transform drift")
        assertOverlayRegion(rendered, expected: expected, baseOnly: baseOnly,
                            viewKey: "z1/v-hearth", overlay: "ov-poker-taken", label: "hearth")
    }

    // MARK: - Case 2: cellar full overlay stack (the R4-024 per-element architecture)

    /// Six independent overlays co-rendered with explicit z-ordering (mirror z11 <
    /// shelf z12 < beam z13, others z10) — the heaviest compositing case in the level.
    /// Every region must match the offline composite built in the same z order.
    func testRenderedFrameCellarComboMatchesOfflineComposite_R5_001() throws {
        let state = makeState(tempDir())
        state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)                  // cellar reachable (p06/p07 guard)
        state.addItem(PuzzleGraph.ItemID.poker)
        XCTAssertTrue(PuzzleEngine.pryBarrel(state: state))            // ov-barrel-pried
        PuzzleEngine.openCellarDrawer(state: state)                    // ov-drawer-open (spoon visible)
        state.addItem(PuzzleGraph.ItemID.weight)
        XCTAssertTrue(PuzzleEngine.hangWeight(state: state))           // ov-shelf-slid (z4 unlocked)
        state.setFlag(PuzzleGraph.StateFlag.moonbeamOn)                // ov-crank-fitted + beam on
        PuzzleEngine.rotateMirror(toDetent: 3, state: state)           // ov-mirror-d3 + detent-3 flag
        XCTAssertEqual(RoomVisuals.beamVisual(state), .intoAlcove)     // full matrix: ov-beam-alcove

        let coordinator = RoomSceneCoordinator(viewID: .cellar, state: state, size: sceneSize)
        guard let frame = renderFrame(coordinator.scene) else {
            XCTFail("SKView.texture(from:) returned nil — cannot render the cellar scene")
            return
        }
        attach(frame, name: "rendered-cellar-combo")
        // Ascending z order, mirroring refreshCellar: z10 barrel/drawer/crank,
        // z11 mirror, z12 shelf, z13 beam.
        let stack = ["ov-barrel-pried", "ov-drawer-open", "ov-crank-fitted",
                     "ov-mirror-d3", "ov-shelf-slid", "ov-beam-alcove"]
        guard let expectedImg = offlineComposite(base: "z3-cellar-base", view: "z3/v-cellar",
                                                 overlays: stack)?.cgImage,
              let baseImg = offlineComposite(base: "z3-cellar-base", view: "z3/v-cellar",
                                             overlays: [])?.cgImage,
              let rendered = gray(frame), let expected = gray(expectedImg),
              let baseOnly = gray(baseImg) else {
            XCTFail("could not build offline composites for the cellar")
            return
        }
        let dGlobal = meanAbsDiff(rendered, expected, rect: CGRect(x: 0, y: 0, width: 1, height: 1))
        XCTAssertLessThan(dGlobal, 4.0,
            "cellar: whole rendered frame diverges from the offline composite (global " +
            "mean |luma| diff \(String(format: "%.2f", dGlobal))) — stack/z-order or transform drift")
        for overlay in stack {
            assertOverlayRegion(rendered, expected: expected, baseOnly: baseOnly,
                                viewKey: "z3/v-cellar", overlay: overlay, label: "cellar")
        }
    }
}
