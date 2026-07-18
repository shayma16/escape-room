# Level 2 — The Clockmaker's Attic — Puzzle Graph Summary (rev 1.2)

_For the user's checkpoint review (checkpoint COMPLETE 2026-07-18 — rulings applied below)._
_Companion to `puzzle-graph.json` (same directory)._
_Rev 1.2: user checkpoint rulings applied — (1) standard IV notation level-wide, IIII beat
removed; (2) Dubai/Burj Khalifa added to the city set, **vault code changed to
VI·X·I·III**; (3) p09 mirrored-dial trap kept, easing valve pre-specced (D9), not
implemented. Rev 1.1 was the Validator ordering-C text fix._

**Framing line:** *All his clocks stopped at six.*

## Theme & mood

A tower clockmaker's attic above the town, in late golden afternoon light. Where Level 1
was "alchemy in a cabin," Level 2's identity is **MECHANISM: the attic itself is a machine
the clockmaker left mid-thought.** Visible linkage rods run from the barred exit door along
the ceiling and into the walls — the door is opened *by* the clock, and restoring the great
tower movement behind the wall IS the level. Every clock in the room stopped at the same
moment (6:00). A gray cat still lives here — the series' quiet living presence, successor
to Level 1's crow.

## Zone map & nested-zone reveal chain

| Zone | Hidden? | Unlocked by |
|---|---|---|
| z1 Main Attic (3 views: bench / master clock & workroom door / stair door & dormer) | start | — |
| z2 Movement Loft (2 views: automaton gear wall / world-clock row) | no (visible locked door) | p01: complete the door's numeral dial |
| z3 Behind the Great Dial (1 rich view) | **HIDDEN** | p06: correct gear train runs the automaton mural to full cycle → wall panel swings open |
| z4 The Clockmaker's Vault | **HIDDEN, nested in z3** (floor hatch under the dial platform) | p07: four-wheel numeric code VI·X·I·III |

Reveal chain: attic → workroom → *(the machine literally opens the wall)* → behind the
tower's great dial → *(numeric code)* → strongroom under the platform. Zones never re-lock.

## Puzzles by zone (mechanic → fixed solution)

### z1 Main Attic (difficulty ~5.0)
- **p01 The numeral-dial door** — scavenge 4 numeral tiles hidden around z1 (II on the
  stove hob, **IV** in the coat pocket, VII in the crate straw, XI on the windowsill) and
  seat them in the door dial's empty sockets (positions 2/4/7/11). Modest trap (rev 1.2,
  replaces the removed IIII beat): a tray under the door offers a loose **VI** tile —
  glyph-order bait for the 4-socket (I-before-V subtracts, I-after-V adds) — disproved by
  the dial's own seated VI at position 6. Wrong tile whir-stalls and pops back. → unlocks
  z2. All numerals level-wide are standard subtractive notation (user ruling).
- **p02 The cat and the mouse** — the cat sleeps on a cushion (something flat beneath it);
  it refuses every offered item with one slow blink. Wind the tin mouse (found in z2) and
  set it down: pounce, chase, cat keeps the mouse and resettles by the exit door. → pocket
  watch B.
- **p03 Dormer floorboard cache** — pocket watch A (coat) has a ⌂ on its case back and a
  single hand frozen on III. At the ⌂ mark by the dormer (engraved 12-notch clock-position
  ring), 3 o'clock points to the third floorboard right → pry with screwdriver → the
  64-tooth **great wheel**. *(Clue-gated on inspecting watch A; boards are otherwise
  uniformly inert — no pixel-hunt, no sweep-pry brute force.)*

### z2 Movement Loft (difficulty ~7.0 — level signature)
- **p04 Chimney brick cache** — watch B (⚙, hand on IX) → 9 o'clock at the chimney's ⚙
  ring → pry brick → **oil can**. Cross-zone loop: mouse (z2) → cat (z1) → watch B → back
  to z2. *(Clue-gated on watch B.)*
