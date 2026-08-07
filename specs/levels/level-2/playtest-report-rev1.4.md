# Level 2 — "The Clockmaker's Attic" — Blind Playtest Report, rev 1.4 RE-CHECK

**Playtester:** Blind Playtester agent
**Input:** `specs/levels/level-2/blind-layout.md` (rev 1.4 refresh) — sole gameplay input
**Isolation:** `puzzle-graph.json`, `walkthrough.md`, validation reports, and the solution
sections of `clue-legibility-p06-p03.md` were NOT read at any point, before or after.
After the blind pass concluded I read only §9 (lines 1038–1104) of
`clue-legibility-p06-p03.md` — the P1–P14 probe checklist — to structure this report. That
section names probes, not solutions; nothing in it revealed an answer I had not already
derived. **No intended-vs-discovered annotations appear in this report**, because I never
opened the dependency graph. Where I flag a risk, it is a risk I hit as a player.

**Headline:** the two clue-legibility changes (frame-cheek crib + live tally readout; chalk
mark on the cache board) both work, and both work *well*. The gear wall is no longer
guide-mandatory — it is now the level's best beat. The rendering fixes to the mirrored dial
and the mouse/cat also hold up. **One beat regressed as a side effect of the fix to another**:
the chalk mark that rescued the dormer cache removed the reasoning that the chimney cache
depends on. That is the single finding worth acting on.

**Overall verdict: READY-WITH-TWEAKS.** Overall difficulty ≈ **6.0** (target hit).
Blind completion time **70–95 min**, median **~80 min**. No beat is guide-mandatory.

---

## 1. Per-beat verdicts at a glance

| # | Beat | Verdict | Blind difficulty (1–10) | Est. blind solve time |
|---|------|---------|------------------------|----------------------|
| 1 | Door-dial numeral tiles | SOLVABLE-BLIND | 2.0 | 6–10 min (mostly search) |
| 2 | Dormer floorboard cache (⌂) | SOLVABLE-BLIND | 3.5 | 4–8 min |
| 3 | Tin mouse + cat | SOLVABLE-WITH-FRICTION | 4.0 | 3–9 min |
| 4 | Chimney brick cache (⚙) | **SOLVABLE-WITH-FRICTION (high)** | **6.5** | **10–20 min** |
| 5 | Oil applications (frame, drum) | SOLVABLE-BLIND | 1.5 | 1–2 min each |
| 6 | Automaton gear wall | SOLVABLE-BLIND | 7.0 | 12–25 min |
| 7 | World-clock row → hatch combination | SOLVABLE-BLIND | 5.0 | 6–12 min |
| 8 | Mirrored great dial (time to set) | SOLVABLE-WITH-FRICTION | 6.5 | 8–15 min |
| 9 | Endgame assembly (wind / pendulum / strike) | SOLVABLE-BLIND | 2.5 | 5–8 min |

Plus a **herring tax of 8–15 min** (see §7), dominated by the sealed display case.

Weighted overall: **5.8–6.2**. The provisional 6.0 is confirmed from the player's side.

---

## 2. Deep beat 1 — The automaton gear wall (p06)

**Verdict: SOLVABLE-BLIND.** Difficulty 7.0. This was guide-mandatory before; it is not now.

### My actual inference chain, in order, with attempt count

1. **(~30 s)** Walk up to the frame with both posts bare. I can state the drive path
   immediately and without hesitation: *crank → its fixed XII pinion → **[gap]** → post A →
   post A's fixed VIII pinion on the same axle → **[gap]** → post B → cam → into the wall.*
   The phrasing that does this is the two pinions "turning against nothing at all." The
   empty posts read unambiguously as **gaps in a drive line**, not as decoration. The
   square-arbor shape plus a visibly wheel-sized void is enough on its own; I did not need
   the slate to know what goes where.
2. **(~1 min)** Try the crank. It rocks a few degrees and jams; there is a bloom of rust on
   the main bearing. Read instantly as "needs oil." Parked as a separate errand. Note that
   **this is the moment the beat becomes untestable** — see §5.
3. **(~2 min)** Notice the chalk on the timber cheek. Same hand as the slate in the attic —
   I recognized the hand before I recognized the content, which is a good hook. A block of
   24 in fives at the **crank end**; one lone matching stroke at the **cam end**, the length
   of the frame away. Read: *24 of this per 1 of that.* I did not have to go back to Zone 1
   to get the target proportion. I did want ~2 min of staring to be confident the spatial
   placement meant what I thought it meant — confidence only became certainty in step 8,
   when the live readout appeared in the same notation.
4. **(~1 min)** Recall the slate. It is the same statement drawn as a schematic: crank(24) →
   XII → ? → VIII → ? → notched cam(1) → door. The stamped **XII** on the crank pinion and
   the stamped **VIII** on post A's pinion match the slate glyph-for-glyph. That
   correspondence is what converts the slate from "atmospheric doodle" to "blueprint for
   the thing in front of me," and it is the single most valuable link in the level. It fires
   reliably because the numerals are stamped **on the pinion faces themselves**.
