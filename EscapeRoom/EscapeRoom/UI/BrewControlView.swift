import SwiftUI

/// Interactive overlay for the cauldron brewing procedure (p14). Ingredients are added
/// by arming them in the inventory bar and tapping the cauldron (select-then-tap);
/// this view supplies the two parameterized controls: flame stage (bellows pump,
/// cycles 1->2->3->1) and stir direction/count, plus the explicit "resolve" action so
/// the player commits deliberately rather than the brew silently evaluating mid-gesture.
///
/// F-013(a) clarity pass (feedback round 1): controls are grouped under FLAME and STIR
/// headers, the flame stage renders as I/II/III pips matching the cauldron's rim
/// runes (not just a number), the stir tally shows its direction arrow, and Release
/// Ladle is disabled until at least one stir so its role ("commit the stir") reads.
struct BrewControlView: View {
    @ObservedObject var state: GameState
    var onOutcome: (PuzzleEngine.BrewOutcome) -> Void
    /// Reports each stir so the brew close-up can draw the directional ripple trail
    /// (Playtest R3: CW vs CCW must be unmistakable).
    var onStir: (BrewSolution.StirDirection) -> Void = { _ in }

    @State private var pendingStirDirection: BrewSolution.StirDirection?
    @State private var pendingStirCount: Int = 0

    var body: some View {
        VStack(spacing: 18) {
            // -- Flame --
            VStack(spacing: 8) {
                sectionHeader("FLAME")
                HStack(spacing: 14) {
                    Button(action: pumpBellows) {
                        Label("Pump Bellows", systemImage: "wind")
                    }
                    .buttonStyle(.chromePrimary)
                    .accessibilityIdentifier("brew-pump")

                    flameStagePips
                }
            }

            // -- Stir --
            VStack(spacing: 8) {
                sectionHeader("STIR")
                HStack(spacing: 14) {
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
                }
                stirTally
            }

            Button(action: resolve) {
                Label("Release Ladle", systemImage: "hand.raised")
            }
            .buttonStyle(.chromePrimary)
            .disabled(pendingStirDirection == nil)
            .opacity(pendingStirDirection == nil ? 0.4 : 1.0)
            .accessibilityIdentifier("brew-release")
        }
        .padding(20)
    }

    private func sectionHeader(_ text: String) -> some View {
        Text(text)
            .font(.caption2.weight(.semibold))
            .kerning(2)
            .foregroundColor(Chrome.textPrimary.opacity(0.55))
    }

    /// Flame stage as the rim-rune numerals I/II/III (matches the lit ember channel
    /// on the cauldron art — the color-blind-safe stage cue), not a bare number.
    private var flameStagePips: some View {
        let stage = state.data.cauldronFlameStage
        return HStack(spacing: 10) {
            ForEach(1...3, id: \.self) { s in
                Text(["I", "II", "III"][s - 1])
                    .font(.system(.footnote, design: .serif).weight(s == stage ? .bold : .regular))
                    .foregroundColor(s == stage ? Color(red: 0.95, green: 0.65, blue: 0.3)
                                                : Chrome.textPrimary.opacity(0.35))
                    // Secondary non-color cue: the active numeral is underlined.
                    .underline(s == stage)
            }
        }
        .accessibilityLabel("Flame stage \(stage)")
        .accessibilityIdentifier("brew-flame-stage")
    }

    /// Stir tally with its direction arrow, so "what have I entered so far" reads.
    private var stirTally: some View {
        HStack(spacing: 6) {
            if let direction = pendingStirDirection {
                Image(systemName: direction == .counterclockwise ? "arrow.counterclockwise" : "arrow.clockwise")
                    .font(.footnote)
                Text("\(pendingStirCount) \(pendingStirCount == 1 ? "turn" : "turns")")
                    .font(.footnote)
            } else {
                Text("not stirred")
                    .font(.footnote)
                    .opacity(0.5)
            }
        }
        .foregroundColor(Chrome.textPrimary)
        .accessibilityIdentifier("brew-stir-tally")
    }

    private func pumpBellows() {
        let next = (state.data.cauldronFlameStage % 3) + 1
        state.setCauldronFlameStage(next)
        SoundManager.shared.play(.bellows) // air puff, not the generic click (F-005)
    }

    private func stir(_ direction: BrewSolution.StirDirection) {
        if pendingStirDirection != direction {
            pendingStirDirection = direction
            pendingStirCount = 0
        }
        pendingStirCount += 1
        SoundManager.shared.play(.stir) // liquid swish (F-005)
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
        case .fizzle: SoundManager.shared.play(.fizzle) // the gray puff's own hiss
        case .notReady: break
        }
        pendingStirDirection = nil
        pendingStirCount = 0
        onOutcome(outcome)
    }
}
