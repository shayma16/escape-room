# Level 1 — The Wizard's Cabin — Validation Report

**Validator:** Puzzle Logic Validator
**Input:** `specs/levels/level-1/puzzle-graph.json` (+ designer summary)
**Date:** 2026-07-04
**Verdict: PASS with 2 required fixes (both Advisory-severity spec corrections) and 6 advisories. No Critical findings. Cleared for user checkpoint review.**

---

## 1. Solvability — PASS

Full dependency trace from the start state (z1, empty inventory):

| Node | Reachable via | Verdict |
|---|---|---|
| itm-poker | free pickup, z1 | PASS |
| p01-rune-door | 6 clues, all in z1, no item prereqs | PASS → unlocks z2 |
| p02-moon-trapdoor | move rug (free) + triptych clue (z1) | PASS → unlocks z3 |
| p05-ash-sift | poker (z1) | PASS → gold ring |
| p03-astrolabe-orion | z2 + window clue (z2) | PASS → coin, crank |
| p04-cabinet-sun-moon | ring (p05) + coin (p03) + z2 | PASS → file, phial |
| p06-barrel-pry | poker + z3 | PASS → weight |
| p07-shelf-counterweight | weight + z3 | PASS → unlocks z4 |
| itm-spoon | free pickup, z3 | PASS |
| itm-cage-key | free pickup, z4 | PASS |
| p08-shutter-winch | crank (p03) + z3 | PASS → moonbeam-on |
| p09-mirror-aim | moonbeam-on + scratch-mark clue | PASS → beam-at-alcove |
| p10-moonflower-bloom | beam-at-alcove + z4 | PASS → blossom |
| p11-cage-unlock | cage key | PASS → feather |
| p12-file-shavings | file (p04) + spoon (z3) | PASS → shavings |
| p13-grind-paste | blossom + z2 mortar | PASS → paste |
| p14-brew | paste + shavings + feather + z2 | PASS → draught-ready |
| p15-fill-phial | phial (p04) + draught-ready | PASS → filled phial |
| p16-door-unseal | filled phial | PASS → door-unsealed |
| p17-escape | door-unsealed | PASS → **WIN** |

All 17 puzzle nodes, 15 items, and 12 clues are reachable. The win node is reachable.
Every clue supporting a puzzle is obtainable at or before the moment its puzzle first
becomes attemptable (grimoire pages, triptych, and all four rune marks are in the start
zone; the Orion window is in the same view as the astrolabe; scratch marks are in the
same view as the mirror).

**Cross-link cycle check — PASS.** The two branch cross-links (crank: workshop→cellar;
file+spoon: workshop+cellar→shavings) both flow *into* consumers with no return edge.
z2's unlock depends only on z1; z3's unlock depends only on z1; z4's unlock depends only
on z1+z3 (poker + barrel). No circular dependency exists.

---

## 2. Soft-lock analysis — PASS (no soft-locks found)

Mistake-path probes performed:

| Player mistake | Outcome | Soft-lock? |
|---|---|---|
| Wrong rune sequence / dial code / star plate, repeatedly | Reset, no lockout, dials retain position | No |
| Swapped ring/coin in cabinet slots | Items pop back to inventory | No |
| Brew with wrong flame / direction / count; any ingredient subset | Gray fizzle; **all ingredients returned intact**; infinite retries | No |
| Feather added to cauldron before flame is set | Explicitly allowed; returned on failed resolve | No |
| Free crow first thing after reaching z4 (before any brewing) | Feather held; sole use is p14; cannot be lost | No |
| Rusted key tried on cage / front door | Visibly rejected; key not consumed | No |
| Enter z3 before ever opening z2 (ordering A style) | Fully supported; crank fetch happens later | No |
| Rotate mirror to detent-3 *before* opening the shutter | Must still latch beam-at-alcove — see Required Fix 2 | No, **if** fix applied |
| Pour filled phial into crow's feed cup or other container | Cauldron stays draught-ready → refill exists | No (see Advisory A3) |
| Solve p16 before freeing the crow | p11 is not on the critical path for p16; crow-freed only gates the win *beat*, not the win — confirmed p17 requires only door-unsealed | No |

Consumable audit: the only consumed items are blossom→paste→(brew), shavings→(brew),
feather→(brew), draught→(basin), ring/coin→(seated in cabinet, no later use),
weight→(hung, no later use), cage key→(single lock). Every consumption point either
cannot fail (p13, p16) or returns the item on failure (p14, p04). The spoon-consumption
note on p12 is sound: re-filing is only impossible after the draught exists, at which
point shavings are no longer needed.

**No dead-end state is reachable, including via plausible mistakes.**

---

## 3. Zone-unlock integrity — PASS

| Zone | Intended unlock | Alternate entry? | Reachable? |
|---|---|---|---|
| z2 Workshop | p01 (solvable entirely from z1 clues) | None modeled | Yes |
| z3 Cellar (hidden) | p02 (rug is freely movable; triptych in z1) | None modeled | Yes |
| z4 Alcove (nested hidden) | p07 (weight ← p06 ← poker, all pre-z4) | None modeled | Yes |

Both hidden zones are reachable only via their single intended unlock edge; no
early-entry path exists (no window, gap, or secondary door into z3/z4 is specified).
The nested-hidden-zone structural requirement (project principle 7) is satisfied:
z4 is hidden inside hidden z3.

