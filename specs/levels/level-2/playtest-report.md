# Level 2 — Blind Playtest Report ("The Clockmaker's Attic")

_Blind Playtester pass against `blind-layout.md` only. Per the Producer's absolute
isolation directive for this run, `puzzle-graph.json`, `puzzle-graph-summary.md`, and
`validation-report.md` were NOT opened at any point — including after the pass — so the
usual intended-vs-discovered annex is deliberately omitted. Everything below is inferred
from player-visible information alone; where the layout is ambiguous about hidden gating,
the ambiguity itself is reported as a finding._

---

## 1. Main pass — narrated blind playthrough (condensed, honest)

### Zone 1 (minutes 0–18)

First sweep: take the screwdriver, tile II off the stove, tile IV and the ⌂/III pocket
watch from the coat, tile VII from the crate, tile XI from the windowsill. The chalk
slate reads immediately as a schematic of *something* — crank, 24 tally marks, gear XII,
"?", gear VIII on the same axle, "?", one-notch wheel, little door. I photograph it
mentally but can't act on it yet.

The workroom door dial is the obvious first lock: four empty sockets at the 2, 4, 7, 11
positions; I'm holding II, IV, VII, XI. Seated all four in about a minute. I did pause
at the tray tile VI — my first instinct was "the tray tile must be the missing one," and
I tried it in the 4-socket before checking my inventory (VI upside down looks
plausible-ish at a glance). Whir, pop, back to tray. Cheap lesson, good pop-out
feedback. **Door open ~6 minutes in.**

Before going through: the cat. "Something flat visibly tucked beneath the cushion" is an
excellent telegraph — I immediately want it. Petting, nudging, offering the screwdriver:
identical slow blink every time. Shelved with a mental bookmark. Also noted: the ⌂
carving with twelve notches by the dormer, the ★ on the longcase clock stopped at 6:00,
the barometer (inspected, filed as "weather... for later?" — it never became anything),
the keyhole-less stair bar (clearly remote-driven; correctly read as "endgame, ignore").

I did NOT yet connect the ⌂ watch (hand on III) to the ⌂ carving. The connection was
available; I just walked past it.

### Zone 2 (minutes 18–70, with two backtracks to Zone 1)

The automaton wall is clearly the slate's machine: crank pinion stamped XII, post A
sharing an axle with the fixed VIII pinion, post B into a cam. The slate is a build
diagram — the two "?" circles are the two empty posts. Two problems present at once:
the crank is rust-jammed, and I need to choose gears.

**Gear math (minute ~25):** 24 tally marks around the crank + one-notch cam + door
sketch = "24 crank turns should make one cam revolution." Ratio needed:
(A/12) × (B/8) = 24, so A × B = 2304. I checked every pair from the rack —
16, 24, 36, 40, 48, 72 — and *nothing multiplies to 2304*. First reaction: I've got the
formula wrong. Rechecked twice. Then the good aha: 2304 = 36 × 64, and no 64 exists on
the rack — **so a 64-tooth gear is hidden somewhere.** That reframed the whole attic as
"where's my 64?"

