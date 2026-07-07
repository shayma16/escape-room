import SwiftUI

/// Inventory bar per style-guide §7-R1 (Rev 2, feedback round 1): the aged-oak strip is
/// retired for a content-hugging translucent dark PILL in the global-chrome register — a
/// piece of glass over the painting, never a hole in it. Auto-collapses to nothing when
/// empty. Horizontal scroll inside the pill past 70% screen width.
///
/// SELECT-THEN-TAP ONLY (user decision 2026-07-07):
/// - Tap an item to ARM it (cell backing lightens, item lifts 4 pt, pale silver ring —
///   §7-R1.4, a pure-luminance grayscale-safe cue); tap it again to disarm. Tapping a
///   target hotspot (or an open close-up's plate) while armed USES the item. No drag.
/// - Arming/disarming is silent (F-019: the visual armed state is the feedback).
/// - Tapping a SECOND item while one is armed attempts the combine gesture
///   (`ItemCombinations`, p12); non-combinable pairs just move the armed selection.
/// - Tapping the ARMED cell again opens the enlarged inspect view (§7-R1.4 / §7-R3);
///   long-press any cell also inspects (F-016 — universal, all items).
///
/// The bar is reachable in EVERY close-up (§7-R1.5 / F-020): GameRoomView layers it
/// above the close-up layer, same pill, same position.
struct InventoryBarView: View {
    @ObservedObject var state: GameState
    @ObservedObject var interaction: InteractionModel

    var horizontalSizeClass_isPad: Bool

    // §7-R1.1 geometry.
    private var barHeight: CGFloat { horizontalSizeClass_isPad ? 64 : 56 }
    private var cellSize: CGFloat { horizontalSizeClass_isPad ? 56 : 46 }
    private var cellGap: CGFloat { horizontalSizeClass_isPad ? 10 : 8 }
    private var endPadding: CGFloat { horizontalSizeClass_isPad ? 12 : 10 }
    private var cornerRadius: CGFloat { horizontalSizeClass_isPad ? 16 : 14 }
    private var bottomInset: CGFloat { horizontalSizeClass_isPad ? 8 : 6 }

    var body: some View {
        GeometryReader { geo in
            // §7-R1.3: empty inventory = NO bar at all; slides/fades in on first pickup.
            if !sortedInventory.isEmpty {
                pill(maxWidth: geo.size.width * 0.70)
                    .frame(maxWidth: .infinity, alignment: .center)
                    .padding(.bottom, bottomInset)   // safe-area handled by the reader itself
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: sortedInventory)
    }

    private func pill(maxWidth: CGFloat) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: cellGap) {
                ForEach(sortedInventory, id: \.self) { itemID in
                    itemCell(itemID)
                }
            }
            .padding(.horizontal, endPadding)
            .frame(height: barHeight)
        }
        .frame(height: barHeight)
        .frame(maxWidth: maxWidth)
        .fixedSize(horizontal: true, vertical: false)   // §7-R1.1: content-hugging, no dead surface
        .background(
            // §7-R1.2: #14161A at 62% over a light background blur; hairline #F2F5F8 @ 8%.
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(red: 0.078, green: 0.086, blue: 0.102).opacity(0.62))
                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: cornerRadius))
                .overlay(
                    RoundedRectangle(cornerRadius: cornerRadius)
                        .stroke(Color(red: 0.949, green: 0.961, blue: 0.973).opacity(0.08), lineWidth: 1)
                )
        )
        .accessibilityIdentifier("inventory-bar")
    }

    private var sortedInventory: [String] {
        // Stable order: catalog declaration order, filtered to held items.
        ItemCatalog.all.map(\.id).filter { state.inventory.contains($0) }
    }

    @ViewBuilder
    private func itemCell(_ itemID: String) -> some View {
        let def = ItemCatalog.definition(for: itemID)
        let isArmed = interaction.armedItem == itemID
        ZStack {
            // §7-R1.4: armed backing lightens to #F2F5F8 @ 16%.
            RoundedRectangle(cornerRadius: cornerRadius - 4)
                .fill(Color(red: 0.949, green: 0.961, blue: 0.973).opacity(isArmed ? 0.16 : 0))
            GameImage(name: def?.iconAsset ?? "icon-poker")
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .overlay(
                    // Existing pale-silver ring treatment (pure luminance, CB-safe).
                    Circle().stroke(Color(red: 0.949, green: 0.961, blue: 0.973).opacity(isArmed ? 0.9 : 0), lineWidth: 2)
                )
                .offset(y: isArmed ? -4 : 0)   // §7-R1.4: item lifts 4 pt
        }
        .frame(width: cellSize, height: cellSize)
        .frame(minWidth: 44, minHeight: 44)     // hit area >= 44 pt (48 padded on iPhone by cellSize+gap)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.12), value: isArmed)
        .onTapGesture { handleTap(itemID) }
        .onLongPressGesture(minimumDuration: 0.45) { inspect(itemID) }
        .accessibilityLabel(def?.name ?? "Item")
        .accessibilityIdentifier("inventory-\(itemID)")
        // §7-R1.4: a second tap on the armed cell inspects (F-016). Kept as a discrete,
        // testable affordance too, so XCUITest can reach inspect deterministically.
        .overlay(alignment: .topTrailing) {
            if isArmed {
                Button(action: { inspect(itemID) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.949, green: 0.961, blue: 0.973))
                        .padding(4)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .offset(x: 4, y: -6)
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
        } else if interaction.armedItem == itemID {
            // §7-R1.4: a second tap on the ALREADY-armed cell opens inspect (tap = arm,
            // tap again = look closer). One gesture family. Silent (F-019).
            inspect(itemID)
        } else {
            // Arm. Silent (F-019).
            interaction.armedItem = itemID
        }
    }

    private func inspect(_ itemID: String) {
        interaction.inspectingItem = itemID
    }
}

