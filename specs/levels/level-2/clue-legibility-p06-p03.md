# Clue-Legibility Redesign — p06 (gear train) and p03 (dormer cache)

_Theme & Puzzle Designer, 2026-08-07. Level 2 "The Clockmaker's Attic", branch
`level2-clockmakers-attic`. Target graph revision: **rev 1.4**. SPEC ONLY — no code._

> ## **REVISED PER VALIDATION — rev A → rev B (2026-08-07)**
>
> Revised against `validation-report-rev1.4.md` (**PASS-WITH-CHANGES**, 0 Critical, 9
> required advisory fixes RF-1…RF-9, recommendations RC-1…RC-6). **All nine RFs applied.
> RC-1 and RC-2 adopted into the spec** (Producer-directed); RC-3…RC-6 folded in as recorded
> art/implementation constraints and a playtest probe.
>
> **User rulings now final and carried in this revision:**
> - **True 6.0 ACCEPTED.** All aids ship. **F3 stays** (the frame-side chalk crib is NOT held
>   back). The 6.0 is still PROVISIONAL until the blind re-check returns and must not be
>   written to `progression-ledger.md` before then.
> - **A5 = p03-only.** p04's chimney brick gets **no chalk mark**. The blind playtest measures
>   the asymmetry (probe P12). RC-1's wide-view ring echo for p04 is **separable from A5** and
>   ships — it gives p04 no mark and pre-empts no decision.
> - A1, A2, A3, A4, A7, A8 approved 2026-08-06.

### RF / RC application register

| # | Requirement | Status | Where applied |
|---|---|---|---|
| **RF-1** | No novel `clue`-type edge | **APPLIED** | §1d delta 2 rewritten; §7 G7 + G24 ("add no edge") |
| **RF-2** | Tally persistence/reset semantics incl. the 3 non-integer pairs | **APPLIED** | §1b F4 rewritten; D13 §7 G16 |
| **RF-3** | Worst case is 48 strokes, not 54 | **APPLIED** | §1b F4, §1d, D13 |
| **RF-4** | Fix the self-contradictory "continuous meshing chain with both posts empty" | **APPLIED** | §1b F1, §1d delta 7, §3 row 1, §7 G19 |
| **RF-5** | Propagate the §6.3 change to ALL FOUR rule sites; §6.4 must not extend it to p04 | **APPLIED** | §8 (5 edit sites, incl. hard-no #7 and §6.4 restated in full) |
| **RF-6** | Scope the `art_impact` clue-state-render clause | **APPLIED** | §2d delta 7; §7 G12 |
| **RF-7** | Two colour-blind prohibitions + luminance floor written into the spec | **APPLIED** | §1b F3/F4, §2b C2, §3 notes, §7 G20 |
| **RF-8** | Correct the RWK register's false "countable clack cadence" backup | **APPLIED** | §7 G22 + G23 |
| **RF-9** | File the §6.3 change as a SANCTIONED REVERSAL, not a clarification | **APPLIED** | §5 A6 rewritten; §7 G2 revision note; §8 header |
| **RC-1** | z2 ⚙-ring wide↔close-up echo, $0 | **ADOPTED — ships as C3** | §2b C3; §3 row 7; §7 G6/G9/G19 |
| **RC-2** | Record the principled basis for the p03/p04 asymmetry | **ADOPTED** | §2b C3 rationale; §7 G9 (p04 `notes`) |
| RC-3 | Slate art constraints (cam tally separated; diagonal reads as a 5th stroke) | recorded | §1b F2; §3 row 2 |
| RC-4 | F4 tedium guard — skippable accrual, statically readable final block | recorded | §1b F4; D13 |
| RC-5 | Playtest probe for the A5 false-negative | recorded | §9 probe **P12** |
| RC-6 | `ov-cache-marked` × `ov-cache-cat-gone` compositing | recorded | §2b C2; D12; §3 row 6 |

---

## 0. Scope, evidence, and binding invariants

**In scope (user ruling, sequenced): exactly two beats.**

| Beat | Verdict source | What the user actually said |
|---|---|---|
| **p06-gear-train** | R8-completion (build 16), user answer #1 | "THE GEAR WALL — which gears to mount / the ratio reasoning didn't land from the in-game clues" |
| **p03-cache-dormer** | R8-009 (build 15) | "i couldn't understand even when i read the walkthrough… i used the screwdriver on the floorboard under the cat, by randomly clicked" |

**Explicitly NOT in scope:** p09 (mirror) and p02 (mouse) — deferred for a blind re-measure
after the P/Q/T rendering fixes land, per `build17-routed-changelist.md` §3.

**Binding invariants (unchanged by everything below):**

- **Solutions are byte-stable.** p06 remains the unordered set {36-tooth rack gear,
  64-tooth great wheel} on posts A/B in either order, target 24 crank : 1 cam. p03 remains
  the single cache at the ⌂ ring's 3-o'clock (board index D3, as-built a single
  always-correct hotspot). **Nothing here changes an answer — only its discoverability.**
- **The p03/p04 pointer MECHANIC stays collapsed** (user ruling KEEP SIMPLE, R8-009). No
  multi-board selection is restored.
- Requirement-flag state model. No new state variables, no new gates, no gate removals.
- Anti-softlock invariants untouched. Clue-gating conventions per rev 1.3 (D6/D7 semantics,
  no-tell rule, D10 faint-tell) preserved — with two textual clarifications and **one
  sanctioned reversal** listed in §5 (A6, rewritten per RF-9).
- Near-wordless. Every element below is a glyph, a stroke count, or a physical part. **No
  text is added anywhere.**
- Difficulty target: the rev-1.3 6.5 is superseded. The Validator's provisional **6.0** is
  user-accepted as a true 6.0 in preference to a false 6.5, and stays provisional until the
  blind re-check (§5).

**Critical scoping caveat the Producer must carry to the user and the Blind Playtester:**
p03's build-16 clarification (`Level2CloseUpVisuals.ringClues` — the canonical hour hand
composited onto `cu-house-ring` once watch A has been inspected, per implementation-notes
"USER RULING — p03/p04 KEEP SIMPLE + CLARIFY") **shipped after the R8-009 report and has
never been measured.** The user's build-16 playthrough did not cite p03 among the
guide-mandatory beats. So the changes in §2 are **additive to an untested fix**, and the
blind re-check must measure the two together. I am not claiming the build-16 fix failed; I
am closing a gap it structurally cannot close (it lives in a close-up that contains no
floor). The same is true, and even less measured, for p04: `clu-ring-chimney`'s hotspot did
not exist until the build-16 wiring batch.

---

## 1. BEAT p06 — the gear wall

### 1a. Why the current clue chain fails

The intended chain has six hops. Only hops G1 and G6 are supported by anything the player
can see at the moment they need it.

| Hop | What the player must do | Support in the build | Status |
|---|---|---|---|
| **G1** | Notice the slate is a schematic of a machine | `cu-slate` is the focal object of z1 v-bench; contract-passed | **lands** (blind playtest: "reads immediately as a schematic of *something*") |
| **G2** | Map the schematic onto the physical frame: crank→XII pinion→post A→VIII pinion→post B→cam | The frame is in **z2**, the slate in **z1**, typically 30–60 min apart. The mapping evidence is the XII/VIII stamps appearing in both places | **fragile — and see the defect below** |
| **G3** | Convert the drawn marks into a target: 24 tallies on the crank + 1 notch on the cam = "24 crank turns per cam turn" | The 24 tallies ring the crank circle; the cam carries a *notch*, not a mark | **fails — invented notation** |
| **G4** | Apply ratio = tooth quotient, stages multiply → (A/12)(B/8)=24 → A×B=2304 | RWK, ratified at checkpoint | lands for some, hard for many |
| **G5** | Search {16,24,36,40,48,72,64} for the unique product pair | Stamps + countable teeth are correct and legible | lands *given* G4 |
| **G6** | Mount and crank | Build-16 pictogram affordances (gear cutouts, dashed empty-post seat rings) | lands |

Three specific defects, in priority order:

**Defect 1 (probable root, G2) — the second stage may not be physically depicted.**
`asset-manifest.json` records the carry-in stamp fix as: *"XII re-stamped contained on the
crank-pinion face annulus… **VIII engraved on the post-A bracket panel**"*. XII sits on an
actual pinion face; VIII sits on a **bracket panel**. If no 8-tooth pinion is *drawn*
coaxially at post A, then the frame the player looks at has: a crank with a gear, one empty
post, another empty post, a cam — and a stray Roman numeral on a bracket. **The two-stage
structure is then not visible at all**, and "(A/12) × (B/8)" is unrecoverable no matter how
well the slate is read. This must be verified against the shipped plate before anything
else; if confirmed, it alone explains "the ratio reasoning didn't land."

**Defect 2 (G3) — the slate compares unlike marks.** "24 tallies" versus "one notch" is a
comparison the player has to *invent* the terms of. A tally is a count-mark; a notch is a
piece of mechanism. Nothing tells the player they are the two sides of the same ratio. The
blind playtester bridged this in ~25 minutes of dedicated puzzling; a real player reads the
24 tallies as decoration or as "crank it 24 times" (the playtest itself logged that exact
misread as a variant path costing ~5 min).

**Defect 3 (G3/G4 fallback) — the sanctioned no-algebra route does not exist in the
build.** Graph D5 and playtest 2b both declare the counting route legitimate and load-
bearing: *"the cranks-per-clack cadence must be consistent and countable."* In the build,
cranking is a single button press that runs a cam cycle. **There is nothing to count.** The
one honest path for a player who won't do algebra was specified and then not delivered — so
every wrong pair produces only "too fast / too slow", which the playtest already rated
*"weak — the target ratio is not an extreme, so faster/slower doesn't hill-climb."* The
player is left with pure algebra or pure brute force over ~21 unordered pairs.

**Why the failure clusters where the user said it did:** all three defects sit on
*multi-step inference* hops. Hop G5 (find symbol → match number), which is the
single-lookup class the user's playthrough demonstrably solves, was never the problem.

### 1b. Redesigned clue presentation

Four changes. All use existing canonical art or existing deterministic renderers. **None
adds a hotspot** (everything is read through the existing `gear-frame` / `slate` hotspots),
so no M1 registration or iPad-band re-litigation is required.

---

**F1 — Depict the second stage. (fixes G2; highest priority)**

*Element:* z2 v-frame gear frame, post A.
*Views:* `z2-frame-base` (wide) + `cu-gear-frame` (close-up).
*Change:* post A must visibly carry a **small pinion of exactly 8 countable teeth,
coaxial with the empty square arbor**, with the canonical **VIII** stamped on that
pinion's own face annulus — exactly the treatment the crank's XII pinion already has. The
bracket-panel VIII engraving is removed or demoted to secondary.

**Mesh requirement — REVISED per RF-4 (the rev-A wording was self-contradictory and
Asset-Gen could have drawn a closed train):**

> The drive path **crank-XII → \[GAP: POST A\] → post-A VIII → \[GAP: POST B\] → cam** must
> read as **one drive path with two identified gaps**, at posts A and B, **each gap visibly
> sized to receive a wheel**. With both posts empty the crank pinion and the post-A pinion
> **mesh with nothing, and must not be drawn as if they do** — a closed train would make the
> empty posts read as decorative and destroy the exact affordance F1 exists to create. What
> must be legible is the *line of drive* and the *two vacancies on it*, not a continuous
> meshing chain. Cross-reference standing **R3** (slotted / adjustable arbors, so wheels of
> different diameters plausibly mesh once mounted).

*Assets:* `l2_z2_build.render_gear` (the deterministic exact-tooth-count renderer already
used for the six rack gears) at n=8; canonical `render_roman`/numeral stamp from
`specs/tools/l2_glyphs.py`. Same square-arbor-hole rhyme as every other gear in the level.
*Art cost:* **$0** if a deterministic composite blends acceptably onto the timber/brass
(precedent: the 14 existing `ov-mount-*` post overlays are pure `render_gear` composites).
**≤ $0.15** if Asset-Gen judges a crop-scoped NB edit is needed to seat it believably.
*Verify first (A8):* if the shipped plate already depicts an 8-tooth coaxial pinion clearly,
F1 collapses to "move the VIII stamp onto its face" and is unambiguously $0.

---

**F2 — Make the slate compare like with like. (fixes G3)**

