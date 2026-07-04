# Multi-Agent Escape Room Game — Claude Code Build Brief

## Project Summary

Build a multi-agent Claude Code subagent system that produces a neutralxe/Neutral-style
point-and-click escape room game for iOS (iPad-primary, iPhone-compatible), from theme
input through App Store submission.

**Genre reference**: neutralxe.net's Room Escape series (Vision, RGB, Elements, Sign, etc.)
— static rendered/painterly interior scenes, single "camera view" per area, minimal-to-no
dialogue, atmosphere carried entirely by visuals and theme, puzzles built on hidden items,
environmental clues, cipher/code logic, and item combination. Complexity should scale up to
Elements-level (multi-area, Myst/Riven-comparable) as levels progress.

**Tech stack**: Swift + SpriteKit for interactive room scenes, SwiftUI for UI chrome
(inventory bar, menus, hint-free static walkthrough is separate from in-app UI). iOS 17+
floor. iPad-primary layout, iPhone-compatible as a secondary adapted layout.

**Business model**: Free, no in-app purchases at launch (structure the codebase so IAP
could be added later without a rearchitect, but do not implement it now).

**Art pipeline**: Flux 2 Pro via the fal.ai API (pay-as-you-go, no subscription), called
programmatically from the Asset Generation Agent. Do not use Midjourney (no practical API
for individuals) or Claude Design (code/UI-prototyping tool, not a painterly still-image
generator) for scene art. Claude Design may optionally be used later for UI chrome
prototyping only.

---

## Core Operating Principles (apply to every agent)

1. **Ask, don't assume.** Any agent that hits ambiguity, underspecification, or a genuine
   judgment call must surface it back to the Producer/user rather than silently deciding.
   This applies especially to puzzle difficulty calibration, real-world-knowledge fairness,
   and any implementation detail not explicitly covered by an upstream spec.
2. **Checkpoint-based, human-in-the-loop.** The user reviews and approves output at defined
   checkpoints (see Pipeline Sequence below) before downstream agents consume it. Agents do
   not silently proceed past a checkpoint.
3. **Static, fixed solution values.** Puzzle codes/answers do not randomize per playthrough.
   The same solution is correct every time.
4. **Multiple valid solve paths are allowed.** Game state must track "has requirement X been
   satisfied," not "did the player do step 1 then step 2," so alternate valid orderings don't
   break progression.
