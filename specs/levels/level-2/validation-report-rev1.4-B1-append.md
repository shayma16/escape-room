# APPEND BLOCK — concatenate verbatim to the END of `validation-report-rev1.4.md`

*Producer: this file is the "B.1 / F-4 verdict" section of `validation-report-rev1.4.md`.
Append it unchanged after the V17 verdict table, then delete this file. It was written
separately only because the Validator had no in-place edit tool this session and rewriting the
703-line approved report wholesale would have risked corrupting its verbatim finding strings —
the same reason the Designer shipped `clue-legibility-p06-p03-revB1-append.md` separately.*

---

## B.1 / F-4 verdict (targeted confirmation, 2026-08-08)

**Scope.** Single-question re-check of the Designer's **F-4** flag in
`clue-legibility-p06-p03-revB1-append.md` (rev B.1, target graph revision 1.4.1): does the
teach-at-dormer chalk note reopen the rev-B *"considered and rejected: chalk sight-line"*
finding, is it no-tell compliant, and does its "no new state / no new overlay id / content
change only" claim hold? Read-only against `puzzle-graph.json` (on disk at `spec_revision`
**1.4**, D12 present), `clue-legibility-p06-p03.md` rev B §2b, `style-guide.md`,
`blind-layout.md`, `asset-manifest.json` and `specs/assets/level-2/z1/z1-state-overlays.json`.
Nothing below reopens an approved decision, and nothing below is a redesign.

**VERDICT: CONFIRMED on all three questions asked. 0 Critical. 4 Advisory (B1-A1…B1-A4), all
documentation-consistency or forward-guard class. Does not block the Art Director hand-off of
H8 or the Blind Playtester re-run.**

### B.1-1 — F-4: the construction claim. **CONFIRMED.**

The rev-B rejection (`clue-legibility-p06-p03.md` §2b, verbatim) reads: *"Considered and
rejected: a chalk sight-line / dashed stroke from the ring to the board. It reads as a modern
UI arrow rather than a diegetic mark, it duplicates what C1+C2 already achieve, and it would
require a new glyph primitive outside the canon."* Its **object** is a ring→board connector.
B.1's object is a mark wholly contained in the `ov-cache-*` rect. They are different objects,
so the rejection is not reopened. Ground by ground:

| Rev-B ground | B.1 status | Basis |
|---|---|---|
| **(1) reads as a modern UI arrow** | **AVOIDED by construction** | B.1b states *"No line, no arrowhead, no dashes, no glow, no animation on appearance beyond whatever the rev-1.4 mark already does."* The mark is a filled silhouette on a physical surface in the clockmaker's established chalk register, not an overlay stroke. A clock hand is a **diegetic object in this level** (two watches + the great dial); an arrowhead is not. Residual risk is wide-scale silhouette identity, not UI-ness — see B1-A4. |
| **(2) duplicates what C1+C2 already achieve** | **SUPERSEDED by measurement — not "avoided by construction"** | The Designer's stated basis (*"the objective has changed"*) is defensible but under-states the real one. The honest basis is **new evidence that did not exist at rev B**: `playtest-report-rev1.4.md` P8 (*"because it had a house mark on it… no reference to the III bearing"*) and P11 (*"did I read it as a direction? no — never"*) demonstrate that C1+C2 achieve the **solve** and not the **teach**. B.1 rests on data, not on a redefinition. Recorded here because it strengthens the case and matters for the record. |
| **(3) requires a new glyph primitive outside the canon** | **AVOIDED — with one de-minimis exception** | `hand-hour` (`z3/v-dial/sprites/hand-hour`) is canonical and is **already composited by C1 and C3** per D12; `masters/glyphs/die-house.png` is canonical and byte-identical to rev 1.4. Neither is new. The **hub dot** is the one mark form not drawn from a named existing asset — see B1-A3. |

**Spanning test — PASS.** Containment in x 0.6375–0.7656 is a hard B.1b constraint and matches
D12's rev-1.4 rect verbatim. Nothing is drawn on the beam, between the beam and the floor, or
outside the mark rect, in either view. No gap is spanned in world space or image space.

**Rev-B bookkeeping — CONFIRMED.** The §2b rejection note **stands unreversed** and requires no
re-ratification. B.1 does not adopt a sight-line.

### B.1-2 — No-tell compliance. **CONFIRMED.**

- **Same gate.** `clu-watch-a`, one of the five persisted D7 booleans (graph D7, line 387).
  Unchanged; no new flag, no second condition.
- **Same single appearance event.** Visibility predicate stays `gate-satisfied AND NOT pried`,
  identical to D12's rev-1.4 predicate; the note renders on view entry. Nothing appears earlier,
  and there is no second event. The pre-clue board remains byte-identical to rev 1.4 and
  transitively to rev 1.3 (uniform boards, no hand in either view).
