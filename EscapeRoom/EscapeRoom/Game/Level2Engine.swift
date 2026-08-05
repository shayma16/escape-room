import Foundation

/// Applies Level 2 puzzle-graph.json (rev 1.3) node logic to a GameState. Like L1's
/// PuzzleEngine, every function is a pure requirement check + state mutation — never a
/// step-order gate — so any valid interleaving (solve_path_notes) converges correctly.
///
/// The one derived boolean, cond-timelock-release (= clock-wound AND hands-at-release AND
/// pendulum-running), is evaluated live from the three inputs and latches door-bar-raised
/// on first TRUE (D2), regardless of the order the inputs were achieved.
enum Level2Engine {

    // MARK: - p01 numeral-dial door

    enum DialResult: Equatable { case seated, rejected, solved }

    /// Seat a tile (an inventory tile id, or the tray VI decoy) into a socket. Correct tile
    /// for that socket seats (removed from inventory, recorded); the tray VI decoy and any
    /// wrong tile are rejected and pop back (no state change). Completing all four sockets
    /// trips the latch and unlocks z2. Ungated (physical seating, pop-back rejection).
    @discardableResult
    static func seatDialTile(_ tile: String, socket: String, state: GameState) -> DialResult {
        guard !state.hasSolved(Level2Graph.PuzzleID.dialDoor) else { return .solved }
        guard Level2Graph.dialSockets.contains(socket) else { return .rejected }
        // Only a held inventory tile can seat; the tray VI decoy (Level2Graph.DecoyTile.trayVI) is
        // never an inventory item so it can never match dialSolution — always rejected.
        guard Level2Graph.dialSolution[socket] == tile, state.hasItem(tile) else { return .rejected }
        state.setL2DialSocket(socket, tile: tile)
        state.removeItem(tile)
        if isDialComplete(state) {
            state.markSolved(Level2Graph.PuzzleID.dialDoor)
            state.unlockZone(Level2Graph.ZoneID.z2Workroom)
            return .solved
        }
        return .seated
    }

    static func isDialComplete(_ state: GameState) -> Bool {
        Level2Graph.dialSolution.allSatisfy { state.data.l2DialSockets[$0.key] == $0.value }
    }

    // MARK: - p02 cat and the wind-up mouse

    enum CatOffer: Equatable { case mouseTell, refusal }

    /// Wind the mouse and set it on the FLOOR near the cat's bench: the cat pounces, keeps
    /// the mouse (consumed by design), and VACATES the cushion. Ungated.
    ///
    /// ROUND 8 (R8-013, user ruling): this no longer auto-grants watch B. The graph's yield is
    /// "cushion now liftable; watch B beneath" — a revealed item, picked up deliberately, per
    /// the standing manual-pickup principle (L1 F-023 / R2-003). p02 opens the cushion; the
    /// player lifts it (`liftCushion`) and taps the watch (`collectWatchB`).
    @discardableResult
    static func placeMouseAtCat(state: GameState) -> Bool {
        guard state.hasItem(Level2Graph.ItemID.toyMouse) else { return false }
        guard !state.hasSolved(Level2Graph.PuzzleID.catMouse) else { return true }
        state.markSolved(Level2Graph.PuzzleID.catMouse)
        state.removeItem(Level2Graph.ItemID.toyMouse)     // cat keeps it (soft-lock-safe: no other use)
        return true
    }

    // MARK: - p02 yield: the cushion lift -> watch B manual pickup (R8-013)

    /// TRUE once the cat has left and the cushion has NOT yet been lifted (the lift affordance
    /// is live). Derived from latched flags only — order-free and idempotent.
    static func isCushionLiftable(_ state: GameState) -> Bool {
        state.hasSolved(Level2Graph.PuzzleID.catMouse)
            && !state.hasFlag(Level2Graph.Flag.cushionLifted)
            && !watchBTaken(state)
    }

    /// Lift the vacated cushion. Latched (never un-lifts), so re-entering the close-up keeps
    /// showing the reveal until watch B is actually collected.
    @discardableResult
    static func liftCushion(state: GameState) -> Bool {
        guard isCushionLiftable(state) else { return false }
        state.setFlag(Level2Graph.Flag.cushionLifted)
        return true
    }

    /// TRUE while watch B lies revealed under the lifted cushion, uncollected.
    static func isWatchBUncollected(_ state: GameState) -> Bool {
        state.hasSolved(Level2Graph.PuzzleID.catMouse)
            && state.hasFlag(Level2Graph.Flag.cushionLifted)
            && !watchBTaken(state)
    }

    /// The deliberate pickup. Idempotent: a second tap can never duplicate the watch.
    @discardableResult
    static func collectWatchB(_ state: GameState) -> Bool {
        guard isWatchBUncollected(state) else { return false }
        state.addItem(Level2Graph.ItemID.watchB)
        return true
    }

