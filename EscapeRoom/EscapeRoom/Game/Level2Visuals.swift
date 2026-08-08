import CoreGraphics
import Foundation

/// Level 2 view identity. Raw values match the asset manifest view directories. RoomScene
/// only stores this as an opaque name; base textures/overlays are set explicitly by the
/// Level 2 coordinator, so these raw values never collide with L1's ViewID.
enum L2ViewID: String, CaseIterable {
    case bench = "v-bench"          // z1
    case master = "v-master"        // z1
    case door = "v-door"            // z1
    case frame = "v-frame"          // z2
    case clockrow = "v-clockrow"    // z2
    case dial = "v-dial"            // z3
    case vault = "v-vault"          // z4

    var zoneID: String {
        switch self {
        case .bench, .master, .door: return Level2Graph.ZoneID.z1Attic
        case .frame, .clockrow: return Level2Graph.ZoneID.z2Workroom
        case .dial: return Level2Graph.ZoneID.z3BehindDial
        case .vault: return Level2Graph.ZoneID.z4Vault
        }
    }

    /// The base plate texture name for this view (from the staged Level-2 wides).
    var baseTexture: String {
        switch self {
        case .bench: return "z1-bench-base"
        case .master: return "z1-master-base"
        case .door: return "z1-door-base"
        case .frame: return "z2-frame-base"
        case .clockrow: return "z2-clockrow-base"
        case .dial: return "z3-dial-base"
        case .vault: return "z4-vault-base"
        }
    }
}

/// Views per zone in presentation order (mirrors puzzle-graph.json zones[].views).
enum Level2Views {
    static let byZone: [String: [L2ViewID]] = [
        Level2Graph.ZoneID.z1Attic: [.bench, .master, .door],
        Level2Graph.ZoneID.z2Workroom: [.frame, .clockrow],
        Level2Graph.ZoneID.z3BehindDial: [.dial],
        Level2Graph.ZoneID.z4Vault: [.vault],
    ]
}

/// Loads the four Level-2 state-overlay JSONs (staged into GameAssets/level-2/) and exposes
/// each overlay's normalized placement rect on its WIDE plate and/or its CLOSE-UP plate.
/// Rects are stored as pixel corner boxes [x0,y0,x1,y1]: wide at 3840x1920, CU at 2048x1536
/// (the canonical @3x plate dims — normalized coords are scale-independent for rendering).
final class Level2OverlayCatalog {
    static let shared = Level2OverlayCatalog()

    private static let wideW: CGFloat = 3840, wideH: CGFloat = 1920
    private static let cuW: CGFloat = 2048, cuH: CGFloat = 1536

    private var wideRects: [String: CGRect] = [:]
    private var cuRects: [String: CGRect] = [:]
    private var stackedOver: [String: String] = [:]

    private init() {
        for zone in ["z1", "z2", "z3", "z4"] {
            load("\(zone)-state-overlays")
        }
        // R8-011(1): the cat facial keys (mouse-tell eyes / slow-blink / tail flick) live in
        // their own rect file with the same schema. `tail_rect_3x` is registered under
        // "<key>-tail" so the two-patch tell (eyes + tail) can be composited independently.
        load("z1-cat-face")
    }

    private func load(_ resource: String) {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json", subdirectory: "GameAssets/level-2")
            ?? Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: [String: Any]] else { return }
        for (key, entry) in raw {
            if let box = Self.doubles(entry["wide_rect_3x"]), box.count == 4 {
                wideRects[key] = Self.norm(box, Self.wideW, Self.wideH)
            }
            if let cuBox = Self.doubles(entry["rect_3x"]) ?? Self.doubles(entry["cu_rect_3x"]), cuBox.count == 4 {
                cuRects[key] = Self.norm(cuBox, Self.cuW, Self.cuH)
            }
            if let tailBox = Self.doubles(entry["tail_rect_3x"]), tailBox.count == 4 {
                cuRects[key + "-tail"] = Self.norm(tailBox, Self.cuW, Self.cuH)
            }
            if let under = entry["composites_over"] as? String { stackedOver[key] = under }
        }
    }

    /// JSON numeric arrays bridge as [NSNumber]/[Any]; coerce to [Double] robustly.
    private static func doubles(_ any: Any?) -> [Double]? {
        guard let arr = any as? [Any] else { return nil }
        let ds = arr.compactMap { ($0 as? NSNumber)?.doubleValue }
        return ds.count == arr.count ? ds : nil
    }

    private static func norm(_ box: [Double], _ w: CGFloat, _ h: CGFloat) -> CGRect {
        CGRect(x: box[0] / w, y: box[1] / h, width: (box[2] - box[0]) / w, height: (box[3] - box[1]) / h)
    }

    func wideRect(_ overlay: String) -> CGRect { wideRects[overlay] ?? .zero }
    func cuRect(_ overlay: String) -> CGRect { cuRects[overlay] ?? .zero }

    /// Overlay keys that must composite ON TOP of another overlay at the same/overlapping
    /// rect (`composites_over` in the JSON). Order is load-bearing for those pairs.
    func compositesOver(_ overlay: String) -> String? { stackedOver[overlay] }
}

