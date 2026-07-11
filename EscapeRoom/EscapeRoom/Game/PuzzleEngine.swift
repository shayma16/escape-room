import Foundation

/// Applies puzzle-graph.json node logic to a GameState. Each function is a pure
/// requirement check + state mutation — never a step-order gate. Multiple call sites
/// (any valid interleaving per solve_path_notes) can call these in any order and the
/// engine still converges correctly, satisfying "requirement met, not action sequence."
enum PuzzleEngine {

    // MARK: - p01 rune door

    /// Called each time a rune tile is pressed. `progress` is appended to; once it
    /// reaches 4 entries it's checked against the fixed solution. Any mismatch resets
    /// with "no lockout" (failure_behavior: "tiles reset with a dull knock").
    @discardableResult
    static func pressRuneTile(_ rune: RuneDoorSolution.Rune, state: GameState) -> RuneDoorResult {
        var progress = state.data.runeDoorProgress.compactMap { RuneDoorSolution.Rune(rawValue: $0) }
        progress.append(rune)

        if progress.count < RuneDoorSolution.solutionOrder.count {
            state.setRuneDoorProgress(progress.map(\.rawValue))
            return .inProgress
        }

        // Clue-gating (rev 1.3): even the CORRECT sequence resets with the same dull
        // knock until the gate is satisfied — no tell (gate_behavior). Tiles self-reset
        // so no stale-correct-input case exists here (D6).
        if progress == RuneDoorSolution.solutionOrder
            && ClueGate.isSatisfied(PuzzleGraph.PuzzleID.runeDoor, state: state) {
            state.setRuneDoorProgress([])
            state.markSolved(PuzzleGraph.PuzzleID.runeDoor)
            state.unlockZone(PuzzleGraph.ZoneID.z2Workshop)
            return .solved
        } else {
            state.setRuneDoorProgress([])
            return .reset
        }
    }

    enum RuneDoorResult: Equatable { case inProgress, solved, reset }

    // MARK: - p02 moon-phase trapdoor

    /// The "free-action: move rug" requirement (p02 `requires`; QA-BUG-010). A latched
    /// satisfied-requirement flag: moving the rug once reveals the trapdoor forever.
    static func moveRug(state: GameState) {
        state.setFlag(PuzzleGraph.StateFlag.rugMoved)
    }

    /// Cellar root-shelf drawer (feedback round 1): the drawer's graph states are
    /// shut / open-with-spoon / open-empty. Opening is a latched free action; the
    /// spoon is then taken with its own explicit tap (manual pickup, same F-023
    /// philosophy as the containers). The previous build overlaid the drawer art
    /// inverted (open-empty before pickup, spoon-still-there after) — fixed here.
    static func openCellarDrawer(state: GameState) {
        state.setFlag(PuzzleGraph.StateFlag.cellarDrawerOpened)
    }

    /// Dials retain position between attempts (no lockout); checked whenever the
    /// player commits (e.g. taps a "try" affordance or on every dial settle — Scene
    /// layer decides the trigger, this just evaluates current dial state).
    static func evaluateMoonDials(state: GameState) -> Bool {
        let positions = state.data.moonDialPositions
        guard positions.count == 3 else { return false }
        let phases = positions.map { MoonDialSolution.clockwiseOrder[$0 % MoonDialSolution.clockwiseOrder.count] }
        // Clue-gating (rev 1.3): while gated the trapdoor stays shut on ANY setting,
        // including the correct one — presentation-identical to a wrong code (no tell).
        // The stale-correct-dials case (correct combo left set while gated, triptych
        // viewed later) resolves via IC-1 re-evaluation on close-up entry (see
        // reevaluateOnCloseUpEntry).
        let solved = phases == MoonDialSolution.solution
            && ClueGate.isSatisfied(PuzzleGraph.PuzzleID.moonTrapdoor, state: state)
        if solved {
            state.markSolved(PuzzleGraph.PuzzleID.moonTrapdoor)
            state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        }
        return solved
    }

    /// IC-1 (D6 rule b): re-evaluate p02's gate+solution when its close-up is (re-)entered.
    /// Handles the stale-correct-dials case — correct combo left set while gated, then the
    /// triptych viewed later: on re-entry the trapdoor opens with no pointless input wiggle.
    /// No-op unless the dials already sit on the solution AND the gate is now satisfied.
    static func reevaluateMoonDialsOnCloseUpEntry(state: GameState) {
        guard !state.hasSolved(PuzzleGraph.PuzzleID.moonTrapdoor) else { return }
        _ = evaluateMoonDials(state: state)
    }

    // MARK: - p03 astrolabe

