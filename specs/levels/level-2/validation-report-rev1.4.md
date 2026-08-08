# Level 2 — Rev 1.4 Delta Validation (clue-legibility, p06 + p03)

**Validator:** Puzzle Logic Validator — DELTA pass only
**Inputs:** `specs/levels/level-2/clue-legibility-p06-p03.md` (Designer, rev-1.4 delta list,
self-checks V1–V15) · `specs/levels/level-2/puzzle-graph.json` **rev 1.3** (authoritative) ·
`validation-report.md` (rev 1.0/1.2/1.3 passes) · `playtest-report.md` ·
`style-guide.md` · `implementation-notes.md` (M1, build-16 `ringClues`, R8-009 KEEP SIMPLE) ·
`build17-routed-changelist.md` §3 · `specs/feedback-backlog.md` ROUND 8 / R8-009 / R8-completion
**Branch:** `level2-clockmakers-attic` · **Date:** 2026-08-07
**User approvals carried in:** A1, A2, A4 (gated on `clu-watch-a`), A7, A8 approved
2026-08-06; A5 = p03-only marking, deferred to playtest; A6 routed to me specifically.

> **VERDICT: PASS-WITH-CHANGES.** 0 Critical. 15/15 Designer checks resolved, 8 required
> fixes (all Advisory severity, all spec/doc/art-constraint class — none touches a solution,
> a gate, a dependency or a state variable), 5 non-blocking recommendations.
> **Provisional official difficulty: 6.0 / 10** (z1 4.5, z2 6.5, z3 7.0, z4 3.5), down from
> 6.5 — surfaced to the user as the one genuine judgment call in this batch.
> Cleared for the Blind Playtester re-check once RF-1…RF-8 are applied.

---

## 0. Headline findings (read these four first)

1. **No delta changes a solution value.** p06 stays `{36, 64}` on posts A/B in either order
   at 24:1; p03 stays the single `ov-cache-*` hotspot. Independently re-derived — §1.
2. **The A6 "all three are clarifications" claim is 2/3 accurate.** D10's scoping and the
   `no_tell_rule`/`art_impact` classification are genuine clarifications. **The style-guide
   §6.3 / zone-element "NO independent visual tell in any state or view" edit is a genuine
   REVERSAL** of a rev-1.0 art contract — substantively sound, and covered by the user's A4
   approval, but it must be recorded as a reversal, not absorbed as a clarification. §3.
3. **Two style-guide sites the Designer's delta list misses** (hard-nos item 7; §6.4's
   "same rule as 6.3" cross-reference). Under the A5 p03-only ruling, §6.4 would silently
   propagate the p03 exception to p04. **RF-5 — must land with the §6.3 edit.**
4. **The level score drops to ~6.0**, i.e. parity with L1. No single beat becomes trivial,
   but the ledger escalation is erased. This is a difficulty decision, not a validation
   failure — §5 gives both readings and names the one separable 0.5 lever (F3).

---

## 1. Solvability + no-solution-change — **PASS** (V1, V6, V9 PASS)

### 1.1 p06 arithmetic, independently re-derived

Realized ratio is `R = (A/12) × (B/8) = A·B / 96` — **commutative**, which is the formal
reason both post arrangements are correct. F1 is depiction of a pinion the graph already
specifies as 8 teeth (`z2-workroom` v-frame element string and `p06.input` both state it),
so **F1 changes no term of that expression** (V6 **PASS**).

Full realizable space (7 gears, 21 unordered pairs — the same space validated at rev 1.0):

| R | pair | | R | pair | | R | pair |
|---|---|---|---|---|---|---|---|
| 4 | 16×24 | | 12 | 16×72, 24×48 | | 24 | **36×64 ← SOLUTION** |
| 6 | 16×36 | | 15 | 36×40 | | 26⅔ | 40×64 |
| 6⅔ | 16×40 | | 16 | 24×64 | | 27 | 36×72 |
| 8 | 16×48 | | 18 | 24×72, 36×48 | | 30 | 40×72 |
| 9 | 24×36 | | 20 | 40×48 | | 32 | 48×64 |
| 10 | 24×40 | | 10⅔ | 16×64 | | 36, 48 | 48×72, 64×72 |

- **36 × 64 = 24 is still the unique realizable pair.** 48×48 = 24 arithmetically; only one
  48 exists. **V1 PASS.**
- **Rack-only maximum-information check (bears on V5):** no rack-only pair equals 24. The
  two nearest rack values **straddle** it — 20 (40×48) below, 27 (36×72) above. A pure
  counting player therefore hits an exact bracket and *cannot* close it with rack parts,
  which forces the intended deduction "a wheel I don't have must exist." F4 does not weaken
  that deduction; it **sharpens** it from "faster/slower, hard to judge" into a hard
  numerical straddle. **V5 PASS** — `rh-48-gear` is unchanged in function (still a pure
  time-cost trap for algebra players); F4 reduces the trap's *reach* (counting players never
  engage it), not its behaviour.
- F2's regrouping is arithmetically exact: **4 groups of five + 4 singles = 24.** The hard
  `= 24` count assertion survives verbatim.

### 1.2 Every delta is presentation-layer — itemised

| Delta | Touches a solution / requirement / gate / state? | Verdict |
|---|---|---|
| F1 post-A 8-tooth pinion depicted, VIII moved to its face | No — mechanism already specced at 8 teeth | **PASS** |
| F2 slate tallies grouped in fives + one cam-rim tally | No — same 24, same 1 | **PASS** |
| F3 frame-cheek chalk crib (24-block + single tally) | No — restatement of an existing target | **PASS** |
| F4 live crank-tally readout | No — pure function of the mounted pair | **PASS** (see RF-2) |
| C1 wide-view ring hand at the 3-notch | No — second rect on an existing composite | **PASS** |
| C2 chalk ⌂ on the cache board, gated on `clu-watch-a` | No — location unchanged; render only | **PASS** |

`p03-cache-dormer.solution_fixed`, `requires`, `clue_gate`, `yields`, `failure_behavior`:
**byte-stable — V9 PASS.** `p06-gear-train.solution_fixed`, `requires`, `clue_gate.gated`
(false), `yields`, `failure_behavior`: **byte-stable.**

### 1.3 Reachability

No node is added to the dependency graph, none is removed, no edge changes weight or
direction. Every node reachable at rev 1.3 remains reachable by the identical closure;
orderings A / B / C re-traced and still valid. **Solvability PASS.**

---

## 2. Soft-locks and state model — **PASS** (V3, V10, V14 PASS with RF-2)

### 2.1 New-state audit

| Proposed element | Persisted? | New flag? | Verdict |
|---|---|---|---|
| F4 live tally | Derived from (mounted pair, revolutions in current cycle) | No | PASS w/ RF-2 |
| F3 chalk crib | Static plate content | No | PASS |
| C1 wide ring hand | Function of existing `clu-watch-a` D7 boolean | No | PASS |
| C2 chalk ⌂ | Function of existing `clu-watch-a` D7 boolean | No | PASS |

`developer_notes` D7's persisted-boolean list is unchanged (5 gating clues). `clu-frame-tally`
correctly gets **no** D7 boolean (it is non-gating). **V2 PASS**, **V10 PASS**.

### 2.2 Mistake-path probes (new surfaces only)