5. **(~4 min)** Do the algebra. Reduction = (A/12) × (B/8) = 24, so A × B = 2304.
6. **(~5 min)** Walk the rack: 16, 24, 36, 40, 48, 72. Products: 384, 576, 640, 768, 1152,
   864, 960, 1152, 1728, 1440, 1728, 2592, 1920, 2880, 3456. **Nothing is 2304.** The two
   nearest straddle it — 40×48 gives exactly 20, 36×72 gives exactly 27 — with a clean hole
   between them. This is excellent: it is not "I couldn't find it," it is a **proof that a
   gear is missing**, and it arrives as a positive result rather than a failure.
7. **(~30 s)** Immediate recall: the bronze wheel from the dormer cavity, sixty-four teeth,
   stamped 64, which I had been carrying with no idea what it was for. 36 × 64 = 2304. This
   is the level's best single moment — a long-held mystery item snaps into place, and it
   snaps in *because of arithmetic I did myself*, not because it was the only thing left.
8. **Mount and crank (attempt 1 of 1 after oiling).** Strokes accrue below the baseline, in
   fives, in the same chalk. Block of 24, no half-stroke, clack. Match. Panel.

**Attempt count: one.** I never mounted a wrong pair on the real solve, because the algebra
resolved first. I mounted wrong pairs afterwards only to run probe P13.

### Route used (P5)

A hybrid, and I think this is the *typical* path rather than an unusually clever one:
**algebra first from the slate/crib (Route A), the tally readout as confirmation, and the
"no rack pair works" result as the bridge to the missing gear.** Actual reasoning time for
p06 in isolation: **~14 min**. Total wall-clock including the oil errand and the walk back:
25–35 min.

A player who cannot or will not do the two-stage algebra has a fully sufficient fallback:
mount anything, crank, read the count, and hill-climb. The readout is **monotonic** in gear
size, so two trials establish the direction. Hill-climbing tops out at 27 (36+72) and finds
nothing between 20 and 24 — so **even the non-algebraic player reaches the "a gear is
missing" conclusion**, just empirically instead of deductively. That redundancy is what
takes this beat off guide-mandatory. Uniqueness holds: with the 64 in play, exactly one of
the 21 unordered pairs yields 24. Confirmed by exhaustion, not by trust.

*(Note: the total ratio is A×B/96, so order across the two posts is commutative — 36/A+64/B
and 64/A+36/B both compute to 24. Whether the build accepts both is invisible from the
layout. If only one is accepted, a player who has done the math correctly can be told "no"
by the machine, which would be the one genuinely unfair moment in the beat. Worth a
one-line check by whoever owns the build; I could not test it.)*

### P6 — did the crib or the readout feel like the game solving itself?

**Honest answer: no, but it is close to the line, and I want to be precise about where the
line is.** The frame crib (24 at the crank end, 1 at the cam end) is pure restatement of
information already on the slate, relocated to the point of use. That is legibility, full
stop — it removes a memory tax, not a reasoning step. The **live tally readout is the item
under suspicion**, and my judgement is that it survives, for three reasons:

- It reports **state, not correctness**. It never says right or wrong; it says "this
  configuration produces N." The player still has to know that 24 is the goal, and has to
  get there.
- The target block and the live block are in the **same notation**, so comparing them is a
  perception act the player performs, not a verdict the game delivers.
- It cannot shortcut the beat's actual gate, which is **the missing seventh gear**. The
  readout makes the search tractable; it does not make the bronze wheel appear.

What it *does* do is lower the beat's ceiling. Pure-algebra p06 with no readout would rate
~8.0–8.5 and would be guide-mandatory for a meaningful fraction of players (the prior real
player is the evidence). With the readout it rates 7.0. Given a target of 6.0 for the level
and this being the intended peak, **7.0 is the right number** — it is still the hardest
thing in the room by a clear margin. I would not add anything further here; one more aid and
it would tip into self-solving.

---

## 3. Deep beat 2 — The dormer floorboard cache (p03). Does it resolve to a LOCATION?

**Verdict: SOLVABLE-BLIND.** Difficulty 3.5. **Yes, it resolves to a location — but not by
the route the beat is built on.** This is the important nuance.

### Chain as experienced

Search the coat → pocket watch, one hand, stopped on **III**, **⌂** on the case back. The
one-handed dial is a good piece of design: a normal watch would read as a time, but one hand
reads as a *pointer*, which is the correct frame. Then, in the stair-door view, the carved
**⌂** on the beam ringed by twelve notches. Symbol match ⌂↔⌂ is about as loud as an
adventure-game affordance gets; I tried the watch on the ring within seconds of seeing both,
with essentially zero deliberation. A hand appears across the ring pointing at III. And a
small chalk **⌂** appears on one floorboard.

**Time from entering the stair-door view with watch A inspected to prying the correct board
(P7): under 60 seconds, zero random clicking.** Target comfortably met.

### P8 — did I understand *why* that board? (In my own words)

