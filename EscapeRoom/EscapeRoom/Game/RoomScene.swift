import SpriteKit
#if canImport(UIKit)
import UIKit
#endif

/// Identifies one of the level's views. zone groupings mirror puzzle-graph.json.
enum ViewID: String, CaseIterable {
    case hearth = "v-hearth"
    case study = "v-study"
    case entry = "v-entry"
    case bench = "v-bench"
    case cabinet = "v-cabinet"
    case cellar = "v-cellar"
    case alcove = "v-alcove"

    var zoneID: String {
        switch self {
        case .hearth, .study, .entry: return PuzzleGraph.ZoneID.z1Cabin
        case .bench, .cabinet: return PuzzleGraph.ZoneID.z2Workshop
        case .cellar: return PuzzleGraph.ZoneID.z3Cellar
        case .alcove: return PuzzleGraph.ZoneID.z4Alcove
        }
    }
}

/// Base SpriteKit scene for a single room view. Renders a full-frame base plate plus
/// zero or more state-driven overlay sprites, exposes hotspot hit-testing, and routes
/// taps back to a delegate that owns the actual puzzle logic.
///
/// Geometry note (QA fix pass): the 2:1 master plates (2560x1280) and the scene
/// (2732x1366) share the same aspect ratio by construction (style guide Section 8), so
/// the base plate is always rendered at exactly the scene's size. Normalized plate
/// coordinates therefore map 1:1 onto normalized SCENE coordinates — always, regardless
/// of how the scene is fitted into the SKView. hotspot layout never depends on whether a
/// texture actually loaded (QA-BUG-022 follow-up hardening: a missing texture must never
/// kill input).
///
/// Presentation (build 9 follow-up): the scene is `.aspectFit` in the SKView, so on iPad
/// the full 2:1 plate is LETTERBOXED (dark bars top+bottom) rather than cropped. SpriteKit
/// owns the scene→view transform (scale + centering + letterbox offset), so scene-space
/// coordinates — hotspots, overlays, and `touch.location(in: self)` — are unaffected by the
/// letterbox: a touch is converted view→scene by UIKit/SpriteKit before hit-testing. The
/// letterbox math only matters OUTSIDE the app (the UI-test `sceneCoordinate` that syntheses
/// a view-space tap from a plate-normalized point must use the same min-scale fit).
final class RoomScene: SKScene {
    let viewID: ViewID
    private(set) var hotspots: [Hotspot] = []
    private var hotspotNodes: [String: SKShapeNode] = [:]
    private let baseNode = SKSpriteNode()
    private var overlayNodes: [String: SKSpriteNode] = [:]

    /// Called on tap inside a hotspot. The only scene input gesture: the select-then-
    /// tap interaction model (feedback round 1) removed drag-to-use entirely, so an
    /// armed inventory item is applied by tapping its target hotspot like any look.
    var onHotspotTap: ((String) -> Void)?

    /// Build 10 (cluster F, R4-005): a tap on EMPTY scene space (no hotspot). The
    /// coordinator uses it to disarm the armed inventory item — "tap away to deselect"
    /// — one of the three always-available disarm affordances.
    var onEmptyTap: (() -> Void)?

    init(viewID: ViewID, size: CGSize) {
        self.viewID = viewID
        super.init(size: size)
        // BUILD 10 — `.aspectFill` RESTORED (the interim build-9 letterbox is removed).
        // The Asset agent re-framed every wide plate into the §8 iPad-4:3 ∩ iPhone-19.5:9
        // dual-safe band (asset-manifest build10_reframe), so under `.aspectFill` (cover)
        // every puzzle-critical element is inside both devices' crops — nothing is cut off,
        // and the scene fills the whole screen edge-to-edge with no dark bars. Hotspot rects
        // are remapped by the same re-frame transform (see Reframe / RoomSceneCoordinator).
        //
        // The scene size stays 2732×1366 (2:1); `.aspectFill` scales it to COVER the SKView
        // (max ratio), cropping the overscan band that lies outside the dual-safe zone. The
        // UI-test `sceneCoordinate` mirror uses the SAME max-scale cover math. The BUG-004
        // guard (`testCriticalHotspotsInsideDualSafeZone`) asserts no critical element leaves
        // the dual-safe band, so a future framing regression fails loudly.
        scaleMode = .aspectFill
        backgroundColor = SKColor(red: 0x10/255.0, green: 0x10/255.0, blue: 0x10/255.0, alpha: 1)
        anchorPoint = CGPoint(x: 0.5, y: 0.5)
        baseNode.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        baseNode.zPosition = 0
        addChild(baseNode)
    }

