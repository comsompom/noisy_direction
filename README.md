# Noisy Detector

An iOS SwiftUI app that finds the direction of the loudest sound by combining
microphone amplitude with the device's compass heading while the user turns
around 360°.

## Features
- Live sound level visualization
- Radar-style direction display
- Smooth rolling average to reduce noise spikes
- Simple Start/Stop scan flow

## Requirements
- macOS with Xcode 15+ (or newer)
- iPhone with microphone + compass (magnetometer)
- iOS 15.0+

## Project Layout
- `NoisyDetector.xcodeproj` – Xcode project
- `NoisyDetector/` – App source code
  - `AudioDirectionManager.swift` – microphone + compass logic
  - `SoundRadarView.swift` – UI
  - `Info.plist` – permissions

## Permissions
The app requests:
- Microphone access to read sound levels
- Location access (When In Use) to read compass heading

## Quick Start
1. Open `NoisyDetector.xcodeproj` in Xcode.
2. Set your Development Team in Signing.
3. Run on a physical iPhone.
4. Tap **Start Scan**, rotate 360°, tap **Stop & Analyze**.

For full deployment steps, see `how_to_deploy.md`.
