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
        for (name, entry) in manifest.assets {
            // Resolve the staged file by basename anywhere under the level dir.
            guard let url = stagedPNGs().first(where: { $0.deletingPathExtension().lastPathComponent + ".png" == name }) else {
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
        ]
        for name in required {
            XCTAssertNotNil(GameAssetLoader.shared.image(named: name), "missing/unloadable staged asset: \(name)")
        }
    }

    func testOverlayRectCatalogLoaded() {
        // Every active wide overlay must resolve a non-zero rect (else it silently won't render).
        for key in ["ov-bar-raised", "ov-cache-pried-wheel", "ov-key-taken", "ov-panel-open",
                    "ov-arbor-oiled", "ov-hatch-open", "ov-workroom-door-open"] {
            XCTAssertNotEqual(Level2OverlayCatalog.shared.wideRect(key), .zero, "no wide rect for \(key)")
        }
    }
}
