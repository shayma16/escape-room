import SwiftUI
import SpriteKit

/// Top-level in-game screen: SpriteKit room view + navigation chevrons + inventory bar
/// + pause glyph + the close-up layer, per style-guide Section 7. Landscape-locked (J6).
///
/// Feedback round 1 layering/navigation changes:
/// - The inventory bar renders ABOVE the close-up layer, so it is visible and usable
///   in EVERY close-up (F-020 systemic fix; presentation refinement pending the
///   Section 7 Rev-2 addendum).
/// - Chevrons cycle views WITHIN the current zone only and hide entirely in
///   single-view zones (F-024); zone transitions are diegetic passages handled by the
///   scene coordinator (rune door, trapdoor, cellar ladder, shelf gap), plus an
///   interim exit affordance for z2 (no return-door art exists — flagged).
/// - Chevron visibility raised per F-025 (interim treatment pending the addendum).
/// - The item inspect view (F-016) presents over everything.
struct GameRoomView: View {
    @ObservedObject var session: LevelSession
    @ObservedObject private var gameState: GameState
    @ObservedObject private var interaction: InteractionModel
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
        self.interaction = session.interaction
        _coordinatorBox = StateObject(wrappedValue: CoordinatorBox(session: session))
    }

    private var barHeight: CGFloat { hSizeClass == .regular ? 96 : 72 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpriteKitContainerView(coordinator: coordinatorBox.coordinator)
                .ignoresSafeArea()
                .accessibilityIdentifier("room-scene")

            navigationChevrons

            // Close-up / inspection layer (QA-BUG-013). Sits UNDER the inventory bar
            // (F-020) and keeps its content clear of it via bottomInset.
            CloseUpHost(coordinator: coordinatorBox.coordinator, bottomInset: barHeight)

            // Chrome above the close-up layer: pause + inventory bar.
            VStack {
                HStack {
                    pauseButton
                    Spacer()
                }
                .padding(24)
                Spacer()
                InventoryBarView(state: session.state, interaction: interaction,
                                  horizontalSizeClass_isPad: hSizeClass == .regular)
            }

            // Interim diegetic-gap patch: z2 has no painted return door, so an exit
            // affordance stands in for "back through the rune door" until the Art
            // Director/asset pass supplies one (flagged in implementation notes).
            if session.currentView.zoneID == PuzzleGraph.ZoneID.z2Workshop {
                ZoneExitHost(coordinator: coordinatorBox.coordinator,
                             barHeight: barHeight) {
                    session.goTo(.study)
                }
            }

            // F-016: enlarged item inspect, over everything.
            if let inspecting = interaction.inspectingItem {
                ItemInspectView(itemID: inspecting) {
                    interaction.inspectingItem = nil
                }
            }

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
            if zoneChanged {
                SoundManager.shared.play(.wood) // diegetic passage beat (Section 7)
            }
            withAnimation(.easeIn(duration: half)) { transitionDip = 1 }
            DispatchQueue.main.asyncAfter(deadline: .now() + half) {
                coordinatorBox.setView(newView, size: CGSize(width: 2732, height: 1366))
                withAnimation(.easeOut(duration: half)) { transitionDip = 0 }
            }
        }
        .sheet(isPresented: $showPause) {
            PauseMenuView(session: session, isPresented: $showPause)
        }
        .statusBarHidden(true)
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

    /// F-024: chevrons rotate within the zone only; single-view zones show none.
    /// F-025 interim: idle visibility raised from 40% bare glyphs to 65% on a soft
    /// scrim disc (final treatment pending the Section 7 Rev-2 addendum).
    @ViewBuilder
    private var navigationChevrons: some View {
        if session.hasViewNavigation {
            HStack {
                chevronButton(systemName: "chevron.left") { session.previousView() }
                Spacer()
                chevronButton(systemName: "chevron.right") { session.nextView() }
            }
            .padding(.horizontal, 10)
        }
    }

    private func chevronButton(systemName: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: systemName)
                .font(.system(size: 28, weight: .medium))
                .foregroundColor(Color(white: 0.95).opacity(0.65))
                .frame(width: 44, height: 44)
                .background(Circle().fill(Color.black.opacity(0.35)))
        }
        .accessibilityLabel(systemName == "chevron.left" ? "Previous view" : "Next view")
        .accessibilityIdentifier(systemName == "chevron.left" ? "nav-previous" : "nav-next")
    }

}

/// Interim z2 exit (see comment at the call site). Down-chevron = "step back", the
/// same grammar as leaving a close-up. Hidden while a close-up is open (which has
/// its own down-chevron — observing the coordinator keeps that in sync).
private struct ZoneExitHost: View {
    @ObservedObject var coordinator: RoomSceneCoordinator
    let barHeight: CGFloat
    let onExit: () -> Void

    var body: some View {
        if coordinator.activeCloseUp == nil {
            VStack {
                Spacer()
                HStack {
                    Button(action: onExit) {
                        Image(systemName: "chevron.down")
                            .font(.system(size: 26, weight: .medium))
                            .foregroundColor(Color(white: 0.95).opacity(0.65))
                            .frame(width: 44, height: 44)
                            .background(Circle().fill(Color.black.opacity(0.35)))
                    }
                    .accessibilityLabel("Leave the workshop")
                    .accessibilityIdentifier("zone-exit")
                    .padding(.leading, 10)
                    .padding(.bottom, barHeight + 12)
                    Spacer()
                }
            }
        }
    }
}

/// Observes the active coordinator and presents its requested close-up.
private struct CloseUpHost: View {
    @ObservedObject var coordinator: RoomSceneCoordinator
    let bottomInset: CGFloat

    var body: some View {
        if let request = coordinator.activeCloseUp {
            CloseUpView(coordinator: coordinator, request: request, bottomInset: bottomInset)
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
        self.coordinator = RoomSceneCoordinator(viewID: session.currentView, state: session.state,
                                                size: CGSize(width: 2732, height: 1366),
                                                interaction: session.interaction)
        wireNavigation(coordinator)
    }

    func setView(_ viewID: ViewID, size: CGSize) {
        guard coordinator.viewID != viewID else { return }
        let next = RoomSceneCoordinator(viewID: viewID, state: session.state, size: size,
                                        interaction: session.interaction)
        wireNavigation(next)
        coordinator = next
    }

    private func wireNavigation(_ coordinator: RoomSceneCoordinator) {
        coordinator.onNavigate = { [weak self] viewID in
            self?.session.goTo(viewID)
        }
    }
}
