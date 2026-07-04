# Level 1 — The Wizard's Cabin — Walkthrough

**STATUS: DRAFT (first pass)** — written against `puzzle-graph.json` spec revision 1.1,
after Validator approval and the user checkpoint. This draft will be reconciled against
the QA report and the Developer's implementation notes in a second pass before it is
final. Items marked **[VERIFY IN SECOND PASS]** depend on implementation choices that
were still open when this draft was written.

---

*"The wizard is gone. The crow remains."*

You wake at night in an abandoned wizard's cabin. The front door's bolt is sealed under
living thorn-vines, and a crow's-beak-shaped basin is set into the door at lock height.
To leave, you must brew the wizard's Unbinding Draught and pour it into that basin. One
of the three ingredients can only be given to you — never taken.

This guide follows one complete solve path, zone by zone, in the order a typical player
encounters things. Many steps can be done in a different order; see **Alternate routes**
at the end. All solutions are fixed — the exact answers below are always correct.

---

## Part 1 — Main Cabin Room: gather clues and open the workshop

You start in the Main Cabin Room, which has three views: the **hearth**, the **study**,
and the **entry** (front door).

### Step 1. Take the iron poker

At the hearth, an iron poker leans against the fireplace. Take it. You will use it twice.

### Step 2. Read the grimoire

On the study desk sits the grimoire, browsable from the start. Three pages matter:

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

The heavy inner door in the study wall is barred by a lock with four pressable rune
tiles. The code is scattered around the room — each element rune appears somewhere in
the cabin next to a Roman numeral giving its press order:

| Where | Rune | Numeral |
|---|---|---|
| Hand bellows hung by the hearth (scratched on handle) | AIR | I |
| Hearth lintel (scorched) | FIRE | II |
| Dead flowerpot in the study (on the clay side) | EARTH | III |
| Windowsill by the front door (etched) | WATER | IV |

If you're unsure of the Roman numerals, the mantel clock's face (I–XII) is your in-room
reference.

**Press the rune tiles in this exact order: AIR, FIRE, EARTH, WATER.**

A wrong sequence just resets the tiles with a dull knock — no penalty, unlimited tries.
The inner door opens: the **Potion Workshop** is now accessible.

> **Ignore:** the rusted bent key on the hook beside the front door. Its bit is snapped
> and plain (visible in close-up); it fits nothing in the level. Also, setting the
> mantel clock hands to XII pops a wooden cuckoo-crow — a charming touch, but no reward.

---

## Part 2 — Potion Workshop: the astrolabe and the cabinet

The workshop has two views: the **bench** (cauldron, bellows, mortar) and the
**cabinet** wall (ingredient cabinet, potion shelf, astrolabe, window).

### Step 4. Solve the astrolabe (p03)

The brass astrolabe on the pedestal has a rotating pointer and six engraved star-pattern
plates. Look at the workshop window: the night sky shows **three bright stars in a
short straight diagonal row** between the trees — that is **Orion's Belt**, the
signature of the constellation Orion. (If you don't know Orion, simple dot-pattern
matching also works: the window's star arrangement — three aligned stars plus four
shoulder/foot stars — matches exactly one plate.)

**Rotate the pointer to plate-2, the Orion plate (three aligned belt stars with four
shoulder/foot stars).**

The base drawer springs open, yielding the **silver coin** (stamped with a crescent)
and the **winch crank handle**. Wrong plates do nothing; no lockout.

### Step 5. Sift the hearth ash (p05)

Return to the Main Cabin Room's hearth. **Use the iron poker on the ash pile** in the
fireplace (a faint glint is visible in close-up). You recover the **gold ring**, a plain
round band.

### Step 6. Open the ingredient cabinet (p04)

Back in the workshop, the locked ingredient cabinet has two inset slots: a
circle-with-rays recess (sun) and a crescent recess (moon). In alchemical tradition the
sun stands for gold and the moon for silver — but you don't need to know that: the round
ring physically fits only the round sun recess, and the crescent-stamped coin fits only
the crescent recess, exactly as grimoire page B showed.

**Place the gold ring in the sun slot and the silver coin in the moon slot.**

Wrong or swapped placements simply pop back out to your inventory. The cabinet opens,
yielding the **metal file** and the **empty glass phial**.

> **Ignore:** the shelf of stoppered potion bottles. They are wax-fused shut and their
> pictogram labels depict unrelated effects (sleep, frost, growth). None can be opened
> or poured; there is no shortcut potion.

