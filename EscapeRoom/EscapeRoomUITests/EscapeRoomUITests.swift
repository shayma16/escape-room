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

    /// Enter Level 1 from the main menu (shared by playthrough + save/resume tests).
    private func enterLevelOne(_ app: XCUIApplication) {
        tapID(app, "menu-play", timeout: coldLaunchTimeout)
        tapID(app, "level-card-1", timeout: coldLaunchTimeout)
        XCTAssertTrue(app.descendants(matching: .any)["pause-button"].waitForExistence(timeout: coldLaunchTimeout))
        Thread.sleep(forTimeInterval: 1.5)
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
        // scene is 2732x1366 .aspectFill and the base plate fills it exactly
        // (RoomScene.setBaseTexture), so a plate-normalized hotspot center maps 1:1 onto
        // the .aspectFill window coordinate `sceneCoordinate(_:_:_:)` produces — i.e. the
        // correct tap for a hotspot rect (x,y,w,h) is (x + w/2, y + h/2). Each tap was
        // verified to (a) fall inside its intended hotspot rect, (b) win the smallest-
        // area-wins overlap resolution (RoomScene.hotspotID(at:)) against any nesting
        // hotspot (star-keyhole/feed-cup inside cage; trapdoor inside rug; ladle inside
        // cauldron; alcove-passage inside cellar), (c) sit inside the iPad-safe band
        // x in [0.1665, 0.8335], and (d) clear the §7-R1 inventory pill (bottom band,
        // screen-y >= 0.835 on iPhone SE) — no scene tap here exceeds scene-y 0.78. The
        // two prior real failure modes this test surfaced (rune-tile modifier order;
        // rug/trapdoor taps under the bar) are both fixed in build-2 source. CI now
        // empirically confirms the full end-to-end solve on both device classes.
        let playthroughEnabled = true
        try XCTSkipUnless(playthroughEnabled, "playthrough disabled")

        let app = launchFreshApp()
        enterLevelOne(app)
        shoot(app, "play-01-hearth")

        // z1 hearth: poker, ash sift (glint close-up).
        // NOTE: taps on low-in-frame hotspots must stay above screen-y ~0.80 — the
        // inventory pill (§7-R1: 64/56 pt, bottom-center) covers a bottom band on iPhone
        // and swallows touches (root cause of CI run 28753975221's failure at the dial step).
        tapScene(app, 0.235, 0.685)                 // take poker
        assertHolding(app, "itm-poker")
        // Select-then-tap (F-007/F-020/F-021): arm the poker, then tap the ash pile.
        // A bare tap on ash is now only a look (no passive auto-apply), so the sift MUST
        // go through the armed-item path or the ring is never yielded.
        useItem(app, item: "itm-poker", onScene: 0.325, 0.650)  // sift ash -> glint close-up
        shoot(app, "play-02-ash-glint")
        // R2-003a two-step: sifting REVEALS the ring in the (now-open) ash close-up; it is
        // NOT auto-granted. Collect it with an explicit tap on the revealed-ring target.
        tapID(app, "collect-itm-gold-ring")
        assertHolding(app, "itm-gold-ring")
        dismissCloseUp(app)

        // Clue-gating (rev 1.3): a thorough player views the clue close-ups before the
        // gated code-entry puzzles will accept their answers. Gather z1's gate clues now.
        tapScene(app, 0.643, 0.40); dismissCloseUp(app)   // hearth bellows -> AIR mark
        tapScene(app, 0.32, 0.285); dismissCloseUp(app)   // hearth lintel -> FIRE mark
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // hearth -> study
        viewZ1GatingClues(app)                             // EARTH mark, triptych, grimoire A + recipe
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // study -> entry
        tapScene(app, 0.227, 0.57); dismissCloseUp(app)   // windowsill -> WATER mark
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
        useItem(app, item: "itm-poker", onScene: 0.765, 0.73) // pry barrel -> weight
        assertHolding(app, "itm-weight")
        // BUG-015 polish: the hook hotspot now sits ON the pulley-rope hook art
        // (x~0.335-0.385), so the weight is released on the hook itself.
        useItem(app, item: "itm-weight", onScene: 0.36, 0.335) // hang weight -> z4
        Thread.sleep(forTimeInterval: 1.2)          // weight-hung beat + shelf slide
        shoot(app, "play-06-shelf-slid")
        tapScene(app, 0.415, 0.645)                 // open drawer
        tapScene(app, 0.415, 0.645)                 // take spoon (manual pickup, F-018)
        assertHolding(app, "itm-spoon")
        tapScene(app, 0.635, 0.78)                  // mirror detent 2
        tapScene(app, 0.635, 0.78)                  // mirror detent 3
        // F-024: zone changes are DIEGETIC PASSAGES, not chevrons. The slid-shelf gap
        // (cellar `alcove-passage` hotspot ~center) leads into the alcove.
        tapScene(app, 0.467, 0.505, settle: 1.2)    // cellar -> alcove via the shelf gap
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
        tapScene(app, 0.745, 0.30); dismissCloseUp(app)  // window -> clu-window-orion
        tapScene(app, 0.205, 0.345); dismissCloseUp(app) // sun slot close-up -> clu-slot-shapes
        tapScene(app, 0.60, 0.57)                   // astrolabe close-up (re-framed pedestal)
        shoot(app, "play-11-astrolabe")
        tapID(app, "astrolabe-plate-2")             // Orion -> drawer springs open
        // F-023 manual pickup: coin + crank are VISIBLE in the drawer; tap each to collect.
        tapID(app, "collect-itm-silver-coin")
        tapID(app, "collect-itm-crank")
        assertHolding(app, "itm-crank")
        assertHolding(app, "itm-silver-coin")
        dismissCloseUp(app)
        useItem(app, item: "itm-gold-ring", onScene: 0.205, 0.345)   // sun recess
        useItem(app, item: "itm-silver-coin", onScene: 0.318, 0.355) // moon recess -> cabinet opens
        // F-023 manual pickup: file + phial visible in the opened cabinet; tap each.
        tapID(app, "collect-itm-file")
        tapID(app, "collect-itm-phial")
        assertHolding(app, "itm-file")
        assertHolding(app, "itm-phial")
        dismissCloseUp(app)
        shoot(app, "play-12-cabinet-open")

        // Free the crow. Leave z2 via the workshop exit affordance (-> study), then
        // chevron to the entry (F-024: zone changes are diegetic / the interim z2 exit).
        tapID(app, "nav-previous")                  // cabinet -> bench (chevron, z2)
        tapID(app, "zone-exit")                     // workshop -> study (z1)
        tapID(app, "nav-next")                      // study -> entry
        Thread.sleep(forTimeInterval: 0.8)
        // Screenshot-coverage detour (QA re-QA gap list, NON-LOAD-BEARING): a deliberate
        // armed-item REACH at the cage triggers the D3 terminal-refusal pose (F-011: a
        // bare tap is now a neutral look, so the refusal fires only on an armed offer).
        // The refusal is a no-op beat that AUTO-DISMISSES after 1.4 s and is exhaustively
        // verified at the unit level (testBareCageTapShowsNeutralPoseNotRefusal_F011,
        // testD1FeedCupRefusalNeverMutatesDraughtOrCrowState). This detour only tries to
        // capture the pose for the screenshot record; because of the 1.4 s auto-dismiss it
        // is inherently timing-sensitive, so it is BEST-EFFORT: it must never fail the
        // load-bearing playthrough (the actual crow-freeing below carries the D3/F-011
        // regression weight). Arm the poker (the rusted key gets the mechanical-reject
        // path, not the refusal), reach into the cage, and grab whatever is on screen.
        let pokerCell = app.descendants(matching: .any)["inventory-itm-poker"]
        if pokerCell.waitForExistence(timeout: 3) {
            pokerCell.tap()                                         // arm the (held) poker
            Thread.sleep(forTimeInterval: 0.2)
            sceneCoordinate(app, 0.70, 0.35).tap()                 // armed reach into the cage
            // Poll briefly for the pose, but do NOT assert — the beat may auto-dismiss
            // before the first poll returns on a slow runner. Capture regardless.
            _ = app.descendants(matching: .any)["refusal-pose"].waitForExistence(timeout: 1.0)
            shoot(app, "play-12b-crow-refusal")
            Thread.sleep(forTimeInterval: 1.6)                     // let the beat fully clear
            // If the refusal close-up is still up, dismiss defensively so the next scene
            // tap reaches the entry, not the (dismiss-on-any-tap) refusal overlay.
            if app.descendants(matching: .any)["refusal-pose"].exists {
                sceneCoordinate(app, 0.5, 0.5).tap()
                Thread.sleep(forTimeInterval: 0.4)
            }
        }
        // Free the crow (LOAD-BEARING, carries D3/F-011): arm the cage key, then tap the
        // star keyhole (select-then-tap). The feather yield proves p11 solved.
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
        tapScene(app, 0.467, 0.505, settle: 1.2)    // cellar -> alcove via the shelf gap
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
        useItem(app, item: "itm-blossom", onScene: 0.76, 0.37) // mortar -> paste
        assertHolding(app, "itm-paste")
        dismissCloseUp(app)
        useItem(app, item: "itm-paste", onScene: 0.264, 0.48)
        useItem(app, item: "itm-shavings", onScene: 0.264, 0.48)
        useItem(app, item: "itm-feather", onScene: 0.264, 0.48)
        tapScene(app, 0.264, 0.48)                  // brew close-up
        for _ in 0..<3 { tapID(app, "brew-pump") }  // flame stage 3
        for _ in 0..<5 { tapID(app, "brew-stir-ccw") }
        tapID(app, "brew-release")                  // -> draught-ready (spiral cue)
        shoot(app, "play-16-draught")
        dismissCloseUp(app)
        useItem(app, item: "itm-phial", onScene: 0.264, 0.48) // bottle the draught
        assertHolding(app, "itm-phial-draught")
        dismissCloseUp(app)

        // Endgame at the door. Leave the workshop via the z2 exit affordance (interim
        // "back through the rune door" chevron; no painted return door yet — flagged),
        // which lands in the study, then chevron round to the entry.
        tapID(app, "zone-exit")                     // workshop -> study (z1)
        Thread.sleep(forTimeInterval: 0.8)
        tapID(app, "nav-next")                      // study -> entry
        Thread.sleep(forTimeInterval: 0.8)
        useItem(app, item: "itm-phial-draught", onScene: 0.50, 0.425) // pour into basin
        shoot(app, "play-17-unsealed")
        dismissCloseUp(app)
        tapScene(app, 0.50, 0.425)                  // slide the bolt and leave (p17)
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
        tapScene(app, 0.235, 0.685)                 // take poker
        assertHolding(app, "itm-poker")
        useItem(app, item: "itm-poker", onScene: 0.325, 0.650) // sift ash -> reveals ring
        // R2-003a two-step: explicitly collect the revealed ring from the ash close-up.
        tapID(app, "collect-itm-gold-ring")
        assertHolding(app, "itm-gold-ring")
        dismissCloseUp(app)
        tapScene(app, 0.643, 0.40); dismissCloseUp(app)   // AIR mark
        tapScene(app, 0.32, 0.285); dismissCloseUp(app)   // FIRE mark
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // -> study
        viewZ1GatingClues(app)                            // EARTH + grimoire page A (+ triptych/recipe)
        tapID(app, "nav-next"); Thread.sleep(forTimeInterval: 0.8) // -> entry
        tapScene(app, 0.227, 0.57); dismissCloseUp(app)   // WATER mark

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
        tapScene(app2, 0.785, 0.46)                 // rune door close-up
        for tile in [3, 1, 4, 2] {                  // AIR, FIRE, EARTH, WATER
            tapID(app2, "rune-tile-\(tile)")
        }
        Thread.sleep(forTimeInterval: 0.6)          // close-up closes on solve
        shoot(app2, "resume-02-runedoor-solved-postresume")
        tapScene(app2, 0.785, 0.46, settle: 1.2)    // through the now-open inner door -> z2 bench
        // Reaching z2 confirms the gate accepted the answer post-relaunch (D7). The z2
        // bench has a mortar hotspot whose close-up we can open as a reachability proof.
        tapScene(app2, 0.76, 0.37)                  // mortar look (z2 v-bench only)
        XCTAssertTrue(app2.descendants(matching: .any)["closeup-dismiss"].waitForExistence(timeout: 5),
                      "must have entered z2 (rune gate did NOT re-lock across relaunch — D7)")
        shoot(app2, "resume-03-in-z2-gate-held")
    }
}
