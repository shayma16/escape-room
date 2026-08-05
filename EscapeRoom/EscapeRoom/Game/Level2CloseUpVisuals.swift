import CoreGraphics
import Foundation

/// ROUND 8 CLUSTER A — the close-up analogue of `Level2Visuals.wideOverlays`.
///
/// Through build 15 every Level-2 close-up rendered ONE STATIC PLATE per close-up id: the
/// per-element state overlays were composited into the WIDE scene only, so collected coat
/// items persisted, seated dial tiles never appeared, pried caches stayed shut, the placed
/// mouse was invisible and the cushion still showed a departed cat (R8-002/004/009/010/011/
/// 012/013 — the P0). The resolved-state art existed all along; nothing consumed it.
///
/// This type is the single, pure, order-free resolver: `(close-up, GameState) -> Plan`, the
/// exact mirror of the wide path. `L2CloseUpHost` renders the Plan and NOTHING else decides
/// what a close-up shows, so a new stateful close-up cannot silently ship stale again.
/// Being a pure function of latched state (never event order) it is also directly testable —
/// see `Level2CloseUpStateTests`, the CI guard that asserts every stateful close-up's
/// composition CHANGES across its state flip.
enum Level2CloseUpVisuals {

    /// Canonical close-up plate geometry (every cu-*.png is authored at 2048x1536 @3x).
    static let plateSize = CGSize(width: 2048, height: 1536)
    static let plateAspect: CGFloat = 2048.0 / 1536.0

    /// One composited layer over the base plate. `rect` is normalized to the CU plate.
    struct Layer: Equatable {
        let key: String     // overlay key (stable identity; also the accessibility id suffix)
        let image: String   // staged image name (always "<key>-cu")
        let rect: CGRect
    }

    /// A manual-pickup / lift target drawn over the plate (invisible; art shows the item).
    struct Target: Equatable {
        let id: String      // accessibility identifier, e.g. "collect-itm-watch-b"
        let kind: Kind
        let rect: CGRect
        enum Kind: String, Equatable {
            case collectTileIV, collectWatchA
            case collectGreatWheel, collectOilcan, collectToyMouse
            case liftCushion, collectWatchB
        }
    }

    /// Everything the host needs to draw a close-up. `focus` is the sub-rect of the plate the
    /// host zooms to (default: the whole plate) — used to make crop-heavy clue plates read.
    struct Plan: Equatable {
        var base: String
        var layers: [Layer] = []
        var targets: [Target] = []
        var focus: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    // MARK: - Layer helper

    /// Resolve an overlay key to its CU layer. Returns nil if the key has no CU rect (the
    /// wide-only overlays), so a wide-only key can never render at a bogus rect.
    static func layer(_ key: String) -> Layer? {
        let rect = Level2OverlayCatalog.shared.cuRect(key)
        guard rect != .zero else { return nil }
        return Layer(key: key, image: key + "-cu", rect: rect)
    }

    private static func append(_ key: String, to layers: inout [Layer]) {
        if let l = layer(key) { layers.append(l) }
    }

    /// The tail half of the D3 mouse-tell. `z1-cat-face.json` authors it as a SECOND patch on
    /// the same entry (`tail_rect_3x`), registered by the catalog under "<key>-tail", with its
    /// own art file `ov-cat-mouse-tell-tail`. Composited alongside the eye key so the tell
    /// reads as "eyes lock AND the tail flicks" rather than a sound with nothing on screen.
    static func catTailTellLayer() -> Layer? {
        let rect = Level2OverlayCatalog.shared.cuRect("ov-cat-mouse-tell-tail")
        guard rect != .zero else { return nil }
        return Layer(key: "ov-cat-mouse-tell-tail", image: "ov-cat-mouse-tell-tail-cu", rect: rect)
    }

    // MARK: - Pickup / interaction rects (normalized to the 2048x1536 plate)
    //
    // Measured off the shipped overlay art. Each sits ON the element it collects, so a player
    // taps what they SEE (the L1 manual-pickup grammar). The host enforces a 44 pt floor.

