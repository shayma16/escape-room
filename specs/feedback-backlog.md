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

### R2-005 — status: RESOLVED (music PROVIDED + staged)
> "let me share with you the exact background music that you need to use"
> ✅ PROVIDED 2026-07-08: user gave `C:\Users\shaim\Downloads\hYkbifnMcwxtLyFKpkVGF_output.wav`
> (RIFF WAVE, 16-bit PCM stereo 48 kHz, 6.29 MB). STAGED into the repo at
> `EscapeRoom/Resources/Audio/music-level1.wav` (committed on branch level1-rebuild-build3).
> → Developer: use THIS as the Level-1 background music, REPLACING the ocean-like ambience
> (R2-004). Integration notes: loop it seamlessly; route it under the "ambiance/music" mute
> toggle (R2-006, separate from SFX); balance volume so it sits under gameplay (the round-1
> "quieter scene" direction R2-002/F-002 still applies — music present but unobtrusive). The
> per-zone amb-z1..z4 loops: Developer decides whether to drop them or keep as subtle texture
> under the music. It's user-supplied — confirm the user has rights to ship it commercially
> before it goes in a public release (record in implementation notes per the licensing rule).

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

### R2-011 — status: logged (POSITIVE, not an issue)
> the caged bird doesn't interact with me, but if i use any key item it turns away — i like
> the idea, it indicates it needs to accept a specific something
> (confirmation: the D3/D4 crow terminal-refusal behavior works and the user LIKES it. Keep
> as-is. Minor watch: user reads it as "needs a specific item" — the design intent is the
> crow gives the feather FREELY once freed, not fed; but the interaction is well-received,
> no change. Narration also: right-nav returns to first scene, triptych clue → p02 solve.)

### R2-012 — status: logged
> on successful opening [of the trapdoor / p02], another psh sound comes up ALONG WITH the
> add-to-inventory sound i liked — is this normal? shouldn't we change that psh sound i hate?
> (context: TWO audio problems on puzzle-solve/trapdoor-open: (a) the hated generic "psh"
> STILL plays here — another surviving instance of the round-1 game-wide-removal that was
> missed (see also R2-009 page-flip). (b) the add-to-INVENTORY sound fires on a trapdoor
> OPEN where nothing is added to inventory — WRONG cue; a solve/zone-unlock/reveal sound
> belongs there, not the pickup sound. Fix: remove psh globally (thorough audit of ALL
> triggers), and map correct distinct cues — pickup≠solve≠unlock. Audio/functional →
> Developer; persists in build 3. Escalates R2-009 into a full sound-trigger audit.)

### R2-013 — status: logged
> the sound indicated i did something right, but zooming out to the original scene doesn't
> show any visual indication — like a slightly opened cellar door / open trapdoor
> (context: after solving p02 (moon dials), the wide z1-hearth view shows NO visual state
> change — the solved/open trapdoor isn't reflected, so the player gets audio success but no
> visual confirmation or wayfinding to the new path. The graph DEFINES this state
> (z1-hearth-trapdoor-open plate + ov-trapdoor-open overlay exist), so the ART is available
> (and being regenerated in build 3) — the defect is the game not APPLYING/rendering the
> open-trapdoor state in the wide view after the solve. Functional (state→visual wiring) →
> Developer; persists in build 3. IMPORTANT UX: state-change visual feedback after a solve
> is load-bearing for wayfinding — Developer should audit that ALL solves show their wide-
> view state change, not just this one, e.g. rune-door opening, cabinet, etc.)

### R2-014 — status: logged
> in the cellar, found the spoon and added it to inventory. but with the drawer opened, the
> place where the spoon was looks blurry and patchy (another bug). zooming in, the spoon is
> STILL there despite being in my inventory. [also narration: sees lever, movable mirror,
> barrel — can't do much yet, going out]
> (context: z3 v-cellar drawer/spoon (itm-spoon pickup). TWO parts: (a) ART — the drawer-
> open region is blurry/patchy in build-2 art (a Flux-plate defect); build 3 regenerates
> this, so COVERED — but verify the new z3 drawer plate is clean at z3 review. (b)
> FUNCTIONAL — the drawer close-up still shows the spoon after it's picked up; the
> "spoon-taken / empty drawer" state isn't applied. SAME systemic bug as R2-003 (ash ring
> persists) and R2-013 (trapdoor open not shown): interactions/pickups don't update the
> visual to their post-state. → Developer, and treat as a SYSTEMIC state-visual-refresh
> audit across all pickups/solves, not a one-off. Persists in build 3.)

