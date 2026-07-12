import Foundation
import CoreGraphics

/// The close-up / inspection layer (QA-BUG-013). A `CloseUpRequest` is emitted by
/// `RoomSceneCoordinator` when a tap should zoom into a `cu-*` plate; `CloseUpView`
/// (SwiftUI) presents it over the SpriteKit room with the style guide Section 7
/// down-chevron for leaving. Interactive close-ups (dial panel, astrolabe ring, rune
/// tiles, clock hands, brew view) drive the puzzle engine through the coordinator so
/// all state logic stays in one place.
enum CloseUpRequest: Equatable, Identifiable {
    /// A plain zoom-in on a single (state-resolved) plate.
    case plain(image: String)
    /// A solved container with individually collectable contents (feedback round 1
    /// F-023/F-018 manual pickup): astrolabe base drawer, sun/moon cabinet.
    case container(PuzzleEngine.Container)
    /// The hearth ash pile (R2-003a): undisturbed / sifted-with-ring (tap to collect) /
    /// cleared. A state-resolved plate plus a tap-to-collect ring target when revealed.
    case ashPile
    /// The cellar barrel (build 10, R4-013): nailed-shut look / pried-with-weight
    /// (tap to collect) — the same manual-pickup grammar as the ash pile.
    case barrel
    /// The alcove crow statue (build 10, R4-026): key-in-beak (tap the key to collect)
    /// / key-taken. Manual pickup from the close-up, per the R2-020 lifecycle model.
    case statueKey
    /// The sun/moon cabinet slot recesses (build 10, R4-020(1)): a state-aware view
    /// that renders each correctly-seated item IN its recess (per-slot positive visual
    /// feedback), replacing the static cu-slots-empty plain zoom.
    case cabinetSlots
    /// Grimoire: browsable spreads, opens at the feather-bookmarked recipe page.
    case grimoire
    /// Triptych: the three night paintings, browsable, opened at the tapped panel
    /// (R2-007 — each panel maps to its own close-up).
    case triptych(panel: Int)
    /// Mantel clock: movable hands, purely the p01 numeral-ring reference. The D5 cuckoo
    /// one-shot was REMOVED (Q3, user decision 2026-07-08) — advancing is cosmetic only.
    case clock
    /// Trapdoor three-dial moon-phase lock (interactive; A5/R5 legibility floor).
    case dialPanel
    /// Astrolabe six-plate selection mini-game (p03).
    case astrolabe
    /// Workshop rune-door press-plate with the four pressable tiles (p01).
    case runeDoor
    /// Cauldron brew view (R3 camera): liquid states + flame/stir controls (p14).
    case brew
    /// The crow's terminal-refusal pose (D3/D4) — auto-dismissing beat, identical
    /// every repeat.
    case refusal

    var id: String {
        switch self {
        case .plain(let image): return "plain-\(image)"
        case .container(let container): return "container-\(container.rawValue)"
        case .ashPile: return "ash-pile"
        case .barrel: return "barrel"
        case .statueKey: return "statue-key"
        case .cabinetSlots: return "cabinet-slots"
        case .grimoire: return "grimoire"
        case .triptych: return "triptych"  // shared clue id across panels (F-012 gate)
        case .clock: return "clock"
        case .dialPanel: return "dial-panel"
        case .astrolabe: return "astrolabe"
        case .runeDoor: return "rune-door"
        case .brew: return "brew"
        case .refusal: return "refusal"
        }
    }
}

/// Static layout data for interactive close-ups, all in coordinates normalized to
/// their 2048x1536 close-up plates. Sourced from the asset pipeline's sprite-metadata
/// JSONs (single source of truth; values are transcribed here because they are fixed
/// per-plate constants, cross-checked in unit tests against the bundled JSON).
enum CloseUpLayout {
    /// Rune-door tile rects within cu-runedoor-tiles (from sprites/runedoor-tiles.json,
    /// rect_in_plate_3x over 2048x1536). Tile order is display order top-to-bottom.
    static let runeTileRects: [Int: CGRect] = [
        1: CGRect(x: 902.0 / 2048, y: 170.0 / 1536, width: 242.0 / 2048, height: 251.0 / 1536),
        2: CGRect(x: 902.0 / 2048, y: 473.0 / 1536, width: 242.0 / 2048, height: 251.0 / 1536),
        3: CGRect(x: 902.0 / 2048, y: 776.0 / 1536, width: 242.0 / 2048, height: 251.0 / 1536),
        4: CGRect(x: 902.0 / 2048, y: 1079.0 / 1536, width: 242.0 / 2048, height: 251.0 / 1536),
    ]

