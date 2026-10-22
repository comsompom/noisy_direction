# NoiseRadar App Store Deployment Guide

Last reviewed: 2026-10-22

Use this guide to prepare, upload, and submit NoiseRadar to App Store Review.
It includes lessons from the previous `get_distance`, `iphone_dust_cleaner`,
and `vozhyk` submissions: give App Review clear sensor-testing instructions,
avoid unsupported claims, keep iPhone-only metadata consistent, include all
required App Store Connect fields, and test the exact uploaded build on a real
device.

## Current App Facts

| Field | Current value |
| --- | --- |
| App display name | NoiseRadar |
| App Store listing name | `NoiseRadar: Sound Finder` |
| Xcode project | `NoiseRadar/NoiseRadar.xcodeproj` |
| App target/source folder | `NoiseRadar/NoiseRadar` |
| Platform | iOS |
| Device family | iPhone only (`TARGETED_DEVICE_FAMILY = 1`) |
| Minimum iOS | iOS 15.0 |
| Version | 1.1 |
| Build | 1 |
| Current bundle ID | `lt.bourdo.NoiseRadar` |
| Current Apple team in project | `8J9SSA37RS` |
| Microphone permission | `NSMicrophoneUsageDescription` |
| Location permission | `NSLocationWhenInUseUsageDescription` |
| Motion permission text | `NSMotionUsageDescription` |
| App Store export options | `build/AppStoreExport/ExportOptions.plist` |
| Account required | No |
| In-app purchases | One non-consumable Remove Ads purchase |
| Developer backend | No |
| Ads / analytics / tracking SDKs | Google Mobile Ads banner ads for free users; no separate analytics SDK |
| Main user value | Estimate the direction of the loudest sound by combining microphone sound levels with compass heading while the user rotates 360 degrees, classify the sound type locally on device, keep recent local sound events, provide configurable foreground threshold alerts, and share local session reports |

Prepared bundle ID:

```text
lt.bourdo.NoiseRadar
```

Before upload, confirm this identifier exists in the Apple Developer account
owned by team `8J9SSA37RS` and matches the App Store Connect app record.

AdMob and StoreKit identifiers for version `1.1`:

| Field | Value |
| --- | --- |
| AdMob app ID | `ca-app-pub-2367013361044576~9236993009` |
| Release banner ad unit ID | `ca-app-pub-2367013361044576/3564109908` |
| Debug banner ad unit ID | `ca-app-pub-3940256099942544/2934735716` |
| Remove Ads product ID | `lt.bourdo.noiseradar.remove_ads` |
| Remove Ads type | Non-consumable |
| Remove Ads launch price | `EUR 0.99` |

The submitted Release build must use the production banner unit. Debug builds
intentionally use Google's test banner unit so local testing can display a
banner without relying on live ad fill.

## Review Risk Guardrails

Use conservative wording everywhere.

Safe positioning:

