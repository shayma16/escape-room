# Level 2 — The Clockmaker's Attic — Validation Report

**Validator:** Puzzle Logic Validator
**Input:** `specs/levels/level-2/puzzle-graph.json` (rev 1.0, first validation) + designer summary
**Reference baseline:** L1 rev-1.3 graph + L1 validation report (clue-gating precedent, R6-003 decoy convention)
**Date:** 2026-07-18
**Verdict: PASS-WITH-CHANGES — 1 required fix (Advisory-severity spec-text correction, L1-Fix-1 class) and 5 recommendations. 0 Critical findings. Cleared for user checkpoint review once the required fix is applied by the Designer.**

---

## 1. Solvability — PASS

Full dependency trace from the start state (z1, empty inventory):

| Node | Reachable via | Verdict |
|---|---|---|
| itm-screwdriver, tiles II/IIII/VII/XI, itm-watch-a | free pickups, z1 | PASS |
| p01-dial-door | 4 tiles, all z1 free pickups; ungated | PASS → unlocks z2 |
| p03-cache-dormer | screwdriver + watch-A inspect (both z1) — **solvable before p01, in the start zone** | PASS → great wheel |
| itm-toy-mouse | free pickup, z2 | PASS |
| p02-cat-mouse | mouse (z2) applied at cat (z1) | PASS → watch B, cat-by-door |
| p04-cache-chimney | screwdriver + watch-B inspect + z2 | PASS → oil can |
| p05-free-arbor | oil can + z2 | PASS → arbor-freed |
| p06-gear-train | arbor-freed + great wheel + z2 (36 on rack, 64 from p03) | PASS → unlocks z3 |
| p07-vault-wheels | z3 + clue-views (z1 master clock, z2 clock row — both permanently reachable) | PASS → unlocks z4 |
| itm-winding-key, itm-return-tag | free pickups, z4 | PASS |
| p08-oil-wind | oil can + key + z3 | PASS → clock-wound |
| p09-set-hands | z3 + tag inspect (tag on required path, z4 strictly precedes any knowledge of 7:20) | PASS → hands-at-release |
| p10-start-pendulum | z3, free act | PASS → pendulum-running |
| cond-timelock-release | AND over the three states, order-free | PASS → door-bar-raised |
| p11-exit | condition + return to z1 (z1 always reachable; zones never re-lock) | PASS → **WIN** |

All 11 puzzle nodes, 12 items, 12 clues, and the derived condition are reachable; the win
node is reachable. Every clue is viewable at or before the moment its puzzle first becomes
attemptable (verified per-gate in §7).

**Solution-value arithmetic independently verified:**
- p01 sockets: seated {I, III, V, VI, VIII, IX, X, XII} is exactly the complement of empty
  positions {2, 4, 7, 11}; tiles II/IIII/VII/XI match. ✓
- p06: (A/12)×(B/8)=24 → A×B=2304. Over {16, 24, 36, 40, 48, 72, 64}: **36×64 is the unique
  realizable pair** (48×48 works arithmetically but only one 48 exists — the herring is
  honest). Both arrangements truly commute: (36/12)×(64/8) = 3×8 = 24; (64/12)×(36/8) =
  16/3 × 9/2 = 24. Accepting both is mathematically correct. ✓
- p07: ★=6; Eiffel 6+1=7; Liberty 6−5=1; Fuji 6+9=15→III. Header order (★, Eiffel,
  Liberty, Fuji) → VI·VII·I·III matches `solution_fixed`. Real-world offsets (Paris +1,
  NY −5, Tokyo +9 vs London) are also factually accurate. ✓
- p09: mirroring 7:20 across the vertical axis: hour hand 220°→140° (4⅔ h), minute
  120°→240° (40 min) — the mirror of 7:20 genuinely *looks like* 4:40, so the naive-copy
  trap value and the D1 render contract are internally consistent. 40 min sits on a
  5-minute detent. ✓

**Orphan check — PASS.** Watches A/B and the return tag have `uses: []` by design
(clue-carriers; declared in notes). State `cat-by-door` (p02) is consumed only as the
p11 silent-nudge beat — decorative, acceptable. Every other yield feeds a consumer.

---

## 2. Soft-lock analysis — PASS (no soft-locks found)

Mistake-path probes:

