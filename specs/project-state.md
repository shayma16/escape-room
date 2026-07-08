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

## RESUME NOTE — feedback round 1 Developer batch COMPLETE, CI GREEN, PR OPEN (2026-07-08)

The resumed Developer batch is DONE. Branch `feedback-round-1` is **CI GREEN** (run
28895420694: build + unit tests × 3 device classes + UI smoke × 3 + Dynamic Island
safe-area screenshots all pass). A PR to `main` is open (do NOT auto-merge — user merges).

What landed on top of the WIP: clue-gating rev 1.3 ENFORCED (was absent from the WIP —
only the persistence substrate existed) for p01/p02/p03/p04/p14, p01 page-A REQUIRED per
the final user ruling, IC-1 re-eval + D7 persistence; `LevelSession.availableViews()`
(compile-break fix); Rev-2 chrome (§7-R1 inventory pill, §7-R2 NavChevron breathing
chevrons, §7-R3 item inspect); all invalidated tests updated + new gating tests added.
Full per-item status, judgment calls (JC-fb1-1..5), sound licensing (all synthesized-
original, nothing sourced), and the security-checklist PASS are in
`specs/levels/level-1/implementation-notes.md` ("Feedback round 1 → build 2").

NEXT (Producer): user reviews the PR; on merge → **full QA regression** (interaction +
nav + gating models changed everything; the UI full-playthrough screenshot test is a
DOCUMENTED XCTSkip awaiting QA scene-coordinate recalibration) → **checkpoint 2 user
review** → release build 2 to TestFlight. Still QUEUED: AF-1 door art fix (Asset Gen) and
JC-fb1-4 (workshop return-door art). Judgment calls needing user/Producer attention:
JC-fb1-1 (p03 has no stale-input surface for IC-1 — vacuous, noted) and JC-fb1-3
(empty-scene disarm deferred).

_Prior (now resolved) resume note — kept for history:_
Developer agent ran out of credits mid-batch. ALL its work is committed + pushed to
branch `feedback-round-1` (commit 5d90803, a WIP checkpoint) — NOT verified, NOT built,
NO CI run yet. To resume:
1. Relaunch a developer agent on branch `feedback-round-1` with take-stock instructions
   (re-read `specs/feedback-backlog.md` routed changelist + design decisions + the
   Developer's original brief). It must: verify what's done vs. the 12-point work order,
   finish the rest, ensure it BUILDS (16 Swift files changed but never compiled here),
   run the security checklist, dispatch `gh workflow run build-and-test.yml` on the
   branch, iterate to green, open a PR to main.
2. Clue-gating: puzzle-graph rev 1.3 is committed + Validator PASS is in
   `validation-report.md` — Developer implements the `clue_gate` table (persist
   clue-viewed flags in save; D6/D7).
3. Checkpoint: after CI green, run FULL QA regression (interaction + nav models changed
   everything) → user checkpoint 2 → release build 2 to TestFlight.
4. **AF-1 door fix still QUEUED** (Asset Gen): after the Developer batch settles, run the
   AF-1 ruling (see feedback-backlog "AF-1 ruling" — unify wide v-entry door to match the
   canonical close-up beak-basin). Held to avoid concurrent asset-manifest.json writes.
5. What the WIP already contains (per commit msg): select-then-tap interaction, nav,
   inventory, close-up, brew/dial UI edits; audio overhaul (quieter ambience + new
   per-object SFX sfx-bellows/cloth/entry, generic sfx-click removed); AF-2/3/4 art
   fixes; style-guide Rev-2 addendum; test edits. Unknown how complete/correct — VERIFY.
6. gh at "C:\Program Files\GitHub CLI\gh.exe"; repo PUBLIC (free CI minutes).

## QUEUED: Level 1 art rebuild → build 3 (user directive 2026-07-08)

After build 2 ships to TestFlight, redo ALL Level 1 art in the new Nano Banana Pro
engine-render style (build-1/2 art was painterly Flux, user rejected). **FULL rebuild —
NO painterly carryover** (user 2026-07-08: carrying over any old asset would look
inconsistent; the earlier "carry over glyph geometry to save money" plan is SUPERSEDED).
**Hard cap: $18.90, and not more** (raised from $10). Every visible asset is freshly
generated OR derived from a FRESH new-style base (never a painterly original). Budget
stretches via free PIL downscales + free crops/overlays *off the fresh bases* (keeps
retries affordable inside the cap). Nano Banana Pro pricing: $0.15/img std, $0.30 4K.
Full costed strategy in `specs/levels/level-1/rebuild-plan.md`. Puzzle graph / solution
values / Designer+Validator UNCHANGED — render-style swap only. Blocked on build 2
shipping (needs user checkpoint-2 GO). Still per-zone user art review before integration.
AF-1 door fix + JC-fb1-4 workshop return-door art fold into this rebuild (done in the new
style, not the old).

## BUILD 2 SHIPPED TO TESTFLIGHT + BUILD 3 REBUILD RUNNING (2026-07-08)

**Build 2 (Within 1.0, build 6) is UPLOADED to App Store Connect / TestFlight** — release
run 28916912716 green end-to-end. Took a release-workflow fix (PR #7, branch
`fix-build-number`): the app Info.plist pinned CFBundleVersion=1 so uploads collided on
"must be higher than 1"; fix stamps the real build number into BOTH the app binary AND the
.xcarchive ApplicationProperties before export. **TODO: merge PR #7 to main** (release was
run from the fix branch). User's device install + spot-check of build 2 is their
step-16 checkpoint.

