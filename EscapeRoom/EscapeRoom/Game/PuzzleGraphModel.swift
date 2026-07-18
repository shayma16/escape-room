import Foundation

// MARK: - Requirement-based puzzle model
//
// This mirrors specs/levels/level-1/puzzle-graph.json (rev 1.2) as static Swift data.
// Per CLAUDE.md / puzzle-graph solve_path_notes.state_model: progression is tracked as
// satisfied-requirement FLAGS and derived boolean CONDITIONS, never as literal step
// sequences. Any ordering that satisfies the `requires` edges is a valid solve path.
//
// Solution values below are the fixed values from the puzzle graph and must never be
// randomized (CLAUDE.md "Static, fixed solution values").

/// A single requirement that must hold for a puzzle/action to be available or to solve.
enum Requirement: Equatable, Codable {
    case item(String)              // player holds this item id
    case zone(String)              // this zone is unlocked
    case state(String)             // this named boolean state flag is true
    case condition(String)         // this derived condition (see DerivedConditions) is true

    func isSatisfied(by state: GameState) -> Bool {
        switch self {
        case .item(let id): return state.inventory.contains(id)
        case .zone(let id): return state.unlockedZones.contains(id)
        case .state(let id): return state.flags.contains(id)
        case .condition(let id): return state.evaluateCondition(id)
        }
    }
}

/// Derived boolean conditions re-evaluated continuously from persistent latched states.
/// D2 (developer_notes): cond-beam-at-alcove must be re-evaluated on every change to its
/// inputs, never gated on the order those inputs were achieved.
struct DerivedCondition {
    let id: String
    let inputStateFlags: [String]  // ALL must be true (AND) — level 1 only needs AND.

    func isTrue(flags: Set<String>) -> Bool {
        inputStateFlags.allSatisfy { flags.contains($0) }
    }
}

enum PuzzleGraph {
    /// cond-beam-at-alcove = moonbeam-on AND mirror-at-detent-3 (derived_conditions[0]).
    static let derivedConditions: [DerivedCondition] = [
        DerivedCondition(id: "cond-beam-at-alcove",
                          inputStateFlags: ["moonbeam-on", "mirror-at-detent-3"])
    ]

    /// Puzzle ids, used across the engine and tests. Matches puzzle-graph.json node ids.
    enum PuzzleID {
        static let runeDoor = "p01-rune-door"
        static let moonTrapdoor = "p02-moon-trapdoor"
        static let astrolabeOrion = "p03-astrolabe-orion"
        static let cabinetSunMoon = "p04-cabinet-sun-moon"
        static let ashSift = "p05-ash-sift"
        static let barrelPry = "p06-barrel-pry"
        static let shelfCounterweight = "p07-shelf-counterweight"
        static let shutterWinch = "p08-shutter-winch"
        static let mirrorAim = "p09-mirror-aim"
        static let moonflowerBloom = "p10-moonflower-bloom"
        static let cageUnlock = "p11-cage-unlock"
        static let fileShavings = "p12-file-shavings"
        static let grindPaste = "p13-grind-paste"
        static let brew = "p14-brew"
        static let fillPhial = "p15-fill-phial"
        static let doorUnseal = "p16-door-unseal"
        static let escape = "p17-escape"
    }

    /// Item ids, matches puzzle-graph.json item node ids.
    enum ItemID {
        static let poker = "itm-poker"
        static let rustedKey = "itm-rusted-key"
        static let goldRing = "itm-gold-ring"
        static let crank = "itm-crank"
        static let silverCoin = "itm-silver-coin"
        static let file = "itm-file"
        static let phial = "itm-phial"
        static let spoon = "itm-spoon"
        static let shavings = "itm-shavings"
        static let weight = "itm-weight"
        static let cageKey = "itm-cage-key"
        static let blossom = "itm-blossom"
        static let paste = "itm-paste"
        static let feather = "itm-feather"
        static let phialDraught = "itm-phial-draught"
    }

    enum ZoneID {
        static let z1Cabin = "z1-cabin"
        static let z2Workshop = "z2-workshop"
        static let z3Cellar = "z3-cellar"
        static let z4Alcove = "z4-alcove"
    }

    /// zones[0].start_zone == true in puzzle-graph.json. The start zone is unlocked
    /// from the very first frame of a fresh save (QA-BUG-001: nothing else ever adds
    /// it to unlockedZones, which left all z1 views unreachable).
    static let startZoneID = ZoneID.z1Cabin