| Player mistake | Outcome | Soft-lock? |
|---|---|---|
| IV tile seated in socket-4 | Whir-stall, pops back to tray; IIII still in play | No |
| Any tile in wrong socket, repeatedly | Pop-back; correct seats persist; unlimited | No |
| Toy mouse wound/placed anywhere but the cat | Circles, returns to inventory (D4) | No |
| Sweep-pry boards/bricks before inspecting the watches | Uniform "doesn't budge"; nothing consumed; re-attempt always possible | No (UX note, §7) |
| Mount any wrong gear pair, crank | Runs fast/slow, latch-slip clack; gears freely remountable; great wheel returns to inventory | No |
| Mount gears before oiling the arbor | Crank still seized; harmless | No |
| Wrong vault code incl. the +IX misread (VI·VII·I·IX) | Hatch shut, wheels retain position, unlimited | No |
| Set hands to naive 4:40 (mirrored-dial trap) | Clock sits there; nothing consumed; unlimited adjustment | No |
| Winding key inserted before oiling drum | Seats but won't turn; squeal restates the need; nothing consumed | No |
| Set correct hands while p09 gated (lucky 1/144), view tag later | D6 stale case: asserts on dial close-up re-entry — see Recommendation R2 | No (perceived-bug risk only) |
| Move the hands after the strike has fired | door-bar-raised is latched permanently | No |
| Backtrack z4→z3→z2→z1 at any point | All zone gates latch open permanently | No |

**Consumable audit — PASS.** The toy mouse is the only by-design consumed item, has exactly
one use, and cannot be lost elsewhere (D4). Screwdriver (2 uses) and oil can (2 uses, never
emptied) follow the L1-poker uses-driven lifecycle with complete `uses` lists. Great wheel
is freely remountable and never consumed. Nothing multi-use can be spent early; no
consumable can be wasted into unwinnability.

**UNGATED p06 wedge check — PASS.** No partial-placement state is irreversible: gears
mount/unmount freely at all times, the fixed pinions are non-removable, wrong ratios end in
a latch-slip (never a jam state), and the panel latch only ever moves one way (open,
permanent). There is no state in which the automaton wall wedges.

**All seven anti_softlock_invariants independently confirmed true as stated.**

---

## 3. Zone-unlock integrity — PASS

| Zone | Intended unlock | Prerequisite zones only? | Alternate entry? |
|---|---|---|---|
| z2 Movement Loft | p01 (4 tiles, all z1) | z1 only | None modeled |
| z3 Behind the Great Dial (hidden) | p06 (arbor-freed ← oilcan ← p04 ← watch B ← mouse ← z2; great wheel ← p03 ← z1) | z1 + z2 only | None modeled |
| z4 Vault (hidden, nested in z3) | p07 (clues in z1 + z2, both viewable strictly before z3 exists — ordering C pre-computes the code) | z1 + z2 + z3 | None modeled |

No circular dependency: each gate's full requirement closure lives strictly upstream.
Both hidden zones are reachable only via their single intended unlock edge; no early-entry
sequence exists (verified against every item/clue location — nothing in z3/z4 is obtainable
before its zone opens; watch B is pinned under the cat until p02). The nested
hidden-zone structural requirement (principle 7) is satisfied: z4 nested inside hidden z3.
Post-unlock backtracking cannot strand: all four gates latch open, z1 is required and
reachable for the finale, and the endgame condition's inputs all persist.

---

## 4. Path consistency — PASS (with one spec-text correction required)

The state model is correctly requirement-based: zone flags, item-held, latched states,
clue-viewed flags, and one derived condition (`cond-timelock-release`, an order-free AND —
orderings B and C exercise different completion orders of the trio). p06 accepts both gear
arrangements as an unordered set. No step-order tracking anywhere. All interleavings
satisfying the requirement edges resolve to the same completable end state.

**Example orderings traced step-by-step:**
- **Ordering A** — every requirement satisfied at each step. **PASS.**
- **Ordering B (pendulum-first, hands-before-winding)** — valid; includes "take key +
  tag". Correctly exercises p08-last latching. **PASS.**
- **Ordering C (knowledge-first)** — **INVALID AS WRITTEN (Required Fix 1).** After
  "p07 first thing in z3 → z4" it proceeds directly to "p08" and later "inspect tag"
  **without ever taking the winding key or the return tag** (z4 pickups). p08 requires
  itm-winding-key; the tag inspect requires holding itm-return-tag. The underlying graph
  is consistent — only the example text is defective. Identical defect class to L1
  Required Fix 1; must be corrected before the Blind Playtester / Developer treat it as a
  reference path. Valid correction: insert "take winding key + return tag" immediately
  after "→ z4". (Designer to confirm — Validator does not redesign.)

