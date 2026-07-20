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
            L2CloseUpHost(coordinator: box.coordinator, bottomInset: barHeight)

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
                    onReplay: { session.restartLevel(); SoundManager.shared.enterLevel() })
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

private struct L2CloseUpHost: View {
    @ObservedObject var coordinator: Level2Coordinator
    let bottomInset: CGFloat
    @ObservedObject private var interaction: InteractionModel
    init(coordinator: Level2Coordinator, bottomInset: CGFloat) {
        self.coordinator = coordinator
        self.bottomInset = bottomInset
        self.interaction = coordinator.interaction ?? InteractionModel()
    }
    var body: some View {
        if let request = coordinator.activeCloseUp {
            ZStack {
                Color.black.opacity(0.92).ignoresSafeArea().onTapGesture { coordinator.dismissCloseUp() }
                content(request)
                    .padding(.bottom, bottomInset)
                VStack { Spacer()
                    NavChevron.dismissButton(action: { coordinator.dismissCloseUp() }, isPad: true)
                        .padding(.bottom, 12).accessibilityIdentifier("closeup-dismiss")
                }
            }
            .transition(.opacity)
        }
    }

    @ViewBuilder private func content(_ request: L2CloseUp) -> some View {
        switch request {
        case .plain(let image): PlatePlateView(image: image)
        case .dialDoor: L2DialDoorControl(coordinator: coordinator, interaction: interaction)
        case .gearFrame: L2GearFrameControl(coordinator: coordinator, state: coordinator.state)
        case .vaultWheels: L2VaultWheelControl(coordinator: coordinator, state: coordinator.state)
        case .greatDial: L2GreatDialControl(coordinator: coordinator, state: coordinator.state)
        case .windingDrum: L2WindingDrumControl(coordinator: coordinator, interaction: interaction)
        case .dormerCache: L2CacheControl(coordinator: coordinator, state: coordinator.state, kind: .dormer, interaction: interaction)
        case .chimneyCache: L2CacheControl(coordinator: coordinator, state: coordinator.state, kind: .chimney, interaction: interaction)
        case .catCushion: L2CatCushionView(coordinator: coordinator)
        }
    }
}

/// A plain zoomed close-up plate.
private struct PlatePlateView: View {
    let image: String
    var body: some View {
        GameImage(name: image).aspectRatio(contentMode: .fit).padding(24)
    }
}

// MARK: p01 dial door

private struct L2DialDoorControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var interaction: InteractionModel
    @State private var trayVISelected = false

    /// Socket CU rects (normalized to the 2048x1536 cu-door-dial plate) from the dial-seat
    /// overlay data. Keyed by socket number.
    private static let socketRects: [String: CGRect] = [
        "2":  CGRect(x: 1159/2048.0, y: 360/1536.0, width: 128/2048.0, height: 128/1536.0),
        "4":  CGRect(x: 1159/2048.0, y: 625/1536.0, width: 128/2048.0, height: 128/1536.0),
        "7":  CGRect(x: 797/2048.0,  y: 722/1536.0, width: 128/2048.0, height: 128/1536.0),
        "11": CGRect(x: 797/2048.0,  y: 263/1536.0, width: 128/2048.0, height: 128/1536.0),
    ]

    var body: some View {
        GeometryReader { geo in
            let plate = fitRect(in: geo.size, aspect: 2048.0/1536.0)
            ZStack {
                GameImage(name: "cu-door-dial").aspectRatio(contentMode: .fit)
                ForEach(Array(Self.socketRects.keys), id: \.self) { socket in
                    let r = Self.socketRects[socket]!
                    Button(action: { seat(socket) }) { Color.clear }
                        .frame(width: r.width * plate.width, height: r.height * plate.height)
                        .position(x: plate.minX + (r.midX) * plate.width, y: plate.minY + (r.midY) * plate.height)
                        .accessibilityIdentifier("dial-socket-\(socket)")
                }
                // Tray VI decoy: selectable, then a socket tap tries it (glyph-order trap).
                Button(action: { trayVISelected.toggle() }) {
                    Text("VI").font(.title3).padding(8)
                        .background(Circle().fill(trayVISelected ? Color.orange.opacity(0.5) : Color.black.opacity(0.4)))
                        .foregroundColor(.white)
                }
                .position(x: plate.midX, y: plate.maxY - 20)
                .accessibilityIdentifier("dial-tray-vi")
            }
        }
        .padding(24)
    }

    private func seat(_ socket: String) {
        if trayVISelected {
            coordinator.seatDialTile("tile-vi-decoy", socket: socket)
            trayVISelected = false
        } else if let armed = interaction.armedItem, Level2Graph.ItemID.dialTiles.contains(armed) {
            coordinator.seatDialTile(armed, socket: socket)
        } else {
            SoundManager.shared.play(.wrong)   // nothing selected to seat
        }
    }
}