- **p05 Free the seized arbor** — oil the gear frame's rusted bearing.
- **p06 The automaton gear train** — the exposed two-stage train: crank pinion XII (12t) →
  wheel on POST A (carrying fixed pinion VIII, 8t) → wheel on POST B → cam driving a
  carved town-automaton mural. Slate in z1: wordless diagram encoding **(A/12) × (B/8) =
  24**, i.e. A×B = 2304. Gear rack {16, 24, 36, 40, 48, 72} + the found 64: unique answer
  **36 × 64** (either post order — both arrangements accepted). The 48 teases 48×48 = 2304,
  but there is only one 48 in the level. Correct ratio: the mural runs one clean cycle and
  the wall panel opens. → unlocks z3. Live feedback: any mounted pair cranks and visibly
  runs too fast/too slow. *(Ratified at checkpoint: arithmetic peak stays; stays ungated.)*
- *(clue scenery)* **World-clock row** (rev 1.2 city set): four dead clocks, all hands
  removed, landmark plates with stamped offsets — **Burj Khalifa +IV** (Dubai,
  user-required), **Big Ben ★** (reference; same star as the z1 master clock), **Fuji
  +IX**, **Liberty −V**.

### z3 Behind the Great Dial (difficulty ~7.5)
- **p07 The four-wheel vault hatch** — **THE NUMERIC-CODE LOCK (standing user directive
  honored).** Four wheels engraved I–XII under pictogram headers (Big Ben ★ / Burj
  Khalifa / Liberty / Fuji — deliberately a *different order* than the z2 row, forcing
  pictogram matching). Master clock stopped at 6:00 (★ reference) + stamped offsets →
  **VI · X · I · III** (6; 6+4=10; 6−5=1; 6+9=15→3 on a 12-hour wheel — the single wrap
  case, ratified). → unlocks z4. *(Clue-gated on viewing both the master clock and the
  clock row. REV 1.2: code changed from VI·VII·I·III when Dubai replaced Paris. Offsets
  are the authentic UTC offsets vs London.)*
- **p08 Oil and wind** — oil the squealing winding drum, then crank the vault's winding
  key until the drive weight rises. → `clock-wound`.
- **p09 Set the hands from behind** — the great dial is translucent and seen from BEHIND:
  numerals visibly mirror-reversed (a mirrored IV reads as a malformed VI). The vault's
  "will return" tag shows the release time **7:20** as a *front* view. Naively copying it
  onto the back view sets the front to 4:40 (the designed trap); the aha is to set the
  **mirror image**. → `hands-at-release` (front = 7:20). *(Clue-gated on inspecting the
  tag. User ruling: trap KEPT for now; a pre-planned overlay-only easing valve is specced
  in developer_notes D9 — a wordless chalk mirror-diagram stageable beside the crank on
  the existing plate — NOT implemented.)*
- **p10 Start the pendulum** — push it. → `pendulum-running`.
- **Derived condition `cond-timelock-release`** = wound ∧ hands-at-7:20 ∧ pendulum —
  order-free AND over three latched/evaluated states; on first TRUE the strike train
  fires, the linkage rods articulate, and the z1 door bar lifts (permanently latched).

### z4 The Clockmaker's Vault (difficulty ~5.0 designer / 3.5 official — reward room)
Winding key, the "will return" tag (release-time clue), and quiet lore (the cat's second
cushion and saucer; an unfinished pocket watch).

- **p11 Exit** — return to z1, bar raised, cat stretches, door opens onto the tower
  stairs; the cat trots out ahead. **WIN.**

## Dependency spine (prose)

Tile scavenge → **p01** → z2. Then three parallel, cross-binding streams: (1) watch A →
dormer cache → great wheel; mouse → cat → watch B → chimney cache → oil can; (2) oil
arbor → **gear train p06** → z3; (3) knowledge: master time (z1) + clock-row offsets (z2)
→ vault code. In z3: **p07** → z4 (key + tag) → endgame trio p08/p09/p10 **in any order**
→ strike → exit. State is pure satisfied-requirement flags + one derived condition; three
example orderings in the JSON exercise pendulum-first and knowledge-first paths.

## Difficulty self-assessment

**Designer estimate 7.0 overall** (z1 5.0 · z2 7.0 · z3 7.5 · z4 5.0); blind-solve
75–120 min (L1: 6.0 official, 60–100 min). **Validator official score at rev 1.1: 6.5**
(z1 5.5 · z2 7.0 · z3 7.0 · z4 3.5) — escalation over L1 judged real and fair. Rev 1.2
deltas for Validator re-verification: p01 eased slightly (IIII trap removed by user
ruling; the VI glyph-order decoy is milder — designer z1 now 5.0), p07 code value changed
with the mechanism intact. Designer expects the official 6.5 to hold or dip at most 0.25.
Escalation still comes from **depth, not obscurity**: two light-arithmetic inference
chains, long dependency chains, heavy cross-zone clue binding, one perceptual inversion.
No pixel-hunting: every cache is anchored by an engraved ring; every code's data is
stamped in-scene.