    required init?(coder aDecoder: NSCoder) { fatalError("init(coder:) not used") }

    func setBaseTexture(_ named: String) {
        baseNode.texture = Self.texture(named: named)
        // Plates are authored 2:1 to match the 2:1 scene exactly (Section 8); always
        // fill the scene so plate-normalized coordinates == scene-normalized coordinates.
        // The scene keeps this fixed 2732×1366 size; `.aspectFit` (build 9 follow-up)
        // fits the whole scene into the SKView (letterboxed on iPad). Nothing here needs a
        // runtime resize — the plate always fills the SCENE; the SKView fit is separate.
        baseNode.size = size
    }

    /// Loose game-art files (base plates, overlays, sprites) are not in the Xcode asset
    /// catalog (see GameAssetLoader doc comment) — resolve via the on-disk index.
    /// Textures are cached: RoomScene state refreshes re-request the same names often
    /// and a full 2560x1280 JPEG decode per refresh causes visible hitches (QA perf note).
    static func texture(named: String) -> SKTexture? {
        if let cached = textureCache.object(forKey: named as NSString) { return cached }
        guard let image = GameAssetLoader.shared.image(named: named) else { return nil }
        let texture = SKTexture(image: image)
        textureCache.setObject(texture, forKey: named as NSString)
        return texture
    }

    private static let textureCache = NSCache<NSString, SKTexture>()

    /// `zPosition` (build 10, cluster B): with independent per-element overlays, two
    /// overlays can OVERLAP (cellar beam × shelf × mirror), and sibling order — set by
    /// node-CREATION order, i.e. the order states happened to change in — is not a correct
    /// stacking rule. Callers with overlapping overlays pass an explicit, state-derived
    /// zPosition (see refreshCellar); non-overlapping overlays keep the default 10.
    func setOverlay(_ key: String, imageNamed: String?, rectNormalized: CGRect,
                    zPosition: CGFloat = 10) {
        if let imageNamed, rectNormalized != .zero {
            let node = overlayNodes[key] ?? {
                let n = SKSpriteNode()
                n.anchorPoint = CGPoint(x: 0, y: 1) // top-left origin to match normalized rects
                addChild(n)
                overlayNodes[key] = n
                return n
            }()
            node.zPosition = zPosition
            node.texture = Self.overlayTexture(named: imageNamed, rectNormalized: rectNormalized)
            positionOverlay(node, rectNormalized: rectNormalized)
        } else {
            overlayNodes[key]?.removeFromParent()
            overlayNodes[key] = nil
        }
    }

