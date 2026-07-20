# Project State

_Maintained by the Producer. Updated after every pipeline stage._

## Current phase

**Level 2 in design.** Theme received from user 2026-07-18. Level 1 COMPLETE and merged to
main (PR #8, 2026-07-18) — shipped as TestFlight "Within 1.0 (14)", user-verified.

## Active level

Level 2 — "The Clockmaker's Attic": mechanical/time-based puzzles (user-specified
elements: gear ratios, clock hands as clues, time zones, Roman numerals; designer free to
add theme-fitting puzzles). Branch: `level2-clockmakers-attic` off main @ b38bc9c.
Pipeline position: step 4 CHECKPOINT COMPLETE (2026-07-18) -> rev 1.2 in progress.

**Design status:** graph rev 1.1 validated PASS-WITH-CHANGES (fix applied); official
difficulty 6.5 (z1 5.5 / z2 7.0 / z3 7.0 / z4 3.5). USER CHECKPOINT RULINGS: #1 OVERRULED
IIII convention -> use standard IV (design change); #2 arithmetic peak RATIFIED; #3 p06
ungated RATIFIED; #4 12-hour wrap RATIFIED; #5 mirror trap KEEP with documented easing
valve reserved (user will judge on play); #6 pictograms fine + DUBAI MUST be a landmark
city ("for authenticity"), Tel Aviv/Tehran/Riyadh EXCLUDED, rest designer's choice (may
move the vault code — permitted pre-art); #7 pry-sweep gating ACCEPTED pending playtest.
Rev 1.2 DONE + delta-validated PASS (code VI-X-I-III confirmed; official 6.5: z1 5.0/z2 7.0/
z3 7.0/z4 3.5; ledger row added). Blind layout WRITTEN + Producer leak-checked + committed
(survived a session-limit cutoff mid-agent; file was complete). **Blind Playtester RUNNING**
(2026-07-18, isolation: blind-layout.md only) with 3 scripted variant passes: impatient
pryer (flag-7 elimination-memory probe), math-averse brute-forcer (p06 tedium), hasty
reader (mirror trap recovery). Playtest DONE: READY-WITH-TWEAKS -> 3 tweaks user-approved
-> rev 1.3 (D10 faint-tell, mouse tell, D11 ambient), delta-validated PASS, A1 RESOLVED,
A3 quote fix applied. Walkthrough DRAFT done (flags: p08 mouse-at-drum dead spec text —
Developer must NOT build; naive-4:40 derivation to re-verify at second pass).

**STEP-8 STYLE CHECKPOINT APPROVED (2026-07-18).** Style guide committed: "one held minute
of golden hour", one-sun continuity rule; scope 7 wides / 25 close-ups / 12 cutouts /
2 canonical sheets / ~46 crop edits / ~12 sprites, zero planned re-rolls; A2 resolved
(Big Ben clock-face stage vs Burj monotonic taper). USER RULINGS: F1 display-case
paint-over YES; F2 KEEP the L1 rune as the series-wide pause glyph (no new glyph asset);
F3 cat design approved; F4 evening win-beat YES; **L2 ART CAP = $15.00** (fresh budget;
L1 closed at $21.15/$23.00). STANDING USER PREFERENCES (also saved to auto-memory):
stylized-3D seed-B engine style; NEVER the "psh" whoosh/hiss SFX (hard rule for all
Developer/sound work).
NEXT: Asset Generation (step 9) in per-zone batches — canonical sheets (numerals +
landmark die) FIRST, then z1 — feeding the FULL cumulative L1 reference library; step-10
per-zone user reviews follow each batch.

## ⭐ CURRENT RESUME NOTE (2026-07-19, CROSS-COMPUTER HANDOFF #3)

**User switching computers (usage limits). Everything durable is committed and pushed to
`level2-clockmakers-attic`. Take stock from THIS repo — agent transcripts do not survive.**

**Exact position — L2 ART BATCH 1 (z1) COMPLETE, AWAITING USER'S STEP-10 z1 VERDICT:**
- Batch 1 done at **$2.55 of the $15.00 L2 cap** (commits e6e1381 → 1e6ae0b → f08d64c):
  canonical sheets A (numerals I–XII + mirrored set; mirrored-IV→malformed-VI PASS, no
  legible mirrored VII) + B (landmark dies, 24px distinctness PASS); 3 z1 wides
  (v-bench/v-master/v-door, glyph-integrated, safe-zone audited); 12 z1 close-ups;
  8 cutouts (screwdriver, tiles II/IV/VII/XI, watches A/B, great-wheel 64t asserted).
  Manifest: `specs/levels/level-2/asset-manifest.json` (predecessor spend corrected to
  $2.25 + $0.30 this session). Review contact sheet for the user:
  `specs/assets/level-2/z1/z1-review-batch1.png`.