*Element:* the chalk ratio diagram.
*Views:* `cu-slate` + the slate region of `z1-bench-base` (wide).
*Changes, all within the existing chalk register (style-guide §Slate + chalk `#E8E4DA` on
`#2E3236`) and the existing deterministic slate renderer:*
1. **The 24 tallies are grouped in fives** — four uprights plus a diagonal strike, four
   groups plus four singles. The count stops being something you must tally-count and
   becomes something you *read*. The hard exact-count contract (`= 24`, asserted in code)
   is preserved verbatim; only the stroke layout changes.
2. **The cam circle gains ONE tally stroke on its rim, in the identical chalk stroke
   style,** alongside (not replacing) its physical single notch. The ratio now reads as a
   direct like-for-like proportion — *this many marks here, one mark there* — instead of
   asking the player to equate a count with a piece of mechanism.
3. No other content change. XII pinion, two `?` wheels, VIII coaxial pinion, cam notch and
   door die all stay exactly as approved.
*Art constraints (RC-3, binding on Asset-Gen):* the cam-rim tally must be **spatially
separated from the 24-block** by a clear margin, so that no player can read a total of 25;
and the five-grouping's diagonal must read as **a fifth stroke**, never as a strike-out or
cancellation (angle and length matched to the four uprights it closes, not overshooting).
*Assets:* existing slate renderer + existing chalk stroke primitive. **$0** (deterministic
PIL). Re-runs the existing 24-count assertion.
*Note:* this touches an **approved, contract-passed plate** — Art Director sign-off (A3,
approved 2026-08-06) is required before Asset-Gen regenerates.

---

**F3 — Put the target where the work happens: the frame-side chalk crib. (fixes the
cross-zone memory burden on G3)  — SHIPS (user ruling: F3 stays)**

*Element:* new chalk marking on the gear frame's own left timber cheek, immediately
adjacent to the fold-out crank.
*Views:* `z2-frame-base` (wide) + `cu-gear-frame` (close-up).
*Content (wordless, no new glyph dies):* the same grouped 24-tally block chalked beside
the crank station, and a single matching tally chalked beside the cam station. **Nothing
else** — not the two-stage schematic, not the `?` wheels, not the pinion stamps. The
*structure* of the train is read off the machine itself (which F1 makes possible); only the
*target proportion* is restated here.
*Rationale:* the clockmaker chalks on things — the slate establishes this as his notation
habit, and D9's dormant easing valve already establishes "small wordless chalk sketch
added to an existing plate" as the sanctioned, $0-class technique for exactly this kind of
staged legibility fix. This is that technique, applied to a beat the user has actually
reported failing.
*Placement constraints (Asset-Gen/Art Director to measure against the shipped plate):*
must sit inside the dual-safe zone, clear the 72 pt iPad pill band, and must **not**
overlap the measured rects of the neighbouring interactive elements — `gear-rack`
(everything left of ≈ x 0.65 is rack territory), `ov-brick-*` (x 0.6711–0.7849), or the
`gear-ring` carve (x 0.7350–0.8050, y 0.4620–0.5960). The frame's left cheek beside the
crank is the intended home. **No new hotspot** — it is plate content read through the
existing `gear-frame` close-up.
*Colour-blind constraints (RF-7, binding):*
- **(a) Luminance floor.** The chalk must hold **≥ 3:1 luminance contrast against its local
  substrate in BOTH the wide and the close-up.** The frame's timber cheek is one of the two
  risk surfaces in this batch, and the fallback NB "chalk-on-timber blend" is exactly the
  operation that could erode it. **Discrimination must never rest on the warm/cool hue
  difference between chalk and timber.**
- **(b) Position, not hue.** The F3 crib block and the F4 live block are distinguished by
  **POSITION ONLY** — a visible baseline, chalked rule, or clear gap between them. They must
  **never** be distinguished by hue, chalk value, or an "old chalk / fresh chalk" treatment,
  and must never read as one continuous block of 24 + N strokes.
*Art cost:* **$0** deterministic (reuses the F2 tally primitive) / **≤ $0.15** if a
crop-scoped NB chalk-on-timber blend is judged necessary.
*Separability (recorded, now moot):* F3 was the separable −0.5 lever. The user has ruled it
**ships**; the level lands at the true 6.0 with the cross-zone binding softened, and
`escalation_rationale` clause (3) is amended accordingly.

---

**F4 — Deliver the counting route that D5 already promises. (fixes G3/G4 fallback)
— REWRITTEN per RF-2 and RF-3**

*Element:* a live chalk tally block on the frame cheek, directly beneath the F3 chalked 24,
separated from it by a visible baseline (RF-7(b)).
*View:* `cu-gear-frame` primarily; mirrored in the wide if the crank is operable there.

**Accrual semantics (RF-2(a) — this is the D11-class ambiguity the Validator flagged, closed):**

- The readout measures **accumulated crank ROTATION since the last cam clack** — *not*
  crossings of a fixed index mark on the crank. One full chalk stroke is laid per **full
  turn of accumulated rotation**; the remainder renders as **one partial stroke**.
- **Why this and not index-crossings:** the realized ratio is `R = A·B / 96`, and every cam
  cycle of a given pair consumes exactly `R` crank revolutions. Measuring accumulated
  rotation therefore renders **the identical picture every cycle** for a given pair — nothing
  oscillates. Counting index-mark crossings instead would drift in phase and produce the
  7 / 7 / 6 oscillation the Validator identified. **Index-crossing counting is prohibited.**
- **The three non-integer pairs, specified explicitly:**

  | Pair | R | Rendered |
  |---|---|---|
  | 16 × 40 | 6⅔ | 6 full strokes + one partial |
  | 16 × 64 | 10⅔ | 10 full strokes + one partial |
  | 40 × 64 | 26⅔ | 26 full strokes + one partial |
  | **36 × 64 (solution)** | **24** | **24 full strokes, NO partial** |
  | all other 17 pairs | integer | N full strokes, no partial |

- **Partial-stroke rendering:** same chalk value, same stroke width, same slot pitch,
  **visibly reduced height (≈ half)** so it cannot be miscounted as a full stroke. It never
  receives a five-group diagonal and is never counted into a group of five. It carries no
  numeric label.
- **Non-integrality is mechanical truth, not a proximity signal.** 6⅔ (far from 24) and 26⅔
  (near 24) render identically in form. The readout still never varies with closeness to the
  target — V4 is preserved.

**Persistence and clearing semantics (RF-2(b) — resolving the "derived, never stored" vs
"the final count persists" contradiction):**

- The block is **transient view/session state**, of exactly the same class as an animation
  frame. It is **never written to the save**, and is **not readable by any gate, condition,
  requirement, or D7 flag**. On save/load it re-derives to **empty**.
- What is drawn is a pure function of **(the currently mounted pair, accumulated crank
  rotation since the last clack)**.
- The **completed-cycle count stays drawn** — so a player who looked away still gets the
  number — **until any one of:**
  1. **any mount or unmount at either post** (clears immediately and completely);
  2. **fewer than two gears mounted** (no pair → no train → nothing drawn);
  3. **scene reload / save load**;
  4. **the start of the next crank press** (redraws from zero).
- Rule (1) is the one that matters: the frame must **never** display a count belonging to a
  configuration that is no longer mounted. That would be a lie about mechanical truth and a
  weak information carry-over.

**Constraints (non-negotiable, for the Validator):** the readout encodes **only the true
realized ratio of the mounted pair** — mechanical truth, identical to what a player could
derive by ear. It **never** hints at the target beyond the F3 chalk, never differs by how
close the pair is, and never varies with any clue-viewed flag. It is ungated, exactly as
p06 is ungated (a mechanically true train must work regardless of what has been read).
**RF-7(c): NO glow, flash, colour change, or any other highlight on the tally block when
the live count reaches 24.** Success differentiation stays exactly where it already lives —
the latch taking and the panel opening.

**Tedium guard (RF-3 corrected + RC-4):** one crank press = one full cam cycle (unchanged
from the build); the tallies accrue during that animation. **Worst case across the whole
gear set is 48 tallies** (64 × 72 = 4608 / 96 = 48) — *not 54, which the rev-A draft
asserted; 54 would require two 72-tooth gears and only one exists anywhere.* The block must
remain legible at 48 (five-grouping makes it so). The accrual animation must be
**skippable / fast-forwardable**, and the persisted final block must be **fully readable
statically without having watched the accrual** — worst case is 48 strokes on *every*
experimental mount. Do **not** implement one-tap-per-turn.
*Art cost:* **$0** — same tally stroke primitive, composited N times at a measured rect.

### 1c. Intended step-by-step inference chain (for the Blind Playtester) — REVISED

A blind player should be able to walk this without the walkthrough:

1. In z1 v-bench, open the slate close-up. It is a chalk drawing of a machine: a circle
   with a block of tally marks around it (four groups of five plus four singles), a small
   wheel stamped **XII**, an unknown wheel `?`, a small wheel stamped **VIII** on the same
   axle, a second `?`, and a last circle with one notch, **one tally mark**, and a little
   door.
2. Read the proportion: **a block of 24 marks on the first circle, one mark of the same kind
   on the last.** The last circle has a door on it. → *"Whatever the machine does,
   twenty-four of the first thing makes one of the last thing, and the last thing opens a
   door."*
3. In z2 v-frame, recognise the drawing: a fold-out crank carrying a small gear stamped
   **XII**; **an empty post-shaped gap**; a small gear stamped **VIII** sharing that post's
   axle; **a second empty gap**; a cam that drives the mural and the wall-panel latch. The
   line of drive is traceable and its two vacancies are obvious. The chalked 24-tally block
   and the single matching tally are on the frame's own cheek, beside the crank and beside
   the cam. → *"This is the drawing. The two `?` are the two empty posts. I choose the two
   wheels."*
4. **Route A (algebra).** A small gear driving a big one slows it by the tooth quotient;
   two stages multiply. (A/12) × (B/8) = 24 → A × B = 2304. The rack offers 16, 24, 36, 40,
   48, 72. No pair works — 48 × 48 would, but there is only one 48 anywhere. → *"A wheel I
   don't have yet must exist."* The great wheel from the floorboard cache is stamped **64**;
   36 × 64 = 2304. Mount 36 and 64 on the two posts, either way round.
5. **Route B (counting — equally sanctioned).** Mount any two wheels and crank once. The
   machine chalks up its own tally block as it turns; at the clack the count sits beneath
   the clockmaker's chalked 24, separated by the baseline. Too few → the pair is too small;
   too many → too big. Rack parts **straddle** the target and cannot reach it — 40 × 48
   reads 20, 36 × 72 reads 27 — so the count itself proves *"a wheel I don't have must
   exist"*, which is the same deduction Route A reaches by arithmetic. A pair that ends on a
   half-height partial stroke is visibly **not a whole number of cranks per cam turn**, which
   is honest mechanical information about that pair and nothing else.
6. **Route C (hybrid, expected to be the common one).** Do the algebra loosely, use the
   tally readout to confirm and to catch arithmetic slips.
7. Crank one full cam cycle at 24:1 → the count lands exactly on the clockmaker's chalked
   24, the mural runs clean, the counterweight drops, and the wall panel swings open onto z3.

**Both orders of {36, 64} across posts A and B are correct** and both must be accepted.

### 1d. Graph / spec deltas for rev 1.4 (p06) — REVISED

Precise change list (verbatim JSON strings in **§7**):

1. **`clu-slate-ratio.content`** — amend to record the fives-grouping and the cam-rim tally.
   `supports`, `viewed_when` (`"slate close-up displayed"`) and its non-gating status are
   **unchanged**.
2. **New node `clu-frame-tally`** (type `clue`) — **REVISED per RF-1.**
   - `location`: `"z2 v-frame, gear-frame timber cheek"`
   - `content`: the chalked 24-tally block (grouped in fives) beside the crank station and a
     single matching tally beside the cam station; restates the slate's target proportion at
     the point of use; carries no structural information.
   - `supports`: `["p06-gear-train"]`
   - `viewed_when`: `"gear-frame close-up displayed (self-satisfying)"`
   - **Non-gating.** p06's `clue_gate.gated` stays `false`; no `required_viewed`; **no D7
     persisted boolean.**
   - **RF-1: ADD NO EDGE.** The rev-1.3 `edges` array contains **no `clue`-type edges at
     all**; all six existing non-gating clues are linked **only** by the node's `supports`
     field and the puzzle's `clues` list. `clu-frame-tally` is linked the same way. Adding a
     novel edge type would be the graph's sole instance of one and risks being read as a
     dependency by the ordering/completability guards in `Level2Tests`. *(The rev-A draft
     specified such an edge; that instruction is withdrawn.)*
