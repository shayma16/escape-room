import SwiftUI

/// The close-up / inspection layer (QA-BUG-013): presents a `CloseUpRequest` over the
/// SpriteKit room. Leaving is always the style guide Section 7 down-chevron (plus tap-
/// anywhere for the auto-dismissing refusal beat).
///
/// Feedback round 1:
/// - The inventory bar stays visible/reachable BELOW this layer (F-020 systemic fix);
///   `bottomInset` keeps close-up content clear of it.
/// - An armed inventory item used on the plate routes to the close-up's originating
///   hotspot (`useArmedItemInCloseUp`), so tool-on-hotspot puzzles work from inside
///   their close-ups.
/// - Solved containers present their contents for tap-to-collect (F-023/F-018).
/// - Dismiss chevron visibility raised (F-025 interim; final per the Section 7 Rev-2
///   addendum when it lands).
/// - Page turns play a paper cue; opening/dismissing close-ups is silent (F-005).
struct CloseUpView: View {
    @ObservedObject var coordinator: RoomSceneCoordinator
    let request: CloseUpRequest
    var bottomInset: CGFloat = 0
    @Environment(\.horizontalSizeClass) private var hSizeClass

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()
                .onTapGesture { armedUseOrNothing() }

            Group {
                switch request {
                case .plain(let image):
                    FittedPlate(imageName: image)
                        .contentShape(Rectangle())
                        .onTapGesture { armedUseOrNothing() }
                case .container(let container):
                    ContainerCloseUp(coordinator: coordinator, container: container)
                case .ashPile:
                    AshPileCloseUp(coordinator: coordinator)
                case .grimoire:
                    PagerCloseUp(coordinator: coordinator,
                                 pages: CloseUpLayout.grimoirePages,
                                 initialIndex: CloseUpLayout.grimoireBookmarkIndex)
                case .triptych(let panel):
                    PagerCloseUp(coordinator: coordinator,
                                 pages: CloseUpLayout.triptychPages,
                                 initialIndex: min(max(panel, 0), CloseUpLayout.triptychPages.count - 1))
                case .clock:
                    ClockCloseUp(coordinator: coordinator)
                case .dialPanel:
                    DialPanelCloseUp(coordinator: coordinator)
                case .astrolabe:
                    AstrolabeCloseUp(coordinator: coordinator)
                case .runeDoor:
                    RuneDoorCloseUp(coordinator: coordinator)
                case .brew:
                    BrewCloseUp(coordinator: coordinator)
                case .refusal:
                    RefusalCloseUp(coordinator: coordinator)
                }
            }
            .padding(.bottom, bottomInset)

            if request != .refusal {
                VStack {
                    Spacer()
                    dismissChevron
                        .padding(.bottom, bottomInset + 10)
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if request == .refusal { dismiss() }
        }
    }

    /// A tap on the plate with an item armed = use it here (routed to the close-up's
    /// originating hotspot). Without an armed item, plate taps do nothing — silence
    /// over generic noise (F-005).
    private func armedUseOrNothing() {
        coordinator.useArmedItemInCloseUp()
    }

    /// §7-R2.4 close-up back affordance: bone-white down-chevron on a soft radial backing
    /// that plays one entrance accent on appear (the "you can leave this way" beat F-025
    /// missed), then joins the breathing pulse.
    private var dismissChevron: some View {
        NavChevron.dismissButton(action: dismiss, isPad: hSizeClass == .regular)
    }

    private func dismiss() {
        // Silent: leaving a close-up needs no cue (F-005 — silence over generic).
        coordinator.dismissCloseUp()
    }
}

// MARK: - Shared fitted-plate helpers

/// Aspect-fit presentation of a close-up plate, exposing the fitted rect so
/// interactive children can be positioned in plate-normalized coordinates.
private struct FittedPlateLayout<Content: View>: View {
    let imageName: String
    var plateAspect: CGFloat = 2048.0 / 1536.0
    @ViewBuilder var content: (CGRect) -> Content

    var body: some View {
        GeometryReader { geo in
            let fitted = Self.fitRect(in: geo.size, aspect: plateAspect)
            ZStack(alignment: .topLeading) {
                GameImage(name: imageName)
                    .aspectRatio(contentMode: .fit)
                    .frame(width: fitted.width, height: fitted.height)
                    .position(x: fitted.midX, y: fitted.midY)
                content(fitted)
            }
        }
    }

