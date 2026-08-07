import SwiftUI
import SpriteKit

// MARK: - Session

/// Owns the long-lived GameState + navigation for a Level 2 playthrough. Parallels L1's
/// LevelSession but over L2ViewID; reuses the shared GameState / SaveGameStore / interaction.
final class L2LevelSession: ObservableObject {
    let levelID = 2
    let state: GameState
    let interaction = InteractionModel()
    @Published var currentView: L2ViewID = .bench

    init(store: SaveGameStore = .shared) {
        self.state = GameState(levelID: 2, store: store)
    }

    var viewsInCurrentZone: [L2ViewID] { Level2Views.byZone[currentView.zoneID] ?? [currentView] }
    var hasViewNavigation: Bool { viewsInCurrentZone.count > 1 }

    func goTo(_ view: L2ViewID) {
        guard state.isZoneUnlocked(view.zoneID) else { return }
        currentView = view
    }
    func nextView() {
        let v = viewsInCurrentZone
        guard v.count > 1, let i = v.firstIndex(of: currentView) else { return }
        goTo(v[(i + 1) % v.count])
    }
    func previousView() {
        let v = viewsInCurrentZone
        guard v.count > 1, let i = v.firstIndex(of: currentView) else { return }
        goTo(v[(i - 1 + v.count) % v.count])
    }
    func restartLevel() {
        state.restartLevel()
        interaction.disarm()
        interaction.inspectingItem = nil
        currentView = .bench
    }
}

/// Holds the Level2Coordinator so it can be swapped on view change without StateObject churn.
final class Level2CoordinatorBox: ObservableObject {
    @Published private(set) var coordinator: Level2Coordinator
    private let session: L2LevelSession

    init(session: L2LevelSession) {
        self.session = session
        self.coordinator = Level2Coordinator(viewID: session.currentView, state: session.state,
                                             size: CGSize(width: 2732, height: 1366),
                                             interaction: session.interaction)
        wire(coordinator)
    }
    func setView(_ viewID: L2ViewID, size: CGSize) {
        guard coordinator.viewID != viewID else { return }
        let next = Level2Coordinator(viewID: viewID, state: session.state, size: size,
                                     interaction: session.interaction)
        wire(next)
        coordinator = next
    }
    private func wire(_ c: Level2Coordinator) {
        c.onNavigate = { [weak self] v in self?.session.goTo(v) }
    }
}

/// Presents the coordinator's RoomScene (mirrors SpriteKitContainerView for the L2 type).
struct L2SpriteContainer: UIViewRepresentable {
    @ObservedObject var coordinator: Level2Coordinator
    func makeUIView(context: Context) -> SKView {
        let v = SKView()
        v.ignoresSiblingOrder = true
        v.preferredFramesPerSecond = 30
        v.backgroundColor = UIColor(red: 0x10/255, green: 0x10/255, blue: 0x10/255, alpha: 1)
        v.presentScene(coordinator.scene)
        coordinator.skView = v
        return v
    }
    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== coordinator.scene { uiView.presentScene(coordinator.scene) }
        uiView.preferredFramesPerSecond = coordinator.activeCloseUp == nil ? 30 : 1
        coordinator.skView = uiView
    }
}

// MARK: - Room view

struct Level2RoomView: View {
    @ObservedObject var session: L2LevelSession
    @ObservedObject private var gameState: GameState
    @ObservedObject private var interaction: InteractionModel
    @StateObject private var box: Level2CoordinatorBox
    @State private var showPause = false
    @State private var transitionDip: Double = 0
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @EnvironmentObject private var navigator: AppNavigator

    init(session: L2LevelSession) {
        self.session = session
        self.gameState = session.state
        self.interaction = session.interaction
        _box = StateObject(wrappedValue: Level2CoordinatorBox(session: session))
    }

    private var barHeight: CGFloat { hSizeClass == .regular ? 72 : 62 }

    var body: some View {
        ZStack {
            Chrome.backdrop.ignoresSafeArea()
            L2SpriteContainer(coordinator: box.coordinator)
                .ignoresSafeArea()
                .accessibilityIdentifier("room-scene")

            navigationChevrons
            // The close-up layer sits UNDER the inventory pill (§7-R1.5 / F-020: the bar must
            // stay live inside close-ups) and keeps BOTH its content and its dismiss chevron
            // clear of the bar band — see L2CloseUpChrome (round 8 Cluster B).
            L2CloseUpHost(coordinator: box.coordinator, state: session.state, bottomInset: barHeight)

            VStack { HStack { pauseButton; Spacer() }.padding(24); Spacer() }

            InventoryBarView(state: session.state, interaction: interaction,
                             horizontalSizeClass_isPad: hSizeClass == .regular)

            if let exit = exitTarget {
                L2ZoneExitHost(coordinator: box.coordinator, barHeight: barHeight) {
                    box.coordinator.exitSingleViewZone(to: exit)
                }
            }

            if let inspecting = interaction.inspectingItem {
                ItemInspectView(itemID: inspecting) { interaction.inspectingItem = nil }
            }

            Color.black.opacity(transitionDip).ignoresSafeArea().allowsHitTesting(false)

            if gameState.isComplete {
                L2CompleteOverlay(
                    onMainMenu: { SoundManager.shared.exitLevel(); navigator.popToRoot() },
                    onReplay: { session.restartLevel(); SoundManager.shared.enterLevel(levelID: 2) })
            }
            if showPause {
                PauseMenuView(onRestart: { session.restartLevel() }, isPresented: $showPause)
                    .transition(.opacity)
            }
        }
        .onChange(of: session.currentView) { newView in
            let zoneChanged = box.coordinator.viewID.zoneID != newView.zoneID
            let half = zoneChanged ? 0.3 : 0.15
            withAnimation(.easeIn(duration: half)) { transitionDip = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + half) {
                box.setView(newView, size: CGSize(width: 2732, height: 1366))
                withAnimation(.easeOut(duration: half)) { transitionDip = 0 }
            }
        }
        .onChange(of: interaction.inspectingItem) { item in
            if let item, let clue = Self.inspectClue[item] { session.state.markClueViewed(clue) }
        }
        .onChange(of: gameState.isComplete) { if $0 { SoundManager.shared.exitLevel() } }
        .statusBarHidden(true)
    }

