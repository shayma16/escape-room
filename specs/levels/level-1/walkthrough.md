# Level 1 — The Wizard's Cabin — Walkthrough

**STATUS: FINAL (second pass)** — reconciled against `puzzle-graph.json` rev 1.2, the
Developer's `implementation-notes.md` (judgment calls 1–18 plus the BUG-004 art
integration), and the re-QA results in `qa-report.md` (step-13 GO, 2026-07-06). All
solution values are unchanged from the draft; this pass updates interaction and
positional descriptions to match the shipped build.

---

*"The wizard is gone. The crow remains."*

You wake at night in an abandoned wizard's cabin. The front door's bolt is sealed under
living thorn-vines, and a crow's-beak-shaped basin is set into the door at lock height.
To leave, you must brew the wizard's Unbinding Draught and pour it into that basin. One
of the three ingredients can only be given to you — never taken.

This guide follows one complete solve path, zone by zone, in the order a typical player
encounters things. Many steps can be done in a different order; see **Alternate routes**
at the end. All solutions are fixed — the exact answers below are always correct.

**How the game controls:** the side chevrons cycle between a zone's views. Tapping an
object of interest opens a close-up; leave a close-up with the down-chevron. Items are
used by dragging them from the inventory bar onto the scene, and combined by tapping one
inventory icon and then the other. Long-press an inventory icon to inspect the item.
Discovered passages (like the cellar trapdoor) are tapped to travel through.

---

## Part 1 — Main Cabin Room: gather clues and open the workshop

You start in the Main Cabin Room, which has three views: the **hearth**, the **study**,
and the **entry** (front door).

### Step 1. Take the iron poker

At the hearth, an iron poker leans against the fireplace. Take it. You will use it twice.

### Step 2. Read the grimoire

On the study desk sits the grimoire, browsable from the start. Tap it — it opens
directly at the black-feather-bookmarked page; page through for the rest. Three pages
matter:

- **Page A — element chart:** four element runes drawn beside pictograms (upward
  triangle = fire beside a flame; downward triangle = water beside a wave; upward
  triangle with bar = air beside a cloud; downward triangle with bar = earth beside a
  mountain). This tells you which rune means which element.
- **Page B — margin note:** a sun symbol beside a ring pictogram, and a crescent symbol
  beside a coin pictogram. Remember this for the workshop cabinet later.
- **The bookmarked page** (marked with a black feather) — the recipe. Pictograms show:
  a moonflower blossom crushed in a mortar; crescent-stamped metal filed into shavings;
  a black feather floating *into an open hand*; a flame beside numeral III; and a spiral
  with a counterclockwise arrowhead and five dots. This is the entire endgame in one
  page. The feather-into-open-hand image matters: the feather must be freely given.

The grimoire's other spreads (a zodiac wheel and a bird-anatomy diagram) are decoys.
They encode nothing — don't cross-reference the zodiac wheel against the astrolabe later;
the workshop *window* is the real star clue.

### Step 3. Solve the workshop rune lock (p01)

The heavy inner door in the study wall is barred by a rune lock. **Tap the lock's
press-plate on the door** to open the tile close-up: four pressable rune tiles, arranged
top to bottom FIRE, WATER, AIR, EARTH. The code is scattered around the room — each
element rune appears somewhere in the cabin next to a Roman numeral giving its press
order (tap each spot for a close-up):

| Where | Rune | Numeral |
|---|---|---|
| Hand bellows hanging to the right of the fireplace (scratched on handle) | AIR | I |
| Hearth lintel (scorched) | FIRE | II |
| Dead flowerpot in the study (on the clay side) | EARTH | III |
| Windowsill by the front door (etched) | WATER | IV |

If you're unsure of the Roman numerals, the mantel clock's face (I–XII) is your in-room
reference.

**Press the rune tiles in this exact order: AIR, FIRE, EARTH, WATER.**

A wrong sequence just resets the tiles with a dull knock — no penalty, unlimited tries.
The inner door opens: the **Potion Workshop** is now accessible.

> **Ignore:** the rusted bent key on its hook to the right of the front door. You can
> pocket it, but its bit is snapped and plain (long-press its inventory icon for a close
> look), and the cage's star-shaped socket visibly rejects it; it fits nothing in the
> level. Also, the mantel clock opens into a close-up with a movable hour hand — tap the
> face to advance it one numeral. The first time the hand reaches XII, a wooden
> cuckoo-crow pops out: a charming one-time touch, but no reward.