---

## 4. Path consistency — PASS (with one spec correction required)

The requirement-flag state model is correctly specified: all progression is
"requirement satisfied" flags; p14 ingredient order is explicitly order-free; only
solution *values* (rune sequence, dial shapes, stir parameters) are ordered. All
interleavings of the two branches that satisfy the requires-edges resolve to the same
completable end state; no ordering produces divergent or stuck state.

**However — Required Fix 1:** `solve_path_notes.example_ordering_A` is invalid as
written. It lists **p04 before p05**, but p04 requires `itm-gold-ring`, which is yielded
by p05. (It also omits the poker and spoon free pickups, as does ordering B for the
poker.) The underlying graph is consistent; the *example* is wrong. This must be
corrected before the Blind Playtester / Developer stages treat it as a reference path.

- Valid correction of A: `["move rug", "p02", "take poker", "p06", "p07", "cage key",
  "p11", "p01", "p03", "p05", "p04", "p08", "p09", "p10", "take spoon", "p12", "p13",
  "p14", "p15", "p16", "p17"]` (Designer to confirm — Validator does not redesign.)

**Required Fix 2 (implementation invariant, route to Developer spec):** `beam-at-alcove`
must be evaluated as a **condition** (`mirror-at-detent-3 AND moonbeam-on`), not as an
event sequence. If the player sets the mirror to detent-3 *before* cranking the shutter
open, the beam state must latch the moment the shutter opens. Anything else violates
project principle 4 (state = satisfied requirements, not step order). The graph's
current `requires: ["state: moonbeam-on"]` phrasing on p09 is ambiguous on this point.

Severity of both fixes: **Advisory** (neither makes the design unsolvable or
soft-lockable; both are spec-accuracy defects that would propagate downstream if
uncorrected). Route to the Designer via the Producer.

---

## 5. Real-world-knowledge fairness

| Fact | Puzzle | Ruling | Notes |
|---|---|---|---|
| Roman numerals I–IV | p01, p14 | **PASS — clearly fair** | Clock face I–XII is a complete in-room decoder; also legible as "count the strokes" for I–III. |
| Orion's Belt | p03 | **PASS — clearly fair** | Cited in project brief as the fairness benchmark. Zero-knowledge fallback (dot-pattern matching window↔plate) is genuinely sufficient; the six plate patterns are structurally distinct (cross, belt+4, seven-star ladle, hook, arc, zigzag). |
| Sun=gold / moon=silver | p04 | **PASS — advisory** | With the shape-fit slots (round ring↔rayed round recess, crescent coin↔crescent recess) plus grimoire page B, the alchemical fact is pure flavor; a player with zero prior knowledge solves it by fit alone. Recommend keeping as designed. |
| Moonflowers bloom in moonlight | p10 | **PASS — advisory (soft)** | Folk logic, but the trembling-bud feedback fires the moment the beam exists anywhere in the cellar — that is a live, causal, in-room cue, and the recipe's blossom-under-moon-ray pictogram seals it. Acceptable for a near-wordless game. |
| Waxing vs waning orientation | p02 | **PASS — not knowledge** | Pure silhouette copying from paintings to dials. No astronomy required. (Legibility burden shifts to art — see A5.) |

No real-world fact is load-bearing without an in-room zero-knowledge backup.
**Fairness gate: PASS.** Advisories on rows 3–4 stand for the user's checkpoint call.

---

## 6. Color-blind safety — PASS (mandatory gate)

Per-element verification of the designer's claimed mitigations:

| Element | Claimed non-color cue | Holds? |
|---|---|---|
| Moon-phase dials (p02) | Embossed silhouette shapes only | **Yes** — no color channel at all |
| Element runes (p01) | Distinct geometric glyphs + grimoire pictogram pairing | **Yes** |
| Gold ring vs silver coin (p04) | Round band vs crescent-stamped disc; slot shape-fit; hallmark stamps | **Yes** — metal color is never the discriminator; the physical fit *is* the puzzle |
| Flame stages (p14) | Flame height + lit ember channel on embossed rim numeral I/II/III | **Yes** — height is spatial, lit-vs-unlit is luminance (CB-safe), numeral is symbolic; triple redundancy |
| Brew success cue | Spiral surface *pattern* + sheen animation | **Yes** — pattern/motion, not hue |
| Potion-shelf red herrings | ≥5 distinct bottle shapes + pictogram labels | **Yes** — liquid color explicitly non-load-bearing |
| Star plates / window sky (p03) | Dot-pattern geometry | **Yes** — monochrome by nature |
| Moonbeam / beam routing (p08–p10) | Beam presence/position = luminance + geometry | **Yes** |

**No puzzle relies on color-only differentiation. Hard gate: PASS.**
Art Director note: preserve these redundancies at asset time — they are load-bearing,
not decorative (especially embossed dial silhouettes and rim ember channels).

---

## 7. Red herrings — PASS (all four have fairness valves; none soft-lock)

