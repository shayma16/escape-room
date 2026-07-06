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
/// NOTE (QA-BUG-004 carve-out): the full playthrough currently runs on iPhone-class
/// devices only — on iPad several puzzle-critical elements (cellar barrel, entry cage)
/// sit outside the 4:3 crop until the Asset Generation re-frame batch lands. The
/// menu/navigation smoke test runs on all devices. When the re-framed plates are
/// integrated, drop the XCTSkip and update the affected coordinates.
final class EscapeRoomUITests: XCTestCase {

    private let sceneSize = CGSize(width: 2732, height: 1366)

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
    }

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetSave"]
        app.launch()
        return app
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

    private func dragItem(_ app: XCUIApplication, item: String, toScene nx: CGFloat, _ ny: CGFloat) {
        let element = app.descendants(matching: .any)["inventory-\(item)"]
        XCTAssertTrue(element.waitForExistence(timeout: 5), "inventory item \(item) must exist")
        let start = element.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
        start.press(forDuration: 0.25, thenDragTo: sceneCoordinate(app, nx, ny))
        Thread.sleep(forTimeInterval: 0.8)
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
        tapID(app, "menu-play")
        shoot(app, "smoke-02-level-select")
        tapID(app, "level-card-1")
        XCTAssertTrue(app.descendants(matching: .any)["pause-button"].waitForExistence(timeout: 10))
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
        if UIDevice.current.userInterfaceIdiom == .pad {
            throw XCTSkip("Full playthrough on iPad is blocked until the QA-BUG-004 re-framed plates land (barrel/cage outside the 4:3 crop).")
        }
        let app = launchFreshApp()
        tapID(app, "menu-play")
        tapID(app, "level-card-1")
        XCTAssertTrue(app.descendants(matching: .any)["pause-button"].waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.5)
        shoot(app, "play-01-hearth")

        // z1 hearth: poker, ash sift (glint close-up), rug discovery, dial panel.
        // NOTE: taps on low-in-frame hotspots must stay above screen-y ~0.80 — the
        // 72-pt inventory bar covers the bottom band on iPhone and swallows touches
        // (root cause of CI run 28753975221's failure at the dial step).
        tapScene(app, 0.235, 0.685)                 // take poker
        assertHolding(app, "itm-poker")
        tapScene(app, 0.325, 0.650)                 // sift ash -> glint close-up
        assertHolding(app, "itm-gold-ring")
        shoot(app, "play-02-ash-glint")
        dismissCloseUp(app)
        tapScene(app, 0.15, 0.76)                   // move rug (upper rug edge, clear of the bar)
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
        tapScene(app, 0.87, 0.73)                   // pry barrel (poker held) -> weight
        assertHolding(app, "itm-weight")
        dragItem(app, item: "itm-weight", toScene: 0.25, 0.32) // hang weight -> z4
        Thread.sleep(forTimeInterval: 1.2)          // weight-hung beat + shelf slide
        shoot(app, "play-06-shelf-slid")
        tapScene(app, 0.36, 0.63)                   // take spoon
        assertHolding(app, "itm-spoon")
        tapScene(app, 0.58, 0.76)                   // mirror detent 2
        tapScene(app, 0.58, 0.76)                   // mirror detent 3
        tapID(app, "nav-next")                      // cellar -> alcove
        Thread.sleep(forTimeInterval: 0.8)
        shoot(app, "play-07-alcove")
        tapScene(app, 0.595, 0.265)                 // take star-bit cage key
        assertHolding(app, "itm-cage-key")

        // Back around to the study for the rune door.
        tapID(app, "nav-next")                      // alcove -> hearth
        tapID(app, "nav-next")                      // hearth -> study
        Thread.sleep(forTimeInterval: 0.8)
        shoot(app, "play-08-study")
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
        tapScene(app, 0.84, 0.72)                   // astrolabe close-up
        shoot(app, "play-11-astrolabe")
        tapID(app, "astrolabe-plate-2")             // Orion -> drawer springs open
        assertHolding(app, "itm-crank")
        assertHolding(app, "itm-silver-coin")
        dismissCloseUp(app)
        dragItem(app, item: "itm-gold-ring", toScene: 0.20, 0.275)   // sun slot
        dragItem(app, item: "itm-silver-coin", toScene: 0.33, 0.275) // moon slot -> file + phial
        assertHolding(app, "itm-file")
        assertHolding(app, "itm-phial")
        shoot(app, "play-12-cabinet-open")

        // Free the crow.
        tapID(app, "nav-previous")                  // cabinet -> bench
        tapID(app, "nav-previous")                  // bench -> entry
        Thread.sleep(forTimeInterval: 0.8)
        tapScene(app, 0.83, 0.33)                   // star keyhole with key -> crow freed
        assertHolding(app, "itm-feather")
        shoot(app, "play-13-crow-freed")
        dismissCloseUp(app)

        // File + spoon -> shavings (inventory combine).
        tapID(app, "inventory-itm-file")
        tapID(app, "inventory-itm-spoon")
        assertHolding(app, "itm-shavings")

        // Light the alcove: winch, then pick the blossom.
        tapID(app, "nav-next")                      // entry -> bench
        tapID(app, "nav-next")                      // bench -> cabinet
        tapID(app, "nav-next")                      // cabinet -> cellar
        Thread.sleep(forTimeInterval: 0.8)
        tapScene(app, 0.19, 0.28)                   // fit crank, open shutter -> moonbeam
        shoot(app, "play-14-beam")
        tapID(app, "nav-next")                      // cellar -> alcove
        Thread.sleep(forTimeInterval: 0.8)
        shoot(app, "play-15-blooming")
        tapScene(app, 0.465, 0.73)                  // pick blossom
        assertHolding(app, "itm-blossom")

        // Brew.
        tapID(app, "nav-next")                      // alcove -> hearth
        tapID(app, "nav-next")                      // hearth -> study
        tapID(app, "nav-next")                      // study -> entry
        tapID(app, "nav-next")                      // entry -> bench
        Thread.sleep(forTimeInterval: 0.8)
        dragItem(app, item: "itm-blossom", toScene: 0.765, 0.37) // mortar -> paste
        assertHolding(app, "itm-paste")
        dismissCloseUp(app)
        dragItem(app, item: "itm-paste", toScene: 0.255, 0.48)
        dragItem(app, item: "itm-shavings", toScene: 0.255, 0.48)
        dragItem(app, item: "itm-feather", toScene: 0.255, 0.48)
        tapScene(app, 0.255, 0.48)                  // brew close-up
        for _ in 0..<3 { tapID(app, "brew-pump") }  // flame stage 3
        for _ in 0..<5 { tapID(app, "brew-stir-ccw") }
        tapID(app, "brew-release")                  // -> draught-ready (spiral cue)
        shoot(app, "play-16-draught")
        dismissCloseUp(app)
        dragItem(app, item: "itm-phial", toScene: 0.255, 0.48) // bottle the draught
        assertHolding(app, "itm-phial-draught")
        dismissCloseUp(app)

        // Endgame at the door.
        tapID(app, "nav-previous")                  // bench -> entry
        Thread.sleep(forTimeInterval: 0.8)
        dragItem(app, item: "itm-phial-draught", toScene: 0.50, 0.55) // pour into basin
        shoot(app, "play-17-unsealed")
        dismissCloseUp(app)
        tapScene(app, 0.50, 0.55)                   // slide the bolt and leave (p17)
        XCTAssertTrue(app.descendants(matching: .any)["level-complete"].waitForExistence(timeout: 6),
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
