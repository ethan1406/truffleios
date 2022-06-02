/*
See LICENSE folder for this sample’s licensing information.

Abstract:
Application's delegate.
*/

import ARKit
import Bugsnag
import FirebaseCore
import UIKit


let hasOnboardedKey = "hasOnboarded"

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


        let hasOnboarded = UserDefaults.standard.bool(forKey: hasOnboardedKey)

        if !hasOnboarded {
            self.window = UIWindow(frame: UIScreen.main.bounds)
            let storyboard = UIStoryboard(name: "Main", bundle: nil)

            let initialViewController = storyboard.instantiateViewController(withIdentifier: "OnboardingScreenId")
            self.window?.rootViewController = initialViewController
            self.window?.makeKeyAndVisible()

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
