import SpriteKit
import Combine

/// Wires a `RoomScene` for a given `ViewID` to `GameState` + `PuzzleEngine`: builds the
/// hotspot list, resolves the current texture set from state, and handles taps by
/// dispatching to the appropriate PuzzleEngine call.
///
/// Feedback round 1 (2026-07-07) — interaction model is now SELECT-THEN-TAP ONLY:
/// - A bare tap is always a LOOK or a direct free action (pickup, rug, mirror, dials).
///   Merely holding an item in inventory never auto-applies it to anything.
/// - To use an item, the player arms it in the inventory bar, then taps the target
///   hotspot (or the plate of a close-up opened from that hotspot). `useItem(_:on:)`
///   is the single entry point; a SUCCESSFUL use disarms, a failed one keeps the item
///   armed (R2-030) and falls through to the normal look (cluster F, R4-005).
/// - Drag-to-use is REMOVED entirely.
/// Also in this pass: per-object sounds (generic click removed everywhere), dead
/// hotspots are silent (F-006/F-014), manual container pickup (F-023/F-018), neutral
/// cage close-up as the default pose (F-011), diegetic zone passages incl. the cellar
/// ladder and alcove shelf gap (F-024), and universal clue-view recording (F-012
/// substrate for the rev-1.3 gate).
final class RoomSceneCoordinator: ObservableObject {
    let viewID: ViewID
    let scene: RoomScene
    let state: GameState
    /// Shared select-then-tap state (armed item). Optional so engine-level tests can
    /// construct a coordinator without chrome; when nil, bare taps are always looks.
    let interaction: InteractionModel?
    /// The presenting SKView, supplied by SpriteKitContainerView.
    weak var skView: SKView?
    private var cancellable: AnyCancellable?

    // MARK: Transient (non-persisted) per-scene UI state.

    @Published var lastBrewOutcome: PuzzleEngine.BrewOutcome?
    @Published var showTerminalRefusal: Bool = false
    /// The close-up currently presented over this scene. Set by tap handling below;
    /// cleared by the close-up's down-chevron (CloseUpView).
    @Published var activeCloseUp: CloseUpRequest?
    /// The hotspot the active close-up was opened from. An armed item used while the
    /// close-up is open routes to this hotspot's use handler, so every puzzle remains
    /// solvable without leaving the zoomed view (F-020: the close-up no longer walls
    /// the player off from item use).
    private(set) var closeUpOrigin: String?
    /// Cosmetic clock-hand position for the clock close-up (D5). Not persisted — only
    /// the one-shot cuckoo latch is, via the engine.
    @Published var clockHour: Int = 6
    /// Pending (visually seated, not yet consumed) cabinet placements. Coordinator-
    /// local by design: leaving the view pops any lone seated item back conceptually
    /// (it was never removed from inventory), so no soft-lock is possible (QA-BUG-017).
    @Published private(set) var pendingSunItem: String?
    @Published private(set) var pendingMoonItem: String?
    /// True briefly after hanging the weight so the ov-weight-hung overlay renders
    /// before the shelf slides (QA-BUG-016; build 10: overlay, not a base swap).
    private var showingWeightHungBeat: Bool = false

    /// Diegetic zone passages (trapdoor -> cellar, rune door -> workshop, cellar
    /// ladder -> hearth, shelf gap <-> alcove); wired to LevelSession.goTo.
    var onNavigate: ((ViewID) -> Void)?

    init(viewID: ViewID, state: GameState, size: CGSize, interaction: InteractionModel? = nil) {
        self.viewID = viewID
        self.state = state
        self.interaction = interaction
        self.scene = RoomScene(sceneName: viewID.rawValue, size: size)
        configure()
        scene.onHotspotTap = { [weak self] id in self?.handleTap(id) }
        // Cluster F (R4-005, build 10): tapping empty scene space disarms the armed
        // item — the "tap away to deselect" affordance. Silent (visual pulse only).
        scene.onEmptyTap = { [weak self] in self?.interaction?.disarm() }
        cancellable = state.objectWillChange.sink { [weak self] _ in
            DispatchQueue.main.async { self?.refresh() }
        }
    }

    // MARK: - Setup

    private func configure() {
        switch viewID {
        case .hearth: configureHearth()
        case .study: configureStudy()
        case .entry: configureEntry()
        case .bench: configureBench()
        case .cabinet: configureCabinet()
        case .cellar: configureCellar()
        case .alcove: configureAlcove()
        }
        refresh()
    }

    func refresh() {
        switch viewID {
        case .hearth: refreshHearth()
        case .study: refreshStudy()
        case .entry: refreshEntry()
        case .bench: refreshBench()
        case .cabinet: refreshCabinet()
        case .cellar: refreshCellar()
        case .alcove: refreshAlcove()
        }
    }

    // MARK: - Close-up presentation + clue recording

    /// Presents a close-up, remembering its originating hotspot for armed-item routing
    /// and recording the view as a seen clue (F-012 substrate — recorded universally
    /// by close-up id; the rev-1.3 clue_gate table keys into these ids).
    private func present(_ request: CloseUpRequest, from origin: String?) {
        // IC-1 (D6 rule b): a stale-but-now-ungated puzzle resolves on close-up (re-)entry,
        // with no pointless input wiggle. Must run BEFORE we commit to presenting the raw
        // puzzle close-up, so an already-solved p02/p03 shows its opened state instead.
        switch request {
        case .dialPanel:
            PuzzleEngine.reevaluateMoonDialsOnCloseUpEntry(state: state)
            if state.hasSolved(PuzzleGraph.PuzzleID.moonTrapdoor) {
                // Trapdoor sprang open: the diegetic passage is now the affordance.
                activeCloseUp = nil
                closeUpOrigin = nil
                onNavigate?(.cellar)
                return
            }
        case .astrolabe:
            // No stale-input surface exists for p03 in this implementation: the astrolabe
            // is a discrete plate-tap mini-game with NO persisted pointer position (unlike
            // the rev-1.3 spec's rotatable-pointer model). A player who tapped plate-2 while
            // gated simply re-taps it once the window is viewed — `selectAstrolabePlate`
            // re-evaluates the now-open gate on that tap. IC-1's "no wiggle" guarantee is
            // therefore vacuously met here; nothing to re-evaluate on entry. (Flagged in
            // implementation notes.)
            break
        default:
            break
        }
        activeCloseUp = request
        closeUpOrigin = origin
        recordClueViewed(request.id)
    }

    func dismissCloseUp() {
        activeCloseUp = nil
        closeUpOrigin = nil
    }

    /// R2-023b: the single-view-zone exit affordance navigates out via the diegetic
    /// passage. Only fires if the target zone is actually reachable (the cellar's ladder
    /// requires the trapdoor open; the alcove's shelf gap is always open once you're in
    /// the alcove). Guards keep it from stranding the player.
    func exitSingleViewZone(to target: ViewID) {
        onNavigate?(target)
    }

    /// Also called by PagerCloseUp per page so multi-spread clues (grimoire recipe
    /// page, individual triptych paintings) record at page granularity.
    ///
    /// Records BOTH the raw plate/spread id (the F-012 substrate, keyed for tests) AND —
    /// via `gatingClues(for:)` — any rev-1.3 `clu-*` gate id that this view satisfies, so
    /// the clue-gating table (which keys on clu-node ids) is driven purely from views the
    /// player actually opened.
    func recordClueViewed(_ viewID: String) {
        state.markClueViewed(viewID)
        for clueID in Self.gatingClues(for: viewID) {
            state.markClueViewed(clueID)
        }
    }

