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

            if let result = manager.directionOfLoudestSound {
                Text("Loudest sound at: \(Int(result))°")
                    .font(.title3)
                    .foregroundColor(.green)
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

                    Text("Tips")
                        .font(.headline)
                    Text("Do not cover the bottom microphone.")
                    Text("Use a real device for accurate compass readings.")

                    Divider()

                    Text("Developer: Oleg Bourdo � https://www.linkedin.com/in/oleg-bourdo-8a2360139/")
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
                        dismiss()
                    }
                }
            }
        }
    }
}





