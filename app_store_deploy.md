# Noisy Detector App Store Deployment Guide

Last reviewed: 2026-10-14

Use this guide to prepare, upload, and submit Noisy Detector to App Store Review.
It includes lessons from the previous `get_distance`, `iphone_dust_cleaner`,
and `vozhyk` submissions: give App Review clear sensor-testing instructions,
avoid unsupported claims, keep iPhone-only metadata consistent, include all
required App Store Connect fields, and test the exact uploaded build on a real
device.

## Current App Facts

| Field | Current value |
| --- | --- |
| App display name | Noisy Detector |
| Xcode project | `NoisyDetector/NoisyDetector.xcodeproj` |
| App target/source folder | `NoisyDetector/NoisyDetector` |
| Platform | iOS |
| Device family | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) |
| Minimum iOS | iOS 15.0 |
| Version | 1.0 |
| Build | 1 |
| Current bundle ID | `com.example.noisydetector` |
| Current Apple team in project | `6X42CRDLS6` |
| Microphone permission | `NSMicrophoneUsageDescription` |
| Location permission | `NSLocationWhenInUseUsageDescription` |
| Account required | No |
| In-app purchases | No |
| Developer backend | No |
| Ads / analytics / tracking SDKs | None seen in current code |
| Main user value | Estimate the direction of the loudest sound by combining microphone sound levels with compass heading while the user rotates 360 degrees, and classify the sound type locally on device |

Important: `com.example.noisydetector` is a placeholder bundle ID. Do not submit
with it. Register and use a real unique bundle identifier before upload.

Recommended bundle ID:

```text
lt.bourdo.noisydetector
```

If that identifier is unavailable, use another unique reverse-DNS identifier
owned by the developer account, for example:

```text
lt.bourdo.noisy-detector
```

## Review Risk Guardrails

Use conservative wording everywhere.

Safe positioning:

```text
Noisy Detector is a local sound-direction utility that estimates where the loudest sound is coming from during a 360 degree scan.
```

Avoid unsupported or risky claims:

```text
Professional acoustic measurement
Certified sound locator
Emergency detection
Security system
Surveillance
Guaranteed direction
Police / military / tactical use
Medical or safety-critical use
```

State clearly that results are estimates and depend on device sensors, rotation
speed, microphone exposure, background noise, and compass accuracy.

## Lessons From Previous App Store Submissions

### From TargetLock / `get_distance`

The review team may ask for more information under Guideline 2.1 when an app
uses sensors or a non-obvious workflow. Prevent this by filling Review Notes
with a complete step-by-step test flow, no-login statement, external services
statement, privacy statement, regional behavior statement, and a clear disclaimer
that the app is not a certified professional tool.

### From Dust Cleaner / `iphone_dust_cleaner`

Even an iPhone-only app can be reviewed in an iPad compatibility environment.
Before upload, test that the interface remains reachable on short-height layouts
and with larger text. If screenshots or metadata say iPhone-only, do not add an
iPad platform and do not upload iPad screenshots.

Also avoid exaggerated utility claims. Dust Cleaner avoided claiming that it
repairs hardware; Noisy Detector should avoid claiming certified acoustic
accuracy or guaranteed source location.

### From Vozhyk

Public metadata must avoid sensitive or regulated positioning. For Noisy
Detector, keep the app framed as a general utility, not as surveillance,
security, emergency, police, military, or safety equipment.

Review Notes should say what hardware is required, which permissions are used,
what is processed locally, and that no backend, account, payment, analytics,
advertising, or tracking services are used.

## Pre-Submission Code And Project Checklist

Complete these before archiving:

- [ ] Change bundle ID from `com.example.noisydetector` to the final registered bundle ID.
- [ ] Confirm `CFBundleDisplayName` is `Noisy Detector`.
- [ ] Confirm Version is `1.0`.
- [ ] Increment Build to a new integer before each upload.
- [ ] Confirm `TARGETED_DEVICE_FAMILY = 1` if this is intended to be iPhone-only.
- [ ] Confirm App Icon exists, including 1024 x 1024 marketing icon.
- [ ] Confirm launch screen/image displays correctly.
- [ ] Confirm microphone permission text is clear.
- [ ] Confirm location permission text explains compass heading.
- [ ] Consider adding `ITSAppUsesNonExemptEncryption = NO` to `Info.plist` if the app does not use encryption beyond Apple system functionality, so App Store Connect does not repeatedly ask export questions.
- [ ] Do not add analytics, ads, crash SDKs, networking, accounts, or cloud upload unless App Privacy and Privacy Policy are updated.

Recommended improved permission text before submission:

```text
NSMicrophoneUsageDescription: Noisy Detector uses the microphone to measure sound levels and classify sound types during a scan. Audio is processed on device and is not recorded or uploaded.
NSLocationWhenInUseUsageDescription: Noisy Detector uses compass heading from Location Services to estimate the direction of the loudest sound during a scan.
```

## Required Physical-Device QA

Run this on the exact build that will be uploaded.

1. Install fresh on a physical iPhone running iOS 15.0 or later.
2. Launch the app.
3. Allow microphone access.
4. Allow location access when prompted so compass heading works.
5. Confirm the main screen is visible:
   - title
   - radar circle
   - Start Scan button
   - Help button
   - sound level text
   - scan quality text
6. Tap `Start Scan`.
7. Keep the phone still during calibration.
8. Slowly rotate 360 degrees.
9. Confirm progress increases.
10. Make a clear sound from one direction, such as clapping or speaking.
11. Tap `Stop & Analyze`.
12. Confirm the app displays `Loudest sound at: ...°` and shows the green result arrow.
13. Test a too-fast rotation and confirm the app warns `Too fast`.
14. Test in a quiet room and confirm `Too quiet` appears if there is no usable sound source.
15. Open Help and confirm the sheet content is readable and dismissible.
16. Deny microphone permission on a fresh install or through Settings and confirm the app shows a useful message.
17. Deny location permission and confirm the app does not crash.
18. Test larger text:

```text
Settings -> Accessibility -> Display & Text Size -> Larger Text
```

19. If possible, test iPhone compatibility mode on iPad or an iPad simulator even though the app is iPhone-only. Confirm the whole UI remains reachable.

If the UI becomes crowded or unreachable during step 18 or 19, fix layout before
submission. The previous Dust Cleaner review problem was caused by unreachable
UI in an iPad review environment.

## Apple Developer Setup

1. Open Apple Developer account settings.
2. Register a new explicit App ID:

```text
Type: App IDs -> App
Description: Noisy Detector
Bundle ID type: Explicit
Bundle ID: lt.bourdo.noisydetector
Capabilities: Defaults only
```

3. In Xcode, open:

```text
NoisyDetector/NoisyDetector.xcodeproj
```

4. Select the `NoisyDetector` target.
5. Open `Signing & Capabilities`.
6. Set:

```text
Automatically manage signing: Enabled
Team: TODO correct Apple Developer team
Bundle Identifier: lt.bourdo.noisydetector
```

Use the same team that owns the App Store Connect app record.

## Archive And Upload From Xcode

1. Open the project in Xcode.
2. Select the `NoisyDetector` scheme.
3. Confirm the target settings:

```text
Display Name: Noisy Detector
Version: 1.0
Build: 1 or next unused build number
Bundle Identifier: lt.bourdo.noisydetector
Minimum iOS: 15.0
Device family: iPhone
Signing team: TODO correct team
```

4. Select:

```text
Any iOS Device (arm64)
```

5. Run a local build.
6. Select:

```text
Product -> Archive
```

7. When Organizer opens, select the new archive.
8. Click:

```text
Distribute App -> App Store Connect -> Upload
```

9. Use automatic signing unless you intentionally manage profiles manually.
10. Wait for upload to complete.
11. Wait for App Store Connect processing email or for the build to appear in
    the app version page.