- **Producer verified at full res:** slate XII/VIII + 24 tallies; door dial seated
  I/III/V/VI/VIII/IX/X/XII with gaps exactly at 2/4/7/11 + single VI tray decoy, no
  keyhole. Flag for user on the sheet: stove-II / crate-VII engravings use a mild vertical
  legibility stretch — user to confirm it reads naturally.
- ✅ z1 STEP-10 VERDICT (user, 2026-07-19): **APPROVED WITH ONE FIX.** Stove-II +
  crate-VII stretch explicitly fine. FIX: door-dial glyph stamping is messy — numerals
  bleed past the brass tile faces and tiles intrude into the round sockets; re-stamp
  from canonical sheet A across ALL plates showing the dial (cu-door-dial, master wide,
  any others) and tidy the decoy tray so it reads as a shelf holding the loose VI (user
  misread it as "a fallen bracket"). VI decoy itself CONFIRMED intentional vs p01 spec
  (seated set + 2/4/7/11 gaps verified by Producer, no numeral conflicts). **Batch 2
  GREEN-LIT with the fix folded in — agent dispatched 2026-07-19:**
  v-frame + v-clockrow wides (~$0.60), CUs 13–19 incl. F1 sealed display case (~$0.45),
  6 rack gears 16/24/36/40/48/72 deterministic via `specs/tools/l2_glyphs.py::render_arabic`
  ($0, F6), landmark plates from sheet B, mouse + oil-can cutouts (~$0.30), PLUS ~14 z1
  state overlays folded in (near-$0 PIL). Est. batch ≈$1.35–1.80 → cumulative ≈$4.35.
- Toy mouse is z2-scoped (parts cabinet); oil can z2; key/tag z4. F2: L1 rune stays — no
  new pause glyph. Session-limit pattern: agents must commit small chunks (two cutoffs
  already recovered cleanly this level).
- ✅ z2 STEP-10 VERDICT (user, 2026-07-19): APPROVED WITH FIXES. Batch-2 flags all
  accepted (ascending win stairs, F1 seam, gear flatness). Defects routed to a fix
  pass (agent dispatched): (1) clockrow numeral rings spill outside all 4 dial faces
  — deterministic re-stamp from sheet A, same class as the door-dial fix; (2) z1
  state overlays bar-raised (misregistered), watch-A-taken (smeary inpaint),
  tile-taken (blurred edges) — rebuild; PLUS binding proactive audit of ALL batch-2
  state overlays for misregistration + blur classes (user caught 3; don't make them
  find more). Then batch 3 (z3) after the user sees the fix results.
- ✅ FIX-PASS VERDICT (user, 2026-07-20): "everything checks out" — all 9 fixes + audit
  accepted; coat watch-wear imprint accepted. ONE remaining fix rolled into batch 3:
  cu-gear-frame XII/VIII stamps mis-registered (XII stretches outside the small gear
  face; VIII floats over the bracket instead of engraved on the panel) — deterministic
  re-stamp, propagate to any plate showing them. BATCH 3 GREEN-LIT (z3 incl. the
  great-dial mirror contract plate — most protected asset — + z4); agent dispatched
  2026-07-20.
- ✅ z3/z4 STEP-10 VERDICT (user, 2026-07-20): APPROVED WITH ONE FIX. Both batch-3
  flags accepted (drum overscan framing, hatch wheel-4 edge spacing). FIX: hatch
  thumb-wheel numerals (XII/III/VI/IX) sit FLAT/skewed on the curved crown faces —
  must CONFORM to the wheel curvature/perspective (cylindrical warp), on cu-hatch-
  wheels CU22 + z3-dial-base wide + the 12-position wheel strip sprite. GATE UPGRADE:
  containment check must also verify curvature/perspective conformance on non-planar
  surfaces. BATCH 4 GREEN-LIT (state overlays + cat/mouse/mural sprites) with the fix
  first; agent dispatched 2026-07-20.
- ✅ BATCH 4 COMPLETE (2026-07-20, finished on Opus after Fable credit exhaustion):
  all remaining state overlays (z2/z3/z4) + cat/mouse/mural sprites + hatch-wheel
  curvature carry-in fix. 24 surface overlays seam-audit PASS (worst 20.2, the optional
  -absent animation aids). Dead-agent z4 clone work REJECTED for interior smear (seam
  passed but blur-class defect) and redone. **LEVEL 2 ART COMPLETE — $8.85/$15.00 cap
  ($6.15 headroom) — awaiting user's final step-10 review.** Review sheet:
  z2/z2z3z4-review-batch4.png. On approval → DEVELOPER STAGE (reminder: do NOT build the
  unreachable p08 mouse-at-drum interaction; NEVER "psh" SFX; L1 round-4 architecture is
  the baseline — per-element overlays, uses-driven lifecycle, manual pickups, containment/
  conformance gates). Model note: Fable 5 credits exhausted 2026-07-20; spawn subagents
  on the session's current model (user on Opus) until Fable resets.
