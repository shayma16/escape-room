# Global UI Chrome Style Guide (Theme-Independent)

*Art Director one-time deliverable, 2026-07-05. Governs the app-wide menu layer: Main
Menu, Level Select, Pause Menu, Settings. This layer is identical across every level and
theme and is NEVER restyled per level. It is deliberately distinct from the painterly
in-room art: flat, quiet, system-native. Downstream consumers: Developer Agent (all
chrome), Asset Generation Agent (app icon + launch screen only, Section 10).*

*Scope decisions baked in (user, 2026-07-05): SF Symbols for all menu icons — no custom
menu icons; app icon and launch screen are the only custom-art pieces in this layer;
Settings contains Sound toggle, Reset Progress (with confirmation), About/Credits,
version number; Pause Menu contains Resume, Restart Level, Settings, Main Menu.*

---

## 1. Design stance

- **The chrome is a picture frame, not a picture.** In-game art is painterly, warm-cool,
  atmospheric; the menu layer is flat, matte, near-monochrome. The contrast is
  intentional: menus read as "outside the room," which makes entering a level feel like
  stepping through a threshold.
- **Hue-neutral darks.** Every surface in this layer is a *neutral* (hue-less) dark so
  it can be overlaid on or sit adjacent to any level palette — Level 1's indigo night,
  or a future amber-lit or green-lit theme — without color-clashing or tinting the art
  underneath. No blues, no warms in the chrome itself.
- **Spare text, never wordless.** The game is near-wordless; menus are allowed text but
  keep it to single words or two-word labels ("Resume," "Reset Progress"). No body copy
  anywhere except the About/Credits sheet and the destructive confirmation sentence.
- **Fixed dark appearance.** The menu layer does not follow the system light/dark
  setting; it is always dark. A light-mode menu over a moody night scene would be
  jarring, and a single appearance halves the QA surface. (Judgment call, Section 11.)
- **System-native behavior, custom-quiet skin.** Standard SwiftUI controls and
  interaction patterns (Toggle, confirmationDialog, NavigationStack) restyled minimally
  — never fighting platform conventions.

## 2. Color palette

All chrome colors are true neutrals (R=G=B or within 2/255 of it). Define these as asset
catalog colors with the names below.

| Token | Role | Hex | Notes |
|---|---|---|---|
| `chromeBackdrop` | Full-screen menu background | `#101010` | Main Menu, Level Select, Settings backgrounds |
| `chromeScrim` | Overlay scrim on paused game | `#000000` at 55% | Pause Menu over frozen scene; never a blur-only material (blur alone can't guarantee text contrast over unknown art) |
| `chromeSurface` | Cards, sheets, button fills | `#1C1C1E` | Matches systemGray6-dark; used for level cards and settings rows |
| `chromeSurfaceRaised` | Pressed/selected fill | `#2C2C2E` | |
| `chromeStroke` | Hairline borders | `#FFFFFF` at 12% | 1 pt hairlines on cards and buttons |
| `chromeTextPrimary` | Labels, titles | `#EDEDEA` | Slightly warm-off-white; softer than pure white on dark, still ≥ 12:1 contrast on `chromeBackdrop` |
| `chromeTextSecondary` | Sublabels, version string | `#9A9A96` | ≥ 4.6:1 on `chromeSurface` |
| `chromeDisabled` | Locked/disabled content | `#5A5A58` | Also drop icon+label to 40% opacity |
| `chromeAccent` | Focus/selection ring, active toggle | `#C9CDD2` | A pale silver — deliberately *not* a saturated tint; selection is communicated by ring + fill change, never by hue alone |
| `chromeDestructive` | Reset Progress only | system `.red` | Always paired with explicit wording and trash/warning symbol — never color-only (Section 7) |

Rules:
- No other colors may appear in the chrome layer. Level thumbnails inside Level Select
  cards are per-level *content*, not chrome, and are exempt.
- Saturated color appears exactly once in the whole layer: the destructive action.
  That scarcity is the point — red means "this deletes something" and nothing else.
- Every text/background pairing must meet WCAG AA (4.5:1) minimum; primary labels
  target 7:1+.

## 3. Typography (system fonts only)

Two system families, fixed roles:

| Role | Font | SwiftUI spec |
|---|---|---|
| Game title (Main Menu), level names/numbers | **New York (system serif)** | `.font(.system(.largeTitle, design: .serif)).fontWeight(.medium)` (title); `.title2` serif for level numbers |
| All functional UI text (buttons, settings rows, dialogs, version) | **SF Pro** | `.body` / `.headline` per role, default design |

- The serif carries a faint storybook echo of the painterly world without importing any
  level's theme; SF Pro keeps controls unmistakably functional. (Judgment call,
  Section 11.)
