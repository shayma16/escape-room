import SwiftUI

/// Level Select -> level transition per Section 6: 700ms dip-to-black with vignette
/// close, hold ~150ms while the scene loads, then fade up on the level's opening view.
/// Respects Reduce Motion by using a simple opacity fade of the same duration.
struct LevelLoadingView: View {
    let levelID: Int
    @State private var session: LevelSession?
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if let session {
                GameRoomView(session: session)
                    .opacity(opacity)
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
                // Build 10 (R4-002): level entry starts the looping music and NOTHING
                // else — the sfx-entry swell (the reported "ocean waves") and the
                // per-zone ambient beds are removed. R3-001: enterLevel() opens the
                // level-music scope (music is bound to the level scene lifecycle).
                SoundManager.shared.enterLevel()
            }
        }
    }
}
