import SwiftUI

/// Settings per Section 5.4 (Rev, R2-006): TWO independent audio toggles —
/// Ambiance/Music and Sound Effects — plus Reset Progress (destructive, confirmed),
/// About, version footer (read from the bundle, never hardcoded).
struct SettingsView: View {
    @State private var ambianceOn: Bool = SoundManager.shared.ambianceEnabled
    @State private var sfxOn: Bool = SoundManager.shared.sfxEnabled
    @State private var showResetConfirm = false
    @State private var showAbout = false
    @State private var resetVersion = 0

    var body: some View {
        ZStack {
            Chrome.backdrop.ignoresSafeArea()
            VStack(spacing: 0) {
                List {
                    Section {
                        // R2-006 toggle 1: ambiance + music.
                        HStack {
                            Image(systemName: ambianceOn ? "speaker.wave.2" : "speaker.slash")
                                .foregroundColor(Chrome.textPrimary)
                            Text("Music & Ambiance")
                                .foregroundColor(Chrome.textPrimary)
                            Spacer()
                            Toggle("", isOn: $ambianceOn)
                                .labelsHidden()
                                .tint(Chrome.accent)
                                .onChange(of: ambianceOn) { newValue in
                                    SoundManager.shared.ambianceEnabled = newValue
                                }
                        }
                        .frame(minHeight: 52)
                        .accessibilityIdentifier("settings-ambiance-toggle")

                        // R2-006 toggle 2: sound effects (interaction cues).
                        HStack {
                            Image(systemName: sfxOn ? "speaker.wave.2.fill" : "speaker.slash.fill")
                                .foregroundColor(Chrome.textPrimary)
                            Text("Sound Effects")
                                .foregroundColor(Chrome.textPrimary)
                            Spacer()
                            Toggle("", isOn: $sfxOn)
                                .labelsHidden()
                                .tint(Chrome.accent)
                                .onChange(of: sfxOn) { newValue in
                                    SoundManager.shared.sfxEnabled = newValue
                                }
                        }
                        .frame(minHeight: 52)
                        .accessibilityIdentifier("settings-sfx-toggle")

                        Button(role: .destructive) {
                            // R4-003: consistent soft ping across all menu chrome.
                            SoundManager.shared.play(.menuConfirm)
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
                            SoundManager.shared.play(.menuConfirm) // R4-003
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
