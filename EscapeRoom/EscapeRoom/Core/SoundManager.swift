import Foundation
import AVFoundation

/// Central functional-audio manager.
///
/// Round-2 audio batch (build 3) — CLUSTER A:
/// - There is NO default per-tap "psh": tap feedback is purely visual (the parchment
///   pulse in RoomScene). Confirmed: no call site plays a generic click; R2-024's root
///   cause (a default sound on every tap incl. nav/empty space) cannot recur because the
///   only always-on tap feedback is `RoomScene.flashTapFeedback`, which plays nothing.
///   Every remaining cue is EVENT-mapped (pickup / solve / unlock / door-open / page /
///   etc.) and object-relevant.
/// - Background music: the user-supplied `music-level1.wav` (fal.ai-generated, user-owned,
///   commercial use OK — see implementation-notes licensing table) loops seamlessly and
///   unobtrusively as the level bed, REPLACING the old ocean-ish z1 ambience (R2-004/005).
///   The per-zone amb-z* loops are retained only as a very faint per-zone texture UNDER
///   the music so zones stay tonally distinct (functional ambient-loop requirement).
/// - R2-006: audio splits into TWO independent, separately-persisted mutes —
///   `ambianceEnabled` (music + ambient beds) and `sfxEnabled` (interaction cues). Either
///   can be toggled without affecting the other.
///
/// All SFX + ambient beds are originally synthesized by tools/build_game_assets.py (no
/// third-party audio). The music is user-provided. See implementation-notes licensing.
final class SoundManager {
    static let shared = SoundManager()

    enum Effect: String {
        // Kept from build 1 (all event-specific, none generic):
        case pickup = "sfx-pickup"      // add-to-inventory (user likes it — unchanged)
        case wrong = "sfx-wrong"        // dull knock, failure_behavior standard
        case solve = "sfx-solve"        // puzzle-solve confirmation
        case unlock = "sfx-unlock"      // zone-unlock stone rumble
        case refusal = "sfx-refusal"    // crow terminal refusal (D3/D4)
        case clockClack = "sfx-clack"   // RETIRED (Q3: cuckoo removed); kept for compat
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
        case door = "sfx-door"          // themed door-opening (R2-015a: rune door / final door)
    }

    enum Zone: String {
        case z1 = "amb-z1"
        case z2 = "amb-z2"
        case z3 = "amb-z3"
        case z4 = "amb-z4"
    }

    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private var ambientPlayer: AVAudioPlayer?
    private var musicPlayer: AVAudioPlayer?
    private var currentZone: Zone?

    /// Per-zone texture bed sits WAY under the music now (it's a faint tonal tint, not
    /// the main bed anymore — the music carries the room). Was 0.18 as the sole bed.
    private let ambientVolume: Float = 0.06
    /// Background music: present but unobtrusive, sits under gameplay (F-002 "quieter
    /// scene" direction still applies).
    private let musicVolume: Float = 0.22
    /// The user-provided level background music (fal.ai-generated, user-owned).
    private let musicResource = "music-level1"

    #if DEBUG
    /// Test seam: every play() call is recorded so unit tests can assert silence on
    /// dead hotspots (F-006/F-014) and per-object cue routing, without real audio I/O.
    private(set) var playedLog: [Effect] = []
    func resetPlayedLog() { playedLog.removeAll() }
    /// Test seams for the F-004 / R2-005 / R2-006 lifecycle + split-toggle assertions.
    var isAmbientActive: Bool { ambientPlayer != nil }
    var isMusicActive: Bool { musicPlayer != nil }
    var debugCurrentZone: Zone? { currentZone }
    #endif

    // MARK: - R2-006 split toggles (independent, separately persisted)

    /// Ambiance + music channel. Muting stops the music AND the per-zone bed; unmuting
    /// resumes both for the current zone.
    var ambianceEnabled: Bool {
        get { SaveGameStore.shared.ambianceOn }
        set {
            SaveGameStore.shared.ambianceOn = newValue
            if !newValue {
                stopAmbient()
                stopMusic()
            } else {
                startMusicIfNeeded()
                if let zone = currentZone {
                    let resume = zone
                    currentZone = nil
                    setAmbientZone(resume)
                }
            }
        }
    }

    /// Interaction-cue channel. Muting only silences SFX; music/ambiance are untouched.
    var sfxEnabled: Bool {
        get { SaveGameStore.shared.sfxOn }
        set { SaveGameStore.shared.sfxOn = newValue }
    }

    private init() {
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])
    }

    // MARK: - SFX

    func play(_ effect: Effect) {
        #if DEBUG
        playedLog.append(effect)
        #endif
        guard sfxEnabled else { return }
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

    // MARK: - Music (R2-004/005: user-supplied level bed, replaces ocean ambience)

    /// Starts the looping level music if it isn't already playing and ambiance is on.
    /// Idempotent — safe to call on every level entry / ambiance-unmute.
    func startMusicIfNeeded() {
        guard SaveGameStore.shared.ambianceOn, musicPlayer == nil else { return }
        guard let url = Bundle.main.url(forResource: musicResource, withExtension: "wav", subdirectory: "Audio")
            ?? Bundle.main.url(forResource: musicResource, withExtension: "wav") else { return }
        if let player = try? AVAudioPlayer(contentsOf: url) {
            player.numberOfLoops = -1   // seamless loop
            player.volume = musicVolume
            player.prepareToPlay()
            player.play()
            musicPlayer = player
        }
    }

    func stopMusic() {
        musicPlayer?.stop()
        musicPlayer = nil
    }

    // MARK: - Per-zone ambient texture (faint tint under the music)

    /// Switches to a new zone's faint texture bed. F-004 fix retained: `stopAmbient()`
    /// clears `currentZone` so re-entering a level always restarts cleanly. Also ensures
    /// the music is running (single entry point used on zone change).
    func setAmbientZone(_ zone: Zone) {
        startMusicIfNeeded()
        if currentZone == zone, ambientPlayer != nil { return }
        currentZone = zone
        ambientPlayer?.stop()
        ambientPlayer = nil
        guard SaveGameStore.shared.ambianceOn else { return }
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

    /// Full ambient + music teardown — called on every exit to menu chrome (pause ->
    /// Main Menu, completion card -> Main Menu). Neither music nor ambience may play
    /// under menus, and both must restart cleanly on re-entry (F-004).
    func stopAmbient() {
        ambientPlayer?.stop()
        ambientPlayer = nil
        currentZone = nil
        stopMusic()
    }
}