*"Because it had a house mark on it, and the house mark matches the house watch I just put
on the house ring."*

That is the whole of my reasoning, and I want it on the record that **it contains no
reference to the III bearing.** I registered a causal chain — watch → ring → mark appears —
so C1 is not entirely absent; I knew the ring *caused* the mark. But I never read the hand
as a **direction**, never noticed that the marked board lies at 3 o'clock from the ring, and
had no occasion to. The mark answered the question before the bearing could be asked.

So: **C2 is carrying this beat outright. C1 survives only as an opt-in that I did not take.**
The mark is a training wheel that prevents the training. That is fine here — and fatal at
the chimney. See §4.

### P9 / P10

- **P9 (pre-inspection uniformity):** Visiting the stair-door view before inspecting watch A,
  the boards are uniform and nothing hints at a cache. No wear pattern, no gap, no seam,
  nothing. **Pass.** I would not have found this by looking.
- **P10 (diegetic or game-pointing-at-itself):** **Mostly diegetic.** The mark is chalk, in
  the clockmaker's hand, and by the time I see it I have already seen that same hand on the
  slate; later I see it again on the frame cheek and the crib. Four instances of the same
  person chalking on the same surfaces in the same style is a strong in-world alibi. There
  *is* a brief "the game just drew that for me" flicker, because it materializes at the
  instant I seat the watch — the timing is game-timing, not world-timing. But the flicker
  passes in about a second and the fiction reabsorbs it. Rate it **8/10 diegetic**.

---

## 4. Deep beat 3 — The chimney brick cache (p04), and probe P12 at length

**Verdict: SOLVABLE-WITH-FRICTION (high). Difficulty 6.5. Est. 10–20 min, of which 8–15 is
pure stall.** This is the level's highest-risk beat and the one place where I would say the
rev 1.4 changes made things *worse* than they were, as a second-order effect.

### P12 (a) — Did I expect a mark on a brick?

**Yes. Emphatically, and immediately.** The dormer taught me a complete, clean, four-step
grammar: *find symbol ring → find matching watch → seat watch → **a mark appears** → pry the
marked thing.* When I reached the chimney and found a ⚙ ring and had a ⚙ watch, I did not
experience this as a new puzzle at all. I experienced it as **the same puzzle again**, and I
executed the learned sequence expecting the same fourth step.

### P12 (b) — How long did I spend looking for a mark before I used the ring?

I used the ring almost immediately (the ⚙↔⚙ match is as loud as ⌂↔⌂). The problem is what
happened **after**. I placed the watch, the hand appeared at IX — and then I spent **8–12
minutes hunting for a mark that does not exist**, scanning the brick field in the wide view,
then in close-up, then re-checking whether I had the right watch, then re-checking whether
the hand had actually seated.

### P12 (c) — Did the absence read as a negative signal?

**Yes, and this is the finding.** The absence did not read as *nothing*; it read as
*"this cache isn't available yet."* My literal internal narration was: *"the mark hasn't
been triggered — there must be another step I haven't done."* I then went and did something
actively counterproductive: I **left the chimney and re-searched Zones 1 and 2 for a missing
trigger**, on the theory that some other action makes the clockmaker's mark appear on
masonry. That cost most of the stall. I did not conclude "the game is broken" — the game
never felt buggy — but I did conclude "the game is not done with me yet," which is
functionally the same stall with better manners.

The asymmetry therefore reads as **neither a bug nor a deliberate escalation. It reads as an
unmet precondition.** That is the worst of the three available readings, because a bug
reading would at least make me try something else, and an escalation reading would make me
look at the hand. An unmet-precondition reading sends me *out of the room*.

### P12 (d) — Once I did use the ring, did the 9 o'clock bearing land on the brick field by itself?

**Yes — instantly, and cleanly, once I finally re-framed the hand as a direction.** IX is
straight left at the same height as the ring; it is one of the four cardinal bearings and
requires no angular estimation whatsoever. The moment the re-frame happened, the beat
resolved in under 30 seconds. **The bearing is not the problem. Getting the player to look
at the bearing is the problem.** (The pairing of III at the dormer and IX at the chimney —
both pure cardinals — is a real kindness and I want to credit it; a bearing of, say, VII or
XI would have added angular-estimation friction on top of the framing friction and pushed
this beat to guide-mandatory.)

### P12 (e) — Deliberate teach-then-test escalation, or a bug?

**Neither, as experienced.** The design intent is legible *in retrospect*: p04's bearing
resolves in-scene and p03's did not, so p03 gets a mark and p04 does not. As a designer's
sentence that is coherent. As a player's experience it never arrives, because **p03 never
taught me to read a bearing**. The escalation cannot land as "teach, then test" when the
teaching step was skipped — I was tested on a skill the tutorial handed me the answer to.

The in-world justification that would have rescued it (chalk does not show on sooty brick)
is available but unsignposted — there is no soot, no smudge, no failed chalk stroke, nothing
that says *the clockmaker could not have marked this one*. Every other chalk instance in the
game is on wood or slate, which is a real pattern, but it is a pattern a player has to
reconstruct rather than notice.

