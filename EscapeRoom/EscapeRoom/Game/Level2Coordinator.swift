import SpriteKit
import Combine

/// The close-up / inspection layer for Level 2. Interactive close-ups drive Level2Engine
/// through the coordinator so all state logic stays in one place (same pattern as L1).
enum L2CloseUp: Equatable, Identifiable {
    case plain(image: String)   // plain state-resolved zoom
    case dialDoor               // p01 interactive tile seating
    case gearFrame              // p06 interactive gear mount + crank
    case vaultWheels            // p07 four-wheel hatch
    case greatDial              // p09 setting crank (mirrored back view; self-satisfies clu-mirrored)
    case windingDrum            // p08 oil + wind (armed-item targets inside the CU)
    case dormerCache            // p03 pry / manual great-wheel pickup
    case chimneyCache           // p04 pry / manual oil-can pickup
    case catCushion             // p02 cat + cushion reveal
    case coat                   // bench coat: manual watch-A + tile-IV pickups (two pockets)

    var id: String {
        switch self {
        case .plain(let i): return "plain-\(i)"
        case .dialDoor: return "dial-door"
        case .gearFrame: return "gear-frame"
        case .vaultWheels: return "vault-wheels"
        case .greatDial: return "great-dial"
        case .windingDrum: return "winding-drum"
        case .dormerCache: return "dormer-cache"
        case .chimneyCache: return "chimney-cache"
        case .catCushion: return "cat-cushion"
        case .coat: return "coat"
        }
    }
}

/// Wires a RoomScene for a given L2ViewID to GameState + Level2Engine: builds hotspots,
/// resolves textures/overlays from state, and dispatches taps (look vs armed-item use).
/// Reuses the shared RoomScene / Hotspot / InteractionModel infrastructure verbatim.
final class Level2Coordinator: ObservableObject {
    let viewID: L2ViewID
    let scene: RoomScene
    let state: GameState
    let interaction: InteractionModel?
    weak var skView: SKView?
    private var cancellable: AnyCancellable?

    @Published var activeCloseUp: L2CloseUp?
    private(set) var closeUpOrigin: String?
    /// Transient cat-response beat for the D3 tell / generic refusal (auto-clears).
    @Published var catResponse: String?

    var onNavigate: ((L2ViewID) -> Void)?