    /// Inspecting a clue-carrier item records its gating clue (D7 substrate).
    static let inspectClue: [String: String] = [
        Level2Graph.ItemID.watchA: Level2ClueID.watchA,
        Level2Graph.ItemID.watchB: Level2ClueID.watchB,
        Level2Graph.ItemID.returnTag: Level2ClueID.returnTag,
    ]

    /// Single-view zones (z3 dial, z4 vault) show a down-chevron back through the diegetic
    /// passage (hatch up / panel back). Multi-view zones use side chevrons.
    private var exitTarget: L2ViewID? {
        switch session.currentView {
        case .dial: return .frame
        case .vault: return .dial
        case .frame, .clockrow: return .master   // back through the workroom door into z1
        default: return nil
        }
    }

    private var pauseButton: some View {
        Button(action: { SoundManager.shared.play(.menuConfirm); showPause = true }) {
            Image("pause-rune").resizable().frame(width: 40, height: 40).opacity(0.4)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityIdentifier("pause-button")
    }

    @ViewBuilder private var navigationChevrons: some View {
        if session.hasViewNavigation {
            HStack {
                NavChevron.sideButton(systemName: "chevron.left", isPad: hSizeClass == .regular) { session.previousView() }
                Spacer()
                NavChevron.sideButton(systemName: "chevron.right", isPad: hSizeClass == .regular) { session.nextView() }
            }
            .padding(.horizontal, 8)
        }
    }
}

/// Down-chevron exit affordance for single-view zones + the z2 back-to-z1 passage.
private struct L2ZoneExitHost: View {
    @ObservedObject var coordinator: Level2Coordinator
    let barHeight: CGFloat
    let onExit: () -> Void
    @Environment(\.horizontalSizeClass) private var hSizeClass
    var body: some View {
        if coordinator.activeCloseUp == nil {
            VStack {
                Spacer()
                HStack {
                    Button(action: onExit) {
                        BreathingChevron(systemName: "chevron.down",
                                         size: NavChevron.glyphSize(isPad: hSizeClass == .regular))
                            .frame(width: 88, height: 56).contentShape(Rectangle())
                    }
                    .accessibilityIdentifier("zone-exit")
                    .padding(.leading, 8).padding(.bottom, barHeight + 12)
                    Spacer()
                }
            }
        }
    }
}

private struct L2CompleteOverlay: View {
    let onMainMenu: () -> Void
    let onReplay: () -> Void
    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 28) {
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 40, weight: .light)).foregroundColor(Chrome.textPrimary)
                    .accessibilityIdentifier("level-complete")
                Button(action: onMainMenu) { Label("Main Menu", systemImage: "house") }
                    .buttonStyle(.chromePrimary).accessibilityIdentifier("complete-main-menu")
                Button(action: onReplay) { Label("Play Again", systemImage: "arrow.clockwise") }
                    .buttonStyle(.chromePrimary).accessibilityIdentifier("complete-replay")
            }
        }
    }
}

// MARK: - Close-up host + controls
//
// ROUND 8 CLUSTERS A/B/C/D. Every close-up now renders through ONE path:
// `Level2CloseUpVisuals.plan(for:state:)` resolves the base plate + its per-element state
// overlays + its manual-pickup targets from GameState (Cluster A — previously the close-ups
// drew a single static plate while only the WIDE scene composited state); `L2Plate` draws
// that plan inside a container whose layout is FULL-SIZE and independent of its conditional
// children (Cluster C — the iPad "plate jumps left, black void on the right" collapse); and
// the dismiss chevron is inset above the inventory band via `L2CloseUpChrome` (Cluster B).

private struct L2CloseUpHost: View {
    @ObservedObject var coordinator: Level2Coordinator
    /// Observed so a state change (pickup, seat, pry, lift) re-evaluates the PLAN and the
    /// close-up re-composites — the missing link behind the whole stale-close-up cluster.
    @ObservedObject var state: GameState
    let bottomInset: CGFloat
    @ObservedObject private var interaction: InteractionModel
    @Environment(\.horizontalSizeClass) private var hSizeClass

    init(coordinator: Level2Coordinator, state: GameState, bottomInset: CGFloat) {
        self.coordinator = coordinator
        self.state = state
        self.bottomInset = bottomInset
        self.interaction = coordinator.interaction ?? InteractionModel()
    }