**True parallelism width:**
- z1-only stage: width 2 (p01 tile scavenge ∥ p03 dormer cache — p03 is fully solvable in
  the start zone) plus free knowledge gathering (master time, slate, watch A).
- Post-p01 midgame: 3 genuine streams as claimed (pointer-watch stream p02→p04; machine
  stream p05→p06 — internally serial; knowledge stream for p07), width 3.
- z3 stage: width 3 (p07 ∥ p10 ∥ drum-oiling half of p08; p09 pends on the z4 tag).
- z4/endgame: the p08/p09/p10 trio is fully order-free, width 3.

---

## 5. Real-world-knowledge fairness

| Fact | Puzzle | Ruling | Notes |
|---|---|---|---|
| Roman numerals I–XII | p01, p07 | **PASS — clearly fair** | 8 seated tiles + every dial in the room as decoder; user-requested ingredient. |
| Clock-face layout (12 top, clockwise) | p01, p03, p04 | **PASS — clearly fair** | Anchored by seated tiles and every in-room dial. |
| IIII-not-IV dial convention | p01 | **PASS — borderline, acceptable as designed** | Genuinely not universal knowledge, but it is not actually *required*: three in-room faces display IIII (observable evidence, not recall), and the wrong-tile cost is one pop-back with no lockout — self-teaching. User decides at checkpoint (see flag ruling 1). |
| Time zones exist as a concept | p07 | **PASS — fair** | All offsets stamped in-world; nothing memorized. Concept-level only; user-requested. |
| Landmark silhouettes → cities | p07 | **PASS — fair AND not required** | Pictogram-to-pictogram matching between plates and headers fully suffices; city names never needed. |
| 12-hour wrap (15 → III) | p07 | **PASS — fair** | The wheel physically offering only I–XII is the decisive in-room affordance; the +IX misread trap costs nothing (unlimited attempts). |
| Gear ratios (bigger=slower; stages multiply) | p06 | **PASS — borderline-fair, the level's peak** | The two-stage multiplication is the one genuine arithmetic stretch. Backups are adequate: the slate's worked wordless diagram, live too-fast/too-slow crank feedback (intended reasoning material), and a bounded (~21 unordered / ~42 ordered pairs) tedious-but-finite experimentation space. Accepted as the ledger-mandated escalation; single most likely stuck point — Blind Playtester must time it. |
| Mirror reversal behind a translucent dial | p09 | **PASS — inference, not trivia** | The reversed numerals sit in the same close-up as the setting crank; evidence base is co-located and permanent. |
| Barometer ≠ clock | rh-barometer | **PASS — no knowledge required** | Fixed needle + weather pictograms; accepts no input. |

No real-world fact is load-bearing without an in-room zero-knowledge or trial-safe backup.
**Fairness gate: PASS.** Register is complete — I found no unregistered RWK surface
(gear-tooth counting is covered under ratios; mirror-time arithmetic under mirror
reversal; "vault lock" and "will return tag" concepts carry no required knowledge).

---

## 6. Color-blind safety — PASS (mandatory gate)

The graph claims no color differentiation exists anywhere. Verified per-element against
every color-involving element actually referenced by puzzles/clues, not just the
`colorblind_safety` sample:

