import SwiftUI

/// Main Menu per global-ui-style.md Section 5.1: flat backdrop, faint keyhole watermark,
/// serif title, two-button column (Play, Settings). No level art here.
struct MainMenuView: View {
    var body: some View {
        NavigationStack {
            ZStack {
                Chrome.backdrop.ignoresSafeArea()

                Image("keyhole-emblem")
                    .resizable()
                    .renderingMode(.template)
                    .aspectRatio(contentMode: .fit)
                    .foregroundColor(.white.opacity(0.08))
                    .frame(width: 420, height: 420)

                VStack(spacing: 40) {
                    Text("The Wizard's Cabin")
                        .font(.chromeTitle())
                        .foregroundColor(Chrome.textPrimary)
                        .multilineTextAlignment(.center)
                        .padding(.top, 48)

                    Spacer()

                    VStack(spacing: 16) {
                        NavigationLink(destination: LevelSelectView()) {
                            Label("Play", systemImage: "play.fill")
                        }
                        .buttonStyle(.chromePrimary)

                        NavigationLink(destination: SettingsView()) {
                            Label("Settings", systemImage: "gearshape")
                        }
                        .buttonStyle(.chromePrimary)
                    }

                    Spacer()
                    Spacer()
                }
            }
            .navigationBarHidden(true)
        }
        .preferredColorScheme(.dark) // J2: fixed dark-only appearance
    }
}
