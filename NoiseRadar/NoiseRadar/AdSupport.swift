import SwiftUI
import UIKit
import GoogleMobileAds

enum AdMobSupport {
    static let applicationID = "ca-app-pub-2367013361044576~9236993009"
    private static let productionBannerAdUnitID = "ca-app-pub-2367013361044576/3564109908"
    private static let testBannerAdUnitID = "ca-app-pub-3940256099942544/2934735716"

    #if DEBUG
    static let bannerAdUnitID = testBannerAdUnitID
    #else
    static let bannerAdUnitID = productionBannerAdUnitID
    #endif

    static func configure() {
        MobileAds.shared.requestConfiguration.maxAdContentRating = GADMaxAdContentRating.general
        MobileAds.shared.start()
    }
}

struct BannerAdView: UIViewRepresentable {
    func makeUIView(context: Context) -> BannerView {
        let banner = BannerView(adSize: AdSizeBanner)
        banner.adUnitID = AdMobSupport.bannerAdUnitID
        banner.rootViewController = UIApplication.shared.topMostViewController
        banner.load(Request())
        return banner
    }

    func updateUIView(_ uiView: BannerView, context: Context) {
        uiView.rootViewController = UIApplication.shared.topMostViewController
    }
}

private extension UIApplication {
    var topMostViewController: UIViewController? {
        connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .flatMap(\.windows)
            .first { $0.isKeyWindow }?
            .rootViewController?
            .topMostPresentedViewController
    }
}

private extension UIViewController {
    var topMostPresentedViewController: UIViewController {
        if let presentedViewController {
            return presentedViewController.topMostPresentedViewController
        }
        if let navigationController = self as? UINavigationController,
           let visibleViewController = navigationController.visibleViewController {
            return visibleViewController.topMostPresentedViewController
        }
        if let tabBarController = self as? UITabBarController,
           let selectedViewController = tabBarController.selectedViewController {
            return selectedViewController.topMostPresentedViewController
        }
        return self
    }
}
