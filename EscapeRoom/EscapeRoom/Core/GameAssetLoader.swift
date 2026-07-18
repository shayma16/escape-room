import UIKit

/// Resolves game-art filenames (base plates, overlays, icons, sprites) to on-disk URLs.
/// These assets live as loose files under the bundled `GameAssets/` and `Audio/` folder
/// references (not an Xcode asset catalog) because the per-level art pipeline
/// (tools/build_game_assets.py) ships hundreds of per-state JPEG/PNG files keyed by
/// path, and hand-maintaining an .xcassets entry per file would make the art pipeline's
/// output non-drop-in. Chrome art (app icon, launch screen, keyhole emblem, pause rune,
/// level thumbnail) is the one-time exception and lives in the real asset catalog
/// (see Assets.xcassets) since SwiftUI's Image(_:) needs catalog entries for those.
///
/// Lookup is by base filename without extension (e.g. "z1-hearth-base"), scanning the
/// bundled GameAssets directory once and caching the index. Names are unique across the
/// level-1 asset tree by construction (asset-manifest.json paths).
final class GameAssetLoader {
    static let shared = GameAssetLoader()

    private var index: [String: URL] = [:]

    /// Decoded-image cache (build 10 CI-perf fix, run 29186397614): `image(named:)` is
    /// called from SwiftUI `body` evaluations (GameImage), which re-run on EVERY observed
    /// state change — without a cache each re-render re-opened and re-decoded the file
    /// (close-up plates are ~10-megapixel JPEGs). Handing back the SAME UIImage instance
    /// also lets UIKit reuse its internally-decoded bitmap instead of decoding per draw.
    /// On the software-rendered CI simulator this decode churn (together with the 60 fps
    /// SKView, see SpriteKitContainerView) starved the main thread badly enough on iPad
    /// that XCUITest event delivery broke down. Cost-bounded so a long session on a real
    /// device degrades gracefully back to disk loads instead of growing without bound.
    private let imageCache: NSCache<NSString, UIImage> = {
        let cache = NSCache<NSString, UIImage>()
        cache.totalCostLimit = 192 * 1024 * 1024   // ~192 MB of decoded pixels
        return cache
    }()

    private init() {
        buildIndex()
    }

    private func buildIndex() {
        guard let resourceURL = Bundle.main.resourceURL else { return }
        let fm = FileManager.default
        for root in ["GameAssets", "Audio"] {
            let rootURL = resourceURL.appendingPathComponent(root)
            guard let enumerator = fm.enumerator(at: rootURL, includingPropertiesForKeys: nil) else { continue }
            for case let fileURL as URL in enumerator {
                let ext = fileURL.pathExtension.lowercased()
                guard ["png", "jpg", "jpeg"].contains(ext) else { continue }
                let key = fileURL.deletingPathExtension().lastPathComponent
                index[key] = fileURL
            }
        }
    }

    func url(for name: String) -> URL? {
        index[name]
    }

    func image(named name: String) -> UIImage? {
        if let cached = imageCache.object(forKey: name as NSString) { return cached }
        guard let url = index[name] else { return nil }
        guard let image = UIImage(contentsOfFile: url.path) else { return nil }
        let pixelCost = Int(image.size.width * image.scale * image.size.height * image.scale) * 4
        imageCache.setObject(image, forKey: name as NSString, cost: pixelCost)
        return image
    }
}