| Red herring | Fairness valve | Soft-lock risk |
|---|---|---|
| Rusted bent key | Close-up shows snapped *plain* bit; cage keyhole visibly star-shaped | None — key persists, fits nothing, consumes nothing |
| Potion shelf | Wax-fused stoppers (cannot be opened, so cannot be mis-poured); unrelated pictogram labels | None — physically inert |
| Mantel clock | XII pops the cuckoo-crow (charm); numeral ring genuinely serves p01, so investigation pays forward | None — hands freely movable, no lock state |
| Grimoire decoy pages | Encode nothing; bird diagram foreshadows the crow | None — see A4 below |

None of the four can be mistaken for a soft-lock: each remains fully inspectable and
visibly inert/rejected rather than "consumed and gone."

---

## 8. Difficulty scoring (official ledger values)

| Zone | Score /10 | Basis |
|---|---|---|
| z1 Main Cabin | **5.0** | p01 six-clue scavenger + symbol mapping + ordered entry (4); p02 hidden discovery + mirrored-silhouette precision, the level's deduction peak (6); p05 tool-use (2); p11 "freely given" insight beat (4); p16/p17 trivial closers |
| z2 Workshop | **6.0** | p03 six-way pattern match (4); p04 dual-cue placement (3); p13 apparatus (2); **p14 multi-parameter procedure from pictograms only — the level's precision peak (7)**; p15 (1) |
| z3 Cellar | **4.0** | p06/p07 mechanical (2–3); p08 cross-zone crank fetch (3); p09 detent + scratch clue (4) |
| z4 Alcove | **5.0** | p10 convergence: requires the winch, mirror, and shelf systems all assembled — individually easy, jointly the level's integration peak |
| **Overall (ledger)** | **6.0 / 10** | 17 nodes, 2 nested hidden zones, 2 cross-linked branches, 4 red herrings, near-wordless clue delivery; offset by zero timers/lockouts/consumable-loss and full in-room verifiability. Designer's 6.5 is defensible; 6.0 is the official score — the anti-frustration invariants are strong enough to pull the effective difficulty slightly under the structural complexity. Blind-solve estimate of 45–75 min is plausible; the Blind Playtester pass will calibrate. |

**Mechanics for the ledger** (avoid over-repetition in Level 2): as listed in
`mechanics_used_for_ledger` — notably shape-orientation dials, star-pattern matching,
light routing, counterweight unlocks, and procedural brewing are now "used once."

---

## 9. Ruling on the designer's 6 flagged judgment calls (Validator's independent take)

1. **Sun=gold/moon=silver (p04): Keep as designed.** The shape-fit path makes the
   alchemy pure flavor; zero-knowledge solvable. No simplification needed. (Advisory —
   user confirms at checkpoint.)
2. **Moonflowers-bloom-in-moonlight (p10): Acceptable.** The trembling-bud reaction is
   an immediate causal cue, not folklore reliance. Keep.
3. **Stir precision, exactly 5 CCW (p14): Acceptable for the no-tutorial baseline,**
   given infinite retries and zero ingredient loss. One genuine weakness: the gray
   fizzle is identical for every failure mode (wrong flame vs wrong direction vs wrong
   count), so a player who misreads *one* parameter gets no differential feedback across
   a 3×2×N space. Advisory: user may ask the Designer for mildly differentiated failure
   feedback (e.g., flame-related fizzle at the fire pit vs stir-related fizzle at the
   surface). Not required — the pictogram is legible and the space is brute-forceable.
4. **"Freely given" feather (p11): Enough, narrowly.** The peck-refusal must read as a
   categorical *refusal* (crow turns away / guards) rather than a "try again" miss, or
   players will grind the cage. The key's placement in the deepest zone is intentional
   and sound. Advisory to Art/Dev: make the refusal animation terminal in tone.
5. **No numeric-code lock: Fine.** Roman-numeral ordering in p01 already scratches the
   "code entry" itch; a digit lock would be theme-dissonant here. User's call for
   series-wide variety planning, not a validation concern.
6. **Night-sky consistency: Not a logic defect — forward to Art Director.** Two
   constraints to record in the style guide: (a) the same clear night sky (moon + Orion)
   must be visible from both z1 and z2 windows; (b) the moon must plausibly sit high
   enough to feed the *vertical* cellar shaft. Neither affects solvability; the triptych
   depicts three *different* nights, so the live sky's moon phase cannot contradict p02.

---

## 10. Additional advisories (non-blocking)

- **A1 (Required Fix 1, restated):** Correct `example_ordering_A` (p04 listed before its
  prerequisite p05; free pickups omitted). Route to Designer.
- **A2 (Required Fix 2, restated):** Specify `beam-at-alcove` as a latched *condition*
  (detent-3 AND moonbeam-on) regardless of action order. Route to Designer/Developer.
- **A3:** The brass feed cup is a plausible mis-pour target for the filled phial despite
  the graph's "no mis-spend target exists" claim. Covered by the cauldron-refill
  invariant either way; Developer should either block the pour or wire the refill.
- **A4:** The zodiac-wheel decoy page shares a star theme with the astrolabe; some
  players will cross-reference it against the six plates. This is time-cost only (the
  window is the real key), but the Blind Playtester should watch for it.
- **A5:** p02's waxing/waning mirrored silhouettes put a hard legibility requirement on
  art: dial embossing must render orientation unmistakably at close-up on iPhone-size
  screens, not just iPad. Already listed in `visually_necessary_elements`; flagging it
  as load-bearing.
