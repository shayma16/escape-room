# Level 2 — The Clockmaker's Attic — Puzzle Graph Summary (rev 1.0)

_For the user's checkpoint review. Companion to `puzzle-graph.json` (same directory)._

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
| z4 The Clockmaker's Vault | **HIDDEN, nested in z3** (floor hatch under the dial platform) | p07: four-wheel numeric code VI·VII·I·III |

Reveal chain: attic → workroom → *(the machine literally opens the wall)* → behind the
tower's great dial → *(numeric code)* → strongroom under the platform. Zones never re-lock.

## Puzzles by zone (mechanic → fixed solution)

### z1 Main Attic (difficulty ~5.5)
- **p01 The numeral-dial door** — scavenge 4 numeral tiles hidden around z1 (II on the
  stove hob, IIII in the coat pocket, VII in the crate straw, XI on the windowsill) and
  seat them in the door dial's empty sockets (positions 2/4/7/11). Trap: a tray under the
  door offers an **IV** tile, and the dial's own seated IX shows subtractive style — but
  every real clock face in the attic writes four as **IIII**. IV whir-stalls and pops back.
  → unlocks z2.
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
  runs too fast/too slow.
- *(clue scenery)* **World-clock row**: four dead clocks, all hands removed, landmark
  plates with stamped offsets — Eiffel **+I**, Big Ben **★** (reference; same star as the
  z1 master clock), Fuji **+IX**, Liberty **−V**.

### z3 Behind the Great Dial (difficulty ~7.5)
- **p07 The four-wheel vault hatch** — **THE NUMERIC-CODE LOCK (standing user directive
  honored).** Four wheels engraved I–XII under pictogram headers (Big Ben ★ / Eiffel /
  Liberty / Fuji — deliberately a *different order* than the z2 row, forcing pictogram
  matching). Master clock stopped at 6:00 (★ reference) + stamped offsets →
  **VI · VII · I · III** (6; 6+1=7; 6−5=1; 6+9=15→3 on a 12-hour wheel). → unlocks z4.
  *(Clue-gated on viewing both the master clock and the clock row.)*
- **p08 Oil and wind** — oil the squealing winding drum, then crank the vault's winding
  key until the drive weight rises. → `clock-wound`.
- **p09 Set the hands from behind** — the great dial is translucent and seen from BEHIND:
  numerals visibly mirror-reversed. The vault's "will return" tag shows the release time
  **7:20** as a *front* view. Naively copying it onto the back view sets the front to 4:40
  (the designed trap); the aha is to set the **mirror image**. → `hands-at-release`
  (front = 7:20). *(Clue-gated on inspecting the tag.)*
- **p10 Start the pendulum** — push it. → `pendulum-running`.
- **Derived condition `cond-timelock-release`** = wound ∧ hands-at-7:20 ∧ pendulum —
  order-free AND over three lat/states; on first TRUE the strike train fires, the linkage
  rods articulate, and the z1 door bar lifts (permanently latched).

### z4 The Clockmaker's Vault (difficulty ~5.0 — reward room)
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

**Designer estimate 7.0 overall** (z1 5.5 · z2 7.0 · z3 7.5 · z4 5.0); blind-solve
75–120 min (L1: 6.0 official, 60–100 min). Escalation comes from **depth, not obscurity**:
two light-arithmetic inference chains (ratio product; offset arithmetic with 12-hour
wrap), longer dependency chains (mouse→cat→watch→cache→oil→arbor→train→zone), heavier
cross-zone clue binding, and one perceptual inversion (mirrored dial) with a designed trap
answer. No pixel-hunting: every cache is anchored by an engraved ring; every code's data
is stamped in-scene. Target band 6.5–7.5: hit. Validator assigns the official score.

## Real-world knowledge used (fairness notes)

