import SwiftUI
import SpriteKit

/// Thin SwiftUI wrapper presenting a RoomScene for the coordinator's current view.
/// Rebuilds the coordinator (and thus the SpriteKit scene) whenever `viewID` changes,
/// since each of the 11 views is its own SKScene per the architecture.
struct SpriteKitContainerView: UIViewRepresentable {
    @ObservedObject var coordinator: RoomSceneCoordinator

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.presentScene(coordinator.scene)
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== coordinator.scene {
            uiView.presentScene(coordinator.scene)
        }
    }
}
