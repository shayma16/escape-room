import SwiftUI

/// App root: always the Main Menu. Used both as the initial scene root and as the
/// target of "Pause -> Main Menu" (Section 5.3) via fullScreenCover, so returning to
/// the menu always starts from a clean navigation stack.
struct RootAppView: View {
    var body: some View {
        MainMenuView()
    }
}
