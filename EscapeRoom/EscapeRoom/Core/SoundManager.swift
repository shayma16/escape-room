import Foundation
import AVFoundation

/// Central functional-audio manager: interact/click, puzzle-solve, incorrect-attempt,
/// item-pickup, zone-unlock, and per-zone ambient loops. Respects the Settings "Sound"
/// master toggle. See specs/levels/level-1/implementation-notes.md for the source and
/// license of every audio file (all are originally synthesized, royalty-free by
/// construction — see that doc for detail).
final class SoundManager {
    static let shared = SoundManager()

    enum Effect: String {
        case click = "sfx-click"
        case pickup = "sfx-pickup"
        case wrong = "sfx-wrong"
        case solve = "sfx-solve"
        case unlock = "sfx-unlock"
        case refusal = "sfx-refusal"
        case clockClack = "sfx-clack"
        case fizzle = "sfx-fizzle"
    }

    enum Zone: String {
        case z1 = "amb-z1"
        case z2 = "amb-z2"
        case z3 = "amb-z3"
        case z4 = "amb-z4"
    }

    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private var ambientPlayer: AVAudioPlayer?
    private var currentZone: Zone?

    var soundOn: Bool {
        get { SaveGameStore.shared.soundOn }
        set { SaveGameStore.shared.soundOn = newValue; if !newValue { stopAmbient() } }
    }

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func play(_ effect: Effect) {
        guard soundOn else { return }
        let key = effect.rawValue
        if let player = effectPlayers[key] {
            player.currentTime = 0
            player.play()
            return
        }
        guard let url = Bundle.main.url(forResource: key, withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: key, withExtension: "wav") else { return }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.prepareToPlay()
            effectPlayers[key] = player
            player.play()
        }
    }

    /// Cross-fades to a new zone's ambient loop. Tonally distinct per zone via the
    /// underlying synthesized texture (see build script) — reverb/pitch/texture vary
    /// by zone while staying unobtrusive.
    func setAmbientZone(_ zone: Zone) {
        guard currentZone != zone else { return }
        currentZone = zone
        stopAmbient()
        guard soundOn else { return }
        guard let url = Bundle.main.url(forResource: zone.rawValue, withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: zone.rawValue, withExtension: "wav") else { return }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = 0.35
            player.prepareToPlay()
            player.play()
            ambientPlayer = player
        }
    }

    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
    }
}
