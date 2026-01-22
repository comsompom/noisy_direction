import SwiftUI

struct SoundRadarView: View {
    @StateObject private var manager = AudioDirectionManager()
    @State private var showHelp = false

    var body: some View {
        VStack(spacing: 24) {
            Text("Noisy Detector")
                .font(.title)
                .bold()

            Text("Turn slowly 360° while scanning.")
                .foregroundColor(.secondary)

            ZStack {
                Circle()
                    .stroke(Color.gray.opacity(0.3), lineWidth: 10)
                    .frame(width: 280, height: 280)

                // Cardinal direction labels
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

                // Sound blob visualization
                SoundBlobShape(points: manager.polarPoints)
                    .fill(Color.green.opacity(0.2))
                    .frame(width: 260, height: 260)

                // Phone orientation marker
                VStack {
                    Image(systemName: "arrow.up")
                        .font(.largeTitle)
                        .foregroundColor(.red)
                    Spacer()
                }
                .frame(width: 280, height: 280)
                .rotationEffect(Angle(degrees: -manager.currentHeading))

                // Result marker after scan
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

                // Live volume visualizer
                Circle()
                    .fill(manager.isScanning ? Color.red : Color.blue)
                    .frame(width: manager.volumeCircleSize, height: manager.volumeCircleSize)
                    .opacity(0.5)
            }

            Text(manager.statusText)
                .font(.headline)

            ProgressView(value: manager.scanProgress)
                .tint(.green)

            if let result = manager.directionOfLoudestSound {
                Text("Loudest sound at: \(Int(result))°")
                    .font(.title3)
                    .foregroundColor(.green)
            }

            Text("Scan quality: \(manager.scanQualityText)")
                .font(.subheadline)
                .foregroundColor(scanQualityColor)

            VStack(spacing: 4) {
                Text("Raw: \(Int(manager.lastRawDecibels)) dB")
                Text("Smoothed: \(Int(manager.lastSmoothedDecibels)) dB")
            }
            .font(.caption)
            .foregroundColor(.secondary)

            if !manager.topHeadings.isEmpty {
                Text("Top 3 headings: \(topHeadingsText)")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }

            Text("Do not cover the bottom microphone.")
                .font(.footnote)
                .foregroundColor(.orange)

            Button(action: {
                if manager.isScanning {
                    manager.stopScanning()
                } else {
                    manager.startScanning()
                }
            }) {
                Text(manager.isScanning ? "Stop & Analyze" : "Start Scan")
                    .font(.headline)
                    .padding()
                    .frame(maxWidth: .infinity)
                    .background(manager.isScanning ? Color.red : Color.blue)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
            .padding(.horizontal)

            Button("Help") {
                showHelp = true
            }
            .font(.subheadline)
        }
        .padding()
        .sheet(isPresented: $showHelp) {
            HelpView()
        }
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

                    Text("Tips")
                        .font(.headline)
                    Text("Do not cover the bottom microphone.")
                    Text("Use a real device for accurate compass readings.")

                    Divider()

                    Text("Developer: Oleg Bourdo — https://www.linkedin.com/in/oleg-bourdo-8a2360139/")
                        .font(.footnote)
                        .foregroundColor(.secondary)

                    Text("This project was created to support the Moon Home Agency initiative: https://moonhome.agency/")
                        .font(.footnote)
                        .foregroundColor(.secondary)
                }
                .padding()
            }
            .navigationTitle("Help")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") {
                        // Dismissed by system
                    }
                }
            }
        }
    }
}
