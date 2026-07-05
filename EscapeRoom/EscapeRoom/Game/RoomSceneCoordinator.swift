import SpriteKit
import Combine

/// Wires a `RoomScene` for a given `ViewID` to `GameState` + `PuzzleEngine`: builds the
/// hotspot list, resolves the current texture set from state, and handles taps/drops by
/// dispatching to the appropriate PuzzleEngine call. One coordinator instance per active
/// view; the room navigator (SwiftUI) creates/destroys these as the player moves between
/// views, but GameState itself is shared/long-lived (owned by LevelSession).
///
/// QA fix pass (2026-07-06):
/// - Emits `CloseUpRequest`s for the inspection layer (QA-BUG-013) instead of dead taps.
/// - Hotspot rects re-aligned against the real art on the non-BUG-004 plates
///   (QA-BUG-015); the BUG-004 plates (v-entry, v-cellar, hearth bellows region,
///   cabinet potion-shelf/astrolabe/window region) keep their old values pending the
///   Asset Generation re-frame batch — final alignment happens when those plates land.
/// - p15/p17/p12 interaction paths wired (QA-BUG-002/-003/-012).
/// - Cabinet placement validates per-slot and rejects audibly (QA-BUG-017).
/// - Key drops on the cage/keyhole act (QA-BUG-018); rug discovery beat (QA-BUG-010);
///   post-freedom cage taps stop replaying the refusal (QA-BUG-020).
final class RoomSceneCoordinator: ObservableObject {
    let viewID: ViewID
    let scene: RoomScene
    let state: GameState
    /// The presenting SKView, supplied by SpriteKitContainerView. Used for the exact
    /// UIKit-window-point -> scene-point conversion on inventory drops (QA-BUG-014).
    weak var skView: SKView?
    private var cancellable: AnyCancellable?

    // MARK: Transient (non-persisted) per-scene UI state.

    @Published var lastBrewOutcome: PuzzleEngine.BrewOutcome?
    @Published var justPoppedClock: Bool = false
    @Published var showTerminalRefusal: Bool = false
    /// The close-up currently presented over this scene (QA-BUG-013). Set by tap
    /// handling below; cleared by the close-up's down-chevron (CloseUpView).
    @Published var activeCloseUp: CloseUpRequest?
    /// Cosmetic clock-hand position for the clock close-up (D5). Not persisted — only
    /// the one-shot cuckoo latch is, via the engine.
    @Published var clockHour: Int = 6
    /// Pending (visually seated, not yet consumed) cabinet placements. Coordinator-
    /// local by design: leaving the view pops any lone seated item back conceptually
    /// (it was never removed from inventory), so no soft-lock is possible (QA-BUG-017).
    @Published private(set) var pendingSunItem: String?
    @Published private(set) var pendingMoonItem: String?
    /// True briefly after a successful ash sift so the glint state renders (QA-BUG-016).
    private(set) var justSiftedAsh: Bool = false
    /// True briefly after hanging the weight so the z3-cellar-weight-hung plate renders
    /// before the shelf slides (QA-BUG-016).
    private var showingWeightHungBeat: Bool = false

    /// Diegetic zone passages (trapdoor -> cellar, solved rune door -> workshop);
    /// wired to LevelSession.goTo by GameRoomView.
    var onNavigate: ((ViewID) -> Void)?

