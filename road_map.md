# NoiseRadar Road Map

Last updated: 2026-10-14

This roadmap is based on the current app state, existing `suggestions.md`, App Store positioning, and current market/customer signals around offline AI, accessibility, sound recognition, outdoor utility, noise logging, export, calibration, haptics, and privacy-first mobile apps.

## Current App Baseline

NoiseRadar currently provides:

- 360 degree scan to estimate the loudest sound direction.
- Offline on-device sound classification using Apple's built-in SoundAnalysis classifier.
- Broad sound categories such as human voice, vehicles, mechanical sounds, animals, alarms, music, nature, household, and impact sounds.
- Direction results by sound type.
- Foreground Scan 360 and Listen modes.
- Local in-memory event history for recent scan/listen events.
- First-run onboarding and readiness checklist.
- Radar visualization, polar sound blob, current heading marker, and result marker.
- Top 3 loudest headings.
- Raw and smoothed decibel display.
- Calibration step, adaptive noise floor, smoothing, high-pass filtering, and fast-rotation rejection.
- Haptic feedback.
- Help sheet.
- iPhone-only app with local processing and no account/backend.

## Implementation Status

Phase 1 is implemented in the iPhone app:

- Direction by sound type.
- Foreground Listen mode.
- Local event history.
- First-run onboarding and readiness checklist.
- iPhone-only build settings tightened to iPhone/iPhone Simulator only, with Mac/Vision designed-for availability disabled.

Phase 2 is implemented for the iPhone app:

- Threshold alerts with configurable sound category, dB threshold, confidence threshold, and alert style.
- Shareable session reports with text summary and CSV event log content.
- Manual calibration offset with reset and calibration guidance.
- Apple Watch companion was intentionally not implemented because the app is currently scoped to iPhone only.

Remaining Phase 1 hardening:

- Physical iPhone QA for scan/listen behavior.
- Accessibility pass on the new UI.
- Persist history if users need saved events across app launches.
- Polish visual layout after device screenshots.

## Research Signals

Current trends and customer requests suggest these directions matter most:

- On-device AI and offline-first behavior are increasingly important because users want privacy, speed, and features that work without connectivity.
- Accessibility sound-recognition workflows are valuable for deaf and hard-of-hearing users, caregivers, older adults, and anyone who may miss important environmental sounds.
- Apple already positions Sound Recognition as an accessibility feature using on-device intelligence, which validates the category but also means NoiseRadar should differentiate with direction, scanning, history, and outdoor field use.
- Sound meter apps compete heavily on calibration, session history, min/avg/max readings, charts, threshold alerts, Apple Watch support, Health/noise integrations, CSV/PDF export, and clean readable UI.
- User discussions around sound meter apps repeatedly ask for logs with date/time, exportable evidence, calibration clarity, threshold alerts, and uncluttered UI.
- Outdoor safety app trends emphasize offline reliability, clear situational awareness, and practical information when cell service is unavailable.

Sources checked:

- Apple Sound Recognition / Accessibility documentation.
- Apple SoundAnalysis / built-in intelligence documentation.
- App Store listings for current decibel/sound meter apps.
- Current mobile app trend reports and app-builder commentary for 2026.
- Public user discussions around sound meter, hearing support, and sound recognition apps.

## Product Direction

NoiseRadar should not try to become a certified sound meter, emergency rescue tool, surveillance tool, or professional acoustic instrument.

Best positioning:

```text
Offline sound direction and sound type awareness for everyday use, accessibility support, home troubleshooting, and outdoor situational awareness.
```

Core promise:

```text
What sound is nearby, how loud is it, and which direction did it come from?
```

## Highest-Value Roadmap

### Phase 1: Make The Core Result More Useful

Priority: Must do before App Store launch or soon after.

#### 1. Direction By Sound Type

Problem:
- The app currently points to the loudest signal overall. In real use, wind or traffic can overpower the sound the user cares about.

Feature:
- Track loudest direction separately for each sound category:
  - Human voice.
  - Animals.
  - Vehicles.
  - Mechanical.
  - Alarm.
  - Music.
  - Nature.
  - Impact.

UI:
- Result cards:
  - `Human voice: 72 degrees, 68% confidence`
  - `Vehicle: 238 degrees, 55% confidence`
- Add category filter chips: `All`, `Voice`, `Animal`, `Vehicle`, `Mechanical`, `Alarm`.

Why customers may like it:
- A hiker may want to ignore wind and find a voice.
- A homeowner may want to find a mechanical hum.
- A hard-of-hearing user may want to identify where a knock, alarm, or voice came from.

Implementation notes:
- Extend `SoundSample` to include current best sound category and confidence at sample time.
- Keep per-category max signal and per-category confidence-weighted score.
- Avoid claiming exact distance or guaranteed detection.

#### 2. Continuous Listen Mode

Problem:
- A manual 360 degree scan is useful, but users may want the phone to keep listening while sitting on a table, camping, working, or monitoring a room.

Feature:
- Add modes:
  - `Scan 360` for direction.
  - `Listen` for continuous sound type and alert monitoring.