- **Not an attempt response.** `no_tell_rule` (graph line 24) governs *gated attempts* and their
  failure grammar; B.1 touches no attempt path. D10 (line 390) constrains the **pry response
  only**, and its own rev-1.4 clarification already states the annotations *"are functions of
  clu-watch-a / clu-watch-b, never of prying."* The wrong-spot dead wall and the D10
  correct-spot faint-tell are byte-stable. **D10 correctly appears on the Designer's
  deliberately-not-touched list.**
- **No new licence created.** `clue_gating.art_impact` (line 27) already scopes item **(ii)** as
  *"the chalk house glyph on the p03 cache board in the wide and the close-up"* — a **named**
  clue-state render, expressly *"NOT a general permission class."* B.1 changes the content of
  that already-named render and adds no fourth annotation, so **p07 and p09 remain strictly
  no-annotation**. That string's closing clause — *"Any future clue-state render requires
  Validator re-verification"* — is **satisfied by this verdict**, which is the re-verification.
- **Post-gate salience.** The note is more conspicuous than the single rev-1.4 glyph. This is
  **not** a no-tell concern (no-tell governs the pre-gate/gated window, where nothing renders)
  and it is already inside the A4-sanctioned, p03-only reversal. No finding.

### B.1-3 — "No new state / no new overlay id / content change only." **CONFIRMED, with one wording correction.**

Verified independently:

- **No new state.** No flag, node, edge, hotspot, gate, consumable or overlay id in any of
  H1–H8. All eight deltas are prose/content; the structural fields
  (`solution_fixed`, `requires`, `clue_gate`, `yields`, `failure_behavior`, `edges`,
  `anti_softlock_invariants`) are on the explicit not-touched list and stay byte-stable.
- **State set unchanged.** `unmarked -> marked -> pried-with-wheel -> empty` still totally
  ordered; suppression on pry rides the same overlay that already suppressed, so no note can
  survive on a lifted board or an empty cavity. **V14 closure re-confirmed.**
- **No M1 re-registration.** Rect containment preserves *what is marked is exactly what is
  tappable*.
- **RC-6 cardinality unchanged.** `ov-cache-marked` × `ov-cache-cat-gone` remains exactly one
  composite pairing (`ov-cache-cat-gone` confirmed present in
  `specs/assets/level-2/z1/z1-state-overlays.json`). **No new `Level2CloseUpStateTests`
  state-flip rows** — a re-render of the existing pairing only.
- **Cost.** $0 additional; the §4 fallback ceiling stays $0.45. Confirmed — the note is a
  deterministic PIL composite of two already-canonical assets.

**Wording correction (B1-A2, below):** B.1 repeatedly calls `ov-cache-marked-wide` /
`ov-cache-marked` the **"existing"** overlays. They exist **in the rev-1.4 spec** (D12 names
them) but **not as authored assets** — they appear nowhere in
`specs/levels/level-2/asset-manifest.json` (which carries `ov-cache-pried-wheel`,
`ov-cache-empty`, …) and nowhere in `z1-state-overlays.json`. Rev B §2b introduced them as
*"New state assets."* The claim that **matters** — *B.1 introduces no new overlay id* — is
**TRUE**, and the practical consequence is strictly favourable (nothing is regenerated; the pair
is authored once, from B.1 content, at zero rework). Only the word "existing" is imprecise.

### Advisory findings

**B1-A1 — Advisory (highest of the four). The H-list site sweep misses three graph sites, one of
which creates an intra-graph contradiction.** B.1c opens *"Site sweep first… Every site in the
repo that describes the p03 cache-board mark is enumerated below; there are eight, six of them
in the graph"* — written expressly to prevent an RF-5 recurrence. Three further graph sites
describe the mark and appear on **neither** the H-list **nor** the deliberately-not-touched list:

| Site | Current text | Effect after B.1 |
|---|---|---|
| `zones[z1-attic].views[v-door].elements`, floorboards string (**line 48**) | *"…the cache board carries a chalk house glyph (canonical die-house) composited INSIDE the ov-cache-* rect x 0.6375-0.7656, in BOTH the wide and the close-up."* | **Direct contradiction with H2.** H2 will say the board carries a two-mark chalk note; this says a single house glyph. This is the zone/view content contract Asset-Gen and the Art Director read, so left as-is it would author the rev-1.4 single glyph. **Fix before commit.** |
| `clue_gating.art_impact`, item (ii) (**line 27**) | *"the chalk house glyph on the p03 cache board in the wide and the close-up"* | Enumeration goes stale. The **scoping function is unaffected** (B.1 is a content change to a named render, not a new class), so this is accuracy only. |
| `visually_necessary_elements.rev_1_4_cue_note` (**line 416**) | *"one chalk house glyph on the p03 cache board"*; *"NO new glyph dies"* | Enumeration goes stale. B.1 does **not** breach *"NO new glyph dies"* (`hand-hour` is an existing sprite, not a die) or *"composites over existing plates and existing sprites"*. Accuracy only. |

Not a correctness defect — no solution value, gate, dependency or state consequence — but line 48
must be reconciled with H2 **before the Producer commits**, or the graph ships self-contradictory
about what is on the board. Route to the Designer for the two verbatim strings; do not
improvise them at commit time.