### R2-015 — status: logged
> solved the arrow/rune door (p01 — combination works). again i hear the two sounds together
> like the rug puzzle — fix those sounds; the door opening should get a themed "door opening"
> sound. also zooming out doesn't show the door opened or slightly opened — another image
> generation that needs fixing
> (context: p01 rune door. THIRD confirmation of BOTH systemic issues: (a) AUDIO — the psh +
> mismatched add-to-inventory double-sound on solve (see R2-012, R2-009); the rune-door open
> event needs a distinct themed door-opening SFX. (b) STATE-VISUAL — the wide view doesn't
> show the door opened after solve (see R2-013 trapdoor, R2-014 spoon). For the door this may
> also need a NEW "door open / ajar" art state generated in build 3 (verify whether an
> open-rune-door plate exists; if not, ADD it to the z1 cascade). So: Developer (sound map +
> state-visual wiring) + build-3 art (open-door state). Reinforces the two systemic audits.)

### R2-016 — status: logged (art consistency — VERIFY/RESOLVE at z2 review)
> [z2-bench narration: pot + bowl, not many clues, moving right.] at the astrolabe scene:
> a cabinet with a crescent on one door, but zooming in shows a slightly DIFFERENT variation
> — the crescent DIRECTION is different, and it's a HOLE when zoomed in vs GLOWING when
> zoomed out. figured i need to put something in there. also the zoomed-in pic shows a plate
> and a lantern on top of the cabinet and a window directly to the right — inconsistent with
> the wide scene
> (context: z2 v-cabinet, p04 sun/moon slots. WIDE↔CLOSE-UP INCONSISTENCY, same class as
> R2-010 door: (a) crescent slot reads as glowing raised medallion in wide but recessed hole
> in close-up, AND the crescent orientation differs — the recess ("hole to place the coin")
> is the correct design; the wide should MATCH (recess, consistent crescent direction). This
> SUPERSEDES my earlier "medallion-wide is fine" call — the user wants consistency. (b) the
> close-up's surroundings (plate + lantern on top, window at right) don't match the wide
> plate's composition. NOTE: user is viewing BUILD-2 (old) art; but build-3's approved
> z2-cabinet base also shows medallions, so this WILL recur unless fixed. RESOLUTION: at z2
> art review, make the build-3 z2-cabinet wide↔close-up consistent — likely re-roll the wide
> to show recesses + align the close-up's framing/surroundings to the wide. Crescent
> orientation must be consistent (puzzle-relevant: crescent coin fits crescent slot). Build-3
> art; verify at z2 review. Also add door R2-010 to the same "wide↔close-up consistency"
> verification pass.)

### R2-017 — status: logged ⚠️ DESIGN TENSION — flag at processing, don't silently apply
> zoomed onto the potions on the shelf — since i solved this before i know they don't do
> anything, a cheap decoy. in principle, don't let me zoom into areas which cannot be used
> for clues
> (context: the potion shelf is an INTENTIONAL red herring (rh-potion-shelf — tempts pouring
> a potion in the door as a shortcut). The user's "no zoom on non-clue areas" principle
> CONFLICTS with the deliberate red-herring design (rh-clock, rh-potion-shelf, rh-rusted-key,
> rh-grimoire-decoys — all intentional challenge/atmosphere). This is a design-philosophy
> change with real tradeoffs (removing zoom-dead-ends strips the red herrings + some
> atmosphere). DO NOT silently strip them — SURFACE to the user at processing: do they want
> (a) red herrings removed entirely, (b) kept but made more obviously inert, or (c) this was
> just an in-the-moment gripe? Design → Theme & Puzzle Designer if a real change. Persists in
> build 3 regardless of art.)

