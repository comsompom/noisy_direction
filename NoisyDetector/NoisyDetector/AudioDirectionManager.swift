import AVFoundation
import Combine
import CoreLocation
import CoreMotion
import Foundation
import UIKit

final class AudioDirectionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private struct SoundSample {
        let heading: Double
        let rawDecibels: Float
        let smoothedDecibels: Float
        let signal: Float
    }

    struct PolarPoint {
        let heading: Double
        let magnitude: Float
    }

    private let emaAlpha: Float = 0.2
    private let noiseFloorDownAlpha: Float = 0.2
    private let noiseFloorUpAlpha: Float = 0.02
    private let highPassAlpha: Float = 0.9
    private let minDetectedSignal: Float = 3.0
    private let calibrationDuration: TimeInterval = 1.5
    private let maxRotationRate: Double = 2.0
    private let noisyEnvironmentThreshold: Float = -35.0

    private var audioRecorder: AVAudioRecorder?
    private var locationManager: CLLocationManager?
    private let motionManager = CMMotionManager()
    private var timer: Timer?
    private var samples: [SoundSample] = []
    private var emaDecibels: Float?
    private var noiseFloorEMA: Float = -60.0
    private var previousAdjustedDecibels: Float?
    private var previousHighPass: Float = 0.0
    private var calibrationSamples: [Float] = []
    private var calibrationStart: Date?
    private var currentRotationRate: Double = 0.0
    private var lastHeading: Double?
    private var accumulatedRotation: Double = 0.0
    private var isRecordingAuthorized = false
    private var isLocationAuthorized = false
    private var isCalibrating = false
    private let haptics = UINotificationFeedbackGenerator()

    @Published var currentDecibels: Float = -160.0
    @Published var lastRawDecibels: Float = -160.0
    @Published var lastSmoothedDecibels: Float = -160.0
    @Published var currentHeading: Double = 0.0
    @Published var isScanning = false
    @Published var directionOfLoudestSound: Double?
    @Published var statusText: String = "Ready"
    @Published var scanProgress: Double = 0.0
    @Published var scanQualityText: String = "Ready"
    @Published var scanQualityLevel: ScanQualityLevel = .normal
    @Published var topHeadings: [Double] = []
    @Published var polarPoints: [PolarPoint] = []

    enum ScanQualityLevel {
        case normal
        case warning
        case bad
    }

    var volumeCircleSize: CGFloat {
        // Map -60...0 to 100...220
        let clamped = max(-60.0, min(0.0, currentDecibels))
        let normalized = (clamped + 60.0) / 60.0
        return 100.0 + (normalized * 120.0)
    }

    override init() {
        super.init()
        setupLocation()
        setupAudio()
        setupMotion()
    }

    private func setupLocation() {
        guard CLLocationManager.headingAvailable() else {
            statusText = "Compass unavailable on this device."
            return
        }

        let manager = CLLocationManager()
        manager.delegate = self
        manager.requestWhenInUseAuthorization()
        manager.headingFilter = 1
        manager.startUpdatingHeading()
        locationManager = manager
    }

    private func setupAudio() {
        let session = AVAudioSession.sharedInstance()
        session.requestRecordPermission { [weak self] granted in
            DispatchQueue.main.async {
                self?.isRecordingAuthorized = granted
                if !granted {
                    self?.statusText = "Microphone permission is required."
                }
            }
        }

        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers])
            try session.setActive(true)

            let url = URL(fileURLWithPath: "/dev/null")
            let settings: [String: Any] = [
                AVFormatIDKey: Int(kAudioFormatAppleLossless),
                AVSampleRateKey: 44100.0,
                AVNumberOfChannelsKey: 1,
                AVEncoderAudioQualityKey: AVAudioQuality.min.rawValue
            ]

            audioRecorder = try AVAudioRecorder(url: url, settings: settings)
            audioRecorder?.isMeteringEnabled = true
            audioRecorder?.prepareToRecord()
        } catch {
            statusText = "Audio setup failed."
        }
    }

    private func setupMotion() {
        guard motionManager.isDeviceMotionAvailable else { return }
        motionManager.deviceMotionUpdateInterval = 0.05
        motionManager.startDeviceMotionUpdates(to: .main) { [weak self] motion, _ in
            guard let rotationRate = motion?.rotationRate else { return }
            let magnitude = sqrt(rotationRate.x * rotationRate.x +
                                 rotationRate.y * rotationRate.y +
                                 rotationRate.z * rotationRate.z)
            self?.currentRotationRate = magnitude
        }
    }

    func startScanning() {
        guard isRecordingAuthorized else {
            statusText = "Enable microphone in Settings."
            return
        }

        samples.removeAll()
        calibrationSamples.removeAll()
        calibrationStart = Date()
        directionOfLoudestSound = nil
        isScanning = true
        isCalibrating = true
        statusText = "Calibrating... stay still"
        scanQualityText = "Calibrating"
        scanQualityLevel = .normal
        scanProgress = 0.0
        accumulatedRotation = 0.0
        lastHeading = nil
        topHeadings = []
        polarPoints = []
        emaDecibels = nil
        previousAdjustedDecibels = nil
        previousHighPass = 0.0

        audioRecorder?.record()
        haptics.prepare()
        haptics.notificationOccurred(.success)
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.captureSample()
        }
    }

    func stopScanning() {
        isScanning = false
        isCalibrating = false
        audioRecorder?.stop()
        timer?.invalidate()
        analyzeResults()
        haptics.notificationOccurred(.warning)
    }

    private func captureSample() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()

        let decibels = recorder.averagePower(forChannel: 0)
        let smoothedDecibels = applyEMA(to: decibels)
        lastRawDecibels = decibels
        lastSmoothedDecibels = smoothedDecibels

        if isCalibrating {
            calibrationSamples.append(smoothedDecibels)
            if let start = calibrationStart,
               Date().timeIntervalSince(start) >= calibrationDuration {
                let total = calibrationSamples.reduce(0, +)
                noiseFloorEMA = calibrationSamples.isEmpty ? -60.0 : (total / Float(calibrationSamples.count))
                isCalibrating = false
                statusText = "Scanning... turn slowly 360°"
                scanQualityText = "Good"
                scanQualityLevel = .normal
            } else {
                statusText = "Calibrating... stay still"
                scanQualityText = "Calibrating"
                scanQualityLevel = .normal
            }
            currentDecibels = smoothedDecibels
            return
        }

        updateNoiseFloor(with: smoothedDecibels)
        let adjustedDecibels = smoothedDecibels - noiseFloorEMA
        let filteredSignal = highPassFilter(adjustedDecibels)
        let signalForSample = max(0.0, filteredSignal)

        currentDecibels = smoothedDecibels

        if isScanning {
            if currentRotationRate > maxRotationRate {
                statusText = "Scanning... slow down"
                scanQualityText = "Too fast"
                scanQualityLevel = .bad
                return
            }
            if statusText == "Scanning... slow down" {
                statusText = "Scanning... turn slowly 360°"
                scanQualityText = "Good"
                scanQualityLevel = .normal
            }
            if noiseFloorEMA > noisyEnvironmentThreshold {
                scanQualityText = "Too noisy"
                scanQualityLevel = .warning
            } else if signalForSample < minDetectedSignal {
                scanQualityText = "Too quiet"
                scanQualityLevel = .warning
            }
            let sample = SoundSample(
                heading: currentHeading,
                rawDecibels: decibels,
                smoothedDecibels: smoothedDecibels,
                signal: signalForSample
            )
            samples.append(sample)
            updateProgress(with: currentHeading)
            updateDerivedData()
        }
    }

    private func applyEMA(to decibels: Float) -> Float {
        if let previous = emaDecibels {
            let next = (emaAlpha * decibels) + ((1.0 - emaAlpha) * previous)
            emaDecibels = next
            return next
        }
        emaDecibels = decibels
        return decibels
    }

    private func updateNoiseFloor(with decibels: Float) {
        if decibels < noiseFloorEMA {
            noiseFloorEMA = (noiseFloorDownAlpha * decibels) + ((1.0 - noiseFloorDownAlpha) * noiseFloorEMA)
        } else {
            noiseFloorEMA = (noiseFloorUpAlpha * decibels) + ((1.0 - noiseFloorUpAlpha) * noiseFloorEMA)
        }
    }

    private func highPassFilter(_ decibels: Float) -> Float {
        guard let previous = previousAdjustedDecibels else {
            previousAdjustedDecibels = decibels
            previousHighPass = 0.0
            return 0.0
        }
        let highPass = highPassAlpha * (previousHighPass + decibels - previous)
        previousAdjustedDecibels = decibels
        previousHighPass = highPass
        return highPass
    }

    private func analyzeResults() {
        guard let maxSample = samples.max(by: { $0.signal < $1.signal }),
              maxSample.signal > minDetectedSignal else {
            statusText = "Sound too quiet. Try again."
            scanQualityText = "Too quiet"
            scanQualityLevel = .warning
            return
        }

        directionOfLoudestSound = maxSample.heading
        statusText = "Scan complete."
        scanQualityText = "Good"
        scanQualityLevel = .normal
        haptics.notificationOccurred(.success)
    }

    func locationManager(_ manager: CLLocationManager, didUpdateHeading newHeading: CLHeading) {
        DispatchQueue.main.async {
            self.currentHeading = newHeading.magneticHeading
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        let status = manager.authorizationStatus
        isLocationAuthorized = (status == .authorizedAlways || status == .authorizedWhenInUse)
        if !isLocationAuthorized {
            statusText = "Enable location access for compass."
        }
    }

    private func updateProgress(with heading: Double) {
        guard let previous = lastHeading else {
            lastHeading = heading
            return
        }
        var delta = abs(heading - previous)
        if delta > 180.0 {
            delta = 360.0 - delta
        }
        accumulatedRotation += delta
        lastHeading = heading
        scanProgress = min(1.0, accumulatedRotation / 360.0)
    }

    private func updateDerivedData() {
        let sorted = samples.sorted { $0.signal > $1.signal }
        topHeadings = sorted.prefix(3).map { $0.heading }
        polarPoints = samples.map { PolarPoint(heading: $0.heading, magnitude: $0.signal) }
    }
}