    init(viewID: L2ViewID, state: GameState, size: CGSize, interaction: InteractionModel? = nil) {
        self.viewID = viewID
        self.state = state
        self.interaction = interaction
        self.scene = RoomScene(sceneName: viewID.rawValue, size: size)
        configure()
        scene.onHotspotTap = { [weak self] id in self?.handleTap(id) }
        scene.onEmptyTap = { [weak self] in self?.interaction?.disarm() }
        cancellable = state.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    // MARK: - Setup / refresh

    private func configure() {
        scene.setBaseTexture(Level2Visuals.baseTexture(viewID, state))
        scene.configureHotspots(hotspots(for: viewID))
        refresh()
    }

    func refresh() {
        scene.setBaseTexture(Level2Visuals.baseTexture(viewID, state))
        // Clear every previously-composited overlay for this view, then re-add the active
        // set — one stable base + independent per-element overlays (never a full-plate swap).
        for name in allOverlayNames(viewID) {
            scene.setOverlay(name, imageNamed: nil, rectNormalized: .zero)
        }
        var z: CGFloat = 10
        for key in Level2Visuals.wideOverlays(viewID, state) {
            let rect = Level2OverlayCatalog.shared.wideRect(key)
            guard rect != .zero else { continue }
            // The only staged overlay variant is the wide crop <key>-wide; the rect is keyed
            // by the base name. Use the base key as the node key so refresh can clear it.
            scene.setOverlay(key, imageNamed: key + "-wide", rectNormalized: rect, zPosition: z)
            z += 1
        }
        if viewID == .dial { updateDialMechanismAnimations() }
    }

    /// M3 / m2: drives the z3 pendulum swing (visible p10 confirmation) and the D11
    /// alive-wrong-time ambient (soft escapement tick + occasional hammer twitch, NEVER a
    /// strike). Pure function of latched state via Level2Visuals.dialMechanism, so it is
    /// order-free and idempotent (the scene guards against restarting a running animation).
    private func updateDialMechanismAnimations() {
        let m = Level2Visuals.dialMechanism(state)
        let pendRect = Level2OverlayCatalog.shared.wideRect("ov-pendulum-absent")
        if m.pendulumSwinging, pendRect != .zero {
            // Dark column background hides the at-rest pendulum on the base plate, then the
            // procedural bob swings over it (weak when unwound, fuller once wound).
            scene.setOverlay("ov-pendulum-absent", imageNamed: "ov-pendulum-absent-wide",
                             rectNormalized: pendRect, zPosition: 15)
            scene.setPendulumSwing(active: true, rect: pendRect,
                                   amplitudeDegrees: m.pendulumFullSwing ? 11 : 5,
                                   period: m.pendulumFullSwing ? 1.6 : 2.3)
        } else {
            scene.setOverlay("ov-pendulum-absent", imageNamed: nil, rectNormalized: .zero)
            scene.setPendulumSwing(active: false, rect: .zero, amplitudeDegrees: 0, period: 1)
        }
        let hamRect = Level2OverlayCatalog.shared.wideRect("ov-hammer-absent")
        if m.aliveWrongTime, hamRect != .zero {
            scene.setOverlay("ov-hammer-absent", imageNamed: "ov-hammer-absent-wide",
                             rectNormalized: hamRect, zPosition: 15)
            scene.setHammerTwitch(active: true, rect: hamRect) { SoundManager.shared.play(.tick) }
        } else {
            scene.setOverlay("ov-hammer-absent", imageNamed: nil, rectNormalized: .zero)
            scene.setHammerTwitch(active: false, rect: .zero, onTick: nil)
        }
    }

    private func allOverlayNames(_ view: L2ViewID) -> [String] {
        // Superset of every overlay (BASE keys) any state could show in this view, so refresh
        // clears stale ones. nil-image setOverlay just removes the node.
        switch view {
        case .bench: return ["ov-screwdriver-taken", "ov-stove-tile-taken"]
        case .master: return ["ov-dial-seat-ii", "ov-dial-seat-iv", "ov-dial-seat-vii",
                              "ov-dial-seat-xi", "ov-crate-tile-taken", "ov-workroom-door-open"]
        case .door: return ["ov-sill-tile-taken", "ov-cache-pried-wheel", "ov-cache-empty",
                            "ov-cushion-reveal", "ov-cushion-empty", "ov-bar-raised"]
        case .frame: return ["ov-arbor-oiled", "ov-brick-pried-oilcan", "ov-brick-empty",
                             "ov-panel-open"] + Level2Graph.rackGears.map { "ov-rack-absent-\($0)" }
        case .clockrow: return ["ov-cabinet-open-mouse", "ov-cabinet-empty"]
        case .dial: return ["ov-drum-oiled", "ov-drum-key-in", "ov-hatch-open"]
        case .vault: return ["ov-key-taken", "ov-tag-taken"]
        }
    }

    // MARK: - Hotspots (normalized to the wide plate; anchored on overlay rects where known,
    // otherwise estimated — flagged for QA hit-target recalibration, the L1 R3-005 process).

    private func hotspots(for view: L2ViewID) -> [Hotspot] {
        switch view {
        case .bench:
            return [
                Hotspot(id: "screwdriver", 0.255, 0.229, 0.094, 0.349),
                Hotspot(id: "stove", 0.63, 0.70, 0.18, 0.16),
                Hotspot(id: "coat", 0.03, 0.26, 0.17, 0.42),
                Hotspot(id: "slate", 0.35, 0.28, 0.22, 0.32),
                Hotspot(id: "barometer", 0.80, 0.18, 0.15, 0.26),
            ]
        case .master:
            return [
                Hotspot(id: "master-clock", 0.06, 0.08, 0.22, 0.74),
                Hotspot(id: "door-dial", 0.52, 0.16, 0.26, 0.60),
                Hotspot(id: "crate", 0.66, 0.78, 0.16, 0.20),
            ]
        case .door:
            return [
                Hotspot(id: "stair-door", 0.14, 0.30, 0.30, 0.46),
                Hotspot(id: "house-ring", 0.52, 0.28, 0.12, 0.16),
                Hotspot(id: "sill", 0.60, 0.46, 0.12, 0.18),
                // m4: extended bottom 0.77 -> 0.81 so the ov-cushion-reveal band (watch B on
                // the bench, y up to 0.807) is fully tappable.
                Hotspot(id: "cat-cushion", 0.66, 0.55, 0.24, 0.26),
                Hotspot(id: "cat-floor", 0.62, 0.78, 0.22, 0.14),
                // M1: re-anchored ON the cache/great-wheel art it reveals — the ov-cache-*
                // wide rect (x0.6375-0.7656, y0.898-1.0). The old x[0.40,0.60] rect did NOT
                // overlap the cache art (zero horizontal overlap), so a human tapping the
                // visible pried board/wheel missed the cache entirely. Now overlay-anchored
                // like every other L2 hotspot; the minHitSize floor expands the small rect
                // upward for a comfortable target above the inventory pill.
                Hotspot(id: "floor-cache", 0.6375, 0.898, 0.1281, 0.102),
            ]
        case .frame:
            return [
                Hotspot(id: "gear-frame", 0.20, 0.26, 0.34, 0.48),
                Hotspot(id: "arbor", 0.15, 0.44, 0.14, 0.22),
                Hotspot(id: "gear-rack", 0.54, 0.52, 0.22, 0.28),
                Hotspot(id: "brick", 0.65, 0.48, 0.16, 0.22),
                Hotspot(id: "panel", 0.19, 0.72, 0.26, 0.26),
            ]
        case .clockrow:
            return [
                Hotspot(id: "clockrow", 0.06, 0.26, 0.48, 0.34),
                Hotspot(id: "cabinet", 0.58, 0.66, 0.18, 0.24),
                Hotspot(id: "display-case", 0.76, 0.28, 0.20, 0.38),
            ]
        case .dial:
            return [
                // m5: notched the dial's right edge 0.62 -> 0.50 so it no longer overlaps the
                // pendulum column (art band x[0.529,0.594]); the pendulum now owns its column
                // unambiguously rather than relying only on smallest-area-wins.
                Hotspot(id: "great-dial", 0.28, 0.16, 0.22, 0.48),
                Hotspot(id: "drum", 0.08, 0.66, 0.18, 0.28),
                Hotspot(id: "pendulum", 0.50, 0.10, 0.12, 0.62),
                Hotspot(id: "hatch", 0.60, 0.72, 0.28, 0.24),
            ]
        case .vault:
            // m3: both anchored to their ov-*-taken wide rects so the key-hook no longer
            // overlaps the tag art edge (old key x[0.23,0.37] covered the tag's right edge).
            // key-hook <- ov-key-taken (x0.2604-0.3268), tag-nail <- ov-tag-taken (x0.1563-0.2526).
            return [
                Hotspot(id: "key-hook", 0.2604, 0.2161, 0.0664, 0.2839),
                Hotspot(id: "tag-nail", 0.1563, 0.2214, 0.0964, 0.2839),
                Hotspot(id: "shelf", 0.54, 0.28, 0.32, 0.42),
                Hotspot(id: "vault-exit", 0.85, 0.20, 0.13, 0.60),
            ]
        }
    }

    // MARK: - Close-up presentation + clue recording

    private func present(_ request: L2CloseUp, from origin: String?) {
        // D6 stale re-evaluation on close-up entry.
        switch request {
        case .vaultWheels:
            Level2Engine.reevaluateVaultOnCloseUpEntry(state: state)
            if state.hasSolved(Level2Graph.PuzzleID.vaultWheels) { onNavigate?(.vault); return }
        case .greatDial:
            _ = Level2Engine.evaluateTimelock(state: state)
        default: break
        }
        activeCloseUp = request
        closeUpOrigin = origin
        recordClueViewed(request.id)
    }

    func dismissCloseUp() { activeCloseUp = nil; closeUpOrigin = nil }

    /// Records the F-012-style substrate id AND any gating clue this view satisfies.
    func recordClueViewed(_ viewID: String) {
        state.markClueViewed(viewID)
        for clueID in Self.gatingClues(for: viewID) { state.markClueViewed(clueID) }
    }

    /// Close-up id -> gating clue ids it reveals (self-satisfying clues + scene clue plates).
    static func gatingClues(for viewID: String) -> [String] {
        switch viewID {
        case "plain-cu-master-face": return [Level2ClueID.masterTime]
        case "plain-cu-clockrow-plates": return [Level2ClueID.worldClockRow]
        case "great-dial": return [Level2ClueID.mirroredNumerals]     // self-satisfying (D1)
        case "plain-cu-slate": return [Level2ClueID.slateRatio]
        case "plain-cu-house-ring": return [Level2ClueID.ringDormer]
        case "plain-cu-gear-ring": return [Level2ClueID.ringChimney]
        default: return []
        }
    }

    // MARK: - Tap routing

    private func handleTap(_ hotspotID: String) {
        if let armed = interaction?.armedItem {
            if useItem(armed, on: hotspotID) { interaction?.disarm() } else { lookTap(hotspotID) }
            return
        }
        lookTap(hotspotID)
    }

    private func lookTap(_ hotspotID: String) {
        switch (viewID, hotspotID) {

        // z1 v-bench
        case (.bench, "screwdriver"):
            if !Level2Visuals.screwdriverTaken(state) {
                state.addItem(Level2Graph.ItemID.screwdriver); SoundManager.shared.play(.pickup)
            }
        case (.bench, "stove"):
            if !Level2Visuals.tileIITaken(state) {
                state.addItem(Level2Graph.ItemID.tileII); SoundManager.shared.play(.pickup)
            } else { present(.plain(image: "cu-stove-hob"), from: hotspotID) }
        case (.bench, "coat"):
            // Two independent manual pickups in one close-up (watch A + tile IV). Prior build
            // presented a PLAIN image with no collect affordance, so tile IV / watch A were
            // uncollectable through the UI (p01 needs tile IV -> L2 was uncompletable in-app).
            present(.coat, from: hotspotID)
        case (.bench, "slate"): present(.plain(image: "cu-slate"), from: hotspotID)
        case (.bench, "barometer"): present(.plain(image: "cu-barometer"), from: hotspotID)

        // z1 v-master
        case (.master, "master-clock"): present(.plain(image: "cu-master-face"), from: hotspotID)
        case (.master, "door-dial"):
            if state.hasSolved(Level2Graph.PuzzleID.dialDoor) { onNavigate?(.frame) }
            else { present(.dialDoor, from: hotspotID) }
        case (.master, "crate"):
            if !Level2Visuals.tileVIITaken(state) {
                state.addItem(Level2Graph.ItemID.tileVII); SoundManager.shared.play(.pickup)
            } else { present(.plain(image: "cu-crate-straw"), from: hotspotID) }

        // z1 v-door
        case (.door, "stair-door"): stairDoorTap()
        case (.door, "house-ring"): present(.plain(image: "cu-house-ring"), from: hotspotID)
        case (.door, "sill"):
            if !Level2Visuals.tileXITaken(state) {
                state.addItem(Level2Graph.ItemID.tileXI); SoundManager.shared.play(.pickup)
            } else { present(.plain(image: "cu-sill-tile"), from: hotspotID) }
        case (.door, "cat-cushion"), (.door, "cat-floor"): present(.catCushion, from: hotspotID)
        case (.door, "floor-cache"): present(.dormerCache, from: hotspotID)

        // z2 v-frame
        case (.frame, "gear-frame"): present(.gearFrame, from: hotspotID)
        case (.frame, "arbor"): present(.plain(image: "cu-gear-frame"), from: hotspotID)
        case (.frame, "gear-rack"): present(.plain(image: "cu-gear-rack"), from: hotspotID)
        case (.frame, "brick"): present(.chimneyCache, from: hotspotID)
        case (.frame, "panel"):
            if state.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial) { onNavigate?(.dial) }

        // z2 v-clockrow
        case (.clockrow, "clockrow"): present(.plain(image: "cu-clockrow-plates"), from: hotspotID)
        case (.clockrow, "cabinet"): cabinetTap()
        case (.clockrow, "display-case"): present(.plain(image: "cu-display-case"), from: hotspotID)

        // z3 v-dial
        case (.dial, "great-dial"): present(.greatDial, from: hotspotID)
        case (.dial, "drum"): present(.windingDrum, from: hotspotID)
        case (.dial, "pendulum"):
            if Level2Engine.pushPendulum(state: state) { SoundManager.shared.play(.tick) }
        case (.dial, "hatch"):
            if state.isZoneUnlocked(Level2Graph.ZoneID.z4Vault) { onNavigate?(.vault) }
            else { present(.vaultWheels, from: hotspotID) }

        // z4 v-vault
        case (.vault, "key-hook"):
            if !Level2Visuals.windingKeyTaken(state) {
                state.addItem(Level2Graph.ItemID.windingKey); SoundManager.shared.play(.pickup)
            }
        case (.vault, "tag-nail"):
            if !Level2Visuals.returnTagTaken(state) {
                state.addItem(Level2Graph.ItemID.returnTag); SoundManager.shared.play(.pickup)
            } else { present(.plain(image: "cu-tag-nail"), from: hotspotID) }
        case (.vault, "shelf"): present(.plain(image: "cu-shelf"), from: hotspotID)
        case (.vault, "vault-exit"): onNavigate?(.dial)

        default: break
        }
    }

