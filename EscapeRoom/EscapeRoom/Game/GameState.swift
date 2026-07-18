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
    /// Clue close-ups the player has actually viewed, keyed by close-up/plate id
    /// (feedback round 1, F-012 clue-gating substrate). Recorded universally so the
    /// rev-1.3 `clue_gate` table can be enforced purely from persisted state once the
    /// Validator passes it. Persisted in the save per the design decision.
    var viewedClues: Set<String> = []
    var isComplete: Bool = false
    var lastUpdated: Date = Date()

    init(levelID: Int) {
        self.levelID = levelID
    }

    /// Custom decoding so saves written by OLDER builds (missing newly-added keys such
    /// as `viewedClues`) still decode instead of silently resetting the player's
    /// progress. Every field added after build 1 must use decodeIfPresent here.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        levelID = try c.decode(Int.self, forKey: .levelID)
        inventory = try c.decodeIfPresent(Set<String>.self, forKey: .inventory) ?? []
        unlockedZones = try c.decodeIfPresent(Set<String>.self, forKey: .unlockedZones) ?? []
        flags = try c.decodeIfPresent(Set<String>.self, forKey: .flags) ?? []
        solvedPuzzles = try c.decodeIfPresent(Set<String>.self, forKey: .solvedPuzzles) ?? []
        runeDoorProgress = try c.decodeIfPresent([String].self, forKey: .runeDoorProgress) ?? []
        moonDialPositions = try c.decodeIfPresent([Int].self, forKey: .moonDialPositions) ?? [0, 0, 0]
        mirrorDetent = try c.decodeIfPresent(Int.self, forKey: .mirrorDetent) ?? 1
        cauldronFlameStage = try c.decodeIfPresent(Int.self, forKey: .cauldronFlameStage) ?? 0
        cauldronIngredients = try c.decodeIfPresent(Set<String>.self, forKey: .cauldronIngredients) ?? []
        viewedClues = try c.decodeIfPresent(Set<String>.self, forKey: .viewedClues) ?? []
        isComplete = try c.decodeIfPresent(Bool.self, forKey: .isComplete) ?? false
        lastUpdated = try c.decodeIfPresent(Date.self, forKey: .lastUpdated) ?? Date()
    }
}

/// Top-level save file: per-level saves + global completion map (drives Level Select
/// badges) + settings. This is the single persistence layer referenced by both gameplay
/// save/resume and the Level Select completion indicators.
struct SaveGame: Codable, Equatable {
    var levels: [Int: LevelSaveData] = [:]
    /// Legacy single master toggle (build <= 2). Retained for migration only; the live
    /// settings are the two independent toggles below (R2-006). Never surfaced in the UI
    /// anymore — kept so an older save decodes and seeds the split toggles once.
    var soundOn: Bool = true
    /// R2-006: split audio settings — ambiance/music mute and SFX mute, independent and
    /// persisted separately. `nil` in a decoded pre-split save; migrated from `soundOn`
    /// on first load (see custom init).
    var ambianceOn: Bool = true
    var sfxOn: Bool = true

    static let empty = SaveGame()

    init() {}

    /// Migration-tolerant decode: pre-split saves carry only `soundOn`; seed BOTH new
    /// toggles from it so muted players stay muted and everyone else stays on.
    init(from decoder: Decoder) throws {
        let c = try decoder.container(keyedBy: CodingKeys.self)
        levels = try c.decodeIfPresent([Int: LevelSaveData].self, forKey: .levels) ?? [:]
        let legacy = try c.decodeIfPresent(Bool.self, forKey: .soundOn) ?? true
        soundOn = legacy
        ambianceOn = try c.decodeIfPresent(Bool.self, forKey: .ambianceOn) ?? legacy
        sfxOn = try c.decodeIfPresent(Bool.self, forKey: .sfxOn) ?? legacy
    }
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
        // QA-BUG-001 fix: the graph's start zone is unlocked from the first frame of a
        // fresh save (zones[0].start_zone == true). Applied on every init so saves
        // written by earlier builds (which never contained the start zone) migrate too.
        if !data.unlockedZones.contains(PuzzleGraph.startZoneID) {
            data.unlockedZones.insert(PuzzleGraph.startZoneID)
            persist()
        }
        // Build 10 cluster A migration: a save written by the build-9 lifecycle
        // (which under-consumed — R4-030's lingering spoon/file) may still hold
        // fully-depleted items; reconcile once on load so old saves come clean.
        ItemLifecycle.reconcile(self)
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
        // Build 10 cluster A: every way an item use can become satisfied passes
        // through setFlag or markSolved, so reconciling here (and only here) makes
        // the uses-driven retain/consume rule impossible to bypass (R4-019/R4-030).
        ItemLifecycle.reconcile(self)
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
        // Build 10 cluster A: see setFlag — the single, unbypassable reconcile point.
        ItemLifecycle.reconcile(self)
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

    /// Records that a clue close-up has been viewed (F-012 clue-gating substrate).
    /// Idempotent latched fact, like any satisfied-requirement flag.
    func markClueViewed(_ clueID: String) {
        guard !data.viewedClues.contains(clueID) else { return }
        data.viewedClues.insert(clueID)
        persist()
    }

    func hasViewedClue(_ clueID: String) -> Bool {
        data.viewedClues.contains(clueID)
    }

    func markComplete() {
        data.isComplete = true
        persist()
    }

    /// Restart just this level's progress (Pause -> Restart Level), leaving other
    /// levels' saves and global settings untouched. The start zone stays unlocked
    /// (QA-BUG-001) — a restarted level must be navigable exactly like a fresh save.
    func restartLevel() {
        data = LevelSaveData(levelID: data.levelID)
        data.unlockedZones.insert(PuzzleGraph.startZoneID)
        persist()
    }

    private func persist() {
        data.lastUpdated = Date()
        store.update { save in
            save.levels[data.levelID] = data
        }
    }
}