    /// Overlay-specific texture path: same cache/loader as `texture(named:)`, plus an
    /// edge feather. Overlays are rectangular crops re-encoded from state-variant
    /// plates; lighting can differ slightly between a variant plate and the base
    /// (e.g. the cabinet moonbeam haze around ov-adrawer-open), so a hard crop edge
    /// renders as a visible straight-edge seam (QA re-QA observation 2, 2026-07-06).
    /// Feathering the outer 12 px of alpha turns that 1-px step into a soft ramp.
    ///
    /// - Only INTERIOR crop edges are feathered: an edge that lies on the plate
    ///   boundary (e.g. the rug/vines/cab-open overlays reach y = 1.0) must stay fully
    ///   opaque, or the base plate would ghost through at the screen edge.
    /// - Safe by construction: the asset pipeline pads every overlay crop by 12 px
    ///   beyond its changed-pixel region (diff -> threshold -> open -> pad(12)), so no
    ///   actual state content lives in the feathered band.
    /// - Base plates are NEVER feathered; only this overlay path applies it.
    /// - Known residual (flagged, not fixable here): ov-adrawer-open's variant plate
    ///   has a regionally different haze rendering, so a softened tonal patch remains
    ///   after feathering; full removal needs an overlay re-cut (Asset Gen).
    static func overlayTexture(named: String, rectNormalized: CGRect) -> SKTexture? {
        let eps: CGFloat = 0.002
        let feather = FeatherEdges(left: rectNormalized.minX > eps,
                                   right: rectNormalized.maxX < 1 - eps,
                                   top: rectNormalized.minY > eps,
                                   bottom: rectNormalized.maxY < 1 - eps)
        let cacheKey = "feathered:\(named):\(feather.cacheSuffix)" as NSString
        if let cached = textureCache.object(forKey: cacheKey) { return cached }
        guard let image = GameAssetLoader.shared.image(named: named) else { return nil }
        let texture = SKTexture(image: featheredImage(image, edges: feather))
        textureCache.setObject(texture, forKey: cacheKey)
        return texture
    }

    struct FeatherEdges {
        let left: Bool, right: Bool, top: Bool, bottom: Bool
        var any: Bool { left || right || top || bottom }
        var cacheSuffix: String { "\(left ? 1 : 0)\(right ? 1 : 0)\(top ? 1 : 0)\(bottom ? 1 : 0)" }
    }