/// BUILD 17 (R8-020, user ruling at GATE 1) — the AUTHORED z3 clockwork sprite rigs.
///
/// Build 16 drew the great-dial hands as SwiftUI capsules and the pendulum as an SKShapeNode
/// rod + bob. That was a documented choice, but on device it read as placeholder strokes and
/// a flat mustard bob in a painterly room, and the hands did not pivot from the dial hub. The
/// user ruled: use the authored sprite art (z3/v-dial/sprites) and anchor it on the authored
/// pivots. So the geometry is READ FROM THE SAME METADATA THE ART WAS CUT AGAINST
/// (`hand-sprites.json` + `clockwork-sprites.json`, staged into the bundle) rather than
/// hand-transcribed into Swift, which is how the build-16 rects drifted from the plate in the
/// first place (the R7-001 / stale-rect family).
final class Level2SpriteCatalog {
    static let shared = Level2SpriteCatalog()

    /// @3x wide-plate reference the sprite rig pixel values are authored against.
    static let wideRef = CGSize(width: 3840, height: 1920)
    /// Canonical close-up plate size.
    static let cuRef = CGSize(width: 2048, height: 1536)

    /// One clock hand. `pivot` and `size` are in the SPRITE's own pixels; `length` is the
    /// tip-to-pivot distance in @3x wide-plate pixels (the two coincide — the sprites are cut
    /// at wide-plate scale).
    struct Hand: Equatable {
        let image: String
        let size: CGSize
        let pivot: CGPoint
        let length: CGFloat
        /// The pivot as a UnitPoint inside the sprite (SwiftUI rotation/scale anchor).
        var anchor: CGPoint {
            CGPoint(x: size.width > 0 ? pivot.x / size.width : 0.5,
                    y: size.height > 0 ? pivot.y / size.height : 0.5)
        }
    }

    /// The great dial's rig, projected into CLOSE-UP plate space (`cu-great-dial`).
    struct DialRig: Equatable {
        /// Hub (the works arbor the hands turn on), normalized to the CU plate.
        let hub: CGPoint
        /// Scale from @3x wide-plate pixels to CU pixels (the CU is a crop + resample).
        let cuScale: CGFloat
        /// Horizontal squash that makes a circular sweep track the painted numeral ellipse.
        let ringSquashX: CGFloat
    }

    struct Pendulum: Equatable {
        let image: String
        /// Sprite rect on the WIDE plate, normalized.
        let rect: CGRect
        /// Pivot inside that rect, normalized (0…1, top-left origin).
        let pivot: CGPoint
        let weakDegrees: CGFloat
        let fullDegrees: CGFloat
    }

    private(set) var hourHand = Hand(image: "hand-hour", size: CGSize(width: 120, height: 380),
                                     pivot: CGPoint(x: 60, y: 290), length: 250)
    private(set) var minuteHand = Hand(image: "hand-minute", size: CGSize(width: 120, height: 510),
                                       pivot: CGPoint(x: 60, y: 420), length: 380)
    private(set) var dial = DialRig(hub: CGPoint(x: 0.3667, y: 0.4543),
                                    cuScale: 1.2075, ringSquashX: 0.875)
    private(set) var pendulum = Pendulum(image: "sp-pendulum",
                                         rect: CGRect(x: 2050/3840.0, y: 0,
                                                      width: 284/3840.0, height: 1440/1920.0),
                                         pivot: CGPoint(x: 136/284.0, y: 8/1440.0),
                                         weakDegrees: 4, fullDegrees: 11)