    var body: some View {
        if let request = coordinator.activeCloseUp {
            ZStack {
                // Scrim = "empty space": tapping it disarms (same grammar as the wide scene).
                // It still dismisses when nothing is armed, but the chevron is now the visible,
                // reliable way out on EVERY close-up.
                Color.black.opacity(0.92).ignoresSafeArea()
                    .onTapGesture {
                        if interaction.armedItem != nil { interaction.disarm() }
                        else { coordinator.dismissCloseUp() }
                    }

                content(request)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .padding(.bottom, bottomInset)

                VStack {
                    Spacer()
                    NavChevron.dismissButton(action: { coordinator.dismissCloseUp() },
                                             isPad: hSizeClass == .regular)
                        .padding(.bottom, L2CloseUpChrome.dismissBottomPadding(barHeight: bottomInset))
                        .accessibilityIdentifier("closeup-dismiss")
                }
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder private func content(_ request: L2CloseUp) -> some View {
        let plan = Level2CloseUpVisuals.plan(for: request, state: state)
        let armed = interaction.armedItem != nil
        switch request {
        case .plain(let image):
            L2PlainCloseUp(coordinator: coordinator, state: state, plan: plan, image: image)
        case .dialDoor:
            L2DialDoorControl(coordinator: coordinator, plan: plan, interaction: interaction)
        case .gearFrame:
            L2GearFrameControl(coordinator: coordinator, state: state, plan: plan, isArmed: armed)
        case .vaultWheels:
            L2VaultWheelControl(coordinator: coordinator, state: state)
        case .greatDial:
            L2GreatDialControl(coordinator: coordinator, state: state, plan: plan)
        case .windingDrum:
            L2Plate(plan: plan, identifier: "winding-drum", isArmed: armed,
                    onUse: { _ = coordinator.runCloseUpUse($0) })
        case .dormerCache:
            L2CacheControl(coordinator: coordinator, plan: plan, kind: .dormer, interaction: interaction)
        case .chimneyCache:
            L2CacheControl(coordinator: coordinator, plan: plan, kind: .chimney, interaction: interaction)
        case .catCushion:
            L2CatCushionView(coordinator: coordinator, state: state, plan: plan, interaction: interaction)
        case .coat:
            L2Plate(plan: plan, identifier: "coat", onTarget: { coordinator.runCloseUpTarget($0) })
        case .cabinetDrawer:
            L2Plate(plan: plan, identifier: "cabinet-drawer", onTarget: { coordinator.runCloseUpTarget($0) })
        }
    }
}

// MARK: - Shared plate renderer (Cluster A compositing + Cluster C stable layout)

/// Draws a `Level2CloseUpVisuals.Plan`: base plate, its state overlays at their authored CU
/// rects, and an invisible >=44 pt tap target per manual-pickup target — plus whatever extra
/// interactive content the caller adds in plate-local coordinates.
///
/// LAYOUT CONTRACT (Cluster C): the ZStack is explicitly framed to the FULL GeometryReader
/// size and carries an always-present `Color.clear` anchor, so removing the last conditional
/// child (e.g. the final coat pocket button) cannot shrink it and re-place the plate
/// top-leading. Every L2 close-up is built on this one container.
private struct L2Plate<Extra: View>: View {
    let plan: Level2CloseUpVisuals.Plan
    /// Armed-item USE regions (round 8 Cluster Q). Supplied by the host so every close-up
    /// routes an armed item through the same `useItem` dispatch a wide tap uses. They only
    /// hit-test while an item IS armed, so an unarmed tap keeps falling through to the
    /// close-up's existing plate/backdrop behaviour (dismiss, disarm).
    let isArmed: Bool
    let onUse: (Level2CloseUpVisuals.UseTarget) -> Void
    /// Debug/diagnostic name for the close-up. Deliberately NOT applied as an
    /// `accessibilityIdentifier` on the container: an identifier on a container turns it into a
    /// single accessibility element and MASKS its children from XCUITest — the documented L1
    /// `LevelCompleteOverlay` trap, and exactly what hid `collect-itm-tile-iv` inside the coat
    /// close-up in full-lane run 31031042901. Close-ups are identified by their leaf controls
    /// (`closeup-dismiss`, `collect-*`, `dial-socket-*`, …), which is what the UI tests query.
    let identifier: String?
    let onPlateTap: (() -> Void)?
    let onTarget: (Level2CloseUpVisuals.Target) -> Void
    let extra: (CGRect) -> Extra

    init(plan: Level2CloseUpVisuals.Plan,
         identifier: String? = nil,
         onPlateTap: (() -> Void)? = nil,
         onTarget: @escaping (Level2CloseUpVisuals.Target) -> Void = { _ in },
         isArmed: Bool = false,
         onUse: @escaping (Level2CloseUpVisuals.UseTarget) -> Void = { _ in },
         @ViewBuilder extra: @escaping (CGRect) -> Extra = { _ in EmptyView() }) {
        self.plan = plan
        self.identifier = identifier
        self.onPlateTap = onPlateTap
        self.onTarget = onTarget
        self.isArmed = isArmed
        self.onUse = onUse
        self.extra = extra
    }

    var body: some View {
        GeometryReader { geo in
            let g = L2PlateGeometry(in: geo.size, focus: plan.focus)
            ZStack(alignment: .topLeading) {
                Color.clear                                  // stable full-size anchor
                // Base plate + its state overlays, clipped to the VISIBLE window. When a plan
                // carries a `focus` zoom (the clock-row clue) the full plate is larger than the
                // window, so this clip is what keeps the un-focused remainder off-screen.
                ZStack(alignment: .topLeading) {
                    Color.clear
                    GameImage(name: plan.base)
                        .aspectRatio(contentMode: .fill)
                        .frame(width: g.plate.width, height: g.plate.height)
                        .accessibilityHidden(true)
                        .position(x: g.plate.midX - g.fitted.minX, y: g.plate.midY - g.fitted.minY)
                    ForEach(plan.layers, id: \.key) { layer in
                        let r = g.sub(layer.rect)
                        GameImage(name: layer.image)
                            .aspectRatio(contentMode: .fill)
                            .frame(width: r.width, height: r.height)
                            .allowsHitTesting(false)
                            .accessibilityHidden(true)
                            .position(x: r.midX - g.fitted.minX, y: r.midY - g.fitted.minY)
                    }
                }
                .frame(width: g.fitted.width, height: g.fitted.height)
                .clipped()
                .position(x: g.fitted.midX, y: g.fitted.midY)
                // ARMED-ITEM USE REGIONS (round 8 Cluster Q). Drawn BELOW the collect targets
                // so a revealed item's pickup always wins where the two overlap, and only
                // hit-testable while something is armed — an unarmed tap must still fall
                // through to the plate/backdrop behaviour the close-up had before.
                ForEach(plan.uses, id: \.id) { use in
                    let r = g.sub(use.rect)
                    Color.white.opacity(0.001)
                        .frame(width: max(r.width, 44), height: max(r.height, 44))
                        .contentShape(Rectangle())
                        .onTapGesture { onUse(use) }
                        .allowsHitTesting(isArmed)
                        .accessibilityLabel(use.label)
                        .accessibilityIdentifier(use.id)
                        .position(x: r.midX, y: r.midY)
                }
                extra(g.plate)
                ForEach(plan.targets, id: \.id) { target in
                    let r = g.sub(target.rect)
                    Color.white.opacity(0.001)
                        .frame(width: max(r.width, 44), height: max(r.height, 44))
                        .contentShape(Rectangle())
                        .onTapGesture { onTarget(target) }
                        .accessibilityLabel(Self.label(for: target))
                        .accessibilityIdentifier(target.id)
                        .position(x: r.midX, y: r.midY)
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .topLeading)
            // A close-up that carries USE regions also absorbs stray plate taps (a no-op),
            // so an unarmed miss near an interactive element does not fall through to the
            // scrim and dismiss the close-up the player is working in.
            .modifier(PlateTapModifier(action: onPlateTap ?? (plan.uses.isEmpty ? nil : {})))
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .padding(24)
    }

    private static func label(for target: Level2CloseUpVisuals.Target) -> String {
        switch target.kind {
        case .collectTileIV: return "Numeral tile"
        case .collectWatchA, .collectWatchB: return "Pocket watch"
        case .collectGreatWheel: return "Great wheel"
        case .collectOilcan: return "Oil can"
        case .collectToyMouse: return "Tin mouse"
        case .liftCushion: return "Cushion"
        }
    }
}

/// Attaches a plate-wide tap ONLY when the close-up actually uses one (armed-item use / pry).
/// Without it the container stays transparent to hits, so the backdrop's dismiss keeps working
/// on the close-ups that have no plate interaction.
private struct PlateTapModifier: ViewModifier {
    let action: (() -> Void)?
    @ViewBuilder func body(content: Content) -> some View {
        if let action {
            content.contentShape(Rectangle()).onTapGesture(perform: action)
        } else {
            content
        }
    }
}

/// Maps plate-normalized rects into view space, honoring the plan's `focus` zoom.
private struct L2PlateGeometry {
    let fitted: CGRect   // the visible area the focus rect fills
    let plate: CGRect    // where the FULL plate is drawn (extends past `fitted` when zoomed)

    init(in size: CGSize, focus: CGRect) {
        let fw = max(focus.width, 0.0001), fh = max(focus.height, 0.0001)
        let aspect = (fw * Level2CloseUpVisuals.plateSize.width)
            / (fh * Level2CloseUpVisuals.plateSize.height)
        let f = fitRect(in: size, aspect: aspect)
        self.fitted = f
        let w = f.width / fw, h = f.height / fh
        self.plate = CGRect(x: f.minX - focus.minX * w, y: f.minY - focus.minY * h,
                            width: w, height: h)
    }

    /// A plate-normalized sub-rect in view coordinates.
    func sub(_ r: CGRect) -> CGRect {
        CGRect(x: plate.minX + r.minX * plate.width, y: plate.minY + r.minY * plate.height,
               width: r.width * plate.width, height: r.height * plate.height)
    }
}

// MARK: - Plain state-resolved plate (+ the wordless ring-pointer clue annotation)

/// Plain close-ups are still STATEFUL (a taken tile, a raised bar, an emptied hook), so they
/// render the same plan pipeline. They additionally carry the round-8 fix-5 clue
/// clarification: once the paired watch has been inspected, the engraved 12-notch ring shows
/// the canonical hour hand pointing along the direction that watch reads — wordless, built
/// from existing canonical art, and NOT a pointer mechanic (the cache stays a single hotspot).
private struct L2PlainCloseUp: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    let plan: Level2CloseUpVisuals.Plan
    let image: String

    var body: some View {
        L2Plate(plan: plan, identifier: "closeup-" + image,
                onPlateTap: { coordinator.useArmedItemInCloseUp() },
                extra: { plate in
            if let ring = Level2CloseUpVisuals.ringClues[image], state.hasViewedClue(ring.gateClue) {
                let radius = ring.radiusFracOfWidth * plate.width
                let center = CGPoint(x: plate.minX + ring.center.x * plate.width,
                                     y: plate.minY + ring.center.y * plate.height)
                let length = radius * Level2CloseUpVisuals.ringPointerLengthFraction
                GameImage(name: "hand-hour")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: length * 0.34, height: length * 1.32)
                    .offset(y: -length * 0.31)
                    .rotationEffect(.degrees(Double(ring.hour % 12) * 30))
                    .allowsHitTesting(false)
                    .accessibilityHidden(true)
                    .position(center)
            }
        })
    }
}

// MARK: p01 dial door (Cluster D: the decoy is the DEPICTED tray tile, never a text button)

private struct L2DialDoorControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    let plan: Level2CloseUpVisuals.Plan
    @ObservedObject var interaction: InteractionModel
    @State private var trayVISelected = false

    /// Socket CU rects come from the same authored overlay data the seated-tile art uses, so
    /// a socket's hit region and its seated tile can never drift apart.
    private static let socketOverlays: [String: String] = [
        "2": "ov-dial-seat-ii", "4": "ov-dial-seat-iv",
        "7": "ov-dial-seat-vii", "11": "ov-dial-seat-xi",
    ]

    var body: some View {
        L2Plate(plan: plan, identifier: "dial-door", extra: { plate in
            ForEach(Level2Graph.dialSockets, id: \.self) { socket in
                let r = Self.sub(Level2OverlayCatalog.shared.cuRect(Self.socketOverlays[socket] ?? ""),
                                 in: plate)
                Color.white.opacity(0.001)
                    .frame(width: max(r.width, 44), height: max(r.height, 44))
                    .contentShape(Rectangle())
                    .onTapGesture { seat(socket) }
                    .accessibilityLabel("Dial socket")
                    .accessibilityIdentifier("dial-socket-" + socket)
                    .position(x: r.midX, y: r.midY)
            }
            // R8-004(3)+(4): the decoy IS the loose VI tile drawn in the tray. Tapping it
            // picks it up (a pale selection ring — no label, no floating button); tapping a
            // socket then tries to seat it and it whirs, stalls and pops back to the tray,
            // exactly as p01's solution_fixed "rejected: tray VI in socket-4" describes.
            trayDecoy(in: plate)
        })
    }

    private func trayDecoy(in plate: CGRect) -> some View {
        let tray = Self.sub(Level2CloseUpVisuals.trayDecoyRect, in: plate)
        return ZStack {
            if trayVISelected {
                RoundedRectangle(cornerRadius: 6)
                    .strokeBorder(NavChevron.boneWhite.opacity(0.85), lineWidth: 2)
                    .frame(width: tray.width * 1.3, height: tray.height * 2.0)
                    .shadow(color: .black.opacity(0.5), radius: 3)
            }
            Color.white.opacity(0.001)
                .frame(width: max(tray.width, 44), height: max(tray.height, 44))
        }
        .contentShape(Rectangle())
        .onTapGesture {
            trayVISelected.toggle()
            if trayVISelected { interaction.disarm() }
            SoundManager.shared.play(.tick)
        }
        .accessibilityLabel("Loose tile in the tray")
        .accessibilityIdentifier("dial-tray-vi")
        .position(x: tray.midX, y: tray.midY)
    }

    private static func sub(_ r: CGRect, in plate: CGRect) -> CGRect {
        CGRect(x: plate.minX + r.minX * plate.width, y: plate.minY + r.minY * plate.height,
               width: r.width * plate.width, height: r.height * plate.height)
    }

    private func seat(_ socket: String) {
        if trayVISelected {
            coordinator.seatDialTile(Level2Graph.DecoyTile.trayVI, socket: socket)
            trayVISelected = false                      // pops back to the tray
        } else if let armed = interaction.armedItem, Level2Graph.ItemID.dialTiles.contains(armed) {
            coordinator.seatDialTile(armed, socket: socket)
        } else {
            SoundManager.shared.play(.wrong)            // nothing selected to seat
        }
    }
}

// MARK: p06 gear frame (near-wordless: real gear art, no "Rack"/"Crank"/"Post A/B" labels)

private struct L2GearFrameControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    let plan: Level2CloseUpVisuals.Plan
    let isArmed: Bool
    @State private var selectedGear: String?

    private var pickerGears: [String] {
        Level2Graph.rackGears + (state.hasItem(Level2Graph.ItemID.greatWheel)
                                 ? [Level2Graph.gearGreatWheelValue] : [])
    }

    var body: some View {
        L2Plate(plan: plan, identifier: "gear-frame",
                isArmed: isArmed,
                onUse: { _ = coordinator.runCloseUpUse($0) },
                extra: { plate in
            postTarget(.a, plate: plate)
            postTarget(.b, plate: plate)
            crankTarget(in: plate)
        })
        .overlay(alignment: .top) { gearPicker.padding(.top, 12) }
    }

    /// The rack, rendered as the ACTUAL gear cutouts (z2/props/gear-*), scaled by tooth count
    /// so their relative sizes — the whole point of a ratio puzzle — read at a glance.
    private var gearPicker: some View {
        HStack(spacing: 10) {
            ForEach(pickerGears, id: \.self) { g in gearButton(g) }
        }
        .padding(.horizontal, 14).padding(.vertical, 8)
        .background(
            Capsule().fill(Color(red: 0.078, green: 0.086, blue: 0.102).opacity(0.62))
                .overlay(Capsule().stroke(NavChevron.boneWhite.opacity(0.08), lineWidth: 1))
        )
        .accessibilityIdentifier("gear-rack-picker")
    }

    private func gearButton(_ g: String) -> some View {
        let teeth = CGFloat(Int(g) ?? 24)
        let size = 30 + (teeth / 72.0) * 26
        return Button(action: { selectedGear = (selectedGear == g ? nil : g) }) {
            ZStack {
                if selectedGear == g {
                    Circle().strokeBorder(NavChevron.boneWhite.opacity(0.9), lineWidth: 2)
                        .frame(width: size + 10, height: size + 10)
                }
                GameImage(name: g == Level2Graph.gearGreatWheelValue ? "inv-great-wheel" : "gear-" + g)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: size, height: size)
                    .offset(y: selectedGear == g ? -3 : 0)
            }
            .frame(width: 62, height: 62)
        }
        .accessibilityLabel("Gear")
        .accessibilityIdentifier("gear-" + g)
    }

