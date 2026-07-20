"""
Overlay quality gate for deterministic state-overlay patches.

Two checks, BOTH must pass:
  1. SEAM-RING check: mean absolute per-pixel color delta between the patched result
     and the base plate, measured in a thin ring straddling the patch mask boundary.
     Threshold: <= 24 (0-255 scale). Measures whether the seam is invisible.
  2. INTERIOR-SHARPNESS check: compares local high-frequency detail inside the patch
     INTERIOR against the adjacent base-plate stone. A patch FAILS if its interior is
     materially softer than the surrounding base (ratio interior/base below `sharp_min`).
     Closes the blind spot where a seam-ring pass hid a blurry/smeared interior.

     The comparison uses the MEDIAN of a local RMS high-pass energy map (not a mean).
     Median makes the base reference the TYPICAL flat-face stone grain instead of the
     rare, high-contrast bevel/mortar edges that a mean over the band would be dominated
     by -- so a genuinely blurred interior (near-zero local grain) still fails, while a
     legitimately flat block face is not falsely flagged.
"""
import cv2, numpy as np


def highpass(gray, sigma=3.0):
    return gray - cv2.GaussianBlur(gray, (0, 0), sigma)


def run(base_rgb, result_rgb, mask_bool, sharp_min=0.75):
    """base_rgb, result_rgb: HxWx3 uint8 arrays (same size). mask_bool: HxW bool of
    the pixels that were replaced. Returns dict of scores + pass flags."""
    base = base_rgb.astype(np.float32)
    res = result_rgb.astype(np.float32)
    M = mask_bool.astype(np.uint8)

    # ---- seam ring: dilate - erode of mask ----
    k = cv2.getStructuringElement(cv2.MORPH_ELLIPSE, (5, 5))
    ring = (cv2.dilate(M, k, iterations=3) - cv2.erode(M, k, iterations=3)) > 0
    seam_delta = float(np.abs(res[ring] - base[ring]).mean()) if ring.sum() else 0.0

    # ---- interior sharpness (robust median local-RMS) ----
    hp_res = highpass(cv2.cvtColor(result_rgb, cv2.COLOR_RGB2GRAY).astype(np.float32))
    hp_base = highpass(cv2.cvtColor(base_rgb, cv2.COLOR_RGB2GRAY).astype(np.float32))

    interior = cv2.erode(M, k, iterations=4) > 0
    outer = (cv2.dilate(M, k, iterations=10) - cv2.dilate(M, k, iterations=3)) > 0

    def local_rms(hp):
        return np.sqrt(cv2.boxFilter(hp * hp, -1, (31, 31)))

    lr_res, lr_base = local_rms(hp_res), local_rms(hp_base)

    def med(m, sel):
        return float(np.median(m[sel])) if sel.sum() else 0.0

    interior_hf = med(lr_res, interior)
    base_hf = med(lr_base, outer)
    ratio = interior_hf / base_hf if base_hf > 1e-6 else 0.0

    return {
        "seam_delta": round(seam_delta, 2),
        "seam_pass": bool(seam_delta <= 24),
        "interior_hf": round(interior_hf, 3),
        "base_hf": round(base_hf, 3),
        "sharpness_ratio": round(ratio, 3),
        "sharp_pass": bool(ratio >= sharp_min),
        "PASS": bool(seam_delta <= 24 and ratio >= sharp_min),
    }