### R2-018 — status: logged
> clicking the astrolabe i selected the Orion-shaped plate [p03]. i hear the "clearing" sound
> used on successful items, but the plates DISAPPEAR — left with only a transparent grey
> background where the 6 plates used to be (graphical bug)
> (context: z2 v-cabinet astrolabe p03. On selecting the correct plate, the 6 plate sprites
> vanish to a transparent grey void instead of showing the resolved state (selected plate /
> drawer springs open with coin+crank). State-visual/graphical bug — likely the plate
> sprites are removed on solve with nothing rendered beneath, or a missing/!transparent
> resolved-state asset. Ties to the systemic state-visual issue (R2-013/14/15) AND may need
> the build-3 astrolabe sprites/resolved-state art. → Developer (state render) + verify
> build-3 astrolabe assets at z2 review. Also: the "clearing" success sound is at least
> firing, but confirm it's an event-appropriate solve cue, not the generic one.)
>
> **CONFIRMED (user re-tested):** re-zooming onto the solved astrolabe shows the SAME grey
> background — so the solved-state astrolabe close-up is a broken/transparent/missing IMAGE.
> This is the root of R2-019 too: the drawer items can't be collected because the resolved
> close-up renders empty grey. So R2-018 + R2-019 = ONE bug: the p03-resolved cabinet/
> astrolabe close-up asset (drawer-open-with-coin+crank, plates resolved) is broken/absent.
> Fix = correct build-3 art for that state + Developer wiring so items are visible+tappable.
> HIGH priority (progression-blocking per R2-019).

### R2-019 — status: logged ⚠️ POSSIBLE CRITICAL (progression-blocking)
> the hidden drawer opened [p03], let me pick up the items. i can't seem to pick anything
> up? is this normal?
> (context: z2 astrolabe base drawer yields itm-silver-coin + itm-crank. User CANNOT collect
> them. LIKELY SAME BUG as R2-018 (plates vanished to grey void) — the p03-solved cabinet
> close-up appears to render into a broken/empty state where the drawer items aren't shown or
> aren't tappable. POTENTIALLY CRITICAL: coin is needed for p04, crank for p08 — if a real
> player can't collect them, it's a SOFT-LOCK. NOTE the discrepancy: QA's build-2 automated
> full-playthrough PASSED (collected these items via scripted coords) — so the LOGIC works
> but the human-facing interactive/visual state is broken (scripted taps hit rects the user
> can't see/reach). This is exactly the kind of thing an automated test can mask. →
> Developer, HIGH priority, investigate R2-018+R2-019 together as one broken p03-resolved
> state. Persists in build 3 (functional). Escalate at processing.)

### R2-020 — status: logged (inventory-lifecycle principle — Developer + build-3 art)
> put the gold ring on the cabinet door / sun placeholder — it works but looks weird (let's
> see on the regenerated images). BUT despite placing the ring in the sun slot, i still see
> it in my inventory. PRINCIPLE: (1) any item i use to interact — when placed and visible on
> the scene — must be REMOVED from inventory. (2) once an item has no further use for any
> puzzle, remove it from inventory entirely, like a CONSUMED item — e.g. the ring goes in the
> sun hole (its only use) → remove it. But the iron poker (used to sift ash AND later needed)
> → KEEP until all its uses are depleted, then remove.
> (context: p04 sun/moon placement. TWO parts: (a) ART — seated ring "looks weird"; ties to
> round-1 F-022 / AF-3 (seated ring/coin); build 3 regenerated cu-slots-seated — VERIFY at z2
> review. (b) FUNCTIONAL, a proper item-lifecycle model → Developer: an item PLACED into its
> slot/final use is removed from inventory (it's now on the scene); a tool is retained while
> it still has remaining uses and removed once ALL its uses are satisfied. MUST respect the
> anti-softlock invariants — never remove an item before every one of its uses is done (poker
> = p05 ash + p06 barrel; file = p12; crank = p08; etc. — Developer tracks remaining-uses per
> item from the puzzle graph's `uses` arrays). Persists in build 3. This refines round-1's
> manual-pickup work into a full place/consume/retain lifecycle.)

### R2-021 — status: logged
> a new "back" arrow lets me switch between scenes — a bit confusing. maybe show text on the
> arrows telling what they do (go left / right / back / up...). the text can appear briefly
> to help, then disappear while the player is locked into solving puzzles in that scene
> (context: navigation affordance clarity — the view-cycle + zone-exit chevrons (§7-R2) +
> the R2-008 swipe don't self-explain, esp. the "back" arrow. FEATURE → Developer: TRANSIENT
> directional hint labels (e.g. on scene entry / first-time, fade out after a few seconds or
> once the player interacts). DESIGN TENSION to flag: the game is intentionally NEAR-WORDLESS
> (CLAUDE.md genre decision) — persistent text labels violate that. The user's own framing
> (brief, auto-hiding, help-then-disappear) is the acceptable compromise: first-time/transient
> hints or directional glyphs, NOT permanent labels. Producer: confirm the transient/first-run
> approach at processing so we honor near-wordless. Persists in build 3.)

### R2-022 — status: logged
> back in the cellar, used the iron stick on the barrel and got the weight. after getting the
> weight, zooming onto the barrel still shows it CLOSED — should be opened by now. also, once
> i picked up the weight, why do i even need to zoom into the barrel anymore? i don't think i
> do
> (context: z3 p06 barrel-pry. TWO parts: (a) FUNCTIONAL — barrel still shows closed after the
> weight is taken; the pried/open+empty state isn't applied. SAME systemic state-visual-refresh
> bug as R2-013 (trapdoor), R2-014 (spoon), R2-015 (door), R2-018 (astrolabe) — add to that
> single audit; the art states exist (z3-cellar-barrel-pried + ov-barrel-*). (b) DESIGN/UX —
> a DEPLETED hotspot (barrel after weight taken) shouldn't keep inviting a zoom with nothing
> to do. Related to but distinct from R2-017 (never-useful red herrings): this is once-useful-
> now-exhausted. Partly solved just by showing the open+empty state (player sees it's done);
> fuller version = stop offering the close-up / down-rank the hotspot once depleted. Flag with
> R2-017 as the "prune dead-end zooms" discussion at processing. → Developer (state refresh) +
> design call on depleted-hotspot handling. Persists in build 3.)

### R2-023 — status: logged
> put the weight on the lever [p07], opened the secret door, see the shelf with moonflower +
> bird-with-key [z4 alcove]. zoomed on the bird, got the key — but the zoomed picture shows
> the bird HEAD only instead of the full bird like the wider scene. also i don't see the
> flipping-between-scenes arrows here, i think u missed them. i click anywhere to go back now
> (context: z4 v-alcove. (a) ART wide↔close-up consistency — cu-statue-key shows head/beak only
> vs full statue in the wide plate; same family as R2-010/R2-016. A tight beak+key crop may be
> intentional, but it should still clearly read as the SAME statue; verify/align at z4 review
> (build 3 regenerated cu-statue-key). (b) NAV — z4 is a SINGLE-VIEW zone (only v-alcove), so
> there are correctly NO left/right flip arrows; this is by-design, NOT a miss — but the
> ABSENCE confuses the user (reinforces R2-021: nav must self-explain). Ensure a clear EXIT/
> back affordance out of the alcove (currently "click anywhere to go back" — undiscoverable).
> → mostly R2-021 nav-clarity + z4 art verify. Persists in build 3.)

### R2-META-QA — status: logged (process, not a game bug)
> "quality agent missed a lot this time around"
> (VALID CRITIQUE — own it. QA's build-2 automated regression PASSED (scripted-coordinate UI
> tests) yet MANY human-facing bugs shipped: broken state-refresh (R2-013/14/15/18/22), the
> astrolabe soft-lock (R2-019), hotspot mismap (R2-007), surviving psh sounds (R2-009/12/15).
> Root: scripted taps hit rects a real player can't see/reach, and the tests asserted logic
> state, not what's rendered/reachable. PRODUCER ACTION for the post-fix QA pass: require
> real-play-style verification — screenshot review of each solve's RESULTING wide-view state,
> assert state-visual changes + hotspot-to-close-up mapping + item-collectibility as a HUMAN
> sees them, not just engine flags. This meta-note directly shapes how the next QA runs.)

### R2-024 — status: logged
> clicking anywhere has that psh sound again
> (context: THE KEY INSIGHT for the sound audit — the psh is essentially the DEFAULT tap/click
> sound firing on virtually EVERY tap, including empty-space clicks and back-navigation. This
> explains why it's everywhere (R2-009 page-flip, R2-012 trapdoor, R2-015 door, and now
> any-click). Root fix: the generic per-tap sound must be REMOVED as the default (tap feedback
> stays VISUAL per style-guide §7 — the parchment pulse — with NO default sound); only specific
> EVENTS get their own themed cues (pickup ✓ kept, solve, unlock, door-open, page-flip). This
> supersedes the piecemeal per-location notes: ONE fix = kill the default tap sound + map
> event-specific sounds. → Developer, top of the sound audit. Persists in build 3.)

---

### R2-025 — status: logged 🔴 CRITICAL CONFIRMED (soft-lock) + more wide↔close-up bugs
> now i'm seriously locked and i know why: i need the sun/moon cabinet but can't pick up the
> drawer items. remember the grey box — i randomly clicked around on the plain grey box and
> managed to pick up the silver moon coin and some attachment that goes somewhere. serious bug:
> i only knew to do this because i played build 1 — the items are NOT visible here. picked them
> up just to keep testing. ALSO images are off: the drawer close-up shows drawer UNDER THE
> ASTROLABE with a window behind it, but zoomed out the drawer is UNDER THE WINDOW, opened.
> zooming on the window to see Orion shows the window CLOSED, but zoomed out the window is
> OPENED. sloppy quality.
> (context: CONFIRMS R2-018/019 as a HARD PROGRESSION-BLOCKING SOFT-LOCK: the p03-resolved
> astrolabe/drawer renders as an empty grey box; coin + crank are invisible and only findable
> by blind-clicking or prior-build knowledge. A NEW PLAYER IS STUCK HERE. TOP-PRIORITY critical
> — the whole level is uncompletable past p03 for anyone who didn't play build 1. Plus a NEW
> wide↔close-up inconsistency cluster in z2-cabinet: (i) drawer POSITION differs (under
> astrolabe+window-behind in close-up vs under-window in wide); (ii) window STATE differs
> (closed in the Orion close-up vs open in wide). Same consistency family as R2-010/16/23 →
> z2 art-review verification + likely re-derive the z2-cabinet close-ups to match the wide.
> Reinforces R2-META-QA (this hard-lock passed automated QA). → Developer (astrolabe resolved-
> state render + item collectibility, CRITICAL) + build-3 art consistency (z2 window/drawer).)

### R2-026 — status: logged 🔴 CRITICAL — grey-box bug is SYSTEMIC (not just astrolabe)
> placed the silver moon on the cabinet hole — SAME grey box issue here. randomly picked up a
> knife [file] and a bottle [phial] from the grey box. going to use them, but log it.
> (context: the broken grey-box resolved-state is NOT astrolabe-only — the sun/moon cabinet
> (p04 resolved → cabinet-open revealing file+phial) ALSO renders as an empty grey box with
> invisible-but-present items. So this is a SYSTEMIC class: every close-up that transitions to
> a "revealed items" / opened state (astrolabe drawer p03, sun/moon cabinet p04, and likely
> others — verify cellar drawer, alcove, etc.) renders grey/blank instead of the resolved-state
> art, leaving items invisible. Almost certainly ONE root cause: the "open/revealed" overlay or
> state-image isn't being composited/shown (missing/transparent), same mechanism as the
> systemic state-visual-refresh bug (R2-013/14/15/18/22). Build 3 regenerated these resolved
> states (cabinet-open, drawer-open) — so the ART now exists; the Developer must fix the
> render/compositing so those states DISPLAY and their items are visible+tappable. TOP CRITICAL
> with R2-025. → Developer (fix the resolved-state rendering across ALL such close-ups) +
> confirm build-3 resolved-state assets are wired in. Reinforces R2-META-QA.)

### R2-context (narration — not routed)
> "tried to feed the bird with the spoon but i have no food. let me open the cage. cool i got
> [reconfirm R2-024] the down/back arrow ALSO plays the psh — reinforces that the default
> per-tap sound fires on navigation too; one fix (kill the default tap sound) covers it.
>
> "tried to feed the bird with the spoon but i have no food. let me open the cage. cool i got
> the feather." — p11 solved via the cage key (feather granted) — WORKING. Minor design note:
> the 'feed the crow' theory-magnet still flickered ("i have no food"), the exact theory D4/R1
> aimed to defuse — but it resolved fine (user pivoted to the key), so no action; just noting
> the magnet isn't 100% dead. Reinforces R2-011 (user likes the refusal).

### R2-027 — status: logged
> using that tool [crank] that twists things into the right zoomed placeholder [winch socket,
> p08]. i hear psh+success tone but i DON'T see the items attached — another image glitch. zoom
> out: window/shutter opened, moonbeam shines. turned the mirror to direct moonlight [p09], went
> in and picked up the moonbloom [p10] — able to pick it up WITHOUT zooming on it. but clicking
> the flowerpot AGAIN still lets me zoom in, really unnecessary
> (context: (a) crank-fitted state doesn't render the crank attached after fitting the winch
> (p08) — same resolved-state-not-showing family as grey-box R2-025/26 + state-refresh
> R2-013/14/22; add to that fix. (b) psh+success double-sound → R2-024/sound audit. (c)
> DEPLETED-HOTSPOT: after picking the moonbloom the flowerpot still invites a pointless zoom —
> SAME as R2-022 (spent barrel)/R2-017 (dead-end zooms); confirms the pattern → "prune depleted/
> dead-end zooms" design discussion. POSITIVE: the moonbeam→mirror→bloom light-routing chain
> (p08/09/10) otherwise WORKED and read well. → Developer (crank render + sound) + design
> (depleted-hotspot pruning). Persists in build 3.)

### R2-028 — status: logged
> combining items isn't intuitive — how can i make combining two objects from inventory more
> intuitive?
> (context: p12 file+spoon combine. Current combine (round-1: tap item A then tap item B, or
> drop on workbench) is undiscoverable. FEATURE/UX → Developer. Producer to propose options at
> processing, e.g.: select item A (armed) → tap item B in the inventory bar shows a "combine?"
> affordance/animation; or a small two-slot combine tray in the enlarged inventory; keep it
> consistent with select-then-tap. Persists in build 3. User explicitly invites a solution.)

### R2-029 — status: logged (feature, forward-looking)
> when enlarging an inventory item, i should be able to ROTATE it to look around it for clues
> (maybe something written under an item in future rooms)
> (context: enhance the item-inspect view (F-016/§7-R3) with rotation / multi-angle inspection
> so items can hide clues on their back/underside — a puzzle mechanic for FUTURE levels too.
> Bigger feature: needs either lightweight 3D item models or multiple rendered angles per item
> (art + tech implication; icons currently single-angle RGBA). → Developer + Asset/Art for
> multi-angle assets; scope at processing (likely a Level-2+ investment, but decide whether to
> seed the interaction now). Note for the Designer: enables "clue hidden under/behind an item".)

### R2-030 — status: logged
> when i select an inventory item and try to use it on something it's not made for, it auto-
> deselects on failure. don't — let me manually select/deselect
> (context: refines the round-1 select-then-tap model. On a FAILED use (wrong target), KEEP the
> item armed instead of auto-disarming, so the user can immediately try another target without
> re-selecting; deselect only on explicit user action (tap the item again / tap-away) or on a
> SUCCESSFUL use. Careful: the crow feed-cup (D4) and wrong-slot placements already return the
> item to inventory — those should leave it armed too, per this. Functional → Developer;
> persists in build 3.)

### R2-completion — status: logged (LEVEL COMPLETED end-to-end)
> added moon dust [shavings] to mortar... pumped bellows to 3, stirred CCW 5 times (psh on
> pump/stir/release buttons), released, bottled the moonwater [draught] with the empty bottle
> (psh), went to the main gate, poured the moonwater into the thorny-door placeholder, unlocked
> (psh). "i'm out."
> (context: LEVEL COMPLETED end-to-end — p13→p14→p15→p16→p17 all work; win condition fires. So
> the PUZZLE LOGIC is fully solvable and complete; the user got through despite the bugs (partly
> via build-1 knowledge past the grey-box soft-lock R2-025/26). Sound: psh reconfirmed on brew
> buttons, item-pickup-into-bottle, door unlock, cellar nav — all the DEFAULT tap sound (R2-024)
> — plus the brew mini-game buttons work functionally. Net: bugs are ~entirely PRESENTATION
> layer (sound, resolved-state rendering, state refresh, wide↔close-up consistency, nav clarity,
> hotspot pruning, item lifecycle) — the underlying design/logic is sound.)

---
## ROUND 2 — PROCESSED 2026-07-08 (routed changelist — pending user CHECKPOINT-1 approval + 3 design calls)

**Framing:** level is completable end-to-end; puzzle LOGIC is sound. ~all issues are
PRESENTATION-LAYER. They consolidate into root fixes. Build 3 (art) must ALSO carry the
round-2 Developer fixes or it still ships the critical soft-lock — so **build 3 = new art +
round-2 dev batch + art-consistency verify**, then player-style QA, then user review → ship.

### Root-cause clusters & routing

**CLUSTER B — Resolved-state / state-visual rendering 🔴 CRITICAL (contains the soft-lock) → Developer**
Items: R2-018/019/025/026 (grey-box: p03 astrolabe drawer + p04 cabinet render blank; items
invisible/uncollectible = PROGRESSION SOFT-LOCK), R2-013 (trapdoor open not shown), R2-014b
(spoon persists), R2-015b (door open not shown), R2-022a (barrel), R2-027a (crank fitted).
Root: after any solve/pickup the game fails to render the resolved/opened/taken state (close-up
AND wide) — one mechanism fix (composite & show resolved-state overlays; refresh wide view;
make revealed items visible+tappable) + wire the build-3 resolved-state art. Regression: FULL.

**CLUSTER A — Sound completion → Developer**
Items: R2-024 (ROOT: kill the default per-tap sound — tap feedback stays visual; it fires on
every tap incl. nav/empty), R2-009 (page-flip), R2-012 (trapdoor), R2-015a (door), R2-027b —
all subsumed by R2-024 + event-mapped themed sounds (keep pickup R2-002; add solve/unlock/
door-open/page-flip). R2-004/R2-005 integrate the user's `music-level1.wav` (loop, unobtrusive,
replace ocean). R2-006 add TWO mute toggles (ambiance/music + SFX) — updates global-ui-style
§5.4/§8. Regression: targeted (audio) + toggle test.

**CLUSTER C — Item lifecycle & interaction → Developer**
R2-003a (ash ring: manual pickup, no auto-grant), R2-020 (place/consume/retain lifecycle —
remove placed items; retain tools until all `uses` satisfied then drop; respect anti-softlock),
R2-030 (don't auto-deselect on failed use — keep armed), R2-028 (intuitive combine — proposed:
arm item A → tap item B in bar shows "combine?"; confirm approach). Regression: FULL (inventory).

**CLUSTER D — Navigation clarity → Developer**
R2-021 (transient/first-run directional hint labels — near-wordless-safe: brief, auto-hide),
R2-023b (single-view zone exit affordance), R2-008 (swipe to flip pages + cycle views; arrows
stay; NOT item-drag). Regression: targeted.

**CLUSTER E — Wide↔close-up art consistency → Asset Generation / Art Director (build-3 verify + targeted re-roll)**
R2-010 (door), R2-016 + R2-025 (cabinet slots + window/drawer position/state), R2-023a (statue
head-only), R2-014a (drawer blurry), R2-003b (ash sifted/cleared states). Build 3 already
regenerated most (cu-slots recesses, unified beak-basin) — VERIFY at per-zone review; re-roll
any mismatch. Regression: targeted visual.

**CLUSTER F — Discrete bug → Developer**
R2-007 (triptych hotspot mismap: right painting opens left's close-up; puzzle-relevant). FULL-ish.

**CLUSTER G — Clock cuckoo clarity → design (see Q3)**
R2-001 (cuckoo reads as a clue but is intentional flavor/rh-clock).

**PROCESS — next QA must test like a PLAYER (R2-META-QA)**
Player-style verification: assert each solve's RENDERED resolved-state, hotspot→close-up
mapping, and item collectibility as a human sees them (screenshot-reviewed) — not scripted-
coordinate logic flags (which masked the soft-lock). Binding for the post-fix QA pass.

**POSITIVES (keep, no action):** R2-002 inventory sound, R2-011 crow refusal, light-routing
chain, level completable.

### 3 DESIGN CALLS surfaced to user (CHECKPOINT-1 — not decided unilaterally)
- Q1 red-herring / depleted-hotspot / dead-end-zoom pruning (R2-017/022b/027c)
- Q2 rotate-to-inspect items scope now vs Level 2+ (R2-029)
- Q3 clock cuckoo treatment (R2-001)
(answers recorded, then CHECKPOINT-1 approval → execute; CHECKPOINT-2 = player-style QA review
before build-3 ship.)

_Say "that's all, process it" (or similar) when ready to process this round._