    enum StateFlag {
        static let moonbeamOn = "moonbeam-on"
        static let mirrorDetent3 = "mirror-at-detent-3"
        static let draughtReady = "draught-ready"
        static let crowFreed = "crow-freed"
        static let doorUnsealed = "door-unsealed"
        /// D5: one-shot cosmetic latch for the clock cuckoo pop. Never gates progression.
        static let clockCuckooSpent = "clock-cuckoo-spent"
        /// p02's "free-action: move rug" requirement (QA-BUG-010). A satisfied-
        /// requirement flag like any other: once the rug has been moved it stays moved.
        /// The dial panel is only reachable through the trapdoor discovered underneath,
        /// so the UI gates the dial close-up on this flag; the engine's dial evaluation
        /// itself stays flag-free because the dials are physically unreachable before
        /// discovery (verified by coordinator tests, not an engine gate).
        static let rugMoved = "rug-moved"
        /// Cellar root-shelf drawer opened (latched free action; feedback round 1 —
        /// the spoon is taken with its own tap after opening, per the manual-pickup
        /// interaction convention).
        static let cellarDrawerOpened = "cellar-drawer-opened"
    }
}

/// Fixed rune-door solution (p01). Order is AIR, FIRE, EARTH, WATER per puzzle-graph.json
/// solution_fixed. Tile-to-rune mapping is from the asset manifest
/// (runedoor-tiles.json): tile1=FIRE, tile2=WATER, tile3=AIR, tile4=EARTH.
enum RuneDoorSolution {
    enum Rune: String, CaseIterable { case air = "AIR", fire = "FIRE", earth = "EARTH", water = "WATER" }

    /// Fixed fully-specified press order, never randomized.
    static let solutionOrder: [Rune] = [.air, .fire, .earth, .water]

    /// tile id -> rune, from the asset manifest's authoritative rect/rune mapping.
    static let tileRune: [Int: Rune] = [1: .fire, 2: .water, 3: .air, 4: .earth]
}

/// Fixed moon-phase trapdoor solution (p02). Dial index 1/2/3 corresponds to the
/// triptych paintings' crow count (1/2/3 crows); dial VALUE is the moon phase shown in
/// that same painting. Order/value are both fixed per puzzle-graph.json.
enum MoonDialSolution {
    enum Phase: String, CaseIterable {
        case new, waxingCrescent, firstQuarter, waxingGibbous, full, waningGibbous, lastQuarter, waningCrescent
    }
    /// Clockwise order from `dial-face` sprite (8 phases), matches asset manifest note.
    static let clockwiseOrder: [Phase] = [.new, .waxingCrescent, .firstQuarter, .waxingGibbous,
                                           .full, .waningGibbous, .lastQuarter, .waningCrescent]

    /// Fixed solution: dial1 = waxing-crescent, dial2 = full, dial3 = waning-gibbous.
    static let solution: [Phase] = [.waxingCrescent, .full, .waningGibbous]
}

/// Fixed astrolabe solution (p03): plate-2 is Orion.
enum AstrolabeSolution {
    static let solutionPlateIndex = 2 // 1-based, matches plate_set / sprite naming plate-2
}

/// Fixed brew parameters (p14).
enum BrewSolution {
    static let flameStage = 3
    enum StirDirection: Equatable { case clockwise, counterclockwise }
    static let stirDirection: StirDirection = .counterclockwise
    static let stirCount = 5
    static let requiredIngredients: Set<String> = [
        PuzzleGraph.ItemID.paste, PuzzleGraph.ItemID.shavings, PuzzleGraph.ItemID.feather
    ]
}

/// Fixed cabinet sun/moon solution (p04).
enum CabinetSolution {
    static let sunSlotItem = PuzzleGraph.ItemID.goldRing
    static let moonSlotItem = PuzzleGraph.ItemID.silverCoin
}

/// Fixed mirror-aim solution (p09): detent-3.
enum MirrorSolution {
    static let solutionDetent = 3
    static let detentCount = 3
}

