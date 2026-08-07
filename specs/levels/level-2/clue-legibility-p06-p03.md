# Clue-Legibility Redesign — p06 (gear train) and p03 (dormer cache)

_Theme & Puzzle Designer, 2026-08-07. Level 2 "The Clockmaker's Attic", branch
`level2-clockmakers-attic`. Target graph revision: **rev 1.4**. SPEC ONLY — no code._

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
  no-tell rule, D10 faint-tell) preserved — with two textual clarifications listed in §4.
- Near-wordless. Every element below is a glyph, a stroke count, or a physical part. **No
  text is added anywhere.**
- Difficulty target stays **6.5-fair**. §5 lists where I believe the felt difficulty moves
  and flags it for the user rather than deciding it.

**Critical scoping caveat the Producer must carry to the user and the Blind Playtester:**
p03's build-16 clarification (`Level2CloseUpVisuals.ringClues` — the canonical hour hand
composited onto `cu-house-ring` once watch A has been inspected, per implementation-notes
"USER RULING — p03/p04 KEEP SIMPLE + CLARIFY") **shipped after the R8-009 report and has
never been measured.** The user's build-16 playthrough did not cite p03 among the
guide-mandatory beats. So the changes in §2 are **additive to an untested fix**, and the
blind re-check must measure the two together. I am not claiming the build-16 fix failed; I
am closing a gap it structurally cannot close (it lives in a close-up that contains no
floor).

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
player is left with pure algebra or pure brute force over ~30 ordered pairs.

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
bracket-panel VIII engraving is removed or demoted to secondary. The drive path
crank-pinion → (post A wheel) → post-A pinion → (post B wheel) → cam must read as one
continuous meshing chain even with both posts empty.
*Assets:* `l2_z2_build.render_gear` (the deterministic exact-tooth-count renderer already
used for the six rack gears) at n=8; canonical `render_roman`/numeral stamp from
`specs/tools/l2_glyphs.py`. Same square-arbor-hole rhyme as every other gear in the level.
*Art cost:* **$0** if a deterministic composite blends acceptably onto the timber/brass
(precedent: the 14 existing `ov-mount-*` post overlays are pure `render_gear` composites).
**≤ $0.15** if Asset-Gen judges a crop-scoped NB edit is needed to seat it believably.
*Verify first:* if the shipped plate already depicts an 8-tooth coaxial pinion clearly,
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
*Assets:* existing slate renderer + existing chalk stroke primitive. **$0** (deterministic
PIL). Re-runs the existing 24-count assertion.
*Note:* this touches an **approved, contract-passed plate** — Art Director sign-off is
required before Asset-Gen regenerates (§5, approval A3).

---

**F3 — Put the target where the work happens: the frame-side chalk crib. (fixes the
cross-zone memory burden on G3)**

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
*Art cost:* **$0** deterministic (reuses the F2 tally primitive) / **≤ $0.15** if a
crop-scoped NB chalk-on-timber blend is judged necessary.
*Separability:* F3 is the one change that softens the level's z1-slate → z2-frame
cross-zone binding. It can be dropped without breaking F1/F2/F4. **I recommend shipping
it** — the evidence is that the chain did not land *at all*, and a half-measure costs a
whole build/playtest cycle — but the tradeoff is the user's to accept (§5, approval A2).

---

**F4 — Deliver the counting route that D5 already promises. (fixes G3/G4 fallback)**

*Element:* a live chalk tally block on the frame cheek, directly beneath the F3 chalked 24.
*View:* `cu-gear-frame` primarily; mirrored in the wide if the crank is operable there.
*Behaviour (presentation only, derived — never stored):*
- One tally stroke is chalked up **per crank revolution** during the run, in the same
  stroke style and the same five-grouping as F2/F3, so the running count and the target sit
  eye-adjacent and compare at a glance.