Listen mode behavior:
- Shows current sound type.
- Shows current dB estimate.
- Shows recent sound events.
- Sends haptic/screen alerts for selected categories.

Why customers may like it:
- Makes the app useful even when the user cannot rotate.
- Fits accessibility and home monitoring use cases.

Implementation notes:
- Keep this foreground-only at first to avoid background audio/review complexity.
- Add clear battery/microphone indicators.

#### 3. Event History

Problem:
- Users often need proof or memory: what happened, when, how loud, and what direction.

Feature:
- Save session events locally:
  - Timestamp.
  - Sound category.
  - Best label.
  - Confidence.
  - Heading.
  - Peak dB.
  - Average dB.
  - Scan quality.

UI:
- `History` tab or sheet.
- Session summary cards.
- Event timeline.

Why customers may like it:
- Useful for apartment noise issues, appliance troubleshooting, wildlife/forest observations, and personal notes.

Privacy:
- Local-only by default.
- No audio recording unless a future explicit opt-in feature is added.

#### 4. Better Onboarding And First-Run Calibration

Problem:
- The app's value depends on correct use: phone upright, bottom mic uncovered, slow rotation, permission grants, and quiet calibration.

Feature:
- First-run onboarding with 3 short screens:
  - `Hold upright`.
  - `Stay still while calibrating`.
  - `Turn slowly 360 degrees`.
- Add a live readiness checklist:
  - Microphone permission.
  - Compass available.
  - Rotation speed OK.
  - Noise floor OK.
  - Mic likely not covered.

Why customers may like it:
- Reduces failed scans and bad first impressions.

## Phase 2: Features Customers Can Pay For Or Review Positively

Implementation status: implemented for iPhone, except Apple Watch companion intentionally skipped.

Priority: Next after the first usable App Store version.

#### 5. Threshold Alerts

Status: Implemented for foreground iPhone use.

Feature:
- User chooses:
  - dB threshold.
  - sound category.
  - confidence threshold.
  - alert style: haptic, screen flash, sound, or none.

Examples:
- Alert when an alarm is detected.
- Alert when a vehicle/mechanical sound is detected above a threshold.
- Alert when human voice is detected from one direction.

Why customers may like it:
- Strong accessibility and practical monitoring use case.
- Similar to what customers expect from modern sound-recognition tools.

Review caution:
- Avoid emergency-service claims. Phrase as `best-effort local alerts`.

#### 6. Export And Share Report

Status: Implemented as shareable text and CSV content.

Feature:
- Export session summaries as:
  - Text.
  - CSV.
  - PDF/image report later.

Report should include:
- Date/time.
- Device model.
- App version/build.
- Calibration state.
- Peak/average dB estimate.
- Top directions.
- Top sound categories.
- Disclaimer that phone microphone estimates are not certified measurements.

Why customers may like it:
- Customers reviewing sound meter apps often value timestamped logs and export.
- Useful for noise complaints, maintenance notes, field logs, and sharing observations.

#### 7. Calibration Settings

Status: Implemented as manual dB offset with reset and guidance.

Feature:
- Manual dB offset setting.
- Calibration guide:
  - `Quiet room`.
  - `Known reference meter`.
  - `Reset to default`.

Why customers may like it:
- Sound meter users often care about calibration because phone microphones differ.

Review caution:
- Do not claim professional accuracy.

#### 8. Apple Watch Companion

Status: Not implemented. The app remains iPhone-only by product decision.

Feature:
- Watch shows:
  - Current sound category.
  - Alert haptics.
  - Direction arrow simplified as `turn left/right` or heading degrees.
  - Start/stop scan remote control.

Why customers may like it:
- Haptics are useful for accessibility and outdoor use.
- The watch is easier to feel than a phone in a pocket.

Implementation notes:
- Start with notifications/haptics first.
- Full watch app can come later.

#### 9. Shortcuts / Action Button Integration

Feature:
- App Intents:
  - Start scan.
  - Stop scan.
  - Start listen mode.
  - Save last result.
  - Ask `what is the loudest direction?`

Why customers may like it:
- Hands-free workflows are increasingly expected.
- Useful when wearing gloves or outdoors.

## Phase 3: Differentiation

Priority: Build after core retention is proven.

#### 10. Outdoor / Deep Forest Mode

Feature:
- A mode optimized for outdoors:
  - Ignore constant wind-like noise.
  - Highlight human voice, animal, vehicle, mechanical, alarm, and impact categories.
  - Bigger UI.
  - Strong haptics.
  - Offline-only banner.
  - Compass confidence warning.

What it should say:

```text
Best-effort sound awareness. Not a navigation, rescue, or emergency tool.
```

Why customers may like it:
- Clear use case: camping, hiking, rural work, finding where a sound came from.

#### 11. Sound Map / Compass Trail

Feature:
- After scan, show a ring with category-colored sectors:
  - Voice sectors in blue.
  - Animals in green.
  - Vehicles/mechanical in orange.
  - Alarms in red.

