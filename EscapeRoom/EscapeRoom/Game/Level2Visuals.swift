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

    private init() {
        for zone in ["z1", "z2", "z3", "z4"] {
            load("\(zone)-state-overlays")
        }
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
            if s.hasSolved(Level2Graph.PuzzleID.cacheDormer) {
                out.append(Level2Engine.isGreatWheelUncollected(s) ? "ov-cache-pried-wheel" : "ov-cache-empty")
            }
            if s.hasSolved(Level2Graph.PuzzleID.catMouse) {
                out.append(watchBTaken(s) ? "ov-cushion-empty" : "ov-cushion-reveal")
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