---

## Part 2 — Potion Workshop: the astrolabe and the cabinet

The workshop has two views: the **bench** (cauldron, bellows, mortar) and the
**cabinet** wall (ingredient cabinet, potion shelf, astrolabe, window).

### Step 4. Solve the astrolabe (p03)

Tap the brass astrolabe on its pedestal to open the plate-selection close-up: six
engraved star-pattern plates. Now look at the workshop window (tap it for a close-up of
the sky): the night sky shows **three bright stars in a short straight diagonal row**
between the trees — that is **Orion's Belt**, the signature of the constellation Orion.
(If you don't know Orion, simple dot-pattern matching also works: the window's star
arrangement — three aligned stars plus four shoulder/foot stars — matches exactly one
plate.)

**In the astrolabe close-up, select plate-2, the Orion plate (three aligned belt stars
with four shoulder/foot stars).**

The base drawer springs open and its contents go straight to your inventory: the
**silver coin** (stamped with a crescent) and the **winch crank handle**. Wrong plates
just knock and do nothing; no lockout.

### Step 5. Sift the hearth ash (p05)

Return to the Main Cabin Room's hearth. **Use the iron poker on the ash pile** in the
fireplace — tap the ash with the poker in your inventory, or drag the poker onto it. A
glint flashes in the stirred ash and you recover the **gold ring**, a plain round band.

### Step 6. Open the ingredient cabinet (p04)

Back in the workshop, the locked ingredient cabinet has two inset slots: a
circle-with-rays recess (sun) and a crescent recess (moon). In alchemical tradition the
sun stands for gold and the moon for silver — but you don't need to know that: the round
ring physically fits only the round sun recess, and the crescent-stamped coin fits only
the crescent recess, exactly as grimoire page B showed.

**Drag the gold ring onto the sun slot and the silver coin onto the moon slot.**

Wrong or swapped placements simply pop back out to your inventory with a knock. The
cabinet opens, yielding the **metal file** and the **empty glass phial**.

> **Ignore:** the shelf of stoppered potion bottles on the cabinet wall. They are
> inspectable but wax-fused shut, and their pictogram labels depict unrelated effects
> (sleep, frost, growth). None can be opened or poured; there is no shortcut potion.

---

## Part 3 — Hidden Cellar: the trapdoor under the rug

### Step 7. Find the trapdoor and study the triptych

In the Main Cabin Room, **tap the floor rug** by the hearth (a free action). It pulls
aside, revealing a trapdoor locked by three rotary dials, each embossed with the eight
moon-phase shapes. Tap the trapdoor to open the dial panel close-up.

The code is in the study: the **triptych** of three night paintings of the same tree
(tap each for a close-up). Each painting contains a number of crows and a moon:

- The painting with **one crow** shows a **waxing crescent** moon.
- The painting with **two crows** shows a **full** moon.
- The painting with **three crows** shows a **waning gibbous** moon.

Crow count = which dial (1st, 2nd, 3rd); moon shape = what to set it to. Each dial
advances one phase per tap, and the notch marker at the top of each dial shows which
phase is currently selected; the lock checks itself after every change.

**Set the dials, left to right: waxing crescent, full, waning gibbous.**

Careful — waxing and waning phases are mirror images of each other. You don't need any
moon knowledge; just copy the exact silhouette orientation from each painting onto the
matching dial. A waxing crescent and a waning crescent face opposite directions, as do
the two gibbous shapes. The dials keep their positions between attempts; no lockout.

The trapdoor opens, revealing the **Hidden Cellar** (this is the hidden-zone reveal —
it only exists once the rug is moved and the dial code is entered). Tap the open
trapdoor to climb down.

### Step 8. Take the silver spoon

A small drawer in the root shelf holds a **tarnished silver spoon**. Take it. Its bowl
is stamped with the same crescent hallmark as the coin — that hallmark identifies it as
silver, which is what the recipe's "crescent-stamped metal, filed" pictogram calls for.

### Step 9. Pry the barrel (p06)

**Use the iron poker on the nailed barrel lid** beside the ladder (a pry gap is visible
in close-up). Inside is the **iron plumb weight** — it goes to your inventory. (The
pried barrel keeps showing a weight nestled inside afterwards; that's just the scene
art — you already have it.)

### Step 10. Hang the counterweight (p07) — opens the Walled Alcove

A heavy sliding shelf sits flush against the far wall, with an empty counterweight hook
and pulley above it, rope visibly connected to the shelf runners.