    /// Watch B is "taken" once held or once any of its downstream sinks has fired (so a
    /// consumed/spent carrier never re-appears under the cushion). Mirrors
    /// `Level2Visuals.watchBTaken`, kept here so the engine has no view-layer dependency.
    private static func watchBTaken(_ state: GameState) -> Bool {
        state.hasItem(Level2Graph.ItemID.watchB)
            || state.hasSolved(Level2Graph.PuzzleID.cacheChimney)
            || state.hasSolved(Level2Graph.PuzzleID.gearTrain)
    }

    /// Offering an armed item DIRECTLY to the cat (D3/D4): the mouse earns the tell (eyes
    /// lock, tail flick, stays put), everything else the generic slow-blink refusal. Never
    /// executes p02, never consumes anything — the item returns to inventory.
    static func offerItemToCat(_ itemID: String) -> CatOffer {
        itemID == Level2Graph.ItemID.toyMouse ? .mouseTell : .refusal
    }

    // MARK: - p03 / p04 pointer-watch pry caches (clue-gated, D10 faint-tell)

    enum PryResult: Equatable {
        case dead          // wrong spot: identical dead "doesn't budge" (anti-sweep wall)
        case faintTell     // CORRECT spot, gate unsatisfied: D10 creak + shift, refuses
        case yielded       // CORRECT spot, gate satisfied: opens (manual pickup follows)
        case alreadyOpen   // already pried
    }

    /// p03 dormer board pry. `isCorrectSpot` is decided by the caller's hotspot (the correct
    /// board is the ⌂-ring 3-o'clock board). Requires the screwdriver. Gate: clu-watch-a.
    static func pryDormerBoard(isCorrectSpot: Bool, state: GameState) -> PryResult {
        pryCache(puzzleID: Level2Graph.PuzzleID.cacheDormer, isCorrectSpot: isCorrectSpot,
                 requiresZone: nil, state: state)
    }

    /// p04 chimney brick pry. Correct brick = ⚙-ring 9-o'clock. Requires screwdriver + z2.
    /// Gate: clu-watch-b.
    static func pryChimneyBrick(isCorrectSpot: Bool, state: GameState) -> PryResult {
        pryCache(puzzleID: Level2Graph.PuzzleID.cacheChimney, isCorrectSpot: isCorrectSpot,
                 requiresZone: Level2Graph.ZoneID.z2Workroom, state: state)
    }

    private static func pryCache(puzzleID: String, isCorrectSpot: Bool, requiresZone: String?,
                                 state: GameState) -> PryResult {
        if state.hasSolved(puzzleID) { return .alreadyOpen }
        guard state.hasItem(Level2Graph.ItemID.screwdriver) else { return .dead }
        if let z = requiresZone, !state.isZoneUnlocked(z) { return .dead }
        guard isCorrectSpot else { return .dead }        // every wrong spot: identical dead wall
        // Correct spot: the gate decides yield vs the D10 faint-tell (no persistent change).
        guard Level2ClueGate.isSatisfied(puzzleID, state: state) else { return .faintTell }
        state.markSolved(puzzleID)
        return .yielded
    }

    // MARK: - p05 free the seized arbor (oiling; ungated)

    @discardableResult
    static func oilArbor(state: GameState) -> Bool {
        guard state.hasItem(Level2Graph.ItemID.oilcan),
              state.isZoneUnlocked(Level2Graph.ZoneID.z2Workroom) else { return false }
        guard !state.hasFlag(Level2Graph.Flag.arborFreed) else { return true }
        state.setFlag(Level2Graph.Flag.arborFreed)
        state.markSolved(Level2Graph.PuzzleID.freeArbor)
        return true
    }

    // MARK: - p06 automaton gear train (gear-ratio; ungated mechanical truth)

    /// Mount a gear on a post. The great wheel (value 64) must be held; mounting removes it
    /// from inventory. Rack gears mount freely (never enter inventory). Freely remountable.
    @discardableResult
    static func mountGear(_ gearValue: String, on post: Level2Post, state: GameState) -> Bool {
        guard state.isZoneUnlocked(Level2Graph.ZoneID.z2Workroom) else { return false }
        guard !state.hasSolved(Level2Graph.PuzzleID.gearTrain) else { return false }
        if gearValue == Level2Graph.gearGreatWheelValue {
            // The 64 is the great wheel: it must be in inventory (or already on the OTHER post).
            let onOther = otherPostGear(post, state) == Level2Graph.gearGreatWheelValue
            guard state.hasItem(Level2Graph.ItemID.greatWheel) || onOther else { return false }
            if state.hasItem(Level2Graph.ItemID.greatWheel) {
                state.removeItem(Level2Graph.ItemID.greatWheel)
            }
        } else {
            guard Level2Graph.rackGears.contains(gearValue) else { return false }
        }
        // If this post already held the great wheel, return it to inventory before replacing.
        if currentPostGear(post, state) == Level2Graph.gearGreatWheelValue {
            state.addItem(Level2Graph.ItemID.greatWheel)
        }
        state.setL2GearPost(post, gear: gearValue)
        return true
    }

