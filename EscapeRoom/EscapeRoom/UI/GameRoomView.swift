import SwiftUI
import SpriteKit

/// Top-level in-game screen: SpriteKit room view + navigation chevrons + inventory bar
/// + pause glyph + the close-up layer, per style-guide Section 7. Landscape-locked (J6).
struct GameRoomView: View {
    @ObservedObject var session: LevelSession
    @ObservedObject private var gameState: GameState
    @StateObject private var coordinatorBox: CoordinatorBox
    @State private var showPause = false
    /// Black dip used for view/zone transitions (style guide Section 7: 300 ms
    /// crossfade view-to-view, 600 ms dip zone-to-zone — QA-BUG-021).
    @State private var transitionDip: Double = 0
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @EnvironmentObject private var navigator: AppNavigator

    init(session: LevelSession) {
        self.session = session
        self.gameState = session.state
        _coordinatorBox = StateObject(wrappedValue: CoordinatorBox(session: session))
    }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpriteKitContainerView(coordinator: coordinatorBox.coordinator)
                .ignoresSafeArea()
                .accessibilityIdentifier("room-scene")

            VStack {
                HStack {
                    pauseButton
                    Spacer()
                }
                .padding(24)
                Spacer()
                InventoryBarView(state: session.state, coordinator: coordinatorBox.coordinator,
                                  horizontalSizeClass_isPad: hSizeClass == .regular)
            }

            navigationChevrons

            // Close-up / inspection layer (QA-BUG-013).
            CloseUpHost(coordinator: coordinatorBox.coordinator)

            // Transition dip overlay.
            Color.black.opacity(transitionDip).ignoresSafeArea().allowsHitTesting(false)

            if gameState.isComplete {
                LevelCompleteOverlay(
                    onMainMenu: {
                        SoundManager.shared.stopAmbient()
                        navigator.popToRoot()
                    },
                    onReplay: {
                        session.restartLevel()
                    }
                )
            }
        }
        .onChange(of: session.currentView) { newView in
            let zoneChanged = coordinatorBox.coordinator.viewID.zoneID != newView.zoneID
            let half = zoneChanged ? 0.3 : 0.15
            withAnimation(.easeIn(duration: half)) { transitionDip = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + half) {
                coordinatorBox.setView(newView, size: CGSize(width: 2732, height: 1366))
                withAnimation(.easeOut(duration: half)) { transitionDip = 0 }
            }
        }
        .onReceive(NotificationCenter.default.publisher(for: .inventoryItemDropped)) { note in
            guard let itemID = note.userInfo?["itemID"] as? String,
                  let point = note.userInfo?["globalPoint"] as? CGPoint else { return }
            handleInventoryDrop(itemID: itemID, globalPoint: point)
        }
        .sheet(isPresented: $showPause) {
            PauseMenuView(session: session, isPresented: $showPause)
        }
        .statusBarHidden(true)
    }

    /// QA-BUG-014 fix: exact conversion. SwiftUI's `.global` drag coordinates are
    /// window base coordinates for a full-screen hierarchy; `UIView.convert(_:from:nil)`
    /// maps window -> SKView space and `SKScene.convertPoint(fromView:)` applies the
    /// real .aspectFill transform (crop included) — no hand-rolled linear mapping.
    private func handleInventoryDrop(itemID: String, globalPoint: CGPoint) {
        let coordinator = coordinatorBox.coordinator
        guard let skView = coordinator.skView, skView.scene === coordinator.scene else { return }
        let viewPoint = skView.convert(globalPoint, from: nil)
        guard skView.bounds.contains(viewPoint) else { return }
        let scenePoint = coordinator.scene.convertPoint(fromView: viewPoint)
        if let hotspotID = coordinator.scene.hotspotID(atScenePoint: scenePoint) {
            coordinator.handleExternalDrop(itemID: itemID, hotspotID: hotspotID)
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
        .accessibilityIdentifier("pause-button")
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
        .accessibilityIdentifier(systemName == "chevron.left" ? "nav-previous" : "nav-next")
    }
}

/// Observes the active coordinator and presents its requested close-up.
private struct CloseUpHost: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        if let request = coordinator.activeCloseUp {
            CloseUpView(coordinator: coordinator, request: request)
                .transition(.opacity)
        }
    }
}

/// p17 win beat: near-wordless completion card (the crow-flies-out animation is a
/// polish-pass item; the card closes the loop to Level Select's completion badge).
/// Also shown when re-entering an already-completed level, where "Play Again"
/// (Restart Level semantics) is the way back in.
private struct LevelCompleteOverlay: View {
    let onMainMenu: () -> Void
    let onReplay: () -> Void

    var body: some View {
        ZStack {
            Color.black.opacity(0.88).ignoresSafeArea()
            VStack(spacing: 28) {
                Image("keyhole-emblem")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white.opacity(0.25))
                    .frame(width: 120, height: 120)
                Image(systemName: "checkmark.circle")
                    .font(.system(size: 40, weight: .light))
                    .foregroundColor(Chrome.textPrimary)
                    .accessibilityIdentifier("level-complete")
                Button(action: onMainMenu) {
                    Label("Main Menu", systemImage: "house")
                }
                .buttonStyle(.chromePrimary)
                .accessibilityIdentifier("complete-main-menu")
                Button(action: onReplay) {
                    Label("Play Again", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.chromePrimary)
                .accessibilityIdentifier("complete-replay")
            }
        }
        // NOTE: no accessibilityIdentifier on this container — an identifier on the
        // ZStack masked its child buttons from the accessibility tree (XCUITest saw
        // "level-complete" but not "complete-main-menu", CI run 28769311462). The
        // identifier lives on the checkmark leaf instead.
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
        wireNavigation(coordinator)
    }

    func setView(_ viewID: ViewID, size: CGSize) {
        guard coordinator.viewID != viewID else { return }
        let next = RoomSceneCoordinator(viewID: viewID, state: session.state, size: size)
        wireNavigation(next)
        coordinator = next
    }

    private func wireNavigation(_ coordinator: RoomSceneCoordinator) {
        coordinator.onNavigate = { [weak self] viewID in
            self?.session.goTo(viewID)
        }
    }
}
