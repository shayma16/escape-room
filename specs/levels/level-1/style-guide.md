# Level 1 Style Guide — The Wizard's Cabin

*Art Director deliverable. Governs puzzle-graph.json spec revision 1.2. This is Level 1,
so Sections 1–3 and 7–9 also seed the series-wide look; per-level sections are 4–6.
Downstream consumer: Asset Generation Agent (Flux 2 Pro via fal.ai) and Developer Agent.*

**Framing line (the only text in the level, title card only):**
*"The wizard is gone. The crow remains."*

---

## 1. Global visual style (series seed)

### 1.1 Rendering language
- **Pre-rendered painterly realism.** Static scenes that read as carefully lit renders
  with an oil-painting surface: precise single-point perspective underneath, soft
  brush-textured light on top. Reference register: neutralxe's Room Escape series
  (Vision, Sign), Myst/Riven interiors. Never cel-shaded, never photo-real-clinical,
  never concept-art loose.
- **One fixed camera per view.** Eye level ~150 cm, lens equivalent 28–35 mm, verticals
  held near-vertical. No fisheye, no dutch angles. Close-up sub-views may go tighter
  (50–70 mm equivalent) and higher-angle where legibility demands (see brew view, 5.4).
- **No text anywhere in scene art.** All signage, labels, and book content is
  pictographic. No letters, no numbers except Roman numerals where the graph specifies
  them (clock ring, rune marks, cauldron rim) — Roman numerals are treated as glyphs.
- **No humans, no human remains.** The wizard's absence is told through objects: a chair
  worn on one arm, a cold pipe, dust sheets, one cup. Melancholy, quiet dread — never
  horror. No gore, no skulls-as-decor, no jump-scare framing.

### 1.2 Materials & texture direction
- Aged, hand-made, once-loved: waxed dark oak, rough-hewn beams, iron with rust bloom
  only at edges, brass with fingerprint-dulled polish, wax-crusted candle stubs, thick
  rippled window glass, dust films broken where the player (and the story) touches.
- Magic is *residue*, not spectacle: faint rune scorches, a lingering sheen, moonflowers.
  No floating particles or glowing auras except where the graph demands feedback (ember
  channels, draught sheen, beam, blooming flowers).
- Dust motes in light shafts are the level's signature atmospheric particle. Use them in
  every strong beam (entry window, workshop window patch, cellar moonbeam).

### 1.3 Composition rules
- One dominant light direction per view; every interactive element receives either direct
  key light or a deliberate rim/edge light. **Gloom never hides a hotspot.**
- Puzzle-critical elements sit on rule-of-thirds intersections or on the natural eye path
  toward them; nothing puzzle-critical is overlapped by foreground props or cropped by
  frame edges (see device dual-safe zone, Section 8).
- Depth staging: foreground shadow mass → mid-ground playfield (all interaction here) →
  background atmosphere (windows, sky, dark corners). Interaction lives in mid-ground.

---

## 2. Palette, lighting, and color-blind contrast rules (series seed)

### 2.1 Master palette
| Role | Swatch | Hex anchor |
|---|---|---|
| Night sky zenith | deep indigo-black | `#0E1626` |
| Night sky horizon glow | slate blue | `#1B2838` |
| Moonlight key / beam core | pale silver-blue | `#DCE8F2` |
| Moonlight fill | cool gray-blue | `#8FA3B5` |
| Star / bone white accents | warm white | `#F2F5F8` |
| Cabin oak shadow | deep umber | `#3A2C1E` |
| Cabin oak mid | aged brown | `#6B5238` |
| Warm light (lamp/ember) | amber | `#D9973F` |
| Warm light deep | burnt orange-brown | `#A05C22` |
| Brass/gold accents | dulled gold | `#C7A24B` |
| Silver/iron accents | cool pewter | `#C4C9CE` / `#5B6066` |
| Ash, stone | warm-gray / blue-gray | `#7A7672` / `#5A6672` |
| Cellar earth | dark loam | `#3B3128` |
| Thorn vines (alive → withered) | gray-green → dry tan | `#4C5546` → `#6E5F4A` |
| Moonflower petals | luminous pale blue-white | `#E6F0F5` |

