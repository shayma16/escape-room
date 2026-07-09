import SwiftUI
import SpriteKit

/// Thin SwiftUI wrapper presenting a RoomScene for the coordinator's current view.
/// Also hands the coordinator a weak reference to the SKView so inventory-drop
/// coordinates can be converted EXACTLY via UIKit + SKScene.convertPoint(fromView:)
/// instead of a hand-rolled linear approximation (QA-BUG-014).
///
/// QA-B3-001 fix: a bare `SKView()` handed to SwiftUI's `UIViewRepresentable` sizing was
/// presenting its scene while its bounds were still square/zero, and `.aspectFill` then
/// locked the scene's viewport to a height×height SQUARE that never grew when the view
/// later filled the full landscape window — so the room art rendered in a left square with
/// a dead black band (the SKView element reported full width to XCUITest, but its rendered
/// scene viewport stayed square). Fix: size the SKView explicitly from the GeometryReader's
/// full landscape proposal, pin it with `autoresizingMask`, and (re)present / re-fit the
/// scene ONLY once the view has real full-window bounds. The scene keeps its fixed
/// 2732×1366 `.aspectFill` size, so it now fills the full landscape SKView edge-to-edge.
struct SpriteKitContainerView: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        GeometryReader { geo in
            SpriteKitHostView(coordinator: coordinator, size: geo.size)
        }
    }
}

private struct SpriteKitHostView: UIViewRepresentable {
    @ObservedObject var coordinator: RoomSceneCoordinator
    /// Full landscape size proposed by the GeometryReader (the real window rect), not the
    /// square SwiftUI otherwise hands a bare SKView.
    let size: CGSize

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: CGRect(origin: .zero, size: resolved(size)))
        view.ignoresSiblingOrder = true
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        coordinator.skView = view
        // Present only once we have real (non-empty) bounds so the scene's viewport is not
        // locked to a square/zero initial frame (QA-B3-001).
        if view.bounds.width > 0, view.bounds.height > 0 {
            view.presentScene(coordinator.scene)
        }
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        let target = resolved(size)
        if uiView.bounds.size != target, target.width > 0, target.height > 0 {
            uiView.frame = CGRect(origin: .zero, size: target)
        }
        // Present (or re-present) now that the view has real full-window bounds; also handle
        // a coordinator/scene swap.
        if uiView.scene !== coordinator.scene, uiView.bounds.width > 0, uiView.bounds.height > 0 {
            uiView.presentScene(coordinator.scene)
        }
        coordinator.skView = uiView
    }

    /// Guard against a zero proposal (can happen on the very first layout pass): fall back
    /// to the main screen bounds so the SKView never comes up empty/square.
    private func resolved(_ proposed: CGSize) -> CGSize {
        if proposed.width > 0, proposed.height > 0 { return proposed }
        let screen = UIScreen.main.bounds.size
        return screen.width > 0 ? screen : CGSize(width: 1, height: 1)
    }
}
