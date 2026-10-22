# Agent Context: NoiseRadar iPhone App

Last reviewed: 2026-10-22

## Mandatory Agent Rule

Every AI agent that changes this repository must update this file in the same turn.

For each change, add an entry under `Change Log` with:
- Date.
- Files changed.
- What changed.
- Why it changed.
- Any verification performed, or why verification was not performed.

Do not leave code, project settings, assets, documentation, or behavior changes undocumented here.

## App Summary

NoiseRadar is an iOS SwiftUI app that estimates the direction of the loudest sound source and labels the general sound type offline. It reads microphone buffers while reading the iPhone compass heading as the user slowly rotates 360 degrees. After scanning, it reports the heading where the strongest filtered sound signal was measured and also shows direction results by sound category. During scanning or foreground Listen mode, it uses Apple's built-in SoundAnalysis classifier locally on device to show broad sound type categories such as human voice, vehicles, mechanical sounds, animals, alarms, music, nature, household, and impact sounds. The app keeps recent local in-memory sound events for scan/listen history, supports configurable foreground threshold alerts, offers a manual dB calibration offset, and can share local text/CSV session reports.

The app is meant to run on a physical iPhone. The iOS Simulator is not suitable because accurate microphone, compass, and motion behavior require device sensors.

## Project Layout

- `NoiseRadar/NoiseRadar.xcodeproj`: Xcode project.
- `NoiseRadar/NoiseRadar/NoiseRadarApp.swift`: SwiftUI app entry point.
- `NoiseRadar/NoiseRadar/AdSupport.swift`: Google Mobile Ads setup, production AdMob IDs, and SwiftUI banner wrapper.
- `NoiseRadar/NoiseRadar/LanguageSupport.swift`: In-app language pack, supported language list, phrase translations, and translation helpers.
- `NoiseRadar/NoiseRadar/PurchaseSupport.swift`: StoreKit 2 Remove Ads purchase manager and ad-free entitlement state.
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`: Main SwiftUI interface, radar visualization, help sheet, controls, and status display.
- `NoiseRadar/NoiseRadar/AudioDirectionManager.swift`: Sensor, microphone, offline sound classification, scan state, signal processing, and result analysis logic.
- `NoiseRadar/NoiseRadar/Info.plist`: App display name and permission usage strings.
- `NoiseRadar/NoiseRadar/Assets.xcassets`: App icon and launch image assets.
- `README.md`: User-facing project summary and quick start.
- `how_to_deploy.md`: Xcode deployment guide.
- `app_store_deploy.md`: App Store submission guide with metadata, review notes, privacy, screenshots, and deployment checklist.
- `image_prompts.md`: Image-generation prompts for the app icon, launch screen, and App Store custom product page header.
- `road_map.md`: Product roadmap with prioritized feature ideas, customer/trend rationale, implementation phases, and concrete tickets.
- `suggestions.md`: Improvement backlog.

## Current Build Settings Observed

- Swift version: 5.0.
- iOS deployment target: 15.0.
- Bundle identifier: `lt.bourdo.NoiseRadar`.
- Development team currently set in the Xcode project: `8J9SSA37RS`.
- Marketing version: `1.1`.
- Build number: `1`.
- App Store export options: `build/AppStoreExport/ExportOptions.plist`.
- Target device family: iPhone only (`TARGETED_DEVICE_FAMILY = 1`).
- Supported platforms: `iphoneos iphonesimulator`.
- Mac Catalyst, Designed for iPhone/iPad on Mac, and Designed for iPhone/iPad on Vision Pro are disabled.
- Google Mobile Ads Swift Package is linked from `https://github.com/googleads/swift-package-manager-google-mobile-ads.git`, up to next major from `13.0.0`.
- `Package.resolved` currently pins GoogleMobileAds `13.11.0` and GoogleUserMessagingPlatform `3.1.0`.
- Remove Ads is implemented as a StoreKit 2 non-consumable with product ID `lt.bourdo.noiseradar.remove_ads`.
- The ad-free entitlement is cached with `UserDefaults` key `isAdFree` and refreshed from current StoreKit entitlements.
- In-app language selection is persisted with `@AppStorage("appLanguageCode")`; Settings shows one Language row that opens a flag/checkmark language picker sheet.
- Belarusian uses a drawn white-red-white flag view in the in-app language picker.
- The language pack currently supports English, German, Spanish, French, Italian, Polish, Czech, Romanian, Lithuanian, Latvian, Estonian, Swedish, Finnish, Ukrainian, Greek, and Belarusian.

## How The App Works

`NoiseRadarApp` opens `SoundRadarView`.

`NoiseRadarApp` also initializes Google Mobile Ads through `AdMobSupport.configure()`, setting the SDK max ad content rating to General before startup.

`NoiseRadarApp` owns a `PurchaseManager` as a `@StateObject` and injects it as an environment object so the banner wrapper and Settings can read the Remove Ads entitlement.