---

## Part 3 — Hidden Cellar: the trapdoor under the rug

### Step 7. Find the trapdoor and study the triptych

In the Main Cabin Room, **move the floor rug** by the hearth (a free action). Beneath it
is a trapdoor locked by three rotary dials, each embossed with the eight moon-phase
shapes.

The code is in the study: the **triptych** of three night paintings of the same tree.
Each painting contains a number of crows and a moon:

- The painting with **one crow** shows a **waxing crescent** moon.
- The painting with **two crows** shows a **full** moon.
- The painting with **three crows** shows a **waning gibbous** moon.

Crow count = which dial (1st, 2nd, 3rd); moon shape = what to set it to.

**Set the dials, left to right: waxing crescent, full, waning gibbous.**

Careful — waxing and waning phases are mirror images of each other. You don't need any
moon knowledge; just copy the exact silhouette orientation from each painting onto the
matching dial. A waxing crescent and a waning crescent face opposite directions, as do
the two gibbous shapes. The dials keep their positions between attempts; no lockout.

The trapdoor opens, revealing the **Hidden Cellar** (this is the hidden-zone reveal —
it only exists once the rug is moved and the dial code is entered). Climb down.

### Step 8. Take the silver spoon

A small drawer in the root shelf holds a **tarnished silver spoon**. Take it. Its bowl
is stamped with the same crescent hallmark as the coin — that hallmark identifies it as
silver, which is what the recipe's "crescent-stamped metal, filed" pictogram calls for.

### Step 9. Pry the barrel (p06)

**Use the iron poker on the nailed barrel lid** (a pry gap is visible at the rim).
Inside is the **iron plumb weight**.

### Step 10. Hang the counterweight (p07) — opens the Walled Alcove

A heavy sliding shelf sits flush against the far wall, with an empty counterweight hook
and pulley above it, rope visibly connected to the shelf runners.

**Hang the iron weight on the empty pulley hook.** The shelf rolls aside, revealing the
**Walled Alcove** — a hidden zone nested inside the hidden cellar.

### Step 11. Take the cage key from the alcove

In the alcove niche, a carved wooden crow statue holds a small **star-bit key** in its
beak. Take it. You'll also see a planter of moonflowers with tightly closed buds — they
need moonlight, which comes next.

---

## Part 4 — Route the moonbeam and bloom the moonflowers

### Step 12. Open the light-shaft shutter (p08)

In the cellar ceiling is a vertical light shaft with a closed wooden shutter, worked by
a winch that is missing its handle. **Fit the winch crank handle** (from the astrolabe
drawer) **to the winch's empty square socket and turn it.** The shutter opens and a
vertical moonbeam falls onto the cellar floor near the mirror stand.

### Step 13. Aim the mirror (p09)

The tilting mirror on the floor stand rotates through three detent positions. Faint
scratch marks are worn into the floor at the **third detent** — the wizard's own habitual
setting.

**Rotate the mirror to detent-3.** The reflected beam sweeps as you rotate and enters
the alcove doorway at the third detent.

Steps 12 and 13 work in **either order**. If you set the mirror to detent-3 before ever
opening the shutter (the scratch marks alone justify it), the beam routes into the
alcove the instant the shutter opens. Nothing here is timed and both states persist.

### Step 14. Pick a moonflower blossom (p10)