- Pipeline after art: batches 2→4 (z2, z3, z4 + sprites/state edits) with step-10 reviews
  → Developer (NOTE: do NOT build the unreachable p08 mouse-at-drum interaction — dead
  spec text, see walkthrough flags; NEVER the "psh" SFX) → QA → GATE → release.
  Deferred L1 items: cu-lintel ghost rect (polish), minor build-14 bugs (unitemized),
  CI cert-cap durable fix (.p12 pinning — proposed, undecided).

## Level 1 (COMPLETE — for reference)

Level 1 — "Wizard's cabin": abandoned wizard's cabin in the woods, gloomy atmosphere,
caged crow, potions/potion-making (user-specified elements). Difficulty 6.0/10. Art spend
$21.15. Post-release deferred items: cu-lintel ghost rectangle (user aware, polish pass);
minor build-14 bugs (user: "minor bugs here and there", not yet itemized); CI cert-cap
durable fix (reusable .p12 — proposed, not yet decided).

## ⭐ CURRENT RESUME NOTE (2026-07-14) — ROUND 6 PROCESSED, AWAITING GATE 1

Post-release feedback round 6 processed 2026-07-14 (build-11 milestone on TestFlight
"Within 1.0 (build 12)"). Routed changelist:
`specs/levels/level-1/round6-routed-changelist.md`. Two systemic Developer clusters
(A container/pickup taken-state render, close-up + wide; B re-frame hotspot/overlay
coordinate remap) + legacy un-defer (R6-007, retire 4 KNOWN_LEGACY_SOURCES) + art singles
(R6-011 5-CCW recipe spiral, R6-002 EARTH glyph, R6-004 band sweep, R6-003 non-collectible
decoy, R5-002 About credit). R6-009 poker soft-lock UNCONFIRMED → screenshot-based alt-order
UI playthrough is a hard release gate. POSITIVE (do not touch): placement consumption works
(coin/ring consumed at p04). Est. art spend this round ~$0.79 (worst ~$2.61) within the
$3.20 headroom on the $23.00 cap.

**NEXT:** awaiting user GATE 1 approval of the changelist. On GO → branch off
level1-rebuild-build3; run ART + DEV tracks in parallel; Cluster B (hotspot remap) must land
before QA; full QA regression incl. the R6-009 screenshot gate; GATE 2 (QA results) →
re-release. Merge to main deferred until the round-6 fix build passes.

### GATE 1 APPROVED — fix build IN PROGRESS (2026-07-14)
Branch `build-12-round6-fixes` off `level1-rebuild-build3` (tip ebd3a0c). Two isolated-worktree
tracks launched:
- **DEV track DONE** — worktree branch `worktree-agent-a547920d30005b1ab` @ commit `964b429`
  (clean FF on ebd3a0c). Cluster A (per-element ContainerCloseUpModel.plan replaces baked
  black-box patch), Cluster B (hotspot re-frame: R6-001 z-order, R6-006 roped-hook + alcove-nav
  safeguard, R6-008/010 rects), R6-003 (rusted key non-collectible), R6-007 registration
  (unified image+rect name). R5-002 was ALREADY fixed in build 11 (no change). Tests added.
  NOT pushed (Producer merges worktrees).
- **ART track RUNNING** — asset-gen worktree; R6-011/R6-002/R6-004/R6-007 re-rolls.
- **DISCOVERED dep (feed to ART, do in JOIN):** container items are baked into single reveal
  plates, not separate overlays. Need three $0 PIL inpaint "empty" variants (code existence-guards
  them; build safe until staged): (1) `cu-cabinet-empty` [REQUIRED — else cabinet close-up
  lingers], (2) `ov-barrel-pried-empty` [REQUIRED — else R6-005 barrel weight not visibly fixed],
  (3) `ov-adrawer-empty` [OPTIONAL nicety — drawer wide already hides functionally].
- **JOIN pass (after both merge):** Developer stages all art + retires 4 KNOWN_LEGACY_SOURCES
  (needs re-rolled flame/slots plates present) → CI → full QA incl. R6-009 screenshot gate.

