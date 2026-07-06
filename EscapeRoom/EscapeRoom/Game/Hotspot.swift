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
    /// The smallest supported device is the iPhone SE (3rd gen), whose landscape
    /// .aspectFill scale for this scene is max(667/2732, 375/1366) = 0.2745 pt per
    /// scene px. 44 pt / 0.2745 = 160.3 scene px, rounded up to 168 for margin. Because
    /// the scale is strictly LARGER on every other supported device (iPad 13" = 0.7554),
    /// enforcing the floor at the smallest device's conversion guarantees >= 44 pt
    /// everywhere, in points, without needing a live view to measure ("small physical
    /// objects get invisible hit-area padding rather than upscaled art").
    let minHitSize: CGFloat

    /// 44 pt at the smallest supported iPhone's .aspectFill scale, in scene pixels.
    static let minHitSceneSize: CGFloat = 168

    init(id: String, _ x: CGFloat, _ y: CGFloat, _ w: CGFloat, _ h: CGFloat,
         minHitSize: CGFloat = Hotspot.minHitSceneSize) {
        self.id = id
        self.normalizedRect = CGRect(x: x, y: y, width: w, height: h)
        self.minHitSize = minHitSize
    }
}