**Drag the iron weight onto the empty pulley hook.** The shelf rolls aside, revealing the
**Walled Alcove** — a hidden zone nested inside the hidden cellar.

### Step 11. Take the cage key from the alcove

In the alcove niche, a carved wooden crow statue holds a small **star-bit key** in its
beak. Take it. You'll also see a planter of moonflowers with tightly closed buds — they
need moonlight, which comes next.

---

## Part 4 — Route the moonbeam and bloom the moonflowers

### Step 12. Open the light-shaft shutter (p08)

In the cellar ceiling is a vertical light shaft with a closed wooden shutter, worked by
a winch that is missing its handle. **Drag the winch crank handle** (from the astrolabe
drawer) **onto the winch's empty square socket.** The shutter cranks open and a vertical
moonbeam falls onto the cellar floor near the mirror stand.

### Step 13. Aim the mirror (p09)

The tilting mirror on the floor stand cycles through three detent positions — tap it to
advance one detent at a time. Faint scratch marks are worn into the floor at the
**third detent** — the wizard's own habitual setting.

**Set the mirror to detent-3.** If the beam is already falling, the reflected beam
visibly sweeps as the mirror turns and enters the alcove doorway at the third detent.

Steps 12 and 13 work in **either order**. If you set the mirror to detent-3 before ever
opening the shutter (the scratch marks alone justify it), the beam routes into the
alcove the instant the shutter opens. Nothing here is timed and both states persist.

### Step 14. Pick a moonflower blossom (p10)

