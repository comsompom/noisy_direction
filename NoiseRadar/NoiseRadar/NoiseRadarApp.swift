import SwiftUI

@main
struct NoiseRadarApp: App {
    @StateObject private var purchaseManager = PurchaseManager()
    @StateObject private var adMobManager = AdMobManager()
    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            SoundRadarView()
                .environmentObject(purchaseManager)
                .environmentObject(adMobManager)
                .onAppear {
                    if !purchaseManager.isAdFree {
                        adMobManager.requestTrackingAuthorizationAndStart()
                    }
                }
                .onChange(of: scenePhase) { phase in
                    if phase == .active && !purchaseManager.isAdFree {
                        adMobManager.requestTrackingAuthorizationAndStart()
                    }
                }
        }
    }
}