    private init() {
        loadHands()
        loadClockwork()
    }

    private func json(_ resource: String) -> [String: Any]? {
        guard let url = Bundle.main.url(forResource: resource, withExtension: "json",
                                        subdirectory: "GameAssets/level-2")
                ?? Bundle.main.url(forResource: resource, withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return nil }
        return raw
    }

    private static func point(_ any: Any?) -> CGPoint? {
        guard let a = any as? [Any], a.count == 2,
              let x = (a[0] as? NSNumber)?.doubleValue, let y = (a[1] as? NSNumber)?.doubleValue
        else { return nil }
        return CGPoint(x: x, y: y)
    }
    private static func box(_ any: Any?) -> [CGFloat]? {
        guard let a = any as? [Any], a.count == 4 else { return nil }
        let d = a.compactMap { ($0 as? NSNumber).map { CGFloat($0.doubleValue) } }
        return d.count == 4 ? d : nil
    }

    private func loadHands() {
        guard let raw = json("hand-sprites") else { return }
        func hand(_ key: String, image: String, fallback: Hand) -> Hand {
            guard let e = raw[key] as? [String: Any], let pivot = Self.point(e["pivot_px_at_3x"]),
                  let len = (e["length_px_at_3x"] as? NSNumber)?.doubleValue,
                  let art = GameAssetLoader.shared.image(named: image)
            else { return fallback }
            return Hand(image: image,
                        size: CGSize(width: art.size.width * art.scale,
                                     height: art.size.height * art.scale),
                        pivot: pivot, length: CGFloat(len))
        }
        hourHand = hand("hand-hour", image: "hand-hour", fallback: hourHand)
        minuteHand = hand("hand-minute", image: "hand-minute", fallback: minuteHand)

        guard let g = raw["great-dial"] as? [String: Any], let hub = Self.point(g["hub_px_at_3x"]),
              let frame = Self.box(g["cu_frame_3x"]), frame[2] > frame[0] else { return }
        let scale = Self.cuRef.width / (frame[2] - frame[0])
        let hubCU = CGPoint(x: (hub.x - frame[0]) * scale, y: (hub.y - frame[1]) * scale)
        var squash: CGFloat = 1
        if let axes = Self.point(g["ring_semi_axes_px_at_3x"]), axes.y > 0 {
            // The painted numeral ring is an ELLIPSE (the dial is seen slightly off-axis), so a
            // rigid circular sweep would drift off the numerals. Squashing the rotated hand by
            // the ring's own axis ratio keeps a hand tip on its numeral all the way round.
            squash = max(0.5, min(1.0, axes.x / axes.y))
        }
        dial = DialRig(hub: CGPoint(x: hubCU.x / Self.cuRef.width, y: hubCU.y / Self.cuRef.height),
                       cuScale: scale, ringSquashX: squash)
    }

    private func loadClockwork() {
        guard let raw = json("clockwork-sprites"),
              let e = raw["sp-pendulum"] as? [String: Any],
              let rect = Self.box(e["rect_3x"]), let local = Self.point(e["pivot_px_local"]),
              rect[2] > rect[0], rect[3] > rect[1] else { return }
        let w = rect[2] - rect[0], h = rect[3] - rect[1]
        var weak: CGFloat = pendulum.weakDegrees, full: CGFloat = pendulum.fullDegrees
        if let amps = e["amplitudes_deg"] as? [String: Any] {
            weak = (amps["weak"] as? NSNumber).map { CGFloat($0.doubleValue) } ?? weak
            full = (amps["full"] as? NSNumber).map { CGFloat($0.doubleValue) } ?? full
        }
        pendulum = Pendulum(image: "sp-pendulum",
                            rect: CGRect(x: rect[0] / Self.wideRef.width,
                                         y: rect[1] / Self.wideRef.height,
                                         width: w / Self.wideRef.width,
                                         height: h / Self.wideRef.height),
                            pivot: CGPoint(x: local.x / w, y: local.y / h),
                            weakDegrees: weak, fullDegrees: full)
    }
}