`SoundRadarView` owns one `@StateObject` instance of `AudioDirectionManager`. It renders:
- A 320x50 AdMob banner at the top of the main screen, Help, History, Settings, and onboarding for free users.
- No AdMob banner once `PurchaseManager.isAdFree` is true after Remove Ads purchase or restore.
- Localized text through `LanguagePack`, including the main screen, Help, History, Settings, onboarding, modes, alert styles, categories, readiness labels, status messages, and sound-category labels.
- App title and usage prompt.
- Segmented mode control for `Scan 360` and `Listen`.
- Radar circle with N/E/S/W labels.
- A green polar sound blob from sampled headings and signal magnitudes.
- A red arrow showing current phone heading.
- A green result marker after analysis.
- A live volume circle whose size is derived from current decibels.
- Scan/listen status, progress, quality, raw/smoothed decibels, top 3 headings, threshold alert status, direction-by-sound-type cards, readiness checklist, and Start/Stop controls.
- History sheet for recent local sound events.
- Settings sheet for threshold alerts and calibration offset.
- Settings sheet includes one Language row that opens a separate flag/checkmark language picker.
- Settings sheet includes an Ad-Free section with Remove Ads and Restore Purchases controls.
- Free users see a main-screen `Remove banner ads.` prompt that opens the Remove Ads purchase sheet, matching the Dust Cleaner Remove Ads flow.
- Share sheet for generated text and CSV session report files.
- First-run onboarding sheet using `@AppStorage("hasSeenOnboarding")`.
- A Help sheet with basic usage steps.

`AudioDirectionManager` coordinates:
- `AVAudioSession` and `AVAudioEngine` for microphone input, configured as play-and-record so sound alerts can play while listening.
- `SNAudioStreamAnalyzer` and `SNClassifySoundRequest(classifierIdentifier: .version1)` for offline on-device sound classification.
- `CLLocationManager` for magnetic heading updates.
- `CMMotionManager` for rotation-rate checks.
- Decibel calculation from live PCM audio buffers.
- `DetectionMode.scan360` and `DetectionMode.listen` modes.
- Per-category direction scoring from signal strength and sound classification confidence.
- Local in-memory recent sound event history, capped at 50 events.
- Persisted threshold alert settings in `UserDefaults`.
- Manual dB calibration offset applied to live decibel readings.
- Text and CSV session report generation into temporary files for iOS sharing.

## Scan Flow

1. On initialization, the manager requests microphone permission, requests When In Use location permission, starts heading updates, configures the audio session, and starts device-motion updates when available.
2. The user taps `Start Scan`.
3. The manager clears previous samples and enters a 1.5 second calibration phase.
4. During calibration, smoothed decibel samples are averaged to initialize the noise floor.
5. After calibration, the user slowly rotates 360 degrees.
6. Every microphone buffer, the manager:
   - Calculates raw decibels from PCM sample RMS.
   - Applies exponential moving average smoothing.
   - Updates the adaptive noise floor.
   - Computes adjusted signal above the noise floor.
   - Applies a simple high-pass filter.
   - Rejects samples if rotation is too fast.
   - Stores heading, raw decibels, smoothed decibels, and filtered signal.
   - Updates scan progress from accumulated heading movement.
   - Updates top headings and polar visualization data.
   - Sends the same buffer to SoundAnalysis on a dedicated queue for local sound classification.
7. The user taps `Stop & Analyze`.
8. The manager chooses the sample with the highest signal if it is above the minimum signal threshold.
9. The manager also builds direction-by-sound-type results from classified samples.
10. The UI displays the loudest heading, result marker, and category direction cards.

In Listen mode:

1. The user selects `Listen`.
2. The manager calibrates briefly and starts processing microphone buffers in the foreground.
3. The app shows current sound type and creates local recent sound events when a confident sound category is detected.
4. Stop ends listening without running scan analysis.

## Important Signal Constants

These constants are currently in `AudioDirectionManager.swift`:
- EMA smoothing alpha: `0.2`.
- Noise floor down alpha: `0.2`.
- Noise floor up alpha: `0.02`.
- High-pass alpha: `0.9`.
- Minimum detected signal: `3.0`.
- Calibration duration: `1.5` seconds.
- Maximum accepted rotation rate: `2.0`.
- Noisy environment threshold: `-35.0` dB.
- Sound classifier window duration: `1.5` seconds.
- Sound classifier overlap factor: `0.8`.

## Permissions

`Info.plist` declares:
- `NSMicrophoneUsageDescription`: required for reading microphone sound levels.
- `NSLocationWhenInUseUsageDescription`: required because compass heading is accessed through Core Location.
- `NSMotionUsageDescription`: explains device motion use for rotation-speed checks.

## Current Known Gaps And Risks

