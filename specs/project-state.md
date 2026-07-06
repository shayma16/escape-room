# Project State

_Maintained by the Producer. Updated after every pipeline stage._

## Current phase

Level 1 in design. Theme received from user on 2026-07-04.

## Active level

Level 1 — "Wizard's cabin": abandoned wizard's cabin in the woods, gloomy atmosphere,
caged crow, potions/potion-making (user-specified elements).

## RESUME NOTE (2026-07-06, written pre-session-limit by the Producer)

If the session is cut off, resume by taking stock — don't restart:
1. `git log`/`git status` + `gh run list` (gh.exe at "C:\Program Files\GitHub CLI\gh.exe";
   check the latest run on branch `qa-fix-pass-level-1`) + the section below.
2. Background-agent transcripts do NOT survive session-limit cutoffs — relaunch agents
   fresh with take-stock instructions rather than assuming SendMessage resume works.
3. Position: Developer QA-fix pass + BUG-004 integration complete (see below); if the
   post-integration CI run isn't green yet, relaunch a developer agent to diagnose and
   finish. Once green: re-QA (step 12, fresh qa-tester agent; prior report + suite
   exist) → step-13 user go/no-go → Documentation second pass (step 14).
4. Waiting on the user: merge of PR #1 (https://github.com/shayma16/escape-room/pull/1).
   The Producer session can push to `qa-fix-pass-level-1` (not needed for main).
5. Flux spend to date: $8.63 (progression-ledger.md). BUG-004 re-frame batch: 11/11
   done, verified, HOLD cleared.

## Pipeline position

**RELEASE STAGE (TestFlight-only scope) — phase 1 PREP COMPLETE 2026-07-07.**
App identity: **Within / com.shayma.within** (locks at first ASC upload). PR #3
(https://github.com/shayma16/escape-room/pull/3): bundle-id/display-name rename,
ITSAppUsesNonExemptEncryption=false, real release.yml (cloud-managed signing via ASC
API key, native xcodebuild export/upload, blocking .ipa security gate). Full record +
user to-do in `specs/release-notes.md`. Awaiting user: merge PR #3 + Apple account
steps 1–4 (register bundle ID, create ASC API key, create app record, gh secret set
ASC_KEY_ID/ASC_ISSUER_ID/ASC_KEY_P8/APPLE_TEAM_ID). Then phase 2: dispatch
release.yml, monitor, verify security gate + upload, hand off for device install
(step-16 user spot-check).

_Prior:_ **LEVEL 1 COMPLETE (2026-07-06) — PR #2 merged 2026-07-07 (commit 0462cb1).
Was: pending one user click: merge of PR #2
(https://github.com/shayma16/escape-room/pull/2, polish carry-forwards incl. crow
lintel perch, CI green run 28817697097).** Step 14 done: walkthrough reconciled FINAL
(14 divergences fixed, commit 1aa76d3); polish batch complete on branch
`polish-carry-forwards` (QA-OBS-023 landscape harness, UI-test waits, 3 screenshot
gaps, moonbeam seam, BUG-015 pixel pass, lintel-perch nudge). **Next: user provides a
Level 2 theme (pipeline step 1) or declares Release stage** (which additionally needs:
Apple Developer enrollment, signing secrets via gh secret set, app name/bundle id —
see Blockers).

_Step-13 record:_ **USER CHECKPOINT: re-QA go/no-go — GO (user, 2026-07-06). QA had recommended GO.**
Re-QA verification pass complete 2026-07-06 (qa-report.md "Re-QA verification pass"
section, commit 798867d): 22/22 bug fixes verified (70 unit tests × 3 devices, 0
failures; all 10 former expected-failure records now permanent passing assertions);
BUG-004 elements visually confirmed on-screen on iPad via playthrough screenshots;
main-branch playthrough-test failure ruled ENVIRONMENTAL (rerun green — 3 passes of
identical content; recommend raising first-interaction UI-test timeouts). New
non-blocking finding QA-OBS-023 (medium): CI simulators compose the app
non-full-screen/portrait in UI tests — screenshot presentation artifact, not an app
bug; Developer should set landscape in UI-test setUp + assert window bounds; real
presentation confirmed at step-16 device check. Other carry-forwards (non-blocking):
UI-test wait robustness, 3 screenshot-coverage gaps (refusal pose, recipe, triptych —
logic unit-verified), moonbeam overlay seam (cosmetic), BUG-015 pixel-perfect polish.
**On user GO: Documentation second pass (step 14) + optionally a small Developer
polish batch for the carry-forwards.**

_Prior position:_ **Step 11/12 loop — Developer QA-fix pass COMPLETE incl. BUG-004 art integration
(2026-07-06); awaiting CI re-verification + user merge of PR #1.** All 22 QA bugs are
now addressed: the 21 Developer-scoped fixes (close-up/inspection layer, astrolabe
mini-game, rug-discovery beat, item-combination UI, exact drag-drop conversion,
bundle-resource folder-ref fix, engine guards, navigation/root fix, state visuals)
went green on CI first (run 28770154060), and after the Asset Generation agent's
BUG-004 re-frame batch completed (11/11 + verification, $0.11), the Developer staged
the 25 re-framed plates into the bundle (validated .NET port of the PIL staging
pipeline), re-aligned all affected hotspots to the manifest's `bug004_reframe`
geometry, unwrapped the last QA expected-failure record (`testQA_BUG_004`), and
enabled the full playthrough UI test on iPad. All 10 QA bug records are now permanent
assertions. Developer security checklist (no bundled secrets; zero permission
strings/entitlements) recorded in implementation-notes.

**CI:** pre-integration green run
https://github.com/shayma16/escape-room/actions/runs/28770154060; the post-integration
run link is recorded in `specs/levels/level-1/implementation-notes.md` ("CI (this
pass)"). **Merge to main is the user's click:** PR #1
https://github.com/shayma16/escape-room/pull/1 (the Developer session's permission
mode blocks direct pushes to origin/main).

Per-bug detail + judgment calls 10–18 + the BUG-004 integration record in
`specs/levels/level-1/implementation-notes.md`.
Next: user merges PR #1 → re-QA (step 12) → step-13 user go/no-go.

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