```text
NoiseRadar is a local sound-direction utility that estimates where the loudest sound is coming from during a 360 degree scan.
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
repairs hardware; NoiseRadar should avoid claiming certified acoustic
accuracy or guaranteed source location.

### From Vozhyk

Public metadata must avoid sensitive or regulated positioning. For Noisy
Detector, keep the app framed as a general utility, not as surveillance,
security, emergency, police, military, or safety equipment.

Review Notes should say what hardware is required, which permissions are used,
what is processed locally, and that there is no backend, account, analytics,
tracking, or cloud processing. The submitted build now includes Google Mobile
Ads banner ads for free users and a StoreKit non-consumable Remove Ads purchase.

## Pre-Submission Code And Project Checklist

Complete these before archiving:

- [ ] Confirm bundle ID `lt.bourdo.NoiseRadar` is registered in Apple Developer.
- [ ] Confirm `CFBundleDisplayName` is `NoiseRadar`.
- [ ] Confirm signing team is `8J9SSA37RS`.
- [ ] Confirm Version is `1.1`.
- [ ] Increment Build to a new integer before each upload.
- [ ] Confirm `TARGETED_DEVICE_FAMILY = 1` if this is intended to be iPhone-only.
- [ ] Confirm App Icon exists, including 1024 x 1024 marketing icon.
- [ ] Confirm launch screen/image displays correctly.
- [ ] Confirm microphone permission text is clear.
- [ ] Confirm location permission text explains compass heading.
- [ ] Consider adding `ITSAppUsesNonExemptEncryption = NO` to `Info.plist` if the app does not use encryption beyond Apple system functionality, so App Store Connect does not repeatedly ask export questions.
- [ ] Confirm Google Mobile Ads and StoreKit behavior matches App Privacy, Review Notes, and the Privacy Policy.

Recommended improved permission text before submission:

```text
NSMicrophoneUsageDescription: NoiseRadar uses the microphone to measure sound levels and classify sound types during a scan. Audio is processed on device and is not recorded or uploaded.
NSLocationWhenInUseUsageDescription: NoiseRadar uses compass heading from Location Services to estimate the direction of the loudest sound during a scan.
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
Description: NoiseRadar
Bundle ID type: Explicit
Bundle ID: lt.bourdo.NoiseRadar
Capabilities: Defaults only
```

3. In Xcode, open:

```text
NoiseRadar/NoiseRadar.xcodeproj
```

4. Select the `NoiseRadar` target.
5. Open `Signing & Capabilities`.
6. Set:

```text
Automatically manage signing: Enabled
Team: 8J9SSA37RS
Bundle Identifier: lt.bourdo.NoiseRadar
```

Use the same team that owns the App Store Connect app record.

## AdMob Setup For Version 1.1

The code already contains the production AdMob IDs. Use this section to verify
the AdMob console and App Store Connect metadata before submitting.

### AdMob App

In Google AdMob:

```text
Apps -> Add app
Platform: iOS
App listed on a supported app store?: No, if the App Store listing is not live yet
App name: NoiseRadar
```

After creation, confirm the AdMob app ID matches the value in `Info.plist`:

```text
ca-app-pub-2367013361044576~9236993009
```

After Apple approves and the App Store page is live, return to AdMob and link
the AdMob app to the App Store listing.

### Banner Ad Unit

Create or verify this banner ad unit in AdMob:

```text
Ad format: Banner
Ad unit name: NoiseRadar Top Banner
Ad unit ID: ca-app-pub-2367013361044576/3564109908
Placement: Top banner on app-owned screens
Ad content rating: General audience
```

The app displays a `320x50` banner at the top of the main screen, Help, History,
Settings, and onboarding while the user is not ad-free. When the user buys or
restores Remove Ads, all banner placements are hidden and no banner view is
shown.

### AdMob Privacy And Consent

Before submitting in countries where Google requires consent messaging, review
AdMob privacy settings and create any required GDPR/EEA or other regional
messages in the AdMob console. If consent behavior is added in code later,
re-test the first launch flow and update this guide, the privacy policy, and App
Review notes.

### App-ads.txt

Recommended after the app is live:

1. In AdMob, open the app's `app-ads.txt` section.
2. Add the required Google seller line to the developer website domain used by
   the App Store listing.
3. Verify AdMob marks `app-ads.txt` as found and authorized.

Do this on the same domain used for Support/Marketing/Privacy when possible:

```text
www.vozhyk.com
```

## Archive And Upload From Xcode

1. Open the project in Xcode.
2. Select the `NoiseRadar` scheme.
3. Confirm the target settings:

```text
Display Name: NoiseRadar
Version: 1.1
Build: 1 or next unused build number if App Store Connect already processed build 1
Bundle Identifier: lt.bourdo.NoiseRadar
Minimum iOS: 15.0
Device family: iPhone
Signing team: 8J9SSA37RS
AdMob App ID in Info.plist: ca-app-pub-2367013361044576~9236993009
Release banner unit: ca-app-pub-2367013361044576/3564109908
Remove Ads product ID: lt.bourdo.noiseradar.remove_ads
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

Command-line export should use:

```text
build/AppStoreExport/ExportOptions.plist
```

Current prepared export from this repo:

```text
Archive: build/archives/NoiseRadar.xcarchive
IPA: build/AppStoreExport/NoiseRadar.ipa
Signing: Cloud Managed Apple Distribution
Provisioning profile: iOS Team Store Provisioning Profile: lt.bourdo.NoiseRadar
Team: 8J9SSA37RS
Version: 1.1
Build: 1
```

During the local command-line export, Xcode printed a non-blocking App Store
Connect provider warning: `No provider associated with App Store Connect user`.
The IPA was still exported successfully. If upload fails from Organizer or
command line, sign into the correct App Store Connect account/provider in Xcode
and retry upload.

If upload warnings appear, read them carefully. Non-blocking warnings may still
allow build processing, but any signing, bundle ID, missing icon, or privacy
manifest problem should be fixed before submitting.

## Create The App Store Connect App Record

