import AVFoundation
import AudioToolbox
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
        let soundCategory: String?
        let soundLabel: String?
        let soundConfidence: Double
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

    struct CategoryDirectionResult: Identifiable {
        let category: String
        let heading: Double
        let confidence: Double
        let signal: Float
        let label: String
        let sampleCount: Int

        var id: String { category }
    }

    struct SoundEvent: Identifiable {
        let id = UUID()
        let date: Date
        let mode: DetectionMode
        let category: String
        let label: String
        let confidence: Double
        let heading: Double?
        let peakDecibels: Float
        let averageDecibels: Float
        let scanQuality: String
    }

    struct ReadinessItem: Identifiable {
        let id = UUID()
        let title: String
        let detail: String
        let isReady: Bool
    }

    struct SessionReport {
        let text: String
        let csv: String
    }

    enum DetectionMode: String, CaseIterable, Identifiable {
        case scan360
        case listen

        var id: String { rawValue }

        var title: String {
            switch self {
            case .scan360:
                return "Scan 360"
            case .listen:
                return "Listen"
            }
        }
    }

    enum AlertStyle: String, CaseIterable, Identifiable {
        case none
        case haptic
        case screenFlash
        case sound

        var id: String { rawValue }

        var title: String {
            switch self {
            case .none:
                return "None"
            case .haptic:
                return "Haptic"
            case .screenFlash:
                return "Screen Flash"
            case .sound:
                return "Sound"
            }
        }
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
    private let analysisQueue = DispatchQueue(label: "NoiseRadar.SoundAnalysis")
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
    private var isCalibrating = false
    private var lastLoggedEventCategory: String?
    private var lastLoggedEventDate: Date?
    private var lastThresholdAlertDate: Date?
    private var lastThresholdAlertCategory: String?
    private let haptics = UINotificationFeedbackGenerator()
    private let defaults = UserDefaults.standard

    @Published var selectedMode: DetectionMode = .scan360
    @Published private(set) var isMicrophoneAuthorized = false
    @Published private(set) var isLocationAuthorized = false
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
    @Published var categoryDirectionResults: [CategoryDirectionResult] = []
    @Published var soundEvents: [SoundEvent] = []
    @Published var isThresholdAlertEnabled: Bool {
        didSet { defaults.set(isThresholdAlertEnabled, forKey: "isThresholdAlertEnabled") }
    }
    @Published var alertDecibelThreshold: Float {
        didSet { defaults.set(alertDecibelThreshold, forKey: "alertDecibelThreshold") }
    }
    @Published var alertConfidenceThreshold: Double {
        didSet { defaults.set(alertConfidenceThreshold, forKey: "alertConfidenceThreshold") }
    }
    @Published var alertCategory: String {
        didSet { defaults.set(alertCategory, forKey: "alertCategory") }
    }
    @Published var alertStyle: AlertStyle {
        didSet { defaults.set(alertStyle.rawValue, forKey: "alertStyle") }
    }
    @Published var calibrationOffset: Float {
        didSet { defaults.set(calibrationOffset, forKey: "calibrationOffset") }
    }
    @Published var lastAlertMessage: String = "Alerts ready"
    @Published var shouldFlashAlert = false

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
        let storedAlertStyle = defaults.string(forKey: "alertStyle").flatMap(AlertStyle.init(rawValue:)) ?? .haptic
        isThresholdAlertEnabled = defaults.object(forKey: "isThresholdAlertEnabled") as? Bool ?? false
        alertDecibelThreshold = defaults.object(forKey: "alertDecibelThreshold") as? Float ?? -30.0
        alertConfidenceThreshold = defaults.object(forKey: "alertConfidenceThreshold") as? Double ?? 0.45
        alertCategory = defaults.string(forKey: "alertCategory") ?? "Any"
        alertStyle = storedAlertStyle
        calibrationOffset = defaults.object(forKey: "calibrationOffset") as? Float ?? 0.0
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
                self?.isMicrophoneAuthorized = granted
                if !granted {
                    self?.statusText = "Microphone permission is required."
                }
            }
        }

        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
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
        startSession(mode: .scan360)
    }

    func startListening() {
        startSession(mode: .listen)
    }

    func startSelectedMode() {
        startSession(mode: selectedMode)
    }

    private func startSession(mode: DetectionMode) {
        guard isMicrophoneAuthorized else {
            statusText = "Enable microphone in Settings."
            return
        }

        selectedMode = mode
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
        categoryDirectionResults = []
        currentSoundClassification = nil
        topSoundClassifications = []
        soundClassificationStatus = "Sound type: Listening..."
        lastLoggedEventCategory = nil
        lastLoggedEventDate = nil
        emaDecibels = nil
        previousAdjustedDecibels = nil
        previousHighPass = 0.0

        if mode == .listen {
            statusText = "Calibrating... stay still"
            scanQualityText = "Listening"
        }

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
        if selectedMode == .scan360 {
            analyzeResults()
        } else {
            statusText = "Listen stopped."
            scanQualityText = "Ready"
            scanQualityLevel = .normal
        }
        haptics.notificationOccurred(.warning)
    }

    private func startAudioEngine() throws {
        stopAudioEngine()

        let session = AVAudioSession.sharedInstance()
        try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
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
        let decibels = calculateDecibels(from: buffer) + calibrationOffset
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
                if selectedMode == .scan360 {
                    statusText = "Scanning... turn slowly 360°"
                    scanQualityText = "Good"
                } else {
                    statusText = "Listening..."
                    scanQualityText = "Listening"
                }
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
            if selectedMode == .scan360 && currentRotationRate > maxRotationRate {
                statusText = "Scanning... slow down"
                scanQualityText = "Too fast"
                scanQualityLevel = .bad
                return
            }
            if selectedMode == .scan360 && statusText == "Scanning... slow down" {
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
            } else if selectedMode == .listen {
                scanQualityText = "Listening"
                scanQualityLevel = .normal
            }

            let classification = currentSoundClassification
            let sample = SoundSample(
                heading: currentHeading,
                rawDecibels: decibels,
                smoothedDecibels: smoothedDecibels,
                signal: signalForSample,
                soundCategory: classification?.category,
                soundLabel: classification?.displayName,
                soundConfidence: classification?.confidence ?? 0.0
            )
            samples.append(sample)
            evaluateThresholdAlert(with: sample)
            if selectedMode == .scan360 {
                updateProgress(with: currentHeading)
            }
            updateDerivedData()
            updateListenEvents(with: sample)
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
        logSummaryEvents()
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
        categoryDirectionResults = buildCategoryDirectionResults(from: samples)
    }

    private func buildCategoryDirectionResults(from samples: [SoundSample]) -> [CategoryDirectionResult] {
        let categorized = Dictionary(grouping: samples) { sample in
            sample.soundCategory ?? "Other"
        }

        return categorized.compactMap { category, samples in
            guard category != "Other" || samples.contains(where: { $0.soundConfidence > 0.0 }) else {
                return nil
            }
            guard let best = samples.max(by: { weightedScore($0) < weightedScore($1) }),
                  best.signal > minDetectedSignal else {
                return nil
            }

            return CategoryDirectionResult(
                category: category,
                heading: best.heading,
                confidence: best.soundConfidence,
                signal: best.signal,
                label: category,
                sampleCount: samples.count
            )
        }
        .sorted { weightedResultScore($0) > weightedResultScore($1) }
        .prefix(5)
        .map { $0 }
    }

    private func weightedScore(_ sample: SoundSample) -> Float {
        let confidence = max(0.15, Float(sample.soundConfidence))
        return sample.signal * confidence
    }

    private func weightedResultScore(_ result: CategoryDirectionResult) -> Float {
        result.signal * max(0.15, Float(result.confidence))
    }

    private func updateListenEvents(with sample: SoundSample) {
        guard selectedMode == .listen,
              sample.signal > minDetectedSignal,
              sample.soundConfidence >= 0.25,
              let category = sample.soundCategory else {
            return
        }

        let now = Date()
        if lastLoggedEventCategory == category,
           let previous = lastLoggedEventDate,
           now.timeIntervalSince(previous) < 5.0 {
            return
        }

        addSoundEvent(
            mode: .listen,
            category: category,
            label: category,
            confidence: sample.soundConfidence,
            heading: isLocationAuthorized ? sample.heading : nil,
            peakDecibels: sample.smoothedDecibels,
            averageDecibels: averageSmoothedDecibels(for: category),
            scanQuality: scanQualityText
        )

        lastLoggedEventCategory = category
        lastLoggedEventDate = now
    }

    private func logSummaryEvents() {
        for result in categoryDirectionResults.prefix(3) {
            addSoundEvent(
                mode: .scan360,
                category: result.category,
                label: result.label,
                confidence: result.confidence,
                heading: result.heading,
                peakDecibels: bestPeakDecibels(for: result.category),
                averageDecibels: averageSmoothedDecibels(for: result.category),
                scanQuality: scanQualityText
            )
        }
    }

    private func addSoundEvent(
        mode: DetectionMode,
        category: String,
        label: String,
        confidence: Double,
        heading: Double?,
        peakDecibels: Float,
        averageDecibels: Float,
        scanQuality: String
    ) {
        let event = SoundEvent(
            date: Date(),
            mode: mode,
            category: category,
            label: label,
            confidence: confidence,
            heading: heading,
            peakDecibels: peakDecibels,
            averageDecibels: averageDecibels,
            scanQuality: scanQuality
        )

        soundEvents.insert(event, at: 0)
        if soundEvents.count > 50 {
            soundEvents.removeLast(soundEvents.count - 50)
        }
    }

    private func evaluateThresholdAlert(with sample: SoundSample) {
        guard isThresholdAlertEnabled,
              sample.smoothedDecibels >= alertDecibelThreshold,
              sample.soundConfidence >= alertConfidenceThreshold,
              sample.signal > minDetectedSignal else {
            return
        }

        let category = sample.soundCategory ?? "Other"
        guard alertCategory == "Any" || alertCategory == category else { return }

        let now = Date()
        if lastThresholdAlertCategory == category,
           let previous = lastThresholdAlertDate,
           now.timeIntervalSince(previous) < 8.0 {
            return
        }

        lastThresholdAlertCategory = category
        lastThresholdAlertDate = now
        lastAlertMessage = "\(category) over \(Int(alertDecibelThreshold)) dB"

        switch alertStyle {
        case .none:
            break
        case .haptic:
            haptics.notificationOccurred(.warning)
        case .screenFlash:
            triggerScreenFlash()
        case .sound:
            AudioServicesPlayAlertSound(SystemSoundID(1057))
        }
    }

    private func triggerScreenFlash() {
        shouldFlashAlert = true
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.45) { [weak self] in
            self?.shouldFlashAlert = false
        }
    }

    func resetCalibrationOffset() {
        calibrationOffset = 0.0
    }

    static let alertCategories = [
        "Any",
        "Human voice",
        "Animals",
        "Vehicles",
        "Mechanical",
        "Alarm",
        "Music",
        "Nature",
        "Household",
        "Impact",
        "Other"
    ]

    func makeSessionReport() -> SessionReport {
        let text = makeTextReport()
        let csv = makeCSVReport()
        return SessionReport(text: text, csv: csv)
    }

    func writeSessionReportFiles() throws -> [URL] {
        let report = makeSessionReport()
        let directory = FileManager.default.temporaryDirectory
        let timestamp = DateFormatter.fileTimestamp.string(from: Date())
        let textURL = directory.appendingPathComponent("NoiseRadar-Report-\(timestamp).txt")
        let csvURL = directory.appendingPathComponent("NoiseRadar-Events-\(timestamp).csv")

        try report.text.write(to: textURL, atomically: true, encoding: .utf8)
        try report.csv.write(to: csvURL, atomically: true, encoding: .utf8)
        return [textURL, csvURL]
    }

    private func makeTextReport() -> String {
        var lines: [String] = []
        lines.append("NoiseRadar Session Report")
        lines.append("Generated: \(DateFormatter.reportDate.string(from: Date()))")
        lines.append("Device: \(UIDevice.current.model)")
        lines.append("App Version: \(Bundle.main.releaseVersion) (\(Bundle.main.buildVersion))")
        lines.append("Mode: \(selectedMode.title)")
        lines.append("Calibration Offset: \(String(format: "%.1f", calibrationOffset)) dB")
        lines.append("Noise Floor: \(Int(noiseFloorEMA)) dB")
        lines.append("Peak dB: \(Int(samples.map { $0.smoothedDecibels }.max() ?? lastSmoothedDecibels))")
        lines.append("Average dB: \(Int(averageAllSmoothedDecibels()))")
        if let heading = directionOfLoudestSound {
            lines.append("Loudest Direction: \(Int(heading)) degrees")
        }
        if !topHeadings.isEmpty {
            lines.append("Top Headings: \(topHeadings.map { "\(Int($0)) degrees" }.joined(separator: ", "))")
        }
        if !categoryDirectionResults.isEmpty {
            lines.append("")
            lines.append("Sound Type Directions:")
            for result in categoryDirectionResults {
                let confidence = Int((result.confidence * 100.0).rounded())
                lines.append("- \(result.category): \(Int(result.heading)) degrees, \(confidence)% confidence, \(Int(result.signal)) signal")
            }
        }
        if !soundEvents.isEmpty {
            lines.append("")
            lines.append("Recent Events:")
            for event in soundEvents.prefix(20) {
                let confidence = Int((event.confidence * 100.0).rounded())
                let heading = event.heading.map { "\(Int($0)) degrees" } ?? "No heading"
                lines.append("- \(DateFormatter.reportDate.string(from: event.date)): \(event.category), \(event.label), \(heading), \(confidence)%, peak \(Int(event.peakDecibels)) dB")
            }
        }
        lines.append("")
        lines.append("Disclaimer: NoiseRadar provides casual phone microphone estimates only. It is not a certified acoustic instrument, emergency system, security system, medical tool, or professional measurement device.")
        return lines.joined(separator: "\n")
    }

    private func makeCSVReport() -> String {
        var rows = ["date,mode,category,label,confidence,heading,peak_db,average_db,quality"]
        for event in soundEvents {
            rows.append([
                csvEscape(DateFormatter.reportDate.string(from: event.date)),
                csvEscape(event.mode.title),
                csvEscape(event.category),
                csvEscape(event.label),
                String(format: "%.2f", event.confidence),
                event.heading.map { String(format: "%.0f", $0) } ?? "",
                String(format: "%.0f", event.peakDecibels),
                String(format: "%.0f", event.averageDecibels),
                csvEscape(event.scanQuality)
            ].joined(separator: ","))
        }
        return rows.joined(separator: "\n")
    }

    private func csvEscape(_ value: String) -> String {
        let escaped = value.replacingOccurrences(of: "\"", with: "\"\"")
        return "\"\(escaped)\""
    }

    private func averageAllSmoothedDecibels() -> Float {
        guard !samples.isEmpty else { return lastSmoothedDecibels }
        let total = samples.reduce(Float(0.0)) { $0 + $1.smoothedDecibels }
        return total / Float(samples.count)
    }

    private func bestPeakDecibels(for category: String) -> Float {
        samples
            .filter { ($0.soundCategory ?? "Other") == category }
            .map { $0.smoothedDecibels }
            .max() ?? lastSmoothedDecibels
    }

    private func averageSmoothedDecibels(for category: String) -> Float {
        let values = samples
            .filter { ($0.soundCategory ?? "Other") == category }
            .map { $0.smoothedDecibels }

        guard !values.isEmpty else { return lastSmoothedDecibels }
        return values.reduce(0, +) / Float(values.count)
    }

    var readinessItems: [ReadinessItem] {
        [
            ReadinessItem(
                title: "Microphone",
                detail: isMicrophoneAuthorized ? "Allowed" : "Permission needed",
                isReady: isMicrophoneAuthorized
            ),
            ReadinessItem(
                title: "Compass",
                detail: isLocationAuthorized ? "Ready" : "Allow location for heading",
                isReady: isLocationAuthorized
            ),
            ReadinessItem(
                title: "Rotation",
                detail: currentRotationRate <= maxRotationRate ? "Slow enough" : "Turn slower",
                isReady: currentRotationRate <= maxRotationRate
            ),
            ReadinessItem(
                title: "Noise floor",
                detail: noiseFloorEMA <= noisyEnvironmentThreshold ? "Usable" : "Noisy environment",
                isReady: noiseFloorEMA <= noisyEnvironmentThreshold
            )
        ]
    }
}

extension Bundle {
    var releaseVersion: String {
        object(forInfoDictionaryKey: "CFBundleShortVersionString") as? String ?? "1.0"
    }

    var buildVersion: String {
        object(forInfoDictionaryKey: "CFBundleVersion") as? String ?? "1"
    }
}

private extension DateFormatter {
    static let reportDate: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .medium
        return formatter
    }()

    static let fileTimestamp: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyyMMdd-HHmmss"
        return formatter
    }()
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
