# Project State

_Maintained by the Producer. Updated after every pipeline stage._

## Current phase

Level 1 in design. Theme received from user on 2026-07-04.

## Active level

Level 1 — "Wizard's cabin": abandoned wizard's cabin in the woods, gloomy atmosphere,
caged crow, potions/potion-making (user-specified elements).

## Pipeline position

**Step 11 — Developer stage RUNNING.** All approvals landed 2026-07-05: z3+z4 batch
(F11 diagonal beam, F12 fogged moon, F15 flower shift, F17 icon cleanup — all
accepted) → LEVEL 1 ART COMPLETE ($8.11). global-ui-style.md approved as recommended
(J1 serif accent, J2 dark-only, J3 thumbnail cards, J4 keyhole motif, J5 no-confirm
Main Menu exit w/ Developer verification duty, J6 LANDSCAPE-LOCKED — now a fixed
decision in CLAUDE.md). Asset Gen COMPLETE: app icon + launch screens delivered ($0.41; art grand total $8.52;
user shown previews, no objection). Developer stage IN PROGRESS.

**RESUME NOTE (2026-07-05, session ended mid-Developer-run):** the user shut down while
the Developer agent was mid-implementation. Working-tree state at commit time: partial
`EscapeRoom/` Xcode scaffold + `tools/` committed as-is — NOT yet a green CI build, no
implementation-notes doc yet. On resume (open session in the project directory):
1. Inspect `EscapeRoom/` + `tools/` + git log to see how far the Developer got.
2. Relaunch the developer agent with the same full brief (puzzle-graph rev 1.2 incl.
   D1=block + D2–D5, asset manifest incl. `global` key, style-guide UI portion,
   global-ui-style.md with rulings J1–J5, LANDSCAPE-LOCKED, F7/F8/F13/F14 integration
   notes, A5/R5 dial ≥30% iPhone width, SFX licensing rules, GitHub Actions build via
   gh.exe at "C:\Program Files\GitHub CLI\gh.exe", progress labels in shell
   descriptions), instructing it to take stock of the partial scaffold and continue —
   not restart.
3. Pipeline after Developer: step-12 QA (simulator via CI artifacts) → step-13 user
   go/no-go → Documentation second pass.

## Blockers / open questions

- fal.ai API key not yet provided (needed before the Asset Generation stage, not before).
- ~~Xcode/macOS build environment~~ RESOLVED 2026-07-04: no local Mac — all
  `xcodebuild`/`xcrun simctl` work runs on GitHub Actions macOS runners. Repo:
  https://github.com/shayma16/escape-room (private). Workflows scaffolded:
  `.github/workflows/build-and-test.yml` (Developer/QA) and `release.yml` (Release
  Manager); placeholder steps to be filled in once an Xcode project exists. Note:
  macOS runners bill at 10x minutes on private repos.
- Signing material (distribution cert, provisioning profile, ASC API key) not yet stored
  as encrypted GitHub Secrets (needed before the Release stage; secret names are listed
  in `release.yml`'s header comment — user creates them via `gh secret set`, never
  pasted in chat or committed).
- Apple Developer Program enrollment not yet done (needed before the Release stage; user
  enrolls and authenticates themselves — agents never touch Apple credentials).
- App name / bundle identifier undecided (needed at Release-stage metadata prep).

## Parallel one-time track: global UI chrome (added by user 2026-07-05)

Theme-independent menu layer (Main Menu, Level Select w/ completion indicators, Pause
Menu, Settings) — identical across all levels, flat/system styling OK, SF Symbols for
menu icons, custom art only for app icon + launch screen. Scope added to
art-director.md / asset-generation.md / developer.md agent definitions.
Sequence: `specs/global-ui-style.md` DELIVERED 2026-07-05 → **USER APPROVAL PENDING**
→ app icon + launch screen generation (Asset Gen) and SwiftUI implementation
(Developer). Direction: "picture frame, not picture" — flat matte neutrals (#101010 /
#1C1C1E), one saturated color (system red, Reset only), SF Pro + New York accents,
capsule buttons, checkmark-badge completion (shape+position, not color), keyhole
identity motif. Six judgment calls await user (doc Section 12): J1 serif accent,
J2 dark-only, J3 thumbnail cards, J4 keyhole motif, J5 no-confirm Main Menu exit
(Developer must verify no transient-state loss), J6 LANDSCAPE-LOCK is an undocumented
assumption needing explicit confirmation. Does not touch or block the Level 1 pipeline.

## Queued

1. Level 1: design → validation → user checkpoint (in progress).