With the beam routed into the alcove, the moonflower buds open. (You may already have
noticed the buds trembling the moment the beam first appeared anywhere in the cellar —
that's your cue that light is what they want.) **Pick one blossom.** The bloom stays
available as long as the beam holds — which is forever, since neither the shutter nor
the mirror ever resets.

---

## Part 5 — Free the crow, prepare the ingredients

### Step 15. Free the crow (p11) — the freely given feather

Return to the Main Cabin Room's entry view. **Do not reach into the cage** — the crow
snaps once, turns its back, and guards its wing. That refusal is final: repeating it
produces the identical closed-off pose every time. It will never work; the recipe showed
the feather floating *into an open hand* — freely given, not taken.

The cage has a tiny star-shaped keyhole. **Use the star-bit cage key** (from the alcove
statue) **on the cage and open the door.** The crow flies up to the rafters, preens, and
one **black feather** drifts down to you. The crow stays perched for the rest of the
level (and will later perch above the door basin — a silent nudge).

### Step 16. File silver shavings (p12)

**Combine the metal file with the silver spoon** (works directly in inventory; the
workbench close-up also accepts it). You get **silver shavings**.

### Step 17. Grind the moonflower paste (p13)

At the workshop bench, **place the blossom in the fixed mortar and grind it** with the
pestle. You get **moonflower paste**.

---

## Part 6 — Brew, bottle, and escape

### Step 18. Brew the Unbinding Draught (p14)

At the cauldron of clear water, everything the recipe page encoded comes together:

1. **Set the flame to stage III.** Pump the large floor bellows; each pump raises the
   flame stage, cycling 1 → 2 → 3 → 1. The current stage is shown by flame height *and*
   by which embossed rim numeral (I / II / III) has its ember channel lit. Stop when
   **III** is lit. (Recipe cue: the flame pictogram beside numeral III.)
2. **Add all three ingredients — moonflower paste, silver shavings, black feather — in
   any order.** Ingredient order does not matter.
3. **Stir the ladle counterclockwise exactly 5 times, then release it.** (Recipe cue:
   the spiral with the counterclockwise arrowhead and five dots along it.)

**Success:** the liquid takes on a pearlescent sheen with a slow spiral pattern moving
across its surface — watch for the *pattern*, not a color change.

**Failure** (wrong flame stage, wrong stir direction, or wrong count): a gray fizzle
puff, and all three ingredients float to the surface intact and return to your
inventory. Nothing is ever lost; reset the flame if needed and try again. The failure
cue is the same regardless of which parameter was wrong, so double-check all three:
flame **III**, stir **counterclockwise**, count **5**.

### Step 19. Fill the phial (p15)

**Use the empty glass phial on the ready cauldron.** You now hold the **Phial of
Unbinding Draught**. The cauldron stays draught-ready afterward, so the phial can always
be refilled if the draught is ever spent elsewhere.

### Step 20. Feed the door (p16)

At the front door, **pour the phial into the crow's-beak rune basin** set into the door
directly over the vine-wrapped bolt. (If you freed the crow, it is perched on the lintel
right above the basin.) The thorn-vines wither and crumble off the bolt.

> **Do not pour the draught into the crow's brass feed cup** on the cage — the rune
> basin is the only pour target that advances the game. Per the current spec the pour
> onto the feed cup is expected to be **blocked** (the crow shakes its head and the
> phial returns to your inventory unspent). If the shipped build instead *allows* the
> mis-pour, no harm done: return to the still-ready cauldron and refill the phial
> (Step 19). **[VERIFY IN SECOND PASS — developer_notes D1: block vs. allow was an open
> implementation choice at draft time; confirm which behavior shipped and simplify this
> note accordingly.]**

### Step 21. Escape (p17)

**Slide the bolt and open the door.** The crow flies out over your shoulder into the
moonlit woods. Level complete.

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
  is fully supported; the beam routes into the alcove the moment the shutter opens.
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
| Workshop rune lock (p01) | Press AIR, FIRE, EARTH, WATER |
| Trapdoor moon dials (p02) | Waxing crescent, full, waning gibbous (orientation matters) |
| Astrolabe (p03) | Plate-2 — Orion (three aligned belt stars + four outliers) |
| Cabinet slots (p04) | Gold ring → sun slot; silver coin → moon slot |
| Hearth ash (p05) | Poker on ash pile → gold ring |
| Barrel (p06) | Poker on nailed lid → iron weight |
| Sliding shelf (p07) | Hang iron weight on pulley hook |
| Light shaft (p08) | Crank handle on winch, turn |
| Mirror (p09) | Detent-3 (floor scratch marks) |
| Moonflowers (p10) | Beam in alcove → pick blossom |
| Crow (p11) | Star-bit key on cage; never reach in |
| Shavings (p12) | File + silver spoon |
| Paste (p13) | Blossom in mortar, grind |
| Brew (p14) | Flame stage III; add paste + shavings + feather (any order); stir counterclockwise 5 times |
| Bottle (p15) | Empty phial on ready cauldron |
| Door (p16) | Pour phial into the door's rune basin |
| Escape (p17) | Slide bolt, open door |

---

*Draft prepared against puzzle-graph.json rev 1.1 (2026-07-04). Second pass will
reconcile against `qa-report.md` and the Developer's implementation notes — in
particular the D1 feed-cup behavior (Step 20) and any brew-failure feedback
differentiation the Designer may add per Validator advisory (judgment call 3).*
