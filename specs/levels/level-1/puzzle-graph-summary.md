# Level 1 — The Wizard's Cabin — Design Summary

*(Reflects puzzle-graph.json spec revision 1.2: Validator fixes + user-approved playtest
tweaks R1/R2 applied. No puzzle, solution value, zone, or item has changed since the
original checkpoint review.)*

**Framing line (only text in the level):** *"The wizard is gone. The crow remains."*

**Premise:** You wake in an abandoned wizard's cabin at night, deep in the woods. The front
door's bolt is sealed under living thorn-vines, with a crow's-beak-shaped rune basin set
into the wood. A crow watches from a cage by the window. To leave, you must brew the
wizard's Unbinding Draught and feed it to the door — and one ingredient can only be
*given*, not taken.

---

## Zone map

```
z1 Main Cabin Room (start)
 ├── rune-locked inner door ──► z2 Potion Workshop
 └── rug ► trapdoor (moon-dial lock) ──► z3 Hidden Cellar   [hidden zone]
                                          └── counterweight shelf ──► z4 Walled Alcove   [nested hidden zone]
```

- **z1 Main Cabin Room** — 3 views: hearth (fireplace, poker, clock, rug), study (desk,
  grimoire, triptych paintings, workshop door), entry (sealed front door, rune basin,
  caged crow, window).
- **z2 Potion Workshop** — unlocks when the four-rune press-lock is solved. Cauldron,
  bellows, mortar, ingredient cabinet, astrolabe, potion shelf, Orion window.
- **z3 Hidden Cellar** — hidden under the rug; trapdoor opens on a three-dial moon-phase
  lock. Barrel, silver spoon drawer, light-shaft winch, tilting mirror, sliding shelf.
- **z4 Walled Alcove** — nested hidden zone *inside* the hidden cellar; the shelf slides
  aside when an iron weight is hung on its pulley hook. Moonflower planter, crow statue
  holding the cage key.

## Puzzle dependency walk-through

**Opening fan-out (z1):** The grimoire on the desk is browsable from the start — element
rune chart, a sun/moon margin note, and a recipe page bookmarked with a black feather
(foreshadowing). Two independent locks lead out of z1:

1. **Workshop rune lock (p01)** — four element runes (air/fire/earth/water) are hidden
   around the room, each scratched beside a Roman numeral I–IV (bellows handle, hearth
   lintel, flowerpot, windowsill). Grimoire page A maps runes to pictograms; the mantel
   clock is the in-room Roman-numeral reference. **Fixed solution: AIR, FIRE, EARTH,
   WATER.**
2. **Moon-phase trapdoor (p02)** — move the rug, find a trapdoor with three dials of
   eight embossed moon-phase silhouettes. The study triptych (same tree, three nights)
   encodes it: crow count in each painting (1/2/3) = dial index, moon shape = value.
   Waxing/waning shapes are mirrored, so orientation precision matters. **Fixed solution:
   waxing crescent, full, waning gibbous.**

**Workshop branch:** Astrolabe with six star-pattern plates; the window sky shows Orion
(belt prominent). Pointing to the Orion plate (**plate-2**) opens the drawer: **silver
coin + winch crank**. The ingredient cabinet has a sun slot and a moon slot — gold ring
(sifted from hearth ash with the poker) in the sun slot, crescent-stamped coin in the
moon slot — yielding **metal file + empty phial**.

**Cellar branch:** Pry the barrel with the poker → **iron weight** → hang on hook →
shelf slides → **alcove (z4)** with the **cage key** and closed moonflower buds. Fit the
crank (from the workshop) to the winch → shutter opens → moonbeam. Rotate the mirror to
its third detent (worn scratch marks on the floor) → beam enters the alcove →
**moonflowers bloom** → pick a blossom. A silver spoon sits in a cellar drawer.
(The mirror and shutter can be set in either order — the beam condition latches whenever
both hold.)

**Convergence — the recipe (all pictographic):**
- Moonflower blossom → grind in the workbench mortar → **paste**.
- File + silver spoon → **silver shavings**.
- **Black feather, freely given**: reaching into the cage — or offering *any* item at the
  brass feed cup — earns the same categorical refusal (the crow snaps once, turns its
  back, and guards its wing; identical on every repeat). Feeding is not a path. Unlock
  the cage with the star-bit key instead: the freed crow flies to the rafters and drops
  one feather. (It later perches over the door basin — a silent hint.)
- **Brew (p14):** flame at stage III (bellows pumps cycle 1→2→3→1; stage shown by flame
  height + lit rim numeral), add all three ingredients **in any order**, stir the ladle
  **counterclockwise exactly 5 turns** (spiral pictogram with arrowhead + five dots).
  Failure = gray fizzle; all ingredients float back intact. No loss, infinite retries.

**Endgame:** Fill the phial from the cauldron → pour into the door's rune basin → vines
wither → slide the bolt → the crow flies out ahead of you. **Win.**

## Multiple solve paths

The two mid-game branches (workshop / cellar) are openable in either order and
interleave freely; they cross-link twice (crank: workshop→cellar; file+spoon:
workshop+cellar). State is tracked purely as satisfied requirements plus derived
conditions — the graph JSON includes three example valid orderings (one exercising the
mirror-before-shutter path), and ingredient order in the brew is explicitly order-free.
Only genuine code values (rune sequence, dial shapes, stir parameters) are ordered, as
solution *values*, not solve-path constraints.