If upload warnings appear, read them carefully. Non-blocking warnings may still
allow build processing, but any signing, bundle ID, missing icon, or privacy
manifest problem should be fixed before submitting.

## Create The App Store Connect App Record

In App Store Connect:

```text
Apps -> + -> New App
```

Fill:

```text
Platform: iOS
Name: Noisy Detector
Primary Language: English (U.S.)
Bundle ID: lt.bourdo.noisydetector
SKU: noisy-detector-ios-001
User Access: Full Access
```

If the bundle ID does not appear, register it in Apple Developer first, then
refresh App Store Connect.

## App Store Product Page Fields

### Name

Maximum 30 characters.

```text
Noisy Detector
```

### Subtitle

Maximum 30 characters.

Recommended:

```text
Find Loud Sound Direction
```

Alternative:

```text
Sound Direction Scanner
```

### Promotional Text

Can be edited without submitting a new app version.

```text
Estimate where the loudest sound is coming from and classify the sound type with an offline 360 degree scan using your iPhone microphone and compass.
```

### Description

Paste this into App Store Connect:

```text
Noisy Detector is a simple iPhone utility that helps estimate the direction of the loudest sound around you and identify the general type of sound.

Tap Start Scan, hold your iPhone upright, stay still during the short calibration step, then slowly turn 360 degrees. Noisy Detector measures sound levels locally on your device, combines them with compass heading to estimate which direction had the strongest sound signal, and uses on-device sound classification to label likely sound types.

Key features:
- 360 degree sound-direction scan
- Offline sound type classification
- Broad categories such as human voice, vehicles, mechanical sounds, animals, alarms, music, nature, household, and impact sounds
- Live radar-style direction display
- Loudest heading result after each scan
- Top 3 loudest headings
- Top sound predictions with confidence
- Raw and smoothed sound level display
- Scan progress indicator
- Scan quality messages for too-fast, too-quiet, or noisy environments
- Local calibration for background noise
- Haptic feedback for scan actions
- Built-in help screen
- No account, subscription, advertising, analytics, or developer backend

Noisy Detector is designed for casual sound-direction estimates, troubleshooting, demonstrations, and general utility use. Results and sound labels are estimates and can be affected by background noise, echoes, overlapping sounds, microphone position, compass accuracy, phone movement, and how slowly the user rotates.

Privacy: sound levels, sound classification, and compass heading are processed on device. The app does not create accounts, record audio files, upload microphone audio, or send scan data to a developer server.
```

### Keywords

Maximum 100 characters total, comma-separated. Do not add spaces unless needed.

```text
sound,noise,loud,direction,detector,compass,microphone,classification,audio,utility
```

Character count: 83.

### Support URL

Required.

TODO:

```text
https://TODO.example.com/noisy-detector/support
```

Minimum support page content:

- App name: Noisy Detector.
- Contact email or support form.
- Short usage steps.
- Troubleshooting for microphone permission, location/compass permission, noisy rooms, and rotating too fast.
- Privacy policy link.
- Statement that the app requires a physical iPhone with microphone and compass.

Temporary option if the repository is public:

```text
https://github.com/TODO/noisy_direction/issues
```

### Marketing URL

Optional.

TODO:

```text
https://TODO.example.com/noisy-detector
```

This can be a simple product page with screenshots, description, support link,
and privacy link.

### Privacy Policy URL

Required for iOS apps.

TODO:

```text
https://TODO.example.com/noisy-detector/privacy
```

The privacy policy must match the current app behavior. Recommended content:

- Noisy Detector uses microphone permission to measure sound levels and classify general sound types during scans.
- Audio is processed on device with Apple system audio and SoundAnalysis frameworks.
- The app does not record audio files.
- The app does not upload microphone audio.
- The app uses location permission only to access compass heading through iOS.
- The app does not collect precise location for developer use.
- The app does not create accounts.
- The app does not use advertising or tracking SDKs.
- The app does not use analytics SDKs.
- The app does not send scan results to a developer backend.
- Include contact email for privacy questions.

