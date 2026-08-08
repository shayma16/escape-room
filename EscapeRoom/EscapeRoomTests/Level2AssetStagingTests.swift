import XCTest
import CryptoKit
@testable import EscapeRoom

/// Build-time guard that Level-2 art is CURRENT and never shadowed by a stale file (user
/// asset-staging directive, 2026-07-09). The staging script (tools/stage_level2_assets.py)
/// resolves each canonical name to exactly one manifest-current source, strips the @Nx
/// suffix so the canonical filename == current art, and records a staged-manifest.json of
/// {canonical name -> sha256}. This test reloads that manifest from the shipped bundle and
/// FAILS LOUDLY if:
///   - any staged file's bytes differ from the manifest (a stale shadow at a canonical name),
///   - any staged file carries a shadow marker (@Nx / -b2pre / -preglyph / _rejects / …),
///   - two staged files collide on one basename (the loader indexes by basename),
///   - a required canonical plate/overlay is missing or unloadable.
///
/// This is the recurrence guard for the build-3 defect where 70 stale close-ups shipped
/// behind fresh wides — here it cannot recur silently.
final class Level2AssetStagingTests: XCTestCase {

    private var levelDir: URL {
        Bundle.main.resourceURL!.appendingPathComponent("GameAssets/level-2")
    }

    private struct Manifest: Decodable {
        struct Entry: Decodable { let sha256: String; let source: String }
        let count: Int
        let assets: [String: Entry]
    }

    private func loadManifest() throws -> Manifest {
        let url = Bundle.main.url(forResource: "staged-manifest", withExtension: "json", subdirectory: "GameAssets/level-2")
            ?? levelDir.appendingPathComponent("staged-manifest.json")
        let data = try Data(contentsOf: url)
        return try JSONDecoder().decode(Manifest.self, from: data)
    }

    private func stagedPNGs() -> [URL] {
        guard let en = FileManager.default.enumerator(at: levelDir, includingPropertiesForKeys: nil) else { return [] }
        return en.compactMap { $0 as? URL }.filter { $0.pathExtension.lowercased() == "png" }
    }

