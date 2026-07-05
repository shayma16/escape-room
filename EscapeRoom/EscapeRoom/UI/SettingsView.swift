import SwiftUI

/// Settings per Section 5.4: Sound toggle, Reset Progress (destructive, confirmed),
/// About, version footer (read from the bundle, never hardcoded).
struct SettingsView: View {
    @State private var soundOn: Bool = SoundManager.shared.soundOn
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var resetVersion = 0

    var body: some View {
        ZStack {
            Chrome.backdrop.ignoresSafeArea()
            VStack(spacing: 0) {
                List {
                    Section {
                        HStack {
                            Image(systemName: soundOn ? "speaker.wave.2" : "speaker.slash")
                                .foregroundColor(Chrome.textPrimary)
                            Text("Sound")
                                .foregroundColor(Chrome.textPrimary)
                            Spacer()
                            Toggle("", isOn: $soundOn)
                                .labelsHidden()
                                .tint(Chrome.accent)
                                .onChange(of: soundOn) { newValue in
                                    SoundManager.shared.soundOn = newValue
                                }
                        }
                        .frame(minHeight: 52)

                        Button(role: .destructive) {
                            showResetConfirm = true
                        } label: {
                            HStack {
                                Image(systemName: "trash").foregroundColor(Chrome.destructive)
                                Text("Reset Progress").foregroundColor(Chrome.destructive)
                                Spacer()
                            }
                        }
                        .frame(minHeight: 52)

                        Button {
                            showAbout = true
                        } label: {
                            HStack {
                                Image(systemName: "info.circle").foregroundColor(Chrome.textPrimary)
                                Text("About").foregroundColor(Chrome.textPrimary)
                                Spacer()
                                Image(systemName: "chevron.right").foregroundColor(Chrome.textSecondary)
                            }
                        }
                        .frame(minHeight: 52)
                    }
                    .listRowBackground(Chrome.surface)
                }
                .scrollContentBackground(.hidden)

                Text(versionString)
                    .font(.footnote)
                    .foregroundColor(Chrome.textSecondary)
                    .padding(.bottom, 24)
            }
        }
        .navigationTitle("Settings")
        .alert("Reset all progress?", isPresented: $showResetConfirm) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                SaveGameStore.shared.resetAllProgress()
                resetVersion += 1
            }
        } message: {
            Text("Every level returns to unsolved. This can't be undone.")
        }
        .sheet(isPresented: $showAbout) {
            AboutView()
        }
    }

    private var versionString: String {
        let shortVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0"
        let buildNumber = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "1"
        return "Version \(shortVersion) (\(buildNumber))"
    }
}

struct AboutView: View {
    var body: some View {
        ZStack {
            Chrome.backdrop.ignoresSafeArea()
            VStack(alignment: .leading, spacing: 16) {
                Text("The Wizard's Cabin")
                    .font(.chromeTitle())
                    .foregroundColor(Chrome.textPrimary)
                Text("An escape-room adventure. Find your way out of the abandoned wizard's cabin.")
                    .font(.body)
                    .foregroundColor(Chrome.textSecondary)
                Text("Credits")
                    .font(.headline)
                    .foregroundColor(Chrome.textPrimary)
                    .padding(.top, 8)
                Text("Original functional sound effects and ambience synthesized in-house (see implementation notes for details). Art generated with Flux 2 Pro.")
                    .font(.footnote)
                    .foregroundColor(Chrome.textSecondary)
                Spacer()
            }
            .padding(32)
        }
    }
}