Saturation ceiling: nothing above ~45% saturation except the amber ember channel glints
and the moonflower glow, which may peak briefly during feedback moments.

### 2.2 Lighting language — the warm/cool duet
The whole level is a conversation between **cold moonlight** (the outside, the sky, the
crow's world) and **dying warm light** (the wizard's leftover lamps and embers, the
indoor world). Each zone sets a different mix ratio (Section 4). This duet is tonal, not
informational: **no puzzle state is ever encoded in warm-vs-cool alone.**

### 2.3 Color-blind contrast mandate (binding, from `colorblind_safety`)
Every graded scene and every state variant must pass a **grayscale check**: convert to
luminance-only and confirm the cue still reads. Specific bindings:
1. **Moon phases (triptych + trapdoor dials):** pure silhouette. Dials: lit portion is
   *raised polished relief*, dark portion is *recessed matte with ambient-occlusion
   shadow* — shape + relief + luminance, zero hue reliance. Terminator edge is a hard
   edge, never a soft gradient. Same one-side-lit logic in the paintings, with the tree
   as a fixed left/right landmark in all three (Section 5.2).
2. **Element runes:** distinct geometric glyphs (triangles/bars), always paired with
   their pictogram on grimoire page A; engraved/scorched so a rim highlight catches the
   groove edge in close-up.
3. **Gold ring vs silver coin:** differentiated by *form* — plain round band vs
   crescent-stamped disc — plus slot shape fit and hallmark stamps. Metal hue is flavor
   only; both must be identifiable in grayscale by silhouette and stamp.
4. **Flame stages 0–3:** flame *height* steps clearly (each stage ~1.6× the last) AND
   exactly one embossed rim rune (I/II/III) has its ember channel lit — the lit channel
   glows *and* visibly fills with molten texture (pattern cue). Flame hue stays constant
   warm amber across all stages; hue never encodes stage.
5. **Brew success:** pearlescent sheen + **slow spiral surface pattern** animation. The
   spiral pattern is the cue; the sheen is garnish. Failure fizzle = matte gray puff +
   flat surface: pattern difference, not color difference.
6. **Potion-shelf red herrings:** ≥5 clearly distinct bottle *silhouettes* + pictogram
   labels + identical fused-wax stoppers. Liquid colors may vary but are deliberately
   muted and never load-bearing.
7. **Luminance ladder rule (global):** any interactive element sits ≥ 2 value steps
   (~20% luminance) apart from its immediate background field, via key light or rim.

---

## 3. The canonical night sky (binding continuity spec)

**User-approved constraint:** one consistent, clear night sky across the z1 entry window,
the z2 workshop window, and the z3/z4 moonbeam — moon AND Orion (three-in-a-row belt)
simultaneously visible.

Define **one sky master plate** that all windows crop from:
- **Moon:** waxing gibbous, ~85% illuminated, **lit side on the right**, riding high in
  the sky (high altitude justifies the vertical cellar light shaft). Cold silver disc
  with visible maria texture; soft halo, no lens flare.
  - *Why waxing gibbous:* bright enough to carry the moonbeam and the moonlit woods, and
    it is **none of the three p02 dial answers** (waxing crescent / full / waning
    gibbous), so the live sky can never be copied into a correct dial. It *is* the mirror
    of the dial-3 answer — acceptable because the triptych is the authoritative clue and
    a window-copy attempt fails, but flagged in Section 10.
- **Orion:** below and to the right of the moon. Belt = three equal-brightness stars in a
  short straight diagonal row (~35° tilt), plus the four fainter shoulder/foot stars —
  the seven-dot pattern **must exactly match astrolabe plate-2's engraving** (same
  proportions, same tilt handedness). Surrounding field stars are markedly fainter and
  **must never form a rival three-in-a-row line** anywhere in either window crop.
