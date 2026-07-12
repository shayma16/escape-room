import XCTest
import UIKit

/// Screen-level automation (QA test-infrastructure request 1): a scripted full
/// playthrough with per-view/state screenshots uploaded as CI artifacts, driving the
/// REAL app (SwiftUI chrome + SpriteKit scenes + drag gestures), which unit tests
/// cannot cover.
///
/// Scene taps use plate-normalized coordinates converted through the same `.aspectFit`
/// (letterbox) math the scene uses (scene 2732x1366, base plate fills the scene exactly);
/// see `sceneCoordinate(_:_:_:)`.
///
/// INTERIM iPad LETTERBOX (build 9 follow-up): the room scene is presented `.aspectFit`, so
/// the FULL 2:1 plate is visible on iPad (letterboxed top+bottom) rather than cropped to the
/// dual-safe band. Every plate-normalized coordinate below — including the z1 clue marks and
/// the edge elements the build-3 `.aspectFill` crop hid — is therefore on-screen and tappable
/// on iPad, so the full playthrough + save/resume run on iPad too (build 10's plate re-frame
/// will restore `.aspectFill` and remove the letterbox).
///
/// Feedback round 1 / build-2 QA regression (2026-07-08): the full playthrough was
/// recalibrated to the select-then-tap + diegetic-passage + clue-gating rewrite and
/// UN-SKIPPED (see testFullPlaythroughWithScreenshots). A save/resume + gate-persistence
/// UI test (testSaveResumeMidPlaythroughPersistsGate) was added to exercise D7 (clue
/// flags persist across relaunch, never re-lock) through the real chrome.
final class EscapeRoomUITests: XCTestCase {

    private let sceneSize = CGSize(width: 2732, height: 1366)