**STUCK EVENT S1 (~10–12 min, minutes ~30–42):** I knew I needed a hidden gear and had
no idea where. Pried at a few random floorboards and bricks with the screwdriver —
"doesn't budge," identical every time, which I read (correctly, I think) as "wrong spot"
rather than "wrong tool." What unstuck me: re-inspecting inventory. The ⌂ watch, hand on
III — and I remembered the ⌂ carving by the dormer *ringed by twelve notches like a
clock face*. Watch = which notch. Went back to Zone 1, treated the carving's notch ring
as a dial, projected the III (3-o'clock) direction onto the floor, pried the board
there: shallow cavity, bronze wheel, 64 teeth, "64" stamped. Genuinely satisfying —
the stamp confirming my computed number is a great "the game shook my hand" moment.

**The rust / oil chain (minutes ~42–60):** Crank still jammed. Rust bloom = need oil.
The parts cabinet gave me the wind-up mouse; the display case of spare clock hands
taunted me — screwed shut, and I'm holding a screwdriver. I tried unscrewing it twice
(the painted-over frame is visible, but with a screwdriver in inventory you *will* try).
The chimney brick with the ⚙ carving and twelve-notch ring now pattern-matched instantly
to the dormer carving: "I need a ⚙ watch." Only unexplored flat thing in the game: under
the cat. Offered the mouse to the cat — **slow blink, mouse returned unused.** That
rejection genuinely cost me ~5 minutes of doubt ("okay, not the mouse... then what?").
What recovered it: the mouse's only other verb — wind it and set it on the floor. Set
it down by the dormer bench: cat off cushion. Second watch: ⚙, hand on IX. Chimney
carving, IX position, pry: oil can. Oiled the crank bearing. This whole chain, once
moving, is the best stretch of the level — three carved-symbol/watch/pry beats that
rhyme with each other.

**Running the mural (minutes ~60–70):** Mounted 36 and 64 (tried 64 on post B first for
no principled reason), cranked. Figures run, and at what felt like the 24th turn —
instead of the ratchet-slip clack I'd heard during an earlier wrong-gear test — the
wall panel opened. Zone 3.

(Note: during the jammed period I had, at all times, at least two live threads — gear
hunt, cat problem, plus the world-clock plates to chew on. I never had "nothing to do.")

**World-clock row:** read on first visit as "I must find hands for these" — reinforced
by the display case full of hands. That false goal survived until Zone 3. The plates
(Burj +IV, Big Ben ★, Fuji +IX, Liberty −V) I copied down without yet knowing their
lock.

### Zone 3 (minutes 70–92)

Behind the great dial: gorgeous read. Mirror-written numerals noted immediately as
"this will matter." The winding drum squeals — after the crank bearing, I knew the
answer on sight: oil it (pattern echo, zero friction). Key socket is square; the mouse's
butterfly key doesn't fit (tried it, returned). Pushed the pendulum because pendulums
demand pushing.

**The hatch (minutes ~74–86):** Four wheels I–XII, headers = the same four landmark
silhouettes. Direct match to the plates. Big Ben's plate has only a ★ — and the ★ is
also on the hatch header — and the longcase clock in Zone 1 wears a ★ and is stopped at
**6:00**. That's the linchpin aha of the level: Big Ben = VI, and the other plates are
*offsets from it*. VI; VI+IV = X; VI−V = I; VI+IX = XV → wraps to III. The wrap on Fuji
made me hesitate ~2 minutes ("XV isn't on the wheel... oh, it's a clock, it wraps").
Header order Big Ben / Burj / Liberty / Fuji → **VI, X, I, III**. Set the wheels — no
reaction — brief flinch ("wrong?") — then tried the hatch itself and it released. (See
fairness table: the silent wheels plus needing to tug the hatch is a small bug-read
risk.)

I never needed to know a single real time zone: the offsets are stamped, the landmarks
only need to be matched silhouette-to-silhouette. The "world clocks with no hands" were
never fixable at all — the plates were the puzzle. In hindsight the hand-less clocks +
sealed hand case is elegant misdirection; in the moment it held a false goal for ~40
minutes of game time.

### Zone 4 + finale (minutes 92–115)

Strongroom: winding key, shop tag. Tag read: hour a third past VII, minute on IV — IV as
minutes = 20, and a third past 7 *is* 7:20 — the clue self-verifies, which I appreciated.
Door pictogram beneath = "the door opens at 7:20." Second cushion and saucer: smiled,
filed as flavor (the cat had already relocated to the stair door).

Back up: oiled the drum, key turned, weight wound, pendulum swinging. Now set 7:20 on
the mirror dial.

**STUCK EVENT S2 (~10 min, minutes ~100–110):** First attempt — I hunted the glyphs from
behind and put the minute hand on the numeral that *reads* "IV." Nothing fired. Movement
alive (pendulum, wound drum), hands set, no chime — for a couple of minutes this read as
"is the trigger broken?" What unstuck me: I went looking for the glyph reading "VII" for
the hour hand **and it does not exist anywhere on the dial** — the true VII mirrors to
"IIV," gibberish. That absence is the alarm bell: in mirror-writing, glyph *order*
reverses, so the thing reading "IV" is actually the VI, and vice versa (I/V/X are each
symmetric; only their order flips). Re-set: hour a third past the "IIV" glyph, minute on
the glyph reading "VI" (true IV). Chimes, the whole ceiling rod-run articulates from
the dial chamber to the stair door, the bar lifts, the cat stands and stretches.
Excellent finale — the room-as-one-machine premise pays off physically.

**Main-pass total: ~110–115 simulated minutes.**

---

## 2. Behavioral variant passes

### 2a. The impatient pryer

Takes the screwdriver in the first thirty seconds and pries everything before reading
anything.

- **What they experience:** dozens of identical "doesn't budge" results across dormer
  boards and (later) chimney bricks. The blind layout is explicit that non-yielding
  spots respond identically every time and that nothing distinguishes the correct board
  or brick visually.
- **The fork the layout cannot answer — flagged for the designer as the single most
  important implementation question in this level:**
  - **If the correct board/brick yields to the screwdriver at any time (no knowledge
    gate):** the pryer, by exhaustively working the dormer area, hits the right board
    early and obtains the 64-gear *before ever reading the slate*, and later the oil-can
    brick *without ever moving the cat*. They finish the level having skipped the ⌂/⚙
    watch chains entirely — the cat, both hidden watches, and the carving-dials become
    optional set dressing. The level still completes; two of its three best clue chains
    go unexperienced.
  - **If the correct board/brick is gated until the matching watch is held/inspected:**
    this player pries the *correct* board early, receives the same "doesn't budge" as
    every wrong board, and — this is the critical behavioral finding — **writes the
    floorboards off as scenery.** When the ⌂/III clue later points them back to a spot
    they have personally certified as inert, the identical negative feedback has
    actively poisoned the clue. In simulation this player does eventually return
    (the watch/carving pairing is strong enough to force one more try), but only after a
    long stall and with real "the game lied to me" resentment. Estimated stall: 15–25
    minutes; a less persistent player could hard-stall here.
- **Self-recovery verdict:** recovers in the ungated world (trivially — they were never
  stuck, just unenlightened); recovers *grudgingly* in the gated world. Either way the
  designer should consciously pick a lane; see tweaks.

### 2b. The math-averse player

Refuses the slate algebra; just mounts gear pairs and cranks.

- **Before finding the 64-gear:** 6 rack gears = 15 pairings, every one of which fails
  (per my math no rack pair can be correct). Each test costs cranking until the cam
  clack — anywhere from a few turns to dozens depending on the pair. Exhausting all 15
  with nothing but the identical ratchet-slip clack is **20–30 minutes of grinding to
  learn a pure negative**, and the failure mode ("it always slips back") can read as a
  broken machine rather than wrong gears. The one mercy: total exhaustion *does* imply
  "a gear is missing," which points back at the world.
- **After finding the 64:** 21 pairings. Two feedback channels exist: mural speed
  (weak — the target ratio is not an extreme, so "faster/slower" doesn't hill-climb)
  and the clack cadence (strong, if noticed): a player who counts cranks-per-clack can
  discover "the slate's 24 tallies = 24 cranks per clack" and tune toward it without
  ever multiplying anything. That counting path is genuinely lovely and rescues this
  variant — but only if the player thinks to count.
- **Tedium rating: moderate-high.** Bounded, never punished, but the pre-64 phase is a
  long dry lottery. Time to stumble into success (with 64 in hand, not counting):
  15–40 minutes of trials.

### 2c. The hasty reader

Takes every clue at face value, never double-checks.

- **Tray tile VI at the 4-socket:** tries it, whir-pop, self-corrects in seconds. Fine.
- **Slate tallies as "crank 24 times":** cranks 24 turns with arbitrary gears, gets a
  clack at some unrelated count (or mid-cycle nothing), briefly suspects a bug. The
  clack's regular cadence eventually reteaches it as a ratio. ~5 min lost.
- **World clocks:** locks instantly onto "find hands," and the screwed-shut case of
  hands confirms the theory. This player spends the longest at the case and may revisit
  it repeatedly. Perceives it as "I'm missing a tool," not a bug — acceptable, but it
  overstays (see fairness).
- **Shop tag:** risk of reading minute-on-IV as "7:04" — and the hand-set crank's
  five-minute stepping physically refuses 7:04. That guardrail works: the mechanism
  itself corrects the misread. Quietly excellent.
- **Mirror dial:** this is where the hasty reader crashes hardest — sets what reads as
  7:20 from behind, gets silence from a visibly alive movement, and of all player types
  is the most likely to perceive **bug, not error**, because every component gives
  positive feedback (swinging pendulum, wound weight, turning crank) except the final
  trigger. The in-scene evidence that can pull them back exists — the crisply reversed
  glyphs, and the total absence of a legible "VII" — but a player who doesn't re-read
  won't see it. Estimated loss: 15–30 minutes; worst realistic stall in the level for
  this archetype.

---

## 3. STUCK events (main pass) and unstick analysis

| # | Where | Duration | What unstuck it |
|---|-------|----------|-----------------|
| S1 | Need a 64-tooth gear, no idea where | ~10–12 min | Re-inspecting inventory: ⌂ watch (III) + remembered ⌂ carving's twelve-notch ring → carving-as-dial → pry at III |
| S2 | Mirror dial: correct-looking 7:20 fires nothing | ~10 min | Hunting for a legible "VII" and finding none → glyph order reverses in mirror → IV/VI swap realized |
| near-stuck | Mouse offered to cat, returned unused | ~5 min | Mouse's only other verb (wind + set on floor) tried near the cat |

---

## 4. Blind solve-time estimates

| Segment | Estimate (competent first-timer) |
|---|---|
| Zone 1 (tiles, first sweep) | 10–18 min |
| Zone 2 (slate math, 64-hunt, cat/oil chain, mural) | 35–60 min |
| Zone 3 (hatch code) | 10–20 min |
| Zone 4 (pickups + tag read) | 3–6 min |
| Finale (restore movement, mirror time-set) | 12–30 min |
| **Total** | **~70–135 min, median ≈ 100 min** |

Per-puzzle blind-solve estimates: door tiles 3–6 min; gear ratio (with hunt) 25–45 min;
cat/mouse/cushion 5–15 min; carving-dial prys 5–15 min each once the pattern lands;
hatch code 8–18 min; final time-set 8–25 min.

**Hardest single inference:** the mirror-dial time-set — specifically realizing that
mirror-writing swaps glyph *order* so the readable "IV" is really the VI. (Runner-up:
carving-notch-ring + watch-hand = *which* board/brick.)

**Best aha:** the ★ chain — Big Ben's plate stamped only ★, the hatch header's ★, and
the ★ longcase stopped at 6:00 snapping together so the whole code cascades from
offsets. Honorable mention: computing 2304, finding no rack pair works, and *deducing a
hidden 64-tooth gear must exist* — the "64" stamp on the found wheel is a perfect
confirmation handshake.

---

## 5. Fairness-of-feel audit

| Pain point | Feel | Rating |
|---|---|---|
| Uniform boards/bricks with identical "doesn't budge" — correct spot indistinguishable until it yields; interacts badly with early prying (see 2a fork) | Pixel-hunt-adjacent; fair *only if* the clue path and pry feedback are reconciled | **flag** |
| Mouse offered to cat is returned unused (correct item, wrong verb, explicit rejection) | False-negative feedback on the right idea; classic stall-maker | **flag** |
| Mirror-dial silence on a wrong time while every sub-system gives positive feedback | Reads as bug to hasty players; the no-legible-VII tell is great but passive | **friction** |
| Display case of hands, screwed shut, while player holds a screwdriver; hand-less clocks sustain the false "find hands" goal for a long stretch | Fair misdirection with a visible paint-over tell, but it overstays and double-teams with the world clocks | **friction** |
| Hatch wheels give no reaction even on the correct code until the hatch itself is tried | Momentary bug-read; cheap to survive | **friction** (minor) |
| Math-averse pre-64 phase: 15 pairings, all fail identically | Long dry negative; "machine is broken" risk | **friction** |
| Tray tile VI glyph bait | Cheap, instantly-corrected, teaches the socket feedback | fine |
| Barometer decoy (weather pictograms near a sun-track mural) | Inspect-once, mild theorizing, no time sink | fine |
| Real-world knowledge load (landmark silhouettes only; offsets are stamped, no time-zone knowledge needed) | Well inside educated-generalist; wrap-past-XII is the only twist | fine |
| Butterfly key vs square socket, second cushion/saucer flavor | Harmless | fine |
| Color-blind exposure | None observed — every discrimination in the level is shape, count, glyph, or position based | fine |

No moon logic found: every solution I reached traced back to something I had seen.

---

## 6. Pacing

- **Zone 1 sings:** dense, generous, the tile lock pays out in minutes, and the room
  plants five long-fuse elements (slate, ★ clock, ⌂ carving, cat, barometer) without
  clue pile-up.
- **Zone 2 is the meaty middle and mostly earns it.** Parallelism is genuinely good —
  jammed crank, gear choice, cat problem, and plate-copying are all live at once; I
  never experienced "nothing to do." The one sag risk: a player who misses *both* the
  mouse-placement insight and the ⌂-watch link at the same time has only dead decoys
  (case, barometer) to grind against.
- **Zone 3 is tight** — the hatch code is a pure thinking beat after Zone 2's legwork,
  and it can even be pre-computed before the panel opens, which sharp players will love.
- **Zone 4 is a well-placed breather**, and the finale — chimes, the rod-run visibly
  articulating the length of the level, the bar lifting, the cat stretching — is the
  best single moment in the game so far. The room-as-one-machine promise is kept.
- **Difficulty curve vs Level 1:** lands. Level 1's chains were softer single-hop
  associations; Level 2 demands one genuine derivation (gear ratio), one cross-zone
  synthesis (★/offsets), and one perceptual reframe (mirror order). It plays clearly
  harder without ever feeling arbitrary — from the player's eye, the escalation is real.

---

## 7. Verdict

**READY-WITH-TWEAKS**

1. **Resolve the pry-gating fork deliberately (flag, highest priority).** Either commit
   to ungated yields and accept that the watch/carving chains become skippable
   shortcuts, or, if gated, give the *correct* board/brick a minutely different response
   when pried un-clued (a creak, a hair of movement) so an early failed pry doesn't
   poison the later clue. As specced-blind, the impatient pryer either skips the level's
   best content or gets lied to — both lanes need a conscious choice.
2. **Un-poison the mouse-on-cat rejection (flag).** The correct item being explicitly
   returned unused when offered directly is the level's clearest false negative. Any
   asymmetry in the cat's reaction to the mouse specifically (ear swivel, tail flick,
   eyes tracking it) — or letting the direct offer route into the floor-release
   behavior — keeps the puzzle while removing the trap.
3. **Give the fully-restored-but-wrong-time state a sign of life (friction).** When
   drum is wound, pendulum swinging, and hands set to a wrong time, some minimal idle
   response (a tick, a half-hearted hammer twitch) would convert "is this broken?" into
   "alive, but wrong time" — protecting the hasty reader through the level's hardest
   inference without weakening the mirror trap itself.

Secondary (fine to ship as-is, worth a thought): the hatch could acknowledge wheel input
generically; the display-case paint-over could be one notch more emphatic in close-up.

_Intended-vs-discovered annotations omitted per the Producer's absolute isolation
directive for this run — puzzle-graph materials were never opened._
