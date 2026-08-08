import CoreGraphics
import Foundation

/// REV 1.4.1 / D13 — THE LIVE CRANK-TALLY READOUT (p06).
///
/// A chalk tally block on the gear-frame cheek, directly beneath the F3 chalk crib and
/// separated from it by the crib's own chalked RULE. It delivers the counting route D5 and
/// blind-playtest 2b have promised since rev 1.0: build 16 ran a whole cam cycle on ONE press
/// with no countable artifact at all, so the sanctioned no-algebra solve route was specified
/// and never shipped.
///
/// THE CONTRACTS THIS TYPE EXISTS TO MAKE TESTABLE (all from developer_notes D13):
///
///  * ACCRUAL IS ACCUMULATED CRANK ROTATION SINCE THE LAST CAM CLACK — one full stroke per
///    full turn, remainder as ONE partial. Counting crossings of an index mark on the crank is
///    PROHIBITED: it drifts in phase and oscillates 7/7/6 across cycles. Because every cam
///    cycle of a given pair consumes exactly R = A*B/96 crank revolutions, the accumulated
///    measure renders the IDENTICAL picture every cycle — the anti-oscillation contract that
///    `Level2TallyTests.testTallyIsCycleStable...` pins.
///  * NON-INTEGER PAIRS (exactly three of the 21) draw N full + ONE partial. The partial is a
///    FIXED CANONICAL GLYPH: constant height, upright, on the shared baseline, never derived
///    from the residue (V17-W1) — which is why nothing in this file ever passes the residue
///    into the layout. It is never grouped into a five and never receives a diagonal.
///  * LEAK CONSTRAINTS — identical in form for correct and incorrect pairs, never varies with
///    closeness to 24, never varies with any clue-viewed flag, ungated exactly as p06 is.
///    NO GLOW / FLASH / COLOUR CHANGE at 24 (RF-7c): there is deliberately no branch on the
///    count anywhere below; success differentiation stays with the latch and the panel.
///  * PERSISTENCE — the block is TRANSIENT VIEW/SESSION state of the same class as an
///    animation frame (see `L2TallyAccrual`): never written to the save, never readable by any
///    gate/condition/requirement/D7 flag, re-derives to EMPTY on load.
///
/// The notation (slot pitch, group gap, row pitch/capacity, baselines, the rule) is READ FROM
/// THE STAGED `tally-sprites.json` — the same metadata the sprites were cut against — rather
/// than hand-transcribed into Swift, which is exactly how build 16's rects drifted from the art.
enum Level2Tally {

    // MARK: - Notation (authored in specs/tools/l2_rev141_crib.py, staged as tally-sprites.json)

    struct Notation: Equatable {
        /// Canonical close-up plate the tally geometry is authored in.
        var plate = CGSize(width: 2048, height: 1536)
        /// Slot pitch between the uprights of a five-group.
        var slotPitch: CGFloat = 14
        /// Extra gap between one five-group and the next.
        var groupGap: CGFloat = 16
        var rowPitch: CGFloat = 56
        /// Strokes per row (4 five-groups).
        var rowCapacity: Int = 20
        /// Draw size of `sp-tally-full` / `sp-tally-partial` (identical — V17-W3: the partial's
        /// SHORTENED TOP is baked into its sprite, never applied as a runtime height).
        var strokeSize = CGSize(width: 4, height: 38)
        /// Draw size of `sp-tally-strike`, the group-closing FIFTH stroke.
        var strikeSize = CGSize(width: 47.6, height: 38)
        /// Left edge of the live block (shares the crib's x0 — the two are one column).
        var x0: CGFloat = 702
        /// Baselines of the (up to three) live rows.
        var rowBaselines: [CGFloat] = [664, 720, 776]
        /// The crib's chalked rule: the POSITION-ONLY separator (RF-7b).
        var ruleY: CGFloat = 604
        /// The authored bounding box of the live block, normalized to the plate.
        var blockRect = CGRect(x: 0.34082, y: 0.403646,
                               width: 0.46582 - 0.34082, height: 0.509115 - 0.403646)

