# Feedback Backlog

_Maintained by the Feedback Intake Agent. Logged as reported during real-world
TestFlight testing. Items are logged verbatim as they arrive (Phase 1) and left
untouched — no classification, routing, or action — until the user explicitly
triggers processing (Phase 2)._

## Round 1 — PROCESSED 2026-07-07 (pending user checkpoint review before execution)

Full classification/routing table is in this section. Individual item entries below are
kept verbatim as logged (Phase 1); this table is the Phase 2 output.

**User resolutions (2026-07-07):**
- Cluster CONFIRM-1 (generic interaction sound): MERGE CONFIRMED — and user broadened the
  scope: fix the generic "psh" across ALL interaction points game-wide, not just the
  three reported triggers.
- Cluster CONFIRM-2 (ash-pile/gold-ring) ROOT CAUSE IDENTIFIED from user's account: the
  poker requirement WAS enforced (poker was in inventory) — the defect is the
  interaction MODEL: merely having the item in inventory (or dragging it) auto-applies
  it to the hotspot with no explicit selection step, so the sift fired without the user
  understanding why, and the ring's grant had no legible feedback (F-007's "animation"
  confusion). User direction: neutralxe-style explicit interaction — the player must
  deliberately choose which inventory item to use on a target; no passive auto-apply.
  (Drag-removal question posed to user; see design decisions.)
  Reclassified: NOT a puzzle-logic bug — interaction-model defect, Developer-scoped.
- Inventory bar hidden in close-ups: CONFIRMED SYSTEMIC by user — happens in every
  close-up (ash, potions, cabinet, cage, ...). Inventory must be reachable throughout.
- F-016 CONFIRMED as wanted feature: tapping an inventory item should also allow
  enlarging it to identify it (currently tap only selects).
- F-018 RESOLVED as duplicate: it is the astrolabe base drawer under the window; opened
  on p03 solve with contents auto-granted (impl. judgment call 14), so the "empty drawer,
  nothing to pick up" is the same auto-grant-confusion root as F-023. Merged into F-023.
- F-003: informs F-001/F-002 + the interaction-model change above (neutralxe baseline).
- F-012: user REJECTS the multiple-solve-paths defense — "remove multiple solving paths
  i don't like it." NOTE: this contradicts core operating principle #4 in CLAUDE.md
  (multiple valid solve paths / requirement-based state). Producer flagged the design
  distinction (clue-gating vs. full linearization) back to the user before routing;
  routing to Theme & Puzzle Designer + Validator + Blind Playtester re-check once scoped.
  This is a DESIGN change, not a bug fix.

**Design decisions (user, 2026-07-07 — CHECKPOINT 1 PASSED, round routed for execution):**
- F-012 scope = **CLUE-GATING**: a puzzle won't accept its solution until its clues have
  been viewed in-game. Parallel branches stay. (Amends CLAUDE.md principle #4's
  order-freedom at the puzzle-input level only; requirement-based state model unchanged.)
  - Implemented as puzzle-graph **rev 1.3** (Designer), **VALIDATED PASS** (Validator,
    difficulty holds 6.0, no soft-locks). Gates: p01 (rune marks + grimoire page A),
    p02 (triptych), p03 (Orion window), p04 (slot/page-B), p14 (recipe, resolve-only);
    all physical-act puzzles (p05–p13, p15–p17) ungated. Clue-viewed flags persist in
    save (D7).
  - **p01 page-A ruling (user, 2026-07-07): REQUIRED — decision is FINAL, do not revert.**
    Both Designer and Validator advised demoting page A to *optional* (a rune-mark
    glyph-matcher can solve p01 without it, so requiring it can knock back an earned
    answer). User was shown that exact tradeoff and chose the strict "must view all
    clues" reading. Keep page A in p01's gate; no config-flag demotion.
- Interaction model = **SELECT-THEN-TAP ONLY**: drag-to-use REMOVED, passive auto-apply
  REMOVED. Player must arm an inventory item, then tap the target.
- Sound: generic "psh" removed EVERYWHERE; per-object sounds or none. Ambience: quieter
  scene overall, F-002 direction (possibly entry-sound-only, neutralxe register).

**Informational — not routed, no bug found (FYI only):**
- F-008 (clock cuckoo "nothing happened"): matches spec exactly (developer_notes D5) —
  the pop is a ONE-SHOT cosmetic flavor beat, intentionally never gates progression.
  Working as designed.
