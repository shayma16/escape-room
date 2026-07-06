import SwiftUI

@main
struct EscapeRoomApp: App {
    init() {
        // UI-test hook: a deterministic fresh save for the scripted full playthrough
        // (QA test-infrastructure request 1). No effect outside the UITest launch.
        if CommandLine.arguments.contains("-resetSave") {
            SaveGameStore.shared.resetAllProgress()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .preferredColorScheme(.dark)
        }
    }
}