    private func stairDoorTap() {
        if state.hasFlag(Level2Graph.Flag.doorBarRaised) {
            if Level2Engine.openStairDoor(state: state) { SoundManager.shared.play(.door) }
        } else {
            // D8: keyless remote lock — rattles once against the linkage, pointing up the rods.
            present(.plain(image: "cu-timelock"), from: "stair-door")
            SoundManager.shared.play(.tick)
        }
    }

    private func cabinetTap() {
        if !state.hasFlag(Level2Graph.Flag.cabinetDrawerOpened) {
            state.setFlag(Level2Graph.Flag.cabinetDrawerOpened); SoundManager.shared.play(.tick)
        } else if !Level2Visuals.mouseTaken(state) {
            state.addItem(Level2Graph.ItemID.toyMouse); SoundManager.shared.play(.pickup)
        }
    }

    // MARK: - Armed-item use (tool-on-hotspot)

    @discardableResult
    func useItem(_ itemID: String, on hotspotID: String) -> Bool {
        switch (viewID, hotspotID) {
        // Pry caches (the cache close-ups are the tap targets too, but a wide armed pry works).
        case (.door, "floor-cache"):
            if itemID == Level2Graph.ItemID.screwdriver { return pryDormer() }
            return false
        case (.frame, "brick"):
            if itemID == Level2Graph.ItemID.screwdriver { return pryChimney() }
            return false
        // Oil the seized arbor (p05).
        case (.frame, "arbor"), (.frame, "gear-frame"):
            if itemID == Level2Graph.ItemID.oilcan, Level2Engine.oilArbor(state: state) {
                SoundManager.shared.play(.solve); return true
            }
            return false
        // Wind the mouse and set it on the FLOOR near the cat's bench (executes p02).
        case (.door, "cat-floor"):
            if itemID == Level2Graph.ItemID.toyMouse, Level2Engine.placeMouseAtCat(state: state) {
                SoundManager.shared.play(.solve)
                present(.catCushion, from: "cat-floor")   // cushion now liftable; watch B revealed
                return true
            }
            // A non-mouse item on the floor is a reach: generic refusal (returns unspent).
            catResponse = "refusal"; SoundManager.shared.play(.refusal); return true
        // Cat: offering an armed item DIRECTLY to the cat (D3/D4 — never executes p02).
        case (.door, "cat-cushion"):
            let offer = Level2Engine.offerItemToCat(itemID)
            catResponse = offer == .mouseTell ? "mouse-tell" : "refusal"
            SoundManager.shared.play(offer == .mouseTell ? .tick : .refusal)
            return true   // intended in-world reaction; item returns unspent
        default:
            return false
        }
    }

