# Level 2 — The Clockmaker's Attic — Walkthrough

**STATUS: DRAFT (Documentation first pass, 2026-07-18)** — written from
`puzzle-graph.json` rev 1.3 (post-playtest tweaks, all user-approved) and
`puzzle-graph-summary.md`, before implementation. All solution values below are the
graph's fixed values and will not change; interaction details (exact taps and drags)
follow the series-standard control scheme and the graph's declared behaviors, and will
be reconciled against the shipped build in the second pass after QA.

---

*"All his clocks stopped at six."*

You are in a tower clockmaker's attic workshop, late golden afternoon. Every clock in
the room stopped at the same moment — six o'clock — and the clockmaker is gone,
mid-thought. The attic backs directly onto the tower's great dial; linkage rods run
from the barred stair door along the ceiling and into the walls. The whole room is one
connected machine, and the only way out is to finish what the clockmaker started:
restore the great tower clock, and the clock itself will open the door. A gray cat
still lives here.

This guide follows one complete solve path, zone by zone, in the order a typical player
encounters things. Many steps can be done in a different order; see **Alternate routes**
at the end. All solutions are fixed — the exact answers below are always correct — but
each *coded or clue-bound* lock only accepts its input after you have viewed its in-game
clue at least once (noted at each puzzle below). This guide's step order always
satisfies that.

**How the game controls:** the side chevrons cycle between a zone's views. Tapping an
object of interest opens a close-up; leave a close-up with the down-chevron. Items are
used by dragging them from the inventory bar onto the scene. Long-press an inventory
icon to inspect the item — several items in this level carry their clue on the item
itself, so inspecting matters. Discovered passages (the workroom door, the wall panel,
the floor hatch) are tapped to travel through.

---

## Part 1 — Main Attic: gather the tiles and open the workroom

You start in the Main Attic, which has three views: the **bench**, the **master clock**
(with the painted workroom door), and the **stair door** (with the dormer window and
the cat).

### Step 1. Take the screwdriver

At the bench, a heavy flat-blade screwdriver sits in a rack over the long workbench.
Take it. You will use it twice, much later — both times to pry something open.

### Step 2. Study the chalk slate

Propped on the bench is a chalk slate with a wordless diagram: a crank circle ringed by
**24 tally marks**, a small gear marked **XII**, an unknown wheel marked **?**, a
smaller gear marked **VIII**, a second **?**, and finally a circle with a single notch
and a little door pictogram. This is the working drawing for the gear machine in the
next room — it says the crank must turn **24 times** for one turn of the final cam.
Remember it for Part 3. (This clue is confirmatory, not required — the machine gives
honest feedback either way — but it is the fast route.)

### Step 3. Collect the four numeral tiles (and pocket watch A)

Four loose Roman-numeral tiles are hidden around the attic:

| Tile | Where |
|---|---|
| **II** | on the cold hob of the small iron stove (bench view) |
| **IV** | in a pocket of the clockmaker's coat on its peg (bench view) |
| **VII** | half-buried in the straw of the packing crate (master-clock view) |
| **XI** | on the dormer windowsill (stair-door view) |

While you're in the coat pockets, also take **pocket watch A** from the other pocket —
a single-handed watchman's watch. Hold onto it; it's a clue carrier you'll inspect in
Part 2.

### Step 4. Look at the master longcase clock

In the master-clock view, tap the tall longcase clock for a close-up. It is stopped at
exactly **6:00** (hour hand on VI, minute hand straight up on XII), and its case is
engraved with a small **star (★)**. Every stopped clock in the level agrees with it.
File both facts away — the star and the six — they are half of a code you will enter
two zones from now, and **viewing this close-up is required** before that code will
work. Doing it now costs nothing.

### Step 5. Solve the numeral-dial door (p01)

The workroom door is painted as a giant hand-less clock dial with 12 tile sockets.
Eight tiles are already seated — I, III, V, VI, VIII, IX, X, XII — leaving four empty
sockets at the **2, 4, 7 and 11** positions. A wooden tray fixed below the dial holds
one loose **VI** tile.