- **A6:** Edge list omits `z2-workshop → p04` (present in the node's `requires`) and
  containment edges for the z1 pickups (poker, rusted key). Node-level data is
  authoritative and correct; harmonize the edge list for tooling that consumes it.

---

## 11. Verdict

| Gate | Result |
|---|---|
| Solvability | **PASS** |
| Soft-locks | **PASS** (none, incl. mistake paths) |
| Zone-unlock integrity | **PASS** |
| Path consistency | **PASS** (Fix 1 & 2 to spec text) |
| Real-world-knowledge fairness | **PASS** (2 advisories for user ruling) |
| Color-blind safety (mandatory) | **PASS** |
| Red herrings | **PASS** |
| **Critical findings** | **0** |
| **Advisory findings** | 6 (incl. 2 required spec fixes) |
| **Official difficulty (ledger)** | **6.0 / 10** (z1: 5.0, z2: 6.0, z3: 4.0, z4: 5.0) |

The level design is logically sound and cleared for the user checkpoint (pipeline
step 4). The two required fixes are spec-text corrections for the Designer, not design
changes, and should be applied before the Blind Playtester stage consumes the graph.

---
---

# Rev 1.3 validation — Clue-gating re-validation

**Validator:** Puzzle Logic Validator
**Input:** `puzzle-graph.json` spec_revision 1.3 (clue-gating policy block, per-node
`clue_gate` fields, `viewed_when` clue fields, `clue_gate` edges, developer_notes D6/D7,
new anti-softlock invariant, revision_notes). Re-validation of previously-approved rev
1.2 (official 6.0). Scope: what rev 1.3 changed. All rev-1.2 findings above still hold.
**Date:** 2026-07-07

## VERDICT: PASS — CRITICAL FINDINGS: 0. Cleared for Developer implementation of gating.

**Developer: this is a rev-1.3 PASS. You may implement clue-gating.** No required fixes
block implementation. One binding implementation constraint (IC-1, below, restating D6
rule (b)) and one binding constraint (IC-2, restating D7 persistence) MUST be honored or
they become soft-lock/lost-progress vectors — but they are already specified in D6/D7;
IC-1/IC-2 are confirmations, not new work. No hard-blocks. Two rev-1.2 required fixes
(Fix 1 example-ordering A text; Fix 2 beam-at-alcove-as-condition) remain open from the
prior report and are UNAFFECTED by rev 1.3 — still Advisory, still Designer/Developer
spec-text items, do not block gating implementation.

### Binding implementation constraints (both already in D6/D7 — confirmed, not new)

- **IC-1 (D6 rule b — stale-correct-input re-evaluation):** every gated puzzle MUST
  re-evaluate (gate AND solution) on entry into its close-up view, not only on an
  input-change/attempt event. Without rule (b), the two stale cases (p02 dials left on
  the correct phases, p03 pointer left on plate-2) would require a pointless input wiggle
  to resolve after the clue is finally viewed — not a soft-lock (the wiggle always exists)
  but a confusing near-miss. p01 and p14 have no stale case (see D6 analysis below), so
  IC-1 is load-bearing specifically for p02 and p03. Confirmed sound; implement as D6
  states.
- **IC-2 (D7 — persistence across save/restore):** the nine clue-viewed booleans MUST be
  saved and never cleared on restore. A restore that re-locked a gate whose clue was
  already viewed would be a lost-progress case (the player would face a gate that reads as
  a wrong-answer bug on a value they legitimately earned). Confirmed sound; implement as
  D7 states.

---

## R1.3-1. No soft-lock introduced by gating — PASS

I verified the Designer's central claim ("every gating clue sits in z1 or the gated
puzzle's own zone, and zones never re-lock") node-by-node:

| Gated puzzle | Puzzle zone | Required clue-views | Clue location(s) | All clues reachable at/before puzzle? |
|---|---|---|---|---|
| p01-rune-door | z1 (start) | clu-mark-air/fire/earth/water + clu-grimoire-elements | all z1 (bellows, lintel, flowerpot, windowsill, grimoire) | **Yes** — all in the always-open start zone |
| p02-moon-trapdoor | z1 (start) | clu-triptych | z1 study wall | **Yes** — same zone as puzzle |
| p03-astrolabe-orion | z2 | clu-window-orion | z2 v-cabinet window (same view as astrolabe) | **Yes** — own zone, literally same view |
| p04-cabinet-sun-moon | z2 | clu-slot-shapes | z2 cabinet close-up OR z1 grimoire page B | **Yes** — self-satisfying via the cabinet close-up the placement itself requires |
| p14-brew | z2 | clu-recipe-page | z1 grimoire (bookmarked page) | **Yes** — start zone, always reachable |

Every gating clue is located either in **z1 (start zone, `unlock: null`, never gated,
never re-locks)** or in the **gated puzzle's own zone** (which the player is by definition
standing in to attempt the puzzle). No gate references a clue in a *sibling* branch zone
or a *downstream* zone, so no gate can be blocked by not-yet-unlocked geography. Clue
viewing is a free, repeatable, cost-free action, and no zone in this level ever re-locks
(verified: every zone `unlock` is a monotonic one-way condition; no node clears a
zone-unlocked flag). Therefore a gated puzzle's gate is satisfiable in every state in
which the puzzle is itself reachable.