    static func fitRect(in size: CGSize, aspect: CGFloat) -> CGRect {
        guard size.width > 0, size.height > 0 else { return .zero }
        let containerAspect = size.width / size.height
        if containerAspect > aspect {
            let h = size.height, w = h * aspect
            return CGRect(x: (size.width - w) / 2, y: 0, width: w, height: h)
        } else {
            let w = size.width, h = w / aspect
            return CGRect(x: 0, y: (size.height - h) / 2, width: w, height: h)
        }
    }
}

private struct FittedPlate: View {
    let imageName: String
    var body: some View {
        FittedPlateLayout(imageName: imageName) { _ in EmptyView() }
            .padding(24)
    }
}

private extension CGRect {
    /// Maps a plate-normalized sub-rect into this (fitted, view-space) rect.
    func subRect(_ normalized: CGRect) -> CGRect {
        CGRect(x: minX + normalized.minX * width,
               y: minY + normalized.minY * height,
               width: normalized.width * width,
               height: normalized.height * height)
    }
}

// MARK: - Solved-container manual pickup (F-023/F-018)

/// Shows the opened container with its remaining contents; the player taps each item
/// to collect it (with the liked pickup chime). Already-collected items are hidden
/// under a soft dark patch (both containers have dark interiors, so absence reads
/// naturally — flagged in implementation notes: per-item removal art doesn't exist).
/// Once everything is collected the empty-container plate renders instead.
private struct ContainerCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator
    let container: PuzzleEngine.Container

    var body: some View {
        let plates = CloseUpLayout.containerPlates(container)
        let uncollected = PuzzleEngine.uncollectedItems(in: container, state: coordinator.state)
        if uncollected.isEmpty {
            FittedPlate(imageName: plates.empty)
        } else {
            FittedPlateLayout(imageName: plates.open) { fitted in
                ForEach(PuzzleEngine.containerContents(container), id: \.self) { itemID in
                    if let normalized = CloseUpLayout.containerItemRects[container]?[itemID] {
                        let rect = fitted.subRect(normalized)
                        if uncollected.contains(itemID) {
                            // Invisible tap target over the painted item (>= 44 pt floor).
                            Color.white.opacity(0.001)
                                .frame(width: max(rect.width, 44), height: max(rect.height, 44))
                                .contentShape(Rectangle())
                                .onTapGesture {
                                    coordinator.collectContainerItem(itemID, from: container)
                                }
                                .accessibilityLabel(ItemCatalog.definition(for: itemID)?.name ?? "Item")
                                .accessibilityIdentifier("collect-\(itemID)")
                                .position(x: rect.midX, y: rect.midY)
                        } else {
                            // Collected while its sibling remains: soft dark patch so
                            // the taken item no longer appears present (F-007 class).
                            RadialGradient(colors: [Color.black.opacity(0.88), Color.black.opacity(0)],
                                           center: .center,
                                           startRadius: 0,
                                           endRadius: max(rect.width, rect.height) * 0.72)
                                .frame(width: rect.width * 1.5, height: rect.height * 1.7)
                                .allowsHitTesting(false)
                                .position(x: rect.midX, y: rect.midY)
                        }
                    }
                }
            }
            .padding(24)
        }
    }
}

// MARK: - Ash pile manual ring pickup (R2-003a)

/// The hearth ash close-up. State-resolved plate; when the ring has been sifted up but
/// not yet taken, an invisible tap target over the visible ring collects it (the liked
/// pickup chime), after which the cleared-ash plate renders. Also honors armed-item use
/// (the poker) so sifting works from inside the close-up (F-020).
private struct AshPileCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        let ringVisible = PuzzleEngine.isRingUncollectedInAsh(coordinator.state)
        FittedPlateLayout(imageName: RoomVisuals.ashCloseUp(coordinator.state)) { fitted in
            if ringVisible {
                let rect = fitted.subRect(CloseUpLayout.ashRingRect)
                Color.white.opacity(0.001)
                    .frame(width: max(rect.width, 44), height: max(rect.height, 44))
                    .contentShape(Rectangle())
                    .onTapGesture { coordinator.collectAshRing() }
                    .accessibilityLabel(ItemCatalog.definition(for: PuzzleGraph.ItemID.goldRing)?.name ?? "Ring")
                    .accessibilityIdentifier("collect-\(PuzzleGraph.ItemID.goldRing)")
                    .position(x: rect.midX, y: rect.midY)
            }
        }
        // Armed poker used on the plate sifts the ash (routes to the "ash" hotspot).
        .contentShape(Rectangle())
        .onTapGesture { coordinator.useArmedItemInCloseUp() }
        .padding(24)
    }
}

// MARK: - Browsable spreads (grimoire, triptych)