// MARK: p06 gear frame

private struct L2GearFrameControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    @State private var selectedGear: String?

    var body: some View {
        VStack(spacing: 14) {
            GameImage(name: "cu-gear-frame").aspectRatio(contentMode: .fit).frame(maxHeight: 320)
            HStack(spacing: 24) {
                postView(.a, label: "Post A")
                postView(.b, label: "Post B")
            }
            Text("Rack").foregroundColor(.white.opacity(0.7)).font(.caption)
            HStack(spacing: 10) {
                ForEach(Level2Graph.rackGears, id: \.self) { g in gearButton(g) }
                if state.hasItem(Level2Graph.ItemID.greatWheel) { gearButton("64") }
            }
            Button(action: { coordinator.crankGearTrain() }) {
                Label("Crank", systemImage: "arrow.triangle.2.circlepath")
            }
            .buttonStyle(.chromePrimary).accessibilityIdentifier("gear-crank")
        }
        .padding(24)
    }

    private func gearButton(_ g: String) -> some View {
        Button(action: { selectedGear = (selectedGear == g ? nil : g) }) {
            Text(g).font(.headline).frame(width: 52, height: 52)
                .background(Circle().fill(selectedGear == g ? Color.orange.opacity(0.5) : Color.black.opacity(0.4)))
                .foregroundColor(.white)
        }
        .accessibilityIdentifier("gear-\(g)")
    }

    private func postView(_ post: Level2Post, label: String) -> some View {
        let current = Level2Engine.currentPostGear(post, state)
        return VStack(spacing: 6) {
            Text(label).font(.caption).foregroundColor(.white.opacity(0.7))
            Button(action: { tapPost(post) }) {
                Text(current ?? "—").font(.title3).frame(width: 64, height: 64)
                    .background(RoundedRectangle(cornerRadius: 10).fill(Color.black.opacity(0.5)))
                    .foregroundColor(.white)
            }
            .accessibilityIdentifier("gear-post-\(post == .a ? "a" : "b")")
        }
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

// MARK: p07 vault wheels

private struct L2VaultWheelControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    private static let headers = ["Big Ben", "Burj", "Liberty", "Fuji"]
    private static let roman = ["", "I","II","III","IV","V","VI","VII","VIII","IX","X","XI","XII"]

    var body: some View {
        VStack(spacing: 16) {
            GameImage(name: "cu-hatch-wheels").aspectRatio(contentMode: .fit).frame(maxHeight: 300)
            HStack(spacing: 20) {
                ForEach(0..<4, id: \.self) { i in wheel(i) }
            }
        }
        .padding(24)
    }

    private func wheel(_ i: Int) -> some View {
        VStack(spacing: 6) {
            Text(Self.headers[i]).font(.caption2).foregroundColor(.white.opacity(0.7))
            Button(action: { coordinator.setVaultWheel(i, delta: 1) }) {
                Image(systemName: "chevron.up").foregroundColor(.white)
            }
            Text(Self.roman[state.data.l2VaultWheels[i]]).font(.title2).foregroundColor(.white)
                .frame(width: 56, height: 44).background(RoundedRectangle(cornerRadius: 8).fill(Color.black.opacity(0.5)))
                .accessibilityIdentifier("vault-wheel-\(i)")
            Button(action: { coordinator.setVaultWheel(i, delta: -1) }) {
                Image(systemName: "chevron.down").foregroundColor(.white)
            }
        }
    }
}

// MARK: p09 great dial (mirrored back view + setting crank)