        /// Distance from one five-group's first upright to the next group's first upright.
        var groupAdvance: CGFloat { 3 * slotPitch + strokeSize.width + groupGap }
        /// Strokes the authored rows can hold (60 >= the level's worst case of 48).
        var capacity: Int { rowCapacity * rowBaselines.count }
    }

    /// The notation actually in force, loaded once from the staged metadata.
    static let notation: Notation = loadNotation()

    private static func loadNotation() -> Notation {
        var n = Notation()
        guard let url = Bundle.main.url(forResource: "tally-sprites", withExtension: "json",
                                        subdirectory: "GameAssets/level-2")
                ?? Bundle.main.url(forResource: "tally-sprites", withExtension: "json"),
              let data = try? Data(contentsOf: url),
              let raw = try? JSONSerialization.jsonObject(with: data) as? [String: Any]
        else { return n }

        if let note = raw["notation"] as? [String: Any] {
            n.slotPitch = num(note["slot_pitch_cu_px"]) ?? n.slotPitch
            n.groupGap = num(note["group_gap_cu_px"]) ?? n.groupGap
            n.rowPitch = num(note["row_pitch_cu_px"]) ?? n.rowPitch
            if let cap = num(note["row_capacity_strokes"]) { n.rowCapacity = Int(cap) }
        }
        if let sprites = raw["sprites"] as? [String: Any] {
            if let full = sprites["sp-tally-full"] as? [String: Any],
               let size = sizePair(full["draw_size_cu_px"]) { n.strokeSize = size }
            if let strike = sprites["sp-tally-strike"] as? [String: Any],
               let size = sizePair(strike["draw_size_cu_px"]) { n.strikeSize = size }
        }
        if let cu = raw["cu_gear_frame"] as? [String: Any] {
            if let plate = sizePair(cu["plate_px"]) { n.plate = plate }
            n.x0 = num(cu["live_x0_px"]) ?? n.x0
            n.ruleY = num(cu["rule_y_px"]) ?? n.ruleY
            if let baselines = (cu["live_row_baselines_px"] as? [Any])?
                .compactMap({ num($0) }), !baselines.isEmpty {
                n.rowBaselines = baselines
            }
            if let box = (cu["live_block_rect_norm"] as? [Any])?.compactMap({ num($0) }),
               box.count == 4 {
                n.blockRect = CGRect(x: box[0], y: box[1],
                                     width: box[2] - box[0], height: box[3] - box[1])
            }
        }
        return n
    }

    private static func num(_ any: Any?) -> CGFloat? {
        (any as? NSNumber).map { CGFloat($0.doubleValue) }
    }
    private static func sizePair(_ any: Any?) -> CGSize? {
        guard let a = any as? [Any], a.count == 2,
              let w = num(a[0]), let h = num(a[1]) else { return nil }
        return CGSize(width: w, height: h)
    }

    // MARK: - Accrual arithmetic
    //
    // The gear train is (A/12) x (B/8) (D5 / F1: post A carries the 8-tooth coaxial pinion with
    // VIII on its own face; the crank pinion is XII), so ONE cam cycle consumes exactly
    // R = A*B/96 crank revolutions. That constant is the entire anti-oscillation argument: the
    // picture drawn at the end of a cycle is a pure function of the mounted pair.

    static let camCycleDivisor = 96

    /// What is DRAWN. Deliberately carries NO residue, NO ratio and NO "closeness to 24":
    /// a partial is a boolean, never a height (V17-W1), and nothing downstream can leak.
    struct Block: Equatable {
        var fullStrokes: Int
        var hasPartial: Bool
        var isEmpty: Bool { fullStrokes == 0 && !hasPartial }
        static let empty = Block(fullStrokes: 0, hasPartial: false)
    }

    static func teeth(_ gear: String?) -> Int? { gear.flatMap { Int($0) } }

    /// Crank revolutions consumed by ONE cam cycle of the mounted pair, or nil with fewer than
    /// two gears mounted (D13(ii): no pair, nothing drawn).
    static func revolutionsPerCamCycle(postA: String?, postB: String?) -> Double? {
        guard let a = teeth(postA), let b = teeth(postB) else { return nil }
        return Double(a * b) / Double(camCycleDivisor)
    }