    /// Rim-rune ember overlay positions on the cu-brew-* plates (from
    /// sprites/rune-ember-rects.json — paste_xy_3x/size_3x over 2048x1536).
    /// Build 11 gapfill: the ember sprites were REBUILT from the build-3 cu-brew-clear
    /// plaques and their positions MOVED vs the build-1 sprites (per-numeral sizes now
    /// differ too). Values re-transcribed; cross-checked against the bundled JSON by
    /// RenderedFrameOverlayTests.testBrewEmberRectsMatchBundledSpriteJSON.
    static let brewEmberRects: [Int: CGRect] = [
        1: CGRect(x: 624.0 / 2048, y: 161.0 / 1536, width: 279.0 / 2048, height: 293.0 / 1536),
        2: CGRect(x: 1190.0 / 2048, y: 169.0 / 1536, width: 306.0 / 2048, height: 303.0 / 1536),
        3: CGRect(x: 1543.0 / 2048, y: 473.0 / 1536, width: 255.0 / 2048, height: 326.0 / 1536),
    ]

    /// Clock face center / radius within the cu-clock-* plates (visually measured;
    /// used to pivot the movable hand sprites).
    static let clockFaceCenter = CGPoint(x: 0.508, y: 0.618)
    static let clockFaceRadius: CGFloat = 0.245 // fraction of plate WIDTH

    /// The grimoire's browsable spreads, in page order. The feather bookmark opens the
    /// book at the recipe page (index 2).
    static let grimoirePages = ["cu-grimoire-pageA", "cu-grimoire-pageB", "cu-grimoire-recipe",
                                 "cu-grimoire-zodiac", "cu-grimoire-bird"]
    static let grimoireBookmarkIndex = 2

    static let triptychPages = ["cu-triptych-1", "cu-triptych-2", "cu-triptych-3"]

    /// The revealed ring's tap target within the cu-ash-sifted plate (R2-003a), measured
    /// against the shipped art: the ring sits between the rake furrows, lower-center.
    static let ashRingRect = CGRect(x: 0.40, y: 0.52, width: 0.20, height: 0.20)

    /// Build 10 (R4-013): the revealed weight's position within the cu-barrel-gap plate
    /// — centered in the dark pry gap between the loosened lid planks (measured against
    /// the shipped art: gap spans x 0.42–0.64, y 0.37–0.64). Until the phase-2 art pass
    /// delivers a dedicated pried-with-weight close-up plate, the weight renders as its
    /// RGBA icon cutout seated in the gap (flagged in implementation notes).
    static let barrelWeightRect = CGRect(x: 0.455, y: 0.40, width: 0.15, height: 0.20)

    /// Build 10 (R4-026): the star-bit key hanging from the statue's beak within the
    /// cu-statue-key plate (key + star bow + hanging ring, measured against the art).
    static let statueKeyRect = CGRect(x: 0.13, y: 0.09, width: 0.16, height: 0.52)

    /// Build 10 (R4-020(1)): the sun / crescent recesses within the cu-slots-empty
    /// plate (measured against the art: sun recess centered ~(0.31,0.60), moon recess
    /// ~(0.76,0.59)). Seated items render as their RGBA icon cutouts inside these.
    static let slotSeatRects: [SlotID: CGRect] = [
        .sun: CGRect(x: 0.235, y: 0.475, width: 0.15, height: 0.25),
        .moon: CGRect(x: 0.685, y: 0.465, width: 0.15, height: 0.25),
    ]

    enum SlotID { case sun, moon }

    // MARK: Container close-ups (manual pickup, feedback round 1)

    /// Plate shown while any content is uncollected / once everything is taken. The
    /// astrolabe has a dedicated inpainted empty close-up; the cabinet has no dedicated
    /// empty CLOSE-UP plate (build-3 gap G3: ov-cab-open-empty is only a cropped WIDE
    /// overlay, not a full close-up), so a fully-collected cabinet just re-shows the open
    /// plate — correct because ContainerCloseUp renders no tap targets once everything is
    /// collected, and the WIDE view already carries the emptied state.
    static func containerPlates(_ container: PuzzleEngine.Container) -> (open: String, empty: String) {
        switch container {
        case .astrolabeDrawer: return ("cu-astrolabe-drawer-open", "cu-astrolabe-drawer-empty")
        case .sunMoonCabinet: return ("cu-cabinet-open", "cu-cabinet-open")
        }
    }

    /// Collectable-item regions, normalized to the container's OPEN plate (measured
    /// against the shipped art). Rendered as invisible tap targets (>= 44 pt enforced
    /// by the view) with a soft dark patch over already-collected items (both
    /// containers have dark interiors, so absence reads naturally).
    static let containerItemRects: [PuzzleEngine.Container: [String: CGRect]] = [
        .astrolabeDrawer: [
            PuzzleGraph.ItemID.silverCoin: CGRect(x: 0.315, y: 0.765, width: 0.145, height: 0.115),
            PuzzleGraph.ItemID.crank: CGRect(x: 0.455, y: 0.755, width: 0.255, height: 0.145),
        ],
        .sunMoonCabinet: [
            PuzzleGraph.ItemID.file: CGRect(x: 0.29, y: 0.50, width: 0.29, height: 0.125),
            PuzzleGraph.ItemID.phial: CGRect(x: 0.55, y: 0.335, width: 0.125, height: 0.29),
        ],
    ]
}
