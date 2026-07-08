import SwiftUI
import UIKit

/// Level Select -> level transition per Section 6: 700ms dip-to-black with vignette
/// close, hold ~150ms while the scene loads, then fade up on the level's opening view.
/// Respects Reduce Motion by using a simple opacity fade of the same duration.
struct LevelLoadingView: View {
    let levelID: Int
    @State private var session: LevelSession?
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        // QA-B3-001: as a NavigationStack destination this screen was proposed a SQUARE
        // (side = screen height) on the CI simulators, collapsing the game + chrome into a
        // left-anchored square with a dead black band. SwiftUI `.frame(maxWidth:.infinity)`
        // cannot fix that — it only fills WITHIN a squeezed proposal. `FullWindowFrame`
        // reads the true hosting-window bounds (ground truth) and pins the content to
        // exactly that size, so the proposal can no longer box the level into a square.
        FullWindowFrame {
            ZStack {
                Color.black.ignoresSafeArea()
                if let session {
                    GameRoomView(session: session)
                        .opacity(opacity)
                }
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            let newSession = LevelSession(levelID: levelID)
            session = newSession
            let dipDuration = reduceMotion ? 0.3 : 0.7
            DispatchQueue.main.asyncAfter(deadline: .now() + dipDuration + 0.15) {
                withAnimation(.easeIn(duration: dipDuration)) {
                    opacity = 1
                }
                // F-002: one soft diegetic entry swell, then the whisper-level zone
                // bed (near-silence with sparse texture — see SoundManager notes).
                SoundManager.shared.play(.entry)
                SoundManager.shared.setAmbientZone(.z1)
            }
        }
    }
}

/// QA-B3-001 hard override (see the body comment above). Reads the TRUE full window bounds
/// straight from the hosting `UIWindow` — independent of any SwiftUI proposal — and pins
/// its content to exactly that size, re-reading on any bounds change (rotation / size
/// class), so the content fills the entire landscape window edge-to-edge on every device.
struct FullWindowFrame<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var windowSize: CGSize = .zero

    var body: some View {
        content()
            .frame(width: windowSize.width == 0 ? nil : windowSize.width,
                   height: windowSize.height == 0 ? nil : windowSize.height)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(WindowBoundsReader { size in
                if windowSize != size { windowSize = size }
            })
            .ignoresSafeArea()
    }
}

/// Reports the hosting `UIWindow`'s bounds (the true full-screen size) up to SwiftUI,
/// tracking changes across layout passes (rotation / size-class).
private struct WindowBoundsReader: UIViewRepresentable {
    let onChange: (CGSize) -> Void

    func makeUIView(context: Context) -> BoundsView {
        let v = BoundsView()
        v.onChange = onChange
        v.backgroundColor = .clear
        v.isUserInteractionEnabled = false
        return v
    }

    func updateUIView(_ uiView: BoundsView, context: Context) {
        uiView.onChange = onChange
        uiView.reportIfNeeded()
    }

    final class BoundsView: UIView {
        var onChange: ((CGSize) -> Void)?
        private var last: CGSize = .zero

        override func didMoveToWindow() {
            super.didMoveToWindow()
            reportIfNeeded()
        }

        override func layoutSubviews() {
            super.layoutSubviews()
            reportIfNeeded()
        }

        func reportIfNeeded() {
            // The window is landscape-locked and full-screen (Info.plist
            // UIRequiresFullScreen), so its bounds are the exact size the game should fill.
            guard let size = window?.bounds.size, size.width > 0, size.height > 0 else { return }
            guard size != last else { return }
            last = size
            DispatchQueue.main.async { [weak self] in self?.onChange?(size) }
        }
    }
}