private struct L2GreatDialControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState

    var body: some View {
        VStack(spacing: 14) {
            GeometryReader { geo in
                let side = min(geo.size.width, geo.size.height)
                ZStack {
                    GameImage(name: "cu-great-dial").aspectRatio(contentMode: .fit)
                    // Hands rendered at the MIRRORED angle (D1: front angle θ renders at −θ).
                    hand(lengthFrac: 0.30, widthPt: 10, angle: -hourAngle, side: side)   // hour
                    hand(lengthFrac: 0.42, widthPt: 6, angle: -minuteAngle, side: side)  // minute
                }
                .frame(width: geo.size.width, height: geo.size.height)
            }
            .frame(maxHeight: 340)
            HStack(spacing: 28) {
                crankButton("minus", detents: -1)
                crankButton("plus", detents: 1)
            }
        }
        .padding(24)
    }

    private var minutes: Int { state.data.l2ClockFrontMinutes }
    private var hourAngle: Double { Double(minutes) * 0.5 }          // 0.5°/min
    private var minuteAngle: Double { Double(minutes % 60) * 6.0 }   // 6°/min

    private func hand(lengthFrac: CGFloat, widthPt: CGFloat, angle: Double, side: CGFloat) -> some View {
        // A side×side container centered on the hub; the hand extends up from center, so
        // rotating the container pivots the hand about the hub (mirrored angle per D1).
        Capsule()
            .fill(Color.black.opacity(0.7))
            .frame(width: widthPt, height: side * lengthFrac)
            .offset(y: -side * lengthFrac / 2)
            .frame(width: side, height: side)
            .rotationEffect(.degrees(angle))
    }

    private func crankButton(_ symbol: String, detents: Int) -> some View {
        Button(action: { coordinator.adjustClock(byDetents: detents) }) {
            Image(systemName: symbol.contains("plus") ? "plus.circle.fill" : "minus.circle.fill")
                .font(.system(size: 40)).foregroundColor(.white.opacity(0.85))
        }
        .accessibilityIdentifier("dial-crank-\(detents > 0 ? "plus" : "minus")")
    }
}

// MARK: p08 winding drum (armed oil / key)

private struct L2WindingDrumControl: View {
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var interaction: InteractionModel
    var body: some View {
        VStack {
            GameImage(name: "cu-winding-drum").aspectRatio(contentMode: .fit)
                .onTapGesture {
                    if let armed = interaction.armedItem, coordinator.useOnDrum(armed) { interaction.disarm() }
                }
        }
        .padding(24)
        .accessibilityIdentifier("winding-drum")
    }
}

// MARK: p03/p04 pry caches

private struct L2CacheControl: View {
    enum Kind { case dormer, chimney }
    @ObservedObject var coordinator: Level2Coordinator
    @ObservedObject var state: GameState
    let kind: Kind
    @ObservedObject var interaction: InteractionModel

    private var plate: String { kind == .dormer ? "cu-floor-cache" : "cu-brick-cache" }
    private var solved: Bool {
        state.hasSolved(kind == .dormer ? Level2Graph.PuzzleID.cacheDormer : Level2Graph.PuzzleID.cacheChimney)
    }
    private var uncollected: Bool {
        kind == .dormer ? Level2Engine.isGreatWheelUncollected(state) : Level2Engine.isOilcanUncollected(state)
    }

    var body: some View {
        VStack {
            GameImage(name: plate).aspectRatio(contentMode: .fit)
                .onTapGesture {
                    if !solved, interaction.armedItem == Level2Graph.ItemID.screwdriver {
                        let ok = kind == .dormer ? coordinator.pryDormer() : coordinator.pryChimney()
                        if ok { interaction.disarm() }
                    } else if uncollected {
                        kind == .dormer ? coordinator.collectGreatWheel() : coordinator.collectOilcan()
                    }
                }
        }
        .padding(24)
        .accessibilityIdentifier(kind == .dormer ? "dormer-cache" : "chimney-cache")
    }
}

// MARK: p02 cat cushion look

private struct L2CatCushionView: View {
    @ObservedObject var coordinator: Level2Coordinator
    private var image: String {
        coordinator.state.hasSolved(Level2Graph.PuzzleID.catMouse) ? "cu-cat-cushion" : "cu-cat-cushion"
    }
    var body: some View {
        GameImage(name: image).aspectRatio(contentMode: .fit).padding(24)
            .accessibilityIdentifier("cat-cushion")
    }
}

/// Compute the fitted (aspectFit) rect of an image with `aspect` (w/h) inside `size`.
private func fitRect(in size: CGSize, aspect: CGFloat) -> CGRect {
    let containerAspect = size.width / size.height
    var w = size.width, h = size.height
    if containerAspect > aspect { w = size.height * aspect } else { h = size.width / aspect }
    return CGRect(x: (size.width - w) / 2, y: (size.height - h) / 2, width: w, height: h)
}