3. **`p06-gear-train.clues`** — replace the "countable clack cadence" entry with one pointing
   at D13 as its realization, and append `clu-frame-tally`.
4. **`p06-gear-train.clue_gate.rationale`** — append the D13-is-ungated rationale.
5. **Amend `developer_notes` D5** — record that "countable" is now realized on screen (D13),
   and that the build-16 implementation ran a whole cam cycle on one press with no countable
   artifact, so the sanctioned no-algebra route was specified but not delivered.
6. **New `developer_notes` D13 — "Live crank-tally readout (rev 1.4)"** — full RF-2 / RF-3 /
   RF-7(c) semantics: accumulated-rotation measurement (index-crossing counting prohibited);
   partial-stroke rendering for the three non-integer pairs; transient view state, never
   saved, never gate-readable; the four clearing conditions; **worst case 48 strokes**;
   skippable accrual; no glow at 24.
7. **`visually_necessary_elements.z2-workroom`** — amend the gear-frame line per **RF-4**:
   post A carries a visibly depicted **8-tooth coaxial pinion** with VIII on its **own face
   annulus**; the drive path reads as **one line of drive with two identified gaps at posts A
   and B, each sized to receive a wheel** — *not* as a closed/continuous meshing chain. Add
   the crib line and the live-tally line (with the RF-7 constraints).
8. **`visually_necessary_elements.z1-attic`** — amend the slate line (fives + cam tally).
9. **`colorblind_safety`** — append the rev-1.4 chalk clause **plus the three RF-7 clauses**
   (luminance floor ≥ 3:1 in both wide and close-up; crib-vs-live separated by POSITION, never
   hue/value; no glow/flash/colour change at 24).
10. **`designer_difficulty_estimate`** — record the Validator's official **6.0 PROVISIONAL**
    (z1 4.5, z2 6.5, z3 7.0, z4 3.5), user-accepted, ledger-write held until the blind
    re-check.
11. **`escalation_rationale`** — amend clause (3): the z1-slate → z2-frame cross-zone binding
    is **softened** (F3 ships); the two-stage structure is still derived from the machine.
12. **`mechanics_used_for_ledger`** — **REVISED (RF-8-adjacent, new):** the mechanic is
    unchanged, but entry [0] currently repeats the false "countable clack cadence" claim in
    the same words the RWK register does. Repoint it at the D13 on-screen readout.
13. **`red_herrings.rh-48-gear`** — no change. The lone-48 trap survives F4 intact: mounting
    48 with anything yields an honest, non-24 tally count.
14. **`anti_softlock_invariants`** — invariant 4 extended to name D12/D13 alongside D10/D11 as
    repeat-identical presentation that never consumes, escalates or locks anything. F1–F4 and
    C1–C3 introduce **no new state, no new gate, and no new consumable**.

### 1e. What the Validator and the Blind Playtester should check (p06)

**Validator (re-check of the revision):**
- V1–V8 as previously resolved (all PASS at rev-1.4 delta validation).
- **V16 (new).** Confirm no `clue`-type edge was added anywhere (RF-1).
- **V17 (new).** Confirm D13's accrual is specified as accumulated rotation, that the three
  non-integer pairs are covered, and that no oscillation is possible (RF-2(a)).
- **V18 (new).** Confirm the persisted display clears on mount/unmount and cannot describe an
  unmounted configuration (RF-2(b)).
- **V19 (new).** Confirm the stroke bound reads 48, not 54 (RF-3).
- **V20 (new).** Confirm the F1 mesh wording cannot be read as licensing a closed train
  (RF-4).
- **V21 (new).** Confirm the three RF-7 clauses are present in `colorblind_safety` **and** in
  the z1/z2 `visually_necessary_elements` lines.
- **V22 (new).** Confirm the RWK register no longer claims a clack-cadence backup, and that
  `mechanics_used_for_ledger[0]` no longer does either (RF-8).

**Blind Playtester (re-check, mandatory):** see the consolidated checklist in **§9**.

---

## 2. BEAT p03 — the dormer floorboard cache

### 2a. Why the current clue chain fails

The user's own account is unusually diagnostic: *"i see the house on the beam clue, and the
clue on the pocket watch, then i used the screwdriver on the floorboard under the cat, by
randomly clicked."* **Both clues were found and both were understood as clues.** The failure
is not discovery and not binding — it is that the clue pair **does not resolve to a place**.

| Hop | What the player must do | Support | Status |
|---|---|---|---|
| **H1** | Find and inspect watch A (⌂ on the case back, single hand on III) | Coat-pocket close-up; inventory long-press inspect | **lands** (user: "the clue on the pocket watch") |
| **H2** | Find the ⌂ ring carved on the beam and bind it to the watch (same canonical die, by construction) | `cu-house-ring`, exactly 12 notches, identical dies | **lands** (user: "i see the house on the beam clue") |
| **H3** | Read the watch's hand as a *direction* on the ring's 12-notch circle | Build 16 composites the canonical hour hand onto `cu-house-ring` at the 3-notch once watch A is inspected | **probably lands now — untested** |
| **H4** | **Project that direction from a carving on a beam onto a location on the floor** | **Nothing.** | **fails** |
| **H5** | Recognise the floor as pryable and the screwdriver as the verb | Screwdriver is armed-item; the cache board is spec'd with *"NO independent visual tell in any state or view"* | **fails** |

**H4 is a geometry problem the scene cannot answer.** Per style-guide §6.3 the ⌂ ring is
carved *"into the beam beside the dormer at eye height"* and the floorboards *"run
front-to-back… at least five boards visible to the RIGHT of the ring's vertical."* A
3-o'clock bearing taken at the ring points **horizontally, at eye height, into empty air.**
It never intersects the floor. The design intends the bearing to be dropped onto the
floorboard columns and then counted out ("third board right") — but neither the projection
nor the count is expressed anywhere in the scene. Even a player who does everything right
arrives at *"somewhere to the right"* and then has to guess. That is precisely
"random-clicked."

**H5 compounds it.** The rev-1.3 art contract deliberately makes all boards identical,
because the anti-sweep wall required that no board betray itself. **That rationale is now
obsolete:** the as-built has exactly **one** cache hotspot (the pointer mechanic was
collapsed per the KEEP SIMPLE ruling, and M1 re-anchored that single hotspot onto the
`ov-cache-*` rect). There are no wrong boards to protect against any more. The build is
still paying the discoverability cost of an anti-sweep defence that no longer defends
anything.

**Why the build-16 fix cannot close this.** The ring-hand annotation lives in
`cu-house-ring` — a close-up of a beam carving. That plate contains **no floor**. It can
make H3 legible; it is structurally incapable of making H4 legible. The fix is correct and
should stay; it is simply not sufficient on its own.

### 2b. Redesigned clue presentation

Three changes (C1, C2 for p03; **C3 added per RC-1** for view parity at p04). C1 and C2 are
gated on the **existing** `clu-watch-a` persisted boolean (D7); C3 on the **existing**
`clu-watch-b` boolean. **No new flag, no new gate, no new hotspot.**

---

**C1 — Echo the ring-hand annotation into the wide view. (completes H3 where H4 happens)**