- **Crops:** z1 entry window frames the moon large, upper third, with Orion's belt fully
  visible in the lower part of the pane between tree silhouettes. z2 workshop window
  frames Orion centered between trees (the p03 clue read), with the moon smaller but
  fully in frame at the top corner. Same star field, same handedness, same tilt in both.
- **Beam continuity:** every moonlight source in the level (entry window pool, workshop
  window patch, cellar shaft beam, alcove beam) shares the identical color temperature
  (`#DCE8F2` core) and dust-mote treatment, so the player subconsciously reads one moon.
- The triptych paintings depict *three different past nights* and are painted artifacts —
  their moons intentionally differ from the live sky and from each other.

---

## 4. Per-zone mood and lighting

Tonal throughline: all four zones share the same night, the same wood-and-earth material
family, and the same warm/cool duet — but each zone owns a distinct mix ratio and key.

### z1 — Main Cabin Room: "the held breath"
- **Mix:** 60% cool / 40% warm. Key light = moonlight through the entry window (long
  pale pool across the floorboards). Warm fill = one low-burning oil lamp on the study
  desk plus a stub candle on the mantel (*ambient set dressing, non-interactive — see
  flag F2*). The hearth is **cold** — dead gray ash, no ember glow.
- Mood: hushed, recently-left, dust in the moonlight. The crow's cage sits half in the
  window's cold light. Melancholy carried by stillness, not decay.
- Value range: mid-dark; the darkest corners still show detail at 15% luminance.

### z2 — Potion Workshop: "the warm heart, still beating"
- **Mix:** 35% cool / 65% warm — the warmest zone. Key = fire pit under the cauldron
  (under-lighting on the cauldron belly, copper glints across hanging tools and bottle
  glass). Accent = a cold slab of Orion-window light across the cabinet end of the room.
- Mood: the one room that feels like the wizard just stepped out — worked-in clutter,
  herbs drying, apparatus dusted by use rather than neglect.
- The two zones of the room read as a warm bench half and a cool cabinet half; the
  player's eye travels warm → cool → the window.

### z3 — Hidden Cellar: "under the floor, under the story"
- **Mix (shutter closed):** 80% dark / 20% warm. Key = weak warm spill from the open
  trapdoor above plus one small hanging lantern near the ladder (*ambient dressing, flag
  F2*). Earthen walls swallow light; the sliding shelf and barrel emerge from gloom with
  edge light only. Coolest darks in the level.
- **Mix (shutter open):** the moonbeam **owns the room** — a hard volumetric silver
  column, dust motes, hard-edged floor ellipse. Everything else drops half a stop; the
  beam re-lights the mirror, shelf face, and scratch marks by bounce.
- Mood: buried, root-smelling, slightly dreadful — the one zone allowed to feel cold in
  the chest. Still no horror staging.

### z4 — Walled Alcove: "the kept secret"
- **Mix:** near-monochrome silver — 90% cool. Before the beam arrives: readable by dim
  cellar spill only (lowest ambient in the game, but the statue and planter still carry
  rim light per the luminance ladder). With the beam redirected in: a single sanctified
  shaft on the moonflower planter; the crow statue catches the bounce, key glinting in
  its beak.
- Mood: reverent, shrine-like. This is the emotional counterweight to the cage in z1 —
  the wizard *built a room for the crow's flower*. Quiet awe, not dread.

---

## 5. Scene composition briefs (one per camera view)

Every element listed is from the Designer's spec; nothing added or moved. Each brief
lists: framing, element placement, required close-up sub-views, and the state variants
the Asset agent must cover (drawn from `visually_necessary_elements` — that JSON block
remains the authoritative checklist; this section is its composition translation).

### 5.1 z1 / v-hearth — "the cold fire"
**Framing:** fireplace centered-left on the back wall; mantel at upper-third line;
armchair right foreground edge (must not occlude the rug); rug center-floor, clearly a
liftable object (corner slightly curled).
**Placement intent:**
- **Fireplace + ash pile** — firebox interior readable; ash a soft gray mound.
  *States:* undisturbed / sifted-with-glint (a small warm glint in raked furrows —
  luminance sparkle + circular silhouette, not color) / ring-taken (furrows, no glint).
