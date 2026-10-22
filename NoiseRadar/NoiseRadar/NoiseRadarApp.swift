import SwiftUI

@main
struct NoiseRadarApp: App {
    @StateObject private var purchaseManager = PurchaseManager()

    init() {
        AdMobSupport.configure()
    }

    var body: some Scene {
        WindowGroup {
            SoundRadarView()
                .environmentObject(purchaseManager)
        }
    }
}
