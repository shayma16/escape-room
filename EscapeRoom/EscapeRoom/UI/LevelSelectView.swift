import SwiftUI

/// Level Select per Section 5.2: level cards with thumbnail art (J3), completion badge
/// (checkmark shape + fixed top-trailing position, never color-only), locked state
/// (dim + lock.fill + disabled tap). Entitlement-gated per level (currently always
/// unlocked, structured for future IAP without rearchitecting).
struct LevelSelectView: View {
    @Environment(\.horizontalSizeClass) private var hSizeClass
    @State private var completionVersion = 0 // bump to force re-read of SaveGameStore

    private let levels: [LevelMeta] = [
        LevelMeta(id: 1, title: "The Wizard's Cabin", thumbnail: "level1-thumb"),
        LevelMeta(id: 2, title: "The Clockmaker's Attic", thumbnail: "level2-thumb")
    ]

    var body: some View {
        ZStack {
            Chrome.backdrop.ignoresSafeArea()
            ScrollView {
                LazyVGrid(columns: gridColumns, spacing: 24) {
                    ForEach(levels) { level in
                        LevelCardView(level: level, isPad: hSizeClass == .regular)
                    }
                }
                .padding(24)
            }
        }
        .navigationTitle("")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                EmptyView() // back chevron supplied automatically by NavigationStack
            }
        }
        .onAppear { completionVersion += 1 }
    }

    private var gridColumns: [GridItem] {
        let count = hSizeClass == .regular ? 4 : 2
        return Array(repeating: GridItem(.flexible(), spacing: 24), count: count)
    }
}

struct LevelMeta: Identifiable {
    let id: Int
    let title: String
    let thumbnail: String
}

private struct LevelCardView: View {
    let level: LevelMeta
    let isPad: Bool

    private var isUnlocked: Bool { Entitlements.isLevelUnlocked(level.id) }
    private var isComplete: Bool { SaveGameStore.shared.isLevelComplete(level.id) }

    private var cardSize: CGSize { isPad ? CGSize(width: 220, height: 165) : CGSize(width: 150, height: 112) }

    var body: some View {
        // Value-based link into the app's single NavigationStack (QA-BUG-019): the
        // level screen is pushed onto the shared path, so "Main Menu" can pop to the
        // existing root instead of covering it.
        NavigationLink(value: level.id) {
            ZStack(alignment: .topTrailing) {
                RoundedRectangle(cornerRadius: 16)
                    .fill(Chrome.surface)
                    .overlay(RoundedRectangle(cornerRadius: 16).stroke(Chrome.stroke, lineWidth: 1))

                VStack(spacing: 0) {
                    thumbnailImage
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    Spacer(minLength: 0)
                }

                LinearGradient(colors: [.clear, Chrome.surface], startPoint: .center, endPoint: .bottom)
                    .frame(height: cardSize.height * 0.4)
                    .frame(maxHeight: .infinity, alignment: .bottom)
                    .clipShape(RoundedRectangle(cornerRadius: 16))

                // R4-001 (standing instruction, R3-003 completion): the card label reads
                // "Level 1" — the WORD plus the serif Arabic numeral, never a bare "1".
                Text("Level \(level.id)")
                    .font(.chromeLevelNumber())
                    .foregroundColor(isUnlocked ? Chrome.textPrimary : Chrome.disabled)
                    .padding(8)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottomLeading)
                    .padding(.leading, 8)
                    .accessibilityIdentifier("level-card-\(level.id)-label")

                if isComplete {
                    ZStack {
                        Circle().fill(Chrome.backdrop)
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(Chrome.textPrimary)
                    }
                    .frame(width: isPad ? 24 : 20, height: isPad ? 24 : 20)
                    .padding(6)
                    .accessibilityLabel("Level \(level.id), completed.")
                }

                if !isUnlocked {
                    Image(systemName: "lock.fill")
                        .font(.system(size: 28))
                        .foregroundColor(Chrome.disabled)
                }
            }
            .frame(width: cardSize.width, height: cardSize.height)
            .opacity(isUnlocked ? 1.0 : 0.35)
        }
        .disabled(!isUnlocked)
        .buttonStyle(.plain)
        // R3-001: entering a level is a MAJOR action -> subtle confirm tone (the level
        // music itself starts later, when the level scene appears — never in the menu).
        .simultaneousGesture(TapGesture().onEnded {
            if isUnlocked { SoundManager.shared.play(.menuConfirm) }
        })
        .accessibilityLabel(isUnlocked ? (isComplete ? "Level \(level.id), completed." : "Level \(level.id)") : "Level \(level.id), locked.")
        .accessibilityIdentifier(isComplete ? "level-card-\(level.id)-complete" : "level-card-\(level.id)")
    }

    @ViewBuilder
    private var thumbnailImage: some View {
        if UIImage(named: level.thumbnail) != nil {
            Image(level.thumbnail)
                .resizable()
                .aspectRatio(contentMode: .fill)
        } else {
            Chrome.surface
                .overlay(Text("Level \(level.id)").font(.chromeLevelNumber()).foregroundColor(Chrome.textSecondary))
        }
    }
}
