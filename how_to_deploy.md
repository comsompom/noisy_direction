# How to Deploy (Xcode)

This guide explains how to build and deploy **Noisy Detector** to a real iPhone.

## 1) Prerequisites
- A Mac with Xcode 15+ installed.
- An Apple ID (free account works for on-device testing).
- An iPhone running iOS 15.0+.
- A USB cable or trusted Wi‑Fi pairing.

## 2) Open the Project
1. On your Mac, open Finder and go to the project folder.
2. Double‑click `NoisyDetector.xcodeproj`.
3. Wait for Xcode to load the project and index files.

## 3) Select the Target
1. In Xcode, at the top toolbar, ensure the scheme is **NoisyDetector**.
2. Select your **iPhone** as the run destination (not a Simulator).
   - The compass and microphone require a real device.

## 4) Configure Signing
1. Click the **NoisyDetector** project in the Project Navigator.
2. Select the **NoisyDetector** target.
3. Go to the **Signing & Capabilities** tab.
4. Check **Automatically manage signing**.
5. Choose your **Team** (your Apple ID).
6. If you see errors:
   - Ensure you are signed in to Xcode: **Xcode → Settings → Accounts**.
   - Change the **Bundle Identifier** to a unique value, e.g.
     `com.yourname.NoisyDetector`.

## 5) Connect and Trust the Device
1. Connect your iPhone via USB (or enable Wi‑Fi debugging).
2. On the iPhone, tap **Trust This Computer** if prompted.
3. In Xcode, confirm the device appears in the run destination list.

## 6) Build and Run
1. Click the **Run** button (▶) in Xcode.
2. Xcode will build and install the app on your iPhone.
3. If prompted on the iPhone:
   - Go to **Settings → Privacy & Security → Developer Mode** and enable it.
   - Restart the phone if required.

## 7) Grant Permissions
On first launch, the app asks for:
- **Microphone** access (required for sound level).
- **Location (When In Use)** access (required for compass heading).
Tap **Allow** for both.

## 8) Use the App
1. Tap **Start Scan**.
2. Slowly rotate your body 360°.
3. Tap **Stop & Analyze**.
4. The green arrow shows the loudest direction.

## 9) Common Issues
- **No microphone access**  
  Go to **Settings → Privacy & Security → Microphone** and enable the app.

- **Compass not updating**  
  Ensure **Location Services** are enabled and allow **When In Use**.

- **Build error: signing**  
  Change the bundle ID, reselect your Team, and retry.

- **Running on Simulator**  
  The simulator cannot access a real microphone/compass. Use a device.

## 10) Optional: App Icon
To add a custom icon:
1. Open `NoisyDetector/Assets.xcassets/AppIcon.appiconset`.
2. Drag your icon images into the appropriate slots.
3. Rebuild and run.

## Project Credits
Developer: Oleg Bourdo — https://www.linkedin.com/in/oleg-bourdo-8a2360139/

This project was created to support the Moon Home Agency initiative: https://moonhome.agency/