Important: do not let Xcode auto-create the app record with the name
`NoiseRadar`. App Store Connect may reject that with:

```text
App Record Creation Error
The App Name you entered is already being used.
```

Fix: create the app record manually in App Store Connect first, using the unique
App Store listing name `NoiseRadar: Sound Finder`. The installed iPhone app can
still display as `NoiseRadar`.

In App Store Connect:

```text
Apps -> + -> New App
```

Fill:

```text
Platform: iOS
Name: NoiseRadar: Sound Finder
Primary Language: English (U.S.)
Bundle ID: lt.bourdo.NoiseRadar
SKU: noiseradar-ios-001
User Access: Full Access
```

If the bundle ID does not appear, register it in Apple Developer first, then
refresh App Store Connect. After this app record exists, upload the archive
again from Xcode Organizer. Xcode should attach the build to the existing app
record instead of trying to create a new record named `NoiseRadar`.

## App Store Product Page Fields

### Name

Maximum 30 characters.

```text
NoiseRadar: Sound Finder
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

### What's New In This Version

Required for updates; optional/not shown the same way for a first release.
Use this for version `1.1` if App Store Connect asks for it:

```text
Version 1.1 adds banner-supported free access, a one-time Remove Ads purchase, expanded language selection, translated help and interface text, and improved App Store-ready screenshots.
```

### Description

Paste this into App Store Connect:

```text
NoiseRadar is a simple iPhone utility that helps estimate the direction of the loudest sound around you and identify the general type of sound.

Use Scan 360 mode to find where sounds are coming from, or Listen mode to monitor nearby sound types in the foreground. NoiseRadar measures sound levels locally on your device, combines them with compass heading to estimate which direction had the strongest sound signal, and uses on-device sound classification to label likely sound types. Optional foreground threshold alerts and local share reports help users keep practical notes without recording or uploading audio.

Key features:
- 360 degree sound-direction scan
- Direction results by sound type
- Foreground Listen mode
- Local recent event history
- Configurable foreground threshold alerts
- Local text and CSV share reports
- Manual dB calibration offset
- First-run onboarding and readiness checklist
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
- Interface language selection with flags
- Free version supported by banner ads
- One-time Remove Ads purchase to hide banner ads forever
- No account, subscription, audio recording, cloud processing, or developer backend

NoiseRadar is designed for casual sound-direction estimates, troubleshooting, demonstrations, and general utility use. Results and sound labels are estimates and can be affected by background noise, echoes, overlapping sounds, microphone position, compass accuracy, phone movement, and how slowly the user rotates.