- Location authorization is tracked but `startScanning()` currently only blocks on microphone authorization, not location authorization.
- The app uses magnetic heading only; no true-heading option is implemented.
- Scan progress accumulates absolute heading deltas, so back-and-forth rotation can count toward 360 degrees.
- Audio input is stopped on manual stop, but there is no explicit app-background or view-disappear cleanup.
- Sound type labels are best-effort classifications from Apple's built-in SoundAnalysis model and can be wrong when sounds overlap, the room is noisy, or the source is quiet.
- History is currently local in-memory only and is not persisted across app launches.
- Threshold alerts are foreground-only and best-effort; sound alerts may be picked up by the microphone in quiet environments.
- No automated tests are currently present.
- The StoreKit product `lt.bourdo.noiseradar.remove_ads` must be created in App Store Connect before production purchase testing; until then, the app will show the purchase as unavailable.

## Verification Notes

Because this app depends on real iPhone microphone, compass, and motion sensors, meaningful end-to-end verification should be done on a physical iPhone through Xcode.

For code-only changes, useful checks include:
- Open `NoiseRadar/NoiseRadar.xcodeproj` in Xcode.
- Build the `NoiseRadar` scheme for a real device.
- Confirm microphone and location permissions are requested.
- Start a scan, wait for calibration, rotate slowly 360 degrees, stop, and verify a loudest heading appears.
- Verify the `Sound type` line updates offline on a physical iPhone with internet disabled.
- Verify `Listen` mode logs local history events without requiring rotation.
- Verify threshold alerts, screen flash, haptic/sound alert styles, calibration offset, and Share report output on a physical iPhone.

## Change Log

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar/PurchaseSupport.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar/LanguageSupport.swift`
- `app_store_deploy.md`
- `agent_context.md`

What changed:
- Added a Dust Cleaner-style main-screen `Remove banner ads.` prompt for free users.
- Added a dedicated `RemoveAdsView` sheet with purchase, restore, ad-free status, and StoreKit status text.
- Kept Settings as a secondary Ad-Free path, but changed its Remove Ads action to open the same sheet.
- Added a `€0.99` fallback price label while still using StoreKit `displayPrice` when the product loads.
- Updated App Store Connect setup guidance to use a `EUR 0.99` launch price and the main-screen Remove Ads review path.

Why:
- The user asked to match the Dust Cleaner Remove Ads experience and use a `0.99 EUR` price for this app.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.
- Ran `xcodebuild -project NoiseRadar/NoiseRadar.xcodeproj -scheme NoiseRadar -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`; build succeeded.

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar/LanguageSupport.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `agent_context.md`

What changed:
- Replaced the temporary text/block Belarusian flag marker with a dedicated SwiftUI white-red-white flag view.
- Updated the Settings selected-language row and language picker rows to render the Belarusian white-red-white flag as an actual bordered flag icon, while keeping normal emoji flags for the other languages.

Why:
- The user clarified that the MyFinance-style implementation should show the correct Belarusian white-red-white flag, not a block-text approximation.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.
- Ran `xcodebuild -project NoiseRadar/NoiseRadar.xcodeproj -scheme NoiseRadar -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`; build succeeded.

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar/LanguageSupport.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `agent_context.md`

What changed:
- Replaced the Belarusian language flag marker from the red-green state emoji to a white-red-white marker.
- Widened the language picker flag slot so the white-red-white marker fits without clipping.

Why:
- The user corrected that the Belarusian language option must use the white-red-white Belarusian flag representation, not the red-green Lukashenko state flag.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.
- Ran `xcodebuild -project NoiseRadar/NoiseRadar.xcodeproj -scheme NoiseRadar -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`; build succeeded.

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar/NoiseRadarApp.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar/LanguageSupport.swift`
- `NoiseRadar/NoiseRadar/PurchaseSupport.swift`
- `NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`
- `app_store_deploy.md`
- `agent_context.md`

What changed:
- Added StoreKit 2 Remove Ads support with non-consumable product ID `lt.bourdo.noiseradar.remove_ads`.
- Added a root `PurchaseManager` environment object, product loading, purchase, restore, transaction update handling, entitlement refresh, and cached ad-free state.
- Gated the shared top AdMob banner so it is shown only to free users and is hidden once Remove Ads is purchased or restored.
- Confirmed the shared top banner wrapper is used on the main screen, Help, History, Settings, and onboarding.
- Reworked Settings language selection from inline flag rows into one Language row that opens a separate flag/checkmark language picker sheet.
- Added localized purchase/status strings for the supported language pack.
- Updated App Store deployment notes for app version `1.1`, Google Mobile Ads, StoreKit, and the Remove Ads IAP setup/review path.

Why:
- The user requested the MyFinance-style language selector and an in-app Remove Ads purchase so paid users can use the app forever without advertisements.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.
- Ran `xcodebuild -project NoiseRadar/NoiseRadar.xcodeproj -scheme NoiseRadar -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`; build succeeded after rerunning outside the sandbox because Xcode needed DerivedData, SwiftPM, and simulator cache access.

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar/LanguageSupport.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `agent_context.md`

What changed:
- Added flag metadata to each supported app language.
- Replaced the plain scrolling SwiftUI language picker in Settings with finance-style tappable flag rows and a checkmark for the selected language.

