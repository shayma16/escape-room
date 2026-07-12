import SwiftUI
import SpriteKit

/// Thin SwiftUI wrapper presenting a RoomScene for the coordinator's current view.
/// Also hands the coordinator a weak reference to the SKView so inventory-drop
/// coordinates can be converted EXACTLY via UIKit + SKScene.convertPoint(fromView:)
/// instead of a hand-rolled linear approximation (QA-BUG-014).
///
/// Render-loop throttling (build 10 CI-perf fix, run 29186397614): a point-and-click
/// room is a STATIC painting — the only scene motion is the 150 ms tap pulse and the
/// occasional overlay swap — yet SKView's default render loop rasterizes the full scene
/// (base plate + every overlay) at 60 fps forever. On the software-rendered CI simulator
/// the 13-inch iPad canvas (2064x2752 px) made that a constant CPU tax that, combined
/// with the un-cached SwiftUI image decodes (GameAssetLoader), progressively starved the
/// main thread until XCUITest tap delivery broke down (the study→entry nav tap that
/// wedged the build-10 iPad run was synthesized correctly but never took effect).
///
/// - Idle scenes render at 30 fps: visually indistinguishable for static art + a soft
///   pulse, and half the render load (also a straight battery win on device).
/// - While a close-up is OPEN the scene drops to 1 fps: the room is behind a 92% black
///   scrim and fully non-interactive; the SwiftUI close-up layer owns the screen. The
///   node tree still updates normally (overlay/state changes made from inside close-ups
///   render on the next tick and instantly on dismiss, when 30 fps resumes).
struct SpriteKitContainerView: UIViewRepresentable {
    @ObservedObject var coordinator: RoomSceneCoordinator

    static let idleFPS = 30
    static let coveredFPS = 1

    func makeUIView(context: Context) -> SKView {
        let view = SKView()
        view.ignoresSiblingOrder = true
        view.preferredFramesPerSecond = Self.idleFPS
        // Fill the SKView itself with the chrome dark-neutral backdrop (#101010) so any
        // uncovered edge reads as intentional framing, matching the app background.
        view.backgroundColor = UIColor(red: 0x10/255.0, green: 0x10/255.0, blue: 0x10/255.0, alpha: 1)
        view.presentScene(coordinator.scene)
        coordinator.skView = view
        return view
    }

    func updateUIView(_ uiView: SKView, context: Context) {
        if uiView.scene !== coordinator.scene {
            uiView.presentScene(coordinator.scene)
        }
        // Throttle while covered by the close-up layer (this view observes the
        // coordinator, so updateUIView re-runs whenever activeCloseUp changes).
        uiView.preferredFramesPerSecond =
            coordinator.activeCloseUp == nil ? Self.idleFPS : Self.coveredFPS
        coordinator.skView = uiView
    }
}