- Weights: Regular/Medium only. No Bold except the destructive confirmation verb. No
  italics, no all-caps except nothing — use sentence case everywhere ("Reset Progress",
  "About").
- **Dynamic Type:** all chrome text uses text styles (never fixed point sizes) and must
  lay out correctly up through the XXL non-accessibility size; at AX sizes, menus may
  scroll but must never truncate a destructive label.
- Numerals: plain Arabic numerals in the chrome ("Level 3"). Roman numerals are an
  in-world glyph language (Level 1 clock/runes); do not leak them into menus.

## 4. Buttons and controls

### 4.1 Primary menu button (Main Menu, Pause Menu)
- **Shape:** capsule (fully rounded ends).
- **Size:** 56 pt tall on iPad, 50 pt on iPhone; width = intrinsic label + 32 pt side
  padding, minimum 220 pt on iPad / 200 pt on iPhone so a stacked column reads as a
  unified block.
- **Fill:** `chromeSurface` with a 1 pt `chromeStroke` hairline. Label
  `chromeTextPrimary`, `.headline` SF Pro.
- **Optional leading SF Symbol** at the label's text size (Section 8).

### 4.2 States (all buttons)
| State | Treatment |
|---|---|
| Default | `chromeSurface` fill, hairline stroke |
| Pressed | fill → `chromeSurfaceRaised`, scale 0.97, 120 ms ease-out; no color flash |
| Focused (keyboard/pointer/game-controller) | 2 pt `chromeAccent` ring outside the stroke |
| Disabled/locked | `chromeDisabled` label + 40% opacity content; lock symbol where applicable — never opacity alone (Section 9) |
| Destructive | label + symbol in `chromeDestructive`; same shape/fill as default so red is the only difference *in addition to* the trash symbol and wording |

### 4.3 Secondary/utility controls
- **Icon-only buttons** (back chevron, close): 44 × 44 pt minimum hit target with the
  symbol at 20–22 pt; no visible container until pressed (then a `chromeSurfaceRaised`
  circle appears behind it).
- **Toggles** (Sound): standard SwiftUI `Toggle`, tinted `chromeAccent` when on. The
  on/off state is carried by knob position + the row's trailing SF Symbol swap
  (`speaker.wave.2` on / `speaker.slash` off), so the toggle is never color-only.
- **Hit targets:** ≥ 44 × 44 pt everywhere, both devices, no exceptions. Settings rows
  are ≥ 52 pt tall and tappable across their full width.

## 5. Screen layouts

### 5.1 Main Menu
- **Backdrop:** flat `chromeBackdrop` with the keyhole emblem (the launch-screen mark,
  Section 10.2) rendered faintly at ~8% white, large and off-center behind the content
  — the only decoration. No level art on the main menu; the room art stays behind the
  "door."
- **Layout (landscape):** game title in serif, upper third, centered. Below it a single
  centered column: **Play** (continues to Level Select), **Settings**. Two buttons
  only. Version string is not shown here (it lives in Settings).
- "Play" is the visually dominant element after the title; Settings may alternatively
  be the gear icon-button in a corner if the user prefers an even sparser menu —
  default spec is the two-button column.

### 5.2 Level Select
- **Structure:** a horizontal row (wraps to grid as level count grows) of **level
  cards** on `chromeBackdrop`, with a plain serif "Levels" title or no title at all —
  prefer no title; a back chevron (top-leading, safe-area-inset) returns to Main Menu.
- **Level card:** rounded rectangle (16 pt radius), `chromeSurface`, hairline stroke.
  - iPad: 220 × 165 pt (4:3, echoing the play frame). iPhone: 150 × 112 pt.
  - Card content: the level's **title-card art as a thumbnail** filling the card
    (per-level content inside theme-independent chrome — permitted), with a bottom
    gradient-to-`chromeSurface` band carrying the level number in serif
    ("1", "2", …) at `.title3`.
  - Until a level's art exists, the placeholder is the number centered on
    `chromeSurface`.
