import Foundation
import SwiftUI

/// Inventory bar per style-guide §7-R1 (Rev 2, feedback round 1): the aged-oak strip is
/// retired for a content-hugging translucent dark PILL in the global-chrome register — a
/// piece of glass over the painting, never a hole in it. Auto-collapses to nothing when
/// empty. Horizontal scroll inside the pill past 70% screen width.
///
/// SELECT-THEN-TAP ONLY (user decision 2026-07-07), armed-item model per build-10
/// cluster F (R4-005):
/// - Tap an item to ARM it (cell backing lightens, item lifts 4 pt, pale silver ring —
///   §7-R1.4 — plus an explicit ✕ badge). Tapping a target hotspot (or an open
///   close-up's plate) while armed USES the item. No drag.
/// - DISARM is trivially discoverable, three ways: tap the ARMED cell again, tap the
///   ✕ badge on it, or tap any empty scene/scrim space (handled by the coordinator /
///   close-up layer). A failed use keeps the item armed (R2-030) but never blocks
///   looks/close-ups (coordinator fall-through).
/// - Inspect (F-016): long-press any cell, or the magnifier badge on the armed cell.
/// - Tapping a SECOND item while one is armed attempts the combine gesture
///   (`ItemCombinations`, p12); non-combinable pairs just move the armed selection.
/// - Arming/disarming is silent (F-019: the visual armed state is the feedback).
///
/// R4-029 (user option (a), 2026-07-11): the combine affordance on a combinable target
/// is LOUD — a larger, pulsing link badge over a stronger amber backing — plus a
/// one-time, near-wordless first-combine hint (the two item icons joined by a link
/// glyph, auto-fading) the first time a combinable pair is armed.
///
/// The bar is reachable in EVERY close-up (§7-R1.5 / F-020): GameRoomView layers it
/// above the close-up layer, same pill, same position.
struct InventoryBarView: View {
    @ObservedObject var state: GameState
    @ObservedObject var interaction: InteractionModel

    var horizontalSizeClass_isPad: Bool