    /// Feedback round 1 (F-023 + merged F-018): solving a container puzzle OPENS the
    /// container and makes its contents visible/collectable — it no longer teleports
    /// the yield into inventory. See `uncollectedItems(in:state:)` / `collectItem`.
    static func selectAstrolabePlate(_ plateIndex: Int, state: GameState) -> Bool {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion) else { return true }
        guard plateIndex == AstrolabeSolution.solutionPlateIndex else { return false }
        // Clue-gating (rev 1.3): the drawer stays shut on ANY plate — including plate-2 —
        // until the Orion window has been viewed (no tell). The stale pointer-on-plate-2
        // case resolves via IC-1 re-evaluation on close-up entry.
        guard ClueGate.isSatisfied(PuzzleGraph.PuzzleID.astrolabeOrion, state: state) else { return false }
        state.markSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
        return true
    }

    /// IC-1 (D6 rule b): re-evaluate p03's gate+solution when its close-up is (re-)entered.
    /// Handles the stale pointer-already-on-plate-2 case — pointer left on the Orion plate
    /// while gated, then the window viewed later: on re-entry the drawer springs open with
    /// no pointless re-selection. Returns true if the puzzle newly solved on this entry, so
    /// the UI can present the sprung-open container immediately.
    @discardableResult
    static func reevaluateAstrolabeOnCloseUpEntry(pointerAtPlate: Int?, state: GameState) -> Bool {
        guard !state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion) else { return false }
        guard let plate = pointerAtPlate else { return false }
        return selectAstrolabePlate(plate, state: state)
    }

    // MARK: - p04 sun/moon cabinet

    /// Wrong/swapped placement pops back to inventory (no loss, no lockout) — modeled
    /// by simply not being called for items that don't match; UI is responsible for
    /// bouncing rejected items back to the inventory bar.
    /// Feedback round 1 (F-023): solving opens the cabinet with the file + phial
    /// visible on the inner shelf; the player collects each with a tap.
    static func placeCabinetItems(sun: String?, moon: String?, state: GameState) -> Bool {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return false }
        guard sun == CabinetSolution.sunSlotItem, moon == CabinetSolution.moonSlotItem,
              state.hasItem(CabinetSolution.sunSlotItem), state.hasItem(CabinetSolution.moonSlotItem) else {
            return false
        }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) else { return true }
        // Clue-gating (rev 1.3, self-satisfying/defensive): seating the items requires the
        // cabinet slot close-up, which itself marks clu-slot-shapes viewed — so in practice
        // the gate is satisfied at the moment of a correct placement. Enforced anyway; a
        // gated placement pops both items back exactly like a swapped placement (no tell).
        guard ClueGate.isSatisfied(PuzzleGraph.PuzzleID.cabinetSunMoon, state: state) else { return false }
        state.removeItem(CabinetSolution.sunSlotItem)
        state.removeItem(CabinetSolution.moonSlotItem)
        state.markSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
        return true
    }

    // MARK: - Container contents (manual pickup, feedback round 1 F-023/F-018)

    /// The two solved-container surfaces whose yields are collected by explicit taps.
    enum Container: String {
        case astrolabeDrawer   // p03 yield: silver coin + crank
        case sunMoonCabinet    // p04 yield: file + phial
    }

    /// Whether a given container item is still waiting to be picked up.
    ///
    /// DERIVED, not stored: an item is uncollected iff its container puzzle is solved
    /// and the player has never taken it — and "never taken" is itself derivable from
    /// requirement state because every possible consumption of these four items is a
    /// tracked puzzle solve (coin -> p04, phial -> p15/p16; crank and file are never
    /// consumed). Deriving it keeps the save format unchanged, migrates old
    /// auto-grant saves for free (they hold or have spent the items, so nothing shows
    /// as collectable twice), and cannot soft-lock a relaunch mid-collection (an
    /// untaken item stays visibly uncollected forever until taken).
    static func isUncollected(_ itemID: String, state: GameState) -> Bool {
        switch itemID {
        case PuzzleGraph.ItemID.silverCoin:
            return state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
                && !state.hasItem(PuzzleGraph.ItemID.silverCoin)
                && !state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) // coin's only sink
        case PuzzleGraph.ItemID.crank:
            // Build 10: the crank IS consumed once its only use (p08) is done
            // (uses-driven lifecycle) — a consumed crank must not re-appear
            // collectable in the drawer.
            return state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
                && !state.hasItem(PuzzleGraph.ItemID.crank)
                && !state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn) // crank's only sink (p08)
        case PuzzleGraph.ItemID.file:
            // Build 10: the file is consumed once p12 is done — same guard.
            return state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
                && !state.hasItem(PuzzleGraph.ItemID.file)
                && !state.hasSolved(PuzzleGraph.PuzzleID.fileShavings) // file's only sink (p12)
        case PuzzleGraph.ItemID.phial:
            return state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
                && !state.hasItem(PuzzleGraph.ItemID.phial)
                && !state.hasItem(PuzzleGraph.ItemID.phialDraught)
                && !state.hasSolved(PuzzleGraph.PuzzleID.fillPhial) // phial's only sink chain
        default:
            return false
        }
    }

    static func containerContents(_ container: Container) -> [String] {
        switch container {
        case .astrolabeDrawer: return [PuzzleGraph.ItemID.silverCoin, PuzzleGraph.ItemID.crank]
        case .sunMoonCabinet: return [PuzzleGraph.ItemID.file, PuzzleGraph.ItemID.phial]
        }
    }

    static func uncollectedItems(in container: Container, state: GameState) -> [String] {
        containerContents(container).filter { isUncollected($0, state: state) }
    }

    /// Explicit pickup tap on a visible container item. Returns false (no state churn)
    /// if the item isn't actually collectable right now.
    @discardableResult
    static func collectItem(_ itemID: String, from container: Container, state: GameState) -> Bool {
        guard containerContents(container).contains(itemID),
              isUncollected(itemID, state: state) else { return false }
        state.addItem(itemID)
        return true
    }

    // MARK: - p05 ash sift (tool-on-hotspot, manual ring pickup)

    /// R2-003a: sifting the ash with the poker REVEALS the ring (marks p05 solved) but no
    /// longer auto-grants it — the player must tap the visible ring to collect it (same
    /// manual-pickup philosophy as the containers, F-023). The ring is uncollected while
    /// p05 is solved and the ring isn't yet held (see `isRingUncollectedInAsh`).
    static func siftAsh(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.poker) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.ashSift) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.ashSift)
        return true
    }

    /// The gold ring sits visible-and-pickable in the sifted ash iff p05 is solved and the
    /// ring hasn't been taken. Derived (not stored), like the container items: the ring's
    /// only sink is p04 (sun slot), so a taken-and-spent ring never re-appears.
    static func isRingUncollectedInAsh(_ state: GameState) -> Bool {
        state.hasSolved(PuzzleGraph.PuzzleID.ashSift)
            && !state.hasItem(PuzzleGraph.ItemID.goldRing)
            && !state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) // ring's only sink
    }

    /// Explicit pickup tap on the visible ash ring. Returns false if not collectable now.
    @discardableResult
    static func collectAshRing(_ state: GameState) -> Bool {
        guard isRingUncollectedInAsh(state) else { return false }
        state.addItem(PuzzleGraph.ItemID.goldRing)
        return true
    }

    // MARK: - p06 barrel pry (tool-on-hotspot, manual weight pickup — R4-013(1))

    /// Build 10: prying REVEALS the weight inside the barrel (marks p06 solved) but no
    /// longer auto-grants it — the player taps the visible weight to collect it, the
    /// same manual-pickup convention as the ash ring and the containers.
    static func pryBarrel(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.poker), state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.barrelPry) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.barrelPry)
        return true
    }

    /// The weight sits visible-and-pickable in the pried barrel iff p06 is solved and
    /// the weight hasn't been taken. Derived, not stored (same pattern as the ash
    /// ring): the weight's only sink is p07 (hung on the hook), so a taken-and-spent
    /// weight never re-appears.
    static func isWeightUncollectedInBarrel(_ state: GameState) -> Bool {
        state.hasSolved(PuzzleGraph.PuzzleID.barrelPry)
            && !state.hasItem(PuzzleGraph.ItemID.weight)
            && !state.hasSolved(PuzzleGraph.PuzzleID.shelfCounterweight) // weight's only sink
    }

    /// Explicit pickup tap on the visible barrel weight. Returns false if not
    /// collectable right now (no state churn).
    @discardableResult
    static func collectBarrelWeight(_ state: GameState) -> Bool {
        guard isWeightUncollectedInBarrel(state) else { return false }
        state.addItem(PuzzleGraph.ItemID.weight)
        return true
    }

    // MARK: - p07 counterweight shelf

    static func hangWeight(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.weight), state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.shelfCounterweight) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.shelfCounterweight)
        state.unlockZone(PuzzleGraph.ZoneID.z4Alcove)
        return true
    }

    // MARK: - p08 shutter winch

    static func fitCrankAndTurn(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.crank), state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar) else { return false }
        state.markSolved(PuzzleGraph.PuzzleID.shutterWinch)
        state.setFlag(PuzzleGraph.StateFlag.moonbeamOn) // persistent latched flag, no timer
        return true
    }

    // MARK: - p09 mirror aim

    /// Order-free by construction (D2 / Validator required fix 2): setting the mirror
    /// to detent-3 before OR after the shutter is opened both work identically, because
    /// cond-beam-at-alcove is re-evaluated from latched flags, not from event order.
    /// QA-BUG-008 fix: p09's solution_fixed is detent-3, so the solved marker is only
    /// set when detent-3 is reached (the mirror-at-detent-3 flag stays the live latch
    /// and is still cleared whenever the mirror is rotated away).
    static func rotateMirror(toDetent detent: Int, state: GameState) {
        state.setMirrorDetent(detent)
        if detent == MirrorSolution.solutionDetent {
            state.setFlag(PuzzleGraph.StateFlag.mirrorDetent3)
            state.markSolved(PuzzleGraph.PuzzleID.mirrorAim)
        } else {
            state.clearFlag(PuzzleGraph.StateFlag.mirrorDetent3)
        }
    }

    // MARK: - p10 moonflower bloom
    // Automatic once cond-beam-at-alcove holds AND z4 is open; UI polls
    // `GameState.evaluateCondition("cond-beam-at-alcove")` continuously (D2) rather
    // than reacting to a one-time event, so it's correct regardless of achievement order.

    static func pickBlossom(state: GameState) -> Bool {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove) else { return false }
        guard state.evaluateCondition("cond-beam-at-alcove") else { return false }
        // QA-BUG-007 fix: the single blossom is picked exactly once (visual state:
        // "one blossom picked"); the same already-solved guard every sibling has.
        guard !state.hasSolved(PuzzleGraph.PuzzleID.moonflowerBloom) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.moonflowerBloom)
        state.addItem(PuzzleGraph.ItemID.blossom)
        return true
    }

    // MARK: - Statue key (manual pickup from the close-up — R4-026)

    /// The star-bit key hangs from the crow statue's beak until explicitly collected
    /// (build 10: was an auto-grant on the statue hotspot tap). Derived, not stored:
    /// the key's only sink is p11 (spent unlocking the cage), so once the crow is
    /// freed the key never re-appears.
    static func isStatueKeyUncollected(_ state: GameState) -> Bool {
        state.isZoneUnlocked(PuzzleGraph.ZoneID.z4Alcove)
            && !state.hasItem(PuzzleGraph.ItemID.cageKey)
            && !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) // key's only sink (p11)
    }

    /// Explicit pickup tap on the key in the statue close-up.
    @discardableResult
    static func collectStatueKey(_ state: GameState) -> Bool {
        guard isStatueKeyUncollected(state) else { return false }
        state.addItem(PuzzleGraph.ItemID.cageKey)
        return true
    }

    // MARK: - p11 cage unlock ("freely given" beat)

    static func unlockCage(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.cageKey) else { return false }
        guard !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.cageUnlock)
        state.setFlag(PuzzleGraph.StateFlag.crowFreed)
        state.addItem(PuzzleGraph.ItemID.feather)
        return true
    }

    /// D3/D4: reaching into the cage OR offering ANY inventory item at the brass feed
    /// cup (including itm-phial-draught per the D1 BLOCK ruling) triggers the IDENTICAL
    /// terminal-refusal grammar every time — no escalation, no state change, item
    /// (if any) returns to inventory unspent. This function intentionally mutates
    /// NOTHING; it exists so call sites have one shared, obviously-side-effect-free path.
    static func triggerCrowTerminalRefusal() {
        // No state mutation by design (anti_softlock_invariants: "no consumable is
        // destroyed... feed-cup offers return the item unspent per D4"). The caller
        // (Scene layer) plays the refusal animation/SFX and returns the dragged item
        // to the inventory bar without ever removing it from inventory.
    }

    // MARK: - p12 file shavings (item combination, order-free of other puzzles)

    static func fileShavings(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.file), state.hasItem(PuzzleGraph.ItemID.spoon) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.fileShavings) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.fileShavings)
        state.addItem(PuzzleGraph.ItemID.shavings)
        // Build 10 (R4-030): p12 is the ONLY graph use of BOTH the file and the spoon,
        // so the markSolved lifecycle hook consumes them both here (uses-driven rule).
        return true
    }

    // MARK: - p13 grind paste

    static func grindPaste(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.blossom), state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.grindPaste) else { return true }
        state.removeItem(PuzzleGraph.ItemID.blossom)
        state.markSolved(PuzzleGraph.PuzzleID.grindPaste)
        state.addItem(PuzzleGraph.ItemID.paste)
        return true
    }

    // MARK: - p14 brew (procedural, parameterized, ingredient-order-free)

    enum BrewOutcome: Equatable { case success, fizzle, notReady }

    /// Ingredients may be added in ANY order (explicitly order-free per spec). Only
    /// flame stage and stir direction/count are parameterized and checked at resolve.
    /// Failure returns all three ingredients to inventory intact (no loss, infinitely
    /// retryable) and reverts the cauldron to water.
    static func resolveBrew(flameStage: Int, stirDirection: BrewSolution.StirDirection, stirCount: Int, state: GameState) -> BrewOutcome {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return .notReady }
        // QA-BUG-006 fix: once the draught is ready, the brew is done — re-stirring an
        // already-successful cauldron must never fizzle it back nor re-grant the spent
        // ingredients (they were consumed INTO the draught). The cauldron stays
        // draught-ready forever (p15 refill invariant).
        guard !state.hasFlag(PuzzleGraph.StateFlag.draughtReady) else { return .notReady }
        let ingredients = state.data.cauldronIngredients
        guard ingredients == BrewSolution.requiredIngredients else { return .notReady }

        // Clue-gating (rev 1.3): while gated, the RESOLVE is inert — any resolve, including
        // a fully correct one, produces the standard gray fizzle with all three ingredients
        // returned intact (no tell, nothing consumed — one retry at most). Resolve is an
        // explicit act and failure fully resets the pot, so no stale-state case exists (D6).
        let gateOpen = ClueGate.isSatisfied(PuzzleGraph.PuzzleID.brew, state: state)
        let success = gateOpen
            && flameStage == BrewSolution.flameStage
            && stirDirection == BrewSolution.stirDirection
            && stirCount == BrewSolution.stirCount

        if success {
            state.markSolved(PuzzleGraph.PuzzleID.brew)
            state.setFlag(PuzzleGraph.StateFlag.draughtReady)
            // QA-BUG-006 fix (second half): the ingredients are spent into the draught —
            // clear the cauldron set so no later resolve can "return" them to inventory.
            state.setCauldronIngredients([])
            return .success
        } else {
            // Fizzle: nothing consumed, ingredients float back to inventory intact.
            for id in ingredients { state.addItem(id) }
            state.setCauldronIngredients([])
            return .fizzle
        }
    }

    // MARK: - p15 fill phial

    /// Cauldron remains draught-ready after filling, so refills always possible — this
    /// invariant is load-bearing for the D1 BLOCK ruling at the feed cup (a mis-poured
    /// phial can always be refilled from the still-ready cauldron, though D1 in this
    /// build simply blocks the pour so the phial is never actually spent there).
    static func fillPhial(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.phial), state.hasFlag(PuzzleGraph.StateFlag.draughtReady) else { return false }
        state.removeItem(PuzzleGraph.ItemID.phial)
        state.markSolved(PuzzleGraph.PuzzleID.fillPhial)
        state.addItem(PuzzleGraph.ItemID.phialDraught)
        return true
    }

    // MARK: - p16 door unseal (endgame)

    static func pourDraughtOnBasin(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.phialDraught) else { return false }
        state.removeItem(PuzzleGraph.ItemID.phialDraught)
        state.markSolved(PuzzleGraph.PuzzleID.doorUnseal)
        state.setFlag(PuzzleGraph.StateFlag.doorUnsealed)
        return true
    }

    /// D1 (user-approved option (a), BLOCK): the brass feed cup is a plausible mis-pour
    /// target for the draught specifically. We BLOCK the pour — zero state churn, the
    /// phial-of-draught returns to inventory unspent — and reuse the D4 terminal-refusal
    /// grammar for visual/audio consistency. This function mutates nothing, mirroring
    /// `triggerCrowTerminalRefusal()`.
    static func attemptPourDraughtAtFeedCup() {
        // Intentionally a no-op: D1 option (a) BLOCK. See triggerCrowTerminalRefusal().
    }

    // MARK: - p17 escape

    static func slideBoltAndLeave(state: GameState) -> Bool {
        guard state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) else { return false }
        state.markSolved(PuzzleGraph.PuzzleID.escape)
        state.markComplete()
        return true
    }

    // Q3 (user decision 2026-07-08): the D5 clock cuckoo is REMOVED. There is no
    // setClockToTwelve / cuckoo latch anymore — the mantel clock is purely the p01
    // numeral-ring reference (its hands still move cosmetically, but nothing pops and
    // no state is written). `clockCuckooSpent` remains defined for save-migration only.
}
