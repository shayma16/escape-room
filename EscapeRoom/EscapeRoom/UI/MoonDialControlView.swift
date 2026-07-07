import SwiftUI

/// Interactive row of the three moon-phase trapdoor dials (p02), presented inside the
/// dial-panel close-up (QA-BUG-010: the dials live behind the rug discovery, never as
/// floating chrome over the hearth). Each dial cycles independently through the 8
/// embossed phases; the trapdoor opens the moment all three dials match the fixed
/// solution — evaluated fresh after every single dial change (never gated on which
/// dial was turned last), matching the "dials retain position, no lockout" behavior.
///
/// Sizing is supplied by the close-up so the Section 8 / A5-R5 legibility floor
/// (each dial face >= 30% of screen width on the smallest iPhone) holds (QA-BUG-011).
struct MoonDialRowView: View {
    @ObservedObject var state: GameState
    let dialSize: CGFloat

    var body: some View {
        HStack(spacing: dialSize * 0.05) {
            ForEach(0..<3, id: \.self) { dialIndex in
                dialControl(dialIndex)
            }
        }
    }

    private func dialControl(_ index: Int) -> some View {
        let phaseRaw = state.data.moonDialPositions[index]
        let phase = MoonDialSolution.clockwiseOrder[phaseRaw % MoonDialSolution.clockwiseOrder.count]
        return VStack(spacing: 6) {
            // Fixed marker: the phase under this notch is the dial's current value.
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: max(dialSize * 0.08, 12)))
                .foregroundColor(Color(white: 0.9).opacity(0.8))
            Button {
                advance(dial: index)
            } label: {
                GameImage(name: "dial-face")
                    .aspectRatio(contentMode: .fit)
                    .frame(width: dialSize, height: dialSize)
                    // The dial-face sprite carries the 8 phases CLOCKWISE from top
                    // (new at 0 deg, waxing crescent at +45 deg, ...). Bringing phase
                    // p under the top marker therefore rotates the disc by -45 * p
                    // degrees. (The previous build rotated +45 * p, which presented
                    // the MIRRORED phase — waxing/waning swapped — a solvability bug
                    // masked by QA-BUG-022's black scenes; fixed in the QA fix pass.)
                    .rotationEffect(.degrees(Double(phaseRaw) * -45))
                    .background(Circle().fill(Color.black.opacity(0.25)))
            }
            .accessibilityLabel("Dial \(index + 1), \(phase.rawValue)")
            .accessibilityIdentifier("moon-dial-\(index + 1)")
        }
    }

    private func advance(dial index: Int) {
        let current = state.data.moonDialPositions[index]
        let next = (current + 1) % MoonDialSolution.clockwiseOrder.count
        state.setMoonDialPosition(dial: index, phase: next)
        SoundManager.shared.play(.tick) // dial ratchet, not the generic click (F-005)
        if PuzzleEngine.evaluateMoonDials(state: state) {
            SoundManager.shared.play(.unlock)
        }
    }
}