    init(viewID: ViewID, state: GameState, size: CGSize) {
        self.viewID = viewID
        self.state = state
        self.scene = RoomScene(viewID: viewID, size: size)
        configure()
        scene.onHotspotTap = { [weak self] id in self?.handleTap(id) }
        scene.onItemDropped = { [weak self] itemID, hotspotID in self?.handleDrop(itemID, on: hotspotID) }
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

    // MARK: - v-hearth (z1)
    // Rects verified against z1-hearth-base (QA-BUG-015), except "bellows": the bellows
    // art sits at x~0.03-0.06, OUTSIDE the dual-safe zone — that region is being
    // re-framed by the Asset Generation agent (QA-BUG-004 carve-out); its hotspot is
    // aligned in the final BUG-004 integration step.

    private func configureHearth() {
        scene.setBaseTexture("z1-hearth-base")
        scene.configureHotspots([
            Hotspot(id: "poker", 0.19, 0.40, 0.09, 0.57),        // = ov-poker-taken rect
            Hotspot(id: "ash", 0.25, 0.57, 0.15, 0.16),
            Hotspot(id: "clock", 0.26, 0.02, 0.13, 0.24),
            Hotspot(id: "bellows", 0.62, 0.20, 0.10, 0.25),      // deferred: BUG-004 re-frame
            Hotspot(id: "lintel", 0.15, 0.24, 0.34, 0.09),
            Hotspot(id: "rug", 0.10, 0.72, 0.60, 0.28),          // = ov-rug-moved rect
            Hotspot(id: "trapdoor-dial", 0.23, 0.72, 0.39, 0.25) // = ov-trapdoor-open rect
        ])
    }

    private func refreshHearth() {
        scene.setOverlay("poker", imageNamed: RoomVisuals.pokerTaken(state) ? "ov-poker-taken" : nil,
                          rectNormalized: overlayRect("z1/v-hearth", "ov-poker-taken"))
        scene.setOverlay("rug", imageNamed: RoomVisuals.rugMoved(state) ? "ov-rug-moved" : nil,
                          rectNormalized: overlayRect("z1/v-hearth", "ov-rug-moved"))
        scene.setOverlay("trapdoor", imageNamed: RoomVisuals.trapdoorOpen(state) ? "ov-trapdoor-open" : nil,
                          rectNormalized: overlayRect("z1/v-hearth", "ov-trapdoor-open"))
    }

    // MARK: - v-study (z1)
    // Rects verified against z1-study-base (QA-BUG-015). The four per-tile hotspots are
    // gone: the physical press-plate is ~2% of the frame wide, so tiles are pressed in
    // the cu-runedoor-tiles close-up (QA-BUG-013/-015); the wide shot carries one
    // "rune-door" hotspot on the brass plate.

    private func configureStudy() {
        scene.setBaseTexture("z1-study-base")
        scene.configureHotspots([
            Hotspot(id: "grimoire", 0.36, 0.46, 0.25, 0.18),
            Hotspot(id: "triptych", 0.29, 0.07, 0.37, 0.20),
            Hotspot(id: "flowerpot", 0.59, 0.44, 0.09, 0.14),
            Hotspot(id: "rune-door", 0.75, 0.33, 0.07, 0.26),
        ])
    }

    private func refreshStudy() {
        // Tile pressed-state sprites render inside the rune-door close-up (derived from
        // the persisted in-progress sequence); the wide plate has no overlay states.
    }

    // MARK: - v-entry (z1)
    // DEFERRED (QA-BUG-004 carve-out): this whole plate is being re-framed (star
    // keyhole, feed cup, cage sit outside the iPad-visible band). Hotspot values are
    // unchanged here and get their final alignment when the re-framed plate lands.

    private func configureEntry() {
        scene.setBaseTexture("z1-entry-base")
        scene.configureHotspots([
            Hotspot(id: "door-lock", 0.40, 0.35, 0.20, 0.40),
            Hotspot(id: "rusted-key", 0.15, 0.30, 0.08, 0.20),
            Hotspot(id: "windowsill", 0.65, 0.55, 0.20, 0.15),
            Hotspot(id: "cage", 0.73, 0.20, 0.25, 0.48),
            Hotspot(id: "feed-cup", 0.85, 0.45, 0.08, 0.08),
            Hotspot(id: "star-keyhole", 0.80, 0.30, 0.06, 0.06),
        ])
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
    // Rects verified against z2-bench-base (QA-BUG-015): cauldron center-left, ladle
    // handle at its upper-left, floor bellows lying bottom-left, mortar on the bench
    // right, plus the workbench top as the p12 combination surface.

    private func configureBench() {
        scene.setBaseTexture("z2-bench-base")
        scene.configureHotspots([
            Hotspot(id: "cauldron", 0.15, 0.32, 0.21, 0.32),
            Hotspot(id: "ladle", 0.12, 0.25, 0.10, 0.15),
            Hotspot(id: "floor-bellows", 0.14, 0.77, 0.16, 0.22),
            Hotspot(id: "mortar", 0.69, 0.30, 0.15, 0.14),
            Hotspot(id: "workbench", 0.44, 0.41, 0.30, 0.12),
        ])
    }

    private func refreshBench() {
        scene.setOverlay("flame", imageNamed: flameOverlayName(),
                          rectNormalized: overlayRect("z2/v-bench", "ov-flame\(max(state.data.cauldronFlameStage, 1))"))
    }

    private func flameOverlayName() -> String? {
        let stage = state.data.cauldronFlameStage
        guard stage > 0 else { return nil }
        return "ov-flame\(min(stage, 3))"
    }

    // MARK: - v-cabinet (z2)
    // Slot rects derived from ov-slots-seated; potion-shelf / astrolabe / window are in
    // the BUG-004 re-frame region — final alignment deferred with that batch.

    private func configureCabinet() {
        scene.configureHotspots([
            Hotspot(id: "sun-slot", 0.15, 0.20, 0.10, 0.15),
            Hotspot(id: "moon-slot", 0.28, 0.20, 0.10, 0.15),
            Hotspot(id: "potion-shelf", 0.50, 0.15, 0.25, 0.30), // deferred: BUG-004 re-frame
            Hotspot(id: "astrolabe", 0.72, 0.55, 0.24, 0.35),    // deferred: BUG-004 re-frame
            Hotspot(id: "window", 0.80, 0.10, 0.18, 0.30),       // deferred: BUG-004 re-frame
        ])
        scene.setBaseTexture("z2-cabinet-base")
    }

    private func refreshCabinet() {
        scene.setOverlay("slots", imageNamed: RoomVisuals.cabinetDoorState(state) ? "ov-slots-seated" : nil,
                          rectNormalized: overlayRect("z2/v-cabinet", "ov-slots-seated"))
        scene.setOverlay("cabinet-door", imageNamed: RoomVisuals.cabinetDoorState(state) ? "ov-cab-open" : nil,
                          rectNormalized: overlayRect("z2/v-cabinet", "ov-cab-open"))
        scene.setOverlay("adrawer", imageNamed: RoomVisuals.astrolabeDrawerOpen(state) ? "ov-adrawer-open" : nil,
                          rectNormalized: overlayRect("z2/v-cabinet", "ov-adrawer-open"))
        // QA-BUG-017: a single correctly-seated item is rendered (icon art over its
        // recess) until the pair completes; no dedicated single-seat plate exists.
        let solved = state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon)
        scene.setOverlay("seat-sun", imageNamed: (!solved && pendingSunItem != nil) ? "icon-gold-ring" : nil,
                          rectNormalized: CGRect(x: 0.17, y: 0.23, width: 0.06, height: 0.09))
        scene.setOverlay("seat-moon", imageNamed: (!solved && pendingMoonItem != nil) ? "icon-silver-coin" : nil,
                          rectNormalized: CGRect(x: 0.30, y: 0.23, width: 0.06, height: 0.09))
    }

    // MARK: - v-cellar (z3)
    // DEFERRED (QA-BUG-004 carve-out): plate being re-framed (barrel mostly outside the
    // iPad band). Hotspots keep their old values until the re-framed plate lands.
    // ("shelf" was removed: it was an inert region that only swallowed drops meant for
    // the hook — QA-BUG-014 observation.)

    private func configureCellar() {
        scene.setBaseTexture("z3-cellar-base")
        scene.configureHotspots([
            Hotspot(id: "barrel", 0.75, 0.48, 0.24, 0.50),
            Hotspot(id: "drawer", 0.28, 0.52, 0.16, 0.22),
            Hotspot(id: "hook", 0.20, 0.25, 0.10, 0.15),
            Hotspot(id: "winch", 0.10, 0.12, 0.18, 0.32),
            Hotspot(id: "mirror", 0.48, 0.55, 0.20, 0.42),
        ])
    }

    private func refreshCellar() {
        scene.setOverlay("barrel", imageNamed: RoomVisuals.barrelState(state), rectNormalized: overlayRect("z3/v-cellar", RoomVisuals.barrelState(state)))
        scene.setOverlay("drawer", imageNamed: RoomVisuals.drawerState(state), rectNormalized: overlayRect("z3/v-cellar", RoomVisuals.drawerState(state)))
        if RoomVisuals.crankFitted(state) {
            scene.setOverlay("crank", imageNamed: "ov-crank-fitted", rectNormalized: overlayRect("z3/v-cellar", "ov-crank-fitted"))
        } else {
            scene.setOverlay("crank", imageNamed: nil, rectNormalized: .zero)
        }
        let mirrorOverlay = state.data.mirrorDetent == 3 ? "ov-mirror-d3" : (state.data.mirrorDetent == 2 ? "ov-mirror-d2" : nil)
        scene.setOverlay("mirror", imageNamed: mirrorOverlay, rectNormalized: mirrorOverlay.map { overlayRect("z3/v-cellar", $0) } ?? .zero)
        // Base plate itself swaps for the beam/shelf composite states (whole-frame
        // variants, not small overlays) — see z3-cellar-beam-*/shelf-slid plates.
        if showingWeightHungBeat {
            // QA-BUG-016: the weight-hung plate renders as the p07 success beat before
            // the shelf slides aside.
            scene.setBaseTexture("z3-cellar-weight-hung")
            return
        }
        switch RoomVisuals.beamVisual(state) {
        case .none:
            scene.setBaseTexture(RoomVisuals.shelfSlid(state) ? "z3-cellar-shelf-slid" : "z3-cellar-base")
        case .floorBeam:
            scene.setBaseTexture(RoomVisuals.shelfSlid(state) ? "z3-cellar-beam-floor-shelf-slid" : "z3-cellar-beam-floor")
        case .blockedOnShelf:
            scene.setBaseTexture("z3-cellar-beam-blocked")
        case .intoAlcove:
            scene.setBaseTexture("z3-cellar-beam-alcove")
        }
    }

    // MARK: - v-alcove (z4)
    // Rects verified against z4-alcove-base (QA-BUG-015): planter center-low, statue
    // key at the beak upper-right of the planter.

    private func configureAlcove() {
        scene.setBaseTexture("z4-alcove-base")
        scene.configureHotspots([
            Hotspot(id: "planter", 0.36, 0.50, 0.21, 0.46),
            Hotspot(id: "statue-key", 0.52, 0.13, 0.15, 0.27),
        ])
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

    // MARK: - Tap routing

    /// Entry point for drops originating in the SwiftUI inventory bar (resolved to a
    /// scene-space hotspot id by the caller). Public because GameRoomView drives it
    /// directly from the exact SKView-based coordinate conversion (QA-BUG-014).
    func handleExternalDrop(itemID: String, hotspotID: String) {
        handleDrop(itemID, on: hotspotID)
    }

    private func handleTap(_ hotspotID: String) {
        SoundManager.shared.play(.click)
        switch (viewID, hotspotID) {

        // -- z1 v-hearth --
        case (.hearth, "poker"):
            if !RoomVisuals.pokerTaken(state) {
                state.addItem(PuzzleGraph.ItemID.poker)
                SoundManager.shared.play(.pickup)
            }
        case (.hearth, "ash"):
            siftAshInteraction()
        case (.hearth, "clock"):
            activeCloseUp = .clock
        case (.hearth, "bellows"):
            activeCloseUp = .plain(image: "cu-bellows")
        case (.hearth, "lintel"):
            activeCloseUp = .plain(image: "cu-lintel")
        case (.hearth, "rug"):
            // QA-BUG-010: hidden-discovery free action. Latched; repeat taps inert.
            if !RoomVisuals.rugMoved(state) {
                PuzzleEngine.moveRug(state: state)
                SoundManager.shared.play(.pickup)
            }
        case (.hearth, "trapdoor-dial"):
            guard RoomVisuals.rugMoved(state) else { break } // nothing there before discovery
            if RoomVisuals.trapdoorOpen(state) {
                onNavigate?(.cellar) // diegetic passage (style guide Section 7)
            } else {
                activeCloseUp = .dialPanel
            }

        // -- z1 v-study --
        case (.study, "grimoire"):
            activeCloseUp = .grimoire
        case (.study, "triptych"):
            activeCloseUp = .triptych
        case (.study, "flowerpot"):
            activeCloseUp = .plain(image: "cu-flowerpot")
        case (.study, "rune-door"):
            if state.hasSolved(PuzzleGraph.PuzzleID.runeDoor) {
                onNavigate?(.bench) // the unbarred inner door is the passage to z2
            } else {
                activeCloseUp = .runeDoor
            }

        // -- z1 v-entry --
        case (.entry, "rusted-key"):
            if !state.hasItem(PuzzleGraph.ItemID.rustedKey) {
                state.addItem(PuzzleGraph.ItemID.rustedKey)
                SoundManager.shared.play(.pickup)
            }
        case (.entry, "windowsill"):
            activeCloseUp = .plain(image: "cu-windowsill")
        case (.entry, "cage"):
            if state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
                // QA-BUG-020: cage is open and empty; the crow is on the rafters.
                activeCloseUp = .plain(image: "cu-cage-open-empty")
            } else {
                playTerminalRefusal()
            }
        case (.entry, "feed-cup"):
            if state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
                break // crow is gone; the cup is inert scenery now
            }
            playTerminalRefusal()
        case (.entry, "star-keyhole"):
            if state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
                activeCloseUp = .plain(image: "cu-cage-open-empty")
            } else if state.hasItem(PuzzleGraph.ItemID.cageKey) {
                if PuzzleEngine.unlockCage(state: state) {
                    SoundManager.shared.play(.solve)
                    activeCloseUp = .plain(image: "cu-crow-rafters") // freed beat + falling feather frame
                }
            } else {
                activeCloseUp = .plain(image: "cu-star-keyhole") // star socket inspection
            }
        case (.entry, "door-lock"):
            doorLockTap()

        // -- z2 v-bench --
        case (.bench, "cauldron"), (.bench, "ladle"):
            activeCloseUp = .brew
        case (.bench, "floor-bellows"):
            pumpFloorBellows()
        case (.bench, "mortar"):
            activeCloseUp = .plain(image: RoomVisuals.mortarState(state))
        case (.bench, "workbench"):
            break // drop surface for p12; tap is inert

        // -- z2 v-cabinet --
        case (.cabinet, "sun-slot"), (.cabinet, "moon-slot"):
            if state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) {
                activeCloseUp = .plain(image: "cu-cabinet-open")
            } else {
                activeCloseUp = .plain(image: "cu-slots-empty")
            }
        case (.cabinet, "potion-shelf"):
            activeCloseUp = .plain(image: "cu-potion-shelf")
        case (.cabinet, "window"):
            activeCloseUp = .plain(image: "cu-window-orion")
        case (.cabinet, "astrolabe"):
            // QA-BUG-005 fix: a bare tap opens the six-plate mini-game; the player
            // must choose the plate. The coordinator never supplies the answer.
            if state.hasSolved(PuzzleGraph.PuzzleID.astrolabeOrion) {
                activeCloseUp = .plain(image: "cu-astrolabe-drawer-empty")
            } else {
                activeCloseUp = .astrolabe
            }