- **Completion indicator (color-blind-safe by shape + position, mandatory):**
  - **Completed:** a `checkmark.circle.fill` SF Symbol badge, 24 pt (iPad) / 20 pt
    (iPhone), pinned to the card's **top-trailing corner**, rendered in
    `chromeTextPrimary` on a `chromeBackdrop` circle. State is carried by the
    *checkmark shape* and its *fixed corner position* — no green, no hue channel at
    all. Accessibility label: "Level N, completed."
  - **Unlocked, not completed:** no badge. Clean card.
  - **Locked:** thumbnail dimmed to 35% opacity + `lock.fill` symbol centered on the
    card at 28 pt in `chromeDisabled`, and the number band grayed. Cue = lock shape +
    dimming + non-tappable, never dimming alone. Accessibility label: "Level N,
    locked."
- Card tap: pressed state per 4.2, then the menu→game transition (Section 6).

### 5.3 Pause Menu
- **Invocation:** the in-game corner rune-glyph button (Level style guide Section 7)
  opens the pause layer; game freezes on the current frame.
- **Presentation:** `chromeScrim` fades in over the frozen scene (200 ms), then a
  centered vertical stack of four primary buttons: **Resume**, **Restart Level**,
  **Settings**, **Main Menu** — that order, top to bottom (safe action first,
  navigation-away last). 16 pt spacing between buttons.
- No panel/card behind the stack: buttons float on the scrim (each carries its own
  `chromeSurface` fill, so legibility is guaranteed over any art). No "Paused" title —
  the frozen dimmed scene says it.
- **Restart Level** is destructive-adjacent (loses in-level progress): it gets a
  confirmation dialog per Section 7 pattern with verb "Restart" (standard, not red —
  it destroys minutes, not the save file). **Main Menu** does *not* confirm: in-level
  state persists per the game's requirement-based state model, so leaving is safe; if
  the Developer finds mid-puzzle transient state that would be lost, escalate rather
  than silently adding a dialog.
- Tapping the scrim outside the stack = Resume. Hardware Esc / controller Menu =
  Resume.
- Settings opens as a sheet *over* the pause layer (Section 5.4); dismissing it
  returns to the pause stack, not the game.

### 5.4 Settings
- **Presentation:** from Main Menu — a push within the menu NavigationStack; from
  Pause — a sheet (`.presentationDetents([.medium, .large])` on iPhone, standard
  centered sheet on iPad). Same content either way.
- **Layout:** grouped rows on `chromeSurface`, 52 pt min height, in this order:
  1. **Music & Ambiance** — row with leading symbol (`speaker.wave.2` / `speaker.slash`,
     swapping with state), label "Music & Ambiance", trailing Toggle. Controls the level
     background music + per-zone ambient beds. (Updated R2-006, 2026-07-08: the single
     master toggle was split into two independent, separately-persisted toggles once the
     Developer added user-provided background music.)
  2. **Sound Effects** — row with leading symbol (`speaker.wave.2.fill` /
     `speaker.slash.fill`, swapping with state), label "Sound Effects", trailing Toggle.
     Controls interaction cues (pickup/solve/unlock/door/page/etc.). Independent of the
     Music & Ambiance toggle.
  3. **Reset Progress** — full-width row, label + `trash` symbol in
     `chromeDestructive`. Tap → confirmation per Section 7.
  4. **About** — row with `info.circle`, pushes/presents a simple credits sheet:
     game title (serif), one-line description, credits list, licenses if any. The one
     place body text is allowed.
  5. **Version footer** — below the group, centered, `chromeTextSecondary`,
     `.footnote`: "Version 1.0 (42)". Not a row, not tappable.
- No account, no notifications, no purchases (free app, no IAP at launch).

## 6. Menu ↔ game transition convention

The series' in-game grammar (Level 1 guide, Section 7) reserves **600 ms
dip-to-near-black with vignette** for zone-to-zone passage. The menu layer extends that
grammar one ring outward:

- **Level Select → level (entering the room):** 700 ms dip-to-black with vignette
  close, hold black ~150 ms while the scene loads, then fade up on the level's title
  card / opening view. Entering a level is the biggest "threshold" in the game and gets
  the longest dip. A muted diegetic sound (door, latch — per level's sound direction)
  may accompany it; the visual convention is fixed and theme-independent.
- **In-game → Pause:** no dip — instant freeze + 200 ms scrim fade (Section 5.3).
  Pausing is not a threshold; the room stays visible behind the scrim to keep the
  player anchored.
- **Pause → Resume:** 150 ms scrim fade-out. **Pause → Main Menu / Restart:** 500 ms
  dip-to-black, then menu fade-up or level reload.
- **Within the menu layer** (Main ↔ Level Select ↔ Settings): standard NavigationStack
  push/pop and sheet presentations at system defaults. No dips inside the chrome —
  dips exclusively mean "crossing between the menu world and the room world" (or
  between zones, in-game).
- Never crossfade menu chrome directly over moving scene content; the black dip is
  what keeps the flat chrome and painterly art from ever being on screen mid-blend.

## 7. Destructive-action confirmation pattern (Reset Progress)

Two-step, standard-component, impossible to trigger by one stray tap:

1. Row tap presents a SwiftUI **alert** (not a confirmationDialog — an alert is more
   interruptive, which is correct for save-file deletion):
   - Title: "Reset all progress?"
   - Message: "Every level returns to unsolved. This can't be undone."
   - Buttons: **Cancel** (`.cancel`, default focus/prominence) and **Reset**
     (`.destructive` role — system renders it red and bold).
2. The destructive cue is triple-channel: red color + explicit verb ("Reset", never
   "OK") + trash symbol on the originating row. A color-blind player reads the wording
   and roles; color is reinforcement only.
3. After confirmation: perform reset, dismiss, and show the Level Select/Settings state
   visibly changed (badges gone, levels re-locked). No success toast — the visible
   state change is the feedback, in keeping with the wordless sensibility.

The same alert pattern (with non-destructive styling and verb "Restart") is reused for
Pause → Restart Level.

## 8. SF Symbol conventions (Developer implements; no custom menu icons)

| Context | Symbol | Notes |
|---|---|---|
| Settings entry | `gearshape` | |
| Music & Ambiance on / off | `speaker.wave.2` / `speaker.slash` | Swap with toggle state (R2-006) |
| Sound Effects on / off | `speaker.wave.2.fill` / `speaker.slash.fill` | Swap with toggle state; distinct filled variant from the ambiance row (R2-006) |
| Reset Progress | `trash` | `chromeDestructive` |
| About | `info.circle` | |
| Main Menu (from pause) | `house` | |
| Restart Level | `arrow.counterclockwise` | |
| Resume | `play.fill` (optional; label may stand alone) | |
| Back navigation | `chevron.backward` | |
| Completed badge | `checkmark.circle.fill` | Level cards, top-trailing |
| Locked level | `lock.fill` | Centered on locked cards |

Rules:
- **Weight:** `.medium` symbol weight everywhere (matches SF Pro Medium labels).
  **Rendering:** monochrome only — no hierarchical, palette, or multicolor rendering;
  color comes from the token system (`chromeTextPrimary` default).
- **Size:** symbols inline with text match the text size (`imageScale(.medium)`);
  standalone icon buttons 20–22 pt; card badges per 5.2.
- Always pair a symbol with a text label in menus (buttons, rows). Icon-only is
  permitted solely for back/close chevrons and the in-game pause glyph (which is the
  level layer's engraved-rune button, not an SF Symbol — see Level 1 guide 7).
- Do not introduce symbols beyond this table without adding them here first; the
  vocabulary stays tiny on purpose.

## 9. Color-blind and accessibility mandate (binding)

- **No state in this layer is color-only.** Completion = checkmark shape + fixed
  position; locked = lock shape + dim + disabled; toggle = knob position + symbol
  swap; destructive = wording + role + symbol, red as reinforcement.
- **Grayscale check:** every chrome screen must read perfectly when desaturated. Since
  the palette is 95% neutral already, the only thing to verify is the destructive red
  (whose meaning survives via wording) — but run the check on every screen anyway.
- All interactive elements carry accessibility labels; level cards announce number +
  lock/completion state (5.2). Buttons are real `Button`s (VoiceOver traits for free).
- Respect **Reduce Motion**: replace dips-with-vignette by simple opacity fades of the
  same duration; replace button press-scale with fill change only.

## 10. Custom-art briefs (Asset Generation Agent, Flux 2 Pro) — the ONLY custom art in this layer

### 10.1 App icon
- **Concept:** a single antique **keyhole, glowing faintly from within**, set in dark
  aged wood — the series' promise ("there is a way out") without depicting any level's
  theme. No crow, no moon, no level-specific props: the icon must survive ten future
  themes.
- **Composition:** keyhole plate centered, filling ~55–60% of the canvas height;
  painterly realism matching the series register (oil-texture wood grain, worn brass
  escutcheon, soft warm light leaking through the keyhole against a neutral-dark
  surround). Reads at 60 px: one strong silhouette, one light source, nothing else.
- **Palette:** neutral dark wood (`#1A1714`-ish), dulled brass, one warm light leak
  (`#D9973F` family — the series' amber). This is in-world art, so warm color is
  allowed here, unlike the chrome.
- **Constraints:** no text, no letters, no border/frame (iOS masks the shape), no
  gloss/bevel effects, composition safe under the superellipse mask (nothing critical
  in corners). Deliver 1024 × 1024 master.
- **Prompt seed:** *"iOS app icon, painterly realism oil painting texture, close-up of
  an antique brass keyhole escutcheon on dark aged oak wood, warm candlelight glowing
  through the keyhole from the other side, moody, muted palette, centered composition,
  no text, no letters"*.

### 10.2 Launch screen
- **Concept:** the Main Menu backdrop, minus interactivity — near-black neutral field
  with the **keyhole emblem** (a simplified, flat, single-color mark derived from the
  app icon's keyhole silhouette) centered at ~10–12% white. Cold start then feels like
  the menu simply "wakes up" around the mark (the menu reuses the same emblem at 8%,
  Section 5.1).
- **Execution note:** the emblem should be delivered as a clean high-res silhouette
  (white on transparent) so the Developer can place it in the launch storyboard/
  configuration and reuse it in the Main Menu at a different opacity. This is a
  derivation/cleanup task from the approved icon art — generate the icon first, then
  extract/redraw the emblem.
- **Constraints:** background exactly `chromeBackdrop` `#101010`; no text, no logo
  type, no loading indicator. Launch screen must be visually identical to the Main
  Menu's empty backdrop per Apple guidance (launch → menu should feel like a fade-in,
  not a screen swap).

## 11. Device scaling (iPad primary / iPhone secondary)

- **Orientation:** the game's 2:1 master plates imply a **landscape-locked app**; the
  menu layer is therefore specified landscape-first. If portrait support is ever
  added, this document needs a portrait pass. (Assumption flagged in Section 12.)
- **iPad:** menu content lives in a centered column, max content width 620 pt; the
  backdrop extends edge-to-edge. Level Select grid: up to 4 cards per row with 24 pt
  gutters. Sheets are centered standard sheets. Support pointer/trackpad hover: hover
  = the focused state ring from 4.2.
- **iPhone:** same structure, full-width minus safe areas; Level Select cards at the
  smaller size (5.2) in a horizontally scrolling row if a grid row would drop cards
  below 150 pt wide. All content respects notch/Dynamic Island and home-indicator
  insets; nothing interactive within 24 pt of screen edges (matches the in-game rule).
- Hit targets ≥ 44 pt on both devices (4.3); the completion badge and lock are
  indicators, not targets — the whole card is the target.
- Test matrix floor: 12.9" iPad and the smallest supported iPhone, at default and XXL
  Dynamic Type.

## 12. Judgment calls flagged for user approval

- **J1 — Serif accent (New York) for the title and level numbers.** Pure SF Pro
  everywhere is the flatter, safer alternative; the system serif adds a quiet
  storybook note bridging toward the painterly art without breaking theme
  independence. Recommend serif; trivially reversible.
- **J2 — Fixed dark-only appearance.** Menus ignore system light mode. Recommended for
  cohesion with night-leaning level art and a single QA surface; App Store screenshots
  will always match reality.
- **J3 — Level cards show per-level title-card art thumbnails** inside the neutral
  chrome frame. Alternative: pure numbered cards, fully theme-free. Thumbnails make
  Level Select the game's "shelf of doors" and aid recognition; the chrome (frame,
  badges, lock) stays theme-independent either way. Recommend thumbnails.
- **J4 — Keyhole as the app-identity motif** (icon, launch emblem, menu backdrop
  watermark) rather than a Level-1 crow/moon motif. Chosen for theme independence
  across the whole series; but the crow icon would market Level 1 harder. Recommend
  keyhole.
- **J5 — Main Menu ≠ confirmation, Restart Level = confirmation** (Section 5.3),
  premised on requirement-based state persisting across menu exits. If the Developer's
  save model diverges, this pairing must be revisited rather than silently changed.
- **J6 — Landscape-locked assumption** (Section 11). No spec file records an
  orientation decision; the 2:1 plates and 4:3/19.5:9 crop system strongly imply
  landscape-only. Needs an explicit user/Developer confirmation so the chrome isn't
  built for an orientation the game won't ship.
