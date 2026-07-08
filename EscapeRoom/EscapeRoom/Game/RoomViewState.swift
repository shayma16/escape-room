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

    /// R2-003a manual pickup: undisturbed before sifting; sifted-with-ring while the ring
    /// is revealed-but-uncollected; cleared once the ring is taken. Purely state-derived.
    static func ashState(_ s: GameState) -> String {
        if PuzzleEngine.isRingUncollectedInAsh(s) { return "cu-ash-sifted" }   // ring visible
        if s.hasSolved(PuzzleGraph.PuzzleID.ashSift) { return "cu-ash-ring-taken" } // cleared
        return "cu-ash-undisturbed"
    }

    /// The ash close-up is a plain state-resolved plate now (no transient beat): the ring
    /// shows in the sifted plate until collected, then the cleared plate renders. The
    /// close-up layer overlays a tappable ring target while `isRingUncollectedInAsh`.
    static func ashCloseUp(_ s: GameState) -> String {
        ashState(s)
    }

    /// Q3 (user decision 2026-07-08): the cuckoo is removed — the clock is now purely the
    /// p01 numeral-ring reference and has a single inert face state. (`cu-clock-unspent`
    /// remains the shipped face+numeral-ring plate; the pop/spent states are retired.)
    static func clockState(_ s: GameState) -> String {
        "cu-clock-unspent"
    }

    static func rugMoved(_ s: GameState) -> Bool {
        // QA-BUG-010: the rug is a discoverable free action with its own latched flag;
        // solved/unlocked states still imply it for saves from earlier builds.
        s.hasFlag(PuzzleGraph.StateFlag.rugMoved)
            || s.hasSolved(PuzzleGraph.PuzzleID.moonTrapdoor)
            || s.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar)
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
        // Graph z1 visually_necessary_elements / p16 clue: "if crow is freed, it
        // perches on the door lintel above the basin (silent nudge)". The perch is
        // keyed on crow-freed ALONE — the previous doorUnsealed gate meant the nudge
        // only rendered AFTER the puzzle it exists to hint at was already solved
        // (found by the Documentation Agent's walkthrough reconciliation, 2026-07-06).
        // cu-crow-rafters remains the transient freed-beat close-up; the persistent
        // wide-shot state is the lintel perch.
        s.hasFlag(PuzzleGraph.StateFlag.crowFreed) ? "on-lintel" : "caged"
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

    /// Open-cabinet wide overlay carries its contents until both are collected
    /// (feedback round 1 F-023 manual pickup): ov-cab-open shows the file + phial on
    /// the inner shelf; ov-cab-open-empty is the collected state.
    static func cabinetOpenOverlay(_ s: GameState) -> String? {
        guard s.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) else { return nil }
        let anyLeft = !PuzzleEngine.uncollectedItems(in: .sunMoonCabinet, state: s).isEmpty
        return anyLeft ? "ov-cab-open" : "ov-cab-open-empty"
    }

    static func astrolabeDrawerOpen(_ s: GameState) -> Bool {
        s.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
    }

    // MARK: z3 v-cellar

    /// Barrel overlay (BUG-004 integration fix): the base plate carries the NAILED
    /// barrel, so pre-solve needs no overlay; after p06 the graph-specified pried
    /// state shows ("barrel (nailed / pried, weight visible inside)" —
    /// visually_necessary_elements). The previous mapping overlaid pried art
    /// pre-solve — a latent visual bug masked by QA-BUG-022's black scenes.
    static func barrelOverlay(_ s: GameState) -> String? {
        s.hasSolved(PuzzleGraph.PuzzleID.barrelPry) ? "ov-barrel-pried" : nil
    }

    /// Cellar drawer (feedback round 1 fix): graph states are shut / open-with-spoon /
    /// open-empty. The previous mapping was inverted AND always overlaid an open
    /// drawer from the first frame. `nil` = shut (the base plate's own art).
    /// Saves from older builds (spoon held, no opened flag) migrate by implication.
    static func cellarDrawerOpened(_ s: GameState) -> Bool {
        s.hasFlag(PuzzleGraph.StateFlag.cellarDrawerOpened) || s.hasItem(PuzzleGraph.ItemID.spoon)
    }

    static func drawerOverlay(_ s: GameState) -> String? {
        guard cellarDrawerOpened(s) else { return nil }
        return s.hasItem(PuzzleGraph.ItemID.spoon) ? "ov-drawer-empty" : "ov-drawer-open"
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