    // MARK: - Close-up interactions (called by the SwiftUI controls)

    func useArmedItemInCloseUp(defaultHotspot: String? = nil) {
        guard let armed = interaction?.armedItem, let origin = defaultHotspot ?? closeUpOrigin else { return }
        if useItem(armed, on: origin) { interaction?.disarm() }
    }

    /// p01: seat a tile from the dial-door close-up.
    func seatDialTile(_ tile: String, socket: String) {
        switch Level2Engine.seatDialTile(tile, socket: socket, state: state) {
        case .seated: SoundManager.shared.play(.seat); interaction?.disarm()
        case .solved:
            SoundManager.shared.play(.door); interaction?.disarm(); dismissCloseUp()
        case .rejected: SoundManager.shared.play(.wrong)
        }
        objectWillChange.send()
    }

    /// p03/p04 pry, routed from the cache close-ups or an armed wide tap.
    @discardableResult func pryDormer() -> Bool { handlePry(Level2Engine.pryDormerBoard(isCorrectSpot: true, state: state), close: .dormerCache) }
    @discardableResult func pryChimney() -> Bool { handlePry(Level2Engine.pryChimneyBrick(isCorrectSpot: true, state: state), close: .chimneyCache) }

    private func handlePry(_ result: Level2Engine.PryResult, close: L2CloseUp) -> Bool {
        switch result {
        case .yielded:
            SoundManager.shared.play(.solve); present(close, from: closeUpOrigin); return true
        case .faintTell:
            SoundManager.shared.play(.creak); return true    // D10 memory hook, no yield
        case .dead:
            return false
        case .alreadyOpen:
            return true
        }
    }