### BUILD ASSEMBLED — CI DISPATCHED (2026-07-14)
`build-12-round6-fixes` fully assembled. Sequence done: ART track (0de6489) + DEV track (964b429)
merged (merge c6746e8); 3 emptied-container plates $0 PIL (7fcdbe0); JOIN pass (2f1c6f7) staged
all art + RETIRED all 4 QA-B10-002 KNOWN_LEGACY_SOURCES (none still stale) + all guards
(nb-shadow, vintage, chrome, security) PASS. Art spend $20.85/$23.00 (headroom $2.15; empties
were $0). No likely CI failure flagged. Container tests now driven by real staged empties
(cu-cabinet-empty, ov-barrel-pried-empty, ov-adrawer-empty), not interim fallback.
**CI GREEN (2026-07-14):** build-and-test run 29328326128 SUCCESS on tip 3f58479 (full suite,
both full playthroughs + save/resume + smoke). Path there: run 1 (29311898591) caught a REAL bug
— stale weight-hook UI-test coord in EscapeRoomUITests missed the R6-006 hotspot move → fixed
(f000e15, weight-hang 0.23,0.33→0.44,0.55; full UI-playthrough coord audit, only that one stale).
Run 2 (29314184259) iPad flake (UI-query timeout, iPhone passed same test) then rerun CANCELLED
at 120-min job timeout → bumped timeout-minutes 120→180 (3f58479). Run 3 green.
**QA DONE (628bb48):** R6-009 poker gate CLEARED — both alt-order UI tests GREEN on iPhone
(testR6009_pokerSurvivesAstrolabeFirst 153s, testR6009_pokerSurvivesBarrelBeforeAsh 80s), standard
full playthrough green (iPhone), testR6VisualRegression_z1Captures green (iPad). Visual fixes
verified from screenshots (spiral 5-CCW, flame plate, EARTH glyph, roped hook, empty wides,
non-collectible key = PASS; drawer-empty + edge-bands UNVERIFIED-BY-SCREENSHOT → device spot-check).
qa-report.md: GO. R6-009 tests gated to iPhone-only on iPad step (workflow -skip-testing).

**CI iteration log (build-12):** run1 29311898591 = real bug (stale weight-hook UI coord) → fixed
f000e15. run2 29314184259 = iPad UI-query flake then rerun CANCELLED at 120min → timeout bumped
120→180 (3f58479). run3 29328326128 = GREEN (pre-QA baseline; iPad full playthrough passed 1357s).
run4 29337094840 (post-QA) = R6-009 gate + all substantive tests GREEN, but iPad
testFullPlaythroughWithScreenshots failed TWICE (initial + rerun) at app.launch() with CoreSimulator
"Failed to terminate app" — an infra teardown-contamination flake (same test green on iPhone + green
on iPad in run3). ROOT-CAUSE FIX: UI-test harness now terminates the app in tearDown (6b8dae0) so no
stuck instance blocks the next test's launch; zero test-logic change.
**CI FULLY GREEN (2026-07-14):** run 29351342351 on tip 7cf278a — full suite incl. the
previously-flaking iPad full playthrough PASSED (tearDown terminate-fix worked). Round-6 fix build
is clean end-to-end.
**GATE 2 APPROVED by user 2026-07-16. BUILD 13 SHIPPED TO TESTFLIGHT.**
Release run 29523440104 SUCCESS — "Within 1.0 (build 13)" uploaded to App Store Connect from
`build-12-round6-fixes`. All steps green (archive w/ cloud-managed signing, build-number stamp,
export, security re-check, upload). Post-GATE-2 work completed and pushed: Documentation second
pass (walkthrough reconciled: R6-011 art↔5-CCW match, R6-003 inspect-only decoy, roped-hook
location, tap-to-collect containers, + documented previously-undocumented rev-1.3 clue gates);
Release notes `specs/levels/level-1/testflight-notes-build13.md`; light Validator re-validation
(graph synced: itm-rusted-key obtained_by none/collectible false + p11 clue text; recipe/brew +
poker invariants PASS; NO solution values changed).

**RELEASE BLOCKER HIT + RESOLVED (record for next time):** release run 29514688025 FAILED at
archive — Apple account hit the **Apple Development certificate cap**. Root cause: the release
workflow uses `CODE_SIGN_STYLE=Automatic` + `-allowProvisioningUpdates`, so EVERY CI run on a fresh
runner mints a NEW Apple Development cert; they accumulate to the cap. User revoked one (dated
Jul 8) and the re-dispatch succeeded. **This WILL recur every few builds.**
→ TODO (deferred, non-blocking, raised with user): stop burning a cert per run — either pin a
reusable signing identity from a .p12 secret, or stop the archive resolving Development signing at
all (likely the test targets pull one in; archive should only need Apple Distribution).
NOTE: certs are ACCOUNT-WIDE, not per-app; user has other live App Store/TestFlight apps. Safe rule
used: only revoke **Apple Development** (disposable, auto-regenerates, cannot affect shipped/
TestFlight builds); NEVER touch **Apple Distribution**.

