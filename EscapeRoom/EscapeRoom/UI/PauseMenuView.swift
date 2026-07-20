import SwiftUI

/// Pause Menu per Section 5.3: Resume, Restart Level, Settings, Main Menu, in that
/// order, floating on a scrim over the frozen scene. Restart Level requires
/// confirmation (destructive-adjacent, loses in-level progress); Main Menu does not,
/// because in-level state persists per the requirement-based state model (J5) — every
/// mutation in GameState is persisted immediately (see SaveGameStore), so there is no
/// transient state that would be silently lost by backgrounding to the menu.
struct PauseMenuView: View {
    /// Restart-this-level action, injected so the pause menu is level-agnostic (reused by
    /// both the Level 1 and Level 2 room views without depending on a concrete session type).
    let onRestart: () -> Void
    @Binding var isPresented: Bool
    @State private var showRestartConfirm = false
    @EnvironmentObject private var navigator: AppNavigator

    var body: some View {
        ZStack {
            // Full-window scrim (QA-B3-002): this view is now a full-screen overlay, not a
            // `.sheet`, so the scrim covers the whole game and the button column centers
            // in the safe area on every device (incl. landscape iPhone / Dynamic Island).
            Chrome.scrim.ignoresSafeArea()
                .contentShape(Rectangle())
                .onTapGesture { isPresented = false }

            VStack(spacing: 16) {
                // R3-001: quiet tactile menu click on each pause-menu button.
                Button(action: { SoundManager.shared.play(.menuConfirm); isPresented = false }) {
                    Label("Resume", systemImage: "play.fill")
                }
                .buttonStyle(.chromePrimary)

                Button(action: { SoundManager.shared.play(.menuConfirm); showRestartConfirm = true }) {
                    Label("Restart Level", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.chromePrimary)

                Button(action: { SoundManager.shared.play(.menuConfirm); presentSettings = true }) {
                    Label("Settings", systemImage: "gearshape")
                }
                .buttonStyle(.chromePrimary)

                Button(action: { SoundManager.shared.play(.menuConfirm); exitToMainMenu() }) {
                    Label("Main Menu", systemImage: "house")
                }
                .buttonStyle(.chromePrimary)
                .accessibilityIdentifier("pause-main-menu")
            }
            // Keep the whole column inside the safe area on notch/Dynamic-Island devices.
            .padding(.vertical, 24)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .alert("Restart level?", isPresented: $showRestartConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Restart") {
                onRestart()
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
        // R3-001: exitLevel() closes the level-music scope AND tears down music/ambience,
        // so the menu we return to is music-free (only menu SFX play in the chrome).
        SoundManager.shared.exitLevel()
        isPresented = false
        navigator.popToRoot()
    }

    @State private var presentSettings = false
}
