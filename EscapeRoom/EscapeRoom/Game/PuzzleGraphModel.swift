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

    enum StateFlag {
        static let moonbeamOn = "moonbeam-on"
        static let mirrorDetent3 = "mirror-at-detent-3"
        static let draughtReady = "draught-ready"
        static let crowFreed = "crow-freed"
        static let doorUnsealed = "door-unsealed"
        /// D5: one-shot cosmetic latch for the clock cuckoo pop. Never gates progression.
        static let clockCuckooSpent = "clock-cuckoo-spent"
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