*Correctly omitted, confirmed intentional:* `revision_notes[]`'s rev-1.4 element (historical
record of rev 1.4, accurate as written) and **D10** (its rev-1.4 clarification names the mark in
passing, but D10 governs the pry response only and is rightly frozen).

**B1-A2 — Advisory. Read "existing overlays" as "specified at rev 1.4, not yet authored."**
Per B.1-3 above. Producer/Asset-Gen should not read B.1 as requiring an edit to a shipped asset.
Side effect, in the Producer's favour: because the pair is unauthored, **A10's rect-capacity
measurement can be folded into first authoring** rather than gating a re-edit — it still must
happen before art starts, and the B.1b fallback ladder (shorten the hand, never the house, then
escalate) still governs.

**B1-A3 — Advisory. The hub dot is the one mark form not drawn from a named canonical asset.**
B.1b defines it as *"a filled chalk dot the width of one chalk stroke."* It is best read as the
degenerate case of the existing chalk-stroke primitive at the same width and value, carrying no
independent semantic content — which is why this is Advisory and not a ground-(3) failure. Two
notes for the Designer's decision (not mine to make):
(i) it is the single point on which a strict reading of *"new primitive outside the canon"* could
bite, and the construction claim would be airtight without it;
(ii) hub-dot-plus-hand is the iconography of a **miniature clock face**, on a board the player
reaches immediately after learning *"the ring is a clock face."* B.1b's *"not a ring, no notches
— it must never invite counting"* is the correct guard and I confirm it is present; the residual
is that the note could read as a tiny clock rather than as a pointer, which is a **null teach,
not a wrong teach** (the player still sees a marked board and pries it, per S-7). Fold into
P12(a0) rather than redesigning.

**B1-A4 — Advisory, and the one with real forward risk. Escalation lever E1 *does* reopen the
rev-B rejection, and must not be treated as pre-approved.** B.1's F-1 pre-specifies E1 as *"a
short chalk sighting stub ruled along the beam outward from the ring at 3 o'clock, ~1–2
ring-diameters, terminating in a single short plumb tick downward."* That is **a ruled chalk
stroke originating at the ring** — squarely inside the rejected class on ground (3) (a ruled
multi-segment guide line is a new primitive outside the canon) and materially exposed on ground
(1). The Designer correctly says *"it would need its own Validator pass"* and *"do not pull E1
pre-emptively."* Strengthening that for the record: **if E1 is ever pulled it requires
re-ratification of the rev-B rejection by the user, not merely a Validator pass**, because it
reverses a recorded design finding rather than working around it. Nothing in B.1's approval
carries E1 with it.

### Difficulty — no change

I concur with S-4 and S-5. The note changes neither the target, nor the hotspot, nor the gate,
nor when the board becomes pryable; it adds confirmatory salience to a board that is already
marked and is already a single always-correct hotspot. **p03 stays 3.5; z1 stays 4.5; the level
stays 6.0 PROVISIONAL** (z1 4.5, z2 6.5, z3 7.0, z4 3.5). The expected p04 effect (stall 8–15 min
→ under 5 min, 6.5 → ~5.5–6.0) is **empirical and not scored here**; rewritten probe P12 settles
it. **This delta does not release the `progression-ledger.md` write** — that write remains held
pending the blind re-check, of which P12 is now part.

### B.1 / F-4 summary

| Check | Severity | Result |
|---|---|---|
| F-4 (a) no line / no arrowhead / no dashes | — | **CONFIRMED** |
| F-4 (b) spans no ring→board gap (rect-contained) | — | **CONFIRMED** |
| F-4 (c) no new primitive outside canon | Advisory (B1-A3) | **CONFIRMED** — `hand-hour` and `die-house` both canonical and already composited; hub dot de minimis |
| Rev-B rejection status | — | **STANDS UNREVERSED; no re-ratification required** |
| Ground (2) basis | — | **Superseded by rev-1.4 playtest evidence**, not avoided by construction — recorded |
| No-tell: same gate, same single appearance event, not an attempt response | — | **CONFIRMED** (no_tell_rule, D7, D10, art_impact all byte-stable) |
| No new state / no new overlay id / content-change-only | Advisory (B1-A2, wording) | **CONFIRMED** |
| Contract-site sweep completeness | Advisory (B1-A1) | **ISSUE — 3 graph sites missed; line 48 contradicts H2. Fix before commit.** |
| Escalation lever E1 | Advisory (B1-A4) | **Reopens the rev-B rejection if pulled — not pre-approved** |
| Colour-blind safety (mandatory gate) | — | **PASS** — shape and position only; the no-fade / no-ghost / no-dash / no-lower-opacity clause carried over from V17-W3 is present and correctly binding |
| Critical findings | — | **0** |
| Difficulty impact | — | **None.** z1 4.5; level **6.0 PROVISIONAL**; ledger write still held |
| **NET** | — | **CONFIRMED (0 Critical, 4 Advisory)** |
