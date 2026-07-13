# Round 6 — Routed Changelist (Level 1)

_Feedback Intake Agent, 2026-07-14. Source: `specs/feedback-backlog.md` Round 6
(R6-001..R6-011 + 5 screenshot-confirmation batches + R6-011 user decision) on TestFlight
"Within 1.0 (build 12)" (build-11 milestone). This is the routed artifact for the
Producer. I classify and route only — the owning agent does the work._

## ⛔ CHECKPOINT GATES (Producer: pause here)
- **GATE 1 — pre-execution:** user reviews THIS changelist before any fix work starts.
- **GATE 2 — post-QA:** user reviews QA's screenshot regression results before re-release.
  R6-009 lifecycle screenshot-validation is a **hard release gate** inside GATE 2.

## DECISIONS ALREADY MADE (do not re-ask)
- **R6-011 = OPTION (a):** re-draw the grimoire stir glyph to **5 dots, COUNTER-CLOCKWISE**
  to match the fixed brew solution (5 CCW). Brew solution value NOT reopened. Crop-scoped
  edit of ONLY the spiral glyph; preserve on the same page moonflower/mortar,
  file/silver-bar, feather/hand, and the **Flame III** numeral; preserve ALL other grimoire
  pages untouched.
- **R6-009 = UNCONFIRMED / possibly intermittent** (did not reproduce on re-test). NOT a
  confirmed critical. Validate via screenshot-based UI playthroughs across ALL legal
  orderings — do not dismiss, do not treat as a deterministic soft-lock.
- **R6-003 = rusted decoy key becomes NON-COLLECTIBLE** (in-world inspectable only). Correct
  cage key from the z4 statue stays. Standing principle: decoys are never inventory items.
- **R6-002 arrow/EARTH-glyph line-position = simple → do it** ($0 PIL re-stamp, prior
  Producer verdict). If scoping shows it is NOT trivial, it reverts to **Producer judgment**
  (user condition: "fix only if simple, skip if big") — do not force it.

## 1. Prioritized item table

| Pri | Item IDs | Defect (one line) | Root cluster | Target agent | Fix type |
|-----|----------|-------------------|--------------|--------------|----------|
| **P0-gate** | R6-009 | Multi-use poker possibly dropped before both uses (ash p05 + barrel p06) → soft-lock — UNCONFIRMED | — (validation, not a coded fix unless repro) | QA (screenshot UI playthroughs) + Validator (anti_softlock_invariants) | validation gate |
| **P1** | R6-008, R6-010 | Container CLOSE-UP collected-state broken for ALL containers — items still shown after collect (+ faint translucent "black box" = mis-composite of same overlay) | **A — container/pickup taken-state render** | Developer | code |
| **P1** | R6-005, R6-008-wide | WIDE taken-state duplication — astrolabe drawer + barrel weight still shown in wide after collect (sun/moon cabinet wide is CORRECT) | **A** | Developer | code |
| **P1** | R6-001, R6-006, R6-008-hotspots, R6-010-hotspots | Hotspots/overlay anchors off the visible element (poker-taken floats over rug; p07 weight tap on wrong hook; drawer/cabinet item rects require random-clicking) | **B — re-frame coordinate delta** | Developer | hotspot-remap |
| **P1** | R6-007 | Legacy dark-photoreal flame/cauldron plate surfaces on bellows-pump — STALE (wrong style) AND MISREGISTERED (floating box) | **D — legacy un-defer** | Asset-Gen (re-roll) + Developer (registration + guard-retire) | art re-roll + guard-retire + code |
| **P1** | R6-004 | Blurry/stretched re-frame edge BAND on padded edges across ≥5 of 6 views (assume all 6) | **C — re-frame band sweep** | Asset-Gen | art-crop-edit |
| **P1** | R6-011 | Grimoire recipe stir glyph reads 6 CW; brew solution is 5 CCW → clue contradicts solution | — (single) | Asset-Gen (re-draw) + Validator (match) + Documentation (walkthrough) | art-crop-edit |
| **P1** | R6-003 | Rusted decoy key is collectible → permanent useless inventory item | — (single) | Developer + Validator (light) | code / config |
| **P2** | R6-002 | Desk/flowerpot EARTH glyph bar sits BELOW the triangle, not through the middle (door canon) | — (single, glyph-canon) | Asset-Gen (stamp) + Developer (stage) | glyph-restamp |
| **P2** | R5-002 (carry) | About screen still credits "Flux 2 Pro"; should credit Nano Banana Pro (fal.ai) for art + fal.ai for music | — (single) | Developer | config / copy |

**POSITIVE — DO NOT TOUCH (regression risk):** placement consumption works correctly — moon
coin + gold ring are consumed when PLACED into the p04 cabinet slots (confirmed batch 3/4).
The bug is specifically CONTAINER-REVEAL items duplicating on COLLECT, not placement.

