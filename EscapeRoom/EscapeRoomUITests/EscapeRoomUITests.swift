import XCTest
import UIKit

/// Screen-level automation (QA test-infrastructure request 1): a scripted full
/// playthrough with per-view/state screenshots uploaded as CI artifacts, driving the
/// REAL app (SwiftUI chrome + SpriteKit scenes + drag gestures), which unit tests
/// cannot cover.
///
/// Scene taps use plate-normalized coordinates converted through the same .aspectFill
/// math the scene uses (scene 2732x1366, base plate fills the scene exactly).
///
/// BUG-004 art integration (2026-07-06): the re-framed plates put every puzzle-
/// critical element inside the dual-safe zone, so the full playthrough now runs on
/// iPad too (coordinates below sit inside the iPad-visible band x in [0.167, 0.833]).
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

    /// QA-OBS-023 loud-failure guard: the app's window must fill the entire screen in
    /// landscape. If a presentation regression (or a portrait-composed simulator)
    /// sneaks back in, this fails at launch instead of silently degrading every
    /// screenshot-based verification downstream.
    private func assertFullScreenLandscapeComposition(_ app: XCUIApplication) {
        let window = app.windows.firstMatch
        XCTAssertTrue(window.waitForExistence(timeout: coldLaunchTimeout),
                      "app window must exist after cold launch")
        let fixed = UIScreen.main.fixedCoordinateSpace.bounds // portrait-fixed device bounds, pt
        let expected = CGSize(width: max(fixed.width, fixed.height),
                              height: min(fixed.width, fixed.height))
        let frame = window.frame
        XCTAssertEqual(frame.minX, 0, accuracy: 0.5, "window must start at the screen origin (x)")
        XCTAssertEqual(frame.minY, 0, accuracy: 0.5, "window must start at the screen origin (y)")
        XCTAssertEqual(frame.width, expected.width, accuracy: 1.0,
                       "window width must equal the landscape screen width (QA-OBS-023)")
        XCTAssertEqual(frame.height, expected.height, accuracy: 1.0,
                       "window height must equal the landscape screen height (QA-OBS-023)")
    }

    // MARK: - Coordinate plumbing

    /// Converts a plate-normalized point to a window coordinate under .aspectFill.
    private func sceneCoordinate(_ app: XCUIApplication, _ nx: CGFloat, _ ny: CGFloat) -> XCUICoordinate {
        let window = app.windows.firstMatch
        let frame = window.frame
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

    /// Select-then-tap USE (feedback round 1): drag-to-use was REMOVED. To use an item on
    /// a target the player ARMS it in the inventory pill (tap its cell) then TAPS the target
    /// scene point. This helper replaces the old `dragItem` drag gesture across the suite.
    private func useItem(_ app: XCUIApplication, item: String, onScene nx: CGFloat, _ ny: CGFloat,
                         settle: TimeInterval = 0.8) {
        let cell = app.descendants(matching: .any)["inventory-\(item)"]
        XCTAssertTrue(cell.waitForExistence(timeout: 5), "inventory item \(item) must exist to arm it")
        cell.tap()                                  // arm
        Thread.sleep(forTimeInterval: 0.2)
        sceneCoordinate(app, nx, ny).tap()          // use on target
        Thread.sleep(forTimeInterval: settle)
    }

    /// Views every clue-gating close-up (rev 1.3) so the gated code-entry puzzles (p01,
    /// p02, p03, p04, p14) accept their solutions later. Mirrors what a thorough player
    /// does; the gate is satisfiable in-scene from z1 + each puzzle's own zone. Called
    /// once early, from the z1 study/hearth/entry views, plus the z2 window when reached.
    private func viewZ1GatingClues(_ app: XCUIApplication) {
        // v-study: flowerpot (EARTH mark), triptych, grimoire pages (elements A + recipe).
        tapScene(app, 0.635, 0.53); dismissCloseUp(app)   // flowerpot -> clu-mark-earth
        tapScene(app, 0.475, 0.17); dismissCloseUp(app)   // triptych -> clu-triptych
        tapScene(app, 0.485, 0.55)                        // grimoire (opens at recipe spread)
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
        XCTAssertTrue(app.descendants(matching: .any)["inventory-\(item)"].waitForExistence(timeout: 5),
                      "\(item) must be in the inventory bar", file: file, line: line)
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

    // MARK: - Full playthrough (iPhone-class; see header note re QA-BUG-004)

    func testFullPlaythroughWithScreenshots() throws {
        let app = launchFreshApp()
        tapID(app, "menu-play", timeout: coldLaunchTimeout)
        tapID(app, "level-card-1", timeout: coldLaunchTimeout)
        XCTAssertTrue(app.descendants(matching: .any)["pause-button"].waitForExistence(timeout: coldLaunchTimeout))
        Thread.sleep(forTimeInterval: 1.5)
        shoot(app, "play-01-hearth")

        // z1 hearth: poker, ash sift (glint close-up).
        // NOTE: taps on low-in-frame hotspots must stay above screen-y ~0.80 — the
        // inventory pill (§7-R1: 64/56 pt, bottom-center) covers a bottom band on iPhone
        // and swallows touches (root cause of CI run 28753975221's failure at the dial step).
        tapScene(app, 0.235, 0.685)                 // take poker
        assertHolding(app, "itm-poker")
        tapScene(app, 0.325, 0.650)                 // sift ash -> glint close-up
        assertHolding(app, "itm-gold-ring")
        shoot(app, "play-02-ash-glint")
        dismissCloseUp(app)

        // Clue-gating (rev 1.3): a thorough player views the clue close-ups before the
        // gated code-entry puzzles will accept their answers. Gather z1's gate clues now.
        tapScene(app, 0.615, 0.40); dismissCloseUp(app)   // hearth bellows -> AIR mark
        tapScene(app, 0.30, 0.28); dismissCloseUp(app)    // hearth lintel -> FIRE mark
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // hearth -> study
        viewZ1GatingClues(app)                             // EARTH mark, triptych, grimoire A + recipe
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // study -> entry
        tapScene(app, 0.20, 0.55); dismissCloseUp(app)    // windowsill -> WATER mark
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // entry -> hearth (wraps)

        // Back at the hearth: rug discovery + the now-ungated dial panel (p02).
        tapScene(app, 0.18, 0.76)                   // move rug (upper rug edge, clear of the bar + iPad band)
        tapScene(app, 0.42, 0.76)                   // trapdoor -> dial close-up
        shoot(app, "play-03-dial-panel")
        for _ in 0..<1 { tapID(app, "moon-dial-1") } // waxing crescent
        for _ in 0..<4 { tapID(app, "moon-dial-2") } // full
        for _ in 0..<5 { tapID(app, "moon-dial-3") } // waning gibbous -> unlock
        shoot(app, "play-04-dials-solved")
        dismissCloseUp(app)
        tapScene(app, 0.42, 0.76, settle: 1.2)      // descend through the trapdoor
        shoot(app, "play-05-cellar")

        // z3 cellar: barrel pry, counterweight, spoon, mirror to detent-3.
        // (Re-framed geometry: scene dx +132, barrel re-staged at 0.545 scale.)
        // Select-then-tap: arm the poker, then tap the barrel (no auto-apply on bare tap).
        useItem(app, item: "itm-poker", onScene: 0.757, 0.665) // pry barrel -> weight
        assertHolding(app, "itm-weight")
        // BUG-015 polish: the hook hotspot now sits ON the pulley-rope hook art
        // (x~0.335-0.385), so the weight is released on the hook itself.
        useItem(app, item: "itm-weight", onScene: 0.36, 0.335) // hang weight -> z4
        Thread.sleep(forTimeInterval: 1.2)          // weight-hung beat + shelf slide
        shoot(app, "play-06-shelf-slid")
        tapScene(app, 0.415, 0.645)                 // take spoon
        assertHolding(app, "itm-spoon")
        tapScene(app, 0.635, 0.78)                  // mirror detent 2
        tapScene(app, 0.635, 0.78)                  // mirror detent 3
        // F-024: zone changes are DIEGETIC PASSAGES, not chevrons. The slid-shelf gap
        // (cellar `alcove-passage` hotspot ~center) leads into the alcove.
        tapScene(app, 0.467, 0.50, settle: 1.2)     // cellar -> alcove via the shelf gap
        shoot(app, "play-07-alcove")
        tapScene(app, 0.595, 0.265)                 // take star-bit cage key
        assertHolding(app, "itm-cage-key")

        // Back out to the cellar, then up the ladder to the hearth, then round to study.
        tapScene(app, 0.765, 0.50, settle: 1.2)     // alcove -> cellar via the shelf gap
        tapScene(app, 0.765, 0.335, settle: 1.2)    // cellar -> hearth up the ladder
        tapID(app, "nav-next")                      // hearth -> study (chevron, same zone)
        Thread.sleep(forTimeInterval: 0.8)
        shoot(app, "play-08-study")
        // Screenshot-coverage detours (QA re-QA gap list): the grimoire opens at the
        // feather-bookmarked recipe spread; the triptych is the three night paintings.
        tapScene(app, 0.485, 0.55)                  // grimoire close-up
        XCTAssertTrue(app.descendants(matching: .any)["closeup-dismiss"].waitForExistence(timeout: 5),
                      "grimoire close-up must present")
        shoot(app, "play-08b-grimoire-recipe")
        dismissCloseUp(app)
        tapScene(app, 0.475, 0.17)                  // triptych close-up
        XCTAssertTrue(app.descendants(matching: .any)["closeup-dismiss"].waitForExistence(timeout: 5),
                      "triptych close-up must present")
        shoot(app, "play-08c-triptych")
        dismissCloseUp(app)
        tapScene(app, 0.785, 0.46)                  // rune door close-up
        for tile in [3, 1, 4, 2] {                  // AIR, FIRE, EARTH, WATER
            tapID(app, "rune-tile-\(tile)")
        }
        Thread.sleep(forTimeInterval: 0.6)          // close-up closes on solve
        shoot(app, "play-09-runedoor-solved")
        tapScene(app, 0.785, 0.46, settle: 1.2)     // through the inner door -> bench

        // z2: astrolabe, cabinet.
        tapID(app, "nav-next")                      // bench -> cabinet
        Thread.sleep(forTimeInterval: 0.8)
        shoot(app, "play-10-cabinet")
        // Clue-gating (rev 1.3): view the Orion window (p03 gate) and the slot-shape
        // close-up (p04 gate) before the code-entry acts.
        tapScene(app, 0.73, 0.30); dismissCloseUp(app)   // window -> clu-window-orion
        tapScene(app, 0.20, 0.34); dismissCloseUp(app)   // sun slot close-up -> clu-slot-shapes
        tapScene(app, 0.60, 0.55)                   // astrolabe close-up (re-framed pedestal)
        shoot(app, "play-11-astrolabe")
        tapID(app, "astrolabe-plate-2")             // Orion -> drawer springs open
        assertHolding(app, "itm-crank")
        assertHolding(app, "itm-silver-coin")
        dismissCloseUp(app)
        useItem(app, item: "itm-gold-ring", onScene: 0.205, 0.345)   // sun recess
        useItem(app, item: "itm-silver-coin", onScene: 0.315, 0.355) // moon recess -> file + phial
        assertHolding(app, "itm-file")
        assertHolding(app, "itm-phial")
        shoot(app, "play-12-cabinet-open")

        // Free the crow. Leave z2 via the workshop exit affordance (-> study), then
        // chevron to the entry (F-024: zone changes are diegetic / the interim z2 exit).
        tapID(app, "nav-previous")                  // cabinet -> bench (chevron, z2)
        tapID(app, "zone-exit")                     // workshop -> study (z1)
        tapID(app, "nav-next")                      // study -> entry
        Thread.sleep(forTimeInterval: 0.8)
        // Screenshot-coverage detour (QA re-QA gap list): a deliberate armed-item REACH
        // at the cage triggers the D3 terminal-refusal pose (F-011: a bare tap is now a
        // neutral look, so the refusal fires only on an armed offer). Arm the rusted key
        // and offer it at the cage.
        let pokerCell = app.descendants(matching: .any)["inventory-itm-poker"]
        if pokerCell.waitForExistence(timeout: 3) {
            pokerCell.tap(); Thread.sleep(forTimeInterval: 0.2)   // arm the (held) poker
            tapScene(app, 0.70, 0.35)               // armed reach into the cage
            XCTAssertTrue(app.descendants(matching: .any)["refusal-pose"].waitForExistence(timeout: 5),
                          "an armed cage reach must present the terminal-refusal pose (D3/F-011)")
            shoot(app, "play-12b-crow-refusal")
            Thread.sleep(forTimeInterval: 1.8)      // refusal beat auto-dismisses (1.4 s)
        }
        // Free the crow: arm the cage key, then tap the star keyhole (select-then-tap).
        useItem(app, item: "itm-cage-key", onScene: 0.794, 0.24) // -> crow freed
        assertHolding(app, "itm-feather")
        shoot(app, "play-13-crow-freed")
        dismissCloseUp(app)
        // Graph-specified silent endgame nudge: once freed, the crow perches on the
        // door lintel above the basin (wide-shot state, p16 clue).
        Thread.sleep(forTimeInterval: 0.5)
        shoot(app, "play-13b-crow-lintel")

        // File + spoon -> shavings (inventory combine).
        tapID(app, "inventory-itm-file")
        tapID(app, "inventory-itm-spoon")
        assertHolding(app, "itm-shavings")

        // Light the alcove: reach the cellar (via z1 hearth trapdoor), fit the crank at
        // the winch, then pick the blossom in the alcove.
        // entry -> hearth (chevron within z1), then down the trapdoor to the cellar.
        tapID(app, "nav-next")                      // entry -> hearth (wraps within z1)
        Thread.sleep(forTimeInterval: 0.8)
        tapScene(app, 0.42, 0.76, settle: 1.2)      // trapdoor -> cellar (diegetic)
        // Select-then-tap: arm the crank, then tap the winch (no auto-fit on bare tap).
        useItem(app, item: "itm-crank", onScene: 0.235, 0.30) // fit crank, open shutter -> moonbeam
        shoot(app, "play-14-beam")
        tapScene(app, 0.467, 0.50, settle: 1.2)     // cellar -> alcove via the shelf gap
        shoot(app, "play-15-blooming")
        tapScene(app, 0.465, 0.73)                  // pick blossom
        assertHolding(app, "itm-blossom")

        // Brew: back to the cellar, up to the hearth, round to the study, through the
        // rune door to the workshop bench.
        tapScene(app, 0.765, 0.50, settle: 1.2)     // alcove -> cellar
        tapScene(app, 0.765, 0.335, settle: 1.2)    // cellar -> hearth up the ladder
        tapID(app, "nav-next")                      // hearth -> study
        Thread.sleep(forTimeInterval: 0.8)
        tapScene(app, 0.785, 0.46, settle: 1.2)     // through the (solved) rune door -> bench
        Thread.sleep(forTimeInterval: 0.8)
        useItem(app, item: "itm-blossom", onScene: 0.765, 0.37) // mortar -> paste
        assertHolding(app, "itm-paste")
        dismissCloseUp(app)
        useItem(app, item: "itm-paste", onScene: 0.255, 0.48)
        useItem(app, item: "itm-shavings", onScene: 0.255, 0.48)
        useItem(app, item: "itm-feather", onScene: 0.255, 0.48)
        tapScene(app, 0.255, 0.48)                  // brew close-up
        for _ in 0..<3 { tapID(app, "brew-pump") }  // flame stage 3
        for _ in 0..<5 { tapID(app, "brew-stir-ccw") }
        tapID(app, "brew-release")                  // -> draught-ready (spiral cue)
        shoot(app, "play-16-draught")
        dismissCloseUp(app)
        useItem(app, item: "itm-phial", onScene: 0.255, 0.48) // bottle the draught
        assertHolding(app, "itm-phial-draught")
        dismissCloseUp(app)

        // Endgame at the door. Leave the workshop via the z2 exit affordance (interim
        // "back through the rune door" chevron; no painted return door yet — flagged),
        // which lands in the study, then chevron round to the entry.
        tapID(app, "zone-exit")                     // workshop -> study (z1)
        Thread.sleep(forTimeInterval: 0.8)
        tapID(app, "nav-next")                      // study -> entry
        Thread.sleep(forTimeInterval: 0.8)
        useItem(app, item: "itm-phial-draught", onScene: 0.50, 0.40) // pour into basin
        shoot(app, "play-17-unsealed")
        dismissCloseUp(app)
        tapScene(app, 0.50, 0.40)                   // slide the bolt and leave (p17)
        // The Main Menu button doubles as the completion-card existence assert.
        XCTAssertTrue(app.descendants(matching: .any)["complete-main-menu"].waitForExistence(timeout: 6),
                      "completing p17 must present the completion card")
        shoot(app, "play-18-complete")
        tapID(app, "complete-main-menu")

        // Completion badge propagates to Level Select from the same save layer.
        tapID(app, "menu-play")
        XCTAssertTrue(app.descendants(matching: .any)["level-card-1-complete"].waitForExistence(timeout: 6),
                      "Level Select must show the completion badge")
        shoot(app, "play-19-badge")
    }
}
