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

    /// An ARMED-ITEM USE target inside a close-up: an on-plate region that proxies a WIDE
    /// hotspot id. ROUND 8 CLUSTER Q (user parity directive): once an interaction's gate is
    /// satisfied it must work from BOTH views, so every close-up declares the wide verbs it
    /// offers instead of hard-coding one hotspot id (build 16's cushion bug) or one item
    /// (build 16's pry-only cache close-ups).
    struct UseTarget: Equatable {
        let id: String        // accessibility identifier, e.g. "use-cat-floor"
        let hotspot: String   // the WIDE hotspot id this region routes to via useItem
        let rect: CGRect      // normalized plate rect (whole plate = the default region)
        let label: String     // VoiceOver label; the art itself is the visible affordance
    }

    /// Everything the host needs to draw a close-up. `focus` is the sub-rect of the plate the
    /// host zooms to (default: the whole plate) — used to make crop-heavy clue plates read.
    struct Plan: Equatable {
        var base: String
        var layers: [Layer] = []
        var targets: [Target] = []
        var uses: [UseTarget] = []
        var focus: CGRect = CGRect(x: 0, y: 0, width: 1, height: 1)
    }

    static let wholePlate = CGRect(x: 0, y: 0, width: 1, height: 1)

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

    // MARK: - Build-17 interaction regions (measured on the shipped close-up plates)

    /// R8-015 / Cluster Q1: the FLOORBOARDS in front of the cat's bench, inside
    /// `cu-cat-cushion`. This is the close-up's proxy for the wide `cat-floor` hotspot — the
    /// hotspot p02's PLACEMENT verb actually lives on. Without it the armed mouse could only
    /// ever be OFFERED from this close-up, and the user had to back out to the wide scene.
    static let catFloorRect = CGRect(x: 190/2048.0, y: 1120/1536.0,
                                     width: 1180/2048.0, height: 380/1536.0)
    /// The cushion/cat band itself (the OFFER region, which yields the D3 tell).
    static let catOfferRect = CGRect(x: 300/2048.0, y: 240/1536.0,
                                     width: 1560/2048.0, height: 620/1536.0)
    /// R8-019: the painted CRANK ARM + handle on `cu-gear-frame`. The build-16 near-wordless
    /// pass put a floating `arrow.triangle.2.circlepath` button here, which reads as a
    /// browser "reload"; the tap target is now the crank art itself.
    static let crankHandleRect = CGRect(x: 8/2048.0, y: 1030/1536.0,
                                        width: 320/2048.0, height: 290/1536.0)
    /// R8-020 sub-item: the painted SETTING CRANK on `cu-great-dial` (the brass arm and knob
    /// below-right of the hub). Replaces the flat white +/- chrome buttons.
    static let dialCrankRect = CGRect(x: 862/2048.0, y: 806/1536.0,
                                      width: 240/2048.0, height: 190/1536.0)
    /// The oiling target on `cu-gear-frame`: the seized arbor bearing (= the ov-arbor-oiled
    /// CU rect), so a player oils exactly what they can see change.
    static var arborRect: CGRect {
        let r = Level2OverlayCatalog.shared.cuRect("ov-arbor-oiled")
        return r != .zero ? r : CGRect(x: 40/2048.0, y: 360/1536.0,
                                       width: 400/2048.0, height: 350/1536.0)
    }

    /// Ring-clue geometry for the wordless pointer annotation (round 8 fix 5; extended to the
    /// WIDE plates by rev 1.4.1 / D12 C1+C3): the engraved 12-notch ring's center + radius on
    /// the plate it is drawn in, normalized to that plate's WIDTH.
    ///
    /// Keys are PLATE names — the two close-up plates (`cu-*`) and, since rev 1.4.1, the two
    /// WIDE base plates (`z1-door-base`, `z2-frame-base`). Same struct, same composite maths,
    /// one lookup: wide and close-up can therefore never disagree about the presence, the hour
    /// or the attitude of a ring hand (the standing parity directive).
    struct RingClue: Equatable {
        let center: CGPoint
        let radiusFracOfWidth: CGFloat
        let hour: Int           // the clock direction the paired watch reads
        let gateClue: String    // only annotated once this clue has been viewed
        /// Art Director's scale factor on the pointer (C1 principle: "a slightly over-scaled
        /// hand is acceptable and preferable to an illegible one"). 1.0 = natural scale.
        let pointerMultiplier: CGFloat

        init(center: CGPoint, radiusFracOfWidth: CGFloat, hour: Int, gateClue: String,
             pointerMultiplier: CGFloat = 1.0) {
            self.center = center
            self.radiusFracOfWidth = radiusFracOfWidth
            self.hour = hour
            self.gateClue = gateClue
            self.pointerMultiplier = pointerMultiplier
        }

        /// Pointer tip distance from the hub, as a fraction of the PLATE WIDTH. This is the
        /// single number `specs/assets/level-2/ring-clue-wide-geometry.json` measures
        /// (`effective_length_px_3x = radius x 0.86 x multiplier`).
        var pointerLengthFracOfWidth: CGFloat {
            radiusFracOfWidth * Level2CloseUpVisuals.ringPointerLengthFraction * pointerMultiplier
        }
        /// Screen-space rotation of the sprite, which is authored pointing UP (12 o'clock).
        /// hour 3 renders exactly horizontal-right, hour 9 exactly horizontal-left — the
        /// attitude the rev-1.4.1 chalk bearing hand on the cache board was laid against.
        var degrees: CGFloat { CGFloat(hour % 12) * 30 }
    }

    static let ringClues: [String: RingClue] = [
        // Close-ups (shipped since round 8).
        "cu-house-ring": RingClue(center: CGPoint(x: 1020/2048.0, y: 770/1536.0),
                                  radiusFracOfWidth: 204/2048.0, hour: 3,
                                  gateClue: Level2ClueID.watchA),
        // REV 1.4.1 approved presentation tweak (Asset-Gen advisory recorded in
        // ring-clue-wide-geometry.json): at the shipped 1.0 multiplier this pointer's tip landed
        // INSIDE the carved gear glyph, so the bearing was hard to read even in the close-up.
        // 1.5 puts the tip out past the notch circle, on the 9-notch, clear of the glyph.
        "cu-gear-ring": RingClue(center: CGPoint(x: 1056/2048.0, y: 571/1536.0),
                                 radiusFracOfWidth: 77/2048.0, hour: 9,
                                 gateClue: Level2ClueID.watchB,
                                 pointerMultiplier: 1.5),

        // REV 1.4.1 / D12 C1 — the z1 WIDE echo. The wide is the ONLY frame that contains both
        // the ⌂ ring and the floorboards, which is why the p03 beat needs it. Measured on the
        // shipped @3x plate: hub (1886.6, 725.7), notch-tip radius 71.7 px; natural scale (the
        // ring is 143 px across in the wide and already reads at room scale).
        "z1-door-base": RingClue(center: CGPoint(x: 0.491302, y: 0.377969),
                                 radiusFracOfWidth: 0.018672, hour: 3,
                                 gateClue: Level2ClueID.watchA,
                                 pointerMultiplier: 1.35),
        // REV 1.4.1 / D12 C3 — the z2 WIDE echo (PARITY ONLY; the chimney brick gets NO chalk
        // mark, A5 = p03-only). Hub (2850.4, 1097.6), radius 21.1 px. SANCTIONED OVER-SCALE:
        // the carve is 42 px across in the wide, so a natural pointer would be ~6 pt and
        // illegible; x2.75 makes it read at room scale and reach toward the brick field its
        // 9-o'clock bearing selects.
        "z2-frame-base": RingClue(center: CGPoint(x: 0.742292, y: 0.571667),
                                  radiusFracOfWidth: 0.005495, hour: 9,
                                  gateClue: Level2ClueID.watchB,
                                  pointerMultiplier: 2.75),
    ]

    /// The WIDE ring-hand entry for a view, if that view's base plate carries one.
    static func wideRingClue(_ view: L2ViewID) -> RingClue? { ringClues[view.baseTexture] }

    /// THE ONE PLACE the ring-hand composite is defined, shared by the SwiftUI close-up path
    /// and the SpriteKit wide path (and asserted by CI without a live scene).
    ///
    /// It reproduces the shipped close-up composite exactly — the maths Asset-Gen rendered its
    /// C1/C3 proof against: the sprite is aspect-FIT into a `0.34L x 1.32L` box whose centre
    /// sits `0.31L` along the pointer from the hub, and the whole thing rotates about the hub.
    ///
    /// - Returns: the drawn art size in the same units as `length`, and the hub's position
    ///   inside that art as a unit anchor in TOP-LEFT-origin (SwiftUI) coordinates. SpriteKit
    ///   callers use `1 - anchor.y`.
    static func ringHandLayout(spritePixelSize sprite: CGSize,
                               length L: CGFloat) -> (size: CGSize, anchor: CGPoint) {
        guard sprite.width > 0, sprite.height > 0, L > 0 else {
            return (.zero, CGPoint(x: 0.5, y: 0.5))
        }
        let box = CGSize(width: 0.34 * L, height: 1.32 * L)
        let k = min(box.width / sprite.width, box.height / sprite.height)
        let size = CGSize(width: sprite.width * k, height: sprite.height * k)
        // The art is offset 0.31L UP the pointer from the hub, so the hub sits 0.31L BELOW the
        // art's centre (top-left-origin y grows downward).
        let anchorY = size.height > 0 ? 0.5 + (0.31 * L) / size.height : 0.5
        return (size, CGPoint(x: 0.5, y: anchorY))
    }

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
        case "cu-sill-tile":
            if Level2Visuals.tileXITaken(s) { append("ov-sill-tile-taken", to: &layers) }
            // CROSS-VIEW ECHO (build 16 gap): this crop's bottom-right corner bakes in the
            // NEIGHBOURING cushion element, so it must echo the cushion's state or the sill
            // plate shows a cat the rest of the game has already removed. Order is load-
            // bearing: the transient lift composites OVER cat-gone at the identical rect
            // (z1-state-overlays "composites_over"), mirroring reveal-over-empty on the
            // cushion CU, so dropping it on pickup restores the flat-cushion corner.
            if s.hasSolved(Level2Graph.PuzzleID.catMouse) { append("ov-sill-cat-gone", to: &layers) }
            if Level2Engine.isWatchBUncollected(s) { append("ov-sill-cushion-lifted", to: &layers) }
        case "cu-timelock":
            if s.hasFlag(Level2Graph.Flag.doorBarRaised) { append("ov-bar-raised", to: &layers) }
        case "cu-gear-rack":
            for g in Level2Graph.rackGears where Level2Visuals.gearMounted(g, s) {
                append("ov-rack-absent-\(g)", to: &layers)
            }
        // z4 — R8-021. Both vault plates are crops of the SAME wall and each depicts BOTH
        // pickups, so each must echo the OTHER element's taken state. Build 16 composited
        // only a plate's own element, which is why re-opening either close-up after
        // collecting both still showed a stale winding key.
        case "cu-key-hook":
            if Level2Visuals.windingKeyTaken(s) { append("ov-key-taken", to: &layers) }
            if Level2Visuals.returnTagTaken(s) { append("ov-keyhook-tag-taken", to: &layers) }
        case "cu-tag-nail":
            if Level2Visuals.returnTagTaken(s) { append("ov-tag-taken", to: &layers) }
            if Level2Visuals.windingKeyTaken(s) { append("ov-tagnail-key-taken", to: &layers) }
        // z1 v-master — both plates look through/at the workroom doorway p01 opens.
        case "cu-master-face":
            if s.hasSolved(Level2Graph.PuzzleID.dialDoor) { append("ov-masterface-door-open", to: &layers) }
        case "cu-crate-straw":
            if Level2Visuals.tileVIITaken(s) { append("ov-crate-tile-taken", to: &layers) }
            if s.hasSolved(Level2Graph.PuzzleID.dialDoor) { append("ov-crate-door-open", to: &layers) }
        // z1 v-door — the ⌂-ring clue post crop includes the stair-door time-lock bar.
        case "cu-house-ring":
            if s.hasFlag(Level2Graph.Flag.doorBarRaised) { append("ov-housering-bar-raised", to: &layers) }
        // z2 v-frame — the ⚙-ring clue plate is cropped off the chimney breast and bakes in
        // the loose cache brick.
        case "cu-gear-ring":
            if s.hasSolved(Level2Graph.PuzzleID.cacheChimney) {
                append(Level2Engine.isOilcanUncollected(s) ? "ov-gearring-brick-pried"
                                                           : "ov-gearring-brick-empty", to: &layers)
            }
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
        // CROSS-ELEMENT ECHO: this crop also shows the cat's bench, so the transient
        // cushion-lift window (watch B revealed) must read here too. Composites OVER
        // ov-cache-cat-gone at the same rect, so dropping it restores the flat cushion.
        if Level2Engine.isWatchBUncollected(s) { append("ov-cache-cushion-lifted", to: &layers) }
        // REV 1.4.1 / D12(2) C2 + RC-6 — the chalk NOTE, the same mark the wide composites, in
        // the frame it is actually tapped in. RC-6: it composites against the INDEPENDENT
        // ov-cache-cat-gone axis above; the two rects are disjoint (cat corner 1499..2048 x
        // 0..555 vs board 1080..2048 x 1150..1536), so their order is free. Ordering with the
        // pried/empty pair below IS load-bearing: same rect, marked -> pried -> empty.
        if Level2Engine.isDormerCacheNoteVisible(s) { append("ov-cache-marked", to: &layers) }
        if s.hasSolved(Level2Graph.PuzzleID.cacheDormer) {
            if Level2Engine.isGreatWheelUncollected(s) {
                append("ov-cache-pried-wheel", to: &layers)
                targets.append(Target(id: "collect-\(Level2Graph.ItemID.greatWheel)",
                                      kind: .collectGreatWheel, rect: greatWheelRect))
            } else {
                append("ov-cache-empty", to: &layers)
            }
        }
        return Plan(base: "cu-floor-cache", layers: layers, targets: targets,
                    uses: [UseTarget(id: "use-floor-cache", hotspot: "floor-cache",
                                     rect: wholePlate, label: "Loose floorboard")])
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
        return Plan(base: "cu-brick-cache", layers: layers, targets: targets,
                    uses: [UseTarget(id: "use-brick", hotspot: "brick",
                                     rect: wholePlate, label: "Loose brick")])
    }

    /// p02 + its yield. THE P0: cat asleep -> cat gone, cushion down (liftable) -> cushion
    /// lifted with watch B revealed -> emptied. Three distinct compositions, one tap each.
    static func catCushionPlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        var targets: [Target] = []
        // CROSS-VIEW ECHO (build 16 gap): the top-left corner of this crop bakes in the dormer
        // SILL, so tile XI must disappear here too once it has been taken. Disjoint rect from
        // every cushion overlay, so it is composited first and order is otherwise irrelevant.
        if Level2Visuals.tileXITaken(s) { append("ov-cushion-sill-taken", to: &layers) }
        // CROSS-ELEMENT ECHO: the bottom of this crop is the dormer floor cache, so it must
        // follow p03's pried/emptied state as well as its own cushion state — and, since rev
        // 1.4.1, its MARKED state too. Without this the cushion close-up would show a bare
        // board while the wide and cu-floor-cache both show a chalked one (the parity hole
        // Asset-Gen found in the cross-view sweep). Same rect, same clu-watch-a gate, same
        // marked -> pried -> empty ordering.
        if Level2Engine.isDormerCacheNoteVisible(s) { append("ov-cushion-cache-marked", to: &layers) }
        if s.hasSolved(Level2Graph.PuzzleID.cacheDormer) {
            append(Level2Engine.isGreatWheelUncollected(s) ? "ov-cushion-cache-pried"
                                                           : "ov-cushion-cache-empty", to: &layers)
        }
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
        // CLUSTER Q1 (R8-015): BOTH p02 verbs are reachable from this close-up — offering the
        // armed item to the cat (the D3 tell, on the cushion) and SETTING it on the floor in
        // front of the bench (the placement that actually solves p02). Build 16 wired only the
        // first, so the mouse could not be placed without backing out to the wide scene.
        let uses = [
            UseTarget(id: "use-cat-floor", hotspot: "cat-floor",
                      rect: catFloorRect, label: "The floor by the bench"),
            UseTarget(id: "use-cat-cushion", hotspot: "cat-cushion",
                      rect: catOfferRect, label: "The cat on its cushion"),
        ]
        return Plan(base: "cu-cat-cushion", layers: layers, targets: targets, uses: uses)
    }

    /// p06: the oiled arbor plus the ACTUAL gear mounted on each post (near-wordless — the
    /// old "Post A"/"Post B" text readouts are gone; the plate shows the gear).
    static func gearFramePlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        if s.hasFlag(Level2Graph.Flag.arborFreed) { append("ov-arbor-oiled", to: &layers) }
        if let a = s.data.l2GearPostA { append("ov-mount-a-\(a)", to: &layers) }
        if let b = s.data.l2GearPostB { append("ov-mount-b-\(b)", to: &layers) }
        // CROSS-ELEMENT ECHO: the opened z3 wall panel is inside this crop.
        if s.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial) {
            append("ov-gearframe-panel-open", to: &layers)
        }
        // PARITY (Cluster Q): p05's oiling verb lives on the wide `arbor` hotspot. The
        // interactive gear-frame close-up had NO plate-tap at all, so an armed oil can was
        // dead here even though it worked from the plain cu-gear-frame close-up and the wide.
        return Plan(base: "cu-gear-frame", layers: layers,
                    uses: [UseTarget(id: "use-arbor", hotspot: "arbor",
                                     rect: arborRect, label: "The seized bearing")])
    }

    /// p08: oiled bearing, then the key seated in the square socket.
    static func windingDrumPlan(_ s: GameState) -> Plan {
        var layers: [Layer] = []
        if s.hasFlag(Level2Graph.Flag.drumOiled) { append("ov-drum-oiled", to: &layers) }
        if s.hasFlag(Level2Graph.Flag.clockWound) { append("ov-drum-key-in", to: &layers) }
        return Plan(base: "cu-winding-drum", layers: layers,
                    uses: [UseTarget(id: "use-drum", hotspot: "drum",
                                     rect: wholePlate, label: "The winding drum")])
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

    // MARK: - Close-up CAMERA FRAMES (the geometry the R8-021 guard gap is closed with)
    //
    // Every L2 close-up plate is a CROP of its wide plate (verified: crop + LANCZOS of the
    // wide reproduces each shipped CU plate to mean |delta| <= 0.2/255). That is why a
    // close-up so often BAKES IN a neighbouring element — and why "resolve only this plate's
    // own element" was a structurally incomplete rule. These are the authored crops
    // (specs/tools/l2_z{1..4}_build.py), normalized to the @3x wide plate, so a test can
    // enumerate every (close-up x foreign wide overlay) pair instead of relying on someone
    // remembering to add a row.
    static let wideRef = CGSize(width: 3840, height: 1920)

    private static func frame(_ x0: CGFloat, _ y0: CGFloat, _ x1: CGFloat, _ y1: CGFloat) -> CGRect {
        CGRect(x: x0 / wideRef.width, y: y0 / wideRef.height,
               width: (x1 - x0) / wideRef.width, height: (y1 - y0) / wideRef.height)
    }

    /// close-up plate name -> (wide view raw value, its camera frame on that wide plate).
    static let cuFrames: [String: (view: String, frame: CGRect)] = [
        "cu-slate": ("v-bench", frame(1230, 300, 2630, 1350)),
        "cu-stove-hob": ("v-bench", frame(2320, 1280, 3160, 1910)),
        "cu-barometer": ("v-bench", frame(940, 0, 1620, 510)),
        "cu-master-face": ("v-master", frame(540, 320, 2500, 1790)),
        "cu-door-dial": ("v-master", frame(1900, 420, 3260, 1440)),
        "cu-crate-straw": ("v-master", frame(2380, 1230, 3300, 1920)),
        "cu-sill-tile": ("v-door", frame(2135, 875, 2855, 1415)),
        "cu-house-ring": ("v-door", frame(1528, 455, 2248, 995)),
        "cu-cat-cushion": ("v-door", frame(2450, 1085, 3410, 1805)),
        "cu-floor-cache": ("v-door", frame(1900, 1140, 2940, 1920)),
        "cu-timelock": ("v-door", frame(620, 420, 1820, 1320)),
        "cu-gear-frame": ("v-frame", frame(660, 660, 2100, 1740)),
        "cu-gear-rack": ("v-frame", frame(1905, 940, 2705, 1540)),
        "cu-gear-ring": ("v-frame", frame(2560, 940, 3120, 1360)),
        "cu-brick-cache": ("v-frame", frame(2470, 935, 3030, 1355)),
        "cu-clockrow-plates": ("v-clockrow", frame(760, 180, 3000, 1860)),
        "cu-cabinet-drawer": ("v-clockrow", frame(2050, 1095, 3150, 1920)),
        "cu-display-case": ("v-clockrow", frame(620, 840, 2060, 1920)),
        "cu-great-dial": ("v-dial", frame(900, 300, 2596, 1572)),
        "cu-winding-drum": ("v-dial", frame(0, 1030, 1187, 1920)),
        "cu-hatch-wheels": ("v-dial", frame(2150, 870, 3550, 1920)),
        "cu-tag-nail": ("v-vault", frame(500, 350, 1400, 1025)),
        "cu-key-hook": ("v-vault", frame(700, 280, 1620, 970)),
        "cu-shelf": ("v-vault", frame(1700, 300, 2980, 1260)),
    ]

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
