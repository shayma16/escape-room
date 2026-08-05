import Foundation

// MARK: - Level 2 "The Clockmaker's Attic" — requirement-based puzzle model
//
// Mirrors specs/levels/level-2/puzzle-graph.json (rev 1.3) as static Swift data. Same
// architecture as Level 1 (PuzzleGraphModel.swift): progression is tracked as satisfied-
// requirement FLAGS + one derived condition, never as literal step sequences. Any ordering
// that satisfies the `requires` edges is a valid solve path (solve_path_notes.state_model).
//
// Fixed solution values are transcribed EXACTLY from the graph and are never randomized.

/// The two arbor posts of the z2 automaton gear frame (p06). The 24:1 ratio product
/// commutes, so {36,64} is valid in EITHER post arrangement (solution_fixed.arrangement).
enum Level2Post { case a, b }

enum Level2Graph {

    // MARK: Zones / views

    enum ZoneID {
        static let z1Attic = "z1-attic"
        static let z2Workroom = "z2-workroom"
        static let z3BehindDial = "z3-behind-dial"
        static let z4Vault = "z4-vault"
    }

    /// zones[0].start_zone == true.
    static let startZoneID = ZoneID.z1Attic

    enum PuzzleID {
        static let dialDoor = "p01-dial-door"
        static let catMouse = "p02-cat-mouse"
        static let cacheDormer = "p03-cache-dormer"
        static let cacheChimney = "p04-cache-chimney"
        static let freeArbor = "p05-free-arbor"
        static let gearTrain = "p06-gear-train"
        static let vaultWheels = "p07-vault-wheels"
        static let oilWind = "p08-oil-wind"
        static let setHands = "p09-set-hands"
        static let startPendulum = "p10-start-pendulum"
        static let exit = "p11-exit"
    }

    enum ItemID {
        static let screwdriver = "itm-screwdriver"
        static let tileII = "itm-tile-ii"
        static let tileIV = "itm-tile-iv"
        static let tileVII = "itm-tile-vii"
        static let tileXI = "itm-tile-xi"
        static let watchA = "itm-watch-a"
        static let toyMouse = "itm-toy-mouse"
        static let watchB = "itm-watch-b"
        static let greatWheel = "itm-great-wheel"
        static let oilcan = "itm-oilcan"
        static let windingKey = "itm-winding-key"
        static let returnTag = "itm-return-tag"

        /// The tiles that seat into the p01 door dial (all four required).
        static let dialTiles: Set<String> = [tileII, tileIV, tileVII, tileXI]
    }

    /// In-scene decoys that are NEVER inventory items (standing R6-003 principle). They can be
    /// picked up *within* their close-up and offered to a socket, where they are refused — the
    /// bait's whole job. Given a distinct id namespace so it can never match `dialSolution`.
    enum DecoyTile {
        /// p01 tray VI: the loose tile in the door tray. solution_fixed lists it as
        /// "rejected: tray VI in socket-4".
        static let trayVI = "tile-vi-decoy"
    }

    /// Persistent latched state flags (kept in GameState.flags, the shared bag).
    enum Flag {
        static let arborFreed = "l2-arbor-freed"        // p05 (oiled the seized bearing)
        static let drumOiled = "l2-drum-oiled"          // p08 step 1 (drum bearing oiled)
        static let clockWound = "l2-clock-wound"        // p08 (drive weight fully raised)
        static let pendulumRunning = "l2-pendulum-running" // p10 (bob pushed)
        static let doorBarRaised = "l2-door-bar-raised" // cond-timelock-release latch
        static let cabinetDrawerOpened = "l2-cabinet-drawer-opened" // z2 parts-cabinet drawer pulled
        /// Round 8 (R8-013, user ruling): the cushion the cat vacated has been LIFTED, so
        /// watch B is revealed and waiting for a deliberate tap. Restores the manual-pickup
        /// step the graph describes ("cushion now liftable; watch B beneath") in place of the
        /// build-15 auto-grant, per the standing L1 manual-pickup principle (F-023 / R2-003).
        static let cushionLifted = "l2-cushion-lifted"
    }

    // MARK: Fixed solution values (never randomized)

    /// p01 door dial: socket position (as String key) -> the tile item id that completes it.
    /// The tray VI decoy is rejected everywhere (pops back). solution_fixed.
    static let dialSolution: [String: String] = [
        "2": ItemID.tileII,
        "4": ItemID.tileIV,
        "7": ItemID.tileVII,
        "11": ItemID.tileXI,
    ]
    static let dialSockets = ["2", "4", "7", "11"]

    /// p06 gear train: the unique meshing pair anywhere in the level is {36, 64}. The 64 is
    /// the found great wheel; the 36 lives on the rack. Either post arrangement is correct
    /// (ratio product commutes). Rack decoy set {16,24,40,48,72} + the lone 48 (rh-48-gear).
    static let gearSolutionSet: Set<String> = ["36", "64"]
    static let rackGears = ["16", "24", "36", "40", "48", "72"]
    static let gearGreatWheelValue = "64"     // itm-great-wheel's mounted value

    /// p07 vault hatch: wheels read VI-X-I-III under headers Big Ben / Burj / Liberty / Fuji
    /// (z3 binding order). CODE CHANGED at rev 1.2 (Dubai replaces Paris). solution_fixed.
    static let vaultSolution = [6, 10, 1, 3]
    static let vaultHeaders = ["bigben", "burj", "liberty", "fuji"]

