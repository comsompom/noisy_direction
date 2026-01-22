# Suggestions and Improvements

This file lists ideas to improve the **Noisy Detector** app, based on the
current project structure and features.

## Accuracy and Signal Processing
- [x] Add adaptive noise floor detection, so quiet rooms are handled better.
- [x] Use weighted averaging or EMA instead of fixed rolling average.
- [x] Apply a simple high‑pass filter to reduce low‑frequency rumble.
- [x] Discard samples while the phone is moving too fast (gyro threshold).
- [x] Add a calibration step to capture baseline noise before scanning.

## UX and UI
- [ ] Add a short onboarding screen explaining the 360° scan.
- [x] Include a compass ring with labeled cardinal directions (N/E/S/W).
- [x] Show a progress indicator for the 360° sweep.
- [x] Provide haptic feedback when scanning starts/stops or on result.
- [x] Add a “scan quality” indicator (too fast, too quiet, too noisy).

## Data Visualization
- [x] Plot the full polar “sound blob” instead of only the max point.
- [x] Show the top 3 loudest headings, not just one.
- [x] Display raw vs smoothed volume for transparency.

## Device and Sensor Handling
- [x] Handle missing magnetometer with a clear fallback message.
- [ ] Offer a “use true heading” toggle when location calibration is good.
- [x] Detect mic obstruction and warn if the bottom mic is covered.

## Performance and Reliability
- [ ] Pause scanning when the app goes to background and resume cleanly.
- [ ] Stop timers and audio session on view disappear.
- [ ] Add error states for audio session interruptions (calls, Siri).

## Accessibility and Localization
- [ ] Add Dynamic Type support for larger text sizes.
- [ ] VoiceOver labels for the radar and buttons.
- [ ] Localize strings for common languages.

## Testing and QA
- [ ] Add unit tests for smoothing and max‑heading selection.
- [ ] Add UI tests for Start/Stop flow.
- [ ] Log sample data to a file for debugging in development builds.

## Project Credits
Developer: Oleg Bourdo — https://www.linkedin.com/in/oleg-bourdo-8a2360139/

This project was created to support the Moon Home Agency initiative: https://moonhome.agency/