- The count **resets at each cam clack** (i.e. it is always "cranks in the current cam
  cycle").
- The **final count of the completed cycle stays chalked** until the next crank press, so
  a player who looked away still gets the number.
- With the correct pair the count reaches exactly the chalked 24 as the cam completes and
  the latch takes — the machine chalks up the clockmaker's own number. That coincidence
  *is* the success beat.
*Constraints (non-negotiable, for the Validator):* the readout encodes **only the true
realized ratio of the mounted pair** — mechanical truth, identical to what a player could
derive by ear. It **never** hints at the target beyond the F3 chalk, never differs by how
close the pair is, and never varies with any clue-viewed flag. It is ungated, exactly as
p06 is ungated (a mechanically true train must work regardless of what has been read).
*Tedium guard:* one crank press = one full cam cycle (unchanged from the build); the
tallies accrue during that animation. Worst case across the whole gear set is 54 tallies —
the block must remain legible at that count (five-grouping makes it so). Do **not**
implement one-tap-per-turn.
*Art cost:* **$0** — same tally stroke primitive, composited N times at a measured rect.

### 1c. Intended step-by-step inference chain (for the Blind Playtester)

A blind player should be able to walk this without the walkthrough:

1. In z1 v-bench, open the slate close-up. It is a chalk drawing of a machine: a circle
   with a block of tally marks around it, a small wheel stamped **XII**, an unknown wheel
   `?`, a small wheel stamped **VIII** on the same axle, a second `?`, and a last circle
   with one notch, one tally mark, and a little door.
2. Read the proportion: **a block of 24 marks on the first circle, one mark on the last.**
   The last circle has a door on it. → *"Whatever the machine does, twenty-four of the
   first thing makes one of the last thing, and the last thing opens a door."*
3. In z2 v-frame, recognise the drawing: a fold-out crank carrying a small gear stamped
   **XII**; an empty post; a small gear stamped **VIII** sharing that post's axle; a second
   empty post; a cam that drives the mural and the wall-panel latch. The chalked 24-tally
   block and single tally are on the frame's own cheek beside the crank and the cam. →
   *"This is the drawing. The two `?` are the two empty posts. I choose the two wheels."*
4. **Route A (algebra).** A small gear driving a big one slows it by the tooth quotient;
   two stages multiply. (A/12) × (B/8) = 24 → A × B = 2304. The rack offers 16, 24, 36, 40,
   48, 72. No pair works — 48 × 48 would, but there is only one 48 anywhere. → *"A wheel I
   don't have yet must exist."* The great wheel from the floorboard cache is stamped **64**;
   36 × 64 = 2304. Mount 36 and 64 on the two posts, either way round.
5. **Route B (counting — equally sanctioned).** Mount any two wheels that mesh, crank once.
   The machine chalks up its own tally block as it turns; at the clack the count sits
   beneath the clockmaker's chalked 24. Too few → the pair is too small; too many → too big.
   Converge. The 64 arrives in the search the same way it does in Route A: once every rack
   pair has been tried and none reaches 24, the missing wheel must be elsewhere.
6. **Route C (hybrid, expected to be the common one).** Do the algebra loosely, use the
   tally readout to confirm and to catch arithmetic slips.
7. Crank one full cam cycle at 24:1 → mural runs clean, counterweight drops, wall panel
   swings open onto z3.

**Both orders of {36, 64} across posts A and B are correct** and both must be accepted.

### 1d. Graph / spec deltas for rev 1.4 (p06)

Precise change list:

1. **`clu-slate-ratio.content`** — amend to: *"…crank circle ringed with 24 tally marks
   **grouped in fives**; fixed pinion XII; unknown wheel '?'; fixed coaxial pinion VIII;
   unknown wheel '?'; cam circle with one notch **and one matching tally mark** and a door
   pictogram. Encodes: (A/12) x (B/8) = 24…"*. `supports`, `viewed_when`
   (`"slate close-up displayed"`) and its non-gating status are **unchanged**.
2. **New node `clu-frame-tally`** (type `clue`):
   - `location`: `"z2 v-frame, gear-frame timber cheek"`
   - `content`: `"Chalked in the clockmaker's hand on the frame itself: a 24-tally block
     (grouped in fives) beside the crank station and a single matching tally beside the cam
     station. Restates the slate's target proportion at the point of use; carries no
     structural information (the two-stage layout is read off the machine)."`
   - `supports`: `["p06-gear-train"]`
   - `viewed_when`: `"gear-frame close-up displayed (self-satisfying — the mounting and
     cranking controls live in this close-up)"`
   - **Non-gating.** p06's `clue_gate.gated` stays `false`; `required_viewed` is not
     introduced. No new edge of type `clue_gate`. Add a `supports`-class edge
     `{ "from": "clu-frame-tally", "to": "p06-gear-train", "type": "clue" }` consistent with
     how the other non-gating clue nodes are edged.
   - **No D7 persisted boolean** (D7 covers gating clues only — do not add one).
3. **`p06-gear-train.clues`** — append two entries: `"clu-frame-tally (chalked target
   proportion at the frame)"` and `"live crank-tally readout (D13): one chalk stroke per
   crank revolution in the current cam cycle, reset at each clack, final count persists"`.
   The existing entry *"live mechanical feedback… the cam clack's cranks-per-clack cadence
   is countable"* is amended to point at D13 as its realization.
4. **`p06-gear-train.clue_gate.rationale`** — append: *"Rev 1.4: the D13 tally readout is
   mechanical truth (the realized ratio of the mounted pair), so it too is ungated;
   gating it would reintroduce the broken-machine read the ungated rationale exists to
   prevent."*
5. **Amend `developer_notes` D5** — append: *"REV 1.4: 'countable' is now realized on
   screen, not only in audio. See D13. The build-16 implementation ran a whole cam cycle on
   one press with no countable artifact, so the sanctioned no-algebra route (playtest 2b)
   was specified but not delivered; D13 delivers it."*
6. **New `developer_notes` D13 — "Live crank-tally readout (rev 1.4)"**: presentation-only,
   derived from crank revolutions within the current cam cycle, never stored; resets at each
   cam clack; final count persists until the next crank press; identical rendering for every
   mounted pair (it reports the realized ratio and nothing else); ungated; renders in
   `cu-gear-frame` and in the wide if the crank is operable there; must stay legible at 54
   strokes (five-grouping); one crank press = one full cam cycle (do not implement
   per-turn tapping).
7. **`visually_necessary_elements.z2-workroom`** — amend the gear-frame line to require:
   *"POST A carrying a visibly depicted **8-tooth coaxial pinion** with VIII stamped on its
   own face annulus (not on a bracket panel); the drive path crank-XII → post-A wheel →
   post-A VIII → post-B wheel → cam legible as one continuous meshing chain with both posts
   empty"*. Add two new lines: *"chalk crib on the frame cheek: 24-tally block (grouped in
   fives) at the crank station, single matching tally at the cam station"* and *"live tally
   block: states 0…N strokes, resets at clack, final count persists"*.
8. **`visually_necessary_elements.z1-attic`** — amend the slate line: *"…24 tallies grouped
   in fives, XII, VIII, two '?', cam notch **plus one matching tally**, door pictogram"*.
9. **`colorblind_safety`** — append: *"Rev 1.4 chalk marks (slate regrouping, frame crib,
   live tally) are luminance-contrast strokes counted by quantity and grouped by shape; no
   color channel is load-bearing, and no mark is distinguished from another by hue."*