5. **Real-world-knowledge puzzles are allowed and encouraged**, calibrated to what a
   reasonably curious, generally-educated adult would recognize — including theme-adjacent
   "famous enough" facts (e.g. Orion's Belt, E=mc², basic periodic table elements) — but not
   specialist/niche knowledge. Anything borderline gets flagged at checkpoint, not guessed.
6. **No hard difficulty ceiling.** Puzzles should be challenging even at level 1, and should
   escalate in difficulty and puzzle-chain complexity across subsequent levels, informed by
   the cross-level progression ledger (see below).
7. **Nested hidden zones are a core structural feature**, not an edge case — levels can and
   should include areas (a hidden basement, a walk-in storage unit, etc.) that unlock
   progressively as the player solves gating puzzles elsewhere in the level.
8. **Color-blind-safe design is mandatory.** Any puzzle relying on color differentiation
   must have a secondary non-color cue (shape, label, pattern, position). No agent may pass
   through a color-only puzzle or palette choice without this.
9. **Shared state lives in files, not memory.** All cross-agent handoffs happen via the
   `specs/` directory described below. Agents do not communicate directly with each other —
   only through the Producer and the shared spec files.

---

## Shared State: `specs/` Directory Structure

```
specs/
  project-state.md              # Producer-maintained: phase, blockers, what's queued
  progression-ledger.md         # Producer-maintained: cross-level difficulty scores,
                                 #   puzzle-mechanic variety, real-world-knowledge domains
                                 #   used, cumulative approved style-reference image library,
                                 #   cumulative Flux API spend across the whole project
  levels/
    level-N/
      puzzle-graph.json         # Theme & Puzzle Designer output (nodes, dependency edges,
                                 #   zone-unlock edges, fixed solution values)
      puzzle-graph-summary.md   # Human-readable version for checkpoint review
      validation-report.md      # Puzzle Logic Validator output (pass/fail, soft-lock and
                                 #   fairness warnings incl. color-blind check, difficulty score)
      playtest-report.md        # Blind Playtester output (friction points, pacing, fairness
                                 #   "feel" assessment, blind time-to-solve per puzzle)
      style-guide.md            # Art Director output (palette, lighting, composition,
                                 #   per-zone mood, device-scaling notes)
      asset-manifest.json       # Asset Generation Agent output (filenames to scenes/
                                 #   hotspots/states)
      qa-report.md              # QA Agent output (pass/fail, bug list, device matrix)
      walkthrough-level-N.md    # Documentation Agent output (draft, then reconciled
                                 #   post-QA final version)
  assets/level-N/...             # Generated image files
```

---

## Agent Roster

### 0. Producer / Orchestrator (main Claude Code thread — not a subagent file)

Takes user input (theme, task, change request), sequences subagent invocations, maintains
`project-state.md` and `progression-ledger.md`, resolves cross-agent conflicts by surfacing
them to the user rather than deciding unilaterally, and enforces the checkpoint sequence
below. Never designs, codes, or makes creative calls itself.

**Progression ledger responsibilities specifically**: before invoking the Theme & Puzzle
Designer for a new level, feed it prior levels' difficulty scores and puzzle-mechanic types
used, with instruction to escalate difficulty and avoid repeating mechanics too heavily.
Before invoking Asset Generation, feed it the cumulative approved reference-image library
across all prior levels (not just the immediately preceding one) so visual style doesn't
drift over the course of the project. Track and report cumulative Flux API spend to the
user after each level completes.

---

### 1. Theme & Puzzle Designer (`.claude/agents/theme-puzzle-designer.md`)

**Input**: a theme (word/phrase) from the user, optional scale/constraints, and the
progression-ledger context the Producer supplies (prior difficulty scores, mechanics used).

**Does**: designs zone/area layout including nested hidden areas with unlock conditions;
designs puzzle chains (hidden items, environmental clues, ciphers, item combination, red
herrings) in Myst/Neutral logic style; incorporates real-world-knowledge puzzles calibrated
to educated-generalist level; sets fixed/static solution values; allows multiple valid solve
paths; escalates difficulty per the progression ledger; outputs a structured dependency
graph, not prose.

**Does not**: validate its own solvability (Validator's job); decide visual style (Art
Director's job, though it specifies visually-necessary puzzle-relevant elements); write
dialogue/lore beyond a single short framing line — genre is near-wordless.

**Outputs**: `puzzle-graph.json`, human-readable `puzzle-graph-summary.md`, list of
visually-necessary elements for the Art Director.

**Flags to user**: puzzle difficulty/obscurity judgment calls, any real-world-knowledge
fact it's unsure clears the "educated generalist" bar.

---

### 2. Puzzle Logic Validator (`.claude/agents/puzzle-validator.md`)

**Input**: `puzzle-graph.json`.

**Does**: checks solvability of every node from start state; checks for soft-locks including
those reachable via plausible player mistakes; checks zone-unlock integrity (hidden areas
only reachable via intended conditions); checks all valid solve paths resolve consistently;
checks real-world-knowledge puzzle fairness (the fact must be inferable in-room); **checks
no puzzle relies on color-only differentiation without a secondary non-color cue**; produces
a per-zone difficulty/complexity score for the progression ledger.

**Does not**: redesign puzzles itself (routes failures back to the Designer); touch code,
art, or copy; judge subjective "fun" (that's the Blind Playtester).

**Outputs**: `validation-report.md` — pass/fail per node, soft-lock warnings, fairness
warnings, color-blind-safety check results, path-consistency confirmation, difficulty score.
Failures are severity-tagged: critical soft-locks hard-block progress to the next stage;
borderline fairness/obscurity calls surface to the user as advisory.

---

### 3. Blind Playtester (`.claude/agents/blind-playtester.md`) — NEW

**Input**: approved `puzzle-graph.json` and level layout, but explicitly **without** access
to the graph's dependency structure or solution key during its simulated playthrough — it
must reason from only what would be visible in-scene, genuinely simulating first-contact
discovery.

**Does**: plays through the level as a first-time player would, using only in-scene
information; reports where it got stuck, real reasoning time to find each connection,
which red herrings felt fair-but-tricky vs. genuinely unfair, and whether the intended
difficulty curve (challenging at level 1, harder in later levels) actually lands from a
player's-eye view rather than the designer's.

**Does not**: check logical solvability (Validator's job, already done); this is a
qualitative/experiential pass, not a pass/fail correctness check.

**Sequence**: runs after Puzzle Validator, before Art Director/Asset Generation/Developer —
catching "technically solvable but not fun" issues before any art or code work begins.

**Outputs**: `playtest-report.md` — friction points, pacing assessment, fairness-of-feel
notes, per-puzzle blind-solve-time estimates.

---

### 4. Art Director (`.claude/agents/art-director.md`)

**Input**: approved `puzzle-graph.json` (visually-necessary elements list), theme, user
checkpoint approval on direction.

**Does**: establishes style guide matching the neutralxe aesthetic (static rendered/
painterly, single-camera-view compositions, muted-but-warm atmospheric palette, realistic
lighting); translates visually-necessary puzzle elements into concrete scene composition;
defines consistent per-zone palette/lighting language (main area vs. hidden basement vs.
storage unit should feel tonally connected); defines UI conventions (cursor states,
inventory bar, no hint-button needed); provides device-scaling notes for iPad-primary/
iPhone-secondary layouts; **ensures palette choices maintain non-color-only distinction
wherever the puzzle graph calls for color-coded elements**.

**Does not**: generate final assets itself; add/move interactive elements the Designer
didn't specify; write code.

**Outputs**: `style-guide.md`, per-zone mood/lighting notes, scene-by-scene composition
brief, device-scaling notes.

---

### 5. Asset Generation Agent (`.claude/agents/asset-generation.md`)

**Input**: approved `style-guide.md`, visually-necessary elements list, the cumulative
cross-level reference-image library from `progression-ledger.md`.

**Does**: generates background scene renders, item icons, and hotspot state variants
(closed/open/open-with-item, etc.) via the Flux 2 Pro API on fal.ai; maintains style
consistency by anchoring each new generation against approved reference images — first from
earlier in the *same* level, and against the project-wide reference library for cross-level
consistency; outputs correctly sized/formatted assets for SpriteKit (@1x/2x/3x); maintains
`asset-manifest.json`; reports an image-count/cost estimate before generating a level, and
reports actual spend back to the Producer for the cumulative ledger.

**Does not**: make composition/palette/mood decisions (executes Art Director's spec only);
omit or simplify a puzzle-relevant visual element because it's hard to render — flags
difficulty instead of dropping it.

**API integration note**: use fal.ai's Flux 2 Pro endpoint via HTTP calls from bash;
authenticate with an API key the user provides; this is pay-as-you-go, no subscription tier
needed.

**Outputs**: final image assets organized by zone/scene, `asset-manifest.json`, per-zone
batch checkpoint bundle for user review, cost estimate/actual reports.

---

### 6. Developer Agent (`.claude/agents/developer.md`)

**Input**: approved `puzzle-graph.json`, `asset-manifest.json`, `style-guide.md` (UI
portion), target iOS version (17+ floor).

**Does**: implements the app in Swift/SpriteKit (interactive room scenes) + SwiftUI (UI
chrome); scene setup, hotspot hit-testing, inventory system, item-combination logic, puzzle
state machines tracking "requirement met" rather than literal action sequence (to support
multiple valid solve paths), zone-unlock/reveal logic, save/resume persistence; implements
fixed solution values exactly as specified; builds iPad-primary responsive layout with
iPhone-compatible secondary layout (larger hit-target tolerance, adapted composition where
needed).

**Does not**: modify puzzle logic, art direction, or difficulty; make App Store submission
decisions; self-certify game-flow correctness (that's QA's job) — though it does write unit
tests for its own core logic.

**Outputs**: buildable Xcode project (via `xcodebuild` from CLI), implementation-notes doc
flagging any judgment calls made on ambiguous specs, unit tests for inventory/state-machine
logic.

---

### 7. QA / Test Agent (`.claude/agents/qa-tester.md`)

**Input**: built Xcode project/TestFlight build, approved `puzzle-graph.json`, target
device list.

**Does**: functional tests against the fixed solution path and all valid alternate paths in
the actual built app; simulator-based device/orientation matrix (iPad primary sizes,
iPhone secondary sizes, notch/Dynamic Island safe areas) via `xcrun simctl`; regression
testing after Developer Agent changes; save/resume state testing; hotspot hit-target
accuracy across device sizes; basic performance checks (load times, memory, crash-free
zone transitions).

**Does not**: fix bugs itself (reports to Developer via Producer with repro steps); re-judge
puzzle design fairness (Validator's job); make release-readiness/App Store guideline calls
(Release Manager's job).

**Scope note**: this agent runs simulator-based automated testing only. Physical-device
spot-checks (real touch behavior, thermals, haptics) are a manual step the user performs
before final release approval — not something this agent can do unassisted.

**Outputs**: `qa-report.md` — pass/fail per puzzle/zone, bug list with severity and repro
steps, device-matrix results, go/no-go recommendation (final decision stays with the user).

---

### 8. Walkthrough / Documentation Agent (`.claude/agents/documentation.md`)

**Two-touch agent — runs twice per level:**

**First pass** (after Puzzle Validator approval, can run in parallel with Art/Asset/Dev
work): consumes validated `puzzle-graph.json` and level layout; writes an ordered,
step-by-step text walkthrough per level; picks one canonical solve path to document clearly
(footnoting major alternate routes briefly rather than narrating every branch); states exact
fixed answers (this game uses static values, so literal answers are correct;
e.g. "enter 4-7-2 on the safe"); includes brief context for real-world-knowledge puzzles
(e.g. "the code comes from Orion's Belt's three stars, mapped to dial positions");
structures the guide by zone matching actual player experience, noting what triggers each
hidden-area reveal.

**Second pass** (after QA approval): reconciles the draft walkthrough against QA's test
results and any Developer-flagged implementation deviations logged during the build;
updates any steps that drifted from the original graph due to implementation judgment calls
or bug fixes, so the final walkthrough matches what actually shipped.

**Does not**: re-validate puzzle logic (assumes the graph is correct; flags inconsistencies
back rather than papering over them); write marketing copy or in-game text; build a
hint-tiered/spoiler-free version — full walkthrough only, no hint system needed.

**Outputs**: `walkthrough-level-N.md` (draft, then reconciled final version).

---

### 9. iOS Release Manager (`.claude/agents/release-manager.md`)

**Input**: QA-approved build.

**Does**: handles provisioning/signing (certificates, provisioning profiles, App ID,
entitlements); runs archive build via `xcodebuild` producing the `.ipa`; prepares App Store
Connect metadata (name, description, keywords, category, age rating, privacy nutrition
label — likely minimal given no data collection); generates required screenshots per device
size via simulator captures; manages version/build numbering; prepares TestFlight builds;
assembles a submission checklist flagging common Apple review rejection risks.

**Does not**: fix bugs or make design changes (routes back to Producer); touch the user's
Apple Developer account credentials, 2FA, or payment info directly — the user handles
initial Apple Developer Program enrollment and account authorization themselves; decide
pricing/monetization strategy (implements what the user decides — currently: free, no IAP
at launch, but structured so IAP could be added later without a rearchitect).

**Outputs**: signed archived `.ipa`, populated App Store Connect metadata draft for review,
submission checklist with flagged risks.

---

## Pipeline Sequence & Checkpoints

For each new level, the Producer sequences agents in this order. **Bolded** steps are
user-approval checkpoints (pause and wait); non-bolded steps auto-proceed but still escalate
individual ambiguities to the user per the "ask, don't assume" principle.

1. User provides theme (+ optional constraints) for the level
2. Theme & Puzzle Designer generates `puzzle-graph.json`
3. Puzzle Logic Validator runs (incl. color-blind-safety check)
4. **User reviews `puzzle-graph-summary.md` + `validation-report.md`**
5. Blind Playtester runs against the approved graph
6. **User reviews `playtest-report.md`** (may route back to step 2 if pacing/fairness issues found)
7. Art Director produces `style-guide.md`
8. **User reviews and approves style direction**
9. Asset Generation Agent generates assets (per-zone batch review, not per-image)
10. **User reviews asset batches per zone**
11. Developer Agent implements the level
12. QA Agent tests the built level (simulator-based)
13. **User reviews `qa-report.md`** and go/no-go
14. Documentation Agent second-pass reconciliation of the walkthrough
15. Once enough levels are ready: iOS Release Manager prepares submission
16. **User performs physical-device spot-check and final release approval**

Throughout, the Producer updates `project-state.md` and `progression-ledger.md` after every
stage.

---

## First Task

Scaffold the `.claude/agents/*.md` subagent definition files per the roster above (one file
per subagent, each with role, allowed tools, and the responsibilities/boundaries described
in its section), set up the `specs/` directory structure, and initialize
`project-state.md` and `progression-ledger.md` as empty tracking documents ready for the
first level. Do not begin designing an actual level yet — wait for the user's first theme
input after scaffolding is confirmed.