| Player action | Outcome | Soft-lock? |
|---|---|---|
| Mount a pair, crank, walk away mid-animation, return | Final count re-derivable from the mounted pair; no state to corrupt | No — **but see RF-2(b)** |
| Unmount a gear while a final count is chalked | Count must clear/re-derive; spec is currently silent | No — bug-read risk, **RF-2(b)** |
| Mount a non-integer pair (16&40, 16&64, 40&64) | Count oscillates across cycles (e.g. 7/7/6) — mechanically honest, spec-silent | No — bug-read risk, **RF-2(a)** |
| Cycle every pair to 48 tallies (64×72) | Block must stay legible; five-grouping handles it | No |
| See the chalk ⌂, pry without the screwdriver armed | Unchanged armed-item grammar | No |
| Pre-clue pry the correct board, then inspect watch A, return | D10 faint-tell memory hook is now **confirmed** by the mark on the same board | No — **improves** on rev 1.3 |
| Pry the marked board, re-enter the close-up | Overlay order marked → pried → empty; mark suppressed | No — **RF-9 note below** |
| Inspect watch A *after* prying | Structurally impossible (gate blocks pre-clue pry) — so `pried ∧ unmarked` is unreachable | No |

**Overlay-state closure (V14).** Because the pry is gated on `clu-watch-a` and the mark is a
function of the same boolean, mark-visibility is exactly `gate-satisfied ∧ ¬pried`. The state
set is totally ordered: unmarked → marked → pried-with-wheel → empty. **No state exists in
which a chalk mark survives on a lifted board or an empty cavity. V14 PASS.**

One implementation caveat the Designer's D12 understates: D12 claims "no new combinatorics",
but the **close-up** carries an independent axis — `ov-cache-cat-gone` (authored in the
build-16 batch for `cu-floor-cache`). `ov-cache-marked` × `ov-cache-cat-gone` is a new
composite pairing. Not a new state variable, but exactly the Cluster-A close-up compositing
family that dominated ROUND 8. Recorded as **RC-6** (implementation constraint).

### 2.3 Invariants

