import Foundation

/// Static metadata for every item node in puzzle-graph.json: display name, inventory
/// icon asset, and (for red herrings) the flag that it never actually unlocks anything.
struct ItemDefinition {
    let id: String
    let name: String
    let iconAsset: String   // matches asset-manifest icon file (without extension/zone path)
    let isRedHerring: Bool
}

enum ItemCatalog {
    static let all: [ItemDefinition] = [
        ItemDefinition(id: PuzzleGraph.ItemID.poker, name: "Iron Poker", iconAsset: "icon-poker", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.rustedKey, name: "Rusted Bent Key", iconAsset: "icon-rusted-key", isRedHerring: true),
        ItemDefinition(id: PuzzleGraph.ItemID.goldRing, name: "Gold Ring", iconAsset: "icon-gold-ring", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.crank, name: "Winch Crank Handle", iconAsset: "icon-crank", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.silverCoin, name: "Silver Coin", iconAsset: "icon-silver-coin", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.file, name: "Metal File", iconAsset: "icon-file", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.phial, name: "Empty Glass Phial", iconAsset: "icon-phial", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.spoon, name: "Tarnished Silver Spoon", iconAsset: "icon-spoon", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.shavings, name: "Silver Shavings", iconAsset: "icon-shavings", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.weight, name: "Iron Plumb Weight", iconAsset: "icon-weight", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.cageKey, name: "Star-Bit Cage Key", iconAsset: "icon-cage-key", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.blossom, name: "Moonflower Blossom", iconAsset: "icon-blossom", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.paste, name: "Moonflower Paste", iconAsset: "icon-paste", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.feather, name: "Black Crow Feather", iconAsset: "icon-feather", isRedHerring: false),
        ItemDefinition(id: PuzzleGraph.ItemID.phialDraught, name: "Phial of Unbinding Draught", iconAsset: "icon-phial-draught", isRedHerring: false),
    ] + level2Items

    /// Level 2 "The Clockmaker's Attic" items (distinct ids/icons from L1; appended so the
    /// shared InventoryBarView / ItemInspectView resolve them). Icon asset names match the
    /// staged Level-2 inventory cutouts (inv-*). None are red herrings — the level's decoys
    /// (tray VI tile, 48 gear) are non-collectible and never enter inventory (R6-003).
    static let level2Items: [ItemDefinition] = [
        ItemDefinition(id: Level2Graph.ItemID.screwdriver, name: "Heavy Flat-Blade Screwdriver", iconAsset: "inv-screwdriver", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.tileII, name: "Numeral Tile II", iconAsset: "inv-tile-ii", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.tileIV, name: "Numeral Tile IV", iconAsset: "inv-tile-iv", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.tileVII, name: "Numeral Tile VII", iconAsset: "inv-tile-vii", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.tileXI, name: "Numeral Tile XI", iconAsset: "inv-tile-xi", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.watchA, name: "Pocket Watch A", iconAsset: "inv-watch-a", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.watchB, name: "Pocket Watch B", iconAsset: "inv-watch-b", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.toyMouse, name: "Tin Wind-Up Mouse", iconAsset: "inv-toy-mouse", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.greatWheel, name: "Great Wheel (64 teeth)", iconAsset: "inv-great-wheel", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.oilcan, name: "Long-Spout Oil Can", iconAsset: "inv-oil-can", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.windingKey, name: "Square-Bit Winding Key", iconAsset: "inv-winding-key", isRedHerring: false),
        ItemDefinition(id: Level2Graph.ItemID.returnTag, name: "'Will Return' Tag (7:20)", iconAsset: "inv-return-tag", isRedHerring: false),
    ]

    static let byID: [String: ItemDefinition] = Dictionary(uniqueKeysWithValues: all.map { ($0.id, $0) })

    static func definition(for id: String) -> ItemDefinition? { byID[id] }
}

/// Generic item-combination resolver. Combination pairs are data (not hardcoded control
/// flow scattered across scenes), so adding future levels' combos means adding data,
/// not rewriting logic. Level 1 has exactly one combination puzzle (p12).
enum ItemCombinations {
    /// Unordered pair -> puzzle id that resolves it.
    static let pairToPuzzle: [Set<String>: String] = [
        Set([PuzzleGraph.ItemID.file, PuzzleGraph.ItemID.spoon]): PuzzleGraph.PuzzleID.fileShavings
    ]

    /// Attempts to combine two inventory items. Returns true if a combination existed
    /// and was resolved (regardless of whether it had already been solved before).
    @discardableResult
    static func combine(_ itemA: String, _ itemB: String, state: GameState) -> Bool {
        guard itemA != itemB else { return false }
        let pair = Set([itemA, itemB])
        guard let puzzleID = pairToPuzzle[pair] else { return false }
        switch puzzleID {
        case PuzzleGraph.PuzzleID.fileShavings:
            return PuzzleEngine.fileShavings(state: state)
        default:
            return false
        }
    }
}
