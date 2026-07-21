import SwiftUI

/// Level Select -> level transition per Section 6: 700ms dip-to-black with vignette
/// close, hold ~150ms while the scene loads, then fade up on the level's opening view.
/// Respects Reduce Motion by using a simple opacity fade of the same duration.
///
/// Routes to the correct level's room view: Level 1 uses GameRoomView/LevelSession; Level 2
/// "The Clockmaker's Attic" uses Level2RoomView/L2LevelSession. Both reuse the shared
/// GameState/SaveGameStore persistence + chrome; only the room stack differs.
struct LevelLoadingView: View {
    let levelID: Int
    @State private var session: LevelSession?
    @State private var l2Session: L2LevelSession?
    @State private var opacity: Double = 0
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            if levelID == 2 {
                if let l2Session {
                    Level2RoomView(session: l2Session).opacity(opacity)
                }
            } else if let session {
                GameRoomView(session: session).opacity(opacity)
            }
        }
        .navigationBarHidden(true)
        .onAppear {
            if levelID == 2 { l2Session = L2LevelSession() } else { session = LevelSession(levelID: levelID) }
            let dipDuration = reduceMotion ? 0.3 : 0.7
            DispatchQueue.main.asyncAfter(deadline: .now() + dipDuration + 0.15) {
                withAnimation(.easeIn(duration: dipDuration)) { opacity = 1 }
                SoundManager.shared.enterLevel(levelID: levelID)
            }
        }
    }
}