/// State -> visual resolvers for Level 2: base texture selection, the active WIDE overlay
/// list per view, taken-state derivations, and manual-pickup availability. Every value is a
/// pure function of latched state (never event order), the visual analogue of Level2Engine.
enum Level2Visuals {

    // MARK: - Taken / opened derivations

    static func screwdriverTaken(_ s: GameState) -> Bool {
        s.hasItem(Level2Graph.ItemID.screwdriver)
            || s.hasSolved(Level2Graph.PuzzleID.cacheDormer)
            || s.hasSolved(Level2Graph.PuzzleID.cacheChimney)
    }
    static func tileTaken(_ id: String, socket: String, _ s: GameState) -> Bool {
        s.hasItem(id) || s.data.l2DialSockets[socket] == id || s.hasSolved(Level2Graph.PuzzleID.dialDoor)
    }
    static func watchATaken(_ s: GameState) -> Bool { s.hasItem(Level2Graph.ItemID.watchA) }
    static func tileIVTaken(_ s: GameState) -> Bool { tileTaken(Level2Graph.ItemID.tileIV, socket: "4", s) }
    static func tileIITaken(_ s: GameState) -> Bool { tileTaken(Level2Graph.ItemID.tileII, socket: "2", s) }
    static func tileVIITaken(_ s: GameState) -> Bool { tileTaken(Level2Graph.ItemID.tileVII, socket: "7", s) }
    static func tileXITaken(_ s: GameState) -> Bool { tileTaken(Level2Graph.ItemID.tileXI, socket: "11", s) }

    static func mouseTaken(_ s: GameState) -> Bool {
        s.hasItem(Level2Graph.ItemID.toyMouse) || s.hasSolved(Level2Graph.PuzzleID.catMouse)
    }
    static func watchBTaken(_ s: GameState) -> Bool {
        s.hasItem(Level2Graph.ItemID.watchB) || s.hasSolved(Level2Graph.PuzzleID.cacheChimney)
            || s.hasSolved(Level2Graph.PuzzleID.gearTrain)
    }
    static func windingKeyTaken(_ s: GameState) -> Bool {
        s.hasItem(Level2Graph.ItemID.windingKey) || s.hasSolved(Level2Graph.PuzzleID.oilWind)
    }
    static func returnTagTaken(_ s: GameState) -> Bool { s.hasItem(Level2Graph.ItemID.returnTag) }

    /// A rack gear is absent (removed to a post) iff it is currently mounted on either post.
    static func gearMounted(_ gearValue: String, _ s: GameState) -> Bool {
        s.data.l2GearPostA == gearValue || s.data.l2GearPostB == gearValue
    }

    // MARK: - z3 dial mechanism motion (M3: pendulum swing + D11 alive-wrong-time ambient)

    /// Pure, order-free descriptor of what the z3 v-dial mechanism should be DOING, derived
    /// entirely from latched flags (never event order) — the presentation analogue of the
    /// engine's timelock inputs. The coordinator turns this into SpriteKit motion + audio.
    ///
    /// - `pendulumSwinging`: p10 pushed. The ONLY on-screen confirmation p10 succeeded (m2).
    /// - `pendulumFullSwing`: wound (fuller amplitude) vs weak swing when unwound (graph
    ///   "weakly if unwound, fully once wound").
    /// - `aliveWrongTime`: D11 — wound AND swinging AND NOT at release. Drives the soft
    ///   escapement-tick loop + occasional hammer twitch (M3). Stops the instant the strike
    ///   fires (door-bar latched) or any input drops. Never new state.
    struct DialMechanism: Equatable {
        let pendulumSwinging: Bool
        let pendulumFullSwing: Bool
        let aliveWrongTime: Bool
    }

    static func dialMechanism(_ s: GameState) -> DialMechanism {
        DialMechanism(
            pendulumSwinging: s.hasFlag(Level2Graph.Flag.pendulumRunning),
            pendulumFullSwing: s.hasFlag(Level2Graph.Flag.clockWound),
            aliveWrongTime: Level2Engine.isAliveWrongTime(s))
    }

    // MARK: - Base texture

    static func baseTexture(_ view: L2ViewID, _ s: GameState) -> String {
        if view == .door && s.isComplete { return "z1-door-win-open" }
        return view.baseTexture
    }

