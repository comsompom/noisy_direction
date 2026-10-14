import AVFoundation
import Combine
import CoreLocation
import CoreMedia
import CoreMotion
import Foundation
import SoundAnalysis
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

    struct SoundClassification: Identifiable {
        let identifier: String
        let displayName: String
        let category: String
        let confidence: Double

        var id: String { identifier }
    }

    private let emaAlpha: Float = 0.2
    private let noiseFloorDownAlpha: Float = 0.2
    private let noiseFloorUpAlpha: Float = 0.02
    private let highPassAlpha: Float = 0.9
    private let minDetectedSignal: Float = 3.0
    private let calibrationDuration: TimeInterval = 1.5
    private let maxRotationRate: Double = 2.0
    private let noisyEnvironmentThreshold: Float = -35.0

    private let audioEngine = AVAudioEngine()
    private let analysisQueue = DispatchQueue(label: "NoisyDetector.SoundAnalysis")
    private var streamAnalyzer: SNAudioStreamAnalyzer?
    private var soundClassificationRequest: SNClassifySoundRequest?
    private var soundClassificationObserver: SoundClassificationObserver?
    private var locationManager: CLLocationManager?
    private let motionManager = CMMotionManager()
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
    @Published var currentSoundClassification: SoundClassification?
    @Published var topSoundClassifications: [SoundClassification] = []
    @Published var soundClassificationStatus: String = "Sound type: Ready"

    enum ScanQualityLevel {
        case normal
        case warning
        case bad
    }

    var volumeCircleSize: CGFloat {
        // Map -60...0 to 100...220
        let clamped = max(-60.0, min(0.0, currentDecibels))
        let normalized = (clamped + 60.0) / 60.0
        return CGFloat(100.0 + (normalized * 120.0))
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
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true)
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
        currentSoundClassification = nil
        topSoundClassifications = []
        soundClassificationStatus = "Sound type: Listening..."
        emaDecibels = nil
        previousAdjustedDecibels = nil
        previousHighPass = 0.0

        do {
            try startAudioEngine()
        } catch {
            isScanning = false
            isCalibrating = false
            statusText = "Audio input failed."
            scanQualityText = "Audio error"
            scanQualityLevel = .bad
            soundClassificationStatus = "Sound type: Unavailable"
            return
        }

        haptics.prepare()
        haptics.notificationOccurred(.success)
    }

    func stopScanning() {
        isScanning = false
        isCalibrating = false
        stopAudioEngine()
        analyzeResults()
        haptics.notificationOccurred(.warning)
    }

    private func startAudioEngine() throws {
        stopAudioEngine()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
        try session.setActive(true)

        let inputNode = audioEngine.inputNode
        let inputBus = AVAudioNodeBus(0)
        let inputFormat = inputNode.outputFormat(forBus: inputBus)

        let analyzer = SNAudioStreamAnalyzer(format: inputFormat)
        let request = try SNClassifySoundRequest(classifierIdentifier: .version1)
        request.windowDuration = CMTime(seconds: 1.5, preferredTimescale: 48_000)
        request.overlapFactor = 0.8

        let observer = SoundClassificationObserver { [weak self] result in
            self?.handleSoundClassification(result)
        } onFailure: { [weak self] error in
            DispatchQueue.main.async {
                self?.soundClassificationStatus = "Sound type: \(error.localizedDescription)"
            }
        }

        try analyzer.add(request, withObserver: observer)

        streamAnalyzer = analyzer
        soundClassificationRequest = request
        soundClassificationObserver = observer

        inputNode.removeTap(onBus: inputBus)
        inputNode.installTap(onBus: inputBus, bufferSize: 4096, format: inputFormat) { [weak self] buffer, time in
            self?.processAudioBuffer(buffer)
            self?.analysisQueue.async {
                self?.streamAnalyzer?.analyze(buffer, atAudioFramePosition: time.sampleTime)
            }
        }

        audioEngine.prepare()
        try audioEngine.start()
    }

    private func stopAudioEngine() {
        if audioEngine.isRunning {
            audioEngine.inputNode.removeTap(onBus: 0)
            audioEngine.stop()
        }

        analysisQueue.sync {
            streamAnalyzer?.completeAnalysis()
            streamAnalyzer?.removeAllRequests()
            streamAnalyzer = nil
            soundClassificationRequest = nil
            soundClassificationObserver = nil
        }
    }

    private func processAudioBuffer(_ buffer: AVAudioPCMBuffer) {
        let decibels = calculateDecibels(from: buffer)
        DispatchQueue.main.async { [weak self] in
            self?.captureSample(decibels: decibels)
        }
    }

    private func calculateDecibels(from buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData,
              buffer.frameLength > 0 else {
            return -160.0
        }

        let channel = channelData[0]
        let frameCount = Int(buffer.frameLength)
        var sumSquares: Float = 0.0

        for frame in 0..<frameCount {
            let sample = channel[frame]
            sumSquares += sample * sample
        }

        let rms = sqrt(sumSquares / Float(frameCount))
        guard rms > 0 else { return -160.0 }
        return max(-160.0, 20.0 * log10(rms))
    }

    private func captureSample(decibels: Float) {
        guard isScanning || isCalibrating else { return }

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

    private func handleSoundClassification(_ result: SNClassificationResult) {
        let classifications = result.classifications
            .prefix(3)
            .map { classification in
                let displayName = formatClassificationName(classification.identifier)
                return SoundClassification(
                    identifier: classification.identifier,
                    displayName: displayName,
                    category: category(for: classification.identifier),
                    confidence: classification.confidence
                )
            }

        DispatchQueue.main.async {
            self.topSoundClassifications = Array(classifications)

            guard let best = classifications.first, best.confidence >= 0.15 else {
                self.currentSoundClassification = nil
                self.soundClassificationStatus = "Sound type: Unknown"
                return
            }

            self.currentSoundClassification = best
            let confidence = Int((best.confidence * 100.0).rounded())
            self.soundClassificationStatus = "Sound type: \(best.category) - \(best.displayName) \(confidence)%"
        }
    }

    private func category(for identifier: String) -> String {
        let value = identifier.lowercased()

        if containsAny(value, ["speech", "voice", "conversation", "narration", "singing", "laughter", "giggle", "cough", "sneeze", "snoring", "breathing", "crying", "sigh", "scream", "whisper", "yell", "chant", "human"]) {
            return "Human voice"
        }
        if containsAny(value, ["animal", "dog", "bark", "cat", "meow", "bird", "chirp", "crow", "horse", "neigh", "cow", "moo", "sheep", "goat", "pig", "oink", "chicken", "rooster", "insect", "mosquito", "fly", "bee", "frog"]) {
            return "Animals"
        }
        if containsAny(value, ["vehicle", "car", "auto", "automobile", "bus", "truck", "motorcycle", "motorbike", "aircraft", "airplane", "helicopter", "train", "subway", "boat", "ship"]) {
            return "Vehicles"
        }
        if containsAny(value, ["mechanical", "engine", "motor", "machinery", "machine", "tool", "drill", "saw", "hammer", "jackhammer", "blender", "vacuum", "printer", "typing", "keyboard", "clicking", "clatter", "squeak", "pump"]) {
            return "Mechanical"
        }
        if containsAny(value, ["alarm", "siren", "bell", "buzzer", "smoke detector", "fire alarm", "ringtone", "telephone"]) {
            return "Alarm"
        }
        if containsAny(value, ["music", "musical", "guitar", "piano", "drum", "violin", "flute", "bass", "instrument"]) {
            return "Music"
        }
        if containsAny(value, ["rain", "thunder", "wind", "water", "stream", "ocean", "waves", "fire", "crackle"]) {
            return "Nature"
        }
        if containsAny(value, ["dish", "microwave", "door", "drawer", "faucet", "toilet", "shower", "household"]) {
            return "Household"
        }
        if containsAny(value, ["bang", "thump", "knock", "clap", "footstep", "impact"]) {
            return "Impact"
        }

        return "Other"
    }

    private func containsAny(_ value: String, _ keywords: [String]) -> Bool {
        keywords.contains { value.contains($0) }
    }

    private func formatClassificationName(_ identifier: String) -> String {
        identifier
            .replacingOccurrences(of: "_", with: " ")
            .replacingOccurrences(of: "-", with: " ")
            .split(separator: " ")
            .map { word in
                word.prefix(1).uppercased() + word.dropFirst()
            }
            .joined(separator: " ")
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

private final class SoundClassificationObserver: NSObject, SNResultsObserving {
    private let onResult: (SNClassificationResult) -> Void
    private let onFailure: (Error) -> Void

    init(onResult: @escaping (SNClassificationResult) -> Void, onFailure: @escaping (Error) -> Void) {
        self.onResult = onResult
        self.onFailure = onFailure
    }

    func request(_ request: SNRequest, didProduce result: SNResult) {
        guard let result = result as? SNClassificationResult else { return }
        onResult(result)
    }

    func request(_ request: SNRequest, didFailWithError error: Error) {
        onFailure(error)
    }
}
