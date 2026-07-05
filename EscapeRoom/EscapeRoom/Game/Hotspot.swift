import CoreGraphics

/// A tappable/droppable region within a room view, expressed in NORMALIZED (0...1)
/// coordinates relative to the base plate, so the same hotspot definition works for
/// both the iPad 4:3 crop and the iPhone 19.5:9 band per the style guide's dual-safe-
/// zone rule (puzzle-critical elements sit inside the intersection of both crops).
struct Hotspot: Identifiable {
    let id: String
    let normalizedRect: CGRect
    /// Minimum on-screen hit target, enforced regardless of the visual art's size
    /// (style guide: "small physical objects get invisible hit-area padding rather
    /// than upscaled art"; ≥44pt both devices, larger tolerance on iPhone).
    let minHitSize: CGFloat

    init(id: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat, minHitSize: CGFloat = 44) {
        self.id = id
        self.normalizedRect = CGRect(x: x, y: y, width: w, height: h)
        self.minHitSize = minHitSize
    }
}
