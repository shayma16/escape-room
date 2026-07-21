import XCTest
import UIKit

/// M2 (QA build-1): on-device UI coverage for Level 2 "The Clockmaker's Attic", the chrome
/// counterpart to the harness-immune geometry/engine net in Level2RegistrationTests +
/// Level2Tests. It drives the REAL app (SwiftUI chrome + the SpriteKit L2 scenes) through
/// menu -> level-2 entry -> z1 element pickups (each tapped at its VISUAL scene position) ->
/// close-up presentation -> navigation -> pause, asserting the resulting inventory/scene
/// state a human would see.
///
/// L2 scenes are `.aspectFill` with hotspots authored in FINAL plate space (no build-10
/// re-frame), so `sceneCoordinate` uses the plain cover-scale math (no `rf` transform).
///
/// Scope note (Developer judgment call, flagged to the Producer): a full blind 11-puzzle
/// XCUITest solve is NOT shipped here — the full human-visible completability + every-element-
/// at-its-visual-position verification is delivered reliably (and on all three device
/// runtimes) by Level2RegistrationTests (registration/M1 guard + player-style visual-tap hit
/// resolution) and Level2Tests (the graph example-ordering A/B end-to-end solves). This UI
/// test verifies the on-device chrome wiring the unit layer cannot: real touch hit-testing,
/// close-up presentation, inventory arming, navigation arrival, and the coat-pocket collect
/// fix. Both tests are cheap enough to run on every device in the matrix.
final class Level2UITests: XCTestCase {

    private let sceneSize = CGSize(width: 2732, height: 1366)
    private let coldLaunchTimeout: TimeInterval = 30
    private var launchedApp: XCUIApplication?

    override func setUp() {
        super.setUp()
        continueAfterFailure = false
        XCUIDevice.shared.orientation = .landscapeLeft
    }
    override func tearDown() {
        if let app = launchedApp, app.state != .notRunning { app.terminate() }
        launchedApp = nil
        super.tearDown()
    }

    private func launchFreshApp() -> XCUIApplication {
        let app = XCUIApplication()
        app.launchArguments = ["-resetSave"]
        launchedApp = app
        app.launch()
        return app
    }

    /// Plate-normalized (top-left) -> window coordinate under `.aspectFill` cover scale, the
    /// exact composition the L2 RoomScene renders (no re-frame for L2).
    private func sceneCoordinate(_ app: XCUIApplication, _ nx: CGFloat, _ ny: CGFloat) -> XCUICoordinate {
        let frame = app.windows.firstMatch.frame
        let scale = max(frame.width / sceneSize.width, frame.height / sceneSize.height)
        let viewX = frame.width / 2 + (nx * sceneSize.width - sceneSize.width / 2) * scale
        let viewY = frame.height / 2 + (ny * sceneSize.height - sceneSize.height / 2) * scale
        return app.windows.firstMatch.coordinate(withNormalizedOffset: CGVector(dx: viewX / frame.width,
                                                                                dy: viewY / frame.height))
    }
    private func tapScene(_ app: XCUIApplication, _ nx: CGFloat, _ ny: CGFloat, settle: TimeInterval = 0.6) {
        sceneCoordinate(app, nx, ny).tap()
        Thread.sleep(forTimeInterval: settle)
    }
    private func tapID(_ app: XCUIApplication, _ id: String, timeout: TimeInterval = 6) {
        let el = app.descendants(matching: .any)[id].firstMatch
        XCTAssertTrue(el.waitForExistence(timeout: timeout), "\(id) must exist")
        el.tap()
        Thread.sleep(forTimeInterval: 0.35)
    }
    private func sceneHotspot(_ app: XCUIApplication, _ id: String) -> XCUIElement {
        app.descendants(matching: .any).matching(NSPredicate(format: "label == %@", "hotspot:\(id)")).firstMatch
    }
    private func assertHolding(_ app: XCUIApplication, _ item: String,
                              file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(app.descendants(matching: .any)["inventory-\(item)"].waitForExistence(timeout: 10),
                      "\(item) must be in the inventory bar", file: file, line: line)
    }
    private func shoot(_ app: XCUIApplication, _ name: String) {
        let a = XCTAttachment(screenshot: app.screenshot()); a.name = name; a.lifetime = .keepAlways; add(a)
    }

