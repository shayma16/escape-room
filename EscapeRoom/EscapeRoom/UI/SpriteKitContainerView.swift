import SwiftUI
import SpriteKit

/// Thin SwiftUI wrapper presenting a RoomScene for the coordinator's current view.
/// Also hands the coordinator a weak reference to the SKView so inventory-drop
/// coordinates can be converted EXACTLY via UIKit + SKScene.convertPoint(fromView:)
/// instead of a hand-rolled linear approximation (QA-BUG-014).
struct SpriteKitContainerView: UIViewRepresentable {
    @ObservedObject var coordinator: RoomSceneCoordinator

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.presentScene(coordinator.scene)
        coordinator.skView = view
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== coordinator.scene {
            uiView.presentScene(coordinator.scene)
        }
        coordinator.skView = uiView
    }
}
