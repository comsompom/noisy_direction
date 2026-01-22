import SwiftUI

struct SoundRadarView: View {
    @StateObject private var manager = AudioDirectionManager()

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
        }
        .padding()
    }
}

#Preview {
    SoundRadarView()
}