    /// The block a COMPLETED cam cycle leaves on the cheek, in exact integer arithmetic (no
    /// floating point, so it cannot drift): N full strokes, plus ONE partial iff A*B is not a
    /// whole multiple of 96. Commutative in A/B by construction — the 36/64 pair reads 24 with
    /// no partial in EITHER post arrangement.
    static func finalBlock(postA: String?, postB: String?) -> Block? {
        guard let a = teeth(postA), let b = teeth(postB) else { return nil }
        let product = a * b
        return Block(fullStrokes: product / camCycleDivisor,
                     hasPartial: product % camCycleDivisor != 0)
    }

    /// The block for an in-progress accrual: one full stroke per completed turn of accumulated
    /// rotation, the remainder as ONE partial. (Same function the completed cycle lands on.)
    static func block(accumulatedRevolutions revolutions: Double) -> Block {
        guard revolutions > 0 else { return .empty }
        let full = Int((revolutions + 1e-9).rounded(.down))
        return Block(fullStrokes: max(0, full),
                     hasPartial: revolutions - Double(full) > 1e-9)
    }

    // MARK: - Layout (five-grouped, bottom-left/baseline anchored, exactly as authored)

    /// One chalk mark to draw. `x`/`baselineY` are the sprite's BOTTOM-LEFT anchor in
    /// cu-gear-frame pixels — the pivot `tally-sprites.json` authors every sprite against.
    struct Mark: Equatable {
        enum Kind: String, Equatable {
            case full, partial, strike
            /// Staged sprite name.
            var image: String {
                switch self {
                case .full: return "sp-tally-full"
                case .partial: return "sp-tally-partial"
                case .strike: return "sp-tally-strike"
                }
            }
        }
        let kind: Kind
        let x: CGFloat
        let baselineY: CGFloat
        /// Row / group / slot the mark occupies (exposed so the guards can assert the
        /// grouping rules instead of re-deriving them from coordinates).
        let row: Int
        let group: Int
        let slot: Int
    }

    /// A slot address inside the block: which row, which five-group, which upright.
    private struct Slot { var row: Int; var group: Int; var index: Int }

    private static func slot(forStrokeIndex i: Int, _ n: Notation) -> Slot {
        let row = i / n.rowCapacity
        let within = i % n.rowCapacity
        return Slot(row: row, group: within / 5, index: within % 5)
    }

    private static func slotX(_ s: Slot, _ n: Notation) -> CGFloat {
        n.x0 + CGFloat(s.group) * n.groupAdvance + CGFloat(min(s.index, 3)) * n.slotPitch
    }

    /// The drawn marks for a block, in draw order. Pure geometry — no state, no gate, no
    /// residue, and no branch on the count (RF-7c: 24 is drawn exactly like 23 and 25).
    static func marks(for block: Block, notation n: Notation = Level2Tally.notation) -> [Mark] {
        var out: [Mark] = []
        let rows = n.rowBaselines.count
        for i in 0..<max(0, block.fullStrokes) {
            let s = slot(forStrokeIndex: i, n)
            guard s.row < rows else { break }
            // The FIFTH stroke of a group is the closing diagonal, drawn from the group's first
            // upright and spanning exactly the four it closes (never a strike-out).
            let kind: Mark.Kind = s.index == 4 ? .strike : .full
            out.append(Mark(kind: kind,
                            x: n.x0 + CGFloat(s.group) * n.groupAdvance
                                + (kind == .strike ? 0 : CGFloat(s.index) * n.slotPitch),
                            baselineY: n.rowBaselines[s.row],
                            row: s.row, group: s.group, slot: s.index))
        }
        if block.hasPartial, let p = partialSlot(after: block.fullStrokes, n) {
            out.append(Mark(kind: .partial, x: slotX(p, n), baselineY: n.rowBaselines[p.row],
                            row: p.row, group: p.group, slot: p.index))
        }
        return out
    }