    /// An empty post shows a faint dashed seat ring (wordless "something mounts here"); a
    /// filled post is shown by the composited mount overlay in the plan.
    private func postTarget(_ post: Level2Post, plate: CGRect) -> some View {
        let current = Level2Engine.currentPostGear(post, state)
        let n = Level2CloseUpVisuals.postRect(post, gear: current)
        let r = CGRect(x: plate.minX + n.minX * plate.width, y: plate.minY + n.minY * plate.height,
                       width: n.width * plate.width, height: n.height * plate.height)
        return ZStack {
            if current == nil {
                Circle()
                    .strokeBorder(NavChevron.boneWhite.opacity(0.30),
                                  style: StrokeStyle(lineWidth: 2, dash: [6, 7]))
                    .frame(width: r.width * 0.9, height: r.width * 0.9)
            }
            Color.white.opacity(0.001).frame(width: max(r.width, 44), height: max(r.height, 44))
        }
        .contentShape(Rectangle())
        .onTapGesture { tapPost(post) }
        .accessibilityLabel(post == .a ? "First arbor post" : "Second arbor post")
        .accessibilityIdentifier("gear-post-" + (post == .a ? "a" : "b"))
        .position(x: r.midX, y: r.midY)
    }

    /// R8-019 — DIEGETIC CRANK. Build 16's near-wordless pass replaced the "Crank" text button
    /// with an `arrow.triangle.2.circlepath` SF Symbol in a chrome circle, which reads as a
    /// browser RELOAD button — UI idiom in a painterly scene, and the user found it confusing
    /// and out of place. The tap target is now the PAINTED CRANK ARM itself, with a faint
    /// brass turn-arc drawn over it (the same wordless "this moves" grammar as the dashed
    /// empty-post seat rings), no floating chrome.
    private func crankTarget(in plate: CGRect) -> some View {
        let n = Level2CloseUpVisuals.crankHandleRect
        let r = CGRect(x: plate.minX + n.minX * plate.width, y: plate.minY + n.minY * plate.height,
                       width: n.width * plate.width, height: n.height * plate.height)
        return ZStack {
            TurnArc(clockwise: true)
                .stroke(NavChevron.boneWhite.opacity(0.34), lineWidth: 3)
                .frame(width: min(r.width, r.height) * 0.72, height: min(r.width, r.height) * 0.72)
                .shadow(color: .black.opacity(0.55), radius: 3)
            Color.white.opacity(0.001)
                .frame(width: max(r.width, 60), height: max(r.height, 60))
        }
        .contentShape(Rectangle())
        .onTapGesture { coordinator.crankGearTrain() }
        .accessibilityLabel("Turn the crank")
        .accessibilityIdentifier("gear-crank")
        .position(x: r.midX, y: r.midY)
    }