## ⭐ ROUND 7 (build 13 device spot-check) — BOTH DEFECTS FIXED, heading to build 14 (2026-07-17)

User spot-checked build 13: **R6-008 astrolabe drawer + R6-006 weight hook CONFIRMED FIXED on
device** (round-6 clusters A and B land). Two defects found → Round 7. Both now fixed on
`build-12-round6-fixes`, verified by the Producer from RENDERED PIXELS (not agent claims):

**R7-002 edge bands — FIXED (4b095ee + 21a1eca).** Root cause: build-10 re-frame PADDED plates;
an outpaint to fill the padding was REJECTED so it fell back to STRETCHING edge pixels; round-6's
R6-004 "sweep" then only VIGNETTED that stretch (darker, not gone). User decision = try outpaint,
fall back. **Outpaint REJECTED AGAIN and marked DO-NOT-RETRY** — architectural, not prompt:
`nano-banana-pro/edit` has NO mask param and downscales refs to 1536px, so interior preservation is
impossible in principle (8/8 failures across 3 framings, $2.40 burned across builds 10+13).
Clean fade-to-black applied to ALL 4 edges, 31 plates + 4 hearth = 35. Probe cost $0.30, rest $0 →
**cumulative art $21.15 / $23.00 (headroom $1.85)**. Producer LESSON: my smear detector produced
FALSE POSITIVES on `cu-lintel` (394px) + `cu-flowerpot` — it measured softness/wood-grain, not
smear; the ART agent correctly overrode me (fading cu-lintel would have blacked out half the FIRE
triangle + numeral II puzzle clue). It also found left/right bands were REAL and bigger than
measured (up to 630px), and fixed a latent `reframe_b10.py` rolling-RNG bug (18/22 variants had
different band noise than their base).

**R7-001 cauldron misplaced — FIXED (c3fcfc8).** Producer measured 23/27 overlays at ratio 1.000;
exactly the 4 R6-007 re-rolled plates wrong (flame1/2/3 = 1.204, slots-seated = 1.427). Developer
found the deeper cause: those ratios are EXACTLY the reframe-scale inverses (1/0.83, 1/0.70). A
`legacy=True` flag in `MANUAL_OVERLAYS` cropped the variant at the OLD pre-re-frame hand rect while
STORING the re-framed rect, relying on SpriteKit to rescale — correct ONLY while the sources really
were old-framing 2560 plates. R6-007 re-rolled them fresh at 3840x1920 in re-framed space,
invalidating the flag's premise. **No number was stale — a PREMISE was.** Fix: moved all 4 into the
auto-diff `OVERLAYS` list (self-locating diff bboxes) and DELETED the `legacy` flag + its stale hand
rects so the class is unrepresentable. **All 27 overlays now 1.000.** Two new guards, both tested by
injecting the old rect: `assert_overlay_rects_match_art()` (Python, blocks writing overlays.json)
+ `testOverlayArtIsPixel1to1WithItsRect` (CI, catches hand-edited overlays.json).
Bundle restaged onto the band-faded plates. All guards PASS; KNOWN_LEGACY_SOURCES stays EMPTY.

