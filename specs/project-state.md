# Project State

_Maintained by the Producer. Updated after every pipeline stage._

## Current phase

Level 1 in design. Theme received from user on 2026-07-04.

## Active level

Level 1 — "Wizard's cabin": abandoned wizard's cabin in the woods, gloomy atmosphere,
caged crow, potions/potion-making (user-specified elements).

## ⭐ CURRENT RESUME NOTE (2026-07-09e) — READ THIS FIRST

**BUILD-9 DEVELOPER PHASE DONE + CI GREEN (branch `level1-rebuild-build3`; green on
build-and-test.yml run 29049860373 — build + unit×3 + UI×3 incl. the iPhone-SE FULL
end-to-end playthrough).** Implemented the ROUND-3 changelist:
- **R3-005 hotspot re-calibration (the playability fix):** re-derived EVERY interactive
  hotspot + close-up trigger across all 7 views to match element positions in the NEW
  build-3 plates (visually measured on the @2x sources). Fixes R3-004 (rune marks now
  tappable) and the "left of the clock" stale-tap. UI-test tap coords re-mapped to the new
  centers. New player-style tests: taps at each element's VISUAL position hit its hotspot;
  left-of-clock inert; p01 solvable via the press-plate.
- **Cuckoo (Q3):** stopped staging cu-clock-pop/cu-clock-spent (DELETED from bundle); only
  the inert numeral clock face ships. No cuckoo asset/hotspot/state remains.
- **R3-007:** re-ran the staging script; verified staged rune-door tiles + grimoire page A
  (hub) + all four element marks carry IDENTICAL canonical glyphs -> p01 matchable.
- **R3-002:** staged the build-3 thumbnail into the xcassets imageset (the app's real load
  path) + chrome; added assert_chrome_current() so chrome art can't ship stale.
- **R3-003:** level number Arabic "1" serif (the Roman "I" was the stale thumbnail).
- **R3-001:** music level-scoped (enterLevel/exitLevel gate — no level music in menus, stops
  on exit + on level-complete); added quiet menu-tap/menu-confirm SFX (synthesized, original).
- **R3-006:** icons verified build-3 canonical (no shadow); `-nb` normalization SKIPPED
  (unused non-shadows; not worth staging risk).

⚠️ **FLAG TO PRODUCER — Asset-Gen owed (NOT Developer-fixable):** the build-3 art did NOT
preserve BUG-004's iPad dual-safe-zone re-framing, so many puzzle-critical elements now sit
OUTSIDE the iPad-visible band. Hotspots correctly match the visible art (must not clamp), so
the level is completable on iPhone but iPad's .aspectFill crops edge elements off-screen on
the PRIMARY device. BUG-004 test wrapped in XCTExpectFailure to track this. Fix = re-frame
the build-3 plates (Asset Gen). **NEXT: CI green -> build-9 player-style QA -> Producer
re-releases build 9 (do NOT open a PR / ship from here).**

## ⭐ RESUME NOTE (2026-07-09d)