- **Iron poker** — leaning against hearth surround, catching lamp rim light; silhouette
  reads "tool" instantly. *States:* present / taken.
- **Mantel clock** — center mantel, face angled to camera. Roman numeral ring I–XII
  **fully legible in every state** (bone-white numerals on dark face, raised relief).
  Movable hands visually distinct lengths. Cuckoo door above the XII.
  *States (per D5):* (1) unspent, door shut; (2) first-XII pop — the toy crow emerges:
  **crude lathe-carved, round-bodied, paint-chipped, painted dot eyes** — unmistakably a
  toy (see crow registers, 5.8); (3) spent — door hangs ajar, toy tipped over on a
  visibly limp broken coil spring, inert. Numeral ring unobstructed in all three.
- **Hand bellows** — hung on a nail beside the hearth; AIR rune + numeral I scratched on
  the handle (subtle at wide, crisp at close-up).
- **FIRE rune + numeral II** — scorched into the hearth lintel; charred groove with
  rim-lit edges.
- **Rug** — *States:* flat / moved (folded back revealing trapdoor).
- **Trapdoor + three moon-phase dials** — iron-banded wood; three rotary dials in a row,
  each with 8 embossed phase silhouettes. **Load-bearing legibility (A5/R5):** relief
  treatment per Section 2.3(1); at the dial close-up each dial face spans ≥ 30% of
  iPhone screen width; waxing/waning mirror pairs unmistakable at that size.
  *States:* locked / open (dark stair mouth, cool air haze).
**Close-ups:** ash pile (3 states) · clock face (all states) · bellows rune · lintel
rune · trapdoor dial panel (interactive) · open trapdoor.

### 5.2 z1 / v-study — "the wizard's mind"
**Framing:** writing desk center-right under the oil lamp (warmest pocket of z1);
triptych on the wall above/left of the desk at eye height; bookshelf far left;
**workshop inner door** right of frame — heavy, iron-strapped, with the four-rune
press-lock plate at hand height.
**Placement intent:**
- **Grimoire** — open on the desk, fixed, in lamplight; the **black-feather bookmark**
  protrudes conspicuously (glossy black against parchment — silhouette cue).
  *Page spreads (each a separate close-up plate, parchment texture, iron-gall-ink
  pictograms, zero text):*
  - **Page A** — four element runes beside pictograms (flame / wave / cloud / mountain).
  - **Page B margin** — sun symbol beside ring pictogram; crescent beside coin pictogram.
  - **Recipe page** (feather-bookmarked) — moonflower + pestle; crescent-metal filed to
    slivers; feather drifting *into an open hand*; flame + III; **spiral with CCW
    arrowhead and five dots**. Spiral drawn as seen from directly above, winding outward
    counterclockwise — handedness locked to the brew view (see 5.4 and R3).
  - **Decoy: zodiac wheel** — visually non-systematic, even line weight, **no highlighted
    constellation**, no dot-pattern echo of plate-2.
  - **Decoy: bird anatomy** — soft graphite study of a crow; gentle foreshadowing, no
    diagram callouts that could read as code.
- **Triptych** — three small framed night paintings of the *same tree*, hung as a row.
  Crow counts 1 / 2 / 3; moons waxing-crescent / full / waning-gibbous. **The tree sits
  on the same side of frame in all three** so left/right (lit-side) reads consistently;
  painted terminators crisp per 2.3(1). Painted-artifact style (visible brushwork,
  craquelure) so they never read as windows.
- **Dead flowerpot** — desk corner or windows-side shelf; EARTH rune + numeral III on the
  clay, legible in close-up.
- **Bookshelf** — inert decoy spines, uniform and dust-veiled: deliberately *boring* at
  close inspection (no titles, no odd book out).
- **Workshop rune door** — four pressable rune tiles in a vertical brass plate; tiles
  have clear pressed/unpressed relief; failure knock resets them flush.
