import SwiftUI

/// Interactive overlay for the cauldron brewing procedure (p14). Ingredients are added
/// by dragging them onto the cauldron hotspot (handled by RoomSceneCoordinator); this
/// view supplies the two remaining parameterized controls: flame stage (floor bellows
/// pump, cycles 1->2->3->1) and stir direction/count (ladle drag), plus the explicit
/// "resolve" action so the player commits deliberately rather than the brew silently
/// evaluating mid-gesture.
struct BrewControlView: View {
    @ObservedObject var state: GameState
    var onOutcome: (PuzzleEngine.BrewOutcome) -> Void
    /// Reports each stir so the brew close-up can draw the directional ripple trail
    /// (Playtest R3: CW vs CCW must be unmistakable).
    var onStir: (BrewSolution.StirDirection) -> Void = { _ in }

    @State private var pendingStirDirection: BrewSolution.StirDirection?
    @State private var pendingStirCount: Int = 0

    var body: some View {
        VStack(spacing: 16) {
            HStack(spacing: 20) {
                Button(action: pumpBellows) {
                    Label("Pump Bellows", systemImage: "flame")
                }
                .buttonStyle(.chromePrimary)
                .accessibilityIdentifier("brew-pump")

                Text("Flame stage \(state.data.cauldronFlameStage)")
                    .foregroundColor(Chrome.textPrimary)
                    .font(.footnote)
            }

            HStack(spacing: 20) {
                Button(action: { stir(.counterclockwise) }) {
                    Label("Stir CCW", systemImage: "arrow.counterclockwise")
                }
                .buttonStyle(.chromePrimary)
                .accessibilityIdentifier("brew-stir-ccw")

                Button(action: { stir(.clockwise) }) {
                    Label("Stir CW", systemImage: "arrow.clockwise")
                }
                .buttonStyle(.chromePrimary)
                .accessibilityIdentifier("brew-stir-cw")

                Text("\(pendingStirCount) turns")
                    .foregroundColor(Chrome.textPrimary)
                    .font(.footnote)
            }

            Button(action: resolve) {
                Label("Release Ladle", systemImage: "checkmark")
            }
            .buttonStyle(.chromePrimary)
            .accessibilityIdentifier("brew-release")
        }
        .padding(20)
    }

    private func pumpBellows() {
        let next = (state.data.cauldronFlameStage % 3) + 1
        state.setCauldronFlameStage(next)
        SoundManager.shared.play(.click)
    }

    private func stir(_ direction: BrewSolution.StirDirection) {
        if pendingStirDirection != direction {
            pendingStirDirection = direction
            pendingStirCount = 0
        }
        pendingStirCount += 1
        SoundManager.shared.play(.click)
        onStir(direction)
    }

    private func resolve() {
        guard let direction = pendingStirDirection else { return }
        let outcome = PuzzleEngine.resolveBrew(flameStage: state.data.cauldronFlameStage,
                                                stirDirection: direction,
                                                stirCount: pendingStirCount,
                                                state: state)
        switch outcome {
        case .success: SoundManager.shared.play(.solve)
        case .fizzle: SoundManager.shared.play(.wrong)
        case .notReady: break
        }
        pendingStirDirection = nil
        pendingStirCount = 0
        onOutcome(outcome)
    }
}
