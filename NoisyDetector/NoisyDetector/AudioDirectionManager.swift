import AVFoundation
import Combine
import CoreLocation
import Foundation

final class AudioDirectionManager: NSObject, ObservableObject, CLLocationManagerDelegate {
    private struct SoundSample {
        let heading: Double
        let decibels: Float
    }

    private let rollingWindowSize = 10
    private let minDetectedDecibels: Float = -50.0

    private var audioRecorder: AVAudioRecorder?
    private var locationManager: CLLocationManager?
    private var timer: Timer?
    private var samples: [SoundSample] = []
    private var recentDecibels: [Float] = []
    private var isRecordingAuthorized = false
    private var isLocationAuthorized = false

    @Published var currentDecibels: Float = -160.0
    @Published var currentHeading: Double = 0.0
    @Published var isScanning = false
    @Published var directionOfLoudestSound: Double?
    @Published var statusText: String = "Ready"

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

    func startScanning() {
        guard isRecordingAuthorized else {
            statusText = "Enable microphone in Settings."
            return
        }

        samples.removeAll()
        recentDecibels.removeAll()
        directionOfLoudestSound = nil
        isScanning = true
        statusText = "Scanning... turn slowly 360°"

        audioRecorder?.record()
        timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { [weak self] _ in
            self?.captureSample()
        }
    }

    func stopScanning() {
        isScanning = false
        audioRecorder?.stop()
        timer?.invalidate()
        analyzeResults()
    }

    private func captureSample() {
        guard let recorder = audioRecorder else { return }
        recorder.updateMeters()

        let decibels = recorder.averagePower(forChannel: 0)
        let smoothedDecibels = rollingAverage(with: decibels)

        DispatchQueue.main.async {
            self.currentDecibels = smoothedDecibels
        }

        if isScanning {
            let sample = SoundSample(heading: currentHeading, decibels: smoothedDecibels)
            samples.append(sample)
        }
    }

    private func rollingAverage(with decibels: Float) -> Float {
        recentDecibels.append(decibels)
        if recentDecibels.count > rollingWindowSize {
            recentDecibels.removeFirst(recentDecibels.count - rollingWindowSize)
        }
        let total = recentDecibels.reduce(0, +)
        return total / Float(recentDecibels.count)
    }

    private func analyzeResults() {
        guard let maxSample = samples.max(by: { $0.decibels < $1.decibels }),
              maxSample.decibels > minDetectedDecibels else {
            statusText = "Sound too quiet. Try again."
            return
        }

        directionOfLoudestSound = maxSample.heading
        statusText = "Scan complete."
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
}