**OPEN (user decision, non-blocking):** `cu-lintel` has a genuine SEPARATE defect — a translucent
ghost RECTANGLE around the FIRE triangle clue (composite artifact) + soft plate. NOT reported by the
user across several playthroughs; Producer lean = leave it. Not fixed.
**BUILD 14 SHIPPED TO TESTFLIGHT (2026-07-17).** CI green (run 29582213189, first try incl. the new
overlay-registration test). Release run 29607835708 SUCCESS → "Within 1.0 (14)" uploaded. Cert-cap
blocker recurred AGAIN (release run 29594981602 failed at Archive, same "maximum number of
certificates") — user revoked one more Apple Development cert, re-dispatch succeeded. **This is now
2 builds in a row hitting the cap; PROPOSED durable fix to user: pin a reusable Apple Development
.p12 as GitHub secrets so CI stops minting a new cert per run** — user has NOT yet decided (offered
to set up after build 14 ships).
**NEXT:** user device spot-check of build 14 — verify R7-001 (cauldron flame on the pot, cabinet
ring/coin seated) + R7-002 (clean faded edges on all 6 scenes). On approval → merge
`build-12-round6-fixes` → `level1-rebuild-build3` → `main` (Level 1 DONE). Only knowingly-unshipped
item: `cu-lintel` ghost rectangle (Producer lean = leave; user's call).

## PRIOR — build 13 spot-check items (superseded by Round 7 above)
**NEXT:** user device spot-check on iPad of build 13. CI-UNVERIFIABLE items needing human eyes:
(1) astrolabe drawer CLOSE-UP empty state after collecting crank+coin, (2) R6-004 top/bottom edge
bands. Also flagged non-blocking: R6-004 left/right overscan NOT swept (only top/bottom reported);
R6-002 EARTH glyph reads correct ▽+bar but has faint carved-groove remnants.
→ On user approval: merge `build-12-round6-fixes` → `level1-rebuild-build3` → `main` (Level 1 done).
Non-blocking eyeball items for GATE 2: R6-004 left/right overscan left as-is (only top/bottom
swept); R6-002 EARTH glyph faint carved-groove remnants (reads correct ▽+bar).

## ⭐ PRIOR RESUME NOTE (2026-07-13) — BUILD 11 SHIPPED

**Build 11 is ON TESTFLIGHT as “Within 1.0 (build 12)”** (release run 29230331494 green;
the number 11 was consumed by a blocked attempt — the security gate correctly fired on a
false positive: the R5-002 About credit "fal.ai" tripping the bare-domain scan pattern;
pattern narrowed, real credential patterns intact). Final CI green on the tip: run
29225239768 (1h47m full suite; earlier rerun reds were runner flakes — different test
each attempt). Build 11 contents: R5-001 poker-plate fix (+rendered-frame guards), ALL 20
stale files replaced (vintage guard live; only the 4 QA-accepted QA-B10-002 residual
exceptions remain), ember-rect sync, About credit, DI render-crash fix. Art spend $19.80
of $23.00.

**NEXT:** user device-test on iPad (headline checks: hearth after poker pickup, cage
close-up, solved astrolabe + drawer, About credit). On user GO → **merge
level1-rebuild-build3 → main** (Level 1 complete). Deferred non-blocking: QA-B10-002
legacy flame/slots re-roll, QA-B10-001 rug seam, plate-2-nb reference drift note,
R2-029 rotate-inspect (Level 2+).

## ⭐ PRIOR RESUME NOTE (2026-07-12, CROSS-COMPUTER HANDOFF #2)

**User is switching computers again (usage limits). Everything durable is committed and
pushed to `level1-rebuild-build3`. Take stock from THIS repo.**

**Exact position — build 10 is FULLY IMPLEMENTED, awaiting its CI green:**
- All round-4 fixes are code-complete and pushed (commits 2e4b54d Phase 1 → a12300c):
  lifecycle engine, armed-item model, sound overhaul, per-element overlay architecture
  (cluster B / R4-024), hotspot re-frame remap + .aspectFill restored (letterbox GONE),
  guard tests (overlay catalog completeness, seam/registration, mirror-position, dial
  view-rotation contract). Art batch complete earlier (12/12; spend $19.35 of $23 cap).
- CI history: run 29164191154 RED (unit fixes landed in 16ca034); run 29186397614 RED
  (single failing step: iPad full-playthrough UI test — diagnosed as a lost nav tap
  under simulator starvation, FIXED in a12300c); **run 29190128411 dispatched
  2026-07-12 11:01 UTC and IN PROGRESS at handoff — check its verdict FIRST:**
  `gh run view 29190128411` (repo shayma16/escape-room; typical duration 30–80m).

**FIRST ACTIONS on resume:**
1. ✅ DONE: run 29190128411 GREEN.
2. ✅ DONE (2026-07-12): QA full player-style pass — **GO** (qa-report.md "Build 10 —
   player-style regression", commit 26f23f2). R4-019 alt-order soft-lock DEAD (all
   orderings complete, per-step anti-softlock asserted); letterbox REMOVED, nothing
   cropped (dual-safe guard on 32 hotspot centers); R4-024 overlay architecture verified
   on frames (no cross-state contamination); R4-007 dial canonical; ALL round-2 closures
   re-verified still fixed. 0 crit/major/moderate; 2 minor art residuals (QA-B10-001
   rug-moved tonal seam → Asset Gen re-roll recommended non-blocking; QA-B10-002 legacy
   flame/slots-seated overlays, pre-existing).
3. ✅ CHECKPOINT 2 PASSED — user GO given 2026-07-12.
4. ✅ **BUILD 10 RELEASED TO TESTFLIGHT — Within 1.0 (build 10)**, release run
   29194936494 GREEN (~4 min). NEXT = user device-test on iPad: confirm full-width (no
   letterbox, nothing cropped), try an ALTERNATE solve order (poker on barrel before
   ash), cellar overlay states, rug-seam severity, combine pulse R4-029a, menu ping,
   DI pause menu if available. **On user GO → merge level1-rebuild-build3 → main**
   (final step; Level 1 complete). Deferred/non-blocking: QA-B10-001 rug-seam re-roll,
   QA-B10-002 legacy overlays, R2-029 rotate-inspect (Level 2+).

**Machine setup if missing (same as handoff #1):** git pull branch
level1-rebuild-build3; gh auth login (repo+workflow); .env with FAL_KEY (gitignored,
copy manually); Python 3.12 + Pillow + numpy. `EscapeRoom/Core/` may appear untracked —
stale Jul-5 orphan files (GameState.swift, Items.swift), intentionally uncommitted,
safe to delete.

**Spend state:** art $19.35 of $23.00 cap (round-4 batch $2.10 over the $17.25
baseline). Feedback: rounds 1–3 shipped; round 4 processed + checkpoint-1 approved,
fixes implemented, in CI verification.

## Build 11 Developer stream (2026-07-12, post-round-5) — R5-001/R5-002 + gapfill staging

Developer status (this update is Developer-authored; Producer to fold into the resume
note): R5-001 root-caused — NOT a runtime-compositor bug; the "misplaced fireplace
fragment" was baked into the manifest-current z1-hearth-poker-taken plate (+240 px
clone-fill, duplicated andiron). Fixed tool-side (poker synthesized from base;
misplaced-clone guard on all auto-diff overlays; full-tree audit: poker was the only
defect). NEW rendered-frame registration tests (SKView.texture(from:) vs offline
composite: hearth poker/rug/trapdoor stack + six-overlay cellar stack). R5-002 About
credit fixed. Scope addition landed: all 19 build11_gapfill assets staged, ember rects
synced (+ JSON cross-check test), VINTAGE GUARD added to the tool (validated: would
have failed pre-gapfill). ⚠ FLAG FOR PRODUCER: the vintage guard discovered a 20TH
stale file the gapfill missed — z2/v-cabinet/cu-cabinet-open@3x.png (build-1 photoreal
container close-up; ships knowingly as a tracked KNOWN_LEGACY_SOURCES exception) —
route to Asset Gen for re-delivery. No PR opened; Producer assembles build 11.

## ⭐ PRIOR POSITION (2026-07-11) — Round 4 feedback PROCESSING

Cross-computer handoff complete: this machine is synced to `level1-rebuild-build3`
(build 9), gh authenticated, FAL_KEY present and live-verified against nano-banana-pro.

**The user device-tested build 9 on iPad and completed Level 1 END-TO-END ("i'm free
now") — the iPad test that gated the build-9 GO. However, the run surfaced a large
feedback round: Round 4, 29 items + completion record, all logged in
`specs/feedback-backlog.md` with 8 screenshots attached across 6 items.** Producer
audit verified the round complete/faithful. Headlines: 🔴 R4-019 poker item-lifecycle
soft-lock (multi-use tool consumed after first use — level unsolvable on legal
alternate orderings, reachable in normal play); R4-024 root-cause diagnosis (cellar
rendered as mutually-exclusive whole-plate swaps → cross-state contamination; fix =
per-element overlay compositing); a class of stale resolved-state close-ups that
escaped the build-3 shadow sweep; surviving default-psh sound; hotspot-geometry gaps;
armed-item interaction traps. Several round-2 fixes have REGRESSED or never fully
shipped — regression-verification directive queued for Developer + QA.

**Post-release feedback round 4 — processed 2026-07-11.** Build 9 device testing (iPad,
TestFlight): 30 items + completion logged; level completed end-to-end. 1 critical
(R4-019 poker-lifecycle soft-lock on alternate orderings). Six root clusters routed:
(A) inventory lifecycle/manual pickup [Dev+Validator], (B) per-element overlay rendering
architecture [Dev, anchor R4-024], (C) stale resolved-state close-ups [Dev staging +
assert_no_nb_shadow extension], (D) default-psh audit completion [Dev], (E) hotspot
re-calibration [Dev], (F) armed-item interaction model [Dev]; singles: Level-1 label,
ocean-residue audio, moon-dial fix [AssetGen], p04 placement feedback, menu-ping
consistency; R4-029 combine-UX = option (a) (user pick). Standing directive: determine
lost-vs-never-shipped for each recurring round-2 fix + add guards; QA re-verifies ALL
round-2 closures in the build-10 pass.

**CHECKPOINT-1 PASSED 2026-07-11 (user: "implement everything u suggested"). Build-10
EXECUTION IN PROGRESS, one build, art cap raised to $23.00 hard stop:**
- ✅ ART BATCH COMPLETE (12/12, commits b215016/ff9299d/0440c74/2c7ae60): all 6 views
  re-framed into the dual-safe band via $0 deterministic PIL (nano-banana outpaint
  REJECTED — re-rendered content, violated content-identical rule; $2.10 spent on the
  rejected attempts, tool specs/tools/reframe_b10.py is the standing re-frame method);
  z4 verified in-band; R4-008 ghost glyph cleaned; cabinet-window moon canon-fixed
  (was mirror-flipped); R4-007 ROOT CAUSE = view rotation tilting correct marks — dial
  sprite rebuilt with pre-rotated marks, VIEW ROTATION MUST NOT CHANGE (contract in
  manifest build10_reframe.developer_contract); triptych verified correct as-is.
  Spend $19.35 of $23.00. Legacy-art flags: z2 flame1/2/3 + slots-seated still build-2
  framing (overlay-remap workaround; regen deferred); z1-hearth-rug-moved tone diff.
- 🔄 DEVELOPER: Phase 1 (lifecycle engine, armed-item model, sound audit, singles)
  implemented, CI run 29164191154 dispatched; PHASE 2 GO sent (overlay architecture +
  hotspot remap per developer_contract + aspectFill/letterbox removal).
- NEXT: Developer CI green → QA full player-style pass (round-4 + ALL round-2
  closures) → ⛔ CHECKPOINT 2 (user reviews QA results) → release build 10.
  Merge to main stays gated until then.

## ⭐ PRIOR RESUME NOTE (2026-07-10, CROSS-COMPUTER HANDOFF)

**User is switching computers; new session resumes on a different machine.** Everything
durable is in THIS repo — take stock from here, not from any prior session's memory.

**Exact position:** build 9 is fully assembled on branch `level1-rebuild-build3`. All
Round-3 fixes landed (stale art→build-3 everywhere incl. icons; canonical rune glyphs —
p01 solvable; hotspot re-calibration to the new art; cuckoo plates deleted; music
level-scoped + menu SFX; "Level 1" Arabic serif; new thumbnail + chrome staleness guard;
interim iPad LETTERBOX so nothing is cropped on iPad — user-chosen interim, commit
354ff00). **The letterbox verification CI run 29056248425 is GREEN** (build + unit×3 +
UI×3 incl. the iPad FULL playthrough + save-resume — iPad completability CONFIRMED under
the letterbox): https://github.com/shayma16/escape-room/actions/runs/29056248425

**FIRST ACTIONS on resume:**
1. ✅ DONE before handoff: **build 9 RELEASED to TestFlight — Within 1.0 (build 9)**,
   release run 29059962959 GREEN (archive→sign→stamp→scan→upload, 3m54s). CI was green
   on 29056248425 (letterbox verified incl. iPad full playthrough). Nothing to dispatch.
2. NEXT = user device test on iPad (letterboxed — whole plate visible, everything
   tappable, p01 solvable end-to-end, music only in-level, quiet menus, "Level 1" serif).
3. On user GO → merge `level1-rebuild-build3` → main (PR), update ledger.
4. DEFERRED to build 10: proper plate re-frame to remove the iPad letterbox (restore
   BUG-004-class dual-safe-zone framing in the build-3 art, then back to aspectFill).

**Machine setup on the new computer (if missing):** repo `git pull` (branch
level1-rebuild-build3); `gh auth login` (needs repo+workflow); `.env` with FAL_KEY at repo
root (gitignored — copy manually; only needed for future art gen); Python 3.12 + Pillow +
numpy (winget) for `tools/build_game_assets.py` / `specs/tools/fal_gen.py`; optionally copy
`~/.claude/projects/C--Users-shaim-escape-room/memory/` for the Producer's memory (repo
resume notes cover the essentials if not).

**Spend state:** art rebuild $17.25 of $18.90 cap (+$0 build-9 art phase). Feedback
backlog: rounds 1–2 fully processed/shipped; round 3 processed → build 9 (this).

## ⭐ RESUME NOTE (2026-07-09e)

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

✅ **iPad crop RESOLVED (INTERIM) — letterbox fix (Developer, branch `level1-rebuild-build3`,
2026-07-09).** The build-3 art dropped BUG-004's iPad dual-safe framing, so `.aspectFill` was
cropping puzzle-critical edge elements off-screen on iPad (the PRIMARY device), making the
level uncompletable there. User chose the INTERIM LETTERBOX fix: `RoomScene` is now
`.aspectFit`, so the WHOLE 2:1 plate is visible on iPad (dark `#101010` bars top+bottom) — no
cropping on any device. UI-test `sceneCoordinate` scale flipped max→min to match the fit +
letterbox offset (taps land on the now-visible iPad edge elements); `Hotspot.minHitSceneSize`
168→182 (44-pt floor at the smaller fit scale); BUG-004 test un-`XCTExpectFailure`d →
permanent "no critical element off-screen" assertion; full iPad UI coverage (playthrough +
save/resume) RESTORED (CI timeout 90→120). **PERMANENT fix still owed to Asset Gen (build 10):
re-frame the build-3 plates into the §8 iPad 4:3 dual-safe band so `.aspectFill` returns and
the letterbox is removed.** **NEXT: CI green -> build-9 player-style QA -> Producer re-releases
build 9 (do NOT open a PR / ship from here).**

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