    // (UIKit is unconditionally available on this iOS-only target — GameAssetLoader
    // already imports it at the top level; no platform conditional needed here.)
    private static func featheredImage(_ image: UIImage, edges: FeatherEdges,
                                       feather: CGFloat = 12) -> UIImage {
        let size = image.size
        guard edges.any, size.width > feather * 4, size.height > feather * 4 else { return image }
        let format = UIGraphicsImageRendererFormat()
        format.scale = image.scale
        format.opaque = false
        return UIGraphicsImageRenderer(size: size, format: format).image { ctx in
            image.draw(in: CGRect(origin: .zero, size: size))
            let cg = ctx.cgContext
            cg.setBlendMode(.destinationIn) // resulting alpha = existing alpha * drawn alpha
            let colors = [UIColor(white: 1, alpha: 0).cgColor,
                          UIColor(white: 1, alpha: 1).cgColor] as CFArray
            guard let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                            colors: colors, locations: [0, 1]) else { return }
            // options == [] -> only the start...end band is composited; everything
            // outside it is untouched (stays fully opaque). Corners multiply out to
            // alphaX * alphaY across the two passes per axis.
            func ramp(from start: CGPoint, to end: CGPoint) {
                cg.drawLinearGradient(gradient, start: start, end: end, options: [])
            }
            if edges.left { ramp(from: CGPoint(x: 0, y: 0), to: CGPoint(x: feather, y: 0)) }
            if edges.right { ramp(from: CGPoint(x: size.width, y: 0), to: CGPoint(x: size.width - feather, y: 0)) }
            if edges.top { ramp(from: CGPoint(x: 0, y: 0), to: CGPoint(x: 0, y: feather)) }
            if edges.bottom { ramp(from: CGPoint(x: 0, y: size.height), to: CGPoint(x: 0, y: size.height - feather)) }
        }
    }

    private func positionOverlay(_ node: SKSpriteNode, rectNormalized: CGRect) {
        let baseSize = size
        let originX = -baseSize.width / 2
        let originY = baseSize.height / 2
        node.position = CGPoint(x: originX + rectNormalized.minX * baseSize.width,
                                 y: originY - rectNormalized.minY * baseSize.height)
        node.size = CGSize(width: rectNormalized.width * baseSize.width,
                            height: rectNormalized.height * baseSize.height)
    }

    /// Hotspots are plate-normalized against the fixed 2732×1366 scene. Under `.aspectFit`
    /// (build 9 follow-up letterbox), SpriteKit maps scene coordinates onto the SKView
    /// uniformly (scale + letterbox offset), and a real touch is converted view→scene before
    /// hit-testing, so these centers stay pixel-accurate to the art on every device — the
    /// letterbox does not shift where a hotspot sits ON the plate.
    func configureHotspots(_ hotspots: [Hotspot]) {
        for node in hotspotNodes.values { node.removeFromParent() }
        hotspotNodes.removeAll()
        self.hotspots = hotspots
        let baseSize = size
        for hotspot in hotspots {
            let rect = hotspot.normalizedRect
            let w = max(rect.width * baseSize.width, hotspot.minHitSize)
            let h = max(rect.height * baseSize.height, hotspot.minHitSize)
            let node = SKShapeNode(rectOf: CGSize(width: w, height: h))
            node.fillColor = .clear
            node.strokeColor = .clear
            node.name = "hotspot:\(hotspot.id)"
            let originX = -baseSize.width / 2
            let originY = baseSize.height / 2
            let cx = originX + (rect.minX + rect.width / 2) * baseSize.width
            let cy = originY - (rect.minY + rect.height / 2) * baseSize.height
            node.position = CGPoint(x: cx, y: cy)
            node.zPosition = 100
            addChild(node)
            hotspotNodes[hotspot.id] = node
        }
    }

    // MARK: - Touch handling (tap-based)

    #if canImport(UIKit)
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        guard let touch = touches.first else { return }
        let point = touch.location(in: self)
        if let hotspotID = hotspotID(at: point) {
            flashTapFeedback(at: point)
            onHotspotTap?(hotspotID)
        } else {
            flashTapFeedback(at: point)
            onEmptyTap?() // cluster F: tap-away disarms (no sound — visual pulse only)
        }
    }
    #endif

    /// Test seam (R3-005 player-style verification): resolve a NORMALIZED plate point
    /// (0…1, top-left origin — the coordinate a human "sees") to the hotspot id that a tap
    /// there would trigger, applying the exact same node hit-test + smallest-area-wins rule
    /// as a real touch. Lets unit tests assert that tapping where an element VISUALLY sits
    /// hits the right hotspot (and that empty space hits nothing), without a live SKView.
    func hotspotIDAtNormalized(_ nx: CGFloat, _ ny: CGFloat) -> String? {
        let p = CGPoint(x: -size.width / 2 + nx * size.width,
                        y: size.height / 2 - ny * size.height)
        return hotspotID(at: p)
    }

    /// Smallest-area hotspot wins where hotspots overlap (e.g. the star keyhole and
    /// feed cup sit inside the larger cage region; the trapdoor sits inside the rug).
    private func hotspotID(at point: CGPoint) -> String? {
        var best: (id: String, area: CGFloat)?
        for node in nodes(at: point) {
            guard let name = node.name, name.hasPrefix("hotspot:") else { continue }
            let id = String(name.dropFirst("hotspot:".count))
            let area = node.frame.width * node.frame.height
            if best == nil || area < best!.area {
                best = (id, area)
            }
        }
        return best?.id
    }

    /// Soft radial parchment-white pulse (~12pt, 150ms) — the only unsolicited tap
    /// feedback per style guide Section 7.
    private func flashTapFeedback(at point: CGPoint) {
        let pulse = SKShapeNode(circleOfRadius: 12)
        pulse.fillColor = SKColor(white: 0.98, alpha: 0.55)
        pulse.strokeColor = .clear
        pulse.position = point
        pulse.zPosition = 1000
        addChild(pulse)
        let scaleUp = SKAction.scale(to: 1.8, duration: 0.15)
        let fade = SKAction.fadeOut(withDuration: 0.15)
        pulse.run(.sequence([.group([scaleUp, fade]), .removeFromParent()]))
    }

}
