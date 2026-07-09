import SwiftUI
import UIKit

@main
struct EscapeRoomApp: App {
    // QA-B3-001: on the CI simulators (and any host that boots portrait) the app window came
    // up PORTRAIT despite the Info.plist landscape lock, so the game screen was laid out into
    // a min-dimension square with a large dead black band. The AppDelegate below makes the
    // landscape lock AUTHORITATIVE at runtime; RootAppView additionally requests a landscape
    // geometry update on appear (see OrientationLock), forcing the window to true landscape
    // dimensions so the game fills it edge-to-edge on every host.
    @UIApplicationDelegateAdaptor(AppDelegate.self) private var appDelegate

    init() {
        // UI-test hook: a deterministic fresh save for the scripted full playthrough
        // (QA test-infrastructure request 1). No effect outside the UITest launch.
        if CommandLine.arguments.contains("-resetSave") {
            SaveGameStore.shared.resetAllProgress()
        }
    }

    var body: some Scene {
        WindowGroup {
            RootAppView()
                .preferredColorScheme(.dark)
                .modifier(OrientationLock())
        }
    }
}

/// Landscape lock enforcement (J6 / QA-B3-001). The Info.plist keys declare landscape-only,
/// but a portrait-booted simulator can still bring the window up portrait; this delegate
/// makes the lock authoritative at runtime.
final class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication,
                     supportedInterfaceOrientationsFor window: UIWindow?)
    -> UIInterfaceOrientationMask {
        .landscape
    }
}

/// Actively requests a LANDSCAPE geometry update (iOS 16+ official API) whenever the view
/// appears / the app becomes active, forcing the window to landscape dimensions even when
/// the host booted portrait (QA-B3-001). No-op once already landscape.
private struct OrientationLock: ViewModifier {
    func body(content: Content) -> some View {
        content
            .onAppear(perform: requestLandscape)
            .onReceive(NotificationCenter.default.publisher(
                for: UIApplication.didBecomeActiveNotification)) { _ in
                requestLandscape()
            }
    }

    private func requestLandscape() {
        guard let scene = UIApplication.shared.connectedScenes
            .compactMap({ $0 as? UIWindowScene })
            .first(where: { $0.activationState == .foregroundActive })
            ?? UIApplication.shared.connectedScenes.compactMap({ $0 as? UIWindowScene }).first
        else { return }
        let pref = UIWindowScene.GeometryPreferences.iOS(interfaceOrientations: .landscape)
        scene.requestGeometryUpdate(pref) { _ in }
        scene.keyWindow?.rootViewController?.setNeedsUpdateOfSupportedInterfaceOrientations()
    }
}
