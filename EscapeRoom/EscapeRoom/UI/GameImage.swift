import SwiftUI

/// SwiftUI image view for loose game-art files resolved via GameAssetLoader (see that
/// type's doc comment for why these aren't in the Xcode asset catalog). Falls back to
/// a neutral placeholder rectangle if the named asset can't be found, so a missing/
/// renamed asset never crashes the UI — it just becomes visibly blank, which is
/// preferable to a hard failure in a shipping game.
struct GameImage: View {
    let name: String

    var body: some View {
        if let uiImage = GameAssetLoader.shared.image(named: name) {
            Image(uiImage: uiImage)
                .resizable()
        } else {
            Color.gray.opacity(0.2)
        }
    }
}
