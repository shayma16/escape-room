import CoreGraphics

/// SINGLE SOURCE OF TRUTH for Level-2 hotspot geometry — normalized (0…1, top-left origin)
/// rects on the fixed 2732×1366 wide plate.
///
/// BOTH sides of the L2 tap pipeline read these exact rects:
///   • the GAME — `Level2Coordinator.hotspots(for:)` builds its `Hotspot`s from this table, so
///     these are the rects a real touch hit-tests against; and
///   • the ON-DEVICE UI TESTS — `Level2UITests` derives every scene-tap coordinate from these
///     rect centers via `Level2HotspotTable.center(_:inView:)`.
///
/// That coupling is deliberate. Build-15's TestFlight gate went red because a UI-test tap was
/// hand-coded at the coat's OLD far-left position while commit 203036a had re-anchored the coat
/// hotspot to its actual art on the right — the literal and the hotspot desynced. With both the
/// game and the tests sourced from this one table, re-anchoring an element moves the game
/// hotspot AND the UI-test tap together; a stale-coordinate desync of that class can no longer
/// happen. (The M1/R-REANCHOR registration guards in Level2RegistrationTests independently pin
/// each rect onto its measured art + the iPad dual-safe band.)
///
/// Dependency-free (CoreGraphics only, keyed by the `L2ViewID` raw value string) so it compiles
/// unchanged into the UI-test target, which has no access to the app's game types.
enum Level2HotspotTable {

    /// View raw value ("v-bench" … "v-vault") -> ordered [(hotspot id, normalized rect)].
    /// Order is preserved for readability only; hit-testing is smallest-area-wins, order-free.
    static let rectsByView: [String: [(id: String, rect: CGRect)]] = [
        // z1 — bench
        "v-bench": [
            ("screwdriver", CGRect(x: 0.255, y: 0.229, width: 0.094, height: 0.349)),
            ("stove",       CGRect(x: 0.63,  y: 0.70,  width: 0.18,  height: 0.16)),
            // R-REANCHOR (L2 iPad-uncompletable fix, commit 203036a): the pocketed coat ART hangs
            // on the RIGHT hook (x≈[0.68,0.81], inside the iPad dual-safe band), NOT far-left. The
            // old x[0.03,0.20] rect sat off the iPad edge over an empty beam, so p01's coat close-up
            // (tile IV + watch A pickups) could never be opened on iPad.
            ("coat",        CGRect(x: 0.68,  y: 0.21,  width: 0.13,  height: 0.46)),
            ("slate",       CGRect(x: 0.35,  y: 0.28,  width: 0.22,  height: 0.32)),
            // R-REANCHOR: round barometer gauge sits top-CENTER, not top-right.
            ("barometer",   CGRect(x: 0.28,  y: 0.05,  width: 0.10,  height: 0.18)),
        ],
        // z1 — master
        "v-master": [
            // R-REANCHOR: longcase (grandfather) clock stands center-left.
            ("master-clock", CGRect(x: 0.31, y: 0.15, width: 0.15, height: 0.73)),
            ("door-dial",    CGRect(x: 0.52, y: 0.16, width: 0.26, height: 0.60)),
            ("crate",        CGRect(x: 0.66, y: 0.78, width: 0.16, height: 0.20)),
        ],
        // z1 — door
        "v-door": [
            ("stair-door", CGRect(x: 0.14, y: 0.30, width: 0.30, height: 0.46)),
            // R-REANCHOR: house/ring glyph engraved on the central post.
            ("house-ring", CGRect(x: 0.45, y: 0.32, width: 0.10, height: 0.16)),
            ("sill",       CGRect(x: 0.60, y: 0.46, width: 0.12, height: 0.18)),
            // m4: bottom extended to 0.81 so the ov-cushion-reveal band is fully tappable.
            ("cat-cushion", CGRect(x: 0.66, y: 0.55, width: 0.24, height: 0.26)),
            ("cat-floor",   CGRect(x: 0.62, y: 0.78, width: 0.22, height: 0.14)),
            // M1: anchored ON the ov-cache-* wide rect it reveals.
            ("floor-cache", CGRect(x: 0.6375, y: 0.898, width: 0.1281, height: 0.102)),
        ],
        // z2 — frame
        "v-frame": [
            ("gear-frame", CGRect(x: 0.20, y: 0.26, width: 0.34, height: 0.48)),
            ("arbor",      CGRect(x: 0.15, y: 0.44, width: 0.14, height: 0.22)),
            ("gear-rack",  CGRect(x: 0.54, y: 0.52, width: 0.22, height: 0.28)),
            ("brick",      CGRect(x: 0.65, y: 0.48, width: 0.16, height: 0.22)),
            ("panel",      CGRect(x: 0.19, y: 0.72, width: 0.26, height: 0.26)),
        ],
        // z2 — clockrow
        "v-clockrow": [
            // R-REANCHOR: the four world-clocks span x≈[0.18,0.82].
            ("clockrow",     CGRect(x: 0.18, y: 0.16, width: 0.64, height: 0.42)),
            ("cabinet",      CGRect(x: 0.58, y: 0.66, width: 0.18, height: 0.24)),
            // R-REANCHOR: glass display case sits bottom-LEFT.
            ("display-case", CGRect(x: 0.17, y: 0.62, width: 0.30, height: 0.30)),
        ],
        // z3 — dial
        "v-dial": [
            // m5: right edge notched to 0.50 so it no longer overlaps the pendulum column.
            ("great-dial", CGRect(x: 0.28, y: 0.16, width: 0.22, height: 0.48)),
            ("drum",       CGRect(x: 0.08, y: 0.66, width: 0.18, height: 0.28)),
            ("pendulum",   CGRect(x: 0.50, y: 0.10, width: 0.12, height: 0.62)),
            ("hatch",      CGRect(x: 0.60, y: 0.72, width: 0.28, height: 0.24)),
        ],
        // z4 — vault
        "v-vault": [
            ("key-hook", CGRect(x: 0.2604, y: 0.2161, width: 0.0664, height: 0.2839)),
            ("tag-nail", CGRect(x: 0.1563, y: 0.2214, width: 0.0964, height: 0.2839)),
            ("shelf",    CGRect(x: 0.54,   y: 0.28,   width: 0.32,   height: 0.42)),
            // R-REANCHOR: exit STAIRS climb the center.
            ("vault-exit", CGRect(x: 0.30, y: 0.15, width: 0.18, height: 0.70)),
        ],
    ]

    /// All (id, rect) pairs for a view, in authored order.
    static func rects(forView view: String) -> [(id: String, rect: CGRect)] {
        rectsByView[view] ?? []
    }

    /// The normalized rect for a specific hotspot in a view (nil if unknown).
    static func rect(_ id: String, inView view: String) -> CGRect? {
        rectsByView[view]?.first(where: { $0.id == id })?.rect
    }

    /// The normalized center of a hotspot — the point a UI test should tap.
    static func center(_ id: String, inView view: String) -> CGPoint? {
        guard let r = rect(id, inView: view) else { return nil }
        return CGPoint(x: r.midX, y: r.midY)
    }
}
