import SwiftUI

/// Pause Menu per Section 5.3: Resume, Restart Level, Settings, Main Menu, in that
/// order, floating on a scrim over the frozen scene. Restart Level requires
/// confirmation (destructive-adjacent, loses in-level progress); Main Menu does not,
/// because in-level state persists per the requirement-based state model (J5) — every
/// mutation in GameState is persisted immediately (see SaveGameStore), so there is no
/// transient state that would be silently lost by backgrounding to the menu.
struct PauseMenuView: View {
    @ObservedObject var session: LevelSession
    @Binding var isPresented: Bool
    @State private var showRestartConfirm = false
    @EnvironmentObject private var navigator: AppNavigator

    var body: some View {
        ZStack {
            Chrome.scrim.ignoresSafeArea()
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                Button(action: { isPresented = false }) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.chromePrimary)

                Button(action: { showRestartConfirm = true }) {
                    Label("Restart Level", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.chromePrimary)

                Button(action: { presentSettings = true }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.chromePrimary)

                Button(action: exitToMainMenu) {
                    Label("Main Menu", systemImage: "house")
                }
                .buttonStyle(.chromePrimary)
                .accessibilityIdentifier("pause-main-menu")
            }
        }
        .alert("Restart level?", isPresented: $showRestartConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Restart") {
                session.restartLevel()
                isPresented = false
            }
        } message: {
            Text("Your progress in this level will be lost.")
        }
        .sheet(isPresented: $presentSettings) {
            NavigationStack {
                SettingsView()
            }
        }
    }

    /// QA-BUG-019 fix: pop the shared NavigationStack back to the existing Main Menu
    /// root (tearing down the level screen and its LevelSession) instead of covering
    /// the live game with a brand-new root; the level's ambient loop stops too. No
    /// confirmation, per J5 — every GameState mutation is already persisted.
    private func exitToMainMenu() {
        SoundManager.shared.stopAmbient()
        isPresented = false
        navigator.popToRoot()
    }

    @State private var presentSettings = false
}