    private func tapPost(_ post: Level2Post) {
        if let g = selectedGear {
            coordinator.mountGear(g, on: post)
            selectedGear = nil
        } else if Level2Engine.currentPostGear(post, state) != nil {
            coordinator.unmountGear(post)
        }
    }
}

// MARK: p07 vault wheels (landmark DIES, not landmark words — the graph's pictogram match)

private struct L2VaultWheelControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    /// z3 binding order (Level2Graph.vaultHeaders), as canonical glyph dies.
    private static let headerDies = ["die-bigben", "die-burj", "die-liberty", "die-fuji"]
    private static let roman = ["", "I", "II", "III", "IV", "V", "VI", "VII", "VIII", "IX", "X", "XI", "XII"]

    var body: some View {
        ZStack {
            L2Plate(plan: Level2CloseUpVisuals.Plan(base: "cu-hatch-wheels"), identifier: "vault-wheels")
            VStack {
                Spacer()
                HStack(spacing: 20) { ForEach(0..<4, id: \.self) { i in wheel(i) } }
                    .padding(.horizontal, 18).padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 18)
                            .fill(Color(red: 0.078, green: 0.086, blue: 0.102).opacity(0.72))
                            .overlay(RoundedRectangle(cornerRadius: 18)
                                .stroke(NavChevron.boneWhite.opacity(0.08), lineWidth: 1))
                    )
                Spacer().frame(height: 74)   // clear of the dismiss chevron
            }
        }
    }

    private func wheel(_ i: Int) -> some View {
        VStack(spacing: 6) {
            GlyphImage(name: Self.headerDies[i], color: NavChevron.boneWhite.opacity(0.85))
                .frame(height: 26)
                .accessibilityIdentifier("vault-header-" + Level2Graph.vaultHeaders[i])
            Button(action: { coordinator.setVaultWheel(i, delta: 1) }) {
                Image(systemName: "chevron.up").foregroundColor(NavChevron.boneWhite)
                    .frame(width: 56, height: 32).contentShape(Rectangle())
            }
            .accessibilityLabel("Turn up")
            .accessibilityIdentifier("vault-wheel-" + String(i) + "-up")
            Text(Self.roman[state.data.l2VaultWheels[i]])
                .font(.title2).foregroundColor(.white)
                .frame(width: 56, height: 44)
                .background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))
                .accessibilityIdentifier("vault-wheel-" + String(i))
            Button(action: { coordinator.setVaultWheel(i, delta: -1) }) {
                Image(systemName: "chevron.down").foregroundColor(NavChevron.boneWhite)
                    .frame(width: 56, height: 32).contentShape(Rectangle())
            }
            .accessibilityLabel("Turn down")
            .accessibilityIdentifier("vault-wheel-" + String(i) + "-down")
        }
    }
}