Why:
- The user clarified that the language pack should match the finance app style with flags, not the current scrolling picker.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.
- Ran `xcodebuild -project NoiseRadar/NoiseRadar.xcodeproj -scheme NoiseRadar -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`; build succeeded.

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`
- `agent_context.md`

What changed:
- Bumped the NoiseRadar target marketing version from `1.0` to `1.1` for Debug and Release builds.
- Updated the observed build settings in this context file.

Why:
- The user clarified that this update should be the new app version `1.1`.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar/LanguageSupport.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`
- `agent_context.md`

What changed:
- Added the same 16-language in-app language pack pattern documented for Magnetic Multi-Tool: English, German, Spanish, French, Italian, Polish, Czech, Romanian, Lithuanian, Latvian, Estonian, Swedish, Finnish, Ukrainian, Greek, and Belarusian.
- Added a Settings > Language picker backed by `@AppStorage("appLanguageCode")`.
- Localized the NoiseRadar main screen, Help sheet, History sheet, Settings sheet, onboarding, primary actions, mode names, alert styles, sound categories, readiness labels, quality/status labels, and dynamic sound-status/category displays.
- Added `LanguageSupport.swift` to the Xcode target.

Why:
- The user asked to deploy the same language-pack approach used by prior apps and provide a fully translated app interface for NoiseRadar.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.
- Ran `xcodebuild -project NoiseRadar/NoiseRadar.xcodeproj -scheme NoiseRadar -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`; build succeeded.
- Rebuilt after removing duplicate translation dictionary keys; build succeeded without duplicate-key warnings.

### 2026-10-22

Files changed:
- `NoiseRadar/NoiseRadar/AdSupport.swift`
- `NoiseRadar/NoiseRadar/NoiseRadarApp.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar/Info.plist`
- `NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`
- `NoiseRadar/NoiseRadar.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved`
- `agent_context.md`

What changed:
- Added the Google Mobile Ads Swift Package dependency and linked the `GoogleMobileAds` product.
- Added `AdSupport.swift` with the NoiseRadar production AdMob app ID `ca-app-pub-2367013361044576~9236993009`, banner ad unit ID `ca-app-pub-2367013361044576/3564109908`, General Audience SDK request configuration, and a SwiftUI `BannerAdView`.
- Initialized Google Mobile Ads from `NoiseRadarApp`.
- Added a 320x50 top banner to `SoundRadarView`.
- Added `GADApplicationIdentifier` and Google-published `SKAdNetworkItems` entries to `Info.plist`.
- Added the Xcode-generated SwiftPM lockfile pinning GoogleMobileAds `13.11.0` and GoogleUserMessagingPlatform `3.1.0`.

Why:
- The user created a dedicated NoiseRadar AdMob app and banner unit and asked to implement the same banner AdMob solution used by prior iOS apps.

Verification:
- Ran `plutil -lint NoiseRadar/NoiseRadar/Info.plist`.
- Ran `plutil -lint NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`.
- Ran `xcodebuild -list -project NoiseRadar/NoiseRadar.xcodeproj`, which resolved GoogleMobileAds `13.11.0` and GoogleUserMessagingPlatform `3.1.0`.
- Ran `xcodebuild -project NoiseRadar/NoiseRadar.xcodeproj -scheme NoiseRadar -configuration Debug -sdk iphonesimulator -destination 'generic/platform=iOS Simulator' build CODE_SIGNING_ALLOWED=NO`; build succeeded.

### 2026-10-20

Files changed:
- `shared_experience/ios_apps_experience/noisy_direction/web_integrate.md`
- `agent_context.md`

What changed:
- Added a NoiseRadar-specific web integration experience document covering the Vozhyk web support page, privacy endpoint, optimized assets, Development page app-logo tile, sitemap entries, deploy smoke checks, verification, and reusable checklist for future apps.

Why:
- The user asked to document how the NoiseRadar web integration was done so the same approach can be reused for future iOS apps.

Verification:
- Reviewed the new document for the expected public URLs, file paths, route names, asset names, link behavior, and verification steps.
- No build or app run was needed because this change only adds documentation.

### 2026-10-17

Files changed:
- `shared_experience/ios_apps_experience/noisy_direction/app_deployment.md`
- `agent_context.md`

What changed:
- Added a NoiseRadar-specific shared App Store deployment experience document.
- Captured app identity, signing/export settings, manual App Store Connect record creation, unique listing-name fix, metadata, review notes, privacy answers, screenshot/header asset size fixes, physical-device QA, support/privacy URLs, and future deployment lessons.

Why:
- The user asked to store the current app's App Store deployment experience under the shared iOS app deployment experience folder for reuse by future apps.

Verification:
- Reviewed `agent_context.md`, the existing `shared_experience/ios_apps_experience/my_finance_ios/app_deployment.md` format, and `app_store_deploy.md`.
- No build was run because this change only adds documentation.

### 2026-10-14

