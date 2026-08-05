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
> ✅ RIGHTS CLEARED (user, 2026-07-08): the track is **fal.ai-generated** → commercial use is
> fine, no third-party licensing issue. Developer: proceed; record "fal.ai-generated, user-
> owned, commercial-use OK" in the implementation-notes licensing table.

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

**USER DECISIONS (2026-07-08) — CHECKPOINT-1 approved, executing:**
- Q1 = **PRUNE DEPLETED ONLY.** Keep red-herring decoys (potions, decoy grimoire pages — deliberate).
  But once a hotspot is USED UP (barrel emptied, flower picked, etc.), stop offering its zoom /
  render it clearly spent. Much of this falls out of the Cluster-B spent-state rendering. Developer
  + (design: which hotspots count as "depleted" from the graph's yields/uses).
- Q2 = **DEFER rotate-to-inspect to Level 2+.** Do NOT build for Level 1 (no L1 item needs it).
  Logged as a planned feature; introduce when a level's puzzle uses it. (R2-029 parked.)
- Q3 = **REMOVE the cuckoo entirely.** Cut the cuckoo pop (rh-clock); keep clock face + numeral
  ring (numeral ring stays the p01 reference). Removes D5 one-shot. Developer + graph note (drop D5
  cuckoo from the design; the clock is now purely the numeral reference). Art: build-3 clock close-up
  no longer needs the cuckoo-door/toy states.

### R2-031 — status: logged → ART-PROCESS DIRECTIVE (feeds Cluster E + all future generation)
> "when generating a scene, take picture-perfect note of it — how everything is set together,
> the colors, the shapes, the texture, everything — so when you zoom in on an area you recreate
> it EXACTLY as in the original scene, just with a different perspective or state."
> (ROOT-CAUSE fix for the wide↔close-up inconsistency family R2-010/16/23/25: close-ups were
> generated "in the style of" the base rather than FROM it, so they drifted. BAKED INTO
> `.claude/agents/asset-generation.md` as the binding "Scene→close-up EXACT recreation" rule:
> derive close-ups by CROPPING the base-plate region and using that exact crop as the img2img
> base, only changing crop/perspective or state; a close-up whose layout/colors/shapes differ
> from its parent scene is a DEFECT. → governs the Cluster-E re-rolls and every future level.)

_Say "that's all, process it" (or similar) when ready to process this round._

---

## Round 3 (in progress — build-3 device testing on iPad, builds 8→9; logging)

**Context:** casual device observations (not thorough — the game was "unplayable with wrong
images" due to the stale-close-up shadow bug, being fixed in build 9). Log functional/layout/
sound items now; defer close-up-LOOK critiques to build 9 (correct art). Fold quick fixes into
build 9 where possible.

### R3-001 — status: logged (fold into build 9)
> the background music i gave is playing for the ENTIRE game instance (menus / before level
> start), instead of being limited to Level 1 as intended. before the level starts, the only
> sounds should be SFX like a click or ping — NOT the psh. "select the most appropriate based
> on my previous selections."
> (context: two parts. (a) BUG — `music-level1.wav` is wired app-wide; it must be SCOPED to the
> Level-1 scene lifecycle (start on entering L1, stop on exit to menu/level-complete). Menus /
> pre-level = NO level music. (b) DESIGN — menu/pre-level UI needs appropriate SFX (button
> taps): a soft, clean, quiet CLICK (and a subtle confirm/ping for major actions), consistent
> with the user's established prefs — they LIKE the quiet add-to-inventory pickup sound, HATE
> the generic "psh" (removed as default, R2-024), want the quiet/tasteful neutralxe register.
> Producer selection (delegated by user): a muted tactile wood/paper click for menu buttons +
> a soft confirm tone for Play/level-enter — NEVER the psh, never the level music in menus.
> → Developer. Fold into build 9. Note for future levels: each level's music is level-scoped;
> the global chrome/menu layer has its own small quiet SFX set, no level music.)

### R3-002 — status: logged (fold into build 9)
> the Level-Select thumbnail is an OLD image — hopefully the stale-assets fix caught it
> (context: `EscapeRoom/Resources/GameAssets/chrome/level1-thumb.jpg` is a CHROME asset, a
> DIFFERENT name/path from the level-1 close-ups the shadow fix promoted — so it was likely
> NOT caught (verify). Fix: regenerate the Level-1 select-card thumbnail from a representative
> BUILD-3 scene (crop/downscale a new base plate — e.g. z1-hearth-base or z1-entry-base, an
> atmospheric read), replacing the stale build-2 painterly thumbnail. → Developer (crop from a
> build-3 base) or Asset if a fresh render is wanted; fold into build 9. Add the chrome
> thumbnail to whatever the shadow guard covers so chrome art can't go stale silently either.)

### R3-003 — status: logged (fold into build 9)
> i don't like the Roman "I" indicating the level number — use the normal "Level 1" serif
> (context: the Level-Select card renders the level number as a Roman numeral "I". This
> actually VIOLATES the approved `specs/global-ui-style.md` §3, which already says: "plain
> Arabic numerals in the chrome ('Level 3'). Roman numerals are an in-world glyph language
> (clock/runes); do not leak them into menus." So the implementation deviated from spec. Fix:
> render the level number as ARABIC "1" / "Level 1" in the serif accent (New York, per §3),
> not Roman. → Developer chrome fix, fold into build 9. Confirms the spec; no spec change.)

### R3-004 — status: logged (likely a symptom of R3-005)
> the arrow/rune clues used to unlock the potion-room door (p01) — i can't get a close-up on
> them
> (context: the four element-rune marks (AIR/FIRE/EARTH/WATER + numerals) can't be inspected —
> tapping where they visually sit does nothing. Almost certainly a hotspot-misalignment symptom
> of R3-005: the rune marks are in DIFFERENT positions in the new build-3 art than the old
> plates the tap rects were calibrated to. → Developer, part of the R3-005 hotspot re-derive.)

### R3-005 — status: logged 🔴 STRUCTURAL (significant) — hotspot positions calibrated to OLD art
> randomly clicking to the LEFT of the clock opens the old cuckoo-clock stale close-up. "with
> the new images generated, the positioning of 'clicking' for close-ups needs to change — the
> developer seems to be using old placement placeholders that fit the OLD images, not the new
> ones."
> (context: SHARP + likely correct + WIDESPREAD. The hotspot/tap rects (plate-normalized on the
> fixed 2732×1366 scene) were calibrated to the OLD build-2 art element positions. The new
> build-3 plates place objects in DIFFERENT spots, so every tap target can be off: tapping where
> a clue visually IS does nothing (R3-004 runes), and tapping where the OLD hotspot was opens
> the wrong/stale close-up (here: a leftover cuckoo close-up — which per Q3 should have been
> REMOVED entirely, so also a Q3-cleanup gap: the cuckoo close-up asset + its hotspot weren't
> deleted). THIS IS WHY CI 'passed': the scripted playthrough uses the same plate-normalized
> coords the code maps, so taps 'land' internally — but a HUMAN clicking where they SEE the
> element misses (same false-pass class as the astrolabe/viewport). FIX = re-derive EVERY
> interactive hotspot + close-up trigger rect to match where each element sits in the NEW
> build-3 plates (use the manifest's build3 element geometry where recorded; visual-verify the
> rest), AND remove the leftover cuckoo close-up/hotspot (Q3). Player-style verification must
> tap where a HUMAN sees each element, not the internal rect. → Developer, SIGNIFICANT task.
> Recommend folding into build 9 so it's the first genuinely playable build (correct images AND
> correct tap targets); otherwise build 9 = right art but still-wrong taps.)

### R3-006 — status: logged (mostly confirms stale-shadow bug; ONE new datapoint = icons)
> ash close-up stale, iron-stick→ring close-up stale, AND the ring INVENTORY ICON stale
> (context: user is testing BUILD 8 (pre-shadow-fix) — build 9 not yet released — so the stale
> ash/ring CLOSE-UPS are the already-known stale-shadow bug, fixed wholesale in build 9; no need
> to enumerate more stale-image instances. NEW datapoint: the stale RING INVENTORY ICON confirms
> the stale-shadow bug also hit ICONS (icon-gold-ring etc.), not just scene close-ups. → Verify
> build 9's shadow fix PROMOTED all build-3 `-nb` ICONS to canonical too (the fix claimed
> close-ups/variants/icons; confirm icons are actually covered). If any icon `-nb` wasn't
> promoted, include it. Also confirms the p05 ash→ring flow works functionally (reveal + collect)
> even on build 8 — just with stale art.)

### R3-007 — status: logged 🔴 CRITICAL (breaks p01 SOLVABILITY) — element-rune glyphs inconsistent across assets
> the rune-door lock (potion-room, p01) shows DIFFERENT glyphs than the "arrow" element-rune
> clues from earlier → the player literally cannot match them → p01 unsolvable. "regenerate this
> scene with the right arrow clues (easier), or regenerate all other scenes/close-ups to use the
> grimoire's glyphs — pick the easier. this is why i told you to be specific about asset-gen
> consistency across scenes and close-ups."
> (context: the four element-rune glyphs must be IDENTICAL everywhere they appear — the four
> element MARKS (bellows AIR+I, lintel FIRE+II, flowerpot EARTH+III, windowsill WATER+IV),
> grimoire PAGE A (rune→pictogram map), and the rune-DOOR lock tiles. The build-3 regen rendered
> them per-scene → they DRIFTED, so the door glyphs don't match the clues. Puzzle-graph
> `clu-grimoire-elements` defines the canonical geometry: FIRE = upward triangle; WATER = downward
> triangle; AIR = upward triangle with bar; EARTH = downward triangle with bar.
> **PRODUCER FIX CHOICE (user delegated "pick the easier"):** deterministic-stamp approach —
> define the 4 canonical glyphs as fixed PIL geometry and STAMP them IDENTICALLY onto every asset
> that shows them: the rune-door tiles (cu-runedoor-tiles + runedoor tile sprites), the 4 element
> marks (cu-bellows-rune, cu-lintel[FIRE], cu-flowerpot-rune, cu-windowsill-rune), and grimoire
> page A. This GUARANTEES consistency (identical pixels), is cheap ($0/near-$0), and is effectively
> the user's easier Option A done robustly — no full scene regens. Grayscale/color-blind distinct.
> → Asset Gen (glyph re-stamp) + Developer stage; fold into build 9. VERIFY a player can match
> mark↔grimoire↔door for all four. This is the load-bearing precision-glyph consistency the §2.3
> and R2-031 checks should enforce — see the strengthened asset-gen rule.)
>
> **GRIMOIRE EMPHASIS (user, 2026-07-09):** the grimoire is the HUB reference — it carries the
> rune→element map (page A) the player uses to read the door, AND it orients the player to the
> puzzle / where clues are. So the grimoire's rune glyphs are the CANONICAL anchor: stamp the
> canonical glyphs on grimoire page A, and make the marks + door match THE GRIMOIRE (if marks/door
> disagree with the grimoire, THEY are the ones to fix — the grimoire is the player's source of
> truth). Also VERIFY the grimoire's other content reads coherently in the new art (page A
> rune↔pictogram pairing correct, recipe page p14, page B sun/moon p04) — the grimoire close-ups
> were regenerated and must be legible + correct, not just internally consistent.)

---
## ROUND 3 — PROCESSED 2026-07-09 (all → BUILD 9; user blocked at p01, testing stopped)

**Framing:** the build-3 art *regeneration* introduced a cascade of consistency/integration
defects that make build 8 unplayable. Build 9 must fix ALL of them to be genuinely playable.
User stopped at p01 (can't find/match the last rune clue → can't unlock the potion door).

### Routed (all into build 9)
1. **Stale close-up/variant/icon shadows → build-3 art** (Developer) — DONE/CI-greening (82 files
   re-staged); +VERIFY icons promoted (R3-006). Root fixed + `assert_no_nb_shadow` guard.
2. **R3-007 🔴 glyph consistency (unblocks p01)** → Asset Gen: define the 4 canonical element-rune
   glyphs (fire ▲ / water ▽ / air ▲-bar / earth ▽-bar) and STAMP identically on grimoire page A
   (the HUB / source of truth), the 4 element marks, and the rune-door tiles; verify all grimoire
   pages legible+correct. Then Developer stages.
3. **R3-005 🔴 STRUCTURAL hotspot re-calibration** (Developer) — re-derive EVERY interactive
   hotspot + close-up trigger to match element positions in the NEW build-3 plates; remove the
   leftover cuckoo close-up/hotspot (Q3). Subsumes R3-004. Unblocks tap-to-inspect everywhere.
4. **R3-001 music level-scope + menu SFX** (Developer) — music tied to L1 scene lifecycle (not
   app-wide); quiet tactile menu click + soft confirm tone; no psh, no level music in menus.
5. **R3-002 Level-Select thumbnail** → Asset/Developer: regenerate from a build-3 scene; add chrome
   art to the stale-shadow guard.
6. **R3-003 Roman→Arabic level numeral** (Developer) — "Level 1" serif, per global-ui-style §3.

### Sequencing (avoid concurrent working-tree writes on the branch)
shadow fix green → **Asset Gen phase** (R3-007 glyphs + R3-002 thumbnail, art finalized FIRST) →
**Developer phase** (stage art + R3-005 hotspots against FINAL art + R3-001 + R3-003 + verify
R3-006 icons) → CI green → **build-9 QA player-style** (tap where a HUMAN sees each element;
prove p01 solvable by matching grimoire↔marks↔door end-to-end; no stale art incl. icons/thumbnail)
→ re-release build 9 to TestFlight.

_Round 3 complete; user testing stopped (blocked at p01). No further items expected this round._

---

## Round 4 (in progress — build-9 device testing on iPad; logging)

**Device/context:** iPad, TestFlight, **build 9** (Within 1.0 build 9) — the build that
shipped to fix the round-3 p01 block + added the interim iPad letterbox. Logging only;
not yet processed. More items expected one at a time via the Producer.

### R4-001 — status: logged
> ok starting the game from scratch and resetting progress, once i click play i can see the updated thumbnail and it replaced the roman I with 1, but missed to write "Level". it's supposed to say Level 1 as i previously instructed.
> (context: Level Select / play screen. POSITIVE note embedded — the updated build-3
> thumbnail now shows correctly. DEFECT: the level label renders just "1" instead of
> "Level 1". Likely ties to round-3 R3-003 (which changed the stale Roman "I" thumbnail
> to Arabic "1" serif) — that fix dropped/omitted the word "Level". User is re-confirming
> a prior standing instruction that the label must read "Level 1". Factual capture only —
> not classified/routed.)

### R4-002 — status: logged
> selecting the thumbnail stars off with the ocean waves sound then goes into the soundclip i shared with you. you should have removed the oceanwaves altogether
> (context: on starting Level 1 from the Level Select thumbnail, the OLD ocean-waves
> ambient loop plays briefly at level entry BEFORE the user-supplied music clip takes
> over. Carry-over of round-2 R2-004 (z1 ambient read as ocean, wrong for a woods/cabin
> theme) + R2-005 (user provided replacement music `music-level1.wav`) — the ocean
> ambience was supposed to be REMOVED entirely and replaced by the supplied music, but a
> residual ocean-waves sound still fires at the start of the level before the music.
> Audio/functional. Factual capture only — not classified/routed.)

### R4-003 — status: logged
> hitting the pause button up left gives me options to restart level or open settings etc. selecting settings uses that ugly tick sound. can u make sure you're only using pings and soft sound effects for selections all across main menu, from main page to level collection (i like the ping u used there) and to overall game controls
> (context: the Pause menu (top-left pause button → Resume/Restart Level/Settings/Main
> Menu) plays an unpleasant "tick" sound on selection (e.g. opening Settings). User wants
> a CONSISTENT soft "ping"/gentle SFX for ALL menu-chrome selections across the whole
> menu layer — Main Menu → Level Select ("level collection") → Pause menu / game
> controls. POSITIVE reference embedded: user LIKES the ping already used on the Level
> Select screen — make that the standard everywhere. Ties to round-3 R3-001 (menu-tap/
> menu-confirm SFX were synthesized/added) — the pause-menu confirm cue is the wrong/
> harsh one and menu SFX aren't consistent. Audio/polish, menu-chrome-wide (global-ui
> layer), not level-specific. Factual capture only — not classified/routed.)