With the beam routed into the alcove, the moonflower buds open. (You may already have
noticed the buds trembling the moment the beam first appeared anywhere in the cellar —
that's your cue that light is what they want.) **Tap a blossom to pick it.** The bloom
stays available as long as the beam holds — which is forever, since neither the shutter
nor the mirror ever resets.

---

## Part 5 — Free the crow, prepare the ingredients

### Step 15. Free the crow (p11) — the freely given feather

Return to the Main Cabin Room's entry view. **Do not reach into the cage** — the crow
snaps once, turns its back, and guards its wing. That refusal is final: repeating it
produces the identical closed-off pose every time. It will never work; the recipe showed
the feather floating *into an open hand* — freely given, not taken. Offering the crow
anything at its brass feed cup earns the same refusal, and the item comes straight
back — there is no food puzzle.

The cage has a tiny star-shaped keyhole. **Use the star-bit cage key** (from the alcove
statue) — tap the keyhole with the key in your inventory, or drag the key onto the cage.
(If you try the rusted key instead, the star socket visibly rejects its plain bit.) The
crow flies up to the rafters, preens, and one **black feather** drifts down to you. The
crow stays perched for the rest of the level.

### Step 16. File silver shavings (p12)

**Combine the metal file with the silver spoon** — tap one of them in the inventory bar,
then tap the other (either order); or drag either one onto the workbench in the
workshop's bench view. You get **silver shavings**.

### Step 17. Grind the moonflower paste (p13)

At the workshop bench, **drag the blossom onto the fixed mortar.** It is ground with the
pestle into **moonflower paste**.

---

## Part 6 — Brew, bottle, and escape

### Step 18. Brew the Unbinding Draught (p14)

At the cauldron of clear water, everything the recipe page encoded comes together. Tap
the cauldron to open the brew close-up; the flame and ladle are worked with its buttons:

1. **Set the flame to stage III.** Tap **Pump Bellows**; each pump raises the flame
   stage, cycling 1 → 2 → 3 → 1. The current stage is shown by flame height *and* by
   which embossed rim numeral (I / II / III) has its ember channel lit. Stop when
   **III** is lit. (Recipe cue: the flame pictogram beside numeral III.)
2. **Add all three ingredients — drag the moonflower paste, silver shavings, and black
   feather onto the cauldron, in any order.** Ingredient order does not matter.
3. **Tap Stir CCW (counterclockwise) exactly 5 times, then tap Release Ladle.** The
   ripple trail in the liquid shows which way you are stirring. (Recipe cue: the spiral
   with the counterclockwise arrowhead and five dots along it.)

**Success:** the liquid takes on a pearlescent sheen with a slow spiral pattern moving
across its surface — watch for the *pattern*, not a color change.

**Failure** (wrong flame stage, wrong stir direction, or wrong count): a gray fizzle
puff, and all three ingredients float to the surface intact and return to your
inventory. Nothing is ever lost; reset the flame if needed and try again. The failure
cue is the same regardless of which parameter was wrong, so double-check all three:
flame **III**, stir **CCW**, count **5**.

### Step 19. Fill the phial (p15)

**Drag the empty glass phial onto the ready cauldron.** You now hold the **Phial of
Unbinding Draught**. The cauldron stays draught-ready afterward, so a refill always
exists — though in practice the draught can never be lost (see the note below).

### Step 20. Feed the door (p16)

At the front door, **drag the phial onto the crow's-beak rune basin** set into the door
directly over the vine-wrapped bolt. The thorn-vines wither and crumble off the bolt.

> **Do not bother pouring the draught into the crow's brass feed cup** on the cage — the
> pour is blocked. While the crow is caged it gives the same closed-off refusal it gives
> everything offered at the cup; once it's freed, the cup is inert scenery. Either way
> the phial returns to your inventory unspent. The rune basin is the only pour target
> that advances the game.

### Step 21. Escape (p17)

**Tap the bolt.** It slides, the door opens, and the crow flies out over your shoulder
into the moonlit woods. Level complete — the completion card offers Main Menu or Play
Again.

---

## Alternate routes (footnotes)

The level has two parallel mid-game branches — the **workshop** branch (rune door →
astrolabe → cabinet) and the **cellar** branch (trapdoor → barrel → shelf → alcove) —
and they can be opened and interleaved in any order that respects item prerequisites.
The path above opens the workshop first. Notable variations:

- **Cellar first:** you can move the rug, solve the moon dials, and clear the entire
  cellar/alcove chain (poker → barrel → weight → shelf → cage key → free the crow)
  before ever touching the workshop rune lock. You will still need the workshop for the
  crank (light shaft), the file (shavings), the mortar, and the cauldron.
- **Mirror before shutter:** setting the mirror to detent-3 before opening the shutter
  is fully supported; the beam routes into the alcove the moment the shutter opens. And
  if you route the beam at detent-3 before hanging the counterweight, it ends in a
  bright spot **on the closed shelf face** — a "blocked, look here" cue, not a bug.
- **Crow timing:** the crow can be freed any time after you hold the cage key — before
  or after brewing prep. The feather has exactly one use (the brew) and cannot be lost;
  a failed brew returns it.
- **Ingredient prep order:** shavings, paste, and the feather can be produced in any
  order, and added to the cauldron in any order.

The only hard cross-links between branches: the **crank** (workshop astrolabe) is needed
for the cellar light shaft, and the **file** (workshop cabinet) is needed with the
cellar spoon. Everything else interleaves freely.

## Quick answer key

| Puzzle | Answer |
|---|---|
| Workshop rune lock (p01) | In the lock close-up, press AIR, FIRE, EARTH, WATER |
| Trapdoor moon dials (p02) | Waxing crescent, full, waning gibbous (orientation matters) |
| Astrolabe (p03) | Select plate-2 — Orion (three aligned belt stars + four outliers) |
| Cabinet slots (p04) | Gold ring → sun slot; silver coin → moon slot |
| Hearth ash (p05) | Poker on ash pile → gold ring |
| Barrel (p06) | Poker on nailed lid → iron weight |
| Sliding shelf (p07) | Drag iron weight onto pulley hook |
| Light shaft (p08) | Drag crank handle onto winch socket |
| Mirror (p09) | Tap to detent-3 (floor scratch marks) |
| Moonflowers (p10) | Beam in alcove → tap a blossom |
| Crow (p11) | Star-bit key on the star keyhole; never reach in |
| Shavings (p12) | Combine file + silver spoon (inventory taps, or drop on workbench) |
| Paste (p13) | Drag blossom onto mortar |
| Brew (p14) | Pump flame to stage III; drag in paste + shavings + feather (any order); Stir CCW ×5; Release Ladle |
| Bottle (p15) | Drag empty phial onto ready cauldron |
| Door (p16) | Pour phial into the door's rune basin |
| Escape (p17) | Tap the bolt |

---

*FINAL — reconciled 2026-07-06 against `puzzle-graph.json` rev 1.2, the Developer's
implementation notes (including the shipped tap/button controls for the moon dials,
astrolabe, clock, and brew, the rug-discovery/close-up navigation, the D1 feed-cup
BLOCK, and the BUG-004 re-framed scene layouts), and the re-QA GO verdict in
`qa-report.md`. All fixed solution values are identical to the draft.*