Files changed:
- `README.md`
- `app_store_deploy.md`
- `agent_context.md`

What changed:
- Added the public YouTube Shorts demo link: `https://youtube.com/shorts/kxWObeB3aho?feature=share`.
- Documented the link in the README demo section and in the App Store deployment guide's demo attachment section.

Why:
- The user provided a YouTube demo link and asked to update app documentation.

Verification:
- Searched the documentation to confirm the YouTube URL is present in the expected files.

### 2026-10-14

Files changed:
- `screenshots/nr_01.jpg`
- `screenshots/nr_02.jpg`
- `screenshots/nr_03.jpg`
- `screenshots/nr_04.jpg`
- `screenshots/nr_05.jpg`
- `agent_context.md`

What changed:
- Resized the existing App Store screenshot files in place from `590 x 1280` to `1179 x 2556`.

Why:
- App Store Connect rejected the screenshot files because their dimensions were invalid. The user requested adjusting the current files without creating new ones.

Verification:
- `sips -g pixelWidth -g pixelHeight` reports `1179 x 2556` for `nr_01.jpg` through `nr_05.jpg`.
- `file` reports all five files as JPEG images at `1179 x 2556`.

### 2026-10-14

Files changed:
- `screenshots/header_custom.png`
- `agent_context.md`

What changed:
- Resized the existing `screenshots/header_custom.png` file in place from `1716 x 872` to `3840 x 1646`.

Why:
- App Store Connect rejected the custom product page header image because its dimensions were invalid. The user requested converting the current file without creating a new file.

Verification:
- `sips -g pixelWidth -g pixelHeight screenshots/header_custom.png` reports `3840 x 1646`.
- `file screenshots/header_custom.png` reports PNG image data at `3840 x 1646`.

### 2026-10-14

Files changed:
- `app_store_deploy.md`
- `agent_context.md`

What changed:
- Documented the App Store Connect `App Record Creation Error` caused by the product-page app name `NoiseRadar` already being in use.
- Updated the App Store submission guide to use `NoiseRadar: Sound Finder` as the unique App Store listing name while keeping the installed iPhone app display name as `NoiseRadar`.
- Added manual App Store Connect record creation steps so Xcode Organizer uploads attach to an existing record instead of trying to auto-create a record named `NoiseRadar`.
- Updated App Store Connect navigation examples to use `NoiseRadar: Sound Finder`.

Why:
- The user hit an App Store Connect deployment error saying the entered app name is already being used.

Verification:
- Swift typecheck against the iPhoneOS SDK was run after this documentation update to confirm no app code was broken.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar/AudioDirectionManager.swift`
- `agent_context.md`

What changed:
- Added visible app version/build text to the Help screen.
- Added an About section in Settings showing the current app version/build.
- Made the existing `Bundle` version/build helper available to SwiftUI views.

Why:
- The user reported that the iPhone app did not show the current app version number anywhere.

Verification:
- Swift typecheck against the iPhoneOS SDK was run after this change.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar/AudioDirectionManager.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `README.md`
- `suggestions.md`
- `road_map.md`
- `app_store_deploy.md`
- `agent_context.md`
- `/Users/olegbourdo/Development/vozhyk_web/deployed_applications/NOISERADAR_PRIVACY_POLICY.html`
- `/Users/olegbourdo/Development/vozhyk_web/context_agent.md`

What changed:
- Implemented Phase 2 for the iPhone-only app, excluding Apple Watch companion work by product decision.
- Added configurable foreground threshold alerts with enable switch, sound category, dB threshold, confidence threshold, and alert style.
- Added alert styles for none, haptic, screen flash, and system sound.
- Added a Settings sheet for threshold alert configuration and manual dB calibration offset.
- Added manual calibration offset persistence and reset.
- Added local session report generation with text summary and CSV event log.
- Added Share sheet support that writes timestamped `.txt` and `.csv` report files to the temporary directory and shares them through iOS.
- Updated App Store guidance, README, suggestions, and roadmap to describe Phase 2 behavior and keep the scope iPhone-only.
- Updated the hosted NoiseRadar privacy policy to describe local alert settings, calibration settings, and temporary local text/CSV share reports.

Why:
- The user requested Phase 2 implementation while keeping the app limited to iPhone only, without Watch, iPad, Mac, Vision Pro, or other companion surfaces.

Verification:
- Swift typecheck against the iPhoneOS SDK succeeded for `NoiseRadarApp.swift`, `SoundRadarView.swift`, and `AudioDirectionManager.swift`.
- `xcodebuild -list -project NoiseRadar/NoiseRadar.xcodeproj` succeeded and reported target/scheme `NoiseRadar`.
- Confirmed project settings remain iPhone-only: `TARGETED_DEVICE_FAMILY = 1`, supported platforms are `iphoneos iphonesimulator`, and Mac/Vision designed-for support remains disabled.
- Flask test-client verification was run for the hosted NoiseRadar privacy policy after the policy text update.
- Physical iPhone QA is still required for threshold alert behavior, sound playback while listening, calibration feel, and the Share sheet output.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `README.md`
- `how_to_deploy.md`
- `suggestions.md`
- `app_store_deploy.md`
- `agent_context.md`
- `/Users/olegbourdo/Development/vozhyk_web/app.py`
- `/Users/olegbourdo/Development/vozhyk_web/deployed_applications/NOISERADAR_PRIVACY_POLICY.html`
- `/Users/olegbourdo/Development/vozhyk_web/context_agent.md`

What changed:
- Replaced the Help screen footer links with the main Vozhyk website URL: `https://www.vozhyk.com/`.
- Removed previous external personal/agency references from project-facing NoiseRadar docs.
- Added the NoiseRadar privacy policy URL to the App Store deployment guide: `https://www.vozhyk.com/noiseradar/privacy-policy`.
- Added a NoiseRadar privacy policy page and Flask route in the Vozhyk web project so the policy is reachable through the main website.