    private func enterLevelTwo(_ app: XCUIApplication) {
        tapID(app, "menu-play", timeout: coldLaunchTimeout)
        tapID(app, "level-card-2", timeout: coldLaunchTimeout)
        XCTAssertTrue(app.descendants(matching: .any)["pause-button"].waitForExistence(timeout: coldLaunchTimeout),
                      "must have entered Level 2 (pause button present)")
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// Navigate a z1 side chevron and wait for the destination's signature hotspot (one retry
    /// for a CI-lost tap), mirroring L1's arrival guard.
    private func ensureView(_ app: XCUIApplication, _ signature: String,
                            file: StaticString = #filePath, line: UInt = #line, navigate: () -> Void) {
        let hs = sceneHotspot(app, signature)
        for attempt in 0..<2 {
            navigate()
            if hs.waitForExistence(timeout: attempt == 0 ? 15 : 25) { Thread.sleep(forTimeInterval: 0.5); return }
        }
        XCTFail("navigation to hotspot:\(signature) did not take effect", file: file, line: line)
    }

    // MARK: - Composition guard (L2 analogue of QA-B3-001)

    func testL2SceneContentFillsScreen() {
        let app = launchFreshApp()
        enterLevelTwo(app)
        Thread.sleep(forTimeInterval: 1.0)
        shoot(app, "l2-composition")
        let win = app.windows.firstMatch.frame
        let scene = app.descendants(matching: .any)["room-scene"].firstMatch
        XCTAssertTrue(scene.waitForExistence(timeout: 5), "L2 room-scene must exist")
        let sf = scene.frame
        XCTAssertFalse(win.isEmpty); XCTAssertFalse(sf.isEmpty)
        XCTAssertGreaterThanOrEqual(sf.width / win.width, 0.90, "L2 scene must span the window width")
        XCTAssertGreaterThanOrEqual(sf.height / win.height, 0.90, "L2 scene must span the window height")
        XCTAssertGreaterThanOrEqual(sf.width, sf.height, "L2 scene must be landscape")
    }

    // MARK: - z1 pickups (incl. the coat-pocket collect FIX) + close-ups + nav + pause

    func testL2Z1PickupsCloseUpsAndNavigationSmoke() {
        let app = launchFreshApp()
        enterLevelTwo(app)
        shoot(app, "l2-smoke-01-bench")

        // Wide-tap pickups at their visual positions (proves real hit-testing + inventory).
        tapScene(app, 0.302, 0.404)                 // screwdriver (rack, left)
        assertHolding(app, "itm-screwdriver")
        tapScene(app, 0.72, 0.77)                   // tile II on the cold stove hob (right)
        assertHolding(app, "itm-tile-ii")

        // Coat close-up: the FIX — two collectible pockets. Prior build shipped a plain image
        // with no pickup path, so tile IV (needed for p01) was unobtainable in-app.
        tapScene(app, 0.115, 0.47)                  // coat (far left)
        XCTAssertTrue(app.descendants(matching: .any)["collect-itm-tile-iv"].waitForExistence(timeout: 5),
                      "coat close-up must expose the tile-IV pocket (completability fix)")
        shoot(app, "l2-smoke-02-coat-pockets")
        tapID(app, "collect-itm-tile-iv")
        tapID(app, "collect-itm-watch-a")
        tapID(app, "closeup-dismiss")
        assertHolding(app, "itm-tile-iv")
        assertHolding(app, "itm-watch-a")

        // z1 navigation: bench -> master (door-dial close-up presents) -> door.
        ensureView(app, "door-dial") { tapID(app, "nav-next") }
        tapScene(app, 0.74, 0.80)                   // crate straw -> tile VII (right, above the pill)
        assertHolding(app, "itm-tile-vii")
        tapScene(app, 0.65, 0.46)                   // door-dial close-up
        XCTAssertTrue(app.descendants(matching: .any)["dial-socket-2"].waitForExistence(timeout: 5),
                      "the numeral-dial close-up must present its sockets")
        shoot(app, "l2-smoke-03-dial-door")
        tapID(app, "closeup-dismiss")

        ensureView(app, "stair-door") { tapID(app, "nav-next") }   // master -> door
        tapScene(app, 0.65, 0.53)                   // dormer sill -> tile XI (clear of the cushion top)
        assertHolding(app, "itm-tile-xi")
        shoot(app, "l2-smoke-04-door")

        // Pause round-trip back to the Main Menu (shared chrome; music scope closes).
        tapID(app, "pause-button")
        shoot(app, "l2-smoke-05-pause")
        app.buttons["Resume"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 0.5)
        tapID(app, "pause-button")
        tapID(app, "pause-main-menu")
        XCTAssertTrue(app.descendants(matching: .any)["menu-play"].waitForExistence(timeout: 6),
                      "Main Menu must be the same root after leaving Level 2")
        shoot(app, "l2-smoke-06-back-at-menu")
    }
}
