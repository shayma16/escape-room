import CoreGraphics

/// A tappable/droppable region within a room view, expressed in NORMALIZED (0...1)
/// coordinates relative to the base plate, so the same hotspot definition works for
/// both the iPad 4:3 crop and the iPhone 19.5:9 band per the style guide's dual-safe-
/// zone rule (puzzle-critical elements sit inside the intersection of both crops).
struct Hotspot: Identifiable {
    let id: String
    let normalizedRect: CGRect
    /// Minimum hit target in SCENE PIXELS (scene is 2732x1366, matching the 2:1 master
    /// plates exactly).
    ///
    /// QA-BUG-009 fix: the style guide's floor is >= 44 SCREEN POINTS on both devices.
    /// The smallest supported device is the iPhone SE (3rd gen). The floor is converted at
    /// the smallest per-scene-pixel scale ANY supported device produces, so a hotspot that
    /// clears it there clears >= 44 pt everywhere.
    ///
    /// BUILD 9 LETTERBOX FOLLOW-UP: the scene is now presented `.aspectFit`, whose scale is
    /// the MIN ratio, not the `.aspectFill` MAX. On iPhone SE landscape that is
    /// min(667/2732, 375/1366) = 0.24414 pt per scene px (width-bound), SMALLER than the old
    /// `.aspectFill` 0.27452 (height-bound). 44 pt / 0.24414 = 180.2 scene px, rounded up to
    /// 182 for margin. Every other supported device fits at a LARGER scale (iPad 13":
    /// min(1376/2732, 1032/1366) = 0.50366), so enforcing the floor at iPhone SE's `.aspectFit`
    /// scale still guarantees >= 44 pt everywhere, without a live view ("small physical
    /// objects get invisible hit-area padding rather than upscaled art").
    let minHitSize: CGFloat

    /// 44 pt at the smallest supported iPhone's `.aspectFit` scale (build 9 letterbox),
    /// in scene pixels: 44 / 0.24414 = 180.2, rounded up to 182.
    static let minHitSceneSize: CGFloat = 182

    init(id: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
         minHitSize: CGFloat = Hotspot.minHitSceneSize) {
        self.id = id
        self.normalizedRect = CGRect(x: x, y: y, width: w, height: h)
        self.minHitSize = minHitSize
    }

    /// Returns a copy with its rect mapped by a build-10 re-frame transform (below).
    func reframed(_ t: Reframe.Transform) -> Hotspot {
        let r = t.map(normalizedRect)
        return Hotspot(id: id, r.minX, r.minY, r.width, r.height, minHitSize: minHitSize)
    }
}

/// Build-10 dual-safe re-frame (BUG-004 permanent fix): the Asset agent re-framed every
/// wide plate into the §8 iPad 4:3 dual-safe band via a uniform scale `s` + offset
/// `(ox,oy)` on the 3840×1920 plate (asset-manifest `build10_reframe.transforms`). The
/// element that used to sit at plate-normalized `p` now sits at `p*s + off`. Hotspot rects
/// (and the two hard-coded seated-slot overlay rects) were authored against the OLD framing,
/// so they are remapped by the SAME transform here — a single source of the numbers, applied
/// uniformly, rather than re-typing ~40 literals (the `developer_contract.rect_remap` rule).
/// overlays.json rects are already emitted in re-framed space by the build tool, so they are
/// NOT remapped again in Swift. Close-up plates were NOT re-framed, so CloseUpLayout rects
/// stay as-is.
enum Reframe {
    struct Transform {
        let scale: CGFloat
        let ox: CGFloat   // normalized x offset (px/3840)
        let oy: CGFloat   // normalized y offset (px/1920)
        func map(_ r: CGRect) -> CGRect {
            CGRect(x: r.minX * scale + ox, y: r.minY * scale + oy,
                   width: r.width * scale, height: r.height * scale)
        }
    }

    /// Per-view transforms transcribed from asset-manifest build10_reframe.transforms.
    static func transform(for view: ViewID) -> Transform {
        switch view {
        case .hearth: return Transform(scale: 0.955, ox: 86 / 3840, oy: 86 / 1920)
        case .study:  return Transform(scale: 0.86, ox: 538 / 3840, oy: 240 / 1920)
        case .entry:  return Transform(scale: 0.74, ox: 425 / 3840, oy: 250 / 1920)
        case .bench:  return Transform(scale: 0.83, ox: 430 / 3840, oy: 163 / 1920)
        case .cabinet: return Transform(scale: 0.70, ox: 630 / 3840, oy: 288 / 1920)
        case .cellar: return Transform(scale: 0.82, ox: 445 / 3840, oy: 173 / 1920)
        case .alcove: return Transform(scale: 1.0, ox: 0, oy: 0) // verified in-band as-is
        }
    }

    /// Remap every hotspot in a view's list by that view's transform.
    static func map(_ hotspots: [Hotspot], view: ViewID) -> [Hotspot] {
        let t = transform(for: view)
        return hotspots.map { $0.reframed(t) }
    }

    /// The iPad-4:3 ∩ iPhone-19.5:9 dual-safe band under `.aspectFill` (both device crops),
    /// from asset-manifest build10_reframe.dual_safe_band_at_3x. Every puzzle-critical
    /// element must sit inside this band so `.aspectFill` never crops it off either device.
    static let dualSafeX: ClosedRange<CGFloat> = (640.0 / 3840)...(3200.0 / 3840)   // [0.1667, 0.8333]
    static let dualSafeY: ClosedRange<CGFloat> = (74.0 / 1920)...(1846.0 / 1920)    // [0.0385, 0.9615]
}
