import SwiftUI

/// Bottom-edge inventory bar per style guide Section 7: aged dark-oak strip, 96pt tall
/// iPad / 72pt iPhone, horizontal scroll if overfull, no labels.
///
/// Feedback round 1 — SELECT-THEN-TAP ONLY (user design decision 2026-07-07):
/// - Tap an item to ARM it (it lifts with the pale silver ring — the armed state);
///   tap it again to disarm. Tapping a target hotspot (or an open close-up's plate)
///   while armed USES the item there. Drag-to-use is gone.
/// - Arming/disarming is silent (F-019: no generic selection sound; the visual armed
///   state is the feedback).
/// - Tapping a SECOND item while one is armed attempts the classic combine gesture
///   (`ItemCombinations`, p12); non-combinable pairs just move the armed selection.
/// - An armed item shows a small magnifier badge; tapping the badge (or long-pressing
///   any item) opens the enlarged inspect view (F-016 — universal, all items).
///
/// The bar is reachable in EVERY close-up (F-020 systemic fix): GameRoomView layers it
/// above the close-up layer.
struct InventoryBarView: View {
    @ObservedObject var state: GameState
    @ObservedObject var interaction: InteractionModel

    var horizontalSizeClass_isPad: Bool

    private var barHeight: CGFloat { horizontalSizeClass_isPad ? 96 : 72 }

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 14) {
                ForEach(sortedInventory, id: \.self) { itemID in
                    itemIcon(itemID)
                }
            }
            .padding(.horizontal, 16)
        }
        .frame(height: barHeight)
        .background(
            LinearGradient(colors: [Color(red: 0.14, green: 0.10, blue: 0.07),
                                     Color(red: 0.09, green: 0.06, blue: 0.04)],
                           startPoint: .top, endPoint: .bottom)
        )
        .overlay(Rectangle().frame(height: 1).foregroundColor(.black.opacity(0.4)), alignment: .top)
        .accessibilityIdentifier("inventory-bar")
    }

    private var sortedInventory: [String] {
        // Stable order: catalog declaration order, filtered to held items.
        ItemCatalog.all.map(\.id).filter { state.inventory.contains($0) }
    }

    @ViewBuilder
    private func itemIcon(_ itemID: String) -> some View {
        let def = ItemCatalog.definition(for: itemID)
        let isArmed = interaction.armedItem == itemID
        ZStack(alignment: .topTrailing) {
            GameImage(name: def?.iconAsset ?? "icon-poker")
                .aspectRatio(contentMode: .fit)
                .frame(width: barHeight - 24, height: barHeight - 24)
                .padding(6)
                .overlay(
                    Circle()
                        .stroke(Color(white: 0.85).opacity(isArmed ? 0.9 : 0), lineWidth: 2)
                )
                .offset(y: isArmed ? -4 : 0)
                .animation(.easeOut(duration: 0.12), value: isArmed)
                .contentShape(Rectangle())
                .frame(minWidth: 44, minHeight: 44)
                .onTapGesture { handleTap(itemID) }
                .onLongPressGesture(minimumDuration: 0.45) { inspect(itemID) }
                .accessibilityLabel(def?.name ?? "Item")
                .accessibilityIdentifier("inventory-\(itemID)")

            // F-016: the armed item's dedicated inspect affordance.
            if isArmed {
                Button(action: { inspect(itemID) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 13, weight: .semibold))
                        .foregroundColor(Color(white: 0.92))
                        .padding(5)
                        .background(Circle().fill(Color.black.opacity(0.65)))
                }
                .offset(x: 6, y: -10)
                .accessibilityLabel("Inspect \(def?.name ?? "item")")
                .accessibilityIdentifier("inspect-\(itemID)")
            }
        }
        .zIndex(isArmed ? 1 : 0)
    }

    private func handleTap(_ itemID: String) {
        if let armed = interaction.armedItem, armed != itemID {
            // Combine attempt (p12 and any future data-driven pair).
            let combinable = ItemCombinations.pairToPuzzle[Set([armed, itemID])] != nil
            if combinable, ItemCombinations.combine(armed, itemID, state: state) {
                SoundManager.shared.play(.solve)
                interaction.disarm()
                return
            }
            // No combination: the armed selection just moves. Silent (F-019).
            interaction.armedItem = itemID
        } else {
            // Arm, or disarm on the second tap. Silent (F-019).
            interaction.armedItem = (interaction.armedItem == itemID) ? nil : itemID
        }
    }

    private func inspect(_ itemID: String) {
        interaction.inspectingItem = itemID
    }
}

/// F-016: enlarged inspect view so items are identifiable. Universal — every item
/// shows its icon art enlarged; items with a dedicated inspection plate (the rusted
/// key's snapped plain bit, the graph's red-herring fairness valve) show that plate
/// instead. Near-wordless per the genre decision: art only, no text label.
struct ItemInspectView: View {
    let itemID: String
    let onDismiss: () -> Void

    /// Items with a full inspection plate (overrides the enlarged icon).
    private static let inspectionPlates: [String: String] = [
        PuzzleGraph.ItemID.rustedKey: "cu-rusted-key"
    ]

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
                .onTapGesture { onDismiss() }

            GeometryReader { geo in
                let def = ItemCatalog.definition(for: itemID)
                let side = min(geo.size.width, geo.size.height) * 0.62
                GameImage(name: Self.inspectionPlates[itemID] ?? def?.iconAsset ?? "icon-poker")
                    .aspectRatio(contentMode: .fit)
                    .frame(maxWidth: Self.inspectionPlates[itemID] != nil ? geo.size.width * 0.86 : side,
                           maxHeight: Self.inspectionPlates[itemID] != nil ? geo.size.height * 0.86 : side)
                    .position(x: geo.size.width / 2, y: geo.size.height / 2)
                    .allowsHitTesting(false)
            }

            VStack {
                Spacer()
                Button(action: onDismiss) {
                    Image(systemName: "chevron.down")
                        .font(.system(size: 30, weight: .medium))
                        .foregroundColor(Color(white: 0.92).opacity(0.85))
                        .frame(width: 64, height: 44)
                        .background(Capsule().fill(Color.black.opacity(0.45)))
                }
                .padding(.bottom, 12)
                .accessibilityLabel("Back")
                .accessibilityIdentifier("inspect-dismiss")
            }
        }
        .accessibilityIdentifier("item-inspect")
    }
}
