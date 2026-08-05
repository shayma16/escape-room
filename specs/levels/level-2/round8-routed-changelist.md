# Round 8 — Routed Changelist (Level 2 "The Clockmaker's Attic")

_Feedback Intake Agent, 2026-08-05. Source: `specs/feedback-backlog.md` Round 8
(R8-001..R8-013), TestFlight "Within 1.0 (15)", build 15, iPad, Level 2 first-time
playthrough. This is the routed artifact for the Producer. I classify and route only —
the owning agent does the work._

## ⛔ CHECKPOINT GATES (Producer: pause here)
- **GATE 1 — pre-execution:** user reviews THIS changelist before any fix work starts.
  Three open questions below must be answered at this gate (one of them, R8-009, is a
  difficulty call and blocks only its own item — the rest of the batch can proceed).
- **GATE 2 — post-QA:** user reviews QA's **screenshot-based** regression results before
  any re-release. Standing project rule (R6-009 / R2-META-QA): state, inventory and
  collect behaviour are verified from rendered screenshots, never engine flags alone.

## 0. RELAY TO THE USER FIRST — the playthrough is probably not blocked

The user stopped at R8-013 ("i guess i can't continue the game now"). Code reading says
they are **not actually soft-locked**:

```swift
// Level2Engine.swift — placeMouseAtCat
state.markSolved(Level2Graph.PuzzleID.catMouse)
state.removeItem(Level2Graph.ItemID.toyMouse)
state.addItem(Level2Graph.ItemID.watchB)          // revealed under the lifted cushion
```

Watch B is **auto-granted the instant p02 solves**, and R8-011 confirms p02 solved (the cat
left the wide view). There is no cushion-lift step in the build at all. So watch B should
already be sitting in the inventory bar and the user can continue at the z2 chimney (p04)
right now. Developer/QA to confirm on device. This does not reduce the severity of R8-013 —
the walkthrough describes an interaction that does not exist, and the close-up actively
contradicts the wide view.

## 1. Prioritized item table (severity-first)

| Pri | Item IDs | Defect (one line) | Class / Sev | Root cluster | Target agent | Proposed regression scope (QA has final say) |
|---|---|---|---|---|---|---|
| **P0** | R8-013(1) | Cushion close-up shows the cat post-p02 and has **no lift/collect interaction**; walkthrough tells the player to lift it → player believes the game is unfinishable | bug / **critical** | **A-crit** | Developer + Documentation | **FULL** — close-up render path + p02/p04 chain, cross-zone reach |
| **P1** | R8-002(1), R8-004(2), R8-010 (R8-009(2) merged), R8-011(2), R8-012, R8-013(2), R8-005(1) | Close-ups render a static plate: collected items, seated tiles, pried boards and placed mouse never appear/disappear in the close-up (the **wide view is correct**) | bug / major | **A** | Developer | **FULL** — shared close-up rendering, every zone |
| **P1** | R8-001, R8-002(2), R8-004(1), R8-005(2), R8-007 | No visible back/down chevron on **any** L2 close-up — it is drawn underneath the inventory bar; players escape by tapping the backdrop | bug / major | **B** | Developer | **FULL-sweep** — shared chrome; screenshot every close-up in the level |
| **P1** | R8-002(3) | On iPad, the close-up plate jumps left leaving a large black void on the right after the last item in it is collected | bug / major | **C** | Developer | Targeted-but-broad — every close-up with conditional positioned children |
| **P1** | R8-004(3)+(4) **[merged]** | Tray-VI decoy is a floating text button near the inventory instead of a tap region on the VI tile drawn in the plate → looks like stray UI **and** the depicted tile is uninteractable | bug / major | **D** | Developer + Validator (light) | Targeted — p01 close-up + confirm no solve path uses the decoy |
| **P1** | R8-011(1) | Cat's mouse-specific tell (approved rev-1.3 tweak 2) ships as **sound only**; the eye-lock/tail-flick was deferred, so a correct idea reads as "broken" | bug (spec-not-delivered) / major | — | Developer + Designer consult | Targeted — p02 + **Blind Playtester spot-check of the tell's legibility** |
| **P2** | R8-009(1) | p03 dormer cache unsolvable for the user **even with the walkthrough open**; clue→location mapping does not land | **balance / design** | — | **Theme & Puzzle Designer + Blind Playtester re-check** + Documentation | Targeted + blind re-check; Validator if the graph changes |
| **P2** | R8-008(3) | L2 close-ups are ~80% crops of the wide plate — they reveal nothing new and feel valueless | polish (art quality) | — | Art Director (+ Asset-Gen only if re-crops are approved) | Targeted |
| **P2** | R8-008(4) | Sealed display case reads as "should open"; it is sealed by design | polish / minor | — | Art Director | Targeted |
| **P2** | R8-005(3) | Taps on cat / house-ring / door-lock "do nothing" — per-element by-design vs defect sweep | bug (verify) / minor | — | Developer + Validator (light) | Targeted |
| **P3** | R8-008(2) | "Clicking the clocks doesn't do much" — insufficiently specific to route | **needs-clarification** | — | user | — |
| — | R8-011(3) | Cat vanishes instead of animating a chase (known deferred animation) | polish | — | **parked** (Producer) | — |