Privacy: sound levels, sound classification, compass heading, and recent event history are processed on device. The app does not create accounts, record audio files, upload microphone audio, or send scan data to a developer server. The free version displays Google Mobile Ads banner ads; users can remove banner ads forever with a non-consumable in-app purchase.
```

### Keywords

Maximum 100 characters total, comma-separated. Do not add spaces unless needed.

```text
sound,noise,loud,direction,detector,compass,microphone,classification,audio,utility
```

Character count: 83.

### Support URL

Required.

Recommended:

```text
https://www.vozhyk.com/noiseradar/support
```

Minimum support page content:

- App name: NoiseRadar.
- Contact email or support form.
- Short usage steps.
- Troubleshooting for microphone permission, location/compass permission, noisy rooms, and rotating too fast.
- Privacy policy link.
- Statement that the app requires a physical iPhone with microphone and compass.

Temporary option only if the repository is public:

```text
https://github.com/TODO/noiseradar/issues
```

### Marketing URL

Optional.

Use the Vozhyk main website:

```text
https://www.vozhyk.com/
```

This can be a simple product page with screenshots, description, support link,
and privacy link.

### Privacy Policy URL

Required for iOS apps.

Use the deployed NoiseRadar privacy policy:

```text
https://www.vozhyk.com/noiseradar/privacy-policy
```

The privacy policy must match the current app behavior. Recommended content:

- NoiseRadar uses microphone permission to measure sound levels and classify general sound types during scans.
- Audio is processed on device with Apple system audio and SoundAnalysis frameworks.
- The app does not record audio files.
- The app does not upload microphone audio.
- The app uses location permission only to access compass heading through iOS.
- The app uses motion only to check scan rotation speed.
- The app can generate local share reports from the current session.
- The app does not collect precise location for developer use.
- The app does not create accounts.
- The free version uses Google Mobile Ads banner ads.
- Google Mobile Ads may process data such as IP address, device identifiers, advertising data, user interactions with ads, crash logs, and performance diagnostics for advertising, measurement, fraud prevention, and SDK operation.
- The app does not use a separate analytics SDK or developer backend.
- The optional Remove Ads purchase is handled by Apple StoreKit.
- Buying or restoring Remove Ads hides all AdMob banner placements in the app.
- The app does not send scan results to a developer backend.
- Include contact email for privacy questions.

Do not say `no data collected` in the privacy policy because this build includes
Google Mobile Ads. Keep the App Privacy answers, privacy policy, review notes,
and actual SDK behavior consistent.

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

1. `screenshots/nr_01.jpg`: main screen before scanning.
2. `screenshots/nr_02.jpg`: calibration or scanning state.
3. `screenshots/nr_03.jpg`: completed scan with green result arrow and loudest heading.
4. `screenshots/nr_04.jpg`: scan quality/status or settings view.
5. `screenshots/nr_05.jpg`: help or language/settings view.
6. `screenshots/nr_06.jpg`: additional localized/settings/help screen.
7. `screenshots/nr_ads.jpg`: Remove Ads or ad-supported screen.

Current screenshot dimensions:

```text
nr_01.jpg through nr_06.jpg: 1179 x 2556 JPEG
nr_ads.jpg: 1179 x 2556 JPEG
```

Rules:

- Use screenshots from the actual submitted build.
- Use iPhone screenshots only if the app remains iPhone-only.
- Do not upload iPad screenshots unless the target is changed to support iPad.
- Do not show exaggerated claims in screenshot text.
- Do not include private addresses, private conversations, or unrelated third-party copyrighted material.
- App previews are optional. Skip the preview video for version 1.1 unless there is a polished physical-device demo.

## App Privacy Answers

In App Store Connect:

```text
Apps -> NoiseRadar: Sound Finder -> App Privacy
```

Because version `1.1` includes Google Mobile Ads, do not answer `No data
collected`. Apple says App Privacy must include the app's own privacy practices
and the privacy practices of third-party partners whose code is integrated.
Google's AdMob data-disclosure guidance says the Google Mobile Ads SDK may
collect data such as IP address, crash logs, performance data, device
identifiers, advertising data, and user interactions.

Recommended App Privacy setup for this build:

```text
Data Collection: Yes
Tracking: Yes if personalized ads, cross-app ad measurement, IDFA access, or any other Apple-defined tracking is enabled.
Tracking: No only if you have configured ads/consent so the app and Google Mobile Ads do not track under Apple's definition.
```

Use the conservative path for the first AdMob submission unless you have
explicitly disabled personalized ads/tracking and verified the final SDK
behavior:

```text
Tracking: Yes
```

Data types to disclose for Google Mobile Ads:

```text
Location:
- Coarse Location

Identifiers:
- Device ID

Usage Data:
- Product Interaction
- Advertising Data

