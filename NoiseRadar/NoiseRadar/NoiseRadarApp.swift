import SwiftUI

@main
struct NoiseRadarApp: App {
    init() {
        AdMobSupport.configure()
    }

    var body: some Scene {
        WindowGroup {
            SoundRadarView()
        }
    }
}