    /// Great wheel lying in the pried dormer cavity (inside ov-cache-pried-wheel).
    static let greatWheelRect = CGRect(x: 1140/2048.0, y: 1200/1536.0,
                                       width: 290/2048.0, height: 170/1536.0)
    /// Oil can standing in the pried chimney recess (inside ov-brick-pried-oilcan).
    static let oilcanRect = CGRect(x: 780/2048.0, y: 640/1536.0,
                                   width: 520/2048.0, height: 460/1536.0)
    /// The cushion itself, while it is still down and liftable (post-p02).
    static let cushionLiftRect = CGRect(x: 420/2048.0, y: 520/1536.0,
                                        width: 1440/2048.0, height: 330/1536.0)
    /// Watch B + chain on the bench once the cushion is lifted (inside ov-cushion-reveal).
    static let watchBRect = CGRect(x: 744/2048.0, y: 760/1536.0,
                                   width: 566/2048.0, height: 160/1536.0)
    /// The VI decoy tile lying flat in the door tray (cu-door-dial). Deterministic: this is
    /// exactly where specs/tools/l2_dialfix.py lays the canonical foreshortened tile
    /// (center 1120,1204; ~118x52 after the -5 deg rotate).
    static let trayDecoyRect = CGRect(x: 1061/2048.0, y: 1178/1536.0,
                                      width: 118/2048.0, height: 52/1536.0)

    /// Ring-clue geometry for the wordless pointer annotation (round 8 fix 5): the engraved
    /// 12-notch ring's center + radius on its clue plate, normalized to the plate WIDTH.
    struct RingClue: Equatable {
        let center: CGPoint
        let radiusFracOfWidth: CGFloat
        let hour: Int           // the clock direction the paired watch reads
        let gateClue: String    // only annotated once this clue has been viewed
    }
    static let ringClues: [String: RingClue] = [
        "cu-house-ring": RingClue(center: CGPoint(x: 1020/2048.0, y: 770/1536.0),
                                  radiusFracOfWidth: 204/2048.0, hour: 3,
                                  gateClue: Level2ClueID.watchA),
        "cu-gear-ring": RingClue(center: CGPoint(x: 1056/2048.0, y: 571/1536.0),
                                 radiusFracOfWidth: 77/2048.0, hour: 9,
                                 gateClue: Level2ClueID.watchB),
    ]

    // MARK: - Plans

    static func plan(for closeUp: L2CloseUp, state s: GameState) -> Plan {
        switch closeUp {
        case .plain(let image):   return plainPlan(image, s)
        case .coat:               return coatPlan(s)
        case .dialDoor:           return dialDoorPlan(s)
        case .dormerCache:        return dormerCachePlan(s)
        case .chimneyCache:       return chimneyCachePlan(s)
        case .catCushion:         return catCushionPlan(s)
        case .gearFrame:          return gearFramePlan(s)
        case .windingDrum:        return windingDrumPlan(s)
        case .cabinetDrawer:      return cabinetDrawerPlan(s)
        case .vaultWheels:        return Plan(base: "cu-hatch-wheels")
        case .greatDial:          return Plan(base: "cu-great-dial")
        }
    }

    /// State-resolved plain plates. Every plate whose art depicts a collectable/latching
    /// element resolves its overlay here — the same list the wide path walks.
    static func plainPlan(_ image: String, _ s: GameState) -> Plan {
        var layers: [Layer] = []
        switch image {
        case "cu-stove-hob":
            if Level2Visuals.tileIITaken(s) { append("ov-stove-tile-taken", to: &layers) }
        case "cu-crate-straw":
            if Level2Visuals.tileVIITaken(s) { append("ov-crate-tile-taken", to: &layers) }
        case "cu-sill-tile":
            if Level2Visuals.tileXITaken(s) { append("ov-sill-tile-taken", to: &layers) }
        case "cu-timelock":
            if s.hasFlag(Level2Graph.Flag.doorBarRaised) { append("ov-bar-raised", to: &layers) }
        case "cu-gear-rack":
            for g in Level2Graph.rackGears where Level2Visuals.gearMounted(g, s) {
                append("ov-rack-absent-\(g)", to: &layers)
            }
        case "cu-key-hook":
            if Level2Visuals.windingKeyTaken(s) { append("ov-key-taken", to: &layers) }
        case "cu-tag-nail":
            if Level2Visuals.returnTagTaken(s) { append("ov-tag-taken", to: &layers) }
        default:
            break
        }
        var plan = Plan(base: image, layers: layers)
        // R8-008(2)/(3): the clock-row plate is the p07 clue but its authored crop also
        // carries the display case + cabinet, so the four timezone plates read small. Focus
        // the presentation on the clock band — a deterministic zoom, no new art.
        if image == "cu-clockrow-plates" {
            plan.focus = CGRect(x: 0.02, y: 0.03, width: 0.96, height: 0.52)
        }
        return plan
    }

