import SwiftUI

/// Bottom-edge inventory bar per style guide Section 7: aged dark-oak strip, 96pt tall
/// iPad / 72pt iPhone, horizontal scroll if overfull, no labels, selected item lifts
/// with a pale silver ring. Drag gesture reports drop location to the active
/// RoomSceneCoordinator for hotspot hit-testing.
struct InventoryBarView: View {
    @ObservedObject var state: GameState
    @ObservedObject var coordinator: RoomSceneCoordinator
    @State private var selectedItem: String?
    @State private var dragOffset: CGSize = .zero
    @State private var draggingItem: String?

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
    }

    private var sortedInventory: [String] {
        // Stable order: catalog declaration order, filtered to held items.
        ItemCatalog.all.map(\.id).filter { state.inventory.contains($0) }
    }

    @ViewBuilder
    private func itemIcon(_ itemID: String) -> some View {
        let def = ItemCatalog.definition(for: itemID)
        let isSelected = selectedItem == itemID
        GameImage(name: def?.iconAsset ?? "icon-poker")
            .aspectRatio(contentMode: .fit)
            .frame(width: barHeight - 24, height: barHeight - 24)
            .padding(6)
            .overlay(
                Circle()
                    .stroke(Color(white: 0.85).opacity(isSelected ? 0.9 : 0), lineWidth: 2)
            )
            .offset(y: isSelected ? -4 : 0)
            .animation(.easeOut(duration: 0.12), value: isSelected)
            .contentShape(Rectangle())
            .frame(minWidth: 44, minHeight: 44)
            .onTapGesture {
                selectedItem = (selectedItem == itemID) ? nil : itemID
            }
            .gesture(
                DragGesture(coordinateSpace: .global)
                    .onChanged { value in
                        draggingItem = itemID
                    }
                    .onEnded { value in
                        handleDrop(itemID: itemID, at: value.location)
                        draggingItem = nil
                    }
            )
            .accessibilityLabel(def?.name ?? "Item")
    }

    private func handleDrop(itemID: String, at globalPoint: CGPoint) {
        // The SpriteKit scene's frame in global coordinates is provided by the parent
        // via a shared coordinate conversion; RoomSceneCoordinator exposes
        // `hotspotID(atScenePoint:)` for the scene's own local space. Precise global-to-
        // scene mapping is handled by GameRoomView, which owns both the scene frame and
        // this bar and forwards resolved drops here.
        NotificationCenter.default.post(name: .inventoryItemDropped, object: nil, userInfo: [
            "itemID": itemID, "globalPoint": globalPoint
        ])
    }
}

extension Notification.Name {
    static let inventoryItemDropped = Notification.Name("inventoryItemDropped")
}
