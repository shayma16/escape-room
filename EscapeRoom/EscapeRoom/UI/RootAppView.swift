import SwiftUI

/// Shared navigation model for the single app-lifetime NavigationStack. "Main Menu"
/// from anywhere (Pause, level completion) pops to root by clearing the path —
/// dismissing back to the EXISTING menu instead of stacking a new root over the live
/// game (QA-BUG-019 fix: no accumulated presentation stacks, no leaked LevelSessions,
/// and the level's ambient loop is stopped on the way out).
final class AppNavigator: ObservableObject {
    @Published var path = NavigationPath()

    func popToRoot() {
        path = NavigationPath()
    }
}

/// App root: always the Main Menu, hosting the one NavigationStack.
struct RootAppView: View {
    @StateObject private var navigator = AppNavigator()

    var body: some View {
        MainMenuView()
            .environmentObject(navigator)
    }
}