/// A canonical glyph die (RGBA silhouette master) tinted for the dark chrome register.
/// Loose game-art files can't use SwiftUI's `renderingMode(.template)` via `Image(uiImage:)`
/// unless the UIImage itself is re-rendered as a template, which this does once per draw.
private struct GlyphImage: View {
    let name: String
    let color: Color
    var body: some View {
        if let ui = GameAssetLoader.shared.image(named: name) {
            Image(uiImage: ui.withRenderingMode(.alwaysTemplate))
                .resizable()
                .aspectRatio(contentMode: .fit)
                .foregroundColor(color)
        } else {
            Color.clear
        }
    }
}

// MARK: p09 great dial (mirrored back view + setting crank)

/// R8-020(1) — THE AUTHORED HANDS, ANCHORED ON THE HUB.
///
/// Build 16 drew both hands as SwiftUI capsules centred on the PLATE centre, so they rendered
/// as placeholder strokes AND the minute hand did not pivot from the dial hub — the player was
/// asked to read a time off an unreadable clock (a rendering confound on p09's difficulty).
/// Build 17, per the user's GATE-1 ruling: the authored `hand-hour` / `hand-minute` sprites,
/// rotated about their authored pivots, placed on the hub the art was cut against
/// (`hand-sprites.json` -> `Level2SpriteCatalog`, not hand-transcribed constants).
///
/// Two contracts are honoured:
///  * D1 MIRROR — this is the BACK of the dial, so a FRONT angle theta renders at -theta.
///    (Nothing about the time is baked into the plate; the sprites carry the time.)
///  * R4-007 SPRITE/VIEW ROTATION — the sprite art is authored UPRIGHT (pointing at 12 with
///    no pre-rotation baked in), so the view rotation applies the angle exactly ONCE.
private struct L2GreatDialControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    let plan: Level2CloseUpVisuals.Plan

    private var rig: Level2SpriteCatalog { .shared }

    var body: some View {
        L2Plate(plan: plan, identifier: "great-dial", extra: { plate in
            hand(rig.hourHand, angle: -hourAngle, in: plate)
            hand(rig.minuteHand, angle: -minuteAngle, in: plate)
            crankTarget(detents: -1, in: plate)
            crankTarget(detents: 1, in: plate)
        })
    }

    private var minutes: Int { state.data.l2ClockFrontMinutes }
    private var hourAngle: Double { Double(minutes) * 0.5 }          // 0.5 deg/min
    private var minuteAngle: Double { Double(minutes % 60) * 6.0 }   // 6 deg/min

    /// Draw a hand sprite at CU scale, rotated about its own pivot, with that pivot sitting on
    /// the dial hub. `ringSquashX` compresses the sweep to the painted numeral ELLIPSE (the
    /// dial is seen slightly off-axis), so a hand tip stays on its numeral all the way round.
    private func hand(_ h: Level2SpriteCatalog.Hand, angle: Double, in plate: CGRect) -> some View {
        let d = rig.dial
        // Plate width is the CU plate (2048 px) drawn at `plate.width` points.
        let ppx = plate.width / Level2SpriteCatalog.cuRef.width
        let w = h.size.width * d.cuScale * ppx
        let ht = h.size.height * d.cuScale * ppx
        let hub = CGPoint(x: plate.minX + d.hub.x * plate.width,
                          y: plate.minY + d.hub.y * plate.height)
        let anchor = h.anchor
        return GameImage(name: h.image)
            .aspectRatio(contentMode: .fit)
            .frame(width: w, height: ht)
            .rotationEffect(.degrees(angle), anchor: UnitPoint(x: anchor.x, y: anchor.y))
            .scaleEffect(x: d.ringSquashX, y: 1, anchor: UnitPoint(x: anchor.x, y: anchor.y))
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            // `.position` places the view's CENTRE; offset it so the PIVOT lands on the hub.
            .position(x: hub.x + (0.5 - anchor.x) * w * d.ringSquashX,
                      y: hub.y + (0.5 - anchor.y) * ht)
    }

    /// R8-020 sub-item — DIEGETIC TIME ADJUST. Build 16 floated two flat white
    /// `plus.circle.fill` / `minus.circle.fill` buttons over the painterly dial: the same
    /// "UI chrome idiom in a diegetic scene" the crank refresh icon was flagged for. The
    /// affordances are now brass turn-arcs sitting ON the painted setting crank below the hub
    /// — counter-clockwise on its left, clockwise on its right — with no chrome plate and no
    /// symbol. Identifiers are unchanged so the UI tests keep working.
    private func crankTarget(detents: Int, in plate: CGRect) -> some View {
        let n = Level2CloseUpVisuals.dialCrankRect
        let r = CGRect(x: plate.minX + n.minX * plate.width, y: plate.minY + n.minY * plate.height,
                       width: n.width * plate.width, height: n.height * plate.height)
        let side = max(min(r.width, r.height) * 0.92, 46)
        let cx = detents > 0 ? r.maxX + side * 0.42 : r.minX - side * 0.42
        return ZStack {
            TurnArc(clockwise: detents > 0)
                .stroke(NavChevron.boneWhite.opacity(0.42), lineWidth: 3)
                .frame(width: side * 0.74, height: side * 0.74)
                .shadow(color: .black.opacity(0.6), radius: 3)
            Color.white.opacity(0.001).frame(width: max(side, 52), height: max(side, 52))
        }
        .contentShape(Rectangle())
        .onTapGesture { coordinator.adjustClock(byDetents: detents) }
        .accessibilityLabel(detents > 0 ? "Advance the hands" : "Turn the hands back")
        .accessibilityIdentifier("dial-crank-" + (detents > 0 ? "plus" : "minus"))
        .position(x: cx, y: r.midY)
    }
}