    /// Coat pocket pickups (bench). Each is a plain manual collect: add once, never re-add.
    /// watch A is a clue carrier (never consumed); tile IV feeds the p01 dial.
    func collectCoatWatchA() {
        guard !Level2Visuals.watchATaken(state) else { return }
        state.addItem(Level2Graph.ItemID.watchA); SoundManager.shared.play(.pickup); objectWillChange.send()
    }
    func collectCoatTileIV() {
        guard !Level2Visuals.tileIVTaken(state) else { return }
        state.addItem(Level2Graph.ItemID.tileIV); SoundManager.shared.play(.pickup); objectWillChange.send()
    }

    func collectGreatWheel() {
        if Level2Engine.collectGreatWheel(state) { SoundManager.shared.play(.pickup); objectWillChange.send() }
    }
    func collectOilcan() {
        if Level2Engine.collectOilcan(state) { SoundManager.shared.play(.pickup); objectWillChange.send() }
    }

    /// p06 gear frame.
    func mountGear(_ gear: String, on post: Level2Post) {
        if Level2Engine.mountGear(gear, on: post, state: state) { SoundManager.shared.play(.seat) }
        else { SoundManager.shared.play(.wrong) }
        objectWillChange.send()
    }
    func unmountGear(_ post: Level2Post) { Level2Engine.unmountGear(post, state: state); objectWillChange.send() }
    func crankGearTrain() {
        if Level2Engine.crankGearTrain(state: state) {
            SoundManager.shared.play(.unlock); dismissCloseUp()
        } else { SoundManager.shared.play(.grind) }
        objectWillChange.send()
    }

