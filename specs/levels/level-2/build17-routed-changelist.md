# Build 17 — Routed Changelist (Level 2, Round 8 late items on build 16)

_Feedback Intake Agent, 2026-08-07. Source: `specs/feedback-backlog.md` → "Round 8 — LATE
ITEMS ON BUILD 16" (R8-014..R8-022 + R8-completion, with all appended clarifications and
three screenshot confirmations). This is the routed artifact for the Producer. I classify
and route only — the owning agent does the work._

## ⛔ CHECKPOINT GATES (Producer: pause here)
- **GATE 1 — pre-execution:** user reviews THIS changelist before any fix work starts. Three
  decisions are required at this gate (§4). Only their own items are blocked; the rest of the
  batch proceeds.
- **GATE 2 — post-QA:** user reviews QA's **screenshot-based** regression results before any
  re-release. Standing rule: state/inventory/collect behaviour is verified from rendered
  screenshots, never engine flags alone.

## 0. Headline

**Level 2 was cleared end-to-end on build 16.** There is **no progression blocker in this
batch** — severity ceiling is major. The build-15 P0 (cushion) and Clusters A (close-up
state) and B (back chevron) are **device-confirmed fixed**, as are the manual pickups and the
cat's refusal tell. What remains is rendering quality, close-up/wide interaction parity, and
one large **design** question about clue legibility.

## 1. Prioritized item table

| Pri | Item IDs | Defect (one line) | Class / Sev | Cluster | Target agent | Proposed regression scope (QA has final say) |
|---|---|---|---|---|---|---|
| **P1** | R8-020(1) | Great-dial hands render as placeholder strokes **and** the minute hand does not pivot from the hub — the p09 clock is hard to read | bug + art decision / major | **P** | Developer (anchor) + **Art Director** (style decision) | Targeted z3 + **full endgame chain** (p08/p09/p10 → release) |
| **P1** | R8-020(2) | "Double pendulum": flat procedural bob swings while the painted brass pendulum stays visible to its right | bug + art decision / major | **P** | Developer (rect/staging) + **Art Director** (style decision) | Targeted z3 wide + p10 |
| **P1** | R8-015 | Mouse cannot be placed from the cat close-up (wide only) — the close-up tap is hardcoded to the wrong hotspot | bug / major | **Q1** | Developer | **FULL** — shared close-up interaction routing |
| **P1** | R8-018 | Oil can cannot be collected from the brick close-up (wide only) — cache close-ups implement *pry* only, no *collect* | bug / major | **Q2** | Developer | **FULL** — parity audit of all collect/place/use targets |
| **P1** | R8-021 | z4 key/tag close-up still shows the stale key after collection; the 22-row render guard did not catch it | bug / major | **R** | Developer + QA (guard coverage) | **FULL** — close-up state + guard table |
| **P1** | R8-017 | Oiling the arbor gives an audio ping but **no visible change** — the applied tool leaves the scene identical | bug / major | **R** | Developer (verify render) → Art Director (strengthen) | Targeted p05 + a sweep for other "audio-only success" states |
| **P2** | R8-019 + R8-020 +/− buttons | Crank affordance reads as a **refresh/reload** icon; dial uses flat white +/− chrome buttons — UI idiom in a diegetic painterly scene | polish | **S** | **Art Director** (affordance direction) + Developer | Targeted |
| **P2** | R8-016 | Cat's tell is not perceived as mouse-exclusive — user wants non-mouse offers inert | **design change** | **T** | Theme & Puzzle Designer (D3/D4 grammar) + Developer | Targeted p02 + Blind Playtester spot-check |
| **P2** | R8-014 | Toy mouse composites **outside/above** the open drawer, floating | bug / minor | **R** | Developer or Asset-Gen (offset ownership TBD) | Targeted |
| **P2** | R8-022 | Dark rectangular seam box behind the seated winding key in the drum close-up | bug / minor | **R** | Asset-Gen (re-blend) or Developer (re-register) | Targeted |
| **P2** | R8-017 jargon | Walkthrough says "arbor bearing" — user did not know what it meant | polish (docs) | — | Documentation | — |
| **BLOCKED** | R8-completion + R8-009 | 4 of the level's core beats needed the walkthrough (p06 ratios, p02 mouse, p09 mirror, p03 cache) — clue legibility under-delivering vs the 6.5 fair-clue target | **balance / design** | — | Theme & Puzzle Designer + **MANDATORY Blind Playtester re-check** (+ Validator if the graph changes, + Documentation) | Targeted per beat + full blind re-solve |
| — | R8-020 gating | "Should the pendulum start on a single early click?" | — | — | **closed — working as designed** | — |