**Fairness call: fair-but-tricky, at the outer edge of fair.** Nothing lies to the player,
attempts are free, the recovery path is short and satisfying, and the brute-pry fallback
caps the worst case. But 8–15 minutes of stall in which the player's best hypothesis sends
them to a different zone is a lot of friction to buy with a single removed chalk mark. The
Designer owns the fix; I will only say that the friction is real, it is the largest in the
level, and it is caused by the dormer's *strength*, not the chimney's weakness.

### Why this matters more than its difficulty number: it is a sole-thread chokepoint

I checked what else is open at the moment the chimney stall begins, and the answer is
**almost nothing**:

- The oil can is behind this brick, and it is the *only* oil in the room. It is needed
  **twice** on the critical path — the gear-frame bearing and the winding-drum bearing.
- The gear wall is rust-jammed, so it cannot be cranked and the tally readout — the fallback
  that makes p06 solvable — **cannot be reached**.
- Zone 3 does not exist yet, so the hatch and everything past it are unavailable.
- The world-clock row has no target time context yet and no input surface.
- The cat/mouse and both caches are done.

The only genuinely open action is **mounting gears on the two posts without being able to
test them**. So a chimney stall is not "get stuck on one thing while other threads breathe";
it is a **hard wall with one silent thread**. And because the stall's own dominant
hypothesis is "I have missed a step elsewhere," the player will spend that time searching
zones that contain nothing.

This compounding — riskiest-framing beat sitting directly upstream of the level's hardest
beat *and* of that beat's safety net — is my strongest pacing note in this report. It is
also, mechanically, why the prior real player needed the walkthrough for *both* p04 and p06:
they are one failure, not two.

---

## 5. Deep beat 4 — The mirrored great dial

**Verdict: SOLVABLE-WITH-FRICTION.** Difficulty 6.5. Est. 8–15 min including one wrong
attempt. **The trap caught me, and then released me — which I think is exactly right.**

### Reading the tag (easy, ~1 min)

The shop tag: hands permanently fixed, minute hand on IV, hour hand a third of the way past
VII. **7:20.** The redundancy is well built — the hour hand's fractional position
independently confirms the minute hand (a third of an hour = 20 min), so a player who is
shaky on "minute hand on IV means 20" gets a second, geometric route to the same number.
The door pictogram beneath supplies the semantics without a word: *the door opens at this
time.* Combined with a hand-setting crank on a dead dial three feet away, the intent is
unmistakable. No friction here at all.

### The mirror decision (the actual beat, ~6–12 min)

Here is my genuine first-contact reasoning, including the wrong turn:

1. *"I'm behind the dial. Everything is mirrored. So I can't just set it to 7:20 — I have to
   invert it. Mirror about the 12–6 axis maps T to 12:00 − T. 7:20 inverts to 4:40. Set it
   so it reads 4:40 from back here and it'll read 7:20 from the town."*
2. Set 4:40 (as I perceived the positions). Everything else done — oiled, wound, pendulum
   swinging. **Nothing happens.**
3. *"...wait."* Look at the numerals again. They are **mirror-written — each glyph crisply
   reversed.** That means I am looking at the *front face's own numerals through the glass*.
   The numerals are mirrored **along with everything else**. So the reversed "VII" glyph is
   sitting at the position that reads VII **from the front**. If I point the hour hand at the
   backwards VII and the minute hand at the backwards IV, the front reads 7:20 by
   construction. **The mirror is self-cancelling if I trust the numerals instead of the
   geometry.**
4. Set the hands to the reversed VII (a third past) and reversed IV. Strike fires.

**So the trap catches the player who reasons *about* the mirror rather than *reading* it.**
I over-corrected: I applied a mirror transform to a scene that had already applied it for me,
and double-inversion put me exactly one wrong answer away. That is a genuinely good trap —
it punishes cleverness-without-looking, and the reversed glyphs are a fair, always-visible
tell that the naive reading is the correct one. I would call it **fair, and the best-designed
red herring in the level**.

### What keeps it from being unfair

Three things, and all three are load-bearing:

- **The candidate set is exactly two.** 7:20 or 4:40. There is no third guess.
- **The crank always turns**, there are no timers, nothing re-locks, and hands hold position.
  Retry cost is ~20 seconds.
- **The other three endgame conditions each have their own local success feedback** — the
  drum's squeal stops when oiled, the drum turns when wound, the pendulum visibly takes up
  its swing. So when nothing happens, the player can be confident the *time* is the variable,
  because it is the only condition they cannot independently confirm.

That third point is subtle and I want to flag it as a design strength rather than an
accident: a four-condition convergence with a single terminal success event is normally
opaque, and this one is legible **only** because three of the four conditions self-report.
If any of those local confirmations is missing or weak in the build, this beat's difficulty
jumps sharply — the player would have four unknowns instead of one.

### Minor note