Why:
- The user requested the app Help main link be `https://www.vozhyk.com/` and asked for a reachable privacy policy page in the Vozhyk web project for App Store submission.

Verification:
- Searched the NoiseRadar repository outside `.git`, `.idea`, and `build`; no previous external personal/agency references remain.
- Flask route and Swift typecheck verification were run after the web/app changes; see final response for results.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`
- `NoiseRadar/NoiseRadar/Info.plist`
- `build/AppStoreExport/ExportOptions.plist`
- `app_store_deploy.md`
- `how_to_deploy.md`
- `agent_context.md`

What changed:
- Prepared NoiseRadar signing and App Store build settings using the deployed TargetLock/Vozhyk pattern.
- Set automatic signing to Apple Developer team `8J9SSA37RS`.
- Set the app bundle identifier to `lt.bourdo.NoiseRadar`.
- Kept version `1.0` and build `1` for the first App Store upload.
- Added explicit Info.plist bundle/version metadata backed by `PRODUCT_BUNDLE_IDENTIFIER`, `MARKETING_VERSION`, and `CURRENT_PROJECT_VERSION`.
- Added `LSRequiresIPhoneOS`, single-scene metadata, portrait orientation, and motion permission text.
- Added `build/AppStoreExport/ExportOptions.plist` for App Store Connect export with automatic signing, Swift symbol stripping, dSYM upload, and team `8J9SSA37RS`.
- Updated deployment documentation to remove placeholder bundle/team instructions.

Why:
- The user requested the app be signed and prepared in Xcode using the previous successful deployment setup from TargetLock and Vozhyk.

Verification:
- Compared signing/build settings and Info.plist structure from `/Users/olegbourdo/Development/get_distance/TargetLock` and `/Users/olegbourdo/Development/vozhyk/iphone_detector`.
- `plutil -lint` passed for `NoiseRadar/NoiseRadar/Info.plist` and `build/AppStoreExport/ExportOptions.plist`.
- `xcodebuild -list -project NoiseRadar/NoiseRadar.xcodeproj` succeeded and reported target/scheme `NoiseRadar`.
- Swift typecheck against the iPhoneOS SDK succeeded.
- `xcodebuild archive` first failed without provisioning updates because no local profile existed for `lt.bourdo.NoiseRadar`; rerunning with `-allowProvisioningUpdates` succeeded and created `build/archives/NoiseRadar.xcarchive`.
- `xcodebuild -exportArchive` with `build/AppStoreExport/ExportOptions.plist` succeeded and created `build/AppStoreExport/NoiseRadar.ipa`.
- Export summary showed `Cloud Managed Apple Distribution`, profile `iOS Team Store Provisioning Profile: lt.bourdo.NoiseRadar`, team `8J9SSA37RS`, version `1.0`, build `1`, architecture `arm64`, and `get-task-allow = false`.
- Export printed a non-blocking App Store Connect provider warning: `No provider associated with App Store Connect user`. The IPA was still exported successfully; App Store upload may require selecting/signing into the correct App Store Connect provider in Xcode.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`
- `NoiseRadar/NoiseRadar.xcodeproj/xcuserdata/olegbourdo.xcuserdatad/xcschemes/xcschememanagement.plist`
- `NoiseRadar/NoiseRadar/NoiseRadarApp.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar/AudioDirectionManager.swift`
- `NoiseRadar/NoiseRadar/Info.plist`
- `README.md`
- `how_to_deploy.md`
- `app_store_deploy.md`
- `image_prompts.md`
- `suggestions.md`
- `road_map.md`
- `agent_context.md`

What changed:
- Renamed the app and Xcode project identity from the previous name to `NoiseRadar`.
- Renamed the project folder to `NoiseRadar/`, the Xcode project to `NoiseRadar.xcodeproj`, the app source folder to `NoiseRadar/NoiseRadar/`, and the Swift app entry file to `NoiseRadarApp.swift`.
- Updated the Xcode target, product reference, app product name, source path, Info.plist path, and bundle identifier placeholder to `lt.bourdo.NoiseRadar`.
- Updated the app display name, in-app title text, permission usage descriptions, SoundAnalysis queue label, App Store/deployment documentation, image prompts, roadmap, and README references to use `NoiseRadar`.
- Preserved the iPhone-only build settings: `TARGETED_DEVICE_FAMILY = 1`, `SUPPORTED_PLATFORMS = "iphoneos iphonesimulator"`, and disabled Mac/Vision designed-for support.

