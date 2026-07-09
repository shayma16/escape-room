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
    /// R2-021: transient first-run directional hint (auto-hides). Near-wordless-safe —
    /// brief glyph+caption on scene entry, fades out; shown once per install.
    @State private var showNavHint = false
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @EnvironmentObject private var navigator: AppNavigator

    /// R2-008: navigation swipe threshold (points). Distinct from item-drag (removed) —
    /// this only cycles views, never moves items.
    private let swipeThreshold: CGFloat = 60

    init(session: LevelSession) {
        self.session = session
        self.gameState = session.state
        self.interaction = session.interaction
        _coordinatorBox = StateObject(wrappedValue: CoordinatorBox(session: session))
    }

    /// Reserved height under close-up content so nothing puzzle-critical sits behind the
    /// inventory pill (§7-R1.5 bottom-band rule: 72 pt iPad / 62 pt iPhone). This is the
    /// pill height (§7-R1.1: 64/56) plus its bottom inset, matching the §7-R1.5 band.
    private var barHeight: CGFloat { hSizeClass == .regular ? 72 : 62 }

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()

            SpriteKitContainerView(coordinator: coordinatorBox.coordinator)
                .ignoresSafeArea()
                .accessibilityIdentifier("room-scene")
                // R2-008: horizontal swipe cycles views within the zone (arrows STAY).
                // Only active when there IS view navigation and no close-up is open (a
                // close-up owns its own swipes, e.g. grimoire pages). Never moves items.
                .simultaneousGesture(viewCycleSwipe)

            navigationChevrons

            // Close-up / inspection layer (QA-BUG-013). Sits UNDER the inventory bar
            // (F-020) and keeps its content clear of it via bottomInset.
            CloseUpHost(coordinator: coordinatorBox.coordinator, bottomInset: barHeight)

            // Chrome above the close-up layer: pause glyph (top-left).
            VStack {
                HStack {
                    pauseButton
                    Spacer()
                }
                .padding(24)
                Spacer()
            }

            // Inventory pill (§7-R1): full-screen overlay, self-anchored bottom-center,
            // drawn above the close-up layer so it is live in EVERY close-up (§7-R1.5).
            InventoryBarView(state: session.state, interaction: interaction,
                             horizontalSizeClass_isPad: hSizeClass == .regular)

            // Interim diegetic-gap patch: z2 has no painted return door, so an exit
            // affordance stands in for "back through the rune door" until the Art
            // Director/asset pass supplies one (flagged in implementation notes).
            if session.currentView.zoneID == PuzzleGraph.ZoneID.z2Workshop {
                ZoneExitHost(coordinator: coordinatorBox.coordinator,
                             barHeight: barHeight) {
                    session.goTo(.study)
                }
            }

            // R2-023b: single-view zones (z3 cellar, z4 alcove) have no side chevrons, so
            // give a clear, always-visible EXIT affordance (the diegetic passage back)
            // rather than an undiscoverable tap-anywhere. Down-chevron = "step back".
            if let exitTarget = singleViewExitTarget {
                ZoneExitHost(coordinator: coordinatorBox.coordinator,
                             barHeight: barHeight) {
                    coordinatorBox.coordinator.exitSingleViewZone(to: exitTarget)
                }
            }

            // F-016: enlarged item inspect, over everything.
            if let inspecting = interaction.inspectingItem {
                ItemInspectView(itemID: inspecting) {
                    interaction.inspectingItem = nil
                }
            }

            // R2-021: transient first-run directional hint (auto-hides).
            if showNavHint {
                NavHintOverlay(hasSideNav: session.hasViewNavigation)
                    .allowsHitTesting(false)
                    .transition(.opacity)
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

            // Pause menu (QA-B3-002): presented as a FULL-SCREEN overlay inside the game
            // ZStack, not a `.sheet`. On a landscape iPhone / Dynamic Island device a
            // `.sheet` composes as a narrow partial page (buttons crammed bottom-left,
            // partially off-screen); a full-window overlay centers within the safe area
            // on every device, matching the completion card.
            if showPause {
                PauseMenuView(session: session, isPresented: $showPause)
                    .transition(.opacity)
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
        .statusBarHidden(true)
        .onAppear { maybeShowFirstRunHint() }
    }

    /// R2-008 swipe: horizontal drag past the threshold cycles views within the zone.
    /// Gated to multi-view zones with no open close-up (the close-up layer handles its
    /// own page swipes). This is navigation only — item-drag stays removed.
    private var viewCycleSwipe: some Gesture {
        DragGesture(minimumDistance: 24)
            .onEnded { value in
                guard session.hasViewNavigation,
                      coordinatorBox.coordinator.activeCloseUp == nil,
                      interaction.inspectingItem == nil else { return }
                let dx = value.translation.width
                guard abs(dx) > swipeThreshold, abs(dx) > abs(value.translation.height) else { return }
                if dx < 0 { session.nextView() } else { session.previousView() }
            }
    }

    /// R2-021: show the directional hint ONCE per install (near-wordless: brief, auto-
    /// hiding). Persisted via UserDefaults so it never becomes a permanent label.
    private func maybeShowFirstRunHint() {
        let key = "nav-hint-shown-v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        UserDefaults.standard.set(true, forKey: key)
        withAnimation(.easeIn(duration: 0.4)) { showNavHint = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.2) {
            withAnimation(.easeOut(duration: 0.6)) { showNavHint = false }
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

    /// R2-023b: for a single-view zone, the diegetic view the exit affordance returns to
    /// (cellar -> hearth up the ladder; alcove -> cellar through the shelf gap). nil in
    /// multi-view zones (which use side chevrons) — z1/z2 handled elsewhere.
    private var singleViewExitTarget: ViewID? {
        switch session.currentView {
        case .cellar: return .hearth
        case .alcove: return .cellar
        default: return nil
        }
    }

    /// F-024: chevrons rotate within the zone only; single-view zones show none.
    /// §7-R2 (Rev 2): bone-white breathing chevrons on a soft radial backing.
    @ViewBuilder
    private var navigationChevrons: some View {
        if session.hasViewNavigation {
            HStack {
                NavChevron.sideButton(systemName: "chevron.left", isPad: hSizeClass == .regular) {
                    session.previousView()
                }
                Spacer()
                NavChevron.sideButton(systemName: "chevron.right", isPad: hSizeClass == .regular) {
                    session.nextView()
                }
            }
            .padding(.horizontal, 8)
        }
    }

}

/// Interim z2 exit (see comment at the call site). Down-chevron = "step back", the
/// same grammar as leaving a close-up. Hidden while a close-up is open (which has
/// its own down-chevron — observing the coordinator keeps that in sync).
private struct ZoneExitHost: View {
    @ObservedObject var coordinator: RoomSceneCoordinator
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
                            .frame(width: 88, height: 56)
                            .contentShape(Rectangle())
                    }
                    .accessibilityLabel("Leave the workshop")
                    .accessibilityIdentifier("zone-exit")
                    .padding(.leading, 8)
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

/// R2-021 transient first-run hint. Near-wordless: directional glyphs with the briefest
/// caption, shown once and auto-hidden (never a persistent label). Honors the genre's
/// wordless direction by leaning on the SF-Symbol glyphs; the short words are a one-time
/// teaching aid the user explicitly asked for.
private struct NavHintOverlay: View {
    let hasSideNav: Bool

    var body: some View {
        VStack {
            Spacer()
            HStack(spacing: 28) {
                if hasSideNav {
                    hint("hand.draw", "swipe or tap to look around")
                }
                hint("hand.tap", "tap objects to interact")
            }
            .padding(.horizontal, 18)
            .padding(.vertical, 12)
            .background(Capsule().fill(Color.black.opacity(0.5)))
            .padding(.bottom, 96)
        }
        .frame(maxWidth: .infinity)
    }

    private func hint(_ symbol: String, _ text: String) -> some View {
        HStack(spacing: 8) {
            Image(systemName: symbol)
                .font(.system(size: 18, weight: .medium))
            Text(text)
                .font(.footnote)
        }
        .foregroundColor(NavChevron.boneWhite.opacity(0.92))
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