**Because clue-viewed flags are modeled as ordinary satisfiable requirements (not
step-order tracking), gating cannot reorder the branch structure.** Rev 1.2's branch
order-freedom is preserved: the two mid-game branches remain interleavable, and the
`cond-beam-at-alcove` order-free contract is untouched (no gate was added to p08/p09/p10).

**Example orderings A, B, C-mirror-first — all three re-verified PASS.** I traced each of
the three orderings in `solve_path_notes` with the inserted `view ...` steps:

- **Ordering A** opens the *cellar* branch first (view triptych → p02 → cellar work →
  p11), then does p01 after viewing the four marks + page A, then the workshop branch
  (view Orion → p03 → p05 → p04-self-satisfying), then the light/bloom chain, then views
  the recipe page before p14. Every gate's clue precedes its puzzle. **PASS.** (Note: the
  rev-1.3 annotated ordering A also silently corrects the rev-1.2 Fix-1 defect — it now
  places p05 before p04 and includes the poker/spoon pickups. Good; the annotated A is
  now internally valid, which partially resolves prior Fix 1 for ordering A. Ordering B's
  and C's pickups are likewise present.)
- **Ordering B** opens the *workshop* branch first. p01 is gated behind the four marks +
  page A (all viewed in the "view clu-mark-... + grimoire page A" step immediately
  before p01). p03 behind Orion view. p04 self-satisfied. p02 behind triptych view. p14
  behind recipe view. **PASS.**
- **Ordering C (mirror-first)** exercises the order-free beam condition: p09 is set to
  detent-3 *before* p08 opens the shutter. p09 is **ungated** (correctly — see R1.3-5),
  so the mirror-first move is unobstructed. All gated puzzles (p01, p02, p03, p04, p14)
  have their clue-view steps inserted ahead of them, and the note "z1 remains freely
  reachable — zones never re-lock" is correct: the player returns to z1 to view the four
  marks + page A after having entered the cellar, and z1 is still open. **PASS.**

**No new soft-lock, dead-end, or unreachable state is introduced by gating.** A gated
attempt consumes nothing (p14's gated resolve returns all three ingredients intact per
the existing p14 invariant; p01/p02/p03/p04 gated attempts reset/pop-back exactly as a
wrong attempt does), so no gated attempt can destroy a resource. The clue always remains
viewable. Confirmed against the mistake-path table in section 2 above — gating adds no new
mistake that strands the player.

## R1.3-2. Gate satisfiability (new anti-softlock invariant) — PASS

The new invariant (anti_softlock_invariants[7]) states: *"Every clue_gate references only
clues located in the start zone (z1) or in the gated puzzle's own zone; zones never
re-lock and clue viewing is a free, repeatable, cost-free action — so whenever a gated
puzzle is reachable, its gate is satisfiable."*

I independently confirm this invariant is **true as stated** and is **sufficient** to
guarantee no permanent block:

1. **Location claim verified** — the R1.3-1 table above confirms all nine gating clues
   are in z1 or the puzzle's own zone. No counterexample.
2. **Never-re-lock claim verified** — no node in the graph clears any zone-unlocked or
   clue-viewed flag (D7 explicitly: "never cleared"). Monotonic state.
3. **Free/repeatable claim verified** — every `viewed_when` is "close-up displayed";
   `viewed_definition` requires no dwell, tap, comprehension, or timer. Displaying a
   close-up is always available for an in-scene element in an open zone.

No gated puzzle is permanently blockable. **Gate satisfiability: PASS.**

## R1.3-3. D6 (stale-correct-input) & D7 (persistence) — SOUND, PASS

**D6 — no stuck state, no lost-progress case.** I evaluated each gated puzzle for a
"correct-but-gated value left in place" scenario:

| Puzzle | Can a correct value persist while gated? | Resolves how? | Stuck / lost progress? |
|---|---|---|---|
| p01 | **No** — tiles self-reset on every completed 4-press (D6, gate_behavior). There is no persistent "correct sequence left standing" state. | Player simply re-enters AIR-FIRE-EARTH-WATER after viewing clues. | No |
| p02 | **Yes** — dials retain position; player may set waxing-crescent/full/waning-gibbous while gated. | D6 rule (b): on close-up entry after triptych is viewed, gate+solution re-evaluate and the trapdoor opens with no wiggle. | No (IC-1 makes this clean) |
| p03 | **Yes** — pointer may sit on plate-2 while gated. | D6 rule (b): drawer springs open on close-up entry after the window is viewed. | No (IC-1) |
| p04 | **No practical case** — seating the item *requires* the cabinet close-up, which self-satisfies the gate at the same moment; the gate is effectively never unsatisfied at the point of a correct placement. | Item seats normally. | No |
| p14 | **No** — resolve (ladle release) is an explicit act and a failed/gated resolve fully resets the pot and returns all ingredients. No persistent "correct brew left standing" state. | Player re-resolves after viewing the recipe; nothing consumed. | No |