Why:
- The user selected `NoiseRadar` as the app name and requested that the project and all references be adjusted to the new name.

Verification:
- Searched the repository outside `.git` and `.idea`; no exact previous app/project identifiers remain.
- `xcodebuild -list -project NoiseRadar/NoiseRadar.xcodeproj` succeeded and reported the target and scheme as `NoiseRadar`.
- Swift typecheck against the iPhoneOS SDK succeeded for `NoiseRadarApp.swift`, `SoundRadarView.swift`, and `AudioDirectionManager.swift`.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar/AudioDirectionManager.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar.xcodeproj/project.pbxproj`
- `README.md`
- `suggestions.md`
- `road_map.md`
- `app_store_deploy.md`
- `agent_context.md`

What changed:
- Implemented Phase 1 of the roadmap for the iPhone app.
- Added direction-by-sound-type results using signal strength weighted by SoundAnalysis classification confidence.
- Added foreground Listen mode alongside Scan 360 mode.
- Added local in-memory event history for recent scan/listen detections.
- Added first-run onboarding and a readiness checklist for microphone, compass, rotation speed, and noise floor.
- Updated the UI to use a scrollable iPhone layout with mode selector, category direction cards, history sheet, and dismissible help sheet.
- Tightened build settings to iPhone/iPhone Simulator only and disabled Mac/Vision designed-for availability.
- Updated README, suggestions, roadmap, and App Store deployment text for Phase 1 behavior.

Why:
- The user requested Phase 1 implementation while keeping the app only for iPhone devices, without Apple Watch, iPad, Mac, Vision Pro, or companion surfaces.

Verification:
- Ran Swift typecheck against the iPhoneOS SDK successfully with local module cache:
  `xcrun --sdk iphoneos swiftc -typecheck -target arm64-apple-ios15.0 ...`
- Physical iPhone QA is still required for microphone, compass, Scan 360, Listen mode, and live SoundAnalysis behavior.

### 2026-10-14

Files changed:
- `road_map.md`
- `agent_context.md`

What changed:
- Added a new product roadmap document based on the current app capabilities, existing suggestions, App Store positioning, and current market/customer signals.
- Prioritized features such as direction by sound type, continuous listen mode, event history, onboarding, threshold alerts, export, calibration, Apple Watch haptics, Shortcuts, outdoor mode, accessibility improvements, and reliability work.
- Added `road_map.md` to the project layout section of this context file.

Why:
- The project needed a customer-focused feature roadmap grounded in current trends and customer-requested utility/accessibility/sound-meter features.

Verification:
- Reviewed the current app README, existing suggestions, agent context, and deployment guidance.
- Researched current trends and customer signals around on-device/offline AI, accessibility sound recognition, sound meter apps, outdoor safety apps, app privacy, calibration, history, export, and haptic/Watch workflows.
- No build was run because this change only adds documentation.

### 2026-10-14

Files changed:
- `launch_screen.png`
- `noisy_load.jpg`
- `NoiseRadar/NoiseRadar/Assets.xcassets/LaunchImage.imageset/launch_screen.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/LaunchImage.imageset/noisy_load.jpg`
- `NoiseRadar/NoiseRadar/Assets.xcassets/LaunchImage.imageset/Contents.json`
- `NoiseRadar/NoiseRadar/LaunchScreen.storyboard`
- `agent_context.md`

What changed:
- Replaced the previous launch-screen source `noisy_load.jpg` with the new root source `launch_screen.png`.
- Generated an app-bundled launch asset at `1290 x 2796` RGB PNG for modern iPhone portrait sizing.
- Updated `LaunchImage.imageset/Contents.json` to reference `launch_screen.png`.
- Updated the launch storyboard image resource metadata to `1290 x 2796`.
- Removed the old root `noisy_load.jpg` and old asset-catalog `noisy_load.jpg`.

Why:
- The new `launch_screen.png` should be the app launch screen, and the bundled launch asset needs to be correctly sized and adjusted for iPhone portrait launch display.

Verification:
- Verified the asset-catalog `launch_screen.png` is `1290 x 2796` RGB PNG.
- Verified `LaunchImage.imageset/Contents.json` parses as valid JSON.
- Searched the repository outside `.git` and `.idea`; no `noisy_load.jpg` references remain.
- Visually inspected the generated launch image crop for iPhone portrait use.
- No build was run because this change only updates launch image assets and storyboard metadata.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-1024.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-20@2x.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-20@3x.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-29@2x.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-29@3x.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-40@2x.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-40@3x.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-60@2x.png`
- `NoiseRadar/NoiseRadar/Assets.xcassets/AppIcon.appiconset/Icon-60@3x.png`
- `README.md`
- `agent_context.md`