**Seat your four tiles into the empty sockets by clock position: II at the 2 position,
IV at the 4 position, VII at the 7 position, XI at the 11 position.** The eight seated
tiles anchor the layout (12 at top, clockwise), so there is never any doubt which
socket is which.

The tray's VI tile is bait for the 4-socket — IV and VI use the same two glyphs in
opposite order (I *before* V subtracts: four; I *after* V adds: six). If you try it,
the socket whirs, stalls, and pops the tile back to the tray. The disproof is on the
dial itself: **a VI is already seated at the 6 position**, one glance away. Any wrong
tile in any socket does the same whir-stall pop-back — inventory tiles return to
inventory, the tray tile to its tray — with unlimited attempts, and correct seats
persist. This door is *not* clue-gated: correct seating always works.

The dial completes, the latch trips, and the workroom door opens: the **Movement
Loft** is now accessible.

> **Ignore:** the wheel **barometer** on the bench-view wall. It looks like one more
> brass clock dial, but its needle is fixed and its face is engraved with sun, cloud
> and rain pictograms — it's a weather instrument, not a clock, and it accepts no
> input of any kind. See **Red herrings** at the end.

> **About the stair door:** the only exit is barred by a heavy horizontal bolt-bar in a
> vault-style time-lock housing with **no keyhole**. Poke at it all you like — the bar
> just rattles once against its linkage, identically every time. Follow the linkage
> rods with your eyes instead: they run from the door along the ceiling and vanish into
> the workroom wall. The door is opened *by* the clock, from the far end of the level.
> Nothing you do at the door itself will ever open it.

---

## Part 2 — The cat, the watches, and the two caches

The Movement Loft has two views: the **gear frame** (automaton wall and chimney) and
the **clock row** (four dead wall clocks and a parts cabinet). This part weaves
between the two zones — the level's two hidden caches are found by using two pocket
watches as *pointers*.

### Step 6. Take the tin mouse

In the Movement Loft's clock-row view, open the parts cabinet's top drawer and take
the **tin wind-up mouse** (it has a built-in butterfly key). It has exactly one use,
coming right up.

### Step 7. Inspect pocket watch A, then pry the dormer floorboard (p03)

**Long-press pocket watch A in your inventory to inspect it.** The case back is
engraved with a **house symbol (⌂)**, and its single hand is frozen on **III**.

Now go to the attic's stair-door view. On the beam beside the dormer is a small carved
**⌂** ringed by a 12-notch circle — a clock-position ring, and the twin of the watch's
engraving. The watch is a pointer: read its hand *at the ring*. A hand on III means the
**3-o'clock direction** — from the ring, that points at the **third floorboard to the
right of the dormer**.

**Pry that board up with the screwdriver.** Underneath is the **great wheel** — a
bronze gear with 64 teeth, stamped **64**. Take it.

*Clue-gate note:* this cache is gated on **inspecting watch A**. Until you have viewed
the watch's close-up, no board will come up — every *wrong* board gives a dead
"doesn't budge," identical on every try, while the *correct* board gives a faint creak
and a hair of movement under the blade but still firmly refuses. If an early prying
spree left you with the memory that one board *felt* different — that was this one, and
it wasn't lying; it just wasn't ready. Inspect the watch and the same board yields
normally. The boards otherwise look perfectly uniform — the watch is the *only* thing
that marks the spot, which is why sweeping the floor blind is deliberately unrewarding.

### Step 8. The cat and the mouse (p02)

In the stair-door view, the gray cat sleeps on a cushion in the dormer sunbeam — and
the cushion visibly has something flat beneath it. The cat refuses everything: nudge
it, or offer it any item, and you get one slow blink as it resettles heavier on the
cushion, and your item comes straight back. (Petting is always allowed — you get a
purr and nothing else.)

One offer is different: **hold the mouse out to the cat directly and the cat's eyes
lock onto it and track it, tail flicking — but it stays put**, and the mouse returns
to your inventory. Right idea, wrong delivery. A cat doesn't take prey from your hand;
prey has to *run*.

**Wind the tin mouse and set it down on the floor near the cat's bench** (drag the
mouse from inventory onto the floorboards by the cushion). The mouse skitters, the cat
pounces and chases it into the stair-door corner — and keeps it, settling there by the
exit for the rest of the level. The mouse is gone for good; it has no other use, so
nothing is lost.