    /// Maps a viewed close-up/spread id to the rev-1.3 gating clue ids it reveals. The
    /// four rune marks are legible only in their close-ups (per art spec / viewed_when);
    /// grimoire page A carries clu-grimoire-elements; page B and the cabinet slot close-up
    /// each satisfy clu-slot-shapes (shared flag); the recipe spread carries the recipe
    /// clue; the workshop window carries Orion; any triptych spread (or the whole triptych)
    /// carries clu-triptych.
    static func gatingClues(for viewID: String) -> [String] {
        switch viewID {
        case "plain-cu-bellows":            return [ClueID.markAir]
        case "plain-cu-lintel":             return [ClueID.markFire]
        case "plain-cu-flowerpot":          return [ClueID.markEarth]
        case "plain-cu-windowsill":         return [ClueID.markWater]
        case "plain-cu-grimoire-pageA":     return [ClueID.grimoireElements]
        case "plain-cu-grimoire-pageB":     return [ClueID.slotShapes]
        case "plain-cu-grimoire-recipe":    return [ClueID.recipePage]
        case "plain-cu-slots-empty":        return [ClueID.slotShapes]
        case "cabinet-slots":               return [ClueID.slotShapes] // build 10: state-aware slots view (R4-020(1))
        case "plain-cu-window-orion":       return [ClueID.windowOrion]
        case "triptych",
             "plain-cu-triptych-1", "plain-cu-triptych-2", "plain-cu-triptych-3":
            return [ClueID.triptych]
        default:                            return []
        }
    }

    // MARK: - v-hearth (z1)

    private func configureHearth() {
        scene.setBaseTexture("z1-hearth-base")
        // R3-005 re-calibration (build 9): rects re-derived by visual inspection of the
        // NEW build-3 z1-hearth-base plate (2:1, plate-normalized). The old rects were
        // calibrated to the build-2 element positions; on the new plate the clock/ash/
        // poker/bellows/FIRE-mark all sit further right/lower, so a human tapping the
        // visible element used to miss (and tapping LEFT of the clock hit the stale clock
        // rect — R3-005). Measurements: clock body x0.35-0.46 y0-0.19; FIRE glyph+II on
        // the lintel x0.53-0.64 y0.24-0.31; AIR bellows tool x0.585-0.63 y0.42-0.62;
        // poker rod x0.245 y0.42-0.57; ash mound x0.36-0.48 y0.60-0.75.
        scene.configureHotspots(Reframe.map([
            Hotspot(id: "poker", 0.215, 0.40, 0.065, 0.20),
            Hotspot(id: "ash", 0.36, 0.60, 0.16, 0.16),
            Hotspot(id: "clock", 0.35, 0.0, 0.11, 0.19),
            Hotspot(id: "bellows", 0.575, 0.42, 0.075, 0.22),  // AIR glyph on the hanging bellows
            Hotspot(id: "lintel", 0.53, 0.22, 0.11, 0.11),     // FIRE glyph + numeral II
            // The patterned rug carpets the whole lower floor; its upper edge (~y0.80 on
            // the plate) is tappable above the inventory pill, so the rect starts at 0.74
            // to keep a reachable band clear of the §7-R1 bottom bar (as the old rug did).
            Hotspot(id: "rug", 0.14, 0.74, 0.60, 0.26),
            Hotspot(id: "trapdoor-dial", 0.30, 0.66, 0.40, 0.24) // under the rug once moved
        ], view: .hearth))
    }

    private func refreshHearth() {
        // R6-001: the poker-taken crop reaches DOWN into the hearth-floor/rug band (its rect
        // extends to ~y0.84, overlapping the folded-rug overlay). With equal z the two
        // overlays composited in undefined order (ignoresSiblingOrder), so the poker crop
        // sometimes drew OVER the moved rug — the reported "floats over the rug" box. Fix by
        // explicit, state-independent stacking: poker BELOW the rug (z9 < z10), rug below the
        // trapdoor (z10 < z11). The rug/trapdoor overlays carry the correct floor truth in
        // that band, so drawing them on top covers the poker crop's stray lower pixels.
        scene.setOverlay("poker", imageNamed: RoomVisuals.pokerTaken(state) ? "ov-poker-taken" : nil,
                          rectNormalized: overlayRect("z1/v-hearth", "ov-poker-taken"),
                          zPosition: 9)
        scene.setOverlay("rug", imageNamed: RoomVisuals.rugMoved(state) ? "ov-rug-moved" : nil,
                          rectNormalized: overlayRect("z1/v-hearth", "ov-rug-moved"),
                          zPosition: 10)
        // Explicit z: the open-trapdoor crop overlaps the folded-rug crop and must stack
        // above it (build 10 — never rely on node-creation order for overlapping overlays).
        scene.setOverlay("trapdoor", imageNamed: RoomVisuals.trapdoorOpen(state) ? "ov-trapdoor-open" : nil,
                          rectNormalized: overlayRect("z1/v-hearth", "ov-trapdoor-open"),
                          zPosition: 11)
    }

    // MARK: - v-study (z1)

    private func configureStudy() {
        scene.setBaseTexture("z1-study-base")
        // R2-007: the triptych is THREE separate panels, each mapping to its OWN close-up
        // (tapping the right/3-crow painting must open the 3-crow close-up, not the left).
        // The old single "triptych" hotspot always opened the pager at panel 1, which is
        // what produced the reported right->left mismap. Panels laid left-to-right across
        // the old triptych rect (x 0.29..0.66).
        // R3-005 re-calibration (build 9): re-derived from the NEW build-3 z1-study-base.
        // The three triptych panels sit left-of-center (x0.20-0.51, receding), NOT at the
        // old x0.29-0.66; the grimoire is on the desk lower-center (x0.30-0.62 y0.55-0.78);
        // the dead FLOWERPOT with the EARTH glyph+III is bottom-LEFT on the low shelf
        // (x0.02-0.16 y0.68-0.92) — the old rect pointed at the lamp; and the rune-door
        // press-plate is right (x0.735-0.79 y0.375-0.665). Panels map left->right to
        // close-ups 0/1/2 (R2-007: tapping a panel opens THAT panel's close-up).
        scene.configureHotspots(Reframe.map([
            Hotspot(id: "grimoire", 0.31, 0.55, 0.30, 0.22),
            Hotspot(id: "triptych-1", 0.20, 0.18, 0.115, 0.22),
            Hotspot(id: "triptych-2", 0.33, 0.20, 0.095, 0.20),
            Hotspot(id: "triptych-3", 0.435, 0.23, 0.075, 0.18),
            Hotspot(id: "flowerpot", 0.02, 0.68, 0.16, 0.26),  // EARTH glyph + numeral III
            Hotspot(id: "rune-door", 0.72, 0.36, 0.085, 0.32),
        ], view: .study))
    }

    private func refreshStudy() {
        // Tile pressed-state sprites render inside the rune-door close-up (derived from
        // the persisted in-progress sequence); the wide plate has no overlay states.
    }

    // MARK: - v-entry (z1)