Do not say `no data collected` in the privacy policy if analytics, crash
reporting, ads, remote logging, cloud sync, accounts, or any server upload is
added later.

### Copyright

Use the legal owner name shown by the App Store seller account.

Recommended if publishing as an individual:

```text
2026 Oleg Bourdo
```

If publishing under a company, use the company legal name instead.

### Categories

Primary category:

```text
Utilities
```

Secondary category:

```text
Productivity
```

Alternative secondary category:

```text
Education
```

Use `Education` only if positioning it mainly as a demonstration of audio and
compass sensing.

### License Agreement

Recommended:

```text
Use Apple's Standard License Agreement.
```

Only use a custom EULA if a hosted legal page and reviewed legal text are ready.

## Screenshots And App Preview

Screenshots are required. Upload at least one screenshot for the required iPhone
display size in App Store Connect, and upload up to 10 if available.

Recommended first submission screenshot set:

1. Main screen before scanning.
2. Calibration/scanning state.
3. Completed scan with green result arrow and loudest heading.
4. Scan quality warning, if visually useful.
5. Help screen.

Rules:

- Use screenshots from the actual submitted build.
- Use iPhone screenshots only if the app remains iPhone-only.
- Do not upload iPad screenshots unless the target is changed to support iPad.
- Do not show exaggerated claims in screenshot text.
- Do not include private addresses, private conversations, or unrelated third-party copyrighted material.
- App previews are optional. Skip the preview video for version 1.0 unless there is a polished physical-device demo.

## App Privacy Answers

In App Store Connect:

```text
Apps -> Noisy Detector -> App Privacy
```

Recommended answer for the current codebase, if no analytics, ads, crash
reporting SDK, account system, backend upload, or third-party SDK data sharing
is added:

```text
Data Collection: No, we do not collect data from this app.
Tracking: No
```

Important: this means the developer does not collect data. The app still
processes microphone levels, sound classification, and compass heading locally
on device. Explain that clearly in the privacy policy and Review Notes.

If any of these are added, update App Privacy before submission:

- Remote logging.
- Analytics.
- Crash reporting SDK.
- Ads.
- Account or login.
- Cloud sync.
- Server-side audio processing.
- Uploading audio, headings, scan history, diagnostics, identifiers, or location.

## Age Rating

In App Store Connect:

```text
Apps -> Noisy Detector -> App Information -> Age Ratings -> Set Up Age Ratings
```

Suggested answers for the current app:

- User-generated content: No.
- Web access/browser: No.
- Messaging/chat/social networking: No.
- Purchases/gambling/contests/loot boxes: No.
- Cartoon/fantasy violence: None.
- Realistic violence: None.
- Sexual content/nudity: None.
- Profanity/crude humor: None.
- Alcohol/tobacco/drug references: None.
- Medical/treatment information: None.
- Horror/fear themes: None.
- Unrestricted web access: No.
- Location sharing: No.
- Made for Kids: No.

Do not mark the app as Made for Kids. The app uses microphone and location
permission for sensor access and is not specifically designed as a kids app.

## Content Rights

Recommended answer:

```text
The app does not contain, show, or access third-party content without authorization.
```

Before submission, verify rights for:

- App icon.
- Launch image.
- Screenshots.
- Product page images.
- Any marketing page images.
- Any code/package/license obligations.

## Export Compliance

Likely answer for the current app:

```text
The app does not use encryption beyond standard Apple operating system functionality.
```

If App Store Connect asks whether the app uses encryption, answer based on the
actual build. Re-check if custom encryption, networking, authentication, VPN,
secure messaging, encrypted cloud storage, or third-party SDK networking is
added.

If no encryption is used, consider adding this to `Info.plist`:

```text
ITSAppUsesNonExemptEncryption = NO
```

## Advertising Identifier

Recommended for the current app:

```text
No, this app does not use the Advertising Identifier (IDFA).
```

Only answer `Yes` if an ads or attribution SDK that uses IDFA is added.

