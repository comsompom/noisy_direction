import SwiftUI

struct SoundRadarView: View {
    @StateObject private var manager = AudioDirectionManager()
    @State private var showHelp = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showShareSheet = false
    @State private var shareItems: [Any] = []
    @State private var showOnboarding = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false

    var body: some View {
        ZStack {
            VStack(spacing: 0) {
                BannerAdView()
                    .frame(width: 320, height: 50)
                    .padding(.top, 8)
                    .padding(.bottom, 6)

                ScrollView {
                    VStack(spacing: 20) {
                        header
                        modePicker
                        radar
                        statusPanel
                        alertPanel
                        categoryResults
                        readinessPanel
                        actionButtons
                    }
                    .padding()
                    .frame(maxWidth: .infinity)
                }
            }

            if manager.shouldFlashAlert {
                Color.yellow
                    .opacity(0.45)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
        .sheet(isPresented: $showHistory) {
            HistoryView(events: manager.soundEvents)
        }
        .sheet(isPresented: $showSettings) {
            SettingsView(manager: manager)
        }
        .sheet(isPresented: $showShareSheet) {
            ShareSheet(items: shareItems)
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .onAppear {
            if !hasSeenOnboarding {
                showOnboarding = true
            }
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("NoiseRadar")
                .font(.title)
                .bold()

            Text(manager.selectedMode == .scan360 ? "Turn slowly 360° while scanning." : "Keep the iPhone still and let it listen.")
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var modePicker: some View {
        Picker("Mode", selection: $manager.selectedMode) {
            ForEach(AudioDirectionManager.DetectionMode.allCases) { mode in
                Text(mode.title).tag(mode)
            }
        }
        .pickerStyle(.segmented)
        .disabled(manager.isScanning)
    }

    private var radar: some View {
        ZStack {
            Circle()
                .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                .frame(width: 280, height: 280)

            Text("N")
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(y: -140)
            Text("E")
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(x: 140)
            Text("S")
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(y: 140)
            Text("W")
                .font(.caption)
                .foregroundColor(.secondary)
                .offset(x: -140)

            SoundBlobShape(points: manager.polarPoints)
                .fill(Color.green.opacity(0.2))
                .frame(width: 260, height: 260)

            VStack {
                Image(systemName: "arrow.up")
                    .font(.largeTitle)
                    .foregroundColor(.red)
                Spacer()
            }
            .frame(width: 280, height: 280)
            .rotationEffect(Angle(degrees: -manager.currentHeading))

            if let targetHeading = manager.directionOfLoudestSound {
                VStack {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 40))
                        .foregroundColor(.green)
                    Spacer()
                }
                .frame(width: 260, height: 260)
                .rotationEffect(Angle(degrees: targetHeading - manager.currentHeading))
            }

            Circle()
                .fill(manager.isScanning ? Color.red : Color.blue)
                .frame(width: manager.volumeCircleSize, height: manager.volumeCircleSize)
                .opacity(0.5)
        }
    }

    private var statusPanel: some View {
        VStack(spacing: 8) {
            Text(manager.statusText)
                .font(.headline)
                .multilineTextAlignment(.center)

            if manager.selectedMode == .scan360 {
                ProgressView(value: manager.scanProgress)
                    .tint(.green)
            }

            if let result = manager.directionOfLoudestSound {
                Text("Loudest sound at: \(Int(result))°")
                    .font(.title3)
                    .foregroundColor(.green)
            }

            Text("Quality: \(manager.scanQualityText)")
                .font(.subheadline)
                .foregroundColor(scanQualityColor)

            Text(manager.soundClassificationStatus)
                .font(.subheadline)
                .multilineTextAlignment(.center)

            if !manager.topSoundClassifications.isEmpty {
                Text("Top sounds: \(topSoundsText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Raw \(Int(manager.lastRawDecibels)) dB · Smoothed \(Int(manager.lastSmoothedDecibels)) dB")
                .font(.caption)
                .foregroundColor(.secondary)

            if !manager.topHeadings.isEmpty {
                Text("Top headings: \(topHeadingsText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var alertPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text("Threshold Alerts")
                    .font(.headline)
                Spacer()
                Text(manager.isThresholdAlertEnabled ? "On" : "Off")
                    .font(.caption)
                    .foregroundColor(manager.isThresholdAlertEnabled ? .green : .secondary)
            }

            Text(manager.lastAlertMessage)
                .font(.caption)
                .foregroundColor(.secondary)

            if manager.isThresholdAlertEnabled {
                Text("\(manager.alertCategory) · \(Int(manager.alertDecibelThreshold)) dB · \(Int((manager.alertConfidenceThreshold * 100.0).rounded()))% · \(manager.alertStyle.title)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding(10)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.secondary.opacity(0.08))
        .cornerRadius(8)
    }

    private var categoryResults: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Directions by Sound Type")
                .font(.headline)

            if manager.categoryDirectionResults.isEmpty {
                Text("No categorized direction yet.")
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(manager.categoryDirectionResults) { result in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(result.category)
                                .font(.subheadline)
                                .bold()
                            Text(result.label)
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }

                        Spacer()

                        Text("\(Int(result.heading))°")
                            .font(.headline)

                        Text("\(Int((result.confidence * 100.0).rounded()))%")
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    .padding(10)
                    .background(Color.secondary.opacity(0.08))
                    .cornerRadius(8)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var readinessPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Readiness")
                .font(.headline)

            ForEach(manager.readinessItems) { item in
                HStack {
                    Image(systemName: item.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(item.isReady ? .green : .orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(item.title)
                            .font(.subheadline)
                        Text(item.detail)
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }

            Text("Do not cover the bottom microphone.")
                .font(.footnote)
                .foregroundColor(.orange)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            Button(action: {
                if manager.isScanning {
                    manager.stopScanning()
                } else {
                    manager.startSelectedMode()
                }
            }) {
                Text(primaryButtonTitle)
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(manager.isScanning ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }

            HStack {
                Button("History") {
                    showHistory = true
                }
                .font(.subheadline)

                Spacer()

                Button("Settings") {
                    showSettings = true
                }
                .font(.subheadline)

                Spacer()

                Button("Share") {
                    do {
                        shareItems = try manager.writeSessionReportFiles()
                    } catch {
                        let report = manager.makeSessionReport()
                        shareItems = [report.text, report.csv]
                    }
                    showShareSheet = true
                }
                .font(.subheadline)

                Spacer()

                Button("Help") {
                    showHelp = true
                }
                .font(.subheadline)
            }
        }
    }

    private var primaryButtonTitle: String {
        if manager.isScanning {
            return manager.selectedMode == .scan360 ? "Stop & Analyze" : "Stop Listening"
        }
        return manager.selectedMode == .scan360 ? "Start Scan" : "Start Listening"
    }

    private var scanQualityColor: Color {
        switch manager.scanQualityLevel {
        case .normal:
            return .green
        case .warning:
            return .orange
        case .bad:
            return .red
        }
    }

    private var topHeadingsText: String {
        manager.topHeadings
            .map { "\(Int($0))°" }
            .joined(separator: ", ")
    }

    private var topSoundsText: String {
        manager.topSoundClassifications
            .map { classification in
                let confidence = Int((classification.confidence * 100.0).rounded())
                return "\(classification.category) \(confidence)%"
            }
            .joined(separator: ", ")
    }
}

private struct SoundBlobShape: Shape {
    let points: [AudioDirectionManager.PolarPoint]

    func path(in rect: CGRect) -> Path {
        guard points.count > 2 else { return Path() }
        let center = CGPoint(x: rect.midX, y: rect.midY)
        let maxRadius = min(rect.width, rect.height) / 2.0
        let maxMagnitude = points.map { $0.magnitude }.max() ?? 0.0
        if maxMagnitude <= 0 {
            return Path()
        }

        let sortedPoints = points.sorted { $0.heading < $1.heading }
        var path = Path()
        for (index, point) in sortedPoints.enumerated() {
            let normalized = CGFloat(point.magnitude / maxMagnitude)
            let radius = maxRadius * normalized
            let angle = Angle(degrees: point.heading - 90.0).radians
            let x = center.x + cos(angle) * radius
            let y = center.y + sin(angle) * radius
            if index == 0 {
                path.move(to: CGPoint(x: x, y: y))
            } else {
                path.addLine(to: CGPoint(x: x, y: y))
            }
        }
        path.closeSubpath()
        return path
    }
}

#if DEBUG
#Preview {
    SoundRadarView()
}
#endif

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationView {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    Text("Quick Help")
                        .font(.title2)
                        .bold()

                    Text("1. Hold the phone upright.")
                    Text("2. Tap Start Scan.")
                    Text("3. Slowly rotate 360°.")
                    Text("4. Tap Stop & Analyze.")
                    Text("5. The green arrow points to the loudest direction.")
                    Text("6. Sound type labels run offline on device.")

                    Text("Tips")
                        .font(.headline)
                    Text("Do not cover the bottom microphone.")
                    Text("Use a real device for accurate compass readings.")
                    Text("Sound labels are best-effort categories and may be wrong in noisy rooms.")

                    Divider()

                    Text("Version \(Bundle.main.releaseVersion) (\(Bundle.main.buildVersion))")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("Website: https://www.vozhyk.com/")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    let events: [AudioDirectionManager.SoundEvent]

    var body: some View {
        NavigationView {
            Group {
                if events.isEmpty {
                    VStack(spacing: 8) {
                        Text("No history yet")
                            .font(.headline)
                        Text("Scan or listen to create local sound events.")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .padding()
                } else {
                    List(events) { event in
                        VStack(alignment: .leading, spacing: 6) {
                            HStack {
                                Text(event.category)
                                    .font(.headline)
                                Spacer()
                                Text(event.mode.title)
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }

                            Text(event.label)
                                .font(.subheadline)

                            Text(historyDetail(for: event))
                                .font(.caption)
                                .foregroundColor(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
            .navigationTitle("History")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func historyDetail(for event: AudioDirectionManager.SoundEvent) -> String {
        let confidence = Int((event.confidence * 100.0).rounded())
        let headingText: String
        if let heading = event.heading {
            headingText = "\(Int(heading))°"
        } else {
            headingText = "No heading"
        }

        return "\(DateFormatter.shortTime.string(from: event.date)) · \(headingText) · \(confidence)% · peak \(Int(event.peakDecibels)) dB · avg \(Int(event.averageDecibels)) dB"
    }
}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @ObservedObject var manager: AudioDirectionManager

    var body: some View {
        NavigationView {
            Form {
                Section("Threshold Alerts") {
                    Toggle("Enable Alerts", isOn: $manager.isThresholdAlertEnabled)

                    Picker("Sound Type", selection: $manager.alertCategory) {
                        ForEach(AudioDirectionManager.alertCategories, id: \.self) { category in
                            Text(category).tag(category)
                        }
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("dB Threshold: \(Int(manager.alertDecibelThreshold)) dB")
                        Slider(
                            value: Binding(
                                get: { Double(manager.alertDecibelThreshold) },
                                set: { manager.alertDecibelThreshold = Float($0) }
                            ),
                            in: -70...0,
                            step: 1
                        )
                    }

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Confidence: \(Int((manager.alertConfidenceThreshold * 100.0).rounded()))%")
                        Slider(value: $manager.alertConfidenceThreshold, in: 0.15...0.95, step: 0.05)
                    }

                    Picker("Alert Style", selection: $manager.alertStyle) {
                        ForEach(AudioDirectionManager.AlertStyle.allCases) { style in
                            Text(style.title).tag(style)
                        }
                    }
                }

                Section("Calibration") {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Manual Offset: \(String(format: "%.1f", manager.calibrationOffset)) dB")
                        Slider(
                            value: Binding(
                                get: { Double(manager.calibrationOffset) },
                                set: { manager.calibrationOffset = Float($0) }
                            ),
                            in: -20...20,
                            step: 0.5
                        )
                    }

                    Button("Reset Calibration") {
                        manager.resetCalibrationOffset()
                    }

                    Text("Use a quiet room or a known reference meter. NoiseRadar results are phone microphone estimates, not certified measurements.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("Reports") {
                    Text("The Share button exports a text summary and CSV event log for the current local session.")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("\(Bundle.main.releaseVersion) (\(Bundle.main.buildVersion))")
                            .foregroundColor(.secondary)
                    }
                }
            }
            .navigationTitle("Settings")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

private struct OnboardingView: View {
    let onDone: () -> Void

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            Text("NoiseRadar")
                .font(.largeTitle)
                .bold()

            VStack(alignment: .leading, spacing: 18) {
                OnboardingRow(icon: "iphone", title: "Hold upright", detail: "Keep the bottom microphone uncovered.")
                OnboardingRow(icon: "timer", title: "Calibrate first", detail: "Stay still while the app learns the room noise.")
                OnboardingRow(icon: "arrow.triangle.2.circlepath", title: "Turn slowly", detail: "Use Scan 360 for direction or Listen mode for ongoing sound events.")
            }

            Spacer()

            Button("Start") {
                onDone()
            }
            .font(.headline)
            .padding()
            .frame(maxWidth: .infinity)
            .background(Color.blue)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
        .padding()
    }
}

private struct OnboardingRow: View {
    let icon: String
    let title: String
    let detail: String

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundColor(.green)
                .frame(width: 32)

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.headline)
                Text(detail)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            }
        }
    }
}

private extension DateFormatter {
    static let shortTime: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .none
        formatter.timeStyle = .short
        return formatter
    }()
}
