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

        if progress == RuneDoorSolution.solutionOrder {
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

    /// Dials retain position between attempts (no lockout); checked whenever the
    /// player commits (e.g. taps a "try" affordance or on every dial settle — Scene
    /// layer decides the trigger, this just evaluates current dial state).
    static func evaluateMoonDials(state: GameState) -> Bool {
        let positions = state.data.moonDialPositions
        guard positions.count == 3 else { return false }
        let phases = positions.map { MoonDialSolution.clockwiseOrder[$0 % MoonDialSolution.clockwiseOrder.count] }
        let solved = phases == MoonDialSolution.solution
        if solved {
            state.markSolved(PuzzleGraph.PuzzleID.moonTrapdoor)
            state.unlockZone(PuzzleGraph.ZoneID.z3Cellar)
        }
        return solved
    }

    // MARK: - p03 astrolabe

    static func selectAstrolabePlate(_ plateIndex: Int, state: GameState) -> Bool {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return false }
        guard plateIndex == AstrolabeSolution.solutionPlateIndex else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.astrolabeOrion)
        state.addItem(PuzzleGraph.ItemID.silverCoin)
        state.addItem(PuzzleGraph.ItemID.crank)
        return true
    }

    // MARK: - p04 sun/moon cabinet

    /// Wrong/swapped placement pops back to inventory (no loss, no lockout) — modeled
    /// by simply not being called for items that don't match; UI is responsible for
    /// bouncing rejected items back to the inventory bar.
    static func placeCabinetItems(sun: String?, moon: String?, state: GameState) -> Bool {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return false }
        guard sun == CabinetSolution.sunSlotItem, moon == CabinetSolution.moonSlotItem,
              state.hasItem(CabinetSolution.sunSlotItem), state.hasItem(CabinetSolution.moonSlotItem) else {
            return false
        }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) else { return true }
        state.removeItem(CabinetSolution.sunSlotItem)
        state.removeItem(CabinetSolution.moonSlotItem)
        state.markSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
        state.addItem(PuzzleGraph.ItemID.file)
        state.addItem(PuzzleGraph.ItemID.phial)
        return true
    }

    // MARK: - p05 ash sift (tool-on-hotspot)

    static func siftAsh(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.poker) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.ashSift) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.ashSift)
        state.addItem(PuzzleGraph.ItemID.goldRing)
        return true
    }

    // MARK: - p06 barrel pry (tool-on-hotspot)

    static func pryBarrel(state: GameState) -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.poker), state.isZoneUnlocked(PuzzleGraph.ZoneID.z3Cellar) else { return false }
        guard !state.hasSolved(PuzzleGraph.PuzzleID.barrelPry) else { return true }
        state.markSolved(PuzzleGraph.PuzzleID.barrelPry)
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
        // Spoon is not consumed (per notes: "not consumed until a successful brew completes").
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

        let success = flameStage == BrewSolution.flameStage
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

    // MARK: - D5 clock cuckoo (cosmetic one-shot latch; never gates progression)

    enum ClockPopResult: Equatable { case popped, spentAlready }

    @discardableResult
    static func setClockToTwelve(state: GameState) -> ClockPopResult {
        if state.hasFlag(PuzzleGraph.StateFlag.clockCuckooSpent) {
            return .spentAlready
        }
        state.setFlag(PuzzleGraph.StateFlag.clockCuckooSpent)
        return .popped
    }
}
