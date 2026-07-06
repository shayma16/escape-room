import SwiftUI

/// Main Menu per global-ui-style.md Section 5.1: flat backdrop, faint keyhole watermark,
/// serif title, two-button column (Play, Settings). No level art here.
///
/// Title note (QA-BUG-021): the global UI spec calls for the GAME title here, and the
/// final app name is still an open Producer item; the menu reads the bundle display
/// name so renaming the app automatically renames the menu (single source of truth).
struct MainMenuView: View {
    @EnvironmentObject private var navigator: AppNavigator

    var body: some View {
        NavigationStack(path: $navigator.path) {
            ZStack {
                Chrome.backdrop.ignoresSafeArea()

                Image("keyhole-emblem")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white.opacity(0.08))
                    .frame(width: 420, height: 420)

                VStack(spacing: 40) {
                    Text(gameTitle)
                        .font(.chromeTitle())
                        .foregroundColor(Chrome.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 48)

                    Spacer()

                    VStack(spacing: 16) {
                        NavigationLink(value: MenuDestination.levelSelect) {
                            Label("Play", systemImage: "play.fill")
                        }
                        .buttonStyle(.chromePrimary)
                        .accessibilityIdentifier("menu-play")

                        NavigationLink(value: MenuDestination.settings) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .buttonStyle(.chromePrimary)
                        .accessibilityIdentifier("menu-settings")
                    }

                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
            .navigationDestination(for: MenuDestination.self) { destination in
                switch destination {
                case .levelSelect: LevelSelectView()
                case .settings: SettingsView()
                }
            }
            .navigationDestination(for: Int.self) { levelID in
                LevelLoadingView(levelID: levelID)
            }
        }
        .preferredColorScheme(.dark) // J2: fixed dark-only appearance
    }

    private var gameTitle: String {
        (Bundle.main.infoDictionary?["CFBundleDisplayName"] as? String) ?? "The Wizard's Cabin"
    }
}

enum MenuDestination: Hashable {
    case levelSelect
    case settings
}
