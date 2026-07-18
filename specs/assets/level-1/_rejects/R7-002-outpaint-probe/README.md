# R7-002 outpaint probe — REJECTED (2026-07-17), $0.30

Crop-scoped strip outpaint of the z2-cabinet TOP band (21:9 slice y[0,1646), 4K, seed 72001).
This tested the ONE technique build 10 never tried: build 10 fed the WHOLE canvas
(jobs-waveA/B + job-test2 prefill); this fed only a strip so the model saw mostly real content.

RESULT: rejected — same architectural failure.
- The band content itself is excellent and on-style (dark timber ceiling beams, wall + window
  arch continuation). The model CAN render the extension.
- But it re-rendered the whole strip: cabinet reshaped, shelf/bottles moved, floor replaced,
  left/right bands dropped by re-framing.
- Registration vs the canonical interior: 21.25 mean-abs with NO alignment optimum (shift
  search saturates at its search boundary) => geometry does not correspond. Build 10 measured
  >15 mean-abs on the whole-canvas attempt; crop-scoping did not help.

ROOT CAUSE: fal-ai/nano-banana-pro/edit is not a masked inpaint - no mask parameter, and the
driver downscales refs to 1536px max side, so byte-identical interior reproduction is
impossible in principle. The invented ceiling belongs to the model's own wall geometry, so its
band cannot be transplanted onto our plate: it would not meet our seam.

=> Fell back to the user-authorized CLEAN FADE ($0 PIL). See R7-002 in feedback-backlog.md.

NOTE for the Producer: if real extended framing is ever wanted, the only route that works is to
adopt a re-rendered plate WHOLESALE and re-derive every hotspot rect, overlay and close-up for
that view from the new plate - a full per-view re-roll, far beyond this task's $2.15 headroom.

ARCHIVE NOTE: kept at @1x only (1280x549) - enough to see the re-render/registration failure;
the @2x/@3x copies were not worth 10MB of repo weight for a rejected probe.