| Element | Non-color cue | Holds? |
|---|---|---|
| 6 rack gears + great wheel (p06) | Size + countable teeth + stamped Arabic numerals; "never color" explicit in visually_necessary_elements | **Yes** |
| Brass/bronze/steel finishes (incl. bronze great wheel vs brass rack) | Declared ambient; discrimination is by stamp/size/teeth | **Yes** |
| Numeral tiles + door sockets (p01) | Engraved numerals; positional anchoring by 8 seated tiles | **Yes** |
| World-clock row (p07) | Landmark silhouettes + stamped offsets — shape + symbol | **Yes** |
| Vault wheels (p07) | Pictogram headers + engraved I–XII | **Yes** |
| Mirrored dial (p09) | Numeral SHAPE reversal; amber glow is luminance/atmosphere, not a discriminator | **Yes** |
| Rust/seizure cues (p05, p08) | Motion cues (crank rocks-and-stops; key seats-but-won't-turn) + audio squeal; rust bloom is redundant texture | **Yes** |
| Mural/cam feedback (p06) | Speed/motion + identical latch-slip clack | **Yes** |
| Endgame states | Weight height, pendulum motion, bar position — all spatial/motion | **Yes** |
| Cat states, sunbeam, golden light | Staging/atmosphere only; never load-bearing | **Yes** |

**No puzzle relies on color-only differentiation anywhere in the level. Hard gate: PASS.**
Art Director note: the non-color redundancies above are load-bearing — especially
countable teeth + stamped counts at close-up, and mirrored-numeral legibility (D1).

---

## 7. Clue-gating — PASS (with 1 UX advisory + 1 dev-constraint recommendation)

Per-gate satisfiability (every ordering):

| Gated puzzle | Zone | Required views | Clue location(s) | Viewable before puzzle reachable? | Carries the code's full information? |
|---|---|---|---|---|---|
| p03-cache-dormer | z1 | clu-watch-a | itm-watch-a (z1 pickup, inspectable anywhere forever) | **Yes** | **Yes** — sole carrier (board has no tell) |
| p04-cache-chimney | z2 | clu-watch-b | itm-watch-b (from p02; obtainable with the same z2 access p04 needs) | **Yes** | **Yes** — sole carrier |
| p07-vault-wheels | z3 | clu-master-time + clu-worldclock-row | z1 + z2, both permanently reachable | **Yes** | **Yes** — jointly the entire code |
| p09-set-hands | z3 | clu-return-tag | itm-return-tag (z4 — strictly precedes any possible knowledge of 7:20) | **Yes** | **Yes** — sole source of 7:20 |

No gate can false-block an earned solve: in every case the gated clue is the *only* source
of the gated information (the L1 page-A asymmetry is not repeated — good). The
clu-mirrored-numerals exclusion from p09's gate (self-satisfying, same close-up as the
crank) is the correct call, matching the L1 p04 precedent. Ungated calls (p01 pop-back,
p02 refusal grammar, p05/p08/p10 physical acts, p06 mechanical truth) are all consistent
with the rev-1.3 information-carriage principle.

**No-tell at the pry-sweeps (p03/p04) — UX risk flagged (Advisory A1).** This level
extends the no-tell rule to physical hotspots for the first time: while gated, the correct
board/brick reads as inert scenery, indistinguishable from truly-inert neighbors. The new
risk class: a player who sweep-pried the correct board *before* inspecting the watch may
mentally eliminate it ("tried it, it doesn't budge") and not re-try after earning the clue.
Mitigation already in the design is real: the watch + ring specify one exact board/brick,
so a post-clue player pries the indicated spot regardless of memory — and sweep-pryers are
precisely the brute-forcers the gate exists to stop. I judge the pattern sound, but the
Blind Playtester must specifically probe the "pried it earlier, watch now inspected"
sequence, and this stays on the user-checkpoint list (designer flag 7).

**Stale-case handling (D6) — sound, with one harmonization recommendation (R2).**
p03/p04 have no stale case (pry is explicit). p07's stale-correct-wheels resolves on
close-up re-entry per D6 — clean, matches L1 IC-1. p09's stale case (correct front-time
pre-set while gated, tag viewed later, possibly in z4/z1): p09's gate_behavior promises
re-evaluation "on close-up entry **(or on any subsequent state change)**", but D6 as
inherited verbatim from L1 triggers only on input events and close-up entry, and D2 lists
only the three condition inputs plus z3 close-up entry. As written, the strike could
require a redundant dial-close-up revisit after the tag inspect. Never a soft-lock (the
close-up is always re-enterable) and the trigger scenario needs a lucky 1/144 pre-set, but
the two texts should be harmonized and the Developer should treat clue-view events as
re-evaluation triggers for p09 (see R2).

---

## 8. Difficulty scoring (official ledger values)