    private func configureEntry() {
        scene.setBaseTexture("z1-entry-base")
        // R3-005 re-calibration (build 9): re-derived from the NEW build-3 z1-entry-base.
        // The crow's-beak basin + bolt (door-lock) is center x0.46-0.68 y0.10-0.50; the
        // WATER-glyph tablet (+numeral IV) sits on the windowsill bottom-LEFT (x0.075-0.135
        // y0.54-0.69) — the old rect was to its right on the bare sill (R3-004 WATER mark
        // couldn't be inspected); the rusted key hangs by the bolt (x0.70-0.73 y0.42-0.63);
        // the birdcage is top-RIGHT (x0.79-0.98), with the padlock keyhole at x0.795-0.83
        // y0.34-0.42 and the brass feed cup at x0.875-0.93 y0.44-0.52.
        scene.configureHotspots(Reframe.map([
            Hotspot(id: "door-lock", 0.46, 0.10, 0.24, 0.42),
            Hotspot(id: "rusted-key", 0.685, 0.42, 0.06, 0.22),
            Hotspot(id: "windowsill", 0.06, 0.53, 0.09, 0.18),  // WATER glyph + numeral IV
            Hotspot(id: "cage", 0.80, 0.10, 0.16, 0.45),
            Hotspot(id: "feed-cup", 0.86, 0.42, 0.08, 0.11),
            Hotspot(id: "star-keyhole", 0.78, 0.33, 0.06, 0.11),
        ], view: .entry))
    }

    private func refreshEntry() {
        scene.setOverlay("vines", imageNamed: RoomVisuals.vinesState(state) == "vines-gone" ? "ov-vines-gone" : nil,
                          rectNormalized: overlayRect("z1/v-entry", "ov-vines-gone"))
        scene.setOverlay("cage", imageNamed: RoomVisuals.cageState(state) == "cage-open-empty" ? "ov-cage-open" : nil,
                          rectNormalized: overlayRect("z1/v-entry", "ov-cage-open"))
        scene.setOverlay("crow-lintel", imageNamed: RoomVisuals.crowLocation(state) == "on-lintel" ? "ov-crow-lintel" : nil,
                          rectNormalized: overlayRect("z1/v-entry", "ov-crow-lintel"))
    }

    // MARK: - v-bench (z2)

    private func configureBench() {
        scene.setBaseTexture("z2-bench-base")
        // R3-005 re-calibration (build 9): re-derived from the NEW build-3 z2-bench-base.
        // Cauldron over the fire x0.22-0.40 y0.42-0.68; ladle out of it x0.36-0.44 y0.40-0.48;
        // floor bellows bottom-left x0.06-0.30 y0.78-0.95; mortar & pestle on the RIGHT table
        // x0.80-0.87 y0.42-0.68 (old rect pointed at the doorway); the workbench surface is
        // the right table foreground x0.80-1.0 y0.68-0.80 (p12 combine secondary path).
        scene.configureHotspots(Reframe.map([
            Hotspot(id: "cauldron", 0.22, 0.40, 0.19, 0.28),
            Hotspot(id: "ladle", 0.35, 0.38, 0.10, 0.10),
            Hotspot(id: "floor-bellows", 0.05, 0.77, 0.28, 0.22),
            Hotspot(id: "mortar", 0.79, 0.42, 0.10, 0.26),
            Hotspot(id: "workbench", 0.80, 0.68, 0.20, 0.12),
        ], view: .bench))
    }

    private func refreshBench() {
        // R6-007 registration sub-fix: derive the flame overlay's IMAGE and its placement
        // RECT from the SAME resolved name. The old code fetched the image via
        // flameOverlayName() (min(stage,3)) but the rect via ov-flame\(max(stage,1)) — two
        // independent stage clamps that could select DIFFERENT overlays (right flame plate,
        // wrong rect => the "floating box" class of misregistration). One source of the name
        // makes the flame plate always land at its own stage's rect. (The flame plate ART is
        // re-rolled by Asset-Gen; the JOIN pass stages it + retires the vintage guard.)
        let flameName = flameOverlayName()
        scene.setOverlay("flame", imageNamed: flameName,
                          rectNormalized: flameName.map { overlayRect("z2/v-bench", $0) } ?? .zero)
    }

    private func flameOverlayName() -> String? {
        let stage = state.data.cauldronFlameStage
        guard stage > 0 else { return nil }
        return "ov-flame\(min(max(stage, 1), 3))"
    }

    // MARK: - v-cabinet (z2)

    private func configureCabinet() {
        // R3-005 re-calibration (build 9): re-derived from the NEW build-3 z2-cabinet-base.
        // The sun/moon slots are the carved medallions on the CABINET DOORS center-frame
        // (sun x0.435-0.49 y0.42-0.53 on the left door; crescent moon x0.555-0.60 y0.42-0.53
        // on the right door) — the old rects were far left. The potion shelf is bottom-LEFT
        // (bottles x0.02-0.36 y0.20-0.52); the astrolabe (armillary sphere) is right
        // x0.72-0.86 y0.36-0.68; the arched Orion window is top-RIGHT x0.86-1.0 y0.02-0.60.
        scene.configureHotspots(Reframe.map([
            Hotspot(id: "sun-slot", 0.42, 0.40, 0.09, 0.15),
            Hotspot(id: "moon-slot", 0.535, 0.40, 0.09, 0.15),
            Hotspot(id: "potion-shelf", 0.02, 0.20, 0.36, 0.34),
            Hotspot(id: "astrolabe", 0.71, 0.34, 0.16, 0.36),
            Hotspot(id: "window", 0.86, 0.02, 0.14, 0.58),
        ], view: .cabinet))
        scene.setBaseTexture("z2-cabinet-base")
    }

    private func refreshCabinet() {
        // The open-cabinet overlay already shows the seated medallions, so only render
        // the separate slots-seated overlay while the cabinet is solved but NOT yet drawn
        // open (transient) — in practice solving opens it immediately, so this collapses
        // to "open overlay only" and avoids a redundant double-composite (gap G3 overlays
        // are localized crops that would otherwise fight for z-order).
        let cabOverlay = RoomVisuals.cabinetOpenOverlay(state)
        let showSlotsOnly = RoomVisuals.cabinetDoorState(state) && cabOverlay == nil
        scene.setOverlay("slots", imageNamed: showSlotsOnly ? "ov-slots-seated" : nil,
                          rectNormalized: overlayRect("z2/v-cabinet", "ov-slots-seated"))
        // F-023: the open cabinet keeps its contents visible in the wide shot until
        // both are collected, then swaps to the empty-shelf overlay.
        scene.setOverlay("cabinet-door", imageNamed: cabOverlay,
                          rectNormalized: cabOverlay.map { overlayRect("z2/v-cabinet", $0) } ?? .zero)
        // R6-008-wide (Round 6 Cluster A): the astrolabe drawer overlay bakes the coin +
        // crank, so it must apply the WIDE taken-state — show contents only while something
        // is uncollected, then the emptied/hidden state (resolver picks ov-adrawer-empty when
        // staged, else hides the small drawer). Rect follows the resolved overlay name.
        let adrawerOverlay = RoomVisuals.astrolabeDrawerOverlay(state)
        scene.setOverlay("adrawer", imageNamed: adrawerOverlay,
                          rectNormalized: adrawerOverlay.map { overlayRect("z2/v-cabinet", $0) } ?? .zero)
        // QA-BUG-017: a single correctly-seated item is rendered (icon art over its
        // recess) until the pair completes; no dedicated single-seat plate exists.
        let solved = state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
        // R3-005 seated-item art over its recess, remapped by the build-10 cabinet
        // re-frame transform (these two rects were authored in the OLD framing).
        let cabT = Reframe.transform(for: .cabinet)
        scene.setOverlay("seat-sun", imageNamed: (!solved && pendingSunItem != nil) ? "icon-gold-ring" : nil,
                          rectNormalized: cabT.map(CGRect(x: 0.437, y: 0.43, width: 0.05, height: 0.09)))
        scene.setOverlay("seat-moon", imageNamed: (!solved && pendingMoonItem != nil) ? "icon-silver-coin" : nil,
                          rectNormalized: cabT.map(CGRect(x: 0.552, y: 0.43, width: 0.05, height: 0.09)))
    }