## Digital Services Act / Trader Status

This is a legal/business answer for EU distribution.

TODO:

```text
Trader status: Trader / Non-trader
Contact details: TODO
```

Choose based on whether the app is distributed in connection with a trade,
business, craft, or profession. If using paid apps or commercial distribution
from Lithuania/EU, review this carefully in App Store Connect.

## Pricing And Availability

Recommended first submission:

```text
Price: Free
Availability: TODO All countries and regions / Selected countries
Release method: Manual release after approval
```

Manual release gives time to inspect the approved version before it goes live.

## App Review Information

In App Store Connect:

```text
Apps -> Noisy Detector -> Distribution -> iOS App Version 1.0 -> App Review
```

### Contact Information

Required.

TODO:

```text
First Name: TODO
Last Name: TODO
Phone Number: TODO
Email: TODO
```

Use contact details Apple can actually reach during review.

### Sign-In Information

Recommended:

```text
Sign-in required: No
```

Noisy Detector currently has no account system.

### Review Notes

Paste this into App Store Connect:

```text
Noisy Detector is a local sound-direction utility for iPhone. It estimates the direction of the loudest sound by combining microphone sound level readings with the iPhone compass heading while the user slowly rotates 360 degrees. It also uses Apple's on-device SoundAnalysis classifier to show broad sound type labels such as human voice, vehicles, mechanical sounds, animals, alarms, music, nature, household, and impact sounds.

No account, login, subscription, in-app purchase, sample file, server setup, or test credentials are required.

Main test flow:
1. Install and launch Noisy Detector on a physical iPhone running iOS 15.0 or later.
2. Allow microphone access. The microphone is used only to measure sound levels and classify sound types during the scan.
3. Allow location access. Location Services are used to provide compass heading for direction estimation.
4. Tap Start Scan.
5. Keep the phone still during the short calibration step.
6. Hold the phone upright and slowly rotate 360 degrees.
7. Make a clear sound from one direction, such as clapping or speaking, while scanning.
8. Tap Stop & Analyze.
9. The app displays the estimated loudest heading in degrees, shows a green marker on the radar, and shows the current best-effort sound type label.
10. The Help button opens short usage instructions.

Required hardware:
Review should be performed on a physical iPhone with microphone and compass support. The iOS Simulator cannot fully test the microphone, compass, and motion-sensor workflow.

External services:
The app uses Apple system frameworks only: SwiftUI, AVFoundation, SoundAnalysis, Core Location, Core Motion, and UIKit haptics. It does not use backend servers, authentication services, payment processors, analytics SDKs, advertising SDKs, tracking SDKs, or cloud AI services.

Regional behavior:
The app functions consistently in all selected countries and regions, subject to iOS permissions and device sensor availability. There are no region-specific accounts, payments, or content differences.

Privacy:
Sound levels, sound classification, and compass heading are processed on device. The app does not create accounts, record audio files, upload microphone audio, upload location, or send scan data to developer servers.

Scope:
Noisy Detector provides casual estimates only. It is not a certified acoustic instrument, emergency system, security system, surveillance tool, medical tool, or professional measurement device. Direction results and sound labels may be affected by background noise, echoes, overlapping sounds, microphone position, compass accuracy, phone movement, and rotation speed.
```

### Demo Attachment

Optional, but recommended if the first submission receives a Guideline 2.1
request for more information.

Attach a 30-90 second physical-device video showing:

- App launch.
- Permission prompts if first launch.
- Start Scan.
- Calibration.
- Slow rotation.
- A visible sound source or clear clap from one direction.
- Stop & Analyze.
- Loudest heading result.
- Help screen.

## Build Selection

After App Store Connect processes the upload:

```text
Apps -> Noisy Detector -> Distribution -> iOS App Version 1.0 -> Build
```

Select the exact processed build that was tested on a physical iPhone.

Before selecting:

- [ ] Build number matches the archive uploaded from Xcode.
- [ ] Bundle ID matches the App Store Connect record.
- [ ] App icon is final.
- [ ] App launches after fresh install.
- [ ] Microphone and location permissions appear.
- [ ] Start/Stop scan flow works.

## Submission Steps

1. Fix the bundle ID and signing team in Xcode.
2. Confirm the app is intentionally iPhone-only.
3. Run physical-device QA.
4. Increment build number if needed.
5. Archive in Xcode.
6. Upload with Organizer.
7. Wait for App Store Connect build processing.
8. Create or open the iOS app version `1.0`.
9. Select the processed build.
10. Fill Name, Subtitle, Promotional Text, Description, Keywords, categories, and copyright.
11. Add Support URL.
12. Add Privacy Policy URL.
13. Complete App Privacy.
14. Complete Age Rating.
15. Complete Content Rights.
16. Complete Export Compliance.
17. Confirm IDFA answer is No.
18. Complete DSA/trader status if prompted.
19. Upload iPhone screenshots.
20. Set pricing and availability.
21. Add App Review contact information.
22. Add Review Notes from this guide.
23. Choose manual release after approval unless you intentionally want automatic release.
24. Click `Add for Review`.
25. Open Draft Submissions and click `Submit for Review`.

## Unable To Add For Review Checklist

If App Store Connect blocks submission, check these common missing items:

- [ ] Build not selected.
- [ ] Build still processing.
- [ ] Bundle ID mismatch.
- [ ] Contact information incomplete.
- [ ] Primary category missing.
- [ ] Privacy Policy URL missing.
- [ ] App Privacy questionnaire incomplete.
- [ ] Age Rating incomplete.
- [ ] Description missing.
- [ ] Keywords missing.
- [ ] Support URL missing.
- [ ] Screenshots missing for required iPhone size.
- [ ] Content Rights incomplete.
- [ ] Export Compliance incomplete.
- [ ] Pricing and availability incomplete.
- [ ] DSA/trader status incomplete if prompted.
- [ ] Paid Apps agreement, banking, or tax forms incomplete if submitting as a paid app.

## Final Rejection Prevention Checklist

- [ ] Metadata describes a casual utility, not a certified/professional/emergency/security tool.
- [ ] Description includes local processing and estimate limitations.
- [ ] Review Notes include the exact sensor test flow.
- [ ] Privacy Policy matches current code.
- [ ] App Privacy answers match actual data collection.
- [ ] No analytics, ads, tracking, account, or backend was added without updating privacy answers.
- [ ] Screenshots show the actual app UI from the submitted build.
- [ ] No iPad screenshots are uploaded while the target is iPhone-only.
- [ ] UI remains usable with larger text and short-height/iPad compatibility review environments.
- [ ] Exact selected build was tested on a real physical iPhone.
- [ ] Support URL and Privacy Policy URL load in a browser.
- [ ] App icon and launch image rights are confirmed.

## Official Apple References Checked

- App Store Connect workflow: `https://developer.apple.com/help/app-store-connect/get-started/app-store-connect-workflow`
- Add a new app record: `https://developer.apple.com/help/app-store-connect/create-an-app-record/add-a-new-app/`
- Upload builds: `https://developer.apple.com/help/app-store-connect/manage-builds/upload-builds/`
- Submit an app: `https://developer.apple.com/help/app-store-connect/manage-submissions-to-app-review/submit-an-app`
- Complete review information: `https://developer.apple.com/help/app-review/before-submitting-for-review/complete-review/`
- App information fields: `https://developer.apple.com/help/app-store-connect/reference/app-information/app-information/`
- Platform version information: `https://developer.apple.com/help/app-store-connect/reference/app-information/platform-version-information`
- Screenshot specifications: `https://developer.apple.com/help/app-store-connect/reference/app-information/screenshot-specifications`
- Manage app privacy: `https://developer.apple.com/help/app-store-connect/manage-app-information/manage-app-privacy/`
- Export compliance: `https://developer.apple.com/help/app-store-connect/manage-app-information/overview-of-export-compliance`
