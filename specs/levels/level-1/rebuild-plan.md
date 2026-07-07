# Level 1 Art Rebuild Plan — Nano Banana Pro engine-render style (build 3)

_Queued 2026-07-08 (user directive). Executes AFTER build 2 ships to TestFlight.
Hard budget cap: **$18.90 total fal.ai spend, and not more** (user raised from $10 on
2026-07-08). **Full rebuild — regenerate EVERYTHING; no painterly-era carryover.** User
reason: carrying over any old asset (even glyph/geometry) alongside fresh engine-render
bases would look inconsistent. So the earlier "carry over style-neutral geometry" plan is
SUPERSEDED — every visible asset is either freshly generated or derived from a FRESH
new-style base (never from a painterly original)._

## Why
Build-1/2 art was generated with Flux 2 Pro in a painterly/matte-painting style the user
rejected. New model + mandatory style template are now in `.claude/agents/asset-
generation.md` (engine-render look: stylized real-time 3D, PBR clean materials, softened
bevels, UE5-Lumen-style lighting, no painterly texture). Level 1 art is redone in that
style for build 3.

## Pricing (verified 2026-07-08)
- Nano Banana Pro (`fal-ai/nano-banana-pro`): **$0.15/image standard**, **$0.30 at 4K**,
  +$0.015 if web-search-in-generation is used (we will NOT use it). Pay-as-you-go.
- @2x/@1x are FREE PIL downscales of @3x — never regenerate them.

## Asset inventory (@3x uniques, current Level 1)
| Type | Count | Rebuild treatment |
|---|---|---|
| Base scene plates (z*-*-base) | 7 | **FRESH t2i.** Hero of the style change. Render at 4K ($0.30) so close-ups crop from them free where possible. |
| Close-ups (cu-*) | 58 | **FRESH or crop-from-fresh-4K-base.** Independent-framing ones → fresh $0.15; true zoom-views → free PIL crop of the FRESH 4K base (consistent, since the base is new-style). Glyph close-ups (rune marks, hallmarks) → re-rendered/re-derived against the new bases, NOT carried over. |
| State variants (z*- non-base) | 30 | **Derive from FRESH bases** — PIL composites/overlays + sparing `/edit` from the new-style base (never from painterly originals). Mostly $0, a few cheap edits. |
| Icons (icon-*) | 15 | **FRESH** rendered objects, $0.15 each (white-bg + PIL cutout). |
| Sprites (dial faces, astrolabe plates, rune tiles, ember runes, ladle) | 16 | **FRESH / re-derived** against the new-style bases — do NOT carry over the painterly-era sprites (they sit on rendered materials and would clash). Pure-geometry ones can be re-composited to match new base materials. |
| Global (app icon + launch) | 4 | App icon FRESH (1 render + ≤2 candidates, ~$0.45). Launch screens = PIL composites, $0. |

## Cost strategy to stay ≤ $18.90 (Producer-set; Asset Gen does detailed accounting)
Full rebuild for consistency — nothing painterly carries over. The budget still stretches
via FREE derivation *from fresh new-style bases* (this preserves consistency, unlike
carrying over old assets): @2x/@1x are always free PIL downscales; true zoom close-ups are
free crops of the fresh 4K bases; localized state variants are free PIL overlays/composites
off the fresh bases. That keeps the count of *independently paid* generations well under
126 and leaves retry headroom inside $18.90.

Envelope (must total ≤ $18.90 incl. retries; 126 all-fresh-no-reuse = $18.90 with ZERO
headroom, so free derivation from fresh bases is what makes retries affordable):
1. 7 base plates @ 4K + retries ≈ **$3–4**
2. ~40–50 independently-framed close-ups (incl. glyph/hallmark/precision) + retries ≈ **$7–9**
3. Icons ×15 + retries ≈ **$2.5–3**
4. Sprites (16) fresh/re-derived — some paid, some PIL ≈ **$1–2**
5. State variants — mostly free PIL off fresh bases ≈ **$0–1.5**
6. App icon ≈ **$0.5**; launch screens $0
7. Reserve remaining margin for retries.

**Binding rule for Asset Gen:** produce a per-asset pre-generation estimate against the
**$18.90** cap BEFORE generating. If the estimate exceeds $18.90, STOP and report to the
Producer for prioritization — do not silently trim puzzle-relevant elements (the don't-drop
rule still holds), and do NOT exceed the cap ("not more" — user, 2026-07-08). Use up to 14
reference images per generation; anchor every new plate to the freshly-approved bases so
the whole level is one coherent engine-render look.

## Consistency anchoring
- The FIRST fresh base plate approved becomes the new-style seed; every subsequent
  generation references it (+ up to 13 more refs) so the whole level is one coherent
  engine-render look.
- The old painterly plates are NOT references for the rebuild (they're the look we're
  leaving). Move superseded plates to `_rejects/flux-painterly/` at integration, do not
  delete (rollback safety).
- The canonical night sky (moon + Orion geometry, `masters/orion-canonical.json`) and all
  fixed solution values / puzzle-relevant elements are UNCHANGED — this is a render-style
  swap, not a redesign. The Designer/Validator do NOT re-run; the puzzle graph is untouched.

## Sequence (after build 2 → TestFlight)
1. Art Director: light "render-style migration" addendum — confirm the existing per-scene
   composition briefs (style-guide §4–6) carry over; note any per-scene material/lighting
   cues for the new engine look. Cost-free. (Can be prepped once the working tree is free
   of the build-2 QA run.)
2. Asset Gen: pre-gen estimate vs $10 → Producer OK → generate per the strategy, per-zone
   batches, live progress tracker in `asset-progress.md` (a new "Build-3 rebuild" section).
3. **User checkpoint: per-zone batch review** (user is hands-on with art — surface each
   zone's new-style plates for approval, same as the original build's step-10).
4. Developer: stage approved new plates into `EscapeRoom/Resources/GameAssets/` (replacing
   the painterly ones), no logic change; hotspot geometry only adjusts if a new plate
   reframes an element (unlikely — same composition briefs). CI green.
5. QA: targeted visual/regression pass (functional logic unchanged from build 2).
6. Release build 3 to TestFlight.

## Status
QUEUED. Blocked on: build 2 shipping to TestFlight (which needs the user's checkpoint-2
GO on the build-2 QA regression). Nothing here spends money until the user OKs the
pre-generation estimate.