Diagnostics:
- Crash Data
- Performance Data
```

Suggested purposes for the Google Mobile Ads data types:

```text
Third-Party Advertising
Analytics
App Functionality / SDK operation where App Store Connect offers it
Fraud Prevention, Security, and Compliance where App Store Connect offers it
```

NoiseRadar app-owned local sensor processing:

```text
Microphone levels: processed on device, not recorded, not uploaded.
Sound classification: processed on device through Apple SoundAnalysis.
Compass heading: used on device for direction estimates, not uploaded.
Motion/rotation speed: used on device for scan quality, not uploaded.
Recent history: in-memory local session history, not uploaded.
Share reports: generated locally only when the user taps Share.
```

If App Store Connect asks whether each data type is linked to the user's
identity, answer based on Google's current SDK disclosure and your AdMob account
configuration. If unsure, use the more conservative linked/tracking disclosure
and make sure the privacy policy says Google Mobile Ads is used for free-user
banner ads.

## Age Rating

In App Store Connect:

```text
Apps -> NoiseRadar: Sound Finder -> App Information -> Age Ratings -> Set Up Age Ratings
```

Suggested answers for the current app:

- User-generated content: No.
- Web access/browser: No.
- Messaging/chat/social networking: No.
- In-app purchases: Yes, non-consumable Remove Ads only.
- Gambling/contests/loot boxes: No.
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

Because this build includes Google Mobile Ads, answer this only after checking
the final Release build and AdMob configuration.

Conservative App Store Connect answer for an AdMob-supported free app:

```text
Yes, this app may use the Advertising Identifier (IDFA).
```

Select the purposes that match the final configuration:

```text
Serve advertisements within the app.
Attribute this app installation to a previously served advertisement.
Attribute an action taken within this app to a previously served advertisement.
```

If the app does not request App Tracking Transparency permission and you have
verified that the final build does not access IDFA, you may answer `No`, but
keep the App Privacy disclosures for Google Mobile Ads data collection. Do not
add an ATT prompt unless you intentionally support personalized ads/tracking and
have a clear `NSUserTrackingUsageDescription` purpose string.

## Digital Services Act / Trader Status

This is a legal/business answer for EU distribution.

Fill this according to the legal/business status of the Apple developer account:

```text
Trader status: Trader / Non-trader
Contact details: legal address, email, and phone required by App Store Connect if prompted
```

Choose based on whether the app is distributed in connection with a trade,
business, craft, or profession. If using paid apps or commercial distribution
from Lithuania/EU, review this carefully in App Store Connect.

## Pricing And Availability

Recommended first submission:

```text
Price: Free
Availability: All countries and regions, unless you intentionally limit distribution
Release method: Manual release after approval
```

Manual release gives time to inspect the approved version before it goes live.

## Remove Ads In-App Purchase

Create this App Store Connect in-app purchase before submitting version `1.1`:

| Field | Value |
| --- | --- |
| Type | Non-Consumable |
| Reference Name | `Remove Ads` |
| Product ID | `lt.bourdo.noiseradar.remove_ads` |
| Display Name | `Remove Ads` |
| Description | `Remove all ads from NoiseRadar forever with a one-time purchase.` |
| Suggested launch price | `EUR 0.99` or Apple-localized equivalent |
| Cleared for Sale | Yes |
| Review screenshot | Screenshot showing the Remove Ads sheet or `screenshots/nr_ads.jpg` if it clearly shows the purchase entry point |

Step-by-step:

1. Open App Store Connect.
2. Open `Apps -> NoiseRadar: Sound Finder`.
3. Open `Features -> In-App Purchases`.
4. Click `+`.
5. Select `Non-Consumable`.
6. Fill:

```text
Reference Name: Remove Ads
Product ID: lt.bourdo.noiseradar.remove_ads
```

7. Add English localization:

```text
Display Name: Remove Ads
Description: Remove all ads from NoiseRadar forever with a one-time purchase.
```

8. Set price:

```text
Price Schedule: EUR 0.99 launch price, or the closest App Store price tier that displays as €0.99.
Availability: All selected app countries/regions unless intentionally limited.
```

9. Upload the IAP review screenshot.
10. Save the in-app purchase.
11. On the app version `1.1` submission page, add this in-app purchase to the same submission before clicking `Add for Review`.

Do not submit version `1.1` without this product created. If the product is
missing, the app's Remove Ads sheet will show purchase unavailable for reviewers.

Review note for the IAP:

```text
The Remove Ads in-app purchase is a non-consumable purchase available from the main NoiseRadar screen and from Settings.

Review path:
1. Launch NoiseRadar on a physical iPhone.
2. Scroll to the main guidance area.
3. Tap Remove banner ads.
4. The Remove Ads sheet appears.
5. Tap Remove Ads to start the StoreKit purchase flow.
6. Tap Restore Purchases to restore a previous purchase.

After purchase or restore, all AdMob banner placements are hidden and ads are no longer loaded.

Product ID:
lt.bourdo.noiseradar.remove_ads
```

## App Review Information

In App Store Connect:

```text
Apps -> NoiseRadar: Sound Finder -> Distribution -> iOS App Version 1.1 -> App Review
```

### Contact Information

Required.

Fill with the real review contact:

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

NoiseRadar currently has no account system.

### Review Notes

Paste this into App Store Connect:

```text
NoiseRadar is a local sound-direction utility for iPhone. It estimates the direction of the loudest sound by combining microphone sound level readings with the iPhone compass heading while the user slowly rotates 360 degrees. It also uses Apple's on-device SoundAnalysis classifier to show broad sound type labels such as human voice, vehicles, mechanical sounds, animals, alarms, music, nature, household, and impact sounds. The app includes Scan 360 mode, foreground Listen mode, direction results by sound type, local recent event history, configurable foreground threshold alerts, manual calibration offset, and local share reports.

No account, login, subscription, sample file, server setup, or test credentials are required. The optional Remove Ads in-app purchase is available from the main screen and Settings and only removes banner advertisements.

