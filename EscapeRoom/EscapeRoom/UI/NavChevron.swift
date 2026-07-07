import SwiftUI

/// Navigation chevrons per style-guide §7-R2 (Rev 2, feedback round 1 / F-025).
/// Series-seed convention: a bone-white chevron mark that is discoverable without
/// shouting — no box, no button plate, just a mark on the scene.
///
/// - Glyph: bone-white #F2F5F8, 2.5 pt stroke; 28 pt iPad / 24 pt iPhone.
/// - Idle: 70% opacity on a soft radial dark backing (44 pt, black @ 25% center -> 0),
///   holding >= 2 luminance steps against bright and dark plate regions.
/// - Idle breathing pulse: 70% -> 100% -> 70% over 2.4 s, continuous, ease-in-out.
/// - Close-up back affordance (§7-R2.4): a down-chevron, bottom-center, plays ONE
///   entrance accent (scale 1.0 -> 1.15 -> 1.0, 600 ms) on appear, then joins the pulse.
/// - Hit areas: side chevrons 56 x 88 pt; back chevron 88 x 56 pt.
enum NavChevron {
    static let boneWhite = Color(red: 0.949, green: 0.961, blue: 0.973) // #F2F5F8

    static func glyphSize(isPad: Bool) -> CGFloat { isPad ? 28 : 24 }

    /// Left/right side chevron (view cycling within a zone).
    static func sideButton(systemName: String, isPad: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            BreathingChevron(systemName: systemName, size: glyphSize(isPad: isPad))
                .frame(width: 56, height: 88)   // §7-R2.1 hit area
                .contentShape(Rectangle())
        }
        .accessibilityLabel(systemName == "chevron.left" ? "Previous view" : "Next view")
        .accessibilityIdentifier(systemName == "chevron.left" ? "nav-previous" : "nav-next")
    }

    /// Down-chevron back affordance for close-ups / inspect (§7-R2.4).
    static func dismissButton(action: @escaping () -> Void, isPad: Bool) -> some View {
        Button(action: action) {
            BreathingChevron(systemName: "chevron.down", size: glyphSize(isPad: isPad), entranceAccent: true)
                .frame(width: 88, height: 56)   // §7-R2.4 hit area
                .contentShape(Rectangle())
        }
        .accessibilityLabel("Back")
        .accessibilityIdentifier("closeup-dismiss")
    }
}

/// The chevron mark itself: radial dark backing + bone-white glyph, breathing pulse,
/// and an optional one-shot entrance accent for the close-up back affordance.
struct BreathingChevron: View {
    let systemName: String
    let size: CGFloat
    var entranceAccent: Bool = false

    @State private var pulse = false
    @State private var accentScale: CGFloat = 1.0

    var body: some View {
        ZStack {
            // §7-R2.2: soft radial dark backing (44 pt, black @ 25% center -> 0).
            RadialGradient(colors: [Color.black.opacity(0.25), Color.clear],
                           center: .center, startRadius: 0, endRadius: 22)
                .frame(width: 44, height: 44)
            Image(systemName: systemName)
                .font(.system(size: size, weight: .semibold))
                .foregroundColor(NavChevron.boneWhite)
                .opacity(pulse ? 1.0 : 0.70)     // §7-R2.3 breathing 70% <-> 100%
                .scaleEffect(accentScale)
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 1.2).repeatForever(autoreverses: true)) {
                pulse = true
            }
            if entranceAccent {
                // §7-R2.4: one entrance accent, scale 1.0 -> 1.15 -> 1.0 over 600 ms.
                withAnimation(.easeOut(duration: 0.3)) { accentScale = 1.15 }
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    withAnimation(.easeIn(duration: 0.3)) { accentScale = 1.0 }
                }
            }
        }
    }
}
