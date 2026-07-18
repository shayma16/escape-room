# Level 2 Style Guide — The Clockmaker's Attic

*Art Director deliverable, 2026-07-18. Governs `puzzle-graph.json` spec revision 1.3
(post-playtest, final for art). Downstream consumers: Asset Generation Agent (Nano Banana
Pro via fal.ai, per `.claude/agents/asset-generation.md`) and Developer Agent.*

**Framing line (title card only — the only sentence in the level):**
*"All his clocks stopped at six."*

**Standing series rules inherited unchanged (not restated in full here):**
- **Rendering style is FIXED series-wide** by the mandatory Nano Banana Pro style
  template ("clearly stylized real-time 3D game render… stylized-PBR, Lumen-comparable
  lighting, no painterly texture, not photoreal"). This guide supplies WHAT is in each
  scene — palette, mood, composition, legibility contracts. It never overrides the
  template's HOW. If any wording below seems to conflict with the template, the template
  wins and the conflict gets flagged to the Producer.
- L1 style guide **Section 7 + 7-R revisions** (tap pulse, armed-item model, inventory
  pill, chevrons, inspect scrim, transitions) are series-seed UI conventions and apply
  verbatim. Level-specific notes in Section 10 below.
- L1 **Section 2.3(7) luminance ladder** (every interactive element ≥ 2 value steps /
  ~20% luminance from its background field) and the **grayscale check** as acceptance
  gate on every plate and variant.
- **No text anywhere in scene art.** The ONLY glyphs permitted in this level: Roman
  numerals in standard subtractive notation (IV, IX — **no IIII anywhere**, rev 1.2 user
  ruling), the four stamped offsets (`+IV`, `★`, `+IX`, `−V`), Arabic tooth-count stamps
  (16, 24, 36, 40, 48, 64, 72), and the pictogram vocabulary (⌂, ⚙, ★, door, sun/cloud/
  rain, the four landmark silhouettes). Nothing else. No letters, no words, no numerals
  beyond these.
- No humans, no human remains. The clockmaker's absence is told by objects: a coat still
  on its peg, a chalk diagram mid-thought, a "will return" tag he never came back for.

---

## 1. Level style concept

Level 1 was **night, moonlight, magic-as-residue**. Level 2 is its daylight counterweight:
**late golden afternoon, dust, mechanism-as-inhabitant**. The attic is one connected
machine the clockmaker left mid-thought — linkage rods run the length of the level like
tendons, and the player's whole journey is walking *into* the machine: sunlit attic →
denser machinery loft → inside the glowing dial itself → the small lamplit strongroom
under it.

Tonal identity vs L1, same engine style:
- **Warm-dominant, not cool-dominant.** L1's duet was cold moonlight over dying warm
  lamps; L2 inverts it — a low warm sun is the protagonist, and the cools are the
  supporting cast (shadowed machinery, slate, steel, the pale sky over the town).
- **Material register: oak + brass + iron, with verdigris and rust as age.** Brass here
  is *worked* metal — dulled by handling, bright only on worn edges and teeth. Verdigris
  (muted green-gray) appears ONLY as ambient patina; it is never load-bearing
  (colorblind_safety: finishes are ambient only).
- **Stillness with one held breath of motion.** Everything mechanical is frozen at 6:00.
  The only things that move before the player acts: dust motes in the sunbeam, and the
  cat's breathing. When the machine finally runs, motion is the reward.
- Melancholy register identical to L1: quiet, recently-left, never horror, never cute.

---

## 2. Master palette

Series-continuity swatches reused from L1 are marked (L1). Saturation ceiling ~45%
except the z3 amber transmitted-light core and brief feedback glints.

| Role | Swatch | Hex anchor |
|---|---|---|
| Afternoon sun key / beam core | warm gold | `#EFC271` |
| Sun fill / bounced warmth | honey | `#C98F4A` |
| Warm lamp light (z4, win beat) | amber (L1) | `#D9973F` |
| Deep warm shadow | burnt umber (L1 family) | `#A05C22` → `#3A2C1E` |
| Attic oak mid / shadow | aged brown / deep umber (L1) | `#6B5238` / `#3A2C1E` |
| Floorboards, straw, raw wood | pale tan | `#C2A264` |
| Brass (dials, gears, plates) | dulled gold (L1) | `#C7A24B`, edge-worn highlight `#E5C878` |
| Bronze (great wheel, movement) | dark bronze | `#8A6F3E` |
| Iron / steel (bar, screwdriver, frame) | cool pewter (L1) | `#C4C9CE` / `#5B6066` |
| Rust bloom (seized arbor, drum) | oxide | `#8A4B2A` |
| Verdigris patina (ambient only) | gray-green | `#5E7A6A` |
| Slate + chalk | blue-black / bone | `#2E3236` / `#E8E4DA` |
| Chimney brick | dusty red-brown, muted | `#7A4A38` |
| Sky over town (dormer view) | pale warm haze → upper blue | `#C9D4DC` → `#8FA6B8` |
| z3 dial glow core | luminous amber | `#F0C060` |
| z3 dial glow deep / falloff | deep amber | `#B87A2E` |
| z3 silhouette darks | near-black warm | `#2A1F14` |
| z4 stone / mortar | cool gray (L1) | `#5A6672` |
| Cat fur | blue-gray | `#8C8C90`, warm rim from the sun |

The town under the dormer is hazy, sun-washed rooftops — background atmosphere only,
low detail, no signage, no people, no readable anything.

---

## 3. Lighting language — "the golden hour, held"

One sun, one moment, level-wide (the L2 analogue of L1's canonical moon):

- **Sun position is canonical and fixed:** low in the west-southwest, warm, ~15° above
  the horizon. Every view's key light traces to it. It never moves during play — the
  whole level is one held minute of golden hour, rhyming with the clocks all stopped at
  one moment.
- **Beam continuity rule:** every direct-sun shaft (dormer beam in z1 v-door, any window
  slash in z1 v-bench, the z3 dial glow) shares the identical color temperature
  (`#EFC271` core) and the series dust-mote treatment. The z3 glow IS the same sun,
  transmitted through the frosted dial glass — the player should subconsciously read one
  light source across the level.
- **Warm/cool mix per zone** (Section 5): z1 70/30 warm, z2 45/55 (the coolest), z3
  amber-owns-everything, z4 a small warm lamp pocket in darkness.
- **Gloom never hides a hotspot** (L1 rule): every interactive element gets direct key
  or a deliberate rim. In z2's machinery shadow and z3's contre-jour, rim light does the
  work.
- **Win beat only:** the final stair-door-open plate may deepen one step toward evening
  (`#D9973F` cast) — the held minute finally moves. (Flag F4.)
- No informational color: no puzzle state is ever encoded in warm-vs-cool or any hue
  (colorblind_safety — this level has zero color-coded elements by design; keep it so).

---

## 4. Glyph canon (binding legibility contracts)

### 4.1 One numeral typeface, level-wide
Produce first, before any plate: a **canonical Roman-numeral reference sheet**
(`numerals-canonical`, analogous to L1's `orion-canonical`) — I through XII in one
engraved-serif letterform, PLUS the full mirrored set. Every dial, tile, stamp, and
engraving in the level uses these exact letterforms:

- Standard subtractive notation everywhere: **IV and IX. IIII is banned** (rev 1.2 user
  ruling — reject any generation containing it).
- Letterforms carry **asymmetric wedge serifs** (a heavier left-foot serif on I, a
  distinct thick/thin stroke contrast on V and X). This asymmetry is load-bearing: it is
  what makes a *mirrored* numeral detectably wrong at a glance (Section 4.2).
- Surfaces vary (chalk, engraved brass, painted door dial, cast tiles) but the skeleton
  of every glyph is identical.

### 4.2 The mirrored great dial (D1 — the level's most load-bearing art)
The z3 close-up renders the dial's BACK: the entire front image mirrored across the
vertical axis. Contracts, all binding:

1. **Numeral ring mirrored as a whole:** the glyph that sits at front-right (III)
   appears at back-left, and every glyph is individually mirror-flipped. XII stays top,
   VI stays bottom (both near-symmetric positions), but their letterforms are flipped.
2. **Mirrored IV must read as a *malformed* VI** — and mirrored VI as a malformed IV.
   The serif asymmetry from 4.1 is exactly what makes the malformation crisp: the
   flipped glyph has its thick strokes and foot serifs on the wrong side. It must be
   clearly *almost*-VI, wrong on inspection — never a clean, legible VI.
3. **NO legible "VII" may exist anywhere on the back view.** Mirrored VII reads as
   "IIV" (backwards). This absence was the playtest's actual unstick — preserve it
   exactly. Keep glyph spacing open enough that "IIV" can never be squinted into "VII".
4. Mirrored IX ↔ malformed XI, same treatment as (2).
5. **Hand silhouettes** show through the translucent glass as soft-edged dark shapes:
   hour hand short and spade-tipped, minute hand long and plain-tipped — identifiable
   by silhouette alone at every position. Hands are delivered as separate sprites
   (Section 8) so the Developer renders any front time θ at mirrored angle −θ; art
   never bakes a specific time into the dial plate.
6. Legibility floor: in the great-dial close-up on the smallest supported iPhone, each
   numeral ≥ 5% of screen width; the malformed-VI vs true-VI distinction must survive a
   grayscale squint at that size. Everything reads by shape and luminance against the
   amber glow — zero hue reliance.

### 4.3 The four landmark pictograms (Validator advisory A2 — resolved here)
One canonical silhouette **die** per landmark, reused *identically* at both sites (z2
engraved brass plates and z3 hatch pictogram headers) — the L1 coin/spoon
"identical-die" rule. Binding is by pictogram matching, so the two renditions must be
geometrically the same mark at different scales. Specs, mutually unambiguous at the
smallest (hatch-header) size:

| Landmark | Silhouette spec | Disambiguator |
|---|---|---|
| **Big Ben ★** | Parallel-sided tower shaft; **a clearly wider clock-face stage near the top** — a square block protruding past the shaft on both sides, carrying an engraved circular dial disc that reads even at ~24 px — then a stepped spire and finial. Aspect ~4:1. | **A2 compliance: the clock stage is mandatory and is the widest point below the spire.** A "tower with a head" — can never be confused with a smooth needle. The ★ is stamped beside it on plate and header alike (same star die as the master longcase case). |
| **Burj Khalifa** | Continuous telescoping taper: Y-lobed flared base, stepped setbacks, monotonically narrowing to a very tall thin needle tip. Aspect ~8:1, no protrusion, no bulge anywhere. | Pure "needle" read; strictly monotonic width vs Big Ben's protruding stage. Tallest and thinnest of the four. |
| **Statue of Liberty** | Figure on a small pedestal, raised torch arm, **crown with exactly 7 rays**, tablet arm tucked. | The only human-figure silhouette. |
| **Mount Fuji** | The only non-vertical mark: wide, low, symmetric mountain with the flattened crest; snowcap indicated by an engraved hatched cap line (relief, not color). Aspect ~1:2.5 (wider than tall). | The only horizontal-format silhouette. |

Acceptance test: all four dies desaturated at hatch-header size, shown to a fresh
viewer — four distinct shapes, no hesitation between Big Ben and Burj Khalifa.

**Site orders are different and binding:** z2 row left→right = Burj Khalifa `+IV` ·
Big Ben `★` · Fuji `+IX` · Liberty `−V`. z3 hatch headers left→right = Big Ben `★` ·
Burj Khalifa · Liberty · Fuji. Do not "fix" the mismatch — it forces pictogram matching.

### 4.4 Small-mark vocabulary
- **⌂ (house) and ⚙ (gear) carved marks**, each ringed by an engraved **12-notch**
  clock-position circle (exactly 12 notches, 12 at top). Same die pair reappears on the
  watch case backs — watch A back ⌂, watch B back ⚙, identical geometry to the beam and
  chimney carvings (the binding is the match).
- **★ star die**: master longcase case, Big Ben plate, Big Ben hatch header — one die,
  three sites.
- **Door pictogram** (simple arched door mark): slate cam circle, return tag. Same die.
- **Barometer pictograms**: sun / cloud / rain, engraved — deliberately weather-flavored
  so the dial reads "not a clock" without words.
- **Exact-count contract (hard):** counts are solve routes, so they are exact — 24 chalk
  tallies on the slate, 12 notches per ring, 12 sockets on the door dial, 7 crown rays,
  and **every gear has exactly its stamped number of teeth** (16/24/36/40/48/72/64 —
  the tooth-counting route is a sanctioned no-algebra solve). Generative models will not
  hold exact tooth counts reliably: gears are authored as individual prop plates and
  verified by count; expect manual/PIL correction passes (flag F6).

---

## 5. Per-zone mood and lighting

Throughline: one sun, one wood-and-brass material family, the linkage rods stitching
every zone together along the ceilings.

### z1 — Main Attic: "the sunlit stillness" (3 views)
- **Mix:** 70% warm / 30% cool. Key = the low sun through the dormer (v-door owns the
  beam; v-bench and v-master receive its warm bounce and one soft raking slash). Cools
  live in the rafters and the north corners.
- Mood: golden dust, held breath. The cat asleep in the sunbeam patch is the zone's
  emotional anchor (and p02 staging — the beam patch on the bench/cushion is REQUIRED
  geometry). Rooflines and beams frame everything; the linkage rods run overhead like a
  sentence the player can't read yet.
- Value range: generous mid-tones; darkest corners hold detail at ~18% luminance.

### z2 — Movement Loft (workroom): "inside the works" (2 views)
- **Mix:** 45% warm / 55% cool — the coolest inhabited zone. No dormer here: light is
  colder spill from a small skylight off-frame plus warm leak through the doorway from
  z1. Machinery reads in steel-and-bronze half-light with precise rims.
- Mood: denser, taller, more crowded — the attic's workshop brain. The automaton wall
  gives it a held-performance feeling: a carved town waiting for its sun to rise. The
  chimney breast adds mass and warm brick color to an otherwise cool room.
- The two views split warm/cool: v-frame cooler (machine wall), v-clockrow slightly
  warmer (brass row catching doorway light).

### z3 — Behind the Great Dial: "inside the lantern" (1 view)
- **Mix:** amber owns the room. The translucent dial is the light source — the level's
  set-piece: a huge glowing disc of transmitted `#F0C060` daylight, mirrored numerals
  floating in it, everything else in the chamber rendered contre-jour in warm
  near-silhouette (`#2A1F14` darks) with amber rims. Dust motes drift in the glow.
- Mood: awe. Stepping through the wall panel is the level's biggest reveal; the player
  is standing inside the town's clock, behind its face, in its light. Machinery
  (drum, pendulum, strike train, rods) reads as dark elegant shapes against the disc.
- Discipline: awe never taxes legibility — the hatch, drum, crank, and pendulum all
  carry rim light per the luminance ladder; the dial close-up carries the numeral
  contracts (4.2).

### z4 — The Clockmaker's Vault: "the kept room" (1 view)
- **Mix:** one small warm lamp (`#D9973F`) in darkness — 60% of the frame in deep
  shadow, a lamplit pocket holding everything that matters. Faint amber leak from the
  open hatch above.
- Mood: intimate, personal, the reward room. The second cushion and empty saucer say
  the cat was loved; the wrapped unfinished watch says the clockmaker meant to come
  back. Quiet tenderness, not dread — z4 is to L2 what the alcove shrine was to L1.

---

## 6. Scene composition briefs (one per camera view)

Every element is from the Designer's spec; nothing added, moved, or removed.
`visually_necessary_elements` in the graph remains the authoritative checklist; this
section is its composition translation. All wides: single-point perspective, standing
eye level (~150 cm), 28–35 mm equivalent; close-ups 50–70 mm.

### 6.1 z1 / v-bench — "the workbench mid-thought"
**Framing:** long workbench along the back wall, spanning the mid-ground; wheel
barometer on the wall far left; iron stove right of bench; clockmaker's coat on its peg
far right frame. Warm raking light from frame-right (dormer direction, off-frame), one
soft sun slash across the bench top.
**Placement intent:**
- **Chalk slate** — propped upright on the bench, center, on a thirds intersection: the
  view's focal object. Diagram fully inside the dual-safe zone. Chalk on slate is the
  highest-contrast surface in the room (bone on blue-black).
- **Screwdriver in bench rack** — left bench end, heavy flat blade catching a rim; its
  silhouette must read "pry tool," rhyming later with boards and bricks.
  *States: present / taken.*
- **Stove + tile II on the cold hob** — cast tile lying flat, numeral up, catching the
  sun slash. Stove is visibly cold (no glow — the level's "everything stopped" rule).
  *States: present / taken.*
- **Coat on peg** — worn wool, both pockets subtly weighted/dimpled (they hold watch A
  and tile IV). The coat invites a search without a marker.
  *Pocket close-up states: watch A present/taken × tile IV present/taken (independent).*
- **Barometer** — brass, clock-like at a glance (the trap), wall-hung left at eye
  height. Fixed needle; sun/cloud/rain pictograms legible only in close-up.
- Ambient bench clutter (springs, arbors, small tools) — dense but clearly
  non-collectible: smaller scale, lower contrast, no rim emphasis (L1 decoy discipline).
**Close-ups:** slate diagram (24 tallies countable, XII / VIII stamps, two `?` wheels,
cam circle with one notch + door pictogram — all crisp) · stove hob (tile II) · coat
pockets (interactive) · barometer face.

### 6.2 z1 / v-master — "the stopped heart and the numbered door"
**Framing:** master longcase clock left-of-center, tall, nearly to the beams; workroom
door center-right with its painted dial at eye height and the fixed wooden tray below;
packing crate with straw front-right; **linkage rods enter along the ceiling from
frame-left (stair-door direction) and vanish into the workroom wall** — composed as a
readable line the eye follows (foreshadows z3).
**Placement intent:**
- **Master longcase** — face angled to camera; stopped at exactly **6:00** (hour on VI,
  minute on XII); the small **★** engraved on the case, visible at wide, crisp in
  close-up. Standard numerals per canon. The pendulum behind its glass hangs dead
  still.
- **Workroom door dial** — large painted hand-less dial: 12 sockets, 8 tiles seated
  (I, III, V, VI, VIII, IX, X, XII), 4 empty sockets at the 2/4/7/11 positions —
  empty sockets read as recessed, shadowed seats. **The seated VI at position 6 must be
  plainly legible at the interactive close-up** — it is the tray decoy's standing
  disproof. *States: per-socket empty/seated ×4; whir-stall pop-back (animation); door
  shut / open onto z2.*
- **Tray + VI tile** — fixed tray directly below the dial; one loose VI tile lying in
  it, same cast-tile design as the inventory tiles at equal render weight (it must not
  look "wrong" — it is an honest decoy). Non-collectible: it never leaves the tray
  except during the seat-and-pop-back animation.
- **Crate + tile VII** — straw-filled crate; the tile half-buried, one corner and
  partial numeral catching light (findable, not pixel-hunted). *States: present/taken.*
**Close-ups:** master clock face (6:00 + ★ — the p07 gating clue view) · door dial
(interactive; sockets + tray) · crate straw (tile VII).

### 6.3 z1 / v-door — "the barred door and the sunbeam"
**Framing:** stair door center-left — heavy horizontal bolt-bar in a vault-style
housing, **visibly keyhole-free** (D8: smooth plate where a keyhole would be; the
absence must be composed, not incidental); linkage rods rise from the bar and run along
the ceiling toward frame-right/off-frame. Dormer window right third: golden beam
falling as a bright patch across a low bench where the **cat sleeps on its cushion**.
Town rooftops hazy through the glass.
**Placement intent:**
- **Cat + cushion** — squarely in the beam patch (p02 staging is required geometry).
  The cushion visibly bulges flat-edged beneath the cat — "something flat under there"
  reads at the close-up without a marker. Cat register per Section 9.1.
  *Cushion states: cat-on / liftable revealing watch B / empty.*
- **Tile XI** — on the dormer windowsill, backlit edge + numeral readable.
  *States: present/taken.*
- **⌂ beam mark + 12-notch ring** — carved into the beam beside the dormer at eye
  height; shadowed groove with rim-caught edges; crisp in close-up.
- **Floorboards** — run front-to-back so their seams are vertical in view and boards
  are unambiguous countable columns; **at least five boards visible to the RIGHT of the
  ring's vertical**, all inside the dual-safe zone, ALL uniform. The cache board (third
  right) has **NO independent visual tell** in any state or view — identical boards, by
  design (the gate carries the info; D10's faint-tell is animation/SFX only, zero
  persistent pixels).
  *Cache states (close-up + wide overlay): flush / pried-open with great wheel / empty.*
- **Stair door** — *states: bar seated / bar raised; door open onto stairs in evening
  light (win).* Bar-rattle and D10 board-shift are animation notes, not art states.
**Close-ups:** ⌂ ring · cat/cushion (interactive) · floor cache · time-lock housing
(bar + rods + NO keyhole — doubles as the clu-linkage-rods anchor).

### 6.4 z2 / v-frame — "the automaton wall"
**Framing:** the floor-to-ceiling automaton wall owns the left two-thirds: carved town
mural (rooftops, jointed figures, a track for the sun disc, the watchman with his bell)
across the upper wall; the exposed **two-stage gear frame** below it at interaction
height; **gear rack** bolted to the wall at the frame's right shoulder; **chimney
breast** fills the right third, the **⚙ ring** carved on one brick at eye height.
Cool key light, warm doorway spill from frame-right.
**Placement intent:**
- **Gear frame** — left: fold-out crank carrying the fixed pinion stamped **XII**;
  empty square-arbor **POST A** (with its fixed coaxial pinion stamped **VIII**);
  empty square-arbor **POST B** driving the cam. The drive path crank→A→B→cam must be
  visually traceable as a line. **Rust bloom** at the main bearing reads at wide
  (oxide `#8A4B2A` + matte texture vs the surrounding worked metal).
  *States: seized / oiled (sheen + cleared bloom at the bearing only); per-post mounted
  overlays for all six rack gears AND the great wheel (either post — 14 overlays);
  crank fold-out; mural run (animation at variable speed); the one correct full cycle
  (sun crosses the town, watchman strikes the bell — key poses); panel shut / swinging
  / latched open onto the z3 doorway.*
- **Gear rack** — six brass gears on pegs: **16, 24, 36, 40, 48, 72** — distinct
  diameters proportional to tooth count, stamped Arabic numerals, and **exactly
  countable teeth** (4.4). Differentiation is size + stamp + count — NEVER color; all
  six share the same brass finish. *States: per-gear on-rack / absent.*
- **Chimney breast** — uniform bricks; ⚙ ring carved on one; **bricks to the LEFT of
  the ring fully visible and inside the safe zone** (9-o'clock = directly left). The
  cache brick has NO independent visual tell (same rule as 6.3).
  *Cache states: flush / pried-open with oil can / empty.*
**Close-ups:** gear frame (interactive — pinion stamps XII/VIII legible, posts, cam) ·
gear rack (teeth countable at iPhone scale) · ⚙ ring · brick cache.

### 6.5 z2 / v-clockrow — "the silent embassy row"
**Framing:** the four dead wall clocks hang in one row across the upper-mid band,
evenly spaced, each with its engraved brass landmark plate mounted directly beneath;
parts cabinet below right; the glass-front spare-hands display case left, below the
row. Brass row catches the warm doorway light; the case sits half a step cooler.
**Placement intent:**
- **World-clock row** — all four faces **hand-less** (bare arbor hole at each center —
  compose the emptiness legibly; a hand-less dial is an odd image and generative drift
  WILL try to add hands — see Section 12), standard numerals. Plates left→right:
  **Burj Khalifa `+IV` · Big Ben `★` · Fuji `+IX` · Liberty `−V`** (binding order).
  Landmark dies per 4.3; offset stamps in the canonical numeral letterforms. One row
  close-up covers all four plates legibly; the faces accept no interaction.
- **Parts cabinet** — modest chest of drawers; top drawer front slightly proud
  (openable read). *States: shut / open with tin mouse / empty.*
- **Spare-hands display case** — assorted hands visible through the glass (the false
  goal must look wonderful). **AD discretion exercised (playtest note, flag F1): the
  paint-over is emphasized one notch** — paint visibly skinned across the case seam,
  drips sealed over BOTH screw heads, screw slots filled flush with dried paint in
  close-up. It must read "sealed shut years ago," categorically not-openable — without
  becoming comic.
**Close-ups:** clock-row plates (the clu-worldclock-row gating view — all four
silhouettes + stamps crisp) · cabinet drawer · display case (paint-over emphasis).

### 6.6 z3 / v-dial — "inside the lantern" (the set-piece)
**Framing:** the great translucent dial fills the left ~55% of frame, a glowing amber
disc seen from behind, its top arc cropped by the chamber roof — big enough to awe,
composed so the FULL numeral ring sits in-frame and inside the safe zone. The platform
floor runs across the lower third; **floor hatch** with its four wheels front-right;
**winding drum** (square socket, drive weight on its line) mid-right; **pendulum**
hanging dead-still through its platform slot, center-right, silhouetted against the
glow; **strike train + chime hammers** upper right, their **linkage rods exiting
frame-right toward z1** — the same rod line the player has followed all level, seen
end-to-end at last. **Setting crank** on the motion works at the dial's hub, clearly a
graspable hotspot against the glow.
**Placement intent:**
- **Great dial (back view)** — mirrored numeral ring per the full D1 contract (4.2);
  hand silhouettes as separate sprites behind the glass; glass texture faintly frosted
  with amber falloff toward the rim; dust motes in the transmitted light.
- **Setting crank** — rim-lit; **keep a clear, uncluttered staging area of plain
  boards/beam beside it** (≥ ~8% of frame width) — reserved for the DORMANT D9 chalk
  overlay. Nothing is drawn there now; nothing else may occupy it.
- **Winding drum** — dry state: rust bloom + dry texture at the bearing (squeal is
  audio); square key socket reads as a square absence (must rhyme with the winding
  key's square bit, and visibly NOT fit the mouse's butterfly key).
  *States: dry / oiled / key-in-socket; drive weight low / rising / fully raised
  (weight is a positioned sprite on its line).*
- **Pendulum** — *states: dead still / weak swing / full swing (sprite + animation
  notes).*
- **Strike train + hammers** — hammers in profile so the D11 twitch (lift-and-settle,
  never striking) reads in silhouette; strike beat = rod articulation key poses.
- **Floor hatch** — four brass combination wheels engraved I–XII, headed left→right by
  the pictogram dies: **Big Ben ★ · Burj Khalifa · Liberty · Fuji** (binding order —
  different from the z2 row). Wheels render any position via a shared 12-position
  sprite strip. *States: shut / open (dark stair mouth down to z4, warm lamp leak).*
**Close-ups:** great dial + crank (interactive; carries clu-mirrored-numerals — the
whole 4.2 contract at full legibility; D9 space reserved in this plate too) · winding
drum (interactive) · hatch wheels (interactive).

### 6.7 z4 / v-vault-interior — "the kept room"
**Framing:** small strongroom, low ceiling, near-square feel inside the landscape
frame; steps/ladder down from the hatch at back-left with faint amber spill; one small
oil lamp lighting the working wall. Intimate 35 mm.
**Placement intent:**
- **Winding key on hook** — left wall in the lamp pool; large square-bit silhouette
  reads instantly (the bit must visually rhyme with the drum socket — L1 crank/socket
  lesson AF-2). *States: present / taken.*
- **"Will return" tag on nail** — beside the key, brass shop tag: miniature FRONT-VIEW
  dial with fixed hands at **7:20** over the door pictogram die. Legible in its
  close-up and in inventory inspect. *States: present / taken.*
- **Shelf** — ledgers (spines blank/pictogram-free) + the wrapped unfinished pocket
  watch, half-unwrapped in cloth: the room's quiet grief object. Inspect-only.
- **Second cushion + empty saucer** — floor corner, lamplight edge. Ambient lore; no
  interaction art beyond the wide.
**Close-ups:** tag on nail (7:20 legible) · key on hook · shelf (lore inspect).

---

## 7. Close-up plate inventory (with legibility contracts)

25 close-up plates. Interactive = hosts input; all obey the 7-R1.5 bottom-band rule.

| # | Plate | Zone | Contract |
|---|---|---|---|
| 1 | Slate diagram | z1 | Exactly 24 tallies countable; XII/VIII stamps; two `?`; cam notch + door die |
| 2 | Stove hob (tile II) | z1 | Numeral legible; present/taken |
| 3 | Coat pockets (interactive) | z1 | Watch A + tile IV independently present/taken |
| 4 | Barometer face | z1 | Fixed needle; sun/cloud/rain engraved; reads "not a clock" |
| 5 | Master clock face | z1 | 6:00 sharp; ★ die; canonical numerals — p07 gating view |
| 6 | Door dial (interactive) | z1 | 12 sockets; seated VI legible (decoy disproof); tray VI; per-socket states |
| 7 | Crate straw (tile VII) | z1 | Half-buried but findable |
| 8 | Dormer windowsill (tile XI) | z1 | Present/taken |
| 9 | ⌂ ring | z1 | 12 notches exact; ⌂ die = watch A back die |
| 10 | Cat + cushion (interactive) | z1 | Flat shape under cushion reads; cushion 3 states |
| 11 | Floor cache | z1 | Uniform boards; flush/pried+wheel/empty; NO pre-open tell |
| 12 | Time-lock housing | z1 | NO keyhole; bar + rod connection legible; bar states |
| 13 | Gear frame (interactive) | z2 | XII/VIII pinion stamps; posts A/B; rust bloom; mount states |
| 14 | Gear rack | z2 | Six gears, exact countable teeth + Arabic stamps at iPhone scale |
| 15 | ⚙ ring | z2 | 12 notches; ⚙ die = watch B back die; bricks left of ring in frame |
| 16 | Brick cache | z2 | Uniform bricks; flush/pried+oilcan/empty; NO pre-open tell |
| 17 | Clock-row plates | z2 | All 4 dies + offsets crisp (A2); faces hand-less — p07 gating view |
| 18 | Cabinet drawer | z2 | Shut/open+mouse/empty |
| 19 | Display case | z2 | Paint-over emphasis (F1): sealed screws, skinned seam |
| 20 | Great dial + crank (interactive) | z3 | Full 4.2 mirror contract; hand sprites; D9 space clear — self-satisfying clue view |
| 21 | Winding drum (interactive) | z3 | Dry/oiled; square socket; key-in; weight track |
| 22 | Hatch wheels (interactive) | z3 | 4 headers per 4.3 order; I–XII wheel strip; engraved numerals legible |
| 23 | Tag on nail | z4 | Mini dial fixed 7:20 + door die — clu-return-tag view (with inventory inspect) |
| 24 | Key on hook | z4 | Square bit rhymes with drum socket |
| 25 | Vault shelf (lore) | z4 | Wrapped watch + ledgers; nothing puzzle-bearing |

**Inventory cutouts (12, RGBA, ≥1024 px long side per 7-R3):** screwdriver · tiles II,
IV, VII, XI · watch A · watch B · toy mouse · great wheel · oil can · winding key ·
return tag.
- **Watches A and B:** authored as hunter-case watches **lying open** — dial (single
  hand frozen on III / IX) and engraved inner lid (⌂ / ⚙ die) both visible in ONE
  cutout, so the standard single-image inspect (7-R3) carries the whole clue. No
  two-sided inspect mechanic needed.
- **Return tag:** front face only (mini dial 7:20 + door die). Do NOT author a reverse
  side — the double-sided tag is D9's dormant tier-2 fallback.
- **Great wheel:** 64 teeth exactly, "64" stamp legible; bronze (visibly not
  rack-brass, ambient distinction only).
- **Toy mouse:** butterfly key visibly round-winged — can never be mistaken for the
  square-bit winding key (p08 failure read).

---

## 8. State-variant matrix (Asset Generation planning sheet)

Delivery rule (L1 Section 6, unchanged): every variant is a same-camera, same-lighting
change of ONLY the stated element — crop-scoped edits against the approved base plate,
or separate layered sprites — never full-plate re-rolls. **Rev 1.3 note (binding): D10,
D3-tell, and D11 ship as animation/SFX/haptic over existing art — zero new plates, zero
persistent pixel changes.**

| Element | Variants | Technique |
|---|---|---|
| **z1** | | |
| Screwdriver rack | taken | crop edit (wide) |
| Stove hob tile II | taken | crop edit (wide + CU) |
| Coat pockets | watch A taken; tile IV taken (independent) | 2 layered overlays (CU) |
| Door dial sockets | 4 × seated-tile | 4 layered overlays (CU + wide echo) |
| Tray VI | seat-and-pop-back | animation notes only (tile sprite reuses cutout) |
| Workroom door | open onto z2 | crop edit (wide) |
| Crate tile VII | taken | crop edit (wide + CU) |
| Sill tile XI | taken | crop edit (wide + CU) |
| Cushion | watch-reveal; empty | 2 overlays (CU + wide echo) |
| Floor cache | pried+wheel; empty | 2 CU variants + 1 wide overlay |
| Stair bar | raised | crop edit (wide + CU 12) |
| Stair door | open, evening light (win) | crop edit (wide) — the one sanctioned lighting shift (F4) |
| Cat | 7 staging beats: asleep / slow-blink refusal / mouse-tell (eye-lock + tail flick) / pounce-chase / settled-by-door / stretch / exit-trot | sprite rig: key poses + motion notes (D3; identical-on-repeat rule) |
| Toy mouse (scene) | wound skitter loop | sprite + notes (D4) |
| D10 board/brick faint-tell | hair-of-movement under blade | animation note ONLY — no art state |
| **z2** | | |
| Arbor bearing | oiled (bloom cleared, sheen) | crop edit (wide + CU 13) |
| Post mounts | 7 gears × 2 posts | 14 layered overlays (CU 13) |
| Rack pegs | 6 × absent | 6 layered overlays (CU 14 + wide echo) |
| Mural run | variable-speed run; correct full cycle (sun transit + watchman bell) | jointed-figure sprite layers + key poses (D5 cadence is Developer timing) |
| Wall panel | swinging; latched open onto z3 | crop edit (wide) + swing key poses |
| Brick cache | pried+oilcan; empty | 2 CU variants + 1 wide overlay |
| Cabinet drawer | open+mouse; empty | 2 overlays (CU 18) |
| Display case | paint-over emphasis pass | one inpaint on CU 19 (F1) |
| **z3** | | |
| Dial hands | hour + minute silhouette sprites, arbor-anchored, mirrored render at any detent | 2 sprites (Developer positions; D1) |
| Winding drum | oiled; key-in | 2 overlays (CU 21) |
| Drive weight | low → raised | 1 sprite + track spec |
| Pendulum | still / weak / full | 1 sprite + animation notes |
| Hammers (D11 twitch) | lift-settle, never strikes | 2 key frames + notes; escapement tick is audio |
| Strike beat | rod articulation (z3 and z1 ends) | key poses + notes |
| Hatch wheels | 12-position engraved strip (shared ×4 wheels) | 1 sprite strip |
| Hatch | open (stair mouth + lamp leak) | crop edit (wide) |
| D9 chalk sketch | **DO NOT GENERATE** — dormant; space reserved only | — |
| **z4** | | |
| Key hook | taken | crop edit (wide + CU 24) |
| Tag nail | taken | crop edit (wide + CU 23) |

**Totals for the batch quote:** 7 wide base plates · 25 close-up plates · 12 inventory
cutouts · 2 canonical reference sheets (numerals incl. mirrored set; landmark/mark
dies) · ~46 crop-scoped overlay/state edits · ~12 sprite/rig deliverables (cat rig,
mouse, 2 dial hands, weight, pendulum, hammer keys, wheel strip, mural figure layers,
panel/strike/pop-back key poses). Zero planned full-plate re-rolls beyond the 7 bases.

---

## 9. Character and prop registers

### 9.1 The cat (the series' second living presence — successor to L1's crow)
- Real-cat proportions in the fixed stylized-PBR register: medium gray shorthair,
  blue-gray `#8C8C90` coat, subtle warm rim from the sunbeam; amber eyes (echoes the
  level palette; catch-light like the L1 crow's intelligent eye). Simplified,
  non-noisy fur per the style template — never fluffy-cute, never gaunt.
- No anthropomorphism, no collar, no expressions beyond cat-truth: the slow blink, the
  eye-lock-and-track, the tail flick, the pounce, the stretch. Dignity per the L1 crow
  rule: refusals read *final*, not sulky.
- The mouse-tell (D3) is carried by eyes + tail ONLY — body stays settled. Compose the
  eye-lock pose so the gaze visibly tracks the offered mouse.

### 9.2 The tin mouse
Folk tin toy: painted tin body (muted, worn), round-winged **butterfly** key on its
back. Deliberately toy-like beside the real cat — the same toy-vs-alive contrast as
L1's clock crow vs live crow.

### 9.3 Keys and sockets (rhyme rule, binding)
Square drives rhyme: winding key bit ↔ drum socket ↔ (visually) the square arbors of
posts A/B. The butterfly key rhymes with nothing — that mismatch is its message.

---

## 10. UI conventions (series-seed inherited; level notes)

- All of L1 §7 as revised by §7-R applies verbatim: tap pulse; select-then-tap armed
  model with equal-rim drop targets (highlighting never leaks correctness — vault
  wheels, wrong boards, and wrong bricks rim exactly like correct ones); translucent
  inventory pill (auto-collapse, close-up persistent, bottom-band composition rule);
  chevron spec with breathing pulse; inspect scrim; 300 ms view crossfade; 600 ms
  zone dip. **No hint button exists.**
- **Pause glyph (level note, flag F2):** same treatment as L1's corner button (engraved
  mark, 40% idle opacity), glyph swapped to a small engraved **winding-key** mark for
  this level. Zero-cost to keep L1's rune instead if the user prefers one series-wide
  mark.
- Zone passages are diegetic hotspots (workroom door, wall panel, hatch, stair door),
  never UI.
- The framing line appears on the title card only. Nothing else in the level renders
  text.

---

## 11. Device scaling (iPad primary / iPhone floor)

- **Masters:** 2:1 landscape plates at **3840 × 1920**. Two crops per plate: iPad 4:3
  centered frame and iPhone 19.5:9 band.
- **Composition safe zone (binding — the L1 BUG-004 lesson, applied from the start,
  not retro-fitted):** every puzzle-critical element, hotspot, clue mark, and countable
  feature must sit BOTH (a) inside the dual-safe-zone intersection of the two crops AND
  (b) **at least 8% of plate width/height in from every plate edge** — whichever bound
  is stricter. Overscan and the outer 8% carry atmosphere only (beams and rods may
  cross them; numerals, rings, sockets, countable boards/bricks/teeth may not).
- **Close-up bottom band (7-R1.5):** no puzzle-critical detail in the bottom 72 pt
  (iPad) / 62 pt (iPhone) of any close-up frame — the inventory pill lives there.
- **Hit targets:** ≥ 44 pt both devices; small marks (rings, tiles, tag, sill tile,
  wheel columns) get invisible hit padding, never upscaled art.
- **Legibility floors on the smallest supported iPhone (grayscale squint at native
  scale is the acceptance gate):**
  - Great-dial close-up: each mirrored numeral ≥ 5% screen width; malformed-VI vs
    true-VI distinct; "IIV" never squintable into "VII" (4.2).
  - Gear rack close-up: individual teeth resolvable and countable (≥ ~8 px per tooth
    pitch); Arabic stamps crisp.
  - Clock-row plate close-up: all four landmark dies distinct (4.3 acceptance test) and
    all four offset stamps legible in one screen.
  - Hatch close-up: engraved wheel numerals + all four header dies legible
    simultaneously.
  - Slate: all 24 tallies individually countable.
  - Tag (close-up AND inspect): 7:20 hand positions unambiguous on the mini dial.
- iPhone: nothing interactive within 24 pt of screen edges; pill/chevrons respect
  safe-area insets (unchanged series rules).

---

## 12. DO-NOT list for Asset Generation (Level-2-specific drift risks)

1. **Do not add hands to the world-clock row.** Four hand-less faces with bare arbor
   holes is the spec; models will "helpfully" complete them. Reject any generation
   where a row clock has hands. Same vigilance: no hands on the door dial.
2. **No IIII, ever.** Standard subtractive numerals only (IV, IX), in the canonical
   letterforms. Reject IIII on any dial, tile, or stamp on sight.
3. **No legible "VII" anywhere on the great dial's back view**, and the mirrored IV
   must stay a *malformed* VI (4.2). This plate is the level's most protected asset —
   verify glyph by glyph.
4. **No text/letters/words/watermarks**; only the Section 0 glyph whitelist. Ledger
   spines, tag, crates, plates: pictograms and numerals only.
5. **No photoreal brass** — no macro-lens metal porn, no mirror polish, no HDR glints.
   Brass is dulled, edge-worn, stylized-PBR per the fixed template. Equally: **no
   painterly/matte-painting texture** — the template's engine-render look is
   non-negotiable in both directions.
6. **No Victorian-postcard sepia.** The warmth is golden-hour *light* over a full
   palette (cool steel, slate, sky, verdigris survive intact) — never a global
   brown-tinted grade. If a candidate looks antiqued/monochrome-warm, reject.
7. **No visual tell on the cache board or brick in ANY state or pre-open frame** —
   identical to neighbors (D10 is animation/SFX only). No loose edges, no gaps, no
   discoloration.
8. **No keyhole on the stair door's time-lock housing** (D8) — a smooth plate; and no
   keyholes invented anywhere else.
9. **No chalk sketch beside the z3 setting crank** — the D9 easing valve is DORMANT;
   only the reserved clear space ships.
10. **No color-coding anywhere:** gears differ by size + teeth + stamp; wheels by
    engraving + header die; tiles by numeral. All same-family finishes. Verdigris and
    metal-tone differences stay ambient.
11. **No people, no figures** except the carved mural's jointed automaton figures
    (clearly wooden, jointed, part of the machine) and the Liberty pictogram die.
12. **No time-of-day drift:** every plate is the same held golden-hour minute (Section
    3); the sole exception is the sanctioned win-beat evening step (F4). No noon light,
    no blue hour, no candles-everywhere.
13. **Exact counts are contracts** (4.4): 24 tallies, 12 notches, 12 sockets, 7 rays,
    exact gear teeth. Count before accepting; expect PIL/manual correction passes on
    tooth geometry (F6).
14. **The cat stays a cat** (9.1): no cartoon eyes, no smile, no bow/collar.

---

## 13. Flags for the user (step-8 style checkpoint)

- **F1 — Display-case paint-over emphasis: ADOPTED (AD discretion the playtest offered).**
  Spec'd one notch more emphatic (sealed screw slots, skinned paint seam — Section 6.5)
  so the ~40-min false goal dies faster at close-up while the case stays an honest,
  attractive red herring. Say the word to revert to the plainer rev-1.2 read.
- **F2 — Pause glyph:** engraved winding-key mark for L2 (vs keeping L1's rune as a
  single series-wide mark). Either is one tiny asset; recommend the key for diegetic
  cohesion. Needs a pick.
- **F3 — Cat design register:** gray-blue shorthair, amber eyes, real-cat dignity
  (9.1) — the series' second living presence, so its design deserves the same sign-off
  the crow got.
- **F4 — Win-beat lighting step:** the final stair-door-open plate shifts one step
  toward evening amber — "the held minute finally moves." Only lighting deviation in
  the level; confirm it's welcome.
- **F5 — Color-blind audit: PASS, no conflicts found.** The graph specifies zero
  color-differentiated puzzles; every distinction is shape/size/count/position/motion
  (gear size+stamp+teeth, silhouette dies, engraved numerals, weight height, bar
  position). This guide adds no color-coding; grayscale check gates every deliverable.
- **F6 — Exact-tooth-count risk (execution, not design):** generative output is
  unlikely to hold exact tooth counts on seven gears; plan on per-gear prop plates
  with count verification and manual/PIL correction (budget note for Asset Gen, not a
  style question). Flagged so the correction passes surprise no one.
