import CoreGraphics
import Foundation

/// Loads EscapeRoom/Resources/GameAssets/level-1/overlays.json at runtime: the
/// authoritative, asset-pipeline-generated map of overlay-image -> normalized rect
/// within its base plate. Avoids hand-transcribing pixel rects into Swift (source of
/// drift bugs); the JSON is the single source of truth already produced by
/// tools/build_game_assets.py.
final class OverlayRectCatalog {
    static let shared = OverlayRectCatalog()

    private struct Entry: Decodable {
        let file: String
        let rect: [Double]
        let dimFile: String?
        let dimGain: Double?
    }

    private var rects: [String: [String: CGRect]] = [:]

    private init() {
        guard let url = Bundle.main.url(forResource: "overlays", withExtension: "json", subdirectory: "GameAssets/level-1")
            ?? Bundle.main.url(forResource: "overlays", withExtension: "json") else {
            return
        }
        guard let data = try? Data(contentsOf: url),
              let raw = try? JSONDecoder().decode([String: [String: Entry]].self, from: data) else {
            return
        }
        for (viewKey, overlays) in raw {
            var perView: [String: CGRect] = [:]
            for (overlayKey, entry) in overlays {
                guard entry.rect.count == 4 else { continue }
                perView[overlayKey] = CGRect(x: entry.rect[0], y: entry.rect[1], width: entry.rect[2], height: entry.rect[3])
            }
            rects[viewKey] = perView
        }
    }

    func rect(view: String, overlay: String) -> CGRect? {
        rects[view]?[overlay]
    }
}