10. **`designer_difficulty_estimate.validator_score_status`** — append a rev-1.4 note (see
    §5 for the direction I expect); the Validator assigns the official number, not me.
11. **`escalation_rationale`** — amend clause (3): the z1-slate → z2-frame cross-zone
    binding is **softened** if F3 ships (the target proportion is restated at the frame; the
    two-stage structure is still derived from the machine). Leave the clause intact if the
    user declines F3.
12. **`mechanics_used_for_ledger`** — no change. The mechanic is the same gear-ratio train.
13. **`red_herrings.rh-48-gear`** — no change. The lone-48 trap survives F4 intact: mounting
    48 with anything yields an honest, non-24 tally count.
14. **`anti_softlock_invariants`** — no change; state explicitly in the rev note that F1–F4
    introduce **no new state, no new gate, and no new consumable**.

### 1e. What the Validator and the Blind Playtester should check (p06)

**Validator (delta-check):**
- V1. Solution set is unchanged and both post arrangements of {36, 64} still resolve.
- V2. `clu-frame-tally` is referenced by **no** `clue_gate` anywhere; p06 remains ungated;
  no D7 boolean was added for it.
- V3. D13 introduces no state: confirm the readout is a pure function of (mounted pair,
  crank revolutions in current cycle) and cannot be read by any gate or condition.
