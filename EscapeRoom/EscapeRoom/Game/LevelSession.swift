import Foundation
import Combine

/// Shared select-then-tap interaction state (feedback round 1, F-020/F-021 cluster +
/// user design decision 2026-07-07: SELECT-THEN-TAP ONLY — drag-to-use and passive
/// auto-apply are REMOVED). One instance per LevelSession, shared by the inventory bar,
/// the room coordinator, and the close-up layer, so an item armed in the wide view can
/// be used inside a close-up and vice versa.
///
/// Not persisted: an armed item is a momentary intention, not progress state.
final class InteractionModel: ObservableObject {
    /// The inventory item the player has armed (tap an inventory icon to arm; tap it
    /// again to disarm). Using it on any target — success or failure — disarms.
    @Published var armedItem: String?
    /// Item currently shown in the enlarged inspect view (F-016).
    @Published var inspectingItem: String?

    func disarm() {
        armedItem = nil
    }
}

/// Owns the long-lived GameState for a single level playthrough plus current-view
/// navigation. One instance created when entering a level from Level Select, torn down
/// (not the save data — just the object) when leaving to the menu.
final class LevelSession: ObservableObject {
    let levelID: Int
    let state: GameState
    let interaction = InteractionModel()
    @Published var currentView: ViewID

    private let store: SaveGameStore

    init(levelID: Int, store: SaveGameStore = .shared) {
        self.levelID = levelID
        self.store = store
        self.state = GameState(levelID: levelID, store: store)
        self.currentView = .hearth
    }

    // MARK: - Navigation model (F-024 fix, feedback round 1)
    //
    // Chevrons cycle VIEWS WITHIN THE CURRENT ZONE only (z1: hearth/study/entry,
    // z2: bench/cabinet). Zone transitions happen exclusively through diegetic
    // passages (rune door, trapdoor, cellar ladder, shelf gap) via `goTo`, per style
    // guide Section 7 ("Zone passages are diegetic hotspots, not UI"). Single-view
    // zones (z3, z4) have no chevron navigation at all — the chrome hides the
    // chevrons there.

    /// Views of each zone in presentation order (mirrors puzzle-graph.json zones[].views).
    static let zoneViews: [String: [ViewID]] = [
        PuzzleGraph.ZoneID.z1Cabin: [.hearth, .study, .entry],
        PuzzleGraph.ZoneID.z2Workshop: [.bench, .cabinet],
        PuzzleGraph.ZoneID.z3Cellar: [.cellar],
        PuzzleGraph.ZoneID.z4Alcove: [.alcove],
    ]

    /// The current zone's view ring (always non-empty).
    var viewsInCurrentZone: [ViewID] {
        Self.zoneViews[currentView.zoneID] ?? [currentView]
    }

    /// Every view the player can currently reach: the views of all UNLOCKED zones.
    /// Used by Level Select / QA to assert that a fresh save exposes the start zone's
    /// three views (QA-BUG-001) and that hidden zones only appear once unlocked.
    func availableViews() -> [ViewID] {
        ViewID.allCases.filter { state.isZoneUnlocked($0.zoneID) }
    }

    /// Whether left/right chevrons should be shown at all (multi-view zones only).
    var hasViewNavigation: Bool {
        viewsInCurrentZone.count > 1
    }

    func goTo(_ view: ViewID) {
        guard state.isZoneUnlocked(view.zoneID) else { return }
        currentView = view
        SoundManager.shared.setAmbientZone(ambientZone(for: view.zoneID))
    }

    func nextView() {
        let views = viewsInCurrentZone
        guard views.count > 1, let idx = views.firstIndex(of: currentView) else { return }
        goTo(views[(idx + 1) % views.count])
    }

    func previousView() {
        let views = viewsInCurrentZone
        guard views.count > 1, let idx = views.firstIndex(of: currentView) else { return }
        goTo(views[(idx - 1 + views.count) % views.count])
    }

    func restartLevel() {
        state.restartLevel()
        interaction.disarm()
        interaction.inspectingItem = nil
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