### R4-004 — status: logged
> ok so i picked up the iron stick and it seems there is a glitch there. let me try to explain it to the best of my ability and let me know if it is still unclear. basically, as soon as i pick up the iron stick, the scene should stay intact with only the iron stick removed because it is now in my inventory. however, the place where the iron stick used to be gets replaced with a portion of the fireplace image from the original scene, but it is misaligned with the background scene, so the fireplace looks like it's broken
> (context: z1 v-hearth, picking up the iron poker (itm-poker). EXPECTED: base scene
> unchanged, only the poker gone. ACTUAL: the "poker-taken" state patch/overlay (the
> `ov-poker-taken` overlay or the `z1-hearth-poker-taken` variant covering the hearth
> region where the poker was) is MISALIGNED with the base plate — a mismatched portion of
> fireplace art is composited over that spot, so the fireplace reads as broken/torn. This
> is a state-variant/overlay pixel-ALIGNMENT defect (the pickup overlay doesn't register
> with the base scene). Could be art (overlay plate not pixel-aligned to base) and/or
> developer (overlay positioning/compositing). Same "state-variant alignment / resolved-
> state rendering" family touched in round 2 (e.g. R2-014 drawer patchy) but this is
> specifically a MISREGISTERED overlay on poker pickup. Build 9, iPad. Factual capture
> only — not classified/routed.)
>
> SCREENSHOT RECEIVED (described; image pasted in chat). Wide z1-hearth view (pause button,
> L/R nav chevrons, inventory bar showing the star-bit key). In front of the ash pile, what
> should be the fireguard/grate reads as a FLAT, slightly-offset panel — a cropped 'portion
> of the fireplace image' standing where the poker was, not integrated into the hearth
> (matches the user's 'hearth looks broken'). Same overlay appears clearly skewed in the
> R4-006 screenshot.

### R4-005 — status: logged
> another bug i noticed is basically when selecting an item in my inventory (in this case the poker), and trying to use it to interact with other things in the scene (which is normal player behavior to try to use things together to see if something else going to unlock, i can't get close ups to other clues or unselect item from inventory, hence hindering progress. a good example is that i selected the poker, tried to unselect it didn't work, so i tried to use it on the clock on the wall to see if i can "reach" it, it didn't give me a close up which i was expecting, tried to use it on both the arrow clues which also didn't give me a close up i was expecting, the only way i could "unselect" the poker was when i went to the scene with the bird, and clicking on the bird and then it would unselect. i know there are other ways to unselect because at some point i was also randomly clicking places and was able to get a close up on the fireplace which also allows to unselect, but i think the hotspot is not easily findable cuz i couldn't reproduce that. i need you to find the issue and fix it. let me know if it's not clear
> (context: z1, interaction model with an ARMED inventory item (poker). Two coupled
> defects: (1) NO EASY DESELECT — with the poker armed, tapping to unselect doesn't work;
> the user only managed to disarm it by tapping the crow in the entry scene, or by
> randomly hitting the fireplace close-up hotspot (which they couldn't reliably reproduce
> — hotspot hard to find). (2) ARMED ITEM BLOCKS INSPECTION — while an item is armed,
> tapping other objects/clues (the wall clock, the rune/"arrow" element marks) does NOT
> open their expected close-up; so the player can't inspect other things or experiment
> with using the item, hindering progress. Expected player behavior: freely try an armed
> item on things AND still be able to open close-ups / examine clues, with an obvious way
> to deselect. Ties to round-2 R2-030 (on failed use keep item armed, deselect only on
> explicit action) and the select-then-tap interaction model (round-1) + the "inventory/
> close-up access" family — but this is a distinct, stronger report: armed state traps
> the player with no discoverable deselect and blocks all other close-ups. User
> explicitly requests: find the root issue and fix it. Interaction-model/UX, functional →
> Developer (at processing). Build 9, iPad. Factual capture only — not classified/routed.)
>
> SCOPE (user directive): the fix must apply to ALL inventory items game-wide — not just
> the poker. The poker is only the example; the deselect affordance and the ability to
> still open close-ups / inspect other objects while an item is armed must hold for EVERY
> armed inventory item (file, crank, coin, ring, keys, spoon, blossom, feather, phial,
> etc.). Route/implement as a general interaction-model fix, not a per-item patch.

### R4-006 — status: logged
> again another bug related to my earlier image placement.. when clicking the rug i can see the misplaced image of the fireplace overlaying in front of the rug, obvious image glitch, i'll show it to u on a screenshot later
> (context: z1 v-hearth, interacting with the rug (the floor rug over the trapdoor). A
> misplaced/misaligned FIREPLACE image is compositing IN FRONT OF the rug — an obvious
> overlay glitch. Same overlay-misregistration/wrong-overlay family as R4-004 (poker-taken
> patch misaligned) — likely a hearth state-overlay rendering with wrong position and/or
> wrong z-order (drawing on top of the rug region). SCREENSHOT PENDING — user will share a
> screenshot of this glitch later (at end of round); attach to R4-006 for the art/dev fix
> pass. Art/overlay-compositing, functional. Build 9, iPad. Factual capture only — not
> classified/routed.)
>
> SCREENSHOT RECEIVED (described; image pasted in chat). Same hearth view with the rug folded
> back (trapdoor floorboards revealed) and the gold ring now in inventory. A large DARK,
> FLAT, TILTED quadrilateral — a detached 'portion of the fireplace/hearth' overlay — floats
> at an angle in front of the fire, overlapping the folded rug and floorboards. Unmistakable
> misregistered-overlay glitch. The upright panel seen in R4-004 is now clearly skewed after
> the rug-move state change. STRONGLY supports the R4-024 root-cause: state overlays/plates
> are being composited at the WRONG transform/position. Likely the SAME bug as R4-004 and the
> R4-024 overlay-transform cluster — group them for one fix.

### R4-007 — status: logged
> ok i see the issue, the under the rug puzzle with the moon phases has an arrow indicator on top, telling me that the moon phase should look correct when the arrow is pointing to the right moonphase. but because it's a dial, it looks a bit wrong visually (i need you to confirm if it's right or wrong). the way i see it, the waxing crescent looks correct, the full moon looks correct, but the waning gibbous looks wrong as when it's in the "correct" unlock position, the dark bite is showing on the left side, not the right as u mentioned
> (context: z1 v-hearth, p02-moon-trapdoor three-dial moon-phase lock (under the rug).
> PRODUCER CONFIRMED WRONG vs spec: per puzzle-graph clu-triptych + p02 (solution
> `waxing-crescent, full, waning-gibbous`; "waxing vs waning are mirrored shapes, exact
> orientation matters"), a WANING GIBBOUS must show the dark bite on the RIGHT (lit on the
> left). The dial in its correct/unlock position renders the dark bite on the LEFT — i.e.
> it is mirror-flipped and reads as a WAXING gibbous. Waxing-crescent and full-moon dial
> shapes look correct; only the waning-gibbous shape is flipped. This is the p02 value for
> the 3-crow painting.
> TWO fix requirements to carry: (a) the dial's waning-gibbous shape must MATCH the
> triptych 3-crow painting AND be astronomically correct (dark-bite-RIGHT), per the
> design's orientation rule (also the color-blind-safety mechanism). VERIFY the triptych
> painting's 3-crow moon too — if the painting is correct but the dial is flipped they're
> inconsistent; if BOTH are flipped the puzzle is still shape-matchable but astronomically
> wrong; either way fix to correct+consistent. (b) AMBIGUITY GUARD: an 8-phase dial should
> carry BOTH a waxing gibbous and a waning gibbous — if the waning one is drawn as a waxing
> gibbous, two dial positions may look identical and the "correct" answer becomes
> ambiguous. Keep them distinct. Art (dial moon-phase silhouette) + verify against
> triptych; possible logic if the solution detent points at the wrong phase. Build 9,
> iPad. Factual capture only — not classified/routed.)
>
> SCREENSHOT RECEIVED (moon-phase dial puzzle at unlock position; pasted in chat). Three
> 8-phase dials, each with a ▼ indicator marking the top/answer position, on a dark
> studded-metal backdrop; inventory = key + gold ring. The MIDDLE dial clearly reads a FULL
> (bright) moon at the arrow — matches the expected middle=full. The LEFT (should be waxing
> crescent) and RIGHT (should be waning gibbous) dials' exact lit-side orientation can't be
> resolved to the pixel from the screenshot; the user's on-device read stands (right dial's
> dark bite on the LEFT = mirrored waning gibbous). FIX ACTION: compare each dial's
> under-arrow shape at full resolution against the triptych paintings AND astronomical
> correctness (waxing crescent lit-on-RIGHT; waning gibbous dark-bite-on-RIGHT); verify the
> outer dials aren't themselves mirrored.

### R4-008 — status: logged
> anyway, i unlocked the cellar, but before going there, i saw the arrow clue on the pot on the desk scene, then i went another right to see the window and the bird and the arrow clue on the window.. there seems to be a transparent weird arrow down watermark atop the tablet that has the arrow down clue, i'll take a screenshot
> (context: a semi-transparent/ghosted "down-arrow" WATERMARK is rendering on top of a
> clue surface that already bears a down-arrow (downward-triangle rune) clue. The
> "down-arrow clues" are the EARTH rune (▽ + numeral III) on the z1 v-study dead flowerpot
> and the WATER rune (▽ + numeral IV) on the z1 v-entry windowsill — user was moving
> between the study (pot) and entry (window+bird) scenes, so it's on one/both of those
> downward-triangle rune surfaces ("tablet"/plaque/sill). Looks like a stray transparent
> duplicate glyph / leftover watermark overlaid on the rune plate. Possibly related to
> canonical rune-glyph stamping (round-3 R3-007) leaving a ghost, or a semi-transparent
> overlay artifact. Screenshot will disambiguate which surface. SCREENSHOT PENDING — user
> will share at end of round; attach to R4-008. Art/overlay-render artifact. Build 9,
> iPad. Factual capture only — not classified/routed.)
>
> SCREENSHOT RECEIVED (z1 v-entry; pasted in chat). Shows the moonlit window (full moon), the
> thorn-door with the carved crow's-beak/skull motif + hanging rusted key, and the caged crow
> on its stand (brass feed cup visible); inventory = key. The WATER rune tablet (downward
> triangle ▽ + numeral IV) sits on the left windowsill. A faint TRANSLUCENT down-pointing
> triangle/arrow watermark is ghosted onto the scene (Producer reads it in the upper-central
> wall area between window and door). LOCATION RESOLUTION (Producer audit): the user's
> verbatim report is authoritative — the ghost ▽ sits "atop the tablet that has the arrow
> down clue" (the windowsill WATER-rune tablet in z1 v-entry). The Producer's screenshot read
> also spotted a possible second faint ▽ in the upper-central wall area. FIX SCOPE: sweep the
> ENTIRE z1 v-entry scene (and its close-ups) for stray semi-transparent ▽/glyph overlays and
> remove them all, rather than fixing one spot — covers both readings without needing further
> user confirmation.

### R4-009 — status: logged
> close up of the bird works fine, but something that could be related to the earlier bug, when selecting the poker from inventory, i can't get a close up of the arrow tablet by the window or the bird head on the door, but using it on the bird cage brings up the wrong close up from the first build, not the stylized 3d one. but at least it allows me to deselect the item from inventory
> (context: z1 v-entry. THREE threads:
> (1) POSITIVE — the normal crow/cage close-up (cu-cage-crow) works fine and shows correct
> build-3 art.
> (2) REINFORCES R4-005 — with the poker armed, tapping the "arrow tablet" (windowsill
> WATER rune ▽+IV clue) and the "bird head on the door" (the crow's-beak/skull motif on
> the thorn-door) does NOT open their close-ups; armed-item state blocks inspection again
> (cross-link to R4-005 game-wide armed-item fix).
> (3) NEW — STALE-ASSET / SHADOW BUG: using the poker ON the bird cage brings up the WRONG
> close-up — an OLD BUILD-1 PAINTERLY image, NOT the stylized-3D (Nano Banana Pro /
> build-3) art. So a stale/shadow cage close-up (likely a distinct "item-used-on-cage" or
> refusal-state close-up asset) is still being loaded instead of the build-3 canonical.
> This is exactly the stale-canonical/shadow class from R2-META-QA / the round-3
> stale-shadow fixes (assert_no_nb_shadow) — apparently one cage close-up variant escaped
> promotion. → Developer (asset staging/shadow audit) + Asset/manifest verify the build-3
> cage-interaction close-up is canonical.
> (4) MINOR — using the poker on the cage DID let the user deselect the poker (another
> ad-hoc deselect path; reinforces R4-005 that deselect is only reachable via certain
> hotspots, not a clear affordance).
> Build 9, iPad. Factual capture only — not classified/routed.)

### R4-010 — status: logged
> now let me get into the cellar, i hear the ugly psh sound, is it the same one i hated from before? if yes, change it, if not, keep it
> (context: entering z3 cellar, user hears the "ugly psh" sound and asks whether it's the
> same hated generic sound from before. PRODUCER NOTE: cannot verify by ear from here. The
> generic "psh" was diagnosed in round 2 as the DEFAULT per-tap sound firing on nearly
> every tap (R2-024) and was slated for game-wide REMOVAL (kill default tap sound; only
> specific events get themed cues; tap feedback stays visual). So a psh still firing on
> cellar entry/taps is very likely the leftover generic sound that escaped removal, OR a
> regression — NOT an intended cue. User's conditional: if same → change it; if genuinely
> a different/intended cue → keep. FIX-PASS ACTION: (a) verify whether the round-2
> default-tap-sound removal actually shipped in build 9; (b) sweep the z3 cellar tap/entry
> sounds; if it's the generic psh, remove it (visual tap feedback only) per the round-2
> sound-audit direction. Audio/functional → Developer. Build 9, iPad. Factual capture
> only — not classified/routed.)

