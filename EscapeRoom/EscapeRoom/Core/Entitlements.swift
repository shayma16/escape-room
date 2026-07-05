import Foundation

/// Structured for future IAP without rearchitecting: every level access check goes
/// through this single entitlement gate. Today it always returns true (free app,
/// no purchases at launch) — see CLAUDE.md fixed decision "free, no IAP at launch."
/// When IAP ships, only this type needs to change.
enum Entitlements {
    /// Returns whether the given level id is unlocked for play.
    /// Currently: always true. Replace with a real purchase/unlock check when IAP
    /// is introduced; callers never need to change.
    static func isLevelUnlocked(_ levelID: Int) -> Bool {
        true
    }
}
