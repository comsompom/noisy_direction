import SwiftUI
import StoreKit

struct SoundRadarView: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var adMobManager: AdMobManager
    @StateObject private var manager = AudioDirectionManager()
    @State private var showHelp = false
    @State private var showHistory = false
    @State private var showSettings = false
    @State private var showShareSheet = false
    @State private var showRemoveAds = false
    @State private var shareItems: [Any] = []
    @State private var showOnboarding = false
    @AppStorage("hasSeenOnboarding") private var hasSeenOnboarding = false
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"

    var body: some View {
        ZStack {
            AdSupportedScreen {
                ScrollView {
                    VStack(spacing: 20) {
                        header
                        modePicker
                        radar
                        statusPanel
                        alertPanel
                        categoryResults
                        readinessPanel
                        removeAdsPrompt
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
        .sheet(isPresented: $showRemoveAds) {
            RemoveAdsView()
        }
        .sheet(isPresented: $showOnboarding) {
            OnboardingView {
                hasSeenOnboarding = true
                showOnboarding = false
            }
        }
        .onAppear {
            presentOnboardingIfNeeded()
        }
        .onChange(of: adMobManager.isReady) { _ in
            presentOnboardingIfNeeded()
        }
        .onChange(of: purchaseManager.isAdFree) { _ in
            presentOnboardingIfNeeded()
        }
    }

    private var canPresentOnboarding: Bool {
        purchaseManager.isAdFree || adMobManager.isReady
    }

    private func presentOnboardingIfNeeded() {
        if !hasSeenOnboarding && canPresentOnboarding {
            showOnboarding = true
        }
    }

    private var header: some View {
        VStack(spacing: 6) {
            Text("NoiseRadar")
                .font(.title)
                .bold()

            Text(t(manager.selectedMode == .scan360 ? "Turn slowly 360° while scanning." : "Keep the iPhone still and let it listen."))
                .font(.subheadline)
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
    }

    private var modePicker: some View {
        Picker(t("Mode"), selection: $manager.selectedMode) {
            ForEach(AudioDirectionManager.DetectionMode.allCases) { mode in
                Text(LanguagePack.modeTitle(mode, languageCode: languageCode)).tag(mode)
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
            Text(t(manager.statusText))
                .font(.headline)
                .multilineTextAlignment(.center)

            if manager.selectedMode == .scan360 {
                ProgressView(value: manager.scanProgress)
                    .tint(.green)
            }

            if let result = manager.directionOfLoudestSound {
                Text("\(t("Loudest sound at")): \(Int(result))°")
                    .font(.title3)
                    .foregroundColor(.green)
            }

            Text("\(t("Quality")): \(t(manager.scanQualityText))")
                .font(.subheadline)
                .foregroundColor(scanQualityColor)

            Text(LanguagePack.soundStatus(manager.soundClassificationStatus, languageCode: languageCode))
                .font(.subheadline)
                .multilineTextAlignment(.center)

            if !manager.topSoundClassifications.isEmpty {
                Text("\(t("Top sounds")): \(topSoundsText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("\(t("Raw")) \(Int(manager.lastRawDecibels)) dB · \(t("Smoothed")) \(Int(manager.lastSmoothedDecibels)) dB")
                .font(.caption)
                .foregroundColor(.secondary)

            if !manager.topHeadings.isEmpty {
                Text("\(t("Top headings")): \(topHeadingsText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
    }

    private var alertPanel: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Text(t("Threshold Alerts"))
                    .font(.headline)
                Spacer()
                Text(t(manager.isThresholdAlertEnabled ? "On" : "Off"))
                    .font(.caption)
                    .foregroundColor(manager.isThresholdAlertEnabled ? .green : .secondary)
            }

            Text(alertMessageText)
                .font(.caption)
                .foregroundColor(.secondary)

            if manager.isThresholdAlertEnabled {
                Text("\(categoryText(manager.alertCategory)) · \(Int(manager.alertDecibelThreshold)) dB · \(Int((manager.alertConfidenceThreshold * 100.0).rounded()))% · \(LanguagePack.alertStyleTitle(manager.alertStyle, languageCode: languageCode))")
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
            Text(t("Directions by Sound Type"))
                .font(.headline)

            if manager.categoryDirectionResults.isEmpty {
                Text(t("No categorized direction yet."))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else {
                ForEach(manager.categoryDirectionResults) { result in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(categoryText(result.category))
                                .font(.subheadline)
                                .bold()
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
            Text(t("Readiness"))
                .font(.headline)

            ForEach(manager.readinessItems) { item in
                HStack {
                    Image(systemName: item.isReady ? "checkmark.circle.fill" : "exclamationmark.triangle.fill")
                        .foregroundColor(item.isReady ? .green : .orange)
                    VStack(alignment: .leading, spacing: 1) {
                        Text(t(item.title))
                            .font(.subheadline)
                        Text(t(item.detail))
                            .font(.caption)
                            .foregroundColor(.secondary)
                    }
                    Spacer()
                }
            }

            Text(t("Do not cover the bottom microphone."))
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
                Button(t("History")) {
                    showHistory = true
                }
                .font(.subheadline)

                Spacer()

                Button(t("Settings")) {
                    showSettings = true
                }
                .font(.subheadline)

                Spacer()

                Button(t("Share")) {
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

                Button(t("Help")) {
                    showHelp = true
                }
                .font(.subheadline)
            }
        }
    }

    private var removeAdsPrompt: some View {
        RemoveAdsPrompt {
            showRemoveAds = true
        }
    }

    private var primaryButtonTitle: String {
        if manager.isScanning {
            return manager.selectedMode == .scan360 ? t("Stop & Analyze") : t("Stop Listening")
        }
        return manager.selectedMode == .scan360 ? t("Start Scan") : t("Start Listening")
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
                return "\(categoryText(classification.category)) \(confidence)%"
            }
            .joined(separator: ", ")
    }

    private var alertMessageText: String {
        if manager.lastAlertMessage == "Alerts ready" {
            return t("Alerts ready")
        }

        if let range = manager.lastAlertMessage.range(of: " over ") {
            let category = String(manager.lastAlertMessage[..<range.lowerBound])
            let suffix = String(manager.lastAlertMessage[range.upperBound...])
            return "\(categoryText(category)) \(t("over")) \(suffix)"
        }

        return t(manager.lastAlertMessage)
    }

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
    }

    private func categoryText(_ category: String) -> String {
        LanguagePack.category(category, languageCode: languageCode)
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

private struct AdSupportedScreen<Content: View>: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @EnvironmentObject private var adMobManager: AdMobManager
    @ViewBuilder let content: Content

    var body: some View {
        VStack(spacing: 0) {
            if !purchaseManager.isAdFree && adMobManager.isReady {
                BannerAdView()
                    .frame(width: 320, height: 50)
                    .padding(.top, 8)
                    .padding(.bottom, 6)
            }

            content
        }
    }
}

private struct RemoveAdsPrompt: View {
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"
    let onTap: () -> Void

    var body: some View {
        if !purchaseManager.isAdFree {
            Button(action: onTap) {
                HStack(spacing: 10) {
                    Image(systemName: "xmark.circle")
                        .font(.title3)

                    Text(t("Remove banner ads."))
                        .font(.subheadline)

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                .padding(10)
                .frame(maxWidth: .infinity)
                .background(Color.secondary.opacity(0.08))
                .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
    }

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
    }
}

#if DEBUG
#Preview {
    SoundRadarView()
        .environmentObject(PurchaseManager())
        .environmentObject(AdMobManager())
}
#endif

private struct HelpView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"

    var body: some View {
        AdSupportedScreen {
            NavigationView {
                ScrollView {
                    VStack(alignment: .leading, spacing: 16) {
                        Text(t("Quick Help"))
                            .font(.title2)
                            .bold()

                        Text(t("1. Hold the phone upright."))
                        Text(t("2. Tap Start Scan."))
                        Text(t("3. Slowly rotate 360°."))
                        Text(t("4. Tap Stop & Analyze."))
                        Text(t("5. The green arrow points to the loudest direction."))
                        Text(t("6. Sound type labels run offline on device."))

                        Text(t("Tips"))
                            .font(.headline)
                        Text(t("Do not cover the bottom microphone."))
                        Text(t("Use a real device for accurate compass readings."))
                        Text(t("Sound labels are best-effort categories and may be wrong in noisy rooms."))

                        Divider()

                        Text("\(t("Version")) \(Bundle.main.releaseVersion) (\(Bundle.main.buildVersion))")
                            .font(.footnote)
                            .foregroundColor(.secondary)

                        Text("\(t("Website")): https://www.vozhyk.com/")
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }
                    .padding()
                }
                .navigationTitle(t("Help"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(t("Done")) {
                            dismiss()
                        }
                    }
                }
            }
        }
    }

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
    }
}

private struct HistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"
    let events: [AudioDirectionManager.SoundEvent]

    var body: some View {
        AdSupportedScreen {
            NavigationView {
                Group {
                    if events.isEmpty {
                        VStack(spacing: 8) {
                            Text(t("No history yet"))
                                .font(.headline)
                            Text(t("Scan or listen to create local sound events."))
                                .font(.subheadline)
                                .foregroundColor(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .padding()
                    } else {
                        List(events) { event in
                            VStack(alignment: .leading, spacing: 6) {
                                HStack {
                                    Text(categoryText(event.category))
                                        .font(.headline)
                                    Spacer()
                                    Text(LanguagePack.modeTitle(event.mode, languageCode: languageCode))
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }

                                Text(historyDetail(for: event))
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                            .padding(.vertical, 4)
                        }
                    }
                }
                .navigationTitle(t("History"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(t("Done")) {
                            dismiss()
                        }
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
            headingText = t("No heading")
        }

        return "\(DateFormatter.shortTime.string(from: event.date)) · \(headingText) · \(confidence)% · \(t("peak")) \(Int(event.peakDecibels)) dB · \(t("avg")) \(Int(event.averageDecibels)) dB"
    }

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
    }

    private func categoryText(_ category: String) -> String {
        LanguagePack.category(category, languageCode: languageCode)
    }

}

private struct SettingsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"
    @State private var showLanguageSelection = false
    @State private var showRemoveAds = false
    @ObservedObject var manager: AudioDirectionManager

    var body: some View {
        AdSupportedScreen {
            NavigationView {
                Form {
                    Section(t("Language")) {
                        Button {
                            showLanguageSelection = true
                        } label: {
                            HStack {
                                Text(t("Language"))
                                    .foregroundColor(.primary)
                                Spacer()
                                if let selectedLanguage {
                                    HStack(spacing: 6) {
                                        LanguageFlagView(language: selectedLanguage)
                                        Text(selectedLanguage.name)
                                    }
                                    .foregroundColor(.secondary)
                                }
                                Image(systemName: "chevron.right")
                                    .font(.caption)
                                    .foregroundColor(.secondary)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    Section(t("Ad-Free")) {
                        if purchaseManager.isAdFree {
                            Label(t("Ads removed"), systemImage: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        } else {
                            Button {
                                showRemoveAds = true
                            } label: {
                                HStack {
                                    Text(removeAdsTitle)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                }
                            }

                            Button(t("Restore Purchases")) {
                                Task {
                                    await purchaseManager.restorePurchases()
                                }
                            }
                        }

                        if !purchaseManager.purchaseStatusMessage.isEmpty {
                            Text(t(purchaseManager.purchaseStatusMessage))
                                .font(.footnote)
                                .foregroundColor(.secondary)
                        }
                    }

                    Section(t("Threshold Alerts")) {
                        Toggle(t("Enable Alerts"), isOn: $manager.isThresholdAlertEnabled)

                        Picker(t("Sound Type"), selection: $manager.alertCategory) {
                            ForEach(AudioDirectionManager.alertCategories, id: \.self) { category in
                                Text(LanguagePack.category(category, languageCode: languageCode)).tag(category)
                            }
                        }

                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(t("dB Threshold")): \(Int(manager.alertDecibelThreshold)) dB")
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
                            Text("\(t("Confidence")): \(Int((manager.alertConfidenceThreshold * 100.0).rounded()))%")
                            Slider(value: $manager.alertConfidenceThreshold, in: 0.15...0.95, step: 0.05)
                        }

                        Picker(t("Alert Style"), selection: $manager.alertStyle) {
                            ForEach(AudioDirectionManager.AlertStyle.allCases) { style in
                                Text(LanguagePack.alertStyleTitle(style, languageCode: languageCode)).tag(style)
                            }
                        }
                    }

                    Section(t("Calibration")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("\(t("Manual Offset")): \(String(format: "%.1f", manager.calibrationOffset)) dB")
                            Slider(
                                value: Binding(
                                    get: { Double(manager.calibrationOffset) },
                                    set: { manager.calibrationOffset = Float($0) }
                                ),
                                in: -20...20,
                                step: 0.5
                            )
                        }

                        Button(t("Reset Calibration")) {
                            manager.resetCalibrationOffset()
                        }

                        Text(t("Use a quiet room or a known reference meter. NoiseRadar results are phone microphone estimates, not certified measurements."))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Section(t("Reports")) {
                        Text(t("The Share button exports a text summary and CSV event log for the current local session."))
                            .font(.footnote)
                            .foregroundColor(.secondary)
                    }

                    Section(t("About")) {
                        HStack {
                            Text(t("Version"))
                            Spacer()
                            Text("\(Bundle.main.releaseVersion) (\(Bundle.main.buildVersion))")
                                .foregroundColor(.secondary)
                        }
                    }
                }
                .navigationTitle(t("Settings"))
                .toolbar {
                    ToolbarItem(placement: .cancellationAction) {
                        Button(t("Done")) {
                            dismiss()
                        }
                    }
                }
            }
        }
        .sheet(isPresented: $showLanguageSelection) {
            LanguageSelectionView()
        }
        .sheet(isPresented: $showRemoveAds) {
            RemoveAdsView()
        }
    }

    private var selectedLanguage: AppLanguage? {
        LanguagePack.supportedLanguages.first { $0.code == languageCode }
    }

    private var removeAdsTitle: String {
        if let product = purchaseManager.removeAdsProduct {
            return "\(t("Remove Ads")) - \(product.displayPrice)"
        }
        return "\(t("Remove Ads")) - \(PurchaseManager.removeAdsFallbackPrice)"
    }

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
    }
}

private struct RemoveAdsView: View {
    @Environment(\.dismiss) private var dismiss
    @EnvironmentObject private var purchaseManager: PurchaseManager
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: 18) {
                VStack(alignment: .leading, spacing: 8) {
                    Text(t("Remove Ads"))
                        .font(.title2)
                        .bold()

                    Text(t("Remove banner ads from NoiseRadar forever with a one-time purchase."))
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                if purchaseManager.isAdFree {
                    Label(t("Ads removed"), systemImage: "checkmark.circle.fill")
                        .font(.headline)
                        .foregroundColor(.green)
                } else {
                    Button {
                        Task {
                            await purchaseManager.purchaseRemoveAds()
                        }
                    } label: {
                        HStack {
                            Text(removeAdsTitle)
                            Spacer()
                            if purchaseManager.isPurchasing {
                                ProgressView()
                            }
                        }
                        .font(.headline)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(Color.blue)
                        .foregroundColor(.white)
                        .cornerRadius(10)
                    }
                    .disabled(purchaseManager.isPurchasing || purchaseManager.isLoadingProducts)

                    Button(t("Restore Purchases")) {
                        Task {
                            await purchaseManager.restorePurchases()
                        }
                    }
                    .font(.subheadline)
                }

                if !purchaseManager.purchaseStatusMessage.isEmpty {
                    Text(t(purchaseManager.purchaseStatusMessage))
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }

                Spacer()
            }
            .padding()
            .navigationTitle(t("Ad-Free"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private var removeAdsTitle: String {
        if let product = purchaseManager.removeAdsProduct {
            return "\(t("Remove Ads")) - \(product.displayPrice)"
        }
        return "\(t("Remove Ads")) - \(PurchaseManager.removeAdsFallbackPrice)"
    }

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
    }
}

private struct LanguageSelectionView: View {
    @Environment(\.dismiss) private var dismiss
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"

    var body: some View {
        NavigationView {
            List(LanguagePack.supportedLanguages) { language in
                Button {
                    languageCode = language.code
                    dismiss()
                } label: {
                    HStack(spacing: 12) {
                        LanguageFlagView(language: language)

                        Text(language.name)
                            .foregroundColor(.primary)

                        Spacer()

                        if languageCode == language.code {
                            Image(systemName: "checkmark.circle.fill")
                                .foregroundColor(.green)
                        }
                    }
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
            }
            .navigationTitle(t("Language"))
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(t("Done")) {
                        dismiss()
                    }
                }
            }
        }
    }

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
    }
}

private struct LanguageFlagView: View {
    let language: AppLanguage

    var body: some View {
        Group {
            if language.code == "be" {
                WhiteRedWhiteFlag()
                    .frame(width: 34, height: 22)
            } else {
                Text(language.flag)
                    .font(.title2)
            }
        }
        .frame(width: 42, height: 28)
        .accessibilityHidden(true)
    }
}

private struct WhiteRedWhiteFlag: View {
    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 3)
                .fill(Color.white)

            VStack(spacing: 0) {
                Color.white
                Color(red: 0.72, green: 0.0, blue: 0.0)
                Color.white
            }

            RoundedRectangle(cornerRadius: 3)
                .stroke(Color.secondary.opacity(0.35), lineWidth: 1)
        }
        .clipShape(RoundedRectangle(cornerRadius: 3))
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
    @AppStorage(LanguagePack.storageKey) private var languageCode = "en"
    let onDone: () -> Void

    var body: some View {
        AdSupportedScreen {
            VStack(spacing: 24) {
                Spacer()

                Text("NoiseRadar")
                    .font(.largeTitle)
                    .bold()

                VStack(alignment: .leading, spacing: 18) {
                    OnboardingRow(icon: "iphone", title: t("Hold upright"), detail: t("Keep the bottom microphone uncovered."))
                    OnboardingRow(icon: "timer", title: t("Calibrate first"), detail: t("Stay still while the app learns the room noise."))
                    OnboardingRow(icon: "arrow.triangle.2.circlepath", title: t("Turn slowly"), detail: t("Use Scan 360 for direction or Listen mode for ongoing sound events."))
                }

                Spacer()

                Button(t("Start")) {
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

    private func t(_ key: String) -> String {
        LanguagePack.text(key, languageCode: languageCode)
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