private struct PagerCloseUp: View {
    let coordinator: RoomSceneCoordinator
    let pages: [String]
    @State var index: Int

    init(coordinator: RoomSceneCoordinator, pages: [String], initialIndex: Int) {
        self.coordinator = coordinator
        self.pages = pages
        _index = State(initialValue: initialIndex)
    }

    var body: some View {
        ZStack {
            FittedPlate(imageName: pages[index])
            HStack {
                pageChevron("chevron.left", enabled: index > 0) { index -= 1 }
                Spacer()
                pageChevron("chevron.right", enabled: index < pages.count - 1) { index += 1 }
            }
            .padding(.horizontal, 6)
        }
        // R2-008: swipe to flip pages (arrows STAY). Navigation swipe only — no item drag.
        .contentShape(Rectangle())
        .gesture(
            DragGesture(minimumDistance: 24)
                .onEnded { value in
                    let dx = value.translation.width
                    guard abs(dx) > 50, abs(dx) > abs(value.translation.height) else { return }
                    if dx < 0, index < pages.count - 1 {
                        SoundManager.shared.play(.page); index += 1
                    } else if dx > 0, index > 0 {
                        SoundManager.shared.play(.page); index -= 1
                    }
                }
        )
        .onAppear { recordPage() }
        .onChange(of: index) { _ in recordPage() }
    }

    /// Per-page clue recording (F-012 substrate): the gate table can key on
    /// individual spreads (e.g. the grimoire recipe page), not just the book.
    private func recordPage() {
        coordinator.recordClueViewed("plain-\(pages[index])")
    }

    private func pageChevron(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.play(.page) // paper, not the generic click (F-005)
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 26, weight: .medium))
                .foregroundColor(Color(white: 0.92).opacity(enabled ? 0.85 : 0.15))
                .frame(width: 44, height: 88)
                .background(Capsule().fill(Color.black.opacity(enabled ? 0.35 : 0)))
        }
        .disabled(!enabled)
        .accessibilityLabel(symbol == "chevron.left" ? "Previous page" : "Next page")
    }
}

// MARK: - Clock (D5)

private struct ClockCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        FittedPlateLayout(imageName: RoomVisuals.clockState(coordinator.state)) { fitted in
            let center = CGPoint(x: fitted.minX + CloseUpLayout.clockFaceCenter.x * fitted.width,
                                 y: fitted.minY + CloseUpLayout.clockFaceCenter.y * fitted.height)
            let radius = CloseUpLayout.clockFaceRadius * fitted.width
            // Movable hour hand (sprite points at XII unrotated; 30 deg per numeral).
            Image("clock-hand-hour")
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: radius * 1.7, height: radius * 1.7)
                .rotationEffect(.degrees(Double(coordinator.clockHour % 12) * 30))
                .position(center)
                .allowsHitTesting(false)
            // Tap surface over the whole face advances the hands one numeral.
            // (Interactive modifiers before .position — see RuneDoorCloseUp note.)
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: radius * 2.2, height: radius * 2.2)
                .contentShape(Circle())
                .onTapGesture { coordinator.advanceClockHour() }
                .accessibilityLabel("Clock hands")
                .accessibilityIdentifier("clock-face")
                .position(center)
        }
        .padding(24)
    }
}

// MARK: - Trapdoor dial panel (p02; QA-BUG-010/-011)

private struct DialPanelCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        GeometryReader { geo in
            // Section 8 / A5-R5 legibility floor (QA-BUG-011): each dial face spans
            // >= 30% of screen width on the smallest iPhone.
            let dialSize = geo.size.width * 0.30
            ZStack {
                GameImage(name: "cu-dial-panel")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.35)
                MoonDialRowView(state: coordinator.state, dialSize: dialSize)
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
            }
        }
        .ignoresSafeArea()
    }
}

// MARK: - Astrolabe six-plate mini-game (p03; QA-BUG-005)

private struct AstrolabeCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        GeometryReader { geo in
            let plateSize = min(geo.size.width / 3.6, geo.size.height / 2.9)
            ZStack {
                GameImage(name: "cu-astrolabe")
                    .aspectRatio(contentMode: .fill)
                    .frame(width: geo.size.width, height: geo.size.height)
                    .clipped()
                    .opacity(0.30)
                VStack(spacing: plateSize * 0.14) {
                    ForEach(0..<2, id: \.self) { row in
                        HStack(spacing: plateSize * 0.14) {
                            ForEach(1...3, id: \.self) { col in
                                plateButton(row * 3 + col, size: plateSize)
                            }
                        }
                    }
                }
            }
        }
        .ignoresSafeArea()
    }

    private func plateButton(_ index: Int, size: CGFloat) -> some View {
        Button {
            coordinator.selectAstrolabePlate(index)
        } label: {
            GameImage(name: "astrolabe-plate-\(index)")
                .aspectRatio(contentMode: .fit)
                .frame(width: size, height: size)
        }
        .frame(minWidth: 44, minHeight: 44)
        .accessibilityLabel("Star plate \(index)")
        .accessibilityIdentifier("astrolabe-plate-\(index)")
    }
}

