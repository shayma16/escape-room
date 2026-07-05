import Foundation

/// Resolves the current image name for a given room view from GameState — purely a
/// function of latched state flags/items/zones, never of the order events happened in.
/// This is the visual analogue of the requirement-based puzzle engine: every render is
/// `f(state) -> imageName`, recomputed on every state change.
enum RoomVisuals {

    // MARK: z1 v-hearth

    static func hearthBase(_ s: GameState) -> String {
        "z1-hearth-base"
    }

    static func ashState(_ s: GameState) -> String {
        if s.hasItem(PuzzleGraph.ItemID.goldRing) || s.hasSolved(PuzzleGraph.PuzzleID.ashSift) {
            return "cu-ash-ring-taken"
        }
        return "cu-ash-undisturbed"
    }

    /// D5: one-shot cuckoo pop, then permanently spent. Never gates progression.
    static func clockState(_ s: GameState, justPopped: Bool) -> String {
        if justPopped { return "cu-clock-pop" }
        return s.hasFlag(PuzzleGraph.StateFlag.clockCuckooSpent) ? "cu-clock-spent" : "cu-clock-unspent"
    }

    static func rugMoved(_ s: GameState) -> Bool {
        s.hasSolved(PuzzleGraph.PuzzleID.moonTrapdoor) || s.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar)
    }

    static func trapdoorOpen(_ s: GameState) -> Bool {
        s.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar)
    }

    static func pokerTaken(_ s: GameState) -> Bool {
        s.hasItem(PuzzleGraph.ItemID.poker)
    }

    // MARK: z1 v-entry

    static func vinesState(_ s: GameState) -> String {
        if s.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) { return "vines-gone" }
        // Withered is a transient mid-pour animation frame; with D1 BLOCK ruling the
        // only real states are alive/gone (basin is never filled from the feed cup, and
        // there's no partial-pour step in the win path), so we treat withered as the
        // immediate pre-gone frame driven by the Scene's transition, not a persisted flag.
        return "vines-alive"
    }

    static func basinState(_ s: GameState) -> String {
        s.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) ? "basin-drained" : "basin-empty"
    }

    static func boltState(_ s: GameState) -> String {
        s.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) ? "bolt-slid" : "bolt-shut"
    }

    static func cageState(_ s: GameState) -> String {
        s.hasFlag(PuzzleGraph.StateFlag.crowFreed) ? "cage-open-empty" : "cage-crow"
    }

    static func crowLocation(_ s: GameState) -> String {
        guard s.hasFlag(PuzzleGraph.StateFlag.crowFreed) else { return "caged" }
        return s.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) ? "on-lintel" : "on-rafters"
    }

    // MARK: z2 v-bench

    static func flameStageState(_ s: GameState) -> Int {
        s.data.cauldronFlameStage
    }

    static func cauldronLiquidState(_ s: GameState, lastBrewOutcome: PuzzleEngine.BrewOutcome?) -> String {
        if s.hasFlag(PuzzleGraph.StateFlag.draughtReady) { return "cu-brew-draught" }
        if lastBrewOutcome == .fizzle { return "cu-brew-fizzle" }
        return "cu-brew-clear"
    }

    static func mortarState(_ s: GameState) -> String {
        if s.hasSolved(PuzzleGraph.PuzzleID.grindPaste) { return "cu-mortar-paste" }
        if s.data.cauldronIngredients.contains(PuzzleGraph.ItemID.blossom) { return "cu-mortar-blossom" }
        return "cu-mortar-empty"
    }

    // MARK: z2 v-cabinet

    static func cabinetSlotsState(_ s: GameState) -> String {
        s.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) ? "cu-slots-seated" : "cu-slots-empty"
    }

    static func cabinetDoorState(_ s: GameState) -> Bool {
        s.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
    }

    static func astrolabeDrawerOpen(_ s: GameState) -> Bool {
        s.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
    }

    // MARK: z3 v-cellar

    static func barrelState(_ s: GameState) -> String {
        s.hasSolved(PuzzleGraph.PuzzleID.barrelPry) ? "ov-barrel-pried" : "ov-barrel-empty"
    }

    static func drawerState(_ s: GameState) -> String {
        s.hasItem(PuzzleGraph.ItemID.spoon) ? "ov-drawer-open" : "ov-drawer-empty"
    }

    static func shelfSlid(_ s: GameState) -> Bool {
        s.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove)
    }

    static func crankFitted(_ s: GameState) -> Bool {
        s.hasFlag(PuzzleGraph.StateFlag.moonbeamOn)
    }

    /// All four combinations of shutter x detent x shelf render distinctly per
    /// visually_necessary_elements — this is the canonical beam-state resolver used by
    /// the cellar scene, re-evaluated continuously (never event-ordered), per D2.
    enum BeamVisual { case none, floorBeam, blockedOnShelf, intoAlcove }

    static func beamVisual(_ s: GameState) -> BeamVisual {
        let moonbeamOn = s.hasFlag(PuzzleGraph.StateFlag.moonbeamOn)
        let atDetent3 = s.hasFlag(PuzzleGraph.StateFlag.mirrorDetent3)
        guard moonbeamOn else { return .none }
        guard atDetent3 else { return .floorBeam }
        return shelfSlid(s) ? .intoAlcove : .blockedOnShelf
    }

    // MARK: z4 v-alcove

    static func planterState(_ s: GameState) -> String {
        if s.hasSolved(PuzzleGraph.PuzzleID.moonflowerBloom) { return "picked" }
        if s.evaluateCondition("cond-beam-at-alcove") { return "blooming" }
        if s.hasFlag(PuzzleGraph.StateFlag.moonbeamOn) { return "trembling" }
        return "closed"
    }

    static func cageKeyTaken(_ s: GameState) -> Bool {
        s.hasItem(PuzzleGraph.ItemID.cageKey)
    }
}