## 2. Root-cause clusters (fix each root ONCE)

### Cluster A — Container / pickup taken-state render  → Developer, code
One mechanism: when an item is collected from a revealed container (or pried barrel), it
enters inventory but is **not removed from the render**.
- **A-primary (close-up):** collected-state render broken for BOTH containers — astrolabe
  drawer (R6-008) and sun/moon cabinet (R6-010). Fix the container-reveal→collect mechanism
  generally: each item disappears from the close-up as it is taken; partial state (one taken,
  one not) composites cleanly with **no black box**; container reads empty when all taken.
  The "black box" is FAINT/translucent (per batch 3/4) — a mis-composite of this same
  collected-state overlay, fixed by the same render fix.
- **A-wide (container-specific):** astrolabe drawer (R6-008-wide) and barrel weight (R6-005)
  still duplicate in the WIDE view after collect. Sun/moon cabinet WIDE renders empty
  correctly (batch 4) — leave it.
- **Guard:** extend the build-10 rendered-frame overlay guard to cover EVERY element's
  partial/taken/emptied state (close-up + wide), not a sample. R6-008 (all three defects on
  one close-up) is the ideal regression fixture.

### Cluster B — Re-frame hotspot/overlay coordinate delta  → Developer, hotspot-remap
Root: the build-10 dual-safe re-frame shifted element positions in the plates; hotspot and
overlay-anchor coordinates were not fully re-mapped. Do a **coordinate audit across all
affected views against the CURRENT re-framed plates**:
- R6-001 — poker-taken overlay anchor floats over the rug in the combined poker-taken +
  rug-moved state (fix z-order/position; extend rendered-frame guard to THIS pair).
- R6-006 — p07 weight tap target on the LEFT wall hook vs the visible RIGHT roped hook; move
  the tap target onto the visible roped hook. (p07 logic is fine.)
- R6-008 / R6-010 item hotspots — coin/crank and file/phial rects don't sit on the visible
  items (currently only findable by random-clicking); re-map to the visible items.