// MARK: - Item lifecycle (build 10, cluster A — R4-019 🔴 / R4-030 / R2-020)
//
// ONE graph-driven rule replaces the old ad-hoc per-item drop closures:
//
//     An item is RETAINED while ANY entry in its puzzle-graph `uses` array is
//     unsatisfied, and CONSUMED (removed from inventory) once ALL of them are
//     satisfied. Items whose `uses` array is EMPTY (the rusted-key red herring)
//     are NEVER auto-consumed.
//
// This fixes both directions of the build-9 lifecycle defect at once: R4-019
// (a multi-use tool must never disappear while a use remains — the poker
// soft-lock on barrel-before-ash orderings) and R4-030 (single-use items must
// not linger after their only use — spoon + file after p12).
//
// PLACED items (gold ring / silver coin into the cabinet, blossom into the
// mortar, ingredients into the cauldron, phial -> draught, draught -> basin)
// keep their existing consume-on-placement in the engine; this table simply
// AGREES with those placements (their single use is satisfied at the same
// moment the engine removes them), so `reconcile` never fights the engine.
//
// The `uses` data below transcribes puzzle-graph.json rev 1.3 item nodes
// verbatim (itm-* `uses` arrays); each use maps to the requirement-state fact
// that proves that use is done. Spec-note conflict recorded in implementation
// notes: the graph's anti_softlock_invariants text says poker/file/crank are
// "never consumed" — the user-approved round-4 changelist (checkpoint 1,
// 2026-07-11) supersedes that at the INVENTORY level with the uses-driven rule
// above, which preserves the invariant's actual purpose (no removal while a
// use remains).
enum ItemLifecycle {
    /// One entry of an item's puzzle-graph `uses` array: the use's puzzle id and
    /// the pure state predicate that holds iff that use has been satisfied.
    struct Use {
        let puzzleID: String
        let isSatisfied: (GameState) -> Bool
    }

    /// item id -> its graph `uses` entries. EVERY itm-* node is present so the
    /// unit-test invariant can be asserted against the graph for every item.
    static let uses: [String: [Use]] = [
        PuzzleGraph.ItemID.poker: [
            Use(puzzleID: PuzzleGraph.PuzzleID.ashSift) { $0.hasSolved(PuzzleGraph.PuzzleID.ashSift) },
            Use(puzzleID: PuzzleGraph.PuzzleID.barrelPry) { $0.hasSolved(PuzzleGraph.PuzzleID.barrelPry) },
        ],
        PuzzleGraph.ItemID.rustedKey: [], // red herring: uses [] -> never consumed
        PuzzleGraph.ItemID.goldRing: [
            Use(puzzleID: PuzzleGraph.PuzzleID.cabinetSunMoon) { $0.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) },
        ],
        PuzzleGraph.ItemID.crank: [
            Use(puzzleID: PuzzleGraph.PuzzleID.shutterWinch) { $0.hasFlag(PuzzleGraph.StateFlag.moonbeamOn) },
        ],
        PuzzleGraph.ItemID.silverCoin: [
            Use(puzzleID: PuzzleGraph.PuzzleID.cabinetSunMoon) { $0.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) },
        ],
        PuzzleGraph.ItemID.file: [
            Use(puzzleID: PuzzleGraph.PuzzleID.fileShavings) { $0.hasSolved(PuzzleGraph.PuzzleID.fileShavings) },
        ],
        PuzzleGraph.ItemID.phial: [
            Use(puzzleID: PuzzleGraph.PuzzleID.fillPhial) { $0.hasSolved(PuzzleGraph.PuzzleID.fillPhial) },
        ],
        PuzzleGraph.ItemID.spoon: [
            Use(puzzleID: PuzzleGraph.PuzzleID.fileShavings) { $0.hasSolved(PuzzleGraph.PuzzleID.fileShavings) },
        ],
        PuzzleGraph.ItemID.shavings: [
            Use(puzzleID: PuzzleGraph.PuzzleID.brew) { $0.hasSolved(PuzzleGraph.PuzzleID.brew) },
        ],
        PuzzleGraph.ItemID.weight: [
            Use(puzzleID: PuzzleGraph.PuzzleID.shelfCounterweight) { $0.hasSolved(PuzzleGraph.PuzzleID.shelfCounterweight) },
        ],
        PuzzleGraph.ItemID.cageKey: [
            Use(puzzleID: PuzzleGraph.PuzzleID.cageUnlock) { $0.hasFlag(PuzzleGraph.StateFlag.crowFreed) },
        ],
        PuzzleGraph.ItemID.blossom: [
            Use(puzzleID: PuzzleGraph.PuzzleID.grindPaste) { $0.hasSolved(PuzzleGraph.PuzzleID.grindPaste) },
        ],
        PuzzleGraph.ItemID.paste: [
            Use(puzzleID: PuzzleGraph.PuzzleID.brew) { $0.hasSolved(PuzzleGraph.PuzzleID.brew) },
        ],
        PuzzleGraph.ItemID.feather: [
            Use(puzzleID: PuzzleGraph.PuzzleID.brew) { $0.hasSolved(PuzzleGraph.PuzzleID.brew) },
        ],
        PuzzleGraph.ItemID.phialDraught: [
            Use(puzzleID: PuzzleGraph.PuzzleID.doorUnseal) { $0.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) },
        ],
    ]

    /// TRUE iff the item still has at least one unsatisfied use (must be retained).
    static func hasRemainingUse(_ itemID: String, state: GameState) -> Bool {
        guard let entries = uses[itemID] else { return true } // unknown item: never drop
        guard !entries.isEmpty else { return true }           // uses [] (red herring): never drop
        return entries.contains { !$0.isSatisfied(state) }
    }

    /// TRUE iff EVERY use of the item is satisfied (safe to consume).
    static func isDepleted(_ itemID: String, state: GameState) -> Bool {
        !hasRemainingUse(itemID, state: state)
    }

    /// Sweeps the whole inventory, removing every held item whose uses are ALL
    /// satisfied. Called from the GameState markSolved/setFlag hooks (every way a
    /// use can become satisfied passes through one of those two mutators), so no
    /// interaction path can forget to reconcile — the R4-030 failure mode. It can
    /// never violate the anti-softlock invariant by construction: an item with an
    /// unsatisfied use always has `hasRemainingUse == true` and is left alone.
    static func reconcile(_ state: GameState) {
        for itemID in state.inventory where isDepleted(itemID, state: state) {
            state.removeItem(itemID)
        }
    }
}