- V4. D13 leaks nothing beyond mechanical truth — in particular that the readout is
  identical in form for correct and incorrect pairs and does not vary with proximity to 24.
- V5. rh-48-gear still functions as a time-cost trap and has not become self-disproving in a
  way that removes the intended deduction "a 64 must exist elsewhere."
- V6. F1 does not change the ratio arithmetic — the coaxial pinion was always 8 teeth in the
  spec; this is depiction, not mechanism.
- V7. Colorblind check on the three new chalk elements (count/shape only).
- V8. Difficulty delta: quantify the change to the worst-case brute-force tail and to the
  intended path; confirm the level's official score.

**Blind Playtester (re-check, mandatory):**
- P1. Standing at the gear frame with both posts empty, can you describe the drive path
  out loud — what turns what, and in what order? (This is the F1 test. If the answer is
  vague, F1 has not landed.)
- P2. Without returning to z1, can you state the target proportion from what is visible at
  the frame? (F3 test.)
- P3. From the slate alone, what do the 24 marks and the cam's one mark mean? Answer before
  reading anything else. (F2 test.)
- P4. Mount a deliberately wrong pair and crank. Does the tally readout tell you *which
  direction* to move, without telling you the answer? (F4 test.)
- P5. Time-to-solve for p06 in isolation, and which of Routes A/B/C you actually used.
- P6. Did anything about the crib or the readout feel like the game solving itself? (The
  legibility-vs-easing boundary — report honestly; this is the number the user will judge.)

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

Two changes. Both are gated on the **existing** `clu-watch-a` persisted boolean (D7) — no
new flag, no new gate, no new hotspot.

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
*Placement (hard constraint):* the mark must be composited **inside the measured
`ov-cache-*` wide rect, x 0.6375–0.7656** (from implementation-notes M1), i.e. on the actual
cache board and inside the existing `floor-cache` hotspot. This guarantees "what is marked
is what is tappable" and **requires no new hotspot and no M1 re-registration.** Mirror the
same mark into `cu-floor-cache` at the corresponding crop coordinates.
*Assets:* `masters/glyphs/die-house.png` (canonical, already used on watch A's inner lid and
the beam carve) rendered in the chalk value `#E8E4DA`, composited deterministically.
*Art cost:* **$0** deterministic PIL / **≤ $0.15** if a crop-scoped NB edit is needed to
sit chalk convincingly on worn timber in raking light.
*New state assets:* `ov-cache-marked-wide` and `ov-cache-marked` (close-up). These must
compose correctly with the existing `ov-cache-pried-wheel` / `ov-cache-empty` /
`ov-cache-cat-gone` overlays — once the board is pried, the mark is naturally gone with the
lifted board (the pried and empty overlays already replace that region, so the ordering is
"marked → pried → empty" with no new combinatorics).

---

*Considered and rejected:* a chalk sight-line / dashed stroke from the ring to the board.
It reads as a modern UI arrow rather than a diegetic mark, it duplicates what C1+C2 already
achieve, and it would require a new glyph primitive outside the canon.

### 2c. Intended step-by-step inference chain (for the Blind Playtester)

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

The beat should now be solvable in **one to three minutes** by a player who has inspected
watch A, with zero random clicking. A player who has *not* inspected watch A still sees
uniform boards and gets the unchanged D10 grammar (dead "doesn't budge" on wrong spots,
faint creak-and-shift on the correct one).

### 2d. Graph / spec deltas for rev 1.4 (p03)

1. **`p03-cache-dormer.solution_fixed`, `requires`, `clue_gate`, `yields`,
   `failure_behavior`** — **all unchanged.** Restate this explicitly in the rev-1.4 note so
   the Validator's diff is unambiguous.