- F-012 (solved rune-door before viewing flowerpot clue): not a bug — the puzzle graph
  allows multiple valid solve paths and never gates clue-viewing before solving; other
  visible clues (clock numeral ring, other rune marks) were enough to infer the answer.

**Classified & routed (see full table below):** 18 items, all severities/routing/
regression-scope proposed. QA has final say on actual regression execution per item.

_Item statuses below updated to reflect Phase 2 classification. `status: routed` items
are queued behind the user's go-ahead on this round (checkpoint 1); `status:
needs-clarification` items are blocked until answered._

**Device/context:** iPad Pro, TestFlight, Level 1 ("The Wizard's Cabin")

### F-001 — status: logged
> there is a brown space empty at the bottom of the scene [on iPad Pro] — scaling may be a bit off
>
> follow-up: "i think the empty brown at the bottom is where the key items are stored,
> hate it" — i.e. the empty brown area is the inventory bar (aged dark-oak strip,
> style-guide §7); user's complaint is about how it looks/reads, not only a scaling gap.

### F-003 — status: logged
> again, use neutralxe as a baseline for how the game should look and feel

### F-004 — status: logged
> i went back to the main menu then started the game again from level one, interestingly,
> the ambiance sound is gone, is it a bug?

### F-005 — status: logged
> i hate the psh sound used when i interact with each object, not just for picking it up
> (actually the sound for adding to inventory is fine), but the very weird sound when i
> zoom into any item.. change it, make the sound relevant to the object rather than a
> standard sound across all, some objects may not need a sound at all

### F-006 — status: logged
> after picking up the long stick next to the fireplace [poker] and adding it to
> inventory, clicking the same place when it's empty gives off the same awful sound,
> indicating that something is there when i had already picked it up, i think that's a bug

### F-007 — status: logged
> i zoomed into the fireplace, found a ring, and tried to pick it up but it stayed there,
> but when i zoomed out, i noticed that it's in my inventory, so i zoomed in again and
> noticed it's gone, so the animation is wrong there as it should have disappeared
> immediately as i picked it up [gold ring, p05-ash-sift]

### F-008 — status: logged
> i zoomed in on the clock, turned the handle a few times and the bird popped, but
> nothing happened, not sure if something else supposed to happen, will see
> (context: user separately confirmed spotting the I/II rune marks as clues — no
> complaint there, noted for context only, not logged as its own item)

### F-009 — status: logged
> also removed the rug and saw the puzzle under it, hate the sound again
> (rug-move / trapdoor-reveal interaction sound — same "psh"-type complaint as F-005,
> flagging possible duplicate for Phase 2, not merging now)

### F-010 — status: logged
> moved right, i see the door with the thorns, clicking on it zooms into a thorny door
> but looks different from the big one? the positioning of the skull head is different
> when zoomed in/out
>
> clarification: "it's the bird skull with the thorns on the door is what i mean" — i.e.
> a bird-skull motif worked into the thorn-vine door ornamentation; its position shifts
> between the wide v-entry view and the door close-up (continuity/consistency issue
> between base plate and close-up plate).

### F-002 — status: logged
> the ambiance rain sound is a bit too loud/noisy, either tone it down or change it to be
> "quieter", not just turning the volume down, but having a more quiet scene, even if you
> have to remove it all together to be more like neutralxe, maybe just an entry sound at
> the start of the level

### F-011 — status: logged
> i see the caged bird, zooming in shows me the bird with his back, is this normal?

### F-012 — status: logged
> turned right, i see the [triptych] and zoomed into the photos on the wall with crows
> and different moon phases. i also flipped through the book [grimoire]. i was able to
> open the door/cabinet on the right with the arrow I II III IIII puzzle [p01-rune-door]
> before zooming in on the dead plant that has a piece of the puzzle that i need, so that
> shouldn't happen...
> (context: dead flowerpot carries the EARTH rune + numeral III clue for p01; user solved
> p01 without having viewed that clue close-up yet — flag for Phase 2, may be a
> discoverability/sequencing concern rather than a hard bug, since the graph allows
> multiple valid solve paths and doesn't gate clue-viewing before solving)

### F-013 — status: logged
> went into the next door, i see the pot, and the stir options, i tried but didn't know
> what's going on, pressed pump bellows and noticed when zooming out that the pot lifted
> a bit, not sure if that's supposed to happen, let's see
> (context: z2 v-bench cauldron/flame-stage/bellows puzzle p14-brew; two threads here —
> (a) unclear brew-interaction affordance/feedback, (b) possible visual state glitch
> where the cauldron appears to shift position between the close-up and wide view after
> pumping the bellows. hedged by user, "let's see" — not a firm complaint yet.)

### F-014 — status: logged
> the table next to the pot, so i can zoom in on the white/marble bowl thing [mortar &
> pestle], but i can also hear the annoying sound pressing on the left side of the table,
> where the drums or utensils are? not sure what those are to be honest.. the sound
> indicates, i assume, that something is there to see, but i didn't see anything
> (context: likely the hanging dried herbs in z2 v-bench, spec'd as ambient/non-
> interactive scenery ("framed as scenery, never lit as a hotspot") — if it's playing an
> interaction sound with no resulting close-up/action, that may be a stray hotspot bug;
> ties into the same generic-interaction-sound complaint as F-005/F-009)

### F-015 — status: logged
> moved right, i see the cabinet with the crescent and sun, zoomed in, didn't notice
> anything valuable, i guess something goes there? i zoomed in on the potion shelft, i see
> eyes, snowflake, plant, snake and maybe wind/merimade potion? not sure what that is but
> i guess it's a clue
> (context: z2 v-cabinet sun/moon slot puzzle p04-cabinet-sun-moon (empty until ring+coin
> placed — user's "didn't notice anything valuable" may just mean pre-solve state, not a
> bug) + potion-shelf red herring rh-potion-shelf, which the graph specs as labeled
> sleep/frost/growth pictograms — user's read (eyes/snowflake/plant/snake/mermaid?)
> doesn't clearly match that list; flag for Phase 2, may just be ambiguous pictogram
> art or a user-perception note, not necessarily a defect)

### F-016 — status: logged
> i used the astrolobe and clicked the orion's belt shaped dots, opened desk, i got two
> key items [p03-astrolabe-orion yields itm-silver-coin + itm-crank], but i noticed i
> can't enlarge key items as clicking them only selects them
> (context: no inventory-item inspect/zoom available, or not discoverable — possible UX
> gap; implementation notes mention long-press-to-inspect was added for at least the
> rusted key, unclear if it's universal)

### F-017 — status: logged
> is that a swiss knife i picked up?
> (context: item-identity/art-clarity question — likely itm-crank "winch crank handle,"
> user isn't sure what the icon depicts)

### F-018 — status: logged
> the drawer under the window also opened but i can't seem to pick anything up
> (context: unclear if this is the SAME astrolabe base drawer already described above, or
> a different drawer — flag for Phase 2 clarification; if a distinct drawer with an item
> that can't be picked up, that's a possible bug)

### F-019 — status: logged
> hate the pshh annoying sound used when selecting key items from inventory too
> (context: another instance of the generic interaction-sound complaint — ties to F-005,
> this time specifically on inventory-item selection rather than pickup/zoom)

### F-020 — status: logged
> went right, i'm back to the main room, not sure what to do next, i feel i need to solve
> the floor puzzle... i went through the walkthrough and figured need to use the iron
> poker on the ash pile, thing is, i select the poker, then i click on the ash pile, but
> the zoomed in pic of the ash pile removes my access to the inventory. i tried dragging
> it but same issue
> (context: p05-ash-sift — inventory bar appears inaccessible while in the ash-pile
> close-up view, blocking the poker-on-hotspot interaction via both tap-select and drag;
> user could not complete this puzzle step through the UI as a result — likely bug,
> high severity if inventory access is broadly blocked in close-up views)

### F-021 — status: logged
> the [walkthrough] said i'm supposed to get the ring now, but i got it from the start
> without having to interact or do anything, i feel that's an issue with the story
> sequence.. puzzles should unlock as i progress
> (context: gold ring (p05-ash-sift, solution_fixed "poker + ash") — user reports already
> having the ring without performing the poker interaction; ties to F-007 (ring pickup
> animation report), possibly the SAME underlying issue — ring may be obtainable/visible
> without the poker+ash requirement being enforced. Flag for Phase 2: possible
> puzzle-logic/requirement-gating bug, not just a visual animation glitch as F-007
> first suggested.)

### F-022 — status: logged
> as the guide said, i dragged the gold ring and the silver ring into the slots, i don't
> like how they fit, as they seem a bit off instead of really fitting in
> (context: p04-cabinet-sun-moon — itm-gold-ring into sun slot, itm-silver-coin ["silver
> ring" as reported] into moon slot; functionally worked, this is a visual-fit/polish
> complaint about the seated placement art/positioning)

---

### F-023 — status: logged
> i opened the locked cabinet, immediately two items went into my inventory, shouldn't i
> pick them up instead of them directly going in?
> (context: p04-cabinet-sun-moon yields itm-file + itm-phial automatically on solve —
> user expected a manual pickup step instead of auto-grant; interaction-pattern/feature
> consistency question, not necessarily a bug — flag for Phase 2, may tie to F-018's
> similar "opened but couldn't pick anything up" confusion, i.e. inconsistent pickup
> patterns across puzzles)

### F-024 — status: logged
> going left and right flips me between scenes instead of perspectives within that
> specific room. like i am in the hidden cellar, and going left takes me out of the room
> into the potion workshop. ideally it should show me different walls of the cellar. the
> same with the other rooms
> (context: navigation architecture — chevron left/right appears to traverse ZONES
> (z1-cabin / z2-workshop / z3-cellar / z4-alcove) rather than cycling VIEWS within a
> zone (z1 has 3 views: v-hearth/v-study/v-entry; z2 has 2: v-bench/v-cabinet). NOTE:
> per puzzle-graph.json z3-cellar and z4-alcove are each spec'd with only ONE view
> (v-cellar, v-alcove — z3 "single wide view" per style-guide 5.6), so "different walls
> of the cellar" may not be an available design target there regardless; the z1/z2
> multi-view zones are where this most clearly applies. Flag for Phase 2 — sounds like a
> significant navigation-model bug/mismatch vs. the intended view-cycling UX.)

### F-025 — status: logged
> i used the key from above the moonflower to open the cage, the bird flew leaving me a
> feather, but it was difficult to see the arrow taking me back to the main scene, i
> thought it was bugged, maybe u need to reconsider the arrows to be more visible, even
> if they stand out a bit
> (context: p11-cage-unlock worked correctly (key from z4 statue, feather granted). Issue
> is the close-up "back/down-chevron" exit affordance being hard to spot (style-guide
> spec: thin bone-white chevrons at 40% idle opacity) — visibility/discoverability
> complaint, distinct from F-024's zone-vs-view navigation-model issue but related
> (both are chevron/navigation UX))

---

## Round 1 — Routed Changelist (prioritized; pending user go-ahead — CHECKPOINT 1)

| # | Items | Class | Sev | Routing | Regression scope (proposed; QA has final say) |
|---|---|---|---|---|---|
| 1 | Cluster CONFIRM-2: F-007+F-020+F-021 | bug (pending root-cause) | **critical** (candidate) | Puzzle Logic Validator + Developer | **Full** — critical-path item, core inventory/close-up interaction |
| 2 | F-024 | bug | **major** | Developer | **Full** — core navigation system, every zone/view |
| 3 | F-004 | bug | major | Developer | **Full** — save/resume + audio-manager lifecycle |
| 4 | F-001 (scaling half) | bug (needs device-config check) | major | Developer | Full if systemic inventory-bar layout defect; else targeted |
| 5 | F-011 | bug (needs verify) | major | Developer + QA verify | Targeted — crow default-pose vs. refusal-pose trigger only |
| 6 | F-010 | bug | minor | Art Director / Asset Generation | Targeted — v-entry door plates only |
| _AF-1 ruling (Producer, 2026-07-07):_ close-up `cu-door-lock` is CANONICAL (it matches the graph's single "crow's-beak rune basin" element). Bring the wide `v-entry` base + all vine-state variants into line: unify the stray crow-head + round bowl into ONE crow's-beak rune basin over the bolt, matching the close-up. Spec-determined, not a free composition choice — no user input needed. EXECUTION QUEUED after the Developer batch lands (avoids concurrent asset-manifest.json writes while the Developer is running). AF-2/3/4 already done ($0.17). ||||
| 7 | F-006 | bug | minor | Developer | Targeted — poker/hearth hotspot only |
| 8 | F-014 | bug | minor | Developer | Targeted — herbs hotspot only |
| 9 | Cluster CONFIRM-1: F-005+F-009+F-019 | polish | — | Developer (SFX sourcing, own scope per agent def) | Targeted — audio trigger points only, no state impact |
| 10 | F-001 (look half) + F-002 + F-003 | polish (creative-direction) | — | Developer (audio: own scope) / Art Director (inventory-bar visual direction) | Targeted |
| 11 | F-016 | feature (system) | — | Developer | Moderate — inventory system + drag/select interplay |
| 12 | F-017 | polish (art clarity) | — | Art Director / Asset Generation | Targeted |
| 13 | F-022 | polish | — | Developer (anchor/position) | Targeted |
| 14 | F-023 | polish (UX clarity) | — | Developer | Targeted |
| 15 | F-025 | polish (nav visibility) | — | Developer, **Art Director consult** (changes a Section-7 series-seed convention, not level-local) | Targeted-but-broad — spot-check across all zones since it's a shared chrome element |
| 16 | F-013(a) unclear brew controls | polish | — | Developer | Targeted |
| 17 | F-013(b) cauldron position glitch | bug (hedged, low-confidence) | minor | Developer + QA verify | Targeted |
| 18 | F-015 (pictogram mismatch) | polish (low-priority) | — | Art Director / Asset Generation (visual check only) | Targeted |

**Checkpoint 2 (after fixes land):** user reviews QA's regression results before any
re-release, per standard process — nothing in this round ships without that review.

---

## Round 2 (in progress — logging, not yet processed)

**Device/context:** iPad Pro, TestFlight, **build 2** (Within 1.0 build 6). NOTE: build 3
(art-only rebuild) is concurrently in progress — triage each item at processing into:
(a) covered-by-build-3 art, (b) functional/logic → Developer (persists regardless of art),
(c) art-legibility/composition → steer the live build-3 cascade.

### R2-001 — status: logged
> the clock atop the fireplace is a bit confusing, i click the clock needle, and when it
> reaches 12 a bird pops, not sure what's the purpose of this clue really if it is really
> a clue
> (context: the D5 clock cuckoo — by design a FLAVOR/red-herring beat, NOT a clue; the
> real p01 reference is the numeral ring. Recurrence of round-1 F-008 confusion. This is a
> DESIGN/UX-clarity issue that persists in build 3 (art-only) — the cuckoo reads as "this
> should do something." Candidate fixes: make it read more clearly as inert flavor, or
> reconsider the beat. Functional/design, not art-render.)

### R2-002 — status: logged (POSITIVE, not an issue)
> i like the new add to inventory sound, it's quiet and nice and indicative so that's good
> (confirmation: the round-1 sound overhaul landed well; keep the add-to-inventory sound.)

### R2-003 — status: logged
> i picked up the iron, saw the triangle-up mark atop the fireplace [FIRE rune glyph — the
> new build-3-style glyph reads correctly, good], zoomed onto the ash, and using the iron
> stick unveiled the ring — but immediately upon finding the ring it is added to my
> inventory without me picking it up. Better: unveil the ring, have me click it AGAIN to
> pick it up from the ash pile, and once it's in inventory the ash pile shows empty (I
> cleared it). "think that needs an image generation too"
> (context: p05-ash-sift. TWO-PART: (a) FUNCTIONAL — insert a manual pickup step: poker →
> ring becomes visible in the sifted ash (no auto-grant) → tap ring to collect → ash shows
> ring-taken. Same manual-pickup principle as round-1 F-023/F-018, applied to the ash ring.
> (b) ART — needs a clear "sifted ash with the ring sitting visible/pickable" state and a
> "ring-taken / cleared" state. The graph already defines ash states
> undisturbed/sifted-with-glint/ring-taken + cu-ash-* close-ups; build 3 is regenerating
> these anyway — STEER the live cascade to render the sifted state with the ring clearly
> pickable and a distinct cleared state. So: functional → Developer; art → fold into build 3.)

### R2-004 — status: logged
> is the background noise ocean? doesn't really fit cabin in the woods theme no?
> (context: the z1 ambient loop reads as ocean/waves — wrong for an abandoned-cabin-in-
> the-woods setting. Audio/functional, persists in build 3 (art-only). Superseded in intent
> by R2-005 (user will supply exact music) — but the "ambience must fit the woods/cabin
> theme, not ocean" note stands regardless. → Developer.)

### R2-005 — status: logged ⚠️ PENDING USER INPUT — REMIND BEFORE ENDING FEEDBACK SESSION
> "let me share with you the exact background music that you need to use, remind me before
> we end the feedback session"
> (ACTION FOR PRODUCER: when the user says "that's all / process it", REMIND them to share
> the exact background music file/link before processing. Do NOT close round 2 without this.
> The supplied music replaces the current ocean-like ambience (R2-004). → Developer to
> integrate once provided, honoring the mute-ambiance toggle R2-006 + licensing rules.)

### R2-006 — status: logged
> in the settings menu, add two toggles: one to mute ambiance, one to mute sound effects
> (the interaction sounds)
> (context: FEATURE — split the current single "Sound" master toggle into TWO independent
> toggles: (1) Ambiance/music mute, (2) SFX/interaction-sounds mute. Updates
> `specs/global-ui-style.md` §5.4 (which specs one master Sound toggle) + §8 SF-Symbol set
> (needs a second speaker-state row). Functional → Developer. Persists in build 3.)

### R2-context (non-issues, narration — not routed)
> "sweeped the rug and i see the puzzle, can't do much with it now so that's ok" — working
> as intended (trapdoor moon-dial revealed; not yet solvable). "i see the top arrow mark" —
> confirming a rune glyph reads (AIR/EARTH mark); no complaint.

### R2-007 — status: logged
> i see the three pictures on the wall with the crows [triptych]. i clicked on the picture
> on the RIGHT (with 3 crows), but the game zoomed onto the picture on the LEFT (with 1
> crow) — i think that's a bug
> (context: z1 v-study triptych, the p02 moon-trapdoor clue. Hotspot→close-up MISMAPPING:
> tapping the right painting opens the wrong (left) painting's close-up. A real functional
> bug and puzzle-relevant — could mislead the p02 solve (crow-count → dial index). Likely
> swapped/mis-ordered hotspot rects or close-up routing for the three triptych panels.
> Functional → Developer; persists in build 3 (art-only). Verify all three map correctly.)

### R2-008 — status: logged
> i zoomed onto the book [grimoire]. can we add swipe to flip through pages (in addition
> to the arrows)? also add swipe to switching between scenes/perspectives — keep the arrows
> too
> (context: FEATURE — additive gesture navigation, arrows STAY: (a) horizontal swipe to
> flip grimoire pages in the book close-up; (b) horizontal swipe to cycle views/
> perspectives within a zone (complements the §7-R2 chevrons). NOTE: distinct from the
> removed drag-to-USE-items (round-1 select-then-tap decision) — this is navigation
> swiping, which is fine and additive; don't reintroduce item-drag. Functional → Developer;
> persists in build 3.)

### R2-009 — status: logged
> i think you forgot to remove the pshh sound when swiping between pages — replace it with
> a page-flipping sound fitting the game theme
> (context: the round-1 game-wide generic-"psh" removal (F-005/F-009/F-019) MISSED the
> grimoire page-navigation sound — the psh still plays there. TWO parts: (a) remove the
> generic psh on page-flip; (b) add a themed page-flip/paper SFX. Ties to the new R2-008
> swipe-to-flip. Audio/functional → Developer; persists in build 3. Flag as an incomplete-
> fix carry-over from round 1, and sweep for any OTHER surviving psh instances while at it.)

### R2-context (more narration — not routed)
> "found the arrows puzzle" (p01 rune door) · "found the clue for the feather and recipe"
> (recipe page) · "found the down-arrow deadplant" (EARTH rune = downward triangle on the
> flowerpot — confirms the new build-3 EARTH glyph reads correctly) · "went to the scene on
> the right" — all progress narration, no complaints.

### R2-010 — status: logged (expected: COVERED BY BUILD 3 — but VERIFY at z1 review)
> found the puzzle clue under the window [WATER rune — narration]. graphics bug in the
> door: in the wide scene the thorn-door's bird skull comes out from the side, but clicking
> to zoom in, it looks DIFFERENT. "make sure u confirm the imagery is consistent of how i
> interact with the game"
> (context: this is the round-1 F-010 / AF-1 door continuity bug (wide plate had a skull +
> separate bowl; close-up had a unified crow's-beak basin). Build 3 already fixed the WIDE
> z1-entry base (unified beak-basin). The CLOSE-UP (cu-door-lock etc.) is being regenerated
> NOW in the derived cascade — the per-scene-consistency directive should make it match the
> new wide plate. PRODUCER ACTION: explicitly verify wide↔close-up door consistency when the
> z1 derived batch comes back for review; targeted re-roll if they don't match. So: covered
> by build 3, but do NOT assume — confirm at z1 art review.)

---

_Say "that's all, process it" (or similar) when ready to process this round._
_REMINDER PENDING: R2-005 — get the exact background music from the user before closing._
