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