2. **No new clue node and no new state.** The annotations render off the existing
   `clu-watch-a` D7 boolean. Do **not** add a D7 flag, a gate, or an edge for them.
3. **`clu-ring-dormer.content`** — amend to record the rendering contract: *"…Carved ⌂
   ringed by a 12-notch clock-position circle. **REV 1.4: once clu-watch-a has been viewed,
   the ring renders the canonical hour hand at the 3-notch in BOTH the wide view and the
   close-up, and the cache board carries a chalk ⌂ of the same canonical die.** 3-o'clock =
   toward the marked board right of the dormer."* `viewed_when` unchanged (*"dormer ring
   close-up displayed (not part of the gate; anchor only)"*) — it stays non-gating.
4. **Zone element string, `z1-attic` → `v-door`** — replace *"floorboards below and around
   the dormer, uniform, none visibly special (cache board has NO independent VISUAL tell…)"*
   with: *"floorboards below and around the dormer, uniform and identical **while
   clu-watch-a is unviewed**; once watch A has been inspected the cache board carries a
   chalk ⌂ (canonical die) inside the cache rect, in both the wide and the close-up. The
   board still has no PRE-CLUE visual tell — the gate carries the info, and rev 1.3's D10
   faint-tell remains animation/SFX only."*
5. **Amend `developer_notes` D10** — the sentence *"NO persistent visual change to the
   board/brick in any state or view — the spot looks identical before and after"* must be
   scoped so it cannot be read as forbidding C2. Amend to: *"…no loose wobble, no gap
   opening, and no persistent visual change **caused by the pry attempt** — a pre-clue pry
   leaves the spot looking identical before and after. (REV 1.4: this constrains the
   *pry response* only. The rev-1.4 clue-viewed annotations — ring hand and chalk ⌂ — are
   a function of clu-watch-a, never of prying, and are correctly invisible to a player who
   has not read the watch.)"*
6. **New `developer_notes` D12 — "Pointer-resolution annotations (rev 1.4)"**: renders off
   the existing `clu-watch-a` D7 boolean; two composites (wide ring hand; chalk ⌂ inside the
   `ov-cache-*` rect x 0.6375–0.7656, mirrored into `cu-floor-cache`); wide and close-up must
   never disagree; layer order marked → pried → empty; introduces no state, no hotspot, no
   gate; must be suppressed the moment the board is pried.
7. **`clue_gating.art_impact`** — append a rev-1.4 clause: the annotations are **clue-state
   renders, not gate tells.** They never appear in response to an attempt and therefore do
   not touch `no_tell_rule`; the wrong-spot wall and the correct-spot faint-tell are
   byte-stable.
8. **`visually_necessary_elements.z1-attic`** — amend the ⌂-beam/floorboard line: add
   *"REV 1.4: clu-watch-a-gated annotations — canonical hour hand on the ring at the 3-notch
   in the WIDE view as well as the close-up; chalk ⌂ (canonical die-house) on the cache
   board in both views; states: unmarked (pre-clue) / marked / pried-with-wheel / empty."*
9. **`colorblind_safety`** — append: *"The rev-1.4 p03 annotations are glyph shape and
   pointer angle; the chalk mark is distinguished by its shape and its luminance against
   timber, never by hue."*
