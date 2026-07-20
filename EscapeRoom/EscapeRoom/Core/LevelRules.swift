import Foundation

/// Per-level behavior that `GameState` needs but that differs by level: which zone is
/// unlocked from the first frame (the graph's `start_zone`) and how the uses-driven
/// item lifecycle reconciles the inventory. Introduced for Level 2 so the shared
/// `GameState` / `SaveGameStore` / `LevelSaveData` persistence stack is reused verbatim
/// across levels instead of forked — Level 1 keeps its exact prior behavior.
protocol LevelRules {
    /// zones[0].start_zone == true (unlocked on a fresh save; migrated onto old saves).
    var startZoneID: String { get }
    /// Sweep the inventory removing any item whose graph `uses` are ALL satisfied
    /// (retain-while-any-use-unsatisfied, consume-when-all-satisfied).
    func reconcile(_ state: GameState)
}

/// Level 1 rules — byte-for-byte the behavior GameState had before the Level 2 work:
/// PuzzleGraph.startZoneID + ItemLifecycle.reconcile.
struct Level1Rules: LevelRules {
    var startZoneID: String { PuzzleGraph.startZoneID }
    func reconcile(_ state: GameState) { ItemLifecycle.reconcile(state) }
}

/// Resolves the rules object for a level id. Unknown ids fall back to Level 1 rules
/// (harmless: a level with no L2 items simply never reconciles anything away).
enum LevelRulesRegistry {
    static func rules(for levelID: Int) -> LevelRules {
        switch levelID {
        case 2: return Level2Rules()
        default: return Level1Rules()
        }
    }
}