Main test flow:
1. Install and launch NoiseRadar on a physical iPhone running iOS 15.0 or later.
2. Allow microphone access. The microphone is used only to measure sound levels and classify sound types during the scan.
3. Allow location access. Location Services are used to provide compass heading for direction estimation.
4. Tap Start Scan.
5. Keep the phone still during the short calibration step.
6. Hold the phone upright and slowly rotate 360 degrees.
7. Make a clear sound from one direction, such as clapping or speaking, while scanning.
8. Tap Stop & Analyze.
9. The app displays the estimated loudest heading in degrees, shows a green marker on the radar, and shows best-effort direction results by sound type.
10. Switch to Listen mode, tap Start Listening, make nearby sounds, then confirm local recent events appear in History.
11. Tap Settings and confirm the Language row opens the language selection screen.
12. On the main screen, tap Remove banner ads and confirm the Remove Ads sheet shows purchase and restore controls.
13. In Settings, confirm the Ad-Free section also opens Remove Ads and shows Restore Purchases. Purchasing or restoring Remove Ads hides all AdMob banners forever for that Apple ID.
14. The Help button opens short usage instructions.

Required hardware:
Review should be performed on a physical iPhone with microphone and compass support. The iOS Simulator cannot fully test the microphone, compass, and motion-sensor workflow.

External services:
The app uses SwiftUI, AVFoundation, SoundAnalysis, Core Location, Core Motion, UIKit haptics, Apple StoreKit for the optional Remove Ads purchase, and Google Mobile Ads for banner ads shown to free users. It does not use developer backend servers, authentication services, a separate analytics SDK, or cloud AI services.

Regional behavior:
The app functions consistently in all selected countries and regions, subject to iOS permissions and device sensor availability. There are no region-specific accounts, payments, or content differences.

Privacy:
Sound levels, sound classification, compass heading, and recent event history are processed on device. The app does not create accounts, record audio files, upload microphone audio, upload location, or send scan data to developer servers. Free users may see Google Mobile Ads banner ads; users who buy or restore Remove Ads no longer load those banners.

Scope:
NoiseRadar provides casual estimates only. It is not a certified acoustic instrument, emergency system, security system, surveillance tool, medical tool, or professional measurement device. Direction results and sound labels may be affected by background noise, echoes, overlapping sounds, microphone position, compass accuracy, phone movement, and rotation speed.
```

### Demo Attachment

Optional, but recommended if the first submission receives a Guideline 2.1
request for more information.

Public YouTube demo:

```text
https://youtube.com/shorts/kxWObeB3aho?feature=share
```

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
Apps -> NoiseRadar: Sound Finder -> Distribution -> iOS App Version 1.1 -> Build
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
8. Create or open the iOS app version `1.1`.
9. Select the processed build.
10. Fill Name, Subtitle, Promotional Text, Description, Keywords, categories, and copyright.
11. Add Support URL.
12. Add Privacy Policy URL.
13. Complete App Privacy.
14. Complete Age Rating.
15. Complete Content Rights.
16. Complete Export Compliance.
17. Confirm the IDFA answer matches Google Mobile Ads usage in the submitted binary.
18. Complete DSA/trader status if prompted.
19. Upload iPhone screenshots.
20. Set pricing and availability.
21. Add App Review contact information.
22. Add Review Notes from this guide.
23. Choose manual release after approval unless you intentionally want automatic release.
24. Add the `Remove Ads` in-app purchase to the same app-version submission.
25. Click `Add for Review`.
26. Open Draft Submissions and click `Submit for Review`.

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
- [ ] Paid Apps agreement, banking, or tax forms incomplete if submitting IAP.
- [ ] App Store listing name is already used. If so, keep the installed app
      display name as `NoiseRadar`, but use a unique listing name such as
      `NoiseRadar: Sound Finder` in App Store Connect.

## Final Rejection Prevention Checklist

- [ ] Metadata describes a casual utility, not a certified/professional/emergency/security tool.
- [ ] Description includes local processing and estimate limitations.
- [ ] Review Notes include the exact sensor test flow.
- [ ] Privacy Policy matches current code.
- [ ] App Privacy answers match actual data collection.
- [ ] Google Mobile Ads and StoreKit usage are reflected in privacy answers and review notes.
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
- Apple user privacy and data use: `https://developer.apple.com/app-store/user-privacy-and-data-use/`
- Google Mobile Ads iOS App Store data disclosure: `https://developers.google.com/admob/ios/privacy/data-disclosure`
- Google Mobile Ads iOS privacy and consent setup: `https://developers.google.com/admob/ios/privacy`