    // MARK: - v-cellar (z3)

    private func configureCellar() {
        scene.setBaseTexture("z3-cellar-base")
        // R3-005 re-calibration (build 9): re-derived from the NEW build-3 z3-cellar-base.
        // Barrel right x0.66-0.80 y0.50-0.82; the handled spoon DRAWER (small chest on the
        // shelf) x0.515-0.60 y0.36-0.44 (old rect was lower/left); the iron weight HOOK ring
        // on the wall x0.20-0.25 y0.28-0.40; the WINCH crank drum at the trapdoor mouth
        // top-left x0.13-0.26 y0.03-0.17 (old rect pointed at the hook); the standing mirror
        // bottom-LEFT x0.06-0.20 y0.36-0.90 (old rect was center-right); the ladder up to the
        // trapdoor is far-RIGHT x0.85-0.96.
        scene.configureHotspots(Reframe.map([
            Hotspot(id: "barrel", 0.66, 0.50, 0.15, 0.32),
            Hotspot(id: "drawer", 0.50, 0.34, 0.11, 0.12),
            // R6-006: the weight HOOK is the ROPED pulley hook hanging beside the sliding
            // plank shelf (reframed ~x0.44-0.52, y0.40-0.68 — the visible rope + hook where
            // the weight hangs), NOT the wrench-shaped wall hook far left (the old rect at
            // reframed ~x0.27). Re-derived in OLD framing so Reframe.map places it on the
            // roped hook. (p07 logic unchanged; only the tap target moved.)
            Hotspot(id: "hook", 0.395, 0.378, 0.098, 0.341),
            Hotspot(id: "winch", 0.11, 0.02, 0.17, 0.16),
            Hotspot(id: "mirror", 0.05, 0.36, 0.16, 0.52),
            // F-024 diegetic passages: the ladder up to the hearth trapdoor and — once the
            // shelf has slid — the revealed alcove mouth behind the sliding plank shelf.
            Hotspot(id: "ladder", 0.84, 0.06, 0.13, 0.80),
            Hotspot(id: "alcove-passage", 0.42, 0.28, 0.10, 0.45),
        ], view: .cellar))
    }

    /// Build 10, cluster B (R4-024 anchor): the cellar is now ONE stable base plus fully
    /// INDEPENDENT per-element overlays — barrel / drawer / crank / mirror / shelf / beam /
    /// weight-hung — each driven solely by its own state. The build-9 full-plate base swaps
    /// (beam matrix + shelf-slid + weight-hung) baked several elements' states into one
    /// image, so changing one (e.g. rotating the mirror → new beam base) visibly flipped
    /// another (the barrel) and the moonbeam jumped. Eliminating the swaps removes that
    /// cross-contamination by construction. The overlay rects come from the re-framed
    /// overlays.json (self-located by auto-diff — this also fixes R4-011: the mirror overlay
    /// was previously cropped from the wrong region and never appeared to move).
    private func refreshCellar() {
        scene.setBaseTexture("z3-cellar-base") // the single, never-swapped cellar base

        // Beam: a light overlay that is a pure function of (moonbeam-on, mirror-detent-3,
        // shelf-slid) — one element, independently composited (never a base swap).
        //
        // Stacking (these overlays OVERLAP, so z is explicit and state-derived — see the
        // setOverlay doc): mirror z11 < shelf z12 < beam z13. The beam-blocked/-alcove
        // crops were diffed from plates whose overlap strips already show the d3 mirror
        // edge / slid shelf, so drawing the beam ON TOP is pixel-consistent AND keeps the
        // bloom-critical "light enters the alcove" cue visible. EXCEPT `.floorBeam`, whose
        // source plate has the shelf CLOSED: with the shelf already open (weight hung,
        // mirror still at d2) the beam must slip UNDER the shelf/mirror overlays (z9),
        // sacrificing a sliver of glow instead of ghosting a closed shelf over the open one.
        let beamImage: String?
        var beamZ: CGFloat = 13
        switch RoomVisuals.beamVisual(state) {
        case .none:           beamImage = nil
        case .floorBeam:      beamImage = "ov-beam-floor"; beamZ = 9
        case .blockedOnShelf: beamImage = "ov-beam-blocked"
        case .intoAlcove:     beamImage = "ov-beam-alcove"
        }
        scene.setOverlay("beam", imageNamed: beamImage,
                          rectNormalized: beamImage.map { overlayRect("z3/v-cellar", $0) } ?? .zero,
                          zPosition: beamZ)

        // Shelf slid open (reveals the alcove mouth) — independent of the beam.
        scene.setOverlay("shelf", imageNamed: RoomVisuals.shelfSlid(state) ? "ov-shelf-slid" : nil,
                          rectNormalized: overlayRect("z3/v-cellar", "ov-shelf-slid"),
                          zPosition: 12)

        let barrelOverlay = RoomVisuals.barrelOverlay(state)
        scene.setOverlay("barrel", imageNamed: barrelOverlay,
                          rectNormalized: barrelOverlay.map { overlayRect("z3/v-cellar", $0) } ?? .zero)
        // Drawer: shut (base art) / open-with-spoon / open-empty (R4-012(2) state refresh).
        let drawerOverlay = RoomVisuals.drawerOverlay(state)
        scene.setOverlay("drawer", imageNamed: drawerOverlay,
                          rectNormalized: drawerOverlay.map { overlayRect("z3/v-cellar", $0) } ?? .zero)
        scene.setOverlay("crank", imageNamed: RoomVisuals.crankFitted(state) ? "ov-crank-fitted" : nil,
                          rectNormalized: overlayRect("z3/v-cellar", "ov-crank-fitted"))
        // Mirror at detent 2 / 3 — its own overlay; rotating it now visibly moves the
        // mirror and touches nothing else (R4-011 / R4-024).
        let mirrorOverlay = state.data.mirrorDetent == 3 ? "ov-mirror-d3"
            : (state.data.mirrorDetent == 2 ? "ov-mirror-d2" : nil)
        scene.setOverlay("mirror", imageNamed: mirrorOverlay,
                          rectNormalized: mirrorOverlay.map { overlayRect("z3/v-cellar", $0) } ?? .zero,
                          zPosition: 11)
        // Transient weight-hung beat — now an overlay (was a full base swap). Topmost:
        // it covers the shelf region during the beat, before the slide is revealed.
        scene.setOverlay("weight-hung", imageNamed: showingWeightHungBeat ? "ov-weight-hung" : nil,
                          rectNormalized: overlayRect("z3/v-cellar", "ov-weight-hung"),
                          zPosition: 14)
    }

    // MARK: - v-alcove (z4)