The single accepted cost (documented in D6 and the 2026-07-07 decision) is that in the
p02/p03 stale cases a value that previously read as "wrong" silently works on return. I
concur this is acceptable and, critically, is **not a lost-progress or stuck case**: the
player loses nothing and the puzzle completes on the next natural interaction (view the
clue, return to the puzzle). It cannot strand anyone. **D6: sound.**

**D7 — persistence sound.** Nine clue-viewed booleans, set on first view, never cleared,
saved alongside requirement flags. A save/restore mid-level cannot re-lock a gate whose
clue was viewed (IC-2). The multi-instance clu-slot-shapes correctly uses a single shared
flag (either instance sets it), which matches the p04 self-satisfying logic and cannot
desync. Because the flags are ordinary satisfiable requirements, they introduce no
step-order tracking (verified against the state_model note). **D7: sound.**

One confirmation for the Developer, not a fix: **IC-2 is load-bearing.** If restore
re-locked a viewed gate, a player who legitimately solved (e.g.) p03 pre-save, saved
mid-solve with the pointer on plate-2 and the window already viewed, then restored, would
hit a gate on an earned value that reads as a bug. D7 already forbids this; just implement
it exactly.

## R1.3-4. Rulings on the three flagged judgment calls

### Flag 1 — Page A (clu-grimoire-elements) in p01's required gate: **ADVISORY. I side with the Designer's recommendation: DEMOTE page A to optional. Surface to the user for the decision; either choice is solvable and soft-lock-free.**

This is the one genuine false-block vector in rev 1.3, and my independent analysis
confirms the Designer's read:

- **The false-block is real.** Each of the four rune marks pairs its element glyph *with*
  its press-order Roman numeral in close-up. The door tiles display those *same* glyphs.
  A player who finds all four marks and reads the numerals (I–IV, "clearly fair," with the
  clock ring as backup) can derive the full ordered sequence AIR-FIRE-EARTH-WATER by pure
  glyph-matching + numeral ordering — **with zero reference to page A.** Page A only maps
  runes to *pictograms* (flame/wave/cloud/mountain), which this player never needed.
  Requiring page A therefore blocks a fully-earned correct answer with a "wrong" knock,
  and — because of the (correct) no_tell_rule — the player has no way to distinguish
  "gated" from "wrong" and will read it as a bug. This directly reintroduces an F-012-class
  frustration (a correct deduction refused), the exact failure the revision exists to cure,
  just relocated from "solved too early" to "solved correctly but refused."