The minute hand clicks in five-minute steps, and both 20 and 40 are multiples of 5, so the
step granularity does not disambiguate. That is a missed free hint, not a flaw.

---

## 6. Deep beat 5 — The tin mouse and the cat

**Verdict: SOLVABLE-WITH-FRICTION.** Difficulty 4.0. Est. 3–9 min. **The rendering fix works;
the residual friction is verb-shaped, not comprehension-shaped.**

Motivation is established in the first two minutes of the game: "something flat is visibly
tucked beneath the cushion" is a promise the player carries the whole of Zone 1 and Zone 2.
By the time the parts-cabinet drawer yields a tin wind-up mouse, the association *cat chases
mouse* fires instantly — this is one of the most universal object pairings in the medium and
it needs no help.

**The friction is entirely in the verb.** My first instinct was to **offer** the mouse to the
cat — item-onto-hotspot, the verb the game has trained me on everywhere else. That gets the
identical slow blink and resettle that *every* offered item gets, and the mouse comes back
unused. In a game with no text, an identical failure response is indistinguishable from
"wrong item," and I briefly crossed the mouse off.

What saved it, and I think saved it reliably, is that **the mouse's own affordance is
demonstrated in Zone 2, where it is useless**: wound and set on the floor it skitters in a
circle, winds down, and returns. That teaches "this is a place-in-room object, not a
give-to-character object" in a low-stakes context where nothing depends on it. Carrying that
verb to the cat is then a short step. The stated fix that **placement works from both views**
also matters more than it sounds — the cat is in the stair-door/dormer view, and a placement
that only registered from one camera would have re-created the "wrong item" ambiguity at
exactly the wrong moment.

Recovery took me ~3 minutes. Worst case for a player who does not connect the Zone 2
demonstration: ~9 minutes, bounded by the fact that the mouse is the only unused item and the
cushion is the only unsolved obvious thing. Not guide-mandatory.

The cat's post-move behaviour (naps by the stair door instead, same responses) is a nice
touch, and the payoff at the strike — it stands and stretches — is the kind of wordless
acknowledgement this game should be made of.

---

## 7. Probe answers: P13 and P14

### P13 — the tally readout with a non-integer pair

**(a) Does the count come out the same every cycle?** I must be honest about the limit of a
document-based pass: **I cannot verify D13 from `blind-layout.md`.** What the layout
*specifies* is deterministic — the readout "clears the moment any gear is mounted or taken
off either post, and starts again from nothing on the next crank," and a leftover part-turn
is shown as "a single half-height stroke." Read literally, that describes a per-cycle
normalized display: 16+40 gives 6 full + 1 half **every cycle**, 40+64 gives 26 full + 1 half
every cycle, with no drift. A physically-simulated readout would instead oscillate (6, 7, 7,
6, 7...) because a 6.667:1 ratio does not repartition on cycle boundaries. **The spec is the
right spec. Whether the build honours it is a QA measurement on the actual build, and I flag
it as untested rather than passed.** If it oscillates, it becomes a defect immediately — see
(c).

**(b) What did the half-height stroke read as?** **A partial turn.** Unambiguously, and on
first sight. Three things make it read that way: it is geometrically clean rather than
smudged or broken, so it does not look like a rendering artifact; it appears in a fixed
position (end of the accrued block) rather than at random; and the **target block above the
baseline contains only full strokes**, so the player has a same-medium, same-frame reference
for what a "complete" stroke looks like. It reads as *the tally notation extended one step*,
which is the correct read.

**(c) Wrong pair, or broken game?** **Wrong pair.** The half-stroke is actually a stronger
signal than a plain miscount: a wrong-but-integer pair says "not 24," but the half-stroke
says *"this pair doesn't even divide evenly"* — a qualitatively different and more
informative kind of no. I estimate the "broken" misread at roughly **15%**, concentrated
entirely in players who never registered the target block above the baseline and therefore
have no reference for a full stroke. **Conditional on (a) holding.** If the count *does* jump
between cycles, the half-stroke's diagnostic value inverts and it becomes the single most
bug-looking element in the level, because non-repeating output in a game with no timers and
no randomness contradicts everything else the room has taught.

**(d) Does the mural repeating identically change the reading?** **Yes, decisively, and in the
right direction.** The mural is the loudest thing on the wall and it is a genuine attention
magnet — a sun on a slotted track and a watchman holding a bell both look like they *ought*
to be readable state ("get the sun to noon," "count the bell strikes"). I did spend a cycle
or two watching the figures instead of the chalk. What resolves it is that **the mural runs
the same animation every cycle regardless of gearing** and the clack is "the same clack every
time," while **the chalk is the only thing on the wall that changes with my input**. Two
cycles establish that, and after that the eye goes to the cheek automatically. The identical
repetition is doing real work: it is what demotes the mural from candidate-signal to
confirmed-decoration, and it is what promotes the chalk from decoration to instrument. Cost:
about 2 minutes of misdirected attention, which I would call good pacing rather than waste —
it makes the moment you *find* the readout feel earned.

