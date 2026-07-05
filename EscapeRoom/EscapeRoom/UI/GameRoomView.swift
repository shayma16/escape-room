import SwiftUI

/// Top-level in-game screen: SpriteKit room view + navigation chevrons + inventory bar
/// + pause glyph, per style-guide Section 7. Landscape-locked (J6 fixed decision).
struct GameRoomView: View {
    @ObservedObject var session: LevelSession
    @StateObject private var coordinatorBox: CoordinatorBox
    @State private var showPause = false
    @State private var sceneFrame: CGRect = .zero
    @Environment(\.horizontalSizeClass) private var hSizeClass

    init(session: LevelSession) {
        self.session = session
        _coordinatorBox = StateObject(wrappedValue: CoordinatorBox(session: session))
    }

    var body: some View {
        GeometryReader { _ in
            ZStack {
                Color.black.ignoresSafeArea()

                SpriteKitContainerView(coordinator: coordinatorBox.coordinator)
                    .ignoresSafeArea()
                    .background(GeometryReader { sceneGeo in
                        Color.clear.onAppear { sceneFrame = sceneGeo.frame(in: .global) }
                            .onChange(of: sceneGeo.size) { _ in sceneFrame = sceneGeo.frame(in: .global) }
                    })

                VStack {
                    HStack {
                        pauseButton
                        Spacer()
                    }
                    .padding(24)
                    Spacer()
                    puzzleControlOverlay
                    InventoryBarView(state: session.state, coordinator: coordinatorBox.coordinator,
                                      horizontalSizeClass_isPad: hSizeClass == .regular)
                }

                navigationChevrons
            }
        }
        .onChange(of: session.currentView) { newView in
            coordinatorBox.setView(newView, size: CGSize(width: 2732, height: 1366))
        }
        .onReceive(NotificationCenter.default.publisher(for: .inventoryItemDropped)) { note in
            guard let itemID = note.userInfo?["itemID"] as? String,
                  let point = note.userInfo?["globalPoint"] as? CGPoint else { return }
            let localPoint = CGPoint(x: point.x - sceneFrame.minX, y: point.y - sceneFrame.minY)
            let scene = coordinatorBox.coordinator.scene
            // SKView-less conversion: our scenes use .aspectFill with a centered anchor
            // point, and the view is sized to fill `sceneFrame`, so view-space (top-left
            // origin) maps to scene-space (centered origin, y-up) via a simple affine
            // transform using the scene's own declared size.
            let scenePoint = CGPoint(
                x: (localPoint.x / max(sceneFrame.width, 1) - 0.5) * scene.size.width,
                y: (0.5 - localPoint.y / max(sceneFrame.height, 1)) * scene.size.height
            )
            if let hotspotID = coordinatorBox.coordinator.scene.hotspotID(atScenePoint: scenePoint) {
                coordinatorBox.coordinator.handleExternalDrop(itemID: itemID, hotspotID: hotspotID)
            }
        }
        .sheet(isPresented: $showPause) {
            PauseMenuView(session: session, isPresented: $showPause)
        }
        .statusBarHidden(true)
    }

    @ViewBuilder
    private var puzzleControlOverlay: some View {
        switch session.currentView {
        case .hearth where !session.state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar):
            MoonDialControlView(state: session.state) {}
        case .bench:
            BrewControlView(state: session.state) { _ in }
        default:
            EmptyView()
        }
    }

    private var pauseButton: some View {
        Button(action: { showPause = true }) {
            Image("pause-rune")
                .resizable()
                .frame(width: 40, height: 40)
                .opacity(0.4)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Pause")
    }

    private var navigationChevrons: some View {
        HStack {
            chevronButton(systemName: "chevron.left") { session.previousView() }
            Spacer()
            chevronButton(systemName: "chevron.right") { session.nextView() }
        }
        .padding(.horizontal, 8)
    }

    private func chevronButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .regular))
                .foregroundColor(Color(white: 0.9).opacity(0.4))
                .frame(width: 44, height: 44)
        }
        .accessibilityLabel(systemName == "chevron.left" ? "Previous view" : "Next view")
    }
}

/// Small helper object so the RoomSceneCoordinator (which owns non-Equatable SpriteKit
/// state) can be swapped out as a `@Published` property without re-triggering
/// StateObject identity churn in the parent view.
final class CoordinatorBox: ObservableObject {
    @Published private(set) var coordinator: RoomSceneCoordinator
    private let session: LevelSession

    init(session: LevelSession) {
        self.session = session
        self.coordinator = RoomSceneCoordinator(viewID: session.currentView, state: session.state, size: CGSize(width: 2732, height: 1366))
    }

    func setView(_ viewID: ViewID, size: CGSize) {
        guard coordinator.viewID != viewID else { return }
        coordinator = RoomSceneCoordinator(viewID: viewID, state: session.state, size: size)
    }
}