### R4-011 — status: logged
> clicking the mirror in the cellar, i hear a sound. from earlier builds, i know that is supposed to make the mirror reposition so that the moonlight can shine into the hidden place, but i don't see that visually. the mirror stays in place
> (context: z3 v-cellar, p09-mirror-aim (rotate the tilting mirror through its 3 detents to
> route the moonbeam toward the alcove). A sound fires on clicking the mirror, but the
> mirror does NOT visually reposition — it stays in place, so the player gets no visual
> feedback that it moved/aimed (and no way to see it's at detent-3). The art states exist
> (z3-cellar-mirror-d2 / mirror-d3 plates in the beam matrix), so the DEFECT is the game
> not APPLYING/rendering the mirror's detent state on interaction. Same systemic
> "state-visual not refreshed after interaction" family as round-2 R2-013 (trapdoor),
> R2-014 (spoon), R2-018 (astrolabe), R2-022 (barrel) — audio success but no visual state
> change. Functional (state→visual wiring) → Developer; add to the systemic state-refresh
> audit. NOTE it's puzzle-relevant: without visible mirror movement the player can't
> confirm detent-3 for the beam-at-alcove condition (moonbeam-on AND mirror-at-detent-3).
> User relied on prior-build knowledge to know the mirror should move. Build 9, iPad.
> Factual capture only — not classified/routed.)

### R4-012 — status: logged
> there is a drawer in the cellar, when i click it i hear a psh sound, please check if it's the same as before, if it is the psh one i hate, change it, if it's not keep it. clicking the drawer again gives me the spoon. then clicking the drawer one more time gives me a close up of the drawer with the spoon in it, isn't that wrong since i already picked up the spoon and it's in my inventory already?
> (context: z3 v-cellar, root-shelf drawer (itm-spoon). TWO threads:
> (1) PSH SOUND on clicking the drawer — same as R4-010: producer can't verify by ear; per
> round-2 R2-024 the generic "psh" default tap sound was slated for game-wide removal, so a
> psh here is very likely the leftover/regression rather than an intended cue. User's
> conditional: if same → change; if genuinely different/intended → keep. Fix-pass: verify
> the round-2 default-tap-sound removal shipped in build 9 + sweep this drawer's tap sound.
> Cross-ref R4-010.
> (2) STALE "SPOON-IN-DRAWER" STATE — after picking up the spoon (it's now in inventory),
> re-opening the drawer close-up STILL shows the spoon sitting in the drawer. The
> "spoon-taken / empty drawer" state isn't applied. This is the EXACT recurrence of round-2
> R2-014 (spoon persists in drawer after pickup) and the systemic state-visual-not-refreshed
> family (R2-013/15/18/22, and R4-011 mirror) — the art states exist; the game isn't
> rendering the post-pickup state. Functional (state→visual) → Developer; add to the
> systemic state-refresh audit. Build 9, iPad. Factual capture only — not classified/routed.)

### R4-013 — status: logged
> used the poker on the barrel, i got the weight immediately in my inventory, but visually i see it inside the barrel. shouldn't i "pick it up" to add it to my inventory? clicking it again does not pick it up by the way
> (context: z3 v-cellar, p06-barrel-pry (poker on nailed barrel → itm-weight). THREE coupled
> threads:
> (1) AUTO-GRANT vs MANUAL PICKUP — the weight goes straight into inventory on prying, with
> no explicit "pick it up" step. This is the manual-pickup model the user has repeatedly
> asked for (round-2 R2-003 ash ring, R2-020 item lifecycle, R2-023) — items should be
> unveiled, then tapped to collect. Recurs here for the weight. → Developer (manual-pickup/
> lifecycle model, game-wide).
> (2) STALE STATE — after the weight is taken (it's in inventory), the barrel close-up STILL
> shows the weight sitting inside. Same systemic state-visual-not-refreshed family as R2-022
> (barrel showed closed after weight), R2-014 (spoon), R4-011 (mirror), R4-012 (spoon
> drawer). The post-pry "weight-taken / empty barrel" state isn't rendered. → Developer
> state-refresh audit.
> (3) DEAD STALE IMAGE — clicking the still-visible weight again does NOT pick it up; it's a
> non-interactive leftover image (consistent with it already being auto-granted + the state
> not refreshing). Reinforces (1)+(2).
> Build 9, iPad. Factual capture only — not classified/routed.)

### R4-014 — status: logged
> i'm trying to use the weight on the lever, it didn't work, and since i have the weight selected, i was kind of locked in, so i used the bottom arrow to go back to the first scene, i still have the weight selected, let me touch the caged bird to unselect it
> (context: z3 v-cellar, p07-shelf-counterweight (hang itm-weight on the pulley hook to
> slide the shelf and reveal the z4 alcove). TWO threads:
> (1) POSSIBLE FUNCTIONAL BUG / POSSIBLE PROGRESSION-BLOCKER — using the weight on the
> lever/hook "didn't work" (the interaction didn't register / p07 didn't trigger) on this
> attempt. p07 unlocks z4-alcove (moonflower + cage key), so if weight-on-hook genuinely
> fails a player is BLOCKED from the alcove. NEEDS INVESTIGATION: is this a real p07 failure
> in build 9, or a symptom of the armed-item interaction bug (R4-005) / a hotspot-hit-target
> miss on the hook? User hadn't retried yet at time of report. → Developer, verify p07
> weight-on-hook works end-to-end; treat as candidate-critical until confirmed.
> (2) REINFORCES R4-005 (armed-item traps player) with a DIFFERENT item (the weight) —
> validates the "applies to ALL inventory items" scope note: with the weight armed the user
> was "locked in," couldn't easily deselect, navigated back to z1 still holding it, and had
> to touch the caged crow (the known ad-hoc deselect path) to disarm. Same
> no-discoverable-deselect problem. Cross-ref R4-005, R4-009.
> Build 9, iPad. Factual capture only — not classified/routed.)
>
> RESOLVED-AS-HOTSPOT by R4-023: p07 weight-on-hook is functional; the earlier "didn't work"
> was a mis-calibrated hotspot, not a p07 logic failure or hard block. Downgrade from
> candidate-critical to a hotspot-calibration bug (still needs fixing).

### R4-015 — status: logged
> ok after doing that i thought i'll just open the arrow glyph door. i entered the right pattern and could hear that the door unlocked, but i don't see visually that it got unlocked.
> (context: z1 v-study, p01-rune-door (the "arrow glyph"/element-rune press-lock that
> unlocks the z2 workshop). POSITIVE embedded: p01 is now SOLVABLE (correct pattern
> accepted, unlock sound fires) — this confirms the build-9 canonical-rune-glyph fix
> (round-3 R3-007) worked; the round-3 p01 block is cleared. DEFECT: after solving, the
> door does NOT visually show as unlocked/open — audio success but no visual state change.
> Exact recurrence of round-2 R2-015 (rune-door open not shown after solve) and the
> systemic state-visual-not-refreshed family (R2-013 trapdoor, R4-011 mirror, R4-012 spoon,
> R4-013 barrel). May also need an "open/ajar rune-door" art state if one wasn't generated
> (R2-015 flagged verifying/adding it). Functional (state→visual) → Developer state-refresh
> audit; verify the open-door plate exists in build-3 art. Build 9, iPad. Factual capture
> only — not classified/routed.)

### R4-016 — status: logged
> now, i tried to go into the potion door by clicking the door but that doesn't work, it seems the hotspot for that is limited to the arrow puzzle  itself. i need to click the arrow puzzle again to go into the potion room. u need to fix that to cover the entire door
> (context: z1 v-study, the workshop ("potion") door that p01-rune-door unlocks (entry to
> z2 workshop). After solving p01, the ENTER-WORKSHOP transition hotspot is limited to the
> small rune/"arrow" press-plate panel only — clicking the door itself does nothing; the
> user must tap the arrow-puzzle panel AGAIN to go through. User directive: the entry
> hotspot must cover the ENTIRE door once unlocked, not just the puzzle panel. Functional/
> hotspot-geometry + navigation → Developer: after p01 is solved, make the whole door a
> "go to z2" hotspot (and it should read as an open/enterable door — ties to R4-015 where
> the door doesn't visually show unlocked). Build 9, iPad. Factual capture only — not
> classified/routed.)

### R4-017 — status: logged
> also clicking the puzzle itself to get into the potion room has that psh sound
> (context: z1 v-study → z2 workshop transition. Tapping the rune-puzzle panel to ENTER the
> potion/workshop room plays the generic "psh" sound. Same class as R4-010/R4-012 and
> round-2 R2-024 (the generic default tap/navigation sound that was slated for game-wide
> removal — visual tap feedback only, no default sound; specific events get themed cues).
> This is another surviving instance, here on a scene-transition/entry tap. Fix-pass: part
> of the same sound audit — remove the default psh on this entry tap; if a transition cue
> is wanted it should be a themed one, not the generic psh. Cross-ref R4-010, R4-012,
> R4-016. Audio/functional → Developer. Build 9, iPad. Factual capture only — not
> classified/routed.)

### R4-018 — status: logged
> i could get a close up of the mortar and the bowl on the table, let me go right to see the orion's belt puzzle. i see the potion shelf, the window with the star placement, the cabinet and the astrolobe. i solved the astrolobe using orion's belt clue, but upon unlock i see it's using the older build none-stylized 3d image. i could pick up the tool and the crescent coin from it, but the close up is definately wrong
> (context: z2 v-cabinet, p03-astrolabe-orion. Threads:
> (1) POSITIVE — mortar/bowl close-ups work; p03 solved correctly via the Orion's-belt clue;
> AND the drawer items (itm-crank "tool" + itm-silver-coin "crescent coin") ARE now
> collectible. This is a MAJOR improvement over round-2 R2-018/019/025 where the
> p03-resolved close-up rendered as an empty grey box and items were invisible/uncollectible
> (the critical soft-lock) — that soft-lock appears RESOLVED in build 9 (verify).
> (2) DEFECT — STALE close-up art: the p03-RESOLVED astrolabe/drawer close-up shows the
> OLDER build (non-stylized, painterly build-1/2) image, not the build-3 stylized-3D art.
> Same stale-asset/shadow class as R4-009 (poker-on-cage stale close-up) and the round-3
> stale-shadow sweep (assert_no_nb_shadow) — another resolved-state/interaction close-up
> that escaped build-3 promotion. → Developer asset-staging/shadow audit + Asset/manifest:
> confirm the build-3 p03-resolved astrolabe/drawer close-up is the canonical staged file.
> PATTERN NOTE: two stale interaction/resolved close-ups now found (cage R4-009 + astrolabe
> R4-018) — the shadow sweep likely missed a whole class of resolved-state close-ups; audit
> ALL of them. Build 9, iPad. Factual capture only — not classified/routed.)

### R4-019 — status: logged 🔴 CRITICAL (soft-lock / progression-blocker)
> oh i found a major bug. as i kept restarting the game to reproduce issues, this time i forgot to use the poker on the ash pile to get the ring.. i simply used the poker on the barrel in the cellar, and it got depleted and removed from inventory. now i can't solve the cabinet puzzle with the gold ring.. i'll have to reset progress and start over to continue testing, but in its current state the game is unsolvable
> (context: 🔴 CRITICAL SOFT-LOCK. The iron poker (itm-poker) has TWO uses per puzzle-graph:
> p05-ash-sift (→ itm-gold-ring) AND p06-barrel-pry (→ itm-weight). The user used the poker
> on the BARREL (p06) FIRST, without having sifted the ash (p05); the poker was then
> DEPLETED and REMOVED from inventory after that single use. With the poker gone, p05 can no
> longer be done → no gold ring → p04-cabinet-sun-moon cannot be solved → the level is
> UNSOLVABLE from that save. User must reset progress to continue.
> ROOT CAUSE: botched item-lifecycle logic (round-2 R2-020). R2-020's rule was: a PLACED/
> consumed item is removed, but a multi-use TOOL is RETAINED until ALL its uses are depleted
> (explicitly: "poker = p05 ash + p06 barrel"). The build removes the poker after its FIRST
> use instead of after ALL `uses` are satisfied. This directly VIOLATES the puzzle-graph
> anti_softlock_invariants ("itm-poker ... reusable and never consumed"; "never remove an
> item before every one of its uses is done").
> REACHABILITY: normal play — the design allows multiple valid solve orders (poker-on-barrel-
> before-ash is a legal path, e.g. cellar-first orderings), so a real player hits this
> without doing anything unusual. Not an edge case.
> FIX: retain any multi-use tool until EVERY entry in its graph `uses` array is satisfied
> (general fix, driven by the graph). Poker must survive until BOTH p05 and p06 are done.
> Audit all multi-use items for the same. → Developer (implement) + Puzzle Logic Validator
> (confirm no softlock reintroduced) + QA regression: add alternate-ordering tests, incl.
> p06-before-p05, that assert the level stays completable (ties to R2-META-QA — automated
> tests missed this because scripted playthroughs used one order). Build 9, iPad. Factual
> capture only — not classified/routed.)

### R4-020 — status: logged
> after restarting, i tried to put the crescent coin in the right place in the cabinet close up, i heard a sound that sounded like it wasn't working. i tried a few times... the coin stayed in my inventory. i decided that it could be a bug and tried to put the gold ring in its place, this time the cabinet unlocked, both items got depleted and removed from my inventory, and i could see the none stylized 3d close up of the open cabinet with an empty bottle and a knife/shaver thing. picking up those
> (context: z2 v-cabinet, p04-cabinet-sun-moon (place itm-gold-ring in the sun slot +
> itm-silver-coin "crescent coin" in the moon slot → cabinet opens → yields itm-file
> "knife/shaver" + itm-phial "empty bottle"). FOUR threads:
> (1) CONFUSING/MISLEADING PLACEMENT FEEDBACK — placing the crescent coin in its (correct)
> moon slot first produced a sound "like it wasn't working" and the coin appeared to STAY in
> inventory (no visible seated-coin feedback), so the user thought it failed and retried
> several times. Only after placing the gold ring did the cabinet unlock and BOTH items get
> consumed together. NEEDS INVESTIGATION: was the coin actually seating with NO positive
> visual/audio feedback (state-visual/audio feedback bug on a correct partial placement),
> and/or is a NEGATIVE-sounding cue playing on a correct placement? Also possible
> clue-gating (rev 1.3, p04 requires slot/page-B clue viewed) interacting confusingly.
> Either way: placing a correct item into a two-slot puzzle must give clear positive
> per-slot feedback (item visibly seats + correct sound), not a "not working" sound + item
> apparently still in inventory. → Developer (per-slot placement feedback + verify
> partial-placement state) + verify against clue-gating.
> (2) STALE CLOSE-UP — the resolved OPEN-cabinet close-up shows non-stylized-3D (old build)
> art, NOT build-3 stylized. THIRD stale resolved/interaction close-up this round (cage
> R4-009, astrolabe R4-018, now cabinet R4-020) — confirms a whole class of resolved-state
> close-ups escaped build-3 shadow-promotion. → Developer asset-staging/shadow audit +
> manifest verify.
> (3) POSITIVE + LIFECYCLE-CORRECT — file+phial ARE collectible from the open cabinet
> (improvement over round-2 R2-026 grey-box soft-lock; verify resolved). And ring+coin being
> CONSUMED on placement here is the CORRECT lifecycle (they're single-use PLACED items now
> sitting in the slots) — do NOT confuse with the R4-019 poker bug (that was a multi-use
> TOOL wrongly consumed after one of two uses). Preserve this distinction for processing.
> (4) POST-PICKUP STATE NOT REFRESHED — after collecting the file + phial from the open
> cabinet, they are NOT removed from the cabinet close-up visual; they stay shown even though
> they're now in inventory. Same systemic state-visual-not-refreshed family as R4-012 (spoon
> drawer), R4-013 (barrel weight), R2-014. User expects: once picked up, the item disappears
> from the scene and the cabinet shows an emptied state — and expects this handled together
> with swapping in the correct build-3 stylized close-up (thread 2). → Developer state-refresh
> audit, in the same fix as the stale-art swap for this close-up.
> Build 9, iPad. Factual capture only — not classified/routed.)

### R4-021 — intentionally not used
> R4-021 intentionally not used — that observation (file/phial remain in the cabinet visual
> after pickup) was folded into R4-020 as thread (4). No item was dropped; numbering resumes
> at R4-022.

### R4-022 — status: logged
> going back to the scene, the visual shows the cabinet door closed although i just unlocked it. it also shows a weird additional part of the sun door, i'll show u a screenshot
> (context: z2 v-cabinet WIDE scene, after solving p04 (cabinet opened in the close-up). TWO
> threads:
> (1) STATE-VISUAL NOT REFRESHED (wide view) — returning to the wide cabinet scene shows the
> cabinet door still CLOSED even though it was just unlocked/opened. Same systemic
> state-visual-not-refreshed family as R4-015 (rune door), R2-013 (trapdoor), etc.,
> specifically the WIDE-view state not reflecting a solved puzzle. → Developer state-refresh
> audit (ensure solves update the wide view, not just the close-up).
> (2) OVERLAY ARTIFACT — a "weird additional part of the sun door" is visible in the wide
> scene: a misplaced/duplicated overlay fragment around the sun-slot door. Same
> overlay-misregistration/wrong-overlay family as R4-004 (poker patch) and R4-006 (rug/
> fireplace). Likely a seated-item or open-state overlay compositing at the wrong position/
> z-order over the sun slot. SCREENSHOT PENDING — user will share at end of round; attach to
> R4-022. → Developer/Art overlay-compositing.
> Build 9, iPad. (Screenshot-pending tally now: R4-004, R4-006, R4-007, R4-008, R4-022.)
> Factual capture only — not classified/routed.)
>
> SCREENSHOT RECEIVED (z2 v-cabinet wide; pasted in chat). CONFIRMS BOTH THREADS. (1) The
> sun/moon cabinet shows its doors CLOSED (left door = sun carving, right door = crescent-moon
> carving) although p04 is SOLVED — inventory shows the file + phial (p04 yield) plus crank/
> spoon/weight — so the wide view isn't reflecting the opened state (wide-view state-refresh).
> (2) EXTRA SUN-DOOR ARTIFACT: an additional wooden door panel bearing a SUN carving juts out,
> MISALIGNED, on the LEFT edge of the cabinet — a duplicated/misplaced door overlay offset
> from the cabinet body. Clear overlay-misregistration, same transform/position class as
> R4-004/R4-006/R4-024 — group with the overlay-transform cluster.

### R4-023 — status: logged
> i'll go back to the cellar. i guess i get to use the crank on the lever and could see the moonlight. i know i need to use the weight on the hook, but the hotspot is wrong again. i randomly clicked on the scene and was able to fight the hotspot to proceed, but u need to fix that
> (context: z3 v-cellar. TWO threads:
> (1) POSITIVE — using the crank on the winch (p08-shutter-winch) worked and the moonlight/
> beam appeared.
> (2) HOTSPOT BUG — the weight-on-hook interaction (p07-shelf-counterweight) has a WRONG/
> mispositioned hotspot: the user couldn't hit it normally and had to randomly click around
> ("fight the hotspot") to trigger it, then it proceeded. So p07 IS functional — the
> item-on-hook works once the correct spot is hit — but the hook hotspot is mis-calibrated /
> hard to find. This RESOLVES the R4-014 ambiguity: R4-014's "weight on the lever didn't
> work" was this same hotspot problem, NOT a p07 logic failure or a hard progression-block.
> → Developer: re-calibrate the p07 hook hotspot to the visible hook position/size (proper
> hit-target). Ties to R3-005 hotspot re-calibration (a gap remained in build 9) and R4-016
> (workshop-door hotspot too small) — recurring hotspot-geometry issue; worth a general
> hit-target audit across interactive elements.
> Build 9, iPad. Factual capture only — not classified/routed.)

### R4-024 — status: logged
> as i said earlier, clicking the mirror i hear a sound so i know it does something, albeit the visual must be fixed. in addition. i'll  share three screenshots showing how clicking the mirror changes how the barrel appears (sometiemes with weight in, sometimes without)
> (context: z3 v-cellar. TWO threads:
> (1) Reconfirms R4-011 — clicking the mirror (p09) plays a sound (something happens) but the
> mirror's own visual state doesn't update; visual must be fixed. Cross-ref R4-011.
> (2) NEW — CROSS-STATE CONTAMINATION: clicking the mirror ALSO changes how the BARREL
> appears, flipping it between weight-in and weight-out states. So a mirror interaction is
> altering an unrelated element's (barrel's) rendered state. LIKELY ROOT CAUSE (producer
> analysis, for the fix pass): the cellar is a single wide view rendered via
> MUTUALLY-EXCLUSIVE FULL-PLATE variants (mirror-d2/d3, barrel-pried, beam, etc.), where each
> full plate bakes in a fixed snapshot of every other element — so swapping to a "mirror"
> plate also reverts the barrel to whatever state that plate was rendered with. This is the
> architectural driver behind the whole round-4 state-refresh cluster (R4-011/12/13/15/22):
> full-plate swaps can't hold independent per-element states. FIX DIRECTION: render each
> element's state as an INDEPENDENT overlay composited on ONE base (the manifest already has
> per-element overlays: ov-barrel-*, ov-mirror-*, ov-drawer-*, etc.), rather than
> mutually-exclusive full plates — so changing one element never resets another. → Developer
> (state/overlay architecture) — flag as the probable common root of the state-refresh
> cluster. THREE SCREENSHOTS PENDING (mirror-click changing barrel appearance) — user shares
> at end of round; attach to R4-024.
> Build 9, iPad. (Screenshot-pending tally now: R4-004, R4-006, R4-007, R4-008, R4-022,
> R4-024[x3].) Factual capture only — not classified/routed.)
>
> SCREENSHOT RECEIVED — 3 images (pasted in chat), z3 cellar wide, inventory = file + phial +
> spoon. Sequence = successive mirror clicks. KEY OBSERVATIONS: (a) the MIRROR (left) is
> IDENTICAL in position/appearance across all 3 shots — it never visually rotates despite the
> click/sound (confirms R4-011). (b) the BARREL (right) TOGGLES state with each mirror click:
> shot 1 = open with the iron WEIGHT sitting inside; shot 2 = open but EMPTY; shot 3 = WEIGHT
> back inside. The user already took that weight earlier (R4-013), so the barrel should stay
> empty — instead it flip-flops as an unrelated element (the mirror) is clicked. (c) the
> MOONBEAM glow-blob also JUMPS position between shots — low on the floor by the mirror in
> shots 1 & 2, then up onto the sliding-shelf panel in shot 3. DIAGNOSIS (strongly supported):
> the cellar wide view is rendered via MUTUALLY-EXCLUSIVE WHOLE-SCENE PLATE SWAPS, and each
> mirror-state plate was baked with a DIFFERENT barrel state and beam position — so a mirror
> click swaps the entire plate, dragging the barrel + beam along, while the mirror sprite
> itself is never updated. This is the common root of the round-4 state-refresh cluster
> (R4-011/12/13/15/22) AND the overlay-transform cluster (R4-004/06/22). FIX: composite
> INDEPENDENT per-element overlays (ov-mirror-*, ov-barrel-*, ov-beam/moonbeam, etc.) on ONE
> stable base, driven by each element's own state — never full-plate swaps that co-mingle
> unrelated element states. Group R4-024 as the anchor item for this architectural fix.

### R4-025 — status: logged
> the hotspot to go into the alcove is also wrong. i clicked randomly to get in
> (context: z3 v-cellar → z4 alcove entry (after p07 slides the shelf aside, revealing the
> alcove passage). The ENTER-ALCOVE hotspot is mispositioned/hard to hit — the user had to
> click randomly to trigger the transition. THIRD hotspot-geometry miss this round: R4-016
> (workshop-door entry hotspot too small), R4-023 (p07 weight-on-hook hotspot), and now
> R4-025 (alcove entry). Confirms a recurring hit-target calibration problem in build 9
> despite R3-005's hotspot re-calibration — the transition/entry hotspots especially seem
> off. → Developer: fix the alcove-entry hotspot to cover the visible passage, AND do a
> GENERAL hit-target audit across all interactive elements + scene-entry hotspots (elevate
> from per-item fixes to a systematic pass). Cross-ref R4-016, R4-023. Build 9, iPad. Factual
> capture only — not classified/routed.)

### R4-026 — status: logged
> got the key from the bird's mouth, but i don't see the value of the close up now. shouldn't i be able to pick up the key from the close up?
> (context: z4 v-alcove, the carved crow statue holding itm-cage-key (star-bit key) in its
> beak; cu-statue-key close-up. The key appears to have been AUTO-GRANTED (obtained without
> an explicit pickup from the close-up), so the statue close-up now feels valueless. User
> expectation: open the statue close-up → see the key in the beak → TAP the key to pick it up
> (manual pickup from the close-up). Same manual-pickup model the user keeps asking for
> (R2-003 ash ring, R2-020 lifecycle, R4-013 barrel weight) — items should be collected via
> an explicit tap, ideally from their close-up. Also ties to the depleted/pointless-close-up
> concern (R2-022 spent barrel, R2-027 spent flowerpot) — once the key is taken the statue
> close-up shouldn't keep inviting a zoom with nothing to do; it should show key-taken
> (state-refresh). → Developer: make the statue key a manual pickup from the close-up, and
> reflect key-taken afterward. Build 9, iPad. Factual capture only — not classified/routed.)

### R4-027 — status: logged
> i took the moonflower, hitting the bottom arrow to go back nto the cellar i hear the psh sound. hitting the down arrow to go back upstairs also i hear the psh sound
> (context: z4 alcove. POSITIVE: took the moonflower (p10-moonflower-bloom → itm-blossom
> worked). DEFECT: the navigation "back/down" chevrons play the generic "psh" sound — both
> the arrow back to the cellar and the down arrow back upstairs. Another surviving instance
> of the default tap/navigation sound (round-2 R2-024: the generic psh fires on nav/back
> chevrons; slated for game-wide removal — visual feedback only, no default sound).
> Reinforces that the psh is still firing on NAVIGATION specifically. Part of the same sound
> audit as R4-010, R4-012, R4-017. → Developer sound audit (remove default psh on nav
> chevrons; themed cue only if desired). Build 9, iPad. Factual capture only — not
> classified/routed.)

### R4-028 — status: logged
> i put the moonflower in the bowl in the potion room. and i used the key on the caged bird to free it, the close up shows the none stylized free bird again
> (context: TWO threads:
> (1) POSITIVE — put the moonflower in the mortar/bowl in the workshop (p13-grind-paste,
> blossom → paste) worked; and freed the caged crow with the star-bit key (p11-cage-unlock)
> worked.
> (2) DEFECT — STALE close-up art: the freed-bird / cage-open (crow-on-rafters) close-up
> shows the OLD non-stylized (build-1/2 painterly) art, NOT build-3 stylized-3D. FOURTH stale
> interaction/resolved close-up this round — after cage/poker-on-cage (R4-009), astrolabe
> (R4-018), cabinet (R4-020). Strongly confirms a whole CLASS of resolved-state/interaction
> close-ups escaped build-3 shadow-promotion. → Developer asset-staging/shadow audit +
> Asset/manifest: sweep and verify EVERY resolved-state / post-interaction close-up
> (cage-open, astrolabe-resolved, cabinet-open, freed-bird, etc.) is the build-3 canonical,
> not a stale shadow. Build 9, iPad. Factual capture only — not classified/routed.)

### R4-029 — status: logged
> i used to the shaver on the spoon from my inventory. that was a hard one by the way, my clue was the little "link" icon that shows on top the spoon in inventory when clicking the shaver. is that the best way to do it?
> (context: p12-file-shavings (combine itm-file "shaver" + itm-spoon → itm-shavings). The
> combine WORKED but was hard to discover. Current implemented affordance: selecting/clicking
> the shaver (file) shows a small "link" icon over the combinable inventory item (the spoon);
> tapping it performs the combine. User found this undiscoverable ("that was a hard one") and
> asks whether it's the best approach — inviting a better/clearer combine UX. Directly
> continues round-2 R2-028 (item-combining isn't intuitive; user explicitly invited a
> solution). It works, so this is UX/polish (feature-refinement), not a bug. → Developer/UX;
> Producer to weigh combine-UX options at processing (e.g. clearer affordance, a combine tray
> in the enlarged inventory, a first-time hint) and surface to the user rather than deciding
> unilaterally. Keep consistent with the select-then-tap model. Build 9, iPad. Factual
> capture only — not classified/routed.)

### R4-030 — status: logged
> ok i put the feather, moonflower paste and the shaved silver into the bowl, pumped to 3 and stirred 5 times, released laddle, and used the empty bottle to get the moonwater. i noticed that spoon and shaver are still in my inventory, not depleted
> (context: POSITIVE — the brew worked: feather + moonflower paste + silver shavings into the
> cauldron, flame stage 3, 5 stirs, release ladle (p14-brew), then bottled the moonwater with
> the empty phial (p15-fill-phial). Level is near-complete.
> BUG — item lifecycle: itm-spoon and itm-file ("shaver") are STILL in inventory though both
> are single-use (graph `uses`: both only p12-file-shavings) and p12 is long done (the
> draught now exists). Per the user's R2-020 lifecycle rule, an item with no remaining uses
> should be REMOVED (consumed). They aren't. This is the FLIP SIDE of the R4-019 poker
> soft-lock: R4-019 = a multi-use tool removed TOO EARLY (after 1 of 2 uses); R4-030 =
> single-use items NOT removed after their only use. So the lifecycle logic is wrong in BOTH
> directions and the SAME unified fix resolves both — "retain an item while ANY entry in its
> graph `uses` array is still unsatisfied; remove it once ALL are satisfied." → Developer
> (same item-lifecycle fix as R4-019); cross-ref R4-019, R2-020. Build 9, iPad. Factual
> capture only — not classified/routed.)

_(Note: items R4-026 through R4-030 were briefly mis-ordered in this file — inserted between
R4-019 and R4-020 due to an editing-anchor slip — and have been moved here to restore
received-order. Content unchanged.)_

### R4-completion — status: logged (LEVEL COMPLETED end-to-end on build 9)
> "i'm free now" — user completed Level 1 end-to-end on build 9: after R4-030 (brew +
> bottling), they poured the moonwater at the thorn-door basin, the door unlocked, and they
> escaped. (context: build 9 is FULLY SOLVABLE end-to-end when played in the standard order —
> p01 through p17 all function, including the previously-blocking p01 glyphs (R4-015
> positive) and the previously soft-locking p03 drawer items (R4-018 positive). The round's
> defects are overwhelmingly PRESENTATION/LIFECYCLE layer (plate-swap state contamination,
> stale close-up art, default psh sound, hotspot geometry, item lifecycle) — with ONE
> critical logic exception: the R4-019 poker-lifecycle soft-lock, which strands
> alternate-order playthroughs. No door-pour/endgame issues were reported this round, unlike
> round 2. This mirrors the R2-completion pattern: solid puzzle logic, presentation debt.)

---
## ROUND 4 — PROCESSED 2026-07-11 (routed changelist — pending user CHECKPOINT-1 approval + 1 design call + merge confirmations)

**Framing:** build 9 is completable end-to-end in the standard order (R4-completion); puzzle
LOGIC is sound with ONE critical exception (R4-019 lifecycle soft-lock on alternate
orderings). Everything else is presentation/lifecycle-layer debt that consolidates into six
root clusters + singles. Several round-2 fixes have RE-APPEARED (psh sound, state refresh,
manual pickup) — see the standing Regression-Verification Directive below.

### Classification (every item, one-line rationale)

| Item | Class | Sev | Rationale | Cluster |
|---|---|---|---|---|
| R4-001 | bug | minor | Level Select label renders "1" not "Level 1" — violates explicit prior instruction (R3-003 fix incomplete); cosmetic, no progression impact | single |
| R4-002 | bug | minor | Residual ocean-waves loop fires at level entry before music — R2-004/005 removal incomplete; audio-only | audio (rides with D) |
| R4-003 | polish | — | Harsh "tick" on pause-menu selection; user wants the liked Level-Select ping standardized across all menu chrome — refinement of working sounds | D (menu) |
| R4-004 | bug | major | Poker-taken hearth overlay composited misaligned — scene visibly broken on the critical path; screenshot confirms misregistered overlay | B |
| R4-005 | bug | major | Armed inventory item has no discoverable deselect AND blocks all other close-ups — game-wide interaction-model defect that traps and hinders the player | F (anchor) |
| R4-006 | bug | major | Detached, tilted hearth-overlay fragment floats over the folded rug — screenshot-confirmed misregistered overlay, same class as R4-004 | B |
| R4-007 | bug | major | p02 waning-gibbous dial silhouette mirror-flipped vs spec (dark bite LEFT, must be RIGHT) — corrupts a puzzle clue's correctness; solvable but misleading + ambiguity risk | single (art+verify) |
| R4-008 | bug | minor | Stray semi-transparent ▽ ghost overlay on/near the windowsill WATER-rune clue tablet — cosmetic but clue-adjacent; sweep whole v-entry scene | B (verify if baked art) |
| R4-009 | bug | minor | (net new thread) poker-on-cage opens an OLD build-1 close-up — stale/shadow asset escaped build-3 promotion; threads (2)+(4) reinforce R4-005 | C; (2),(4)→merge F |
| R4-010 | bug | minor | Generic psh on cellar entry — near-certain survivor of the R2-024 default-tap-sound removal; conditional resolved by code check (see flags) | D (anchor) |
| R4-011 | bug | major | Mirror (p09) never visually moves across detents — puzzle-relevant feedback missing; player can't confirm detent-3; screenshots confirm | B |
| R4-012 | bug | major | (2) drawer close-up still shows spoon after pickup — exact R2-014 recurrence, state not re-rendered; (1) psh → cluster D | B; (1)→D |
| R4-013 | bug | major | (1) weight auto-granted, no manual pickup (violates agreed R2-020 model); (2)+(3) barrel still shows dead, untappable weight — state not re-rendered | A(1); B(2,3) |
| R4-014 | bug | major | Weight-on-hook read as broken — RESOLVED-AS-HOTSPOT by R4-023 (mis-calibrated hit-target, not p07 logic); (2) armed-weight trap reinforces R4-005 | (1)→merge E; (2)→merge F |
| R4-015 | bug | major | p01 door gives audio-only unlock, no visual state change — R2-015 recurrence on the critical path; wayfinding-load-bearing | B |
| R4-016 | bug | major | Enter-workshop hotspot covers only the small puzzle panel, not the unlocked door — navigation friction on the critical path | E |
| R4-017 | bug | minor | Generic psh on the workshop-entry tap — another default-tap-sound survivor | D |
| R4-018 | bug | minor | p03-resolved astrolabe close-up is stale build-1/2 art (items ARE collectible — round-2 soft-lock resolved); style-consistency defect | C |
| R4-019 | bug | **critical** | Poker (multi-use: p05+p06) consumed after FIRST use → barrel-before-ash strands the gold ring → level unsolvable; violates anti_softlock_invariants; reachable in normal play | A (anchor) |
| R4-020 | bug | major | (1) correct coin placement gives failure-sounding cue + no seated visual → user believes it failed; (2) stale open-cabinet close-up → C; (4) file/phial persist in visual after pickup → B; (3) positive | single(1); C(2); B(4) |
| R4-022 | bug | major | (1) wide view shows cabinet closed after p04 solve — wide-view state refresh; (2) duplicated, misaligned sun-door overlay — screenshot-confirmed | B (both) |
| R4-023 | bug | major | p07 hook hotspot mispositioned — user had to "fight the hotspot"; nearly read as a progression block (see R4-014) | E |
| R4-024 | bug | **major (systemic root)** | Mirror clicks flip the BARREL's state and jump the moonbeam — screenshot-proven cross-state contamination from mutually-exclusive full-plate swaps; common root of cluster B's symptoms | B (ANCHOR) |
| R4-025 | bug | major | Alcove-entry hotspot mispositioned — third hit-target miss this round; systemic calibration problem | E |
| R4-026 | bug | minor | Statue key auto-granted instead of tapped from close-up — inconsistent application of the agreed manual-pickup/lifecycle model (R2-020); no design conflict (confirmed below) | A (manual-pickup) |
| R4-027 | bug | minor | Generic psh on nav/back chevrons (two instances) — default-tap-sound survivor on navigation | D |
| R4-028 | bug | minor | Freed-bird close-up is stale build-1/2 art — FOURTH stale resolved-state close-up; confirms a missed asset class | C |
| R4-029 | polish (feature-refinement) | — | Combine works but the "link"-icon affordance is undiscoverable; user asks for a better way — needs a USER OPTION PICK, not a unilateral call | flag → user |
| R4-030 | bug | major | Spoon+file (single-use, p12 done) never consumed — lifecycle engine wrong in the OPPOSITE direction from R4-019; same unified fix | A |
| R4-completion | informational | — | Level completed end-to-end on build 9; positive confirmations for p01 glyphs, p03 collectibility, p08–p17 chain | — |

### Root-cause clusters (validated against the Producer's audit — adopted with corrections)

The Producer's seven-cluster read is broadly CORRECT. My corrections: (i) the
"overlay-transform" artifacts (R4-004/006/008/022(2)) and the "state-refresh" failures
(R4-011/012(2)/013(2,3)/015/020(4)/022(1)) are ONE cluster (B) under the R4-024 plate-swap
root — the 3-screenshot sequence proves both symptom families come from whole-scene plates/
overlays being selected or composited wrongly; (ii) the manual-pickup items (R4-013(1),
R4-026) belong WITH the lifecycle engine (A) as one Developer work package — same
inventory-engine code; (iii) R4-002 is NOT part of the psh cluster (it's a lingering
ambient loop, not the default tap sound) — batched with the audio work but tracked
separately; (iv) R4-008 stays in B provisionally — if the ghost ▽ turns out to be baked
into the plate art (not an overlay), it re-routes to Asset Generation for re-stamp/inpaint.

- **A — Inventory lifecycle & pickup engine** (R4-019 🔴 anchor, R4-030, R4-013(1),
  R4-026): ONE rule fixes both directions — *retain an item while ANY entry in its graph
  `uses` array is unsatisfied; remove it once ALL are satisfied* — plus the manual-pickup
  step (reveal → tap to collect) applied uniformly (weight, statue key; ash-ring already
  has it).
- **B — Scene-state rendering architecture** (R4-024 anchor; R4-004, R4-006, R4-008?,
  R4-011, R4-012(2), R4-013(2,3), R4-015, R4-020(4), R4-022): replace mutually-exclusive
  full-plate swaps with INDEPENDENT per-element overlays (ov-mirror-*, ov-barrel-*,
  ov-poker-taken, ov-trapdoor-*, ov-beam, door-open, cabinet-open, ...) composited on ONE
  stable base per view, each driven solely by its element's own state. **Art scoping:**
  the manifest already carries per-element ov-* overlays for barrel/mirror/drawer/trapdoor
  states — Developer INVENTORIES coverage first; only genuinely missing overlays (e.g. an
  open rune-door state, seated-slot fragments, beam positions if plate-baked) go to Asset
  Generation as derived crops from EXISTING build-3 plates (cheap; no new scene
  generations expected). The misregistration half of the bug = fix overlay TRANSFORMS
  (position/scale/z-order) in the same compositor work.
- **C — Stale resolved-state close-ups** (R4-009(3), R4-018, R4-020(2), R4-028): a whole
  CLASS of post-interaction/resolved close-ups still loads build-1/2 art. Developer
  staging audit + asset-manifest verification; EXTEND the `assert_no_nb_shadow` CI guard
  to interaction-triggered and resolved-state close-ups (the round-3 guard demonstrably
  didn't reach this class).
- **D — Default-tap "psh" completion audit** (R4-010 anchor, R4-012(1), R4-017, R4-027;
  + R4-003 menu-ping polish; R4-002 rides along): the R2-024 root fix (kill the default
  tap sound; event-specific themed cues only) either regressed or never fully shipped —
  verify at code level, then sweep ALL triggers. Menu chrome: standardize the liked
  Level-Select ping across Main Menu / Level Select / Pause / Settings.
- **E — Hotspot / hit-target calibration** (R4-016, R4-023 [absorbs R4-014(1)], R4-025):
  systematic hit-target audit of ALL interactive elements AND scene-entry/transition
  hotspots against the build-3 plates (R3-005 left gaps); entry hotspots must cover the
  full visible affordance (whole door, whole passage, visible hook).
- **F — Armed-item interaction model** (R4-005 anchor [absorbs R4-009(2), R4-014(2)]):
  game-wide per the user's scope directive — (1) always-available, obvious deselect (tap
  armed item again / tap empty space / explicit ✕); (2) an armed item must NOT block
  close-ups — a tap on a non-target opens its close-up as normal, item stays armed (per
  R2-030); failed uses keep the item armed.
- **Singles:** R4-001 (Level-1 label), R4-002 (ocean residue), R4-007 (moon-dial
  mirror-flip + triptych verify + 8-phase waxing/waning distinctness), R4-020(1)
  (per-slot placement feedback), R4-029 (combine UX — user decision).

### Merge proposals — CONFIRM AT CHECKPOINT, not silently applied

| Proposal | Keep | Merge in | Basis |
|---|---|---|---|
| M-1 | R4-005 | R4-009 thread (2), R4-014 thread (2) | same armed-item defect, different items/scenes |
| M-2 | R4-023 | R4-014 thread (1) | R4-023 proved the "failure" was the hook hotspot |
| M-3 | R4-019 | R4-030 (as flip-side evidence) | one lifecycle engine, one unified fix |
| M-4 | R4-024 | R4-004, R4-006, R4-011, R4-012(2), R4-013(2,3), R4-015, R4-022 as symptoms | screenshot-proven common plate-swap root |
| M-5 | R4-010 | R4-012(1), R4-017, R4-027 | identical default-psh survivor class |

No opposing-direction conflicts detected this round.

### Flags for the user (blocking only their own items)

1. **R4-029 — combine-UX (status: needs-clarification).** Options — pick one (or propose
   your own): **(a)** keep the link icon but make it LOUD — pulse/glow the combinable item
   + brief first-time tooltip ("combine?") when a combinable item is armed (smallest
   change); **(b)** a two-slot combine tray inside the enlarged-inventory view — drop two
   items in, tap combine (most discoverable, more UI); **(c)** armed item A + tap item B →
   inline confirm chip ("combine file + spoon?") before combining (middle ground, stays
   pure select-then-tap). All three preserve the near-wordless direction ((a)/(c) use one
   transient word or none).
2. **R4-010 / R4-012 psh conditionals — resolution method (FYI, no action needed):** the
   Developer resolves "is it the same psh?" at CODE level — inspect the audio trigger map;
   if the cellar-entry/drawer taps reference the same default-tap asset slated for removal
   in R2-024, it is removed (your standing instruction). Only if it turns out to be a
   DISTINCT, intentionally-themed cue will we come back and ask keep-or-change.
3. **R4-026 — no design conflict (FYI):** manual pickup of the statue key is consistent
   with your R2-020 lifecycle rule and the R2-003 manual-pickup direction; folded into
   cluster A. The related "depleted close-up shouldn't invite a zoom" point stays parked
   with the round-2 R2-017/R2-022 "prune dead-end zooms" design discussion.
4. **Merge confirmations M-1…M-5 above.**

### ROUND 4 — ROUTED CHANGELIST (prioritized; ⛔ CHECKPOINT 1 — user reviews/approves BEFORE any execution)

| # | Cluster/Item | Class | Sev | Routing | Regression scope (proposed — QA has final say) |
|---|---|---|---|---|---|
| 1 | **A** — lifecycle engine + manual pickup (R4-019🔴, R4-030, R4-013(1), R4-026) | bug | **critical** | **Developer** (uses-driven retain/consume + manual-pickup step) + **Puzzle Logic Validator** (re-validate: no soft-lock reintroduced, all orderings) | **FULL** + NEW alternate-ordering suite (incl. p06-before-p05, cellar-first) asserting completability |
| 2 | **B** — per-element overlay architecture (R4-024 anchor + symptoms) | bug | major (systemic) | **Developer** (compositor: one base + independent ov-* overlays, correct transforms/z-order); **Asset Generation** ONLY for overlays found missing in the manifest inventory (derived crops from existing build-3 plates); flag to **Art Director** only if a state needs new art direction | **FULL** — touches every view's rendering; player-style screenshot verification of EVERY state change (per R2-META-QA) |
| 3 | **F** — armed-item interaction model (R4-005 + merged) | bug | major | **Developer** (deselect affordance + close-ups reachable while armed, ALL items game-wide) | **FULL** — core interaction system; test armed-state against every hotspot class |
| 4 | **E** — hotspot/hit-target audit (R4-016, R4-023, R4-025) | bug | major | **Developer** (systematic re-calibration vs build-3 plates; entry hotspots cover full affordance) | Broad-targeted: tap-audit every hotspot + transition in all 4 zones at human-visible coordinates |
| 5 | R4-007 — moon-dial waning-gibbous mirror-flip | bug | major | **Asset Generation** (correct dial silhouette: dark-bite-RIGHT; keep waxing/waning gibbous distinct on the 8-phase ring) + verify triptych 3-crow moon matches + **Developer** if the solve detent indexes the wrong phase | Targeted: p02 dial + triptych close-ups + p02 solve verify |
| 6 | R4-020(1) — per-slot placement feedback (p04) | bug | major | **Developer** (correct partial placement: item seats visibly + positive cue; audit other multi-slot puzzles; verify no confusing clue-gating interaction) | Targeted: p04 both orders (coin-first / ring-first) |
| 7 | **C** — stale resolved-state close-ups (R4-009(3), R4-018, R4-020(2), R4-028) | bug | minor (class-level major) | **Developer** (staging audit + manifest verify + extend `assert_no_nb_shadow` to resolved/interaction close-ups); **Asset Generation** only if a build-3 file is genuinely absent | Targeted: visual review of every resolved-state close-up in all zones |
| 8 | **D** — psh completion audit (R4-010 + merged) | bug | minor | **Developer** (verify whether the R2-024 fix shipped; kill default tap sound at the trigger map; themed event cues only) | Targeted: audio triggers, all tap classes incl. nav/entry |
| 9 | R4-002 — residual ocean-waves at entry | bug | minor | **Developer** (remove leftover amb loop from level-entry sequence; music only, per R2-005) | Targeted: level start/restart/resume audio |
| 10 | R4-001 — "Level 1" label | bug | minor | **Developer** (label = "Level 1", serif, per global-ui-style §3 + standing instruction) | Targeted: Level Select chrome |
| 11 | R4-003 — menu-chrome sound consistency | polish | — | **Developer** (standardize the Level-Select ping across Main Menu / Level Select / Pause / Settings) | Targeted: menu layer |
| 12 | R4-029 — combine-UX | polish | — | ⏸ BLOCKED on user option pick (flag 1) → then **Developer** | Targeted: p12 combine + inventory interplay |
| 13 | **STANDING — Regression-Verification Directive** (per R2-META-QA): for EACH recurring round-2 fix (psh removal, state-visual refresh, manual pickup) the Developer must determine whether it was LOST in the build-3 rebuild or NEVER FULLY SHIPPED, record the answer in implementation notes, and add a guard (test or CI assert) against silent loss; **QA must re-verify ALL round-2 closures** — not just round-4 items — in the build-10 pass | process | — | **Developer + QA** | FULL (it IS the regression-pass definition) |

**Sequencing note (for the Producer):** items 1–4 are interdependent at the engine layer
(lifecycle, compositor, interaction, hotspots) — one Developer batch, with the Validator
gating item 1 before staging; any item-5/7 art is finalized BEFORE the Developer stages,
per the round-3 sequencing lesson (no concurrent working-tree writes).

**⛔ CHECKPOINT 1 (now):** user reviews this changelist + resolves flag 1 and merges
M-1…M-5 before ANY execution.
**⛔ CHECKPOINT 2 (after fixes land):** user reviews QA's build-10 regression results
(including the round-2 closure re-verification) BEFORE re-release to TestFlight.

### Item statuses
All round-4 items → `status: routed (pending checkpoint-1)` per the table above, EXCEPT:
R4-029 → `needs-clarification` (user option pick); R4-014(1) → `duplicate-of-R4-023`
(pending M-2); R4-009(2)/R4-014(2) → `duplicate-of-R4-005` (pending M-1); R4-030 →
`merged-with-R4-019` (pending M-3); R4-021 → unused; R4-completion + embedded positives →
informational, not routed.

### Post-release delta — HANDOFF TEXT for the Producer (single-writer: Producer applies these; Intake does not write those two files)

**For `specs/progression-ledger.md`** (append under Level 1):
> **Post-release feedback round 4 (build 9, processed 2026-07-11).** No difficulty rescore —
> no balance changes requested or made; Level 1 holds 6.0. Mechanics touched by the routed
> fixes: item-lifecycle engine (uses-driven retain/consume — fixes the poker soft-lock
> R4-019 and non-consumption R4-030; preserves anti_softlock_invariants), manual-pickup
> uniformity (weight, statue key), armed-item interaction model (deselect +
> inspect-while-armed), scene-state rendering (full-plate swaps → per-element overlay
> compositing), p02 waning-gibbous dial art corrected to spec (dark-bite-RIGHT, matches
> triptych). Solvability: build 9 verified completable end-to-end (standard order) by the
> user; alternate-order completability restored by the lifecycle fix (Validator to
> re-confirm).

**For `specs/project-state.md`** (new entry):
> **Post-release feedback round 4 — processed 2026-07-11.** Build 9 device testing (iPad,
> TestFlight): 30 items + completion logged; level completed end-to-end. 1 critical
> (R4-019 poker-lifecycle soft-lock on alternate orderings). Six root clusters routed:
> (A) inventory lifecycle/manual pickup [Dev+Validator], (B) per-element overlay rendering
> architecture [Dev, anchor R4-024], (C) stale resolved-state close-ups [Dev staging +
> assert_no_nb_shadow extension], (D) default-psh audit completion [Dev], (E) hotspot
> re-calibration [Dev], (F) armed-item interaction model [Dev]; singles: Level-1 label,
> ocean-residue audio, moon-dial mirror-flip [AssetGen], p04 placement feedback, menu-ping
> consistency; R4-029 combine-UX awaiting user option pick. Standing directive: determine
> lost-vs-never-shipped for each recurring round-2 fix + add guards; QA re-verifies ALL
> round-2 closures in the build-10 pass. Status: ⛔ awaiting user CHECKPOINT-1 on the
> changelist; target build 10.

### ✅ CHECKPOINT 1 PASSED (user, 2026-07-11) — round routed for execution

- **Changelist APPROVED as routed** — all six clusters (A–F) + singles + the standing
  Regression-Verification Directive. **Merges M-1…M-5 CONFIRMED.**
- **R4-029 combine-UX RESOLVED: option (a)** — clearer link affordance (pulse/highlight,
  larger badge) + a one-time first-combine hint; interaction stays select-then-tap.
  R4-029 status → `routed` (Developer).
- **Execution shape (user-approved): ONE build — build 10** = round-4 fixes + the
  deferred letterbox plate re-frame, internally ordered: lifecycle → re-frame → overlay
  architecture on the RE-FRAMED bases → hotspot recalibration → armed-item/sound/singles
  → QA full pass including the round-2 closure re-verification.
- **Budget ruling:** art cap raised to **$23.00 HARD STOP** (was $18.90; $17.25 spent) to
  cover the re-frame + dial fix + overlay gap-fills; Asset Generation stops and reports
  if projecting past it.
- **⛔ CHECKPOINT 2 remains:** user reviews QA's build-10 regression results before any
  re-release to TestFlight.

**Item statuses (final for this round):** all round-4 items → `status: routed`, EXCEPT:
R4-014(1) → `duplicate-of-R4-023`; R4-009(2)/R4-014(2) → `duplicate-of-R4-005`; R4-030 →
`merged-with-R4-019`; R4-021 → unused; R4-completion + embedded positives → informational,
not routed. R4-029 → `routed` per the option-(a) resolution above (was
needs-clarification). No items remain blocked.

_Round 4 processing complete; checkpoint 1 passed. Producer routes execution from here.
Next gate: CHECKPOINT 2 (QA build-10 regression review) before re-release._

---

## Round 5 (build-10 device testing on iPad — CONFIRMED build "1.0 (10)" via Settings footer)

### R5-001 — status: logged 🔴 MAJOR (build-10 runtime defect, critical-path visual)
> picked up the poker on BUILD 10 and still see the misplaced fireplace fragment
> (context: R4-004 recurrence ON build 10 — the overlay ARCHITECTURE shipped (ov-poker-taken
> rebuilt in 342d858) and QA "verified" it — but via an OFFLINE COMPOSITE of the staged overlay
> at overlays.json rects, NOT a live rendered frame. Device shows the runtime still
> misregisters. So the defect is in the RUNTIME compositing path (coordinate space/anchor/
> scale mismatch vs the offline math, wrong overlay chosen, or z/transform bug in the
> SpriteKit compositor). QA-method lesson: offline composite ≠ rendered frame — overlay
> verification MUST use real rendered frames. → Developer, HIGH: reproduce via an in-app
> rendered frame (simulator screenshot after poker pickup), root-cause runtime-vs-composite
> divergence, fix, and add a rendered-frame registration assertion so this can't pass falsely
> again.)

### R5-002 — status: logged (minor, rides with build 11)
> the About screen says "Art generated with Flux 2 Pro" — not true
> (context: `SettingsView.swift:126` — stale credit from the original chrome build; the art
> has been Nano Banana Pro (fal.ai) since the model switch, and the music is fal.ai-generated
> too. Fix the attribution line: art = Nano Banana Pro via fal.ai; keep sounds line; add music
> credit. → Developer one-liner, fold into build 11.)

### R5-context
> Stale close-ups on build 10 (cage refusal view, solved astrolabe) = the 18 never-generated
> build-1 files — CONFIRMED against the shipped bundle, root-caused (cluster-C mislabel +
> guard blind spot), gap-fill generation already running (build11_gapfill). Vintage guard to
> be added by Developer at staging.

---

## Round 6 (build-11 milestone device testing on iPad — TestFlight "Within 1.0 (build 12)"; logging)

### R6-001 — status: logged (SCREENSHOT ATTACHED 2026-07-13)
> [screenshot] confirms the combined state: rug folded back revealing the trapdoor planks, poker
> in inventory. AIR rune (up-triangle+bar +I) on the bellows and FIRE (up-triangle +II) on the
> lintel both read CORRECT here (reconfirms R6-002 that AIR/FIRE are fine; only EARTH drifted).
> The "empty poker placeholder" the user reports is the poker-taken overlay/patch composited in
> the wrong spot in this combined poker-taken+rug-moved state — consistent with the R6-006 re-frame
> coordinate-delta root (overlay anchors not re-mapped to the re-framed plate). Developer reproduces
> in-engine; the fix is coordinate/overlay-registration, not art. (If the Producer's element ID is
> off, the exact artifact is in the hearth-base/rug region per the user.)
> as soon as i pick up the poker from next to the fireplace, AND unveil the cellar door from
> under the rug, the empty poker placeholder hovers over the rug — a visual bug
> (context: z1 v-hearth. TWO overlays active together — poker-taken + rug-moved — and the
> poker-taken overlay renders floating OVER the rug-moved region instead of sitting flush on
> the hearth surround where the poker was. Build 11 fixed the R5-001 baked-in poker fragment
> and added rendered-frame registration tests for the poker/rug/trapdoor STACK — but this
> specific COMBINED state (poker gone + rug folded) apparently still mis-composites: likely a
> z-order or position issue where the poker-taken patch draws above/into the rug-moved overlay.
> The rendered-frame guard may test the overlays individually or in a different combo, not this
> exact pair. → Developer: reproduce the poker-taken + rug-moved combined frame, fix the
> compositing (z-order/position), and EXTEND the rendered-frame guard to this pairing. Picture
> to be attached. NOTE: this is the same overlay-compositing family as R4-004/R4-024 — verify
> the fix is general, not just this pair.)

### R6-002 — status: logged (SIMPLE fix approved by user → do it)
> arrow clues: (1) AIR up-arrow-with-line on the bellows ✓, (2) FIRE up-arrow above the
> fireplace ✓, (4) WATER down-arrow-no-line by the window ✓ — all correct. BUT (3) the EARTH
> down-arrow on the desk flowerpot has its LINE UNDERNEATH the triangle, not through the MIDDLE
> like the potion-room door shows. "if it's supposed to be in the middle like the door puzzle,
> and it's a SIMPLE fix, do it; if big, skip."
> (context: glyph-canon inconsistency, R3-007 family. Canonical EARTH = downward triangle with
> a horizontal bar THROUGH the middle (matches the door tiles + the classical alchemical earth
> symbol). The flowerpot mark (`cu-flowerpot` + the wide z1-study flowerpot region if the rune
> shows there) has the bar mis-placed BELOW the triangle → doesn't match the door → a player
> comparing clue↔door sees two different EARTH glyphs. VERDICT: this IS a simple fix — a $0
> deterministic PIL re-stamp of the canonical EARTH glyph onto the flowerpot mark (same
> technique R3-007 used on the door), so per the user's condition, DO IT. Door = canon; bring
> the flowerpot to match. → Asset Gen (stamp) + Developer stage; fold into next build. Reinforces
> R3-007: the four MARKS were assumed pixel-correct but EARTH's bar position drifted from canon —
> re-verify all four marks match the door canon exactly while at it.)

### R6-003 — status: logged (design principle + fix)
> picked up the rusted key next to the door in the caged-crow scene, finished the game, NEVER
> used it → it's a useless inventory item. "i don't mind decoys, but decoys should NEVER be
> items that are added to inventory. the correct key for the caged crow is taken from the hidden
> moonflower room — keep that."
> (context: the rusted bent key (itm-rusted-key / rh-rusted-key) is an INTENTIONAL red herring —
> plain/snapped bit that can't fit the cage's star keyhole; the REAL key is the star-bit key from
> the z4 alcove statue (itm-cage-key), which stays. But it's currently COLLECTIBLE → clutters
> inventory with a permanently-useless item, which reads as a bug/incompleteness to the player.
> FIX: make the rusted key a NON-COLLECTIBLE scene decoy — still inspectable (close-up shows the
> broken/plain bit so the 'try it on the cage' theory is defused by LOOKING, not by picking-up-
> and-failing), but tapping it does NOT add it to inventory. The alcove star-key remains the only
> collectible cage key. → puzzle-graph note (rusted key = non-inventory decoy; verify NO solve
> path referenced itm-rusted-key — it's a decoy, so none should → light Validator confirm) +
> Developer (remove the pickup, keep the inspect close-up). Small, fold into next build.
> **STANDING DESIGN PRINCIPLE (user, 2026-07-13): decoys/red-herrings must NEVER be collectible
> inventory items — they stay as in-scene inspectable objects only.** Applies to THIS level
> (audit other decoys: potion shelf is already non-collectible ✓; clock inert ✓) AND all future
> levels — add to the Theme & Puzzle Designer's rules.)

### R6-004 — status: logged (picture incoming)
> the desk scene (z1 study) has a weird BLURRY effect up top, like the scene got STRETCHED
> (context: almost certainly a re-frame artifact. Build-10 dual-safe re-framing of all 6 views
> used `specs/tools/reframe_b10.py` with a "PIL BAND FALLBACK after outpaint rejection" — where
> it couldn't cleanly extend a plate to the re-framed aspect it filled the edge by stretching/
> banding existing pixels → a blurry stretched strip. The z1-study base plate's TOP edge is
> likely showing that band. → Asset Gen: re-derive the study plate's top region cleanly (crop-in
> / content-preserving fill, NOT a stretch band); if the whole re-frame band is bad on this view,
> redo that view's re-frame. Await picture for severity + SWEEP the other 5 views (the re-frame
> touched all 6) for the same top/edge band. Fold into next build.)
>
> **CONFIRMED SYSTEMIC (user, 2026-07-13):** the same blurry/stretched band also shows in the
> caged-crow scene (z1 v-entry), this time on BOTH top AND bottom edges. So the re-frame band
> artifact is NOT isolated to the study — it's across views (the re-frame added bands wherever the
> plate's native aspect fell short of the re-framed dual-safe target, top and/or bottom). Treat as
> a FULL re-frame-band sweep: for each of the 6 views, replace any stretched/blurred fallback band
> with clean content-preserving fill (or re-frame the view properly). This is the cosmetic residue
> of the aspectFill-restore path; prioritize the views the player sees most (entry, study, hearth).
> Pictures for entry (top+bottom) + study (top) incoming.
> Third view CONFIRMED: z3 cellar shows the band TOP AND BOTTOM. So study(top) + entry(top+bottom)
> + cellar(top+bottom) + bench/potion-room(top+bottom) + CABINET(top+bottom) = ≥5 of 6 views
> affected → all-view sweep confirmed (only alcove unconfirmed; assume all 6). Screenshots incoming. Pattern:
> bands appear on whichever short edge(s) the re-frame had to pad — treat as ALL views, ALL edges;
> re-derive clean content per edge.)

### R6-005 — status: logged (picture incoming) — state-refresh recurrence on BUILD 11
> barrel: zoomed (closed), back; zoomed again, used poker on it, picked up the weight (now in
> inventory), back once more → the weight is visible BOTH on the wide scene AND in my inventory
> (context: z3 cellar barrel (p06). After collecting the weight, the wide cellar view still shows
> the weight (barrel should read pried-and-EMPTY / weight-taken), so the weight appears duplicated
> — in-scene AND held. This is the state-visual / overlay family (R4-013 barrel, R2-014 spoon,
> R4-024 cellar contamination) that build 10's per-element overlay architecture was supposed to
> fix and QA marked verified — so either the weight-TAKEN transition wasn't wired (barrel shows
> pried-with-weight, no ov for pried-empty applied on collect) or it regressed. NOTABLE: QA's
> build-10 overlay verification (offline composites + rendered-frame tests) did NOT catch this,
> same gap-class as R6-001 (uncovered overlay combo). → Developer: wire/verify the weight-taken
> cellar state so the wide view shows the empty pried barrel after collect; add it to the
> rendered-frame overlay coverage. Screenshot incoming. Reinforces: the rendered-frame overlay
> guard needs to cover EVERY element's taken/resolved state, not a sample.)

### R6-006 — status: logged 🔴 (hotspot mispositioned, p07 — recurrence of R4-023)
> using the weight on the roped hook doesn't work — hotspot location is WRONG. after random
> clicking, it let me hook the weight on the WALL hook to the LEFT of the hidden compartment; the
> compartment opened, but VISUALLY the weight hangs on the ROPED hook to the RIGHT. confirms the
> hotspot is disconnected from the visual. now the weight is on the roped hook (not in inventory,
> correct) but ALSO still visible in the barrel.
> (context: z3 cellar p07 (hang weight → counterweight → open compartment). TWO things: (1) 🔴
> HOTSPOT MISPOSITIONED — the tap target for hanging the weight is on the LEFT wall hook, but the
> weight-hung VISUAL renders on the RIGHT roped hook → tap-target ≠ visible affordance. RECURRENCE
> of R4-023 (p07 hook), which build-10 cluster-E was supposed to fix. LIKELY ROOT (connects R6-001):
> the build-10 dual-safe RE-FRAME shifted every element's position in the plates, and the hotspot/
> overlay coordinates were NOT fully re-mapped to the re-framed positions → cellar hotspots (hook)
> and overlay anchors (poker+rug) are offset by the re-frame delta. → Developer: re-derive cellar
> (and audit ALL views') hotspot + overlay coords against the CURRENT re-framed plates; tap target
> must sit on the visible roped hook. (2) reconfirms R6-005 (weight still in barrel). p07 LOGIC is
> fine (compartment opened) — purely hotspot-position + state-visual. Screenshot incoming.)

### R6-007 — status: logged (picture incoming) — likely the QA-B10-002 DEFERRED legacy art surfacing
> potion room: closed up on the big pot over the fireplace [CAULDRON, not the mortar — the mortar
> is the marble bowl on the workbench], tried random combos (2× clockwise, released ladle), went
> back to the scene, and the cauldron image changed to one of those STALE images.
> (context: z2 v-bench cauldron/brew (p14). STRONG SUSPECT: this is a KNOWN deferred-legacy asset,
> NOT a new stale-shadow — the vintage guard has 4 tracked KNOWN_LEGACY_SOURCES exceptions, and
> THREE of them are the z2 bench FLAME plates `z2-bench-flame1/2/3` (QA-B10-002 "accepted minor art
> residual, re-roll deferred"). When the player pumps the bellows / interacts with the brew, the
> flame-stage overlay shows one of those build-2-framed plates → reads as "stale" vs the new bench
> base. (Could alternatively be a stale brew-state close-up like cu-brew-fizzle — screenshot will
> disambiguate.) IMPLICATION: the deferred QA-B10-002 residuals are PLAYER-VISIBLE in normal play,
> so 'defer' is wrong — UN-DEFER: → Asset Gen re-roll the 3 flame plates (+ slots-seated) in
> build-3 style, then remove their KNOWN_LEGACY_SOURCES exceptions so the vintage guard covers them
> too. Fold into next build. Minor naming aside: user unsure cauldron vs mortar — not an issue.)
>
> **CONFIRMED (user, 2026-07-13): the stale image appears ONLY when pumping the bellows** →
> it IS the flame-stage overlay = the deferred legacy `z2-bench-flame1/2/3` plates, exactly as
> suspected. Fix = re-roll all THREE flame plates in build-3 style + un-defer (remove their
> KNOWN_LEGACY_SOURCES exceptions). "check on all combos" → verify every flame stage (0/1/2/3) AND
> every brew liquid state (clear/fizzle/draught) renders build-3 art, plus the slots-seated 4th
> deferred residual. So the QA-B10-002 "accepted, deferred" set is fully un-deferred this round.)

### R6-008 — status: logged (3 screenshots incoming) — astrolabe drawer: black-box + hotspot + dup
> astrolabe base drawer (z2 cabinet, p03 yield): (SS1) a BLACK SQUARE appears after randomly
> clicking and finding the FIRST item hotspot (the crank); (SS2) with BOTH hotspots found (moon
> coin + crank) the drawer reads empty and the black box disappears; (SS3) the crank + moon coin
> are in inventory BUT also still appear in the open drawer.
> (context: THREE defects on ONE close-up, each in a family already open this round: (1) 🆕
> BLACK-SQUARE artifact while one item is collected but not the other — a partial/intermediate
> drawer state renders a black box (missing/transparent overlay drawn black, or a bad per-item
> mask); distant echo of the build-3 astrolabe GREY-BOX soft-lock (R2-018/019/025/026) — the
> partial resolved state still isn't compositing cleanly. (2) HOTSPOT DISCOVERY IS RANDOM — the
> coin/crank item hotspots don't sit on the visible items → same re-frame-coordinate-delta root as
> R6-006 (item rects not re-mapped to the re-framed plate). (3) ITEM DUPLICATION — coin+crank in
> inventory but STILL shown in the open drawer → drawer-emptied state not applied after collect,
> same as R6-005. → Developer: fix partial-collect drawer render (no black box; each item gone as
> taken; empty when both taken), re-map the two item hotspots to the visible items, add this
> drawer's partial+emptied states to the rendered-frame guard. SS1/2/3 incoming. NOTE: this single
> close-up reproduces ALL THREE of this round's systemic roots (missing/black render, hotspot
> delta, taken-state-not-applied) — an ideal regression fixture for the Developer.)

### R6-009 — status: logged 🔴🔴 CRITICAL (progression soft-lock) — R4-019 REGRESSED / never really shipped
> "again i forgot to get the gold [ring] from the ash using the poker, and the poker is COMPLETELY
> CONSUMED, rendering the game unsolvable."
> (context: z1 ash-sift p05 (poker reveals gold ring) + z3 barrel-pry p06 (poker) — the poker is a
> MULTI-USE tool. User used it on the barrel first, poker got consumed, so the ash-sift is now
> impossible → gold ring unreachable → LEVEL UNSOLVABLE. This is EXACTLY R4-019, the round-4
> CRITICAL that build-10's item-lifecycle engine (retain while ANY `uses` entry unsatisfied; remove
> only when ALL satisfied) was built to fix, and that build-10 QA marked "DEAD". IT IS NOT DEAD in
> the shipped build. ROOT of the QA MISS: build-10 QA verified R4-019 at "engine + coordinator"
> level (unit/coordinator asserts) and EXPLICITLY did NOT run a second UI alternate-order
> playthrough (noted in the qa-report as an accepted scope call). So the ENGINE rule may be right
> while the actual in-GAME consumption path (whatever code the poker-on-barrel tap runs) still
> decrements/removes the poker — OR a build-11 change regressed it. This is the recurring project
> lesson in its worst form: engine-verified ≠ player-experienced, and it shipped a CRITICAL
> soft-lock. → TOP PRIORITY. Developer: reproduce via a real UI playthrough in the ALTERNATE order
> (barrel-before-ash), find where the poker is actually consumed in the shipped path, fix so the
> poker survives until BOTH p05 and p06 are done, and add a UI (not just engine) alternate-order
> playthrough to CI that would FAIL on this. Validator: re-confirm anti_softlock_invariants hold
> for the poker in the SHIPPED build. This gates the next release — do not ship until a real UI
> alt-order playthrough completes green.)
>
> **REFINED REPRO (user, 2026-07-13; re-testing to confirm):** "the poker disappears if i get to
> the astrolabe scene BEFORE going to the cellar." → This is likely NOT use-consumption at all —
> the poker is removed from inventory on ENTERING/REACHING the z2-cabinet (astrolabe) view, before
> it's used on anything. Suspects: a scene-transition/zone-load side effect, a save/restore round-
> trip dropping the item, an over-eager lifecycle "remove when satisfied" mis-firing (though the
> poker's uses are UNSATISFIED here), or armed-item/combine logic clearing it. Much more findable
> than a general order bug: Developer, instrument inventory on z2-cabinet entry and bisect which
> event removes the poker. Await user's re-test confirmation of the exact trigger scene/sequence.
> Still 🔴 CRITICAL (any path that silently drops the multi-use poker = soft-lock).)
>
> **RE-TEST (user, 2026-07-13): DID NOT REPRODUCE — user still HAS the poker; "not sure if i saw
> wrong earlier."** → Reclassify from confirmed-critical to **UNCONFIRMED / possibly intermittent
> or a misperception.** DO NOT treat as a confirmed soft-lock, but DO NOT dismiss — an intermittent
> item-drop is worse than a deterministic one. **USER DIRECTIVE: "you need to validate this from
> screenshots."** → the poker (and every multi-use tool's) lifecycle MUST be validated with
> SCREENSHOT-based UI playthroughs across ALL legal orderings (barrel-before-ash, astrolabe-first,
> etc.) capturing the inventory bar at each step — not engine/coordinator asserts (that gap is
> exactly what let R4-019 "pass"). If screenshots show the poker retained through every ordering,
> R6-009 resolves as no-repro (lifecycle sound); if any frame shows it vanish, that frame is the
> repro. This screenshot-based lifecycle validation is a GATING requirement for the next release.
> STANDING (reinforced by user): verification of state/inventory/collect behaviors = rendered
> screenshots, never engine flags alone.)