    /// Where the ONE partial goes.
    ///
    /// It occupies the next UPRIGHT slot after the last full stroke — the accrual frontier, so
    /// the picture stays continuous as the partial is replaced by a full stroke. JUDGMENT CALL
    /// (flagged in implementation-notes): when the next mark would be a group's CLOSING
    /// DIAGONAL (four uprights already standing), the partial cannot take that slot — V17 says
    /// it is upright, never diagonal, never grouped into a five and never struck — so it steps
    /// to the first upright of the NEXT group, where it can never be closed. None of the three
    /// non-integer pairs in the shipped gear set lands there (6, 10 and 26 full strokes leave
    /// 1, 0 and 1 uprights standing), so this rule only governs the accrual animation.
    private static func partialSlot(after fullStrokes: Int, _ n: Notation) -> Slot? {
        var s = slot(forStrokeIndex: max(0, fullStrokes), n)
        if s.index == 4 {
            s.index = 0
            s.group += 1
            if s.group >= n.rowCapacity / 5 { s.group = 0; s.row += 1 }
        }
        return s.row < n.rowBaselines.count ? s : nil
    }

    /// The bottom-left anchored draw rect of a mark, in plate pixels (the view converts).
    static func drawRect(_ mark: Mark, notation n: Notation = Level2Tally.notation) -> CGRect {
        let size = mark.kind == .strike ? n.strikeSize : n.strokeSize
        return CGRect(x: mark.x, y: mark.baselineY - size.height,
                      width: size.width, height: size.height)
    }
}

/// D13 PERSISTENCE — the transient accrual state, held by the view layer (`Level2Coordinator`)
/// and NEVER by `GameState`. Nothing here is saved, nothing here is readable by a gate, and a
/// fresh coordinator (scene reload / save load / relaunch) starts EMPTY by construction: the
/// only way to make the block non-empty is to press the crank.
///
/// The completed count STAYS DRAWN (a player who looked away still gets the number) until one
/// of D13's four clearing conditions: (i) any mount/unmount at either post, (ii) fewer than two
/// gears mounted, (iii) scene reload or save load, (iv) the start of the next crank press,
/// which redraws from zero.
final class L2TallyAccrual {
    /// The pair the current block belongs to. The frame must NEVER display a count belonging to
    /// a configuration that is no longer mounted, so this is cleared on any mount/unmount.
    private(set) var pairKey: String?
    /// Accumulated crank rotation since the last cam clack, in revolutions.
    private(set) var revolutions: Double = 0
    /// The full cycle's rotation, R = A*B/96.
    private(set) var target: Double = 0

    var isAccruing: Bool { pairKey != nil && revolutions < target - 1e-9 }

    /// What is drawn right now (nil = nothing drawn at all).
    var block: Level2Tally.Block? {
        guard pairKey != nil else { return nil }
        return Level2Tally.block(accumulatedRevolutions: revolutions)
    }

    static func pairKey(postA: String?, postB: String?) -> String? {
        guard let a = postA, let b = postB else { return nil }
        return a + "x" + b
    }

    /// D13(iv): a crank press REDRAWS FROM ZERO. Returns false with fewer than two gears.
    @discardableResult
    func begin(postA: String?, postB: String?) -> Bool {
        guard let key = Self.pairKey(postA: postA, postB: postB),
              let r = Level2Tally.revolutionsPerCamCycle(postA: postA, postB: postB) else {
            clear(); return false
        }
        pairKey = key
        target = r
        revolutions = 0
        return true
    }

    /// Advance the accrual animation by `delta` revolutions (never past the cycle).
    func advance(by delta: Double) {
        guard pairKey != nil, delta > 0 else { return }
        revolutions = min(target, revolutions + delta)
    }

    /// RC-4: the accrual must be skippable — the final block is fully readable statically.
    func finish() {
        guard pairKey != nil else { return }
        revolutions = target
    }

    /// D13 (i)/(ii)/(iii): clears immediately and completely.
    func clear() {
        pairKey = nil
        revolutions = 0
        target = 0
    }
}