**POSITIVE — DO NOT REGRESS.** R8-003, R8-006, R8-008(1), R8-011(3): p01, p02 and p03 all
complete on device. The build-15 critical fixes are **device-confirmed**: the coat
two-pocket collect (tile IV + watch A were previously unobtainable → L2 was uncompletable)
and the re-anchored barometer/house hotspots. p01 opens the door end-to-end. Do not
refactor the coat collect or the hotspot anchors beyond what Cluster A/C require.

## 2. Root-cause clusters (fix each root ONCE)

### Cluster A — Close-up state overlays never render → Developer, code
L2 close-ups render **one static plate per close-up id**. `Level2Visuals` composites the
per-element state overlays (`ov-cushion-reveal`, `ov-cushion-empty`, …) into the **wide**
scene only; no close-up consumes them. Hence every symptom in this cluster: coat items
persist after collect, seated dial tiles never appear, the pried floorboard never opens,
the placed mouse is invisible, the cushion still shows a departed cat, and the sill
close-up still shows a collected XI tile.

Worst instance, and the P0 blocker, in `EscapeRoom/EscapeRoom/UI/Level2RoomView.swift`:

```swift
private struct L2CatCushionView: View {
    @ObservedObject var coordinator: Level2Coordinator
    private var image: String {
        coordinator.state.hasSolved(Level2Graph.PuzzleID.catMouse) ? "cu-cat-cushion" : "cu-cat-cushion"
    }
    var body: some View {
        GameImage(name: image).aspectRatio(contentMode: .fit).padding(24)
            .accessibilityIdentifier("cat-cushion")
    }
}
```

Both ternary branches are the same asset, and the view has **no tap target whatsoever** —
so there is no cushion-lift affordance and watch B is instead auto-granted by
`placeMouseAtCat`. Fix generally, not per-close-up: close-ups must resolve their plate and
overlays from `GameState` the way the wide view already does.

- **Note for the Developer:** the resolved-state art largely **already exists** (the
  overlays are authored and used by the wide view) → expected art spend **$0**.
- **Auto-grant vs manual pickup:** the watch-B auto-grant contradicts the standing L1
  principle (F-023 / R2-003, user-directed): revealed items are picked up deliberately, not
  auto-granted. Restoring the cushion-lift → tap-watch-B step satisfies both R8-013 and that
  principle. **Producer: confirm at GATE 1** that we restore the manual pickup rather than
  merely fixing the image, since it changes an interaction the user has opinions about.
- **Guard:** extend the rendered-frame guard to assert **every** close-up's
  pre/partial/post-collect state, mirroring the L1 round-6 Cluster-A guard work.

### Cluster B — Close-up dismiss chevron is under the inventory bar → Developer, code
In `L2CloseUpHost`, close-up content receives `.padding(.bottom, bottomInset)`
(`bottomInset = barHeight`, 72pt on iPad) but the dismiss chevron receives only
`.padding(.bottom, 12)`; and in the parent ZStack `InventoryBarView` is added **after**
`L2CloseUpHost`, so it paints over it. The chevron exists and is simply occluded — the
user's own hypothesis in R8-001 ("is it hidden under the inventory screwdriver i just
picked?") was correct. One fix (inset the chevron above the bar and/or raise the close-up
host's z-order) resolves all five reports. The backdrop's
`.onTapGesture { dismissCloseUp() }` explains the edge-tap escape the user resorted to.
Verify the chevron's contrast against L1's round-1 F-025 visibility ruling while there.

