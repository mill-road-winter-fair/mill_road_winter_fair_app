import Flutter
import UIKit
import GoogleMaps

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GeneratedPluginRegistrant.register(with: self)
    if let apiKey = Bundle.main.object(forInfoDictionaryKey: "GMSApiKey") as? String {
        GMSServices.provideAPIKey(apiKey as String)
        print("Got IOS_GOOGLE_MAPS_SDK_API_KEY"+apiKey)
    } else {
        print("Couldn't get IOS_GOOGLE_MAPS_SDK_API_KEY via GMSApiKey")
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