    private func configureAlcove() {
        scene.setBaseTexture("z4-alcove-base")
        // R3-005 re-calibration (build 9): re-derived from the NEW build-3 z4-alcove-base.
        // The moonflower PLANTER (stone basin) is center-bottom x0.42-0.72 y0.58-0.95; the
        // crow STATUE holding the star-topped key is center x0.53-0.68 y0.10-0.52 (the key
        // hangs from its beak x0.53-0.58 y0.14-0.35); the exit passage back to the cellar is
        // the right-edge stone gap.
        scene.configureHotspots(Reframe.map([
            Hotspot(id: "planter", 0.42, 0.55, 0.30, 0.42),
            Hotspot(id: "statue-key", 0.52, 0.10, 0.17, 0.42),
            // F-024: the shelf gap back out to the cellar (right frame edge).
            Hotspot(id: "cellar-passage", 0.85, 0.10, 0.13, 0.80),
        ], view: .alcove))
    }

    private func refreshAlcove() {
        let planter = RoomVisuals.planterState(state)
        let keyTaken = RoomVisuals.cageKeyTaken(state)
        switch (planter, keyTaken) {
        case ("closed", false): scene.setBaseTexture("z4-alcove-base")
        case ("trembling", _): scene.setBaseTexture("z4-alcove-trembling")
        case ("blooming", false): scene.setBaseTexture("z4-alcove-blooming")
        case ("blooming", true): scene.setBaseTexture("z4-alcove-blooming-keytaken")
        case ("picked", false): scene.setBaseTexture("z4-alcove-picked")
        case ("picked", true): scene.setBaseTexture("z4-alcove-picked-keytaken")
        default: scene.setBaseTexture("z4-alcove-base")
        }
        if planter == "closed" || planter == "trembling" {
            scene.setOverlay("key-taken", imageNamed: keyTaken ? "ov-key-taken" : nil,
                              rectNormalized: overlayRect("z4/v-alcove", "ov-key-taken"))
        } else {
            scene.setOverlay("key-taken", imageNamed: nil, rectNormalized: .zero)
        }
    }

    // MARK: - Tap routing (select-then-tap)

    private func handleTap(_ hotspotID: String) {
        // An armed inventory item first tries this tap as a USE.
        // R2-030: keep the item ARMED on a failed use; disarm ONLY on a successful use
        // (or explicit tap-away / re-tap / ✕, handled elsewhere). "Successful" = the use
        // meaningfully progressed OR triggered its intended in-world reaction (crow
        // refusal, fairness reject) — anything that isn't a no-op on the wrong target.
        //
        // Cluster F (R4-005, build 10): an armed item must NEVER block inspection — if
        // the use did not engage this target, the tap FALLS THROUGH to the normal look
        // (close-up / free action) with the item still armed, so the player can keep
        // examining clues and experimenting without deselecting first.
        if let armed = interaction?.armedItem {
            if useItem(armed, on: hotspotID) {
                interaction?.disarm()
            } else {
                lookTap(hotspotID) // armed state never walls off looks (R4-005)
            }
            return
        }
        lookTap(hotspotID)
    }