    /// Bench coat: two independent pockets, each emptying as its item is collected.
    static func coatPlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        var targets: [Target] = []
        if Level2Visuals.tileIVTaken(s) {
            append("ov-coat-tile-taken", to: &layers)
        } else if let r = layer("ov-coat-tile-taken")?.rect {
            targets.append(Target(id: "collect-\(Level2Graph.ItemID.tileIV)", kind: .collectTileIV, rect: r))
        }
        if Level2Visuals.watchATaken(s) {
            append("ov-coat-watch-taken", to: &layers)
        } else if let r = layer("ov-coat-watch-taken")?.rect {
            targets.append(Target(id: "collect-\(Level2Graph.ItemID.watchA)", kind: .collectWatchA, rect: r))
        }
        return Plan(base: "cu-coat-pockets", layers: layers, targets: targets)
    }

    /// p01: each seated socket composites its numeral tile, exactly like the wide dial.
    static func dialDoorPlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        for (socket, key) in [("2", "ov-dial-seat-ii"), ("4", "ov-dial-seat-iv"),
                              ("7", "ov-dial-seat-vii"), ("11", "ov-dial-seat-xi")] {
            if s.data.l2DialSockets[socket] != nil || s.hasSolved(Level2Graph.PuzzleID.dialDoor) {
                append(key, to: &layers)
            }
        }
        return Plan(base: "cu-door-dial", layers: layers)
    }

    /// p03: unpried boards -> pried cavity with the wheel -> empty cavity. Also echoes the
    /// cat-gone state, since this crop overlaps the cushion corner.
    static func dormerCachePlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        var targets: [Target] = []
        if s.hasSolved(Level2Graph.PuzzleID.catMouse) { append("ov-cache-cat-gone", to: &layers) }
        if s.hasSolved(Level2Graph.PuzzleID.cacheDormer) {
            if Level2Engine.isGreatWheelUncollected(s) {
                append("ov-cache-pried-wheel", to: &layers)
                targets.append(Target(id: "collect-\(Level2Graph.ItemID.greatWheel)",
                                      kind: .collectGreatWheel, rect: greatWheelRect))
            } else {
                append("ov-cache-empty", to: &layers)
            }
        }
        return Plan(base: "cu-floor-cache", layers: layers, targets: targets)
    }

    /// p04: identical grammar to p03 on the chimney breast.
    static func chimneyCachePlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        var targets: [Target] = []
        if s.hasSolved(Level2Graph.PuzzleID.cacheChimney) {
            if Level2Engine.isOilcanUncollected(s) {
                append("ov-brick-pried-oilcan", to: &layers)
                targets.append(Target(id: "collect-\(Level2Graph.ItemID.oilcan)",
                                      kind: .collectOilcan, rect: oilcanRect))
            } else {
                append("ov-brick-empty", to: &layers)
            }
        }
        return Plan(base: "cu-brick-cache", layers: layers, targets: targets)
    }

    /// p02 + its yield. THE P0: cat asleep -> cat gone, cushion down (liftable) -> cushion
    /// lifted with watch B revealed -> emptied. Three distinct compositions, one tap each.
    static func catCushionPlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        var targets: [Target] = []
        if s.hasSolved(Level2Graph.PuzzleID.catMouse) {
            append("ov-cushion-empty", to: &layers)
            if Level2Engine.isWatchBUncollected(s) {
                append("ov-cushion-reveal", to: &layers)
                targets.append(Target(id: "collect-\(Level2Graph.ItemID.watchB)",
                                      kind: .collectWatchB, rect: watchBRect))
            } else if Level2Engine.isCushionLiftable(s) {
                targets.append(Target(id: "lift-cushion", kind: .liftCushion, rect: cushionLiftRect))
            }
        }
        return Plan(base: "cu-cat-cushion", layers: layers, targets: targets)
    }

    /// p06: the oiled arbor plus the ACTUAL gear mounted on each post (near-wordless — the
    /// old "Post A"/"Post B" text readouts are gone; the plate shows the gear).
    static func gearFramePlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        if s.hasFlag(Level2Graph.Flag.arborFreed) { append("ov-arbor-oiled", to: &layers) }
        if let a = s.data.l2GearPostA { append("ov-mount-a-\(a)", to: &layers) }
        if let b = s.data.l2GearPostB { append("ov-mount-b-\(b)", to: &layers) }
        return Plan(base: "cu-gear-frame", layers: layers)
    }

    /// p08: oiled bearing, then the key seated in the square socket.
    static func windingDrumPlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        if s.hasFlag(Level2Graph.Flag.drumOiled) { append("ov-drum-oiled", to: &layers) }
        if s.hasFlag(Level2Graph.Flag.clockWound) { append("ov-drum-key-in", to: &layers) }
        return Plan(base: "cu-winding-drum", layers: layers)
    }

    /// z2 parts cabinet: drawer open with the toy mouse -> emptied once taken.
    static func cabinetDrawerPlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        var targets: [Target] = []
        if Level2Visuals.mouseTaken(s) {
            append("ov-cabinet-empty", to: &layers)
        } else if s.hasFlag(Level2Graph.Flag.cabinetDrawerOpened) {
            append("ov-cabinet-open-mouse", to: &layers)
            if let r = layer("ov-cabinet-open-mouse")?.rect {
                targets.append(Target(id: "collect-\(Level2Graph.ItemID.toyMouse)",
                                      kind: .collectToyMouse, rect: r))
            }
        }
        return Plan(base: "cu-cabinet-drawer", layers: layers, targets: targets)
    }

    /// Ring-pointer geometry: where the hour hand's TIP should land for a given ring, as a
    /// fraction of the ring radius (inside the notch circle, unmistakably "this direction").
    static let ringPointerLengthFraction: CGFloat = 0.86

    /// Mount-overlay rect for a post, used by the gear-frame close-up's tap targets so the
    /// post hit region sits exactly on the depicted arbor (44 pt floor applied by the host).
    static func postRect(_ post: Level2Post, gear: String?) -> CGRect {
        let side = post == .a ? "a" : "b"
        // Every mount overlay for a post is concentric; the 48 is a good median footprint
        // for an EMPTY post's hit region.
        let key = "ov-mount-\(side)-\(gear ?? "48")"
        let r = Level2OverlayCatalog.shared.cuRect(key)
        return r != .zero ? r : Level2OverlayCatalog.shared.cuRect("ov-mount-\(side)-48")
    }
}