**One caution:** the chalk is on the frame's timber cheek beside the fold-out crank, i.e. in
the same close-up region as the thing the player is actively operating. That co-location is
what makes the readout hard to miss and it should be protected — if the crank interaction
ever moves to a camera that excludes the cheek, this beat loses its safety net and reverts to
guide-mandatory.

### P14 — chalk elements with no colour vision

**(a) Two separate blocks, or one long block of 24+N?** **Two, unmistakably, and never
confused.** Three independent separators, any one of which would suffice:
*(i) a chalked baseline physically drawn between them; (ii) above/below spatial relation, not
left/right — vertical stacking with a rule between is the universal "these are different
quantities" convention; (iii) temporal — the target block is present before the player ever
touches the crank, with visibly empty cheek beneath it, so the player watches the second
block come into existence in a space they already know was blank.* I never once read them as
a running total.

**(b) Distinguishable without colour, and without one looking fresher?** **Yes.** Every
discrimination in the readout is **positional or formal**, none is chromatic:
- target vs. live → above vs. below the baseline
- crank-end quantity vs. cam-end quantity → opposite ends of the frame, separated by its full
  length
- groups of five → the diagonal strike-through across four uprights (form)
- complete turn vs. part turn → full height vs. half height (form)

No element depends on hue, saturation, freshness, or brightness *difference between two
chalk marks*. **Fully safe for total absence of colour vision**, and safe for monochrome
display. Same holds for every other symbolic pair in the level: ⌂ vs ⚙ is form; the ★ linking
the master clock to the Big Ben plate is form; the four landmark silhouettes are outline
shapes; the +IV / ★ / +IX / −V stamps are glyphs. **I found no colour-only discrimination
anywhere in Level 2.**

**(c) Did anything glow, flash or change colour at 24?** **No.** The layout states it
explicitly ("Nothing about it ever glows, flashes or changes colour"), and success arrived
via the latch/clack and the panel opening. That is the correct behaviour for a near-wordless
room and it preserved the moment — a highlight would have converted my deduction into the
game's announcement. **Pass.**

**(d) Readable against the timber in the wide view, not just close-up?** **As specified,
yes** — the layout guarantees "Readable in the room view and in the close-up," and critically
that "the finished block stays drawn and readable at a glance after the crank stops," which
is what lets the player compare the two blocks at leisure instead of counting under time
pressure. **But this is the one P14 item I cannot actually verify from a text document**, and
it is a **luminance-contrast** question rather than a colour question: white chalk on golden
afternoon-lit timber is a light-on-light pairing, and at wide-view scale the discriminations
that matter (a *diagonal* strike-through; a *half*-height stroke) are fine-grained form
judgements. Recommend an explicit contrast check on the rendered plate at wide-view
resolution, in the level's actual golden-hour lighting, including a greyscale pass. If the
half-stroke is not resolvable in the wide view, P13(b) degrades from "partial turn" to
"smudge" and the readout loses its best feature.

### Probes P1–P11 (from §9, answered from the blind pass)

- **P1 (drive path):** Passed cleanly, ~30 s, no hesitation. Gaps read as gaps. See §2 step 1.
- **P2 (target proportion without returning to z1):** **Yes.** The frame crib alone suffices;
  I did not need the slate to state 24:1. ~2 min to full confidence.
- **P3 (24 and 1 from the slate alone):** *"24 turns of the crank per 1 turn of the output
  wheel, and then the door opens."* **I never read the total as 25.** The lone stroke is on a
  different circle in the schematic and at the opposite end of the physical frame; the
  separation is doing its job. The "four groups of five plus four singles" grouping made the
  24 countable at a glance rather than requiring a tally.
- **P4 (does a wrong pair tell direction without telling the answer?):** **Yes.** The readout
  is monotonic in gear size, so two trials establish which way to move, and it never names a
  target. Best-in-level feedback design.
- **P5 (time and route):** ~14 min isolated reasoning; hybrid algebra-first with the readout
  as confirmation. See §2.
- **P6 (self-solving?):** No, but near the line. Full argument in §2.
- **P7 (time to the correct board):** **Under 60 s, zero random clicking.** Target met.
- **P8 (why that board, in my words):** *"It had a house mark, and the house mark matched the
  house watch I put on the house ring."* **No reference to the bearing. C2 carries the beat;
  C1 is opt-in and I did not opt in.** This is the root cause of the P12 stall.
- **P9 (uniformity before watch A):** **Pass** — boards look uniform, nothing hints at the
  cache.
- **P10 (diegetic?):** ~8/10 diegetic. Brief "the game drew that" flicker at the moment of
  appearance; absorbed by the clockmaker's established chalk habit. See §3.