- **The information-carriage test — which is the whole justification for gating (see the
  no_tell_rule's own stated mitigation: "gating ONLY on clues that carry the code's actual
  information") — page A FAILS.** The four marks carry the entire code. Page A is
  corroborative, not necessary. Gating on it violates the revision's own stated design
  principle.
- **Counter-consideration (why it's Advisory, not a required fix):** page A is on the
  *natural* solve path — most players open the grimoire — so in practice the gate is
  usually pre-satisfied, and F-012's own player did have the grimoire available. Keeping
  page A in is not *unsolvable* (the clue is always reachable in z1). So this is a
  fairness/false-block judgment, not a solvability defect → **Advisory severity, user
  decides.** But my recommendation is unambiguous: **gate p01 on the four marks only;
  page A optional.** It is a one-line change (`required_viewed` drops
  clu-grimoire-elements; move it to `optional_not_required`), removes the only false-block
  in the revision, and costs the intended player nothing.
- **Developer note:** this ruling does NOT block implementation. Implement p01's gate as
  the four marks required and page A required *pending the user's checkpoint ruling* (the
  current spec state), OR, if the user rules before you reach p01, as four-marks-only. The
  edge `clu-grimoire-elements → p01 (clue_gate)` is already tagged FLAGGED. Wire it so the
  required/optional status of page A is a single config flag, per the Designer's "one-line
  change either way."

### Flag 2 — clu-clock-numerals excluded from p01's gate: **CONCUR. Keep it excluded (optional/backup reference only). No change needed.**

Correct call. Requiring the clock close-up would (a) add a false-block vector for the
majority who read I–IV directly off the marks without needing the ring, and (b) gate on a
clue that is a *redundant backup decoder*, not a carrier of unique code information — the
numerals are already present on each mark. Roman numerals I–IV sit at the "clearly fair"
end of the knowledge register (section 5), so no player is entitled to the ring as a
prerequisite. Excluding it is consistent with the same information-carriage principle that
argues *against* page A in Flag 1. Note the internal consistency: if you keep page A in
(Flag 1) but exclude the numeral ring, you are gating on a pictogram decoder the player
may not need while *not* gating on a numeral decoder the player may not need — an asymmetry
that further supports demoting page A. **PASS, no action.**

### Flag 3 — p12 (file + spoon) left ungated: **CONCUR. Keep it ungated. No change needed.**

Correct call, on two independent grounds:

1. **It's experimentation, not code entry.** Combining two held tools (file on soft metal)
   is exactly the tactile poking-around the genre rewards, and the spoon's crescent
   hallmark independently identifies it as silver — the recipe page is motivating flavor,
   not the sole information carrier. Gating it would punish a player who reasons "file +
   soft metal = shavings" unaided, with no anti-spoiler payoff.
2. **Containment closes the spoiler loophole.** Even a player who files shavings with no
   idea why gains nothing exploitable: `itm-shavings` is inert until **p14, which IS gated
   on the recipe page.** So the recipe knowledge is still enforced at the true code-entry
   chokepoint; nothing leaks past the system. The same containment argument correctly
   covers ungated p13 (paste inert until p14). **PASS, no action.**

**Consistency check across the three flags:** the Designer's line is coherent — gate only
where a puzzle *accepts a code-like value* AND the gated clue *carries unique code
information*. p12/p13 fail the first test (physical acts, contained downstream); the clock
ring and page A fail the second test (redundant decoders). The only place the current spec
deviates from its own stated principle is keeping page A in p01's gate (Flag 1), which is
exactly why I flag that one for change and concur on the other two.

## R1.3-5. Color-blind safety, fixed solution values, D1–D5, prior anti-softlock invariants — INTACT, PASS

Verified rev 1.3 touched none of these:

- **Color-blind safety:** the `colorblind_safety` block and all `visually_necessary_elements`
  are byte-for-byte the rev-1.2 content; `rev_1_3_note` explicitly confirms "Clue-gating
  adds NO new visual states." The no_tell_rule *reinforces* CB-safety by reusing existing
  failure presentations (no new color-coded "gated" indicator was introduced — which is
  also why a color-only "not yet" tell was correctly rejected). **Hard gate: PASS.**
- **Fixed solution values:** unchanged. p01 AIR-FIRE-EARTH-WATER; p02
  waxing-crescent/full/waning-gibbous; p03 plate-2; p04 ring→sun/coin→moon; p14 flame-3 +
  {paste,shavings,feather} + CCW×5. No per-playthrough randomization introduced (gating is
  a static requirement, principle 3 intact). **PASS.**
- **D1–D5:** all present verbatim, semantics unchanged (D1 feed-cup draught BLOCK; D2
  beam-condition; D3 cage-reach refusal tone; D4 feed-cup universal refusal; D5 clock
  one-shot). D6/D7 are strictly additive. **PASS.**
- **Prior anti-softlock invariants:** the first seven invariants are unchanged; the eighth
  (gating) is additive and verified in R1.3-2. **PASS.**
- **Rev-1.2 required fixes 1 & 2:** unchanged by rev 1.3; still open as Advisory spec-text
  items (ordering-A now annotated-correct in the 1.3 orderings, which resolves Fix 1 for
  ordering A specifically; Fix 2 beam-as-condition is codified in derived_conditions +ID2
  and remains a Developer implementation invariant). Do not re-open at this stage.

## R1.3-6. Difficulty re-score — 6.0 / 10 HOLDS (per-zone unchanged)

Official ledger score for rev 1.3: **6.0 / 10** — unchanged from rev 1.2. Per-zone:
**z1 5.0, z2 6.0, z3 4.0, z4 5.0** — unchanged.

Rationale for holding at 6.0 rather than +0.25:

- Gating changes **nothing on the intended deduction path**. Every gating clue lies on the
  natural solve route and (per the playtest traces) was viewed before its puzzle. For a
  player solving as designed, the game is behaviorally identical to rev 1.2 — no added
  reasoning, no added steps, no added friction.
- What gating *removes* is difficulty-**reducing** shortcuts: the six-tap brute force on
  p03 and the 1-in-512 lucky spin on p02. Closing an unintended trivial shortcut nudges
  *effective* difficulty marginally **up** for a shortcut-seeker, but does not raise the
  intended-path difficulty that the ledger score measures.
- The only added cost is at most one extra failure cycle in the rare p02/p03 stale-input
  edge case (D6), which is negligible and offset by the anti-frustration invariants
  (nothing consumed, no lockout).

The Designer's +0.0..+0.25 band is defensible, but the increment lands below the 0.5
rounding granularity of the ledger and does not shift any per-zone score. **Official
rev-1.3 score: 6.0 / 10, holding.** Blind-solve estimate unchanged (60–100 min); note the
gating does not require a *re-run* of the Blind Playtester for score purposes, though the
Producer may still route rev 1.3 through a blind pass to confirm the no_tell refusal does
not read as a bug in practice (esp. under Flag 1 if page A is kept).

**Ledger note:** no new mechanic added; `mechanics_used_for_ledger` is unchanged.
Clue-gating is a *meta-rule on existing mechanics*, not a new puzzle mechanic, so it does
not affect Level 2 mechanic-repetition planning.

## R1.3 verdict table

| Gate (rev 1.3 scope) | Result |
|---|---|
| No soft-lock introduced by gating (all gates satisfiable pre-puzzle; orderings A/B/C hold) | **PASS** |
| Gate satisfiability invariant | **PASS** |
| D6 stale-correct-input (no stuck / lost-progress state) | **PASS** (sound; IC-1 binding) |
| D7 clue-viewed persistence across save/restore | **PASS** (sound; IC-2 binding) |
| Flag 1 — page A in p01 gate | **ADVISORY — recommend DEMOTE to optional; user decides** |
| Flag 2 — numeral ring excluded | **CONCUR — keep excluded** |
| Flag 3 — p12 ungated | **CONCUR — keep ungated** |
| Color-blind safety intact | **PASS** (mandatory gate) |
| Fixed solution values / D1–D5 / prior invariants intact | **PASS** |
| **Critical findings (rev 1.3)** | **0** |
| **Required fixes blocking Developer** | **0** |
| **Official difficulty (rev 1.3)** | **6.0 / 10** (z1 5.0, z2 6.0, z3 4.0, z4 5.0) — holds |

**Rev 1.3 is cleared for Developer implementation of clue-gating.** The single Advisory
(Flag 1, page A) is a user-checkpoint decision, not an implementation blocker: implement
page A's required/optional status as a single config flag so the ruling can be applied
without rework.

---
---

# Round-6 light re-validation, 2026-07-14

**Validator:** Puzzle Logic Validator
**Scope:** LIGHT graph-sync pass only (not a full re-validation). The Round-6 fix build
(branch `build-12-round6-fixes`; R6-003 / R6-011 / R6-009, all CI-green, QA GO,
user-approved) left `puzzle-graph.json` stale in two places, found by the Documentation
agent. This section records the two graph fixes and the three targeted re-checks.

## VERDICT: PASS — all three checks PASS. NO solution value changed.

## Graph fixes applied (drift sync to the shipped build)

1. **itm-rusted-key node (R6-003 — decoy key is inspect-only in the shipped code):**
   - OLD: `"obtained_by": "pickup", "uses": [], "red_herring": true`
   - NEW: `"obtained_by": "none", "collectible": false, "uses": [], "red_herring": true,`
     plus a `"notes"` field: *"R6-003 graph sync (2026-07-14): INSPECT-ONLY in the shipped
     build — the key never enters inventory; it stays on its hook and misleads visually
     in-scene only (close-up shows the snapped plain bit). The real cage key remains
     itm-cage-key from the z4 alcove statue."*
   - Schema note: the graph had no prior convention for a non-collectible scenery item
     (this is its first), so the explicit `"obtained_by": "none"` + `"collectible": false`
     pair with an item-level `"notes"` field (already used on itm-phial-draught) was used
     rather than inventing new structure.
2. **p11-cage-unlock clue text (stale drag interaction):**
   - OLD: *"star keyhole visibly matches star key bit (and visibly rejects itm-rusted-key's
     plain bit)"* — described inserting/trying the rusted key, an interaction that can no
     longer occur since the key cannot be held.
   - NEW: *"star keyhole visibly matches star key bit (the rusted decoy key misleads
     visually in-scene only: it is inspect-only per R6-003, never held, and its close-up
     shows a snapped plain bit that plainly cannot match the star keyhole)"*.