| Fact | Register | In-room backup |
|---|---|---|
| Roman numerals I–XII (user-requested) | clearly fair | 8 seated tiles + every dial in the room |
| Clock-face layout (12 top, clockwise) | clearly fair | seated tiles anchor all positions |
| Dials write 4 as IIII (not IV) | **borderline — see flags** | three in-room faces show IIII; wrong tile costs one pop-back |
| Time zones exist (user-requested) | fair as concept | all offsets stamped in-world; nothing memorized |
| Landmark silhouettes → cities | fair AND not required | pictogram-to-pictogram matching suffices |
| 12-hour wrap (15 → 3 o'clock) | mild borderline — see flags | wheel physically only offers I–XII |
| Gear ratios (bigger = slower; stages multiply) | **borderline — see flags** | slate worked diagram + live speed feedback + bounded trial |
| Mirror reversal behind a translucent dial | inference, not trivia | reversed numerals in the same close-up as the crank |

## BORDERLINE FLAGS for the user

1. **The IIII convention (p01).** Traditional clock dials write four as IIII while keeping
   IX — a delightful educated-generalist fact, but genuinely not universally known. As
   designed it is *soft*: three in-room clock faces show IIII, and a wrong IV attempt
   costs one pop-back with no lockout (trial-and-error resolves it in ≤2 tries). Approve
   as-is, or demote (make the tray IV tile physically mis-pegged so it can't seat — pure
   observation, zero knowledge)?
2. **Gear-ratio arithmetic (p06).** Computing (A/12) × (B/8) = 24 is the level's peak
   reasoning. Backups: the slate's worked diagram, live too-fast/too-slow feedback, and a
   bounded (~30-pair, tedious-but-finite) experimentation space. I judge this fair-hard
   and exactly the escalation the ledger asks for — but it is the single most likely
   "stuck" point. Confirm you accept a genuine arithmetic puzzle here.
3. **p06 is deliberately UNGATED** (unlike every other code-like puzzle): a mechanically
   correct train must work even if the slate was never viewed, because gating physical
   truth reads as a broken machine. Cost: a determined player can brute-force ~30 pairs.
   Designer call — confirm.
4. **12-hour wrap (p07).** Fuji: 6 + 9 = 15 → III. Most adults convert 15:00 readily and
   the wheel only offers I–XII, but it is the one arithmetic step with a small trap
   (setting IX by mis-reading "+IX" as the answer). Fair in my judgment; flagging per
   protocol.
5. **Mirrored-dial trap (p09).** The naive reading sets 4:40 and produces silence (no
   tell). Evidence is strong (mirrored numerals fill the same close-up), but this is the
   level's harshest silent failure. Alternative if you want it gentler: add a small
   inspection mirror beside the crank showing the front view (drops the puzzle to
   execution). I recommend keeping the trap.
6. **Landmark pictograms.** Big Ben / Eiffel / Liberty / Fuji were chosen for maximal
   recognizability, but NO city knowledge is required — plates match headers by pictogram.
   Flagging only because the ledger requires listing every RWK surface.
7. **Difficulty of z1's cache gating.** p03/p04 floorboards/bricks are deliberately
   tell-free (the watch is the whole clue) and pry attempts are clue-gated no-tell. A
   player who tries prying before finding the watches gets uniform "doesn't budge" — by
   design identical to inert boards. Confirm you're comfortable with this gating pattern
   extending L1's policy to physical sweeps.

## Open design questions

- None blocking. The cat's refusal grammar, mouse no-loss rule, and time-lock keyless-door
  grammar are specified in developer_notes D3/D4/D8; the mirrored-render contract is D1.

## Visually-necessary elements

The complete per-zone list (with all required states) is in `puzzle-graph.json` →
`visually_necessary_elements`. Headlines for the Art Director: legible numerals at close-up
on five distinct dial types (master clock, door dial, watches, world clocks, mirrored
great dial — the mirrored numerals are load-bearing); countable gear teeth + stamped
counts; the continuous linkage-rod line from door to strike train across three zones; the
cat's four staging states; golden-afternoon light with a sunbeam patch (cat) and amber
transmitted glow (great dial). No color-differentiated puzzle elements exist anywhere in
the level (see `colorblind_safety`).
