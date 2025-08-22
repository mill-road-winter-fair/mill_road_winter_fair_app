import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
      if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
          GMSServices.provideAPIKey(apiKey as String)
      } else {
          print("Couldn't get IOS_GOOGLE_MAPS_SDK_API_KEY via GMSApiKey")
      }
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