    /// R4-029: one-time first-combine hint latch (per install, like the nav hint).
    @State private var showCombineHint = false
    @State private var combineHintPair: (armed: String, target: String)?
    /// Drives the combine badge pulse.
    @State private var combinePulse = false

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
                VStack(spacing: 10) {
                    // R4-029: one-time, near-wordless first-combine hint — the two item
                    // icons joined by a link glyph, floating above the pill, auto-fades.
                    if showCombineHint, let pair = combineHintPair {
                        combineHintCapsule(pair)
                            .transition(.opacity.combined(with: .move(edge: .bottom)))
                    }
                    pill(maxWidth: geo.size.width * 0.70)
                }
                .frame(maxWidth: .infinity, alignment: .center)
                .padding(.bottom, bottomInset)   // safe-area handled by the reader itself
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
                .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .animation(.easeOut(duration: 0.2), value: sortedInventory)
        .onAppear {
            withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                combinePulse = true
            }
        }
        .onChange(of: interaction.armedItem) { armed in
            maybeShowFirstCombineHint(armed: armed)
        }
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

    /// R2-028/R4-029: when an item is armed, any OTHER inventory item it can combine
    /// with shows the (now pulsing) combine affordance; tapping it performs the combine.
    private func isCombineTarget(_ itemID: String) -> Bool {
        guard let armed = interaction.armedItem, armed != itemID else { return false }
        return ItemCombinations.pairToPuzzle[Set([armed, itemID])] != nil
    }

    @ViewBuilder
    private func itemCell(_ itemID: String) -> some View {
        let def = ItemCatalog.definition(for: itemID)
        let isArmed = interaction.armedItem == itemID
        let combineTarget = isCombineTarget(itemID)
        ZStack {
            // §7-R1.4: armed backing lightens to #F2F5F8 @ 16%.
            RoundedRectangle(cornerRadius: cornerRadius - 4)
                .fill(Color(red: 0.949, green: 0.961, blue: 0.973).opacity(isArmed ? 0.16 : 0))
            // R4-029(a): a combine target gets a stronger amber backing that breathes
            // with the badge pulse, so "these two go together" reads at a glance.
            RoundedRectangle(cornerRadius: cornerRadius - 4)
                .fill(Color(red: 0.85, green: 0.62, blue: 0.28)
                    .opacity(combineTarget ? (combinePulse ? 0.38 : 0.22) : 0))
            GameImage(name: def?.iconAsset ?? "icon-poker")
                .aspectRatio(contentMode: .fit)
                .padding(6)
                .overlay(
                    // Existing pale-silver ring treatment (pure luminance, CB-safe).
                    Circle().stroke(Color(red: 0.949, green: 0.961, blue: 0.973).opacity(isArmed ? 0.9 : 0), lineWidth: 2)
                )
                .offset(y: isArmed ? -4 : 0)   // §7-R1.4: item lifts 4 pt
        }
        // R4-029(a): larger, PULSING link badge on a combinable target.
        .overlay(alignment: .topLeading) {
            if combineTarget {
                Image(systemName: "link")
                    .font(.system(size: 15, weight: .bold))
                    .foregroundColor(Color(red: 0.949, green: 0.961, blue: 0.973))
                    .padding(5)
                    .background(Circle().fill(Color(red: 0.55, green: 0.40, blue: 0.14).opacity(0.95)))
                    .scaleEffect(combinePulse ? 1.18 : 0.95)
                    .offset(x: -6, y: -8)
                    .accessibilityHidden(true)
            }
        }
        .frame(width: cellSize, height: cellSize)
        .frame(minWidth: 44, minHeight: 44)     // hit area >= 44 pt (48 padded on iPhone by cellSize+gap)
        .contentShape(Rectangle())
        .animation(.easeOut(duration: 0.12), value: isArmed)
        .onTapGesture { handleTap(itemID) }
        .onLongPressGesture(minimumDuration: 0.45) { inspect(itemID) }
        .accessibilityLabel(combineTarget ? "Combine with \(def?.name ?? "item")" : (def?.name ?? "Item"))
        .accessibilityIdentifier(combineTarget ? "combine-\(itemID)" : "inventory-\(itemID)")
        // Cluster F (R4-005): the ARMED cell carries an explicit, obvious ✕ (disarm)
        // badge top-trailing, and keeps a discrete inspect magnifier top-leading
        // (F-016; long-press also inspects). Both are separate testable affordances.
        .overlay(alignment: .topTrailing) {
            if isArmed {
                Button(action: { interaction.disarm() }) {
                    Image(systemName: "xmark")
                        .font(.system(size: 12, weight: .bold))
                        .foregroundColor(Color(red: 0.949, green: 0.961, blue: 0.973))
                        .padding(5)
                        .background(Circle().fill(Color.black.opacity(0.7)))
                }
                .offset(x: 6, y: -8)
                .accessibilityLabel("Deselect \(def?.name ?? "item")")
                .accessibilityIdentifier("disarm-\(itemID)")
            }
        }
        .overlay(alignment: .topLeading) {
            if isArmed {
                Button(action: { inspect(itemID) }) {
                    Image(systemName: "plus.magnifyingglass")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(Color(red: 0.949, green: 0.961, blue: 0.973))
                        .padding(4)
                        .background(Circle().fill(Color.black.opacity(0.6)))
                }
                .offset(x: -6, y: -8)
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
            // Cluster F (R4-005): a second tap on the ALREADY-armed cell DISARMS —
            // the trivially-discoverable deselect. (Inspect moved to the magnifier
            // badge + long-press, F-016.) Silent (F-019).
            interaction.disarm()
        } else {
            // Arm. Silent (F-019).
            interaction.armedItem = itemID
        }
    }

    private func inspect(_ itemID: String) {
        interaction.inspectingItem = itemID
    }

    // MARK: - R4-029 one-time first-combine hint (near-wordless)

    private func maybeShowFirstCombineHint(armed: String?) {
        guard let armed else { return }
        let key = "combine-hint-shown-v1"
        guard !UserDefaults.standard.bool(forKey: key) else { return }
        // Find a held combine partner for the newly-armed item.
        guard let target = sortedInventory.first(where: { candidate in
            candidate != armed && ItemCombinations.pairToPuzzle[Set([armed, candidate])] != nil
        }) else { return }
        UserDefaults.standard.set(true, forKey: key)
        combineHintPair = (armed: armed, target: target)
        withAnimation(.easeIn(duration: 0.3)) { showCombineHint = true }
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0) {
            withAnimation(.easeOut(duration: 0.6)) { showCombineHint = false }
        }
    }

    /// Icon + link + icon: symbols only, no text (near-wordless direction).
    private func combineHintCapsule(_ pair: (armed: String, target: String)) -> some View {
        HStack(spacing: 10) {
            GameImage(name: ItemCatalog.definition(for: pair.armed)?.iconAsset ?? "")
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
            Image(systemName: "link")
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(Color(red: 0.85, green: 0.62, blue: 0.28))
            GameImage(name: ItemCatalog.definition(for: pair.target)?.iconAsset ?? "")
                .aspectRatio(contentMode: .fit)
                .frame(width: 30, height: 30)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Capsule().fill(Color.black.opacity(0.6)))
        .allowsHitTesting(false)
        .accessibilityLabel("These two items can be combined")
        .accessibilityIdentifier("combine-hint")
    }
}

// TODO (R2-029, Q2 DEFERRED to Level 2+ per user decision 2026-07-08): rotate-to-inspect.
// No Level-1 item hides a clue on its back, so the inspect view stays a single-angle
// enlargement for now. When a future level needs it, add a rotation gesture here plus
// multi-angle art per item (icons are currently single-angle RGBA). Not built for L1.

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