**POSITIVE — DO NOT REGRESS.** Level cleared end-to-end. Close-up state rendering ("closeups
are fine"), the back chevron ("arrow is fine now"), the cat refusal tell, the z4 manual
pickups, p06 gear train, the panel, and the full endgame chain all work on device.

## 2. Corrections to the Producer's clustering read

Independent code verification changed three of the five clusters. These matter because they
change **who owns the fix**.

### 2.1 Cluster P is a decision, not a wiring bug
The procedural rendering is a deliberate, documented build-16 choice —
`EscapeRoom/EscapeRoom/Game/RoomScene.swift`:

> "These are drawn PROCEDURALLY (SKShapeNode rod + bob), consistent with L2's other moving
> parts being rendered procedurally (the mirrored clock hands are SwiftUI capsules) rather
> than from bespoke sprite art."

So the flat mustard bob and the dark hand strokes **are** the intended code path, not
unstaged assets. Cluster P therefore splits:
- **P-decision (Art Director + user):** keep procedural and restyle it to sit in the
  painterly scene, or adopt authored sprite art. Cost/scope differ; **not my call**.
- **P-bug (Developer, true either way):**
  - The `ov-pendulum-absent` suppression **is** invoked — `Level2Coordinator` sets it
    whenever `pendulumSwinging` and `pendRect != .zero`, and since the swing renders at all,
    that branch demonstrably ran. So "the overlay isn't applied" is wrong. The painted
    pendulum surviving **to the right** of the animated one points at the absent-patch
    **rect being mis-registered against the current plate**, or `ov-pendulum-absent-wide` not
    being staged. Same family as the L1 R7-001 stale-rect bug — measure image dims vs rect.
  - The minute hand **not pivoting from the hub** is a straight anchor bug, independent of
    the style decision.

### 2.2 Cluster T — discrimination already fires; this is a design change
`Level2Engine.offerItemToCat` is
`itemID == Level2Graph.ItemID.toyMouse ? .mouseTell : .refusal`, and the UI composites
different layers (`ov-cat-mouse-tell` + tail-flick vs `ov-cat-slow-blink`). The code path is
correct — the two reactions simply **read alike at play scale** (both are eye-state changes).

That reclassifies R8-016 from bug to **design change**, and it **conflicts with an approved
decision**: rev-1.3 playtest tweak 2 deliberately gave non-mouse items the slow blink. The
user is entitled to override their own earlier approval, but it must be **confirmed** and the
D3/D4 grammar updated in the puzzle graph — not silently coded. See §4.

### 2.3 Cluster Q has two distinct roots
Both verified in `EscapeRoom/EscapeRoom/UI/Level2RoomView.swift`. One audit, two fixes:
- **Q1 (R8-015):** the cushion close-up hardcodes a single hotspot id —
  `coordinator.useItem(armed, on: "cat-cushion")` — while p02's placement verb lives on the
  **sibling** hotspot `cat-floor` (`Level2Coordinator`: `case (.door, "cat-floor")` runs
  `placeMouseAtCat`; `case (.door, "cat-cushion")` only returns the tell). From the close-up
  the armed mouse can therefore *only* produce the tell — placement is structurally
  unreachable. This is exactly what the user hit.
- **Q2 (R8-018):** `L2CacheControl.onPlateTap` is guarded to one verb —
  `guard interaction.armedItem == Level2Graph.ItemID.screwdriver else { return }` — so the
  cache close-up implements *pry* only and has **no collect target** for the revealed item.

**Generalize the fix** per the user's directive: once an interaction's gate is satisfied it
should work from **both** the wide view and the close-up. Audit every collect/place/use
target rather than patching these two.

## 3. Sequencing insight — read before acting on the difficulty verdict

Two of the four "guide-mandatory" beats have **rendering confounds** that plausibly caused
the illegibility:
- **p09 (mirror derivation)** is read off a dial whose hands render as **mis-anchored
  placeholder strokes** (R8-020(1)). The player may have been asked to derive a time from an
  unreadable clock.
- **p02 (mouse behaviour)** had placement **structurally unreachable** from the close-up (Q1)
  and a tell that reads **identically to every refusal** (T).

**Recommendation: land P, Q and T first, then re-measure p09 and p02 with the Blind
Playtester before redesigning them.** A design change made now would be calibrated against
broken rendering. **p06 (gear ratios)** and **p03 (cache location)** have no such confound
and are genuine design items.

This is a **sequencing recommendation only**. The difficulty direction is the user's call —
I am not proposing any numeric or design tweak, per the balance rule.

## 4. Decisions required at GATE 1 (I will not choose these)

1. **R8-020 — sprite vs procedural.** Adopt authored sprite art for the pendulum bob and dial
   hands, or keep procedural and restyle it to match the painterly scene? Reverses a
   documented build-16 decision and may carry asset cost — Producer should confirm with
   Asset-Gen whether suitable cutouts already exist (if they do, expect **$0**).
2. **R8-016 — confirm the override.** The directive "only the tin mouse gets a reaction"
   reverses approved rev-1.3 playtest tweak 2 (slow-blink refusal for other items). Confirm,
   and note the tradeoff: a fully inert cat may read as unresponsive rather than as a
   deliberate signal. If confirmed, the Designer updates D3/D4 in the graph before the
   Developer implements.
3. **R8-completion / R8-009 — difficulty direction.** Which of the four beats do you want
   made more legible, and how far? Options span "clue-art legibility only" → "add an
   intermediate clue" → "simplify the inference." **Any change requires a Blind Playtester
   re-check**, and per §3 I'd recommend deciding p09 and p02 *after* the render fixes land.

## 5. Order of operations (Producer)

Re-entry, not a restart.

1. **GATE 1** — user approves this changelist and answers §4. (Pause.)
2. **DEV track (Developer)** — Q1 + Q2 parity audit (largest blast radius, do first) →
   R8-021 z4 close-up state + close the guard coverage gap → R8-017 verify the arbor-oiled
   overlay actually renders in both views → R8-020 anchor/rect bugs (hub pivot;
   `ov-pendulum-absent` registration/staging) → R8-014 offset → R8-019/R8-020 affordance
   implementation once the Art Director's direction lands.
3. **ART track (parallel, Art Director)** — the §4.1 style decision; diegetic affordance
   direction for crank and +/− (Cluster S); strengthen the arbor-oiled visual if R8-017 turns
   out to be "renders but too subtle"; R8-022 re-blend and R8-014 offset if those prove to be
   art-owned rather than code-owned.
4. **DESIGN track (parallel, only for p06 and p03; p09 and p02 deferred per §3)** — Theme &
   Puzzle Designer on clue legibility → Validator if the graph changes → **Blind Playtester
   re-check (mandatory)**.
5. **Documentation** — "arbor bearing" plain-language gloss; reconcile the walkthrough with
   whatever the design track changes.
6. Assemble build 17 → CI green.
7. **QA (screenshot-based)** — scope in §6. QA has final say.
8. **GATE 2** — user reviews QA screenshots → re-release.

**Dependencies:** Cluster S implementation waits on the Art Director's direction. The p09/p02
design work waits on the P/Q/T fixes (§3). Everything else is parallel.

## 6. Proposed regression scope — **FULL QA regression, screenshot-based**

Cluster Q changes shared close-up interaction routing across the level, and Cluster R touches
close-up state rendering plus the render guard — cross-zone reach on core systems, so a full
pass is warranted. Specifically require:
- A **full end-to-end playthrough** — the level is now completable and that path must not
  regress. This is the primary assertion.
- **Close-up/wide parity matrix:** for every collect/place/use target, prove the interaction
  succeeds from **both** views once its gate is satisfied (the user's standing directive).
- Screenshots of each close-up pre-collect, partial and post-collect, including **z4 key/tag**
  (R8-021's guard gap) — and extend the 22-row guard table to cover the missing rows.
- z3 endgame visual pass: dial hands anchored at the hub and legible enough to *read a time
  from*, single pendulum (no painted survivor), no seam box behind the seated key.
- Confirm every "applied tool" produces a **visible** change, not audio alone (R8-017 class).

QA has final say on what actually executes.

## 7. Post-release delta (Producer to apply — single-writer files)

**`specs/progression-ledger.md`** (append):
> Post-release feedback round 8 late batch (Level 2, build 16, processed 2026-08-07). Level 2
> **cleared end-to-end on device** — the build-16 fix set held. **No difficulty rescore yet;**
> Level 2 holds Validator-official 6.5 (z1 5.0 · z2 7.0 · z3 7.0 · z4 3.5). A rescore is
> PENDING a user decision: the player reported the level was not completable without the
> walkthrough, naming four guide-mandatory beats — p06 gear ratios, p02 mouse behaviour, p09
> mirror transform, p03 cache location. Failure pattern is multi-step inference; single-lookup
> clue-chains (p01, p04 post-clue, p05, p07, p10/p11) landed. Note p09 and p02 have rendering
> confounds (mis-anchored dial hands; close-up placement unreachable) — re-measure with the
> Blind Playtester after the render fixes before rescoring. Mechanics touched this round are
> render/interaction, not logic: close-up↔wide interaction parity (close-up taps were
> hardcoded to one hotspot id and cache close-ups implemented pry only), z4 close-up
> taken-state, procedural mechanism rendering (pendulum, dial hands) and its overlay
> registration, plus affordance-idiom polish. One approved-design reversal pending user
> confirmation: R8-016 would make the cat's tell mouse-exclusive, overriding rev-1.3 playtest
> tweak 2. Art spend this round **decision-dependent** — $0 if the existing sprite cutouts
> cover the R8-020 style decision; scope with Asset-Gen if not.

**`specs/project-state.md`** (new resume entry):
> Post-release feedback round 8 LATE batch (build 16) processed 2026-08-07, branch
> `level2-clockmakers-attic`. Routed changelist:
> `specs/levels/level-2/build17-routed-changelist.md`. **Level 2 cleared end-to-end on iPad**
> — build-15 P0 (cushion) and Clusters A/B device-confirmed fixed; no progression blockers
> remain. Build-17 scope: Cluster Q close-up↔wide interaction parity (two roots: close-up taps
> hardcoded to a single hotspot id, and cache close-ups implementing pry with no collect),
> Cluster R remaining stale/mis-rendered states (z4 key/tag close-up + render-guard coverage
> gap, arbor-oiled invisible, drawer-mouse offset, key seam box), Cluster P z3 mechanism
> rendering (procedural bob/hands — mis-registered absent-overlay and hub pivot; the
> sprite-vs-procedural style choice is a GATE-1 user decision), Cluster S diegetic affordance
> direction (crank reads as a refresh icon; dial +/− chrome). Cluster T (cat tell exclusivity)
> is a design change that reverses approved rev-1.3 tweak 2 — user confirmation required. The
> big open item is the clue-legibility verdict (4 guide-mandatory beats) — BLOCKED on a user
> difficulty decision, with a mandatory Blind Playtester re-check, and recommended to be
> measured only after the P/Q/T render fixes land. GATE 1 pending user; GATE 2 (screenshot QA)
> before re-release.

## 8. Open questions for the user
1. **R8-020** — authored sprites or restyled procedural rendering for the pendulum and dial
   hands?
2. **R8-016** — confirm the override of approved rev-1.3 tweak 2 (non-mouse offers become
   inert); note the "cat feels unresponsive" tradeoff.
3. **R8-completion / R8-009** — difficulty direction for the four guide-mandatory beats, and
   do you accept the §3 recommendation to decide p09 and p02 *after* the render fixes?
4. **Non-blocking:** R8-014 and R8-022 — Producer to determine offset/seam ownership (art
   plate vs overlay rect) before assigning; no user input needed.
