import SwiftUI

/// The close-up / inspection layer (QA-BUG-013): presents a `CloseUpRequest` over the
/// SpriteKit room. Leaving is always the style guide Section 7 down-chevron (plus tap-
/// anywhere for the auto-dismissing refusal beat). Interactive close-ups drive puzzle
/// logic exclusively through the coordinator.
struct CloseUpView: View {
    @ObservedObject var coordinator: RoomSceneCoordinator
    let request: CloseUpRequest

    var body: some View {
        ZStack {
            Color.black.opacity(0.92).ignoresSafeArea()

            switch request {
            case .plain(let image):
                FittedPlate(imageName: image)
            case .grimoire:
                PagerCloseUp(pages: CloseUpLayout.grimoirePages,
                             initialIndex: CloseUpLayout.grimoireBookmarkIndex)
            case .triptych:
                PagerCloseUp(pages: CloseUpLayout.triptychPages, initialIndex: 0)
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

            if request != .refusal {
                VStack {
                    Spacer()
                    dismissChevron
                }
            }
        }
        .contentShape(Rectangle())
        .onTapGesture {
            if request == .refusal { dismiss() }
        }
    }

    private var dismissChevron: some View {
        Button(action: dismiss) {
            Image(systemName: "chevron.down")
                .font(.system(size: 30, weight: .regular))
                .foregroundColor(Color(white: 0.92).opacity(0.55))
                .frame(width: 64, height: 44)
        }
        .padding(.bottom, 10)
        .accessibilityLabel("Back")
        .accessibilityIdentifier("closeup-dismiss")
    }

    private func dismiss() {
        SoundManager.shared.play(.click)
        coordinator.activeCloseUp = nil
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

// MARK: - Browsable spreads (grimoire, triptych)

private struct PagerCloseUp: View {
    let pages: [String]
    @State var index: Int

    init(pages: [String], initialIndex: Int) {
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
    }

    private func pageChevron(_ symbol: String, enabled: Bool, action: @escaping () -> Void) -> some View {
        Button {
            SoundManager.shared.play(.click)
            action()
        } label: {
            Image(systemName: symbol)
                .font(.system(size: 26))
                .foregroundColor(Color(white: 0.92).opacity(enabled ? 0.55 : 0.12))
                .frame(width: 44, height: 88)
        }
        .disabled(!enabled)
        .accessibilityLabel(symbol == "chevron.left" ? "Previous page" : "Next page")
    }
}

// MARK: - Clock (D5)

private struct ClockCloseUp: View {
    @ObservedObject var coordinator: RoomSceneCoordinator

    var body: some View {
        FittedPlateLayout(imageName: RoomVisuals.clockState(coordinator.state, justPopped: coordinator.justPoppedClock)) { fitted in
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
            Circle()
                .fill(Color.white.opacity(0.001))
                .frame(width: radius * 2.2, height: radius * 2.2)
                .position(center)
                .onTapGesture { coordinator.advanceClockHour() }
                .accessibilityLabel("Clock hands")
                .accessibilityIdentifier("clock-face")
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
            // >= 30% of screen width on the smallest iPhone. Sized from the actual
            // container width, so it holds on every device.
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
                ZStack {
                    if coordinator.pressedRuneTiles.contains(tile) {
                        GameImage(name: "runedoor-tile\(tile)-pressed")
                            .aspectRatio(contentMode: .fill)
                    } else {
                        Color.white.opacity(0.001)
                    }
                }
                .frame(width: rect.width, height: rect.height)
                .position(x: rect.midX, y: rect.midY)
                .contentShape(Rectangle())
                .onTapGesture { coordinator.pressRuneTile(tile) }
                .accessibilityLabel("Rune tile \(tile)")
                .accessibilityIdentifier("rune-tile-\(tile)")
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
                        coordinator.activeCloseUp = nil
                    }
                }
            }
            .accessibilityIdentifier("refusal-pose")
    }
}