- **P11 (ring-hand annotations, four rects):** Close-ups — hand noticed reliably at both
  rings; the pivot-at-hub presentation reads as a mechanism, not a scratch. **Wide views —
  this is the weak rect**: a single small hand lying on a carved beam ring (z1) or a brick
  ring (z2) at room scale is easy to miss, and at the dormer I had no *reason* to look for it
  because the chalk mark had already answered my question. **Did I read it as a direction?
  At z1, no — never. At z2, only after ~10 min of failing to find a mark.** Wide and close-up
  never appeared to disagree at either ring (the layout guarantees present-in-both or
  absent-from-both, and nothing in my pass contradicted it). **The four-rect fix is
  structurally sound; the problem is not that the hand is invisible, it is that at z1 the
  player is never given a reason to interrogate it.**

---

## 8. Red herrings — fair vs. unfair

| Herring | Cost | Call |
|---|---|---|
| **Sealed display case of spare clock hands** (screwed, painted over) + four handless wall clocks + a screwdriver in inventory | **6–12 min** | **Fair-but-tricky, and the single largest time sink in the level.** The setup is almost cruel — four clocks *missing hands*, a case *full of hands*, and the exact tool. I tried the screwdriver on it three times across two visits. What makes it fair is that the "no" is visible and physical rather than arbitrary: **painted-over screws cannot be turned**, and that is legible in close-up. It is also thematically perfect for a dead workshop. **Keep it, but it is at the ceiling of acceptable cost** — this is where a player's goodwill gets spent. |
| **Wheel barometer** (sun/cloud/rain pictograms, accepts no input) | 1–3 min | **Fair.** Explicitly inert, and its pictogram vocabulary never recurs anywhere else in the level, so it de-escalates quickly. Pure atmosphere. |
| **Tray VI tile** below the door dial (liftable, not carryable) | 1–2 min | **Fair and well-judged.** There is already a VI seated at 6 and no empty socket it fits, so it self-resolves in about one attempt. It teaches the seat/reject mechanic safely before the real tiles matter. |
| **Loose clock parts on the workbench** (none takeable) | <1 min | **Fair.** Establishes "not everything is an item" in the first 30 seconds, which pays off all game. |
| **The mural's sun-on-a-track and bell-watchman** | ~2 min | **Fair, and productive.** Draws the eye, then proves inert by identical repetition, which is precisely what redirects attention to the chalk. See P13(d). |
| **The mirror inversion at the great dial** | 5–10 min + one retry | **Fair, and the best herring in the level.** Punishes reasoning-without-looking; the reversed glyphs are an always-visible tell. See §5. |
| **The absent mark at the chimney** | **8–15 min** | **Not a herring — an unintended one.** This is the only element that misled me *without meaning to*, and the only one where my dominant hypothesis sent me to the wrong zone. See §4. |

Nothing in the level destroys items, locks the player out, punishes wrong attempts, or
re-locks. That consistency is a large part of why the friction stays tolerable — I was always
willing to try one more thing.

---

## 9. Pacing

**Act 1 — Zone 1 (0–20 min). Slightly front-loaded, otherwise good.**
Pleasant scavenging: four numeral tiles across four hotspots in three views (stove hob, coat
pocket, straw crate, windowsill) gives the player early, frequent, low-stakes wins and
teaches the search grammar. The ⌂ cache resolves fast and yields a **bronze 64-tooth gear
whose purpose is completely opaque** — an excellent long-fuse item that pays off 40 minutes
later. The cushion establishes a standing goal. The master clock's 6:00 and its ★ get banked
without comment.

*The one risk here is a clue pile-up at minute two:* **the slate is the most
information-dense object in the game and it arrives before the player has any context for
it.** I studied it for ~4 minutes, extracted "some kind of gear diagram, 24 of something, a
door," and shelved it. A player could easily conclude it is atmospheric and never return.
**This is mitigated well** by the frame cheek repeating the same 24-and-1 in the same
recognizable hand — the crib does not just restate the target, it *re-summons the slate*.
That is a better fix than it may have looked on paper, and it is worth protecting.

**Act 2 — Zone 2 (20–50 min). The longest stretch, the highest highs, and the only real
dead zone.**
Four of the level's nine beats live here plus most of the backtracking (Z2→Z1→Z2 twice). Each
trip has a clear objective, so the fetching does not feel aimless. Flow is strong from the
mouse through the cushion watch. **Then it stops dead at the chimney**, and per §4 there is
essentially nothing else open — the gear wall is rust-locked, Zone 3 does not exist, the
clock row has no context. **This is the level's only genuine dead zone and it is 8–15
minutes long.** Everything after it is excellent: oil → crank → the tally readout → the
bronze wheel snapping into place is the best sustained run in the level.

**Act 3 — Zones 3 and 4 (50–75 min). Clean, fast, well-shaped.**
The hatch combination is a satisfying pure-logic beat with no hunting — all inputs are
already in the player's head, and the **reordered headers** (wall row reads Burj / Big Ben /
Fuji / Liberty; hatch headers read Big Ben / Burj / Liberty / Fuji) add a fair attentiveness
tax rather than a knowledge tax. Worth noting explicitly: **this beat needs no real-world
knowledge at all** — the offsets are printed, and the landmarks can be matched
silhouette-to-silhouette without naming them. Only the ★ link to the master clock is
required, and that is a symbol match. Very fair. The 6+9=15→III wraparound is the only pinch
and the I–XII wheels force the resolution.

