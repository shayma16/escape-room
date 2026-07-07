# Level 1 Art Rebuild Plan — Nano Banana Pro engine-render style (build 3)

_Queued 2026-07-08 (user directive). Executes AFTER build 2 ships to TestFlight.
Hard budget cap: **$10.00 total fal.ai spend** for the entire Level 1 rebuild. Be
conservative — a brute-force full regen does NOT fit and is forbidden._

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
| Base scene plates (z*-*-base) | 7 | **FRESH t2i.** Hero of the style change. Render key ones at 4K ($0.30) so close-ups crop from them free. |
| Close-ups (cu-*) | 58 | **SPLIT.** Croppable zoom-views → free PIL crop of the 4K base. Independent-framing scene close-ups (materials/objects) → fresh $0.15. Pure glyph/geometry close-ups (rune marks, hallmarks, numerals) → CARRY OVER (style-neutral). |
| State variants (z*- non-base) | 30 | **Mostly free.** PIL composites/overlays + sparing `/edit` from the fresh base (as the original build did at ~$0). |
| Icons (icon-*) | 15 | **FRESH** rendered objects, $0.15 each (white-bg + PIL cutout, as before). |
| Sprites (dial faces, astrolabe plates, rune tiles, ember runes, ladle) | 16 | **CARRY OVER** — these are geometry/glyph overlays, style-neutral; verify they still read against the new bases, regen only if a specific one clashes. |
| Global (app icon + launch) | 4 | App icon FRESH (1 render + ≤2 candidates, ~$0.45). Launch screens = PIL composites, $0. |

## Cost strategy to stay under $10 (Producer-set; Asset Gen does detailed accounting)
The load-bearing insight: **not everything needs re-rendering.** Only painterly-vs-engine-
render-*sensitive* content does — rendered scenes, materials, objects, icons. Pure
**geometry/glyph** assets (moon-phase silhouettes, star dot-patterns, rune glyphs, Roman
numerals, crescent hallmark, rune-door tiles) are shape-based and style-neutral — they
CARRY OVER unchanged (verify legibility against the new bases; regen only on a real clash).

Fresh-generation budget envelope (must total ≤ $10 incl. retries):
1. 7 base plates (mix 4K/standard) + retry allowance ≈ **$2.5–3.2**
2. Icons ×15 + retries ≈ **$2.5**
3. Non-croppable scene close-ups (the ~12–18 that need own framing, NOT the glyph ones) ≈ **$2.5–3.0**
4. App icon ≈ **$0.5**
5. State variants: target **$0–1.5** (PIL/overlay free; sparing edits only)
Everything else (croppable close-ups, @2x/@1x, glyph carryover, launch screens) = **$0**.

**Binding rule for Asset Gen:** produce a per-asset pre-generation estimate against the
$10 cap BEFORE generating. If the estimate exceeds $10, STOP and report to the Producer
for prioritization — do not silently trim puzzle-relevant elements (the don't-drop rule
still holds). Use up to 14 reference images per generation for consistency; anchor every
new plate to the freshly-approved bases so the level stays coherent in the new style.

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