What changed:
- Replaced all existing AppIcon image renditions with square RGB PNGs generated from the new root asset `noise_icon.png`.
- Updated the README app icon image reference from `noisy_icon.jpg` to `noise_icon.png`.
- Confirmed no documentation references to `noisy_icon.jpg` remain.

Why:
- `noise_icon.png` is now the main app icon source and should replace the previous `noisy_icon.jpg` in documentation and the app icon asset catalog.

Verification:
- Verified generated AppIcon files have the expected square dimensions and RGB color format.
- Searched the repository for `noisy_icon.jpg` references outside `.git` and `.idea`; none remain.
- No build was run because this change only updates image assets and documentation.

### 2026-10-14

Files changed:
- `image_prompts.md`
- `agent_context.md`

What changed:
- Added separate image-generation prompts for the NoiseRadar app icon, launch/loading screen, and App Store custom product page header.
- Included target sizes, visual direction, negative prompts, and review notes to avoid misleading emergency/security/military positioning.
- Added `image_prompts.md` to the project layout section of this context file.

Why:
- The app needs consistent visual asset prompts for App Store-ready branding and product-page preparation.

Verification:
- Reviewed the prompts for consistency with the current app behavior, App Store positioning, and existing deployment guidance.
- No build was run because this change only adds documentation.

### 2026-10-14

Files changed:
- `NoiseRadar/NoiseRadar/AudioDirectionManager.swift`
- `NoiseRadar/NoiseRadar/SoundRadarView.swift`
- `NoiseRadar/NoiseRadar/Info.plist`
- `README.md`
- `app_store_deploy.md`
- `agent_context.md`

What changed:
- Added offline on-device sound classification using Apple's SoundAnalysis framework and built-in classifier.
- Replaced recorder-only metering with an `AVAudioEngine` microphone tap so the same audio stream drives decibel calculation and sound classification.
- Added broad category mapping for sound labels such as human voice, vehicles, mechanical sounds, animals, alarms, music, nature, household, and impact sounds.
- Added UI for the current sound type and top sound classifications.
- Updated microphone and location permission text to describe local audio processing and sound classification.
- Updated README and App Store deployment guidance for offline sound labels and local privacy behavior.
- Updated this context file with the new architecture and mandatory change record.

Why:
- The app needed offline ML-style sound descriptions without internet access, while preserving the existing sound direction scan.

Verification:
- Confirmed Apple SoundAnalysis supports built-in and custom Core ML sound classification through `SNClassifySoundRequest`, and live microphone stream analysis through `SNAudioStreamAnalyzer`.
- Ran Swift typecheck against the iPhoneOS SDK successfully with local module cache:
  `xcrun --sdk iphoneos swiftc -typecheck -target arm64-apple-ios15.0 ...`
- Attempted full `xcodebuild` for simulator and generic iOS device with local DerivedData; both were blocked by sandbox/CoreSimulator asset tooling failures (`No available simulator runtimes for platform iphonesimulator`), not by Swift type errors.
- Physical-device runtime verification is still required for microphone, compass, and live classification behavior.

### 2026-10-14

Files changed:
- `app_store_deploy.md`
- `agent_context.md`

What changed:
- Added a dedicated App Store deployment guide for NoiseRadar.
- Documented recommended App Store Connect fields, review notes, privacy answers, screenshots, age rating, export compliance, build/upload steps, and rejection-prevention checklist.
- Captured deployment lessons from `get_distance`, `iphone_dust_cleaner`, and `vozhyk`.
- Added `app_store_deploy.md` to the project layout section of this context file.

Why:
- The app needs a complete, step-by-step App Store submission reference that accounts for previous review issues and includes accurate product-page and reviewer-facing text.

Verification:
- Reviewed prior deployment and review documents in `/Users/olegbourdo/Development/get_distance`, `/Users/olegbourdo/Development/iphone_dust_cleaner`, and `/Users/olegbourdo/Development/vozhyk`.
- Reviewed current NoiseRadar project settings, `Info.plist`, asset catalog metadata, and existing documentation.
- Cross-checked the submission flow against current Apple App Store Connect and App Review documentation.
- No build was run because this change only adds documentation.

### 2026-10-14

Files changed:
- `agent_context.md`

What changed:
- Added this agent context file at the repository root.
- Documented the app architecture, scan flow, key files, permissions, known gaps, and verification notes.
- Added the mandatory rule that every future AI-agent change must be tracked in this file.

Why:
- The repository needed a durable context document so future AI agents can understand how the app works and keep a clear record of changes.

Verification:
- Reviewed `README.md`, `how_to_deploy.md`, `suggestions.md`, `Info.plist`, `NoiseRadarApp.swift`, `SoundRadarView.swift`, `AudioDirectionManager.swift`, and relevant Xcode project settings.
- No build was run because this task only added documentation.