**Close-ups:** grimoire spreads (5) · triptych (one plate per painting, gallery-lit by
lamp) · flowerpot rune · rune-tile panel (interactive states).

### 5.3 z1 / v-entry — "the door and the prisoner"
**Framing:** front door center; window left with the canonical sky (Section 3, moon
prominent); crow cage on its tall stand right of the door, half in window moonlight —
the level's emotional anchor, placed on a thirds line facing the door.
**Placement intent:**
- **Front door** — thorn-vines coil across the bolt; the **crow's-beak rune basin** sits
  at lock height directly over the vine-wrapped bolt (spatial causality visible in one
  glance). *Vine states:* alive (gray-green, faintly tensed) / withered (dry tan,
  slumped) / gone (crumbled fragments on the floor). *Basin states:* empty / filled
  (pearlescent liquid, faint spiral echo of the draught) / drained. *Bolt:* vined /
  free / slid.
- **Rusted bent key** — on a hook beside the door, temptingly at eye height.
  *Close-up fairness valve:* the bit is visibly **snapped and plain**.
- **Window** — moonlit woods, moon large, Orion belt visible (Section 3 crop). **WATER
  rune + numeral IV** etched into the sill, catching window light.
- **Crow cage on stand** — wrought iron, tall; **tiny star-shaped keyhole** (close-up
  shows the star socket clearly; visually rejects the rusted key's plain bit); **brass
  feed cup** clipped inside the bars, obvious and reachable (it must *invite* the false
  theory so the refusal can kill it).
  *Crow states:* caged / cage open / crow on rafters (preening; one feather drifting
  down — a single held frame of falling-feather art plus animation notes) / crow on the
  door lintel above the basin (silent endgame nudge).
  *Refusal animation (D3/D4):* crow snaps once, turns its back, guards its wing —
  **identical closed-off pose every repeat, no variation frames** — triggered by both
  cage-reach and any item offered at the feed cup. Compose the pose so the turned back
  reads as *final* (hunched, wing raised like a shut door), not sulky-temporary.
  *Feed cup filled state:* required **only if** the Developer chooses D1 option (b) —
  see flag F3.
**Close-ups:** basin (3 states) · star keyhole (+ key-in-lock success frame) · rusted
key bit · windowsill rune · cage/crow interactive close-up · door bolt.

### 5.4 z2 / v-bench — "the living apparatus"
**Framing:** cauldron over the fire pit center-left, under-lit; floor bellows at its
base, foreground-left, pump handle toward camera; workbench right with the fixed mortar;
dried herbs hanging from beams top-frame (ambient, clearly out of reach).
**Placement intent:**
- **Cauldron + fire pit + floor bellows** — flame stages 0–3 by height (each ~1.6× the
  last) plus rim runes I/II/III with ember channels per 2.3(4). One state render per
  stage. Bellows reads as a foot/hand pump with an obvious action affordance.
- **Ladle** — resting in the cauldron, handle toward camera.
- **Brew close-up (the R3-critical view):** camera drops to ~65° high angle over the
  rim so the liquid surface reads near-top-down — **the same orientation as the recipe
  page spiral**. Stir feedback: the drag gesture leaves a glowing ripple trail arc
  following the ladle sweep, so CW vs CCW is unmistakable from this camera. Page
  handedness and scene handedness are the same handedness by construction. The three
  rim runes remain visible at the ellipse edge in this close-up (stage check at brew
  time).
  *Liquid states:* clear water / gray fizzle puff with the three ingredients bobbing
  intact / pearlescent draught with slow CCW spiral surface pattern (pattern = cue, per
  2.3(5)).
- **Mortar & pestle** — fixed to the workbench, in warm key light.
  *States:* empty / blossom in bowl / ground paste.
- **Hanging herbs** — visibly dry, dusty, and high: framed as scenery, never lit as a
  hotspot.
**Close-ups:** brew view (all liquid states × visible stage runes) · mortar (3 states) ·
rim-rune/flame stage detail.

### 5.5 z2 / v-cabinet — "the locked knowledge"
**Framing:** ingredient cabinet center; astrolabe pedestal right, silhouetted against
the Orion window behind it (the eye-line from plates to sky is the puzzle); potion
shelf left.
**Placement intent:**
- **Ingredient cabinet** — two inset slots at chest height: circle-with-rays recess
  (round, ring-depth) and crescent recess. Recess geometry legible at close-up: the
  round slot is a ring-sized annular seat; the crescent slot matches the coin stamp.
  *States:* empty / correct items seated (ring + coin flush, catching light) / open
  (file + phial on the inner shelf).
- **Potion bottle shelf** — ≥5 distinct silhouettes (e.g. squat onion, tall taper,
  flat flask, twin-bulb, tear-drop); all stoppers fused under identical drips of gray
  wax; pictogram labels (sleep / frost / growth etc.), muted liquids per 2.3(6).
- **Astrolabe / star-globe** — brass, pedestal-mounted; rotating pointer; six engraved
  star-pattern plates arranged around it; base drawer.
  *Plates close-up:* six dot-pattern engravings per the plate_set — plate-2 is the exact
  seven-dot Orion match to the window sky (Section 3). Dot patterns differ by
  *arrangement only*; identical dot size/finish across plates (no luminance tell).
  *Drawer states:* shut / sprung open with silver coin (crescent stamp up) + crank.
- **Workshop window** — canonical sky crop, Orion centered between tree silhouettes,
  moon in top corner (Section 3).
**Close-ups:** slot pair (3 states) · astrolabe plate ring (interactive) · drawer ·
window sky · bottle shelf inspection (wax seals + labels) · coin (crescent hallmark —
must match the spoon hallmark exactly, see 5.6).

### 5.6 z3 / v-cellar — "the buried machine"
**Framing:** single wide view. Ladder from the trapdoor at right frame edge (with the
warm spill from above); barrel mid-right; root shelf with small drawer center-back;
**sliding shelf flush against the far wall center-left** with pulley + empty hook above
it, taut rope visibly running to the shelf runners (the machine must explain itself);
light shaft in the ceiling upper-left with shutter + winch; mirror on its floor stand
between the shaft's landing spot and the shelf.
**Placement intent:**
- **Barrel** — nailed lid with a visible pry gap at the rim. *States:* nailed / pried
  open, iron plumb weight visible inside.
- **Root-shelf drawer** — *States:* shut / open with the tarnished silver spoon,
  **crescent hallmark stamped in the bowl** (identical die to the coin's stamp).
- **Sliding shelf + pulley + hook** — *States:* hook empty (rope taut, hook glinting —
  the "wants weight" read) / weight hung / shelf slid aside revealing the alcove mouth.
- **Light shaft + shutter + winch** — winch has an **empty square socket** (reads as
  crank-shaped absence; also visibly too large/wrong for the rusted key's bent bit).
  *States:* shut / crank fitted / open with the vertical moonbeam (volumetric, dust
  motes, hard floor ellipse — Section 3 continuity).
- **Mirror on stand** — three detents; **floor scratch marks worn at detent-3** (pale
  arcs in the dirt, moonbeam-bounce lit once the beam exists; readable by lantern light
  before).
- **Beam matrix (all combinations required — R4):**
  1. no beam (shutter shut; any detent including detent-3 pre-set),
  2. beam at floor (shutter open, detent 1–2; bright ellipse near the mirror stand),
  3. **beam blocked** (shutter open, detent-3, shelf closed): a hard bright spot **ON
     the shelf face**, halo bleeding into the shelf's board seams — composed to read
     "the light wants to go through here", emphatically not "bugged". The spot sits at
     the shelf's visual center, above the runners the rope connects to.
  4. beam redirected into the alcove doorway (shutter open, detent-3, shelf slid) —
     regardless of the order the player set things.
  Mirror-sweep feedback: when the beam is live, rotating the mirror sweeps the
  reflected beam visibly between detents.
**Close-ups:** barrel rim pry gap · drawer + spoon hallmark · hook/pulley rig · winch
socket (+ crank fitted) · mirror detents + scratch marks.

### 5.7 z4 / v-alcove — "the shrine"
**Framing:** tight stone niche, portrait-feeling composition even in landscape: planter
low center in the (future) beam's landing spot; carved crow statue on a ledge above and
behind it, facing the planter; dusty empty shelf ledge to one side (honest emptiness —
nothing hidden there).
**Placement intent:**
- **Moonflower planter** — *States:* buds tightly closed / buds trembling (subtle motion
  state whenever the beam is anywhere in the cellar — art delivers a "stirred" variant +
  animation notes) / blooming in the beam (petals open, luminous per palette; interior
  glow pattern radial, readable in grayscale) / one blossom picked.
- **Carved crow statue** — the third crow register (5.8): weathered folk carving,
  dignified, holding the **star-bit key** in its beak; key catches beam-bounce glint.
  *States:* key present / taken.
**Close-ups:** statue beak + key · planter (4 states).

### 5.8 The three crow registers (binding character-design note)
Three crow depictions exist and must never blur into each other:
1. **The live crow (z1):** real corvid proportions, sleek, glossy black with faint cool
   iridescence; intelligent eye catch-light; animation poses per 5.3.
2. **The clock toy (z1):** round-bodied, chunky, lathe-carved, chipped paint, painted
   dot eyes, visible wood grain — a child's toy, per D5, so it never teaches "the clock
   matters to the crow".
3. **The alcove statue (z4):** hand-carved folk art, stylized and weathered but
   *dignified* — clearly the wizard's loving work, not a toy and not alive.

---

## 6. State-variant delivery checklist (for the Asset Generation Agent)

The authoritative list is `puzzle-graph.json → visually_necessary_elements`; Section 5
maps every entry to a view and close-up. Delivery rule: **each state variant is a
same-camera, same-lighting re-render of its base plate** — only the stated element
changes, so the Developer can layer or swap cleanly. Animation beats (cuckoo pop, crow
refusal, feather fall, beam sweep, bud tremble, spiral sheen, vine wither) are delivered
as key poses + motion notes; the refusal pose is a single reusable pose per D3/D4.

Conditional asset: **feed cup "filled" state** exists only if the Developer picks D1
option (b) — do not generate until D1 is decided (flag F3).

---

## 7. UI conventions (series seed — near-wordless, no hint button)

- **Tap feedback:** soft radial parchment-white pulse (≈12 pt, 150 ms) at the touch
  point. That is the *only* unsolicited feedback; hotspots are otherwise unmarked —
  exploration is the game.
- **Item drag:** dragged item ghosts at ~70% opacity under the finger. While dragging,
  **every interactive drop region shows a faint cool rim** — including wrong ones (feed
  cup, decoy bottles) — so highlighting can never leak correctness.
- **Inventory bar:** bottom edge, aged dark-oak strip with a soft top shadow (96 pt tall
  iPad / 72 pt iPhone). Items rendered on transparency with a warm rim light; selected
  item lifts slightly with a pale silver ring. Horizontal scroll if overfull. No labels.
- **Navigation:** thin bone-white chevrons at side edges for view rotation (40% idle
  opacity, pulse on tap); a down-chevron / back region for leaving close-ups. Zone
  passages (doors, trapdoor, shelf gap) are diegetic hotspots, not UI.
- **Transitions:** view-to-view = 300 ms crossfade with a 2% directional push;
  zone-to-zone (rune door, trapdoor, shelf) = 600 ms dip-to-near-black with vignette
  close and a diegetic sound.
- **System chrome:** one small engraved-rune glyph button (corner, 40% opacity) for the
  settings sheet. **No hint button exists. No text in scenes; the framing line appears
  on the title card only.**

## 8. Device scaling (iPad primary / iPhone secondary)

- **Master plates:** generate at 2:1 super-frame, 2732 × 1366 minimum. Two crops are
  defined per plate: the **iPad 4:3 frame** (centered) and the **iPhone 19.5:9 band**.
  **Dual-safe zone = the intersection of both crops**; every puzzle-critical element,
  hotspot, and clue mark must sit wholly inside it. Overscan regions carry atmosphere
  only (beams may enter frame from overscan; runes may not live there).
- **Hit targets:** ≥ 44 pt on both devices; small physical objects (feed cup, keyhole,
  scratch marks, rune marks) get invisible hit-area padding rather than upscaled art.
- **Close-up legibility floor (binding case: A5/R5):** in the trapdoor-dial close-up on
  the smallest supported iPhone, each dial face spans ≥ 30% of screen width and the
  waxing/waning terminator relief must survive a grayscale squint test at that size.
  Same floor applies to: triptych moon silhouettes, astrolabe dot patterns vs window
  stars, the recipe spiral's arrowhead, coin/spoon hallmarks, and the star keyhole.
- **iPhone safe areas:** inventory bar and chevrons respect the home indicator and
  notch insets; no critical hotspot within 24 pt of screen edges on iPhone.
- **Asset resolution:** wide plates @2x for 12.9" iPad (2732 px basis); close-up plates
  authored so the finest cue (dial terminator) holds at iPhone native scale without
  sharpening artifacts.

## 9. Flux 2 Pro prompting guidance (for the Asset Generation Agent)

- **Style anchor phrase (use verbatim in every scene prompt, then vary content):**
  *"pre-rendered point-and-click adventure game background, painterly realism, moody
  1990s Myst-style interior, muted warm-and-cool night palette, volumetric moonlight
  with dust motes, precise single-point perspective, oil painting texture, highly
  detailed, no text, no letters, no people"*
- **Negative/avoid:** cartoon, cel shading, anime, lens flare, neon, saturated fantasy
  glow, photobash artifacts, watermark, signage text, humans, skulls/gore.
- Generate each view's **base plate first**, approve, then produce state variants via
  img2img/inpainting against the approved plate to hold camera and lighting.
- The approved base plates of this level become the **series style-reference library
  seed** — record them in `specs/progression-ledger.md` for Level 2+ consistency.
- Precision glyph work (runes, Roman numerals, moon-phase dial faces, star-plate dot
  patterns, recipe pictograms) is high-risk for generative drift: generate these as
  **separate close-up plates with simple geometry prompts**, and expect manual
  correction passes; the grayscale check (2.3) is the acceptance gate.

---

## 10. Flags for the user (style checkpoint) — judgment calls made here

- **F1 — Live moon phase = waxing gibbous (~85%).** Chosen because it is bright enough
  to power the beam and the moonlit woods and matches none of the three p02 dial
  answers; it *is* the mirror image of the dial-3 answer (waning gibbous). The triptych
  remains the sole authoritative p02 clue, and copying the window moon into any dial
  fails — but if the user prefers zero mirror-adjacency, a fatter waxing gibbous
  (~90%+, nearly full but clearly lopsided-right) is the fallback. Needs sign-off.
- **F2 — Ambient light dressing added:** one oil lamp on the z1 desk, a mantel candle
  stub, and one small lantern by the z3 ladder. Non-interactive scenery only, required
  to keep interiors readable with a cold hearth. Framed as "the wizard's lights still
  burning low" — reinforces recent absence. Confirm this reading is welcome.
- **F3 — D1 decision should precede asset generation.** The feed cup's optional
  "filled" state exists only under D1 option (b). Art recommendation: **option (a),
  block-the-pour**, reusing the terminal-refusal pose — zero extra state, one
  consistent refusal grammar (matches D4), one fewer asset. Developer decides; asking
  now avoids a wasted or missing render.
- **F4 — No color-blind conflicts found.** Every graph-specified cue already carries a
  shape/pattern/relief channel; Section 2.3 binds the grading so low-light never
  crushes them. The only load-bearing risk is executional (dial relief at iPhone size),
  gated by the Section 8 grayscale squint test at asset review.