### R6-010 — status: logged (2 screenshots incoming) — p04 cabinet = SAME 3 defects as R6-008
> used coin + ring on the cabinet (p04 solved), can see the shaver [file] + vial/bottle [phial]
> inside; hotspots wrong AGAIN — picked the shaver by random clicking → BLACK BOX appeared → kept
> random-clicking for the bottle → black box disappears, items in inventory but ALSO still visible
> in the open cabinet.
> (context: z2 v-cabinet p04 open-state (file+phial). This reproduces the EXACT R6-008 triad on a
> SECOND container: (1) black-box partial-collect render, (2) wrong item hotspots (re-frame
> coordinate delta), (3) items duplicated (collected but still shown in the open cabinet — taken-
> state not applied). So the three round-6 systemic roots hit EVERY resolved-container close-up
> (astrolabe drawer R6-008 + sun/moon cabinet R6-010) → the Developer fix MUST be general to the
> container-reveal→collect mechanism, not per-close-up: (a) render each item gone as it's taken
> with NO black box for partial states, (b) map item hotspots to the visible items in the
> re-framed plate, (c) empty the container in the wide+close-up once all items taken. Merge R6-010
> into R6-008's fix (they are one bug on two containers). Screenshots incoming.
> **EXTENDS (user, 2026-07-13): going back to the WIDE cabinet scene shows the cabinet empty but
> with a visible BLACK BOX where the placeholder used to be.** So the black-box artifact is not
> just the close-up partial state — it also renders in the WIDE view's cabinet-open-empty state
> (an item overlay/placeholder rendering as a black rect instead of showing nothing / the empty
> shelf). Add the wide cabinet-open-empty state to the render fix + rendered-frame guard. Same
> screenshot ALSO shows R6-004 band (see R6-004 — cabinet = 5th view).)