    /// Unmount a post. The great wheel returns to inventory; rack gears return to the rack.
    static func unmountGear(_ post: Level2Post, state: GameState) {
        guard !state.hasSolved(Level2Graph.PuzzleID.gearTrain) else { return }
        if currentPostGear(post, state) == Level2Graph.gearGreatWheelValue {
            state.addItem(Level2Graph.ItemID.greatWheel)
        }
        state.setL2GearPost(post, gear: nil)
    }

    static func currentPostGear(_ post: Level2Post, _ state: GameState) -> String? {
        post == .a ? state.data.l2GearPostA : state.data.l2GearPostB
    }
    static func otherPostGear(_ post: Level2Post, _ state: GameState) -> String? {
        post == .a ? state.data.l2GearPostB : state.data.l2GearPostA
    }

    /// TRUE iff the two posts currently hold the unique 24:1 pair {36, 64} (either order).
    static func isGearTrainCorrect(_ state: GameState) -> Bool {
        guard let a = state.data.l2GearPostA, let b = state.data.l2GearPostB else { return false }
        return Set([a, b]) == Level2Graph.gearSolutionSet
    }

    /// Crank the frame through one cam revolution. At exactly 24:1 the mural completes a
    /// clean cycle, the counterweight drops, the wall panel swings open and z3 unlocks.
    /// Requires the arbor freed. Wrong ratio: cam runs wrong speed, latch slips (false).
    /// Ungated (a mechanically true train MUST work — gating physical truth reads as broken).
    @discardableResult
    static func crankGearTrain(state: GameState) -> Bool {
        guard state.isZoneUnlocked(Level2Graph.ZoneID.z2Workroom),
              state.hasFlag(Level2Graph.Flag.arborFreed) else { return false }
        guard !state.hasSolved(Level2Graph.PuzzleID.gearTrain) else { return true }
        guard isGearTrainCorrect(state) else { return false }
        state.markSolved(Level2Graph.PuzzleID.gearTrain)   // great wheel consumed by lifecycle
        state.unlockZone(Level2Graph.ZoneID.z3BehindDial)
        return true
    }

    // MARK: - p07 four-wheel vault hatch (numeric code; clue-gated)

    static func setVaultWheel(_ index: Int, value: Int, state: GameState) {
        let v = ((value - 1) % 12 + 12) % 12 + 1   // wrap into 1...12
        state.setL2VaultWheel(index, value: v)
        _ = evaluateVault(state: state)
    }