/// A wordless "turn this" mark: a three-quarter arc with a small arrowhead, drawn in the
/// scene's bone-white at low opacity. Used for the gear-frame crank and the great dial's
/// setting crank instead of SF Symbols, which carry a UI-chrome idiom (`arrow.clockwise` reads
/// as RELOAD — R8-019) that clashes with the painterly room. NOTE: the global menu layer's
/// SF-Symbols-only rule is unaffected; this is in-room game art, like the dashed seat rings.
struct TurnArc: Shape {
    let clockwise: Bool

    func path(in rect: CGRect) -> Path {
        var p = Path()
        let c = CGPoint(x: rect.midX, y: rect.midY)
        let radius = min(rect.width, rect.height) / 2
        let start: CGFloat = clockwise ? -200 : 20
        let sweep: CGFloat = 240
        let end = clockwise ? start + sweep : start - sweep
        p.addArc(center: c, radius: radius,
                 startAngle: .degrees(Double(start)), endAngle: .degrees(Double(end)),
                 clockwise: !clockwise)
        // Arrowhead at the finishing end of the sweep, tangent to the arc.
        let a = CGFloat(end) * .pi / 180
        let tip = CGPoint(x: c.x + cos(a) * radius, y: c.y + sin(a) * radius)
        let tangent = a + (clockwise ? .pi / 2 : -.pi / 2)
        let head = radius * 0.42
        for side in [CGFloat(2.5), CGFloat(-2.5)] {
            let d = tangent + .pi + side * 0.35
            p.move(to: tip)
            p.addLine(to: CGPoint(x: tip.x + cos(d) * head, y: tip.y + sin(d) * head))
        }
        return p
    }
}

