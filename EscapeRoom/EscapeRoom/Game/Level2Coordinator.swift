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
    case catCushion             // p02 cat + cushion lift + manual watch-B pickup (R8-013)
    case coat                   // bench coat: manual watch-A + tile-IV pickups (two pockets)
    case cabinetDrawer          // z2 parts cabinet: drawer open -> manual toy-mouse pickup

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
        case .cabinetDrawer: return "cabinet-drawer"
        }
    }
}

/// R8-011(1): the cat's transient reaction to a DIRECT offer (D3/D4). The rev-1.3 mouse-tell
/// shipped sound-only, so a correct idea read as "broken". These drive the VISIBLE facial
/// keys composited onto the cushion close-up (existing `ov-cat-*` art), which is why the
/// coordinator presents that close-up on an offer instead of reacting off-screen.
enum L2CatResponse: String, Equatable {
    case mouseTell      // eyes open + locked gaze + tail flick — "right idea, wrong verb"
    case refusal        // the generic slow blink
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
    /// Transient cat-response beat for the D3 tell / generic refusal. Auto-clears after
    /// `catResponseDuration` so the tell is a beat, never a new latched state (R8-011(1)).
    @Published var catResponse: L2CatResponse?
    static let catResponseDuration: TimeInterval = 2.0
    private var catResponseToken = 0

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
        // BUILD 17 (R8-020): rect + pivot + amplitudes come from the AUTHORED sprite rig, and
        // the absent patch is registered against the SAME rect, so the paint-out can never
        // again miss part of the painted pendulum (the build-16 "double pendulum").
        let rig = Level2SpriteCatalog.shared.pendulum
        let pendRect = Level2OverlayCatalog.shared.wideRect("ov-pendulum-absent")
        if m.pendulumSwinging, pendRect != .zero {
            // Background patch hides the at-rest pendulum on the base plate, then the authored
            // brass cutout swings over it (weak when unwound, fuller once wound).
            scene.setOverlay("ov-pendulum-absent", imageNamed: "ov-pendulum-absent-wide",
                             rectNormalized: pendRect, zPosition: 15)
            scene.setPendulumSwing(active: true, rect: rig.rect, pivot: rig.pivot,
                                   imageNamed: rig.image,
                                   amplitudeDegrees: m.pendulumFullSwing ? rig.fullDegrees
                                                                        : rig.weakDegrees,
                                   period: m.pendulumFullSwing ? 1.6 : 2.3)
        } else {
            scene.setOverlay("ov-pendulum-absent", imageNamed: nil, rectNormalized: .zero)
            scene.setPendulumSwing(active: false, rect: .zero, pivot: .zero, imageNamed: nil,
                                   amplitudeDegrees: 0, period: 1)
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

    // MARK: - Hotspots
    //
    // Every L2 hotspot rect now lives in ONE place — `Level2HotspotTable` (normalized to the
    // wide plate). The coordinator builds its `Hotspot`s from that table, and the on-device UI
    // tests derive their tap coordinates from the SAME table, so a re-anchor can never desync a
    // UI-test tap from the game hotspot again (the build-15 stale-coat-tap gate). See the table
    // file for the per-element R-REANCHOR rationale; the Level2RegistrationTests art-rect +
    // iPad-band guards independently lock every inspect hotspot onto its measured art.

    private func hotspots(for view: L2ViewID) -> [Hotspot] {
        Level2HotspotTable.rects(forView: view.rawValue).map {
            Hotspot(id: $0.id, $0.rect.minX, $0.rect.minY, $0.rect.width, $0.rect.height)
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
        // R8-005(3): this DOES open a clue close-up (the ⌂ ring). Build 15's "nothing happens"
        // was the occluded-chevron/stale-plate cluster, not a dead hotspot.
        case (.door, "house-ring"): present(.plain(image: "cu-house-ring"), from: hotspotID)
        case (.door, "sill"):
            if !Level2Visuals.tileXITaken(state) {
                state.addItem(Level2Graph.ItemID.tileXI); SoundManager.shared.play(.pickup)
            } else { present(.plain(image: "cu-sill-tile"), from: hotspotID) }
        case (.door, "cat-cushion"), (.door, "cat-floor"): present(.catCushion, from: hotspotID)
        case (.door, "floor-cache"): present(.dormerCache, from: hotspotID)

        // z2 v-frame
        case (.frame, "gear-frame"): present(.gearFrame, from: hotspotID)
        // PARITY (Cluster Q): the arbor and the frame are the SAME plate. Build 16 opened a
        // second, PLAIN close-up here whose plan resolved no layers at all — so the oiled
        // bearing (and every mounted gear) was invisible on the very close-up the walkthrough
        // sends you to for p05, and no armed verb was wired on the interactive one. One plate,
        // one close-up, one state resolver.
        case (.frame, "arbor"): present(.gearFrame, from: hotspotID)
        case (.frame, "gear-rack"): present(.plain(image: "cu-gear-rack"), from: hotspotID)
        case (.frame, "brick"): present(.chimneyCache, from: hotspotID)
        // The ⚙+ring12 carve beside the loose cache brick: the p04 clue plate (clu-ring-chimney).
        // Its close-up annotates the IX direction once watch B has been read (ringClues).
        case (.frame, "gear-ring"): present(.plain(image: "cu-gear-ring"), from: hotspotID)
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
            } else {
                // R8-005(3) dead-tap sweep: post-pickup this was silently inert. It now opens
                // the (state-resolved, empty-hook) close-up like every other taken element.
                present(.plain(image: "cu-key-hook"), from: hotspotID)
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

    /// z2 parts cabinet. Pulling the drawer opens the (state-resolved) drawer close-up; the
    /// mouse is then a deliberate tap inside it — the manual-pickup grammar, and the reason
    /// the "mouse in the drawer" state is now visible at all (R8-012 family).
    private func cabinetTap() {
        if !state.hasFlag(Level2Graph.Flag.cabinetDrawerOpened) {
            state.setFlag(Level2Graph.Flag.cabinetDrawerOpened); SoundManager.shared.play(.tick)
        }
        present(.cabinetDrawer, from: "cabinet")
    }

    /// Manual toy-mouse pickup from the opened drawer.
    func collectToyMouse() {
        guard !Level2Visuals.mouseTaken(state) else { return }
        state.addItem(Level2Graph.ItemID.toyMouse)
        SoundManager.shared.play(.pickup)
        objectWillChange.send()
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
                present(.catCushion, from: "cat-floor")   // cat gone; the cushion is now liftable
                return true
            }
            return false        // R8-016: anything but the mouse is INERT here (see below)
        // Cat: offering an armed item DIRECTLY to the cat (D3/D4 — never executes p02).
        //
        // R8-016 (user CONFIRMED override of approved rev-1.3 playtest tweak 2): ONLY the tin
        // mouse gets a reaction. rev-1.3 gave every other item a slow-blink refusal, but on
        // device the two reads were both "the cat opens one eye", so the tell stopped
        // signalling "the mouse is the key". Non-mouse offers are now fully inert — no
        // overlay, no sound, item unspent — and the strong tell is exclusive to the mouse.
        case (.door, "cat-cushion"):
            guard Level2Engine.offerItemToCat(itemID) == .mouseTell else { return false }
            showCatResponse(.mouseTell)
            return true   // intended in-world reaction; item returns unspent
        // p08 drum: oil / wind. PARITY (round-8 Cluster Q): this used to exist ONLY inside the
        // drum close-up, so an armed oil can or key tapped on the drum in the WIDE scene was
        // silently dead. Routing it through useItem gives both views the same verb.
        case (.dial, "drum"):
            return useOnDrum(itemID)
        default:
            return false
        }
    }

    /// R8-011(1): play the cat's reaction as a VISIBLE beat, not just a sound. The tell art
    /// (`ov-cat-mouse-tell` eyes + tail) is authored on the cushion close-up plate, so the
    /// offer opens/keeps that close-up and composites the facial key for
    /// `catResponseDuration`, then clears. No new state, no new art.
    ///
    /// R8-016: only `.mouseTell` ever reaches here now — a non-mouse offer is inert and
    /// `useItem` returns false before calling this. `.refusal` is retained as the engine's
    /// classification (and for the tests that assert the discrimination) but is never
    /// presented.
    func showCatResponse(_ response: L2CatResponse) {
        guard response == .mouseTell else { return }
        catResponse = response
        SoundManager.shared.play(.tick)
        if activeCloseUp != .catCushion { present(.catCushion, from: "cat-cushion") }
        catResponseToken += 1
        let token = catResponseToken
        DispatchQueue.main.asyncAfter(deadline: .now() + Self.catResponseDuration) { [weak self] in
            guard let self, self.catResponseToken == token else { return }
            self.catResponse = nil
        }
    }

    // MARK: - p02 yield: cushion lift + manual watch-B pickup (R8-013)

    /// Lift the cat-vacated cushion, revealing watch B on the bench beneath it.
    func liftCushion() {
        guard Level2Engine.liftCushion(state: state) else { return }
        SoundManager.shared.play(.creak)
        objectWillChange.send()
    }

    /// Collect the revealed watch B (the deliberate second tap).
    func collectWatchB() {
        guard Level2Engine.collectWatchB(state) else { return }
        SoundManager.shared.play(.pickup)
        objectWillChange.send()
    }

    // MARK: - Close-up interactions (called by the SwiftUI controls)

    func useArmedItemInCloseUp(defaultHotspot: String? = nil) {
        guard let armed = interaction?.armedItem, let origin = defaultHotspot ?? closeUpOrigin else { return }
        if useItem(armed, on: origin) { interaction?.disarm() }
    }

    /// ROUND 8 CLUSTER Q — close-up ↔ wide interaction PARITY (user directive, R8-015/R8-018).
    ///
    /// A close-up plan declares the WIDE hotspot ids it proxies as `UseTarget`s, and this is
    /// the single dispatch point for them: the armed item runs through the SAME `useItem`
    /// switch a wide tap uses, so a verb can never exist in one view and not the other again.
    ///
    /// Build 16's failure was structural, not a missing case: the cushion close-up hard-coded
    /// `useItem(armed, on: "cat-cushion")` while p02's PLACEMENT verb lives on the sibling
    /// hotspot `cat-floor`, so from the close-up the armed mouse could only ever produce the
    /// tell — placement was unreachable, which is exactly what cost the user real time.
    @discardableResult
    func runCloseUpUse(_ target: Level2CloseUpVisuals.UseTarget) -> Bool {
        guard let armed = interaction?.armedItem else { return false }
        guard useItem(armed, on: target.hotspot) else { return false }
        interaction?.disarm()
        return true
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

    /// Single dispatch point for every manual-pickup / lift target a close-up plan declares,
    /// so the view layer never re-implements collect semantics per close-up (round 8 Cluster A).
    func runCloseUpTarget(_ target: Level2CloseUpVisuals.Target) {
        switch target.kind {
        case .collectTileIV:     collectCoatTileIV()
        case .collectWatchA:     collectCoatWatchA()
        case .collectGreatWheel: collectGreatWheel()
        case .collectOilcan:     collectOilcan()
        case .collectToyMouse:   collectToyMouse()
        case .liftCushion:       liftCushion()
        case .collectWatchB:     collectWatchB()
        }
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