**Build 3 = Level 1 full art rebuild RUNNING** (Asset Gen, branch `level1-rebuild-build3`,
$18.90 cap, new Nano Banana Pro engine style, no painterly carryover). Long multi-hour
job; delivers per-zone for user review; do NOT ship build 3 without per-zone art approval.
NOTE: while it runs, the main working tree is on `level1-rebuild-build3` — use a git
worktree for any main/release git ops (as done for PR #7) so Asset Gen is undisturbed.

## CHECKPOINT 2 STATUS (2026-07-08) — build 2 QA GO (now shipped, see above)

**Build 2 QA regression = GO** (qa-report.md "Build 2 regression": zero bugs, full
end-to-end playthrough un-skipped + GREEN, clue-gating/D6/D7/select-then-tap/nav/audio all
verified, no regressions, +new save/resume UI test). Branch `feedback-round-1` is green
(run 28903408232).

**ACTION NEEDED FROM USER: merge PR #6** (https://github.com/shayma16/escape-room/pull/6).
PR #5 was merged but only captured build-2 code up to 6c82467; it MISSED 5 later commits —
critically the **CI 90-min timeout fix** (without it main's merge CI CANCELLED at 65 min,
so **main is NOT currently green**), plus the QA GO report, the Nano Banana art-model
switch, and the rebuild plan/budget. PR #6 brings all 5 to main. Sequence: merge PR #6 →
confirm main CI green → release build 2 to TestFlight (release.yml, macos-26/Xcode 26,
Admin ASC key already set) → then Level 1 rebuild (build 3, $18.90 cap, see QUEUED
section above).

Known non-blocking carry-forwards into/after build 2: QA-OBS-023 (CI screenshots render
rotated/letterboxed — screenshot fidelity only, not a play defect; real-device is the
user's TestFlight spot-check); F-010/AF-1 door art NOT fixed in build 2 — deliberately
folded into the build-3 full rebuild instead of patching painterly art.

## Pipeline position

**POST-RELEASE FEEDBACK ROUND 1 → BUILD 2 IN PROGRESS (2026-07-07).** User tested build 1
on TestFlight (iPad Pro) and reported 25 items (`specs/feedback-backlog.md`); intake
processed, clustered, routed; both user checkpoints observed (checkpoint 1 = routed batch
review PASSED with design decisions; checkpoint 2 = QA regression review, still upcoming).

User-approved design decisions this round:
- **Clue-gating** (F-012): puzzle inputs inert until their clues are viewed in-game.
  Puzzle-graph **rev 1.3** (Designer) — VALIDATED PASS (difficulty holds 6.0, no
  soft-locks). **p01 gates on grimoire page A = REQUIRED, FINAL user ruling** (overrode
  a Designer+Validator advisory to demote it; do not revert). This is now a **standing
  design rule for all future levels** — Level 2's Designer must apply clue-gating from
  the start (amends CLAUDE.md principle #4 at the puzzle-input level; branches/order-free
  state model otherwise unchanged). TODO: formalize in CLAUDE.md when convenient.
- **Select-then-tap interaction** (drag + passive auto-apply removed) — neutralxe model.
- **Sound overhaul** game-wide (generic "psh" gone; per-object or silence; pickup sound
  kept), quieter ambience, and audio-lifecycle fix.
- Inventory reachable in every close-up + item-inspect; nav model = chevrons cycle VIEWS
  within a zone (zone changes only via diegetic passages); chrome restyle per style-guide
  §7 Rev-2 addendum (Art Director). Manual pickup from solved containers.

RUNNING: Developer fix batch (branch `feedback-round-1`) + Asset Generation art fixes
(AF-1..AF-4). DONE: Designer rev 1.3, Validator PASS, Art Director §7-R addendum.
NEXT: Developer integrates gating (polling for rev-1.3 PASS — now satisfied) → green CI →
full QA regression (interaction + nav models touch everything) → **checkpoint 2 user
review** → release build 2 to TestFlight.

_Two items NOT changed (working as designed):_ F-008 clock cuckoo (one-shot flavor, D5),
and rune-door-before-flowerpot was a valid alt path (now moot under gating).

---

_Prior:_ **RELEASE STAGE (TestFlight-only) — BUILD UPLOADED TO TESTFLIGHT 2026-07-07.** Within
1.0 (build from release run 28822356309) archived, cloud-signed, security-scanned
(clean), and uploaded to App Store Connect successfully. Repo is now PUBLIC (user
choice — free Actions minutes, removed the GitHub-billing spend block that stopped the
first dispatch; history pre-scanned, no secrets ever committed).

Two CI fixes were needed during the release run and are captured for reuse:
(1) ASC API key must be **Admin** role, not App Manager — App Manager can't create the
distribution cert via cloud signing (export failed "Cloud signing permission error");
user regenerated the key as Admin. (2) Release must build on **macos-26 / Xcode 26** —
Apple rejects uploads built with <iOS 26 SDK; macos-15/Xcode 16 failed at upload
validation. Fix in PR #4 (https://github.com/shayma16/escape-room/pull/4), verified
green end-to-end on branch `fix-xcode26-release`. build-and-test.yml stays on macos-15
(simulator only, no upload SDK gate).

**Awaiting user:** (a) merge PR #4 so main carries the working release workflow; (b) in
App Store Connect: wait for the build to finish "Processing," create a TestFlight
internal testing group, add self as tester, install via the TestFlight app. That device
install IS the step-16 physical-device spot-check + final release approval (user's
checkpoint). Full record in `specs/release-notes.md`.

_Phase-1 prep record:_ App identity **Within / com.shayma.within**; PR #3 (merged,
be77e99) did the rename + ITSAppUsesNonExemptEncryption=false + real release.yml.

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