    /// p09 hand-setting: mechanism FRONT time = 7:20 (D1 canonical front-time). In minutes.
    static let clockReleaseMinutes = 7 * 60 + 20   // 440
    /// The un-mirrored naive trap: copying the tag's hand positions onto the mirrored back
    /// view sets the FRONT to 4:40. Present only so tests assert it does NOT release.
    static let clockNaiveTrapMinutes = 4 * 60 + 40 // 280

    // MARK: Item lifecycle uses (graph itm-* `uses` arrays, transcribed verbatim)
    //
    // Retain while ANY use unsatisfied; consume when ALL satisfied. Empty `uses` (the three
    // clue-carrier watches/tag) are NEVER auto-consumed (same rule as L1's rusted-key).

    /// Items the graph nodes mark **explicitly NEVER consumed** — retained whole level
    /// regardless of their `uses` (itm-screwdriver, itm-oilcan "and beyond"). This is a
    /// per-item override of the generic consume-when-all-uses-done rule (m1 QA fidelity
    /// fix): both still LIST their uses below for documentation, but the lifecycle never
    /// drops them. No soft-lock risk (there is no use after their last one anyway).
    static let neverConsumedItems: Set<String> = [ItemID.screwdriver, ItemID.oilcan]

    static let itemUses: [String: [String]] = [
        ItemID.screwdriver: [PuzzleID.cacheDormer, PuzzleID.cacheChimney],
        ItemID.tileII: [PuzzleID.dialDoor],
        ItemID.tileIV: [PuzzleID.dialDoor],
        ItemID.tileVII: [PuzzleID.dialDoor],
        ItemID.tileXI: [PuzzleID.dialDoor],
        ItemID.watchA: [],
        ItemID.toyMouse: [PuzzleID.catMouse],
        ItemID.watchB: [],
        ItemID.greatWheel: [PuzzleID.gearTrain],
        ItemID.oilcan: [PuzzleID.freeArbor, PuzzleID.oilWind],
        ItemID.windingKey: [PuzzleID.oilWind],
        ItemID.returnTag: [],
    ]
}

/// Level 2 clue nodes (persisted in GameState.viewedClues once their view is displayed).
enum Level2ClueID {
    static let slateRatio = "clu-slate-ratio"
    static let watchA = "clu-watch-a"
    static let watchB = "clu-watch-b"
    static let ringDormer = "clu-ring-dormer"
    static let ringChimney = "clu-ring-chimney"
    static let masterTime = "clu-master-time"
    static let worldClockRow = "clu-worldclock-row"
    static let mirroredNumerals = "clu-mirrored-numerals"
    static let returnTag = "clu-return-tag"
    static let linkageRods = "clu-linkage-rods"
    static let catRefusal = "clu-cat-refusal"
}

/// rev-1.3 `clue_gate` table for Level 2 as static data. A gated puzzle does not accept its
/// solution — even the correct one — until every listed clue has been VIEWED (no-tell). The
/// two pry caches (p03/p04) additionally give the D10 faint-tell on the CORRECT spot while
/// gated; that presentation cue lives in the coordinator, the gate logic is here.
enum Level2ClueGate {
    static let requiredClues: [String: [String]] = [
        Level2Graph.PuzzleID.cacheDormer: [Level2ClueID.watchA],
        Level2Graph.PuzzleID.cacheChimney: [Level2ClueID.watchB],
        Level2Graph.PuzzleID.vaultWheels: [Level2ClueID.masterTime, Level2ClueID.worldClockRow],
        Level2Graph.PuzzleID.setHands: [Level2ClueID.returnTag],
    ]

    static func isSatisfied(_ puzzleID: String, state: GameState) -> Bool {
        guard let required = requiredClues[puzzleID] else { return true }
        return required.allSatisfy { state.hasViewedClue($0) }
    }

    static func isGated(_ puzzleID: String) -> Bool { requiredClues[puzzleID] != nil }
}

/// Uses-driven item lifecycle for Level 2 (mirrors L1's ItemLifecycle). One rule: retain an
/// item while any of its graph `uses` is unsatisfied; consume it once all are satisfied.
/// Empty-uses items (clue carriers) are never auto-consumed. Reconciled from GameState's
/// markSolved/setFlag hooks via Level2Rules, so no interaction path can bypass it.
enum Level2Lifecycle {
    /// TRUE iff the item still has at least one unsatisfied use (must be retained).
    static func hasRemainingUse(_ itemID: String, state: GameState) -> Bool {
        if Level2Graph.neverConsumedItems.contains(itemID) { return true }   // m1: graph says NEVER consumed
        guard let uses = Level2Graph.itemUses[itemID] else { return true }   // unknown: never drop
        guard !uses.isEmpty else { return true }                            // clue carrier: never drop
        return uses.contains { !state.hasSolved($0) }
    }

    static func isDepleted(_ itemID: String, state: GameState) -> Bool {
        !hasRemainingUse(itemID, state: state)
    }

    static func reconcile(_ state: GameState) {
        for itemID in state.inventory where isDepleted(itemID, state: state) {
            state.removeItem(itemID)
        }
    }
}

/// Level 2 rules object consumed by GameState (start zone + lifecycle reconcile).
struct Level2Rules: LevelRules {
    var startZoneID: String { Level2Graph.startZoneID }
    func reconcile(_ state: GameState) { Level2Lifecycle.reconcile(state) }
}