### Cluster C — iPad close-up layout collapse → Developer, code
`L2CoatControl` is a `GeometryReader { ZStack { … } }` whose only full-size children are
the **conditional** positioned pocket buttons. When the last uncollected pocket button is
removed the ZStack shrinks to the fitted image and GeometryReader re-places it
**top-leading** → the plate jumps left and a black void opens on the right, exactly as
reported. Audit every close-up control built on this pattern (coat, dial door, caches), not
just the coat.

### Cluster D — Tray-VI decoy affordance → Developer + Validator (light)
```swift
Button(action: { trayVISelected.toggle() }) {
    Text("VI").font(.title3).padding(8)
        .background(Circle().fill(trayVISelected ? Color.orange.opacity(0.5) : Color.black.opacity(0.4)))
        .foregroundColor(.white)
}
.position(x: plate.midX, y: plate.maxY - 20)
```
This single element is **both** halves of R8-004: the out-of-place "VI button above the
inventory" and the reason the VI tile drawn on the tray can't be interacted with. Design
intent (puzzle-graph summary, p01) is a *selectable glyph-order bait* on the tray — never an
inventory item (standing R6-003 principle). Spec-determined, so **no user decision needed**:
move the tap target onto the depicted tray tile and drop the floating button. Validator
confirms no solve path references the decoy.

## 3. Items that are NOT mine to decide — surface at GATE 1

### R8-009 — p03 difficulty / clue clarity → Theme & Puzzle Designer + Blind Playtester
The user could not solve p03 **with the walkthrough open** and had to random-click. Per the
binding rule, a difficulty complaint never goes straight to implementation as a blind tweak:
it routes to the Designer **with a Blind Playtester re-check** of whatever change lands.
This also confirms Documentation's second-pass discrepancy #1 — the intended
"clock-hand-as-pointer" spatial beat (watch A hand on III + the ⌂ ring → third floorboard
right) is **collapsed** in the as-built into a single always-correct cache hotspot gated only
on the watch clue, so there is nothing for the clue to point *at*.

**Question for the user (I will not choose):**
(a) restore the intended spatial beat — the ring/hand actually select which board pries; or
(b) keep the collapsed single cache and instead strengthen the clue/tell so the location
reads; or (c) treat it as acceptable difficulty and fix only the walkthrough step.
Documentation must fix the walkthrough's p03 step under any option; note that the same
collapsed pattern applies to **p04** (chimney), so whatever is chosen should apply to both.