// MARK: - Rune door tiles (p01)

private struct RuneDoorCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        FittedPlateLayout(imageName: "cu-runedoor-tiles") { fitted in
            ForEach(1...4, id: \.self) { tile in
                let rect = fitted.subRect(CloseUpLayout.runeTileRects[tile] ?? .zero)
                // NOTE: interactive/accessibility modifiers must come BEFORE
                // .position() — .position wraps the view in a full-container frame,
                // so anything applied after it covers the entire close-up. The old
                // order made the topmost tile swallow every tap and reported a huge
                // un-hittable frame to XCUITest (CI run 28768853014).
                ZStack {
                    if coordinator.pressedRuneTiles.contains(tile) {
                        GameImage(name: "runedoor-tile\(tile)-pressed")
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.white.opacity(0.001)
                    }
                }
                .frame(width: rect.width, height: rect.height)
                .contentShape(Rectangle())
                .onTapGesture { coordinator.pressRuneTile(tile) }
                .accessibilityLabel("Rune tile \(tile)")
                .accessibilityIdentifier("rune-tile-\(tile)")
                .position(x: rect.midX, y: rect.midY)
            }
        }
        .padding(24)
    }
}

// MARK: - Brew view (p14/p15; QA-BUG-016 liquid states + R3 affordance)

private struct BrewCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator
    @State private var rippleDirection: BrewSolution.StirDirection?

    var body: some View {
        HStack(spacing: 0) {
            FittedPlateLayout(imageName: RoomVisuals.cauldronLiquidState(coordinator.state,
                                                                          lastBrewOutcome: coordinator.lastBrewOutcome)) { fitted in
                // Exactly one rim rune's ember channel is lit at the current stage
                // (colorblind_safety: stage never encoded by flame color alone).
                let stage = coordinator.state.data.cauldronFlameStage
                if stage >= 1, stage <= 3, let rect = CloseUpLayout.brewEmberRects[stage] {
                    let r = fitted.subRect(rect)
                    GameImage(name: "rune-ember-\(["I", "II", "III"][stage - 1])")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: r.width, height: r.height)
                        .position(x: r.midX, y: r.midY)
                        .allowsHitTesting(false)
                }
                // R3: the stir gesture leaves a directional ripple trail; the CCW
                // sprite is mirrored horizontally for CW, so handedness is unmistakable.
                if let direction = rippleDirection {
                    GameImage(name: "ladle-ripple-ccw")
                        .aspectRatio(contentMode: .fit)
                        .frame(width: fitted.width * 0.45)
                        .scaleEffect(x: direction == .counterclockwise ? 1 : -1, y: 1)
                        .position(x: fitted.midX, y: fitted.midY)
                        .allowsHitTesting(false)
                        .transition(.opacity)
                }
            }
            // Armed-item taps on the liquid add ingredients / bottle the draught
            // without leaving the brew view (select-then-tap inside close-ups).
            .contentShape(Rectangle())
            .onTapGesture { coordinator.useArmedItemInCloseUp() }
            .padding(.vertical, 24)
            .padding(.leading, 24)

            BrewControlView(state: coordinator.state,
                            onOutcome: { coordinator.brewOutcomeReported($0) },
                            onStir: { direction in
                                withAnimation(.easeIn(duration: 0.1)) { rippleDirection = direction }
                                DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
                                    withAnimation(.easeOut(duration: 0.3)) { rippleDirection = nil }
                                }
                            })
                .frame(maxWidth: 340)
        }
    }
}

// MARK: - Terminal refusal beat (D3/D4; QA-BUG-016)

private struct RefusalCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        FittedPlate(imageName: "cu-cage-crow-refusal")
            .onAppear {
                // Identical, short, non-escalating beat every repeat; auto-dismisses.
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.4) {
                    if coordinator.activeCloseUp == .refusal {
                        coordinator.dismissCloseUp()
                    }
                }
            }
            .accessibilityIdentifier("refusal-pose")
    }
}
