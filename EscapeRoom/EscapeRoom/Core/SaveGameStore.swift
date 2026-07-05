import Foundation

/// Single persistence layer for the whole app: per-level save data (progress,
/// inventory, flags) AND the completion map that drives Level Select badges, plus
/// global settings (sound). Both gameplay save/resume and the menu chrome read from
/// this same store, per the architecture requirement that Level Select completion
/// comes from the same persistence layer as save/resume.
///
/// Backed by a JSON file on disk so it's trivially unit-testable with an injected
/// directory, rather than hitting the real UserDefaults/FileManager singleton.
final class SaveGameStore {
    private let fileURL: URL
    private let queue = DispatchQueue(label: "com.escaperoom.savegamestore")
    private var cached: SaveGame?

    /// Shared instance backed by the real app-support directory.
    static let shared = SaveGameStore(directory: SaveGameStore.defaultDirectory())

    init(directory: URL) {
        try? FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        self.fileURL = directory.appendingPathComponent("savegame.json")
    }

    static func defaultDirectory() -> URL {
        let base = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first
            ?? FileManager.default.temporaryDirectory
        return base.appendingPathComponent("EscapeRoom", isDirectory: true)
    }

    func load() -> SaveGame {
        queue.sync {
            if let cached { return cached }
            guard let data = try? Data(contentsOf: fileURL),
                  let decoded = try? JSONDecoder().decode(SaveGame.self, from: data) else {
                let empty = SaveGame.empty
                cached = empty
                return empty
            }
            cached = decoded
            return decoded
        }
    }

    /// Read-modify-write helper used by all mutators.
    func update(_ mutate: (inout SaveGame) -> Void) {
        queue.sync {
            var current = cached ?? load()
            mutate(&current)
            cached = current
            if let data = try? JSONEncoder().encode(current) {
                try? data.write(to: fileURL, options: .atomic)
            }
        }
    }

    func isLevelComplete(_ levelID: Int) -> Bool {
        load().levels[levelID]?.isComplete ?? false
    }

    var soundOn: Bool {
        get { load().soundOn }
        set { update { $0.soundOn = newValue } }
    }

    /// Reset ALL progress (Settings -> Reset Progress). Destructive; caller is
    /// responsible for the confirmation UI per global-ui-style.md Section 7.
    func resetAllProgress() {
        update { save in
            save.levels = [:]
            // soundOn setting is a preference, not "progress" — left untouched.
        }
    }
}