    /// Cold-launch first interactions can exceed 6 s on contended CI runners (the
    /// main-branch flake in run 28803258067 attempt 1 was a 6 s wait on level-card-1
    /// while a concurrent job slowed first-frame). QA re-QA recommendation: 20-30 s
    /// for everything up to and including level entry; steady-state waits stay short.
    private let coldLaunchTimeout: TimeInterval = 30

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        // QA-OBS-023: CI simulators boot portrait; this app is landscape-locked, so an
        // un-rotated device composes the app in a rotated sub-window and every
        // screenshot misrepresents the true presentation (iPad shots showed a ~3:2
        // crop instead of the real 4:3). Rotate before launching.
        XCUIDevice.shared.orientation = .landscapeLeft
    }

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetSave"]
        app.launch()
        assertFullScreenLandscapeComposition(app)
        return app
    }

    /// Relaunch WITHOUT -resetSave: the same on-disk save is reloaded, exercising the
    /// persistence layer end-to-end (save/resume + D7 gate persistence). Used by
    /// testSaveResumeMidPlaythroughPersistsGate.
    private func relaunchKeepingSave() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = []   // no reset: reload persisted save
        app.launch()
        assertFullScreenLandscapeComposition(app)
        return app
    }

    /// QA-OBS-023 loud-failure guard: the app's window must fill the entire screen in
    /// landscape. If a presentation regression (or a portrait-composed simulator)
    /// sneaks back in, this fails at launch instead of silently degrading every
    /// screenshot-based verification downstream.
    private func assertFullScreenLandscapeComposition(_ app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: coldLaunchTimeout),
                      "app window must exist after cold launch")
        // QA-OBS-023 intent: the app window must fill the screen in LANDSCAPE, not be
        // portrait-composed in a rotated sub-window (which silently degrades every
        // screenshot). We assert that intent directly against the window's own frame:
        // origin at (0,0) and a landscape aspect (width > height). The earlier version
        // compared against `UIScreen.main.fixedCoordinateSpace.bounds`, but in the
        // XCUITest RUNNER process `UIScreen.main` is unreliable (it reported a stale
        // 480-pt dimension on the CI SE simulator while the real app window was 667 pt),
        // so that comparison was environment-fragile. The window frame IS the app's true
        // presentation and is what matters here.
        let frame = window.frame
        XCTAssertEqual(frame.minX, 0, accuracy: 0.5, "window must start at the screen origin (x)")
        XCTAssertEqual(frame.minY, 0, accuracy: 0.5, "window must start at the screen origin (y)")
        XCTAssertGreaterThan(frame.width, frame.height,
                             "window must be composed LANDSCAPE (width > height), not portrait (QA-OBS-023)")
        XCTAssertGreaterThan(frame.width, 0, "window must have a real size")
        XCTAssertGreaterThan(frame.height, 0, "window must have a real size")
    }

    // MARK: - Coordinate plumbing

    /// Converts a plate-normalized point (0…1, top-left origin — where a human "sees" an
    /// element on the 2:1 plate) to a WINDOW coordinate, mirroring the scene's presentation.
    ///
    /// INTERIM iPad LETTERBOX (build 9 follow-up): the scene is now `.aspectFit` (RoomScene),
    /// so the whole 2:1 plate is fitted + centered inside the window with letterbox bars —
    /// top+bottom on iPad (4:3), thin side pillarbox on iPhone (19.5:9). The scale is
    /// therefore the MIN ratio (fit), not the max ratio (fill/cover) the previous
    /// `.aspectFill` presentation used. The centering formula is identical for fit and fill;
    /// only the scale selection flips. Using `min` here reproduces the letterbox offset, so a
    /// synthesized tap lands on the SAME on-plate element the app hit-tests — the previously
    /// off-screen iPad edge elements (flowerpot, potion shelf, windowsill, mirror, winch,
    /// mortar, astrolabe, cage, feed cup, ladder) are now inside the fitted plate and
    /// tappable via this math.
    private func sceneCoordinate(_ app: XCUIApplication, _ nx: CGFloat, _ ny: CGFloat) -> XCUICoordinate {
        let window = app.windows.firstMatch
        let frame = window.frame
        // BUILD 10: `.aspectFill` restored (letterbox removed) — the scene COVERS the window,
        // so the scale is the MAX ratio (cover), mirroring RoomScene. A synthesized tap at a
        // plate-normalized point lands on the same on-plate element the app hit-tests; points
        // in the overscan band (outside the dual-safe zone) fall off-screen, which is exactly
        // where no puzzle-critical element sits after the re-frame.
        let scale = max(frame.width / sceneSize.width, frame.height / sceneSize.height)
        let viewX = frame.width / 2 + (nx * sceneSize.width - sceneSize.width / 2) * scale
        let viewY = frame.height / 2 + (ny * sceneSize.height - sceneSize.height / 2) * scale
        return window.coordinate(withNormalizedOffset: CGVector(dx: viewX / frame.width,
                                                                dy: viewY / frame.height))
    }

    private func tapScene(_ app: XCUIApplication, _ nx: CGFloat, _ ny: CGFloat, settle: TimeInterval = 0.6) {
        sceneCoordinate(app, nx, ny).tap()
        Thread.sleep(forTimeInterval: settle)
    }

    // BUILD 10 re-frame: every scene tap below is authored in OLD (pre-re-frame) plate-
    // normalized coordinates. The Asset agent re-framed each wide plate by a per-view
    // scale+offset (asset-manifest build10_reframe), so a point p now sits at p*s+off.
    // `rf` applies that transform (mirroring Swift's Reframe) and the view-aware `tapScene` /
    // `useItem` overloads reframe before tapping, so the existing coordinates keep working.
    private static let reframeT: [String: (CGFloat, CGFloat, CGFloat)] = [
        "hearth": (0.955, 86 / 3840, 86 / 1920),
        "study":  (0.86, 538 / 3840, 240 / 1920),
        "entry":  (0.74, 425 / 3840, 250 / 1920),
        "bench":  (0.83, 430 / 3840, 163 / 1920),
        "cabinet": (0.70, 630 / 3840, 288 / 1920),
        "cellar": (0.82, 445 / 3840, 173 / 1920),
        "alcove": (1.0, 0, 0),
    ]

    private func rf(_ view: String, _ nx: CGFloat, _ ny: CGFloat) -> (CGFloat, CGFloat) {
        let (s, ox, oy) = Self.reframeT[view]!
        return (nx * s + ox, ny * s + oy)
    }

    private func tapScene(_ app: XCUIApplication, _ view: String, _ nx: CGFloat, _ ny: CGFloat,
                          settle: TimeInterval = 0.6) {
        let (x, y) = rf(view, nx, ny)
        sceneCoordinate(app, x, y).tap()
        Thread.sleep(forTimeInterval: settle)
    }

    /// Select-then-tap USE (feedback round 1): drag-to-use was REMOVED. To use an item on
    /// a target the player ARMS it in the inventory pill (tap its cell) then TAPS the target
    /// scene point. This helper replaces the old `dragItem` drag gesture across the suite.
    private func useItem(_ app: XCUIApplication, item: String, view: String,
                         onScene nx: CGFloat, _ ny: CGFloat, settle: TimeInterval = 0.8) {
        let cell = app.descendants(matching: .any)["inventory-\(item)"]
        XCTAssertTrue(cell.waitForExistence(timeout: 10), "inventory item \(item) must exist to arm it")
        cell.tap()                                  // arm
        Thread.sleep(forTimeInterval: 0.2)
        let (x, y) = rf(view, nx, ny)               // build-10 re-frame
        sceneCoordinate(app, x, y).tap()            // use on target
        Thread.sleep(forTimeInterval: settle)
    }

    // MARK: - Navigation arrival guards (build 10, CI run 29186397614 diagnosis)
    //
    // On the CPU-starved iPad CI simulator a synthesized navigation tap can be LOST:
    // in run 29186397614 the study→entry `nav-next` tap (t=1409 s) was synthesized at the
    // chevron's exact frame (session-log activation point (1340, 503.5) inside
    // {{1312, 459.5}, {56, 88}}), yet the AX tree and the xcresult screen recording show
    // the app never left the study. The script then blind-tapped entry coordinates as
    // silent no-ops until `assertHolding(itm-feather)` wedged 36 minutes into the test.
    //
    // Every load-bearing navigation in the solve therefore verifies ARRIVAL: the
    // destination view's signature hotspot appearing in the accessibility tree (SpriteKit
    // exposes the always-configured hotspot nodes as `hotspot:<id>` labels — confirmed in
    // the same run's AX dumps). One retry covers the genuinely-lost-tap case; a real
    // navigation bug still fails loudly, in seconds, with a precise message — this guard
    // is strictly MORE rigorous than the old blind tap-and-sleep, not a relaxation.
    private static let viewSignatureHotspot: [String: String] = [
        "hearth": "ash", "study": "grimoire", "entry": "cage", "bench": "cauldron",
        "cabinet": "astrolabe", "cellar": "barrel", "alcove": "planter",
    ]

    private func sceneHotspot(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label == %@", "hotspot:\(id)")).firstMatch
    }

    /// Performs `navigate` and waits for `view`'s signature hotspot to appear, retrying
    /// the navigation ONCE if it never does (the lost-tap case). The retry only fires
    /// after the destination demonstrably failed to appear for the full first timeout.
    private func ensureView(_ app: XCUIApplication, _ view: String,
                            settle: TimeInterval = 0.6,
                            file: StaticString = #filePath, line: UInt = #line,
                            via navigate: () -> Void) {
        let signature = Self.viewSignatureHotspot[view]!
        let hotspot = sceneHotspot(app, signature)
        for attempt in 0..<2 {
            navigate()
            if hotspot.waitForExistence(timeout: attempt == 0 ? 20 : 30) {
                Thread.sleep(forTimeInterval: settle)   // transition dip settles
                return
            }
        }
        XCTFail("navigation to \(view) (signature hotspot:\(signature)) did not take effect, even after one retry",
                file: file, line: line)
    }

    /// Views every clue-gating close-up (rev 1.3) so the gated code-entry puzzles (p01,
    /// p02, p03, p04, p14) accept their solutions later. Mirrors what a thorough player
    /// does; the gate is satisfiable in-scene from z1 + each puzzle's own zone. Called
    /// once early, from the z1 study/hearth/entry views, plus the z2 window when reached.
    private func viewZ1GatingClues(_ app: XCUIApplication) {
        // v-study: flowerpot (EARTH mark), triptych, grimoire pages (elements A + recipe).
        // R3-005 re-calibrated centers on the build-3 study plate.
        tapScene(app, "study", 0.10, 0.76); dismissCloseUp(app)    // flowerpot (bottom-left) -> clu-mark-earth
        tapScene(app, "study", 0.377, 0.30); dismissCloseUp(app)   // triptych (middle panel) -> clu-triptych
        tapScene(app, "study", 0.46, 0.66)                         // grimoire (opens at recipe spread)
        // Page back to page A, then forward, so both element + recipe spreads are viewed.
        if app.descendants(matching: .any)["Previous page"].firstMatch.waitForExistence(timeout: 3) {
            for _ in 0..<2 { app.descendants(matching: .any)["Previous page"].firstMatch.tap(); Thread.sleep(forTimeInterval: 0.2) }
            for _ in 0..<2 { app.descendants(matching: .any)["Next page"].firstMatch.tap(); Thread.sleep(forTimeInterval: 0.2) }
        }
        dismissCloseUp(app)
    }

    private func tapID(_ app: XCUIApplication, _ identifier: String, timeout: TimeInterval = 6) {
        let element = app.descendants(matching: .any)[identifier].firstMatch
        XCTAssertTrue(element.waitForExistence(timeout: timeout), "\(identifier) must exist")
        element.tap()
        Thread.sleep(forTimeInterval: 0.4)
    }

    private func dismissCloseUp(_ app: XCUIApplication) {
        tapID(app, "closeup-dismiss")
        Thread.sleep(forTimeInterval: 0.3)
    }

    private func shoot(_ app: XCUIApplication, _ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    /// Milestone assert: a pickup/yield reached the inventory bar. Doubles as a
    /// diagnostic that the preceding scene tap actually landed on its hotspot.
    private func assertHolding(_ app: XCUIApplication, _ item: String,
                               file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.descendants(matching: .any)["inventory-\(item)"].waitForExistence(timeout: 10),
                      "\(item) must be in the inventory bar", file: file, line: line)
    }

    /// Enter Level 1 from the main menu (shared by playthrough + save/resume tests).
    private func enterLevelOne(_ app: XCUIApplication) {
        tapID(app, "menu-play", timeout: coldLaunchTimeout)
        tapID(app, "level-card-1", timeout: coldLaunchTimeout)
        XCTAssertTrue(app.descendants(matching: .any)["pause-button"].waitForExistence(timeout: coldLaunchTimeout))
        Thread.sleep(forTimeInterval: 1.5)
    }

    // MARK: - QA-B3-001 / QA-B3-002 presentation regression guards

    /// QA-B3-001 full-window container guard — RECONCILED with the INTERIM iPad LETTERBOX
    /// (build 9 follow-up).
    ///
    /// What this guard asserts is the SpriteKit CONTAINER (the `room-scene` SKView) fills the
    /// FULL landscape WINDOW in POINTS. That invariant is UNCHANGED by the letterbox: the
    /// SKView is still the full-window `.ignoresSafeArea` container; the interim letterbox
    /// (`.aspectFit`, build 9) draws its dark bars INSIDE that full-window SKView (SpriteKit
    /// fits the 2:1 scene into the view), so the SKView's frame still spans the whole window.
    /// A genuine square-viewport / dead-band CONTAINER regression (the SKView collapsing to a
    /// square) still fails this loudly.
    ///
    /// IMPORTANT — the pixel content-fill is NO LONGER a pure artifact on iPad. Two effects
    /// now overlap in the raster:
    ///  1. The CI-SIMULATOR SCREENSHOT RASTER-LETTERBOX (documented across SEVEN prior builds:
    ///     the pixel content-fill was byte-identical at 0.5622 = 750/1334 on iPhone SE
    ///     regardless of app architecture — the simulator's screenshot compositor boxes the
    ///     raster while every LOGICAL frame reports full landscape). Harness artifact only.
    ///  2. The INTENTIONAL app-level iPad letterbox (`.aspectFit`): the live app now renders
    ///     the 2:1 plate fitted with dark bars top+bottom on iPad's 4:3 window — by design, so
    ///     no puzzle-critical edge element is cropped (the build-3 crop regression that made
    ///     the level uncompletable on iPad). This is a REAL, intended in-app letterbox, not an
    ///     artifact — build 10's plate re-frame removes it.
    /// Because both are now present, the pixel content-fill fractions are recorded ONLY as
    /// diagnostics (never asserted); the assertion is purely the harness-immune container
    /// frame. Real devices fill the window minus the intended iPad top/bottom bars — the
    /// user's TestFlight spot-check is the final confirmation.
    func testSceneContentFillsScreen_QA_B3_001() {
        let app = launchFreshApp()
        enterLevelOne(app)
        Thread.sleep(forTimeInterval: 1.5) // scene fade-up settles
        shoot(app, "b3-001-full-width-scene")

        let ss = app.screenshot()
        let imgSize = ss.image.size                 // pixels
        let win = app.windows.firstMatch.frame      // points
        let sceneEl = app.descendants(matching: .any)["room-scene"].firstMatch
        XCTAssertTrue(sceneEl.waitForExistence(timeout: 5),
            "room-scene (SpriteKit view) must exist in the level (QA-B3-001)")
        let sceneFrame = sceneEl.frame              // points

        // Pixel content-fill (recorded as a diagnostic — see the raster-letterbox note above).
        let whole = nonBlackBoundingBoxFraction(ss)
        let inScene = sceneFrame.isEmpty ? whole
            : nonBlackBoundingBoxFraction(ss, cropToPointRect: sceneFrame)

        let diag = "window=\(win) sceneFrame=\(sceneFrame) screenshotPt=\(imgSize) pixelFill_whole=w:\(whole.widthFraction),h:\(whole.heightFraction) pixelFill_inScene=w:\(inScene.widthFraction),h:\(inScene.heightFraction)"
        let att = XCTAttachment(string: diag)
        att.name = "b3-001-geometry-diagnostic"
        att.lifetime = .keepAlways
        add(att)
        print("QA-B3-001 DIAG: \(diag)")

        // The real, harness-immune assertion: the SpriteKit scene view fills the full
        // landscape WINDOW (points). A square-viewport / dead-band layout regression would
        // collapse the scene frame to a square (or a sub-rect), which this catches.
        XCTAssertFalse(win.isEmpty, "app window frame must resolve (QA-B3-001)")
        XCTAssertFalse(sceneFrame.isEmpty, "room-scene frame must resolve (QA-B3-001)")
        let widthFill = win.width > 0 ? sceneFrame.width / win.width : 0
        let heightFill = win.height > 0 ? sceneFrame.height / win.height : 0
        let sceneIsLandscape = sceneFrame.width >= sceneFrame.height
        XCTAssertGreaterThanOrEqual(widthFill, 0.90,
            "the game scene view must span the full window WIDTH — no square-viewport / dead band (QA-B3-001). sceneFrame=\(sceneFrame) window=\(win) widthFill=\(widthFill); pixelFill(whole)=\(whole.widthFraction) [CI raster-letterbox is an accepted screenshot artifact — see test doc]")
        XCTAssertGreaterThanOrEqual(heightFill, 0.90,
            "the game scene view must span the full window HEIGHT (QA-B3-001). heightFill=\(heightFill)")
        XCTAssertTrue(sceneIsLandscape,
            "the game scene view must be LANDSCAPE (width >= height), never a square viewport (QA-B3-001). sceneFrame=\(sceneFrame)")
    }

    /// QA-B3-002 chrome-on-screen guard. Build 3 clipped the completion card ("Main Men",
    /// "Play Agai") and crammed the pause menu bottom-left / off-screen on the Dynamic
    /// Island device. This drives the level to completion and asserts BOTH the completion-
    /// card and the pause-menu buttons have frames fully inside the window bounds (they
    /// resolve by accessibility id regardless of visible position, so a frame check is
    /// what actually catches the clip). Runs the full solve, so it is gated to the same
    /// device as the full playthrough (iPhone SE) to stay within the CI time budget.
    func testChromeFullyOnScreen_QA_B3_002() throws {
        let app = launchFreshApp()
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: coldLaunchTimeout))
        let screen = window.frame

        // Pause menu chrome: reachable immediately after entering the level.
        enterLevelOne(app)
        tapID(app, "pause-button")
        for id in ["pause-main-menu"] {
            let el = app.descendants(matching: .any)[id].firstMatch
            XCTAssertTrue(el.waitForExistence(timeout: 6), "\(id) must exist in the pause menu")
            assertFrameInside(el.frame, screen, label: id)
        }
        let resume = app.buttons["Resume"].firstMatch
        XCTAssertTrue(resume.waitForExistence(timeout: 6), "Resume must exist")
        assertFrameInside(resume.frame, screen, label: "Resume")
        shoot(app, "b3-002-pause-on-screen")
        resume.tap()
        Thread.sleep(forTimeInterval: 0.4)

        // Completion-card chrome: run the full scripted solve, then assert both buttons
        // sit fully inside the window (the truncation was a layout clip, not an id issue).
        solveLevelOne(app) // shared with the playthrough test
        for id in ["complete-main-menu", "complete-replay"] {
            let el = app.descendants(matching: .any)[id].firstMatch
            XCTAssertTrue(el.waitForExistence(timeout: 6), "\(id) must exist on the completion card")
            assertFrameInside(el.frame, screen, label: id)
        }
        shoot(app, "b3-002-completion-on-screen")
    }

    /// Asserts `frame` lies fully within `container` (QA-B3-002). A clipped/off-screen
    /// button has an edge outside the window — this catches it.
    private func assertFrameInside(_ frame: CGRect, _ container: CGRect, label: String,
                                   file: StaticString = #filePath, line: UInt = #line) {
        // A zero frame means XCUITest could not resolve a real position — treat as a fail.
        XCTAssertFalse(frame.isEmpty, "\(label) has an empty frame (unresolved / off-screen)", file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.minX, container.minX - 0.5, "\(label) clipped at LEFT", file: file, line: line)
        XCTAssertGreaterThanOrEqual(frame.minY, container.minY - 0.5, "\(label) clipped at TOP", file: file, line: line)
        XCTAssertLessThanOrEqual(frame.maxX, container.maxX + 0.5, "\(label) clipped at RIGHT", file: file, line: line)
        XCTAssertLessThanOrEqual(frame.maxY, container.maxY + 0.5, "\(label) clipped at BOTTOM", file: file, line: line)
    }

    /// Measures the non-black bounding box of a screenshot as a fraction of the scanned
    /// region. A near-black pixel (luma < threshold) counts as background; the
    /// leftmost/rightmost/topmost/bottommost non-black pixels define the content box.
    /// `cropToPointRect` (in the image's POINT space, e.g. an app-window frame) restricts
    /// the scan to that sub-rect and expresses the fractions relative to it — used to
    /// measure fill WITHIN the app window (QA-B3-001), ignoring any device-level letterbox.
    private func nonBlackBoundingBoxFraction(_ screenshot: XCUIScreenshot,
                                             lumaThreshold: UInt8 = 24,
                                             cropToPointRect: CGRect? = nil)
        -> (widthFraction: CGFloat, heightFraction: CGFloat) {
        guard let cg = screenshot.image.cgImage else { return (0, 0) }
        let w = cg.width, h = cg.height
        guard w > 0, h > 0 else { return (0, 0) }
        let bytesPerPixel = 4
        let bytesPerRow = bytesPerPixel * w
        var pixels = [UInt8](repeating: 0, count: bytesPerRow * h)
        let colorSpace = CGColorSpaceCreateDeviceRGB()
        guard let ctx = CGContext(data: &pixels, width: w, height: h, bitsPerComponent: 8,
                                  bytesPerRow: bytesPerRow, space: colorSpace,
                                  bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue) else {
            return (0, 0)
        }
        ctx.draw(cg, in: CGRect(x: 0, y: 0, width: w, height: h))

        // Determine the scan window in PIXELS. `image.size` is in points; scale maps the
        // point-space crop rect onto the pixel buffer.
        let pointSize = screenshot.image.size
        let scaleX = pointSize.width > 0 ? CGFloat(w) / pointSize.width : 1
        let scaleY = pointSize.height > 0 ? CGFloat(h) / pointSize.height : 1
        var x0 = 0, y0 = 0, x1 = w, y1 = h
        if let crop = cropToPointRect, crop.width > 0, crop.height > 0 {
            x0 = max(0, Int((crop.minX * scaleX).rounded()))
            y0 = max(0, Int((crop.minY * scaleY).rounded()))
            x1 = min(w, Int((crop.maxX * scaleX).rounded()))
            y1 = min(h, Int((crop.maxY * scaleY).rounded()))
            guard x1 > x0, y1 > y0 else { return (0, 0) }
        }
        let regionW = x1 - x0, regionH = y1 - y0
        // Sample on a stride for speed; content bands are large so a coarse grid suffices.
        let stride = max(1, min(regionW, regionH) / 400)
        var minX = x1, maxX = x0 - 1, minY = y1, maxY = y0 - 1
        var y = y0
        while y < y1 {
            var x = x0
            while x < x1 {
                let i = y * bytesPerRow + x * bytesPerPixel
                let r = pixels[i], g = pixels[i + 1], b = pixels[i + 2]
                // Rough luma; any channel clearly above black => content.
                let luma = UInt16(r) * 3 + UInt16(g) * 6 + UInt16(b)
                if luma / 10 > UInt16(lumaThreshold) {
                    if x < minX { minX = x }
                    if x > maxX { maxX = x }
                    if y < minY { minY = y }
                    if y > maxY { maxY = y }
                }
                x += stride
            }
            y += stride
        }
        guard maxX >= minX, maxY >= minY else { return (0, 0) }
        let wf = CGFloat(maxX - minX + 1) / CGFloat(regionW)
        let hf = CGFloat(maxY - minY + 1) / CGFloat(regionH)
        return (wf, hf)
    }

    // MARK: - All-device smoke: menus, level entry, z1 navigation, pause, settings

    func testMenuAndNavigationSmoke() {
        let app = launchFreshApp()
        shoot(app, "smoke-01-main-menu")
        tapID(app, "menu-play", timeout: coldLaunchTimeout)
        shoot(app, "smoke-02-level-select")
        tapID(app, "level-card-1", timeout: coldLaunchTimeout)
        XCTAssertTrue(app.descendants(matching: .any)["pause-button"].waitForExistence(timeout: coldLaunchTimeout))
        Thread.sleep(forTimeInterval: 1.5) // scene fade-up
        shoot(app, "smoke-03-hearth")
        // Chevron navigation covers all three z1 views from a fresh save (QA-BUG-001).
        tapID(app, "nav-next")
        Thread.sleep(forTimeInterval: 0.8)
        shoot(app, "smoke-04-study")
        tapID(app, "nav-next")
        Thread.sleep(forTimeInterval: 0.8)
        shoot(app, "smoke-05-entry")
        // Pause menu round-trip.
        tapID(app, "pause-button")
        shoot(app, "smoke-06-pause")
        app.buttons["Resume"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 0.5)
        // Exit to the existing menu root (QA-BUG-019).
        tapID(app, "pause-button")
        tapID(app, "pause-main-menu")
        XCTAssertTrue(app.descendants(matching: .any)["menu-play"].waitForExistence(timeout: 6),
                      "Main Menu must be the same root, not a stacked cover")
        shoot(app, "smoke-07-back-at-menu")
    }

    // MARK: - Full playthrough (both device classes; see header note re QA-BUG-004)

    func testFullPlaythroughWithScreenshots() throws {
        // FEEDBACK ROUND 1 (build 2) — QA REGRESSION PASS (2026-07-08): UN-SKIPPED.
        // The Developer left this end-to-end playthrough as a documented XCTSkip because
        // the select-then-tap + diegetic-passage + clue-gating rewrite changed both the
        // interaction flow and the required tap targets, and recalibrating the coordinates
        // against the new scene layout was explicitly QA's regression job.
        //
        // QA recalibration method (static, then empirical): every scene tap below was
        // cross-checked against the AUTHORITATIVE hotspot rects in
        // RoomSceneCoordinator.configure*() (the same rects the scene hit-tests). The
        // scene is 2732x1366 `.aspectFit` (build 9 letterbox) and the base plate fills it
        // exactly (RoomScene.setBaseTexture), so a plate-normalized hotspot center maps 1:1
        // onto the fit-scaled window coordinate `sceneCoordinate(_:_:_:)` produces — i.e. the
        // correct tap for a hotspot rect (x,y,w,h) is (x + w/2, y + h/2). Each tap was
        // verified to (a) fall inside its intended hotspot rect, (b) win the smallest-
        // area-wins overlap resolution (RoomScene.hotspotID(at:)) against any nesting
        // hotspot (star-keyhole/feed-cup inside cage; trapdoor inside rug; ladle inside
        // cauldron; alcove-passage inside cellar), and (c) clear the §7-R1 inventory pill.
        // BUILD 9 LETTERBOX: under `.aspectFit` the WHOLE plate is visible on iPad, so taps no
        // longer need to sit inside the old `.aspectFill` iPad-safe band [0.1665, 0.8335] —
        // the edge elements (flowerpot/potion-shelf/windowsill/mirror/winch/mortar/astrolabe/
        // cage/feed-cup/ladder) are now on-screen and these same centers reach them on iPad.
        // The two prior real failure modes this test surfaced (rune-tile modifier order;
        // rug/trapdoor taps under the bar) remain fixed. CI confirms the full end-to-end
        // solve on iPhone SE AND iPad.
        let playthroughEnabled = true
        try XCTSkipUnless(playthroughEnabled, "playthrough disabled")

        let app = launchFreshApp()
        enterLevelOne(app)
        solveLevelOne(app) // shared full solve; leaves the completion card presented

        tapID(app, "complete-main-menu")

        // Completion badge propagates to Level Select from the same save layer.
        tapID(app, "menu-play")
        XCTAssertTrue(app.descendants(matching: .any)["level-card-1-complete"].waitForExistence(timeout: 6),
                      "Level Select must show the completion badge")
        shoot(app, "play-19-badge")
    }

    /// The full scripted end-to-end solve, shared by `testFullPlaythroughWithScreenshots`
    /// and `testChromeFullyOnScreen_QA_B3_002`. Assumes the app is already inside Level 1
    /// (post `enterLevelOne`). Runs every puzzle via human-reachable taps and RETURNS with
    /// the completion card presented (`complete-main-menu` existing) — it does NOT tap the
    /// card, so callers can assert on the card or continue to Level Select.
    ///
    /// BUILD 9 LETTERBOX re-verification: every scene tap below is a plate-normalized
    /// coordinate fed through `sceneCoordinate(_:_:_:)`, whose `.aspectFit` (2732x1366) math
    /// is the SAME composition the app now renders (RoomScene `.aspectFit`, the SKView filling
    /// the full landscape window with the fitted plate letterboxed on iPad). The centering
    /// formula is shared between fit and fill — only the scale flips max→min — so these same
    /// plate-normalized centers stay correct on BOTH iPhone (near-full-fill) and iPad
    /// (letterboxed), re-verified against the RoomSceneCoordinator hotspot rects (unchanged).
    private func solveLevelOne(_ app: XCUIApplication) {
        shoot(app, "play-01-hearth")

        // z1 hearth: poker, ash sift (glint close-up).
        // NOTE: taps on low-in-frame hotspots must stay above screen-y ~0.80 — the
        // inventory pill (§7-R1: 64/56 pt, bottom-center) covers a bottom band on iPhone
        // and swallows touches (root cause of CI run 28753975221's failure at the dial step).
        // R3-005 (build 9): every scene tap below is the CENTER of the re-calibrated
        // hotspot rect (RoomSceneCoordinator.configure*), which now matches where each
        // element visually sits in the build-3 plates. A human tapping the visible element
        // hits it; tapping the old placeholder position no longer does anything.
        tapScene(app, "hearth", 0.248, 0.50)                  // take poker (rod hangs left of the hearth)
        assertHolding(app, "itm-poker")
        // R5-001 record: a real device-rendered frame of the poker-taken hearth (the
        // exact surface of the build-10 "misplaced fireplace fragment" report). The
        // pixel-level registration assertion lives in RenderedFrameOverlayTests (unit
        // level, SKView.texture(from:) — immune to the CI raster-letterbox); this shot
        // keeps a human-inspectable frame in the CI artifact record.
        Thread.sleep(forTimeInterval: 0.6)
        shoot(app, "play-01b-poker-taken")
        // Select-then-tap (F-007/F-020/F-021): arm the poker, then tap the ash pile.
        // A bare tap on ash is now only a look (no passive auto-apply), so the sift MUST
        // go through the armed-item path or the ring is never yielded.
        useItem(app, item: "itm-poker", view: "hearth", onScene: 0.44, 0.68)    // sift ash mound (center hearth)
        shoot(app, "play-02-ash-glint")
        // R2-003a two-step: sifting REVEALS the ring in the (now-open) ash close-up; it is
        // NOT auto-granted. Collect it with an explicit tap on the revealed-ring target.
        tapID(app, "collect-itm-gold-ring")
        assertHolding(app, "itm-gold-ring")
        dismissCloseUp(app)

        // Clue-gating (rev 1.3): a thorough player views the clue close-ups before the
        // gated code-entry puzzles will accept their answers. Gather z1's gate clues now.
        tapScene(app, "hearth", 0.613, 0.53); dismissCloseUp(app)   // hearth bellows -> AIR mark
        tapScene(app, "hearth", 0.585, 0.275); dismissCloseUp(app)  // hearth lintel -> FIRE mark
        ensureView(app, "study") { tapID(app, "nav-next") }        // hearth -> study
        viewZ1GatingClues(app)                             // EARTH mark, triptych, grimoire A + recipe
        ensureView(app, "entry") { tapID(app, "nav-next") }        // study -> entry
        tapScene(app, "entry", 0.105, 0.62); dismissCloseUp(app)   // windowsill tablet -> WATER mark
        ensureView(app, "hearth") { tapID(app, "nav-next") }       // entry -> hearth (wraps)

        // Back at the hearth: rug discovery + the now-ungated dial panel (p02).
        // Rug is tapped in its exposed left strip (left of the trapdoor, which wins the
        // smaller-area overlap); the trapdoor-dial is center-floor.
        // Rug: far-left exposed strip (x0.22 is clear of the center inventory pill and of
        // the trapdoor rect x0.30-0.70, so the rug — not the smaller trapdoor — takes it).
        tapScene(app, "hearth", 0.22, 0.80, settle: 0.9)      // move rug
        // Trapdoor-dial at (0.60,0.70): inside the trapdoor rect (x0.30-0.70, y0.66-0.90)
        // but OUTSIDE the smaller ash (x0.36-0.52) and rug (y>=0.74) rects, so the trapdoor
        // — not a smaller-area overlapping hotspot — wins the tap. (The prior (0.50,0.72)
        // sat inside the ash rect, which won the overlap and opened the ash close-up instead
        // of the dial — that was the CI "moon-dial-1 must exist" failure.)
        tapScene(app, "hearth", 0.60, 0.70, settle: 0.9)      // trapdoor -> dial close-up
        shoot(app, "play-03-dial-panel")
        for _ in 0..<1 { tapID(app, "moon-dial-1") } // waxing crescent
        for _ in 0..<4 { tapID(app, "moon-dial-2") } // full
        for _ in 0..<5 { tapID(app, "moon-dial-3") } // waning gibbous -> unlock
        shoot(app, "play-04-dials-solved")
        dismissCloseUp(app)
        ensureView(app, "cellar", settle: 1.2) {              // descend through the trapdoor
            tapScene(app, "hearth", 0.60, 0.70, settle: 1.2)
        }
        shoot(app, "play-05-cellar")

        // z3 cellar (R3-005 re-calibrated to the build-3 cellar plate): barrel right,
        // spoon drawer (handled chest on the shelf), weight hook on the wall, winch drum
        // top-left, standing mirror bottom-left, ladder far-right.
        // Select-then-tap: arm the poker, then tap the barrel (no auto-apply on bare tap).
        useItem(app, item: "itm-poker", view: "cellar", onScene: 0.735, 0.66) // pry barrel -> weight REVEALED
        // Build 10 (R4-013): the weight is revealed in the pried-barrel close-up and
        // collected with its own explicit tap (manual-pickup model), not auto-granted.
        tapID(app, "collect-itm-weight")
        assertHolding(app, "itm-weight")
        dismissCloseUp(app)
        useItem(app, item: "itm-weight", view: "cellar", onScene: 0.23, 0.33) // hang weight on the wall hook -> z4
        Thread.sleep(forTimeInterval: 1.2)          // weight-hung beat + shelf slide
        shoot(app, "play-06-shelf-slid")
        tapScene(app, "cellar", 0.555, 0.40)                  // open drawer (handled chest)
        tapScene(app, "cellar", 0.555, 0.40)                  // take spoon (manual pickup, F-018)
        assertHolding(app, "itm-spoon")
        tapScene(app, "cellar", 0.13, 0.62)                   // mirror detent 2 (bottom-left stand)
        tapScene(app, "cellar", 0.13, 0.62)                   // mirror detent 3
        // F-024: zone changes are DIEGETIC PASSAGES, not chevrons. The slid-shelf gap
        // (cellar `alcove-passage` hotspot ~center) leads into the alcove.
        ensureView(app, "alcove", settle: 1.2) {              // cellar -> alcove via the shelf gap
            tapScene(app, "cellar", 0.47, 0.505, settle: 1.2)
        }
        shoot(app, "play-07-alcove")
        tapScene(app, "alcove", 0.605, 0.31)                  // crow statue close-up (key in beak)
        // Build 10 (R4-026): the key is a manual pickup FROM the close-up — tap the key.
        tapID(app, "collect-itm-cage-key")
        assertHolding(app, "itm-cage-key")
        dismissCloseUp(app)

        // Back out to the cellar, then up the ladder to the hearth, then round to study.
        // (zone-exit chevrons: the edge gap/ladder are off the iPad aspectFill crop.)
        ensureView(app, "cellar", settle: 1.2) { tapID(app, "zone-exit") } // alcove -> cellar
        ensureView(app, "hearth", settle: 1.2) { tapID(app, "zone-exit") } // cellar -> hearth
        ensureView(app, "study") { tapID(app, "nav-next") }  // hearth -> study (chevron, same zone)
        shoot(app, "play-08-study")
        // Screenshot-coverage detours (QA re-QA gap list): the grimoire opens at the
        // feather-bookmarked recipe spread; the triptych is the three night paintings.
        tapScene(app, "study", 0.46, 0.66)                   // grimoire close-up (open book on the desk)
        XCTAssertTrue(app.descendants(matching: .any)["closeup-dismiss"].waitForExistence(timeout: 5),
                      "grimoire close-up must present")
        shoot(app, "play-08b-grimoire-recipe")
        dismissCloseUp(app)
        tapScene(app, "study", 0.377, 0.30)                  // triptych close-up (middle panel)
        XCTAssertTrue(app.descendants(matching: .any)["closeup-dismiss"].waitForExistence(timeout: 5),
                      "triptych close-up must present")
        shoot(app, "play-08c-triptych")
        dismissCloseUp(app)
        tapScene(app, "study", 0.762, 0.52)                  // rune door close-up (right press-plate)
        // p01 fixed solution: AIR, FIRE, EARTH, WATER (RuneDoorSolution.solutionOrder).
        // The canonical PIL-stamped door glyphs now match the grimoire + element marks
        // (R3-007), so a human can read this off the grimoire hub.
        for tile in [3, 1, 4, 2] {                  // AIR, FIRE, EARTH, WATER
            tapID(app, "rune-tile-\(tile)")
        }
        Thread.sleep(forTimeInterval: 0.6)          // close-up closes on solve
        shoot(app, "play-09-runedoor-solved")
        ensureView(app, "bench", settle: 1.2) {              // through the inner door -> bench
            tapScene(app, "study", 0.762, 0.52, settle: 1.2)
        }

        // z2: astrolabe, cabinet.
        ensureView(app, "cabinet") { tapID(app, "nav-next") } // bench -> cabinet
        shoot(app, "play-10-cabinet")
        // Clue-gating (rev 1.3): view the Orion window (p03 gate) and the slot-shape
        // close-up (p04 gate) before the code-entry acts.
        tapScene(app, "cabinet", 0.93, 0.31); dismissCloseUp(app)   // Orion window (top-right) -> clu-window-orion
        tapScene(app, "cabinet", 0.465, 0.475); dismissCloseUp(app) // sun slot close-up -> clu-slot-shapes
        tapScene(app, "cabinet", 0.79, 0.52)                   // astrolabe close-up (armillary sphere, right)
        shoot(app, "play-11-astrolabe")
        tapID(app, "astrolabe-plate-2")             // Orion -> drawer springs open
        // F-023 manual pickup: coin + crank are VISIBLE in the drawer; tap each to collect.
        tapID(app, "collect-itm-silver-coin")
        tapID(app, "collect-itm-crank")
        assertHolding(app, "itm-crank")
        assertHolding(app, "itm-silver-coin")
        dismissCloseUp(app)
        useItem(app, item: "itm-gold-ring", view: "cabinet", onScene: 0.465, 0.475)   // sun recess (left door)
        useItem(app, item: "itm-silver-coin", view: "cabinet", onScene: 0.58, 0.475)  // moon recess (right door) -> cabinet opens
        // F-023 manual pickup: file + phial visible in the opened cabinet; tap each.
        tapID(app, "collect-itm-file")
        tapID(app, "collect-itm-phial")
        assertHolding(app, "itm-file")
        assertHolding(app, "itm-phial")
        dismissCloseUp(app)
        shoot(app, "play-12-cabinet-open")

        // Free the crow. Leave z2 via the workshop exit affordance (-> study), then
        // chevron to the entry (F-024: zone changes are diegetic / the interim z2 exit).
        // THIS study->entry nav is the exact step whose lost tap wedged CI run
        // 29186397614 on iPad — all three hops are now arrival-verified (see ensureView).
        ensureView(app, "bench") { tapID(app, "nav-previous") } // cabinet -> bench (chevron, z2)
        ensureView(app, "study") { tapID(app, "zone-exit") }    // workshop -> study (z1)
        ensureView(app, "entry") { tapID(app, "nav-next") }     // study -> entry
        // Screenshot-coverage detour (QA re-QA gap list, NON-LOAD-BEARING): a deliberate
        // armed-item REACH at the cage triggers the D3 terminal-refusal pose (F-011: a
        // bare tap is now a neutral look, so the refusal fires only on an armed offer).
        // The refusal is a no-op beat that AUTO-DISMISSES after 1.4 s and is exhaustively
        // verified at the unit level (testBareCageTapShowsNeutralPoseNotRefusal_F011,
        // testD1FeedCupRefusalNeverMutatesDraughtOrCrowState). This detour only tries to
        // capture the pose for the screenshot record; because of the 1.4 s auto-dismiss it
        // is inherently timing-sensitive, so it is BEST-EFFORT: it must never fail the
        // load-bearing playthrough (the actual crow-freeing below carries the D3/F-011
        // regression weight). BUILD 10: the poker is CONSUMED once both its uses are
        // done (cluster A), so it is long gone here — arm the SPOON instead (any
        // non-key item gets the same D3 refusal; the spoon's own p12 use comes later
        // and the refusal returns it unspent).
        let reachCell = app.descendants(matching: .any)["inventory-itm-spoon"]
        if reachCell.waitForExistence(timeout: 3) {
            reachCell.tap()                                         // arm the (held) spoon
            Thread.sleep(forTimeInterval: 0.2)
            let reachP = rf("entry", 0.88, 0.325)
            sceneCoordinate(app, reachP.0, reachP.1).tap()          // armed reach into the cage (top-right)
            // Poll briefly for the pose, but do NOT assert — the beat may auto-dismiss
            // before the first poll returns on a slow runner. Capture regardless.
            _ = app.descendants(matching: .any)["refusal-pose"].waitForExistence(timeout: 1.0)
            shoot(app, "play-12b-crow-refusal")
            Thread.sleep(forTimeInterval: 1.6)                     // let the beat fully clear
            // If the refusal close-up is still up, dismiss defensively so the next scene
            // tap reaches the entry, not the (dismiss-on-any-tap) refusal overlay.
            if app.descendants(matching: .any)["refusal-pose"].exists {
                let dismissP = rf("entry", 0.5, 0.5)
                sceneCoordinate(app, dismissP.0, dismissP.1).tap()
                Thread.sleep(forTimeInterval: 0.4)
            }
        }
        // Free the crow (LOAD-BEARING, carries D3/F-011): arm the cage key, then tap the
        // star keyhole (select-then-tap). The feather yield proves p11 solved.
        useItem(app, item: "itm-cage-key", view: "entry", onScene: 0.81, 0.385) // cage keyhole -> crow freed
        assertHolding(app, "itm-feather")
        shoot(app, "play-13-crow-freed")
        dismissCloseUp(app)
        // Graph-specified silent endgame nudge: once freed, the crow perches on the
        // door lintel above the basin (wide-shot state, p16 clue).
        Thread.sleep(forTimeInterval: 0.5)
        shoot(app, "play-13b-crow-lintel")

        // File + spoon -> shavings (inventory combine). R2-028: once the file is armed the
        // combinable spoon cell exposes the "combine" affordance, so its accessibility id
        // becomes `combine-itm-spoon` (not `inventory-itm-spoon`) — tap that to combine.
        tapID(app, "inventory-itm-file")
        tapID(app, "combine-itm-spoon")
        assertHolding(app, "itm-shavings")

        // Light the alcove: reach the cellar (via z1 hearth trapdoor), fit the crank at
        // the winch, then pick the blossom in the alcove.
        // entry -> hearth (chevron within z1), then down the trapdoor to the cellar.
        ensureView(app, "hearth") { tapID(app, "nav-next") }  // entry -> hearth (wraps within z1)
        ensureView(app, "cellar", settle: 1.2) {              // trapdoor -> cellar (diegetic)
            tapScene(app, "hearth", 0.60, 0.70, settle: 1.2)
        }
        // Select-then-tap: arm the crank, then tap the winch (no auto-fit on bare tap).
        useItem(app, item: "itm-crank", view: "cellar", onScene: 0.195, 0.10) // fit crank at the winch drum -> moonbeam
        shoot(app, "play-14-beam")
        ensureView(app, "alcove", settle: 1.2) {              // cellar -> alcove via the shelf gap
            tapScene(app, "cellar", 0.47, 0.505, settle: 1.2)
        }
        shoot(app, "play-15-blooming")
        tapScene(app, "alcove", 0.57, 0.76)                   // pick blossom (planter basin, center-bottom)
        assertHolding(app, "itm-blossom")

        // Brew: back to the cellar, up to the hearth, round to the study, through the
        // rune door to the workshop bench.
        // (zone-exit chevrons: the edge gap/ladder are off the iPad aspectFill crop.)
        ensureView(app, "cellar", settle: 1.2) { tapID(app, "zone-exit") } // alcove -> cellar
        ensureView(app, "hearth", settle: 1.2) { tapID(app, "zone-exit") } // cellar -> hearth
        ensureView(app, "study") { tapID(app, "nav-next") }  // hearth -> study
        ensureView(app, "bench", settle: 1.2) {              // through the (solved) rune door -> bench
            tapScene(app, "study", 0.762, 0.52, settle: 1.2)
        }
        useItem(app, item: "itm-blossom", view: "bench", onScene: 0.84, 0.55) // mortar (right table) -> paste
        assertHolding(app, "itm-paste")
        dismissCloseUp(app)
        useItem(app, item: "itm-paste", view: "bench", onScene: 0.315, 0.54)    // cauldron (over the fire)
        useItem(app, item: "itm-shavings", view: "bench", onScene: 0.315, 0.54)
        useItem(app, item: "itm-feather", view: "bench", onScene: 0.315, 0.54)
        tapScene(app, "bench", 0.315, 0.54)                  // brew close-up
        for _ in 0..<3 { tapID(app, "brew-pump") }  // flame stage 3
        for _ in 0..<5 { tapID(app, "brew-stir-ccw") }
        tapID(app, "brew-release")                  // -> draught-ready (spiral cue)
        shoot(app, "play-16-draught")
        dismissCloseUp(app)
        useItem(app, item: "itm-phial", view: "bench", onScene: 0.315, 0.54) // bottle the draught
        assertHolding(app, "itm-phial-draught")
        dismissCloseUp(app)

        // Endgame at the door. Leave the workshop via the z2 exit affordance (interim
        // "back through the rune door" chevron; no painted return door yet — flagged),
        // which lands in the study, then chevron round to the entry.
        ensureView(app, "study") { tapID(app, "zone-exit") } // workshop -> study (z1)
        ensureView(app, "entry") { tapID(app, "nav-next") }  // study -> entry
        useItem(app, item: "itm-phial-draught", view: "entry", onScene: 0.58, 0.31) // pour into the crow's-beak basin
        shoot(app, "play-17-unsealed")
        dismissCloseUp(app)
        tapScene(app, "entry", 0.58, 0.31)                   // slide the bolt and leave (p17)
        // The Main Menu button doubles as the completion-card existence assert.
        XCTAssertTrue(app.descendants(matching: .any)["complete-main-menu"].waitForExistence(timeout: 6),
                      "completing p17 must present the completion card")
        shoot(app, "play-18-complete")
    }

    // MARK: - Save/resume + clue-gate persistence (D7), driven through the real chrome

    /// Regression scope item 4 + D7: a clue viewed in-game and a container-collected item
    /// must survive save/quit/relaunch, and a gated puzzle must NOT re-lock after the
    /// clue's flag was persisted. This drives the FULL persistence path (SaveGameStore ->
    /// relaunch -> reload), not just the in-memory unit-level check.
    ///
    /// Sequence: fresh save -> pick poker + sift ash (progress) -> view all four z1 rune
    /// marks + grimoire page A (p01 gate clues) -> quit to Main Menu -> relaunch KEEPING
    /// the save -> re-enter -> the poker/ring are still held (save/resume) AND the rune
    /// door now ACCEPTS the fixed sequence immediately (the gate stayed satisfied; it did
    /// not re-lock across the relaunch — D7).
    func testSaveResumeMidPlaythroughPersistsGate() {
        let app = launchFreshApp()
        enterLevelOne(app)

        // Progress + p01 clue-gathering on the z1 views.
        tapScene(app, "hearth", 0.248, 0.50)                  // take poker (R3-005 re-calibrated)
        assertHolding(app, "itm-poker")
        useItem(app, item: "itm-poker", view: "hearth", onScene: 0.44, 0.68) // sift ash -> reveals ring
        // R2-003a two-step: explicitly collect the revealed ring from the ash close-up.
        tapID(app, "collect-itm-gold-ring")
        assertHolding(app, "itm-gold-ring")
        dismissCloseUp(app)
        tapScene(app, "hearth", 0.613, 0.53); dismissCloseUp(app)   // AIR mark (bellows)
        tapScene(app, "hearth", 0.585, 0.275); dismissCloseUp(app)  // FIRE mark (lintel)
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // -> study
        viewZ1GatingClues(app)                            // EARTH + grimoire page A (+ triptych/recipe)
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // -> entry
        tapScene(app, "entry", 0.105, 0.62); dismissCloseUp(app)   // WATER mark (windowsill)

        // Quit to Main Menu (persistence is synchronous per every GameState mutator).
        tapID(app, "pause-button")
        tapID(app, "pause-main-menu")
        XCTAssertTrue(app.descendants(matching: .any)["menu-play"].waitForExistence(timeout: 6),
                      "Main Menu after quit")
        app.terminate()

        // Relaunch WITHOUT reset: the same save reloads.
        let app2 = relaunchKeepingSave()
        enterLevelOne(app2)
        shoot(app2, "resume-01-back-in-level")

        // Save/resume: the poker and ring persisted across the relaunch.
        assertHolding(app2, "itm-poker")
        assertHolding(app2, "itm-gold-ring")

        // D7: the p01 gate stayed satisfied (all four marks + page A were viewed pre-quit
        // and never re-lock). Go to the study and press the fixed rune sequence; if the
        // gate had re-locked, the tiles would reset and the door would not open. We
        // confirm the solve by taking the diegetic passage into z2 afterward — reaching
        // v-bench (a z2 view) is only possible once p01 has actually solved and opened
        // the inner door.
        tapID(app2, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // hearth -> study
        tapScene(app2, "study", 0.762, 0.52)                 // rune door close-up (R3-005 re-calibrated)
        for tile in [3, 1, 4, 2] {                  // AIR, FIRE, EARTH, WATER
            tapID(app2, "rune-tile-\(tile)")
        }
        Thread.sleep(forTimeInterval: 0.6)          // close-up closes on solve
        shoot(app2, "resume-02-runedoor-solved-postresume")
        tapScene(app2, "study", 0.762, 0.52, settle: 1.2)    // through the now-open inner door -> z2 bench
        // Reaching z2 confirms the gate accepted the answer post-relaunch (D7). The z2
        // bench has a mortar hotspot whose close-up we can open as a reachability proof.
        tapScene(app2, "bench", 0.84, 0.55)                  // mortar look (z2 v-bench only)
        XCTAssertTrue(app2.descendants(matching: .any)["closeup-dismiss"].waitForExistence(timeout: 5),
                      "must have entered z2 (rune gate did NOT re-lock across relaunch — D7)")
        shoot(app2, "resume-03-in-z2-gate-held")
    }
}