### Cluster C — Re-frame edge-band sweep  → Asset-Gen, art-crop-edit
R6-004: blurry/stretched PIL band-fallback residue on whichever short edge(s) each view was
padded. Confirmed on study (top), entry (top+bottom), cellar (top+bottom), bench (top+bottom),
cabinet (top+bottom); alcove unconfirmed → **treat as all 6 views, all edges**. Replace each
stretched/blurred band with clean content-preserving fill (prefer $0 deterministic PIL;
nano-banana crop-edit fallback only where PIL can't). The faint horizontal band inside the
CLOSED-cabinet wide state is this same R6-004 band on the base plate — the OPEN-cabinet wide
state is clean (batch 4), so it's a base-plate fix, not a container-overlay fix.

### Cluster D — Legacy art un-defer (R6-007)  → Asset-Gen + Developer
The 4 QA-B10-002 KNOWN_LEGACY_SOURCES exceptions are PLAYER-VISIBLE in normal play (bellows
pump), so "deferred" is wrong. Un-defer fully:
- Asset-Gen: re-roll in build-3 style — `z2/v-bench/z2-bench-flame1@3x`,
  `z2-bench-flame2@3x`, `z2-bench-flame3@3x`, and `z2/v-cabinet/z2-cabinet-slots-seated@3x`.
- Developer: fix the flame overlay **registration** (the floating/misregistered box), then
  **retire all four `KNOWN_LEGACY_SOURCES` entries** (`tools/build_game_assets.py` lines
  ~138–141) so the vintage guard covers them. Verify every flame stage (0/1/2/3) and every
  brew liquid state (clear/fizzle/draught) renders build-3 art.

## 3. Order of operations (Producer)

Re-entry, not a restart — only the agents below are re-invoked; no full per-level rerun.

1. **GATE 1** — user approves this changelist. (Pause.)
2. Branch off `level1-rebuild-build3`. Then run two tracks in **parallel**:
   - **ART track (Asset-Gen)** — R6-011 spiral crop-edit; R6-002 EARTH glyph re-stamp ($0);
     R6-004 band sweep (all 6 views); R6-007 re-roll flame1/2/3 + slots-seated. Delivers PNG
     drop-ins.
   - **DEV track (Developer, code)** — Cluster A (container/pickup taken-state render, close-up
     + wide); Cluster B (hotspot/overlay coordinate audit — **must land before QA**);
     R6-003 (remove pickup, keep inspect close-up); R5-002 About copy; guard extensions.
3. **Join:** once ART lands, Developer stages the re-rolled/re-stamped plates and **retires
   the 4 KNOWN_LEGACY_SOURCES exceptions** (R6-007 guard-retire depends on the re-rolled
   flame/slots plates existing, else the vintage guard fails).
4. **Validator (light, can run parallel):** R6-003 confirm no solve path references
   `itm-rusted-key`; R6-011 confirm recipe↔brew match (5 CCW) after re-draw; R6-009
   re-confirm anti_softlock_invariants for the poker.
5. Assemble build → CI green.
6. **QA (screenshot-based, player-style)** — QA has final say on scope. Must include the
   **R6-009 gate**: screenshot UI playthroughs across ALL legal orderings (barrel-before-ash,
   astrolabe-first, standard) capturing the inventory bar at each step — poker retained
   through every ordering, or the vanishing frame is the repro. Also verify per-human: container
   collected-state (close-up + wide, no black box, no duplication), hotspots-on-visuals,
   bands gone, decoy non-collectible, recipe↔brew, EARTH glyph vs door.
7. **Documentation** second pass: reconcile the walkthrough for R6-011 (5 CCW) and R6-003
   (decoy no longer collected).
8. **GATE 2** — user reviews QA results → re-release.

**Dependencies in brief:** Cluster B (hotspot remap) **before** QA. ART re-rolls run parallel
to DEV code, but Developer staging + guard-retire depend on ART delivery. R6-002 ($0 PIL) and
Cluster A are independent of ART.

**Proposed regression scope: FULL QA regression.** This build touches shared systems —
item-lifecycle/pickup state machine, overlay compositing, and hotspot geometry across
multiple views (cross-zone reach). Art-only items (R6-011, R6-002, R6-004) would individually
be targeted, but they ship in the same build, so they fold into the full pass. QA has final say.

## 4. Art-spend forecast (headroom $3.20 of the $23.00 cap; live total $19.80)

| Generation | Method | Expected | Worst case |
|------------|--------|----------|-----------|
| R6-011 recipe spiral (5-dot CCW) | crop-scoped edit, 1 glyph | ~$0.05 | $0.11 |
| R6-002 EARTH glyph re-stamp | deterministic PIL | $0.00 | $0.00 |
| R6-004 band sweep (6 views × padded edges) | PIL content-fill first; nano crop-edit fallback | ~$0.30 (PIL-heavy) | ~$1.30 |
| R6-007 re-roll flame1/2/3 + slots-seated (4 plates) | crop-scoped off fresh bench/cabinet base | ~$0.44 | ~$1.20 |
| **Total** | | **~$0.79** | **~$2.61** |

Both expected (~$0.79) and worst case (~$2.61) fit under the **$3.20** headroom. Prefer $0
PIL wherever content-preserving fill is achievable to protect margin.

## 5. Post-release delta (Producer to apply — single-writer files)

**`specs/progression-ledger.md`** (append under Cumulative spend):
> Post-release feedback round 6 (build-11 milestone, processed 2026-07-14). No difficulty
> rescore — no balance change; Level 1 holds 6.0. Mechanics touched: container-reveal→collect
> taken-state rendering (close-up + wide) and hotspot/overlay re-frame coordinate remap (both
> render/UX, not logic); rusted key demoted to non-collectible decoy (no solve path used it);
> grimoire recipe stir glyph corrected to canon (5 CCW — clue, not solution). Art re-rolls this
> round: recipe spiral crop-edit, EARTH glyph re-stamp ($0), re-frame band sweep, un-deferred
> QA-B10-002 flame1/2/3 + slots-seated. Est. art spend this round ~$0.79 (worst case ~$2.61) —
> within the $3.20 headroom on the $23.00 cap. R6-009 poker-lifecycle: unconfirmed; gated on
> screenshot-based alt-order UI validation before release.

**`specs/project-state.md`** (new resume entry):
> Post-release feedback round 6 processed 2026-07-14 (build-11 milestone on TestFlight
> "Within 1.0 (build 12)"). Routed changelist:
> `specs/levels/level-1/round6-routed-changelist.md`. Two systemic Developer clusters
> (A container/pickup taken-state render; B re-frame hotspot/overlay coordinate remap) + legacy
> un-defer (R6-007, retire 4 KNOWN_LEGACY_SOURCES) + art singles (R6-011 5-CCW recipe, R6-002
> EARTH glyph, R6-004 band sweep, R6-003 non-collectible decoy, R5-002 About credit). R6-009
> poker soft-lock UNCONFIRMED → screenshot-based alt-order UI playthrough is a hard release gate.
> GATE 1 (changelist review) pending user; GATE 2 (QA screenshot results) before re-release.

## 6. Open questions for the user
None. The two that would have blocked — R6-011 (option a, confirmed) and R6-009 (validate from
screenshots, confirmed) — are already resolved. R6-002's "fix only if simple" is a Producer
judgment (prior verdict: simple, do it). Everything else is routable as classified.