    /// p07 vault wheels.
    func setVaultWheel(_ index: Int, delta: Int) {
        let current = state.data.l2VaultWheels[index]
        Level2Engine.setVaultWheel(index, value: current + delta, state: state)
        SoundManager.shared.play(.tick)
        if state.hasSolved(Level2Graph.PuzzleID.vaultWheels) { SoundManager.shared.play(.unlock); dismissCloseUp() }
        objectWillChange.send()
    }

    /// p08 winding drum (oil / wind) via armed items in the CU.
    func useOnDrum(_ itemID: String) -> Bool {
        if itemID == Level2Graph.ItemID.oilcan, Level2Engine.oilDrum(state: state) {
            SoundManager.shared.play(.solve); objectWillChange.send(); return true
        }
        if itemID == Level2Graph.ItemID.windingKey {
            if Level2Engine.windDrum(state: state) {
                SoundManager.shared.play(.unlock); objectWillChange.send(); return true
            } else { SoundManager.shared.play(.wrong) }   // oil first / not ready
        }
        return false
    }

    /// p09 setting crank (5-minute detents; front time renders mirrored in the CU).
    func adjustClock(byDetents detents: Int) {
        Level2Engine.adjustClock(byDetents: detents, state: state)
        SoundManager.shared.play(.tick)
        if state.hasFlag(Level2Graph.Flag.doorBarRaised) { SoundManager.shared.play(.chime) }
        objectWillChange.send()
    }

    func exitSingleViewZone(to target: L2ViewID) { onNavigate?(target) }
}
