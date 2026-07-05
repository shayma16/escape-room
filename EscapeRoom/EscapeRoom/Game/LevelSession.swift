import Foundation
import Combine

/// Owns the long-lived GameState for a single level playthrough plus current-view
/// navigation. One instance created when entering a level from Level Select, torn down
/// (not the save data — just the object) when leaving to the menu.
final class LevelSession: ObservableObject {
    let levelID: Int
    let state: GameState
    @Published var currentView: ViewID

    private let store: SaveGameStore

    init(levelID: Int, store: SaveGameStore = .shared) {
        self.levelID = levelID
        self.store = store
        self.state = GameState(levelID: levelID, store: store)
        self.currentView = .hearth
    }

    /// Ordered view list for chevron navigation within a zone, and the zone's first
    /// view when a zone is freshly unlocked.
    static let viewOrder: [ViewID] = [.hearth, .study, .entry, .bench, .cabinet, .cellar, .alcove]

    func availableViews() -> [ViewID] {
        Self.viewOrder.filter { state.isZoneUnlocked($0.zoneID) }
    }

    func goTo(_ view: ViewID) {
        guard state.isZoneUnlocked(view.zoneID) else { return }
        currentView = view
        SoundManager.shared.setAmbientZone(ambientZone(for: view.zoneID))
    }

    func nextView() {
        let views = availableViews()
        guard let idx = views.firstIndex(of: currentView) else { return }
        goTo(views[(idx + 1) % views.count])
    }

    func previousView() {
        let views = availableViews()
        guard let idx = views.firstIndex(of: currentView) else { return }
        goTo(views[(idx - 1 + views.count) % views.count])
    }

    func restartLevel() {
        state.restartLevel()
        currentView = .hearth
    }

    private func ambientZone(for zoneID: String) -> SoundManager.Zone {
        switch zoneID {
        case PuzzleGraph.ZoneID.z1Cabin: return .z1
        case PuzzleGraph.ZoneID.z2Workshop: return .z2
        case PuzzleGraph.ZoneID.z3Cellar: return .z3
        case PuzzleGraph.ZoneID.z4Alcove: return .z4
        default: return .z1
        }
    }
}
