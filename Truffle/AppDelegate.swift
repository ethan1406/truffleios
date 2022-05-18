/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Application's delegate.
*/

import ARKit
import Bugsnag
import FirebaseCore
import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {
	var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]? = nil) -> Bool {
        configureGoogleAnalytics()
        configureBugsnag()

        guard ARWorldTrackingConfiguration.isSupported else {
            fatalError("""
                ARKit is not available on this device. For apps that require ARKit
                for core functionality, use the `arkit` key in the key in the
                `UIRequiredDeviceCapabilities` section of the Info.plist to prevent
                the app from installing. (If the app can't be installed, this error
                can't be triggered in a production scenario.)
                In apps where AR is an additive feature, use `isSupported` to
                determine whether to show UI for launching AR experiences.
            """) // For details, see https://developer.apple.com/documentation/arkit
        }

        return true
    }


    private func configureBugsnag() {
        Bugsnag.start()
    }

    private func configureGoogleAnalytics() {
        FirebaseApp.configure()
    }
}
