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
}
