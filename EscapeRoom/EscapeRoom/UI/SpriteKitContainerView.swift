import SwiftUI
import SpriteKit

/// Thin SwiftUI wrapper presenting a RoomScene for the coordinator's current view.
/// Also hands the coordinator a weak reference to the SKView so inventory-drop
/// coordinates can be converted EXACTLY via UIKit + SKScene.convertPoint(fromView:)
/// instead of a hand-rolled linear approximation (QA-BUG-014).
///
/// QA-B3-001 (viewport fix, 2026-07-09): the scene was rendering into a left-anchored
/// SQUARE viewport (side = screen HEIGHT) with a dead black band on the trailing edge
/// (iPad ~25 %, iPhone SE ~44 %, Dynamic Island ~54 %). Root cause: SwiftUI's
/// `UIViewRepresentable` sizing proposed a SQUARE frame to the bare `SKView` (SKView has
/// no intrinsic content size, and inside the NavigationStack host chain the proposed size
/// collapsed to a height×height square), so `.aspectFill` filled a square SKView instead
/// of the full landscape window. The base `SpriteView`/`SKView` then centered the 2:1
/// plate inside that square and cropped it.
///
/// Fix: drive the SKView frame from an explicit `GeometryReader` full-proposed size (the
/// real landscape window rect) and pin the SKView with `autoresizingMask` so it always
/// tracks its host bounds. The scene KEEPS its fixed 2732×1366 authoring size with
/// `.aspectFill`, so SpriteKit scales + centers it to fill the (now full-window) SKView
/// edge-to-edge. Plate-normalized hotspots and the UI-test `sceneCoordinate(_:_:_:)`
/// full-frame `.aspectFill(2732×1366)` math therefore map 1:1 onto the full window with
/// NO change — the only bug was the square SKView frame; the scene math was always right.
struct SpriteKitContainerView: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        GeometryReader { geo in
            SpriteKitContainerRepresentable(coordinator: coordinator, size: geo.size)
        }
    }
}

private struct SpriteKitContainerRepresentable: UIViewRepresentable {
    @ObservedObject var coordinator: RoomSceneCoordinator
    /// The FULL landscape size proposed by the GeometryReader (the real window rect),
    /// not the collapsed square SwiftUI otherwise hands a bare SKView.
    let size: CGSize

    func makeUIView(context: Context) -> SKView {
        let view = SKView(frame: CGRect(origin: .zero, size: size))
        view.ignoresSiblingOrder = true
        // Track the host bounds so a rotation / safe-area / size-class change keeps the
        // SKView full-window (QA-B3-001: never let it collapse to a square again).
        view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        applySize(size, to: view)
        view.presentScene(coordinator.scene)
        coordinator.skView = view
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== coordinator.scene {
            uiView.presentScene(coordinator.scene)
        }
        applySize(size, to: uiView)
        coordinator.skView = uiView
    }

    /// Force the SKView frame to the full landscape rect. The scene keeps its fixed
    /// 2732×1366 `.aspectFill` size, so SpriteKit fills the full-window SKView edge-to-
    /// edge (centered) — never a left-pinned square (QA-B3-001).
    private func applySize(_ size: CGSize, to view: SKView) {
        guard size.width > 0, size.height > 0 else { return }
        if view.bounds.size != size {
            view.frame = CGRect(origin: .zero, size: size)
        }
    }
}