## Red herrings and defused theory magnets

1. **Rusted bent key** by the door — fits nothing; close-up shows a snapped plain bit
   (the cage keyhole is visibly star-shaped, so it's fair).
2. **Potion shelf** in the workshop — tempting shortcut potions, wax-fused shut,
   unrelated pictogram labels. Differentiated by bottle *shape* + label, never color.
3. **Mantel clock** — movable hands; the *first* XII setting pops a crude carved toy
   crow once (dry wooden clack, charm beat, no reward); afterwards the little door hangs
   ajar showing the toy tipped over on a limp broken spring — visibly spent flavor, not
   a mechanism. The toy is round-bodied and paint-chipped, clearly not the live crow.
   The numeral ring still genuinely supports p01, so time spent here isn't wasted.
   *(De-escalated per playtest R2: the old always-repeating pop taught players "the
   clock matters to the crow" and cost 5–8 min in revisits.)*
4. **Brass feed cup** — the level's biggest theory magnet in blind play ("feed the crow
   to get the feather"). Defused per playtest R1: every item offered at the cup triggers
   the crow's terminal refusal, so the feeding theory dies on first contact instead of
   sustaining a 5–15 minute food hunt. (The draught-specific mis-pour case keeps its own
   developer ruling, D1 in the JSON.)
5. **Grimoire decoy pages** — zodiac wheel and bird-anatomy spread invite over-reading;
   encode nothing (the bird diagram softly foreshadows the crow).

## Difficulty rationale

Designer estimate 6.5/10; **official Validator score 6.0/10** (z1 5.0, z2 6.0, z3 4.0,
z4 5.0). First level, but genuinely challenging per project rules: 17 puzzle nodes,
4 zones with two *nested* hidden zones, two cross-linked parallel branches, a
mirrored-shape precision dial code, a multi-parameter brewing procedure, and the red
herrings above. Balanced against frustration by: no timers, no lockouts, no consumable
ever lost to failure (invariants listed in the JSON), and every deduction verifiable
in-room. Blind solve estimate: **60–100 minutes** for a first-time player
(playtest-calibrated; the original 45–75 designer estimate is superseded).

## Flagged judgment calls — status after Validator + Playtest passes

1. **Alchemical sun=gold / moon=silver (p04).** Validator: pass-advisory, keep. Playtest:
   confirmed solvable purely by shape fit; the alchemical fact was never needed.
2. **"Moonflowers bloom in moonlight" (p10).** Validator: acceptable — the trembling-bud
   reaction is a live causal cue. Playtest rated the bloom the level's best wordless
   progress cue.
3. **Stir precision (p14): exactly 5 counterclockwise turns.** Validator: acceptable for
   a no-tutorial baseline given infinite retries. Playtest: procedure fully inferable
   from the pictogram (2–3 failed resolves typical, felt like experimentation). One
   binding art/dev requirement recorded in the JSON (R3): page-spiral orientation and
   in-scene ladle affordance must agree on what "counterclockwise" looks like.
4. **"Freely given" feather beat (p11).** Terminal-refusal treatment now covers both the
   cage reach and the feed cup (R1). Playtest confirmed the refusal tone works and the
   feather's delivery retroactively lands the "given, not taken" idea.
5. **No numeric-code lock anywhere.** Validator: fine; series-wide variety is a ledger
   concern, not a level defect.
6. **Night-sky consistency.** Forwarded to the Art Director: same clear night sky (moon +
   Orion) from both windows; moon plausibly high enough to feed the vertical cellar
   shaft. The triptych depicts three different nights, so the live sky cannot contradict
   p02.

## Real-world-knowledge register

| Fact | Verdict | In-room backup |
|---|---|---|
| Roman numerals I–IV | Clearly fair | Clock face I–XII in-room |
| Orion's Belt pattern | Clearly fair (cited in project brief) | Pure dot-pattern matching suffices |
| Sun=gold, moon=silver | Flagged → Validator pass-advisory; playtest confirmed backup carries it | Shape-fit slots + grimoire margin |
| Moonflowers bloom in moonlight | Flagged-soft → Validator acceptable | Trembling buds + recipe pictogram |
| Waxing vs. waning orientation | Not required — pure shape copying | n/a |

## Color-blind safety

- Moon phases, element runes, star plates: **silhouette/shape only**, no color channel.
- Gold ring vs. silver coin: shape + slot fit + hallmark stamps, never metal color alone.
- Flame stages: height + which embossed rim numeral's ember channel is lit.
- Brew success: spiral **surface pattern** + sheen animation, not a color change alone.
- Potion-shelf herrings: distinct bottle shapes + pictogram labels.

## Visually-necessary elements for the Art Director

The complete per-zone list — including every required hotspot **state variant** (e.g.
trapdoor locked/open, flame stages 0–3, buds closed/trembling/blooming/picked, cage
occupied/open/empty, vines alive/withered/gone, beam none/floor/blocked-on-shelf/
redirected, clock unspent/first-pop/spent, feed-cup refusal animation) — is in
`puzzle-graph.json` under `visually_necessary_elements`. That JSON block is the
authoritative checklist; nothing on it may be dropped or simplified without a flag.