/// Enlarged item inspect per style-guide §7-R3 (Rev 2, F-016). Universal — every item
/// shows its RGBA cutout enlarged, floating alone "examined by moonlight": full-screen
/// scrim #0B0D10 @ 78%, a faint radial parchment-white glow at 6% peak behind the item
/// (luminance separation, grayscale-safe), no card/border/label. Items with a dedicated
/// inspection plate (the rusted key's snapped plain bit, the red-herring fairness valve)
/// show that plate instead. Dismissal does NOT disarm (the armed item is unaffected —
/// this view is presented over the armed inventory pill), so inspect never costs a step.
struct ItemInspectView: View {
    let itemID: String
    let onDismiss: () -> Void

    /// Items with a full inspection plate (overrides the enlarged icon).
    private static let inspectionPlates: [String: String] = [
        PuzzleGraph.ItemID.rustedKey: "cu-rusted-key"
    ]

    var body: some View {
        ZStack {
            // §7-R3: scrim #0B0D10 @ 78%.
            Color(red: 0.043, green: 0.051, blue: 0.063).opacity(0.78).ignoresSafeArea()
                .onTapGesture { onDismiss() }        // §7-R3: tap anywhere dismisses

            GeometryReader { geo in
                let def = ItemCatalog.definition(for: itemID)
                let hasPlate = Self.inspectionPlates[itemID] != nil
                // §7-R3: item cutout at ~60% of screen height.
                let side = min(geo.size.width, geo.size.height * 0.60)
                ZStack {
                    // Faint radial parchment-white glow at 6% peak (lifts dark items off scrim).
                    RadialGradient(colors: [Color(red: 0.96, green: 0.95, blue: 0.90).opacity(0.06),
                                            Color.clear],
                                   center: .center, startRadius: 0, endRadius: side * 0.7)
                        .frame(width: side * 1.4, height: side * 1.4)
                        .allowsHitTesting(false)
                    GameImage(name: Self.inspectionPlates[itemID] ?? def?.iconAsset ?? "icon-poker")
                        .aspectRatio(contentMode: .fit)
                        .frame(maxWidth: hasPlate ? geo.size.width * 0.86 : side,
                               maxHeight: hasPlate ? geo.size.height * 0.86 : side * 1.0)
                        .allowsHitTesting(false)
                }
                .position(x: geo.size.width / 2, y: geo.size.height / 2)
            }

            // §7-R2.4/§7-R3: standard down-chevron, bottom-center.
            VStack {
                Spacer()
                NavChevron.dismissButton(action: onDismiss, isPad: true)
                    .padding(.bottom, 12)
                    .accessibilityIdentifier("inspect-dismiss")
            }
        }
        .transition(.opacity)
        .accessibilityIdentifier("item-inspect")
    }
}