All other graph content is byte-for-byte unchanged; JSON validity preserved.

## Re-check results

| Check | Result | Detail |
|---|---|---|
| (a) No solve path / dependency edge / `uses` list requires or consumes itm-rusted-key | **PASS** | Node `uses` is `[]`; no `requires`/`yields`/`requires_state`/`requires_condition`/`clue_gate` edge references it; no puzzle `requires` list names it; no example ordering includes it. Its only remaining references are the item node itself, the rewritten p11 clue text (visual mismatch only), one `z1-cabin → itm-rusted-key` `contains` edge (scene containment — harmless and accurate, the key is physically in z1), and the rh-rusted-key red-herring entry. |
| (b) Recipe/brew consistency (R6-011) | **PASS** | p14 `solution_fixed` remains `flame_stage: 3`, stir `counterclockwise × 5` — unchanged. All clue references agree with the redrawn 5-dot CCW page art: clu-recipe-page content ("flame pictogram with numeral III; spiral with arrowhead pointing counterclockwise and five dots"), p14 derivation ("flame pictogram + III; spiral with CCW arrowhead and five dots"), p14 gate rationale ("flame III, CCW x5 stir"), and visually_necessary_elements ("flame+III, CCW 5-dot spiral"). No contradiction anywhere in the graph. |
| (c) Poker anti-softlock invariants (R6-009) | **PASS** | itm-poker `uses` still lists BOTH `p05-ash-sift` and `p06-barrel-pry`; both `requires` edges present; no ordering constraint exists between p05 and p06 (p05 requires only the poker, p06 requires poker + z3 — either order valid, per orderings A/B/C); anti_softlock_invariants[1] ("itm-poker … reusable and never consumed") intact. Consistent with the shipped ItemLifecycle behavior (poker retained while either use is unsatisfied) verified GO in QA R6-009. |

## Explicit statement

**No solution value changed** in this pass or in the Round-6 build as reflected here:
p01 AIR-FIRE-EARTH-WATER, p02 waxing-crescent/full/waning-gibbous, p03 plate-2,
p04 ring→sun/coin→moon, p14 flame-3 + {paste, shavings, feather} + CCW×5 all stand
verbatim. Zones, edges, clue gates, difficulty score (6.0/10; z1 5.0, z2 6.0, z3 4.0,
z4 5.0), and all anti-softlock invariants are untouched.

## Advisory (non-blocking, historical-text only)

- The rh-rusted-key entry ("Tempts use on the front door and cage") and the section-2
  mistake-path row ("Rusted key tried on cage / front door") describe pre-R6-003 behavior
  in which the key could be held and tried. Post-R6-003 the temptation is visual-only.
  Both texts were intentionally left untouched (outside this pass's two-edit scope; the
  report rows are historical record). If the Designer revises the red-herring blurb in a
  future graph revision, route it via the Producer — Advisory, not a correctness defect.