    // MARK: - Active WIDE overlays, returned as BASE overlay keys (the JSON keys, no -wide
    // suffix). The coordinator resolves each to its `<key>-wide` image (the only staged
    // variant) and its Level2OverlayCatalog wide rect (keyed by the base name). One stable
    // base + independent per-element overlays — never a full-plate swap.

    static func wideOverlays(_ view: L2ViewID, _ s: GameState) -> [String] {
        switch view {
        case .bench:
            var out: [String] = []
            if screwdriverTaken(s) { out.append("ov-screwdriver-taken") }
            if tileIITaken(s) { out.append("ov-stove-tile-taken") }
            return out
        case .master:
            var out: [String] = []
            for (socket, ov) in [("2", "ov-dial-seat-ii"), ("4", "ov-dial-seat-iv"),
                                 ("7", "ov-dial-seat-vii"), ("11", "ov-dial-seat-xi")] {
                if s.data.l2DialSockets[socket] != nil || s.hasSolved(Level2Graph.PuzzleID.dialDoor) {
                    out.append(ov)
                }
            }
            if tileVIITaken(s) { out.append("ov-crate-tile-taken") }
            if s.hasSolved(Level2Graph.PuzzleID.dialDoor) { out.append("ov-workroom-door-open") }
            return out
        case .door:
            var out: [String] = []
            if tileXITaken(s) { out.append("ov-sill-tile-taken") }
            // REV 1.4.1 / D12(2) C2 — the clockmaker's CHALK NOTE on the cache board (hub dot +
            // bearing hand + ⌂), composited once watch A has been read. Appended BEFORE the
            // pried/empty pair, which shares its exact rect: the authored order is
            // marked -> pried -> empty, so even if the visibility predicate were ever loosened
            // the pried board would still paint over the note rather than the other way round.
            if Level2Engine.isDormerCacheNoteVisible(s) { out.append("ov-cache-marked") }
            if s.hasSolved(Level2Graph.PuzzleID.cacheDormer) {
                out.append(Level2Engine.isGreatWheelUncollected(s) ? "ov-cache-pried-wheel" : "ov-cache-empty")
            }
            if s.hasSolved(Level2Graph.PuzzleID.catMouse) {
                // R8-013: the cat-vacated cushion sits DOWN until the player lifts it; only
                // then does the reveal (cushion tipped up, watch B on the bench) composite —
                // and it composites OVER the empty base, per the overlay JSON's contract.
                out.append("ov-cushion-empty")
                if Level2Engine.isWatchBUncollected(s) { out.append("ov-cushion-reveal") }
            }
            if s.hasFlag(Level2Graph.Flag.doorBarRaised) { out.append("ov-bar-raised") }
            return out
        case .frame:
            var out: [String] = []
            if s.hasFlag(Level2Graph.Flag.arborFreed) { out.append("ov-arbor-oiled") }
            for g in Level2Graph.rackGears where gearMounted(g, s) { out.append("ov-rack-absent-\(g)") }
            if s.hasSolved(Level2Graph.PuzzleID.cacheChimney) {
                out.append(Level2Engine.isOilcanUncollected(s) ? "ov-brick-pried-oilcan" : "ov-brick-empty")
            }
            if s.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial) { out.append("ov-panel-open") }
            return out
        case .clockrow:
            if s.hasFlag(Level2Graph.Flag.cabinetDrawerOpened) || mouseTaken(s) {
                return [mouseTaken(s) ? "ov-cabinet-empty" : "ov-cabinet-open-mouse"]
            }
            return []
        case .dial:
            var out: [String] = []
            if s.hasFlag(Level2Graph.Flag.drumOiled) { out.append("ov-drum-oiled") }
            if s.hasFlag(Level2Graph.Flag.clockWound) { out.append("ov-drum-key-in") }
            if s.isZoneUnlocked(Level2Graph.ZoneID.z4Vault) { out.append("ov-hatch-open") }
            return out
        case .vault:
            var out: [String] = []
            if windingKeyTaken(s) { out.append("ov-key-taken") }
            if returnTagTaken(s) { out.append("ov-tag-taken") }
            return out
        }
    }
}
