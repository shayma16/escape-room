# Release Notes — iOS Release Manager

Maintained by the Release Manager agent. Records release-pipeline decisions and state.
Not App Store marketing copy (that comes later, phase 3+).

## Phase 1 — TestFlight prep (2026-07-07, branch `release-testflight-prep`)

Scope: prepare the QA-approved Level 1 build ("Within") for TestFlight internal testing
only. No App Store metadata, no marketing screenshots, no workflow runs triggered
(signing secrets do not exist yet; macOS runners bill 10x — a run would only fail).

### Fixed identity (locked decisions — do not reopen)

| Item | Value |
|---|---|
| App display name | Within |
| Bundle ID (app) | `com.shayma.within` — **locks permanently at first ASC upload** |
| Bundle ID (tests) | `com.shayma.within.tests` / `com.shayma.within.uitests` |
| Marketing version | 1.0 (workflow input, default `1.0`) |
| Build number | Auto: release.yml run number (`github.run_number`); manual override input available |
| Business | Free, no IAP at launch |
| Platform | iOS 17+, landscape-locked, iPad + iPhone |

### Changes made in this phase

1. `EscapeRoom/EscapeRoom.xcodeproj/project.pbxproj` — placeholder bundle IDs
   (`com.escaperoom.app.wizardscabin[.tests|.uitests]`) replaced with the values above
   in all Debug/Release configs. MARKETING_VERSION 1.0 / CURRENT_PROJECT_VERSION 1
   were already correct.
2. `EscapeRoom/EscapeRoom/Info.plist` — `CFBundleDisplayName` set to `Within`; added
   `ITSAppUsesNonExemptEncryption = false` (HTTPS-only exemption) so TestFlight builds
   do not stall on the manual "Missing Compliance" question.
3. `.github/workflows/release.yml` — placeholder stubs replaced with the real pipeline
   (see design below).
4. Not changed: `"The Wizard's Cabin"` strings in Swift UI files — those are the Level 1
   *title* (content), not the app name; `MainMenuView` reads the app name from
   `CFBundleDisplayName` at runtime. The stale hardcoded *fallback* literal in
   `MainMenuView.swift:66` never triggers (the plist key exists); flag to Producer if a
   code-side cleanup pass happens anyway.

### release.yml design decisions

- **Signing: cloud-managed automatic signing.** `xcodebuild archive` runs with
  `-allowProvisioningUpdates` + `-authenticationKeyPath/-authenticationKeyID/
  -authenticationKeyIssuerID` (App Store Connect API key). Xcode creates/downloads the
  Apple Distribution certificate and App Store profile itself on the runner. **No
  `.p12`/provisioning-profile secrets and no keychain-import step are needed.**
  Contingency: if the first real run fails at certificate creation with an ASC
  permissions error, options are (a) recreate the API key with Admin role, or
  (b) fall back to a manually exported distribution cert — secrets `CERT_P12_BASE64` +
  `CERT_PASSWORD` plus a temp-keychain import step. Neither is included now; add only
  if actually hit.
- **Upload: native `xcodebuild -exportArchive` with `destination: upload`** in
  ExportOptions.plist (method `app-store-connect`) — the same path Xcode Organizer
  uses. Chosen over fastlane pilot (Ruby gem drift, extra setup on a bare runner) and
  `xcrun altool` (deprecated for App Store uploads). The archive is exported twice
  from one `.xcarchive`: first `destination: export` to disk (artifact + security
  scan), then `destination: upload` — only after the security gate passes.
- **Build numbering:** `CURRENT_PROJECT_VERSION = github.run_number` of release.yml
  (monotonic, no state file), with a manual `build_number` dispatch input as override.
  Marketing version is a dispatch input defaulting to 1.0.
- **Security re-check (blocking gate before upload),** per the Release Manager mandate:
  1. Unzips the actual exported `.ipa` and scans the full payload (binary included)
     for dev-time secrets: key-bearing files (`.p8/.p12/.pem/.env/.netrc`) and secret
     string patterns (FAL_KEY / fal.ai keys, `sk-…`, AWS `AKIA…`, GitHub `ghp_…`/
     `github_pat_`, PEM private-key headers, generic `api_key: …`).
  2. Dumps the signed entitlements (`codesign -d --entitlements`) and fails on anything
     outside the automatic-signing baseline (application-identifier, team-identifier,
     get-task-allow, beta-reports-active, keychain-access-groups); also fails if any
     `NS*UsageDescription` permission key appears in the shipped Info.plist — the game
     needs none of camera/mic/location/contacts.
  A failure blocks the upload step and routes back to the Producer.
- Artifacts on every run (even failures): exported `.ipa`, entitlements dump,
  archive Info.plist.

### Required GitHub Secrets (user creates; values never touch repo/chat)

| Secret | Content |
|---|---|
| `ASC_KEY_ID` | App Store Connect API Key ID (10 chars) |
| `ASC_ISSUER_ID` | Issuer ID (UUID, top of the Integrations > API keys page) |
| `ASC_KEY_P8` | Full contents of the downloaded `AuthKey_<KEYID>.p8` (raw or base64 both accepted) |
| `APPLE_TEAM_ID` | 10-character Team ID (developer.apple.com > Account > Membership details) |

Exact commands are in the release.yml header comment.

### User to-do before phase 2 (requires their authenticated Apple account; agent never handles these credentials)

1. Register the bundle ID: developer.apple.com/account > Certificates, Identifiers &
   Profiles > Identifiers > + > App IDs > App; description "Within", explicit bundle ID
   `com.shayma.within`, **no capabilities beyond defaults**.
2. Create the ASC API key: App Store Connect > Users and Access > Integrations >
   App Store Connect API > Team Keys > +; role **App Manager**. Note the Key ID and
   Issuer ID; download the `.p8` (single download — keep it outside the repo).
3. Create the app record: App Store Connect > My Apps > + > New App; platform iOS,
   name "Within", primary language, bundle ID `com.shayma.within`, any SKU (e.g.
   `within-001`). **The bundle ID locks at this point/first upload.**
4. Run the four `gh secret set` commands from the release.yml header.
5. TestFlight (can be done after the first upload): app > TestFlight > Internal
   Testing > + group, add own Apple ID as tester; install the TestFlight app on device.

### Phase 2 (next) — first TestFlight upload

Prerequisites: user to-dos 1–4 complete. Then the Release Manager:
`gh workflow run release.yml` (defaults: version 1.0, build = run number) →
`gh run watch` → verify security-gate output and upload success → `gh run download`
for the `.ipa` artifact record → confirm build appears in TestFlight processing →
hand off to user for device install and physical-device spot-check (user checkpoint,
step 16). Failure modes to watch: ASC permissions on cloud cert creation (see
contingency above), missing app record ("no suitable application records"), Apple
processing rejections (emailed to the account holder).
