# Project State

_Maintained by the Producer. Updated after every pipeline stage._

## Current phase

Level 1 in design. Theme received from user on 2026-07-04.

## Active level

Level 1 — "Wizard's cabin": abandoned wizard's cabin in the woods, gloomy atmosphere,
caged crow, potions/potion-making (user-specified elements).

## Pipeline position

**Step 11/12 loop — Developer QA-fix pass IN PROGRESS (2026-07-06).** User approved a
full fix pass on the 22 QA bugs. Developer has implemented fixes for all
Developer-scoped bugs (21 of 22 fully; QA-BUG-004 hotspot alignment deferred by design
pending the Asset Generation agent's concurrent art re-frame batch — 0/11 done at
Developer handoff; Developer owns the final integration step when it lands). Includes
the new close-up/inspection layer, astrolabe mini-game, rug-discovery beat,
item-combination UI, exact drag-drop conversion, bundle-resource fix (folder refs),
a new XCUITest full-playthrough target with screenshot artifacts, and a Dynamic Island
device added to the CI matrix. 9 of QA's 10 expected-failure bug records unwrapped into
permanent assertions (BUG-004's stays wrapped). Per-bug detail + new judgment calls
10–18 in `specs/levels/level-1/implementation-notes.md` ("QA fix pass" section).
Next: CI green → re-QA (step 12) → step-13 user go/no-go.

_Prior position:_ **Step 13 — USER CHECKPOINT: QA go/no-go review — resolved 2026-07-06
as "full fix pass approved" (with BUG-004 = art re-frame, run concurrently).** QA stage (step 12) completed
2026-07-05: `specs/levels/level-1/qa-report.md` delivered (commit 7fd5372) with QA test
suite `EscapeRoom/EscapeRoomTests/QALevelFlowTests.swift` (57 tests × 2 simulators,
green run https://github.com/shayma16/escape-room/actions/runs/28745951536, incl. 10
strict expected-failure `testQA_BUG_*` records that flip loudly when each bug is fixed).

**QA recommendation: NO-GO.** Engine layer is a faithful graph implementation (all 3
example orderings incl. mirror-first C, all failure behaviors, D1–D5, all anti-softlock
invariants pass), but the interaction/presentation layer is unfinished: level currently
uncompletable in-app by any path (22 bugs: 7 critical / 8 major / 4 moderate / 3 minor).
Headline criticals: game art unreachable in app bundle (BUG-022, black scenes); z1 never
unlocked from fresh save (001); no UI path for p12/p15/p17 (012/002/003); close-up/clue
layer entirely missing (013); iPad 4:3 crop pushes p11 keyhole + feed cup off-screen
(004 — needs a CROSS-AGENT decision: approved art plates place critical elements outside
the style-guide §8 dual-safe zone; fix = art re-framing vs hotspot relayout vs display
policy; may loop in Art Director/Asset Gen, not just Developer).

Judgment-call verification: hotspot rects FAIL (004/009/015); tap-placeholder controls —
semantics PASS, interaction shape defective (006/010/011); vine mid-state unwired PASS;
drag-drop conversion FAIL systematic (014); J5 no-confirm exit premise HOLDS.

Awaiting user: (a) go/no-go on routing the 21 Developer-scoped bugs back to the
Developer (QA's suggested fix order in report: bundle assets first), and (b) the
BUG-004 cross-agent decision. After fixes → re-QA → step 13 again → Documentation
second pass (step 14).

_Prior stage summary:_ **Step 11 — Developer stage COMPLETE, green CI.** All approvals landed 2026-07-05: z3+z4
batch (F11 diagonal beam, F12 fogged moon, F15 flower shift, F17 icon cleanup — all
accepted) → LEVEL 1 ART COMPLETE ($8.11). global-ui-style.md approved as recommended
(J1 serif accent, J2 dark-only, J3 thumbnail cards, J4 keyhole motif, J5 no-confirm
Main Menu exit w/ Developer verification duty, J6 LANDSCAPE-LOCKED — now a fixed
decision in CLAUDE.md). Asset Gen COMPLETE: app icon + launch screens delivered ($0.41;
art grand total $8.52; user shown previews, no objection).

Developer Agent implementation finished 2026-07-05: full Xcode project (SpriteKit
rooms + SwiftUI chrome), requirement-based puzzle state machines for all 17
puzzle-graph nodes, zone-unlock logic for both nested hidden zones, save/resume
persistence, one-time global UI chrome, and synthesized (original, no third-party
license needed) SFX/ambient audio. Unit tests (29 cases) cover inventory,
zone-unlocks, the order-independent beam condition (D2), brew/endgame state machines,
and save/restart/reset. **`build-and-test.yml` is GREEN**: build + unit tests pass on
both a 12.9"/13" iPad Pro simulator and an iPhone SE simulator
(https://github.com/shayma16/escape-room/actions/runs/28745052491). Getting to green
required several CI-only fixes not visible from local inspection (all documented in
`specs/levels/level-1/implementation-notes.md`): a stray literal quote breaking the
workflow YAML entirely, an invalid `../Resources` path in a synchronized asset group,
replacing Xcode's newer file-system-synchronized-groups mechanism with traditional
explicit file references for compiled Swift sources (the synchronized-groups scheme
resolved zero simulator destinations for unclear reasons), pinning-related simulator
platform support gaps (fixed by using the runner's default Xcode instead of an
explicitly side-installed version), a serial-queue self-deadlock risk in
`SaveGameStore`, and 3 unit tests that omitted a required zone-unlock precondition.

Full judgment-call list (hotspot rect placement, moon-dial/brew interaction shape,
vine mid-wither state, drag/drop coordinate conversion, etc.) is in
`specs/levels/level-1/implementation-notes.md` for Producer/user review before QA.

**Next:** step-12 QA (simulator via CI artifacts) → step-13 user go/no-go →
Documentation second pass.

## Security posture note (user directive 2026-07-06)

No dedicated Security Review agent for now: the app has no backend, no user accounts,
and no web views, so the attack surface is limited to the two checks folded into the
existing agents (Developer: no dev-time secrets bundled + minimal entitlements;
Release Manager: independent re-check of both on the archived .ipa as a final
pre-submission gate — see the two agent definition files). **Revisit and add a
dedicated Security Review agent if any of these are ever introduced: cloud saves,
user accounts, IAP, or embedded web content.**

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