The strongroom is a two-minute room that hands over two payoffs (key + tag) and a lovely
quiet beat (the second cushion and empty saucer). Then the dial, the assembly, the strike,
the rods articulating along their whole run, the bar lifting, and the cat standing up.
**Good ending.**

**Curve shape — one structural note.** The peak is in the middle, not at the end: Zone 1 sits
at 2.0–3.5, Zone 2 spikes to 6.5–7.5, Zones 3–4 settle at 5.0–6.5. The gear wall (7.0) is
harder than the capstone (6.5), so the level's climax is not its hardest moment. **This is
fine** — the finale's job is convergence and payoff, and the four-condition assembly with the
mirror twist delivers that emotionally even at a lower difficulty. But if anything gets
tuned upward later, the dial is the place with headroom, not the gear wall.

---

## 10. Time estimate

| Segment | Est. |
|---|---|
| Zone 1 search + door dial | 6–10 min |
| Slate study (no payoff yet; revisited later) | 3–5 min (+2–3) |
| ⌂ ring + floorboard cache | 4–8 min |
| Mouse acquisition + cat | 3–9 min |
| **⚙ ring + chimney brick** | **10–20 min** |
| Oil the frame | 1–2 min |
| Gear wall solve | 12–25 min |
| Clock row → hatch combination | 6–12 min |
| Strongroom | 2 min |
| Tag → mirrored dial time (incl. one wrong attempt) | 8–15 min |
| Oil drum, wind, pendulum, strike, exit | 5–8 min |
| Herring tax + wandering | 8–15 min |
| **Total** | **70–95 min (median ~80)** |

Add 15 min if the chimney's mark-absence hypothesis sticks hard; subtract 15 if the player
reads the ring bearing at the dormer unprompted.

---

## 11. Verdict and recommendation

### READY-WITH-TWEAKS

**Overall difficulty: 6.0** (range 5.8–6.2). The provisional 6.0 is confirmed from the
player's side, and the intended curve does land experientially, not just on paper.

**No beat is guide-mandatory.** Every one of the four beats that previously required the
walkthrough now has a blind path:

- **Gear wall — fixed, and fixed well.** The stamped pinions make the slate legible as a
  blueprint; the frame crib puts the target at the point of use; the live tally gives
  monotonic, non-answer-revealing feedback; and the rack's deliberate hole between 20 and 27
  turns "I can't find it" into a positive proof that a gear is missing. Route A and Route B
  both work independently. This went from the level's failure to the level's best beat.
- **Tin mouse — fixed.** Clear feedback plus both-view placement removes the ambiguity; the
  residual offer-verb friction is bounded by the Zone 2 demonstration.
- **Mirrored dial — works.** Proper hub-anchored sprites make the hand positions readable,
  the two-candidate space plus free retries plus three self-reporting sibling conditions
  keep the trap fair. It caught me and released me in about 10 minutes.
- **Floorboard cache — fixed, at a cost.** Sub-60-second solve, but the fix consumed the
  reasoning that the chimney needs.

**The one tweak I would gate on** is the chimney/dormer asymmetry (§4). Not because the
chimney is unsolvable — it is not, and the IX bearing is beautifully clean once you look at
it — but because of three compounding factors: the absence reads as *"not available yet"*
rather than as *"read the hand"*; the dormer no longer teaches bearing-reading, so the
"teach-then-test" escalation has no teach step; and the stall sits on a **sole-thread
chokepoint** with the oil can behind it, which simultaneously blocks the gear wall *and* its
tally-readout safety net. The Designer owns the remedy; from the player's chair, what is
missing is simply *some* reason to look at the hand at the dormer, or *some* in-scene reason
the brick could not have been chalked.

**Two build-side checks I could not run from a document, flagged for QA rather than design:**
1. **P13(a) — cycle-to-cycle stability of the tally count on a non-integer pair** (mount
   16+40, crank three cycles untouched; the count must be identical each cycle). The spec is
   correct; the build is unverified. An oscillation here inverts the half-stroke from the
   readout's best feature to its most bug-looking one.
2. **P14(d) — wide-view luminance contrast of white chalk on golden-lit timber**, including
   a greyscale pass, specifically checking that the *diagonal* strike-through and the
   *half-height* stroke are resolvable at room-view scale.
3. *(Minor, §2)* Whether the gear wall accepts **both** post orderings of 36/64, since the
   ratio is commutative. Rejecting a mathematically correct arrangement would be the one
   genuinely unfair moment in an otherwise very fair beat.

**Colour-blind check: clean pass.** No colour-only discrimination exists anywhere in Level 2;
every symbolic distinction is positional or formal. Nothing glows, flashes, or changes hue,
including at the moment of success.

*End of report. Owner: Blind Playtester. Next: Producer → Designer (P12 friction) and
QA (P13a / P14d build checks).*
