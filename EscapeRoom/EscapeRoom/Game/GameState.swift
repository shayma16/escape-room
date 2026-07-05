import Foundation
import Combine

/// Full persistable state for a single level playthrough.
/// Encodes ONLY satisfied-requirement flags / held items / unlocked zones / derived-
/// condition inputs — never a literal step sequence — per the puzzle graph's
/// requirement-based state model.
struct LevelSaveData: Codable, Equatable {
    var levelID: Int
    var inventory: Set<String> = []
    var unlockedZones: Set<String> = []
    var flags: Set<String> = []                 // e.g. "moonbeam-on", "door-unsealed"
    var solvedPuzzles: Set<String> = []          // puzzle ids that have yielded their reward
    var runeDoorProgress: [String] = []          // in-progress tile press sequence (transient-ish but safe to persist)
    var moonDialPositions: [Int] = [0, 0, 0]     // current dial indices (0-7), persisted so it "retains position" per spec
    var mirrorDetent: Int = 1                    // current mirror detent (1...3)
    var cauldronFlameStage: Int = 0              // 0-3
    var cauldronIngredients: Set<String> = []    // ingredients currently in cauldron
    var isComplete: Bool = false
    var lastUpdated: Date = Date()
}

/// Top-level save file: per-level saves + global completion map (drives Level Select
/// badges) + settings. This is the single persistence layer referenced by both gameplay
/// save/resume and the Level Select completion indicators.
struct SaveGame: Codable, Equatable {
    var levels: [Int: LevelSaveData] = [:]
    var soundOn: Bool = true

    static let empty = SaveGame()
}

/// Observable runtime game state for a single level. Wraps a `LevelSaveData` and
/// exposes convenience mutators used by the puzzle state machines. Persists via
/// `SaveGameStore` on every meaningful change.
final class GameState: ObservableObject {
    @Published private(set) var data: LevelSaveData
    private let store: SaveGameStore

    init(levelID: Int, store: SaveGameStore) {
        self.store = store
        if let existing = store.load().levels[levelID] {
            self.data = existing
        } else {
            self.data = LevelSaveData(levelID: levelID)
        }
    }

    // MARK: - Read helpers

    var inventory: Set<String> { data.inventory }
    var unlockedZones: Set<String> { data.unlockedZones }
    var flags: Set<String> { data.flags }
    var solvedPuzzles: Set<String> { data.solvedPuzzles }
    var isComplete: Bool { data.isComplete }

    func hasSolved(_ puzzleID: String) -> Bool { data.solvedPuzzles.contains(puzzleID) }
    func hasFlag(_ flag: String) -> Bool { data.flags.contains(flag) }
    func hasItem(_ itemID: String) -> Bool { data.inventory.contains(itemID) }
    func isZoneUnlocked(_ zoneID: String) -> Bool { data.unlockedZones.contains(zoneID) }

    /// Evaluate a derived condition (e.g. cond-beam-at-alcove) fresh from current flags,
    /// every time it's asked — never cached against an event order. Satisfies D2.
    func evaluateCondition(_ id: String) -> Bool {
        guard let condition = PuzzleGraph.derivedConditions.first(where: { $0.id == id }) else {
            return false
        }
        return condition.isTrue(flags: data.flags)
    }

    func requirementsSatisfied(_ requirements: [Requirement]) -> Bool {
        requirements.allSatisfy { $0.isSatisfied(by: self) }
    }

    // MARK: - Mutators (all persist)

    func addItem(_ id: String) {
        data.inventory.insert(id)
        persist()
    }

    @discardableResult
    func removeItem(_ id: String) -> Bool {
        let removed = data.inventory.remove(id) != nil
        if removed { persist() }
        return removed
    }

    func unlockZone(_ id: String) {
        guard !data.unlockedZones.contains(id) else { return }
        data.unlockedZones.insert(id)
        persist()
    }

    func setFlag(_ id: String) {
        guard !data.flags.contains(id) else { return }
        data.flags.insert(id)
        persist()
    }

    func clearFlag(_ id: String) {
        guard data.flags.contains(id) else { return }
        data.flags.remove(id)
        persist()
    }

    func markSolved(_ puzzleID: String) {
        guard !data.solvedPuzzles.contains(puzzleID) else { return }
        data.solvedPuzzles.insert(puzzleID)
        persist()
    }

    func setRuneDoorProgress(_ progress: [String]) {
        data.runeDoorProgress = progress
        persist()
    }

    func setMoonDialPosition(dial index: Int, phase: Int) {
        guard data.moonDialPositions.indices.contains(index) else { return }
        data.moonDialPositions[index] = phase
        persist()
    }

    func setMirrorDetent(_ detent: Int) {
        data.mirrorDetent = detent
        persist()
    }

    func setCauldronFlameStage(_ stage: Int) {
        data.cauldronFlameStage = stage
        persist()
    }

    func setCauldronIngredients(_ ingredients: Set<String>) {
        data.cauldronIngredients = ingredients
        persist()
    }

    func markComplete() {
        data.isComplete = true
        persist()
    }

    /// Restart just this level's progress (Pause -> Restart Level), leaving other
    /// levels' saves and global settings untouched.
    func restartLevel() {
        data = LevelSaveData(levelID: data.levelID)
        persist()
    }

    private func persist() {
        data.lastUpdated = Date()
        store.update { save in
            save.levels[data.levelID] = data
        }
    }
}
