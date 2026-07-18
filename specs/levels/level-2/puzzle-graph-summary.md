# Level 2 — The Clockmaker's Attic — Puzzle Graph Summary (rev 1.3)

_Checkpoints complete: step-4 design rulings (rev 1.2) and step-6 playtest tweaks (rev 1.3,
all three user-approved). Companion to `puzzle-graph.json` (same directory)._
_Rev 1.3 (post-playtest, verdict READY-WITH-TWEAKS): (1) pry-gates KEPT with a new
faint-tell memory hook on the correct board/brick (D10); (2) the cat now gives a
mouse-specific tell on a direct offer (D3); (3) the movement shows an "alive, wrong time"
sign of life when wound + swinging (D11). Feedback grammar only — no solution, dependency,
ordering, or herring changed; D9 stays dormant._
_Rev 1.2: standard IV notation level-wide; Dubai/Burj Khalifa in the city set; vault code
VI·X·I·III; D9 easing valve specced. Rev 1.1: Validator ordering-C text fix._

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
  seat them in the door dial's empty sockets (positions 2/4/7/11). Modest trap: a tray
  under the door offers a loose **VI** tile — glyph-order bait for the 4-socket —
  disproved by the dial's own seated VI at position 6. Wrong tile whir-stalls and pops
  back. → unlocks z2. *(Playtest: solved ~6 min, decoy cost seconds — working as
  intended.)*
- **p02 The cat and the mouse** — the cat sleeps on a cushion (something flat beneath
  it). Rev 1.3: offering the mouse DIRECTLY earns a **tell** — eyes lock on, tail
  flicks, cat stays put, mouse returns (every other item still gets the generic slow
  blink). The working verb: wind the mouse and set it on the FLOOR — pounce, chase, cat
  keeps it and resettles by the exit door. → pocket watch B.
