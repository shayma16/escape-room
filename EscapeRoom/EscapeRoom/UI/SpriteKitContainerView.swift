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
        // INTERIM iPad LETTERBOX (build 9 follow-up): under `.aspectFit` the scene does not
        // cover the whole SKView on iPad (bars top+bottom). Fill the SKView itself with the
        // chrome dark-neutral backdrop (#101010) so the letterbox bars read as intentional
        // framing, matching the app background — not stark black.
        view.backgroundColor = UIColor(red: 0x10/255.0, green: 0x10/255.0, blue: 0x10/255.0, alpha: 1)
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
