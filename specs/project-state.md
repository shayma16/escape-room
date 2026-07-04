# Project State

_Maintained by the Producer. Updated after every pipeline stage._

## Current phase

Level 1 in design. Theme received from user on 2026-07-04.

## Active level

Level 1 — "Wizard's cabin": abandoned wizard's cabin in the woods, gloomy atmosphere,
caged crow, potions/potion-making (user-specified elements).

## Pipeline position

**Step 8 — USER CHECKPOINT (paused, awaiting style approval).** `style-guide.md`
complete: painterly pre-rendered realism (Myst/neutralxe register), warm/cool duet
(moonlight vs dying ember/lamp light) with per-zone mix ratios, canonical single
night-sky master plate (moon high + Orion at plate-2 tilt), full state-variant
coverage incl. beam matrix and clock states, grayscale-check gate for color-blind
safety, dual-safe-zone 2:1 plates with iPhone dial-legibility floor. Four judgment
calls for user (guide Section 10): F1 live-moon phase choice, F2 ambient light
dressing, F3 resolve developer_notes D1 (art recommends block-the-pour), F4 no CB
conflicts (executional risk gated at asset review). BLOCKER for step 9: fal.ai API
key still not provided.

## Blockers / open questions

- fal.ai API key not yet provided (needed before the Asset Generation stage, not before).
- ~~Xcode/macOS build environment~~ RESOLVED 2026-07-04: no local Mac — all
  `xcodebuild`/`xcrun simctl` work runs on GitHub Actions macOS runners. Repo:
  https://github.com/shayma16/escape-room (private). Workflows scaffolded:
  `.github/workflows/build-and-test.yml` (Developer/QA) and `release.yml` (Release
  Manager); placeholder steps to be filled in once an Xcode project exists. Note:
  macOS runners bill at 10x minutes on private repos.
- Signing material (distribution cert, provisioning profile, ASC API key) not yet stored
  as encrypted GitHub Secrets (needed before the Release stage; secret names are listed
  in `release.yml`'s header comment — user creates them via `gh secret set`, never
  pasted in chat or committed).
- Apple Developer Program enrollment not yet done (needed before the Release stage; user
  enrolls and authenticates themselves — agents never touch Apple credentials).
- App name / bundle identifier undecided (needed at Release-stage metadata prep).

## Queued

1. Level 1: design → validation → user checkpoint (in progress).
