import Foundation
import AVFoundation

/// Central functional-audio manager. Feedback round 1 sound overhaul (F-005/F-009/
/// F-019 merged, user-broadened): the generic interaction "psh" click is GONE from
/// every interaction point — each remaining cue is either object-relevant or absent
/// (user explicitly prefers silence over a generic sound). The add-to-inventory
/// pickup chime is kept unchanged (user liked it).
///
/// Ambience (F-002, "quieter scene"): a soft diegetic entry swell plays once at level
/// entry, then per-zone loops run at a whisper level (re-synthesized sparser + quieter
/// AND played at lower volume) — the neutralxe register: near-silence with sparse
/// texture rather than a constant weather bed.
///
/// All files are originally synthesized by tools/build_game_assets.py (no third-party
/// audio, no license obligations — see implementation-notes.md licensing table).
final class SoundManager {
    static let shared = SoundManager()

    enum Effect: String {
        // Kept from build 1 (all event-specific, none generic):
        case pickup = "sfx-pickup"      // add-to-inventory (user likes it — unchanged)
        case wrong = "sfx-wrong"        // dull knock, failure_behavior standard
        case solve = "sfx-solve"        // puzzle-solve confirmation
        case unlock = "sfx-unlock"      // zone-unlock stone rumble
        case refusal = "sfx-refusal"    // crow terminal refusal (D3/D4)
        case clockClack = "sfx-clack"   // cuckoo pop (D5)
        case fizzle = "sfx-fizzle"      // brew failure hiss
        // New per-object cues (feedback round 1; synthesized, see build script):
        case page = "sfx-page"          // grimoire/triptych page turn
        case stonePress = "sfx-stone"   // rune tile press
        case tick = "sfx-tick"          // dial/clock-hand ratchet, item seating
        case grind = "sfx-grind"        // mirror stand detent scrape
        case bellows = "sfx-bellows"    // bellows air puff (both pumps)
        case stir = "sfx-stir"          // ladle stir swish
        case cloth = "sfx-cloth"        // rug slide
        case wood = "sfx-wood"          // drawer/passage wood slide
        case entry = "sfx-entry"        // one-shot level-entry swell (F-002)
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

    /// Whisper-level ambient bed per the F-002 direction (was 0.35 in build 1, on
    /// louder source files).
    private let ambientVolume: Float = 0.18

    #if DEBUG
    /// Test seam: every play() call is recorded so unit tests can assert silence on
    /// dead hotspots (F-006/F-014) and per-object cue routing, without real audio I/O.
    private(set) var playedLog: [Effect] = []
    func resetPlayedLog() { playedLog.removeAll() }
    /// Test seam for the F-004 lifecycle assertions.
    var isAmbientActive: Bool { ambientPlayer != nil }
    var debugCurrentZone: Zone? { currentZone }
    #endif

    var soundOn: Bool {
        get { SaveGameStore.shared.soundOn }
        set {
            SaveGameStore.shared.soundOn = newValue
            if !newValue {
                stopAmbient()
            } else if let zone = currentZone {
                // Re-enabling sound mid-level resumes the current zone's bed.
                let resume = zone
                currentZone = nil
                setAmbientZone(resume)
            }
        }
    }

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    func play(_ effect: Effect) {
        #if DEBUG
        playedLog.append(effect)
        #endif
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

    /// Switches to a new zone's ambient loop. F-004 fix: `stopAmbient()` now clears
    /// `currentZone`, so re-entering a level after exiting to the Main Menu always
    /// restarts the bed (the old guard compared against a stale zone and silently
    /// skipped the restart). The guard here only debounces same-zone view changes
    /// while a loop is actually playing.
    func setAmbientZone(_ zone: Zone) {
        if currentZone == zone, ambientPlayer != nil { return }
        currentZone = zone
        ambientPlayer?.stop()
        ambientPlayer = nil
        guard soundOn else { return }
        guard let url = Bundle.main.url(forResource: zone.rawValue, withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: zone.rawValue, withExtension: "wav") else { return }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1
            player.volume = ambientVolume
            player.prepareToPlay()
            player.play()
            ambientPlayer = player
        }
    }

    /// Full ambient teardown — called on every exit to menu chrome (pause -> Main
    /// Menu, completion card -> Main Menu). Ambience must never play under menus
    /// (QA BUG-019 companion) and must restart cleanly on re-entry (F-004).
    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentZone = nil
    }
}
