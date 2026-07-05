import SwiftUI

/// Bottom-edge inventory bar per style guide Section 7: aged dark-oak strip, 96pt tall
/// iPad / 72pt iPhone, horizontal scroll if overfull, no labels, selected item lifts
/// with a pale silver ring. Drag gesture reports drop location to the active
/// RoomSceneCoordinator for hotspot hit-testing.
///
/// QA-BUG-012 fix (item combination): tapping an item selects it; tapping a SECOND
/// item while one is selected attempts `ItemCombinations.combine` on the pair (the
/// classic point-and-click combine gesture). If the pair combines (file + spoon ->
/// shavings, p12), the solve plays; otherwise selection simply moves to the tapped
/// item — no penalty, no noise, so the gesture can never punish exploration.
///
/// Long-pressing an item opens its inspection close-up where one exists (the rusted
/// key's snapped plain bit — the graph's red-herring fairness valve).
struct InventoryBarView: View {
    @ObservedObject var state: GameState
    @ObservedObject var coordinator: RoomSceneCoordinator
    @State private var selectedItem: String?
    @State private var draggingItem: String?
    @State private var dragTranslation: CGSize = .zero

    var horizontalSizeClass_isPad: Bool

    private var barHeight: CGFloat { horizontalSizeClass_isPad ? 96 : 72 }

    /// Inventory items that have an inspection close-up plate.
    private static let inspectionPlates: [String: String] = [
        PuzzleGraph.ItemID.rustedKey: "cu-rusted-key"
    ]

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
        let isSelected = selectedItem == itemID
        let isDragging = draggingItem == itemID
        GameImage(name: def?.iconAsset ?? "icon-poker")
            .aspectRatio(contentMode: .fit)
            .frame(width: barHeight - 24, height: barHeight - 24)
            .padding(6)
            .overlay(
                Circle()
                    .stroke(Color(white: 0.85).opacity(isSelected ? 0.9 : 0), lineWidth: 2)
            )
            // Section 7: dragged item ghosts at ~70% opacity under the finger.
            .opacity(isDragging ? 0.7 : 1.0)
            .offset(isDragging ? dragTranslation : .zero)
            .offset(y: isSelected ? -4 : 0)
            .animation(.easeOut(duration: 0.12), value: isSelected)
            .contentShape(Rectangle())
            .frame(minWidth: 44, minHeight: 44)
            .onTapGesture { handleTap(itemID) }
            .onLongPressGesture(minimumDuration: 0.45) { handleInspect(itemID) }
            .simultaneousGesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        draggingItem = itemID
                        dragTranslation = value.translation
                    }
                    .onEnded { value in
                        handleDrop(itemID: itemID, at: value.location)
                        draggingItem = nil
                        dragTranslation = .zero
                    }
            )
            .accessibilityLabel(def?.name ?? "Item")
            .accessibilityIdentifier("inventory-\(itemID)")
            .zIndex(isDragging ? 10 : 0)
    }

    private func handleTap(_ itemID: String) {
        if let selected = selectedItem, selected != itemID {
            // Combine attempt (p12 and any future data-driven pair).
            let newlySolvable = ItemCombinations.pairToPuzzle[Set([selected, itemID])] != nil
            if newlySolvable, ItemCombinations.combine(selected, itemID, state: state) {
                SoundManager.shared.play(.solve)
                selectedItem = nil
                return
            }
            // No combination: selection just moves.
            selectedItem = itemID
            SoundManager.shared.play(.click)
        } else {
            selectedItem = (selectedItem == itemID) ? nil : itemID
            SoundManager.shared.play(.click)
        }
    }

    private func handleInspect(_ itemID: String) {
        guard let plate = Self.inspectionPlates[itemID] else { return }
        SoundManager.shared.play(.click)
        coordinator.activeCloseUp = .plain(image: plate)
    }

    private func handleDrop(itemID: String, at globalPoint: CGPoint) {
        // GameRoomView owns the exact window-point -> scene-point conversion (via the
        // presenting SKView, QA-BUG-014) and forwards resolved drops to the coordinator.
        NotificationCenter.default.post(name: .inventoryItemDropped, object: nil, userInfo: [
            "itemID": itemID, "globalPoint": globalPoint
        ])
    }
}

extension Notification.Name {
    static let inventoryItemDropped = Notification.Name("inventoryItemDropped")
}
