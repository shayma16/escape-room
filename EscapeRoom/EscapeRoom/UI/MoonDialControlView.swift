import SwiftUI

/// Interactive overlay for the three moon-phase trapdoor dials (p02). Each dial cycles
/// independently through the 8 embossed phases (clockwise order fixed by the dial-face
/// sprite); the trapdoor opens the moment all three dials match the fixed solution —
/// evaluated fresh after every single dial change (never gated on which dial was turned
/// last), matching the "dials retain position, no lockout" failure behavior.
struct MoonDialControlView: View {
    @ObservedObject var state: GameState
    var onSolved: () -> Void

    var body: some View {
        HStack(spacing: 24) {
            ForEach(0..<3, id: \.self) { dialIndex in
                dialControl(dialIndex)
            }
        }
        .padding(20)
        .background(Chrome.surface.opacity(0.001)) // hit-test container only, no visual chrome bleed into game art
    }

    private func dialControl(_ index: Int) -> some View {
        let phaseRaw = state.data.moonDialPositions[index]
        let phase = MoonDialSolution.clockwiseOrder[phaseRaw % MoonDialSolution.clockwiseOrder.count]
        return VStack(spacing: 8) {
            Button {
                advance(dial: index)
            } label: {
                GameImage(name: "dial-face")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 84, height: 84)
                    .rotationEffect(.degrees(Double(phaseRaw) * 45))
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }
            .frame(minWidth: 44, minHeight: 44)
            .accessibilityLabel("Dial \(index + 1), \(phase.rawValue)")
        }
    }

    private func advance(dial index: Int) {
        let current = state.data.moonDialPositions[index]
        let next = (current + 1) % MoonDialSolution.clockwiseOrder.count
        state.setMoonDialPosition(dial: index, phase: next)
        SoundManager.shared.play(.click)
        if PuzzleEngine.evaluateMoonDials(state: state) {
            SoundManager.shared.play(.unlock)
            onSolved()
        }
    }
}