No timers introduced (F4's accrual is animation pacing, not a deadline). Unlimited attempts
preserved at every lock. No new consumable. No gate removal. All seven
`anti_softlock_invariants` re-confirmed true as written; delta 14's "no new state, no new
gate, no new consumable" claim is **accurate**. **Soft-lock gate: PASS.**

---

## 3. Gating integrity and the A6 text changes — the crux

### 3.1 Is the chalk ⌂ a legitimate clue-state render or an illegal gate-tell?

Tested against the rev-1.3 `no_tell_rule` on its own terms. The rule's subject is *gated
attempts*: "Gated attempts replay the puzzle's EXISTING failure grammar with no
distinguishing tell." C1/C2 are **not attempt responses** — they are functions of a
clue-viewed flag, rendered on view entry, independent of whether the player has ever pried.
Four independent confirmations:

- **Pre-clue experience is byte-identical to today** (uniform boards, no hand in either
  view). The anti-spoiler property the gate exists to protect is fully intact. **V11 PASS.**
- **Post-clue, the gate is satisfied** — there is nothing left for the no-tell rule to
  protect. The rule guards the *gated* state, which the annotation never occupies.
- **The annotation never varies with an attempt**, so the wrong-spot dead wall and the D10
  correct-spot faint-tell are byte-stable. **V12 PASS.**
- **Precedent already shipped:** build-16's `Level2CloseUpVisuals.ringClues` composites the
  canonical hour hand onto `cu-house-ring` on exactly this trigger, and the `cu-gear-ring`
  IX twin is wired. C1 is that same table, one more rect.

**Ruling: legitimate clue-state render. Not a gate tell. PASS.**

One honest distinction the Designer's framing blurs, which the user should hear plainly:

- **C1 (ring hand) re-presents information the viewed clue already carries** (watch A says
  III; the ring shows III). Unimpeachable legibility work.
- **C2 (chalk ⌂) presents the derived answer**, because the derivation (H4: project an
  eye-height 3-o'clock bearing onto a floor) is one the scene provably cannot support. C2 is
  therefore a *difficulty* change wearing legibility clothes. The Designer says so honestly
  in A4 and the user approved it. I am scoring it as a difficulty change in §5, not
  re-litigating it.

Consequence to record: with C2 shipped, **`clu-ring-dormer` becomes fully optional for
solving p03** (inspect watch A → see mark → pry). It was already non-gating ("anchor only"),
so nothing breaks — but the ⌂ *reasoning* chain is now opt-in. Playtest probe P8 is the right
instrument; I concur it must run.

### 3.2 Verdict on each A6 text change — clarification vs reversal

| # | Text | Designer's claim | **My verdict** |
|---|---|---|---|
| 1 | **D10 scoping** — "…no persistent visual change **caused by the pry attempt**" | clarification | **CLARIFICATION — CONFIRMED.** D10's topic line, its opening scope ("Applies ONLY to the two correct pry spots… while their clue-gate is unsatisfied"), and the trailing clause "the spot looks identical **before and after**" all establish the pry response as the referent. The phrase "in any state or view" was belt-and-braces drafting inside a pry-response paragraph, not an independent art contract. Narrowing it restores the plain reading. **No rev-1.3 ruling is reversed.** |
| 2 | **`no_tell_rule` / `clue_gating.art_impact`** — annotations classified as clue-state renders, not gate tells | clarification | **CLARIFICATION — CONFIRMED**, per §3.1. The rule's scope has always been attempt responses; classifying a non-attempt render as outside it changes nothing about p03/p04/p07/p09 attempt grammar. **Conditional on RF-6** (the clause must be scoped, not written as a general licence). |
| 3 | **Style-guide §6.3 + the zone-element string** — "NO independent visual tell in any state or view — identical boards, by design" | clarification | **REVERSAL — not a clarification.** This is *not* D10. It is the rev-1.0/1.1 anti-sweep art contract, restated verbatim at four sites (graph zone element, `visually_necessary_elements.z1-attic`, style-guide §6.3, style-guide hard-no #7) and cited as-is in my own rev-1.3 pass. Its scope was genuinely "any state or view", and rev 1.4 narrows it to "pre-clue only". Calling that a clarification understates it. |

**Is reversal #3 sound?** Yes, on its own merits, and I clear it:

- Its stated rationale — *"the gate carries the info"* — is preserved exactly: the mark is a
  function of the gate's own clue, so a pre-clue player still sees nothing.
- Its unstated rationale — the anti-sweep wall, which needed all boards identical so a
  brute-pryer got no differential — is moot post-gate, and moot in the as-built regardless:
  per the R8-009 KEEP SIMPLE ruling and M1 there is exactly **one** cache hotspot. There are
  no wrong boards left to protect against.
- It is inside the user's A4 approval ("cache-board chalk ⌂, gated on `clu-watch-a`").

**Ruling: sanctioned reversal.** Required action is bookkeeping, not redesign — the rev-1.4
note must say "REVERSES the rev-1.0 no-visual-tell art contract for p03, scoped to
post-`clu-watch-a`; user-approved 2026-08-06 (A4)" rather than listing it under
clarifications. And it must be applied at **all four** sites (see RF-5 — the Designer's delta
list reaches only two of them).

### 3.3 D5 amendment

D5's rev-1.4 append ("'countable' is now realized on screen… the build-16 implementation ran
a whole cam cycle on one press with no countable artifact") is a factual implementation note.
I verified the rev-1.3 D5 text does assert "the cranks-per-clack cadence must be consistent
and countable" and that `p06.clues` repeats it. The append corrects a spec-vs-build gap; it
reverses no ruling. **CLARIFICATION — CONFIRMED.**

### 3.4 Gate satisfiability, unchanged

| Gated puzzle | Required views | Still satisfiable before the puzzle is reachable? | Sole information carrier? |
|---|---|---|---|
| p03 | `clu-watch-a` | Yes (z1 pickup, inspectable anywhere, forever) | Yes — and C2 renders *off* it, never around it |
| p04 | `clu-watch-b` | Yes | Yes |
| p07 | `clu-master-time` + `clu-worldclock-row` | Yes | Yes |
| p09 | `clu-return-tag` | Yes | Yes |

Five `clue_gate` edges, four gated puzzles, unchanged. p06 remains ungated; `clu-frame-tally`
appears in no gate and introduces no `required_viewed`. **V2 PASS.** F4's ungated status is
correct and its rationale is right: a mechanically true train must report the truth
regardless of what has been read — gating the readout would reintroduce the broken-machine
read the ungated rationale exists to prevent.

**V4 (leak check) — PASS, with one required constraint.** The readout is `f(mounted pair)`
only: identical in form for correct and incorrect pairs, no proximity signal, no variation
with any clue-viewed flag. The success differentiation stays where it already lives — the
latch taking and the panel opening. **RF-7(c) forbids any glow/flash/colour change on the
tally block at 24**, which would convert an honest readout into both a tell and a
colour-carried cue.

---

## 4. Fairness / real-world knowledge — **PASS** (A7 cleared)

| Surface | Ruling | Basis |
|---|---|---|
| **A7 — tally marks grouped in fives** (four uprights + diagonal strike) | **PASS — clearly fair, not borderline** | Near-universal counting convention, and critically **the player is never required to know it**: the crib and the live block use the *identical* notation, so the comparison is shape-matching, and the strokes remain individually countable for anyone who has never seen a five-bar gate. Two independent zero-knowledge routes. This sits *below* the already-ratified 12-hour-wrap entry in demand. |
| Like-for-like tally comparison (24 marks : 1 mark) | **PASS** | Proportion by count. No arithmetic required to *read* it; near-wordless. Art constraint at RC-3. |
| ⌂ symbol-match chain (watch / beam / board) | **PASS** | Pure symbol matching against one canonical die — the exact clue class R8-completion records the user solving reliably ("single-lookup clues worked"). |
| Gear ratio (bigger = slower; stages multiply) | **PASS — borderline, materially improved** | Unchanged as a fact, but F4 finally delivers the sanctioned zero-arithmetic route that D5 and playtest 2b have promised since rev 1.0. Its `in_room_backup` becomes true for the first time. |
| New RWK introduced by rev 1.4 | **None beyond A7** | Confirmed by sweep of all six deltas. |

**Register defect found (RF-8):** `real_world_knowledge_register`'s gear-ratio entry currently
cites *"countable clack cadence"* as an in-room backup — a backup the build has never had
(the Designer's own Defect 3). The register is presently making a false claim about the
shipped game. It must be repointed at D13, and an A7 entry added. The Designer's p06 delta
list (items 1–14) does not touch the register at all.

---

## 5. Difficulty impact — **provisional 6.0 / 10** (V8, V15)

Measured against the **as-built**, per V15's correct instruction.

### 5.1 p06

| Change | Δ | Reasoning |
|---|---|---|
| F1 depict the 8-tooth pinion | **≈ 0** | This is defect repair, not easing. If the second stage is undepicted (A8 confirms it will now be drawn), `(A/12)×(B/8)` is *unrecoverable* and the beat is not "7.5-hard", it is broken-into-brute-force. F1 restores the intended difficulty rather than reducing it. |
| F2 fives + cam tally | **−0.25** | Removes an invented-notation hop (G3). Pure legibility. |
| F3 frame crib | **−0.50** | Genuinely removes the z1→z2 memory carry that `escalation_rationale` clause (3) explicitly counts as difficulty. **This is the separable 0.5.** |
| F4 live tally | **−0.75 to −1.00** | The largest delta in the batch. `R = A·B/96` is strictly monotone in both arguments, so an exact readout beside an exact target turns a 21-pair search into a ~3–4-mount binary search. The playtest already rated the old faster/slower signal "weak — the target ratio is not an extreme, so faster/slower doesn't hill-climb"; F4 replaces a weak signal with a decisive one. |

**p06: 7.5 → ≈ 6.25.** Not trivial — three things still carry it: recognising the two-stage
structure on the machine, the rack-straddle deduction (§1.1: 20 and 27 bracket 24, so a
missing wheel *must* exist), and the mount/crank iteration cost. It stays inside
"challenging-but-fair".

**Worst-case brute tail (V8): ~21 mounts with weak feedback → ~4 mounts with exact feedback.**

### 5.2 p03

As-built (post-KEEP-SIMPLE, post-build-16): inspect watch A → locate an unmarked single
hotspot with no floor-projection support → R8-009's random clicking. Effective ≈ 5.0 with a
pathological tail. Post-C1+C2: inspect watch A → see the marked board → pry. **≈ 3.5.**

Not trivial (three hops survive: find and inspect watch A, recognise the pry verb, act at the
right place), and it sits in the same band as p05 (2.0) and p04 (5.0), both accepted. But it
is now a **lookup beat, not an inference beat** — the honest description.

### 5.3 Ledger

| Zone | rev 1.3 official | **rev 1.4 provisional** | Basis |
|---|---|---|---|
| z1 Main Attic | 5.0 | **4.5** | p01 4.5, p02 4.0, p03 6.0 → 3.5 |
| z2 Movement Loft | 7.0 | **6.5** | p04 5.0, p05 2.0, p06 7.5 → 6.25 |
| z3 Behind the Great Dial | 7.0 | **7.0** | untouched (p09/p02 explicitly out of scope) |
| z4 Vault | 3.5 | **3.5** | untouched |
| **Overall** | 6.5 | **6.0 / 10 — PROVISIONAL** | |

**This is the one real judgment call in the batch, and it goes to the user.** Two defensible
readings:

- **Reading 1 (ledger-protective):** 6.0 is parity with L1's 6.0. The +0.5 escalation that
  justified L2's design is erased. If the ledger number matters, **F3 is the lever** — hold
  it back and the level lands ≈ 6.25 with the cross-zone binding intact.
- **Reading 2 (my own, offered as analysis not a decision):** the 6.5 was scored against the
  *design*. The as-built could not be completed without the guide (R8-completion), p06's
  counting route was specified and never delivered, and p03's projection hop was
  geometrically impossible in-scene. A number that high was measuring obscurity, not
  difficulty. Rev 1.4 converts an unfair ~8 into a fair ~6. **I would rather ship a true 6.0
  than a false 6.5**, and recover escalation at Level 3 by design rather than by fog.

**The 6.0 is PROVISIONAL and must not be written into `progression-ledger.md` until the Blind
Playtester re-check returns** — these are legibility changes whose magnitude is empirical, and
P5 (time-to-solve, route actually used) and P7 (time-to-pry) are the measurements that settle
it. **No beat falls below "challenging-but-fair" into trivial.**

---

## 6. Colour-blind safety — **PASS (conditional)** — mandatory gate (V7)

| New element | Non-colour cue | Holds? |
|---|---|---|
| F2 slate tallies grouped in fives | Stroke count + grouping shape; chalk `#E8E4DA` on slate `#2E3236` is a very large luminance step | **Yes** |
| F2 single cam-rim tally | Stroke shape, distinct from the notch (a cut in the rim outline) | **Yes** — RC-3 |
| F3 frame-cheek crib | Stroke count + grouping shape | **Yes** — conditional on RF-7(a) |
| F4 live tally block | Stroke count + grouping shape + **position** relative to the crib | **Yes** — conditional on RF-7(b) |
| C1 wide ring hand | Silhouette + pointer angle against the 12-notch ring | **Yes** |
| C2 chalk ⌂ | Canonical `die-house` glyph *shape* + luminance against timber | **Yes** — conditional on RF-7(a) |
| F1 8-tooth pinion + VIII stamp | Countable teeth + Roman glyph | **Yes** |

**No delta introduces a colour-only discrimination.** Hard gate **PASS**, conditional on
RF-7 being recorded in `colorblind_safety` and `visually_necessary_elements`. Two of the three
RF-7 clauses would become **Critical** if implemented the wrong way, which is precisely why
they must be written down now rather than left to Asset-Gen:

- If the F3 crib and the F4 live block were distinguished by **hue or chalk value** ("old
  chalk" vs "fresh chalk"), that is a colour-only distinction on a load-bearing comparison —
  **Critical**. The spec's own wording ("the same stroke style", "eye-adjacent") points at
  position, which is a valid cue; it must be stated as a requirement.
- If the tally block **glows or changes colour** on hitting 24, that is both a gate-adjacent
  tell and a colour-carried success cue — **Critical**.

The Designer's two `colorblind_safety` appends (p06 delta 9, p03 delta 9) are **accurate as
far as they go** but state neither the luminance floor nor the block-separation rule.

---

## 7. Consistency — the A5 p03-marked / p04-unmarked asymmetry

**My view, for the Blind Playtester's attention (I concur with the user's ruling to measure
rather than pre-empt).**

**In favour of the asymmetry:**
- p03 is the *teaching* instance and p04 the *test*. Teach-then-test is a legitimate and
  common escalation shape; it also means rev 1.4 does not flatten the whole pointer mechanic.
- **The asymmetry has a principled geometric basis**, which is the part the record is
  currently missing. p03's 3-o'clock bearing is taken at eye height on a beam and travels
  **horizontally into empty air — it never intersects the floor** (the Designer's H4). p04's
  9-o'clock bearing points **directly at the brick field it is about to select**. p04's
  pointer beat is *supportable in-scene*; p03's was not. So p03 needs a substitute and p04
  does not. That is a real reason, not an exception. **RC-2: record it in the graph**, or a
  later reader will read the asymmetry as an oversight.
- p04 was explicitly *not* reported as failing (R8-completion lists "p04 chimney (post-clue)"
  among the chains that landed).

**Against — the risk to hand the playtester:**
- The player who learns "the clockmaker marks his caches" at p03 and then finds no chalk ⚙ at
  the chimney may infer *"this cache isn't available yet"* or *"it's somewhere else."* That is
  a **false-negative inference** — structurally the inverse of the elimination-memory problem
  D10 was built to solve. It is a stall risk, **not a soft-lock** (the ring + watch B still
  carry the full location, unlimited attempts, nothing consumable). **RC-5** gives the probe.
- p04's ring beat has **never been blind-measured** — its `gear-ring` hotspot was missing
  until the build-16 wiring batch (implementation-notes). It must be measured in this same
  pass regardless of the A5 outcome.

**A second, smaller asymmetry the Designer does not flag (RC-1).** C1 echoes the ring hand
into the z1 **wide**; no equivalent is proposed for the z2 chimney ⚙ ring, whose carve *is*
visible in the `z2-frame-base` wide. Post-rev-1.4, `cu-gear-ring` would show a hand while the
wide shows a bare ring — the same element disagreeing across two views, which is exactly the
standing wide↔close-up parity directive that generated Cluster A/Q. This defect exists today
for p03 too; C1 fixes it for p03 and leaves it for p04. It is the same `ringClues` table
extended by one rect, $0, and **it is fully separable from the A5 chalk-mark question** — it
gives p04 no mark and pre-empts no decision.

**V13 (wide↔close-up parity for C2): PASS** — the Designer correctly requires the mark in
both `z1-door-base` and `cu-floor-cache` in every state.

---

## 8. Designer self-check register (V1–V15)

| # | Check | Result |
|---|---|---|
| V1 | Solution set unchanged; both post arrangements resolve | **PASS** (§1.1) |
| V2 | `clu-frame-tally` in no `clue_gate`; p06 ungated; no D7 boolean | **PASS** (§3.4) — but see **RF-1** on the proposed edge |
| V3 | D13 introduces no state; unreadable by any gate/condition | **PASS with RF-2** |
| V4 | D13 leaks nothing beyond mechanical truth | **PASS with RF-7(c)** |
| V5 | `rh-48-gear` intact; "a 64 must exist" deduction survives | **PASS — strengthened** (§1.1) |
| V6 | F1 is depiction, not mechanism | **PASS** |
| V7 | Colour-blind check on the three new chalk elements | **PASS (conditional on RF-7)** |
| V8 | Difficulty delta: brute tail + intended path; official score | **DONE** — tail 21→~4 mounts; provisional **6.0** (§5) |
| V9 | p03 byte-stable in solution/requires/gate/yields/failure | **PASS** |
| V10 | No new state, flag, node, edge or hotspot for C1/C2 | **PASS** |
| V11 | Pre-clue experience unchanged in both views; D10 + wrong-spot wall intact | **PASS** |
| V12 | `no_tell_rule` not violated — never a response to an attempt | **PASS** (§3.1) |
| V13 | Wide↔close-up parity in every state | **PASS** |
| V14 | marked → pried → empty leaves no orphan mark | **PASS** (§2.2) |
| V15 | p03 difficulty delta measured against the as-built | **DONE** — 5.0 → 3.5 (§5.2) |

---

## 9. Required fixes (all **Advisory** severity — apply before the Blind Playtester re-check)

None is Critical; none touches a solution, gate, dependency or state variable. All are
spec-text, documentation-consistency or recorded-art-constraint class.

**RF-1 — drop the proposed `clu-frame-tally` edge (schema conformance).**
Delta 2 says to add `{ "from": "clu-frame-tally", "to": "p06-gear-train", "type": "clue" }`
"consistent with how the other non-gating clue nodes are edged." **It is not consistent.**
Rev 1.3's `edges` array contains **no `clue`-type edges at all** — the only clue edges are the
five `clue_gate` edges. All six existing non-gating clues (`clu-slate-ratio`,
`clu-ring-dormer`, `clu-ring-chimney`, `clu-linkage-rods`, `clu-mirrored-numerals`,
`clu-cat-refusal`) are linked *only* by the node's `supports` field and the puzzle's `clues`
list. Adding one would be the graph's sole instance of a novel edge type and risks being read
as a dependency by the ordering/completability guards in `Level2Tests`. **Fix:** add no edge;
use `supports` + `p06.clues`, exactly like the other six.

**RF-2 — D13 must close two behavioural gaps.**
(a) **Non-integer ratios.** Three of the 21 pairs are non-integer: 16×40 = 6⅔, 16×64 = 10⅔,
40×64 = 26⅔. D13 is silent on partial revolutions, so the count would oscillate across
successive cycles (7/7/6…) — mechanically honest, but an unspecified oscillation is precisely
the bug-read class that D11 exists to prevent. Specify the rendering (e.g. a visibly short
partial stroke, with the residue carrying into the next cycle).
(b) **"Derived — never stored" vs "the final count persists until the next crank press" are
in contradiction as written.** Resolve by stating the persisted display is a pure function of
the *currently mounted pair*, and **clears on any mount/unmount and when no pair is
mounted** — otherwise the frame can display a count for a configuration that is no longer
present (a lie about mechanical truth, and a weak information carry-over).

**RF-3 — D13's "worst case 54 strokes" is factually wrong.** The maximum realizable count is
**48** (64 × 72 / 96). 54 would require two 72-tooth gears; only one exists. The legibility
constraint is unaffected (48 < 54) but the graph should record the true bound.

**RF-4 — reword delta 7's mesh requirement.** *"the drive path … legible as one continuous
meshing chain with both posts empty"* is physically self-contradictory: with both posts empty
the crank pinion and the post-A pinion mesh with nothing. As written it risks Asset-Gen
depicting a *closed* train, which would make the empty posts read as decorative and destroy
the affordance F1 exists to create. Reword to: *"legible as a drive path with two identified
gaps at posts A and B, each gap sized to receive a wheel."* Cross-reference standing
**R3** (slotted/adjustable arbors so gears of different diameters plausibly mesh).

**RF-5 — the style-guide edit must cover all four sites, not two.** The Designer's delta 4
(zone-element string) and delta 10 (§6.3) reach two. The remaining two:
- **`style-guide.md` hard-nos, item 7:** *"No visual tell on the cache board or brick in ANY
  state or pre-open frame — identical to neighbors (D10 is animation/SFX only). No loose
  edges, no gaps, no discoloration."* Must be scoped to pre-clue (p03) and left absolute for
  p04.
- **`style-guide.md` §6.4 (chimney):** *"The cache brick has NO independent visual tell (same
  rule as 6.3)."* Under the A5 p03-only ruling this cross-reference would **silently
  propagate the p03 exception to p04**. Restate §6.4's rule explicitly and in full rather
  than by reference.
Also amend `visually_necessary_elements.z1-attic`'s corresponding line (delta 8 covers this —
confirm it lands). Route to the **Art Director**, per delta 10; Asset-Gen must not apply it.

**RF-6 — scope the `clue_gating.art_impact` rev-1.4 clause.** As drafted ("the annotations
are clue-state renders, not gate tells") it reads as a general permission class. Written
generally it would licence clue-state renders at **p07 and p09**, whose gates protect code
entries where any post-view annotation is spoiler-equivalent and whose strict no-tell status
has been explicitly preserved through revs 1.2 and 1.3. **Fix:** scope the clause to the two
named p03 annotations and append: *"p07 and p09 remain strictly no-annotation; any future
clue-state render requires Validator re-verification."*

**RF-7 — record three colour-blind / legibility constraints (mandatory-gate condition).**
(a) Chalk must hold **≥ 3:1 luminance contrast against its local substrate in both the wide
and the close-up**. The slate is safe by construction; the **frame timber cheek** and the
**worn floorboard in raking light** are the two risk surfaces, and the fallback NB blend
("sit chalk convincingly on worn timber") is exactly the operation that could erode it.
Discrimination must never rest on the warm/cool hue difference between chalk and timber.
(b) The **F3 crib block and the F4 live block must be separated by position** (a visible
baseline, rule or gap), never distinguished by hue or chalk value, and must never read as one
continuous block of 24 + N strokes.
(c) **No glow, flash or colour change on the tally block when the live count reaches 24.**
Success differentiation stays with the latch and the panel (V4).
Add all three to `colorblind_safety` and to the `visually_necessary_elements` z1/z2 lines.

**RF-8 — repair the RWK register.** The gear-ratio entry's `in_room_backup` cites *"countable
clack cadence"*, a backup the build has never had. Repoint it at D13. Add an entry for
tally-marks-in-fives (A7): *"confidence: clearly fair — convention, never required as
arithmetic; in_room_backup: identical notation on both blocks makes the comparison
shape-matching, and individual strokes remain countable."* The p06 delta list touches the
register nowhere.

**RF-9 (bookkeeping, but the one the record most needs) — classify the §6.3 change honestly
in the rev-1.4 revision note.** Per §3.2, list it as: *"REVERSES the rev-1.0 'no independent
visual tell in any state or view' art contract **for p03 only**, scoped to post-`clu-watch-a`;
rationale preserved (the gate still carries the info; the as-built has one hotspot, so the
anti-sweep wall no longer defends anything); **user-approved 2026-08-06 (A4)**. p04's contract
is unchanged."* Do not file it under A6's "clarifications".

---

## 10. Recommendations (non-blocking)

- **RC-1 — annotation parity for p04's ring, $0.** Extend the wide ring-hand echo to the z2
  chimney ⚙ ring (`z2-frame-base`), same `ringClues` table, one more rect. Otherwise
  `cu-gear-ring` shows a hand while the wide shows a bare ring — the same element disagreeing
  across views, the standing parity directive's exact failure class. **Separable from A5; it
  gives p04 no chalk mark and pre-empts no decision.**
- **RC-2 — record the A5 rationale in the graph** (§7): p04's 9-o'clock bearing lands directly
  on its brick field; p03's 3-o'clock ran horizontally into empty air at eye height. The
  asymmetry is principled, and should not read as an oversight to a later reader.
- **RC-3 — slate art constraints.** The single cam tally must be unmistakably a chalk stroke
  in the slate's chalk register, spatially separated from the 24-block so no player reads a
  25-total; and the five-grouping's diagonal must read as a *fifth stroke*, not as a
  strike-out or cancellation.
- **RC-4 — F4 tedium guard.** Cap or allow-skip on the accrual animation (worst case 48
  strokes, on *every* experimental mount); the persisted final block must be fully readable
  statically without watching the accrual. The Designer's "do not implement one-tap-per-turn"
  is right and should stand.
- **RC-5 — playtest probe for the A5 false-negative:** *"After prying the marked board at p03,
  go to the chimney. Did you expect a mark there? How long did you spend looking for one
  before using the ring?"* Pair with **P11** (the never-measured build-16 ring annotations,
  now both p03 and p04).
- **RC-6 — close-up compositing constraint.** `ov-cache-marked` must compose correctly with
  `ov-cache-cat-gone` in `cu-floor-cache` (an independent axis D12 does not account for) —
  the ROUND 8 Cluster-A family. Add to the Developer's parity audit.
- Standing items carried forward unchanged: **A2** (Big Ben pictogram stage), **A3** (z1 score
  citation — now superseded by §5.3), **R2–R5**.

---

## 11. Verdict

| Gate | Result |
|---|---|
| Solvability / no-solution-change (V1, V6, V9) | **PASS** |
| Soft-locks and state model (V3, V10, V14) | **PASS** (RF-2) |
| Gating integrity — clue-state render vs gate tell (V2, V4, V11, V12) | **PASS** (RF-6) |
| A6 text changes — clarification vs reversal | **2 clarifications CONFIRMED; 1 REVERSAL identified** (sanctioned by A4; RF-9) |
| Path consistency (orderings A/B/C, both post arrangements, all solve routes) | **PASS** |
| Fairness / RWK (A7 and the two new chains) | **PASS** (RF-8) |
| Colour-blind safety (mandatory) | **PASS — conditional on RF-7** |
| Wide↔close-up parity (V13) | **PASS for p03** (RC-1 for p04) |
| **Critical findings** | **0** |
| **Required fixes** | **9, all Advisory severity** |
| **Official difficulty** | **6.0 / 10 PROVISIONAL** (z1 4.5, z2 6.5, z3 7.0, z4 3.5) — do not write to the ledger until the blind re-check |

**Overall: PASS-WITH-CHANGES.** Every rev-1.4 delta is presentation-layer; no solution value,
requirement, gate, dependency, state variable, consumable or ordering moves. The chalk ⌂ is a
legitimate clue-state render, not a gate tell. Apply RF-1…RF-9 (Designer via Producer; RF-5
and RF-7 route to the Art Director) and the batch is cleared for the Blind Playtester
re-check.

**Two items go to the user as decisions, not findings:** the provisional drop from 6.5 to 6.0
(§5.3, with F3 named as the separable 0.5 lever), and the A5 asymmetry (§7, where I concur
with option (iii) — measure it).

---

## V17 — partial-stroke verdict (micro delta-check, 2026-08-07)

**Scope.** Single-item re-check of the Designer's RF-2(a) application: the half-height partial
tally stroke in `clue-legibility-p06-p03.md` rev B §1b F4 / §1c Route B, and its verbatim
graph string §7 **G16 → `developer_notes` D13**. `puzzle-graph.json` on disk is still **rev
1.3** (it contains no D13), so this verdict binds the G16 D13 string **before the Producer
commits it**. Read-only everywhere else; nothing below reopens an approved decision.

**VERDICT: APPROVE WITH WORDING TWEAK (W1–W4). 0 Critical. 1 Advisory (playtest probe).
Does not block the Blind Playtester re-check.**

### V17.1 Ground truth — all 21 pairs re-derived independently

Gear set {16, 24, 36, 40, 48, 72} on the rack + {64} from the cache = 7 wheels,
C(7,2) = 21 unordered pairs, `R = A·B / 96`:

| R | Pairs |
|---|---|
| 4, 6, 8, 9, 10, 12, 12, 15, 16, 18, 18, 20, 27, 30, 32, 36, 48 | the 17 wrong **integer** pairs |
| **24** | **36 × 64 — the solution. Exactly integer. NO partial.** |
| 6⅔ / 10⅔ / 26⅔ | 16×40, 16×64, 40×64 — the three **non-integer** pairs |

The Designer's D13 table is arithmetically correct on all four rows, and the 18-integer /
3-non-integer split is correct. **No fourth non-integer pair exists.**

### V17.2 (a) Does the partial stroke leak solution information? — **NO. PASS.**

Three independent proofs, any one of which is sufficient:

1. **Redundancy — the decisive one.** For all three non-integer pairs the *full-stroke count
   alone* already eliminates the pair: 6 ≠ 24, 10 ≠ 24, 26 ≠ 24. The sanctioned counting
   route delivers a complete 21 → 1 discrimination on its own. The partial stroke's
   proposition ("this pair is non-integer") narrows 21 → 18 — a **strict subset** of an
   elimination the player has already been handed, with strictly greater force, in the same
   glance. **Marginal information content of the partial stroke: zero.** It cannot function
   as an illegitimate elimination tell, because it eliminates nothing the primary readout has
   not already eliminated. The Producer's framing ("only 3 of 21 are non-integer and none is
   the solution") is true but does not create a leak: the readout is not a *classifier*
   handing out 1 bit, it is a *quantity* handing out the exact answer.
2. **Glyph invariance.** All three residues are **identical**. 640, 1024 and 2560 are each
   ≡ 64 (mod 96), so every non-integer pair leaves a residue of exactly **⅔** of a turn.
   There is therefore exactly **one** partial glyph in the entire level, invariant across all
   three pairs. A single constant symbol carrying one already-redundant bit is the
   least-informative possible faithful rendering.
3. **Proximity neutrality — V4 re-verified.** 6⅔ (17.33 from the target) and 26⅔ (2.67 from
   the target) render byte-identically in form. The readout still never varies with closeness
   to 24, never varies with any clue-viewed flag, and remains ungated. **V4 stays PASS.** The
   Designer's core claim is correct as stated.

**Counter-argument considered and rejected.** *"A player can skip counting to 26 by spotting
the partial."* True, and harmless: it is a **legibility affordance available identically to a
far wrong pair and a near wrong pair**. It does not order the search, does not reduce the
number of mounts required, and hill-climbs nothing. Under V4 the prohibited property is
*variation with closeness to the target*; a constant is not a gradient.

**Recorded for the record — the rejected alternative is the leakier and less honest one.**
Round-down-with-no-partial would render 26⅔ as "26", a **false** statement about the mounted
pair on the one readout whose entire legitimacy rests on D13's own "encodes only the true
realized ratio of the mounted pair". It would also collapse 16×36 (R = 6, genuinely integer)
and 16×40 (R = 6⅔) onto an identical picture. Since D13's ungated status is justified
precisely by *"a mechanically true train must report the truth regardless of what has been
read"* (§3.4), a rendering that lies undermines the justification for the whole element. The
partial is the more faithful option.

### V17.3 (b) D11-class "reads as broken" risk — **real but bounded; PASS with W1–W3.**

- **No misread of the partial can produce a false 24 or suppress the true 24 — provable.**
  Rounding the three partials up or down gives 7 / 11 / 27 or 6 / 10 / 26. **None is 23, 24
  or 25.** The nearest non-integer to the target is 26⅔, a full 2.67 strokes away. And the
  solution pair renders 24 full strokes with **no partial at all**, so the solve signal can
  never be corrupted by partial-stroke confusion in either direction. Worst case of a total
  misread is a wrong pair staying wrong. **No correctness exposure: no soft-lock, no false
  positive, no false negative on the solution, no new mistake path.** This is what downgrades
  the D11 concern from structural to cosmetic.
- **Reproducibility is the anti-glitch cue, and it is already guaranteed.** RF-2(a)'s
  accumulated-rotation measure makes the picture byte-identical on every cycle of a given
  pair — the Designer's own reason for prohibiting index-crossing counting. Rendering errors
  do not reproduce pixel-identically on demand; a mark that survives a re-crank reads as
  intentional. This is exactly the `anti_softlock_invariants[3]` "repeat-identical
  presentation" class that G17 already extends to D13, and it is the substantive answer to
  the D11 worry.
- **Residual exposure is presentation-only, and W2/W3 close it.** A short stroke that shares
  the block's baseline and is shortened *at the top* reads as a deliberate mark; one that
  floats, is clipped at the bottom, or is faded/dashed reads as a render failure. The current
  D13 string does not say which. That is the whole of the remaining risk.
- **Stroke bound unaffected (V19/RF-3).** Maximum marks on any partial-bearing pair is
  26 + 1 = **27**, comfortably inside the RF-3 worst case of **48** (72 × 64, integer, no
  partial). The five-grouping legibility argument is untouched.
- **Fairness/RWK: no new demand.** The player is never required to interpret "⅔ of a turn" —
  the full-stroke count alone settles every one of these pairs. The partial is strictly
  optional information. **No new RWK register entry needed.**

### V17.4 (c) Colour-blind safety — **PASS (form-based), with one binding addition.**

Height and stroke length are achromatic **form/size** cues; the discrimination survives full
achromatopsia and all three dichromacies, and it does not depend on hue, saturation or the
warm/cool chalk-vs-timber relationship that RF-7(a) exists to police. D13 already pins same
chalk value, same stroke width, same slot pitch — which is the correct instinct.

**Binding addition (folded into W3):** the part-stroke must **not** be rendered lighter,
faded, ghosted, dashed, translucent or at lower opacity than a full stroke. Any of those
substitutes a *value* cue for the form cue, and would independently threaten the RF-7(a)
≥ 3:1 luminance floor at reduced size. The part-stroke must hold **≥ 3:1 luminance contrast
against the frame timber cheek in its own right, in BOTH the wide and the close-up.** With
that clause the mandatory colour-blind gate is **PASS**; without it the element sits one NB
chalk-on-timber blend away from an RF-7(a) violation.

### V17.5 (d) NET — approve with wording tweak

The mechanism is approved as designed; the Designer's reasoning survives adversarial
checking. Four wording tweaks to the **G16 D13** string, all non-semantic clarifications that
change no behaviour and require no redesign round-trip:

- **W1 (the one that matters — forward-guard).** Replace *"at roughly HALF HEIGHT"* with a
  **single fixed canonical part-stroke glyph at a CONSTANT height** (nominal 0.5×, Art
  Director's call within 0.4–0.6× of a full stroke), and add the clause: **"the part-stroke's
  height is a CONSTANT and MUST NOT be derived from the residue at runtime."** Today the two
  implementations are indistinguishable — every residue is exactly ⅔ (V17.2 proof 2) — but a
  residue-proportional implementation would silently convert stroke height into a *variable*
  channel the moment the gear set ever changed. That is the only mechanism by which this
  element could ever become a proximity signal. Freeze it now, while it costs nothing.
- **W2.** State that the part-stroke is **UPRIGHT — never drawn on the diagonal**, so it can
  never be confused with a five-group closing strike. D13 currently says only that it never
  *receives* a diagonal and is never counted into a five; it never says what it is. This
  matters at 26⅔, where the partial follows a lone single after five complete groups.
- **W3.** Add: **same baseline as the full strokes, shortened at the top, occupying its own
  full slot pitch**; plus the RF-7(a) / no-fade / no-dash colour-blind clause from V17.4.
- **W4 (Advisory — surfaced to the user, non-blocking).** Add Blind Playtester probe **P13**:
  *"Did you notice the short stroke? Did you read it as broken, and how long did you spend
  trying to decode it?"* The part-stroke is never load-bearing, so the worst realistic cost is
  a short rabbit hole — but bug-read perception is the one property here that analysis cannot
  settle and only measurement can.

**Rejected minimal alternative, recorded with its trade-off.** *Round down, no partial.*
Trade-off: it removes the cosmetic glitch risk entirely, at the cost of (i) making D13 state
something false about the mounted pair, undermining the mechanical-truth premise that is the
sole justification for D13 being ungated, and (ii) collapsing two genuinely distinct
mechanical states (R = 6 and R = 6⅔) onto one picture. **Strictly worse. Do not adopt.**

| V17 sub-check | Severity | Result |
|---|---|---|
| (a) Information leak / illegitimate elimination tell | — | **PASS** — zero marginal information; V4 preserved |
| (b) D11-class "reads as broken" | Advisory | **PASS with W1–W3** — no correctness exposure, provable |
| (c) Colour-blind safety (mandatory gate) | Advisory (binding clause) | **PASS with W3** — form/height, never value or hue |
| (d) NET | — | **APPROVE WITH WORDING TWEAK (W1–W4)** |
| Critical findings | — | **0** |
| Difficulty impact | — | **None.** z2 stays 6.5; level stays **6.0 PROVISIONAL** |
| V17 (rev-1.4 checklist item) | — | **PASS** — accumulated-rotation accrual confirmed, all three non-integer pairs covered, no oscillation possible |

---

## B.1 / F-4 verdict (targeted confirmation, 2026-08-08)

**Scope.** Single-question re-check of the Designer's **F-4** flag in
`clue-legibility-p06-p03-revB1-append.md` (rev B.1, target graph revision 1.4.1): does the
teach-at-dormer chalk note reopen the rev-B *"considered and rejected: chalk sight-line"*
finding, is it no-tell compliant, and does its "no new state / no new overlay id / content
change only" claim hold? Read-only against `puzzle-graph.json` (on disk at `spec_revision`
**1.4**, D12 present), `clue-legibility-p06-p03.md` rev B §2b, `style-guide.md`,
`blind-layout.md`, `asset-manifest.json` and `specs/assets/level-2/z1/z1-state-overlays.json`.
Nothing below reopens an approved decision, and nothing below is a redesign.

**VERDICT: CONFIRMED on all three questions asked. 0 Critical. 4 Advisory (B1-A1…B1-A4), all
documentation-consistency or forward-guard class. Does not block the Art Director hand-off of
H8 or the Blind Playtester re-run.**

### B.1-1 — F-4: the construction claim. **CONFIRMED.**

The rev-B rejection (`clue-legibility-p06-p03.md` §2b, verbatim) reads: *"Considered and
rejected: a chalk sight-line / dashed stroke from the ring to the board. It reads as a modern
UI arrow rather than a diegetic mark, it duplicates what C1+C2 already achieve, and it would
require a new glyph primitive outside the canon."* Its **object** is a ring→board connector.
B.1's object is a mark wholly contained in the `ov-cache-*` rect. They are different objects,
so the rejection is not reopened. Ground by ground:

| Rev-B ground | B.1 status | Basis |
|---|---|---|
| **(1) reads as a modern UI arrow** | **AVOIDED by construction** | B.1b states *"No line, no arrowhead, no dashes, no glow, no animation on appearance beyond whatever the rev-1.4 mark already does."* The mark is a filled silhouette on a physical surface in the clockmaker's established chalk register, not an overlay stroke. A clock hand is a **diegetic object in this level** (two watches + the great dial); an arrowhead is not. Residual risk is wide-scale silhouette identity, not UI-ness — see B1-A4. |
| **(2) duplicates what C1+C2 already achieve** | **SUPERSEDED by measurement — not "avoided by construction"** | The Designer's stated basis (*"the objective has changed"*) is defensible but under-states the real one. The honest basis is **new evidence that did not exist at rev B**: `playtest-report-rev1.4.md` P8 (*"because it had a house mark on it… no reference to the III bearing"*) and P11 (*"did I read it as a direction? no — never"*) demonstrate that C1+C2 achieve the **solve** and not the **teach**. B.1 rests on data, not on a redefinition. Recorded here because it strengthens the case and matters for the record. |
| **(3) requires a new glyph primitive outside the canon** | **AVOIDED — with one de-minimis exception** | `hand-hour` (`z3/v-dial/sprites/hand-hour`) is canonical and is **already composited by C1 and C3** per D12; `masters/glyphs/die-house.png` is canonical and byte-identical to rev 1.4. Neither is new. The **hub dot** is the one mark form not drawn from a named existing asset — see B1-A3. |

**Spanning test — PASS.** Containment in x 0.6375–0.7656 is a hard B.1b constraint and matches
D12's rev-1.4 rect verbatim. Nothing is drawn on the beam, between the beam and the floor, or
outside the mark rect, in either view. No gap is spanned in world space or image space.

**Rev-B bookkeeping — CONFIRMED.** The §2b rejection note **stands unreversed** and requires no
re-ratification. B.1 does not adopt a sight-line.

### B.1-2 — No-tell compliance. **CONFIRMED.**

- **Same gate.** `clu-watch-a`, one of the five persisted D7 booleans (graph D7, line 387).
  Unchanged; no new flag, no second condition.
- **Same single appearance event.** Visibility predicate stays `gate-satisfied AND NOT pried`,
  identical to D12's rev-1.4 predicate; the note renders on view entry. Nothing appears earlier,
  and there is no second event. The pre-clue board remains byte-identical to rev 1.4 and
  transitively to rev 1.3 (uniform boards, no hand in either view).
- **Not an attempt response.** `no_tell_rule` (graph line 24) governs *gated attempts* and their
  failure grammar; B.1 touches no attempt path. D10 (line 390) constrains the **pry response
  only**, and its own rev-1.4 clarification already states the annotations *"are functions of
  clu-watch-a / clu-watch-b, never of prying."* The wrong-spot dead wall and the D10
  correct-spot faint-tell are byte-stable. **D10 correctly appears on the Designer's
  deliberately-not-touched list.**
- **No new licence created.** `clue_gating.art_impact` (line 27) already scopes item **(ii)** as
  *"the chalk house glyph on the p03 cache board in the wide and the close-up"* — a **named**
  clue-state render, expressly *"NOT a general permission class."* B.1 changes the content of
  that already-named render and adds no fourth annotation, so **p07 and p09 remain strictly
  no-annotation**. That string's closing clause — *"Any future clue-state render requires
  Validator re-verification"* — is **satisfied by this verdict**, which is the re-verification.
- **Post-gate salience.** The note is more conspicuous than the single rev-1.4 glyph. This is
  **not** a no-tell concern (no-tell governs the pre-gate/gated window, where nothing renders)
  and it is already inside the A4-sanctioned, p03-only reversal. No finding.

### B.1-3 — "No new state / no new overlay id / content change only." **CONFIRMED, with one wording correction.**

Verified independently:

- **No new state.** No flag, node, edge, hotspot, gate, consumable or overlay id in any of
  H1–H8. All eight deltas are prose/content; the structural fields
  (`solution_fixed`, `requires`, `clue_gate`, `yields`, `failure_behavior`, `edges`,
  `anti_softlock_invariants`) are on the explicit not-touched list and stay byte-stable.
- **State set unchanged.** `unmarked -> marked -> pried-with-wheel -> empty` still totally
  ordered; suppression on pry rides the same overlay that already suppressed, so no note can
  survive on a lifted board or an empty cavity. **V14 closure re-confirmed.**
- **No M1 re-registration.** Rect containment preserves *what is marked is exactly what is
  tappable*.
- **RC-6 cardinality unchanged.** `ov-cache-marked` × `ov-cache-cat-gone` remains exactly one
  composite pairing (`ov-cache-cat-gone` confirmed present in
  `specs/assets/level-2/z1/z1-state-overlays.json`). **No new `Level2CloseUpStateTests`
  state-flip rows** — a re-render of the existing pairing only.
- **Cost.** $0 additional; the §4 fallback ceiling stays $0.45. Confirmed — the note is a
  deterministic PIL composite of two already-canonical assets.

**Wording correction (B1-A2, below):** B.1 repeatedly calls `ov-cache-marked-wide` /
`ov-cache-marked` the **"existing"** overlays. They exist **in the rev-1.4 spec** (D12 names
them) but **not as authored assets** — they appear nowhere in
`specs/levels/level-2/asset-manifest.json` (which carries `ov-cache-pried-wheel`,
`ov-cache-empty`, …) and nowhere in `z1-state-overlays.json`. Rev B §2b introduced them as
*"New state assets."* The claim that **matters** — *B.1 introduces no new overlay id* — is
**TRUE**, and the practical consequence is strictly favourable (nothing is regenerated; the pair
is authored once, from B.1 content, at zero rework). Only the word "existing" is imprecise.

### Advisory findings

**B1-A1 — Advisory (highest of the four). The H-list site sweep misses three graph sites, one of
which creates an intra-graph contradiction.** B.1c opens *"Site sweep first… Every site in the
repo that describes the p03 cache-board mark is enumerated below; there are eight, six of them
in the graph"* — written expressly to prevent an RF-5 recurrence. Three further graph sites
describe the mark and appear on **neither** the H-list **nor** the deliberately-not-touched list:

| Site | Current text | Effect after B.1 |
|---|---|---|
| `zones[z1-attic].views[v-door].elements`, floorboards string (**line 48**) | *"…the cache board carries a chalk house glyph (canonical die-house) composited INSIDE the ov-cache-* rect x 0.6375-0.7656, in BOTH the wide and the close-up."* | **Direct contradiction with H2.** H2 will say the board carries a two-mark chalk note; this says a single house glyph. This is the zone/view content contract Asset-Gen and the Art Director read, so left as-is it would author the rev-1.4 single glyph. **Fix before commit.** |
| `clue_gating.art_impact`, item (ii) (**line 27**) | *"the chalk house glyph on the p03 cache board in the wide and the close-up"* | Enumeration goes stale. The **scoping function is unaffected** (B.1 is a content change to a named render, not a new class), so this is accuracy only. |
| `visually_necessary_elements.rev_1_4_cue_note` (**line 416**) | *"one chalk house glyph on the p03 cache board"*; *"NO new glyph dies"* | Enumeration goes stale. B.1 does **not** breach *"NO new glyph dies"* (`hand-hour` is an existing sprite, not a die) or *"composites over existing plates and existing sprites"*. Accuracy only. |

Not a correctness defect — no solution value, gate, dependency or state consequence — but line 48
must be reconciled with H2 **before the Producer commits**, or the graph ships self-contradictory
about what is on the board. Route to the Designer for the two verbatim strings; do not
improvise them at commit time.

*Correctly omitted, confirmed intentional:* `revision_notes[]`'s rev-1.4 element (historical
record of rev 1.4, accurate as written) and **D10** (its rev-1.4 clarification names the mark in
passing, but D10 governs the pry response only and is rightly frozen).

**B1-A2 — Advisory. Read "existing overlays" as "specified at rev 1.4, not yet authored."**
Per B.1-3 above. Producer/Asset-Gen should not read B.1 as requiring an edit to a shipped asset.
Side effect, in the Producer's favour: because the pair is unauthored, **A10's rect-capacity
measurement can be folded into first authoring** rather than gating a re-edit — it still must
happen before art starts, and the B.1b fallback ladder (shorten the hand, never the house, then
escalate) still governs.

**B1-A3 — Advisory. The hub dot is the one mark form not drawn from a named canonical asset.**
B.1b defines it as *"a filled chalk dot the width of one chalk stroke."* It is best read as the
degenerate case of the existing chalk-stroke primitive at the same width and value, carrying no
independent semantic content — which is why this is Advisory and not a ground-(3) failure. Two
notes for the Designer's decision (not mine to make):
(i) it is the single point on which a strict reading of *"new primitive outside the canon"* could
bite, and the construction claim would be airtight without it;
(ii) hub-dot-plus-hand is the iconography of a **miniature clock face**, on a board the player
reaches immediately after learning *"the ring is a clock face."* B.1b's *"not a ring, no notches
— it must never invite counting"* is the correct guard and I confirm it is present; the residual
is that the note could read as a tiny clock rather than as a pointer, which is a **null teach,
not a wrong teach** (the player still sees a marked board and pries it, per S-7). Fold into
P12(a0) rather than redesigning.

**B1-A4 — Advisory, and the one with real forward risk. Escalation lever E1 *does* reopen the
rev-B rejection, and must not be treated as pre-approved.** B.1's F-1 pre-specifies E1 as *"a
short chalk sighting stub ruled along the beam outward from the ring at 3 o'clock, ~1–2
ring-diameters, terminating in a single short plumb tick downward."* That is **a ruled chalk
stroke originating at the ring** — squarely inside the rejected class on ground (3) (a ruled
multi-segment guide line is a new primitive outside the canon) and materially exposed on ground
(1). The Designer correctly says *"it would need its own Validator pass"* and *"do not pull E1
pre-emptively."* Strengthening that for the record: **if E1 is ever pulled it requires
re-ratification of the rev-B rejection by the user, not merely a Validator pass**, because it
reverses a recorded design finding rather than working around it. Nothing in B.1's approval
carries E1 with it.

### Difficulty — no change

I concur with S-4 and S-5. The note changes neither the target, nor the hotspot, nor the gate,
nor when the board becomes pryable; it adds confirmatory salience to a board that is already
marked and is already a single always-correct hotspot. **p03 stays 3.5; z1 stays 4.5; the level
stays 6.0 PROVISIONAL** (z1 4.5, z2 6.5, z3 7.0, z4 3.5). The expected p04 effect (stall 8–15 min
→ under 5 min, 6.5 → ~5.5–6.0) is **empirical and not scored here**; rewritten probe P12 settles
it. **This delta does not release the `progression-ledger.md` write** — that write remains held
pending the blind re-check, of which P12 is now part.

### B.1 / F-4 summary

| Check | Severity | Result |
|---|---|---|
| F-4 (a) no line / no arrowhead / no dashes | — | **CONFIRMED** |
| F-4 (b) spans no ring→board gap (rect-contained) | — | **CONFIRMED** |
| F-4 (c) no new primitive outside canon | Advisory (B1-A3) | **CONFIRMED** — `hand-hour` and `die-house` both canonical and already composited; hub dot de minimis |
| Rev-B rejection status | — | **STANDS UNREVERSED; no re-ratification required** |
| Ground (2) basis | — | **Superseded by rev-1.4 playtest evidence**, not avoided by construction — recorded |
| No-tell: same gate, same single appearance event, not an attempt response | — | **CONFIRMED** (no_tell_rule, D7, D10, art_impact all byte-stable) |
| No new state / no new overlay id / content-change-only | Advisory (B1-A2, wording) | **CONFIRMED** |
| Contract-site sweep completeness | Advisory (B1-A1) | **ISSUE — 3 graph sites missed; line 48 contradicts H2. Fix before commit.** |
| Escalation lever E1 | Advisory (B1-A4) | **Reopens the rev-B rejection if pulled — not pre-approved** |
| Colour-blind safety (mandatory gate) | — | **PASS** — shape and position only; the no-fade / no-ghost / no-dash / no-lower-opacity clause carried over from V17-W3 is present and correctly binding |
| Critical findings | — | **0** |
| Difficulty impact | — | **None.** z1 4.5; level **6.0 PROVISIONAL**; ledger write still held |
| **NET** | — | **CONFIRMED (0 Critical, 4 Advisory)** |