### R6-011 — status: logged ⚠️ design decision at checkpoint (recipe↔brew mismatch)
> the grimoire recipe page shows the spiral going CLOCKWISE with 6 dots, but the brew requires 5
> CCW → the clue is wrong. "easier to fix the mortar to 5 CLOCKWISE than regenerate the pic?"
> (context: p14 brew (cauldron, not mortar). DOUBLE mismatch clue↔solution: recipe art = CW + 6
> dots; brew solution = 5 stirs CCW. Both DIRECTION and COUNT disagree. The CANON (puzzle-graph
> `clu-grimoire-recipe` + p14 solution) is **5 CCW** — recipe should read "CCW arrowhead + FIVE
> dots." So the RECIPE ART is the defective side (build-3 regen drew it CW with 6 dots).
> PRODUCER RECOMMENDATION (answer to the user's question): fix the RECIPE ART, not the brew.
> Reasons: (1) the brew's 5-CCW is the canonical fixed solution value — CLAUDE.md says don't
> reopen those; changing it is a puzzle-graph + Validator + anti-softlock change, NOT just "flip a
> constant". (2) The COUNT also mismatches (6 vs 5), so matching the brew to the art would mean 6
> CW — a bigger change. (3) The recipe-art fix is art-only, likely a simple targeted re-draw of
> the spiral (deterministic PIL CCW 5-dot spiral, ~$0), no logic/validator risk. So flipping the
> art is actually the EASIER and SAFER path, contrary to first impression. → USER DECISION at
> checkpoint-1: (a) fix recipe art to CCW+5 [recommended], or (b) change brew to match the art
> (CW + 6 stirs; reopens the solution value). If (a): Asset Gen re-draws the spiral; Validator
> confirms recipe↔brew match. Screenshot of the recipe page helpful.)

### Round-6 SCREENSHOT CONFIRMATIONS (batch, 2026-07-13) — supersedes the "incoming" markers above
- **R6-004 (entry scene):** band present at top/bottom edges (subtle at this compression). Entry
  = confirmed via screenshot; all-view sweep stands.
- **R6-005 (cellar):** CONFIRMED — the iron weight is visible sitting ON/IN the barrel AND is the
  4th item in the inventory bar simultaneously → clear duplication (taken-state not applied to the
  barrel).
- **R6-006 (cellar, p07 solved):** CONFIRMED — the sliding panel is OPEN (dark compartment
  revealed), the weight now hangs on the ROPED hook (center pulley), and the weight is correctly
  GONE from inventory (3 items) — BUT the barrel STILL shows the weight → reconfirms R6-005's stale
  barrel state. Puzzle LOGIC fine (compartment opened). Confirms the hotspot-vs-visual mismatch
  context.
- **R6-007 (potion room):** STRONGLY CONFIRMED — the stale asset renders as a DARK PHOTOREAL
  cauldron RECTANGLE floating/misregistered over the warm stylized bench scene (clearly build-1/2
  art, wrong style AND wrong frame). It's both STALE (a legacy plate) and MISREGISTERED (floating
  box). Un-defer + re-roll the flame/cauldron plates AND fix its overlay registration.