| Zone | Designer | **Validator (official)** | Basis |
|---|---|---|---|
| z1 Main Attic | 5.5 | **5.5** | p01 scavenge + convention trap with a ≤1-attempt valve (4.5); p02 cross-zone character beat (4); p03 pointer-watch inference — symbol binding + hand-as-direction, genuinely novel (6). Agree. |
| z2 Movement Loft | 7.0 | **7.0** | p04 pointer instance 2, easier once the pattern lands (5); p05 trivial (2); **p06 wordless two-stage ratio with unique-pair discovery and the 48×48 herring — the level's reasoning peak (7.5)**. Agree. |
| z3 Behind the Great Dial | 7.5 | **7.0** | p07 star-link → reference 6 → offsets → wrap → pictogram rebinding, a genuine 7; p09 mirror inversion with the 4:40 trap (6.5–7 — the evidence is co-located and permanent); p08/p10 trivial closers. Nothing here reaches an 8-class: all data is stamped in-scene, nothing is consumable, nothing locks out. −0.5 vs designer. |
| z4 Vault | 5.0 | **3.5** | A reward room: two free pickups + lore. The only cognition is recognizing the tag as the release-time clue. L1's z4 earned its 5.0 with the three-system convergence bloom; L2's z4 has no puzzle at all. −1.5 vs designer. |
| **Overall (ledger)** | 7.0 | **6.5 / 10** | 11 puzzle nodes + 1 derived condition, 4-deep nested zone chain, 3-stream midgame, heavy cross-zone binding, 4 honest red herrings, two arithmetic inference chains and one perceptual inversion. Escalation over L1's 6.0 is **real (+0.5) and fair**: it comes from chain depth and layered reasoning, never obscurity or pixel-hunting. Same correction applied to L1 (designer 6.5 → official 6.0): the anti-frustration invariants (no lockouts, nothing wasteable, all code data stamped in-scene, pop-back valves, bounded p06 brute space) pull effective difficulty under the structural estimate. Target band 6.5–7.5: met at the bottom edge. Blind-solve 75–120 min: plausible; p06 and p07 will dominate; Blind Playtester calibrates. |

**Ledger note:** four genuinely new mechanics (gear-ratio train, pointer-watch caches,
time-zone code lock, mirrored-dial setting) with two deliberate L1 echoes (tool-on-hotspot,
character beat) — repetition posture is healthy for Level 3 planning.

---

## 9. Schema & convention conformance — PASS

- **Schema:** matches L1 rev-1.3 structure section-for-section (zones/views,
  derived_conditions, typed nodes, typed edges incl. clue_gate edges, solve_path_notes,
  developer_notes, red_herrings, anti_softlock_invariants, visually_necessary_elements,
  colorblind_safety, difficulty estimate, ledger mechanics, RWK register). Edge list is
  harmonized with node-level `requires` (no L1-A6-class gaps found).
- **Red herrings / R6-003:** all four decoys are non-collectible and never enter
  inventory. Note: unlike L1's itm-rusted-key (an item node with `obtained_by: "none"`,
  `collectible: false`), L2 models decoys purely as scene elements + red_herrings entries
  with no item nodes at all — a *stronger* form of the convention (nothing to
  mis-collect). Conformant.
- **Near-wordless:** no text-riddle dependencies; all payloads are numerals, pictograms,
  silhouettes, stamps, and motion. One art-time caution: the "will return" tag must carry
  its information in the mini dial + door pictogram only — any literal lettering must be
  decorative and non-load-bearing (see R4).
- **Static fixed solutions:** all solution values fixed; no randomization anywhere.
- **Counts:** 11 puzzles, 1 derived condition, 12 items, 12 clues, 4 red herrings, 4 zones
  (2 hidden, 1 nested) — matches the summary.

---

## 10. Ruling on the designer's 7 borderline flags (Validator's independent take)

1. **IIII convention (p01) — CONCUR, keep as designed.** The demote option (mis-pegged IV)
   is unnecessary: the knowledge is never required — three in-room faces are observable
   evidence, and the pop-back valve makes the worst case one extra attempt. Demoting would
   also delete the level's best small teaching beat. User decides at checkpoint.
2. **Gear-ratio arithmetic (p06) — CONCUR, accept.** Fair-hard and exactly the ledger's
   mandated escalation; the slate diagram + live speed feedback + bounded pair space are
   adequate backups. It is the likeliest stuck point — Blind Playtester should time it
   specifically. User confirms the arithmetic-puzzle acceptance.
3. **p06 deliberately UNGATED — CONCUR.** The mechanical-truth exception is principled and
   matches L1's p09-mirror precedent (a physical apparatus must respond, or it reads
   broken). The ~30-40-pair brute space with a full crank cycle per test is a real
   deterrent; wedge check in §2 confirms no irreversible state. Keep ungated.
4. **12-hour wrap (p07) — CONCUR, fair.** The I–XII wheel is a physical affordance that
   forces the conversion; the +IX misread costs nothing. No change.
5. **Mirrored-dial trap (p09) — CONCUR, keep the trap; do NOT add the inspection mirror.**
   The evidence (reversed numerals) is permanent and co-located with the crank; the silent
   4:40 failure is consistent with the level's failure grammar; and the gate cannot
   false-block since 7:20 is unknowable without the tag. This is the level's signature aha
   — the mirror accessory would demote it to execution. Blind Playtester should watch how
   long the 4:40 plateau lasts.
