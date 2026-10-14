# Agent Context: Noisy Detector iPhone App

Last reviewed: 2026-10-14

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

Noisy Detector is an iOS SwiftUI app that estimates the direction of the loudest sound source. It records microphone power levels while reading the iPhone compass heading as the user slowly rotates 360 degrees. After scanning, it reports the heading where the strongest filtered sound signal was measured.

The app is meant to run on a physical iPhone. The iOS Simulator is not suitable because accurate microphone, compass, and motion behavior require device sensors.

## Project Layout

- `NoisyDetector/NoisyDetector.xcodeproj`: Xcode project.
- `NoisyDetector/NoisyDetector/NoisyDetectorApp.swift`: SwiftUI app entry point.
- `NoisyDetector/NoisyDetector/SoundRadarView.swift`: Main SwiftUI interface, radar visualization, help sheet, controls, and status display.
- `NoisyDetector/NoisyDetector/AudioDirectionManager.swift`: Sensor, microphone, scan state, signal processing, and result analysis logic.
- `NoisyDetector/NoisyDetector/Info.plist`: App display name and permission usage strings.
- `NoisyDetector/NoisyDetector/Assets.xcassets`: App icon and launch image assets.
- `README.md`: User-facing project summary and quick start.
- `how_to_deploy.md`: Xcode deployment guide.
- `suggestions.md`: Improvement backlog.

## Current Build Settings Observed

- Swift version: 5.0.
- iOS deployment target: 15.0.
- Bundle identifier: `com.example.noisydetector`.
- Development team currently set in the Xcode project: `6X42CRDLS6`.

## How The App Works

`NoisyDetectorApp` opens `SoundRadarView`.

`SoundRadarView` owns one `@StateObject` instance of `AudioDirectionManager`. It renders:
- App title and usage prompt.
- Radar circle with N/E/S/W labels.
- A green polar sound blob from sampled headings and signal magnitudes.
- A red arrow showing current phone heading.
- A green result marker after analysis.
- A live volume circle whose size is derived from current decibels.
- Scan status, progress, quality, raw/smoothed decibels, top 3 headings, and Start/Stop controls.
- A Help sheet with basic usage steps.

`AudioDirectionManager` coordinates:
- `AVAudioSession` and `AVAudioRecorder` for microphone metering.
- `CLLocationManager` for magnetic heading updates.
- `CMMotionManager` for rotation-rate checks.
- A repeating 0.05 second timer while scanning.

## Scan Flow

1. On initialization, the manager requests microphone permission, requests When In Use location permission, starts heading updates, configures the audio session, and starts device-motion updates when available.
2. The user taps `Start Scan`.
3. The manager clears previous samples and enters a 1.5 second calibration phase.
4. During calibration, smoothed decibel samples are averaged to initialize the noise floor.
5. After calibration, the user slowly rotates 360 degrees.
6. Every timer tick, the manager:
   - Updates audio meters.
   - Applies exponential moving average smoothing.
   - Updates the adaptive noise floor.
   - Computes adjusted signal above the noise floor.
   - Applies a simple high-pass filter.
   - Rejects samples if rotation is too fast.
   - Stores heading, raw decibels, smoothed decibels, and filtered signal.
   - Updates scan progress from accumulated heading movement.
   - Updates top headings and polar visualization data.
7. The user taps `Stop & Analyze`.
8. The manager chooses the sample with the highest signal if it is above the minimum signal threshold.
9. The UI displays the loudest heading and result marker.

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

## Permissions

`Info.plist` declares:
- `NSMicrophoneUsageDescription`: required for reading microphone sound levels.
- `NSLocationWhenInUseUsageDescription`: required because compass heading is accessed through Core Location.

## Current Known Gaps And Risks

- Location authorization is tracked but `startScanning()` currently only blocks on microphone authorization, not location authorization.
- Help sheet `Done` button does not explicitly dismiss the sheet.
- The app uses magnetic heading only; no true-heading option is implemented.
- Scan progress accumulates absolute heading deltas, so back-and-forth rotation can count toward 360 degrees.
- Timers/audio are stopped on manual stop, but there is no explicit app-background or view-disappear cleanup.
- No automated tests are currently present.

## Verification Notes

Because this app depends on real iPhone microphone, compass, and motion sensors, meaningful end-to-end verification should be done on a physical iPhone through Xcode.

For code-only changes, useful checks include:
- Open `NoisyDetector/NoisyDetector.xcodeproj` in Xcode.
- Build the `NoisyDetector` scheme for a real device.
- Confirm microphone and location permissions are requested.
- Start a scan, wait for calibration, rotate slowly 360 degrees, stop, and verify a loudest heading appears.

## Change Log

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
- Reviewed `README.md`, `how_to_deploy.md`, `suggestions.md`, `Info.plist`, `NoisyDetectorApp.swift`, `SoundRadarView.swift`, `AudioDirectionManager.swift`, and relevant Xcode project settings.
- No build was run because this task only added documentation.