## Real-world knowledge used (fairness notes)

| Fact | Register | In-room backup |
|---|---|---|
| Roman numerals I–XII, standard subtractive notation incl. IV-vs-VI glyph order (user-requested; notation per rev 1.2 ruling) | clearly fair | 8 seated tiles + every dial in the room; seated VI disproves the tray decoy |
| Clock-face layout (12 top, clockwise) | clearly fair | seated tiles anchor all positions |
| Time zones exist (user-requested) | fair as concept | all offsets stamped in-world; nothing memorized |
| Landmark silhouettes → cities (Big Ben, Burj Khalifa, Liberty, Fuji) | fair AND not required | pictogram-to-pictogram matching suffices |
| 12-hour wrap (15 → 3 o'clock) | mild borderline — RATIFIED (flag #4) | wheel physically only offers I–XII |
| Gear ratios (bigger = slower; stages multiply) | borderline — RATIFIED (flag #2) | slate worked diagram + live speed feedback + bounded trial |
| Mirror reversal behind a translucent dial | inference, not trivia — CONDITIONALLY KEPT (flag #5, D9 valve specced) | reversed numerals in the same close-up as the crank |

## BORDERLINE FLAGS — CHECKPOINT RULINGS (user, 2026-07-18)

1. **IIII convention — OVERRULED.** User prefers standard IV. Applied level-wide (rev
   1.2); the IIII teaching beat is removed. p01 compensated with a modest non-RWK VI
   glyph-order decoy; p01 is slightly easier, accepted.
2. **Gear-ratio arithmetic — RATIFIED.** The arithmetic peak stays as designed.
3. **p06 ungated — RATIFIED.** Stays ungated (mechanical truth).
4. **12-hour wrap — RATIFIED.** Kept as a feature; still exactly one wrap case (Fuji)
   after the rev 1.2 city change.
5. **Mirrored-dial trap — CONDITIONAL KEEP.** Kept exactly as designed; user will judge
   in play. Easing valve pre-specced (D9: overlay-only chalk mirror-diagram beside the
   crank; activating it changes no solution, gate, or failure grammar). Not implemented.
6. **Landmark pictograms — MODIFIED.** Dubai (Burj Khalifa) added per user; Tel Aviv,
   Tehran, Riyadh excluded per user; Paris dropped (designer choice to keep four wheels
   and exactly one wrap case). **Vault code is now VI·X·I·III.**
7. **Pry-sweep no-tell gating — ACCEPTED pending playtest.** Blind Playtester must probe
   the "swept the correct board pre-clue, then inspected the watch, then returned"
   sequence (Validator R1).

## Open design questions

- None blocking. The cat's refusal grammar, mouse no-loss rule, and time-lock keyless-door
  grammar are specified in developer_notes D3/D4/D8; the mirrored-render contract is D1;
  the p09 easing valve is D9 (spec only).

## Visually-necessary elements

The complete per-zone list (with all required states) is in `puzzle-graph.json` →
`visually_necessary_elements`, headed by the rev 1.2 **global numeral rule: standard
subtractive numerals (IV, IX) on every dial, tile, stamp and engraving — no IIII anywhere
in the level.** Headlines for the Art Director: legible numerals at close-up on five
distinct dial types (master clock, door dial, watches, world clocks, mirrored great dial —
the mirrored numerals are load-bearing, and a mirrored IV must crisply read as a malformed
VI per D1); countable gear teeth + stamped counts; the Burj Khalifa needle-spire silhouette
(user-required) among four silhouette-distinct landmark plates; the continuous linkage-rod
line from door to strike train across three zones; the cat's four staging states;
golden-afternoon light with a sunbeam patch (cat) and amber transmitted glow (great dial);
clear staging space beside the z3 setting crank reserved for the D9 easing-valve overlay.
No color-differentiated puzzle elements exist anywhere in the level (see
`colorblind_safety`).