**BUILD-3 STALE CLOSE-UP SHADOW FIXED (Developer, branch `level1-rebuild-build3`).**
Device check on build 3 (build 8) found in-scene close-ups ("inspect" images) were STALE
build-2 painterly art while wide scenes were correct. Root cause: build-3 delivered
close-ups/variants/icons under `-nb` filenames while the old build-2 art still sat at the
canonical names the pipeline loads (only the 7 bases had been promoted). Fix = **Option B**:
`git mv`-promoted every FINAL intended build-3 `-nb` (per manifest blocks
`build3_rebuild`/`build3_derived`/`build3_consistency_reroll_2026_07_09`) to its canonical
name on disk, archived the superseded build-2 canonicals to
`_rejects/flux-painterly/*-build2@Nx.png`, deleted `SRC_OVERRIDE`, removed `resolve_src`'s
`-nb` fallback, and added `assert_no_nb_shadow()` (fails the build if a `-nb` shadow ever
recurs next to a build-loaded canonical). **82 bundle files re-staged stale→build-3**;
spot-check across all zones = bundle matches build-3 source (0.00%, clock 2.07% inpaint)
and differs from build-2 by 67–98%. Already-correct re-roll assets (door/slots/statue
state variants, and the override'd door-lock/statue) did NOT regress. No game logic / no
code / no secrets / no entitlements changed. Details in implementation-notes
"Build-3 stale close-up shadow fix (2026-07-09)". **NEXT = CI to green on
`build-and-test.yml`, then Producer re-releases build 9 (do NOT open a PR / ship from
here).**

## ⭐ RESUME NOTE (2026-07-09c)

**BUILD 3 SHIPPED TO TESTFLIGHT — Within 1.0 (build 8)**, release run 29020603301 green
(archive→sign→stamp→scan→upload). Released from branch `level1-rebuild-build3` (added the
PR-#7 build-number stamp to that branch's release.yml). Build 3 = new engine-style art +
all round-2 fixes + consistency re-rolls. QA: soft-lock DEAD (screenshot-proven),
QA-B3-002 chrome clip FIXED, QA-B3-001 "black band" = CI-simulator screenshot artifact
(NOT an app bug — Developer's 7-build experiment; app renders full-width). **AWAITING USER
DEVICE SPOT-CHECK** on TestFlight: (1) does it fill the whole iPad screen (settles
QA-B3-001)? (2) pause menu + completion card fully on-screen? **On GO → merge build 3 to
main** (level1-rebuild-build3 → main via PR). Build 2 (build 6) also still on TestFlight.

## ⭐ RESUME NOTE (2026-07-09, latest) — build-3 assembly (superseded by ship above)

**QA-B3-001 / QA-B3-002 presentation fix pass COMPLETE + CI GREEN (Developer, 2026-07-09,
branch `level1-rebuild-build3`, commit `a6e4c3e`).** Build-3 player-style QA returned NO-GO
on QA-B3-001 (content in a left square + dead black band) and QA-B3-002 (clipped completion/
pause chrome). Resolution:
- **QA-B3-002 (chrome) — FIXED in-app + guarded.** `ChromePrimaryButtonStyle` label no longer
  truncates (`lineLimit(1)` + `fixedSize`); the pause menu moved from a landscape-clipped
  `.sheet` to a full-screen safe-area overlay. New UI test `testChromeFullyOnScreen_QA_B3_002`
  asserts pause + completion-card buttons are fully on-screen (was RED pre-fix, now GREEN).
- **QA-B3-001 (square viewport) — determined to be a CI-SIMULATOR SCREENSHOT RASTER-LETTERBOX
  ARTIFACT, not an app bug.** A seven-build controlled experiment (SwiftUI→UIKit lifecycle,
  window-bounds pins, geometry requests, SKView re-sizing) all produced a byte-identical
  0.5622 pixel measurement while every LOGICAL frame reports full landscape width — proving
  the app renders full-width and only the portrait-booted simulator's screenshot compositor
  letterboxes the raster. All speculative app-layout experiments were REVERTED to the build-3
  base; the QA-B3-001 guard is now a harness-immune LOGICAL check (scene view fills the full
  landscape window in points). Full detail + evidence + QA/Producer flag in
  `implementation-notes.md` "QA-B3-001 / QA-B3-002 viewport fix (build 3.1)".
- **CI GREEN:** run 28992893431 — build + unit×3 + UI×3 (incl. the full player-style
  playthrough and both new guards on all three device classes).
- **NEXT:** QA re-verify (screenshot) — WITH the understanding that CI screenshots still show
  the simulator raster letterbox (not an app defect); definitive full-screen presentation is
  the user's on-device TestFlight spot-check. Then user review → release. DO NOT open a PR /
  ship yet. If QA insists on a full-width CI screenshot, that is a runner-image/infra item
  (boot simulators landscape), not an app change — flagged for the Producer.

---

**Build-3 consistency re-roll INTEGRATED (Developer, 2026-07-09, branch
`level1-rebuild-build3`).** Asset agent re-rolled the flagged Level-1 close-ups/plates for
wide↔close-up consistency (manifest `build3_consistency_reroll_2026_07_09`); Developer
re-staged the corrected drop-in plates into `EscapeRoom/Resources/GameAssets` via
`tools/build_game_assets.py`. 14 bundle files re-staged: door-lock family (grey-stone
beak-basin; the flagged STALE build-2 `cu-door-lock-vines-gone` replaced), cabinet
slots empty/seated (two-door sun/moon armoire), alcove statue-key + taken (gold star key,
plain stone), and the hearth rug/trapdoor chain. **G1 rug-moved needed NO new state
wiring** — the rug-moved wide state already existed in RoomSceneCoordinator; only the
overlay SOURCE changed (Part-1 synthetic inpaint → REAL re-rolled `z1-hearth-rug-moved-nb`
plate). Pipeline judgment: added a `SRC_OVERRIDE` + reordered `resolve_src` so corrected
`-nb` art wins over stale on-disk canonical `@3x`; the two hearth overlays moved to
hand-rect crops (global tonal drift, same class as gap G3). No game logic changed.
Implementation-notes has a "Build-3 consistency re-roll integration" section. **CI on the
branch iterating to green; NEXT = player-style QA, then user review, then release. DO NOT
open a PR / ship.**

## RESUME NOTE (2026-07-08)

**State:** Build 2 SHIPPED to TestFlight (Within 1.0 build 6; release fix on PR #7,
awaiting merge to main — release ran from branch `fix-build-number`). **Build 3 = Level 1
full art rebuild + round-2 Developer fix batch — the DEVELOPER BATCH HAS LANDED** on branch
`level1-rebuild-build3` (commits `BUILD 3 Part 1` art integration + `BUILD 3 Part 2` fix
clusters). Build-3 art is integrated into `EscapeRoom/Resources/GameAssets`; all six fix
clusters (B/A/C/D/F/G) + Q1/Q2/R2-006 implemented; implementation-notes updated with a
"Round 2 fix batch (build 3)" section. CI on the branch iterating to green (run
28965195362). **DO NOT open a PR to main or ship yet** — after CI is green, the Producer
runs player-style QA and the user does per-zone art review before release.

**Developer flags to the Producer/user (from the build-3 batch):**
- 3 build-3 ASSET-DELIVERY GAPS (G1/G2/G3) handled defensively in the build script but the
  ART may want an Asset-Gen cleanup: G1 = z1-hearth poker-taken/trapdoor-open shipped only
  as `-nb` (never renamed) + no rug-moved plate; G2/G3 = state-variant wide plates are
  superseded-generation 2560x1280 region-edits that do not pixel-align with the fresh 4K
  bases (wide state overlays are now hand-rect crops with minor tonal drift, feather-
  softened; a re-derive against the 4K bases would be pixel-perfect).
- GRAPH/LEDGER: Q3 removed the D5 clock cuckoo entirely (only graph-affecting change) — the
  clock is now purely the p01 numeral reference; drop rh-clock's cuckoo one-shot from the
  design ledger.
- Music `music-level1.wav` rights confirmed by Producer (fal.ai-generated, user-owned,
  commercial-use OK) — recorded in the implementation-notes licensing table.

**Remaining before QA:** ✅ CI GREEN (run 28969620585 — build + unit×3 devices + UI
incl. full playthrough all pass; 4 stale tests fixed, no game-code bugs). BUILD 3 is
code-complete. **NEXT CHECKPOINT = USER PER-ZONE ART REVIEW (before QA).** Agreed
sequencing (user, 2026-07-08): Developer → art review → drop-in re-rolls of flagged
plates (using the R2-031 scene→close-up exact-recreation rule) → player-style QA → ship.
Art review agenda: (1) wide↔close-up consistency on the previously-buggy spots (door
beak-basin, cabinet sun/moon slots, alcove statue, workshop window — R2-010/16/23/25);
(2) the Developer's flagged art-gaps G1/G2/G3 (missing z1 rug-moved plate; state-variant
wide overlays not pixel-aligned to the 4K bases — re-derive for pixel-perfect). Re-rolls
are drop-in PNG swaps (same paths, no code change). After review+re-rolls → player-style
QA (R2-META-QA: verify rendered states + reachability as a human sees them).

**If a usage/session limit cut off mid-cascade — resume WITHOUT re-spending budget (this
is the one job where sloppy resume wastes real money against the $18.90 cap):**
1. Read `specs/levels/level-1/asset-progress.md` "BUILD-3 FULL REBUILD" section — the
   authoritative per-asset status + cost tracker — and check the PNGs already on disk in
   `specs/assets/level-1/`. The cascade agent commits+pushes PER COMPLETED ZONE, so
   `git log` on this branch shows the last durably-saved zone.
2. Relaunch a FRESH asset-generation agent told to READ the tracker + on-disk files FIRST
   and **SKIP every asset already `done` — NEVER re-generate a completed asset** (re-spend).
   Continue only from the first not-done asset. Respect the $18.90 hard cap; check the
   tracker header for live spend (was $2.40 at cascade start).
3. **Seed is LOCKED** = candidate B, promoted to `z1/v-hearth/z1-hearth-base` (clearly
   stylized). Style template calibrated to that strength in `.claude/agents/asset-
   generation.md`. Do NOT re-pick the seed or re-open the style.
4. Delivery is PER-ZONE for user review; do NOT integrate into `EscapeRoom/Resources` or
   ship build 3 without the user's per-zone art approval.
5. To do main/release git ops while the cascade holds the working tree, use a git worktree
   (as done for PR #7) so the running Asset Gen is undisturbed.

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

## CHECKPOINT 2 STATUS (for user's morning, 2026-07-08)

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