**Lift the now-vacant cushion and take pocket watch B** — the flat shape that was
under the cat all along.

> Wound and placed anywhere *not* near the cat, the mouse just skitters a small circle
> and returns to your inventory. It can never be wasted.

### Step 9. Inspect watch B, then pry the chimney brick (p04)

**Long-press pocket watch B to inspect it.** Case back: a **gear symbol (⚙)**; single
hand frozen on **IX**.

Return to the Movement Loft's gear-frame view. On the chimney breast, one brick bears
a carved **⚙** ringed by the same style of 12-notch clock ring. Same trick as the
dormer: hand on IX = **9-o'clock direction** = **the brick directly left of the
ring**.

**Pry that brick out with the screwdriver.** In the cavity is the **long-spout oil
can**. Take it — you will use it twice, and it never runs dry.

*Clue-gate note:* identical grammar to Step 7 — gated on **inspecting watch B**. Wrong
bricks are dead-identical "doesn't budge"; the correct brick gives the faint
grinding-creak-and-shift tell until the watch has been viewed, then yields normally.

---

## Part 3 — The gear train: make the machine open the wall

### Step 10. Oil the seized arbor (p05)

The automaton wall in the gear-frame view is a carved town scene driven by an exposed
two-stage gear frame — but its main arbor is visibly seized: a rust bloom at the
bearing, and the fold-out crank only rocks a few degrees. **Use the oil can on the
rust-bloomed bearing.** The arbor frees; the crank now turns.

### Step 11. Build the 24-to-1 train and crank it (p06)

The frame, left to right: the **crank** carries a fixed pinion stamped **XII**
(12 teeth); empty **post A** carries a fixed coaxial pinion stamped **VIII** (8 teeth);
empty **post B** drives the cam that runs the mural and, at the end of one full cam
turn, the wall-panel latch. A rack on the wall holds six loose brass gears stamped
**16, 24, 36, 40, 48, 72** (countable teeth; rack gears mount and return freely but
never enter your inventory).

The slate from Step 2 encodes the requirement: crank-to-cam must be **24 to 1**. The
crank's 12-tooth pinion drives the wheel on post A; post A's 8-tooth pinion drives the
wheel on post B. So (A÷12) × (B÷8) = 24, which means **A × B = 2304**. No pair on the
rack multiplies to 2304 — the tempting exception is 48 × 48, but there is only one
48-tooth gear in the entire level. The unique working pair is **36 × 64**: the 36 is
on the rack, and the 64 is the great wheel you dug out of the floor in Step 7.

**Mount the 36-tooth rack gear on one post and the 64-tooth great wheel on the other —
either arrangement works (36 on A with 64 on B, or the reverse; the ratio multiplies
out the same). Then fold out the crank and turn it through one full cam revolution.**

At exactly 24:1 the mural runs one clean cycle — the carved sun crosses the town, the
watchman figure strikes his bell — a counterweight drops, and a **wall panel swings
open** onto the tower-clock chamber: **Behind the Great Dial**. The panel latches open
permanently.

This puzzle is deliberately *not* clue-gated — a correctly built train always works,
slate or no slate. Wrong pairs give honest feedback: the cam visibly runs too fast or
too slow, and at cycle-end the latch ratchets and slips with a clack (the same clack
for every wrong ratio; speed is the only differential). If algebra isn't your thing,
the machine itself is countable: mount any meshing pair and count **cranks per cam
clack** — you are hunting for exactly 24, the slate's 24 tally marks. Gears remount
freely; the great wheel returns to your inventory if unmounted; no lockout.

> **Ignore:** the glass-front **display case of spare clock hands** in the clock-row
> view, and the search for "the second 48." See **Red herrings** at the end.

### Step 12. Read the world-clock row

Before (or after) crawling through the panel, tap the **row of four dead wall clocks**
in the clock-row view for a close-up of their brass plates. All four clocks have had
their hands removed — they will never tell time and never need hands. The payload is
stamped on the landmark plates beneath them:

| Plate (landmark silhouette) | Stamp |
|---|---|
| Burj Khalifa (needle-spire tower) | **+IV** |
| Big Ben (clock tower) | **★** (no offset — the same star as the master clock) |
| Mount Fuji (snow-capped peak) | **+IX** |
| Statue of Liberty (torch figure) | **−V** |

These are time-zone offsets from the starred reference clock. You don't need to
recognize a single landmark or know a single real time zone — the pictograms will be
matched against identical pictograms, and every offset is stamped right here.
**Viewing this close-up is required** (together with Step 4's master clock) before the
vault code in the next zone will work.

---

## Part 4 — Behind the Great Dial: the vault code

You emerge behind the tower's great translucent dial, glowing amber with afternoon
light. Note — and this will matter in Part 5 — **every numeral on the dial reads
mirror-reversed from back here**. The chamber holds the winding drum, the setting
crank, the dead-still pendulum, the strike train with its chime hammers (the ceiling
linkage rods re-emerge here and run off toward the stair door), and a **floor hatch**
in the platform.

### Step 13. Open the four-wheel vault hatch (p07)

The hatch is locked by four brass combination wheels, each engraved **I–XII**, headed
left to right by pictogram plates: **Big Ben ★, Burj Khalifa, Statue of Liberty,
Mount Fuji**. Note the order is *different* from the z2 clock row — match pictogram to
pictogram, not position to position.

The derivation: the master clock (Step 4) stopped at **6:00** and carries the **★** —
the same star as the Big Ben plate and the Big Ben wheel header. So the starred
reference reads 6, and each other wheel is 6 adjusted by its plate's stamped offset:

| Wheel header | Offset (from its z2 plate) | Arithmetic | Set to |
|---|---|---|---|
| Big Ben ★ | reference | 6 | **VI** |
| Burj Khalifa | +IV | 6 + 4 = 10 | **X** |
| Statue of Liberty | −V | 6 − 5 = 1 | **I** |
| Mount Fuji | +IX | 6 + 9 = 15 → wraps to 3 | **III** |

The Fuji wheel is the one wrinkle: 15 doesn't exist on a 12-hour wheel, so it wraps —
15 o'clock is 3 o'clock. The wheel itself only offers I–XII, which is your nudge.

**Set the wheels, left to right under their headers: VI · X · I · III — then try the
hatch.** (The hatch releases when *tried*, not on the final wheel click.)

*Clue-gate note:* this lock is gated on having viewed **both** the master clock
close-up (Step 4) and the world-clock-row close-up (Step 12). The wheels always spin
freely and keep their positions, but until both clues are viewed the hatch stays shut
on *any* setting — including the correct one — with no distinguishing tell. If you
followed this guide's order, both are long since satisfied.

The hatch opens onto the **Clockmaker's Vault**, a small strongroom under the
platform.

### Step 14. Clear the vault

Two takeables, both needed:

- The **square-bit winding key**, on its hook.
- The **brass "will return" shop tag**, on a nail: a miniature clock dial with its
  hands **fixed at 7:20**, above a small door pictogram. This is the clockmaker's
  "back at 7:20" sign — and the time-lock's release time. **Long-press it in your
  inventory and view the close-up now**; the setting crank upstairs will not honor the
  release time until you have.

The rest of the vault is quiet lore: a second cat cushion with an empty saucer, and a
shelf of ledgers with a wrapped, unfinished pocket watch — all inspect-only, none
needed (see **Red herrings**).

---

## Part 5 — Restore the movement and escape

Three things bring the great clock back to life — **wind it, set it to the release
time, start the pendulum** — and they work in **any order**. The moment all three are
true at once, the strike fires and the door bar lifts, permanently. This guide's order
is one of several; see Alternate routes.

### Step 15. Oil and wind the movement (p08)

The winding drum's bearing is dry and rusted — it squeals. **Use the oil can on the
drum bearing first**, then **insert the winding key in the square socket and crank
until the drive weight rises fully** on its line. (Key before oil: the key seats but
won't turn and the drum squeals — oil it and try again. Nothing is consumed.) The
clock is now wound; this state persists.

### Step 16. Set the hands from behind — the mirror trap (p09)

The return tag says the release time is **7:20**. The trap: the tag shows the dial's
**front**, and you are standing **behind** it. From back here the dial is a mirror
image — that's what the reversed numerals have been telling you since you walked in.
Copy the tag's hand positions naively onto the view in front of you and you have
actually set the front of the clock to **4:40** — and nothing will happen.

The evidence is all on the glass. Look closely at the mirrored numerals: nowhere on
the back view is there a legible "VII" — and what looks like a malformed VI is
actually the mirrored IV (and vice versa). The back view is the front's mirror, so the
tag's time must be entered *as its mirror image*.

**Turn the setting crank until the hands — read naively, as if the back view were an
ordinary dial — show 4:40** (hour hand two-thirds of the way from the 4-position
toward the 5, minute hand on the 8-position; the minute hand moves in 5-minute
detents, so the positions land exactly). That is the mirror image of 7:20, which means
the *front* of the great dial now truly reads **7:20** — the release time.

*Clue-gate note:* the crank always turns and the hands always move, but the release
time only counts after you have **inspected the return tag** (Step 14). Until then —
or at any wrong time — the strike simply doesn't fire, with no tell. One reassurance
the movement *does* give you: once the clock is wound and the pendulum is swinging, a
wrong time is no longer silent — you'll hear a soft escapement tick, and occasionally
a chime hammer twitches without ever striking. That sound means "alive, wrong input,"
never "broken" — but it is identical at every wrong time and tells you nothing about
the right one. The right one is 7:20, front, mirrored as above. Full silence, by
contrast, means the wind or the pendulum is still missing.

### Step 17. Start the pendulum (p10)

**Push the pendulum bob.** It swings and keeps swinging (weakly if you somehow got
here unwound; fully once wound — either way it counts, permanently).

### Step 18. The strike — and the exit (p11)

The instant all three hold — wound, front hands at 7:20, pendulum running — the
**strike train fires**: chimes, and the linkage rods articulate visibly along the
ceiling, here and all the way back in the attic. The stair door's bar lifts, and it
stays lifted — no later hand-fiddling can re-lock it.

**Return through the panel and the workroom to the attic's stair-door view.** The cat
— parked by the door since Step 8 — stands and stretches as the bar rises, in case
you missed the chimes. **Open the stair door.** It swings onto the tower stairs in
evening light, and the cat trots out ahead of you, tail up. Level complete.

---

## Alternate routes (footnotes)

Progression is tracked purely as satisfied requirements, never step order. The hard
spine is: tiles → **workroom door (p01)** → mouse → cat → watch B, and watch A →
dormer cache → great wheel; then oil → arbor → **gear train (p06)** → the dial
chamber; then **vault code (p07)** → key + tag → the endgame trio. Within that,
notable freedoms:

- **Knowledge first:** the vault code can be fully pre-computed long before the vault
  exists — view the master clock (z1) and the clock row (z2) early and walk into the
  dial chamber with VI·X·I·III in hand; the hatch opens first try (ordering C in the
  design doc). The reverse also works: reach the hatch first, then backtrack for the
  two clue views — both zones stay open forever.
- **Cache order is free:** the dormer board (watch A) and the chimney brick (watch B)
  can be done in either order, each as soon as its watch has been inspected. Watch A
  is available from the first minutes; watch B always comes via the cat.
- **The slate is optional:** p06 is not gated. You can solve the gear train by pure
  experiment — mount pairs and count cranks per cam-clack until you hit 24 — without
  ever reading the slate. The slate just saves you the sweep.
- **Endgame trio in any order:** wind / set hands / pendulum are order-free (orderings
  B and C in the design doc do pendulum-first and hands-before-winding). Whichever
  act completes the set fires the strike. Hands can even be set to 7:20 *before*
  inspecting the tag — the release then asserts itself when you next enter the
  close-up after viewing the tag (the game re-checks; you are never stuck).
- **The mouse only works one way:** wound and on the floor near the cat. Offered from
  the hand it earns the eye-lock tell; placed anywhere else it circles back to
  inventory. It can never be lost early.

The only hard cross-zone links: watch B (earned in z1 via the cat, using the z2 mouse)
is needed for the z2 chimney cache; the great wheel (z1 floor) is needed for the z2
gear train; and the vault code marries a z1 clue to a z2 clue at a z3 lock. Everything
else interleaves freely.

## Red herrings — never needed, never collectible

- **The wheel barometer** (attic, bench view). A clock-like brass dial with a fixed
  needle and engraved sun/cloud/rain pictograms. It is a weather instrument, not a
  clock; it accepts no input, holds no code, and cannot be set. Inspect once and move
  on.
- **The tray VI tile** (under the workroom-door dial). The one loose tile you never
  need. It exists to bait the empty 4-socket (IV vs VI glyph order) and pops back to
  its tray from any socket. It never enters your inventory. The seated VI at the
  dial's 6 position disproves it at a glance.
- **The 48-tooth gear** (workroom gear rack). 48 × 48 = 2304 exactly — the arithmetic
  works, and the game knows it. But there is only one 48-tooth gear anywhere in the
  level; the hunt for a second is the trap. The real pair is 36 × 64.
- **The spare-hands display case** (workroom, clock-row view). Four hand-less clocks
  practically beg you to refit hands, and a case of spare hands sits right there —
  screwed shut and painted over, with a screwdriver in your pocket. It never opens.
  The world clocks never get hands and accept no interaction; their stamped plates
  are the entire point of the row.
- **The vault shelf** (and the second cushion with its saucer). Ledgers and a wrapped,
  unfinished pocket watch — inspect-only lore about the man who left, and the cat's
  other nap spot. Nothing here is collectible or required.

## Quick answer key

Reminder before using this table cold: the gated puzzles stay inert — with their
normal "wrong answer" feedback — until their clue has been viewed in-game at least
once (p03: inspect watch A; p04: inspect watch B; p07: the master-clock close-up *and*
the world-clock-row close-up; p09: the return-tag close-up). At p07 and p09 there is
deliberately no tell distinguishing "not yet" from "wrong." At p03/p04 the one
sanctioned tell: pre-clue, the *correct* board/brick creaks and shifts faintly but
refuses; wrong spots are always simply dead.

| Puzzle | Answer |
|---|---|
| Numeral-dial door (p01) | Seat II / IV / VII / XI in the empty sockets at positions 2 / 4 / 7 / 11 (tray VI is a decoy) |
| Cat and mouse (p02) | Wind the tin mouse and set it on the floor by the cat's bench; then lift the cushion → watch B |
| Dormer cache (p03) | Watch A: ⌂, hand on III → pry the 3rd floorboard right of the dormer ⌂-ring → great wheel (64t) |
| Chimney cache (p04) | Watch B: ⚙, hand on IX → pry the brick directly left of the chimney ⚙-ring → oil can |
| Seized arbor (p05) | Oil can on the rust-bloomed bearing |
| Gear train (p06) | Mount 36-tooth (rack) and 64-tooth (great wheel) on posts A/B — either order — and crank one full cam cycle (24 cranks : 1 cam) |
| Vault hatch wheels (p07) | Left to right under Big Ben ★ / Burj Khalifa / Liberty / Fuji: **VI · X · I · III**, then try the hatch |
| Oil and wind (p08) | Oil can on the drum bearing, winding key in the square socket, crank until the weight is fully raised |
| Set the hands (p09) | Front time **7:20** — from behind, set the hands to read 4:40 naively (the mirror image of the tag's 7:20; naive 7:20 copy = the 4:40 trap) |
| Pendulum (p10) | Push the bob |
| Exit (p11) | When the strike fires and the bar lifts, return to the attic and open the stair door |

---

*DRAFT — Documentation first pass, 2026-07-18, from `puzzle-graph.json` rev 1.3 and
`puzzle-graph-summary.md`. To be reconciled after QA (second pass) against the
Developer's implementation notes and `qa-report.md`. Fixed solution values verified
against the graph: p01 sockets 2/4/7/11 ← II/IV/VII/XI; p02 mouse wound + floor at
cat; p03 board at ⌂-ring 3 o'clock; p04 brick at ⚙-ring 9 o'clock; p06 gear set
{36, 64}, either post order, 24:1; p07 VI-X-I-III; p09 front 7:20 (back view mirror);
p08/p10 mechanism completions; p11 via cond-timelock-release.*
