import SwiftUI
import UIKit

/// QA-B3-001 root cause + fix. On the CI simulators the app came up with a PORTRAIT
/// interface even though the Info.plist declares landscape-only, so the game + chrome
/// composed into a rotated, min-dimension square with a large dead black band in the
/// screenshot. SwiftUI's `WindowGroup` + `@UIApplicationDelegateAdaptor` was not reliably
/// forcing the interface orientation on the (portrait-booted) simulator.
///
/// Fix: drive the app from a UIKit `UIApplicationDelegate` + `UIWindowSceneDelegate` and
/// host the SwiftUI root in a `LandscapeHostingController` whose
/// `supportedInterfaceOrientations` is `.landscape` — the canonical, reliable way to lock a
/// SwiftUI app to landscape. The delegate also reports `.landscape` app-wide and requests a
/// landscape geometry update on connect, so the interface is landscape on every host. This
/// makes the window landscape-sized and the game fills it edge-to-edge.
@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        // UI-test hook: a deterministic fresh save for the scripted full playthrough.
        if CommandLine.arguments.contains("-resetSave") {
            SaveGameStore.shared.resetAllProgress()
        }
        return true
    }

    /// App-wide landscape lock (authoritative at runtime, not just Info.plist).
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?)
    -> UIInterfaceOrientationMask {
        .landscape
    }

    func application(_ application: UIApplication,
                     configurationForConnecting connectingSceneSession: UISceneSession,
                     options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        let config = UISceneConfiguration(name: "Main", sessionRole: connectingSceneSession.role)
        config.delegateClass = SceneDelegate.self
        return config
    }
}

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let root = LandscapeHostingController(rootView: RootAppView().preferredColorScheme(.dark))
        root.overrideUserInterfaceStyle = .dark

        let window = UIWindow(windowScene: windowScene)
        window.rootViewController = root
        window.makeKeyAndVisible()
        self.window = window

        // Force landscape at connect (the interface can come up portrait on a portrait-
        // booted simulator; this rotates it to landscape immediately — QA-B3-001).
        let pref = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
        windowScene.requestGeometryUpdate(pref) { _ in }
        root.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}

/// SwiftUI-hosting controller locked to landscape (QA-B3-001). Overriding
/// `supportedInterfaceOrientations` here is the reliable lock the SwiftUI-only path missed.
final class LandscapeHostingController<Content: View>: UIHostingController<Content> {
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask { .landscape }
    override var preferredInterfaceOrientationForPresentation: UIInterfaceOrientation { .landscapeRight }
    override var shouldAutorotate: Bool { true }
}
