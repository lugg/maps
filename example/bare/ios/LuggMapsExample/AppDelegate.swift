import UIKit
import GoogleMaps

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
  func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil
  ) -> Bool {
    if let apiKey = RNCConfig.env(for: "GOOGLE_MAPS_API_KEY") {
      GMSServices.provideAPIKey(apiKey)
    }

    return true
  }
}