        // -- z3 v-cellar --
        case (.cellar, "drawer"):
            if !state.hasItem(PuzzleGraph.ItemID.spoon) {
                state.addItem(PuzzleGraph.ItemID.spoon)
                SoundManager.shared.play(.pickup)
            } else {
                activeCloseUp = .plain(image: "cu-spoon-drawer")
            }
        case (.cellar, "barrel"):
            if state.hasItem(PuzzleGraph.ItemID.poker) {
                let newlySolved = !state.hasSolved(PuzzleGraph.PuzzleID.barrelPry)
                if PuzzleEngine.pryBarrel(state: state), newlySolved {
                    SoundManager.shared.play(.solve)
                }
            } else {
                activeCloseUp = .plain(image: "cu-barrel-gap") // pry-gap clue inspection
            }
        case (.cellar, "winch"):
            if state.hasItem(PuzzleGraph.ItemID.crank) {
                let newly = !state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn)
                if PuzzleEngine.fitCrankAndTurn(state: state), newly {
                    SoundManager.shared.play(.unlock)
                }
            } else {
                activeCloseUp = .plain(image: state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn) ? "cu-winch-crank" : "cu-winch-socket")
            }
        case (.cellar, "mirror"):
            let next = (state.data.mirrorDetent % MirrorSolution.detentCount) + 1
            PuzzleEngine.rotateMirror(toDetent: next, state: state)
            SoundManager.shared.play(.click)
        case (.cellar, "hook"):
            break // drop target for the weight; tap is inert

        // -- z4 v-alcove --
        case (.alcove, "planter"):
            if !state.hasSolved(PuzzleGraph.PuzzleID.moonflowerBloom), PuzzleEngine.pickBlossom(state: state) {
                SoundManager.shared.play(.pickup)
            } else {
                activeCloseUp = .plain(image: "cu-planter-\(RoomVisuals.planterState(state))")
            }
        case (.alcove, "statue-key"):
            if !RoomVisuals.cageKeyTaken(state) {
                state.addItem(PuzzleGraph.ItemID.cageKey)
                SoundManager.shared.play(.pickup)
            } else {
                activeCloseUp = .plain(image: "cu-statue-key-taken")
            }

        default:
            break
        }
    }

    /// p05 via tap (poker already in inventory). Also reachable via drag-poker-on-ash.
    private func siftAshInteraction() {
        if state.hasItem(PuzzleGraph.ItemID.poker), !state.hasSolved(PuzzleGraph.PuzzleID.ashSift) {
            if PuzzleEngine.siftAsh(state: state) {
                SoundManager.shared.play(.solve)
                justSiftedAsh = true
                // QA-BUG-016: show the sifted-with-glint state as the success beat.
                activeCloseUp = .plain(image: "cu-ash-sifted")
                DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) { [weak self] in
                    self?.justSiftedAsh = false
                }
            }
        } else {
            activeCloseUp = .plain(image: RoomVisuals.ashCloseUp(state, justSifted: justSiftedAsh))
        }
    }

    /// p16/p17 door interactions (QA-BUG-003): before unsealing the door-lock close-up
    /// is the inspection surface; once unsealed, the tap slides the bolt and wins.
    private func doorLockTap() {
        if state.hasFlag(PuzzleGraph.StateFlag.doorUnsealed) {
            if !state.isComplete {
                if PuzzleEngine.slideBoltAndLeave(state: state) {
                    SoundManager.shared.play(.unlock)
                }
            }
        } else {
            activeCloseUp = .plain(image: "cu-door-lock")
        }
    }

    /// D3/D4 shared refusal beat: identical pose, identical sound, zero state churn.
    private func playTerminalRefusal() {
        PuzzleEngine.triggerCrowTerminalRefusal()
        showTerminalRefusal = true
        activeCloseUp = .refusal // QA-BUG-016: the pose is actually rendered now
        SoundManager.shared.play(.refusal)
    }

    /// Floor bellows in the scene pump the flame stage directly (stages cycle
    /// 1 -> 2 -> 3 -> 1 per flame_mechanics); the brew close-up has the same control.
    func pumpFloorBellows() {
        guard state.isZoneUnlocked(PuzzleGraph.ZoneID.z2Workshop) else { return }
        let next = (state.data.cauldronFlameStage % 3) + 1
        state.setCauldronFlameStage(next)
        SoundManager.shared.play(.click)
    }

    // MARK: - Close-up interactions (driven by CloseUpView)

    /// p01: tile presses from the rune-door close-up. Pressed tiles derive from the
    /// persisted in-progress sequence, so reopening the close-up restores them.
    func pressRuneTile(_ tile: Int) {
        guard let rune = RuneDoorSolution.tileRune[tile] else { return }
        SoundManager.shared.play(.click)
        switch PuzzleEngine.pressRuneTile(rune, state: state) {
        case .solved:
            SoundManager.shared.play(.unlock)
            activeCloseUp = nil // pull back so the opened door / new zone reads
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
    func selectAstrolabePlate(_ index: Int) {
        if PuzzleEngine.selectAstrolabePlate(index, state: state) {
            SoundManager.shared.play(.solve)
            activeCloseUp = .plain(image: "cu-astrolabe-drawer-empty") // drawer sprung; items granted
        } else {
            SoundManager.shared.play(.wrong)
        }
    }

    /// D5: advance the clock's hour hand one numeral. Reaching XII triggers the
    /// one-shot cuckoo pop (first time only; spent state thereafter).
    func advanceClockHour() {
        clockHour = clockHour % 12 + 1
        SoundManager.shared.play(.click)
        guard clockHour == 12 else { return }
        if PuzzleEngine.setClockToTwelve(state: state) == .popped {
            justPoppedClock = true
            SoundManager.shared.play(.clockClack)
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.8) { [weak self] in
                self?.justPoppedClock = false
            }
        }
        // Spent: door hangs ajar, toy inert — no sound beyond a faint creak (D5).
    }

    /// p14 brew resolve outcome, reported by BrewControlView inside the brew close-up.
    func brewOutcomeReported(_ outcome: PuzzleEngine.BrewOutcome) {
        lastBrewOutcome = outcome
    }

    // MARK: - Drop routing

    private func handleDrop(_ itemID: String, on hotspotID: String) {
        switch (viewID, hotspotID) {

        // -- z1 v-entry --
        case (.entry, "feed-cup"):
            // D4 (+ D1 for the draught specifically): ANY item offered here gets the
            // identical terminal refusal; item is returned to inventory unspent.
            guard !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) else { break }
            if itemID == PuzzleGraph.ItemID.phialDraught {
                PuzzleEngine.attemptPourDraughtAtFeedCup()
            } else {
                PuzzleEngine.triggerCrowTerminalRefusal()
            }
            showTerminalRefusal = true
            activeCloseUp = .refusal
            SoundManager.shared.play(.refusal)
        case (.entry, "star-keyhole"), (.entry, "cage"):
            entryCageDrop(itemID, on: hotspotID)
        case (.entry, "door-lock"):
            if itemID == PuzzleGraph.ItemID.phialDraught {
                if PuzzleEngine.pourDraughtOnBasin(state: state) {
                    SoundManager.shared.play(.solve)
                    activeCloseUp = .plain(image: "cu-door-lock-vines-gone") // wither beat
                }
            } else if itemID == PuzzleGraph.ItemID.rustedKey {
                // Red-herring fairness valve: visible mechanical reject.
                SoundManager.shared.play(.wrong)
                activeCloseUp = .plain(image: "cu-door-lock")
            }

        // -- z1 v-hearth --
        case (.hearth, "ash"):
            if itemID == PuzzleGraph.ItemID.poker {
                siftAshInteraction()
            }

        // -- z3 v-cellar --
        case (.cellar, "barrel"):
            if itemID == PuzzleGraph.ItemID.poker {
                let newly = !state.hasSolved(PuzzleGraph.PuzzleID.barrelPry)
                if PuzzleEngine.pryBarrel(state: state), newly {
                    SoundManager.shared.play(.solve)
                }
            }
        case (.cellar, "hook"):
            if itemID == PuzzleGraph.ItemID.weight {
                let newly = !state.hasSolved(PuzzleGraph.PuzzleID.shelfCounterweight)
                if PuzzleEngine.hangWeight(state: state), newly {
                    SoundManager.shared.play(.unlock)
                    playWeightHungBeat()
                }
            }
        case (.cellar, "winch"):
            if itemID == PuzzleGraph.ItemID.crank {
                let newly = !state.hasFlag(PuzzleGraph.StateFlag.moonbeamOn)
                if PuzzleEngine.fitCrankAndTurn(state: state), newly {
                    SoundManager.shared.play(.unlock)
                }
            }

        // -- z2 v-cabinet --
        case (.cabinet, "sun-slot"), (.cabinet, "moon-slot"):
            attemptCabinetPlacement(itemID, slot: hotspotID)

        // -- z2 v-bench --
        case (.bench, "mortar"):
            if itemID == PuzzleGraph.ItemID.blossom, PuzzleEngine.grindPaste(state: state) {
                SoundManager.shared.play(.solve)
                activeCloseUp = .plain(image: "cu-mortar-paste")
            }
        case (.bench, "cauldron"), (.bench, "ladle"):
            cauldronDrop(itemID)
        case (.bench, "workbench"):
            // p12 secondary path: the workbench close-up/top accepts the combination.
            if itemID == PuzzleGraph.ItemID.file || itemID == PuzzleGraph.ItemID.spoon {
                let other = itemID == PuzzleGraph.ItemID.file ? PuzzleGraph.ItemID.spoon : PuzzleGraph.ItemID.file
                let newly = !state.hasSolved(PuzzleGraph.PuzzleID.fileShavings)
                if ItemCombinations.combine(itemID, other, state: state), newly {
                    SoundManager.shared.play(.solve)
                }
            }

        default:
            break
        }
    }

    /// QA-BUG-018: dropping keys on the cage/star keyhole acts. The star key unlocks;
    /// the rusted key gets a visible mechanical reject at the keyhole close-up; any
    /// other item offered at the cage is a reach and gets the terminal refusal (D3).
    private func entryCageDrop(_ itemID: String, on hotspotID: String) {
        if itemID == PuzzleGraph.ItemID.cageKey, !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
            if PuzzleEngine.unlockCage(state: state) {
                SoundManager.shared.play(.solve)
                activeCloseUp = .plain(image: "cu-crow-rafters")
            }
        } else if itemID == PuzzleGraph.ItemID.rustedKey {
            SoundManager.shared.play(.wrong)
            activeCloseUp = .plain(image: "cu-star-keyhole") // plain bit visibly rejected by the star socket
        } else if !state.hasFlag(PuzzleGraph.StateFlag.crowFreed) {
            playTerminalRefusal()
        }
    }

    /// p14 ingredient adds + p15 bottling (QA-BUG-002) share the cauldron drop target.
    private func cauldronDrop(_ itemID: String) {
        if itemID == PuzzleGraph.ItemID.phial {
            if PuzzleEngine.fillPhial(state: state) {
                SoundManager.shared.play(.solve)
                activeCloseUp = .brew // show the (still-ready) draught being bottled
            } else {
                SoundManager.shared.play(.wrong) // cauldron isn't ready yet
            }
        } else {
            addCauldronIngredient(itemID)
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
    /// pops back audibly. Only the correct item seats (rendered by refreshCabinet);
    /// the pair completing hands over to the engine, which consumes both.
    private func attemptCabinetPlacement(_ itemID: String, slot: String) {
        guard !state.hasSolved(PuzzleGraph.PuzzleID.cabinetSunMoon) else { return }
        let correctItem = slot == "sun-slot" ? CabinetSolution.sunSlotItem : CabinetSolution.moonSlotItem
        guard itemID == correctItem, state.hasItem(itemID) else {
            SoundManager.shared.play(.wrong) // "item pops back out" (failure_behavior)
            return
        }
        if slot == "sun-slot" { pendingSunItem = itemID } else { pendingMoonItem = itemID }
        SoundManager.shared.play(.click)
        if PuzzleEngine.placeCabinetItems(sun: pendingSunItem, moon: pendingMoonItem, state: state) {
            SoundManager.shared.play(.solve)
            pendingSunItem = nil
            pendingMoonItem = nil
        }
        refreshCabinet()
    }

    private func addCauldronIngredient(_ itemID: String) {
        // Post-success adds are refused: the draught is done and ingredients must not
        // vanish into it (QA-BUG-006 companion guard).
        guard !state.hasFlag(PuzzleGraph.StateFlag.draughtReady) else { return }
        guard BrewSolution.requiredIngredients.contains(itemID), state.hasItem(itemID) else { return }
        var ingredients = state.data.cauldronIngredients
        ingredients.insert(itemID)
        state.removeItem(itemID)
        state.setCauldronIngredients(ingredients)
        SoundManager.shared.play(.pickup)
    }

    // MARK: - overlay rect lookup

    private func overlayRect(_ viewKey: String, _ overlayKey: String) -> CGRect {
        OverlayRectCatalog.shared.rect(view: viewKey, overlay: overlayKey) ?? .zero
    }
}