    private func sha256(_ url: URL) -> String? {
        guard let data = try? Data(contentsOf: url) else { return nil }
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    func testNoShadowMarkersInStagedTree() {
        let markers = ["@1x", "@2x", "@3x", "-b2pre", "-b3pre", "-b4pre", "-preglyph",
                       "-rawfix", "-rawgen", "-superseded", "-rejects", "-r1", "-r2"]
        for url in stagedPNGs() {
            let name = url.deletingPathExtension().lastPathComponent
            for m in markers {
                XCTAssertFalse(name.contains(m), "stale/shadow-marked art staged: \(name) contains \(m)")
            }
        }
    }

    func testNoBasenameCollisionsInLevel2() {
        var seen: [String: URL] = [:]
        for url in stagedPNGs() {
            let base = url.deletingPathExtension().lastPathComponent
            if let prior = seen[base] {
                XCTFail("basename collision (shadow risk): \(base)\n  \(prior.path)\n  \(url.path)")
            }
            seen[base] = url
        }
    }

    func testStagedBytesMatchManifest_noStaleShadow() throws {
        let manifest = try loadManifest()
        XCTAssertGreaterThan(manifest.count, 0)
        // Index once: the staged set grew to ~150 files in round 8 (the close-up overlay
        // crops), and re-enumerating per asset made this quadratic.
        var byName: [String: URL] = [:]
        for url in stagedPNGs() { byName[url.deletingPathExtension().lastPathComponent + ".png"] = url }
        for (name, entry) in manifest.assets {
            // Resolve the staged file by basename anywhere under the level dir.
            guard let url = byName[name] else {
                XCTFail("manifest-current asset missing from bundle: \(name) (source \(entry.source))")
                continue
            }
            XCTAssertEqual(sha256(url), entry.sha256,
                           "staged \(name) differs from its manifest-current source — a stale shadow slipped in")
        }
    }

    func testRequiredCanonicalAssetsPresentAndLoadable() {
        let required = [
            "z1-bench-base", "z1-master-base", "z1-door-base",
            "z2-frame-base", "z2-clockrow-base", "z3-dial-base", "z4-vault-base",
            "cu-door-dial", "cu-great-dial", "cu-hatch-wheels", "cu-gear-frame",
            "ov-bar-raised-wide", "ov-cache-pried-wheel-wide", "ov-key-taken-wide", "ov-panel-open-wide",
            "inv-screwdriver", "inv-great-wheel", "inv-return-tag",
            // ROUND 8 CLUSTER A: the CLOSE-UP overlay crops. Authored in batch 2/3, never
            // staged through build 15 — which is why every L2 close-up rendered a static
            // plate while the wide view composited correctly. If these stop shipping, the
            // stale-close-up defect returns, so they are required here by name.
            "ov-cushion-empty-cu", "ov-cushion-reveal-cu", "ov-cache-pried-wheel-cu",
            "ov-cache-empty-cu", "ov-brick-pried-oilcan-cu", "ov-brick-empty-cu",
            "ov-coat-tile-taken-cu", "ov-coat-watch-taken-cu", "ov-sill-tile-taken-cu",
            "ov-dial-seat-ii-cu", "ov-dial-seat-iv-cu", "ov-dial-seat-vii-cu", "ov-dial-seat-xi-cu",
            "ov-drum-oiled-cu", "ov-drum-key-in-cu", "ov-key-taken-cu", "ov-tag-taken-cu",
            "ov-cabinet-open-mouse-cu", "ov-cabinet-empty-cu", "ov-arbor-oiled-cu",
            "ov-mount-a-36-cu", "ov-mount-b-64-cu",
            // R8-011(1): the cat's VISIBLE mouse-tell keys.
            "ov-cat-mouse-tell-cu", "ov-cat-mouse-tell-tail-cu", "ov-cat-slow-blink-cu",
            // Near-wordless replacements for the p06/p07 text UI.
            "gear-16", "gear-36", "gear-72", "die-bigben", "die-fuji", "hand-hour",
            // Close-up plates newly reachable this round.
            "cu-cabinet-drawer", "cu-key-hook",
            // BUILD 17 / R8-020 (user ruling): the z3 clockwork runs on AUTHORED sprite art —
            // the great dial's two hands and the brass pendulum cutout. If any of these stop
            // shipping the mechanism silently falls back to nothing on screen.
            "hand-minute", "sp-pendulum",
            // BUILD 17 / R8-021 + the systematic sweep behind it: the CROSS-ELEMENT close-up
            // echoes. Each of these clears a NEIGHBOURING element that its host plate also
            // depicts; without them a close-up shows an item the player is already carrying
            // (the reported stale winding key) or a door the level has already opened.
            "ov-keyhook-tag-taken-cu", "ov-tagnail-key-taken-cu",
            "ov-masterface-door-open-cu", "ov-crate-door-open-cu",
            "ov-housering-bar-raised-cu", "ov-gearring-brick-pried-cu",
            "ov-gearring-brick-empty-cu", "ov-gearframe-panel-open-cu",
            "ov-cushion-cache-pried-cu", "ov-cushion-cache-empty-cu",
            "ov-cache-cushion-lifted-cu",
            // REV 1.4.1: the teach-at-dormer chalk NOTE (wide + close-up + the cushion-crop
            // echo) and the D13 live-tally stroke sprites. If any of these stop shipping the
            // p03 teach or the p06 counting route silently render NOTHING.
            "ov-cache-marked-wide", "ov-cache-marked-cu", "ov-cushion-cache-marked-cu",
            "sp-tally-full", "sp-tally-partial", "sp-tally-strike",
        ]
        for name in required {
            XCTAssertNotNil(GameAssetLoader.shared.image(named: name), "missing/unloadable staged asset: \(name)")
        }
    }

    func testOverlayRectCatalogLoaded() {
        // Every active wide overlay must resolve a non-zero rect (else it silently won't render).
        for key in ["ov-bar-raised", "ov-cache-pried-wheel", "ov-key-taken", "ov-panel-open",
                    "ov-arbor-oiled", "ov-hatch-open", "ov-workroom-door-open",
                    "ov-cache-marked"] {
            XCTAssertNotEqual(Level2OverlayCatalog.shared.wideRect(key), .zero, "no wide rect for \(key)")
        }
    }

    /// Round 8: the CLOSE-UP rect side of the same catalog, plus the cat facial-key file that
    /// is loaded from its own JSON (`z1-cat-face.json`). A missing CU rect makes the overlay
    /// silently not render — exactly the failure mode this round is fixing.
    func testCloseUpOverlayRectsAndCatFaceCatalogLoaded() {
        for key in ["ov-cushion-empty", "ov-cushion-reveal", "ov-cache-pried-wheel", "ov-cache-empty",
                    "ov-brick-pried-oilcan", "ov-coat-tile-taken", "ov-coat-watch-taken",
                    "ov-sill-tile-taken", "ov-dial-seat-iv", "ov-drum-oiled", "ov-key-taken",
                    "ov-tag-taken", "ov-cabinet-open-mouse", "ov-mount-a-36", "ov-rack-absent-36"] {
            XCTAssertNotEqual(Level2OverlayCatalog.shared.cuRect(key), .zero, "no CU rect for \(key)")
        }
        for key in ["ov-cat-mouse-tell", "ov-cat-mouse-tell-tail", "ov-cat-slow-blink"] {
            XCTAssertNotEqual(Level2OverlayCatalog.shared.cuRect(key), .zero,
                              "no CU rect for \(key) — z1-cat-face.json must ship and load")
        }
        // BUILD 17 cross-element echoes (R8-021 + the systematic sweep).
        for key in ["ov-keyhook-tag-taken", "ov-tagnail-key-taken", "ov-masterface-door-open",
                    "ov-crate-door-open", "ov-housering-bar-raised", "ov-gearring-brick-pried",
                    "ov-gearring-brick-empty", "ov-gearframe-panel-open",
                    "ov-cushion-cache-pried", "ov-cushion-cache-empty",
                    "ov-cache-cushion-lifted",
                    // REV 1.4.1 teach-at-dormer note: the board's own CU rect + the cushion
                    // crop's echo of the same note.
                    "ov-cache-marked", "ov-cushion-cache-marked"] {
            XCTAssertNotEqual(Level2OverlayCatalog.shared.cuRect(key), .zero,
                              "no CU rect for the \(key) echo — it would composite NOTHING")
        }
    }

    /// REV 1.4.1 / D13: the live tally block is composited at runtime from AUTHORED sprites and
    /// AUTHORED notation. Both must ship, or the counting route (p06's safety net) draws nothing
    /// — and if the notation silently fell back to defaults the live block could drift off the
    /// timber cheek the crib is chalked on.
    func testTallySpriteRigShipsAndLoads() {
        XCTAssertNotNil(Bundle.main.url(forResource: "tally-sprites", withExtension: "json",
                                        subdirectory: "GameAssets/level-2")
                        ?? Bundle.main.url(forResource: "tally-sprites", withExtension: "json"),
                        "tally-sprites.json must ship in the bundle")
        for sprite in ["sp-tally-full", "sp-tally-partial", "sp-tally-strike"] {
            XCTAssertNotNil(GameAssetLoader.shared.image(named: sprite),
                            "the D13 stroke sprite \(sprite) must ship")
        }
        // The notation in force must be the AUTHORED notation (the in-code fallbacks are kept
        // deliberately identical to it, so this pins the values rather than the code path).
        let n = Level2Tally.notation
        XCTAssertEqual(n.rowBaselines.count, 3)
        XCTAssertEqual(n.x0, 702, accuracy: 0.001)
        XCTAssertEqual(n.ruleY, 604, accuracy: 0.001)
        XCTAssertNotEqual(n.blockRect, .zero)
    }

    /// BUILD 17: the authored sprite RIGS ship and load. The runtime reads its pendulum rect,
    /// pivot and amplitudes — and the dial hub the hands turn on — from these files rather
    /// than from constants, so a missing rig would silently fall back to defaults.
    func testClockworkSpriteRigsShipAndLoad() {
        for resource in ["hand-sprites", "clockwork-sprites"] {
            XCTAssertNotNil(Bundle.main.url(forResource: resource, withExtension: "json",
                                            subdirectory: "GameAssets/level-2")
                            ?? Bundle.main.url(forResource: resource, withExtension: "json"),
                            "\(resource).json must ship in the bundle")
        }
        let rig = Level2SpriteCatalog.shared
        XCTAssertNotEqual(rig.pendulum.rect, .zero)
        XCTAssertGreaterThan(rig.pendulum.fullDegrees, 0)
        XCTAssertGreaterThan(rig.hourHand.length, 0)
        XCTAssertGreaterThan(rig.minuteHand.length, 0)
        XCTAssertGreaterThan(rig.dial.cuScale, 1.0, "the CU crop is a zoom of the wide plate")
    }
}