Why customers may like it:
- Easier to understand than one arrow.
- Makes screenshots more compelling for App Store.

#### 12. Frequency View

Feature:
- Optional FFT/spectrum panel:
  - Low / mid / high energy.
  - Rumble warning.
  - Mechanical hum hint.
  - Whistle/high-pitch hint.

Why customers may like it:
- Common feature in premium decibel apps.
- Helps diagnose mechanical, electrical, appliance, or environmental noise.

Implementation notes:
- Keep it simple; avoid overwhelming casual users.

#### 13. Custom Sound Training

Feature:
- Let users create local custom labels for sounds:
  - `My generator`.
  - `My doorbell`.
  - `My dog`.
  - `Cabin pump`.

Why customers may like it:
- Apple Sound Recognition supports some custom sound workflows at the OS level, and customers understand the concept.
- This would make NoiseRadar personal and useful in recurring environments.

Implementation caution:
- This is a larger project. It may require Create ML / custom Core ML model workflows or careful sample capture and classification design.
- Need strong privacy copy and clear user consent if saving audio samples.

#### 14. Local Audio Clip Option

Feature:
- Optional 3-10 second local clip saved with an event.
- Disabled by default.
- User can delete all clips.
- No upload.

Why customers may like it:
- Evidence/context for logs.

Review/privacy caution:
- This changes App Privacy and product messaging. Do not add until policy/docs are ready.

#### 15. iCloud Sync For History

Feature:
- Optional iCloud sync for saved history/reports.

Why customers may like it:
- Useful across devices.

Privacy caution:
- App Privacy answers must change if data leaves local device storage.

## Accessibility Roadmap

These should be prioritized because they are useful and support the strongest differentiated customer group.

1. Dynamic Type support for all text.
2. VoiceOver labels for radar, arrows, start/stop, status, and results.
3. High-contrast mode.
4. Color-blind-safe category colors.
5. Haptic patterns by category:
   - Voice: short-short.
   - Alarm: long-long.
   - Vehicle/mechanical: pulse train.
6. Optional screen flash alert.
7. Large result mode:
   - One big label.
   - One big arrow.
   - One confidence line.
8. Apple Watch haptic alert support.

## Reliability / Quality Roadmap

1. Handle location permission denial before scanning.
2. Explicitly dismiss Help sheet.
3. Stop audio engine on scene background.
4. Handle audio session interruptions.
5. Handle route changes, headphones, and external microphones.
6. Add true heading option when location quality supports it.
7. Improve scan progress so back-and-forth turning does not count as full 360 degrees.
8. Add unit tests for:
   - EMA smoothing.
   - Noise floor update.
   - High-pass filter.
   - Heading wraparound.
   - Per-category loudest direction.
9. Add a debug sample log export behind a development flag.

## App Store / Monetization Ideas

Recommended first release:

```text
Free app, no ads, no account, local-only.
```

Potential paid features later:

- Unlimited history.
- CSV/PDF export.
- Outdoor Mode.
- Custom category alerts.
- Apple Watch companion.
- Frequency analyzer.
- Custom sound labels/training.

Avoid:

- Ads in the core scanning UI.
- Cloud upload by default.
- Emergency/rescue/security claims.
- Professional measurement claims.

## Suggested Implementation Order

### Version 1.0

- Fix App Store bundle ID.
- Improve first-run onboarding.
- Fix Help sheet dismissal.
- Block scan or clearly warn when location permission is denied.
- Add app background cleanup.
- Verify offline sound classification on physical iPhone.
- Submit with conservative metadata.

### Version 1.1

- Direction by sound type.
- Local event history.
- Export text/CSV.
- Threshold alerts.
- Better accessibility labels and Dynamic Type.

### Version 1.2

- Listen mode.
- Outdoor / Deep Forest Mode.
- Category-colored sound map.
- Calibration settings.
- Improved scan progress algorithm.

### Version 1.3

- Apple Watch haptic alerts.
- Shortcuts / Action Button integration.
- Frequency view.
- PDF/image report export.

### Version 2.0

- Custom local sound labels/training.
- Optional local audio clips.
- Optional iCloud sync.
- Advanced outdoor field tools if customer feedback supports them.

## Top 10 Concrete Tickets

1. Add `SoundCategory` enum and store category/confidence in each scan sample.
2. Add per-category loudest direction calculation.
3. Add result cards for top categories.
4. Add first-run onboarding.
5. Add foreground Listen mode.
6. Add local session history model.
7. Add CSV export for history.
8. Add threshold alert settings.
9. Add app background/audio interruption cleanup.
10. Add VoiceOver/Dynamic Type pass for the main screen.

## Success Metrics

Track locally first, without analytics SDK:

- Scan completion rate.
- Average failed scans per session.
- Most used mode: scan vs listen.
- Number of saved sessions.
- Number of exports.
- Alert categories enabled.
- Feature requests from App Store reviews/support.

If analytics are added later, update App Privacy, privacy policy, `app_store_deploy.md`, and `agent_context.md` first.