- **p03 Dormer floorboard cache** — pocket watch A (⌂ case back, hand on III) + the ⌂
  clock-position ring by the dormer → 3 o'clock → third floorboard right → pry → the
  64-tooth **great wheel**. *(Clue-gated on inspecting watch A. Rev 1.3: wrong boards
  stay dead-identical; the CORRECT board pre-clue gives a faint creak + perceptible
  shift — a memory hook, not an invitation — then yields normally once the watch is
  seen. Ruling #7 + playtest 2a resolved.)*

### z2 Movement Loft (difficulty ~7.0 — level signature)
- **p04 Chimney brick cache** — watch B (⚙, hand on IX) → 9 o'clock at the chimney's ⚙
  ring → pry brick → **oil can**. Same rev-1.3 faint-tell grammar as p03. Cross-zone
  loop: mouse (z2) → cat (z1) → watch B → back to z2.
- **p05 Free the seized arbor** — oil the gear frame's rusted bearing.
- **p06 The automaton gear train** — crank pinion XII (12t) → POST A wheel (+ fixed
  pinion VIII, 8t) → POST B wheel → cam. Slate: **(A/12) × (B/8) = 24** → A×B = 2304.
  Rack {16, 24, 36, 40, 48, 72} + the found 64: unique answer **36 × 64** (either post
  order). The lone 48 teases 48×48. Correct ratio → mural runs one clean cycle → wall
  panel opens → z3. *(Playtest: the "no rack pair works, a 64 must be hidden" deduction
  landed exactly as designed and was rated a top aha; the cranks-per-clack counting
  route is a sanctioned no-algebra path — D5.)*
- *(clue scenery)* **World-clock row**: hand-less clocks, landmark plates + stamped
  offsets — Burj Khalifa **+IV** (Dubai), Big Ben **★** (reference), Fuji **+IX**,
  Liberty **−V**.

### z3 Behind the Great Dial (difficulty ~7.5)
- **p07 The four-wheel vault hatch — THE NUMERIC-CODE LOCK.** Wheels I–XII under
  pictogram headers (Big Ben ★ / Burj Khalifa / Liberty / Fuji — different order than
  the z2 row). Master clock 6:00 (★) + offsets → **VI · X · I · III** (6; 6+4=10;
  6−5=1; 6+9=15→3, the single ratified wrap). → unlocks z4. *(Clue-gated on master clock
  + clock row. Playtest: the ★ chain was rated the level's best aha.)*
- **p08 Oil and wind** — oil the squealing drum, crank the winding key, weight rises.
  → `clock-wound`.
- **p09 Set the hands from behind** — mirrored dial; the vault tag shows **7:20**
  front-view; naive copy sets 4:40 (trap); the aha is to set the mirror image (the
  playtest's unstick: no legible "VII" exists on the back view). → `hands-at-release`
  (front = 7:20). *(Clue-gated on the tag. Rev 1.3, D11: with the clock wound and
  pendulum swinging, any wrong time now yields a soft escapement tick + an occasional
  hammer twitch that never strikes — "alive, wrong input", never "broken". Identical at
  every wrong time; reveals nothing about 7:20. D9 easing valve stays dormant and
  separate.)*
- **p10 Start the pendulum** — push it. → `pendulum-running`.
- **`cond-timelock-release`** = wound ∧ hands-at-7:20 ∧ pendulum, order-free; on first
  TRUE the strike fires, the rods articulate the length of the level, the z1 bar lifts
  (latched).

### z4 The Clockmaker's Vault (difficulty ~5.0 designer / 3.5 official — reward room)
Winding key, the "will return" tag (release-time clue; self-verifying read, per
playtest), quiet lore (second cushion, saucer, unfinished pocket watch).

- **p11 Exit** — return to z1, bar raised, cat stretches, door opens onto the tower
  stairs; the cat trots out ahead. **WIN.** *(Playtest: "best single moment in the game
  so far.")*

## Dependency spine (prose)

Tile scavenge → **p01** → z2. Three parallel cross-binding streams: (1) watch A → dormer
cache → great wheel; mouse → cat → watch B → chimney cache → oil can; (2) oil arbor →
**gear train p06** → z3; (3) knowledge: master time (z1) + clock-row offsets (z2) → vault
code. In z3: **p07** → z4 (key + tag) → endgame trio p08/p09/p10 **in any order** →
strike → exit. State is pure satisfied-requirement flags + one derived condition; the
rev-1.3 tweaks add no state (D10/D11 are presentation over existing flags).

## Difficulty self-assessment

**Designer estimate 7.0 overall** (z1 5.0 · z2 7.0 · z3 7.5 · z4 5.0). **Validator
official: 6.5** (z1 5.0 · z2 7.0 · z3 7.0 · z4 3.5), confirmed at the rev-1.2 delta
re-validation. **Blind-solve now playtest-calibrated: 70–135 min, median ~100** (L1:
60–100). Playtest verdict on the curve: "the escalation is real" — one derivation (gear
ratio), one cross-zone synthesis (★/offsets), one perceptual reframe (mirror order),
never arbitrary. Rev 1.3 trims worst-case stall tails (S1/S2, the poisoned-pry and
bug-read failure modes), not intended-path difficulty; designer expects 6.5 to hold.

## Real-world knowledge used (fairness notes)

| Fact | Register | In-room backup |
|---|---|---|
| Roman numerals I–XII, standard subtractive notation incl. IV-vs-VI glyph order | clearly fair | 8 seated tiles + every dial; seated VI disproves the tray decoy |
| Clock-face layout (12 top, clockwise) | clearly fair | seated tiles anchor all positions |
| Time zones exist | fair as concept — playtest: "I never needed to know a single real time zone" | all offsets stamped in-world |
| Landmark silhouettes (Big Ben, Burj Khalifa, Liberty, Fuji) | fair AND not required | pictogram-to-pictogram matching suffices |
| 12-hour wrap (15 → 3 o'clock) | mild borderline — RATIFIED; playtest: ~2 min hesitation | wheel physically only offers I–XII |
| Gear ratios (stages multiply) | borderline — RATIFIED as the arithmetic peak | slate diagram + speed feedback + countable clack cadence |
| Mirror reversal behind a translucent dial | inference — CONDITIONALLY KEPT (D9 dormant; D11 kills the bug-read) | reversed numerals; no legible "VII" on the back view |

## BORDERLINE FLAGS — CHECKPOINT RULINGS (user, 2026-07-18)

1. **IIII convention — OVERRULED** (rev 1.2). Standard IV level-wide; VI glyph-order
   decoy compensates; p01 slightly easier, accepted.
2. **Gear-ratio arithmetic — RATIFIED.** Playtest confirmed it as the intended peak with
   a working no-algebra fallback (clack counting).
3. **p06 ungated — RATIFIED.**
4. **12-hour wrap — RATIFIED.** Still exactly one wrap case (Fuji).
5. **Mirrored-dial trap — CONDITIONAL KEEP.** D9 easing valve specced and DORMANT
   (untouched by rev 1.3); D11's alive-wrong-time signal addresses only the "feels like a
   bug" component, deliberately not the inference itself.
6. **Landmark pictograms — MODIFIED** (rev 1.2). Dubai in; Tel Aviv/Tehran/Riyadh
   excluded; Paris dropped. **Vault code VI·X·I·III.**
7. **Pry-sweep gating — RESOLVED** (rev 1.3, playtest tweak 1, user-approved). Gate
   KEPT; the correct board/brick now carries the D10 faint-tell memory hook pre-clue;
   wrong spots remain dead-identical.

## Post-playtest tweaks applied (rev 1.3, all user-approved)

| # | Playtest finding | Change | Where specced |
|---|---|---|---|
| 1 | Impatient-pryer fork (2a): pure no-tell let an early pry certify the correct spot as inert, poisoning the later watch clue | Correct board/brick pre-clue: slight creak + perceptible shift, firmly not yielding; no visual change; wrong spots unchanged | no_tell_rule amendment, p03/p04, D10 |
| 2 | Mouse offered to cat returned "unused" — punished the right idea (~5 min doubt) | Mouse-specific tell: eyes lock + tail flick, cat stays put, mouse returns; all other items keep the slow blink | clu-cat-refusal, p02, D3/D4 |
| 3 | Wound + swinging + wrong time was fully silent — read as bug (S2, hasty reader worst case) | Alive-wrong-time ambient: soft escapement tick + hammer twitch that never strikes; silence only when wind or pendulum missing; identical at every wrong time | p09 failure grammar, D2, D11 |

Secondary playtest suggestions (ship-as-is per ruling): hatch releases on try rather than
on last wheel click (kept); display-case paint-over emphasis left to the Art Director's
discretion (noted on rh-hands-case).

## Open design questions

- None blocking. Grammars: cat D3, mouse D4, time-lock door D8, mirror render D1, pry
  memory hook D10, alive-wrong-time D11; D9 easing valve dormant, activation is a user
  call at any feedback round.

## Visually-necessary elements

Full per-zone list with states: `puzzle-graph.json` → `visually_necessary_elements`,
headed by the global numeral rule (standard IV/IX everywhere, no IIII) and the rev-1.3
cue note: **no new plates, no re-rolls** — the three tweaks are SFX/haptic + one line of
animation each (correct-spot creak-shift; cat eye-lock/tail-flick) plus one ambient layer
(escapement tick + hammer twitch). Headlines for the Art Director: legible numerals at
close-up on five dial types (the mirrored great dial is load-bearing — mirrored IV must
read as malformed VI, and NO legible "VII" may exist on the back view); countable gear
teeth + stamped counts; the Burj Khalifa needle-spire silhouette among four
silhouette-distinct plates; the continuous linkage-rod line across three zones; the cat's
five staging states (incl. the new mouse-offer tell); golden-afternoon light (sunbeam
patch; amber dial glow); reserved staging space beside the z3 crank for the dormant D9
overlay. No color-differentiated puzzle elements anywhere (see `colorblind_safety`).