### R8-008(2) — needs clarification
"Clicking the clocks on the wall doesn't do much really" is not specific enough to route.
**Ask the user:** does tapping a world-clock open a close-up at all, or does nothing happen?
If a close-up opens, is the complaint that it is not *useful* (in which case it folds into
R8-008(3)'s close-up-value item) rather than broken?

### NEW observation — near-wordless genre consistency
The as-built p01/p06 close-ups use literal text UI: a `Text("VI")` button, and "Rack",
"Crank", "Post A"/"Post B" labels in the gear frame. CLAUDE.md fixes the genre as
**near-wordless**. This is a creative call, not a bug — **ask the user** whether these
should be replaced with wordless affordances, ideally scoped alongside the R8-008(3)
close-up art pass. Not routed pending that answer.

## 4. Order of operations (Producer)

Re-entry, not a restart — only the agents below are re-invoked; no full per-level rerun.

1. **Relay section 0** to the user immediately (they have stopped playing believing L2 is
   dead; they can most likely continue).
2. **GATE 1** — user approves this changelist and answers the three open questions. (Pause.)
3. **DEV track (Developer, code)** — the whole batch is code, so it is largely serial in one
   agent: Cluster A (close-up state resolution, **P0 cushion first**, incl. the manual
   watch-B pickup if approved) → Cluster B (chevron inset/z-order) → Cluster C (layout) →
   Cluster D (tray VI) → R8-011(1) cat tell → R8-005(3) dead-tap sweep → guard extensions.
4. **DESIGN track (parallel, only if the user picks (a) or (b) on R8-009)** — Theme & Puzzle
   Designer reworks p03/p04 clue-to-location; **Validator** re-checks the graph if it
   changes; **Blind Playtester** re-checks the difficulty of the result. Do not let this
   block the DEV track.
5. **ART track (parallel)** — Art Director on R8-008(3) close-up value and R8-008(4) sealed
   case read. Asset-Gen only if the Art Director approves re-crops; expected spend **$0** for
   Clusters A–D since the state overlays already exist.
6. **Documentation** — walkthrough fixes for the cushion/watch-B step (mandatory, it is
   currently wrong) and for whatever R8-009 resolves to.
7. Assemble build → CI green.
8. **QA (screenshot-based, player-style)** — see scope below. QA has final say.
9. **GATE 2** — user reviews QA screenshots → re-release.

**Dependencies:** Cluster A before QA (everything else is cosmetic by comparison).
Documentation's walkthrough fix depends on the R8-009 decision. Art track is independent.

## 5. Proposed regression scope — **FULL QA regression, screenshot-based**

This batch rewrites the shared close-up rendering path, the shared close-up chrome, and the
close-up layout container — cross-zone reach across all four zones, plus a change to the
p02→p04 item chain if the manual watch-B pickup is restored. That is squarely "shared state
/ core systems" territory, so a full pass is warranted. Specifically require:
- A full L2 playthrough capturing **screenshots** of each close-up in its pre-collect,
  partial and post-collect states, asserting what a human sees (the L1 lesson: scripted taps
  hitting invisible rects mask exactly these defects).
- Every close-up screenshotted with the inventory bar populated, to prove the chevron is
  visible and not occluded.
- The p02 → cushion → watch B → p04 chimney chain end-to-end, confirming watch B is
  obtainable **and** that the cushion close-up shows the post-p02 state.
- The alternate-order legality sweep for multi-use tools (screwdriver), per the standing
  R6-009 rule.

QA has final say on what actually executes.

## 6. Post-release delta (Producer to apply — single-writer files)

**`specs/progression-ledger.md`** (append):
> Post-release feedback round 8 (Level 2, build 15, processed 2026-08-05). **No difficulty
> rescore yet** — Level 2 holds Validator-official 6.5 (z1 5.0 · z2 7.0 · z3 7.0 · z4 3.5)
> pending the R8-009 p03 decision; if the clue-to-location beat is reworked, re-score z1 and
> re-run the Blind Playtester before updating this line. Mechanics touched this round are
> render/UX, not logic: close-up state-overlay resolution (close-ups previously rendered
> static plates while the wide view composited correctly), close-up dismiss-chevron z-order,
> iPad close-up layout, and the tray-VI decoy affordance. One interaction-model item pending
> user approval: restore the manual cushion-lift pickup for watch B (currently auto-granted
> on p02 solve, which contradicts the standing manual-pickup principle from L1 F-023/R2-003).
> Expected art spend this round **$0.00** — the resolved-state overlays already exist; any
> spend would come only from an approved R8-008(3) close-up re-crop pass.

**`specs/project-state.md`** (new resume entry):
> Post-release feedback round 8 processed 2026-08-05 — first Level 2 device round (TestFlight
> "Within 1.0 (15)", iPad, branch `level2-clockmakers-attic`). Routed changelist:
> `specs/levels/level-2/round8-routed-changelist.md`. Build-15 critical fixes are
> device-CONFIRMED (coat two-pocket collect + re-anchored hotspots; p01/p02/p03 all solved on
> device). Four Developer clusters routed: A close-up state-overlay rendering (contains the
> P0 — cushion close-up is stale and has no lift interaction, so the user believed L2 was
> unfinishable; watch B is in fact auto-granted at p02 solve, so no true soft-lock), B
> close-up dismiss chevron occluded by the inventory bar, C iPad close-up layout collapse, D
> tray-VI decoy affordance; plus the undelivered rev-1.3 cat mouse-tell. Design item R8-009
> (p03 under-clued even with the walkthrough; confirms Documentation discrepancy #1) is
> BLOCKED on a user difficulty decision at GATE 1 and carries a mandatory Blind Playtester
> re-check. Art items (close-up crop value, sealed-case read) with Art Director. GATE 1
> (changelist review) pending user; GATE 2 (screenshot-based QA) before re-release.

## 7. Open questions for the user
1. **R8-009 p03 difficulty** — option (a) restore the spatial beat / (b) strengthen the clue
   on the collapsed cache / (c) accept and fix only the walkthrough. Applies to p04 too.
2. **R8-008(2)** — do the world clocks open a close-up at all, or is the tap dead?
3. **Near-wordless consistency** — replace the "VI"/"Rack"/"Crank"/"Post A/B" text UI with
   wordless affordances?
4. **Confirm (non-blocking):** restore the manual cushion-lift pickup for watch B rather
   than keeping the auto-grant, per the standing manual-pickup principle.
5. **Merges (non-blocking, confirm):** R8-009(2) merged into R8-010 (R8-010 kept — it carries
   the wide-vs-close-up diagnostic); R8-004(3) merged with R8-004(4) (one element).