6. **Landmark pictograms — CONCUR, fair and not required.** Pictogram-to-pictogram
   matching fully suffices; register entry is protocol completeness only. No change.
7. **Pry-sweep no-tell gating (p03/p04) — CONCUR with the pattern, with a new advisory.**
   The extension of L1's gating policy to physical sweeps is sound (the watch is the sole
   information carrier, so no earned solve can be blocked), but it introduces the
   elimination-memory UX risk described in §7 (Advisory A1): a pre-clue sweep-pryer may
   mentally rule out the correct board. Mitigated by the watch specifying the exact spot;
   Blind Playtester must probe the exact sequence; user confirms comfort with the pattern.

---

## 11. Required changes vs recommendations

### REQUIRED (route to Designer via Producer; apply before Blind Playtester / Developer consume the graph)

1. **Fix example_ordering_C (Advisory-severity spec-text defect; L1-Fix-1 class).**
   Ordering C omits the z4 free pickups: it runs "p07 … → z4" straight into "p08" and
   later "inspect tag" without ever listing "take winding key + return tag". As written,
   p08's itm-winding-key requirement and the tag inspect are unsatisfied. The graph itself
   is consistent; only the example is wrong. Insert the pickups immediately after the z4
   unlock. (Not Critical — no design change, no solution value touched.)

### RECOMMENDATIONS (non-blocking)

- **R1 (UX / Blind Playtester probe):** p03/p04 no-tell pry gating — explicitly test the
  "swept the correct board pre-clue, inspected the watch, returns" sequence for the
  elimination-memory failure mode (§7). Surface at user checkpoint alongside designer
  flag 7.
- **R2 (Developer constraint / spec harmonization):** p09's gate_behavior promises stale
  re-evaluation "on any subsequent state change," which is broader than the inherited-
  verbatim D6 (input events + close-up entry) and than D2's trigger list. Harmonize:
  treat clue-view flag changes (specifically clu-return-tag) as re-evaluation triggers
  for p09 and for cond-timelock-release, so a stale-correct-hands state resolves without
  a redundant dial-close-up revisit. Never a soft-lock either way; this closes a
  perceived-bug edge case.
- **R3 (Art Director, physical plausibility):** p06 accepts either gear on either post,
  and any of 7 gears "meshes" on both posts — with fixed post centers, real gears of
  different diameters could not all mesh. Genre-standard abstraction and explicitly
  accepted by the design, but the frame's art should suggest slotted/adjustable arbors
  (or generous mesh clearance) so the mechanically-literate player isn't thrown by the
  "mechanical truth" framing.
- **R4 (Art / near-wordless):** the "will return" tag must carry its payload entirely in
  the mini dial + door pictogram; any literal shop-sign lettering must be decorative,
  illegible-as-instruction, or omitted.
- **R5 (Ledger):** record z4 at 3.5 (reward room, no puzzle) rather than the designer's
  5.0; if a future revision wants z4 to earn more, that is a design decision, not a
  validation requirement.

---

## 12. Verdict

| Gate | Result |
|---|---|
| Solvability (incl. arithmetic verification of all four code values) | **PASS** |
| Soft-locks (incl. mistake paths, consumable audit, ungated-p06 wedge check, mirrored-trap no-consume) | **PASS** |
| Zone-unlock integrity (z1→z2→z3→z4 nested chain, no early entry, no circularity, safe backtracking) | **PASS** |
| Path consistency (orderings A/B pass; ordering C spec text defective — Required Fix 1) | **PASS with fix** |
| Real-world-knowledge fairness | **PASS** (3 borderline entries, all with valves; user rules at checkpoint) |
| Color-blind safety (mandatory) | **PASS** |
| Clue-gating (satisfiability, information-carriage, no-tell, stale cases) | **PASS** (A1 UX advisory; R2 harmonization) |
| Schema / R6-003 / near-wordless / static-solutions conformance | **PASS** |
| **Critical findings** | **0** |
| **Required fixes** | **1** (spec-text, Advisory severity) |
| **Official difficulty (ledger)** | **6.5 / 10** (z1 5.5, z2 7.0, z3 7.0, z4 3.5) — escalation over L1's 6.0 is real and fair |

**Overall verdict: PASS-WITH-CHANGES.** The design is logically sound, soft-lock-free,
color-blind-safe, and fairly escalated. Apply Required Fix 1 (ordering C text) before the
Blind Playtester stage; the borderline-flag rulings in §10 go to the user checkpoint.
