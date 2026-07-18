import Foundation
import AVFoundation

/// Central functional-audio manager.
///
/// Build-10 audio model (cluster D + R4-002, completing the R2-024 root fix):
/// - There is NO default per-tap/navigation sound of ANY kind. Tap feedback is purely
///   visual (RoomScene.flashTapFeedback). The round-1/2 passes removed the generic
///   "psh" click but then ASSIGNED `sfx-wood` as a blanket "diegetic passage beat" on
///   every zone transition (and the drawer) — recreating a default nav sound, which is
///   exactly what the user kept hearing (R4-010/012(1)/017/027). Build 10 removes that
///   trigger class entirely and DELETES sfx-wood from the bundle so it cannot silently
///   return. Remaining cues are all EVENT-mapped and object-relevant (pickup / seat /
///   solve / unlock / door-open / page / refusal / …).
/// - Level audio is the user-supplied `music-level1.wav` ONLY (fal.ai-generated,
///   user-owned, commercial use OK — see implementation-notes licensing table), looped,
///   level-scoped (R3-001). The per-zone amb-z* texture beds and the sfx-entry swell —
///   the "ocean waves at level entry" the user reported (R4-002) — are REMOVED from
///   playback and from the bundle.
/// - R2-006: two independent, separately-persisted mutes — `ambianceEnabled`
///   (music) and `sfxEnabled` (interaction cues).
/// - R4-003: menu chrome uses ONE consistent cue — the liked Level-Select ping
///   (`menuConfirm`) — across Main Menu / Level Select / Pause / Settings / game
///   controls. The "ugly tick" `sfx-menu-tap` is retired and deleted.
///
/// All SFX are originally synthesized by tools/build_game_assets.py (+ the build-10
/// sfx-seat, same synth pipeline — no third-party audio). The music is user-provided.
final class SoundManager {
    static let shared = SoundManager()

    enum Effect: String {
        // Event-specific cues (none generic; every trigger is an object/state event):
        case pickup = "sfx-pickup"      // add-to-inventory (user likes it — unchanged)
        case wrong = "sfx-wrong"        // dull knock, failure_behavior standard
        case solve = "sfx-solve"        // puzzle-solve confirmation
        case unlock = "sfx-unlock"      // zone-unlock stone rumble
        case refusal = "sfx-refusal"    // crow terminal refusal (D3/D4)
        case clockClack = "sfx-clack"   // RETIRED (Q3: cuckoo removed); kept for compat
        case fizzle = "sfx-fizzle"      // brew failure hiss
        case page = "sfx-page"          // grimoire/triptych page turn
        case stonePress = "sfx-stone"   // rune tile press
        case tick = "sfx-tick"          // dial/clock-hand ratchet (in-world mechanisms only)
        case seat = "sfx-seat"          // build 10 R4-020(1): warm POSITIVE item-seats-in-recess cue
        case grind = "sfx-grind"        // mirror stand detent scrape
        case bellows = "sfx-bellows"    // bellows air puff (both pumps)
        case stir = "sfx-stir"          // ladle stir swish
        case cloth = "sfx-cloth"        // rug slide
        case door = "sfx-door"          // themed door-opening (R2-015a: rune door / final door)
        // R4-003: THE menu cue — the liked Level-Select ping, used consistently across
        // all menu chrome. (sfx-menu-tap — the "ugly tick" — is retired and deleted.)
        case menuConfirm = "sfx-menu-confirm"
        // Build 10 removals (cases deleted, files deleted from the bundle):
        // - sfx-wood: the surviving default nav/passage "psh" (R4-010/012/017/027).
        // - sfx-entry: the "ocean waves" swell at level entry (R4-002).
        // - amb-z1..z4: per-zone texture beds (R4-002 — level audio is music only).
        // - sfx-menu-tap: the disliked menu tick (R4-003).
    }

    private var effectPlayers: [String: AVAudioPlayer] = [:]
    private var musicPlayer: AVAudioPlayer?

    /// R3-001: level music is SCOPED to an active level scene. This is TRUE only between
    /// `enterLevel()` (level scene appears) and `exitLevel()` (back to menu / complete).
    /// Nothing may start `music-level1.wav` while it is false — so the menus / pre-level
    /// screens carry no level music (only the menu ping). `startMusicIfNeeded()` and the
    /// Settings ambiance-unmute both consult this flag.
    private var inLevel: Bool = false

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
    /// Test seams for the level-music lifecycle assertions (R3-001 / R4-002).
    var isMusicActive: Bool { musicPlayer != nil }
    var debugInLevel: Bool { inLevel }
    #endif

    // MARK: - R3-001 level-music lifecycle (music is scoped to the level scene)

    /// Called when a Level scene appears (LevelLoadingView). Marks the level active so
    /// music may play, then starts it. Idempotent. Build 10 (R4-002): this is the ONLY
    /// level-entry audio — no entry swell, no ambient bed.
    func enterLevel() {
        inLevel = true
        startMusicIfNeeded()
    }

    /// Called on EVERY exit from a level to the menu chrome (pause -> Main Menu,
    /// completion -> Main Menu, and any teardown). Clears the level scope and stops the
    /// music so the menus are music-free (R3-001).
    func exitLevel() {
        inLevel = false
        stopMusic()
    }

    // MARK: - R2-006 split toggles (independent, separately persisted)

    /// Ambiance/music channel. Muting stops the music; unmuting resumes it (in-level only).
    var ambianceEnabled: Bool {
        get { SaveGameStore.shared.ambianceOn }
        set {
            SaveGameStore.shared.ambianceOn = newValue
            if !newValue {
                stopMusic()
            } else {
                startMusicIfNeeded()
            }
        }
    }

    /// Interaction-cue channel. Muting only silences SFX; music is untouched.
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

    // MARK: - Music (R2-004/005 + R4-002: the user-supplied level bed is the ONLY level audio)

    /// Starts the looping level music if it isn't already playing and ambiance is on.
    /// Idempotent — safe to call on every level entry / ambiance-unmute.
    /// R3-001: music is level-scoped — it NEVER starts outside an active level scene, so
    /// unmuting ambiance from Settings while in the menus does not leak level music.
    /// F-004 lineage: `stopMusic()` fully clears the player, so re-entering a level
    /// always restarts the bed cleanly.
    func startMusicIfNeeded() {
        guard inLevel else { return }
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
}