    /// Bare taps: looks, direct pickups, and item-free apparatus actions. No generic
    /// interaction sound — each case carries its own object-relevant cue or none
    /// (F-005/F-009/F-019; dead hotspots are silent per F-006/F-014).
    private func lookTap(_ hotspotID: String) {
        switch (viewID, hotspotID) {

        // -- z1 v-hearth --
        case (.hearth, "poker"):
            if !RoomVisuals.pokerTaken(state) {
                state.addItem(PuzzleGraph.ItemID.poker)
                SoundManager.shared.play(.pickup)
            }
            // Taken: the hook is empty — dead hotspot, intentionally silent (F-006).
        case (.hearth, "ash"):
            // No auto-apply: a bare tap is always a look. Sifting requires the armed
            // poker (F-007/F-020/F-021). If the ring is already revealed-but-uncollected,
            // the ash close-up presents it as a tap-to-collect target (R2-003a).
            present(.ashPile, from: "ash")
        case (.hearth, "clock"):
            present(.clock, from: "clock")
        case (.hearth, "bellows"):
            present(.plain(image: "cu-bellows"), from: "bellows")
        case (.hearth, "lintel"):
            present(.plain(image: "cu-lintel"), from: "lintel")
        case (.hearth, "rug"):
            if !RoomVisuals.rugMoved(state) {
                PuzzleEngine.moveRug(state: state)
                SoundManager.shared.play(.cloth)
            }
        case (.hearth, "trapdoor-dial"):
            guard RoomVisuals.rugMoved(state) else { break } // nothing there before discovery
            if RoomVisuals.trapdoorOpen(state) {
                onNavigate?(.cellar) // diegetic passage (style guide Section 7)
            } else {
                present(.dialPanel, from: "trapdoor-dial")
            }

        // -- z1 v-study --
        case (.study, "grimoire"):
            present(.grimoire, from: "grimoire")
        case (.study, "triptych-1"):
            present(.triptych(panel: 0), from: "triptych")
        case (.study, "triptych-2"):
            present(.triptych(panel: 1), from: "triptych")
        case (.study, "triptych-3"):
            present(.triptych(panel: 2), from: "triptych")
        case (.study, "flowerpot"):
            present(.plain(image: "cu-flowerpot"), from: "flowerpot")
        case (.study, "rune-door"):
            if state.hasSolved(PuzzleGraph.PuzzleID.runeDoor) {
                onNavigate?(.bench) // the unbarred inner door is the passage to z2
            } else {
                present(.runeDoor, from: "rune-door")
            }

        // -- z1 v-entry --
        case (.entry, "rusted-key"):
            // R6-003: the rusted key is an in-world DECOY, never an inventory item (standing
            // principle: decoys are never collected). A tap INSPECTS it (the close-up shows
            // the snapped/plain bit that will never fit the star lock) and leaves inventory
            // untouched. The real cage key comes from the z4 statue. No solve path references
            // itm-rusted-key (graph `uses: []`), so nothing is lost by never granting it.
            present(.plain(image: "cu-rusted-key"), from: "rusted-key")
        case (.entry, "windowsill"):
            present(.plain(image: "cu-windowsill"), from: "windowsill")
        case (.entry, "cage"), (.entry, "feed-cup"):
            // F-011 fix: a bare tap is a LOOK at the caged crow's neutral pose. The
            // turned-back pose is exclusively the D3/D4 refusal reaction, which now
            // triggers only on an armed-item offer (a deliberate reach).
            present(.plain(image: state.hasFlag(PuzzleGraph.StateFlag.crowFreed)
                            ? "cu-cage-open-empty" : "cu-cage-crow"), from: hotspotID)
        case (.entry, "star-keyhole"):
            if state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
                present(.plain(image: "cu-cage-open-empty"), from: "star-keyhole")
            } else {
                // No auto-unlock with the key merely held: look at the star socket.
                present(.plain(image: "cu-star-keyhole"), from: "star-keyhole")
            }
        case (.entry, "door-lock"):
            doorLockTap()

        // -- z2 v-bench --
        case (.bench, "cauldron"), (.bench, "ladle"):
            present(.brew, from: "cauldron")
        case (.bench, "floor-bellows"):
            pumpFloorBellows()
        case (.bench, "mortar"):
            present(.plain(image: RoomVisuals.mortarState(state)), from: "mortar")
        case (.bench, "workbench"):
            break // inert scenery tap: silent (F-014 class)

        // -- z2 v-cabinet --
        case (.cabinet, "sun-slot"), (.cabinet, "moon-slot"):
            if state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) {
                present(.container(.sunMoonCabinet), from: hotspotID)
            } else {
                // Build 10 (R4-020(1)): state-aware slots view — a correctly-seated item
                // renders IN its recess, so partial placements read as progress.
                present(.cabinetSlots, from: hotspotID)
            }
        case (.cabinet, "potion-shelf"):
            present(.plain(image: "cu-potion-shelf"), from: "potion-shelf")
        case (.cabinet, "window"):
            present(.plain(image: "cu-window-orion"), from: "window")
        case (.cabinet, "astrolabe"):
            if state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion) {
                present(.container(.astrolabeDrawer), from: "astrolabe")
            } else {
                present(.astrolabe, from: "astrolabe")
            }

        // -- z3 v-cellar --
        case (.cellar, "drawer"):
            // Manual pickup, two beats: opening the drawer is a latched free action;
            // the visible spoon is then taken with its own tap (feedback round 1).
            // Build 10 (cluster D, R4-012(1)): the drawer-open sfx-wood was the SAME
            // disliked "psh" asset as the nav beat — removed; the slide is visual only.
            if !RoomVisuals.cellarDrawerOpened(state) {
                PuzzleEngine.openCellarDrawer(state: state)
            } else if !RoomVisuals.spoonTaken(state) {
                state.addItem(PuzzleGraph.ItemID.spoon)
                SoundManager.shared.play(.pickup)
            } else {
                // Depleted (Q1/R2-022 class): the emptied drawer's state renders in the
                // wide view (ov-drawer-empty); no pointless spoon-still-there zoom
                // (R4-012(2) — the stale close-up plate showed the taken spoon).
                break
            }
        case (.cellar, "barrel"):
            // Q1 (depleted-hotspot pruning): once the barrel is pried AND the weight is
            // collected, it's spent — stop offering the pry-gap zoom (R2-022). While the
            // pried barrel still holds the uncollected weight, the close-up presents it
            // as a tap-to-collect target (build 10, R4-013 manual pickup).
            if state.hasSolved(PuzzleGraph.PuzzleID.barrelPry),
               !PuzzleEngine.isWeightUncollectedInBarrel(state) {
                break // depleted: no pointless zoom
            }
            present(.barrel, from: "barrel")
        case (.cellar, "winch"):
            // No auto-fit with the crank merely held: look at the socket/crank.
            present(.plain(image: state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn)
                            ? "cu-winch-crank" : "cu-winch-socket"), from: "winch")
        case (.cellar, "mirror"):
            let next = (state.data.mirrorDetent % MirrorSolution.detentCount) + 1
            PuzzleEngine.rotateMirror(toDetent: next, state: state)
            SoundManager.shared.play(.grind)
        case (.cellar, "hook"):
            // R6-006: the roped-hook target now sits over the sliding-shelf / alcove-mouth
            // region and, being the smaller rect, wins the hit-test over `alcove-passage`.
            // Once the shelf has slid (weight hung), that spot IS the revealed passage — so a
            // bare tap there navigates to the alcove, exactly like alcove-passage, and the
            // move can never strand the player. Before the shelf slides the hook is purely
            // the armed-weight use target (a bare tap is inert and silent).
            if RoomVisuals.shelfSlid(state) {
                onNavigate?(.alcove)
            }
        case (.cellar, "ladder"):
            // Diegetic passage: up the ladder through the trapdoor (F-024).
            if RoomVisuals.trapdoorOpen(state) {
                onNavigate?(.hearth)
            }
        case (.cellar, "alcove-passage"):
            // Diegetic passage: through the revealed alcove mouth (F-024). Inert
            // (and invisible) until the shelf has slid.
            if RoomVisuals.shelfSlid(state) {
                onNavigate?(.alcove)
            }

        // -- z4 v-alcove --
        case (.alcove, "planter"):
            if !state.hasSolved(PuzzleGraph.PuzzleID.moonflowerBloom) {
                if PuzzleEngine.pickBlossom(state: state) {
                    SoundManager.shared.play(.pickup)
                } else {
                    // Not yet bloomed (needs the moonbeam): a look is still informative.
                    present(.plain(image: "cu-planter-\(RoomVisuals.planterState(state))"), from: "planter")
                }
            }
            // Q1: after the single blossom is picked the planter is spent — no more zoom
            // (R2-027). The picked state renders in the wide view.
        case (.alcove, "statue-key"):
            // Build 10 (R4-026): manual pickup from the close-up — the statue look
            // shows the key in the beak; the player taps the KEY to collect it. After
            // the key is taken the close-up shows the key-taken state.
            present(.statueKey, from: "statue-key")
        case (.alcove, "cellar-passage"):
            onNavigate?(.cellar) // back out through the shelf gap (F-024)

        default:
            break
        }
    }

    /// p16/p17 door interactions (QA-BUG-003): before unsealing the door-lock close-up
    /// is the inspection surface; once unsealed, the tap slides the bolt and wins.
    private func doorLockTap() {
        if state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) {
            if !state.isComplete {
                if PuzzleEngine.slideBoltAndLeave(state: state) {
                    SoundManager.shared.play(.door) // the front door swinging open (R2-015a)
                }
            }
        } else {
            present(.plain(image: "cu-door-lock"), from: "door-lock")
        }
    }

    /// D3/D4 shared refusal beat: identical pose, identical sound, zero state churn.
    /// Reached ONLY by deliberately offering an armed item at the cage/feed cup —
    /// bare taps show the neutral pose instead (F-011).
    private func playTerminalRefusal() {
        PuzzleEngine.triggerCrowTerminalRefusal()
        showTerminalRefusal = true
        activeCloseUp = .refusal
        closeUpOrigin = nil
        SoundManager.shared.play(.refusal)
    }

    /// Floor bellows in the scene pump the flame stage directly (stages cycle
    /// 1 -> 2 -> 3 -> 1 per flame_mechanics); the brew close-up has the same control.
    func pumpFloorBellows() {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return }
        let next = (state.data.cauldronFlameStage % 3) + 1
        state.setCauldronFlameStage(next)
        SoundManager.shared.play(.bellows)
    }

    // MARK: - Close-up interactions (driven by CloseUpView)

    /// An armed item used while a close-up is open routes to the close-up's
    /// originating hotspot (the zoomed view is the same object, just closer). This is
    /// what makes every tool-on-hotspot puzzle solvable from inside its close-up —
    /// the exact flow the user could not perform in F-020.
    func useArmedItemInCloseUp() {
        guard let origin = closeUpOrigin else { return }
        useArmedItem(onHotspot: origin)
    }

    /// Build 10 (R4-020(1)): a close-up can route an armed use to a SPECIFIC hotspot
    /// (e.g. the slots close-up's per-recess targets), not only its originating one.
    /// R2-030: disarm only on a successful/engaged use; a wrong-target no-op keeps the
    /// item armed so the player can try elsewhere without re-selecting.
    func useArmedItem(onHotspot hotspotID: String) {
        guard let armed = interaction?.armedItem else { return }
        if useItem(armed, on: hotspotID) {
            interaction?.disarm()
        }
    }

    /// Collect one visible item from an opened container (F-023/F-018 manual pickup).
    func collectContainerItem(_ itemID: String, from container: PuzzleEngine.Container) {
        if PuzzleEngine.collectItem(itemID, from: container, state: state) {
            SoundManager.shared.play(.pickup)
            objectWillChange.send()
        }
    }

    /// p01: tile presses from the rune-door close-up.
    func pressRuneTile(_ tile: Int) {
        guard let rune = RuneDoorSolution.tileRune[tile] else { return }
        SoundManager.shared.play(.stonePress)
        switch PuzzleEngine.pressRuneTile(rune, state: state) {
        case .solved:
            SoundManager.shared.play(.door) // themed rune-door opening (R2-015a)
            dismissCloseUp() // pull back so the opened door / new zone reads
        case .reset:
            SoundManager.shared.play(.wrong) // dull knock; tiles reset flush
        case .inProgress:
            break
        }
        objectWillChange.send()
    }

    /// Which tiles render pressed in the close-up (from persisted progress).
    var pressedRuneTiles: Set<Int> {
        let runeToTile = Dictionary(uniqueKeysWithValues: RuneDoorSolution.tileRune.map { ($1.rawValue, $0) })
        return Set(state.data.runeDoorProgress.compactMap { runeToTile[$0] })
    }

    /// p03: the player chose a plate in the astrolabe close-up (QA-BUG-005).
    /// F-023: solving springs the drawer open with the coin + crank VISIBLE — the
    /// container close-up follows, and the player taps each item to collect it.
    func selectAstrolabePlate(_ index: Int) {
        if PuzzleEngine.selectAstrolabePlate(index, state: state) {
            SoundManager.shared.play(.solve)
            present(.container(.astrolabeDrawer), from: "astrolabe")
        } else {
            SoundManager.shared.play(.wrong)
        }
    }

    /// Q3 (user decision 2026-07-08): the D5 cuckoo is REMOVED. The mantel clock is now
    /// purely the p01 numeral-ring reference; its hands still move (a small tactile beat)
    /// but nothing pops and no state is latched — the clock never gates or rewards.
    func advanceClockHour() {
        clockHour = clockHour % 12 + 1
        SoundManager.shared.play(.tick)
    }

    /// p14 brew resolve outcome, reported by BrewControlView inside the brew close-up.
    func brewOutcomeReported(_ outcome: PuzzleEngine.BrewOutcome) {
        lastBrewOutcome = outcome
    }

    // MARK: - Item use (armed item -> target hotspot)

    /// The single "use item X on hotspot Y" entry point (select-then-tap). Also the
    /// programmatic surface unit tests drive.
    ///
    /// Returns TRUE when the use meaningfully engaged the target (progressed a puzzle OR
    /// produced its intended in-world reaction — a refusal, a fairness reject) and the
    /// caller should DISARM. Returns FALSE for a wrong-target no-op, so the item stays
    /// ARMED and the player can try another target immediately (R2-030). Never mutates
    /// state on a false return.
    @discardableResult
    func useItem(_ itemID: String, on hotspotID: String) -> Bool {
        switch (viewID, hotspotID) {

        // -- z1 v-entry --
        case (.entry, "feed-cup"):
            // D4 (+ D1 for the draught specifically): ANY item offered here gets the
            // identical terminal refusal; item is returned to inventory unspent. This IS
            // the item's intended reaction here, so it counts as a use (disarm).
            guard !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) else { return false }
            if itemID == PuzzleGraph.ItemID.phialDraught {
                PuzzleEngine.attemptPourDraughtAtFeedCup()
            } else {
                PuzzleEngine.triggerCrowTerminalRefusal()
            }
            showTerminalRefusal = true
            activeCloseUp = .refusal
            closeUpOrigin = nil
            SoundManager.shared.play(.refusal)
            return true
        case (.entry, "star-keyhole"), (.entry, "cage"):
            return entryCageUse(itemID, on: hotspotID)
        case (.entry, "door-lock"):
            if itemID == PuzzleGraph.ItemID.phialDraught {
                if PuzzleEngine.pourDraughtOnBasin(state: state) {
                    SoundManager.shared.play(.solve)
                    present(.plain(image: "cu-door-lock-vines-gone"), from: "door-lock") // wither beat
                    return true
                }
                return false
            } else if itemID == PuzzleGraph.ItemID.rustedKey {
                // Red-herring fairness valve: visible mechanical reject (an intended
                // reaction — disarm).
                SoundManager.shared.play(.wrong)
                present(.plain(image: "cu-door-lock"), from: "door-lock")
                return true
            }
            return false

        // -- z1 v-hearth --
        case (.hearth, "ash"):
            if itemID == PuzzleGraph.ItemID.poker {
                return siftAsh()
            }
            return false

        // -- z3 v-cellar --
        case (.cellar, "barrel"):
            if itemID == PuzzleGraph.ItemID.poker {
                let newly = !state.hasSolved(PuzzleGraph.PuzzleID.barrelPry)
                if PuzzleEngine.pryBarrel(state: state) {
                    // Item lifecycle (cluster A): retain/consume is handled by the
                    // GameState markSolved hook — the poker survives here unless BOTH
                    // its graph uses (p05 + p06) are now satisfied (R4-019 fix).
                    if newly {
                        SoundManager.shared.play(.solve)
                        present(.barrel, from: "barrel") // weight revealed + pickable (R4-013)
                    }
                    return true
                }
            }
            return false
        case (.cellar, "hook"):
            if itemID == PuzzleGraph.ItemID.weight {
                let newly = !state.hasSolved(PuzzleGraph.PuzzleID.shelfCounterweight)
                if PuzzleEngine.hangWeight(state: state) {
                    if newly {
                        SoundManager.shared.play(.unlock)
                        playWeightHungBeat()
                    }
                    return true // weight placed on the hook; consumed by the lifecycle hook
                }
            }
            return false
        case (.cellar, "winch"):
            if itemID == PuzzleGraph.ItemID.crank {
                let newly = !state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn)
                if PuzzleEngine.fitCrankAndTurn(state: state) {
                    if newly { SoundManager.shared.play(.unlock) }
                    return true // crank fitted; consumed by the lifecycle hook (its only use)
                }
            }
            return false

        // -- z2 v-cabinet --
        case (.cabinet, "sun-slot"), (.cabinet, "moon-slot"):
            return attemptCabinetPlacement(itemID, slot: hotspotID)

        // -- z2 v-bench --
        case (.bench, "mortar"):
            if itemID == PuzzleGraph.ItemID.blossom, PuzzleEngine.grindPaste(state: state) {
                SoundManager.shared.play(.solve)
                present(.plain(image: "cu-mortar-paste"), from: "mortar")
                return true
            }
            return false
        case (.bench, "cauldron"), (.bench, "ladle"):
            return cauldronUse(itemID)
        case (.bench, "workbench"):
            // p12 secondary path: the workbench accepts the combination. The file and
            // spoon (both single-use, p12 only) are consumed by the lifecycle hook.
            if itemID == PuzzleGraph.ItemID.file || itemID == PuzzleGraph.ItemID.spoon {
                let other = itemID == PuzzleGraph.ItemID.file ? PuzzleGraph.ItemID.spoon : PuzzleGraph.ItemID.file
                let newly = !state.hasSolved(PuzzleGraph.PuzzleID.fileShavings)
                if ItemCombinations.combine(itemID, other, state: state), newly {
                    SoundManager.shared.play(.solve)
                    return true
                }
            }
            return false

        default:
            return false
        }
    }

    // MARK: - Item lifecycle (build 10, cluster A)
    //
    // The old hand-maintained `toolUseGates` closures + scattered `dropItemIfDepleted`
    // call sites are RETIRED. Retain/consume is now the single graph-driven rule in
    // `ItemLifecycle` (PuzzleGraphModel.swift), reconciled from the GameState
    // markSolved/setFlag hooks — no interaction path can bypass it (R4-019/R4-030).

    /// p05 via the armed poker (the ONLY way to sift — no passive auto-apply). R2-003a:
    /// sifting reveals the ring in the ash (no auto-grant); the ash close-up now shows it
    /// as a tap-to-collect target and the sifted plate renders until it's taken.
    @discardableResult
    private func siftAsh() -> Bool {
        guard state.hasItem(PuzzleGraph.ItemID.poker), !state.hasSolved(PuzzleGraph.PuzzleID.ashSift) else { return false }
        if PuzzleEngine.siftAsh(state: state) {
            SoundManager.shared.play(.solve)
            present(.ashPile, from: "ash") // ring now visible + pickable
            return true
        }
        return false
    }

    /// R2-003a: explicit pickup tap on the revealed ash ring.
    func collectAshRing() {
        if PuzzleEngine.collectAshRing(state) {
            SoundManager.shared.play(.pickup)
            objectWillChange.send()
        }
    }

    /// Build 10 (R4-013): explicit pickup tap on the weight revealed in the pried barrel.
    func collectBarrelWeight() {
        if PuzzleEngine.collectBarrelWeight(state) {
            SoundManager.shared.play(.pickup)
            objectWillChange.send()
        }
    }

    /// Build 10 (R4-026): explicit pickup tap on the key in the statue's beak.
    func collectStatueKey() {
        if PuzzleEngine.collectStatueKey(state) {
            SoundManager.shared.play(.pickup)
            objectWillChange.send()
        }
    }

    /// QA-BUG-018 lineage, select-then-tap form: using keys on the cage/star keyhole
    /// acts. The star key unlocks; the rusted key gets a visible mechanical reject at
    /// the keyhole close-up; any other item offered at the cage is a reach and gets
    /// the terminal refusal (D3).
    @discardableResult
    private func entryCageUse(_ itemID: String, on hotspotID: String) -> Bool {
        if itemID == PuzzleGraph.ItemID.cageKey, !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
            if PuzzleEngine.unlockCage(state: state) {
                SoundManager.shared.play(.solve)
                present(.plain(image: "cu-crow-rafters"), from: hotspotID)
                // key spent in the lock — consumed by the lifecycle hook (its only use)
                return true
            }
            return false
        } else if itemID == PuzzleGraph.ItemID.rustedKey {
            SoundManager.shared.play(.wrong)
            present(.plain(image: "cu-star-keyhole"), from: hotspotID) // plain bit visibly rejected
            return true // intended fairness reject — disarm
        } else if !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
            playTerminalRefusal()
            return true // intended refusal reaction — disarm
        }
        return false
    }

    /// p14 ingredient adds + p15 bottling (QA-BUG-002) share the cauldron target.
    @discardableResult
    private func cauldronUse(_ itemID: String) -> Bool {
        if itemID == PuzzleGraph.ItemID.phial {
            if PuzzleEngine.fillPhial(state: state) {
                SoundManager.shared.play(.solve)
                present(.brew, from: "cauldron") // show the (still-ready) draught being bottled
                return true
            } else {
                SoundManager.shared.play(.wrong) // cauldron isn't ready yet
                return false // let the player re-try once ready without re-arming
            }
        } else {
            return addCauldronIngredient(itemID)
        }
    }

    private func playWeightHungBeat() {
        showingWeightHungBeat = true
        refreshCellar()
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.9) { [weak self] in
            self?.showingWeightHungBeat = false
            self?.refreshCellar()
        }
    }

    /// QA-BUG-017 fix: per-slot validation. A wrong item never becomes "pending" — it
    /// pops back audibly. Only the correct item seats (rendered by refreshCabinet and,
    /// build 10, by the state-aware `.cabinetSlots` close-up); the pair completing
    /// hands over to the engine, which consumes both. On the pair completing, the
    /// cabinet opens with its contents visible for manual pickup.
    ///
    /// Build 10 (R4-020(1)): a CORRECT partial placement now gives clearly POSITIVE
    /// per-slot feedback — the item seats visibly (wide overlay + close-up seat art)
    /// with a warm "seat" cue, never the tick that read as "not working". Judgment
    /// call (implementation notes): the seated item stays in inventory until the pair
    /// completes — pending placements are coordinator-local by design (QA-BUG-017
    /// anti-softlock: leaving the view can never strand a half-placed item).
    ///
    /// Clue-gating note (R4-020(1) verification): p04's gate (clu-slot-shapes) is
    /// "self-satisfying" per the graph — but under select-then-tap a player CAN reach a
    /// slot without ever opening the slots close-up. Physically seating an item in a
    /// recess is equivalent exposure to the slot-shapes clue, so it records the clue
    /// viewed — otherwise a fully correct pair would silently never open (worse than
    /// the confusion this item reports). Flagged in implementation notes.
    @discardableResult
    private func attemptCabinetPlacement(_ itemID: String, slot: String) -> Bool {
        guard !state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) else { return false }
        let correctItem = slot == "sun-slot" ? CabinetSolution.sunSlotItem : CabinetSolution.moonSlotItem
        guard itemID == correctItem, state.hasItem(itemID) else {
            SoundManager.shared.play(.wrong) // "item pops back out" (failure_behavior)
            // R2-030: a wrong item at a slot pops back — keep it armed to try the other
            // slot immediately. (Returns false = no disarm; falls through to the look.)
            return false
        }
        if slot == "sun-slot" { pendingSunItem = itemID } else { pendingMoonItem = itemID }
        state.markClueViewed(ClueID.slotShapes) // seating IS seeing the slot shapes (see doc)
        SoundManager.shared.play(.seat) // warm positive seat cue (R4-020(1); replaces .tick)
        if PuzzleEngine.placeCabinetItems(sun: pendingSunItem, moon: pendingMoonItem, state: state) {
            SoundManager.shared.play(.solve)
            pendingSunItem = nil
            pendingMoonItem = nil
            present(.container(.sunMoonCabinet), from: slot) // F-023 manual pickup
        }
        refreshCabinet()
        objectWillChange.send() // live-update an open .cabinetSlots close-up
        return true // correct item seated (placed) — disarm
    }

    @discardableResult
    private func addCauldronIngredient(_ itemID: String) -> Bool {
        // Post-success adds are refused: the draught is done and ingredients must not
        // vanish into it (QA-BUG-006 companion guard).
        guard !state.hasFlag(PuzzleGraph.StateFlag.draughtReady) else { return false }
        guard BrewSolution.requiredIngredients.contains(itemID), state.hasItem(itemID) else { return false }
        var ingredients = state.data.cauldronIngredients
        ingredients.insert(itemID)
        state.removeItem(itemID) // placed into the cauldron (removed from inventory, R2-020)
        state.setCauldronIngredients(ingredients)
        SoundManager.shared.play(.stir) // the ingredient slipping into the water
        return true
    }

    // MARK: - overlay rect lookup

    private func overlayRect(_ viewKey: String, _ overlayKey: String) -> CGRect {
        OverlayRectCatalog.shared.rect(view: viewKey, overlay: overlayKey) ?? .zero
    }
}