- **BONUS — R6-003 reconfirmed:** the rusted decoy KEY is visibly IN the inventory bar (leftmost
  item) across the cellar/bench shots — exactly the "decoy should not be collectible" problem.

### Round-6 SCREENSHOT CONFIRMATIONS (batch 3, 2026-07-13) — R6-008 / R6-010 container bug
- **R6-008 (astrolabe drawer), 3 frames CONFIRMED:** (a) PARTIAL state — crank collected (in
  inventory) but STILL shown in the open drawer next to the un-taken moon coin → duplication;
  the "black box" is present but FAINT here (user note) — so the black-box artifact severity
  VARIES by state (a subtle translucent/dark rect, not always solid). (b) drawer EMPTY once both
  taken, no black box, both items now in inventory. (c) WIDE cabinet view STILL shows the coin +
  crank in the astrolabe drawer while both are in inventory → the taken-state-not-applied
  duplication extends to the WIDE view, not just the close-up.
- **R6-010 (sun/moon cabinet) CONFIRMED:** cabinet OPEN (p04 solved), the file [shaver] is in
  inventory but STILL visible on the cabinet shelf → duplication; a faint horizontal band/artifact
  crosses the cabinet interior (black-box/re-frame residue). Same container-reveal bug as R6-008.
- **POSITIVE (lifecycle) confirmed:** the moon coin + gold ring were CONSUMED correctly when
  PLACED into the p04 slots (gone from inventory in the cabinet-open frame). So PLACEMENT
  consumption works — the bug is specifically CONTAINER-REVEAL items duplicating on COLLECT (they
  enter inventory but aren't removed from the container render). Narrows the Developer fix.
- **Severity note:** black box is FAINT/translucent in these captures (not the solid black of
  earlier reports) → the fix is the same (render the empty container correctly per collect state),
  but it reads as a subtle mis-composite, not an alarming solid box, at least in these states.

### Round-6 SCREENSHOT CONFIRMATIONS (batch 4, 2026-07-13) — container CLOSE-UP vs WIDE distinction
- **R6-010 b (cabinet CLOSE-UP):** file + phial BOTH collected (both in inventory) but BOTH still
  shown on the cabinet shelf → duplication of both items in the close-up; faint translucent band
  still crosses the cabinet interior in the close-up.
- **R6-010 wide (cabinet OPEN):** the cabinet-open-empty WIDE state renders CORRECTLY — shelves
  empty, no duplication, and the user confirms NO band in the open-wide state ("doesn't have the
  band since i already opened the cabinet"). → REFINES the earlier R6-010-extend note: the
  open-wide cabinet is actually clean; the band was on the CLOSED-cabinet wide state (R6-004
  re-frame band on the base plate, hidden once the open overlay covers it).
- **BUT same wide shot still shows the ASTROLABE DRAWER (bottom-right) displaying its coin+crank**
  after collect/consume → R6-008 WIDE duplication persists. So the two containers DIFFER in the
  wide view: astrolabe drawer duplicates in wide; sun/moon cabinet renders empty in wide correctly.
  COMMON defect = the CLOSE-UP collected-state (both containers wrong); wide-view is container-
  specific (drawer wrong, cabinet right). Developer: fix the close-up collected-state render for
  ALL containers; additionally fix the astrolabe-drawer WIDE taken-state (barrel weight R6-005 is
  the same wide-taken-state class). Net: (1) close-up per-item collected render [all containers],
  (2) wide taken-state for drawer + barrel [R6-008/R6-005], (3) the faint band is R6-004 on the
  base plates.

### Round-6 SCREENSHOT CONFIRMATION (batch 5, 2026-07-14) — R6-011 recipe page
- **R6-011 (grimoire/recipe page) CONFIRMED:** the recipe spread reads left→right: moonflower in a
  mortar → shaver/file shaving the silver bar → feather dropped into an open hand → FIRE flame with
  Roman numeral **III**. Below the ingredient row is the STIR glyph: a **spiral with 6 dots** placed
  along its arc and a terminal **arrowhead at the outer/bottom end pointing LEFT → reads CLOCKWISE**.
  So the art instructs **6 stirs, clockwise**. The implemented brew solution is **5 stirs, CCW**.
  → MISMATCH on BOTH count (6 vs 5) AND direction (CW vs CCW), exactly as the user reported.
- The Flame **III** on the page correctly matches the brew's flame-level requirement (Flame III) —
  so ONLY the stir glyph is wrong; the flame clue is fine and must be preserved on any redraw.
- **USER DECISION still pending at checkpoint-1** (unchanged): (a) re-draw the spiral to **5 dots,
  CCW** to match the fixed solution [Producer recommendation — art-only, no logic/validator churn],
  or (b) change the brew solution to **6 CW** to match the current art (reopens the solution value,
  requires Validator re-confirm + walkthrough update). Grimoire cross-clues (potion-door + "where to
  find the other clues") must be re-checked for consistency under whichever option is chosen.
  This is the LAST outstanding Round-6 screenshot; round is ready to process on user trigger.

### R6-011 USER DECISION (2026-07-14): OPTION (a) — regenerate the art
- User approved re-drawing the stir glyph to **5 dots, COUNTER-CLOCKWISE** to match the fixed brew
  solution (5 CCW). Brew solution value is NOT reopened.
- **Binding constraint from user:** "don't lose the other clues on that particular page and the
  other pages of the grimoire — just fix the affected one." → Asset Gen must edit ONLY the spiral
  glyph (crop-scoped edit), preserving on the SAME page: moonflower/mortar, file/shaver+silver bar,
  feather/hand, and the Flame **III** numeral; and preserving ALL OTHER grimoire pages untouched
  (potion-door clue page + the "where to find the other clues" page). No full-page or full-grimoire
  re-render. Validator then re-confirms recipe↔brew match; Documentation reconciles the walkthrough.

### ROUND 6 PROCESSING TRIGGERED (2026-07-14) — user said "process it"

**PROCESSED 2026-07-14 (Feedback Intake). Routed changelist:
`specs/levels/level-1/round6-routed-changelist.md` (handed to Producer; pending GATE 1
user review before execution).** Phase-2 status per item:

| Item(s) | Class | Status | Target | Cluster / fix type |
|---------|-------|--------|--------|--------------------|
| R6-009 | bug (unconfirmed) | routed (release GATE) | QA screenshot UI playthroughs + Validator | poker-lifecycle screenshot validation across all orderings |
| R6-008, R6-010 (close-up) | bug (major) | routed | Developer | Cluster A — container collected-state render (code) |
| R6-005, R6-008-wide | bug (major) | routed | Developer | Cluster A — wide taken-state (code) |
| R6-001, R6-006, R6-008/010-hotspots | bug (major) | routed | Developer | Cluster B — re-frame coordinate remap (hotspot-remap) |
| R6-007 | bug (major) | routed | Asset-Gen + Developer | Cluster D — un-defer, re-roll + registration + guard-retire |
| R6-004 | bug (minor/cosmetic) | routed | Asset-Gen | Cluster C — re-frame band sweep (art-crop-edit) |
| R6-011 | bug (clue↔solution) | routed (decision a) | Asset-Gen + Validator + Documentation | 5-CCW spiral crop-edit |
| R6-003 | bug (minor) + standing principle | routed | Developer + Validator (light) | non-collectible decoy (code/config) |
| R6-002 | polish (glyph-canon) | routed | Asset-Gen + Developer | EARTH glyph re-stamp ($0 PIL) |
| R5-002 (carry) | polish (copy) | routed | Developer | About credit → Nano Banana Pro (fal.ai) / fal.ai music |

No duplicates requiring user merge-confirmation, no unresolved conflicts, no vague/
unactionable items (the screenshot batches resolved all "incoming" ambiguity), and no open
questions — R6-011 (option a) and R6-009 (screenshot-validate) were decided during logging.


---

# ROUND 7 — build 13 device spot-check (TestFlight "Within 1.0 (build 13)")

_User iPad spot-check of the Round-6 fix build, 2026-07-16. GATE-2 follow-up: this is the
post-release verification of the round-6 fixes, NOT a new feature round._

## CONFIRMED FIXED ON DEVICE (round-6 fixes verified by the user — close these)
- **R6-008 astrolabe drawer — FIXED** (user: "the astrolobe ... got fixed"). Container
  collect-state (Cluster A) confirmed working on device, close-up + wide.
- **R6-006 weight hook — FIXED** (user: "the weight got fixed"). Cluster B hotspot re-frame
  remap confirmed working on device.
  → These two were the round-6 systemic clusters; device-confirmed = clusters A and B land.

## R7-001 — cauldron/flame plate MISPLACED (art correct, registration wrong)
> "the cauldron picture was correctly replaced but it wasn't placed correctly where it used to
> be so that needs to be fixed"

The R6-007 ART re-roll SUCCEEDED (the new build-3-style cauldron/flame plate is the one
rendering — no more dark photoreal box), but the OVERLAY REGISTRATION is still wrong: the
correct plate is drawn at the wrong position/frame vs where the cauldron actually sits in the
bench scene. So R6-007 was HALF-fixed: art = yes, placement = no.
- Note: the round-6 Developer registration sub-fix unified the flame overlay's image name and
  placement-rect name (was `min(stage,3)` image vs `max(stage,1)` rect). That fixed a
  right-plate/wrong-rect MISMATCH but evidently the resulting rect itself is still not where
  the cauldron belongs on the current re-framed bench plate.
- SUSPECT: the overlay rect in `overlays.json` for the z2/v-bench flame plates was derived
  against a pre-re-frame (or differently-sized) base — the re-rolled plates are now 3840×1920
  (were stale 2560), so a rect computed for the old dimensions would land the art off-position.
- Severity: major (visible misplaced art in the potion room). Target: Developer (+ Asset-Gen if
  the rect must be re-derived from the plate).
- NEEDS: screenshot of where the cauldron renders now vs where it should be.

## R7-002 — screen edge bands STILL blurry/stretched on SOME scenes (R6-004 incomplete)
> "i still see the screen edges blurry/stretched on some scenes"

The R6-004 band sweep did NOT fully resolve on device. Round-6 scope note (from the ART agent,
and surfaced to the user at GATE 2 as non-blocking): the sweep cleaned the **top/bottom (short)
padded edges only** across the 6 re-framed views + variants; **left/right overscan bands were
deliberately LEFT AS-IS** because the original R6-004 report named only top/bottom.
- LIKELY ROOT: the user is now seeing the untouched **left/right** overscan bands — i.e. scope
  was too narrow, not that the sweep failed.
- ALTERNATIVE: some views/states were missed by the sweep, or close-up plates carry bands too
  (the sweep covered the 6 wide views + their variants; close-ups were not enumerated).
- Severity: minor/cosmetic but user-visible and now twice-reported → fix properly this time:
  sweep ALL edges (left/right as well as top/bottom) on ALL affected plates incl. close-ups.
- Target: Asset-Gen ($0 PIL preferred — the round-6 sweep was $0).
- NEEDS: which scenes, and which edges (top/bottom vs left/right) — screenshot ideal.

## STILL UNCONFIRMED from round 6 (user did not mention; re-ask at next spot-check)
- R6-004-adjacent: whether top/bottom specifically improved (user says "some scenes" still bad).
- R6-002 EARTH glyph faint carved-groove remnants (known, accepted as "fix only if simple").

## ROUND 7 — PRODUCER ROOT-CAUSE DIAGNOSIS (2026-07-16)

### R7-001 cauldron misplaced — ROOT CAUSE FOUND: stale overlay rects on the 4 re-rolled plates
Measured every overlay's image dims vs its `overlays.json` rect dims (bundle
`EscapeRoom/Resources/GameAssets/level-1/overlays.json`). **23 of 27 overlays match exactly
(ratio 1.000). Exactly 4 are mismatched — and they are EXACTLY the 4 QA-B10-002 legacy plates
that the round-6 ART track re-rolled (R6-007):**
| overlay | image px | rect px | img/rect |
|---|---|---|---|
| z2/v-bench ov-flame1 | 998x652 | 828x541 | **1.204** |
| z2/v-bench ov-flame2 | 998x768 | 828x637 | **1.204** |
| z2/v-bench ov-flame3 | 998x883 | 828x733 | **1.204** |
| z2/v-cabinet ov-slots-seated | 844x423 | 591x295 | **1.427** |
- The ART re-roll delivered CORRECT art at the correct plate size (3840x1920, matching base), but
  the overlays' placement RECTS were NOT recomputed from the new art — they are stale, carried from
  the old 2560-era diff bboxes. The compositor faithfully draws correct art into a wrong rect →
  the plate is scaled ~83% (flame) / ~70% (slots) and lands off-position = the user's "correctly
  replaced but not placed correctly where it used to be".
- Aspect ratios match exactly (998/883 == 828/733), so it is a pure uniform scale+offset error,
  NOT a bad crop. Confirms rect-derivation, not art, is at fault.
- **NOTE — R7-001b (not yet user-reported): `ov-slots-seated` is misregistered too** (1.427). That
  is the cabinet sun/moon "ring+coin seated" overlay. Same bug, same cause. Fix both.
- The other 23 overlays are auto-derived by `tools/build_game_assets.py` and are all 1.000 — so the
  fix is to make these 4 derive their rects the same way (the pipeline evidently carried hardcoded/
  cached rects for the former legacy-exception plates). Fixing the derivation prevents recurrence.
- Target: Developer (pipeline rect derivation + restage). Verify ALL 27 overlays == 1.000 after.

### R7-002 edge bands — ROOT CAUSE FOUND: stretched pixels under a vignette, never real content
Origin commit ff9299d (build 10): "S8 dual-safe re-frame of all 6 views (29 plates), **PIL band
fallback after outpaint rejection**" — the re-frame PADDED the plates top/bottom for the iPad safe
zone, an outpaint to fill that padding with real content was REJECTED, and it fell back to
STRETCHING the boundary pixels. Round-6's R6-004 "sweep" then applied a dark vignette ON TOP of
that stretch: pixel probe shows a smooth ramp from near-black (y=0, avg 6) to real content
(y~240, avg 57), with constant hue ratios across x = the smear is still there, just dimmed.
So R6-004 made it darker, not fixed. Measured smear depth per source plate (@3x, 3840x1920) —
correlates almost exactly with the user's report:
| view | top smear | bottom smear | user reported |
|---|---|---|---|
| study (desk) | 185px | 1px | top ✅ |
| entry (crow) | 195px | 194px | top+bottom ✅ |
| bench (cauldron) | 108px | 108px | top ✅ |
| cabinet (astrolabe) | 233px | 233px | top+bottom ✅ |
| cellar | 118px | 118px | bottom ✅ |
| hearth | 15px | 0px | NOT reported ✅ (clean) |
- Visible because on iPad the app fills width and shows the plate's FULL HEIGHT → the padding is
  on-screen by design (the dual-safe-zone re-frame intends it to be seen).
- **USER DECISION (2026-07-16): "Try outpaint, fall back"** — attempt a real outpaint of the padded
  strips with Nano Banana Pro (genuine scene extension); if it drifts in style/quality, fall back to
  a CLEAN fade-to-black (erase the smeared pixels entirely, no fake detail) rather than burn budget.
- Left/right edges also show smear (visible in the bench base plate) — sweep ALL edges this time.
- Target: Asset-Gen. Budget: $2.15 headroom of the $23.00 cap.

---

## Round 8 (Level 2 "The Clockmaker's Attic" — build-15 device testing on iPad, TestFlight "Within 1.0 (15)"; logging)

_First feedback round for LEVEL 2. Device/context: iPad, TestFlight, build 15, Level 2
first-time playthrough. Logging only (Phase 1) — items logged verbatim as reported, no
classification/routing/action until the user explicitly triggers processing._

### R8-001 — status: logged
> ok starting level 2 for the first time, the first scene is the chalkboard. inspecting pulls a closeup that shows a door at the end but i can't really pick up anything, so i go back. i pickup the screwdriver, and the little watch thing on the wall pulls another closeup of weather clock? cloudy, sunny, rainy. oh but there is no down arrow to get out of the closeup. is it hidden under the inventory screwdriver i just picked? i'm not sure, you have to check. i click randomly at the edges of the closeup and that seems to take me back to main scene, but i still need that arrow for consistency

(context — factual, no classification: Level 2 z1 v-bench, build 15, iPad.
- POSITIVE (working as reported): the slate/chalkboard inspect works — pulls a clue
  close-up showing a door at the end; nothing to pick up there, which is as-designed
  (clue view). The screwdriver pickup works.
- POSITIVE (confirms a prior fix target): "the little watch thing on the wall" = the
  BAROMETER close-up (cu-barometer, weather symbols cloudy/sunny/rainy) OPENS correctly —
  confirms the re-anchored barometer hotspot works (this was a stale-hotspot fix target).
- DEFECT reported: the barometer close-up has NO visible down/back exit chevron. User
  suspects it may be HIDDEN behind the inventory bar / the just-picked-up screwdriver
  inventory icon. User had to tap randomly at the close-up edges to exit; wants the exit
  arrow present for consistency with other close-ups.
- FOR THE FIX PASS TO CHECK (user explicitly asked): is the exit chevron missing entirely,
  or is it z-order/position-occluded by the inventory bar / a newly-added inventory item,
  specifically on the cu-barometer close-up.
- Narration only (not a defect): the slate close-up's "door at the end.")

### R8-002 — status: logged
> a closeup to the coat, i pick up the IV tablet, although it's in my inventory but i can also see it on the coat closeup still, that's another bug. i pickup the pocket watch, same issue, it is in my inventory but also didn't disappear from the coat. also no "down" arrow here too to go back to the main scene. i also noticed that after i picked up the pocket watch, the closeup whole image shifted to the left of the ipad screen, leaving a big black void on the right

(context — factual, no classification: Level 2 z1 v-bench COAT close-up (the two-pocket
collect — L2CoatControl; this was the critical build fix that made tile IV + watch A
obtainable). Build 15, iPad, Level 2.
- POSITIVE (working as reported): both pickups WORK — tile IV and the pocket watch (watch A)
  go to inventory, so the p01 path is reachable.
- DEFECT (1) STATE NOT REFRESHED: after collecting tile IV and the pocket watch, both STILL
  show in the coat close-up (pockets not emptied). Same "manual-pickup emptied-container /
  state-visual not refreshed after pickup" family as L1 round-4 (R4-013 / R4-012 /
  R4-020-thread-4). The coat close-up must show the emptied pocket(s) once collected.
- DEFECT (2) MISSING EXIT CHEVRON: the coat close-up also has no down/back arrow to return
  to the main scene — same as R8-001 barometer. Now appears SYSTEMIC across L2 close-ups,
  not a single view. Cross-ref R8-001.
- DEFECT (3) NEW iPad LAYOUT SHIFT: after picking up the pocket watch, the whole close-up
  image shifted LEFT on the iPad screen, leaving a big BLACK VOID on the right. A close-up
  positioning/relayout bug on iPad triggered by the pickup (possibly the close-up view
  re-centers/re-lays-out when an item node is removed; iPad-aspect specific).)

### R8-003 — status: logged (POSITIVE / progress narration — no defect)
> i picked up the II tablet. nothing else to inspect in this scene it seems, going right

(context — factual, no classification: Level 2 z1 v-bench, build 15, iPad. Progress
narration — the stove tile II (itm-tile-ii) pickup works; user finds nothing else to
inspect in v-bench and navigates RIGHT to the next view (v-master). No defect reported;
id retained for sequence.)

### R8-004 — status: logged
> i picked up the VII tablet and the VI tablet. inspecting the wall clock doesn't reveal much, missing back arrow again. i click randomly at the edges to go back. let's close up on the clock on the door, i see a VI tablet on the shelf under the clock but can't pick it up. there is also a VI button just above my inventory, which looks out of place . anyway, it seems those tablets fit on this clock, i place the II tablet in the right place, the clock takes it because it disappears from my inventory, but i don't see it visually. same issue after adding the IV tablet, and the VII tablet. i spam the VI tablet on the shelf trying to pick it up, doesn't work, so i click randomly to get out of the close up, then click it again to get into the closeup, try to pick it up, doesn't work. visually when i get out of the close up, i can see the tablets i placed on the clock, but when into the closeup, although i put them there already, i don't see them visually. that's another bug. let me go to the cat scene now to the right

(context — factual, no classification: Level 2 z1 v-master (master/wall clock) + z2 v-door
door-dial (p01). Build 15, iPad, Level 2. Multiple threads:
- POSITIVE / PROGRESS: VII and VI tablet pickups work; user places 3 of 4 p01 tiles
  (II / IV / VII) into the door dial — the puzzle ACCEPTS them (each disappears from
  inventory). Still needs XI (from the sill). Moving RIGHT to the cat scene.
- THREAD (1) MISSING BACK CHEVRON: the master/wall-clock close-up again has no down/back
  arrow — user clicks edges to exit. Systemic across L2 close-ups (cross-ref R8-001
  barometer, R8-002 coat).
- THREAD (2) DOOR-DIAL CLOSE-UP STATE-REFRESH: placing tiles II/IV/VII — p01 LOGIC works
  and the WIDE view DOES show the seated tiles, but the CLOSE-UP does NOT render the placed
  tiles (re-opening the close-up shows empty sockets though they're placed). So the
  close-up seated-tile state isn't rendered; wide vs close-up divergence. Same state-visual
  family as R8-002.
- THREAD (3) VI DECOY NOT PICKABLE: the loose VI tile on the tray/shelf under the door clock
  can't be picked up (user spammed it, re-entered the close-up, still no). FOR FIX PASS TO
  DETERMINE: is the tray VI meant to be COLLECTIBLE (design intent = pickable decoy that
  tempts the wrong placement, per p01 "rejected: tray VI in socket-4") or a NON-COLLECTIBLE
  decoy (like L1's demoted decoys)? Current behavior (can't pick up) is confusing either way.
- THREAD (4) STRAY UI: a "VI button just above my inventory that looks out of place" — a
  misplaced/leftover VI UI element/button near the inventory bar (rendering/placement bug);
  possibly the VI decoy rendered as an errant button.)

### R8-005 — status: logged
> found the xi tablet. then i try to get closeup on the cat, i can see part of the tablet i just picked up, it shouldn't be there. no back to main scene arrow. trying closeups and random clicks on cat, sunny house thing on the pillar, and door lock. nothing happens. i guess now the puzzles start

(context — factual, no classification: Level 2 z1 v-door (cat/sill/door scene). Build 15,
iPad, Level 2. Threads:
- POSITIVE / PROGRESS: the XI tile (itm-tile-xi, from the sill cu-sill-tile) pickup works —
  user now has all 4 p01 tiles (II / IV / VII / XI).
- THREAD (1) RENDER ARTIFACT: opening the CAT close-up (cu-cat-cushion) shows "part of the
  tablet i just picked up" (the XI tile) where it shouldn't be — a leftover tile/overlay
  fragment bleeding into the cat close-up. May relate to QA m4 ("cat-cushion clips the
  watch-B reveal") — same cushion close-up region, but here it's a stray XI-tile fragment.
  Art/overlay compositing.
- THREAD (2) MISSING BACK CHEVRON on the cat close-up (systemic; cross-ref R8-001/002/004).
- THREAD (3) "NOTHING HAPPENS" on tapping the CAT, the "sunny house thing on the pillar"
  (house-ring / sun glyph = cu-house-ring, a re-anchored hotspot), and the DOOR LOCK — no
  close-up / no response. FOR FIX PASS, determine PER ELEMENT whether by-design or defect:
  cat = p02 (needs the wind-up mouse, so no action yet may be intended, but a close-up/tell
  should still be reachable); door lock = endgame p11 timelock (not active yet — intended);
  house-ring = a CLUE close-up that SHOULD open (if tapping it does nothing, the re-anchored
  house-ring hotspot may be missing its close-up or mis-hit — verify, since house-ring was
  re-anchored in commit 203036a). User inferred "now the puzzles start.")

### R8-006 — status: logged (POSITIVE / milestone — no defect)
> ok now that i have the last tablet, let me open that clock on the door, i put it in place and the door opens. i go in.

(context — factual, no classification: Level 2 z2 v-door → z2 interior. Build 15, iPad,
Level 2. MILESTONE: placing the XI tile completes p01 (numeral-tile door II/IV/VII/XI at
sockets 2/4/7/11), the door OPENS, and the user enters z2. Confirms the critical build-15
fixes work end-to-end on iPad — the coat two-pocket collect (tile IV + watch A, previously
unobtainable → L2 uncompletable) and the re-anchored hotspots — so p01 is now solvable on
iPad, the exact thing that was broken. Despite the R8-004 door-dial close-up state-refresh
bug (placed tiles not shown in the close-up), the puzzle still completes. No new defect;
positive progress narration, id retained for sequence.)

### R8-007 — status: logged
> two closeups immediately inside, the gear with numbers and the wooden toy thing on the wall. these are puzzles i don't have answers for yet. oh there is something else on the wall, a sunny gear. all those closeups don't have the back arrow

(context — factual, no classification: Level 2 z2 interior (v-frame). Build 15, iPad,
Level 2.
- PROGRESS: user finds the z2 puzzle elements — "the gear with numbers" (the gear-frame /
  p06 gear-train puzzle, cu-gear-frame), "the wooden toy thing on the wall" (the
  mural/automaton), and "a sunny gear" (the sun-gear glyph clue). All correctly read as
  puzzles the user has no answers for yet (gated — expected at this point).
- DEFECT MISSING BACK CHEVRON on all these z2 close-ups too — confirms the missing-exit-arrow
  bug is SYSTEMIC across the ENTIRE level (z1 + z2), every close-up (cross-ref R8-001
  barometer, R8-002 coat, R8-004 wall-clock, R8-005 cat). No new defect beyond the chevron
  here; the rest is progress narration.)