// MARK: - Clue-gating (puzzle-graph.json rev 1.3, F-012 user decision 2026-07-07)
//
// Code-entry puzzles do NOT accept their solution — even the correct one — until their
// gating clue set has been VIEWED in-game (per-node `clue_gate.required_viewed`). A gated
// attempt replays the puzzle's EXISTING failure grammar with NO tell (clue_gating.
// no_tell_rule). Clue-viewed flags are ordinary satisfiable requirements persisted in the
// save (D7); they never re-lock and are never cleared. Branch order-freedom is unchanged.
//
// Validator rev-1.3 PASS confirmed: every gating clue sits in z1 (always-open start zone)
// or the gated puzzle's own zone, so a gate is always satisfiable when its puzzle is
// reachable (no soft-lock). IC-2 (persistence) is honored by GameState.viewedClues.
enum ClueID {
    static let markAir = "clu-mark-air"
    static let markFire = "clu-mark-fire"
    static let markEarth = "clu-mark-earth"
    static let markWater = "clu-mark-water"
    static let grimoireElements = "clu-grimoire-elements"   // page A
    static let triptych = "clu-triptych"
    static let windowOrion = "clu-window-orion"
    static let slotShapes = "clu-slot-shapes"               // cabinet slots OR grimoire page B
    static let recipePage = "clu-recipe-page"
}

/// The rev-1.3 `clue_gate` table as static Swift data. Maps each GATED puzzle to the set
/// of clue ids that must all have been viewed before its solution is accepted. Ungated
/// puzzles are simply absent (all physical-act puzzles: p05–p13, p15–p17).
enum ClueGate {
    /// puzzle id -> required-viewed clue ids (AND semantics).
    ///
    /// p01 page-A ruling (user, 2026-07-07, FINAL — do NOT demote): grimoire page A stays
    /// REQUIRED alongside the four rune marks. Both Designer and Validator advised demoting
    /// it to optional; the user chose the strict "must view all clues" reading. Kept as a
    /// single config constant so the ruling could be flipped without touching call sites,
    /// but it is intentionally left as REQUIRED per the final ruling.
    static let p01PageARequired = true

    static let requiredClues: [String: [String]] = {
        var table: [String: [String]] = [
            PuzzleGraph.PuzzleID.moonTrapdoor: [ClueID.triptych],
            PuzzleGraph.PuzzleID.astrolabeOrion: [ClueID.windowOrion],
            PuzzleGraph.PuzzleID.cabinetSunMoon: [ClueID.slotShapes],
            PuzzleGraph.PuzzleID.brew: [ClueID.recipePage],
        ]
        var p01 = [ClueID.markAir, ClueID.markFire, ClueID.markEarth, ClueID.markWater]
        if p01PageARequired { p01.append(ClueID.grimoireElements) }
        table[PuzzleGraph.PuzzleID.runeDoor] = p01
        return table
    }()

    /// Whether a puzzle's gate is currently satisfied (all required clues viewed). Ungated
    /// puzzles return true unconditionally.
    static func isSatisfied(_ puzzleID: String, state: GameState) -> Bool {
        guard let required = requiredClues[puzzleID] else { return true }
        return required.allSatisfy { state.hasViewedClue($0) }
    }

    static func isGated(_ puzzleID: String) -> Bool {
        requiredClues[puzzleID] != nil
    }
}