    /// While gated the hatch stays shut on ANY setting incl. the correct one (no tell).
    @discardableResult
    static func evaluateVault(state: GameState) -> Bool {
        guard state.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial) else { return false }
        guard !state.hasSolved(Level2Graph.PuzzleID.vaultWheels) else { return true }
        let solved = state.data.l2VaultWheels == Level2Graph.vaultSolution
            && Level2ClueGate.isSatisfied(Level2Graph.PuzzleID.vaultWheels, state: state)
        if solved {
            state.markSolved(Level2Graph.PuzzleID.vaultWheels)
            state.unlockZone(Level2Graph.ZoneID.z4Vault)
        }
        return solved
    }

    /// D6 stale-correct-wheels: re-evaluate the gate+solution on hatch close-up (re-)entry.
    static func reevaluateVaultOnCloseUpEntry(state: GameState) { _ = evaluateVault(state: state) }

    // MARK: - p08 oil + wind the movement (mechanism completion; ungated)

    @discardableResult
    static func oilDrum(state: GameState) -> Bool {
        guard state.hasItem(Level2Graph.ItemID.oilcan),
              state.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial) else { return false }
        guard !state.hasFlag(Level2Graph.Flag.drumOiled) else { return true }
        state.setFlag(Level2Graph.Flag.drumOiled)
        return true
    }

    /// Wind with the key. Key-before-oil: seats but won't turn (false; oil need restated).
    @discardableResult
    static func windDrum(state: GameState) -> Bool {
        guard state.hasItem(Level2Graph.ItemID.windingKey),
              state.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial) else { return false }
        guard !state.hasFlag(Level2Graph.Flag.clockWound) else { return true }
        guard state.hasFlag(Level2Graph.Flag.drumOiled) else { return false }  // oil first
        state.setFlag(Level2Graph.Flag.clockWound)          // winding key consumed by lifecycle
        state.markSolved(Level2Graph.PuzzleID.oilWind)
        _ = evaluateTimelock(state: state)
        return true
    }

    // MARK: - p09 set the hands from behind (mirrored dial; clue-gated)

    /// Adjust the front time by a signed number of 5-minute detents (the setting crank).
    static func adjustClock(byDetents detents: Int, state: GameState) {
        let next = state.data.l2ClockFrontMinutes + detents * 5
        state.setL2ClockFrontMinutes(next)
        _ = evaluateTimelock(state: state)
    }

    /// hands-at-release is continuously evaluated: FRONT time == 7:20 AND the gate (return
    /// tag viewed) — while gated it never asserts, indistinguishable from a wrong time.
    static func isHandsAtRelease(_ state: GameState) -> Bool {
        state.data.l2ClockFrontMinutes == Level2Graph.clockReleaseMinutes
            && Level2ClueGate.isSatisfied(Level2Graph.PuzzleID.setHands, state: state)
    }

    // MARK: - p10 start the pendulum (free physical act; ungated)

    @discardableResult
    static func pushPendulum(state: GameState) -> Bool {
        guard state.isZoneUnlocked(Level2Graph.ZoneID.z3BehindDial) else { return false }
        guard !state.hasFlag(Level2Graph.Flag.pendulumRunning) else { return true }
        state.setFlag(Level2Graph.Flag.pendulumRunning)
        state.markSolved(Level2Graph.PuzzleID.startPendulum)
        _ = evaluateTimelock(state: state)
        return true
    }

    // MARK: - cond-timelock-release (order-free derived condition; latches the door bar)

    /// Re-evaluated on every change to its three inputs + on z3 close-up entry (D2/D6). On
    /// first TRUE it latches door-bar-raised PERMANENTLY (later hand-fiddling can't re-lock).
    @discardableResult
    static func evaluateTimelock(state: GameState) -> Bool {
        if state.hasFlag(Level2Graph.Flag.doorBarRaised) { return true }
        let wound = state.hasFlag(Level2Graph.Flag.clockWound)
        let pendulum = state.hasFlag(Level2Graph.Flag.pendulumRunning)
        guard wound && pendulum && isHandsAtRelease(state) else { return false }
        state.markSolved(Level2Graph.PuzzleID.setHands)     // definitely at release now
        state.setFlag(Level2Graph.Flag.doorBarRaised)       // latched permanently
        return true
    }

    /// D11 alive-wrong-time ambient (presentation only): wound AND swinging AND NOT at
    /// release. Derived, never stored; introduces no new state and never affects the latch.
    static func isAliveWrongTime(_ state: GameState) -> Bool {
        !state.hasFlag(Level2Graph.Flag.doorBarRaised)
            && state.hasFlag(Level2Graph.Flag.clockWound)
            && state.hasFlag(Level2Graph.Flag.pendulumRunning)
            && !isHandsAtRelease(state)
    }

    // MARK: - p11 open the stair door and leave (endgame)

    @discardableResult
    static func openStairDoor(state: GameState) -> Bool {
        guard state.hasFlag(Level2Graph.Flag.doorBarRaised) else { return false }
        guard !state.isComplete else { return true }
        state.markSolved(Level2Graph.PuzzleID.exit)
        state.markComplete()
        return true
    }

    // MARK: - Manual pickups (revealed-then-collected, derived not stored — L1 pattern)

    /// Great wheel sits in the pried dormer cache until collected. Sink: mounted on a post
    /// OR p06 consumed it. Derived so a taken/spent wheel never re-appears in the cavity.
    static func isGreatWheelUncollected(_ state: GameState) -> Bool {
        state.hasSolved(Level2Graph.PuzzleID.cacheDormer)
            && !state.hasItem(Level2Graph.ItemID.greatWheel)
            && state.data.l2GearPostA != Level2Graph.gearGreatWheelValue
            && state.data.l2GearPostB != Level2Graph.gearGreatWheelValue
            && !state.hasSolved(Level2Graph.PuzzleID.gearTrain)
    }

    @discardableResult
    static func collectGreatWheel(_ state: GameState) -> Bool {
        guard isGreatWheelUncollected(state) else { return false }
        state.addItem(Level2Graph.ItemID.greatWheel)
        return true
    }

    /// Oil can sits in the pried chimney cache until collected. Sink: both its uses (p05+p08).
    static func isOilcanUncollected(_ state: GameState) -> Bool {
        state.hasSolved(Level2Graph.PuzzleID.cacheChimney)
            && !state.hasItem(Level2Graph.ItemID.oilcan)
            && !(state.hasSolved(Level2Graph.PuzzleID.freeArbor)
                 && state.hasSolved(Level2Graph.PuzzleID.oilWind))
    }

    @discardableResult
    static func collectOilcan(_ state: GameState) -> Bool {
        guard isOilcanUncollected(state) else { return false }
        state.addItem(Level2Graph.ItemID.oilcan)
        return true
    }
}