// MARK: p03/p04 pry caches (state-resolved: closed -> pried with the find -> emptied)

/// CLUSTER Q2 (R8-018): build 16 guarded the plate tap to ONE verb —
/// `armedItem == screwdriver` — so the cache close-ups implemented *pry* and nothing else.
/// The pry now goes through the plan's `use` region like every other armed verb (the same
/// `useItem` dispatch the wide `floor-cache`/`brick` taps use), and the revealed item's
/// collect target comes from the plan, so both verbs work from either view.
private struct L2CacheControl: View {
    enum Kind { case dormer, chimney }
    @ObservedObject var coordinator: Level2Coordinator
    let plan: Level2CloseUpVisuals.Plan
    let kind: Kind
    @ObservedObject var interaction: InteractionModel

    var body: some View {
        L2Plate(plan: plan,
                identifier: kind == .dormer ? "dormer-cache" : "chimney-cache",
                onTarget: { coordinator.runCloseUpTarget($0) },
                isArmed: interaction.armedItem != nil,
                onUse: { _ = coordinator.runCloseUpUse($0) })
    }
}

// MARK: p02 cat cushion — THE P0: state-correct plate + lift + manual watch-B pickup

/// Build 15 shipped `hasSolved(catMouse) ? "cu-cat-cushion" : "cu-cat-cushion"` — a literal
/// no-op ternary with no tap target at all, so the close-up always showed a sleeping cat and
/// the cushion could never be lifted (R8-012/R8-013). It now renders the plan (cat asleep ->
/// cat gone -> cushion lifted with watch B -> emptied), carries the lift/collect targets, and
/// composites the cat's facial-key tell while a direct offer is being refused (R8-011(1)).
private struct L2CatCushionView: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    let plan: Level2CloseUpVisuals.Plan
    @ObservedObject var interaction: InteractionModel

    /// The visible half of the D3 tell: eye key + tail key.
    ///
    /// R8-016 (user CONFIRMED override of approved rev-1.3 playtest tweak 2): the tell is
    /// MOUSE-EXCLUSIVE. rev-1.3 gave every other offered item an `ov-cat-slow-blink` refusal,
    /// but at play scale a slow half-lid blink and the tell's peering eye read as the same
    /// thing, so the cat appeared to react to everything and the tell stopped meaning "the
    /// mouse is the key". A non-mouse offer now produces no response at all (the coordinator
    /// returns false before setting `catResponse`), so this only ever renders `.mouseTell`.
    private var tellLayers: [Level2CloseUpVisuals.Layer] {
        guard !state.hasSolved(Level2Graph.PuzzleID.catMouse),
              coordinator.catResponse == .mouseTell else { return [] }
        return [Level2CloseUpVisuals.layer("ov-cat-mouse-tell"),
                Level2CloseUpVisuals.catTailTellLayer()].compactMap { $0 }
    }

    private var composited: Level2CloseUpVisuals.Plan {
        var p = plan
        p.layers.append(contentsOf: tellLayers)
        return p
    }

    /// CLUSTER Q1 (R8-015): the plate tap used to hard-code `useItem(armed, on: "cat-cushion")`
    /// — the OFFER hotspot — while p02's placement verb lives on the sibling hotspot
    /// `cat-floor`. From this close-up the armed mouse could therefore only ever produce the
    /// tell; placement was structurally unreachable and the player had to back out to the wide
    /// scene. Both verbs are now regions on the plate (floor in front of the bench = place,
    /// cushion = offer), routed through the same `useItem` dispatch as the wide taps.
    var body: some View {
        L2Plate(plan: composited, identifier: "cat-cushion",
                onTarget: { coordinator.runCloseUpTarget($0) },
                isArmed: interaction.armedItem != nil,
                onUse: { _ = coordinator.runCloseUpUse($0) })
            .animation(.easeInOut(duration: 0.25), value: coordinator.catResponse)
    }
}

/// Compute the fitted (aspectFit) rect of an image with `aspect` (w/h) inside `size`.
private func fitRect(in size: CGSize, aspect: CGFloat) -> CGRect {
    guard size.width > 0, size.height > 0 else { return .zero }
    let containerAspect = size.width / size.height
    var w = size.width, h = size.height
    if containerAspect > aspect { w = size.height * aspect } else { h = size.width / aspect }
    return CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h)
}
