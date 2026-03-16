import UIKit
import Flutter
import GoogleMaps

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: 
        [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    GMSServices.provideAPIKey("AIzaSyBp-MnsQYAMi6FATU9Nhv6sfFV71Az4Ehc")
    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, 
        didFinishLaunchingWithOptions: launchOptions)
  }
}