10. **Style-guide §6.3 must be updated in the same pass** — its current text ("The cache
    board has **NO independent visual tell** in any state or view — identical boards, by
    design") will otherwise directly contradict the graph. Same edit as delta 4. This is an
    Art Director-owned file; route the edit, do not have Asset-Gen apply it silently.

### 2e. What the Validator and the Blind Playtester should check (p03)

**Validator (delta-check):**
- V9. `p03-cache-dormer` is byte-stable in solution, requirements, gate, yields and failure
  behaviour.
- V10. No new state, flag, node, edge or hotspot was introduced; the annotations are pure
  functions of the existing `clu-watch-a` boolean.
- V11. The pre-clue experience is unchanged — confirm a player who has not inspected watch A
  sees no mark and no hand, in **either** view, and that D10's faint-tell grammar and the
  wrong-spot wall are intact.
- V12. `no_tell_rule` is not violated: the annotations are never a response to an attempt.
- V13. Wide↔close-up parity: the mark's presence/absence is identical in both views in every
  state (this is the standing directive that generated Cluster A/Q).
- V14. Overlay ordering marked → pried → empty produces no state in which a chalk mark
  survives on a lifted board or on an empty cavity.
- V15. Difficulty delta for z1 and for the level; note that p03's *mechanical* difficulty was
  already collapsed by the KEEP SIMPLE ruling, so the delta should be measured against the
  as-built, not against the rev-1.3 design intent.

**Blind Playtester (re-check, mandatory):**
- P7. After inspecting watch A, how long from entering the stair-door view to prying the
  correct board? Target: under three minutes, zero random clicking.
- P8. Did you understand *why* that board? Say it in your own words. (If the answer is "it
  had a mark on it" with no reference to the ring or the watch, C1 has not landed and only
  C2 is carrying the beat — report that; it is a real, though acceptable, outcome.)
- P9. Deliberately visit the stair-door view **before** inspecting watch A. Do the boards
  look uniform? Does anything hint at the cache? (Must be "no".)
- P10. Does the marked board look like part of the room, or like the game pointing at
  itself?
- P11. Re-measure the build-16 ring-hand annotation while you are here — it has never been
  blind-measured (see §0).

---

## 3. Visually-necessary elements added or changed (Art Director hand-off)

| # | Zone / view | Element | New or changed | Owner |
|---|---|---|---|---|
| 1 | z2 v-frame (wide + `cu-gear-frame`) | Post-A coaxial **8-tooth pinion**, VIII stamped on its own face annulus; continuous crank→A→B→cam mesh legible with both posts empty | changed (verify first) | Asset-Gen (`render_gear` n=8) + Art Director |
| 2 | z1 v-bench (wide + `cu-slate`) | Slate: 24 tallies **grouped in fives**; **one matching tally on the cam rim** beside its notch | changed — approved plate | Art Director sign-off → Asset-Gen |
| 3 | z2 v-frame (wide + `cu-gear-frame`) | Chalk crib on the frame cheek: 24-tally block at the crank station, single tally at the cam station | new | Asset-Gen (deterministic) |
| 4 | z2 `cu-gear-frame` | Live tally block, 0…N strokes, resets at clack, final count persists | new | Developer (composite) + Asset-Gen (stroke primitive) |
| 5 | z1 v-door (wide) | Canonical hour hand on the ⌂ ring at the 3-notch, gated on `clu-watch-a` | new rect, existing sprite | Developer |
| 6 | z1 v-door (wide + `cu-floor-cache`) | Chalk **⌂** on the cache board inside x 0.6375–0.7656, gated on `clu-watch-a`; overlays `ov-cache-marked-wide` / `ov-cache-marked` | new | Asset-Gen (deterministic `die-house`) |

Everything above uses existing canonical dies, existing deterministic renderers, or existing
sprites. **No generative scene work. No new glyph dies. No new hotspots.**

## 4. Art cost

| Item | Deterministic (preferred) | Fallback if an NB blend is required |
|---|---|---|
| F1 post-A pinion | $0.00 | $0.15 |
| F2 slate re-render | $0.00 | $0.00 |
| F3 frame chalk crib | $0.00 | $0.15 |
| F4 live tally strokes | $0.00 | $0.00 |
| C1 wide ring hand | $0.00 | $0.00 |
| C2 cache chalk ⌂ (2 overlays) | $0.00 | $0.15 |
| **Total** | **$0.00** | **$0.45** |

L2 cap is $15.00 with **$2.25 headroom**, so even the all-fallback case ($0.45) clears with
$1.80 to spare. My recommendation: authorise the $0.45 ceiling up front so Asset-Gen is not
blocked mid-pass, and expect to spend $0.00–$0.15 of it.

## 5. Producer approvals and flags — do not proceed without these

**A1 — p06 difficulty judgment call (F4, the live tally readout).** The readout gives an
exact, legible error signal on every crank, which converts p06's fallback path from
"listen to a cadence" into a visible hill-climb; a determined player can converge in roughly
three attempts without doing any algebra. My position: this is **spec conformance, not
easing** — graph D5 and playtest tweak 2b already declare the counting route sanctioned and
load-bearing, and the build simply never delivered it. But it is unambiguously a change to
the *felt* difficulty of the level's signature mechanic, so it is the user's call, not mine.

**A2 — p06 cross-zone binding (F3, the frame-side chalk crib).** Shipping it means the
target proportion no longer has to be carried from z1 to z2 in the player's head; the
level's escalation rationale explicitly counts that cross-zone binding as difficulty. F3 is
separable from F1/F2/F4. **I recommend shipping it** given the evidence, but the user may
prefer to ship F1+F2+F4 first and hold F3 in reserve for the next measurement.

**A3 — F2 touches an approved, contract-passed asset.** `cu-slate` passed art review with a
hard exact-count contract. Regrouping the tallies and adding the cam tally requires Art
Director sign-off and a re-run of the 24-count assertion before Asset-Gen regenerates.

**A4 — p03 difficulty judgment call (C2, the chalk ⌂ on the board).** This converts p03's
final hop from spatial projection into symbol matching — the clue class the user solves
reliably. Given the pointer mechanic is already collapsed to a single hotspot per the KEEP
SIMPLE ruling, I judge this consistent with the user's own direction, but it is a difficulty
decision and it should be stated plainly rather than absorbed.

**A5 — p04 grammar symmetry (a real fork, user's call).** p03 and p04 are a matched pair by
design: same watch grammar, same ring die, same pry verb. If p03's board gets a gated chalk
mark and p04's chimney brick does not, the level teaches a rule at p03 and breaks it at p04.
**But p04 was explicitly NOT reported as failing** ("p04 chimney (post-clue)" is listed among
the clue-chains that landed), and my brief scopes me to two beats. Three options: (i) apply
the identical gated chalk **⚙** to the cache brick for grammar consistency (+$0.00–0.15);
(ii) leave p04 untouched and accept the asymmetry; (iii) defer to the same blind re-check
that measures p03. **I recommend (iii)** — let the playtester report whether the asymmetry
reads as a bug — but I am flagging it rather than deciding it. *(Related, already routed:
implementation-notes records that `clu-ring-chimney`'s hotspot was missing and was added in
the build-16 wiring batch, so p04's ring beat only became visible very recently and has
likewise never been measured.)*

**A6 — graph-rule touches requiring explicit sign-off.** Three rev-1.3 texts are edited, all
clarifications rather than reversals, but all in load-bearing rule prose: **D10** (scoped to
pry responses so it cannot be read as forbidding clue-viewed annotations), **`no_tell_rule`
/ `clue_gating.art_impact`** (annotations classified as clue-state renders, not gate tells),
and **style-guide §6.3** (the "no visual tell in any state or view" line, which would
otherwise contradict the graph). None changes a gate, a solution or a state; all three need
the Validator's eyes specifically.

**A7 — real-world-knowledge check (minor, but flagging per the standing rule).** F2/F3/F4
rely on **tally marks grouped in fives** (four uprights plus a diagonal strike) reading as a
countable quantity. I judge this comfortably inside the educated-generalist bar — it is a
near-universal counting convention and the player is never required to *use* it as
arithmetic, only to compare two blocks of marks. But it is a convention rather than a fact,
so I am naming it rather than assuming it. No other new real-world knowledge is introduced;
the gear-ratio and clock-face facts are the already-ratified ones.

**A8 — verification dependency (do this before art work starts).** F1 is written as
"verify, then fix" because I am reading the asset manifest, not the shipped pixels. Someone
with the plate in front of them must confirm whether an 8-tooth coaxial pinion is actually
depicted at post A. If it is, F1 shrinks to a stamp relocation ($0). If it is not, F1 is the
single highest-value change in this document and should lead the batch.

## 6. Sequencing note

F1 (verify + depict the second stage) should land **before** the blind re-check regardless of
what else is approved, because every other p06 change is measured against a frame the player
can actually read. C1 and C2 should land together — shipping C1 alone leaves H4 unsupported,
and shipping C2 alone reduces the beat to mark-hunting with the reasoning stripped out.