/// ROUND 8 CLUSTER B — close-up chrome geometry, as pure data so CI can assert it.
///
/// Build 15 padded the close-up dismiss chevron by a flat 12 pt while the inventory pill
/// occupies the bottom 72 pt (iPad) / 62 pt (iPhone) band AND is drawn above the close-up
/// layer (§7-R1.5 / F-020 — the bar must stay live inside close-ups). The chevron was
/// therefore rendered but invisible on EVERY L2 close-up (R8-001/002/004/005/007); players
/// escaped by tapping the backdrop. Level 1 never had this because it insets the chevron by
/// `bottomInset + 10`; this type makes that convention explicit and testable for both levels.
enum L2CloseUpChrome {
    /// §7-R2.4 hit area for the back affordance.
    static let dismissSize = CGSize(width: 88, height: 56)
    /// Clearance between the top of the inventory band and the bottom of the chevron.
    static let gap: CGFloat = 10

    /// The bottom padding the dismiss chevron must use so it clears the inventory bar band.
    static func dismissBottomPadding(barHeight: CGFloat) -> CGFloat { barHeight + gap }

    /// The chevron's on-screen frame (bottom-centered) for a screen of `size`.
    static func dismissFrame(in size: CGSize, barHeight: CGFloat) -> CGRect {
        let padding = dismissBottomPadding(barHeight: barHeight)
        return CGRect(x: (size.width - dismissSize.width) / 2,
                      y: size.height - padding - dismissSize.height,
                      width: dismissSize.width, height: dismissSize.height)
    }

    /// The band the inventory pill occupies along the bottom of the screen.
    static func inventoryBand(in size: CGSize, barHeight: CGFloat) -> CGRect {
        CGRect(x: 0, y: size.height - barHeight, width: size.width, height: barHeight)
    }

    /// iPad / iPhone bar heights (mirrors GameRoomView.barHeight and Level2RoomView.barHeight).
    static let padBarHeight: CGFloat = 72
    static let phoneBarHeight: CGFloat = 62
}
