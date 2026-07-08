import SwiftUI

/// Theme-independent global UI chrome tokens per specs/global-ui-style.md Section 2.
/// Hue-neutral darks; never restyled per level.
enum Chrome {
    static let backdrop = Color(red: 0x10/255, green: 0x10/255, blue: 0x10/255)
    static let scrim = Color.black.opacity(0.55)
    static let surface = Color(red: 0x1C/255, green: 0x1C/255, blue: 0x1E/255)
    static let surfaceRaised = Color(red: 0x2C/255, green: 0x2C/255, blue: 0x2E/255)
    static let stroke = Color.white.opacity(0.12)
    static let textPrimary = Color(red: 0xED/255, green: 0xED/255, blue: 0xEA/255)
    static let textSecondary = Color(red: 0x9A/255, green: 0x9A/255, blue: 0x96/255)
    static let disabled = Color(red: 0x5A/255, green: 0x5A/255, blue: 0x58/255)
    static let accent = Color(red: 0xC9/255, green: 0xCD/255, blue: 0xD2/255)
    static let destructive = Color.red
}

/// Primary capsule menu button per Section 4.1.
struct ChromePrimaryButtonStyle: ButtonStyle {
    var isDestructive: Bool = false
    @Environment(\.horizontalSizeClass) private var hSizeClass

    func makeBody(configuration: Configuration) -> some View {
        let isPad = hSizeClass == .regular
        configuration.label
            .font(.headline)
            .foregroundColor(isDestructive ? Chrome.destructive : Chrome.textPrimary)
            // QA-B3-002: the label must never truncate ("Main Men" / "Play Agai"). Pin it
            // to a single line at its natural width so the capsule grows to fit the text
            // instead of clipping it, and keep the minWidth only as a lower bound.
            .lineLimit(1)
            .fixedSize(horizontal: true, vertical: false)
            .padding(.horizontal, 32)
            .frame(minWidth: isPad ? 220 : 200, minHeight: isPad ? 56 : 50)
            .background(
                Capsule()
                    .fill(configuration.isPressed ? Chrome.surfaceRaised : Chrome.surface)
            )
            .overlay(Capsule().stroke(Chrome.stroke, lineWidth: 1))
            .scaleEffect(configuration.isPressed ? 0.97 : 1.0)
            .animation(.easeOut(duration: 0.12), value: configuration.isPressed)
    }
}

extension ButtonStyle where Self == ChromePrimaryButtonStyle {
    static var chromePrimary: ChromePrimaryButtonStyle { ChromePrimaryButtonStyle() }
    static var chromeDestructive: ChromePrimaryButtonStyle { ChromePrimaryButtonStyle(isDestructive: true) }
}

/// Serif title font per Section 3 (New York / system serif) — game title, level numbers.
extension Font {
    static func chromeTitle() -> Font {
        .system(.largeTitle, design: .serif).weight(.medium)
    }
    static func chromeLevelNumber() -> Font {
        .system(.title2, design: .serif)
    }
}