*Element:* the ⌂ beam carving in z1 v-door.
*View:* `z1-door-base` (**wide**) — the annotation currently exists only in `cu-house-ring`.
*Change:* once `clu-watch-a` is viewed, the wide plate composites the same canonical hour
hand (`z3/v-dial/sprites/hand-hour`) pivoted at the ring hub, pointing at the 3-o'clock
notch — the same table entry, a second rect. Scale the hand so it remains readable at wide
scale (the carve is small in the wide; a slightly over-scaled hand is acceptable and
preferable to an illegible one — Art Director's call on the exact factor).
*Why it matters:* the wide view is the **only** frame that contains both the ring and the
floorboards. The pointer and its target must be visible in one image or the projection hop
cannot be made.
*Assets:* existing `hand-hour` sprite, existing `Level2CloseUpVisuals.ringClues` pattern
extended to a wide rect. **Art cost: $0.**

---

**C2 — The clockmaker marked his own cache. (fixes H4 and H5)**

*Element:* the cache floorboard in z1 v-door.
*Views:* `z1-door-base` (wide) **and** `cu-floor-cache` (close-up) — both, so the two views
never contradict (the standing wide↔close-up parity directive).
*Change:* once `clu-watch-a` is viewed, the cache board carries a small **chalk ⌂ mark**,
struck in the clockmaker's chalk register — the **same canonical `die-house` glyph** as the
watch's case back and the beam carving. Before the watch is inspected, the boards remain
uniform and identical exactly as today.
*Two things this does at once:*
- It converts H4 from an unsupported spatial projection into the clue class the user
  demonstrably solves: **find the matching symbol.** The ⌂ appears three times — on the
  watch, on the beam, and on the board — closing the triangle.
- It gives H5 its affordance: a marked board is obviously the board to work on, and the
  screwdriver is the only tool that acts on floorboards.
*What it deliberately does NOT do:* it does not replace the reasoning for a player who is
already reasoning. The mark sits **at the ring's 3-o'clock bearing**, so a player who
derived the direction sees it confirmed, not pre-empted; and a player who has not inspected
watch A sees nothing at all, so the pre-clue anti-spoiler property is fully preserved.
*Honest classification (Validator §3.1, recorded here so it is not lost):* C1 re-presents
information the viewed clue already carries. **C2 presents the derived answer**, because the
derivation it replaces is one the scene provably cannot support. C2 is a **difficulty
change**, user-approved as A4, and it makes `clu-ring-dormer` **optional** for solving p03
(it was already non-gating, "anchor only"). Probe **P8** is the instrument that measures
whether the reasoning chain survives as an opt-in.
*Placement (hard constraint):* the mark must be composited **inside the measured
`ov-cache-*` wide rect, x 0.6375–0.7656** (from implementation-notes M1), i.e. on the actual
cache board and inside the existing `floor-cache` hotspot. This guarantees "what is marked
is what is tappable" and **requires no new hotspot and no M1 re-registration.** Mirror the
same mark into `cu-floor-cache` at the corresponding crop coordinates.
*Colour-blind constraint (RF-7(a), binding):* the chalk ⌂ must hold **≥ 3:1 luminance
contrast against the board in BOTH the wide and the close-up**. The **worn floorboard in
raking light** is the second of the batch's two risk surfaces, and the fallback NB blend
("sit chalk convincingly on worn timber") is precisely the operation that could erode it.
**Discrimination must rest on glyph shape + luminance, never on the warm/cool hue difference
between chalk and timber.**
*Assets:* `masters/glyphs/die-house.png` (canonical, already used on watch A's inner lid and
the beam carve) rendered in the chalk value `#E8E4DA`, composited deterministically.
*Art cost:* **$0** deterministic PIL / **≤ $0.15** if a crop-scoped NB edit is needed.
*New state assets:* `ov-cache-marked-wide` and `ov-cache-marked` (close-up). These must
compose correctly with the existing `ov-cache-pried-wheel` / `ov-cache-empty` overlays —
ordering is **marked → pried → empty**, with no new combinatorics on that axis.
**RC-6 (added):** the close-up carries an **independent** axis the rev-A draft did not
account for — `ov-cache-cat-gone`, authored in the build-16 batch for `cu-floor-cache`.
`ov-cache-marked` × `ov-cache-cat-gone` is a new composite pairing (the ROUND 8 Cluster-A
family). It introduces no state variable, but it must be added to the Developer's parity
audit and to the `Level2CloseUpStateTests` state-flip rows.

---

**C3 — Wide-view ring-hand echo for the z2 ⚙ ring. (RC-1; parity only — p04 gets NO mark)**

*Element:* the ⚙ ring carved on the chimney breast in z2 v-frame.
*View:* `z2-frame-base` (**wide**) — the annotation currently exists only in `cu-gear-ring`.
*Change:* once `clu-watch-b` is viewed, the wide plate composites the same canonical hour
hand pivoted at the ⚙ ring hub, pointing at the **9-o'clock** notch. Same `ringClues` table,
one more rect. The carve is measured on the shipped plate at **x [0.7359, 0.7487],
y [0.5589, 0.5844]** (implementation-notes, build-16 `gear-ring` hotspot batch), so the pivot
is already known to sub-pixel accuracy.
*Why it ships:* without it, post-rev-1.4 `cu-gear-ring` shows a hand while the wide shows a
bare ring — **the same element disagreeing across two views**, which is exactly the standing
wide↔close-up parity directive whose violation generated Cluster A/Q. C1 fixes this for p03;
C3 fixes it for p04.
***It is separable from A5 and pre-empts nothing.*** C3 gives p04 **no chalk mark**. Under
the A5 p03-only ruling the chimney brick's "no independent visual tell" contract stays
**absolute and unchanged**.
*Assets:* existing `hand-hour` sprite; existing `ringClues["cu-gear-ring"]` entry extended to
a wide rect. **Art cost: $0.**

---

***The p03 / p04 asymmetry — the principled basis (RC-2). This must be recorded in the
graph, not left as an exception:***

> p04's **9-o'clock bearing**, taken at the ⚙ ring carved at eye height on the chimney
> breast, points **directly at the brick field it selects** — pointer and target are the same
> surface, in the same frame, at the same height. p03's **3-o'clock bearing**, taken at the ⌂
> ring on the dormer beam at eye height, travels **horizontally into empty air and never
> intersects the floor** it is supposed to select (H4). **p04's pointer beat is supportable
> in-scene; p03's was not.** p03 therefore needs a substitute mark and p04 does not. This is a
> **reason, not an exception** — and it is also why the two rings both get their wide-view
> hand (a pure parity fix, C1/C3) while only p03 gets a chalk mark.
>
> Secondary supports, recorded for completeness: p03 is the teaching instance and p04 the
> test (teach-then-test is a legitimate escalation shape and keeps the pointer mechanic from
> being flattened level-wide); and p04 was explicitly **not** reported as failing.
>
> **Known risk, to be measured not assumed (RC-5 → probe P12):** a player who learns "the
> clockmaker marks his caches" at p03 and finds no chalk ⚙ at the chimney may infer *"this
> cache isn't available yet"* or *"it's somewhere else"* — a **false-negative inference**,
> structurally the inverse of the elimination-memory problem D10 was built to solve. It is a
> **stall risk, not a soft-lock**: the ring plus watch B still carry the full location,
> attempts are unlimited, and nothing is consumable.

---

*Considered and rejected:* a chalk sight-line / dashed stroke from the ring to the board.
It reads as a modern UI arrow rather than a diegetic mark, it duplicates what C1+C2 already
achieve, and it would require a new glyph primitive outside the canon.

### 2c. Intended step-by-step inference chain (for the Blind Playtester) — REVISED

1. Take the coat's pocket watch A. Inspect it: the case back is engraved with a small
   **house (⌂)**, and its single hand is stopped on **III**.
2. In the stair-door view, find the same **⌂** carved on the beam beside the dormer, ringed
   by a circle of twelve notches. → *"The watch and the beam are talking about each other,
   and the ring is a clock face."*
3. Because the watch has been read, the beam's ring now shows a hand pointing at the
   **3-notch** — in the close-up *and* in the wide view. → *"Three o'clock. That way,
   to the right."*
4. Look right along that bearing, at the floor: one floorboard carries a chalk **⌂** — the
   third mark of the same house symbol, the clockmaker's note to himself. → *"That board."*
5. Arm the screwdriver, pry the marked board. Underneath: a bronze gear with countable
   teeth, stamped **64** — the great wheel.
6. Tap it in the opened cache to collect it.

**The p04 chain, for contrast (unchanged in substance; C3 adds only the wide echo):**
inspect watch B (⚙, hand on IX) → find the ⚙ ring on the chimney breast → because the watch
has been read, the ring shows a hand at the **9-notch**, now **in the wide as well as the
close-up** → 9 o'clock is **directly left**, and the ring's own bearing lands on the brick
field in the same frame → pry the brick left of the ring. **There is no chalk mark here, and
none is needed** — the bearing resolves in-scene.

The p03 beat should now be solvable in **one to three minutes** by a player who has inspected
watch A, with zero random clicking. A player who has *not* inspected watch A still sees
uniform boards and gets the unchanged D10 grammar (dead "doesn't budge" on wrong spots,
faint creak-and-shift on the correct one).

### 2d. Graph / spec deltas for rev 1.4 (p03) — REVISED

1. **`p03-cache-dormer.solution_fixed`, `requires`, `clue_gate`, `yields`,
   `failure_behavior`** — **all unchanged / byte-stable.** A `notes` field is added pointing
   at D12; none of the five protected fields is touched.
2. **No new clue node and no new state.** The annotations render off the existing
   `clu-watch-a` (C1/C2) and `clu-watch-b` (C3) D7 booleans. Do **not** add a D7 flag, a
   gate, a node, or an edge for them.
3. **`clu-ring-dormer.content`** — amend to record the rendering contract (hand in BOTH views;
   chalk ⌂ on the board). `viewed_when` unchanged; it stays non-gating.
4. **`clu-ring-chimney.content`** — **NEW (RC-1):** amend to record the wide-view hand echo
   (gated on `clu-watch-b`) **and to state explicitly that the chimney brick carries NO chalk
   mark** (A5 = p03-only), so the parity fix can never be misread as licensing one.
5. **`p04-cache-chimney`** — **NEW (RC-2):** add a `notes` field recording the principled
   geometric basis for the asymmetry, the C3 parity echo, and the explicit "no mark" ruling.
   All p04 solution/gate/failure fields **unchanged**.
6. **Zone element string, `z1-attic` → `v-door`** — replace the uniform-floorboards string
   with the pre-clue/post-clue split. **This is the SANCTIONED REVERSAL site in the graph
   (RF-9);** file it as such, not as a clarification.
7. **Amend `developer_notes` D10** — scope *"no persistent visual change… in any state or
   view"* to the **pry response**, so it cannot be read as forbidding C2. *(Validator:
   CLARIFICATION CONFIRMED — D10's topic line, its opening scope and its "identical before and
   after" clause all establish the pry response as the referent.)*
8. **New `developer_notes` D12 — "Pointer-resolution annotations (rev 1.4)"**: renders off the
   existing `clu-watch-a` / `clu-watch-b` D7 booleans; three composites (z1 wide ring hand;
   chalk ⌂ inside the `ov-cache-*` rect x 0.6375–0.7656 mirrored into `cu-floor-cache`; z2
   wide ⚙-ring hand); wide and close-up must never disagree; layer order marked → pried →
   empty; **`ov-cache-marked` × `ov-cache-cat-gone` is an independent close-up axis and must be
   in the parity audit (RC-6)**; introduces no state, no hotspot, no gate; suppressed the
   moment the board is pried; **no chalk mark on the chimney brick**.
9. **`clue_gating.art_impact`** — append a rev-1.4 clause, **SCOPED per RF-6**: the clause
   names only the p03 annotations (and the two ring-hand echoes) as clue-state renders rather
   than gate tells, and appends *"p07 and p09 remain strictly no-annotation; any future
   clue-state render requires Validator re-verification."* It must **not** be written as a
   general permission class — written generally it would licence clue-state renders at p07 and
   p09, whose gates protect code entries where any post-view annotation is spoiler-equivalent.
10. **`visually_necessary_elements.z1-attic`** — amend the ⌂-beam/floorboard line (this is one
    of the four RF-5 sites). **`visually_necessary_elements.z2-workroom`** — amend the chimney
    line for the C3 wide echo, restating the brick's absolute no-tell contract in full.
11. **`colorblind_safety`** — append the p03 annotation clause plus the RF-7(a) luminance floor.
12. **Style-guide edits — FOUR contract sites plus the §6.4 cross-reference (RF-5).** See
    **§8**. This is an Art Director-owned file; route the edit, do not have Asset-Gen apply it.

### 2e. What the Validator and the Blind Playtester should check (p03)

**Validator (re-check of the revision):**
- V9–V15 as previously resolved (all PASS at rev-1.4 delta validation).
- **V23 (new).** Confirm the reversal is filed as a reversal at all four contract sites, and
  that neither §6.4 nor the graph's z2 chimney strings extend the p03 exception to p04
  (RF-5, RF-9).
- **V24 (new).** Confirm the `art_impact` clause is scoped to the named annotations and
  explicitly re-asserts p07/p09 strict no-annotation (RF-6).
- **V25 (new).** Confirm C3 introduces no mark, no hotspot, no state, and no A5 pre-emption,
  and that `clu-ring-chimney` remains non-gating.
- **V26 (new).** Confirm the RC-2 rationale is recorded in the graph, not only in this spec.

**Blind Playtester:** see **§9**.

---

## 3. Visually-necessary elements added or changed (Art Director hand-off)

| # | Zone / view | Element | New or changed | Owner |
|---|---|---|---|---|
| 1 | z2 v-frame (wide + `cu-gear-frame`) | Post-A coaxial **8-tooth pinion**, VIII stamped on its own face annulus. **RF-4:** the drive path reads as **one line of drive with two identified gaps (posts A, B), each sized to receive a wheel** — NOT as a closed/continuous meshing chain; with the posts empty the crank and post-A pinions must not be drawn meshing with anything. Cross-ref **R3** (slotted/adjustable arbors) | changed (verify first, A8) | Asset-Gen (`render_gear` n=8) + Art Director |
| 2 | z1 v-bench (wide + `cu-slate`) | Slate: 24 tallies **grouped in fives**; **one matching tally on the cam rim** beside its notch. **RC-3:** cam tally clearly separated from the 24-block (no 25-total read); diagonal reads as a **fifth stroke**, never a strike-out | changed — approved plate (A3) | Art Director sign-off → Asset-Gen |
| 3 | z2 v-frame (wide + `cu-gear-frame`) | Chalk crib on the frame cheek: 24-tally block at the crank station, single tally at the cam station. **RF-7(a)** ≥ 3:1 luminance vs the timber in both views; hue never load-bearing | new | Asset-Gen (deterministic) |
| 4 | z2 `cu-gear-frame` | Live tally block: 0…N full strokes + at most one half-height partial; **max 48**; **RF-7(b)** separated from the crib by a visible baseline/gap — POSITION only, never hue or chalk value, never one continuous 24+N block; **RF-7(c)** no glow/flash/colour change at 24; accrual skippable, final block statically readable (RC-4) | new | Developer (composite) + Asset-Gen (stroke primitive) |
| 5 | z1 v-door (wide) | Canonical hour hand on the ⌂ ring at the 3-notch, gated on `clu-watch-a` | new rect, existing sprite | Developer |
| 6 | z1 v-door (wide + `cu-floor-cache`) | Chalk **⌂** on the cache board inside x 0.6375–0.7656, gated on `clu-watch-a`; overlays `ov-cache-marked-wide` / `ov-cache-marked`; **RF-7(a)** ≥ 3:1 luminance on worn timber in raking light, in both views; **RC-6** must composite correctly with `ov-cache-cat-gone` | new | Asset-Gen (deterministic `die-house`) |
| 7 | **z2 v-frame (wide)** | **Canonical hour hand on the ⚙ ring at the 9-notch, gated on `clu-watch-b`** (pivot at the measured carve, x [0.7359, 0.7487], y [0.5589, 0.5844]). **NO chalk mark on the brick** — the brick's no-tell contract is unchanged and absolute | **new rect, existing sprite (RC-1)** | Developer |

Everything above uses existing canonical dies, existing deterministic renderers, or existing
sprites. **No generative scene work. No new glyph dies. No new hotspots.**

## 4. Art cost

| Item | Deterministic (preferred) | Fallback if an NB blend is required |
|---|---|---|
| F1 post-A pinion | $0.00 | $0.15 |
| F2 slate re-render | $0.00 | $0.00 |
| F3 frame chalk crib | $0.00 | $0.15 |
| F4 live tally strokes | $0.00 | $0.00 |
| C1 wide ring hand (z1 ⌂) | $0.00 | $0.00 |
| C2 cache chalk ⌂ (2 overlays) | $0.00 | $0.15 |
| **C3 wide ring hand (z2 ⚙, RC-1)** | **$0.00** | **$0.00** |
| **Total** | **$0.00** | **$0.45** |

L2 cap is $15.00 with **$2.25 headroom**, so even the all-fallback case ($0.45) clears with
$1.80 to spare. RC-1 adds **$0.00** to both columns. Recommendation unchanged: authorise the
$0.45 ceiling up front so Asset-Gen is not blocked mid-pass, and expect to spend $0.00–$0.15.

## 5. Producer approvals and flags — STATUS AFTER THE USER RULINGS

**A1 — p06 difficulty judgment call (F4, the live tally readout). → APPROVED 2026-08-06;
ships.** The readout gives an exact, legible error signal on every crank, converting p06's
fallback path into a visible hill-climb (~3–4 mounts instead of a 21-pair search). Recorded as
spec conformance *and* as a real change to felt difficulty; the user accepted it as part of
the true 6.0.

**A2 — p06 cross-zone binding (F3, the frame-side chalk crib). → APPROVED; F3 SHIPS.** The
target proportion no longer has to be carried from z1 to z2 in the player's head.
`escalation_rationale` clause (3) is amended to say so.

**A3 — F2 touches an approved, contract-passed asset. → APPROVED.** Art Director sign-off and
a re-run of the 24-count assertion are still required before Asset-Gen regenerates `cu-slate`.

**A4 — p03 difficulty judgment call (C2, the chalk ⌂ on the board). → APPROVED.** This
converts p03's final hop from spatial projection into symbol matching. **It is also the
approval that sanctions the §6.3 reversal (see A6).**

**A5 — p04 grammar symmetry. → RULED: p03-ONLY.** p04's chimney brick gets **no chalk mark**;
the blind re-check measures whether the asymmetry reads as a bug (probe **P12**). The
principled basis for the asymmetry is now recorded in the graph per RC-2 (see §2b). RC-1's
wide-view ring echo (**C3**) ships independently — it is a parity fix, gives p04 no mark, and
pre-empts nothing.

**A6 — graph-rule touches. REWRITTEN PER RF-9: TWO CLARIFICATIONS AND ONE SANCTIONED
REVERSAL** *(the rev-A draft filed all three as clarifications; the Validator identified the
third as a genuine reversal and that classification is adopted).*

| # | Text | Classification |
|---|---|---|
| 1 | **D10** scoped to *"no persistent visual change **caused by the pry attempt**"* | **CLARIFICATION — Validator-confirmed.** D10's topic line, opening scope and "identical before and after" clause all establish the pry response as the referent. No rev-1.3 ruling reversed. |
| 2 | **`no_tell_rule` / `clue_gating.art_impact`** — the named annotations classified as clue-state renders, not gate tells | **CLARIFICATION — Validator-confirmed, conditional on RF-6 scoping.** The rule's subject has always been attempt responses. **p07 and p09 remain strictly no-annotation.** |
| 3 | **The "NO independent visual tell in ANY state or view" art contract** (graph zone element, `visually_necessary_elements.z1-attic`, style-guide §6.3, style-guide hard-no #7) | ***SANCTIONED REVERSAL — NOT a clarification.*** Reverses the rev-1.0/1.1 anti-sweep art contract **for p03 only**, scoped to post-`clu-watch-a`. Rationale preserved (the gate still carries the information; a pre-clue player sees nothing) and the unstated anti-sweep rationale is moot in the as-built, which has exactly **one** cache hotspot per R8-009 KEEP SIMPLE + M1. **User-approved 2026-08-06 (A4). p04's contract is UNCHANGED and absolute.** Must be filed as a reversal in the rev-1.4 revision note and applied at **all four sites**, with §6.4 restated in full so the exception cannot propagate. |

**A7 — real-world-knowledge check. → CLEARED by the Validator as "clearly fair, not
borderline".** Tally marks grouped in fives (four uprights + diagonal strike) are a
near-universal counting convention, **and the player is never required to know it**: the crib
and the live block use the *identical* notation, so the comparison is shape-matching, and the
strokes remain individually countable for anyone who has never seen a five-bar gate. Two
independent zero-knowledge routes. This entry is now **added to the RWK register** per RF-8.

**A8 — verification dependency (do this before art work starts).** F1 is written as
"verify, then fix" because I am reading the asset manifest, not the shipped pixels. Someone
with the plate in front of them must confirm whether an 8-tooth coaxial pinion is actually
depicted at post A. If it is, F1 shrinks to a stamp relocation ($0). If it is not, F1 is the
single highest-value change in this document and should lead the batch.

**A9 (new) — difficulty of record.** The Validator's official **6.0 / 10 PROVISIONAL**
(z1 4.5, z2 6.5, z3 7.0, z4 3.5) is **user-accepted** — a true 6.0 in preference to a false
6.5, with escalation to be recovered at Level 3 by design rather than by fog. **It must not be
written into `progression-ledger.md` until the Blind Playtester re-check returns**; probes P5
and P7 are the measurements that settle it.

## 6. Sequencing note

F1 (verify + depict the second stage) should land **before** the blind re-check regardless of
what else is approved, because every other p06 change is measured against a frame the player
can actually read. C1 and C2 should land together — shipping C1 alone leaves H4 unsupported,
and shipping C2 alone reduces the beat to mark-hunting with the reasoning stripped out. C3 is
independent and can land in any order, but should land in the same build so P11/P12 measure
both rings under identical conditions.

---

## 7. EXACT rev-1.4 change list for `specs/levels/level-2/puzzle-graph.json`

*Drop-in, verbatim. No solution value, requirement, gate, dependency, ordering, red herring,
consumable, state variable or edge changes anywhere in this list.* Strings use the file's
existing ASCII conventions (`--` for em dash, `->` for arrows, `x` for multiplication).

**G1. `spec_revision`** — `"1.3"` → `"1.4"`.

**G2. `revision_notes[]`** — insert as the FIRST array element:

```
"Rev 1.4 (2026-08-07, CLUE-LEGIBILITY PASS -- Designer spec clue-legibility-p06-p03.md rev B; Validator delta-report validation-report-rev1.4.md PASS-WITH-CHANGES, 0 Critical, RF-1..RF-9 applied; user rulings 2026-08-06/07: A1-A4 + A7-A8 approved, F3 SHIPS, true 6.0 ACCEPTED, A5 = p03-only with the blind re-check measuring the asymmetry). SCOPE: DISCOVERABILITY ONLY, for the two beats the user reported failing -- p06 (the gear wall) and p03 (the dormer cache). NOTHING MOVES: every solution value, requirement, clue gate, dependency, ordering, red herring, consumable, state variable and EDGE is byte-stable from rev 1.3. p06 remains the unordered set {36-tooth rack gear, 64-tooth great wheel} on posts A/B in EITHER order at 24 crank : 1 cam; p03 remains the single cache at the house-ring's 3-o'clock (board index D3, one always-correct hotspot). p06 CHANGES (F1-F4): POST A now visibly carries its 8-tooth coaxial pinion with VIII stamped on the pinion's OWN face annulus (the second stage was not depicted -- VIII sat on a bracket panel, so '(A/12) x (B/8)' was unrecoverable from the machine); the slate's 24 tallies are GROUPED IN FIVES and the cam circle gains ONE matching tally stroke so the ratio compares like with like instead of comparing a count with a notch; a chalk CRIB on the frame's own timber cheek restates the 24:1 target at the point of use; and D13 delivers the live crank-tally readout that D5 and playtest 2b have declared sanctioned and load-bearing since rev 1.0 but the build never had (one press ran a whole cam cycle with no countable artifact). p03 CHANGES (C1-C2): the canonical hour hand now echoes onto the house ring in the WIDE view as well as the close-up (the wide is the ONLY frame containing both the ring and the floorboards), and the cache board carries a chalk house glyph of the same canonical die -- BOTH rendered off the EXISTING clu-watch-a persisted boolean, both fully invisible before watch A is inspected. RC-1 (C3): the matching wide-view hand echo is added to the z2 gear ring, gated on clu-watch-b, for wide<->close-up parity; the chimney brick gets NO chalk mark (A5 = p03-only) and its no-tell contract is UNCHANGED and absolute. *** SANCTIONED REVERSAL -- record as a reversal, NOT as a clarification (Validator RF-9): the rev-1.0/1.1 art contract 'the cache board has NO independent visual tell in ANY state or view -- identical boards, by design' is REVERSED FOR p03 ONLY, scoped to post-clu-watch-a. Its stated rationale is preserved exactly (the gate still carries the information; a pre-clue player sees nothing), and its unstated rationale -- the anti-sweep wall, which needed all boards identical so a brute-pryer got no differential -- is moot in the as-built, which has exactly ONE cache hotspot per the R8-009 KEEP SIMPLE ruling and M1. USER-APPROVED 2026-08-06 (A4). Applied at all four contract sites (this zone element string, visually_necessary_elements.z1-attic, style-guide 6.3, style-guide hard-no 7); style-guide 6.4 is restated in full so the exception cannot propagate to p04. *** Two text CLARIFICATIONS (Validator-confirmed; no rev-1.3 ruling reversed): D10 is scoped to the PRY RESPONSE (it never governed clue-state renders), and clue_gating.art_impact classifies the NAMED annotations as clue-state renders rather than gate tells -- p07 and p09 remain strictly no-annotation. DIFFICULTY: official 6.0 PROVISIONAL (z1 4.5, z2 6.5, z3 7.0, z4 3.5), user-accepted as a true 6.0 in preference to a false 6.5 -- DO NOT write to progression-ledger.md until the Blind Playtester re-check returns."
```

**G3a. `zones[z1-attic].views[v-door].elements`** — REPLACE the element string beginning
`"floorboards below and around the dormer, uniform, none visibly special (cache board has NO independent VISUAL tell`… with:

```
"floorboards below and around the dormer, uniform and identical WHILE clu-watch-a IS UNVIEWED (cache board has NO independent VISUAL tell pre-clue -- the gate carries the info; rev 1.3: pre-clue prys on the correct board give the D10 faint-tell, creak + shift only, no visual difference). REV 1.4 SANCTIONED REVERSAL (user-approved A4, 2026-08-06 -- reverses the rev-1.0 'no independent visual tell in ANY state or view' contract for p03 ONLY): once watch A has been inspected the cache board carries a chalk house glyph (canonical die-house) composited INSIDE the ov-cache-* rect x 0.6375-0.7656, in BOTH the wide and the close-up. Pre-clue appearance is byte-identical to rev 1.3; D10's faint-tell remains animation/SFX only. See D12. p04's chimney-brick contract is UNCHANGED and absolute."
```

**G3b. `zones[z1-attic].views[v-bench].elements`** — in the slate element string, replace
`"crank circle ringed by 24 tally marks"` with
`"crank circle ringed by 24 tally marks GROUPED IN FIVES"`, and replace
`"cam circle with a single notch and a door pictogram"` with
`"cam circle with a single notch, ONE MATCHING TALLY STROKE on its rim, and a door pictogram"`.

**G4. `nodes[clu-slate-ratio].content`** — REPLACE with:

```
"Wordless chalk schematic of the z2 gear frame: crank circle ringed with 24 tally marks GROUPED IN FIVES (four groups of five plus four singles); fixed pinion XII; unknown wheel '?'; fixed coaxial pinion VIII; unknown wheel '?'; cam circle with one notch AND ONE MATCHING TALLY MARK and a door pictogram. Encodes: (A/12) x (B/8) = 24, i.e. A x B = 2304 -> 36 and 64. REV 1.4: the fives-grouping makes the 24 readable rather than tally-countable (the hard '= 24' count assertion is unchanged), and the cam-rim tally makes the proportion a like-for-like comparison of marks instead of a count compared with a piece of mechanism."
```
`supports`, `viewed_when` and non-gating status **unchanged**.

**G5. `nodes[clu-ring-dormer].content`** — REPLACE with:

```
"Carved house glyph ringed by a 12-notch clock-position circle: the in-scene 'apply a clock direction HERE' anchor. 3-o'clock = toward the marked floorboard right of the dormer. REV 1.4: once clu-watch-a has been viewed, the ring renders the canonical hour hand at the 3-notch in BOTH the wide view (z1-door-base) and the close-up (cu-house-ring), and the cache board carries a chalk house glyph of the same canonical die in both views (D12). The ring stays NON-GATING and, with the board marked, is OPTIONAL for solving p03 -- it is the reasoning route, not the only route (playtest probe P8 measures whether the reasoning survives as an opt-in)."
```
`viewed_when` **unchanged** (`"dormer ring close-up displayed (not part of the gate; anchor only)"`).

**G6. `nodes[clu-ring-chimney].content`** — REPLACE with:

```
"Carved gear glyph ringed by a 12-notch clock-position circle. 9-o'clock = the brick directly left of the ring. REV 1.4 (RC-1, parity only): once clu-watch-b has been viewed, the ring renders the canonical hour hand at the 9-notch in BOTH the wide view (z2-frame-base) and the close-up (cu-gear-ring) -- the same ringClues table, one more rect, $0. THE CHIMNEY BRICK CARRIES NO CHALK MARK: A5 is ruled p03-only, and the brick's 'no independent visual tell' contract is UNCHANGED and absolute. Reason (RC-2): the 9-o'clock bearing points DIRECTLY at the brick field it selects -- pointer and target share one surface in one frame -- so p04's pointer beat is supportable in-scene and needs no substitute. See p04-cache-chimney.notes."
```
`viewed_when` **unchanged**.

**G7. NEW node** — insert into `nodes` immediately after `clu-slate-ratio`:

```json
{ "id": "clu-frame-tally", "type": "clue", "location": "z2 v-frame, gear-frame timber cheek", "content": "Chalked in the clockmaker's hand on the frame itself: a 24-tally block (grouped in fives) beside the crank station and a single matching tally beside the cam station. Restates the slate's target proportion at the point of use; carries NO structural information -- the two-stage layout is read off the machine (F1). REV 1.4 (F3), user-approved A2.", "supports": ["p06-gear-train"], "viewed_when": "gear-frame close-up displayed (self-satisfying -- the mounting and cranking controls live in this close-up)" }
```

**G8 (RF-1). `edges`** — **NO CHANGE. Add no edge for `clu-frame-tally`.** The array contains
no `clue`-type edges; all non-gating clues are linked only via `supports` + the puzzle's
`clues` list, and `clu-frame-tally` follows that convention. *(The rev-A draft's proposed
`{"from":"clu-frame-tally","to":"p06-gear-train","type":"clue"}` is WITHDRAWN.)*

**G9. `nodes[p03-cache-dormer]`** — ADD one field (all five protected fields untouched):

```
"notes": "REV 1.4: solution, requires, clue_gate, yields and failure_behavior are BYTE-STABLE. Two presentation-only annotations render off the EXISTING clu-watch-a D7 boolean (D12): the canonical hour hand on the house ring in the WIDE view as well as the close-up (C1), and a chalk house glyph on the cache board inside the ov-cache-* rect in both views (C2). Pre-clue appearance unchanged. C2 is a user-approved DIFFICULTY change (A4), not merely legibility: it replaces a projection hop (an eye-height 3-o'clock bearing onto a floor) that the scene provably cannot support, and it makes clu-ring-dormer optional for solving."
```

**G10. `nodes[p04-cache-chimney]`** — ADD one field (RC-2; all p04 fields untouched):

```
"notes": "REV 1.4: UNCHANGED in solution, requires, clue_gate, yields and failure_behavior, and the cache brick's 'NO independent visual tell' art contract is UNCHANGED AND ABSOLUTE -- the p03 reversal does NOT propagate here (A5 = p03-only, user ruling). PRINCIPLED BASIS FOR THE ASYMMETRY (RC-2, record so a later reader does not read it as an oversight): p04's 9-o'clock bearing, taken at the gear ring carved at eye height on the chimney breast, points DIRECTLY at the brick field it selects -- pointer and target are the same surface, in the same frame, at the same height. p03's 3-o'clock bearing, taken at the house ring on the dormer beam at eye height, travels HORIZONTALLY INTO EMPTY AIR and never intersects the floor it selects. p04's pointer beat is supportable in-scene; p03's was not. p03 therefore needs a substitute mark and p04 does not -- a reason, not an exception. Secondary: p03 teaches, p04 tests; p04 was explicitly not reported as failing. RC-1 (C3) adds the WIDE-view hand echo at the 9-notch for wide<->close-up parity only -- no mark, no hotspot, no state, and no A5 pre-emption. KNOWN RISK, measured not assumed (playtest probe P12): a player who learns 'the clockmaker marks his caches' at p03 may read the unmarked brick as 'not available yet' -- a false-negative inference. Stall risk only, never a soft-lock: the ring plus watch B carry the full location, attempts are unlimited, nothing is consumable. NOTE: p04's ring beat has never been blind-measured -- its gear-ring hotspot did not exist until the build-16 wiring batch."
```

**G11. `nodes[p06-gear-train].clues`** — REPLACE the fourth entry
(`"live mechanical feedback: … cranks-per-clack cadence is countable …"`) with:

```
"live mechanical feedback: with ANY meshing pair mounted the crank turns and the cam/mural visibly runs at the resulting speed; REV 1.4 -- 'countable' is now realized ON SCREEN by the D13 live crank-tally readout (one chalk stroke per crank revolution in the current cam cycle), because the build ran a whole cam cycle on one press with no countable artifact (playtest 2b: the counting path is a legitimate no-algebra solve route, and D13 is what delivers it)"
```
and APPEND:
```
"clu-frame-tally (F3: the chalked 24:1 target proportion restated on the frame's own cheek)"
```

**G12. `nodes[p06-gear-train].clue_gate.rationale`** — APPEND:

```
" REV 1.4: the D13 tally readout is mechanical truth (the realized ratio of the mounted pair, identical in form for correct and incorrect pairs, with no proximity signal), so it too is UNGATED; gating it would reintroduce the broken-machine read this ungated rationale exists to prevent. clu-frame-tally is likewise non-gating and appears in no clue_gate."
```

**G13. `clue_gating.art_impact`** — APPEND (SCOPED per RF-6):

```
" REV 1.4 (scoped clause -- NOT a general permission class): three named annotations are CLUE-STATE RENDERS, not gate tells -- (i) the canonical hour hand on the z1 house ring in the wide view, (ii) the chalk house glyph on the p03 cache board in the wide and the close-up, both functions of clu-watch-a, and (iii) the canonical hour hand on the z2 gear ring in the wide view, a function of clu-watch-b. They render on view entry, never in response to an attempt, so no_tell_rule is untouched: the wrong-spot dead wall and the D10 correct-spot faint-tell are byte-stable, and the pre-clue experience is byte-identical to rev 1.3. p07 AND p09 REMAIN STRICTLY NO-ANNOTATION -- their gates protect code entries where any post-view annotation is spoiler-equivalent. Any future clue-state render requires Validator re-verification."
```

**G14. `developer_notes[D5].note`** — APPEND:

```
" REV 1.4: 'countable' is now realized ON SCREEN, not only in audio -- see D13. The build-16 implementation ran a whole cam cycle on ONE press with no countable artifact, so the sanctioned no-algebra route (playtest 2b) was specified and never delivered; D13 delivers it. Note the rack-only straddle that makes the counting route close honestly: no rack-only pair reads 24, and the two nearest bracket it (40x48 = 20 below, 36x72 = 27 above), so a counting player hits a hard numerical bracket and must conclude that a wheel they do not have exists elsewhere."
```

**G15. `developer_notes[D10].note`** — REPLACE the sentence
`"It must NOT read as an invitation on its own: no loose wobble, no gap opening, NO persistent visual change to the board/brick in any state or view -- the spot looks identical before and after."`
with:

```
"It must NOT read as an invitation on its own: no loose wobble, no gap opening, and NO persistent visual change CAUSED BY THE PRY ATTEMPT -- a pre-clue pry leaves the spot looking identical before and after. (REV 1.4 CLARIFICATION, Validator-confirmed: this constrains the PRY RESPONSE only. The rev-1.4 clue-viewed annotations -- ring hands and the p03 chalk house glyph -- are functions of clu-watch-a / clu-watch-b, never of prying, and are correctly invisible to a player who has not read the watch. See D12.)"
```

**G16. NEW `developer_notes` entries** — append after D11:

```json
{ "id": "D12", "topic": "Pointer-resolution annotations (rev 1.4, C1/C2/C3 -- user-approved A4 + RC-1)", "note": "PRESENTATION ONLY, rendered off EXISTING D7 booleans; no new state, no new flag, no new node, no new edge, no new hotspot, no gate change. THREE composites. (1) C1: canonical hour hand (z3/v-dial/sprites/hand-hour) pivoted at the house-ring hub at the 3-notch, composited into the z1-door-base WIDE plate when clu-watch-a is true -- the existing Level2CloseUpVisuals.ringClues pattern extended to a wide rect; scale the hand up as needed for wide legibility (Art Director's factor). The wide is the ONLY frame containing both the ring and the floorboards, which is why the beat needs it. (2) C2: chalk house glyph (canonical masters/glyphs/die-house.png in chalk value #E8E4DA) composited INSIDE the measured ov-cache-* wide rect x 0.6375-0.7656 when clu-watch-a is true, and mirrored into cu-floor-cache at the corresponding crop coordinates -- what is marked is exactly what is tappable, so no new hotspot and no M1 re-registration. (3) C3: canonical hour hand at the 9-notch of the z2 gear ring, composited into the z2-frame-base WIDE plate when clu-watch-b is true (carve measured at x [0.7359, 0.7487], y [0.5589, 0.5844]) -- PARITY ONLY; the chimney brick gets NO chalk mark (A5 = p03-only). CONSTRAINTS: wide and close-up must NEVER disagree about the presence or absence of any of the three (the standing parity directive that generated Cluster A/Q); mark-visibility is exactly (gate-satisfied AND NOT pried), giving the totally ordered state set unmarked -> marked -> pried-with-wheel -> empty, so no chalk mark can ever survive on a lifted board or an empty cavity; the chalk mark must be suppressed the moment the board is pried. RC-6: ov-cache-marked composites against an INDEPENDENT close-up axis, ov-cache-cat-gone (authored in the build-16 batch for cu-floor-cache) -- that pairing must be in the Developer's parity audit and in the Level2CloseUpStateTests state-flip rows. COLOUR-BLIND (RF-7a): the chalk must hold >= 3:1 luminance contrast against worn timber in raking light in BOTH views; discrimination is glyph SHAPE plus luminance, never the warm/cool hue difference between chalk and timber." },
{ "id": "D13", "topic": "Live crank-tally readout (rev 1.4, F4 -- user-approved A1; delivers the counting route D5 and playtest 2b have promised since rev 1.0)", "note": "PRESENTATION ONLY. A chalk tally block on the gear-frame cheek, directly beneath the F3 crib and separated from it by a visible baseline. ACCRUAL: measured as ACCUMULATED CRANK ROTATION SINCE THE LAST CAM CLACK -- one full chalk stroke per full turn of accumulated rotation, remainder drawn as ONE partial stroke. Counting crossings of a fixed index mark on the crank is PROHIBITED: it drifts in phase and produces a 7/7/6 oscillation across cycles. Because every cam cycle of a given pair consumes exactly R = A*B/96 crank revolutions, the accumulated-rotation measure renders the IDENTICAL picture every cycle -- nothing oscillates. NON-INTEGER PAIRS (exactly three of the 21): 16x40 = 6 2/3 -> 6 full + one partial; 16x64 = 10 2/3 -> 10 full + one partial; 40x64 = 26 2/3 -> 26 full + one partial. All other 18 pairs are integers; the SOLUTION 36x64 = exactly 24 full strokes with NO partial. The partial stroke is the same chalk value, width and slot pitch at roughly HALF HEIGHT so it can never be miscounted as full; it never receives a five-group diagonal and is never counted into a group of five. Non-integrality is mechanical truth, NOT a proximity signal -- 6 2/3 (far) and 26 2/3 (near) render identically in form. PERSISTENCE: the block is TRANSIENT VIEW/SESSION STATE of the same class as an animation frame -- NEVER written to the save, NEVER readable by any gate, condition, requirement or D7 flag; on save/load it re-derives to EMPTY. What is drawn is a pure function of (currently mounted pair, accumulated rotation since the last clack). The completed-cycle count STAYS DRAWN -- so a player who looked away still gets the number -- until any of: (i) any mount or unmount at either post (clears immediately and completely; the frame must NEVER display a count belonging to a configuration that is no longer mounted), (ii) fewer than two gears mounted (no pair, nothing drawn), (iii) scene reload or save load, (iv) the start of the next crank press (redraws from zero). LEAK CONSTRAINTS: identical in form for correct and incorrect pairs; never varies with closeness to 24; never varies with any clue-viewed flag; UNGATED, exactly as p06 is ungated. NO GLOW, FLASH OR COLOUR CHANGE when the count reaches 24 (RF-7c) -- success differentiation stays with the latch taking and the panel opening. LEGIBILITY / TEDIUM: worst case across the whole gear set is 48 STROKES (64x72 = 4608/96 = 48; it is NOT 54 -- that would require two 72-tooth gears and only one exists). The block must stay legible at 48 via the five-grouping; the accrual animation must be skippable/fast-forwardable and the final block fully readable STATICALLY without having watched it accrue (RC-4). One crank press = one full cam cycle -- do NOT implement per-turn tapping. Renders in cu-gear-frame and in the wide if the crank is operable there; the crib and the live block are distinguished by POSITION ONLY (visible baseline/gap), NEVER by hue or chalk value, and must never read as one continuous block of 24+N strokes (RF-7b)." }
```

**G17. `anti_softlock_invariants[3]`** — REPLACE the trailing sentence
`"The D10 faint-tell and D11 ambient are repeat-identical presentation cues that never consume, escalate, or lock anything."`
with:

```
"The D10 faint-tell, the D11 ambient, the D12 pointer-resolution annotations and the D13 tally readout are repeat-identical presentation over existing flags (or, for D13, transient view state) that never consume, escalate, or lock anything; rev 1.4 adds NO new state, NO new gate and NO new consumable."
```

**G18. `solve_path_notes.state_model`** — APPEND:

```
" Rev 1.4 likewise adds NO new state: the D12 annotations are pure functions of the existing clu-watch-a / clu-watch-b booleans, and the D13 tally readout is transient view state that is never saved and never readable by any gate or condition."
```
**`solve_path_notes.revision_note`** — APPEND:
```
" Rev 1.4: no ordering changes -- every delta is presentation-layer; orderings A/B/C are valid as written."
```

**G19. `visually_necessary_elements`** —

(a) ADD a key beside `rev_1_3_cue_note`:
```
"rev_1_4_cue_note": "Rev 1.4 adds ONLY deterministic composites over existing plates and existing sprites: an 8-tooth pinion + VIII stamp at post A, a regrouped slate, two chalk tally blocks on the gear-frame cheek, one chalk house glyph on the p03 cache board, and three ring-hand rects (z1 wide, z2 wide, plus the two shipped close-ups). NO new plates, NO new glyph dies, NO new hotspots, NO generative scene work, NO re-rolls."
```

(b) `z1-attic` — REPLACE the slate line with:
```
"chalk slate with the two-stage ratio diagram (24 tallies GROUPED IN FIVES -- four groups of five plus four singles, XII, VIII, two '?', cam notch PLUS ONE MATCHING TALLY STROKE on the rim, door pictogram) -- legible in close-up; the cam tally must be clearly separated from the 24-block so no player reads a 25-total, and the five-grouping's diagonal must read as a FIFTH STROKE, never as a strike-out (RC-3)"
```

(c) `z1-attic` — REPLACE the `⌂ beam mark…` line with:
```
"⌂ beam mark with 12-notch ring (close-up legible); floorboards uniform; REV 1.4 clu-watch-a-gated annotations (D12): canonical hour hand on the ring at the 3-notch in the WIDE view (z1-door-base) as well as the close-up, and a chalk ⌂ (canonical die-house) on the cache board inside the ov-cache-* rect x 0.6375-0.7656 in BOTH views. Cache board states: unmarked (pre-clue) / marked / pried-open with great wheel / empty -- the mark is suppressed the moment the board is pried. REV 1.4 SANCTIONED REVERSAL of the rev-1.0 'no independent visual tell in ANY state or view' contract, FOR p03 ONLY, scoped to post-clu-watch-a (user-approved A4); the PRE-CLUE board is still byte-identical to its neighbours. RF-7(a): the chalk must hold >= 3:1 luminance contrast against worn timber in raking light in BOTH views -- shape plus luminance, never hue. REV 1.3 (D10) unchanged: pre-clue pry on the CORRECT board = slight-shift animation (a hair of movement under the blade, settles back) + creak SFX + haptic tick, NO persistent visual change CAUSED BY THE PRY; wrong boards keep the existing dead non-response"
```

(d) `z2-workroom` — REPLACE the gear-frame line with:
```
"gear frame: fold-out crank with XII-stamped pinion; POST A carrying a VISIBLY DEPICTED 8-TOOTH COAXIAL PINION with VIII stamped on its OWN FACE ANNULUS (not on a bracket panel); POST B + cam. RF-4: the drive path crank-XII -> [GAP: POST A] -> post-A VIII -> [GAP: POST B] -> cam must read as ONE LINE OF DRIVE WITH TWO IDENTIFIED GAPS, each gap visibly sized to receive a wheel -- with the posts empty the crank and post-A pinions mesh with NOTHING and must NOT be drawn as if they do (a closed train would make the empty posts read as decorative and destroy the affordance). Cross-ref standing R3 (slotted/adjustable arbors so wheels of different diameters plausibly mesh once mounted). Seized state (rust bloom, crank rocks) / oiled state; per-post mounted-gear overlays for every rack gear and the great wheel"
```

(e) `z2-workroom` — ADD two lines:
```
"chalk crib on the gear-frame timber cheek (F3): 24-tally block GROUPED IN FIVES at the crank station, single matching tally at the cam station -- inside the dual-safe zone, clear of the 72pt iPad pill band, and not overlapping gear-rack (left of ~x 0.65), ov-brick-* (x 0.6711-0.7849) or the gear-ring carve (x 0.7350-0.8050, y 0.4620-0.5960). RF-7(a): >= 3:1 luminance against the timber in BOTH the wide and the close-up; hue is never load-bearing",
"live tally block (D13) beneath the crib: 0..N full strokes plus at most ONE half-height partial stroke; MAXIMUM 48 strokes; separated from the crib by a visible baseline or gap -- POSITION ONLY, NEVER by hue or chalk value, and never reading as one continuous block of 24+N (RF-7b); NO glow, flash or colour change at 24 (RF-7c); accrual skippable and the final block fully readable statically (RC-4)"
```

(f) `z2-workroom` — REPLACE the chimney line with:
```
"chimney breast: ⚙ mark with 12-notch ring; bricks uniform; the cache brick has NO INDEPENDENT VISUAL TELL IN ANY STATE OR VIEW -- identical to its neighbours, by design (UNCHANGED at rev 1.4: the p03 reversal is p03-ONLY per user ruling A5, and it does NOT propagate here). Cache brick states: flush / pried-open with oil can / empty. REV 1.4 (RC-1, C3): once clu-watch-b is viewed the ⚙ ring renders the canonical hour hand at the 9-notch in the WIDE view (z2-frame-base) as well as in cu-gear-ring -- a wide<->close-up PARITY fix only, no mark, no hotspot, no state. REV 1.3 (D10) unchanged: pre-clue pry on the CORRECT brick = slight-shift animation + grinding-creak SFX + haptic tick, NO persistent visual change caused by the pry; wrong bricks keep the dead non-response"
```

**G20. `colorblind_safety`** — APPEND four entries:

```
"Rev 1.4 chalk marks (slate regrouping, frame crib, live tally block, cache-board ⌂) are luminance-contrast strokes and canonical glyph SHAPES, counted by quantity and grouped by shape; no color channel is load-bearing and no mark is distinguished from another by hue. The rev-1.4 p03/p04 pointer annotations are glyph shape and pointer ANGLE against a 12-notch ring.",
"RF-7(a) LUMINANCE FLOOR (mandatory): every rev-1.4 chalk element must hold >= 3:1 luminance contrast against its LOCAL substrate in BOTH the wide and the close-up. The slate is safe by construction; the two risk surfaces are the gear-frame TIMBER CHEEK and the WORN FLOORBOARD IN RAKING LIGHT, and the fallback NB 'blend chalk onto worn timber' edit is exactly the operation that could erode it. Discrimination must NEVER rest on the warm/cool hue difference between chalk and timber.",
"RF-7(b) BLOCK SEPARATION (mandatory): the F3 crib block and the D13 live block are distinguished by POSITION -- a visible baseline, chalked rule or clear gap -- and NEVER by hue, chalk value, or an 'old chalk vs fresh chalk' treatment. They must never read as one continuous block of 24+N strokes. Distinguishing them by value or hue would be a color-only distinction on a load-bearing comparison.",
"RF-7(c) NO SUCCESS COLOR CUE (mandatory): the live tally block must NOT glow, flash or change color when the count reaches 24. Success differentiation stays with the latch taking and the wall panel opening -- a color-carried success cue would be both a gate-adjacent tell and a color-only signal."
```

**G21. `designer_difficulty_estimate`** —
- `validator_official_score`: `6.5` → `6.0`
- `validator_score_status` → REPLACE with:
```
"REV 1.4: 6.0 / 10 PROVISIONAL (z1 4.5, z2 6.5, z3 7.0, z4 3.5), down from 6.5 (z1 5.0, z2 7.0, z3 7.0, z4 3.5). Deltas: p03 5.0 -> 3.5 (C1+C2 convert an in-scene-unsupportable projection hop into symbol matching), p06 7.5 -> ~6.25 (F1 is defect repair and moves it ~0; F2 -0.25; F3 -0.5, the separable lever, which the USER RULED SHIPS; F4 -0.75 to -1.0, turning a 21-pair search with weak faster/slower feedback into a ~4-mount bracket). USER RULING 2026-08-07: the true 6.0 is ACCEPTED in preference to a false 6.5 -- the 6.5 was scored against the DESIGN, while the as-built could not be completed without the walkthrough, p06's counting route was specified and never delivered, and p03's projection hop was geometrically impossible in-scene; escalation is to be recovered at Level 3 by design rather than by fog. STILL PROVISIONAL: do NOT write to progression-ledger.md until the Blind Playtester re-check returns -- probes P5 (p06 time-to-solve and route used) and P7 (p03 time-to-pry) are the measurements that settle it. No beat falls below challenging-but-fair into trivial."
```
- `escalation_rationale` — REPLACE clause (3) with:
```
"(3) heavier cross-zone clue binding (z1 master time + z2 plates -> z3 vault; watches found in one zone, applied in another) -- REV 1.4: the z1-slate -> z2-frame binding is SOFTENED, because F3 restates the 24:1 target proportion on the frame itself (user-approved A2, F3 ships); the two-stage STRUCTURE is still derived from the machine rather than carried, and the remaining cross-zone bindings are untouched;"
```

**G22. `mechanics_used_for_ledger[0]`** — REPLACE with *(RF-8-adjacent: this entry repeated
the register's false claim in the same words)*:

```
"gear-ratio train reasoning (two-stage reduction, unique pair, live mechanical feedback: visible cam speed plus the D13 on-screen crank-tally readout -- rev 1.4; the pre-1.4 'countable clack cadence' was never implemented) -- NEW, level signature"
```

**G23. `real_world_knowledge_register`** —
(a) REPLACE the gear-ratio entry with:
```json
{ "fact": "Bigger gear turns slower; ratio = tooth quotient; stages multiply", "confidence": "borderline -- RATIFIED at checkpoint (flag #2, arithmetic peak accepted). REV 1.4 CORRECTION (Validator RF-8): the pre-1.4 register claimed a 'countable clack cadence' in-room backup that the build NEVER HAD -- one crank press ran a whole cam cycle with no countable artifact, so the no-algebra route was specified and not delivered. D13 now delivers it on screen, and this entry's in_room_backup is true for the first time.", "in_room_backup": "slate worked diagram (24 tallies grouped in fives vs one matching cam tally -- a like-for-like proportion) + the F3 chalk crib restating that target at the frame + live cam-speed feedback + the D13 LIVE CRANK-TALLY READOUT (one chalk stroke per crank revolution in the current cam cycle, compared at a glance against the chalked 24) + a hard rack straddle (no rack-only pair reads 24; 40x48 = 20 and 36x72 = 27 bracket it, forcing the deduction that a missing wheel exists) + bounded experimentation" }
```
(b) ADD a new entry (A7):
```json
{ "fact": "Tally marks grouped in fives (four uprights plus a diagonal fifth stroke) read as a countable quantity", "confidence": "clearly fair, NOT borderline -- Validator-cleared 2026-08-07 (Designer flag A7). A near-universal counting convention, and the player is never required to KNOW it: the F3 crib and the D13 live block use the IDENTICAL notation, so the comparison is shape-matching, and the individual strokes remain countable for anyone who has never seen a five-bar gate. Sits BELOW the already-ratified 12-hour-wrap entry in demand.", "in_room_backup": "two independent zero-knowledge routes -- identical notation on both blocks makes the comparison pure shape-matching, and every stroke is individually countable; the player never performs arithmetic ON the tallies, only compares two blocks" }
```

**G24. `red_herrings.rh-48-gear`** — **NO CHANGE.** The lone-48 trap is intact: mounting 48
with anything yields an honest non-24 count. *(Validator: F4 reduces the trap's reach —
counting players never engage it — not its behaviour.)*

**G25. `zones[z2-workroom].views[v-frame].elements`, chimney string** — **NO CHANGE,
deliberately.** It states the brick's no-tell contract absolutely; under A5 that is correct
and must stay.

---

## 8. EXACT change list for `specs/levels/level-2/style-guide.md` (ART DIRECTOR-OWNED — ROUTE, DO NOT APPLY)

**Header for the routed request:** *"Rev 1.4 applies a **SANCTIONED REVERSAL** (user-approved
A4, 2026-08-06) of the rev-1.0 'no independent visual tell in ANY state or view' art contract,
**for p03 only**, scoped to post-`clu-watch-a`. It must land at **all four** contract sites,
and §6.4 must be restated in full so it cannot propagate to p04 (Validator RF-5, RF-9)."*

**S1 — §6.3, Floorboards bullet.** REPLACE:
> *"…all inside the dual-safe zone, ALL uniform. The cache board (third right) has **NO independent visual tell** in any state or view — identical boards, by design (the gate carries the info; D10's faint-tell is animation/SFX only, zero persistent pixels).*
> *Cache states (close-up + wide overlay): flush / pried-open with great wheel / empty.*"

WITH:
> *"…all inside the dual-safe zone, ALL uniform. **PRE-CLUE** (while `clu-watch-a` is unviewed) the cache board (third right) has **NO independent visual tell** — identical boards, by design (the gate carries the info; D10's faint-tell is animation/SFX only, zero persistent pixels). **REV 1.4 SANCTIONED REVERSAL of the rev-1.0 "in any state or view" contract, for p03 ONLY (user-approved A4):** once `clu-watch-a` has been viewed, the cache board carries a small **chalk ⌂** — the canonical `die-house` glyph in chalk value `#E8E4DA` — composited inside the measured `ov-cache-*` rect (x 0.6375–0.7656) in **both** the wide and the close-up, and the ⌂ ring carries the canonical hour hand at the 3-notch in **both** views (D12). The chalk must hold **≥ 3:1 luminance contrast against worn timber in raking light in both views**; discrimination is glyph shape + luminance, **never** the warm/cool hue difference between chalk and timber (RF-7a). The mark is suppressed the moment the board is pried.*
> *Cache states (close-up + wide overlay): **unmarked (pre-clue) / marked** / pried-open with great wheel / empty.*"

**S2 — §6.4, Chimney breast bullet.** REPLACE the cross-reference (it would otherwise silently
propagate the p03 exception to p04):
> *"The cache brick has NO independent visual tell (same rule as 6.3)."*

WITH (rule restated in full, absolute):
> *"The cache brick has **NO independent visual tell in ANY state or view** — identical to its neighbouring bricks, by design, **before and after** `clu-watch-b` is viewed. **This rule is stated here in full and is NOT a reference to §6.3: the rev-1.4 chalk-mark exception is p03-ONLY (user ruling A5) and does NOT apply to the chimney brick.** The gate carries the information; D10's faint-tell is animation/SFX only, zero persistent pixels. **Rev 1.4 (RC-1) adds one thing here and one thing only:** once `clu-watch-b` has been viewed, the **⚙ ring** carries the canonical hour hand at the **9-notch** in the **wide** view (`z2-frame-base`) as well as in `cu-gear-ring` — a wide↔close-up parity fix on the ring carve, **not** a mark on any brick.*
> *Cache states: flush / pried-open with oil can / empty.*"

**S3 — Hard-nos, item 7.** REPLACE:
> *"7. **No visual tell on the cache board or brick in ANY state or pre-open frame** — identical to neighbors (D10 is animation/SFX only). No loose edges, no gaps, no discoloration."*

WITH:
> *"7. **No visual tell on the cache board or brick that is caused by prying, and none at all on the chimney brick.** Specifically: (a) **p04's chimney brick — absolute, unchanged:** no independent visual tell in ANY state or view, identical to neighbours before and after `clu-watch-b`. (b) **p03's cache board — pre-clue only (rev 1.4 sanctioned reversal, user-approved A4):** identical to neighbours while `clu-watch-a` is unviewed; once it is viewed the board carries the chalk ⌂ per §6.3, in both views. (c) **Both, always:** no loose edges, no gaps, no discoloration, and no persistent visual change **caused by a pry attempt** — D10 remains animation/SFX only.*"

**S4 — §6.4, Gear frame bullet.** REPLACE:
> *"…empty square-arbor **POST A** (with its fixed coaxial pinion stamped **VIII**); empty square-arbor **POST B** driving the cam. The drive path crank→A→B→cam must be visually traceable as a line."*

WITH:
> *"…empty square-arbor **POST A**, carrying a **visibly depicted 8-tooth coaxial pinion with VIII stamped on that pinion's own face annulus** (not on a bracket panel — the second stage must be legible as mechanism, or `(A/12)×(B/8)` is unrecoverable from the machine); empty square-arbor **POST B** driving the cam. The drive path must read as **one line of drive with two identified gaps, at posts A and B, each gap visibly sized to receive a wheel** — with the posts empty the crank pinion and the post-A pinion **mesh with nothing and must not be drawn as if they do** (a closed train makes the empty posts read as decorative and destroys the mounting affordance). Cross-reference standing **R3** (slotted / adjustable arbors, so wheels of different diameters plausibly mesh once mounted)."*

**S5 — §6.4, new bullet (chalk on the frame).** ADD:
> *"- **Chalk crib + live tally, frame cheek (rev 1.4)** — the clockmaker's own chalk on the frame's left timber cheek beside the fold-out crank: a **24-tally block grouped in fives** at the crank station and a **single matching tally** at the cam station (F3), with the **live tally block** below it, separated by a visible baseline (D13). Inside the dual-safe zone, clear of the 72 pt iPad pill band, and not overlapping `gear-rack` (left of ≈ x 0.65), `ov-brick-*` (x 0.6711–0.7849) or the `gear-ring` carve (x 0.7350–0.8050, y 0.4620–0.5960). **≥ 3:1 luminance against the timber in both wide and close-up; hue is never load-bearing** (RF-7a). **The crib and the live block are separated by POSITION only — never by hue or chalk value ("old chalk / fresh chalk" is prohibited) — and must never read as one continuous block of 24+N strokes** (RF-7b). **No glow, flash or colour change when the live count reaches 24** (RF-7c). Max 48 strokes."*

**S6 — §6.1/§Slate (the `cu-slate` entry).** ADD to the slate's placement intent:
> *"Rev 1.4: the 24 tallies are **grouped in fives** (four uprights + a diagonal fifth stroke; four groups plus four singles — exact count still 24, contract-asserted), and the cam circle carries **one matching tally stroke** on its rim beside its notch. The cam tally must be **clearly separated from the 24-block** so no player reads a 25-total, and the diagonal must read as a **fifth stroke**, never as a strike-out or cancellation (RC-3)."*

---

## 9. Consolidated Blind Playtester checklist (P1–P14) — REVISED

*The playtester runs against `blind-layout.md`, never this document or the graph.*

**p06 (the gear wall)**
- **P1.** Standing at the gear frame with both posts empty, can you describe the drive path
  out loud — what turns what, in what order, and **where the missing pieces go**? (F1/RF-4
  test. Vague answer ⇒ F1 has not landed. Also report: did the empty posts read as *gaps in a
  drive line*, or as decoration?)
- **P2.** Without returning to z1, can you state the target proportion from what is visible at
  the frame? (F3 test.)
- **P3.** From the slate alone, what do the 24 marks and the cam's one mark mean? Answer
  before reading anything else. (F2 test. Also: did you ever read the total as 25?)
- **P4.** Mount a deliberately wrong pair and crank. Does the tally readout tell you *which
  direction* to move, without telling you the answer? (F4 test.)
- **P5.** Time-to-solve for p06 in isolation, and which of Routes A/B/C you actually used.
  **(One of the two measurements that settles the provisional 6.0.)**
- **P6.** Did anything about the crib or the readout feel like the game solving itself? (The
  legibility-vs-easing boundary — report honestly; this is the number the user will judge.)
- **P13 (NEW — RF-2 non-integer-pair behaviour).** Mount **16 and 40** (also try **40 and 64**)
  and crank **two or three full cycles without touching the gears**. (a) Does the count come
  out **the same every cycle**, or does it jump (e.g. 7, 7, 6)? *(It must be the same every
  cycle — any jump is the D13 oscillation bug.)* (b) What did the **short half-height stroke**
  read as — a partial turn, a smudge, a rendering glitch, or an error message? (c) Did it make
  you think that pair was **wrong**, or that the game was **broken**? *(The first is intended;
  the second is a defect.)*
- **P14 (NEW — RF-7 field check).** Look at the two chalk blocks on the frame cheek. (a) Are
  they obviously **two separate blocks**, or did they ever read as one long block of 24+N?
  (b) Could you tell them apart **without relying on colour or on one looking fresher**?
  (c) When the count hit 24 on the correct pair, did anything **glow, flash or change colour**?
  *(Must be "no" — success should have come from the latch and the panel.)* (d) Was the chalk
  readable against the timber in the **wide** view, not just the close-up?

**p03 / p04 (the caches)**
- **P7.** After inspecting watch A, how long from entering the stair-door view to prying the
  correct board? Target: under three minutes, zero random clicking. **(The second measurement
  that settles the provisional 6.0.)**
- **P8.** Did you understand *why* that board? Say it in your own words. (If the answer is "it
  had a mark on it" with no reference to the ring or the watch, C1 has not landed and only C2
  is carrying the beat — report that; it is a real, though acceptable, outcome. This is also
  the probe for whether `clu-ring-dormer`'s reasoning survives as an opt-in.)
- **P9.** Deliberately visit the stair-door view **before** inspecting watch A. Do the boards
  look uniform? Does anything hint at the cache? (Must be "no".)
- **P10.** Does the marked board look like part of the room, or like the game pointing at
  itself?
- **P11 (AMENDED).** Re-measure the ring-hand annotations — **all four rects, none of which has
  ever been blind-measured**: the z1 ⌂ ring in the **close-up** (build 16) and in the **wide**
  (C1), and the z2 ⚙ ring in the **close-up** (build 16 — its hotspot did not exist until that
  batch) and in the **wide** (C3). For each: did you notice the hand? Did you read it as a
  direction? Did the wide and the close-up ever appear to disagree?
- **P12 (NEW — RC-5, the A5 asymmetry probe; report this one at length).** After prying the
  **marked** board at p03, go to the chimney at p04. (a) **Did you expect a mark on a brick?**
  (b) **How long did you spend looking for one before you used the ring?** (c) When you found
  none, did you conclude *"this cache isn't available yet"* or *"the cache is somewhere else"*
  — i.e. did the absence read as a **negative signal** rather than as nothing? (d) Once you did
  use the ⚙ ring, did the 9-o'clock bearing land on the brick field **by itself**, without
  needing a mark? (e) Overall: did the p03-marked / p04-unmarked difference read as a
  **deliberate teach-then-test escalation**, or as a **bug**? *(This measures the user's A5
  ruling. The designed reason for the asymmetry is that p04's bearing resolves in-scene and
  p03's did not — the probe tests whether the player experiences that, or only the absence.)*

---

*End of spec. Owner: Theme & Puzzle Designer. Next agent: Blind Playtester (via Producer,
against `blind-layout.md`, which must be refreshed to describe the new visible elements —
post-A pinion + gaps, regrouped slate, frame chalk blocks, marked board, both wide ring hands
— with no dependency edges or solution values).*
